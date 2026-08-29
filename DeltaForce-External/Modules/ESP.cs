using System.Numerics;
using System.Runtime.InteropServices;
using DeltaForce_External.Data;
using ImGuiNET;

namespace DeltaForce_External.Modules
{
    /// <summary>
    /// ESP module for Delta Force: Hawk Ops
    /// Features: Box, Health, Name, Weapon, Distance, Head Circle,
    ///           View Direction, Defusing Indicator, Bomb Carrier,
    ///           Flash Status, Helmet Indicator, Loot ESP, Vehicle ESP
    /// </summary>
    internal class ESP
    {
        // Settings
        public static bool PlayerESP = true;
        public static bool BoxESP = true;
        public static bool HealthBar = true;
        public static bool NameESP = true;
        public static bool WeaponESP = true;
        public static bool DistanceESP = true;
        public static bool HeadCircle = true;
        public static bool ViewDirection = true;
        public static bool DefusingIndicator = true;
        public static bool BombCarrier = true;
        public static bool FlashStatus = true;
        public static bool HelmetIndicator = true;
        public static bool Tracers = false;

        // Loot / Vehicle ESP
        public static bool LootESP = true;
        public static bool VehicleESP = true;
        public static bool GrenadeESP = true;

        // Colors
        private static uint EnemyColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0, 0, 1));
        private static uint TeamColor = ImGui.ColorConvertFloat4ToU32(new Vector4(0, 1, 0, 1));
        private static uint OccludedColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 0, 0.5f));
        private static uint HealthGreen = ImGui.ColorConvertFloat4ToU32(new Vector4(0, 1, 0, 1));
        private static uint HealthRed = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0, 0, 1));
        private static uint DefusingColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0.5f, 0, 1));
        private static uint BombColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 0, 1));
        private static uint LootColor = ImGui.ColorConvertFloat4ToU32(new Vector4(0.8f, 0.6f, 0.2f, 1));
        private static uint VehicleColor = ImGui.ColorConvertFloat4ToU32(new Vector4(0.3f, 0.6f, 1, 1));
        private static uint GrenadeColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0.3f, 0, 1));
        private static uint HeadCircleColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0, 1, 1));

        private static ImDrawListPtr drawList;
        private static int screenWidth = 1920;
        private static int screenHeight = 1080;

        public static void Draw(Entity? localPlayer, List<Entity> players)
        {
            if (!PlayerESP || localPlayer == null) return;

            drawList = ImGui.GetBackgroundDrawList();
            screenWidth = (int)ImGui.GetIO().DisplaySize.X;
            screenHeight = (int)ImGui.GetIO().DisplaySize.Y;

            foreach (var player in players)
            {
                if (player == null || !player.IsValid) continue;
                if (player.Position2D == new Vector2(-99, -99)) continue;
                if (player.Head2D == new Vector2(-99, -99)) continue;
                if (player.TeamId == localPlayer.TeamId) continue;

                uint color = player.IsVisible ? EnemyColor : OccludedColor;

                // Calculate box dimensions
                float entityHeight = Math.Abs(player.Head2D.Y - player.Position2D.Y);
                float halfWidth = entityHeight / 3f;
                float topY = Math.Min(player.Head2D.Y, player.Position2D.Y);
                float bottomY = Math.Max(player.Head2D.Y, player.Position2D.Y);
                float centerX = (player.Head2D.X + player.Position2D.X) / 2f;

                Vector2 boxTop = new(centerX - halfWidth, topY);
                Vector2 boxBottom = new(centerX + halfWidth, bottomY);

                // Box ESP
                if (BoxESP)
                    drawList.AddRect(boxTop, boxBottom, color, 0, ImDrawFlags.None, 2f);

                // Health Bar
                if (HealthBar)
                    DrawHealthBar(player, boxTop, boxBottom);

                // Name
                if (NameESP && !string.IsNullOrEmpty(player.Name))
                {
                    Vector2 nameSize = ImGui.CalcTextSize(player.Name);
                    Vector2 namePos = new(centerX - nameSize.X / 2, topY - nameSize.Y - 5);
                    drawList.AddText(namePos, ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 1)), player.Name);
                }

                // Weapon
                if (WeaponESP && !string.IsNullOrEmpty(player.WeaponName))
                {
                    Vector2 weaponSize = ImGui.CalcTextSize(player.WeaponName);
                    Vector2 weaponPos = new(centerX - weaponSize.X / 2, bottomY + 5);
                    drawList.AddText(weaponPos, ImGui.ColorConvertFloat4ToU32(new Vector4(0.7f, 0.7f, 0.7f, 1)), player.WeaponName);
                }

                // Distance
                if (DistanceESP)
                {
                    string distText = $"{(int)player.Distance}m";
                    Vector2 distSize = ImGui.CalcTextSize(distText);
                    Vector2 distPos = new(centerX - distSize.X / 2, bottomY + 20);
                    drawList.AddText(distPos, ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 0.7f)), distText);
                }

                // Head Circle
                if (HeadCircle)
                {
                    float radius = Math.Clamp(8f / (player.Distance * 0.01f), 4f, 15f);
                    drawList.AddCircle(player.Head2D, radius, HeadCircleColor, 0, 2f);
                }

                // View Direction
                if (ViewDirection)
                    DrawViewDirection(player);

                // Defusing Indicator
                if (DefusingIndicator && player.IsDefusing)
                {
                    string defText = "DEFUSING";
                    Vector2 defSize = ImGui.CalcTextSize(defText);
                    Vector2 defPos = new(centerX - defSize.X / 2, topY - defSize.Y - 20);
                    drawList.AddText(defPos, DefusingColor, defText);
                }

                // Bomb Carrier
                if (BombCarrier && player.HasBomb)
                {
                    string bombText = "C4";
                    Vector2 bombSize = ImGui.CalcTextSize(bombText);
                    Vector2 bombPos = new(centerX - bombSize.X / 2, topY - bombSize.Y - 35);
                    drawList.AddText(bombPos, BombColor, bombText);
                }

                // Flash Status
                if (FlashStatus && player.IsFlashed)
                {
                    string flashText = "FLASHED";
                    Vector2 flashSize = ImGui.CalcTextSize(flashText);
                    Vector2 flashPos = new(centerX + halfWidth + 5, topY);
                    drawList.AddText(flashPos, ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 0, 1)), flashText);
                }

                // Helmet Indicator
                if (HelmetIndicator)
                {
                    string helmetText = player.HasHelmet ? "HK" : "NH";
                    Vector2 helmetSize = ImGui.CalcTextSize(helmetText);
                    Vector2 helmetPos = new(centerX + halfWidth + 5, topY + 15);
                    drawList.AddText(helmetPos, ImGui.ColorConvertFloat4ToU32(new Vector4(0.5f, 0.8f, 1, 1)), helmetText);
                }

                // Tracers
                if (Tracers)
                {
                    Vector2 start = new(screenWidth / 2f, screenHeight);
                    drawList.AddLine(start, player.Position2D, color, 1f);
                }
            }

            // Loot ESP
            if (LootESP)
                DrawLootESP(localPlayer);

            // Vehicle ESP
            if (VehicleESP)
                DrawVehicleESP(localPlayer);

            // Grenade ESP
            if (GrenadeESP)
                DrawGrenadeESP();
        }

        private static void DrawHealthBar(Entity player, Vector2 boxTop, Vector2 boxBottom)
        {
            float boxWidth = boxBottom.X - boxTop.X;
            float boxHeight = boxBottom.Y - boxTop.Y;

            float healthPercent = Math.Clamp(player.Health / player.MaxHealth, 0f, 1f);
            float barHeight = boxHeight * healthPercent;

            Vector2 barTop = new(boxTop.X - 6, boxBottom.Y - barHeight);
            Vector2 barBottom = new(boxTop.X - 2, boxBottom.Y);

            // Background
            drawList.AddRectFilled(new Vector2(boxTop.X - 7, boxTop.Y), new Vector2(boxTop.X - 1, boxBottom.Y),
                ImGui.ColorConvertFloat4ToU32(new Vector4(0, 0, 0, 0.5f)));

            // Health fill
            uint healthColor = healthPercent > 0.5f ? HealthGreen : HealthRed;
            drawList.AddRectFilled(barTop, barBottom, healthColor);

            // Health text
            string hpText = $"{(int)player.Health}";
            Vector2 hpSize = ImGui.CalcTextSize(hpText);
            Vector2 hpPos = new(boxTop.X - 7 - hpSize.X, boxBottom.Y - barHeight - hpSize.Y / 2);
            drawList.AddText(hpPos, ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 0.8f)), hpText);
        }

        private static void DrawViewDirection(Entity player)
        {
            float yaw = player.ViewAngles.Y * (MathF.PI / 180f);
            float length = 30f;

            float dx = MathF.Cos(yaw) * length;
            float dy = MathF.Sin(yaw) * length;

            Vector2 end = new(player.Head2D.X + dx, player.Head2D.Y + dy);
            drawList.AddLine(player.Head2D, end, ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 0.6f)), 1.5f);

            // Arrow head
            float arrowSize = 5f;
            float arrowAngle = yaw + MathF.PI;
            Vector2 arrow1 = new(end.X + MathF.Cos(arrowAngle - 0.5f) * arrowSize, end.Y + MathF.Sin(arrowAngle - 0.5f) * arrowSize);
            Vector2 arrow2 = new(end.X + MathF.Cos(arrowAngle + 0.5f) * arrowSize, end.Y + MathF.Sin(arrowAngle + 0.5f) * arrowSize);
            drawList.AddTriangleFilled(end, arrow1, arrow2, ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 0.6f)));
        }

        private static void DrawLootESP(Entity? localPlayer)
        {
            // TODO: iterate through LootItems from EntityManager
            // Draw item name, distance, and rarity color
        }

        private static void DrawVehicleESP(Entity? localPlayer)
        {
            // TODO: iterate through Vehicles from EntityManager
            // Draw vehicle box, health bar, and driver name
        }

        private static void DrawGrenadeESP()
        {
            // TODO: iterate through Grenades from EntityManager
            // Draw grenade type, trajectory prediction
        }
    }
}
