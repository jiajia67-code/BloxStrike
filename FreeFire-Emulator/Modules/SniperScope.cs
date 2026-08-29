using System;
using System.Collections.Generic;
using FreeFire_Emulator.Classes;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// Sniper Scope — 狙擊鏡修改（自訂鏡頭參數）
    /// </summary>
    internal static class SniperScope
    {
        public static bool Enabled = false;

        // S: 搜尋 bytes — 原始 sniper scope 資料表
        private static readonly byte[] Search = new byte[]
        {
            0xF4, 0xA5, 0x03, 0x00, 0xF9, 0xA5, 0x03, 0x00,
            0xF4, 0xA5, 0x03, 0x00, 0x01, 0x00, 0x00, 0x00,
            0x9A, 0x99, 0x99, 0x3E, 0xFF, 0xFF, 0xFF, 0xFF,
            0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x60, 0x40,
            0xCD, 0xCC, 0x8C, 0x3F, 0x8F, 0xC2, 0xF5, 0x3C,
            0xCD, 0xCC, 0xCC, 0x3D, 0x06, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x19, 0x3F, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00
        };

        // R: 替換 bytes — 修改後的 scope 資料表
        private static readonly byte[] Replace = new byte[]
        {
            0xF4, 0xA5, 0x03, 0x00, 0xF9, 0xA5, 0x03, 0x00,
            0xF4, 0xA5, 0x03, 0x00, 0x01, 0x00, 0x00, 0x00,
            0x9A, 0x99, 0x99, 0x3E, 0xFF, 0xFF, 0xFF, 0xFF,
            0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x60, 0x40,
            0xCD, 0xCC, 0x8C, 0x3F, 0x8F, 0xC2, 0xF5, 0x3C,
            0xCD, 0xCC, 0xCC, 0x3D, 0x06, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x19, 0x3F, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00
        };

        private static readonly List<long> FoundAddresses = new List<long>();
        private static bool PatternSearched = false;

        public static void FindPattern(Memory mem)
        {
            if (PatternSearched) return;
            FoundAddresses.Clear();
            Console.WriteLine("[SniperScope] Searching for sniper scope pattern...");
            long[] results = mem.FindPatternAll(Search);
            if (results != null && results.Length > 0)
            {
                FoundAddresses.AddRange(results);
                Console.WriteLine($"[SniperScope] Found {FoundAddresses.Count} pattern(s)");
            }
            else Console.WriteLine("[SniperScope] Pattern not found");
            PatternSearched = true;
        }

        public static bool ApplyPatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Replace)) c++; }
            Console.WriteLine($"[SniperScope] Applied to {c}/{FoundAddresses.Count}");
            return c > 0;
        }

        public static bool RemovePatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Search)) c++; }
            Console.WriteLine($"[SniperScope] Restored {c}/{FoundAddresses.Count}");
            return c > 0;
        }
    }
}
