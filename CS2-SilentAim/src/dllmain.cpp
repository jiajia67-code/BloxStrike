#include <Windows.h>
#include <cstdint>
#include <thread>
#include <string>
#include "Hook.h"
#include "IPC.h"

// ============================================================
// MinHook Headers (simplified - you need to link MinHook library)
// ============================================================

// For full implementation, download MinHook from:
// https://github.com/TsudaKageworkspace/minhook

// Simplified MinHook stub for compilation
// Replace with actual MinHook library
#ifndef MINHOOK_STUB
#define MH_OK 0
#define MH_ERROR_ALREADY_INITIALIZED -1
#define MH_ERROR_NOT_INITIALIZED -2
#define MH_ERROR_MEMORY_ALLOC -3
#define MH_ERROR_FUNCTION_NOT_FOUND -4
#define MH_ERROR_FUNCTION_TOO_SHORT -5

inline int MH_Initialize() { return MH_OK; }
inline int MH_Uninitialize() { return MH_OK; }
inline int MH_CreateHook(LPVOID pTarget, LPVOID pDetour, LPVOID* ppOriginal) { return MH_OK; }
inline int MH_EnableHook(LPVOID pTarget) { return MH_OK; }
inline int MH_DisableHook(LPVOID pTarget) { return MH_OK; }
#endif

// ============================================================
// Log to console (for debugging)
// ============================================================

static void Log(const char* msg)
{
    OutputDebugStringA(msg);
    // Also try to write to a log file
    HANDLE hFile = CreateFileA(
        "C:\\Users\\fff92\\Desktop\\GameCheats\\CS2-SilentAim\\hook.log",
        FILE_APPEND_DATA,
        FILE_SHARE_READ,
        nullptr,
        OPEN_ALWAYS,
        FILE_ATTRIBUTE_NORMAL,
        nullptr
    );

    if (hFile != INVALID_HANDLE_VALUE)
    {
        DWORD bytesWritten;
        WriteFile(hFile, msg, (DWORD)strlen(msg), &bytesWritten, nullptr);
        CloseHandle(hFile);
    }
}

// ============================================================
// Main Thread
// ============================================================

DWORD WINAPI MainThread(LPVOID lpParam)
{
    // Wait for game to load
    Sleep(3000);

    Log("[SilentAim] DLL loaded into CS2\n");
    Log("[SilentAim] Initializing...\n");

    // Initialize MinHook
    if (MH_Initialize() != MH_OK)
    {
        Log("[SilentAim] Failed to initialize MinHook\n");
        return 1;
    }
    Log("[SilentAim] MinHook initialized\n");

    // Initialize IPC (shared memory with external program)
    if (!IPC::Initialize())
    {
        Log("[SilentAim] IPC not available - external program not running\n");
        Log("[SilentAim] Continuing with hook only...\n");
    }
    else
    {
        Log("[SilentAim] IPC connected to external program\n");
    }

    // Install hooks
    if (!Hook::Install())
    {
        Log("[SilentAim] Failed to install hooks\n");
        return 1;
    }

    // Notify external program that we're hooked
    IPC::SetHooked(true);
    Log("[SilentAim] ✅ All hooks installed successfully!\n");
    Log("[SilentAim] Silent aim is now active\n");

    // Main loop - keep DLL alive
    while (true)
    {
        // Check for unload key (DELETE key)
        if (GetAsyncKeyState(VK_DELETE) & 1)
        {
            Log("[SilentAim] Unload requested\n");
            break;
        }

        // Update IPC state
        if (IPC::IsAvailable())
        {
            SharedAimData data = IPC::Read();
            if (data.Magic == MAGIC_NUMBER)
            {
                Hook::silentAimActive = data.Active || data.AntiAimActive;
            }
        }

        Sleep(10);
    }

    // Cleanup
    Log("[SilentAim] Cleaning up...\n");
    IPC::SetHooked(false);
    Hook::Uninstall();
    MH_Uninitialize();
    IPC::Cleanup();

    Log("[SilentAim] DLL unloaded\n");

    // Free DLL and exit thread
    HMODULE hModule = GetModuleHandleA("CS2-SilentAim.dll");
    if (hModule)
        FreeLibraryAndExitThread(hModule, 0);

    return 0;
}

// ============================================================
// DLL Entry Point
// ============================================================

BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved)
{
    switch (ul_reason_for_call)
    {
    case DLL_PROCESS_ATTACH:
        DisableThreadLibraryCalls(hModule);
        CreateThread(nullptr, 0, MainThread, hModule, 0, nullptr);
        break;

    case DLL_PROCESS_DETACH:
        IPC::Cleanup();
        break;
    }

    return TRUE;
}
