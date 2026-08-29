

-- BLOXSTRIKE VIEWMODEL CHANGER v1.0
-- Custom weapon viewmodel position, angle, FOV, animation

local Players = nil

pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local UIS = nil
pcall(function() UIS = game:GetService("UserInputService") end)
local lplr = Players.LocalPlayer

 -- Viewmodel State
local VM = {
    -- Offset = Vector3.new(0, 0, 0),
    -- Angle = Vector3.new(0, 0, 0),
    Scale = 1,
    FOV = 70,
    -- SinOffset = Vector3.new(0, 0, 0),
    -- ShakeOffset = Vector3.new(0, 0, 0),
    -- BobOffset = Vector3.new(0, 0, 0),
    OriginalCameraFOV = 70,
}

 -- Viewmodel Presets
local ViewmodelPresets = {
    ["Default"] = {
        PosX = 0, PosY = 0, PosZ = 0,
        AngX = 0, AngY = 0, AngZ = 0,
        Scale = 1, FOV = 70,
    },
    ["CS2 Style"] = {
        PosX = -0.5, PosY = -0.3, PosZ = -1.5,
        AngX = 0, AngY = 0, AngZ = 0,
        Scale = 0.95, FOV = 68,
    },
    ["Far Right"] = {
        PosX = -1.2, PosY = -0.2, PosZ = -1.0,
        AngX = 0, AngY = 15, AngZ = 0,
        Scale = 0.9, FOV = 72,
    },
    ["Close Up"] = {
        PosX = 0, PosY = 0.2, PosZ = -0.5,
        AngX = 0, AngY = 0, AngZ = 0,
        Scale = 1.1, FOV = 65,
    },
    ["Tight"] = {
        PosX = -0.3, PosY = -0.5, PosZ = -1.8,
        AngX = 5, AngY = 5, AngZ = 0,
        Scale = 0.85, FOV = 70,
    },
    ["Wide"] = {
        PosX = -0.8, PosY = -0.1, PosZ = -2.0,
        AngX = -3, AngY = -10, AngZ = 0,
        Scale = 0.9, FOV = 80,
    },
    ["Center"] = {
        PosX = 0, PosY = -0.3, PosZ = -1.5,
        AngX = 0, AngY = 0, AngZ = 0,
        Scale = 0.95, FOV = 70,
    },
    ["Insurgency"] = {
        PosX = -0.7, PosY = -0.4, PosZ = -1.2,
        AngX = 10, AngY = 8, AngZ = 0,
        Scale = 1.0, FOV = 68,
    },
}

 -- Viewmodel FOV (Perspective)
local vmFovCircle = nil

 -- Viewmodel Bob (Walking)
local function calculateBob(speed, time)
    if not Flags.VMBob then return Vector3.new(0, 0, 0) end

    local bobAmount = Flags.VMBobAmount or 0.5
    local bobSpeed = Flags.VMBobSpeed or 8

    if speed < 1 then return Vector3.new(0, 0, 0) end

    local bobX = math.sin(time * bobSpeed) * bobAmount * 0.5
    local bobY = math.abs(math.cos(time * bobSpeed)) * bobAmount

    return Vector3.new(bobX, bobY, 0)
end

 -- Viewmodel Sway (Mouse Movement)
local lastMousePos = Vector2.new(0, 0)
local swayVelocity = Vector2.new(0, 0)

local function calculateSway(dt)
    if not Flags.VMSway then return Vector3.new(0, 0, 0) end

    local mousePos = UIS:GetMouseLocation()
    local delta = mousePos - lastMousePos
    lastMousePos = mousePos

    -- Smooth velocity
    swayVelocity = swayVelocity:Lerp(delta / math.max(dt, 0.001), 0.1)

    local swayAmount = Flags.VMSwayAmount or 0.3
    local swayX = -swayVelocity.X * swayAmount * 0.01
    local swayY = swayVelocity.Y * swayAmount * 0.01

    return Vector3.new(swayX, swayY, 0)
end

 -- Viewmodel Recoil Animation
local recoilOffset = Vector3.new(0, 0, 0)

local function applyRecoil(amount)
    recoilOffset = recoilOffset + Vector3.new(0, amount * 0.5, amount * 0.2)
end

 -- Viewmodel Breathing
local function calculateBreathing(time)
    if not Flags.VMBreathe then return Vector3.new(0, 0, 0) end

    local breatheAmount = Flags.VMBreatheAmount or 0.1
    local breatheSpeed = Flags.VMBreatheSpeed or 1.5

    local breatheY = math.sin(time * breatheSpeed * math.pi) * breatheAmount
    local breatheX = math.cos(time * breatheSpeed * math.pi * 0.5) * breatheAmount * 0.3

    return Vector3.new(breatheX, breatheY, 0)
end

 -- Viewmodel Engine
task.spawn(function()
    while true do
        local dt = RunService.RenderStepped:Wait()
        pcall(function()
            local cam = workspace.CurrentCamera
            if not cam then return end

            -- Store original FOV
            if VM.OriginalCameraFOV == 70 then
                VM.OriginalCameraFOV = cam.FieldOfView
            end

            -- Check if viewmodel features are enabled
            local anyEnabled = Flags.VMOffset or Flags.VMAngle or Flags.VMScale or Flags.VMFOV
                or Flags.VMBob or Flags.VMSway or Flags.VMBreathe or Flags.VMRecoil

            if not anyEnabled then return end
            if not lplr.Character then return end

            local tool = lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
            if not tool then return end

            local handle = tool:FindFirstChild("Handle")
            if not handle then return end

             -- Position Offset
            if Flags.VMOffset then
                local offsetX = Flags.VMPosX or 0
                local offsetY = Flags.VMPosY or 0
                local offsetZ = Flags.VMPosZ or 0
                VM.Offset = Vector3.new(offsetX / 10, offsetY / 10, offsetZ / 10)
            end

             -- Angle Offset
            if Flags.VMAngle then
                local angX = Flags.VMAngX or 0
                local angY = Flags.VMAngY or 0
                local angZ = Flags.VMAngZ or 0
                VM.Angle = Vector3.new(angX, angY, angZ)
            end

             -- Scale
            if Flags.VMScale then
                local scale = (Flags.VMScaleVal or 100) / 100
                VM.Scale = math.clamp(scale, 0.5, 2)
            end

             -- FOV
            if Flags.VMFOV then
                cam.FieldOfView = Flags.VMFOVVal or 70
            else
                cam.FieldOfView = VM.OriginalCameraFOV
            end

             -- Walking Bob
            local speed = 0
            local hrp = lplr and lplr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                speed = hrp.AssemblyLinearVelocity.Magnitude
            end
            VM.BobOffset = calculateBob(speed, tick())

             -- Mouse Sway
            VM.SinOffset = calculateSway(dt)

             -- Breathing
            local breatheOffset = calculateBreathing(tick())

             -- Recoil Decay
            recoilOffset = recoilOffset:Lerp(Vector3.new(0, 0, 0), dt * 10)

             -- Apply All Offsets to Handle
            local totalOffset = VM.Offset + VM.BobOffset + VM.SinOffset + breatheOffset + recoilOffset

            -- Position
            handle.CFrame = handle.CFrame + totalOffset

            -- Rotation
            if Flags.VMAngle then
                local angRad = Vector3.new(
                    math.rad(VM.Angle.X),
                    math.rad(VM.Angle.Y),
                    math.rad(VM.Angle.Z)
                )
                handle.CFrame = handle.CFrame * CFrame.Angles(angRad.X, angRad.Y, angRad.Z)
            end

            -- Scale (using mesh if available)
            if Flags.VMScale and VM.Scale ~= 1 then
                local mesh = handle:FindFirstChildWhichIsA("SpecialMesh")
                if mesh then
                    mesh.Scale = Vector3.new(VM.Scale, VM.Scale, VM.Scale)
                else
                    -- Try to find a mesh in children
                    for _, child in ipairs(handle:GetChildren()) do
                        if child:IsA("DataModelMesh") then
                            child.Scale = Vector3.new(VM.Scale, VM.Scale, VM.Scale)
                            break
                        end
                    end
                end
            end

             -- Viewmodel FOV Circle (debug)
            if Flags.VMFovCircle then
                if not vmFovCircle then
                    local Compat = _G.BS and _G.BS.Compat
                    if Compat and Compat.DrawingNew then
                        vmFovCircle = Compat.DrawingNew("Circle")
                    else
                        pcall(function() vmFovCircle = Drawing.new("Circle") end)
                    end
                    if vmFovCircle then vmFovCircle.Thickness = 1; vmFovCircle.NumSides = 64; vmFovCircle.Filled = false end
                end
                if vmFovCircle then
                    vmFovCircle.Position = UIS:GetMouseLocation()
                    vmFovCircle.Radius = 100
                    vmFovCircle.Color = Color3.fromRGB(0, 255, 255)
                    vmFovCircle.Visible = true
                end
            else
                if vmFovCircle then vmFovCircle.Visible = false end
            end
        end)
    end
end)

 -- Recoil Hook (listen for tool activation)
task.spawn(function()
    while true do
        task.wait(0.1)
        pcall(function()
            if Flags.VMRecoil and lplr.Character then
                local tool = lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
                if tool then
                    -- Simple recoil on tool activation
                    local conn
                    conn = tool.Activated:Connect(function()
                        local recoilAmount = Flags.VMRecoilAmount or 1
                        applyRecoil(recoilAmount)
                    end)
                    -- Don't reconnect if already connected
                    if conn then
                        task.delay(1, function()
                            pcall(function() conn:Disconnect() end)
                        end)
                    end
                end
            end
        end)
    end
end)

 -- Cleanup
lplr.CharacterRemoving:Connect(function()
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then
            cam.FieldOfView = VM.OriginalCameraFOV
        end
    end)
    if vmFovCircle then vmFovCircle.Visible = false end
end)

 -- Expose API
BS.Viewmodel = {
    Presets = ViewmodelPresets,
    ApplyPreset = function(name)
        local preset = ViewmodelPresets[name]
        if not preset then return end
        Flags.VMOffset = true
        Flags.VMPosX = preset.PosX
        Flags.VMPosY = preset.PosY
        Flags.VMPosZ = preset.PosZ
        Flags.VMAngle = true
        Flags.VMAngX = preset.AngX
        Flags.VMAngY = preset.AngY
        Flags.VMAngZ = preset.AngZ
        Flags.VMScale = true
        Flags.VMScaleVal = preset.Scale * 100
        Flags.VMFOV = true
        Flags.VMFOVVal = preset.FOV
        -- [optimized] print("[Viewmodel] Applied preset: " .. name)
    end,
}

local presetNames = {} for k, _ in pairs(ViewmodelPresets) do table.insert(presetNames, k) end
print("[Viewmodel] BloxStrike Viewmodel Changer loaded")
-- [optimized] print("[Viewmodel] Presets: " .. table.concat(presetNames, ", "))
