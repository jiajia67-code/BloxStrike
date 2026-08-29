using System.Numerics;
using System.Runtime.InteropServices;
using Enlisted_External.Classes;
using Enlisted_External.Data;

namespace Enlisted_External.Modules
{
    internal class Aimbot
    {
        [DllImport("user32.dll")]
        static extern short GetAsyncKeyState(int vKey);

        [DllImport("user32.dll")]
        static extern void mouse_event(uint dwFlags, int dx, int dy, uint dwData, IntPtr dwExtraInfo);

        public static bool Enabled = false;
        public static bool VisibleOnly = true;
        public static bool DrawFOV = true;
        public static bool DrawTargetLine = true;
        public static float FOV = 100f;
        public static float Smooth = 5f;
        public static float MaxDistance = 3000f;
        public static int AimKey = 0x02; // Right mouse button

        private const uint MOUSEEVENTF_MOVE = 0x0001;

        public static void Update(Entity? localPlayer, List<Entity> players, float screenW, float screenH)
        {
            if (!Enabled || localPlayer == null || !localPlayer.IsValid) return;

            bool keyHeld = (GetAsyncKeyState(AimKey) & 0x8000) != 0;
            if (!keyHeld) return;

            Vector2 screenCenter = new(screenW / 2, screenH / 2);
            Entity? bestTarget = null;
            float bestScore = float.MaxValue;

            foreach (var player in players)
            {
                if (player == null || !player.IsValid) continue;
                if (player.TeamId == localPlayer.TeamId) continue;
                if (VisibleOnly && !player.IsVisible) continue;
                if (player.Distance > MaxDistance) continue;
                if (player.Head2D.X < -90) continue;

                float dist = Vector2.Distance(player.Head2D, screenCenter);
                if (dist > FOV) continue;

                float score = dist + player.Distance * 0.01f;
                if (score < bestScore)
                {
                    bestScore = score;
                    bestTarget = player;
                }
            }

            if (bestTarget != null)
            {
                AimAtTarget(bestTarget.Head2D, screenCenter, screenW, screenH);
            }
        }

        private static void AimAtTarget(Vector2 target, Vector2 center, float sw, float sh)
        {
            float dx = target.X - center.X;
            float dy = target.Y - center.Y;

            // Apply smoothing
            dx /= Smooth;
            dy /= Smooth;

            // Convert to relative mouse movement
            int moveX = (int)(dx * 65536f / sw);
            int moveY = (int)(dy * 65536f / sh);

            // Move mouse
            mouse_event(MOUSEEVENTF_MOVE, moveX, moveY, 0, IntPtr.Zero);
        }

        /// <summary>
        /// Get FOV circle center and radius for rendering
        /// </summary>
        public static (Vector2 center, float radius, bool valid) GetFOVCircle(float sw, float sh)
        {
            if (!Enabled || !DrawFOV)
                return (Vector2.Zero, 0, false);

            return (new Vector2(sw / 2, sh / 2), FOV, true);
        }

        /// <summary>
        /// Get target line for rendering
        /// </summary>
        public static (Vector2 from, Vector2 to, bool valid) GetTargetLine(
            Entity? localPlayer, List<Entity> players, float sw, float sh)
        {
            if (!Enabled || !DrawTargetLine || localPlayer == null)
                return (Vector2.Zero, Vector2.Zero, false);

            Vector2 center = new(sw / 2, sh / 2);
            Entity? best = null;
            float bestScore = float.MaxValue;

            foreach (var p in players)
            {
                if (p == null || !p.IsValid || p.TeamId == localPlayer.TeamId) continue;
                if (p.Head2D.X < -90 || p.Distance > MaxDistance) continue;
                float dist = Vector2.Distance(p.Head2D, center);
                if (dist > FOV) continue;
                float score = dist + p.Distance * 0.01f;
                if (score < bestScore) { bestScore = score; best = p; }
            }

            if (best != null)
                return (center, best.Head2D, true);

            return (Vector2.Zero, Vector2.Zero, false);
        }
    }
}
