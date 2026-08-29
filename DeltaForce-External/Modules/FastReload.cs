using DeltaForce_External.Classes;
using DeltaForce_External.Data;

namespace DeltaForce_External.Modules
{
    /// <summary>
    /// Fast Reload module for Delta Force: Hawk Ops
    /// Speeds up weapon reload by modifying the reload animation timer
    /// 
    /// How it works:
    /// 1. Detect when reload starts (ReloadTime or bIsReloading flag)
    /// 2. Write a faster reload time value
    /// 3. Or skip the reload animation entirely
    /// 
    /// Offsets needed (use Dumper-7 to find):
    /// - ReloadTime: how long the reload takes (float)
    /// - bIsReloading: whether currently reloading (bool)
    /// - LastReloadTime: when reload started (float)
    /// - ReloadDuration: duration of reload animation (float)
    /// </summary>
    internal class FastReload
    {
        // Settings
        public static bool Enabled = false;
        public static float ReloadSpeedMultiplier = 0.5f; // 0.5 = 2x faster, 0.25 = 4x faster
        public static bool SkipAnimation = false; // Skip reload animation entirely

        // Offsets (need Dumper-7 to find actual values for Delta Force)
        private const int ReloadTime = 0x0;          // float - current reload timer
        private const int ReloadDuration = 0x0;       // float - total reload duration
        private const int bIsReloading = 0x0;         // bool - is currently reloading
        private const int LastReloadTime = 0x0;       // float - time when reload started
        private const int bReloadComplete = 0x0;      // bool - reload finished

        // State tracking
        private static float originalReloadDuration = 0f;
        private static bool isModified = false;

        /// <summary>
        /// Apply fast reload to the local player
        /// Called every frame
        /// </summary>
        public static void Update(Memory memory, IntPtr playerPawn)
        {
            if (!Enabled || playerPawn == IntPtr.Zero) return;

            try
            {
                // Check if currently reloading
                bool isReloading = memory.ReadBool(playerPawn + bIsReloading);

                if (isReloading)
                {
                    if (!isModified)
                    {
                        // Read original reload duration
                        originalReloadDuration = memory.ReadFloat(playerPawn + ReloadDuration);

                        if (originalReloadDuration > 0f)
                        {
                            // Apply faster reload
                            float newDuration = originalReloadDuration * ReloadSpeedMultiplier;

                            if (SkipAnimation)
                            {
                                // Set reload timer to 0 (instant reload)
                                memory.Write(playerPawn + ReloadTime, 0f);
                                memory.Write(playerPawn + ReloadDuration, 0.01f);
                            }
                            else
                            {
                                // Set faster reload duration
                                memory.Write(playerPawn + ReloadDuration, newDuration);
                            }

                            isModified = true;
                        }
                    }
                }
                else
                {
                    // Not reloading, reset state
                    if (isModified && originalReloadDuration > 0f)
                    {
                        // Restore original reload duration
                        memory.Write(playerPawn + ReloadDuration, originalReloadDuration);
                    }
                    isModified = false;
                    originalReloadDuration = 0f;
                }
            }
            catch { }
        }

        /// <summary>
        /// Force complete reload instantly
        /// Useful when you want to skip the entire reload
        /// </summary>
        public static void ForceCompleteReload(Memory memory, IntPtr playerPawn)
        {
            if (playerPawn == IntPtr.Zero) return;

            try
            {
                // Set reload to complete
                memory.Write(playerPawn + bReloadComplete, true);
                memory.Write(playerPawn + ReloadTime, 0f);

                // Also set ammo to full (if needed)
                // memory.Write(playerPawn + CurrentAmmo, MaxAmmo);
            }
            catch { }
        }

        /// <summary>
        /// Check if reload is in progress
        /// </summary>
        public static bool IsReloading(Memory memory, IntPtr playerPawn)
        {
            if (playerPawn == IntPtr.Zero) return false;

            try
            {
                return memory.ReadBool(playerPawn + bIsReloading);
            }
            catch
            {
                return false;
            }
        }
    }
}
