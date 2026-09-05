// ============================================================================
// CS2-TeamShare DLL — 隊友端 ESP 分享客戶端 + D3D9 疊加層
// 連接開掛者的 Named Pipe 伺服器，接收實體資料，渲染 ESP
// ============================================================================

#include <Windows.h>
#include <cstdint>
#include "TeamShareClient.h"
#include "EspOverlay.h"

// ============================================================================
// 除錯輸出（安全，不寫檔）
// ============================================================================

#ifdef _DEBUG
static void DebugLog(const char* msg)
{
    OutputDebugStringA(msg);
}
#else
#define DebugLog(x) ((void)0)
#endif

// ============================================================================
// 資料同步執行緒：從 TeamShare Client 讀取資料到 Overlay
// ============================================================================

static DWORD WINAPI DataSyncThread(LPVOID lpParam)
{
    (void)lpParam;

    while (EspOverlay::IsRunning())
    {
        // 從 TeamShare Client 的本地共享記憶體讀取資料
        if (TeamShareClient::GetState() == TeamShareClient::State::Connected)
        {
            // 資料已經在 TeamShareClient 的本地共享記憶體中
            // EspOverlay 直接從那裡讀取
        }

        Sleep(33); // ~30Hz 同步頻率
    }

    return 0;
}

// ============================================================================
// 監聽 TeamShare 事件（數據更新通知）
// ============================================================================

static DWORD WINAPI EventListenerThread(LPVOID lpParam)
{
    (void)lpParam;

    while (EspOverlay::IsRunning())
    {
        if (TeamShareClient::GetState() == TeamShareClient::State::Connected)
        {
            // 讀取最新的 TeamShare 資料並餵給 Overlay
            // 使用 shared memory 直接訪問
            HANDLE hMap = OpenFileMappingA(FILE_MAP_READ, FALSE, "Local\\CS2TeamShareClient");
            if (hMap)
            {
                TeamShareFullUpdate* pData = (TeamShareFullUpdate*)MapViewOfFile(
                    hMap, FILE_MAP_READ, 0, 0, sizeof(TeamShareFullUpdate));
                if (pData)
                {
                    EspOverlay::SetEspData(pData);
                    UnmapViewOfFile(pData);
                }
                CloseHandle(hMap);
            }
        }

        Sleep(50); // ~20Hz 更新
    }

    return 0;
}

// ============================================================================
// 找到 CS2 窗口
// ============================================================================

static HWND FindCS2Window()
{
    // 嘗試多個窗口類名
    const char* classNames[] = {
        "Valve001",
        "SDL_app",
        NULL
    };

    for (int i = 0; classNames[i]; i++) {
        HWND hwnd = FindWindowA(classNames[i], NULL);
        if (hwnd) return hwnd;
    }

    // 回退：找到 CS2 進程的主窗口
    HWND hwnd = NULL;
    struct EnumData { DWORD pid; HWND hwnd; } data = { GetCurrentProcessId(), NULL };

    EnumWindows([](HWND hwnd, LPARAM lParam) -> BOOL {
        DWORD pid = 0;
        GetWindowThreadProcessId(hwnd, &pid);
        if (pid == (DWORD)lParam && IsWindowVisible(hwnd)) {
            char className[256] = {};
            GetClassNameA(hwnd, className, sizeof(className));
            // 過濾非遊戲窗口
            if (strcmp(className, "Progman") != 0 &&
                strcmp(className, "Shell_TrayWnd") != 0 &&
                strcmp(className, "WorkerW") != 0) {
                ((EnumData*)lParam)->hwnd = hwnd;
                return FALSE;
            }
        }
        return TRUE;
    }, (LPARAM)&data);

    return data.hwnd;
}

// ============================================================================
// DLL 入口點
// ============================================================================

static HMODULE g_hModule = NULL;

static DWORD WINAPI MainThread(LPVOID lpParam)
{
    g_hModule = (HMODULE)lpParam;

    // 等待遊戲載入
    Sleep(5000);

    // 初始化 TeamShare Client
    if (!TeamShareClient::Initialize()) {
        DebugLog("[TeamShare] Failed to initialize\n");
        return 0;
    }

    DebugLog("[TeamShare] Client initialized, connecting to server...\n");

    // 啟動 TeamShare 接收執行緒
    HANDLE hPipeThread = CreateThread(NULL, 0, TeamShareClient::ThreadProc, NULL, 0, NULL);
    if (hPipeThread) CloseHandle(hPipeThread);

    // 等待連接建立
    Sleep(3000);

    // 找到 CS2 窗口
    HWND hCS2 = NULL;
    for (int i = 0; i < 30 && !hCS2; i++) {
        hCS2 = FindCS2Window();
        if (!hCS2) Sleep(1000);
    }

    // 啟動 D3D9 ESP 疊加層
    if (hCS2) {
        EspOverlay::Initialize(hCS2);
        DebugLog("[TeamShare] ESP Overlay started\n");

        // 啟動資料同步執行緒
        HANDLE hSyncThread = CreateThread(NULL, 0, DataSyncThread, NULL, 0, NULL);
        if (hSyncThread) CloseHandle(hSyncThread);

        // 啟動事件監聽執行緒
        HANDLE hEventThread = CreateThread(NULL, 0, EventListenerThread, NULL, 0, NULL);
        if (hEventThread) CloseHandle(hEventThread);
    }

    // 主迴圈：等待卸載
    while (!(GetAsyncKeyState(VK_END) & 1))
    {
        Sleep(1000);

        // 每 5 秒檢查連接狀態
        static int checkTimer = 0;
        checkTimer++;
        if (checkTimer >= 5) {
            checkTimer = 0;

            // 檢查 Overlay 是否還在運行
            if (hCS2 && !EspOverlay::IsRunning()) {
                // 重新啟動 Overlay
                EspOverlay::Initialize(hCS2);
            }
        }
    }

    // 卸載
    EspOverlay::Shutdown();
    TeamShareClient::Shutdown();

    // 釋放 DLL
    FreeLibraryAndExitThread(g_hModule, 0);
    return 0;
}

extern "C" BOOL APIENTRY DllMain(HMODULE hModule, DWORD reason, LPVOID reserved)
{
    (void)reserved;

    switch (reason)
    {
    case DLL_PROCESS_ATTACH:
        DisableThreadLibraryCalls(hModule);
        {
            HANDLE hThread = CreateThread(NULL, 0, MainThread, hModule, 0, NULL);
            if (hThread) CloseHandle(hThread);
        }
        break;

    case DLL_PROCESS_DETACH:
        EspOverlay::Shutdown();
        TeamShareClient::Shutdown();
        break;
    }

    return TRUE;
}
