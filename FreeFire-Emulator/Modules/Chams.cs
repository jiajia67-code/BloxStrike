using System.Numerics;
using FreeFire_Emulator.Data;
using ImGuiNET;

namespace FreeFire_Emulator.Modules
{
    internal class Chams
    {
        public static bool Enabled = false;

        public static void Draw(Entity? localPlayer, List<Entity> players)
        {
            if (!Enabled || localPlayer == null) return;

            var drawList = ImGui.GetBackgroundDrawList();
            uint color = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0, 0, 0.4f));

            foreach (var player in players)
            {
                if (player == null || !player.IsValid) continue;
                if (player.Position2D == new Vector2(-99, -99)) continue;
                if (player.Head2D == new Vector2(-99, -99)) continue;
                if (player.IsTeammate) continue;

                float entityHeight = Math.Abs(player.Head2D.Y - player.Position2D.Y);
                float halfWidth = entityHeight / 3f;
                float topY = Math.Min(player.Head2D.Y, player.Position2D.Y);
                float bottomY = Math.Max(player.Head2D.Y, player.Position2D.Y);
                float centerX = (player.Head2D.X + player.Position2D.X) / 2f;

                drawList.AddRectFilled(new(centerX - halfWidth, topY), new(centerX + halfWidth, bottomY), color);
                drawList.AddCircleFilled(player.Head2D, Math.Clamp(8f / (player.Distance * 0.01f), 4f, 12f), color);
            }
        }
    }
}
