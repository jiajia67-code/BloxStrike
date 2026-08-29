using System.Numerics;
using Enlisted_External.Data;

namespace Enlisted_External.Modules
{
    internal class Chams
    {
        public static bool Enabled = false;
        public static bool PlayerChams = true;

        public static List<ChamsBox> Boxes { get; } = new();

        public struct ChamsBox
        {
            public Vector2 Min, Max;
            public bool IsEnemy;
        }

        public static void Update(Entity? localPlayer, List<Entity> players)
        {
            Boxes.Clear();
            if (!Enabled || localPlayer == null) return;

            foreach (var player in players)
            {
                if (player == null || !player.IsValid) continue;
                if (player.Position2D.X < -90 || player.Head2D.X < -90) continue;

                float entityHeight = Math.Abs(player.Head2D.Y - player.Position2D.Y);
                float halfWidth = entityHeight / 3f;
                float topY = Math.Min(player.Head2D.Y, player.Position2D.Y);
                float bottomY = Math.Max(player.Head2D.Y, player.Position2D.Y);
                float centerX = (player.Head2D.X + player.Position2D.X) / 2f;

                Boxes.Add(new ChamsBox
                {
                    Min = new(centerX - halfWidth, topY),
                    Max = new(centerX + halfWidth, bottomY),
                    IsEnemy = player.TeamId != localPlayer.TeamId,
                });
            }
        }
    }
}
