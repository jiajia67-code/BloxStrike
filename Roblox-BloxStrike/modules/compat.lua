

-- BLOXSTRIKE EXECUTOR COMPATIBILITY MODULE v1.0
-- Works with: Fluxus, Delta, Wave, Solara, Hydrogen, Arceus X,
-- Script-Ware, Synapse X, KRNL, Comet, Oxygen U, Evon,
-- JJSploit, Nihon, AWP.GG, Celery, Velocity, Potassium,
-- Real, ByteBreaker, Nexomia, Yub-X, Xeno, Vega X, Ronix,
-- and ALL executors with standard Lua/Roblox API
-- Supports: PC (Windows/Mac/Linux), Mobile (Android/iOS), Emulators

local Compat = {}
local HttpService = nil
pcall(function() HttpService = game:GetService("HttpService") end)
local UserInputService = nil
pcall(function() UserInputService = game:GetService("UserInputService") end)
local Players = nil
pcall(function() Players = game:GetService("Players") end)
local lplr = Players.LocalPlayer

-- SECTION 1: EXECUTOR DETECTION  

local executorName = "Unknown"
local executorVersion = "Unknown"

pcall(function()
    if identifyexecutor then
        local name, ver = identifyexecutor()
        executorName = name or "Unknown"
        executorVersion = ver or "Unknown"
    elseif getexecutorname then
        executorName = getexecutorname()
    end
end)

Compat.Executor = executorName
Compat.Version = executorVersion

-- SECTION 2: DEVICE DETECTION  

Compat.IsMobile = false
Compat.IsPC = false
Compat.IsEmulator = false
Compat.IsLandscape = true
-- Compat.ScreenSize = Vector2.new(1920, 1080)
Compat.Scale = 1
Compat.ScreenSize = Vector2.new(1920, 1080)

pcall(function()
    -- Detect mobile
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        Compat.IsMobile = true
    elseif UserInputService.TouchEnabled and UserInputService.KeyboardEnabled then
        -- Could be a 2-in-1 device or emulator
        Compat.IsEmulator = true
    end
    
    -- Detect PC
    if UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
        Compat.IsPC = true
    end
    
    -- Screen size
    Compat.ScreenSize = workspace.CurrentCamera.ViewportSize
    
    -- Scale factor for different resolutions
    local baseWidth = 1920
    Compat.Scale = Compat.ScreenSize.X / baseWidth
    if Compat.Scale < 0.5 then Compat.Scale = 0.5 end
    if Compat.Scale > 2.0 then Compat.Scale = 2.0 end
end)

-- Detect mobile executors
pcall(function()
    if identifyexecutor then
        local name = identifyexecutor()
        if name then
            name = name:lower()
            if name:find("arceus") or name:find("hydrogen") or name:find("celery") 
                or name:find("evon") or name:find("fluxus android") then
                Compat.IsMobile = true
            end
        end
    end
end)

print("[Compat] Executor: " .. executorName .. " v" .. executorVersion)
-- [optimized] print("[Compat] Device: " .. (Compat.IsMobile and "Mobile" or Compat.IsEmulator and "Emulator" or "PC"))
-- [optimized] print("[Compat] Screen: " .. Compat.ScreenSize.X .. "x" .. Compat.ScreenSize.Y .. " | Scale: " .. string.format("%.2f", Compat.Scale))

-- SECTION 3: FILESYSTEM  

Compat.ReadFile = function(path)
    local s, r = pcall(function()
        if readfile then return readfile(path) end
    end)
    return s and r or nil
end

Compat.WriteFile = function(path, content)
    local s = pcall(function()
        if writefile then writefile(path, content) end
    end)
    return s
end

Compat.AppendFile = function(path, content)
    local s = pcall(function()
        if appendfile then appendfile(path, content) end
    end)
    return s
end

Compat.IsFile = function(path)
    local s, r = pcall(function()
        if isfile then return isfile(path) end
    end)
    return s and r or false
end

Compat.MakeFolder = function(path)
    local s = pcall(function()
        if makefolder then makefolder(path) end
    end)
    return s
end

Compat.DeleteFile = function(path)
    local s = pcall(function()
        if delfile then delfile(path) end
    end)
    return s
end

Compat.ListFiles = function(path)
    local s, r = pcall(function()
        if listfiles then return listfiles(path) end
    end)
    return s and r or {}
end

-- SECTION 4: CLIPBOARD  

Compat.SetClipboard = function(text)
    pcall(function()
        if setclipboard then setclipboard(text) end
    end)
end

Compat.GetClipboard = function()
    local s, r = pcall(function()
        if getclipboard then return getclipboard() end
    end)
    return s and r or ""
end

-- SECTION 5: HTTP  

Compat.HttpRequest = function(params)
    local result = nil
    local success = false
    
    -- Try each HTTP function in order of preference
    local httpFuncs = {
        function() return syn and syn.request end,
        function() return http_request end,
        function() return request end,
        function() return HttpPostAsync end,
    }
    
    for _, getFunc in ipairs(httpFuncs) do
        local s, func = pcall(getFunc)
        if s and func then
            local rs, rr = pcall(func, params)
            if rs then
                result = rr
                success = true
                break
            end
        end
    end
    
    -- Fallback: use HttpService (limited, no custom headers)
    if not success then
        local s, r = pcall(function()
            return HttpService:RequestAsync({
                Url = params.Url,
                Method = params.Method or "GET",
                Body = params.Body,
            })
        end)
        if s then result = r; success = true end
    end
    
    return success, result
end

Compat.HttpGet = function(url)
    local s, r = pcall(function()
        if httpget then return httpget(url) end
        if game.HttpGet then return game:HttpGet(url) end
        -- Use our HttpRequest
        local ok, res = Compat.HttpRequest({Url = url, Method = "GET"})
        if ok and res then return res.Body or res end
    end)
    return s and r or nil
end

-- SECTION 6: DRAWING API   API

Compat.HasDrawing = false
pcall(function()
    if Drawing then Compat.HasDrawing = true end
end)

Compat.DrawingNew = function(class)
    if not Compat.HasDrawing then return nil end
    local s, obj = pcall(function()
        return Drawing.new(class)
    end)
    return s and obj or nil
end

Compat.DrawingFont = function(fontName)
    if not Compat.HasDrawing then return 2 end
    local s, r = pcall(function()
        if fontName == "UI" then return Drawing.Fonts.UI
        elseif fontName == "System" then return Drawing.Fonts.System
        elseif fontName == "Plex" then return Drawing.Fonts.Plex
        elseif fontName == "Monospace" then return Drawing.Fonts.Monospace
        else return Drawing.Fonts.UI end
    end)
    return s and r or 2
end

-- SECTION 7: MOUSE  

Compat.MouseMoveRel = function(x, y)
    pcall(function()
        if mousemoverel then mousemoverel(x, y) end
    end)
end

Compat.Mouse1Click = function()
    pcall(function()
        if mouse1click then mouse1click() end
    end)
end

Compat.Mouse1Press = function()
    pcall(function()
        if mouse1press then mouse1press() end
    end)
end

Compat.Mouse1Release = function()
    pcall(function()
        if mouse1release then mouse1release() end
    end)
end

Compat.Mouse2Click = function()
    pcall(function()
        if mouse2click then mouse2click() end
    end)
end

Compat.GetMouseLocation = function()
    local s, r = pcall(function()
        return UserInputService:GetMouseLocation()
    end)
    return s and r or Vector2.new(0, 0)
end

-- SECTION 8: HOOKING   Hook

Compat.HookFunction = function(old, new)
    pcall(function()
        if hookfunction then return hookfunction(old, new) end
    end)
    return old
end

Compat.HookMetamethod = function(obj, method, hook)
    local s, r = pcall(function()
        if hookmetamethod then return hookmetamethod(obj, method, hook) end
    end)
    return s and r or nil
end

Compat.GetRawMetamethod = function()
    local s, r = pcall(function()
        if getrawmetatable then return getrawmetatable(game) end
    end)
    return s and r or nil
end

Compat.NewCClosure = function(func)
    local s, r = pcall(function()
        if newcclosure then return newcclosure(func) end
    end)
    return s and r or func
end

Compat.IsLClosure = function(func)
    local s, r = pcall(function()
        if islclosure then return islclosure(func) end
    end)
    return s and r or false
end

Compat.GetNameCallMethod = function()
    local s, r = pcall(function()
        if getnamecallmethod then return getnamecallmethod() end
    end)
    return s and r or ""
end

Compat.SetReadonly = function(mt, val)
    pcall(function()
        if setreadonly then setreadonly(mt, val) end
    end)
end

Compat.IsReadonly = function(mt)
    local s, r = pcall(function()
        if isreadonly then return isreadonly(mt) end
    end)
    return s and r or false
end

Compat.CheckCaller = function()
    local s, r = pcall(function()
        if checkcaller then return checkcaller() end
    end)
    return s and r or false
end

Compat.GetEnv = function(level)
    local s, r = pcall(function()
        if getfenv then return getfenv(level or 1) end
    end)
    return s and r or nil
end

Compat.SetEnv = function(func, env)
    pcall(function()
        if setfenv then setfenv(func, env) end
    end)
end

Compat.GetGenv = function()
    local s, r = pcall(function()
        if getgenv then return getgenv() end
    end)
    return s and r or nil
end

Compat.GetRenviron = function()
    local s, r = pcall(function()
        if getrenv then return getrenv() end
    end)
    return s and r or nil
end

-- SECTION 9: CONNECTIONS  

Compat.GetConnections = function(signal)
    local s, r = pcall(function()
        if getconnections then return getconnections(signal) end
    end)
    return s and r or {}
end

Compat.FireSignal = function(signal, ...)
    local args = {...}
    pcall(function()
        if firesignal then firesignal(signal, unpack(args)) end
    end)
end

Compat.FireClickDetector = function(detector)
    pcall(function()
        if fireclickdetector then fireclickdetector(detector) end
    end)
end

Compat.FireTouchInterest = function(part, root, toggle)
    pcall(function()
        if firetouchinterest then firetouchinterest(part, root, toggle) end
    end)
end

-- SECTION 10: INSTANCE OPERATIONS  

Compat.GetInstances = function()
    local s, r = pcall(function()
        if getinstances then return getinstances() end
    end)
    return s and r or {}
end

Compat.GetNilInstances = function()
    local s, r = pcall(function()
        if getnilinstances then return getnilinstances() end
    end)
    return s and r or {}
end

Compat.GetScripts = function()
    local s, r = pcall(function()
        if getscripts then return getscripts() end
    end)
    return s and r or {}
end

Compat.GetRunningScripts = function()
    local s, r = pcall(function()
        if getrunningscripts then return getrunningscripts() end
    end)
    return s and r or {}
end

Compat.GetHiddenProperty = function(obj, prop)
    local s, r = pcall(function()
        if gethiddenproperty then return gethiddenproperty(obj, prop) end
    end)
    return s and r or nil
end

Compat.SetHiddenProperty = function(obj, prop, val)
    pcall(function()
        if sethiddenproperty then sethiddenproperty(obj, prop, val) end
    end)
end

-- SECTION 11: GC  

Compat.GetGC = function()
    local s, r = pcall(function()
        if getgc then return getgc() end
    end)
    return s and r or {}
end

Compat.CollectGarbage = function(mode)
    pcall(function()
        collectgarbage(mode or "collect")
    end)
end

-- SECTION 12: FFLAG  Roblox Flags

Compat.SetFFlag = function(flag, value)
    pcall(function()
        if setfflag then setfflag(flag, value) end
    end)
end

Compat.GetFFlag = function(flag)
    local s, r = pcall(function()
        if getfflag then return getfflag(flag) end
    end)
    return s and r or nil
end

-- SECTION 13: SCHEDULER  

Compat.GetScheduler = function()
    local s, r = pcall(function()
        if getscheduler then return getscheduler() end
    end)
    return s and r or nil
end

Compat.GetScriptClosure = function(script)
    local s, r = pcall(function()
        if getscriptclosure then return getscriptclosure(script) end
    end)
    return s and r or nil
end

-- SECTION 14: LOADING  

Compat.LoadString = function(code)
    local s, r = pcall(function()
        return loadstring(code)
    end)
    return s and r or nil
end

-- SECTION 15: MOBILE INPUT  

Compat.TouchInput = {
    Active = false,
    -- LastTouch = Vector2.new(0, 0),
    SwipeThreshold = 50,
    DoubleTapThreshold = 0.3,
    LastTapTime = 0,
}

-- Detect touch input for mobile
if Compat.IsMobile then
    pcall(function()
        UserInputService.TouchStarted:Connect(function(input, gpe)
            if gpe then return end
            Compat.TouchInput.Active = true
            Compat.TouchInput.LastTouch = input.Position
            local now = tick()
            if now - Compat.TouchInput.LastTapTime < Compat.TouchInput.DoubleTapThreshold then
                _G.BS_DoubleTap = true
            end
            Compat.TouchInput.LastTapTime = now
        end)
        UserInputService.TouchEnded:Connect(function(input, gpe)
            Compat.TouchInput.Active = false
        end)
    end)
end

-- SECTION 16: FEATURE DETECTION  

Compat.Features = {
    Drawing = Compat.HasDrawing,
    -- MouseMoveRel = (function() local s = pcall(function() return mousemoverel ~= nil end); return s end)(),
    -- Mouse1Click = (function() local s = pcall(function() return mouse1click ~= nil end); return s end)(),
    -- HookFunction = (function() local s = pcall(function() return hookfunction ~= nil end); return s end)(),
    -- HookMetamethod = (function() local s = pcall(function() return hookmetamethod ~= nil end); return s end)(),
    -- GetRawMetatable = (function() local s = pcall(function() return getrawmetatable ~= nil end); return s end)(),
    -- NewCClosure = (function() local s = pcall(function() return newcclosure ~= nil end); return s end)(),
    -- IsLClosure = (function() local s = pcall(function() return islclosure ~= nil end); return s end)(),
    -- GetNameCallMethod = (function() local s = pcall(function() return getnamecallmethod ~= nil end); return s end)(),
    -- CheckCaller = (function() local s = pcall(function() return checkcaller ~= nil end); return s end)(),
    -- GetGenv = (function() local s = pcall(function() return getgenv ~= nil end); return s end)(),
    -- SetReadonly = (function() local s = pcall(function() return setreadonly ~= nil end); return s end)(),
    -- GetConnections = (function() local s = pcall(function() return getconnections ~= nil end); return s end)(),
    -- FireSignal = (function() local s = pcall(function() return firesignal ~= nil end); return s end)(),
    -- GetInstances = (function() local s = pcall(function() return getinstances ~= nil end); return s end)(),
    -- GetScripts = (function() local s = pcall(function() return getscripts ~= nil end); return s end)(),
    ReadFile = (function() local s = pcall(function() return readfile ~= nil end); return s end)(),
    -- WriteFile = (function() local s = pcall(function() return writefile ~= nil end); return s end)(),
    -- IsFile = (function() local s = pcall(function() return isfile ~= nil end); return s end)(),
    -- SetClipboard = (function() local s = pcall(function() return setclipboard ~= nil end); return s end)(),
    -- GetClipboard = (function() local s = pcall(function() return getclipboard ~= nil end); return s end)(),
    -- HttpRequest = (function() local s = pcall(function() return (syn and syn.request) or http_request or request end); return s end)(),
    -- SetFFlag = (function() local s = pcall(function() return setfflag ~= nil end); return s end)(),
    -- GetGC = (function() local s = pcall(function() return getgc ~= nil end); return s end)(),
    -- LoadString = (function() local s = pcall(function() return loadstring ~= nil end); return s end)(),
}

-- SECTION 17: PRINTER  

function Compat.PrintReport()
    -- [optimized] print("[Compat]  Executor Compatibility Report ")
    print("[Compat] Executor: " .. executorName .. " v" .. executorVersion)
    -- [optimized] print("[Compat] Device: " .. (Compat.IsMobile and " Mobile" or Compat.IsEmulator and " Emulator" or " PC"))
    -- [optimized] print("[Compat] Screen: " .. Compat.ScreenSize.X .. "x" .. Compat.ScreenSize.Y)
    -- [optimized] print("[Compat] Scale: " .. string.format("%.2f", Compat.Scale))
    -- [optimized] print("[Compat]  Available Features ")
    
    local available = 0
    local total = 0
    for name, has in pairs(Compat.Features) do
        total = total + 1
        if has then available = available + 1 end
    end
    
    -- [optimized] print("[Compat] APIs: " .. available .. "/" .. total .. " available")
    
    -- Print missing features
    local missing = {}
    for name, has in pairs(Compat.Features) do
        if not has then
            table.insert(missing, name)
        end
    end
    if #missing > 0 then
        -- [optimized] print("[Compat] Missing: " .. table.concat(missing, ", "))
        -- [optimized] print("[Compat] Features using missing APIs will be disabled or use fallbacks")
    else
        -- [optimized] print("[Compat]  All APIs available  Full functionality")
    end
    -- [optimized] print("[Compat] ")
end

 -- Expose
BS.Compat = Compat

-- Auto-print report on load
task.delay(1, function()
    -- Compat.PrintReport()
end)

print("[Compat] BloxStrike Compatibility Module loaded")
-- [optimized] print("[Compat] Supports: All executors + PC + Mobile + Emulators")

return Compat