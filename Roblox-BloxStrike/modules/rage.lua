-- BLOXSTRIKE RAGE MODULE v5.0 (Full Implementation)
-- HVH, Anti-Aim, Silent Aim, Fake Lag, Resolver, Rage Bot

local Players = nil
pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local UIS = nil
pcall(function() UIS = game:GetService("UserInputService") end)
local Workspace = game:GetService("Workspace")
local lplr = Players and Players.LocalPlayer

if not BS.Win then warn("[Rage] BS.Win not available") return end
local page = nil
pcall(function() page = BS.Win:Tab("暴力") end)
if not page then warn("[Rage] Failed to create tab!") return end

-- ═══ SILENT AIM ═══
page:Label(" Silent Aim ")
page:Toggle("靜默瞄準", false, function(v) Flags.SilentAim = v end)
page:Slider("FOV", 10, 360, 140, function(v) Flags.SAFov = v end)
page:Dropdown({Name="部位", Flag="SABone", Options={"Head","Chest","Pelvis"}, Default="Head"})
page:Toggle("牆壁穿透", false, function(v) Flags.SAWall = v end)
page:Slider("命中修正", 0, 100, 100, function(v) Flags.SAHitChance = v end)

-- ═══ ANTI-AIM ═══
page:Label(" Anti-Aim ")
page:Toggle("反瞄準", false, function(v) Flags.AA = v end)
page:Dropdown({Name="Pitch", Flag="AAPitch", Options={"Static","Jitter","Spin","Down","Up","Random"}, Default="Static"})
page:Dropdown({Name="Yaw", Flag="AAYaw", Options={"Spin","Back","Left","Right","Jitter","Random"}, Default="Spin"})
page:Slider("旋轉速度", 1, 36, 18, function(v) Flags.AASpd = v end)
page:Toggle("身體旋轉", false, function(v) Flags.AABodyYaw = v end)
page:Slider("Body Yaw 度數", 1, 180, 90, function(v) Flags.AABodyYawDeg = v end)
page:Dropdown({Name="Fake Yaw", Flag="AAFakeYaw", Options={"Off","Left","Right","Jitter"}, Default="Off"})

-- ═══ FAKE LAG ═══
page:Label(" Fake Lag ")
page:Toggle("假延遲", false, function(v) Flags.FL = v end)
page:Slider("封包數", 1, 16, 8, function(v) Flags.FLChoke = v end)
page:Dropdown({Name="模式", Flag="FLStyle", Options={"Static","Break","Adaptive"}, Default="Static"})
page:Toggle("FL 觸發器", false, function(v) Flags.FLTrigger = v end)

-- ═══ RESOLVER ═══
page:Label(" Resolver ")
page:Toggle("解析器", false, function(v) Flags.Resolver = v end)
page:Toggle("自動反制", false, function(v) Flags.AutoResolve = v end)
page:Dropdown({Name="解析模式", Flag="ResolverMode", Options={"Velocity","Brute","SpinDetect","Adaptive"}, Default="Velocity"})

-- ═══ RAGE BOT ═══
page:Label(" Rage Bot ")
page:Toggle("暴力瞄準", false, function(v) Flags.Ragebot = v end)
page:Slider("命中率", 50, 100, 100, function(v) Flags.RageHC = v end)
page:Toggle("自動開火", false, function(v) Flags.RageAF = v end)
page:Toggle("雙發", false, function(v) Flags.RageDT = v end)
page:Toggle("刀殺", false, function(v) Flags.RageKnife = v end)
page:Slider("Rage FOV", 10, 360, 360, function(v) Flags.RageFOV = v end)
page:Dropdown({Name="Rage 部位", Flag="RageBone", Options={"Head","Neck","Chest","Pelvis","Closest"}, Default="Head"})
page:Toggle("優先爆頭", false, function(v) Flags.RageHeadshot = v end)

-- ═══ LOGIC ═══
local RAGE = {}
BS.Rage = RAGE

-- State tracking
local resolverState = {}
local fakeLagState = {
    tickCount = 0,
    lastTick = 0,
    velocity = Vector3.new(0, 0, 0),
    lastPosition = nil,
}
local rageState = {
    lastTarget = nil,
    lastFireTime = 0,
    dtReady = false,
    dtCooldown = 0,
}

-- ═══════════════════════════════════════════════════════════════
-- SILENT AIM — Raycast Modification
-- ═══════════════════════════════════════════════════════════════
local function getSilentAimTarget()
    if not Flags.SilentAim or not BS.alive or not BS.alive() then return nil end

    local cam = Workspace.CurrentCamera
    if not cam then return nil end

    local fov = (Flags.SAFov or 140) / 2
    local boneName = Flags.SABone or "Head"
    local hitChance = (Flags.SAHitChance or 100) / 100

    -- Hit chance check
    if math.random() > hitChance then return nil end

    local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    local closestDist = fov
    local bestTarget = nil
    local bestPos = nil

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= lplr and BS.enemies and player in (BS.enemies() or {}) then
            local char = player.Character
            if not char then continue end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then continue end

            -- Wall check
            if not Flags.SAWall then
                local rayParams = RaycastParams.new()
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                rayParams.FilterDescendantsInstances = {lplr.Character}
                local origin = cam.CFrame.Position
                local dir = (hrp.Position - origin).Unit * (hrp.Position - origin).Magnitude
                local result = Workspace:Raycast(origin, dir, rayParams)
                if result and not result.Instance:IsDescendantOf(char) then continue end
            end

            -- Get bone position
            local targetPos
            if boneName == "Head" then
                local head = char:FindFirstChild("Head")
                targetPos = head and head.Position or hrp.Position + Vector3.new(0, 2, 0)
            elseif boneName == "Pelvis" then
                targetPos = hrp.Position + Vector3.new(0, -1, 0)
            else
                targetPos = hrp.Position + Vector3.new(0, 1, 0) -- Chest default
            end

            -- FOV check on screen
            local screenPos, onScreen = cam:WorldToScreenPoint(targetPos)
            if not onScreen then continue end
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude

            if dist < closestDist then
                closestDist = dist
                bestTarget = player
                bestPos = targetPos
            end
        end
    end

    return bestTarget, bestPos
end

-- Store the resolved target for other modules (combat.lua aimbot)
RAGE.SilentTarget = nil
RAGE.SilentPosition = nil

-- ═══════════════════════════════════════════════════════════════
-- RESOLVER — Anti-Bruteforce Anti-Aim Detection
-- ═══════════════════════════════════════════════════════════════
local function updateResolverData(player)
    if not player or not player.Character then return end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local uid = tostring(player.UserId)
    if not resolverState[uid] then
        resolverState[uid] = {
            VelocityHistory = {},
            LastAngles = {},
            BruteStep = 0,
            DetectedType = "None",
            LastUpdate = 0,
        }
    end

    local state = resolverState[uid]
    local now = tick()

    -- Track velocity
    local vel = hrp.Velocity
    table.insert(state.VelocityHistory, vel)
    if #state.VelocityHistory > 10 then table.remove(state.VelocityHistory, 1) end

    -- Track rotation
    local rot = hrp.CFrame.LookVector
    table.insert(state.LastAngles, rot)
    if #state.LastAngles > 10 then table.remove(state.LastAngles, 1) end
end

local function resolvePlayer(player)
    if not Flags.Resolver or not player or not player.Character then return nil end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local uid = tostring(player.UserId)
    local state = resolverState[uid]
    if not state then return nil end

    local mode = Flags.ResolverMode or "Velocity"
    local resolvedPos = nil

    if mode == "Velocity" then
        -- Use average velocity to predict real position
        local avgVel = Vector3.new(0, 0, 0)
        for _, v in ipairs(state.VelocityHistory) do
            avgVel = avgVel + v
        end
        avgVel = avgVel / math.max(#state.VelocityHistory, 1)
        resolvedPos = hrp.Position + avgVel * 0.15
        state.DetectedType = "Velocity"

    elseif mode == "Brute" then
        -- Cycle through body positions to counter brute-force anti-aim
        state.BruteStep = (state.BruteStep + 1) % 4
        local offsets = {
            Vector3.new(0, 3, 0),   -- Head
            Vector3.new(0, 1, 0),   -- Chest
            Vector3.new(0, -1, 0),  -- Pelvis
            Vector3.new(0, 2, 0),   -- Neck
        }
        resolvedPos = hrp.Position + offsets[state.BruteStep + 1]
        state.DetectedType = "Brute"

    elseif mode == "SpinDetect" then
        -- If spinning, target center of spin (HRP position)
        local avgRot = Vector3.new(0, 0, 0)
        for _, r in ipairs(state.LastAngles) do
            avgRot = avgRot + r
        end
        avgRot = avgRot / math.max(#state.LastAngles, 1)
        resolvedPos = hrp.Position + avgRot * 2
        state.DetectedType = "Spin"

    elseif mode == "Adaptive" then
        -- Auto-detect type and use best method
        local vel = hrp.Velocity
        local speed = vel.Magnitude
        local avgSpeed = 0
        for _, v in ipairs(state.VelocityHistory) do
            avgSpeed = avgSpeed + v.Magnitude
        end
        avgSpeed = avgSpeed / math.max(#state.VelocityHistory, 1)

        if speed > 10 and avgSpeed > 10 then
            -- Moving: use velocity prediction
            resolvedPos = hrp.Position + vel * 0.15
            state.DetectedType = "Moving"
        elseif speed < 2 and avgSpeed < 2 then
            -- Standing still with anti-aim: cycle through body parts
            state.BruteStep = (state.BruteStep + 1) % 4
            local offsets = {
                Vector3.new(0, 3, 0),
                Vector3.new(0, 1, 0),
                Vector3.new(0, -1, 0),
                Vector3.new(0, 2, 0),
            }
            resolvedPos = hrp.Position + offsets[state.BruteStep + 1]
            state.DetectedType = "Stationary"
        else
            -- Jittering: use average position
            resolvedPos = hrp.Position + Vector3.new(0, 1.5, 0)
            state.DetectedType = "Jittering"
        end
    end

    return resolvedPos
end

-- ═══════════════════════════════════════════════════════════════
-- FAKE LAG — Network Choke Simulation
-- ═══════════════════════════════════════════════════════════════
local function applyFakeLag()
    if not Flags.FL or not BS.alive or not BS.alive() then return end

    local char = lplr.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local now = tick()
    local chokeCount = Flags.FLChoke or 8
    local style = Flags.FLStyle or "Static"

    -- Track velocity
    local currentPos = hrp.Position
    if fakeLagState.lastPosition then
        fakeLagState.velocity = (currentPos - fakeLagState.lastPosition) / math.max(now - fakeLagState.lastTick, 0.001)
    end
    fakeLagState.lastPosition = currentPos
    fakeLagState.lastTick = now

    -- Calculate move speed
    local moveSpeed = fakeLagState.velocity.Magnitude

    -- Apply choke based on style
    if style == "Static" then
        -- Constant choke
        fakeLagState.tickCount = (fakeLagState.tickCount + 1) % chokeCount
        -- On "break" ticks, allow position update
        if fakeLagState.tickCount ~= 0 then
            -- Freeze visual position by re-setting CFrame
            -- (In real HVH this would be network-level, in executor we simulate via velocity zeroing)
            hrp.Velocity = Vector3.new(0, 0, 0)
        end

    elseif style == "Break" then
        -- Random breaks in choke pattern
        local breakPoint = math.random(1, chokeCount)
        fakeLagState.tickCount = (fakeLagState.tickCount + 1) % chokeCount
        if fakeLagState.tickCount == breakPoint then
            -- Break: send full update
            hrp.Velocity = Vector3.new(0, 0, 0)
        end

    elseif style == "Adaptive" then
        -- Choke more when moving fast (harder to track)
        local adaptiveChoke = math.clamp(math.floor(moveSpeed / 50 * chokeCount), 2, chokeCount)
        fakeLagState.tickCount = (fakeLagState.tickCount + 1) % adaptiveChoke
        if fakeLagState.tickCount ~= 0 then
            hrp.Velocity = Vector3.new(0, 0, 0)
        end
    end

    -- FL Trigger: stop choking when shooting
    if Flags.FLTrigger then
        local tool = BS.tool and BS.tool()
        if tool and tool:FindFirstChild("RemoteEvent") then
            -- Reset choke when firing
            fakeLagState.tickCount = 0
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- RAGE BOT — Auto-Aim + Auto-Fire
-- ═══════════════════════════════════════════════════════════════
local function getRageTarget()
    if not Flags.Ragebot or not BS.alive or not BS.alive() then return nil end

    local cam = Workspace.CurrentCamera
    if not cam then return nil end

    local fov = (Flags.RageFOV or 360) / 2
    local boneName = Flags.RageBone or "Head"
    local hitChance = (Flags.RageHC or 100) / 100

    if math.random() > hitChance then return nil end

    local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    local closestDist = fov
    local bestTarget = nil
    local bestPos = nil

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= lplr and BS.enemies and player in (BS.enemies() or {}) then
            local char = player.Character
            if not char then continue end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then continue end

            -- Knife check
            if Flags.RageKnife then
                local tool = BS.tool and BS.tool()
                if tool and tool.Name:lower():find("knife") then
                    -- Knife range only
                    local dist = (hrp.Position - cam.CFrame.Position).Magnitude
                    if dist < 8 then
                        return player, hrp.Position
                    end
                    continue
                end
            end

            -- Get bone position
            local targetPos
            if boneName == "Head" and Flags.RageHeadshot then
                local head = char:FindFirstChild("Head")
                targetPos = head and head.Position or hrp.Position + Vector3.new(0, 2, 0)
            elseif boneName == "Pelvis" then
                targetPos = hrp.Position + Vector3.new(0, -1, 0)
            elseif boneName == "Neck" then
                targetPos = hrp.Position + Vector3.new(0, 2.2, 0)
            elseif boneName == "Closest" then
                -- Find closest bone to crosshair
                local bones = {
                    char:FindFirstChild("Head") and char.Head.Position,
                    hrp.Position + Vector3.new(0, 1, 0), -- Chest
                    hrp.Position + Vector3.new(0, -1, 0), -- Pelvis
                }
                local minDist = math.huge
                for _, bpos in ipairs(bones) do
                    if not bpos then continue end
                    local sp, onScreen = cam:WorldToScreenPoint(bpos)
                    if onScreen then
                        local d = (Vector2.new(sp.X, sp.Y) - screenCenter).Magnitude
                        if d < minDist then
                            minDist = d
                            targetPos = bpos
                        end
                    end
                end
                if not targetPos then targetPos = hrp.Position + Vector3.new(0, 1, 0) end
            else
                targetPos = hrp.Position + Vector3.new(0, 1, 0) -- Chest
            end

            -- FOV check
            local screenPos, onScreen = cam:WorldToScreenPoint(targetPos)
            if not onScreen then
                -- Rage bot can target off-screen enemies if FOV is large
                local dist3D = (cam.CFrame.Position - targetPos).Magnitude
                if dist3D < 50 and closestDist < fov then
                    closestDist = 0
                    bestTarget = player
                    bestPos = targetPos
                end
                continue
            end

            local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
            if dist < closestDist then
                closestDist = dist
                bestTarget = player
                bestPos = targetPos
            end
        end
    end

    return bestTarget, bestPos
end

-- ═══════════════════════════════════════════════════════════════
-- MAIN LOOP — All Rage Features
-- ═══════════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    -- Anti-Aim
    pcall(function()
        if Flags.AA and BS.alive and BS.alive() then
            local pitch = Flags.AAPitch or "Static"
            local yaw = Flags.AAYaw or "Spin"
            local speed = Flags.AASpd or 18
            local bodyYaw = Flags.AABodyYaw
            local bodyDeg = Flags.AABodyYawDeg or 90

            local char = lplr.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            -- Yaw first
            local baseCF = hrp.CFrame
            if yaw == "Spin" then
                local angle = tick() * speed * 10
                baseCF = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(angle % 360), 0)
            elseif yaw == "Back" then
                baseCF = CFrame.new(hrp.Position) * hrp.CFrame.Rotation * CFrame.Angles(0, math.rad(180), 0)
            elseif yaw == "Left" then
                baseCF = CFrame.new(hrp.Position) * hrp.CFrame.Rotation * CFrame.Angles(0, math.rad(-90), 0)
            elseif yaw == "Right" then
                baseCF = CFrame.new(hrp.Position) * hrp.CFrame.Rotation * CFrame.Angles(0, math.rad(90), 0)
            elseif yaw == "Jitter" then
                local jitterAngle = math.random(-180, 180)
                baseCF = CFrame.new(hrp.Position) * hrp.CFrame.Rotation * CFrame.Angles(0, math.rad(jitterAngle), 0)
            elseif yaw == "Random" then
                local rAngle = math.random(0, 360)
                baseCF = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(rAngle), 0)
            end

            -- Pitch
            if pitch == "Down" then
                baseCF = baseCF * CFrame.Angles(math.rad(-89), 0, 0)
            elseif pitch == "Up" then
                baseCF = baseCF * CFrame.Angles(math.rad(89), 0, 0)
            elseif pitch == "Jitter" then
                baseCF = baseCF * CFrame.Angles(math.rad(math.random(-89, 89)), 0, 0)
            elseif pitch == "Random" then
                baseCF = baseCF * CFrame.Angles(math.rad(math.random(-89, 89)), 0, 0)
            end
            -- "Static" = no pitch modification

            hrp.CFrame = baseCF

            -- Body yaw (visual desync via root joint)
            if bodyYaw then
                local rootJoint = char:FindFirstChild("UpperTorso") and char.UpperTorso:FindFirstChild("RootJoint")
                if rootJoint then
                    local fakeYaw = Flags.AAFakeYaw or "Off"
                    if fakeYaw == "Left" then
                        rootJoint.C0 = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(-bodyDeg), 0)
                    elseif fakeYaw == "Right" then
                        rootJoint.C0 = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(bodyDeg), 0)
                    elseif fakeYaw == "Jitter" then
                        local r = math.random(-1, 1)
                        rootJoint.C0 = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(r * bodyDeg), 0)
                    end
                end
            end
        end
    end)

    -- Silent Aim target resolution
    pcall(function()
        RAGE.SilentTarget, RAGE.SilentPosition = getSilentAimTarget()
    end)

    -- Resolver data tracking
    pcall(function()
        if Flags.Resolver then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= lplr then
                    updateResolverData(player)
                end
            end
        end
    end)

    -- Fake Lag
    pcall(function()
        applyFakeLag()
    end)

    -- Rage Bot
    pcall(function()
        local target, targetPos = getRageTarget()
        if target and targetPos then
            local cam = Workspace.CurrentCamera
            if cam then
                -- Snap camera to target
                local cframe = CFrame.new(cam.CFrame.Position, targetPos)
                cam.CFrame = cframe

                -- Auto-fire
                if Flags.RageAF then
                    local now = tick()
                    local tool = BS.tool and BS.tool()
                    if tool and (now - rageState.lastFireTime) >= 0.05 then
                        -- Double tap logic
                        if Flags.RageDT then
                            if rageState.dtReady then
                                pcall(function() tool:Activate() end)
                                rageState.dtReady = false
                                rageState.dtCooldown = now + 0.1
                            elseif now > rageState.dtCooldown then
                                pcall(function() tool:Activate() end)
                                rageState.dtReady = true
                                rageState.dtCooldown = now + 0.02
                            end
                        else
                            pcall(function() tool:Activate() end)
                        end
                        rageState.lastFireTime = now
                    end
                end
            end
        end
    end)
end)

print("[Rage] BloxStrike Rage v5.0 loaded (full implementation)")
