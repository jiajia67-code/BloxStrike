using System;
using System.Collections.Generic;
using FreeFire_Emulator.Classes;
using FreeFire_Emulator.Data;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// Teleport — 瞬間移動到指定位置
    /// 使用寫入玩家位置的方式實現
    /// </summary>
    internal static class Teleport
    {
        public static bool Enabled = false;
        public static float TeleportDistance = 100f; // 瞬移距離
        public static bool UseClickTeleport = true; // 點擊地圖瞬移
        public static bool UseForwardTeleport = false; // 向前瞬移
        public static float Cooldown = 0.5f; // 冷卻時間 (秒)

        private static DateTime _lastTeleport = DateTime.MinValue;

        // IL2CPP Offsets (from Offsets.cs)
        // Player_ShadowBase = 0x18B8 (Normal), 0x18C8 (India)
        // MoveCompPosition = 0x20
        // XPose = 0x78
        // MainCameraTransform = 0x24C (Normal), 0x250 (India)

        private static long _lastKnownPosition = 0;

        /// <summary>
        /// 向前瞬移 — 根據當前面向方向移動指定距離
        /// </summary>
        public static bool TeleportForward(Memory mem, long localPlayerPawn)
        {
            if (!Enabled || !UseForwardTeleport) return false;
            if (localPlayerPawn == 0) return false;
            if ((DateTime.Now - _lastTeleport).TotalSeconds < Cooldown) return false;

            try
            {
                // 讀取當前位置 (透過 ShadowBase -> MoveComp)
                long shadowBase = mem.Read<long>((IntPtr)(localPlayerPawn + Offsets.Player_ShadowBase));
                if (shadowBase == 0) return false;

                long moveComp = mem.Read<long>((IntPtr)(shadowBase + 0x20));
                if (moveComp == 0) return false;

                // 讀取當前 XYZ
                float x = mem.Read<float>((IntPtr)(moveComp + Offsets.MoveCompPosition));
                float y = mem.Read<float>((IntPtr)(moveComp + Offsets.MoveCompPosition + 4));
                float z = mem.Read<float>((IntPtr)(moveComp + Offsets.MoveCompPosition + 8));

                // 讀取視角方向 (Yaw)
                long cameraTransform = mem.Read<long>((IntPtr)(localPlayerPawn + Offsets.MainCameraTransform));
                float yaw = 0f;
                if (cameraTransform != 0)
                {
                    yaw = mem.Read<float>((IntPtr)(cameraTransform + 0xB8)); // Y rotation
                }

                // 計算新位置 (根據 Yaw 方向)
                float rad = yaw * (float)(Math.PI / 180.0);
                float newX = x + (float)Math.Sin(rad) * TeleportDistance;
                float newY = y + (float)Math.Cos(rad) * TeleportDistance;

                // 寫入新位置
                mem.Write<float>((IntPtr)(moveComp + Offsets.MoveCompPosition), newX);
                mem.Write<float>((IntPtr)(moveComp + Offsets.MoveCompPosition + 4), newY);
                mem.Write<float>((IntPtr)(moveComp + Offsets.MoveCompPosition + 8), z); // Z 不變

                _lastTeleport = DateTime.Now;
                Console.WriteLine($"[Teleport] Moved forward {TeleportDistance}m");
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Teleport] Error: {ex.Message}");
                return false;
            }
        }

        /// <summary>
        /// 瞬移到指定座標
        /// </summary>
        public static bool TeleportTo(Memory mem, long localPlayerPawn, float targetX, float targetY, float targetZ)
        {
            if (!Enabled) return false;
            if (localPlayerPawn == 0) return false;
            if ((DateTime.Now - _lastTeleport).TotalSeconds < Cooldown) return false;

            try
            {
                long shadowBase = mem.Read<long>((IntPtr)(localPlayerPawn + Offsets.Player_ShadowBase));
                if (shadowBase == 0) return false;

                long moveComp = mem.Read<long>((IntPtr)(shadowBase + 0x20));
                if (moveComp == 0) return false;

                // 寫入目標位置
                mem.Write<float>((IntPtr)(moveComp + Offsets.MoveCompPosition), targetX);
                mem.Write<float>((IntPtr)(moveComp + Offsets.MoveCompPosition + 4), targetY);
                mem.Write<float>((IntPtr)(moveComp + Offsets.MoveCompPosition + 8), targetZ);

                _lastTeleport = DateTime.Now;
                Console.WriteLine($"[Teleport] Moved to ({targetX:F1}, {targetY:F1}, {targetZ:F1})");
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Teleport] Error: {ex.Message}");
                return false;
            }
        }

        /// <summary>
        /// 傳送到敵人位置（追蹤瞬移）
        /// </summary>
        public static bool TeleportToEnemy(Memory mem, long localPlayerPawn, long enemyPawn)
        {
            if (!Enabled || enemyPawn == 0) return false;

            try
            {
                long enemyShadow = mem.Read<long>((IntPtr)(enemyPawn + Offsets.Player_ShadowBase));
                if (enemyShadow == 0) return false;

                long enemyMoveComp = mem.Read<long>((IntPtr)(enemyShadow + 0x20));
                if (enemyMoveComp == 0) return false;

                float ex = mem.Read<float>((IntPtr)(enemyMoveComp + Offsets.MoveCompPosition));
                float ey = mem.Read<float>((IntPtr)(enemyMoveComp + Offsets.MoveCompPosition + 4));
                float ez = mem.Read<float>((IntPtr)(enemyMoveComp + Offsets.MoveCompPosition + 8));

                return TeleportTo(mem, localPlayerPawn, ex, ey, ez);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Teleport] Enemy teleport error: {ex.Message}");
                return false;
            }
        }
    }
}
