using System;
using System.Collections.Generic;
using FreeFire_Emulator.Classes;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// 120 FPS Unlocker — 解除幀率上限到 120 FPS
    /// </summary>
    internal static class FPSUnlocker
    {
        public static bool Enabled = false;

        // S: 搜尋 bytes
        private static readonly byte[] Search = new byte[]
        {
            0x30, 0x48, 0x2D, 0xE9, 0xA4, 0x40, 0x9F, 0xE5,
            0x04, 0x40, 0x8F, 0xE0, 0x00, 0x00, 0xD4, 0xE5,
            0x00, 0x00, 0x50, 0xE3, 0x04, 0x00, 0x00, 0x1A,
            0x94, 0x00, 0x9F, 0xE5, 0x00, 0x00, 0x9F, 0xE7,
            0x37, 0xC0, 0x95, 0xEB, 0x01, 0x00, 0xA0, 0xE3
        };

        // R: 替換 bytes
        private static readonly byte[] Replace = new byte[]
        {
            0x30, 0x48, 0xA0, 0xE3, 0x1E, 0xFF, 0x2F, 0xE1,
            0x04, 0x40, 0x8F, 0xE0, 0x00, 0x00, 0xD4, 0xE5,
            0x00, 0x00, 0x50, 0xE3, 0x04, 0x00, 0x00, 0x1A,
            0x94, 0x00, 0x9F, 0xE5, 0x00, 0x00, 0x9F, 0xE7,
            0x37, 0xC0, 0x95, 0xEB, 0x01, 0x00, 0xA0, 0xE3
        };

        private static readonly List<long> FoundAddresses = new List<long>();
        private static bool PatternSearched = false;

        public static void FindPattern(Memory mem)
        {
            if (PatternSearched) return;
            FoundAddresses.Clear();
            Console.WriteLine("[120FPS] Searching for FPS unlocker pattern...");
            long[] results = mem.FindPatternAll(Search);
            if (results != null && results.Length > 0)
            {
                FoundAddresses.AddRange(results);
                Console.WriteLine($"[120FPS] Found {FoundAddresses.Count} pattern(s)");
                foreach (long a in FoundAddresses) Console.WriteLine($"[120FPS]   0x{a:X}");
            }
            else Console.WriteLine("[120FPS] Pattern not found");
            PatternSearched = true;
        }

        public static bool ApplyPatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Replace)) c++; }
            Console.WriteLine($"[120FPS] Applied to {c}/{FoundAddresses.Count}");
            return c > 0;
        }

        public static bool RemovePatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Search)) c++; }
            Console.WriteLine($"[120FPS] Restored {c}/{FoundAddresses.Count}");
            return c > 0;
        }
    }
}
