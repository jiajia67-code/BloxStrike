using System;
using System.Collections.Generic;
using FreeFire_Emulator.Classes;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// HD Map — 高清地圖
    /// </summary>
    internal static class HDMap
    {
        public static bool Enabled = false;

        private static readonly byte[] Search = new byte[]
        {
            0x88, 0x00, 0xD0, 0xE5, 0x1E, 0xFF, 0x2F, 0xE1,
            0x88, 0x10, 0xC0, 0xE5, 0x1E, 0xFF, 0x2F, 0xE1,
            0x8C, 0x00, 0x90, 0xE5, 0x1E, 0xFF, 0x2F, 0xE1,
            0x8C, 0x10, 0x80, 0xE5, 0x1E, 0xFF, 0x2F, 0xE1,
            0x90, 0x00, 0x90, 0xE5, 0x1E, 0xFF, 0x2F, 0xE1,
            0x90, 0x10, 0x80, 0xE5, 0x1E, 0xFF, 0x2F, 0xE1
        };

        private static readonly byte[] Replace = new byte[]
        {
            0x88, 0x00, 0xA0, 0xE3, 0x1E, 0xFF, 0x2F, 0xE1,
            0x88, 0x10, 0xC0, 0xE5, 0x1E, 0xFF, 0x2F, 0xE1,
            0x8C, 0x00, 0x90, 0xE5, 0x1E, 0xFF, 0x2F, 0xE1,
            0x8C, 0x10, 0x80, 0xE5, 0x1E, 0xFF, 0x2F, 0xE1,
            0x90, 0x00, 0x90, 0xE5, 0x1E, 0xFF, 0x2F, 0xE1,
            0x90, 0x10, 0x80, 0xE5, 0x1E, 0xFF, 0x2F, 0xE1
        };

        private static readonly List<long> FoundAddresses = new List<long>();
        private static bool PatternSearched = false;

        public static void FindPattern(Memory mem)
        {
            if (PatternSearched) return;
            FoundAddresses.Clear();
            Console.WriteLine("[HDMap] Searching for HD map pattern...");
            long[] results = mem.FindPatternAll(Search);
            if (results != null && results.Length > 0)
            {
                FoundAddresses.AddRange(results);
                Console.WriteLine($"[HDMap] Found {FoundAddresses.Count} pattern(s)");
            }
            else Console.WriteLine("[HDMap] Pattern not found");
            PatternSearched = true;
        }

        public static bool ApplyPatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Replace)) c++; }
            Console.WriteLine($"[HDMap] Applied to {c}/{FoundAddresses.Count}");
            return c > 0;
        }

        public static bool RemovePatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Search)) c++; }
            Console.WriteLine($"[HDMap] Restored {c}/{FoundAddresses.Count}");
            return c > 0;
        }
    }
}
