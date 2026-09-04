-- BLOXSTRIKE SMART AI MODULE v4.0
-- AI-Powered Target Selection, Predictive Aimbot, Adaptive Playstyle

local Players = nil
pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local UserInputService = nil
pcall(function() UserInputService = game:GetService("UserInputService") end)
local lplr = Players and Players.LocalPlayer

if not BS.Win then warn("[SmartAI] BS.Win not available") return end
local page = nil
pcall(function() page = BS.Win:Tab("暴力") end)
if not page then warn("[SmartAI] Failed to create tab!") return end

-- AI State
local AIState = {
    Playstyle = "Balanced",
    ThreatLevel = "Low",
    LobbySkill = 50,
    CounterStrategy = "None",
    SessionKills = 0,
    SessionDeaths = 0,
    SessionHeadshots = 0,
    SessionShots = 0,
    SessionHits = 0,
    SessionStartTime = tick(),
    DecisionCount = 0,
    -- New AI tracking
    EnemyProfiles = {},     -- Per-enemy behavior profiles
    AimHistory = {},        -- Recent aim decisions for pattern analysis
    AdaptLevel = 0,         -- How much AI has adapted (0-100)
    LastDecisionTime = 0,
    PredictionModel = {},   -- Velocity prediction cache
}

local AI = {}
BS.SmartAI = AI
BS.AIState = AIState

-- GUI Elements
page:Label(" AI Settings ")
page:Toggle("AI Auto-Adjust", false, function(v) Flags.AI_Enabled = v end)
page:Dropdown({Name="AI Mode", Flag="AIMode", Options={"Legit","Balanced","Rage","Stealth","Adaptive"}, Default="Balanced"})
page:Toggle("Auto Legit", false, function(v) Flags.AI_Legit = v end)
page:Toggle("Auto Rage", false, function(v) Flags.AI_Rage = v end)
page:Toggle("Auto Stealth", false, function(v) Flags.AI_Stealth = v end)
page:Separator()

page:Label(" Target Selection AI ")
page:Toggle("AI Target Select", false, function(v) Flags.AI_TargetSelect = v end)
page:Dropdown({Name="Target Priority", Flag="AITargetPriority", Options={"距离","血量","威胁","综合","随机","智能"}, Default="综合"})
page:Toggle("威胁评估", false, function(v) Flags.AI_ThreatAssess = v end)
page:Toggle("敌人行为分析", false, function(v) Flags.AI_BehaviorAnalysis = v end)
page:Toggle("武器匹配优化", false, function(v) Flags.AI_WeaponMatch = v end)
page:Separator()

page:Label(" Prediction AI ")
page:Toggle("AI 预测", false, function(v) Flags.AI_Prediction = v end)
page:Toggle("移动模式识别", false, function(v) Flags.AI_MovementPattern = v end)
page:Toggle("跳跃预测", false, function(v) Flags.AI_JumpPredict = v end)
page:Toggle("strafe 预测", false, function(v) Flags.AI_StrafePredict = v end)
page:Slider("预测精度", 1, 10, 5, function(v) Flags.AI_PredAccuracy = v end)
page:Separator()

page:Label(" Playstyle AI ")
page:Toggle("自适应玩法", false, function(v) Flags.AI_AdaptivePlay = v end)
page:Toggle("自我限制", false, function(v) Flags.AI_SelfLimit = v end)
page:Slider("击杀上限/h", 5, 50, 20, function(v) Flags.AI_KillLimit = v end)
page:Toggle("模式轮换", false, function(v) Flags.AI_ModeRotate = v end)
page:Separator()

page:Label(" AI Info ")
page:Toggle("Show AI HUD", false, function(v) Flags.AI_HUD = v end)

-- Core functions
function AI.GetPlaystyle() return AIState.Playstyle end
function AI.GetThreat() return AIState.ThreatLevel end

-- ====================================================================
-- ENEMY PROFILING SYSTEM
-- Track each enemy's behavior patterns over time
-- ====================================================================
local function getEnemyProfile(player)
    local uid = player.UserId
    if not AIState.EnemyProfiles[uid] then
        AIState.EnemyProfiles[uid] = {
            Player = player,
            LastPosition = nil,
            VelocityHistory = {},
            AvgSpeed = 0,
            StrafeCount = 0,
            JumpFrequency = 0,
            AimSkill = 50,          -- 0-100 estimated skill
            AggressionLevel = 50,   -- 0-100
            DeathsToUs = 0,
            KillsOnUs = 0,
            LastSeen = 0,
            PredictionConfidence = 0,
            MovementPattern = "unknown", -- linear, zigzag, stationary, aggressive
        }
    end
    return AIState.EnemyProfiles[uid]
end

-- Update enemy profile with new observation
local function updateEnemyProfile(player, dt)
    local profile = getEnemyProfile(player)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    profile.LastSeen = tick()

    -- Track velocity history
    local vel = hrp.AssemblyLinearVelocity
    local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude

    table.insert(profile.VelocityHistory, {Speed = speed, Vel = vel, Time = tick()})
    if #profile.VelocityHistory > 30 then table.remove(profile.VelocityHistory, 1) end

    -- Calculate average speed
    local totalSpeed = 0
    for _, v in ipairs(profile.VelocityHistory) do totalSpeed = totalSpeed + v.Speed end
    profile.AvgSpeed = totalSpeed / math.max(#profile.VelocityHistory, 1)

    -- Detect strafing (direction changes)
    if profile.LastPosition then
        local moveDir = (hrp.Position - profile.LastPosition).Unit
        if profile.LastMoveDir then
            local dot = profile.LastMoveDir:Dot(moveDir)
            if dot < -0.3 then  -- Direction reversed = strafing
                profile.StrafeCount = profile.StrafeCount + 1
            end
        end
        profile.LastMoveDir = moveDir
    end
    profile.LastPosition = hrp.Position

    -- Classify movement pattern
    if profile.AvgSpeed < 2 then
        profile.MovementPattern = "stationary"
    elseif profile.StrafeCount > 10 then
        profile.MovementPattern = "zigzag"
    elseif profile.AvgSpeed > 20 then
        profile.MovementPattern = "aggressive"
    else
        profile.MovementPattern = "linear"
    end

    -- Estimate aim skill (based on how often they face us)
    local myHRP = BS.hrp and BS.hrp()
    if myHRP then
        local lookDir = hrp.CFrame.LookVector
        local toUs = (myHRP.Position - hrp.Position).Unit
        local dot = lookDir:Dot(toUs)
        if dot > 0.7 then
            profile.AimSkill = math.min(100, profile.AimSkill + 0.5)
        end
    end

    -- Aggression based on speed and proximity
    if speed > 15 then
        profile.AggressionLevel = math.min(100, profile.AggressionLevel + 0.3)
    else
        profile.AggressionLevel = math.max(0, profile.AggressionLevel - 0.1)
    end
end

-- ====================================================================
-- AI TARGET SELECTION
-- Score enemies based on multiple factors
-- ====================================================================
function AI.SelectTarget(maxDist, fov)
    if not Flags.AI_TargetSelect then return nil end

    maxDist = maxDist or math.huge
    fov = fov or 180

    local myHRP = BS.hrp and BS.hrp()
    if not myHRP then return nil end

    local cam = workspace.CurrentCamera
    local mousePos = UserInputService:GetMouseLocation()
    local myPos = myHRP.Position
    local myTeam = BS.team()
    local priority = Flags.AITargetPriority or "综合"

    local candidates = {}

    for _, player in pairs(Players:GetPlayers()) do
        if player == lplr then continue end
        local char = player.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        local head = char:FindFirstChild("Head")
        if not hrp or not hum or hum.Health <= 0 then continue end

        -- Team/friend check
        if BS.Flags and BS.Flags.TeamCheck and myTeam and player.Team == myTeam then continue end
        if BS.Flags and BS.Flags.FriendCheck and lplr:IsFriendsWith(player.UserId) then continue end

        local dist = (myPos - hrp.Position).Magnitude
        if dist > maxDist then continue end

        local aimPos = head and head.Position or hrp.Position + Vector3.new(0, 1.5, 0)

        -- Wall/visibility check
        if not BS.hasLineOfSight(myPos, aimPos) then continue end

        local pos, vis = cam:WorldToViewportPoint(aimPos)
        if not vis then continue end

        local screenDist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
        if screenDist > fov then continue end

        local profile = getEnemyProfile(player)

        -- Calculate composite score
        local score = 0

        if priority == "距离" then
            score = 1000 - dist
        elseif priority == "血量" then
            score = 100 - hum.Health
        elseif priority == "威胁" then
            score = profile.AggressionLevel + (100 - profile.AimSkill) * 0.5
        elseif priority == "智能" then
            -- Smart scoring: balance multiple factors
            local distScore = math.clamp(1000 - dist, 0, 1000) * 0.3
            local hpScore = (100 - hum.Health) * 0.2
            local crosshairScore = math.clamp(500 - screenDist, 0, 500) * 0.3
            local threatScore = profile.AggressionLevel * 0.1
            local skillVuln = (100 - profile.AimSkill) * 0.1
            score = distScore + hpScore + crosshairScore + threatScore + skillVuln

            -- Bonus: prefer enemies looking away
            local lookDir = hrp.CFrame.LookVector
            local toUs = (myPos - hrp.Position).Unit
            local dot = lookDir:Dot(toUs)
            if dot < 0 then score = score + 50 end  -- Not looking at us

            -- Bonus: moving targets are easier to predict
            local speed = profile.AvgSpeed
            if speed > 5 then score = score + 20 end
        elseif priority == "随机" then
            score = math.random(1, 1000)
        else
            -- Default:综合 (composite)
            local distScore = math.clamp(1000 - dist, 0, 1000) * 0.35
            local hpScore = (100 - hum.Health) * 0.25
            local crosshairScore = math.clamp(500 - screenDist, 0, 500) * 0.4
            score = distScore + hpScore + crosshairScore
        end

        table.insert(candidates, {
            Player = player,
            Char = char,
            HRP = hrp,
            Hum = hum,
            Head = head,
            AimPos = aimPos,
            Score = score,
            Dist = dist,
            ScreenDist = screenDist,
            Profile = profile,
        })
    end

    -- Sort by score (highest first)
    table.sort(candidates, function(a, b) return a.Score > b.Score end)

    return candidates[1], candidates
end

-- ====================================================================
-- AI PREDICTION ENGINE
-- Predict enemy movement based on behavior analysis
-- ====================================================================
function AI.PredictPosition(target, time)
    if not Flags.AI_Prediction or not target then return nil end

    local hrp = target.HRP
    if not hrp then return nil end

    local profile = target.Profile or getEnemyProfile(target.Player)
    local pos = hrp.Position
    local vel = hrp.AssemblyLinearVelocity
    local pattern = profile.MovementPattern

    local predictedPos = pos

    if pattern == "linear" then
        -- Simple linear prediction
        predictedPos = pos + vel * time

    elseif pattern == "zigzag" then
        -- Sinusoidal strafe prediction
        local freq = math.clamp(profile.StrafeCount * 0.1, 1, 5)
        local amplitude = math.clamp(profile.AvgSpeed * 0.3, 1, 8)
        local perpDir = Vector3.new(-vel.Z, 0, vel.X).Unit * amplitude
        local offset = math.sin(tick() * freq) * perpDir
        predictedPos = pos + vel * time + offset

    elseif pattern == "aggressive" then
        -- Aggressive: predict continued push
        predictedPos = pos + vel * time * 1.2

    else
        -- Stationary or unknown: assume slight random movement
        predictedPos = pos + vel * time * 0.5
    end

    -- Jump prediction
    if Flags.AI_JumpPredict and vel.Y > 5 then
        -- Target is in air, predict landing
        local airTime = vel.Y / 196.2  -- gravity
        local landTime = math.min(airTime, time)
        predictedPos = predictedPos + Vector3.new(0, -0.5 * 196.2 * landTime * landTime, 0)
    end

    -- Confidence based on data quality
    local confidence = math.clamp(#profile.VelocityHistory / 20, 0, 1)
    profile.PredictionConfidence = confidence * 100

    return predictedPos, confidence
end

-- ====================================================================
-- AI WEAPON MATCHING
-- Optimize aim based on current weapon
-- ====================================================================
function AI.GetOptimalBone(target)
    if not Flags.AI_WeaponMatch then return "Head" end

    local weaponType = BS.weaponType and BS.weaponType() or "other"
    local dist = target.Dist or 100
    local profile = target.Profile or getEnemyProfile(target.Player)

    if weaponType == "sniper" then
        -- Snipers: always go for head
        return "Head"
    elseif weaponType == "shotgun" then
        -- Shotguns: body shots at close range, head at medium
        if dist < 20 then return "Chest" else return "Head" end
    elseif weaponType == "smg" then
        -- SMGs: body spray at close, head at medium
        if dist < 15 then return "Chest" else return "Head" end
    elseif weaponType == "rifle" then
        -- Rifles: adaptive based on enemy skill
        if profile.AimSkill > 70 then
            -- Good enemy: go for head quickly
            return "Head"
        else
            -- Bad enemy: body shots are fine
            return "Chest"
        end
    else
        -- Default: head
        return "Head"
    end
end

-- ====================================================================
-- ADAPTIVE PLAYSTYLE ENGINE
-- Adjust behavior based on session performance
-- ====================================================================
local function updateAdaptivePlaystyle()
    if not Flags.AI_AdaptivePlay then return end

    local sessionTime = (tick() - AIState.SessionStartTime) / 3600  -- hours
    local kd = AIState.SessionDeaths > 0 and AIState.SessionKills / AIState.SessionDeaths or AIState.SessionKills
    local hsRate = AIState.SessionKills > 0 and AIState.SessionHeadshots / AIState.SessionKills or 0
    local killRate = sessionTime > 0 and AIState.SessionKills / sessionTime or 0

    -- Threat assessment
    if kd > 3 then
        AIState.ThreatLevel = "High"
    elseif kd > 1.5 then
        AIState.ThreatLevel = "Medium"
    else
        AIState.ThreatLevel = "Low"
    end

    -- Self-limiting: if getting too many kills, dial back
    if Flags.AI_SelfLimit then
        local killLimit = Flags.AI_KillLimit or 20
        if killRate > killLimit then
            AIState.CounterStrategy = "SelfLimit"
            -- Reduce aimbot aggressiveness
            if Flags.AimbotSmooth then
                Flags.AimbotSmooth = math.min(Flags.AimbotSmooth + 1, 30)
            end
        else
            AIState.CounterStrategy = "None"
        end
    end

    -- Mode rotation: periodically switch between legit and slightly more aggressive
    if Flags.AI_ModeRotate then
        local rotateTime = 300  -- 5 minutes
        local phase = math.floor((tick() - AIState.SessionStartTime) / rotateTime) % 3
        if phase == 0 then
            AIState.Playstyle = "Legit"
        elseif phase == 1 then
            AIState.Playstyle = "Balanced"
        else
            AIState.Playstyle = "Balanced"
        end
    end
end

-- ====================================================================
-- KILL TRACKING
-- ====================================================================
local prevHealth = {}
task.spawn(function()
    while true do
        task.wait(0.3)
        pcall(function()
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= lplr and player.Character then
                    local hum = player.Character:FindFirstChildOfClass("Humanoid")
                    if hum then
                        local prevHP = prevHealth[player.UserId] or hum.Health
                        if prevHP > 0 and hum.Health <= 0 then
                            local isEnemy = true
                            if lplr.Team and player.Team == lplr.Team then isEnemy = false end
                            if isEnemy then
                                AIState.SessionKills = AIState.SessionKills + 1
                                local tool = lplr.Character and lplr.Character:FindFirstChildWhichIsA("Tool")
                                -- Simple headshot detection
                                if tool then AIState.SessionHits = AIState.SessionHits + 1 end
                            end
                        end
                        prevHealth[player.UserId] = hum.Health
                    end
                end
            end
        end)
    end
end)

-- ====================================================================
-- MAIN AI LOOP
-- ====================================================================
task.spawn(function()
    while true do
        task.wait(2)
        if not Flags.AI_Enabled then continue end
        pcall(function()
            local mode = Flags.AIMode or "Balanced"
            AIState.Playstyle = mode

            -- Update enemy profiles
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= lplr then
                    updateEnemyProfile(player, 2)
                end
            end

            -- Adaptive playstyle
            updateAdaptivePlaystyle()

            -- Auto-adjust based on K/D
            if AIState.SessionDeaths > 0 then
                local kd = AIState.SessionKills / AIState.SessionDeaths
                if kd > 2 then AIState.ThreatLevel = "High"
                elseif kd > 1 then AIState.ThreatLevel = "Medium"
                else AIState.ThreatLevel = "Low" end
            end

            AIState.DecisionCount = AIState.DecisionCount + 1
        end)
    end
end)

-- ====================================================================
-- AI TARGET SELECTION LOOP (integrated with aimbot)
-- ====================================================================
task.spawn(function()
    while true do
        task.wait()
        if Flags.AI_TargetSelect and Flags.Aimbot and BS.alive and BS.alive() then
            pcall(function()
                local target = AI.SelectTarget(Flags.AimbotFOV or 180, Flags.AimbotFOV or 180)
                if target then
                    -- Override aimbot bone selection with AI recommendation
                    local optimalBone = AI.GetOptimalBone(target)
                    -- Store AI recommendation for aimbot to use
                    Flags._AI_RecommendedBone = optimalBone
                    Flags._AI_Target = target

                    -- AI prediction
                    if Flags.AI_Prediction then
                        local predictedPos, confidence = AI.PredictPosition(target, 0.1)
                        if predictedPos and confidence > 0.3 then
                            Flags._AI_PredictedPos = predictedPos
                            Flags._AI_PredConfidence = confidence
                        end
                    end
                end
            end)
        else
            Flags._AI_RecommendedBone = nil
            Flags._AI_Target = nil
            Flags._AI_PredictedPos = nil
        end
    end
end)

-- ====================================================================
-- AI HUD DISPLAY
-- ====================================================================
local aiHUDObj = nil
task.spawn(function()
    while true do
        task.wait(0.5)
        if Flags.AI_HUD then
            pcall(function()
                if not aiHUDObj then
                    local Compat = _G.BS and _G.BS.Compat
                    if Compat and Compat.DrawingNew then
                        aiHUDObj = Compat.DrawingNew("Text")
                    else
                        pcall(function() aiHUDObj = Drawing.new("Text") end)
                    end
                    if aiHUDObj then
                        aiHUDObj.Center = false
                        aiHUDObj.Outline = true
                        aiHUDObj.OutlineColor = Color3.new(0, 0, 0)
                        aiHUDObj.Font = 2
                        aiHUDObj.Size = 13
                    end
                end
                if aiHUDObj then
                    local profiles = 0
                    for _ in pairs(AIState.EnemyProfiles) do profiles = profiles + 1 end
                    aiHUDObj.Text = string.format(
                        "AI: %s | Threat: %s | K/D: %d/%d | Profiles: %d | Adapt: %d%%",
                        AIState.Playstyle, AIState.ThreatLevel,
                        AIState.SessionKills, AIState.SessionDeaths,
                        profiles, AIState.AdaptLevel
                    )
                    aiHUDObj.Color = Color3.fromRGB(0, 255, 200)
                    aiHUDObj.Position = Vector2.new(10, 500)
                    aiHUDObj.Visible = true
                end
            end)
        else
            if aiHUDObj then aiHUDObj.Visible = false end
        end
    end
end)

print("[SmartAI] BloxStrike Smart AI v4.0 loaded")
