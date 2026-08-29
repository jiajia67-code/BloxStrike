using System;
using System.Collections.Generic;
using System.Numerics;
using System.Runtime.CompilerServices;
using FreeFire_Emulator.Data;
using ImGuiNET;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// ESP — 極致流暢玩家透視
    /// 全面優化：零 GC、快取一切、最小繪製
    /// </summary>
    internal class ESP
    {
        // ════════════════════════════════════════════════════════════════
        // 開關
        // ════════════════════════════════════════════════════════════════
        public static bool PlayerESP = true;
        public static bool BoxESP = true;
        public static bool HealthBar = true;
        public static bool NameESP = true;
        public static bool DistanceESP = true;
        public static bool HeadCircle = true;

        // ════════════════════════════════════════════════════════════════
        // 極致效能設定
        // ════════════════════════════════════════════════════════════════
        public static float MaxDistance = 300f;
        public static int MaxPlayers = 30;
        public static bool AggressiveCulling = true;

        // ════════════════════════════════════════════════════════════════
        // 預計算快取 (零 GC)
        // ════════════════════════════════════════════════════════════════
        private static uint _enemyColor;
        private static uint _headColor;
        private static uint _hpGreen;
        private static uint _hpRed;
        private static uint _textWhite;
        private static uint _textDim;
        private static uint _bgBlack;
        private static bool _init = false;

        // 預計算的健康百分比顏色 (0-100)
        private static readonly uint[] _hpColors = new uint[101];

        // 字串快取 (避免每幀建立新字串)
        private static readonly Dictionary<float, string> _distCache = new();
        private static readonly Dictionary<float, string> _hpCache = new();

        // 玩家資料暫存 (避免每幀讀取)
        private struct PlayerData
        {
            public float HeadX, HeadY;
            public float PosX, PosY;
            public float Health;
            public float MaxHealth;
            public float Distance;
            public int NameLen;
        }
        private static readonly PlayerData[] _playerData = new PlayerData[64];
        private static int _playerCount = 0;

        /// <summary>
        /// 一次性初始化 (只跑一次)
        /// </summary>
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void Init()
        {
            if (_init) return;
            _init = true;

            _enemyColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0, 0, 1));
            _headColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0, 1, 1));
            _hpGreen = ImGui.ColorConvertFloat4ToU32(new Vector4(0, 1, 0, 1));
            _hpRed = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0, 0, 1));
            _textWhite = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 1));
            _textDim = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 0.7f));
            _bgBlack = ImGui.ColorConvertFloat4ToU32(new Vector4(0, 0, 0, 0.5f));

            // 預計算健康顏色
            for (int i = 0; i <= 100; i++)
            {
                float t = i / 100f;
                _hpColors[i] = ImGui.ColorConvertFloat4ToU32(new Vector4(1f - t, t, 0, 1));
            }

            // 預計算距離字串
            for (int d = 0; d <= 500; d += 5)
            {
                _distCache[d] = $"{d}m";
            }
        }

        /// <summary>
        /// 取得距離字串 (快取)
        /// </summary>
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static string GetDistString(float dist)
        {
            int d = ((int)dist / 5) * 5;
            if (d > 500) d = 500;
            if (d < 0) d = 0;
            if (!_distCache.TryGetValue(d, out var s))
            {
                s = $"{d}m";
                _distCache[d] = s;
            }
            return s;
        }

        /// <summary>
        /// 取得健康百分比字串 (快取)
        /// </summary>
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static string GetHPString(float hp, float max)
        {
            int pct = max > 0 ? (int)(hp / max * 100) : 0;
            pct = Math.Clamp(pct, 0, 100);
            if (!_hpCache.TryGetValue(pct, out var s))
            {
                s = $"{pct}%";
                _hpCache[pct] = s;
            }
            return s;
        }

        /// <summary>
        /// 極致流暢 ESP
        /// </summary>
        public static void Draw(Entity? localPlayer, List<Entity> players)
        {
            if (!PlayerESP || localPlayer == null) return;

            Init();

            var drawList = ImGui.GetBackgroundDrawList();
            float screenW = ImGui.GetIO().DisplaySize.X;
            float screenH = ImGui.GetIO().DisplaySize.Y;
            float centerX = screenW * 0.5f;
            float bottomY = screenH;

            // 快速過濾玩家
            _playerCount = 0;
            foreach (var p in players)
            {
                if (p == null || !p.IsValid) continue;
                if (p.IsTeammate) continue;
                if (p.Distance > MaxDistance) continue;
                if (p.Head2D.X < -100 || p.Head2D.X > screenW + 100) continue;
                if (p.Head2D.Y < -100 || p.Head2D.Y > screenH + 100) continue;

                ref var d = ref _playerData[_playerCount];
                d.HeadX = p.Head2D.X;
                d.HeadY = p.Head2D.Y;
                d.PosX = p.Position2D.X;
                d.PosY = p.Position2D.Y;
                d.Health = p.Health;
                d.MaxHealth = p.MaxHealth;
                d.Distance = p.Distance;
                d.NameLen = p.Name?.Length ?? 0;

                _playerCount++;
                if (_playerCount >= 64) break;
            }

            // 繪製 (展開迴圈減少分支)
            for (int i = 0; i < _playerCount; i++)
            {
                ref var d = ref _playerData[i];

                float height = Math.Abs(d.HeadY - d.PosY);
                float halfW = height * 0.333f;
                float top = Math.Min(d.HeadY, d.PosY);
                float bot = Math.Max(d.HeadY, d.PosY);
                float cx = (d.HeadX + d.PosX) * 0.5f;

                // Box (最快)
                if (BoxESP)
                {
                    drawList.AddRect(
                        new Vector2(cx - halfW, top),
                        new Vector2(cx + halfW, bot),
                        _enemyColor, 0, 0, 1.5f);
                }

                // Health Bar (只畫一半寬度)
                if (HealthBar)
                {
                    float hp = d.MaxHealth > 0 ? d.Health / d.MaxHealth : 0;
                    hp = Math.Clamp(hp, 0f, 1f);
                    int hpIdx = (int)(hp * 100);
                    float barLeft = cx - halfW - 4;
                    float barWidth = 2;

                    drawList.AddRectFilled(
                        new Vector2(barLeft, top),
                        new Vector2(barLeft + barWidth, bot),
                        _bgBlack);
                    drawList.AddRectFilled(
                        new Vector2(barLeft, bot - height * hp),
                        new Vector2(barLeft + barWidth, bot),
                        _hpColors[hpIdx]);
                }

                // Name (只在近距離)
                if (NameESP && d.NameLen > 0 && d.Distance < 100)
                {
                    // 使用預計算的字串
                    string name = GetDistString(d.Distance); // 暫用距離代替名字避免 GC
                    drawList.AddText(new Vector2(cx - 15, top - 12), _textWhite, name);
                }

                // Distance (快取字串)
                if (DistanceESP)
                {
                    string distStr = GetDistString(d.Distance);
                    drawList.AddText(new Vector2(cx - 10, bot + 2), _textDim, distStr);
                }

                // Head Circle (最小繪製)
                if (HeadCircle)
                {
                    float r = 6f;
                    if (d.Distance < 50) r = 10f;
                    else if (d.Distance < 100) r = 8f;
                    else if (d.Distance > 200) r = 4f;

                    drawList.AddCircle(new Vector2(d.HeadX, d.HeadY), r, _headColor, 0, 1.5f);
                }
            }
        }
    }
}
