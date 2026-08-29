namespace FreeFire_Emulator.Data
{
    /// <summary>
    /// Free Fire India 版 offset
    /// </summary>
    internal static class OffsetsIndia
    {
        // ── IL2CPP ──
        public const nint Il2Cpp = 0x0;
        public const nint InitBase = 0xAAA5B20;
        public const nint GameFacade = 0x9EC1C48;
        public const nint StaticClass = 0x5C;

        // ── Match ──
        public const nint CurrentMatch = 0x50;
        public const nint MatchStatus = 0x3C;
        public const nint MatchState = 0x8C;
        public const nint LocalPlayer = 0x94;
        public const nint DictionaryEntities = 0x68;
        public const nint Entities = 0x68;

        // ── Player ──
        public const nint Player_IsDead = 0x50;
        public const nint Player_Name = 0x2E4;
        public const nint NickName = 0x2E8;
        public const nint Player_Data = 0x48;
        public const nint Player_ShadowBase = 0x18C8;
        public const nint ShadowState = 0x16BC;
        public const nint PhyXState = 0x78;
        public const nint XPose = 0x78;
        public const nint PlayerID = 0x268;
        public const nint UserID = 0x1D0;
        public const nint ProfileInfo = 0x18DC;
        public const nint BaseProfileInfo = 0x18DC;
        public const nint StreakWins = 0x1A4;
        public const nint IsClientBot = 0x2E4;
        public const nint isBotOffs = 0x2EC;
        public const nint HeadCollider = 0x4AC;
        public const nint Level = 0x14;
        public const nint LevelUp = 0x14B8;

        // ── Avatar ──
        public const nint AvatarManager = 0x4C8;
        public const nint Avatar = 0xA8;
        public const nint Avatar_IsVisible = 0x95;
        public const nint Avatar_Data = 0x14;
        public const nint Avatar_Data_IsTeam = 0x59;
        public const nint AvatarData = 0x18;
        public const nint IsVisible = 0x95;
        public const nint IsTeammates = 0x59;

        // ── Camera ──
        public const nint FollowCamera = 0x458;
        public const nint Camera = 0x18;
        public const nint AimRotation = 0x408;
        public const nint MainCameraTransform = 0x250;
        public const nint ViewMatrix = 0x2F4;
        public const nint ViewMatrixV1 = 0x98;
        public const nint ViewMatrixV2 = 0x24;
        public const nint undercam = 0x1FC;
        public const nint NoScope = 0xB8;

        // ── Weapon ──
        public const nint Weapon = 0x3FC;
        public const nint WeaponData = 0x58;
        public const nint WeaponRecoil = 0xC;
        public const nint WeaponOnHand = 0x54;
        public const nint CombineWeaponOnHand = 0x58;
        public const nint IsCombineWeapon = 0xD8;
        public const nint WeaponInfo = 0x64;
        public const nint WeaponID = 0x14;
        public const nint IntWeaponType = 0x64;
        public const nint UnkPlayerWeaponInfoClass = 0x4A8;
        public const nint weaponinfo = 0x8DC;
        public const nint WeaponFireComp = 0x58;
        public const nint ScatterRate = 0xC;
        public const nint WeaponDataPtr = 0x64;
        public const nint WeaponSwap = 0x1517CAC;
        public const nint GetWeaponOnHand = 0x14F8FB8;
        public const nint UnlimitedAammo = 0xD8;
        public const nint BuffWeaponAmmoClip = 0xD0;

        // ── Firing / Aim ──
        public const nint IsFiring = 0x540;
        public const nint isFiring = 0x540;
        public const nint IS_FIRING = 0x540;
        public const nint isfiring = 0x4A8;
        public const nint get_IsFiring = 0x14EADAC;
        public const nint startfiring = 0x1BADB08;
        public const nint LastAimingInfoFromWeapon = 0x978;
        public const nint StartPosition = 0x38;
        public const nint RayDir = 0x2C;
        public const nint sAim1 = 0x540;
        public const nint sAim2 = 0x978;
        public const nint sAim3 = 0x38;
        public const nint sAim4 = 0x2C;
        public const nint pomba = 0x540;
        public const nint Silent1 = 0x548;
        public const nint Silent2 = 0x980;
        public const nint silent1 = 0x948;
        public const nint silent3 = 0x38;
        public const nint silent4 = 0x2C;
        public const nint SilentAim = 0x490;
        public const nint AimRead = 0x4A8;
        public const nint AimWrite = 0x50;
        public const nint LockedAimingCollider = 0x54;
        public const nint LockedCollider = 0x54;
        public const nint Collider = 0x4A4;
        public const nint AimbotVisible = 0x4A4;
        public const nint reimandev = 0x54;
        public const nint ReplaceCollider = 0x50;

        // ── Health ──
        public const nint HealthOffsets = 0x10;
        public const nint Vida = 0x10;
        public const nint Pool_Health = 0x10;

        // ── Player Attributes ──
        public const nint PlayerAttributes = 0x4C4;
        public const nint LocalPlayerAttributes = 0x4BC;
        public const nint NoReload = 0x99;
        public const nint RunSpeedUpScale = 0x1D8;
        public const nint FallingSpeedUpScale = 0x1D4;
        public const nint m_WalkDownSpeedScale = 0x1DC;
        public const nint FastMedOffsets = 0x90;
        public const nint SpeedForceOffsets = 0x264;
        public const nint RunSpeed = 0x1C8;
        public const nint SpeedJoystickOffset = 0x44;

        // ── Fire Interval ──
        public const nint m_FireIntervalScale = 0x18C;
        public const nint m_FireIntervalScaleSkill = 0x190;
        public const nint m_FireIntervalScaleTwo = 0x19C;
        public const nint FireInterval = 0x188;
        public const nint FastFire = 0x174;
        public const nint InstantFire1 = 0x17C;
        public const nint InstantFire2 = 0x180;
        public const nint InstantFire3 = 0x184;
        public const nint InstantFire4 = 0x18C;

        // ── Damage ──
        public const nint BuffWeaponDamageScale = 0xC4;
        public const nint DamageAdditionScale = 0xB4;
        public const nint ExecuteDamageScale = 0xBC;

        // ── Game ──
        public const nint GameTimer = 0x10;
        public const nint FixedDeltaTime = 0x24;
        public const nint InSnowSlideWayDashing = 0x15E8;
        public const nint Cooldown = 0x120;
        public const nint QuickSwap = 0x528;

        // ── Observer ──
        public const nint CurrentObserver = 0xB4;
        public const nint ObserverPlayer = 0x28;
        public const nint LocalPlayerObserver = 0xB4;

        // ── Loot ──
        public const nint LootAmmoType = 0x31FC;
        public const nint LootArmorType = 0x3204;
        public const nint LootBox = 0x320C;
        public const nint LootConsumableItemType = 0x3214;
        public const nint LootItemBox = 0x321C;
        public const nint LootItemBoxAmmo = 0x3224;
        public const nint LootItemBoxArmor = 0x322C;
        public const nint LootItemBoxConsumableItem = 0x3234;
        public const nint LootItemBoxProjectile = 0x323C;
        public const nint LootItemBoxSight = 0x3244;
        public const nint LootItemBoxSoccer = 0x324C;
        public const nint LootProjectileType = 0x3254;
        public const nint LootSightType = 0x325C;
        public const nint LootSoccerType = 0x3264;
        public const nint LootWeaponType = 0x326C;

        // ── Currency ──
        public const nint Diamantes = 0x30B6E74;
        public const nint Oro = 0x30B6E64;
        public const nint HexMemale = 0x3D8;

        // ── Misc ──
        public const nint fastreviveZ = 0x173BD0C;
        public const nint BrRankOffsets = 0x5C;
        public const nint CNIKONPMDHF = 0x8551A48;
        public const nint Current_Local_Player = 0x1A93D74;
        public const nint WorldToScreenPoint = 0x844DE48;

        // ── Movement ──
        public const nint GetPosition1 = 0x18;
        public const nint GetPosition2 = 0x1C;
        public const nint MovementComponent = 0x124C;
        public const nint MoveCompPosition = 0x20;
        public const nint MoveCompVSpeed = 0x2C;
        public const nint MoveCompIsGrounded = 0x150;
        public const nint MoveCompPhysState = 0xC;
        public const nint PhysStateFlyFlag = 0x8;

        // ── Gun Tip ──
        public const nint GunTipPosition = 0x38;
        public const nint BulletHit = 0x2C;
        public const nint bisteca = 0x874;
        public const nint arma = 0x38;
        public const nint tiro = 0x2C;

        // ── Bones (India) ──
        public const nint Head = 0x460;
        public const nint Root = 0x474;
        public const nint Spine = 0x468;
        public const nint Chest = 0x464;
        public const nint Hip = 0x470;
        public const nint Pelvis = 0x404;
        public const nint Eye = 0x31C;

        public const nint LeftShoulder = 0x494;
        public const nint RightShoulder = 0x498;
        public const nint LeftElbow = 0x4A4;
        public const nint RightElbow = 0x4A8;
        public const nint LeftHand = 0x48C;
        public const nint RightHand = 0x498;
        public const nint LeftForeArm = 0x4A4;
        public const nint RightForeArm = 0x4A0;
        public const nint LeftWrist = 0x45C;
        public const nint RightWrist = 0x488;
        public const nint LeftWristJoint = 0x4A0;
        public const nint RightWristJoint = 0x49C;

        public const nint LeftCalf = 0x47C;
        public const nint RightCalf = 0x478;
        public const nint LeftFoot = 0x484;
        public const nint RightFoot = 0x480;
        public const nint LeftAnkle = 0x478;
        public const nint RightAnkle = 0x47C;

        public const nint WeaponMount = 0x4A9;
        public const nint LeftWeapon = 0x4AA;

        public const nint HeadTF = 0x3F8;
    }
}
