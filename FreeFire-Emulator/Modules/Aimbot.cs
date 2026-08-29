using System;
using System.Numerics;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using FreeFire_Emulator.Classes;
using FreeFire_Emulator.Data;
using ImGuiNET;

namespace FreeFire_Emulator.Modules
{
    internal class Aimbot
    {
        [DllImport("user32.dll")]
        static extern short GetAsyncKeyState(int vKey);

        // ── 基本設定 ──
        public static bool Enabled = false;
        public static bool VisibleOnly = true;
        public static bool TeamCheck = true;
        public static bool KnockedCheck = true;
        public static float MaxDistance = 3000f;
        
        // ── 瞄準鍵 ──
        public static int AimKey = 0x02; // 右鍵
        public static bool AimToggle = false;
        private static bool _aimToggled = false;
        private static bool _lastKeyState = false;
        
        // ── FOV 設定 ──
        public static bool DrawFOV = true;
        public static float FOV = 100f;
        public static float FOVThickness = 1.5f;
        public static int FOVStyle = 0; // 0=Circle, 1=Square, 2=Crosshair, 3=Filled
        public static float FOVFilledAlpha = 0.1f;
        public static bool ShowFOVCenter = true;
        
        // ── 瞄準部位 ──
        public static int AimBone = 0; // 0=Head, 1=Neck, 2=Chest, 3=Stomach, 4=Pelvis, 5=Closest
        public static bool BonePreview = true;
        
        // ── 平滑設定 ──
        public static int SmoothMode = 0; // 0=Linear, 1=Exponential, 2=Adaptive, 3=Bezier
        public static float SmoothX = 5f;
        public static float SmoothY = 5f;
        public static float SmoothSpeed = 1f;
        public static bool AdaptiveSmoothing = true;
        public static float AdaptiveMin = 1f;
        public static float AdaptiveMax = 15f;
        
        // ── 瞄準模式 ──
        public static int AimMode = 0; // 0=Smooth, 1=Silent, 2=Snap, 3=Triggerbot
        public static float SnapStrength = 0.8f;
        public static float SnapThreshold = 5f;
        
        // ── 目標選擇 ──
        public static int TargetSort = 0; // 0=FOV, 1=Distance, 2=Health, 3=Danger
        public static bool PreferVisible = true;
        public static bool HeadshotPriority = false;
        public static bool SingleTarget = true;
        public static bool TargetSwitchDelay = false;
        public static float TargetSwitchTime = 0.1f;
        
        // ── 預測 ──
        public static bool EnablePrediction = true;
        public static float PredictionFactor = 1f;
        public static bool LeadTarget = true;
        public static float LeadAmount = 0.5f;
        
        // ── 後座力補償 ──
        public static bool CompensateRecoil = true;
        public static float RecoilScaleX = 1f;
        public static float RecoilScaleY = 1f;
        public static bool CompensateSpread = false;
        
        // ── 視覺反饋 ──
        public static bool ShowAimLine = true;
        public static float AimLineThickness = 1f;
        public static bool ShowTargetInfo = true;
        public static bool HighlightTarget = true;
        public static float HighlightSize = 20f;
        public static bool ShowHitbox = false;
        
        // ── 安全設定 ──
        public static bool HumanizedAim = true;
        public static float JitterAmount = 0.5f;
        public static float ReactionDelay = 0.02f;
        private static float _reactionTimer = 0f;
        private static Entity? _lockedTarget = null;
        private static Vector2 _lastAimPos = Vector2.Zero;
        private static float _lastAimTime = 0f;
        
        // ── 進階設定 ──
        public static bool AutoFire = false;
        public static float AutoFireDelay = 0.1f;
        public static bool AutoScope = false;
        public static float MinHealthToAim = 20f;
        public static bool AimWhileJumping = false;
        public static bool NoAimOnKnife = true;
        
        // ── 快取 ──
        private static uint _cachedFOVColor;
        private static uint _cachedTargetColor;
        private static uint _cachedAimLineColor;
        private static bool _colorsDirty = true;
        
        private static IL2CppSDK il2cpp;
        
        // 瞄準部位名稱
        private static readonly string[] BoneNames = { "Head", "Neck", "Chest", "Stomach", "Pelvis", "Closest" };
        private static readonly string[] SmoothModeNames = { "Linear", "Exponential", "Adaptive", "Bezier" };
        private static readonly string[] AimModeNames = { "Smooth", "Silent", "Snap", "Triggerbot" };
        private static readonly string[] SortModeNames = { "FOV", "Distance", "Health", "Danger" };
        private static readonly string[] FOVStyleNames = { "Circle", "Square", "Crosshair", "Filled" };
        
        public Aimbot(Memory mem, IL2CppSDK sdk)
        {
            il2cpp = sdk;
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void UpdateColors()
        {
            if (!_colorsDirty) return;
            _cachedFOVColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 0.3f));
            _cachedTargetColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0, 0, 1));
            _cachedAimLineColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 0, 0.8f));
            _colorsDirty = false;
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static Vector2 GetAimPoint(Entity player)
        {
            return AimBone switch
            {
                0 => player.Head2D != Vector2.Zero ? player.Head2D : player.HeadScreen,
                1 => player.Neck != Vector3.Zero ? WorldToScreen(player.Neck) : player.HeadScreen,
                2 => player.Spine != Vector3.Zero ? WorldToScreen(player.Spine) : player.HeadScreen,
                3 => player.Hip != Vector3.Zero ? WorldToScreen(player.Hip) : player.HeadScreen,
                4 => player.Hip != Vector3.Zero ? WorldToScreen(player.Hip) : player.HeadScreen,
                5 => GetClosestBone(player),
                _ => player.Head2D != Vector2.Zero ? player.Head2D : player.HeadScreen
            };
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static Vector2 GetClosestBone(Entity player)
        {
            Vector2 center = new(ImGui.GetIO().DisplaySize.X / 2, ImGui.GetIO().DisplaySize.Y / 2);
            Vector2 head = player.Head2D != Vector2.Zero ? player.Head2D : player.HeadScreen;
            
            float minDist = Vector2.Distance(head, center);
            Vector2 closest = head;
            
            var bones = new[] { player.Neck, player.Spine, player.Hip };
            foreach (var bone in bones)
            {
                if (bone == Vector3.Zero) continue;
                Vector2 boneScreen = WorldToScreen(bone);
                float dist = Vector2.Distance(boneScreen, center);
                if (dist < minDist)
                {
                    minDist = dist;
                    closest = boneScreen;
                }
            }
            
            return closest;
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static Vector2 WorldToScreen(Vector3 worldPos)
        {
            // 簡化的 W2S - 實際應該使用 ViewMatrix
            return new Vector2(worldPos.X, worldPos.Y);
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static float GetAdaptiveSmooth(float distance)
        {
            if (!AdaptiveSmoothing) return (SmoothX + SmoothY) / 2f;
            float t = MathF.Min(distance / FOV, 1f);
            return AdaptiveMin + (AdaptiveMax - AdaptiveMin) * t;
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static Vector2 ApplySmoothing(Vector2 current, Vector2 target, float deltaTime)
        {
            float smooth = GetAdaptiveSmooth(Vector2.Distance(current, target));
            
            return SmoothMode switch
            {
                1 => // Exponential
                    current + (target - current) * (1f - MathF.Exp(-smooth * deltaTime * SmoothSpeed)),
                2 => // Adaptive
                    current + (target - current) * MathF.Min(1f, smooth * deltaTime * SmoothSpeed),
                3 => // Bezier (simplified)
                    current + (target - current) * MathF.Pow(deltaTime * SmoothSpeed, 2f / smooth),
                _ => // Linear
                    current + (target - current) * MathF.Min(1f, deltaTime * SmoothSpeed / smooth)
            };
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static Vector2 PredictTargetPosition(Entity target, float deltaTime)
        {
            if (!EnablePrediction) return GetAimPoint(target);
            
            Vector2 aimPoint = GetAimPoint(target);
            Vector3 targetPos = target.Position;
            
            // 使用位置差計算速度（需要前幀位置）
            // 簡化版本：使用目標的相對位置
            Vector2 predictedOffset = new(0, 0);
            
            if (LeadTarget)
            {
                float leadX = targetPos.X * LeadAmount * PredictionFactor;
                float leadY = targetPos.Y * LeadAmount * PredictionFactor;
                predictedOffset = new Vector2(leadX, leadY);
            }
            
            return aimPoint + predictedOffset;
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static float GetTargetScore(Entity target, Vector2 screenCenter)
        {
            Vector2 aimPoint = GetAimPoint(target);
            float dist = Vector2.Distance(aimPoint, screenCenter);
            
            return TargetSort switch
            {
                1 => target.Distance, // Distance
                2 => 100f - target.Health, // Health (lower = better)
                3 => dist * 0.5f + target.Distance * 0.01f + (target.IsFiring ? -50f : 0f), // Danger
                _ => dist + target.Distance * 0.01f // FOV
            };
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static float GetBoneZ(Vector3 worldPos)
        {
            // 簡化的Z值獲取
            return worldPos.Z;
        }
        
        public void Update(Entity? localPlayer, List<Entity> players)
        {
            if (!Enabled || localPlayer == null || !localPlayer.IsValid) return;
            
            UpdateColors();
            
            var drawList = ImGui.GetBackgroundDrawList();
            Vector2 screenCenter = new(ImGui.GetIO().DisplaySize.X / 2, ImGui.GetIO().DisplaySize.Y / 2);
            float deltaTime = ImGui.GetIO().DeltaTime;
            
            // ── 繪製 FOV ──
            if (DrawFOV)
            {
                uint fovColor = _cachedFOVColor;
                
                switch (FOVStyle)
                {
                    case 1: // Square
                        drawList.AddRect(screenCenter - new Vector2(FOV), screenCenter + new Vector2(FOV), fovColor, 0, 0, FOVThickness);
                        break;
                    case 2: // Crosshair
                        drawList.AddLine(screenCenter - new Vector2(FOV, 0), screenCenter + new Vector2(FOV, 0), fovColor, FOVThickness);
                        drawList.AddLine(screenCenter - new Vector2(0, FOV), screenCenter + new Vector2(0, FOV), fovColor, FOVThickness);
                        break;
                    case 3: // Filled
                        drawList.AddCircleFilled(screenCenter, FOV, ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, FOVFilledAlpha)));
                        drawList.AddCircle(screenCenter, FOV, fovColor, 0, FOVThickness);
                        break;
                    default: // Circle
                        drawList.AddCircle(screenCenter, FOV, fovColor, 0, FOVThickness);
                        break;
                }
                
                if (ShowFOVCenter)
                {
                    drawList.AddCircleFilled(screenCenter, 3f, fovColor);
                }
            }
            
            // ── 瞄準鍵處理 ──
            bool keyHeld = (GetAsyncKeyState(AimKey) & 0x8000) != 0;
            
            if (AimToggle)
            {
                if (keyHeld && !_lastKeyState)
                {
                    _aimToggled = !_aimToggled;
                }
                _lastKeyState = keyHeld;
                keyHeld = _aimToggled;
            }
            else
            {
                _aimToggled = false;
            }
            
            if (!keyHeld)
            {
                _lockedTarget = null;
                _reactionTimer = 0f;
                return;
            }
            
            // ── 反應延遲 ──
            if (ReactionDelay > 0)
            {
                _reactionTimer += deltaTime;
                if (_reactionTimer < ReactionDelay) return;
            }
            
            // ── 找目標 ──
            Entity? bestTarget = null;
            float bestScore = float.MaxValue;
            
            foreach (var player in players)
            {
                if (player == null || !player.IsValid) continue;
                if (player.IsTeammate && TeamCheck) continue;
                if (player.IsDead) continue;
                if (KnockedCheck && player.Health < MinHealthToAim) continue;
                if (player.Distance > MaxDistance) continue;
                if (player.Head2D == new Vector2(-99, -99)) continue;
                
                Vector2 aimPoint = GetAimPoint(player);
                if (aimPoint == Vector2.Zero) continue;
                
                float dist = Vector2.Distance(aimPoint, screenCenter);
                if (dist > FOV) continue;
                
                if (VisibleOnly && !player.IsVisible) continue;
                
                float score = GetTargetScore(player, screenCenter);
                if (score < bestScore)
                {
                    bestScore = score;
                    bestTarget = player;
                }
            }
            
            // ── 目標鎖定 ──
            if (SingleTarget && _lockedTarget != null && _lockedTarget.IsValid && !_lockedTarget.IsDead)
            {
                Vector2 lockedAim = GetAimPoint(_lockedTarget);
                if (Vector2.Distance(lockedAim, screenCenter) <= FOV)
                {
                    bestTarget = _lockedTarget;
                }
            }
            
            if (bestTarget == null)
            {
                _lockedTarget = null;
                return;
            }
            
            _lockedTarget = bestTarget;
            
            // ── 瞄準處理 ──
            Vector2 targetAim = PredictTargetPosition(bestTarget, deltaTime);
            
            if (targetAim == Vector2.Zero) return;
            
            // 視覺反饋
            if (HighlightTarget)
            {
                drawList.AddCircle(targetAim, HighlightSize, _cachedTargetColor, 0, 2f);
                drawList.AddCircleFilled(targetAim, 3f, _cachedTargetColor);
            }
            
            if (ShowAimLine)
            {
                drawList.AddLine(screenCenter, targetAim, _cachedAimLineColor, AimLineThickness);
            }
            
            if (ShowTargetInfo)
            {
                string info = $"{bestTarget.Name} | {bestTarget.Health:F0}HP | {bestTarget.Distance:F0}m | {BoneNames[AimBone]}";
                drawList.AddText(targetAim + new Vector2(10, -20), _cachedTargetColor, info);
            }
            
            // ── 執行瞄準 ──
            Vector2 delta = targetAim - screenCenter;
            
            if (AimMode == 0) // Smooth
            {
                Vector2 smoothed = ApplySmoothing(screenCenter, targetAim, deltaTime);
                Vector2 aimDelta = smoothed - screenCenter;
                
                // 人類化抖動
                if (HumanizedAim)
                {
                    aimDelta.X += (Random.Shared.NextSingle() - 0.5f) * JitterAmount;
                    aimDelta.Y += (Random.Shared.NextSingle() - 0.5f) * JitterAmount;
                }
                
                // 補償後座力
                if (CompensateRecoil)
                {
                    aimDelta.X *= RecoilScaleX;
                    aimDelta.Y *= RecoilScaleY;
                }
                
                // 寫入視角
                WriteAimDelta(aimDelta);
            }
            else if (AimMode == 1) // Silent
            {
                // Silent Aim - 只修改瞄準點不移動視角
                WriteSilentAim(targetAim);
            }
            else if (AimMode == 2) // Snap
            {
                float dist = Vector2.Distance(screenCenter, targetAim);
                if (dist < SnapThreshold)
                {
                    WriteAimDelta(delta * SnapStrength);
                }
            }
            else if (AimMode == 3) // Triggerbot
            {
                if (bestTarget.IsVisible && bestTarget.Distance < MaxDistance)
                {
                    SimulateClick();
                }
            }
            
            _lastAimPos = targetAim;
            _lastAimTime = (float)ImGui.GetTime();
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private void WriteAimDelta(Vector2 delta)
        {
            try
            {
                // 使用 IL2CPP 讀寫視角
                if (il2cpp == null) return;
                
                // 寫入 view angles
                // 這裡需要根據實際 offset 實作
            }
            catch { }
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private void WriteSilentAim(Vector2 targetPos)
        {
            try
            {
                // Silent Aim - 修改子彈方向而非視角
                if (il2cpp == null) return;
                
                // 這裡需要根據實際 offset 實作
            }
            catch { }
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private void SimulateClick()
        {
            try
            {
                // 模擬滑鼠點擊
                // 實際需要使用 SendInput 或類似方法
            }
            catch { }
        }
    }
}
