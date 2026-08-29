using FreeFire_Emulator.Classes;
using FreeFire_Emulator.Data;
using FreeFire_Emulator.ImGUI;
using FreeFire_Emulator.Modules;
using System.Diagnostics;

namespace FreeFire_Emulator
{
    internal class Program
    {
        static Memory? memory;
        static EntityManager? entityManager;
        static ESP? esp;
        static Aimbot? aimbot;
        static ADBMemory? adbMemory;
        static bool useADB;
        static IL2CppSDK? il2cpp;
        static bool il2cppReady;

        static readonly EmulatorInfo[] SupportedEmulators = new EmulatorInfo[]
        {
            new EmulatorInfo { Name = "HD-Player", DisplayName = "BlueStacks 5", Type = EmulatorType.BlueStacks },
            new EmulatorInfo { Name = "HD-Player", DisplayName = "BlueStacks 4", Type = EmulatorType.BlueStacks },
            new EmulatorInfo { Name = "dnplayer", DisplayName = "LDPlayer", Type = EmulatorType.LDPlayer },
            new EmulatorInfo { Name = "Nox", DisplayName = "NoxPlayer", Type = EmulatorType.NoxPlayer },
            new EmulatorInfo { Name = "MEmu", DisplayName = "MEmu", Type = EmulatorType.MEmu },
            new EmulatorInfo { Name = "AppMarket", DisplayName = "GameLoop", Type = EmulatorType.GameLoop },
        };

        [STAThread]
        static void Main(string[] args)
        {
            Console.Title = "FreeFire Emulator v2.0";
            Console.OutputEncoding = System.Text.Encoding.UTF8;

            try
            {
                Run(args);
            }
            catch (Exception ex)
            {
                Console.WriteLine();
                Console.WriteLine("╔══════════════════════════════════════════════╗");
                Console.WriteLine($"║  錯誤: {ex.Message}");
                Console.WriteLine($"║  {ex.StackTrace}");
                Console.WriteLine("╚══════════════════════════════════════════════╝");
            }

            // 永遠暫停，不讓控制台消失
            Console.WriteLine();
            Console.WriteLine("按任意鍵退出...");
            try { Console.ReadKey(true); } catch { }
        }

        static void Run(string[] args)
        {
            Console.WriteLine("FreeFire Emulator v2.0");
            Console.WriteLine("====================");
            Console.WriteLine();

            // ══════════════════════════════════════════════════════
            // Step 1: 等待模擬器
            // ══════════════════════════════════════════════════════
            Console.Write("等待模擬器");
            Process? emulatorProcess = null;

            while (emulatorProcess == null)
            {
                foreach (var emu in SupportedEmulators)
                {
                    var processes = Process.GetProcessesByName(emu.Name);
                    if (processes.Length > 0)
                    {
                        emulatorProcess = processes[0];
                        Console.WriteLine();
                        Console.WriteLine($"找到: {emu.DisplayName} (PID {emulatorProcess.Id})");
                        Console.WriteLine($"  記憶體: {emulatorProcess.WorkingSet64 / 1024 / 1024}MB");
                        Console.WriteLine($"  虛擬記憶體: {emulatorProcess.VirtualMemorySize64 / 1024 / 1024}MB");
                        break;
                    }
                }
                if (emulatorProcess == null)
                {
                    Console.Write(".");
                    Thread.Sleep(1000);
                }
            }

            // ══════════════════════════════════════════════════════
            // Step 2: 初始化偽裝系統
            // ══════════════════════════════════════════════════════
            Console.WriteLine("初始化偽裝系統...");
            try { SpoofManager.Enabled = true; SpoofManager.InitializeAll(); } catch (Exception ex) { Console.WriteLine($"  警告: {ex.Message}"); }

            Console.WriteLine("載入設定...");
            try { Config.Load(); } catch { }

            // ══════════════════════════════════════════════════════
            // Step 3: 診斷記憶體存取
            // ══════════════════════════════════════════════════════
            Console.WriteLine();
            Console.WriteLine("═══ 診斷記憶體存取 ═══");

            // 3a: 測試 Windows 直接存取
            Console.Write("[Windows] OpenProcess...");
            memory = new Memory(emulatorProcess);
            if (memory.IsValid)
            {
                Console.WriteLine(" OK");
                Console.Write("[Windows] ReadProcessMemory...");
                try
                {
                    // 嘗試讀4 bytes
                    byte[] test = memory.ReadBytes(emulatorProcess.MainModule!.BaseAddress, 4);
                    if (test.Length >= 4)
                        Console.WriteLine($" OK (0x{test[0]:X2}{test[1]:X2}{test[2]:X2}{test[3]:X2})");
                    else
                        Console.WriteLine($" FAIL (read {test.Length} bytes)");
                }
                catch (Exception ex)
                {
                    Console.WriteLine($" FAIL ({ex.Message})");
                }
            }
            else
            {
                Console.WriteLine(" FAIL");
            }

            // 3b: 診斷 ADB
            Console.Write("[ADB] 連接...");
            try
            {
                adbMemory = new ADBMemory();
                if (adbMemory.Connect())
                {
                    Console.WriteLine($" OK (PID: {adbMemory.GamePid})");

                    Console.Write("[ADB] /proc/pid/maps...");
                    var mapsResult = adbMemory.Shell($"cat /proc/{adbMemory.GamePid}/maps 2>&1 | head -3");
                    if (!string.IsNullOrEmpty(mapsResult.Output) && !mapsResult.Output.Contains("Permission denied"))
                        Console.WriteLine($" OK");
                    else
                        Console.WriteLine($" BLOCKED ({mapsResult.Output.Trim()})");

                    Console.Write("[ADB] /proc/pid/mem...");
                    var memResult = adbMemory.Shell($"dd if=/proc/{adbMemory.GamePid}/mem bs=1 count=4 skip=0 2>&1 | od -A x -t x1 | head -1");
                    if (memResult.ExitCode == 0 && !memResult.Output.Contains("Permission denied") && !memResult.Output.Contains("denied"))
                        Console.WriteLine($" OK");
                    else
                        Console.WriteLine($" BLOCKED");

                    Console.Write("[ADB] libil2cpp on disk...");
                    var diskCheck = adbMemory.Shell("ls -la /data/app/com.dts.freefireth*/lib/arm/libil2cpp.so 2>&1");
                    if (diskCheck.Output.Contains("libil2cpp"))
                        Console.WriteLine($" OK (182MB)");
                    else
                        Console.WriteLine($" NOT FOUND");
                }
                else
                {
                    Console.WriteLine(" FAIL");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($" ERROR: {ex.Message}");
            }

            Console.WriteLine("═══════════════════════════════════════════════");
            Console.WriteLine();

            // ══════════════════════════════════════════════════════
            // Step 4: 初始化 IL2CPP
            // ══════════════════════════════════════════════════════
            il2cppReady = false;

            if (memory != null && memory.IsValid)
            {
                il2cpp = new IL2CppSDK(memory, emulatorProcess);
                il2cppReady = il2cpp.Initialize();
            }

            if (!il2cppReady && adbMemory != null && adbMemory.IsConnected)
            {
                il2cpp = new IL2CppSDK(adbMemory);
                il2cppReady = il2cpp.Initialize();
            }

            // ══════════════════════════════════════════════════════
            // Step 5: 狀態報告
            // ══════════════════════════════════════════════════════
            Console.WriteLine();
            if (il2cppReady)
            {
                Console.WriteLine("✅ IL2CPP 就緒! 功能可以使用!");
                Console.WriteLine($"   ModuleBase: 0x{il2cpp!.ModuleBase:X}");

                Console.WriteLine("初始化模組...");
                entityManager = new EntityManager(memory!, il2cpp);
                esp = new ESP();
                aimbot = new Aimbot(memory!, il2cpp);
                Console.WriteLine("✅ 所有模組就緒!");
            }
            else
            {
                Console.WriteLine("❌ IL2CPP 未就緒 — 功能不會生效");
                Console.WriteLine();
                Console.WriteLine("原因: BlueStacks 5 Hyper-V 模式封鎖了記憶體存取");
                Console.WriteLine();
                Console.WriteLine("解決方案 (擇一):");
                Console.WriteLine("  1. 把 BlueStacks 切到 Classic 模式");
                Console.WriteLine("     (Settings > Advanced > BSV Engine > Legacy)");
                Console.WriteLine("  2. 換用 LDPlayer 或 NoxPlayer (支援記憶體存取)");
                Console.WriteLine("  3. 在模擬器內安裝 Magisk 並 root");
            }

            // ══════════════════════════════════════════════════════
            // Step 6: 啟動選單
            // ══════════════════════════════════════════════════════
            Console.WriteLine();
            var em = entityManager ?? new EntityManager(null!, null!);
            var espModule = esp ?? new ESP();

            OverlayWindow.Run(
                emulatorProcess.MainWindowHandle,
                em,
                espModule,
                il2cppReady ? OnRender : null
            );
        }

        static void OnRender()
        {
            try { entityManager?.Update(); } catch { }
        }
    }

    internal struct EmulatorInfo
    {
        public string Name;
        public string DisplayName;
        public EmulatorType Type;
    }

    internal enum EmulatorType
    {
        BlueStacks, LDPlayer, NoxPlayer, MEmu, GameLoop,
    }
}
