using System.Numerics;
using Enlisted_External.Data;

namespace Enlisted_External.Modules
{
    /// <summary>
    /// ESP module using Dagor Engine bone system + proper W2S
    /// Draws via Overlay console or external overlay window
    /// </summary>
    internal class ESP
    {
        public static bool PlayerESP = true;
        public static bool BoxESP = true;
        public static bool HealthBar = true;
        public static bool NameESP = true;
        public static bool WeaponESP = true;
        public static bool DistanceESP = true;
        public static bool HeadCircle = true;
        public static bool ViewDirection = true;
        public static bool Tracers = false;
        public static bool LootESP = true;
        public static bool VehicleESP = true;

        public static float MaxDistance = 3000f;

        // Draw data for external rendering
        public static List<ESPBox> DrawBoxes { get; } = new();
        public static List<ESPBone> DrawBones { get; } = new();

        public struct ESPBox
        {
            public Vector2 Min, Max;
            public float Health, MaxHealth;
            public string Name;
            public float Distance;
            public bool IsTeammate;
            public Vector2 HeadPos;
        }

        public struct ESPBone
        {
            public Vector2 From, To;
            public bool IsVisible;
        }

        public static void Update(Entity? localPlayer, List<Entity> players, float sw, float sh)
        {
            DrawBoxes.Clear();
            DrawBones.Clear();

            if (!PlayerESP || localPlayer == null) return;

            foreach (var player in players)
            {
                if (player == null || !player.IsValid) continue;
                if (player.Position2D.X < -90 || player.Head2D.X < -90) continue;
                if (player.TeamId == localPlayer.TeamId) continue;
                if (player.Distance > MaxDistance) continue;

                // 3D box corners → 2D AABB
                var corners = Classes.DagorSDK.MakeBoxCorners(player.Position);
                Classes.DagorSDK.GetBoxAABB(corners, new float[16],
                    sw, sh, out Vector2 boxMin, out Vector2 boxMax);

                // Fallback: simple height-based box
                if (boxMin.X < -90)
                {
                    float entityHeight = Math.Abs(player.Head2D.Y - player.Position2D.Y);
                    float halfWidth = entityHeight / 3f;
                    float topY = Math.Min(player.Head2D.Y, player.Position2D.Y);
                    float bottomY = Math.Max(player.Head2D.Y, player.Position2D.Y);
                    float centerX = (player.Head2D.X + player.Position2D.X) / 2f;
                    boxMin = new Vector2(centerX - halfWidth, topY);
                    boxMax = new Vector2(centerX + halfWidth, bottomY);
                }

                DrawBoxes.Add(new ESPBox
                {
                    Min = boxMin,
                    Max = boxMax,
                    Health = player.Health,
                    MaxHealth = player.MaxHealth,
                    Name = player.Name,
                    Distance = player.Distance,
                    IsTeammate = player.TeamId == localPlayer.TeamId,
                    HeadPos = player.Head2D,
                });

                // Skeleton bones
                if (player.Bones3D.Count > 0)
                {
                    // Connect known bone pairs
                    int[][] bonePairs = {
                        new[]{ 53, 22 },  // HEAD → NECK
                        new[]{ 22, 27 },  // NECK → CHEST
                        new[]{ 27, 1 },   // CHEST → PELVIS
                        new[]{ 1, 13 },   // PELVIS → LEFT_KNEE
                        new[]{ 1, 15 },   // PELVIS → RIGHT_KNEE
                    };

                    foreach (var pair in bonePairs)
                    {
                        if (player.Bones2D.ContainsKey(pair[0]) &&
                            player.Bones2D.ContainsKey(pair[1]))
                        {
                            DrawBones.Add(new ESPBone
                            {
                                From = player.Bones2D[pair[0]],
                                To = player.Bones2D[pair[1]],
                                IsVisible = true,
                            });
                        }
                    }
                }
            }
        }
    }
}
