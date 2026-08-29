using System;
using System.Collections.Generic;
using FreeFire_Emulator.Classes;

namespace FreeFire_Emulator.Modules
{
    internal static class InvisibleMode
    {
        public static bool Enabled = false;
        public static bool FullInvisible = true;
        public static bool OnlyWhenNotShooting = true;

        private static readonly byte[] Search = new byte[]
        {
            0x30, 0x48, 0x2D, 0xE9, 0x00, 0x40, 0xA0, 0xE1,
            0x41, 0x0C, 0x04, 0xE3, 0x00, 0x10, 0xA0, 0xE3,
            0x32, 0x13, 0x6E, 0xEB, 0x00, 0x00, 0x50, 0xE3
        };
        // ARM64: MOV W0, #0; RET (make invisible)
        private static readonly byte[] Replace = new byte[]
        {
            0xE3, 0xA0, 0x00, 0x00, 0xE1, 0x2F, 0xFF, 0x1E
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
            Console.WriteLine($"[InvisibleMode] Found {FoundAddresses.Count} addresses");
        }

        public static bool ApplyPatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Replace)) c++; }
            Console.WriteLine($"[InvisibleMode] Applied to {c}/{FoundAddresses.Count}");
            return c > 0;
        }

        public static bool RemovePatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Search)) c++; }
            Console.WriteLine($"[InvisibleMode] Restored {c}/{FoundAddresses.Count}");
            return c > 0;
        }
    }
}
