--!nocheck
-- ══════════════════════════════════════════════════════════════
-- ESP MODULE v5.1 — Advanced Personal ESP
-- ══════════════════════════════════════════════════════════════
local E = BW.Win:Tab("ESP")
if not E or not E.Toggle then warn("[ESP] Failed to create tab!") return end

-- ═══ Player ESP ═══
E:Toggle("Player ESP (Box)", false, function(v) Flags.ESP_Box = v end)
E:Toggle("Player ESP (Name)", false, function(v) Flags.ESP_Name = v end)
E:Toggle("Player ESP (Health)", false, function(v) Flags.ESP_Health = v end)
E:Toggle("Player ESP (Distance)", false, function(v) Flags.ESP_Dist = v end)
E:Toggle("Tracer ESP", false, function(v) Flags.ESP_Tracer = v end)
E:Toggle("3D Box ESP", false, function(v) Flags.ESP_3DBox = v end)
E:Toggle("Health Bar", false, function(v) Flags.ESP_HealthBar = v end)
E:Toggle("Target ESP", false, function(v) Flags.ESP_Target = v end)
E:Toggle("Skeleton ESP", false, function(v) Flags.ESP_Skeleton = v end)
E:Toggle("Head Dot", false, function(v) Flags.ESP_HeadDot = v end)
E:Toggle("Glow ESP", false, function(v) Flags.ESP_Glow = v end)
E:Separator()

-- ═══ World ESP ═══
E:Toggle("Bed ESP", false, function(v) Flags.ESP_Bed = v end)
E:Toggle("Item ESP", false, function(v) Flags.ESP_Item = v end)
E:Toggle("Chest ESP", false, function(v) Flags.ESP_Chest = v end)
E:Toggle("Shop NPC ESP", false, function(v) Flags.ESP_Shop = v end)
E:Toggle("Resource Spawn ESP", false, function(v) Flags.ESP_Resource = v end)
E:Toggle("Crystal ESP", false, function(v) Flags.ESP_Crystal = v end)
E:Toggle("Drill ESP", false, function(v) Flags.ESP_Drill = v end)
E:Separator()

-- ═══ Settings ═══
E:Toggle("Team Check", false, function(v) Flags.ESP_TeamCheck = v end)
E:Toggle("Distance Limit", false, function(v) Flags.ESP_DistLimit = v end)
E:Slider("Max ESP Distance", 50, 500, 200, function(v) Flags.ESP_MaxDist = v end)
E:Separator()

-- ═══ Chams ═══
E:Toggle("Chams", false, function(v) Flags.Chams = v end)
E:Toggle("Arrows (outside FOV)", false, function(v) Flags.Arrows = v end)
E:Toggle("KitESP", false, function(v) Flags.KitESP = v end)
E:Toggle("StorageESP", false, function(v) Flags.StorageESP = v end)
E:Toggle("Waypoints", false, function(v) Flags.Waypoints = v end)
E:Button({Name="Add Waypoint", Color=Color3.fromRGB(60,100,140)}, function()
    local my = BW.hrp()
    if my then
        local wp = Instance.new("Part"); wp.Size=Vector3.new(2,2,2); wp.Position=my.Position
        wp.Anchored=true; wp.CanCollide=false; wp.Transparency=0.5; wp.Color=Color3.fromRGB(0,255,0); wp.Parent=BW.Workspace; wp.Name="BW_Waypoint"
        local bb=Instance.new("BillboardGui",wp); bb.Size=UDim2.new(0,80,0,20); bb.StudsOffset=Vector3.new(0,2,0); bb.AlwaysOnTop=true
        local lbl=Instance.new("TextLabel",bb); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=0.5; lbl.BackgroundColor3=Color3.fromRGB(0,0,0); lbl.Text="WP"; lbl.TextColor3=Color3.fromRGB(0,255,0); lbl.TextScaled=true
    end
end)
E:Button({Name="Clear Waypoints", Color=Color3.fromRGB(140,60,60)}, function()
    for _, wp in pairs(BW.Workspace:GetChildren()) do if wp.Name=="BW_Waypoint" then wp:Destroy() end end
end)

-- ═══ ENGINES ═══
local ESP_BBs = {}
local ESP_Drawings = {}

local function clearESP()
    for _, bb in pairs(ESP_BBs) do pcall(function() bb:Destroy() end) end
    ESP_BBs = {}
    for _, d in pairs(ESP_Drawings) do pcall(function() d:Remove() end) end
    ESP_Drawings = {}
end

-- 3D Box ESP
local function draw3DBox(hrp)
    if not hrp then return end
    local size = Vector3.new(2, 5, 2)
    local pos = hrp.Position
    local corners = {
        pos + Vector3.new(-size.X/2, -size.Y/2, -size.Z/2),
        pos + Vector3.new(size.X/2, -size.Y/2, -size.Z/2),
        pos + Vector3.new(size.X/2, size.Y/2, -size.Z/2),
        pos + Vector3.new(-size.X/2, size.Y/2, -size.Z/2),
        pos + Vector3.new(-size.X/2, -size.Y/2, size.Z/2),
        pos + Vector3.new(size.X/2, -size.Y/2, size.Z/2),
        pos + Vector3.new(size.X/2, size.Y/2, size.Z/2),
        pos + Vector3.new(-size.X/2, size.Y/2, size.Z/2),
    }
    local edges = {{1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}}
    for _, edge in pairs(edges) do
        local a, b = corners[edge[1]], corners[edge[2]]
        local posA, visA = BW.Camera:WorldToViewportPoint(a)
        local posB, visB = BW.Camera:WorldToViewportPoint(b)
        if visA and visB then
            local line = Drawing.new("Line")
            line.From = Vector2.new(posA.X, posA.Y)
            line.To = Vector2.new(posB.X, posB.Y)
            line.Color = Color3.fromRGB(255, 50, 50)
            line.Thickness = 1
            line.Visible = true
            table.insert(ESP_Drawings, line)
        end
    end
end

-- Health Bar
local function drawHealthBar(player, hrp, hum)
    if not hrp or not hum then return end
    local pos, onScr = BW.Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
    if not onScr then return end
    local hpPct = hum.Health / hum.MaxHealth
    local barWidth = 40
    local barHeight = 4
    local x, y = pos.X - barWidth/2, pos.Y - 25
    -- Background
    local bg = Drawing.new("Square")
    bg.Size = Vector2.new(barWidth, barHeight)
    bg.Position = Vector2.new(x, y)
    bg.Color = Color3.fromRGB(50, 50, 50)
    bg.Filled = true
    bg.Visible = true
    table.insert(ESP_Drawings, bg)
    -- Fill
    local fill = Drawing.new("Square")
    fill.Size = Vector2.new(barWidth * hpPct, barHeight)
    fill.Position = Vector2.new(x, y)
    fill.Color = hpPct > 0.5 and Color3.fromRGB(0, 255, 0) or hpPct > 0.25 and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(255, 0, 0)
    fill.Filled = true
    fill.Visible = true
    table.insert(ESP_Drawings, fill)
end

-- Target ESP (highlight targeted enemy)
local function drawTargetESP(target)
    if not target or not target.HRP then return end
    local pos, onScr = BW.Camera:WorldToViewportPoint(target.HRP.Position)
    if not onScr then return end
    -- Draw circle around target
    local circle = Drawing.new("Circle")
    circle.Position = Vector2.new(pos.X, pos.Y)
    circle.Radius = 20
    circle.Color = Color3.fromRGB(255, 0, 0)
    circle.Thickness = 2
    circle.Visible = true
    table.insert(ESP_Drawings, circle)
end

-- Head Dot
local function drawHeadDot(hrp)
    if not hrp then return end
    local head = hrp.Parent:FindFirstChild("Head")
    if not head then return end
    local pos, onScr = BW.Camera:WorldToViewportPoint(head.Position)
    if not onScr then return end
    local dot = Drawing.new("Circle")
    dot.Position = Vector2.new(pos.X, pos.Y)
    dot.Radius = 3
    dot.Color = Color3.fromRGB(255, 50, 50)
    dot.Filled = true
    dot.Visible = true
    table.insert(ESP_Drawings, dot)
end

-- Tracer
local function drawTracer(hrp)
    if not hrp then return end
    local pos, onScr = BW.Camera:WorldToViewportPoint(hrp.Position)
    if not onScr then return end
    local center = Vector2.new(BW.Camera.ViewportSize.X/2, BW.Camera.ViewportSize.Y)
    local tracer = Drawing.new("Line")
    tracer.From = center
    tracer.To = Vector2.new(pos.X, pos.Y)
    tracer.Color = Color3.fromRGB(255, 50, 50)
    tracer.Thickness = 1
    tracer.Visible = true
    table.insert(ESP_Drawings, tracer)
end

-- Bed ESP
local function updateBedESP()
    local descendants = BW.Perf and BW.Perf.GetDescendantsCached(BW.Workspace, 3) or BW.Workspace:GetDescendants()
    for _, obj in pairs(descendants) do
        if obj.Name:find("bed") and obj:IsA("Model") then
            local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("Part")
            if part and not part:FindFirstChild("BW_BedESP") then
                local bb=Instance.new("BillboardGui"); bb.Name="BW_BedESP"; bb.Size=UDim2.new(0,80,0,25); bb.StudsOffset=Vector3.new(0,2,0); bb.AlwaysOnTop=true; bb.Adornee=part; bb.Parent=part
                local lbl=Instance.new("TextLabel",bb); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=0.5; lbl.BackgroundColor3=Color3.fromRGB(0,0,0); lbl.Text="BED"; lbl.TextColor3=Color3.fromRGB(255,200,50); lbl.TextScaled=true; lbl.Font=Enum.Font.GothamBold
                table.insert(ESP_BBs, bb)
            end
        end
    end
end

-- Resource ESP
local function updateResourceESP()
    local descendants = BW.Perf and BW.Perf.GetDescendantsCached(BW.Workspace, 3) or BW.Workspace:GetDescendants()
    for _, obj in pairs(descendants) do
        if obj:IsA("BasePart") then
            local n=obj.Name:lower(); local c=nil
            if n:find("iron") then c=Color3.fromRGB(200,200,210) end
            if n:find("gold") then c=Color3.fromRGB(255,215,0) end
            if n:find("diamond") then c=Color3.fromRGB(100,200,255) end
            if n:find("emerald") then c=Color3.fromRGB(50,255,50) end
            if c and not obj:FindFirstChild("BW_ResESP") then
                local bb=Instance.new("BillboardGui"); bb.Name="BW_ResESP"; bb.Size=UDim2.new(0,60,0,20); bb.StudsOffset=Vector3.new(0,1.5,0); bb.AlwaysOnTop=true; bb.Adornee=obj; bb.Parent=obj
                local lbl=Instance.new("TextLabel",bb); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=0.5; lbl.BackgroundColor3=Color3.fromRGB(0,0,0); lbl.Text=obj.Name; lbl.TextColor3=c; lbl.TextScaled=true; lbl.Font=Enum.Font.GothamBold
                table.insert(ESP_BBs, bb)
            end
        end
    end
end

-- Chams
local function updateChams()
    for _, e in pairs(BW.enemies()) do
        for _, part in pairs(e.Char:GetDescendants()) do
            if part:IsA("BasePart") and not part:GetAttribute("_BW_Chams") then
                part:SetAttribute("_BW_Chams", part.Material.Name)
                part.Material=Enum.Material.ForceField; part.Color=Color3.fromRGB(255,0,0); part.Transparency=0.5; part.CanCollide=false
            end
        end
    end
end

local function clearChams()
    for _, e in pairs(BW.enemies()) do
        for _, part in pairs(e.Char:GetDescendants()) do
            if part:IsA("BasePart") and part:GetAttribute("_BW_Chams") then
                pcall(function() part.Material=Enum.Material[part:GetAttribute("_BW_Chams")] end)
                part:RemoveAttribute("_BW_Chams"); part.Transparency=0
            end
        end
    end
end

-- Player ESP
local function updatePlayerESP()
    for _, e in pairs(BW.enemies()) do
        if not (Flags.ESP_TeamCheck and e.Player.Team==BW.LocalPlayer.Team) then
            local hrp2=e.HRP
            if hrp2 then
                local my=BW.hrp()
                local dist=(my and math.floor((my.Position-hrp2.Position).Magnitude)) or 0
                if Flags.ESP_DistLimit and dist > (Flags.ESP_MaxDist or 200) then
                    goto continue_esp
                end
                local pos, onScr=BW.Camera:WorldToViewportPoint(hrp2.Position)
                -- 3D Box
                if Flags.ESP_3DBox then pcall(function() draw3DBox(hrp2) end) end
                -- Health Bar
                if Flags.ESP_HealthBar then pcall(function() drawHealthBar(e.Player, hrp2, e.Hum) end) end
                -- Tracer
                if Flags.ESP_Tracer then pcall(function() drawTracer(hrp2) end) end
                -- Head Dot
                if Flags.ESP_HeadDot then pcall(function() drawHeadDot(hrp2) end) end
                -- Billboard ESP
                if onScr and (Flags.ESP_Box or Flags.ESP_Name or Flags.ESP_Health or Flags.ESP_Dist) then
                    local bb=e.Char:FindFirstChild("BW_PlayerESP")
                    if not bb then
                        bb=Instance.new("BillboardGui"); bb.Name="BW_PlayerESP"; bb.Size=UDim2.new(0,120,0,50); bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true; bb.Adornee=hrp2; bb.Parent=e.Char
                        local lbl=Instance.new("TextLabel",bb); lbl.Name="Info"; lbl.Size=UDim2.new(1,0,0.6,0); lbl.BackgroundTransparency=0.5; lbl.BackgroundColor3=Color3.fromRGB(0,0,0); lbl.TextColor3=Color3.new(1,1,1); lbl.TextScaled=true; lbl.Font=Enum.Font.GothamBold
                        local hp=Instance.new("TextLabel",bb); hp.Name="HP"; hp.Size=UDim2.new(1,0,0.3,0); hp.Position=UDim2.new(0,0,0.6,0); hp.BackgroundTransparency=0.5; hp.BackgroundColor3=Color3.fromRGB(0,0,0); hp.TextColor3=Color3.fromRGB(0,255,0); hp.TextScaled=true; hp.Font=Enum.Font.GothamBold
                        table.insert(ESP_BBs, bb)
                    end
                    local info=bb:FindFirstChild("Info")
                    local hpLbl=bb:FindFirstChild("HP")
                    if info then
                        local text=""
                        if Flags.ESP_Name then text=e.Player.Name end
                        if Flags.ESP_Dist then text=text.." ["..dist.."m]" end
                        info.Text=text
                    end
                    if hpLbl then
                        local hpPct=e.Hum.Health/e.Hum.MaxHealth
                        hpLbl.Text=math.floor(e.Hum.Health).."/"..math.floor(e.Hum.MaxHealth)
                        hpLbl.TextColor3=hpPct>0.5 and Color3.fromRGB(0,255,0) or hpPct>0.25 and Color3.fromRGB(255,255,0) or Color3.fromRGB(255,0,0)
                    end
                end
            end
        end
        ::continue_esp::
    end
end

-- Main ESP loop
task.spawn(function()
    while true do
        -- Clear drawings first
        for _, d in pairs(ESP_Drawings) do pcall(function() d:Remove() end) end
        ESP_Drawings = {}

        local anyESP=Flags.ESP_Box or Flags.ESP_Name or Flags.ESP_Health or Flags.ESP_Dist or Flags.ESP_3DBox or Flags.ESP_HealthBar or Flags.ESP_Tracer or Flags.ESP_HeadDot or Flags.ESP_Glow
        if anyESP then pcall(updatePlayerESP) end
        if Flags.ESP_Bed then pcall(updateBedESP) end
        if Flags.ESP_Resource then pcall(updateResourceESP) end
        if Flags.Chams then pcall(updateChams)
        else pcall(clearChams) end
        task.wait(0.05)
    end
end)

-- Arrows
task.spawn(function()
    while true do
        if Flags.Arrows then
            pcall(function()
                for _, e in pairs(BW.enemies()) do
                    local pos, onScr=BW.Camera:WorldToViewportPoint(e.HRP.Position)
                    if not onScr then
                        local center=Vector2.new(BW.Camera.ViewportSize.X/2,BW.Camera.ViewportSize.Y/2)
                        local dir=(Vector2.new(pos.X,pos.Y)-center).Unit
                        local arrowPos=center+dir*math.min(BW.Camera.ViewportSize.X*0.4,200)
                        local arrow=Drawing.new("Triangle")
                        arrow.PointA=arrowPos+dir*10; arrow.PointB=arrowPos+Vector2.new(-dir.Y,dir.X)*6; arrow.PointC=arrowPos+Vector2.new(dir.Y,-dir.X)*6
                        arrow.Color=Color3.fromRGB(255,50,50); arrow.Filled=true; arrow.Visible=true
                        table.insert(ESP_Drawings, arrow)
                    end
                end
            end)
        end
        task.wait(0.1)
    end
end)

-- Target ESP (highlight nearest enemy)
task.spawn(function()
    while true do
        if Flags.ESP_Target then
            pcall(function()
                local target, dist = BW.nearestEnemy(50)
                if target then drawTargetESP(target) end
            end)
        end
        task.wait(0.1)
    end
end)

print("[ESP] Module loaded (advanced)")
