using System;
using System.Collections.Generic;
using FreeFire_Emulator.Classes;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// Diamond Hack 999 — 鑽石 Hack
    /// </summary>
    internal static class DiamondHack
    {
        public static bool Enabled = false;

        private static readonly byte[] Search = new byte[]
        {
            0x30, 0x48, 0x2D, 0xE9, 0x00, 0x40, 0xA0, 0xE1,
            0x57, 0x02, 0x01, 0xE3, 0x00, 0x10, 0xA0, 0xE3,
            0x53, 0xEE, 0x8A, 0xEB, 0x00, 0x00, 0x50, 0xE3,
            0x0B, 0x00, 0x00, 0x0A, 0x57, 0x02, 0x01, 0xE3,
            0x00, 0x10, 0xA0, 0xE3, 0x52, 0xEE, 0x8A, 0xEB,
            0x00, 0x50, 0xA0, 0xE1, 0x00, 0x00, 0x50, 0xE3
        };

        // 注意: 替換 bytes 前 2 bytes 不同 (0x30→0x30, 0x48→0x48, 0x2D→0x00)
        private static readonly byte[] Replace = new byte[]
        {
            0x30, 0x48, 0x00, 0xE3, 0x1E, 0xFF, 0x2F, 0xE1,
            0x57, 0x02, 0x01, 0xE3, 0x00, 0x10, 0xA0, 0xE3,
            0x53, 0xEE, 0x8A, 0xEB, 0x00, 0x00, 0x50, 0xE3,
            0x0B, 0x00, 0x00, 0x0A, 0x57, 0x02, 0x01, 0xE3,
            0x00, 0x10, 0xA0, 0xE3, 0x52, 0xEE, 0x8A, 0xEB,
            0x00, 0x50, 0xA0, 0xE1, 0x00, 0x00, 0x50, 0xE3
        };

        private static readonly List<long> FoundAddresses = new List<long>();
        private static bool PatternSearched = false;

        public static void FindPattern(Memory mem)
        {
            if (PatternSearched) return;
            FoundAddresses.Clear();
            Console.WriteLine("[DiamondHack] Searching for diamond hack pattern...");
            long[] results = mem.FindPatternAll(Search);
            if (results != null && results.Length > 0)
            {
                FoundAddresses.AddRange(results);
                Console.WriteLine($"[DiamondHack] Found {FoundAddresses.Count} pattern(s)");
            }
            else Console.WriteLine("[DiamondHack] Pattern not found");
            PatternSearched = true;
        }

        public static bool ApplyPatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Replace)) c++; }
            Console.WriteLine($"[DiamondHack] Applied to {c}/{FoundAddresses.Count}");
            return c > 0;
        }

        public static bool RemovePatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Search)) c++; }
            Console.WriteLine($"[DiamondHack] Restored {c}/{FoundAddresses.Count}");
            return c > 0;
        }
    }
}
