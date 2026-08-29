using System.Numerics;
using System.Runtime.InteropServices;
using DeltaForce_External.Classes;
using DeltaForce_External.Data;

namespace DeltaForce_External.Modules
{
    /// <summary>
    /// Triggerbot for Delta Force: Hawk Ops
    /// Automatically fires when crosshair is over an enemy
    /// 
    /// How it works:
    /// 1. Cast a ray from camera through crosshair (TraceLine)
    /// 2. Check if the hit actor is an enemy
    /// 3. If yes, simulate left mouse click
    /// 
    /// Features:
    /// - Visible check (only shoot visible enemies)
    /// - Delay (human-like reaction time)
    /// - Random delay (anti-detection)
    /// - Hotkey toggle
    /// - Team check (don't shoot teammates)
    /// - Distance limit
    /// </summary>
    internal class Triggerbot
    {
        [DllImport("user32.dll")]
        static extern void mouse_event(uint dwFlags, int dx, int dy, uint dwData, IntPtr dwExtraInfo);

        [DllImport("user32.dll")]
        static extern short GetAsyncKeyState(int vKey);

        // Mouse event flags
        private const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
        private const uint MOUSEEVENTF_LEFTUP = 0x0004;

        // Settings
        public static bool Enabled = false;
        public static bool VisibleOnly = true;
        public static bool TeamCheck = true;
        public static int TriggerKey = 0x06; // Mouse 4 (side button)
        public static float MaxDistance = 3000f;

        // Delay settings
        public static bool UseDelay = true;
        public static float MinDelay = 50f;   // Minimum delay in ms
        public static float MaxDelay = 150f;  // Maximum delay in ms
        public static bool RandomDelay = true;

        // State
        private static bool isShooting = false;
        private static float delayCounter = 0f;
        private static bool waitingForDelay = false;
        private static Random random = new();

        // Cached player list (set by main loop)
        private static List<Entity> cachedPlayers = new();
        private static Entity? cachedLocalPlayer;

        public static void SetPlayers(List<Entity> players, Entity? localPlayer)
        {
            cachedPlayers = players;
            cachedLocalPlayer = localPlayer;
        }

        /// <summary>
        /// Update triggerbot each frame
        /// </summary>
        public static void Update(Memory memory, IntPtr localPawn, IntPtr controller, float deltaTime)
        {
            if (!Enabled || localPawn == IntPtr.Zero || controller == IntPtr.Zero)
            {
                StopShooting();
                return;
            }

            // Check trigger key
            bool keyHeld = (GetAsyncKeyState(TriggerKey) & 0x8000) != 0;
            if (!keyHeld)
            {
                StopShooting();
                delayCounter = 0f;
                waitingForDelay = false;
                return;
            }

            // Cast ray from camera through crosshair
            // In UE4, TraceLine goes from camera position forward
            bool hitEnemy = TraceCrosshair(memory, localPawn, controller);

            if (hitEnemy)
            {
                if (waitingForDelay)
                {
                    // Wait for delay
                    delayCounter -= deltaTime * 1000f; // Convert to ms
                    if (delayCounter <= 0f)
                    {
                        StartShooting();
                        waitingForDelay = false;
                    }
                }
                else if (!isShooting)
                {
                    if (UseDelay)
                    {
                        // Start delay
                        waitingForDelay = true;
                        delayCounter = RandomDelay
                            ? (float)(random.NextDouble() * (MaxDelay - MinDelay) + MinDelay)
                            : MinDelay;
                    }
                    else
                    {
                        StartShooting();
                    }
                }
            }
            else
            {
                StopShooting();
                waitingForDelay = false;
                delayCounter = 0f;
            }
        }

        /// <summary>
        /// Cast a trace line through the crosshair to check for enemies
        /// </summary>
        private static bool TraceCrosshair(Memory memory, IntPtr localPawn, IntPtr controller)
        {
            // For external, we need to:
            // 1. Get camera position and direction
            // 2. Perform a trace line in the game
            // 3. Check if the hit actor is an enemy

            // Option A: Use game's built-in TraceLine (requires finding the function)
            // Option B: Calculate screen center → world position → check nearby entities
            // Option C: Use the crosshair entity check (if game provides it)

            // Simple approach: Check if any enemy is near screen center
            try
            {
                // Get screen center
                float screenCenterX = 1920f / 2f;
                float screenCenterY = 1080f / 2f;

                // Check if any enemy is close to crosshair
                // This is a simplified check - real triggerbot uses TraceLine
                foreach (var entity in cachedPlayers)
                {
                    if (entity == null || !entity.IsValid) continue;
                    if (entity.Position2D == new Vector2(-99, -99)) continue;

                    // Check distance to crosshair
                    float distToCrosshair = Vector2.Distance(
                        entity.Head2D,
                        new Vector2(screenCenterX, screenCenterY)
                    );

                    // If enemy head is near crosshair (within 30 pixels)
                    if (distToCrosshair < 30f)
                    {
                        // Check visibility
                        if (VisibleOnly && !entity.IsVisible) continue;

                        // Check team
                        if (TeamCheck && cachedLocalPlayer != null && entity.TeamId == cachedLocalPlayer.TeamId) continue;

                        // Check distance
                        if (entity.Distance > MaxDistance) continue;

                        return true;
                    }
                }
            }
            catch { }

            return false;
        }

        /// <summary>
        /// Start shooting (mouse down)
        /// </summary>
        private static void StartShooting()
        {
            if (!isShooting)
            {
                mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, IntPtr.Zero);
                isShooting = true;
            }
        }

        /// <summary>
        /// Stop shooting (mouse up)
        /// </summary>
        private static void StopShooting()
        {
            if (isShooting)
            {
                mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, IntPtr.Zero);
                isShooting = false;
            }
        }
    }
}
