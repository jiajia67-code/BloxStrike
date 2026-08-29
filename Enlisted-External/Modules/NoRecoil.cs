using System.Numerics;
using Enlisted_External.Classes;
using Enlisted_External.Data;

namespace Enlisted_External.Modules
{
    internal class NoRecoil
    {
        public static bool Enabled = false;
        public static float RecoilScaleX = 1.0f;
        public static float RecoilScaleY = 1.0f;

        public static void Update(Memory memory, IntPtr playerPawn, bool isShooting)
        {
            if (!Enabled || playerPawn == IntPtr.Zero || !isShooting) return;
            // Dagor Engine: counter recoil by modifying view angles
            // Exact offset needs reverse engineering
        }

        public static Vector3 GetCompensation()
        {
            return Enabled ? new Vector3(-RecoilScaleY, -RecoilScaleX, 0) : Vector3.Zero;
        }
    }
}
