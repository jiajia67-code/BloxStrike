using System.Numerics;
using DeltaForce_External.Classes;

namespace DeltaForce_External.Data
{
    /// <summary>
    /// Manages all entities in Delta Force: Hawk Ops
    /// Reads from UE4 GWorld → PersistentLevel → Actors
    /// </summary>
    internal class EntityManager
    {
        private Memory memory;
        private UE4SDK sdk;
        private float[] viewMatrix = new float[16];

        public Entity? LocalPlayer { get; private set; }
        public List<Entity> Players { get; private set; } = new();
        public List<LootItem> LootItems { get; private set; } = new();
        public List<Vehicle> Vehicles { get; private set; } = new();
        public List<Grenade> Grenades { get; private set; } = new();
        public int ScreenWidth { get; set; } = 1920;
        public int ScreenHeight { get; set; } = 1080;

        public EntityManager(Memory mem, UE4SDK sdkRef)
        {
            memory = mem;
            sdk = sdkRef;
        }

        public void Update()
        {
            Players.Clear();
            LootItems.Clear();
            Vehicles.Clear();
            Grenades.Clear();

            IntPtr localPawn = sdk.GetLocalPlayerPawn();
            IntPtr localController = sdk.GetLocalPlayerController();

            if (localPawn == IntPtr.Zero || localController == IntPtr.Zero)
                return;

            // Read local player info
            LocalPlayer = ReadPlayerEntity(localPawn, localController, 0);
            if (LocalPlayer == null) return;

            // View matrix will be read from camera when available
            viewMatrix = new float[16]; // Placeholder — update with actual view matrix

            // Get all actors
            List<IntPtr> actors = sdk.GetActors();

            int playerIndex = 0;
            foreach (IntPtr actor in actors)
            {
                if (actor == localPawn) continue;

                string className = sdk.GetActorClassName(actor);

                // Classify entity by class name
                if (IsPlayerClass(className))
                {
                    playerIndex++;
                    Entity? player = ReadPlayerEntity(actor, IntPtr.Zero, playerIndex);
                    if (player != null && player.IsValid)
                        Players.Add(player);
                }
                else if (IsLootClass(className))
                {
                    LootItem? loot = ReadLootEntity(actor, className);
                    if (loot != null) LootItems.Add(loot);
                }
                else if (IsVehicleClass(className))
                {
                    Vehicle? vehicle = ReadVehicleEntity(actor, className);
                    if (vehicle != null) Vehicles.Add(vehicle);
                }
                else if (IsGrenadeClass(className))
                {
                    Grenade? grenade = ReadGrenadeEntity(actor, className);
                    if (grenade != null) Grenades.Add(grenade);
                }
            }
        }

        private Entity? ReadPlayerEntity(IntPtr pawnPtr, IntPtr controllerPtr, int index)
        {
            try
            {
                var entity = new Entity
                {
                    ActorAddress = pawnPtr,
                    PlayerIndex = index
                };

                // Read root component location
                IntPtr rootComponent = memory.ReadPointer(pawnPtr + Offsets.Actor_RootComponent);
                if (rootComponent != IntPtr.Zero)
                {
                    entity.Position = memory.Read<Vector3>(rootComponent + Offsets.SceneComponent_RelativeLocation);
                    entity.Velocity = memory.Read<Vector3>(rootComponent + Offsets.SceneComponent_ComponentVelocity);
                }

                // Read health (approximate, needs SDK dump for exact offset)
                entity.Health = 100f; // TODO: read actual health
                entity.MaxHealth = 100f;
                entity.IsAlive = entity.Health > 0;

                // Read team
                entity.TeamId = 0; // TODO: read from PlayerState

                // Read name from PlayerState
                IntPtr playerState = memory.ReadPointer(pawnPtr + Offsets.Pawn_PlayerState);
                if (playerState != IntPtr.Zero)
                {
                    IntPtr namePtr = memory.ReadPointer(playerState + Offsets.PlayerState_PlayerNamePrivate);
                    if (namePtr != IntPtr.Zero)
                        entity.Name = memory.ReadString(namePtr, 64);
                }

                // Calculate head position (pelvis + height offset)
                entity.HeadPosition = entity.Position + new Vector3(0, 0, 80f);

                // Project to 2D
                entity.Position2D = sdk.WorldToScreen(entity.Position, viewMatrix);
                entity.Head2D = sdk.WorldToScreen(entity.HeadPosition, viewMatrix);

                // Calculate distance to local player
                if (LocalPlayer != null)
                    entity.Distance = Vector3.Distance(LocalPlayer.Position, entity.Position);

                return entity;
            }
            catch
            {
                return null;
            }
        }

        private LootItem? ReadLootEntity(IntPtr actorPtr, string className)
        {
            try
            {
                var loot = new LootItem { Address = actorPtr };

                IntPtr rootComponent = memory.ReadPointer(actorPtr + Offsets.Actor_RootComponent);
                if (rootComponent != IntPtr.Zero)
                    loot.Position = memory.Read<Vector3>(rootComponent + Offsets.SceneComponent_RelativeLocation);

                loot.Position2D = sdk.WorldToScreen(loot.Position, viewMatrix);

                if (LocalPlayer != null)
                    loot.Distance = Vector3.Distance(LocalPlayer.Position, loot.Position);

                loot.ItemName = className;
                loot.ItemType = "Loot";
                loot.Quantity = 1;

                return loot;
            }
            catch
            {
                return null;
            }
        }

        private Vehicle? ReadVehicleEntity(IntPtr actorPtr, string className)
        {
            try
            {
                var vehicle = new Vehicle { Address = actorPtr };

                IntPtr rootComponent = memory.ReadPointer(actorPtr + Offsets.Actor_RootComponent);
                if (rootComponent != IntPtr.Zero)
                    vehicle.Position = memory.Read<Vector3>(rootComponent + Offsets.SceneComponent_RelativeLocation);

                vehicle.Position2D = sdk.WorldToScreen(vehicle.Position, viewMatrix);

                if (LocalPlayer != null)
                    vehicle.Distance = Vector3.Distance(LocalPlayer.Position, vehicle.Position);

                vehicle.Health = 1000f;
                vehicle.MaxHealth = 1000f;

                return vehicle;
            }
            catch
            {
                return null;
            }
        }

        private Grenade? ReadGrenadeEntity(IntPtr actorPtr, string className)
        {
            try
            {
                var grenade = new Grenade { Address = actorPtr };

                IntPtr rootComponent = memory.ReadPointer(actorPtr + Offsets.Actor_RootComponent);
                if (rootComponent != IntPtr.Zero)
                    grenade.Position = memory.Read<Vector3>(rootComponent + Offsets.SceneComponent_RelativeLocation);

                grenade.Position2D = sdk.WorldToScreen(grenade.Position, viewMatrix);
                grenade.GrenadeType = className;
                grenade.Velocity = Vector3.Zero;

                return grenade;
            }
            catch
            {
                return null;
            }
        }

        private bool IsPlayerClass(string className)
        {
            return className.Contains("Player", StringComparison.OrdinalIgnoreCase) ||
                   className.Contains("Character", StringComparison.OrdinalIgnoreCase) ||
                   className.Contains("Pawn", StringComparison.OrdinalIgnoreCase);
        }

        private bool IsLootClass(string className)
        {
            return className.Contains("Pickup", StringComparison.OrdinalIgnoreCase) ||
                   className.Contains("Item", StringComparison.OrdinalIgnoreCase) ||
                   className.Contains("Loot", StringComparison.OrdinalIgnoreCase) ||
                   className.Contains("WeaponPickup", StringComparison.OrdinalIgnoreCase);
        }

        private bool IsVehicleClass(string className)
        {
            return className.Contains("Vehicle", StringComparison.OrdinalIgnoreCase) ||
                   className.Contains("Car", StringComparison.OrdinalIgnoreCase) ||
                   className.Contains("Tank", StringComparison.OrdinalIgnoreCase) ||
                   className.Contains("Helicopter", StringComparison.OrdinalIgnoreCase);
        }

        private bool IsGrenadeClass(string className)
        {
            return className.Contains("Grenade", StringComparison.OrdinalIgnoreCase) ||
                   className.Contains("Projectile", StringComparison.OrdinalIgnoreCase) ||
                   className.Contains("Flash", StringComparison.OrdinalIgnoreCase) ||
                   className.Contains("Smoke", StringComparison.OrdinalIgnoreCase);
        }
    }
}
