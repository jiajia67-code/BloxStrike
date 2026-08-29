using System;
using System.Numerics;
using System.Runtime.CompilerServices;
using FreeFire_Emulator.Data;
using ImGuiNET;

namespace FreeFire_Emulator.Modules
{
    internal class Radar
    {
        // 基本設定
        public static bool Enabled = false;
        public static float RadarSize = 250f;
        public static float RadarRange = 3000f;
        
        // 顯示選項
        public static bool ShowTeammates = true;
        public static bool ShowEnemies = true;
        public static bool ShowBots = true;
        public static bool ShowVehicles = false;
        public static bool ShowLoot = false;
        public static bool ShowGrenades = false;
        
        // 雷達樣式
        public static int RadarStyle = 0; // 0=方形, 1=圓形, 2=六角形
        public static int RadarPosition = 0; // 0=左上, 1=右上, 2=左下, 3=右下, 4=中間
        public static float RadarX = 50f;
        public static float RadarY = 50f;
        
        // 進階功能
        public static bool ShowSnapLines = false;
        public static bool ShowDirectionArrows = true;
        public static bool ShowPlayerNames = false;
        public static bool ShowPlayerHealth = false;
        public static bool ShowPlayerDistance = true;
        public static bool ShowFOVCone = false;
        public static bool RotateRadar = false; // 旋轉雷達跟隨玩家視角
        public static bool ZoomEnabled = false;
        public static float ZoomLevel = 1f;
        public static bool ShowGridLines = true;
        public static bool ShowRangeCircles = true;
        
        // 顏色設定
        public static float EnemyR = 1f, EnemyG = 0f, EnemyB = 0f;
        public static float TeammateR = 0f, TeammateG = 1f, TeammateB = 0f;
        public static float BotR = 1f, BotG = 0.5f, BotB = 0f;
        public static float VehicleR = 0f, VehicleG = 0.5f, VehicleB = 1f;
        public static float LootR = 1f, LootG = 1f, LootB = 0f;
        public static float GrenadeR = 1f, GrenadeG = 0f, GrenadeB = 1f;
        public static float RadarBgR = 0f, RadarBgG = 0f, RadarBgB = 0f, RadarBgA = 0.5f;
        public static float GridR = 1f, GridG = 1f, GridB = 1f, GridA = 0.1f;
        
        // 動態效果
        public static bool PulseEnemies = false;
        public static bool ShowTrail = false;
        public static int MaxTrailPoints = 10;
        
        // 隱藏在玩家視角外
        public static bool HideWhenMenuOpen = false;
        public static bool OnlyInGame = true;
        
        // 快取
        private static uint _cachedEnemyColor;
        private static uint _cachedTeammateColor;
        private static uint _cachedBotColor;
        private static uint _cachedVehicleColor;
        private static uint _cachedLootColor;
        private static uint _cachedGrenadeColor;
        private static uint _cachedBgColor;
        private static uint _cachedGridColor;
        private static bool _colorsDirty = true;
        
        // 方向箭頭快取
        private static Vector2[] _arrowPoints = new Vector2[3];
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void UpdateColors()
        {
            if (!_colorsDirty) return;
            _cachedEnemyColor = ImGui.ColorConvertFloat4ToU32(new Vector4(EnemyR, EnemyG, EnemyB, 1f));
            _cachedTeammateColor = ImGui.ColorConvertFloat4ToU32(new Vector4(TeammateR, TeammateG, TeammateB, 1f));
            _cachedBotColor = ImGui.ColorConvertFloat4ToU32(new Vector4(BotR, BotG, BotB, 1f));
            _cachedVehicleColor = ImGui.ColorConvertFloat4ToU32(new Vector4(VehicleR, VehicleG, VehicleB, 1f));
            _cachedLootColor = ImGui.ColorConvertFloat4ToU32(new Vector4(LootR, LootG, LootB, 1f));
            _cachedGrenadeColor = ImGui.ColorConvertFloat4ToU32(new Vector4(GrenadeR, GrenadeG, GrenadeB, 1f));
            _cachedBgColor = ImGui.ColorConvertFloat4ToU32(new Vector4(RadarBgR, RadarBgG, RadarBgB, RadarBgA));
            _cachedGridColor = ImGui.ColorConvertFloat4ToU32(new Vector4(GridR, GridG, GridB, GridA));
            _colorsDirty = false;
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static Vector2 GetRadarPosition()
        {
            var io = ImGui.GetIO();
            return RadarPosition switch
            {
                0 => new Vector2(RadarX, RadarY),
                1 => new Vector2(io.DisplaySize.X - RadarX - RadarSize, RadarY),
                2 => new Vector2(RadarX, io.DisplaySize.Y - RadarY - RadarSize),
                3 => new Vector2(io.DisplaySize.X - RadarX - RadarSize, io.DisplaySize.Y - RadarY - RadarSize),
                4 => new Vector2((io.DisplaySize.X - RadarSize) / 2, (io.DisplaySize.Y - RadarSize) / 2),
                _ => new Vector2(RadarX, RadarY)
            };
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static Vector2 WorldToRadar(Vector3 worldPos, Vector3 localPos, float localYaw, Vector2 radarCenter, float scale)
        {
            float dx = worldPos.X - localPos.X;
            float dy = worldPos.Y - localPos.Y;
            
            if (RotateRadar)
            {
                float rad = localYaw * MathF.PI / 180f;
                float cos = MathF.Cos(rad);
                float sin = MathF.Sin(rad);
                float rotX = dx * cos - dy * sin;
                float rotY = dx * sin + dy * cos;
                dx = rotX;
                dy = rotY;
            }
            
            float effectiveScale = scale * ZoomLevel;
            return radarCenter + new Vector2(dx * effectiveScale, dy * effectiveScale);
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static bool IsInRadar(Vector2 pos, Vector2 radarMin, Vector2 radarMax, int style)
        {
            return style switch
            {
                1 => Vector2.Distance(pos, radarMin + new Vector2(RadarSize / 2)) <= RadarSize / 2,
                2 => MathF.Abs(pos.X - radarMin.X - RadarSize / 2) + MathF.Abs(pos.Y - radarMin.Y - RadarSize / 2) <= RadarSize / 2,
                _ => pos.X >= radarMin.X && pos.X <= radarMax.X && pos.Y >= radarMin.Y && pos.Y <= radarMax.Y
            };
        }
        
        private static void DrawArrow(ImDrawListPtr drawList, Vector2 center, float angle, float size, uint color)
        {
            float rad = angle * MathF.PI / 180f;
            float cos = MathF.Cos(rad);
            float sin = MathF.Sin(rad);
            
            _arrowPoints[0] = center + new Vector2(cos * size, sin * size);
            _arrowPoints[1] = center + new Vector2(cos * size * 0.6f - sin * size * 0.5f, sin * size * 0.6f + cos * size * 0.5f);
            _arrowPoints[2] = center + new Vector2(cos * size * 0.6f + sin * size * 0.5f, sin * size * 0.6f - cos * size * 0.5f);
            
            drawList.AddTriangleFilled(_arrowPoints[0], _arrowPoints[1], _arrowPoints[2], color);
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static float GetEnemyPulse(float time)
        {
            return PulseEnemies ? 0.7f + MathF.Sin(time * 5f) * 0.3f : 1f;
        }
        
        public static void Draw(Entity? localPlayer, List<Entity> players)
        {
            if (!Enabled || localPlayer == null || players == null) return;
            
            UpdateColors();
            
            var drawList = ImGui.GetBackgroundDrawList();
            var radarPos = GetRadarPosition();
            var radarMin = radarPos;
            var radarMax = radarPos + new Vector2(RadarSize);
            var radarCenter = radarPos + new Vector2(RadarSize / 2);
            float scale = (RadarSize / 2) / RadarRange;
            float time = (float)ImGui.GetTime();
            
            // 背景
            if (RadarStyle == 1) // 圓形
            {
                drawList.AddCircleFilled(radarCenter, RadarSize / 2, _cachedBgColor);
                drawList.AddCircle(radarCenter, RadarSize / 2, ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 0.3f)), 0, 1f);
            }
            else if (RadarStyle == 2) // 六角形
            {
                drawList.AddCircleFilled(radarCenter, RadarSize / 2, _cachedBgColor, 6);
                drawList.AddCircle(radarCenter, RadarSize / 2, ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 0.3f)), 6);
            }
            else // 方形
            {
                drawList.AddRectFilled(radarMin, radarMax, _cachedBgColor, 4f);
                drawList.AddRect(radarMin, radarMax, ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 0.3f)), 4f, 0, 1f);
            }
            
            // 網格線
            if (ShowGridLines)
            {
                int gridLines = 4;
                float gridStep = RadarSize / gridLines;
                for (int i = 1; i < gridLines; i++)
                {
                    float pos = radarMin.X + i * gridStep;
                    drawList.AddLine(new Vector2(pos, radarMin.Y), new Vector2(pos, radarMax.Y), _cachedGridColor);
                    pos = radarMin.Y + i * gridStep;
                    drawList.AddLine(new Vector2(radarMin.X, pos), new Vector2(radarMax.X, pos), _cachedGridColor);
                }
            }
            
            // 範圍圈
            if (ShowRangeCircles)
            {
                float rangeStep = RadarSize / 4f;
                for (int i = 1; i <= 3; i++)
                {
                    float radius = rangeStep * i;
                    if (RadarStyle == 0)
                    {
                        // 方形用矩形
                        var rectMin = radarCenter - new Vector2(radius);
                        var rectMax = radarCenter + new Vector2(radius);
                        drawList.AddRect(rectMin, rectMax, _cachedGridColor);
                    }
                    else
                    {
                        drawList.AddCircle(radarCenter, radius, _cachedGridColor);
                    }
                }
            }
            
            // 中心十字線
            drawList.AddLine(new Vector2(radarCenter.X, radarMin.Y), new Vector2(radarCenter.X, radarMax.Y), _cachedGridColor);
            drawList.AddLine(new Vector2(radarMin.X, radarCenter.Y), new Vector2(radarMax.X, radarCenter.Y), _cachedGridColor);
            
            // FOV 圓錐
            if (ShowFOVCone && localPlayer.Rotation != Vector3.Zero)
            {
                float fovAngle = 90f; // 90度 FOV
                float fovRad = fovAngle * MathF.PI / 180f;
                float coneLength = RadarSize / 2;
                float yaw = localPlayer.Rotation.Y;
                
                float yawRad = yaw * MathF.PI / 180f;
                drawList.AddLine(radarCenter, radarCenter + new Vector2(MathF.Cos(yawRad - fovRad / 2) * coneLength, MathF.Sin(yawRad - fovRad / 2) * coneLength), ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 0, 0.3f)));
                drawList.AddLine(radarCenter, radarCenter + new Vector2(MathF.Cos(yawRad + fovRad / 2) * coneLength, MathF.Sin(yawRad + fovRad / 2) * coneLength), ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 0, 0.3f)));
            }
            
            // 玩家方向箭頭（自己）
            if (ShowDirectionArrows && localPlayer.Rotation != Vector3.Zero)
            {
                DrawArrow(drawList, radarCenter, localPlayer.Rotation.Y, 6f, ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 1)));
            }
            
            // 中心點
            drawList.AddCircleFilled(radarCenter, 4f, ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 1)));
            
            // 繪製玩家
            foreach (var player in players)
            {
                if (player == null || !player.IsValid) continue;
                if (player.Position == Vector3.Zero) continue;
                if (player.IsTeammate && !ShowTeammates) continue;
                if (!player.IsTeammate && !ShowEnemies) continue;
                if (player.IsBot && !ShowBots) continue;
                
                Vector2 dotPos = WorldToRadar(player.Position, localPlayer.Position, localPlayer.Rotation.Y, radarCenter, scale);
                
                if (!IsInRadar(dotPos, radarMin, radarMax, RadarStyle)) continue;
                
                // 選擇顏色
                uint color = player.IsTeammate ? _cachedTeammateColor : player.IsBot ? _cachedBotColor : _cachedEnemyColor;
                float dotSize = player.IsBot ? 3f : 4f;
                
                // 脈衝效果
                if (PulseEnemies && !player.IsTeammate)
                {
                    float pulse = GetEnemyPulse(time);
                    color = ImGui.ColorConvertFloat4ToU32(new Vector4(EnemyR, EnemyG, EnemyB, pulse));
                }
                
                // Snap Line
                if (ShowSnapLines)
                {
                    drawList.AddLine(radarCenter, dotPos, color, 0.5f);
                }
                
                // 方向箭頭
                if (ShowDirectionArrows && player.Rotation != Vector3.Zero)
                {
                    DrawArrow(drawList, dotPos, player.Rotation.Y, 5f, color);
                }
                
                // 玩家點
                drawList.AddCircleFilled(dotPos, dotSize, color);
                
                // 名字
                if (ShowPlayerNames && !string.IsNullOrEmpty(player.Name))
                {
                    drawList.AddText(dotPos + new Vector2(6, -8), color, player.Name);
                }
                
                // 血量
                if (ShowPlayerHealth && player.Health > 0)
                {
                    float healthPct = player.Health / 100f;
                    Vector2 hpBarMin = dotPos + new Vector2(-10, 6);
                    Vector2 hpBarMax = dotPos + new Vector2(10, 9);
                    drawList.AddRectFilled(hpBarMin, hpBarMax, ImGui.ColorConvertFloat4ToU32(new Vector4(0, 0, 0, 0.6f)));
                    hpBarMax.X = hpBarMin.X + 20f * healthPct;
                    uint hpColor = healthPct > 0.5f ? ImGui.ColorConvertFloat4ToU32(new Vector4(0, 1, 0, 1)) :
                                   healthPct > 0.25f ? ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 0, 1)) :
                                   ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0, 0, 1));
                    drawList.AddRectFilled(hpBarMin, hpBarMax, hpColor);
                }
                
                // 距離
                if (ShowPlayerDistance)
                {
                    float dist = Vector3.Distance(localPlayer.Position, player.Position);
                    string distText = dist > 1000 ? $"{dist / 1000f:F1}km" : $"{dist:F0}m";
                    drawList.AddText(dotPos + new Vector2(6, 2), ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 0.8f)), distText);
                }
            }
            
            // 標題
            drawList.AddText(radarMin + new Vector2(4, -18), ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 0.8f)), "RADAR");
            
            // 範圍顯示
            if (ShowPlayerDistance)
            {
                string rangeText = $"Range: {RadarRange:F0}m";
                if (ZoomEnabled) rangeText += $" (Zoom: {ZoomLevel:F1}x)";
                drawList.AddText(radarMin + new Vector2(4, RadarSize + 4), ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 0.6f)), rangeText);
            }
        }
    }
}
