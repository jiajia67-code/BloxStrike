using System;
using System.Collections.Generic;
using FreeFire_Emulator.Classes;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// No Delay — 無延遲（取消技能/動作冷卻）
    /// </summary>
    internal static class NoDelay
    {
        public static bool Enabled = false;

        private static readonly byte[] Search = new byte[]
        {
            0x30, 0x48, 0x2D, 0xE9, 0x28, 0x42, 0x9F, 0xE5,
            0x04, 0x40, 0x8F, 0xE0, 0x00, 0x00, 0xD4, 0xE5,
            0x00, 0x00, 0x50, 0xE3, 0x04, 0x00, 0x00, 0x1A,
            0x18, 0x02, 0x9F, 0xE5, 0x00, 0x00, 0x9F, 0xE7,
            0xB1, 0x33, 0xBE, 0xEB, 0x01, 0x00, 0xA0, 0xE3,
            0x00, 0x00, 0xC4, 0xE5, 0x26, 0x05, 0x07, 0xE3
        };

        private static readonly byte[] Replace = new byte[]
        {
            0x30, 0x48, 0xA0, 0xE3, 0x1E, 0xFF, 0x2F, 0xE1,
            0x04, 0x40, 0x8F, 0xE0, 0x00, 0x00, 0xD4, 0xE5,
            0x00, 0x00, 0x50, 0xE3, 0x04, 0x00, 0x00, 0x1A,
            0x18, 0x02, 0x9F, 0xE5, 0x00, 0x00, 0x9F, 0xE7,
            0xB1, 0x33, 0xBE, 0xEB, 0x01, 0x00, 0xA0, 0xE3,
            0x00, 0x00, 0xC4, 0xE5, 0x26, 0x05, 0x07, 0xE3
        };

        private static readonly List<long> FoundAddresses = new List<long>();
        private static bool PatternSearched = false;

        public static void FindPattern(Memory mem)
        {
            if (PatternSearched) return;
            FoundAddresses.Clear();
            Console.WriteLine("[NoDelay] Searching for no delay pattern...");
            long[] results = mem.FindPatternAll(Search);
            if (results != null && results.Length > 0)
            {
                FoundAddresses.AddRange(results);
                Console.WriteLine($"[NoDelay] Found {FoundAddresses.Count} pattern(s)");
            }
            else Console.WriteLine("[NoDelay] Pattern not found");
            PatternSearched = true;
        }

        public static bool ApplyPatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Replace)) c++; }
            Console.WriteLine($"[NoDelay] Applied to {c}/{FoundAddresses.Count}");
            return c > 0;
        }

        public static bool RemovePatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Search)) c++; }
            Console.WriteLine($"[NoDelay] Restored {c}/{FoundAddresses.Count}");
            return c > 0;
        }
    }
}
