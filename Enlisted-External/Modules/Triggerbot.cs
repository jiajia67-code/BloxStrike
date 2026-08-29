using System.Numerics;
using System.Runtime.InteropServices;
using Enlisted_External.Data;

namespace Enlisted_External.Modules
{
    internal class Triggerbot
    {
        [DllImport("user32.dll")]
        static extern void mouse_event(uint dwFlags, int dx, int dy, uint dwData, IntPtr dwExtraInfo);

        [DllImport("user32.dll")]
        static extern short GetAsyncKeyState(int vKey);

        private const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
        private const uint MOUSEEVENTF_LEFTUP = 0x0004;

        public static bool Enabled = false;
        public static bool VisibleOnly = true;
        public static bool TeamCheck = true;
        public static int TriggerKey = 0x06; // Mouse4
        public static float MaxDistance = 3000f;

        private static bool isShooting = false;

        public static void Update(Entity? localPlayer, List<Entity> players, float screenW, float screenH)
        {
            if (!Enabled) { StopShooting(); return; }

            bool keyHeld = (GetAsyncKeyState(TriggerKey) & 0x8000) != 0;
            if (!keyHeld) { StopShooting(); return; }

            Vector2 center = new(screenW / 2, screenH / 2);
            bool hitEnemy = false;

            foreach (var entity in players)
            {
                if (entity == null || !entity.IsValid) continue;
                if (entity.Head2D.X < -90) continue;
                if (VisibleOnly && !entity.IsVisible) continue;
                if (TeamCheck && localPlayer != null && entity.TeamId == localPlayer.TeamId) continue;
                if (entity.Distance > MaxDistance) continue;

                float dist = Vector2.Distance(entity.Head2D, center);
                if (dist < 30f) { hitEnemy = true; break; }
            }

            if (hitEnemy) StartShooting();
            else StopShooting();
        }

        private static void StartShooting()
        {
            if (!isShooting) { mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, IntPtr.Zero); isShooting = true; }
        }

        private static void StopShooting()
        {
            if (isShooting) { mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, IntPtr.Zero); isShooting = false; }
        }
    }
}
