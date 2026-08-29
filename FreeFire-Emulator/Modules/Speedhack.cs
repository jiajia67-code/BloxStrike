using System;
using System.Collections.Generic;
using FreeFire_Emulator.Classes;

namespace FreeFire_Emulator.Modules
{
    internal static class Speedhack
    {
        // ── 設定 ──
        public static bool Enabled = false;
        public static float SpeedMultiplier = 2.0f; // 倍率 (1=正常, 2=兩倍速, 3=三倍速)

        // ── Pattern: Speedhack ──
        // 搜尋 bytes (S)
        private static readonly byte[] SpeedSearch = new byte[]
        {
            0x02, 0x2B, 0x07, 0x3D, 0x02, 0x2B, 0x07, 0x3D,
            0x02, 0x2B, 0x07, 0x3D, 0x00, 0x00, 0x00, 0x00,
            0x9B, 0x6C, 0xF2, 0x41
        };

        // 原始正常速度 bytes (R) — float 30.4f @ 位元組 16-19
        private static readonly byte[] SpeedNormal = new byte[]
        {
            0xE3, 0xA5, 0x9B, 0x3C, 0xE3, 0xA5, 0x9B, 0x3C,
            0x02, 0x2B, 0x07, 0x3D, 0x00, 0x00, 0x00, 0x00,
            0x9B, 0x6C, 0xF2, 0x41
        };

        // 已找到的 patch 位置
        private static readonly List<long> FoundAddresses = new List<long>();
        private static bool PatternSearched = false;

        // ── 公開方法 ──

        /// <summary>
        /// 搜尋 Speedhack pattern
        /// </summary>
        public static void FindPattern(Memory mem)
        {
            if (PatternSearched) return;
            FoundAddresses.Clear();
            Console.WriteLine("[Speedhack] Searching for speed pattern...");

            long[] results = mem.FindPatternAll(SpeedSearch);
            if (results != null && results.Length > 0)
            {
                FoundAddresses.AddRange(results);
                Console.WriteLine($"[Speedhack] Found {FoundAddresses.Count} pattern(s)");
                for (int i = 0; i < FoundAddresses.Count; i++)
                    Console.WriteLine($"[Speedhack]   [{i}] 0x{FoundAddresses[i]:X}");
            }
            else
            {
                Console.WriteLine("[Speedhack] Pattern not found");
            }
            PatternSearched = true;
        }

        /// <summary>
        /// 套用 Speedhack patch (根據 SpeedMultiplier 計算)
        /// </summary>
        public static bool ApplyPatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            byte[] patchedBytes = CalculateSpeedBytes(SpeedMultiplier);
            int patchedCount = 0;
            foreach (long addr in FoundAddresses)
            {
                if (mem.WriteBytes(addr, patchedBytes)) patchedCount++;
            }
            Console.WriteLine($"[Speedhack] Applied x{SpeedMultiplier:F1} speed to {patchedCount}/{FoundAddresses.Count}");
            return patchedCount > 0;
        }

        /// <summary>
        /// 還原 Speedhack patch
        /// </summary>
        public static bool RemovePatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int restoredCount = 0;
            foreach (long addr in FoundAddresses)
            {
                if (mem.WriteBytes(addr, SpeedNormal)) restoredCount++;
            }
            Console.WriteLine($"[Speedhack] Restored original speed at {restoredCount}/{FoundAddresses.Count}");
            return restoredCount > 0;
        }

        /// <summary>
        /// 更新倍率（即時套用）
        /// </summary>
        public static void UpdateSpeed(Memory mem, float newMultiplier)
        {
            SpeedMultiplier = Math.Clamp(newMultiplier, 0.5f, 10.0f);
            if (Enabled && FoundAddresses.Count > 0)
                ApplyPatch(mem);
        }

        // ── 私有方法 ──

        /// <summary>
        /// 根據倍率計算 replacement bytes
        /// 位元組 16-19: 原始 float 30.4f → 原始值 × 倍率
        /// </summary>
        private static byte[] CalculateSpeedBytes(float multiplier)
        {
            float originalSpeed = BitConverter.ToSingle(SpeedNormal, 16); // 30.4f
            float newSpeed = originalSpeed * multiplier;

            byte[] result = new byte[SpeedNormal.Length];
            Array.Copy(SpeedNormal, result, SpeedNormal.Length);

            byte[] speedBytes = BitConverter.GetBytes(newSpeed);
            result[16] = speedBytes[0];
            result[17] = speedBytes[1];
            result[18] = speedBytes[2];
            result[19] = speedBytes[3];

            return result;
        }
    }
}
