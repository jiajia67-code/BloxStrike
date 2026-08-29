

-- BLOXSTRIKE CORE MODULE v1.0
-- Services, Config, Performance, Utils for CS2-style FPS

local Players = nil

pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local UserInputService = nil
pcall(function() UserInputService = game:GetService("UserInputService") end)
local TweenService = nil
pcall(function() TweenService = game:GetService("TweenService") end)
local Lighting = nil
pcall(function() Lighting = game:GetService("Lighting") end)
local ReplicatedStorage = nil
pcall(function() ReplicatedStorage = game:GetService("ReplicatedStorage") end)
local StarterGui = nil
pcall(function() StarterGui = game:GetService("StarterGui") end)
local Workspace = nil
pcall(function() Workspace = game:GetService("Workspace") end)
local lplr = Players.LocalPlayer

 -- Mobile Detection
local isMobile = false
pcall(function()
    isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end)

 -- Shared State
local BS = {
    LocalPlayer = lplr,
    Camera = workspace.CurrentCamera, -- Legacy reference, prefer workspace.CurrentCamera
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
    Config = {},
    isMobile = isMobile,
    screenScale = 1,
}

print("[Core] BloxStrike Core initialized")

 -- Performance Cache
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

function Perf:CleanupCache()
    local now = tick()
    for key, time in pairs(self.CacheTime) do
        if now - time > 30 then
            self.Cache[key] = nil
            self.CacheTime[key] = nil
        end
    end
end

BS.Perf = Perf

 -- Utility Functions
function BS.alive()
    local char = lplr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return hum and hrp and hum.Health > 0
end

function BS.hrp()
    local char = lplr.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

function BS.hum()
    local char = lplr.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

function BS.char()
    return lplr.Character
end

function BS.head()
    local char = lplr.Character
    return char and char:FindFirstChild("Head")
end

function BS.cam()
    return workspace.CurrentCamera
end

function BS.team()
    return lplr.Team
end

function BS.enemies()
    local enemies = {}
    local myTeam = BS.team()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= lplr then
            local char = player.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChildOfClass("Humanoid")
                local head = char:FindFirstChild("Head")
                if hrp and hum and hum.Health > 0 then
                    local isEnemy = true
                    -- Team check
                    if BS.Flags.TeamCheck and myTeam and player.Team == myTeam then
                        isEnemy = false
                    end
                    -- Friend check
                    if BS.Flags.FriendCheck and lplr:IsFriendsWith(player.UserId) then
                        isEnemy = false
                    end
                    if isEnemy then
                        table.insert(enemies, {
                            Player = player,
                            Char = char,
                            HRP = hrp,
                            Hum = hum,
                            Head = head
                        })
                    end
                end
            end
        end
    end
    return enemies
end

function BS.nearestEnemy(maxDist)
    maxDist = maxDist or math.huge
    local myHRP = BS.hrp()
    if not myHRP then return nil, math.huge end
    local nearest, nearDist = nil, maxDist
    for _, e in pairs(BS.enemies()) do
        local dist = (myHRP.Position - e.HRP.Position).Magnitude
        if dist < nearDist then
            nearest, nearDist = e, dist
        end
    end
    return nearest, nearDist
end

function BS.bestEnemy(maxDist, fov)
    -- Best enemy: closest to crosshair AND within FOV
    maxDist = maxDist or math.huge
    fov = fov or 180
    local myHRP = BS.hrp()
    if not myHRP then return nil, math.huge end
    local cam = workspace.CurrentCamera
    local mouse = UserInputService:GetMouseLocation()
    local best, bestScore = nil, fov
    for _, e in pairs(BS.enemies()) do
        local dist = (myHRP.Position - e.HRP.Position).Magnitude
        if dist <= maxDist then
            local pos, vis = cam:WorldToViewportPoint(e.Head and e.Head.Position or e.HRP.Position)
            if vis then
                local screenDist = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                if screenDist < bestScore then
                    best, bestScore = e, screenDist
                end
            end
        end
    end
    return best, bestScore
end

function BS.hasLineOfSight(pos1, pos2)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {lplr.Character}
    local result = workspace:Raycast(pos1, (pos2 - pos1), params)
    return result == nil
end

function BS.tool()
    local char = lplr.Character
    return char and char:FindFirstChildWhichIsA("Tool", true)
end

function BS.equipTool(name)
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
    -- Check backpack
    local bp = lplr:FindFirstChild("Backpack")
    if bp then
        for _, tool in pairs(bp:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:lower():find(name:lower()) then
                tool.Parent = char
                return true
            end
        end
    end
    return false
end

function BS.findTool(name)
    local char = lplr.Character
    if not char then return nil end
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find(name:lower()) then
            return tool
        end
    end
    local bp = lplr:FindFirstChild("Backpack")
    if bp then
        for _, tool in pairs(bp:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:lower():find(name:lower()) then
                return tool
            end
        end
    end
    return nil
end

function BS.weaponType()
    local tool = BS.tool()
    if not tool then return "none" end
    local name = tool.Name:lower()
    -- CS2-style weapon categories
    if name:find("ak") or name:find("m4") or name:find("rifle") or name:find("ar") then return "rifle" end
    if name:find("awp") or name:find("scout") or name:find("sniper") then return "sniper" end
    if name:find("deagle") or name:find("pistol") or name:find("glock") or name:find("usps") or name:find("usp") then return "pistol" end
    if name:find("shotgun") or name:find("nova") or name:find("xm10") then return "shotgun" end
    if name:find("smg") or name:find("mp") or name:find("mac") or name:find("ump") then return "smg" end
    if name:find("knife") or name:find("bayonet") then return "knife" end
    if name:find("grenade") or name:find("flash") or name:find("smoke") or name:find("molotov") or name:find("he") then return "grenade" end
    if name:find("defuse") or name:find("kit") then return "defuse" end
    if name:find("c4") or name:find("bomb") then return "bomb" end
    return "other"
end

 -- Aim Utilities
function BS.getBonePosition(character, boneName)
    local bone = character:FindFirstChild(boneName)
    if bone then return bone.Position end
    -- Fallback to HumanoidRootPart
    local hrp = character:FindFirstChild("HumanoidRootPart")
    return hrp and hrp.Position or nil
end

function BS.getAimPosition(target, bone)
    bone = bone or "Head"
    if bone == "Head" then
        return BS.getBonePosition(target.Char, "頭部") or target.HRP.Position + Vector3.new(0, 1.5, 0)
    elseif bone == "Chest" then
        return target.HRP.Position + Vector3.new(0, 0.5, 0)
    elseif bone == "Pelvis" then
        return target.HRP.Position
    elseif bone == "Nearest" then
        local headPos = BS.getBonePosition(target.Char, "頭部") or target.HRP.Position + Vector3.new(0, 1.5, 0)
        return headPos
    end
    return target.HRP.Position
end

function BS.getVelocity(target)
    return target.HRP.AssemblyLinearVelocity
end

function BS.predictPosition(target, time)
    local pos = BS.getAimPosition(target)
    local vel = BS.getVelocity(target)
    return pos + vel * time
end

 -- Weapon Stats
local WEAPON_STATS = {
    rifle = { fireRate = 0.1, damage = 30, recoil = 1.5, spread = 0.02 },
    sniper = { fireRate = 1.5, damage = 100, recoil = 3.0, spread = 0.001 },
    pistol = { fireRate = 0.3, damage = 40, recoil = 0.8, spread = 0.015 },
    shotgun = { fireRate = 0.8, damage = 80, recoil = 2.0, spread = 0.1 },
    smg = { fireRate = 0.07, damage = 20, recoil = 0.6, spread = 0.03 },
    knife = { fireRate = 0.4, damage = 40, recoil = 0, spread = 0 },
}

function BS.getWeaponStats()
    local wtype = BS.weaponType()
    return WEAPON_STATS[wtype] or { fireRate = 0.1, damage = 25, recoil = 1.0, spread = 0.02 }
end

 -- Auto Cleanup
task.spawn(function()
    while task.wait(30) do
        -- Perf:CleanupCache()
        pcall(collectgarbage, "collect")
    end
end)

 -- Camera Update on Respawn
lplr.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    BS.Camera = workspace.CurrentCamera
end)

 -- FPS Counter
RunService.RenderStepped:Connect(function()
    Perf.FrameCount = Perf.FrameCount + 1
    if tick() - Perf.LastFrame >= 1 then
        Perf.FPS = Perf.FrameCount
        Perf.FrameCount = 0
        Perf.LastFrame = tick()
    end
end)

 -- Ping Tracker
local Ping = {
    Current = 0,
    Average = 0,
    History = {},
    Quality = "Good",
}

local function updatePing()
    pcall(function()
        local stats = nil
        pcall(function() stats = game:GetService("Stats") end)
        local pingVal = 0
            pcall(function() pingVal = stats.Network.ServerStatsItem["Data Ping"].Value end)
        Ping.Current = math.floor(pingVal)
        table.insert(Ping.History, pingVal)
        if #Ping.History > 20 then table.remove(Ping.History, 1) end
        local sum = 0
        for _, v in ipairs(Ping.History) do sum = sum + v end
        Ping.Average = math.floor(sum / #Ping.History)
        if Ping.Average < 50 then
            Ping.Quality = "Good"
        elseif Ping.Average < 100 then
            Ping.Quality = "Fair"
        elseif Ping.Average < 200 then
            Ping.Quality = "Poor"
        else
            Ping.Quality = "Terrible"
        end
    end)
end

task.spawn(function()
    while task.wait(0.5) do updatePing() end
end)

function BS.pingDelay(baseDelay)
    local pingFactor = Ping.Current / 1000
    return math.max(baseDelay + pingFactor * 0.5, baseDelay * 0.8)
end

function BS.pingAttackInterval()
    if Ping.Current < 30 then return 0.05
    elseif Ping.Current < 60 then return 0.08
    elseif Ping.Current < 100 then return 0.12
    elseif Ping.Current < 200 then return 0.18
    else return 0.25 end
end

-- Ensure Ping has safe defaults
Ping.Current = Ping.Current or 0
Ping.Average = Ping.Average or 0

BS.Ping = Ping

print("[Core] BloxStrike Core ready | Ping: " .. Ping.Quality)

return BS
