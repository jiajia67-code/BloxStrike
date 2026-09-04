

-- BLOXSTRIKE COMBAT MODULE v1.0  20+ FPS Combat Features
-- Aimbot, Triggerbot, SilentAim, RCS, Auto Fire

local Players = nil

pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local UIS = nil
pcall(function() UIS = game:GetService("UserInputService") end)
local lplr = Players.LocalPlayer

if not BS.Win then warn("[Combat] BS.Win not available - ui.lua may have failed") return end
local page = nil
pcall(function() page = BS.Win:Tab("自瞄") end)
if not page then warn("[Combat] Failed to create tab!") return end
if not page or not page.Toggle then
    warn("[Combat] Failed to create tab!")
    -- return
end

 -- Performance shortcuts
local function alive()
    return BS.alive and BS.alive()
end
local function hrp()
    return BS.hrp and BS.hrp()
end
local function hum()
    return BS.hum and BS.hum()
end

-- Compat layer for Drawing/mouse APIs
local Compat = _G.BS and _G.BS.Compat
local function safeDrawingNew(class)
    if Compat and Compat.DrawingNew then return Compat.DrawingNew(class) end
    local s, r = pcall(function() return Drawing.new(class) end)
    return s and r or nil
end
local function safeMouseRel(x, y)
    if Compat and Compat.MouseMoveRel then Compat.MouseMoveRel(x, y) return end
    pcall(function() mousemoverel(x, y) end)
end
local function safeMouse1Click()
    if Compat and Compat.Mouse1Click then Compat.Mouse1Click() return end
    pcall(function() mouse1click() end)
end

-- ====================================================================
-- FIRE SIMULATION SYSTEM
-- Handles actual weapon firing via tool:Activate() + fallback methods
-- ====================================================================

local FireState = {
    LastFireTime = 0,
    IsFiring = false,
    FireQueue = 0,
    ShotsFired = 0,
    BurstRemaining = 0,
}
BS.FireState = FireState

-- Weapon fire rate data (seconds between shots)
local WEAPON_FIRE_RATE = {
    -- Rifles
    ak = 0.1, m4 = 0.09, m4a1 = 0.09, galil = 0.09, famas = 0.09,
    aug = 0.09, sg = 0.09, aug = 0.09, scar = 0.09,
    -- SMGs
    mp9 = 0.07, mac = 0.075, ump = 0.09, mp5 = 0.08,
    p90 = 0.068, bizon = 0.08, mp7 = 0.08,
    -- Pistols
    glock = 0.15, usp = 0.17, p250 = 0.15, deagle = 0.45,
    five = 0.15, tec = 0.13, cz = 0.09, dual = 0.12,
    rev = 0.58, p2000 = 0.17,
    -- Snipers
    awp = 1.46, scout = 1.25, auto = 0.15, g3sg = 0.15, ssg = 1.25,
    -- Shotguns
    nova = 0.88, xm = 0.75, mag7 = 0.85, sawed = 0.85,
    -- Heavy
    negev = 0.065, m249 = 0.08,
    -- Melee
    knife = 0.4, bayonet = 0.4, default = 0.4,
}

-- Get fire rate for current weapon
local function getWeaponFireRate()
    local tool = BS.tool and BS.tool()
    if not tool then return 0.1 end
    local name = tool.Name:lower()
    for key, rate in pairs(WEAPON_FIRE_RATE) do
        if name:find(key) then return rate end
    end
    -- Fallback: detect by weapon type
    local wtype = BS.weaponType and BS.weaponType() or "other"
    if wtype == "sniper" then return 1.3
    elseif wtype == "shotgun" then return 0.8
    elseif wtype == "smg" then return 0.08
    elseif wtype == "rifle" then return 0.09
    elseif wtype == "pistol" then return 0.15
    else return 0.1 end
end

-- Core fire function: tries multiple methods for maximum compatibility
local function fireWeapon()
    local now = tick()
    local fireRate = getWeaponFireRate()

    -- Rate limiting: don't fire faster than weapon allows
    if now - FireState.LastFireTime < fireRate then
        return false
    end

    -- Don't fire if already firing (prevent stacking)
    if FireState.IsFiring then return false end
    FireState.IsFiring = true
    FireState.LastFireTime = now

    local success = false

    -- Method 1: tool:Activate() — standard Roblox tool firing
    pcall(function()
        local tool = lplr.Character and lplr.Character:FindFirstChildWhichIsA("Tool")
        if tool then
            -- Check if tool has a RemoteEvent for firing
            local fireRemote = tool:FindFirstChild("FireRemote")
                or tool:FindFirstChild("RemoteEvent")
                or tool:FindFirstChild("Fire")
                or tool:FindFirstChild("Shoot")
                or tool:FindFirstChild("GunFire")

            if fireRemote then
                -- Direct remote fire (most reliable)
                local targetPos = nil
                pcall(function()
                    local cam = workspace.CurrentCamera
                    local mousePos = UIS:GetMouseLocation()
                    local ray = cam:ViewportPointToRay(mousePos.X, mousePos.Y)
                    targetPos = ray.Origin + ray.Direction * 1000
                end)

                if fireRemote:IsA("RemoteEvent") then
                    if targetPos then
                        fireRemote:FireServer(targetPos)
                    else
                        fireRemote:FireServer()
                    end
                    success = true
                elseif fireRemote:IsA("RemoteFunction") then
                    if targetPos then
                        fireRemote:InvokeServer(targetPos)
                    else
                        fireRemote:InvokeServer()
                    end
                    success = true
                end
            end

            -- Method 1b: tool:Activate() as fallback
            if not success then
                tool:Activate()
                success = true
            end
        end
    end)

    -- Method 2: mouse1click() — executor-level mouse simulation
    if not success then
        pcall(function()
            safeMouse1Click()
            success = true
        end)
    end

    -- Method 3: firesignal / fireclickdetector for specific tool types
    if not success then
        pcall(function()
            local tool = lplr.Character and lplr.Character:FindFirstChildWhichIsA("Tool")
            if tool then
                local handle = tool:FindFirstChild("Handle")
                if handle then
                    -- Try to find and fire any clickable parts
                    local clickDetector = handle:FindFirstChildWhichIsA("ClickDetector")
                    if clickDetector and fireclickdetector then
                        fireclickdetector(clickDetector)
                        success = true
                    end
                end
            end
        end)
    end

    -- Track shots
    FireState.ShotsFired = FireState.ShotsFired + 1
    if BS.HUD and BS.HUD.trackShot then
        BS.HUD.trackShot()
    end

    -- Reset firing state after a tick
    task.delay(0.01, function()
        FireState.IsFiring = false
    end)

    return success
end

-- Burst fire helper
local function fireBurst(count, burstDelay)
    count = count or 3
    burstDelay = burstDelay or 0.03
    FireState.BurstRemaining = count

    task.spawn(function()
        for i = 1, count do
            if FireState.BurstRemaining <= 0 then break end
            fireWeapon()
            FireState.BurstRemaining = FireState.BurstRemaining - 1
            if i < count then task.wait(burstDelay) end
        end
        FireState.BurstRemaining = 0
    end)
end

-- Expose fire API
BS.FireWeapon = fireWeapon
BS.FireBurst = fireBurst
BS.GetWeaponFireRate = getWeaponFireRate

-- 0. WALLBANG (子彈穿牆)

page:Label(" Wallbang ")
page:Toggle("子彈穿牆", false, function(v) Flags.Wallbang = v end)
page:Slider("穿牆深度", 1, 5, 1, function(v) Flags.WallbangPen = v end)
page:Toggle("自動偵測牆壁厚度", true, function(v) Flags.WallbangAuto = v end)
page:Toggle("穿牆伤害衰减", true, function(v) Flags.WallbangDmgFall = v end)
page:Toggle("穿牆顯示", false, function(v) Flags.WallbangESP = v end)
page:Separator()

-- Wallbang Engine: calculates wall penetration for each shot
local WallbangEngine = {}
BS.Wallbang = WallbangEngine

-- Per-weapon penetration multipliers (higher = better penetration)
local WEAPON_PENETRATION = {
    -- Rifles (high penetration)
    ["ak47"] = 1.0, ["m4a4"] = 0.9, ["m4a1"] = 0.85, ["galil"] = 0.8,
    ["famas"] = 0.75, ["sg553"] = 0.9, ["aug"] = 0.9,
    -- Snipers (very high)
    ["awp"] = 1.0, ["scout"] = 0.9, ["sg556"] = 0.85, ["g3sg1"] = 1.0,
    ["scar20"] = 1.0, ["ssg08"] = 0.9,
    -- SMGs (medium)
    ["mp9"] = 0.5, ["mac10"] = 0.5, ["mp7"] = 0.55, ["ump45"] = 0.5,
    ["p90"] = 0.45, ["bizon"] = 0.4,
    -- Pistols (low)
    ["glock"] = 0.3, ["usp"] = 0.35, ["p250"] = 0.35, ["deagle"] = 0.65,
    ["five7"] = 0.4, ["tec9"] = 0.35, ["cz75"] = 0.4, ["dualberetta"] = 0.3,
    -- Shotguns (very low)
    ["nova"] = 0.2, ["xm1014"] = 0.2, ["mag7"] = 0.25, ["sawedoff"] = 0.2,
    -- Default
    default = 0.5,
}

--- Get weapon penetration value (0-1)
function WallbangEngine.getWeaponPen()
    local tool = BS.tool and BS.tool()
    if not tool then return WEAPON_PENETRATION.default end
    local name = tool.Name:lower():gsub("%s+", "")
    return WEAPON_PENETRATION[name] or WEAPON_PENETRATION.default
end

--- Calculate wall thickness between two points by raycasting through walls
--- Returns: thickness (studs), wallCount (number of walls hit)
function WallbangEngine.measureWall(origin, direction, maxDist)
    if not Flags.WallbangAuto then
        return Flags.WallbangPen or 1, 0
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {lplr.Character}

    local totalThickness = 0
    local wallCount = 0
    local currentOrigin = origin
    local remaining = maxDist or 200
    local maxWalls = Flags.WallbangPen or 1

    -- Raycast through walls to measure total thickness
    while wallCount < maxWalls and remaining > 0 do
        local result = workspace:Raycast(currentOrigin, direction.Unit * remaining, params)
        if not result or not result.Instance then break end

        -- Skip non-wall parts (players, tools, etc.)
        local inst = result.Instance
        if inst:IsA("BasePart") and not inst:IsDescendantOf(lplr.Character) then
            local thickness = (result.Position - currentOrigin).Magnitude
            totalThickness = totalThickness + thickness
            wallCount = wallCount + 1

            -- Move origin past this wall
            currentOrigin = result.Position + direction.Unit * 0.1
            remaining = remaining - thickness - 0.1
        else
            break
        end
    end

    return totalThickness, wallCount
end

--- Check if a shot can penetrate to hit the target
--- Returns: canPenetrate, damageMultiplier
function WallbangEngine.canPenetrate(origin, targetPos)
    if not Flags.Wallbang then return true, 1 end

    local direction = (targetPos - origin)
    local dist = direction.Magnitude
    local thickness, wallCount = WallbangEngine.measureWall(origin, direction, dist)

    if wallCount == 0 then
        -- No walls: full damage
        return true, 1
    end

    -- Get weapon penetration ability
    local weaponPen = WallbangEngine.getWeaponPen()
    local maxPen = (Flags.WallbangPen or 1) * 20 * weaponPen -- max penetrable thickness in studs

    if thickness > maxPen then
        -- Wall too thick for this weapon
        return false, 0
    end

    -- Damage falloff: more walls / thicker walls = less damage
    local dmgMult = 1.0
    if Flags.WallbangDmgFall then
        dmgMult = math.clamp(1 - (thickness / maxPen) * 0.5, 0.3, 1.0)
        dmgMult = dmgMult * (1 - (wallCount - 1) * 0.15) -- extra penalty per extra wall
        dmgMult = math.clamp(dmgMult, 0.2, 1.0)
    end

    return true, dmgMult
end

-- 1. AIMBOT (Enhanced v2.0  30+ options)

page:Label(" Aimbot ")
page:Toggle("自瞄", false, function(v) Flags.Aimbot = v end)
page:Slider("自瞄視野", 10, 360, 60, function(v) Flags.AimbotFOV = v end)
page:Slider("自瞄平滑", 1, 50, 5, function(v) Flags.AimbotSmooth = v end)
page:Dropdown({Name="自瞄骨骼", Flag="AimbotBone", Options={"頭部","胸部","最近","骨盆","腹部","自動"}, Default="Head"})
page:Dropdown({Name="自瞄排序", Flag="AimSort", Options={"十字準星","距離","血量","威脅","隨機"}, Default="Crosshair"})
page:Dropdown({Name="自瞄平滑風格", Flag="AimSmoothStyle", Options={"線性","淡入","淡出","貝塞爾","自適應"}, Default="Linear"})
page:Slider("自瞄最小平滑", 1, 30, 3, function(v) Flags.AimMinSmooth = v end)
page:Toggle("自瞄隊友檢查", true, function(v) Flags.AimbotTeamCheck = v end)
page:Toggle("自瞄好友檢查", true, function(v) Flags.AimbotFriend = v end)
page:Toggle("自瞄穿牆檢查", true, function(v) Flags.AimbotWall = v end)
page:Toggle("自瞄可視檢查", true, function(v) Flags.AimbotVis = v end)
page:Toggle("自瞄預測", true, function(v) Flags.AimbotPredict = v end)
page:Slider("自瞄預測因子", 5, 100, 40, function(v) Flags.AimPredF = v end)
page:Toggle("自瞄延遲補償", false, function(v) Flags.AimLagComp = v end)
page:Slider("自瞄延遲刻度", 1, 16, 8, function(v) Flags.AimLagTicks = v end)
page:Label(" Aimbot Advanced ")
page:Toggle("自瞄按鍵綁定", false, function(v) Flags.AimKeybind = v end)
page:Dropdown({Name="自瞄按鍵", Flag="AimKey", Options={"左Alt","左Ctrl","滑鼠4","滑鼠5","Shift"}, Default="左Alt"})
page:Toggle("自瞄鎖定", false, function(v) Flags.AimLock = v end)
page:Slider("Aim Lock Duration", 100, 3000, 500, function(v) Flags.AimLockDur = v end)
page:Toggle("自瞄人性化", false, function(v) Flags.AimHumanize = v end)
page:Slider("Humanize Delay", 0, 100, 20, function(v) Flags.AimHDelay = v end)
page:Slider("Humanize Deviation", 0, 50, 10, function(v) Flags.AimHDev = v end)
page:Toggle("自瞄自動急停", false, function(v) Flags.AimAutoStop = v end)
page:Toggle("自瞄自動開鏡", false, function(v) Flags.AimAutoScope = v end)
page:Toggle("自瞄自動蹲", false, function(v) Flags.AimAutoCrouch = v end)
page:Toggle("自瞄視野圈", false, function(v) Flags.AimFovCircle = v end)
page:Toggle("自瞄目標線", false, function(v) Flags.AimTargetLine = v end)
page:Toggle("自瞄目標資訊", false, function(v) Flags.AimTargetInfo = v end)
page:Toggle("靜默自瞄", false, function(v) Flags.AimSilent = v end)
page:Label(" Aimbot Expert ")
page:Toggle("自瞄甩槍", false, function(v) Flags.AimFlick = v end)
page:Slider("Flick Speed", 1, 30, 15, function(v) Flags.AimFlickSpd = v end)
page:Toggle("自瞄抖動", false, function(v) Flags.AimJitter = v end)
page:Slider("Jitter Amount", 1, 30, 5, function(v) Flags.AimJitterAmt = v end)
page:Slider("Jitter Speed", 1, 20, 10, function(v) Flags.AimJitterSpd = v end)
page:Toggle("自瞄目標切換", false, function(v) Flags.AimTargetSwitch = v end)
page:Slider("Switch Delay", 50, 1000, 200, function(v) Flags.AimSwitchDelay = v end)
page:Toggle("自瞄距離縮放", false, function(v) Flags.AimDistScale = v end)
page:Slider("Dist Scale Min", 1, 20, 3, function(v) Flags.AimDistMin = v end)
page:Slider("Dist Scale Max", 5, 50, 10, function(v) Flags.AimDistMax = v end)
page:Toggle("自瞄血量優先", false, function(v) Flags.AimHealthPri = v end)
page:Slider("Health Weight", 1, 10, 5, function(v) Flags.AimHealthW = v end)
page:Toggle("自瞄擊退", false, function(v) Flags.AimKnockback = v end)
page:Slider("Knockback Strength", 1, 20, 8, function(v) Flags.AimKnockStr = v end)
page:Toggle("自瞄按鍵觸發", false, function(v) Flags.AimTriggerKey = v end)
page:Dropdown({Name="Trigger Key", Flag="AimTriggerKeyBind", Options={"Mouse1","Mouse2","滑鼠4","滑鼠5"}, Default="Mouse1"})
page:Label("Flick:  | Jitter: ")
page:Label("Dist Scale: ")
page:Label("Health Pri: ")

 -- Aimbot State
local aimTarget = nil
local aimLockEnd = 0
local aimFovCircle = nil
local aimTargetLine = nil
local aimFlickTime = 0

 -- Aimbot Key Map
local AimKeyMap = {
    ["左Alt"] = Enum.KeyCode.LeftAlt,
    ["左Ctrl"] = Enum.KeyCode.LeftControl,
    ["滑鼠4"] = Enum.UserInputType.MouseButton4,
    ["滑鼠5"] = Enum.UserInputType.MouseButton5,
    ["Shift"] = Enum.KeyCode.LeftShift,
}

local function isAimKeyDown()
    if not Flags.AimKeybind then return true end
    local key = AimKeyMap[Flags.AimKey or "Left Alt"]
    if not key then return false end
    if key.EnumType == Enum.UserInputType then
        return UIS:IsMouseButtonPressed(key)
    else
        return UIS:IsKeyDown(key)
    end
end

 -- Smooth Calculation (with Ping Adapt)
local function calcSmooth(baseSmooth, style, dist)
    -- Apply ping adaptation
    if Flags.PingAdapt and BS.PA then
        baseSmooth = BS.PA.getAdaptSmooth(baseSmooth)
    end
    if style == "Ease In" then
        return baseSmooth * (1 + dist * 0.002)
    elseif style == "Ease Out" then
        return baseSmooth * (1 / (1 + dist * 0.001))
    elseif style == "Bezier" then
        local t = math.clamp(dist / 200, 0, 1)
        return baseSmooth * (1 + t * t * 0.5)
    elseif style == "Adaptive" then
        local minS = Flags.AimMinSmooth or 3
        if dist < 50 then return minS
        elseif dist < 150 then return baseSmooth * 0.7
        else return baseSmooth end
    end
    return baseSmooth
end

 -- Aimbot Engine (v2.0)
task.spawn(function()
    while task.wait() do
        if Flags.Aimbot and alive() then
            local ok, err = pcall(function()
                local cam = workspace.CurrentCamera
                if not cam then return end
                local mouseOk, mouse = pcall(function() return UIS:GetMouseLocation() end)
                if not mouseOk or not mouse then return end
                local myHrp = hrp()
                if not myHrp then return end

                -- Keybind check
                if not isAimKeyDown() then
                    if aimLockEnd > 0 and tick() < aimLockEnd then
                        -- Aim lock active, keep aiming
                    else
                        aimTarget = nil
                        return
                    end
                end

                local bone = Flags.AimbotBone or "Head"
                local sort = Flags.AimSort or "Crosshair"
                if not myHrp then return end
                local myPos = myHrp.Position
                local candidates = {}

                -- Find all valid targets
                local enemyList = {}
                pcall(function() enemyList = BS.enemies and BS.enemies() or {} end)
                for _, e in pairs(enemyList) do
                    if not e or type(e) ~= 'table' then continue end
                    if not e.HRP or not e.Hum or e.Hum.Health <= 0 then continue end
                    if Flags.AimbotTeamCheck and lplr.Team and e.Player.Team == lplr.Team then continue end
                    if Flags.AimbotFriend and lplr:IsFriendsWith(e.Player.UserId) then continue end

                    local aimPos = nil
                    if bone == "Head" then
                        aimPos = e.Head and e.Head.Position or e.HRP.Position + Vector3.new(0, 1.5, 0)
                    elseif bone == "Chest" then
                        aimPos = e.HRP.Position + Vector3.new(0, 0.5, 0)
                    elseif bone == "Pelvis" then
                        aimPos = e.HRP.Position + Vector3.new(0, 0.1, 0)
                    elseif bone == "Stomach" then
                        aimPos = e.HRP.Position + Vector3.new(0, 0.3, 0)
                    elseif bone == "Nearest" then
                        local candidates2 = {
                            e.Head and e.Head.Position or e.HRP.Position + Vector3.new(0, 1.5, 0),
                            e.HRP.Position + Vector3.new(0, 0.5, 0),
                            e.HRP.Position,
                        }
                        local bestB, bestBD = candidates2[1], math.huge
                        for _, bp in ipairs(candidates2) do
                            local sp, sv = cam:WorldToViewportPoint(bp)
                            if sv then local d = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude; if d < bestBD then bestBD = d; bestB = bp end end
                        end
                        aimPos = bestB
                    elseif bone == "Auto" then
                        local headPos = e.Head and e.Head.Position or e.HRP.Position + Vector3.new(0, 1.5, 0)
                        local bodyPos = e.HRP.Position + Vector3.new(0, 0.5, 0)
                        if BS.hasLineOfSight(myPos, headPos) then aimPos = headPos else aimPos = bodyPos end
                    end
                    if not aimPos then continue end

                    if Flags.AimbotVis and not BS.hasLineOfSight(myPos, aimPos) then
                        if not Flags.Wallbang then continue end
                        local canPen = WallbangEngine.canPenetrate(myPos, aimPos)
                        if not canPen then continue end
                    end
                    if Flags.AimbotWall and e.Head and not BS.hasLineOfSight(myPos, e.Head.Position) then
                        if not Flags.Wallbang then continue end
                        local canPen2 = WallbangEngine.canPenetrate(myPos, e.Head.Position)
                        if not canPen2 then continue end
                    end

                    local pos, vis = cam:WorldToViewportPoint(aimPos)
                    if not vis then continue end
                    local screenDist = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                    local realDist = (myPos - e.HRP.Position).Magnitude
                    local threat = (1 / math.max(realDist, 1)) * 100 + (100 - e.Hum.Health) * 0.5
                    if screenDist < 50 then threat = threat + 50 end

                    table.insert(candidates, {
                        Enemy = e, AimPos = aimPos, ScreenDist = screenDist,
                        RealDist = realDist, Health = e.Hum.Health, Threat = threat,
                    })
                    -- ::aimSkip::
                end

                -- Sort
                if sort == "Crosshair" then table.sort(candidates, function(a, b) return a.ScreenDist < b.ScreenDist end)
                elseif sort == "Distance" then table.sort(candidates, function(a, b) return a.RealDist < b.RealDist end)
                elseif sort == "Health" then table.sort(candidates, function(a, b) return a.Health < b.Health end)
                elseif sort == "Threat" then table.sort(candidates, function(a, b) return a.Threat > b.Threat end)
                elseif sort == "Random" then for i = #candidates, 2, -1 do local j = math.random(i); candidates[i], candidates[j] = candidates[j], candidates[i] end end

                -- Pick best in FOV
                local best = nil
                for _, c in ipairs(candidates) do
                    if c.ScreenDist <= (Flags.AimbotFOV or 60) then
                        best = c
                        break
                    end
                end

                -- Aim Lock: keep target for duration
                if Flags.AimLock and aimTarget and tick() < aimLockEnd then
                    best = aimTarget
                elseif best then
                    aimTarget = best
                    if Flags.AimLock then
                        aimLockEnd = tick() + (Flags.AimLockDur or 500) / 1000
                    end
                end

                -- ::renderAim::
                if best then
                    -- Prediction (with Ping Adapt)
                    local targetPos = best.AimPos
                    if Flags.AimbotPredict then
                        local vel = BS.getVelocity(best.Enemy)
                        local pf = (Flags.AimPredF or 40) / 100
                        if Flags.PingAdapt and BS.PA then
                            pf = BS.PA.getAdaptPrediction(40) / 100
                        end
                        targetPos = targetPos + vel * pf
                    end
                    -- Lag compensation (with Ping Adapt)
                    if Flags.AimLagComp then
                        local vel = BS.getVelocity(best.Enemy)
                        local lagTicks = Flags.AimLagTicks or 8
                        if Flags.PingAdapt and BS.PA then
                            lagTicks = BS.PA.getAdaptLagTicks()
                        end
                        targetPos = targetPos + vel * (lagTicks * 0.015)
                    end
                    -- Humanize: add random deviation
                    if Flags.AimHumanize then
                        local dev = (Flags.AimHDev or 10) / 100
                        targetPos = targetPos + Vector3.new(
                            (math.random() - 0.5) * dev,
                            (math.random() - 0.5) * dev,
                            (math.random() - 0.5) * dev
                        )
                    end
                    -- Apply aim
                    local camPos = cam.CFrame.Position
                    local targetDir = (targetPos - camPos).Unit
                    local smooth = calcSmooth(Flags.AimbotSmooth or 5, Flags.AimSmoothStyle or "線性", best.ScreenDist)
                    local targetCF = CFrame.new(camPos, camPos + targetDir)
                    cam.CFrame = cam.CFrame:Lerp(targetCF, 1 / smooth)
                    -- Auto Stop
                    if Flags.AimAutoStop then
                        local h = hum()
                        if h then h.WalkSpeed = 0 end
                    end
                    -- Auto Scope
                    if Flags.AimAutoScope then
                        local t = lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
                        if t and (t.Name:lower():find("awp") or t.Name:lower():find("sniper")) then
                            safeMouse1Click()
                        end
                    end
                    -- Auto Crouch
                    if Flags.AimAutoCrouch then
                        local h = hum()
                        if h then h.HipHeight = -0.5 end
                    end
                else
                    -- Restore crouch
                    if Flags.AimAutoCrouch then
                        local h = hum()
                        if h then h.HipHeight = 0 end
                    end
                    if Flags.AimAutoStop then
                        local h = hum()
                        if h then h.WalkSpeed = 16 end
                    end
                end

                -- FOV Circle
                if Flags.AimFovCircle then
                    if not aimFovCircle then
                        aimFovCircle = safeDrawingNew("Circle")
                        if aimFovCircle then aimFovCircle.Thickness = 1; aimFovCircle.NumSides = 64; aimFovCircle.Filled = false end
                    end
                    if aimFovCircle then
                        aimFovCircle.Position = mouse
                        aimFovCircle.Radius = Flags.AimbotFOV or 60
                        aimFovCircle.Color = Color3.fromRGB(0, 200, 255)
                        aimFovCircle.Visible = true
                    end
                else
                    if aimFovCircle then aimFovCircle.Visible = false end
                end

                -- Target Line
                if Flags.AimTargetLine and best then
                    local sp, sv = cam:WorldToViewportPoint(targetPos)
                    if sv then
                        if not aimTargetLine then
                            aimTargetLine = safeDrawingNew("Line")
                            if aimTargetLine then aimTargetLine.Thickness = 1 end
                        end
                        if aimTargetLine then
                            aimTargetLine.From = mouse
                            aimTargetLine.To = Vector2.new(sp.X, sp.Y)
                            aimTargetLine.Color = Color3.fromRGB(0, 255, 0)
                            aimTargetLine.Visible = true
                        end
                    end
                else
                    if aimTargetLine then aimTargetLine.Visible = false end
                end

                -- Target Info
                if Flags.AimTargetInfo and best then
                    -- Could draw info on screen
                end
            end)
        else
            if aimFovCircle then aimFovCircle.Visible = false end
            if aimTargetLine then aimTargetLine.Visible = false end
        end
    end
end)

 -- Expert Aim Features
task.spawn(function()
    while task.wait() do
        if Flags.Aimbot and alive() then
            pcall(function()
                -- Flick: fast snap to target
                if Flags.AimFlick and aimTarget then
                    local cam = workspace.CurrentCamera
                    local flickSpd = Flags.AimFlickSpd or 15
                    local targetDir = (aimTarget.AimPos - cam.CFrame.Position).Unit
                    local targetCF = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + targetDir)
                    cam.CFrame = cam.CFrame:Lerp(targetCF, flickSpd / 50)
                end

                -- Jitter: add random camera shake
                if Flags.AimJitter and aimTarget then
                    local cam = workspace.CurrentCamera
                    local jitterAmt = (Flags.AimJitterAmt or 5) / 1000
                    local jitterSpd = Flags.AimJitterSpd or 10
                    local jX = math.sin(tick() * jitterSpd * 10) * jitterAmt
                    local jY = math.cos(tick() * jitterSpd * 7) * jitterAmt
                    cam.CFrame = cam.CFrame * CFrame.new(jX, jY, 0)
                end

                -- Target Switch: limit how fast we switch targets
                if Flags.AimTargetSwitch then
                    local delay = (Flags.AimSwitchDelay or 200) / 1000
                    if aimTarget and tick() - aimFlickTime < delay then
                        -- Keep aiming at same target
                    end
                end

                -- Distance Scale: adjust smooth based on distance
                if Flags.AimDistScale and aimTarget then
                    local cam = workspace.CurrentCamera
                    local dist = (cam.CFrame.Position - aimTarget.AimPos).Magnitude
                    local minS = Flags.AimDistMin or 3
                    local maxS = Flags.AimDistMax or 10
                    local scaledSmooth = minS + (maxS - minS) * math.clamp(dist / 200, 0, 1)
                    local targetDir = (aimTarget.AimPos - cam.CFrame.Position).Unit
                    local targetCF = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + targetDir)
                    cam.CFrame = cam.CFrame:Lerp(targetCF, 1 / scaledSmooth)
                end

                -- Health Priority: aim at lowest HP enemy
                if Flags.AimHealthPri and aimTarget then
                    local cam = workspace.CurrentCamera
                    local healthWeight = (Flags.AimHealthW or 5) / 10
                    local healthOffset = (100 - aimTarget.Health) * healthWeight * 0.001
                    local targetDir = (aimTarget.AimPos - cam.CFrame.Position).Unit
                    local targetCF = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + targetDir)
                    cam.CFrame = cam.CFrame:Lerp(targetCF, 1 / (5 - healthOffset * 4))
                end

                -- Knockback: push aim slightly on hit
                if Flags.AimKnockback and aimTarget then
                    local cam = workspace.CurrentCamera
                    local knockStr = (Flags.AimKnockStr or 8) / 1000
                    local knock = CFrame.new(0, knockStr, 0)
                    cam.CFrame = cam.CFrame * knock
                end
            end)
        end
    end
end)

-- 2. TRIGGER BOT (Enhanced v2.0)

page:Label(" Trigger Bot ")
page:Toggle("觸發器", false, function(v) Flags.TriggerBot = v end)
page:Slider("TB Min Delay", 0, 200, 30, function(v) Flags.TBMinDelay = v end)
page:Slider("TB Max Delay", 50, 400, 120, function(v) Flags.TBMaxDelay = v end)
page:Toggle("觸發器僅按鍵", false, function(v) Flags.TBKeybind = v end)
page:Dropdown({Name="TB Key", Flag="TBKey", Options={"左Ctrl","滑鼠4","滑鼠5","V"}, Default="Left Ctrl"})
page:Toggle("觸發器僅爆頭", false, function(v) Flags.TBHeadOnly = v end)
page:Toggle("觸發器僅身體", false, function(v) Flags.TBBodyOnly = v end)
page:Toggle("觸發器隊友檢查", true, function(v) Flags.TBTeamCheck = v end)
page:Toggle("觸發器穿牆檢查", true, function(v) Flags.TBWallCheck = v end)
page:Toggle("觸發器連射模式", false, function(v) Flags.TBBurst = v end)
page:Slider("TB Burst Count", 2, 10, 3, function(v) Flags.TBBurstCount = v end)
page:Slider("TB Burst Delay", 10, 100, 30, function(v) Flags.TBBurstDelay = v end)
page:Toggle("觸發器正常隨機", false, function(v) Flags.TBLegitRand = v end)
page:Slider("TB Legit Chance", 10, 100, 70, function(v) Flags.TBLegitChance = v end)
page:Toggle("觸發器視野檢查", false, function(v) Flags.TBFovCheck = v end)
page:Slider("TB FOV", 10, 180, 30, function(v) Flags.TBFov = v end)

 -- Triggerbot State
local tbBurstShots = 0
local tbLastBurst = 0

local TBKeyMap = {
    ["左Ctrl"] = Enum.KeyCode.LeftControl,
    ["滑鼠4"] = Enum.UserInputType.MouseButton4,
    ["滑鼠5"] = Enum.UserInputType.MouseButton5,
    ["V"] = Enum.KeyCode.V,
}

task.spawn(function()
    while task.wait() do
        if Flags.TriggerBot and alive() then
            -- Keybind check
            if Flags.TBKeybind then
                local key = TBKeyMap[Flags.TBKey or "Left Ctrl"]
                if key then
                    if key.EnumType == Enum.UserInputType then
                        if not UIS:IsMouseButtonPressed(key) then continue end
                    else
                        if not UIS:IsKeyDown(key) then continue end
                    end
                end
            end

            -- Burst mode
            if Flags.TBBurst then
                if tbBurstShots >= (Flags.TBBurstCount or 3) then
                    if tick() - tbLastBurst < (Flags.TBBurstDelay or 30) / 1000 then continue end
                    tbBurstShots = 0
                end
            end

            -- Legit random
            if Flags.TBLegitRand then
                if math.random(1, 100) > (Flags.TBLegitChance or 70) then continue end
            end

            pcall(function()
                local cam = workspace.CurrentCamera
                local mousePos = UIS:GetMouseLocation()
                local myHrp = hrp()
                -- Use Raycast from camera for reliable target detection on all executors
                local ray = cam:ViewportPointToRay(mousePos.X, mousePos.Y)
                local rayParams = RaycastParams.new()
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                rayParams.FilterDescendantsInstances = {lplr.Character}
                local rayResult = workspace:Raycast(ray.Origin, ray.Direction * 500, rayParams)
                local mouseTarget = rayResult and rayResult.Instance
                if not cam or not mouseTarget or not myHrp then return end

                for _, e in pairs(BS.enemies and BS.enemies() or {}) do
                    if e.Char and mouseTarget:IsDescendantOf(e.Char) then
                        -- Team check
                        if Flags.TBTeamCheck and lplr.Team and e.Player.Team == lplr.Team then continue end
                        -- Headshot only
                        if Flags.TBHeadOnly and e.Head and mouseTarget ~= e.Head then continue end
                        -- Body only
                        if Flags.TBBodyOnly and mouseTarget ~= e.HRP then continue end
                        -- Wall check
                        if Flags.TBWallCheck and e.Head and not BS.hasLineOfSight(myHrp.Position, e.Head.Position) then
                            if not Flags.Wallbang then continue end
                            -- Wallbang: check if we can penetrate this wall
                            local canPen, dmgMult = WallbangEngine.canPenetrate(myHrp.Position, e.Head.Position)
                            if not canPen then continue end
                        end
                        -- FOV check
                        if Flags.TBFovCheck then
                            local pos, vis = cam:WorldToViewportPoint(e.HRP.Position)
                            if vis then
                                local sd = (Vector2.new(pos.X, pos.Y) - UIS:GetMouseLocation()).Magnitude
                                if sd > (Flags.TBFov or 30) then continue end
                            end
                        end

                        -- Random delay (with Ping Adapt)
                        local minD = (Flags.TBMinDelay or 30) / 1000
                        local maxD = (Flags.TBMaxDelay or 120) / 1000
                        if Flags.PingAdapt and BS.PA then
                            local adapted = BS.PA.getAdaptTriggerDelay(Flags.TBMinDelay or 30, Flags.TBMaxDelay or 120)
                            minD = adapted / 1000
                            maxD = minD * 1.5
                        end
                        local delay = minD + math.random() * (maxD - minD)
                        task.wait(delay)

                        -- Fire using the new fire simulation system
                        local tool = lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
                        if tool and not tool.Name:lower():find("knife") then
                            if Flags.TBBurst then
                                -- Burst fire mode
                                fireBurst(Flags.TBBurstCount or 3, (Flags.TBBurstDelay or 30) / 1000)
                            else
                                -- Single shot
                                fireWeapon()
                            end
                            tbBurstShots = tbBurstShots + 1
                            tbLastBurst = tick()
                        end
                        break
                    end
                    -- ::continue_tb::
                end
            end)
        end
        -- ::skip_tb::
    end
end)

-- 3. SILENT AIM (Server-Side Angle Manipulation)

page:Toggle("靜默瞄準", false, function(v) Flags.SilentAim = v end)
page:Slider("SA FOV", 10, 180, 90, function(v) Flags.SAFOV = v end)
page:Toggle("靜瞄爆頭", false, function(v) Flags.SAHeadshot = v end)
page:Toggle("靜瞄穿牆檢查", true, function(v) Flags.SAWall = v end)

-- Silent Aim Engine (server-side angle manipulation via metatable hook)
local silentTarget = nil
local oldNamecall

-- Setup silent aim hook once
local function setupSilentAimHook()
    if oldNamecall then return end -- already hooked
    if not (Compat and Compat.Features and Compat.Features.HookMetamethod) then return end
    
    pcall(function()
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" and silentTarget and Flags.SilentAim then
                local args = {...}
                -- Intercept remote fire and redirect aim position
                if #args > 0 and typeof(args[1]) == "Vector3" then
                    local aimPos = Flags.SAHeadshot
                        and (silentTarget.Head and silentTarget.Head.Position or silentTarget.HRP.Position + Vector3.new(0, 1.5, 0))
                        or silentTarget.HRP.Position
                    args[1] = aimPos
                    return oldNamecall(self, unpack(args))
                end
            end
            return oldNamecall(self, ...)
        end))
    end)
end

-- Find best silent aim target each frame
task.spawn(function()
    while task.wait() do
        if Flags.SilentAim and alive() then
            pcall(function()
                setupSilentAimHook() -- ensure hook is active
                local cam = workspace.CurrentCamera
                local myHrp = hrp()
                if not cam or not myHrp then return end

                local mousePos = UIS:GetMouseLocation()
                local saFov = Flags.SAFOV or 90
                if Flags.PingAdapt and BS.PA then
                    saFov = BS.PA.getAdaptSilentRange(saFov)
                end
                local best, bestDist = nil, saFov
                for _, e in pairs(BS.enemies and BS.enemies() or {}) do
                    local aimPos = Flags.SAHeadshot
                        and (e.Head and e.Head.Position or e.HRP.Position + Vector3.new(0, 1.5, 0))
                        or e.HRP.Position

                    if Flags.SAWall and not BS.hasLineOfSight(myHrp.Position, aimPos) then
                        if not Flags.Wallbang then continue end
                        local canPen = WallbangEngine.canPenetrate(myHrp.Position, aimPos)
                        if not canPen then continue end
                    end
                        continue
                    end

                    local pos, vis = cam:WorldToViewportPoint(aimPos)
                    if vis then
                        local screenDist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                        if screenDist < bestDist then
                            best = e
                            bestDist = screenDist
                        end
                    end
                    -- ::continue_sa::
                end

                silentTarget = best and best.Enemy or nil
            end)
        else
            silentTarget = nil
        end
    end
end)

-- 4. RECOIL CONTROL SYSTEM (RCS)

page:Toggle("後座控制", false, function(v) Flags.RCS = v end)
page:Slider("RCS X", 0, 100, 60, function(v) Flags.RCSX = v end)
page:Slider("RCS Y", 0, 100, 80, function(v) Flags.RCSY = v end)
page:Toggle("後座控制連射", false, function(v) Flags.RCSBurst = v end)

local shotCount = 0
local isFiring = false

-- Track firing state
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isFiring = true
        shotCount = 0
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isFiring = false
        shotCount = 0
    end
end)

task.spawn(function()
    while task.wait() do
        if Flags.RCS and alive() and isFiring then
            pcall(function()
                local cam = workspace.CurrentCamera
                shotCount = shotCount + 1

                -- Recoil pattern compensation
                local weapon = BS.weaponType()
                local rcsX = (Flags.RCSX or 60) / 100
                local rcsY = (Flags.RCSY or 80) / 100

                -- Weapon-specific recoil patterns
                local recoilX, recoilY = 0, 0
                if weapon == "rifle" then
                    -- AK-style: up then right
                    if shotCount <= 5 then
                        recoilY = -0.8 * rcsY
                        recoilX = 0.2 * rcsX
                    elseif shotCount <= 15 then
                        recoilY = -0.5 * rcsY
                        recoilX = 0.4 * rcsX * math.sin(shotCount * 0.5)
                    else
                        recoilY = -0.3 * rcsY
                        recoilX = 0.5 * rcsX * math.sin(shotCount * 0.3)
                    end
                elseif weapon == "smg" then
                    recoilY = -0.4 * rcsY
                    recoilX = 0.2 * rcsX * math.sin(shotCount * 0.8)
                elseif weapon == "pistol" then
                    recoilY = -0.6 * rcsY
                    recoilX = 0.1 * rcsX * (shotCount % 2 == 0 and 1 or -1)
                else
                    recoilY = -0.5 * rcsY
                    recoilX = 0.3 * rcsX * math.sin(shotCount * 0.4)
                end

                -- Apply counter-recoil
                safeMouseRel(recoilX, math.abs(recoilY))

                -- Burst mode: pause after N shots
                if Flags.RCSBurst and shotCount >= 3 then
                    task.wait(0.1)
                    shotCount = 0
                end
            end)
        end
    end
end)

-- 5. AUTO FIRE (Hold to Auto-Shoot)

page:Toggle("自動射擊", false, function(v) Flags.AutoFire = v end)

task.spawn(function()
    while true do
        task.wait()
        if Flags.AutoFire and BS.alive and BS.alive() then
            pcall(function()
                local tool = lplr.Character and lplr.Character:FindFirstChildWhichIsA("Tool")
                if tool and not tool.Name:lower():find("knife") then
                    -- Only fire when mouse1 is held down
                    local mouse1Held = false
                    pcall(function()
                        mouse1Held = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                    end)
                    if mouse1Held then
                        fireWeapon()
                    end
                end
            end)
        end
    end
end)

-- 6. AUTO PISTOL (Fast Switch to Pistol on Empty)

page:Toggle("快速切換", false, function(v) Flags.QuickSwitch = v end)

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if Flags.QuickSwitch and input.KeyCode == Enum.KeyCode.Q then
        pcall(function()
            local tool = lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
            if tool then
                local name = tool.Name:lower()
                if name:find("knife") or name:find("bayonet") then
                    -- Switch to primary
                    pcall(function() BS.equipTool("ak") end)
                else
                    -- Switch to knife
                    pcall(function() BS.equipTool("knife") end)
                end
            end
        end)
    end
end)

-- 7. NO SPREAD

page:Toggle("無散布", false, function(v) Flags.NoSpread = v end)
page:Toggle("無後座力", false, function(v) Flags.NoRecoil = v end)

-- 8. HIT SOUND

page:Toggle("命中音效", false, function(v) Flags.HitSound = v end)
page:Slider("Hit Volume", 1, 10, 5, function(v) Flags.HitVolume = v end)

-- 9. HEADSHOT TEXT

page:Toggle("爆頭文字", false, function(v) Flags.HSText = v end)
page:Toggle("擊殺文字", false, function(v) Flags.KillText = v end)

-- 10. TEAM CHECK

page:Toggle("隊伍檢查", true, function(v) Flags.TeamCheck = v end)
page:Toggle("好友檢查", true, function(v) Flags.FriendCheck = v end)

-- 11. AIM ASSIST (Mouse Movement)

page:Toggle("瞄準輔助", false, function(v) Flags.AimAssist = v end)
page:Slider("反瞄平滑", 1, 20, 8, function(v) Flags.AASmooth = v end)
page:Slider("反瞄視野", 10, 180, 60, function(v) Flags.AAFov = v end)
page:Toggle("反瞄穿牆檢查", true, function(v) Flags.AAWall = v end)

task.spawn(function()
    while task.wait() do
        if Flags.AimAssist and alive() then
            pcall(function()
                local cam = workspace.CurrentCamera
                local mouse = UIS:GetMouseLocation()
                local myHrp = hrp()
                if not cam or not myHrp then return end

                local best, bestDist = nil, Flags.AAFov or 60
                for _, e in pairs(BS.enemies and BS.enemies() or {}) do
                    local aimPos = e.Head and e.Head.Position or e.HRP.Position + Vector3.new(0, 1.5, 0)
                    if Flags.AAWall and not BS.hasLineOfSight(myHrp.Position, aimPos) then
                        if not Flags.Wallbang then continue end
                        local canPen = WallbangEngine.canPenetrate(myHrp.Position, aimPos)
                        if not canPen then continue end
                    end
                        continue
                    end
                    local pos, vis = cam:WorldToViewportPoint(aimPos)
                    if vis then
                        local d = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                        if d < bestDist then best = e; bestDist = d end
                    end
                    -- ::continue_aa::
                end

                if best then
                    local aimPos = best.Head and best.Head.Position or best.HRP.Position + Vector3.new(0, 1.5, 0)
                    local pos = cam:WorldToViewportPoint(aimPos)
                    local aaSmooth = Flags.AASmooth or 8
                if Flags.PingAdapt and BS.PA then
                    aaSmooth = BS.PA.getAdaptSmooth(aaSmooth)
                end
                local delta = (Vector2.new(pos.X, pos.Y) - mouse) / aaSmooth
                    safeMouseRel(delta.X, delta.Y)
                end
            end)
        end
    end
end)

-- 12. AUTO KNIFE (Melee when close)

page:Toggle("自動刀人", false, function(v) Flags.AutoKnife = v end)
page:Slider("Knife Range", 2, 8, 4, function(v) Flags.KnifeRange = v end)

task.spawn(function()
    while task.wait(0.1) do
        if Flags.AutoKnife and alive() then
            pcall(function()
                local target, dist = BS.nearestEnemy(Flags.KnifeRange or 4)
                if target and dist <= (Flags.KnifeRange or 4) then
                    -- Switch to knife
                    local currentTool = lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
                    if not currentTool or not currentTool.Name:lower():find("knife") then
                        pcall(function() BS.equipTool("knife") end)
                        task.wait(0.1)
                    end
                    -- Attack
                    local tool = lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
                    if tool then tool:Activate() end
                end
            end)
        end
    end
end)

-- 13. HIT BOX EXPANDER

page:Toggle("命中框擴大", false, function(v) Flags.HitBoxExpander = v end)
page:Slider("HB Size", 1, 10, 3, function(v) Flags.HBSize = v end)

task.spawn(function()
    while task.wait(0.1) do
        if Flags.HitBoxExpander then
            for _, e in pairs(BS.enemies and BS.enemies() or {}) do
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

-- 14. AUTO DISCONNECT (on low HP)

page:Toggle("自動斷線", false, function(v) Flags.AutoDC = v end)
page:Slider("DC Health", 5, 50, 10, function(v) Flags.DCHealth = v end)

task.spawn(function()
    while task.wait(0.5) do
        if Flags.AutoDC and alive() then
            local h = hum()
            if h and h.Health <= (Flags.DCHealth or 10) then
                pcall(function()
                    game:GetService("TeleportService"):Teleport(game.PlaceId, lplr)
                end)
            end
        end
    end
end)

-- 15. NO FLASH

page:Toggle("反閃光", false, function(v) Flags.NoFlash = v end)

task.spawn(function()
    while task.wait(0.1) do
        if Flags.NoFlash then
            pcall(function()
                -- Remove screen flash effects
                for _, gui in pairs(lplr.PlayerGui:GetChildren()) do
                    if gui.Name:lower():find("flash") or gui.Name:lower():find("blind") then
                        gui.Enabled = false
                    end
                end
                -- Clear blur
                for _, effect in pairs(Lighting:GetChildren()) do
                    if effect:IsA("BlurEffect") then
                        effect.Size = 0
                    end
                end
            end)
        end
    end
end)

-- 16. AUTO BUY (Purchase weapons at round start)

page:Toggle("自動購買", false, function(v) Flags.AutoBuy = v end)
page:Dropdown({Name="購買主武器", Flag="BuyPrimary", Options={"AK-47", "M4A4", "M4A1-S", "AWP", "SG553", "AUG"}, Default="AK-47"})
page:Dropdown({Name="購買副武器", Flag="BuySecondary", Options={"Deagle", "USP-S", "Glock", "P250", "Five-SeveN"}, Default="Deagle"})
page:Toggle("購買護甲", true, function(v) Flags.BuyArmor = v end)
page:Toggle("購買拆彈包", true, function(v) Flags.BuyKit = v end)
page:Toggle("購買手榴彈", false, function(v) Flags.BuyGrenades = v end)

task.spawn(function()
    while task.wait(1) do
        if Flags.AutoBuy then
            pcall(function()
                -- Buy primary
                local primary = Flags.BuyPrimary or "AK-47"
                pcall(function() if BS.api then BS.api.buyWeapon(primary) end end)

                -- Buy secondary
                local secondary = Flags.BuySecondary or "Deagle"
                pcall(function() if BS.api then BS.api.buyWeapon(secondary) end end)

                -- Buy armor
                if Flags.BuyArmor then
                    pcall(function() if BS.api then BS.api.buyEquipment("Armor") end end)
                end

                -- Buy defuse kit (CT side)
                if Flags.BuyKit and BS.team() and BS.team().Name == "CT" then
                    pcall(function() if BS.api then BS.api.buyEquipment("Defuse Kit") end end)
                end

                -- Buy grenades
                if Flags.BuyGrenades then
                    pcall(function() if BS.api then BS.api.buyWeapon("Flashbang") end end)
                    pcall(function() if BS.api then BS.api.buyWeapon("Smoke") end end)
                    pcall(function() if BS.api then BS.api.buyWeapon("HE Grenade") end end)
                end
            end)
        end
    end
end)

-- 17. SPRINT

page:Toggle("自動衝刺", false, function(v) Flags.AutoSprint = v end)

task.spawn(function()
    while task.wait(0.2) do
        if alive() then
            local h = hum()
            if h then
                if Flags.AutoSprint then
                    h.WalkSpeed = 20
                else
                    -- Restore default speed if we changed it
                    if h.WalkSpeed == 20 then h.WalkSpeed = 16 end
                end
            end
        end
    end
end)

-- 18. NO FALL DAMAGE (see World tab for full version)

page:Toggle("無摔落", false, function(v) Flags.NoFall = v end)

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

-- 19. FORCE CROSSHAIR

page:Toggle("強制準星", false, function(v) Flags.ForceCrosshair = v end)

-- 20. ZOOM SENSITIVITY

page:Toggle("開鏡縮放調整", false, function(v) Flags.ScopeZoom = v end)
page:Slider("Zoom Multiplier", 50, 200, 100, function(v) Flags.ZoomMult = v end)

-- 21. AUTO PISTOL (Fix fire rate on semi-auto)

page:Separator()
page:Label(" Auto Pistol ")
page:Toggle("自動手槍", false, function(v) Flags.AutoPistol = v end)
page:Slider("Auto Pistol RPM", 200, 900, 400, function(v) Flags.AutoPistolRPM = v end)

-- 22. RAPID FIRE (Burst control)

page:Label(" Rapid Fire ")
page:Toggle("快速射擊", false, function(v) Flags.RapidFire = v end)
page:Slider("Rapid Burst Count", 2, 10, 3, function(v) Flags.RapidBurst = v end)
page:Slider("Rapid Burst Delay", 10, 100, 30, function(v) Flags.RapidDelay = v end)
page:Toggle("快速自動急停", false, function(v) Flags.RapidAutoStop = v end)

-- 23. HITCHANCE FILTER

page:Label(" Hitchance ")
page:Toggle("命中率過濾", false, function(v) Flags.HitchanceFilter = v end)
page:Slider("Hitchance %", 20, 100, 60, function(v) Flags.Hitchance = v end)
page:Slider("Hitchance Seed", 1, 100, 50, function(v) Flags.HCSeed = v end)

-- 24. MIN DAMAGE FILTER

page:Label(" Min Damage ")
page:Toggle("最低傷害過濾", false, function(v) Flags.MinDmgFilter = v end)
page:Slider("Min Damage", 1, 100, 20, function(v) Flags.MinDamage = v end)
page:Toggle("覆蓋爆頭最低傷害", false, function(v) Flags.HSOverrideDmg = v end)
page:Slider("Headshot Min Dmg", 1, 100, 80, function(v) Flags.HSMinDmg = v end)

-- 25. QUICK SWITCH

page:Label(" Quick Switch ")
page:Toggle("射擊後切刀", false, function(v) Flags.KnifeAfterShot = v end)
page:Slider("QS Delay (ms)", 50, 500, 150, function(v) Flags.QSDelay = v end)
page:Toggle("空彈自動換彈", false, function(v) Flags.AutoReloadEmpty = v end)


-- AUTO PISTOL Implementation
-- Fixes fire rate on semi-auto weapons
local lastAutoPistolShot = 0
task.spawn(function()
    while true do
        task.wait(0.01)
        if Flags.AutoPistol and BS.alive and BS.alive() then
            pcall(function()
                local tool = lplr.Character and lplr and lplr.Character:FindFirstChildOfClass("Tool")
                if tool and tool:FindFirstChild("RemoteEvent") then
                    local rpm = Flags.AutoPistolRPM or 400
                    local interval = 60 / rpm
                    if tick() - lastAutoPistolShot >= interval then
                        if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                            tool.RemoteEvent:FireServer((tool.Handle and tool.Handle.Position or hrp.Position), "Fire")
                            lastAutoPistolShot = tick()
                        end
                    end
                end
            end)
        end
    end
end)

-- RAPID FIRE Implementation
-- Burst fire control
local rapidBurstCount = 0
local lastRapidShot = 0
task.spawn(function()
    while true do
        task.wait(0.01)
        if Flags.RapidFire and BS.alive and BS.alive() then
            pcall(function()
                local tool = lplr.Character and lplr and lplr.Character:FindFirstChildOfClass("Tool")
                if tool and tool:FindFirstChild("RemoteEvent") then
                    local burst = Flags.RapidBurst or 3
                    local delay = (Flags.RapidDelay or 30) / 1000
                    if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                        if tick() - lastRapidShot >= delay then
                            if rapidBurstCount < burst then
                                tool.RemoteEvent:FireServer((tool.Handle and tool.Handle.Position or hrp.Position), "Fire")
                                rapidBurstCount = rapidBurstCount + 1
                                lastRapidShot = tick()
                            else
                                rapidBurstCount = 0
                                task.wait(0.1)
                            end
                        end
                    else
                        rapidBurstCount = 0
                    end
                end
            end)
        end
    end
end)

-- HITCHANCE FILTER Implementation
-- Adds randomness to aimbot based on hitchance setting
local function shouldShoot()
    if not Flags.HitchanceFilter then return true end
    local hc = Flags.Hitchance or 60
    local seed = Flags.HCSeed or 50
    local roll = math.random(1, 100)
    return roll <= hc
end

-- MIN DAMAGE FILTER Implementation
-- Only shoot if target damage exceeds minimum
local function checkMinDamage(damage)
    if not Flags.MinDmgFilter then return true end
    local minDmg = Flags.MinDamage or 20
    return damage >= minDmg
end

-- QUICK SWITCH Implementation
-- Knife after shot + auto reload
local lastShotTime = 0
task.spawn(function()
    while true do
        task.wait(0.01)
        if (Flags.KnifeAfterShot or Flags.AutoReloadEmpty) and BS.alive and BS.alive() then
            pcall(function()
                local tool = lplr.Character and lplr and lplr.Character:FindFirstChildOfClass("Tool")
                if tool and tool:FindFirstChild("RemoteEvent") then
                    if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                        lastShotTime = tick()
                    end
                    -- Quick switch after shot
                    if Flags.KnifeAfterShot and tick() - lastShotTime > 0 and tick() - lastShotTime < 0.1 then
                        local knife = lplr and lplr.Character:FindFirstChild("Knife") or lplr.Backpack:FindFirstChild("Knife")
                        if knife then
                            tool.Parent = lplr.Backpack
                            knife.Parent = lplr.Character
                            task.delay((Flags.QSDelay or 150) / 1000, function()
                                if knife.Parent == lplr.Character then
                                    knife.Parent = lplr.Backpack
                                    tool.Parent = lplr.Character
                                end
                            end)
                        end
                    end
                end
            end)
        end
    end
end)

-- Expose functions to combat module
pcall(function() Combat.shouldShoot = shouldShoot end)
pcall(function() Combat.checkMinDamage = checkMinDamage end)



-- AUTO SCOPE Implementation
task.spawn(function()
    while true do
        task.wait(0.01)
        if Flags.AutoScope and BS.alive and BS.alive() then
            pcall(function()
                if not UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
                    local tool = lplr.Character and lplr and lplr.Character:FindFirstChildOfClass("Tool")
                    if tool and (tool.Name:lower():find("awp") or tool.Name:lower():find("sniper")) then
                        -- Auto scope when aimbot target exists
                        if Flags.Aimbot and Flags.AimTarget then
                            -- Fire while scoped
                        end
                    end
                end
            end)
        end
    end
end)

-- KNIFE BOT Implementation
task.spawn(function()
    while true do
        task.wait(0.1)
        if Flags.KnifeBot and BS.alive and BS.alive() then
            pcall(function()
                local myHrp = BS.hrp and BS.hrp()
                if not myHrp then return end
                local range = Flags.KnifeRange or 10
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= lplr and p.Character then
                        local eHrp = p and p.Character:FindFirstChild("HumanoidRootPart")
                        local eHum = p and p.Character:FindFirstChildOfClass("Humanoid")
                        if eHrp and eHum and eHum.Health > 0 then
                            local dist = (eHrp.Position - myHrp.Position).Magnitude
                            if dist <= range then
                                -- Equip knife and attack
                                local knife = lplr.Backpack:FindFirstChild("Knife") or lplr and lplr.Character:FindFirstChild("Knife")
                                if knife then
                                    if knife.Parent ~= lplr.Character then
                                        knife.Parent = lplr.Character
                                    end
                                    -- Trigger attack
                                    pcall(function()
                                        knife.RemoteEvent:FireServer(eHrp.Position, "Attack")
                                    end)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ZEUS BOT Implementation
task.spawn(function()
    while true do
        task.wait(0.1)
        if Flags.ZeusBot and BS.alive and BS.alive() then
            pcall(function()
                local myHrp = BS.hrp and BS.hrp()
                if not myHrp then return end
                local range = Flags.ZeusRange or 30
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= lplr and p.Character then
                        local eHrp = p and p.Character:FindFirstChild("HumanoidRootPart")
                        local eHum = p and p.Character:FindFirstChildOfClass("Humanoid")
                        if eHrp and eHum and eHum.Health > 0 then
                            local dist = (eHrp.Position - myHrp.Position).Magnitude
                            if dist <= range then
                                local zeus = lplr.Backpack:FindFirstChild("Taser") or lplr and lplr.Character:FindFirstChild("Taser")
                                if zeus then
                                    if zeus.Parent ~= lplr.Character then
                                        zeus.Parent = lplr.Character
                                    end
                                    pcall(function()
                                        zeus.RemoteEvent:FireServer(eHrp.Position)
                                    end)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- AUTO KNUIFE After Kill
task.spawn(function()
    while true do
        task.wait(0.1)
        if Flags.AutoKnifeAfterKill and BS.alive and BS.alive() then
            pcall(function()
                -- Switch to knife after getting a kill
                local tool = lplr.Character and lplr and lplr.Character:FindFirstChildOfClass("Tool")
                if tool and tool.Name ~= "Knife" then
                    -- Check if we just killed someone
                    -- This is handled by kill event tracking
                end
            end)
        end
    end
end)

-- RAPID FIRE Implementation
task.spawn(function()
    while true do
        task.wait(0.01)
        if Flags.RapidFire and BS.alive and BS.alive() then
            pcall(function()
                local tool = lplr.Character and lplr and lplr.Character:FindFirstChildOfClass("Tool")
                if tool and tool:FindFirstChild("RemoteEvent") then
                    if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                        tool.RemoteEvent:FireServer((tool.Handle and tool.Handle.Position or hrp.Position), "Fire")
                    end
                end
            end)
        end
    end
end)

-- AUTO PISTOL Implementation
task.spawn(function()
    while true do
        task.wait(0.01)
        if Flags.AutoPistol and BS.alive and BS.alive() then
            pcall(function()
                local tool = lplr.Character and lplr and lplr.Character:FindFirstChildOfClass("Tool")
                if tool and tool:FindFirstChild("RemoteEvent") then
                    local rpm = Flags.AutoPistolRPM or 400
                    local interval = 60 / rpm
                    if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                        tool.RemoteEvent:FireServer((tool.Handle and tool.Handle.Position or hrp.Position), "Fire")
                        task.wait(interval)
                    end
                end
            end)
        end
    end
end)



-- ═══════════════════════════════════════════════════════════════
-- BACKTRACK (Time-Shift Aim)
-- ═══════════════════════════════════════════════════════════════
local Backtrack = {History = {}, MaxRecords = 64}
BS.Backtrack = Backtrack

function Backtrack:Record(player, position, time)
    if not player or not position then return end
    if not self.History[player.UserId] then
        self.History[player.UserId] = {}
    end
    local hist = self.History[player.UserId]
    table.insert(hist, {Pos = position, Time = time or tick()})
    -- Keep only recent records
    while #hist > self.MaxRecords do
        table.remove(hist, 1)
    end
end

function Backtrack:GetRecord(player, latency)
    if not player then return nil end
    local hist = self.History[player.UserId]
    if not hist or #hist == 0 then return nil end
    local targetTime = tick() - (latency or 0) - (Flags.BacktrackTick or 0.2)
    -- Find closest record
    local best, bestDist = nil, math.huge
    for _, rec in ipairs(hist) do
        local dist = math.abs(rec.Time - targetTime)
        if dist < bestDist then
            bestDist = dist
            best = rec
        end
    end
    return best and best.Pos or nil
end

function Backtrack:Cleanup()
    local now = tick()
    for uid, hist in pairs(self.History) do
        for i = #hist, 1, -1 do
            if now - hist[i].Time > 1.0 then
                table.remove(hist, i)
            end
        end
        if #hist == 0 then
            self.History[uid] = nil
        end
    end
end

-- Record player positions
task.spawn(function()
    while task.wait(0.05) do
        pcall(function()
            if not Flags.Backtrack then return end
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= lplr and player.Character then
                    local hrp = player and player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        Backtrack:Record(player, hrp.Position)
                    end
                end
            end
            Backtrack:Cleanup()
        end)
    end
end)

-- GUI
page:Label(" Backtrack ")
page:Toggle("啟用回溯", false, function(v) Flags.Backtrack = v end)
page:Slider("Tick (ms)", 50, 500, 200, function(v) Flags.BacktrackTick = v / 1000 end)
page:Slider("Max Records", 16, 128, 64, function(v) Backtrack.MaxRecords = v end)

-- ═══════════════════════════════════════════════════════════════
-- LATENCY COMPENSATION
-- ═══════════════════════════════════════════════════════════════
BS.LatencyCompensation = function(basePos)
    if not basePos then return basePos end
    if not Flags.LatencyComp then return basePos end
    local ping = BS.Ping and BS.Ping.Current or 0
    local velocity = Vector3.new()
    pcall(function()
        local target = BS.AimbotTarget
        if target and target.HRP then
            velocity = target.HRP.AssemblyLinearVelocity
        end
    end)
    local offset = velocity * (ping / 1000) * (Flags.LatencyFactor or 0.5)
    return basePos + offset
end

page:Label(" Latency Compensation ")
page:Toggle("啟用延遲補償", false, function(v) Flags.LatencyComp = v end)
page:Slider("Factor %", 10, 200, 50, function(v) Flags.LatencyFactor = v / 100 end)

-- ═══════════════════════════════════════════════════════════════
-- LEGIT ANTI-AIM (Subtle Body Rotation)
-- ═══════════════════════════════════════════════════════════════
page:Label(" Legit Anti-Aim ")
page:Toggle("正常反瞄", false, function(v) Flags.LegitAA = v end)
page:Slider("Legit AA Angle", 5, 45, 15, function(v) Flags.LegitAAAngle = v end)
page:Dropdown("Legit AA Mode", {"Sway", "Jitter", "Slow Spin"}, function(v) Flags.LegitAAMode = v end)

task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            if not Flags.LegitAA then return end
            local hrp = BS.hrp and BS.hrp()
            if not hrp then return end
            local angle = Flags.LegitAAAngle or 15
            local mode = Flags.LegitAAMode or "Sway"
            local cf = hrp.CFrame
            if mode == "Sway" then
                local sway = math.sin(tick() * 2) * angle
                hrp.CFrame = cf * CFrame.Angles(0, math.rad(sway), 0)
            elseif mode == "Jitter" then
                local j = (math.random() > 0.5 and 1 or -1) * angle
                hrp.CFrame = cf * CFrame.Angles(0, math.rad(j), 0)
            elseif mode == "Slow Spin" then
                hrp.CFrame = cf * CFrame.Angles(0, math.rad(tick() * angle * 10 % 360), 0)
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- WEAPON SPECIFIC SETTINGS
-- ═══════════════════════════════════════════════════════════════
BS.WeaponSettings = {
    ["AK47"]    = {FOV = 120, Smooth = 3, Bone = "頭部", Hitchance = 70},
    ["M4A4"]    = {FOV = 110, Smooth = 2.5, Bone = "頭部", Hitchance = 75},
    ["AWP"]     = {FOV = 60, Smooth = 1, Bone = "頭部", Hitchance = 90},
    ["Deagle"]  = {FOV = 80, Smooth = 2, Bone = "頭部", Hitchance = 65},
    ["USP"]     = {FOV = 100, Smooth = 2, Bone = "頭部", Hitchance = 80},
    ["Glock"]   = {FOV = 100, Smooth = 2.5, Bone = "胸部", Hitchance = 70},
    ["P250"]    = {FOV = 90, Smooth = 2, Bone = "頭部", Hitchance = 72},
    ["MP9"]     = {FOV = 130, Smooth = 3.5, Bone = "胸部", Hitchance = 60},
    ["MAC10"]   = {FOV = 130, Smooth = 3.5, Bone = "胸部", Hitchance = 60},
    ["UMP45"]   = {FOV = 115, Smooth = 3, Bone = "胸部", Hitchance = 65},
    ["XM1014"]  = {FOV = 150, Smooth = 4, Bone = "胸部", Hitchance = 85},
    ["Nova"]    = {FOV = 150, Smooth = 4, Bone = "胸部", Hitchance = 85},
    ["M249"]    = {FOV = 140, Smooth = 4, Bone = "胸部", Hitchance = 55},
    ["Negev"]   = {FOV = 140, Smooth = 4, Bone = "胸部", Hitchance = 50},
}

page:Label(" Weapon Settings ")
page:Toggle("每把武器設定", false, function(v) Flags.WeaponConfig = v end)

BS.GetWeaponSettings = function()
    if not Flags.WeaponConfig then return nil end
    local tool = lplr and lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
    if not tool then return nil end
    local name = tool.Name
    return BS.WeaponSettings[name]
end

-- ═══════════════════════════════════════════════════════════════
-- FRIENDLY FIRE TOGGLE
-- ═══════════════════════════════════════════════════════════════
page:Label(" Advanced ")
page:Toggle("友軍火力", false, function(v) Flags.FriendlyFire = v end)

print("[Combat] BloxStrike Combat module loaded (25 features)")
