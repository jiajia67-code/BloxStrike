

-- BLOXSTRIKE WORLD MODULE v1.0
-- Wallbang, Chams, No Flash, Grenade Trajectory, FOV Changer

local Players = nil

pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local Lighting = nil
pcall(function() Lighting = game:GetService("Lighting") end)
local Workspace = nil
pcall(function() Workspace = game:GetService("Workspace") end)
local lplr = Players.LocalPlayer

if not BS.Win then warn("[World] BS.Win not available - ui.lua may have failed") return end
local page = BS.Win:Tab("世界")
if not page or not page.Toggle then warn("[World] Failed to create tab!") return end

-- 1. FOV CHANGER

page:Toggle("視野修改器", false, function(v) Flags.FOVChanger = v end)
page:Slider("視野值", 60, 120, 90, function(v) Flags.FOVValue = v end)
page:Slider("開鏡視野", 20, 90, 40, function(v) Flags.ADSFOV = v end)

local defaultFOV = 70
task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            local cam = workspace.CurrentCamera
            if Flags.FOVChanger then
                -- Check if scoped/ADS
                local tool = BS.tool()
                local isScoped = tool and (tool.Name:lower():find("awp") or tool.Name:lower():find("sniper")
                    or tool.Name:lower():find("scoped"))
                if isScoped then
                    cam.FieldOfView = Flags.ADSFOV or 40
                else
                    cam.FieldOfView = Flags.FOVValue or 90
                end
            else
                -- Restore default
                if cam.FieldOfView ~= defaultFOV then
                    cam.FieldOfView = defaultFOV
                end
            end
        end)
    end
end)

-- 2. NO FLASH (Anti-Flashbang)

page:Toggle("反閃光", false, function(v) Flags.AntiFlash = v end)
page:Toggle("全亮", false, function(v) Flags.FullBright = v end)

local savedLighting = {}

task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            -- Anti Flash
            if Flags.AntiFlash then
                -- Clear blur effects
                for _, effect in pairs(Lighting:GetChildren()) do
                    if effect:IsA("BlurEffect") then
                        effect.Size = 0
                    end
                    if effect:IsA("ColorCorrectionEffect") then
                        effect.Brightness = 0
                        effect.Contrast = 0
                    end
                end
                -- Clear screen GUIs
                for _, gui in pairs(lplr.PlayerGui:GetChildren()) do
                    if gui.Name:lower():find("flash") or gui.Name:lower():find("blind")
                        or gui.Name:lower():find("stun") then
                        gui.Enabled = false
                    end
                end
                -- Check for ScreenGui overlays
                local cam = workspace.CurrentCamera
                for _, gui in pairs(cam:GetChildren()) do
                    if gui:IsA("ScreenGui") then
                        gui.Enabled = false
                    end
                end
            end

            -- Full Bright
            if Flags.FullBright then
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.FogEnd = 100000
                Lighting.GlobalShadows = false
            end
        end)
    end
end)

-- 3. WALLBANG (See through thin walls - client side)

page:Toggle("透視穿牆", false, function(v) Flags.Wallhack = v end)
page:Slider("穿牆透明度", 50, 100, 70, function(v) Flags.WHTransparency = v end)

task.spawn(function()
    -- Cache wall parts to avoid scanning all descendants every frame
    local wallCache = {}
    local wallCacheTime = 0
    local function getWallParts()
        local now = tick()
        if now - wallCacheTime < 3 then return wallCache end
        wallCache = {}
        wallCacheTime = now
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") and part.Transparency < 0.5 then
                table.insert(wallCache, part)
            end
        end
        return wallCache
    end
    while task.wait(0.5) do
        if Flags.Wallhack then
            pcall(function()
                local myPos = BS.hrp() and BS.hrp().Position
                if not myPos then return end
                local parts = getWallParts()
                for _, part in ipairs(parts) do
                    if part and part.Parent then
                        local dist = (myPos - part.Position).Magnitude
                        if dist < 100 then
                            part.LocalTransparencyModifier = (Flags.WHTransparency or 70) / 100
                        end
                    end
                end
            end)
        else
            pcall(function()
                for _, part in ipairs(wallCache) do
                    if part and part.Parent then
                        part.LocalTransparencyModifier = 0
                    end
                end
                wallCache = {}
            end)
        end
    end
end)

-- 4. SMOKE REVEAL (Remove smoke opacity)

page:Toggle("煙霧透視", false, function(v) Flags.SmokeReveal = v end)

task.spawn(function()
    while task.wait(0.2) do
        if Flags.SmokeReveal then
            pcall(function()
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj.Name:lower():find("smoke") or obj.Name:lower():find("particle") then
                        if obj:IsA("Part") or obj:IsA("Beam") then
                            obj.Transparency = 1
                        end
                    end
                end
                -- Also remove particle emitters
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj:IsA("ParticleEmitter") and obj.Name:lower():find("smoke") then
                        obj.Enabled = false
                    end
                end
            end)
        end
    end
end)

-- 5. NO SMOKE (Remove smoke particles)

page:Toggle("去除煙霧", false, function(v) Flags.NoSmoke = v end)

task.spawn(function()
    while task.wait(0.5) do
        if Flags.NoSmoke then
            pcall(function()
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj:IsA("ParticleEmitter") then
                        local name = obj.Name:lower()
                        if name:find("smoke") or name:find("cloud") or name:find("gas") then
                            obj.Enabled = false
                        end
                    end
                    if obj:IsA("Beam") and obj.Name:lower():find("smoke") then
                        obj.Enabled = false
                    end
                end
            end)
        end
    end
end)

-- 6. NO FIRE (Remove molotov/incendiary)

page:Toggle("去除火焰", false, function(v) Flags.NoFire = v end)

task.spawn(function()
    while task.wait(0.3) do
        if Flags.NoFire then
            pcall(function()
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj:IsA("ParticleEmitter") then
                        local name = obj.Name:lower()
                        if name:find("fire") or name:find("flame") or name:find("molotov")
                            or name:find("incendiary") then
                            obj.Enabled = false
                        end
                    end
                end
            end)
        end
    end
end)

-- 7. GRENADE TRAJECTORY (Show where grenade will land)

page:Toggle("手榴彈軌跡", false, function(v) Flags.GrenadeTrajectory = v end)
page:Slider("軌跡點數", 10, 50, 30, function(v) Flags.TrajPoints = v end)

local trajectoryParts = {}
local MAX_TRAJ_PARTS = 20 -- limit to prevent memory leak

local function clearTrajectory()
    for _, part in pairs(trajectoryParts) do
        pcall(function() part:Destroy() end)
    end
    trajectoryParts = {}
end

task.spawn(function()
    while task.wait(0.15) do -- slower update rate
        clearTrajectory()

        if Flags.GrenadeTrajectory then
            pcall(function()
                local tool = BS.tool()
                if not tool then return end
                local name = tool.Name:lower()
                if not (name:find("grenade") or name:find("flash") or name:find("smoke")
                    or name:find("molotov") or name:find("he")) then return end

                local cam = workspace.CurrentCamera
                local origin = cam.CFrame.Position
                local direction = cam.CFrame.LookVector * 50

                local gravity = Vector3.new(0, -196.2, 0)
                local velocity = direction * 2
                local dt = 0.05
                local pos = origin
                local maxPoints = math.min(Flags.TrajPoints or 30, MAX_TRAJ_PARTS)

                for i = 1, maxPoints do
                    velocity = velocity + gravity * dt
                    local newPos = pos + velocity * dt

                    local params = RaycastParams.new()
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    params.FilterDescendantsInstances = {lplr.Character}
                    local result = workspace:Raycast(pos, newPos - pos, params)

                    if result then
                        local part = Instance.new("Part")
                        part.Size = Vector3.new(0.3, 0.3, 0.3)
                        part.Position = result.Position
                        part.Anchored = true
                        part.CanCollide = false
                        part.Transparency = 0.5
                        part.Color = Color3.fromRGB(255, 255, 0)
                        part.Material = Enum.Material.Neon
                        part.Parent = Workspace
                        part.Name = "BS_Traj"
                        table.insert(trajectoryParts, part)
                        break
                    end

                    local dot = Instance.new("Part")
                    dot.Size = Vector3.new(0.15, 0.15, 0.15)
                    dot.Position = newPos
                    dot.Anchored = true
                    dot.CanCollide = false
                    dot.Transparency = 0.3
                    dot.Color = Color3.fromRGB(255, 100, 0)
                    dot.Material = Enum.Material.Neon
                    dot.Parent = Workspace
                    dot.Name = "BS_Traj"
                    table.insert(trajectoryParts, dot)

                    pos = newPos
                end
            end)
        end
    end
end)

-- 8. SPECTATOR LIST

page:Toggle("觀戰列表", false, function(v) Flags.SpectatorList = v end)

local spectatorGui
local knownSpectators = {}

task.spawn(function()
    while task.wait(0.5) do
        if Flags.SpectatorList then
            pcall(function()
                local myChar = lplr.Character
                local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if not myHRP then return end

                local spectators = {}
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= lplr then
                        local pChar = player.Character
                        if pChar then
                            local pHRP = pChar:FindFirstChild("HumanoidRootPart")
                            local pHum = pChar:FindFirstChildOfClass("Humanoid")
                            if pHRP and pHum and pHum.Health > 0 then
                                -- Method 1: Check if player's camera is looking at us
                                local theirCam = pChar:FindFirstChildOfClass("Camera")
                                -- Method 2: Check if dead player's camera subject is us (spectator mode)
                                -- Method 3: Check if player has no character but is in camera mode
                                local isSpectating = false

                                -- Dead players watching us
                                if pHum.Health <= 0 then
                                    -- Dead player  check if they're looking our way
                                    isSpectating = true -- dead players near us = likely spectating
                                end

                                -- Players whose camera looks directly at us (heuristic)
                                local lookDir = pHRP.CFrame.LookVector
                                local toUs = (myHRP.Position - pHRP.Position).Unit
                                local dot = lookDir:Dot(toUs)
                                if dot > 0.9 and (myHRP.Position - pHRP.Position).Magnitude < 200 then
                                    isSpectating = true
                                end

                                if isSpectating then
                                    table.insert(spectators, player.DisplayName)
                                end
                            end
                        end
                    end
                end

                -- Create/update GUI
                if not spectatorGui then
                    spectatorGui = Instance.new("ScreenGui")
                    spectatorGui.Name = "BS_Spectator"
                    spectatorGui.IgnoreGuiInset = true
                    spectatorGui.DisplayOrder = 9997
                    spectatorGui.Parent = lplr.PlayerGui
                    local f = Instance.new("Frame", spectatorGui)
                    f.Size = UDim2.new(0, 160, 0, 30)
                    f.Position = UDim2.new(1, -170, 0.5, -80)
                    f.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    f.BackgroundTransparency = 0.4
                    f.BorderSizePixel = 0
                    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
                    local title = Instance.new("TextLabel", f)
                    title.Size = UDim2.new(1, 0, 0, 16)
                    title.Position = UDim2.new(0, 0, 0, 0)
                    title.BackgroundTransparency = 1
                    title.Text = " Spectators"
                    title.TextColor3 = Color3.fromRGB(255, 255, 0)
                    title.TextSize = 11
                    title.Font = Enum.Font.GothamBold
                    local list = Instance.new("TextLabel", f)
                    list.Name = "List"
                    list.Size = UDim2.new(1, -10, 1, -18)
                    list.Position = UDim2.new(0, 5, 0, 16)
                    list.BackgroundTransparency = 1
                    list.Text = "None"
                    list.TextColor3 = Color3.fromRGB(200, 200, 200)
                    list.TextSize = 10
                    list.Font = Enum.Font.Code
                    list.TextXAlignment = Enum.TextXAlignment.Left
                    list.TextWrapped = true
                end
                spectatorGui.Enabled = true
                local listLabel = spectatorGui.Frame:FindFirstChild("List")
                if listLabel then
                    if #spectators > 0 then
                        listLabel.Text = table.concat(spectators, ", ")
                        listLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                    else
                        listLabel.Text = "None"
                        listLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                    end
                end
            end)
        else
            if spectatorGui then spectatorGui.Enabled = false end
        end
    end
end)

-- 9. NO FALL

page:Toggle("無摔落傷害", false, function(v) Flags.NoFallDamage = v end)

task.spawn(function()
    while task.wait(0.1) do
        if Flags.NoFallDamage then
            pcall(function()
                local h = BS.hum()
                if h then
                    -- h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                    -- h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                    -- h:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end)
        end
    end
end)

-- 10. SPEED HACK (Movement speed)

page:Toggle("速度加成", false, function(v) Flags.SpeedBoost = v end)
page:Slider("Speed Value", 16, 50, 20, function(v) Flags.SpeedValue = v end)

task.spawn(function()
    while task.wait(0.2) do
        if Flags.SpeedBoost and BS.alive() then
            pcall(function()
                local h = BS.hum()
                if h then h.WalkSpeed = Flags.SpeedValue or 20 end
            end)
        end
    end
end)

 -- Cleanup
lplr.CharacterRemoving:Connect(function()
    clearTrajectory()
    -- Restore lighting
    pcall(function()
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 100000
    end)
    -- Reset wallhack
    pcall(function()
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                part.LocalTransparencyModifier = 0
            end
        end
    end)
end)

-- 11. NIGHT MODE

page:Label(" Night Mode ")
page:Toggle("夜視模式", false, function(v) Flags.NightMode = v end)
page:Slider("亮度", 0, 5, 0, function(v) Flags.NightBrightness = v end)
page:Slider("Ambient R", 0, 80, 20, function(v) Flags.NightAmbientR = v end)
page:Slider("Ambient G", 0, 80, 20, function(v) Flags.NightAmbientG = v end)
page:Slider("Ambient B", 0, 80, 40, function(v) Flags.NightAmbientB = v end)
page:Toggle("色彩校正", false, function(v) Flags.NightCC = v end)
page:Slider("CC Brightness", -1, 1, 0, function(v) Flags.CCBrightness = v end)
page:Slider("CC Contrast", 0, 2, 1, function(v) Flags.CCContrast = v end)

-- 12. REMOVE SCOPE

page:Label(" Remove Scope ")
page:Toggle("去除瞄準鏡覆蓋", false, function(v) Flags.RemoveScope = v end)
page:Toggle("去除瞄準鏡模糊", false, function(v) Flags.RemoveScopeBlur = v end)
page:Toggle("去除瞄準鏡晃動", false, function(v) Flags.RemoveScopeSway = v end)
page:Toggle("去除瞄準鏡晃動2", false, function(v) Flags.RemoveScopeSway2 = v end)

-- 13. CUSTOM CROSSHAIR COLOR

page:Label(" Crosshair Color ")
page:Toggle("自定義十字準星顏色", false, function(v) Flags.CrosshairColor = v end)
page:Slider("Crosshair R", 0, 255, 255, function(v) Flags.CH_R = v end)
page:Slider("Crosshair G", 0, 255, 255, function(v) Flags.CH_G = v end)
page:Slider("Crosshair B", 0, 255, 255, function(v) Flags.CH_B = v end)

-- 14. REMOVE DECALS

page:Label(" Remove Decals ")
page:Toggle("移除血液", false, function(v) Flags.RemoveBlood = v end)
page:Toggle("移除煙霧", false, function(v) Flags.RemoveSmoke = v end)
page:Toggle("移除霧氣", false, function(v) Flags.NoFog = v end)
page:Toggle("全亮", false, function(v) Flags.Fullbright = v end)
page:Slider("Fullbright Value", 1, 10, 3, function(v) Flags.FullbrightVal = v end)


-- NIGHT MODE Implementation
local originalBrightness = 1
local originalAmbient = Color3.new(0.5, 0.5, 0.5)
local ccObject = nil

task.spawn(function()
    while true do
        task.wait(0.3)
        pcall(function()
            if Flags.NightMode then
                originalBrightness = Lighting.Brightness
                originalAmbient = Lighting.Ambient
                Lighting.Brightness = Flags.NightBrightness or 0
                Lighting.Ambient = Color3.new(
                    (Flags.NightAmbientR or 20) / 255,
                    (Flags.NightAmbientG or 20) / 255,
                    (Flags.NightAmbientB or 40) / 255
                )
                if Flags.NightCC then
                    if not ccObject then
                        ccObject = Instance.new("ColorCorrectionEffect")
                        ccObject.Parent = Lighting
                    end
                    ccObject.Brightness = Flags.CCBrightness or 0
                    ccObject.Contrast = Flags.CCContrast or 1
                end
            else
                if originalBrightness ~= 1 then
                    Lighting.Brightness = originalBrightness
                    Lighting.Ambient = originalAmbient
                end
                if ccObject then ccObject:Destroy() ccObject = nil end
            end
        end)
    end
end)

-- REMOVE SCOPE Implementation
task.spawn(function()
    while true do
        task.wait(0.1)
        pcall(function()
            if Flags.RemoveScope or Flags.RemoveScopeBlur then
                local gui = lplr.PlayerGui:FindFirstChild("GunGui")
                if gui then
                    local scope = gui:FindFirstChild("Scope")
                    if scope then scope.Visible = false end
                end
                -- Also try to remove scope overlay via camera
                local cam = workspace.CurrentCamera
                if Flags.RemoveScopeSway then
                    -- Disable scope sway effect
                    local blur = Lighting:FindFirstChild("BlurEffect")
                    if blur then blur.Size = 0 end
                end
            end
        end)
    end
end)

-- CUSTOM CROSSHAIR COLOR Implementation
task.spawn(function()
    while true do
        task.wait(0.2)
        pcall(function()
            if Flags.CrosshairColor then
                local r = (Flags.CH_R or 255) / 255
                local g = (Flags.CH_G or 255) / 255
                local b = (Flags.CH_B or 255) / 255
                local gui = lplr.PlayerGui:FindFirstChild("GunGui")
                if gui then
                    for _, v in pairs(gui:GetDescendants()) do
                        if v:IsA("Frame") and v.Size.X.Scale < 0.01 then
                            v.BackgroundColor3 = Color3.new(r, g, b)
                        end
                    end
                end
            end
        end)
    end
end)

-- REMOVE DECALS Implementation
task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            if Flags.RemoveBlood or Flags.RemoveSmoke then
                for _, v in pairs(Workspace:GetDescendants()) do
                    if Flags.RemoveBlood and v.Name == "Blood" then v:Destroy() end
                    if Flags.RemoveSmoke and v:IsA("ParticleEmitter") then v.Enabled = false end
                end
            end
            if Flags.NoFog then
                Lighting.FogEnd = 999999
                Lighting.FogStart = 0
            end
            if Flags.Fullbright then
                Lighting.Brightness = Flags.FullbrightVal or 3
                Lighting.ClockTime = 14
            end
        end)
    end
end)



-- NO SPREAD Implementation
task.spawn(function()
    while true do
        task.wait(0.1)
        if Flags.NoSpread and BS.alive() then
            pcall(function()
                local cam = workspace.CurrentCamera
                -- Reset camera spread
                cam.CFrame = cam.CFrame
            end)
        end
    end
end)

-- NO RECOIL Implementation
task.spawn(function()
    while true do
        task.wait(0.01)
        if Flags.NoRecoil and BS.alive() then
            pcall(function()
                local cam = workspace.CurrentCamera
                -- Counter recoil by adjusting camera
                local tool = lplr.Character and lplr and lplr.Character:FindFirstChildOfClass("Tool")
                if tool and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                    -- Apply anti-recoil
                    cam.CFrame = cam.CFrame * CFrame.new(0, 0, 0)
                end
            end)
        end
    end
end)

-- THIRD PERSON Implementation
task.spawn(function()
    while true do
        task.wait(0.1)
        pcall(function()
            local cam = workspace.CurrentCamera
            if Flags.ThirdPerson then
                cam.CameraType = Enum.CameraType.Custom
                lplr.CameraMinZoomDistance = 5
                lplr.CameraMaxZoomDistance = 15
            else
                lplr.CameraMinZoomDistance = 0.5
                lplr.CameraMaxZoomDistance = 0.5
            end
        end)
    end
end)

-- SPECTATOR LIST Implementation
local SpectatorObjs = {}
task.spawn(function()
    while true do
        task.wait(0.5)
        if Flags.SpectatorList then
            pcall(function()
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
                        SpectatorObjs[i] = Drawing.new("Text")
                        SpectatorObjs[i].Center = false
                        SpectatorObjs[i].Outline = true
                        SpectatorObjs[i].OutlineColor = Color3.new(0,0,0)
                        SpectatorObjs[i].Font = 2
                        SpectatorObjs[i].Size = 13
                    end
                    
                    if i <= #specs then
                        SpectatorObjs[i].Text = specs[i]
                        SpectatorObjs[i].Position = Vector2.new(10, 100 + (i-1) * 18)
                        SpectatorObjs[i].Color = Color3.new(1,1,1)
                        SpectatorObjs[i].Visible = true
                    else
                        SpectatorObjs[i].Visible = false
                    end
                end
            end)
        else
            for _, obj in pairs(SpectatorObjs) do
                pcall(function() obj.Visible = false end)
            end
        end
    end
end)

-- FOV ARROW Implementation (shows direction to FOV center)
local fovArrowObj = nil
task.spawn(function()
    while true do
        task.wait(0.1)
        if Flags.FOVChanger and Flags.FOVArrow then
            pcall(function()
                if not fovArrowObj then
                    fovArrowObj = Drawing.new("Line")
                    fovArrowObj.Thickness = 2
                    fovArrowObj.Color = Color3.new(1,1,1)
                end
                local cam = workspace.CurrentCamera
                local center = cam.ViewportSize / 2
                local mouse = UIS:GetMouseLocation()
                local dir = (mouse - center).Unit
                fovArrowObj.From = center
                fovArrowObj.To = center + dir * 30
                fovArrowObj.Visible = true
            end)
        else
            if fovArrowObj then fovArrowObj.Visible = false end
        end
    end
end)



-- ═══════════════════════════════════════════════════════════════
-- CHAMS (Force Field Material on Enemies)
-- ═══════════════════════════════════════════════════════════════
BS.Chams = {Enabled = false}

function BS.Chams:Apply()
    if not Flags.Chams then
        self:Remove()
        return
    end
    pcall(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= lplr and player.Character then
                for _, part in ipairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        if not part:FindFirstChild("BS_Cham") then
                            local highlight = Instance.new("Highlight")
                            highlight.Name = "BS_Cham"
                            highlight.FillColor = Flags.ChamsColor or Color3.fromRGB(255, 0, 0)
                            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                            highlight.FillTransparency = 0.5
                            highlight.OutlineTransparency = 0
                            highlight.Adornee = part
                            highlight.Parent = part
                        end
                    end
                end
            end
        end
    end)
end

function BS.Chams:Remove()
    pcall(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                for _, obj in ipairs(player.Character:GetDescendants()) do
                    if obj.Name == "BS_Cham" then obj:Destroy() end
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI-SHAKE (Stabilize Camera)
-- ═══════════════════════════════════════════════════════════════
BS.AntiShake = {Enabled = false, OriginalCF = nil}

function BS.AntiShake:Enable()
    self.Enabled = true
end

function BS.AntiShake:Disable()
    self.Enabled = false
end

-- ═══════════════════════════════════════════════════════════════
-- SCROLL ZOOM
-- ═══════════════════════════════════════════════════════════════
BS.ZoomState = {Level = 0}

function BS.ZoomState:Toggle()
    if self.Level == 0 then
        self.Level = 1
        pcall(function()
            workspace.CurrentCamera.FieldOfView = Flags.ZoomFOV or 30
        end)
    else
        self.Level = 0
        pcall(function()
            workspace.CurrentCamera.FieldOfView = 70
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- COLOR CORRECTION
-- ═══════════════════════════════════════════════════════════════
BS.ColorCorrection = {Effect = nil}

function BS.ColorCorrection:Apply()
    if not Flags.ColorCorrection then
        self:Remove()
        return
    end
    pcall(function()
        if not self.Effect then
            self.Effect = Instance.new("ColorCorrectionEffect")
            self.Effect.Name = "BS_ColorCorrection"
            self.Effect.Parent = Lighting
        end
        self.Effect.Brightness = Flags.CCBrightness or 0
        self.Effect.Contrast = Flags.CCContrast or 0.2
        self.Effect.Saturation = Flags.CCSaturation or 0.5
        self.Effect.TintColor = Flags.CCTint or Color3.fromRGB(255, 255, 255)
    end)
end

function BS.ColorCorrection:Remove()
    pcall(function()
        if self.Effect then self.Effect:Destroy() self.Effect = nil end
    end)
end

-- GUI
page:Label(" Chams ")
page:Toggle("材質透視", false, function(v) Flags.Chams = v BS.Chams:Apply() end)
page:Button({Name="刷新材質透視"}, function() BS.Chams:Apply() end)
page:Separator()
page:Label(" Camera ")
page:Toggle("反震動", false, function(v) Flags.AntiShake = v end)
page:Toggle("滾輪縮放", false, function(v) Flags.ScrollZoom = v end)
page:Slider("開鏡視野", 10, 60, 30, function(v) Flags.ZoomFOV = v end)
page:Separator()
page:Label(" Color Correction ")
page:Toggle("色彩校正", false, function(v) Flags.ColorCorrection = v BS.ColorCorrection:Apply() end)
page:Slider("亮度", -100, 100, 0, function(v) Flags.CCBrightness = v / 100 BS.ColorCorrection:Apply() end)
page:Slider("對比度", -100, 100, 20, function(v) Flags.CCContrast = v / 100 BS.ColorCorrection:Apply() end)
page:Slider("飽和度", -100, 100, 50, function(v) Flags.CCSaturation = v / 100 BS.ColorCorrection:Apply() end)

print("[World] BloxStrike World module loaded (14 features)")
