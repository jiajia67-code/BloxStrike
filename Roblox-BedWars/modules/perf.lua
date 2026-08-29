--!nocheck
-- ══════════════════════════════════════════════════════════════
-- PERFORMANCE CACHE MODULE v5.1
-- Reduces lag by caching expensive operations and merging loops
-- ══════════════════════════════════════════════════════════════

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local lplr = Players.LocalPlayer

local Perf = {}

-- ═══ Service Cache (never call GetService twice) ═══
Perf.Services = {
    RunService = RunService,
    Players = Players,
    Workspace = workspace,
    UserInputService = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService"),
    Lighting = game:GetService("Lighting"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CollectionService = game:GetService("CollectionService"),
    TeleportService = game:GetService("TeleportService"),
    HttpService = game:GetService("HttpService"),
}

-- ═══ Frame Cache (updated every frame) ═══
Perf.Frame = {
    Camera = workspace.CurrentCamera,
    ViewportSize = Vector2.new(0, 0),
    DeltaTime = 0,
    FrameCount = 0,
}

-- Update frame cache every frame
RunService.RenderStepped:Connect(function(dt)
    Perf.Frame.Camera = workspace.CurrentCamera
    Perf.Frame.ViewportSize = Perf.Frame.Camera.ViewportSize
    Perf.Frame.DeltaTime = dt
    Perf.Frame.FrameCount = Perf.Frame.FrameCount + 1
end)

-- ═══ Entity Cache (updated every 0.5s instead of every frame) ═══
Perf.Entities = {
    Players = {},
    Enemies = {},
    LocalPlayer = nil,
    Character = nil,
    HRP = nil,
    Humanoid = nil,
    LastUpdate = 0,
}

-- Update entity cache every 0.5s
task.spawn(function()
    while true do
        Perf.Entities.LocalPlayer = lplr
        Perf.Entities.Character = lplr.Character
        Perf.Entities.HRP = Perf.Entities.Character and Perf.Entities.Character:FindFirstChild("HumanoidRootPart")
        Perf.Entities.Humanoid = Perf.Entities.Character and Perf.Entities.Character:FindFirstChildOfClass("Humanoid")

        local enemies = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= lplr and p.Character then
                local h = p.Character:FindFirstChild("HumanoidRootPart")
                local hu = p.Character:FindFirstChildOfClass("Humanoid")
                if h and hu and hu.Health > 0 then
                    table.insert(enemies, {Player = p, HRP = h, Char = p.Character, Hum = hu})
                end
            end
        end
        Perf.Entities.Enemies = enemies
        Perf.Entities.LastUpdate = tick()
        task.wait(0.5)
    end
end)

-- ═══ Throttle (skip frames for expensive operations) ═══
Perf.ThrottleTimers = {}
function Perf.Throttle(name, interval, func)
    local now = tick()
    if not Perf.ThrottleTimers[name] or now - Perf.ThrottleTimers[name] >= interval then
        Perf.ThrottleTimers[name] = now
        func()
    end
end

-- ═══ Throttle with frame budget (don't exceed X ms per frame) ═══
Perf.FrameBudget = 0.005 -- 5ms per frame max
Perf.FrameTimeUsed = 0
RunService.Heartbeat:Connect(function()
    Perf.FrameTimeUsed = 0
end)

function Perf.BudgetThrottle(name, interval, func)
    local now = tick()
    if not Perf.ThrottleTimers[name] or now - Perf.ThrottleTimers[name] >= interval then
        if Perf.FrameTimeUsed < Perf.FrameBudget then
            Perf.ThrottleTimers[name] = now
            local startTime = tick()
            func()
            Perf.FrameTimeUsed = Perf.FrameTimeUsed + (tick() - startTime)
        end
    end
end

-- ═══ Object Cache (cache expensive lookups) ═══
Perf.ObjectCache = {}
Perf.CacheExpiry = {}

function Perf.GetCached(name, func, expiry)
    local now = tick()
    if not Perf.ObjectCache[name] or now - (Perf.CacheExpiry[name] or 0) >= (expiry or 1) then
        Perf.ObjectCache[name] = func()
        Perf.CacheExpiry[name] = now
    end
    return Perf.ObjectCache[name]
end

function Perf.ClearCache(name)
    if name then
        Perf.ObjectCache[name] = nil
        Perf.CacheExpiry[name] = nil
    else
        Perf.ObjectCache = {}
        Perf.CacheExpiry = {}
    end
end

-- ═══ Reduced GetDescendants (cache results) ═══
Perf.DescendantCache = {}
Perf.DescendantCacheTime = {}

function Perf.GetDescendantsCached(parent, expiry)
    local key = tostring(parent)
    local now = tick()
    if not Perf.DescendantCache[key] or now - (Perf.DescendantCacheTime[key] or 0) >= (expiry or 2) then
        Perf.DescendantCache[key] = parent:GetDescendants()
        Perf.DescendantCacheTime[key] = now
    end
    return Perf.DescendantCache[key]
end

-- ═══ Reduced GetChildren (cache results) ═══
Perf.ChildrenCache = {}
Perf.ChildrenCacheTime = {}

function Perf.GetChildrenCached(parent, expiry)
    local key = tostring(parent)
    local now = tick()
    if not Perf.ChildrenCache[key] or now - (Perf.ChildrenCacheTime[key] or 0) >= (expiry or 1) then
        Perf.ChildrenCache[key] = parent:GetChildren()
        Perf.ChildrenCacheTime[key] = now
    end
    return Perf.ChildrenCache[key]
end

-- ═══ Unified Loop Manager (replaces 70+ individual while loops) ═══
Perf.Loops = {
    EveryFrame = {},      -- 60 FPS
    Every01 = {},         -- 10 FPS
    Every02 = {},         -- 5 FPS
    Every05 = {},         -- 2 FPS
    Every1 = {},          -- 1 FPS
    Every2 = {},          -- 0.5 FPS
    Every5 = {},          -- 0.2 FPS
}

function Perf.AddLoop(category, name, func)
    table.insert(Perf.Loops[category], {Name = name, Func = func})
end

-- Run all loops
task.spawn(function()
    local timers = {Every01 = 0, Every02 = 0, Every05 = 0, Every1 = 0, Every2 = 0, Every5 = 0}
    local intervals = {Every01 = 0.1, Every02 = 0.2, Every05 = 0.5, Every1 = 1, Every2 = 2, Every5 = 5}

    while true do
        local dt = task.wait()

        -- Every frame
        for _, loop in pairs(Perf.Loops.EveryFrame) do
            pcall(loop.Func, dt)
        end

        -- Timed loops
        for category, interval in pairs(intervals) do
            timers[category] = timers[category] + dt
            if timers[category] >= interval then
                timers[category] = 0
                for _, loop in pairs(Perf.Loops[category]) do
                    pcall(loop.Func, dt)
                end
            end
        end
    end
end)

-- ═══ Statistics ═══
Perf.Stats = {
    CallsPerFrame = 0,
    TotalCalls = 0,
    LastReport = 0,
}

function Perf.Report()
    local now = tick()
    if now - Perf.Stats.LastReport >= 5 then
        print(string.format("[Perf] Calls: %d/s, Entities: %d, Cache: %d",
            Perf.Stats.CallsPerFrame,
            #Perf.Entities.Enemies,
            #Perf.ObjectCache + #Perf.DescendantCache + #Perf.ChildrenCache))
        Perf.Stats.CallsPerFrame = 0
        Perf.Stats.LastReport = now
    end
    Perf.Stats.TotalCalls = Perf.Stats.TotalCalls + 1
    Perf.Stats.CallsPerFrame = Perf.Stats.CallsPerFrame + 1
end

print("[Perf] Module loaded (unified loop system)")
return Perf
