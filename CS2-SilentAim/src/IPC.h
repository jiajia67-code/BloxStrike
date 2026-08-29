#pragma once
#include <Windows.h>
#include <cstdint>

// Shared data structure between DLL and external program
// Must match HookInjector.SharedAimData exactly
#pragma pack(push, 1)
struct SharedAimData
{
    float Pitch;                // 0x00 - Aim pitch
    float Yaw;                  // 0x04 - Aim yaw
    bool Active;                // 0x08 - Silent aim active
    bool AntiAimActive;         // 0x09 - Anti-aim active
    float AAPitch;              // 0x0A - Anti-aim pitch
    float AAYaw;                // 0x0E - Anti-aim yaw
    bool DesyncActive;          // 0x12 - Desync active
    float DesyncAngle;          // 0x13 - Desync angle
    bool FakeLagActive;         // 0x17 - Fake lag active
    int ChokeAmount;            // 0x18 - Fake lag choke amount
    int Hooked;                 // 0x1C - Hook status (1 = connected)
    int Status;                 // 0x20 - Status code
    int StatusMsg;              // 0x24 - Status message
    bool Attack;                // 0x28 - Auto shoot
    bool BackTurned;            // 0x29 - Enemy back turned
    float AutoShootConfidence;  // 0x2A - Auto shoot confidence
    int Magic;                  // 0x2E - Magic number for validation
};
#pragma pack(pop)

static constexpr int MAGIC_NUMBER = 0x43425546; // "FUBC"
static constexpr const char* MAP_NAME = "Local\\TitledGuiSilentAim";

class IPC
{
public:
    static bool Initialize()
    {
        hMapFile = OpenFileMappingA(
            FILE_MAP_ALL_ACCESS,
            FALSE,
            MAP_NAME
        );

        if (!hMapFile)
            return false;

        pSharedData = (SharedAimData*)MapViewOfFile(
            hMapFile,
            FILE_MAP_ALL_ACCESS,
            0, 0,
            sizeof(SharedAimData)
        );

        if (!pSharedData)
        {
            CloseHandle(hMapFile);
            hMapFile = nullptr;
            return false;
        }

        return true;
    }

    static SharedAimData Read()
    {
        SharedAimData data = {};
        if (pSharedData)
            memcpy(&data, pSharedData, sizeof(SharedAimData));
        return data;
    }

    static void Write(const SharedAimData& data)
    {
        if (pSharedData)
            memcpy(pSharedData, &data, sizeof(SharedAimData));
    }

    static void SetHooked(bool hooked)
    {
        if (!pSharedData) return;
        SharedAimData data = Read();
        data.Hooked = hooked ? 1 : 0;
        data.Magic = MAGIC_NUMBER;
        data.Status = hooked ? 1 : 0;
        Write(data);
    }

    static bool IsAvailable()
    {
        return pSharedData != nullptr;
    }

    static void Cleanup()
    {
        if (pSharedData)
        {
            UnmapViewOfFile(pSharedData);
            pSharedData = nullptr;
        }
        if (hMapFile)
        {
            CloseHandle(hMapFile);
            hMapFile = nullptr;
        }
    }

private:
    inline static HANDLE hMapFile = nullptr;
    inline static SharedAimData* pSharedData = nullptr;
};
