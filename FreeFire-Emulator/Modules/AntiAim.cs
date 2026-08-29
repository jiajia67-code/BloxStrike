using System;
using System.Collections.Generic;
using FreeFire_Emulator.Classes;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// Anti-Aim — 讓敵人難以瞄準你
    /// 旋轉角度讓 hitbox 偏移
    /// </summary>
    internal static class AntiAim
    {
        public static bool Enabled = false;

        // Anti-Aim 模式
        // 0 = Jitter (快速抖動)
        // 1 = Spin (旋轉)
        // 2 = Fake (假方向)
        // 3 = Reverse (反向)
        public static int Mode = 0;

        public static float YawOffset = 0f;       // Yaw 偏移
        public static float PitchAngle = -89f;    // Pitch 角度 (89 = 向下看)
        public static float JitterRange = 45f;    // 抖動範圍
        public static float SpinSpeed = 360f;     // 旋轉速度

        // Pattern: SetAimRotation 函式
        private static readonly byte[] Search = new byte[]
        {
            0xF0, 0x4F, 0x2D, 0xE9, 0x00, 0x00, 0xA0, 0xE1,
            0x08, 0x10, 0x90, 0xE5, 0x0C, 0x20, 0x90, 0xE5,
            0x10, 0x30, 0x90, 0xE5, 0x00, 0x00, 0x51, 0xE3
        };

        // Replacement: NOP (不做任何事，阻止遊戲修改角度)
        private static readonly byte[] Replace_NOP = new byte[]
        {
            0x00, 0x00, 0xA0, 0xE3, 0x1E, 0xFF, 0x2F, 0xE1,
            0x08, 0x10, 0x90, 0xE5, 0x0C, 0x20, 0x90, 0xE5,
            0x10, 0x30, 0x90, 0xE5, 0x00, 0x00, 0x51, 0xE3
        };

        private static readonly List<long> FoundAddresses = new List<long>();
        private static bool PatternSearched = false;

        // 抖動計時
        private static Random rng = new Random();
        private static float currentJitterYaw = 0f;
        private static float spinAngle = 0f;

        public static void FindPattern(Memory mem)
        {
            if (PatternSearched) return;
            FoundAddresses.Clear();
            Console.WriteLine("[AntiAim] Searching for aim rotation pattern...");
            long[] results = mem.FindPatternAll(Search);
            if (results != null && results.Length > 0)
            {
                FoundAddresses.AddRange(results);
                Console.WriteLine($"[AntiAim] Found {FoundAddresses.Count} pattern(s)");
            }
            else Console.WriteLine("[AntiAim] Pattern not found (aim not available)");
            PatternSearched = true;
        }

        /// <summary>
        /// 套用 Anti-Aim patch（阻止遊戲旋轉角度）
        /// </summary>
        public static bool ApplyPatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Replace_NOP)) c++; }
            Console.WriteLine($"[AntiAim] Applied to {c}/{FoundAddresses.Count}");
            return c > 0;
        }

        /// <summary>
        /// 還原 patch
        /// </summary>
        public static bool RemovePatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Search)) c++; }
            Console.WriteLine($"[AntiAim] Restored {c}/{FoundAddresses.Count}");
            return c > 0;
        }

        /// <summary>
        /// 計算當前 Anti-Aim 角度
        /// </summary>
        public static (float pitch, float yaw) GetAntiAimAngles(float baseYaw, float basePitch)
        {
            if (!Enabled) return (basePitch, baseYaw);

            float yaw = baseYaw + YawOffset;
            float pitch = PitchAngle;

            switch (Mode)
            {
                case 0: // Jitter
                    currentJitterYaw = (float)(rng.NextDouble() * 2 - 1) * JitterRange;
                    yaw += currentJitterYaw;
                    break;

                case 1: // Spin
                    spinAngle += SpinSpeed * 0.016f; // ~60fps
                    if (spinAngle > 360f) spinAngle -= 360f;
                    yaw += spinAngle;
                    break;

                case 2: // Fake (假方向 = 反向 180)
                    yaw += 180f;
                    break;

                case 3: // Reverse (反向 + jitter)
                    yaw += 180f + (float)(rng.NextDouble() * 2 - 1) * JitterRange * 0.5f;
                    break;
            }

            // 正規化角度
            while (yaw > 180f) yaw -= 360f;
            while (yaw < -180f) yaw += 360f;

            return (pitch, yaw);
        }

        public static string GetModeName()
        {
            return Mode switch
            {
                0 => "Jitter",
                1 => "Spin",
                2 => "Fake",
                3 => "Reverse",
                _ => "Unknown"
            };
        }
    }
}
