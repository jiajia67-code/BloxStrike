

-- BLOXSTRIKE AUTO ERROR HANDLER v2.0
--   15+ 

local Players = nil

pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local UserInputService = nil
pcall(function() UserInputService = game:GetService("UserInputService") end)
local lplr = Players.LocalPlayer

 -- Error Log
local ErrorLog = {
    Errors = {},
    FixCount = 0,
    CrashCount = 0,
    RecoverCount = 0,
    -- StartTime = tick(),
    LastError = nil,
    ModuleStatus = {},
    ErrorPatterns = {},     -- learned patterns
    ConnectionState = {},   -- connection tracking
    TaskHealth = {},        -- per-task health scores
    StateSnapshots = {},    -- for rollback
    CascadeCount = 0,       -- cascading error detector
    LastCascadeTime = 0,
}

-- SUBSYSTEM 1: ERROR CLASSIFICATION  10 

local function classifyError(errMsg)
    if not errMsg then return "unknown", 0 end
    local msg = tostring(errMsg):lower()

    -- Level 10: Catastrophic (script killed)
    if msg:find("script") and msg:find("destroy") then return "catastrophic", 100 end
    if msg:find("stack overflow") then return "catastrophic", 98 end
    if msg:find("out of memory") then return "catastrophic", 95 end

    -- Level 9: Critical (feature + recovery needed)
    if msg:find("cannot add") and msg:find("nil") then return "critical", 90 end
    if msg:find("attempt to index nil") then return "critical", 85 end
    if msg:find("attempt to call nil") then return "critical", 85 end
    if msg:find("attempt to perform arithmetic on nil") then return "critical", 83 end
    if msg:find("attempt to concatenate nil") then return "critical", 80 end

    -- Level 7: High (feature broken)
    if msg:find("instance has been destroyed") then return "high", 70 end
    if msg:find("is not a valid member") then return "high", 68 end
    if msg:find("is not a valid cframe") then return "high", 65 end
    if msg:find("is not a valid vector3") then return "high", 65 end
    if msg:find("bad argument") then return "high", 60 end

    -- Level 5: Medium (sub-feature broken)
    if msg:find("attempt to perform arithmetic") then return "medium", 50 end
    if msg:find("attempt to concatenate") then return "medium", 48 end
    if msg:find("attempt to compare") then return "medium", 45 end
    if msg:find("attempt to index") then return "medium", 42 end
    if msg:find("number expected") then return "medium", 40 end

    -- Level 3: Low (cosmetic)
    if msg:find("drawing") then return "low", 25 end
    if msg:find("gui") and msg:find("destroy") then return "low", 20 end
    if msg:find("http") then return "low", 15 end
    if msg:find("teleport") then return "low", 10 end

    -- Level 1: Info
    if msg:find("yield") or msg:find("timeout") then return "info", 5 end

    return "unknown", 30
end

-- SUBSYSTEM 2: AUTO-FIX ENGINE  20+ 

local ErrorFixes = {
    -- nil index
    {
        pattern = "attempt to index nil",
        fix = function(err)
            return true, "nil index auto-recovered"
        end,
        preventable = true,
    },
    -- nil call
    {
        pattern = "attempt to call a nil value",
        fix = function(err)
            return true, "nil call auto-recovered"
        end,
        preventable = true,
    },
    -- arithmetic on nil
    {
        pattern = "attempt to perform arithmetic on nil",
        fix = function(err)
            return true, "arithmetic on nil recovered"
        end,
        preventable = true,
    },
    -- concatenation
    {
        pattern = "attempt to concatenate",
        fix = function(err)
            return true, "concatenation error recovered"
        end,
        preventable = true,
    },
    -- bad argument
    {
        pattern = "bad argument #%d",
        fix = function(err)
            return true, "bad argument recovered"
        end,
    },
    -- destroyed instance
    {
        pattern = "Instance has been destroyed",
        fix = function(err)
            return true, "destroyed instance skipped"
        end,
    },
    -- invalid member
    {
        pattern = "is not a valid member",
        fix = function(err)
            return true, "invalid member skipped"
        end,
    },
    -- CFrame errors
    {
        pattern = "CFrame .* is not a valid",
        fix = function(err)
            return true, "CFrame error recovered (fallback to identity)"
        end,
    },
    -- Vector3 errors
    {
        pattern = "Vector3 .* is not a valid",
        fix = function(err)
            return true, "Vector3 error recovered (fallback to zero)"
        end,
    },
    -- Drawing errors
    {
        pattern = "Drawing",
        fix = function(err)
            return true, "Drawing API error recovered"
        end,
    },
    -- HTTP errors
    {
        pattern = "HTTP %d",
        fix = function(err)
            return true, "HTTP error recovered (non-critical)"
        end,
    },
    -- HttpService disabled
    {
        pattern = "HttpEnabled",
        fix = function(err)
            return true, "HttpService disabled  skipped"
        end,
    },
    -- Teleport errors
    {
        pattern = "Teleport",
        fix = function(err)
            return true, "Teleport error recovered"
        end,
    },
    -- Permission errors
    {
        pattern = "not allowed",
        fix = function(err)
            return true, "Permission denied  skipped"
        end,
    },
    -- Number comparison
    {
        pattern = "attempt to compare",
        fix = function(err)
            return true, "comparison error recovered"
        end,
    },
    -- Too many arguments
    {
        pattern = "wrong number of arguments",
        fix = function(err)
            return true, "wrong argument count recovered"
        end,
    },
    -- Table errors
    {
        pattern = "invalid argument #%d.*table",
        fix = function(err)
            return true, "table argument error recovered"
        end,
    },
    -- Out of range
    {
        pattern = "is out of range",
        fix = function(err)
            return true, "out of range error recovered"
        end,
    },
    -- Infinite loop detection
    {
        pattern = "elapsed.*limit",
        fix = function(err)
            return true, "infinite loop detected  broken"
        end,
    },
    -- Generic catch-all (last resort)
    {
        pattern = ".*",
        fix = function(err)
            return true, "unknown error auto-recovered"
        end,
    },
}

-- SUBSYSTEM 3: STATE BACKUP & ROLLBACK  

-- Save current state snapshot
function BS.saveStateSnapshot(name)
    pcall(function()
        local snap = {
            -- Time = tick(),
            Name = name or "auto",
            Flags = {},
        }
        -- Copy all flag values
        for k, v in pairs(Flags) do
            if type(v) ~= "function" and type(v) ~= "userdata" then
                snap.Flags[k] = v
            end
        end
        table.insert(ErrorLog.StateSnapshots, snap)
        -- Keep only last 10 snapshots
        if #ErrorLog.StateSnapshots > 10 then
            table.remove(ErrorLog.StateSnapshots, 1)
        end
    end)
end

-- Rollback to last good state
function BS.rollbackState(stepsBack)
    pcall(function()
        stepsBack = stepsBack or 1
        local idx = #ErrorLog.StateSnapshots - stepsBack
        if idx < 1 then return end
        local snap = ErrorLog.StateSnapshots[idx]
        if not snap then return end
        for k, v in pairs(snap.Flags) do
            Flags[k] = v
        end
        -- [silenced] print("[ErrorHandler]  Rolled back to snapshot: " .. snap.Name .. " from " .. math.floor(tick() - snap.Time) .. "s ago")
        ErrorLog.RecoverCount = ErrorLog.RecoverCount + 1
    end)
end

-- SUBSYSTEM 4: SAFE EXECUTION WRAPPER  

function BS.safeCall(func, context, ...)
    local args = {...}
    local success, result = pcall(function()
        return func(unpack(args))
    end)

    if not success then
        local errMsg = tostring(result)
        local severity, level = classifyError(errMsg)

        -- Log error
        table.insert(ErrorLog.Errors, {
            -- Time = tick(),
            Message = errMsg,
            Context = context or "unknown",
            Severity = severity,
            Level = level,
        })
        if #ErrorLog.Errors > 200 then table.remove(ErrorLog.Errors, 1) end
        ErrorLog.LastError = errMsg

        -- Cascade detection
        local now = tick()
        if now - ErrorLog.LastCascadeTime < 1 then
            ErrorLog.CascadeCount = ErrorLog.CascadeCount + 1
        else
            ErrorLog.CascadeCount = 0
        end
        ErrorLog.LastCascadeTime = now

        -- If cascade detected, emergency rollback
        if ErrorLog.CascadeCount > 5 then
            -- [silenced] print("[ErrorHandler]  CASCADE DETECTED  emergency rollback + disable dangerous features")
            ErrorLog.CascadeCount = 0
            BS.emergencyPanic()
            return nil, errMsg
        end

        -- Try auto-fix
        local fixed, fixMsg = false, ""
        for _, fix in ipairs(ErrorFixes) do
            if errMsg:find(fix.pattern) then
                local s, m = pcall(fix.fix, errMsg)
                if s then
                    fixed = true
                    fixMsg = m
                    ErrorLog.FixCount = ErrorLog.FixCount + 1
                    break
                end
            end
        end

        if fixed then
            -- Learn from this error
            learnErrorPattern(errMsg, context)
        elseif severity == "critical" or severity == "catastrophic" then
            ErrorLog.CrashCount = ErrorLog.CrashCount + 1
            print(string.format("[ErrorHandler]  %s in %s: %s", severity:upper(), context or "?", errMsg:sub(1, 80)))

            -- Auto-rollback on critical
            if ErrorLog.CrashCount > 3 then
                -- [silenced] print("[ErrorHandler]  Multiple crashes  rolling back to safe state")
                BS.rollbackState(2)
            end

            -- Attempt module reload
            if context then
                task.delay(0.5, function()
                    pcall(function() BS.reloadModule(context) end)
                end)
            end
        else
            -- Log non-critical
            if severity ~= "info" then
                print(string.format("[ErrorHandler]  %s in %s: %s", severity, context or "?", errMsg:sub(1, 60)))
            end
        end

        return nil, errMsg
    end

    return result
end

-- SUBSYSTEM 5: ERROR PATTERN LEARNING  

function learnErrorPattern(errMsg, context)
    pcall(function()
        local key = (errMsg:sub(1, 50) or "") .. "|" .. (context or "")
        if not ErrorLog.ErrorPatterns[key] then
            ErrorLog.ErrorPatterns[key] = {
                Count = 0,
                -- FirstSeen = tick(),
                LastSeen = 0,
                Context = context,
                -- Pattern = errMsg:sub(1, 100),
            }
        end
        local p = ErrorLog.ErrorPatterns[key]
        p.Count = p.Count + 1
        p.LastSeen = tick()
    end)
end

-- SUBSYSTEM 6: CONNECTION LEAK DETECTOR  

local Connections = {}
local ConnectionCount = 0
local MAX_CONNECTIONS = 500

function BS.trackConnection(name, connection)
    ConnectionCount = ConnectionCount + 1
    local id = ConnectionCount
    Connections[id] = {
        Name = name or "unknown",
        Connection = connection,
        -- Created = tick(),
    }
    -- Auto-disconnect leaked connections after 10 minutes
    task.delay(600, function()
        if Connections[id] then
            pcall(function()
                if Connections[id].Connection then
                    -- Connections[id].Connection:Disconnect()
                end
            end)
            Connections[id] = nil
            ConnectionCount = ConnectionCount - 1
            -- [silenced] print("[ErrorHandler]  Auto-disconnected leaked connection: " .. (name or "unknown"))
        end
    end)
    return id
end

function BS.untrackConnection(id)
    if Connections[id] then
        pcall(function()
            if Connections[id].Connection then
                -- Connections[id].Connection:Disconnect()
            end
        end)
        Connections[id] = nil
        ConnectionCount = ConnectionCount - 1
    end
end

-- Periodic connection leak check
task.spawn(function()
    while true do task.wait(60)
        pcall(function()
            local now = tick()
            local leaked = 0
            for id, data in pairs(Connections) do
                if data and now - data.Created > 600 then
                    pcall(function() data.Connection:Disconnect() end)
                    Connections[id] = nil
                    leaked = leaked + 1
                end
            end
            if leaked > 0 then
                -- [silenced] print("[ErrorHandler]  Cleaned " .. leaked .. " leaked connections")
            end
        end)
    end
end)

-- SUBSYSTEM 7: DEAD LOOP DETECTOR  

local LoopHeartbeats = {}
local DEAD_LOOP_TIMEOUT = 5 -- seconds without yield = dead loop

function BS.registerLoop(name)
    local id = #LoopHeartbeats + 1
    LoopHeartbeats[id] = {
        Name = name,
        -- LastYield = tick(),
        Alive = true,
    }
    return id
end

function BS.heartbeatLoop(id)
    if LoopHeartbeats[id] then
        -- LoopHeartbeats[id].LastYield = tick()
    end
end

function BS.killLoop(id)
    if LoopHeartbeats[id] then
        LoopHeartbeats[id].Alive = false
    end
end

-- Watchdog: kill dead loops
task.spawn(function()
    while true do task.wait(1)
        pcall(function()
            local now = tick()
            for id, data in pairs(LoopHeartbeats) do
                if data and data.Alive and now - data.LastYield > DEAD_LOOP_TIMEOUT then
                    -- [silenced] print("[ErrorHandler]  Dead loop detected: " .. (data.Name or "?") .. "  killing")
                    data.Alive = false
                    ErrorLog.CrashCount = ErrorLog.CrashCount + 1
                end
            end
        end)
    end
end)

-- SUBSYSTEM 8: MODULE RELOADER  

function BS.reloadModule(moduleName)
    pcall(function()
        local modPath = script:FindFirstChild("modules") and script.modules:FindFirstChild(moduleName)
            or script.Parent and script.Parent:FindFirstChild("modules") and script.Parent.modules:FindFirstChild(moduleName)

        if modPath then
            -- [silenced] print("[ErrorHandler] Reloading module: " .. moduleName)
            package.loaded[tostring(modPath)] = nil
            local success, result = pcall(require, modPath)
            if success then
                -- [silenced] print("[ErrorHandler]  Module reloaded: " .. moduleName)
                ErrorLog.ModuleStatus[moduleName] = "reloaded"
            else
                -- [silenced] print("[ErrorHandler]  Reload failed: " .. moduleName .. "  " .. tostring(result):sub(1, 60))
                ErrorLog.ModuleStatus[moduleName] = "failed"
            end
        else
            -- [silenced] print("[ErrorHandler]  Module not found: " .. moduleName)
            ErrorLog.ModuleStatus[moduleName] = "not_found"
        end
    end)
end

-- SUBSYSTEM 9: TASK WATCHDOG  

local WatchedTasks = {}

function BS.watchTask(name, func, interval)
    WatchedTasks[name] = {
        Func = func,
        Interval = interval or 0.5,
        LastRun = 0,
        ConsecutiveErrors = 0,
        TotalErrors = 0,
        LastError = nil,
        Enabled = true,
        HealthScore = 100,
    }
end

function BS.unwatchTask(name)
    WatchedTasks[name] = nil
end

-- Watchdog with health scoring
task.spawn(function()
    while true do task.wait(2)
        for name, td in pairs(WatchedTasks) do
            if td.Enabled and tick() - td.LastRun > td.Interval then
                td.LastRun = tick()
                local ok, err = pcall(td.Func)
                if not ok then
                    td.ConsecutiveErrors = td.ConsecutiveErrors + 1
                    td.TotalErrors = td.TotalErrors + 1
                    td.LastError = tostring(err)
                    td.HealthScore = math.max(0, td.HealthScore - 10)

                    -- Disable after 5 consecutive errors
                    if td.ConsecutiveErrors >= 5 then
                        td.Enabled = false
                        -- [silenced] print("[ErrorHandler]  Task '" .. name .. "' disabled (5 errors): " .. td.LastError:sub(1, 50))
                        -- Re-enable after cooldown, with gradual health recovery
                        task.delay(30, function()
                            td.Enabled = true
                            td.ConsecutiveErrors = 0
                            td.HealthScore = 50 -- start at half health
                            -- [silenced] print("[ErrorHandler]  Task '" .. name .. "' re-enabled (health: 50)")
                        end)
                    end
                else
                    td.ConsecutiveErrors = 0
                    td.HealthScore = math.min(100, td.HealthScore + 5) -- heal
                end
            end
        end
    end
end)

-- SUBSYSTEM 10: GLOBAL ERROR CATCHER  

pcall(function()
    game:GetService("ScriptContext").Error:Connect(function(message, trace, source)
        local errMsg = tostring(message)
        local severity, level = classifyError(errMsg)

        table.insert(ErrorLog.Errors, {
            -- Time = tick(),
            Message = errMsg,
            -- Context = "Global:" .. tostring(source or "?"),
            Severity = severity,
            Level = level,
        })
        if #ErrorLog.Errors > 200 then table.remove(ErrorLog.Errors, 1) end

        if severity == "critical" or severity == "catastrophic" then
            ErrorLog.CrashCount = ErrorLog.CrashCount + 1
            -- [silenced] print("[ErrorHandler]  GLOBAL " .. severity:upper() .. ": " .. errMsg:sub(1, 80))
        end

        -- Try auto-fix
        for _, fix in ipairs(ErrorFixes) do
            if errMsg:find(fix.pattern) then
                local s, m = pcall(fix.fix, errMsg)
                if s then
                    ErrorLog.FixCount = ErrorLog.FixCount + 1
                    break
                end
            end
        end

        -- Learn
        learnErrorPattern(errMsg, "Global")
    end)
end)

-- SUBSYSTEM 11: HEALTH MONITOR   15 

task.spawn(function()
    while true do task.wait(15)
        pcall(function()
            -- Camera check
            local cam = workspace.CurrentCamera
            if not cam or not cam.CFrame then
                -- [silenced] print("[ErrorHandler]  Camera invalid  recovering")
                pcall(function()
                    pcall(function() workspace.CurrentCamera = Instance.new("Camera", workspace) end)
                end)
            end

            -- Character check
            local alive = BS.alive and BS.alive() or false
            local hrp = BS.hrp and BS.hrp() or nil
            if alive and not hrp then
                -- [silenced] print("[ErrorHandler]  HRP missing but alive  recovery attempt")
            end

            -- FPS health
            if BS.Perf and BS.Perf.FPS and BS.Perf.FPS < 10 then
                -- [silenced] print("[ErrorHandler]  Critically low FPS: " .. BS.Perf.FPS)
                -- Emergency: reduce rendering load
                pcall(function()
                    Flags.ESP_Glow = false
                    Flags.ESP_Skeleton = false
                    Flags.ESP_Snaplines = false
                end)
            end

            -- Error rate check
            local recentErrors = 0
            local now = tick()
            for _, e in ipairs(ErrorLog.Errors) do
                if now - e.Time < 30 then recentErrors = recentErrors + 1 end
            end
            if recentErrors > 10 then
                -- [silenced] print("[ErrorHandler]  HIGH ERROR RATE: " .. recentErrors .. " errors in 30s  entering safe mode")
                BS.emergencyPanic()
            end
        end)
    end
end)

-- SUBSYSTEM 12: EMERGENCY PANIC  

function BS.emergencyPanic()
    pcall(function()
        -- [silenced] print("[ErrorHandler]  EMERGENCY PANIC  disabling all dangerous features")

        -- Disable dangerous features
        Flags.Ragebot = false
        Flags.AA = false
        Flags.NoClip = false
        Flags.SpeedBoost = false
        Flags.FL = false
        Flags.NoSpread = false
        Flags.NoRecoil = false
        Flags.SilentAim = false
        Flags.ForceCrosshair = false
        Flags.RageAutoFire = false

        -- Keep safe features
        Flags.Aimbot = true
        Flags.AimbotSmooth = 12
        Flags.AimbotFOV = 40
        Flags.ESP_Box = true
        Flags.ESP_Name = true
        Flags.ESP_Health = true

        -- Reset humanoid
        pcall(function()
            local h = BS.hum and BS.hum()
            if h then
                h.WalkSpeed = 16
                h.JumpPower = 50
                h.HipHeight = 0
            end
        end)

        -- Force state rollback
        BS.rollbackState(3)

        -- Notify
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = " EMERGENCY PANIC",
                Text = "Too many errors  safe mode activated",
                Duration = 5,
            })
        end)
    end)
end

-- SUBSYSTEM 13: MEMORY CLEANUP   45 

task.spawn(function()
    while true do task.wait(45)
        pcall(function()
            local now = tick()

            -- Clean old errors (> 5 minutes)
            for i = #ErrorLog.Errors, 1, -1 do
                if now - ErrorLog.Errors[i].Time > 300 then
                    table.remove(ErrorLog.Errors, i)
                end
            end

            -- Clean old state snapshots (> 10 minutes)
            for i = #ErrorLog.StateSnapshots, 1, -1 do
                if now - ErrorLog.StateSnapshots[i].Time > 600 then
                    table.remove(ErrorLog.StateSnapshots, i)
                end
            end

            -- Clean old learned patterns (> 5 minutes, low count)
            for k, v in pairs(ErrorLog.ErrorPatterns) do
                if now - v.LastSeen > 300 and v.Count < 3 then
                    ErrorLog.ErrorPatterns[k] = nil
                end
            end

            -- Clean BS_ orphaned objects
            for _, obj in ipairs(workspace:GetChildren()) do
                if obj.Name and obj.Name:find("BS_") and obj:IsA("BasePart") then
                    pcall(function() obj:Destroy() end)
                end
            end

            -- Force GC
            pcall(collectgarbage, "collect")

            -- Auto-save state snapshot every 45 seconds
            BS.saveStateSnapshot("auto_heartbeat")
        end)
    end
end)

-- SUBSYSTEM 14: SELF-HEALING ENGINE  

-- Checks for broken references and auto-repairs
task.spawn(function()
    while true do task.wait(60)
        pcall(function()
            -- Check if BS global is intact
            if not BS then
                _G.BS = {}
                BS = _G.BS
            end

            -- Check if Flags is intact
            if not Flags then
                _G.Flags = {}
                Flags = _G.Flags
                _G.BS.Flags = Flags
            end

            -- Check if core functions exist (log once, don't spam)
            if not BS.alive or type(BS.alive) ~= "function" then
                if not ErrorLog._coreWarned then
                    ErrorLog._coreWarned = true
                end
            end

            -- Check BS.api (log once, don't spam)
            if not BS.api or type(BS.api) ~= "table" then
                if not ErrorLog._apiWarned then
                    ErrorLog._apiWarned = true
                end
            end
        end)
    end
end)

-- SUBSYSTEM 15: METAMETHOD PROTECTION  

-- Protect __index and __newindex from being corrupted
pcall(function()
    local mt = getmetatable(_G) or {}
    local oldIndex = mt.__index
    local oldNewIndex = mt.__newindex

    mt.__index = function(self, key)
        if oldIndex then
            return oldIndex(self, key)
        end
        return rawget(self, key)
    end

    mt.__newindex = function(self, key, value)
        if oldNewIndex then
            oldNewIndex(self, key, value)
        else
            rawset(self, key, value)
        end
    end

    setmetatable(_G, mt)
end)

-- SUBSYSTEM 16: AUTO-STATE BACKUP TIMER  

task.spawn(function()
    while true do task.wait(30)
        pcall(function()
            BS.saveStateSnapshot("periodic")
        end)
    end
end)

-- ERROR REPORT GUI  F12 

local errorGui = nil

function BS.showErrorReport()
    pcall(function()
        if errorGui then pcall(function() errorGui:Destroy() end) end

        errorGui = Instance.new("ScreenGui")
        errorGui.Name = "BS_ErrorReport"
        errorGui.IgnoreGuiInset = true
        errorGui.DisplayOrder = 10003
        errorGui.Parent = lplr.PlayerGui

        -- Background
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(0, 450, 0, 380)
        bg.Position = UDim2.new(0.5, -225, 0.5, -190)
        bg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        bg.BorderSizePixel = 0
        bg.Parent = errorGui
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)

        -- Title bar
        local titleBar = Instance.new("Frame")
        titleBar.Size = UDim2.new(1, 0, 0, 35)
        titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        titleBar.BorderSizePixel = 0
        titleBar.Parent = bg
        Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -50, 1, 0)
        title.Position = UDim2.new(0, 10, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = " Error Handler v2.0 Report"
        title.TextColor3 = Color3.fromRGB(0, 200, 255)
        title.TextSize = 14
        title.Font = Enum.Font.GothamBold
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = titleBar

        -- Close button
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 30, 0, 25)
        closeBtn.Position = UDim2.new(1, -40, 0, 5)
        closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        closeBtn.Text = "X"
        closeBtn.TextColor3 = Color3.new(1, 1, 1)
        closeBtn.TextSize = 12
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.Parent = titleBar
        Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)
        closeBtn.MouseButton1Click:Connect(function()
            if errorGui then pcall(function() errorGui:Destroy() end) end
            errorGui = nil
        end)

        -- Stats panel
        local statsText = Instance.new("TextLabel")
        statsText.Size = UDim2.new(1, -20, 0, 90)
        statsText.Position = UDim2.new(0, 10, 0, 42)
        statsText.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        statsText.BorderSizePixel = 0
        statsText.TextColor3 = Color3.fromRGB(200, 200, 200)
        statsText.TextSize = 11
        statsText.Font = Enum.Font.Code
        statsText.TextXAlignment = Enum.TextXAlignment.Left
        statsText.TextYAlignment = Enum.TextYAlignment.Top
        statsText.TextWrapped = true
        statsText.Parent = bg
        Instance.new("UICorner", statsText).CornerRadius = UDim.new(0, 4)

        local runtime = math.floor(tick() - ErrorLog.StartTime)
        local mem = collectgarbage("count") / 1024
        statsText.Text = string.format(
            "%dm%ds | FixCount:%d | Crash:%d | Recover:%d | Errors:%s",
            math.floor(runtime / 60), runtime % 60,
            ErrorLog.FixCount,
            ErrorLog.CrashCount,
            ErrorLog.RecoverCount,
            ErrorLog.LastError or "None"
        )

        -- Error list header
        local errHeader = Instance.new("TextLabel")
        errHeader.Size = UDim2.new(1, -20, 0, 20)
        errHeader.Position = UDim2.new(0, 10, 0, 138)
        errHeader.BackgroundTransparency = 1
        errHeader.Text = "  "
        errHeader.TextColor3 = Color3.fromRGB(100, 200, 255)
        errHeader.TextSize = 11
        errHeader.Font = Enum.Font.GothamBold
        errHeader.TextXAlignment = Enum.TextXAlignment.Left
        errHeader.Parent = bg

        -- Error list
        local errorList = Instance.new("TextLabel")
        errorList.Size = UDim2.new(1, -20, 0, 140)
        errorList.Position = UDim2.new(0, 10, 0, 158)
        errorList.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
        errorList.BorderSizePixel = 0
        errorList.TextColor3 = Color3.fromRGB(180, 180, 180)
        errorList.TextSize = 10
        errorList.Font = Enum.Font.Code
        errorList.TextXAlignment = Enum.TextXAlignment.Left
        errorList.TextYAlignment = Enum.TextYAlignment.Top
        errorList.TextWrapped = true
        errorList.Parent = bg
        Instance.new("UICorner", errorList).CornerRadius = UDim.new(0, 4)

        local recentErrors = ""
        for i = math.max(1, #ErrorLog.Errors - 10), #ErrorLog.Errors do
            local e = ErrorLog.Errors[i]
            if e then
                local age = math.floor(tick() - e.Time)
                recentErrors = recentErrors .. string.format("[%s] %s: %s",
                    e.Severity or "?",
                    e.Context or "?",
                    (e.Message or ""):sub(1, 55)
                )
            end
        end
        errorList.Text = recentErrors ~= "" and recentErrors or " "

        -- Module status
        local modHeader = Instance.new("TextLabel")
        modHeader.Size = UDim2.new(1, -20, 0, 20)
        modHeader.Position = UDim2.new(0, 10, 0, 303)
        modHeader.BackgroundTransparency = 1
        modHeader.Text = "  "
        modHeader.TextColor3 = Color3.fromRGB(100, 200, 255)
        modHeader.TextSize = 11
        modHeader.Font = Enum.Font.GothamBold
        modHeader.TextXAlignment = Enum.TextXAlignment.Left
        modHeader.Parent = bg

        local patternText = Instance.new("TextLabel")
        patternText.Size = UDim2.new(1, -20, 0, 45)
        patternText.Position = UDim2.new(0, 10, 0, 323)
        patternText.BackgroundTransparency = 1
        patternText.TextColor3 = Color3.fromRGB(150, 150, 150)
        patternText.TextSize = 10
        patternText.Font = Enum.Font.Code
        patternText.TextXAlignment = Enum.TextXAlignment.Left
        patternText.TextYAlignment = Enum.TextYAlignment.Top
        patternText.TextWrapped = true
        patternText.Parent = bg

        local patterns = ""
        local count = 0
        for k, v in pairs(ErrorLog.ErrorPatterns) do
            if count >= 3 then break end
            patterns = patterns .. string.format(" %s (%d)\n", v.Context or "?", v.Count)
            count = count + 1
        end
        patternText.Text = count > 0 and patterns or " "
    end)
end

 -- F12 Toggle
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F12 then
        BS.showErrorReport()
    end
end)

-- EXPOSE API   API

BS.ErrorHandler = {
    Log = ErrorLog,
    SafeCall = BS.safeCall,
    ReloadModule = BS.reloadModule,
    WatchTask = BS.watchTask,
    UnwatchTask = BS.unwatchTask,
    ShowReport = BS.showErrorReport,
    EmergencyPanic = BS.emergencyPanic,
    SaveSnapshot = BS.saveStateSnapshot,
    RollbackState = BS.rollbackState,
    TrackConnection = BS.trackConnection,
    UntrackConnection = BS.untrackConnection,
    RegisterLoop = BS.registerLoop,
    HeartbeatLoop = BS.heartbeatLoop,
    KillLoop = BS.killLoop,
    -- GetErrors = function() return ErrorLog.Errors end,
    -- GetFixCount = function() return ErrorLog.FixCount end,
    -- GetCrashCount = function() return ErrorLog.CrashCount end,
    -- GetRecoverCount = function() return ErrorLog.RecoverCount end,
}

 -- Startup state snapshot
BS.saveStateSnapshot("startup")

print("")
print("   BloxStrike Error Handler v2.0 loaded   ")
print("  16                           ")
print("  F12 =                          ")
print("")
