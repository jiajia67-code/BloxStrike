using System;
using System.Collections.Generic;
using FreeFire_Emulator.Classes;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// Guest Reset — 重設遊客帳號
    /// </summary>
    internal static class GuestReset
    {
        public static bool Enabled = false;

        private static readonly byte[] Search = new byte[]
        {
            0x10, 0x40, 0x2D, 0xE9, 0xD0, 0x40, 0x9F, 0xE5,
            0x04, 0x40, 0x8F, 0xE0, 0x00, 0x00, 0xD4, 0xE5,
            0x00, 0x00, 0x50, 0xE3, 0x04, 0x00, 0x00, 0x1A,
            0xC0, 0x00, 0x9F, 0xE5, 0x00, 0x00, 0x9F, 0xE7,
            0xA9, 0x36, 0xA9, 0xEB, 0x01
        };

        private static readonly byte[] Replace = new byte[]
        {
            0x10, 0x40, 0xA0, 0xE3, 0x1E, 0xFF, 0x2F, 0xE1,
            0x04, 0x40, 0x8F, 0xE0, 0x00, 0x00, 0xD4, 0xE5,
            0x00, 0x00, 0x50, 0xE3, 0x04, 0x00, 0x00, 0x1A,
            0xC0, 0x00, 0x9F, 0xE5, 0x00, 0x00, 0x9F, 0xE7,
            0xA9, 0x36, 0xA9, 0xEB, 0x01
        };

        private static readonly List<long> FoundAddresses = new List<long>();
        private static bool PatternSearched = false;

        public static void FindPattern(Memory mem)
        {
            if (PatternSearched) return;
            FoundAddresses.Clear();
            Console.WriteLine("[GuestReset] Searching for guest reset pattern...");
            long[] results = mem.FindPatternAll(Search);
            if (results != null && results.Length > 0)
            {
                FoundAddresses.AddRange(results);
                Console.WriteLine($"[GuestReset] Found {FoundAddresses.Count} pattern(s)");
            }
            else Console.WriteLine("[GuestReset] Pattern not found");
            PatternSearched = true;
        }

        public static bool ApplyPatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Replace)) c++; }
            Console.WriteLine($"[GuestReset] Applied to {c}/{FoundAddresses.Count}");
            return c > 0;
        }

        public static bool RemovePatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Search)) c++; }
            Console.WriteLine($"[GuestReset] Restored {c}/{FoundAddresses.Count}");
            return c > 0;
        }
    }
}
