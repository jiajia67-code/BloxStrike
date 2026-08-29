using System;
using System.Numerics;
using System.Runtime.InteropServices;
using FreeFire_Emulator.Classes;
using ImGuiNET;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// CrosshairOverlay — 自訂十字線疊加層
    /// 在螢幕中心顯示自訂十字線
    /// </summary>
    internal static class CrosshairOverlay
    {
        public static bool Enabled = false;

        // 十字線樣式
        public static int CrosshairStyle = 0; // 0=十字, 1=點, 2=圓圈, 3=T字, 4=自訂
        public static float CrosshairSize = 10f; // 十字線大小
        public static float CrosshairGap = 4f; // 中心間距
        public static float CrosshairThickness = 2f; // 線條粗細
        public static float DotSize = 3f; // 中心點大小

        // 十字線顏色
        public static float CrosshairR = 0f;
        public static float CrosshairG = 1f;
        public static float CrosshairB = 0f;
        public static float CrosshairA = 1f;

        // 開關選項
        public static bool ShowDot = true; // 顯示中心點
        public static bool ShowOutline = false; // 顯示外框
        public static bool DynamicColor = false; // 動態顏色 (瞄準時變色)
        public static bool HideWhenScoped = true; // 開鏡時隱藏

        // 動態顏色設定
        public static float AimColorR = 1f;
        public static float AimColorG = 0f;
        public static float AimColorB = 0f;

        /// <summary>
        /// 繪製十字線疊加層
        /// </summary>
        public static void DrawCrosshair(Vector2 screenCenter, bool isAiming, bool isScoped)
        {
            if (!Enabled) return;
            if (HideWhenScoped && isScoped) return;

            float cx = screenCenter.X;
            float cy = screenCenter.Y;

            // 選擇顏色
            var color = new System.Numerics.Vector4(CrosshairR, CrosshairG, CrosshairB, CrosshairA);
            if (DynamicColor && isAiming)
            {
                color = new System.Numerics.Vector4(AimColorR, AimColorG, AimColorB, CrosshairA);
            }

            // 根據樣式繪製
            switch (CrosshairStyle)
            {
                case 0: DrawCross(cx, cy, color); break;
                case 1: DrawDotOnly(cx, cy, color); break;
                case 2: DrawCircleCrosshair(cx, cy, color); break;
                case 3: DrawTCrosshair(cx, cy, color); break;
                case 4: DrawCustomCrosshair(cx, cy, color); break;
            }
        }

        /// <summary>
        /// 標準十字線
        /// </summary>
        private static void DrawCross(float cx, float cy, System.Numerics.Vector4 color)
        {
            var drawList = ImGuiNET.ImGui.GetWindowDrawList();
            var u32Color = ImGui.ColorConvertFloat4ToU32(color);

            // 上
            drawList.AddLine(
                new System.Numerics.Vector2(cx, cy - CrosshairGap),
                new System.Numerics.Vector2(cx, cy - CrosshairGap - CrosshairSize),
                u32Color, CrosshairThickness
            );
            // 下
            drawList.AddLine(
                new System.Numerics.Vector2(cx, cy + CrosshairGap),
                new System.Numerics.Vector2(cx, cy + CrosshairGap + CrosshairSize),
                u32Color, CrosshairThickness
            );
            // 左
            drawList.AddLine(
                new System.Numerics.Vector2(cx - CrosshairGap, cy),
                new System.Numerics.Vector2(cx - CrosshairGap - CrosshairSize, cy),
                u32Color, CrosshairThickness
            );
            // 右
            drawList.AddLine(
                new System.Numerics.Vector2(cx + CrosshairGap, cy),
                new System.Numerics.Vector2(cx + CrosshairGap + CrosshairSize, cy),
                u32Color, CrosshairThickness
            );

            // 中心點
            if (ShowDot)
            {
                drawList.AddCircleFilled(
                    new System.Numerics.Vector2(cx, cy),
                    DotSize,
                    u32Color
                );
            }

            // 外框
            if (ShowOutline)
            {
                var outlineColor = ImGui.ColorConvertFloat4ToU32(new System.Numerics.Vector4(0, 0, 0, color.W));
                float offset = CrosshairThickness;
                drawList.AddCircle(new System.Numerics.Vector2(cx, cy), DotSize + offset, outlineColor, 16, offset);
            }
        }

        /// <summary>
        /// 純點十字線
        /// </summary>
        private static void DrawDotOnly(float cx, float cy, System.Numerics.Vector4 color)
        {
            var drawList = ImGuiNET.ImGui.GetWindowDrawList();
            var u32Color = ImGui.ColorConvertFloat4ToU32(color);

            // 中心大點
            drawList.AddCircleFilled(
                new System.Numerics.Vector2(cx, cy),
                DotSize * 2,
                u32Color
            );

            // 外框
            if (ShowOutline)
            {
                var outlineColor = ImGui.ColorConvertFloat4ToU32(new System.Numerics.Vector4(0, 0, 0, color.W));
                drawList.AddCircle(new System.Numerics.Vector2(cx, cy), DotSize * 2 + 2, outlineColor, 16, 1f);
            }
        }

        /// <summary>
        /// 圓圈十字線
        /// </summary>
        private static void DrawCircleCrosshair(float cx, float cy, System.Numerics.Vector4 color)
        {
            var drawList = ImGuiNET.ImGui.GetWindowDrawList();
            var u32Color = ImGui.ColorConvertFloat4ToU32(color);

            // 外圈
            drawList.AddCircle(
                new System.Numerics.Vector2(cx, cy),
                CrosshairSize,
                u32Color,
                32,
                CrosshairThickness
            );

            // 十字線
            drawList.AddLine(new System.Numerics.Vector2(cx, cy - CrosshairGap), new System.Numerics.Vector2(cx, cy - CrosshairSize), u32Color, CrosshairThickness);
            drawList.AddLine(new System.Numerics.Vector2(cx, cy + CrosshairGap), new System.Numerics.Vector2(cx, cy + CrosshairSize), u32Color, CrosshairThickness);
            drawList.AddLine(new System.Numerics.Vector2(cx - CrosshairGap, cy), new System.Numerics.Vector2(cx - CrosshairSize, cy), u32Color, CrosshairThickness);
            drawList.AddLine(new System.Numerics.Vector2(cx + CrosshairGap, cy), new System.Numerics.Vector2(cx + CrosshairSize, cy), u32Color, CrosshairThickness);

            // 中心點
            if (ShowDot)
            {
                drawList.AddCircleFilled(new System.Numerics.Vector2(cx, cy), DotSize, u32Color);
            }
        }

        /// <summary>
        /// T 字十字線
        /// </summary>
        private static void DrawTCrosshair(float cx, float cy, System.Numerics.Vector4 color)
        {
            var drawList = ImGuiNET.ImGui.GetWindowDrawList();
            var u32Color = ImGui.ColorConvertFloat4ToU32(color);

            // 橫線
            drawList.AddLine(
                new System.Numerics.Vector2(cx - CrosshairSize, cy),
                new System.Numerics.Vector2(cx + CrosshairSize, cy),
                u32Color, CrosshairThickness
            );

            // 上方短線
            drawList.AddLine(
                new System.Numerics.Vector2(cx, cy),
                new System.Numerics.Vector2(cx, cy - CrosshairSize * 0.6f),
                u32Color, CrosshairThickness
            );

            // 中心點
            if (ShowDot)
            {
                drawList.AddCircleFilled(new System.Numerics.Vector2(cx, cy), DotSize, u32Color);
            }
        }

        /// <summary>
        /// 自訂十字線 (點+四角)
        /// </summary>
        private static void DrawCustomCrosshair(float cx, float cy, System.Numerics.Vector4 color)
        {
            var drawList = ImGuiNET.ImGui.GetWindowDrawList();
            var u32Color = ImGui.ColorConvertFloat4ToU32(color);

            // 四個角 (L形)
            float cornerLen = CrosshairSize * 0.5f;
            float cornerGap = CrosshairGap + 4f;

            // 左上
            drawList.AddLine(new System.Numerics.Vector2(cx - cornerGap, cy - cornerGap), new System.Numerics.Vector2(cx - cornerGap - cornerLen, cy - cornerGap), u32Color, CrosshairThickness);
            drawList.AddLine(new System.Numerics.Vector2(cx - cornerGap, cy - cornerGap), new System.Numerics.Vector2(cx - cornerGap, cy - cornerGap - cornerLen), u32Color, CrosshairThickness);

            // 右上
            drawList.AddLine(new System.Numerics.Vector2(cx + cornerGap, cy - cornerGap), new System.Numerics.Vector2(cx + cornerGap + cornerLen, cy - cornerGap), u32Color, CrosshairThickness);
            drawList.AddLine(new System.Numerics.Vector2(cx + cornerGap, cy - cornerGap), new System.Numerics.Vector2(cx + cornerGap, cy - cornerGap - cornerLen), u32Color, CrosshairThickness);

            // 左下
            drawList.AddLine(new System.Numerics.Vector2(cx - cornerGap, cy + cornerGap), new System.Numerics.Vector2(cx - cornerGap - cornerLen, cy + cornerGap), u32Color, CrosshairThickness);
            drawList.AddLine(new System.Numerics.Vector2(cx - cornerGap, cy + cornerGap), new System.Numerics.Vector2(cx - cornerGap, cy + cornerGap + cornerLen), u32Color, CrosshairThickness);

            // 右下
            drawList.AddLine(new System.Numerics.Vector2(cx + cornerGap, cy + cornerGap), new System.Numerics.Vector2(cx + cornerGap + cornerLen, cy + cornerGap), u32Color, CrosshairThickness);
            drawList.AddLine(new System.Numerics.Vector2(cx + cornerGap, cy + cornerGap), new System.Numerics.Vector2(cx + cornerGap, cy + cornerGap + cornerLen), u32Color, CrosshairThickness);

            // 中心點
            if (ShowDot)
            {
                drawList.AddCircleFilled(new System.Numerics.Vector2(cx, cy), DotSize, u32Color);
            }
        }
    }
}
