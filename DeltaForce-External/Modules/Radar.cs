using System.Numerics;
using DeltaForce_External.Data;
using ImGuiNET;

namespace DeltaForce_External.Modules
{
    /// <summary>
    /// Radar Hack for Delta Force: Hawk Ops
    /// Draws a minimap showing all player positions relative to local player
    /// 
    /// How it works:
    /// 1. Read all player positions from GWorld
    /// 2. Calculate relative position to local player
    /// 3. Draw dots on a minimap overlay
    /// 
    /// Features:
    /// - Adjustable radar size and position
    /// - Team filter (show/hide teammates)
    /// - Distance filter (max range)
    /// - Color coding (enemy = red, team = green)
    /// - Draggable radar window
    /// </summary>
    internal class Radar
    {
        // Settings
        public static bool Enabled = false;
        public static float RadarSize = 200f;        // Radar window size in pixels
        public static float RadarRange = 3000f;       // Max range to show (in game units)
        public static bool ShowTeammates = true;
        public static bool ShowEnemies = true;
        public static bool ShowVehicles = true;
        public static bool ShowLoot = false;
        public static float RadarX = 50f;             // Radar position X
        public static float RadarY = 50f;             // Radar position Y
        public static float DotSize = 4f;             // Player dot size
        public static float PlayerDotSize = 4f;
        public static float VehicleDotSize = 6f;
        public static float LootDotSize = 3f;

        // Colors
        private static uint EnemyDotColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0, 0, 1));
        private static uint TeamDotColor = ImGui.ColorConvertFloat4ToU32(new Vector4(0, 1, 0, 1));
        private static uint VehicleDotColor = ImGui.ColorConvertFloat4ToU32(new Vector4(0.3f, 0.6f, 1, 1));
        private static uint LootDotColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0.8f, 0, 0.6f));
        private static uint RadarBgColor = ImGui.ColorConvertFloat4ToU32(new Vector4(0, 0, 0, 0.4f));
        private static uint RadarBorderColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 0.3f));
        private static uint LocalDotColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 1));
        private static uint CrosshairColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 0.15f));

        /// <summary>
        /// Draw the radar overlay
        /// </summary>
        public static void Draw(Entity? localPlayer, List<Entity> players, List<Vehicle> vehicles, List<LootItem> loot)
        {
            if (!Enabled || localPlayer == null) return;

            ImDrawListPtr drawList = ImGui.GetBackgroundDrawList();

            // Radar background
            Vector2 radarMin = new(RadarX, RadarY);
            Vector2 radarMax = new(RadarX + RadarSize, RadarY + RadarSize);
            Vector2 radarCenter = new(RadarX + RadarSize / 2, RadarY + RadarSize / 2);

            // Draw background
            drawList.AddRectFilled(radarMin, radarMax, RadarBgColor, 4f);
            drawList.AddRect(radarMin, radarMax, RadarBorderColor, 4f, ImDrawFlags.None, 1f);

            // Draw crosshair lines
            drawList.AddLine(new Vector2(radarCenter.X, radarMin.Y), new Vector2(radarCenter.X, radarMax.Y), CrosshairColor);
            drawList.AddLine(new Vector2(radarMin.X, radarCenter.Y), new Vector2(radarMax.X, radarCenter.Y), CrosshairColor);

            // Draw range circles
            for (float range = RadarRange / 4; range <= RadarRange; range += RadarRange / 4)
            {
                float circleRadius = (range / RadarRange) * (RadarSize / 2);
                drawList.AddCircle(radarCenter, circleRadius, CrosshairColor, 0, 1f);
            }

            // Draw local player (center dot)
            drawList.AddCircleFilled(radarCenter, PlayerDotSize, LocalDotColor);

            // Draw players
            foreach (var player in players)
            {
                if (player == null || !player.IsValid) continue;
                if (player.Position == Vector3.Zero) continue;

                // Check team filter
                if (player.TeamId == localPlayer.TeamId && !ShowTeammates) continue;
                if (player.TeamId != localPlayer.TeamId && !ShowEnemies) continue;

                // Calculate relative position
                Vector2 relativePos = WorldToRadar(localPlayer, player, RadarRange);
                if (relativePos == Vector2.Zero) continue;

                // Check if within radar range
                float dist = Vector2.Distance(Vector2.Zero, relativePos);
                if (dist > RadarSize / 2) continue;

                // Calculate dot position on radar
                Vector2 dotPos = radarCenter + relativePos;

                // Choose color based on team
                uint dotColor = (player.TeamId == localPlayer.TeamId) ? TeamDotColor : EnemyDotColor;

                // Draw player dot
                drawList.AddCircleFilled(dotPos, PlayerDotSize, dotColor);

                // Draw direction indicator
                float yaw = player.ViewAngles.Y * (MathF.PI / 180f);
                float dirLen = 8f;
                Vector2 dirEnd = new(
                    dotPos.X + MathF.Cos(yaw) * dirLen,
                    dotPos.Y + MathF.Sin(yaw) * dirLen
                );
                drawList.AddLine(dotPos, dirEnd, dotColor, 1.5f);
            }

            // Draw vehicles
            if (ShowVehicles)
            {
                foreach (var vehicle in vehicles)
                {
                    if (vehicle == null || vehicle.Position == Vector3.Zero) continue;

                    Vector2 relativePos = WorldToRadar(localPlayer, vehicle, RadarRange);
                    if (relativePos == Vector2.Zero) continue;

                    float dist = Vector2.Distance(Vector2.Zero, relativePos);
                    if (dist > RadarSize / 2) continue;

                    Vector2 dotPos = radarCenter + relativePos;
                    drawList.AddCircleFilled(dotPos, VehicleDotSize, VehicleDotColor);
                }
            }

            // Draw loot
            if (ShowLoot)
            {
                foreach (var item in loot)
                {
                    if (item == null || item.Position == Vector3.Zero) continue;

                    Vector2 relativePos = WorldToRadar(localPlayer, item, RadarRange);
                    if (relativePos == Vector2.Zero) continue;

                    float dist = Vector2.Distance(Vector2.Zero, relativePos);
                    if (dist > RadarSize / 2) continue;

                    Vector2 dotPos = radarCenter + relativePos;
                    drawList.AddCircleFilled(dotPos, LootDotSize, LootDotColor);
                }
            }

            // Draw radar label
            Vector2 labelPos = new(RadarX + 4, RadarY + RadarSize + 4);
            drawList.AddText(labelPos, ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 0.5f)), $"Radar ({(int)RadarRange}m)");
        }

        /// <summary>
        /// Convert world position to radar-relative 2D position
        /// </summary>
        private static Vector2 WorldToRadar(Entity localPlayer, Entity target, float range)
        {
            float dx = target.Position.X - localPlayer.Position.X;
            float dy = target.Position.Y - localPlayer.Position.Y;

            // Rotate by local player's yaw
            float yaw = localPlayer.ViewAngles.Y * (MathF.PI / 180f);
            float cos = MathF.Cos(-yaw);
            float sin = MathF.Sin(-yaw);

            float rotX = dx * cos - dy * sin;
            float rotY = dx * sin + dy * cos;

            // Scale to radar size
            float scale = (RadarSize / 2) / range;
            return new Vector2(rotX * scale, rotY * scale);
        }

        /// <summary>
        /// Convert world position to radar for non-player entities
        /// </summary>
        private static Vector2 WorldToRadar(Entity localPlayer, Vector3 worldPos, float range)
        {
            float dx = worldPos.X - localPlayer.Position.X;
            float dy = worldPos.Y - localPlayer.Position.Y;

            float yaw = localPlayer.ViewAngles.Y * (MathF.PI / 180f);
            float cos = MathF.Cos(-yaw);
            float sin = MathF.Sin(-yaw);

            float rotX = dx * cos - dy * sin;
            float rotY = dx * sin + dy * cos;

            float scale = (RadarSize / 2) / range;
            return new Vector2(rotX * scale, rotY * scale);
        }

        private static Vector2 WorldToRadar(Entity localPlayer, Vehicle target, float range)
            => WorldToRadar(localPlayer, target.Position, range);

        private static Vector2 WorldToRadar(Entity localPlayer, LootItem target, float range)
            => WorldToRadar(localPlayer, target.Position, range);
    }
}
