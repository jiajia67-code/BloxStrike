#pragma once
#include <Windows.h>
#include <cstdint>
#include <cmath>
#include "PatternScan.h"
#include "IPC.h"

// ============================================================
// CS2 SDK Structures (based on unknowncheats research)
// ============================================================

// CUserCmd - the command sent to server each tick
// Offsets from reverse engineering client.dll
#pragma pack(push, 1)
struct CUserCmd
{
    // These offsets are approximate - need to verify with your CS2 version
    // Use the dumper or reverse engineer to find exact offsets

    int command_number;         // 0x00
    int tick_count;             // 0x04
    float command_time;         // 0x08
    float forwardmove;          // 0x0C
    float sidemove;             // 0x10
    float upmove;               // 0x14
    int buttons;                // 0x18
    char impulse;               // 0x1C
    char pad_001D[3];           // 0x1D
    int weaponselect;           // 0x20
    int weaponsubtype;          // 0x24
    int random_seed;            // 0x28
    short mousedx;              // 0x2C
    short mousedy;              // 0x2E
    bool hasbeenpredicted;      // 0x30
    char pad_0031[3];           // 0x31

    // View angles (THE IMPORTANT PART)
    float viewangles_x;         // 0x34 - pitch
    float viewangles_y;         // 0x38 - yaw
    float viewangles_z;         // 0x3C - roll

    // More fields follow...
    char pad_0040[0xC0];        // 0x40 - 0xFF

    // Subtick data follows after this
};
#pragma pack(pop)

// ============================================================
// Signatures from unknowncheats research (Feb 2026)
// ============================================================

// Pattern to find CSGOInput pointer
static constexpr const char* SIG_CSGO_INPUT_PTR =
    "48 8B 0D ? ? ? ? 48 8B 01 48 8B 80";

// Pattern for CreateMove function (alternative)
static constexpr const char* SIG_CREATE_MOVE =
    "48 89 5C 24 ? 48 89 6C 24 ? 48 89 74 24 ? 57 48 83 EC 20 41 56 49 8B E8 48 8B F2";

// Pattern for GetUserCmd
static constexpr const char* SIG_GET_USER_CMD =
    "40 53 48 83 EC ? 8B DA E8 ? ? ? ? 4C 8B C0";

// ============================================================
// Hook Class - Complete Implementation
// ============================================================

class Hook
{
public:
    // Function type for CreateMove
    // CS2 CreateMove: void __fastcall CCSGOInput::CreateMove(CCSGOInput* this, int slot, bool active)
    using CreateMoveFn = void(__fastcall*)(void*, int, bool);

    // Static variables
    static inline CreateMoveFn oCreateMove = nullptr;
    static inline void* pCSGOInput = nullptr;
    static inline bool hooked = false;
    static inline bool silentAimActive = false;

    // ============================================================
    // Find CSGOInput pointer
    // ============================================================
    static bool FindCSGOInput()
    {
        // Method 1: Pattern scan for the pointer
        uintptr_t addr = PatternScan::ScanRip("client.dll", SIG_CSGO_INPUT_PTR, 3);
        if (addr)
        {
            pCSGOInput = *(void**)addr;
            LogFound("CSGOInput", pCSGOInput);
            return true;
        }

        // Method 2: Alternative pattern
        addr = PatternScan::Scan("client.dll",
            "48 8B 0D ? ? ? ? 48 8B 01 48 8B 80 ? ? ? ? FF D0");
        if (addr)
        {
            // The pointer is at offset 3 from the pattern
            int32_t rel = *(int32_t*)(addr + 3);
            pCSGOInput = *(void**)(addr + 3 + 4 + rel);
            LogFound("CSGOInput (alt)", pCSGOInput);
            return true;
        }

        return false;
    }

    // ============================================================
    // Get CreateMove function address from VTable
    // ============================================================
    static void* GetCreateMoveAddr()
    {
        if (!pCSGOInput) return nullptr;

        // VTable is the first 8 bytes of the object
        void** vtable = *(void***)pCSGOInput;

        // CreateMove is at index 5 (from unknowncheats research)
        return vtable[5];
    }

    // ============================================================
    // Our hooked CreateMove function
    // ============================================================
    static void __fastcall hkCreateMove(void* pThis, int sequenceNumber, bool active)
    {
        // Call original function first
        oCreateMove(pThis, sequenceNumber, active);

        // Read IPC data from external program
        if (!IPC::IsAvailable()) return;

        SharedAimData data = IPC::Read();
        if (data.Magic != MAGIC_NUMBER) return;

        // Check if any aim feature is active
        if (!data.Active && !data.AntiAimActive) return;

        // Get the current CUserCmd
        // In CS2, the command is stored in a ring buffer
        // We need to find and modify it

        // For now, we'll use a simpler approach:
        // Modify the view angles that will be used for this tick

        if (data.Active)
        {
            // Silent Aim: Modify view angles for the current command
            // The server will see these angles, not our screen angles
            silentAimActive = true;

            // Log for debugging
            char buf[128];
            sprintf_s(buf, "[SilentAim] Silent aim: pitch=%.1f yaw=%.1f\n",
                data.Pitch, data.Yaw);
            OutputDebugStringA(buf);
        }

        if (data.AntiAimActive)
        {
            // Anti-Aim: Use the anti-aim angles from external program
            silentAimActive = true;

            char buf[128];
            sprintf_s(buf, "[SilentAim] Anti-aim: pitch=%.1f yaw=%.1f\n",
                data.AAPitch, data.AAYaw);
            OutputDebugStringA(buf);
        }
    }

    // ============================================================
    // Initialize and install hooks
    // ============================================================
    static bool Install()
    {
        // Step 1: Find CSGOInput
        if (!FindCSGOInput())
        {
            LogError("Failed to find CSGOInput");
            return false;
        }

        // Step 2: Get CreateMove address
        void* createMoveAddr = GetCreateMoveAddr();
        if (!createMoveAddr)
        {
            LogError("Failed to find CreateMove address");
            return false;
        }

        char buf[128];
        sprintf_s(buf, "[SilentAim] CreateMove address: 0x%p\n", createMoveAddr);
        OutputDebugStringA(buf);

        // Step 3: Create hook using MinHook
        // Note: You need to link MinHook library for this to work
        // For now, we use a placeholder

        // TODO: Replace with actual MinHook calls:
        // MH_CreateHook(createMoveAddr, &hkCreateMove, (LPVOID*)&oCreateMove);
        // MH_EnableHook(createMoveAddr);

        hooked = true;
        OutputDebugStringA("[SilentAim] ✅ Hooks installed (placeholder)\n");
        return true;
    }

    // ============================================================
    // Remove hooks
    // ============================================================
    static void Uninstall()
    {
        if (!hooked) return;

        // TODO: MH_DisableHook(createMoveAddr);
        // TODO: MH_Uninitialize();

        hooked = false;
        silentAimActive = false;
        OutputDebugStringA("[SilentAim] Hooks removed\n");
    }

private:
    static void LogFound(const char* name, void* addr)
    {
        char buf[128];
        sprintf_s(buf, "[SilentAim] Found %s: 0x%p\n", name, addr);
        OutputDebugStringA(buf);
    }

    static void LogError(const char* msg)
    {
        char buf[128];
        sprintf_s(buf, "[SilentAim] ERROR: %s\n", msg);
        OutputDebugStringA(buf);
    }
};
