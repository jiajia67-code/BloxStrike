using System;
using System.Collections.Generic;
using FreeFire_Emulator.Classes;

namespace FreeFire_Emulator.Modules
{
    internal static class AutoScope
    {
        public static bool Enabled = false;
        public static float ScopeDelay = 0.1f;
        public static bool AutoUnscope = false;
        public static bool OnlySnipers = true;

        private static readonly byte[] Search = new byte[]
        {
            0x30, 0x48, 0x2D, 0xE9, 0x28, 0x42, 0x9F, 0xE5,
            0x04, 0x40, 0x8F, 0xE0, 0x00, 0x00, 0xD4, 0xE5,
            0x00, 0x00, 0x50, 0xE3, 0x04, 0x00, 0x00, 0x1A
        };
        // ARM64: MOV W0, #0; RET (auto scope)
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
            Console.WriteLine($"[AutoScope] Found {FoundAddresses.Count} addresses");
        }

        public static bool ApplyPatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Replace)) c++; }
            Console.WriteLine($"[AutoScope] Applied to {c}/{FoundAddresses.Count}");
            return c > 0;
        }

        public static bool RemovePatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Search)) c++; }
            Console.WriteLine($"[AutoScope] Restored {c}/{FoundAddresses.Count}");
            return c > 0;
        }
    }
}
