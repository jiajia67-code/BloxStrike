// ============================================================================
// CS2_Offsets.h — Centralized CS2 Offsets
// Generated: 2026-08-29 (Build 14178)
// Sources: a2x/cs2-dumper, sezzyaep/CS2-OFFSETS, s2v.app SchemaExplorer
// ============================================================================
#pragma once
#include <cstdint>
#include <cstddef>

// ============================================================================
// Module-Level Offsets (from cs2-dumper, 2026-08-29)
// ============================================================================
namespace CS2 {
namespace client_dll {
    // Core pointers
    constexpr ptrdiff_t dwCSGOInput                          = 0x23DBC70;
    constexpr ptrdiff_t dwEntityList                        = 0x2571220;
    constexpr ptrdiff_t dwGameEntitySystem                  = 0x2571220;
    constexpr ptrdiff_t dwGameEntitySystem_highestEntityIdx = 0x2090;
    constexpr ptrdiff_t dwGameRules                         = 0x23C5D28;
    constexpr ptrdiff_t dwGlobalVars                        = 0x20AF5F0;
    constexpr ptrdiff_t dwGlowManager                       = 0x23C2A58;
    constexpr ptrdiff_t dwLocalPlayerController             = 0x23A0F30;
    constexpr ptrdiff_t dwLocalPlayerPawn                   = 0x23C6268;
    constexpr ptrdiff_t dwPlantedC4                         = 0x2390A18;
    constexpr ptrdiff_t dwPrediction                        = 0x23C6170;
    constexpr ptrdiff_t dwSensitivity                       = 0x23C3578;
    constexpr ptrdiff_t dwSensitivity_sensitivity           = 0x58;
    constexpr ptrdiff_t dwViewAngles                        = 0x23DC2F8;
    constexpr ptrdiff_t dwViewMatrix                        = 0x23CB830;
    constexpr ptrdiff_t dwViewRender                        = 0x23CB898;
    constexpr ptrdiff_t dwWeaponC4                          = 0x233EF10;
}

namespace engine2_dll {
    constexpr ptrdiff_t dwBuildNumber                        = 0x60F594;
    constexpr ptrdiff_t dwNetworkGameClient                  = 0x90D4B0;
    constexpr ptrdiff_t dwNetworkGameClient_clientTickCount  = 0x378;
    constexpr ptrdiff_t dwNetworkGameClient_deltaTick        = 0x24C;
    constexpr ptrdiff_t dwNetworkGameClient_isBackgroundMap  = 0x2C141F;
    constexpr ptrdiff_t dwNetworkGameClient_localPlayer      = 0xF8;
    constexpr ptrdiff_t dwNetworkGameClient_maxClients       = 0x240;
    constexpr ptrdiff_t dwNetworkGameClient_serverTickCount  = 0x24C;
    constexpr ptrdiff_t dwNetworkGameClient_signOnState      = 0x230;
    constexpr ptrdiff_t dwWindowHeight                       = 0x9118D4;
    constexpr ptrdiff_t dwWindowWidth                        = 0x9118D0;
}

namespace inputsystem_dll {
    constexpr ptrdiff_t dwInputSystem                        = 0x45BA0;
}

namespace matchmaking_dll {
    constexpr ptrdiff_t dwGameTypes                          = 0x1ADF80;
}

namespace soundsystem_dll {
    constexpr ptrdiff_t dwSoundSystem                        = 0x54B5D0;
    constexpr ptrdiff_t dwSoundSystem_engineViewData         = 0x7C;
}

// ============================================================================
// Button Offsets (from sezzyaep, 2026-08-28)
// ============================================================================
namespace buttons {
    constexpr ptrdiff_t attack    = 0x20B38F0;
    constexpr ptrdiff_t attack2   = 0x20B3980;
    constexpr ptrdiff_t back      = 0x20B3BC0;
    constexpr ptrdiff_t duck      = 0x20B3E90;
    constexpr ptrdiff_t forward   = 0x20B3B30;
    constexpr ptrdiff_t jump      = 0x20B3E00;
    constexpr ptrdiff_t left      = 0x20B3C50;
    constexpr ptrdiff_t reload    = 0x20B3860;
    constexpr ptrdiff_t right     = 0x20B3CE0;
    constexpr ptrdiff_t sprint    = 0x20B37D0;
    constexpr ptrdiff_t turnleft  = 0x20B3A10;
    constexpr ptrdiff_t turnright = 0x20B3AA0;
    constexpr ptrdiff_t use       = 0x20B3D70;
    constexpr ptrdiff_t zoom      = 0x23DBB00;
    constexpr ptrdiff_t lookatweapon = 0x23DBB90;
    constexpr ptrdiff_t showscores   = 0x23DBA70;
}

// ============================================================================
// CUserCmd Ring Buffer Layout
// ============================================================================
namespace CUserCmd {
    // Ring buffer: 15 slots, each slot is a CUserCmd
    constexpr int SLOT_COUNT           = 15;
    constexpr ptrdiff_t CMD_SIZE       = 0x100;       // per-command size in ring buffer
    constexpr ptrdiff_t OFFSET_PITCH   = 0x34;        // float — view pitch
    constexpr ptrdiff_t OFFSET_YAW     = 0x38;        // float — view yaw
    constexpr ptrdiff_t OFFSET_ROLL    = 0x3C;        // float — view roll
    constexpr ptrdiff_t OFFSET_SEQ     = 0x04;        // int — command sequence number
    constexpr ptrdiff_t OFFSET_BUTTONS = 0x40;        // uint32 — button bitmask
    constexpr ptrdiff_t OFFSET_MOUSE_X = 0x28;        // int32 — accumulated mouse X
    constexpr ptrdiff_t OFFSET_MOUSE_Y = 0x2C;        // int32 — accumulated mouse Y
    constexpr ptrdiff_t OFFSET_FORWARD = 0x1C;        // float — forward move
    constexpr ptrdiff_t OFFSET_SIDE    = 0x20;        // float — side move
    constexpr ptrdiff_t OFFSET_UP      = 0x24;        // float — up move

    // Button bitmasks
    constexpr uint32_t IN_ATTACK       = (1 << 0);
    constexpr uint32_t IN_JUMP         = (1 << 1);
    constexpr uint32_t IN_DUCK         = (1 << 2);
    constexpr uint32_t IN_FORWARD      = (1 << 3);
    constexpr uint32_t IN_BACK         = (1 << 4);
    constexpr uint32_t IN_USE          = (1 << 5);
    constexpr uint32_t IN_CANCEL       = (1 << 6);
    constexpr uint32_t IN_LEFT         = (1 << 7);
    constexpr uint32_t IN_RIGHT        = (1 << 8);
    constexpr uint32_t IN_MOVELEFT     = (1 << 9);
    constexpr uint32_t IN_MOVERIGHT    = (1 << 10);
    constexpr uint32_t IN_ATTACK2      = (1 << 11);
    constexpr uint32_t IN_RUN          = (1 << 12);
    constexpr uint32_t IN_RELOAD       = (1 << 13);
    constexpr uint32_t IN_ALT1         = (1 << 14);
    constexpr uint32_t IN_ALT2         = (1 << 15);
    constexpr uint32_t IN_SCORE        = (1 << 16);
    constexpr uint32_t IN_SPEED        = (1 << 17);
    constexpr uint32_t IN_WALK         = (1 << 18);
    constexpr uint32_t IN_BULLRUSH     = (1 << 22);
}

// ============================================================================
// CCSGOInput Internal Offsets
// ============================================================================
namespace CCSGOInput {
    constexpr ptrdiff_t ViewAngles         = 0xB0;     // QAngle — current view angles
    constexpr ptrdiff_t vtable_CreateMove  = 5 * 8;    // vtable index 5 (x64: 5 * sizeof(ptr))
}

// ============================================================================
// C_BaseEntity fields
// ============================================================================
namespace C_BaseEntity {
    constexpr ptrdiff_t m_pGameSceneNode  = 0x328;     // CGameSceneNode*
    constexpr ptrdiff_t m_pCollision      = 0x320;     // CCollisionProperty*
    constexpr ptrdiff_t m_iHealth         = 0x344;     // int32
    constexpr ptrdiff_t m_iTeamNum        = 0x3CB;     // uint8
    constexpr ptrdiff_t m_fFlags          = 0x3EC;     // int32 (EntityFlags)
    constexpr ptrdiff_t m_vecAbsOrigin    = 0xD8;      // Vector (via GameSceneNode)
    constexpr ptrdiff_t m_vecVelocity     = 0x120;     // Vector
    constexpr ptrdiff_t m_nSubclassID     = 0x540;     // uint32 (weapon VData pointer offset = +0x08)
}

// ============================================================================
// C_BasePlayerPawn fields
// ============================================================================
namespace C_BasePlayerPawn {
    constexpr ptrdiff_t m_vecViewOffset    = 0xCB0;    // CNetworkViewOffsetVector (eye offset from feet)
    constexpr ptrdiff_t m_vOldOrigin       = 0x168;    // Vector — last networked origin
}

// ============================================================================
// C_CSPlayerPawnBase fields
// ============================================================================
namespace C_CSPlayerPawnBase {
    constexpr ptrdiff_t m_pClippingWeapon          = 0x1480;   // CHandle<C_CSWeaponBase>
    constexpr ptrdiff_t m_vecLastClipCameraPos     = 0x1460;   // Vector
    constexpr ptrdiff_t m_angEyeAngles             = 0x3350;   // QAngle — eye angles (from schema 2026)
    constexpr ptrdiff_t m_iPlayerState             = 0x13FC;   // CSPlayerState
    constexpr ptrdiff_t m_flFlashMaxAlpha          = 0x1424;   // float
    constexpr ptrdiff_t m_flFlashDuration          = 0x1428;   // float
    constexpr ptrdiff_t m_hOriginalController      = 0x1478;   // CHandle<CCSPlayerController>
}

// ============================================================================
// C_CSPlayerPawn fields
// ============================================================================
namespace C_CSPlayerPawn {
    constexpr ptrdiff_t m_pBulletServices           = 0x1490;  // CCSPlayer_BulletServices*
    constexpr ptrdiff_t m_pHostageServices          = 0x1498;  // CCSPlayer_HostageServices*
    constexpr ptrdiff_t m_pBuyServices              = 0x14A0;  // CCSPlayer_BuyServices*
    constexpr ptrdiff_t m_pGlowServices             = 0x14A8;  // CCSPlayer_GlowServices*
    constexpr ptrdiff_t m_pActionTrackingServices   = 0x14B0;  // CCSPlayer_ActionTrackingServices*
    constexpr ptrdiff_t m_bIsWalking                = 0x1C58;  // bool
    constexpr ptrdiff_t m_entitySpottedState        = 0x1C60;  // EntitySpottedState_t
    constexpr ptrdiff_t m_bIsScoped                 = 0x1C78;  // bool
    constexpr ptrdiff_t m_bIsDefusing               = 0x1C7A;  // bool
    constexpr ptrdiff_t m_iShotsFired               = 0x1C88;  // int32
    constexpr ptrdiff_t m_flFlinchStack             = 0x1C90;  // float
    constexpr ptrdiff_t m_flVelocityModifier        = 0x1C94;  // float
    constexpr ptrdiff_t m_ArmorValue                = 0x1CA4;  // int32
    constexpr ptrdiff_t m_bOldIsScoped              = 0x1CB4;  // bool
    constexpr ptrdiff_t m_bGunGameImmunity          = 0x3268;  // bool
    constexpr ptrdiff_t m_fImmuneToGunGameDamageTime = 0x3264; // GameTime_t
    constexpr ptrdiff_t m_angEyeAngles_v2           = 0x3350;  // QAngle (confirmed from schema)
    constexpr ptrdiff_t m_bKilledByHeadshot         = 0x1CA1;  // bool
}

// ============================================================================
// EntitySpottedState_t (sub-struct of C_CSPlayerPawn)
// ============================================================================
namespace EntitySpottedState_t {
    constexpr ptrdiff_t m_bSpotted         = 0x0;
    constexpr ptrdiff_t m_bSpottedByMask   = 0x2;    // uint16
}

// ============================================================================
// CCSPlayerController fields
// ============================================================================
namespace CCSPlayerController {
    constexpr ptrdiff_t m_hPlayerPawn      = 0x7E4;   // CHandle<C_CSPlayerPawn>
    constexpr ptrdiff_t m_bPawnIsAlive     = 0x7FC;   // bool
    constexpr ptrdiff_t m_iszPlayerName    = 0x818;   // char[32] (via CBasePlayerController)
    constexpr ptrdiff_t m_iTeamNum         = 0x7F3;   // uint8 (controller team)
}

// ============================================================================
// CBasePlayerController fields
// ============================================================================
namespace CBasePlayerController {
    constexpr ptrdiff_t m_iszPlayerName    = 0x818;   // char[32]
    constexpr ptrdiff_t m_hPawn            = 0x7E4;   // CHandle
}

// ============================================================================
// CGameSceneNode fields
// ============================================================================
namespace CGameSceneNode {
    constexpr ptrdiff_t m_vecAbsOrigin     = 0xD8;    // Vector
    constexpr ptrdiff_t m_bDormant         = 0xE0;    // bool
    constexpr ptrdiff_t m_pOwner           = 0x18;    // CEntityInstance*
}

// ============================================================================
// CSkeletonInstance (extends CGameSceneNode)
// ============================================================================
namespace CSkeletonInstance {
    constexpr ptrdiff_t m_modelState       = 0x170;   // CModelState
}

// ============================================================================
// CModelState
// ============================================================================
namespace CModelState {
    constexpr ptrdiff_t m_MeshGroupMask    = 0x80;    // uint64
}

// ============================================================================
// CBaseAnimGraph (extends C_BaseModelEntity)
// ============================================================================
namespace CBaseAnimGraph {
    // m_vecViewOffset is inherited from C_BaseModelEntity
}

// ============================================================================
// C_AttributeContainer
// ============================================================================
namespace C_AttributeContainer {
    constexpr ptrdiff_t m_Item             = 0x40;    // C_EconItemView
}

// ============================================================================
// C_EconItemView
// ============================================================================
namespace C_EconItemView {
    constexpr ptrdiff_t m_iItemDefinitionIndex = 0x1B8;  // uint16
}

// ============================================================================
// Weapon Base Data (via C_BaseEntity::m_nSubclassID + 0x08)
// ============================================================================
namespace WeaponData {
    constexpr ptrdiff_t WeaponDataPTR_offset = 0x08;   // from m_nSubclassID
    constexpr ptrdiff_t m_iClip1            = 0x1640;  // C_BasePlayerWeapon::m_iClip1
    constexpr ptrdiff_t m_iMaxClip1         = 0x40;    // CBasePlayerWeaponVData::m_iMaxClip1
    constexpr ptrdiff_t m_flCycleTime       = 0x1C;    // CCSWeaponBaseVData::m_flCycleTime
    constexpr ptrdiff_t m_flPenetration     = 0x28;    // CCSWeaponBaseVData::m_flPenetration
    constexpr ptrdiff_t m_WeaponType        = 0x134;   // CCSWeaponBaseVData::m_WeaponType
    constexpr ptrdiff_t m_flInaccuracyMove  = 0x68;    // CCSWeaponBaseVData::m_flInaccuracyMove
    constexpr ptrdiff_t m_nNumBullets       = 0x11C;   // CCSWeaponBaseVData::m_nNumBullets
    constexpr ptrdiff_t m_bInReload         = 0x1648;  // C_CSWeaponBase::m_bInReload
}

// ============================================================================
// CPlayer_WeaponServices
// ============================================================================
namespace CPlayer_WeaponServices {
    constexpr ptrdiff_t m_hActiveWeapon     = 0x58;    // CHandle<C_BasePlayerWeapon>
}

// ============================================================================
// Glow Property (via C_BaseModelEntity::m_Glow + CGlowProperty offsets)
// ============================================================================
namespace CGlowProperty {
    constexpr ptrdiff_t m_bGlowing              = 0x0;   // bool
    constexpr ptrdiff_t m_fGlowColorOverride    = 0x10;  // Vector
    constexpr ptrdiff_t m_fGlowColor            = 0x18;  // float32
    constexpr ptrdiff_t m_glowColorOverride     = 0x10;  // Color
}

// ============================================================================
// GameRules (C_CSGameRules)
// ============================================================================
namespace C_CSGameRules {
    constexpr ptrdiff_t m_bFreezePeriod          = 0x40;   // bool
    constexpr ptrdiff_t m_bWarmupPeriod          = 0x41;   // bool
    constexpr ptrdiff_t m_bHasMatchStarted       = 0xAC;   // bool
    constexpr ptrdiff_t m_bBombPlanted           = 0x9A5;  // bool
    constexpr ptrdiff_t m_iRoundWinStatus        = 0x9A8;  // int32
    constexpr ptrdiff_t m_eRoundWinReason        = 0x9AC;  // int32
    constexpr ptrdiff_t m_gamePhase              = 0x80;   // int32
    constexpr ptrdiff_t m_totalRoundsPlayed      = 0x84;   // int32
    constexpr ptrdiff_t m_bIsQueuedMatchmaking   = 0x98;   // bool
    constexpr ptrdiff_t m_bIsHltvActive          = 0x8C2;  // bool
    constexpr ptrdiff_t m_pGameModeRules         = 0xD98;  // CCSGameModeRules*
}

// ============================================================================
// CPlayer_MovementServices (for bunnyhop, movement exploits)
// ============================================================================
namespace CPlayer_MovementServices {
    constexpr ptrdiff_t m_nImpulse               = 0x48;    // int32
    constexpr ptrdiff_t m_nButtons               = 0x50;    // CInButtonState
    constexpr ptrdiff_t m_nQueuedButtonDownMask  = 0x70;    // uint64
    constexpr ptrdiff_t m_flCmdForwardMove       = 0x1A0;   // float
    constexpr ptrdiff_t m_flCmdLeftMove          = 0x1A4;   // float
    constexpr ptrdiff_t m_flCmdUpMove            = 0x1A8;   // float
    constexpr ptrdiff_t m_flMaxspeed             = 0x1AC;   // float
    constexpr ptrdiff_t m_vecOldViewAngles       = 0x240;   // QAngle
}

// ============================================================================
// CCSPlayer_MovementServices (CS2-specific movement)
// ============================================================================
namespace CCSPlayer_MovementServices {
    constexpr ptrdiff_t m_flDuckAmount           = 0x22C;   // float
    constexpr ptrdiff_t m_flDuckSpeed            = 0x230;   // float
    constexpr ptrdiff_t m_bDesiresDuck           = 0x235;   // bool
    constexpr ptrdiff_t m_flStamina              = 0x4D8;   // float
}

// ============================================================================
// CCSPlayer_CameraServices
// ============================================================================
namespace CCSPlayer_CameraServices {
    constexpr ptrdiff_t m_flDeathCamTilt         = 0x2A8;   // float
    constexpr ptrdiff_t m_vClientScopeInaccuracy = 0x2B0;   // Vector
}

// ============================================================================
// Pattern Signatures (for runtime offset resolution)
// ============================================================================
namespace Signatures {
    // CSGOInput — Primary pattern
    constexpr const char* CSGOInput_Primary =
        "\x48\x8B\x0D\x00\x00\x00\x00\x45\x33\xC0\x48\x8B\x01\x4C\x8D\x44\x24"
        "\x00\x00\x00\x00\x00\xFF\x50\x00\x00\x00\x84\xC0\x74\x05";
    constexpr const char* CSGOInput_Primary_Mask =
        "xxx????xxxxxxx??????xx????xx";

    // CSGOInput — Fallback pattern
    constexpr const char* CSGOInput_Fallback =
        "\x48\x89\x5C\x24\x08\x48\x89\x6C\x24\x10\x48\x89\x74\x24\x18\x57"
        "\x41\x54\x41\x55\x41\x56\x41\x57\x48\x83\xEC\x00\x4C\x8B\x25\x00\x00\x00\x00";
    constexpr const char* CSGOInput_Fallback_Mask =
        "xxxxxxxxxxxxxxxxxxxxxxxxxxxx?xxx????";
}

// ============================================================================
// VTable indices for CCSGOInput (x64, each pointer = 8 bytes)
// ============================================================================
namespace VTableIndex {
    constexpr int CreateMove      = 5;     // CCSGOInput::CreateMove
    constexpr int CreateMoveSize  = 5 * 8; // byte offset in vtable
}

// ============================================================================
// Dynamic World / Map Info
// ============================================================================
namespace World {
    constexpr float GRAVITY          = 800.0f;   // CS2 default gravity
    constexpr float TICK_INTERVAL    = 0.015625f; // 64 tick = 1/64
    constexpr int   MAX_PLAYERS      = 64;
    constexpr int   MAX_ENTITIES     = 2048;
}

// ============================================================================
// Team Numbers
// ============================================================================
namespace Team {
    constexpr int UNASSIGNED  = 0;
    constexpr int SPECTATOR   = 1;
    constexpr int TERRORIST   = 2;
    constexpr int COUNTER_T   = 3;
}

} // namespace CS2

// ============================================================================
// ESP Data Structures (shared between C++ hook and C# overlay)
// ============================================================================

#pragma pack(push, 1)

// Per-player ESP data written by hook DLL, read by C# overlay
struct EspPlayerData {
    float screenX;      // 0x00: screen X (-1 = off-screen)
    float screenY;      // 0x04: screen Y
    float health;       // 0x08: health
    int teamNum;        // 0x0C: team number (2=T, 3=CT)
    int spotted;        // 0x10: has been spotted by team
    int isScoped;       // 0x14: player is scoped in
    int isDefusing;     // 0x18: player is defusing bomb
    int armorValue;     // 0x1C: armor value (0-100)
    float distanceSq;   // 0x20: distance squared from local player
    int valid;          // 0x24: 1 if this slot has valid data
    int boneHeadX;      // 0x28: head bone screen X (-1 = off-screen)
    int boneHeadY;      // 0x2C: head bone screen Y
    int boneChestX;     // 0x30: chest bone screen X
    int boneChestY;     // 0x34: chest bone screen Y
};

// ESP configuration sent from C# overlay to hook DLL
struct EspConfig {
    unsigned char Enabled;       // 0x00: master switch
    unsigned char ShowBoxes;     // 0x01: draw bounding boxes
    unsigned char ShowNames;     // 0x02: draw player names
    unsigned char ShowHealth;    // 0x03: draw health bars
    unsigned char ShowSnaplines; // 0x04: draw lines from crosshair
    unsigned char ShowBones;     // 0x05: draw bone skeleton
    unsigned char ShowDistance;   // 0x06: draw distance text
    unsigned char TeamCheck;     // 0x07: skip teammates
    int padding[3];              // 0x08: alignment
};

#pragma pack(pop)

// ============================================================================
// Shared Memory Layout
// ============================================================================
// Offset 0x00: SharedAimData (50 bytes)
// Offset 0x32: AimbotConfig  (24 bytes)
// Offset 0x4A: EspConfig     (20 bytes)
// ============================================================================

// ============================================================================
// Triggerbot Config (shared between C++ hook and C# overlay)
// ============================================================================

#pragma pack(push, 1)

struct TriggerbotConfig {
    unsigned char Enabled;           // 0x00: master switch
    unsigned char Mode;              // 0x01: 0=off, 1=normal, 2=wallbang, 3=headshot-only
    unsigned char DelayMs;           // 0x02: delay in ms (0-250, looks human)
    unsigned char BurstCount;        // 0x03: shots per burst (0=auto hold)
    unsigned char MinDamage;         // 0x04: min damage threshold (1-100)
    unsigned char Hitchance;         // 0x05: hitchance % (1-100)
    unsigned char VisCheck;          // 0x06: visibility check before shooting
    unsigned char SilentAim;         // 0x07: silent aim when triggerbot fires
    unsigned char DelayBetweenShots; // 0x08: ms between burst shots
    unsigned char FriendlyFire;      // 0x09: allow shooting teammates
    int padding[2];                  // 0x0A: alignment
};

#pragma pack(pop)

// ============================================================================
// Updated Shared Memory Layout
// ============================================================================
// Offset 0x00: SharedAimData    (50 bytes)
// Offset 0x32: AimbotConfig     (24 bytes)
// Offset 0x4A: EspConfig        (20 bytes)
// Offset 0x5E: TriggerbotConfig (20 bytes)
// Offset 0x72: EspPlayerData[64](3584 bytes)
// ============================================================================

// ============================================================================
// 舉報系統 — GC (Game Coordinator) 消息類型
// ============================================================================

namespace Off::GC {
    // ECsgoGCMsg enum values (cstrike15_gcmessages.proto)
    constexpr uint32_t k_EMsgGCCStrike15_v2_ClientReportPlayer   = 9119;
    constexpr uint32_t k_EMsgGCCStrike15_v2_ClientReportServer   = 9120;
    constexpr uint32_t k_EMsgGCCStrike15_v2_ClientCommendPlayer  = 9121;
    constexpr uint32_t k_EMsgGCCStrike15_v2_ClientReportResponse = 9122;
    constexpr uint32_t k_EMsgGCCStrike15_v2_MatchmakingGC2ClientHello = 9110;
    constexpr uint32_t k_EMsgGCCStrike15_v2_PlayerOverwatchCaseUpdate  = 9131;
    constexpr uint32_t k_EMsgGCCStrike15_v2_PlayerOverwatchCaseAssignment = 9132;
    constexpr uint32_t k_EMsgGCCStrike15_v2_ServerNotificationForUserPenalty = 9118;
    constexpr uint32_t k_EMsgGCCStrike15_v2_MatchmakingGC2ClientAbandon = 9112;
    constexpr uint32_t k_EMsgGCCStrike15_v2_GC2ClientTextMsg     = 9134;
    constexpr uint32_t k_EMsgGCCStrike15_v2_AccountPrivacySettings = 9158;
    constexpr uint32_t k_EMsgGCCStrike15_v2_AcknowledgePenalty   = 9171;
}

// ============================================================================
// ISteamGameCoordinator VMT 索引
// ============================================================================

namespace Off::GC_VMT {
    constexpr int SendMessage      = 0;  // EGCResult SendMessage(uint32_t unMsgType, const void* pubData, uint32_t cubData)
    constexpr int RetrieveMessage  = 2;  // EGCResult RetrieveMessage(uint32_t *punMsgType, void *pubDest, uint32_t cubDest, uint32_t *pcubMsgSize)
}

// ============================================================================
// 舉報 CMsgGCCStrike15_v2_ClientReportPlayer 偏移量
// ============================================================================

namespace Off::Report {
    // Protobuf field offsets (protobuf encoding: field_tag + value)
    // Message: CMsgGCCStrike15_v2_ClientReportPlayer
    constexpr int ACCOUNT_ID     = 1;  // field 1: uint32 account_id
    constexpr int RPT_AIMBOT     = 2;  // field 2: uint32 rpt_aimbot
    constexpr int RPT_WALLHACK   = 3;  // field 3: uint32 rpt_wallhack
    constexpr int RPT_SPEEDHACK  = 4;  // field 4: uint32 rpt_speedhack
    constexpr int RPT_TEAMHARM   = 5;  // field 5: uint32 rpt_teamharm
    constexpr int RPT_TEXTABUSE  = 6;  // field 6: uint32 rpt_textabuse
    constexpr int RPT_VOICEABUSE = 7;  // field 7: uint32 rpt_voiceabuse
    constexpr int MATCH_ID       = 8;  // field 8: uint64 match_id
    constexpr int REPORT_FROM_DEMO = 9; // field 9: bool report_from_demo
}

// ============================================================================
// CUserCmd 按鍵 / 舉報相關遊戲事件
// ============================================================================

// vote_cast event field
// 歐射玩家: entity_index (凶手), vote_option (0=kick), team (陣營)


// ============================================================================
// Glow ESP — CGlowProperty (Build 14178, s2v.app 2026-08-29)
// ============================================================================
namespace Glow {
    constexpr ptrdiff_t MODEL_ENTITY_GLOW       = 0x0DE0; // C_BaseModelEntity::m_Glow (CGlowProperty embedded)
    // CGlowProperty members (relative to m_Glow base):
    constexpr ptrdiff_t fGlowColor              = 0x08;  // Color (R,G,B,A)
    constexpr ptrdiff_t iGlowType               = 0x30;  // int32 (0=default)
    constexpr ptrdiff_t iGlowTeam               = 0x34;  // int32
    constexpr ptrdiff_t nGlowRange              = 0x38;  // int32
    constexpr ptrdiff_t nGlowRangeMin           = 0x3C;  // int32
    constexpr ptrdiff_t glowColorOverride       = 0x40;  // Color
    constexpr ptrdiff_t bFlashing               = 0x44;  // bool
    constexpr ptrdiff_t flGlowTime              = 0x48;  // float32
    constexpr ptrdiff_t bEligibleForScreenHighlight = 0x50; // bool
    constexpr ptrdiff_t bGlowing                = 0x51;  // bool (核心！)
}

// ============================================================================
// Bomb Timer — C_PlantedC4 (Build 14178, s2v.app 2026-08-29)
// ============================================================================
namespace Bomb {
    constexpr ptrdiff_t bBombTicking            = 0x11A0; // bool
    constexpr ptrdiff_t nBombSite               = 0x11A4; // int32 (0=A, 1=B)
    constexpr ptrdiff_t flC4Blow                = 0x11D0; // GameTime_t (爆炸時間)
    constexpr ptrdiff_t bCannotBeDefused        = 0x11D4; // bool
    constexpr ptrdiff_t flTimerLength           = 0x11D8; // float32 (預設40秒)
    constexpr ptrdiff_t bBeingDefused           = 0x11DC; // bool
    constexpr ptrdiff_t flDefuseLength          = 0x11EC; // float32 (拆彈時間, 預設10/5秒)
    constexpr ptrdiff_t flDefuseCountDown       = 0x11F0; // GameTime_t
    constexpr ptrdiff_t bBombDefused            = 0x11F4; // bool
}

// ============================================================================
// RCS — C_CSPlayerPawn::m_iShotsFired (Build 14178, s2v.app 2026-08-29)
// ============================================================================
namespace RCS {
    constexpr ptrdiff_t iShotsFired             = 0x1C8C; // int32
}

// ============================================================================
// Spectator List — CPlayer_ObserverServices (Build 14178, s2v.app 2026-08-29)
// ============================================================================
namespace Observer {
    constexpr ptrdiff_t pObserverServices       = 0x1220; // CPlayer_ObserverServices* (in C_BasePlayerPawn)
    constexpr ptrdiff_t iObserverMode           = 0x48;   // uint8 (0=ineye, 1=thirdperson, 2=free, 4=firstperson)
    constexpr ptrdiff_t hObserverTarget         = 0x4C;   // CHandle<C_BaseEntity>
}

// ============================================================================
// Flash Detection — C_CSPlayerPawnBase (Build 14178, s2v.app 2026-08-29)
// ============================================================================
namespace Flash {
    constexpr ptrdiff_t flFlashDuration         = 0x1428; // float32
    constexpr ptrdiff_t flFlashMaxAlpha         = 0x1424; // float32
    constexpr ptrdiff_t bFlashBuildUp           = 0x1420; // bool
}
