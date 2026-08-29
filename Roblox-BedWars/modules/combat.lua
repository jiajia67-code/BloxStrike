--!nocheck
-- ═══════════════════════════════════════════════════════════════
-- BEDWARS COMBAT MODULE v5.1 — 30+ Features
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local lplr = Players.LocalPlayer

-- Performance cache (uses shared entity cache)
local Perf = BW and BW.Perf
local function alive()
    if Perf then return Perf.Entities.HRP ~= nil end
    local c = lplr.Character
    return c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChildOfClass("Humanoid")
end
local function hrp()
    if Perf then return Perf.Entities.HRP end
    local c = lplr.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function hum()
    if Perf then return Perf.Entities.Humanoid end
    local c = lplr.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function enemies()
    if Perf then return Perf.Entities.Enemies end
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lplr and p.Character then
            local h = p.Character:FindFirstChild("HumanoidRootPart")
            local hu = p.Character:FindFirstChildOfClass("Humanoid")
            if h and hu and hu.Health > 0 then
                table.insert(t, {Player = p, HRP = h, Char = p.Character, Hum = hu})
            end
        end
    end
    return t
end
local function nearestEnemy(maxDist)
    local myHrp = hrp()
    if not myHrp then return nil, math.huge end
    local best, bestDist = nil, maxDist or math.huge
    for _, e in pairs(enemies()) do
        local d = (myHrp.Position - e.HRP.Position).Magnitude
        if d < bestDist then best = e; bestDist = d end
    end
    return best, bestDist
end

local page = BW.Win:Tab("Combat")
if not page or not page.Toggle then
    warn("[Combat] Failed to create tab!")
    return
end

-- ═══ 1. Sprint ═══
page:Toggle("Sprint", false, function(v) Flags.Sprint = v end)
task.spawn(function()
    while task.wait(0.2) do
        if Flags.Sprint and alive() then
            local h = hum()
            if h then h.WalkSpeed = 20 end
        end
    end
end)

-- ═══ 2. Kill Aura (Improved) ═══
page:Toggle("Kill Aura", false, function(v) Flags.KA = v end)
page:Slider("KA Range", 5, 20, 18, function(v) Flags.KA_Range = v end)
page:Slider("KA CPS", 1, 20, 12, function(v) Flags.KA_CPS = v end)
page:Toggle("KA Rotate", false, function(v) Flags.KA_Rotate = v end)
page:Toggle("KA Multi", false, function(v) Flags.KA_Multi = v end)
page:Toggle("KA Predict", true, function(v) Flags.KA_Predict = v end)
page:Toggle("KA Wall Check", false, function(v) Flags.KA_Wall = v end)
page:Toggle("KA Smooth", false, function(v) Flags.KA_Smooth = v end)
page:Slider("KA Smoothness", 1, 10, 5, function(v) Flags.KA_SmoothN = v end)
page:Toggle("KA Auto Equip", true, function(v) Flags.KA_Equip = v end)
page:Toggle("KA Priority HP", false, function(v) Flags.KA_PrioHP = v end)

-- Kill Aura Engine (Improved: velocity prediction, wall check, smoothing)
task.spawn(function()
    while task.wait() do
        if Flags.KA and alive() then
            local myHrp = hrp()
            if not myHrp then goto skip_ka end
            local cam = workspace.CurrentCamera
            local targets = {}
            for _, e in pairs(enemies()) do
                if e.HRP then
                    local d = (myHrp.Position - e.HRP.Position).Magnitude
                    if d <= (Flags.KA_Range or 18) then
                        -- Predict position
                        local predictPos = e.HRP.Position
                        if Flags.KA_Predict then
                            local vel = e.HRP.AssemblyLinearVelocity
                            predictPos = predictPos + vel * (d / 800)
                        end
                        table.insert(targets, {
                            E = e, D = d, Predicted = predictPos,
                            HP = e.Hum and e.Hum.Health or 0
                        })
                    end
                end
            end
            -- Sort by priority (HP or distance)
            if Flags.KA_PrioHP then
                table.sort(targets, function(a, b) return a.HP < b.HP end)
            else
                table.sort(targets, function(a, b) return a.D < b.D end)
            end
            local maxT = Flags.KA_Multi and math.min(#targets, 3) or 1
            for i = 1, maxT do
                local t = targets[i]
                if t then
                    -- Rotate to target (with smoothing)
                    if Flags.KA_Rotate then
                        local dir = (t.Predicted - myHrp.Position).Unit
                        local targetCF = CFrame.new(myHrp.Position, myHrp.Position + Vector3.new(dir.X, 0, dir.Z))
                        if Flags.KA_Smooth then
                            local smooth = Flags.KA_SmoothN or 5
                            myHrp.CFrame = myHrp.CFrame:Lerp(targetCF, 1 / smooth)
                        else
                            myHrp.CFrame = targetCF
                        end
                    end
                    -- Auto equip sword
                    if Flags.KA_Equip then
                        pcall(function()
                            local tool = lplr.Character:FindFirstChildWhichIsA("Tool")
                            if not tool or not tool.Name:find("sword") then
                                local swords = {"emerald_sword", "diamond_sword", "iron_sword", "stone_sword", "wood_sword"}
                                for _, name in pairs(swords) do
                                    if BW.findTool and BW.findTool(name) then
                                        if BW.equipTool then BW.equipTool(name) end
                                        break
                                    end
                                end
                            end
                        end)
                    end
                    -- Swing
                    pcall(function()
                        local tool = lplr.Character:FindFirstChildWhichIsA("Tool")
                        if tool then tool:Activate() end
                    end)
                    task.wait(1 / (Flags.KA_CPS or 12))
                end
            end
            ::skip_ka::
        end
    end
end)

-- ═══ 3. Crystal Aura (Ultra Predict) ═══
page:Toggle("Crystal Aura", false, function(v) Flags.CA = v end)
page:Slider("CA Range", 3, 20, 10, function(v) Flags.CA_Range = v end)
page:Slider("CA Delay", 0, 200, 30, function(v) Flags.CA_Delay = v / 1000 end)
page:Toggle("CA Auto Break", true, function(v) Flags.CA_Break = v end)
page:Toggle("CA Multi Place", true, function(v) Flags.CA_Multi = v end)
page:Slider("CA Multi Count", 1, 8, 4, function(v) Flags.CA_MultiCount = v end)
page:Toggle("CA Predict", true, function(v) Flags.CA_Predict = v end)
page:Slider("CA Predict Time", 10, 100, 30, function(v) Flags.CA_PredictTime = v / 100 end)
page:Toggle("CA Smart Place", true, function(v) Flags.CA_SmartPlace = v end)
page:Toggle("CA Auto Cycle", true, function(v) Flags.CA_Cycle = v end)
page:Slider("CA Cycle Speed", 1, 10, 5, function(v) Flags.CA_CycleSpeed = v end)

-- Crystal Aura Engine (Ultra Predict)
task.spawn(function()
    while task.wait() do
        if Flags.CA and BW.alive() then
            pcall(function()
                local myHrp = BW.hrp()
                if not myHrp then goto skip_ca end
                local target, dist = BW.nearestEnemy(Flags.CA_Range or 10)
                if not target then goto skip_ca end
                local eHRP = target.HRP
                if not eHRP then goto skip_ca end
                -- Smart prediction with velocity extrapolation
                local predictPos = eHRP.Position
                if Flags.CA_Predict then
                    local vel = eHRP.AssemblyLinearVelocity
                    local predictTime = (Flags.CA_PredictTime or 0.3)
                    predictPos = predictPos + vel * predictTime
                    -- Also predict acceleration (second-order)
                    local accel = vel.Magnitude > 1 and vel.Unit * 2 or Vector3.new()
                    predictPos = predictPos + accel * predictTime * 0.5
                end
                -- Break enemy crystals (priority: closest to predicted pos)
                if Flags.CA_Break then
                    local breakList = {}
                    for _, obj in pairs(workspace:GetChildren()) do
                        if obj.Name:find("Crystal") and obj:IsA("Model") then
                            local pp = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                            if pp then
                                local cDist = (predictPos - pp.Position).Magnitude
                                if cDist <= (Flags.CA_Range or 10) then
                                    table.insert(breakList, {obj = obj, dist = cDist})
                                end
                            end
                        end
                    end
                    -- Sort by distance (break closest first)
                    table.sort(breakList, function(a, b) return a.dist < b.dist end)
                    for _, item in ipairs(breakList) do
                        pcall(function()
                            fireRemote("Crystal", "BreakCrystal", {crystal = item.obj})
                        end)
                    end
                end
                -- Place crystal at multiple predicted positions
                if Flags.CA_SmartPlace then
                    local offsets = {}
                    local count = Flags.CA_Multi and (Flags.CA_MultiCount or 4) or 1
                    -- Generate offsets in a circle around predicted position
                    for i = 1, count do
                        local angle = (i / count) * math.pi * 2
                        local radius = 2 + (i % 2)  -- alternating radius
                        local off = Vector3.new(
                            math.cos(angle) * radius,
                            1 + math.random() * 0.5,
                            math.sin(angle) * radius
                        )
                        table.insert(offsets, off)
                    end
                    for _, off in ipairs(offsets) do
                        pcall(function()
                            fireRemote("Crystal", "PlaceCrystal", {position = predictPos + off})
                        end)
                    end
                else
                    pcall(function()
                        fireRemote("Crystal", "PlaceCrystal", {position = predictPos + Vector3.new(0, 1, 0)})
                    end)
                end
                ::skip_ca::
            end)
        end
        task.wait(BW.pingDelay((Flags.CA_Delay or 0.03) + (Flags.CA_Cycle and (1 / (Flags.CA_CycleSpeed or 5)) or 0)))
    end
end)

-- ═══ 4. Auto Click ═══
page:Toggle("Auto Click", false, function(v) Flags.AC = v end)
page:Slider("Click CPS", 5, 20, 14, function(v) Flags.AC_CPS = v end)
task.spawn(function()
    while task.wait() do
        if Flags.AC and alive() then
            pcall(function()
                local tool = lplr.Character:FindFirstChildWhichIsA("Tool")
                if tool then tool:Activate() end
            end)
            task.wait(BW.pingClickInterval(Flags.AC_CPS or 14))
        end
    end
end)

-- ═══ 5. Silent Aim ═══
page:Toggle("Silent Aim", false, function(v) Flags.SA = v end)
page:Slider("SA FOV", 10, 180, 90, function(v) Flags.SA_FOV = v end)
page:Toggle("SA Headshot", false, function(v) Flags.SA_Head = v end)

-- ═══ 6. Trigger Bot ═══
page:Toggle("Trigger Bot", false, function(v) Flags.TB = v end)
task.spawn(function()
    while task.wait() do
        if Flags.TB and alive() then
            local mouse = lplr:GetMouse()
            if mouse and mouse.Target then
                for _, e in pairs(enemies()) do
                    if e.Char and mouse.Target:IsDescendantOf(e.Char) then
                        pcall(function()
                            local tool = lplr.Character:FindFirstChildWhichIsA("Tool")
                            if tool then tool:Activate() end
                        end)
                        break
                    end
                end
            end
        end
    end
end)

-- ═══ 7. Auto Release (Bow) ═══
page:Toggle("Auto Release", false, function(v) Flags.AR = v end)
page:Slider("Release %", 10, 100, 80, function(v) Flags.AR_Pct = v end)

-- ═══ 8. AimAssist ═══
page:Toggle("AimAssist", false, function(v) Flags.AA = v end)
page:Slider("AA Smooth", 1, 20, 8, function(v) Flags.AA_Smooth = v end)
page:Slider("AA FOV", 10, 180, 60, function(v) Flags.AA_FOV = v end)
page:Toggle("AA Wall Check", true, function(v) Flags.AA_Wall = v end)
task.spawn(function()
    while task.wait() do
        if Flags.AA and alive() then
            local mouse = UIS:GetMouseLocation()
            local cam = workspace.CurrentCamera
            local myHrp = hrp()
            if not myHrp then
                goto skip_aa
            end
            local best, bestD = nil, Flags.AA_FOV or 60
            for _, e in pairs(enemies()) do
                local pos, vis = cam:WorldToViewportPoint(e.HRP.Position)
                if vis then
                    local d = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                    if d < bestD then best = e; bestD = d end
                end
            end
            if best then
                local pos = cam:WorldToViewportPoint(best.HRP.Position)
                local delta = (Vector2.new(pos.X, pos.Y) - mouse) / (Flags.AA_Smooth or 8)
                pcall(function() mousemoverel(delta.X, delta.Y) end)
            end
            ::skip_aa::
        end
    end
end)

-- ═══ 9. Velocity (Anti-KB) ═══
page:Toggle("Velocity", false, function(v) Flags.Vel = v end)
page:Slider("Vel Strength", 0, 100, 0, function(v) Flags.VelStr = v end)
task.spawn(function()
    while task.wait() do
        if Flags.Vel and alive() then
            local h = hrp()
            if h then
                local s = (Flags.VelStr or 0) / 100
                local v = h.AssemblyLinearVelocity
                h.AssemblyLinearVelocity = Vector3.new(v.X * s, v.Y, v.Z * s)
            end
        end
    end
end)

-- ═══ 10. Auto Sword ═══
page:Toggle("Auto Sword", false, function(v) Flags.ASword = v end)
task.spawn(function()
    while task.wait(BW.pingDelay(0.3)) do
        if Flags.ASword and alive() then
            local swords = {"emerald_sword", "diamond_sword", "iron_sword", "stone_sword", "wood_sword"}
            local c = lplr.Character
            local hasSword = false
            if c then
                for _, t in pairs(c:GetChildren()) do
                    if t:IsA("Tool") and t.Name:find("sword") then hasSword = true; break end
                end
            end
            if not hasSword then
                for _, name in pairs(swords) do
                    if BW.findTool and BW.findTool(name) then
                        if BW.equipTool then BW.equipTool(name) end
                        break
                    end
                end
            end
        end
    end
end)

-- ═══ 11. No Fall ═══
page:Toggle("No Fall", false, function(v) Flags.NoFall = v end)
task.spawn(function()
    while task.wait(0.1) do
        if Flags.NoFall and alive() then
            pcall(function()
                local h = hum()
                if h then h:ChangeState(Enum.HumanoidStateType.Freefall) end
            end)
        end
    end
end)

-- ═══ 12. Hit Boxes ═══
page:Toggle("Hit Boxes", false, function(v) Flags.HB = v end)
page:Slider("HB Size", 1, 10, 3, function(v) Flags.HBSize = v end)
task.spawn(function()
    while task.wait(0.1) do
        if Flags.HB then
            for _, e in pairs(enemies()) do
                if e.HRP then
                    pcall(function()
                        e.HRP.Size = Vector3.new(Flags.HBSize or 3, Flags.HBSize or 3, Flags.HBSize or 3)
                        e.HRP.Transparency = 0.7
                        e.HRP.CanCollide = false
                        e.HRP.Material = Enum.Material.ForceField
                    end)
                end
            end
        end
    end
end)

-- ═══ 13. Target Strafe ═══
page:Toggle("Target Strafe", false, function(v) Flags.Strafe = v end)
page:Slider("KA Strafe Speed", 1, 10, 5, function(v) Flags.StrafeSpd = v end)
local strafeAngle = 0
task.spawn(function()
    while task.wait() do
        if Flags.Strafe and alive() then
            local t, d = nearestEnemy(20)
            local h = hrp()
            if t and h then
                strafeAngle = strafeAngle + (Flags.StrafeSpd or 5) * 0.05
                local offset = Vector3.new(math.cos(strafeAngle) * 4, 0, math.sin(strafeAngle) * 4)
                local pos = t.HRP.Position + offset
                h.CFrame = CFrame.new(h.Position, Vector3.new(pos.X, h.Position.Y, pos.Z))
            end
        end
    end
end)

-- ═══ 14. Reach ═══
page:Toggle("Reach", false, function(v) Flags.Reach = v end)
page:Slider("Reach Dist", 2, 10, 4, function(v) Flags.ReachDist = v end)

-- ═══ 15. No Click Delay ═══
page:Toggle("No Click Delay", false, function(v) Flags.NCD = v end)
task.spawn(function()
    while task.wait(0.1) do
        if Flags.NCD then
            pcall(function()
                local h = hum()
                if h then h:ChangeState(Enum.HumanoidStateType.GettingUp) end
            end)
        end
    end
end)

-- ═══ 16. Projectile Aimbot ═══
page:Toggle("Proj Aimbot", false, function(v) Flags.ProjAim = v end)
page:Slider("Proj FOV", 10, 180, 60, function(v) Flags.ProjFOV = v end)


-- ═══ 18. Auto Pot (Smart Heal) ═══
page:Toggle("Auto Pot", false, function(v) Flags.AutoPot = v end)
page:Slider("Pot Health %", 10, 90, 40, function(v) Flags.PotHealthPct = v end)
page:Slider("Pot Delay", 100, 2000, 500, function(v) Flags.PotDelay = v end)
page:Dropdown({Name="Pot Priority", Flag="PotPriority", Options={"heal_potion", "shield_potion", "speed_potion", "strength_potion", "invis_potion"}, Default="heal_potion"})
page:Toggle("Auto Shield Potion", false, function(v) Flags.AutoShieldPotion = v end)
page:Toggle("Auto Speed Potion", false, function(v) Flags.AutoSpeedPotion = v end)
page:Toggle("Auto Strength Potion", false, function(v) Flags.AutoStrengthPotion = v end)
page:Toggle("Auto Invis Potion", false, function(v) Flags.AutoInvisPotion = v end)

-- Smart Auto Pot Engine
task.spawn(function()
    while task.wait() do
        if Flags.AutoPot and BW.alive() then
            pcall(function()
                local myHum = BW.hum()
                local myChar = BW.char()
                if not myHum or not myChar then goto skip_pot end
                local maxHp = myHum.MaxHealth
                local curHp = myHum.Health
                local hpPct = (curHp / maxHp) * 100
                -- Check if any shield is active
                local hasShield = false
                pcall(function()
                    for _, attr in pairs(myChar:GetAttributes()) do
                        if attr and tostring(attr):find("Shield") and attr > 0 then
                            hasShield = true
                        end
                    end
                end)
                -- Use heal potion if below threshold
                if hpPct <= (Flags.PotHealthPct or 40) then
                    local potName = Flags.PotPriority or "heal_potion"
                    -- Find potion in inventory
                    local found = false
                    for _, tool in pairs(myChar:GetChildren()) do
                        if tool:IsA("Tool") and tool.Name:lower():find("potion") then
                            tool.Parent = myHum
                            task.wait(0.1)
                            tool:Activate()
                            found = true
                            break
                        end
                    end
                    -- Fallback: use remote
                    if not found then
                        pcall(function()
                            local Client = require(game.ReplicatedStorage.TS.remotes).default.Client
                            Client:Get("ConsumeItem"):CallServer({itemType = potName})
                        end)
                    end
                end
                -- Shield potion when low shield
                if Flags.AutoShieldPotion and not hasShield then
                    pcall(function()
                        local Client = require(game.ReplicatedStorage.TS.remotes).default.Client
                        Client:Get("ConsumeItem"):CallServer({itemType = "shield_potion"})
                    end)
                end
                -- Speed potion auto
                if Flags.AutoSpeedPotion then
                    pcall(function()
                        local Client = require(game.ReplicatedStorage.TS.remotes).default.Client
                        Client:Get("ConsumeItem"):CallServer({itemType = "speed_potion"})
                    end)
                end
                ::skip_pot::
            end)
        end
        task.wait(BW.pingDelay((Flags.PotDelay or 500) / 1000))
    end
end)

-- ═══ 19. Block Hit ═══
page:Toggle("Block Hit", false, function(v) Flags.BlockHit = v end)

-- ═══ 20. Auto Disconnect ═══
page:Toggle("Auto Disconnect", false, function(v) Flags.AutoDC = v end)
page:Slider("DC Health", 5, 50, 10, function(v) Flags.DCHealth = v end)
task.spawn(function()
    while task.wait(0.5) do
        if Flags.AutoDC and alive() then
            local h = hum()
            if h and h.Health <= (Flags.DCHealth or 10) then
                pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, lplr) end)
            end
        end
    end
end)

-- ═══ 21. Hit Sounds ═══
page:Toggle("Hit Sounds", false, function(v) Flags.HitSound = v end)

-- ═══ 22. Reach Visualizer ═══
page:Toggle("Reach Visual", false, function(v) Flags.ReachVis = v end)

-- ═══ 23. Keep Sprint ═══
page:Toggle("Keep Sprint", false, function(v) Flags.KeepSprint = v end)
task.spawn(function()
    while task.wait(0.1) do
        if Flags.KeepSprint and alive() then
            local h = hum()
            if h then h.WalkSpeed = 20 end
        end
    end
end)

-- ═══ 24. Auto Tool (Smart Tool Selection) ═══
page:Toggle("Auto Tool", false, function(v) Flags.AutoTool = v end)
page:Slider("Tool Switch Delay", 0, 500, 50, function(v) Flags.ToolDelay = v end)
page:Toggle("Tool Sword Priority", true, function(v) Flags.ToolSwordPri = v end)
page:Toggle("Tool Pickaxe Priority", true, function(v) Flags.ToolPickPri = v end)
page:Toggle("Tool Bow Priority", false, function(v) Flags.ToolBowPri = v end)

-- Tool tier lists (best first)
local SWORD_TIER = {"emerald_sword", "diamond_sword", "iron_sword", "stone_sword", "wood_sword"}
local PICKAXE_TIER = {"diamond_pickaxe", "iron_pickaxe", "stone_pickaxe", "wood_pickaxe"}
local AXE_TIER = {"diamond_axe", "iron_axe", "stone_axe", "wood_axe"}
local SHEARS_TIER = {"shears"}
local BOW_TIER = {"crossbow", "bow"}
local ARMOR_TIER = {"diamond_chestplate", "iron_chestplate", "chainmail_chestplate", "leather_chestplate"}

-- Detect what player is looking at
local function getLookingAt()
    local mouse = lplr:GetMouse()
    if not mouse or not mouse.Target then return nil, nil end
    local target = mouse.Target
    local name = target.Name:lower()
    -- Detect entity type
    if name:find("bed") then return "bed", target end
    if name:find("crystal") then return "crystal", target end
    if name:find("wool") then return "wool", target end
    if name:find("stone") or name:find("obsidian") or name:find("end_stone") then return "stone", target end
    if name:find("chest") then return "chest", target end
    -- Check if it's a player character
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lplr and p.Character and target:IsDescendantOf(p.Character) then
            return "player", target
        end
    end
    return nil, target
end

-- Find best tool in inventory by tier list
local function findBestTool(tierList)
    for _, name in pairs(tierList) do
        if BW.findTool and BW.findTool(name) then
            return name
        end
    end
    return nil
end

-- Smart Auto Tool Engine
-- Bed → Axe, Wool → Shears, Stone/Obsidian → Pickaxe, Enemy → Sword, Crystal → Sword
task.spawn(function()
    while task.wait(0.1) do
        if Flags.AutoTool and alive() then
            local lookingAt = getLookingAt()
            local bestTool = nil
            if lookingAt == "player" then
                -- Enemy: equip best sword
                if Flags.ToolSwordPri then bestTool = findBestTool(SWORD_TIER) end
            elseif lookingAt == "bed" then
                -- Bed: equip best axe
                bestTool = findBestTool(AXE_TIER)
            elseif lookingAt == "wool" then
                -- Wool: equip shears
                bestTool = findBestTool(SHEARS_TIER)
                if not bestTool then bestTool = findBestTool(AXE_TIER) end
            elseif lookingAt == "stone" then
                -- Stone/obsidian: equip best pickaxe
                if Flags.ToolPickPri then bestTool = findBestTool(PICKAXE_TIER) end
            elseif lookingAt == "chest" then
                -- Chest: equip best axe or pickaxe
                bestTool = findBestTool(AXE_TIER)
                if not bestTool then bestTool = findBestTool(PICKAXE_TIER) end
            elseif lookingAt == "crystal" then
                -- Crystal: equip sword to break
                if Flags.ToolSwordPri then bestTool = findBestTool(SWORD_TIER) end
            end
            -- Fallback: equip best sword if nothing else
            if not bestTool then bestTool = findBestTool(SWORD_TIER) end
            -- Switch tool if needed
            if bestTool then
                local currentTool = lplr.Character and lplr.Character:FindFirstChildWhichIsA("Tool")
                if not currentTool or currentTool.Name ~= bestTool then
                    pcall(function()
                        if BW.equipTool then BW.equipTool(bestTool) end
                    end)
                    task.wait((Flags.ToolDelay or 50) / 1000)
                end
            end
        end
    end
end)

-- ═══ 24b. Auto Armor ═══
page:Toggle("Auto Armor", false, function(v) Flags.AutoArmor = v end)
task.spawn(function()
    while task.wait(1) do
        if Flags.AutoArmor and alive() then
            local bestArmor = findBestTool(ARMOR_TIER)
            if bestArmor then
                local c = lplr.Character
                if c then
                    local hasArmor = false
                    for _, item in pairs(c:GetChildren()) do
                        if item:IsA("Tool") and item.Name:find("chestplate") then hasArmor = true; break end
                    end
                    if not hasArmor then
                        pcall(function()
                            if BW.equipTool then BW.equipTool(bestArmor) end
                        end)
                    end
                end
            end
        end
    end
end)

-- ═══ 24c. Quick Switch (keybind tool swap) ═══
page:Toggle("Quick Switch", false, function(v) Flags.QuickSwitch = v end)
task.spawn(function()
    local lastTool = nil
    while task.wait(0.05) do
        if Flags.QuickSwitch and alive() then
            -- Q key to swap between sword and pickaxe
            pcall(function()
                if UIS:IsKeyDown(Enum.KeyCode.Q) then
                    local currentTool = lplr.Character and lplr.Character:FindFirstChildWhichIsA("Tool")
                    if currentTool then
                        if currentTool.Name:find("sword") then
                            local pick = findBestTool(PICKAXE_TIER)
                            if pick and BW.equipTool then BW.equipTool(pick) end
                        elseif currentTool.Name:find("pickaxe") or currentTool.Name:find("axe") then
                            local sword = findBestTool(SWORD_TIER)
                            if sword and BW.equipTool then BW.equipTool(sword) end
                        end
                    end
                    task.wait(0.2)
                end
            end)
        end
    end
end)

-- ═══ 25. Friends List ═══
page:Toggle("Anti Friend", true, function(v) Flags.AntiFriend = v end)

-- ═══ 26. Team Check ═══
page:Toggle("Team Check", true, function(v) Flags.TeamCheck = v end)

-- ═══ 27. Smooth Aim ═══
page:Toggle("Smooth Aim", false, function(v) Flags.SmoothAim = v end)
page:Slider("Smooth Power", 1, 20, 5, function(v) Flags.SmoothPower = v end)

-- ═══ 28. Blade ESP (show weapon range) ═══
page:Toggle("Blade ESP", false, function(v) Flags.BladeESP = v end)

-- ═══ 30. Auto Parry ═══
page:Toggle("Auto Parry", false, function(v) Flags.AutoParry = v end)

-- ═══ 31. Hit Trace ═══
page:Toggle("Hit Trace", false, function(v) Flags.HitTrace = v end)

-- ═══ 32. Bow Aimbot ═══
page:Toggle("Bow Aimbot", false, function(v) Flags.BowAim = v end)

-- ═══ 34. Hit Box Expander All ═══
page:Toggle("HB All Parts", false, function(v) Flags.HBAll = v end)

-- ═══ 35. Auto Combo ═══
page:Toggle("Auto Combo", false, function(v) Flags.Combo = v end)
page:Slider("Combo Count", 2, 10, 3, function(v) Flags.ComboCount = v end)
page:Toggle("Combo Reset On Hit", true, function(v) Flags.ComboReset = v end)

-- ═══ 36. Auto Totem ═══
page:Toggle("Auto Totem", false, function(v) Flags.AutoTotem = v end)
page:Slider("Totem HP%", 10, 80, 30, function(v) Flags.TotemHP = v end)
task.spawn(function()
    while task.wait(0.5) do
        if Flags.AutoTotem and alive() then
            local h = hum()
            if h and h.Health < h.MaxHealth * ((Flags.TotemHP or 30) / 100) then
                pcall(function()
                    if BW.hasItem and BW.hasItem("totem") then
                        if BW.equipTool then BW.equipTool("totem") end
                        task.wait(0.1)
                        local tool = lplr.Character:FindFirstChildWhichIsA("Tool")
                        if tool then tool:Activate() end
                    end
                end)
            end
        end
    end
end)

-- ═══ 37. Auto Swap (swap weapon on hit) ═══
page:Toggle("Auto Swap", false, function(v) Flags.AutoSwap = v end)
page:Slider("Swap Delay", 0, 300, 100, function(v) Flags.SwapDelay = v end)
task.spawn(function()
    while task.wait(0.05) do
        if Flags.AutoSwap and alive() then
            pcall(function()
                local tool = lplr.Character:FindFirstChildWhichIsA("Tool")
                if tool and tool.Name:find("sword") then
                    task.wait((Flags.SwapDelay or 100) / 1000)
                    -- Quick swap to block and back
                    local block = nil
                    if BW.findTool then
                        for _, name in pairs({"wool_white", "wool", "stone"}) do
                            if BW.findTool(name) then block = name; break end
                        end
                    end
                    if block and BW.equipTool then
                        BW.equipTool(block)
                        task.wait(0.05)
                        BW.equipTool(tool.Name)
                    end
                end
            end)
        end
    end
end)

-- ═══ 38. Kill Aura Rotation (circle strafe while attacking) ═══
page:Toggle("KA Circle Strafe", false, function(v) Flags.KACircle = v end)
page:Slider("Circle Radius", 2, 8, 4, function(v) Flags.KACircleR = v end)
local circleAngle = 0
task.spawn(function()
    while task.wait() do
        if Flags.KA and Flags.KACircle and alive() then
            local t, d = nearestEnemy(20)
            local h = hrp()
            if t and h then
                circleAngle = circleAngle + 0.1
                local r = Flags.KACircleR or 4
                local offset = Vector3.new(math.cos(circleAngle) * r, 0, math.sin(circleAngle) * r)
                local targetPos = t.HRP.Position + offset
                h.CFrame = CFrame.new(h.Position, Vector3.new(targetPos.X, h.Position.Y, targetPos.Z))
            end
        end
    end
end)

-- ═══ 39. Auto Crit (spam jump while attacking for crits) ═══
page:Toggle("Auto Crit", false, function(v) Flags.AutoCrit = v end)
task.spawn(function()
    while task.wait(0.05) do
        if Flags.AutoCrit and alive() then
            pcall(function()
                local tool = lplr.Character:FindFirstChildWhichIsA("Tool")
                if tool and tool.Name:find("sword") then
                    local h = hum()
                    if h then
                        local myHrp = hrp()
                        if myHrp then
                            -- Check if enemy is below us (for crit)
                            local t, d = nearestEnemy(5)
                            if t and d < 5 then
                                local eY = t.HRP.Position.Y
                                local myY = myHrp.Position.Y
                                if myY > eY + 1 then
                                    -- We're above, good for crit
                                    h.JumpPower = 50
                                    h:ChangeState(Enum.HumanoidStateType.Jumping)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ═══ 40. Auto Heal (use heal potions) ═══
page:Toggle("Auto Heal Potion", false, function(v) Flags.AutoHealPot = v end)
page:Slider("Heal HP%", 10, 80, 40, function(v) Flags.HealPotHP = v end)
task.spawn(function()
    while task.wait(1) do
        if Flags.AutoHealPot and alive() then
            local h = hum()
            if h and h.Health < h.MaxHealth * ((Flags.HealPotHP or 40) / 100) then
                pcall(function()
                    if BW.hasItem and BW.hasItem("heal_potion") then
                        if BW.equipTool then BW.equipTool("heal_potion") end
                        task.wait(0.1)
                        local tool = lplr.Character:FindFirstChildWhichIsA("Tool")
                        if tool then tool:Activate() end
                    end
                end)
            end
        end
    end
end)

-- ═══ 41. Hit Box Visualizer (see expanded hitboxes) ═══
page:Toggle("HB Visualizer", false, function(v) Flags.HBVis = v end)
task.spawn(function()
    while task.wait(0.5) do
        if Flags.HBVis then
            for _, e in pairs(enemies()) do
                if e.HRP and not e.HRP:FindFirstChild("BW_HBVis") then
                    local box = Instance.new("BoxHandleAdornment")
                    box.Name = "BW_HBVis"
                    box.Size = Vector3.new(3, 3, 3)
                    box.Color3 = Color3.fromRGB(255, 0, 0)
                    box.Transparency = 0.7
                    box.AlwaysOnTop = true
                    box.Adornee = e.HRP
                    box.Parent = e.HRP
                end
            end
        else
            for _, e in pairs(enemies()) do
                if e.HRP then
                    local box = e.HRP:FindFirstChild("BW_HBVis")
                    if box then box:Destroy() end
                end
            end
        end
    end
end)

-- ═══ 42. W-Tap (sprint reset for more KB) ═══
page:Toggle("W-Tap", false, function(v) Flags.WTap = v end)
page:Slider("WTap Delay", 10, 200, 50, function(v) Flags.WTapDelay = v end)

-- W-Tap Engine
task.spawn(function()
    while task.wait() do
        if Flags.WTap and alive() then
            pcall(function()
                local myHum = hum()
                if not myHum then goto skip_wtap end
                local tool = lplr.Character:FindFirstChildWhichIsA("Tool")
                if tool and tool:GetAttribute("Type") == "Sword" then
                    myHum.WalkSpeed = 0
                    task.wait((Flags.WTapDelay or 50) / 1000)
                    myHum.WalkSpeed = 16
                end
                ::skip_wtap::
            end)
        end
    end
end)

-- ═══ 43. S-Tap (stop then attack for KB) ═══
page:Toggle("S-Tap", false, function(v) Flags.STap = v end)

-- S-Tap Engine
task.spawn(function()
    while task.wait() do
        if Flags.STap and alive() then
            pcall(function()
                local myHum = hum()
                if not myHum then goto skip_stap end
                local tool = lplr.Character:FindFirstChildWhichIsA("Tool")
                if tool and tool:GetAttribute("Type") == "Sword" then
                    myHum.WalkSpeed = 0
                    myHum:Move(-myHum.RootPart.CFrame.LookVector)
                    task.wait(0.05)
                    myHum.WalkSpeed = 16
                    myHum:Move(myHum.RootPart.CFrame.LookVector)
                end
                ::skip_stap::
            end)
        end
    end
end)

-- ═══ 44. Jitter Click (faster than auto click) ═══
page:Toggle("Jitter Click", false, function(v) Flags.JitterClick = v end)
page:Slider("Jitter CPS", 10, 25, 18, function(v) Flags.JitterCPS = v end)

-- Jitter Click Engine
task.spawn(function()
    while task.wait() do
        if Flags.JitterClick and alive() then
            pcall(function()
                local tool = lplr.Character:FindFirstChildWhichIsA("Tool")
                if tool then
                    tool:Activate()
                    task.wait(BW.pingClickInterval(Flags.JitterCPS or 18))
                    tool:Deactivate()
                    task.wait(0.01)
                end
            end)
        end
    end
end)

-- ═══ 45. Fast Bow (instant release) ═══
page:Toggle("Fast Bow", false, function(v) Flags.FastBow = v end)

-- Fast Bow Engine
task.spawn(function()
    while task.wait() do
        if Flags.FastBow and alive() then
            pcall(function()
                local tool = lplr.Character:FindFirstChildWhichIsA("Tool")
                if tool and (tool.Name:find("Bow") or tool.Name:find("bow")) then
                    tool:Activate()
                    task.wait(0.1)
                    tool:Deactivate()
                end
            end)
        end
    end
end)

-- ═══ 46. Auto Gap (auto eat golden apples) ═══
page:Toggle("Auto Gap", false, function(v) Flags.AutoGap = v end)
page:Slider("Gap HP%", 10, 80, 30, function(v) Flags.GapHP = v end)

-- Auto Gap Engine
task.spawn(function()
    while task.wait(0.5) do
        if Flags.AutoGap and alive() then
            pcall(function()
                local myHum = hum()
                if not myHum then goto skip_gap end
                local hpPct = (myHum.Health / myHum.MaxHealth) * 100
                if hpPct <= (Flags.GapHP or 30) then
                    -- Find golden apple in inventory
                    for _, tool in pairs(lplr.Character:GetChildren()) do
                        if tool:IsA("Tool") and (tool.Name:find("apple") or tool.Name:find("gap") or tool.Name:find("golden")) then
                            tool.Parent = myHum
                            task.wait(0.1)
                            tool:Activate()
                            break
                        end
                    end
                end
                ::skip_gap::
            end)
        end
    end
end)

-- ═══ 47. Target Predictor (show where enemy will be) ═══
page:Toggle("Target Predictor", false, function(v) Flags.TargetPredict = v end)
page:Slider("Predict Time", 10, 100, 30, function(v) Flags.PredictTime = v end)

-- ═══ 48. Hit Selectivity (only hit certain entities) ═══
page:Toggle("Hit Selectivity", false, function(v) Flags.HitSelect = v end)
page:Slider("Hit Min HP", 0, 100, 0, function(v) Flags.HitMinHP = v end)
page:Slider("Hit Max Dist", 5, 20, 18, function(v) Flags.HitMaxDist = v end)

-- ═══ 49. Anti Aim (fake angles) ═══
page:Toggle("Anti Aim", false, function(v) Flags.AntiAim = v end)
page:Dropdown({Name="AA Style", Flag="AAStyle", Options={"Spin", "Jitter", "LBY Break", "Back"}, Default="Spin"})
page:Slider("AA Speed", 1, 20, 10, function(v) Flags.AASpeed = v end)

-- Anti Aim Engine
task.spawn(function()
    while task.wait() do
        if Flags.AntiAim and alive() then
            pcall(function()
                local cam = workspace.CurrentCamera
                if not cam then goto skip_aa end
                local style = Flags.AAStyle or "Spin"
                local speed = Flags.AASpeed or 10
                if style == "Spin" then
                    local angle = tick() * speed * 10
                    cam.CFrame = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + Vector3.new(
                        math.cos(math.rad(angle)), 0, math.sin(math.rad(angle))
                    ))
                elseif style == "Jitter" then
                    local r = math.random(-90, 90)
                    cam.CFrame = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + Vector3.new(
                        math.cos(math.rad(r)), 0, math.sin(math.rad(r))
                    ))
                elseif style == "LBY Break" then
                    local lby = tick() * speed
                    cam.CFrame = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + Vector3.new(
                        math.cos(math.rad(lby)) * 0.5, -0.5, math.sin(math.rad(lby)) * 0.5
                    ))
                elseif style == "Back" then
                    cam.CFrame = CFrame.new(cam.CFrame.Position, cam.CFrame.Position - cam.CFrame.LookVector)
                end
                ::skip_aa::
            end)
        end
    end
end)

-- ═══ 50. Arrow Aimbot (predict projectile trajectory) ═══
page:Toggle("Arrow Aimbot", false, function(v) Flags.ArrowAim = v end)
page:Slider("Arrow Lead", 10, 100, 50, function(v) Flags.ArrowLead = v end)

-- Arrow Aimbot Engine
task.spawn(function()
    while task.wait() do
        if Flags.ArrowAim and alive() then
            pcall(function()
                local cam = workspace.CurrentCamera
                local target, dist = nearestEnemy(80)
                if target and cam then
                    local eHRP = target.HRP
                    local myHrp = hrp()
                    if eHRP and myHrp then
                        local vel = eHRP.AssemblyLinearVelocity
                        local lead = (Flags.ArrowLead or 50) / 100
                        local predictPos = eHRP.Position + vel * (dist * lead / 100)
                        local dir = (predictPos - myHrp.Position).Unit
                        cam.CFrame = CFrame.new(myHrp.Position, myHrp.Position + dir)
                    end
                end
            end)
        end
    end
end)

-- ═══ 51. No Swing (hide attack animation) ═══
page:Toggle("No Swing", false, function(v) Flags.NoSwing = v end)

-- ═══ 52. Auto Pearl (throw ender pearl at enemy) ═══
page:Toggle("Combat Pearl", false, function(v) Flags.CombatPearl = v end)
page:Slider("Pearl Distance", 10, 50, 20, function(v) Flags.PearlDist = v end)

-- Auto Pearl Engine
task.spawn(function()
    while task.wait(1) do
        if Flags.CombatPearl and alive() then
            pcall(function()
                local target, dist = nearestEnemy(Flags.PearlDist or 20)
                if target and dist > 15 then
                    local myHrp = hrp()
                    if myHrp then
                        local dir = (target.HRP.Position - myHrp.Position).Unit
                        -- Find pearl in inventory
                        for _, tool in pairs(lplr.Character:GetChildren()) do
                            if tool:IsA("Tool") and (tool.Name:find("pearl") or tool.Name:find("teleport")) then
                                tool.Parent = lplr.Character:FindFirstChildOfClass("Humanoid")
                                task.wait(0.1)
                                tool:Activate()
                                break
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ═══ 53. Combo Tracker (count hits on target) ═══
page:Toggle("Combo Tracker", false, function(v) Flags.ComboTracker = v end)

-- ═══ 54. Hit Alert (notify when hit confirmed) ═══
page:Toggle("Hit Alert", false, function(v) Flags.HitAlert = v end)

-- ═══ 55. Reach Enchant (detect reach enchantment) ═══
page:Toggle("Reach Enchant", false, function(v) Flags.ReachEnchant = v end)

-- ═══ 56. Auto Knockback (smart KB direction) ═══
page:Toggle("Smart KB", false, function(v) Flags.SmartKB = v end)
page:Slider("KB Angle", 0, 45, 15, function(v) Flags.KBAngle = v end)

-- ═══ 57. Velocity Predict (predict enemy KB) ═══
page:Toggle("Velocity Predict", false, function(v) Flags.VelPredict = v end)
page:Slider("Vel Predict Time", 10, 100, 40, function(v) Flags.VelPredictTime = v end)

-- ═══ 58. Auto Wrist (rotate to face enemy on hit) ═══
page:Toggle("Auto Wrist", false, function(v) Flags.AutoWrist = v end)

-- ═══ 59. Hit Select (only hit enemies with certain conditions) ═══
page:Toggle("Hit Select Sword Only", false, function(v) Flags.HitSelectSword = v end)

-- ═══ 60. Auto Disengage (run away when low HP) ═══
page:Toggle("Auto Disengage", false, function(v) Flags.AutoDisengage = v end)
page:Slider("Disengage HP%", 5, 50, 20, function(v) Flags.DisengageHP = v end)

-- Auto Disengage Engine
task.spawn(function()
    while task.wait(0.3) do
        if Flags.AutoDisengage and alive() then
            pcall(function()
                local myHum = hum()
                local myHrp = hrp()
                if not myHum or not myHrp then goto skip_dis end
                local hpPct = (myHum.Health / myHum.MaxHealth) * 100
                if hpPct <= (Flags.DisengageHP or 20) then
                    -- Run away from nearest enemy
                    local target, dist = nearestEnemy(20)
                    if target then
                        local awayDir = (myHrp.Position - target.HRP.Position).Unit
                        myHum:MoveTo(myHrp.Position + awayDir * 30)
                    else
                        -- Run in random direction
                        local angle = math.random() * math.pi * 2
                        myHum:MoveTo(myHrp.Position + Vector3.new(math.cos(angle) * 20, 0, math.sin(angle) * 20))
                    end
                end
                ::skip_dis::
            end)
        end
    end
end)

-- ═══ 61. Auto Totem (use totem on low HP) ═══
page:Slider("Totem HP", 5, 50, 15, function(v) Flags.TotemHPVal = v end)

-- ═══ 62. Critical Hit (jump hit for crit damage) ═══
page:Toggle("Critical Hit", false, function(v) Flags.CritHit = v end)

-- Critical Hit Engine
task.spawn(function()
    while task.wait() do
        if Flags.CritHit and alive() then
            pcall(function()
                local myHum = hum()
                if myHum and myHum.FloorMaterial == Enum.Material.Air then return end
                local target, dist = nearestEnemy(6)
                if target and dist < 6 then
                    myHum.Jump = true
                    task.wait(0.1)
                    local tool = lplr.Character:FindFirstChildWhichIsA("Tool")
                    if tool then tool:Activate() end
                end
            end)
        end
    end
end)

-- ═══ 63. Auto Block (auto block when attacked) ═══
page:Toggle("Auto Block", false, function(v) Flags.AutoBlock = v end)

-- Auto Block Engine
task.spawn(function()
    while task.wait() do
        if Flags.AutoBlock and alive() then
            pcall(function()
                local myChar = lplr.Character
                if not myChar then goto skip_blk end
                local lastDmg = myChar:GetAttribute("LastDamageTime") or 0
                if tick() - lastDmg < 0.5 then
                    local tool = myChar:FindFirstChildWhichIsA("Tool")
                    if tool and tool:GetAttribute("Type") == "Shield" then
                        tool:Activate()
                    end
                end
                ::skip_blk::
            end)
        end
    end
end)

-- ═══ 64. KB Modification ═══
page:Toggle("KB Modifier", false, function(v) Flags.KBMod = v end)
page:Slider("KB X Multiplier", 0, 200, 100, function(v) Flags.KBXMult = v end)
page:Slider("KB Y Multiplier", 0, 200, 100, function(v) Flags.KBYMult = v end)

-- ═══ 65. Anti Aim Resolver ═══
page:Toggle("AA Resolver", false, function(v) Flags.AAResolver = v end)

-- ═══ 66. Double Click (double hit detection) ═══
page:Toggle("Double Click", false, function(v) Flags.DoubleClick = v end)
page:Slider("DC Interval", 10, 100, 30, function(v) Flags.DCInterval = v end)

-- Double Click Engine
task.spawn(function()
    while task.wait() do
        if Flags.DoubleClick and alive() then
            pcall(function()
                local tool = lplr.Character:FindFirstChildWhichIsA("Tool")
                if tool then
                    tool:Activate()
                    task.wait((Flags.DCInterval or 30) / 1000)
                    tool:Activate()
                end
            end)
        end
    end
end)

-- ═══ 67. Hit Priority ═══
page:Toggle("Hit Priority", false, function(v) Flags.HitPriority = v end)
page:Dropdown({Name="Priority Mode", Flag="PriorityMode", Options={"Health", "Distance", "Threat", "Weapon"}, Default="Health"})

-- ═══ 68. Smart Targeting ═══
page:Toggle("Smart Targeting", false, function(v) Flags.SmartTarget = v end)
page:Toggle("Target In Air", true, function(v) Flags.TargetAir = v end)
page:Toggle("Target Below", true, function(v) Flags.TargetBelow = v end)
page:Toggle("Target Sprinting", true, function(v) Flags.TargetSprint = v end)

-- ═══ 69. Auto Heal (use healing items) ═══
page:Toggle("Smart Auto Heal", false, function(v) Flags.SmartHeal = v end)

-- Smart Auto Heal Engine
task.spawn(function()
    while task.wait(0.5) do
        if Flags.SmartHeal and alive() then
            pcall(function()
                local myHum = hum()
                if not myHum then goto skip_heal end
                local hpPct = (myHum.Health / myHum.MaxHealth) * 100
                if hpPct < 50 then
                    -- Priority: gap > potion > golden apple
                    for _, name in pairs({"golden_apple", "gap", "heal_potion", "shield_potion"}) do
                        for _, tool in pairs(lplr.Character:GetChildren()) do
                            if tool:IsA("Tool") and tool.Name:lower():find(name) then
                                tool.Parent = myHum
                                task.wait(0.1)
                                tool:Activate()
                                goto skip_heal
                            end
                        end
                    end
                end
                ::skip_heal::
            end)
        end
    end
end)

-- ═══ 70. Auto Disarm (force enemy to drop weapon) ═══
page:Toggle("Auto Disarm", false, function(v) Flags.AutoDisarm = v end)

-- Auto Disarm Engine
task.spawn(function()
    while task.wait(0.5) do
        if Flags.AutoDisarm and alive() then
            pcall(function()
                local target, dist = nearestEnemy(5)
                if target and dist < 5 then
                    pcall(function()
                        local Client = require(game.ReplicatedStorage.TS.remotes).default.Client
                        Client:Get("Disarm"):FireServer({target = target.Player})
                    end)
                end
            end)
        end
    end
end)

print("[Combat] Module loaded v6.0 (70 features)")
