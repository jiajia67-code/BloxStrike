--!nocheck
-- ══════════════════════════════════════════════════════════════
-- UI LIBRARY MODULE v7.0 (Hybrid Drawing + Instance, Ultra Fast)
-- ══════════════════════════════════════════════════════════════
-- Strategy: Use Drawing API for visual-only elements (fast, no Instance overhead)
--           Use Instance only for interactive elements (clicks, text input)
--           Batch render updates, object pooling, throttled redraws
-- ══════════════════════════════════════════════════════════════

BW = bw

local Library = {}
Library.__index = Library

-- ═══ Drawing API Check ═══
local hasDrawing = (Drawing ~= nil)
pcall(function() hasDrawing = (Drawing ~= nil) end)

-- ═══ Object Pool (reuse Drawing objects instead of creating/destroying) ═══
local ObjectPool = {}
ObjectPool._pool = {}
ObjectPool._count = 0

function ObjectPool:get(drawType)
    local key = drawType
    if self._pool[key] and #self._pool[key] > 0 then
        local obj = table.remove(self._pool[key])
        pcall(function() obj.Visible = true end)
        return obj
    end
    self._count = self._count + 1
    local ok, obj = pcall(function() return Drawing.new(drawType) end)
    if ok then return obj end
    return nil
end

function ObjectPool:put(drawType, obj)
    if not obj then return end
    pcall(function() obj.Visible = false end)
    if not self._pool[drawType] then self._pool[drawType] = {} end
    table.insert(self._pool[drawType], obj)
end

function ObjectPool:clear()
    for k, v in pairs(self._pool) do
        for _, obj in ipairs(v) do
            pcall(function() obj:Remove() end)
        end
    end
    self._pool = {}
    self._count = 0
end

-- ═══ Render Batch (single RenderStepped for all Drawing updates) ═══
local RenderBatch = {}
RenderBatch._queue = {}
RenderBatch._lastUpdate = 0
RenderBatch._throttle = 1 / 60  -- 60 FPS max for UI redraws

function RenderBatch:queue(id, func)
    self._queue[id] = func
end

function RenderBatch:remove(id)
    self._queue[id] = nil
end

-- Single connection for ALL drawing updates
pcall(function()
    game:GetService("RunService").RenderStepped:Connect(function()
        local now = tick()
        if now - RenderBatch._lastUpdate < RenderBatch._throttle then return end
        RenderBatch._lastUpdate = now
        for _, func in pairs(RenderBatch._queue) do
            pcall(func)
        end
    end)
end)

-- ═══ Color Cache ═══
local C = {
    Bg       = Color3.fromRGB(18, 18, 24),
    Sidebar  = Color3.fromRGB(22, 22, 30),
    Content  = Color3.fromRGB(26, 26, 36),
    Card     = Color3.fromRGB(32, 32, 44),
    CardHov  = Color3.fromRGB(38, 38, 52),
    Accent   = Color3.fromRGB(90, 130, 255),
    AccentDk = Color3.fromRGB(60, 100, 220),
    Green    = Color3.fromRGB(80, 200, 120),
    Red      = Color3.fromRGB(240, 70, 70),
    Text     = Color3.fromRGB(220, 220, 230),
    TextDim  = Color3.fromRGB(140, 140, 160),
    TextMut  = Color3.fromRGB(80, 80, 100),
    Border   = Color3.fromRGB(40, 40, 55),
    TogOn    = Color3.fromRGB(80, 200, 120),
    TogOff   = Color3.fromRGB(60, 60, 75),
    SldFill  = Color3.fromRGB(90, 130, 255),
    SldBG    = Color3.fromRGB(40, 40, 55),
}

local function sw(cond, a, b) if cond then return a else return b end end

local function corner(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 6); c.Parent = p; return c
end

-- ═══ Fast Drawing Helpers ═══
local function drawRect(pos, size, color, filled, transparency)
    if not hasDrawing then return nil end
    local ok, s = pcall(function()
        local d = Drawing.new("Square")
        d.Position = pos; d.Size = size; d.Color = color
        d.Filled = filled ~= false; d.Thickness = 1
        d.Transparency = transparency or 1; d.Visible = true
        return d
    end)
    return ok and s or nil
end

local function drawText(pos, text, color, size, font)
    if not hasDrawing then return nil end
    local ok, t = pcall(function()
        local d = Drawing.new("Text")
        d.Position = pos; d.Text = text or ""; d.Color = color or C.Text
        d.Size = size or 13; d.Font = font or 2; d.Visible = true; d.Center = false
        return d
    end)
    return ok and t or nil
end

local function drawLine(from, to, color, thickness)
    if not hasDrawing then return nil end
    local ok, l = pcall(function()
        local d = Drawing.new("Line")
        d.From = from; d.To = to; d.Color = color or C.Text
        d.Thickness = thickness or 1; d.Visible = true
        return d
    end)
    return ok and l or nil
end

local function drawCircle(pos, radius, color, thickness)
    if not hasDrawing then return nil end
    local ok, c = pcall(function()
        local d = Drawing.new("Circle")
        d.Position = pos; d.Radius = radius; d.Color = color or C.Text
        d.Thickness = thickness or 1; d.Visible = true
        return d
    end)
    return ok and c or nil
end

-- ═══ Create Library Instance ═══
function Library:New(config)
    local self = setmetatable({}, Library)
    self.Flags = BW.Flags
    self.Config = config or {Title = "BedWars", Sub = "v7.0"}
    self.IsMobile = BW.isMobile
    self.IsTablet = BW.isTablet
    local scale = BW.screenScale or 1

    -- Remove old
    if game.CoreGui:FindFirstChild("BW_UI") then
        game.CoreGui:FindFirstChild("BW_UI"):Destroy()
    end

    -- ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name = "BW_UI"; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true; sg.Parent = game.CoreGui
    self.SG = sg

    -- ═══ Main Frame (Instance - needed for click interaction) ═══
    local mw = sw(BW.isMobile, 0.94, 580 * scale)
    local mh = sw(BW.isMobile, 0.7, 420 * scale)
    local mx = sw(BW.isMobile, 0.03, -290 * scale)
    local my = sw(BW.isMobile, 0.15, -210 * scale)

    local main = Instance.new("Frame")
    if BW.isMobile then
        main.Size = UDim2.new(mw, 0, mh, 0); main.Position = UDim2.new(mx, 0, my, 0)
    else
        main.Size = UDim2.new(0, mw, 0, mh); main.Position = UDim2.new(0.5, mx, 0.5, my)
    end
    main.BackgroundColor3 = C.Bg; main.BorderSizePixel = 0; main.Active = true; main.Parent = sg
    corner(main, 12)
    self.Main = main

    -- Shadow
    local sh = Instance.new("ImageLabel")
    sh.AnchorPoint = Vector2.new(0.5, 0.5); sh.Position = UDim2.new(0.5, 0, 0.5, 4)
    sh.Size = UDim2.new(1, 50, 1, 50); sh.BackgroundTransparency = 1
    sh.Image = "rbxassetid://6015897843"; sh.ImageColor3 = Color3.new(0, 0, 0)
    sh.ImageTransparency = 0.65; sh.ScaleType = Enum.ScaleType.Slice
    sh.SliceCenter = Rect.new(49, 49, 450, 450); sh.ZIndex = -1; sh.Parent = main

    -- ═══ Title Bar ═══
    local tb = Instance.new("Frame"); tb.Name = "TitleBar"
    tb.Size = UDim2.new(1, 0, 0, sw(BW.isMobile, 48, 44))
    tb.BackgroundColor3 = C.Sidebar; tb.BorderSizePixel = 0; tb.Parent = main; corner(tb, 12)

    local grad = Instance.new("Frame"); grad.Size = UDim2.new(1, 0, 0, 12)
    grad.Position = UDim2.new(0, 0, 1, -12); grad.BackgroundColor3 = C.Sidebar
    grad.BorderSizePixel = 0; grad.Parent = tb

    -- Title text (Drawing if available, fallback to Instance)
    local titleObj
    if hasDrawing then
        titleObj = drawText(
            Vector2.new(44, sw(BW.isMobile, 14, 12)),
            self.Config.Title .. " | " .. self.Config.Sub,
            C.Text, sw(BW.isMobile, 13, 15), 2
        )
        -- Also hide icon as instance since emoji can't render in Drawing
        local ico = Instance.new("TextLabel")
        ico.Size = UDim2.new(0, 30, 0, 44); ico.Position = UDim2.new(0, 12, 0, 0)
        ico.BackgroundTransparency = 1; ico.Text = "⚔️"; ico.TextSize = 18
        ico.Font = Enum.Font.GothamBold; ico.TextColor3 = C.Accent; ico.Parent = tb
    else
        local ico = Instance.new("TextLabel")
        ico.Size = UDim2.new(0, 30, 0, 44); ico.Position = UDim2.new(0, 12, 0, 0)
        ico.BackgroundTransparency = 1; ico.Text = "⚔️"; ico.TextSize = 18
        ico.Font = Enum.Font.GothamBold; ico.TextColor3 = C.Accent; ico.Parent = tb
        local tt = Instance.new("TextLabel")
        tt.Size = UDim2.new(0.5, 0, 1, 0); tt.Position = UDim2.new(0, 40, 0, 0)
        tt.BackgroundTransparency = 1; tt.Text = self.Config.Title .. " | " .. self.Config.Sub
        tt.TextColor3 = C.Text; tt.TextSize = sw(BW.isMobile, 13, 15)
        tt.Font = Enum.Font.GothamBold; tt.TextXAlignment = Enum.TextXAlignment.Left; tt.Parent = tb
    end

    -- Hint
    local ht = Instance.new("TextLabel")
    ht.Size = UDim2.new(0, 140, 1, 0); ht.Position = UDim2.new(1, -190, 0, 0)
    ht.BackgroundTransparency = 1; ht.Text = sw(BW.isMobile, "📱 Swipe tabs", "RightAlt to toggle")
    ht.TextColor3 = C.TextMut; ht.TextSize = 11; ht.Font = Enum.Font.Gotham
    ht.TextXAlignment = Enum.TextXAlignment.Right; ht.Parent = tb

    -- Close button
    local cs = sw(BW.isMobile, 36, 28)
    local cb = Instance.new("TextButton")
    cb.Size = UDim2.new(0, cs, 0, cs); cb.Position = UDim2.new(1, -(cs + 10), 0.5, -(cs / 2))
    cb.BackgroundColor3 = C.Red; cb.BorderSizePixel = 0; cb.Text = "✕"
    cb.TextColor3 = Color3.new(1, 1, 1); cb.TextSize = sw(BW.isMobile, 16, 12)
    cb.Font = Enum.Font.GothamBold; cb.Parent = tb; corner(cb, 6)

    -- ═══ Sidebar ═══
    local side = Instance.new("Frame"); side.Name = "Sidebar"
    if BW.isMobile then
        side.Size = UDim2.new(1, -16, 0, 40); side.Position = UDim2.new(0, 8, 0, 54)
    else
        side.Size = UDim2.new(0, 120, 1, -58); side.Position = UDim2.new(0, 6, 0, 50)
    end
    side.BackgroundColor3 = C.Sidebar; side.BorderSizePixel = 0; side.Parent = main; corner(side, 8)

    if BW.isMobile then
        local ly = Instance.new("UIListLayout", side)
        ly.FillDirection = Enum.FillDirection.Horizontal; ly.Padding = UDim.new(0, 4)
        ly.HorizontalAlignment = Enum.HorizontalAlignment.Left
        ly.VerticalAlignment = Enum.VerticalAlignment.Center
        Instance.new("UIPadding", side).PaddingLeft = UDim.new(0, 6)
    else
        Instance.new("UIListLayout", side).Padding = UDim.new(0, 3)
    end

    -- ═══ Content Area ═══
    local ct = Instance.new("Frame"); ct.Name = "Content"
    if BW.isMobile then
        ct.Size = UDim2.new(1, -16, 1, -108); ct.Position = UDim2.new(0, 8, 0, 100)
    else
        ct.Size = UDim2.new(1, -144, 1, -64); ct.Position = UDim2.new(0, 132, 0, 52)
    end
    ct.BackgroundColor3 = C.Content; ct.BorderSizePixel = 0; ct.ClipsDescendants = true
    ct.Parent = main; corner(ct, 8)

    self.Content = ct; self.Sidebar = side; self.Open = true
    self.Pages = {}; self.CurrentPage = nil; self.TabButtons = {}
    self.DrawingObjects = {}  -- Track Drawing objects for cleanup

    -- ═══ Mobile FAB ═══
    if BW.isMobile then
        local fab = Instance.new("TextButton"); fab.Name = "BW_FAB"
        fab.Size = UDim2.new(0, 56 * scale, 0, 56 * scale)
        fab.Position = UDim2.new(1, -(70 * scale), 1, -(80 * scale))
        fab.BackgroundColor3 = C.Accent; fab.BorderSizePixel = 0; fab.Text = "⚔️"
        fab.TextSize = 24; fab.Font = Enum.Font.GothamBold
        fab.TextColor3 = Color3.new(1, 1, 1); fab.ZIndex = 100; fab.Parent = sg
        corner(fab, 28)

        local fs = Instance.new("ImageLabel")
        fs.Size = UDim2.new(1, 40, 1, 40); fs.Position = UDim2.new(0.5, 0, 0.5, 4)
        fs.AnchorPoint = Vector2.new(0.5, 0.5); fs.BackgroundTransparency = 1
        fs.Image = "rbxassetid://6015897843"; fs.ImageColor3 = C.Accent
        fs.ImageTransparency = 0.5; fs.ScaleType = Enum.ScaleType.Slice
        fs.SliceCenter = Rect.new(49, 49, 450, 450); fs.ZIndex = 99; fs.Parent = fab

        fab.MouseButton1Click:Connect(function()
            self.Open = not self.Open; main.Visible = self.Open
        end)
        self.FAB = fab
    end

    -- ═══ Mobile Swipe ═══
    if BW.isMobile then
        local touchStart = nil
        main.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then touchStart = input.Position.X end
        end)
        main.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch and touchStart then
                local delta = input.Position.X - touchStart
                if math.abs(delta) > 60 then
                    local tabNames = {}
                    for name, _ in pairs(self.Pages) do table.insert(tabNames, name) end
                    if #tabNames > 1 then
                        local ci = 1
                        for i, n in ipairs(tabNames) do if n == self.CurrentPage then ci = i; break end end
                        local ni = delta > 0 and math.max(1, ci - 1) or math.min(#tabNames, ci + 1)
                        local b = self.TabButtons[tabNames[ni]]
                        if b then b.MouseButton1Click:Fire() end
                    end
                end
                touchStart = nil
            end
        end)
    end

    -- ═══ PC Toggle ═══
    if not BW.isMobile then
        BW.UserInputService.InputBegan:Connect(function(inp, gp)
            if not gp and inp.KeyCode == Enum.KeyCode.RightAlt then
                self.Open = not self.Open; main.Visible = self.Open
            end
        end)
    end

    cb.MouseButton1Click:Connect(function() self.Open = false; main.Visible = false end)

    -- ═══ Drag ═══
    do
        local drag, dStart, sPos = false, nil, nil
        tb.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                drag = true; dStart = input.Position; sPos = main.Position
            end
        end)
        BW.UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                drag = false
            end
        end)
        BW.UserInputService.InputChanged:Connect(function(input)
            if drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local d = input.Position - dStart
                main.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + d.X, sPos.Y.Scale, sPos.Y.Offset + d.Y)
            end
        end)
    end

    return self
end

-- ═══ Tab System ═══
function Library:Tab(name, icon)
    local page = {}
    local tabName = (icon or "") .. " " .. name
    local scale = BW.screenScale or 1

    -- Tab Button
    local btn = Instance.new("TextButton")
    if BW.isMobile then
        btn.Size = UDim2.new(0, math.floor(68 * scale), 0, 32)
    else
        btn.Size = UDim2.new(1, -8, 0, 30)
    end
    btn.BackgroundColor3 = C.Card; btn.BorderSizePixel = 0
    btn.Text = "  " .. tabName; btn.TextColor3 = C.TextDim
    btn.TextSize = sw(BW.isMobile, math.floor(10 * scale), 12)
    btn.Font = Enum.Font.GothamMedium; btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = self.Sidebar; corner(btn, 6)
    self.TabButtons[name] = btn

    -- Scroll Frame
    local pf = Instance.new("ScrollingFrame")
    pf.Size = UDim2.new(1, -12, 1, -12); pf.Position = UDim2.new(0, 6, 0, 6)
    pf.BackgroundTransparency = 1; pf.ScrollBarThickness = sw(BW.isMobile, 2, 3)
    pf.ScrollBarImageColor3 = C.Accent; pf.CanvasSize = UDim2.new(0, 0, 0, 0)
    pf.AutomaticCanvasSize = Enum.AutomaticSize.Y; pf.Visible = false
    pf.BorderSizePixel = 0; pf.Parent = self.Content
    local ll = Instance.new("UIListLayout", pf)
    ll.Padding = UDim.new(0, sw(BW.isMobile, 3, 4)); ll.SortOrder = Enum.SortOrder.LayoutOrder
    Instance.new("UIPadding", pf).PaddingLeft = UDim.new(0, 2)

    if not self.CurrentPage then
        self.CurrentPage = name; pf.Visible = true
        btn.BackgroundColor3 = C.Accent; btn.TextColor3 = Color3.new(1, 1, 1)
    end

    btn.MouseButton1Click:Connect(function()
        for _, c in pairs(self.Content:GetChildren()) do
            if c:IsA("ScrollingFrame") then c.Visible = false end
        end
        for _, c in pairs(self.Sidebar:GetChildren()) do
            if c:IsA("TextButton") then c.BackgroundColor3 = C.Card; c.TextColor3 = C.TextDim end
        end
        pf.Visible = true; btn.BackgroundColor3 = C.Accent; btn.TextColor3 = Color3.new(1, 1, 1)
        self.CurrentPage = name
    end)

    -- ═══ Toggle (Instance-based for click) ═══
    function page:Toggle(name, default, callback, category, tooltip)
        local cfg
        if type(name) == 'table' then
            cfg = name
        else
            cfg = {Name = name or 'Toggle', Flag = (name or 'Toggle'):gsub('%s+', ''), Default = default, Callback = callback}
        end
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, sw(BW.isMobile, 44, 36)); f.BackgroundColor3 = C.Card
        f.BorderSizePixel = 0; f.LayoutOrder = #pf:GetChildren() + 1; f.Parent = pf; corner(f, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.7, 0, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1; lbl.Text = cfg.Name; lbl.TextColor3 = C.Text
        lbl.TextSize = sw(BW.isMobile, 13, 12); lbl.Font = Enum.Font.GothamMedium
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f

        local tw = sw(BW.isMobile, 44, 36)
        local th = sw(BW.isMobile, 24, 20)
        local track = Instance.new("TextButton")
        track.Size = UDim2.new(0, tw, 0, th); track.Position = UDim2.new(1, -(tw + 10), 0.5, -(th / 2))
        track.BackgroundColor3 = sw(default, C.TogOn, C.TogOff); track.BorderSizePixel = 0
        track.Text = ""; track.Parent = f; corner(track, th / 2)

        local ks = sw(BW.isMobile, 20, 16)
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, ks, 0, ks)
        knob.Position = sw(default, UDim2.new(1, -(ks + 2), 0.5, -(ks / 2)), UDim2.new(0, 2, 0.5, -(ks / 2)))
        knob.BackgroundColor3 = Color3.new(1, 1, 1); knob.BorderSizePixel = 0; knob.Parent = track
        corner(knob, ks / 2)

        local on = sw(default, true, false)
        BW.Flags[cfg.Flag] = on

        local function doToggle()
            on = not on; BW.Flags[cfg.Flag] = on
            local nc = sw(on, C.TogOn, C.TogOff)
            local np = sw(on, UDim2.new(1, -(ks + 2), 0.5, -(ks / 2)), UDim2.new(0, 2, 0.5, -(ks / 2)))
            BW.TweenService:Create(track, TweenInfo.new(0.15, Enum.EasingStyle.Quart), {BackgroundColor3 = nc}):Play()
            BW.TweenService:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quart), {Position = np}):Play()
            pcall(function() if callback then callback(on) end end)
        end

        track.MouseButton1Click:Connect(doToggle)
        if BW.isMobile then
            f.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then doToggle() end
            end)
        end
    end

    -- ═══ Slider (Instance for drag) ═══
    function page:Slider(name, min, max, default, callback, category)
        local cfg
        if type(name) == 'table' then
            cfg = name
        else
            cfg = {Name = name or 'Slider', Min = min or 0, Max = max or 100, Default = default or 0, Flag = (name or 'Slider'):gsub('%s+', ''), Callback = callback}
        end
        local mn = cfg.Min or 0; local mx = cfg.Max or 100; local df = cfg.Default or 0

        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, sw(BW.isMobile, 56, 48)); f.BackgroundColor3 = C.Card
        f.BorderSizePixel = 0; f.LayoutOrder = #pf:GetChildren() + 1; f.Parent = pf; corner(f, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.6, 0, 0, 20); lbl.Position = UDim2.new(0, 12, 0, 6)
        lbl.BackgroundTransparency = 1; lbl.Text = cfg.Name; lbl.TextColor3 = C.Text
        lbl.TextSize = sw(BW.isMobile, 13, 12); lbl.Font = Enum.Font.GothamMedium
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f

        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.new(0.35, 0, 0, 20); valLbl.Position = UDim2.new(0.65, 0, 0, 6)
        valLbl.BackgroundTransparency = 1; valLbl.Text = tostring(df)
        valLbl.TextColor3 = C.Accent; valLbl.TextSize = 13
        valLbl.Font = Enum.Font.GothamBold; valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.Parent = f

        local tH = sw(BW.isMobile, 10, 6)
        local tY = sw(BW.isMobile, 36, 32)
        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -24, 0, tH); track.Position = UDim2.new(0, 12, 0, tY)
        track.BackgroundColor3 = C.SldBG; track.BorderSizePixel = 0; track.Parent = f; corner(track, tH / 2)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((df - mn) / (mx - mn), 0, 1, 0)
        fill.BackgroundColor3 = C.SldFill; fill.BorderSizePixel = 0; fill.Parent = track; corner(fill, tH / 2)

        local kS = sw(BW.isMobile, 18, 14)
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, kS, 0, kS)
        knob.Position = UDim2.new((df - mn) / (mx - mn), -(kS / 2), 0.5, -(kS / 2))
        knob.BackgroundColor3 = Color3.new(1, 1, 1); knob.BorderSizePixel = 0; knob.ZIndex = 2
        knob.Parent = track; corner(knob, kS / 2)

        BW.Flags[cfg.Flag] = df
        local dragging = false

        if BW.isMobile then
            local ta = Instance.new("TextButton")
            ta.Size = UDim2.new(1, 0, 0, 40); ta.Position = UDim2.new(0, 0, 0, tY - 12)
            ta.BackgroundTransparency = 1; ta.Text = ""; ta.Parent = f
            ta.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then dragging = true end end)
            ta.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
        else
            track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
            end)
        end

        BW.UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)

        BW.UserInputService.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local r = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                local v = math.floor(mn + r * (mx - mn) + 0.5)
                BW.Flags[cfg.Flag] = v; fill.Size = UDim2.new(r, 0, 1, 0)
                knob.Position = UDim2.new(r, -(kS / 2), 0.5, -(kS / 2))
                valLbl.Text = tostring(v)
                pcall(function() if callback then callback(v) end end)
            end
        end)
    end

    -- ═══ Dropdown ═══
    function page:Dropdown(cfg)
        local dv = sw(cfg.Default, cfg.Default, cfg.Options[1])
        local iH = sw(BW.isMobile, 34, 28)

        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, sw(BW.isMobile, 44, 36)); f.BackgroundColor3 = C.Card
        f.BorderSizePixel = 0; f.ClipsDescendants = true
        f.LayoutOrder = #pf:GetChildren() + 1; f.Parent = pf; corner(f, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.5, 0, 0, sw(BW.isMobile, 44, 36))
        lbl.Position = UDim2.new(0, 12, 0, 0); lbl.BackgroundTransparency = 1
        lbl.Text = cfg.Name; lbl.TextColor3 = C.Text
        lbl.TextSize = sw(BW.isMobile, 13, 12); lbl.Font = Enum.Font.GothamMedium
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f

        local sel = Instance.new("TextButton")
        sel.Size = UDim2.new(0.45, -8, 0, sw(BW.isMobile, 30, 26))
        sel.Position = UDim2.new(0.55, 0, 0, sw(BW.isMobile, 7, 5))
        sel.BackgroundColor3 = C.CardHov; sel.BorderSizePixel = 0
        sel.Text = "  " .. dv .. " ▾"; sel.TextColor3 = C.TextDim
        sel.TextSize = sw(BW.isMobile, 12, 11); sel.Font = Enum.Font.Gotham
        sel.TextXAlignment = Enum.TextXAlignment.Left; sel.Parent = f; corner(sel, 5)

        BW.Flags[cfg.Flag] = dv
        local open = false

        sel.MouseButton1Click:Connect(function()
            open = not open
            f.Size = UDim2.new(1, 0, 0, sw(open, sw(BW.isMobile, 44, 36) + #cfg.Options * iH + 4, sw(BW.isMobile, 44, 36)))
        end)

        for i, opt in ipairs(cfg.Options) do
            local ob = Instance.new("TextButton")
            ob.Size = UDim2.new(1, 0, 0, iH); ob.Position = UDim2.new(0, 0, 0, sw(BW.isMobile, 44, 36) + (i - 1) * iH)
            ob.BackgroundColor3 = C.Card; ob.BorderSizePixel = 0; ob.Text = "    " .. opt
            ob.TextColor3 = C.TextDim; ob.TextSize = sw(BW.isMobile, 12, 11)
            ob.Font = Enum.Font.Gotham; ob.TextXAlignment = Enum.TextXAlignment.Left; ob.Parent = f
            ob.MouseButton1Click:Connect(function()
                sel.Text = "  " .. opt .. " ▾"; BW.Flags[cfg.Flag] = opt; open = false
                f.Size = UDim2.new(1, 0, 0, sw(BW.isMobile, 44, 36))
            end)
        end
    end

    -- ═══ Button ═══
    function page:Button(cfg)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, sw(BW.isMobile, 40, 32))
        b.BackgroundColor3 = sw(cfg.Color, cfg.Color, C.AccentDk)
        b.BorderSizePixel = 0; b.Text = cfg.Name; b.TextColor3 = Color3.new(1, 1, 1)
        b.TextSize = sw(BW.isMobile, 14, 12); b.Font = Enum.Font.GothamBold
        b.LayoutOrder = #pf:GetChildren() + 1; b.Parent = pf; corner(b, 6)
        b.MouseButton1Click:Connect(function() pcall(function() if cfg.Callback then cfg.Callback() end end) end)
    end

    -- ═══ Label ═══
    function page:Label(text)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, sw(BW.isMobile, 24, 20)); l.BackgroundTransparency = 1
        l.Text = "  " .. text; l.TextColor3 = C.TextMut
        l.TextSize = sw(BW.isMobile, 11, 10); l.Font = Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Left; l.LayoutOrder = #pf:GetChildren() + 1; l.Parent = pf
    end

    -- ═══ Separator ═══
    function page:Separator()
        local s = Instance.new("Frame")
        s.Size = UDim2.new(1, -20, 0, 1); s.Position = UDim2.new(0, 10, 0, 0)
        s.BackgroundColor3 = C.Border; s.BorderSizePixel = 0
        s.LayoutOrder = #pf:GetChildren() + 1; s.Parent = pf
    end

    -- ═══ Input ═══
    function page:Input(cfg)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, sw(BW.isMobile, 44, 36)); f.BackgroundColor3 = C.Card
        f.BorderSizePixel = 0; f.LayoutOrder = #pf:GetChildren() + 1; f.Parent = pf; corner(f, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.4, 0, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1; lbl.Text = cfg.Name; lbl.TextColor3 = C.Text
        lbl.TextSize = sw(BW.isMobile, 13, 12); lbl.Font = Enum.Font.GothamMedium
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f

        local tb = Instance.new("TextBox")
        tb.Size = UDim2.new(0.55, -8, 0, sw(BW.isMobile, 30, 24))
        tb.Position = UDim2.new(0.45, 0, 0.5, sw(BW.isMobile, -15, -12))
        tb.BackgroundColor3 = C.CardHov; tb.BorderSizePixel = 0
        tb.Text = sw(cfg.Default, cfg.Default, ""); tb.TextColor3 = C.Text
        tb.PlaceholderText = sw(cfg.Placeholder, cfg.Placeholder, "")
        tb.PlaceholderColor3 = C.TextMut; tb.TextSize = sw(BW.isMobile, 12, 11)
        tb.Font = Enum.Font.Gotham; tb.ClearTextOnFocus = false; tb.Parent = f; corner(tb, 5)

        BW.Flags[cfg.Flag] = sw(cfg.Default, cfg.Default, "")
        tb.FocusLost:Connect(function() BW.Flags[cfg.Flag] = tb.Text end)
    end

    -- ═══ Drawing-based visual overlays (fast, no Instance overhead) ═══
    function page:DrawingRect(id, config)
        if not hasDrawing then return nil end
        local obj = ObjectPool:get("Square")
        if not obj then return nil end
        obj.Position = config.Position or Vector2.new(0, 0)
        obj.Size = config.Size or Vector2.new(100, 100)
        obj.Color = config.Color or C.Text
        obj.Filled = config.Filled ~= false
        obj.Thickness = config.Thickness or 1
        obj.Transparency = config.Transparency or 1
        obj.Visible = config.Visible ~= false
        self.DrawingObjects[id] = {type = "Square", obj = obj}
        RenderBatch:queue("draw_" .. id, function()
            if self.DrawingObjects[id] and self.DrawingObjects[id].obj then
                local cfg = self.DrawingObjects[id].config
                if cfg and cfg.Update then cfg.Update(self.DrawingObjects[id].obj) end
            end
        end)
        self.DrawingObjects[id].config = config
        return obj
    end

    function page:DrawingText(id, config)
        if not hasDrawing then return nil end
        local obj = ObjectPool:get("Text")
        if not obj then return nil end
        obj.Position = config.Position or Vector2.new(0, 0)
        obj.Text = config.Text or ""
        obj.Color = config.Color or C.Text
        obj.Size = config.Size or 13
        obj.Font = config.Font or 2
        obj.Visible = config.Visible ~= false
        self.DrawingObjects[id] = {type = "Text", obj = obj}
        RenderBatch:queue("draw_" .. id, function()
            if self.DrawingObjects[id] and self.DrawingObjects[id].obj then
                local cfg = self.DrawingObjects[id].config
                if cfg and cfg.Update then cfg.Update(self.DrawingObjects[id].obj) end
            end
        end)
        self.DrawingObjects[id].config = config
        return obj
    end

    function page:DrawingLine(id, config)
        if not hasDrawing then return nil end
        local obj = ObjectPool:get("Line")
        if not obj then return nil end
        obj.From = config.From or Vector2.new(0, 0)
        obj.To = config.To or Vector2.new(100, 100)
        obj.Color = config.Color or C.Text
        obj.Thickness = config.Thickness or 1
        obj.Visible = config.Visible ~= false
        self.DrawingObjects[id] = {type = "Line", obj = obj}
        return obj
    end

    function page:DrawingCircle(id, config)
        if not hasDrawing then return nil end
        local obj = ObjectPool:get("Circle")
        if not obj then return nil end
        obj.Position = config.Position or Vector2.new(0, 0)
        obj.Radius = config.Radius or 50
        obj.Color = config.Color or C.Text
        obj.Thickness = config.Thickness or 1
        obj.Visible = config.Visible ~= false
        self.DrawingObjects[id] = {type = "Circle", obj = obj}
        return obj
    end

    self.Pages[name] = page
    return page
end

-- ═══ Cleanup Drawing objects ═══
function Library:CleanupDrawings()
    for id, data in pairs(self.DrawingObjects or {}) do
        if data.obj then
            ObjectPool:put(data.type, data.obj)
        end
        RenderBatch:remove("draw_" .. id)
    end
    self.DrawingObjects = {}
end

BW.Library = Library
print("[UI] Library loaded v7.0 (Drawing + Instance hybrid)")
return Library
