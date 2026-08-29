using System;
using System.Collections.Generic;
using FreeFire_Emulator.Classes;

namespace FreeFire_Emulator.Modules
{
    internal static class GrenadeNuke
    {
        public static bool Enabled = false;
        public static float ExplosionRadiusMultiplier = 3.0f;
        public static float DamageMultiplier = 2.5f;

        private static readonly byte[] Search = new byte[]
        {
            0xF4, 0xA5, 0x03, 0x00, 0xF9, 0xA5, 0x03, 0x00,
            0xF4, 0xA5, 0x03, 0x00, 0x01, 0x00, 0x00, 0x00,
            0x9A, 0x99, 0x99, 0x3E, 0xFF, 0xFF, 0xFF, 0xFF
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
            Console.WriteLine($"[GrenadeNuke] Found {FoundAddresses.Count} addresses");
        }

        public static bool ApplyPatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Search)) c++; }
            Console.WriteLine($"[GrenadeNuke] Applied to {c}/{FoundAddresses.Count}");
            return c > 0;
        }

        public static bool RemovePatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Search)) c++; }
            Console.WriteLine($"[GrenadeNuke] Restored {c}/{FoundAddresses.Count}");
            return c > 0;
        }
    }
}
