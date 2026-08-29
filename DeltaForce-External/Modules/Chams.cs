using System.Numerics;
using DeltaForce_External.Data;
using ImGuiNET;

namespace DeltaForce_External.Modules
{
    /// <summary>
    /// Chams module for Delta Force: Hawk Ops
    /// Highlights player models through walls with colored materials
    /// 
    /// How it works (external approach):
    /// 1. Find player mesh components
    /// 2. Override the material/color on each mesh
    /// 3. Use different colors for visible vs occluded
    /// 
    /// For external, we can:
    /// - Draw 3D chams via overlay (boxes/skeleton through walls)
    /// - Modify material parameters if accessible
    /// - Use depth buffer manipulation
    /// 
    /// Note: True chams (material override) requires internal hook
    /// External can only do overlay-based chams (boxes, skeletons)
    /// </summary>
    internal class Chams
    {
        // Settings
        public static bool Enabled = false;
        public static bool PlayerChams = true;
        public static bool VehicleChams = false;
        public static bool LootChams = false;
        public static bool VisibleCheck = true;

        // Colors
        private static Vector4 _visibleEnemyColor = new(1, 0, 0, 0.8f);
        private static Vector4 _occludedEnemyColor = new(0, 0, 1, 0.6f);
        private static Vector4 _visibleTeamColor = new(0, 1, 0, 0.8f);
        private static Vector4 _occludedTeamColor = new(0, 0.5f, 0, 0.6f);
        private static Vector4 _vehicleColor = new(0.3f, 0.6f, 1, 0.7f);
        private static Vector4 _lootColor = new(1, 0.8f, 0, 0.5f);

        /// <summary>
        /// Draw chams overlay (3D boxes through walls)
        /// This is the external approach - draws colored boxes around players
        /// </summary>
        public static void Draw(Entity? localPlayer, List<Entity> players, List<Vehicle> vehicles)
        {
            if (!Enabled || localPlayer == null) return;

            ImDrawListPtr drawList = ImGui.GetBackgroundDrawList();

            // Player chams (3D boxes)
            if (PlayerChams)
            {
                foreach (var player in players)
                {
                    if (player == null || !player.IsValid) continue;
                    if (player.Position2D == new Vector2(-99, -99)) continue;
                    if (player.Head2D == new Vector2(-99, -99)) continue;

                    // Get color based on visibility and team
                    uint chamsColor = GetPlayerChamsColor(player, localPlayer);

                    // Draw 3D box through walls
                    Draw3DBoxChams(drawList, player, chamsColor);
                }
            }

            // Vehicle chams
            if (VehicleChams)
            {
                foreach (var vehicle in vehicles)
                {
                    if (vehicle == null || vehicle.Position2D == new Vector2(-99, -99)) continue;

                    uint color = ImGui.ColorConvertFloat4ToU32(_vehicleColor);
                    float boxSize = 30f;

                    Vector2 min = new(vehicle.Position2D.X - boxSize, vehicle.Position2D.Y - boxSize);
                    Vector2 max = new(vehicle.Position2D.X + boxSize, vehicle.Position2D.Y + boxSize);

                    // Draw filled box (through walls)
                    drawList.AddRectFilled(min, max, color);
                    drawList.AddRect(min, max, ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 0.8f)), 0, ImDrawFlags.None, 2f);
                }
            }
        }

        /// <summary>
        /// Get the chams color for a player
        /// </summary>
        private static uint GetPlayerChamsColor(Entity player, Entity localPlayer)
        {
            bool isTeam = player.TeamId == localPlayer.TeamId;
            bool isVisible = player.IsVisible;

            Vector4 color;
            if (isTeam)
                color = isVisible ? _visibleTeamColor : _occludedTeamColor;
            else
                color = isVisible ? _visibleEnemyColor : _occludedEnemyColor;

            return ImGui.ColorConvertFloat4ToU32(color);
        }

        /// <summary>
        /// Draw a 3D box around a player using chams colors
        /// This draws through walls (no depth test)
        /// </summary>
        private static void Draw3DBoxChams(ImDrawListPtr drawList, Entity player, uint color)
        {
            // Calculate box dimensions from head and feet positions
            float entityHeight = Math.Abs(player.Head2D.Y - player.Position2D.Y);
            float halfWidth = entityHeight / 3f;

            float topY = Math.Min(player.Head2D.Y, player.Position2D.Y);
            float bottomY = Math.Max(player.Head2D.Y, player.Position2D.Y);
            float centerX = (player.Head2D.X + player.Position2D.X) / 2f;

            Vector2 boxTop = new(centerX - halfWidth, topY);
            Vector2 boxBottom = new(centerX + halfWidth, bottomY);

            // Draw filled box (chams effect - through walls)
            drawList.AddRectFilled(boxTop, boxBottom, color);

            // Draw outline
            uint outlineColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 0.8f));
            drawList.AddRect(boxTop, boxBottom, outlineColor, 0, ImDrawFlags.None, 2f);

            // Draw head circle (chams)
            float headRadius = Math.Clamp(8f / (player.Distance * 0.01f), 4f, 12f);
            drawList.AddCircleFilled(player.Head2D, headRadius, color);
            drawList.AddCircle(player.Head2D, headRadius, outlineColor, 0, 2f);
        }

        /// <summary>
        /// Apply chams to mesh components (requires internal hook)
        /// This is a placeholder for the internal approach
        /// </summary>
        public static void ApplyMeshChams(IntPtr meshComponent, bool isVisible, bool isEnemy)
        {
            // For internal cheats, you would:
            // 1. Get the material instance from the mesh
            // 2. Override the material with a colored one
            // 3. Use depth stencil to render through walls
            //
            // Example (internal, not for external):
            // auto material = GetMaterialInstanceDynamic(mesh);
            // if (isVisible)
            //     material->SetVectorParameterValue("Color", isEnemy ? RedColor : GreenColor);
            // else
            //     material->SetVectorParameterValue("Color", isEnemy ? BlueColor : DarkGreenColor);
            //
            // For depth stencil (render through walls):
            // SetDepthStencilState(AlwaysDraw);
        }
    }
}
