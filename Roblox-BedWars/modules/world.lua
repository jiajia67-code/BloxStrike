--!nocheck
-- ═══════════════════════════════════════════════════════════════
-- BEDWARS WORLD MODULE v6.0 — Faster Auto Farm + Pathfinding
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lplr = Players.LocalPlayer

local function alive()
    local c = lplr.Character
    return c and c:FindFirstChildOfClass("Humanoid") and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChildOfClass("Humanoid").Health > 0
end
local function hrp() return lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart") end
local function hum() return lplr.Character and lplr.Character:FindFirstChildOfClass("Humanoid") end
local function enemies()
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lplr and p.Character then
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            local r = p.Character:FindFirstChild("HumanoidRootPart")
            if h and r and h.Health > 0 then table.insert(t, {Player = p, HRP = r, Hum = h, Char = p.Character}) end
        end
    end
    return t
end
local function nearestEnemy(maxD)
    maxD = maxD or math.huge
    local my = hrp()
    if not my then return nil, math.huge end
    local best, bd = nil, maxD
    for _, e in pairs(enemies()) do
        local d = (my.Position - e.HRP.Position).Magnitude
        if d < bd then best, bd = e, d end
    end
    return best, bd
end

local function fireRemote(name, ...)
    local args = {...}
    pcall(function()
        local Client = require(ReplicatedStorage.TS.remotes).default.Client
        for _, ns in pairs({"Bedwars", "Block", "Shop", "Inventory"}) do
            pcall(function()
                local r = Client:GetNamespace(ns):Get(name)
                if r then r:SendToServer(unpack(args)) end
            end)
        end
    end)
end

local function invokeRemote(name, ...)
    local args = {...}
    pcall(function()
        local Client = require(ReplicatedStorage.TS.remotes).default.Client
        pcall(function()
            local r = Client:Get(name)
            if r then r:CallServer(unpack(args)) end
        end)
        for _, ns in pairs({"Bedwars", "Block", "Shop", "Inventory"}) do
            pcall(function()
                local r = Client:GetNamespace(ns):Get(name)
                if r then r:CallServer(unpack(args)) end
            end)
        end
    end)
end

local page = BW.Win:Tab("World")
if not page or not page.Toggle then warn("[World] Failed to create tab!") return end

-- ═══ 1. Scaffold ═══
page:Toggle("Scaffold", false, function(v) Flags.Scaffold = v end)
page:Toggle("Scaffold Extend", false, function(v) Flags.ScaffoldExtend = v end)

-- ═══ 2. Bed Protect ═══
page:Toggle("Bed Protect", false, function(v) Flags.BedProtect = v end)

-- ═══ 3. Auto Collect ═══
page:Toggle("Auto Collect", false, function(v) Flags.AutoCollect = v end)

-- ═══ 4. Nuker ═══
page:Toggle("Nuker", false, function(v) Flags.Nuker = v end)
page:Slider("Nuker Range", 1, 10, 5, function(v) Flags.NukerRange = v end)

-- ═══ 5. Auto Break Bed ═══
page:Toggle("Auto Break Bed", false, function(v) Flags.AutoBreakBed = v end)
page:Slider("Bed Range", 1, 10, 5, function(v) Flags.BedRange = v end)
page:Toggle("Bed Rush", false, function(v) Flags.BedRush = v end)

-- ═══ 6. Chest Steal ═══
page:Toggle("Chest Steal", false, function(v) Flags.ChestSteal = v end)

-- ═══ 7. Safe Walk ═══
page:Toggle("Safe Walk", false, function(v) Flags.SafeWalk = v end)

-- ═══ 8. Xray ═══
page:Toggle("Xray", false, function(v) Flags.Xray = v end)

-- ═══ 9. Auto Builder ═══
page:Toggle("Auto Builder", false, function(v) Flags.AutoBuilder = v end)

-- ═══ 10. Fast Break ═══
page:Toggle("Fast Break", false, function(v) Flags.FastBreak = v end)

-- ═══ 11. Bridge Assist ═══
page:Toggle("Bridge Assist", false, function(v) Flags.BridgeAssist = v end)

-- ═══ 12. Auto Heal ═══
page:Toggle("Auto Heal", false, function(v) Flags.AutoHeal = v end)

-- ═══ 13. Auto Pearl ═══
page:Toggle("Auto Pearl", false, function(v) Flags.AutoPearl = v end)

-- ═══ 14. Fullbright ═══
page:Toggle("Fullbright", false, function(v) Flags.Fullbright = v end)
task.spawn(function()
    while true do
        if Flags.Fullbright then
            pcall(function()
                game:GetService("Lighting").Brightness = 2
                game:GetService("Lighting").ClockTime = 14
                game:GetService("Lighting").OutdoorAmbient = Color3.fromRGB(200, 200, 200)
                game:GetService("Lighting").GlobalShadows = false
            end)
        end
        task.wait(1)
    end
end)

-- ═══ 15. No Fog ═══
page:Toggle("No Fog", false, function(v) Flags.NoFog = v end)
task.spawn(function()
    while true do
        if Flags.NoFog then
            pcall(function()
                game:GetService("Lighting").FogEnd = 1000000
                game:GetService("Lighting").FogStart = 0
                for _, v in pairs(game:GetService("Lighting"):GetDescendants()) do
                    if v:IsA("Atmosphere") then v.Density = 0 end
                end
            end)
        end
        task.wait(2)
    end
end)

-- ═══ 16. Auto Trap ═══
page:Toggle("Auto Trap", false, function(v) Flags.AutoTrap = v end)

-- ═══ 17. Auto Void ═══
page:Toggle("Auto Void", false, function(v) Flags.AutoVoid = v end)

-- ═══ 18. Bed Aura ═══
page:Toggle("Bed Aura", false, function(v) Flags.BedAura = v end)

-- ═══ 19. No Clip ═══
page:Toggle("No Clip", false, function(v) Flags.NoClip = v end)

-- ═══ 20. Speed Bridge ═══
page:Toggle("Speed Bridge", false, function(v) Flags.SpeedBridge = v end)

-- ═══ 21. Auto Upgrade ═══
page:Toggle("Auto Upgrade", false, function(v) Flags.AutoUpgrade = v end)

-- ═══ 22. Auto Team ═══
page:Toggle("Auto Team", false, function(v) Flags.AutoTeam = v end)

-- ═══ 23. Auto Shop ═══
page:Toggle("Auto Shop", false, function(v) Flags.AutoShop = v end)


-- ═══ 25. Jump Boost ═══
page:Toggle("Jump Boost", false, function(v) Flags.JumpBoost = v end)

-- ═══ 26. AUTO FARM v2 (Fast + Smart) ═══
page:Toggle("Auto Farm", false, function(v) Flags.AutoFarm = v end)
page:Slider("Farm Radius", 10, 150, 60, function(v) Flags.FarmRadius = v end)
page:Slider("Farm Speed", 1, 16, 16, function(v) Flags.FarmSpeed = v end)
page:Toggle("Farm Iron", true, function(v) Flags.FarmIron = v end)
page:Toggle("Farm Gold", true, function(v) Flags.FarmGold = v end)
page:Toggle("Farm Diamond", true, function(v) Flags.FarmDiamond = v end)
page:Toggle("Farm Emerald", true, function(v) Flags.FarmEmerald = v end)
page:Toggle("Farm Bed Break", false, function(v) Flags.FarmBedBreak = v end)
page:Toggle("Farm Kill Aura", false, function(v) Flags.FarmKA = v end)
page:Toggle("Farm Auto Buy", false, function(v) Flags.FarmAutoBuy = v end)
page:Toggle("Farm Pathfind", true, function(v) Flags.FarmPathfind = v end)
page:Slider("Farm Collect Range", 3, 15, 8, function(v) Flags.FarmCollectRange = v end)
page:Toggle("Farm Magnet", true, function(v) Flags.FarmMagnet = v end)

-- ═══ FAST AUTO FARM ENGINE v2 ═══
task.spawn(function()
    local pathfindCache = {}
    local lastCollect = 0
    local lastBuy = 0
    local lastAttack = 0

    while true do
        if Flags.AutoFarm and alive() then
            pcall(function()
                local myHrp = hrp()
                local myHum = hum()
                if not myHrp or not myHum then goto skip_farm end

                -- 1. Find nearest resource (optimized: check nearby only)
                local bestObj, bestDist = nil, Flags.FarmRadius or 60
                local collectRange = Flags.FarmCollectRange or 8

                for _, obj in pairs(workspace:GetChildren()) do
                    if obj:IsA("BasePart") then
                        local pt = obj:GetAttribute("PickupType")
                        if pt then
                            local shouldFarm = false
                            if pt == "iron" and Flags.FarmIron then shouldFarm = true
                            elseif pt == "gold" and Flags.FarmGold then shouldFarm = true
                            elseif pt == "diamond" and Flags.FarmDiamond then shouldFarm = true
                            elseif pt == "emerald" and Flags.FarmEmerald then shouldFarm = true
                            end
                            if shouldFarm then
                                local d = (myHrp.Position - obj.Position).Magnitude
                                if d < bestDist then bestObj = obj; bestDist = d end
                            end
                        end
                    end
                end

                -- 2. Move to resource (pathfinding or direct)
                if bestObj then
                    local targetPos = bestObj.Position

                    if Flags.FarmPathfind and bestDist > 10 then
                        -- Use pathfinding for complex terrain
                        local path = PathfindingService:CreatePath({
                            AgentRadius = 2,
                            AgentHeight = 5,
                            AgentCanJump = true,
                            AgentCanClimb = false,
                        })
                        local ok = pcall(function()
                            path:ComputeAsync(myHrp.Position, targetPos)
                        end)
                        if ok and path.Status == Enum.PathStatus.Success then
                            local waypoints = path:GetWaypoints()
                            for _, wp in ipairs(waypoints) do
                                if not Flags.AutoFarm or not alive() then break end
                                myHum:MoveTo(wp.Position)
                                if wp.Action == Enum.PathWaypointAction.Jump then
                                    myHum.Jump = true
                                end
                                myHum.MoveToFinished:Wait()
                            end
                        else
                            -- Fallback: direct MoveTo
                            myHum:MoveTo(targetPos)
                            task.wait(0.3)
                        end
                    else
                        -- Direct walk for close targets
                        myHum:MoveTo(targetPos)
                        task.wait(0.2)
                    end

                    -- 3. Magnet: teleport close items to us
                    if Flags.FarmMagnet and bestDist < collectRange then
                        for _, obj in pairs(workspace:GetChildren()) do
                            if obj:IsA("BasePart") and obj:GetAttribute("PickupType") then
                                local d = (myHrp.Position - obj.Position).Magnitude
                                if d < collectRange then
                                    pcall(function()
                                        obj.CFrame = myHrp.CFrame + Vector3.new(0, -1, 0)
                                    end)
                                end
                            end
                        end
                    end

                    -- 4. Fast collect: walk through items
                    if bestDist < collectRange then
                        pcall(function()
                            bestObj.CFrame = myHrp.CFrame + Vector3.new(0, 0, 0)
                        end)
                    end
                end

                -- 5. Kill Aura while farming
                if Flags.FarmKA and (tick() - lastAttack) > 0.3 then
                    lastAttack = tick()
                    local target, dist = nearestEnemy(6)
                    if target and dist < 6 then
                        pcall(function()
                            local tool = lplr.Character:FindFirstChildWhichIsA("Tool")
                            if tool then tool:Activate() end
                        end)
                    end
                end

                -- 6. Auto buy blocks while farming
                if Flags.FarmAutoBuy and (tick() - lastBuy) > 5 then
                    lastBuy = tick()
                    pcall(function()
                        invokeRemote("BedwarsPurchaseItem", {shopItem = {itemType = "wool", shopId = "main"}})
                    end)
                end

                ::skip_farm::
            end)
        end
        task.wait(0.1)  -- Fast loop for quick response
    end
end)

-- ═══ 27. Auto Bridge Advanced ═══
page:Toggle("Auto Bridge", false, function(v) Flags.AutoBridge = v end)
page:Slider("Bridge Target", 10, 100, 30, function(v) Flags.BridgeTarget = v end)

-- ═══ 28. ESP Bed (world) ═══
page:Toggle("ESP Bed", false, function(v) Flags.ESP_Bed = v end)

-- ═══ 29. Auto Pickup ═══
page:Toggle("Auto Pickup", false, function(v) Flags.AutoPickup = v end)

-- ═══ 30. World ESP ═══
page:Toggle("World ESP", false, function(v) Flags.ESP_World = v end)

-- ═══ Engine: Auto Break Bed ═══
task.spawn(function()
    while true do
        if Flags.AutoBreakBed and alive() then
            pcall(function()
                local myHrp = hrp()
                if not myHrp then goto skip_brk end
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= lplr and p.Character then
                        for _, part in pairs(p.Character:GetDescendants()) do
                            if part:IsA("BasePart") and part:GetAttribute("Bed") then
                                local d = (myHrp.Position - part.Position).Magnitude
                                if d < (Flags.BedRange or 5) then
                                    local tool = lplr.Character:FindFirstChildWhichIsA("Tool")
                                    if tool then tool:Activate() end
                                end
                            end
                        end
                    end
                end
                ::skip_brk::
            end)
        end
        task.wait(0.3)
    end
end)

-- ═══ Engine: Chest Steal ═══
task.spawn(function()
    while true do
        if Flags.ChestSteal and alive() then
            pcall(function()
                for _, obj in pairs(workspace:GetChildren()) do
                    if obj:IsA("Model") and (obj.Name:find("Chest") or obj.Name:find("chest")) then
                        local pp = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                        if pp then
                            local d = (hrp().Position - pp.Position).Magnitude
                            if d < 8 then
                                invokeRemote("ChestGetItem", {chest = obj})
                            end
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

-- ═══ Engine: Scaffold ═══
task.spawn(function()
    while true do
        if Flags.Scaffold and alive() then
            pcall(function()
                local myHrp = hrp()
                local myHum = hum()
                if not myHrp or not myHum then goto skip_sca end
                local lookDir = myHrp.CFrame.LookVector
                local placePos = myHrp.Position + lookDir * 3 - Vector3.new(0, 3, 0)
                -- Snap to grid
                placePos = Vector3.new(
                    math.floor(placePos.X / 3 + 0.5) * 3,
                    math.floor(placePos.Y / 3 + 0.5) * 3,
                    math.floor(placePos.Z / 3 + 0.5) * 3
                )
                pcall(function()
                    fireRemote("Block", "PlaceBlock", {blockType = "wool", position = placePos, normal = Vector3.new(0, 1, 0)})
                end)
                if Flags.ScaffoldExtend then
                    local extendPos = placePos + lookDir * 3
                    pcall(function()
                        fireRemote("Block", "PlaceBlock", {blockType = "wool", position = extendPos, normal = Vector3.new(0, 1, 0)})
                    end)
                end
                ::skip_sca::
            end)
        end
        task.wait(0.1)
    end
end)

-- ═══ Engine: Auto Collect ═══
task.spawn(function()
    while true do
        if Flags.AutoCollect and alive() then
            pcall(function()
                local myHrp = hrp()
                if myHrp then
                    for _, obj in pairs(workspace:GetChildren()) do
                        if obj:IsA("BasePart") and obj:GetAttribute("PickupType") then
                            local d = (myHrp.Position - obj.Position).Magnitude
                            if d < 8 then
                                pcall(function()
                                    invokeRemote("PickupItemDrop", {itemDrop = obj})
                                end)
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- ═══ Engine: Nuker ═══
task.spawn(function()
    while true do
        if Flags.Nuker and alive() then
            pcall(function()
                local myHrp = hrp()
                if myHrp then
                    for _, obj in pairs(workspace:GetChildren()) do
                        if obj:IsA("BasePart") and obj.Name:find("Block") then
                            local d = (myHrp.Position - obj.Position).Magnitude
                            if d < (Flags.NukerRange or 5) then
                                obj:BreakJoints()
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- ═══ Engine: Bed Protect ═══
task.spawn(function()
    while true do
        if Flags.BedProtect and alive() then
            pcall(function()
                local myHrp = hrp()
                if myHrp then
                    for _, p in pairs(Players:GetPlayers()) do
                        if p == lplr and p.Character then
                            for _, part in pairs(p.Character:GetDescendants()) do
                                if part:IsA("BasePart") and part:GetAttribute("Bed") then
                                    -- Place blocks around bed
                                    for _, off in pairs({Vector3.new(3,0,0), Vector3.new(-3,0,0), Vector3.new(0,0,3), Vector3.new(0,0,-3)}) do
                                        pcall(function()
                                            fireRemote("Block", "PlaceBlock", {blockType = "wool", position = part.Position + off, normal = Vector3.new(0, 1, 0)})
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(2)
    end
end)

-- ═══ Engine: No Clip ═══
task.spawn(function()
    while true do
        if Flags.NoClip and alive() then
            pcall(function()
                local char = lplr.Character
                if char then
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
        task.wait(0.1)
    end
end)

-- ═══ Engine: Safe Walk ═══
task.spawn(function()
    while true do
        if Flags.SafeWalk and alive() then
            pcall(function()
                local myHrp = hrp()
                local myHum = hum()
                if myHrp and myHum then
                    local ray = workspace:Raycast(myHrp.Position, Vector3.new(0, -3, 0))
                    if not ray then
                        myHum:MoveTo(myHrp.Position)
                    end
                end
            end)
        end
        task.wait(0.1)
    end
end)

-- ═══ Engine: Jump Boost ═══
task.spawn(function()
    while true do
        if Flags.JumpBoost and alive() then
            pcall(function()
                local h = hum()
                if h then h.JumpPower = 70 end
            end)
        end
        task.wait(0.5)
    end
end)

-- ═══ Engine: Auto Pearl ═══
task.spawn(function()
    while true do
        if Flags.AutoPearl and alive() then
            pcall(function()
                local target, dist = nearestEnemy(50)
                if target and dist > 15 then
                    local myHrp = hrp()
                    if myHrp then
                        local dir = (target.HRP.Position - myHrp.Position).Unit
                        invokeRemote("ProjectileFire", {
                            position = myHrp.Position,
                            direction = dir,
                            chargeTime = 0.5
                        })
                    end
                end
            end)
        end
        task.wait(2)
    end
end)

-- ═══ Engine: Xray ═══
task.spawn(function()
    while true do
        if Flags.Xray then
            pcall(function()
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and not v:IsDescendantOf(lplr.Character or Instance.new("Model")) then
                        if v.Transparency < 0.8 then
                            v.LocalTransparencyModifier = 0.7
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

-- ═══ Engine: Auto Pickup ═══
task.spawn(function()
    while true do
        if Flags.AutoPickup and alive() then
            pcall(function()
                local myHrp = hrp()
                if myHrp then
                    for _, obj in pairs(workspace:GetChildren()) do
                        if obj:IsA("BasePart") and obj:GetAttribute("PickupType") then
                            local d = (myHrp.Position - obj.Position).Magnitude
                            if d < 6 then
                                pcall(function()
                                    invokeRemote("PickupItemDrop", {itemDrop = obj})
                                end)
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.3)
    end
end)

print("[World] Module loaded v6.0 (Fast Auto Farm + 30 features)")
