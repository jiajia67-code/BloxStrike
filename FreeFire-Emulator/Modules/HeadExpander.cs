using System;
using System.Collections.Generic;
using FreeFire_Emulator.Classes;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// Head Hitbox Expander — 擴大頭部 hitbox
    /// 讓敵人更容易被爆頭
    /// </summary>
    internal static class HeadExpander
    {
        public static bool Enabled = false;
        public static float ExpanderScale = 1.5f; // 擴大倍率 (1.0-3.0)

        // Pattern: HeadCollider 讀取函式
        private static readonly byte[] Search = new byte[]
        {
            0xF0, 0x4F, 0x2D, 0xE9, 0x00, 0x10, 0xA0, 0xE1,
            0x08, 0x20, 0x91, 0xE5, 0x00, 0x00, 0x52, 0xE3,
            0x01, 0x00, 0x00, 0x0A, 0x0C, 0x00, 0x91, 0xE5,
            0x00, 0x00, 0x50, 0xE3, 0x01, 0x00, 0x00, 0x1A
        };

        // Replacement: 修改碰撞體大小
        private static readonly byte[] Replace = new byte[]
        {
            0x00, 0x00, 0xA0, 0xE3, 0x1E, 0xFF, 0x2F, 0xE1,
            0x08, 0x20, 0x91, 0xE5, 0x00, 0x00, 0x52, 0xE3,
            0x01, 0x00, 0x00, 0x0A, 0x0C, 0x00, 0x91, 0xE5,
            0x00, 0x00, 0x50, 0xE3, 0x01, 0x00, 0x00, 0x1A
        };

        private static readonly List<long> FoundAddresses = new List<long>();
        private static bool PatternSearched = false;

        public static void FindPattern(Memory mem)
        {
            if (PatternSearched) return;
            FoundAddresses.Clear();
            Console.WriteLine("[HeadExpander] Searching for head collider pattern...");
            long[] results = mem.FindPatternAll(Search);
            if (results != null && results.Length > 0)
            {
                FoundAddresses.AddRange(results);
                Console.WriteLine($"[HeadExpander] Found {FoundAddresses.Count} pattern(s)");
            }
            else Console.WriteLine("[HeadExpander] Pattern not found");
            PatternSearched = true;
        }

        public static bool ApplyPatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Replace)) c++; }
            Console.WriteLine($"[HeadExpander] Applied to {c}/{FoundAddresses.Count}");
            return c > 0;
        }

        public static bool RemovePatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Search)) c++; }
            Console.WriteLine($"[HeadExpander] Restored {c}/{FoundAddresses.Count}");
            return c > 0;
        }
    }
}
