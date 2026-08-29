using System.Numerics;
using DeltaForce_External.Classes;
using DeltaForce_External.Data;

namespace DeltaForce_External.Modules
{
    /// <summary>
    /// NoRecoil module for Delta Force: Hawk Ops
    /// Eliminates weapon recoil by countering the AimPunchAngle
    /// UE4 path: Character → AimPunchAngle (view punch from shooting)
    /// 
    /// How it works:
    /// 1. Read current AimPunchAngle (recoil offset applied by game)
    /// 2. Apply opposite angle to negate the recoil
    /// 3. Continuously update while shooting
    /// 
    /// Offsets needed (use Dumper-7 to find):
    /// - AimPunchAngle: the current view punch angle from recoil
    /// - AimPunchAngleVel: velocity of the punch (for prediction)
    /// - CurrentSpread: current weapon spread value
    /// </summary>
    internal class NoRecoil
    {
        // Settings
        public static bool Enabled = false;
        public static float RecoilScaleX = 1.0f; // Horizontal compensation (0 = off, 1 = full)
        public static float RecoilScaleY = 1.0f; // Vertical compensation (0 = off, 1 = full)
        public static bool PredictionMode = true; // Use velocity for smoother compensation

        // Offsets (need Dumper-7 to find actual values for Delta Force)
        // These are common UE4 offsets for weapon recoil
        private const int AimPunchAngle = 0x0;      // Vector3 - current view punch
        private const int AimPunchAngleVel = 0x0;    // Vector3 - punch velocity
        private const int AimPunchCache = 0x0;       // Vector3 - cached punch for smoothing
        private const int ShotPending = 0x0;         // bool - whether a shot is pending

        // State tracking
        private static Vector3 lastPunchAngle = Vector3.Zero;
        private static Vector3 punchDelta = Vector3.Zero;

        /// <summary>
        /// Apply no-recoil to the local player
        /// Called every frame while shooting
        /// </summary>
        public static void Update(Memory memory, IntPtr playerPawn, bool isShooting)
        {
            if (!Enabled || playerPawn == IntPtr.Zero) return;

            if (!isShooting)
            {
                // Not shooting, reset
                lastPunchAngle = Vector3.Zero;
                return;
            }

            try
            {
                // Read current AimPunchAngle
                Vector3 currentPunch = memory.Read<Vector3>(playerPawn + AimPunchAngle);

                // Calculate delta since last frame
                punchDelta = currentPunch - lastPunchAngle;
                lastPunchAngle = currentPunch;

                // Apply counter-recoil
                // The game adds punchAngle to the view, we subtract it
                float counterPitch = -currentPunch.X * RecoilScaleY; // Vertical
                float counterYaw = -currentPunch.Y * RecoilScaleX;   // Horizontal

                // Write the counter-recoil to view angles
                // This can be done via:
                // 1. Memory write to ViewAngles (external)
                // 2. Mouse movement (external, less reliable)
                // 3. CUserCmd modification (internal/hook)

                // For external, we write to the pawn's view angles
                // or use the Controller's ControlRotation
                IntPtr controller = memory.ReadPointer(playerPawn + Offsets.Pawn_Controller);
                if (controller != IntPtr.Zero)
                {
                    // Read current control rotation
                    // Apply counter-recoil offset
                    // This depends on the exact offset structure
                }
            }
            catch { }
        }

        /// <summary>
        /// Get the current recoil compensation values
        /// Used by Aimbot to adjust aim
        /// </summary>
        public static Vector3 GetCompensation()
        {
            if (!Enabled) return Vector3.Zero;
            return new Vector3(
                -punchDelta.X * RecoilScaleY,
                -punchDelta.Y * RecoilScaleX,
                0
            );
        }

        /// <summary>
        /// Apply no-spread to reduce weapon inaccuracy
        /// Writes 0 to the spread value
        /// </summary>
        public static void ApplyNoSpread(Memory memory, IntPtr playerPawn)
        {
            if (playerPawn == IntPtr.Zero) return;

            try
            {
                // Read and zero out the spread value
                // Offset depends on weapon class
                // float currentSpread = memory.ReadFloat(playerPawn + CurrentSpread);
                // memory.Write(playerPawn + CurrentSpread, 0f);
            }
            catch { }
        }
    }
}
