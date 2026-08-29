using System.Numerics;
using FreeFire_Emulator.Classes;
using FreeFire_Emulator.Data;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// NoRecoil for Free Fire (Unity IL2CPP)
    /// 
    /// IL2CPP offsets from dump:
    /// - PlayerAttributes.GetScatterRate = 0x1f7aa00 (weapon recoil)
    /// - PlayerAttributes.GetWeaponRunSpeedScale = 0x1f77314 (speed)
    /// 
    /// How it works:
    /// 1. Hook or patch GetScatterRate() to return 0
    /// 2. Or write 0 to the scatter rate field directly
    /// 3. For external: modify the return value in memory
    /// 
    /// Unity IL2CPP method calling:
    /// The method address is in libil2cpp.so
    /// We can NOP the method or redirect to return 0
    /// </summary>
    internal class NoRecoil
    {
        // Settings
        public static bool Enabled = false;
        public static float RecoilScale = 0f; // 0 = no recoil, 1 = full recoil

        // IL2CPP Method offsets (from dump)
        private const int GetScatterRate = 0x1f7aa00;  // PlayerAttributes.GetScatterRate
        private const int GetWeaponRunSpeedScale = 0x1f77314; // PlayerAttributes.GetWeaponRunSpeedScale

        // ARM64 NOP sled: 0xD503201F
        private static readonly byte[] NopSled = [0x1F, 0x20, 0x03, 0xD5];
        // ARM64 MOV W0, #0; RET: 0x0000A0E3 0x1EFF2FE1
        private static readonly byte[] ReturnZero = [0xE3, 0xA0, 0x00, 0x00, 0xE1, 0x2F, 0xFF, 0x1E];

        private static Memory? memory;
        private static IL2CppSDK? il2cpp;
        private static bool patched = false;
        private static byte[]? originalBytes;

        public static void Initialize(Memory mem, IL2CppSDK sdk)
        {
            memory = mem;
            il2cpp = sdk;
        }

        /// <summary>
        /// Apply or remove no-recoil patch
        /// </summary>
        public static void Update()
        {
            if (memory == null || il2cpp == null) return;

            if (Enabled && !patched)
            {
                ApplyPatch();
            }
            else if (!Enabled && patched)
            {
                RemovePatch();
            }
        }

        /// <summary>
        /// Patch GetScatterRate to return 0
        /// Replaces the method with: MOV W0, #0; RET
        /// </summary>
        private static void ApplyPatch()
        {
            try
            {
                IntPtr methodAddr = il2cpp.ModuleBase + GetScatterRate;

                // Save original bytes
                originalBytes = memory.ReadBytes(methodAddr, 8);

                // Write return 0 patch
                memory.WriteBytes(methodAddr, ReturnZero);

                patched = true;
                Console.WriteLine("[*] NoRecoil patched");
            }
            catch { }
        }

        /// <summary>
        /// Restore original GetScatterRate
        /// </summary>
        private static void RemovePatch()
        {
            try
            {
                if (originalBytes == null) return;

                IntPtr methodAddr = il2cpp.ModuleBase + GetScatterRate;
                memory.WriteBytes(methodAddr, originalBytes);

                patched = false;
                originalBytes = null;
                Console.WriteLine("[*] NoRecoil restored");
            }
            catch { }
        }

        /// <summary>
        /// Get current recoil value for aimbot compensation
        /// </summary>
        public static float GetRecoilCompensation()
        {
            return Enabled ? -RecoilScale : 0f;
        }
    }
}
