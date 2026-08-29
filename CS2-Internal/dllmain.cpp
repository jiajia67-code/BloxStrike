#include <Windows.h>
#include <thread>
#include <iostream>
#include <fstream>

// Forward declarations
void Initialize(HMODULE hModule);
void Shutdown();

// Global
HMODULE g_Module = nullptr;
bool g_Running = true;

BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved)
{
    if (ul_reason_for_call == DLL_PROCESS_ATTACH)
    {
        g_Module = hModule;
        DisableThreadLibraryCalls(hModule);
        CreateThread(nullptr, 0, (LPTHREAD_START_ROUTINE)Initialize, hModule, 0, nullptr);
    }
    else if (ul_reason_for_call == DLL_PROCESS_DETACH)
    {
        Shutdown();
    }
    return TRUE;
}
