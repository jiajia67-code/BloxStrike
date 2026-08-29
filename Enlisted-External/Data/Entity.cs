using System.Numerics;

namespace Enlisted_External.Data
{
    /// <summary>
    /// Represents a soldier/player entity in Enlisted
    /// Dagor Engine uses component-based entity system
    /// </summary>
    public class Entity
    {
        // Identity
        public IntPtr ActorAddress { get; set; }
        public string Name { get; set; } = "";
        public int TeamId { get; set; }
        public int PlayerIndex { get; set; }

        // Health
        public float Health { get; set; }
        public float MaxHealth { get; set; }

        // Position
        public Vector3 Position { get; set; }
        public Vector2 Position2D { get; set; }
        public Vector3 HeadPosition { get; set; }
        public Vector2 Head2D { get; set; }

        // View
        public Vector3 ViewAngles { get; set; }
        public Vector3 ViewDirection { get; set; }

        // Velocity
        public Vector3 Velocity { get; set; }

        // Weapon
        public string WeaponName { get; set; } = "";
        public int Ammo { get; set; }
        public int MaxAmmo { get; set; }

        // State
        public bool IsAlive { get; set; }
        public bool IsVisible { get; set; }
        public bool IsCrouching { get; set; }
        public bool IsProne { get; set; }
        public bool IsSprinting { get; set; }
        public bool IsReloading { get; set; }
        public bool IsAiming { get; set; }
        public float Distance { get; set; }

        // Bones
        public Dictionary<int, Vector3> Bones3D { get; set; } = new();
        public Dictionary<int, Vector2> Bones2D { get; set; } = new();

        public bool IsValid => IsAlive && Health > 0 && Position != Vector3.Zero;
        public bool IsTeammate(int localTeam) => TeamId == localTeam;
    }

    /// <summary>
    /// Represents a vehicle in Enlisted
    /// </summary>
    public class Vehicle
    {
        public IntPtr Address { get; set; }
        public float Health { get; set; }
        public float MaxHealth { get; set; }
        public string VehicleType { get; set; } = "";
        public Vector3 Position { get; set; }
        public Vector2 Position2D { get; set; }
        public float Distance { get; set; }
        public float Speed { get; set; }
        public int TeamId { get; set; }
    }

    /// <summary>
    /// Represents a loot item in Enlisted
    /// </summary>
    public class LootItem
    {
        public IntPtr Address { get; set; }
        public string ItemName { get; set; } = "";
        public string ItemType { get; set; } = "";
        public int Quantity { get; set; }
        public Vector3 Position { get; set; }
        public Vector2 Position2D { get; set; }
        public float Distance { get; set; }
    }
}
