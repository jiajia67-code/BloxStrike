
-- -- BLOXSTRIKE SMART AI MODULE v1.0
-- AI ?  + -- 
local Players = nil
pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local UserInputService = nil
pcall(function() UserInputService = game:GetService("UserInputService") end)
local HttpService = nil
pcall(function() HttpService = game:GetService("HttpService") end)
local StarterGui = nil
pcall(function() StarterGui = game:GetService("StarterGui") end)
local lplr = Players.LocalPlayer

if not BS.Win then warn("[Smart AI] BS.Win not available - ui.lua may have failed") return end
local page = BS.Win:Tab("Smart AI")
if not page or not page.Toggle then warn("[SmartAI] Failed to create tab!") return end

local AI = {}
BS.SmartAI = AI

-- -- SECTION 1: AI 
-- page:Label("  AI ? ")
page:Toggle("Smart AI", true, function(v) Flags.SmartAI = v end)
page:Toggle("Auto Optimize All", true, function(v) Flags.AI_AutoOpt = v end)
page:Toggle("AI Learning", true, function(v) Flags.AI_Learning = v end)
page:Toggle("AI Aggressive Mode", false, function(v) Flags.AI_Aggressive = v end)
page:Slider("AI Confidence", 20, 95, 65, function(v) Flags.AI_Confidence = v end)
page:Slider("AI Adapt Speed", 1, 10, 5, function(v) Flags.AI_AdaptSpeed = v end)
page:Toggle("AI Save Profile", true, function(v) Flags.AI_SaveProfile = v end)
page:Separator()
page:Label("  /  ")
page:Button({Name=" (", Color=Color3.fromRGB(0, 200, 80)}, function()
    AI.activateSafeMode()
end)
page:Button({Name="[Toggle]", Color=Color3.fromRGB(255, 50, 50)}, function()
    AI.activateAggressiveMode()
end)
page:Button({Name="  (", Color=Color3.fromRGB(200, 200, 0)}, function()
    AI.activateBalancedMode()
end)
page:Button({Name=" AI ", Color=Color3.fromRGB(100, 200, 255)}, function()
    AI.autoSelectMode()
end)
page:Separator()
page:Button({Name="[AI] Activate All", Color=Color3.fromRGB(0, 200, 100)}, function()
    AI.fullAnalysis()
end)
page:Button({Name="[AI] Smart Features", Color=Color3.fromRGB(0, 150, 255)}, function()
    AI.showStatus()
end)
page:Button({Name="[AI] Toggle", Color=Color3.fromRGB(200, 80, 80)}, function()
    AI.resetLearning()
end)

-- -- SECTION 2: AI --
    page:Label(" AI ")
page:Toggle("AI Aimbot Tuner", true, function(v) Flags.AI_AimTune = v end)
page:Toggle("AI ESP Tuner", true, function(v) Flags.AI_ESPTune = v end)
page:Toggle("AI Rage Tuner", true, function(v) Flags.AI_RageTune = v end)
page:Toggle("AI Movement Tuner", true, function(v) Flags.AI_MoveTune = v end)
page:Toggle("AI Stealth Tuner", true, function(v) Flags.AI_StealthTune = v end)
page:Toggle("AI KillFX Tuner", true, function(v) Flags.AI_KillFX = v end)
page:Toggle("AI Playstyle Detection", true, function(v) Flags.AI_Playstyle = v end)
page:Toggle("AI Counter-Aim", true, function(v) Flags.AI_CounterAim = v end)
page:Toggle("AI Threat Response", true, function(v) Flags.AI_ThreatResp = v end)
page:Toggle("AI Map Adapt", true, function(v) Flags.AI_MapAdapt = v end)
page:Toggle("AI Safety Tuner", true, function(v) Flags.AI_SafetyTune = v end)
page:Toggle("AI HVH Tuner", true, function(v) Flags.AI_HVHTune = v end)
page:Toggle("AI Viewmodel Tuner", true, function(v) Flags.AI_VMTune = v end)
page:Toggle("AI World Tuner", true, function(v) Flags.AI_WorldTune = v end)
page:Toggle("AI Chat Tuner", true, function(v) Flags.AI_ChatTune = v end)
page:Toggle("AI Bypass Tuner", true, function(v) Flags.AI_BypassTune = v end)
page:Toggle("AI Bhop Tuner", true, function(v) Flags.AI_BhopTune = v end)

-- AI STATE
local AIState = {
    -- Player Performance Tracking
    SessionKills = 0,
    SessionDeaths = 0,
    SessionHeadshots = 0,
    SessionShots = 0,
    SessionHits = 0,
    SessionDamage = 0,
    -- SessionStartTime = tick(),

    -- Per-enemy tracking
    EnemyStats = {}, -- {uid = {name, timesKilled, timesDied, avgDist, weaponUsed, headshotRate}}

    -- Aim Performance
    AimScore = 50,          -- 0-100
    AimMissReasons = {      -- Why we miss
        PingTooHigh = 0,
        SmoothWrong = 0,
        PredictionOff = 0,
        FOVTooSmall = 0,
        ReactionSlow = 0,
        TargetSwitch = 0,
    },

    -- Playstyle Detection
    Playstyle = "Balanced", -- Aggressive / Passive / Tactical / Sniper / Runner / Balanced
    PlaystyleConfidence = 0,
    PlaystyleHistory = {},

    -- Learning Data
    OptimalSettings = {},   -- Best performing settings per context
    SettingsHistory = {},   -- {timestamp, settings, performance}
    PerformanceTrend = {},  -- Performance over time

    -- Threat Assessment
    ThreatLevel = "Normal",
    LobbySkill = "Medium",  -- Easy / Medium / Hard / VeryHard / Cheater
    LobbySkillScore = 50,
    CounterStrategy = "None",

    -- Context
    CurrentMap = nil,
    MapPhase = "Mid",       -- Early / Mid / Late
    RoundNumber = 0,
    Score = {CT = 0, T = 0},

    -- Feature Health
    FeatureHealth = {},     -- {featureName = {successRate, lastUsed, overallRating}}

    -- AI Decisions Log
    Decisions = {},         -- {time, decision, reason, result}
    MaxDecisions = 100,
}-- -- SECTION 3: PERFORMANCE ANALYZER -- 
local deathAnalysis = { RecentKills = {}, RecentDeaths = {}, StreakData = {}, MapControl = 50 }

local function calcPerformanceScore()
    local s = AIState
    local score = 50
    local factors = {} -- 

    -- 1. K/D     if s.SessionDeaths > 0 then
        local kd = s.SessionKills / s.SessionDeaths
        local kdImpact = math.clamp((kd - 1) * 10, -25, 25)
        score = score + kdImpact
        factors.KD = kdImpact

    -- 2. /     local recentKills = #deathAnalysis.RecentKills
    local recentDeaths = #deathAnalysis.RecentDeaths
    if recentKills > recentDeaths then
        local streakBonus = math.min((recentKills - recentDeaths) * 3, 15)
        score = score + streakBonus
        factors.Streak = streakBonus
    elseif recentDeaths > recentKills then
        local deathPenalty = math.min((recentDeaths - recentKills) * 4, 20)
        score = score - deathPenalty
        factors.Streak = -deathPenalty

    -- 3.     if s.SessionShots > 0 then
        local acc = s.SessionHits / s.SessionShots
        local accImpact = math.clamp((acc - 0.3) * 50, -15, 15)
        score = score + accImpact
        factors.Accuracy = accImpact

    -- 4.     if s.SessionKills > 0 then
        local hsRate = s.SessionHeadshots / s.SessionKills
        local hsImpact = math.clamp((hsRate - 0.3) * 25, -10, 10)
        score = score + hsImpact
        factors.Headshot = hsImpact

    -- 5.      if s.SessionKills > 0 then
        local dmgPerKill = s.SessionDamage / s.SessionKills
        local efficiency = math.clamp(1 - dmgPerKill / 200, -1, 1)
        local dmgImpact = efficiency * 10
        score = score + dmgImpact
        factors.DamageEff = dmgImpact

    -- 6.     local sessionMin = (tick() - s.SessionStartTime) / 60
    score = score + math.min(sessionMin / 10, 5)

    -- 7. 60 ?vs     local recentPerf = 0
    local recentCount = 0
    for _, entry in ipairs(s.PerformanceTrend) do
        if tick() - entry.Time < 60 then
            recentPerf = recentPerf + entry.Score
            recentCount = recentCount + 1
    if recentCount > 0 then
        recentPerf = recentPerf / recentCount
        local trend = recentPerf - score
        -- score = score + math.clamp(trend * 0.3, -10, 10)
        factors.Trend = trend * 0.3

    -- 8.      if s.AvgEngagementDist and s.AvgEngagementDist > 0 then
        -- <20m? aggressive play
        -- >60m? tactical play
        if s.AvgEngagementDist < 20 then
            score = score + 3
        elseif s.AvgEngagementDist > 60 then
            score = score + 2

    -- 9.      if s.AvgReactionTime and s.AvgReactionTime > 0 then
        if s.AvgReactionTime < 200 then
            score = score + 5
        elseif s.AvgReactionTime > 500 then
            score = score - 5

    return math.clamp(math.floor(score), 0, 100)

function AI.trackKill(victim, headshot, dist, weapon)
    table.insert(AIState.SessionKills + 0 > 0 and deathAnalysis.RecentKills or deathAnalysis.RecentKills, tick())
    -- 
    local now = tick()
    for i = #deathAnalysis.RecentKills, 1, -1 do
        if now - deathAnalysis.RecentKills[i] > 60 then
            table.remove(deathAnalysis.RecentKills, i)
    -- TODO
    if dist then
        AIState.AvgEngagementDist = ((AIState.AvgEngagementDist or 0) + dist) / 2
    -- TODO
    table.insert(AIState.PerformanceTrend, { Time = tick(), Score = calcPerformanceScore(), Type = "Kill" })
    if #AIState.PerformanceTrend > 100 then table.remove(AIState.PerformanceTrend, 1) end

function AI.trackDeath(killer, dist)
    table.insert(deathAnalysis.RecentDeaths, tick())
    local now = tick()
    for i = #deathAnalysis.RecentDeaths, 1, -1 do
        if now - deathAnalysis.RecentDeaths[i] > 60 then
            table.remove(deathAnalysis.RecentDeaths, i)
    table.insert(AIState.PerformanceTrend, { Time = tick(), Score = calcPerformanceScore(), Type = "Death" })
    if #AIState.PerformanceTrend > 100 then table.remove(AIState.PerformanceTrend, 1) end

-- -- SECTION 4: PLAYSTYLE DETECTOR 
local function detectPlaystyle()
    if not Flags.AI_Playstyle then return end

    local scores = {
        Aggressive = 0,
        Passive = 0,
        Tactical = 0,
        Sniper = 0,
        Runner = 0,
    }

    -- A.      if Flags.Ragebot then scores.Aggressive = scores.Aggressive + 20 end
    if Flags.AA then scores.Aggressive = scores.Aggressive + 10 end
    if Flags.Aimbot then scores.Tactical = scores.Tactical + 15 end
    if Flags.TriggerBot then scores.Aggressive = scores.Aggressive + 10 end
    if Flags.Bhop then scores.Runner = scores.Runner + 20 end
    if Flags.SpeedBoost then scores.Runner = scores.Runner + 15 end
    if Flags.NoClip then scores.Runner = scores.Runner + 10 end
    if Flags.SilentAim then scores.Aggressive = scores.Aggressive + 15 end

    -- B.      local wType = BS.weaponType and BS.weaponType() or "none"
    if wType == "sniper" then scores.Sniper = scores.Sniper + 30
    elseif wType == "rifle" then scores.Tactical = scores.Tactical + 10
    elseif wType == "smg" then scores.Aggressive = scores.Aggressive + 15
    elseif wType == "pistol" then scores.Tactical = scores.Tactical + 5

    -- C.      if AIState.SessionDeaths > 0 then
        local kd = AIState.SessionKills / AIState.SessionDeaths
        if kd > 3 then scores.Aggressive = scores.Aggressive + 15
        elseif kd > 1.5 then scores.Tactical = scores.Tactical + 10
        elseif kd < 1 then scores.Passive = scores.Passive + 10
        end
    end

    if AIState.SessionShots > 0 then
        local acc = AIState.SessionHits / AIState.SessionShots
        if acc > 0.5 then scores.Tactical = scores.Tactical + 10
        elseif acc < 0.2 then scores.Runner = scores.Runner + 10
        end
    end

    -- D.      if BS.alive() then
        local h = BS.hum()
        if h and h.WalkSpeed > 20 then scores.Runner = scores.Runner + 10 end
        if h and h.WalkSpeed > 30 then scores.Runner = scores.Runner + 10 end
    end

    -- E.     local avgDist = AIState.AvgEngagementDist or 0
    if avgDist > 0 then
        if avgDist < 15 then scores.Aggressive = scores.Aggressive + 20
        elseif avgDist < 30 then scores.Tactical = scores.Tactical + 10
        elseif avgDist > 60 then scores.Sniper = scores.Sniper + 20
        end
    end

    -- F.     local avgReact = AIState.AvgReactionTime or 300
    if avgReact < 150 then scores.Aggressive = scores.Aggressive + 15
    elseif avgReact > 400 then scores.Sniper = scores.Sniper + 10
    end

    -- G.     -- -- 
    local recentDeaths = #deathAnalysis.RecentDeaths
    if recentDeaths > 3 then
        scores.Tactical = scores.Tactical + 10 -- end

    -- H.     local recentKills = #deathAnalysis.RecentKills
    if recentKills > 3 and recentDeaths == 0 then
        scores.Aggressive = scores.Aggressive + 15 -- 
    end

    -- Find best with confidence
    local best, bestScore = "Balanced", 0
    for style, sc in pairs(scores) do
        if sc > bestScore then
            best = style
            bestScore = sc
        end
    end

    AIState.Playstyle = best
    AIState.PlaystyleConfidence = math.min(100, bestScore + 30)

    -- Track history with decay
    table.insert(AIState.PlaystyleHistory, { Style = best, Time = tick(), Score = bestScore })
    if #AIState.PlaystyleHistory > 50 then table.remove(AIState.PlaystyleHistory, 1) end
end

-- -- SECTION 5: LOBBY SKILL ASSESSMENT

local function assessLobbySkill()
    if not Flags.AI_ThreatResp then return end

    local enemies = BS.enemies and BS.enemies() or {}
    if #enemies == 0 then return end

    local myHRP = BS.hrp()
    local skillScore = 50
    local indicators = {}

    -- A.     local totalHP = 0
    local highHPCount = 0
    for _, e in ipairs(enemies) do
        if e.Hum then
            totalHP = totalHP + e.Hum.Health
            if e.Hum.Health > 80 then highHPCount = highHPCount + 1 end
        end
    end
    local avgHP = totalHP / #enemies
    if avgHP > 80 then skillScore = skillScore + 15; indicators.HighHP = true end
    if avgHP < 40 then skillScore = skillScore - 10; indicators.LowHP = true end
    if highHPCount > #enemies * 0.7 then skillScore = skillScore + 10; indicators.MostlyHighHP = true end

    -- B.      local totalDist = 0
    local closeRangeCount = 0
    for _, e in ipairs(enemies) do
        if myHRP and e.HRP then
            local dist = (myHRP.Position - e.HRP.Position).Magnitude
            totalDist = totalDist + dist
            if dist < 20 then closeRangeCount = closeRangeCount + 1 end
        end
    end
    local avgDist = totalDist / #enemies
    if avgDist < 25 then skillScore = skillScore + 10; indicators.AggressiveLobby = true end
    if avgDist > 60 then skillScore = skillScore - 5; indicators.PassiveLobby = true end

    -- C. K/D      if AIState.SessionDeaths > AIState.SessionKills then
        skillScore = skillScore + 15; indicators.Losing = true
    elseif AIState.SessionKills > AIState.SessionDeaths * 2 then
        skillScore = skillScore - 10; indicators.Winning = true
    end

    -- D.      local recentDeaths = #deathAnalysis.RecentDeaths
    if recentDeaths > 3 then
        skillScore = skillScore + 10; indicators.FrequentDeaths = true
    end

    -- E.      local fastMovers = 0
    for _, e in ipairs(enemies) do
        if e.HRP then
            local vel = e.HRP.AssemblyLinearVelocity.Magnitude
            if vel > 25 then fastMovers = fastMovers + 1 end
        end
    end
    if fastMovers > #enemies * 0.5 then
        skillScore = skillScore + 8; indicators.FastMovers = true
    end

    -- F. CheatDetect      if BS.CheatDetect and BS.PlayerData then
        local cheaterCount = 0
        for uid, data in pairs(BS.PlayerData) do
            if data.TotalScore > 60 then cheaterCount = cheaterCount + 1 end
        end
        if cheaterCount > 0 then
            skillScore = skillScore + cheaterCount * 15; indicators.Cheaters = true
        end
    end

    -- G. Ping      local ping = BS.Ping and BS.Ping.Current or 50
    if ping > 150 then skillScore = skillScore + 5; indicators.HighPing = true end

    AIState.LobbySkillScore = math.clamp(skillScore, 0, 100)
    AIState.LobbyIndicators = indicators

    if skillScore > 80 then AIState.LobbySkill = "Cheater"
    elseif skillScore > 65 then AIState.LobbySkill = "VeryHard"
    elseif skillScore > 45 then AIState.LobbySkill = "Hard"
    elseif skillScore > 30 then AIState.LobbySkill = "Medium"
    else AIState.LobbySkill = "Easy" end
end

-- -- SECTION 6: AI OPTIMIZATION ENGINE -- 
local function logDecision(decision, reason)
    table.insert(AIState.Decisions, {
        -- Time = tick(),
        Decision = decision,
        Reason = reason,
    })
    if #AIState.Decisions > AIState.MaxDecisions then
        table.remove(AIState.Decisions, 1)
    end
end

-- Aimbot Auto-Tuner
    local function tuneAimbot()
    if not Flags.AI_AimTune then return end

    local perf = calcPerformanceScore()
    local ping = BS.Ping and BS.Ping.Current or 50
    local skill = AIState.LobbySkillScore
    local style = AIState.Playstyle

    -- Smooth: adjust based on performance and ping
    local baseSmooth = 5
    if perf < 40 then
        -- Playing badly increase smooth (more stable)
        baseSmooth = 8
        logDecision("Aimbot Smooth 8", "Performance low (" .. perf .. ")")
    elseif perf > 75 and style == "Aggressive" then
        -- Playing well + aggressive decrease smooth (faster snap)
        baseSmooth = 3
        logDecision("Aimbot Smooth 3", "High performance + Aggressive style")
    end

    -- FOV: adjust based on lobby skill and playstyle
    local baseFOV = 60
    if skill > 65 then
        baseFOV = 90 -- harder lobby wider FOV
    elseif skill < 30 then
        baseFOV = 45 -- easy lobby tighter FOV
    end
    if style == "Sniper" then baseFOV = 30 end
    if style == "Aggressive" then baseFOV = math.max(baseFOV, 80) end

    -- Prediction: adjust based on ping
    local basePred = 40
    if ping > 100 then basePred = 60
    elseif ping > 50 then basePred = 45
    else basePred = 35 end

    -- Bone selection: based on distance and skill
    local bone = "Head"
    if skill > 60 then bone = "Chest" end -- harder enemies easier target

    -- Apply with confidence check
    local confidence = Flags.AI_Confidence or 65
    if perf > confidence then
        Flags.AimbotSmooth = baseSmooth
        Flags.AimbotFOV = baseFOV
        Flags.AimPredF = basePred
        logDecision(string.format("Aimbot: Smooth=%d FOV=%d Pred=%d Bone=%s",
            baseSmooth, baseFOV, basePred, bone), "AI Auto-Tune")
    end
end

-- ESP Auto-Tuner
    local function tuneESP()
    if not Flags.AI_ESPTune then return end

    local perf = calcPerformanceScore()
    local lobbySkill = AIState.LobbySkillScore
    local playstyle = AIState.Playstyle

    -- If doing well less ESP needed (trust your skills)
    -- If struggling more ESP info
    if perf < 40 then
        -- Struggling enable more ESP
        Flags.ESP_Box = true
        Flags.ESP_Name = true
        Flags.ESP_Health = true
        Flags.ESP_Dist = true
        Flags.ESP_Weapon = true
        if lobbySkill > 60 then
            Flags.ESP_Skeleton = true
            Flags.ESP_Velocity = true
        end
        logDecision("ESP: Full info enabled", "Low performance, need more info")
    elseif perf > 75 then
        -- Doing well minimal ESP (less clutter)
        if playstyle == "Aggressive" then
            Flags.ESP_Skeleton = false
            Flags.ESP_Velocity = false
            Flags.ESP_LaserLine = false
            logDecision("ESP: Minimal mode", "High performance, Aggressive style")
        end
    end

    -- Color mode based on lobby
    if lobbySkill > 60 then
        Flags.ESPColorMode = "Health" -- Show health colors for awareness
    else
        Flags.ESPColorMode = "Team"
    end

    -- Box style: simpler on low FPS
    if BS.Perf and BS.Perf.FPS < 30 then
        Flags.ESPBoxStyle = "2D"
        Flags.ESP_Skeleton = false
        Flags.ESP_Glow = false
        logDecision("ESP: Simplified (low FPS)", "FPS: " .. (BS.Perf.FPS or 0))
    end
end

-- Rage Auto-Tuner
    local function tuneRage()
    if not Flags.AI_RageTune then return end

    local perf = calcPerformanceScore()
    local lobbySkill = AIState.LobbySkillScore
    local playstyle = AIState.Playstyle
    local ping = BS.Ping and BS.Ping.Current or 50

    if not Flags.Ragebot then return end

    -- Hitchance: adjust based on ping and lobby
    local hc = 85
    if ping > 150 then hc = 70 end -- high ping lower hitchance
    if lobbySkill > 65 then hc = 90 end -- hard lobby higher hitchance
    if playstyle == "Aggressive" then hc = math.min(95, hc + 10) end

    Flags.RageHC = hc

    -- Fake Lag: adjust based on lobby
    if Flags.FL then
        local choke = 7
        if lobbySkill > 60 then choke = 5 end -- hard lobby less fake lag
        if lobbySkill < 30 then choke = 10 end -- easy lobby more fake lag
        Flags.FLChoke = choke
    end

    -- Anti-Aim: adjust based on lobby skill
    if Flags.AA then
        if lobbySkill > 65 then
            -- Hard lobby use more complex AA
            Flags.AAYaw = "LBY Break"
            Flags.AAPitch = "Down"
        elseif lobbySkill < 30 then
            -- Easy lobby simple AA is fine
            Flags.AAYaw = "Jitter"
            Flags.AAPitch = "Down"
        else
            Flags.AAYaw = "Spin"
            Flags.AAPitch = "Down"
        end
    end

    -- Resolver: more aggressive on hard lobbies
    if Flags.Resolver then
        Flags.ResSteps = lobbySkill > 60 and 8 or 5
    end

    logDecision(string.format("Rage: HC=%d FL=%d AA=%s", hc, Flags.FLChoke or 7,
        Flags.AAYaw or "Spin"), "Lobby: " .. AIState.LobbySkill)
end

-- Movement Auto-Tuner
    local function tuneMovement()
    if not Flags.AI_MoveTune then return end

    local perf = calcPerformanceScore()
    local playstyle = AIState.Playstyle
    local lobbySkill = AIState.LobbySkillScore

    -- Bhop mode based on playstyle
    if Flags.Bhop then
        if playstyle == "Runner" then
            Flags.BhopSpeed = 30
            Flags.BhopStrafeSpd = 15
        elseif playstyle == "Aggressive" then
            Flags.BhopSpeed = 28
            Flags.BhopStrafeSpd = 12
        elseif playstyle == "Tactical" then
            Flags.BhopSpeed = 22
            Flags.BhopStrafeSpd = 8
        end
    end

    -- Speed boost: cautious on hard lobbies
    if Flags.SpeedBoost then
        local maxSpeed = 25
        if lobbySkill > 60 then maxSpeed = 22 end
        if perf < 40 then maxSpeed = 20 end
        Flags._AdaptSpeed = maxSpeed
    end

    logDecision("Movement: Speed=" .. (Flags.BhopSpeed or 24), "Style: " .. playstyle)
end

-- Stealth Auto-Tuner
    local function tuneStealth()
    if not Flags.AI_StealthTune then return end

    local lobbySkill = AIState.LobbySkillScore
    local risk = BS.Stealth and BS.Stealth.RiskLevel or 0

    -- Higher lobby skill more stealth
    if lobbySkill > 65 then
        Flags.StealthHumanize = true
        Flags.StealthRandomTiming = true
        Flags.StealthAntiPattern = true
        Flags.HVHSafeMode = true
        Flags.MLEvasion = true
        Flags.MLEntropy = true
        Flags.MLMicroPause = true
        logDecision("Stealth: Maximum protection", "Hard lobby detected")
    elseif lobbySkill > 45 then
        Flags.StealthHumanize = true
        Flags.StealthRandomTiming = true
        Flags.HVHSafeMode = true
        logDecision("Stealth: Balanced protection", "Medium lobby")
    else
        -- Easy lobby, can be more aggressive
        logDecision("Stealth: Minimal (easy lobby)", "Easy lobby")
    end

    -- Risk-based auto-adjust
    if risk > 60 then
        Flags.StealthAutoDisable = true
        Flags.StealthRiskThresh = 60
        logDecision("Stealth: Auto-disable ON (risk=" .. risk .. "%)", "High risk")
    end
end

-- KillFX Auto-Tuner
    local function tuneKillFX()
    if not Flags.AI_KillFX then return end

    local perf = calcPerformanceScore()

    -- High performance more kill effects (celebration)
    -- Low performance fewer effects (focus)
    if perf > 70 then
        Flags.KillSound = true
        Flags.KillAnimations = true
        Flags.KillBlur = true
        Flags.KillScreenShake = true
    elseif perf < 40 then
        Flags.KillSound = true  -- keep sounds for morale
        Flags.KillBlur = false  -- disable visual distractions
        Flags.KillScreenShake = false
        Flags.KillVignette = false
    end
end

-- -- SAFETY MODE -- function AI.activateSafeMode()
    -- Flags.Ragebot = false
    Flags.AA = false
    Flags.NoClip = false
    Flags.SpeedBoost = false
    Flags.FL = false
    Flags.SilentAim = false
    Flags.NoSpread = false
    Flags.NoRecoil = false
    Flags.Resolver = false
    Flags.RageKnife = false
    Flags.RageZeus = false
    Flags.EdgeFric = false

    -- Legit ?     Flags.Aimbot = true
    Flags.AimbotSmooth = 12
    Flags.AimbotFOV = 40
    Flags.AimbotBone = "Head"
    Flags.AimbotSort = "Crosshair"
    Flags.AimbotTeamCheck = true
    Flags.AimbotWall = true
    Flags.AimbotVis = true
    Flags.AimbotPredict = true
    Flags.AimbotHumanize = true
    Flags.AimHDelay = 40
    Flags.AimHDev = 15
    Flags.TriggerBot = false  -- too risky in safe mode

    -- ESP?     Flags.ESP_Box = true
    Flags.ESP_Name = true
    Flags.ESP_Health = true
    Flags.ESP_Dist = true
    Flags.ESP_Weapon = false
    Flags.ESP_Skeleton = false
    Flags.ESP_Snaplines = false
    Flags.ESP_Glow = false
    Flags.ESP_Velocity = false

    -- Flags.Bhop = false
    Flags.BhopMode = "Legit"
    Flags.BhopSpeed = 20
    Flags.BhopDelay = 0

    -- Flags.StealthHumanize = true
    Flags.StealthRandomTiming = true
    Flags.StealthAntiPattern = true
    Flags.StealthMaskHooks = true
    Flags.StealthHideGUI = true
    Flags.StealthCleanEnv = true
    Flags.StealthAntiDebug = true
    Flags.StealthMemClean = true
    Flags.StealthBehavior = true
    Flags.StealthReaction = true
    Flags.StealthReactionMin = 150
    Flags.StealthReactionMax = 400
    Flags.StealthAimSmooth = true
    Flags.StealthHideCoreGui = true

    -- HVH ?     Flags.HVHSafeMode = true
    Flags.HVHWarmup = true
    Flags.HVHWarmupDur = 180
    Flags.HVHGradual = true
    Flags.HVHBehavior = true
    Flags.HVHMoveLegit = true
    Flags.HVHAimLegit = true
    Flags.HVHAntiStat = true
    Flags.HVHServMask = true
    Flags.HVHKillMask = true
    Flags.HVHFakeMiss = true
    Flags.HVHFakeMissRate = 20

    -- ML     Flags.MLEvasion = true
    Flags.MLEntropy = true
    Flags.MLMouseEntropy = true
    Flags.MLReaction = true
    Flags.MLMicroPause = true
    Flags.MLDecision = true
    Flags.MLReactionVar = 200

    -- Flags.TrafficMask = true
    Flags.TrafficNoise = true
    Flags.TrafficBurst = true
    Flags.TrafficRemoteFP = true

    -- Flags.MemEvasion = true
    Flags.MemStrEnc = true
    Flags.MemObjScramble = true
    Flags.MemRefClean = true
    Flags.MemGCObf = true

    -- Flags.AntiReplay = true
    Flags.ActionFuzz = true
    Flags.SeqShuffle = true
    Flags.TimingDesync = true

    -- Flags.FPRotation = true
    Flags.FPRotInterval = 120
    Flags.FPMove = true
    Flags.FPAim = true
    Flags.FPTiming = true

    -- Bypass     Flags.SSVL = true
    Flags.SSVLVelCap = true
    Flags.SSVLMaxVel = 40
    Flags.SSVLDrift = true
    Flags.SSVLAccel = true
    Flags.SSVLMaxAccel = 80

    -- Flags.StatSmooth = true
    Flags.StatKDReg = true
    Flags.StatTargetKD = 20
    Flags.StatHSReg = true
    Flags.StatMaxHS = 40
    Flags.StatDmgSpread = true
    Flags.StatKillTiming = true
    Flags.StatMinKillGap = 4
    Flags.StatWeaponRot = true

    -- Viewmodel     Flags.VMEnabled = true
    Flags.VMScale = 100
    Flags.VMBob = 1
    Flags.VMSway = 1

    -- Chat     Flags.ChatAutoGG = true

    AIState.Mode = "Safe"
    logDecision("MODE: Safe Mode activated", "All HVH disabled, all stealth enabled")

    pcall(function()
         StarterGui:SetCore("SendNotification", {
            Title = "[SMART AI]",
            Text = "\n\nLegit Aimbot + ESP",
            Duration = 5,
        })
    end)
end

-- -- AGGRESSIVE MODE HVH?-- function AI.activateAggressiveMode()
    -- Rage      Flags.Ragebot = true
    Flags.RageFOV = 180
    Flags.RageHC = 85
    Flags.RageBone = "Head"
    Flags.RageSort = "Crosshair"
    Flags.RageAF = true
    Flags.RageFR = 12
    Flags.RageDT = true
    Flags.RageDTD = 6
    Flags.RageWall = true
    Flags.RagePen = 70
    Flags.RagePred = true
    Flags.RagePredF = 35
    Flags.RageRes = true
    Flags.RageResS = 8
    Flags.RageSmartBody = true
    Flags.RageMinDmg = 1
    Flags.RageSafe = true
    Flags.RageAutoReload = true

    -- Silent Aim      Flags.SilentAim = true
    Flags.SAFov = 140
    Flags.SAHC = 92
    Flags.SABone = "Head"
    Flags.SAPred = true
    Flags.SAPredT = 30
    Flags.SAAF = true
    Flags.SASwitch = 80
    Flags.SABacktrack = true
    Flags.SABTT = 200
    Flags.SAAutoWall = true
    Flags.SAWallPen = 70
    Flags.SALagComp = true
    Flags.SALCTicks = 8
    Flags.SA360 = true
    Flags.SA360Range = 360
    Flags.SABackwards = true
    Flags.SABackDir = "Away"
    Flags.SAHitSound = true

    -- Anti-Aim      Flags.AA = true
    Flags.AAPitch = "Down"
    Flags.AAYaw = "LBY Break"
    Flags.AASpd = 12
    Flags.AAJittR = 100
    Flags.AAFakeDuck = true
    Flags.AAFDC = 8
    Flags.AAFree = true
    Flags.AAEdge = true
    Flags.AALBY = true
    Flags.AALBYO = 120
    Flags.AAAnimBreak = true
    Flags.AAAnimStyle = "Breaker"
    Flags.AADesync = true
    Flags.AADesyncR = 90
    Flags.AADynJitt = true
    Flags.AADynMin = 30
    Flags.AADynMax = 150
    Flags.AABodyFlip = true
    Flags.AABodyFlipInt = 5
    Flags.AAMoveManip = true
    Flags.AAMoveStr = 8
    Flags.AAAntiRes = true
    Flags.AABruteMiss = true
    Flags.AABruteSteps = 4
    Flags.AASlowAA = true
    Flags.AAAirAA = true
    Flags.AAAntiUntrust = true
    Flags.AASlowLBY = true

    -- Fake Lag      Flags.FL = true
    Flags.FLChoke = 7
    Flags.FLStyle = "Adaptive"
    Flags.FLVar = 20
    Flags.FLFakeWalk = true
    Flags.FLFWS = 4
    Flags.FLBLC = true

    -- Resolver      Flags.Resolver = true
    Flags.ResMode = "Smart"
    Flags.ResSteps = 8
    Flags.ResAuto = true
    Flags.ResAB = true
    Flags.ResVelTrack = true
    Flags.ResPosTrack = true
    Flags.ResAdaptive = true
    Flags.ResSmart = true
    Flags.ResAntiBrute = true
    Flags.ResAutoSw = true
    Flags.ResMiss = true

    -- Flags.Bhop = true
    Flags.BhopMode = "HvH"
    Flags.BhopSpeed = 30
    Flags.BhopDelay = 0
    Flags.BhopStrafe = true
    Flags.BhopStrafeSpd = 15
    Flags.BhopStrafePattern = "Aggressive"
    Flags.BhopAirAccel = true
    Flags.BhopAirAccelVal = 15
    Flags.SpeedBoost = true
    Flags.NoClip = false  -- too obvious

    -- ESP      Flags.ESP_Box = true
    Flags.ESPBoxStyle = "Corners"
    Flags.ESP_Name = true
    Flags.ESP_Health = true
    Flags.ESP_HealthText = true
    Flags.ESP_Dist = true
    Flags.ESP_Weapon = true
    Flags.ESP_WeaponAmmo = true
    Flags.ESP_Skeleton = true
    Flags.ESP_Snaplines = true
    Flags.ESP_Headshot = true
    Flags.ESP_Velocity = true
    Flags.ESP_Glow = true
    Flags.ESP_Arrow = true
    Flags.ESP_InfoCard = true
    Flags.ESP_LaserLine = true
    Flags.ESP_HeadHit = true

    -- Flags.StealthHumanize = true
    Flags.StealthRandomTiming = true
    Flags.StealthAntiPattern = true
    Flags.StealthMaskHooks = true
    Flags.StealthHideGUI = true
    Flags.StealthHideCoreGui = true
    Flags.HVHSafeMode = true
    Flags.HVHBehavior = true
    Flags.HVHKillMask = true
    Flags.HVHAimDelay = true
    Flags.HVHAimDelayMin = 80
    Flags.HVHAimDelayMax = 200
    Flags.HVHFakeMiss = true
    Flags.HVHFakeMissRate = 10

    -- ML     Flags.MLEvasion = true
    Flags.MLEntropy = true
    Flags.MLMouseEntropy = true
    Flags.MLReaction = true
    Flags.MLMicroPause = true

    -- KillFX     Flags.KillSound = true
    Flags.KillAnimations = true
    Flags.KillBlur = true
    Flags.KillScreenShake = true
    Flags.KillBlood = true
    Flags.KillVignette = true
    Flags.KillRing = true
    Flags.KillChromatic = true

    -- Combat Assist     Flags.ChatAutoTaunt = true
    Flags.ChatAutoGG = true
    Flags.SpectatorAlert = true
    Flags.PlayerRating = true

    -- Viewmodel     Flags.VMEnabled = true
    Flags.VMScale = 90
    Flags.VMAngleX = -2
    Flags.VMAngleY = 2
    Flags.VMAngleZ = 0
    Flags.VMBob = 2
    Flags.VMSway = 2
    Flags.VMRecoil = 3

    AIState.Mode = "Aggressive"
    logDecision("MODE: Aggressive Mode activated", "All HVH enabled, all features ON")

    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "[AI] Rage Config",
            Text = "Ragebot + AA + SilentAim + FakeLag + Resolver + Bhop + Full ESP + Full HVH",
            Duration = 5,
        })
    end)
end

-- -- BALANCED MODE 
function AI.activateBalancedMode()
    -- Aimbot     Flags.Aimbot = true
    Flags.AimbotSmooth = 5
    Flags.AimbotFOV = 60
    Flags.AimbotBone = "Head"
    Flags.AimbotPredict = true
    Flags.AimbotHumanize = true
    Flags.AimbotTeamCheck = true
    Flags.AimbotWall = true
    Flags.TriggerBot = false

    -- Rage     Flags.Ragebot = false
    Flags.AA = false
    Flags.SilentAim = true
    Flags.SAFov = 90
    Flags.SAHC = 80
    Flags.FL = false
    Flags.Resolver = false
    Flags.NoClip = false
    Flags.SpeedBoost = false

    -- ESP     Flags.ESP_Box = true
    Flags.ESP_Name = true
    Flags.ESP_Health = true
    Flags.ESP_HealthText = true
    Flags.ESP_Dist = true
    Flags.ESP_Weapon = true
    Flags.ESP_Skeleton = true
    Flags.ESP_Snaplines = true
    Flags.ESP_Velocity = true
    Flags.ESP_Glow = true

    -- Flags.Bhop = true
    Flags.BhopMode = "Legit"
    Flags.BhopSpeed = 22
    Flags.BhopDelay = 0
    Flags.BhopStrafe = true
    Flags.BhopStrafeSpd = 8

    -- Flags.StealthHumanize = true
    Flags.StealthRandomTiming = true
    Flags.HVHSafeMode = true
    Flags.HVHMoveLegit = true
    Flags.HVHAimLegit = true

    -- KillFX     Flags.KillSound = true
    Flags.KillAnimations = true
    Flags.KillBlur = true
    Flags.KillScreenShake = false
    Flags.KillVignette = false

    -- Viewmodel     Flags.VMEnabled = true
    Flags.VMScale = 100

    AIState.Mode = "Balanced"
    logDecision("MODE: Balanced Mode activated", "Legit aimbot + Silent Aim + Full ESP + Legit Bhop")

    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "[AI] Legit Config",
            Text = "Aimbot + Silent Aim + Full ESP + Legit Bhop",
            Duration = 5,
        })
    end)
end

-- -- AUTO SELECT MODE AI 
function AI.autoSelectMode()
    assessLobbySkill()
    detectPlaystyle()
    analyzeEnemyBehavior()

    local perf = calcPerformanceScore()
    local skill = AIState.LobbySkillScore
    local style = AIState.Playstyle
    local risk = BS.Stealth and BS.Stealth.RiskLevel or 0
    local ping = BS.Ping and BS.Ping.Current or 50
    local indicators = AIState.LobbyIndicators or {}
    local confidence = AIState.PlaystyleConfidence or 50

    -- local safeScore = 0   -- 
    local aggrScore = 0   -- 
    local balScore = 0    -- 

    -- 1.      if skill > 80 then safeScore = safeScore + 40
    elseif skill > 65 then safeScore = safeScore + 25; balScore = balScore + 10
    elseif skill > 50 then balScore = balScore + 20
    elseif skill > 30 then aggrScore = aggrScore + 15; balScore = balScore + 10
    else aggrScore = aggrScore + 25 end

    -- 2.      if indicators.Cheaters then
        safeScore = safeScore + 50
    end

    -- 3. ?     if perf < 20 then aggrScore = aggrScore + 25 -- elseif perf < 40 then aggrScore = aggrScore + 15; balScore = balScore + 10
    elseif perf > 80 then balScore = balScore + 15 -- 
    end

    -- 4. 30 ?     local recentPerf = 0
    local recentCount = 0
    for _, entry in ipairs(AIState.PerformanceTrend) do
        if tick() - entry.Time < 30 then
            recentPerf = recentPerf + entry.Score
            recentCount = recentCount + 1
        end
    end
    if recentCount > 0 then
        recentPerf = recentPerf / recentCount
        if recentPerf > perf + 10 then
            -- TODO
            balScore = balScore + 10
        elseif recentPerf < perf - 15 then
            -- TODO
            aggrScore = aggrScore + 15
        end
    end

    -- 5.      if style == "Aggressive" then aggrScore = aggrScore + 15
    elseif style == "Tactical" then balScore = balScore + 15
    elseif style == "Sniper" then balScore = balScore + 10
    elseif style == "Runner" then aggrScore = aggrScore + 10
    elseif style == "Passive" then safeScore = safeScore + 10
    end

    -- 6. ?     if risk > 70 then safeScore = safeScore + 40
    elseif risk > 50 then safeScore = safeScore + 20
    elseif risk > 30 then balScore = balScore + 10
    end

    -- 7. Ping     if ping > 250 then safeScore = safeScore + 20
    elseif ping > 150 then safeScore = safeScore + 10
    elseif ping < 30 then aggrScore = aggrScore + 10 end

    -- 8. /     local recentKills = #deathAnalysis.RecentKills
    local recentDeaths = #deathAnalysis.RecentDeaths
    if recentKills > 4 then aggrScore = aggrScore + 15 -- 
    elseif recentDeaths > 3 then safeScore = safeScore + 15 -- 
    end

    -- 9.      local placeId = game.PlaceId
    if mapState.Maps[placeId] then
        local mapPerf = mapState.Maps[placeId].AvgPerformance
        if mapPerf < 35 then safeScore = safeScore + 10 -- elseif mapPerf > 70 then aggrScore = aggrScore + 10 end
    end

    -- 10.      local highThreatCount = 0
    for _, pattern in pairs(counterState.EnemyAimPatterns) do
        if pattern.ThreatScore > 50 then highThreatCount = highThreatCount + 1 end
    end
    if highThreatCount >= 3 then safeScore = safeScore + 20
    elseif highThreatCount >= 1 then balScore = balScore + 10 end

    -- 11.     if confidence > 80 then
        --  
        aggrScore = aggrScore + 10
    elseif confidence < 40 then
        --          safeScore = safeScore + 10
    end

    -- local maxScore = math.max(safeScore, aggrScore, balScore)
    local decision = "Balanced"

    if maxScore == safeScore and safeScore > aggrScore and safeScore > balScore then
        decision = "Safe"
    elseif maxScore == aggrScore and aggrScore > safeScore and aggrScore > balScore then
        decision = "Aggressive"
    else
        decision = "Balanced"
    end

    -- if decision == "Safe" then
        AI.activateSafeMode()
    elseif decision == "Aggressive" then
        AI.activateAggressiveMode()
    else
        AI.activateBalancedMode()
    end

    logDecision("AUTO SELECT: " .. decision,
        string.format("Safe=%d Aggr=%d Bal=%d | Skill=%.0f Perf=%.0f Risk=%d Ping=%d Style=%s",
            safeScore, aggrScore, balScore, skill, perf, risk, ping, style))
end

-- -- ADDITIONAL TUNERS -- 
-- Safety Tuner
    local function tuneSafety()
    if not Flags.AI_SafetyTune then return end
    local risk = BS.Stealth and BS.Stealth.RiskLevel or 0
    local perf = calcPerformanceScore()

    -- Auto-enable safety features based on risk
    if risk > 50 then
        Flags.StealthHumanize = true
        Flags.StealthRandomTiming = true
        Flags.StealthAntiPattern = true
        Flags.StealthMaskHooks = true
        Flags.HVHSafeMode = true
        Flags.MLEvasion = true
        Flags.MLEntropy = true
        Flags.MLMicroPause = true
        Flags.TrafficNoise = true
        Flags.AntiReplay = true
        Flags.ActionFuzz = true
        logDecision("Safety: Enhanced (risk=" .. risk .. "%)", "High risk")
    end

    if risk > 70 then
        -- Critical risk: disable dangerous features
        Flags.Ragebot = false
        Flags.AA = false
        Flags.NoClip = false
        Flags.SpeedBoost = false
        Flags.SilentAim = false
        logDecision("Safety: CRITICAL HVH disabled (risk=" .. risk .. "%)", "Very high risk")
    end

    -- Anti-stat: auto-adjust based on performance
    if perf > 80 then
        Flags.StatSmooth = true
        Flags.StatKDReg = true
        Flags.StatTargetKD = 25
        Flags.StatHSReg = true
        Flags.StatMaxHS = 50
    end

    -- Memory cleanup interval: faster on high risk
    if risk > 40 then
        Flags.MemCleanInt = 10
        Flags.MemRefClean = true
        Flags.MemGCObf = true
    end
end

-- HVH Tuner
    local function tuneHVH()
    if not Flags.AI_HVHTune then return end
    local perf = calcPerformanceScore()
    local lobbySkill = AIState.LobbySkillScore
    local ping = BS.Ping and BS.Ping.Current or 50

    -- Only tune if HVH features are active
    if not Flags.Ragebot and not Flags.AA then return end

    -- Ragebot tuning
    if Flags.Ragebot then
        local hc = 85
        if ping > 150 then hc = 70
        elseif ping > 100 then hc = 75 end
        if lobbySkill > 65 then hc = math.min(95, hc + 10) end
        if perf > 80 then hc = math.min(95, hc + 5) end
        Flags.RageHC = hc

        -- Auto body aim when missing
        if perf < 30 and Flags.RageSmartBody then
            Flags.RageBody = true
            Flags.RageHead = false
            logDecision("Rage: Switch to body aim (low perf)", "Performance: " .. perf)
        end
    end

    -- Anti-Aim tuning
    if Flags.AA then
        if lobbySkill > 65 then
            Flags.AAYaw = "LBY Break"
            Flags.AAJittR = 120
            Flags.AADesync = true
            Flags.AADesyncR = 120
        elseif lobbySkill < 30 then
            Flags.AAYaw = "Jitter"
            Flags.AAJittR = 80
        end

        -- Adjust AA speed based on ping
        if ping > 150 then
            Flags.AASpd = 8 -- slower AA on high ping
        else
            Flags.AASpd = 12
        end
    end

    -- Fake Lag tuning
    if Flags.FL then
        local choke = 7
        if lobbySkill > 60 then choke = 5
        elseif lobbySkill < 30 then choke = 10 end
        if ping > 150 then choke = math.max(2, choke - 3) end
        Flags.FLChoke = choke
    end

    -- Silent Aim tuning
    if Flags.SilentAim then
        local saFOV = 90
        if lobbySkill > 65 then saFOV = 140 end
        if ping > 100 then saFOV = math.min(180, saFOV + 30) end
        Flags.SAFov = saFOV
        Flags.SAHC = lobbySkill > 60 and 95 or 85
    end

    -- Resolver tuning
    if Flags.Resolver then
        Flags.ResSteps = lobbySkill > 60 and 10 or 6
        Flags.ResAdaptive = true
        Flags.ResSmart = true
    end
end

-- Viewmodel Tuner
    local function tuneViewmodel()
    if not Flags.AI_VMTune then return end
    local playstyle = AIState.Playstyle
    local perf = calcPerformanceScore()

    if not Flags.VMEnabled then return end

    if playstyle == "Sniper" then
        Flags.VMScale = 85
        Flags.VMAngleX = -3
        Flags.VMAngleY = 3
        Flags.VMBob = 0.5
        Flags.VMSway = 0.5
    elseif playstyle == "Aggressive" then
        Flags.VMScale = 95
        Flags.VMAngleX = -1
        Flags.VMAngleY = 1
        Flags.VMBob = 2
        Flags.VMSway = 2
        Flags.VMRecoil = 3
    elseif playstyle == "Tactical" then
        Flags.VMScale = 100
        Flags.VMAngleX = -2
        Flags.VMAngleY = 2
        Flags.VMBob = 1
        Flags.VMSway = 1
    else
        Flags.VMScale = 100
        Flags.VMBob = 1
        Flags.VMSway = 1
    end
end

-- World Tuner
    local function tuneWorld()
    if not Flags.AI_WorldTune then return end
    local perf = calcPerformanceScore()

    -- Low FPS disable heavy world features
    if BS.Perf and BS.Perf.FPS < 30 then
        Flags.Fullbright = true
        Flags.NoFog = true
        Flags.NoFlash = true
        Flags.RemoveSmoke = true
        -- Disable heavy effects
        Flags.ThirdPerson = false
    elseif BS.Perf and BS.Perf.FPS > 60 then
        Flags.Fullbright = true
        Flags.NoFog = true
    end
end

-- Chat Tuner
    local function tuneChat()
    if not Flags.AI_ChatTune then return end
    local perf = calcPerformanceScore()
    local style = AIState.Playstyle

    -- Auto GG enabled in all modes
    Flags.ChatAutoGG = true

    -- Taunt only when doing well
    if perf > 60 and style == "Aggressive" then
        Flags.ChatAutoTaunt = true
    else
        Flags.ChatAutoTaunt = false
    end

    -- Callout when doing well
    if perf > 50 then
        Flags.ChatAutoCallout = true
    else
        Flags.ChatAutoCallout = false
    end

    -- Spectator alert always on
    Flags.SpectatorAlert = true
    Flags.PlayerRating = true
end

-- Bypass Tuner
    local function tuneBypass()
    if not Flags.AI_BypassTune then return end
    local lobbySkill = AIState.LobbySkillScore
    local risk = BS.Stealth and BS.Stealth.RiskLevel or 0

    if lobbySkill > 60 or risk > 40 then
        -- Hard lobby / high risk maximum bypass
        Flags.SSVL = true
        Flags.SSVLVelCap = true
        Flags.SSVLMaxVel = 35
        Flags.SSVLDrift = true
        Flags.SSVLAccel = true
        Flags.SSVLMaxAccel = 60
        Flags.SSVLAngular = true
        Flags.SSVLMaxAngular = 50
        Flags.TrafficMask = true
        Flags.TrafficNoise = true
        Flags.TrafficBurst = true
        Flags.TrafficRemoteFP = true
        Flags.FPRotation = true
        Flags.FPRotInterval = 90
        logDecision("Bypass: Maximum (hard lobby)", "Skill: " .. lobbySkill)
    elseif lobbySkill > 40 then
        Flags.SSVL = true
        Flags.SSVLVelCap = true
        Flags.SSVLMaxVel = 45
        Flags.TrafficNoise = true
        Flags.FPRotation = true
        Flags.FPRotInterval = 120
    else
        Flags.SSVL = true
        Flags.SSVLMaxVel = 55
    end
end

-- Bhop Tuner
    local function tuneBhop()
    if not Flags.AI_BhopTune then return end
    local playstyle = AIState.Playstyle
    local lobbySkill = AIState.LobbySkillScore
    local perf = calcPerformanceScore()

    if not Flags.Bhop then return end

    if playstyle == "Runner" then
        Flags.BhopSpeed = 30
        Flags.BhopStrafeSpd = 15
        Flags.BhopStrafePattern = "Sinusoidal"
    elseif playstyle == "Aggressive" then
        Flags.BhopSpeed = 28
        Flags.BhopStrafeSpd = 12
        Flags.BhopStrafePattern = "Aggressive"
    elseif playstyle == "Tactical" then
        Flags.BhopSpeed = 22
        Flags.BhopStrafeSpd = 8
        Flags.BhopStrafePattern = "Smooth"
    else
        Flags.BhopSpeed = 24
        Flags.BhopStrafeSpd = 10
        Flags.BhopStrafePattern = "Linear"
    end

    -- Hard lobby more legit bhop
    if lobbySkill > 60 then
        Flags.BhopMode = "Legit"
        Flags.BhopSpeed = 20
        Flags.BhopStrafeSpd = 6
    end
end

-- -- SECTION 7: COUNTER-AIM SYSTEM
-- --
    local counterState = {
    EnemyAimPatterns = {},
    CounterActions = {},
}

local function analyzeEnemyBehavior()
    if not Flags.AI_CounterAim then return end

    local enemies = BS.enemies and BS.enemies() or {}
    local myHRP = BS.hrp()

    for _, e in ipairs(enemies) do
        if e.Player and e.HRP then
            local uid = e.Player.UserId
            local dist = myHRP and (myHRP.Position - e.HRP.Position).Magnitude or 999
            local vel = e.HRP.AssemblyLinearVelocity.Magnitude
            local h = e.Hum

            if not counterState.EnemyAimPatterns[uid] then
                counterState.EnemyAimPatterns[uid] = {
                    Name = e.Player.Name,
                    AvgDist = dist,
                    MovementType = "Unknown",
                    AggressionScore = 0,
                    ThreatScore = 0,
                    PositionHistory = {},
                    WeaponType = "unknown",
                    HeadshotTendency = 0,
                    ReactionPattern = {},
                    PeekPattern = 0,
                    -- LastSeen = tick(),
                }
            end

            local p = counterState.EnemyAimPatterns[uid]
            p.AvgDist = (p.AvgDist * 0.8) + (dist * 0.2) -- 
            p.LastSeen = tick()

            -- A.              table.insert(p.PositionHistory, { Time = tick(), Pos = e.HRP.Position, Vel = vel })
            if #p.PositionHistory > 30 then table.remove(p.PositionHistory, 1) end

            if vel > 25 then
                p.MovementType = "Fast"
                p.AggressionScore = p.AggressionScore + 1
            elseif vel < 2 then
                p.MovementType = "Static"
            elseif vel > 10 then
                p.MovementType = "Strafing"
            else
                p.MovementType = "Normal"
            end

            -- B.              if #p.PositionHistory >= 10 then
                local posVariance = 0
                local posCenter = Vector3.new(0, 0, 0)
                for _, ph in ipairs(p.PositionHistory) do
                    posCenter = posCenter + ph.Pos
                end
                posCenter = posCenter / #p.PositionHistory
                for _, ph in ipairs(p.PositionHistory) do
                    posVariance = posVariance + (ph.Pos - posCenter).Magnitude
                end
                posVariance = posVariance / #p.PositionHistory

                -- TODO
                -- TODO
                if posVariance > 30 then
                    p.PeekPattern = p.PeekPattern + 1
                end
            end

            -- C. ?             local tool = e.Char and e.Char:FindFirstChildWhichIsA("Tool")
            if tool then
                local name = tool.Name:lower()
                if name:find("awp") or name:find("sniper") then p.WeaponType = "sniper"
                elseif name:find("ak") or name:find("m4") then p.WeaponType = "rifle"
                elseif name:find("smg") or name:find("mp") then p.WeaponType = "smg"
                elseif name:find("shotgun") then p.WeaponType = "shotgun"
                end
            end

            -- D.             p.ThreatScore = 0
            if p.AvgDist < 15 then p.ThreatScore = p.ThreatScore + 35
            elseif p.AvgDist < 30 then p.ThreatScore = p.ThreatScore + 20 end
            if p.MovementType == "Fast" then p.ThreatScore = p.ThreatScore + 20
            elseif p.MovementType == "Strafing" then p.ThreatScore = p.ThreatScore + 15 end
            if p.AggressionScore > 5 then p.ThreatScore = p.ThreatScore + 20 end
            if p.WeaponType == "sniper" and p.AvgDist < 30 then p.ThreatScore = p.ThreatScore + 15 end
            if p.HeadshotTendency > 0.6 then p.ThreatScore = p.ThreatScore + 15 end
            if p.PeekPattern > 5 then p.ThreatScore = p.ThreatScore + 10 end

            -- 
            if BS.CheatDetect and BS.PlayerData[uid] then
                local cheatScore = BS.PlayerData[uid].TotalScore or 0
                if cheatScore > 60 then p.ThreatScore = p.ThreatScore + 30 end
                if cheatScore > 80 then p.ThreatScore = p.ThreatScore + 20 end
            end

            p.ThreatScore = math.min(100, p.ThreatScore)
        end
    end

    -- Auto counter based on enemy behavior
    local highThreatCount = 0
    for _, pattern in pairs(counterState.EnemyAimPatterns) do
        if pattern.ThreatScore > 50 then
            highThreatCount = highThreatCount + 1
        end
    end

    if highThreatCount >= 2 then
        -- Multiple aggressive enemies defensive strategy
        AIState.CounterStrategy = "Defensive"
        if Flags.AA then Flags.AAYaw = "LBY Break" end
        if Flags.FL then Flags.FLChoke = 10 end
        logDecision("Counter: Defensive (2+ aggressive enemies)", "Enemy analysis")
    elseif highThreatCount == 1 then
        AIState.CounterStrategy = "Targeted"
        logDecision("Counter: Targeted (1 aggressive enemy)", "Enemy analysis")
    else
        AIState.CounterStrategy = "None"
    end
end

-- -- SECTION 8: MAP ADAPTATION

local mapState = {
    Maps = {},  -- {placeId = {name, bestStrategy, avgPerformance, playCount}}
}

local function adaptToMap()
    if not Flags.AI_MapAdapt then return end

    local placeId = game.PlaceId
    if not mapState.Maps[placeId] then
        local mapName = "Unknown"
        pcall(function()
            mapName = game:GetService("MarketplaceService"):GetProductInfo(placeId).Name
        end)
        mapState.Maps[placeId] = {
            Name = mapName,
            BestStrategy = "Balanced",
            AvgPerformance = 50,
            PlayCount = 0,
            -- LastPlayed = tick(),
        }
    end

    local map = mapState.Maps[placeId]
    map.PlayCount = map.PlayCount + 1
    map.LastPlayed = tick()

    -- Adjust strategy based on map history
    if map.AvgPerformance < 40 then
        -- Bad performance on this map switch strategy
        if map.BestStrategy == "Aggressive" then
            map.BestStrategy = "Tactical"
        elseif map.BestStrategy == "Tactical" then
            map.BestStrategy = "Passive"
        else
            map.BestStrategy = "Aggressive"
        end
        logDecision("Map: Strategy " .. map.BestStrategy, map.Name .. " (low perf)")
    end
end

-- -- SECTION 9: SELF-LEARNING ENGINE
-- --
    local function learnFromHistory()
    if not Flags.AI_Learning then return end

    local history = AIState.SettingsHistory
    if #history < 5 then return end

    -- -- local now = tick()
    local weightedBest = nil
    local weightedBestScore = 0
    local decayRate = 0.005 -- 5 
    for _, entry in ipairs(history) do
        local age = now - entry.Time
        local timeWeight = math.exp(-decayRate * age / 60) -- 
        local perfWeight = entry.Performance * timeWeight

        if perfWeight > weightedBestScore then
            weightedBestScore = perfWeight
            weightedBest = entry
        end
    end

    -- -- Ping//    local contextBest = nil
    local contextBestScore = 0
    local currentPing = BS.Ping and BS.Ping.Current or 50
    local currentStyle = AIState.Playstyle
    local currentSkill = AIState.LobbySkillScore

    for _, entry in ipairs(history) do
        if entry.Performance > 60 then
            local score = entry.Performance
            -- 
            if entry.Ping and math.abs(entry.Ping - currentPing) < 30 then
                score = score + 15 -- Ping 
            end
            if entry.Playstyle == currentStyle then
                score = score + 10 -- 
            end
            if entry.LobbySkill and math.abs(entry.LobbySkill - currentSkill) < 15 then
                score = score + 10 -- 
            end
            if score > contextBestScore then
                contextBestScore = score
                contextBest = entry
            end
        end
    end

    -- local bestEntry = contextBest or weightedBest
    if bestEntry and bestEntry.Performance > 60 then
        local prevSettings = AIState.OptimalSettings or {}
        AIState.OptimalSettings = bestEntry.Settings or {}
        AIState.OptimalSettingsSource = contextBest and "Context" or "Global"
        logDecision("Learning: " .. (contextBest and "Context" or "Global") .. " optimal found",
            -- "Perf=" .. bestEntry.Performance .. " Context: Style=" .. currentStyle .. " Skill=" .. math.floor(currentSkill))
    end
end

-- Record current settings and performance for learning
local function recordPerformance()
    local perf = calcPerformanceScore()
    local settings = {
        AimbotFOV = Flags.AimbotFOV,
        AimbotSmooth = Flags.AimbotSmooth,
        RageHC = Flags.RageHC,
        FLChoke = Flags.FLChoke,
        BhopSpeed = Flags.BhopSpeed,
        AAPitch = Flags.AAPitch,
        AAYaw = Flags.AAYaw,
    }

    table.insert(AIState.SettingsHistory, {
        -- Time = tick(),
        Performance = perf,
        Settings = settings,
        Playstyle = AIState.Playstyle,
        LobbySkill = AIState.LobbySkill,
        Ping = BS.Ping and BS.Ping.Current or 0,
    })

    -- Keep only last 200 entries
    if #AIState.SettingsHistory > 200 then
        table.remove(AIState.SettingsHistory, 1)
    end

    -- Update map performance
    local placeId = game.PlaceId
    if mapState.Maps[placeId] then
        local map = mapState.Maps[placeId]
        map.AvgPerformance = (map.AvgPerformance + perf) / 2
    end
end

-- -- SECTION 10: THREAT RESPONSE SYSTEM

local function respondToThreat()
    if not Flags.AI_ThreatResp then return end

    local threat = AIState.LobbySkill
    local skill = AIState.LobbySkillScore
    local perf = calcPerformanceScore()
    local risk = BS.Stealth and BS.Stealth.RiskLevel or 0
    local indicators = AIState.LobbyIndicators or {}

    local prevThreat = AIState.ThreatLevel

    if threat == "Cheater" or indicators.Cheaters then
        AIState.ThreatLevel = "Critical"
        -- Flags.Ragebot = false
        Flags.SilentAim = false
        Flags.AA = false
        Flags.NoClip = false
        Flags.SpeedBoost = false
        Flags.FL = false
        Flags.StealthHumanize = true
        Flags.HVHSafeMode = true
        Flags.MLEvasion = true
        Flags.MLEntropy = true
        Flags.MLMicroPause = true
        pcall(function()
             StarterGui:SetCore("SendNotification", {
                Title = "? AI ?: CRITICAL",
                Text = "",
                Duration = 8,
            })
        end)
        logDecision("Threat: FULL SAFE (cheater detected)", threat)

    elseif threat == "VeryHard" or skill > 65 then
        AIState.ThreatLevel = "High"
        Flags.StealthHumanize = true
        Flags.HVHSafeMode = true
        if Flags.Ragebot then
            Flags.RageHC = 95
            Flags.RageSafe = true
        end
        if Flags.AA then
            Flags.AAYaw = "LBY Break"
            Flags.AAJittR = 120
        end
        if Flags.FL then Flags.FLChoke = 5 end
        if Flags.SilentAim then Flags.SAHC = 95 end
        logDecision("Threat: Max performance (very hard lobby)", threat)

    elseif threat == "Hard" or skill > 45 then
        AIState.ThreatLevel = "Elevated"
        Flags.StealthHumanize = true
        if Flags.Ragebot then Flags.RageHC = math.min(95, (Flags.RageHC or 85) + 5) end
        logDecision("Threat: Enhanced (hard lobby)", threat)

    elseif threat == "Medium" then
        AIState.ThreatLevel = "Normal"
    elseif threat == "Easy" then
        AIState.ThreatLevel = "Low"
        logDecision("Threat: Relaxed (easy lobby)", threat)
    else
        AIState.ThreatLevel = "Normal"
    end

    -- if prevThreat ~= AIState.ThreatLevel then
        pcall(function()
             StarterGui:SetCore("SendNotification", {
                Title = " AI ",
                Text = prevThreat .. " " .. AIState.ThreatLevel,
                Duration = 3,
            })
        end)
    end
end

-- -- SECTION 11: FULL ANALYSIS 
function AI.fullAnalysis()
    if not Flags.SmartAI then return end

    -- 1. Detect playstyle
    detectPlaystyle()

    -- 2. Assess lobby skill
    assessLobbySkill()

    -- 3. Analyze enemies
    analyzeEnemyBehavior()

    -- 4. Adapt to map
    adaptToMap()

    -- 5. Respond to threats
    respondToThreat()

    -- 6. Tune all systems
    tuneAimbot()
    tuneESP()
    tuneRage()
    tuneMovement()
    tuneStealth()
    tuneKillFX()

    -- 7. Learn from history
    learnFromHistory()

    -- 8. Record performance
    recordPerformance()

    -- 9. Show results
    AI.showStatus()

    pcall(function()
         StarterGui:SetCore("SendNotification", {
            Title = " AI ",
            -- Text = string.format(
                -- ": %s (%.0f%%)\n?: %s (%.0f%%)\n: %d/100\n: %s",
                AIState.Playstyle, AIState.PlaystyleConfidence,
                AIState.LobbySkill, AIState.LobbySkillScore,
                calcPerformanceScore(),
                AIState.CounterStrategy),
            Duration = 6,
        })
    end)
end

-- -- SECTION 12: AI STATUS DISPLAY
function AI.showStatus()
    local perf = calcPerformanceScore()
    local uptime = math.floor((tick() - AIState.SessionStartTime) / 60)

    local statusText = string.format(
        -- " AI \n" ..
        -- "\n" ..
        -- "?: %d/100\n" ..
        -- "?: %s (%.0f%%)\n" ..
        -- ": %s (%.0f%%)\n" ..
        -- ": %s\n" ..
        -- "?: %s\n" ..
        -- "\n" ..
        -- "K/D: %d/%d | HS: %d\n" ..
        -- " %.0f%%\n" ..
        -- ": %d\n" ..
        -- "?: %d",
        -- perf,
        AIState.Playstyle, AIState.PlaystyleConfidence,
        AIState.LobbySkill, AIState.LobbySkillScore,
        AIState.ThreatLevel,
        AIState.CounterStrategy,
        AIState.SessionKills, AIState.SessionDeaths, AIState.SessionHeadshots,
        AIState.SessionShots > 0 and (AIState.SessionHits / AIState.SessionShots * 100) or 0,
        -- uptime,
        -- #AIState.Decisions
    )

    pcall(function()
         StarterGui:SetCore("SendNotification", {
            Title = "[AI] Full Config"
            Text = statusText,
            Duration = 10,
        })
    end)
end

-- -- SECTION 13: RESET
function AI.resetLearning()
    AIState.SettingsHistory = {}
    AIState.OptimalSettings = {}
    AIState.Decisions = {}
    AIState.EnemyStats = {}
    AIState.PlaystyleHistory = {}
    AIState.SessionKills = 0
    AIState.SessionDeaths = 0
    AIState.SessionHeadshots = 0
    AIState.SessionShots = 0
    AIState.SessionHits = 0
    AIState.SessionDamage = 0
    AIState.SessionStartTime = tick()

    pcall(function()
         StarterGui:SetCore("SendNotification", {
            Title = " AI ?",
            Text = "",
            Duration = 3,
        })
    end)
end

-- -- SECTION 14: AI TRACKING -- -- Track kills
BS.Events = BS.Events or {}
BS.Events.OnKill = BS.Events.OnKill or function() end
local origOnKill = BS.Events.OnKill
BS.Events.OnKill = function(victim, headshot)
    origOnKill(victim, headshot)
    AIState.SessionKills = AIState.SessionKills + 1
    if headshot then AIState.SessionHeadshots = AIState.SessionHeadshots + 1 end

    -- Per-enemy tracking
    if victim and victim:IsA("Player") then
        local uid = victim.UserId
        if not AIState.EnemyStats[uid] then
            AIState.EnemyStats[uid] = {
                Name = victim.Name,
                TimesKilled = 0,
                TimesDied = 0,
                Headshots = 0,
            }
        end
        AIState.EnemyStats[uid].TimesKilled = AIState.EnemyStats[uid].TimesKilled + 1
        if headshot then AIState.EnemyStats[uid].Headshots = AIState.EnemyStats[uid].Headshots + 1 end
    end
end

-- Track deaths
BS.Events.OnDeath = BS.Events.OnDeath or function() end
local origOnDeath = BS.Events.OnDeath
BS.Events.OnDeath = function(killer)
    origOnDeath(killer)
    AIState.SessionDeaths = AIState.SessionDeaths + 1

    if killer and killer:IsA("Player") then
        local uid = killer.UserId
        if not AIState.EnemyStats[uid] then
            AIState.EnemyStats[uid] = { Name = killer.Name, TimesKilled = 0, TimesDied = 0, Headshots = 0 }
        end
        AIState.EnemyStats[uid].TimesDied = AIState.EnemyStats[uid].TimesDied + 1
    end
end

-- Track shots
BS.Events.OnShoot = BS.Events.OnShoot or function() end
local origOnShoot = BS.Events.OnShoot
BS.Events.OnShoot = function(hit)
    origOnShoot(hit)
    AIState.SessionShots = AIState.SessionShots + 1
    if hit then AIState.SessionHits = AIState.SessionHits + 1 end
end

-- -- MAIN AI LOOP 
-- task.spawn(function()
    while true do task.wait(5)
        if Flags.SmartAI and Flags.AI_AutoOpt then
            pcall(function()
                -- Core analysis every 5 seconds
                detectPlaystyle()
                assessLobbySkill()
                analyzeEnemyBehavior()
                respondToThreat()

                -- Tuning every 5 seconds (ALL parameters)
                tuneAimbot()
                tuneESP()
                tuneRage()
                tuneMovement()
                tuneStealth()
                tuneKillFX()
                tuneSafety()
                tuneHVH()
                tuneViewmodel()
                tuneWorld()
                tuneChat()
                tuneBypass()
                tuneBhop()

                -- Map adaptation
                adaptToMap()
            end)
        end
    end
end)

-- Record performance periodically
task.spawn(function()
    while true do task.wait(30)
        if Flags.SmartAI and Flags.AI_Learning then
            pcall(function()
                recordPerformance()
                learnFromHistory()
            end)
        end
    end
end)

-- -- AI HUD DISPLAY  AI --
    local aiHUD = nil
task.spawn(function()
    while true do task.wait(0.3)
        if Flags.SmartAI and BS.alive() then
            if not aiHUD then
                pcall(function()
                    local _Compat = _G.BS and _G.BS.Compat; if _Compat and _Compat.DrawingNew then aiHUD = _Compat.DrawingNew("Text") else pcall(function() aiHUD = Drawing.new("Text") end) end
                    aiHUD.Center = false
                    aiHUD.Outline = true
                    aiHUD.OutlineColor = Color3.new(0, 0, 0)
                    aiHUD.Font = Drawing.Fonts.UI
                    aiHUD.Size = 12
                end)
            end
            local perf = calcPerformanceScore()
            local style = AIState.Playstyle
            local threat = AIState.LobbySkill
            local counter = AIState.CounterStrategy

            local color = perf > 70 and Color3.fromRGB(0, 255, 100)
                or perf > 40 and Color3.fromRGB(255, 255, 0)
                or Color3.fromRGB(255, 50, 50)

            aiHUD.Text = string.format("AI: %s [%s] | Threat: %s | Counter: %s | Perf: %d",
                style, threat, AIState.ThreatLevel, counter, perf)
            aiHUD.Color = color
            aiHUD.Position = Vector2.new(10, 505)
            aiHUD.Visible = true
        else
            if aiHUD then aiHUD.Visible = false end
        end
    end
end)

-- Expose BS.SmartAI = AI
BS.AIState = AIState

print("[SmartAI] BloxStrike Smart AI v2.0 loaded")
print("[SmartAI] Features: Playstyle Detection, Lobby Assessment,")
print("[SmartAI]   Auto Aimbot/ESP/Rage/Movement/Stealth/Viewmodel/World/Chat/Bypass/Bhop Tuning,")
print("[SmartAI]   Safety Mode, Aggressive Mode, Balanced Mode, Auto Select,")
print("[SmartAI]   Counter-Aim, Threat Response, Map Adaptation,")
print("[SmartAI]   Self-Learning, AI HUD Display"
