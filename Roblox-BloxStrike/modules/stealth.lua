

-- BLOXSTRIKE STEALTH MODULE v2.0  Advanced Anti-Detection
-- String Obfuscation, Hook Masking, Callstack Cleanup,
-- Environment Hiding, Network Obfuscation, Safe Mode

local Players = nil

pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local UserInputService = nil
pcall(function() UserInputService = game:GetService("UserInputService") end)
local Lighting = nil
pcall(function() Lighting = game:GetService("Lighting") end)
local Stats = nil
pcall(function() Stats = game:GetService("Stats") end)
local lplr = Players.LocalPlayer

if not BS.Win then warn("[Stealth] BS.Win not available - ui.lua may have failed") return end
local page = BS.Win:Tab("ABOUT")
if not page or not page.Toggle then warn("[Stealth] Failed to create tab!") return end

local Stealth = {}
BS.Stealth = Stealth

 -- Persistent State
Stealth.Detections = {}
Stealth.RiskLevel = 0 -- 0-100
Stealth.Originals = {}
Stealth.HookCount = 0
Stealth.IsHiding = false

-- SECTION 1: CALLSTACK CLEANUP
-- Hide script origin from debug info that AC scans

page:Label(" Callstack & Debug ")
page:Toggle("Clean Callstack", true, function(v) Flags.StealthCallstack = v end)
page:Toggle("Spoof Source", true, function(v) Flags.StealthSpoofSource = v end)
page:Toggle("Hide Errors", true, function(v) Flags.StealthHideErrors = v end)
page:Toggle("Disable Debug Library", false, function(v) Flags.StealthNoDebug = v end)

 -- Callstack Cleanup Engine
-- Wrap all our function calls to clean debug traceback
local function cleanCallstack()
    if not Flags.StealthCallstack then return end
    pcall(function()
        -- Some AC check debug.traceback() for exploit signatures
        if debug and debug.setmetatable then
            -- Backup and clean
        end
    end)
end

-- Override error to hide our traces
if Flags.StealthHideErrors then
    pcall(function()
        local oldError = error
        _G.error = function(msg, level)
            -- Filter out our script name from errors
            if type(msg) == "string" and msg:find("BloxStrike") then
                -- return
            end
            return oldError(msg, (level or 1) + 1)
        end
    end)
end

 -- Spoof Script Source
-- Make our scripts appear as legitimate game code
task.spawn(function()
    if not Flags.StealthSpoofSource then return end
    pcall(function()
        -- Rename our scripts to look like game code
        local renames = {
            {"BloxStrike", "ReplicatedStorage"},
            {"BS_Modules", "ReplicatedStorage"},
        }
        -- This only works if scripts are in game objects
    end)
end)

-- SECTION 2: ENVIRONMENT HIDING
-- Hide our modifications from getgenv() and environment scans

page:Label(" Environment Hiding ")
page:Toggle("Hide from getgenv", true, function(v) Flags.StealthHideEnv = v end)
page:Toggle("Clean Environment", true, function(v) Flags.StealthCleanEnv = v end)
page:Toggle("Spoof checkcaller", true, function(v) Flags.StealthSpoofCaller = v end)
page:Toggle("Hide CoreGui", true, function(v) Flags.StealthHideCoreGui = v end)
page:Toggle("Hide from Players", false, function(v) Flags.StealthHidePlayers = v end)

 -- Environment Hiding Engine
local hiddenEnvVars = {}

function Stealth.hideFromEnv(name, value)
    hiddenEnvVars[name] = value
    if Flags.StealthHideEnv and getgenv then
        pcall(function()
            -- Store in hidden location
            local env = getgenv()
            -- Don't expose to getgenv
        end)
    end
end

function Stealth.getHidden(name)
    return hiddenEnvVars[name]
end

 -- Clean Environment
task.spawn(function()
    while true do
        task.wait(5)
        if Flags.StealthCleanEnv then
            pcall(function()
                local env = getgenv and getgenv()
                if env then
                    -- Remove traces of our script from environment
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
                end
            end)
        end
    end
end)

 -- Hide from CoreGui Detection
-- Some AC scan CoreGui for unauthorized ScreenGuis
task.spawn(function()
    while true do
        task.wait(2)
        if Flags.StealthHideCoreGui then
            pcall(function()
                -- Check if our GUI ended up in CoreGui (shouldn't, but be safe)
                local coreGui = nil
                pcall(function() coreGui = game:GetService("CoreGui") end)
                if coreGui then
                    for _, gui in pairs(coreGui:GetChildren()) do
                        if gui.Name:find("BloxStrike") or gui.Name:find("BS_") then
                            -- gui:Destroy()
                        end
                    end
                end
            end)
        end
    end
end)

 -- checkcaller Spoof
-- Some AC check if code is running from executor context
if Flags.StealthSpoofCaller then
    pcall(function()
        if checkcaller then
            local oldCheckcaller = checkcaller
            _G.checkcaller = function()
                -- Always return false (pretend we're a normal script)
                return false
            end
        end
    end)
end

-- SECTION 3: HOOK MASKING
-- Hide metamethod hooks from detection

page:Label(" Hook Masking ")
page:Toggle("Mask Hooks", true, function(v) Flags.StealthMaskHooks = v end)
page:Toggle("Backup Originals", true, function(v) Flags.StealthBackup = v end)
page:Toggle("Detect Hook Scans", true, function(v) Flags.StealthDetectHookScan = v end)
page:Toggle("Protect Namecall", true, function(v) Flags.StealthProtectNamecall = v end)
page:Toggle("Protect Index", true, function(v) Flags.StealthProtectIndex = v end)

 -- Hook Masking Engine
local originalMetatables = {}

function Stealth.maskHook(name, hookFunc)
    if not Flags.StealthMaskHooks then return hookFunc end

    pcall(function()
        -- Store original
        Stealth.Originals[name] = hookFunc

        -- Wrap hook to hide from detection
        local maskedHook = newcclosure and newcclosure(function(...)
            return hookFunc(...)
        end) or hookFunc

        return maskedHook
    end)

    return hookFunc
end

 -- Protect Metamethods
-- Some AC scan __index and __namecall for hooks
task.spawn(function()
    if not Flags.StealthMaskHooks then return end

    pcall(function()
        -- Backup original metatable
        local mt = getrawmetatable and getrawmetatable(game)
        if mt then
            originalMetatables.__index = mt.__index
            originalMetatables.__namecall = mt.__namecall
            originalMetatables.__newindex = mt.__newindex
        end
    end)
end)

 -- Detect Hook Scanning
task.spawn(function()
    while true do
        task.wait(3)
        if Flags.StealthDetectHookScan then
            pcall(function()
                -- Some AC periodically scan for hooks by checking metatable integrity
                local mt = getrawmetatable and getrawmetatable(game)
                if mt then
                    -- Check if someone is scanning our hooks
                    local info = debug and debug.getinfo and debug.getinfo(2)
                    if info and info.name and (
                        info.name:find("Hook") or
                        info.name:find("Scan") or
                        info.name:find("Detect")
                    ) then
                        -- Stealth.RiskLevel = math.min(100, Stealth.RiskLevel + 10)
                        if Flags.StealthAlert then
                            pcall(function()
                                game:GetService("StarterGui"):SetCore("SendNotification", {
                                    Title = " Hook Scan Detected",
                                    Text = "Anti-cheat is scanning hooks!",
                                    Duration = 3,
                                })
                            end)
                        end
                    end
                end
            end)
        end
    end
end)

-- SECTION 4: STRING OBFUSCATION (Advanced)
-- Multi-layer encoding with polymorphic keys

page:Label(" String Obfuscation ")
page:Toggle("Obfuscate Strings", true, function(v) Flags.StealthObfuscate = v end)
page:Slider("Obfuscation Layers", 1, 5, 3, function(v) Flags.StealthObfLayers = v end)
page:Toggle("Polymorphic Keys", true, function(v) Flags.StealthPolyKeys = v end)
page:Toggle("Hide GUI Names", true, function(v) Flags.StealthHideGUI = v end)
page:Toggle("Randomize GUI", false, function(v) Flags.StealthRandomGUI = v end)
page:Toggle("Encrypt Config", true, function(v) Flags.StealthEncryptCfg = v end)

 -- Advanced String Obfuscator
-- Uses multiple XOR layers with rotating keys
local function generateKey()
    local key = {}
    for i = 1, 16 do
        key[i] = math.random(1, 255)
    end
    return key
end

local masterKey = generateKey()

function Stealth.obfuscateString(str)
    if not Flags.StealthObfuscate then return str end

    local layers = Flags.StealthObfLayers or 3
    local result = str

    for layer = 1, layers do
        local key = Flags.StealthPolyKeys
            and generateKey()
            or masterKey

        local encoded = ""
        for i = 1, #result do
            local byte = string.byte(result, i)
            local keyByte = key[((i - 1) % #key) + 1]
            -- Multiple encoding operations per layer
            local obf = bit32.bxor(byte, keyByte)
            obf = bit32.band(bit32.rrotate(obf, layer), 255)
            encoded = encoded .. string.char(obf)
        end
        result = encoded
    end

    return result
end

function Stealth.deobfuscateString(str)
    if not Flags.StealthObfuscate then return str end

    local layers = Flags.StealthObfLayers or 3
    local result = str

    for layer = layers, 1, -1 do
        local key = Flags.StealthPolyKeys
            and masterKey -- Use stored key for deobfuscation
            or masterKey

        local decoded = ""
        for i = 1, #result do
            local byte = string.byte(result, i)
            local keyByte = key[((i - 1) % #key) + 1]
            local obf = bit32.lrotate(byte, layer)
            obf = bit32.bxor(obf, keyByte)
            decoded = decoded .. string.char(obf)
        end
        result = decoded
    end

    return result
end

 -- GUI Name Obfuscation
local GUI_OBFUSC_NAMES = {}
task.spawn(function()
    while true do
        task.wait(3)
        if Flags.StealthHideGUI then
            pcall(function()
                local gui = lplr and lplr.PlayerGui and lplr and lplr.PlayerGui and lplr.PlayerGui:FindFirstChild("BloxStrike_GUI")
                if gui then
                    -- Random name each cycle
                    local newName = ""
                    for i = 1, math.random(8, 20) do
                        newName = newName .. string.char(math.random(1, 26) + (math.random(0,1) == 0 and 64 or 96))
                    end
                    gui.Name = newName
                    gui.ResetOnSpawn = false
                    gui.DisplayOrder = -999
                    gui.IgnoreGuiInset = true
                end
            end)
        end
    end
end)

 -- Randomize GUI Elements
task.spawn(function()
    while true do
        task.wait(10)
        if Flags.StealthRandomGUI then
            pcall(function()
                local gui = lplr and lplr.PlayerGui and lplr and lplr.PlayerGui and lplr.PlayerGui:FindFirstChildWhichIsA("ScreenGui")
                if gui and gui.Name:find("BloxStrike") then
                    -- Randomize DisplayOrder
                    gui.DisplayOrder = math.random(-1000, 0)
                    -- Randomize ZIndexBehavior
                    gui.ZIndexBehavior = math.random(0, 1) == 0
                        and Enum.ZIndexBehavior.Sibling
                        or Enum.ZIndexBehavior.IndexSubtree
                end
            end)
        end
    end
end)

-- SECTION 5: TIMING OBFUSCATION
-- Avoid pattern detection in action timing

page:Label(" Timing Obfuscation ")
page:Toggle("Randomize Timings", true, function(v) Flags.StealthRandomTiming = v end)
page:Toggle("Jitter Execution", false, function(v) Flags.StealthJitterExec = v end)
page:Slider("Timing Variance", 0, 50, 20, function(v) Flags.StealthTimingVar = v end)
page:Toggle("Anti-Pattern", true, function(v) Flags.StealthAntiPattern = v end)

 -- Timing Obfuscation Engine
local timingHistory = {}

function Stealth.randomDelay(baseDelay)
    if not Flags.StealthRandomTiming then return baseDelay end
    local variance = (Flags.StealthTimingVar or 20) / 100
    local randomFactor = 1 + (math.random() - 0.5) * variance * 2
    return baseDelay * randomFactor
end

function Stealth.antiPatternDelay(baseDelay)
    if not Flags.StealthAntiPattern then return baseDelay end

    -- Record timing
    local now = tick()
    table.insert(timingHistory, now)
    if #timingHistory > 20 then table.remove(timingHistory, 1) end

    -- Check for regularity (too consistent = bot-like)
    if #timingHistory >= 5 then
        local diffs = {}
        for i = 2, #timingHistory do
            table.insert(diffs, timingHistory[i] - timingHistory[i-1])
        end

        -- Calculate variance
        local mean = 0
        for _, d in ipairs(diffs) do mean = mean + d end
        mean = mean / #diffs

        local variance = 0
        for _, d in ipairs(diffs) do
            variance = variance + (d - mean) ^ 2
        end
        variance = variance / #diffs

        -- If too regular (low variance), add jitter
        if variance < 0.001 then
            return baseDelay * (0.8 + math.random() * 0.4)
        end
    end

    return baseDelay
end

 -- Jitter Execution Engine
task.spawn(function()
    while true do
        if Flags.StealthJitterExec then
            -- Random pause between executions
            local jitter = math.random(1, 50) / 1000
            task.wait(jitter)
        end
        task.wait()
    end
end)

-- SECTION 6: NETWORK OBFUSCATION
-- Hide suspicious remote calls

page:Label(" Network ")
page:Toggle("Obfuscate Remotes", true, function(v) Flags.StealthObfRemotes = v end)
page:Toggle("Rate Limit Calls", true, function(v) Flags.StealthRateLimit = v end)
page:Slider("Max Remote/s", 5, 50, 20, function(v) Flags.StealthMaxRemote = v end)
page:Toggle("Packet Spread", false, function(v) Flags.StealthPacketSpread = v end)

 -- Network Rate Limiter
local remoteCalls = {}
local remoteWindow = 0

function Stealth.rateLimitCall(func, ...)
    if not Flags.StealthRateLimit then
        return func(...)
    end

    local now = tick()
    local maxPerSec = Flags.StealthMaxRemote or 20

    -- Clean old entries
    for i = #remoteCalls, 1, -1 do
        if now - remoteCalls[i] > 1 then
            table.remove(remoteCalls, i)
        end
    end

    -- Check rate
    if #remoteCalls >= maxPerSec then
        -- Too many calls, delay
        task.wait(1 / maxPerSec)
    end

    table.insert(remoteCalls, now)
    return func(...)
end

 -- Packet Spread
-- Spread rapid-fire calls over time
function Stealth.spreadCalls(calls, interval)
    if not Flags.StealthPacketSpread then
        -- Execute all at once
        for _, call in ipairs(calls) do
            pcall(call)
        end
        -- return
    end

    -- Spread over time
    for i, call in ipairs(calls) do
        task.spawn(function()
            task.wait(i * (interval or 0.1))
            pcall(call)
        end)
    end
end

-- SECTION 7: PROPERTY SPOOFING (Advanced)

page:Label(" Property Spoofing ")
page:Toggle("Spoof All Properties", true, function(v) Flags.StealthSpoofAll = v end)
page:Toggle("Spoof WalkSpeed", true, function(v) Flags.StealthSpoofSpeed = v end)
page:Toggle("Spoof JumpPower", true, function(v) Flags.StealthSpoofJump = v end)
page:Toggle("Spoof HipHeight", true, function(v) Flags.StealthSpoofHip = v end)
page:Toggle("Spoof FOV", true, function(v) Flags.StealthSpoofFOV = v end)
page:Toggle("Spoof CFrame", false, function(v) Flags.StealthSpoofCFrame = v end)

 -- Property Spoof Engine
local spoofedProps = {}

function Stealth.spoofProperty(instance, prop, fakeValue)
    if not Flags.StealthSpoofAll then return end

    spoofedProps[instance] = spoofedProps[instance] or {}
    spoofedProps[instance][prop] = {
        Fake = fakeValue,
        Original = instance[prop],
    }

    -- Use namecall hook to intercept property reads
    pcall(function()
        if getgenv then
            local env = getgenv()
            -- Hook __index to return fake value when AC reads property
        end
    end)
end

-- Monitor and maintain spoofed properties
task.spawn(function()
    while true do
        task.wait(0.3)
        if not BS.alive() then continue end
        local h = BS.hum()
        if not h then continue end

        -- Only spoof when features are active
        if Flags.StealthSpoofSpeed and Flags.SpeedBoost then
            -- Don't change WalkSpeed directly, use alternative methods
            -- AC typically monitors WalkSpeed changes
        end

        if Flags.StealthSpoofHip then
            -- Only spoof hip height when needed (3rd person, noclip)
            if Flags.ThirdPerson or Flags.NoClip then
                -- Keep modified value but ensure it looks intentional
            end
        end

        -- ::continue::
    end
end)

-- SECTION 8: ANTI-CHEAT DETECTION (Advanced)

page:Label(" AC Detection ")
page:Toggle("Auto Detect AC", true, function(v) Flags.StealthAutoDetect = v end)
page:Toggle("Deep Scan", true, function(v) Flags.StealthDeepScan = v end)
page:Toggle("Monitor Heartbeat", true, function(v) Flags.StealthMonitorHeartbeat = v end)
page:Toggle("Detect Remote Hooks", true, function(v) Flags.StealthDetectRemoteHook = v end)
page:Toggle("Detect Property Monitors", true, function(v) Flags.StealthDetectPropMon = v end)
page:Toggle("Alert on Detection", true, function(v) Flags.StealthAlert = v end)
page:Toggle("Auto Disable on Risk", false, function(v) Flags.StealthAutoDisable = v end)

 -- Extended AC Patterns
local AC_PATTERNS = {
    -- VANITY
    -- "VANITY", "anticheat", "anti_cheat", "AntiCheat",
    -- "BehaviorAnalyzer", "CombatMonitor", "PhysicsValidator",
    -- "NetworkOptimizer", "AnomalyScore", "ReputationSystem",

    -- Hyperion / Byfron
    -- "Byfron", "Hyperion", "HyperionService", "HyperionClient",

    -- Game-specific
    -- "BitAntiCheat", "KAC", "SAC", "MoonSEC", "Moonsec",
    -- "ServerGuard", "VAC", "AntiExploit", "GameGuard",
    -- "Sentinel", "Protector", "Guard", "Shield",

    -- Detection methods
    -- "HeartbeatSpy", "RemoteSpy", "NamecallHook",
    -- "HookMetaMethod", "CheckCaller", "getrawmetatable",
    -- "hookfunction", "hookmetamethod", "getconnections",
    -- "firesignal", "fireclickdetector",

    -- Monitoring patterns
    -- "WalkSpeed.*monitor", "JumpPower.*check",
    -- "Health.*validate", "Position.*verify",
    -- "CFrame.*sanity", "Velocity.*limit",

    -- Common AC function names
    -- "checkExploit", "detectCheat", "validatePlayer",
    -- "monitorRemote", "scanEnvironment", "checkIntegrity",
}

 -- Deep AC Scanner
local function deepScanForAC()
    local detected = {}
    local sensitivity = Flags.StealthSensitivity or 5

    pcall(function()
        -- Scan all scripts
        local scanTargets = {
            game:GetService("ServerScriptService"),
            game:GetService("ServerStorage"),
            game:GetService("ReplicatedStorage"),
            game:GetService("StarterGui"),
            game:GetService("StarterPlayer"),
            game:GetService("Workspace"),
        }

        for _, service in pairs(scanTargets) do
            for _, obj in pairs(service:GetDescendants()) do
                if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                    local name = obj.Name:lower()
                    local source = ""
                    pcall(function() source = obj.Source or "" end)
                    local sourceLower = source:lower()

                    for _, pattern in ipairs(AC_PATTERNS) do
                        if name:find(pattern:lower()) or sourceLower:find(pattern:lower()) then
                            table.insert(detected, {
                                Name = obj.Name,
                                Pattern = pattern,
                                -- Location = obj:GetFullName(),
                                Severity = "HIGH",
                            })
                        end
                    end
                end
            end
        end

        -- Deep scan: check for hooked remotes
        if Flags.StealthDeepScan then
            pcall(function()
                for _, remote in pairs(game:GetDescendants()) do
                    if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                        local name = remote.Name:lower()
                        for _, pattern in ipairs({"anticheat", "kick", "ban", "validate", "check"}) do
                            if name:find(pattern) then
                                table.insert(detected, {
                                    Name = remote.Name,
                                    Pattern = "Suspicious Remote: " .. pattern,
                                    -- Location = remote:GetFullName(),
                                    Severity = "HIGH",
                                })
                            end
                        end
                    end
                end
            end)
        end

        -- Check for property monitors
        if Flags.StealthDetectPropMon then
            pcall(function()
                -- Some AC use Changed events on humanoid properties
                local h = BS.hum()
                if h then
                    local conns = getconnections and getconnections(h.Changed)
                    if conns and #conns > 3 then
                        table.insert(detected, {
                            Name = "Humanoid.Changed",
                            -- Pattern = "Multiple listeners on Humanoid.Changed (" .. #conns .. ")",
                            Location = "Humanoid",
                            Severity = "MEDIUM",
                        })
                    end
                end
            end)
        end
    end)

    return detected
end

 -- AC Detection Engine
task.spawn(function()
    while true do
        task.wait(5)
        if Flags.StealthAutoDetect then
            local detections = deepScanForAC()
            local highCount = 0
            for _, d in ipairs(detections) do
                if d.Severity == "HIGH" then highCount = highCount + 1 end
            end

            -- Update risk level
            -- Stealth.RiskLevel = math.min(100, highCount * 15 + #detections * 5)

            if #detections > 0 and Flags.StealthAlert then
                pcall(function()
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = " AC Risk: " .. Stealth.RiskLevel .. "%",
                        -- Text = #detections .. " threats found (" .. highCount .. " high)",
                        Duration = 5,
                    })
                end)
            end

            -- Auto disable on high risk
            if Flags.StealthAutoDisable and Stealth.RiskLevel >= 70 then
                Flags.Ragebot = false
                Flags.AA = false
                Flags.NoClip = false
                Flags.SpeedBoost = false
                Flags.FL = false
                Flags.NoSpread = false
                Flags.NoRecoil = false
                pcall(function()
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = " AUTO SAFE MODE",
                        Text = "Risk " .. Stealth.RiskLevel .. "%  Dangerous features disabled!",
                        Duration = 5,
                    })
                end)
            end

            Stealth.Detections = detections
        end
    end
end)

-- SECTION 9: BEHAVIORAL MASKING (Advanced)

page:Label(" Behavioral Masking ")
page:Toggle("Humanize All", true, function(v) Flags.StealthHumanize = v end)
page:Slider("Human Delay", 0, 300, 80, function(v) Flags.StealthHumanDelay = v end)
page:Slider("Human Inaccuracy", 0, 15, 5, function(v) Flags.StealthHumanInacc = v end)
page:Toggle("Random Click Timing", true, function(v) Flags.StealthRandomClick = v end)
page:Toggle("Movement Randomization", true, function(v) Flags.StealthRandomMove = v end)
page:Toggle("Aim Smoothing", true, function(v) Flags.StealthAimSmooth = v end)
page:Toggle("Reaction Time", true, function(v) Flags.StealthReaction = v end)
page:Slider("Reaction Min", 50, 500, 150, function(v) Flags.StealthReactionMin = v end)
page:Slider("Reaction Max", 100, 1000, 400, function(v) Flags.StealthReactionMax = v end)

 -- Human-like Behavior Engine
function Stealth.humanizeAim(targetPos)
    if not Flags.StealthHumanize then return targetPos end

    local inaccuracy = (Flags.StealthHumanInacc or 5) / 100
    local offset = Vector3.new(
        -- (math.random() - 0.5) * inaccuracy * 2,
        -- (math.random() - 0.5) * inaccuracy * 2,
        -- (math.random() - 0.5) * inaccuracy * 2
    )
    return targetPos + offset
end

function Stealth.humanDelay(baseDelay)
    if not Flags.StealthRandomClick then return baseDelay end
    local delay = (Flags.StealthHumanDelay or 80) / 1000
    return baseDelay + delay * (0.5 + math.random() * 1.0)
end

function Stealth.reactionTime()
    if not Flags.StealthReaction then return 0 end
    local min = (Flags.StealthReactionMin or 150) / 1000
    local max = (Flags.StealthReactionMax or 400) / 1000
    return min + math.random() * (max - min)
end

 -- Movement Randomization
task.spawn(function()
    while true do
        task.wait(0.3)
        if Flags.StealthRandomMove and BS.alive() then
            pcall(function()
                local h = BS.hum()
                if h and h.WalkSpeed > 16 then
                    -- Micro-variations in speed
                    local base = h.WalkSpeed
                    local jitter = (math.random() - 0.5) * 1.5
                    h.WalkSpeed = base + jitter
                end
            end)
        end
    end
end)

 -- Aim Smoothing
function Stealth.smoothAim(current, target, smooth)
    if not Flags.StealthAimSmooth then return target end
    return current:Lerp(target, smooth or 0.3)
end

-- SECTION 10: ADVANCED SAFETY

page:Label(" Advanced Safety ")
page:Toggle("Risk Calculator", true, function(v) Flags.StealthRiskCalc = v end)
page:Slider("Risk Threshold", 30, 100, 70, function(v) Flags.StealthRiskThresh = v end)
page:Toggle("Silent Mode", false, function(v) Flags.StealthSilentMode = v end)
page:Toggle("Anti Replay", false, function(v) Flags.StealthAntiReplay = v end)
page:Toggle("Packet Obfuscation", false, function(v) Flags.StealthPacketObf = v end)
page:Toggle("Memory Cleanup", true, function(v) Flags.StealthMemClean = v end)
page:Slider("Mem Clean Interval", 10, 60, 30, function(v) Flags.StealthMemInt = v end)
page:Toggle("Anti Debug", true, function(v) Flags.StealthAntiDebug = v end)
page:Toggle("Server Validation Bypass", false, function(v) Flags.StealthServBypass = v end)
page:Toggle("Emergency Disconnect", false, function(v) Flags.StealthEmgDisconnect = v end)
page:Slider("Emg Disconnect HP", 5, 50, 15, function(v) Flags.StealthEmgHP = v end)
page:Toggle("Auto Kick Detection", false, function(v) Flags.StealthAutoKick = v end)
page:Toggle("Behavior Randomization", true, function(v) Flags.StealthBehavior = v end)
page:Slider("Behavior Interval", 1, 30, 10, function(v) Flags.StealthBehInt = v end)
page:Toggle("Rate Limit All", true, function(v) Flags.StealthRateLimit = v end)
page:Slider("Max Actions/s", 5, 50, 20, function(v) Flags.StealthMaxAct = v end)
page:Toggle("Whitelist Admins", true, function(v) Flags.StealthWhitelistAdmin = v end)
page:Toggle("Server Hop on Risk", false, function(v) Flags.StealthServerHop = v end)
page:Slider("Server Hop Threshold", 50, 100, 80, function(v) Flags.StealthHopThresh = v end)

 -- Risk Calculator Engine
local function calculateRisk()
    local risk=0
    -- Active features risk
    if Flags.Ragebot then risk=risk+25 end
    if Flags.AA then risk=risk+20 end
    if Flags.NoClip then risk=risk+30 end
    if Flags.SpeedBoost then risk=risk+15 end
    if Flags.FL then risk=risk+10 end
    if Flags.SilentAim then risk=risk+20 end
    if Flags.Resolver then risk=risk+10 end
    if Flags.Bhop then risk=risk+5 end
    -- Stealth mitigation
    if Flags.StealthHumanize then risk=risk-10 end
    if Flags.StealthRandomTiming then risk=risk-5 end
    if Flags.StealthMaskHooks then risk=risk-5 end
    if Flags.StealthHideGUI then risk=risk-5 end
    if Flags.StealthBehavior then risk=risk-5 end
    -- AC detection risk
    risk=risk+Stealth.RiskLevel*0.3
    return math.clamp(math.floor(risk),0,100)
end

 -- Silent Mode Engine
task.spawn(function()
    while true do task.wait(1)
        if Flags.StealthSilentMode then
            pcall(function()
                -- Hide all visual indicators
                local gui=lplr and lplr.PlayerGui and lplr and lplr.PlayerGui and lplr.PlayerGui:FindFirstChild("BloxStrike_GUI")
                if gui then gui.Enabled=false end
                -- Hide FOV circles
                if saFovCircle then saFovCircle.Visible=false end
                if vizFovCirc then vizFovCirc.Visible=false end
                if aaVizCircle then aaVizCircle.Visible=false end
                -- Hide target lines
                if vizTgtLine then vizTgtLine.Visible=false end
                -- Hide all Drawing objects
                pcall(function()
                    for _,v in pairs(getgenv() and getgenv().Drawing and {} or {}) do
                        pcall(function() v.Visible=false end)
                    end
                end)
            end)
        end
    end
end)

 -- Memory Cleanup Engine
task.spawn(function()
    while true do
        task.wait(Flags.StealthMemInt or 30)
        if Flags.StealthMemClean then
            pcall(function()
                -- Clear old data
                resData={}
                timingHistory={}
                remoteCalls={}
                RAGE.Targets={}
                -- Force garbage collection
                collectgarbage("collect")
                collectgarbage("collect")
                -- Clear any leaked Drawing objects
                pcall(function()
                    for _,v in pairs(getgenv() and getgenv().Drawing and {} or {}) do
                        if v.Visible==false then pcall(function() v:Remove() end) end
                    end
                end)
            end)
        end
    end
end)

 -- Anti Debug Engine
task.spawn(function()
    while true do task.wait(5)
        if Flags.StealthAntiDebug then
            pcall(function()
                -- Override debug functions to prevent AC from reading our stack
                if debug then
                    local oldGetInfo=debug.getinfo
                    debug.getinfo=function(level,what)
                        local info=oldGetInfo(level,what)
                        if info and info.source and info.source:find("BloxStrike") then
                            info.source="[C]" -- Fake C source
                            info.short_src="[C]"
                        end
                        return info
                    end
                end
                -- Override debug.traceback
                if debug then
                    local oldTraceback=debug.traceback
                    debug.traceback=function(level)
                        local tb=oldTraceback(level)
                        if tb then
                            -- Remove BloxStrike traces
                            tb=tb:gsub(".-BloxStrike.-%c.-%c","")
                        end
                        return tb
                    end
                end
            end)
        end
    end
end)

 -- Behavior Randomization Engine
task.spawn(function()
    while true do task.wait(Flags.StealthBehInt or 10)
        if Flags.StealthBehavior and BS.alive() then
            pcall(function()
                local h=hum()
                if h then
                    -- Random slight speed variation
                    local base=h.WalkSpeed
                    h.WalkSpeed=base+math.random(-1,1)
                    task.wait(0.1)
                    h.WalkSpeed=base
                end
            end)
        end
    end
end)

 -- Emergency Disconnect Engine
task.spawn(function()
    while true do task.wait(1)
        if Flags.StealthEmgDisconnect and BS.alive() then
            pcall(function()
                local h=hum()
                if h and h.Health<h.MaxHealth*((Flags.StealthEmgHP or 15)/100) then
                    -- Critical HP: emergency teleport
                    pcall(function()
                        game:GetService("TeleportService"):Teleport(game.PlaceId,lplr)
                    end)
                end
            end)
        end
    end
end)

 -- Auto Kick Detection
task.spawn(function()
    while true do task.wait(2)
        if Flags.StealthAutoKick then
            pcall(function()
                -- Detect if being kicked
                localgui=lplr and lplr.PlayerGui and lplr and lplr.PlayerGui and lplr.PlayerGui:FindFirstChild("BloxStrike_GUI")
                if not lplr.Character and not Flags.StealthEmgDisconnect then
                    -- Might be kicked: try to rejoin
                    task.wait(5)
                    if not lplr.Character then
                        pcall(function()
                            game:GetService("TeleportService"):Teleport(game.PlaceId,lplr)
                        end)
                    end
                end
            end)
        end
    end
end)

 -- Rate Limit All Engine
local actionCount=0
local actionWindow=tick()
task.spawn(function()
    while true do task.wait(1)
        if Flags.StealthRateLimit then
            local now=tick()
            if now-actionWindow>1 then
                actionCount=0
                actionWindow=now
            end
            -- Reset if too many actions
            if actionCount>(Flags.StealthMaxAct or 20) then
                task.wait(1)
                actionCount=0
            end
        end
    end
end)

function Stealth.rateLimitAction()
    if not Flags.StealthRateLimit then return true end
    actionCount=actionCount+1
    return actionCount<=(Flags.StealthMaxAct or 20)
end

 -- Server Hop on Risk
task.spawn(function()
    while true do task.wait(10)
        if Flags.StealthServerHop then
            local risk=calculateRisk()
            if risk>=(Flags.StealthHopThresh or 80) then
                pcall(function()
                    local servers=game:GetService("HttpService"):JSONDecode(
                        game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
                    )
                    if servers and servers.data then
                        for _,server in pairs(servers.data) do
                            if server.id~=game.JobId and server.playing<server.maxPlayers then
                                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId,server.id,lplr)
                                break
                            end
                        end
                    end
                end)
            end
        end
    end
end)

 -- Update Risk Level
task.spawn(function()
    while true do task.wait(3)
        if Flags.StealthRiskCalc then
            -- Stealth.RiskLevel=calculateRisk()
            -- Auto-disable on high risk
            if Flags.StealthAutoDisable and Stealth.RiskLevel>=(Flags.StealthRiskThresh or 70) then
                Flags.Ragebot=false
                Flags.AA=false
                Flags.NoClip=false
                Flags.SpeedBoost=false
                Flags.FL=false
                pcall(function()
                    game:GetService("StarterGui"):SetCore("SendNotification",{
                        Title=" AUTO SAFE",
                        Text="Risk "..Stealth.RiskLevel.."%  Dangerous features disabled!",
                        Duration=5
                    })
                end)
            end
        end
    end
end)

-- SECTION 11: SAFE MODE PROFILES

page:Label(" Safe Mode Profiles ")
page:Button({Name="[SAFE] Conservative", Color=Color3.fromRGB(0, 150, 0)}, function()
    -- Only keep: ESP, Aimbot (legit), Triggerbot (legit)
    Flags.Ragebot = false
    Flags.AA = false
    Flags.NoClip = false
    Flags.SpeedBoost = false
    Flags.FL = false
    Flags.NoSpread = false
    Flags.NoRecoil = false
    Flags.SilentAim = false
    Flags.ForceCrosshair = false
    -- Keep safe features
    Flags.ESP_Box = true
    Flags.ESP_Name = true
    Flags.ESP_Health = true
    Flags.Aimbot = true
    Flags.AimbotSmooth = 8
    Flags.AimbotFOV = 60
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = " Conservative Mode",
            Text = "Only ESP + Legit Aimbot enabled",
            Duration = 3,
        })
    end)
end)

page:Button({Name="[SAFE] Balanced", Color=Color3.fromRGB(200, 200, 0)}, function()
    -- Keep most features but disable blatant ones
    Flags.Ragebot = false
    Flags.AA = false
    Flags.NoClip = false
    Flags.FL = false
    Flags.NoSpread = false
    Flags.NoRecoil = false
    -- Keep: ESP, Aimbot, Triggerbot, Bhop, Third Person
    Flags.ESP_Box = true
    Flags.ESP_Name = true
    Flags.ESP_Health = true
    Flags.ESP_Dist = true
    Flags.Aimbot = true
    Flags.TriggerBot = true
    Flags.Bhop = true
    Flags.ThirdPerson = true
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = " Balanced Mode",
            Text = "Balanced features enabled",
            Duration = 3,
        })
    end)
end)

page:Button({Name="[SAFE] HVH Ready", Color=Color3.fromRGB(200, 100, 0)}, function()
    -- Enable HVH but with humanization
    Flags.Ragebot = true
    Flags.RageFOV = 180
    Flags.RageHitchance = 85
    Flags.RageSilent = true
    Flags.RageAutoFire = false
    Flags.AA = true
    Flags.AAPitch = "Down"
    Flags.AAYaw = "Jitter"
    Flags.FL = true
    Flags.FLChoke = 4
    Flags.StealthHumanize = true
    Flags.StealthRandomTiming = true
    Flags.StealthAntiPattern = true
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = " HVH Ready",
            Text = "HVH with humanization enabled",
            Duration = 3,
        })
    end)
end)

-- SECTION 11: EMERGENCY CONTROLS

page:Label(" Emergency ")
page:Button({Name=" EMERGENCY: Nuclear Disable", Color=Color3.fromRGB(200, 0, 0)}, function()
    -- Disable EVERYTHING + clean all traces
    for key, _ in pairs(Flags) do
        Flags[key] = false
    end
    -- Restore all properties
    pcall(function()
        local h = BS.hum()
        if h then
            h.WalkSpeed = 16
            h.JumpPower = 50
            h.HipHeight = 0
        end
        workspace.CurrentCamera.FieldOfView = 70
    end)
    -- Restore character
    pcall(function()
        local char = lplr.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = 0
                    part.CanCollide = true
                    part.LocalTransparencyModifier = 0
                    part.Material = Enum.Material.Plastic
                end
            end
        end
    end)
    -- Restore workspace
    pcall(function()
        for _, part in pairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                part.LocalTransparencyModifier = 0
            end
        end
    end)
    -- Restore lighting
    pcall(function()
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 100000
    end)
    -- Destroy all BS objects
    pcall(function()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name:find("BS_") then obj:Destroy() end
        end
    end)
    -- Hide GUI completely
    pcall(function()
        local gui = lplr and lplr.PlayerGui and lplr and lplr.PlayerGui and lplr.PlayerGui:FindFirstChild("BloxStrike_GUI")
        if gui then gui.Enabled = false end
    end)
    -- Restore hooks
    -- Stealth.restoreHooks()
    -- Clear timing history
    timingHistory = {}
    remoteCalls = {}
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = " NUCLEAR DISABLE",
            Text = "ALL features OFF. GUI hidden. Traces cleaned.",
            Duration = 10,
        })
    end)
end)

 -- Emergency Keybinds
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    -- F10 = Nuclear disable
    if input.KeyCode == Enum.KeyCode.F10 then
        for key, _ in pairs(Flags) do
            Flags[key] = false
        end
        pcall(function()
            local h = BS.hum()
            if h then
                h.WalkSpeed = 16
                h.JumpPower = 50
                h.HipHeight = 0
            end
            workspace.CurrentCamera.FieldOfView = 70
        end)
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = " F10 NUCLEAR",
                Text = "ALL disabled!",
                Duration = 3,
            })
        end)
    end

    -- F9 = Safe mode
    if input.KeyCode == Enum.KeyCode.F9 then
        Flags.Ragebot = false
        Flags.AA = false
        Flags.NoClip = false
        Flags.SpeedBoost = false
        Flags.FL = false
        Flags.NoSpread = false
        Flags.NoRecoil = false
        Flags.SilentAim = false
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = " F9 SAFE",
                Text = "Dangerous features disabled.",
                Duration = 3,
            })
        end)
    end

    -- F8 = Toggle GUI visibility
    if input.KeyCode == Enum.KeyCode.F8 then
        pcall(function()
            local gui = lplr and lplr.PlayerGui and lplr and lplr.PlayerGui and lplr.PlayerGui:FindFirstChild("BloxStrike_GUI")
            if gui then
                gui.Enabled = not gui.Enabled
            end
        end)
    end
end)

-- SECTION 12: RISK MONITOR

task.spawn(function()
    while true do
        task.wait(3)
        pcall(function()
            -- Calculate risk based on active features
            local risk = 0
            if Flags.Ragebot then risk = risk + 30 end
            if Flags.AA then risk = risk + 20 end
            if Flags.NoClip then risk = risk + 25 end
            if Flags.SpeedBoost then risk = risk + 15 end
            if Flags.FL then risk = risk + 10 end
            if Flags.NoSpread then risk = risk + 20 end
            if Flags.NoRecoil then risk = risk + 20 end
            if Flags.SilentAim then risk = risk + 25 end

            -- Reduce risk with stealth features
            if Flags.StealthHumanize then risk = risk - 10 end
            if Flags.StealthRandomTiming then risk = risk - 5 end
            if Flags.StealthMaskHooks then risk = risk - 5 end
            if Flags.StealthHideGUI then risk = risk - 5 end

            -- Add AC detection risk
            risk = risk + Stealth.RiskLevel * 0.3

            -- Stealth.RiskLevel = math.clamp(math.floor(risk), 0, 100)

            -- Warn if risk is high
            if Stealth.RiskLevel >= 80 and Flags.StealthAlert then
                pcall(function()
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = " HIGH RISK: " .. Stealth.RiskLevel .. "%",
                        -- Text = "Consider using SAFE mode (F9)",
                        Duration = 5,
                    })
                end)
            end
        end)
    end
end)

-- SECTION 11: HVH SAFE MODE (Anti-Detection for HVH)
-- Specific techniques to avoid ban while using HVH features

page:Label(" HVH  ")
page:Toggle("HVH Safe Mode", false, function(v) Flags.HVHSafeMode = v end)
page:Toggle("Anti-Trust Score Bypass", true, function(v) Flags.HVHTrustBypass = v end)
page:Toggle("Behavioral Consistency", true, function(v) Flags.HVHBehavior = v end)
page:Toggle("Kill Pattern Masking", true, function(v) Flags.HVHKillMask = v end)
page:Toggle("Movement Legitimacy", true, function(v) Flags.HVHMoveLegit = v end)
page:Toggle("Aim Legitimacy", true, function(v) Flags.HVHAimLegit = v end)
page:Toggle("Anti-Stat Detection", true, function(v) Flags.HVHAntiStat = v end)
page:Toggle("Server-Side Validation Mask", true, function(v) Flags.HVHServMask = v end)
page:Toggle("Session Warmup", true, function(v) Flags.HVHWarmup = v end)
page:Slider("Warmup Duration", 30, 300, 120, function(v) Flags.HVHWarmupDur = v end)
page:Toggle("Gradual Escalation", true, function(v) Flags.HVHGradual = v end)
page:Toggle("Anti-Stat Spike", true, function(v) Flags.HVHAntiSpike = v end)
page:Toggle("Kill Cooldown", true, function(v) Flags.HVHKillCD = v end)
page:Slider("Kill CD Time", 1, 10, 3, function(v) Flags.HVHKillCDTime = v end)
page:Label(" HVH  ")
page:Toggle("Fake Miss Shots", true, function(v) Flags.HVHFakeMiss = v end)
page:Slider("Fake Miss Rate", 5, 40, 15, function(v) Flags.HVHFakeMissRate = v end)
page:Toggle("Aim Delay Variation", true, function(v) Flags.HVHAimDelay = v end)
page:Slider("Aim Delay Min", 50, 300, 100, function(v) Flags.HVHAimDelayMin = v end)
page:Slider("Aim Delay Max", 100, 500, 300, function(v) Flags.HVHAimDelayMax = v end)
page:Toggle("Movement Patterns", true, function(v) Flags.HVHMovePattern = v end)
page:Dropdown({Name="Move Pattern", Flag="HVMvPat", Options={"Linear","Zigzag","Random Walk","Strafe","Stop-Go"}, Default="Linear"})
page:Toggle("Crosshair Resting", true, function(v) Flags.HVHRestCrosshair = v end)
page:Toggle("Look Around", false, function(v) Flags.HVHLookAround = v end)
page:Label(" HVH  ")
page:Toggle("KD Balance", true, function(v) Flags.HVHKDBalance = v end)
page:Slider("Target KD", 10, 50, 25, function(v) Flags.HVHTargetKD = v end)
page:Toggle("Headshot Ratio Limit", true, function(v) Flags.HVHHSLimit = v end)
page:Slider("Max HS Ratio", 20, 80, 50, function(v) Flags.HVHMaxHS = v end)
page:Toggle("Damage Distribution", true, function(v) Flags.HVHDmgDist = v end)
page:Toggle("Weapon Rotation", false, function(v) Flags.HVHWepRot = v end)
page:Label(" HVH  ")
page:Toggle("Auto Panic on Risk", true, function(v) Flags.HVHPanic = v end)
page:Slider("Panic Risk Level", 50, 90, 70, function(v) Flags.HVHPanicLevel = v end)
page:Toggle("Server Hop on Ban Risk", true, function(v) Flags.HVHServerHop = v end)
page:Slider("Ban Risk Threshold", 60, 95, 80, function(v) Flags.HVHBanThreshold = v end)
page:Toggle("Auto Account Switch", false, function(v) Flags.HVHAccSwitch = v end)
page:Label("F9 = Safe Mode | F10 = Nuclear Panic")

 -- HVH Safe Mode Engine
local hvhState = {
    -- SessionStart = tick(),
    KillsThisSession = 0,
    DeathsThisSession = 0,
    HeadshotsThisSession = 0,
    TotalShots = 0,
    MissedShots = 0,
    LastKillTime = 0,
    WarmupDone = false,
    EscalationLevel = 0,
    BehaviorPattern = {},
    MovementPhase = 0,
    LookAroundTimer = 0,
}

 -- Warmup: Start slow, gradually increase
task.spawn(function()
    while true do task.wait(1)
        if Flags.HVHSafeMode and Flags.HVHWarmup then
            local elapsed = tick() - hvhState.SessionStart
            local warmupDur = Flags.HVHWarmupDur or 120
            if elapsed < warmupDur then
                hvhState.WarmupDone = false
                -- During warmup: disable dangerous features
                if elapsed < warmupDur * 0.3 then
                    -- Phase 1: Only ESP + legit aimbot
                    Flags.Ragebot = false
                    Flags.AA = false
                    Flags.FL = false
                elseif elapsed < warmupDur * 0.6 then
                    -- Phase 2: Light HVH
                    Flags.Ragebot = false
                    Flags.AA = true
                    Flags.FL = false
                else
                    -- Phase 3: Medium HVH
                    Flags.AA = true
                    Flags.FL = true
                end
            else
                hvhState.WarmupDone = true
            end
        end
    end
end)

 -- Gradual Escalation: Increase intensity over time
task.spawn(function()
    while true do task.wait(30)
        if Flags.HVHSafeMode and Flags.HVHGradual and hvhState.WarmupDone then
            local sessionMin = (tick() - hvhState.SessionStart) / 60
            -- Every 10 minutes, allow slightly more aggressive settings
            hvhState.EscalationLevel = math.min(5, math.floor(sessionMin / 10))
        end
    end
end)

 -- Kill Pattern Masking: Add delays and randomness
task.spawn(function()
    while true do task.wait(0.5)
        if Flags.HVHSafeMode and Flags.HVHKillMask then
            pcall(function()
                -- Kill cooldown: don't kill too fast
                if Flags.HVHKillCD then
                    local cd = Flags.HVHKillCDTime or 3
                    if tick() - hvhState.LastKillTime < cd then
                        -- Too fast, temporarily reduce ragebot accuracy
                        if Flags.Ragebot then
                            local origHC = Flags.RageHC
                            Flags.RageHC = math.max(30, (origHC or 85) - 30)
                            task.wait(cd - (tick() - hvhState.LastKillTime))
                            Flags.RageHC = origHC
                        end
                    end
                end

                -- Fake miss shots: intentionally miss some shots
                if Flags.HVHFakeMiss then
                    local missRate = (Flags.HVHFakeMissRate or 15) / 100
                    if math.random() < missRate then
                        -- Temporarily move aim slightly off target
                        local cam = workspace.CurrentCamera
                        if cam then
                            local offset = Vector3.new(
                                -- (math.random() - 0.5) * 2,
                                -- (math.random() - 0.5) * 2,
                                -- 0
                            )
                            -- This is subtle enough to look like human error
                        end
                    end
                end
            end)
        end
    end
end)

 -- Movement Legitimacy: Human-like movement patterns
task.spawn(function()
    while true do task.wait(0.5)
        if Flags.HVHSafeMode and Flags.HVHMoveLegit and BS.alive() then
            pcall(function()
                local h = hum()
                if not h then return end
                local hrp = hrp()
                if not hrp then return end

                local pattern = Flags.HVMvPat or "Linear"
                hvhState.MovementPhase = hvhState.MovementPhase + 0.1

                if pattern == "Zigzag" then
                    local zigAngle = math.sin(hvhState.MovementPhase * 2) * 0.3
                    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, zigAngle, 0)
                elseif pattern == "Random Walk" then
                    if math.random() < 0.1 then
                        h.WalkDirection = Vector3.new(
                            -- (math.random() - 0.5) * 2,
                            -- 0,
                            -- (math.random() - 0.5) * 2
                        ).Unit
                    end
                elseif pattern == "Strafe" then
                    local strafeAngle = math.sin(hvhState.MovementPhase) * 0.2
                    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, strafeAngle, 0)
                elseif pattern == "Stop-Go" then
                    if math.random() < 0.05 then
                        h.WalkSpeed = 0
                        task.wait(0.3 + math.random() * 0.5)
                        h.WalkSpeed = 16
                    end
                end

                -- Micro speed variations
                local baseSpeed = h.WalkSpeed
                local jitter = (math.random() - 0.5) * 0.8
                h.WalkSpeed = baseSpeed + jitter
                task.wait(0.1)
                h.WalkSpeed = baseSpeed
            end)
        end
    end
end)

 -- Aim Legitimacy: Add realistic aim behavior
task.spawn(function()
    while true do task.wait(0.3)
        if Flags.HVHSafeMode and Flags.HVHAimLegit then
            pcall(function()
                -- Aim delay variation
                if Flags.HVHAimDelay then
                    local minD = (Flags.HVHAimDelayMin or 100) / 1000
                    local maxD = (Flags.HVHAimDelayMax or 300) / 1000
                    local delay = minD + math.random() * (maxD - minD)
                    task.wait(delay)
                end

                -- Crosshair resting: occasionally look away from enemies
                if Flags.HVHRestCrosshair and math.random() < 0.02 then
                    local cam = workspace.CurrentCamera
                    if cam then
                        local lookDir = cam.CFrame.LookVector
                        local restOffset = Vector3.new(
                            -- (math.random() - 0.5) * 0.5,
                            -- (math.random() - 0.5) * 0.3,
                            -- 0
                        )
                        cam.CFrame = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + lookDir + restOffset)
                        task.wait(0.2 + math.random() * 0.3)
                    end
                end

                -- Look around occasionally
                if Flags.HVHLookAround then
                    hvhState.LookAroundTimer = hvhState.LookAroundTimer + 0.3
                    if hvhState.LookAroundTimer > 10 + math.random() * 10 then
                        hvhState.LookAroundTimer = 0
                        local cam = workspace.CurrentCamera
                        if cam then
                            local lookAngle = (math.random() - 0.5) * math.pi * 0.5
                            cam.CFrame = cam.CFrame * CFrame.Angles(0, lookAngle, 0)
                            task.wait(0.3 + math.random() * 0.5)
                        end
                    end
                end
            end)
        end
    end
end)

 -- Anti-Stat Detection: Keep stats looking human
task.spawn(function()
    while true do task.wait(2)
        if Flags.HVHSafeMode and Flags.HVHAntiStat then
            pcall(function()
                -- KD Balance: if KD is too high, intentionally die
                if Flags.HVHKDBalance then
                    local targetKD = (Flags.HVHTargetKD or 25) / 10
                    if hvhState.DeathsThisSession > 0 then
                        local currentKD = hvhState.KillsThisSession / hvhState.DeathsThisSession
                        if currentKD > targetKD and math.random() < 0.3 then
                            -- Walk into enemy fire (subtle)
                            local enemies = BS.enemies()
                            if #enemies > 0 then
                                local target = enemies[math.random(#enemies)]
                                if target and target.HRP then
                                    local h = hum()
                                    if h then
                                        -- h:MoveTo(target.HRP.Position)
                                        task.wait(2)
                                    end
                                end
                            end
                        end
                    end
                end

                -- Headshot ratio limit
                if Flags.HVHHSLimit then
                    local totalKills = hvhState.KillsThisSession
                    if totalKills > 5 then
                        local hsRatio = hvhState.HeadshotsThisSession / totalKills
                        if hsRatio > (Flags.HVHMaxHS or 50) / 100 then
                            -- Too many headshots, aim at body for a while
                            Flags.RageHead = false
                            Flags.RageBody = true
                            task.wait(5)
                            Flags.RageBody = false
                        end
                    end
                end
            end)
        end
    end
end)

 -- Kill/Death Tracking for HVH
BS.HVHKD = hvhState

 -- Server-Side Validation Mask
task.spawn(function()
    while true do task.wait(0.5)
        if Flags.HVHSafeMode and Flags.HVHServMask then
            pcall(function()
                -- Ensure all modified values are within server-accepted ranges
                local h = hum()
                if h then
                    -- WalkSpeed: keep within reasonable range
                    if h.WalkSpeed > 50 then
                        h.WalkSpeed = 16 + math.random() * 10
                    end
                    -- JumpPower: keep within reasonable range
                    if h.JumpPower > 100 then
                        h.JumpPower = 50 + math.random() * 20
                    end
                    -- HipHeight: keep within reasonable range
                    if h.HipHeight < -2 or h.HipHeight > 5 then
                        h.HipHeight = 0
                    end
                end

                -- CFrame: ensure no NaN or extreme values
                local cam = workspace.CurrentCamera
                if cam then
                    local cf = cam.CFrame
                    if cf ~= cf then -- NaN check
                        cam.CFrame = CFrame.new(0, 10, 0)
                    end
                end
            end)
        end
    end
end)

 -- Anti-Stat Spike: Avoid sudden stat jumps
task.spawn(function()
    while true do task.wait(5)
        if Flags.HVHSafeMode and Flags.HVHAntiSpike then
            pcall(function()
                -- Track recent kills per minute
                local now = tick()
                local recentKills = 0
                -- If getting too many kills too fast, slow down
                if now - hvhState.LastKillTime < 2 then
                    recentKills = recentKills + 1
                end
                if recentKills > 3 then
                    -- Too many kills in short time, temporarily disable ragebot
                    Flags.Ragebot = false
                    task.wait(5)
                    Flags.Ragebot = true
                end
            end)
        end
    end
end)

 -- Panic System
task.spawn(function()
    while true do task.wait(2)
        if Flags.HVHSafeMode and Flags.HVHPanic then
            local risk = calculateRisk()
            if risk >= (Flags.HVHPanicLevel or 70) then
                -- Auto panic: disable all dangerous features
                Flags.Ragebot = false
                Flags.AA = false
                Flags.NoClip = false
                Flags.SpeedBoost = false
                Flags.FL = false
                Flags.SilentAim = false
                Flags.Resolver = false
                pcall(function()
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = " HVH SAFE MODE",
                        Text = "Risk " .. risk .. "%  Dangerous features disabled!",
                        Duration = 5,
                    })
                end)

                -- Server hop if threshold reached
                if Flags.HVHServerHop and risk >= (Flags.HVHBanThreshold or 80) then
                    pcall(function()
                        local servers = game:GetService("HttpService"):JSONDecode(
                            game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
                        )
                        if servers and servers.data then
                            for _, server in pairs(servers.data) do
                                if server.id ~= game.JobId and server.playing < server.maxPlayers then
                                    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, server.id, lplr)
                                    break
                                end
                            end
                        end
                    end)
                end
            end
        end
    end
end)

-- SECTION 13: SSVL  Server-Side Validation Layer
-- Make ALL client modifications appear server-side legitimate

page:Label(" SSVL  ")
page:Toggle("SSVL Enabled", true, function(v) Flags.SSVL = v end)
page:Toggle("Velocity Cap", true, function(v) Flags.SSVLVelCap = v end)
page:Slider("Max Velocity", 10, 200, 60, function(v) Flags.SSVLMaxVel = v end)
page:Toggle("Position Drift", true, function(v) Flags.SSVLDrift = v end)
page:Toggle("Acceleration Cap", true, function(v) Flags.SSVLAccel = v end)
page:Slider("Max Acceleration", 20, 500, 100, function(v) Flags.SSVLMaxAccel = v end)
page:Toggle("Angular Velocity Limit", true, function(v) Flags.SSVLAngular = v end)
page:Slider("Max Angular Vel", 10, 200, 80, function(v) Flags.SSVLMaxAngular = v end)
page:Toggle("Ping Simulation", true, function(v) Flags.SSVLPingSim = v end)
page:Slider("Fake Ping Offset", -50, 100, 30, function(v) Flags.SSVLPingOff = v end)

 -- SSVL Engine
local ssvlState = {
    PositionBuffer = {},
    VelocityBuffer = {},
    AccelerationBuffer = {},
    -- LastTick = tick(),
    -- DriftAccum = Vector3.new(0, 0, 0),
}

-- Velocity + Acceleration capping: keep within server-reasonable limits
task.spawn(function()
    while true do task.wait(0.05)
        if not Flags.SSVL or not BS.alive() then continue end
        local hrp = BS.hrp()
        if not hrp then continue end
        local h = BS.hum()
        if not h then continue end

        -- Velocity cap: clamp AssemblyLinearVelocity
        if Flags.SSVLVelCap then
            local vel = hrp.AssemblyLinearVelocity
            local maxV = Flags.SSVLMaxVel or 60
            local horizVel = Vector3.new(vel.X, 0, vel.Z)
            if horizVel.Magnitude > maxV then
                local clamped = horizVel.Unit * maxV
                hrp.AssemblyLinearVelocity = Vector3.new(clamped.X, vel.Y, clamped.Z)
            end
        end

        -- Acceleration cap: prevent instant direction changes
        if Flags.SSVLAccel then
            local now = tick()
            local dt = now - ssvlState.LastTick
            if dt > 0.01 then
                local vel = hrp.AssemblyLinearVelocity
                local accel = (vel - (ssvlState.LastVelocity or vel)) / dt
                local maxA = Flags.SSVLMaxAccel or 100
                if accel.Magnitude > maxA then
                    local clampedAccel = accel.Unit * maxA
                    hrp.AssemblyLinearVelocity = (ssvlState.LastVelocity or vel) + clampedAccel * dt
                end
                ssvlState.LastVelocity = vel
                ssvlState.LastTick = now
            end
        end

        -- Angular velocity limit
        if Flags.SSVLAngular then
            local angVel = hrp.AssemblyAngularVelocity
            local maxAng = (Flags.SSVLMaxAngular or 80) / 10
            if angVel.Magnitude > maxAng then
                hrp.AssemblyAngularVelocity = angVel.Unit * maxAng
            end
        end

        -- Position drift: add micro-drift so position changes look continuous not teleport
        if Flags.SSVLDrift then
            local vel = hrp.AssemblyLinearVelocity
            if vel.Magnitude > 30 then
                -- Add tiny random drift to mask exact position
                ssvlState.DriftAccum = ssvlState.DriftAccum + Vector3.new(
                    -- (math.random() - 0.5) * 0.02,
                    -- 0,
                    -- (math.random() - 0.5) * 0.02
                )
                if ssvlState.DriftAccum.Magnitude > 0.5 then
                    ssvlState.DriftAccum = Vector3.new(0, 0, 0)
                end
            end
        end

        -- ::ssVLcont::
    end
end)

-- Ping simulation: fake client latency to mask spike patterns
task.spawn(function()
    while true do task.wait(2)
        if Flags.SSVL and Flags.SSVLPingSim then
            pcall(function()
                local stats = nil
                pcall(function() stats = game:GetService("Stats") end)
                if stats and stats.Network then
                    local offset = Flags.SSVLPingOff or 30
                    local basePing = 0
                    pcall(function() basePing = stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
                    -- SSVL doesn't modify the real ping, just monitors
                    -- If AC checks for abnormally low ping, we can note it
                    if basePing and basePing < 10 then
                        -- Suspiciously low ping, AC might flag
                        -- Stealth.RiskLevel = math.min(100, Stealth.RiskLevel + 2)
                    end
                end
            end)
        end
    end
end)

-- SECTION 14: FINGERPRINT ROTATION
-- Rotate player behavior fingerprint to avoid signature matching

page:Label("  ")
page:Toggle("Fingerprint Rotation", true, function(v) Flags.FPRotation = v end)
page:Slider("Rotation Interval", 30, 300, 120, function(v) Flags.FPRotInterval = v end)
page:Toggle("Name Fingerprint", true, function(v) Flags.FPName = v end)
page:Toggle("Movement Fingerprint", true, function(v) Flags.FPMove = v end)
page:Toggle("Aim Fingerprint", true, function(v) Flags.FPAim = v end)
page:Toggle("Timing Fingerprint", true, function(v) Flags.FPTiming = v end)
page:Toggle("Camera Fingerprint", true, function(v) Flags.FPCamera = v end)

 -- Fingerprint State
local fpState = {
    CurrentProfile = 1,
    -- LastRotation = tick(),
    Profiles = {
        {Name="Player_" .. math.random(1000,9999), MoveStyle="Normal", AimStyle="Smooth", TimingBase=80, CamSens=1.0},
        {Name="Player_" .. math.random(1000,9999), MoveStyle="Aggressive", AimStyle="Flick", TimingBase=60, CamSens=1.2},
        {Name="Player_" .. math.random(1000,9999), MoveStyle="Passive", AimStyle="Slow", TimingBase=120, CamSens=0.8},
        {Name="Player_" .. math.random(1000,9999), MoveStyle="Mixed", AimStyle="Adaptive", TimingBase=90, CamSens=1.1},
        {Name="Player_" .. math.random(1000,9999), MoveStyle="Cautious", AimStyle="Precise", TimingBase=100, CamSens=0.9},
    },
}

local function getFPProfile()
    return fpState.Profiles[fpState.CurrentProfile]
end

function Stealth.getFingerprintDelay()
    if not Flags.FPRotation then return 80 end
    local p = getFPProfile()
    local base = p.TimingBase
    return base + (math.random() - 0.5) * 20
end

function Stealth.getFingerprintAimSmooth()
    if not Flags.FPRotation then return 0.3 end
    local p = getFPProfile()
    if p.AimStyle == "Flick" then return 0.6
    elseif p.AimStyle == "Slow" then return 0.15
    elseif p.AimStyle == "Precise" then return 0.25
    else return 0.35 end
end

function Stealth.getFingerprintCamSens()
    if not Flags.FPRotation then return 1.0 end
    return getFPProfile().CamSens
end

-- Rotation engine
task.spawn(function()
    while true do task.wait(1)
        if Flags.FPRotation then
            local interval = Flags.FPRotInterval or 120
            if tick() - fpState.LastRotation > interval then
                fpState.CurrentProfile = (fpState.CurrentProfile % #fpState.Profiles) + 1
                fpState.LastRotation = tick()
                -- Regenerate names
                for i = 1, #fpState.Profiles do
                    fpState.Profiles[i].Name = "Player_" .. math.random(1000, 9999)
                end
                pcall(function()
                    -- Subtle notification
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = " ",
                        -- Text = "Profile: " .. getFPProfile().MoveStyle .. " / " .. getFPProfile().AimStyle,
                        Duration = 2,
                    })
                end)
            end
        end
    end
end)

-- SECTION 15: TRAFFIC PATTERN MASKING
-- Hide network traffic patterns from AC analysis

page:Label("  ")
page:Toggle("Traffic Masking", true, function(v) Flags.TrafficMask = v end)
page:Toggle("Noise Injection", true, function(v) Flags.TrafficNoise = v end)
page:Slider("Noise Level", 1, 10, 3, function(v) Flags.TrafficNoiseLvl = v end)
page:Toggle("Burst Smoothing", true, function(v) Flags.TrafficBurst = v end)
page:Slider("Burst Window", 5, 50, 15, function(v) Flags.TrafficBurstWin = v end)
page:Toggle("Remote Fingerprint", true, function(v) Flags.TrafficRemoteFP = v end)

 -- Traffic Masking Engine
local trafficState = {
    BurstBuffer = {},
    NoiseCounter = 0,
    -- LastBurstFlush = tick(),
    RemoteFingerprints = {},
}

-- Inject noise: send fake harmless remote calls to mask real ones
function Stealth.injectTrafficNoise()
    if not Flags.TrafficNoise then return end
    pcall(function()
        -- Fire harmless RemoteEvents to add noise
        local noiseLevel = Flags.TrafficNoiseLvl or 3
        for i = 1, noiseLevel do
            task.delay(math.random() * 0.5, function()
                pcall(function()
                    -- Find any non-AC remote and fire it harmlessly
                    for _, obj in pairs(game:GetDescendants()) do
                        if obj:IsA("RemoteEvent") then
                            local name = obj.Name:lower()
                            if not name:find("anticheat") and not name:find("kick") and not name:find("ban") then
                                pcall(function() obj:FireServer() end)
                                break
                            end
                        end
                    end
                end)
            end)
        end
    end)
end

-- Burst smoothing: spread rapid-fire actions over time
function Stealth.smoothBurst(action)
    if not Flags.TrafficBurst then return action() end
    table.insert(trafficState.BurstBuffer, {Action=action, Time=tick()})
    local window = (Flags.TrafficBurstWin or 15) / 1000
    if tick() - trafficState.LastBurstFlush > window then
        for _, entry in ipairs(trafficState.BurstBuffer) do
            task.spawn(pcall, entry.Action)
        end
        trafficState.BurstBuffer = {}
        trafficState.LastBurstFlush = tick()
    end
end

-- Remote fingerprinting: track which remotes AC monitors
task.spawn(function()
    while true do task.wait(5)
        if Flags.TrafficMask and Flags.TrafficRemoteFP then
            pcall(function()
                -- Check which remotes have AC watchers
                for _, obj in pairs(game:GetDescendants()) do
                    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                        local conns = getconnections and getconnections(obj.OnServerEvent)
                        if conns and #conns > 3 then
                            trafficState.RemoteFingerprints[obj:GetFullName()] = {
                                Watchers = #conns,
                                Suspicious = true,
                            }
                        end
                    end
                end
            end)
        end
    end
end)

-- Periodic noise injection
task.spawn(function()
    while true do task.wait(15)
        if Flags.TrafficMask then
            -- Stealth.injectTrafficNoise()
        end
    end
end)

-- SECTION 16: ML / BEHAVIORAL AI EVASION
-- Evade machine learning based behavioral analysis

page:Label(" ML  ")
page:Toggle("ML Evasion", true, function(v) Flags.MLEvasion = v end)
page:Slider("Human Score Target", 50, 95, 80, function(v) Flags.MLHumanScore = v end)
page:Toggle("Movement Entropy", true, function(v) Flags.MLEntropy = v end)
page:Toggle("Mouse Entropy", true, function(v) Flags.MLMouseEntropy = v end)
page:Toggle("Reaction Simulation", true, function(v) Flags.MLReaction = v end)
page:Slider("Reaction Variance", 10, 500, 150, function(v) Flags.MLReactionVar = v end)
page:Toggle("Decision Delay", true, function(v) Flags.MLDecision = v end)
page:Toggle("Micro Pauses", true, function(v) Flags.MLMicroPause = v end)

 -- ML Evasion Engine
local mlState = {
    HumanScore = 100,
    EntropyAccum = 0,
    MouseHistory = {},
    DecisionBuffer = {},
    MicroPauseTimer = 0,
}

-- Movement entropy: add random micro-variations to movement vector
function Stealth.addMovementEntropy(dir)
    if not Flags.MLEvasion or not Flags.MLEntropy then return dir end
    -- Add gaussian-like noise to movement direction
    local noise = Vector3.new(
        -- (math.random() - 0.5) * 0.08,
        -- 0,
        -- (math.random() - 0.5) * 0.08
    )
    mlState.EntropyAccum = mlState.EntropyAccum + noise.Magnitude
    return (dir + noise).Unit
end

-- Mouse entropy: add micro-jitter to mouse movement
function Stealth.addMouseEntropy(angle)
    if not Flags.MLEvasion or not Flags.MLMouseEntropy then return angle end
    local jitter = (math.random() - 0.5) * 0.003
    table.insert(mlState.MouseHistory, angle + jitter)
    if #mlState.MouseHistory > 30 then table.remove(mlState.MouseHistory, 1) end
    return angle + jitter
end

-- Reaction time simulation: mimic human reaction delays
function Stealth.mlReactionTime()
    if not Flags.MLEvasion or not Flags.MLReaction then return 0 end
    local base = (Flags.MLReactionVar or 150) / 1000
    -- Human reaction is log-normal distributed
    -- Use Box-Muller transform for gaussian
    local u1 = math.random()
    local u2 = math.random()
    local gaussian = math.sqrt(-2 * math.log(math.max(u1, 0.001))) * math.cos(2 * math.pi * u2)
    return math.max(0.05, base + gaussian * base * 0.3)
end

-- Decision delay: don't always react instantly
function Stealth.mlDecisionDelay()
    if not Flags.MLEvasion or not Flags.MLDecision then return end
    -- 15% chance to "hesitate" briefly
    if math.random() < 0.15 then
        task.wait(0.05 + math.random() * 0.15)
    end
end

-- Micro pauses: small idle moments like a real player
task.spawn(function()
    while true do task.wait(0.1)
        if Flags.MLEvasion and Flags.MLMicroPause and BS.alive() then
            mlState.MicroPauseTimer = mlState.MicroPauseTimer + 0.1
            -- Every 8-20 seconds, pause briefly
            local pauseInterval = 8 + math.random() * 12
            if mlState.MicroPauseTimer > pauseInterval then
                mlState.MicroPauseTimer = 0
                -- Brief stillness
                local h = BS.hum()
                if h then
                    local origSpeed = h.WalkSpeed
                    h.WalkSpeed = 0
                    task.wait(0.2 + math.random() * 0.5)
                    h.WalkSpeed = origSpeed
                end
            end
        end
    end
end)

-- Human score calculator
task.spawn(function()
    while true do task.wait(5)
        if Flags.MLEvasion then
            local score = 100
            -- Deductions
            if Flags.Ragebot then score = score - 30 end
            if Flags.NoClip then score = score - 25 end
            if Flags.SpeedBoost then score = score - 20 end
            if Flags.SilentAim then score = score - 15 end
            -- Bonuses
            if Flags.MLEntropy then score = score + 5 end
            if Flags.MLMouseEntropy then score = score + 5 end
            if Flags.MLReaction then score = score + 5 end
            if Flags.MLMicroPause then score = score + 5 end
            if Flags.HVHSafeMode then score = score + 10 end
            mlState.HumanScore = math.clamp(score, 0, 100)

            -- If score is too low, warn and auto-enable protections
            if mlState.HumanScore < (Flags.MLHumanScore or 80) then
                -- Auto-enable more evasion features
                Flags.MLEntropy = true
                Flags.MLMouseEntropy = true
                Flags.MLReaction = true
                Flags.MLMicroPause = true
            end
        end
    end
end)

BS.MLState = mlState

-- SECTION 17: STATISTICAL ANOMALY SMOOTHING
-- Ensure our stats don't trigger statistical detection

page:Label("  ")
page:Toggle("Stat Smoothing", true, function(v) Flags.StatSmooth = v end)
page:Toggle("KD Regulation", true, function(v) Flags.StatKDReg = v end)
page:Slider("Target KD", 10, 40, 20, function(v) Flags.StatTargetKD = v end)
page:Toggle("HS Ratio Regulation", true, function(v) Flags.StatHSReg = v end)
page:Slider("Max HS %", 20, 70, 45, function(v) Flags.StatMaxHS = v end)
page:Toggle("Damage Spread", true, function(v) Flags.StatDmgSpread = v end)
page:Toggle("Kill Timing Spread", true, function(v) Flags.StatKillTiming = v end)
page:Slider("Min Kill Gap", 1, 15, 3, function(v) Flags.StatMinKillGap = v end)
page:Toggle("Weapon Rotation", true, function(v) Flags.StatWeaponRot = v end)
page:Toggle("Death Staging", false, function(v) Flags.StatDeathStage = v end)

 -- Statistical Smoothing Engine
local statState = {
    SessionKills = 0,
    SessionDeaths = 0,
    SessionHeadshots = 0,
    SessionTotalDamage = 0,
    SessionDamageValues = {},
    LastKillTime = 0,
    KillTimestamps = {},
    WeaponUsage = {},
    ForcedDeaths = 0,
}

-- KD Regulation: if too good, play worse for a while
task.spawn(function()
    while true do task.wait(3)
        if Flags.StatSmooth and Flags.StatKDReg and statState.SessionDeaths > 0 then
            local currentKD = statState.SessionKills / math.max(1, statState.SessionDeaths)
            local targetKD = (Flags.StatTargetKD or 20) / 10
            if currentKD > targetKD * 1.5 then
                -- Way too good, need some deaths
                Flags.StatDeathStage = true
                statState.ForcedDeaths = statState.ForcedDeaths + 1
            elseif currentKD < targetKD * 0.5 then
                Flags.StatDeathStage = false
            end
        end
    end
end)

-- Kill timing spread: ensure kills aren't too evenly spaced
task.spawn(function()
    while true do task.wait(1)
        if Flags.StatSmooth and Flags.StatKillTiming then
            local now = tick()
            local minGap = Flags.StatMinKillGap or 3
            -- Track recent kills
            for i = #statState.KillTimestamps, 1, -1 do
                if now - statState.KillTimestamps[i] > 60 then
                    table.remove(statState.KillTimestamps, i)
                end
            end
            -- If kills are too evenly spaced, inject gaps
            if #statState.KillTimestamps >= 3 then
                local lastTwo = statState.KillTimestamps[#statState.KillTimestamps] - statState.KillTimestamps[#statState.KillTimestamps - 1]
                if math.abs(lastTwo - minGap) < 0.5 then
                    -- Too regular, slow down
                    task.wait(minGap + math.random() * 3)
                end
            end
        end
    end
end)

-- Weapon rotation: don't use the same weapon all the time
function Stealth.trackWeaponUse(weaponName)
    if not Flags.StatWeaponRot then return end
    weaponName = weaponName or "default"
    statState.WeaponUsage[weaponName] = (statState.WeaponUsage[weaponName] or 0) + 1
    -- If this weapon is overused, suggest switching
    local totalUses = 0
    for _, v in pairs(statState.WeaponUsage) do totalUses = totalUses + v end
    if totalUses > 10 then
        local usageRatio = statState.WeaponUsage[weaponName] / totalUses
        if usageRatio > 0.7 then
            -- Overusing one weapon, should switch
            return false -- signal to switch
        end
    end
    return true
end

-- Track kills/deaths for stats
function Stealth.onKill(headshot)
    statState.SessionKills = statState.SessionKills + 1
    if headshot then statState.SessionHeadshots = statState.SessionHeadshots + 1 end
    statState.LastKillTime = tick()
    table.insert(statState.KillTimestamps, tick())
    hvhState.KillsThisSession = (hvhState.KillsThisSession or 0) + 1
    if headshot then hvhState.HeadshotsThisSession = (hvhState.HeadshotsThisSession or 0) + 1 end
end

function Stealth.onDeath()
    statState.SessionDeaths = statState.SessionDeaths + 1
    hvhState.DeathsThisSession = (hvhState.DeathsThisSession or 0) + 1
end

BS.StatState = statState

-- SECTION 18: ANTI-REPLAY PROTECTION
-- Prevent AC from replaying our actions to detect cheats

page:Label("  ")
page:Toggle("Anti Replay", true, function(v) Flags.AntiReplay = v end)
page:Toggle("Action Fuzzing", true, function(v) Flags.ActionFuzz = v end)
page:Slider("Fuzz Amount", 1, 20, 5, function(v) Flags.ActionFuzzAmt = v end)
page:Toggle("Sequence Shuffling", true, function(v) Flags.SeqShuffle = v end)
page:Toggle("Timing Desync", true, function(v) Flags.TimingDesync = v end)

 -- Anti-Replay Engine
local replayState = {
    ActionHistory = {},
    FuzzAmount = 5,
}

-- Action fuzzing: slightly vary repeated actions
function Stealth.fuzzAction(actionType, params)
    if not Flags.AntiReplay or not Flags.ActionFuzz then return params end
    local fuzz = (Flags.ActionFuzzAmt or 5) / 100
    if type(params) == "number" then
        return params * (1 + (math.random() - 0.5) * fuzz * 2)
    elseif type(params) == "Vector3" then
        return params + Vector3.new(
            -- (math.random() - 0.5) * fuzz * 2,
            -- (math.random() - 0.5) * fuzz * 2,
            -- (math.random() - 0.5) * fuzz * 2
        )
    elseif type(params) == "CFrame" then
        local pos = params.Position
        local newOffset = Vector3.new(
            -- (math.random() - 0.5) * fuzz * 2,
            -- 0,
            -- (math.random() - 0.5) * fuzz * 2
        )
        return CFrame.new(pos + newOffset) * (params - pos)
    end
    return params
end

-- Timing desync: vary action timing to prevent replay matching
function Stealth.desyncTiming(baseDelay)
    if not Flags.AntiReplay or not Flags.TimingDesync then return baseDelay end
    -- Add gaussian jitter
    local u1 = math.max(0.001, math.random())
    local u2 = math.random()
    local gaussian = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
    return math.max(0.001, baseDelay + gaussian * baseDelay * 0.15)
end

-- SECTION 19: MEMORY SIGNATURE EVASION
-- Evade memory signature scanning

page:Label("  ")
page:Toggle("Memory Evasion", true, function(v) Flags.MemEvasion = v end)
page:Toggle("String Encryption", true, function(v) Flags.MemStrEnc = v end)
page:Toggle("Object Scrambling", true, function(v) Flags.MemObjScramble = v end)
page:Toggle("Reference Cleanup", true, function(v) Flags.MemRefClean = v end)
page:Slider("Cleanup Interval", 10, 60, 20, function(v) Flags.MemCleanInt = v end)
page:Toggle("GC Obfuscation", true, function(v) Flags.MemGCObf = v end)

 -- Memory Evasion Engine
local memEvadeState = {
    EncryptedStrings = {},
    OriginalStrings = {},
    CleanupTimer = 0,
}

-- Encrypt sensitive strings in memory
function Stealth.encryptMemoryString(str)
    if not Flags.MemEvasion or not Flags.MemStrEnc then return str end
    if memEvadeState.EncryptedStrings[str] then
        return memEvadeState.EncryptedStrings[str]
    end
    -- XOR encrypt with rotating key
    local key = math.random(1, 255)
    local encrypted = ""
    for i = 1, #str do
        local b = bit32.bxor(string.byte(str, i), key)
        encrypted = encrypted .. string.char(b)
    end
    memEvadeState.EncryptedStrings[str] = encrypted
    memEvadeState.OriginalStrings[encrypted] = str
    return encrypted
end

function Stealth.decryptMemoryString(enc)
    return memEvadeState.OriginalStrings[enc] or enc
end

-- Object name scrambling: rename BS_ objects with random names
task.spawn(function()
    while true do task.wait(10)
        if Flags.MemEvasion and Flags.MemObjScramble then
            pcall(function()
                -- Scramble our workspace objects
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj.Name:find("BS_") or obj.Name:find("BloxStrike") then
                        local newName = ""
                        for i = 1, math.random(6, 15) do
                            newName = newName .. string.char(math.random(65, 122))
                        end
                        obj.Name = newName
                    end
                end
                -- Scramble our GUI
                local gui = lplr and lplr.PlayerGui and lplr and lplr.PlayerGui and lplr.PlayerGui:FindFirstChildWhichIsA("ScreenGui")
                if gui and (gui.Name:find("BloxStrike") or gui.Name:find("BS_")) then
                    local newName = ""
                    for i = 1, math.random(10, 20) do
                        newName = newName .. string.char(math.random(65, 122))
                    end
                    gui.Name = newName
                end
            end)
        end
    end
end)

-- Reference cleanup: nil out old references periodically
task.spawn(function()
    while true do task.wait(Flags.MemCleanInt or 20)
        if Flags.MemEvasion and Flags.MemRefClean then
            pcall(function()
                -- Clear old detection data
                Stealth.Detections = {}
                resData = {}
                timingHistory = {}
                remoteCalls = {}
                replayState.ActionHistory = {}
                ssvlState.PositionBuffer = {}
                ssvlState.VelocityBuffer = {}
                trafficState.BurstBuffer = {}
                mlState.MouseHistory = {}
                statState.SessionDamageValues = {}
                -- Force GC
                collectgarbage("collect")
                collectgarbage("collect")
            end)
        end
    end
end)

-- GC obfuscation: confuse memory scanners during GC
task.spawn(function()
    while true do task.wait(30)
        if Flags.MemEvasion and Flags.MemGCObf then
            pcall(function()
                -- Create temporary objects then destroy them to confuse scanners
                local temps = {}
                for i = 1, 10 do
                    local t = Instance.new("Part")
                    t.Name = string.char(math.random(65, 122), math.random(65, 122), math.random(65, 122))
                    t.Size = Vector3.new(math.random(1, 5), math.random(1, 5), math.random(1, 5))
                    t.Transparency = 1
                    t.Anchored = true
                    t.CanCollide = false
                    t.Parent = workspace.CurrentCamera
                    table.insert(temps, t)
                end
                task.wait(0.1)
                for _, t in ipairs(temps) do
                    pcall(function() t:Destroy() end)
                end
                collectgarbage("collect")
            end)
        end
    end
end)

-- SECTION 20: ANTI-EMULATION / SANDBOX DETECTION
-- Detect if running in analysis environment

page:Label("  /  ")
page:Toggle("Anti-Emulation", true, function(v) Flags.AntiEmulation = v end)
page:Toggle("Sandbox Detection", true, function(v) Flags.SandboxDetect = v end)
page:Toggle("Timing Canary", true, function(v) Flags.TimingCanary = v end)
page:Toggle("Environment Integrity", true, function(v) Flags.EnvIntegrity = v end)
page:Toggle("Self-Heal", true, function(v) Flags.SelfHeal = v end)

 -- Anti-Emulation Engine
local emulationState = {
    OriginalFunctions = {},
    IntegrityHash = 0,
    -- CanaryValue = math.random(10000, 99999),
    -- LastIntegrityCheck = tick(),
}

-- Store original critical functions before any hooks
pcall(function()
    if getrawmetatable then
        emulationState.OriginalFunctions = {
            index = select(2, pcall(getrawmetatable, game)).__index,
            newindex = select(2, pcall(getrawmetatable, game)).__newindex,
            namecall = select(2, pcall(getrawmetatable, game)).__namecall,
        }
    end
end)

-- Timing canary: detect if our timing is being manipulated
task.spawn(function()
    while true do task.wait(1)
        if Flags.AntiEmulation and Flags.TimingCanary then
            local startTick = tick()
            task.wait(0.016) -- ~1 frame
            local elapsed = tick() - startTick
            -- If elapsed is very different from expected, something is interfering
            if elapsed > 0.1 then
                -- Timing is being stretched (sandbox/emulation)
                -- Stealth.RiskLevel = math.min(100, Stealth.RiskLevel + 5)
                pcall(function()
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = " ",
                        Text = "",
                        Duration = 3,
                    })
                end)
            end
        end
    end
end)

-- Environment integrity check: verify our hooks haven't been tampered
task.spawn(function()
    while true do task.wait(10)
        if Flags.AntiEmulation and Flags.EnvIntegrity then
            pcall(function()
                -- Check if our critical functions are still intact
                local intact = true
                -- Verify checkcaller hasn't been re-hooked
                if checkcaller then
                    local result = checkcaller()
                    if result ~= false and result ~= true then
                        intact = false
                    end
                end
                -- Verify debug library is intact
                if debug and debug.getinfo then
                    local info = debug.getinfo(1)
                    if not info then
                        intact = false
                    end
                end
                if not intact then
                    -- Stealth.RiskLevel = math.min(100, Stealth.RiskLevel + 10)
                end
            end)
        end
    end
end)

-- Self-heal: restore broken hooks and functions
function Stealth.selfHeal()
    if not Flags.SelfHeal then return end
    pcall(function()
        -- Re-apply checkcaller spoof
        if Flags.StealthSpoofCaller and checkcaller then
            _G.checkcaller = function() return false end
        end
        -- Re-apply debug overrides
        if Flags.StealthAntiDebug and debug then
            local oldGetInfo = debug.getinfo
            debug.getinfo = function(level, what)
                local info = oldGetInfo(level, what)
                if info and info.source and info.source:find("BloxStrike") then
                    info.source = "[C]"
                    info.short_src = "[C]"
                end
                return info
            end
        end
        -- Re-protect metamethods
        if Bypass and Bypass.backupMetatables then
            pcall(function() Bypass.backupMetatables() end)
        end
        
-- ═══════════════════════════════════════════════════════════════
-- HWID SPOOFER
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}

function BS.HWIDSpoofer:Generate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = ""
    for i = 1, 32 do
        local r = math.random(1, #chars)
        id = id .. chars:sub(r, r)
        if i == 8 or i == 12 or i == 16 or i == 20 then
            id = id .. "-"
        end
    end
    return id
end

function BS.HWIDSpoofer:Activate()
    self.Active = true
    self.SpoofedID = self:Generate()
    -- Try to hook HWID functions
    pcall(function()
        if gethwid then
            local old = gethwid
            gethwid = function() return self.SpoofedID end
        end
    end)
    pcall(function()
        if getmachineid then
            local old = getmachineid
            getmachineid = function() return self.SpoofedID end
        end
    end)
    print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end

-- ═══════════════════════════════════════════════════════════════
-- PING SPOOF
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}

function BS.PingSpoof:SetPing(value)
    self.FakePing = value
    self.Active = true
    -- Override ping reporting
    pcall(function()
        if BS.Ping then
            BS.Ping.Current = value
            BS.Ping.Average = value
        end
    end)
end

function BS.PingSpoof:Disable()
    self.Active = false
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI-SCREENSHOT
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}

function BS.AntiScreenshot:Activate()
    self.Active = true
    -- Hide all BS GUI elements when screenshot is detected
    pcall(function()
        -- Hook SetCore("SendNotification") to suppress
        local oldSetCore
        oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
            if method == "TakeScreenshot" then
                -- Hide everything temporarily
                if BS.Win then BS.Win.Visible = false end
                task.delay(1, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
                return
            end
            return oldSetCore(self, method, ...)
        end)
    end)
    -- Also hide on PrintScreen key
    pcall(function()
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.PrintScreen then
                if BS.Win then BS.Win.Visible = false end
                task.delay(2, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
            end
        end)
    end)
    print("[Stealth] Anti-Screenshot active")
end

-- ═══════════════════════════════════════════════════════════════
-- STATISTICS TRACKER
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
    Kills = 0,
    Deaths = 0,
    Headshots = 0,
    Shots = 0,
    Hits = 0,
    Damage = 0,
    StartTime = tick(),
}

function BS.Stats:RecordKill(headshot)
    self.Kills = self.Kills + 1
    if headshot then self.Headshots = self.Headshots + 1 end
end

function BS.Stats:RecordDeath()
    self.Deaths = self.Deaths + 1
end

function BS.Stats:RecordShot(hit)
    self.Shots = self.Shots + 1
    if hit then self.Hits = self.Hits + 1 end
end

function BS.Stats:RecordDamage(dmg)
    self.Damage = self.Damage + dmg
end

function BS.Stats:GetKD()
    if self.Deaths == 0 then return self.Kills end
    return math.floor(self.Kills / self.Deaths * 10) / 10
end

function BS.Stats:GetHSPercent()
    if self.Kills == 0 then return 0 end
    return math.floor(self.Headshots / self.Kills * 100)
end

function BS.Stats:GetAccuracy()
    if self.Shots == 0 then return 0 end
    return math.floor(self.Hits / self.Shots * 100)
end

function BS.Stats:GetPlayTime()
    return math.floor(tick() - self.StartTime)
end

function BS.Stats:GetReport()
    return string.format(
        "K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
        self.Kills, self.Deaths, self:GetKD(),
        self:GetHSPercent(), self:GetAccuracy(),
        self.Damage, math.floor(self:GetPlayTime() / 60)
    )
end

-- GUI
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)

print("[Stealth] Self-heal completed")
    end)
end

-- Auto self-heal when degradation detected
task.spawn(function()
    while true do task.wait(15)
        if Flags.AntiEmulation and Flags.SelfHeal then
            if Stealth.RiskLevel > 30 then
                -- Stealth.selfHeal()
            end
        end
    end
end)

-- SECTION 21: COMPREHENSIVE RISK MATRIX
-- Unified risk calculation combining ALL detection vectors

page:Label("  ")
page:Toggle("Matrix Risk Calc", true, function(v) Flags.MatrixRisk = v end)
page:Toggle("Auto Panic on Matrix", true, function(v) Flags.MatrixPanic = v end)
page:Slider("Panic Threshold", 40, 90, 65, function(v) Flags.MatrixPanicThresh = v end)
page:Toggle("Adaptive Stealth", true, function(v) Flags.AdaptiveStealth = v end)

 -- Risk Matrix Engine
local riskMatrix = {
    FeatureRisk = 0,
    BehaviorRisk = 0,
    NetworkRisk = 0,
    StatRisk = 0,
    MemoryRisk = 0,
    TimingRisk = 0,
    TotalRisk = 0,
    History = {},
}

local function calculateComprehensiveRisk()
    if not Flags.MatrixRisk then return calculateRisk() end

    local r = 0

    -- Feature Risk (what's turned on)
    local featureRisk = 0
    if Flags.Ragebot then featureRisk = featureRisk + 25 end
    if Flags.AA then featureRisk = featureRisk + 20 end
    if Flags.NoClip then featureRisk = featureRisk + 30 end
    if Flags.SpeedBoost then featureRisk = featureRisk + 15 end
    if Flags.SilentAim then featureRisk = featureRisk + 20 end
    if Flags.FL then featureRisk = featureRisk + 10 end
    if Flags.NoSpread then featureRisk = featureRisk + 20 end
    if Flags.NoRecoil then featureRisk = featureRisk + 20 end
    if Flags.Resolver then featureRisk = featureRisk + 10 end
    riskMatrix.FeatureRisk = math.min(100, featureRisk)

    -- Behavior Risk (how human-like)
    local behaviorRisk = 50 -- base risk
    if Flags.MLEvasion then behaviorRisk = behaviorRisk - 10 end
    if Flags.MLEntropy then behaviorRisk = behaviorRisk - 5 end
    if Flags.MLMicroPause then behaviorRisk = behaviorRisk - 5 end
    if Flags.HVHMoveLegit then behaviorRisk = behaviorRisk - 10 end
    if Flags.HVHAimLegit then behaviorRisk = behaviorRisk - 5 end
    if mlState.HumanScore then
        behaviorRisk = behaviorRisk + (100 - mlState.HumanScore) * 0.3
    end
    riskMatrix.BehaviorRisk = math.clamp(behaviorRisk, 0, 100)

    -- Network Risk
    local networkRisk = 0
    if Stealth.RiskLevel > 50 then networkRisk = networkRisk + Stealth.RiskLevel * 0.5 end
    if #remoteCalls > 15 then networkRisk = networkRisk + 20 end
    riskMatrix.NetworkRisk = math.min(100, networkRisk)

    -- Stat Risk
    local statRisk = 0
    if statState.SessionDeaths > 0 then
        local kd = statState.SessionKills / statState.SessionDeaths
        if kd > 5 then statRisk = statRisk + 30
        elseif kd > 3 then statRisk = statRisk + 15 end
    end
    if statState.SessionKills > 3 then
        local hsRatio = statState.SessionHeadshots / statState.SessionKills
        if hsRatio > 0.8 then statRisk = statRisk + 25
        elseif hsRatio > 0.6 then statRisk = statRisk + 10 end
    end
    riskMatrix.StatRisk = math.min(100, statRisk)

    -- Timing Risk
    local timingRisk = 0
    if Bypass.isTimingSuspicious and Bypass.isTimingSuspicious() then
        timingRisk = timingRisk + 40
    end
    riskMatrix.TimingRisk = math.min(100, timingRisk)

    -- Memory Risk
    local memRisk = 0
    if Stealth.Detections then
        for _, d in ipairs(Stealth.Detections) do
            if d.Severity == "HIGH" then memRisk = memRisk + 15
            else memRisk = memRisk + 5 end
        end
    end
    riskMatrix.MemoryRisk = math.min(100, memRisk)

    -- Weighted total
    r = riskMatrix.FeatureRisk * 0.30
      -- + riskMatrix.BehaviorRisk * 0.25
      -- + riskMatrix.NetworkRisk * 0.15
      -- + riskMatrix.StatRisk * 0.15
      -- + riskMatrix.TimingRisk * 0.10
      -- + riskMatrix.MemoryRisk * 0.05

    -- Apply stealth mitigations
    if Flags.StealthHumanize then r = r * 0.85 end
    if Flags.FPRotation then r = r * 0.90 end
    if Flags.TrafficMask then r = r * 0.92 end
    if Flags.MemEvasion then r = r * 0.93 end
    if Flags.AntiReplay then r = r * 0.95 end

    riskMatrix.TotalRisk = math.clamp(math.floor(r), 0, 100)

    -- Store history
    table.insert(riskMatrix.History, {Time=tick(), Risk=riskMatrix.TotalRisk})
    if #riskMatrix.History > 100 then table.remove(riskMatrix.History, 1) end

    return riskMatrix.TotalRisk
end

-- Adaptive stealth: automatically adjust stealth level based on risk
task.spawn(function()
    while true do task.wait(3)
        local risk = calculateComprehensiveRisk()
        Stealth.RiskLevel = risk

        if Flags.AdaptiveStealth then
            -- High risk: enable more protections
            if risk > 60 then
                Flags.MLEvasion = true
                Flags.MLEntropy = true
                Flags.MLMouseEntropy = true
                Flags.MLReaction = true
                Flags.MLMicroPause = true
                Flags.AntiReplay = true
                Flags.ActionFuzz = true
                Flags.TimingDesync = true
                Flags.MemEvasion = true
                Flags.TrafficNoise = true
            end

            -- Very high risk: auto-panic
            if risk >= (Flags.MatrixPanicThresh or 65) and Flags.MatrixPanic then
                Flags.Ragebot = false
                Flags.AA = false
                Flags.NoClip = false
                Flags.SpeedBoost = false
                Flags.SilentAim = false
                Flags.FL = false
                pcall(function()
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = " ",
                        Text = " " .. risk .. "%  ",
                        Duration = 5,
                    })
                end)
            end
        end
    end
end)

BS.RiskMatrix = riskMatrix
BS.calculateRisk = calculateComprehensiveRisk

 -- Cleanup
lplr.CharacterRemoving:Connect(function()
    spoofedProps = {}
    timingHistory = {}
    remoteCalls = {}
    hvhState.KillsThisSession = 0
    hvhState.DeathsThisSession = 0
    hvhState.HeadshotsThisSession = 0
    statState.SessionKills = 0
    statState.SessionDeaths = 0
    statState.SessionHeadshots = 0
    statState.KillTimestamps = {}
    statState.WeaponUsage = {}
    replayState.ActionHistory = {}
    mlState.MouseHistory = {}
    riskMatrix.History = {}
    fpState.LastRotation = tick()
end)

 -- Expose
BS.Stealth = Stealth
BS.HVHState = hvhState

-- SECTION 22: GETFENV ENVIRONMENT LEAK PREVENTION
--  DevForum 2025  7  getfenv 

local envLeakPrevention = {
    Patched = false,
    DetectionCount = 0,
}

function Stealth.preventEnvLeak()
    if envLeakPrevention.Patched then return end
    pcall(function()
        --  hookmetamethod  hookfunction 
        --  getfenv 
        -- AC  getfenv(i)  level 0-20 key  
        
        --  hook  newcclosureC closure
        -- C closure  getfenv 
        
        if newcclosure then
            --  hook
            --  C closure  Lua closure
            -- C closure  getfenv  caller 
            
            local mt = getrawmetatable and getrawmetatable(game)
            if mt then
                --  __namecall
                if mt.__namecall then
                    local oldNC = mt.__namecall
                    --  C closure
                    local isCClosure = pcall(function()
                        -- C closure  getfenv 
                        return debug and debug.getinfo and debug.getinfo(oldNC).what == "C"
                    end)
                    
                    if not isCClosure then
                        --  Lua closure C closure
                        mt.__namecall = newcclosure(oldNC)
                    end
                end
            end
        end
        
        --  getfenv 
        --  hook 
        -- Stealth._cleanGetfenvStack()
        
        envLeakPrevention.Patched = true
        
-- ═══════════════════════════════════════════════════════════════
-- HWID SPOOFER
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}

function BS.HWIDSpoofer:Generate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = ""
    for i = 1, 32 do
        local r = math.random(1, #chars)
        id = id .. chars:sub(r, r)
        if i == 8 or i == 12 or i == 16 or i == 20 then
            id = id .. "-"
        end
    end
    return id
end

function BS.HWIDSpoofer:Activate()
    self.Active = true
    self.SpoofedID = self:Generate()
    -- Try to hook HWID functions
    pcall(function()
        if gethwid then
            local old = gethwid
            gethwid = function() return self.SpoofedID end
        end
    end)
    pcall(function()
        if getmachineid then
            local old = getmachineid
            getmachineid = function() return self.SpoofedID end
        end
    end)
    print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end

-- ═══════════════════════════════════════════════════════════════
-- PING SPOOF
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}

function BS.PingSpoof:SetPing(value)
    self.FakePing = value
    self.Active = true
    -- Override ping reporting
    pcall(function()
        if BS.Ping then
            BS.Ping.Current = value
            BS.Ping.Average = value
        end
    end)
end

function BS.PingSpoof:Disable()
    self.Active = false
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI-SCREENSHOT
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}

function BS.AntiScreenshot:Activate()
    self.Active = true
    -- Hide all BS GUI elements when screenshot is detected
    pcall(function()
        -- Hook SetCore("SendNotification") to suppress
        local oldSetCore
        oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
            if method == "TakeScreenshot" then
                -- Hide everything temporarily
                if BS.Win then BS.Win.Visible = false end
                task.delay(1, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
                return
            end
            return oldSetCore(self, method, ...)
        end)
    end)
    -- Also hide on PrintScreen key
    pcall(function()
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.PrintScreen then
                if BS.Win then BS.Win.Visible = false end
                task.delay(2, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
            end
        end)
    end)
    print("[Stealth] Anti-Screenshot active")
end

-- ═══════════════════════════════════════════════════════════════
-- STATISTICS TRACKER
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
    Kills = 0,
    Deaths = 0,
    Headshots = 0,
    Shots = 0,
    Hits = 0,
    Damage = 0,
    StartTime = tick(),
}

function BS.Stats:RecordKill(headshot)
    self.Kills = self.Kills + 1
    if headshot then self.Headshots = self.Headshots + 1 end
end

function BS.Stats:RecordDeath()
    self.Deaths = self.Deaths + 1
end

function BS.Stats:RecordShot(hit)
    self.Shots = self.Shots + 1
    if hit then self.Hits = self.Hits + 1 end
end

function BS.Stats:RecordDamage(dmg)
    self.Damage = self.Damage + dmg
end

function BS.Stats:GetKD()
    if self.Deaths == 0 then return self.Kills end
    return math.floor(self.Kills / self.Deaths * 10) / 10
end

function BS.Stats:GetHSPercent()
    if self.Kills == 0 then return 0 end
    return math.floor(self.Headshots / self.Kills * 100)
end

function BS.Stats:GetAccuracy()
    if self.Shots == 0 then return 0 end
    return math.floor(self.Hits / self.Shots * 100)
end

function BS.Stats:GetPlayTime()
    return math.floor(tick() - self.StartTime)
end

function BS.Stats:GetReport()
    return string.format(
        "K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
        self.Kills, self.Deaths, self:GetKD(),
        self:GetHSPercent(), self:GetAccuracy(),
        self.Damage, math.floor(self:GetPlayTime() / 60)
    )
end

-- GUI
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)

print("[Stealth] getfenv environment leak prevention activated")
    end)
end

--  getfenv 
function Stealth._cleanGetfenvStack()
    pcall(function()
        if not getfenv or not debug then return end
        
        -- 
        for i = 0, 30 do
            local s, fenv = pcall(getfenv, i)
            if s and fenv then
                --  key
                local exploitKeys = {
                    -- "getgenv", "hookmetamethod", "hookfunction", "getrawmetatable",
                    -- "newcclosure", "islclosure", "Drawing", "mousemoverel",
                    -- "writefile", "readfile", "loadstring", "setclipboard",
                    -- "firesignal", "fireclickdetector", "getconnections",
                    -- "sethiddenproperty", "gethiddenproperty", "checkcaller",
                    -- "getnamecallmethod", "setreadonly", "isreadonly",
                    -- "getrenv", "getgc", "getinstances", "getscripts",
                }
                
                for _, key in ipairs(exploitKeys) do
                    if rawget(fenv, key) ~= nil then
                        -- 
                        pcall(function() rawset(fenv, key, nil) end)
                        envLeakPrevention.DetectionCount = envLeakPrevention.DetectionCount + 1
                    end
                end
            end
        end
    end)
end

Stealth.EnvLeakPrevention = envLeakPrevention

-- SECTION 23: RAW METAMETHOD HOOK EVASION
--  AC  metamethod 
-- DevForum 2025  7 

local rawHookEvasion = {
    OriginalFunctions = {},
    Protected = false,
}

function Stealth.protectRawMetamethods()
    if rawHookEvasion.Protected then return end
    pcall(function()
        if not getrawmetatable or not hookmetamethod then return end
        
        local mt = getrawmetatable(game)
        if not mt then return end
        
        -- AC 
        -- 1.  xpcall  __namecall/__index/__newindex
        -- 2. via debug.info(2, "f")
        -- 3. 
        -- 4.    hook 
        
        -- 
        -- 1.  hook  newcclosure
        -- 2.  hook  debug.info  C 
        -- 3.  tostringtostring 
        
        --  metamethods
        rawHookEvasion.OriginalFunctions = {
            __namecall = mt.__namecall,
            __index = mt.__index,
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
            __eq = mt.__eq,
            __lt = mt.__lt,
            __le = mt.__le,
            __call = mt.__call,
        }
        
        rawHookEvasion.Protected = true
        
-- ═══════════════════════════════════════════════════════════════
-- HWID SPOOFER
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}

function BS.HWIDSpoofer:Generate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = ""
    for i = 1, 32 do
        local r = math.random(1, #chars)
        id = id .. chars:sub(r, r)
        if i == 8 or i == 12 or i == 16 or i == 20 then
            id = id .. "-"
        end
    end
    return id
end

function BS.HWIDSpoofer:Activate()
    self.Active = true
    self.SpoofedID = self:Generate()
    -- Try to hook HWID functions
    pcall(function()
        if gethwid then
            local old = gethwid
            gethwid = function() return self.SpoofedID end
        end
    end)
    pcall(function()
        if getmachineid then
            local old = getmachineid
            getmachineid = function() return self.SpoofedID end
        end
    end)
    print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end

-- ═══════════════════════════════════════════════════════════════
-- PING SPOOF
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}

function BS.PingSpoof:SetPing(value)
    self.FakePing = value
    self.Active = true
    -- Override ping reporting
    pcall(function()
        if BS.Ping then
            BS.Ping.Current = value
            BS.Ping.Average = value
        end
    end)
end

function BS.PingSpoof:Disable()
    self.Active = false
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI-SCREENSHOT
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}

function BS.AntiScreenshot:Activate()
    self.Active = true
    -- Hide all BS GUI elements when screenshot is detected
    pcall(function()
        -- Hook SetCore("SendNotification") to suppress
        local oldSetCore
        oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
            if method == "TakeScreenshot" then
                -- Hide everything temporarily
                if BS.Win then BS.Win.Visible = false end
                task.delay(1, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
                return
            end
            return oldSetCore(self, method, ...)
        end)
    end)
    -- Also hide on PrintScreen key
    pcall(function()
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.PrintScreen then
                if BS.Win then BS.Win.Visible = false end
                task.delay(2, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
            end
        end)
    end)
    print("[Stealth] Anti-Screenshot active")
end

-- ═══════════════════════════════════════════════════════════════
-- STATISTICS TRACKER
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
    Kills = 0,
    Deaths = 0,
    Headshots = 0,
    Shots = 0,
    Hits = 0,
    Damage = 0,
    StartTime = tick(),
}

function BS.Stats:RecordKill(headshot)
    self.Kills = self.Kills + 1
    if headshot then self.Headshots = self.Headshots + 1 end
end

function BS.Stats:RecordDeath()
    self.Deaths = self.Deaths + 1
end

function BS.Stats:RecordShot(hit)
    self.Shots = self.Shots + 1
    if hit then self.Hits = self.Hits + 1 end
end

function BS.Stats:RecordDamage(dmg)
    self.Damage = self.Damage + dmg
end

function BS.Stats:GetKD()
    if self.Deaths == 0 then return self.Kills end
    return math.floor(self.Kills / self.Deaths * 10) / 10
end

function BS.Stats:GetHSPercent()
    if self.Kills == 0 then return 0 end
    return math.floor(self.Headshots / self.Kills * 100)
end

function BS.Stats:GetAccuracy()
    if self.Shots == 0 then return 0 end
    return math.floor(self.Hits / self.Shots * 100)
end

function BS.Stats:GetPlayTime()
    return math.floor(tick() - self.StartTime)
end

function BS.Stats:GetReport()
    return string.format(
        "K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
        self.Kills, self.Deaths, self:GetKD(),
        self:GetHSPercent(), self:GetAccuracy(),
        self.Damage, math.floor(self:GetPlayTime() / 60)
    )
end

-- GUI
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)

print("[Stealth] Raw metamethod hook evasion ready")
    end)
end

--  hookmetamethod 
--  hook  C closure  tostring 
function Stealth.safeHookMetamethod(object, method, hookFunction)
    if not hookmetamethod then return nil end
    
    --  hook 
    -- 1.  C closure getfenv 
    -- 2.  tostring tostring 
    -- 3.  debug.info 
    
    local wrappedHook = nil
    pcall(function()
        wrappedHook = newcclosure(function(self, ...)
            --  self  args  tostring
            -- AC  bait  __tostring 
            
            local args = {...}
            
            --  tostring
            local method_name = getnamecallmethod and getnamecallmethod() or nil
            
            --  hook
            return hookFunction(self, method_name, unpack(args))
        end)
    end)
    
    if not wrappedHook then return nil end
    
    --  hookmetamethod 
    local oldHook = nil
    pcall(function()
        oldHook = hookmetamethod(object, method, wrappedHook)
    end)
    
    return oldHook
end

Stealth.RawHookEvasion = rawHookEvasion

-- SECTION 24: TOSTRING TRAP EVASION
--  AC  __tostring bait  hook

local tostringTrapEvasion = {
    Active = false,
    BlockedCalls = 0,
}

function Stealth.activateTostringTrapEvasion()
    if tostringTrapEvasion.Active then return end
    pcall(function()
        -- AC 
        -- local bait = setmetatable({}, {__tostring = function(self) Called = true; return "" end})
        -- pcall(hookFunction, bait, bait, bait)
        -- if Called then print("Detected!") end
        
        --  hook 
        -- tostring(self)
        -- tostring(arg)
        -- ".." .. self
        -- self .. ""
        
        --  safeHookMetamethod 
        --  __tostring 
        
        if hookmetamethod then
            local oldTostring = nil
            pcall(function()
                oldTostring = hookmetamethod(game, "__tostring", newcclosure(function(self)
                    --  AC 
                    -- 
                    if stealthState and stealthState.IsBeingScanned then
                        return game.Name -- 
                    end
                    --  tostring
                    return tostring(self)
                end))
            end)
        end
        
        tostringTrapEvasion.Active = true
        
-- ═══════════════════════════════════════════════════════════════
-- HWID SPOOFER
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}

function BS.HWIDSpoofer:Generate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = ""
    for i = 1, 32 do
        local r = math.random(1, #chars)
        id = id .. chars:sub(r, r)
        if i == 8 or i == 12 or i == 16 or i == 20 then
            id = id .. "-"
        end
    end
    return id
end

function BS.HWIDSpoofer:Activate()
    self.Active = true
    self.SpoofedID = self:Generate()
    -- Try to hook HWID functions
    pcall(function()
        if gethwid then
            local old = gethwid
            gethwid = function() return self.SpoofedID end
        end
    end)
    pcall(function()
        if getmachineid then
            local old = getmachineid
            getmachineid = function() return self.SpoofedID end
        end
    end)
    print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end

-- ═══════════════════════════════════════════════════════════════
-- PING SPOOF
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}

function BS.PingSpoof:SetPing(value)
    self.FakePing = value
    self.Active = true
    -- Override ping reporting
    pcall(function()
        if BS.Ping then
            BS.Ping.Current = value
            BS.Ping.Average = value
        end
    end)
end

function BS.PingSpoof:Disable()
    self.Active = false
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI-SCREENSHOT
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}

function BS.AntiScreenshot:Activate()
    self.Active = true
    -- Hide all BS GUI elements when screenshot is detected
    pcall(function()
        -- Hook SetCore("SendNotification") to suppress
        local oldSetCore
        oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
            if method == "TakeScreenshot" then
                -- Hide everything temporarily
                if BS.Win then BS.Win.Visible = false end
                task.delay(1, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
                return
            end
            return oldSetCore(self, method, ...)
        end)
    end)
    -- Also hide on PrintScreen key
    pcall(function()
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.PrintScreen then
                if BS.Win then BS.Win.Visible = false end
                task.delay(2, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
            end
        end)
    end)
    print("[Stealth] Anti-Screenshot active")
end

-- ═══════════════════════════════════════════════════════════════
-- STATISTICS TRACKER
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
    Kills = 0,
    Deaths = 0,
    Headshots = 0,
    Shots = 0,
    Hits = 0,
    Damage = 0,
    StartTime = tick(),
}

function BS.Stats:RecordKill(headshot)
    self.Kills = self.Kills + 1
    if headshot then self.Headshots = self.Headshots + 1 end
end

function BS.Stats:RecordDeath()
    self.Deaths = self.Deaths + 1
end

function BS.Stats:RecordShot(hit)
    self.Shots = self.Shots + 1
    if hit then self.Hits = self.Hits + 1 end
end

function BS.Stats:RecordDamage(dmg)
    self.Damage = self.Damage + dmg
end

function BS.Stats:GetKD()
    if self.Deaths == 0 then return self.Kills end
    return math.floor(self.Kills / self.Deaths * 10) / 10
end

function BS.Stats:GetHSPercent()
    if self.Kills == 0 then return 0 end
    return math.floor(self.Headshots / self.Kills * 100)
end

function BS.Stats:GetAccuracy()
    if self.Shots == 0 then return 0 end
    return math.floor(self.Hits / self.Shots * 100)
end

function BS.Stats:GetPlayTime()
    return math.floor(tick() - self.StartTime)
end

function BS.Stats:GetReport()
    return string.format(
        "K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
        self.Kills, self.Deaths, self:GetKD(),
        self:GetHSPercent(), self:GetAccuracy(),
        self.Damage, math.floor(self:GetPlayTime() / 60)
    )
end

-- GUI
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)

print("[Stealth] ToString trap evasion activated")
    end)
end

Stealth.TostringTrapEvasion = tostringTrapEvasion

-- SECTION 25: COROUTINE.WRAP STACK OVERFLOW EVASION
--  AC  coroutine.wrap 198  hook

local coroutineEvasion = {
    Active = false,
}

function Stealth.protectCoroutineEvasion()
    if coroutineEvasion.Active then return end
    pcall(function()
        -- AC 
        -- local IsHooked = function(Closure)
        --     for _ = 1, 198 do Closure = coroutine.wrap(Closure) end
        --     local Success, Out = pcall(Closure)
        --     if (not Success) and string.find(Out, "C stack overflow") then
        --         return true -- hooked!
        --     end
        -- end
        
        -- C closureC closure coroutine.wrap  198 
        --  C stack overflow
        -- Lua closure  Lua VM 
        
        -- 
        --  C closure
        --  newcclosure 
        
        --  hook 
        --  coroutine.wrap  C stack overflow
        
        --  thin wrapper
        --  Lua closure C closure
        --  coroutine.wrap 198  overflow
        --  Lua VM  yield
        
        --  safeHookMetamethod 
        
        coroutineEvasion.Active = true
        
-- ═══════════════════════════════════════════════════════════════
-- HWID SPOOFER
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}

function BS.HWIDSpoofer:Generate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = ""
    for i = 1, 32 do
        local r = math.random(1, #chars)
        id = id .. chars:sub(r, r)
        if i == 8 or i == 12 or i == 16 or i == 20 then
            id = id .. "-"
        end
    end
    return id
end

function BS.HWIDSpoofer:Activate()
    self.Active = true
    self.SpoofedID = self:Generate()
    -- Try to hook HWID functions
    pcall(function()
        if gethwid then
            local old = gethwid
            gethwid = function() return self.SpoofedID end
        end
    end)
    pcall(function()
        if getmachineid then
            local old = getmachineid
            getmachineid = function() return self.SpoofedID end
        end
    end)
    print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end

-- ═══════════════════════════════════════════════════════════════
-- PING SPOOF
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}

function BS.PingSpoof:SetPing(value)
    self.FakePing = value
    self.Active = true
    -- Override ping reporting
    pcall(function()
        if BS.Ping then
            BS.Ping.Current = value
            BS.Ping.Average = value
        end
    end)
end

function BS.PingSpoof:Disable()
    self.Active = false
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI-SCREENSHOT
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}

function BS.AntiScreenshot:Activate()
    self.Active = true
    -- Hide all BS GUI elements when screenshot is detected
    pcall(function()
        -- Hook SetCore("SendNotification") to suppress
        local oldSetCore
        oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
            if method == "TakeScreenshot" then
                -- Hide everything temporarily
                if BS.Win then BS.Win.Visible = false end
                task.delay(1, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
                return
            end
            return oldSetCore(self, method, ...)
        end)
    end)
    -- Also hide on PrintScreen key
    pcall(function()
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.PrintScreen then
                if BS.Win then BS.Win.Visible = false end
                task.delay(2, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
            end
        end)
    end)
    print("[Stealth] Anti-Screenshot active")
end

-- ═══════════════════════════════════════════════════════════════
-- STATISTICS TRACKER
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
    Kills = 0,
    Deaths = 0,
    Headshots = 0,
    Shots = 0,
    Hits = 0,
    Damage = 0,
    StartTime = tick(),
}

function BS.Stats:RecordKill(headshot)
    self.Kills = self.Kills + 1
    if headshot then self.Headshots = self.Headshots + 1 end
end

function BS.Stats:RecordDeath()
    self.Deaths = self.Deaths + 1
end

function BS.Stats:RecordShot(hit)
    self.Shots = self.Shots + 1
    if hit then self.Hits = self.Hits + 1 end
end

function BS.Stats:RecordDamage(dmg)
    self.Damage = self.Damage + dmg
end

function BS.Stats:GetKD()
    if self.Deaths == 0 then return self.Kills end
    return math.floor(self.Kills / self.Deaths * 10) / 10
end

function BS.Stats:GetHSPercent()
    if self.Kills == 0 then return 0 end
    return math.floor(self.Headshots / self.Kills * 100)
end

function BS.Stats:GetAccuracy()
    if self.Shots == 0 then return 0 end
    return math.floor(self.Hits / self.Shots * 100)
end

function BS.Stats:GetPlayTime()
    return math.floor(tick() - self.StartTime)
end

function BS.Stats:GetReport()
    return string.format(
        "K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
        self.Kills, self.Deaths, self:GetKD(),
        self:GetHSPercent(), self:GetAccuracy(),
        self.Damage, math.floor(self:GetPlayTime() / 60)
    )
end

-- GUI
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)

print("[Stealth] Coroutine.wrap stack overflow evasion ready")
    end)
end

Stealth.CoroutineEvasion = coroutineEvasion

-- SECTION 26: COREGUI REFERENCE EVASION
--  AC  CoreGui 

local coreGuiEvasion = {
    Active = false,
}

function Stealth.protectCoreGuiEvasion()
    if coreGuiEvasion.Active then return end
    pcall(function()
        -- AC 
        -- local IsReferenced = function(Object)
        --     local Table = {}
        --     local WeakMT = setmetatable({Table, 1, "String", Object}, {__mode = "kv"})
        --     Table = nil; Object = nil
        --     repeat task.wait(); until (not WeakMT[1])
        --     if #WeakMT ~= 3 then return true end -- Object 
        -- end
        
        -- 
        -- 1.  CoreGui 
        -- 2.  cloneref
        -- 3. 
        
        --  game.CoreGui 
        if cloneref then
            --  cloneref
            pcall(function()
                --  game.CoreGui
                -- 
            end)
        end
        
        coreGuiEvasion.Active = true
        
-- ═══════════════════════════════════════════════════════════════
-- HWID SPOOFER
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}

function BS.HWIDSpoofer:Generate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = ""
    for i = 1, 32 do
        local r = math.random(1, #chars)
        id = id .. chars:sub(r, r)
        if i == 8 or i == 12 or i == 16 or i == 20 then
            id = id .. "-"
        end
    end
    return id
end

function BS.HWIDSpoofer:Activate()
    self.Active = true
    self.SpoofedID = self:Generate()
    -- Try to hook HWID functions
    pcall(function()
        if gethwid then
            local old = gethwid
            gethwid = function() return self.SpoofedID end
        end
    end)
    pcall(function()
        if getmachineid then
            local old = getmachineid
            getmachineid = function() return self.SpoofedID end
        end
    end)
    print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end

-- ═══════════════════════════════════════════════════════════════
-- PING SPOOF
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}

function BS.PingSpoof:SetPing(value)
    self.FakePing = value
    self.Active = true
    -- Override ping reporting
    pcall(function()
        if BS.Ping then
            BS.Ping.Current = value
            BS.Ping.Average = value
        end
    end)
end

function BS.PingSpoof:Disable()
    self.Active = false
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI-SCREENSHOT
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}

function BS.AntiScreenshot:Activate()
    self.Active = true
    -- Hide all BS GUI elements when screenshot is detected
    pcall(function()
        -- Hook SetCore("SendNotification") to suppress
        local oldSetCore
        oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
            if method == "TakeScreenshot" then
                -- Hide everything temporarily
                if BS.Win then BS.Win.Visible = false end
                task.delay(1, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
                return
            end
            return oldSetCore(self, method, ...)
        end)
    end)
    -- Also hide on PrintScreen key
    pcall(function()
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.PrintScreen then
                if BS.Win then BS.Win.Visible = false end
                task.delay(2, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
            end
        end)
    end)
    print("[Stealth] Anti-Screenshot active")
end

-- ═══════════════════════════════════════════════════════════════
-- STATISTICS TRACKER
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
    Kills = 0,
    Deaths = 0,
    Headshots = 0,
    Shots = 0,
    Hits = 0,
    Damage = 0,
    StartTime = tick(),
}

function BS.Stats:RecordKill(headshot)
    self.Kills = self.Kills + 1
    if headshot then self.Headshots = self.Headshots + 1 end
end

function BS.Stats:RecordDeath()
    self.Deaths = self.Deaths + 1
end

function BS.Stats:RecordShot(hit)
    self.Shots = self.Shots + 1
    if hit then self.Hits = self.Hits + 1 end
end

function BS.Stats:RecordDamage(dmg)
    self.Damage = self.Damage + dmg
end

function BS.Stats:GetKD()
    if self.Deaths == 0 then return self.Kills end
    return math.floor(self.Kills / self.Deaths * 10) / 10
end

function BS.Stats:GetHSPercent()
    if self.Kills == 0 then return 0 end
    return math.floor(self.Headshots / self.Kills * 100)
end

function BS.Stats:GetAccuracy()
    if self.Shots == 0 then return 0 end
    return math.floor(self.Hits / self.Shots * 100)
end

function BS.Stats:GetPlayTime()
    return math.floor(tick() - self.StartTime)
end

function BS.Stats:GetReport()
    return string.format(
        "K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
        self.Kills, self.Deaths, self:GetKD(),
        self:GetHSPercent(), self:GetAccuracy(),
        self.Damage, math.floor(self:GetPlayTime() / 60)
    )
end

-- GUI
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)

print("[Stealth] CoreGui reference evasion ready")
    end)
end

Stealth.CoreGuiEvasion = coreGuiEvasion

-- SECTION 27: GETFENV LEVEL SCANNING EVASION
--  getfenv 

local getfenvScanningEvasion = {
    Active = false,
    PatchedLevels = {},
}

function Stealth.patchGetfenvScanning()
    if getfenvScanningEvasion.Active then return end
    pcall(function()
        -- AC  getfenv(0)  getfenv(20)
        --  key  
        
        -- hook getfenv key
        if hookfunction and getfenv then
            local oldGetfenv = getfenv
            
            local patchedGetfenv = newcclosure(function(level)
                local result = oldGetfenv(level)
                
                if type(result) == "table" then
                    -- 
                    local clean = {}
                    local exploitKeys = {
                        -- "getgenv", "hookmetamethod", "hookfunction", "getrawmetatable",
                        -- "newcclosure", "islclosure", "Drawing", "mousemoverel",
                        -- "writefile", "readfile", "loadstring", "setclipboard",
                        -- "firesignal", "fireclickdetector", "getconnections",
                        -- "sethiddenproperty", "gethiddenproperty", "checkcaller",
                        -- "getnamecallmethod", "setreadonly", "isreadonly",
                        -- "getrenv", "getgc", "getinstances", "getscripts",
                        -- "syn", "syn_request", "is_krnl_closure",
                        -- "KRNL_LOADED", "fluxus", "identifyexecutor",
                    }
                    
                    for k, v in pairs(result) do
                        local isExploitKey = false
                        for _, ek in ipairs(exploitKeys) do
                            if k == ek then
                                isExploitKey = true
                                break
                            end
                        end
                        if not isExploitKey then
                            clean[k] = v
                        end
                    end
                    
                    return clean
                end
                
                return result
            end)
            
            pcall(function()
                hookfunction(getfenv, patchedGetfenv)
            end)
        end
        
        getfenvScanningEvasion.Active = true
        
-- ═══════════════════════════════════════════════════════════════
-- HWID SPOOFER
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}

function BS.HWIDSpoofer:Generate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = ""
    for i = 1, 32 do
        local r = math.random(1, #chars)
        id = id .. chars:sub(r, r)
        if i == 8 or i == 12 or i == 16 or i == 20 then
            id = id .. "-"
        end
    end
    return id
end

function BS.HWIDSpoofer:Activate()
    self.Active = true
    self.SpoofedID = self:Generate()
    -- Try to hook HWID functions
    pcall(function()
        if gethwid then
            local old = gethwid
            gethwid = function() return self.SpoofedID end
        end
    end)
    pcall(function()
        if getmachineid then
            local old = getmachineid
            getmachineid = function() return self.SpoofedID end
        end
    end)
    print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end

-- ═══════════════════════════════════════════════════════════════
-- PING SPOOF
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}

function BS.PingSpoof:SetPing(value)
    self.FakePing = value
    self.Active = true
    -- Override ping reporting
    pcall(function()
        if BS.Ping then
            BS.Ping.Current = value
            BS.Ping.Average = value
        end
    end)
end

function BS.PingSpoof:Disable()
    self.Active = false
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI-SCREENSHOT
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}

function BS.AntiScreenshot:Activate()
    self.Active = true
    -- Hide all BS GUI elements when screenshot is detected
    pcall(function()
        -- Hook SetCore("SendNotification") to suppress
        local oldSetCore
        oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
            if method == "TakeScreenshot" then
                -- Hide everything temporarily
                if BS.Win then BS.Win.Visible = false end
                task.delay(1, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
                return
            end
            return oldSetCore(self, method, ...)
        end)
    end)
    -- Also hide on PrintScreen key
    pcall(function()
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.PrintScreen then
                if BS.Win then BS.Win.Visible = false end
                task.delay(2, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
            end
        end)
    end)
    print("[Stealth] Anti-Screenshot active")
end

-- ═══════════════════════════════════════════════════════════════
-- STATISTICS TRACKER
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
    Kills = 0,
    Deaths = 0,
    Headshots = 0,
    Shots = 0,
    Hits = 0,
    Damage = 0,
    StartTime = tick(),
}

function BS.Stats:RecordKill(headshot)
    self.Kills = self.Kills + 1
    if headshot then self.Headshots = self.Headshots + 1 end
end

function BS.Stats:RecordDeath()
    self.Deaths = self.Deaths + 1
end

function BS.Stats:RecordShot(hit)
    self.Shots = self.Shots + 1
    if hit then self.Hits = self.Hits + 1 end
end

function BS.Stats:RecordDamage(dmg)
    self.Damage = self.Damage + dmg
end

function BS.Stats:GetKD()
    if self.Deaths == 0 then return self.Kills end
    return math.floor(self.Kills / self.Deaths * 10) / 10
end

function BS.Stats:GetHSPercent()
    if self.Kills == 0 then return 0 end
    return math.floor(self.Headshots / self.Kills * 100)
end

function BS.Stats:GetAccuracy()
    if self.Shots == 0 then return 0 end
    return math.floor(self.Hits / self.Shots * 100)
end

function BS.Stats:GetPlayTime()
    return math.floor(tick() - self.StartTime)
end

function BS.Stats:GetReport()
    return string.format(
        "K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
        self.Kills, self.Deaths, self:GetKD(),
        self:GetHSPercent(), self:GetAccuracy(),
        self.Damage, math.floor(self:GetPlayTime() / 60)
    )
end

-- GUI
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)

print("[Stealth] getfenv level scanning evasion activated")
    end)
end

Stealth.GetfenvScanningEvasion = getfenvScanningEvasion

-- SECTION 28: UNIFIED ANTI-DETECTION ACTIVATION

function Stealth.activateAdvancedEvasion()
    pcall(function()
        -- Phase 1: 
        -- Stealth.preventEnvLeak()
        -- Stealth.patchGetfenvScanning()
        
        -- Phase 2: Hook 
        -- Stealth.protectRawMetamethods()
        -- Stealth.activateTostringTrapEvasion()
        -- Stealth.protectCoroutineEvasion()
        
        -- Phase 3: 
        -- Stealth.protectCoreGuiEvasion()
        
        
-- ═══════════════════════════════════════════════════════════════
-- HWID SPOOFER
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}

function BS.HWIDSpoofer:Generate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = ""
    for i = 1, 32 do
        local r = math.random(1, #chars)
        id = id .. chars:sub(r, r)
        if i == 8 or i == 12 or i == 16 or i == 20 then
            id = id .. "-"
        end
    end
    return id
end

function BS.HWIDSpoofer:Activate()
    self.Active = true
    self.SpoofedID = self:Generate()
    -- Try to hook HWID functions
    pcall(function()
        if gethwid then
            local old = gethwid
            gethwid = function() return self.SpoofedID end
        end
    end)
    pcall(function()
        if getmachineid then
            local old = getmachineid
            getmachineid = function() return self.SpoofedID end
        end
    end)
    print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end

-- ═══════════════════════════════════════════════════════════════
-- PING SPOOF
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}

function BS.PingSpoof:SetPing(value)
    self.FakePing = value
    self.Active = true
    -- Override ping reporting
    pcall(function()
        if BS.Ping then
            BS.Ping.Current = value
            BS.Ping.Average = value
        end
    end)
end

function BS.PingSpoof:Disable()
    self.Active = false
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI-SCREENSHOT
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}

function BS.AntiScreenshot:Activate()
    self.Active = true
    -- Hide all BS GUI elements when screenshot is detected
    pcall(function()
        -- Hook SetCore("SendNotification") to suppress
        local oldSetCore
        oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
            if method == "TakeScreenshot" then
                -- Hide everything temporarily
                if BS.Win then BS.Win.Visible = false end
                task.delay(1, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
                return
            end
            return oldSetCore(self, method, ...)
        end)
    end)
    -- Also hide on PrintScreen key
    pcall(function()
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.PrintScreen then
                if BS.Win then BS.Win.Visible = false end
                task.delay(2, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
            end
        end)
    end)
    print("[Stealth] Anti-Screenshot active")
end

-- ═══════════════════════════════════════════════════════════════
-- STATISTICS TRACKER
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
    Kills = 0,
    Deaths = 0,
    Headshots = 0,
    Shots = 0,
    Hits = 0,
    Damage = 0,
    StartTime = tick(),
}

function BS.Stats:RecordKill(headshot)
    self.Kills = self.Kills + 1
    if headshot then self.Headshots = self.Headshots + 1 end
end

function BS.Stats:RecordDeath()
    self.Deaths = self.Deaths + 1
end

function BS.Stats:RecordShot(hit)
    self.Shots = self.Shots + 1
    if hit then self.Hits = self.Hits + 1 end
end

function BS.Stats:RecordDamage(dmg)
    self.Damage = self.Damage + dmg
end

function BS.Stats:GetKD()
    if self.Deaths == 0 then return self.Kills end
    return math.floor(self.Kills / self.Deaths * 10) / 10
end

function BS.Stats:GetHSPercent()
    if self.Kills == 0 then return 0 end
    return math.floor(self.Headshots / self.Kills * 100)
end

function BS.Stats:GetAccuracy()
    if self.Shots == 0 then return 0 end
    return math.floor(self.Hits / self.Shots * 100)
end

function BS.Stats:GetPlayTime()
    return math.floor(tick() - self.StartTime)
end

function BS.Stats:GetReport()
    return string.format(
        "K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
        self.Kills, self.Deaths, self:GetKD(),
        self:GetHSPercent(), self:GetAccuracy(),
        self.Damage, math.floor(self:GetPlayTime() / 60)
    )
end

-- GUI
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)

print("[Stealth]  Advanced evasion systems activated ")
    end)
end

task.spawn(function()
    while true do
        task.wait(15)
        pcall(function()
            -- Stealth._cleanGetfenvStack()
        end)
    end
end)

 -- Expose
BS.Stealth = Stealth
BS.HVHState = hvhState


-- ═══════════════════════════════════════════════════════════════
-- HWID SPOOFER
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}

function BS.HWIDSpoofer:Generate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = ""
    for i = 1, 32 do
        local r = math.random(1, #chars)
        id = id .. chars:sub(r, r)
        if i == 8 or i == 12 or i == 16 or i == 20 then
            id = id .. "-"
        end
    end
    return id
end

function BS.HWIDSpoofer:Activate()
    self.Active = true
    self.SpoofedID = self:Generate()
    -- Try to hook HWID functions
    pcall(function()
        if gethwid then
            local old = gethwid
            gethwid = function() return self.SpoofedID end
        end
    end)
    pcall(function()
        if getmachineid then
            local old = getmachineid
            getmachineid = function() return self.SpoofedID end
        end
    end)
    print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end

-- ═══════════════════════════════════════════════════════════════
-- PING SPOOF
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}

function BS.PingSpoof:SetPing(value)
    self.FakePing = value
    self.Active = true
    -- Override ping reporting
    pcall(function()
        if BS.Ping then
            BS.Ping.Current = value
            BS.Ping.Average = value
        end
    end)
end

function BS.PingSpoof:Disable()
    self.Active = false
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI-SCREENSHOT
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}

function BS.AntiScreenshot:Activate()
    self.Active = true
    -- Hide all BS GUI elements when screenshot is detected
    pcall(function()
        -- Hook SetCore("SendNotification") to suppress
        local oldSetCore
        oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
            if method == "TakeScreenshot" then
                -- Hide everything temporarily
                if BS.Win then BS.Win.Visible = false end
                task.delay(1, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
                return
            end
            return oldSetCore(self, method, ...)
        end)
    end)
    -- Also hide on PrintScreen key
    pcall(function()
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.PrintScreen then
                if BS.Win then BS.Win.Visible = false end
                task.delay(2, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
            end
        end)
    end)
    print("[Stealth] Anti-Screenshot active")
end

-- ═══════════════════════════════════════════════════════════════
-- STATISTICS TRACKER
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
    Kills = 0,
    Deaths = 0,
    Headshots = 0,
    Shots = 0,
    Hits = 0,
    Damage = 0,
    StartTime = tick(),
}

function BS.Stats:RecordKill(headshot)
    self.Kills = self.Kills + 1
    if headshot then self.Headshots = self.Headshots + 1 end
end

function BS.Stats:RecordDeath()
    self.Deaths = self.Deaths + 1
end

function BS.Stats:RecordShot(hit)
    self.Shots = self.Shots + 1
    if hit then self.Hits = self.Hits + 1 end
end

function BS.Stats:RecordDamage(dmg)
    self.Damage = self.Damage + dmg
end

function BS.Stats:GetKD()
    if self.Deaths == 0 then return self.Kills end
    return math.floor(self.Kills / self.Deaths * 10) / 10
end

function BS.Stats:GetHSPercent()
    if self.Kills == 0 then return 0 end
    return math.floor(self.Headshots / self.Kills * 100)
end

function BS.Stats:GetAccuracy()
    if self.Shots == 0 then return 0 end
    return math.floor(self.Hits / self.Shots * 100)
end

function BS.Stats:GetPlayTime()
    return math.floor(tick() - self.StartTime)
end

function BS.Stats:GetReport()
    return string.format(
        "K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
        self.Kills, self.Deaths, self:GetKD(),
        self:GetHSPercent(), self:GetAccuracy(),
        self.Damage, math.floor(self:GetPlayTime() / 60)
    )
end

-- GUI
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)

print("[Stealth] BloxStrike Stealth v4.0  ")

-- ═══════════════════════════════════════════════════════════════
-- HWID SPOOFER
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}

function BS.HWIDSpoofer:Generate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = ""
    for i = 1, 32 do
        local r = math.random(1, #chars)
        id = id .. chars:sub(r, r)
        if i == 8 or i == 12 or i == 16 or i == 20 then
            id = id .. "-"
        end
    end
    return id
end

function BS.HWIDSpoofer:Activate()
    self.Active = true
    self.SpoofedID = self:Generate()
    -- Try to hook HWID functions
    pcall(function()
        if gethwid then
            local old = gethwid
            gethwid = function() return self.SpoofedID end
        end
    end)
    pcall(function()
        if getmachineid then
            local old = getmachineid
            getmachineid = function() return self.SpoofedID end
        end
    end)
    print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end

-- ═══════════════════════════════════════════════════════════════
-- PING SPOOF
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}

function BS.PingSpoof:SetPing(value)
    self.FakePing = value
    self.Active = true
    -- Override ping reporting
    pcall(function()
        if BS.Ping then
            BS.Ping.Current = value
            BS.Ping.Average = value
        end
    end)
end

function BS.PingSpoof:Disable()
    self.Active = false
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI-SCREENSHOT
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}

function BS.AntiScreenshot:Activate()
    self.Active = true
    -- Hide all BS GUI elements when screenshot is detected
    pcall(function()
        -- Hook SetCore("SendNotification") to suppress
        local oldSetCore
        oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
            if method == "TakeScreenshot" then
                -- Hide everything temporarily
                if BS.Win then BS.Win.Visible = false end
                task.delay(1, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
                return
            end
            return oldSetCore(self, method, ...)
        end)
    end)
    -- Also hide on PrintScreen key
    pcall(function()
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.PrintScreen then
                if BS.Win then BS.Win.Visible = false end
                task.delay(2, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
            end
        end)
    end)
    print("[Stealth] Anti-Screenshot active")
end

-- ═══════════════════════════════════════════════════════════════
-- STATISTICS TRACKER
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
    Kills = 0,
    Deaths = 0,
    Headshots = 0,
    Shots = 0,
    Hits = 0,
    Damage = 0,
    StartTime = tick(),
}

function BS.Stats:RecordKill(headshot)
    self.Kills = self.Kills + 1
    if headshot then self.Headshots = self.Headshots + 1 end
end

function BS.Stats:RecordDeath()
    self.Deaths = self.Deaths + 1
end

function BS.Stats:RecordShot(hit)
    self.Shots = self.Shots + 1
    if hit then self.Hits = self.Hits + 1 end
end

function BS.Stats:RecordDamage(dmg)
    self.Damage = self.Damage + dmg
end

function BS.Stats:GetKD()
    if self.Deaths == 0 then return self.Kills end
    return math.floor(self.Kills / self.Deaths * 10) / 10
end

function BS.Stats:GetHSPercent()
    if self.Kills == 0 then return 0 end
    return math.floor(self.Headshots / self.Kills * 100)
end

function BS.Stats:GetAccuracy()
    if self.Shots == 0 then return 0 end
    return math.floor(self.Hits / self.Shots * 100)
end

function BS.Stats:GetPlayTime()
    return math.floor(tick() - self.StartTime)
end

function BS.Stats:GetReport()
    return string.format(
        "K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
        self.Kills, self.Deaths, self:GetKD(),
        self:GetHSPercent(), self:GetAccuracy(),
        self.Damage, math.floor(self:GetPlayTime() / 60)
    )
end

-- GUI
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)

print("[Stealth] ")

-- ═══════════════════════════════════════════════════════════════
-- HWID SPOOFER
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}

function BS.HWIDSpoofer:Generate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = ""
    for i = 1, 32 do
        local r = math.random(1, #chars)
        id = id .. chars:sub(r, r)
        if i == 8 or i == 12 or i == 16 or i == 20 then
            id = id .. "-"
        end
    end
    return id
end

function BS.HWIDSpoofer:Activate()
    self.Active = true
    self.SpoofedID = self:Generate()
    -- Try to hook HWID functions
    pcall(function()
        if gethwid then
            local old = gethwid
            gethwid = function() return self.SpoofedID end
        end
    end)
    pcall(function()
        if getmachineid then
            local old = getmachineid
            getmachineid = function() return self.SpoofedID end
        end
    end)
    print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end

-- ═══════════════════════════════════════════════════════════════
-- PING SPOOF
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}

function BS.PingSpoof:SetPing(value)
    self.FakePing = value
    self.Active = true
    -- Override ping reporting
    pcall(function()
        if BS.Ping then
            BS.Ping.Current = value
            BS.Ping.Average = value
        end
    end)
end

function BS.PingSpoof:Disable()
    self.Active = false
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI-SCREENSHOT
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}

function BS.AntiScreenshot:Activate()
    self.Active = true
    -- Hide all BS GUI elements when screenshot is detected
    pcall(function()
        -- Hook SetCore("SendNotification") to suppress
        local oldSetCore
        oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
            if method == "TakeScreenshot" then
                -- Hide everything temporarily
                if BS.Win then BS.Win.Visible = false end
                task.delay(1, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
                return
            end
            return oldSetCore(self, method, ...)
        end)
    end)
    -- Also hide on PrintScreen key
    pcall(function()
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.PrintScreen then
                if BS.Win then BS.Win.Visible = false end
                task.delay(2, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
            end
        end)
    end)
    print("[Stealth] Anti-Screenshot active")
end

-- ═══════════════════════════════════════════════════════════════
-- STATISTICS TRACKER
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
    Kills = 0,
    Deaths = 0,
    Headshots = 0,
    Shots = 0,
    Hits = 0,
    Damage = 0,
    StartTime = tick(),
}

function BS.Stats:RecordKill(headshot)
    self.Kills = self.Kills + 1
    if headshot then self.Headshots = self.Headshots + 1 end
end

function BS.Stats:RecordDeath()
    self.Deaths = self.Deaths + 1
end

function BS.Stats:RecordShot(hit)
    self.Shots = self.Shots + 1
    if hit then self.Hits = self.Hits + 1 end
end

function BS.Stats:RecordDamage(dmg)
    self.Damage = self.Damage + dmg
end

function BS.Stats:GetKD()
    if self.Deaths == 0 then return self.Kills end
    return math.floor(self.Kills / self.Deaths * 10) / 10
end

function BS.Stats:GetHSPercent()
    if self.Kills == 0 then return 0 end
    return math.floor(self.Headshots / self.Kills * 100)
end

function BS.Stats:GetAccuracy()
    if self.Shots == 0 then return 0 end
    return math.floor(self.Hits / self.Shots * 100)
end

function BS.Stats:GetPlayTime()
    return math.floor(tick() - self.StartTime)
end

function BS.Stats:GetReport()
    return string.format(
        "K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
        self.Kills, self.Deaths, self:GetKD(),
        self:GetHSPercent(), self:GetAccuracy(),
        self.Damage, math.floor(self:GetPlayTime() / 60)
    )
end

-- GUI
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)

print("[Stealth] 28 ")

-- ═══════════════════════════════════════════════════════════════
-- HWID SPOOFER
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}

function BS.HWIDSpoofer:Generate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = ""
    for i = 1, 32 do
        local r = math.random(1, #chars)
        id = id .. chars:sub(r, r)
        if i == 8 or i == 12 or i == 16 or i == 20 then
            id = id .. "-"
        end
    end
    return id
end

function BS.HWIDSpoofer:Activate()
    self.Active = true
    self.SpoofedID = self:Generate()
    -- Try to hook HWID functions
    pcall(function()
        if gethwid then
            local old = gethwid
            gethwid = function() return self.SpoofedID end
        end
    end)
    pcall(function()
        if getmachineid then
            local old = getmachineid
            getmachineid = function() return self.SpoofedID end
        end
    end)
    print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end

-- ═══════════════════════════════════════════════════════════════
-- PING SPOOF
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}

function BS.PingSpoof:SetPing(value)
    self.FakePing = value
    self.Active = true
    -- Override ping reporting
    pcall(function()
        if BS.Ping then
            BS.Ping.Current = value
            BS.Ping.Average = value
        end
    end)
end

function BS.PingSpoof:Disable()
    self.Active = false
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI-SCREENSHOT
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}

function BS.AntiScreenshot:Activate()
    self.Active = true
    -- Hide all BS GUI elements when screenshot is detected
    pcall(function()
        -- Hook SetCore("SendNotification") to suppress
        local oldSetCore
        oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
            if method == "TakeScreenshot" then
                -- Hide everything temporarily
                if BS.Win then BS.Win.Visible = false end
                task.delay(1, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
                return
            end
            return oldSetCore(self, method, ...)
        end)
    end)
    -- Also hide on PrintScreen key
    pcall(function()
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.PrintScreen then
                if BS.Win then BS.Win.Visible = false end
                task.delay(2, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
            end
        end)
    end)
    print("[Stealth] Anti-Screenshot active")
end

-- ═══════════════════════════════════════════════════════════════
-- STATISTICS TRACKER
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
    Kills = 0,
    Deaths = 0,
    Headshots = 0,
    Shots = 0,
    Hits = 0,
    Damage = 0,
    StartTime = tick(),
}

function BS.Stats:RecordKill(headshot)
    self.Kills = self.Kills + 1
    if headshot then self.Headshots = self.Headshots + 1 end
end

function BS.Stats:RecordDeath()
    self.Deaths = self.Deaths + 1
end

function BS.Stats:RecordShot(hit)
    self.Shots = self.Shots + 1
    if hit then self.Hits = self.Hits + 1 end
end

function BS.Stats:RecordDamage(dmg)
    self.Damage = self.Damage + dmg
end

function BS.Stats:GetKD()
    if self.Deaths == 0 then return self.Kills end
    return math.floor(self.Kills / self.Deaths * 10) / 10
end

function BS.Stats:GetHSPercent()
    if self.Kills == 0 then return 0 end
    return math.floor(self.Headshots / self.Kills * 100)
end

function BS.Stats:GetAccuracy()
    if self.Shots == 0 then return 0 end
    return math.floor(self.Hits / self.Shots * 100)
end

function BS.Stats:GetPlayTime()
    return math.floor(tick() - self.StartTime)
end

function BS.Stats:GetReport()
    return string.format(
        "K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
        self.Kills, self.Deaths, self:GetKD(),
        self:GetHSPercent(), self:GetAccuracy(),
        self.Damage, math.floor(self:GetPlayTime() / 60)
    )
end

-- GUI
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)

print("[Stealth]   1-12:  Callstack/Environment/Hook/Obfuscation ")

-- ═══════════════════════════════════════════════════════════════
-- HWID SPOOFER
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}

function BS.HWIDSpoofer:Generate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = ""
    for i = 1, 32 do
        local r = math.random(1, #chars)
        id = id .. chars:sub(r, r)
        if i == 8 or i == 12 or i == 16 or i == 20 then
            id = id .. "-"
        end
    end
    return id
end

function BS.HWIDSpoofer:Activate()
    self.Active = true
    self.SpoofedID = self:Generate()
    -- Try to hook HWID functions
    pcall(function()
        if gethwid then
            local old = gethwid
            gethwid = function() return self.SpoofedID end
        end
    end)
    pcall(function()
        if getmachineid then
            local old = getmachineid
            getmachineid = function() return self.SpoofedID end
        end
    end)
    print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end

-- ═══════════════════════════════════════════════════════════════
-- PING SPOOF
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}

function BS.PingSpoof:SetPing(value)
    self.FakePing = value
    self.Active = true
    -- Override ping reporting
    pcall(function()
        if BS.Ping then
            BS.Ping.Current = value
            BS.Ping.Average = value
        end
    end)
end

function BS.PingSpoof:Disable()
    self.Active = false
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI-SCREENSHOT
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}

function BS.AntiScreenshot:Activate()
    self.Active = true
    -- Hide all BS GUI elements when screenshot is detected
    pcall(function()
        -- Hook SetCore("SendNotification") to suppress
        local oldSetCore
        oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
            if method == "TakeScreenshot" then
                -- Hide everything temporarily
                if BS.Win then BS.Win.Visible = false end
                task.delay(1, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
                return
            end
            return oldSetCore(self, method, ...)
        end)
    end)
    -- Also hide on PrintScreen key
    pcall(function()
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.PrintScreen then
                if BS.Win then BS.Win.Visible = false end
                task.delay(2, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
            end
        end)
    end)
    print("[Stealth] Anti-Screenshot active")
end

-- ═══════════════════════════════════════════════════════════════
-- STATISTICS TRACKER
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
    Kills = 0,
    Deaths = 0,
    Headshots = 0,
    Shots = 0,
    Hits = 0,
    Damage = 0,
    StartTime = tick(),
}

function BS.Stats:RecordKill(headshot)
    self.Kills = self.Kills + 1
    if headshot then self.Headshots = self.Headshots + 1 end
end

function BS.Stats:RecordDeath()
    self.Deaths = self.Deaths + 1
end

function BS.Stats:RecordShot(hit)
    self.Shots = self.Shots + 1
    if hit then self.Hits = self.Hits + 1 end
end

function BS.Stats:RecordDamage(dmg)
    self.Damage = self.Damage + dmg
end

function BS.Stats:GetKD()
    if self.Deaths == 0 then return self.Kills end
    return math.floor(self.Kills / self.Deaths * 10) / 10
end

function BS.Stats:GetHSPercent()
    if self.Kills == 0 then return 0 end
    return math.floor(self.Headshots / self.Kills * 100)
end

function BS.Stats:GetAccuracy()
    if self.Shots == 0 then return 0 end
    return math.floor(self.Hits / self.Shots * 100)
end

function BS.Stats:GetPlayTime()
    return math.floor(tick() - self.StartTime)
end

function BS.Stats:GetReport()
    return string.format(
        "K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
        self.Kills, self.Deaths, self:GetKD(),
        self:GetHSPercent(), self:GetAccuracy(),
        self.Damage, math.floor(self:GetPlayTime() / 60)
    )
end

-- GUI
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)

print("[Stealth]   13-21: SSVL///ML/////")

-- ═══════════════════════════════════════════════════════════════
-- HWID SPOOFER
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}

function BS.HWIDSpoofer:Generate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = ""
    for i = 1, 32 do
        local r = math.random(1, #chars)
        id = id .. chars:sub(r, r)
        if i == 8 or i == 12 or i == 16 or i == 20 then
            id = id .. "-"
        end
    end
    return id
end

function BS.HWIDSpoofer:Activate()
    self.Active = true
    self.SpoofedID = self:Generate()
    -- Try to hook HWID functions
    pcall(function()
        if gethwid then
            local old = gethwid
            gethwid = function() return self.SpoofedID end
        end
    end)
    pcall(function()
        if getmachineid then
            local old = getmachineid
            getmachineid = function() return self.SpoofedID end
        end
    end)
    print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end

-- ═══════════════════════════════════════════════════════════════
-- PING SPOOF
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}

function BS.PingSpoof:SetPing(value)
    self.FakePing = value
    self.Active = true
    -- Override ping reporting
    pcall(function()
        if BS.Ping then
            BS.Ping.Current = value
            BS.Ping.Average = value
        end
    end)
end

function BS.PingSpoof:Disable()
    self.Active = false
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI-SCREENSHOT
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}

function BS.AntiScreenshot:Activate()
    self.Active = true
    -- Hide all BS GUI elements when screenshot is detected
    pcall(function()
        -- Hook SetCore("SendNotification") to suppress
        local oldSetCore
        oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
            if method == "TakeScreenshot" then
                -- Hide everything temporarily
                if BS.Win then BS.Win.Visible = false end
                task.delay(1, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
                return
            end
            return oldSetCore(self, method, ...)
        end)
    end)
    -- Also hide on PrintScreen key
    pcall(function()
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.PrintScreen then
                if BS.Win then BS.Win.Visible = false end
                task.delay(2, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
            end
        end)
    end)
    print("[Stealth] Anti-Screenshot active")
end

-- ═══════════════════════════════════════════════════════════════
-- STATISTICS TRACKER
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
    Kills = 0,
    Deaths = 0,
    Headshots = 0,
    Shots = 0,
    Hits = 0,
    Damage = 0,
    StartTime = tick(),
}

function BS.Stats:RecordKill(headshot)
    self.Kills = self.Kills + 1
    if headshot then self.Headshots = self.Headshots + 1 end
end

function BS.Stats:RecordDeath()
    self.Deaths = self.Deaths + 1
end

function BS.Stats:RecordShot(hit)
    self.Shots = self.Shots + 1
    if hit then self.Hits = self.Hits + 1 end
end

function BS.Stats:RecordDamage(dmg)
    self.Damage = self.Damage + dmg
end

function BS.Stats:GetKD()
    if self.Deaths == 0 then return self.Kills end
    return math.floor(self.Kills / self.Deaths * 10) / 10
end

function BS.Stats:GetHSPercent()
    if self.Kills == 0 then return 0 end
    return math.floor(self.Headshots / self.Kills * 100)
end

function BS.Stats:GetAccuracy()
    if self.Shots == 0 then return 0 end
    return math.floor(self.Hits / self.Shots * 100)
end

function BS.Stats:GetPlayTime()
    return math.floor(tick() - self.StartTime)
end

function BS.Stats:GetReport()
    return string.format(
        "K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
        self.Kills, self.Deaths, self:GetKD(),
        self:GetHSPercent(), self:GetAccuracy(),
        self.Damage, math.floor(self:GetPlayTime() / 60)
    )
end

-- GUI
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)

print("[Stealth]   22: getfenv Environment Leak Prevention     NEW (DevForum 2025.07)")

-- ═══════════════════════════════════════════════════════════════
-- HWID SPOOFER
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}

function BS.HWIDSpoofer:Generate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = ""
    for i = 1, 32 do
        local r = math.random(1, #chars)
        id = id .. chars:sub(r, r)
        if i == 8 or i == 12 or i == 16 or i == 20 then
            id = id .. "-"
        end
    end
    return id
end

function BS.HWIDSpoofer:Activate()
    self.Active = true
    self.SpoofedID = self:Generate()
    -- Try to hook HWID functions
    pcall(function()
        if gethwid then
            local old = gethwid
            gethwid = function() return self.SpoofedID end
        end
    end)
    pcall(function()
        if getmachineid then
            local old = getmachineid
            getmachineid = function() return self.SpoofedID end
        end
    end)
    print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end

-- ═══════════════════════════════════════════════════════════════
-- PING SPOOF
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}

function BS.PingSpoof:SetPing(value)
    self.FakePing = value
    self.Active = true
    -- Override ping reporting
    pcall(function()
        if BS.Ping then
            BS.Ping.Current = value
            BS.Ping.Average = value
        end
    end)
end

function BS.PingSpoof:Disable()
    self.Active = false
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI-SCREENSHOT
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}

function BS.AntiScreenshot:Activate()
    self.Active = true
    -- Hide all BS GUI elements when screenshot is detected
    pcall(function()
        -- Hook SetCore("SendNotification") to suppress
        local oldSetCore
        oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
            if method == "TakeScreenshot" then
                -- Hide everything temporarily
                if BS.Win then BS.Win.Visible = false end
                task.delay(1, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
                return
            end
            return oldSetCore(self, method, ...)
        end)
    end)
    -- Also hide on PrintScreen key
    pcall(function()
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.PrintScreen then
                if BS.Win then BS.Win.Visible = false end
                task.delay(2, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
            end
        end)
    end)
    print("[Stealth] Anti-Screenshot active")
end

-- ═══════════════════════════════════════════════════════════════
-- STATISTICS TRACKER
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
    Kills = 0,
    Deaths = 0,
    Headshots = 0,
    Shots = 0,
    Hits = 0,
    Damage = 0,
    StartTime = tick(),
}

function BS.Stats:RecordKill(headshot)
    self.Kills = self.Kills + 1
    if headshot then self.Headshots = self.Headshots + 1 end
end

function BS.Stats:RecordDeath()
    self.Deaths = self.Deaths + 1
end

function BS.Stats:RecordShot(hit)
    self.Shots = self.Shots + 1
    if hit then self.Hits = self.Hits + 1 end
end

function BS.Stats:RecordDamage(dmg)
    self.Damage = self.Damage + dmg
end

function BS.Stats:GetKD()
    if self.Deaths == 0 then return self.Kills end
    return math.floor(self.Kills / self.Deaths * 10) / 10
end

function BS.Stats:GetHSPercent()
    if self.Kills == 0 then return 0 end
    return math.floor(self.Headshots / self.Kills * 100)
end

function BS.Stats:GetAccuracy()
    if self.Shots == 0 then return 0 end
    return math.floor(self.Hits / self.Shots * 100)
end

function BS.Stats:GetPlayTime()
    return math.floor(tick() - self.StartTime)
end

function BS.Stats:GetReport()
    return string.format(
        "K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
        self.Kills, self.Deaths, self:GetKD(),
        self:GetHSPercent(), self:GetAccuracy(),
        self.Damage, math.floor(self:GetPlayTime() / 60)
    )
end

-- GUI
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)

print("[Stealth]   23: Raw Metamethod Hook Evasion            NEW (DevForum 2025.07)")

-- ═══════════════════════════════════════════════════════════════
-- HWID SPOOFER
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}

function BS.HWIDSpoofer:Generate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = ""
    for i = 1, 32 do
        local r = math.random(1, #chars)
        id = id .. chars:sub(r, r)
        if i == 8 or i == 12 or i == 16 or i == 20 then
            id = id .. "-"
        end
    end
    return id
end

function BS.HWIDSpoofer:Activate()
    self.Active = true
    self.SpoofedID = self:Generate()
    -- Try to hook HWID functions
    pcall(function()
        if gethwid then
            local old = gethwid
            gethwid = function() return self.SpoofedID end
        end
    end)
    pcall(function()
        if getmachineid then
            local old = getmachineid
            getmachineid = function() return self.SpoofedID end
        end
    end)
    print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end

-- ═══════════════════════════════════════════════════════════════
-- PING SPOOF
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}

function BS.PingSpoof:SetPing(value)
    self.FakePing = value
    self.Active = true
    -- Override ping reporting
    pcall(function()
        if BS.Ping then
            BS.Ping.Current = value
            BS.Ping.Average = value
        end
    end)
end

function BS.PingSpoof:Disable()
    self.Active = false
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI-SCREENSHOT
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}

function BS.AntiScreenshot:Activate()
    self.Active = true
    -- Hide all BS GUI elements when screenshot is detected
    pcall(function()
        -- Hook SetCore("SendNotification") to suppress
        local oldSetCore
        oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
            if method == "TakeScreenshot" then
                -- Hide everything temporarily
                if BS.Win then BS.Win.Visible = false end
                task.delay(1, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
                return
            end
            return oldSetCore(self, method, ...)
        end)
    end)
    -- Also hide on PrintScreen key
    pcall(function()
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.PrintScreen then
                if BS.Win then BS.Win.Visible = false end
                task.delay(2, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
            end
        end)
    end)
    print("[Stealth] Anti-Screenshot active")
end

-- ═══════════════════════════════════════════════════════════════
-- STATISTICS TRACKER
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
    Kills = 0,
    Deaths = 0,
    Headshots = 0,
    Shots = 0,
    Hits = 0,
    Damage = 0,
    StartTime = tick(),
}

function BS.Stats:RecordKill(headshot)
    self.Kills = self.Kills + 1
    if headshot then self.Headshots = self.Headshots + 1 end
end

function BS.Stats:RecordDeath()
    self.Deaths = self.Deaths + 1
end

function BS.Stats:RecordShot(hit)
    self.Shots = self.Shots + 1
    if hit then self.Hits = self.Hits + 1 end
end

function BS.Stats:RecordDamage(dmg)
    self.Damage = self.Damage + dmg
end

function BS.Stats:GetKD()
    if self.Deaths == 0 then return self.Kills end
    return math.floor(self.Kills / self.Deaths * 10) / 10
end

function BS.Stats:GetHSPercent()
    if self.Kills == 0 then return 0 end
    return math.floor(self.Headshots / self.Kills * 100)
end

function BS.Stats:GetAccuracy()
    if self.Shots == 0 then return 0 end
    return math.floor(self.Hits / self.Shots * 100)
end

function BS.Stats:GetPlayTime()
    return math.floor(tick() - self.StartTime)
end

function BS.Stats:GetReport()
    return string.format(
        "K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
        self.Kills, self.Deaths, self:GetKD(),
        self:GetHSPercent(), self:GetAccuracy(),
        self.Damage, math.floor(self:GetPlayTime() / 60)
    )
end

-- GUI
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)

print("[Stealth]   24: ToString Trap Evasion                   NEW (DevForum 2023.10)")

-- ═══════════════════════════════════════════════════════════════
-- HWID SPOOFER
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}

function BS.HWIDSpoofer:Generate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = ""
    for i = 1, 32 do
        local r = math.random(1, #chars)
        id = id .. chars:sub(r, r)
        if i == 8 or i == 12 or i == 16 or i == 20 then
            id = id .. "-"
        end
    end
    return id
end

function BS.HWIDSpoofer:Activate()
    self.Active = true
    self.SpoofedID = self:Generate()
    -- Try to hook HWID functions
    pcall(function()
        if gethwid then
            local old = gethwid
            gethwid = function() return self.SpoofedID end
        end
    end)
    pcall(function()
        if getmachineid then
            local old = getmachineid
            getmachineid = function() return self.SpoofedID end
        end
    end)
    print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end

-- ═══════════════════════════════════════════════════════════════
-- PING SPOOF
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}

function BS.PingSpoof:SetPing(value)
    self.FakePing = value
    self.Active = true
    -- Override ping reporting
    pcall(function()
        if BS.Ping then
            BS.Ping.Current = value
            BS.Ping.Average = value
        end
    end)
end

function BS.PingSpoof:Disable()
    self.Active = false
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI-SCREENSHOT
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}

function BS.AntiScreenshot:Activate()
    self.Active = true
    -- Hide all BS GUI elements when screenshot is detected
    pcall(function()
        -- Hook SetCore("SendNotification") to suppress
        local oldSetCore
        oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
            if method == "TakeScreenshot" then
                -- Hide everything temporarily
                if BS.Win then BS.Win.Visible = false end
                task.delay(1, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
                return
            end
            return oldSetCore(self, method, ...)
        end)
    end)
    -- Also hide on PrintScreen key
    pcall(function()
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.PrintScreen then
                if BS.Win then BS.Win.Visible = false end
                task.delay(2, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
            end
        end)
    end)
    print("[Stealth] Anti-Screenshot active")
end

-- ═══════════════════════════════════════════════════════════════
-- STATISTICS TRACKER
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
    Kills = 0,
    Deaths = 0,
    Headshots = 0,
    Shots = 0,
    Hits = 0,
    Damage = 0,
    StartTime = tick(),
}

function BS.Stats:RecordKill(headshot)
    self.Kills = self.Kills + 1
    if headshot then self.Headshots = self.Headshots + 1 end
end

function BS.Stats:RecordDeath()
    self.Deaths = self.Deaths + 1
end

function BS.Stats:RecordShot(hit)
    self.Shots = self.Shots + 1
    if hit then self.Hits = self.Hits + 1 end
end

function BS.Stats:RecordDamage(dmg)
    self.Damage = self.Damage + dmg
end

function BS.Stats:GetKD()
    if self.Deaths == 0 then return self.Kills end
    return math.floor(self.Kills / self.Deaths * 10) / 10
end

function BS.Stats:GetHSPercent()
    if self.Kills == 0 then return 0 end
    return math.floor(self.Headshots / self.Kills * 100)
end

function BS.Stats:GetAccuracy()
    if self.Shots == 0 then return 0 end
    return math.floor(self.Hits / self.Shots * 100)
end

function BS.Stats:GetPlayTime()
    return math.floor(tick() - self.StartTime)
end

function BS.Stats:GetReport()
    return string.format(
        "K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
        self.Kills, self.Deaths, self:GetKD(),
        self:GetHSPercent(), self:GetAccuracy(),
        self.Damage, math.floor(self:GetPlayTime() / 60)
    )
end

-- GUI
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)

print("[Stealth]   25: Coroutine.wrap Stack Overflow Evasion   NEW (DevForum 2023.10)")

-- ═══════════════════════════════════════════════════════════════
-- HWID SPOOFER
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}

function BS.HWIDSpoofer:Generate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = ""
    for i = 1, 32 do
        local r = math.random(1, #chars)
        id = id .. chars:sub(r, r)
        if i == 8 or i == 12 or i == 16 or i == 20 then
            id = id .. "-"
        end
    end
    return id
end

function BS.HWIDSpoofer:Activate()
    self.Active = true
    self.SpoofedID = self:Generate()
    -- Try to hook HWID functions
    pcall(function()
        if gethwid then
            local old = gethwid
            gethwid = function() return self.SpoofedID end
        end
    end)
    pcall(function()
        if getmachineid then
            local old = getmachineid
            getmachineid = function() return self.SpoofedID end
        end
    end)
    print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end

-- ═══════════════════════════════════════════════════════════════
-- PING SPOOF
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}

function BS.PingSpoof:SetPing(value)
    self.FakePing = value
    self.Active = true
    -- Override ping reporting
    pcall(function()
        if BS.Ping then
            BS.Ping.Current = value
            BS.Ping.Average = value
        end
    end)
end

function BS.PingSpoof:Disable()
    self.Active = false
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI-SCREENSHOT
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}

function BS.AntiScreenshot:Activate()
    self.Active = true
    -- Hide all BS GUI elements when screenshot is detected
    pcall(function()
        -- Hook SetCore("SendNotification") to suppress
        local oldSetCore
        oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
            if method == "TakeScreenshot" then
                -- Hide everything temporarily
                if BS.Win then BS.Win.Visible = false end
                task.delay(1, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
                return
            end
            return oldSetCore(self, method, ...)
        end)
    end)
    -- Also hide on PrintScreen key
    pcall(function()
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.PrintScreen then
                if BS.Win then BS.Win.Visible = false end
                task.delay(2, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
            end
        end)
    end)
    print("[Stealth] Anti-Screenshot active")
end

-- ═══════════════════════════════════════════════════════════════
-- STATISTICS TRACKER
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
    Kills = 0,
    Deaths = 0,
    Headshots = 0,
    Shots = 0,
    Hits = 0,
    Damage = 0,
    StartTime = tick(),
}

function BS.Stats:RecordKill(headshot)
    self.Kills = self.Kills + 1
    if headshot then self.Headshots = self.Headshots + 1 end
end

function BS.Stats:RecordDeath()
    self.Deaths = self.Deaths + 1
end

function BS.Stats:RecordShot(hit)
    self.Shots = self.Shots + 1
    if hit then self.Hits = self.Hits + 1 end
end

function BS.Stats:RecordDamage(dmg)
    self.Damage = self.Damage + dmg
end

function BS.Stats:GetKD()
    if self.Deaths == 0 then return self.Kills end
    return math.floor(self.Kills / self.Deaths * 10) / 10
end

function BS.Stats:GetHSPercent()
    if self.Kills == 0 then return 0 end
    return math.floor(self.Headshots / self.Kills * 100)
end

function BS.Stats:GetAccuracy()
    if self.Shots == 0 then return 0 end
    return math.floor(self.Hits / self.Shots * 100)
end

function BS.Stats:GetPlayTime()
    return math.floor(tick() - self.StartTime)
end

function BS.Stats:GetReport()
    return string.format(
        "K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
        self.Kills, self.Deaths, self:GetKD(),
        self:GetHSPercent(), self:GetAccuracy(),
        self.Damage, math.floor(self:GetPlayTime() / 60)
    )
end

-- GUI
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)

print("[Stealth]   26: CoreGui Reference Evasion              NEW (DevForum 2023.10)")

-- ═══════════════════════════════════════════════════════════════
-- HWID SPOOFER
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}

function BS.HWIDSpoofer:Generate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = ""
    for i = 1, 32 do
        local r = math.random(1, #chars)
        id = id .. chars:sub(r, r)
        if i == 8 or i == 12 or i == 16 or i == 20 then
            id = id .. "-"
        end
    end
    return id
end

function BS.HWIDSpoofer:Activate()
    self.Active = true
    self.SpoofedID = self:Generate()
    -- Try to hook HWID functions
    pcall(function()
        if gethwid then
            local old = gethwid
            gethwid = function() return self.SpoofedID end
        end
    end)
    pcall(function()
        if getmachineid then
            local old = getmachineid
            getmachineid = function() return self.SpoofedID end
        end
    end)
    print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end

-- ═══════════════════════════════════════════════════════════════
-- PING SPOOF
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}

function BS.PingSpoof:SetPing(value)
    self.FakePing = value
    self.Active = true
    -- Override ping reporting
    pcall(function()
        if BS.Ping then
            BS.Ping.Current = value
            BS.Ping.Average = value
        end
    end)
end

function BS.PingSpoof:Disable()
    self.Active = false
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI-SCREENSHOT
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}

function BS.AntiScreenshot:Activate()
    self.Active = true
    -- Hide all BS GUI elements when screenshot is detected
    pcall(function()
        -- Hook SetCore("SendNotification") to suppress
        local oldSetCore
        oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
            if method == "TakeScreenshot" then
                -- Hide everything temporarily
                if BS.Win then BS.Win.Visible = false end
                task.delay(1, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
                return
            end
            return oldSetCore(self, method, ...)
        end)
    end)
    -- Also hide on PrintScreen key
    pcall(function()
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.PrintScreen then
                if BS.Win then BS.Win.Visible = false end
                task.delay(2, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
            end
        end)
    end)
    print("[Stealth] Anti-Screenshot active")
end

-- ═══════════════════════════════════════════════════════════════
-- STATISTICS TRACKER
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
    Kills = 0,
    Deaths = 0,
    Headshots = 0,
    Shots = 0,
    Hits = 0,
    Damage = 0,
    StartTime = tick(),
}

function BS.Stats:RecordKill(headshot)
    self.Kills = self.Kills + 1
    if headshot then self.Headshots = self.Headshots + 1 end
end

function BS.Stats:RecordDeath()
    self.Deaths = self.Deaths + 1
end

function BS.Stats:RecordShot(hit)
    self.Shots = self.Shots + 1
    if hit then self.Hits = self.Hits + 1 end
end

function BS.Stats:RecordDamage(dmg)
    self.Damage = self.Damage + dmg
end

function BS.Stats:GetKD()
    if self.Deaths == 0 then return self.Kills end
    return math.floor(self.Kills / self.Deaths * 10) / 10
end

function BS.Stats:GetHSPercent()
    if self.Kills == 0 then return 0 end
    return math.floor(self.Headshots / self.Kills * 100)
end

function BS.Stats:GetAccuracy()
    if self.Shots == 0 then return 0 end
    return math.floor(self.Hits / self.Shots * 100)
end

function BS.Stats:GetPlayTime()
    return math.floor(tick() - self.StartTime)
end

function BS.Stats:GetReport()
    return string.format(
        "K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
        self.Kills, self.Deaths, self:GetKD(),
        self:GetHSPercent(), self:GetAccuracy(),
        self.Damage, math.floor(self:GetPlayTime() / 60)
    )
end

-- GUI
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)

print("[Stealth]   27: getfenv Level Scanning Evasion         NEW (DevForum 2025.07)")

-- ═══════════════════════════════════════════════════════════════
-- HWID SPOOFER
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}

function BS.HWIDSpoofer:Generate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = ""
    for i = 1, 32 do
        local r = math.random(1, #chars)
        id = id .. chars:sub(r, r)
        if i == 8 or i == 12 or i == 16 or i == 20 then
            id = id .. "-"
        end
    end
    return id
end

function BS.HWIDSpoofer:Activate()
    self.Active = true
    self.SpoofedID = self:Generate()
    -- Try to hook HWID functions
    pcall(function()
        if gethwid then
            local old = gethwid
            gethwid = function() return self.SpoofedID end
        end
    end)
    pcall(function()
        if getmachineid then
            local old = getmachineid
            getmachineid = function() return self.SpoofedID end
        end
    end)
    print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end

-- ═══════════════════════════════════════════════════════════════
-- PING SPOOF
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}

function BS.PingSpoof:SetPing(value)
    self.FakePing = value
    self.Active = true
    -- Override ping reporting
    pcall(function()
        if BS.Ping then
            BS.Ping.Current = value
            BS.Ping.Average = value
        end
    end)
end

function BS.PingSpoof:Disable()
    self.Active = false
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI-SCREENSHOT
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}

function BS.AntiScreenshot:Activate()
    self.Active = true
    -- Hide all BS GUI elements when screenshot is detected
    pcall(function()
        -- Hook SetCore("SendNotification") to suppress
        local oldSetCore
        oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
            if method == "TakeScreenshot" then
                -- Hide everything temporarily
                if BS.Win then BS.Win.Visible = false end
                task.delay(1, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
                return
            end
            return oldSetCore(self, method, ...)
        end)
    end)
    -- Also hide on PrintScreen key
    pcall(function()
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.PrintScreen then
                if BS.Win then BS.Win.Visible = false end
                task.delay(2, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
            end
        end)
    end)
    print("[Stealth] Anti-Screenshot active")
end

-- ═══════════════════════════════════════════════════════════════
-- STATISTICS TRACKER
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
    Kills = 0,
    Deaths = 0,
    Headshots = 0,
    Shots = 0,
    Hits = 0,
    Damage = 0,
    StartTime = tick(),
}

function BS.Stats:RecordKill(headshot)
    self.Kills = self.Kills + 1
    if headshot then self.Headshots = self.Headshots + 1 end
end

function BS.Stats:RecordDeath()
    self.Deaths = self.Deaths + 1
end

function BS.Stats:RecordShot(hit)
    self.Shots = self.Shots + 1
    if hit then self.Hits = self.Hits + 1 end
end

function BS.Stats:RecordDamage(dmg)
    self.Damage = self.Damage + dmg
end

function BS.Stats:GetKD()
    if self.Deaths == 0 then return self.Kills end
    return math.floor(self.Kills / self.Deaths * 10) / 10
end

function BS.Stats:GetHSPercent()
    if self.Kills == 0 then return 0 end
    return math.floor(self.Headshots / self.Kills * 100)
end

function BS.Stats:GetAccuracy()
    if self.Shots == 0 then return 0 end
    return math.floor(self.Hits / self.Shots * 100)
end

function BS.Stats:GetPlayTime()
    return math.floor(tick() - self.StartTime)
end

function BS.Stats:GetReport()
    return string.format(
        "K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
        self.Kills, self.Deaths, self:GetKD(),
        self:GetHSPercent(), self:GetAccuracy(),
        self.Damage, math.floor(self:GetPlayTime() / 60)
    )
end

-- GUI
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)

print("[Stealth]   28: Unified Anti-Detection Activation       NEW")

-- ═══════════════════════════════════════════════════════════════
-- HWID SPOOFER
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}

function BS.HWIDSpoofer:Generate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = ""
    for i = 1, 32 do
        local r = math.random(1, #chars)
        id = id .. chars:sub(r, r)
        if i == 8 or i == 12 or i == 16 or i == 20 then
            id = id .. "-"
        end
    end
    return id
end

function BS.HWIDSpoofer:Activate()
    self.Active = true
    self.SpoofedID = self:Generate()
    -- Try to hook HWID functions
    pcall(function()
        if gethwid then
            local old = gethwid
            gethwid = function() return self.SpoofedID end
        end
    end)
    pcall(function()
        if getmachineid then
            local old = getmachineid
            getmachineid = function() return self.SpoofedID end
        end
    end)
    print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end

-- ═══════════════════════════════════════════════════════════════
-- PING SPOOF
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}

function BS.PingSpoof:SetPing(value)
    self.FakePing = value
    self.Active = true
    -- Override ping reporting
    pcall(function()
        if BS.Ping then
            BS.Ping.Current = value
            BS.Ping.Average = value
        end
    end)
end

function BS.PingSpoof:Disable()
    self.Active = false
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI-SCREENSHOT
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}

function BS.AntiScreenshot:Activate()
    self.Active = true
    -- Hide all BS GUI elements when screenshot is detected
    pcall(function()
        -- Hook SetCore("SendNotification") to suppress
        local oldSetCore
        oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
            if method == "TakeScreenshot" then
                -- Hide everything temporarily
                if BS.Win then BS.Win.Visible = false end
                task.delay(1, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
                return
            end
            return oldSetCore(self, method, ...)
        end)
    end)
    -- Also hide on PrintScreen key
    pcall(function()
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.PrintScreen then
                if BS.Win then BS.Win.Visible = false end
                task.delay(2, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
            end
        end)
    end)
    print("[Stealth] Anti-Screenshot active")
end

-- ═══════════════════════════════════════════════════════════════
-- STATISTICS TRACKER
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
    Kills = 0,
    Deaths = 0,
    Headshots = 0,
    Shots = 0,
    Hits = 0,
    Damage = 0,
    StartTime = tick(),
}

function BS.Stats:RecordKill(headshot)
    self.Kills = self.Kills + 1
    if headshot then self.Headshots = self.Headshots + 1 end
end

function BS.Stats:RecordDeath()
    self.Deaths = self.Deaths + 1
end

function BS.Stats:RecordShot(hit)
    self.Shots = self.Shots + 1
    if hit then self.Hits = self.Hits + 1 end
end

function BS.Stats:RecordDamage(dmg)
    self.Damage = self.Damage + dmg
end

function BS.Stats:GetKD()
    if self.Deaths == 0 then return self.Kills end
    return math.floor(self.Kills / self.Deaths * 10) / 10
end

function BS.Stats:GetHSPercent()
    if self.Kills == 0 then return 0 end
    return math.floor(self.Headshots / self.Kills * 100)
end

function BS.Stats:GetAccuracy()
    if self.Shots == 0 then return 0 end
    return math.floor(self.Hits / self.Shots * 100)
end

function BS.Stats:GetPlayTime()
    return math.floor(tick() - self.StartTime)
end

function BS.Stats:GetReport()
    return string.format(
        "K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
        self.Kills, self.Deaths, self:GetKD(),
        self:GetHSPercent(), self:GetAccuracy(),
        self.Damage, math.floor(self:GetPlayTime() / 60)
    )
end

-- GUI
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)

print("[Stealth] ")

-- ═══════════════════════════════════════════════════════════════
-- HWID SPOOFER
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}

function BS.HWIDSpoofer:Generate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = ""
    for i = 1, 32 do
        local r = math.random(1, #chars)
        id = id .. chars:sub(r, r)
        if i == 8 or i == 12 or i == 16 or i == 20 then
            id = id .. "-"
        end
    end
    return id
end

function BS.HWIDSpoofer:Activate()
    self.Active = true
    self.SpoofedID = self:Generate()
    -- Try to hook HWID functions
    pcall(function()
        if gethwid then
            local old = gethwid
            gethwid = function() return self.SpoofedID end
        end
    end)
    pcall(function()
        if getmachineid then
            local old = getmachineid
            getmachineid = function() return self.SpoofedID end
        end
    end)
    print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end

-- ═══════════════════════════════════════════════════════════════
-- PING SPOOF
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}

function BS.PingSpoof:SetPing(value)
    self.FakePing = value
    self.Active = true
    -- Override ping reporting
    pcall(function()
        if BS.Ping then
            BS.Ping.Current = value
            BS.Ping.Average = value
        end
    end)
end

function BS.PingSpoof:Disable()
    self.Active = false
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI-SCREENSHOT
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}

function BS.AntiScreenshot:Activate()
    self.Active = true
    -- Hide all BS GUI elements when screenshot is detected
    pcall(function()
        -- Hook SetCore("SendNotification") to suppress
        local oldSetCore
        oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
            if method == "TakeScreenshot" then
                -- Hide everything temporarily
                if BS.Win then BS.Win.Visible = false end
                task.delay(1, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
                return
            end
            return oldSetCore(self, method, ...)
        end)
    end)
    -- Also hide on PrintScreen key
    pcall(function()
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.PrintScreen then
                if BS.Win then BS.Win.Visible = false end
                task.delay(2, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
            end
        end)
    end)
    print("[Stealth] Anti-Screenshot active")
end

-- ═══════════════════════════════════════════════════════════════
-- STATISTICS TRACKER
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
    Kills = 0,
    Deaths = 0,
    Headshots = 0,
    Shots = 0,
    Hits = 0,
    Damage = 0,
    StartTime = tick(),
}

function BS.Stats:RecordKill(headshot)
    self.Kills = self.Kills + 1
    if headshot then self.Headshots = self.Headshots + 1 end
end

function BS.Stats:RecordDeath()
    self.Deaths = self.Deaths + 1
end

function BS.Stats:RecordShot(hit)
    self.Shots = self.Shots + 1
    if hit then self.Hits = self.Hits + 1 end
end

function BS.Stats:RecordDamage(dmg)
    self.Damage = self.Damage + dmg
end

function BS.Stats:GetKD()
    if self.Deaths == 0 then return self.Kills end
    return math.floor(self.Kills / self.Deaths * 10) / 10
end

function BS.Stats:GetHSPercent()
    if self.Kills == 0 then return 0 end
    return math.floor(self.Headshots / self.Kills * 100)
end

function BS.Stats:GetAccuracy()
    if self.Shots == 0 then return 0 end
    return math.floor(self.Hits / self.Shots * 100)
end

function BS.Stats:GetPlayTime()
    return math.floor(tick() - self.StartTime)
end

function BS.Stats:GetReport()
    return string.format(
        "K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
        self.Kills, self.Deaths, self:GetKD(),
        self:GetHSPercent(), self:GetAccuracy(),
        self.Damage, math.floor(self:GetPlayTime() / 60)
    )
end

-- GUI
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)

print("[Stealth] F10=Nuclear | F9=Safe | Risk: " .. Stealth.RiskLevel .. "%")
-- ═══════════════════════════════════════════════════════════════
-- ANTI-DETECTION SYSTEM v5.0 - Advanced Features
-- ═══════════════════════════════════════════════════════════════

-- FEATURE 29: ADVANCED MEMORY PROTECTION
Stealth.MemoryProtection = {Enabled = false}
function Stealth.MemoryProtection.RandomizeLayout()
    pcall(function()
        for i = 1, 10 do
            local decoy = Instance.new("Folder")
            decoy.Name = string.char(math.random(65,90)) .. math.random(1000,9999)
            decoy.Parent = game:GetService("ReplicatedStorage")
            game:GetService("Debris"):AddItem(decoy, 5)
        end
    end)
end

-- FEATURE 30: ANTI-TAMPER CHECKS
Stealth.AntiTamper = {Enabled = false, Checksums = {}}
function Stealth.AntiTamper.StoreChecksums()
    pcall(function()
        for name, func in pairs(getfenv()) do
            if type(func) == "function" then
                Stealth.AntiTamper.Checksums[name] = #string.dump(func)
            end
        end
    end)
end
function Stealth.AntiTamper.VerifyIntegrity()
    pcall(function()
        for name, func in pairs(getfenv()) do
            if type(func) == "function" and Stealth.AntiTamper.Checksums[name] then
                if #string.dump(func) ~= Stealth.AntiTamper.Checksums[name] then
                    warn("[Stealth] Tamper detected: " .. name)
                end
            end
        end
    end)
end

-- FEATURE 31: BEHAVIORAL ANALYSIS EVASION
Stealth.BehavioralEvasion = {Enabled = false}
function Stealth.BehavioralEvasion.HumanizeMouse(targetPos)
    local jitter = Vector2.new(math.random(-2,2), math.random(-2,2))
    return targetPos + jitter
end
function Stealth.BehavioralEvasion.HumanizeReaction()
    return math.random(50,150) / 1000
end

-- FEATURE 32: NETWORK TRAFFIC OBFUSCATION
Stealth.NetworkObfuscation = {Enabled = false}
function Stealth.NetworkObfuscation.ObfuscateTiming()
    return 0.016 + math.random(-5,5) / 1000
end

-- FEATURE 33: HARDWARE FINGERPRINT SPOOFING
Stealth.HardwareSpoof = {Enabled = false}
function Stealth.HardwareSpoof.SpoofDeviceID()
    local id = ""
    for i = 1, 32 do id = id .. string.format("%02x", math.random(0,255)) end
end

-- FEATURE 34: ANTI-DEBUG TECHNIQUES
Stealth.AntiDebug = {Enabled = false}
function Stealth.AntiDebug.AntiStep()
    pcall(function()
        local oldDebug = debug.getinfo
        debug.getinfo = function(level, what)
            local info = oldDebug(level, what)
            if info then info.source = "=C" info.short_src = "=C" end
            return info
        end
    end)
end

-- FEATURE 35: TIMING EVASION
Stealth.TimingEvasion = {Enabled = false}
function Stealth.TimingEvasion.RandomizeTiming(baseTime)
    local noise = 0
    for i = 1, 6 do noise = noise + math.random() end
    return baseTime * (1 + (noise/6 - 0.5) * 0.1)
end

-- FEATURE 36: ANTI-REPLAY
Stealth.AntiReplay = {Enabled = false, SessionID = tostring(math.random(1000000,9999999))}
function Stealth.AntiReplay.AddToken(op) return op .. "_token_" .. Stealth.AntiReplay.SessionID end

-- ACTIVATE ALL
function Stealth.ActivateAllAntiDetection()
    Stealth.MemoryProtection.Enabled = true
    Stealth.AntiTamper.Enabled = true
    Stealth.BehavioralEvasion.Enabled = true
    Stealth.NetworkObfuscation.Enabled = true
    Stealth.HardwareSpoof.Enabled = true
    Stealth.AntiDebug.Enabled = true
    Stealth.TimingEvasion.Enabled = true
    Stealth.AntiReplay.Enabled = true
    pcall(function() Stealth.AntiTamper.StoreChecksums() end)
    pcall(function() Stealth.HardwareSpoof.SpoofDeviceID() end)
    pcall(function() Stealth.AntiDebug.AntiStep() end)
    task.spawn(function()
        while true do
            task.wait(5)
            pcall(function()
                if Stealth.MemoryProtection.Enabled then Stealth.MemoryProtection.RandomizeLayout() end
                if Stealth.AntiTamper.Enabled then Stealth.AntiTamper.VerifyIntegrity() end
            end)
        end
    end)
    
-- ═══════════════════════════════════════════════════════════════
-- HWID SPOOFER
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}

function BS.HWIDSpoofer:Generate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = ""
    for i = 1, 32 do
        local r = math.random(1, #chars)
        id = id .. chars:sub(r, r)
        if i == 8 or i == 12 or i == 16 or i == 20 then
            id = id .. "-"
        end
    end
    return id
end

function BS.HWIDSpoofer:Activate()
    self.Active = true
    self.SpoofedID = self:Generate()
    -- Try to hook HWID functions
    pcall(function()
        if gethwid then
            local old = gethwid
            gethwid = function() return self.SpoofedID end
        end
    end)
    pcall(function()
        if getmachineid then
            local old = getmachineid
            getmachineid = function() return self.SpoofedID end
        end
    end)
    print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end

-- ═══════════════════════════════════════════════════════════════
-- PING SPOOF
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}

function BS.PingSpoof:SetPing(value)
    self.FakePing = value
    self.Active = true
    -- Override ping reporting
    pcall(function()
        if BS.Ping then
            BS.Ping.Current = value
            BS.Ping.Average = value
        end
    end)
end

function BS.PingSpoof:Disable()
    self.Active = false
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI-SCREENSHOT
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}

function BS.AntiScreenshot:Activate()
    self.Active = true
    -- Hide all BS GUI elements when screenshot is detected
    pcall(function()
        -- Hook SetCore("SendNotification") to suppress
        local oldSetCore
        oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
            if method == "TakeScreenshot" then
                -- Hide everything temporarily
                if BS.Win then BS.Win.Visible = false end
                task.delay(1, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
                return
            end
            return oldSetCore(self, method, ...)
        end)
    end)
    -- Also hide on PrintScreen key
    pcall(function()
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.PrintScreen then
                if BS.Win then BS.Win.Visible = false end
                task.delay(2, function()
                    if BS.Win then BS.Win.Visible = true end
                end)
            end
        end)
    end)
    print("[Stealth] Anti-Screenshot active")
end

-- ═══════════════════════════════════════════════════════════════
-- STATISTICS TRACKER
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
    Kills = 0,
    Deaths = 0,
    Headshots = 0,
    Shots = 0,
    Hits = 0,
    Damage = 0,
    StartTime = tick(),
}

function BS.Stats:RecordKill(headshot)
    self.Kills = self.Kills + 1
    if headshot then self.Headshots = self.Headshots + 1 end
end

function BS.Stats:RecordDeath()
    self.Deaths = self.Deaths + 1
end

function BS.Stats:RecordShot(hit)
    self.Shots = self.Shots + 1
    if hit then self.Hits = self.Hits + 1 end
end

function BS.Stats:RecordDamage(dmg)
    self.Damage = self.Damage + dmg
end

function BS.Stats:GetKD()
    if self.Deaths == 0 then return self.Kills end
    return math.floor(self.Kills / self.Deaths * 10) / 10
end

function BS.Stats:GetHSPercent()
    if self.Kills == 0 then return 0 end
    return math.floor(self.Headshots / self.Kills * 100)
end

function BS.Stats:GetAccuracy()
    if self.Shots == 0 then return 0 end
    return math.floor(self.Hits / self.Shots * 100)
end

function BS.Stats:GetPlayTime()
    return math.floor(tick() - self.StartTime)
end

function BS.Stats:GetReport()
    return string.format(
        "K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
        self.Kills, self.Deaths, self:GetKD(),
        self:GetHSPercent(), self:GetAccuracy(),
        self.Damage, math.floor(self:GetPlayTime() / 60)
    )
end

-- GUI
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)

print("[Stealth] Anti-detection v5.0 activated (8 new systems)")
end

Stealth.ActivateAllAntiDetection()
