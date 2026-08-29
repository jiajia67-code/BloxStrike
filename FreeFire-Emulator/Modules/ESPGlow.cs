using System;
using System.Collections.Generic;
using FreeFire_Emulator.Classes;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// ESP Glow — 玩家發光穿透牆壁
    /// </summary>
    internal static class ESPGlow
    {
        public static bool Enabled = false;

        // 設定
        public static bool EnemyOnly = true;       // 只對敵人發光
        public static bool TeamGlow = false;       // 隊友也發光
        public static float GlowIntensity = 1.0f;  // 發光強度

        // 發光顏色 (R, G, B)
        public static float EnemyR = 1.0f;
        public static float EnemyG = 0.0f;
        public static float EnemyB = 0.0f;
        public static float TeamR = 0.0f;
        public static float TeamG = 1.0f;
        public static float TeamB = 0.0f;

        // Pattern: Avatar_IsVisible 讀取
        // 修改讓所有玩家都「可見」
        private static readonly byte[] Search = new byte[]
        {
            0xF0, 0x4F, 0x2D, 0xE9, 0x00, 0x00, 0xA0, 0xE1,
            0x08, 0x10, 0x90, 0xE5, 0x00, 0x00, 0x51, 0xE3,
            0x01, 0x00, 0x00, 0x0A, 0x08, 0x00, 0xA0, 0xE3,
            0x01, 0x00, 0xA0, 0xE3, 0x1E, 0xFF, 0x2F, 0xE1
        };

        // Replacement: 強制 return 1 (可見)
        private static readonly byte[] Replace = new byte[]
        {
            0x00, 0x00, 0xA0, 0xE3, 0x1E, 0xFF, 0x2F, 0xE1,
            0x08, 0x10, 0x90, 0xE5, 0x00, 0x00, 0x51, 0xE3,
            0x01, 0x00, 0x00, 0x0A, 0x08, 0x00, 0xA0, 0xE3,
            0x01, 0x00, 0xA0, 0xE3, 0x1E, 0xFF, 0x2F, 0xE1
        };

        private static readonly List<long> FoundAddresses = new List<long>();
        private static bool PatternSearched = false;

        public static void FindPattern(Memory mem)
        {
            if (PatternSearched) return;
            FoundAddresses.Clear();
            Console.WriteLine("[ESPGlow] Searching for visibility pattern...");
            long[] results = mem.FindPatternAll(Search);
            if (results != null && results.Length > 0)
            {
                FoundAddresses.AddRange(results);
                Console.WriteLine($"[ESPGlow] Found {FoundAddresses.Count} pattern(s)");
            }
            else Console.WriteLine("[ESPGlow] Pattern not found");
            PatternSearched = true;
        }

        /// <summary>
        /// 套用 Glow（強制所有玩家可見）
        /// </summary>
        public static bool ApplyPatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Replace)) c++; }
            Console.WriteLine($"[ESPGlow] Applied to {c}/{FoundAddresses.Count}");
            return c > 0;
        }

        /// <summary>
        /// 還原 Glow
        /// </summary>
        public static bool RemovePatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Search)) c++; }
            Console.WriteLine($"[ESPGlow] Restored {c}/{FoundAddresses.Count}");
            return c > 0;
        }

        /// <summary>
        /// 取得敵人發光顏色
        /// </summary>
        public static (float r, float g, float b) GetEnemyColor()
        {
            return (EnemyR, EnemyG, EnemyB);
        }

        /// <summary>
        /// 取得隊友發光顏色
        /// </summary>
        public static (float r, float g, float b) GetTeamColor()
        {
            return (TeamR, TeamG, TeamB);
        }
    }
}
