using System;
using System.Collections.Generic;
using FreeFire_Emulator.Classes;

namespace FreeFire_Emulator.Modules
{
    internal static class Wallhack
    {
        // ── 設定 ──
        public static bool Enabled = false;

        // ── Pattern: Wallhack ──
        // 搜尋 bytes (S) — 原始渲染參數
        private static readonly byte[] WallSearch = new byte[]
        {
            0x3F, 0xAE, 0x47, 0x81, 0x3F, 0xAE, 0x47, 0x81,
            0x3F, 0xAE, 0x47, 0x81, 0x3F, 0xEF, 0xFF, 0x7F,
            0x3F, 0xAE, 0x47, 0x81, 0x3F
        };

        // 原始 bytes (R)
        private static readonly byte[] WallNormal = new byte[]
        {
            0x3F, 0xAE, 0x47, 0x81, 0x3F, 0xAE, 0x47, 0x81,
            0x3F, 0xAE, 0x47, 0x81, 0x3F, 0xEF, 0xFF, 0x7F,
            0x3F, 0xAE, 0x47, 0x81, 0x3F
        };

        // 修改後 bytes (R) — 把第 3 個 float 的正負號翻轉 (0x3F → 0xBF)
        private static readonly byte[] WallPatched = new byte[]
        {
            0x3F, 0xAE, 0x47, 0x81, 0x3F, 0xAE, 0x47, 0x81,
            0xBF, 0xAE, 0x47, 0x81, 0x3F, 0xEF, 0xFF, 0x7F,
            0x3F, 0xAE, 0x47, 0x81, 0x3F
        };

        // 已找到的 patch 位置
        private static readonly List<long> FoundAddresses = new List<long>();
        private static bool PatternSearched = false;

        // ── 公開方法 ──

        /// <summary>
        /// 搜尋 Wallhack pattern
        /// </summary>
        public static void FindPattern(Memory mem)
        {
            if (PatternSearched) return;
            FoundAddresses.Clear();
            Console.WriteLine("[Wallhack] Searching for wallhack pattern...");

            long[] results = mem.FindPatternAll(WallSearch);
            if (results != null && results.Length > 0)
            {
                FoundAddresses.AddRange(results);
                Console.WriteLine($"[Wallhack] Found {FoundAddresses.Count} pattern(s)");
                for (int i = 0; i < FoundAddresses.Count; i++)
                    Console.WriteLine($"[Wallhack]   [{i}] 0x{FoundAddresses[i]:X}");
            }
            else
            {
                Console.WriteLine("[Wallhack] Pattern not found");
            }
            PatternSearched = true;
        }

        /// <summary>
        /// 套用 Wallhack patch
        /// </summary>
        public static bool ApplyPatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int patchedCount = 0;
            foreach (long addr in FoundAddresses)
            {
                if (mem.WriteBytes(addr, WallPatched)) patchedCount++;
            }
            Console.WriteLine($"[Wallhack] Applied wallhack to {patchedCount}/{FoundAddresses.Count}");
            return patchedCount > 0;
        }

        /// <summary>
        /// 還原 Wallhack patch
        /// </summary>
        public static bool RemovePatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int restoredCount = 0;
            foreach (long addr in FoundAddresses)
            {
                if (mem.WriteBytes(addr, WallNormal)) restoredCount++;
            }
            Console.WriteLine($"[Wallhack] Restored original at {restoredCount}/{FoundAddresses.Count}");
            return restoredCount > 0;
        }
    }
}
