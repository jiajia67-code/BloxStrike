

-- BLOXSTRIKE KILL EFFECTS MODULE v2.0
-- 30+ Sounds, 15+ Visual Effects, Kill Streak, Kill Feed

local Players = nil

pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local Lighting = nil
pcall(function() Lighting = game:GetService("Lighting") end)
local UIS = nil
pcall(function() UIS = game:GetService("UserInputService") end)
local lplr = Players.LocalPlayer

-- HITMARKER GUI
if not BS.Win then warn("[Hit Effects] BS.Win not available - ui.lua may have failed") return end
local KE = BS.Win:Tab("雜項")
if KE and KE.Toggle then
    KE:Label(" Hitmarker ")
    KE:Toggle("Hitmarker", false, function(v) Flags.Hitmarker = v end)
    KE:Dropdown({Name="Hitmarker Style", Flag="HMStyle", Options={"CS2","MW2","Fortnite","Custom"}, Default="CS2"})
    KE:Slider("Hitmarker Size", 5, 30, 12, function(v) Flags.HMSize = v end)
    KE:Slider("Hitmarker Duration", 1, 10, 3, function(v) Flags.HMDuration = v end)
    KE:Toggle("Headshot Marker", true, function(v) Flags.HMHeadshot = v end)
    KE:Toggle("Hit Sound", false, function(v) Flags.HitSound = v end)
    KE:Dropdown({Name="Hit Sound", Flag="HMSound", Options={"CS2 Dink","Quake Hit","Metal Pipe","Minecraft XP","Vine Boom"}, Default="CS2 Dink"})
    KE:Slider("Hit Sound Volume", 1, 10, 5, function(v) Flags.HMSoundVol = v end)
    KE:Separator()
    KE:Label(" Kill Effect ")
    KE:Toggle("Kill Effect", false, function(v) Flags.KillEffect = v end)
    KE:Dropdown({Name="Kill Style", Flag="KEStyle", Options={"Flash","Shake","Zoom","SlowMo"}, Default="Flash"})
    KE:Toggle("Kill Sound", false, function(v) Flags.KillSound = v end)
    KE:Dropdown({Name="Kill Sound", Flag="KESound", Options={"Frag","Explosion","Metal Pipe","Mario Coin"}, Default="Frag"})
    KE:Slider("Kill Sound Volume", 1, 10, 7, function(v) Flags.KESoundVol = v end)
    KE:Toggle("Kill Streak Sound", false, function(v) Flags.KillStreakSound = v end)
    KE:Separator()
    KE:Label(" Damage Indicator ")
    KE:Toggle("Damage Numbers", false, function(v) Flags.DmgNumbers = v end)
    KE:Toggle("Damage Direction", false, function(v) Flags.DmgDirection = v end)
    KE:Slider("Damage Duration", 1, 10, 3, function(v) Flags.DmgDuration = v end)
end

-- SOUND DATABASE  30+ Sound IDs

local Sounds = {
     -- Kill Sounds (20+ styles)
    Kill = {
        {Name = "CS2 Dink",          ID = "rbxassetid://9125402735",  Vol = 0.8},
        {Name = "Quake Hit",         ID = "rbxassetid://138087576",   Vol = 0.7},
        {Name = "Metal Pipe",        ID = "rbxassetid://9125999404",  Vol = 0.6},
        {Name = "Minecraft XP",      ID = "rbxassetid://142376098",   Vol = 0.5},
        {Name = "Vine Boom",         ID = "rbxassetid://9126214519",  Vol = 0.5},
        {Name = "Mario Coin",        ID = "rbxassetid://138087606",   Vol = 0.6},
        {Name = "Frag",              ID = "rbxassetid://3124961779",  Vol = 0.7},
        {Name = "Heavy Impact",      ID = "rbxassetid://18900180842", Vol = 0.8},
        {Name = "Sharp Slash",       ID = "rbxassetid://18834235361", Vol = 0.7},
        {Name = "Punch Hit",         ID = "rbxassetid://18834234238", Vol = 0.6},
        {Name = "Explosion",         ID = "rbxassetid://13134985300", Vol = 0.9},
        {Name = "Blade Hit",         ID = "rbxassetid://3932145654",  Vol = 0.7},
        {Name = "Electric Zap",      ID = "rbxassetid://4086012327",  Vol = 0.6},
        {Name = "Heavy Smash",       ID = "rbxassetid://15294800508", Vol = 0.9},
        {Name = "Body Fall",         ID = "rbxassetid://16190706844", Vol = 0.5},
        {Name = "Block Break",       ID = "rbxassetid://13106548051", Vol = 0.6},
        {Name = "Fire Blast",        ID = "rbxassetid://13441650522", Vol = 0.7},
        {Name = "Collapse",          ID = "rbxassetid://3784889529",  Vol = 0.8},
        {Name = "Clock Tick",        ID = "rbxassetid://8140501675",  Vol = 0.4},
        {Name = "Notification",      ID = "rbxassetid://8551372796",  Vol = 0.5},
    },

     -- Headshot Sounds (10+ styles)
    Headshot = {
        {Name = "CS2 Headshot",      ID = "rbxassetid://9125402735",  Vol = 0.9},
        {Name = "Quake Headshot",    ID = "rbxassetid://138087576",   Vol = 0.8},
        {Name = "Sharp Crack",       ID = "rbxassetid://18834235361", Vol = 0.9},
        {Name = "Heavy Smash HS",    ID = "rbxassetid://15294800508", Vol = 1.0},
        {Name = "Explosion HS",      ID = "rbxassetid://13134985300", Vol = 0.9},
        {Name = "Electric Zap HS",   ID = "rbxassetid://4086012327",  Vol = 0.8},
        {Name = "Blade Crit",        ID = "rbxassetid://3932145654",  Vol = 0.9},
        {Name = "Vine Boom HS",      ID = "rbxassetid://9126214519",  Vol = 0.7},
    },

     -- Hit Sounds (8 styles)
    Hit = {
        {Name = "Hit Classic",       ID = "rbxassetid://138087576",   Vol = 0.3},
        {Name = "Hit Soft",          ID = "rbxassetid://138087546",   Vol = 0.25},
        {Name = "Hit Sharp",         ID = "rbxassetid://138087587",   Vol = 0.35},
        {Name = "Hit Ding",          ID = "rbxassetid://142376098",   Vol = 0.2},
        {Name = "Hit Punch",         ID = "rbxassetid://18834234238", Vol = 0.3},
        {Name = "Hit Blade",         ID = "rbxassetid://3932145654",  Vol = 0.25},
        {Name = "Hit Impact",        ID = "rbxassetid://18900180842", Vol = 0.3},
        {Name = "Hit Zap",           ID = "rbxassetid://4086012327",  Vol = 0.2},
    },

     -- Streak Sounds
    DoubleKill  = {ID = "rbxassetid://18900180842", Vol = 0.85},
    TripleKill  = {ID = "rbxassetid://13134985300", Vol = 0.9},
    QuadKill    = {ID = "rbxassetid://15294800508", Vol = 0.95},
    PentaKill   = {ID = "rbxassetid://13441650522", Vol = 1.0},
    Unstoppable = {ID = "rbxassetid://13143785092", Vol = 1.0},
    Rampage     = {ID = "rbxassetid://13143785795", Vol = 1.0},
    Godlike     = {ID = "rbxassetid://13079933410", Vol = 1.0},

     -- Death Sound
    Death = {ID = "rbxassetid://16190703134", Vol = 0.6},
}

-- KILL FEED

local KillFeed = {}
local KillFeedMax = 8

-- GUI REFERENCES

local killEffectGui = nil
local killFeedGui = nil
local streakGui = nil
local vignetteGui = nil

-- LIGHTING EFFECTS (Post-Processing)

local function createLightingEffect(name, className)
    local existing = Lighting:FindFirstChild(name)
    if existing then return existing end
    local effect = Instance.new(className)
    effect.Name = name
    effect.Enabled = false
    effect.Parent = Lighting
    return effect
end

local blurEffect = createLightingEffect("BS_KillBlur", "BlurEffect")
blurEffect.Size = 0

local colorCorrection = createLightingEffect("BS_KillCC", "ColorCorrectionEffect")
colorCorrection.Brightness = 0
colorCorrection.Contrast = 0
colorCorrection.Saturation = 0
colorCorrection.TintColor = Color3.fromRGB(255, 255, 255)

local bloomEffect = createLightingEffect("BS_KillBloom", "BloomEffect")
bloomEffect.Intensity = 0
bloomEffect.Size = 0
bloomEffect.Threshold = 1

local sunRays = createLightingEffect("BS_KillSunRays", "SunRaysEffect")
sunRays.Intensity = 0
sunRays.Spread = 0.5

-- HELPER: Play Sound

local function playSound(soundData, pitch)
    if not soundData or not soundData.ID then return end
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = soundData.ID
        s.Volume = soundData.Vol or 0.5
        s.PlaybackSpeed = pitch or 1.0
        s.Parent = lplr.Character and lplr and lplr.Character:FindFirstChild("HumanoidRootPart") or workspace
        s:Play()
        game:GetService("Debris"):AddItem(s, 2)
    end)
end

local function playSoundFromList(list, index, pitch)
    local idx = index or 1
    local data = list[idx] or list[1]
    playSound(data, pitch)
end

-- SCREEN EFFECT: Blur Flash

local function doBlurFlash(intensity, duration)
    if not Flags.FXBlur then return end
    pcall(function()
        blurEffect.Enabled = true
        blurEffect.Size = intensity or 20

        task.spawn(function()
            local start = tick()
            while tick() - start < (duration or 0.3) do
                local pct = (tick() - start) / (duration or 0.3)
                blurEffect.Size = (intensity or 20) * (1 - pct)
                RunService.RenderStepped:Wait()
            end
            blurEffect.Size = 0
            blurEffect.Enabled = false
        end)
    end)
end

-- SCREEN EFFECT: Color Correction Flash

local function doColorFlash(color, contrast, duration)
    if not Flags.FXColorFlash then return end
    pcall(function()
        colorCorrection.Enabled = true
        colorCorrection.TintColor = color or Color3.fromRGB(255, 200, 200)
        colorCorrection.Contrast = contrast or 0.5
        colorCorrection.Brightness = 0.2

        task.spawn(function()
            local start = tick()
            while tick() - start < (duration or 0.4) do
                local pct = (tick() - start) / (duration or 0.4)
                colorCorrection.Contrast = (contrast or 0.5) * (1 - pct)
                colorCorrection.Brightness = 0.2 * (1 - pct)
                colorCorrection.Saturation = 0.5 * (1 - pct)
                RunService.RenderStepped:Wait()
            end
            colorCorrection.Contrast = 0
            colorCorrection.Brightness = 0
            colorCorrection.Saturation = 0
            colorCorrection.TintColor = Color3.fromRGB(255, 255, 255)
            colorCorrection.Enabled = false
        end)
    end)
end

-- SCREEN EFFECT: Bloom Flash

local function doBloomFlash(intensity, duration)
    if not Flags.FXBloom then return end
    pcall(function()
        bloomEffect.Enabled = true
        bloomEffect.Intensity = intensity or 2
        bloomEffect.Size = 30
        bloomEffect.Threshold = 0.5

        task.spawn(function()
            local start = tick()
            while tick() - start < (duration or 0.5) do
                local pct = (tick() - start) / (duration or 0.5)
                bloomEffect.Intensity = (intensity or 2) * (1 - pct)
                RunService.RenderStepped:Wait()
            end
            bloomEffect.Intensity = 0
            bloomEffect.Enabled = false
        end)
    end)
end

-- SCREEN EFFECT: Sun Rays Flash

local function doSunRaysFlash(duration)
    if not Flags.FXSunRays then return end
    pcall(function()
        sunRays.Enabled = true
        sunRays.Intensity = 0.8

        task.spawn(function()
            local start = tick()
            while tick() - start < (duration or 0.4) do
                local pct = (tick() - start) / (duration or 0.4)
                sunRays.Intensity = 0.8 * (1 - pct)
                RunService.RenderStepped:Wait()
            end
            sunRays.Intensity = 0
            sunRays.Enabled = false
        end)
    end)
end

-- SCREEN EFFECT: Vignette (Red edges)

local function doVignette(color, duration)
    if not Flags.FXVignette then return end
    pcall(function()
        if not vignetteGui then
            vignetteGui = Instance.new("ScreenGui")
            vignetteGui.Name = "BS_Vignette"
            vignetteGui.IgnoreGuiInset = true
            vignetteGui.DisplayOrder = 10002
            vignetteGui.Parent = lplr.PlayerGui
        end

        -- Top gradient
        local top = Instance.new("ImageLabel")
        top.Size = UDim2.new(1, 0, 0.4, 0)
        top.Position = UDim2.new(0, 0, 0, 0)
        top.BackgroundTransparency = 1
        top.Image = "rbxassetid://1039949736" -- gradient
        top.ImageColor3 = color or Color3.fromRGB(255, 0, 0)
        top.ImageTransparency = 0.5
        top.ScaleType = Enum.ScaleType.Stretch
        top.ZIndex = 10001
        top.Parent = vignetteGui

        -- Bottom gradient
        local bot = Instance.new("ImageLabel")
        bot.Size = UDim2.new(1, 0, 0.4, 0)
        bot.Position = UDim2.new(0, 0, 0.6, 0)
        bot.BackgroundTransparency = 1
        bot.Image = "rbxassetid://1039949736"
        bot.ImageColor3 = color or Color3.fromRGB(255, 0, 0)
        bot.ImageTransparency = 0.5
        bot.ScaleType = Enum.ScaleType.Stretch
        bot.Rotation = 180
        bot.ZIndex = 10001
        bot.Parent = vignetteGui

        -- Left gradient
        local left = Instance.new("ImageLabel")
        left.Size = UDim2.new(0.3, 0, 1, 0)
        left.Position = UDim2.new(0, 0, 0, 0)
        left.BackgroundTransparency = 1
        left.Image = "rbxassetid://1039949736"
        left.ImageColor3 = color or Color3.fromRGB(255, 0, 0)
        left.ImageTransparency = 0.6
        left.ScaleType = Enum.ScaleType.Stretch
        left.Rotation = 90
        left.ZIndex = 10001
        left.Parent = vignetteGui

        -- Right gradient
        local right = Instance.new("ImageLabel")
        right.Size = UDim2.new(0.3, 0, 1, 0)
        right.Position = UDim2.new(0.7, 0, 0, 0)
        right.BackgroundTransparency = 1
        right.Image = "rbxassetid://1039949736"
        right.ImageColor3 = color or Color3.fromRGB(255, 0, 0)
        right.ImageTransparency = 0.6
        right.ScaleType = Enum.ScaleType.Stretch
        right.Rotation = 270
        right.ZIndex = 10001
        right.Parent = vignetteGui

        task.spawn(function()
            local start = tick()
            while tick() - start < (duration or 0.5) do
                local pct = (tick() - start) / (duration or 0.5)
                local trans = 0.5 + pct * 0.5
                top.ImageTransparency = trans
                bot.ImageTransparency = trans
                left.ImageTransparency = trans + 0.1
                right.ImageTransparency = trans + 0.1
                RunService.RenderStepped:Wait()
            end
            -- vignetteGui:ClearAllChildren()
        end)
    end)
end

-- SCREEN EFFECT: Screen Flash (Frame)

local function doScreenFlash(color, transparency, duration)
    if not Flags.FXFlash then return end
    pcall(function()
        if not killEffectGui then
            killEffectGui = Instance.new("ScreenGui")
            killEffectGui.Name = "BS_KillEffect"
            killEffectGui.IgnoreGuiInset = true
            killEffectGui.DisplayOrder = 10000
            killEffectGui.Parent = lplr.PlayerGui
        end

        local flash = Instance.new("Frame")
        flash.Size = UDim2.new(1, 0, 1, 0)
        flash.BackgroundColor3 = color or Color3.fromRGB(255, 255, 255)
        flash.BackgroundTransparency = transparency or 0.4
        flash.BorderSizePixel = 0
        flash.ZIndex = 9999
        flash.Parent = killEffectGui

        task.spawn(function()
            local start = tick()
            while tick() - start < (duration or 0.3) do
                local pct = (tick() - start) / (duration or 0.3)
                flash.BackgroundTransparency = (transparency or 0.4) + pct * (1 - (transparency or 0.4))
                RunService.RenderStepped:Wait()
            end
            -- flash:Destroy()
        end)
    end)
end

-- SCREEN EFFECT: Screen Shake

local function doScreenShake(intensity, duration)
    if not Flags.FXShake then return end
    pcall(function()
        local cam = workspace.CurrentCamera
        if not cam then return end

        local startTime = tick()
        local conn
        conn = RunService.RenderStepped:Connect(function()
            local elapsed = tick() - startTime
            if elapsed > duration then
                -- conn:Disconnect()
                -- return
            end
            local fade = 1 - (elapsed / duration)
            local sx = (math.random() - 0.5) * intensity * fade
            local sy = (math.random() - 0.5) * intensity * fade
            local sz = (math.random() - 0.5) * intensity * fade * 0.3
            cam.CFrame = cam.CFrame * CFrame.new(sx, sy, sz)
        end)
    end)
end

-- SCREEN EFFECT: Chromatic Aberration (RGB Split)

local function doChromaticAberration(intensity, duration)
    if not Flags.FXChromatic then return end
    pcall(function()
        if not killEffectGui then
            killEffectGui = Instance.new("ScreenGui")
            killEffectGui.Name = "BS_KillEffect"
            killEffectGui.IgnoreGuiInset = true
            killEffectGui.DisplayOrder = 10000
            killEffectGui.Parent = lplr.PlayerGui
        end

        local offset = intensity or 4

        -- Red layer (shifted left)
        local redLayer = Instance.new("Frame")
        redLayer.Size = UDim2.new(1, 0, 1, 0)
        redLayer.Position = UDim2.new(0, -offset, 0, 0)
        redLayer.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        redLayer.BackgroundTransparency = 0.85
        redLayer.BorderSizePixel = 0
        redLayer.ZIndex = 9997
        redLayer.Parent = killEffectGui

        -- Blue layer (shifted right)
        local blueLayer = Instance.new("Frame")
        blueLayer.Size = UDim2.new(1, 0, 1, 0)
        blueLayer.Position = UDim2.new(0, offset, 0, 0)
        blueLayer.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
        blueLayer.BackgroundTransparency = 0.85
        blueLayer.BorderSizePixel = 0
        blueLayer.ZIndex = 9997
        blueLayer.Parent = killEffectGui

        task.spawn(function()
            local start = tick()
            while tick() - start < (duration or 0.2) do
                local pct = (tick() - start) / (duration or 0.2)
                local alpha = 0.85 + pct * 0.15
                redLayer.BackgroundTransparency = alpha
                blueLayer.BackgroundTransparency = alpha
                RunService.RenderStepped:Wait()
            end
            -- redLayer:Destroy()
            -- blueLayer:Destroy()
        end)
    end)
end

-- SCREEN EFFECT: Slow Motion (FOV warp)

local function doSlowMotion(scale, duration)
    if not Flags.FXSlowMo then return end
    pcall(function()
        local cam = workspace.CurrentCamera
        if not cam then return end

        local origFOV = cam.FieldOfView
        local targetFOV = origFOV * (scale or 0.7)

        task.spawn(function()
            local start = tick()
            -- Zoom in
            while tick() - start < 0.1 do
                local pct = (tick() - start) / 0.1
                cam.FieldOfView = origFOV + (targetFOV - origFOV) * pct
                RunService.RenderStepped:Wait()
            end
            -- Hold
            task.wait(duration or 0.3)
            -- Zoom out
            local returnStart = tick()
            while tick() - returnStart < 0.2 do
                local pct = (tick() - returnStart) / 0.2
                cam.FieldOfView = targetFOV + (origFOV - targetFOV) * pct
                RunService.RenderStepped:Wait()
            end
            cam.FieldOfView = origFOV
        end)
    end)
end

-- SCREEN EFFECT: Damage Direction Indicator

local function doDamageIndicator(angle, color)
    if not Flags.FXDamageDir then return end
    pcall(function()
        if not killEffectGui then
            killEffectGui = Instance.new("ScreenGui")
            killEffectGui.Name = "BS_KillEffect"
            killEffectGui.IgnoreGuiInset = true
            killEffectGui.DisplayOrder = 10000
            killEffectGui.Parent = lplr.PlayerGui
        end

        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0, 60, 0, 60)
        indicator.AnchorPoint = Vector2.new(0.5, 0.5)
        indicator.Position = UDim2.new(0.5, 0, 0.5, 0)
        indicator.BackgroundTransparency = 1
        indicator.Rotation = angle or 0
        indicator.ZIndex = 9998
        indicator.Parent = killEffectGui

        local arrow = Instance.new("ImageLabel")
        arrow.Size = UDim2.new(1, 0, 0.3, 0)
        arrow.Position = UDim2.new(0, 0, 0.1, 0)
        arrow.BackgroundTransparency = 1
        arrow.Image = "rbxassetid://1039949736"
        arrow.ImageColor3 = color or Color3.fromRGB(255, 0, 0)
        arrow.ImageTransparency = 0.3
        arrow.ScaleType = Enum.ScaleType.Stretch
        arrow.ZIndex = 9999
        arrow.Parent = indicator

        task.spawn(function()
            local start = tick()
            while tick() - start < 0.5 do
                local pct = (tick() - start) / 0.5
                arrow.ImageTransparency = 0.3 + pct * 0.7
                indicator.Position = UDim2.new(0.5, 0, 0.5 - pct * 0.05, 0)
                RunService.RenderStepped:Wait()
            end
            -- indicator:Destroy()
        end)
    end)
end

-- SCREEN EFFECT: Blood Particles

local function doBloodEffect(count)
    if not Flags.FxBlood then return end
    pcall(function()
        if not killEffectGui then
            killEffectGui = Instance.new("ScreenGui")
            killEffectGui.Name = "BS_KillEffect"
            killEffectGui.IgnoreGuiInset = true
            killEffectGui.DisplayOrder = 10000
            killEffectGui.Parent = lplr.PlayerGui
        end

        local vpSize = workspace.CurrentCamera.ViewportSize

        for i = 1, (count or 15) do
            local size = math.random(2, 7)
            local particle = Instance.new("Frame")
            particle.Size = UDim2.new(0, size, 0, size)
            particle.Position = UDim2.new(0.5 + (math.random() - 0.5) * 0.2, 0, 0.5 + (math.random() - 0.5) * 0.2, 0)
            particle.AnchorPoint = Vector2.new(0.5, 0.5)
            particle.BackgroundColor3 = Color3.fromRGB(150 + math.random(105), math.random(20), math.random(20))
            particle.BorderSizePixel = 0
            particle.Rotation = math.random(360)
            particle.ZIndex = 9998
            particle.Parent = killEffectGui

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent = particle

            task.spawn(function()
                local startTime = tick()
                local vx = (math.random() - 0.5) * 250
                local vy = -math.random(80, 350)
                local gravity = 900
                local startX = particle.Position.X.Scale
                local startY = particle.Position.Y.Scale

                while tick() - startTime < 0.7 do
                    local dt = RunService.RenderStepped:Wait()
                    local elapsed = tick() - startTime
                    vx = vx * 0.97
                    vy = vy + gravity * dt

                    particle.Position = UDim2.new(
                        -- startX + vx * elapsed / vpSize.X,
                        -- 0,
                        -- startY + vy * elapsed / vpSize.Y,
                        -- 0
                    )
                    particle.BackgroundTransparency = elapsed / 0.7
                end
                -- particle:Destroy()
            end)
        end
    end)
end

-- SCREEN EFFECT: Kill Ring (Expanding circle)

local function doKillRing(color)
    if not Flags.FxKillRing then return end
    pcall(function()
        if not killEffectGui then
            killEffectGui = Instance.new("ScreenGui")
            killEffectGui.Name = "BS_KillEffect"
            killEffectGui.IgnoreGuiInset = true
            killEffectGui.DisplayOrder = 10000
            killEffectGui.Parent = lplr.PlayerGui
        end

        local ring = Instance.new("Frame")
        ring.Size = UDim2.new(0, 10, 0, 10)
        ring.AnchorPoint = Vector2.new(0.5, 0.5)
        ring.Position = UDim2.new(0.5, 0, 0.5, 0)
        ring.BackgroundTransparency = 1
        ring.ZIndex = 9998
        ring.Parent = killEffectGui

        local circle = Instance.new("UIStroke")
        circle.Color = color or Color3.fromRGB(255, 50, 50)
        circle.Thickness = 3
        circle.Transparency = 0.3
        circle.Parent = ring

        Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)

        task.spawn(function()
            local start = tick()
            while tick() - start < 0.5 do
                local pct = (tick() - start) / 0.5
                local size = 10 + pct * 400
                ring.Size = UDim2.new(0, size, 0, size)
                circle.Transparency = 0.3 + pct * 0.7
                circle.Thickness = 3 * (1 - pct)
                RunService.RenderStepped:Wait()
            end
            -- ring:Destroy()
        end)
    end)
end

-- SCREEN EFFECT: White Flash Fade

local function doWhiteFlash(duration)
    if not Flags.FxWhiteFlash then return end
    doScreenFlash(Color3.fromRGB(255, 255, 255), 0.2, duration or 0.25)
end

-- SCREEN EFFECT: Red Flash Fade

local function doRedFlash(duration)
    if not Flags.FxRedFlash then return end
    doScreenFlash(Color3.fromRGB(255, 0, 0), 0.3, duration or 0.35)
end

-- SCREEN EFFECT: Desaturation (CS2 kill effect)

local function doDesaturation(amount, duration)
    if not Flags.FxDesat then return end
    pcall(function()
        colorCorrection.Enabled = true
        colorCorrection.Saturation = -(amount or 0.8)

        task.spawn(function()
            local start = tick()
            while tick() - start < (duration or 0.5) do
                local pct = (tick() - start) / (duration or 0.5)
                colorCorrection.Saturation = -(amount or 0.8) * (1 - pct)
                RunService.RenderStepped:Wait()
            end
            colorCorrection.Saturation = 0
            colorCorrection.Enabled = false
        end)
    end)
end

-- SCREEN EFFECT: FOV Punch (Quick zoom in/out)

local function doFOVPunch(amount, duration)
    if not Flags.FxFovPunch then return end
    pcall(function()
        local cam = workspace.CurrentCamera
        if not cam then return end

        local origFOV = cam.FieldOfView
        local start = tick()

        task.spawn(function()
            while tick() - start < (duration or 0.15) do
                local pct = (tick() - start) / (duration or 0.15)
                local fov = origFOV - (amount or 10) * math.sin(pct * math.pi)
                cam.FieldOfView = fov
                RunService.RenderStepped:Wait()
            end
            cam.FieldOfView = origFOV
        end)
    end)
end

-- SCREEN EFFECT: Horizontal Lines (Glitch)

local function doGlitchLines(count, duration)
    if not Flags.FxGlitch then return end
    pcall(function()
        if not killEffectGui then
            killEffectGui = Instance.new("ScreenGui")
            killEffectGui.Name = "BS_KillEffect"
            killEffectGui.IgnoreGuiInset = true
            killEffectGui.DisplayOrder = 10000
            killEffectGui.Parent = lplr.PlayerGui
        end

        for i = 1, (count or 5) do
            local line = Instance.new("Frame")
            line.Size = UDim2.new(1, 0, 0, math.random(1, 4))
            line.Position = UDim2.new(0, 0, math.random() * 1, 0)
            line.BackgroundColor3 = Color3.fromRGB(math.random(100, 255), math.random(100, 255), math.random(100, 255))
            line.BackgroundTransparency = 0.5
            line.BorderSizePixel = 0
            line.ZIndex = 9999
            line.Parent = killEffectGui

            task.spawn(function()
                task.wait(duration or 0.15)
                -- line:Destroy()
            end)
        end
    end)
end

-- STREAK TEXT

local streakNames = {
    -- [2] = "DOUBLE KILL",
    -- [3] = "TRIPLE KILL",
    -- [4] = "QUAD KILL",
    -- [5] = "PENTA KILL!",
    -- [7] = "UNSTOPPABLE!",
    -- [10] = "RAMPAGE!!",
    -- [15] = "GODLIKE!!!",
}

local streakColors = {
    -- [2] = Color3.fromRGB(255, 255, 0),
    -- [3] = Color3.fromRGB(255, 150, 0),
    -- [4] = Color3.fromRGB(255, 50, 0),
    -- [5] = Color3.fromRGB(255, 0, 0),
    -- [7] = Color3.fromRGB(200, 0, 255),
    -- [10] = Color3.fromRGB(255, 0, 150),
    -- [15] = Color3.fromRGB(255, 255, 255),
}

local function showStreakText(text, color, streak)
    if not Flags.FxStreakText then return end
    pcall(function()
        if not streakGui then
            streakGui = Instance.new("ScreenGui")
            streakGui.Name = "BS_Streak"
            streakGui.IgnoreGuiInset = true
            streakGui.DisplayOrder = 10001
            streakGui.Parent = lplr.PlayerGui
        end

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 60)
        label.Position = UDim2.new(0.5, 0, 0.3, 0)
        label.AnchorPoint = Vector2.new(0.5, 0.5)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = color
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.TextStrokeTransparency = 0.3
        label.TextSize = 30 + streak * 3
        label.Font = Enum.Font.GothamBold
        label.TextTransparency = 0
        label.Parent = streakGui

        task.spawn(function()
            local startTime = tick()
            while tick() - startTime < 2.0 do
                local elapsed = tick() - startTime
                if elapsed < 0.3 then
                    label.TextSize = (30 + streak * 3) * (1 + elapsed / 0.3 * 0.4)
                else
                    local fade = (elapsed - 0.3) / 1.7
                    label.TextTransparency = fade
                    label.TextStrokeTransparency = 0.3 + fade * 0.7
                    label.Position = UDim2.new(0.5, 0, 0.3 - fade * 0.08, 0)
                end
                RunService.RenderStepped:Wait()
            end
            -- label:Destroy()
        end)
    end)
end

-- KILL FEED (CS2 Style)

local function addKillFeedEntry(killer, victim, weapon, isHeadshot)
    if not Flags.FxKillFeed then return end

    pcall(function()
        if not killFeedGui then
            killFeedGui = Instance.new("ScreenGui")
            killFeedGui.Name = "BS_KillFeed"
            killFeedGui.IgnoreGuiInset = true
            killFeedGui.DisplayOrder = 9999
            killFeedGui.Parent = lplr.PlayerGui
        end

        table.insert(KillFeed, 1, {
            Killer = killer or "",
            Victim = victim or "",
            Weapon = weapon or "?",
            Headshot = isHeadshot or false,
            -- Time = tick(),
        })
        if #KillFeed > KillFeedMax then table.remove(KillFeed) end
        rebuildKillFeed()
    end)
end

function rebuildKillFeed()
    if not killFeedGui then return end
    for _, child in ipairs(killFeedGui:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    pcall(function()
        local entryH = 22
        local feedW = 320

        for i, entry in ipairs(KillFeed) do
            local alpha = math.clamp(1 - (tick() - entry.Time) / 5, 0, 1)
            if alpha <= 0 then table.remove(KillFeed, i); continue end

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(0, feedW, 0, entryH)
            frame.Position = UDim2.new(1, -feedW - 10, 0, 10 + (i - 1) * (entryH + 2))
            frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            frame.BackgroundTransparency = 0.4 + (1 - alpha) * 0.6
            frame.BorderSizePixel = 0
            frame.Parent = killFeedGui
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 3)

            local killerLabel = Instance.new("TextLabel")
            killerLabel.Size = UDim2.new(0.35, 0, 1, 0)
            killerLabel.Position = UDim2.new(0.02, 0, 0, 0)
            killerLabel.BackgroundTransparency = 1
            killerLabel.Text = entry.Killer
            killerLabel.TextColor3 = entry.Killer == lplr.DisplayName and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(255, 255, 255)
            killerLabel.TextSize = 11
            killerLabel.Font = Enum.Font.GothamBold
            killerLabel.TextXAlignment = Enum.TextXAlignment.Left
            killerLabel.TextTransparency = 1 - alpha
            killerLabel.Parent = frame

            local wepLabel = Instance.new("TextLabel")
            wepLabel.Size = UDim2.new(0.26, 0, 1, 0)
            wepLabel.Position = UDim2.new(0.37, 0, 0, 0)
            wepLabel.BackgroundTransparency = 1
            wepLabel.Text = entry.Headshot and (" " .. entry.Weapon) or ("[" .. entry.Weapon .. "]")
            wepLabel.TextColor3 = entry.Headshot and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(200, 200, 200)
            wepLabel.TextSize = 10
            wepLabel.Font = Enum.Font.Code
            wepLabel.TextTransparency = 1 - alpha
            wepLabel.Parent = frame

            local victimLabel = Instance.new("TextLabel")
            victimLabel.Size = UDim2.new(0.35, 0, 1, 0)
            victimLabel.Position = UDim2.new(0.63, 0, 0, 0)
            victimLabel.BackgroundTransparency = 1
            victimLabel.Text = entry.Victim
            victimLabel.TextColor3 = entry.Victim == lplr.DisplayName and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 200, 200)
            victimLabel.TextSize = 11
            victimLabel.Font = Enum.Font.GothamBold
            victimLabel.TextXAlignment = Enum.TextXAlignment.Right
            victimLabel.TextTransparency = 1 - alpha
            victimLabel.Parent = frame

            -- ::continue::
        end
    end)
end

-- Cleanup old feed entries
task.spawn(function()
    while true do
        task.wait(1)
        if #KillFeed > 0 then
            local removed = false
            for i = #KillFeed, 1, -1 do
                if tick() - KillFeed[i].Time > 5 then table.remove(KillFeed, i); removed = true end
            end
            if removed then rebuildKillFeed() end
        end
    end
end)

-- KILL TRACKING ENGINE

local prevHealth = {}
local killStreak = 0
local lastKillTime = 0
local killTimes = {}

local function onKill(victim, isHeadshot, weaponName)
    local now = tick()
    killStreak = killStreak + 1
    lastKillTime = now

    table.insert(killTimes, now)
    local recentKills = 0
    for i = #killTimes, 1, -1 do
        if now - killTimes[i] > 4 then table.remove(killTimes, i)
        else recentKills = recentKills + 1 end
    end

     -- Kill Sound
    if Flags.FxKillSound then
        local list = isHeadshot and Sounds.Headshot or Sounds.Kill
        local pitch = Flags.FxRandomPitch and (0.8 + math.random() * 0.4) or 1.0
        playSoundFromList(list, Flags.FxKillSoundIdx or 1, pitch)
    end

     -- Hit Sound
    if Flags.FxHitSound then
        playSoundFromList(Sounds.Hit, Flags.FxHitSoundIdx or 1, 0.9 + math.random() * 0.2)
    end

     -- Visual Effects (all simultaneously)
    doScreenFlash(isHeadshot and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255), 0.3, 0.25)
    doWhiteFlash(0.2)
    doRedFlash(0.3)
    doBlurFlash(isHeadshot and 25 or 15, 0.3)
    doColorFlash(isHeadshot and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(255, 255, 255), 0.4, 0.35)
    doBloomFlash(isHeadshot and 3 or 1.5, 0.4)
    doSunRaysFlash(0.3)
    doScreenShake(isHeadshot and 0.8 or 0.4, isHeadshot and 0.25 or 0.12)
    doChromaticAberration(isHeadshot and 6 or 3, 0.15)
    doSlowMotion(isHeadshot and 0.6 or 0.8, 0.2)
    doVignette(isHeadshot and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 100, 0), 0.4)
    doBloodEffect(isHeadshot and 20 or 10)
    doKillRing(isHeadshot and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255))
    doDesaturation(isHeadshot and 0.6 or 0.3, 0.4)
    doFOVPunch(isHeadshot and 15 or 8, 0.12)
    doGlitchLines(isHeadshot and 8 or 3, 0.1)

     -- Kill Feed
    addKillFeedEntry(lplr.DisplayName, victim, weaponName, isHeadshot)

     -- Streak
    if recentKills >= 2 then
        local name = streakNames[recentKills]
        if name then
            local streakSoundKey = ({[2]="DoubleKill",[3]="TripleKill",[4]="QuadKill",[5]="PentaKill",[7]="Unstoppable",[10]="Rampage",[15]="Godlike"})[recentKills]
            local soundData = streakSoundKey and Sounds[streakSoundKey]
            playSound(soundData or Sounds.DoubleKill, 0.7 + recentKills * 0.05)
            showStreakText(name, streakColors[recentKills] or Color3.fromRGB(255, 255, 0), recentKills)
        end
    end
end

local function onDeath()
    playSound(Sounds.Death, 0.8 + math.random() * 0.4)
    killStreak = 0
    doScreenFlash(Color3.fromRGB(255, 0, 0), 0.2, 0.5)
    doBlurFlash(30, 0.5)
    doScreenShake(1.2, 0.4)
    doVignette(Color3.fromRGB(200, 0, 0), 0.8)
    doDesaturation(0.9, 0.8)
end

 -- Main Kill Detection Loop
task.spawn(function()
    while true do
        task.wait(0.15)
        pcall(function()
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= lplr and player.Character then
                    local hum = player and player.Character:FindFirstChildOfClass("Humanoid")
                    if hum then
                        local prevHP = prevHealth[player.UserId] or hum.Health
                        if prevHP > 0 and hum.Health <= 0 then
                            local isEnemy = not (lplr.Team and player.Team == lplr.Team)
                            if isEnemy then
                                local weaponName = "Unknown"
                                pcall(function()
                                    local tool = lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
                                    if tool then weaponName = tool.Name end
                                end)

                                -- Headshot detection
                                local isHeadshot = false
                                pcall(function()
                                    local head = player and player.Character:FindFirstChild("Head")
                                    if head and head:GetAttribute("LastDamage") then isHeadshot = true end
                                end)

                                onKill(player.DisplayName, isHeadshot, weaponName)
                            end
                        end
                        prevHealth[player.UserId] = hum.Health
                    end
                end
            end
            if killStreak > 0 and tick() - lastKillTime > 8 then killStreak = 0 end
        end)
    end
end)

 -- Death Detection
task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            local char = lplr.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and not hum:GetAttribute("BS_KillSndConn") then
                    -- hum:SetAttribute("BS_KillSndConn", true)
                    hum.Died:Connect(onDeath)
                end
            end
        end)
    end
end)

 -- Cleanup
lplr.CharacterRemoving:Connect(function()
    if killEffectGui then killEffectGui:ClearAllChildren() end
    if vignetteGui then vignetteGui:ClearAllChildren() end
    pcall(function()
        blurEffect.Enabled = false
        colorCorrection.Enabled = false
        bloomEffect.Enabled = false
        sunRays.Enabled = false
    end)
end)


-- HITMARKER Implementation
local HitObjs = {}
local function drawHitmarker(pos, isHeadshot)
    if not Flags.Hitmarker then return end
    pcall(function()
        local cam = workspace.CurrentCamera
        local sp, vis = cam:WorldToViewportPoint(pos)
        if not vis then return end
        local sx, sy = sp.X, sp.Y
        local size = (Flags.HMSize or 12)
        local color = isHeadshot and Color3.new(1,0,0) or Color3.new(1,1,1)
        -- Create 4 lines for X shape
        for i = 1, 4 do
            if not HitObjs[i] then
                HitObjs[i] = Drawing.new("Line")
                HitObjs[i].Thickness = 2
                HitObjs[i].Color = color
                HitObjs[i].Visible = true
            end
            HitObjs[i].Color = color
        end
        -- Top-left to center
        HitObjs[1].From = Vector2.new(sx - size, sy - size)
        HitObjs[1].To = Vector2.new(sx - 2, sy - 2)
        -- Top-right to center
        HitObjs[2].From = Vector2.new(sx + size, sy - size)
        HitObjs[2].To = Vector2.new(sx + 2, sy - 2)
        -- Bottom-left to center
        HitObjs[3].From = Vector2.new(sx - size, sy + size)
        HitObjs[3].To = Vector2.new(sx - 2, sy + 2)
        -- Bottom-right to center
        HitObjs[4].From = Vector2.new(sx + size, sy + size)
        HitObjs[4].To = Vector2.new(sx + 2, sy + 2)
        -- Fade out after duration
        task.delay((Flags.HMDuration or 3) * 0.1, function()
            for _, obj in pairs(HitObjs) do pcall(function() obj.Visible = false end) end
        end)
    end)
end

-- Hit Sound Implementation
local function playHitSound()
    if not Flags.HitSound then return end
    pcall(function()
        local sound = Instance.new("Sound")
        local soundId = "rbxassetid://9125402735" -- CS2 Dink default
        local hmSound = Flags.HMSound or "CS2 Dink"
        if hmSound == "Quake Hit" then soundId = "rbxassetid://138087576"
        elseif hmSound == "Metal Pipe" then soundId = "rbxassetid://9125999404"
        elseif hmSound == "Minecraft XP" then soundId = "rbxassetid://142376098"
        elseif hmSound == "Vine Boom" then soundId = "rbxassetid://9126214519"
        end
        sound.SoundId = soundId
        sound.Volume = (Flags.HMSoundVol or 5) / 10
        sound.Parent = workspace.CurrentCamera
        sound:Play()
        game:GetService("Debris"):AddItem(sound, 2)
    end)
end

-- Kill Effect Implementation
local function playKillEffect()
    if not Flags.KillEffect then return end
    pcall(function()
        local style = Flags.KEStyle or "Flash"
        if style == "Flash" then
            local gui = Instance.new("ScreenGui")
            gui.IgnoreGuiInset = true
            local flash = Instance.new("Frame", gui)
            flash.Size = UDim2.new(1,0,1,0)
            flash.BackgroundColor3 = Color3.new(1,0.2,0.2)
            flash.BackgroundTransparency = 0.8
            gui.Parent = lplr.PlayerGui
            game:GetService("TweenService"):Create(flash, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            game:GetService("Debris"):AddItem(gui, 0.5)
        elseif style == "Shake" then
            local cam = workspace.CurrentCamera
            local orig = cam.CFrame
            cam.CFrame = orig * CFrame.new(math.random(-1,1)*0.3, math.random(-1,1)*0.3, 0)
            task.delay(0.1, function() cam.CFrame = orig end)
        end
    end)
end

-- Kill Sound Implementation
local function playKillSound()
    if not Flags.KillSound then return end
    pcall(function()
        local sound = Instance.new("Sound")
        local soundId = "rbxassetid://3124961779" -- Frag default
        local keSound = Flags.KESound or "Frag"
        if keSound == "Explosion" then soundId = "rbxassetid://13134985300"
        elseif keSound == "Metal Pipe" then soundId = "rbxassetid://9125999404"
        elseif keSound == "Mario Coin" then soundId = "rbxassetid://138087606"
        end
        sound.SoundId = soundId
        sound.Volume = (Flags.KESoundVol or 7) / 10
        sound.Parent = workspace.CurrentCamera
        sound:Play()
        game:GetService("Debris"):AddItem(sound, 2)
    end)
end

-- Damage Numbers Implementation
local function showDamageNumbers(pos, damage)
    if not Flags.DmgNumbers then return end
    pcall(function()
        local cam = workspace.CurrentCamera
        local sp, vis = cam:WorldToViewportPoint(pos + Vector3.new(0, 2, 0))
        if not vis then return end
        local txt = Drawing.new("Text")
        txt.Text = tostring(math.floor(damage))
        txt.Position = Vector2.new(sp.X, sp.Y)
        txt.Color = damage >= 100 and Color3.new(1,0,0) or Color3.new(1,1,0)
        txt.Size = 16
        txt.Center = true
        txt.Outline = true
        txt.Visible = true
        task.spawn(function()
            for i = 1, 20 do
                txt.Position = txt.Position - Vector2.new(0, 2)
                txt.TextTransparency = i / 20
                task.wait(0.02)
            end
            txt:Remove()
        end)
    end)
end

-- Expose functions
KE.drawHitmarker = drawHitmarker
KE.playHitSound = playHitSound
KE.playKillEffect = playKillEffect
KE.playKillSound = playKillSound
KE.showDamageNumbers = showDamageNumbers


print("[KillEffects] BloxStrike Kill Effects v2.0 loaded  30+ sounds, 15+ visual effects")
