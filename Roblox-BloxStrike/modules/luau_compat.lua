-- ═══════════════════════════════════════════════════════════════
-- LUAU COMPATIBILITY SHIMS
-- ═══════════════════════════════════════════════════════════════
-- Provides safe wrappers for features that may not exist.
-- Modules should use these instead of raw API calls.
--
-- Usage in other modules:
--   local compat = BS.LuauCompat
--   compat.task.spawn(fn)
--   compat.safeHttpGet(url)
--   compat.safeProperty(obj, "ClassName")
-- ═══════════════════════════════════════════════════════════════

local BS = rawget(_G, "BS") or {}
local L = BS.Luau or {}
local Compat = {}

-- ═══ Safe Task Library ═══
Compat.task = {}

Compat.task.spawn = function(fn, ...)
    if type(task) == "table" and type(task.spawn) == "function" then
        return task.spawn(fn, ...)
    else
        -- Fallback: coroutine
        local co = coroutine.create(fn)
        return coroutine.resume(co, ...)
    end
end

Compat.task.wait = function(t)
    if type(task) == "table" and type(task.wait) == "function" then
        return task.wait(t)
    else
        -- Fallback: os.clock spin
        local start = os.clock()
        repeat until os.clock() - start >= (t or 0)
        return os.clock() - start
    end
end

Compat.task.delay = function(t, fn)
    if type(task) == "table" and type(task.delay) == "function" then
        return task.delay(t, fn)
    else
        return spawn(function()
            Compat.task.wait(t)
            fn()
        end)
    end
end

Compat.task.defer = function(fn, ...)
    if type(task) == "table" and type(task.defer) == "function" then
        return task.defer(fn, ...)
    else
        return Compat.task.spawn(fn, ...)
    end
end

Compat.task.cancel = function(handle)
    if type(task) == "table" and type(task.cancel) == "function" then
        return task.cancel(handle)
    end
    -- No fallback possible
end

-- ═══ Safe HTTP ═══
Compat.safeHttpGet = function(url, silent)
    -- Try multiple HTTP methods
    local methods = {
        -- Method 1: game:HttpGet (most executors)
        function()
            return game:HttpGet(url, silent ~= false)
        end,
        -- Method 2: request function
        function()
            if type(request) == "function" then
                local resp = request({Url = url, Method = "GET"})
                return resp and resp.Body
            end
            return nil
        end,
        -- Method 3: http.request
        function()
            if type(http) == "table" and type(http.request) == "function" then
                local resp = http.request({Url = url, Method = "GET"})
                return resp and resp.Body
            end
            return nil
        end,
        -- Method 4: syn.request (Synapse)
        function()
            if type(syn) == "table" and type(syn.request) == "function" then
                local resp = syn.request({Url = url, Method = "GET"})
                return resp and resp.Body
            end
            return nil
        end,
    }
    
    for _, method in ipairs(methods) do
        local ok, result = pcall(method)
        if ok and result then return result end
    end
    return nil
end

-- ═══ Safe Service Get ═══
Compat.getService = function(serviceName)
    local ok, service = pcall(function()
        return game:GetService(serviceName)
    end)
    if ok then return service end
    
    -- Fallback: try game:FindService
    local ok2, service2 = pcall(function()
        return game:FindService(serviceName)
    end)
    if ok2 then return service2 end
    
    return nil
end

-- ═══ Safe Property Access ═══
-- Prevents "attempt to index nil" errors
Compat.safeGet = function(obj, ...)
    if obj == nil then return nil end
    local current = obj
    for _, key in ipairs({...}) do
        if current == nil then return nil end
        local t = type(current)
        if t == "table" then
            current = current[key]
        elseif t == "userdata" then
            -- Roblox Instance
            local ok, val = pcall(function() return current[key] end)
            if ok then current = val else return nil end
        else
            return nil
        end
    end
    return current
end

-- ═══ Safe Method Call ═══
Compat.safeCall = function(obj, methodName, ...)
    if obj == nil then return nil end
    local method = obj[methodName]
    if type(method) ~= "function" then return nil end
    return method(obj, ...)
end

-- ═══ Safe FindFirstChild ═══
Compat.findFirstChild = function(parent, name, className)
    if parent == nil then return nil end
    local ok, result = pcall(function()
        if className then
            return parent:FindFirstChildOfClass(className)
        else
            return parent:FindFirstChild(name)
        end
    end)
    if ok then return result end
    return nil
end

-- ═══ Safe WaitForChild ═══
Compat.waitForChild = function(parent, name, timeout)
    if parent == nil then return nil end
    local ok, result = pcall(function()
        return parent:WaitForChild(name, timeout or 5)
    end)
    if ok then return result end
    return nil
end

-- ═══ Typeof Polyfill ═══
Compat.typeof = function(val)
    if type(val) == "userdata" or type(val) == "table" then
        -- Try Roblox typeof
        if type(typeof) == "function" then
            return typeof(val)
        end
        -- Try ClassName detection
        if type(val.IsA) == "function" then
            local ok, className = pcall(function() return val.ClassName end)
            if ok and className then return className end
        end
        return type(val)
    end
    return type(val)
end

-- ═══ Safe Drawing ═══
Compat.createDrawing = function(drawingType)
    if type(Drawing) ~= "table" then return nil end
    local ok, obj = pcall(function()
        return Drawing.new(drawingType)
    end)
    if ok then return obj end
    return nil
end

Compat.getFont = function(name)
    if type(Drawing) ~= "table" then return 0 end
    if type(Drawing.Fonts) ~= "table" then return 0 end
    return Drawing.Fonts[name] or Drawing.Fonts.UI or 0
end

-- ═══ Feature Gate ═══
-- Only execute code if feature is available
Compat.ifFeature = function(featureName, fn, fallback)
    if L[featureName] then
        return fn()
    elseif fallback then
        return fallback()
    end
    return nil
end

-- ═══ Safe pcall with error context ═══
Compat.safecall = function(context, fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok then
        -- Log error with context
        if type(warn) == "function" then
            warn("[BloxStrike] " .. context .. " failed: " .. tostring(result))
        end
        return false, result
    end
    return true, result
end

-- ═══ Store in BS ═══
BS.LuauCompat = Compat

return Compat
