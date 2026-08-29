using System;
using System.Numerics;
using FreeFire_Emulator.Classes;
using FreeFire_Emulator.Data;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// Aim Assist — 輔助瞄準（像正常玩家的微調）
    /// 不是全自動，而是輕微修正角度
    /// </summary>
    internal static class AimAssist
    {
        public static bool Enabled = false;

        // 設定
        public static float FOV = 120f;           // 偵測範圍
        public static float Smooth = 8f;          // 平滑度 (越大越慢，越自然)
        public static float AimStrength = 0.6f;   // 瞄準強度 (0.1-1.0)
        public static bool BoneTarget = true;     // 瞄準骨骼
        public static int TargetBone = 0;         // 0=頭, 1=胸, 2=身體
        public static bool VisibleOnly = true;    // 只瞄準可見敵人
        public static bool KeyHold = true;        // 按住才啟動
        public static int AimKey = 0x02;          // 滑鼠右鍵 (VK_RBUTTON)

        // 狀態
        private static Vector2 targetScreen = Vector2.Zero;
        private static IntPtr currentTarget = IntPtr.Zero;
        private static bool isActive = false;

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        static extern short GetAsyncKeyState(int vKey);

        /// <summary>
        /// 計算目標位置
        /// </summary>
        public static Vector3 GetTargetBonePosition(IntPtr player, IL2CppSDK il2cpp)
        {
            return TargetBone switch
            {
                0 => il2cpp.GetHeadPosition(player),
                1 => il2cpp.GetSpinePosition(player),
                2 => il2cpp.GetHipPosition(player),
                _ => il2cpp.GetHeadPosition(player)
            };
        }

        /// <summary>
        /// 計算瞄準角度
        /// </summary>
        public static (float pitch, float yaw) CalculateAimAngle(Vector3 myPos, Vector3 targetPos)
        {
            Vector3 delta = targetPos - myPos;
            float distance = delta.Length();

            if (distance < 0.1f) return (0f, 0f);

            float yaw = (float)(Math.Atan2(delta.Y, delta.X) * 180.0 / Math.PI);
            float pitch = (float)(Math.Atan2(delta.Z, Math.Sqrt(delta.X * delta.X + delta.Y * delta.Y)) * 180.0 / Math.PI);

            return (pitch, yaw);
        }

        /// <summary>
        /// 平滑角度（模擬正常玩家的瞄準）
        /// </summary>
        public static (float pitch, float yaw) SmoothAngle(float currentPitch, float currentYaw, float targetPitch, float targetYaw)
        {
            // 加入自然的抖動
            float jitter = (float)(new Random().NextDouble() * 0.5 - 0.25);

            float smoothPitch = currentPitch + (targetPitch - currentPitch) / Smooth + jitter;
            float smoothYaw = currentYaw + (targetYaw - currentYaw) / Smooth + jitter;

            // 正規化角度
            while (smoothYaw > 180f) smoothYaw -= 360f;
            while (smoothYaw < -180f) smoothYaw += 360f;

            return (smoothPitch, smoothYaw);
        }

        /// <summary>
        /// 檢查是否在 FOV 內
        /// </summary>
        public static bool IsInFOV(Vector2 screenPos, Vector2 center, float fov)
        {
            float distance = Vector2.Distance(screenPos, center);
            return distance <= fov;
        }

        /// <summary>
        /// 取得最接近中心的目標
        /// </summary>
        public static IntPtr FindBestTarget(EntityManager em, IL2CppSDK il2cpp)
        {
            if (em.LocalPlayer == null) return IntPtr.Zero;

            IntPtr bestTarget = IntPtr.Zero;
            float bestDist = FOV;
            Vector2 screenCenter = new Vector2(960, 540); // 1080p 中心

            foreach (var player in em.Players)
            {
                if (player == null || !player.IsValid || player.IsTeam) continue;
                if (VisibleOnly && !player.IsVisible) continue;

                Vector3 targetPos = GetTargetBonePosition(player.Address, il2cpp);
                Vector2 targetScreen = il2cpp.WorldToScreen(targetPos);

                if (targetScreen.X < 0 || targetScreen.Y < 0) continue;
                if (targetScreen.X > 1920 || targetScreen.Y > 1080) continue;

                float dist = Vector2.Distance(targetScreen, screenCenter);
                if (dist < bestDist)
                {
                    bestDist = dist;
                    bestTarget = player.Address;
                    targetScreen = targetScreen;
                }
            }

            return bestTarget;
        }

        /// <summary>
        /// 檢查是否按住瞄準鍵
        /// </summary>
        public static bool IsAimKeyHeld()
        {
            if (!KeyHold) return true;
            return (GetAsyncKeyState(AimKey) & 0x8000) != 0;
        }

        /// <summary>
        /// 套用 Aim Assist
        /// </summary>
        public static void Apply(IntPtr player, IL2CppSDK il2cpp, EntityManager em)
        {
            if (!Enabled || !IsAimKeyHeld()) return;

            IntPtr target = FindBestTarget(em, il2cpp);
            if (target == IntPtr.Zero) return;

            Vector3 targetPos = GetTargetBonePosition(target, il2cpp);
            Vector3 myPos = il2cpp.GetLocalPlayerPosition();

            var (targetPitch, targetYaw) = CalculateAimAngle(myPos, targetPos);
            Vector3 currentAngles = il2cpp.GetViewAngles();
            float currentPitch = currentAngles.X;
            float currentYaw = currentAngles.Y;
            var (newPitch, newYaw) = SmoothAngle(currentPitch, currentYaw, targetPitch, targetYaw);

            // 套用 AimStrength
            float finalPitch = currentPitch + (newPitch - currentPitch) * AimStrength;
            float finalYaw = currentYaw + (newYaw - currentYaw) * AimStrength;

            il2cpp.SetAimRotation(player, finalPitch, finalYaw);
        }

        public static string GetBoneName()
        {
            return TargetBone switch
            {
                0 => "Head",
                1 => "Chest",
                2 => "Body",
                _ => "Head"
            };
        }
    }
}
