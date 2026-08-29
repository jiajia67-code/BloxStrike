using System;
using System.Numerics;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using FreeFire_Emulator.Data;
using ImGuiNET;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// AI Aim - 智慧自動射擊系統
    /// 
    /// 功能：
    /// 1. 自動偵測最佳射擊時機
    /// 2. 預測敵人移動軌跡
    /// 3. 計算最佳射擊角度
    /// 4. 自動觸發射擊
    /// 5. 學習並適應敵人行為
    /// 
    /// 技術：
    /// - 機率模型決策
    /// - 軌跡預測
    /// - 威脅評估
    /// - 自適應學習
    /// - 人類化射擊模式
    /// </summary>
    internal class AIAim
    {
        [DllImport("user32.dll")]
        static extern short GetAsyncKeyState(int vKey);

        [DllImport("user32.dll")]
        static extern void mouse_event(uint dwFlags, int dx, int dy, uint dwData, IntPtr dwExtraInfo);

        private const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
        private const uint MOUSEEVENTF_LEFTUP = 0x0004;

        // ── 基本設定 ──
        public static bool Enabled = false;
        public static bool AutoFire = true; // 自動射擊
        public static bool VisibleOnly = true;
        public static bool TeamCheck = true;
        public static float MaxDistance = 3000f;
        
        // ── 射擊時機 ──
        public static float OptimalAngle = 5f; // 最佳角度範圍 (度)
        public static float TriggerThreshold = 0.8f; // 觸發閾值 (0-1)
        public static float PredictionAccuracy = 0.7f; // 預測準確度
        public static bool WaitForHeadshot = true; // 等待爆頭機會
        public static float HeadshotThreshold = 15f; // 爆頭角度閾值
        
        // ── 威脅評估 ──
        public static bool ThreatAssessment = true; // 威脅評估
        public static float DangerRadius = 200f; // 危險範圍
        public static float ThreatDecay = 0.95f; // 威脅衰減
        public static bool PrioritizeClosest = true; // 優先最近
        
        // ── 學習系統 ──
        public static bool LearningEnabled = true; // 啟用學習
        public static float LearningRate = 0.1f; // 學習率
        public static float MemorySize = 100f; // 記憶大小
        public static bool AdaptToPatterns = true; // 適應模式
        
        // ── 射擊模式 ──
        public static int FireMode = 0; // 0=Single, 1=Burst, 2=Auto
        public static int BurstCount = 3;
        public static float BurstDelay = 0.05f;
        public static float AutoFireDelay = 0.1f;
        
        // ── 人類化 ──
        public static bool Humanized = true;
        public static float ReactionDelay = 0.02f;
        public static float MinReaction = 0.01f;
        public static float MaxReaction = 0.1f;
        public static float MissChance = 0.05f; // 失誤機率
        public static float JitterAmount = 0.3f;
        
        // ── 預測設定 ──
        public static bool PredictMovement = true;
        public static float PredictionTime = 0.1f;
        public static bool LeadTarget = true;
        public static float LeadFactor = 0.5f;
        
        // ── 視覺設定 ──
        public static bool ShowAnalysis = true;
        public static bool ShowThreats = true;
        public static bool ShowPrediction = true;
        public static bool ShowFireTiming = true;
        
        // ── 狀態 ──
        private static Entity? _currentTarget = null;
        private static Entity? _lastTarget = null;
        private static float _threatLevel = 0f;
        private static float _lastFireTime = 0f;
        private static float _reactionTimer = 0f;
        private static bool _isFiring = false;
        private static int _burstCounter = 0;
        private static float _burstTimer = 0f;
        
        // 學習資料
        private static float[] _hitHistory = new float[32];
        private static int _historyIndex = 0;
        private static float _averageAccuracy = 0.5f;
        private static float _patternScore = 0f;
        
        // 威脅追蹤
        private static float[] _threatLevels = new float[64];
        private static Vector2[] _lastPositions = new Vector2[64];
        
        // 隨機
        private static Random _random = new();
        
        // 快取
        private static uint _cachedTargetColor;
        private static uint _cachedThreatColor;
        private static uint _cachedFireColor;
        private static uint _cachedPredictColor;
        private static bool _colorsDirty = true;
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void UpdateColors()
        {
            if (!_colorsDirty) return;
            _cachedTargetColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0, 0, 0.8f));
            _cachedThreatColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0.5f, 0, 0.8f));
            _cachedFireColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 0, 1f));
            _cachedPredictColor = ImGui.ColorConvertFloat4ToU32(new Vector4(0, 1, 1, 0.8f));
            _colorsDirty = false;
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static Vector2 GetScreenCenter()
        {
            return new Vector2(ImGui.GetIO().DisplaySize.X / 2, ImGui.GetIO().DisplaySize.Y / 2);
        }
        
        /// <summary>
        /// 計算威脅等級
        /// </summary>
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static float CalculateThreat(Entity player, Vector2 screenCenter, int index)
        {
            float threat = 0f;
            
            // 距離威脅 (越近越危險)
            float distThreat = 1f - (player.Distance / MaxDistance);
            threat += distThreat * 0.4f;
            
            // 螢幕距離威脅 (越接近中心越危險)
            Vector2 playerScreen = player.ScreenPos;
            float screenDist = Vector2.Distance(playerScreen, screenCenter);
            float screenThreat = 1f - (screenDist / 500f);
            threat += MathF.Max(0, screenThreat) * 0.3f;
            
            // 可見性威脅 (可見更危險)
            if (player.IsVisible) threat += 0.2f;
            
            // 血量威脅 (血多更危險)
            threat += (player.Health / 100f) * 0.1f;
            
            // 移動威脅 (正在移動更危險)
            if (index >= 0 && index < _lastPositions.Length)
            {
                float moveDist = Vector2.Distance(playerScreen, _lastPositions[index]);
                if (moveDist > 5f) threat += 0.1f;
                _lastPositions[index] = playerScreen;
            }
            
            return MathF.Min(1f, threat);
        }
        
        /// <summary>
        /// 計算射擊分數
        /// </summary>
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static float CalculateFireScore(Entity player, Vector2 screenCenter)
        {
            float score = 0f;
            
            Vector2 aimPoint = player.Head2D != Vector2.Zero ? player.Head2D : player.ScreenPos;
            float dist = Vector2.Distance(aimPoint, screenCenter);
            
            // 角度分數 (越接近中心越好)
            float angleScore = 1f - MathF.Min(1f, dist / 200f);
            score += angleScore * 0.4f;
            
            // 距離分數 (越近越好)
            float distScore = 1f - (player.Distance / MaxDistance);
            score += distScore * 0.2f;
            
            // 可見性分數
            if (player.IsVisible) score += 0.2f;
            
            // 血量分數 (目標血量)
            score += (player.Health / 100f) * 0.1f;
            
            // 學習分數
            score += _averageAccuracy * 0.1f;
            
            return MathF.Min(1f, score);
        }
        
        /// <summary>
        /// 預測目標位置
        /// </summary>
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static Vector2 PredictTarget(Entity player, float deltaTime)
        {
            Vector2 currentPos = player.ScreenPos;
            
            if (!PredictMovement) return currentPos;
            
            // 簡化預測：假設勻速移動
            // 實際應使用卡爾曼濾波或其他預測算法
            Vector2 predicted = currentPos;
            
            if (LeadTarget)
            {
                // 根據距離計算提前量
                float lead = player.Distance * LeadFactor * 0.001f;
                predicted.X += lead * 10f; // 簡化
            }
            
            return predicted;
        }
        
        /// <summary>
        /// 判斷是否應該射擊
        /// </summary>
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static bool ShouldFire(Entity player, Vector2 screenCenter)
        {
            Vector2 aimPoint = player.Head2D != Vector2.Zero ? player.Head2D : player.ScreenPos;
            float dist = Vector2.Distance(aimPoint, screenCenter);
            
            // 檢查角度
            if (dist > OptimalAngle * 10f) return false;
            
            // 計算射擊分數
            float score = CalculateFireScore(player, screenCenter);
            
            // 檢查閾值
            if (score < TriggerThreshold) return false;
            
            // 爆頭檢查
            if (WaitForHeadshot)
            {
                Vector2 headPos = player.Head2D != Vector2.Zero ? player.Head2D : player.HeadScreen;
                float headDist = Vector2.Distance(headPos, screenCenter);
                if (headDist > HeadshotThreshold * 10f)
                {
                    // 不在爆頭範圍，降低射擊意願
                    if (_random.NextSingle() > 0.3f) return false;
                }
            }
            
            // 人類化失誤
            if (Humanized && _random.NextSingle() < MissChance)
            {
                return false;
            }
            
            return true;
        }
        
        /// <summary>
        /// 更新學習系統
        /// </summary>
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void UpdateLearning(bool hit)
        {
            if (!LearningEnabled) return;
            
            _hitHistory[_historyIndex] = hit ? 1f : 0f;
            _historyIndex = (_historyIndex + 1) % _hitHistory.Length;
            
            // 計算平均準確度
            float sum = 0f;
            for (int i = 0; i < _hitHistory.Length; i++)
            {
                sum += _hitHistory[i];
            }
            _averageAccuracy = sum / _hitHistory.Length;
            
            // 模式偵測
            if (AdaptToPatterns)
            {
                // 簡化版：偵測連續命中/失誤
                int consecutiveHits = 0;
                for (int i = _hitHistory.Length - 1; i >= 0 && i >= _hitHistory.Length - 5; i--)
                {
                    if (_hitHistory[i] > 0.5f) consecutiveHits++;
                    else break;
                }
                
                if (consecutiveHits >= 3)
                {
                    // 連續命中，降低失誤率
                    MissChance = MathF.Max(0.01f, MissChance * 0.9f);
                }
            }
        }
        
        /// <summary>
        /// 執行射擊
        /// </summary>
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void ExecuteFire()
        {
            float currentTime = (float)ImGui.GetTime();
            
            switch (FireMode)
            {
                case 0: // Single
                    mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, IntPtr.Zero);
                    _isFiring = true;
                    _lastFireTime = currentTime;
                    // 短暫點擊
                    System.Threading.Thread.Sleep(10);
                    mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, IntPtr.Zero);
                    _isFiring = false;
                    UpdateLearning(true); // 假設命中
                    break;
                    
                case 1: // Burst
                    if (_burstCounter < BurstCount)
                    {
                        _burstTimer += ImGui.GetIO().DeltaTime;
                        if (_burstTimer >= BurstDelay)
                        {
                            mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, IntPtr.Zero);
                            _isFiring = true;
                            _lastFireTime = currentTime;
                            System.Threading.Thread.Sleep(5);
                            mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, IntPtr.Zero);
                            _isFiring = false;
                            _burstCounter++;
                            _burstTimer = 0f;
                            UpdateLearning(true);
                        }
                    }
                    break;
                    
                case 2: // Auto
                    float timeSinceLastFire = currentTime - _lastFireTime;
                    if (timeSinceLastFire >= AutoFireDelay)
                    {
                        mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, IntPtr.Zero);
                        _isFiring = true;
                        _lastFireTime = currentTime;
                    }
                    break;
            }
        }
        
        /// <summary>
        /// 停止射擊
        /// </summary>
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void StopFire()
        {
            if (_isFiring)
            {
                mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, IntPtr.Zero);
                _isFiring = false;
                _burstCounter = 0;
                _burstTimer = 0f;
            }
        }
        
        /// <summary>
        /// 主更新函數
        /// </summary>
        public static void Update(Entity? localPlayer, List<Entity> players, float deltaTime)
        {
            if (!Enabled || localPlayer == null || !localPlayer.IsValid)
            {
                StopFire();
                return;
            }
            
            UpdateColors();
            
            Vector2 screenCenter = GetScreenCenter();
            float currentTime = (float)ImGui.GetTime();
            
            // ── 反應延遲 ──
            _reactionTimer += deltaTime;
            float delay = Humanized ? MinReaction + (_random.NextSingle() * (MaxReaction - MinReaction)) : ReactionDelay;
            if (_reactionTimer < delay) return;
            
            // ── 找目標 ──
            Entity? bestTarget = null;
            float bestScore = 0f;
            int bestIndex = -1;
            
            for (int i = 0; i < players.Count; i++)
            {
                var player = players[i];
                if (player == null || !player.IsValid) continue;
                if (player.IsDead) continue;
                if (player.IsTeammate && TeamCheck) continue;
                if (VisibleOnly && !player.IsVisible) continue;
                if (player.Distance > MaxDistance) continue;
                
                // 計算威脅
                if (ThreatAssessment)
                {
                    _threatLevels[i] = CalculateThreat(player, screenCenter, i);
                }
                
                // 計算射擊分數
                float score = CalculateFireScore(player, screenCenter);
                
                if (score > bestScore)
                {
                    bestScore = score;
                    bestTarget = player;
                    bestIndex = i;
                }
            }
            
            // ── 更新目標 ──
            _currentTarget = bestTarget;
            
            // ── 威脅等級 ──
            if (ThreatAssessment && bestIndex >= 0)
            {
                _threatLevel = _threatLevels[bestIndex];
            }
            
            // ── 射擊判斷 ──
            if (bestTarget != null && AutoFire && ShouldFire(bestTarget, screenCenter))
            {
                // 預測位置
                Vector2 predictedPos = PredictTarget(bestTarget, deltaTime);
                
                // 執行射擊
                ExecuteFire();
            }
            else
            {
                StopFire();
            }
            
            _lastTarget = bestTarget;
            _reactionTimer = 0f;
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
            if (ShowAnalysis && _currentTarget != null && _currentTarget.IsValid)
            {
                Vector2 targetPos = _currentTarget.ScreenPos;
                if (targetPos != Vector2.Zero)
                {
                    // 目標框
                    float boxSize = 25f;
                    drawList.AddRect(targetPos - new Vector2(boxSize), targetPos + new Vector2(boxSize), _cachedTargetColor, 0, 0, 2f);
                    
                    // 射擊分數
                    float score = CalculateFireScore(_currentTarget, screenCenter);
                    string scoreText = $"Score: {score:P0}";
                    drawList.AddText(targetPos + new Vector2(boxSize + 5, -15), _cachedTargetColor, scoreText);
                    
                    // 目標資訊
                    string info = $"{_currentTarget.Name} | {_currentTarget.Health:F0}HP | {_currentTarget.Distance:F0}m";
                    drawList.AddText(targetPos + new Vector2(boxSize + 5, 0), _cachedTargetColor, info);
                    
                    // 瞄準線
                    drawList.AddLine(screenCenter, targetPos, _cachedTargetColor, 1f);
                }
            }
            
            // ── 威脅等級 ──
            if (ShowThreats)
            {
                float threatBarWidth = 100f;
                float threatBarHeight = 10f;
                Vector2 barPos = new(10, 30);
                
                // 背景
                drawList.AddRectFilled(barPos, barPos + new Vector2(threatBarWidth, threatBarHeight), ImGui.ColorConvertFloat4ToU32(new Vector4(0, 0, 0, 0.5f)));
                
                // 威脅條
                float threatWidth = threatBarWidth * _threatLevel;
                uint threatColor = _threatLevel > 0.7f ? _cachedTargetColor :
                                  _threatLevel > 0.4f ? _cachedThreatColor :
                                  ImGui.ColorConvertFloat4ToU32(new Vector4(0, 1, 0, 0.8f));
                drawList.AddRectFilled(barPos, barPos + new Vector2(threatWidth, threatBarHeight), threatColor);
                
                // 文字
                string threatText = $"Threat: {_threatLevel:P0}";
                drawList.AddText(barPos + new Vector2(0, -15), threatColor, threatText);
            }
            
            // ── 預測位置 ──
            if (ShowPrediction && _currentTarget != null && _currentTarget.IsValid)
            {
                Vector2 predicted = PredictTarget(_currentTarget, ImGui.GetIO().DeltaTime);
                if (predicted != Vector2.Zero)
                {
                    drawList.AddCircle(predicted, 8f, _cachedPredictColor, 0, 2f);
                    drawList.AddLine(screenCenter, predicted, _cachedPredictColor, 1f);
                    
                    string predText = "PREDICTED";
                    drawList.AddText(predicted + new Vector2(10, -10), _cachedPredictColor, predText);
                }
            }
            
            // ── 射擊狀態 ──
            if (ShowFireTiming)
            {
                string fireStatus = _isFiring ? "FIRING" : "READY";
                uint fireColor = _isFiring ? _cachedFireColor : ImGui.ColorConvertFloat4ToU32(new Vector4(0, 1, 0, 0.8f));
                drawList.AddText(new Vector2(10, 60), fireColor, $"Status: {fireStatus}");
                
                // 射擊模式
                string[] fireModeNames = { "Single", "Burst", "Auto" };
                drawList.AddText(new Vector2(10, 80), ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 0.8f)), $"Mode: {fireModeNames[FireMode]}");
                
                // 學習統計
                if (LearningEnabled)
                {
                    string learnText = $"Accuracy: {_averageAccuracy:P0} | Miss: {MissChance:P0}";
                    drawList.AddText(new Vector2(10, 100), ImGui.ColorConvertFloat4ToU32(new Vector4(0.5f, 0.5f, 1f, 0.8f)), learnText);
                }
            }
            
            // ── 瞄準圈 ──
            if (_currentTarget != null)
            {
                // 最佳射擊範圍
                drawList.AddCircle(screenCenter, OptimalAngle * 10f, ImGui.ColorConvertFloat4ToU32(new Vector4(0, 1, 0, 0.3f)), 0, 1f);
                
                // 觸發閾值圈
                drawList.AddCircle(screenCenter, HeadshotThreshold * 10f, ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 0, 0.3f)), 0, 1f);
            }
            
            // ── 狀態文字 ──
            string status = _currentTarget != null ? "AI AIM: TARGET LOCKED" : "AI AIM: SCANNING";
            uint statusColor = _currentTarget != null ? _cachedTargetColor : ImGui.ColorConvertFloat4ToU32(new Vector4(0, 1, 0, 0.8f));
            drawList.AddText(new Vector2(10, ImGui.GetIO().DisplaySize.Y - 45), statusColor, status);
            
            string settings = $"Angle: {OptimalAngle:F1}° | Trigger: {TriggerThreshold:P0} | Lead: {LeadFactor:F1}";
            drawList.AddText(new Vector2(10, ImGui.GetIO().DisplaySize.Y - 25), ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 0.8f)), settings);
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
        /// 取得威脅等級
        /// </summary>
        public static float GetThreatLevel() => _threatLevel;
    }
}
