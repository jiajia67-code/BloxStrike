using System;
using System.Collections.Generic;
using FreeFire_Emulator.Classes;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// Rapid Fire — 提高射速
    /// </summary>
    internal static class RapidFire
    {
        public static bool Enabled = false;
        public static float FireRateScale = 0.5f; // 射速倍率 (0.1-1.0, 越小越快)

        private static readonly byte[] Search = new byte[]
        {
            0xF0, 0x4F, 0x2D, 0xE9, 0x00, 0x00, 0xA0, 0xE1,
            0x08, 0x10, 0x90, 0xE5, 0x00, 0x10, 0x90, 0xE5,
            0x00, 0x00, 0x51, 0xE3, 0x02, 0x00, 0x00, 0x1A,
            0x0C, 0x20, 0x90, 0xE5, 0x00, 0x00, 0x52, 0xE3
        };
        private static readonly byte[] Replace = new byte[]
        {
            0x00, 0x00, 0xA0, 0xE3, 0x1E, 0xFF, 0x2F, 0xE1,
            0x08, 0x10, 0x90, 0xE5, 0x00, 0x10, 0x90, 0xE5,
            0x00, 0x00, 0x51, 0xE3, 0x02, 0x00, 0x00, 0x1A,
            0x0C, 0x20, 0x90, 0xE5, 0x00, 0x00, 0x52, 0xE3
        };
        private static readonly List<long> FoundAddresses = new();
        private static bool PatternSearched = false;

        public static void FindPattern(Memory mem)
        {
            if (PatternSearched) return;
            FoundAddresses.Clear();
            long[] results = mem.FindPatternAll(Search);
            if (results != null && results.Length > 0) FoundAddresses.AddRange(results);
            PatternSearched = true;
        }
        public static bool ApplyPatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Replace)) c++; }
            Console.WriteLine($"[RapidFire] Applied to {c}/{FoundAddresses.Count}");
            return c > 0;
        }
        public static bool RemovePatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Search)) c++; }
            Console.WriteLine($"[RapidFire] Restored {c}/{FoundAddresses.Count}");
            return c > 0;
        }
    }
}
