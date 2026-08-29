--[[
    BLOXSTRIKE v3.0 — OPTIMIZED Injection Loader
    Speed optimized version
]]

-- ═══════════════════════════════════════════════════════════════
-- PHASE 0: GAME CHECK
-- ═══════════════════════════════════════════════════════════════

if game.PlaceId ~= 114234929420007 then
    warn("[BloxStrike] Wrong game! Please join BloxStrike game.")
    warn("PlaceId required: 114234929420007")
    return
end

-- ═══════════════════════════════════════════════════════════════
-- PHASE 1: GLOBAL SETUP
-- ═══════════════════════════════════════════════════════════════

Flags = {}
_G.BS = _G.BS or {}
_G.Flags = Flags
_G.BS.Flags = Flags

local startTime = tick()

-- ═══════════════════════════════════════════════════════════════
-- PHASE 2: MODULE DISCOVERY
-- ═══════════════════════════════════════════════════════════════

local MODULES = nil
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
    warn("[BloxStrike] modules/ not found!")
    return
end

-- ═══════════════════════════════════════════════════════════════
-- PHASE 3: ENVIRONMENT PREAMBLE
-- ═══════════════════════════════════════════════════════════════

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
local function cam()return workspace and workspace.CurrentCamera or nil end
local function backpack()return lplr and lplr.Backpack or nil end
local function playerGui()return lplr and lplr.PlayerGui or nil end
if BS and not BS.alive then BS.alive=alive end;if BS and not BS.hrp then BS.hrp=hrp end;if BS and not BS.hum then BS.hum=hum end
if BS and not BS.LocalPlayer then BS.LocalPlayer=lplr end;if BS and not BS.Players then BS.Players=Players end
if BS and not BS.RunService then BS.RunService=RunService end;if BS and not BS.UserInputService then BS.UserInputService=UserInputService end
if BS and not BS.TweenService then BS.TweenService=TweenService end;if BS and not BS.Lighting then BS.Lighting=Lighting end
if BS and not BS.Workspace then BS.Workspace=Workspace end;if BS and not BS.StarterGui then BS.StarterGui=StarterGui end
if BS and not BS.Camera then BS.Camera=cam end;if BS and not BS.Backpack then BS.Backpack=backpack end;if BS and not BS.PlayerGui then BS.PlayerGui=playerGui end
]]

-- ═══════════════════════════════════════════════════════════════
-- PHASE 4: MODULE LOADER
-- ═══════════════════════════════════════════════════════════════

local loaded = {}
local failedNames = {}
local loadTimes = {}

local function loadModule(name)
    if loaded[name] then return true end

    local path = MODULES .. "/" .. name .. ".lua"
    local t0 = tick()

    local ok, code = pcall(readfile, path)
    if not ok or not code then
        table.insert(failedNames, name)
        return false
    end

    code = code:gsub("%-%-!nocheck[%s]*", "")
    code = ENV_PREAMBLE .. code

    local fn, err = loadstring(code, "[string \"" .. name .. "\"]")
    if not fn then
        warn("[BloxStrike] Compile error in " .. name .. ": " .. tostring(err))
        table.insert(failedNames, name)
        return false
    end

    local ok2, result = pcall(fn)
    if not ok2 then
        warn("[BloxStrike] Runtime error in " .. name .. ": " .. tostring(result))
        table.insert(failedNames, name)
        return false
    end

    loaded[name] = result or true
    loadTimes[name] = math.floor((tick() - t0) * 1000)
    return true
end

-- ═══════════════════════════════════════════════════════════════
-- PHASE 5: SEQUENTIAL LOADING (reliable, no race conditions)
-- ═══════════════════════════════════════════════════════════════

-- Priority order: compat -> core -> ui -> api -> rest
local loadOrder = {
    "compat", "core", "ui", "api",
    "bypass", "cheatdetect", "combat", "combatassist",
    "errorhandler", "esp", "events", "hud",
    "killeffects", "pingadapt", "rage", "settings",
    "smartai", "stealth", "utility", "viewmodel",
    "webhook", "world",
}

-- Phase A: Load priority modules first
local priority = {"compat", "core", "ui"}
for _, name in ipairs(priority) do
    loadModule(name)
end

-- Merge priority return values into _G.BS
if loaded.compat then
    for k, v in pairs(loaded.compat) do
        if type(v) ~= "userdata" then
            _G.BS[k] = v
        end
    end
end
if loaded.core then
    for k, v in pairs(loaded.core) do
        if type(v) ~= "userdata" then
            _G.BS[k] = v
        end
    end
end
_G.BS.Flags = Flags

-- Phase B: Load remaining modules
for _, name in ipairs(loadOrder) do
    if not loaded[name] then
        loadModule(name)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- PHASE 6: POST-LOAD
-- ═══════════════════════════════════════════════════════════════

pcall(function()
    if _G.BS.Bypass and _G.BS.Bypass.activateAll then
        _G.BS.Bypass.activateAll()
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- PHASE 7: SUMMARY
-- ═══════════════════════════════════════════════════════════════

local ok_count = 0
for _ in pairs(loaded) do ok_count = ok_count + 1 end

local totalTime = math.floor((tick() - startTime) * 1000)

print("")
print("========================================")
print("  BLOXSTRIKE v3.0 OPTIMIZED")
print("========================================")
print("")
print("[BloxStrike] " .. ok_count .. " modules loaded in " .. totalTime .. "ms")

if #failedNames > 0 then
    warn("[BloxStrike] " .. #failedNames .. " modules failed:")
    for _, f in ipairs(failedNames) do
        warn("  X " .. f)
    end
end

print("")
print("[BloxStrike] INSERT = menu")
print("")

-- Show keybind hints
if loaded.combat or loaded.rage or loaded.esp then
    print("[BloxStrike] Keybinds: INSERT=Menu  X=ESP  Z=Bhop  C=AA  V=SA  N=Night  M=NoScope")
end

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "BloxStrike v3.0",
        Text = ok_count .. " modules loaded in " .. totalTime .. "ms!",
        Duration = 3,
    })
end)
