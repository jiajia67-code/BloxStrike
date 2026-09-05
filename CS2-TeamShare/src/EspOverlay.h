// ============================================================================
// EspOverlay.h — Direct3D9 透明疊加層
// 在隊友螢幕上繪製方框、骨骼、血量等 ESP 資料
// 純 D3D9 + GDI — 不依賴 d3dx9
// ============================================================================

#pragma once
#include <Windows.h>
#include <cstdint>
#include <d3d9.h>
#include <cstdio>
#include <cstring>
#pragma comment(lib, "d3d9.lib")

#include "../CS2-Offsets/TeamShare.h"

// ============================================================================
// 簡易 2D 向量（替代 D3DXVECTOR2）
// ============================================================================

struct Vec2 {
    float x, y;
    Vec2() : x(0), y(0) {}
    Vec2(float _x, float _y) : x(_x), y(_y) {}
};

// ============================================================================
// 簡易頂點格式（用於 DrawPrimitiveUP 繪製線條和填充）
// ============================================================================

struct EspVertex {
    float x, y, z, rhw;
    DWORD color;
    EspVertex() : x(0), y(0), z(0), rhw(1.0f), color(0) {}
    EspVertex(float _x, float _y, DWORD _c) : x(_x), y(_y), z(0), rhw(1.0f), color(_c) {}
};

// ============================================================================
// 顏色定義
// ============================================================================

struct EspColor {
    BYTE r, g, b, a;
    EspColor() : r(255), g(255), b(255), a(255) {}
    EspColor(BYTE r, BYTE g, BYTE b, BYTE a = 255) : r(r), g(g), b(b), a(a) {}
    DWORD ToD3D() const { return D3DCOLOR_ARGB(a, r, g, b); }
};

namespace Colors {
    static const EspColor Box       (0, 255, 0);        // 綠色方框
    static const EspColor BoxFill   (0, 50, 0, 80);     // 綠色填充
    static const EspColor Health    (0, 255, 0);        // 血量綠
    static const EspColor HealthLow (255, 0, 0);        // 血量紅
    static const EspColor Name      (255, 255, 255);    // 白色名字
    static const EspColor Bone      (255, 200, 0);      // 金色骨骼
    static const EspColor BoneHead  (255, 50, 50);      // 紅色頭部
    static const EspColor Snapline  (100, 100, 255);    // 藍色連線
    static const EspColor Distance  (200, 200, 200);    // 灰色距離
    static const EspColor Weapon    (255, 165, 0);      // 橙色武器
    static const EspColor TeamShare (0, 200, 255);      // 青色（隊友分享標記）
}

// ============================================================================
// ESP 設定
// ============================================================================

struct EspSettings {
    bool enabled;
    bool showBoxes;         // 方框
    bool showSkeleton;      // 骨骼
    bool showHealthBar;     // 血量條
    bool showName;          // 名字
    bool showDistance;      // 距離
    bool showSnapline;      // 底部連線
    bool showWeapon;        // 武器
    bool showTeamMarker;    // 隊友分享標記
    float maxDistance;      // 最大顯示距離
    int   boxStyle;         // 0=2D, 1=3D corner, 2=3D full

    EspSettings() :
        enabled(true), showBoxes(true), showSkeleton(true),
        showHealthBar(true), showName(false), showDistance(true),
        showSnapline(true), showWeapon(false), showTeamMarker(true),
        maxDistance(3000.0f), boxStyle(0) {}
};

// ============================================================================
// Overlay 管理器
// ============================================================================

class EspOverlay {
public:
    static bool Initialize(HWND hTargetWnd);
    static void Shutdown();
    static bool IsRunning() { return g_running; }
    static void SetEspData(const TeamShareFullUpdate* data);
    static EspSettings& GetSettings() { return g_settings; }

    // 覆蓋層窗口過程
    static LRESULT CALLBACK OverlayWndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);

private:
    // D3D9
    static IDirect3D9*       g_pD3D;
    static IDirect3DDevice9* g_pDevice;

    // 純 D3D9 文字渲染（無 d3dx9）
    static HFONT             g_hFont;
    static IDirect3DTexture9* g_pTextTexture;
    static IDirect3DSurface9* g_pTextSurface;
    static int               g_textTexW;
    static int               g_textTexH;

    // 窗口
    static HWND   g_hOverlayWnd;
    static HWND   g_hTargetWnd;
    static bool   g_running;
    static DWORD  g_overlayThreadId;

    // 資料
    static TeamShareFullUpdate g_espData;
    static EspSettings         g_settings;
    static int    g_screenW;
    static int    g_screenH;
    static float  g_viewMatrix[16];

    // 初始化
    static bool CreateOverlayWindow();
    static bool InitD3D();
    static void ReleaseD3D();
    static bool InitTextRenderer();
    static void ReleaseTextRenderer();

    // 渲染
    static void Render();
    static void DrawLineInternal(float x1, float y1, float x2, float y2, DWORD color, float width = 1.0f);
    static void DrawBox2D(float x, float y, float w, float h, DWORD color);
    static void DrawBoxFilled(float x, float y, float w, float h, DWORD color);
    static void DrawHealthBar(float x, float y, float h, float health, float maxHealth);
    static void DrawSkeleton(const TeamSharePlayerData& player, DWORD color);
    static void DrawSnapline(float screenX, float screenY, DWORD color);
    static void DrawText(float x, float y, const char* text, DWORD color);

    // 投影
    static bool WorldToScreen(float worldX, float worldY, float worldZ, float& screenX, float& screenY);

    // 主迴圈
    static DWORD WINAPI OverlayThread(LPVOID lpParam);
};

// ============================================================================
// 靜態成員定義
// ============================================================================

// D3D9
IDirect3D9*       EspOverlay::g_pD3D       = nullptr;
IDirect3DDevice9* EspOverlay::g_pDevice     = nullptr;

// 純 D3D9 文字渲染
HFONT              EspOverlay::g_hFont        = NULL;
IDirect3DTexture9* EspOverlay::g_pTextTexture = nullptr;
IDirect3DSurface9* EspOverlay::g_pTextSurface = nullptr;
int                EspOverlay::g_textTexW     = 512;
int                EspOverlay::g_textTexH     = 32;

// 窗口
HWND   EspOverlay::g_hOverlayWnd = NULL;
HWND   EspOverlay::g_hTargetWnd  = NULL;
bool   EspOverlay::g_running     = false;
DWORD  EspOverlay::g_overlayThreadId = 0;

// 資料
TeamShareFullUpdate EspOverlay::g_espData = {};
EspSettings         EspOverlay::g_settings;
int    EspOverlay::g_screenW = 1920;
int    EspOverlay::g_screenH = 1080;
float  EspOverlay::g_viewMatrix[16] = {};

// ============================================================================
// 初始化
// ============================================================================

bool EspOverlay::Initialize(HWND hTargetWnd) {
    g_hTargetWnd = hTargetWnd;
    g_running = true;

    HANDLE hThread = CreateThread(NULL, 0, OverlayThread, NULL, 0, &g_overlayThreadId);
    if (!hThread) { g_running = false; return false; }
    CloseHandle(hThread);
    return true;
}

void EspOverlay::Shutdown() {
    g_running = false;
    Sleep(200);
    ReleaseD3D();
    if (g_hOverlayWnd) {
        DestroyWindow(g_hOverlayWnd);
        g_hOverlayWnd = NULL;
    }
}

// ============================================================================
// 建立透明疊加窗口
// ============================================================================

bool EspOverlay::CreateOverlayWindow() {
    WNDCLASSEXA wc = {};
    wc.cbSize = sizeof(wc);
    wc.style = CS_HREDRAW | CS_VREDRAW;
    wc.lpfnWndProc = OverlayWndProc;
    wc.hInstance = GetModuleHandle(NULL);
    wc.lpszClassName = "TSOverlay";
    RegisterClassExA(&wc);

    g_hOverlayWnd = CreateWindowExA(
        WS_EX_LAYERED | WS_EX_TRANSPARENT | WS_EX_TOPMOST | WS_EX_NOACTIVATE,
        "TSOverlay", "TeamShare ESP",
        WS_POPUP,
        0, 0, g_screenW, g_screenH,
        NULL, NULL, wc.hInstance, NULL);

    if (!g_hOverlayWnd) return false;

    // 設定透明色（黑色 = 透明）
    SetLayeredWindowAttributes(g_hOverlayWnd, RGB(0, 0, 0), 0, LWA_COLORKEY);
    ShowWindow(g_hOverlayWnd, SW_SHOW);
    UpdateWindow(g_hOverlayWnd);

    return true;
}

// ============================================================================
// 初始化 Direct3D9（純 D3D9，無 d3dx9）
// ============================================================================

bool EspOverlay::InitD3D() {
    g_pD3D = Direct3DCreate9(D3D_SDK_VERSION);
    if (!g_pD3D) return false;

    D3DPRESENT_PARAMETERS pp = {};
    pp.Windowed               = TRUE;
    pp.SwapEffect             = D3DSWAPEFFECT_DISCARD;
    pp.hDeviceWindow          = g_hOverlayWnd;
    pp.EnableAutoDepthStencil = TRUE;
    pp.AutoDepthStencilFormat = D3DFMT_D16;
    pp.PresentationInterval   = D3DPRESENT_INTERVAL_ONE;

    HRESULT hr = g_pD3D->CreateDevice(
        D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, g_hOverlayWnd,
        D3DCREATE_HARDWARE_VERTEXPROCESSING,
        &pp, &g_pDevice);

    if (FAILED(hr)) {
        hr = g_pD3D->CreateDevice(
            D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, g_hOverlayWnd,
            D3DCREATE_SOFTWARE_VERTEXPROCESSING,
            &pp, &g_pDevice);
    }
    if (FAILED(hr)) return false;

    // 設定渲染狀態
    g_pDevice->SetRenderState(D3DRS_ALPHABLENDENABLE, TRUE);
    g_pDevice->SetRenderState(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA);
    g_pDevice->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA);
    g_pDevice->SetRenderState(D3DRS_LIGHTING, FALSE);
    g_pDevice->SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG1);
    g_pDevice->SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_DIFFUSE);
    g_pDevice->SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1);
    g_pDevice->SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_DIFFUSE);

    // 初始化文字渲染器（純 D3D9 + GDI）
    if (!InitTextRenderer()) return false;

    return true;
}

// ============================================================================
// 純 D3D9 文字渲染器（替代 ID3DXFont）
// 使用 GDI 在 D3D9 紋理表面繪製文字
// ============================================================================

bool EspOverlay::InitTextRenderer() {
    // 建立 Win32 字型
    g_hFont = CreateFontA(
        14, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,
        DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        ANTIALIASED_QUALITY, DEFAULT_PITCH | FF_DONTCARE,
        "Consolas");
    if (!g_hFont) return false;

    // 建立 D3D9 紋理（用於文字渲染）
    g_textTexW = 512;
    g_textTexH = 32;
    HRESULT hr = g_pDevice->CreateTexture(
        g_textTexW, g_textTexH, 1,
        D3DUSAGE_RENDERTARGET, D3DFMT_A8R8G8B8,
        D3DPOOL_DEFAULT, &g_pTextTexture, NULL);
    if (FAILED(hr)) return false;

    // 取得表面鎖定用
    hr = g_pTextTexture->GetSurfaceLevel(0, &g_pTextSurface);
    if (FAILED(hr)) return false;

    return true;
}

void EspOverlay::ReleaseTextRenderer() {
    if (g_pTextSurface) { g_pTextSurface->Release(); g_pTextSurface = nullptr; }
    if (g_pTextTexture) { g_pTextTexture->Release(); g_pTextTexture = nullptr; }
    if (g_hFont) { DeleteObject(g_hFont); g_hFont = NULL; }
}

// ============================================================================
// 初始化/釋放
// ============================================================================

void EspOverlay::ReleaseD3D() {
    ReleaseTextRenderer();
    if (g_pDevice) { g_pDevice->Release(); g_pDevice = nullptr; }
    if (g_pD3D) { g_pD3D->Release(); g_pD3D = nullptr; }
}

// ============================================================================
// 窗口過程（輸入穿透）
// ============================================================================

LRESULT CALLBACK EspOverlay::OverlayWndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_DESTROY:
        g_running = false;
        PostQuitMessage(0);
        return 0;
    case WM_KEYDOWN:
        if (wParam == VK_INSERT) {
            g_settings.enabled = !g_settings.enabled;
        }
        else if (wParam == VK_F1) {
            g_settings.showBoxes = !g_settings.showBoxes;
        }
        else if (wParam == VK_F2) {
            g_settings.showSkeleton = !g_settings.showSkeleton;
        }
        else if (wParam == VK_F3) {
            g_settings.showHealthBar = !g_settings.showHealthBar;
        }
        else if (wParam == VK_F4) {
            g_settings.showSnapline = !g_settings.showSnapline;
        }
        break;
    }
    return DefWindowProcA(hWnd, msg, wParam, lParam);
}

// ============================================================================
// WorldToScreen 投影
// ============================================================================

bool EspOverlay::WorldToScreen(float wx, float wy, float wz, float& sx, float& sy) {
    float clipX = g_viewMatrix[0]*wx + g_viewMatrix[4]*wy + g_viewMatrix[8]*wz  + g_viewMatrix[12];
    float clipY = g_viewMatrix[1]*wx + g_viewMatrix[5]*wy + g_viewMatrix[9]*wz  + g_viewMatrix[13];
    float clipW = g_viewMatrix[3]*wx + g_viewMatrix[7]*wy + g_viewMatrix[11]*wz + g_viewMatrix[15];

    if (clipW < 0.01f) return false;

    float ndcX = clipX / clipW;
    float ndcY = clipY / clipW;

    sx = (g_screenW / 2.0f) + (ndcX * g_screenW / 2.0f);
    sy = (g_screenH / 2.0f) - (ndcY * g_screenH / 2.0f);

    return (sx > -100 && sx < g_screenW + 100 && sy > -100 && sy < g_screenH + 100);
}


// ============================================================================
// 繪製輔助函數
// ============================================================================

// --- 繪製線條（純 D3D9 DrawPrimitiveUP，替代 ID3DXLine）---

void EspOverlay::DrawLineInternal(float x1, float y1, float x2, float y2, DWORD color, float width) {
    if (!g_pDevice) return;

    // 設定渲染狀態
    g_pDevice->SetTexture(0, NULL);
    g_pDevice->SetFVF(D3DFVF_XYZRHW | D3DFVF_DIFFUSE);

    // 線段就是兩個頂點
    EspVertex verts[2] = {
        EspVertex(x1, y1, color),
        EspVertex(x2, y2, color)
    };

    g_pDevice->DrawPrimitiveUP(D3DPT_LINESTRIP, 1, verts, sizeof(EspVertex));
}

void EspOverlay::DrawBox2D(float x, float y, float w, float h, DWORD color) {
    if (!g_pDevice) return;

    g_pDevice->SetTexture(0, NULL);
    g_pDevice->SetFVF(D3DFVF_XYZRHW | D3DFVF_DIFFUSE);

    // 4 個邊用 5 個頂點（LINESTRIP 閉合）
    EspVertex verts[5] = {
        EspVertex(x,   y,   color),
        EspVertex(x+w, y,   color),
        EspVertex(x+w, y+h, color),
        EspVertex(x,   y+h, color),
        EspVertex(x,   y,   color)
    };

    g_pDevice->DrawPrimitiveUP(D3DPT_LINESTRIP, 4, verts, sizeof(EspVertex));
}

void EspOverlay::DrawBoxFilled(float x, float y, float w, float h, DWORD color) {
    if (!g_pDevice) return;

    EspVertex vertices[4] = {
        EspVertex(x,   y,   color),
        EspVertex(x+w, y,   color),
        EspVertex(x,   y+h, color),
        EspVertex(x+w, y+h, color),
    };

    g_pDevice->SetFVF(D3DFVF_XYZRHW | D3DFVF_DIFFUSE);
    g_pDevice->SetTexture(0, NULL);
    g_pDevice->DrawPrimitiveUP(D3DPT_TRIANGLESTRIP, 2, vertices, sizeof(EspVertex));
}

void EspOverlay::DrawHealthBar(float x, float y, float h, float health, float maxHealth) {
    float barW = 4.0f;
    float ratio = (maxHealth > 0) ? health / maxHealth : 0;
    if (ratio > 1.0f) ratio = 1.0f;

    DWORD barColor;
    if (ratio > 0.6f) barColor = Colors::Health.ToD3D();
    else if (ratio > 0.3f) barColor = D3DCOLOR_ARGB(255, 255, 165, 0); // 橙色
    else barColor = Colors::HealthLow.ToD3D();

    // 背景（紅色）
    DrawBoxFilled(x - barW - 2, y, barW, h, D3DCOLOR_ARGB(100, 0, 0, 0));
    // 血量
    float fillH = h * ratio;
    DrawBoxFilled(x - barW - 2, y + (h - fillH), barW, fillH, barColor);
}

void EspOverlay::DrawSkeleton(const TeamSharePlayerData& player, DWORD color) {
    if (!g_pDevice) return;

    // 提取骨骼陣列
    const float(*bones)[3] = (const float(*)[3])&player.boneHead;

    // 骨骼連接定義
    struct { int a, b; } pairs[] = {
        {5, 3},  // origin → pelvis
        {3, 4},  // pelvis → spine2
        {4, 2},  // spine2 → chest
        {2, 1},  // chest → neck
        {1, 0},  // neck → head
        {1, 6},  // neck → shoulderL
        {6, 7},  // shoulderL → elbowL
        {7, 8},  // elbowL → handL
        {1, 9},  // neck → shoulderR
        {9, 10}, // shoulderR → elbowR
        {10, 11},// elbowR → handR
        {3, 12}, // pelvis → hipL
        {12, 13},// hipL → kneeL
        {13, 14},// kneeL → footL
        {3, 15}, // pelvis → hipR
        {15, 16},// hipR → kneeR
        {16, 17},// kneeR → footR
    };

    for (auto& bp : pairs) {
        float sx1, sy1, sx2, sy2;
        bool on1 = WorldToScreen(bones[bp.a][0], bones[bp.a][1], bones[bp.a][2], sx1, sy1);
        bool on2 = WorldToScreen(bones[bp.b][0], bones[bp.b][1], bones[bp.b][2], sx2, sy2);

        if (on1 && on2) {
            DWORD lineColor = (bp.a == 0 || bp.b == 0) ? Colors::BoneHead.ToD3D() : color;
            DrawLineInternal(sx1, sy1, sx2, sy2, lineColor, 1.5f);
        }
    }
}

void EspOverlay::DrawSnapline(float screenX, float screenY, DWORD color) {
    float centerX = g_screenW / 2.0f;
    float bottomY = g_screenH - 20.0f;
    DrawLineInternal(centerX, bottomY, screenX, screenY, color, 1.0f);
}

// ============================================================================
// 純 D3D9 文字繪製（替代 ID3DXFont）
// 使用 GDI 在 D3D9 紋理的表面 DC 上繪製，然後渲染紋理
// ============================================================================

void EspOverlay::DrawText(float x, float y, const char* text, DWORD color) {
    if (!g_pDevice || !g_pTextTexture || !g_pTextSurface || !text || !text[0]) return;
    if (!g_hFont) return;

    // 從表面取得 DC（GDI 繪製目標）
    HDC hdc = NULL;
    HRESULT hr = g_pTextSurface->GetDC(&hdc);
    if (FAILED(hr) || !hdc) return;

    // 清除表面為全透明
    RECT clearRect = {0, 0, g_textTexW, g_textTexH};
    HBRUSH hbrBlack = (HBRUSH)GetStockObject(BLACK_BRUSH);
    FillRect(hdc, &clearRect, hbrBlack);

    // 設定 GDI 繪製參數
    SetBkMode(hdc, TRANSPARENT);
    SetTextColor(hdc, RGB((color >> 16) & 0xFF, (color >> 8) & 0xFF, color & 0xFF));
    SelectObject(hdc, g_hFont);

    // 計算文字大小以決定實際需要的紋理大小
    SIZE textSize = {};
    GetTextExtentPoint32A(hdc, text, (int)strlen(text), &textSize);

    // 繪製文字到 DC
    TextOutA(hdc, 0, 0, text, (int)strlen(text));

    g_pTextSurface->ReleaseDC(hdc);

    // 渲染紋理到螢幕（只繪製文字佔據的區域）
    float tw = (float)textSize.cx + 4.0f;
    float th = (float)textSize.cy + 2.0f;

    // 設定紋理和渲染狀態
    g_pDevice->SetTexture(0, g_pTextTexture);
    g_pDevice->SetFVF(D3DFVF_XYZRHW | D3DFVF_DIFFUSE | D3DFVF_TEX1);

    // 定義帶紋理坐標的頂點
    struct TextVertex {
        float x, y, z, rhw;
        DWORD color;
        float tu, tv;
    };

    TextVertex quad[4] = {
        { x,      y,      0, 1, 0xFFFFFFFF, 0.0f, 0.0f },
        { x + tw, y,      0, 1, 0xFFFFFFFF, 1.0f, 0.0f },
        { x,      y + th, 0, 1, 0xFFFFFFFF, 0.0f, 1.0f },
        { x + tw, y + th, 0, 1, 0xFFFFFFFF, 1.0f, 1.0f },
    };

    g_pDevice->DrawPrimitiveUP(D3DPT_TRIANGLESTRIP, 2, quad, sizeof(TextVertex));

    // 清除紋理以供下次使用
    g_pDevice->SetTexture(0, NULL);
}

// ============================================================================
// 更新 ESP 資料（從外部呼叫）
// ============================================================================

void EspOverlay::SetEspData(const TeamShareFullUpdate* data) {
    if (data) {
        memcpy(&g_espData, data, sizeof(TeamShareFullUpdate));
    }
}

// ============================================================================
// 主渲染迴圈
// ============================================================================

DWORD WINAPI EspOverlay::OverlayThread(LPVOID lpParam) {
    (void)lpParam;

    // 等待遊戲窗口
    Sleep(3000);

    // 建立疊加窗口
    if (!CreateOverlayWindow()) return 0;

    // 初始化 D3D9
    if (!InitD3D()) return 0;

    MSG msg = {};
    while (g_running) {
        while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
            if (msg.message == WM_QUIT) { g_running = false; break; }
        }

        if (!g_running) break;

        // 同步目標窗口位置和大小
        if (g_hTargetWnd && IsWindow(g_hTargetWnd)) {
            RECT rc;
            GetWindowRect(g_hTargetWnd, &rc);
            int newX = rc.left;
            int newY = rc.top;
            int newW = rc.right - rc.left;
            int newH = rc.bottom - rc.top;

            if (newW > 0 && newH > 0) {
                if (newW != g_screenW || newH != g_screenH) {
                    g_screenW = newW;
                    g_screenH = newH;
                    MoveWindow(g_hOverlayWnd, newX, newY, newW, newH, FALSE);
                }
                SetWindowPos(g_hOverlayWnd, HWND_TOPMOST, newX, newY, newW, newH,
                    SWP_NOACTIVATE | SWP_SHOWWINDOW);
            }
        }

        // 渲染
        if (g_settings.enabled) {
            Render();
        }

        Sleep(16); // ~60fps
    }

    ReleaseD3D();
    return 0;
}

// ============================================================================
// 主渲染函數
// ============================================================================

void EspOverlay::Render() {
    if (!g_pDevice) return;

    // 清除背景為黑色（透明色）
    g_pDevice->Clear(0, NULL, D3DCLEAR_TARGET | D3DCLEAR_ZBUFFER,
                     D3DCOLOR_XRGB(0, 0, 0), 1.0f, 0);

    if (FAILED(g_pDevice->BeginScene())) return;

    // 處理輸入
    if (GetAsyncKeyState(VK_INSERT) & 1) g_settings.enabled = !g_settings.enabled;
    if (GetAsyncKeyState(VK_F1) & 1) g_settings.showBoxes = !g_settings.showBoxes;
    if (GetAsyncKeyState(VK_F2) & 1) g_settings.showSkeleton = !g_settings.showSkeleton;
    if (GetAsyncKeyState(VK_F3) & 1) g_settings.showHealthBar = !g_settings.showHealthBar;
    if (GetAsyncKeyState(VK_F4) & 1) g_settings.showSnapline = !g_settings.showSnapline;
    if (GetAsyncKeyState(VK_F5) & 1) g_settings.showDistance = !g_settings.showDistance;

    // 繪製隊友分享標記
    if (g_settings.showTeamMarker) {
        DrawText(10, 10, "[TeamShare ESP] ON - F1~F5: Toggle", Colors::TeamShare.ToD3D());
        char info[128];
        wsprintfA(info, "Players: %d | Press INSERT to toggle", g_espData.header.playerCount);
        DrawText(10, 28, info, Colors::Distance.ToD3D());
    }

    // 遍歷每個玩家
    for (uint32_t i = 0; i < g_espData.header.playerCount && i < TEAMSHARE_MAX_PLAYERS; i++) {
        const TeamSharePlayerData& p = g_espData.players[i];
        if (p.entityId == 0) continue;
        if (p.health <= 0) continue;
        if (p.isAlive == 0) continue;

        // 距離檢查
        float dist = (p.distance > 0) ? p.distance : 1.0f;
        if (dist > g_settings.maxDistance * g_settings.maxDistance) continue;

        // 獲取頭部螢幕座標
        float headSX = 0, headSY = 0;
        float bodySX = 0, bodySY = 0;
        float feetSX = 0, feetSY = 0;

        bool headOk = WorldToScreen(p.boneHead[0], p.boneHead[1], p.boneHead[2], headSX, headSY);
        bool bodyOk = WorldToScreen(p.originX, p.originY, p.originZ, bodySX, bodySY);
        bool feetOk = WorldToScreen(p.bonePelvis[0], p.bonePelvis[1], p.bonePelvis[2], feetSX, feetSY);

        if (!headOk && !bodyOk) continue;

        // 使用可用的座標
        float topX = headOk ? headSX : bodySX;
        float topY = headOk ? headSY : bodySY;
        float botX = bodyOk ? bodySX : headSX;
        float botY = bodyOk ? bodySY : headSY;

        // 方框尺寸
        float boxH = (botY > topY) ? (botY - topY) : 60.0f;
        float boxW = boxH * 0.5f;
        float boxX = topX - boxW / 2.0f;
        float boxY = topY - 10.0f;
        boxH += 20.0f;

        DWORD espColor = Colors::Box.ToD3D();

        // 血量顏色
        float healthRatio = p.health / 100.0f;
        DWORD healthColor;
        if (healthRatio > 0.6f) healthColor = Colors::Health.ToD3D();
        else if (healthRatio > 0.3f) healthColor = D3DCOLOR_ARGB(255, 255, 165, 0);
        else healthColor = Colors::HealthLow.ToD3D();

        // 繪製方框
        if (g_settings.showBoxes) {
            DrawBox2D(boxX, boxY, boxW, boxH, espColor);
        }

        // 繪製血量條
        if (g_settings.showHealthBar) {
            DrawHealthBar(boxX, boxY, boxH, p.health, 100.0f);
        }

        // 繪製骨骼
        if (g_settings.showSkeleton) {
            DrawSkeleton(p, Colors::Bone.ToD3D());
        }

        // 繪製連線
        if (g_settings.showSnapline) {
            DrawSnapline(topX, topY + boxH, Colors::Snapline.ToD3D());
        }

        // 繪製血量文字
        if (g_settings.showName) {
            char hpText[32];
            wsprintfA(hpText, "%.0f HP", p.health);
            DrawText(topX - 20, boxY - 16, hpText, healthColor);
        }

        // 繪製距離
        if (g_settings.showDistance) {
            char distText[32];
            float distM = dist / 39.37f; // CS2 單位轉公尺
            wsprintfA(distText, "%.0fm", distM);
            DrawText(topX - 15, boxY + boxH + 4, distText, Colors::Distance.ToD3D());
        }

        // 繪製武器
        if (g_settings.showWeapon && p.weaponId > 0) {
            // 簡易武器名稱（常見武器）
            const char* weaponName = "?";
            switch (p.weaponId) {
                case 4: weaponName = "AK-47"; break;
                case 7: weaponName = "M4A4"; break;
                case 16: weaponName = "M4A1-S"; break;
                case 9: weaponName = "AWP"; break;
                case 38: weaponName = "SSG 08"; break;
                case 13: weaponName = "Galil"; break;
                case 10: weaponName = "FAMAS"; break;
                case 61: weaponName = "USP-S"; break;
                case 30: weaponName = "Glock-18"; break;
                case 32: weaponName = "P250"; break;
                case 2: weaponName = "Dual Berettas"; break;
                case 1: weaponName = "Desert Eagle"; break;
                case 3: weaponName = "Five-Seven"; break;
                case 64: weaponName = "Tec-9"; break;
                case 63: weaponName = "CZ75"; break;
                case 26: weaponName = "PP-Bizon"; break;
                case 17: weaponName = "MP9"; break;
                case 23: weaponName = "MP5-SD"; break;
                case 24: weaponName = "UMP-45"; break;
                case 19: weaponName = "P90"; break;
                case 8: weaponName = "Scout"; break;
                case 39: weaponName = "AUG"; break;
                case 28: weaponName = "Negev"; break;
            }
            DrawText(topX - 20, boxY + boxH + 18, weaponName, Colors::Weapon.ToD3D());
        }

        // 狀態標記
        if (p.isScoped) {
            DrawText(topX + boxW / 2 + 5, topY, "[SCOPE]", D3DCOLOR_ARGB(255, 100, 200, 255));
        }
        if (p.isDefusing) {
            DrawText(topX + boxW / 2 + 5, topY + 16, "[DEFUSE]", D3DCOLOR_ARGB(255, 255, 100, 100));
        }
    }

    g_pDevice->EndScene();
    g_pDevice->Present(NULL, NULL, NULL, NULL);
}
