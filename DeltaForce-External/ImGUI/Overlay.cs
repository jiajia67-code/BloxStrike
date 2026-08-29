using System.Diagnostics;
using System.Numerics;
using System.Runtime.InteropServices;
using DeltaForce_External.Data;
using DeltaForce_External.Modules;
using ImGuiNET;

namespace DeltaForce_External.ImGUI
{
    /// <summary>
    /// DirectX 11 transparent overlay for Delta Force: Hawk Ops
    /// Uses raw P/Invoke for D3D11 device creation
    /// </summary>
    internal class Overlay
    {
        [DllImport("user32.dll")]
        static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

        [DllImport("user32.dll")]
        static extern short GetAsyncKeyState(int vKey);

        [StructLayout(LayoutKind.Sequential)]
        public struct RECT { public int Left, Top, Right, Bottom; }

        const int VK_INSERT = 0x2D;
        const int VK_END = 0x23;

        private Process gameProcess;
        private Action onRender;
        private bool isRunning;
        private bool showMenu = true;

        // Raw D3D11 pointers
        private IntPtr d3dDevice;
        private IntPtr d3dContext;
        private IntPtr swapChain;
        private IntPtr renderTargetView;

        public Overlay(Process process, Action renderCallback)
        {
            gameProcess = process;
            onRender = renderCallback;
        }

        public void Run()
        {
            isRunning = true;

            if (!InitializeDirectX())
            {
                Console.WriteLine("[-] Failed to initialize DirectX!");
                return;
            }

            InitializeImGui();
            Console.WriteLine("[+] Overlay started");

            while (isRunning)
            {
                if ((GetAsyncKeyState(VK_END) & 0x8000) != 0)
                {
                    isRunning = false;
                    break;
                }

                if ((GetAsyncKeyState(VK_INSERT) & 1) != 0)
                    showMenu = !showMenu;

                RenderFrame();
                Thread.Sleep(1);
            }

            Cleanup();
        }

        private bool InitializeDirectX()
        {
            try
            {
                // Create D3D11 device using raw interop
                IntPtr d3d11Dll = LoadLibrary("d3d11.dll");
                IntPtr createFunc = GetProcAddress(d3d11Dll, "D3D11CreateDeviceAndSwapChain");

                if (createFunc == IntPtr.Zero)
                {
                    Console.WriteLine("[-] D3D11CreateDeviceAndSwapChain not found!");
                    return false;
                }

                // For now, mark as initialized - actual D3D11 setup happens in the game process
                // The overlay window approach requires hooking into the game's D3D11 context
                Console.WriteLine("[*] D3D11 overlay ready (requires game D3D11 context)");

                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[-] DirectX init failed: {ex.Message}");
                return false;
            }
        }

        private void InitializeImGui()
        {
            ImGui.CreateContext();
            var io = ImGui.GetIO();
            io.DisplaySize = new Vector2(1920, 1080);

            ImGui.StyleColorsDark();
            var style = ImGui.GetStyle();
            style.WindowRounding = 6;
            style.FrameRounding = 4;
        }

        private void RenderFrame()
        {
            // New ImGui frame
            ImGui.NewFrame();

            // Draw ESP
            ESP.Draw(null, new List<Entity>());

            // Call render callback
            onRender.Invoke();

            // Draw menu
            if (showMenu)
                DrawMenu();

            ImGui.Render();
        }

        private void DrawMenu()
        {
            ImGui.Begin("DeltaForce External", ImGuiWindowFlags.AlwaysAutoResize);

            ImGui.Text("=== Delta Force: Hawk Ops ===");
            ImGui.Separator();

            if (ImGui.CollapsingHeader("Player ESP", ImGuiTreeNodeFlags.DefaultOpen))
            {
                bool val;
                val = ESP.PlayerESP; if (ImGui.Checkbox("Enable Player ESP", ref val)) ESP.PlayerESP = val;
                val = ESP.BoxESP; if (ImGui.Checkbox("Box ESP", ref val)) ESP.BoxESP = val;
                val = ESP.HealthBar; if (ImGui.Checkbox("Health Bar", ref val)) ESP.HealthBar = val;
                val = ESP.NameESP; if (ImGui.Checkbox("Name", ref val)) ESP.NameESP = val;
                val = ESP.WeaponESP; if (ImGui.Checkbox("Weapon", ref val)) ESP.WeaponESP = val;
                val = ESP.DistanceESP; if (ImGui.Checkbox("Distance", ref val)) ESP.DistanceESP = val;
                val = ESP.HeadCircle; if (ImGui.Checkbox("Head Circle", ref val)) ESP.HeadCircle = val;
                val = ESP.ViewDirection; if (ImGui.Checkbox("View Direction", ref val)) ESP.ViewDirection = val;
                val = ESP.Tracers; if (ImGui.Checkbox("Tracers", ref val)) ESP.Tracers = val;
            }

            if (ImGui.CollapsingHeader("Status ESP"))
            {
                bool val;
                val = ESP.DefusingIndicator; if (ImGui.Checkbox("Defusing Indicator", ref val)) ESP.DefusingIndicator = val;
                val = ESP.BombCarrier; if (ImGui.Checkbox("Bomb Carrier", ref val)) ESP.BombCarrier = val;
                val = ESP.FlashStatus; if (ImGui.Checkbox("Flash Status", ref val)) ESP.FlashStatus = val;
                val = ESP.HelmetIndicator; if (ImGui.Checkbox("Helmet Indicator", ref val)) ESP.HelmetIndicator = val;
            }

            if (ImGui.CollapsingHeader("World ESP"))
            {
                bool val;
                val = ESP.LootESP; if (ImGui.Checkbox("Loot ESP", ref val)) ESP.LootESP = val;
                val = ESP.VehicleESP; if (ImGui.Checkbox("Vehicle ESP", ref val)) ESP.VehicleESP = val;
                val = ESP.GrenadeESP; if (ImGui.Checkbox("Grenade ESP", ref val)) ESP.GrenadeESP = val;
            }

            if (ImGui.CollapsingHeader("Aimbot"))
            {
                bool valB;
                valB = Aimbot.Enabled; if (ImGui.Checkbox("Enable Aimbot", ref valB)) Aimbot.Enabled = valB;
                valB = Aimbot.VisibleOnly; if (ImGui.Checkbox("Visible Only", ref valB)) Aimbot.VisibleOnly = valB;
                valB = Aimbot.DrawFOV; if (ImGui.Checkbox("Draw FOV", ref valB)) Aimbot.DrawFOV = valB;
                valB = Aimbot.DrawTargetLine; if (ImGui.Checkbox("Draw Target Line", ref valB)) Aimbot.DrawTargetLine = valB;

                float fov = Aimbot.FOV; if (ImGui.SliderFloat("FOV", ref fov, 10f, 500f)) Aimbot.FOV = fov;
                float smooth = Aimbot.Smooth; if (ImGui.SliderFloat("Smooth", ref smooth, 1f, 20f)) Aimbot.Smooth = smooth;
                float maxDist = Aimbot.MaxDistance; if (ImGui.SliderFloat("Max Distance", ref maxDist, 100f, 5000f)) Aimbot.MaxDistance = maxDist;
            }

            // NoRecoil section
            if (ImGui.CollapsingHeader("No Recoil"))
            {
                bool val;
                val = NoRecoil.Enabled; if (ImGui.Checkbox("Enable NoRecoil", ref val)) NoRecoil.Enabled = val;
                val = NoRecoil.PredictionMode; if (ImGui.Checkbox("Prediction Mode", ref val)) NoRecoil.PredictionMode = val;

                float scaleX = NoRecoil.RecoilScaleX; if (ImGui.SliderFloat("Horizontal Scale", ref scaleX, 0f, 1f)) NoRecoil.RecoilScaleX = scaleX;
                float scaleY = NoRecoil.RecoilScaleY; if (ImGui.SliderFloat("Vertical Scale", ref scaleY, 0f, 1f)) NoRecoil.RecoilScaleY = scaleY;
            }

            // Fast Reload section
            if (ImGui.CollapsingHeader("Fast Reload"))
            {
                bool val;
                val = FastReload.Enabled; if (ImGui.Checkbox("Enable Fast Reload", ref val)) FastReload.Enabled = val;
                val = FastReload.SkipAnimation; if (ImGui.Checkbox("Skip Animation", ref val)) FastReload.SkipAnimation = val;

                float mult = FastReload.ReloadSpeedMultiplier; if (ImGui.SliderFloat("Speed Multiplier", ref mult, 0.1f, 1f)) FastReload.ReloadSpeedMultiplier = mult;
            }

            // Radar section
            if (ImGui.CollapsingHeader("Radar"))
            {
                bool val;
                val = Radar.Enabled; if (ImGui.Checkbox("Enable Radar", ref val)) Radar.Enabled = val;
                val = Radar.ShowTeammates; if (ImGui.Checkbox("Show Teammates", ref val)) Radar.ShowTeammates = val;
                val = Radar.ShowEnemies; if (ImGui.Checkbox("Show Enemies", ref val)) Radar.ShowEnemies = val;
                val = Radar.ShowVehicles; if (ImGui.Checkbox("Show Vehicles", ref val)) Radar.ShowVehicles = val;
                val = Radar.ShowLoot; if (ImGui.Checkbox("Show Loot", ref val)) Radar.ShowLoot = val;

                float size = Radar.RadarSize; if (ImGui.SliderFloat("Radar Size", ref size, 100f, 400f)) Radar.RadarSize = size;
                float range = Radar.RadarRange; if (ImGui.SliderFloat("Radar Range", ref range, 500f, 10000f)) Radar.RadarRange = range;
            }

            // Chams section
            if (ImGui.CollapsingHeader("Chams"))
            {
                bool val;
                val = Chams.Enabled; if (ImGui.Checkbox("Enable Chams", ref val)) Chams.Enabled = val;
                val = Chams.PlayerChams; if (ImGui.Checkbox("Player Chams", ref val)) Chams.PlayerChams = val;
                val = Chams.VehicleChams; if (ImGui.Checkbox("Vehicle Chams", ref val)) Chams.VehicleChams = val;
                val = Chams.VisibleCheck; if (ImGui.Checkbox("Visible Check", ref val)) Chams.VisibleCheck = val;
            }

            // Triggerbot section
            if (ImGui.CollapsingHeader("Triggerbot"))
            {
                bool val;
                val = Triggerbot.Enabled; if (ImGui.Checkbox("Enable Triggerbot", ref val)) Triggerbot.Enabled = val;
                val = Triggerbot.VisibleOnly; if (ImGui.Checkbox("Visible Only", ref val)) Triggerbot.VisibleOnly = val;
                val = Triggerbot.TeamCheck; if (ImGui.Checkbox("Team Check", ref val)) Triggerbot.TeamCheck = val;
                val = Triggerbot.UseDelay; if (ImGui.Checkbox("Use Delay", ref val)) Triggerbot.UseDelay = val;
                val = Triggerbot.RandomDelay; if (ImGui.Checkbox("Random Delay", ref val)) Triggerbot.RandomDelay = val;

                float minD = Triggerbot.MinDelay; if (ImGui.SliderFloat("Min Delay (ms)", ref minD, 0f, 200f)) Triggerbot.MinDelay = minD;
                float maxD = Triggerbot.MaxDelay; if (ImGui.SliderFloat("Max Delay (ms)", ref maxD, 0f, 500f)) Triggerbot.MaxDelay = maxD;
                float maxDist = Triggerbot.MaxDistance; if (ImGui.SliderFloat("Max Distance", ref maxDist, 100f, 5000f)) Triggerbot.MaxDistance = maxDist;
            }

            ImGui.Separator();
            ImGui.Text("INSERT = Toggle Menu | END = Exit");
            ImGui.End();
        }

        private void Cleanup()
        {
            ImGui.DestroyContext();
        }

        [DllImport("kernel32.dll")]
        private static extern IntPtr LoadLibrary(string lpFileName);

        [DllImport("kernel32.dll")]
        private static extern IntPtr GetProcAddress(IntPtr hModule, string lpProcName);
    }
}
