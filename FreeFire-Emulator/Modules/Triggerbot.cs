using System;
using System.Numerics;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Threading;
using FreeFire_Emulator.Data;
using ImGuiNET;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// Triggerbot - 進階觸發系統
    /// 
    /// 功能：
    /// 1. 多種射擊模式
    /// 2. 智能目標選擇
    /// 3. 動態 hitbox
    /// 4. 殺敵連擊追蹤
    /// 5. 自動換彈
    /// 6. 視覺反饋
    /// </summary>
    internal class Triggerbot
    {
        [DllImport("user32.dll")]
        static extern void mouse_event(uint dwFlags, int dx, int dy, uint dwData, IntPtr dwExtraInfo);

        [DllImport("user32.dll")]
        static extern short GetAsyncKeyState(int vKey);

        [DllImport("user32.dll")]
        static extern bool SetCursorPos(int X, int Y);

        private const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
        private const uint MOUSEEVENTF_LEFTUP = 0x0004;

        // ── 基本設定 ──
        public static bool Enabled = false;
        public static bool VisibleOnly = true;
        public static bool TeamCheck = true;
        public static bool KnockedCheck = true;
        public static float MaxDistance = 3000f;
        public static int TriggerKey = 0x06; // Mouse4
        
        // ── 瞄準設定 ──
        public static int Hitbox = 0; // 0=Head, 1=Neck, 2=Body, 3=Chest, 4=Any
        public static float HitboxSize = 30f;
        public static bool HeadshotOnly = false;
        public static float MinHealth = 10f;
        public static bool DynamicHitbox = true; // 動態 hitbox
        public static float HitboxScale = 1.0f; // hitbox 縮放
        
        // ── 射擊模式 (12種) ──
        public static int FireMode = 0;
        // 0=Single, 1=Burst(3), 2=Auto, 3=Quad Burst
        // 4=Tap Fire, 5=Double Tap, 6=Rapid Burst
        // 7=Snap Fire, 8=Hold Fire, 9=Alternating
        // 10=Smart Burst, 11=Adaptive
        
        public static int BurstCount = 3;
        public static float BurstDelay = 0.05f;
        public static float AutoDelay = 0.1f;
        public static float TapInterval = 0.15f; // Tap Fire 間隔
        public static int DoubleTapCount = 2; // 雙發數量
        public static float DoubleTapDelay = 0.03f; // 雙發間隔
        public static float RapidBurstInterval = 0.02f; // 快速連射間隔
        public static int RapidBurstCount = 5; // 快速連射數量
        
        // ── 智能設定 ──
        public static bool SmartTrigger = true; // 智能觸發
        public static float MinFireChance = 0.7f; // 最小射擊機率
        public static float MaxFireChance = 1.0f; // 最大射擊機率
        public static bool PredictMovement = true; // 預測移動
        public static float PredictionFactor = 0.5f; // 預測因子
        
        // ── 延遲設定 ──
        public static float ReactionDelay = 0.02f;
        public static float MinDelay = 0.01f;
        public static float MaxDelay = 0.1f;
        public static bool RandomDelay = true;
        
        // ── 擊殺後 ──
        public static bool StopOnKill = true;
        public static float StopDelay = 0.1f;
        public static bool SwitchTarget = true;
        public static bool AutoReload = true; // 自動換彈
        public static float ReloadDelay = 1.5f; // 換彈延遲
        
        // ── 殺敵連擊 ──
        public static bool KillStreak = true; // 啟用連擊
        public static int CurrentStreak = 0; // 當前連擊
        public static int MaxStreak = 0; // 最高連擊
        public static float StreakBonus = 0.1f; // 連擊獎勵 (每殺加成)
        public static bool ShowStreak = true; // 顯示連擊
        
        // ── 視覺反饋 ──
        public static bool ShowCrosshair = true;
        public static bool ShowTarget = true;
        public static bool ShowHitbox = false;
        public static bool ShowFireRate = true;
        public static bool ShowKillFeed = true; // 擊殺資訊
        public static bool ShowStreakInfo = true; // 連擊資訊
        public static bool ShowDamageNumbers = true; // 傷害數字
        public static float CrosshairSize = 10f;
        public static float CrosshairGap = 2f;
        public static float CrosshairThickness = 1.5f;
        public static int CrosshairStyle = 0; // 0=Cross, 1=Dot, 2=Circle, 3=Triangle
        
        // ── 內部狀態 ──
        private static bool _isShooting = false;
        private static int _burstCount = 0;
        private static float _burstTimer = 0f;
        private static float _reactionTimer = 0f;
        private static float _lastFireTime = 0f;
        private static Entity? _lastTarget = null;
        private static Entity? _currentTarget = null;
        private static int _killCount = 0;
        private static int _totalShots = 0;
        private static int _totalHits = 0;
        private static bool _isReloading = false;
        private static float _reloadTimer = 0f;
        private static float _alternatingPhase = 0f;
        private static int _tapCount = 0;
        private static float _lastTapTime = 0f;
        
        // 擊殺歷史
        private static string[] _killHistory = new string[10];
        private static float[] _killTimes = new float[10];
        private static int _killHistoryIndex = 0;
        
        // 傷害數字
        private static float[] _damageNumbers = new float[10];
        private static Vector2[] _damagePositions = new Vector2[10];
        private static float[] _damageTimers = new float[10];
        private static int _damageIndex = 0;
        
        // 快取
        private static uint _cachedCrosshairColor;
        private static uint _cachedTargetColor;
        private static uint _cachedHitboxColor;
        private static uint _cachedStreakColor;
        private static bool _colorsDirty = true;
        
        private static List<Entity> _cachedPlayers = new();
        private static Entity? _cachedLocalPlayer;
        
        private static readonly string[] HitboxNames = { "Head", "Neck", "Body", "Chest", "Any" };
        private static readonly string[] FireModeNames = { 
            "Single", "Burst(3)", "Auto", "Quad Burst",
            "Tap Fire", "Double Tap", "Rapid Burst",
            "Snap Fire", "Hold Fire", "Alternating",
            "Smart Burst", "Adaptive"
        };
        private static readonly string[] CrosshairStyleNames = { "Cross", "Dot", "Circle", "Triangle" };
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void UpdateColors()
        {
            if (!_colorsDirty) return;
            _cachedCrosshairColor = ImGui.ColorConvertFloat4ToU32(new Vector4(0, 1, 0, 0.8f));
            _cachedTargetColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0, 0, 0.8f));
            _cachedHitboxColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 0, 0.3f));
            _cachedStreakColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0.5f, 0, 1f));
            _colorsDirty = false;
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void SetPlayers(List<Entity> players, Entity? localPlayer)
        {
            _cachedPlayers = players;
            _cachedLocalPlayer = localPlayer;
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static Vector2 GetScreenCenter()
        {
            return new Vector2(ImGui.GetIO().DisplaySize.X / 2, ImGui.GetIO().DisplaySize.Y / 2);
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static Vector2 GetAimPoint(Entity entity)
        {
            return Hitbox switch
            {
                0 => entity.Head2D != Vector2.Zero ? entity.Head2D : entity.HeadScreen,
                1 => entity.Neck != Vector3.Zero ? WorldToScreen(entity.Neck) : entity.HeadScreen,
                2 => entity.ScreenPos,
                3 => entity.Spine != Vector3.Zero ? WorldToScreen(entity.Spine) : entity.ScreenPos,
                _ => entity.Head2D != Vector2.Zero ? entity.Head2D : entity.ScreenPos
            };
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static Vector2 WorldToScreen(Vector3 worldPos)
        {
            return new Vector2(worldPos.X, worldPos.Y);
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static bool IsInCrosshair(Entity entity, Vector2 screenCenter)
        {
            Vector2 aimPoint = GetAimPoint(entity);
            if (aimPoint == Vector2.Zero) return false;
            
            float distance = Vector2.Distance(aimPoint, screenCenter);
            
            // 動態 hitbox
            float dynamicSize = HitboxSize * HitboxScale;
            
            // 根據距離調整 hitbox
            if (DynamicHitbox)
            {
                float distanceFactor = MathF.Max(0.5f, 1f - entity.Distance / MaxDistance);
                dynamicSize *= distanceFactor;
            }
            
            if (HeadshotOnly) dynamicSize *= 0.5f;
            
            return distance <= dynamicSize;
        }
        
        /// <summary>
        /// 計算射擊機率
        /// </summary>
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static float CalculateFireChance(Entity entity)
        {
            float chance = 1.0f;
            
            // 距離因子
            float distFactor = 1f - (entity.Distance / MaxDistance);
            chance *= MathF.Max(0.5f, distFactor);
            
            // 可見性
            if (entity.IsVisible) chance *= 1.2f;
            
            // 血量
            chance *= MathF.Max(0.3f, entity.Health / 100f);
            
            // 連擊獎勵
            if (KillStreak && CurrentStreak > 0)
            {
                chance *= 1f + (CurrentStreak * StreakBonus);
            }
            
            return MathF.Min(1f, chance);
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static Entity? FindTarget()
        {
            if (_cachedLocalPlayer == null) return null;
            
            Vector2 screenCenter = GetScreenCenter();
            Entity? bestTarget = null;
            float bestDist = float.MaxValue;
            
            foreach (var entity in _cachedPlayers)
            {
                if (entity == null || !entity.IsValid) continue;
                if (entity.IsDead) continue;
                if (entity.IsTeammate && TeamCheck) continue;
                if (VisibleOnly && !entity.IsVisible) continue;
                if (entity.Distance > MaxDistance) continue;
                if (entity.Health < MinHealth) continue;
                if (KnockedCheck && entity.Health < 20f) continue;
                
                if (!IsInCrosshair(entity, screenCenter)) continue;
                
                // 智能觸發檢查
                if (SmartTrigger)
                {
                    float fireChance = CalculateFireChance(entity);
                    if (_random.NextSingle() > fireChance) continue;
                }
                
                float dist = Vector2.Distance(GetAimPoint(entity), screenCenter);
                if (dist < bestDist)
                {
                    bestDist = dist;
                    bestTarget = entity;
                }
            }
            
            return bestTarget;
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void StartShooting()
        {
            if (!_isShooting && !_isReloading)
            {
                mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, IntPtr.Zero);
                _isShooting = true;
                _lastFireTime = (float)ImGui.GetTime();
                _totalShots++;
            }
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void StopShooting()
        {
            if (_isShooting)
            {
                mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, IntPtr.Zero);
                _isShooting = false;
            }
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void SimulateClick()
        {
            StartShooting();
            Thread.Sleep(10);
            StopShooting();
            _totalHits++;
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static float GetRandomDelay()
        {
            if (!RandomDelay) return ReactionDelay;
            return MinDelay + (_random.NextSingle() * (MaxDelay - MinDelay));
        }
        
        private static Random _random = new();
        
        /// <summary>
        /// 更新射擊模式
        /// </summary>
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void UpdateFireMode(float deltaTime)
        {
            float currentTime = (float)ImGui.GetTime();
            
            switch (FireMode)
            {
                case 0: // Single
                    SimulateClick();
                    break;
                    
                case 1: // Burst (3)
                    if (_burstCount < BurstCount)
                    {
                        _burstTimer += deltaTime;
                        if (_burstTimer >= BurstDelay)
                        {
                            SimulateClick();
                            _burstCount++;
                            _burstTimer = 0f;
                        }
                    }
                    else
                    {
                        _burstCount = 0;
                        _burstTimer = 0f;
                    }
                    break;
                    
                case 2: // Auto
                    float timeSinceLastFire = currentTime - _lastFireTime;
                    if (timeSinceLastFire >= AutoDelay)
                    {
                        StartShooting();
                    }
                    break;
                    
                case 3: // Quad Burst
                    if (_burstCount < 4)
                    {
                        _burstTimer += deltaTime;
                        if (_burstTimer >= BurstDelay * 0.8f)
                        {
                            SimulateClick();
                            _burstCount++;
                            _burstTimer = 0f;
                        }
                    }
                    else
                    {
                        _burstCount = 0;
                        _burstTimer = 0f;
                    }
                    break;
                    
                case 4: // Tap Fire
                    if (currentTime - _lastTapTime >= TapInterval)
                    {
                        SimulateClick();
                        _lastTapTime = currentTime;
                    }
                    break;
                    
                case 5: // Double Tap
                    if (_tapCount < DoubleTapCount)
                    {
                        _burstTimer += deltaTime;
                        if (_burstTimer >= DoubleTapDelay)
                        {
                            SimulateClick();
                            _tapCount++;
                            _burstTimer = 0f;
                        }
                    }
                    else
                    {
                        _tapCount = 0;
                        _burstTimer = 0f;
                        _lastTapTime = currentTime;
                    }
                    break;
                    
                case 6: // Rapid Burst
                    if (_burstCount < RapidBurstCount)
                    {
                        _burstTimer += deltaTime;
                        if (_burstTimer >= RapidBurstInterval)
                        {
                            SimulateClick();
                            _burstCount++;
                            _burstTimer = 0f;
                        }
                    }
                    else
                    {
                        _burstCount = 0;
                        _burstTimer = 0f;
                    }
                    break;
                    
                case 7: // Snap Fire
                    float snapDelay = 0.05f + (_random.NextSingle() * 0.1f);
                    if (currentTime - _lastFireTime >= snapDelay)
                    {
                        SimulateClick();
                    }
                    break;
                    
                case 8: // Hold Fire
                    StartShooting();
                    break;
                    
                case 9: // Alternating
                    _alternatingPhase += deltaTime * 5f;
                    if (MathF.Sin(_alternatingPhase) > 0)
                    {
                        StartShooting();
                    }
                    else
                    {
                        StopShooting();
                    }
                    break;
                    
                case 10: // Smart Burst
                    int smartBurst = _currentTarget != null && _currentTarget.Distance < 500f ? 5 : 3;
                    if (_burstCount < smartBurst)
                    {
                        _burstTimer += deltaTime;
                        if (_burstTimer >= BurstDelay * 0.7f)
                        {
                            SimulateClick();
                            _burstCount++;
                            _burstTimer = 0f;
                        }
                    }
                    else
                    {
                        _burstCount = 0;
                        _burstTimer = 0f;
                    }
                    break;
                    
                case 11: // Adaptive
                    float adaptiveDelay = AutoDelay * (_currentTarget != null ? 
                        MathF.Max(0.5f, _currentTarget.Distance / MaxDistance) : 1f);
                    if (currentTime - _lastFireTime >= adaptiveDelay)
                    {
                        StartShooting();
                    }
                    break;
            }
        }
        
        public static void Update(float deltaTime)
        {
            if (!Enabled)
            {
                StopShooting();
                return;
            }
            
            UpdateColors();
            
            // ── 換彈檢查 ──
            if (_isReloading)
            {
                _reloadTimer += deltaTime;
                if (_reloadTimer >= ReloadDelay)
                {
                    _isReloading = false;
                    _reloadTimer = 0f;
                }
                return;
            }
            
            // ── 觸發鍵檢查 ──
            bool keyHeld = (GetAsyncKeyState(TriggerKey) & 0x8000) != 0;
            if (!keyHeld)
            {
                StopShooting();
                _burstCount = 0;
                _reactionTimer = 0f;
                _currentTarget = null;
                _tapCount = 0;
                return;
            }
            
            // ── 反應延遲 ──
            _reactionTimer += deltaTime;
            float delay = GetRandomDelay();
            if (_reactionTimer < delay) return;
            
            // ── 找目標 ──
            Entity? target = FindTarget();
            
            if (target == null)
            {
                StopShooting();
                _burstCount = 0;
                _currentTarget = null;
                return;
            }
            
            _currentTarget = target;
            
            // ── 更新射擊模式 ──
            UpdateFireMode(deltaTime);
            
            _lastTarget = target;
        }
        
        public static void Draw()
        {
            if (!Enabled) return;
            
            UpdateColors();
            
            var drawList = ImGui.GetBackgroundDrawList();
            Vector2 screenCenter = GetScreenCenter();
            
            // ── 十字線 ──
            if (ShowCrosshair)
            {
                switch (CrosshairStyle)
                {
                    case 1: // Dot
                        drawList.AddCircleFilled(screenCenter, 3f, _cachedCrosshairColor);
                        break;
                    case 2: // Circle
                        drawList.AddCircle(screenCenter, CrosshairSize, _cachedCrosshairColor, 0, CrosshairThickness);
                        drawList.AddCircleFilled(screenCenter, 2f, _cachedCrosshairColor);
                        break;
                    case 3: // Triangle
                        Vector2 p1 = screenCenter + new Vector2(0, -CrosshairSize);
                        Vector2 p2 = screenCenter + new Vector2(-CrosshairSize * 0.866f, CrosshairSize * 0.5f);
                        Vector2 p3 = screenCenter + new Vector2(CrosshairSize * 0.866f, CrosshairSize * 0.5f);
                        drawList.AddTriangle(p1, p2, p3, _cachedCrosshairColor, CrosshairThickness);
                        break;
                    default: // Cross
                        drawList.AddLine(screenCenter - new Vector2(CrosshairSize, 0), screenCenter - new Vector2(CrosshairGap, 0), _cachedCrosshairColor, CrosshairThickness);
                        drawList.AddLine(screenCenter + new Vector2(CrosshairGap, 0), screenCenter + new Vector2(CrosshairSize, 0), _cachedCrosshairColor, CrosshairThickness);
                        drawList.AddLine(screenCenter - new Vector2(0, CrosshairSize), screenCenter - new Vector2(0, CrosshairGap), _cachedCrosshairColor, CrosshairThickness);
                        drawList.AddLine(screenCenter + new Vector2(0, CrosshairGap), screenCenter + new Vector2(0, CrosshairSize), _cachedCrosshairColor, CrosshairThickness);
                        break;
                }
                drawList.AddCircleFilled(screenCenter, 1f, _cachedCrosshairColor);
            }
            
            // ── 目標高亮 ──
            if (ShowTarget && _currentTarget != null && _currentTarget.IsValid)
            {
                Vector2 targetPos = GetAimPoint(_currentTarget);
                if (targetPos != Vector2.Zero)
                {
                    drawList.AddCircle(targetPos, HitboxSize * HitboxScale, _cachedTargetColor, 0, 2f);
                    drawList.AddCircleFilled(targetPos, 3f, _cachedTargetColor);
                    drawList.AddLine(screenCenter, targetPos, _cachedTargetColor, 1f);
                    
                    string info = $"TARGET: {_currentTarget.Name} | {_currentTarget.Health:F0}HP | {_currentTarget.Distance:F0}m";
                    drawList.AddText(targetPos + new Vector2(10, -20), _cachedTargetColor, info);
                }
                
                if (ShowHitbox)
                {
                    drawList.AddCircle(screenCenter, HitboxSize * HitboxScale, _cachedHitboxColor, 0, 1f);
                }
            }
            
            // ── 換彈狀態 ──
            if (_isReloading)
            {
                string reloadText = $"RELOADING... {_reloadTimer:F1}s";
                drawList.AddText(screenCenter + new Vector2(20, 40), ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 0, 0.9f)), reloadText);
            }
            
            // ── 射擊狀態 ──
            if (ShowFireRate && _isShooting)
            {
                float fireRate = 1f / MathF.Max((float)ImGui.GetTime() - _lastFireTime, 0.001f);
                string fireText = $"FIRING | {fireRate:F1} RPS | Shots: {_totalShots}";
                drawList.AddText(screenCenter + new Vector2(20, 20), _cachedTargetColor, fireText);
            }
            
            // ── 連擊資訊 ──
            if (ShowStreakInfo && KillStreak && CurrentStreak > 0)
            {
                string streakText = $"STREAK: {CurrentStreak} | MAX: {MaxStreak}";
                drawList.AddText(new Vector2(10, 30), _cachedStreakColor, streakText);
            }
            
            // ── 擊殺歷史 ──
            if (ShowKillFeed)
            {
                for (int i = 0; i < _killHistory.Length; i++)
                {
                    int idx = (_killHistoryIndex - i + _killHistory.Length) % _killHistory.Length;
                    if (!string.IsNullOrEmpty(_killHistory[idx]))
                    {
                        float alpha = 1f - (float)i / _killHistory.Length;
                        uint color = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0, 0, alpha * 0.8f));
                        drawList.AddText(new Vector2(10, 50 + i * 20), color, _killHistory[idx]);
                    }
                }
            }
            
            // ── 傷害數字 ──
            if (ShowDamageNumbers)
            {
                for (int i = 0; i < _damageNumbers.Length; i++)
                {
                    if (_damageTimers[i] > 0)
                    {
                        float elapsed = (float)ImGui.GetTime() - _damageTimers[i];
                        if (elapsed < 1f)
                        {
                            float yOffset = elapsed * 30f;
                            float alpha = 1f - elapsed;
                            uint dmgColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 0, alpha));
                            string dmgText = $"-{_damageNumbers[i]:F0}";
                            drawList.AddText(_damagePositions[i] - new Vector2(0, yOffset), dmgColor, dmgText);
                        }
                    }
                }
            }
            
            // ── 模式顯示 ──
            string modeText = $"[{FireModeNames[FireMode]}] | Key: {TriggerKey:X}";
            if (VisibleOnly) modeText += " | Vis";
            if (HeadshotOnly) modeText += " | HS";
            if (SmartTrigger) modeText += " | Smart";
            drawList.AddText(new Vector2(10, ImGui.GetIO().DisplaySize.Y - 25), _cachedCrosshairColor, modeText);
            
            // ── 統計 ──
            string statsText = $"Shots: {_totalShots} | Hits: {_totalHits} | Kills: {_killCount}";
            drawList.AddText(new Vector2(10, ImGui.GetIO().DisplaySize.Y - 45), ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 0.8f)), statsText);
        }
        
        /// <summary>
        /// 記錄擊殺
        /// </summary>
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void OnKill(string? killerName = null, float damage = 100f)
        {
            _killCount++;
            
            // 更新連擊
            if (KillStreak)
            {
                CurrentStreak++;
                if (CurrentStreak > MaxStreak) MaxStreak = CurrentStreak;
            }
            
            // 記錄擊殺歷史
            string killMsg = $"KILL #{_killCount}: {_currentTarget?.Name ?? "Unknown"}";
            _killHistory[_killHistoryIndex] = killMsg;
            _killTimes[_killHistoryIndex] = (float)ImGui.GetTime();
            _killHistoryIndex = (_killHistoryIndex + 1) % _killHistory.Length;
            
            // 記錄傷害
            if (_currentTarget != null)
            {
                _damageNumbers[_damageIndex] = damage;
                _damagePositions[_damageIndex] = _currentTarget.ScreenPos;
                _damageTimers[_damageIndex] = (float)ImGui.GetTime();
                _damageIndex = (_damageIndex + 1) % _damageNumbers.Length;
            }
            
            if (StopOnKill)
            {
                StopShooting();
                Thread.Sleep((int)(StopDelay * 1000));
            }
            
            if (SwitchTarget)
            {
                _currentTarget = null;
            }
            
            // 自動換彈
            if (AutoReload && _totalShots > 0 && _totalShots % 30 == 0)
            {
                _isReloading = true;
                _reloadTimer = 0f;
                StopShooting();
            }
        }
        
        /// <summary>
        /// 重置統計
        /// </summary>
        public static void ResetStats()
        {
            _killCount = 0;
            _totalShots = 0;
            _totalHits = 0;
            CurrentStreak = 0;
            MaxStreak = 0;
            _killHistory = new string[10];
            _killTimes = new float[10];
            _killHistoryIndex = 0;
        }
    }
}
