# ⚡ BloxStrike v3.0 — 終極 CS2 風格 Roblox FPS 腳本

---

## 🎮 遊戲連結

**👉 https://www.roblox.com/games/114234929420007/BloxStrike 👈**

---

## 📺 功能展示

### ⚔️ 戰鬥系統
```
自瞄 v2.0 ─────────────── 30+ 選項
├── FOV (10-360°)
├── 平滑度 (1-50)
├── 6 種骨頭瞄准
├── 5 種排序模式
├── 速度預測 + 延遲補償
├── 人性化 (隨機延遲 + 偏差)
└── 自動停止/開鏡/蹲下

觸發器 v2.0 ────────────── 15+ 選項
├── 延遲範圍 (0-400ms)
├── 連射模式
├── 仿人類隨機觸發
└── FOV 檢查

靜默瞄準 ───────────────── 伺服器端修改
後座力控制 ─────────────── 武器專用補償
無散佈 / 無後座 ────────── 完全移除
自動射擊 / 快速切換 ────── 一鍵操作
```

### 🎯 HVH / 暴力系統
```
暴力機器人 ─────────────── 進階自動瞄準
├── Multipoint (頭+胸+身體)
├── Safe Point (安全點)
├── Damage Override (傷害覆蓋)
├── PSilent (純靜默瞄準)
├── Rapid Fire (速射)
└── Auto Wallbang (自動穿牆)

反瞄準 ─────────────────── 8 種模式
├── Jitter / Spin / Back / Fake
├── Emotion (情緒 AA)
├── Lean (身體傾斜)
└── LBY Breaker

假延遲 ─────────────────── 4 種模式
├── Constant / Adaptive
├── Random / Tick
└── Hideshots + Onshot

解析器 ─────────────────── 智能解析
├── Brute Force
├── Moving AW
├── Freestand
└── Side Detection
```

### 👁️ ESP 系統 (60+ 選項)
```
框線 ──── 2D / 角落 / 3D / 填充 / 完整
名稱 ──── 名稱 + 背景 + 字體大小 + 對齊
血量 ──── 血條 (左/右/上) + 文字 + 顏色
護甲 ──── 護甲條
距離 ──── 距離顯示 + 單位切換
武器 ──── 武器名稱 + 彈藥數量
骷髏 ──── 骨骼線條 ESP
頭部 ──── 頭部圓圈 + hitbox
槍管 ──── 槍管方向
追蹤線 ── 從螢幕底部/中央/頂部/滑鼠
雷達 ──── 迷你雷達地圖
指南針 ── 頂部指南針
擊殺列表 ─ CS2 風格擊殺列表
傷害數字 ─ 傷害數字顯示
水印 ──── 左上角資訊
十字準心 ─ 5 種樣式 (+, ○, △, ◇, T)
```

### 🌍 世界功能
```
視野修改器 ── 調整 FOV
防閃光 ────── 完全移除閃光效果
全亮 ──────── 移除陰影
透視 ──────── 看穿薄牆
煙霧揭示 ──── 移除煙霧不透明度
無煙 ──────── 移除煙霧粒子
無火 ──────── 移除燃燒彈效果
手榴彈軌跡 ── 顯示手榴彈落點
無掉落傷害 ── 免疫掉落傷害
速度提升 ──── 調整移動速度
```

### 💀 擊殺效果 (30+ 聲音, 15+ 視覺)
```
擊殺音效 ──── 20 種風格
├── CS2 / Quake / 金屬管
├── Minecraft / Vine Boom
└── 更多...

螢幕效果 ──── 閃爍/模糊/色彩校正
視覺效果 ──── 色差/暗角/血滴/擴散
連殺系統 ──── 7 級
├── Double → Triple → Quad
├── Penta → Unstoppable
└── Rampage → GODLIKE
```

### 🐰 移動系統
```
兔子跳 ────── 8 種跳躍模式
├── Auto / Legit / HvH
├── Long Jump / B-Hop Plus
├── Edge Bug / Strafe Hack
└── Stamina Jump

空中轉向 ──── 6 種模式
├── Linear / Sinusoidal
├── Random / Aggressive
├── Smooth / Circular
└── 可調速度/角度/靈敏度

多重跳躍 ──── 2-5 次
自動衝刺 ──── 持續奔跑
```

### 🕵️ 隱身系統
```
反偵測 ────── 28 個防護區塊
├── getfenv 環境洩漏防禦
├── Raw Metamethod Hook 逃逸
├── ToString Trap 逃逸
├── Coroutine.wrap 堆疊溢位逃逸
└── CoreGui 引用逃逸

繞過系統 ──── 30 個進階繞過
├── __namecall Hook 保護
├── Executor 指紋偽裝
├── Signal Hook 保護
├── Remote 呼叫偽裝
├── Memory Region Cloaking
├── AC 簽名 evasion
├── Heartbeat Spoofing
└── Anti-Dump

流量偽裝 ──── 模擬正常流量
├── 噪音注入
├── 節流控制
├── 突發平滑
└── Remote 指紋
```

### 🌐 Discord 整合
```
事件通知 ──── 即時推送
├── 🎮 腳本載入
├── 💀 擊殺
├── 🎯 爆頭
├── ☠️ 死亡
├── 🔥 連殺 (3/5/7/10+)
├── 🏆 回合勝利
├── ❌ 回合失敗
└── 💣 炸彈安裝

富文本嵌入 ── 完整資訊
├── 標題/描述/顏色
├── 欄位 (玩家/武器/距離)
├── 縮圖 (頭像)
└── 時間戳
```

---

## ⚡ 快速開始

### 安裝方式 1：手動（推薦）
```bash
# 1. 下載倉庫
git clone https://github.com/jiajia67-code/BloxStrike.git

# 2. 複製 BloxStrike/ 資料夾到執行器目錄
# Potassium: %LOCALAPPDATA%\Potassium\scripts\

# 3. 在執行器中貼上 BloxStrike.lua 並執行
```

### 安裝方式 2：一鍵修復
```bash
# 1. 貼上 BloxStrike.lua（不要執行）
# 2. 貼上 BloxStrike_Fixer.lua 並執行
# 3. 自動修復所有模組並載入
```

### 安裝方式 3：獨立版
```bash
# 直接貼上 BloxStrike_Standalone.lua 並執行
# 所有模組已內嵌，不需要外部檔案
```

---

## 🎮 操作按鍵

| 按鍵 | 功能 |
|------|------|
| `INSERT` | 開啟/關閉選單 |
| `F3` | 效能監控 |
| `F9` | 安全模式 |
| `F10` | 緊急停用 |
| `F12` | 錯誤報告 |
| `X` | 切換 ESP |
| `Z` | 切換 Bhop |
| `C` | 切換 Anti-Aim |
| `V` | 切換 Silent Aim |
| `N` | 切換夜視 |
| `M` | 切換移除瞄準鏡 |
| `Q` | 快速切換武器 |
| `V` | 切換第三人稱 |
| `C` | 重置第三人稱相機 |

---

## 🖥️ 支援執行器

```
✅ Fluxus      ✅ Delta       ✅ Wave
✅ Solara      ✅ Hydrogen    ✅ Arceus X
✅ Script-Ware ✅ Synapse X   ✅ KRNL
✅ Comet       ✅ Oxygen U    ✅ Evon
✅ JJSploit    ✅ Nihon       ✅ AWP.GG
✅ Celery      ✅ Velocity    ✅ Potassium
✅ Real        ✅ ByteBreaker ✅ Nexomia
✅ Yub-X       ✅ Xeno        ✅ Vega X
✅ Ronix
```

## 📱 支援設備

```
💻 PC: Windows / macOS / Linux
📱 Mobile: Android / iOS (自動適配觸控)
🎮 Emulators: 所有 Roblox 模擬器
```

---

## 📊 功能統計

| 類別 | 數量 |
|------|------|
| 戰鬥功能 | 30+ |
| HVH 功能 | 80+ |
| ESP 功能 | 60+ |
| 世界功能 | 10 |
| 擊殺效果 | 30+ 聲音, 15+ 視覺 |
| 隱身功能 | 50+ |
| 移動功能 | 20+ |
| 總計 | **150+ 功能** |

---

## 🔧 模組架構

```
BloxStrike/
├── BloxStrike.lua          ← 主腳本
├── BloxStrike_Fixer.lua    ← 一鍵修復
├── BloxStrike_Standalone.lua ← 獨立版
└── modules/
    ├── core.lua            ← 核心服務
    ├── ui.lua              ← UI 框架
    ├── compat.lua          ← 執行器兼容
    ├── api.lua             ← 遊戲 API
    ├── combat.lua          ← 戰鬥系統
    ├── esp.lua             ← ESP 系統
    ├── world.lua           ← 世界功能
    ├── rage.lua            ← HVH 系統
    ├── stealth.lua         ← 隱身系統
    ├── utility.lua         ← 工具功能
    ├── webhook.lua         ← Discord 整合
    ├── events.lua          ← 事件追蹤
    ├── killeffects.lua     ← 擊殺效果
    ├── settings.lua        ← 設定系統
    ├── viewmodel.lua       ← 武器視角
    ├── combatassist.lua    ← 聊天助手
    ├── smartai.lua         ← AI 學習
    ├── pingadapt.lua       ← 延遲適應
    ├── cheatdetect.lua     ← 反作弊掃描
    ├── bypass.lua          ← 反作弊繞過
    ├── errorhandler.lua    ← 錯誤處理
    ├── hud.lua             ← HUD 顯示
    ├── luau_compat.lua     ← Luau 兼容
    └── luau_detect.lua     ← Luau 檢測
```

---

## ⚠️ 免責聲明

此腳本僅供教育和測試用途。使用任何第三方腳本都有被封鎖的風險。請先在小號測試。

---

## 📝 更新日誌

### v3.0.0 (最新)
- ✅ 修復所有16個壞掉的模組
- ✅ GUI 分頁優化 (13個邏輯分頁)
- ✅ 加入一鍵修復腳本
- ✅ 加入獨立版本
- ✅ 加入遊戲限制 (僅限 BloxStrike)
- ✅ 修復空白分頁名稱問題
- ✅ 重命名 "Combat Assist" 為 "Comms"
- ✅ 移除重複的設定按鈕

### v2.0
- ✅ 全裝置兼容層 (25+ 執行器)
- ✅ UI v2.0 (手機觸控 + 自適應螢幕)
- ✅ ESP 兼容層 (Drawing API 安全封裝)
- ✅ 設定兼容層 (跨執行器檔案操作)
- ✅ Webhook 兼容層 (跨執行器 HTTP)
- ✅ 全自動錯誤處理系統
- ✅ 設定存檔系統 (5 個預設)
- ✅ 武器視角修改器 (8 個預設)
- ✅ 擊殺音效+動畫 (30+ 聲音, 15+ 效果)
- ✅ 暴力機器人 (Ragebot, Anti-Aim, Fake Lag, Resolver)
- ✅ 靜默瞄準加入 HVH
- ✅ 兔子跳 (8 種模式)
- ✅ 反偵測系統 v2.0

---

*BloxStrike — 終極 CS2 風格 Roblox FPS 腳本*

**⚡ 150+ 功能 | 🎯 精準瞄準 | 🕵️ 完美隱身 | 🌐 Discord 整合 ⚡**
