using Enlisted_External.Classes;
using Enlisted_External.Data;
using Enlisted_External.ImGUI;
using Enlisted_External.Modules;
using System.Diagnostics;

namespace Enlisted_External
{
    internal class Program
    {
        static Memory? memory;
        static EntityManager? entityManager;
        static DagorSDK? sdk;

        static void Main(string[] args)
        {
            // Check for dump mode
            if (args.Length > 0 && args[0] == "--dump")
            {
                Tools.MemoryDumper.Run();
                return;
            }

            Console.Title = "Enlisted External — Dagor Engine 6.x";
            Console.WriteLine("═══════════════════════════════════════════════════════════");
            Console.WriteLine("     Enlisted External — Dagor Engine 6.x (daECS)");
            Console.WriteLine("═══════════════════════════════════════════════════════════");
            Console.WriteLine();

            // ── Step 1: Find Enlisted process ──
            Console.Write("[*] Waiting for Enlisted...");
            Process? gameProcess = null;
            int waitCount = 0;
            while (gameProcess == null)
            {
                gameProcess = Process.GetProcessesByName("enlisted").FirstOrDefault();
                if (gameProcess == null)
                {
                    Thread.Sleep(1000);
                    Console.Write(".");
                    waitCount++;
                    if (waitCount > 300) // 5 minutes
                    {
                        Console.WriteLine("\n[-] Timeout. Please start Enlisted first.");
                        Console.ReadKey();
                        return;
                    }
                }
            }

            Console.WriteLine($" OK");
            Console.WriteLine($"[+] Found Enlisted: PID {gameProcess.Id}");

            // ── Step 2: Open process ──
            memory = new Memory(gameProcess);
            if (!memory.IsValid)
            {
                Console.WriteLine("[-] Failed to open process! (try running as admin)");
                Console.ReadKey();
                return;
            }
            Console.WriteLine("[+] Process handle opened");

            // ── Step 3: Get base address ──
            var module = gameProcess.MainModule;
            if (module == null)
            {
                Console.WriteLine("[-] Failed to get main module!");
                Console.ReadKey();
                return;
            }

            IntPtr baseAddress = module.BaseAddress;
            Console.WriteLine($"[+] Base Address: 0x{baseAddress:X}");

            // ── Step 4: Initialize Dagor SDK ──
            sdk = new DagorSDK(memory, baseAddress);
            if (!sdk.Initialize())
            {
                Console.WriteLine("[-] Dagor SDK init failed! Game may not be fully loaded.");
                Console.WriteLine("[*] Try restarting Enlisted and injecting again.");
                Console.WriteLine("[*] Press any key to continue anyway...");
                Console.ReadKey();
                // Continue — menu will still show, just ESP won't work
            }

            // ── Step 5: Initialize EntityManager ──
            entityManager = new EntityManager(memory, sdk);
            Console.WriteLine("[+] Entity Manager initialized");

            // ── Step 6: Get screen size ──
            int screenW = 1920, screenH = 1080;
            try
            {
                screenW = gameProcess.MainWindowHandle != IntPtr.Zero ? 1920 : 1920;
                screenH = 1080;
            }
            catch { }

            Console.WriteLine($"[+] Screen: {screenW}x{screenH}");
            Console.WriteLine();
            Console.WriteLine("[+] All systems ready!");
            Console.WriteLine("[*] Starting overlay — INSERT=Menu, END=Exit");
            Console.WriteLine();

            // ── Step 7: Main loop ──
            bool menuOpen = true;
            bool isRunning = true;

            while (isRunning)
            {
                // Check END
                if ((GetAsyncKeyState(0x23) & 0x8000) != 0)
                {
                    isRunning = false;
                    break;
                }

                // Check INSERT
                if ((GetAsyncKeyState(0x2D) & 1) != 0)
                {
                    menuOpen = !menuOpen;
                    Thread.Sleep(100);
                }

                // Update entities
                try
                {
                    entityManager.ScreenWidth = screenW;
                    entityManager.ScreenHeight = screenH;
                    entityManager.Update();

                    // Update modules
                    ESP.Update(entityManager.LocalPlayer, entityManager.Players, screenW, screenH);
                    Aimbot.Update(entityManager.LocalPlayer, entityManager.Players, screenW, screenH);
                    Triggerbot.Update(entityManager.LocalPlayer, entityManager.Players, screenW, screenH);
                    Radar.Update(entityManager.LocalPlayer, entityManager.Players, entityManager.Vehicles);
                    Chams.Update(entityManager.LocalPlayer, entityManager.Players);
                }
                catch { }

                // Status line (only updates periodically)
                if (waitCount++ % 30 == 0)
                {
                    try
                    {
                        string status = $"[Status] Players: {entityManager.Players.Count} | ";
                        status += $"Local: {(entityManager.LocalPlayer != null ? "YES" : "NO")} | ";
                        status += $"Camera: {entityManager.LocalPlayer?.Position.ToString() ?? "N/A"}";
                        Console.WriteLine(status);
                    }
                    catch { }
                }

                Thread.Sleep(16); // ~60fps
            }

            Console.WriteLine("\n[*] Exiting...");
        }

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        static extern short GetAsyncKeyState(int vKey);
    }
}
