using System.Numerics;
using FreeFire_Emulator.Classes;
using FreeFire_Emulator.Data;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// Fast Reload for Free Fire (Unity IL2CPP)
    /// 
    /// IL2CPP offsets from dump:
    /// - Player.get_InSwapWeaponCD = 0x11ad6b8 (weapon swap cooldown)
    /// - PlayerAttributes.GetWeaponRunSpeedScale = 0x1f77314 (reload speed)
    /// 
    /// How it works:
    /// 1. Patch InSwapWeaponCD to always return false (no cooldown)
    /// 2. Or modify the reload timer to 0
    /// 3. For external: patch the method return value
    /// 
    /// Fast Weapon Switch (from dump):
    /// - get_InSwapWeaponCD offset: 0x11ad6b8
    /// - Patch: MOV W0, #0; RET (return false = no cooldown)
    /// </summary>
    internal class FastReload
    {
        // Settings
        public static bool Enabled = false;
        public static bool FastWeaponSwitch = false;

        // IL2CPP Method offsets (from dump)
        private const int GetInSwapWeaponCD = 0x11ad6b8; // Player.get_InSwapWeaponCD
        private const int GetWeaponRunSpeedScale = 0x1f77314; // PlayerAttributes.GetWeaponRunSpeedScale

        // ARM64 return false: MOV W0, #0; RET
        private static readonly byte[] ReturnFalse = [0xE3, 0xA0, 0x00, 0x00, 0xE1, 0x2F, 0xFF, 0x1E];
        // ARM64 return true: MOV W0, #1; RET
        private static readonly byte[] ReturnTrue = [0xE3, 0xA0, 0x01, 0x00, 0xE1, 0x2F, 0xFF, 0x1E];
        // ARM64 return 0 (for speed scale): MOV W0, #0; RET
        private static readonly byte[] ReturnZero = [0xE3, 0xA0, 0x00, 0x00, 0xE1, 0x2F, 0xFF, 0x1E];

        private static Memory? memory;
        private static IL2CppSDK? il2cpp;
        private static bool patched = false;
        private static byte[]? originalBytes;
        private static bool switchPatched = false;
        private static byte[]? originalSwitchBytes;

        public static void Initialize(Memory mem, IL2CppSDK sdk)
        {
            memory = mem;
            il2cpp = sdk;
        }

        public static void Update()
        {
            if (memory == null || il2cpp == null) return;

            // Fast Reload patch
            if (Enabled && !patched)
                ApplyReloadPatch();
            else if (!Enabled && patched)
                RemoveReloadPatch();

            // Fast Weapon Switch patch
            if (FastWeaponSwitch && !switchPatched)
                ApplySwitchPatch();
            else if (!FastWeaponSwitch && switchPatched)
                RemoveSwitchPatch();
        }

        /// <summary>
        /// Patch weapon swap cooldown to return false
        /// </summary>
        private static void ApplyReloadPatch()
        {
            try
            {
                // Patch GetWeaponRunSpeedScale to return higher value
                // This makes reload faster
                IntPtr methodAddr = il2cpp!.ModuleBase + GetWeaponRunSpeedScale;
                originalBytes = memory!.ReadBytes(methodAddr, 8);
                memory.WriteBytes(methodAddr, ReturnZero);
                patched = true;
                Console.WriteLine("[*] Fast Reload patched");
            }
            catch { }
        }

        private static void RemoveReloadPatch()
        {
            try
            {
                if (originalBytes == null) return;
                IntPtr methodAddr = il2cpp!.ModuleBase + GetWeaponRunSpeedScale;
                memory!.WriteBytes(methodAddr, originalBytes);
                patched = false;
                originalBytes = null;
                Console.WriteLine("[*] Fast Reload restored");
            }
            catch { }
        }

        /// <summary>
        /// Patch weapon swap cooldown to return false (no cooldown)
        /// </summary>
        private static void ApplySwitchPatch()
        {
            try
            {
                IntPtr methodAddr = il2cpp!.ModuleBase + GetInSwapWeaponCD;
                originalSwitchBytes = memory!.ReadBytes(methodAddr, 8);
                memory.WriteBytes(methodAddr, ReturnFalse);
                switchPatched = true;
                Console.WriteLine("[*] Fast Weapon Switch patched");
            }
            catch { }
        }

        private static void RemoveSwitchPatch()
        {
            try
            {
                if (originalSwitchBytes == null) return;
                IntPtr methodAddr = il2cpp!.ModuleBase + GetInSwapWeaponCD;
                memory!.WriteBytes(methodAddr, originalSwitchBytes);
                switchPatched = false;
                originalSwitchBytes = null;
                Console.WriteLine("[*] Fast Weapon Switch restored");
            }
            catch { }
        }
    }
}
