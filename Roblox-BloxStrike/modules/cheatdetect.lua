

-- BLOXSTRIKE CHEAT DETECT MODULE v1.0

-- : Aimbot, Wallhack, ESP, SpeedHack, Triggerbot,
--         Spinbot, Teleport, Macro, NoRecoil, SilentAim

local Players = nil

pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local UserInputService = nil
pcall(function() UserInputService = game:GetService("UserInputService") end)
local StarterGui = nil
pcall(function() StarterGui = game:GetService("StarterGui") end)
local HttpService = nil
pcall(function() HttpService = game:GetService("HttpService") end)
local lplr = Players.LocalPlayer

if not BS.Win then warn("[Cheat Detect] BS.Win not available - ui.lua may have failed") return end
local page = BS.Win:Tab("關於")
if not page or not page.Toggle then warn("[CheatDetect] Failed to create tab!") return end

local CD = {}
BS.CheatDetect = CD

-- SECTION 1: 

page:Label("   ")
page:Toggle("Cheat Detect", true, function(v) Flags.CheatDetect = v end)
page:Toggle("Auto Scan", true, function(v) Flags.CD_AutoScan = v end)
page:Slider("Scan Interval", 1, 10, 3, function(v) Flags.CD_ScanInterval = v end)
page:Slider("Min Confidence", 30, 95, 60, function(v) Flags.CD_MinConfidence = v end)
page:Toggle("Show Alerts", true, function(v) Flags.CD_Alerts = v end)
page:Toggle("Auto Report", false, function(v) Flags.CD_AutoReport = v end)
page:Toggle("Sound Alert", true, function(v) Flags.CD_SoundAlert = v end)
page:Toggle("Lobby Summary", true, function(v) Flags.CD_LobbySummary = v end)
page:Toggle("Match Start Scan", true, function(v) Flags.CD_MatchStart = v end)
page:Toggle("Persistent Banner", true, function(v) Flags.CD_Banner = v end)
page:Toggle("Suspect ESP Marker", true, function(v) Flags.CD_SuspectMarker = v end)
page:Slider("Alert Threshold", 30, 90, 50, function(v) Flags.CD_AlertThreshold = v end)
page:Slider("Warn Threshold", 50, 95, 70, function(v) Flags.CD_WarnThreshold = v end)
page:Slider("Critical Threshold", 70, 99, 85, function(v) Flags.CD_CriticalThreshold = v end)
page:Button({Name=" ", Color=Color3.fromRGB(255, 50, 50)}, function()
    CD.fullScan()
end)
page:Button({Name=" ", Color=Color3.fromRGB(0, 200, 255)}, function()
    CD.showReport()
end)
page:Button({Name=" ", Color=Color3.fromRGB(200, 100, 100)}, function()
    CD.clearAll()
end)

-- SECTION 2: 

page:Label("  ")
page:Toggle("Aimbot Detect", true, function(v) Flags.CD_Aimbot = v end)
page:Toggle("Wallhack Detect", true, function(v) Flags.CD_Wallhack = v end)
page:Toggle("ESP Detect", true, function(v) Flags.CD_ESP = v end)
page:Toggle("Triggerbot Detect", true, function(v) Flags.CD_Trigger = v end)
page:Toggle("Spinbot Detect", true, function(v) Flags.CD_Spin = v end)
page:Toggle("Teleport Detect", true, function(v) Flags.CD_Teleport = v end)
page:Toggle("Macro Detect", true, function(v) Flags.CD_Macro = v end)
page:Toggle("NoRecoil Detect", true, function(v) Flags.CD_NoRecoil = v end)
page:Toggle("SilentAim Detect", true, function(v) Flags.CD_SilentAim = v end)
page:Toggle("Snapbot Detect", true, function(v) Flags.CD_Snap = v end)
page:Toggle("Flick Detect", true, function(v) Flags.CD_Flick = v end)
page:Toggle("RCS Detect", true, function(v) Flags.CD_RCS = v end)
page:Toggle("Bhop Detect", true, function(v) Flags.CD_Bhop = v end)
page:Toggle("ThirdPerson Detect", true, function(v) Flags.CD_ThirdPerson = v end)

-- CORE STATE  

local PlayerData = {}
-- PlayerData[uid] = {
--   Name, PositionHistory[], VelocityHistory[], CameraHistory[],
--   ShotHistory[], KillTimestamps[], DeathTimestamps[],
--   DamageDealtTo[], DamageReceivedFrom[],
--   AimAngles[], ReactionTimes[],
--   Flags = {Aimbot=0, Wallhack=0, ESP=0, Speed=0, Trigger=0, ...},
--   Confidence = {Aimbot=0, Wallhack=0, ...},
--   TotalScore = 0,
--   LastScan = 0,
-- }

local function getPlayerData(uid)
    if not PlayerData[uid] then
        PlayerData[uid] = {
            Name = "Unknown",
            PositionHistory = {},
            VelocityHistory = {},
            CameraHistory = {},
            ShotTimestamps = {},
            KillTimestamps = {},
            DeathTimestamps = {},
            DamageDealt = {},     -- {time, damage, isHeadshot}
            DamageReceived = {},  -- {time, damage, from}
            AimSnaps = {},        -- {time, angle, speed, targetVisible}
            ReactionTimes = {},   -- {time, reactionMs}
            HitPositions = {},    -- {time, pos, targetVisible, throughWall}
            HeadshotRate = 0,
            TotalKills = 0,
            TotalDeaths = 0,
            TotalShots = 0,
            TotalHits = 0,
            -- Detection scores (0-100)
            Flags = {
                Aimbot = 0,
                Wallhack = 0,
                ESP = 0,
                Trigger = 0,
                Spinbot = 0,
                Teleport = 0,
                Macro = 0,
                NoRecoil = 0,
                SilentAim = 0,
                Snapbot = 0,
                Flick = 0,
                RCS = 0,
                Bhop = 0,
                ThirdPerson = 0,
            },
            TotalScore = 0,
            LastScan = 0,
            ScanCount = 0,
            -- FirstSeen = tick(),
        }
    end
    return PlayerData[uid]
end

-- STATISTICAL UTILITIES  

local function calcMean(t)
    if #t == 0 then return 0 end
    local sum = 0
    for _, v in ipairs(t) do sum = sum + v end
    return sum / #t
end

local function calcSD(t)
    if #t < 2 then return 0 end
    local mean = calcMean(t)
    local sumSq = 0
    for _, v in ipairs(t) do sumSq = sumSq + (v - mean) ^ 2 end
    return math.sqrt(sumSq / (#t - 1))
end

local function calcCV(t)
    local mean = calcMean(t)
    local sd = calcSD(t)
    if mean == 0 then return 0 end
    return sd / math.abs(mean)
end

local function calcAutocorr(t, lag)
    if #t < lag + 2 then return 0 end
    local mean = calcMean(t)
    local num, den = 0, 0
    for i = 1, #t - lag do
        num = num + (t[i] - mean) * (t[i + lag] - mean)
        den = den + (t[i] - mean) ^ 2
    end
    if den == 0 then return 0 end
    return num / den
end

-- SECTION 3: AIMBOT DETECTOR  
-- ///

local function detectAimbot(uid)
    if not Flags.CD_Aimbot then return 0 end
    local data = PlayerData[uid]
    if not data or #data.AimSnaps < 15 then return 0 end

    local score = 0
    local evidence = 0

     -- Test 1:
    local snapSpeeds = {}
    for i = 2, #data.AimSnaps do
        local dt = data.AimSnaps[i].Time - data.AimSnaps[i-1].Time
        if dt > 0.005 and dt < 0.5 then
            local angleDiff = math.abs(data.AimSnaps[i].Angle - data.AimSnaps[i-1].Angle)
            table.insert(snapSpeeds, angleDiff / dt)
        end
    end
    if #snapSpeeds > 8 then
        local avgSpeed = calcMean(snapSpeeds)
        local sdSpeed = calcSD(snapSpeeds)
        local cvSpeed = calcCV(snapSpeeds)
        -- : 100-400 deg/s, : 800+ deg/s
        if avgSpeed > 1200 then score = score + 35; evidence = evidence + 1
        elseif avgSpeed > 800 then score = score + 25; evidence = evidence + 1
        elseif avgSpeed > 500 then score = score + 10
        end
        -- CV 
        if cvSpeed < 0.15 and avgSpeed > 400 then score = score + 15; evidence = evidence + 1 end
    end

     -- Test 2:
    local snapAngles = {}
    for _, snap in ipairs(data.AimSnaps) do
        table.insert(snapAngles, snap.Angle)
    end
    if #snapAngles > 20 then
        local ac1 = calcAutocorr(snapAngles, 1)
        local ac3 = calcAutocorr(snapAngles, 3)
        -- : , : 
        if math.abs(ac1) < 0.05 and math.abs(ac3) < 0.05 then
            score = score + 20; evidence = evidence + 1
        elseif ac1 < -0.1 then
            score = score + 15; evidence = evidence + 1 --  =  = 
        end
        --   
        local smallSnaps = 0
        local largeSnaps = 0
        for _, a in ipairs(snapAngles) do
            if a < 5 then smallSnaps = smallSnaps + 1
            elseif a > 30 then largeSnaps = largeSnaps + 1 end
        end
        local total = #snapAngles
        if total > 15 then
            local bimodalScore = (smallSnaps / total) * (largeSnaps / total) * 4
            if bimodalScore > 0.3 then score = score + 10; evidence = evidence + 1 end
        end
    end

     -- Test 3:
    local headKills = 0
    local totalKills = 0
    for _, dmg in ipairs(data.DamageDealt) do
        if dmg.IsHeadshot then headKills = headKills + 1 end
        totalKills = totalKills + 1
    end
    if totalKills > 5 then
        local hsRate = headKills / totalKills
        --  N  X 
        --  25-40% 70%+
        if hsRate > 0.85 and totalKills > 8 then score = score + 25; evidence = evidence + 2
        elseif hsRate > 0.70 and totalKills > 10 then score = score + 15; evidence = evidence + 1
        elseif hsRate > 0.60 and totalKills > 15 then score = score + 8
        end
    end

     -- Test 4:
    if #data.ReactionTimes > 10 then
        local avgReact = calcMean(data.ReactionTimes)
        local cvReact = calcCV(data.ReactionTimes)
        --  +  = 
        if cvReact < 0.05 and avgReact < 200 then score = score + 15; evidence = evidence + 1
        elseif avgReact < 60 then score = score + 20; evidence = evidence + 2 -- 60ms  = 
        elseif avgReact < 100 then score = score + 10
        end
    end

     -- Test 5:
    if #data.AimSnaps > 30 then
        -- 
        local angleVariance = calcSD(snapAngles) ^ 2
        if angleVariance < 100 and #snapAngles > 20 then
            score = score + 10; evidence = evidence + 1 --  = 
        end
    end

    -- 
    if evidence < 2 then score = math.floor(score * 0.6) end
    if evidence >= 4 then score = math.min(100, score + 10) end

    return math.min(100, score)
end

-- SECTION 4: WALLHACK DETECTOR  

local function detectWallhack(uid)
    if not Flags.CD_Wallhack then return 0 end
    local data = PlayerData[uid]
    if not data or #data.PositionHistory < 20 then return 0 end

    local score = 0
    local evidence = 0
    local suspect = Players:GetPlayerByUserId(uid)
    if not suspect or not suspect.Character then return 0 end
    local theirHRP = suspect and suspect.Character:FindFirstChild("HumanoidRootPart")
    if not theirHRP then return 0 end

     -- Test 1:
    local wallHits = 0
    local totalHits = 0
    for _, hit in ipairs(data.HitPositions) do
        totalHits = totalHits + 1
        if hit.ThroughWall then wallHits = wallHits + 1 end
    end
    if totalHits > 5 then
        local wallHitRate = wallHits / totalHits
        if wallHitRate > 0.5 then score = score + 35; evidence = evidence + 2
        elseif wallHitRate > 0.3 then score = score + 20; evidence = evidence + 1
        elseif wallHitRate > 0.15 then score = score + 10
        end
    end

     -- Test 2:
    local preAimCount = 0
    local totalAimChecks = 0
    for _, snap in ipairs(data.AimSnaps) do
        totalAimChecks = totalAimChecks + 1
        if not snap.TargetVisible then preAimCount = preAimCount + 1 end
    end
    if totalAimChecks > 10 then
        local preAimRate = preAimCount / totalAimChecks
        if preAimRate > 0.6 then score = score + 30; evidence = evidence + 2
        elseif preAimRate > 0.4 then score = score + 20; evidence = evidence + 1
        elseif preAimRate > 0.25 then score = score + 10
        end
    end

     -- Test 3:
    local trackThroughWalls = 0
    local totalTrackChecks = 0
    for _, cam in ipairs(data.CameraHistory) do
        totalTrackChecks = totalTrackChecks + 1
        if cam.LookingAtHidden then trackThroughWalls = trackThroughWalls + 1 end
    end
    if totalTrackChecks > 10 then
        local trackRate = trackThroughWalls / totalTrackChecks
        if trackRate > 0.5 then score = score + 25; evidence = evidence + 2
        elseif trackRate > 0.3 then score = score + 15; evidence = evidence + 1
        end
    end

     -- Test 4:
    local instantReactions = 0
    for _, react in ipairs(data.ReactionTimes) do
        if react < 50 then instantReactions = instantReactions + 1 end
    end
    if #data.ReactionTimes > 5 then
        local instantRate = instantReactions / #data.ReactionTimes
        if instantRate > 0.3 then score = score + 15; evidence = evidence + 1
        elseif instantRate > 0.15 then score = score + 10
        end
    end

     -- Test 5:
    if #data.AimSnaps > 15 then
        local invisibleAimSnaps = 0
        local visibleAimSnaps = 0
        for _, snap in ipairs(data.AimSnaps) do
            if snap.TargetVisible then visibleAimSnaps = visibleAimSnaps + 1
            else invisibleAimSnaps = invisibleAimSnaps + 1 end
        end
        local total = visibleAimSnaps + invisibleAimSnaps
        if total > 10 then
            local invisibleRatio = invisibleAimSnaps / total
            -- 
            if invisibleRatio > 0.6 then score = score + 15; evidence = evidence + 1 end
        end
    end

     -- Test 6:
    if #data.PositionHistory > 20 then
        local avoidCount = 0
        for i = 5, #data.PositionHistory do
            local dt = data.PositionHistory[i].Time - data.PositionHistory[i-1].Time
            if dt > 0 and dt < 0.5 then
                local vel = data.PositionHistory[i].Pos - data.PositionHistory[i-1].Pos
                local speed = vel.Magnitude / dt
                --  = 
                if i > 5 then
                    local prevVel = data.PositionHistory[i-1].Pos - data.PositionHistory[i-2].Pos
                    if prevVel.Magnitude > 0.1 then
                        local angle = math.acos(math.clamp(vel.Unit:Dot(prevVel.Unit), -1, 1))
                        if angle > 2.5 and speed > 15 then avoidCount = avoidCount + 1 end
                    end
                end
            end
        end
        if avoidCount > 5 then score = score + 10; evidence = evidence + 1 end
    end

    if evidence < 2 then score = math.floor(score * 0.5) end
    if evidence >= 4 then score = math.min(100, score + 10) end
    return math.min(100, score)
end

-- SECTION 5: ESP DETECTOR

local function detectESP(uid)
    if not Flags.CD_ESP then return 0 end
    local data = PlayerData[uid]
    if not data or #data.CameraHistory < 15 then return 0 end

    local score = 0
    local evidence = 0
    local suspect = Players:GetPlayerByUserId(uid)
    if not suspect or not suspect.Character then return 0 end

     -- Test 1:
    local hiddenLookCount = 0
    local totalCamSamples = #data.CameraHistory
    for _, cam in ipairs(data.CameraHistory) do
        if cam.LookingAtHidden then hiddenLookCount = hiddenLookCount + 1 end
    end
    if totalCamSamples > 15 then
        local rate = hiddenLookCount / totalCamSamples
        if rate > 0.4 then score = score + 30; evidence = evidence + 2
        elseif rate > 0.25 then score = score + 20; evidence = evidence + 1
        elseif rate > 0.15 then score = score + 10
        end
    end

     -- Test 2:
    local trackingEvents = 0
    for i = 10, #data.CameraHistory do
        if data.CameraHistory[i].HiddenTargetVelocity then
            trackingEvents = trackingEvents + 1
        end
    end
    if trackingEvents > 5 then
        score = score + math.min(25, trackingEvents * 3)
        evidence = evidence + 1
    end

     -- Test 3: ESP
    local cornerChecks = 0
    for _, snap in ipairs(data.AimSnaps) do
        if snap.IsCornerCheck then cornerChecks = cornerChecks + 1 end
    end
    if cornerChecks > 10 then
        score = score + math.min(20, cornerChecks * 1.5)
        evidence = evidence + 1
    end

     -- Test 4: ESP
    if #data.AimSnaps > 15 then
        local wallTargetSnaps = 0
        for _, snap in ipairs(data.AimSnaps) do
            if not snap.TargetVisible and snap.Angle and snap.Angle > 10 then
                wallTargetSnaps = wallTargetSnaps + 1
            end
        end
        local totalSnaps = #data.AimSnaps
        if totalSnaps > 10 then
            local wallTargetRate = wallTargetSnaps / totalSnaps
            if wallTargetRate > 0.5 then score = score + 15; evidence = evidence + 1 end
        end
    end

    if evidence < 2 then score = math.floor(score * 0.6) end
    if evidence >= 3 then score = math.min(100, score + 8) end
    return math.min(100, score)
end

-- SECTION 6: SPEEDHACK DETECTOR

local function detectSpeedhack(uid)
    if not Flags.CD_Speed then return 0 end
    local data = PlayerData[uid]
    if not data or #data.PositionHistory < 20 then return 0 end

    local score = 0

    -- Test 1: Movement speed analysis
    local speeds = {}
    for i = 2, #data.PositionHistory do
        local dt = data.PositionHistory[i].Time - data.PositionHistory[i-1].Time
        if dt > 0.01 and dt < 1 then
            local dist = (data.PositionHistory[i].Pos - data.PositionHistory[i-1].Pos).Magnitude
            local speed = dist / dt
            table.insert(speeds, speed)
        end
    end

    if #speeds > 10 then
        -- Calculate average and max speed
        local totalSpeed = 0
        local maxSpeed = 0
        local burstCount = 0
        for _, s in ipairs(speeds) do
            totalSpeed = totalSpeed + s
            maxSpeed = math.max(maxSpeed, s)
            if s > 50 then burstCount = burstCount + 1 end -- >50 studs/s is very fast
        end
        local avgSpeed = totalSpeed / #speeds

        -- Normal walk: ~16 studs/s, Sprint: ~20-25, SpeedHack: 50+
        if maxSpeed > 100 then score = score + 35
        elseif maxSpeed > 60 then score = score + 25
        elseif maxSpeed > 40 then score = score + 15
        end

        if avgSpeed > 30 then score = score + 15
        elseif avgSpeed > 25 then score = score + 10
        end

        -- Burst detection: sudden speed spikes
        if burstCount > 5 then score = score + 15
        elseif burstCount > 2 then score = score + 8
        end
    end

    -- Test 2: Position consistency (no micro-stuttering = inhuman)
    if #data.PositionHistory > 20 then
        local posDiffs = {}
        for i = 2, math.min(50, #data.PositionHistory) do
            local dt = data.PositionHistory[i].Time - data.PositionHistory[i-1].Time
            if dt > 0.01 and dt < 0.1 then
                local dist = (data.PositionHistory[i].Pos - data.PositionHistory[i-1].Pos).Magnitude / dt
                table.insert(posDiffs, dist)
            end
        end
        if #posDiffs > 10 then
            local mean = 0
            for _, d in ipairs(posDiffs) do mean = mean + d end
            mean = mean / #posDiffs
            local variance = 0
            for _, d in ipairs(posDiffs) do variance = variance + (d - mean) ^ 2 end
            variance = variance / #posDiffs
            local cv = math.sqrt(variance) / math.max(mean, 1)
            -- Very smooth movement = speed hack (humans have micro-stutter)
            if cv < 0.1 and mean > 20 then score = score + 15 end
        end
    end

    return math.min(100, score)
end

-- SECTION 7: TRIGGERBOT DETECTOR

local function detectTriggerbot(uid)
    if not Flags.CD_Trigger then return 0 end
    local data = PlayerData[uid]
    if not data or #data.ShotTimestamps < 15 then return 0 end

    local score = 0
    local evidence = 0

     -- Test 1:
    local intervals = {}
    for i = 2, #data.ShotTimestamps do
        local dt = (data.ShotTimestamps[i] - data.ShotTimestamps[i-1]) * 1000
        if dt > 5 and dt < 1000 then table.insert(intervals, dt) end
    end

    if #intervals > 10 then
        local cv = calcCV(intervals)
        local meanInterval = calcMean(intervals)
        local sdInterval = calcSD(intervals)
        --  = 
        if cv < 0.02 and meanInterval < 200 then score = score + 35; evidence = evidence + 2
        elseif cv < 0.05 and meanInterval < 150 then score = score + 25; evidence = evidence + 1
        elseif cv < 0.08 then score = score + 10
        end
        -- 
        if meanInterval < 50 then score = score + 15; evidence = evidence + 1
        elseif meanInterval < 80 then score = score + 8
        end
    end

     -- Test 2:
    if #intervals > 20 then
        local ac1 = calcAutocorr(intervals, 1)
        local ac2 = calcAutocorr(intervals, 2)
        -- 
        if ac1 > 0.95 and ac2 > 0.9 then score = score + 20; evidence = evidence + 2 end
        if ac1 > 0.8 then score = score + 10; evidence = evidence + 1 end
    end

     -- Test 3:
    local fastShots = 0
    for _, snap in ipairs(data.AimSnaps) do
        if snap.TimeToFire and snap.TimeToFire < 80 then fastShots = fastShots + 1 end
    end
    if #data.AimSnaps > 10 then
        local fastRate = fastShots / #data.AimSnaps
        if fastRate > 0.7 then score = score + 20; evidence = evidence + 1
        elseif fastRate > 0.5 then score = score + 10
        end
    end

     -- Test 4:
    if #intervals > 15 then
        local patternMatch = 0
        for plen = 2, math.min(5, math.floor(#intervals / 3)) do
            local matches = 0
            for i = 1, #intervals - plen do
                if math.abs(intervals[i] - intervals[i + plen]) < 1 then matches = matches + 1 end
            end
            if matches / (#intervals - plen) > 0.8 then patternMatch = plen; break end
        end
        if patternMatch > 0 then score = score + 15; evidence = evidence + 1 end
    end

    if evidence < 2 then score = math.floor(score * 0.5) end
    if evidence >= 3 then score = math.min(100, score + 8) end
    return math.min(100, score)
end

-- SECTION 8: SPINBOT DETECTOR

local function detectSpinbot(uid)
    if not Flags.CD_Spin then return 0 end
    local data = PlayerData[uid]
    if not data or #data.CameraHistory < 20 then return 0 end

    local score = 0
    local evidence = 0

     -- Test 1:
    local rotSpeeds = {}
    for i = 2, #data.CameraHistory do
        local dt = data.CameraHistory[i].Time - data.CameraHistory[i-1].Time
        if dt > 0.005 and dt < 0.5 then
            local angleDiff = math.abs(data.CameraHistory[i].Yaw - data.CameraHistory[i-1].Yaw)
            if angleDiff > 180 then angleDiff = 360 - angleDiff end
            table.insert(rotSpeeds, angleDiff / dt)
        end
    end

    if #rotSpeeds > 10 then
        local avgRot = calcMean(rotSpeeds)
        local maxRot = 0
        for _, s in ipairs(rotSpeeds) do maxRot = math.max(maxRot, s) end
        -- : max ~800 deg/s, : 2000+ deg/s
        if maxRot > 3000 then score = score + 40; evidence = evidence + 2
        elseif maxRot > 2000 then score = score + 30; evidence = evidence + 1
        elseif maxRot > 1200 then score = score + 15
        end
        if avgRot > 1000 then score = score + 15; evidence = evidence + 1
        elseif avgRot > 600 then score = score + 8
        end
    end

     -- Test 2:
    if #rotSpeeds > 20 then
        local ac1 = calcAutocorr(rotSpeeds, 1)
        local ac3 = calcAutocorr(rotSpeeds, 3)
        -- 
        if ac1 > 0.9 and ac3 > 0.8 then score = score + 20; evidence = evidence + 2 end
        if ac1 > 0.7 then score = score + 10; evidence = evidence + 1 end
        -- 
        local cvRot = calcCV(rotSpeeds)
        if cvRot < 0.1 and avgRot > 500 then score = score + 10; evidence = evidence + 1 end
    end

     -- Test 3: 360
    if #data.CameraHistory > 15 then
        local yawChanges = {}
        for i = 2, #data.CameraHistory do
            local dt = data.CameraHistory[i].Time - data.CameraHistory[i-1].Time
            if dt > 0 and dt < 1 then
                local yawDiff = data.CameraHistory[i].Yaw - data.CameraHistory[i-1].Yaw
                if yawDiff > 180 then yawDiff = yawDiff - 360
                elseif yawDiff < -180 then yawDiff = yawDiff + 360 end
                table.insert(yawChanges, yawDiff)
            end
        end
        if #yawChanges > 10 then
            local totalYaw = 0
            for _, y in ipairs(yawChanges) do totalYaw = totalYaw + y end
            --  360 
            local timeWindow = data.CameraHistory[#data.CameraHistory].Time - data.CameraHistory[1].Time
            if timeWindow > 0 then
                local rotPerSec = math.abs(totalYaw) / timeWindow
                if rotPerSec > 720 then score = score + 25; evidence = evidence + 2 end -- 2+ rotations/sec
                if rotPerSec > 360 then score = score + 15; evidence = evidence + 1 end
            end
        end
    end

    if evidence < 2 then score = math.floor(score * 0.5) end
    if evidence >= 3 then score = math.min(100, score + 10) end
    return math.min(100, score)
end

-- SECTION 9: TELEPORT DETECTOR

local function detectTeleport(uid)
    if not Flags.CD_Teleport then return 0 end
    local data = PlayerData[uid]
    if not data or #data.PositionHistory < 15 then return 0 end

    local score = 0

    local teleports = 0
    for i = 2, #data.PositionHistory do
        local dt = data.PositionHistory[i].Time - data.PositionHistory[i-1].Time
        if dt > 0.01 and dt < 1 then
            local dist = (data.PositionHistory[i].Pos - data.PositionHistory[i-1].Pos).Magnitude
            local speed = dist / dt

            -- Teleport: distance > speed * dt * 3
            if dist > 100 then -- More than 100 studs in one frame
                teleports = teleports + 1
            elseif dist > 50 and speed > 200 then
                teleports = teleports + 1
            end
        end
    end

    if teleports > 5 then score = score + 40
    elseif teleports > 3 then score = score + 25
    elseif teleports > 1 then score = score + 15
    end

    return math.min(100, score)
end

-- SECTION 10: MACRO DETECTOR

local function detectMacro(uid)
    if not Flags.CD_Macro then return 0 end
    local data = PlayerData[uid]
    if not data or #data.ShotTimestamps < 20 then return 0 end

    local score = 0

    -- Test 1: Perfect rhythm (macro has exact timing between clicks)
    local intervals = {}
    for i = 2, #data.ShotTimestamps do
        local dt = (data.ShotTimestamps[i] - data.ShotTimestamps[i-1]) * 1000
        if dt > 10 and dt < 500 then
            table.insert(intervals, dt)
        end
    end

    if #intervals > 15 then
        -- Test for exact repeating pattern
        local patternLengths = {2, 3, 4, 5}
        for _, plen in ipairs(patternLengths) do
            if #intervals >= plen * 3 then
                local matches = 0
                local total = 0
                for i = 1, #intervals - plen do
                    local diff = math.abs(intervals[i] - intervals[i + plen])
                    if diff < 1 then -- Within 1ms = same interval
                        matches = matches + 1
                    end
                    total = total + 1
                end
                if total > 0 and matches / total > 0.8 then
                    score = score + 30 + (plen * 5)
                    break
                end
            end
        end

        -- Test 2: Near-zero variance
        local mean = 0
        for _, v in ipairs(intervals) do mean = mean + v end
        mean = mean / #intervals
        local variance = 0
        for _, v in ipairs(intervals) do variance = variance + (v - mean) ^ 2 end
        variance = variance / #intervals
        local sd = math.sqrt(variance)

        -- Humans: SD > 30ms, Macros: SD < 5ms
        if sd < 2 then score = score + 30
        elseif sd < 5 then score = score + 20
        elseif sd < 10 then score = score + 10
        end
    end

    -- Test 3: Inhuman click speed
    if #intervals > 10 then
        local minInterval = math.huge
        for _, v in ipairs(intervals) do minInterval = math.min(minInterval, v) end
        if minInterval < 20 then score = score + 20 -- <20ms click = inhuman
        elseif minInterval < 40 then score = score + 10
        end
    end

    return math.min(100, score)
end

-- SECTION 11: NORECOIL DETECTOR

local function detectNoRecoil(uid)
    if not Flags.CD_NoRecoil then return 0 end
    local data = PlayerData[uid]
    if not data or #data.AimSnaps < 20 then return 0 end

    local score = 0

    -- Test 1: During sustained fire, camera doesn't move up
    local sustainedFireAngles = {}
    for i = 2, #data.AimSnaps do
        local dt = data.AimSnaps[i].Time - data.AimSnaps[i-1].Time
        if dt > 0 and dt < 0.2 then -- During rapid fire
            table.insert(sustainedFireAngles, {
                Pitch = data.AimSnaps[i].Pitch,
                Time = data.AimSnaps[i].Time,
            })
        end
    end

    if #sustainedFireAngles > 10 then
        -- Check pitch stability during fire
        local pitchDiffs = 0
        for i = 2, #sustainedFireAngles do
            pitchDiffs = pitchDiffs + math.abs(sustainedFireAngles[i].Pitch - sustainedFireAngles[i-1].Pitch)
        end
        local avgPitchDiff = pitchDiffs / (#sustainedFireAngles - 1)

        -- During firing, pitch should move up (recoil). If perfectly stable = no recoil
        if avgPitchDiff < 0.1 then score = score + 30 -- Almost zero pitch change
        elseif avgPitchDiff < 0.5 then score = score + 15
        end

        -- Test 2: Zero vertical deviation over many shots
        local verticalRange = 0
        local maxPitch = -90
        local minPitch = 90
        for _, a in ipairs(sustainedFireAngles) do
            maxPitch = math.max(maxPitch, a.Pitch)
            minPitch = math.min(minPitch, a.Pitch)
        end
        verticalRange = maxPitch - minPitch
        if verticalRange < 1 and #sustainedFireAngles > 15 then
            score = score + 20 -- Perfectly flat aim during fire
        end
    end

    return math.min(100, score)
end

-- SECTION 12: SILENT AIM DETECTOR

local function detectSilentAim(uid)
    if not Flags.CD_SilentAim then return 0 end
    local data = PlayerData[uid]
    if not data or #data.HitPositions < 10 then return 0 end

    local score = 0

    -- Test 1: Hits that don't match camera direction
    local mismatches = 0
    for _, hit in ipairs(data.HitPositions) do
        if hit.CameraDirection and hit.HitDirection then
            local dot = hit.CameraDirection:Dot(hit.HitDirection)
            -- dot < 0.9 = bullet went in a different direction than camera
            if dot < 0.8 then
                mismatches = mismatches + 1
            end
        end
    end
    if #data.HitPositions > 8 then
        local mismatchRate = mismatches / #data.HitPositions
        if mismatchRate > 0.4 then score = score + 35
        elseif mismatchRate > 0.25 then score = score + 20
        elseif mismatchRate > 0.15 then score = score + 10
        end
    end

    -- Test 2: Kills from impossible angles
    local impossibleKills = 0
    for _, kill in ipairs(data.KillTimestamps) do
        if kill.Angle and math.abs(kill.Angle) > 60 then
            impossibleKills = impossibleKills + 1
        end
    end
    if #data.KillTimestamps > 3 then
        local impossibleRate = impossibleKills / #data.KillTimestamps
        if impossibleRate > 0.3 then score = score + 25
        elseif impossibleRate > 0.15 then score = score + 10
        end
    end

    return math.min(100, score)
end

-- SECTION 13: SNAPBOT / FLICK DETECTOR

local function detectSnap(uid)
    if not Flags.CD_Snap then return 0 end
    local data = PlayerData[uid]
    if not data or #data.AimSnaps < 10 then return 0 end

    local score = 0

    local instantSnaps = 0
    local largeSnaps = 0
    for _, snap in ipairs(data.AimSnaps) do
        if snap.Duration and snap.Duration < 0.02 then -- <20ms snap
            instantSnaps = instantSnaps + 1
        end
        if snap.Angle and snap.Angle > 90 then -- 90+ degree snap
            largeSnaps = largeSnaps + 1
            if snap.Duration and snap.Duration < 0.05 then
                score = score + 8 -- Large + fast = very suspicious
            end
        end
    end

    if #data.AimSnaps > 10 then
        local instantRate = instantSnaps / #data.AimSnaps
        if instantRate > 0.4 then score = score + 25
        elseif instantRate > 0.2 then score = score + 15
        end
    end

    return math.min(100, score)
end

-- SECTION 13B: RCS DETECTOR  

local function detectRCS(uid)
    if not Flags.CD_RCS then return 0 end
    local data = PlayerData[uid]
    if not data or #data.AimSnaps < 20 then return 0 end
    local score = 0
    local evidence = 0

     -- Test 1:
    local sustainedFireAngles = {}
    for i = 2, #data.AimSnaps do
        local dt = data.AimSnaps[i].Time - data.AimSnaps[i-1].Time
        if dt > 0 and dt < 0.2 then
            table.insert(sustainedFireAngles, { Pitch = data.AimSnaps[i].Pitch, Time = data.AimSnaps[i].Time })
        end
    end
    if #sustainedFireAngles > 10 then
        local pitchDiffs = {}
        for i = 2, #sustainedFireAngles do
            table.insert(pitchDiffs, sustainedFireAngles[i].Pitch - sustainedFireAngles[i-1].Pitch)
        end
        local avgPitchDiff = calcMean(pitchDiffs)
        local sdPitchDiff = calcSD(pitchDiffs)
        -- avg > 0.5
        -- RCS avg  0
        if math.abs(avgPitchDiff) < 0.05 and #sustainedFireAngles > 15 then
            score = score + 30; evidence = evidence + 2
        elseif math.abs(avgPitchDiff) < 0.2 and sdPitchDiff < 0.5 then
            score = score + 15; evidence = evidence + 1
        end
    end

     -- Test 2: RCS
    if #sustainedFireAngles > 20 then
        local verticalRange = 0
        local maxP = -90
        local minP = 90
        for _, a in ipairs(sustainedFireAngles) do
            maxP = math.max(maxP, a.Pitch)
            minP = math.min(minP, a.Pitch)
        end
        verticalRange = maxP - minP
        if verticalRange < 1 and #sustainedFireAngles > 15 then
            score = score + 20; evidence = evidence + 1
        end
    end

    if evidence < 2 then score = math.floor(score * 0.5) end
    return math.min(100, score)
end

-- SECTION 13C: BHOP DETECTOR  

local function detectBhop(uid)
    if not Flags.CD_Bhop then return 0 end
    local data = PlayerData[uid]
    if not data or #data.PositionHistory < 30 then return 0 end
    local score = 0
    local evidence = 0

     -- Test 1:
    local verticalPositions = {}
    for _, pos in ipairs(data.PositionHistory) do
        table.insert(verticalPositions, pos.Pos.Y)
    end
    if #verticalPositions > 20 then
        -- Y 
        local yChanges = {}
        for i = 2, #verticalPositions do
            table.insert(yChanges, verticalPositions[i] - verticalPositions[i-1])
        end
        --  bhop  Y 
        if #yChanges > 15 then
            local ac1 = calcAutocorr(yChanges, 1)
            if ac1 > 0.85 then score = score + 25; evidence = evidence + 1 end
        end
        -- 
        local consecutiveUp = 0
        local maxConsecutive = 0
        for _, yc in ipairs(yChanges) do
            if yc > 0.5 then consecutiveUp = consecutiveUp + 1
            else
                maxConsecutive = math.max(maxConsecutive, consecutiveUp)
                consecutiveUp = 0
            end
        end
        maxConsecutive = math.max(maxConsecutive, consecutiveUp)
        if maxConsecutive > 8 then score = score + 20; evidence = evidence + 1 end
    end

     -- Test 2:
    if #data.VelocityHistory > 20 then
        local airSpeeds = {}
        for _, v in ipairs(data.VelocityHistory) do
            local horizSpeed = Vector3.new(v.Vel.X, 0, v.Vel.Z).Magnitude
            table.insert(airSpeeds, horizSpeed)
        end
        if #airSpeeds > 10 then
            local maxHorizSpeed = 0
            for _, s in ipairs(airSpeeds) do maxHorizSpeed = math.max(maxHorizSpeed, s) end
            if maxHorizSpeed > 50 then score = score + 15; evidence = evidence + 1 end
        end
    end

    if evidence < 2 then score = math.floor(score * 0.5) end
    return math.min(100, score)
end

-- SECTION 13D: THIRDPERSON DETECTOR  

local function detectThirdPerson(uid)
    if not Flags.CD_ThirdPerson then return 0 end
    local data = PlayerData[uid]
    if not data or #data.CameraHistory < 20 then return 0 end
    local score = 0

     -- Test 1:
    --  = 
    local suspect = Players:GetPlayerByUserId(uid)
    if suspect and suspect.Character then
        local hrp = suspect and suspect.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local cam = workspace.CurrentCamera
            if cam then
                local camDist = (cam.CFrame.Position - hrp.Position).Magnitude
                if camDist > 15 then score = score + 30 end --  ~5-8
                if camDist > 25 then score = score + 20 end
            end
        end
    end

    return math.min(100, score)
end

-- SECTION 14: COMBINED SCORING  

local function calculateTotalScore(uid)
    local data = PlayerData[uid]
    if not data then return 0 end

    data.Flags.Aimbot = detectAimbot(uid)
    data.Flags.Wallhack = detectWallhack(uid)
    data.Flags.ESP = detectESP(uid)
    data.Flags.Trigger = detectTriggerbot(uid)
    data.Flags.Spinbot = detectSpinbot(uid)
    data.Flags.Teleport = detectTeleport(uid)
    data.Flags.Macro = detectMacro(uid)
    data.Flags.NoRecoil = detectNoRecoil(uid)
    data.Flags.SilentAim = detectSilentAim(uid)
    data.Flags.Snapbot = detectSnap(uid)
    data.Flags.RCS = detectRCS(uid)
    data.Flags.Bhop = detectBhop(uid)
    data.Flags.ThirdPerson = detectThirdPerson(uid)

    -- 
    local weights = {
        Aimbot = 1.3, Wallhack = 1.5, ESP = 1.2, Trigger = 1.2,
        Spinbot = 1.4, Teleport = 1.5, Macro = 1.1, NoRecoil = 0.9,
        SilentAim = 1.4, Snapbot = 1.3, RCS = 1.0, Bhop = 1.1, ThirdPerson = 0.8,
    }

    local total = 0
    local maxPossible = 0
    local activeDetectors = 0
    for flag, fScore in pairs(data.Flags) do
        if fScore > 0 then activeDetectors = activeDetectors + 1 end
        total = total + fScore * (weights[flag] or 1.0)
        maxPossible = maxPossible + 100 * (weights[flag] or 1.0)
    end

    --   
    if activeDetectors >= 4 then total = total * 1.15
    elseif activeDetectors >= 3 then total = total * 1.10
    elseif activeDetectors >= 2 then total = total * 1.05
    end

    data.TotalScore = math.clamp(math.floor(total / maxPossible * 100), 0, 100)
    return data.TotalScore
end

-- SECTION 15: MAIN SCAN ENGINE  

function CD.fullScan()
    if not Flags.CheatDetect then return end

    local myHRP = BS.hrp()
    local myTeam = BS.team()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= lplr then
            local uid = player.UserId
            local data = getPlayerData(uid)
            data.Name = player.Name

            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local cam = char and char:FindFirstChildOfClass("Humanoid")

            if hrp and hum and hum.Health > 0 then
                -- Collect position data
                table.insert(data.PositionHistory, {
                    -- Time = tick(),
                    Pos = hrp.Position,
                })
                if #data.PositionHistory > 100 then table.remove(data.PositionHistory, 1) end

                -- Collect velocity data
                table.insert(data.VelocityHistory, {
                    -- Time = tick(),
                    Vel = hrp.AssemblyLinearVelocity,
                })
                if #data.VelocityHistory > 100 then table.remove(data.VelocityHistory, 1) end

                -- Collect camera data (check if looking at hidden enemies)
                pcall(function()
                    local theirCam = workspace.CurrentCamera
                    if theirCam then
                        local lookAt = theirCam.CFrame.LookVector
                        -- Check if looking towards any of our hidden teammates
                        local lookingAtHidden = false
                        for _, other in pairs(Players:GetPlayers()) do
                            if other ~= lplr and other ~= player then
                                local otherChar = other.Character
                                local otherHRP = otherChar and otherChar:FindFirstChild("HumanoidRootPart")
                                if otherHRP and myHRP then
                                    local toOther = (otherHRP.Position - hrp.Position).Unit
                                    local dot = lookAt:Dot(toOther)
                                    if dot > 0.9 then -- Looking almost directly at another player
                                        -- Check if this player can see the target
                                        local params = RaycastParams.new()
                                        params.FilterType = Enum.RaycastFilterType.Exclude
                                        params.FilterDescendantsInstances = {char, otherChar}
                                        local ray = workspace:Raycast(hrp.Position, otherHRP.Position - hrp.Position, params)
                                        if ray then
                                            lookingAtHidden = true -- Can't see through wall but looking = ESP
                                        end
                                    end
                                end
                            end
                        end

                        table.insert(data.CameraHistory, {
                            -- Time = tick(),
                            -- Yaw = math.deg(math.atan2(lookAt.X, lookAt.Z)),
                            -- Pitch = math.deg(math.asin(lookAt.Y)),
                            LookingAtHidden = lookingAtHidden,
                        })
                        if #data.CameraHistory > 200 then table.remove(data.CameraHistory, 1) end
                    end
                end)

                -- Collect aim snap data (track sudden camera movements)
                if #data.CameraHistory >= 2 then
                    local curr = data.CameraHistory[#data.CameraHistory]
                    local prev = data.CameraHistory[#data.CameraHistory - 1]
                    local dt = curr.Time - prev.Time
                    if dt > 0.005 and dt < 0.5 then
                        local yawDiff = math.abs(curr.Yaw - prev.Yaw)
                        if yawDiff > 180 then yawDiff = 360 - yawDiff end
                        local pitchDiff = math.abs(curr.Pitch - prev.Pitch)

                        if yawDiff > 5 or pitchDiff > 5 then -- Significant snap
                            -- Check if there was an enemy in that direction
                            local targetVisible = false
                            local params = RaycastParams.new()
                            params.FilterType = Enum.RaycastFilterType.Exclude
                            params.FilterDescendantsInstances = {char}
                            local ray = workspace:Raycast(hrp.Position, curr.LookAtDirection or lookAt * 100, params)

                            table.insert(data.AimSnaps, {
                                -- Time = tick(),
                                Angle = yawDiff,
                                Duration = dt,
                                -- TargetVisible = not ray or (ray.Distance > 50),
                                Pitch = curr.Pitch,
                            })
                            if #data.AimSnaps > 500 then table.remove(data.AimSnaps, 1) end
                        end
                    end
                end
            end
        end
    end

    -- Run detection on all tracked players
    local results = {}
    for uid, data in pairs(PlayerData) do
        if tick() - data.LastScan > 3 then -- Don't scan too often
            local totalScore = calculateTotalScore(uid)
            data.TotalScore = totalScore
            data.LastScan = tick()
            data.ScanCount = data.ScanCount + 1

            if totalScore >= (Flags.CD_MinConfidence or 60) then
                table.insert(results, {
                    UserId = uid,
                    Name = data.Name,
                    Score = totalScore,
                    Flags = data.Flags,
                })
            end
        end
    end

    -- Sort by score (highest first)
    table.sort(results, function(a, b) return a.Score > b.Score end)

     -- Multi-Tier Alert System
    if Flags.CD_Alerts and #results > 0 then
        local alertThreshold = Flags.CD_AlertThreshold or 50
        local warnThreshold = Flags.CD_WarnThreshold or 70
        local criticalThreshold = Flags.CD_CriticalThreshold or 85

        local alertNames = {}
        local warnNames = {}
        local criticalNames = {}

        for _, result in ipairs(results) do
            local mainCheat = CD.getMainCheat(result.Flags)
            local details = CD.getFlagSummary(result.Flags)

            if result.Score >= criticalThreshold then
                -- [CRITICAL] Almost certainly cheating
                table.insert(criticalNames, result.Name)
                CD.sendAlert(
                    "[CONFIRMED CHEATER]",
                    string.format("%s [%.0f%% confidence]\nType: %s\nEvidence: %s",
                        result.Name, result.Score, mainCheat, details),
                    Color3.fromRGB(255, 0, 0), 12
                )
                CD.playAlertSound("critical")
                logDecision("CHEATER CONFIRMED: " .. result.Name, mainCheat .. " (" .. result.Score .. "%)")

            elseif result.Score >= warnThreshold then
                -- [WARN] Highly suspicious
                table.insert(warnNames, result.Name)
                CD.sendAlert(
                    "[CONFIRMED CHEATER]",
                    string.format("%s [%.0f%% confidence]\nType: %s\nEvidence: %s",
                        result.Name, result.Score, mainCheat, details),
                    Color3.fromRGB(255, 200, 0), 8
                )
                CD.playAlertSound("warn")
                logDecision("SUSPECT: " .. result.Name, mainCheat .. " (" .. result.Score .. "%)")

            elseif result.Score >= alertThreshold then
                --  ALERT  Somewhat suspicious
                table.insert(alertNames, result.Name)
                logDecision("SUSPICIOUS: " .. result.Name, mainCheat .. " (" .. result.Score .. "%)")
            end
        end

        -- Lobby Summary
        if #results > 0 and Flags.CD_LobbySummary then
            local summary = string.format(" : %d \n", #results)
            if #criticalNames > 0 then
                summary = summary .. " : " .. table.concat(criticalNames, ", ") .. "\n"
            end
            if #warnNames > 0 then
                summary = summary .. " : " .. table.concat(warnNames, ", ") .. "\n"
            end
            if #alertNames > 0 then
                summary = summary .. " : " .. table.concat(alertNames, ", ")
            end

            CD.sendAlert(" ", summary, Color3.fromRGB(100, 200, 255), 10)
        end

        -- Update persistent banner
        if Flags.CD_Banner then
            CD.updateBanner(#criticalNames, #warnNames, #alertNames, criticalNames, warnNames)
        end
    end

    return results
end

-- SECTION 16: ALERT HELPERS  

local alertCooldowns = {} -- prevent spam

function CD.getMainCheat(flags)
    local cheats = {
        Aimbot = "Aimbot ",
        Wallhack = " Wallhack ",
        ESP = "ESP  ",
        Trigger = " Triggerbot ",
        Spinbot = " Spinbot ",
        Teleport = " Teleport ",
        Macro = " Macro ",
        NoRecoil = " NoRecoil ",
        SilentAim = " SilentAim ",
        Snapbot = " Snapbot ",
        RCS = " RCS ",
        Bhop = " Bhop ",
        ThirdPerson = " 3rdPerson ",
    }
    local bestCheat = ""
    local maxScore = 0
    for flag, score in pairs(flags) do
        if score > maxScore then
            maxScore = score
            bestCheat = cheats[flag] or flag
        end
    end
    return bestCheat .. " (" .. math.floor(maxScore) .. "%)"
end

-- Anti-spam: don't alert same player too often
function CD.canAlert(uid, level)
    local key = uid .. "_" .. level
    local last = alertCooldowns[key] or 0
    local cooldown = level == "critical" and 30 or level == "warn" and 60 or 120
    if tick() - last < cooldown then return false end
    alertCooldowns[key] = tick()
    return true
end

-- Send notification with anti-spam
function CD.sendAlert(title, text, color, duration)
    pcall(function()
         StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5,
        })
    end)
end

-- Play alert sound
function CD.playAlertSound(level)
    if not Flags.CD_SoundAlert then return end
    pcall(function()
        local sound = Instance.new("Sound")
        if level == "critical" then
            sound.SoundId = "rbxassetid://5587286548" -- loud alert
            sound.Volume = 1.0
        elseif level == "warn" then
            sound.SoundId = "rbxassetid://5587286548" -- medium alert
            sound.Volume = 0.7
        else
            sound.SoundId = "rbxassetid://5587286548" -- soft alert
            sound.Volume = 0.4
        end
        sound.PlayOnRemove = false
        sound.Parent = lplr.Character and lplr and lplr.Character:FindFirstChild("HumanoidRootPart") or workspace
        sound:Play()
        game:GetService("Debris"):AddItem(sound, 2)
    end)
end

 -- Persistent Banner
local bannerGui = nil
function CD.updateBanner(criticalCount, warnCount, alertCount, criticalNames, warnNames)
    pcall(function()
        local totalCheaters = criticalCount + warnCount
        if totalCheaters == 0 then
            if bannerGui then bannerGui.Enabled = false end
            -- return
        end

        if not bannerGui then
            bannerGui = Instance.new("ScreenGui")
            bannerGui.Name = "BS_CheatBanner"
            bannerGui.IgnoreGuiInset = true
            bannerGui.DisplayOrder = 9998
            bannerGui.Parent = lplr.PlayerGui

            local frame = Instance.new("Frame", bannerGui)
            frame.Name = "Banner"
            frame.Size = UDim2.new(1, 0, 0, 0)
            frame.Position = UDim2.new(0, 0, 0, 25)
            frame.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
            frame.BackgroundTransparency = 0.1
            frame.BorderSizePixel = 0
            frame.AutomaticSize = Enum.AutomaticSize.Y

            local layout = Instance.new("UIListLayout", frame)
            layout.Padding = UDim.new(0, 2)
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

            local title = Instance.new("TextLabel", frame)
            title.Name = "Title"
            title.Size = UDim2.new(1, 0, 0, 18)
            title.BackgroundTransparency = 1
            title.TextColor3 = Color3.fromRGB(255, 50, 50)
            title.TextSize = 14
            title.Font = Enum.Font.Code
            title.Text = ""

            local detail = Instance.new("TextLabel", frame)
            detail.Name = "Detail"
            detail.Size = UDim2.new(1, 0, 0, 14)
            detail.BackgroundTransparency = 1
            detail.TextColor3 = Color3.fromRGB(255, 200, 100)
            detail.TextSize = 11
            detail.Font = Enum.Font.Code
            detail.Text = ""
            detail.TextWrapped = true
        end

        bannerGui.Enabled = true
        local frame = bannerGui.Banner
        local titleText = string.format(" : %d  (%d , %d )",
            totalCheaters, criticalCount, warnCount)
        frame.Title.Text = titleText

        local detailText = ""
        if #criticalNames > 0 then
            detailText = detailText .. " : " .. table.concat(criticalNames, ", ") .. " | "
        end
        if #warnNames > 0 then
            detailText = detailText .. " : " .. table.concat(warnNames, ", ")
        end
        frame.Detail.Text = detailText
    end)
end

 -- Match Start Scan
local matchScanned = false
lplr.CharacterAdded:Connect(function()
    if Flags.CD_MatchStart and Flags.CheatDetect then
        matchScanned = false
        task.delay(3, function()
            if not matchScanned then
                matchScanned = true
                pcall(function()
                    CD.sendAlert(" ", "...", Color3.fromRGB(100, 200, 255), 3)
                end)
                task.delay(2, function()
                    pcall(function() CD.fullScan() end)
                end)
            end
        end)
    end
end)

 -- Player Join Alert
pcall(function()
    Players.PlayerAdded:Connect(function(player)
        if Flags.CheatDetect and Flags.CD_Alerts then
            task.delay(5, function()
                pcall(function()
                    if isfile and isfile("BloxStrike/CheatLog.json") then
                        local log = HttpService:JSONDecode(readfile("BloxStrike/CheatLog.json"))
                        if log and log[tostring(player.UserId)] then
                            local prevScore = log[tostring(player.UserId)].Score or 0
                            if prevScore > 50 then
                                CD.sendAlert(
                                    string.format("%s (%.0f%%)", player.Name, prevScore),
                                    Color3.fromRGB(255, 150, 0), 8
                                )
                            end
                        end
                    end
                end)
            end)
        end
    end)
end)

 -- Persist Cheat Log
task.spawn(function()
    while true do task.wait(30)
        pcall(function()
            local log = {}
            for uid, data in pairs(PlayerData) do
                if data.TotalScore > 30 then
                    log[tostring(uid)] = {
                        Name = data.Name,
                        Score = data.TotalScore,
                        Flags = data.Flags,
                        LastSeen = tick(),
                    }
                end
            end
            writefile("BloxStrike/CheatLog.json", HttpService:JSONEncode(log))
        end)
    end
end)

-- SECTION 17: REPORT & DISPLAY

function CD.getFlagSummary(flags)
    local active = {}
    for flag, score in pairs(flags) do
        if score > 30 then
            table.insert(active, flag .. "=" .. math.floor(score))
        end
    end
    return #active > 0 and table.concat(active, ", ") or "None"
end

function CD.showReport()
    local report = " :\n\n"
    local found = false

    -- Sort players by score
    local sorted = {}
    for uid, data in pairs(PlayerData) do
        if data.TotalScore > 0 then
            table.insert(sorted, data)
        end
    end
    table.sort(sorted, function(a, b) return a.TotalScore > b.TotalScore end)

    for i, data in ipairs(sorted) do
        if i > 10 then break end
        local status = data.TotalScore >= 70 and "" or data.TotalScore >= 40 and "" or ""
        report = report .. string.format("%s %s: %.0f%% [%s]\n",
            status, data.Name, data.TotalScore, CD.getFlagSummary(data.Flags))
        found = true
    end

    if not found then
        report = report .. " "
    end

    pcall(function()
         StarterGui:SetCore("SendNotification", {
            Title = " ",
            Text = report,
            Duration = 10,
        })
    end)
end

function CD.clearAll()
    PlayerData = {}
    pcall(function()
         StarterGui:SetCore("SendNotification", {
            Title = " ",
            Text = "",
            Duration = 3,
        })
    end)
end

-- SECTION 18: SUSPECT ESP MARKER  

local suspectMarkers = {}

local function updateSuspectMarkers()
    if not Flags.CD_SuspectMarker then
        -- Hide all markers
        for uid, marker in pairs(suspectMarkers) do
            pcall(function() marker.Visible = false end)
        end
        -- return
    end

    local cam = workspace.CurrentCamera
    if not cam then return end

    for uid, data in pairs(PlayerData) do
        if data.TotalScore > 30 then
            local player = Players:GetPlayerByUserId(uid)
            if player and player.Character then
                local hrp = player and player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local pos, vis = cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
                    if vis then
                        if not suspectMarkers[uid] then
                            pcall(function()
                                suspectMarkers[uid] = Drawing.new("Text")
                                suspectMarkers[uid].Center = true
                                suspectMarkers[uid].Outline = true
                                suspectMarkers[uid].OutlineColor = Color3.new(0, 0, 0)
                                suspectMarkers[uid].Font = Drawing.Fonts.UI
                                suspectMarkers[uid].Size = 14
                            end)
                        end
                        local marker = suspectMarkers[uid]
                        local emoji = data.TotalScore >= 85 and "" or data.TotalScore >= 70 and "" or ""
                        marker.Text = string.format("%s %s [%.0f%%]", emoji, data.Name, data.TotalScore)
                        marker.Position = Vector2.new(pos.X, pos.Y)
                        marker.Color = data.TotalScore >= 85 and Color3.fromRGB(255, 0, 0)
                            or data.TotalScore >= 70 and Color3.fromRGB(255, 200, 0)
                            or Color3.fromRGB(255, 255, 100)
                        marker.Visible = true
                    else
                        if suspectMarkers[uid] then suspectMarkers[uid].Visible = false end
                    end
                end
            end
        else
            if suspectMarkers[uid] then suspectMarkers[uid].Visible = false end
        end
    end
end

-- SECTION 19: LIVE HUD  

local cdHUD = nil
task.spawn(function()
    while true do task.wait(0.5)
        if Flags.CheatDetect and BS.alive() then
            -- Find highest scoring suspect
            local worst = nil
            local worstScore = 0
            for uid, data in pairs(PlayerData) do
                if data.TotalScore > worstScore then
                    worstScore = data.TotalScore
                    worst = data
                end
            end

            if not cdHUD then
                pcall(function()
                    cdHUD = Drawing.new("Text")
                    cdHUD.Center = false
                    cdHUD.Outline = true
                    cdHUD.OutlineColor = Color3.new(0, 0, 0)
                    cdHUD.Font = Drawing.Fonts.UI
                    cdHUD.Size = 12
                end)
            end

            if worst and worstScore > 20 then
                local color = worstScore >= 70 and Color3.fromRGB(255, 0, 0)
                    or worstScore >= 40 and Color3.fromRGB(255, 200, 0)
                    or Color3.fromRGB(200, 200, 200)
                cdHUD.Text = string.format(" Top Suspect: %s [%.0f%%] %s",
                    worst.Name, worstScore, CD.getFlagSummary(worst.Flags))
                cdHUD.Color = color
                cdHUD.Position = Vector2.new(10, 490)
                cdHUD.Visible = true
            else
                cdHUD.Text = " Cheat Detect:  No threats detected"
                cdHUD.Color = Color3.fromRGB(0, 200, 0)
                cdHUD.Position = Vector2.new(10, 490)
                cdHUD.Visible = true
            end
        else
            if cdHUD then cdHUD.Visible = false end
        end
    end
end)

 -- Suspect Marker Update Loop
task.spawn(function()
    while true do task.wait(0.2)
        if Flags.CheatDetect and BS.alive() then
            pcall(function() updateSuspectMarkers() end)
        end
    end
end)

-- MAIN SCAN LOOP  

task.spawn(function()
    while true do task.wait(Flags.CD_ScanInterval or 3)
        if Flags.CheatDetect and Flags.CD_AutoScan then
            pcall(function() CD.fullScan() end)


end)

-- Cleanup on player leaving
-- Players.PlayerRemoving:Connect(function(player)
    PlayerData[player.UserId] = nil
end)

 -- Expose
BS.CheatDetect = CD
BS.PlayerData = PlayerData

print("[CheatDetect] BloxStrike Cheat Detect v1.0 loaded")
print("[CheatDetect] Features: Aimbot Detector, Wallhack Detector,")
print("[CheatDetect]   ESP Detector, Speedhack Detector, Triggerbot Detector,")
print("[CheatDetect]   Spinbot Detector, Teleport Detector, Macro Detector,")
print("[CheatDetect]   NoRecoil Detector, SilentAim Detector, Snapbot Detector"
print("[CheatDetect] Auto-scan interval: " .. (Flags.CD_ScanInterval or 3) .. "s"
