

-- BLOXSTRIKE UTILITY MODULE v2.0
-- (Misc) Tab: Bhop (Enhanced), Misc features
-- Utility Tab: Bomb Timer, Radar, Panic, Auto Defuse, etc.

local Players = nil

pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local UIS = nil
pcall(function() UIS = game:GetService("UserInputService") end)
local StarterGui = nil
pcall(function() StarterGui = game:GetService("StarterGui") end)
local lplr = Players.LocalPlayer

--  TAB (Misc)

if not BS.Win then warn("[Unknown] BS.Win not available - ui.lua may have failed") return end
local M = BS.Win:Tab("Misc")
if not M or not M.Toggle then warn("[Misc] Failed to create tab!") return end

-- 1. BHOP (Bunny Hop  Ultimate Enhanced)

M:Label("  Bunny Hop ")
M:Toggle("Bhop", false, function(v) Flags.Bhop = v end)
M:Dropdown({Name="Bhop Mode", Flag="BhopMode", Options={"Auto","Legit","HvH","Long Jump","B-Hop Plus","Edge Bug","Strafe Hack","Stamina Jump"}, Default="Auto"})
M:Slider("Bhop Delay", 0, 100, 0, function(v) Flags.BhopDelay = v end)
M:Slider("Bhop Speed", 16, 50, 24, function(v) Flags.BhopSpeed = v end)
M:Toggle("Bhop Keybind Only", false, function(v) Flags.BhopKeybind = v end)
M:Toggle("Bhop Auto Run", false, function(v) Flags.BhopAutoRun = v end)
M:Toggle("Bhop Crouch", false, function(v) Flags.BhopCrouch = v end)
M:Toggle("Bhop Jump Bug", false, function(v) Flags.BhopJB = v end)
M:Toggle("Bhop Edge Bug", false, function(v) Flags.BhopEB = v end)
M:Separator()

 -- Air Strafe
M:Label(" Air Strafe ")
M:Toggle("Auto Strafe", true, function(v) Flags.BhopStrafe = v end)
M:Dropdown({Name="Strafe Pattern", Flag="BhopStrafePattern", Options={"Linear","Sinusoidal","Random","Aggressive","Smooth","Circular"}, Default="Linear"})
M:Slider("Strafe Speed", 1, 30, 10, function(v) Flags.BhopStrafeSpd = v end)
M:Slider("Strafe Angle Limit", 10, 90, 45, function(v) Flags.BhopStrafeAngle = v end)
M:Slider("Strafe Sensitivity", 1, 20, 8, function(v) Flags.BhopStrafeSens = v end)
M:Toggle("W-Strafe (Forward)", false, function(v) Flags.BhopWStrafe = v end)
M:Toggle("Air Accelerate", false, function(v) Flags.BhopAirAccel = v end)
M:Slider("Air Accel Value", 1, 20, 10, function(v) Flags.BhopAirAccelVal = v end)
M:Separator()

 -- Ground Strafe
-- M:Label(" Ground Strafe ")
-- M:Toggle("Ground Strafe", false, function(v) Flags.BhopGround = v end)
-- M:Slider("Ground Strafe Speed", 1, 20, 10, function(v) Flags.BhopGroundSpd = v end)
-- M:Dropdown({Name="Ground Pattern", Flag="BhopGroundPattern", Options={"Left","Right","Zigzag","Wiggle"}, Default="Left"})
-- M:Toggle("Pre-Strafe", false, function(v) Flags.BhopPreStr = v end)
-- M:Slider("Pre-Strafe Angle", 5, 60, 25, function(v) Flags.BhopPreAngle = v end)
M:Slider("Pre-Strafe Speed", 1, 20, 12, function(v) Flags.BhopPreSpeed = v end)
M:Separator()

 -- Advanced
M:Label(" Advanced ")
M:Toggle("Multi-Jump", false, function(v) Flags.BhopMultiJump = v end)
M:Slider("Multi-Jump Count", 2, 5, 2, function(v) Flags.BhopMultiCount = v end)
-- M:Toggle("Stamina System", false, function(v) Flags.BhopStamina = v end)
-- M:Slider("Max Stamina", 10, 100, 50, function(v) Flags.BhopMaxStamina = v end)
-- M:Slider("Stamina Drain", 1, 20, 5, function(v) Flags.BhopStamDrain = v end)
-- M:Slider("Stamina Regen", 1, 20, 3, function(v) Flags.BhopStamRegen = v end)
-- M:Toggle("Bunny Hop Sound", false, function(v) Flags.BhopSound = v end)
-- M:Toggle("Speed Indicator", false, function(v) Flags.BhopSpeedInd = v end)
M:Toggle("Bhop Bind (Space)", false, function(v) Flags.BhopBindSpace = v end)
M:Toggle("Bhop Auto Strafe Keys", false, function(v) Flags.BhopAutoKeys = v end)
-- M:Label("Hold Space | A/D air strafe | Scrolling wheel")

 -- Bhop State
local bhopStrafeAngle = 0
local bhopGroundAngle = 0
local bhopJumpCount = 0
local bhopLastGround = 0
local bhopStamina = 50
local bhopMultiJumpUsed = 0
local bhopLastJump = 0
local bhopStrafeTime = 0
local bhopAvgSpeed = 0
local bhopMaxSpeed = 0

 -- Bhop Engine
task.spawn(function()
    while true do
        task.wait()
        if not (Flags.Bhop and BS.alive()) then continue end
        pcall(function()
            local h = BS.hum()
            local hrp = BS.hrp()
            if not h or not hrp then return end

            local mode = Flags.BhopMode or "Auto"
            local onGround = h.FloorMaterial ~= Enum.Material.Air
            local vel = hrp.AssemblyLinearVelocity
            local speed = vel.Magnitude
            local isMoving = speed > 2
            local now = tick()

            -- Track speed
            bhopAvgSpeed = bhopAvgSpeed * 0.9 + speed * 0.1
            if speed > bhopMaxSpeed then bhopMaxSpeed = speed end
            bhopStrafeTime = bhopStrafeTime + 1

             -- Keybind Check
            if Flags.BhopKeybind then
                if not UIS:IsKeyDown(Enum.KeyCode.Space) and not UIS:IsKeyDown(Enum.KeyCode.ThumbstickButton1) then return end
            end

             -- Stamina System
            if Flags.BhopStamina then
                if not onGround then
                    bhopStamina = bhopStamina - (Flags.BhopStamDrain or 5) * 0.016
                    if bhopStamina <= 0 then
                        bhopStamina = 0
                        return -- No stamina, can't jump
                    end
                else
                    bhopStamina = math.min(bhopStamina + (Flags.BhopStamRegen or 3) * 0.016, Flags.BhopMaxStamina or 50)
                end
            end

             -- Auto Run
            if Flags.BhopAutoRun then
                h.WalkSpeed = Flags.BhopSpeed or 24
            end

             -- Jump Logic
            local function doJump()
                if now - bhopLastJump < 0.05 then return end -- Anti double-jump spam
                -- h:ChangeState(Enum.HumanoidStateType.Jumping)
                bhopLastJump = now
                bhopJumpCount = bhopJumpCount + 1

                -- Jump sound
                if Flags.BhopSound then
                    pcall(function()
                        local s = Instance.new("Sound")
                        s.SoundId = "rbxassetid://138087576"
                        s.Volume = 0.3
                        s.PlaybackSpeed = 1.2 + math.random() * 0.3
                        s.Parent = hrp
                        s:Play()
                        game:GetService("Debris"):AddItem(s, 0.5)
                    end)
                end
            end

             -- Mode: Auto
            if mode == "Auto" then
                if onGround then
                    bhopLastGround = now
                    local bhopDelay = (Flags.BhopDelay or 0) / 1000
                    -- Ping Adapt: increase bhop delay on high ping
                    if Flags.PingAdapt and BS.PA then
                        bhopDelay = BS.PA.getAdaptBhopInterval(bhopDelay)
                    end
                    task.wait(bhopDelay)
                    doJump()
                end

             -- Mode: Legit
            elseif mode == "Legit" then
                if onGround and isMoving then
                    local delay = (Flags.BhopDelay or 0) / 1000 + math.random() * 0.015
                    task.wait(delay)
                    doJump()
                end

             -- Mode: HvH
            elseif mode == "HvH" then
                if onGround then
                    doJump()
                end
                -- Speed boost
                if not onGround then
                    local lookDir = hrp.CFrame.LookVector
                    hrp.Velocity = lookDir * math.max(speed, Flags.BhopSpeed or 24)
                end

             -- Mode: Long Jump
            elseif mode == "Long Jump" then
                if onGround then
                    -- Pre-strafe sprint
                    if Flags.BhopPreStr then
                        local preAngle = math.rad(Flags.BhopPreAngle or 25)
                        local preSpd = (Flags.BhopPreSpeed or 12) / 500
                        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, preAngle, 0)
                        h.WalkSpeed = 35
                    end
                    task.wait(0.02)
                    doJump()
                    task.delay(0.05, function() h.WalkSpeed = Flags.BhopSpeed or 24 end)
                end
                -- Max air strafe
                if not onGround and Flags.BhopStrafe then
                    local ljs = (Flags.BhopStrafeSpd or 10) / 300
                    if UIS:IsKeyDown(Enum.KeyCode.D) then
                        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, -ljs, 0)
                    elseif UIS:IsKeyDown(Enum.KeyCode.A) then
                        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, ljs, 0)
                    end
                end

             -- Mode: B-Hop Plus
            elseif mode == "B-Hop Plus" then
                if onGround then
                    task.wait((Flags.BhopDelay or 0) / 1000)
                    doJump()
                    -- Instant air velocity
                    local lookDir = hrp.CFrame.LookVector
                    hrp.Velocity = Vector3.new(lookDir.X * 30, vel.Y + 20, lookDir.Z * 30)
                end
                -- Aggressive strafe
                if not onGround and Flags.BhopStrafe then
                    local aggro = (Flags.BhopStrafeSpd or 10) / 200
                    if UIS:IsKeyDown(Enum.KeyCode.D) then
                        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, -aggro, 0)
                    elseif UIS:IsKeyDown(Enum.KeyCode.A) then
                        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, aggro, 0)
                    end
                end

             -- Mode: Edge Bug
            elseif mode == "Edge Bug" then
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = {lplr.Character}
                local lookVec = hrp.CFrame.LookVector
                -- Check for edge ahead
                local result = workspace:Raycast(hrp.Position, lookVec * 4 + Vector3.new(0, -6, 0), params)
                if result then
                    -- Near edge, boost off
                    if onGround then
                        -- h:ChangeState(Enum.HumanoidStateType.Jumping)
                        hrp.Velocity = Vector3.new(lookVec.X * 40, 25, lookVec.Z * 40)
                    end
                elseif onGround then
                    doJump()
                end
                -- Air strafe
                if not onGround and Flags.BhopStrafe then
                    local ebs = (Flags.BhopStrafeSpd or 10) / 400
                    if UIS:IsKeyDown(Enum.KeyCode.D) then
                        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, -ebs, 0)
                    elseif UIS:IsKeyDown(Enum.KeyCode.A) then
                        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, ebs, 0)
                    end
                end

             -- Mode: Strafe Hack
            elseif mode == "Strafe Hack" then
                if onGround then
                    task.wait((Flags.BhopDelay or 0) / 1000)
                    doJump()
                end
                -- Auto strafe with pattern
                if not onGround and Flags.BhopStrafe then
                    local pattern = Flags.BhopStrafePattern or "Sinusoidal"
                    local sspd = (Flags.BhopStrafeSpd or 10) / 500
                    local angle = 0
                    if pattern == "Sinusoidal" then
                        angle = math.sin(bhopStrafeTime * 0.05) * sspd * 3
                    elseif pattern == "Random" then
                        angle = (math.random() - 0.5) * sspd * 4
                    elseif pattern == "Aggressive" then
                        angle = sspd * 2 * (UIS:IsKeyDown(Enum.KeyCode.D) and 1 or -1)
                    elseif pattern == "Smooth" then
                        angle = math.atan2(math.sin(bhopStrafeTime * 0.03), 1) * sspd * 2
                    elseif pattern == "Circular" then
                        angle = sspd * 2
                    else -- Linear
                        if UIS:IsKeyDown(Enum.KeyCode.D) then angle = -sspd
                        elseif UIS:IsKeyDown(Enum.KeyCode.A) then angle = sspd end
                    end
                    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, angle, 0)
                    -- Velocity boost
                    if Flags.BhopAirAccel then
                        local accel = (Flags.BhopAirAccelVal or 10) / 10
                        hrp.Velocity = hrp.Velocity + hrp.CFrame.LookVector * accel
                    end
                end

             -- Mode: Stamina Jump
            elseif mode == "Stamina Jump" then
                -- Force stamina mode on
                if not Flags.BhopStamina then
                    Flags.BhopStamina = true
                    bhopStamina = Flags.BhopMaxStamina or 50
                end
                if onGround and bhopStamina > 5 then
                    task.wait((Flags.BhopDelay or 0) / 1000)
                    doJump()
                end
                -- Smooth strafe
                if not onGround and Flags.BhopStrafe and bhopStamina > 0 then
                    local sstr = (Flags.BhopStrafeSpd or 10) / 600
                    if UIS:IsKeyDown(Enum.KeyCode.D) then
                        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, -sstr, 0)
                    elseif UIS:IsKeyDown(Enum.KeyCode.A) then
                        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, sstr, 0)
                    end
                end
            end

             -- Air Strafe (shared for all modes)
            if Flags.BhopStrafe and not onGround and mode ~= "Strafe Hack" and mode ~= "Long Jump" then
                local strafeSpd = (Flags.BhopStrafeSpd or 10) / 1000
                local pattern = Flags.BhopStrafePattern or "Linear"
                local angleLimit = math.rad(Flags.BhopStrafeAngle or 45)

                if pattern == "Sinusoidal" then
                    local sineAngle = math.sin(bhopStrafeTime * 0.04) * angleLimit
                    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, sineAngle * 0.05, 0)
                elseif pattern == "Random" then
                    local rAngle = (math.random() - 0.5) * angleLimit * 0.1
                    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, rAngle, 0)
                elseif pattern == "Aggressive" then
                    local aggSpd = strafeSpd * 2
                    if UIS:IsKeyDown(Enum.KeyCode.D) then
                        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, -aggSpd, 0)
                    elseif UIS:IsKeyDown(Enum.KeyCode.A) then
                        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, aggSpd, 0)
                    end
                elseif pattern == "Smooth" then
                    local smoothAngle = math.atan2(math.sin(bhopStrafeTime * 0.02), 2) * strafeSpd
                    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, smoothAngle, 0)
                elseif pattern == "Circular" then
                    local circAngle = strafeSpd * 1.5
                    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, circAngle, 0)
                else -- Linear
                    if UIS:IsKeyDown(Enum.KeyCode.D) then
                        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, -strafeSpd, 0)
                    elseif UIS:IsKeyDown(Enum.KeyCode.A) then
                        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, strafeSpd, 0)
                    end
                end
                -- W-Strafe
                if Flags.BhopWStrafe and UIS:IsKeyDown(Enum.KeyCode.W) then
                    local wsAngle = strafeSpd * 0.5
                    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, wsAngle, 0)
                end
            end

             -- Ground Strafe
            if Flags.BhopGround and onGround then
                local gsSpd = (Flags.BhopGroundSpd or 10) / 1000
                local gPattern = Flags.BhopGroundPattern or "Left"
                if gPattern == "Zigzag" then
                    gsSpd = gsSpd * (math.sin(bhopStrafeTime * 0.08) > 0 and 1 or -1)
                elseif gPattern == "Wiggle" then
                    gsSpd = gsSpd * math.sin(bhopStrafeTime * 0.15)
                elseif gPattern == "Right" then
                    gsSpd = -gsSpd
                end
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0, -gsSpd, 0)
                h.WalkSpeed = Flags.BhopSpeed or 24
            end

             -- Crouch Bhop
            if Flags.BhopCrouch then
                if not onGround then
                    h.HipHeight = -0.5
                else
                    h.HipHeight = 0
                end
            end

             -- Jump Bug
            if Flags.BhopJB and onGround then
                h.HipHeight = -0.5
                -- h:ChangeState(Enum.HumanoidStateType.Jumping)
                task.delay(0.04, function()
                    if h then h.HipHeight = 0 end
                end)
            end

             -- Edge Bug
            if Flags.BhopEB and mode ~= "Edge Bug" then
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = {lplr.Character}
                local lookVec = hrp.CFrame.LookVector
                local result = workspace:Raycast(hrp.Position, lookVec * 3 + Vector3.new(0, -5, 0), params)
                if not result and not onGround then
                    h.WalkSpeed = math.min(h.WalkSpeed + 2, 30)
                end
            end

             -- Multi-Jump
            if Flags.BhopMultiJump and not onGround then
                if UIS:IsKeyDown(Enum.KeyCode.Space) then
                    local timeSinceLast = now - bhopLastJump
                    if timeSinceLast > 0.15 and bhopMultiJumpUsed < (Flags.BhopMultiCount or 2) then
                        doJump()
                        bhopMultiJumpUsed = bhopMultiJumpUsed + 1
                    end
                end
            end
            if onGround then
                bhopMultiJumpUsed = 0
                bhopLastGround = now
            end

             -- Speed Indicator
            if Flags.BhopSpeedInd then
                -- Store for display in HUD
                BS.BhopSpeed = math.floor(speed)
                BS.BhopAvgSpeed = math.floor(bhopAvgSpeed)
                BS.BhopMaxSpeed = math.floor(bhopMaxSpeed)
                BS.BhopStamina = math.floor(bhopStamina)
            end

        end)
        -- ::continue::
    end
end)

 -- Bhop HUD Overlay
local bhopHudGui = nil
task.spawn(function()
    while true do
        task.wait(0.15)
        pcall(function()
            if not (Flags.Bhop and Flags.BhopSpeedInd and BS.alive()) then
                if bhopHudGui then bhopHudGui.Enabled = false end
                -- return
            end
            if not bhopHudGui then
                bhopHudGui = Instance.new("ScreenGui")
                bhopHudGui.Name = "BS_BhopHUD"
                bhopHudGui.IgnoreGuiInset = true
                bhopHudGui.DisplayOrder = 9997
                bhopHudGui.Parent = lplr.PlayerGui
                local f = Instance.new("Frame", bhopHudGui)
                f.Size = UDim2.new(0, 180, 0, 55)
                f.Position = UDim2.new(0.5, -90, 1, -80)
                f.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                f.BackgroundTransparency = 0.3
                f.BorderSizePixel = 0
                Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
                for i = 1, 3 do
                    local lbl = Instance.new("TextLabel", f)
                    lbl.Name = "L" .. i
                    lbl.Size = UDim2.new(1, -10, 0, 16)
                    lbl.Position = UDim2.new(0, 5, 0, (i - 1) * 17 + 2)
                    lbl.BackgroundTransparency = 1
                    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
                    lbl.TextSize = 11
                    lbl.Font = Enum.Font.Code
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                end
            end
            bhopHudGui.Enabled = true
            local f = bhopHudGui:FindFirstChildOfClass("Frame")
            if f then
                local spd = BS.BhopSpeed or 0
                local avg = BS.BhopAvgSpeed or 0
                local mx = BS.BhopMaxSpeed or 0
                local stam = BS.BhopStamina or 0
                local mode = Flags.BhopMode or "Auto"
                f.L1.Text = string.format("Mode: %s | Speed: %d", mode, spd)
                f.L1.TextColor3 = spd > 40 and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(200, 200, 200)
                f.L2.Text = string.format("Avg: %d | Max: %d", avg, mx)
                f.L2.TextColor3 = Color3.fromRGB(180, 180, 180)
                if Flags.BhopStamina then
                    local stamPct = stam / (Flags.BhopMaxStamina or 50)
                    f.L3.Text = string.format("Stamina: %d/%d", stam, Flags.BhopMaxStamina or 50)
                    f.L3.TextColor3 = stamPct > 0.5 and Color3.fromRGB(0, 255, 0) or stamPct > 0.25 and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(255, 0, 0)
                else
                    f.L3.Text = string.format("Jumps: %d", bhopJumpCount)
                    f.L3.TextColor3 = Color3.fromRGB(150, 150, 150)
                end
            end
        end)
    end
end)

-- 2. MISC FEATURES (in  tab)

M:Separator()
-- M:Label("  Misc Features ")
-- M:Toggle("Hit Marker", false, function(v) Flags.HitMarker = v end)
-- M:Toggle("Auto Crosshair", false, function(v) Flags.AutoCrosshair = v end)
-- M:Toggle("Damage Numbers", false, function(v) Flags.DamageNumbers = v end)
M:Toggle("Player Count Display", false, function(v) Flags.PlayerCount = v end)
M:Button({Name="Record Clip", Color=Color3.fromRGB(140,60,60)}, function()
    pcall(function() StarterGui:SetCore("ToggleRecording", {}) end)
end)
M:Separator()

-- 3. KILL EFFECTS v2.0 (30+ sounds, 15+ effects)

-- M:Label("  Kill Sounds (20 styles) ")
-- M:Toggle("Kill Sound", false, function(v) Flags.FxKillSound = v end)
-- M:Dropdown({Name="Kill Sound Style", Flag="FxKillSoundIdx", Options={"1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20"}, Default="1"})
M:Toggle("Random Pitch", false, function(v) Flags.FxRandomPitch = v end)
M:Separator()

-- M:Label("  Hit & Death Sounds ")
-- M:Toggle("Hit Sound", false, function(v) Flags.FxHitSound = v end)
M:Dropdown({Name="Hit Sound Style", Flag="FxHitSoundIdx", Options={"1","2","3","4","5","6","7","8"}, Default="1"})
M:Separator()

-- M:Label("  Screen Effects ")
-- M:Toggle("Screen Flash", false, function(v) Flags.FXFlash = v end)
-- M:Toggle("White Flash", false, function(v) Flags.FxWhiteFlash = v end)
-- M:Toggle("Red Flash", false, function(v) Flags.FxRedFlash = v end)
-- M:Toggle("Blur Flash", false, function(v) Flags.FXBlur = v end)
-- M:Toggle("Color Correction", false, function(v) Flags.FXColorFlash = v end)
-- M:Toggle("Bloom Flash", false, function(v) Flags.FXBloom = v end)
-- M:Toggle("Sun Rays Flash", false, function(v) Flags.FXSunRays = v end)
M:Toggle("Screen Shake", false, function(v) Flags.FXShake = v end)
M:Separator()

-- M:Label("  Visual Effects ")
-- M:Toggle("Chromatic Aberration", false, function(v) Flags.FXChromatic = v end)
-- M:Toggle("Vignette (Red Edges)", false, function(v) Flags.FXVignette = v end)
-- M:Toggle("Blood Particles", false, function(v) Flags.FxBlood = v end)
-- M:Toggle("Kill Ring (Expanding)", false, function(v) Flags.FxKillRing = v end)
-- M:Toggle("Desaturation (CS2)", false, function(v) Flags.FxDesat = v end)
-- M:Toggle("FOV Punch", false, function(v) Flags.FxFovPunch = v end)
-- M:Toggle("Glitch Lines", false, function(v) Flags.FxGlitch = v end)
-- M:Toggle("Slow Motion FOV", false, function(v) Flags.FXSlowMo = v end)
M:Toggle("Damage Direction", false, function(v) Flags.FXDamageDir = v end)
M:Separator()

-- M:Label("  Kill Streak ")
-- M:Toggle("Kill Streak Sound", false, function(v) Flags.FxStreakSound = v end)
-- M:Toggle("Kill Streak Text", false, function(v) Flags.FxStreakText = v end)
-- M:Label("2x Double | 3x Triple | 4x Quad | 5x Penta")
M:Label("7x Unstoppable | 10x Rampage | 15x GODLIKE")
M:Separator()

-- M:Label("  Kill Feed ")
-- M:Toggle("Kill Feed Overlay", false, function(v) Flags.FxKillFeed = v end)
-- M:Label("CS2-Style kill feed (top right)")

 -- Player Count Display
local playerCountGui
task.spawn(function()
    while task.wait(2) do
        pcall(function()
            if Flags.PlayerCount then
                if not playerCountGui then
                    playerCountGui = Instance.new("ScreenGui")
                    playerCountGui.Name = "BS_PlayerCount"
                    playerCountGui.IgnoreGuiInset = true
                    playerCountGui.DisplayOrder = 9997
                    playerCountGui.Parent = lplr.PlayerGui
                    local lbl = Instance.new("TextLabel", playerCountGui)
                    lbl.Size = UDim2.new(0, 130, 0, 22)
                    lbl.Position = UDim2.new(1, -140, 0, 10)
                    lbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    lbl.BackgroundTransparency = 0.3
                    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                    lbl.TextSize = 11
                    lbl.Font = Enum.Font.Code
                    Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 4)
                end
                playerCountGui.Enabled = true
                local alive, total = 0, 0
                for _, p in ipairs(Players:GetPlayers()) do
                    total = total + 1
                    if p.Character then
                        local hum = p and p.Character:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then alive = alive + 1 end
                    end
                end
                local lbl = playerCountGui:FindFirstChildOfClass("TextLabel")
                if lbl then lbl.Text = string.format("Alive: %d/%d", alive, total) end
            else
                if playerCountGui then playerCountGui.Enabled = false end
            end
        end)
    end
end)

-- UTILITY TAB

local U = BS.Win:Tab("Utility")
if not U or not U.Toggle then warn("[Utility] Failed to create tab!") return end

 -- BOMB TIMER
-- U:Label("  Bomb Timer ")
-- U:Toggle("Bomb Timer", false, function(v) Flags.BombTimer = v end)
-- U:Slider("Bomb Duration", 30, 60, 40, function(v) Flags.BombDuration = v end)

local bombTimerGui
task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            if Flags.BombTimer then
                local bomb = BS.api and BS.api.getBomb and BS.api.getBomb()
                if bomb then
                    if not bombTimerGui then
                        bombTimerGui = Instance.new("ScreenGui")
                        bombTimerGui.Name = "BS_BombTimer"
                        bombTimerGui.IgnoreGuiInset = true
                        bombTimerGui.DisplayOrder = 9997
                        bombTimerGui.Parent = lplr.PlayerGui
                        local f = Instance.new("Frame", bombTimerGui)
                        f.Size = UDim2.new(0, 200, 0, 50)
                        f.Position = UDim2.new(0.5, -100, 0.1, 0)
                        f.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                        f.BackgroundTransparency = 0.3
                        f.BorderSizePixel = 0
                        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
                        local t = Instance.new("TextLabel", f)
                        t.Name = "TimerText"
                        t.Size = UDim2.new(1, 0, 1, 0)
                        t.BackgroundTransparency = 1
                        t.TextColor3 = Color3.fromRGB(255, 0, 0)
                        t.TextScaled = true
                        t.Font = Enum.Font.Code
                    end
                    bombTimerGui.Enabled = true
                    local duration = Flags.BombDuration or 40
                    local elapsed = bomb:GetAttribute("ElapsedTime") or 0
                    local remaining = math.max(0, duration - elapsed)
                    local textLabel = bombTimerGui.Frame:FindFirstChild("TimerText")
                    if textLabel then
                        textLabel.Text = string.format(" %.1fs", remaining)
                        textLabel.TextColor3 = remaining < 10 and Color3.fromRGB(255,0,0) or remaining < 20 and Color3.fromRGB(255,255,0) or Color3.fromRGB(255,255,255)
                    end
                else
                    if bombTimerGui then bombTimerGui.Enabled = false end
                end
            else
                if bombTimerGui then bombTimerGui.Enabled = false end
            end
        end)
    end
end)

 -- AUTO DEFUSE
-- U:Label("  Bomb ")
-- U:Toggle("Auto Defuse", false, function(v) Flags.AutoDefuse = v end)
-- U:Slider("Defuse Range", 3, 10, 5, function(v) Flags.DefuseRange = v end)
-- U:Toggle("Auto Plant", false, function(v) Flags.AutoPlant = v end)

task.spawn(function()
    while task.wait(0.5) do
        if Flags.AutoDefuse and BS.alive() then
            pcall(function()
                local bomb = BS.api and BS.api.getBomb and BS.api.getBomb()
                if not bomb then return end
                local myHrp = BS.hrp()
                if not myHrp then return end
                local dist = (myHrp.Position - bomb.Position).Magnitude
                if dist <= (Flags.DefuseRange or 5) then
                    if BS.api.hasDefuseKit and BS.api.hasDefuseKit() then
                        BS.equipTool("defuse") or BS.equipTool("kit")
                        task.wait(0.1)
                    end
                    local h = BS.hum()
                    if h then h:MoveTo(bomb.Position) end
                    if BS.api.defuseBomb then BS.api.defuseBomb() end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if Flags.AutoPlant and BS.alive() then
            pcall(function()
                if not BS.api.hasBomb or not BS.api.hasBomb() then return end
                local sites = workspace:FindFirstChild("BombSites") or workspace:FindFirstChild("Map")
                if not sites then return end
                local myHrp = BS.hrp()
                if not myHrp then return end
                local nearestSite, nearestDist = nil, math.huge
                for _, site in pairs(sites:GetChildren()) do
                    local sitePos = site:GetPrimaryPartCFrame and site:GetPrimaryPartCFrame().Position
                    if sitePos then
                        local dist = (myHrp.Position - sitePos).Magnitude
                        if dist < nearestDist then nearestSite = site; nearestDist = dist end
                    end
                end
                if nearestSite and nearestDist < 30 then
                    local h = BS.hum()
                    if h then h:MoveTo(nearestSite:GetPrimaryPartCFrame().Position) end
                    task.wait(1)
                    if BS.api.plantBomb then BS.api.plantBomb(nearestSite.Name) end
                end
            end)
        end
    end
end)

 -- PANIC
-- U:Label("  Safety ")
-- U:Toggle("Panic Key (INSERT)", false, function(v) Flags.PanicEnabled = v end)

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if Flags.PanicEnabled and input.KeyCode == Enum.KeyCode.Insert then
        for key, _ in pairs(Flags) do
            if key ~= "PanicEnabled" and key ~= "TeamCheck" and key ~= "FriendCheck" and key ~= "ESP_TeamCheck" then
                Flags[key] = false
            end
        end
        print("[Panic] All features disabled!")
    end
end)

 -- SERVER
-- U:Label("  Server ")
-- U:Toggle("Auto Reconnect", false, function(v) Flags.AutoReconnect = v end)
U:Button({Name="Server Hop", Color=Color3.fromRGB(60,100,140)}, function()
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

task.spawn(function()
    while task.wait(5) do
        if Flags.AutoReconnect then
            pcall(function()
                if not lplr.Character then
                    task.wait(10)
                    if not lplr.Character then
                        game:GetService("TeleportService"):Teleport(game.PlaceId, lplr)
                    end
                end
            end)
        end
    end
end)

-- NOTE: Settings/Presets are in the Settings tab -- avoid duplication

 -- Cleanup
lplr.CharacterRemoving:Connect(function()
    if bombTimerGui then bombTimerGui.Enabled = false end
    if bhopHudGui then bhopHudGui.Enabled = false end
    if playerCountGui then playerCountGui.Enabled = false end
end)


-- ═══════════════════════════════════════════════════════════════
-- GRENADE PREVIEW (Trajectory Prediction)
-- ═══════════════════════════════════════════════════════════════
local GrenadePreview = {}
BS.GrenadePreview = GrenadePreview

function GrenadePreview:DrawTrajectory()
    if not Flags.GrenadePreview then return end
    pcall(function()
        local hrp = BS.hrp()
        if not hrp then return end
        local cam = workspace.CurrentCamera
        if not cam then return end
        local origin = cam.CFrame.Position
        local direction = cam.CFrame.LookVector * (Flags.GrenadeForce or 50)
        -- Simulate trajectory (simple parabola)
        local gravity = Vector3.new(0, -196.2, 0)
        local dt = 0.05
        local pos = origin
        local vel = direction
        local lastPos = pos
        for i = 1, 60 do
            vel = vel + gravity * dt
            pos = pos + vel * dt
            local sp, vis = cam:WorldToViewportPoint(pos)
            if vis then
                local line = poolLine()
                line.From = v2(cam:WorldToViewportPoint(lastPos).X, cam:WorldToViewportPoint(lastPos).Y)
                line.To = v2(sp.X, sp.Y)
                line.Color = Color3.fromRGB(255, 255, 0)
                line.Thickness = 1
                line.Visible = true
            end
            -- Stop if hit something
            local ray = Workspace:Raycast(lastPos, pos - lastPos)
            if ray then break end
            lastPos = pos
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- JUMP THROW (Jump + Throw at same time)
-- ═══════════════════════════════════════════════════════════════
BS.JumpThrow = function()
    pcall(function()
        local hrp = BS.hrp()
        local hum = BS.hum()
        if hrp and hum then
            -- Jump
            hum.Jump = true
            -- Small delay then throw
            task.delay(0.05, function()
                -- Simulate mouse click (throw)
                pcall(function()
                    local vim = nil
                    pcall(function() vim = game:GetService("VirtualInputManager") end)
                    vim:SendMouseButtonEvent(0, 0, 0, true)
                    task.delay(0.05, function()
                        vim:SendMouseButtonEvent(0, 0, 0, false)
                    end)
                end)
            end)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- QUICK NADE (Fast grenade switch + throw)
-- ═══════════════════════════════════════════════════════════════
BS.QuickNade = function()
    pcall(function()
        local backpack = lplr and lplr.Backpack
        if not backpack then return end
        -- Find grenade
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:lower():find("grenade") or tool.Name:lower():find("flash") or tool.Name:lower():find("smoke") or tool.Name:lower():find("molotov")) then
                -- Equip
                tool.Parent = lplr.Character or lplr
                -- Throw after short delay
                task.delay(0.1, function()
                    pcall(function()
                        tool:Activate()
                    end)
                end)
                break
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- BOMB TIMER
-- ═══════════════════════════════════════════════════════════════
BS.BombTimer = {Active = false, TimeLeft = 0, Site = "?"}
local bombTimerGui = nil

function BS.BombTimer:Start(site, duration)
    self.Active = true
    self.TimeLeft = duration or 40
    self.Site = site or "?"
    
    if not bombTimerGui then
        bombTimerGui = Instance.new("ScreenGui")
        bombTimerGui.Name = "BS_BombTimer"
        bombTimerGui.Parent = game:GetService("CoreGui")
    end
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 60)
    frame.Position = UDim2.new(0.5, -100, 0, 20)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = bombTimerGui
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0.5, 0)
    label.BackgroundTransparency = 1
    label.Text = "BOMB SITE: " .. self.Site
    label.TextColor3 = Color3.fromRGB(255, 200, 0)
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.Parent = frame
    
    local timer = Instance.new("TextLabel")
    timer.Name = "Timer"
    timer.Size = UDim2.new(1, 0, 0.5, 0)
    timer.Position = UDim2.new(0, 0, 0.5, 0)
    timer.BackgroundTransparency = 1
    timer.Text = tostring(self.TimeLeft) .. "s"
    timer.TextColor3 = Color3.fromRGB(255, 50, 50)
    timer.TextSize = 20
    timer.Font = Enum.Font.GothamBold
    timer.Parent = frame
    
    -- Countdown
    task.spawn(function()
        while self.Active and self.TimeLeft > 0 do
            task.wait(1)
            self.TimeLeft = self.TimeLeft - 1
            if timer then
                timer.Text = tostring(self.TimeLeft) .. "s"
                if self.TimeLeft <= 10 then
                    timer.TextColor3 = Color3.fromRGB(255, 0, 0)
                end
            end
        end
        self.Active = false
        if bombTimerGui then bombTimerGui:ClearAllChildren() end
    end)
end

function BS.BombTimer:Stop()
    self.Active = false
    if bombTimerGui then bombTimerGui:ClearAllChildren() end
end

-- GUI
page:Label(" Grenade ")
page:Toggle("Grenade Preview", false, function(v) Flags.GrenadePreview = v end)
page:Slider("Grenade Force", 20, 100, 50, function(v) Flags.GrenadeForce = v end)
page:Button({Name="Jump Throw"}, function() BS.JumpThrow() end)
page:Button({Name="Quick Nade"}, function() BS.QuickNade() end)
page:Separator()
page:Label(" Bomb ")
page:Button({Name="Start Timer (40s)"}, function() BS.BombTimer:Start("A", 40) end)
page:Button({Name="Stop Timer"}, function() BS.BombTimer:Stop() end)

print("[Utility] BloxStrike Utility module v2.0 loaded (Misc + Utility + Settings)")

)