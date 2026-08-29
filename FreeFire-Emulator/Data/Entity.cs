using System.Numerics;

namespace FreeFire_Emulator.Data
{
    /// <summary>
    /// Entity — 使用真實 Free Fire offset
    /// </summary>
    internal class Entity
    {
        // ── 基本資訊 ──
        public IntPtr Address;
        public string Name = "";
        public int PlayerID;
        public float Health;
        public float MaxHealth;
        public bool IsDead;
        public bool IsBot;
        public bool IsTeam;
        public bool IsVisible;
        public float Distance;

        // ── 位置 ──
        public Vector3 Position;
        public Vector3 HeadPosition;

        // ── 骨骼 ──
        public Vector3 Head;
        public Vector3 Neck;
        public Vector3 Spine;
        public Vector3 Hip;
        public Vector3 LeftHand;
        public Vector3 RightHand;
        public Vector3 LeftElbow;
        public Vector3 RightElbow;
        public Vector3 LeftFoot;
        public Vector3 RightFoot;
        public Vector3 LeftAnkle;
        public Vector3 RightAnkle;
        public Vector3 LeftShoulder;
        public Vector3 RightShoulder;

        // ── 武器 ──
        public int WeaponID;
        public string WeaponName = "";

        // ── 螢幕座標 ──
        public Vector2 ScreenPos;
        public Vector2 HeadScreen;
        public Vector2 FootScreen;

        // ── 旋轉 ──
        public Vector3 Rotation; // Y = Yaw, X = Pitch, Z = Roll

        // ── 狀態 ──
        public bool IsFiring;
        public bool IsGirl;
        public bool IsGhostMode;

        // ── 別名（給其他模組用） ──
        public Vector2 Position2D
        {
            get => ScreenPos;
            set => ScreenPos = value;
        }

        public Vector2 Head2D
        {
            get => HeadScreen;
            set => HeadScreen = value;
        }

        public bool IsTeammate
        {
            get => IsTeam;
            set => IsTeam = value;
        }

        public bool IsAlive
        {
            get => !IsDead;
            set => IsDead = !value;
        }

        public Vector2 ActorAddress
        {
            get => new Vector2(Address.ToInt64(), 0);
        }

        public int PlayerIndex { get; set; }

        public bool IsValid => Address != IntPtr.Zero && !IsDead;
    }
}
