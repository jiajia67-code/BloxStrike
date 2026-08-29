

-- BLOXSTRIKE HUD MODULE v1.0
-- Performance Monitor, Status Panel, Feature Overview

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
local StarterGui = nil
pcall(function() StarterGui = game:GetService("StarterGui") end)
local lplr = Players.LocalPlayer

if not BS.Win then warn("[HUD] BS.Win not available - ui.lua may have failed") return end
local page = BS.Win:Tab("HUD")
if not page or not page.Toggle then warn("[HUD] Failed to create tab!") return end

local HUD = {}

-- Watermark Implementation
local WatermarkObj = nil
local function updateWatermark()
    if not Flags.Watermark then
        if WatermarkObj then WatermarkObj.Visible = false end
        return
    end
    if not WatermarkObj then
        pcall(function() WatermarkObj = Drawing.new("Text") end)
        if not WatermarkObj then return end
        WatermarkObj.Center = false
        WatermarkObj.Outline = true
        WatermarkObj.OutlineColor = Color3.new(0,0,0)
        WatermarkObj.Font = 2
        WatermarkObj.Size = 14
    end
    local parts = {"BloxStrike v3.0"}
    if Flags.WMFPS then table.insert(parts, math.floor(1/workspace.CurrentCamera:GetPropertyChangedSignal("CFrame"):Wait() and 60 or 60) .. " FPS") end
    if Flags.WMPing then
        pcall(function()
            local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"].Value)
            table.insert(parts, ping .. " ms")
        end)
    end
    if Flags.WMServer then table.insert(parts, game:GetService("Workspace").Name) end
    if Flags.WMPlayers then table.insert(parts, #game:GetService("Players"):GetPlayers() .. " players") end
    if Flags.WMTime then table.insert(parts, os.date("%H:%M:%S")) end
    WatermarkObj.Text = "  " .. table.concat(parts, " | ") .. "  "
    WatermarkObj.Position = Vector2.new(10, 10)
    WatermarkObj.Color = Color3.new(1,1,1)
    WatermarkObj.Visible = true
end

-- Spectator List Implementation
local SpectatorObjs = {}
local function updateSpectators()
    if not Flags.SpectatorList then
        for _, obj in pairs(SpectatorObjs) do pcall(function() obj.Visible = false end) end
        SpectatorObjs = {}
        return
    end
    local myChar = lplr.Character
    if not myChar then return end
    local myHead = myChar:FindFirstChild("Head")
    if not myHead then return end
    local specs = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lplr and p.Character then
            local cam = p and p.Character:FindFirstChildOfClass("Camera")
            if cam and cam.CameraSubject == myHead then
                table.insert(specs, p.Name)
            end
        end
    end
    for i = 1, math.max(#specs, #SpectatorObjs) do
        if not SpectatorObjs[i] then
            pcall(function() SpectatorObjs[i] = Drawing.new("Text") end)
        end
        if SpectatorObjs[i] then
            if i <= #specs then
                SpectatorObjs[i].Text = specs[i]
                SpectatorObjs[i].Position = Vector2.new(10, 30 + (i-1) * 18)
                SpectatorObjs[i].Color = Color3.new(1,1,1)
                SpectatorObjs[i].Size = 13
                SpectatorObjs[i].Outline = true
                SpectatorObjs[i].Visible = true
            else
                SpectatorObjs[i].Visible = false
            end
        end
    end
end

-- Kill Counter Implementation
local SessionKills = 0
local SessionDeaths = 0
local SessionHeadshots = 0
local SessionShots = 0
local SessionHits = 0
local KillCounterObj = nil

local function updateKillCounter()
    if not Flags.KillCounter then
        if KillCounterObj then KillCounterObj.Visible = false end
        return
    end
    if not KillCounterObj then
        pcall(function() KillCounterObj = Drawing.new("Text") end)
        if not KillCounterObj then return end
        KillCounterObj.Center = false
        KillCounterObj.Outline = true
        KillCounterObj.OutlineColor = Color3.new(0,0,0)
        KillCounterObj.Font = 2
        KillCounterObj.Size = 13
    end
    local parts = {}
    if Flags.KDShow then
        local kd = SessionDeaths > 0 and string.format("%.1f", SessionKills/SessionDeaths) or tostring(SessionKills)
        table.insert(parts, "K/D: " .. SessionKills .. "/" .. SessionDeaths .. " (" .. kd .. ")")
    end
    if Flags.HSShow and SessionKills > 0 then
        table.insert(parts, "HS: " .. math.floor(SessionHeadshots/SessionKills*100) .. "%")
    end
    if Flags.AccShow and SessionShots > 0 then
        table.insert(parts, "Acc: " .. math.floor(SessionHits/SessionShots*100) .. "%")
    end
    KillCounterObj.Text = "  " .. table.concat(parts, " | ") .. "  "
    KillCounterObj.Position = Vector2.new(10, workspace.CurrentCamera.ViewportSize.Y - 30)
    KillCounterObj.Color = Color3.new(1,1,0.5)
    KillCounterObj.Visible = #parts > 0
end

-- Listen for kills/deaths
lplr.CharacterAdded:Connect(function()
    task.delay(0.5, function()
        local hum = lplr.Character and lplr and lplr.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Died:Connect(function()
                SessionDeaths = SessionDeaths + 1
            end)
        end
    end)
end)

-- HUD update loop
task.spawn(function()
    while true do
        task.wait(0.2)
        pcall(function()
            updateWatermark()
            updateSpectators()
            updateKillCounter()
        end)
    end
end)

-- Expose kill tracking
HUD.trackKill = function(wasHeadshot)
    SessionKills = SessionKills + 1
    if wasHeadshot then SessionHeadshots = SessionHeadshots + 1 end
end
HUD.trackShot = function() SessionShots = SessionShots + 1 end
HUD.trackHit = function() SessionHits = SessionHits + 1 end


BS.HUD = HUD

-- SECTION 1: PERFORMANCE MONITOR

page:Label("  ")
page:Toggle("FPS Display", false, function(v) Flags.HUDFPS = v end)
page:Toggle("Ping Display", false, function(v) Flags.HUDPing = v end)
page:Toggle("Memory Display", false, function(v) Flags.HUDMemory = v end)
page:Toggle("Server Info", false, function(v) Flags.HUDServer = v end)
page:Toggle("Player Count", false, function(v) Flags.HUDPlayerCount = v end)
page:Dropdown({Name="HUD Position", Flag="HUDPos", Options={"Top-Left","Top-Center","Top-Right","Bottom-Left","Bottom-Center","Bottom-Right"}, Default="Top-Left"})
page:Slider("HUD Size", 8, 20, 14, function(v) Flags.HUDSize = v end)

-- SECTION 2: FEATURE STATUS PANEL

page:Label("  ")
page:Toggle("Feature Status", false, function(v) Flags.HUDFeatures = v end)
page:Toggle("Risk Level Display", false, function(v) Flags.HUDRisk = v end)
page:Toggle("Active Modules", false, function(v) Flags.HUDModules = v end)
page:Toggle("Weapon Info", false, function(v) Flags.HUDWeapon = v end)
page:Toggle("Player Info", false, function(v) Flags.HUDPlayerInfo = v end)

-- SECTION 3: K/D & COMBAT HUD

page:Label("  HUD ")
page:Toggle("K/D Display", false, function(v) Flags.HUDKD = v end)
page:Toggle("Accuracy Display", false, function(v) Flags.HUDAccuracy = v end)
page:Toggle("Kill Streak Display", false, function(v) Flags.HUDStreak = v end)
page:Toggle("Velocity Display", false, function(v) Flags.HUDVelocity = v end)
page:Toggle("Speed Display", false, function(v) Flags.HUDSpeed = v end)
page:Toggle("Health Crosshair", false, function(v) Flags.HUDHealthCross = v end)

-- SECTION 4: NOTIFICATION CENTER

page:Label("  ")
page:Toggle("Notification Center", false, function(v) Flags.HUDNotifications = v end)
page:Slider("Max Notifications", 3, 10, 5, function(v) Flags.HUDMaxNotif = v end)
page:Toggle("Feature Toggle Notif", true, function(v) Flags.HUDFeatureNotif = v end)
page:Toggle("Kill Notif", false, function(v) Flags.HUDKillNotif = v end)

-- SECTION 5: WATERMARK

page:Label(" Watermark ")
page:Toggle("Watermark", false, function(v) Flags.Watermark = v end)
page:Dropdown({Name="Watermark Style", Flag="WMStyle", Options={"Default","Compact","Minimal","CS2"}, Default="CS2"})
page:Toggle("Show FPS", true, function(v) Flags.WMFPS = v end)
page:Toggle("Show Ping", true, function(v) Flags.WMPing = v end)
page:Toggle("Show Server", false, function(v) Flags.WMServer = v end)
page:Toggle("Show Players", false, function(v) Flags.WMPlayers = v end)
page:Toggle("Show Time", false, function(v) Flags.WMTime = v end)
page:Separator()

-- SECTION 6: SPECTATOR LIST

page:Label(" Spectator List ")
page:Toggle("Spectator List", false, function(v) Flags.SpectatorList = v end)
page:Dropdown({Name="Spec Style", Flag="SpecStyle", Options={"Vertical","Horizontal","Compact"}, Default="Vertical"})
page:Toggle("Show Spec Mode", true, function(v) Flags.SpecMode = v end)
page:Toggle("Notify Spectator", false, function(v) Flags.SpecNotify = v end)
page:Separator()

-- SECTION 7: KILL COUNTER

page:Label(" Kill Counter ")
page:Toggle("Kill Counter", false, function(v) Flags.KillCounter = v end)
page:Toggle("Show K/D", true, function(v) Flags.KDShow = v end)
page:Toggle("Show HS %", true, function(v) Flags.HSShow = v end)
page:Toggle("Show Accuracy", false, function(v) Flags.AccShow = v end)
page:Toggle("Session Stats", false, function(v) Flags.SessionStats = v end)
page:Separator()

-- HUD Drawing Engine (Object Pool, zero-delay)

local HUDObjects = {}
local HUDFrameCount = 0
local NotifQueue = {}

-- Object pool for HUD Drawing objects
local function getHUDObject(uniqueId)
    if HUDObjects[uniqueId] then
        return HUDObjects[uniqueId]
    end
    local obj = nil
    pcall(function()
        obj = Drawing.new("Text")
        obj.Visible = false
        obj.Center = false
        obj.Outline = true
        obj.OutlineColor = Color3.new(0, 0, 0)
        obj.Color = Color3.new(1, 1, 1)
        obj.Size = Flags.HUDSize or 14
        obj.Font = Drawing.Fonts.UI
    end)
    if not obj then
        local noop = setmetatable({}, {__index = function() return nil end, __newindex = function() end})
        return noop
    end
    HUDObjects[uniqueId] = obj
    return obj
end

-- Position calculator
local function getHUDPosition(section, line, align)
    align = align or Flags.HUDPos or "Top-Left"
    local textSize = (Flags.HUDSize or 14) + 4
    local margin = 12

    if align == "Top-Left" then
        return Vector2.new(margin + section * 200, margin + line * textSize)
    elseif align == "Top-Center" then
        return Vector2.new(400 + section * 200, margin + line * textSize)
    elseif align == "Top-Right" then
        return Vector2.new(780 - margin + section * 200, margin + line * textSize)
    elseif align == "Bottom-Left" then
        return Vector2.new(margin + section * 200, 540 - margin - line * textSize)
    elseif align == "Bottom-Center" then
        return Vector2.new(400 + section * 200, 540 - margin - line * textSize)
    elseif align == "Bottom-Right" then
        return Vector2.new(780 - margin + section * 200, 540 - margin - line * textSize)
    end
    return Vector2.new(margin, margin + line * textSize)
end

-- Colors
local C_WHITE = Color3.new(1, 1, 1)
local C_GREEN = Color3.new(0, 1, 0)
local C_YELLOW = Color3.new(1, 1, 0)
local C_RED = Color3.new(1, 0.2, 0.2)
local C_CYAN = Color3.new(0, 1, 1)
local C_ORANGE = Color3.new(1, 0.6, 0)
local C_PURPLE = Color3.new(0.8, 0, 1)
local C_GRAY = Color3.new(0.6, 0.6, 0.6)
local C_BLUE = Color3.new(0.3, 0.6, 1)

 -- HUD Render Loop
RunService.RenderStepped:Connect(function()
    HUDFrameCount = HUDFrameCount + 1
    if HUDFrameCount % 3 ~= 0 then return end -- Update every 3 frames for performance

    local size = Flags.HUDSize or 14
    local anyHUD = Flags.HUDFPS or Flags.HUDPing or Flags.HUDMemory or
        Flags.HUDServer or Flags.HUDPlayerCount or Flags.HUDFeatures or
        Flags.HUDRisk or Flags.HUDModules or Flags.HUDWeapon or
        Flags.HUDPlayerInfo or Flags.HUDKD or Flags.HUDAccuracy or
        Flags.HUDStreak or Flags.HUDVelocity or Flags.HUDSpeed or
        Flags.HUDHealthCross or Flags.HUDNotifications

    if not anyHUD then
        -- Hide all
        for _, obj in pairs(HUDObjects) do
            obj.Visible = false
        end
        -- return
    end

    local line = 0
    local section = 0

     -- Performance Section
    if Flags.HUDFPS then
        local fpsObj = getHUDObject("fps")
        local fps = BS.Perf and BS.Perf.FPS or 60
        fpsObj.Text = "FPS: " .. fps
        fpsObj.Size = size
        fpsObj.Position = getHUDPosition(0, line)
        fpsObj.Color = fps >= 60 and C_GREEN or fps >= 30 and C_YELLOW or C_RED
        fpsObj.Visible = true
        line = line + 1
    end

    if Flags.HUDPing then
        local pingObj = getHUDObject("ping")
        local ping = BS.Ping and BS.Ping.Current or 0
        local quality = BS.Ping and BS.Ping.Quality or "Good"
        pingObj.Text = "Ping: " .. ping .. "ms [" .. quality .. "]"
        pingObj.Size = size
        pingObj.Position = getHUDPosition(0, line)
        pingObj.Color = ping < 50 and C_GREEN or ping < 100 and C_YELLOW or C_RED
        pingObj.Visible = true
        line = line + 1
    end

    if Flags.HUDMemory then
        local memObj = getHUDObject("memory")
        local mem = collectgarbage("count")
        memObj.Text = string.format("Memory: %.1f MB", mem / 1024)
        memObj.Size = size
        memObj.Position = getHUDPosition(0, line)
        memObj.Color = mem < 100 * 1024 and C_GREEN or mem < 300 * 1024 and C_YELLOW or C_RED
        memObj.Visible = true
        line = line + 1
    end

    if Flags.HUDServer then
        local srvObj = getHUDObject("server")
        srvObj.Text = "Server: " .. (game.JobId and game.JobId:sub(1, 8) or "N/A")
        srvObj.Size = size
        srvObj.Position = getHUDPosition(0, line)
        srvObj.Color = C_GRAY
        srvObj.Visible = true
        line = line + 1
    end

    if Flags.HUDPlayerCount then
        local pcObj = getHUDObject("playercount")
        pcObj.Text = "Players: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers
        pcObj.Size = size
        pcObj.Position = getHUDPosition(0, line)
        pcObj.Color = C_CYAN
        pcObj.Visible = true
        line = line + 1
    end

     -- Feature Status Section
    local featLine = 0
    if Flags.HUDFeatures then
        local features = {}

        -- Combat features
        if Flags.Aimbot then table.insert(features, {"Aimbot", C_GREEN}) end
        if Flags.TriggerBot then table.insert(features, {"Trigger", C_GREEN}) end
        if Flags.Ragebot then table.insert(features, {"Rage", C_RED}) end
        if Flags.AA then table.insert(features, {"Anti-Aim", C_ORANGE}) end
        if Flags.SilentAim then table.insert(features, {"Silent", C_PURPLE}) end

        -- ESP features
        if Flags.ESP_Box then table.insert(features, {"ESP", C_CYAN}) end
        if Flags.ESP_Name then table.insert(features, {"Name", C_CYAN}) end
        if Flags.ESP_Health then table.insert(features, {"HP", C_GREEN}) end
        if Flags.ESP_Skeleton then table.insert(features, {"Skel", C_YELLOW}) end

        -- Movement
        if Flags.Bhop then table.insert(features, {"Bhop", C_YELLOW}) end
        if Flags.NoClip then table.insert(features, {"NoClip", C_RED}) end
        if Flags.SpeedBoost then table.insert(features, {"Speed", C_ORANGE}) end

        -- Safety
        if Flags.StealthHumanize then table.insert(features, {"Humanize", C_GREEN}) end
        if Flags.HVHSafeMode then table.insert(features, {"HVH Safe", C_GREEN}) end

        for i, feat in ipairs(features) do
            local obj = getHUDObject("feat_" .. i)
            obj.Text = " " .. feat[1]
            obj.Size = size - 2
            obj.Position = getHUDPosition(1, featLine)
            obj.Color = feat[2]
            obj.Visible = true
            featLine = featLine + 1
        end
    end

     -- Risk Level
    if Flags.HUDRisk then
        local riskObj = getHUDObject("risk")
        local risk = 0
        if BS.Stealth and BS.Stealth.RiskLevel then
            risk = BS.Stealth.RiskLevel
        end
        riskObj.Text = string.format("Risk: %d%%", risk)
        riskObj.Size = size
        riskObj.Position = getHUDPosition(1, featLine)
        riskObj.Color = risk < 30 and C_GREEN or risk < 60 and C_YELLOW or C_RED
        riskObj.Visible = true
        featLine = featLine + 1
    end

     -- Active Modules
    if Flags.HUDModules then
        local modObj = getHUDObject("modules")
        local activeCount = 0
        local moduleNames = {"Combat", "ESP", "Rage", "Stealth", "Bhop", "Bypass"}
        local moduleFlags = {Flags.Aimbot or Flags.Ragebot, Flags.ESP_Box, Flags.AA, Flags.StealthHumanize, Flags.Bhop, true}

        local activeModules = {}
        for i, name in ipairs(moduleNames) do
            if moduleFlags[i] then
                table.insert(activeModules, name)
                activeCount = activeCount + 1
            end
        end

        modObj.Text = "Modules (" .. activeCount .. "): " .. table.concat(activeModules, ", ")
        modObj.Size = size - 2
        modObj.Position = getHUDPosition(1, featLine)
        modObj.Color = C_BLUE
        modObj.Visible = true
        featLine = featLine + 1
    end

     -- Weapon Info
    if Flags.HUDWeapon then
        local wpnObj = getHUDObject("weapon")
        local wType = BS.weaponType and BS.weaponType() or "none"
        local tool = BS.tool and BS.tool()
        local toolName = tool and tool.Name or "None"
        wpnObj.Text = "Weapon: " .. toolName .. " [" .. wType .. "]"
        wpnObj.Size = size
        wpnObj.Position = getHUDPosition(1, featLine)
        wpnObj.Color = C_YELLOW
        wpnObj.Visible = true
        featLine = featLine + 1
    end

     -- Player Info
    if Flags.HUDPlayerInfo then
        local plrObj = getHUDObject("playerinfo")
        local hp = 0
        local maxHp = 100
        local speed = 16
        if BS.alive() then
            local h = BS.hum()
            if h then
                hp = h.Health
                maxHp = h.MaxHealth
                speed = h.WalkSpeed
            end
        end
        plrObj.Text = string.format("HP: %d/%d | Speed: %.0f | Pos: %s",
            math.floor(hp), math.floor(maxHp), speed,
            BS.hrp() and string.format("(%.0f,%.0f,%.0f)", BS.hrp().Position.X, BS.hrp().Position.Y, BS.hrp().Position.Z) or "N/A")
        plrObj.Size = size
        plrObj.Position = getHUDPosition(1, featLine)
        plrObj.Color = hp > maxHp * 0.6 and C_GREEN or hp > maxHp * 0.3 and C_YELLOW or C_RED
        plrObj.Visible = true
        featLine = featLine + 1
    end

     -- Combat HUD Section
    local combatLine = 0
    if Flags.HUDKD and BS.CombatAssist then
        local s = BS.CombatAssist.SessionStats
        local kdObj = getHUDObject("kd")
        local kd = s.Deaths > 0 and string.format("%.2f", s.Kills / s.Deaths) or ""
        kdObj.Text = string.format("K/D: %d/%d (%s)", s.Kills, s.Deaths, kd)
        kdObj.Size = size
        kdObj.Position = getHUDPosition(2, combatLine)
        kdObj.Color = C_WHITE
        kdObj.Visible = true
        combatLine = combatLine + 1
    end

    if Flags.HUDAccuracy and BS.CombatAssist then
        local s = BS.CombatAssist.SessionStats
        local accObj = getHUDObject("accuracy")
        local acc = s.Shots > 0 and string.format("%.1f%%", s.HitCount / s.Shots * 100) or "0%"
        accObj.Text = "Acc: " .. acc .. " | HS: " .. (s.Kills > 0 and string.format("%.0f%%", s.Headshots / s.Kills * 100) or "0%")
        accObj.Size = size
        accObj.Position = getHUDPosition(2, combatLine)
        accObj.Color = C_CYAN
        accObj.Visible = true
        combatLine = combatLine + 1
    end

    if Flags.HUDStreak and BS.CombatAssist then
        local s = BS.CombatAssist.SessionStats
        local streakObj = getHUDObject("streak")
        streakObj.Text = string.format("Streak: %d | Best: %d", s.KillStreak, s.MaxKillStreak)
        streakObj.Size = size
        streakObj.Position = getHUDPosition(2, combatLine)
        streakObj.Color = s.KillStreak >= 5 and C_RED or s.KillStreak >= 3 and C_ORANGE or C_WHITE
        streakObj.Visible = true
        combatLine = combatLine + 1
    end

    if Flags.HUDVelocity and BS.alive() then
        local velObj = getHUDObject("velocity")
        local hrp = BS.hrp()
        if hrp then
            local vel = hrp.AssemblyLinearVelocity
            local speed = vel.Magnitude
            velObj.Text = string.format("Vel: %.1f (%.1f, %.1f, %.1f)", speed, vel.X, vel.Y, vel.Z)
            velObj.Size = size
            velObj.Position = getHUDPosition(2, combatLine)
            velObj.Color = speed > 50 and C_RED or speed > 20 and C_YELLOW or C_WHITE
            velObj.Visible = true
            combatLine = combatLine + 1
        end
    end

    if Flags.HUDSpeed and BS.alive() then
        local spdObj = getHUDObject("speed")
        local h = BS.hum()
        if h then
            spdObj.Text = string.format("Speed: %.0f studs/s", h.WalkSpeed * 3)
            spdObj.Size = size
            spdObj.Position = getHUDPosition(2, combatLine)
            spdObj.Color = C_GREEN
            spdObj.Visible = true
            combatLine = combatLine + 1
        end
    end

     -- Health Crosshair
    if Flags.HUDHealthCross and BS.alive() then
        local hcObj = getHUDObject("healthcross")
        local h = BS.hum()
        if h then
            local pct = h.Health / h.MaxHealth * 100
            hcObj.Text = string.format(" %d", math.floor(h.Health))
            hcObj.Size = size
            hcObj.Center = true
            hcObj.Position = Vector2.new(400, 280)
            hcObj.Color = pct > 60 and C_GREEN or pct > 30 and C_YELLOW or C_RED
            hcObj.Visible = true
        end
    else
        local hcObj = getHUDObject("healthcross")
        if hcObj then hcObj.Visible = false end
    end

     -- Notification Center
    if Flags.HUDNotifications and #NotifQueue > 0 then
        local maxNotif = Flags.HUDMaxNotif or 5
        local notifLine = 0
        for i = #NotifQueue, math.max(1, #NotifQueue - maxNotif + 1), -1 do
            local notif = NotifQueue[i]
            local age = tick() - notif.Time
            if age < 8 then -- Fade after 8 seconds
                local nObj = getHUDObject("notif_" .. i)
                nObj.Text = notif.Text
                nObj.Size = size - 2
                nObj.Position = getHUDPosition(3, notifLine)
                nObj.Color = notif.Color or C_WHITE
                nObj.Transparency = math.clamp(1 - age / 8, 0, 1)
                nObj.Visible = true
                notifLine = notifLine + 1
            end
        end
    end
end)

 -- Notification System
function HUD.addNotification(text, color, duration)
    table.insert(NotifQueue, {
        Text = text,
        Color = color or C_WHITE,
        -- Time = tick(),
        Duration = duration or 5,
    })
    -- Trim old
    if #NotifQueue > 20 then
        table.remove(NotifQueue, 1)
    end

    -- Also show Roblox notification if enabled
    if Flags.HUDFeatureNotif then
        pcall(function()
             StarterGui:SetCore("SendNotification", {
                Title = "BloxStrike",
                Text = text,
                Duration = duration or 3,
            })
        end)
    end
end

 -- Feature Toggle Listener
-- Watch for flag changes and show notifications
local lastFlags = {}
task.spawn(function()
    while true do task.wait(0.5)
        if Flags.HUDFeatureNotif then
            for key, value in pairs(Flags) do
                if type(value) == "boolean" and lastFlags[key] ~= nil and lastFlags[key] ~= value then
                    local state = value and " ON" or " OFF"
                    HUD.addNotification(key .. " " .. state, value and C_GREEN or C_RED, 2)
                end
                lastFlags[key] = value
            end
        end
    end
end)

 -- Session Reset on Respawn
lplr.CharacterAdded:Connect(function()
    -- Don't reset stats on respawn
end)

 -- Cleanup
function HUD.cleanup()
    for _, obj in pairs(HUDObjects) do
        pcall(function() obj.Visible = false obj:Remove() end)
    end
    HUDObjects = {}
    NotifQueue = {}
end

 -- Expose

-- Watermark Implementation
local WatermarkObj = nil
local function updateWatermark()
    if not Flags.Watermark then
        if WatermarkObj then WatermarkObj.Visible = false end
        return
    end
    if not WatermarkObj then
        pcall(function() WatermarkObj = Drawing.new("Text") end)
        if not WatermarkObj then return end
        WatermarkObj.Center = false
        WatermarkObj.Outline = true
        WatermarkObj.OutlineColor = Color3.new(0,0,0)
        WatermarkObj.Font = 2
        WatermarkObj.Size = 14
    end
    local parts = {"BloxStrike v3.0"}
    if Flags.WMFPS then table.insert(parts, math.floor(1/workspace.CurrentCamera:GetPropertyChangedSignal("CFrame"):Wait() and 60 or 60) .. " FPS") end
    if Flags.WMPing then
        pcall(function()
            local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"].Value)
            table.insert(parts, ping .. " ms")
        end)
    end
    if Flags.WMServer then table.insert(parts, game:GetService("Workspace").Name) end
    if Flags.WMPlayers then table.insert(parts, #game:GetService("Players"):GetPlayers() .. " players") end
    if Flags.WMTime then table.insert(parts, os.date("%H:%M:%S")) end
    WatermarkObj.Text = "  " .. table.concat(parts, " | ") .. "  "
    WatermarkObj.Position = Vector2.new(10, 10)
    WatermarkObj.Color = Color3.new(1,1,1)
    WatermarkObj.Visible = true
end

-- Spectator List Implementation
local SpectatorObjs = {}
local function updateSpectators()
    if not Flags.SpectatorList then
        for _, obj in pairs(SpectatorObjs) do pcall(function() obj.Visible = false end) end
        SpectatorObjs = {}
        return
    end
    local myChar = lplr.Character
    if not myChar then return end
    local myHead = myChar:FindFirstChild("Head")
    if not myHead then return end
    local specs = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lplr and p.Character then
            local cam = p and p.Character:FindFirstChildOfClass("Camera")
            if cam and cam.CameraSubject == myHead then
                table.insert(specs, p.Name)
            end
        end
    end
    for i = 1, math.max(#specs, #SpectatorObjs) do
        if not SpectatorObjs[i] then
            pcall(function() SpectatorObjs[i] = Drawing.new("Text") end)
        end
        if SpectatorObjs[i] then
            if i <= #specs then
                SpectatorObjs[i].Text = specs[i]
                SpectatorObjs[i].Position = Vector2.new(10, 30 + (i-1) * 18)
                SpectatorObjs[i].Color = Color3.new(1,1,1)
                SpectatorObjs[i].Size = 13
                SpectatorObjs[i].Outline = true
                SpectatorObjs[i].Visible = true
            else
                SpectatorObjs[i].Visible = false
            end
        end
    end
end

-- Kill Counter Implementation
local SessionKills = 0
local SessionDeaths = 0
local SessionHeadshots = 0
local SessionShots = 0
local SessionHits = 0
local KillCounterObj = nil

local function updateKillCounter()
    if not Flags.KillCounter then
        if KillCounterObj then KillCounterObj.Visible = false end
        return
    end
    if not KillCounterObj then
        pcall(function() KillCounterObj = Drawing.new("Text") end)
        if not KillCounterObj then return end
        KillCounterObj.Center = false
        KillCounterObj.Outline = true
        KillCounterObj.OutlineColor = Color3.new(0,0,0)
        KillCounterObj.Font = 2
        KillCounterObj.Size = 13
    end
    local parts = {}
    if Flags.KDShow then
        local kd = SessionDeaths > 0 and string.format("%.1f", SessionKills/SessionDeaths) or tostring(SessionKills)
        table.insert(parts, "K/D: " .. SessionKills .. "/" .. SessionDeaths .. " (" .. kd .. ")")
    end
    if Flags.HSShow and SessionKills > 0 then
        table.insert(parts, "HS: " .. math.floor(SessionHeadshots/SessionKills*100) .. "%")
    end
    if Flags.AccShow and SessionShots > 0 then
        table.insert(parts, "Acc: " .. math.floor(SessionHits/SessionShots*100) .. "%")
    end
    KillCounterObj.Text = "  " .. table.concat(parts, " | ") .. "  "
    KillCounterObj.Position = Vector2.new(10, workspace.CurrentCamera.ViewportSize.Y - 30)
    KillCounterObj.Color = Color3.new(1,1,0.5)
    KillCounterObj.Visible = #parts > 0
end

-- Listen for kills/deaths
lplr.CharacterAdded:Connect(function()
    task.delay(0.5, function()
        local hum = lplr.Character and lplr and lplr.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Died:Connect(function()
                SessionDeaths = SessionDeaths + 1
            end)
        end
    end)
end)

-- HUD update loop
task.spawn(function()
    while true do
        task.wait(0.2)
        pcall(function()
            updateWatermark()
            updateSpectators()
            updateKillCounter()
        end)
    end
end)

-- Expose kill tracking
HUD.trackKill = function(wasHeadshot)
    SessionKills = SessionKills + 1
    if wasHeadshot then SessionHeadshots = SessionHeadshots + 1 end
end
HUD.trackShot = function() SessionShots = SessionShots + 1 end
HUD.trackHit = function() SessionHits = SessionHits + 1 end


BS.HUD = HUD

print("[HUD] BloxStrike HUD v1.0 loaded")
print("[HUD] Features: Performance Monitor, Feature Status, Combat HUD,")
print("[HUD]   Notification Center, Health Crosshair, Velocity Display")
