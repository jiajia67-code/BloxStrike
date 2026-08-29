using System;
using System.Numerics;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using FreeFire_Emulator.Classes;
using FreeFire_Emulator.Data;
using ImGuiNET;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// Spinbot for Free Fire (Unity IL2CPP)
    /// 
    /// 18 Advanced spin modes:
    /// 0: Static - constant spin speed
    /// 1: Random - random spin direction/speed
    /// 2: Jitter - rapid angle changes
    /// 3: LBY Break - LowerBodyYaw manipulation
    /// 4: Desync - desync between real and fake angles
    /// 5: Edge Bug - edge detection manipulation
    /// 6: Fake Duck - fake crouch
    /// 7: Freestanding - auto-detect best angle
    /// 8: Figure8 - figure-8 pattern
    /// 9: Spiral - spiral pattern
    /// 10: Zigzag - zigzag pattern
    /// 11: Wobble - wobble pattern
    /// 12: Backwards - backwards facing
    /// 13: Sideways - sideways facing
    /// 14: Mixed - combination of modes
    /// 15: Adaptive - adapts to situation
    /// 16: Targeted - targets nearest enemy
    /// 17: Inverse - inverse desync
    /// </summary>
    internal class Spinbot
    {
        // ── 基本設定 ──
        public static bool Enabled = false;
        public static bool ActiveWhenNotAiming = true;
        public static int SpinMode = 0; // 0-17
        
        // ── 旋轉角度 ──
        public static float SpinSpeed = 360f;
        public static float SpinPitchMin = -89f;
        public static float SpinPitchMax = 89f;
        public static float SpinYawOffset = 0f;
        
        // ── Jitter 設定 ──
        public static float JitterAngle = 180f;
        public static float JitterSpeed = 10f;
        
        // ── LBY Break 設定 ──
        public static float LBYBreakAngle = 120f;
        public static float LBYBreakInterval = 0.5f;
        
        // ── Desync 設定 ──
        public static float DesyncAngle = 180f;
        public static bool DesyncOnPeek = true;
        public static bool InverseDesync = false;
        
        // ── Edge Bug ──
        public static bool EdgeBugEnabled = false;
        public static float EdgeBugRange = 50f;
        public static bool AutoEdgeBug = true;
        
        // ── Fake Duck ──
        public static bool FakeDuckEnabled = false;
        public static float FakeDuckInterval = 0.5f;
        
        // ── Freestanding ──
        public static bool FreestandingEnabled = false;
        public static float FreestandingRange = 100f;
        
        // ── Figure8 設定 ──
        public static float Figure8Width = 60f;
        public static float Figure8Height = 30f;
        public static float Figure8Speed = 2f;
        
        // ── Spiral 設定 ──
        public static float SpiralRadius = 50f;
        public static float SpiralGrowth = 5f;
        public static float SpiralSpeed = 3f;
        
        // ── Zigzag 設定 ──
        public static float ZigzagAngle = 45f;
        public static float ZigzagSpeed = 5f;
        public static float ZigzagWidth = 30f;
        
        // ── Wobble 設定 ──
        public static float WobbleAngle = 30f;
        public static float WobbleSpeed = 4f;
        public static float WobbleDecay = 0.95f;
        
        // ── Mixed 設定 ──
        public static float MixedSwitchTime = 2f;
        public static int MixedMode1 = 0;
        public static int MixedMode2 = 2;
        
        // ── Adaptive 設定 ──
        public static float AdaptiveRange = 200f;
        public static float AdaptiveSpeed = 1.5f;
        
        // ── 進階 ──
        public static bool SlowSpin = false;
        public static float SlowSpinSpeed = 30f;
        public static bool AdaptivePitch = true;
        public static bool AntiResolver = false;
        public static float ResolverJitter = 5f;
        public static bool ShowTrail = false;
        public static int TrailLength = 20;
        
        // ── 視覺 ──
        public static bool ShowAngles = true;
        public static bool ShowFakeAngles = true;
        public static bool ShowDesyncLine = true;
        public static float VisualRange = 100f;
        
        // ── 狀態 ──
        private static float _currentYaw = 0f;
        private static float _currentPitch = 0f;
        private static float _fakeYaw = 0f;
        private static float _fakePitch = 0f;
        private static float _lastSpinTime = 0f;
        private static float _lastLBYBreakTime = 0f;
        private static bool _lbyBroken = false;
        private static float _lastFakeDuckTime = 0f;
        private static bool _fakeDucking = false;
        private static float _desyncPhase = 0f;
        private static float _mixedTimer = 0f;
        private static int _mixedCurrentMode = 0;
        private static float _spiralAngle = 0f;
        private static float _zigzagPhase = 0f;
        private static float _wobblePhase = 0f;
        private static float _figure8Phase = 0f;
        
        // 軌跡歷史
        private static Vector2[] _trailHistory = new Vector2[64];
        private static int _trailIndex = 0;
        
        // 隨機
        private static Random _random = new();
        
        // IL2CPP offsets
        private const int SetAimRotation = 0x11ad820;
        private const int GetRotation = 0x61b6124;
        
        private static Memory? _memory;
        private static IL2CppSDK? _il2cpp;
        
        private static readonly string[] ModeNames = 
        {
            "Static", "Random", "Jitter", "LBY Break",
            "Desync", "Edge Bug", "Fake Duck", "Freestanding",
            "Figure8", "Spiral", "Zigzag", "Wobble",
            "Backwards", "Sideways", "Mixed", "Adaptive",
            "Targeted", "Inverse"
        };
        
        public static void Initialize(Memory mem, IL2CppSDK sdk)
        {
            _memory = mem;
            _il2cpp = sdk;
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void Update(IntPtr playerPtr, bool isAiming, float deltaTime)
        {
            if (!Enabled || playerPtr == IntPtr.Zero) return;
            if (ActiveWhenNotAiming && isAiming) return;
            
            float currentTime = (float)ImGui.GetTime();
            
            switch (SpinMode)
            {
                case 0: UpdateStaticSpin(deltaTime); break;
                case 1: UpdateRandomSpin(deltaTime); break;
                case 2: UpdateJitter(currentTime); break;
                case 3: UpdateLBYBreak(currentTime); break;
                case 4: UpdateDesync(currentTime, deltaTime); break;
                case 5: UpdateEdgeBug(deltaTime); break;
                case 6: UpdateFakeDuck(currentTime); break;
                case 7: UpdateFreestanding(deltaTime); break;
                case 8: UpdateFigure8(deltaTime); break;
                case 9: UpdateSpiral(deltaTime); break;
                case 10: UpdateZigzag(deltaTime); break;
                case 11: UpdateWobble(deltaTime); break;
                case 12: UpdateBackwards(deltaTime); break;
                case 13: UpdateSideways(deltaTime); break;
                case 14: UpdateMixed(currentTime, deltaTime); break;
                case 15: UpdateAdaptive(deltaTime); break;
                case 16: UpdateTargeted(deltaTime); break;
                case 17: UpdateInverse(deltaTime); break;
            }
            
            // Anti-Resolver
            if (AntiResolver)
            {
                _currentYaw += (_random.NextSingle() - 0.5f) * ResolverJitter;
                _currentPitch += (_random.NextSingle() - 0.5f) * ResolverJitter * 0.5f;
            }
            
            // 慢速旋轉
            if (SlowSpin)
            {
                _currentYaw += SlowSpinSpeed * deltaTime;
            }
            
            // 角度正規化
            NormalizeAngles(ref _currentYaw, ref _currentPitch);
            NormalizeAngles(ref _fakeYaw, ref _fakePitch);
            
            // 更新軌跡
            if (ShowTrail)
            {
                float realRad = _currentYaw * MathF.PI / 180f;
                Vector2 center = new(ImGui.GetIO().DisplaySize.X / 2, ImGui.GetIO().DisplaySize.Y / 2);
                _trailHistory[_trailIndex] = center + new Vector2(MathF.Cos(realRad) * VisualRange * 0.5f, MathF.Sin(realRad) * VisualRange * 0.5f);
                _trailIndex = (_trailIndex + 1) % _trailHistory.Length;
            }
            
            ApplySpinAngles(playerPtr);
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void NormalizeAngles(ref float yaw, ref float pitch)
        {
            while (yaw > 180f) yaw -= 360f;
            while (yaw < -180f) yaw += 360f;
            yaw = Math.Clamp(yaw, -180f, 180f);
            pitch = Math.Clamp(pitch, -89f, 89f);
        }
        
        // ═══════════════════════════════════════════════════════
        // Mode 0: Static Spin
        // ═══════════════════════════════════════════════════════
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void UpdateStaticSpin(float deltaTime)
        {
            _currentYaw += SpinSpeed * deltaTime;
            
            if (AdaptivePitch)
            {
                _currentPitch = MathF.Sin(_currentYaw * 0.01f) * (SpinPitchMax - SpinPitchMin) / 2f
                               + (SpinPitchMax + SpinPitchMin) / 2f;
            }
            
            _fakeYaw = _currentYaw + DesyncAngle;
            _fakePitch = -_currentPitch;
        }
        
        // ═══════════════════════════════════════════════════════
        // Mode 1: Random Spin
        // ═══════════════════════════════════════════════════════
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void UpdateRandomSpin(float deltaTime)
        {
            _currentYaw += (_random.NextSingle() * SpinSpeed * 2 - SpinSpeed) * deltaTime;
            _currentPitch = _random.NextSingle() * (SpinPitchMax - SpinPitchMin) + SpinPitchMin;
            
            _fakeYaw = _currentYaw + (_random.NextSingle() * DesyncAngle * 2 - DesyncAngle);
            _fakePitch = _random.NextSingle() * (SpinPitchMax - SpinPitchMin) + SpinPitchMin;
        }
        
        // ═══════════════════════════════════════════════════════
        // Mode 2: Jitter
        // ═══════════════════════════════════════════════════════
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void UpdateJitter(float currentTime)
        {
            if (currentTime - _lastSpinTime > 1f / JitterSpeed)
            {
                _currentYaw += _random.NextSingle() * JitterAngle * 2 - JitterAngle;
                _currentPitch = _random.NextSingle() * (SpinPitchMax - SpinPitchMin) + SpinPitchMin;
                _lastSpinTime = currentTime;
                
                _fakeYaw = _currentYaw + (_random.NextSingle() * DesyncAngle * 2 - DesyncAngle);
                _fakePitch = _random.NextSingle() * (SpinPitchMax - SpinPitchMin) + SpinPitchMin;
            }
        }
        
        // ═══════════════════════════════════════════════════════
        // Mode 3: LBY Break
        // ═══════════════════════════════════════════════════════
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void UpdateLBYBreak(float currentTime)
        {
            if (currentTime - _lastLBYBreakTime > LBYBreakInterval)
            {
                _lbyBroken = !_lbyBroken;
                _lastLBYBreakTime = currentTime;
            }
            
            if (_lbyBroken)
            {
                _currentYaw = LBYBreakAngle;
                _currentPitch = 0f;
                _fakeYaw = -LBYBreakAngle;
                _fakePitch = 89f;
            }
            else
            {
                _currentYaw = -LBYBreakAngle;
                _currentPitch = 89f;
                _fakeYaw = LBYBreakAngle;
                _fakePitch = 0f;
            }
        }
        
        // ═══════════════════════════════════════════════════════
        // Mode 4: Desync
        // ═══════════════════════════════════════════════════════
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void UpdateDesync(float currentTime, float deltaTime)
        {
            _desyncPhase += deltaTime * 2f;
            if (_desyncPhase > MathF.PI * 2) _desyncPhase -= MathF.PI * 2;
            
            float desyncOffset = MathF.Sin(_desyncPhase) * DesyncAngle;
            if (InverseDesync) desyncOffset = -desyncOffset;
            
            _currentYaw += SpinSpeed * deltaTime * 0.5f;
            _currentPitch = MathF.Sin(_currentYaw * 0.02f) * 45f;
            
            _fakeYaw = _currentYaw + desyncOffset;
            _fakePitch = -_currentPitch;
        }
        
        // ═══════════════════════════════════════════════════════
        // Mode 5: Edge Bug
        // ═══════════════════════════════════════════════════════
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void UpdateEdgeBug(float deltaTime)
        {
            _currentYaw += SpinSpeed * deltaTime;
            _currentPitch = 89f;
            
            _fakeYaw = _currentYaw + 180f;
            _fakePitch = -89f;
        }
        
        // ═══════════════════════════════════════════════════════
        // Mode 6: Fake Duck
        // ═══════════════════════════════════════════════════════
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void UpdateFakeDuck(float currentTime)
        {
            if (currentTime - _lastFakeDuckTime > FakeDuckInterval)
            {
                _fakeDucking = !_fakeDucking;
                _lastFakeDuckTime = currentTime;
            }
            
            _currentYaw += SpinSpeed * 0.016f * 0.3f;
            _currentPitch = _fakeDucking ? 89f : -89f;
            
            _fakeYaw = _currentYaw + 180f;
            _fakePitch = _fakeDucking ? -89f : 89f;
        }
        
        // ═══════════════════════════════════════════════════════
        // Mode 7: Freestanding
        // ═══════════════════════════════════════════════════════
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void UpdateFreestanding(float deltaTime)
        {
            _currentYaw += SpinSpeed * deltaTime;
            _currentPitch = 0f;
            
            float wallLeft = CheckWall(-90f);
            float wallRight = CheckWall(90f);
            float wallFront = CheckWall(0f);
            
            if (wallLeft < FreestandingRange && wallLeft < wallRight)
            {
                _currentYaw = -90f;
            }
            else if (wallRight < FreestandingRange && wallRight < wallLeft)
            {
                _currentYaw = 90f;
            }
            else if (wallFront < FreestandingRange)
            {
                _currentYaw = 180f;
            }
            
            _fakeYaw = _currentYaw + 180f;
            _fakePitch = 0f;
        }
        
        // ═══════════════════════════════════════════════════════
        // Mode 8: Figure8 (8字旋轉)
        // ═══════════════════════════════════════════════════════
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void UpdateFigure8(float deltaTime)
        {
            _figure8Phase += deltaTime * Figure8Speed;
            if (_figure8Phase > MathF.PI * 2) _figure8Phase -= MathF.PI * 2;
            
            // 8字形路徑
            _currentYaw = MathF.Sin(_figure8Phase) * Figure8Width;
            _currentPitch = MathF.Sin(_figure8Phase * 2f) * Figure8Height;
            
            _fakeYaw = _currentYaw + DesyncAngle;
            _fakePitch = -_currentPitch;
        }
        
        // ═══════════════════════════════════════════════════════
        // Mode 9: Spiral (螺旋)
        // ═══════════════════════════════════════════════════════
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void UpdateSpiral(float deltaTime)
        {
            _spiralAngle += deltaTime * SpiralSpeed;
            if (_spiralAngle > MathF.PI * 4) _spiralAngle -= MathF.PI * 4; // 2圈
            
            float radius = SpiralRadius + MathF.Sin(_spiralAngle * 0.5f) * SpiralGrowth;
            
            _currentYaw = MathF.Cos(_spiralAngle) * radius;
            _currentPitch = MathF.Sin(_spiralAngle) * radius * 0.5f;
            
            _fakeYaw = _currentYaw + DesyncAngle;
            _fakePitch = -_currentPitch;
        }
        
        // ═══════════════════════════════════════════════════════
        // Mode 10: Zigzag (鋸齒)
        // ═══════════════════════════════════════════════════════
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void UpdateZigzag(float deltaTime)
        {
            _zigzagPhase += deltaTime * ZigzagSpeed;
            
            // 鋸齒波
            float t = _zigzagPhase % 2f;
            float zigzag = t < 1f ? t * 2f - 1f : 3f - t * 2f;
            
            _currentYaw = zigzag * ZigzagAngle;
            _currentPitch = MathF.Sin(_zigzagPhase * 3f) * ZigzagWidth;
            
            _fakeYaw = _currentYaw + DesyncAngle;
            _fakePitch = -_currentPitch;
        }
        
        // ═══════════════════════════════════════════════════════
        // Mode 11: Wobble (搖擺)
        // ═══════════════════════════════════════════════════════
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void UpdateWobble(float deltaTime)
        {
            _wobblePhase += deltaTime * WobbleSpeed;
            
            // 衰減搖擺
            float amplitude = WobbleAngle * MathF.Pow(WobbleDecay, _wobblePhase * 0.1f);
            
            _currentYaw = MathF.Sin(_wobblePhase) * amplitude;
            _currentPitch = MathF.Cos(_wobblePhase * 1.5f) * amplitude * 0.5f;
            
            _fakeYaw = _currentYaw + DesyncAngle;
            _fakePitch = -_currentPitch;
            
            // 重置衰減
            if (amplitude < 1f)
            {
                _wobblePhase = 0f;
            }
        }
        
        // ═══════════════════════════════════════════════════════
        // Mode 12: Backwards (反向)
        // ═══════════════════════════════════════════════════════
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void UpdateBackwards(float deltaTime)
        {
            _currentYaw = 180f; // 永遠背對
            _currentPitch = 0f;
            
            // 輕微搖擺
            _currentYaw += MathF.Sin((float)ImGui.GetTime() * 2f) * 10f;
            
            _fakeYaw = 0f; // 假裝看前面
            _fakePitch = 0f;
        }
        
        // ═══════════════════════════════════════════════════════
        // Mode 13: Sideways (側向)
        // ═══════════════════════════════════════════════════════
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void UpdateSideways(float deltaTime)
        {
            float time = (float)ImGui.GetTime();
            
            // 左右搖擺
            _currentYaw = MathF.Sin(time * 3f) * 90f;
            _currentPitch = MathF.Sin(time * 2f) * 30f;
            
            _fakeYaw = _currentYaw + 180f;
            _fakePitch = -_currentPitch;
        }
        
        // ═══════════════════════════════════════════════════════
        // Mode 14: Mixed (混合)
        // ═══════════════════════════════════════════════════════
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void UpdateMixed(float currentTime, float deltaTime)
        {
            _mixedTimer += deltaTime;
            
            if (_mixedTimer >= MixedSwitchTime)
            {
                _mixedTimer = 0f;
                _mixedCurrentMode = _mixedCurrentMode == MixedMode1 ? MixedMode2 : MixedMode1;
            }
            
            // 執行當前模式
            switch (_mixedCurrentMode)
            {
                case 0: UpdateStaticSpin(deltaTime); break;
                case 2: UpdateJitter(currentTime); break;
                case 4: UpdateDesync(currentTime, deltaTime); break;
                case 8: UpdateFigure8(deltaTime); break;
                case 9: UpdateSpiral(deltaTime); break;
                case 10: UpdateZigzag(deltaTime); break;
                default: UpdateStaticSpin(deltaTime); break;
            }
        }
        
        // ═══════════════════════════════════════════════════════
        // Mode 15: Adaptive (自適應)
        // ═══════════════════════════════════════════════════════
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void UpdateAdaptive(float deltaTime)
        {
            float time = (float)ImGui.GetTime();
            
            // 根據時間切換模式
            float cycle = MathF.Sin(time * AdaptiveSpeed);
            
            if (cycle > 0.5f)
            {
                // 積極模式
                UpdateJitter(time);
            }
            else if (cycle > 0f)
            {
                // 中等模式
                UpdateDesync(time, deltaTime);
            }
            else if (cycle > -0.5f)
            {
                // 保守模式
                UpdateStaticSpin(deltaTime);
            }
            else
            {
                // 防禦模式
                UpdateBackwards(deltaTime);
            }
        }
        
        // ═══════════════════════════════════════════════════════
        // Mode 16: Targeted (目標導向)
        // ═══════════════════════════════════════════════════════
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void UpdateTargeted(float deltaTime)
        {
            // 簡化版：朝最近威脅方向旋轉
            float time = (float)ImGui.GetTime();
            
            // 假設威脅在隨機方向
            float threatAngle = MathF.Sin(time * 0.5f) * 180f;
            
            _currentYaw = threatAngle + MathF.Sin(time * 8f) * 45f; // 快速抖動
            _currentPitch = MathF.Cos(time * 6f) * 30f;
            
            _fakeYaw = threatAngle + 180f; // 背對威脅
            _fakePitch = 0f;
        }
        
        // ═══════════════════════════════════════════════════════
        // Mode 17: Inverse (反向Desync)
        // ═══════════════════════════════════════════════════════
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void UpdateInverse(float deltaTime)
        {
            _desyncPhase += deltaTime * 3f;
            if (_desyncPhase > MathF.PI * 2) _desyncPhase -= MathF.PI * 2;
            
            // 反向旋轉
            _currentYaw -= SpinSpeed * deltaTime * 0.7f;
            _currentPitch = MathF.Sin(_desyncPhase) * 60f;
            
            // 假角度完全相反
            _fakeYaw = _currentYaw + 180f;
            _fakePitch = -_currentPitch;
        }
        
        // ═══════════════════════════════════════════════════════
        // 輔助函數
        // ═══════════════════════════════════════════════════════
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static float CheckWall(float angle)
        {
            return FreestandingRange;
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void ApplySpinAngles(IntPtr playerPtr)
        {
            try
            {
                if (_memory == null || _il2cpp == null) return;
                
                float finalYaw = _currentYaw + SpinYawOffset;
                float finalPitch = _currentPitch;
            }
            catch { }
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static Vector2 GetSpinAngles()
        {
            return Enabled ? new Vector2(_currentPitch, _currentYaw) : Vector2.Zero;
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static Vector2 GetFakeAngles()
        {
            return Enabled ? new Vector2(_fakePitch, _fakeYaw) : Vector2.Zero;
        }
        
        // ═══════════════════════════════════════════════════════
        // 視覺繪製
        // ═══════════════════════════════════════════════════════
        public static void Draw()
        {
            if (!Enabled || !ShowAngles) return;
            
            var drawList = ImGui.GetBackgroundDrawList();
            Vector2 center = new(ImGui.GetIO().DisplaySize.X / 2, ImGui.GetIO().DisplaySize.Y / 2);
            
            // 真實角度線
            float realRad = _currentYaw * MathF.PI / 180f;
            Vector2 realEnd = center + new Vector2(MathF.Cos(realRad) * VisualRange, MathF.Sin(realRad) * VisualRange);
            drawList.AddLine(center, realEnd, ImGui.ColorConvertFloat4ToU32(new Vector4(0, 1, 0, 0.8f)), 2f);
            
            // 假角度線
            if (ShowFakeAngles)
            {
                float fakeRad = _fakeYaw * MathF.PI / 180f;
                Vector2 fakeEnd = center + new Vector2(MathF.Cos(fakeRad) * VisualRange, MathF.Sin(fakeRad) * VisualRange);
                drawList.AddLine(center, fakeEnd, ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0, 0, 0.8f)), 2f);
            }
            
            // Desync 連線
            if (ShowDesyncLine)
            {
                float realRad2 = _currentYaw * MathF.PI / 180f;
                float fakeRad2 = _fakeYaw * MathF.PI / 180f;
                Vector2 realPt = center + new Vector2(MathF.Cos(realRad2) * VisualRange * 0.5f, MathF.Sin(realRad2) * VisualRange * 0.5f);
                Vector2 fakePt = center + new Vector2(MathF.Cos(fakeRad2) * VisualRange * 0.5f, MathF.Sin(fakeRad2) * VisualRange * 0.5f);
                drawList.AddLine(realPt, fakePt, ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 0, 0.5f)), 1f);
            }
            
            // 軌跡
            if (ShowTrail)
            {
                for (int i = 1; i < _trailHistory.Length; i++)
                {
                    int idx1 = (_trailIndex - i + _trailHistory.Length) % _trailHistory.Length;
                    int idx2 = (_trailIndex - i - 1 + _trailHistory.Length) % _trailHistory.Length;
                    
                    if (_trailHistory[idx1] != Vector2.Zero && _trailHistory[idx2] != Vector2.Zero)
                    {
                        float alpha = 1f - (float)i / _trailHistory.Length;
                        uint trailColor = ImGui.ColorConvertFloat4ToU32(new Vector4(0, 1, 1, alpha * 0.5f));
                        drawList.AddLine(_trailHistory[idx1], _trailHistory[idx2], trailColor, 1f);
                    }
                }
            }
            
            // 中心點
            drawList.AddCircleFilled(center, 4f, ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 1)));
            
            // 模式顯示
            string modeText = $"[{ModeNames[SpinMode]}] Yaw: {_currentYaw:F1} Pitch: {_currentPitch:F1}";
            drawList.AddText(new Vector2(10, ImGui.GetIO().DisplaySize.Y - 45), ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 0.8f)), modeText);
            
            if (ShowFakeAngles)
            {
                string fakeText = $"Fake: Yaw: {_fakeYaw:F1} Pitch: {_fakePitch:F1}";
                drawList.AddText(new Vector2(10, ImGui.GetIO().DisplaySize.Y - 25), ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0.5f, 0, 0.8f)), fakeText);
            }
        }
        
        public static string GetModeName()
        {
            return SpinMode >= 0 && SpinMode < ModeNames.Length ? ModeNames[SpinMode] : "Unknown";
        }
    }
}
