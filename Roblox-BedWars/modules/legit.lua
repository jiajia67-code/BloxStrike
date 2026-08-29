-- ══════════════════════════════════════════════════════════════
-- LEGIT MODULE
-- ══════════════════════════════════════════════════════════════
local L = BW.Win:Tab("Legit", "🎨")
L:Toggle({Name="Custom Crosshair", Flag="Crosshair"})
L:Slider({Name="Crosshair Size", Flag="CH_Size", Min=1, Max=10, Default=3})
L:Dropdown({Name="Crosshair Color", Flag="CH_Color", Options={"White","Red","Green","Blue","Cyan","Yellow"}, Default="White"})
L:Toggle({Name="Keystrokes", Flag="Keystrokes"})
L:Toggle({Name="FPS Display", Flag="FPS_Disp"})
L:Toggle({Name="Ping Display", Flag="Ping_Disp"})
L:Toggle({Name="Speed Display", Flag="Speed_Disp"})
L:Toggle({Name="Session Info", Flag="SessionInfo"})
L:Slider({Name="FOV Changer", Flag="FOV_Val", Min=50, Max=120, Default=70})
L:Toggle({Name="FOV Active", Flag="FOV_Active"})
L:Separator()
L:Label("-- Visual Mods --")
L:Toggle({Name="Atmosphere", Flag="Atmosphere"})
L:Toggle({Name="Time Changer", Flag="TimeChanger"})
L:Slider({Name="Time Hour", Flag="TimeHour", Min=0, Max=23, Default=14})
L:Toggle({Name="HitColor", Flag="HitColor"})
L:Toggle({Name="KillEffect", Flag="KillEffect"})
L:Toggle({Name="Breadcrumbs", Flag="Breadcrumbs"})
L:Toggle({Name="Cape", Flag="Cape"})
L:Toggle({Name="ChinaHat", Flag="ChinaHat"})

-- ═══ ENGINES ═══

-- Crosshair
task.spawn(function()
    while true do
        if BW.Flags.Crosshair then
            local sg=BW.SG
            if sg and not sg:FindFirstChild("CrosshairGui") then
                local ch=Instance.new("Frame"); ch.Name="CrosshairGui"; ch.Size=UDim2.new(0,1,0,1); ch.BackgroundColor3=Color3.new(1,1,1); ch.BorderSizePixel=0; ch.AnchorPoint=Vector2.new(0.5,0.5); ch.Position=UDim2.new(0.5,0,0.5,0); ch.Parent=sg; ch.ZIndex=999
                Instance.new("Frame",ch).Size=UDim2.new(0,BW.Flags.CH_Size or 3,0,BW.Flags.CH_Size or 3); ch.Frame.BackgroundColor3=Color3.new(1,1,1); ch.Frame.BorderSizePixel=0; ch.Frame.AnchorPoint=Vector2.new(0.5,0.5); ch.Frame.Position=UDim2.new(0.5,0,0.5,0); ch.Frame.ZIndex=1000
                local h=Instance.new("Frame",ch); h.Size=UDim2.new(0,(BW.Flags.CH_Size or 3)*6,0,BW.Flags.CH_Size or 3); h.BackgroundColor3=Color3.new(1,1,1); h.BorderSizePixel=0; h.AnchorPoint=Vector2.new(0.5,0.5); h.Position=UDim2.new(0.5,0,0.5,0); h.ZIndex=1000
                local v=Instance.new("Frame",ch); v.Size=UDim2.new(0,BW.Flags.CH_Size or 3,0,(BW.Flags.CH_Size or 3)*6); v.BackgroundColor3=Color3.new(1,1,1); v.BorderSizePixel=0; v.AnchorPoint=Vector2.new(0.5,0.5); v.Position=UDim2.new(0.5,0,0.5,0); v.ZIndex=1000
            end
        else
            local sg=BW.SG
            if sg and sg:FindFirstChild("CrosshairGui") then sg.CrosshairGui:Destroy() end
        end
        task.wait(0.5)
    end
end)

-- FOV Changer
task.spawn(function()
    while true do
        if BW.Flags.FOV_Active then BW.Camera.FieldOfView=BW.Flags.FOV_Val or 70
        elseif BW.Camera.FieldOfView~=70 then BW.Camera.FieldOfView=70 end
        task.wait(0.3)
    end
end)

-- Atmosphere
task.spawn(function()
    while true do
        if BW.Flags.Atmosphere then BW.Lighting.Ambient=Color3.fromRGB(100,100,120); BW.Lighting.Brightness=2 end
        task.wait(1)
    end
end)

-- Time Changer
task.spawn(function()
    while true do
        if BW.Flags.TimeChanger then BW.Lighting.ClockTime=BW.Flags.TimeHour or 14 end
        task.wait(1)
    end
end)

-- Breadcrumbs
task.spawn(function()
    while true do
        if BW.Flags.Breadcrumbs and BW.alive() then
            local my=BW.hrp()
            if my then
                local p=Instance.new("Part"); p.Size=Vector3.new(0.2,0.2,0.2); p.Position=my.Position-Vector3.new(0,2,0)
                p.Anchored=true; p.CanCollide=false; p.Material=Enum.Material.Neon; p.Color=Color3.fromRGB(0,150,255); p.Parent=BW.Workspace
                game:GetService("Debris"):AddItem(p,2)
            end
        end
        task.wait(0.1)
    end
end)

-- Cape
task.spawn(function()
    while true do
        if BW.Flags.Cape then
            local c=BW.char()
            if c and not c:FindFirstChild("BW_Cape") then
                local torso=c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso")
                if torso then
                    local cape=Instance.new("Part"); cape.Name="BW_Cape"; cape.Size=Vector3.new(1.5,2,0.1); cape.Color=Color3.fromRGB(255,0,0); cape.Material=Enum.Material.Fabric; cape.Anchored=false; cape.CanCollide=false; cape.Parent=c
                    local w=Instance.new("Weld"); w.Part0=torso; w.Part1=cape; w.C0=CFrame.new(0,-1,-0.7); w.Parent=cape
                end
            end
        else
            local c=BW.char() if c and c:FindFirstChild("BW_Cape") then c.BW_Cape:Destroy() end
        end
        task.wait(1)
    end
end)

-- ChinaHat
task.spawn(function()
    while true do
        if BW.Flags.ChinaHat then
            local c=BW.char()
            if c and not c:FindFirstChild("BW_ChinaHat") then
                local head=c:FindFirstChild("Head")
                if head then
                    local hat=Instance.new("Part"); hat.Name="BW_ChinaHat"; hat.Size=Vector3.new(2,1,2); hat.Shape=Enum.PartType.Cylinder; hat.Color=Color3.fromRGB(255,50,50); hat.Material=Enum.Material.SmoothPlastic; hat.Anchored=false; hat.CanCollide=false; hat.Parent=c
                    local w=Instance.new("Weld"); w.Part0=head; w.Part1=hat; w.C0=CFrame.new(0,1.2,0)*CFrame.Angles(0,0,math.rad(90)); w.Parent=hat
                end
            end
        else
            local c=BW.char() if c and c:FindFirstChild("BW_ChinaHat") then c.BW_ChinaHat:Destroy() end
        end
        task.wait(1)
    end
end)

print("[Legit] Module loaded")
