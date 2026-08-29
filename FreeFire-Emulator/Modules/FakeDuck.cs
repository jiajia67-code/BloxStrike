using System;
using System.Collections.Generic;
using FreeFire_Emulator.Classes;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// Fake Duck — 假蹲（快速蹲下又站起）
    /// 讓敵人以為你在蹲，但其實你在動
    /// </summary>
    internal static class FakeDuck
    {
        public static bool Enabled = false;
        public static float DuckSpeed = 0.15f; // 蹲下速度 (秒)
        public static bool OnlyWhenStanding = true; // 只在站立時觸發

        // Pattern: DuckAmount 寫入函式
        private static readonly byte[] Search = new byte[]
        {
            0xF0, 0x4F, 0x2D, 0xE9, 0x04, 0x00, 0xA0, 0xE1,
            0x00, 0x10, 0xA0, 0xE3, 0x08, 0x10, 0x80, 0xE5,
            0x0C, 0x10, 0x80, 0xE5, 0x10, 0x20, 0x80, 0xE5,
            0x00, 0xE8, 0xA0, 0xE1, 0xF0, 0x8F, 0xBD, 0xE8
        };

        // Replacement: 強制 duckAmount = 0 (站立)
        private static readonly byte[] Replace_Stand = new byte[]
        {
            0x00, 0x00, 0xA0, 0xE3, 0x1E, 0xFF, 0x2F, 0xE1,
            0x00, 0x10, 0xA0, 0xE3, 0x08, 0x10, 0x80, 0xE5,
            0x0C, 0x10, 0x80, 0xE5, 0x10, 0x20, 0x80, 0xE5,
            0x00, 0xE8, 0xA0, 0xE1, 0xF0, 0x8F, 0xBD, 0xE8
        };

        // Replacement: 強制 duckAmount = 1 (蹲下)
        private static readonly byte[] Replace_Duck = new byte[]
        {
            0x01, 0x00, 0xA0, 0xE3, 0x1E, 0xFF, 0x2F, 0xE1,
            0x00, 0x10, 0xA0, 0xE3, 0x08, 0x10, 0x80, 0xE5,
            0x0C, 0x10, 0x80, 0xE5, 0x10, 0x20, 0x80, 0xE5,
            0x00, 0xE8, 0xA0, 0xE1, 0xF0, 0x8F, 0xBD, 0xE8
        };

        private static readonly List<long> FoundAddresses = new List<long>();
        private static bool PatternSearched = false;

        // 狀態
        private static bool isDucked = false;
        private static float duckTimer = 0f;

        public static void FindPattern(Memory mem)
        {
            if (PatternSearched) return;
            FoundAddresses.Clear();
            Console.WriteLine("[FakeDuck] Searching for duck pattern...");
            long[] results = mem.FindPatternAll(Search);
            if (results != null && results.Length > 0)
            {
                FoundAddresses.AddRange(results);
                Console.WriteLine($"[FakeDuck] Found {FoundAddresses.Count} pattern(s)");
            }
            else Console.WriteLine("[FakeDuck] Pattern not found");
            PatternSearched = true;
        }

        /// <summary>
        /// 套用 Fake Duck（切換蹲下狀態）
        /// </summary>
        public static bool ApplyPatch(Memory mem, bool duck)
        {
            if (FoundAddresses.Count == 0) return false;

            byte[] patch = duck ? Replace_Duck : Replace_Stand;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, patch)) c++; }
            isDucked = duck;
            return c > 0;
        }

        /// <summary>
        /// 更新 Fake Duck（每幀呼叫）
        /// </summary>
        public static void Update(Memory mem, float deltaTime)
        {
            if (!Enabled) return;

            duckTimer += deltaTime;
            if (duckTimer >= DuckSpeed)
            {
                duckTimer = 0f;
                isDucked = !isDucked;
                ApplyPatch(mem, isDucked);
            }
        }

        public static bool RemovePatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            // 還原為站立
            isDucked = false;
            return ApplyPatch(mem, false);
        }
    }
}
