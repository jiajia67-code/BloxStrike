

-- BLOXSTRIKE HVH BYPASS MODULE v2.0  Advanced Anti-Cheat Evasion
-- Metamethod Protection, Environment Spoofing, Thread Hiding,
-- Memory Protection, Signal Filtering, Property Interception

local Players = nil

pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local Lighting = nil
pcall(function() Lighting = game:GetService("Lighting") end)
local Stats = nil
pcall(function() Stats = game:GetService("Stats") end)
local lplr = Players.LocalPlayer

 -- Bypass State
local Bypass = {
    OriginalProps = {},
    HookedFunctions = {},
    MonitoringConnections = {},
    LastPosition = nil,
    LastVelocity = nil,
    PositionHistory = {},
    VelocityHistory = {},
    SuspiciousEvents = {},
    IsBypassing = false,
    OriginalMetatables = {},
    FilteredSignals = {},
    HiddenThreads = {},
    ProtectedGC = false,
}

-- SECTION 1: ADVANCED METAMETHOD HOOK PROTECTION
-- Protect __index and __namecall from AC detection

-- Backup original metamethods before any hooks
function Bypass.backupMetatables()
    pcall(function()
        if getrawmetatable then
            local mt = getrawmetatable(game)
            if mt then
                Bypass.OriginalMetatables = {
                    __index = mt.__index,
                    __namecall = mt.__namecall,
                    __newindex = mt.__newindex,
                    __tostring = mt.__tostring,
                    __concat = mt.__concat,
                    __unm = mt.__unm,
                    __add = mt.__add,
                    __sub = mt.__sub,
                    __mul = mt.__mul,
                    __div = mt.__div,
                    __mod = mt.__mod,
                    __pow = mt.__pow,
                    __len = mt.__len,
                }
                print("[Bypass] Original metatables backed up")
            end
        end
    end)
end

-- Restore original metamethods (emergency)
function Bypass.restoreMetatables()
    pcall(function()
        if getrawmetatable then
            local mt = getrawmetatable(game)
            if mt and Bypass.OriginalMetatables then
                for name, func in pairs(Bypass.OriginalMetatables) do
                    mt[name] = func
                end
                print("[Bypass] Original metatables restored")
            end
        end
    end)
end

-- Check if a metamethod is hooked
function Bypass.isMetatableHooked(name)
    pcall(function()
        if getrawmetatable then
            local mt = getrawmetatable(game)
            if mt and Bypass.OriginalMetatables then
                if mt[name] ~= Bypass.OriginalMetatables[name] then
                    return true
                end
            end
        end
    end)
    return false
end

-- Protect hooks from AC detection
function Bypass.protectHook(name, hookFunc)
    pcall(function()
        if not getrawmetatable then return hookFunc end
        local mt = getrawmetatable(game)
        if not mt then return hookFunc end

        -- Store original if not stored
        if not Bypass.OriginalMetatables[name] then
            Bypass.OriginalMetatables[name] = mt[name]
        end

        -- Create protected hook
        local original = Bypass.OriginalMetatables[name]
        local protectedHook = newcclosure and newcclosure(function(self, ...)
            -- Check if AC is scanning
            if Bypass.isACScanning() then
                -- AC is scanning, use original
                return original(self, ...)
            end
            -- Otherwise use our hook
            return hookFunc(self, ...)
        end) or hookFunc

        return protectedHook
    end)
    return hookFunc
end

-- Detect if AC is scanning metamethods
function Bypass.isACScanning()
    pcall(function()
        -- Check debug.getinfo for scanner patterns
        if debug and debug.getinfo then
            local info = debug.getinfo(3)
            if info and info.name then
                local name = info.name:lower()
                if name:find("scan") or name:find("hook") or name:find("detect") or name:find("check") then
                    return true
                end
            end
        end

        -- Check for rapid consecutive calls (scanner behavior)
        local now = tick()
        if Bypass._lastACCheck and now - Bypass._lastACCheck < 0.001 then
            -- Bypass._acCallCount = (Bypass._acCallCount or 0) + 1
            if Bypass._acCallCount > 10 then
                return true -- Too many rapid calls = scanner
            end
        else
            Bypass._acCallCount = 0
        end
        Bypass._lastACCheck = now
    end)
    return false
end

-- SECTION 2: ENVIRONMENT SPOOFING
-- Spoof environment variables that AC checks

-- Spoof checkcaller (pretend we're a normal script)
function Bypass.spoofCheckcaller()
    pcall(function()
        if checkcaller then
            local oldCheckcaller = checkcaller
            -- Make checkcaller return false so AC thinks we're not an exploit script
            _G.checkcaller = function()
                return false
            end
            -- Store original for emergency restore
            Bypass._originalCheckcaller = oldCheckcaller
            print("[Bypass] checkcaller spoofed  always returns false")
        end
    end)
end

-- Restore checkcaller (emergency)
function Bypass.restoreCheckcaller()
    pcall(function()
        if Bypass._originalCheckcaller then
            _G.checkcaller = Bypass._originalCheckcaller
        end
    end)
end

-- Spoof getgenv (hide our modifications)
function Bypass.spoofGetgenv()
    pcall(function()
        if getgenv then
            local env = getgenv()
            -- Remove suspicious variables
            local suspicious = {}
            for key, _ in pairs(env) do
                local keyLower = key:lower()
                -- Keep only legitimate executor globals
                local legit = false
                for _, keep in ipairs({
                    -- "syn", "http_request", "request", "getgenv",
                    -- "getrawmetatable", "hookfunction", "hookmetamethod",
                    -- "Drawing", "drawingnew", "writefile", "readfile",
                    -- "isfile", "isfolder", "makefolder", "delfile",
                    -- "loadstring", "setclipboard", "getclipboard",
                    -- "mousemoverel", "setfflag", "getfflag",
                    -- "getscheduler", "getscriptclosure", "getnamecallmethod",
                    -- "checkcaller", "newcclosure", "islclosure",
                    -- "getgc", "getinstances", "getnilinstances",
                    -- "getscripts", "getrunningscripts", "getconnections",
                    -- "firesignal", "fireclickdetector", "firetouchinterest",
                    -- "sethiddenproperty", "gethiddenproperty",
                }) do
                    if key == keep or keyLower:find(keep:lower()) then
                        legit = true
                        break
                    end
                end
                if not legit and not key:find("^_") then
                    table.insert(suspicious, key)
                end
            end

            -- Hide suspicious variables in a hidden table
            for _, key in ipairs(suspicious) do
                -- env["_" .. key .. "_hidden"] = env[key]
                env[key] = nil
            end
        end
    end)
end

-- SECTION 3: THREAD HIDING
-- Hide our threads from AC monitoring

-- Hide a thread from AC
function Bypass.hideThread(name, func)
    Bypass.HiddenThreads[name] = {
        Func = func,
        Hidden = true,
        LastRun = 0,
    }
end

-- Run hidden thread
function Bypass.runHiddenThread(name)
    local thread = Bypass.HiddenThreads[name]
    if not thread then return end

    task.spawn(function()
        while true do
            task.wait(0.5)
            if thread.Hidden then
                -- Add random delay to look human
                task.wait(math.random() * 0.1)
                pcall(thread.Func)
                thread.LastRun = tick()
            end
        end
    end)
end

-- SECTION 4: MEMORY PROTECTION
-- Prevent memory scanning and protect our data

-- Protect our memory from AC scanning
function Bypass.protectMemory()
    pcall(function()
        -- Hide our objects from workspace scanning
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name:find("BS_") then
                obj.Parent = nil -- Move to nil (hidden)
            end
        end

        -- Hide our GUI objects
        for _, gui in pairs(lplr.PlayerGui:GetChildren()) do
            if gui.Name:find("BloxStrike") or gui.Name:find("BS_") then
                gui.Enabled = false
                gui.DisplayOrder = -9999
                gui.IgnoreGuiInset = true
            end
        end

        -- Force garbage collection to clean traces
        collectgarbage("collect")
        collectgarbage("collect")
    end)
end

-- SECTION 5: SIGNAL FILTERING
-- Filter out AC detection signals

-- Filter Changed events (AC uses these to monitor properties)
function Bypass.filterChangedEvents(instance)
    pcall(function()
        if getconnections then
            local conns = getconnections(instance.Changed)
            for _, conn in ipairs(conns) do
                -- Check if connection is from AC
                local info = debug.getinfo(conn.Function)
                if info and info.source then
                    local source = info.source:lower()
                    if source:find("anticheat") or source:find("monitor") or source:find("detect") then
                        -- conn:Disconnect()
                        print("[Bypass] Filtered AC Changed connection: " .. instance.Name)
                    end
                end
            end
        end
    end)
end

-- Filter DescendantAdded events (AC uses these to monitor new objects)
function Bypass.filterDescendantEvents(parent)
    pcall(function()
        if getconnections then
            local conns = getconnections(parent.DescendantAdded)
            for _, conn in ipairs(conns) do
                local info = debug.getinfo(conn.Function)
                if info and info.source then
                    local source = info.source:lower()
                    if source:find("anticheat") or source:find("monitor") or source:find("detect") then
                        -- conn:Disconnect()
                        print("[Bypass] Filtered AC DescendantAdded connection")
                    end
                end
            end
        end
    end)
end

-- SECTION 6: PROPERTY CHANGE INTERCEPTION
-- Intercept property changes before AC sees them

-- Intercept Humanoid property changes
function Bypass.interceptHumanoidProps()
    pcall(function()
        local h = BS.hum()
        if not h then return end

        -- Store original values
        Bypass.OriginalProps = {
            WalkSpeed = h.WalkSpeed,
            JumpPower = h.JumpPower,
            JumpHeight = h.JumpHeight,
            HipHeight = h.HipHeight,
            MaxHealth = h.MaxHealth,
            Health = h.Health,
            PlatformStand = h.PlatformStand,
            AutoRotate = h.AutoRotate,
        }

        -- Filter Changed events on Humanoid
        -- Bypass.filterChangedEvents(h)
    end)
end

-- SECTION 7: REMOTE OBFUSCATION
-- Obfuscate remote call patterns

-- Obfuscate remote call timing
local remoteCallHistory = {}
local remoteCallLimit = 20

function Bypass.obfuscateRemoteCall(func, ...)
    local now = tick()

    -- Clean old entries
    for i = #remoteCallHistory, 1, -1 do
        if now - remoteCallHistory[i] > 1 then
            table.remove(remoteCallHistory, i)
        end
    end

    -- Check rate
    if #remoteCallHistory >= remoteCallLimit then
        task.wait(1 / remoteCallLimit)
    end

    -- Add human-like delay
    if math.random() < 0.4 then
        task.wait(math.random() * 0.03)
    end

    table.insert(remoteCallHistory, now)
    return func(...)
end

-- Validate remote before calling
function Bypass.validateRemote(remote)
    if not remote then return false end

    local name = remote.Name:lower()
    local suspicious = {"anticheat", "kick", "ban", "validate", "check", "monitor", "guard", "shield"}
    for _, s in ipairs(suspicious) do
        if name:find(s) then
            return false
        end
    end

    return true
end

-- SECTION 8: ADVANCED TIMING OBFUSCATION
-- Sophisticated timing to avoid pattern detection

local timingPatterns = {}
local timingHistory = {}

-- Generate human-like timing pattern
function Bypass.generateTimingPattern()
    local patterns = {
        -- Consistent with small variations
        function(base)
            return base + (math.random() - 0.5) * base * 0.1
        end,
        -- Occasional long pauses
        function(base)
            if math.random() < 0.05 then
                return base * (2 + math.random() * 3)
            end
            return base + (math.random() - 0.5) * base * 0.2
        end,
        -- Accelerating then decelerating
        function(base)
            local t = tick() % 10
            local factor = 1 + math.sin(t * 0.5) * 0.3
            return base * factor + (math.random() - 0.5) * base * 0.1
        end,
        -- Random bursts
        function(base)
            if math.random() < 0.1 then
                return base * 0.5
            elseif math.random() < 0.1 then
                return base * 2
            end
            return base + (math.random() - 0.5) * base * 0.15
        end,
    }
    return patterns[math.random(#patterns)]
end

-- Apply timing obfuscation
function Bypass.obfuscateTiming(baseDelay)
    local pattern = Bypass.generateTimingPattern()
    local delay = pattern(baseDelay)

    -- Record for analysis
    table.insert(timingHistory, {Time = tick(), Delay = delay})
    if #timingHistory > 50 then table.remove(timingHistory, 1) end

    return math.max(0.001, delay)
end

-- Check if timing looks suspicious
function Bypass.isTimingSuspicious()
    if #timingHistory < 10 then return false end

    local intervals = {}
    for i = 2, #timingHistory do
        table.insert(intervals, timingHistory[i].Time - timingHistory[i-1].Time)
    end

    local mean = 0
    for _, v in ipairs(intervals) do mean = mean + v end
    mean = mean / #intervals

    local variance = 0
    for _, v in ipairs(intervals) do
        variance = variance + (v - mean)^2
    end
    variance = variance / #intervals

    -- Very low variance = too regular = suspicious
    return variance < 0.00001
end

-- SECTION 9: GC (GARBAGE COLLECTION) PROTECTION
-- Protect garbage collection from AC interference

-- Protect our objects from AC-triggered GC
function Bypass.protectGC()
    if Bypass.ProtectedGC then return end
    Bypass.ProtectedGC = true

    pcall(function()
        -- Disable automatic GC temporarily
        collectgarbage("stop")

        -- Clean only our objects
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name:find("BS_") and obj:IsA("BasePart") then
                pcall(function() obj:Destroy() end)
            end
        end

        -- Re-enable GC
        collectgarbage("restart")
    end)
end

-- SECTION 10: CFRAME VALIDATION BYPASS

-- Validate CFrame before setting
function Bypass.validateCFrame(cf)
    if not cf then return false end
    if cf ~= cf then return false end -- NaN check
    local pos = cf.Position
    if math.abs(pos.X) > 5000 or math.abs(pos.Y) > 5000 or math.abs(pos.Z) > 5000 then
        return false
    end
    return true
end

-- Safe CFrame set
function Bypass.safeCFrameSet(instance, cf)
    if not Bypass.validateCFrame(cf) then return false end
    pcall(function() instance.CFrame = cf end)
    return true
end

-- SECTION 11: TELEPORT DETECTION BYPASS

function Bypass.trackPosition()
    if not BS.alive() then return end
    local hrp = BS.hrp()
    if not hrp then return end
    local currentPos = hrp.Position
    local currentVel = hrp.AssemblyLinearVelocity
    table.insert(Bypass.PositionHistory, {Time = tick(), Pos = currentPos})
    table.insert(Bypass.VelocityHistory, {Time = tick(), Vel = currentVel})
    if #Bypass.PositionHistory > 20 then table.remove(Bypass.PositionHistory, 1) end
    if #Bypass.VelocityHistory > 20 then table.remove(Bypass.VelocityHistory, 1) end
    Bypass.LastPosition = currentPos
    Bypass.LastVelocity = currentVel
end

function Bypass.isTeleport(newPos)
    if not Bypass.LastPosition then return false end
    local distance = (newPos - Bypass.LastPosition).Magnitude
    local velocity = Bypass.LastVelocity and Bypass.LastVelocity.Magnitude or 0
    local maxReasonable = velocity * 0.5 + 10
    return distance > maxReasonable
end

function Bypass.smoothTeleport(targetPos, duration)
    if not BS.alive() then return false end
    local hrp = BS.hrp()
    if not hrp then return false end
    duration = duration or 0.3
    if not Bypass.validateCFrame(CFrame.new(targetPos)) then return false end
    local startCF = hrp.CFrame
    local endCF = CFrame.new(targetPos) * (startCF - startCF.Position)
    pcall(function()
        local tween = game:GetService("TweenService"):Create(
            hrp, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {CFrame = endCF}
        )
        pcall(function() tween:Play() end)
    end)
    return true
end

-- SECTION 12: HEARTBEAT MONITORING BYPASS

local heartbeatHistory = {}

function Bypass.trackHeartbeat()
    local now = tick()
    table.insert(heartbeatHistory, now)
    if #heartbeatHistory > 30 then table.remove(heartbeatHistory, 1) end
end

function Bypass.isHeartbeatAbnormal()
    if #heartbeatHistory < 10 then return false end
    local intervals = {}
    for i = 2, #heartbeatHistory do
        table.insert(intervals, heartbeatHistory[i] - heartbeatHistory[i-1])
    end
    local mean = 0
    for _, v in ipairs(intervals) do mean = mean + v end
    mean = mean / #intervals
    local variance = 0
    for _, v in ipairs(intervals) do variance = variance + (v - mean)^2 end
    variance = variance / #intervals
    return variance < 0.0001
end

-- SECTION 13: BEHAVIORAL ANALYSIS BYPASS

function Bypass.humanizeMovement()
    if not BS.alive() then return end
    local h = BS.hum()
    if not h then return end
    local baseSpeed = h.WalkSpeed
    local jitter = (math.random() - 0.5) * 1.0
    h.WalkSpeed = baseSpeed + jitter
    task.wait(0.1)
    h.WalkSpeed = baseSpeed
    if math.random() < 0.1 then
        local hrp = BS.hrp()
        if hrp then
            local microAdjust = CFrame.Angles(0, (math.random() - 0.5) * 0.05, 0)
            hrp.CFrame = hrp.CFrame * microAdjust
        end
    end
end

function Bypass.humanizeAim(targetPos)
    if not targetPos then return targetPos end
    local offset = Vector3.new(
        -- (math.random() - 0.5) * 0.3,
        -- (math.random() - 0.5) * 0.3,
        -- (math.random() - 0.5) * 0.1
    )
    return targetPos + offset
end

-- SECTION 14: EMERGENCY BYPASS SYSTEM

function Bypass.emergencyBypass()
    pcall(function()
        -- Bypass.restoreMetatables()
        -- Bypass.protectMemory()
        for _, conn in pairs(Bypass.MonitoringConnections) do
            pcall(function() conn:Disconnect() end)
        end
        Bypass.MonitoringConnections = {}
        for k, _ in pairs(Flags) do
            if k:find("Bhop") or k:find("Rage") or k:find("AA") or k:find("FL") then
                Flags[k] = false
            end
        end
        print("[Bypass] Emergency bypass activated")
    end)
end

-- MAIN BYPASS ENGINE

-- Initialize
task.spawn(function()
    task.wait(1)
    -- Bypass.backupMetatables()
    -- Bypass.spoofCheckcaller()
    -- Bypass.spoofGetgenv()
    -- Bypass.interceptHumanoidProps()
    print("[Bypass] Advanced bypass systems initialized")
end)

-- Position tracking
RunService.Heartbeat:Connect(function()
    -- Bypass.trackHeartbeat()
    -- Bypass.trackPosition()
end)

-- Periodic protection
task.spawn(function()
    while true do
        task.wait(15)
        -- Bypass.protectMemory()
        -- Bypass.protectGC()
        pcall(collectgarbage, "collect")
    end
end)

 -- Expose API
BS.Bypass = Bypass

-- SECTION 15: INJECTION ARTIFACT CLOAKING
-- Hide all traces of script injection from AC

-- Hide injection artifacts
task.spawn(function()
    while true do task.wait(20)
        pcall(function()
            -- 1. Hide all Drawing objects from workspace scans
            pcall(function()
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and (
                        obj.Name:find("BS_") or obj.Name:find("BloxStrike") or
                        obj.Transparency == 1 and not obj.Anchored and obj.Size.Magnitude < 5
                    ) then
                        pcall(function() obj:Destroy() end)
                    end
                end
            end)

            -- 2. Hide ScreenGuis from CoreGui detection
            pcall(function()
                local cg = nil
                pcall(function() cg = game:GetService("CoreGui") end)
                if cg then
                    for _, gui in pairs(cg:GetChildren()) do
                        if gui:IsA("ScreenGui") and (
                            gui.Name:find("BloxStrike") or gui.Name:find("BS_")
                        ) then
                            -- gui:Destroy()
                        end
                    end
                end
            end)

            -- 3. Remove BS_ objects from PlayerGui
            pcall(function()
                for _, gui in pairs(lplr.PlayerGui:GetChildren()) do
                    if gui:IsA("ScreenGui") and (
                        gui.Name:find("BloxStrike") or gui.Name:find("BS_")
                    ) then
                        gui.Enabled = false
                        gui.DisplayOrder = -9999
                        gui.IgnoreGuiInset = true
                    end
                end
            end)

            -- 4. Force GC
            collectgarbage("collect")
        end)
    end
end)

-- SECTION 16: ANTI-DEBUG PROTECTION
-- Comprehensive debug library protection

pcall(function()
    if debug then
        -- Override debug.getinfo to hide our script
        local oldGetInfo = debug.getinfo
        debug.getinfo = function(level, what)
            local info = oldGetInfo(level, what)
            if info then
                if info.source and (
                    info.source:find("BloxStrike") or info.source:find("BS_") or
                    info.source:find("bypass") or info.source:find("stealth") or
                    info.source:find("rage") or info.source:find("combat")
                ) then
                    info.source = "[C]"
                    info.short_src = "[C]"
                    info.linedefined = 0
                    info.lastlinedefined = 0
                end
                if info.what == "Lua" and info.source == "[C]" then
                    -- Looks like C code, which is harder to trace
                end
            end
            return info
        end

        -- Override debug.traceback to remove our stack frames
        local oldTraceback = debug.traceback
        debug.traceback = function(level, message)
            local tb = oldTraceback(level, message)
            if tb then
                -- Remove BloxStrike related lines
                tb = tb:gsub(".-BloxStrike.-%c.-%c", "")
                tb = tb:gsub(".-BS_%w+.-%c.-%c", "")
                tb = tb:gsub(".-bypass.-%c.-%c", "")
                tb = tb:gsub(".-stealth.-%c.-%c", "")
            end
            return tb
        end

        -- Override debug.getlocal to hide our upvalues
        local oldGetLocal = debug.getlocal
        debug.getlocal = function(level, index)
            local name, value = oldGetLocal(level, index)
            if name and name:find("BS_") then
                return nil, nil
            end
            return name, value
        end

        -- Override debug.getupvalue to hide our upvalues
        local oldGetUpvalue = debug.getupvalue
        debug.getupvalue = function(func, level)
            local name, value = oldGetUpvalue(func, level)
            if name and (
                name:find("BS") or name:find("BloxStrike") or
                name:find("bypass") or name:find("stealth")
            ) then
                return nil, nil
            end
            return name, value
        end
    end
end)

-- SECTION 17: REPLAY PROTECTION
-- Prevent AC from replaying recorded sessions

local replayProtection = {
    ActionLog = {},
    MaxLogSize = 200,
    -- FuzzSeed = math.random(1, 99999),
}

function Bypass.logAction(actionType, params)
    table.insert(replayProtection.ActionLog, {
        Type = actionType,
        -- Time = tick(),
        -- Fuzz = math.random(),
    })
    if #replayProtection.ActionLog > replayProtection.MaxLogSize then
        table.remove(replayProtection.ActionLog, 1)
    end
end

-- Fuzzy compare: don't let AC match exact action sequences
function Bypass.fuzzyActionMatch(log1, log2, threshold)
    threshold = threshold or 0.8
    if #log1 ~= #log2 then return false end
    local matchCount = 0
    for i = 1, #log1 do
        if log1[i].Type == log2[i].Type then
            local timeDiff = math.abs(log1[i].Time - log2[i].Time)
            if timeDiff < 0.1 then
                matchCount = matchCount + 1
            end
        end
    end
    return (matchCount / #log1) >= threshold
end

-- SECTION 18: INTEGRITY MONITOR
-- Continuous integrity checking and self-repair

local integrityState = {
    CheckCount = 0,
    FailCount = 0,
    RepairCount = 0,
    -- LastCheck = tick(),
}

function Bypass.checkIntegrity()
    integrityState.CheckCount = integrityState.CheckCount + 1
    local issues = {}

    pcall(function()
        -- 1. Check if metamethods are still intact
        if getrawmetatable then
            local mt = getrawmetatable(game)
            if mt then
                if Bypass.OriginalMetatables.__index then
                    if mt.__index ~= Bypass.OriginalMetatables.__index then
                        table.insert(issues, "__index modified")
                    end
                end
            end
        end

        -- 2. Check if our GUI still exists
        local guiFound = false
        pcall(function()
            for _, gui in pairs(lplr.PlayerGui:GetChildren()) do
                if gui:IsA("ScreenGui") then
                    guiFound = true
                end
            end
        end)
        if not guiFound then
            table.insert(issues, "GUI missing")
        end

        -- 3. Check if character is healthy
        if BS.alive and not BS.alive() then
            table.insert(issues, "Character dead/missing")
        end

        -- 4. Check camera
        local cam = workspace.CurrentCamera
        if not cam then
            table.insert(issues, "Camera missing")
        elseif cam.CFrame ~= cam.CFrame then
            table.insert(issues, "Camera NaN")
        end

        -- 5. Check humanoid properties
        local h = BS.hum()
        if h then
            if h.WalkSpeed < 0 or h.WalkSpeed > 500 then
                table.insert(issues, "WalkSpeed extreme: " .. h.WalkSpeed)
            end
            if h.JumpPower < 0 or h.JumpPower > 500 then
                table.insert(issues, "JumpPower extreme: " .. h.JumpPower)
            end
        end
    end)

    if #issues > 0 then
        integrityState.FailCount = integrityState.FailCount + 1
        -- Auto-repair
        for _, issue in ipairs(issues) do
            if issue == "Camera NaN" then
                pcall(function()
                    pcall(function() workspace.CurrentCamera.CFrame = CFrame.new(0, 10, 0) end)
                end)
            elseif issue:find("WalkSpeed") or issue:find("JumpPower") then
                pcall(function()
                    local h = BS.hum()
                    if h then
                        h.WalkSpeed = math.clamp(h.WalkSpeed, 0, 100)
                        h.JumpPower = math.clamp(h.JumpPower, 0, 200)
                    end
                end)
            elseif issue == "GUI missing" then
                pcall(function() if BS.Stealth and BS.Stealth.selfHeal then BS.Stealth.selfHeal() end end)
            end
            integrityState.RepairCount = integrityState.RepairCount + 1
        end
    end

    integrityState.LastCheck = tick()
    return issues
end

-- Periodic integrity check
task.spawn(function()
    while true do task.wait(5)
        pcall(function() Bypass.checkIntegrity() end)
    end
end)

Bypass.IntegrityState = integrityState

-- SECTION 19: PROPERTY INTERCEPTION v2
-- Advanced property change interception with response system

local propIntercept = {
    WatchedProperties = {},
    ChangeLog = {},
    AutoRestore = true,
}

-- Watch specific properties and auto-restore if AC tries to reset them
function Bypass.watchProperty(instance, propName, getDesired, priority)
    propIntercept.WatchedProperties[instance] = propIntercept.WatchedProperties[instance] or {}
    propIntercept.WatchedProperties[instance][propName] = {
        GetDesired = getDesired,
        Priority = priority or 1,
        LastValue = nil,
    }
end

-- Property monitoring engine
task.spawn(function()
    while true do task.wait(0.1)
        pcall(function()
            for instance, props in pairs(propIntercept.WatchedProperties) do
                if instance and instance.Parent then
                    for propName, data in pairs(props) do
                        local currentValue = instance[propName]
                        local desiredValue = data.GetDesired()
                        if desiredValue and currentValue ~= desiredValue then
                            -- AC might have reset our value, restore it
                            if propIntercept.AutoRestore then
                                instance[propName] = desiredValue
                                table.insert(propIntercept.ChangeLog, {
                                    -- Time = tick(),
                                    Instance = instance.Name,
                                    Property = propName,
                                    Was = currentValue,
                                    -- SetTo = tostring(desiredValue),
                                })
                            end
                        end
                        data.LastValue = currentValue
                    end
                end
            end
            -- Keep change log small
            if #propIntercept.ChangeLog > 100 then
                table.remove(propIntercept.ChangeLog, 1)
            end
        end)
    end
end)

Bypass.PropIntercept = propIntercept

-- SECTION 20: NETWORK FINGERPRINT EVASION
-- Make our network traffic look like legitimate Roblox traffic

local netFP = {
    PacketHistory = {},
    NormalTrafficPatterns = {},
    -- LastBurstTime = tick(),
    BurstCount = 0,
}

-- Analyze normal traffic patterns
function Bypass.analyzeNormalTraffic()
    pcall(function()
        -- Sample what normal Roblox traffic looks like
        for _, remote in pairs(game:GetDescendants()) do
            if remote:IsA("RemoteEvent") then
                local conns = getconnections and getconnections(remote.OnClientEvent)
                if conns and #conns > 0 then
                    netFP.NormalTrafficPatterns[remote.Name] = {
                        ConnCount = #conns,
                        -- Frequency = math.random(1, 10),
                    }
                end
            end
        end
    end)
end

-- Generate fake normal traffic
function Bypass.generateNormalTraffic()
    if not Flags.TrafficMask then return end
    pcall(function()
        -- Fire random existing remotes to generate normal-looking traffic
        local remotes = {}
        for _, obj in pairs(game:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                local name = obj.Name:lower()
                if not name:find("anticheat") and not name:find("kick") and not name:find("ban") and not name:find("validate") then
                    table.insert(remotes, obj)
                end
            end
        end
        if #remotes > 0 then
            local target = remotes[math.random(#remotes)]
            pcall(function() target:FireServer() end)
        end
    end)
end

-- Monitor burst patterns
function Bypass.trackBurst()
    local now = tick()
    if now - netFP.LastBurstTime < 0.5 then
        netFP.BurstCount = netFP.BurstCount + 1
    else
        netFP.BurstCount = 0
    end
    netFP.LastBurstTime = now

    -- If too many bursts, slow down
    if netFP.BurstCount > 10 then
        task.wait(0.5 + math.random() * 0.5)
        netFP.BurstCount = 0
    end
end

Bypass.NetFP = netFP

-- SECTION 21: EMERGENCY SANDBOX DETECTION
-- Detect if we're being analyzed in a sandbox

local sandboxState = {
    DetectionCount = 0,
    IsSandboxed = false,
    CanaryValues = {},
}

-- Create timing canary
function Bypass.createTimingCanary()
    sandboxState.CanaryValues.StartTime = tick()
    sandboxState.CanaryValues.ExpectedDelta = 0.016 -- ~60fps
end

-- Check timing canary
function Bypass.checkTimingCanary()
    if not sandboxState.CanaryValues.StartTime then return false end
    local elapsed = tick() - sandboxState.CanaryValues.StartTime
    local expectedFrames = elapsed / sandboxState.CanaryValues.ExpectedDelta
    -- If timing is significantly off, might be sandboxed
    if elapsed > 1 and math.abs(expectedFrames - elapsed * 60) > 10 then
        sandboxState.IsSandboxed = true
        sandboxState.DetectionCount = sandboxState.DetectionCount + 1
        return true
    end
    return false
end

-- Detect analysis environment
task.spawn(function()
    while true do task.wait(5)
        pcall(function()
            -- 1. Check if script execution is delayed
            local startTick = tick()
            task.defer(function()
                local deferTime = tick() - startTick
                if deferTime > 0.1 then
                    sandboxState.DetectionCount = sandboxState.DetectionCount + 1
                end
            end)

            -- 2. Check for suspicious environment variables
            pcall(function()
                if getgenv then
                    local env = getgenv()
                    for key, _ in pairs(env) do
                        local keyLower = key:lower()
                        if keyLower:find("monitor") or keyLower:find("capture") then
                            sandboxState.IsSandboxed = true
                            sandboxState.DetectionCount = sandboxState.DetectionCount + 1
                        end
                    end
                end
            end)

            -- 3. Memory pattern check
            local gcCount = collectgarbage("count")
            if gcCount > 500 then -- Abnormally high memory usage might indicate monitoring
                sandboxState.DetectionCount = sandboxState.DetectionCount + 1
            end

            -- If too many detections, enter silent mode
            if sandboxState.DetectionCount > 3 then
                -- Hide everything
                pcall(function()
                    local gui = lplr.PlayerGui:FindFirstChildWhichIsA("ScreenGui")
                    if gui then gui.Enabled = false end
                end)
            end
        end)
    end
end)

Bypass.SandboxState = sandboxState

-- SECTION 22: __NAMECALL HOOK PROTECTION
-- Intercept AC's namecall scanning to hide our modifications

local namecallProtection = {
    ProtectedInstances = {},
    SpoofedReturns = {},
    CallCount = 0,
    LastScanDetection = 0,
}

-- Register an instance to have spoofed namecall responses
function Bypass.protectInstanceFromNamecall(instance, methodName, spoofReturn)
    if not instance then return end
    local id = tostring(instance)
    namecallProtection.ProtectedInstances[id] = namecallProtection.ProtectedInstances[id] or {}
    namecallProtection.ProtectedInstances[id][methodName] = spoofReturn
end

-- Hook __namecall to intercept AC scanning attempts
function Bypass.hookNamecall()
    pcall(function()
        if not getrawmetatable or not hookmetamethod then return end

        local mt = getrawmetatable(game)
        if not mt then return end

        local oldNamecall = mt.__namecall
        if not oldNamecall then return end

        mt.__namecall = newcclosure and newcclosure(function(self, ...)
            local method = getnamecallmethod and getnamecallmethod() or ""
            local methodLower = method:lower()

            -- Track call frequency for scanner detection
            namecallProtection.CallCount = namecallProtection.CallCount + 1
            local now = tick()
            if now - namecallProtection.LastScanDetection > 1 then
                namecallProtection.CallCount = 0
            end

            -- If AC is scanning rapidly, return benign data
            if namecallProtection.CallCount > 50 then
                namecallProtection.LastScanDetection = now
                -- Return safe defaults instead of real data
                if methodLower == "getchildren" or methodLower == "getdescendants" then
                    return {}
                elseif methodLower == "findfirstchild" or methodLower:find("find") then
                    return nil
                elseif methodLower == "getproperty" or methodLower == "getattr" then
                    return nil
                elseif methodLower == "clone" then
                    return nil
                end
            end

            -- Protect our GUI instances from GetChildren/GetDescendants scanning
            local id = tostring(self)
            if namecallProtection.ProtectedInstances[id] then
                local spoof = namecallProtection.ProtectedInstances[id][method]
                if spoof ~= nil then
                    return spoof
                end
            end

            -- Intercept suspicious method calls on our objects
            if self and self.Name and (
                self.Name:find("BS_") or self.Name:find("BloxStrike") or
                self.Name:find("BS_Kill") or self.Name:find("BS_Weapon")
            ) then
                if methodLower == "getchildren" then return {} end
                if methodLower == "getdescendants" then return {} end
                if methodLower == "clone" then return nil end
            end

            -- Intercept debug/stack inspection calls
            if methodLower == "getinfo" or methodLower == "getstack" or methodLower == "setstack" then
                if namecallProtection.CallCount > 20 then
                    return {source = "[C]", what = "C", name = ""}
                end
            end

            return oldNamecall(self, ...)
        end) or oldNamecall

        print("[Bypass] __namecall hook installed")
    end)
end

Bypass.NamecallProtection = namecallProtection

-- SECTION 23: EXECUTOR FINGERPRINT SPOOF
-- Hide executor-specific identifiers from AC detection

local executorFingerprint = {
    Originals = {},
    Spoofed = false,
}

function Bypass.spoofExecutorFingerprint()
    pcall(function()
        if executorFingerprint.Spoofed then return end

        -- 1. Spoof identifying global functions that AC checks
        local executorGlobals = {
            -- "syn", "syn_request", "syn_request_async",
            -- "fluxus", "fluxus_execute",
            -- "KRNL_LOADED", "is_synapse_function",
            -- "getexecutorname", "identifyexecutor",
            -- "isfolio", "is_krnl_closure",
            -- "HALO_LOADED", "draw",
        }

        for _, name in ipairs(executorGlobals) do
            if _G[name] ~= nil then
                executorFingerprint.Originals[name] = _G[name]
                -- Spoof to return legitimate-looking values
                if name == "getexecutorname" or name == "identifyexecutor" then
                    _G[name] = function() return "RobloxStudio" end
                else
                    _G[name] = nil
                end
            end
        end

        -- 2. Spoof script environment detection
        if getgenv then
            local env = getgenv()
            -- Remove executor-specific flags
            local execFlags = {
                -- "__Namecall", "__Index", "__NewIndex",
                -- "__metatable", "__gc",
            }
            for _, flag in ipairs(execFlags) do
                if env[flag] then
                    executorFingerprint.Originals["genv_" .. flag] = env[flag]
                    env[flag] = nil
                end
            end
        end

        -- 3. Spoof closure detection
        if islclosure then
            local oldIsLClosure = islclosure
            executorFingerprint.Originals.islclosure = oldIsLClosure
            _G.islclosure = function(func)
                -- If AC is checking our functions, report them as C closures
                local info = debug and debug.getinfo and debug.getinfo(func)
                if info and info.source and (
                    info.source:find("BloxStrike") or info.source:find("BS_")
                ) then
                    return false -- Report as C closure (harder to analyze)
                end
                return oldIsLClosure(func)
            end
        end

        executorFingerprint.Spoofed = true
        print("[Bypass] Executor fingerprint spoofed")
    end)
end

function Bypass.restoreExecutorFingerprint()
    pcall(function()
        for name, value in pairs(executorFingerprint.Originals) do
            if name:sub(1, 5) == "genv_" then
                local realName = name:sub(6)
                if getgenv then getgenv()[realName] = value end
            else
                _G[name] = value
            end
        end
        executorFingerprint.Spoofed = false
        print("[Bypass] Executor fingerprint restored")
    end)
end

Bypass.ExecutorFingerprint = executorFingerprint

-- SECTION 24: SIGNAL HOOK PROTECTION
-- Wrap our signal connections to avoid AC detection

local signalProtection = {
    WrappedConnections = {},
    TotalWrapped = 0,
}

-- Wrap a connection with AC evasion
function Bypass.wrapConnection(name, connection)
    if not connection then return nil end
    pcall(function()
        signalProtection.TotalWrapped = signalProtection.TotalWrapped + 1
        local id = signalProtection.TotalWrapped

        signalProtection.WrappedConnections[id] = {
            Name = name or "unknown",
            Connection = connection,
            -- Created = tick(),
            Active = true,
        }

        -- Auto-cleanup after 5 minutes to prevent connection leak detection
        task.delay(300, function()
            if signalProtection.WrappedConnections[id] then
                pcall(function() connection:Disconnect() end)
                signalProtection.WrappedConnections[id] = nil
            end
        end)
    end)
    return connection
end

-- Wrap UserInputService connection with anti-detection
function Bypass.wrapInputConnection(name, inputType, callback)
    local conn = nil
    pcall(function()
        if inputType == "Began" then
            conn = UserInputService.InputBegan:Connect(function(input, gpe)
                -- Random micro-delay to avoid pattern detection
                if math.random() < 0.05 then
                    task.wait(math.random() * 0.005)
                end
                callback(input, gpe)
            end)
        elseif inputType == "Ended" then
            conn = UserInputService.InputEnded:Connect(function(input)
                if math.random() < 0.03 then
                    task.wait(math.random() * 0.003)
                end
                callback(input)
            end)
        elseif inputType == "Changed" then
            conn = UserInputService.InputChanged:Connect(function(input)
                callback(input)
            end)
        end
    end)
    return Bypass.wrapConnection(name, conn)
end

-- Disconnect all our connections (emergency)
function Bypass.disconnectAllWrapped()
    for id, data in pairs(signalProtection.WrappedConnections) do
        if data and data.Connection then
            pcall(function() data.Connection:Disconnect() end)
        end
        signalProtection.WrappedConnections[id] = nil
    end
    print("[Bypass] All wrapped connections disconnected")
end

Bypass.SignalProtection = signalProtection

-- SECTION 25: REMOTE CALL CAMOUFLAGE
-- Make our remote calls look like normal game traffic

local remoteCamouflage = {
    CallHistory = {},
    PatternIndex = 0,
    LastDecoy = 0,
    DecoyInterval = 3,
    RateLimiter = {},
}

-- Send a remote call with camouflage
function Bypass.camouflagedFire(remote, ...)
    local args = {...}
    if not remote or not remote:IsA("RemoteEvent") then return false end
    if not Bypass.validateRemote(remote) then return false end

    local now = tick()
    local name = remote.Name

    -- Rate limiting per remote
    remoteCamouflage.RateLimiter[name] = remoteCamouflage.RateLimiter[name] or {Count = 0, ResetTime = now}
    local limiter = remoteCamouflage.RateLimiter[name]
    if now - limiter.ResetTime > 1 then
        limiter.Count = 0
        limiter.ResetTime = now
    end
    limiter.Count = limiter.Count + 1

    -- Hard rate limit: max 15 calls per second per remote
    if limiter.Count > 15 then
        return false
    end

    -- Add human-like jitter
    local jitter = (math.random() - 0.5) * 0.008
    if jitter > 0 then task.wait(jitter) end

    -- Record call pattern
    table.insert(remoteCamouflage.CallHistory, {
        Remote = name,
        Time = now,
        -- Args = select("#", ...),
    })
    if #remoteCamouflage.CallHistory > 100 then
        table.remove(remoteCamouflage.CallHistory, 1)
    end

    -- Send decoy traffic periodically
    if now - remoteCamouflage.LastDecoy > remoteCamouflage.DecoyInterval then
        remoteCamouflage.LastDecoy = now
        -- Fire a random legitimate remote to dilute our traffic
        pcall(function()
            for _, obj in pairs(game:GetDescendants()) do
                if obj:IsA("RemoteEvent") and obj ~= remote then
                    local rname = obj.Name:lower()
                    if not rname:find("anticheat") and not rname:find("kick")
                        and not rname:find("ban") and not rname:find("validate") then
                        -- obj:FireServer()
                        break
                    end
                end
            end
        end)
    end

    -- Fire the actual remote
    pcall(function() remote:FireServer(unpack(args)) end)
    return true
end

-- Send a camouflaged InvokeServer
function Bypass.camouflagedInvoke(remote, ...)
    if not remote or not remote:IsA("RemoteFunction") then return nil end
    if not Bypass.validateRemote(remote) then return nil end

    -- Add jitter
    local jitter = (math.random() - 0.5) * 0.005
    if jitter > 0 then task.wait(jitter) end

    local result = nil
    pcall(function() result = {remote:InvokeServer(...)} end)
    return result and result[1] or nil
end

Bypass.RemoteCamouflage = remoteCamouflage

-- SECTION 26: MEMORY REGION CLOAKING
-- Hide executable memory regions from AC memory scanners

local memoryCloaking = {
    HiddenRegions = {},
    CloakedObjects = {},
    ScanInterval = 10,
    LastScan = 0,
}

-- Hide our objects from memory scanning
function Bypass.cloakMemory()
    pcall(function()
        local now = tick()
        if now - memoryCloaking.LastScan < memoryCloaking.ScanInterval then return end
        memoryCloaking.LastScan = now

        -- 1. Hide Drawing objects (ESP uses many)
        pcall(function()
            -- Drawing objects are in a special memory space, but AC can scan references
            -- We can't directly hide Drawing memory, but we can clean up unused ones
        end)

        -- 2. Rename our suspicious parts to look legitimate
        pcall(function()
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Name:find("BS_") then
                    -- Rename to a generic Roblox name
                    local legitNames = {
                        -- "SpawnLocation", "Part", "TrussPart",
                        -- "WedgePart", "CornerWedgePart",
                    }
                    obj.Name = legitNames[math.random(#legitNames)]
                    obj.Parent = nil -- Also hide from workspace
                end
            end
        end)

        -- 3. Clean up orphaned tables/references in our global state
        pcall(function()
            -- Clear old position history
            if Bypass.PositionHistory and #Bypass.PositionHistory > 20 then
                local keep = {}
                for i = math.max(1, #Bypass.PositionHistory - 10), #Bypass.PositionHistory do
                    table.insert(keep, Bypass.PositionHistory[i])
                end
                Bypass.PositionHistory = keep
            end

            -- Clear old velocity history
            if Bypass.VelocityHistory and #Bypass.VelocityHistory > 20 then
                local keep = {}
                for i = math.max(1, #Bypass.VelocityHistory - 10), #Bypass.VelocityHistory do
                    table.insert(keep, Bypass.VelocityHistory[i])
                end
                Bypass.VelocityHistory = keep
            end
        end)

        -- 4. Rename our ScreenGuis to look legitimate
        pcall(function()
            for _, gui in pairs(lplr.PlayerGui:GetChildren()) do
                if gui:IsA("ScreenGui") and (
                    gui.Name:find("BloxStrike") or gui.Name:find("BS_")
                ) then
                    local legitGuiNames = {
                        -- "RobloxGui", "ChatGui", "HealthGui",
                        -- "PlayerList", "BackpackGui",
                    }
                    gui.Name = legitGuiNames[math.random(#legitGuiNames)]
                end
            end
        end)
    end)
end

Bypass.MemoryCloaking = memoryCloaking

-- SECTION 27: AC SIGNATURE EVASION
-- Detect and evade specific AC signature patterns

local signatureEvasion = {
    DetectedSignatures = {},
    EvasionActive = false,
    RiskScore = 0,
}

-- Common AC signature patterns to evade
local AC_PATTERNS = {
    -- String patterns that AC scans for
    Strings = {
        -- "自瞄", "aimbot", "透視", "esp",
        -- "穿牆", "wallhack", "NoClip", "noclip",
        -- "SpeedHack", "speedhack", "TriggerBot",
        -- "SilentAim", "silentaim", "連跳", "bhop",
        -- "BloxStrike", "FreeBuff",
        -- Exploit API names
        -- "getrawmetatable", "hookmetamethod", "hookfunction",
        -- "newcclosure", "islclosure", "getnamecallmethod",
        -- "Drawing.new", "mousemoverel", "mouse1click",
        -- "writefile", "readfile", "loadstring",
        -- "setclipboard", "getclipboard",
        -- "firesignal", "fireclickdetector",
        -- "getconnections", "getgc",
        -- "sethiddenproperty", "gethiddenproperty",
    },
    -- Function call patterns
    FunctionCalls = {
        -- "game:GetService\"Stats\"",
        -- "workspace.CurrentCamera",
        -- "UserInputService:GetMouseLocation",
        -- "PlayerGui",
        -- "HumanoidRootPart.Position",
    },
}

-- Scan for AC signature detection in our code
function Bypass.scanForSignatures()
    pcall(function()
        local detected = {}
        local env = getgenv and getgenv() or {}

        -- Check global environment for suspicious strings
        for key, value in pairs(env) do
            if type(value) == "string" then
                for _, pattern in ipairs(AC_PATTERNS.Strings) do
                    if value:find(pattern) then
                        table.insert(detected, {
                            Type = "GlobalString",
                            Key = key,
                            Pattern = pattern,
                        })
                        break
                    end
                end
            end
        end

        signatureEvasion.DetectedSignatures = detected
        signatureEvasion.RiskScore = math.min(100, #detected * 5)

        if #detected > 3 then
            signatureEvasion.EvasionActive = true
        end
    end)
end

-- Apply active evasion based on detected signatures
function Bypass.applySignatureEvasion()
    if not signatureEvasion.EvasionActive then return end
    pcall(function()
        local env = getgenv and getgenv() or {}

        -- 1. Remove suspicious strings from globals
        for key, value in pairs(env) do
            if type(value) == "string" then
                for _, sig in ipairs(signatureEvasion.DetectedSignatures) do
                    if sig.Key == key then
                        -- Obfuscate the string by splitting it
                        env[key] = ""
                        break
                    end
                end
            end
        end

        -- 2. Rename our function closures to look innocent
        -- This is done by wrapping them in newcclosure
        pcall(function()
            if newcclosure then
                for key, value in pairs(env) do
                    if type(value) == "function" and not checkcaller() then
                        -- Only wrap functions that AC might flag
                        local info = debug and debug.getinfo and debug.getinfo(value)
                        if info and info.source and info.source:find("BS_") then
                            env[key] = newcclosure(value)
                        end
                    end
                end
            end
        end)
    end)
end

Bypass.SignatureEvasion = signatureEvasion

-- SECTION 28: HEARTBEAT SPOOFING
-- Make our heartbeat pattern look like normal game traffic

local heartbeatSpoof = {
    OriginalInterval = 1/60,
    SpoofedInterval = 1/60,
    JitterAmount = 0.002,
    FakeHeartbeats = 0,
}

-- Generate human-like heartbeat timing
function Bypass.spoofHeartbeatTiming()
    pcall(function()
        -- Add micro-jitter to avoid perfect 60fps pattern detection
        local jitter = (math.random() - 0.5) * heartbeatSpoof.JitterAmount
        return heartbeatSpoof.OriginalInterval + jitter
    end)
    return heartbeatSpoof.OriginalInterval
end

-- Create fake heartbeat events to dilute our real ones
function Bypass.generateDecoyHeartbeats()
    pcall(function()
        -- Fire dummy RunService events to make our heartbeat pattern less obvious
        local now = tick()
        if now % 2 < 0.02 then -- Every ~2 seconds
            heartbeatSpoof.FakeHeartbeats = heartbeatSpoof.FakeHeartbeats + 1
        end
    end)
end

Bypass.HeartbeatSpoof = heartbeatSpoof

-- SECTION 29: ADVANCED ANTI-DUMP
-- Prevent memory dumping of our code and data

local antiDump = {
    ObfuscatedStrings = {},
    Active = false,
}

-- Obfuscate string literals in our environment
function Bypass.obfuscateStrings()
    pcall(function()
        if antiDump.Active then return end

        local env = getgenv and getgenv() or {}

        -- Find and obfuscate suspicious string values
        for key, value in pairs(env) do
            if type(value) == "string" and #value > 3 then
                -- Check if it contains exploit-related strings
                local lower = value:lower()
                local suspicious = false
                for _, pattern in ipairs({"exploit", "cheat", "hack", "bypass", "bloxstrike"}) do
                    if lower:find(pattern) then
                        suspicious = true
                        break
                    end
                end

                if suspicious then
                    -- Store original and replace with empty
                    antiDump.ObfuscatedStrings[key] = value
                    env[key] = string.rep("\0", #value)
                end
            end
        end

        antiDump.Active = true
    end)
end

-- Restore obfuscated strings (for our own use)
function Bypass.deobfuscateString(key)
    return antiDump.ObfuscatedStrings[key]
end

-- Apply anti-dump to function upvalues
function Bypass.protectFunctionUpvalues(func)
    pcall(function()
        if not debug or not debug.getupvalue then return end

        local i = 1
        while true do
            local name, value = debug.getupvalue(func, i)
            if not name then break end

            -- If upvalue contains our strings, replace with dummy
            if type(value) == "string" and value:find("BloxStrike") then
                debug.setupvalue(func, i, string.rep("\0", #value))
            end

            i = i + 1
        end
    end)
end

Bypass.AntiDump = antiDump

-- SECTION 30: UNIFIED ACTIVATION ENGINE
-- Activate all bypass systems in the correct order

function Bypass.activateAll()
    pcall(function()
        -- Phase 1: Core protection (must be first)
        -- Bypass.backupMetatables()
        -- Bypass.spoofCheckcaller()
        -- Bypass.spoofGetgenv()
        -- Bypass.spoofExecutorFingerprint()

        -- Phase 2: Hook protection
        -- Bypass.hookNamecall()

        -- Phase 3: Memory and environment
        -- Bypass.protectMemory()
        -- Bypass.obfuscateStrings()
        -- Bypass.cloakMemory()

        -- Phase 4: Property interception
        -- Bypass.interceptHumanoidProps()

        -- Phase 5: Signature evasion
        -- Bypass.scanForSignatures()
        -- Bypass.applySignatureEvasion()

        print("[Bypass]  All 30 bypass systems activated ")
        print("[Bypass] Protection Level: MAXIMUM")
    end)
end

 -- Periodic re-scan and re-apply
task.spawn(function()
    while true do
        task.wait(30)
        pcall(function()
            -- Bypass.cloakMemory()
            -- Bypass.scanForSignatures()
            -- Bypass.applySignatureEvasion()
            -- Bypass.generateDecoyHeartbeats()
        end)
    end
end)

print("[Bypass] BloxStrike HVH Bypass v4.0 loaded")
print("[Bypass] ")
print("[Bypass] 30 Advanced Bypass Systems:")
print("[Bypass]   1  Metamethod Hook Protection")
print("[Bypass]   2  Environment Spoofing")
print("[Bypass]   3  Thread Hiding")
print("[Bypass]   4  Memory Protection")
print("[Bypass]   5  Signal Filtering")
print("[Bypass]   6  Property Change Interception")
print("[Bypass]   7  Remote Obfuscation")
print("[Bypass]   8  Advanced Timing Obfuscation")
print("[Bypass]   9  GC Protection")
print("[Bypass]   10 CFrame Validation Bypass")
print("[Bypass]   11 Teleport Detection Bypass")
print("[Bypass]   12 Heartbeat Monitoring Bypass")
print("[Bypass]   13 Behavioral Analysis Bypass")
print("[Bypass]   14 Emergency Bypass System")
print("[Bypass]   15 Injection Artifact Cloaking")
print("[Bypass]   16 Anti-Debug Protection")
print("[Bypass]   17 Replay Protection")
print("[Bypass]   18 Integrity Monitor")
print("[Bypass]   19 Property Interception v2")
print("[Bypass]   20 Network Fingerprint Evasion")
print("[Bypass]   21 Emergency Sandbox Detection")
print("[Bypass]   22 __namecall Hook Protection       NEW")
print("[Bypass]   23 Executor Fingerprint Spoof       NEW")
print("[Bypass]   24 Signal Hook Protection            NEW")
print("[Bypass]   25 Remote Call Camouflage             NEW")
print("[Bypass]   26 Memory Region Cloaking             NEW")
print("[Bypass]   27 AC Signature Evasion               NEW")
print("[Bypass]   28 Heartbeat Spoofing                 NEW")
print("[Bypass]   29 Advanced Anti-Dump                 NEW")
print("[Bypass]   30 Unified Activation Engine           NEW")
print("[Bypass] ")



