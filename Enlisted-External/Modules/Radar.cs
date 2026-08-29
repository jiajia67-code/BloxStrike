using System.Numerics;
using Enlisted_External.Data;

namespace Enlisted_External.Modules
{
    internal class Radar
    {
        public static bool Enabled = false;
        public static float RadarSize = 200f;
        public static float RadarRange = 3000f;
        public static bool ShowTeammates = true;
        public static bool ShowEnemies = true;

        public static List<RadarDot> Dots { get; } = new();
        public static (Vector2 min, Vector2 max, Vector2 center) RadarBounds { get; private set; }

        public struct RadarDot
        {
            public Vector2 Position;
            public bool IsEnemy;
            public bool IsVehicle;
        }

        public static void Update(Entity? localPlayer, List<Entity> players, List<Vehicle> vehicles)
        {
            Dots.Clear();

            Vector2 radarMin = new(50, 50);
            Vector2 radarMax = new(50 + RadarSize, 50 + RadarSize);
            Vector2 radarCenter = new(50 + RadarSize / 2, 50 + RadarSize / 2);
            RadarBounds = (radarMin, radarMax, radarCenter);

            if (!Enabled || localPlayer == null) return;

            foreach (var player in players)
            {
                if (player == null || !player.IsValid) continue;
                if (player.Position == Vector3.Zero) continue;
                if (player.TeamId == localPlayer.TeamId && !ShowTeammates) continue;
                if (player.TeamId != localPlayer.TeamId && !ShowEnemies) continue;

                float dx = player.Position.X - localPlayer.Position.X;
                float dy = player.Position.Y - localPlayer.Position.Y;
                float yaw = localPlayer.ViewAngles.Y * (MathF.PI / 180f);
                float cos = MathF.Cos(-yaw), sin = MathF.Sin(-yaw);
                float rotX = dx * cos - dy * sin;
                float rotY = dx * sin + dy * cos;
                float scale = (RadarSize / 2) / RadarRange;
                Vector2 dotPos = radarCenter + new Vector2(rotX * scale, rotY * scale);

                if (Vector2.Distance(radarCenter, dotPos) > RadarSize / 2) continue;

                Dots.Add(new RadarDot
                {
                    Position = dotPos,
                    IsEnemy = player.TeamId != localPlayer.TeamId,
                    IsVehicle = false,
                });
            }

            if (vehicles != null)
            {
                foreach (var v in vehicles)
                {
                    if (v == null || v.Position == Vector3.Zero) continue;
                    float dx = v.Position.X - localPlayer.Position.X;
                    float dy = v.Position.Y - localPlayer.Position.Y;
                    float yaw = localPlayer.ViewAngles.Y * (MathF.PI / 180f);
                    float cos = MathF.Cos(-yaw), sin = MathF.Sin(-yaw);
                    float rotX = dx * cos - dy * sin;
                    float rotY = dx * sin + dy * cos;
                    float scale = (RadarSize / 2) / RadarRange;
                    Vector2 dotPos = radarCenter + new Vector2(rotX * scale, rotY * scale);
                    if (Vector2.Distance(radarCenter, dotPos) > RadarSize / 2) continue;

                    Dots.Add(new RadarDot
                    {
                        Position = dotPos,
                        IsEnemy = v.TeamId != localPlayer.TeamId,
                        IsVehicle = true,
                    });
                }
            }
        }
    }
}
