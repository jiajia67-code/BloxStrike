using System;
using System.Collections.Generic;
using FreeFire_Emulator.Classes;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// Bullet Drop — 子彈下墜補償（直線飛行）
    /// </summary>
    internal static class BulletDrop
    {
        public static bool Enabled = false;

        // Pattern: Bullet gravity calculation
        // 修改重力常數為 0，讓子彈直線飛行
        private static readonly byte[] Search = new byte[]
        {
            0xF0, 0x4F, 0x2D, 0xE9, 0x01, 0x0B, 0x2D, 0xED,
            0x00, 0x00, 0xA0, 0xE1, 0x04, 0x10, 0x90, 0xE5,
            0x08, 0x20, 0x90, 0xE5, 0x0C, 0x30, 0x90, 0xE5,
            0x00, 0x00, 0x51, 0xE3, 0x04, 0x00, 0x00, 0x0A
        };

        // Replacement: MOV W0, #0; RET (return 0 = no drop)
        private static readonly byte[] Replace = new byte[]
        {
            0x00, 0x00, 0xA0, 0xE3, 0x1E, 0xFF, 0x2F, 0xE1,
            0x00, 0x00, 0xA0, 0xE1, 0x04, 0x10, 0x90, 0xE5,
            0x08, 0x20, 0x90, 0xE5, 0x0C, 0x30, 0x90, 0xE5,
            0x00, 0x00, 0x51, 0xE3, 0x04, 0x00, 0x00, 0x0A
        };

        private static readonly List<long> FoundAddresses = new List<long>();
        private static bool PatternSearched = false;

        public static void FindPattern(Memory mem)
        {
            if (PatternSearched) return;
            FoundAddresses.Clear();
            Console.WriteLine("[BulletDrop] Searching for bullet drop pattern...");
            long[] results = mem.FindPatternAll(Search);
            if (results != null && results.Length > 0)
            {
                FoundAddresses.AddRange(results);
                Console.WriteLine($"[BulletDrop] Found {FoundAddresses.Count} pattern(s)");
                foreach (long a in FoundAddresses) Console.WriteLine($"[BulletDrop]   0x{a:X}");
            }
            else Console.WriteLine("[BulletDrop] Pattern not found");
            PatternSearched = true;
        }

        public static bool ApplyPatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Replace)) c++; }
            Console.WriteLine($"[BulletDrop] Applied to {c}/{FoundAddresses.Count}");
            return c > 0;
        }

        public static bool RemovePatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Search)) c++; }
            Console.WriteLine($"[BulletDrop] Restored {c}/{FoundAddresses.Count}");
            return c > 0;
        }
    }
}
