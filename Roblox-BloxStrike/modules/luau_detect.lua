-- ═══════════════════════════════════════════════════════════════
-- BLOXSTRIKE LUAU VERSION DETECTOR & COMPATIBILITY LAYER
-- ═══════════════════════════════════════════════════════════════
-- Auto-detects Luau version and provides polyfills for
-- features that may not exist in older executors.
--
-- Capability flags (available after load):
--   BS.Luau.canContinue    - continue statement available
--   BS.Luau.canTypeof      - typeof() function available
--   BS.Luau.canTask        - task library available
--   BS.Luau.canBuffer      - buffer library available
--   BS.Luau.canNative      - @native annotation supported
--   BS.Luau.canFenv        - getfenv/setfenv available
--   BS.Luau.canDebug       - debug library available
--   BS.Luau.canBit         - bit library available
--   BS.Luau.canHttp        - http requests available
--   BS.Luau.canDrawing     - Drawing library available
--   BS.Luau.canSyn         - Synapse/Xeno APIs available
--   BS.Luau.canKRNL        - KRNL APIs available
--   BS.Luau.canFluxus      - Fluxus APIs available
--   BS.Luau.canPotassium   - Potassium APIs available
--   BS.Luau.canEggscord    - Eggscord APIs available
--   BS.Luau.canOxygen      - Oxygen U APIs available
--   BS.Luau.version        - detected version string
--   BS.Luau.engine         - "luau" | "lua51" | "luau-old" | "unknown"
-- ═══════════════════════════════════════════════════════════════

local BS = rawget(_G, "BS") or {}
local Luau = {}

-- ═══ PHASE 1: Core Language Feature Detection ═══

-- Test: typeof() - Luau-specific function
do
    local ok, result = pcall(function() return typeof(game) end)
    Luau.canTypeof = ok and result ~= nil
end

-- Test: continue statement
-- We test by attempting to compile a function with continue
do
    local ok = pcall(function()
        return loadstring("local t = {1,2,3}\nfor _,v in ipairs(t) do if v == 2 then continue end end")
    end)
    -- loadstring might return nil for syntax error, or a function
    if ok then
        local fn = loadstring("local x = 0\nfor i = 1, 10 do if i == 5 then continue end x = x + 1 end return x")
        if fn then
            local ok2, result = pcall(fn)
            Luau.canContinue = ok2 and result == 9  -- 9 because 5 is skipped
        else
            Luau.canContinue = false
        end
    else
        Luau.canContinue = false
    end
end

-- Test: goto statement
do
    local fn = loadstring("::label:: local x = 1 goto label")
    Luau.canGoto = fn ~= nil
end

-- Test: task library (Roblox)
Luau.canTask = type(task) == "table" and type(task.spawn) == "function"

-- Test: buffer library (very new Luau)
Luau.canBuffer = type(buffer) == "table"

-- Test: @native annotation
-- Can't really test at runtime, but we can guess based on other features
Luau.canNative = Luau.canBuffer  -- if buffer exists, @native likely works

-- Test: getfenv/setfenv (Lua 5.1)
Luau.canFenv = type(getfenv) == "function" and type(setfenv) == "function"

-- Test: debug library
Luau.canDebug = type(debug) == "table"

-- Test: bit library (Lua 5.1 / Luau)
Luau.canBit = type(bit) == "table" or type(bit32) == "table"

-- Test: http requests
Luau.canHttp = (type(game) == "table" and pcall(function() return game.HttpGet ~= nil end))
    or (type(http) == "table" and type(http.request) == "function")
    or (type(request) == "function")
    or (type(HttpGet) == "function")

-- Test: Drawing library (exploit-specific)
Luau.canDrawing = type(Drawing) == "table"

-- ═══ PHASE 2: Executor Detection ═══

-- Test: Potassium
Luau.canPotassium = false
do
    local ok = pcall(function()
        -- Potassium-specific APIs
        return type(readfile) == "function"
            and type(writefile) == "function"
            and type(isfile) == "function"
            and type(loadfile) == "function"
    end)
    if ok then
        -- Additional check: Potassium uses loadfile differently
        local ok2 = pcall(function()
            return type(listfiles) == "function"
        end)
        Luau.canPotassium = true  -- readfile/writefile/isfile exist
    end
end

-- Test: Synapse X / Synapse Z
Luau.canSyn = false
do
    local syn_apis = {
        "syn", "syn_request", "syn_protect_gui", "syn_unprotect_gui",
        "syn_getgc", "getinstances", "getnilinstances", "getscripts",
        "getthreadidentity", "setthreadidentity"
    }
    for _, api in ipairs(syn_apis) do
        if type(rawget(_G, api)) ~= "nil" then
            Luau.canSyn = true
            break
        end
    end
end

-- Test: KRNL
Luau.canKRNL = false
do
    local krnl_apis = {"krnl_loaded", "KRNL_LOADED", "identifyexecutor"}
    for _, api in ipairs(krnl_apis) do
        if type(rawget(_G, api)) ~= "nil" then
            Luau.canKRNL = true
            break
        end
    end
end

-- Test: Fluxus
Luau.canFluxus = false
do
    local ok = pcall(function()
        return type(fluxus) == "table" or type(Fluxus) == "table"
    end)
    Luau.canFluxus = ok
end

-- Test: Eggscord
Luau.canEggscord = false
do
    local ok = pcall(function()
        return type(eggscord) ~= "nil" or type(Eggscord) ~= "nil"
    end)
    Luau.canEggscord = ok
end

-- Test: Oxygen U
Luau.canOxygen = false
do
    local ok = pcall(function()
        return type(OXYGEN_LOADED) ~= "nil" or type(oxygen) ~= "nil"
    end)
    Luau.canOxygen = ok
end

-- Test: Wave
Luau.canWave = false
do
    local ok = pcall(function()
        return type(WaveEnvironment) ~= "nil" or type(wave) ~= "nil"
    end)
    Luau.canWave = ok
end

-- Test: Arceus X
Luau.canArceusX = false
do
    local ok = pcall(function()
        return type(arceusx) ~= "nil" or type(getexecutorname) == "function"
    end)
    if ok and type(getexecutorname) == "function" then
        local name = pcall(function() return getexecutorname() end)
        if name and type(name) == "string" and name:lower():find("arceus") then
            Luau.canArceusX = true
        end
    end
end

-- ═══ PHASE 3: Engine Classification ═══

-- Detect engine type based on capabilities
if Luau.canTask and Luau.canTypeof and not Luau.canFenv then
    Luau.engine = "luau"           -- Modern Roblox Luau
elseif Luau.canFenv and not Luau.canTypeof then
    Luau.engine = "lua51"          -- Lua 5.1 (old executor)
elseif Luau.canFenv and Luau.canTypeof then
    Luau.engine = "luau-hybrid"    -- Mixed (some executors)
else
    Luau.engine = "unknown"
end

-- Version string
if Luau.canPotassium then
    Luau.version = "Potassium"
elseif Luau.canSyn then
    Luau.version = "Synapse"
elseif Luau.canKRNL then
    Luau.version = "KRNL"
elseif Luau.canFluxus then
    Luau.version = "Fluxus"
elseif Luau.canEggscord then
    Luau.version = "Eggscord"
elseif Luau.canOxygen then
    Luau.version = "Oxygen U"
elseif Luau.canWave then
    Luau.version = "Wave"
elseif Luau.canArceusX then
    Luau.version = "Arceus X"
else
    Luau.version = "Unknown"
end

-- ═══ PHASE 4: Polyfills ═══

-- Polyfill: typeof() for Lua 5.1 executors
if not Luau.canTypeof then
    local _typeof = function(val)
        local t = type(val)
        if t == "userdata" or t == "table" then
            -- Try metatable-based type detection
            local mt = getmetatable(val)
            if mt and mt.__index then
                -- Check for Roblox classes
                if type(val.IsA) == "function" then
                    local ok, className = pcall(function() return val.ClassName end)
                    if ok and className then return className end
                end
            end
            return t
        end
        return t
    end
    -- Don't overwrite if already exists
    if not rawget(_G, "typeof") then
        rawset(_G, "typeof", _typeof)
    end
end

-- Polyfill: task library for old executors
if not Luau.canTask then
    local taskPolyfill = {
        spawn = function(fn, ...)
            return coroutine.wrap(fn)(...)
        end,
        wait = function(t)
            local start = tick()
            repeat until tick() - start >= (t or 0)
            return tick() - start
        end,
        delay = function(t, fn)
            return coroutine.wrap(function()
                task.wait(t)
                fn()
            end)()
        end,
        defer = function(fn, ...)
            return coroutine.wrap(fn)(...)
        end,
        delay = function(t, fn)
            spawn(function()
                wait(t)
                fn()
            end)
        end,
    }
    rawset(_G, "task", taskPolyfill)
end

-- Polyfill: table.clone for old executors
if not table.clone then
    table.clone = function(t)
        local copy = {}
        for k, v in pairs(t) do
            copy[k] = v
        end
        return setmetatable(copy, getmetatable(t))
    end
end

-- Polyfill: buffer library (stub)
if not Luau.canBuffer then
    rawset(_G, "buffer", {
        create = function(size) return {} end,
        fromstring = function(str) return {data = str} end,
        tostring = function(buf) return buf.data or "" end,
        readu8 = function(buf, offset) return 0 end,
        writeu8 = function(buf, offset, value) end,
        length = function(buf) return 0 end,
    })
end

-- ═══ PHASE 5: Safe Execution Helpers ═══

-- Safe require: tries multiple paths
Luau.safeRequire = function(modulePath)
    local paths = {
        modulePath,
        modulePath:gsub("%.", "/"),
        "modules/" .. modulePath:gsub("%.", "/"),
        "BloxStrike/modules/" .. modulePath:gsub("%.", "/"),
    }
    for _, path in ipairs(paths) do
        local ok, result = pcall(require, path)
        if ok and result then return result end
    end
    return nil
end

-- Safe property access: prevents nil index errors
Luau.safeGet = function(obj, ...)
    if obj == nil then return nil end
    local current = obj
    for _, key in ipairs({...}) do
        if current == nil then return nil end
        current = current[key]

    return current


-- Safe method call: prevents nil index on method calls
Luau.safeCall = function(obj, methodName, ...)
    if obj == nil then return nil end
    local method = obj[methodName]
    if type(method) ~= "function" then return nil end
    return method(obj, ...)


-- Feature gate: only run code if feature is available
Luau.ifFeature = function(featureName, fn, fallback)
    if Luau[featureName] then
        return fn()
    elseif fallback then
        return fallback()

    return nil


-- ═══ PHASE 6: Print Diagnostics ═══

local function printDiagnostics()
    print("[Luau Detector] Engine: " .. Luau.engine)
    print("[Luau Detector] Executor: " .. Luau.version)
    print("[Luau Detector] Capabilities:")
    print("  typeof=" .. tostring(Luau.canTypeof)
        .. " continue=" .. tostring(Luau.canContinue)
        .. " goto=" .. tostring(Luau.canGoto)
        .. " task=" .. tostring(Luau.canTask))
    print("  buffer=" .. tostring(Luau.canBuffer)
        .. " fenv=" .. tostring(Luau.canFenv)
        .. " debug=" .. tostring(Luau.canDebug)
        .. " drawing=" .. tostring(Luau.canDrawing))
    print("  http=" .. tostring(Luau.canHttp)
        .. " bit=" .. tostring(Luau.canBit))


-- Run diagnostics
pcall(printDiagnostics)

-- ═══ Store in BS ═══
BS.Luau = Luau

return Luau
