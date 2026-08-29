
-- -- BLOXSTRIKE PING ADAPT MODULE v1.0
-- Ping  

local Players = nil

pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local Stats = nil
pcall(function() Stats = game:GetService("Stats") end)
local StarterGui = nil
pcall(function() StarterGui = game:GetService("StarterGui") end)
local lplr = Players.LocalPlayer

if not BS.Win then warn("[Ping Adapt] BS.Win not available - ui.lua may have failed") return end
local page = BS.Win:Tab("暴力")
if not page or not page.Toggle then warn("[PingAdapt] Failed to create tab!") return end

local PA = {}
BS.PingAdapt = PA

-- -- SECTION 1: PING MONITOR 
-- page:Label(" Ping  ")
page:Toggle("延遲適應", true, function(v) Flags.PingAdapt = v end)
page:Dropdown({Name="適應模式", Flag="PingAdaptMode", Options={"保守","平衡","進攻","極致"}, Default="Balanced"})
page:Toggle("顯示延遲統計", false, function(v) Flags.PingShowStats = v end)
page:Toggle("延遲自動恐慌", true, function(v) Flags.PingPanic = v end)
page:Slider("恐慌延遲值", 200, 500, 350, function(v) Flags.PingPanicThreshold = v end)

-- Ping State
local PingState = {
    Current = 0,
    Average = 0,
    Min = 9999,
    Max = 0,
    Jitter = 0,
    History = {},
    JitterHistory = {},
    Quality = "Good",       -- Good / Fair / Poor / Terrible
    -- QualityScore = 100,     -- 0-100 (100=perfect)
    Tier = "Low",           -- Low / Medium / High / Extreme
    PacketLoss = 0,
    LastSpike = 0,
    SpikeCount = 0,
    AdaptMultiplier = 1.0,  -- Global multiplier for all features
}

-- Ping Tier Classification
    local function classifyPing(ping)
    if ping < 30 then return "Low", "Good", 100
    elseif ping < 60 then return "Low", "Good", 90
    elseif ping < 100 then return "Medium", "Fair", 75
    elseif ping < 150 then return "Medium", "Fair", 60
    elseif ping < 200 then return "High", "Poor", 40
    elseif ping < 350 then return "High", "Poor", 20
    else return "Extreme", "Terrible", 5 end
end

-- Real-time Ping Tracker
task.spawn(function()
    while true do task.wait(0.2)
        pcall(function()
            local stats = nil
            pcall(function() stats = game:GetService("Stats") end)
            local pingVal = 0
            pcall(function() pingVal = stats.Network.ServerStatsItem["Data Ping"].Value end)

            -- PingState.Current = math.floor(pingVal)

            -- History (last 60 readings)
            table.insert(PingState.History, pingVal)
            if #PingState.History > 60 then table.remove(PingState.History, 1) end

            -- Min/Max
            -- PingState.Min = math.min(PingState.Min, pingVal)
            -- PingState.Max = math.max(PingState.Max, pingVal)

            -- Average
            local sum = 0
            for _, v in ipairs(PingState.History) do sum = sum + v end
            -- PingState.Average = math.floor(sum / #PingState.History)

            -- Jitter (variance between consecutive readings)
            if #PingState.History >= 2 then
                local last = PingState.History[#PingState.History]
                local prev = PingState.History[#PingState.History - 1]
                local j = math.abs(last - prev)
                table.insert(PingState.JitterHistory, j)
                if #PingState.JitterHistory > 30 then table.remove(PingState.JitterHistory, 1) end
                local jSum = 0
                for _, v in ipairs(PingState.JitterHistory) do jSum = jSum + v end
                -- PingState.Jitter = math.floor(jSum / #PingState.JitterHistory)
            end

            -- Spike detection
            if pingVal > PingState.Average * 2 and pingVal > 100 then
                -- PingState.LastSpike = tick()
                PingState.SpikeCount = PingState.SpikeCount + 1
            end

            -- Classification
            -- PingState.Tier, PingState.Quality, PingState.QualityScore = classifyPing(PingState.Average)

            -- Adapt multiplier: higher ping = lower multiplier = more conservative
            local mode = Flags.PingAdaptMode or "Balanced"
            local baseMult = 1.0
            if mode == "Conservative" then
                baseMult = math.clamp(1 - (PingState.Average - 30) / 300, 0.3, 1.0)
            elseif mode == "Balanced" then
                baseMult = math.clamp(1 - (PingState.Average - 30) / 200, 0.2, 1.0)
            elseif mode == "Aggressive" then
                baseMult = math.clamp(1 - (PingState.Average - 30) / 400, 0.4, 1.0)
            else -- Ultra
                baseMult = math.clamp(1 - (PingState.Average - 30) / 500, 0.5, 1.0)
            end

            -- Jitter penalty
            if PingState.Jitter > 20 then
                baseMult = baseMult * math.clamp(1 - PingState.Jitter / 200, 0.5, 1.0)
            end

            -- Spike penalty (recent spike = be more conservative for 2 seconds)
            if tick() - PingState.LastSpike < 2 then
                baseMult = baseMult * 0.6
            end

            -- PingState.AdaptMultiplier = math.clamp(baseMult, 0.1, 1.0)

            -- Auto panic on extreme lag
            if Flags.PingPanic and PingState.Current > (Flags.PingPanicThreshold or 350) then
                -- Temporarily disable dangerous features
                Flags.Ragebot = false
                Flags.AA = false
                Flags.NoClip = false
                Flags.SpeedBoost = false
                Flags.FL = false
            end
        end)
    end
end)

-- -- SECTION 2: PING-ADAPTED API 

--- ping (ping= ping=
---@param baseSmooth number ---@return number adaptedSmooth
function PA.getAdaptSmooth(baseSmooth)
    if not Flags.PingAdapt then return baseSmooth end
    local m = PingState.AdaptMultiplier
    -- ?ping     -- TODO
    return math.clamp(baseSmooth / m, 1, 100)
end

--- ping  FOV
---@param baseFOV number
---@return number adaptedFOV
function PA.getAdaptFOV(baseFOV)
    if not Flags.PingAdapt then return baseFOV end
    local m = PingState.AdaptMultiplier
    -- ?ping  FOV    -- TODO
    return math.clamp(baseFOV / m, 10, 360)
end

--- ping 
---@param basePred number
---@return number adaptedPred
function PA.getAdaptPrediction(basePred)
    if not Flags.PingAdapt then return basePred end
    -- TODO
    return math.clamp(basePred + pingBonus * 50, 0, 100)
end

--- ping ms?---@param baseDelay number  ms
---@return number adaptedDelay
function PA.getAdaptDelay(baseDelay)
    if not Flags.PingAdapt then return baseDelay end
    local m = PingState.AdaptMultiplier
    -- TODO
    return math.clamp(baseDelay / m, 1, 2000)
end

--- ping 
---@param baseMin number
---@param baseMax number
---@return number delay
function PA.getAdaptTriggerDelay(baseMin, baseMax)
    if not Flags.PingAdapt then return baseMin + math.random() * (baseMax - baseMin) end
    local m = PingState.AdaptMultiplier
    -- TODO
    local pingAdd = PingState.Current * 0.1
    local minD = baseMin / m + pingAdd * 0.5
    local maxD = baseMax / m + pingAdd
    return math.clamp(minD + math.random() * (maxD - minD), 1, 2000)
end

--- ping ---@param baseInterval number 
---@return number adaptedInterval
function PA.getAdaptUpdateRate(baseInterval)
    if not Flags.PingAdapt then return baseInterval end
    local m = PingState.AdaptMultiplier
    -- TODO
end

--- ping 
---@param baseDelay number
---@return number adaptedDelay
function PA.getAdaptSwitchDelay(baseDelay)
    if not Flags.PingAdapt then return baseDelay end
    local m = PingState.AdaptMultiplier
    -- TODO
    return math.clamp(baseDelay / m, 10, 2000)
end

--- ping  lag compensation tick ---@return number lagTicks
function PA.getAdaptLagTicks()
    if not Flags.PingAdapt then return 8 end
    -- ping  lag compensation
    return math.clamp(math.floor(PingState.Current / 16), 1, 32)
end

--- ping 
---@param baseSpeed number
---@return number adaptedSpeed
function PA.getAdaptSpeed(baseSpeed)
    if not Flags.PingAdapt then return baseSpeed end
    local m = PingState.AdaptMultiplier
    -- TODO
    return baseSpeed * math.clamp(m + 0.2, 0.5, 1.2)
end

--- ping 
---@param baseJump number
---@return number adaptedJump
function PA.getAdaptJump(baseJump)
    if not Flags.PingAdapt then return baseJump end
    local m = PingState.AdaptMultiplier
    return baseJump * math.clamp(m + 0.3, 0.6, 1.1)
end

--- ping  resolver 
---@param baseAccuracy number
---@return number adaptedAccuracy
function PA.getAdaptResolverAccuracy(baseAccuracy)
    if not Flags.PingAdapt then return baseAccuracy end
    -- TODO
    return math.clamp(baseAccuracy * m, 20, 100)
end

--- ping  ESP ---@return number skipFrames
function PA.getAdaptESPSkip()
    if not Flags.PingAdapt then return 1 end
    local ping = PingState.Current
    if ping < 50 then return 1       -- 
    elseif ping < 100 then return 2  -- 
    elseif ping < 200 then return 3  -- 
    else return 4 end                -- 
end

--- ping  triggerbot  burst ---@param baseCount number
---@return number adaptedCount
function PA.getAdaptBurstCount(baseCount)
    if not Flags.PingAdapt then return baseCount end
    local m = PingState.AdaptMultiplier
    -- TODO
    return math.clamp(math.floor(baseCount * m), 1, 10)
end

--- ping  fake lag chock
---@param baseChoke number
---@return number adaptedChoke
function PA.getAdaptFakeLag(baseChoke)
    if not Flags.PingAdapt then return baseChoke end
    local ping = PingState.Current
    -- TODO
    if ping > 150 then return math.max(1, baseChoke - 3) end
    if ping > 100 then return math.max(2, baseChoke - 1) end
    return baseChoke
end

--- ping  anti-aim jitter
---@param baseJitter number
---@return number adaptedJitter
function PA.getAdaptAAJitter(baseJitter)
    if not Flags.PingAdapt then return baseJitter end
    local m = PingState.AdaptMultiplier
    -- TODO
end

--- ping  bhop 
---@param baseInterval number
---@return number adaptedInterval
function PA.getAdaptBhopInterval(baseInterval)
    if not Flags.PingAdapt then return baseInterval end
    local ping = PingState.Current
    -- TODO
end

--- ping  silent aim ?
---@param baseRange number
---@return number adaptedRange
function PA.getAdaptSilentRange(baseRange)
    if not Flags.PingAdapt then return baseRange end
    local m = PingState.AdaptMultiplier
    -- TODO
end

--- ping  triggerbot chance
---@param baseChance number 0-100
---@return number adaptedChance
function PA.getAdaptTriggerChance(baseChance)
    if not Flags.PingAdapt then return baseChance end
    local m = PingState.AdaptMultiplier
    -- TODO
    return math.clamp(baseChance * m, 10, 100)
end

--- ping 
---@return number delay
function PA.getAdaptAutoFireDelay()
    if not Flags.PingAdapt then return 0 end
    local ping = PingState.Current
    return math.max(0, ping / 1000 * 0.3)
end

--- lag spike 
---@return boolean shouldPause
function PA.shouldPause()
    if not Flags.PingAdapt then return false end
    -- spike  100ms
    if tick() - PingState.LastSpike < 0.1 then return true end
    -- TODO
    return false
end

--- ping ---@param baseDelay number
---@return number adaptedDelay
function PA.getAdaptHumanDelay(baseDelay)
    if not Flags.PingAdapt then return baseDelay end
    local m = PingState.AdaptMultiplier
    -- TODO
end

-- -- SECTION 3: PING-ADAPTED AIMBOT  ping 
-- page:Label("  Ping  ")
page:Toggle("自瞄延遲適應", true, function(v) Flags.AimPingAdapt = v end)
page:Toggle("自動延遲補償", true, function(v) Flags.LagCompAuto = v end)
page:Toggle("自動預測", true, function(v) Flags.PredAuto = v end)
page:Toggle("自動平滑", true, function(v) Flags.SmoothAuto = v end)
page:Toggle("自動視野", true, function(v) Flags.FOVAuto = v end)

-- -- SECTION 4: PING-ADAPTED TRIGGERBOT  ping 
-- page:Label("  Ping  ")
page:Toggle("觸發器延遲適應", true, function(v) Flags.TBPingAdapt = v end)

-- -- SECTION 5: PING-ADAPTED ESP ESP ping 
-- page:Label(" ESP Ping  ")
page:Toggle("透視延遲適應", true, function(v) Flags.ESPPingAdapt = v end)
page:Toggle("透視品質縮放", true, function(v) Flags.ESPQualityScale = v end)

-- -- SECTION 6: PING-ADAPTED MOVEMENT  ping 
-- page:Label(" ? Ping  ")
page:Toggle("移動延遲適應", true, function(v) Flags.MovePingAdapt = v end)
page:Toggle("連跳延遲適應", true, function(v) Flags.BhopPingAdapt = v end)

-- -- SECTION 7: PING-ADAPTED HVH HVH ping 
-- page:Label(" HVH Ping  ")
page:Toggle("反瞄延遲適應", true, function(v) Flags.AAPingAdapt = v end)
page:Toggle("自動假延遲", true, function(v) Flags.FLPingAdapt = v end)
page:Toggle("解析自動", true, function(v) Flags.ResolverPingAdapt = v end)

-- -- SECTION 8: PING STATISTICS DISPLAY
-- page:Label(" Ping ? ")
page:Button({Name=" Ping ?", Color=Color3.fromRGB(0, 200, 255)}, function()
    local statsText = string.format(
        -- " Ping ?:\n" ..
        -- ": %dms | ?: %dms\n" ..
        -- " %dms |  %dms\n" ..
        -- "Jitter: %dms | ?: %s\n" ..
        -- "?: %s | : %.2f\n" ..
        -- "Spike : %d",
        PingState.Current, PingState.Average,
        PingState.Min, PingState.Max,
        PingState.Jitter, PingState.Quality,
        PingState.Tier, PingState.AdaptMultiplier,
        PingState.SpikeCount
    )
    pcall(function()
         StarterGui:SetCore("SendNotification", {
            Title = " Ping ?",
            Text = statsText,
            Duration = 8,
        })
    end)
end)

page:Button({Name="[Feature]", Color=Color3.fromRGB(200, 100, 100)}, function()
    PingState.Min = 9999
    PingState.Max = 0
    PingState.SpikeCount = 0
    PingState.History = {}
    PingState.JitterHistory = {}
end)

-- -- SECTION 9: GLOBAL INTEGRATION -- 
-- Auto-apply ping adaptation to combat features
task.spawn(function()
    while true do task.wait(0.1)
        if not Flags.PingAdapt then continue end
        if PA.shouldPause() then continue end

        pcall(function()
            -- Auto-adjust lag compensation based on ping
            if Flags.LagCompAuto and Flags.Aimbot then
                Flags.AimLagComp = PingState.Current > 80
                Flags.AimLagTicks = PA.getAdaptLagTicks()
            end

            -- Auto-adjust prediction based on ping
            if Flags.PredAuto and Flags.Aimbot then
                local basePred = Flags.AimPredF or 40
                Flags.AimPredF = math.floor(PA.getAdaptPrediction(basePred))
            end

            -- Auto-adjust smooth based on ping
            if Flags.SmoothAuto and Flags.Aimbot then
                local baseSmooth = 5
                Flags.AimbotSmooth = math.floor(PA.getAdaptSmooth(baseSmooth))
            end

            -- Auto-adjust FOV based on ping
            if Flags.FOVAuto and Flags.Aimbot then
                local baseFOV = 60
                Flags.AimbotFOV = math.floor(PA.getAdaptFOV(baseFOV))
            end
        end)

        -- ::continue::
    end
end)

-- Auto-apply ping adaptation to triggerbot
task.spawn(function()
    while true do task.wait(0.2)
        if not Flags.PingAdapt or not Flags.TBPingAdapt then continue end
        pcall(function()
            -- Adjust triggerbot delays based on ping
            if Flags.TriggerBot then
                local baseMin = 30
                local baseMax = 120
                local adapted = PA.getAdaptTriggerDelay(baseMin, baseMax)
                -- Store adapted values (triggerbot reads these)
                Flags._AdaptTBMinDelay = adapted * 0.5
                Flags._AdaptTBMaxDelay = adapted
            end
        end)
        -- ::continue::
    end
end)

-- Auto-apply ping adaptation to ESP
task.spawn(function()
    while true do task.wait(0.5)
        if not Flags.PingAdapt or not Flags.ESPPingAdapt then continue end
        pcall(function()
            -- Adjust ESP skip frames based on ping
            Flags._ESPSkipFrames = PA.getAdaptESPSkip()

            -- Scale ESP quality on high ping
            if Flags.ESPQualityScale then
                local quality = PingState.QualityScore
                if quality < 40 then
                    -- Reduce ESP complexity on poor ping
                    Flags.ESP_Skeleton = false
                    Flags.ESP_Snaplines = false
                    Flags.ESP_SoundEsp = false
                    Flags.ESP_Velocity = false
                elseif quality < 60 then
                    -- Reduce some ESP features
                    Flags.ESP_SoundEsp = false
                end
            end
        end)
        -- ::continue::
    end
end)

-- Auto-apply ping adaptation to movement
task.spawn(function()
    while true do task.wait(0.2)
        if not Flags.PingAdapt or not Flags.MovePingAdapt then continue end
        pcall(function()
            -- Adjust speed based on ping
            if Flags.SpeedBoost and BS.alive() then
                local h = BS.hum()
                if h then
                    local targetSpeed = 22 -- base boosted speed
                    local adaptedSpeed = PA.getAdaptSpeed(targetSpeed)
                    -- Don't directly set here, just provide the adapted value
                    Flags._AdaptSpeed = adaptedSpeed
                end
            end

            -- Adjust bhop interval based on ping
            if Flags.Bhop and Flags.BhopPingAdapt then
                local baseInterval = 0.1
                Flags._AdaptBhopInterval = PA.getAdaptBhopInterval(baseInterval)
            end
        end)
        -- ::continue::
    end
end)

-- Auto-apply ping adaptation to HVH
task.spawn(function()
    while true do task.wait(0.3)
        if not Flags.PingAdapt then continue end
        pcall(function()
            -- Anti-aim jitter adaptation
            if Flags.AA and Flags.AAPingAdapt then
                local baseJitter = 20
                Flags._AdaptAAJitter = PA.getAdaptAAJitter(baseJitter)
            end

            -- Fake lag adaptation
            if Flags.FL and Flags.FLPingAdapt then
                local baseChoke = 6
                Flags._AdaptFakeLag = PA.getAdaptFakeLag(baseChoke)
            end

            -- Silent aim adaptation
            if Flags.SilentAim then
                local baseFOV = 90
                Flags._AdaptSAFOV = PA.getAdaptSilentRange(baseFOV)
            end
        end)
        -- ::continue::
    end
end)

-- Ping Display HUD
    local pingHUD = nil
task.spawn(function()
    while true do task.wait(0.1)
        if Flags.PingShowStats then
            if not pingHUD then
                pcall(function()
                    local _Compat = _G.BS and _G.BS.Compat; if _Compat and _Compat.DrawingNew then pingHUD = _Compat.DrawingNew("Text") else pcall(function() pingHUD = Drawing.new("Text") end) end
                    pingHUD.Center = false
                    pingHUD.Outline = true
                    pingHUD.OutlineColor = Color3.new(0, 0, 0)
                    pingHUD.Font = Drawing.Fonts.UI
                    pingHUD.Size = 13
                end)
            end
            local ping = PingState.Current
            local color = ping < 50 and Color3.fromRGB(0, 255, 0)
                or ping < 100 and Color3.fromRGB(255, 255, 0)
                or ping < 200 and Color3.fromRGB(255, 150, 0)
                or Color3.fromRGB(255, 50, 50)
            pingHUD.Text = string.format("PING: %dms [%s] x%.2f | Jitter: %d",
                ping, PingState.Quality, PingState.AdaptMultiplier, PingState.Jitter)
            pingHUD.Color = color
            pingHUD.Position = Vector2.new(10, 520)
            pingHUD.Visible = true
        else
            if pingHUD then pingHUD.Visible = false end
        end
    end
end)

-- Expose BS.PingState = PingState
BS.PA = PA

print("[PingAdapt] BloxStrike Ping Adapt v1.0 loaded")
-- [optimized] print("[PingAdapt] Features: Real-time Ping Monitor,")
-- [optimized] print("[PingAdapt]   Aimbot Adapt (Smooth/FOV/Predict/LagComp),")
-- [optimized] print("[PingAdapt]   Triggerbot Adapt (Delay/Chance/Burst),")
-- [optimized] print("[PingAdapt]   ESP Adapt (SkipFrames/Quality),")
-- [optimized] print("[PingAdapt]   Movement Adapt (Speed/Bhop),")
-- [optimized] print("[PingAdapt]   HVH Adapt (AA/FakeLag/Resolver/SilentAim),")
-- [optimized] print("[PingAdapt]   Auto Panic on Extreme Lag")
-- [optimized] print("[PingAdapt] Ping: " .. PingState.Current .. "ms [" .. PingState.Quality .. "]")
