--!nocheck
-- ══════════════════════════════════════════════════════════════
-- EXECUTOR COMPATIBILITY MODULE v5.1
-- Works with: Fluxus, Delta, Wave, Solara, Hydrogen, Arceus X,
-- Script-Ware, Synapse X, KRNL, Comet, Electron, Oxygen U,
-- Evon, JJSploit, Nihon, AWP.GG, Celery, Velocity, Potassium,
-- Real, ByteBreaker, Nexomia, Yub-X, and more
-- ══════════════════════════════════════════════════════════════

local Compat = {}

-- ═══ 1. Executor Detection ═══
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
Compat.IsMobile = false

-- Detect mobile executors
pcall(function()
    if identifyexecutor then
        local name = identifyexecutor()
        if name then
            name = name:lower()
            if name:find("arceus") or name:find("hydrogen") or name:find("celery") or name:find("evon") then
                Compat.IsMobile = true
            end
        end
    end
end)

print("[Compat] Executor: " .. executorName .. " v" .. executorVersion)

-- ═══ 2. Safe Function Wrappers ═══
-- These wrap common executor functions with fallbacks

-- Filesystem
Compat readFile = function(path)
    if readfile then return readfile(path) end
    return nil
end

Compat writeFile = function(path, content)
    if writefile then writefile(path, content); return true end
    return false
end

Compat.appendFile = function(path, content)
    if appendfile then appendfile(path, content); return true end
    return false
end

Compat.isFile = function(path)
    if isfile then return isfile(path) end
    return false
end

Compat.listFiles = function(path)
    if listfiles then return listfiles(path) end
    return {}
end

Compat.makeFolder = function(path)
    if makefolder then makefolder(path); return true end
    return false
end

Compat.deleteFile = function(path)
    if delfile then delfile(path); return true end
    return false
end

-- Hooking
Compat.hookFunction = function(old, new)
    if hookfunction then return hookfunction(old, new) end
    return old
end

Compat.hookMetamethod = function(obj, method, hook)
    if hookmetamethod then
        return hookmetamethod(obj, method, hook)
    end
    return nil
end

Compat.getRawMetamethod = function(obj, method)
    if getrawmetamethod then
        return getrawmetamethod(obj, method)
    end
    return nil
end

-- Drawing API
Compat.hasDrawing = (Drawing ~= nil)
Compat.drawTriangle = function(points, color, filled, thickness)
    if not Compat.hasDrawing then return nil end
    local success, triangle = pcall(function()
        local t = Drawing.new("Triangle")
        t.PointA = points[1]
        t.PointB = points[2]
        t.PointC = points[3]
        t.Color = color or Color3.fromRGB(255, 255, 255)
        t.Filled = filled or false
        t.Thickness = thickness or 1
        t.Visible = true
        return t
    end)
    return success and triangle or nil
end

Compat.drawLine = function(from, to, color, thickness)
    if not Compat.hasDrawing then return nil end
    local success, line = pcall(function()
        local l = Drawing.new("Line")
        l.From = from
        l.To = to
        l.Color = color or Color3.fromRGB(255, 255, 255)
        l.Thickness = thickness or 1
        l.Visible = true
        return l
    end)
    return success and line or nil
end

Compat.drawCircle = function(position, radius, color, thickness, filled)
    if not Compat.hasDrawing then return nil end
    local success, circle = pcall(function()
        local c = Drawing.new("Circle")
        c.Position = position
        c.Radius = radius or 50
        c.Color = color or Color3.fromRGB(255, 255, 255)
        c.Thickness = thickness or 1
        c.Filled = filled or false
        c.Visible = true
        return c
    end)
    return success and circle or nil
end

Compat.drawSquare = function(position, size, color, filled, thickness)
    if not Compat.hasDrawing then return nil end
    local success, square = pcall(function()
        local s = Drawing.new("Square")
        s.Position = position
        s.Size = size
        s.Color = color or Color3.fromRGB(255, 255, 255)
        s.Filled = filled or false
        s.Thickness = thickness or 1
        s.Visible = true
        return s
    end)
    return success and square or nil
end

Compat.drawText = function(position, text, color, size, font)
    if not Compat.hasDrawing then return nil end
    local success, textObj = pcall(function()
        local t = Drawing.new("Text")
        t.Position = position
        t.Text = text or ""
        t.Color = color or Color3.fromRGB(255, 255, 255)
        t.Size = size or 14
        t.Font = font or 2
        t.Visible = true
        return t
    end)
    return success and textObj or nil
end

-- Mouse/Keyboard Simulation
Compat.mouseMove = function(x, y)
    if mousemoveabs then mousemoveabs(x, y); return true end
    return false
end

Compat.mouseMoveRel = function(x, y)
    if mousemoverel then mousemoverel(x, y); return true end
    return false
end

Compat.mouse1Click = function()
    if mouse1click then mouse1click(); return true end
    return false
end

Compat.mouse1Press = function()
    if mouse1press then mouse1press(); return true end
    return false
end

Compat.mouse1Release = function()
    if mouse1release then mouse1release(); return true end
    return false
end

Compat.mouse2Click = function()
    if mouse2click then mouse2click(); return true end
    return false
end

Compat.keyPress = function(key)
    if keypress then keypress(key); return true end
    return false
end

Compat.keyRelease = function(key)
    if keyrelease then keyrelease(key); return true end
    return false
end

Compat.keyClick = function(key)
    if keyclick then keyclick(key); return true end
    return false
end

-- Instance Access
Compat.getInstances = function()
    if getinstances then return getinstances() end
    return game:GetDescendants()
end

Compat.getNilInstances = function()
    if getnilinstances then return getnilinstances() end
    return {}
end

Compat.getScripts = function()
    if getscripts then return getscripts() end
    return {}
end

Compat.getConnections = function(event)
    if getconnections then return getconnections(event) end
    return {}
end

-- Identity
Compat.setIdentity = function(level)
    if setidentity then setidentity(level); return true end
    if setidentitylevel then setidentitylevel(level); return true end
    return false
end

Compat.getIdentity = function()
    if getidentity then return getidentity() end
    if getidentitylevel then return getidentitylevel() end
    return 0
end

-- FPS
Compat.setFpsCap = function(fps)
    if setfpscap then setfpscap(fps); return true end
    return false
end

-- Teleport
Compat.queueOnTeleport = function(code)
    if queue_on_teleport then queue_on_teleport(code); return true end
    return false
end

-- Clipboard
Compat.setClipboard = function(text)
    if setclipboard then setclipboard(text); return true end
    return false
end

Compat.getClipboard = function()
    if getclipboard then return getclipboard() end
    return ""
end

-- HTTP
Compat.httpGet = function(url)
    if game and game.HttpGet then
        local success, result = pcall(function() return game:HttpGet(url, true) end)
        if success then return result end
    end
    if httpget then
        local success, result = pcall(function() return httpget(url) end)
        if success then return result end
    end
    return nil
end

Compat.request = function(params)
    if request then
        local success, result = pcall(function() return request(params) end)
        if success then return result end
    end
    return nil
end

-- Closure
Compat.newCClosure = function(func)
    if newcclosure then return newcclosure(func) end
    return func
end

Compat.isCClosure = function(func)
    if iscclosure then return iscclosure(func) end
    return false
end

Compat.isLClosure = function(func)
    if islclosure then return islclosure(func) end
    return false
end

Compat.compareClosures = function(a, b)
    if compareclosures then return compareclosures(a, b) end
    return a == b
end

-- Misc
Compat.getNameCallMethod = function()
    if getnamecallmethod then return getnamecallmethod() end
    return ""
end

Compat.getCallingScript = function()
    if getcallingscript then return getcallingscript() end
    return nil
end

Compat.isSynapse = function()
    return executorName:lower():find("synapse") ~= nil
end

Compat.isFluxus = function()
    return executorName:lower():find("fluxus") ~= nil
end

Compat.isDelta = function()
    return executorName:lower():find("delta") ~= nil
end

Compat.isSolara = function()
    return executorName:lower():find("solara") ~= nil
end

Compat.isWave = function()
    return executorName:lower():find("wave") ~= nil
end

Compat.isHydrogen = function()
    return executorName:lower():find("hydrogen") ~= nil
end

Compat.isArceus = function()
    return executorName:lower():find("arceus") ~= nil
end

Compat.isKRNL = function()
    return executorName:lower():find("krnl") ~= nil
end

Compat.isVelocity = function()
    return executorName:lower():find("velocity") ~= nil
end

Compat.isPotassium = function()
    return executorName:lower():find("potassium") ~= nil
end

-- ═══ 3. Service Compatibility ═══
-- Use cloneref if available, fallback to game:GetService
local function safeService(name)
    local success, service = pcall(function()
        if cloneref then
            return cloneref(game:GetService(name))
        end
        return game:GetService(name)
    end)
    return success and service or nil
end

Compat.Services = {
    Players = safeService("Players"),
    RunService = safeService("RunService"),
    UserInputService = safeService("UserInputService"),
    TweenService = safeService("TweenService"),
    Lighting = safeService("Lighting"),
    ReplicatedStorage = safeService("ReplicatedStorage"),
    CollectionService = safeService("CollectionService"),
    TeleportService = safeService("TeleportService"),
    HttpService = safeService("HttpService"),
    MarketplaceService = safeService("MarketplaceService"),
    StarterGui = safeService("StarterGui"),
    Workspace = workspace,
}

-- ═══ 4. Feature Detection ═══
Compat.Features = {
    Drawing = Compat.hasDrawing,
    HookFunction = (hookfunction ~= nil),
    HookMetamethod = (hookmetamethod ~= nil),
    GetRawMetamethod = (getrawmetamethod ~= nil),
    MouseMove = (mousemoveabs ~= nil),
    MouseMoveRel = (mousemoverel ~= nil),
    Mouse1Click = (mouse1click ~= nil),
    KeyPress = (keypress ~= nil),
    GetInstances = (getinstances ~= nil),
    GetConnections = (getconnections ~= nil),
    SetIdentity = (setidentity ~= nil),
    SetFpsCap = (setfpscap ~= nil),
    QueueOnTeleport = (queue_on_teleport ~= nil),
    ReadFile = (readfile ~= nil),
    WriteFile = (writefile ~= nil),
    IsFile = (isfile ~= nil),
    HTTP = (game and game.HttpGet ~= nil),
    NewCClosure = (newcclosure ~= nil),
    CloneRef = (cloneref ~= nil),
}

-- Print supported features
local featureCount = 0
for _, v in pairs(Compat.Features) do if v then featureCount = featureCount + 1 end end
print("[Compat] Features: " .. featureCount .. "/" .. 20 .. " supported")

-- ═══ 5. Universal UNC Test ═══
Compat.UNC = {}
Compat.UNC Score = 0

local uncTests = {
    {"hookfunction", function() return hookfunction ~= nil end},
    {"readfile", function() return readfile ~= nil end},
    {"writefile", function() return writefile ~= nil end},
    {"isfile", function() return isfile ~= nil end},
    {"Drawing", function() return Drawing ~= nil end},
    {"mousemoverel", function() return mousemoverel ~= nil end},
    {"getrawmetamethod", function() return getrawmetamethod ~= nil end},
    {"getconnections", function() return getconnections ~= nil end},
    {"getinstances", function() return getinstances ~= nil end},
    {"setidentity", function() return setidentity ~= nil end},
    {"setfpscap", function() return setfpscap ~= nil end},
    {"queue_on_teleport", function() return queue_on_teleport ~= nil end},
    {"newcclosure", function() return newcclosure ~= nil end},
    {"cloneref", function() return cloneref ~= nil end},
    {"request", function() return request ~= nil end},
    {"setclipboard", function() return setclipboard ~= nil end},
    {"getscripts", function() return getscripts ~= nil end},
    {"getnilinstances", function() return getnilinstances ~= nil end},
    {"hookmetamethod", function() return hookmetamethod ~= nil end},
    {"keypress", function() return keypress ~= nil end},
}

local passed = 0
for _, test in pairs(uncTests) do
    local success, result = pcall(test[2])
    if success and result then
        passed = passed + 1
        Compat.UNC[test[1]] = true
    else
        Compat.UNC[test[1]] = false
    end
end
Compat.UNC.Score = math.floor((passed / #uncTests) * 100)
print("[Compat] UNC Score: " .. Compat.UNC.Score .. "% (" .. passed .. "/" .. #uncTests .. ")")

return Compat
