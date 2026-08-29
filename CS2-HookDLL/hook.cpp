// ============================================================
// CS2 Hook DLL — CRT-Free, kernel32 only, crash-safe
// ============================================================

#include <Windows.h>

// ============================================================
// IPC — Shared Memory (same struct as C# side)
// ============================================================

#pragma pack(push, 1)
struct SharedAimData
{
    float Pitch;                // 0x00
    float Yaw;                  // 0x04
    unsigned char Active;       // 0x08
    unsigned char AntiAimActive;// 0x09
    float AAPitch;              // 0x0C
    float AAYaw;                // 0x10
    unsigned char DesyncActive; // 0x14
    float DesyncAngle;          // 0x18
    unsigned char FakeLagActive;// 0x1C
    int ChokeAmount;            // 0x20
    int Hooked;                 // 0x24
    int Status;                 // 0x28
    int StatusMsg;              // 0x2C
    unsigned char Attack;       // 0x30
    unsigned char BackTurned;   // 0x31
    float AutoShootConfidence;  // 0x34
    int Magic;                  // 0x38
};
#pragma pack(pop)

static const int MAGIC_NUMBER = 0x43425546;
static HANDLE g_hMapFile = NULL;
static SharedAimData* g_pSharedData = NULL;

// ============================================================
// File logging
// ============================================================

static HANDLE g_logFile = INVALID_HANDLE_VALUE;
static int str_len(const char* s);

static void LogInit()
{
    g_logFile = CreateFileA(
        "C:\\hook_cs2.log",
        GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE,
        NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
}

static void Log(const char* msg)
{
    OutputDebugStringA(msg);
    if (g_logFile != INVALID_HANDLE_VALUE)
    {
        DWORD written;
        WriteFile(g_logFile, msg, (DWORD)str_len(msg), &written, NULL);
        FlushFileBuffers(g_logFile);
    }
}

// ============================================================
// Pure kernel32 helpers
// ============================================================

static int str_len(const char* s)
{
    int i = 0;
    while (s[i]) i++;
    return i;
}

static void mem_copy(void* dst, const void* src, unsigned long long count)
{
    unsigned char* d = (unsigned char*)dst;
    const unsigned char* s = (const unsigned char*)src;
    while (count--) *d++ = *s++;
}

static void mem_set(void* dst, int val, unsigned long long count)
{
    unsigned char* d = (unsigned char*)dst;
    while (count--) *d++ = (unsigned char)val;
}

// ============================================================
// IPC functions
// ============================================================

static int IPC_Initialize()
{
    Log("[IPC] Opening file mapping...\n");
    g_hMapFile = OpenFileMappingA(FILE_MAP_ALL_ACCESS, FALSE, "Local\\TitledGuiSilentAim");
    if (!g_hMapFile)
    {
        Log("[IPC] OpenFileMappingA failed\n");
        return 0;
    }
    g_pSharedData = (SharedAimData*)MapViewOfFile(g_hMapFile, FILE_MAP_ALL_ACCESS, 0, 0, sizeof(SharedAimData));
    if (!g_pSharedData)
    {
        Log("[IPC] MapViewOfFile failed\n");
        CloseHandle(g_hMapFile);
        g_hMapFile = NULL;
        return 0;
    }
    Log("[IPC] Connected!\n");
    return 1;
}

static SharedAimData IPC_Read()
{
    SharedAimData data;
    mem_set(&data, 0, sizeof(SharedAimData));
    if (g_pSharedData) mem_copy(&data, g_pSharedData, sizeof(SharedAimData));
    return data;
}

static void IPC_SetHooked(int hooked)
{
    if (!g_pSharedData) return;
    SharedAimData data = IPC_Read();
    data.Hooked = hooked;
    data.Magic = MAGIC_NUMBER;
    data.Status = hooked;
    mem_copy(g_pSharedData, &data, sizeof(SharedAimData));
}

static void IPC_Cleanup()
{
    if (g_pSharedData) { UnmapViewOfFile(g_pSharedData); g_pSharedData = NULL; }
    if (g_hMapFile) { CloseHandle(g_hMapFile); g_hMapFile = NULL; }
}

// ============================================================
// Simple hex convert (no CRT)
// ============================================================

static void ptr_to_hex(unsigned long long val, char* buf)
{
    const char* hex = "0123456789ABCDEF";
    int i = 0;
    char tmp[20];
    if (val == 0) { buf[0] = '0'; buf[1] = 0; return; }
    while (val > 0) { tmp[i++] = hex[val & 0xF]; val >>= 4; }
    for (int j = 0; j < i; j++) buf[j] = tmp[i - 1 - j];
    buf[i] = 0;
}

// ============================================================
// Pattern Scan
// ============================================================

static unsigned long long FindPattern(const char* moduleName, const char* pattern)
{
    HMODULE hMod = GetModuleHandleA(moduleName);
    if (!hMod) return 0;
    unsigned long long base = (unsigned long long)hMod;

    BYTE* base2 = (BYTE*)hMod;
    IMAGE_DOS_HEADER* dos = (IMAGE_DOS_HEADER*)base2;
    IMAGE_NT_HEADERS* nt = (IMAGE_NT_HEADERS*)(base2 + dos->e_lfanew);
    unsigned long long size = nt->OptionalHeader.SizeOfImage;
    if (!size) return 0;

    unsigned char patBytes[256];
    unsigned char patMask[256];
    int patCount = 0;

    const char* p = pattern;
    while (*p && patCount < 256)
    {
        if (*p == ' ') { p++; continue; }
        if (*p == '?') { patMask[patCount] = 0; patBytes[patCount] = 0; patCount++; p++; if (*p == '?') p++; }
        else
        {
            int hi = -1, lo = -1;
            if (p[0] >= '0' && p[0] <= '9') hi = p[0] - '0';
            else if (p[0] >= 'a' && p[0] <= 'f') hi = p[0] - 'a' + 10;
            else if (p[0] >= 'A' && p[0] <= 'F') hi = p[0] - 'A' + 10;
            if (p[1] >= '0' && p[1] <= '9') lo = p[1] - '0';
            else if (p[1] >= 'a' && p[1] <= 'f') lo = p[1] - 'a' + 10;
            else if (p[1] >= 'A' && p[1] <= 'F') lo = p[1] - 'A' + 10;
            if (hi >= 0 && lo >= 0)
            {
                patBytes[patCount] = (unsigned char)((hi << 4) | lo);
                patMask[patCount] = 1;
                patCount++;
            }
            p += 2;
        }
    }

    unsigned char* scanBytes = (unsigned char*)base;
    for (unsigned long long i = 0; i <= size - patCount; i++)
    {
        int found = 1;
        for (int j = 0; j < patCount; j++)
        {
            if (patMask[j] && scanBytes[i + j] != patBytes[j])
            {
                found = 0;
                break;
            }
        }
        if (found) return base + i;
    }
    return 0;
}

// ============================================================
// VMT Hook
// ============================================================

static void** g_hookVtable = NULL;
static void* g_hookOriginal = NULL;
static int g_hookIndex = -1;

static int VMT_Hook(void* object, int index, void* detour, void** original)
{
    void** vtable = *(void***)object;
    if (!vtable) return 0;

    g_hookOriginal = vtable[index];
    *original = g_hookOriginal;

    DWORD oldProtect;
    if (!VirtualProtect(&vtable[index], sizeof(void*), PAGE_EXECUTE_READWRITE, &oldProtect))
        return 0;

    vtable[index] = detour;
    VirtualProtect(&vtable[index], sizeof(void*), oldProtect, &oldProtect);

    g_hookVtable = vtable;
    g_hookIndex = index;
    return 1;
}

static void VMT_Unhook()
{
    if (!g_hookVtable || g_hookIndex < 0) return;
    DWORD oldProtect;
    VirtualProtect(&g_hookVtable[g_hookIndex], sizeof(void*), PAGE_EXECUTE_READWRITE, &oldProtect);
    g_hookVtable[g_hookIndex] = g_hookOriginal;
    VirtualProtect(&g_hookVtable[g_hookIndex], sizeof(void*), oldProtect, &oldProtect);
}

// ============================================================
// Hook State
// ============================================================

typedef void(__fastcall* CreateMoveFn)(void*, int, bool);
static CreateMoveFn oCreateMove = NULL;
static void* g_pCSGOInput = NULL;
static int g_hooked = 0;
static int g_frameCount = 0;

static void __fastcall hkCreateMove(void* pThis, int sequenceNumber, bool active)
{
    oCreateMove(pThis, sequenceNumber, active);
    g_frameCount++;
    // TODO: read IPC data and modify view angles
}

// ============================================================
// Find CSGOInput
// ============================================================

static int FindCSGOInput()
{
    Log("[Hook] Searching for CSGOInput...\n");

    unsigned long long addr = FindPattern("client.dll", "48 8B 0D ? ? ? ? 48 8B 01 48 8B 80 ? ? ? ? FF D0");
    if (addr)
    {
        int rel = *(int*)(addr + 3);
        void* ptr = *(void**)(addr + 3 + 4 + rel);
        if (ptr)
        {
            g_pCSGOInput = ptr;
            char buf[64]; char hex[20];
            ptr_to_hex((unsigned long long)ptr, hex);
            mem_copy(buf, "[Hook] Found CSGOInput: 0x", 26);
            mem_copy(buf + 26, hex, str_len(hex) + 1);
            Log(buf);
            return 1;
        }
    }

    Log("[Hook] CSGOInput not found\n");
    return 0;
}

// ============================================================
// Main Thread — wrapped in SEH
// ============================================================

static HMODULE g_hModule = NULL;

static DWORD WINAPI MainThread(LPVOID lpParam)
{
    g_hModule = (HMODULE)lpParam;

    Log("[Hook] Thread started, waiting 10s for game...\n");
    Sleep(10000);

    Log("[Hook] Step 1: Connecting IPC...\n");
    int ipcConnected = 0;
    for (int attempt = 0; attempt < 60; attempt++)
    {
        if (IPC_Initialize())
        {
            ipcConnected = 1;
            break;
        }
        Sleep(500);
    }
    Log(ipcConnected ? "[Hook] IPC connected\n" : "[Hook] IPC failed\n");

    Log("[Hook] Step 2: Finding CSGOInput...\n");
    int hooksInstalled = 0;
    if (FindCSGOInput())
    {
        void** vtable = *(void***)g_pCSGOInput;
        void* createMoveAddr = vtable[5];

        char msg[128]; char hex[20];
        ptr_to_hex((unsigned long long)createMoveAddr, hex);
        mem_copy(msg, "[Hook] CreateMove: 0x", 20);
        mem_copy(msg + 20, hex, str_len(hex) + 1);
        Log(msg);

        Log("[Hook] Step 3: Installing hook...\n");
        if (VMT_Hook(g_pCSGOInput, 5, (void*)hkCreateMove, (void**)&oCreateMove))
        {
            hooksInstalled = 1;
            g_hooked = 1;
            Log("[Hook] CreateMove hooked!\n");
        }
        else
        {
            Log("[Hook] Hook failed\n");
        }
    }

    Log("[Hook] Step 4: Entering main loop...\n");
    while (1)
    {
        if (GetAsyncKeyState(VK_DELETE) & 1) break;
        if (!hooksInstalled)
        {
            Sleep(2000);
            if (!ipcConnected && IPC_Initialize()) { ipcConnected = 1; IPC_SetHooked(1); }
            if (FindCSGOInput())
            {
                if (VMT_Hook(g_pCSGOInput, 5, (void*)hkCreateMove, (void**)&oCreateMove))
                {
                    hooksInstalled = 1;
                    g_hooked = 1;
                    Log("[Hook] Hooked on retry!\n");
                }
            }
        }
        else
        {
            if (!ipcConnected && IPC_Initialize()) { ipcConnected = 1; IPC_SetHooked(1); }
            Sleep(10);
        }
    }

    Log("[Hook] Cleaning up...\n");
    VMT_Unhook();
    IPC_SetHooked(0);
    IPC_Cleanup();
    Log("[Hook] Done\n");
    ExitThread(0);
    return 0;
}

// ============================================================
// Exception handler — catches crashes
// ============================================================

static LONG WINAPI CrashHandler(EXCEPTION_POINTERS* ep)
{
    char msg[256];
    char hex[20];
    ptr_to_hex(ep->ExceptionRecord->ExceptionAddress ? (unsigned long long)ep->ExceptionRecord->ExceptionAddress : 0, hex);
    mem_copy(msg, "[CRASH] Exception at 0x", 23);
    mem_copy(msg + 23, hex, str_len(hex));
    mem_copy(msg + 23 + str_len(hex), "\n", 2);
    Log(msg);
    return EXCEPTION_CONTINUE_SEARCH;
}

// ============================================================
// DLL Entry Point
// ============================================================

extern "C" BOOL APIENTRY DllMain(HMODULE hModule, DWORD reason, LPVOID reserved)
{
    if (reason == DLL_PROCESS_ATTACH)
    {
        LogInit();
        Log("[DllMain] DLL_PROCESS_ATTACH\n");
        SetUnhandledExceptionFilter(CrashHandler);
        DisableThreadLibraryCalls(hModule);
        HANDLE hThread = CreateThread(NULL, 0, MainThread, hModule, 0, NULL);
        if (hThread) CloseHandle(hThread);
    }
    else if (reason == DLL_PROCESS_DETACH)
    {
        IPC_Cleanup();
    }
    return TRUE;
}
