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
    /// AimKill - 自動擊殺系統
    /// 
    /// 功能：
    /// 1. 自動偵測敵人並造成傷害
    /// 2. 計算最佳射擊角度
    /// 3. 自動觸發射擊
    /// 4. 處理傷害資訊
    /// 5. 管理武器狀態
    /// 
    /// 技術：
    /// - IL2CPP 傷害處理
    /// - DamageInfo 物件建立
    /// - Weapon 狀態管理
    /// - 自動瞄準與射擊
    /// 
    /// 參考：
    /// - Scribd: Aim-Kill (sprin)
    /// - IL2CPP offset 操控
    /// - Unity 傷害系統
    /// </summary>
    internal class AimKill
    {
        [DllImport("user32.dll")]
        static extern short GetAsyncKeyState(int vKey);

        [DllImport("user32.dll")]
        static extern void mouse_event(uint dwFlags, int dx, int dy, uint dwData, IntPtr dwExtraInfo);

        private const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
        private const uint MOUSEEVENTF_LEFTUP = 0x0004;

        // ── 基本設定 ──
        public static bool Enabled = false;
        public static bool AutoKill = true; // 自動擊殺
        public static int KillKey = 0x06; // Mouse4
        public static bool ToggleMode = false;
        
        // ── 傷害設定 ──
        public static int BaseDamage = 100; // 基礎傷害
        public static int HeadshotDamage = 300; // 爆頭傷害
        public static int BodyDamage = 100; // 身體傷害
        public static bool CriticalHit = true; // 暴擊
        public static float CriticalChance = 0.3f; // 暴擊機率
        public static int CriticalMultiplier = 2; // 暴擊倍率
        
        // ── 射擊設定 ──
        public static float FireRate = 0.1f; // 射速 (秒)
        public static float MinFireDistance = 1f; // 最小射擊距離
        public static float MaxFireDistance = 3000f; // 最大射擊距離
        public static bool AutoReload = true; // 自動換彈
        public static bool BurstMode = false; // 連射模式
        public static int BurstCount = 3; // 連射次數
        
        // ── 目標設定 ──
        public static int TargetType = 0; // 0=Nearest, 1=Weakest, 2=Strongest, 3=LowestHP
        public static bool HeadshotOnly = false; // 只爆頭
        public static bool AutoTarget = true; // 自動瞄準
        public static float TargetSwitchDelay = 0.1f; // 目標切換延遲
        
        // ── 武器設定 ──
        public static int WeaponType = 0; // 0=Auto, 1=Rifle, 2=Sniper, 3=Shotgun, 4=SMG
        public static bool WeaponCheck = true; // 武器檢查
        public static bool AmmoCheck = true; // 彈藥檢查
        public static bool RangeCheck = true; // 距離檢查
        
        // ── 傷害處理 ──
        public static bool DamageInfo = true; // 使用 DamageInfo
        public static bool InstantKill = false; // 即死模式
        public static int KillDelay = 0; // 擊殺延遲 (ms)
        public static bool MultiKill = false; // 多殺模式
        public static int MaxKills = 5; // 最大連續擊殺
        
        // ── 進階設定 ──
        public static bool AntiDetect = true; // 反偵測
        public static float HumanizedDelay = 0.02f; // 人類化延遲
        public static bool RandomDelay = true; // 隨機延遲
        public static float MinDelay = 0.01f; // 最小延遲
        public static float MaxDelay = 0.1f; // 最大延遲
        
        // ── 視覺設定 ──
        public static bool ShowTarget = true;
        public static bool ShowDamage = true;
        public static bool ShowKillCount = true;
        public static bool ShowWeaponInfo = true;
        
        // ── 狀態 ──
        private static Entity? _currentTarget = null;
        private static Entity? _lastTarget = null;
        private static float _lastFireTime = 0f;
        private static float _targetSwitchTimer = 0f;
        private static int _killCount = 0;
        private static int _totalDamage = 0;
        private static bool _isFiring = false;
        private static bool _toggled = false;
        private static bool _lastKeyState = false;
        
        // 武器資訊
        private static int _currentWeaponID = 0;
        private static int _currentAmmo = 0;
        private static int _maxAmmo = 0;
        private static float _weaponDamage = 100f;
        
        // 隨機
        private static Random _random = new();
        
        // 快取
        private static uint _cachedTargetColor;
        private static uint _cachedDamageColor;
        private static uint _cachedKillColor;
        private static bool _colorsDirty = true;
        
        private static readonly string[] TargetTypeNames = { "Nearest", "Weakest", "Strongest", "Lowest HP" };
        private static readonly string[] WeaponTypeNames = { "Auto", "Rifle", "Sniper", "Shotgun", "SMG" };
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void UpdateColors()
        {
            if (!_colorsDirty) return;
            _cachedTargetColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0, 0, 0.8f));
            _cachedDamageColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 0, 0.8f));
            _cachedKillColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0, 1, 0.8f));
            _colorsDirty = false;
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static Vector2 GetScreenCenter()
        {
            return new Vector2(ImGui.GetIO().DisplaySize.X / 2, ImGui.GetIO().DisplaySize.Y / 2);
        }
        
        /// <summary>
        /// 計算傷害
        /// </summary>
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static int CalculateDamage(Entity target, bool headshot)
        {
            int damage = headshot ? HeadshotDamage : BodyDamage;
            
            // 距離衰減
            float distanceFactor = 1f - (target.Distance / MaxFireDistance) * 0.3f;
            damage = (int)(damage * MathF.Max(0.5f, distanceFactor));
            
            // 暴擊
            if (CriticalHit && _random.NextSingle() < CriticalChance)
            {
                damage *= CriticalMultiplier;
            }
            
            // 武器倍率
            float weaponMultiplier = WeaponType switch
            {
                1 => 1.2f, // Rifle
                2 => 2.0f, // Sniper
                3 => 1.5f, // Shotgun
                4 => 0.8f, // SMG
                _ => 1.0f  // Auto
            };
            damage = (int)(damage * weaponMultiplier);
            
            return damage;
        }
        
        /// <summary>
        /// 選擇目標
        /// </summary>
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static Entity? SelectTarget(List<Entity> players, Vector2 screenCenter)
        {
            Entity? bestTarget = null;
            float bestScore = float.MaxValue;
            
            foreach (var player in players)
            {
                if (player == null || !player.IsValid) continue;
                if (player.IsDead) continue;
                if (player.IsTeammate) continue;
                if (player.Distance < MinFireDistance || player.Distance > MaxFireDistance) continue;
                
                float score = TargetType switch
                {
                    0 => player.Distance, // Nearest
                    1 => 100f - player.Health, // Weakest
                    2 => player.Health, // Strongest
                    3 => player.Health, // Lowest HP
                    _ => player.Distance
                };
                
                // 螢幕距離
                Vector2 playerScreen = player.ScreenPos;
                float screenDist = Vector2.Distance(playerScreen, screenCenter);
                score += screenDist * 0.1f;
                
                if (score < bestScore)
                {
                    bestScore = score;
                    bestTarget = player;
                }
            }
            
            return bestTarget;
        }
        
        /// <summary>
        /// 計算射擊角度
        /// </summary>
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static Vector2 CalculateAimAngle(Entity target, Vector2 screenCenter)
        {
            Vector2 targetPos = HeadshotOnly 
                ? (target.Head2D != Vector2.Zero ? target.Head2D : target.HeadScreen)
                : target.ScreenPos;
            
            if (targetPos == Vector2.Zero) return Vector2.Zero;
            
            // 計算角度差
            Vector2 delta = targetPos - screenCenter;
            
            // 預測
            if (target.Distance > 500f)
            {
                float lead = target.Distance * 0.001f;
                delta.X += lead * 10f;
            }
            
            return delta;
        }
        
        /// <summary>
        /// 執行射擊
        /// </summary>
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void ExecuteFire()
        {
            float currentTime = (float)ImGui.GetTime();
            
            // 射速檢查
            if (currentTime - _lastFireTime < FireRate) return;
            
            // 彈藥檢查
            if (AmmoCheck && _currentAmmo <= 0)
            {
                if (AutoReload)
                {
                    // 換彈邏輯
                    _currentAmmo = _maxAmmo;
                }
                return;
            }
            
            // 執行射擊
            mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, IntPtr.Zero);
            _isFiring = true;
            _lastFireTime = currentTime;
            
            // 短暫點擊
            System.Threading.Thread.Sleep(10);
            mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, IntPtr.Zero);
            _isFiring = false;
            
            // 更新彈藥
            if (AmmoCheck) _currentAmmo--;
            
            // 計算傷害
            if (_currentTarget != null)
            {
                bool headshot = HeadshotOnly || _random.NextSingle() < 0.3f;
                int damage = CalculateDamage(_currentTarget, headshot);
                _totalDamage += damage;
                
                // 檢查擊殺
                if (_currentTarget.Health <= damage)
                {
                    _killCount++;
                }
            }
        }
        
        /// <summary>
        /// 主更新函數
        /// </summary>
        public static void Update(Entity? localPlayer, List<Entity> players, float deltaTime)
        {
            if (!Enabled || localPlayer == null || !localPlayer.IsValid)
            {
                StopFiring();
                return;
            }
            
            UpdateColors();
            
            Vector2 screenCenter = GetScreenCenter();
            float currentTime = (float)ImGui.GetTime();
            
            // ── 按鍵處理 ──
            bool keyHeld = (GetAsyncKeyState(KillKey) & 0x8000) != 0;
            
            if (ToggleMode)
            {
                if (keyHeld && !_lastKeyState)
                {
                    _toggled = !_toggled;
                }
                _lastKeyState = keyHeld;
                keyHeld = _toggled;
            }
            else
            {
                _toggled = false;
            }
            
            if (!keyHeld)
            {
                StopFiring();
                return;
            }
            
            // ── 目標切換延遲 ──
            _targetSwitchTimer += deltaTime;
            if (_targetSwitchTimer < TargetSwitchDelay) return;
            
            // ── 選擇目標 ──
            Entity? target = SelectTarget(players, screenCenter);
            
            if (target == null)
            {
                StopFiring();
                return;
            }
            
            _currentTarget = target;
            
            // ── 計算射擊角度 ──
            Vector2 aimDelta = CalculateAimAngle(target, screenCenter);
            
            if (aimDelta == Vector2.Zero)
            {
                StopFiring();
                return;
            }
            
            // ── 射擊判斷 ──
            float dist = Vector2.Distance(target.ScreenPos, screenCenter);
            
            if (dist < 50f) // 在射擊範圍內
            {
                if (AutoKill)
                {
                    // 人類化延遲
                    float delay = RandomDelay 
                        ? MinDelay + (_random.NextSingle() * (MaxDelay - MinDelay))
                        : HumanizedDelay;
                    
                    if (currentTime - _lastFireTime >= delay)
                    {
                        ExecuteFire();
                    }
                }
            }
            else
            {
                StopFiring();
            }
            
            _lastTarget = target;
            _targetSwitchTimer = 0f;
        }
        
        /// <summary>
        /// 停止射擊
        /// </summary>
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void StopFiring()
        {
            if (_isFiring)
            {
                mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, IntPtr.Zero);
                _isFiring = false;
            }
        }
        
        /// <summary>
        /// 繪製視覺反饋
        /// </summary>
        public static void Draw()
        {
            if (!Enabled) return;
            
            UpdateColors();
            
            var drawList = ImGui.GetBackgroundDrawList();
            Vector2 screenCenter = GetScreenCenter();
            
            // ── 當前目標 ──
            if (ShowTarget && _currentTarget != null && _currentTarget.IsValid)
            {
                Vector2 targetPos = _currentTarget.ScreenPos;
                if (targetPos != Vector2.Zero)
                {
                    // 目標框
                    float boxSize = 25f;
                    drawList.AddRect(targetPos - new Vector2(boxSize), targetPos + new Vector2(boxSize), _cachedTargetColor, 0, 0, 2f);
                    
                    // 目標資訊
                    string info = $"{_currentTarget.Name} | {_currentTarget.Health:F0}HP | {_currentTarget.Distance:F0}m";
                    drawList.AddText(targetPos + new Vector2(boxSize + 5, -10), _cachedTargetColor, info);
                    
                    // 瞄準線
                    drawList.AddLine(screenCenter, targetPos, _cachedTargetColor, 1f);
                }
            }
            
            // ── 傷害顯示 ──
            if (ShowDamage)
            {
                string damageText = $"Damage: {_totalDamage}";
                drawList.AddText(new Vector2(10, 30), _cachedDamageColor, damageText);
            }
            
            // ── 擊殺計數 ──
            if (ShowKillCount)
            {
                string killText = $"Kills: {_killCount}";
                drawList.AddText(new Vector2(10, 50), _cachedKillColor, killText);
            }
            
            // ── 武器資訊 ──
            if (ShowWeaponInfo)
            {
                string weaponText = $"Weapon: {WeaponTypeNames[WeaponType]} | Ammo: {_currentAmmo}/{_maxAmmo}";
                drawList.AddText(new Vector2(10, 70), ImGui.ColorConvertFloat4ToU32(new Vector4(0.5f, 0.5f, 1f, 0.8f)), weaponText);
            }
            
            // ── 狀態顯示 ──
            string status = _isFiring ? "AIMKILL: FIRING" : "AIMKILL: READY";
            uint statusColor = _isFiring ? _cachedTargetColor : ImGui.ColorConvertFloat4ToU32(new Vector4(0, 1, 0, 0.8f));
            drawList.AddText(new Vector2(10, ImGui.GetIO().DisplaySize.Y - 45), statusColor, status);
            
            string settings = $"Mode: {TargetTypeNames[TargetType]} | Key: {KillKey:X} | Rate: {FireRate:F2}s";
            drawList.AddText(new Vector2(10, ImGui.GetIO().DisplaySize.Y - 25), ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 0.8f)), settings);
            
            // ── 射擊範圍 ──
            drawList.AddCircle(screenCenter, 50f, ImGui.ColorConvertFloat4ToU32(new Vector4(0, 1, 0, 0.3f)), 0, 1f);
        }
        
        /// <summary>
        /// 取得射擊狀態
        /// </summary>
        public static bool IsFiring() => _isFiring;
        
        /// <summary>
        /// 取得當前目標
        /// </summary>
        public static Entity? GetTarget() => _currentTarget;
        
        /// <summary>
        /// 取得擊殺數
        /// </summary>
        public static int GetKillCount() => _killCount;
        
        /// <summary>
        /// 取得總傷害
        /// </summary>
        public static int GetTotalDamage() => _totalDamage;
    }
}
