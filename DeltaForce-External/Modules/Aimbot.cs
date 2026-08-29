using System.Numerics;
using System.Runtime.InteropServices;
using DeltaForce_External.Classes;
using DeltaForce_External.Data;
using ImGuiNET;

namespace DeltaForce_External.Modules
{
    /// <summary>
    /// Aimbot module for Delta Force: Hawk Ops
    /// Features: Smooth aim, bone selection, FOV circle, visibility check, aim key
    /// </summary>
    internal class Aimbot
    {
        [DllImport("user32.dll")]
        static extern short GetAsyncKeyState(int vKey);

        // Settings
        public static bool Enabled = false;
        public static bool VisibleOnly = true;
        public static bool DrawFOV = true;
        public static bool DrawTargetLine = true;

        public static float FOV = 100f;
        public static float Smooth = 5f;
        public static float MaxDistance = 3000f;
        public static int AimKey = 0x02; // Right mouse button (VK_RBUTTON)

        // Bone selection: head, neck, chest, stomach
        public static string TargetBone = "head";

        private static Memory memory;
        private static UE4SDK sdk;

        private static Entity? currentTarget;
        private static float[] currentAimAngles = new float[2]; // pitch, yaw

        public Aimbot(Memory mem, UE4SDK sdkRef)
        {
            memory = mem;
            sdk = sdkRef;
        }

        public void Update(Entity? localPlayer, List<Entity> players)
        {
            if (!Enabled || localPlayer == null || !localPlayer.IsValid) return;

            drawList = ImGui.GetBackgroundDrawList();

            // Draw FOV circle
            if (DrawFOV)
                DrawFOVCircle();

            // Find best target
            currentTarget = FindBestTarget(localPlayer, players);

            if (currentTarget == null) return;

            // Draw target line
            if (DrawTargetLine && currentTarget.Position2D != new Vector2(-99, -99))
            {
                Vector2 screenCenter = new(ImGui.GetIO().DisplaySize.X / 2, ImGui.GetIO().DisplaySize.Y / 2);
                drawList.AddLine(screenCenter, currentTarget.Position2D,
                    ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0, 0, 0.8f)), 1.5f);
            }

            // Check if aim key is held
            bool aimKeyHeld = (GetAsyncKeyState(AimKey) & 0x8000) != 0;
            if (!aimKeyHeld) return;

            // Calculate aim angles
            Vector3 targetPos = GetBonePosition(currentTarget, TargetBone);
            Vector3 eyePos = localPlayer.Position + new Vector3(0, 0, 60f); // Approximate eye height

            Vector3 delta = targetPos - eyePos;
            float distance = delta.Length();

            if (distance < 1f || distance > MaxDistance) return;

            float pitch = MathF.Atan2(-delta.Z, MathF.Sqrt(delta.X * delta.X + delta.Y * delta.Y)) * (180f / MathF.PI);
            float yaw = MathF.Atan2(delta.Y, delta.X) * (180f / MathF.PI);

            // Apply smoothing
            if (Smooth > 0)
            {
                float pitchDiff = pitch - currentAimAngles[0];
                float yawDiff = yaw - currentAimAngles[1];

                // Normalize yaw difference
                while (yawDiff > 180) yawDiff -= 360;
                while (yawDiff < -180) yawDiff += 360;

                pitch += pitchDiff / Smooth;
                yaw += yawDiff / Smooth;
            }

            currentAimAngles[0] = pitch;
            currentAimAngles[1] = yaw;

            // Apply aim (via mouse movement or memory write)
            ApplyAim(pitch, yaw);
        }

        private Entity? FindBestTarget(Entity localPlayer, List<Entity> players)
        {
            Entity? bestTarget = null;
            float bestScore = float.MaxValue;

            Vector2 screenCenter = new(ImGui.GetIO().DisplaySize.X / 2, ImGui.GetIO().DisplaySize.Y / 2);

            foreach (var player in players)
            {
                if (player == null || !player.IsValid) continue;
                if (player.TeamId == localPlayer.TeamId) continue;
                if (VisibleOnly && !player.IsVisible) continue;
                if (player.Distance > MaxDistance) continue;

                Vector2 targetPos2D = GetBonePosition2D(player, TargetBone);
                if (targetPos2D == new Vector2(-99, -99)) continue;

                // Check if target is within FOV
                float distToCrosshair = Vector2.Distance(targetPos2D, screenCenter);
                if (distToCrosshair > FOV) continue;

                // Score: prefer closer targets with lower distance to crosshair
                float score = distToCrosshair + player.Distance * 0.01f;

                if (score < bestScore)
                {
                    bestScore = score;
                    bestTarget = player;
                }
            }

            return bestTarget;
        }

        private Vector3 GetBonePosition(Entity player, string boneName)
        {
            // Try to get bone position from entity bones dictionary
            if (player.Bones3D.TryGetValue(boneName, out Vector3 bonePos))
                return bonePos;

            // Fallback: approximate bone positions
            return boneName switch
            {
                "head" => player.Position + new Vector3(0, 0, 75f),
                "neck" => player.Position + new Vector3(0, 0, 65f),
                "chest" => player.Position + new Vector3(0, 0, 45f),
                "stomach" => player.Position + new Vector3(0, 0, 30f),
                _ => player.Position + new Vector3(0, 0, 75f),
            };
        }

        private Vector2 GetBonePosition2D(Entity player, string boneName)
        {
            if (player.Bones2D.TryGetValue(boneName, out Vector2 bonePos2D))
                return bonePos2D;

            // Fallback: use head 2D
            return boneName switch
            {
                "head" => player.Head2D,
                "neck" => player.Head2D + new Vector2(0, 10),
                "chest" => new Vector2((player.Head2D.X + player.Position2D.X) / 2,
                                       (player.Head2D.Y + player.Position2D.Y) * 0.4f),
                "stomach" => new Vector2((player.Head2D.X + player.Position2D.X) / 2,
                                         (player.Head2D.Y + player.Position2D.Y) * 0.6f),
                _ => player.Head2D,
            };
        }

        private void ApplyAim(float pitch, float yaw)
        {
            // For external aimbot, we move the mouse
            // Calculate the delta from current view angles to target
            // This requires reading current view angles and calculating mouse delta

            // Alternative: write directly to view angles in memory
            // This is more reliable for external cheats
            IntPtr controller = sdk.GetLocalPlayerController();
            if (controller == IntPtr.Zero) return;

            // TODO: Find and write to the view angles memory location
            // Typically at PlayerController + ViewTarget or a camera component
        }

        private static ImDrawListPtr drawList;

        private void DrawFOVCircle()
        {
            Vector2 screenCenter = new(ImGui.GetIO().DisplaySize.X / 2, ImGui.GetIO().DisplaySize.Y / 2);
            drawList.AddCircle(screenCenter, FOV, ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 0.3f)), 0, 1.5f);
        }

        public void Disable()
        {
            Enabled = false;
            currentTarget = null;
        }
    }
}
