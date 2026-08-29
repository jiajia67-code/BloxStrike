using System.Numerics;

namespace DeltaForce_External.Data
{
    /// <summary>
    /// Delta Force: Hawk Ops memory offsets
    /// Engine: UE4 4.24
    /// Source: UnknownCheats SDK dump + GSpots + Dumper-7
    /// PC version offsets need to be found with GSpots tool
    /// </summary>
    public static class Offsets
    {
        // ============================================================
        // UE4 Core pointers (PC版需要用GSpots工具找實際offset)
        // ============================================================

        // iOS版 offset (v1.202.37101) — PC版會不同
        public static IntPtr GWorld = IntPtr.Zero;
        public static IntPtr GObjects = IntPtr.Zero;
        public static IntPtr GNames = IntPtr.Zero;

        // FName 加密函數 offset
        public const int FName_DecryptAnsi = 0x9EA3D2C;
        public const int FName_DecryptWide = 0x6244790;

        // ============================================================
        // Pattern scanning patterns (UE4 通用)
        // ============================================================
        public const string GWorld_Pattern = "48 8B 1D ?? ?? ?? ?? 48 8B 75 28 E8";
        public const string GNames_Pattern = "48 83 EC 28 48 8B 05 ?? ?? ?? ?? 48 85 C0 75 50";
        public const string TraceLine_Pattern = "40 53 55 56 57 41 54 41 56 41 57 48 81 EC";

        // ============================================================
        // UObject 基礎結構 (UE4 通用)
        // ============================================================
        public const int UObject_ObjectFlags = 0x18;
        public const int UObject_InternalIndex = 0x24;
        public const int UObject_ClassPrivate = 0x08;
        public const int UObject_NamePrivate = 0x1C;
        public const int UObject_OuterPrivate = 0x10;

        // UField
        public const int UField_Next = 0x28;

        // UStruct
        public const int UStruct_SuperStruct = 0x40;
        public const int UStruct_Children = 0x50;
        public const int UStruct_ChildProperties = 0x68;
        public const int UStruct_PropertiesSize = 0x3C;

        // UFunction
        public const int UFunction_FunctionFlags = 0xB8;
        public const int UFunction_NumParams = 0xB0;
        public const int UFunction_ParamSize = 0xB2;
        public const int UFunction_Func = 0xD8;

        // FField (UE4.25+)
        public const int FField_ClassPrivate = 0x20;
        public const int FField_Next = 0x18;
        public const int FField_NamePrivate = 0x28;

        // FProperty
        public const int FProperty_ArrayDim = 0x38;
        public const int FProperty_ElementSize = 0x3C;
        public const int FProperty_PropertyFlags = 0x40;
        public const int FProperty_Offset_Internal = 0x4C;
        public const int FProperty_Size = 0x78;

        // ============================================================
        // UWorld 結構路徑 (UE4 通用)
        // ============================================================
        public const int World_PersistentLevel = 0x30;
        public const int World_OwningGameInstance = 0x180;

        // ULevel
        public const int Level_Actors = 0x98;
        public const int Level_ActorCount = 0xA0;

        // ============================================================
        // AActor 結構 (UE4 通用)
        // ============================================================
        public const int Actor_RootComponent = 0x138;
        public const int Actor_ClassPrivate = 0x10;

        // ACharacter / APawn
        public const int Character_Mesh = 0x280;
        public const int Character_CharacterMovement = 0x290;
        public const int Pawn_Controller = 0x228;
        public const int Pawn_PlayerState = 0x220;

        // APlayerController
        public const int PlayerController_CameraManager = 0x440;
        public const int PlayerController_ViewTarget = 0x338;

        // USceneComponent
        public const int SceneComponent_RelativeLocation = 0x11C;
        public const int SceneComponent_RelativeRotation = 0x128;
        public const int SceneComponent_ComponentVelocity = 0x140;

        // USkeletalMeshComponent
        public const int SkeletalMeshComponent_CachedBoneArray = 0x590;

        // APlayerState
        public const int PlayerState_PlayerNamePrivate = 0x30;
        public const int PlayerState_PlayerId = 0x0;
        public const int PlayerState_TeamID = 0x0;

        // Health (需要用 Dumper-7 找實際 offset)
        public const int HealthComponent_Health = 0x0;
        public const int HealthComponent_MaxHealth = 0x4;

        // Weapon (需要用 Dumper-7 找實際 offset)
        public const int WeaponComponent_CurrentWeapon = 0x0;
        public const int WeaponData_WeaponName = 0x0;
        public const int WeaponData_Ammo = 0x0;

        // Camera
        public const int CameraComponent_FieldOfView = 0x200;

        // Character State (需要用 Dumper-7 找實際 offset)
        public const int Character_bIsDefusing = 0x0;
        public const int Character_bHasBomb = 0x0;
        public const int Character_bIsCrouching = 0x0;

        // Loot / Item
        public const int PickupActor_ItemName = 0x0;

        // Vehicle
        public const int Vehicle_Health = 0x0;
        public const int Vehicle_Driver = 0x0;

        // Grenade
        public const int Projectile_Thrower = 0x0;

        // ============================================================
        // Bone indices (UE4 skeleton — delta force specific)
        // ============================================================
        public static Dictionary<string, int> BoneOffsets = new()
        {
            { "head", 1 },
            { "neck", 2 },
            { "spine_01", 3 },
            { "spine_02", 4 },
            { "spine_03", 5 },
            { "pelvis", 6 },
            { "upperarm_l", 7 },
            { "lowerarm_l", 8 },
            { "hand_l", 9 },
            { "upperarm_r", 10 },
            { "lowerarm_r", 11 },
            { "hand_r", 12 },
            { "thigh_l", 13 },
            { "calf_l", 14 },
            { "foot_l", 15 },
            { "thigh_r", 16 },
            { "calf_r", 17 },
            { "foot_r", 18 },
        };
    }
}
