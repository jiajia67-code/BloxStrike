using System;
using System.Numerics;
using System.Runtime.InteropServices;
using FreeFire_Emulator.Classes;
using FreeFire_Emulator.Data;
using ImGuiNET;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// ScopeOverlay — 自訂狙擊鏡疊加層
    /// 在開鏡時顯示自訂的瞄準鏡UI
    /// </summary>
    internal static class ScopeOverlay
    {
        public static bool Enabled = false;

        // 瞄準鏡樣式
        public static int ScopeStyle = 0; // 0=紅點, 1=全息, 2=ACOG, 3=狙擊鏡, 4=自訂
        public static float ScopeSize = 100f; // 瞄準鏡大小
        public static float ScopeThickness = 2f; // 線條粗細
        public static float DotSize = 4f; // 中心點大小
        public static float ScopeOpacity = 0.8f; // 透明度

        // 瞄準鏡顏色
        public static float ScopeR = 1f;
        public static float ScopeG = 0f;
        public static float ScopeB = 0f;
        public static float ScopeA = 1f;

        // 開關選項
        public static bool ShowDot = true; // 顯示中心點
        public static bool ShowCrosshair = true; // 顯示十字線
        public static bool ShowCircle = true; // 顯示圓圈
        public static bool ShowLines = true; // 顯示四條線
        public static bool OnlyWhenScoped = true; // 只在開鏡時顯示

        // 靈敏度
        public static float ScopeSensitivity = 1f;

        // IL2CPP Offsets
        private static long _isScopedOffset = 0x1C78;
        private static long _aimRotationOffset = 0x400;
        private static long _mainCameraTransformOffset = 0x24C;

        private static bool _isCurrentlyScoped = false;

        /// <summary>
        /// 繪製瞄準鏡疊加層
        /// </summary>
        public static void DrawScope(Vector2 screenCenter, bool isScoped)
        {
            if (!Enabled) return;
            if (OnlyWhenScoped && !isScoped) return;

            _isCurrentlyScoped = isScoped;

            // 計算中心點
            float centerX = screenCenter.X;
            float centerY = screenCenter.Y;

            // 根據樣式繪製
            switch (ScopeStyle)
            {
                case 0: DrawRedDot(centerX, centerY); break;
                case 1: DrawHolographic(centerX, centerY); break;
                case 2: DrawACOG(centerX, centerY); break;
                case 3: DrawSniperScope(centerX, centerY); break;
                case 4: DrawCustomScope(centerX, centerY); break;
            }
        }

        /// <summary>
        /// 紅點瞄準鏡
        /// </summary>
        private static void DrawRedDot(float cx, float cy)
        {
            var drawList = ImGuiNET.ImGui.GetWindowDrawList();
            var color = new System.Numerics.Vector4(ScopeR, ScopeG, ScopeB, ScopeOpacity);

            // 中心紅點
            if (ShowDot)
            {
                drawList.AddCircleFilled(
                    new System.Numerics.Vector2(cx, cy),
                    DotSize,
                    ImGui.ColorConvertFloat4ToU32(color)
                );
            }

            // 十字線
            if (ShowCrosshair)
            {
                float lineLen = ScopeSize * 0.3f;
                drawList.AddLine(
                    new System.Numerics.Vector2(cx - lineLen, cy),
                    new System.Numerics.Vector2(cx + lineLen, cy),
                    ImGui.ColorConvertFloat4ToU32(color),
                    ScopeThickness
                );
                drawList.AddLine(
                    new System.Numerics.Vector2(cx, cy - lineLen),
                    new System.Numerics.Vector2(cx, cy + lineLen),
                    ImGui.ColorConvertFloat4ToU32(color),
                    ScopeThickness
                );
            }
        }

        /// <summary>
        /// 全息瞄準鏡
        /// </summary>
        private static void DrawHolographic(float cx, float cy)
        {
            var drawList = ImGuiNET.ImGui.GetWindowDrawList();
            var color = new System.Numerics.Vector4(ScopeR, ScopeG, ScopeB, ScopeOpacity);

            // 中心圓點
            if (ShowDot)
            {
                drawList.AddCircleFilled(
                    new System.Numerics.Vector2(cx, cy),
                    DotSize * 0.8f,
                    ImGui.ColorConvertFloat4ToU32(color)
                );
            }

            // 外圈
            if (ShowCircle)
            {
                drawList.AddCircle(
                    new System.Numerics.Vector2(cx, cy),
                    ScopeSize * 0.4f,
                    ImGui.ColorConvertFloat4ToU32(color),
                    32,
                    ScopeThickness
                );
            }

            // 十字線 (斷開式)
            if (ShowCrosshair)
            {
                float innerGap = 8f;
                float lineLen = ScopeSize * 0.3f;

                // 上
                drawList.AddLine(
                    new System.Numerics.Vector2(cx, cy - innerGap),
                    new System.Numerics.Vector2(cx, cy - lineLen),
                    ImGui.ColorConvertFloat4ToU32(color), ScopeThickness
                );
                // 下
                drawList.AddLine(
                    new System.Numerics.Vector2(cx, cy + innerGap),
                    new System.Numerics.Vector2(cx, cy + lineLen),
                    ImGui.ColorConvertFloat4ToU32(color), ScopeThickness
                );
                // 左
                drawList.AddLine(
                    new System.Numerics.Vector2(cx - innerGap, cy),
                    new System.Numerics.Vector2(cx - lineLen, cy),
                    ImGui.ColorConvertFloat4ToU32(color), ScopeThickness
                );
                // 右
                drawList.AddLine(
                    new System.Numerics.Vector2(cx + innerGap, cy),
                    new System.Numerics.Vector2(cx + lineLen, cy),
                    ImGui.ColorConvertFloat4ToU32(color), ScopeThickness
                );
            }
        }

        /// <summary>
        /// ACOG 瞄準鏡
        /// </summary>
        private static void DrawACOG(float cx, float cy)
        {
            var drawList = ImGuiNET.ImGui.GetWindowDrawList();
            var color = new System.Numerics.Vector4(ScopeR, ScopeG, ScopeB, ScopeOpacity);

            // 外圈
            if (ShowCircle)
            {
                drawList.AddCircle(
                    new System.Numerics.Vector2(cx, cy),
                    ScopeSize * 0.5f,
                    ImGui.ColorConvertFloat4ToU32(color),
                    64,
                    ScopeThickness
                );
            }

            // 十字線
            if (ShowLines)
            {
                float lineLen = ScopeSize * 0.45f;
                float gap = 12f;

                // 四條線
                drawList.AddLine(new System.Numerics.Vector2(cx, cy - gap), new System.Numerics.Vector2(cx, cy - lineLen), ImGui.ColorConvertFloat4ToU32(color), ScopeThickness);
                drawList.AddLine(new System.Numerics.Vector2(cx, cy + gap), new System.Numerics.Vector2(cx, cy + lineLen), ImGui.ColorConvertFloat4ToU32(color), ScopeThickness);
                drawList.AddLine(new System.Numerics.Vector2(cx - gap, cy), new System.Numerics.Vector2(cx - lineLen, cy), ImGui.ColorConvertFloat4ToU32(color), ScopeThickness);
                drawList.AddLine(new System.Numerics.Vector2(cx + gap, cy), new System.Numerics.Vector2(cx + lineLen, cy), ImGui.ColorConvertFloat4ToU32(color), ScopeThickness);
            }

            // 中心點
            if (ShowDot)
            {
                drawList.AddCircleFilled(
                    new System.Numerics.Vector2(cx, cy),
                    DotSize,
                    ImGui.ColorConvertFloat4ToU32(color)
                );
            }
        }

        /// <summary>
        /// 狙擊鏡 (多圈+密位線)
        /// </summary>
        private static void DrawSniperScope(float cx, float cy)
        {
            var drawList = ImGuiNET.ImGui.GetWindowDrawList();
            var color = new System.Numerics.Vector4(ScopeR, ScopeG, ScopeB, ScopeOpacity);
            var dimColor = new System.Numerics.Vector4(ScopeR, ScopeG, ScopeB, ScopeOpacity * 0.5f);

            // 外圈
            drawList.AddCircle(new System.Numerics.Vector2(cx, cy), ScopeSize * 0.5f, ImGui.ColorConvertFloat4ToU32(color), 64, ScopeThickness);

            // 內圈
            drawList.AddCircle(new System.Numerics.Vector2(cx, cy), ScopeSize * 0.3f, ImGui.ColorConvertFloat4ToU32(dimColor), 32, ScopeThickness * 0.5f);

            // 十字線
            if (ShowLines)
            {
                float lineLen = ScopeSize * 0.48f;
                drawList.AddLine(new System.Numerics.Vector2(cx - lineLen, cy), new System.Numerics.Vector2(cx + lineLen, cy), ImGui.ColorConvertFloat4ToU32(color), ScopeThickness);
                drawList.AddLine(new System.Numerics.Vector2(cx, cy - lineLen), new System.Numerics.Vector2(cx, cy + lineLen), ImGui.ColorConvertFloat4ToU32(color), ScopeThickness);
            }

            // 密位線 (Mil-dots)
            for (int i = -4; i <= 4; i++)
            {
                if (i == 0) continue;
                float offset = i * (ScopeSize * 0.05f);
                drawList.AddCircleFilled(new System.Numerics.Vector2(cx + offset, cy), 1.5f, ImGui.ColorConvertFloat4ToU32(color));
                drawList.AddCircleFilled(new System.Numerics.Vector2(cx, cy + offset), 1.5f, ImGui.ColorConvertFloat4ToU32(color));
            }

            // 中心點
            if (ShowDot)
            {
                drawList.AddCircleFilled(new System.Numerics.Vector2(cx, cy), DotSize, ImGui.ColorConvertFloat4ToU32(color));
            }
        }

        /// <summary>
        /// 自訂瞄準鏡
        /// </summary>
        private static void DrawCustomScope(float cx, float cy)
        {
            var drawList = ImGuiNET.ImGui.GetWindowDrawList();
            var color = new System.Numerics.Vector4(ScopeR, ScopeG, ScopeB, ScopeOpacity);

            // X 形十字線
            if (ShowCrosshair)
            {
                float len = ScopeSize * 0.4f;
                drawList.AddLine(new System.Numerics.Vector2(cx - len, cy - len), new System.Numerics.Vector2(cx + len, cy + len), ImGui.ColorConvertFloat4ToU32(color), ScopeThickness);
                drawList.AddLine(new System.Numerics.Vector2(cx + len, cy - len), new System.Numerics.Vector2(cx - len, cy + len), ImGui.ColorConvertFloat4ToU32(color), ScopeThickness);
            }

            // 中心點
            if (ShowDot)
            {
                drawList.AddCircleFilled(new System.Numerics.Vector2(cx, cy), DotSize, ImGui.ColorConvertFloat4ToU32(color));
            }
        }

        /// <summary>
        /// 檢查是否開鏡
        /// </summary>
        public static bool IsScoped(Memory mem, long localPlayerPawn)
        {
            if (localPlayerPawn == 0) return false;
            try
            {
                return mem.ReadBool((IntPtr)(localPlayerPawn + _isScopedOffset));
            }
            catch
            {
                return false;
            }
        }
    }
}
