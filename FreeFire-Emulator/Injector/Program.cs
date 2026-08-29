using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading;

namespace FreeFire_Emulator.Injector
{
    /// <summary>
    /// 自動注入器 - 自動找模擬器並注入
    /// </summary>
    class Program
    {
        // 模擬器進程名稱
        private static readonly string[] EmulatorProcessNames = new string[]
        {
            "HD-Player",           // BlueStacks
            "dnplayer",            // LDPlayer
            "Nox",                 // Nox
            "NoxVMSVC",           // Nox VM
            "MEmu",               // MEmu
            "MEmuHeadless",       // MEmu Headless
            "AndroidEmulator",    // GameLoop
            "AppMarket",          // GameLoop AppMarket
            "LdVBoxHeadless",     // LDPlayer VBox
            "MEmuHeadless",       // MEmu Headless
            "LdVBoxSVC",         // LDPlayer SVC
            "NoxVVM",            // Nox VM
        };

        // Free Fire 進程名稱
        private static readonly string[] FreeFireProcessNames = new string[]
        {
            "com.dts.freefireth",
            "com.dts.freefiremax",
            "freefire",
            "FreeFire",
        };

        // DLL 路徑
        private static string _dllPath = "";
        
        // 狀態
        private static bool _isInjected = false;
        private static Process? _targetProcess = null;

        [DllImport("kernel32.dll")]
        static extern IntPtr OpenProcess(uint dwDesiredAccess, bool bInheritHandle, int dwProcessId);

        [DllImport("kernel32.dll")]
        static extern IntPtr GetModuleHandle(string lpModuleName);

        [DllImport("kernel32.dll")]
        static extern IntPtr GetProcAddress(IntPtr hModule, string lpProcName);

        [DllImport("kernel32.dll")]
        static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);

        [DllImport("kernel32.dll")]
        static extern bool VirtualProtectEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flNewProtect, out uint lpflOldProtect);

        [DllImport("kernel32.dll")]
        static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out int lpNumberOfBytesWritten);

        [DllImport("kernel32.dll")]
        static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, out int lpThreadId);

        [DllImport("kernel32.dll")]
        static extern bool CloseHandle(IntPtr hObject);

        [DllImport("kernel32.dll")]
        static extern uint WaitForSingleObject(IntPtr hHandle, uint dwMilliseconds);

        private const uint PROCESS_ALL_ACCESS = 0x1F0FFF;
        private const uint PROCESS_CREATE_THREAD = 0x0002;
        private const uint PROCESS_QUERY_INFORMATION = 0x0400;
        private const uint PROCESS_VM_OPERATION = 0x0008;
        private const uint PROCESS_VM_WRITE = 0x0020;
        private const uint PROCESS_VM_READ = 0x0010;
        private const uint MEM_COMMIT = 0x1000;
        private const uint MEM_RESERVE = 0x2000;
        private const uint PAGE_READWRITE = 0x04;
        private const uint INFINITE = 0xFFFFFFFF;

        static void Main(string[] args)
        {
            Console.Title = "FreeFire Auto-Injector v2.0";
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine(@"
  ╔═══════════════════════════════════════════════════╗
  ║        FreeFire Auto-Injector v2.0               ║
  ║        自動注入器 - 自動找模擬器並注入            ║
  ╚═══════════════════════════════════════════════════╝
");
            Console.ResetColor();

            // 檢查 DLL
            _dllPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "FreeFire_Emulator.dll");
            
            if (!File.Exists(_dllPath))
            {
                Console.ForegroundColor = ConsoleColor.Yellow;
                Console.WriteLine("[!] 找不到 DLL: FreeFire_Emulator.dll");
                Console.WriteLine("[*] 請確保 DLL 在同一目錄下");
                Console.WriteLine("");
                Console.ForegroundColor = ConsoleColor.White;
                Console.WriteLine("按任意鍵退出...");
                Console.ReadKey();
                return;
            }

            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine("[✓] 找到 DLL: " + Path.GetFileName(_dllPath));
            Console.ResetColor();

            // 開始自動注入
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("\n[*] 開始自動掃描模擬器...");
            Console.ResetColor();

            // 主循環
            while (true)
            {
                try
                {
                    // 尋找模擬器
                    Process? emulator = FindEmulator();
                    
                    if (emulator != null)
                    {
                        Console.ForegroundColor = ConsoleColor.Green;
                        Console.WriteLine($"[✓] 找到模擬器: {emulator.ProcessName} (PID: {emulator.Id})");
                        Console.ResetColor();

                        // 尋找 Free Fire
                        Process? freeFire = FindFreeFire(emulator.Id);
                        
                        if (freeFire != null)
                        {
                            Console.ForegroundColor = ConsoleColor.Green;
                            Console.WriteLine($"[✓] 找到 Free Fire: {freeFire.ProcessName} (PID: {freeFire.Id})");
                            Console.ResetColor();

                            // 注入
                            if (!_isInjected)
                            {
                                Console.ForegroundColor = ConsoleColor.Yellow;
                                Console.WriteLine("[*] 正在注入...");
                                Console.ResetColor();

                                bool success = Inject(freeFire.Id);
                                
                                if (success)
                                {
                                    _isInjected = true;
                                    _targetProcess = freeFire;
                                    
                                    Console.ForegroundColor = ConsoleColor.Green;
                                    Console.WriteLine("[✓] 注入成功！");
                                    Console.WriteLine("[*] 功能已啟動，享受遊戲！");
                                    Console.ResetColor();
                                }
                                else
                                {
                                    Console.ForegroundColor = ConsoleColor.Red;
                                    Console.WriteLine("[✗] 注入失敗，將在5秒後重試...");
                                    Console.ResetColor();
                                    Thread.Sleep(5000);
                                }
                            }
                            else
                            {
                                // 檢查進程是否還活著
                                try
                                {
                                    if (_targetProcess != null && !_targetProcess.HasExited)
                                    {
                                        // 進程還活著
                                        Thread.Sleep(1000);
                                        continue;
                                    }
                                }
                                catch
                                {
                                    // 進程已結束
                                }
                                
                                _isInjected = false;
                                Console.ForegroundColor = ConsoleColor.Yellow;
                                Console.WriteLine("[*] 進程已結束，重新掃描...");
                                Console.ResetColor();
                            }
                        }
                        else
                        {
                            Console.ForegroundColor = ConsoleColor.Yellow;
                            Console.WriteLine("[*] 等待 Free Fire 啟動...");
                            Console.ResetColor();
                            Thread.Sleep(2000);
                        }
                    }
                    else
                    {
                        Console.ForegroundColor = ConsoleColor.Yellow;
                        Console.Write("\r[*] 等待模擬器啟動... (" + DateTime.Now.ToString("HH:mm:ss") + ")  ");
                        Console.ResetColor();
                        Thread.Sleep(1000);
                    }
                }
                catch (Exception ex)
                {
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine($"\n[!] 錯誤: {ex.Message}");
                    Console.ResetColor();
                    Thread.Sleep(2000);
                }
            }
        }

        /// <summary>
        /// 尋找模擬器進程
        /// </summary>
        static Process? FindEmulator()
        {
            foreach (string processName in EmulatorProcessNames)
            {
                Process[] processes = Process.GetProcessesByName(processName);
                if (processes.Length > 0)
                {
                    return processes[0];
                }
            }
            return null;
        }

        /// <summary>
        /// 尋找 Free Fire 進程
        /// </summary>
        static Process? FindFreeFire(int emulatorId)
        {
            // 方法1: 尋找已知的 Free Fire 進程名稱
            foreach (string processName in FreeFireProcessNames)
            {
                Process[] processes = Process.GetProcessesByName(processName);
                if (processes.Length > 0)
                {
                    return processes[0];
                }
            }

            // 方法2: 尋找模擬器的所有子進程
            try
            {
                Process? emulator = Process.GetProcessById(emulatorId);
                if (emulator != null)
                {
                    // 使用 WMI 尋找子進程
                    var searcher = new System.Management.ManagementObjectSearcher(
                        $"SELECT * FROM Win32_Process WHERE ParentProcessId = {emulatorId}");
                    
                    foreach (var obj in searcher.Get())
                    {
                        uint childPid = Convert.ToUInt32(obj["ProcessId"]);
                        string childName = obj["Name"].ToString() ?? "";
                        
                        // 檢查是否是 Free Fire
                        if (childName.ToLower().Contains("freefire") || 
                            childName.ToLower().Contains("free fire") ||
                            childName.ToLower().Contains("dts"))
                        {
                            try
                            {
                                return Process.GetProcessById((int)childPid);
                            }
                            catch { }
                        }
                    }
                }
            }
            catch { }

            // 方法3: 尋找所有進程，檢查命令列
            try
            {
                foreach (Process proc in Process.GetProcesses())
                {
                    try
                    {
                        string cmdLine = GetCommandLine(proc.Id);
                        if (cmdLine.ToLower().Contains("freefire") || 
                            cmdLine.ToLower().Contains("free fire"))
                        {
                            return proc;
                        }
                    }
                    catch { }
                }
            }
            catch { }

            return null;
        }

        /// <summary>
        /// 取得進程命令列
        /// </summary>
        static string GetCommandLine(int processId)
        {
            try
            {
                using var searcher = new System.Management.ManagementObjectSearcher(
                    $"SELECT CommandLine FROM Win32_Process WHERE ProcessId = {processId}");
                
                foreach (var obj in searcher.Get())
                {
                    return obj["CommandLine"]?.ToString() ?? "";
                }
            }
            catch { }
            
            return "";
        }

        /// <summary>
        /// 注入 DLL 到進程
        /// </summary>
        static bool Inject(int processId)
        {
            try
            {
                // 開啟進程
                IntPtr hProcess = OpenProcess(
                    PROCESS_CREATE_THREAD | PROCESS_QUERY_INFORMATION | 
                    PROCESS_VM_OPERATION | PROCESS_VM_WRITE | PROCESS_VM_READ,
                    false, processId);
                
                if (hProcess == IntPtr.Zero)
                {
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine("[✗] 無法開啟進程 (需要管理員權限)");
                    Console.ResetColor();
                    return false;
                }

                // 取得 LoadLibraryA 地址
                IntPtr kernel32 = GetModuleHandle("kernel32.dll");
                IntPtr loadLibraryAddr = GetProcAddress(kernel32, "LoadLibraryA");
                
                if (loadLibraryAddr == IntPtr.Zero)
                {
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine("[✗] 無法取得 LoadLibraryA 地址");
                    Console.ResetColor();
                    CloseHandle(hProcess);
                    return false;
                }

                // 分配記憶體
                byte[] dllBytes = System.Text.Encoding.ASCII.GetBytes(_dllPath + "\0");
                IntPtr allocAddr = VirtualAllocEx(hProcess, IntPtr.Zero, (uint)dllBytes.Length, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
                
                if (allocAddr == IntPtr.Zero)
                {
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine("[✗] 無法分配記憶體");
                    Console.ResetColor();
                    CloseHandle(hProcess);
                    return false;
                }

                // 寫入 DLL 路徑
                int bytesWritten;
                if (!WriteProcessMemory(hProcess, allocAddr, dllBytes, (uint)dllBytes.Length, out bytesWritten))
                {
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine("[✗] 無法寫入記憶體");
                    Console.ResetColor();
                    CloseHandle(hProcess);
                    return false;
                }

                // 建立遠端執行緒
                int threadId;
                IntPtr hThread = CreateRemoteThread(hProcess, IntPtr.Zero, 0, loadLibraryAddr, allocAddr, 0, out threadId);
                
                if (hThread == IntPtr.Zero)
                {
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine("[✗] 無法建立遠端執行緒");
                    Console.ResetColor();
                    CloseHandle(hProcess);
                    return false;
                }

                // 等待執行緒完成
                WaitForSingleObject(hThread, INFINITE);

                // 清理
                CloseHandle(hThread);
                CloseHandle(hProcess);

                return true;
            }
            catch (Exception ex)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"[✗] 注入錯誤: {ex.Message}");
                Console.ResetColor();
                return false;
            }
        }
    }
}
