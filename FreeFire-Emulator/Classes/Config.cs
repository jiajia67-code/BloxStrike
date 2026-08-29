using System;
using System.IO;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace FreeFire_Emulator.Classes
{
    /// <summary>
    /// Config System — 設定檔儲存/載入
    /// </summary>
    internal static class Config
    {
        private static string ConfigPath = "FreeFire_Config.json";

        // ── 設定結構 ──
        public class Settings
        {
            // ESP
            public bool ESP_Enabled { get; set; } = false;
            public bool ESP_Box { get; set; } = true;
            public bool ESP_Health { get; set; } = true;
            public bool ESP_Name { get; set; } = true;
            public bool ESP_Distance { get; set; } = true;
            public bool ESP_HeadCircle { get; set; } = false;
            public bool ESP_Skeleton { get; set; } = false;
            public bool ESP_Snaplines { get; set; } = false;

            // Aimbot
            public bool Aimbot_Enabled { get; set; } = false;
            public float Aimbot_FOV { get; set; } = 120f;
            public float Aimbot_Smooth { get; set; } = 8f;
            public bool Aimbot_VisibleOnly { get; set; } = true;
            public int Aimbot_Bone { get; set; } = 0;

            // Aim Assist
            public bool AimAssist_Enabled { get; set; } = false;
            public float AimAssist_FOV { get; set; } = 120f;
            public float AimAssist_Smooth { get; set; } = 8f;
            public float AimAssist_Strength { get; set; } = 0.6f;

            // NoRecoil
            public bool NoRecoil_Enabled { get; set; } = false;
            public float NoRecoil_Scale { get; set; } = 0f;

            // Fast Reload
            public bool FastReload_Enabled { get; set; } = false;
            public bool FastReload_Switch { get; set; } = false;

            // Spinbot
            public bool Spinbot_Enabled { get; set; } = false;
            public int Spinbot_Mode { get; set; } = 0;
            public float Spinbot_Speed { get; set; } = 360f;

            // Anti-Aim
            public bool AntiAim_Enabled { get; set; } = false;
            public int AntiAim_Mode { get; set; } = 0;
            public float AntiAim_YawOffset { get; set; } = 0f;
            public float AntiAim_Pitch { get; set; } = -89f;

            // ESP Glow
            public bool ESPGlow_Enabled { get; set; } = false;

            // Radar
            public bool Radar_Enabled { get; set; } = false;
            public float Radar_Size { get; set; } = 200f;
            public float Radar_Range { get; set; } = 2000f;

            // Chams
            public bool Chams_Enabled { get; set; } = false;

            // Triggerbot
            public bool Triggerbot_Enabled { get; set; } = false;
            public bool Triggerbot_VisibleOnly { get; set; } = true;

            // Misc
            public bool Speedhack_Enabled { get; set; } = false;
            public float Speedhack_Speed { get; set; } = 2f;
            public bool Wallhack_Enabled { get; set; } = false;
            public bool FPS120_Enabled { get; set; } = false;
            public bool StreamProof_Enabled { get; set; } = false;

            // Version
            public int Version { get; set; } = 1;
        }

        private static Settings currentSettings = new Settings();
        private static bool isLoaded = false;

        /// <summary>
        /// 載入設定
        /// </summary>
        public static Settings Load()
        {
            try
            {
                if (File.Exists(ConfigPath))
                {
                    string json = File.ReadAllText(ConfigPath);
                    currentSettings = JsonSerializer.Deserialize<Settings>(json) ?? new Settings();
                    isLoaded = true;
                    Console.WriteLine($"[Config] Loaded from {ConfigPath}");
                }
                else
                {
                    currentSettings = new Settings();
                    Console.WriteLine("[Config] Using default settings");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Config] Load error: {ex.Message}");
                currentSettings = new Settings();
            }

            return currentSettings;
        }

        /// <summary>
        /// 儲存設定
        /// </summary>
        public static void Save()
        {
            try
            {
                // 從各模組同步設定
                SyncFromModules();

                string json = JsonSerializer.Serialize(currentSettings, new JsonSerializerOptions
                {
                    WriteIndented = true
                });
                File.WriteAllText(ConfigPath, json);
                Console.WriteLine($"[Config] Saved to {ConfigPath}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Config] Save error: {ex.Message}");
            }
        }

        /// <summary>
        /// 套用設定到各模組
        /// </summary>
        public static void ApplyToModules()
        {
            try
            {
                // ESP
                Modules.ESP.PlayerESP = currentSettings.ESP_Enabled;
                Modules.ESP.BoxESP = currentSettings.ESP_Box;
                Modules.ESP.HealthBar = currentSettings.ESP_Health;
                Modules.ESP.NameESP = currentSettings.ESP_Name;
                Modules.ESP.DistanceESP = currentSettings.ESP_Distance;
                Modules.ESP.HeadCircle = currentSettings.ESP_HeadCircle;

                // Aimbot
                Modules.Aimbot.Enabled = currentSettings.Aimbot_Enabled;
                Modules.Aimbot.FOV = currentSettings.Aimbot_FOV;
                Modules.Aimbot.SmoothX = currentSettings.Aimbot_Smooth;
                Modules.Aimbot.SmoothY = currentSettings.Aimbot_Smooth;
                Modules.Aimbot.VisibleOnly = currentSettings.Aimbot_VisibleOnly;

                // Aim Assist
                Modules.AimAssist.Enabled = currentSettings.AimAssist_Enabled;
                Modules.AimAssist.FOV = currentSettings.AimAssist_FOV;
                Modules.AimAssist.Smooth = currentSettings.AimAssist_Smooth;
                Modules.AimAssist.AimStrength = currentSettings.AimAssist_Strength;

                // NoRecoil
                Modules.NoRecoil.Enabled = currentSettings.NoRecoil_Enabled;
                Modules.NoRecoil.RecoilScale = currentSettings.NoRecoil_Scale;

                // Fast Reload
                Modules.FastReload.Enabled = currentSettings.FastReload_Enabled;
                Modules.FastReload.FastWeaponSwitch = currentSettings.FastReload_Switch;

                // Spinbot
                Modules.Spinbot.Enabled = currentSettings.Spinbot_Enabled;
                Modules.Spinbot.SpinMode = currentSettings.Spinbot_Mode;
                Modules.Spinbot.SpinSpeed = currentSettings.Spinbot_Speed;

                // Anti-Aim
                Modules.AntiAim.Enabled = currentSettings.AntiAim_Enabled;
                Modules.AntiAim.Mode = currentSettings.AntiAim_Mode;
                Modules.AntiAim.YawOffset = currentSettings.AntiAim_YawOffset;
                Modules.AntiAim.PitchAngle = currentSettings.AntiAim_Pitch;

                // ESP Glow
                Modules.ESPGlow.Enabled = currentSettings.ESPGlow_Enabled;

                // Radar
                Modules.Radar.Enabled = currentSettings.Radar_Enabled;
                Modules.Radar.RadarSize = currentSettings.Radar_Size;
                Modules.Radar.RadarRange = currentSettings.Radar_Range;

                // Chams
                Modules.Chams.Enabled = currentSettings.Chams_Enabled;

                // Triggerbot
                Modules.Triggerbot.Enabled = currentSettings.Triggerbot_Enabled;
                Modules.Triggerbot.VisibleOnly = currentSettings.Triggerbot_VisibleOnly;

                // Misc
                Modules.Speedhack.Enabled = currentSettings.Speedhack_Enabled;
                Modules.Speedhack.SpeedMultiplier = currentSettings.Speedhack_Speed;
                Modules.Wallhack.Enabled = currentSettings.Wallhack_Enabled;
                Modules.FPSUnlocker.Enabled = currentSettings.FPS120_Enabled;
                Modules.StreamProof.Enabled = currentSettings.StreamProof_Enabled;

                Console.WriteLine("[Config] Settings applied to all modules");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Config] Apply error: {ex.Message}");
            }
        }

        /// <summary>
        /// 從各模組同步設定
        /// </summary>
        private static void SyncFromModules()
        {
            try
            {
                // ESP
                currentSettings.ESP_Enabled = Modules.ESP.PlayerESP;
                currentSettings.ESP_Box = Modules.ESP.BoxESP;
                currentSettings.ESP_Health = Modules.ESP.HealthBar;
                currentSettings.ESP_Name = Modules.ESP.NameESP;
                currentSettings.ESP_Distance = Modules.ESP.DistanceESP;
                currentSettings.ESP_HeadCircle = Modules.ESP.HeadCircle;

                // Aimbot
                currentSettings.Aimbot_Enabled = Modules.Aimbot.Enabled;
                currentSettings.Aimbot_FOV = Modules.Aimbot.FOV;
                currentSettings.Aimbot_Smooth = Modules.Aimbot.SmoothX;

                // Aim Assist
                currentSettings.AimAssist_Enabled = Modules.AimAssist.Enabled;
                currentSettings.AimAssist_FOV = Modules.AimAssist.FOV;
                currentSettings.AimAssist_Smooth = Modules.AimAssist.Smooth;
                currentSettings.AimAssist_Strength = Modules.AimAssist.AimStrength;

                // NoRecoil
                currentSettings.NoRecoil_Enabled = Modules.NoRecoil.Enabled;
                currentSettings.NoRecoil_Scale = Modules.NoRecoil.RecoilScale;

                // Fast Reload
                currentSettings.FastReload_Enabled = Modules.FastReload.Enabled;

                // Spinbot
                currentSettings.Spinbot_Enabled = Modules.Spinbot.Enabled;
                currentSettings.Spinbot_Mode = Modules.Spinbot.SpinMode;
                currentSettings.Spinbot_Speed = Modules.Spinbot.SpinSpeed;

                // Anti-Aim
                currentSettings.AntiAim_Enabled = Modules.AntiAim.Enabled;
                currentSettings.AntiAim_Mode = Modules.AntiAim.Mode;

                // ESP Glow
                currentSettings.ESPGlow_Enabled = Modules.ESPGlow.Enabled;

                // Radar
                currentSettings.Radar_Enabled = Modules.Radar.Enabled;

                // Chams
                currentSettings.Chams_Enabled = Modules.Chams.Enabled;

                // Triggerbot
                currentSettings.Triggerbot_Enabled = Modules.Triggerbot.Enabled;

                // Misc
                currentSettings.Speedhack_Enabled = Modules.Speedhack.Enabled;
                currentSettings.Speedhack_Speed = Modules.Speedhack.SpeedMultiplier;
                currentSettings.Wallhack_Enabled = Modules.Wallhack.Enabled;
                currentSettings.FPS120_Enabled = Modules.FPSUnlocker.Enabled;
                currentSettings.StreamProof_Enabled = Modules.StreamProof.Enabled;
            }
            catch { }
        }

        /// <summary>
        /// 取得當前設定
        /// </summary>
        public static Settings GetCurrentSettings()
        {
            if (!isLoaded) Load();
            return currentSettings;
        }
    }
}
