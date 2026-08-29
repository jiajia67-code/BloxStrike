using DeltaForce_External.Classes;
using DeltaForce_External.Data;
using DeltaForce_External.ImGUI;
using DeltaForce_External.Modules;
using System.Diagnostics;

namespace DeltaForce_External
{
    internal class Program
    {
        static Memory? memory;
        static Overlay? overlay;
        static EntityManager? entityManager;
        static ESP? esp;
        static Aimbot? aimbot;

        static void Main(string[] args)
        {
            Console.Title = "DeltaForce External - Hawk Ops";
            Console.WriteLine("=== DeltaForce External ===");
            Console.WriteLine("[*] Waiting for Delta Force: Hawk Ops...");

            // Wait for game process
            Process? gameProcess = null;
            while (gameProcess == null)
            {
                gameProcess = Process.GetProcessesByName("DeltaForceClient-Win64-Shipping")
                    .FirstOrDefault();
                if (gameProcess == null)
                {
                    Thread.Sleep(1000);
                    Console.Write(".");
                }
            }

            Console.WriteLine($"\n[+] Found Delta Force: PID {gameProcess.Id}");

            // Initialize memory reader
            memory = new Memory(gameProcess);
            if (!memory.IsValid)
            {
                Console.WriteLine("[-] Failed to open process!");
                Console.ReadKey();
                return;
            }

            Console.WriteLine("[+] Process handle opened");

            // Find UE4 base addresses
            var module = gameProcess.MainModule;
            if (module == null)
            {
                Console.WriteLine("[-] Failed to get main module!");
                Console.ReadKey();
                return;
            }

            IntPtr baseAddress = module.BaseAddress;
            Console.WriteLine($"[+] Base Address: 0x{baseAddress:X}");

            // Initialize UE4 SDK
            var sdk = new UE4SDK(memory, baseAddress);
            if (!sdk.Initialize())
            {
                Console.WriteLine("[-] Failed to initialize UE4 SDK!");
                Console.ReadKey();
                return;
            }

            Console.WriteLine("[+] UE4 SDK initialized");
            Console.WriteLine($"    GWorld:    0x{sdk.GWorld:X}");
            Console.WriteLine($"    GObjects:  0x{sdk.GObjects:X}");
            Console.WriteLine($"    GNames:    0x{sdk.GNames:X}");

            // Initialize modules
            entityManager = new EntityManager(memory, sdk);
            esp = new ESP();
            aimbot = new Aimbot(memory, sdk);

            // Start overlay
            overlay = new Overlay(gameProcess, OnRender);

            Console.WriteLine("[+] All systems ready! Starting overlay...");
            Console.WriteLine("[*] Press INSERT to toggle menu");
            Console.WriteLine("[*] Press END to exit");

            overlay.Run();

            // Cleanup
            aimbot?.Disable();
            Console.WriteLine("[*] Exiting...");
        }

        static void OnRender()
        {
            if (entityManager == null || esp == null || aimbot == null) return;

            // Update entities
            entityManager.Update();

            // Draw ESP
            Modules.ESP.Draw(entityManager.LocalPlayer, entityManager.Players);

            // Draw aimbot
            aimbot.Update(entityManager.LocalPlayer, entityManager.Players);
        }
    }
}
