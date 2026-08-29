using System.Diagnostics;
using System.Numerics;
using System.Runtime.InteropServices;
using Enlisted_External.Data;
using Enlisted_External.Modules;

namespace Enlisted_External.ImGUI
{
    internal class Overlay
    {
        [DllImport("user32.dll")]
        static extern short GetAsyncKeyState(int vKey);

        [DllImport("kernel32.dll")]
        static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);

        [DllImport("kernel32.dll")]
        static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);

        [DllImport("kernel32.dll")]
        static extern IntPtr GetStdHandle(int nStdHandle);

        const int VK_INSERT = 0x2D;
        const int VK_END = 0x23;
        const int VK_UP = 0x26;
        const int VK_DOWN = 0x28;
        const int VK_LEFT = 0x25;
        const int VK_RIGHT = 0x27;
        const int VK_RETURN = 0x0D;
        const int VK_ESCAPE = 0x1B;
        const int STD_OUTPUT_HANDLE = -11;
        const uint ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004;

        private Process gameProcess;
        private Action? onRender;
        private bool isRunning;
        private bool showMenu = true;
        private int selectedTab = 0;
        private int selectedItem = 0;

        private static readonly string[] Tabs = { "ESP", "Aimbot", "Trigger", "NoRecoil", "Radar", "Chams", "Config" };

        public Overlay(Process process, Action renderCallback)
        {
            gameProcess = process;
            onRender = renderCallback;
        }

        public void Run()
        {
            isRunning = true;
            EnableAnsi();
            Console.CursorVisible = false;

            DrawMenu();
            Console.WriteLine("[+] Overlay started. INSERT=Menu, END=Exit");

            while (isRunning)
            {
                HandleInput();
                if (showMenu) DrawMenu();
                Thread.Sleep(16); // ~60fps
            }

            Console.CursorVisible = true;
            Console.ResetColor();
        }

        private void EnableAnsi()
        {
            try
            {
                IntPtr hOut = GetStdHandle(STD_OUTPUT_HANDLE);
                GetConsoleMode(hOut, out uint mode);
                SetConsoleMode(hOut, mode | ENABLE_VIRTUAL_TERMINAL_PROCESSING);
            }
            catch { }
        }

        private void ClearScreen()
        {
            try
            {
                Console.SetCursorPosition(0, 0);
            }
            catch
            {
                Console.Write("\x1b[2J\x1b[H");
            }
        }

        private void HandleInput()
        {
            // Check END to exit
            if ((GetAsyncKeyState(VK_END) & 0x8000) != 0)
            {
                isRunning = false;
                return;
            }

            // Check INSERT to toggle menu
            if ((GetAsyncKeyState(VK_INSERT) & 1) != 0)
            {
                showMenu = !showMenu;
                Thread.Sleep(100);
            }

            if (!showMenu) return;

            var items = GetTabItems();

            // Arrow keys with debounce
            if ((GetAsyncKeyState(VK_UP) & 1) != 0)
            {
                selectedItem = Math.Max(0, selectedItem - 1);
                DrawMenu();
                Thread.Sleep(50);
            }
            if ((GetAsyncKeyState(VK_DOWN) & 1) != 0)
            {
                selectedItem = Math.Min(items.Length - 1, selectedItem + 1);
                DrawMenu();
                Thread.Sleep(50);
            }
            if ((GetAsyncKeyState(VK_LEFT) & 1) != 0)
            {
                selectedTab = Math.Max(0, selectedTab - 1);
                selectedItem = 0;
                DrawMenu();
                Thread.Sleep(50);
            }
            if ((GetAsyncKeyState(VK_RIGHT) & 1) != 0)
            {
                selectedTab = Math.Min(Tabs.Length - 1, selectedTab + 1);
                selectedItem = 0;
                DrawMenu();
                Thread.Sleep(50);
            }
            if ((GetAsyncKeyState(VK_RETURN) & 1) != 0)
            {
                ToggleItem(selectedItem);
                DrawMenu();
                Thread.Sleep(50);
            }
        }

        private void DrawMenu()
        {
            try { ClearScreen(); } catch { return; }

            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("═══════════════════════════════════════════════════════════════");
            Console.WriteLine("       Enlisted External — Dagor Engine 6.x (daECS)");
            Console.WriteLine("═══════════════════════════════════════════════════════════════");
            Console.ResetColor();

            // Tab bar
            for (int i = 0; i < Tabs.Length; i++)
            {
                if (i == selectedTab)
                {
                    Console.ForegroundColor = ConsoleColor.Black;
                    Console.BackgroundColor = ConsoleColor.Cyan;
                }
                else
                {
                    Console.ForegroundColor = ConsoleColor.DarkGray;
                }
                Console.Write($" {Tabs[i]} ");
                Console.ResetColor();
            }
            Console.WriteLine();
            Console.WriteLine(new string('─', 63));

            // Items
            var items = GetTabItems();
            for (int i = 0; i < items.Length; i++)
            {
                var (label, value) = items[i];

                if (i == selectedItem)
                {
                    Console.ForegroundColor = ConsoleColor.Yellow;
                    Console.Write(" ► ");
                }
                else
                {
                    Console.Write("   ");
                }

                Console.ForegroundColor = ConsoleColor.White;
                Console.Write($" {label,-28}");

                if (value is true)
                {
                    Console.ForegroundColor = ConsoleColor.Green;
                    Console.Write("  [ON] ");
                }
                else if (value is false)
                {
                    Console.ForegroundColor = ConsoleColor.DarkGray;
                    Console.Write("  [OFF]");
                }
                else if (value is float fv)
                {
                    Console.ForegroundColor = ConsoleColor.Yellow;
                    Console.Write($"  {fv:F1}  ");
                }
                else if (value is int iv)
                {
                    Console.ForegroundColor = ConsoleColor.Yellow;
                    Console.Write($"  {iv}  ");
                }

                Console.ResetColor();
                Console.WriteLine();
            }

            Console.WriteLine(new string('─', 63));
            Console.ForegroundColor = ConsoleColor.DarkGray;
            Console.WriteLine(" ← → Tab  ↑↓ Move  ENTER Toggle  INSERT Close  END Exit");
            Console.ResetColor();
        }

        private (string label, object? value)[] GetTabItems()
        {
            return selectedTab switch
            {
                0 => new[] // ESP
                {
                    ("Enable ESP", (object?)ESP.PlayerESP),
                    ("Box ESP", ESP.BoxESP),
                    ("Health Bar", ESP.HealthBar),
                    ("Name", ESP.NameESP),
                    ("Weapon", ESP.WeaponESP),
                    ("Distance", ESP.DistanceESP),
                    ("Head Circle", ESP.HeadCircle),
                    ("View Direction", ESP.ViewDirection),
                    ("Tracers", ESP.Tracers),
                    ("Loot ESP", ESP.LootESP),
                    ("Vehicle ESP", ESP.VehicleESP),
                },
                1 => new[] // Aimbot
                {
                    ("Enable Aimbot", (object?)Aimbot.Enabled),
                    ("Visible Only", Aimbot.VisibleOnly),
                    ("Draw FOV", Aimbot.DrawFOV),
                    ("Draw Target Line", Aimbot.DrawTargetLine),
                    ("FOV", Aimbot.FOV),
                    ("Smooth", Aimbot.Smooth),
                    ("Max Distance", (object?)(int)Aimbot.MaxDistance),
                },
                2 => new[] // Triggerbot
                {
                    ("Enable Trigger", (object?)Triggerbot.Enabled),
                    ("Visible Only", Triggerbot.VisibleOnly),
                    ("Team Check", Triggerbot.TeamCheck),
                    ("Max Distance", (object?)(int)Triggerbot.MaxDistance),
                },
                3 => new[] // NoRecoil
                {
                    ("Enable NoRecoil", (object?)NoRecoil.Enabled),
                    ("Horizontal", NoRecoil.RecoilScaleX),
                    ("Vertical", NoRecoil.RecoilScaleY),
                },
                4 => new[] // Radar
                {
                    ("Enable Radar", (object?)Radar.Enabled),
                    ("Size", Radar.RadarSize),
                    ("Range", Radar.RadarRange),
                    ("Show Teammates", Radar.ShowTeammates),
                    ("Show Enemies", Radar.ShowEnemies),
                },
                5 => new[] // Chams
                {
                    ("Enable Chams", (object?)Chams.Enabled),
                    ("Player Chams", Chams.PlayerChams),
                },
                _ => new[] // Config
                {
                    ("— Coming Soon —", (object?)null),
                },
            };
        }

        private void ToggleItem(int index)
        {
            switch (selectedTab)
            {
                case 0: ToggleESP(index); break;
                case 1: ToggleAimbot(index); break;
                case 2: ToggleTrigger(index); break;
                case 3: ToggleNoRecoil(index); break;
                case 4: ToggleRadar(index); break;
                case 5: ToggleChams(index); break;
            }
        }

        private void ToggleESP(int i)
        {
            switch (i)
            {
                case 0: ESP.PlayerESP = !ESP.PlayerESP; break;
                case 1: ESP.BoxESP = !ESP.BoxESP; break;
                case 2: ESP.HealthBar = !ESP.HealthBar; break;
                case 3: ESP.NameESP = !ESP.NameESP; break;
                case 4: ESP.WeaponESP = !ESP.WeaponESP; break;
                case 5: ESP.DistanceESP = !ESP.DistanceESP; break;
                case 6: ESP.HeadCircle = !ESP.HeadCircle; break;
                case 7: ESP.ViewDirection = !ESP.ViewDirection; break;
                case 8: ESP.Tracers = !ESP.Tracers; break;
                case 9: ESP.LootESP = !ESP.LootESP; break;
                case 10: ESP.VehicleESP = !ESP.VehicleESP; break;
            }
        }

        private void ToggleAimbot(int i)
        {
            switch (i)
            {
                case 0: Aimbot.Enabled = !Aimbot.Enabled; break;
                case 1: Aimbot.VisibleOnly = !Aimbot.VisibleOnly; break;
                case 2: Aimbot.DrawFOV = !Aimbot.DrawFOV; break;
                case 3: Aimbot.DrawTargetLine = !Aimbot.DrawTargetLine; break;
                case 4: Aimbot.FOV = Aimbot.FOV >= 500 ? 10 : Aimbot.FOV + 50; break;
                case 5: Aimbot.Smooth = Aimbot.Smooth >= 20 ? 1 : Aimbot.Smooth + 1; break;
                case 6: Aimbot.MaxDistance = Aimbot.MaxDistance >= 5000 ? 500 : Aimbot.MaxDistance + 500; break;
            }
        }

        private void ToggleTrigger(int i)
        {
            switch (i)
            {
                case 0: Triggerbot.Enabled = !Triggerbot.Enabled; break;
                case 1: Triggerbot.VisibleOnly = !Triggerbot.VisibleOnly; break;
                case 2: Triggerbot.TeamCheck = !Triggerbot.TeamCheck; break;
                case 3: Triggerbot.MaxDistance = Triggerbot.MaxDistance >= 5000 ? 500 : Triggerbot.MaxDistance + 500; break;
            }
        }

        private void ToggleNoRecoil(int i)
        {
            switch (i)
            {
                case 0: NoRecoil.Enabled = !NoRecoil.Enabled; break;
                case 1: NoRecoil.RecoilScaleX = NoRecoil.RecoilScaleX <= 0 ? 1 : NoRecoil.RecoilScaleX - 0.1f; break;
                case 2: NoRecoil.RecoilScaleY = NoRecoil.RecoilScaleY <= 0 ? 1 : NoRecoil.RecoilScaleY - 0.1f; break;
            }
        }

        private void ToggleRadar(int i)
        {
            switch (i)
            {
                case 0: Radar.Enabled = !Radar.Enabled; break;
                case 1: Radar.RadarSize = Radar.RadarSize >= 400 ? 100 : Radar.RadarSize + 50; break;
                case 2: Radar.RadarRange = Radar.RadarRange >= 10000 ? 500 : Radar.RadarRange + 500; break;
                case 3: Radar.ShowTeammates = !Radar.ShowTeammates; break;
                case 4: Radar.ShowEnemies = !Radar.ShowEnemies; break;
            }
        }

        private void ToggleChams(int i)
        {
            switch (i)
            {
                case 0: Chams.Enabled = !Chams.Enabled; break;
                case 1: Chams.PlayerChams = !Chams.PlayerChams; break;
            }
        }

        private void Cleanup() { }
    }
}
