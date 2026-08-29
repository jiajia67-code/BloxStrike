--!nocheck
-- ══════════════════════════════════════════════════════════════
-- MOVEMENT MODULE v5.1 — Advanced Personal Movement
-- ══════════════════════════════════════════════════════════════
local M = BW.Win:Tab("Move")
if not M or not M.Toggle then warn("[Move] Failed to create tab!") return end

-- ═══ Basic Movement ═══
M:Toggle("Speed", false, function(v) Flags.Speed = v end)
M:Slider("Speed Value", 16, 100, 32, function(v) Flags.SpeedVal = v end)
M:Toggle("Fly", false, function(v) Flags.Fly = v end)
M:Slider("Fly Speed", 1, 30, 8, function(v) Flags.FlySpeed = v end)
M:Toggle("Long Jump", false, function(v) Flags.LongJump = v end)
M:Slider("LJ Power", 30, 100, 50, function(v) Flags.LJPower = v end)
M:Toggle("High Jump", false, function(v) Flags.HighJump = v end)
M:Slider("Jump Power", 50, 200, 100, function(v) Flags.JumpPower = v end)
M:Toggle("Inf Jump", false, function(v) Flags.InfJump = v end)
M:Toggle("NoClip", false, function(v) Flags.NoClip = v end)
M:Toggle("Anti Void", false, function(v) Flags.AntiVoid = v end)
M:Toggle("Phase", false, function(v) Flags.Phase = v end)

-- ═══ Advanced Movement ═══
M:Toggle("Invisible", false, function(v) Flags.Invisible = v end)
M:Slider("Invis Level", 1, 10, 5, function(v) Flags.InvisLevel = v end)
M:Toggle("MouseTP", false, function(v) Flags.MouseTP = v end)
M:Toggle("NoSlowdown", false, function(v) Flags.NoSlowdown = v end)
M:Toggle("Spider", false, function(v) Flags.Spider = v end)
M:Toggle("Swim", false, function(v) Flags.Swim = v end)
M:Toggle("Gravity", false, function(v) Flags.Gravity = v end)
M:Slider("Gravity Value", 0, 200, 100, function(v) Flags.GravVal = v end)
M:Toggle("Spin Bot", false, function(v) Flags.SpinBot = v end)
M:Slider("Spin Speed", 1, 30, 10, function(v) Flags.SpinSpeed = v end)

-- ═══ NEW: Advanced Features ═══
M:Toggle("Auto Jump", false, function(v) Flags.AutoJump = v end)
M:Slider("Auto Jump Delay", 100, 1000, 300, function(v) Flags.AutoJumpDelay = v end)
M:Toggle("Bhop", false, function(v) Flags.Bhop = v end)
M:Slider("Bhop Speed", 16, 50, 32, function(v) Flags.BhopSpeed = v end)
M:Toggle("Strafe", false, function(v) Flags.StrafeMove = v end)
M:Slider("Strafe Speed", 1, 10, 5, function(v) Flags.StrafeSpeed = v end)
M:Toggle("Edge Jump", false, function(v) Flags.EdgeJump = v end)
M:Toggle("Safe Fall", false, function(v) Flags.SafeFall = v end)
M:Toggle("Auto Walk", false, function(v) Flags.AutoWalk = v end)
M:Slider("Walk Target Range", 10, 100, 30, function(v) Flags.WalkRange = v end)
M:Toggle("No Fall Damage", false, function(v) Flags.NoFallDmg = v end)
M:Toggle("Fast Climb", false, function(v) Flags.FastClimb = v end)
M:Toggle("Water Speed", false, function(v) Flags.WaterSpeed = v end)
M:Slider("Water Speed Val", 16, 50, 30, function(v) Flags.WaterSpeedVal = v end)
M:Toggle("Land Factor", false, function(v) Flags.LandFactor = v end)
M:Slider("Land Factor Val", 1, 10, 3, function(v) Flags.LandFactorVal = v end)

-- ═══ ENGINES ═══
local flyBV = nil
local lastSafePos = nil

-- Consolidated movement loop
task.spawn(function()
    while true do
        local h = BW.hum()
        local my = BW.hrp()
        if h and my then
            -- Speed
            if Flags.Speed then h.WalkSpeed = Flags.SpeedVal or 32
            elseif not Flags.Bhop and h.WalkSpeed > 16 then h.WalkSpeed = 16 end
            -- High Jump
            if Flags.HighJump then h.JumpPower = Flags.JumpPower or 100 end
            -- Fly
            if Flags.Fly then
                if not flyBV then flyBV=Instance.new("BodyVelocity"); flyBV.Name="_BW_Fly"; flyBV.MaxForce=Vector3.new(math.huge,math.huge,math.huge); flyBV.P=10000; flyBV.Parent=my end
                flyBV.Velocity=Vector3.new(0,0,0)
                local sp=Flags.FlySpeed or 8; local cam=BW.Camera.CFrame
                if BW.UserInputService:IsKeyDown(Enum.KeyCode.W) then flyBV.Velocity=flyBV.Velocity+cam.LookVector*sp end
                if BW.UserInputService:IsKeyDown(Enum.KeyCode.S) then flyBV.Velocity=flyBV.Velocity-cam.LookVector*sp end
                if BW.UserInputService:IsKeyDown(Enum.KeyCode.A) then flyBV.Velocity=flyBV.Velocity-cam.RightVector*sp end
                if BW.UserInputService:IsKeyDown(Enum.KeyCode.D) then flyBV.Velocity=flyBV.Velocity+cam.RightVector*sp end
                if BW.UserInputService:IsKeyDown(Enum.KeyCode.Space) then flyBV.Velocity=flyBV.Velocity+Vector3.new(0,sp,0) end
                if BW.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then flyBV.Velocity=flyBV.Velocity-Vector3.new(0,sp,0) end
            else if flyBV then flyBV:Destroy(); flyBV=nil end end
            -- NoClip
            if Flags.NoClip then for _, p in pairs(BW.char():GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end
            -- Anti Void
            if Flags.AntiVoid then
                local pos=my.Position
                if pos.Y>0 then lastSafePos=pos end
                if pos.Y<-50 and lastSafePos then my.CFrame=CFrame.new(lastSafePos) end
            end
            -- Gravity
            if Flags.Gravity then BW.Workspace.Gravity=Flags.GravVal or 100
            elseif BW.Workspace.Gravity~=196.2 then BW.Workspace.Gravity=196.2 end
            -- Swim
            if Flags.Swim then h:ChangeState(Enum.HumanoidStateType.Swimming) end
            -- Phase
            if Flags.Phase then h.PlatformStand=true; task.wait(0.1); h.PlatformStand=false end
            -- Invisible
            if Flags.Invisible then
                local lv=(Flags.InvisLevel or 5)/10
                for _, p in pairs(BW.char():GetDescendants()) do
                    if p:IsA("BasePart") then p.Transparency=lv
                    elseif p:IsA("Decal") then p.Transparency=lv end
                end
            end
            -- No Slowdown
            if Flags.NoSlowdown then
                h.WalkSpeed = Flags.Speed and (Flags.SpeedVal or 32) or 16
            end
            -- Fast Climb
            if Flags.FastClimb then
                h.ClimbSpeed = 50
            end
            -- Water Speed
            if Flags.WaterSpeed then
                -- Increase speed when in water
                if h:GetState() == Enum.HumanoidStateType.Swimming then
                    h.WalkSpeed = Flags.WaterSpeedVal or 30
                end
            end
        end
        task.wait(0.05)
    end
end)

-- Long Jump
task.spawn(function()
    while true do
        if Flags.LongJump and BW.alive() then
            local h=BW.hum(); local my=BW.hrp()
            if h and my and h:GetState()==Enum.HumanoidStateType.Freefall then
                local p=Flags.LJPower or 50; local v=my.Velocity
                my.Velocity=Vector3.new(v.X*p/50,40,v.Z*p/50)
            end
        end
        task.wait(0.1)
    end
end)

-- Inf Jump
BW.UserInputService.JumpRequest:Connect(function()
    if Flags.InfJump and BW.alive() then local h=BW.hum() if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)

-- MouseTP
BW.UserInputService.InputBegan:Connect(function(input,gp)
    if gp then return end
    if Flags.MouseTP and input.UserInputType==Enum.UserInputType.MouseButton2 then
        local mouse=BW.LocalPlayer:GetMouse()
        if mouse and mouse.Hit then local my=BW.hrp() if my then my.CFrame=CFrame.new(mouse.Hit.Position+Vector3.new(0,3,0)) end end
    end
end)

-- Spider
task.spawn(function()
    while true do
        if Flags.Spider and BW.alive() then
            local my=BW.hrp(); local h=BW.hum()
            if my and h then
                local rp=RaycastParams.new(); rp.FilterDescendantsInstances={BW.char()}; rp.FilterType=Enum.RaycastFilterType.Exclude
                local r=BW.Workspace:Raycast(my.Position,my.CFrame.LookVector*2,rp)
                if r then h.WalkSpeed=0; my.Velocity=Vector3.new(0,30,0)
                else h.WalkSpeed=Flags.Speed and (Flags.SpeedVal or 32) or 16 end
            end
        end
        task.wait(0.05)
    end
end)

-- Spin Bot
task.spawn(function()
    local angle=0
    while true do
        if Flags.SpinBot and BW.alive() then
            local my=BW.hrp()
            if my then angle=angle+(Flags.SpinSpeed or 10); if angle>=360 then angle=angle-360 end
            my.CFrame=CFrame.new(my.Position)*CFrame.Angles(0,math.rad(angle),0) end
        end
        task.wait()
    end
end)

-- Auto Jump
task.spawn(function()
    while true do
        if Flags.AutoJump and BW.alive() then
            local h = BW.hum()
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
        task.wait((Flags.AutoJumpDelay or 300) / 1000)
    end
end)

-- Bhop (auto bunny hop with speed)
task.spawn(function()
    while true do
        if Flags.Bhop and BW.alive() then
            local h = BW.hum()
            local my = BW.hrp()
            if h and my then
                h.WalkSpeed = Flags.BhopSpeed or 32
                if h:GetState() == Enum.HumanoidStateType.Running then
                    h:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end
        task.wait(0.1)
    end
end)

-- Edge Jump (jump at edge of block)
task.spawn(function()
    while true do
        if Flags.EdgeJump and BW.alive() then
            local my = BW.hrp()
            local h = BW.hum()
            if my and h then
                local rp = RaycastParams.new()
                rp.FilterDescendantsInstances = {BW.char()}
                rp.FilterType = Enum.RaycastFilterType.Exclude
                -- Check if we're near an edge
                local frontRay = BW.Workspace:Raycast(my.Position, my.CFrame.LookVector * 3, rp)
                local downRay = BW.Workspace:Raycast(my.Position, Vector3.new(0, -4, 0), rp)
                if frontRay and not downRay then
                    h:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end
        task.wait(0.05)
    end
end)

-- Safe Fall (slow fall)
task.spawn(function()
    while true do
        if Flags.SafeFall and BW.alive() then
            local h = BW.hum()
            local my = BW.hrp()
            if h and my then
                if h:GetState() == Enum.HumanoidStateType.Freefall then
                    my.Velocity = Vector3.new(my.Velocity.X, math.max(my.Velocity.Y, -20), my.Velocity.Z)
                end
            end
        end
        task.wait(0.05)
    end
end)

-- Auto Walk (walk to nearest enemy)
task.spawn(function()
    while true do
        if Flags.AutoWalk and BW.alive() then
            local h = BW.hum()
            local my = BW.hrp()
            if h and my then
                local target, dist = BW.nearestEnemy(Flags.WalkRange or 30)
                if target then
                    h:MoveTo(target.HRP.Position)
                end
            end
        end
        task.wait(0.5)
    end
end)

-- No Fall Damage
task.spawn(function()
    while true do
        if Flags.NoFallDmg and BW.alive() then
            local h = BW.hum()
            if h then h:ChangeState(Enum.HumanoidStateType.Freefall) end
        end
        task.wait(0.1)
    end
end)

-- Land Factor (reduce fall damage)
task.spawn(function()
    while true do
        if Flags.LandFactor and BW.alive() then
            local my = BW.hrp()
            local h = BW.hum()
            if my and h then
                if h:GetState() == Enum.HumanoidStateType.Freefall then
                    local vel = my.Velocity.Y
                    if vel < -50 then
                        my.Velocity = Vector3.new(my.Velocity.X, vel * (Flags.LandFactorVal or 3) / 10, my.Velocity.Z)
                    end
                end
            end
        end
        task.wait(0.05)
    end
end)

print("[Move] Module loaded (30+ features)")
