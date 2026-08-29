

-- BLOXSTRIKE ESP MODULE v3.0  Ultimate Zero Delay ESP
-- 60+ Options, Object Pool, Cached Functions, Single Loop

if not BS.Win then warn("[ESP] BS.Win not available - ui.lua may have failed") return end
local UIS = nil pcall(function() UIS = game:GetService("UserInputService") end)
local RunService = nil pcall(function() RunService = game:GetService("RunService") end)
if not RunService then warn("[ESP] RunService not available") return end

-- Safe mouse position getter (prevents GetMouseLocation crash)
local mousePos = Vector2.new(0, 0)
local function getMousePos()
    local ok, pos = pcall(function() return UIS and UIS:GetMouseLocation() end)
    if ok and pos then mousePos = pos end
    return mousePos
end

local E = BS.Win:Tab("透視")
if not E or not E.Toggle then warn("[ESP] Failed to create tab!") return end

-- GUI SECTION  60+ Options

 -- Player ESP
E:Label(" Player ESP ")
E:Toggle("方框透視", false, function(v) Flags.ESP_Box = v end)
E:Toggle("名字透視", false, function(v) Flags.ESP_Name = v end)
E:Toggle("名字背景", false, function(v) Flags.ESP_NameBG = v end)
E:Slider("名字字體大小", 8, 20, 13, function(v) Flags.ESP_NameSize = v end)
E:Toggle("血量條", false, function(v) Flags.ESP_Health = v end)
E:Toggle("血量文字", false, function(v) Flags.ESP_HealthText = v end)
E:Dropdown({Name="血量位置", Flag="ESPHealthPos", Options={"左","右","上"}, Default="Left"})
E:Toggle("護甲條", false, function(v) Flags.ESP_Armor = v end)
E:Toggle("距離透視", false, function(v) Flags.ESP_Dist = v end)
E:Toggle("距離單位", false, function(v) Flags.ESP_DistUnit = v end)
E:Toggle("武器透視", false, function(v) Flags.ESP_Weapon = v end)
E:Toggle("武器彈藥", false, function(v) Flags.ESP_WeaponAmmo = v end)
E:Toggle("頭部圓點", false, function(v) Flags.ESP_HeadDot = v end)
E:Toggle("頭部命中框", false, function(v) Flags.ESP_HeadHit = v end)
E:Toggle("槍管透視", false, function(v) Flags.ESP_Barrel = v end)
E:Toggle("追蹤線", false, function(v) Flags.ESP_Tracer = v end)
E:Toggle("瞄準線", false, function(v) Flags.ESP_Snaplines = v end)
E:Toggle("骨骼透視", false, function(v) Flags.ESP_Skeleton = v end)
E:Toggle("受傷指示器", false, function(v) Flags.ESP_OOF = v end)
E:Toggle("離屏箭頭", false, function(v) Flags.ESP_Arrow = v end)
E:Slider("Arrow Size", 8, 30, 15, function(v) Flags.ESP_ArrowSize = v end)
E:Toggle("爆頭圖標", false, function(v) Flags.ESP_Headshot = v end)
E:Toggle("速度箭頭", false, function(v) Flags.ESP_Velocity = v end)
E:Toggle("目標透視", false, function(v) Flags.ESP_Target = v end)
E:Toggle("資訊卡片", false, function(v) Flags.ESP_InfoCard = v end)
E:Toggle("雷射線", false, function(v) Flags.ESP_LaserLine = v end)
E:Separator()

 -- World ESP
E:Label(" World ESP ")
E:Toggle("炸彈透視", false, function(v) Flags.ESP_Bomb = v end)
E:Toggle("炸彈計時器", false, function(v) Flags.ESP_BombTimer = v end)
E:Toggle("炸彈距離", false, function(v) Flags.ESP_BombDist = v end)
E:Toggle("拆彈包透視", false, function(v) Flags.ESP_DefuseKit = v end)
E:Toggle("手榴彈透視", false, function(v) Flags.ESP_Grenade = v end)
E:Toggle("手榴彈線", false, function(v) Flags.ESP_GrenadeLine = v end)
E:Toggle("物品透視", false, function(v) Flags.ESP_Loot = v end)
E:Toggle("載具透視", false, function(v) Flags.ESP_Vehicle = v end)
E:Toggle("掉落武器透視", false, function(v) Flags.ESP_DroppedWep = v end)
E:Toggle("目標透視", false, function(v) Flags.ESP_Objective = v end)
E:Toggle("材質透視", false, function(v) Flags.Chams = v end)
E:Toggle("發光透視", false, function(v) Flags.ESP_Glow = v end)
E:Slider("Glow Transparency", 0, 100, 50, function(v) Flags.ESP_GlowT = v end)
E:Separator()

 -- Visual
E:Label(" Visual Settings ")
E:Dropdown({Name="方框風格", Flag="ESPBoxStyle", Options={"2D","Corners","3D","Filled Box","Full Box"}, Default="2D"})
E:Dropdown({Name="透視顏色模式", Flag="ESPColorMode", Options={"Team","血量","距離","Rainbow","自定義"}, Default="Team"})
pcall(function() E:Colorpicker("Custom Color", Color3.fromRGB(255,255,255), function(v) Flags.ESP_CustomColor = v end) end)
E:Toggle("透視輪廓", true, function(v) Flags.ESP_Outline = v end)
E:Slider("方框線寬", 1, 3, 1, function(v) Flags.ESP_BoxThick = v end)
E:Slider("Box Fill Transparency", 0, 100, 50, function(v) Flags.ESP_BoxFillT = v end)
E:Slider("Tracer Thickness", 1, 3, 1, function(v) Flags.ESP_TracerThick = v end)
E:Dropdown({Name="Tracer Origin", Flag="ESPTracerOrigin", Options={"下","居中","上","Mouse"}, Default="Bottom"})
E:Dropdown({Name="名字對齊", Flag="ESPNameAlign", Options={"居中","左","右"}, Default="Center"})
E:Dropdown({Name="血量顏色", Flag="ESPHealthColor", Options={"Classic","Gradient","Segmented"}, Default="Classic"})
E:Toggle("彩虹透視速度", false, function(v) Flags.ESP_Rainbow = v end)
E:Slider("Rainbow Speed", 1, 20, 5, function(v) Flags.ESP_RainbowSpeed = v end)
E:Separator()

 -- Display
E:Label(" Display ")
E:Toggle("浮水印", false, function(v) Flags.ESP_Watermark = v end)
E:Dropdown({Name="Watermark Style", Flag="ESPWmStyle", Options={"左","居中","右"}, Default="Left"})
E:Toggle("狀態顯示", false, function(v) Flags.ESP_Status = v end)
E:Toggle("回合資訊", false, function(v) Flags.ESP_RoundInfo = v end)
E:Toggle("觀戰列表", false, function(v) Flags.ESP_SpecList = v end)
E:Toggle("警告系統", false, function(v) Flags.ESP_Alert = v end)
E:Toggle("FPS 顯示", false, function(v) Flags.ESP_FPS = v end)
E:Toggle("速度顯示", false, function(v) Flags.ESP_Speed = v end)
E:Toggle("擊殺訊息", false, function(v) Flags.ESP_KillFeed = v end)
E:Toggle("傷害數字", false, function(v) Flags.ESP_DmgNumbers = v end)
E:Toggle("命中標記", false, function(v) Flags.ESP_HitMarker = v end)
E:Toggle("雷達透視", false, function(v) Flags.ESP_Radar = v end)
E:Slider("Radar Size", 100, 300, 150, function(v) Flags.ESP_RadarSize = v end)
E:Slider("Radar Range", 50, 500, 200, function(v) Flags.ESP_RadarRange = v end)
E:Toggle("雷達背景", false, function(v) Flags.ESP_RadarBG = v end)
E:Toggle("指南針", false, function(v) Flags.ESP_Compass = v end)
E:Separator()

 -- Settings
E:Label(" Settings ")
E:Toggle("隊伍檢查", true, function(v) Flags.ESP_TeamCheck = v end)
E:Toggle("距離限制", false, function(v) Flags.ESP_DistLimit = v end)
E:Slider("最大透視距離", 50, 500, 200, function(v) Flags.ESP_MaxDist = v end)
E:Toggle("可視檢查", false, function(v) Flags.ESP_VisCheck = v end)
E:Toggle("按距離排序", false, function(v) Flags.ESP_SortDist = v end)
E:Toggle("視野圈", false, function(v) Flags.ESP_FOVCirc = v end)
E:Slider("視野圈大小", 10, 360, 100, function(v) Flags.ESP_FOVSize = v end)
E:Toggle("視野填充", false, function(v) Flags.ESP_FOVFill = v end)
E:Toggle("十字準星", false, function(v) Flags.CustomCrosshair = v end)
E:Slider("十字準星大小", 1, 20, 5, function(v) Flags.CrosshairSize = v end)
E:Slider("十字準星間距", 1, 10, 2, function(v) Flags.CrosshairGap = v end)
E:Slider("十字準星粗細", 1, 5, 1, function(v) Flags.CrosshairThick = v end)
E:Toggle("十字準星點", false, function(v) Flags.CrosshairDot = v end)
E:Dropdown({Name="十字準星風格", Flag="CrosshairStyle", Options={"Plus","Circle","Triangle","Diamond","T-Shape"}, Default="Plus"})
E:Toggle("十字準星輪廓", false, function(v) Flags.CrosshairOutline = v end)
E:Slider("十字準星輪廓大小", 1, 5, 2, function(v) Flags.CrosshairOLSize = v end)
E:Separator()

 -- Miscellaneous
E:Label(" Miscellaneous ")
E:Toggle("第三人稱", false, function(v) Flags.ThirdPerson = v end)
E:Slider("TP Distance", 2, 30, 12, function(v) Flags.TPDistance = v end)
E:Slider("TP Height", -5, 10, 2, function(v) Flags.TPHeight = v end)
E:Slider("TP Smooth", 1, 20, 5, function(v) Flags.TPSmooth = v end)
E:Dropdown({Name="TP Shoulder", Flag="TPShoulder", Options={"右", "左", "居中"}, Default="Right"})
E:Slider("TP Shoulder Offset", -10, 10, 3, function(v) Flags.TPShoulderOffset = v end)
E:Toggle("第三人稱自動縮放", true, function(v) Flags.TPAutoZoom = v end)
E:Toggle("第三人稱碰撞檢查", true, function(v) Flags.TPCollision = v end)
E:Toggle("第三人稱平滑", true, function(v) Flags.TPSmoothLook = v end)
E:Toggle("第三人稱頭部追蹤", false, function(v) Flags.TPHeadFollow = v end)
E:Slider("TP FOV", 50, 120, 70, function(v) Flags.TPFOV = v end)
E:Label("Scroll: Zoom | V: Shoulder | C: Reset")
E:Separator()

 -- Viewmodel
E:Label(" Viewmodel ")
E:Toggle("角色位置", false, function(v) Flags.VMOffset = v end)
E:Slider("VM Pos X", -20, 20, -5, function(v) Flags.VMPosX = v end)
E:Slider("VM Pos Y", -20, 20, 0, function(v) Flags.VMPosY = v end)
E:Slider("VM Pos Z", -30, 0, -15, function(v) Flags.VMPosZ = v end)
E:Toggle("角色角度", false, function(v) Flags.VMAngle = v end)
E:Slider("VM Ang X", -45, 45, 0, function(v) Flags.VMAngX = v end)
E:Slider("VM Ang Y", -45, 45, 0, function(v) Flags.VMAngY = v end)
E:Slider("VM Ang Z", -45, 45, 0, function(v) Flags.VMAngZ = v end)
E:Toggle("角色縮放", false, function(v) Flags.VMScale = v end)
E:Slider("VM Scale %", 50, 200, 100, function(v) Flags.VMScaleVal = v end)
E:Toggle("角色視野", false, function(v) Flags.VMFOV = v end)
E:Slider("VM FOV Value", 50, 120, 70, function(v) Flags.VMFOVVal = v end)
E:Separator()
E:Label(" VM Effects ")
E:Toggle("角色搖晃(走路)", false, function(v) Flags.VMBob = v end)
E:Slider("VM Bob Amount", 1, 20, 5, function(v) Flags.VMBobAmount = v end)
E:Slider("VM Bob Speed", 1, 20, 8, function(v) Flags.VMBobSpeed = v end)
E:Toggle("角色晃動(滑鼠)", false, function(v) Flags.VMSway = v end)
E:Slider("VM Sway Amount", 1, 20, 3, function(v) Flags.VMSwayAmount = v end)
E:Toggle("角色呼吸", false, function(v) Flags.VMBreathe = v end)
E:Slider("VM Breathe Amount", 1, 10, 1, function(v) Flags.VMBreatheAmount = v end)
E:Slider("VM Breathe Speed", 1, 10, 5, function(v) Flags.VMBreatheSpeed = v end)
E:Toggle("角色後座動畫", false, function(v) Flags.VMRecoil = v end)
E:Slider("VM Recoil Amount", 1, 20, 8, function(v) Flags.VMRecoilAmount = v end)
E:Separator()
E:Label(" VM Presets ")
E:Button({Name="CS2 Style", Color=Color3.fromRGB(60,120,60)}, function() if BS.Viewmodel then BS.Viewmodel.ApplyPreset("CS2 Style") end end)
E:Button({Name="最右", Color=Color3.fromRGB(60,80,120)}, function() if BS.Viewmodel then BS.Viewmodel.ApplyPreset("Far Right") end end)
E:Button({Name="近距離", Color=Color3.fromRGB(120,60,60)}, function() if BS.Viewmodel then BS.Viewmodel.ApplyPreset("Close Up") end end)
E:Button({Name="Tight", Color=Color3.fromRGB(80,60,120)}, function() if BS.Viewmodel then BS.Viewmodel.ApplyPreset("Tight") end end)
E:Button({Name="Wide", Color=Color3.fromRGB(120,120,60)}, function() if BS.Viewmodel then BS.Viewmodel.ApplyPreset("Wide") end end)
E:Button({Name="居中", Color=Color3.fromRGB(60,120,120)}, function() if BS.Viewmodel then BS.Viewmodel.ApplyPreset("Center") end end)
E:Button({Name="游擊", Color=Color3.fromRGB(120,80,60)}, function() if BS.Viewmodel then BS.Viewmodel.ApplyPreset("Insurgency") end end)
E:Button({Name="預設", Color=Color3.fromRGB(100,100,100)}, function() if BS.Viewmodel then BS.Viewmodel.ApplyPreset("Default") end end)
E:Separator()

-- SOUND ESP (Footstep indicators)
E:Label(" Sound ESP ")
E:Toggle("聲音透視", false, function(v) Flags.ESP_Sound = v end)
E:Slider("Sound ESP Range", 10, 100, 50, function(v) Flags.ESP_SoundRange = v end)
E:Toggle("3D聲音透視", false, function(v) Flags.ESP_Sound3D = v end)
E:Toggle("腳步指示器", false, function(v) Flags.ESP_Footstep = v end)
E:Slider("Footstep Duration", 1, 10, 3, function(v) Flags.ESP_FootDuration = v end)
E:Separator()

-- GLOW ESP
E:Label(" Glow ESP ")
E:Toggle("發光透視", false, function(v) Flags.ESP_Glow = v end)
E:Slider("Glow Intensity", 1, 20, 5, function(v) Flags.ESP_GlowIntensity = v end)
E:Slider("Glow Thickness", 1, 5, 2, function(v) Flags.ESP_GlowThick = v end)
E:Toggle("發光隊伍檢查", false, function(v) Flags.ESP_GlowTeam = v end)
E:Separator()


-- SOUND ESP Implementation
-- Shows footstep indicators for nearby players
local SoundObjs = {}
task.spawn(function()
    while true do
        task.wait(0.2)
        if Flags.ESP_Sound and BS.alive and BS.alive() then
            pcall(function()
                local myHrp = BS.hrp and BS.hrp()
                if not myHrp then return end
                local range = (Flags.ESP_SoundRange or 50) * 3
                local cam = workspace.CurrentCamera
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= lplr and p.Character then
                        local hrp = p and p.Character:FindFirstChild("HumanoidRootPart")
                        local hum = p and p.Character:FindFirstChildOfClass("Humanoid")
                        if hrp and hum and hum.MoveDirection.Magnitude > 0 then
                            local dist = (hrp.Position - myHrp.Position).Magnitude
                            if dist <= range then
                                local sp, vis = cam:WorldToViewportPoint(hrp.Position)
                                if vis then
                                    local key = p.UserId
                                    if not SoundObjs[key] then
                                        SoundObjs[key] = Drawing.new("Circle")
                                        SoundObjs[key].Filled = true
                                        SoundObjs[key].NumSides = 20
                                        SoundObjs[key].Thickness = 1
                                    end
                                    local alpha = 1 - (dist / range)
                                    SoundObjs[key].Position = Vector2.new(sp.X, sp.Y)
                                    SoundObjs[key].Radius = 6 + alpha * 10
                                    SoundObjs[key].Color = Color3.new(1, 0.5, 0) -- Orange
                                    SoundObjs[key].Transparency = alpha * 0.7
                                    SoundObjs[key].Visible = true
                                end
                            end
                        end
                    end
                end
                -- Cleanup far players
                for key, obj in pairs(SoundObjs) do
                    local player = Players:GetPlayerByUserId(key)
                    if not player or not player.Character then
                        obj.Visible = false
                    end
                end
            end)
        else
            for _, obj in pairs(SoundObjs) do pcall(function() obj.Visible = false end) end
        end
    end
end)

-- GLOW ESP Implementation
-- Draws glow outline around players
local GlowObjs = {}
task.spawn(function()
    while true do
        task.wait(0.1)
        if Flags.ESP_Glow and BS.alive and BS.alive() then
            pcall(function()
                local cam = workspace.CurrentCamera
                local myTeam = lplr.Team
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= lplr and p.Character then
                        if Flags.ESP_GlowTeam and p.Team == myTeam then
                            if GlowObjs[p.UserId] then GlowObjs[p.UserId].Visible = false end
                            continue
                        end
                        local hrp = p and p.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local sp, vis = cam:WorldToViewportPoint(hrp.Position)
                            if vis then
                                local key = p.UserId
                                if not GlowObjs[key] then
                                    GlowObjs[key] = Drawing.new("Circle")
                                    GlowObjs[key].Filled = false
                                    GlowObjs[key].NumSides = 30
                                end
                                GlowObjs[key].Position = Vector2.new(sp.X, sp.Y)
                                GlowObjs[key].Radius = 20 + (Flags.ESP_GlowIntensity or 5) * 2
                                GlowObjs[key].Thickness = (Flags.ESP_GlowThick or 2)
                                GlowObjs[key].Color = Color3.new(0.3, 0.5, 1)
                                GlowObjs[key].Transparency = 0.5
                                GlowObjs[key].Visible = true
                            end
                        end
                    end
                end
            end)
        else
            for _, obj in pairs(GlowObjs) do pcall(function() obj.Visible = false end) end
        end
    end
end)



-- SKELETON ESP Implementation
local function drawSkeleton(player, hrp, color)
    if not Flags.ESP_Skeleton then return end
    pcall(function()
        local cam = workspace.CurrentCamera
        local char = player.Character
        if not char then return end
        
        local bones = {
            {"頭部", "Torso"},
            {"Torso", "Left Arm"},
            {"Torso", "Right Arm"},
            {"Torso", "Left Leg"},
            {"Torso", "Right Leg"},
        }
        
        for _, bone in pairs(bones) do
            local part1 = char:FindFirstChild(bone[1])
            local part2 = char:FindFirstChild(bone[2])
            if part1 and part2 then
                local sp1, vis1 = cam:WorldToViewportPoint(part1.Position)
                local sp2, vis2 = cam:WorldToViewportPoint(part2.Position)
                if vis1 and vis2 then
                    local line = poolLine()
                    line.From = Vector2.new(sp1.X, sp1.Y)
                    line.To = Vector2.new(sp2.X, sp2.Y)
                    line.Color = color
                    line.Thickness = 1
                    line.Visible = true
                end
            end
        end
    end)
end

-- SNAPLINES Implementation
local function drawSnapline(player, hrp, color)
    if not Flags.ESP_Snaplines then return end
    pcall(function()
        local cam = workspace.CurrentCamera
        local sp, vis = cam:WorldToViewportPoint(hrp.Position)
        if vis then
            local line = poolLine()
            line.From = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
            line.To = Vector2.new(sp.X, sp.Y)
            line.Color = color
            line.Thickness = 1
            line.Visible = true
        end
    end)
end

-- HEAD DOT Implementation
local function drawHeadDot(player, hrp, color)
    if not Flags.ESP_HeadDot then return end
    pcall(function()
        local head = player.Character and player and player.Character:FindFirstChild("Head")
        if not head then return end
        local cam = workspace.CurrentCamera
        local sp, vis = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        if vis then
            local circle = poolCircle()
            circle.Position = Vector2.new(sp.X, sp.Y)
            circle.Radius = 4
            circle.Color = color
            circle.Filled = true
            circle.Visible = true
        end
    end)
end

-- BARREL ESP Implementation
local function drawBarrel(player, hrp, color)
    if not Flags.ESP_Barrel then return end
    pcall(function()
        local head = player.Character and player and player.Character:FindFirstChild("Head")
        if not head then return end
        local cam = workspace.CurrentCamera
        local sp1, vis1 = cam:WorldToViewportPoint(hrp.Position)
        local sp2, vis2 = cam:WorldToViewportPoint(hrp.Position + head.CFrame.LookVector * 3)
        if vis1 and vis2 then
            local line = poolLine()
            line.From = Vector2.new(sp1.X, sp1.Y)
            line.To = Vector2.new(sp2.X, sp2.Y)
            line.Color = Color3.new(1, 0, 0)
            line.Thickness = 2
            line.Visible = true
        end
    end)
end


-- OBJECT POOL  Zero GC pressure

local LinePool, TextPool, SquarePool, CirclePool = {}, {}, {}, {}
local PIdx = {L=1, T=1, S=1, C=1}
local PMax = {L=0, T=0, S=0, C=0}

-- Use compat layer for Drawing API (supports all executors)
local Compat = _G.BS and _G.BS.Compat
local function createDrawing(class)
    if Compat and Compat.DrawingNew then return Compat.DrawingNew(class) end
    local s, r = pcall(function() return Drawing.new(class) end)
    return s and r or nil
end

-- Mobile scale factor for ESP elements
local espScale = 1
if Compat and Compat.Scale then espScale = Compat.Scale end

local function poolLine()
    local i = PIdx.L; PIdx.L = i + 1
    if not LinePool[i] then
        local obj = createDrawing("Line")
        if obj then obj.Visible=false; obj.Thickness=1; LinePool[i]=obj; PMax.L=PMax.L+1 end
    end
    return LinePool[i]
end
local function poolText()
    local i = PIdx.T; PIdx.T = i + 1
    if not TextPool[i] then
        local obj = createDrawing("Text")
        if obj then obj.Visible=false; obj.Size=13; obj.Center=true; obj.Outline=true; TextPool[i]=obj; PMax.T=PMax.T+1 end
    end
    return TextPool[i]
end
local function poolSquare()
    local i = PIdx.S; PIdx.S = i + 1
    if not SquarePool[i] then
        local obj = createDrawing("Square")
        if obj then obj.Visible=false; obj.Filled=false; SquarePool[i]=obj; PMax.S=PMax.S+1 end
    end
    return SquarePool[i]
end
local function poolCircle()
    local i = PIdx.C; PIdx.C = i + 1
    if not CirclePool[i] then
        local obj = createDrawing("Circle")
        if obj then obj.Visible=false; obj.Filled=false; CirclePool[i]=obj; PMax.C=PMax.C+1 end
    end
    return CirclePool[i]
end

local function resetPool() PIdx.L=1; PIdx.T=1; PIdx.S=1; PIdx.C=1 end
local function hideUnused()
    for i=PIdx.L,PMax.L do LinePool[i].Visible=false end
    for i=PIdx.T,PMax.T do TextPool[i].Visible=false end
    for i=PIdx.S,PMax.S do SquarePool[i].Visible=false end
    for i=PIdx.C,PMax.C do CirclePool[i].Visible=false end
end

-- CACHED FUNCTIONS

local w2s = function(pos) return workspace.CurrentCamera:WorldToViewportPoint(pos) end
local v2 = Vector2.new
local v3 = Vector3.new
local mAbs, mFloor, mClamp, mAtan2, mSin, mCos, mRad, mSqrt, mMin, mMax =
    math.abs, math.floor, math.clamp, math.atan2, math.sin, math.cos, math.rad, math.sqrt, math.min, math.max
local RGB = Color3.fromRGB
local RGBLerp = Color3.new().Lerp

local V3_UP = v3(0, 3, 0)
local V3_ZERO = v3(0, 0, 0)

-- Color constants
local C_WHITE=RGB(255,255,255); local C_RED=RGB(255,50,50); local C_GREY=RGB(200,200,200)
local C_GREEN=RGB(0,255,0); local C_YELLOW=RGB(255,255,0); local C_BLUE=RGB(50,150,255)
local C_HP_BG=RGB(50,50,50); local C_ARMOR=RGB(0,150,255); local C_WEAPON=RGB(200,150,50)
local C_BOMB=RGB(255,100,0); local C_ORANGE=RGB(255,165,0); local C_CYAN=RGB(0,200,255)
local C_PURPLE=RGB(180,0,255); local C_PINK=RGB(255,0,150)

-- BOX CALCULATION (shared)

local function calcBox(hrp)
    local pos, vis = w2s(workspace.CurrentCamera, hrp.Position)
    if not vis then return nil end
    local topP = w2s(workspace.CurrentCamera, hrp.Position + V3_UP)
    local botP = w2s(workspace.CurrentCamera, hrp.Position - V3_UP)
    local boxH = mAbs(topP.Y - botP.Y)
    return pos, boxH, boxH * 0.5
end

-- COLOR MODE

local rainbowHue = 0
local function getESPColor(player, hum, dist)
    local mode = Flags.ESPColorMode or "Team"
    if mode == "Custom" then return Flags.ESP_CustomColor or C_WHITE
    elseif mode == "Rainbow" then
        rainbowHue = (rainbowHue + (Flags.ESP_RainbowSpeed or 5) * 0.001) % 1
        return Color3.fromHSV(rainbowHue, 1, 1)
    elseif mode == "Health" then
        local hp = hum.Health / hum.MaxHealth
        if hp > 0.5 then return C_GREEN elseif hp > 0.25 then return C_YELLOW else return C_RED end
    elseif mode == "Distance" then
        if dist < 50 then return C_RED elseif dist < 100 then return C_YELLOW else return C_GREEN end
    else
        local myTeam = BS.team()
        if myTeam and player.Team == myTeam then return C_BLUE end
        return C_RED
    end
end

-- Health bar color
local function getHealthColor(pct, mode)
    if mode == "Segmented" then
        if pct > 0.75 then return RGB(0,200,0) elseif pct > 0.5 then return RGB(0,200,0)
        elseif pct > 0.25 then return RGB(200,200,0) else return RGB(200,0,0) end
    elseif mode == "Gradient" then
        return RGBLerp(RGB(255,0,0), RGB(0,255,0), pct)
    else
        if pct > 0.5 then return C_GREEN elseif pct > 0.25 then return C_YELLOW else return C_RED end
    end
end

-- DRAWING FUNCTIONS

 -- 2D Box
local function drawBox2D(hrp, color, thick)
    local pos, boxH, boxW = calcBox(hrp)
    if not pos then return end
    local hw, hh = boxW*0.5, boxH*0.5; local x, y = pos.X, pos.Y
    local l1=poolLine(); l1.From=v2(x-hw,y-hh); l1.To=v2(x+hw,y-hh); l1.Color=color; l1.Thickness=thick; l1.Visible=true
    local l2=poolLine(); l2.From=v2(x-hw,y+hh); l2.To=v2(x+hw,y+hh); l2.Color=color; l2.Thickness=thick; l2.Visible=true
    local l3=poolLine(); l3.From=v2(x-hw,y-hh); l3.To=v2(x-hw,y+hh); l3.Color=color; l3.Thickness=thick; l3.Visible=true
    local l4=poolLine(); l4.From=v2(x+hw,y-hh); l4.To=v2(x+hw,y+hh); l4.Color=color; l4.Thickness=thick; l4.Visible=true
end

 -- Corner Box
local function drawCornerBox(hrp, color, thick)
    local pos, boxH, boxW = calcBox(hrp)
    if not pos then return end
    local cl=boxW*0.3; local x,y = pos.X-boxW*0.5, pos.Y-boxH*0.5
    local c={v2(x,y),v2(x+cl,y),v2(x,y),v2(x,y+cl),v2(x+boxW,y),v2(x+boxW-cl,y),v2(x+boxW,y),v2(x+boxW,y+cl),
             v2(x,y+boxH),v2(x+cl,y+boxH),v2(x,y+boxH),v2(x,y+boxH-cl),v2(x+boxW,y+boxH),v2(x+boxW-cl,y+boxH),v2(x+boxW,y+boxH),v2(x+boxW,y+boxH-cl)}
    for i=1,8 do local l=poolLine(); l.From=c[i*2-1]; l.To=c[i*2]; l.Color=color; l.Thickness=thick; l.Visible=true end
end

 -- 3D Box
local function draw3DBox(hrp, color, thick)
    local cam = workspace.CurrentCamera
    local cf = hrp.CFrame
    local size = v3(1.5, 3, 1.5)
    local corners3D = {
        -- cf * v3(-size.X,-size.Y,-size.Z), cf * v3(size.X,-size.Y,-size.Z),
        -- cf * v3(size.X,-size.Y,size.Z), cf * v3(-size.X,-size.Y,size.Z),
        -- cf * v3(-size.X,size.Y,-size.Z), cf * v3(size.X,size.Y,-size.Z),
        -- cf * v3(size.X,size.Y,size.Z), cf * v3(-size.X,size.Y,size.Z),
    }
    local corners2D, visAll = {}, true
    for i, c3 in ipairs(corners3D) do
        local p, v = w2s(cam, c3)
        corners2D[i] = p; if not v then visAll = false end
    end
    if not visAll then return end
    local edges = {{1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}}
    for _, e in ipairs(edges) do
        local l=poolLine(); l.From=corners2D[e[1]]; l.To=corners2D[e[2]]; l.Color=color; l.Thickness=thick; l.Visible=true
    end
end

 -- Full Box (double outline)
local function drawFullBox(hrp, color, thick)
    drawBox2D(hrp, color, thick)
    local pos, boxH, boxW = calcBox(hrp)
    if not pos then return end
    local hw, hh = boxW*0.5+2, boxH*0.5+2; local x,y = pos.X, pos.Y
    local ol = Flags.ESP_Outline and RGB(0,0,0) or color
    local l1=poolLine(); l1.From=v2(x-hw,y-hh); l1.To=v2(x+hw,y-hh); l1.Color=ol; l1.Thickness=thick+2; l1.Visible=true
    local l2=poolLine(); l2.From=v2(x-hw,y+hh); l2.To=v2(x+hw,y+hh); l2.Color=ol; l2.Thickness=thick+2; l2.Visible=true
    local l3=poolLine(); l3.From=v2(x-hw,y-hh); l3.To=v2(x-hw,y+hh); l3.Color=ol; l3.Thickness=thick+2; l3.Visible=true
    local l4=poolLine(); l4.From=v2(x+hw,y-hh); l4.To=v2(x+hw,y+hh); l4.Color=ol; l4.Thickness=thick+2; l4.Visible=true
end

 -- Filled Box
local function drawFilledBox(hrp, color, thick)
    local pos, boxH, boxW = calcBox(hrp)
    if not pos then return end
    local hw, hh = boxW*0.5, boxH*0.5
    local fill=poolSquare(); fill.Size=v2(boxW,boxH); fill.Position=v2(pos.X-hw,pos.Y-hh); fill.Color=color; fill.Filled=true; fill.Transparency=(Flags.ESP_BoxFillT or 50)/100; fill.Visible=true
    drawBox2D(hrp, color, thick)
end

 -- Health Bar (Left/Right/Top)
local function drawHealthBar(hrp, hum, color)
    local pos, boxH, boxW = calcBox(hrp)
    if not pos then return end
    local hpPct = hum.Health / hum.MaxHealth
    local hpMode = Flags.ESPHealthColor or "Classic"
    local hpC = getHealthColor(hpPct, hpMode)
    local hpPos = Flags.ESPHealthPos or "Left"
    local x, y, barW, barH

    if hpPos == "Top" then
        x = pos.X - boxW * 0.5; y = pos.Y - boxH * 0.5 - 8
        barW = boxW; barH = 4
        local bg=poolSquare(); bg.Size=v2(barW,barH); bg.Position=v2(x,y); bg.Color=C_HP_BG; bg.Filled=true; bg.Visible=true
        local fill=poolSquare(); fill.Size=v2(barW*hpPct,barH); fill.Position=v2(x,y); fill.Color=hpC; fill.Filled=true; fill.Visible=true
    elseif hpPos == "Right" then
        x = pos.X + boxW * 0.5 + 2; y = pos.Y - boxH * 0.5
        barW = 4; barH = boxH
        local bg=poolSquare(); bg.Size=v2(barW,barH); bg.Position=v2(x,y); bg.Color=C_HP_BG; bg.Filled=true; bg.Visible=true
        local fill=poolSquare(); fill.Size=v2(barW,barH*hpPct); fill.Position=v2(x,y+barH*(1-hpPct)); fill.Color=hpC; fill.Filled=true; fill.Visible=true
    else -- Left (default)
        x = pos.X - boxW * 0.5 - 6; y = pos.Y - boxH * 0.5
        barW = 4; barH = boxH
        local bg=poolSquare(); bg.Size=v2(barW,barH); bg.Position=v2(x,y); bg.Color=C_HP_BG; bg.Filled=true; bg.Visible=true
        local fill=poolSquare(); fill.Size=v2(barW,barH*hpPct); fill.Position=v2(x,y+barH*(1-hpPct)); fill.Color=hpC; fill.Filled=true; fill.Visible=true
    end

    -- Health text
    if Flags.ESP_HealthText then
        local txt = mFloor(hum.Health)
        local t=poolText(); t.Position=v2(x + barW/2, y + barH * (1 - hpPct)); t.Text=tostring(txt); t.Size=10; t.Color=C_WHITE; t.Center=true; t.Visible=true
    end
end

 -- Armor Bar
local function drawArmorBar(hrp, player)
    local armor = 0
    pcall(function() armor = player.Character and player.Character:GetAttribute("Armor") or 0 end)
    if armor <= 0 then return end
    local pos, boxH, boxW = calcBox(hrp)
    if not pos then return end
    local x = pos.X + boxW * 0.5 + (Flags.ESPHealthPos == "Right" and 8 or 2)
    local y = pos.Y - boxH * 0.5
    local aPct = mClamp(armor/100,0,1)
    local bg=poolSquare(); bg.Size=v2(4,boxH); bg.Position=v2(x,y); bg.Color=C_HP_BG; bg.Filled=true; bg.Visible=true
    local fill=poolSquare(); fill.Size=v2(4,boxH*aPct); fill.Position=v2(x,y+boxH*(1-aPct)); fill.Color=C_ARMOR; fill.Filled=true; fill.Visible=true
end

 -- Name (with background) 
local function drawName(player, hrp, color)
    local pos, vis = w2s(workspace.CurrentCamera, hrp.Position + V3_UP)
    if not vis then return end
    local fontSize = Flags.ESP_NameSize or 13
    local align = Flags.ESPNameAlign or "Center"
    local t=poolText()
    t.Position=v2(pos.X, pos.Y - 15 - fontSize)
    t.Text=player.DisplayName
    t.Color=color
    t.Size=fontSize
    t.Center = (align == "Center")
    t.Visible=true

    -- Name background
    if Flags.ESP_NameBG then
        local txtW = t.TextBounds.X + 6
        local txtH = fontSize + 4
        local bgX = align == "Center" and (pos.X - txtW/2) or (align == "Left" and (pos.X - txtW) or pos.X)
        local bg=poolSquare(); bg.Size=v2(txtW,txtH); bg.Position=v2(bgX, pos.Y - 15 - fontSize - 2); bg.Color=RGB(0,0,0); bg.Filled=true; bg.Transparency=0.5; bg.Visible=true
    end
end

 -- Distance (with unit)
local function drawDistance(hrp, color)
    local myHrp = BS.hrp and BS.hrp()
    if not myHrp then return end
    local pos, vis = w2s(workspace.CurrentCamera, hrp.Position - V3_UP)
    if not vis then return end
    local dist = mFloor((myHrp.Position-hrp.Position).Magnitude)
    local unit = Flags.ESP_DistUnit and "m" or ""
    local t=poolText(); t.Position=v2(pos.X,pos.Y+5); t.Text=dist..unit; t.Color=color; t.Size=11; t.Visible=true
end

 -- Weapon (with ammo) 
local function drawWeapon(player, hrp, color)
    local tool = player.Character and player and player.Character:FindFirstChildWhichIsA("Tool")
    if not tool then return end
    local pos, vis = w2s(workspace.CurrentCamera, hrp.Position - v3(0,4,0))
    if not vis then return end
    local wepName = tool.Name
    if Flags.ESP_WeaponAmmo then
        local ammo = tool:GetAttribute("Ammo") or tool:GetAttribute("CurrentAmmo") or "?"
        wepName = wepName .. " [" .. tostring(ammo) .. "]"
    end
    local t=poolText(); t.Position=v2(pos.X,pos.Y+5); t.Text=wepName; t.Color=C_WEAPON; t.Size=11; t.Visible=true
end

 -- Tracer
local function drawTracer(hrp, color)
    local pos, vis = w2s(workspace.CurrentCamera, hrp.Position)
    if not vis then return end
    local orig = Flags.ESPTracerOrigin or "Bottom"
    local sw, sh = workspace.CurrentCamera.ViewportSize.X, workspace.CurrentCamera.ViewportSize.Y
    local from
    if orig=="Bottom" then from=v2(sw*0.5,sh)
    elseif orig=="Center" then from=v2(sw*0.5,sh*0.5)
    elseif orig=="Top" then from=v2(sw*0.5,0)
    else from=getMousePos() end
    local l=poolLine(); l.From=from; l.To=v2(pos.X,pos.Y); l.Color=color; l.Thickness=Flags.ESP_TracerThick or 1; l.Visible=true
end

 -- Head Dot
local function drawHeadDot(hrp)
    local head = hrp.Parent and hrp.Parent:FindFirstChild("Head")
    if not head then return end
    local pos, vis = w2s(workspace.CurrentCamera, head.Position)
    if not vis then return end
    local c=poolCircle(); c.Position=v2(pos.X,pos.Y); c.Radius=3; c.Color=C_RED; c.Filled=true; c.Visible=true
end

 -- Head Hitbox
local function drawHeadHitbox(hrp, color)
    local head = hrp.Parent and hrp.Parent:FindFirstChild("Head")
    if not head then return end
    local pos, vis = w2s(workspace.CurrentCamera, head.Position)
    if not vis then return end
    local c=poolCircle(); c.Position=v2(pos.X,pos.Y); c.Radius=8; c.Color=color; c.Thickness=1; c.Filled=false; c.Visible=true
end

 -- Barrel
local function drawBarrel(hrp, color)
    local lookVec = hrp.CFrame.LookVector
    local p1,v1 = w2s(workspace.CurrentCamera, hrp.Position + lookVec)
    local p2,v2v = w2s(workspace.CurrentCamera, hrp.Position + lookVec * 5)
    if v1 and v2v then
        local l=poolLine(); l.From=v2(p1.X,p1.Y); l.To=v2(p2.X,p2.Y); l.Color=color; l.Thickness=1; l.Visible=true
    end
end

 -- Snaplines
local function drawSnapline(hrp, color)
    local pos, vis = w2s(hrp.Position)
    if not vis then return end
    local sw, sh = workspace.CurrentCamera.ViewportSize.X, workspace.CurrentCamera.ViewportSize.Y
    local l=poolLine(); l.From=v2(sw*0.5,sh*0.5); l.To=v2(pos.X,pos.Y); l.Color=color; l.Thickness=1; l.Visible=true
end

 -- Skeleton
local function drawSkeleton(player, color)
    local char = player.Character; if not char then return end
    local function gp(n) local p=char:FindFirstChild(n); return p and p.Position or nil end
    local head,torso,root = gp("Head"),gp("UpperTorso") or gp("Torso"),gp("HumanoidRootPart")
    local lArm,rArm = gp("LeftUpperArm") or gp("Left Arm"),gp("RightUpperArm") or gp("Right Arm")
    local lLeg,rLeg = gp("LeftUpperLeg") or gp("Left Leg"),gp("RightUpperLeg") or gp("Right Leg")
    local lFore,rFore = gp("LeftLowerArm") or gp("Left Arm"),gp("RightLowerArm") or gp("Right Arm")
    local lShin,rShin = gp("LeftLowerLeg") or gp("Left Leg"),gp("RightLowerLeg") or gp("Right Leg")
    local function bone(a,b)
        if not a or not b then return end
        local pa,va=w2s(workspace.CurrentCamera,a); local pb,vb=w2s(workspace.CurrentCamera,b)
        if va and vb then local l=poolLine(); l.From=v2(pa.X,pa.Y); l.To=v2(pb.X,pb.Y); l.Color=color; l.Visible=true end
    end
    bone(head,torso); bone(torso,root)
    bone(torso,lArm); bone(lArm,lFore)
    bone(torso,rArm); bone(rArm,rFore)
    bone(root,lLeg); bone(lLeg,lShin)
    bone(root,rLeg); bone(rLeg,rShin)
end

 -- Target ESP
local function drawTargetESP(player, hrp)
    if not Flags.ESP_Target then return end
    local target = RAGE and RAGE.Target
    if not target or target.Enemy.Player ~= player then return end
    local pos, vis = w2s(workspace.CurrentCamera, hrp.Position)
    if not vis then return end
    local c=poolCircle(); c.Position=v2(pos.X,pos.Y); c.Radius=20; c.Color=C_YELLOW; c.Thickness=2; c.Filled=false; c.Visible=true
end

 -- OOF Indicator (Out Of Field)
local function drawOOF(player, hrp, color)
    local cam = workspace.CurrentCamera
    local camCF = cam.CFrame
    local dirToPlayer = (hrp.Position - camCF.Position).Unit
    local camForward = camCF.LookVector
    local dot = camForward:Dot(dirToPlayer)
    if dot > 0.1 then return end -- on screen
    local pos, vis = w2s(cam, hrp.Position)
    if vis then return end -- on screen
    -- Show at screen edge
    local angle = mAtan2(camCF.RightVector:Dot(dirToPlayer), camForward:Dot(dirToPlayer))
    local cx, cy = cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5
    local radius = mMin(cx, cy) * 0.8
    local sx = cx + mSin(angle) * radius
    local sy = cy - mCos(angle) * radius
    local t=poolText(); t.Position=v2(sx,sy); t.Text=""; t.Size=16; t.Color=color; t.Center=true; t.Visible=true
end

 -- Off-Screen Arrow
local function drawOffScreenArrow(player, hrp, color)
    local cam = workspace.CurrentCamera
    local camCF = cam.CFrame
    local dirToPlayer = (hrp.Position - camCF.Position).Unit
    local camForward = camCF.LookVector
    local dot = camForward:Dot(dirToPlayer)
    if dot > 0 then return end -- on screen
    local angle = mAtan2(camCF.RightVector:Dot(dirToPlayer), camForward:Dot(dirToPlayer))
    local cx, cy = cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5
    local radius = mMin(cx, cy) * 0.85
    local arrowSize = Flags.ESP_ArrowSize or 15
    local sx = cx + mSin(angle) * radius
    local sy = cy - mCos(angle) * radius
    -- Arrow direction
    local perpX = mCos(angle)
    local perpY = mSin(angle)
    -- Triangle arrow
    local tip = v2(sx, sy)
    local left = v2(sx - perpX * arrowSize * 0.5 - mSin(angle) * arrowSize, sy + perpY * arrowSize * 0.5 - mCos(angle) * arrowSize)
    local right = v2(sx - perpX * arrowSize * 0.5 + mSin(angle) * arrowSize, sy + perpY * arrowSize * 0.5 + mCos(angle) * arrowSize)
    -- Draw 3 lines
    local l1=poolLine(); l1.From=left; l1.To=tip; l1.Color=color; l1.Thickness=2; l1.Visible=true
    local l2=poolLine(); l2.From=right; l2.To=tip; l2.Color=color; l2.Thickness=2; l2.Visible=true
    local l3=poolLine(); l3.From=left; l3.To=right; l3.Color=color; l3.Thickness=2; l3.Visible=true
    -- Name on arrow
    local t=poolText(); t.Position=v2(sx, sy + 12); t.Text=player.DisplayName; t.Color=color; t.Size=10; t.Center=true; t.Visible=true
end

 -- Headshot Icon
local function drawHeadshotIcon(hrp, color)
    local head = hrp.Parent and hrp.Parent:FindFirstChild("Head")
    if not head then return end
    local pos, vis = w2s(workspace.CurrentCamera, head.Position)
    if not vis then return end
    local t=poolText(); t.Position=v2(pos.X+10,pos.Y-10); t.Text=""; t.Size=12; t.Color=color; t.Visible=true
end

 -- Velocity Arrow
local function drawVelocityArrow(hrp, color)
    local vel = hrp.Velocity
    local speed = vel.Magnitude
    if speed < 1 then return end
    local dir = vel.Unit
    local startP = hrp.Position + dir * 1.5
    local endP = startP + dir * mMin(speed * 0.1, 5)
    local p1,v1 = w2s(workspace.CurrentCamera, startP)
    local p2,v2v = w2s(workspace.CurrentCamera, endP)
    if v1 and v2v then
        local l=poolLine(); l.From=v2(p1.X,p1.Y); l.To=v2(p2.X,p2.Y); l.Color=color; l.Thickness=1; l.Visible=true
    end
end

 -- Laser Line (from weapon to target)
local function drawLaserLine(player, hrp, color)
    if not Flags.ESP_LaserLine then return end
    local tool = player.Character and player and player.Character:FindFirstChildWhichIsA("Tool")
    if not tool then return end
    local muzzle = tool:FindFirstChild("Muzzle") or tool:FindFirstChild("Handle")
    if not muzzle then return end
    local startPos = tool.Handle and tool.Handle.Position or hrp.Position + hrp.CFrame.LookVector * 2
    local endPos = hrp.Position + hrp.CFrame.LookVector * 100
    local p1,v1 = w2s(workspace.CurrentCamera, startPos)
    local p2,v2v = w2s(workspace.CurrentCamera, endPos)
    if v1 and v2v then
        local l=poolLine(); l.From=v2(p1.X,p1.Y); l.To=v2(p2.X,p2.Y); l.Color=C_RED; l.Thickness=1; l.Visible=true
    end
end

 -- Info Card
local function drawInfoCard(player, hrp, hum, color, dist)
    if not Flags.ESP_InfoCard then return end
    local pos, boxH, boxW = calcBox(hrp)
    if not pos then return end
    local x = pos.X + boxW * 0.5 + 10
    local y = pos.Y - boxH * 0.5
    local lines = {
        player.DisplayName,
        -- "HP: " .. mFloor(hum.Health) .. "/" .. mFloor(hum.MaxHealth),
        -- "Dist: " .. mFloor(dist) .. "m",
    }
    local tool = player.Character and player and player.Character:FindFirstChildWhichIsA("Tool")
    if tool then table.insert(lines, "Wep: " .. tool.Name) end
    local velocity = hrp.Velocity.Magnitude
    if velocity > 1 then table.insert(lines, "Speed: " .. mFloor(velocity)) end
    -- Background
    local bgW = 120
    local bgH = #lines * 14 + 8
    local bg=poolSquare(); bg.Size=v2(bgW,bgH); bg.Position=v2(x,y); bg.Color=RGB(0,0,0); bg.Filled=true; bg.Transparency=0.6; bg.Visible=true
    -- Border
    local b1=poolLine(); b1.From=v2(x,y); b1.To=v2(x+bgW,y); b1.Color=color; b1.Thickness=1; b1.Visible=true
    local b2=poolLine(); b2.From=v2(x,y+bgH); b2.To=v2(x+bgW,y+bgH); b2.Color=color; b2.Thickness=1; b2.Visible=true
    local b3=poolLine(); b3.From=v2(x,y); b3.To=v2(x,y+bgH); b3.Color=color; b3.Thickness=1; b3.Visible=true
    local b4=poolLine(); b4.From=v2(x+bgW,y); b4.To=v2(x+bgW,y+bgH); b4.Color=color; b4.Thickness=1; b4.Visible=true
    -- Text lines
    for i, line in ipairs(lines) do
        local t=poolText(); t.Position=v2(x+4, y+4+(i-1)*14); t.Text=line; t.Color=C_WHITE; t.Size=10; t.Center=false; t.Visible=true
    end
end

 -- FOV Circle
local fovCircleObj = nil
local fovFillObj = nil
local function updateFOVCircle()
    if not Flags.ESP_FOVCirc then
        if fovCircleObj then fovCircleObj.Visible=false end
        if fovFillObj then fovFillObj.Visible=false end
        -- return
    end
    if not fovCircleObj then
        local obj = createDrawing("Circle")
        if obj then obj.Thickness=1; obj.NumSides=64; obj.Filled=false; fovCircleObj=obj end
    end
    fovCircleObj.Position = getMousePos()
    fovCircleObj.Radius = Flags.ESP_FOVSize or 100
    fovCircleObj.Color = C_WHITE
    fovCircleObj.Visible = true
    if Flags.ESP_FOVFill then
        if not fovFillObj then
            local obj = createDrawing("Circle")
            if obj then obj.Thickness=0; obj.NumSides=64; obj.Filled=true; fovFillObj=obj end
        end
        fovFillObj.Position = getMousePos()
        fovFillObj.Radius = Flags.ESP_FOVSize or 100
        fovFillObj.Color = RGB(255,255,255)
        fovFillObj.Filled = true
        fovFillObj.Transparency = 0.05
        fovFillObj.Visible = true
    elseif fovFillObj then
        fovFillObj.Visible = false
    end
end

 -- Custom Crosshair (5 styles)
local function drawCrosshair()
    if not Flags.CustomCrosshair then return end
    local size = Flags.CrosshairSize or 5
    local gap = Flags.CrosshairGap or 2
    local thick = Flags.CrosshairThick or 1
    local style = Flags.CrosshairStyle or "Plus"
    local cx = workspace.CurrentCamera.ViewportSize.X * 0.5
    local cy = workspace.CurrentCamera.ViewportSize.Y * 0.5
    local cc = C_GREEN

    if style == "Plus" then
        local l1=poolLine(); l1.From=v2(cx-size-gap,cy); l1.To=v2(cx-gap,cy); l1.Color=cc; l1.Thickness=thick; l1.Visible=true
        local l2=poolLine(); l2.From=v2(cx+gap,cy); l2.To=v2(cx+size+gap,cy); l2.Color=cc; l2.Thickness=thick; l2.Visible=true
        local l3=poolLine(); l3.From=v2(cx,cy-size-gap); l3.To=v2(cx,cy-gap); l3.Color=cc; l3.Thickness=thick; l3.Visible=true
        local l4=poolLine(); l4.From=v2(cx,cy+gap); l4.To=v2(cx,cy+size+gap); l4.Color=cc; l4.Thickness=thick; l4.Visible=true
    elseif style == "Circle" then
        local c=poolCircle(); c.Position=v2(cx,cy); c.Radius=size+gap; c.Color=cc; c.Thickness=thick; c.Filled=false; c.Visible=true
    elseif style == "Triangle" then
        local l1=poolLine(); l1.From=v2(cx,cy-gap); l1.To=v2(cx-size,cy+size); l1.Color=cc; l1.Thickness=thick; l1.Visible=true
        local l2=poolLine(); l2.From=v2(cx-size,cy+size); l2.To=v2(cx+size,cy+size); l2.Color=cc; l2.Thickness=thick; l2.Visible=true
        local l3=poolLine(); l3.From=v2(cx+size,cy+size); l3.To=v2(cx,cy-gap); l3.Color=cc; l3.Thickness=thick; l3.Visible=true
    elseif style == "Diamond" then
        local l1=poolLine(); l1.From=v2(cx,cy-gap-size); l1.To=v2(cx+size+gap,cy); l1.Color=cc; l1.Thickness=thick; l1.Visible=true
        local l2=poolLine(); l2.From=v2(cx+size+gap,cy); l2.To=v2(cx,cy+size+gap); l2.Color=cc; l2.Thickness=thick; l2.Visible=true
        local l3=poolLine(); l3.From=v2(cx,cy+size+gap); l3.To=v2(cx-size-gap,cy); l3.Color=cc; l3.Thickness=thick; l3.Visible=true
        local l4=poolLine(); l4.From=v2(cx-size-gap,cy); l4.To=v2(cx,cy-size-gap); l4.Color=cc; l4.Thickness=thick; l4.Visible=true
    elseif style == "T-Shape" then
        local l1=poolLine(); l1.From=v2(cx-size-gap,cy); l1.To=v2(cx+size+gap,cy); l1.Color=cc; l1.Thickness=thick; l1.Visible=true
        local l2=poolLine(); l2.From=v2(cx,cy); l2.To=v2(cx,cy+size+gap); l2.Color=cc; l2.Thickness=thick; l2.Visible=true
    end
    -- Outline
    if Flags.CrosshairOutline then
        local olSize = Flags.CrosshairOLSize or 2
        local oc = RGB(0,0,0)
        if style == "Circle" then
            local c=poolCircle(); c.Position=v2(cx,cy); c.Radius=size+gap; c.Color=oc; c.Thickness=thick+olSize*2; c.Filled=false; c.Visible=true
        else
            local l1=poolLine(); l1.From=v2(cx-size-gap-olSize,cy-olSize); l1.To=v2(cx+size+gap+olSize,cy+olSize); l1.Color=oc; l1.Thickness=thick+olSize*2; l1.Visible=true
        end
    end
    -- Center dot
    if Flags.CrosshairDot then
        local dot=poolCircle(); dot.Position=v2(cx,cy); dot.Radius=1.5; dot.Color=cc; dot.Filled=true; dot.Visible=true
    end
end

 -- Bomb ESP
local bombFrame = 0
local function drawBombESP()
    if not Flags.ESP_Bomb then return end
    bombFrame = bombFrame + 1
    if bombFrame % 10 ~= 0 then return end
    local bomb = BS.api and BS.api.getBomb and BS.api.getBomb()
    if not bomb then return end
    local pos, vis = w2s(workspace.CurrentCamera, bomb.Position)
    if not vis then return end
    local t=poolText(); t.Position=v2(pos.X,pos.Y-20); t.Text=" C4"; t.Color=C_BOMB; t.Size=16; t.Visible=true
    if Flags.ESP_BombTimer then
        local timer = BS.api.getBombTimer and BS.api.getBombTimer() or 40
        local t2=poolText(); t2.Position=v2(pos.X,pos.Y); t2.Text=string.format("%.1fs",timer); t2.Color=timer<10 and C_RED or C_YELLOW; t2.Size=14; t2.Visible=true
    end
    if Flags.ESP_BombDist then
        local myHrp = BS.hrp and BS.hrp()
        if myHrp then
            local d = mFloor((myHrp.Position - bomb.Position).Magnitude)
            local t3=poolText(); t3.Position=v2(pos.X,pos.Y+15); t3.Text=d.."m"; t3.Color=C_GREY; t3.Size=11; t3.Visible=true
        end
    end
end

 -- Grenade Line (trajectory preview)
local function drawGrenadeESP()
    if not Flags.ESP_Grenade then return end
    -- Scan for grenade objects in workspace
    pcall(function()
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj.Name:find("Grenade") or obj.Name:find("Flash") or obj.Name:find("Smoke") or obj.Name:find("Molotov") then
                local pos, vis = w2s(workspace.CurrentCamera, obj.Position)
                if vis then
                    local label = ""
                    if obj.Name:find("Flash") then label = ""
                    elseif obj.Name:find("Smoke") then label = ""
                    elseif obj.Name:find("Molotov") then label = "" end
                    local t=poolText(); t.Position=v2(pos.X,pos.Y-15); t.Text=label.." "..obj.Name; t.Color=C_YELLOW; t.Size=12; t.Visible=true
                    if Flags.ESP_GrenadeLine then
                        local myHrp = BS.hrp and BS.hrp()
                        if myHrp then
                            local p1,v1 = w2s(workspace.CurrentCamera, myHrp.Position)
                            if v1 then local l=poolLine(); l.From=v2(p1.X,p1.Y); l.To=v2(pos.X,pos.Y); l.Color=C_ORANGE; l.Thickness=1; l.Visible=true end
                        end
                    end
                end
            end
        end
    end)
end

 -- Radar ESP
local radarGui = nil
local function updateRadar()
    if not Flags.ESP_Radar then
        if radarGui then radarGui.Enabled = false end; return
    end
    local rSize = Flags.ESP_RadarSize or 150
    local rRange = Flags.ESP_RadarRange or 200
    local rX, rY = 50, workspace.CurrentCamera.ViewportSize.Y - rSize - 50

    if not radarGui then
        radarGui = Instance.new("ScreenGui"); radarGui.Name="BS_Radar"; radarGui.IgnoreGuiInset=true; radarGui.DisplayOrder=9998; radarGui.Parent=lplr.PlayerGui
    end
    radarGui.Enabled = true
    -- radarGui:ClearAllChildren()

    -- Background
    local bg = Instance.new("Frame"); bg.Size=UDim2.new(0,rSize,0,rSize); bg.Position=UDim2.new(0,rX,0,rY); bg.BackgroundColor3=RGB(0,0,0); bg.BackgroundTransparency=0.3; bg.BorderSizePixel=1; bg.BorderColor3=RGB(100,100,100); bg.Parent=radarGui
    Instance.new("UICorner",bg).CornerRadius=UDim.new(0,4)
    -- Crosshair
    local ch1=Instance.new("Frame"); ch1.Size=UDim2.new(1,0,0,1); ch1.Position=UDim2.new(0,0,0.5,0); ch1.BackgroundColor3=RGB(80,80,80); ch1.BorderSizePixel=0; ch1.Parent=bg
    local ch2=Instance.new("Frame"); ch2.Size=UDim2.new(0,1,1,0); ch2.Position=UDim2.new(0.5,0,0,0); ch2.BackgroundColor3=RGB(80,80,80); ch2.BorderSizePixel=0; ch2.Parent=bg

    local myPos = BS.hrp and BS.hrp() and BS.hrp and BS.hrp().Position or V3_ZERO
    local myTeam = BS.team()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == lplr then continue end
        local char = player.Character; if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart"); local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then continue end
        local relPos = hrp.Position - myPos
        local rx = relPos.X / rRange * (rSize * 0.5) + rSize * 0.5
        local ry = relPos.Z / rRange * (rSize * 0.5) + rSize * 0.5
        if rx < 0 or rx > rSize or ry < 0 or ry > rSize then continue end
        local dotColor = C_RED
        if Flags.ESP_TeamCheck and myTeam and player.Team == myTeam then dotColor = C_BLUE end
        local dot=Instance.new("Frame"); dot.Size=UDim2.new(0,5,0,5); dot.Position=UDim2.new(0,rx-2.5,0,ry-2.5); dot.BackgroundColor3=dotColor; dot.BorderSizePixel=0; dot.Parent=bg
        Instance.new("UICorner",dot).CornerRadius=UDim.new(0,5)
        -- ::continue::
    end
end

 -- Compass 
local compassGui = nil
local function updateCompass()
    if not Flags.ESP_Compass then
        if compassGui then compassGui.Enabled = false end; return
    end
    if not compassGui then
        compassGui = Instance.new("ScreenGui"); compassGui.Name="BS_Compass"; compassGui.IgnoreGuiInset=true; compassGui.DisplayOrder=9998; compassGui.Parent=lplr.PlayerGui
        local f=Instance.new("Frame",compassGui); f.Size=UDim2.new(0,300,0,20); f.Position=UDim2.new(0.5,-150,0,40); f.BackgroundColor3=RGB(0,0,0); f.BackgroundTransparency=0.4; f.BorderSizePixel=0; f.Parent=compassGui
        Instance.new("UICorner",f).CornerRadius=UDim.new(0,4)
        for i=1,5 do
            local lbl=Instance.new("TextLabel",f); lbl.Name="D"..i; lbl.Size=UDim2.new(0,50,1,0); lbl.Position=UDim2.new(0,(i-1)*60,0,0); lbl.BackgroundTransparency=1; lbl.TextColor3=C_GREY; lbl.TextSize=11; lbl.Font=Enum.Font.Code; lbl.TextXAlignment=Enum.TextXAlignment.Center
        end
    end
    compassGui.Enabled = true
    local yaw = workspace.CurrentCamera.CFrame and workspace.CurrentCamera.CFrame:ToEulerAnglesYXZ() or 0
    local deg = mFloor(mDeg(yaw))
    local dirs = {"W","NW","N","NE","E","SE","S","SW"}
    for i = 1, 5 do
        local idx = ((deg + (i-3) * 45) % 360) / 45 + 1
        local dirIdx = mFloor(idx + 0.5) % 8 + 1
        local lbl = compassGui.Frame:FindFirstChild("D"..i)
        if lbl then
            lbl.Text = dirs[dirIdx]
            lbl.TextColor3 = (i == 3) and C_WHITE or C_GREY
        end
    end
end

 -- GUI Overlays
local wmGui, stGui, fpGui = nil, nil, nil

local function updateWatermark()
    if not Flags.ESP_Watermark then if wmGui then wmGui.Enabled=false end; return end
    if not wmGui then
        wmGui = Instance.new("ScreenGui"); wmGui.Name="BS_WM"; wmGui.IgnoreGuiInset=true; wmGui.DisplayOrder=9999; wmGui.Parent=lplr.PlayerGui
        local f=Instance.new("Frame",wmGui); f.Size=UDim2.new(0,280,0,30); f.Position=UDim2.new(0,10,0,10); f.BackgroundColor3=RGB(0,0,0); f.BackgroundTransparency=0.3; f.BorderSizePixel=0
        Instance.new("UICorner",f).CornerRadius=UDim.new(0,6)
        local t=Instance.new("TextLabel",f); t.Name="T"; t.Size=UDim2.new(1,-10,1,0); t.Position=UDim2.new(0,5,0,0); t.BackgroundTransparency=1; t.TextColor3=C_CYAN; t.TextSize=12; t.Font=Enum.Font.Code; t.TextXAlignment=Enum.TextXAlignment.Left
    end
    wmGui.Enabled = true
    local lbl = wmGui.Frame.T
    if lbl then lbl.Text = string.format(" BloxStrike | %d FPS | %dms | %d Players", BS.Perf and BS.Perf.FPS or 0, BS.Ping and BS.Ping.Current or 0, #Players:GetPlayers()) end
end

local function updateStatus()
    if not Flags.ESP_Status then if stGui then stGui.Enabled=false end; return end
    if not stGui then
        stGui = Instance.new("ScreenGui"); stGui.Name="BS_ST"; stGui.IgnoreGuiInset=true; stGui.DisplayOrder=9999; stGui.Parent=lplr.PlayerGui
        local f=Instance.new("Frame",stGui); f.Size=UDim2.new(0,200,0,110); f.Position=UDim2.new(1,-210,0,10); f.BackgroundColor3=RGB(0,0,0); f.BackgroundTransparency=0.3; f.BorderSizePixel=0
        Instance.new("UICorner",f).CornerRadius=UDim.new(0,6)
        for i=1,5 do
            local lbl=Instance.new("TextLabel",f); lbl.Name="L"..i; lbl.Size=UDim2.new(1,-10,0,18); lbl.Position=UDim2.new(0,5,0,(i-1)*20); lbl.BackgroundTransparency=1; lbl.TextColor3=C_GREY; lbl.TextSize=10; lbl.Font=Enum.Font.Code; lbl.TextXAlignment=Enum.TextXAlignment.Left
        end
    end
    stGui.Enabled = true
    local risk = BS.Stealth and BS.Stealth.RiskLevel or 0
    stGui.Frame.L1.Text = "Risk: "..risk.."%"; stGui.Frame.L1.TextColor3 = risk>70 and C_RED or C_GREEN
    stGui.Frame.L2.Text = "Mode: "..(Flags.Ragebot and "Rage" or Flags.SilentAim and "Silent" or "Legit")
    stGui.Frame.L3.Text = "Ping: "..(BS.Ping and BS.Ping.Current or 0).."ms"
    stGui.Frame.L4.Text = "FPS: "..(BS.Perf and BS.Perf.FPS or 0)
    local active = 0; for _,v in pairs(Flags) do if v==true then active=active+1 end end
    stGui.Frame.L5.Text = "Active: "..active.." features"
end

local function updateFPS()
    if not Flags.ESP_FPS then if fpGui then fpGui.Enabled=false end; return end
    if not fpGui then
        fpGui = Instance.new("ScreenGui"); fpGui.Name="BS_FPS"; fpGui.IgnoreGuiInset=true; fpGui.DisplayOrder=9999; fpGui.Parent=lplr.PlayerGui
        local lbl=Instance.new("TextLabel",fpGui); lbl.Size=UDim2.new(0,120,0,20); lbl.Position=UDim2.new(0.5,-60,0,5); lbl.BackgroundTransparency=1; lbl.TextColor3=C_GREEN; lbl.TextSize=14; lbl.Font=Enum.Font.Code; lbl.Text="FPS: 0"
    end
    fpGui.Enabled = true
    local lbl = fpGui:FindFirstChildOfClass("TextLabel")
    if lbl then lbl.Text = "FPS: "..(BS.Perf and BS.Perf.FPS or 0) end
end

local dispFrame = 0

-- MAIN RENDER LOOP  Single RenderStepped, zero delay

RunService.RenderStepped:Connect(function()
    if not BS.alive and BS.alive() then return end

    -- Ping Adapt: skip frames on high ping for performance
    local skipFrames = 1
    if Flags.PingAdapt and BS.PA then
        skipFrames = BS.PA.getAdaptESPSkip()
    end
    if skipFrames > 1 and (dispFrame % skipFrames) ~= 0 then
        -- return
    end

    resetPool()

    local myHrp = BS.hrp and BS.hrp()
    local myTeam = BS.team()
    local cam = workspace.CurrentCamera
    local thick = Flags.ESP_BoxThick or 1
    dispFrame = dispFrame + 1

    -- Collect players with distance for sorting
    local playerData = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player == lplr then continue end
        local char = player.Character; if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then continue end
        if Flags.ESP_TeamCheck and myTeam and player.Team == myTeam then continue end
        local dist = myHrp and (myHrp.Position - hrp.Position).Magnitude or 9999
        if Flags.ESP_DistLimit and dist > (Flags.ESP_MaxDist or 200) then continue end
        table.insert(playerData, {player=player, hrp=hrp, hum=hum, dist=dist})
        -- ::skip::
    end

    -- Sort by distance if enabled
    if Flags.ESP_SortDist then
        table.sort(playerData, function(a,b) return a.dist < b.dist end)
    end

    -- Draw player ESP
    for _, pd in ipairs(playerData) do
        local espColor = getESPColor(pd.player, pd.hum, pd.dist)

        -- Box
        if Flags.ESP_Box then
            local style = Flags.ESPBoxStyle or "2D"
            if style == "2D" then drawBox2D(pd.hrp, espColor, thick)
            elseif style == "Corners" then drawCornerBox(pd.hrp, espColor, thick)
            elseif style == "3D" then draw3DBox(pd.hrp, espColor, thick)
            elseif style == "Filled Box" then drawFilledBox(pd.hrp, espColor, thick)
            elseif style == "Full Box" then drawFullBox(pd.hrp, espColor, thick) end
        end
        if Flags.ESP_Health then drawHealthBar(pd.hrp, pd.hum, espColor) end
        if Flags.ESP_Armor then drawArmorBar(pd.hrp, pd.player) end
        if Flags.ESP_Name then drawName(pd.player, pd.hrp, espColor) end
        if Flags.ESP_Dist then drawDistance(pd.hrp, espColor) end
        if Flags.ESP_Tracer then drawTracer(pd.hrp, espColor) end
        if Flags.ESP_HeadDot then drawHeadDot(pd.hrp) end
        if Flags.ESP_Weapon then drawWeapon(pd.player, pd.hrp, espColor) end
        if Flags.ESP_Snaplines then drawSnapline(pd.hrp, espColor) end
        if Flags.ESP_Skeleton then drawSkeleton(pd.player, espColor) end
        if Flags.ESP_Target then drawTargetESP(pd.player, pd.hrp) end
        if Flags.ESP_HeadHit then drawHeadHitbox(pd.hrp, espColor) end
        if Flags.ESP_Barrel then drawBarrel(pd.hrp, espColor) end
        if Flags.ESP_OOF then drawOOF(pd.player, pd.hrp, espColor) end
        if Flags.ESP_Arrow then drawOffScreenArrow(pd.player, pd.hrp, espColor) end
        if Flags.ESP_Headshot then drawHeadshotIcon(pd.hrp, espColor) end
        if Flags.ESP_Velocity then drawVelocityArrow(pd.hrp, espColor) end
        if Flags.ESP_LaserLine then drawLaserLine(pd.player, pd.hrp, espColor) end
        if Flags.ESP_InfoCard then drawInfoCard(pd.player, pd.hrp, pd.hum, espColor, pd.dist) end

        -- Chams
        if Flags.Chams then
            pcall(function()
                for _, part in ipairs(pd.player.Character:GetDescendants()) do
                    if part:IsA("BasePart") and not part:FindFirstChild("BS_Chams") then
                        local sg = Instance.new("SurfaceGui"); sg.Name="BS_Chams"; sg.Face=Enum.NormalId.Front; sg.Parent=part
                        local fr = Instance.new("Frame",sg); fr.Size=UDim2.new(1,0,1,0); fr.BackgroundColor3=espColor; fr.BackgroundTransparency=0.6
                    end
                end
            end)
        end

        -- Glow
        if Flags.ESP_Glow then
            pcall(function()
                local hl = pd.player and player.Character:FindFirstChild("BS_Glow")
                if not hl then
                    hl = Instance.new("Highlight"); hl.Name="BS_Glow"; hl.FillColor=espColor; hl.OutlineColor=espColor
                    hl.FillTransparency=(Flags.ESP_GlowT or 50)/100; hl.OutlineTransparency=0; hl.Parent=pd.player.Character
                end
            end)
        else
            pcall(function() local hl=pd.player and player.Character:FindFirstChild("BS_Glow"); if hl then hl:Destroy() end end)
        end
    end

    -- World ESP
    drawBombESP()
    drawGrenadeESP()

    -- Overlays (throttled)
    if dispFrame % 6 == 0 then
        updateWatermark()
        updateStatus()
        updateFPS()
        updateRadar()
        updateCompass()
    end

    drawCrosshair()
    updateFOVCircle()

    hideUnused()
end)

-- THIRD PERSON ENGINE

local lplrLocal = game:GetService("Players").LocalPlayer

local tpState = {
    currentDist = 12,
    targetDist = 12,
    shoulderSide = 1,
    cameraAngle = 0,
    verticalAngle = 0,
}

-- Scroll Wheel Zoom
if UIS then pcall(function() UIS.InputChanged:Connect(function(input)
    if not Flags.ThirdPerson then return end
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        tpState.targetDist = math.clamp(tpState.targetDist - input.Position.Z * 2, 2, 30)
    end
end) end) end

-- V Key: Switch Shoulder / C Key: Reset
if UIS then pcall(function() UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if not Flags.ThirdPerson then return end
    if input.KeyCode == Enum.KeyCode.V then
        tpState.shoulderSide = tpState.shoulderSide * -1
    end
    if input.KeyCode == Enum.KeyCode.C then
        tpState.targetDist = Flags.TPDistance or 12
        tpState.verticalAngle = 0
    end
end) end) end

-- Third Person Render
RunService.RenderStepped:Connect(function(dt)
    pcall(function()
        local cam = workspace.CurrentCamera
        local hrp = BS.hrp and BS.hrp()
        if not cam or not hrp then return end

        if Flags.ThirdPerson then
            local smooth = (Flags.TPSmooth or 5) / 10
            tpState.currentDist = tpState.currentDist + (tpState.targetDist - tpState.currentDist) * smooth

            local shoulder = Flags.TPShoulderOffset or 3
            if Flags.TPShoulder == "Left" then
                tpState.shoulderSide = -1
            elseif Flags.TPShoulder == "Right" then
                tpState.shoulderSide = 1
            else
                shoulder = 0
            end

            local lookDir = cam.CFrame.LookVector
            local rightDir = cam.CFrame.RightVector
            local height = Flags.TPHeight or 2
            local basePos = hrp.Position + Vector3.new(0, height, 0)
            local shoulderOffset = rightDir * shoulder * tpState.shoulderSide
            local camPos = basePos - lookDir * tpState.currentDist + shoulderOffset

            -- Collision Check
            if Flags.TPCollision then
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = {lplrLocal.Character}
                local result = workspace:Raycast(basePos, camPos - basePos, params)
                if result then
                    camPos = result.Position + (basePos - result.Position).Unit * 0.5
                end
            end

            -- Look Target
            local lookTarget = basePos
            if Flags.TPHeadFollow then
                local head = hrp.Parent:FindFirstChild("Head")
                if head then
                    lookTarget = head.Position + lookDir * 5
                end
            end

            -- Apply Camera
            if Flags.TPSmoothLook then
                local targetCF = CFrame.new(camPos, lookTarget)
                cam.CFrame = cam.CFrame:Lerp(targetCF, smooth)
            else
                cam.CFrame = CFrame.new(camPos, lookTarget)
            end

            -- FOV
            if Flags.TPFOV then
                local targetFOV = Flags.TPFOV
                if Flags.TPAutoZoom then
                    local tool = BS.tool()
                    local isScoped = tool and (tool.Name:lower():find("awp") or tool.Name:lower():find("sniper"))
                    if isScoped then targetFOV = 30 end
                end
                cam.FieldOfView = cam.FieldOfView + (targetFOV - cam.FieldOfView) * smooth
            end

            -- Make character slightly transparent
            local char = lplrLocal.Character
            if char then
                local head = char:FindFirstChild("Head")
                if head then head.Transparency = 0.5 end
                local hrpChar = char:FindFirstChild("HumanoidRootPart")
                if hrpChar then hrpChar.Transparency = 0.8 end
            end
        else
            -- Restore transparency
            local char = lplrLocal.Character
            if char then
                local head = char:FindFirstChild("Head")
                if head and head.Transparency > 0 then head.Transparency = 0 end
                local hrpChar = char:FindFirstChild("HumanoidRootPart")
                if hrpChar and hrpChar.Transparency > 0 then hrpChar.Transparency = 0 end
            end
        end
    end)
end)

-- Cleanup
lplr.CharacterRemoving:Connect(function()
    for i=1, PMax.L do pcall(function() LinePool[i].Visible=false end) end
    for i=1, PMax.T do pcall(function() TextPool[i].Visible=false end) end
    for i=1, PMax.S do pcall(function() SquarePool[i].Visible=false end) end
    for i=1, PMax.C do pcall(function() CirclePool[i].Visible=false end) end
end)


-- ═══════════════════════════════════════════════════════════════
-- CONTAINER ESP (Crates, Supplies, Loot)
-- ═══════════════════════════════════════════════════════════════
local containerTypes = {"SpawnLocation", "Seat", "VehicleSeat"}
local ContainerESP = {}
BS.ContainerESP = ContainerESP

function ContainerESP:Update()
    if not Flags.ContainerESP then return end
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (obj.Name:lower():find("crate") or obj.Name:lower():find("loot") or obj.Name:lower():find("supply") or obj.Name:lower():find("chest")) then
                local hrp = BS.hrp and BS.hrp()
                if hrp then
                    local dist = (hrp.Position - obj.Position).Magnitude
                    if dist < (Flags.ContainerESPRange or 200) then
                        local sp, vis = cam:WorldToViewportPoint(obj.Position)
                        if vis then
                            local t = poolText()
                            t.Position = v2(sp.X, sp.Y)
                            t.Text = obj.Name .. " [" .. math.floor(dist) .. "m]"
                            t.Color = Color3.fromRGB(255, 200, 0)
                            t.Size = 10
                            t.Center = true
                            t.Visible = true
                        end
                    end
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- VEHICLE ESP
-- ═══════════════════════════════════════════════════════════════
local VehicleESP = {}
BS.VehicleESP = VehicleESP

function VehicleESP:Update()
    if not Flags.VehicleESP then return end
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("VehicleSeat") or obj:IsA("Seat") then
                local hrp = BS.hrp and BS.hrp()
                if hrp then
                    local dist = (hrp.Position - obj.Position).Magnitude
                    if dist < (Flags.VehicleESPRange or 300) then
                        local sp, vis = cam:WorldToViewportPoint(obj.Position)
                        if vis then
                            local t = poolText()
                            t.Position = v2(sp.X, sp.Y)
                            t.Text = "Vehicle [" .. math.floor(dist) .. "m]"
                            t.Color = Color3.fromRGB(0, 200, 255)
                            t.Size = 10
                            t.Center = true
                            t.Visible = true
                        end
                    end
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- PREDICTION LINE (Show where enemy is moving)
-- ═══════════════════════════════════════════════════════════════
local predictionLines = {}
BS.PredictionESP = {Lines = predictionLines}

function BS.PredictionESP:Update()
    if not Flags.PredictionLine then
        for _, line in pairs(predictionLines) do
            if line then line.Visible = false end
        end
        return
    end
    pcall(function()
        for uid, line in pairs(predictionLines) do
            if line then line.Visible = false end
        end
        local enemies = BS.GetEnemies and BS.GetEnemies() or {}
        for _, e in ipairs(enemies) do
            if e and e.HRP and e.Player then
                local vel = e.HRP.AssemblyLinearVelocity
                if vel.Magnitude > 1 then
                    local futurePos = e.HRP.Position + vel * (Flags.PredictionTime or 0.3)
                    local sp, vis = cam:WorldToViewportPoint(futurePos)
                    if vis then
                        local line = poolLine()
                        local sp2 = cam:WorldToViewportPoint(e.HRP.Position)
                        line.From = v2(sp2.X, sp2.Y)
                        line.To = v2(sp.X, sp.Y)
                        line.Color = Color3.fromRGB(255, 100, 0)
                        line.Thickness = 1
                        line.Visible = true
                        predictionLines[e.Player.UserId] = line
                    end
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- HEADSHOT LINE (Line from enemy head to crosshair)
-- ═══════════════════════════════════════════════════════════════
local hsLines = {}

function BS.UpdateHeadshotLines()
    if not Flags.HeadshotLine then
        for _, line in pairs(hsLines) do
            if line then line.Visible = false end
        end
        return
    end
    pcall(function()
        for uid, line in pairs(hsLines) do
            if line then line.Visible = false end
        end
        local screenCenter = cam.ViewportSize / 2
        local enemies = BS.GetEnemies and BS.GetEnemies() or {}
        for _, e in ipairs(enemies) do
            if e and e.HRP and e.Head and e.Player then
                local headPos = e.Head.Position
                local sp, vis = cam:WorldToViewportPoint(headPos)
                if vis then
                    local line = poolLine()
                    line.From = v2(sp.X, sp.Y)
                    line.To = v2(screenCenter.X, screenCenter.Y)
                    line.Color = Color3.fromRGB(255, 0, 0)
                    line.Thickness = 1
                    line.Transparency = 0.5
                    line.Visible = true
                    hsLines[e.Player.UserId] = line
                end
            end
        end
    end)
end

-- GUI
E:Label(" World ESP ")
E:Toggle("容器透視", false, function(v) Flags.ContainerESP = v end)
E:Slider("Container Range", 50, 500, 200, function(v) Flags.ContainerESPRange = v end)
E:Toggle("載具透視", false, function(v) Flags.VehicleESP = v end)
E:Slider("Vehicle Range", 50, 500, 300, function(v) Flags.VehicleESPRange = v end)
E:Separator()
E:Label(" Prediction ")
E:Toggle("預測線", false, function(v) Flags.PredictionLine = v end)
E:Slider("Predict Time", 10, 50, 30, function(v) Flags.PredictionTime = v / 100 end)
E:Toggle("爆頭線", false, function(v) Flags.HeadshotLine = v end)

print("[ESP] BloxStrike ESP v3.0 loaded  "..(PMax.L + PMax.T + PMax.S + PMax.C).." pool objects ready")
