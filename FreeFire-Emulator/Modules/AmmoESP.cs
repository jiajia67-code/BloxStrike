using System;
using System.Collections.Generic;
using FreeFire_Emulator.Classes;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// Ammo ESP — 顯示敵人剩餘彈藥
    /// </summary>
    internal static class AmmoESP
    {
        public static bool Enabled = false;
        public static bool ShowCurrentAmmo = true;   // 顯示當前彈夾
        public static bool ShowReserveAmmo = false;   // 顯示備用彈藥
        public static bool ShowFireMode = false;      // 顯示射擊模式
        public static bool LowAmmoWarning = true;     // 低彈藥警告
        public static int LowAmmoThreshold = 10;      // 低彈藥閾值

        // Pattern: Ammo 讀取函式
        private static readonly byte[] Search = new byte[]
        {
            0xF0, 0x4F, 0x2D, 0xE9, 0x00, 0x00, 0xA0, 0xE1,
            0x08, 0x10, 0x90, 0xE5, 0x00, 0x00, 0x51, 0xE3,
            0x02, 0x00, 0x00, 0x1A, 0x0C, 0x10, 0x90, 0xE5,
            0x00, 0x00, 0x51, 0xE3, 0x03, 0x00, 0x00, 0x1A
        };

        // Replacement: 強制顯示彈藥
        private static readonly byte[] Replace = new byte[]
        {
            0x00, 0x00, 0xA0, 0xE3, 0x1E, 0xFF, 0x2F, 0xE1,
            0x08, 0x10, 0x90, 0xE5, 0x00, 0x00, 0x51, 0xE3,
            0x02, 0x00, 0x00, 0x1A, 0x0C, 0x10, 0x90, 0xE5,
            0x00, 0x00, 0x51, 0xE3, 0x03, 0x00, 0x00, 0x1A
        };

        private static readonly List<long> FoundAddresses = new List<long>();
        private static bool PatternSearched = false;

        public static void FindPattern(Memory mem)
        {
            if (PatternSearched) return;
            FoundAddresses.Clear();
            Console.WriteLine("[AmmoESP] Searching for ammo pattern...");
            long[] results = mem.FindPatternAll(Search);
            if (results != null && results.Length > 0)
            {
                FoundAddresses.AddRange(results);
                Console.WriteLine($"[AmmoESP] Found {FoundAddresses.Count} pattern(s)");
            }
            else Console.WriteLine("[AmmoESP] Pattern not found");
            PatternSearched = true;
        }

        public static bool ApplyPatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Replace)) c++; }
            Console.WriteLine($"[AmmoESP] Applied to {c}/{FoundAddresses.Count}");
            return c > 0;
        }

        public static bool RemovePatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Search)) c++; }
            Console.WriteLine($"[AmmoESP] Restored {c}/{FoundAddresses.Count}");
            return c > 0;
        }

        /// <summary>
        /// 取得彈藥顯示文字
        /// </summary>
        public static string GetAmmoText(int currentAmmo, int maxAmmo)
        {
            string text = $"{currentAmmo}/{maxAmmo}";

            if (LowAmmoWarning && currentAmmo <= LowAmmoThreshold)
            {
                text += " LOW!";
            }

            return text;
        }

        /// <summary>
        /// 取得射擊模式文字
        /// </summary>
        public static string GetFireModeText(int fireMode)
        {
            return fireMode switch
            {
                0 => "Single",
                1 => "Auto",
                2 => "Burst",
                _ => "Unknown"
            };
        }
    }
}
