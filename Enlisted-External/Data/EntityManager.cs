using System.Numerics;
using Enlisted_External.Classes;

namespace Enlisted_External.Data
{
    internal class EntityManager
    {
        private Memory memory;
        private DagorSDK sdk;

        public Entity? LocalPlayer { get; private set; }
        public List<Entity> Players { get; private set; } = new();
        public List<Vehicle> Vehicles { get; private set; } = new();
        public List<LootItem> LootItems { get; private set; } = new();
        public float[] ViewMatrix { get; private set; } = new float[16];
        public int ScreenWidth { get; set; } = 1920;
        public int ScreenHeight { get; set; } = 1080;

        public EntityManager(Memory mem, DagorSDK sdkRef)
        {
            memory = mem;
            sdk = sdkRef;
        }

        public void Update()
        {
            Players.Clear();
            Vehicles.Clear();
            LootItems.Clear();
            LocalPlayer = null;

            // Update view matrix
            sdk.UpdateViewMatrix();
            ViewMatrix = new float[16];
            for (int c = 0; c < 4; c++)
                for (int r = 0; r < 4; r++)
                    ViewMatrix[c * 4 + r] = 0; // flatten for compatibility

            // Get all entities from ECS
            var entities = sdk.GetAllEntities();

            foreach (var entityInfo in entities)
            {
                try
                {
                    // Read core components
                    IntPtr entityBase = GetEntityBase(entityInfo);
                    if (entityBase == IntPtr.Zero) continue;

                    // Check if alive
                    int aliveRaw = ReadComponentByte(entityInfo, DagorSDK.CompHash.IsAlive);
                    if (aliveRaw == 0) continue;

                    // Read transform → position
                    Vector3 position = ReadTransformPosition(entityInfo);
                    if (position == Vector3.Zero) continue;

                    // Read team
                    int teamId = ReadComponentInt(entityInfo, DagorSDK.CompHash.Team);

                    // Read health
                    float hp = ReadComponentFloat(entityInfo, DagorSDK.CompHash.HitPointsHP);
                    float maxHp = ReadComponentFloat(entityInfo, DagorSDK.CompHash.HitPointsMaxHP);
                    if (maxHp <= 0) maxHp = 100f;

                    // Check if this is a soldier (has HumanNetPhys)
                    IntPtr physPtr = GetComponentPtr(entityInfo, DagorSDK.CompHash.HumanNetPhys);
                    bool isSoldier = physPtr != IntPtr.Zero;

                    // Check if local player (has BindedCamera)
                    IntPtr camId = GetComponentPtr(entityInfo, DagorSDK.CompHash.BindedCamera);
                    bool isLocalPlayer = camId != IntPtr.Zero;

                    // Read animchar for bones
                    IntPtr animcharPtr = GetComponentPtr(entityInfo, DagorSDK.CompHash.Animchar);

                    // Get velocity
                    Vector3 velocity = ReadComponentVector3(entityInfo, DagorSDK.CompHash.Velocity);

                    // Project to 2D
                    Vector2 pos2D = sdk.WorldToScreen(position, ScreenWidth, ScreenHeight);

                    // Head position from bone system
                    Vector3 headPos = position + new Vector3(0, 0, 1.7f); // default standing height
                    Vector2 head2D = new(-99, -99);

                    if (animcharPtr != IntPtr.Zero)
                    {
                        var bones = sdk.GetBonePositions(animcharPtr);
                        if (bones.ContainsKey(53)) // HEAD bone
                        {
                            headPos = bones[53];
                            head2D = sdk.WorldToScreen(headPos, ScreenWidth, ScreenHeight);
                        }

                        // Use bone-based height for box
                        if (bones.ContainsKey(1)) // PELVIS
                        {
                            float boneHeight = bones.ContainsKey(53) ? bones[53].Y - bones[1].Y : 1.7f;
                            // Adjust box corners
                        }
                    }

                    if (head2D.X < -90)
                        head2D = sdk.WorldToScreen(headPos, ScreenWidth, ScreenHeight);

                    if (isLocalPlayer)
                    {
                        LocalPlayer = new Entity
                        {
                            ActorAddress = entityBase,
                            Name = "Local",
                            TeamId = teamId,
                            Health = hp,
                            MaxHealth = maxHp,
                            Position = position,
                            Position2D = pos2D,
                            HeadPosition = headPos,
                            Head2D = head2D,
                            Velocity = velocity,
                            IsAlive = hp > 0,
                            Bones3D = animcharPtr != IntPtr.Zero ? sdk.GetBonePositions(animcharPtr) : new(),
                        };
                        continue;
                    }

                    // Calculate distance
                    float dist = LocalPlayer != null ? Vector3.Distance(LocalPlayer.Position, position) : 0;

                    Entity player = new Entity
                    {
                        ActorAddress = entityBase,
                        TeamId = teamId,
                        Health = hp,
                        MaxHealth = maxHp,
                        Position = position,
                        Position2D = pos2D,
                        HeadPosition = headPos,
                        Head2D = head2D,
                        Velocity = velocity,
                        Distance = dist,
                        IsAlive = hp > 0,
                        Bones3D = animcharPtr != IntPtr.Zero ? sdk.GetBonePositions(animcharPtr) : new(),
                    };

                    // Project bones to 2D
                    foreach (var bone in player.Bones3D)
                    {
                        player.Bones2D[bone.Key] = sdk.WorldToScreen(bone.Value, ScreenWidth, ScreenHeight);
                    }

                    if (player.IsValid)
                        Players.Add(player);
                }
                catch { }
            }
        }

        // ============================================================
        // Component Reading Helpers
        // ============================================================

        private IntPtr GetEntityBase(DagorSDK.EntityInfo info)
        {
            // This is a simplified entity base resolution
            // In real Dagor ECS, you'd walk archetype → chunk → row
            return sdk.GetComponentData(info, DagorSDK.CompHash.Transform);
        }

        private Vector3 ReadTransformPosition(DagorSDK.EntityInfo info)
        {
            IntPtr compData = sdk.GetComponentData(info, DagorSDK.CompHash.Transform);
            if (compData == IntPtr.Zero) return Vector3.Zero;

            try
            {
                // TMatrix 48B: position at float[9..11] (bytes 36..47)
                float x = memory.ReadFloat(compData + 36);
                float y = memory.ReadFloat(compData + 40);
                float z = memory.ReadFloat(compData + 44);
                return new Vector3(x, y, z);
            }
            catch { return Vector3.Zero; }
        }

        private float ReadComponentFloat(DagorSDK.EntityInfo info, uint hash)
        {
            IntPtr compData = sdk.GetComponentData(info, hash);
            if (compData == IntPtr.Zero) return 0f;
            return memory.ReadFloat(compData + 0x10);
        }

        private int ReadComponentInt(DagorSDK.EntityInfo info, uint hash)
        {
            IntPtr compData = sdk.GetComponentData(info, hash);
            if (compData == IntPtr.Zero) return 0;
            return memory.ReadInt(compData + 0x10);
        }

        private int ReadComponentByte(DagorSDK.EntityInfo info, uint hash)
        {
            IntPtr compData = sdk.GetComponentData(info, hash);
            if (compData == IntPtr.Zero) return 0;
            return memory.ReadByte(compData + 0x10);
        }

        private IntPtr GetComponentPtr(DagorSDK.EntityInfo info, uint hash)
        {
            IntPtr compData = sdk.GetComponentData(info, hash);
            if (compData == IntPtr.Zero) return IntPtr.Zero;
            return memory.ReadPointer(compData + 0x10);
        }

        private Vector3 ReadComponentVector3(DagorSDK.EntityInfo info, uint hash)
        {
            IntPtr compData = sdk.GetComponentData(info, hash);
            if (compData == IntPtr.Zero) return Vector3.Zero;
            return memory.Read<Vector3>(compData + 0x10);
        }
    }
}
