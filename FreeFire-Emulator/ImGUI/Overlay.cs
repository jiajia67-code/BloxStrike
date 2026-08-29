using System.Diagnostics;
using System.Runtime.InteropServices;
using FreeFire_Emulator.Classes;
using FreeFire_Emulator.Data;
using FreeFire_Emulator.Modules;

namespace FreeFire_Emulator.ImGUI
{
    internal static class OverlayWindow
    {
        [DllImport("user32.dll")]
        static extern short GetAsyncKeyState(int vKey);

        private static bool _running;
        private static int _selectedTab;
        private static int _selectedItem;
        private static int _lastVKey;
        private static DateTime _lastKeyTime;

        private static readonly string[] _tabs = {
            "ESP", "Aimbot", "Trigger", "Spin",
            "Radar", "FakeLag", "AimKill", "AIAim",
            "Combat", "Visual", "AntiDet", "Config"
        };

        public static void Run(IntPtr gameWnd, EntityManager em, ESP esp, Action? renderCallback)
        {
            _running = true;

            // 背景 render
            var renderThread = new Thread(() =>
            {
                while (_running)
                {
                    try { renderCallback?.Invoke(); } catch { }
                    Thread.Sleep(100);
                }
            }) { IsBackground = true };
            renderThread.Start();

            // 主迴圈
            while (_running)
            {
                DrawMenu();
                WaitForInput();
            }
        }

        private static void ClearScreen()
        {
            // ANSI escape code: move cursor to top-left + clear
            try
            {
                Console.Write("\x1b[2J\x1b[H");
                Console.Out.Flush();
            }
            catch
            {
                try
                {
                    // 備用: 多印空行使內容上移
                    for (int i = 0; i < 3; i++) Console.WriteLine();
                }
                catch { }
            }
        }

        private static void DrawMenu()
        {
            ClearScreen();
            var items = GetTabItems();

            try
            {
                Console.WriteLine("==========================================================");
                Console.WriteLine("     FreeFire Emulator v2.0 — Console Menu");
                Console.WriteLine("  Arrows=Navigate  Enter=Toggle  Esc=Exit");
                Console.WriteLine("==========================================================");
                Console.WriteLine();

                // 分頁列
                string tabLine = "";
                for (int i = 0; i < _tabs.Length; i++)
                {
                    string t = (i == _selectedTab) ? $"[{_tabs[i]}]" : $" {_tabs[i]}";
                    tabLine += t.PadRight(12);
                }
                Console.WriteLine(tabLine);
                Console.WriteLine(new string('-', 60));
                Console.WriteLine();

                // 選項
                for (int i = 0; i < items.Count; i++)
                {
                    var (label, value) = items[i];
                    string cur = (i == _selectedItem) ? ">>>" : "   ";

                    if (value == null)
                    {
                        Console.WriteLine($"{cur} === {label} ===");
                    }
                    else if (value is bool b)
                    {
                        Console.WriteLine($"{cur} {label,-22} {(b ? "[ON ]" : "[OFF]")}");
                    }
                    else
                    {
                        Console.WriteLine($"{cur} {label,-22} {value}");
                    }
                }

                Console.WriteLine();
                Console.WriteLine(new string('-', 60));
                Console.WriteLine("Arrow=Move  Enter=Toggle  Left/Right=Tab  Esc=Exit");
                Console.WriteLine();
                Console.Out.Flush();
            }
            catch { }
        }

        private static void WaitForInput()
        {
            while (_running)
            {
                Thread.Sleep(30);

                int[] keys = { 0x26, 0x28, 0x25, 0x27, 0x0D, 0x1B };
                for (int k = 0; k < keys.Length; k++)
                {
                    if ((GetAsyncKeyState(keys[k]) & 1) != 0)
                    {
                        if (keys[k] == _lastVKey && (DateTime.Now - _lastKeyTime).TotalMilliseconds < 150)
                            continue;
                        _lastVKey = keys[k];
                        _lastKeyTime = DateTime.Now;

                        var items = GetTabItems();
                        switch (k)
                        {
                            case 0: _selectedItem = Math.Max(0, _selectedItem - 1); return;
                            case 1: _selectedItem = Math.Min(items.Count - 1, _selectedItem + 1); return;
                            case 2: _selectedTab = Math.Max(0, _selectedTab - 1); _selectedItem = 0; return;
                            case 3: _selectedTab = Math.Min(_tabs.Length - 1, _selectedTab + 1); _selectedItem = 0; return;
                            case 4: ToggleCurrent(); return;
                            case 5: _running = false; return;
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════
        // Tab Items
        // ═══════════════════════════════════════════════════════════
        private static List<(string, object?)> _items = new();

        private static List<(string, object?)> GetTabItems()
        {
            _items.Clear();
            switch (_selectedTab)
            {
                case 0:
                    _items.Add(("Enable ESP", ESP.PlayerESP));
                    _items.Add(("Box ESP", ESP.BoxESP));
                    _items.Add(("Health Bar", ESP.HealthBar));
                    _items.Add(("Name", ESP.NameESP));
                    _items.Add(("Distance", ESP.DistanceESP));
                    _items.Add(("Head Circle", ESP.HeadCircle));
                    _items.Add(("Max Distance", ESP.MaxDistance));
                    break;
                case 1:
                    _items.Add(("Enable", Aimbot.Enabled));
                    _items.Add(("Visible Only", Aimbot.VisibleOnly));
                    _items.Add(("Team Check", Aimbot.TeamCheck));
                    _items.Add(("Humanized", Aimbot.HumanizedAim));
                    _items.Add(("Prediction", Aimbot.EnablePrediction));
                    _items.Add(("Headshot Priority", Aimbot.HeadshotPriority));
                    _items.Add(("FOV", Aimbot.FOV));
                    _items.Add(("Smooth X", Aimbot.SmoothX));
                    _items.Add(("Smooth Y", Aimbot.SmoothY));
                    _items.Add(("Aim Bone", Aimbot.AimBone));
                    _items.Add(("Max Distance", Aimbot.MaxDistance));
                    break;
                case 2:
                    _items.Add(("Enable", Triggerbot.Enabled));
                    _items.Add(("Visible Only", Triggerbot.VisibleOnly));
                    _items.Add(("Team Check", Triggerbot.TeamCheck));
                    _items.Add(("Headshot Only", Triggerbot.HeadshotOnly));
                    _items.Add(("Fire Mode", Triggerbot.FireMode));
                    _items.Add(("Reaction Delay", Triggerbot.ReactionDelay));
                    break;
                case 3:
                    _items.Add(("Enable", Spinbot.Enabled));
                    _items.Add(("Show Angles", Spinbot.ShowAngles));
                    _items.Add(("Spin Mode", Spinbot.SpinMode));
                    _items.Add(("Spin Speed", Spinbot.SpinSpeed));
                    break;
                case 4:
                    _items.Add(("Enable", Radar.Enabled));
                    _items.Add(("Show Enemies", Radar.ShowEnemies));
                    _items.Add(("Show Teammates", Radar.ShowTeammates));
                    _items.Add(("Show Bots", Radar.ShowBots));
                    _items.Add(("Snap Lines", Radar.ShowSnapLines));
                    _items.Add(("Direction Arrows", Radar.ShowDirectionArrows));
                    _items.Add(("Player Names", Radar.ShowPlayerNames));
                    _items.Add(("Player Health", Radar.ShowPlayerHealth));
                    _items.Add(("Rotate With View", Radar.RotateRadar));
                    _items.Add(("Radar Size", Radar.RadarSize));
                    break;
                case 5:
                    _items.Add(("Enable", FakeLag.Enabled));
                    _items.Add(("Toggle Mode", FakeLag.ToggleMode));
                    _items.Add(("Freeze Duration", FakeLag.FreezeDuration));
                    _items.Add(("Freeze Radius", FakeLag.FreezeRadius));
                    _items.Add(("Shots Per Freeze", FakeLag.ShotsPerFreeze));
                    break;
                case 6:
                    _items.Add(("Enable", AimKill.Enabled));
                    _items.Add(("Auto Kill", AimKill.AutoKill));
                    _items.Add(("Headshot Only", AimKill.HeadshotOnly));
                    _items.Add(("Instant Kill", AimKill.InstantKill));
                    _items.Add(("Critical Hit", AimKill.CriticalHit));
                    _items.Add(("Base Damage", AimKill.BaseDamage));
                    break;
                case 7:
                    _items.Add(("Enable", AIAim.Enabled));
                    _items.Add(("Predict Movement", AIAim.PredictMovement));
                    _items.Add(("Humanized", AIAim.Humanized));
                    _items.Add(("Fire Mode", AIAim.FireMode));
                    _items.Add(("Max Distance", AIAim.MaxDistance));
                    break;
                case 8:
                    _items.Add(("No Recoil", NoRecoil.Enabled));
                    _items.Add(("No Spread", NoSpread.Enabled));
                    _items.Add(("Fast Reload", FastReload.Enabled));
                    _items.Add(("Rapid Fire", RapidFire.Enabled));
                    _items.Add(("Magic Bullet", MagicBullet.Enabled));
                    _items.Add(("Damage Multiplier", DamageMultiplier.Enabled));
                    _items.Add(("Infinite Jump", InfiniteJump.Enabled));
                    _items.Add(("Speedhack", Speedhack.Enabled));
                    break;
                case 9:
                    _items.Add(("Wallhack", Wallhack.Enabled));
                    _items.Add(("Chams", Chams.Enabled));
                    _items.Add(("Head Expander", HeadExpander.Enabled));
                    _items.Add(("ESP Glow", ESPGlow.Enabled));
                    _items.Add(("Ammo ESP", AmmoESP.Enabled));
                    _items.Add(("Skin ESP", SkinESP.Enabled));
                    _items.Add(("Scope Overlay", ScopeOverlay.Enabled));
                    _items.Add(("Crosshair Overlay", CrosshairOverlay.Enabled));
                    _items.Add(("120 FPS Unlock", FPSUnlocker.Enabled));
                    _items.Add(("Gold Body", GoldBody.Enabled));
                    break;
                case 10:
                    _items.Add(("Anti Detect", AntiDetect.Enabled));
                    _items.Add(("Anti Cheat Bypass", AntiCheatBypass.Enabled));
                    _items.Add(("Emulator Bypass", EmulatorBypass.Enabled));
                    _items.Add(("Stream Proof", StreamProof.Enabled));
                    _items.Add(("Device Spoof", DeviceSpoof.Enabled));
                    _items.Add(("ISP Spoof", ISPSpoof.Enabled));
                    _items.Add(("SIM Card Spoof", SIMCardSpoof.Enabled));
                    _items.Add(("Battery Spoof", BatterySpoof.Enabled));
                    _items.Add(("Sensor Spoof", SensorSpoof.Enabled));
                    _items.Add(("GPS Spoof", GPSSpoof.Enabled));
                    _items.Add(("WiFi Spoof", WiFiSpoof.Enabled));
                    _items.Add(("Bluetooth Spoof", BluetoothSpoof.Enabled));
                    _items.Add(("NFC Spoof", NFCSpoof.Enabled));
                    break;
                case 11:
                    _items.Add(("CPU Cores", Environment.ProcessorCount));
                    _items.Add(("Memory MB", GC.GetTotalMemory(false) / 1024 / 1024));
                    break;
            }
            if (_selectedItem >= _items.Count) _selectedItem = Math.Max(0, _items.Count - 1);
            return _items;
        }

        // ═══════════════════════════════════════════════════════════
        // Toggle
        // ═══════════════════════════════════════════════════════════
        private static void ToggleCurrent()
        {
            if (_selectedItem >= _items.Count) return;
            if (_items[_selectedItem].Item2 == null || _items[_selectedItem].Item2 is not bool) return;
            try
            {
                switch (_selectedTab)
                {
                    case 0: ToggleESP(_selectedItem); break;
                    case 1: ToggleAimbot(_selectedItem); break;
                    case 2: ToggleTriggerbot(_selectedItem); break;
                    case 3: ToggleSpinbot(_selectedItem); break;
                    case 4: ToggleRadar(_selectedItem); break;
                    case 5: ToggleFakeLag(_selectedItem); break;
                    case 6: ToggleAimKill(_selectedItem); break;
                    case 7: ToggleAIAim(_selectedItem); break;
                    case 8: ToggleCombat(_selectedItem); break;
                    case 9: ToggleVisual(_selectedItem); break;
                    case 10: ToggleAntiDetect(_selectedItem); break;
                }
            }
            catch { }
        }

        private static void ToggleESP(int i) { switch (i) { case 0: ESP.PlayerESP = !ESP.PlayerESP; break; case 1: ESP.BoxESP = !ESP.BoxESP; break; case 2: ESP.HealthBar = !ESP.HealthBar; break; case 3: ESP.NameESP = !ESP.NameESP; break; case 4: ESP.DistanceESP = !ESP.DistanceESP; break; case 5: ESP.HeadCircle = !ESP.HeadCircle; break; } }
        private static void ToggleAimbot(int i) { switch (i) { case 0: Aimbot.Enabled = !Aimbot.Enabled; break; case 1: Aimbot.VisibleOnly = !Aimbot.VisibleOnly; break; case 2: Aimbot.TeamCheck = !Aimbot.TeamCheck; break; case 3: Aimbot.HumanizedAim = !Aimbot.HumanizedAim; break; case 4: Aimbot.EnablePrediction = !Aimbot.EnablePrediction; break; case 5: Aimbot.HeadshotPriority = !Aimbot.HeadshotPriority; break; } }
        private static void ToggleTriggerbot(int i) { switch (i) { case 0: Triggerbot.Enabled = !Triggerbot.Enabled; break; case 1: Triggerbot.VisibleOnly = !Triggerbot.VisibleOnly; break; case 2: Triggerbot.TeamCheck = !Triggerbot.TeamCheck; break; case 3: Triggerbot.HeadshotOnly = !Triggerbot.HeadshotOnly; break; } }
        private static void ToggleSpinbot(int i) { switch (i) { case 0: Spinbot.Enabled = !Spinbot.Enabled; break; case 1: Spinbot.ShowAngles = !Spinbot.ShowAngles; break; } }
        private static void ToggleRadar(int i) { switch (i) { case 0: Radar.Enabled = !Radar.Enabled; break; case 1: Radar.ShowEnemies = !Radar.ShowEnemies; break; case 2: Radar.ShowTeammates = !Radar.ShowTeammates; break; case 3: Radar.ShowBots = !Radar.ShowBots; break; case 4: Radar.ShowSnapLines = !Radar.ShowSnapLines; break; case 5: Radar.ShowDirectionArrows = !Radar.ShowDirectionArrows; break; case 6: Radar.ShowPlayerNames = !Radar.ShowPlayerNames; break; case 7: Radar.ShowPlayerHealth = !Radar.ShowPlayerHealth; break; case 8: Radar.RotateRadar = !Radar.RotateRadar; break; } }
        private static void ToggleFakeLag(int i) { switch (i) { case 0: FakeLag.Enabled = !FakeLag.Enabled; break; case 1: FakeLag.ToggleMode = !FakeLag.ToggleMode; break; } }
        private static void ToggleAimKill(int i) { switch (i) { case 0: AimKill.Enabled = !AimKill.Enabled; break; case 1: AimKill.AutoKill = !AimKill.AutoKill; break; case 2: AimKill.HeadshotOnly = !AimKill.HeadshotOnly; break; case 3: AimKill.InstantKill = !AimKill.InstantKill; break; case 4: AimKill.CriticalHit = !AimKill.CriticalHit; break; } }
        private static void ToggleAIAim(int i) { switch (i) { case 0: AIAim.Enabled = !AIAim.Enabled; break; case 1: AIAim.PredictMovement = !AIAim.PredictMovement; break; case 2: AIAim.Humanized = !AIAim.Humanized; break; } }
        private static void ToggleCombat(int i) { switch (i) { case 0: NoRecoil.Enabled = !NoRecoil.Enabled; break; case 1: NoSpread.Enabled = !NoSpread.Enabled; break; case 2: FastReload.Enabled = !FastReload.Enabled; break; case 3: RapidFire.Enabled = !RapidFire.Enabled; break; case 4: MagicBullet.Enabled = !MagicBullet.Enabled; break; case 5: DamageMultiplier.Enabled = !DamageMultiplier.Enabled; break; case 6: InfiniteJump.Enabled = !InfiniteJump.Enabled; break; case 7: Speedhack.Enabled = !Speedhack.Enabled; break; } }
        private static void ToggleVisual(int i) { switch (i) { case 0: Wallhack.Enabled = !Wallhack.Enabled; break; case 1: Chams.Enabled = !Chams.Enabled; break; case 2: HeadExpander.Enabled = !HeadExpander.Enabled; break; case 3: ESPGlow.Enabled = !ESPGlow.Enabled; break; case 4: AmmoESP.Enabled = !AmmoESP.Enabled; break; case 5: SkinESP.Enabled = !SkinESP.Enabled; break; case 6: ScopeOverlay.Enabled = !ScopeOverlay.Enabled; break; case 7: CrosshairOverlay.Enabled = !CrosshairOverlay.Enabled; break; case 8: FPSUnlocker.Enabled = !FPSUnlocker.Enabled; break; case 9: GoldBody.Enabled = !GoldBody.Enabled; break; } }
        private static void ToggleAntiDetect(int i) { switch (i) { case 0: AntiDetect.Enabled = !AntiDetect.Enabled; break; case 1: AntiCheatBypass.Enabled = !AntiCheatBypass.Enabled; break; case 2: EmulatorBypass.Enabled = !EmulatorBypass.Enabled; break; case 3: StreamProof.Enabled = !StreamProof.Enabled; break; case 4: DeviceSpoof.Enabled = !DeviceSpoof.Enabled; break; case 5: ISPSpoof.Enabled = !ISPSpoof.Enabled; break; case 6: SIMCardSpoof.Enabled = !SIMCardSpoof.Enabled; break; case 7: BatterySpoof.Enabled = !BatterySpoof.Enabled; break; case 8: SensorSpoof.Enabled = !SensorSpoof.Enabled; break; case 9: GPSSpoof.Enabled = !GPSSpoof.Enabled; break; case 10: WiFiSpoof.Enabled = !WiFiSpoof.Enabled; break; case 11: BluetoothSpoof.Enabled = !BluetoothSpoof.Enabled; break; case 12: NFCSpoof.Enabled = !NFCSpoof.Enabled; break; } }
    }
}
