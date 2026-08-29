using System;
using System.Collections.Generic;
using FreeFire_Emulator.Classes;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// No Spread — 消除彈道散佈
    /// </summary>
    internal static class NoSpread
    {
        public static bool Enabled = false;

        // Pattern: tangentTheta (散佈角度)
        // Normal: tangentTheta = 0xC
        // 直接 patch 為 return 0
        private static readonly byte[] Search = new byte[]
        {
            0xF4, 0x4F, 0x2D, 0xE9, 0x00, 0x00, 0xA0, 0xE1,
            0x0C, 0x10, 0x90, 0xE5, 0x00, 0x00, 0x51, 0xE3,
            0x02, 0x00, 0x00, 0x1A, 0x30, 0x10, 0x9F, 0xE5,
            0x00, 0x20, 0xA0, 0xE3, 0x32, 0x03, 0x6E, 0xEB
        };

        // Replacement: MOV W0, #0; RET (return 0 = no spread)
        private static readonly byte[] Replace = new byte[]
        {
            0x00, 0x00, 0xA0, 0xE3, 0x1E, 0xFF, 0x2F, 0xE1,
            0x0C, 0x10, 0x90, 0xE5, 0x00, 0x00, 0x51, 0xE3,
            0x02, 0x00, 0x00, 0x1A, 0x30, 0x10, 0x9F, 0xE5,
            0x00, 0x20, 0xA0, 0xE3, 0x32, 0x03, 0x6E, 0xEB
        };

        private static readonly List<long> FoundAddresses = new List<long>();
        private static bool PatternSearched = false;

        public static void FindPattern(Memory mem)
        {
            if (PatternSearched) return;
            FoundAddresses.Clear();
            Console.WriteLine("[NoSpread] Searching for spread pattern...");
            long[] results = mem.FindPatternAll(Search);
            if (results != null && results.Length > 0)
            {
                FoundAddresses.AddRange(results);
                Console.WriteLine($"[NoSpread] Found {FoundAddresses.Count} pattern(s)");
                foreach (long a in FoundAddresses) Console.WriteLine($"[NoSpread]   0x{a:X}");
            }
            else Console.WriteLine("[NoSpread] Pattern not found");
            PatternSearched = true;
        }

        public static bool ApplyPatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Replace)) c++; }
            Console.WriteLine($"[NoSpread] Applied to {c}/{FoundAddresses.Count}");
            return c > 0;
        }

        public static bool RemovePatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Search)) c++; }
            Console.WriteLine($"[NoSpread] Restored {c}/{FoundAddresses.Count}");
            return c > 0;
        }
    }
}
