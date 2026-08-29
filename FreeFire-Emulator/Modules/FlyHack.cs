using System;
using System.Collections.Generic;
using FreeFire_Emulator.Classes;
using FreeFire_Emulator.Data;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// Fly Hack — 飛行模式
    /// 修改 MovementComponent 的垂直速度和重力
    /// </summary>
    internal static class FlyHack
    {
        public static bool Enabled = false;
        public static float FlySpeed = 5.0f; // 飛行速度
        public static float FlyHeight = 50f; // 飛行高度
        public static bool NoGravity = true; // 無重力
        public static bool InfiniteJump = true; // 無限跳躍

        // MovementComponent Offsets (from Offsets.cs)
        // MovementComponent = 0x124C (Normal)
        // MoveCompVSpeed = 0x2C
        // MoveCompIsGrounded = 0x150
        // MoveCompPhysState = 0xC
        // PhysStateFlyFlag = 0x8

        private static bool _isFlying = false;

        /// <summary>
        /// 啟動飛行模式
        /// </summary>
        public static bool StartFly(Memory mem, long localPlayerPawn)
        {
            if (localPlayerPawn == 0) return false;

            try
            {
                long moveComp = mem.Read<long>((IntPtr)(localPlayerPawn + Offsets.MovementComponent));
                if (moveComp == 0) return false;

                // 設定飛行標誌
                if (NoGravity)
                {
                    long physState = mem.Read<long>((IntPtr)(moveComp + Offsets.MoveCompPhysState));
                    if (physState != 0)
                    {
                        mem.Write<byte>((IntPtr)(physState + Offsets.PhysStateFlyFlag), 1);
                    }
                }

                // 設定垂直速度（向上飛）
                mem.Write<float>((IntPtr)(moveComp + Offsets.MoveCompVSpeed), FlySpeed);

                // 取消地面判定
                mem.Write<byte>((IntPtr)(moveComp + Offsets.MoveCompIsGrounded), 0);

                _isFlying = true;
                Console.WriteLine($"[FlyHack] Flying at speed {FlySpeed}");
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[FlyHack] Start error: {ex.Message}");
                return false;
            }
        }

        /// <summary>
        /// 停止飛行模式
        /// </summary>
        public static bool StopFly(Memory mem, long localPlayerPawn)
        {
            if (localPlayerPawn == 0) return false;

            try
            {
                long moveComp = mem.Read<long>((IntPtr)(localPlayerPawn + Offsets.MovementComponent));
                if (moveComp == 0) return false;

                // 恢復重力
                if (NoGravity)
                {
                    long physState = mem.Read<long>((IntPtr)(moveComp + Offsets.MoveCompPhysState));
                    if (physState != 0)
                    {
                        mem.Write<byte>((IntPtr)(physState + Offsets.PhysStateFlyFlag), 0);
                    }
                }

                // 重置垂直速度
                mem.Write<float>((IntPtr)(moveComp + Offsets.MoveCompVSpeed), 0f);

                _isFlying = false;
                Console.WriteLine("[FlyHack] Stopped flying");
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[FlyHack] Stop error: {ex.Message}");
                return false;
            }
        }

        /// <summary>
        /// 更新飛行高度（每幀呼叫）
        /// </summary>
        public static void Update(Memory mem, long localPlayerPawn)
        {
            if (!Enabled || localPlayerPawn == 0) return;

            try
            {
                long moveComp = mem.Read<long>((IntPtr)(localPlayerPawn + Offsets.MovementComponent));
                if (moveComp == 0) return;

                // 讀取當前高度
                long shadowBase = mem.Read<long>((IntPtr)(localPlayerPawn + Offsets.Player_ShadowBase));
                if (shadowBase != 0)
                {
                    long movePos = mem.Read<long>((IntPtr)(shadowBase + 0x20));
                    if (movePos != 0)
                    {
                        float currentZ = mem.Read<float>((IntPtr)(movePos + Offsets.MoveCompPosition + 8));

                        // 如果低於飛行高度，向上飛
                        if (currentZ < FlyHeight)
                        {
                            mem.Write<float>((IntPtr)(moveComp + Offsets.MoveCompVSpeed), FlySpeed);
                        }
                        // 如果高於飛行高度，保持
                        else
                        {
                            mem.Write<float>((IntPtr)(moveComp + Offsets.MoveCompVSpeed), 0f);
                        }
                    }
                }

                // 無限跳躍
                if (InfiniteJump)
                {
                    mem.Write<byte>((IntPtr)(moveComp + Offsets.MoveCompIsGrounded), 0);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[FlyHack] Update error: {ex.Message}");
            }
        }

        /// <summary>
        /// 切換飛行模式
        /// </summary>
        public static void Toggle(Memory mem, long localPlayerPawn)
        {
            if (_isFlying)
                StopFly(mem, localPlayerPawn);
            else
                StartFly(mem, localPlayerPawn);
        }
    }
}
