using System;
using System.Collections.Generic;
using FreeFire_Emulator.Classes;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// Gold Body — 金色身體效果
    /// </summary>
    internal static class GoldBody
    {
        public static bool Enabled = false;

        private static readonly byte[] Search = new byte[]
        {
            0x30, 0x48, 0x2D, 0xE9, 0x00, 0x40, 0xA0, 0xE1,
            0x41, 0x0C, 0x04, 0xE3, 0x00, 0x10, 0xA0, 0xE3,
            0x32, 0x13, 0x6E, 0xEB, 0x00, 0x00, 0x50, 0xE3,
            0x0B, 0x00, 0x00, 0x0A, 0x41, 0x0C, 0x04, 0xE3,
            0x00, 0x10, 0xA0, 0xE3, 0x61, 0x13, 0x6E, 0xEB,
            0x00, 0x50, 0xA0, 0xE1, 0x00, 0x00, 0x50, 0xE3
        };

        private static readonly byte[] Replace = new byte[]
        {
            0x30, 0x48, 0xA0, 0xE3, 0x1E, 0xFF, 0x2F, 0xE1,
            0x41, 0x0C, 0x04, 0xE3, 0x00, 0x10, 0xA0, 0xE3,
            0x32, 0x13, 0x6E, 0xEB, 0x00, 0x00, 0x50, 0xE3,
            0x0B, 0x00, 0x00, 0x0A, 0x41, 0x0C, 0x04, 0xE3,
            0x00, 0x10, 0xA0, 0xE3, 0x61, 0x13, 0x6E, 0xEB,
            0x00, 0x50, 0xA0, 0xE1, 0x00, 0x00, 0x50, 0xE3
        };

        private static readonly List<long> FoundAddresses = new List<long>();
        private static bool PatternSearched = false;

        public static void FindPattern(Memory mem)
        {
            if (PatternSearched) return;
            FoundAddresses.Clear();
            Console.WriteLine("[GoldBody] Searching for gold body pattern...");
            long[] results = mem.FindPatternAll(Search);
            if (results != null && results.Length > 0)
            {
                FoundAddresses.AddRange(results);
                Console.WriteLine($"[GoldBody] Found {FoundAddresses.Count} pattern(s)");
            }
            else Console.WriteLine("[GoldBody] Pattern not found");
            PatternSearched = true;
        }

        public static bool ApplyPatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Replace)) c++; }
            Console.WriteLine($"[GoldBody] Applied to {c}/{FoundAddresses.Count}");
            return c > 0;
        }

        public static bool RemovePatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Search)) c++; }
            Console.WriteLine($"[GoldBody] Restored {c}/{FoundAddresses.Count}");
            return c > 0;
        }
    }
}
