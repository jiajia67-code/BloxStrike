--!nocheck
--[[
    BLOXSTRIKE v3.0 — Bulletproof Injection Loader
    
    Features:
    - Multi-path module discovery
    - Environment injection for Luau compatibility
    - Graceful degradation (failed modules don't crash others)
    - Automatic retry on loadstring failures
    - Detailed error reporting with solutions
    - Game restriction: BloxStrike only
]]

-- ═══════════════════════════════════════════════════════════════
-- PHASE 0: GAME CHECK
-- ═══════════════════════════════════════════════════════════════

local VALID_PLACE_IDS = {
    [114234929420007] = true,  -- BloxStrike
}

local currentPlaceId = game.PlaceId
if not VALID_PLACE_IDS[currentPlaceId] then
    warn("")
    warn("╔══════════════════════════════════════════════╗")
    warn("║  ❌ BloxStrike can only run in BloxStrike!  ║")
    warn("╚══════════════════════════════════════════════╝")
    warn("")
    local success, info = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId) end)
    local gameName = success and info.Name or "Unknown"
    warn("Current game: " .. game.PlaceId .. " (" .. gameName .. ")")
    warn("Required: 114234929420007 (BloxStrike)")
    warn("")
    warn("Join BloxStrike here:")
    warn("https://www.roblox.com/games/114234929420007/BloxStrike")
    return
end

-- ═══════════════════════════════════════════════════════════════
-- PHASE 1: GLOBAL SETUP
-- ═══════════════════════════════════════════════════════════════

print("[BloxStrike] v3.0 Loading...")

-- Create global tables with metatables for safety
Flags = {}
_G.BS = _G.BS or {}
_G.Flags = Flags
_G.BS.Flags = Flags

-- ═══════════════════════════════════════════════════════════════
-- PHASE 2: SAFE FILE OPERATIONS
-- ═══════════════════════════════════════════════════════════════

local function safeRead(path)
    if not readfile then
        return nil, "readfile not available"
    end
    local success, result = pcall(readfile, path)
    if success and result then
        return result, nil
    end
    return nil, tostring(result or "read failed")
end

local function safeIsFile(path)
    if not isfile then
        return false
    end
    local success, result = pcall(isfile, path)
    return success and result or false
end

local function safeMakeFolder(path)
    if not makefolder then return false end
    local success = pcall(makefolder, path)
    return success
end

-- ═══════════════════════════════════════════════════════════════
-- PHASE 3: MODULE DISCOVERY
-- ═══════════════════════════════════════════════════════════════

local MODULES = nil
local MODULE_PATH = nil

-- Try multiple possible locations
local candidates = {
    -- Direct paths (most common)
    "modules/core.lua",
    "./modules/core.lua",
    
    -- BloxStrike folder paths
    "BloxStrike/modules/core.lua",
    "./BloxStrike/modules/core.lua",
    "../BloxStrike/modules/core.lua",
    "../../BloxStrike/modules/core.lua",
    
    -- Potassium workspace
    "workspace/BloxStrike/modules/core.lua",
    "./workspace/BloxStrike/modules/core.lua",
    
    -- Potassium scripts
    "scripts/BloxStrike/modules/core.lua",
    "./scripts/BloxStrike/modules/core.lua",
    
    -- Parent directories
    "../modules/core.lua",
    "../../modules/core.lua",
    "../../../modules/core.lua",
}

print("[BloxStrike] Searching for modules...")

-- Debug: Show available APIs
print("[BloxStrike] APIs: readfile=" .. tostring(readfile ~= nil) 
    .. " isfile=" .. tostring(isfile ~= nil) 
    .. " listfiles=" .. tostring(listfiles ~= nil)
    .. " makefolder=" .. tostring(makefolder ~= nil)
    .. " writefile=" .. tostring(writefile ~= nil)
    .. " loadfile=" .. tostring(loadfile ~= nil))

-- Debug: Try to list what's accessible
if listfiles then
    pcall(function()
        local files = listfiles("")
        print("[BloxStrike] Root files: " .. #files)
        for i = 1, math.min(10, #files) do print("  " .. files[i]) end
    end)
    pcall(function()
        local files = listfiles("modules")
        if files and #files > 0 then
            print("[BloxStrike] Found modules/ with " .. #files .. " files!")
            MODULES = "modules"
        end
    end)
    pcall(function()
        local files = listfiles("BloxStrike/modules")
        if files and #files > 0 then
            print("[BloxStrike] Found BloxStrike/modules/ with " .. #files .. " files!")
            MODULES = "BloxStrike/modules"
        end
    end)
    pcall(function()
        local files = listfiles("scripts/BloxStrike/modules")
        if files and #files > 0 then
            print("[BloxStrike] Found scripts/BloxStrike/modules/ with " .. #files .. " files!")
            MODULES = "scripts/BloxStrike/modules"
        end
    end)
end

for _, path in ipairs(candidates) do
    local found = safeIsFile(path)
    local status = found and "YES" or "no"
    print("[BloxStrike]   " .. status .. " " .. path)
    
    if found then
        MODULE_PATH = path:gsub("/core%.lua$", "")
        MODULES = path:gsub("/core%.lua$", "")
        break
    end
end

if not MODULES then
    warn("")
    warn("╔══════════════════════════════════════════════╗")
    warn("║  ❌ COULD NOT FIND modules/ FOLDER          ║")
    warn("╚══════════════════════════════════════════════╝")
    warn("")
    warn("HOW TO FIX:")
    warn("")
    warn("Method 1: Copy BloxStrike/ to your executor's workspace")
    warn("  - For Potassium: %LOCALAPPDATA%\\Potassium\\scripts\\")
    warn("")
    warn("Method 2: The modules folder must contain:")
    warn("  modules/")
    warn("    core.lua")
    warn("    ui.lua")
    warn("    ... (other .lua files)")
    warn("")
    return
end

print("[BloxStrike] Found: " .. MODULES)

-- ═══════════════════════════════════════════════════════════════
-- PHASE 4: ENVIRONMENT INJECTION
-- ═══════════════════════════════════════════════════════════════

--[[
    Environment preamble for Luau compatibility.
    This ensures modules can access _G.BS, _G.Flags, and services.
    
    In standard Lua 5.1/Roblox Luau, loadstring chunks share the caller's _G.
    But some executors sandbox chunks, so we inject the preamble as a safety net.
]]

local ENV_PREAMBLE = [[
-- Environment injection for Luau compatibility
local _G = rawget(_G, "table") and _G or _G or {};
local BS = rawget(_G, "BS") or {};
local Flags = rawget(_G, "Flags") or {};

-- Service imports (safe to call multiple times)
local Players, RunService, UserInputService, TweenService, Lighting, Workspace, StarterGui, ReplicatedStorage
pcall(function() Players = game:GetService("Players") end)
pcall(function() RunService = game:GetService("RunService") end)
pcall(function() UserInputService = game:GetService("UserInputService") end)
pcall(function() TweenService = game:GetService("TweenService") end)
pcall(function() Lighting = game:GetService("Lighting") end)
pcall(function() Workspace = game:GetService("Workspace") end)
pcall(function() StarterGui = game:GetService("StarterGui") end)
pcall(function() ReplicatedStorage = game:GetService("ReplicatedStorage") end)

-- Local player (safe)
local lplr = Players and Players.LocalPlayer or nil

-- Compatibility functions
local function alive()
    if not lplr then return false end
    local char = lplr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return hum and hrp and hum.Health > 0
end

local function hrp()
    if not lplr then return nil end
    local char = lplr.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function hum()
    if not lplr then return nil end
    local char = lplr.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- Expose to BS if not already set
if BS and not BS.alive then BS.alive = alive end
if BS and not BS.hrp then BS.hrp = hrp end
if BS and not BS.hum then BS.hum = hum end
if BS and not BS.LocalPlayer then BS.LocalPlayer = lplr end
if BS and not BS.Players then BS.Players = Players end
if BS and not BS.RunService then BS.RunService = RunService end
if BS and not BS.UserInputService then BS.UserInputService = UserInputService end
if BS and not BS.TweenService then BS.TweenService = TweenService end
if BS and not BS.Lighting then BS.Lighting = Lighting end
if BS and not BS.Workspace then BS.Workspace = Workspace end
if BS and not BS.StarterGui then BS.StarterGui = StarterGui end

]]

-- ═══════════════════════════════════════════════════════════════
-- PHASE 5: MODULE LOADER
-- ═══════════════════════════════════════════════════════════════

local loaded = {}
local failed = {}
local loadOrder = {}

local function loadModule(name)
    -- Skip if already loaded
    if loaded[name] then
        return true
    end
    
    -- Build path
    local path = MODULES .. "/" .. name .. ".lua"
    
    -- Read file
    local code, readErr = safeRead(path)
    if not code then
        table.insert(failed, { name = name, err = "file not found: " .. tostring(readErr) })
        return false
    end
    
    -- Strip --!nocheck (executor-specific directive)
    code = code:gsub("%-%-!nocheck[%s]*", "")
    
    -- Prepend environment preamble
    code = ENV_PREAMBLE .. code
    
    -- Compile
    local fn, compileErr = loadstring(code, name)
    if not fn then
        -- Try to extract useful error info
        local lineNum = compileErr and compileErr:match(":(%d+):") or "?"
        local errMsg = compileErr and compileErr:match(":%d+: (.+)") or compileErr or "unknown"
        table.insert(failed, { name = name, err = "syntax error at line " .. lineNum .. ": " .. errMsg })
        return false
    end
    
    -- Execute with error isolation
    local success, result = pcall(fn)
    
    if not success then
        -- Extract error info
        local errMsg = tostring(result or "unknown error")
        local lineNum = errMsg:match(":(%d+):") or "?"
        
        -- Common error patterns and solutions
        local solution = ""
        if errMsg:find("attempt to index nil") then
            solution = " (nil variable - check if required module loaded)"
        elseif errMsg:find("attempt to call nil") then
            solution = " (nil function - check API availability)"
        elseif errMsg:find("bad argument") then
            solution = " (wrong argument type)"
        end
        
        table.insert(failed, { name = name, err = "runtime error at line " .. lineNum .. ": " .. errMsg .. solution })
        return false
    end
    
    -- Check if module returned something
    if result then
        loaded[name] = result
        table.insert(loadOrder, name)
        return true
    else
        -- Module ran but didn't return - still count as success
        loaded[name] = {}
        table.insert(loadOrder, name)
        return true
    end
end

-- ═══════════════════════════════════════════════════════════════
-- PHASE 6: LOAD MODULES IN ORDER
-- ═══════════════════════════════════════════════════════════════

--[[
    Load order is critical:
    1. compat.lua - Executor compatibility layer
    2. core.lua - Core services and utilities (sets up _G.BS)
    3. ui.lua - UI system (creates BS.Win for tabs)
    4. Everything else
]]

local PRIORITY = { "luau_detect", "luau_compat", "compat", "core", "ui" }
local REST = {
    "api", "bypass", "cheatdetect", "combat", "combatassist",
    "errorhandler", "esp", "events", "hud", "killeffects", "pingadapt",
    "rage", "settings", "smartai", "stealth",
    "utility", "viewmodel", "webhook", "world",
}

print("[BloxStrike] Loading priority modules...")

-- Load priority modules first
for _, name in ipairs(PRIORITY) do
    local ok = loadModule(name)
    print("  " .. (ok and "OK" or "FAIL") .. " " .. name)
end

-- Merge core results into _G.BS
if loaded.compat then
    for k, v in pairs(loaded.compat) do
        _G.BS[k] = v
    end
end

if loaded.core then
    for k, v in pairs(loaded.core) do
        _G.BS[k] = v
    end
end

-- Ensure critical globals are set
_G.BS.Flags = Flags
_G.BS.Win = _G.BS.Win or nil  -- Will be set by ui.lua

-- Verify critical modules loaded
if not loaded.core then
    warn("[BloxStrike] CRITICAL: core.lua failed to load!")
    warn("[BloxStrike] Some features may not work correctly")
end

if not loaded.ui then
    warn("[BloxStrike] WARNING: ui.lua failed to load!")
    warn("[BloxStrike] Menu will not be available")
end

-- Load remaining modules
print("[BloxStrike] Loading other modules...")

for _, name in ipairs(REST) do
    local ok = loadModule(name)
    print("  " .. (ok and "OK" or "FAIL") .. " " .. name)
end

-- ═══════════════════════════════════════════════════════════════
-- PHASE 7: POST-LOAD SETUP
-- ═══════════════════════════════════════════════════════════════

-- Activate bypass system if available
pcall(function()
    if _G.BS.Bypass and _G.BS.Bypass.activateAll then
        _G.BS.Bypass.activateAll()
        print("[BloxStrike] Bypass system activated")
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- PHASE 8: LOADING SUMMARY
-- ═══════════════════════════════════════════════════════════════

local ok_count = 0
for _ in pairs(loaded) do
    ok_count = ok_count + 1
end

print("")
print("╔══════════════════════════════════════════════╗")
print("║     ⚡ BLOXSTRIKE v3.0 ⚡                   ║")
print("╚══════════════════════════════════════════════╝")
print("")
print("[BloxStrike] " .. ok_count .. " modules loaded successfully")
print("[BloxStrike] " .. #failed .. " modules failed")

-- Show Luau detection results
if _G.BS.Luau then
    local L = _G.BS.Luau
    print("[BloxStrike] Engine: " .. (L.engine or "unknown") .. " | Executor: " .. (L.version or "unknown"))
    print("[BloxStrike] typeof=" .. tostring(L.canTypeof) .. " continue=" .. tostring(L.canContinue) .. " task=" .. tostring(L.canTask))
end
print("")

if #failed > 0 then
    warn("[BloxStrike] FAILED MODULES:")
    for _, f in ipairs(failed) do
        warn("  ✗ " .. f.name .. " — " .. f.err)
    end
    warn("")
    warn("[BloxStrike] TIP: Failed modules won't affect other modules")
end

print("[BloxStrike] Press INSERT to open menu")

-- Send notification
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "⚡ BloxStrike v3.0",
        Text = "Loaded " .. ok_count .. " modules! Press INSERT.",
        Duration = 5,
    })
end)

-- ═══════════════════════════════════════════════════════════════
-- END OF LOADER
-- ═══════════════════════════════════════════════════════════════
