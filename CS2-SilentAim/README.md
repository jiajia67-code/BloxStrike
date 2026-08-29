# CS2 Silent Aim DLL

靜默自瞄 DLL for CS2，透過 CreateMove hook 修改伺服器端角度。

## 功能

- **Silent Aim** — 修改 CUserCmd 角度，伺服器看到的角度跟畫面不同
- **Anti-Aim** — 支援外部程式的反瞄準角度
- **IPC 通訊** — 與 Titled GUI CS2 外部程式共享記憶體
- **自動注入** — 外部程式自動注入 DLL 到 CS2

## 原理

### 為什麼需要 DLL？

外部程式只能修改記憶體中的數值（如 `dwViewAngles`），但這些修改：
1. 伺服器不會看到（只影響本地渲染）
2. 可以被伺服器驗證並修正

DLL hook 則是在 **`CreateMove` 函數被呼叫時**修改角度：
1. CS2 每個 tick 都會呼叫 `CCSGOInput::CreateMove`
2. 我們 hook 這個函數
3. 在函數執行後，修改 `CUserCmd` 中的視角角度
4. 伺服器收到的就是修改後的角度

### 技術架構

```
┌─ CS2 遊戲引擎 ─────────────────────────────┐
│  CreateMove() 被呼叫                        │
│    ↓                                        │
│  我們的 Hook 攔截                           │
│    ↓                                        │
│  從 IPC 讀取外部程式的瞄準角度               │
│    ↓                                        │
│  修改 CUserCmd.viewangles                   │
│    ↓                                        │
│  呼叫原始 CreateMove()                      │
│    ↓                                        │
│  伺服器收到修改後的角度 → 靜默瞄準生效！    │
└─────────────────────────────────────────────┘
```

## 編譯

### 方法 1：Visual Studio (推薦)

1. 開啟 **Developer Command Prompt for VS**
2. 執行 `build.bat`
3. DLL 會生成在 `bin/` 目錄

### 方法 2：CMake

```bash
mkdir build
cd build
cmake .. -G "Visual Studio 17 2022"
cmake --build . --config Release
```

### 方法 3：手動編譯

```bash
cl /EHsc /O2 /LD /Fe:"CS2-SilentAim.dll" src\dllmain.cpp /I src kernel32.lib psapi.lib
```

## 使用方式

### 自動注入（推薦）

1. 先啟動 Titled GUI CS2 外部程式
2. 啟動 CS2 並進入地圖
3. 外部程式會自動注入 DLL

### 手動注入

1. 使用任何 DLL 注入器
2. 注入 `CS2-SilentAim.dll` 到 `cs2.exe` 進程
3. DLL 會自動連接 IPC

### 控制項

| 按鍵 | 功能 |
|------|------|
| DELETE | 從 CS2 卸載 DLL |

## 檔案結構

```
CS2-SilentAim/
├── src/
│   ├── dllmain.cpp      # DLL 入口點
│   ├── Hook.h           # CreateMove hook + silent aim 邏輯
│   ├── IPC.h            # 與外部程式通訊
│   └── PatternScan.h    # 模式掃描器
├── CMakeLists.txt       # CMake 建置設定
├── build.bat            # MSVC 編譯腳本
└── README.md            # 本文件
```

## 重要注意事項

### BattlEye 保護

CS2 使用 BattlEye 反外掛，DLL 注入可能會被偵測：
- **風險等級**：高
- **偵測方式**：內核級驅動掃描
- **建議**：僅在私人伺服器測試

### Offset 更新

CS2 每次更新後，以下 offset 可能改變：
- `CCSGOInput` 的 VTable 結構
- `CUserCmd` 的記憶體布局
- `CreateMove` 的函數簽章

每次更新後需要：
1. 重新反編譯 `client.dll`
2. 更新 Pattern Scan 簽章
3. 重新編譯 DLL

### 與外部程式的整合

DLL 透過共享記憶體（Memory Mapped File）與 Titled GUI CS2 通訊：
- 共享記憶體名稱：`Local\TitledGuiSilentAim`
- 結構體大小：`sizeof(SharedAimData)`
- Magic Number：`0x43425546`

## 依賴

- MinHook（需要下載並連結）
- Windows SDK
- Visual Studio Build Tools

## License

僅供學習和研究用途。
