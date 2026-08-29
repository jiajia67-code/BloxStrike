// Minimal DLL — just logs and sleeps, no hooks, no IPC
#include <Windows.h>

static void Log(const char* msg) { OutputDebugStringA(msg); }

static DWORD WINAPI Thread(LPVOID p)
{
    Log("[Minimal] Thread started\n");
    Sleep(2000);
    Log("[Minimal] Thread alive after 2s\n");
    Sleep(10000);
    Log("[Minimal] Thread alive after 12s\n");
    return 0;
}

BOOL APIENTRY DllMain(HMODULE h, DWORD r, LPVOID)
{
    if (r == DLL_PROCESS_ATTACH)
    {
        Log("[Minimal] DLL_PROCESS_ATTACH\n");
        HANDLE ht = CreateThread(0, 0, Thread, 0, 0, 0);
        if (ht) CloseHandle(ht);
    }
    return TRUE;
}
