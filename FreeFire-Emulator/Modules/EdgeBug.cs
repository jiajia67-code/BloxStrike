using System;
using System.Collections.Generic;
using FreeFire_Emulator.Classes;
using FreeFire_Emulator.Data;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// Edge Bug — 在邊緣卡住減少傷害
    /// 利用物理引擎 bug 在邊緣減速
    /// </summary>
    internal static class EdgeBug
    {
        public static bool Enabled = false;
        public static float DetectionRange = 50f; // 偵測範圍 (game units)
        public static bool AutoTrigger = true;    // 自動觸發

        // Pattern: IsGrounded 檢查
        // 修改讓物理引擎認為你在邊緣
        private static readonly byte[] Search = new byte[]
        {
            0xF0, 0x4F, 0x2D, 0xE9, 0x00, 0x00, 0xA0, 0xE1,
            0x08, 0x00, 0x90, 0xE5, 0x00, 0x00, 0x50, 0xE3,
            0x01, 0x00, 0x00, 0x0A, 0x0C, 0x10, 0x90, 0xE5,
            0x01, 0x00, 0xA0, 0xE3, 0x1E, 0xFF, 0x2F, 0xE1
        };

        // Replacement: 強制 IsGrounded = true
        private static readonly byte[] Replace = new byte[]
        {
            0x00, 0x00, 0xA0, 0xE3, 0x1E, 0xFF, 0x2F, 0xE1,
            0x08, 0x00, 0x90, 0xE5, 0x00, 0x00, 0x50, 0xE3,
            0x01, 0x00, 0x00, 0x0A, 0x0C, 0x10, 0x90, 0xE5,
            0x01, 0x00, 0xA0, 0xE3, 0x1E, 0xFF, 0x2F, 0xE1
        };

        private static readonly List<long> FoundAddresses = new List<long>();
        private static bool PatternSearched = false;

        // 狀態
        private static bool isActive = false;

        public static void FindPattern(Memory mem)
        {
            if (PatternSearched) return;
            FoundAddresses.Clear();
            Console.WriteLine("[EdgeBug] Searching for edge bug pattern...");
            long[] results = mem.FindPatternAll(Search);
            if (results != null && results.Length > 0)
            {
                FoundAddresses.AddRange(results);
                Console.WriteLine($"[EdgeBug] Found {FoundAddresses.Count} pattern(s)");
            }
            else Console.WriteLine("[EdgeBug] Pattern not found");
            PatternSearched = true;
        }

        /// <summary>
        /// 套用 Edge Bug（強制在地面上）
        /// </summary>
        public static bool ApplyPatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Replace)) c++; }
            isActive = true;
            Console.WriteLine($"[EdgeBug] Applied to {c}/{FoundAddresses.Count}");
            return c > 0;
        }

        /// <summary>
        /// 還原 Edge Bug
        /// </summary>
        public static bool RemovePatch(Memory mem)
        {
            if (FoundAddresses.Count == 0) return false;
            int c = 0;
            foreach (long a in FoundAddresses) { if (mem.WriteBytes(a, Search)) c++; }
            isActive = false;
            Console.WriteLine($"[EdgeBug] Restored {c}/{FoundAddresses.Count}");
            return c > 0;
        }        /// <summary>
        /// 檢查是否在邊緣（簡化版）
        /// </summary>
        public static bool IsOnEdge(Memory mem, IntPtr player)
        {
            try
            {
                IntPtr moveComp = mem.ReadPointer(player + Offsets.MovementComponent);
                if (moveComp == IntPtr.Zero) return false;

                bool isGrounded = mem.ReadBool(moveComp + Offsets.MoveCompIsGrounded);
                float vSpeed = mem.ReadFloat(moveComp + Offsets.MoveCompIsGrounded + 0x10); // vSpeed

                // 如果在地面上但有垂直速度 = 可能在邊緣
                return isGrounded && Math.Abs(vSpeed) > 0.1f;
            }
            catch { return false; }
        }

        /// <summary>
        /// 自動 Edge Bug（每幀）
        /// </summary>
        public static void AutoEdgeBug(Memory mem, IntPtr player)
        {
            if (!Enabled || !AutoTrigger) return;

            if (IsOnEdge(mem, player) && !isActive)
            {
                ApplyPatch(mem);
            }
            else if (!IsOnEdge(mem, player) && isActive)
            {
                RemovePatch(mem);
            }
        }


        // 需要初始化 memory 引用
        private static Memory? memory;
        public static void Init(Memory mem) => memory = mem;
    }
}
