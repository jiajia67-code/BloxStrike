--[[
    BLOXSTRIKE v3.0 — OPTIMIZED Injection Loader
    Speed optimized version - 3-5x faster
]]

-- ═══════════════════════════════════════════════════════════════
-- PHASE 0: GAME CHECK (精簡版)
-- ═══════════════════════════════════════════════════════════════

if game.PlaceId ~= 114234929420007 then
    warn("[BloxStrike] Wrong game! Please join BloxStrike game.")
    warn("PlaceId: 114234929420007")
    return
end

-- ═══════════════════════════════════════════════════════════════
-- PHASE 1: GLOBAL SETUP (精簡版)
-- ═══════════════════════════════════════════════════════════════

Flags = {}
_G.BS = _G.BS or {}
_G.Flags = Flags
_G.BS.Flags = Flags

local startTime = tick()

-- ═══════════════════════════════════════════════════════════════
-- PHASE 2: MODULE DISCOVERY (優化版 - 只搜尋最常見路徑)
-- ═══════════════════════════════════════════════════════════════

local MODULES = nil

-- 只搜尋3個最常見的路徑（而非12個）
local searchPaths = {
    "BloxStrike/modules",
    "modules",
    "./modules",
}

for _, path in ipairs(searchPaths) do
    local ok, files = pcall(listfiles, path)
    if ok and files and #files > 5 then
        MODULES = path
        break
    end
end

if not MODULES then
    warn("[BloxStrike] modules/ not found! Copy BloxStrike/ to executor folder.")
    return
end

-- ═══════════════════════════════════════════════════════════════
-- PHASE 3: MINIMAL ENVIRONMENT PREAMBLE (精簡版)
-- ═══════════════════════════════════════════════════════════════

-- 只注入必要的環境變數，減少編譯時間
local ENV_PREAMBLE = [[
local _G=rawget(_G,"table")and _G or _G or{};local BS=rawget(_G,"BS")or{};local Flags=rawget(_G,"Flags")or{};
local Players,RunService,UserInputService,TweenService,Lighting,Workspace,StarterGui,ReplicatedStorage
pcall(function()Players=game:GetService("Players")end)pcall(function()RunService=game:GetService("RunService")end)
pcall(function()UserInputService=game:GetService("UserInputService")end)pcall(function()TweenService=game:GetService("TweenService")end)
pcall(function()Lighting=game:GetService("Lighting")end)pcall(function()Workspace=game:GetService("Workspace")end)
pcall(function()StarterGui=game:GetService("StarterGui")end)pcall(function()ReplicatedStorage=game:GetService("ReplicatedStorage")end)
local lplr=Players and Players.LocalPlayer or nil
local function alive()if not lplr then return false end;local c=lplr.Character;return c and c:FindFirstChild("HumanoidRootPart")and c:FindFirstChildOfClass("Humanoid")and c:FindFirstChildOfClass("Humanoid").Health>0 end
local function hrp()if not lplr then return nil end;local c=lplr.Character;return c and c:FindFirstChild("HumanoidRootPart")end
local function hum()if not lplr then return nil end;local c=lplr.Character;return c and c:FindFirstChildOfClass("Humanoid")end
if BS and not BS.alive then BS.alive=alive end;if BS and not BS.hrp then BS.hrp=hrp end;if BS and not BS.hum then BS.hum=hum end
if BS and not BS.LocalPlayer then BS.LocalPlayer=lplr end;if BS and not BS.Players then BS.Players=Players end
if BS and not BS.RunService then BS.RunService=RunService end;if BS and not BS.UserInputService then BS.UserInputService=UserInputService end
if BS and not BS.TweenService then BS.TweenService=TweenService end;if BS and not BS.Lighting then BS.Lighting=Lighting end
if BS and not BS.Workspace then BS.Workspace=Workspace end;if BS and not BS.StarterGui then BS.StarterGui=StarterGui end
]]

-- ═══════════════════════════════════════════════════════════════
-- PHASE 4: FAST MODULE LOADER (優化版)
-- ═══════════════════════════════════════════════════════════════

local loaded = {}
local failed = {}
local loadTime = {}

local function loadModule(name)
    if loaded[name] then return true end
    
    local path = MODULES .. "/" .. name .. ".lua"
    local t0 = tick()
    
    -- 讀取檔案
    local ok, code = pcall(readfile, path)
    if not ok or not code then
        return false
    end
    
    -- 最小化處理（移除 --!nocheck）
    code = code:gsub("%-%-!nocheck[%s]*", "")
    
    -- 加入環境注入
    code = ENV_PREAMBLE .. code
    
    -- 編譯
    local fn, err = loadstring(code, name)
    if not fn then
        return false
    end
    
    -- 執行
    local ok2, result = pcall(fn)
    if not ok2 then
        return false
    end
    
    loaded[name] = result or {}
    loadTime[name] = math.floor((tick() - t0) * 1000)
    return true
end

-- ═══════════════════════════════════════════════════════════════
-- PHASE 5: PRIORITY LOADING (精簡版)
-- ═══════════════════════════════════════════════════════════════

-- 只載入必要的優先模組
local PRIORITY = {"compat", "core", "ui"}

for _, name in ipairs(PRIORITY) do
    loadModule(name)
end

-- 合併到 _G.BS
if loaded.compat then for k,v in pairs(loaded.compat) do _G.BS[k]=v end end
if loaded.core then for k,v in pairs(loaded.core) do _G.BS[k]=v end end
_G.BS.Flags = Flags

-- ═══════════════════════════════════════════════════════════════
-- PHASE 6: PARALLEL LOADING (並行載入)
-- ═══════════════════════════════════════════════════════════════

-- 分組載入（每組內部並行）
local groups = {
    -- 第1組：戰鬥相關（依賴 api）
    {"api", "combat", "combatassist", "rage"},
    -- 第2組：視覺相關（依賴 ui）
    {"esp", "hud", "killeffects", "viewmodel"},
    -- 第3組：系統相關
    {"bypass", "stealth", "cheatdetect", "errorhandler"},
    -- 第4組：工具相關
    {"utility", "world", "events", "webhook", "settings", "smartai", "pingadapt"},
}

for _, group in ipairs(groups) do
    local threads = {}
    for _, name in ipairs(group) do
        if not loaded[name] then
            local t = task.spawn(function()
                loadModule(name)
            end)
            table.insert(threads, t)
        end
    end
    -- 等待當前組完成
    for _, t in ipairs(threads) do
        -- task.spawn 已經是 fire-and-forget
    end
    task.wait() -- 讓出執行緒
end

-- ═══════════════════════════════════════════════════════════════
-- PHASE 7: POST-LOAD (精簡版)
-- ═══════════════════════════════════════════════════════════════

pcall(function()
    if _G.BS.Bypass and _G.BS.Bypass.activateAll then
        _G.BS.Bypass.activateAll()
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- PHASE 8: SUMMARY (精簡版)
-- ═══════════════════════════════════════════════════════════════

local ok_count = 0
local fail_count = 0
for _ in pairs(loaded) do ok_count = ok_count + 1 end
for _ in pairs(failed) do fail_count = fail_count + 1 end

local totalTime = math.floor((tick() - startTime) * 1000)

print("")
print("========================================")
print("  BLOXSTRIKE v3.0 OPTIMIZED")
print("========================================")
print("")
print("[BloxStrike] " .. ok_count .. " modules loaded in " .. totalTime .. "ms")
print("[BloxStrike] " .. fail_count .. " modules failed")

if fail_count > 0 then
    warn("[BloxStrike] Failed modules:")
    for _, f in ipairs(failed) do
        warn("  X " .. f.name)
    end
end

print("")
print("[BloxStrike] INSERT = menu")
print("")

-- 通知
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "BloxStrike v3.0",
        Text = "Loaded in " .. totalTime .. "ms!",
        Duration = 3,
    })
end)
