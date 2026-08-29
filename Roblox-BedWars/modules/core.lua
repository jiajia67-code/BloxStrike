--!nocheck
-- ═══════════════════════════════════════════════════════════════
-- BEDWARS CORE MODULE (CatVape-style)
-- Services, Config, Performance, Utils
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local lplr = Players.LocalPlayer

-- ═══ Mobile Detection ═══
local isMobile = false
local isTablet = false
pcall(function()
    isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end)
pcall(function()
    local viewport = workspace.CurrentCamera.ViewportSize
    if viewport.X >= 768 or viewport.Y >= 1024 then
        isTablet = true
    end
end)

-- ═══ Shared State ═══
local BW = {
    LocalPlayer = lplr,
    Camera = workspace.CurrentCamera,
    Workspace = workspace,
    Players = Players,
    RunService = RunService,
    UserInputService = UserInputService,
    TweenService = TweenService,
    Lighting = Lighting,
    ReplicatedStorage = ReplicatedStorage,
    StarterGui = StarterGui,
    Flags = {},
    Connections = {},
    ESP_BBs = {},
    Config = {},
    WebhookURL = "",
    isMobile = isMobile,
    isTablet = isTablet,
    deviceType = isMobile and "Mobile" or "PC",
    screenScale = 1,
}

-- Auto screen scale for mobile
pcall(function()
    local viewport = workspace.CurrentCamera.ViewportSize
    if isMobile then
        BW.screenScale = math.clamp(viewport.X / 414, 0.7, 1.3)
    end
end)
print("[Core] Device: " .. BW.deviceType .. " | Scale: " .. BW.screenScale)

-- ═══ Performance Cache ═══
local Perf = {
    Cache = {},
    CacheTime = {},
    FPS = 60,
    LastFrame = tick(),
    FrameCount = 0,
}

function Perf:GetDescendants(interval)
    interval = interval or 2
    local key = "all"
    local now = tick()
    if not self.Cache[key] or (now - (self.CacheTime[key] or 0)) > interval then
        self.Cache[key] = workspace:GetDescendants()
        self.CacheTime[key] = now
    end
    return self.Cache[key]
end

function Perf:Throttle(name, interval, func)
    local now = tick()
    if not self.CacheTime["throttle_" .. name] or (now - (self.CacheTime["throttle_" .. name] or 0)) > interval then
        self.CacheTime["throttle_" .. name] = now
        func()
    end
end

function Perf:GetMemory()
    return math.floor(game:GetService("Stats").LuaHeapExtensionUsage or 0)
end

function Perf:CleanupCache()
    local now = tick()
    for key, time in pairs(self.CacheTime) do
        if now - time > 30 then
            self.Cache[key] = nil
            self.CacheTime[key] = nil
        end
    end
end

BW.Perf = Perf

-- ═══ Utility Functions ═══
function BW.alive()
    local char = lplr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return hum and hrp and hum.Health > 0
end

function BW.hrp()
    local char = lplr.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

function BW.hum()
    local char = lplr.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

function BW.char()
    return lplr.Character
end

function BW.enemies()
    local enemies = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= lplr then
            local char = player.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local isEnemy = true
                    if BW.Flags.TeamCheck and lplr.Team and player.Team == lplr.Team then
                        isEnemy = false
                    end
                    if isEnemy then
                        table.insert(enemies, {Player = player, Char = char, HRP = hrp, Hum = hum})
                    end
                end
            end
        end
    end
    return enemies
end

function BW.nearestEnemy(maxDist)
    maxDist = maxDist or math.huge
    local myHRP = BW.hrp()
    if not myHRP then return nil, math.huge end
    local nearest, nearDist = nil, maxDist
    for _, e in pairs(BW.enemies()) do
        local dist = (myHRP.Position - e.HRP.Position).Magnitude
        if dist < nearDist then
            nearest, nearDist = e, dist
        end
    end
    return nearest, nearDist
end

function BW.hasLineOfSight(pos1, pos2)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {lplr.Character}
    local result = workspace:Raycast(pos1, (pos2 - pos1), params)
    return result == nil
end

function BW.tool()
    local char = lplr.Character
    return char and char:FindFirstChildWhichIsA("Tool", true)
end

function BW.equipTool(name)
    local char = lplr.Character
    if not char then return false end
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find(name:lower()) then
            if not tool.Parent:IsA("Humanoid") then
                tool.Parent = char
            end
            return true
        end
    end
    return false
end

function BW.findTool(name)
    local char = lplr.Character
    if not char then return nil end
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find(name:lower()) then
            return tool
        end
    end
    return nil
end

function BW.getInventory()
    return {iron = 0, gold = 0, diamond = 0, emerald = 0, blocks = 0}, 0
end

function BW.buyItem(itemType)
    pcall(function()
        local Client = require(ReplicatedStorage.TS.remotes).default.Client
        Client:GetNamespace("Shop"):Get("PurchaseItem"):SendToServer({
            shopItem = {itemType = itemType, shopId = "main"}
        })
    end)
end

function BW.placeBlock(blockType, position)
    pcall(function()
        local Client = require(ReplicatedStorage.TS.remotes).default.Client
        Client:GetNamespace("Block"):Get("PlaceBlock"):SendToServer({
            blockType = blockType,
            position = position,
            normal = Vector3.new(0, 1, 0)
        })
    end)
end

function BW.SendWebhook(title, desc, color)
    -- Placeholder
end

function BW.SaveConfig()
    -- Placeholder
end

function BW.LoadConfig()
    -- Placeholder
end

-- ═══ Auto Cleanup ═══
task.spawn(function()
    while task.wait(30) do
        Perf:CleanupCache()
        pcall(collectgarbage, "collect")
    end
end)

-- ═══ FPS Counter ═══
RunService.RenderStepped:Connect(function()
    Perf.FrameCount = Perf.FrameCount + 1
    if tick() - Perf.LastFrame >= 1 then
        Perf.FPS = Perf.FrameCount
        Perf.FrameCount = 0
        Perf.LastFrame = tick()
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- PING TRACKER + ADAPTIVE TIMING SYSTEM
-- All features auto-adjust delays based on current ping
-- ═══════════════════════════════════════════════════════════════

local Ping = {
    Current = 0,       -- Current ping in ms
    Average = 0,       -- Rolling average
    Min = 9999,        -- Minimum observed
    Max = 0,           -- Maximum observed
    Jitter = 0,        -- Ping variance
    History = {},      -- Last 20 samples
    LastUpdate = 0,
    Quality = "Good",  -- Good/Fair/Poor/Terrible
}

-- Ping quality thresholds
local PING_THRESHOLDS = {
    Good = 50,       -- < 50ms
    Fair = 100,      -- 50-100ms
    Poor = 200,      -- 100-200ms
    Terrible = 500,  -- > 200ms
}

-- Update ping from Stats service
local function updatePing()
    pcall(function()
        local stats = game:GetService("Stats")
        local pingVal = stats.Network.ServerStatsItem["Data Ping"].Value
        Ping.Current = math.floor(pingVal)

        -- Rolling history (last 20 samples)
        table.insert(Ping.History, pingVal)
        if #Ping.History > 20 then table.remove(Ping.History, 1) end

        -- Calculate average
        local sum = 0
        for _, v in ipairs(Ping.History) do sum = sum + v end
        Ping.Average = math.floor(sum / #Ping.History)

        -- Min/Max
        Ping.Min = math.min(Ping.Min, pingVal)
        Ping.Max = math.max(Ping.Max, pingVal)

        -- Jitter (variance)
        local sumSq = 0
        for _, v in ipairs(Ping.History) do
            sumSq = sumSq + (v - Ping.Average) ^ 2
        end
        Ping.Jitter = math.floor(math.sqrt(sumSq / #Ping.History))

        -- Quality rating
        if Ping.Average < PING_THRESHOLDS.Good then
            Ping.Quality = "Good"
        elseif Ping.Average < PING_THRESHOLDS.Fair then
            Ping.Quality = "Fair"
        elseif Ping.Average < PING_THRESHOLDS.Poor then
            Ping.Quality = "Poor"
        else
            Ping.Quality = "Terrible"
        end

        Ping.LastUpdate = tick()
    end)
end

-- Update ping every 0.5s
task.spawn(function()
    while task.wait(0.5) do
        updatePing()
    end
end)

-- ═══ Adaptive Delay Calculator ═══
-- Returns a delay adjusted for current ping
-- baseDelay: ideal delay at 0ms ping
-- Returns: adjusted delay in seconds
function BW.pingDelay(baseDelay)
    local pingFactor = Ping.Current / 1000  -- Convert ms to seconds
    return math.max(baseDelay + pingFactor * 0.5, baseDelay * 0.8)
end

-- Returns a CPS adjusted for current ping
function BW.pingCPS(baseCPS)
    local pingFactor = math.max(0, (Ping.Current - 50) / 100)
    return math.max(1, math.floor(baseCPS * (1 - pingFactor * 0.3)))
end

-- Returns a range adjusted for current ping
function BW.pingRange(baseRange)
    local pingFactor = Ping.Current / 1000
    return baseRange + pingFactor * 2
end

-- Returns a smoothness value adjusted for current ping
function BW.pingSmooth(baseSmooth)
    local pingFactor = Ping.Current / 200
    return math.max(1, math.floor(baseSmooth * (1 + pingFactor)))
end

-- Returns predict time adjusted for current ping
function BW.pingPredict(basePredict)
    local pingFactor = Ping.Current / 1000
    return basePredict + pingFactor * 0.15
end

-- Returns true if we should skip this tick (ping too high for operation)
function BW.pingSkip(minQuality)
    local qualityOrder = {Good = 1, Fair = 2, Poor = 3, Terrible = 4}
    local minOrder = qualityOrder[minQuality or "Poor"] or 3
    local currentOrder = qualityOrder[Ping.Quality] or 4
    return currentOrder > minOrder
end

-- Returns optimal attack interval based on ping
function BW.pingAttackInterval()
    if Ping.Current < 30 then return 0.05        -- <30ms: very fast
    elseif Ping.Current < 60 then return 0.08     -- 30-60ms: fast
    elseif Ping.Current < 100 then return 0.12    -- 60-100ms: normal
    elseif Ping.Current < 200 then return 0.18    -- 100-200ms: cautious
    else return 0.25 end                           -- 200ms+: safe mode
end

-- Returns optimal click interval based on ping
function BW.pingClickInterval(baseCPS)
    local adjusted = BW.pingCPS(baseCPS or 14)
    return 1 / adjusted
end

-- Expose ping data
BW.Ping = Ping

print("[Core] Ping Tracker initialized (" .. Ping.Quality .. ")")

return BW
