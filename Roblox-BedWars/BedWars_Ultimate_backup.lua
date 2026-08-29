--[[
    BED WARS ULTIMATE v4.4 (Modular Build)
    90+ Features | Discord Webhook | Auto Buy
    Crystal Aura | 3-Wide Bridge | Anti Void
    Compatible with: Delta / Fluxus / Wave / Synapse / Potassium
    Game: https://www.roblox.com/games/6872265039
    Toggle UI: Right Alt (PC) / Close button (Mobile)
]]


-- core.lua
-- ══════════════════════════════════════════════════════════════
-- CORE MODULE (shared by all modules)
-- ══════════════════════════════════════════════════════════════

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- DEVICE DETECTION
local isMobile = false
local isTablet = false
local isPC = true
pcall(function()
    isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
    isTablet = UserInputService.TouchEnabled and UserInputService.MouseEnabled
    isPC = UserInputService.MouseEnabled and not UserInputService.TouchEnabled
    local viewportSize = Workspace.CurrentCamera.ViewportSize
    if viewportSize.X < 800 or viewportSize.Y < 600 then
        isMobile = true
        isPC = false
    elseif viewportSize.X < 1200 and viewportSize.Y < 800 then
        isTablet = true
    end
end)
local deviceType = isMobile and "Mobile" or (isTablet and "Tablet" or "PC")

-- CONFIG (save/load)
local Config = {
    DiscordWebhook = "",
    WebhookOnKill = true,
    WebhookOnBedBreak = true,
    WebhookOnDeath = true,
    WebhookOnVictory = true,
}
local CONFIG_PATH = "BedWars_Config.json"
local function SaveConfig()
    pcall(function()
        if writefile then writefile(CONFIG_PATH, HttpService:JSONEncode(Config)) end
    end)
end
local function LoadConfig()
    pcall(function()
        if readfile and isfile and isfile(CONFIG_PATH) then
            local data = HttpService:JSONDecode(readfile(CONFIG_PATH))
            for k, v in pairs(data) do Config[k] = v end
        end
    end)
end
LoadConfig()

-- DISCORD WEBHOOK
local function SendWebhook(title, description, color, thumbnail)
    if not Config.DiscordWebhook or Config.DiscordWebhook == "" then return end
    pcall(function()
        local data = {
            embeds = {{
                title = title, description = description, color = color or 3447003,
                thumbnail = (thumbnail and {url = thumbnail}) or nil,
                footer = {text = "BedWars Ultimate | " .. os.date("%H:%M:%S")},
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            }}
        }
        if syn and syn.request then
            syn.request({Url = Config.DiscordWebhook, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(data)})
        elseif http_request then
            http_request({Url = Config.DiscordWebhook, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(data)})
        elseif request then
            request({Url = Config.DiscordWebhook, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(data)})
        end
    end)
end

-- FLAGS
local Flags = {}

-- PERFORMANCE SYSTEM
local Perf = {}
Perf.Cache = {}
Perf.CacheTime = {}
Perf.Throttle = {}
Perf.Heartbeat = RunService.Heartbeat
Perf.LastFrame = tick()
Perf.FPS = 60
Perf.FrameCount = 0
Perf.LastFPSCheck = tick()
Perf.Descendants = {}
Perf.DescendantsTime = 0
Perf.DescendantsInterval = 2

function Perf:GetDescendants()
    local now = tick()
    if now - Perf.DescendantsTime > Perf.DescendantsInterval then
        Perf.Descendants = Workspace:GetDescendants()
        Perf.DescendantsTime = now
    end
    return Perf.Descendants
end

function Perf:GetDescendantsByName(name, interval)
    interval = interval or 3
    local key = "name_" .. name
    local now = tick()
    if not Perf.Cache[key] or (now - (Perf.CacheTime[key] or 0)) > interval then
        Perf.Cache[key] = {}
        for _, obj in pairs(Perf:GetDescendants()) do
            if obj.Name:lower():find(name:lower()) then table.insert(Perf.Cache[key], obj) end
        end
        Perf.CacheTime[key] = now
    end
    return Perf.Cache[key]
end

function Perf:GetDescendantsByClass(className, interval)
    interval = interval or 3
    local key = "class_" .. className
    local now = tick()
    if not Perf.Cache[key] or (now - (Perf.CacheTime[key] or 0)) > interval then
        Perf.Cache[key] = {}
        for _, obj in pairs(Perf:GetDescendants()) do
            if obj:IsA(className) then table.insert(Perf.Cache[key], obj) end
        end
        Perf.CacheTime[key] = now
    end
    return Perf.Cache[key]
end

function Perf:Throttle(name, interval, func)
    local now = tick()
    if not Perf.Throttle[name] or (now - Perf.Throttle[name]) >= interval then
        Perf.Throttle[name] = now
        func()
        return true
    end
    return false
end

function Perf:Debounce(name, func)
    if Perf.Throttle[name .. "_debounce"] then return false end
    Perf.Throttle[name .. "_debounce"] = true
    func()
    task.delay(0.01, function() Perf.Throttle[name .. "_debounce"] = false end)
    return true
end

Perf.Heartbeat:Connect(function()
    Perf.FrameCount = Perf.FrameCount + 1
    local now = tick()
    if now - Perf.LastFPSCheck >= 1 then
        Perf.FPS = Perf.FrameCount
        Perf.FrameCount = 0
        Perf.LastFPSCheck = now
    end
    Perf.LastFrame = now
end)

function Perf:GetMemory()
    return math.floor(collectgarbage("count") / 1024 * 100) / 100
end

function Perf:CleanupCache()
    for key, _ in pairs(Perf.Cache) do
        if Perf.CacheTime[key] and (tick() - Perf.CacheTime[key]) > 30 then
            Perf.Cache[key] = nil
            Perf.CacheTime[key] = nil
        end
    end
end

task.spawn(function()
    while true do Perf:CleanupCache(); task.wait(30) end
end)

-- UTILITY FUNCTIONS
local function char() return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() end
local function hrp() local c = LocalPlayer.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = LocalPlayer.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function alive()
    local c = LocalPlayer.Character
    if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    local r = c:FindFirstChild("HumanoidRootPart")
    return h and r and h.Health > 0
end

local function enemies()
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Team ~= LocalPlayer.Team then
            local c = p.Character
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                local r = c:FindFirstChild("HumanoidRootPart")
                if h and r and h.Health > 0 then
                    table.insert(t, {Player=p, Char=c, Hum=h, HRP=r})
                end
            end
        end
    end
    return t
end

local function nearestEnemy(maxD)
    maxD = maxD or math.huge
    local my = hrp()
    if not my then return nil, math.huge end
    local best, bd = nil, maxD
    for _, e in pairs(enemies()) do
        local d = (my.Position - e.HRP.Position).Magnitude
        if d < bd then bd = d; best = e end
    end
    return best, bd
end

local function hasLineOfSight(from, to)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = Workspace:Raycast(from, (to - from), rayParams)
    return not result or (result.Position - to).Magnitude < 3
end

local function getInventory()
    local c = LocalPlayer.Character
    if not c then return {}, 0, 0, 0, 0 end
    local tools, iron, gold, diamond, emerald = {}, 0, 0, 0, 0
    for _, t in pairs(c:GetChildren()) do if t:IsA("Tool") then table.insert(tools, t) end end
    pcall(function()
        local ls = LocalPlayer:FindFirstChild("leaderstats")
        if ls then
            iron = (ls:FindFirstChild("Iron") and ls.Iron.Value) or 0
            gold = (ls:FindFirstChild("Gold") and ls.Gold.Value) or 0
            diamond = (ls:FindFirstChild("Diamond") and ls.Diamond.Value) or 0
            emerald = (ls:FindFirstChild("Emerald") and ls.Emerald.Value) or 0
        end
    end)
    return tools, iron, gold, diamond, emerald
end

local function equipTool(name)
    local c = LocalPlayer.Character
    if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    for _, t in pairs(c:GetChildren()) do
        if t:IsA("Tool") and t.Name:lower():find(name:lower()) then
            if h then h:EquipTool(t) end
            return t
        end
    end
    for _, t in pairs(LocalPlayer.Backpack:GetChildren()) do
        if t:IsA("Tool") and t.Name:lower():find(name:lower()) then
            if h then h:EquipTool(t) end
            return t
        end
    end
    return nil
end

local function findTool(name)
    local c = LocalPlayer.Character
    local bp = LocalPlayer.Backpack
    for _, t in pairs(c and c:GetChildren() or {}) do
        if t:IsA("Tool") and t.Name:lower():find(name:lower()) then return t end
    end
    for _, t in pairs(bp and bp:GetChildren() or {}) do
        if t:IsA("Tool") and t.Name:lower():find(name:lower()) then return t end
    end
    return nil
end

local function buyItem(itemName)
    pcall(function()
        for _, r in pairs(ReplicatedStorage:GetDescendants()) do
            if r:IsA("RemoteEvent") and r.Name:lower():find("shop") then
                r:FireServer(itemName)
                return true
            end
        end
        local sg = LocalPlayer.PlayerGui:FindFirstChild("Shop") or LocalPlayer.PlayerGui:FindFirstChild("ItemShop")
        if sg then
            for _, btn in pairs(sg:GetDescendants()) do
                if btn:IsA("TextButton") and btn.Text:lower():find(itemName:lower()) then
                    btn.Activated:Fire()
                    return true
                end
            end
        end
    end)
    return false
end

-- Export to global table
BW = {
    Players = Players, RunService = RunService, UserInputService = UserInputService,
    ReplicatedStorage = ReplicatedStorage, Workspace = Workspace, TweenService = TweenService,
    StarterGui = StarterGui, VirtualInputManager = VirtualInputManager,
    TeleportService = TeleportService, HttpService = HttpService, Lighting = Lighting,
    LocalPlayer = LocalPlayer, Camera = Camera,
    isMobile = isMobile, isTablet = isTablet, isPC = isPC, deviceType = deviceType,
    Config = Config, SaveConfig = SaveConfig, LoadConfig = LoadConfig,
    SendWebhook = SendWebhook,
    Flags = Flags, Perf = Perf,
    char = char, hrp = hrp, hum = hum, alive = alive,
    enemies = enemies, nearestEnemy = nearestEnemy, hasLineOfSight = hasLineOfSight,
    getInventory = getInventory, equipTool = equipTool, findTool = findTool, buyItem = buyItem,
}

print("[Core] Loaded | Device: " .. deviceType)


-- ui.lua
-- ══════════════════════════════════════════════════════════════
-- UI LIBRARY MODULE
-- ══════════════════════════════════════════════════════════════
local Library = {}
Library.__index = Library

function Library:New(config)
    local self = setmetatable({}, Library)
    self.Flags = BW.Flags
    self.Config = config or {Title="BedWars", Sub="v4.4"}
    self.IsMobile = BW.isMobile or BW.isTablet

    if game.CoreGui:FindFirstChild("BW_UI") then game.CoreGui:FindFirstChild("BW_UI"):Destroy() end
    local sg = Instance.new("ScreenGui")
    sg.Name = "BW_UI"
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.Parent = game.CoreGui
    self.SG = sg

    local main = Instance.new("Frame")
    if BW.isMobile then
        main.Size = UDim2.new(0.95, 0, 0.7, 0)
        main.Position = UDim2.new(0.025, 0, 0.15, 0)
    elseif BW.isTablet then
        main.Size = UDim2.new(0.8, 0, 0.65, 0)
        main.Position = UDim2.new(0.1, 0, 0.175, 0)
    else
        main.Size = UDim2.new(0, 540, 0, 400)
        main.Position = UDim2.new(0.5, -270, 0.5, -200)
    end
    main.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.Parent = sg
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
    self.Main = main

    local sh = Instance.new("ImageLabel", main)
    sh.AnchorPoint = Vector2.new(0.5, 0.5)
    sh.Position = UDim2.new(0.5, 0, 0.5, 5)
    sh.Size = UDim2.new(1, 40, 1, 40)
    sh.BackgroundTransparency = 1
    sh.Image = "rbxassetid://6015897843"
    sh.ImageColor3 = Color3.new(0,0,0)
    sh.ImageTransparency = 0.6
    sh.ScaleType = Enum.ScaleType.Slice
    sh.SliceCenter = Rect.new(49,49,450,450)
    sh.ZIndex = -1

    local tb = Instance.new("Frame", main)
    tb.Size = UDim2.new(1, 0, 0, BW.isMobile and 50 or 38)
    tb.BackgroundColor3 = Color3.fromRGB(22, 22, 35)
    tb.BorderSizePixel = 0
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 12)

    local tl = Instance.new("TextLabel", tb)
    tl.Size = UDim2.new(0.5, 0, 1, 0)
    tl.Position = UDim2.new(0, 14, 0, 0)
    tl.BackgroundTransparency = 1
    tl.Text = "⚔️ " .. self.Config.Title .. " | " .. self.Config.Sub
    tl.TextColor3 = Color3.fromRGB(80, 180, 255)
    tl.TextSize = BW.isMobile and 16 or 14
    tl.Font = Enum.Font.GothamBold
    tl.TextXAlignment = Enum.TextXAlignment.Left

    local kb = Instance.new("TextLabel", tb)
    kb.Size = UDim2.new(0.5, -14, 1, 0)
    kb.Position = UDim2.new(0.5, 0, 0, 0)
    kb.BackgroundTransparency = 1
    kb.Text = BW.isMobile and "📱 Touch toggle" or "RightAlt toggle"
    kb.TextColor3 = Color3.fromRGB(100, 100, 120)
    kb.TextSize = BW.isMobile and 12 or 11
    kb.Font = Enum.Font.Gotham
    kb.TextXAlignment = Enum.TextXAlignment.Right

    local closeBtn = Instance.new("TextButton", tb)
    closeBtn.Size = UDim2.new(0, BW.isMobile and 40 or 30, 0, BW.isMobile and 36 or 26)
    closeBtn.Position = UDim2.new(1, BW.isMobile and -48 or -36, 0.5, BW.isMobile and -18 or -13)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.TextSize = BW.isMobile and 18 or 14
    closeBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

    local sidebar = Instance.new("Frame", main)
    if BW.isMobile then
        sidebar.Size = UDim2.new(1, -10, 0, 40)
        sidebar.Position = UDim2.new(0, 5, 0, 55)
        Instance.new("UIListLayout", sidebar).FillDirection = Enum.FillDirection.Horizontal
        Instance.new("UIListLayout", sidebar).Padding = UDim.new(0, 4)
    else
        sidebar.Size = UDim2.new(0, 110, 1, -48)
        sidebar.Position = UDim2.new(0, 5, 0, 43)
        Instance.new("UIListLayout", sidebar).Padding = UDim.new(0, 3)
    end
    sidebar.BackgroundTransparency = 1

    local content = Instance.new("Frame", main)
    if BW.isMobile then
        content.Size = UDim2.new(1, -10, 1, -110)
        content.Position = UDim2.new(0, 5, 0, 100)
    else
        content.Size = UDim2.new(1, -130, 1, -53)
        content.Position = UDim2.new(0, 120, 0, 48)
    end
    content.BackgroundColor3 = Color3.fromRGB(22, 22, 35)
    content.BorderSizePixel = 0
    Instance.new("UICorner", content).CornerRadius = UDim.new(0, 8)
    self.Content = content
    self.Sidebar = sidebar
    self.Open = true
    self.Pages = {}
    self.CurrentPage = nil

    if not BW.isMobile then
        BW.UserInputService.InputBegan:Connect(function(inp, gp)
            if not gp and inp.KeyCode == Enum.KeyCode.RightAlt then
                self.Open = not self.Open
                main.Visible = self.Open
            end
        end)
    end
    closeBtn.MouseButton1Click:Connect(function()
        self.Open = not self.Open
        main.Visible = self.Open
    end)
    return self
end

function Library:Tab(name, icon)
    local page = {}
    local tabName = (icon or "") .. " " .. name
    local btn = Instance.new("TextButton", self.Sidebar)
    if BW.isMobile then btn.Size = UDim2.new(0, 70, 1, 0); btn.TextSize = 10
    else btn.Size = UDim2.new(1, 0, 0, 28); btn.TextSize = 11 end
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    btn.BorderSizePixel = 0
    btn.Text = "  " .. tabName
    btn.TextColor3 = Color3.fromRGB(140, 140, 160)
    btn.Font = Enum.Font.GothamMedium
    btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local pf = Instance.new("ScrollingFrame", self.Content)
    pf.Size = UDim2.new(1, -8, 1, -8)
    pf.Position = UDim2.new(0, 4, 0, 4)
    pf.BackgroundTransparency = 1
    pf.ScrollBarThickness = 3
    pf.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
    pf.CanvasSize = UDim2.new(0, 0, 0, 0)
    pf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    pf.Visible = false
    Instance.new("UIListLayout", pf).Padding = UDim.new(0, 4)
    Instance.new("UIPadding", pf).PaddingLeft = UDim.new(0, 2)

    if not self.CurrentPage then
        self.CurrentPage = name
        pf.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(40, 70, 130)
        btn.TextColor3 = Color3.new(1, 1, 1)
    end

    btn.MouseButton1Click:Connect(function()
        for _, c in pairs(self.Content:GetChildren()) do if c:IsA("ScrollingFrame") then c.Visible = false end end
        for _, c in pairs(self.Sidebar:GetChildren()) do
            if c:IsA("TextButton") then c.BackgroundColor3 = Color3.fromRGB(30, 30, 45); c.TextColor3 = Color3.fromRGB(140, 140, 160) end
        end
        pf.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(40, 70, 130)
        btn.TextColor3 = Color3.new(1, 1, 1)
        self.CurrentPage = name
    end)

    function page:Toggle(cfg)
        local f = Instance.new("Frame", pf)
        f.Size = UDim2.new(1, 0, 0, BW.isMobile and 44 or 32)
        f.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
        f.BorderSizePixel = 0
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        local lbl = Instance.new("TextLabel", f)
        lbl.Size = UDim2.new(0.7, 0, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1; lbl.Text = cfg.Name
        lbl.TextColor3 = Color3.fromRGB(190, 190, 200); lbl.TextSize = BW.isMobile and 14 or 12
        lbl.Font = Enum.Font.GothamMedium; lbl.TextXAlignment = Enum.TextXAlignment.Left
        local tb = Instance.new("TextButton", f)
        tb.Size = UDim2.new(0, BW.isMobile and 50 or 40, 0, BW.isMobile and 26 or 20)
        tb.Position = UDim2.new(1, BW.isMobile and -60 or -50, 0.5, BW.isMobile and -13 or -10)
        tb.BackgroundColor3 = cfg.Default and Color3.fromRGB(70, 170, 70) or Color3.fromRGB(50, 50, 62)
        tb.BorderSizePixel = 0; tb.Text = ""
        Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 10)
        local ci = Instance.new("Frame", tb)
        ci.Size = UDim2.new(0, BW.isMobile and 20 or 16, 0, BW.isMobile and 20 or 16)
        ci.Position = cfg.Default and UDim2.new(1, BW.isMobile and -23 or -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        ci.BackgroundColor3 = Color3.new(1, 1, 1); ci.BorderSizePixel = 0
        Instance.new("UICorner", ci).CornerRadius = UDim.new(0, 8)
        local on = cfg.Default or false
        BW.Flags[cfg.Flag] = on
        tb.MouseButton1Click:Connect(function()
            on = not on; BW.Flags[cfg.Flag] = on
            BW.TweenService:Create(tb, TweenInfo.new(0.15), {BackgroundColor3 = on and Color3.fromRGB(70, 170, 70) or Color3.fromRGB(50, 50, 62)}):Play()
            BW.TweenService:Create(ci, TweenInfo.new(0.15), {Position = on and UDim2.new(1, BW.isMobile and -23 or -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)}):Play()
        end)
    end

    function page:Slider(cfg)
        local min, max, def = cfg.Min or 0, cfg.Max or 100, cfg.Default or 0
        local f = Instance.new("Frame", pf)
        f.Size = UDim2.new(1, 0, 0, 42); f.BackgroundColor3 = Color3.fromRGB(28, 28, 42); f.BorderSizePixel = 0
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        local lbl = Instance.new("TextLabel", f)
        lbl.Size = UDim2.new(0.55, 0, 0, 18); lbl.Position = UDim2.new(0, 10, 0, 3)
        lbl.BackgroundTransparency = 1; lbl.Text = cfg.Name
        lbl.TextColor3 = Color3.fromRGB(190, 190, 200); lbl.TextSize = 12
        lbl.Font = Enum.Font.GothamMedium; lbl.TextXAlignment = Enum.TextXAlignment.Left
        local vl = Instance.new("TextLabel", f)
        vl.Size = UDim2.new(0.4, 0, 0, 18); vl.Position = UDim2.new(0.6, 0, 0, 3)
        vl.BackgroundTransparency = 1; vl.Text = tostring(def)
        vl.TextColor3 = Color3.fromRGB(80, 180, 255); vl.TextSize = 12
        vl.Font = Enum.Font.GothamBold; vl.TextXAlignment = Enum.TextXAlignment.Right
        local bg = Instance.new("Frame", f)
        bg.Size = UDim2.new(1, -20, 0, 5); bg.Position = UDim2.new(0, 10, 0, 28)
        bg.BackgroundColor3 = Color3.fromRGB(45, 45, 60); bg.BorderSizePixel = 0
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 3)
        local fill = Instance.new("Frame", bg)
        fill.Size = UDim2.new((def - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(70, 150, 255); fill.BorderSizePixel = 0
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)
        local knob = Instance.new("Frame", bg)
        knob.Size = UDim2.new(0, 12, 0, 12)
        knob.Position = UDim2.new((def - min) / (max - min), -6, 0.5, -6)
        knob.BackgroundColor3 = Color3.new(1, 1, 1); knob.BorderSizePixel = 0
        Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 6)
        BW.Flags[cfg.Flag] = def
        local drag = false
        bg.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true end end)
        BW.UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)
        BW.UserInputService.InputChanged:Connect(function(i)
            if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
                local r = math.clamp((i.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
                local v = math.floor(min + r * (max - min) + 0.5)
                BW.Flags[cfg.Flag] = v
                fill.Size = UDim2.new(r, 0, 1, 0)
                knob.Position = UDim2.new(r, -6, 0.5, -6)
                vl.Text = tostring(v)
            end
        end)
    end

    function page:Dropdown(cfg)
        local f = Instance.new("Frame", pf)
        f.Size = UDim2.new(1, 0, 0, 32); f.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
        f.BorderSizePixel = 0; f.ClipsDescendants = true
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        local lbl = Instance.new("TextLabel", f)
        lbl.Size = UDim2.new(0.5, 0, 0, 32); lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1; lbl.Text = cfg.Name
        lbl.TextColor3 = Color3.fromRGB(190, 190, 200); lbl.TextSize = 12
        lbl.Font = Enum.Font.GothamMedium; lbl.TextXAlignment = Enum.TextXAlignment.Left
        local sel = Instance.new("TextButton", f)
        sel.Size = UDim2.new(0.45, -8, 0, 24); sel.Position = UDim2.new(0.55, 0, 0, 4)
        sel.BackgroundColor3 = Color3.fromRGB(40, 40, 55); sel.BorderSizePixel = 0
        sel.Text = "  " .. (cfg.Default or cfg.Options[1] or "")
        sel.TextColor3 = Color3.fromRGB(180, 180, 190); sel.TextSize = 11
        sel.Font = Enum.Font.Gotham; sel.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", sel).CornerRadius = UDim.new(0, 5)
        BW.Flags[cfg.Flag] = cfg.Default or cfg.Options[1]
        local open = false
        sel.MouseButton1Click:Connect(function()
            open = not open
            f.Size = UDim2.new(1, 0, 0, open and (32 + #cfg.Options * 26 + 4) or 32)
        end)
        for i, opt in ipairs(cfg.Options) do
            local ob = Instance.new("TextButton", f)
            ob.Size = UDim2.new(1, 0, 0, 24); ob.Position = UDim2.new(0, 0, 0, 32 + (i - 1) * 26)
            ob.BackgroundColor3 = Color3.fromRGB(35, 35, 50); ob.BorderSizePixel = 0
            ob.Text = "  " .. opt; ob.TextColor3 = Color3.fromRGB(170, 170, 180)
            ob.TextSize = 11; ob.Font = Enum.Font.Gotham; ob.TextXAlignment = Enum.TextXAlignment.Left
            ob.MouseButton1Click:Connect(function()
                sel.Text = "  " .. opt; BW.Flags[cfg.Flag] = opt
                open = false; f.Size = UDim2.new(1, 0, 0, 32)
            end)
        end
    end

    function page:Button(cfg)
        local b = Instance.new("TextButton", pf)
        b.Size = UDim2.new(1, 0, 0, 30); b.BackgroundColor3 = cfg.Color or Color3.fromRGB(45, 75, 130)
        b.BorderSizePixel = 0; b.Text = cfg.Name; b.TextColor3 = Color3.new(1, 1, 1)
        b.TextSize = 12; b.Font = Enum.Font.GothamBold
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        b.MouseButton1Click:Connect(function() if cfg.Callback then cfg.Callback() end end)
    end

    function page:Label(text)
        local l = Instance.new("TextLabel", pf)
        l.Size = UDim2.new(1, 0, 0, 20); l.BackgroundTransparency = 1; l.Text = text
        l.TextColor3 = Color3.fromRGB(100, 100, 120); l.TextSize = 10
        l.Font = Enum.Font.Gotham; l.TextXAlignment = Enum.TextXAlignment.Left
    end

    function page:Separator()
        local s = Instance.new("Frame", pf)
        s.Size = UDim2.new(1, 0, 0, 1); s.BackgroundColor3 = Color3.fromRGB(40, 40, 55); s.BorderSizePixel = 0
    end

    function page:Input(cfg)
        local f = Instance.new("Frame", pf)
        f.Size = UDim2.new(1, 0, 0, 32); f.BackgroundColor3 = Color3.fromRGB(28, 28, 42); f.BorderSizePixel = 0
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        local lbl = Instance.new("TextLabel", f)
        lbl.Size = UDim2.new(0.4, 0, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1; lbl.Text = cfg.Name
        lbl.TextColor3 = Color3.fromRGB(190, 190, 200); lbl.TextSize = 12
        lbl.Font = Enum.Font.GothamMedium; lbl.TextXAlignment = Enum.TextXAlignment.Left
        local tb = Instance.new("TextBox", f)
        tb.Size = UDim2.new(0.55, -8, 0, 22); tb.Position = UDim2.new(0.45, 0, 0.5, -11)
        tb.BackgroundColor3 = Color3.fromRGB(38, 38, 52); tb.BorderSizePixel = 0
        tb.Text = cfg.Default or ""; tb.TextColor3 = Color3.fromRGB(200, 200, 210)
        tb.PlaceholderText = cfg.Placeholder or ""; tb.PlaceholderColor3 = Color3.fromRGB(80, 80, 100)
        tb.TextSize = 11; tb.Font = Enum.Font.Gotham; tb.ClearTextOnFocus = false
        Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 5)
        BW.Flags[cfg.Flag] = cfg.Default or ""
        tb.FocusLost:Connect(function() BW.Flags[cfg.Flag] = tb.Text end)
    end

    self.Pages[name] = page
    return page
end

BW.Library = Library
print("[UI] Library loaded")


-- combat.lua
-- ══════════════════════════════════════════════════════════════
-- COMBAT MODULE
-- ══════════════════════════════════════════════════════════════

-- ═══ TAB ═══
local C = BW.Win:Tab("Combat", "⚔️")
C:Toggle({Name="Kill Aura", Flag="KA"})
C:Slider({Name="KA Range", Flag="KA_Range", Min=5, Max=20, Default=15})
C:Slider({Name="KA CPS", Flag="KA_CPS", Min=8, Max=20, Default=14})
C:Toggle({Name="KA Ray Check", Flag="KA_Ray"})
C:Toggle({Name="KA Target Nearest", Flag="KA_Nearest", Default=true})
C:Toggle({Name="KA Smooth Rotation", Flag="KA_SmoothRot", Default=true})
C:Slider({Name="KA Smoothness", Flag="KA_Smooth", Min=1, Max=10, Default=3})
C:Toggle({Name="KA Multi-Target", Flag="KA_MultiTarget"})
C:Slider({Name="KA Max Targets", Flag="KA_MaxTargets", Min=2, Max=5, Default=3})
C:Slider({Name="KA Rotation Speed", Flag="KA_RotSpeed", Min=0, Max=5, Default=0})
C:Separator()
C:Toggle({Name="Crystal Aura", Flag="CrystalAura"})
C:Slider({Name="Crystal Range", Flag="CA_Range", Min=2, Max=8, Default=4})
C:Slider({Name="CA Place Delay", Flag="CA_PlaceDelay", Min=0, Max=2, Default=0.3})
C:Slider({Name="CA Break Delay", Flag="CA_BreakDelay", Min=0, Max=1, Default=0.1})
C:Toggle({Name="CA Burst Mode", Flag="CA_Burst"})
C:Slider({Name="CA Break Range", Flag="CA_BreakRange", Min=3, Max=10, Default=6})
C:Separator()
C:Toggle({Name="Auto Clicker", Flag="AutoClick"})
C:Slider({Name="Click CPS", Flag="AC_CPS", Min=10, Max=20, Default=16})
C:Toggle({Name="TriggerBot", Flag="TriggerBot"})
C:Toggle({Name="NoClickDelay", Flag="NoClickDelay"})
C:Separator()
C:Label("-- Auto Shoot --")
C:Toggle({Name="Auto Shoot", Flag="AutoShoot"})
C:Slider({Name="Fire Rate", Flag="ShootRate", Min=1, Max=20, Default=5})
C:Slider({Name="Change Delay", Flag="ShootChangeDelay", Min=0, Max=5, Default=1})
C:Slider({Name="Switch Delay", Flag="ShootSwitchDelay", Min=0, Max=3, Default=0})
C:Dropdown({Name="Projectile Type", Flag="ProjType", Options={"Wled Projectiles","All Projectiles","Bow Only","Fireball Only"}, Default="Wled Projectiles"})
C:Toggle({Name="Auto Release (bow)", Flag="AutoRelease"})
C:Slider({Name="Release Charge %", Flag="ReleasePct", Min=10, Max=100, Default=90})
C:Slider({Name="Release Delay", Flag="ReleaseDelay", Min=0, Max=2, Default=0})
C:Separator()
C:Label("-- Projectile Aimbot --")
C:Toggle({Name="Projectile Aimbot", Flag="ProjAimbot"})
C:Dropdown({Name="Aim Mode", Flag="ProjAimMode", Options={"Mouse","Camera","Silent"}, Default="Mouse"})
C:Slider({Name="Aim FOV", Flag="ProjAimFOV", Min=10, Max=180, Default=120})
C:Toggle({Name="Prediction", Flag="ProjPrediction"})
C:Separator()
C:Toggle({Name="Reach Extend", Flag="Reach"})
C:Slider({Name="Reach Dist", Flag="ReachDist", Min=6, Max=20, Default=14})
C:Toggle({Name="Auto Sword", Flag="AutoSword"})
C:Toggle({Name="Velocity (Anti-KB)", Flag="Velocity"})
C:Toggle({Name="No Fall Damage", Flag="NoFall"})
C:Toggle({Name="Hitbox Expand", Flag="Hitbox"})
C:Slider({Name="Hitbox Size", Flag="HitboxSize", Min=5, Max=20, Default=10})
C:Toggle({Name="Auto Rod", Flag="AutoRod"})
C:Toggle({Name="AimAssist (Smooth)", Flag="AimAssist"})
C:Slider({Name="AA FOV", Flag="AA_FOV", Min=10, Max=180, Default=90})
C:Slider({Name="AA Smoothness", Flag="AA_Smooth", Min=1, Max=20, Default=5})
C:Toggle({Name="TargetStrafe", Flag="TargetStrafe"})
C:Slider({Name="Strafe Speed", Flag="StrafeSpeed", Min=1, Max=15, Default=5})
C:Toggle({Name="Sprint", Flag="AutoSprint"})
C:Toggle({Name="AutoTool", Flag="AutoTool"})

-- ═══ ENGINES ═══

-- Kill Aura
local function getTargetScore(e)
    local my = BW.hrp(); if not my or not e.HRP then return 0 end
    local dist = (my.Position - e.HRP.Position).Magnitude
    local hp = e.Hum.Health / e.Hum.MaxHealth
    return math.clamp(1 - dist/30, 0, 1) * 50 + (1 - hp) * 30 + ((e.HRP.Velocity.Magnitude > 5 and 20) or 0)
end

local function getSortedEnemies(range)
    local my = BW.hrp(); if not my then return {} end
    local sorted = {}
    for _, e in pairs(BW.enemies()) do
        local dist = (my.Position - e.HRP.Position).Magnitude
        if dist < range then
            local los = not BW.Flags.KA_Ray or BW.hasLineOfSight(my.Position, e.HRP.Position)
            if los then e.Score = getTargetScore(e); table.insert(sorted, e) end
        end
    end
    table.sort(sorted, function(a, b) return a.Score > b.Score end)
    return sorted
end

local function smoothRotateTo(pos, smooth)
    local my = BW.hrp(); if not my then return end
    local targetCF = CFrame.new(my.Position, Vector3.new(pos.X, my.Position.Y, pos.Z))
    my.CFrame = my.CFrame:Lerp(targetCF, math.clamp(1/(smooth or 3), 0.1, 1))
end

task.spawn(function()
    while true do
        if BW.Flags.KA and BW.alive() then
            local range = BW.Flags.KA_Range or 15
            local cps = BW.Flags.KA_CPS or 14
            local smooth = BW.Flags.KA_Smooth or 3
            local delay = 1 / (cps * 2)
            if BW.Flags.AutoSword then BW.equipTool("sword") end
            local targets = getSortedEnemies(range)
            if #targets > 0 then
                local my = BW.hrp()
                if my then
                    if BW.Flags.KA_MultiTarget then
                        local count = math.min(#targets, BW.Flags.KA_MaxTargets or 3)
                        for i = 1, count do
                            smoothRotateTo(targets[i].HRP.Position, smooth)
                            BW.VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                            task.wait(delay/count)
                            BW.VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
                            task.wait(delay/count)
                        end
                    else
                        smoothRotateTo(targets[1].HRP.Position, smooth)
                        local rotSpeed = BW.Flags.KA_RotSpeed or 0
                        if rotSpeed > 0 then
                            local angle = (tick() * rotSpeed * 360) % 360
                            my.CFrame = my.CFrame * CFrame.Angles(0, math.rad(angle), 0)
                        end
                        BW.VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                        task.wait(delay)
                        BW.VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
                    end
                end
            end
            task.wait(delay)
        else
            task.wait(0.1)
        end
    end
end)

-- Crystal Aura
local CA_Crystals = {}
local function findBestCrystalPos(eHRP)
    local my = BW.hrp(); if not my or not eHRP then return nil end
    local range = BW.Flags.CA_Range or 4
    local bestPos, bestScore = nil, -1
    for _, off in ipairs({Vector3.new(0,0,0),Vector3.new(2,0,0),Vector3.new(-2,0,0),Vector3.new(0,0,2),Vector3.new(0,0,-2),Vector3.new(2,0,2),Vector3.new(-2,0,-2),Vector3.new(2,0,-2),Vector3.new(-2,0,2)}) do
        local pos = eHRP.Position + off
        local d = (my.Position - pos).Magnitude
        if d < range then
            local score = (range - (eHRP.Position - pos).Magnitude) * 10 + (range - d) * 5
            local tooClose = false
            for _, c in pairs(CA_Crystals) do if (c - pos).Magnitude < 2 then tooClose = true; break end end
            if not tooClose and score > bestScore then bestScore = score; bestPos = pos end
        end
    end
    return bestPos
end

task.spawn(function()
    while true do
        if BW.Flags.CrystalAura and BW.alive() then
            local now = tick()
            local range = BW.Flags.CA_Range or 4
            -- Break
            local enemy = BW.nearestEnemy(BW.Flags.CA_BreakRange or 6)
            if enemy then
                for _, obj in pairs(BW.Workspace:GetDescendants()) do
                    if obj:IsA("Model") and obj.Name:lower():find("crystal") then
                        local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("Part")
                        if part and (enemy.HRP.Position - part.Position).Magnitude < 5 then
                            local my = BW.hrp()
                            if my then my.CFrame = CFrame.new(my.Position, part.Position) end
                            BW.equipTool("sword") or BW.equipTool("axe")
                            task.wait(0.05)
                            BW.VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                            task.wait(0.05)
                            BW.VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
                        end
                    end
                end
            end
            -- Place
            local enemy2 = BW.nearestEnemy(range)
            if enemy2 then
                local pos = findBestCrystalPos(enemy2.HRP)
                if pos then
                    local crystal = BW.findTool("crystal") or BW.findTool("tnt")
                    if crystal then
                        local h = BW.hum()
                        if h and crystal.Parent ~= BW.char() then h:EquipTool(crystal); task.wait(0.1) end
                        local remote = nil
                        for _, r in pairs(BW.ReplicatedStorage:GetDescendants()) do
                            if r:IsA("RemoteEvent") and (r.Name:lower():find("crystal") or r.Name:lower():find("place")) then remote = r; break end
                        end
                        if remote then remote:FireServer(pos)
                        else
                            local my = BW.hrp()
                            if my then my.CFrame = CFrame.new(my.Position, pos) end
                            BW.VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                            task.wait(0.03)
                            BW.VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
                        end
                    end
                end
            end
            task.wait(0.01)
        else
            task.wait(0.1)
        end
    end
end)

-- Auto Clicker
task.spawn(function()
    while true do
        if BW.Flags.AutoClick and BW.alive() then
            local d = 1 / (BW.Flags.AC_CPS or 16)
            BW.VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
            task.wait(d * 0.4)
            BW.VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
            task.wait(d * 0.6)
        else task.wait(0.5) end
    end
end)

-- TriggerBot
task.spawn(function()
    while true do
        if BW.Flags.TriggerBot and BW.alive() then
            local mouse = BW.LocalPlayer:GetMouse()
            if mouse and mouse.Target then
                for _, e in pairs(BW.enemies()) do
                    if mouse.Target:IsDescendantOf(e.Char) then
                        BW.VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                        task.wait(0.05)
                        BW.VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
                        break
                    end
                end
            end
        end
        task.wait(0.01)
    end
end)

-- NoClickDelay
task.spawn(function()
    while true do
        if BW.Flags.NoClickDelay and BW.alive() then
            BW.VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
            task.wait()
            BW.VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
            task.wait()
        else task.wait(0.2) end
    end
end)

-- Auto Rod
task.spawn(function()
    while true do
        if BW.Flags.AutoRod and BW.alive() then
            local enemy, dist = BW.nearestEnemy(18)
            if enemy and dist > 8 then
                if BW.equipTool("rod") then
                    local my = BW.hrp()
                    if my then my.CFrame = CFrame.new(my.Position, enemy.HRP.Position) end
                    BW.VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                    task.wait(0.15)
                    BW.VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
                    task.wait(0.3)
                end
            end
        end
        task.wait(0.5)
    end
end)

-- Velocity
task.spawn(function()
    while true do
        if BW.Flags.Velocity and BW.alive() then
            local c = BW.char()
            if c then
                for _, v in pairs(c:GetDescendants()) do
                    if (v:IsA("BodyVelocity") or v:IsA("BodyAngularVelocity")) and not v:GetAttribute("_BW_Own") then
                        v:Destroy()
                    end
                end
            end
        end
        task.wait(0.05)
    end
end)

-- Hitbox Expand
task.spawn(function()
    while true do
        if BW.Flags.Hitbox then
            local size = BW.Flags.HitboxSize or 10
            for _, e in pairs(BW.enemies()) do
                if not e.HRP:GetAttribute("_BW_Orig") then e.HRP:SetAttribute("_BW_Orig", e.HRP.Size.X) end
                e.HRP.Size = Vector3.new(size, size, size)
                e.HRP.Transparency = 0.6; e.HRP.Color = Color3.fromRGB(255,50,50); e.HRP.CanCollide = false
            end
        else
            for _, e in pairs(BW.enemies()) do
                if e.HRP:GetAttribute("_BW_Orig") then
                    local o = e.HRP:GetAttribute("_BW_Orig")
                    e.HRP.Size = Vector3.new(o,o,o); e.HRP.Transparency = 1
                    e.HRP:RemoveAttribute("_BW_Orig")
                end
            end
        end
        task.wait(0.1)
    end
end)

-- AimAssist
task.spawn(function()
    while true do
        if BW.Flags.AimAssist and BW.alive() then
            local fov = BW.Flags.AA_FOV or 90
            local smooth = BW.Flags.AA_Smooth or 5
            local enemy = BW.nearestEnemy(fov)
            if enemy then
                local my = BW.hrp()
                if my then
                    local targetPos = enemy.HRP.Position + Vector3.new(0,1,0)
                    local lookDir = (targetPos - Camera.CFrame.Position).Unit
                    local newLook = Camera.CFrame.LookVector:Lerp(lookDir, 1/smooth)
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + newLook)
                end
            end
        end
        task.wait(0.01)
    end
end)

-- AutoShoot
local lastShootTime = 0
local currentTarget = nil
task.spawn(function()
    while true do
        if BW.Flags.AutoShoot and BW.alive() then
            local now = tick()
            local enemy = BW.nearestEnemy(60)
            if enemy then currentTarget = enemy end
            if currentTarget and currentTarget.Hum.Health > 0 then
                local proj = nil
                for _, t in pairs(BW.char():GetChildren()) do if t:IsA("Tool") and t.Name:lower():find("bow") then proj = t; break end end
                if not proj then for _, t in pairs(BW.LocalPlayer.Backpack:GetChildren()) do if t:IsA("Tool") and t.Name:lower():find("bow") then proj = t; break end end end
                if proj then
                    if proj.Parent ~= BW.char() then BW.hum():EquipTool(proj); task.wait(0.1) end
                    local my = BW.hrp()
                    if my then my.CFrame = CFrame.new(my.Position, Vector3.new(currentTarget.HRP.Position.X, my.Position.Y, currentTarget.HRP.Position.Z)) end
                    if now - lastShootTime >= 1/(BW.Flags.ShootRate or 5) then
                        BW.VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                        task.wait(0.05)
                        BW.VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
                        lastShootTime = now
                    end
                end
            end
        else currentTarget = nil end
        task.wait(0.01)
    end
end)

-- AutoRelease
task.spawn(function()
    local charging = false
    local chargeStart = 0
    while true do
        if BW.Flags.AutoRelease and BW.alive() then
            if BW.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                if not charging then charging = true; chargeStart = tick() end
                local pct = (tick() - chargeStart) / 2.0
                if pct >= (BW.Flags.ReleasePct or 90) / 100 then
                    task.wait(BW.Flags.ReleaseDelay or 0)
                    BW.VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
                    charging = false; task.wait(0.3)
                end
            else charging = false end
        else charging = false end
        task.wait(0.01)
    end
end)

-- ProjectileAimbot
task.spawn(function()
    while true do
        if BW.Flags.ProjAimbot and BW.alive() then
            local fov = BW.Flags.ProjAimFOV or 120
            local enemy = BW.nearestEnemy(fov)
            if enemy then
                local targetPos = enemy.HRP.Position
                if BW.Flags.ProjPrediction then
                    local vel = enemy.HRP.Velocity
                    local dist = (BW.hrp().Position - targetPos).Magnitude
                    targetPos = targetPos + vel * (dist / 100)
                end
                if BW.Flags.ProjAimMode == "Mouse" then
                    local sp, onScr = Camera:WorldToViewportPoint(targetPos)
                    if onScr then pcall(function() mousemoveabs(sp.X, sp.Y) end) end
                elseif BW.Flags.ProjAimMode == "Camera" then
                    local lookDir = (targetPos - Camera.CFrame.Position).Unit
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Camera.CFrame.LookVector:Lerp(lookDir, 0.3))
                end
            end
        end
        task.wait(0.01)
    end
end)

-- TargetStrafe
task.spawn(function()
    local angle = 0
    while true do
        if BW.Flags.TargetStrafe and BW.alive() then
            local enemy = BW.nearestEnemy(20)
            if enemy then
                angle = angle + (BW.Flags.StrafeSpeed or 5)
                if angle >= 360 then angle = angle - 360 end
                local my = BW.hrp()
                if my then
                    local offset = Vector3.new(math.cos(math.rad(angle)) * 4, 0, math.sin(math.rad(angle)) * 4)
                    my.Velocity = (enemy.HRP.Position + offset - my.Position).Unit * (BW.Flags.StrafeSpeed or 5) * 2
                end
            end
        end
        task.wait()
    end
end)

-- AutoSprint
task.spawn(function()
    while true do
        if BW.Flags.AutoSprint and BW.alive() then
            local h = BW.hum()
            if h then h.WalkSpeed = math.max(h.WalkSpeed, 16) end
        end
        task.wait(0.5)
    end
end)

print("[Combat] Module loaded")


-- world.lua
-- ══════════════════════════════════════════════════════════════
-- WORLD MODULE
-- ══════════════════════════════════════════════════════════════
local W = BW.Win:Tab("World", "🌍")
W:Toggle({Name="Auto Scaffold", Flag="Scaffold"})
W:Toggle({Name="Scaffold Tower", Flag="ScaffoldTower"})
W:Dropdown({Name="Bridge Width", Flag="BridgeWidth", Options={"1x","2x","3x"}, Default="3x"})
W:Toggle({Name="Safe Scaffold", Flag="SafeScaffold"})
W:Slider({Name="Bridge Speed", Flag="BridgeSpeed", Min=0.01, Max=0.2, Default=0.05})
W:Slider({Name="Blocks Ahead", Flag="ScaffoldAhead", Min=1, Max=4, Default=2})
W:Toggle({Name="Scaffold Auto Buy", Flag="ScaffoldAutoBuy"})
W:Separator()
W:Toggle({Name="Nuker", Flag="Nuker"})
W:Slider({Name="Nuker Range", Flag="NukerRange", Min=2, Max=6, Default=4})
W:Toggle({Name="Nuker Beds Only", Flag="NukerBeds"})
W:Separator()
W:Toggle({Name="Auto Collect", Flag="AutoCollect"})
W:Slider({Name="Collect Range", Flag="CollectRange", Min=5, Max=25, Default=15})
W:Toggle({Name="Collect Iron", Flag="AC_Iron", Default=true})
W:Toggle({Name="Collect Gold", Flag="AC_Gold", Default=true})
W:Toggle({Name="Collect Diamond", Flag="AC_Diamond", Default=true})
W:Toggle({Name="Collect Emerald", Flag="AC_Emerald", Default=true})
W:Separator()
W:Toggle({Name="Auto Farm", Flag="AutoFarm"})
W:Dropdown({Name="Farm Target", Flag="FarmTarget", Options={"Iron Only","Iron + Gold","All Resources"}, Default="Iron Only"})
W:Slider({Name="Farm Speed", Flag="FarmSpeed", Min=8, Max=50, Default=20})
W:Toggle({Name="Farm Return Base", Flag="FarmReturn"})
W:Toggle({Name="Farm Avoid Enemies", Flag="FarmAvoid"})
W:Toggle({Name="Farm Auto Buy Blocks", Flag="FarmBuyBlocks"})
W:Separator()
W:Toggle({Name="Auto Break Bed", Flag="AutoBreakBed"})
W:Toggle({Name="BedProtector", Flag="BedProtector"})
W:Toggle({Name="SafeWalk", Flag="SafeWalk"})
W:Toggle({Name="Xray", Flag="Xray"})
W:Toggle({Name="Freecam", Flag="Freecam"})
W:Toggle({Name="ChestSteal", Flag="ChestSteal"})
W:Toggle({Name="PickupRange", Flag="PickupRange"})
W:Slider({Name="Pickup Dist", Flag="PickupDist", Min=5, Max=30, Default=15})

-- ═══ ENGINES ═══

-- Auto Scaffold
local function findBestBlock()
    local priorities = {"obsidian","endstone","stone","wool","clay","wood","plank","glass","block"}
    local c = BW.char()
    if c then for _, t in pairs(c:GetChildren()) do if t:IsA("Tool") then for _, p in ipairs(priorities) do if t.Name:lower():find(p) then return t end end end end end
    for _, t in pairs(BW.LocalPlayer.Backpack:GetChildren()) do if t:IsA("Tool") then for _, p in ipairs(priorities) do if t.Name:lower():find(p) then return t end end end end
    return nil
end

local function placeBlock(pos)
    local r = BW.ReplicatedStorage:FindFirstChild("BlockPlace") or BW.ReplicatedStorage:FindFirstChild("PlaceBlock") or BW.ReplicatedStorage:FindFirstChild("BuildBlock")
    if r then r:FireServer(pos, 0); return true end
    return false
end

task.spawn(function()
    while true do
        if BW.Flags.Scaffold and BW.alive() then
            local my = BW.hrp()
            if my then
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {BW.char()}
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                local result = BW.Workspace:Raycast(my.Position, Vector3.new(0,-4,0), rayParams)
                if not result then
                    local block = findBestBlock()
                    if block then
                        local h = BW.hum()
                        if h and block.Parent ~= BW.char() then h:EquipTool(block); task.wait(0.05) end
                        local look = my.CFrame.LookVector
                        local right = my.CFrame.RightVector
                        local pos = my.Position - Vector3.new(0,3,0)
                        local ahead = BW.Flags.ScaffoldAhead or 2
                        local positions = {}
                        for i = 1, ahead do table.insert(positions, pos + look * (i*2)) end
                        local w = BW.Flags.BridgeWidth or "3x"
                        if w == "2x" or w == "3x" then for i = 1, ahead do table.insert(positions, pos + look*(i*2) + right*2) end end
                        if w == "3x" then for i = 1, ahead do table.insert(positions, pos + look*(i*2) - right*2) end end
                        for _, p in ipairs(positions) do placeBlock(p) end
                    elseif BW.Flags.ScaffoldAutoBuy then
                        local _, iron = BW.getInventory()
                        if iron >= 12 then BW.buyItem("Wool") end
                    end
                elseif BW.Flags.ScaffoldTower then
                    local h = BW.hum()
                    if h then
                        h.Jump = true; task.wait(0.1)
                        local block = findBestBlock()
                        if block then if block.Parent ~= BW.char() then h:EquipTool(block) end; placeBlock(my.Position - Vector3.new(0,3,0)) end
                    end
                end
                if BW.Flags.SafeScaffold then
                    local below = BW.Workspace:Raycast(my.Position, Vector3.new(0,-6,0), rayParams)
                    if not below then local block = findBestBlock() if block then if block.Parent ~= BW.char() then BW.hum():EquipTool(block) end; placeBlock(my.Position - Vector3.new(0,3,0)) end end
                end
            end
            task.wait(BW.Flags.BridgeSpeed or 0.05)
        else task.wait(0.1) end
    end
end)

-- Nuker
task.spawn(function()
    while true do
        if BW.Flags.Nuker and BW.alive() then
            local my = BW.hrp()
            if my then
                local range = BW.Flags.NukerRange or 4
                BW.equipTool("pickaxe") or BW.equipTool("axe") or BW.equipTool("sword")
                for _, obj in pairs(BW.Workspace:GetDescendants()) do
                    if BW.Flags.NukerBeds then
                        if obj.Name == "Bed" and obj:IsA("Model") then
                            local tag = obj:FindFirstChild("Team")
                            if not (tag and tag:IsA("StringValue") and tag.Value == (BW.LocalPlayer.Team and BW.LocalPlayer.Team.Name or "")) then
                                local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("Part")
                                if part and (my.Position - part.Position).Magnitude < 8 then
                                    my.CFrame = CFrame.new(my.Position, part.Position)
                                    BW.VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1); task.wait(0.1)
                                    BW.VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1); task.wait(0.15)
                                end
                            end
                        end
                    elseif obj:IsA("BasePart") and not obj:IsDescendantOf(BW.char() or game) then
                        if (my.Position - obj.Position).Magnitude < range and obj.Anchored then
                            my.CFrame = CFrame.new(my.Position, obj.Position)
                            BW.VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1); task.wait(0.1)
                            BW.VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1); task.wait(0.15)
                        end
                    end
                end
            end
        end
        task.wait(0.2)
    end
end)

-- Auto Collect
task.spawn(function()
    while true do
        if BW.Flags.AutoCollect and BW.alive() then
            local my = BW.hrp()
            if my then
                for _, obj in pairs(BW.Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        local n = obj.Name:lower()
                        local isRes = (BW.Flags.AC_Iron and n:find("iron")) or (BW.Flags.AC_Gold and n:find("gold")) or (BW.Flags.AC_Diamond and n:find("diamond")) or (BW.Flags.AC_Emerald and n:find("emerald"))
                        if isRes and (my.Position - obj.Position).Magnitude < (BW.Flags.CollectRange or 15) then
                            my.CFrame = CFrame.new(obj.Position + Vector3.new(0,2,0)); task.wait(0.1)
                        end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

-- Auto Break Bed
task.spawn(function()
    while true do
        if BW.Flags.AutoBreakBed and BW.alive() then
            local my = BW.hrp()
            if my then
                for _, obj in pairs(BW.Workspace:GetDescendants()) do
                    if obj.Name == "Bed" and obj:IsA("Model") then
                        local tag = obj:FindFirstChild("Team")
                        if not (tag and tag:IsA("StringValue") and tag.Value == (BW.LocalPlayer.Team and BW.LocalPlayer.Team.Name or "")) then
                            local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("Part")
                            if part and (my.Position - part.Position).Magnitude < 8 then
                                my.CFrame = CFrame.new(my.Position, part.Position)
                                BW.equipTool("axe") or BW.equipTool("pickaxe") or BW.equipTool("sword")
                                task.wait(0.05)
                                BW.VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1); task.wait(0.1)
                                BW.VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.2)
    end
end)

-- BedProtector
task.spawn(function()
    while true do
        if BW.Flags.BedProtector and BW.alive() then
            local my = BW.hrp()
            if my then
                for _, obj in pairs(BW.Workspace:GetDescendants()) do
                    if obj.Name == "Bed" and obj:IsA("Model") then
                        local tag = obj:FindFirstChild("Team")
                        if tag and tag:IsA("StringValue") and tag.Value == (BW.LocalPlayer.Team and BW.LocalPlayer.Team.Name or "") then
                            local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("Part")
                            if part and (my.Position - part.Position).Magnitude < 15 then
                                local block = BW.findTool("wool") or BW.findTool("block")
                                if block then
                                    BW.equipTool(block.Name); task.wait(0.05)
                                    for _, off in ipairs({Vector3.new(3,0,0),Vector3.new(-3,0,0),Vector3.new(0,0,3),Vector3.new(0,0,-3),Vector3.new(3,3,0),Vector3.new(-3,3,0),Vector3.new(0,3,3),Vector3.new(0,3,-3)}) do
                                        placeBlock(part.Position + off); task.wait(0.05)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(2)
    end
end)

-- SafeWalk
task.spawn(function()
    while true do
        if BW.Flags.SafeWalk and BW.alive() then
            local my = BW.hrp()
            if my then
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {BW.char()}
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                local result = BW.Workspace:Raycast(my.Position - Vector3.new(0,0.5,0), my.CFrame.LookVector * 3, rayParams)
                if not result and not BW.Flags.Fly then
                    local h = BW.hum()
                    if h then
                        h.WalkSpeed = 0; task.wait(0.1)
                        h.WalkSpeed = BW.Flags.Speed and (BW.Flags.SpeedVal or 32) or 16
                    end
                end
            end
        end
        task.wait(0.05)
    end
end)

-- Xray
task.spawn(function()
    local xrayOrig = {}
    while true do
        if BW.Flags.Xray then
            for _, obj in pairs(BW.Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and not obj:IsDescendantOf(BW.char() or game.Players) then
                    if not xrayOrig[obj] then xrayOrig[obj] = obj.Transparency end
                    obj.Transparency = 0.8
                end
            end
        else
            for obj, orig in pairs(xrayOrig) do if obj and obj.Parent then obj.Transparency = orig end end
            xrayOrig = {}
        end
        task.wait(0.5)
    end
end)

-- ChestSteal
task.spawn(function()
    while true do
        if BW.Flags.ChestSteal and BW.alive() then
            local my = BW.hrp()
            if my then
                for _, obj in pairs(BW.Workspace:GetDescendants()) do
                    if obj:IsA("Model") and (obj.Name:lower():find("chest") or obj.Name:lower():find("container")) then
                        local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("Part")
                        if part and (my.Position - part.Position).Magnitude < 8 then
                            pcall(function()
                                local gui = BW.LocalPlayer.PlayerGui:FindFirstChild("Chest") or BW.LocalPlayer.PlayerGui:FindFirstChild("Container")
                                if gui then for _, btn in pairs(gui:GetDescendants()) do if btn:IsA("TextButton") or btn:IsA("ImageButton") then btn.Activated:Fire() end end end
                            end)
                        end
                    end
                end
            end
        end
        task.wait(1)
    end
end)

-- Freecam
task.spawn(function()
    local fcPos = nil
    while true do
        if BW.Flags.Freecam and BW.alive() then
            if not fcPos then fcPos = Camera.CFrame end
            Camera.CameraType = Enum.CameraType.Scriptable
            local sp = 2
            if BW.UserInputService:IsKeyDown(Enum.KeyCode.W) then fcPos = fcPos + fcPos.LookVector * sp end
            if BW.UserInputService:IsKeyDown(Enum.KeyCode.S) then fcPos = fcPos - fcPos.LookVector * sp end
            if BW.UserInputService:IsKeyDown(Enum.KeyCode.A) then fcPos = fcPos - fcPos.RightVector * sp end
            if BW.UserInputService:IsKeyDown(Enum.KeyCode.D) then fcPos = fcPos + fcPos.RightVector * sp end
            if BW.UserInputService:IsKeyDown(Enum.KeyCode.Space) then fcPos = fcPos + Vector3.new(0,sp,0) end
            Camera.CFrame = fcPos
        else
            if fcPos then Camera.CameraType = Enum.CameraType.Custom; fcPos = nil end
        end
        task.wait()
    end
end)

print("[World] Module loaded")


-- esp.lua
-- ══════════════════════════════════════════════════════════════
-- ESP MODULE
-- ══════════════════════════════════════════════════════════════
local E = BW.Win:Tab("ESP", "👁️")
E:Toggle({Name="Player ESP (Box)", Flag="ESP_Box"})
E:Toggle({Name="Player ESP (Name)", Flag="ESP_Name"})
E:Toggle({Name="Player ESP (Health)", Flag="ESP_Health"})
E:Toggle({Name="Player ESP (Distance)", Flag="ESP_Dist"})
E:Toggle({Name="Tracer ESP", Flag="ESP_Tracer"})
E:Separator()
E:Toggle({Name="Bed ESP", Flag="ESP_Bed"})
E:Toggle({Name="Item ESP", Flag="ESP_Item"})
E:Toggle({Name="Chest ESP", Flag="ESP_Chest"})
E:Toggle({Name="Shop NPC ESP", Flag="ESP_Shop"})
E:Toggle({Name="Resource Spawn ESP", Flag="ESP_Resource"})
E:Separator()
E:Toggle({Name="Team Check", Flag="ESP_TeamCheck", Default=true})
E:Label("-- Render Modules --")
E:Toggle({Name="Chams", Flag="Chams"})
E:Toggle({Name="Arrows (outside FOV)", Flag="Arrows"})
E:Toggle({Name="KitESP", Flag="KitESP"})
E:Toggle({Name="StorageESP", Flag="StorageESP"})
E:Toggle({Name="Waypoints", Flag="Waypoints"})
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

local function clearESP()
    for _, bb in pairs(ESP_BBs) do pcall(function() bb:Destroy() end) end
    ESP_BBs = {}
end

local function updateBedESP()
    for _, obj in pairs(BW.Workspace:GetDescendants()) do
        if obj.Name=="Bed" and obj:IsA("Model") then
            local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("Part")
            if part and not part:FindFirstChild("BW_BedESP") then
                local tag = obj:FindFirstChild("Team")
                local isEnemy = not (tag and tag:IsA("StringValue") and tag.Value==(BW.LocalPlayer.Team and BW.LocalPlayer.Team.Name or ""))
                if isEnemy then
                    local bb=Instance.new("BillboardGui"); bb.Name="BW_BedESP"; bb.Size=UDim2.new(0,80,0,25); bb.StudsOffset=Vector3.new(0,2,0); bb.AlwaysOnTop=true; bb.Adornee=part; bb.Parent=part
                    local lbl=Instance.new("TextLabel",bb); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=0.5; lbl.BackgroundColor3=Color3.fromRGB(0,0,0); lbl.Text="BED"; lbl.TextColor3=Color3.fromRGB(255,200,50); lbl.TextScaled=true; lbl.Font=Enum.Font.GothamBold
                    table.insert(ESP_BBs, bb)
                end
            end
        end
    end
end

local function updateResourceESP()
    for _, obj in pairs(BW.Workspace:GetDescendants()) do
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

local function updatePlayerESP()
    for _, e in pairs(BW.enemies()) do
        if BW.Flags.ESP_TeamCheck and e.Player.Team==BW.LocalPlayer.Team then goto continue_esp end
        local hrp2=e.HRP
        if hrp2 then
            local my=BW.hrp()
            local dist=(my and math.floor((my.Position-hrp2.Position).Magnitude)) or 0
            local pos, onScr=BW.Camera:WorldToViewportPoint(hrp2.Position)
            if onScr and (BW.Flags.ESP_Box or BW.Flags.ESP_Name or BW.Flags.ESP_Health or BW.Flags.ESP_Dist) then
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
                    if BW.Flags.ESP_Name then text=e.Player.Name end
                    if BW.Flags.ESP_Dist then text=text.." ["..dist.."m]" end
                    info.Text=text
                end
                if hpLbl then
                    local hpPct=e.Hum.Health/e.Hum.MaxHealth
                    hpLbl.Text=math.floor(e.Hum.Health).."/"..math.floor(e.Hum.MaxHealth)
                    hpLbl.TextColor3=hpPct>0.5 and Color3.fromRGB(0,255,0) or hpPct>0.25 and Color3.fromRGB(255,255,0) or Color3.fromRGB(255,0,0)
                end
            end
        end
        ::continue_esp::
    end
end

-- Main ESP loop
task.spawn(function()
    while true do
        local anyESP=BW.Flags.ESP_Box or BW.Flags.ESP_Name or BW.Flags.ESP_Health or BW.Flags.ESP_Dist
        if anyESP then BW.Perf:Throttle("ESP_Players",0.5,function() pcall(updatePlayerESP) end) end
        if BW.Flags.ESP_Bed then BW.Perf:Throttle("ESP_Beds",3,function() pcall(updateBedESP) end) end
        if BW.Flags.ESP_Resource then BW.Perf:Throttle("ESP_Res",3,function() pcall(updateResourceESP) end) end
        if BW.Flags.Chams then BW.Perf:Throttle("ESP_Chams",2,function() pcall(updateChams) end)
        else BW.Perf:Throttle("Chams_Clear",5,function() pcall(clearChams) end) end
        task.wait(0.1)
    end
end)

-- Arrows
task.spawn(function()
    local arrowDraws={}
    while true do
        for _, a in pairs(arrowDraws) do pcall(function() a:Remove() end) end
        arrowDraws={}
        if BW.Flags.Arrows then
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
                        table.insert(arrowDraws, arrow)
                    end
                end
            end)
        end
        task.wait(0.1)
    end
end)

print("[ESP] Module loaded")


-- move.lua
-- ══════════════════════════════════════════════════════════════
-- MOVEMENT MODULE
-- ══════════════════════════════════════════════════════════════
local M = BW.Win:Tab("Move", "🏃")
M:Toggle({Name="Speed", Flag="Speed"})
M:Slider({Name="Speed Value", Flag="SpeedVal", Min=16, Max=100, Default=32})
M:Toggle({Name="Fly", Flag="Fly"})
M:Slider({Name="Fly Speed", Flag="FlySpeed", Min=1, Max=30, Default=8})
M:Toggle({Name="Long Jump", Flag="LongJump"})
M:Slider({Name="LJ Power", Flag="LJPower", Min=30, Max=100, Default=50})
M:Toggle({Name="High Jump", Flag="HighJump"})
M:Slider({Name="Jump Power", Flag="JumpPower", Min=50, Max=200, Default=100})
M:Toggle({Name="Inf Jump", Flag="InfJump"})
M:Toggle({Name="NoClip", Flag="NoClip"})
M:Toggle({Name="Anti Void", Flag="AntiVoid"})
M:Toggle({Name="Phase", Flag="Phase"})
M:Toggle({Name="Invisible", Flag="Invisible"})
M:Slider({Name="Invis Level", Flag="InvisLevel", Min=1, Max=10, Default=5})
M:Toggle({Name="MouseTP", Flag="MouseTP"})
M:Toggle({Name="NoSlowdown", Flag="NoSlowdown"})
M:Toggle({Name="Spider", Flag="Spider"})
M:Toggle({Name="Swim", Flag="Swim"})
M:Toggle({Name="Gravity", Flag="Gravity"})
M:Slider({Name="Gravity Value", Flag="GravVal", Min=0, Max=200, Default=100})
M:Toggle({Name="Spin Bot", Flag="SpinBot"})
M:Slider({Name="Spin Speed", Flag="SpinSpeed", Min=1, Max=30, Default=10})

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
            if BW.Flags.Speed then h.WalkSpeed = BW.Flags.SpeedVal or 32
            elseif h.WalkSpeed > 16 then h.WalkSpeed = 16 end
            -- High Jump
            if BW.Flags.HighJump then h.JumpPower = BW.Flags.JumpPower or 100 end
            -- Fly
            if BW.Flags.Fly then
                if not flyBV then flyBV=Instance.new("BodyVelocity"); flyBV.Name="_BW_Fly"; flyBV.MaxForce=Vector3.new(math.huge,math.huge,math.huge); flyBV.P=10000; flyBV.Parent=my end
                flyBV.Velocity=Vector3.new(0,0,0)
                local sp=BW.Flags.FlySpeed or 8; local cam=BW.Camera.CFrame
                if BW.UserInputService:IsKeyDown(Enum.KeyCode.W) then flyBV.Velocity=flyBV.Velocity+cam.LookVector*sp end
                if BW.UserInputService:IsKeyDown(Enum.KeyCode.S) then flyBV.Velocity=flyBV.Velocity-cam.LookVector*sp end
                if BW.UserInputService:IsKeyDown(Enum.KeyCode.A) then flyBV.Velocity=flyBV.Velocity-cam.RightVector*sp end
                if BW.UserInputService:IsKeyDown(Enum.KeyCode.D) then flyBV.Velocity=flyBV.Velocity+cam.RightVector*sp end
                if BW.UserInputService:IsKeyDown(Enum.KeyCode.Space) then flyBV.Velocity=flyBV.Velocity+Vector3.new(0,sp,0) end
                if BW.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then flyBV.Velocity=flyBV.Velocity-Vector3.new(0,sp,0) end
            else if flyBV then flyBV:Destroy(); flyBV=nil end end
            -- NoClip
            if BW.Flags.NoClip then for _, p in pairs(BW.char():GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end
            -- Anti Void
            if BW.Flags.AntiVoid then
                local pos=my.Position
                if pos.Y>0 then lastSafePos=pos end
                if pos.Y<-50 and lastSafePos then my.CFrame=CFrame.new(lastSafePos) end
            end
            -- Gravity
            if BW.Flags.Gravity then BW.Workspace.Gravity=BW.Flags.GravVal or 100
            elseif BW.Workspace.Gravity~=196.2 then BW.Workspace.Gravity=196.2 end
            -- Swim
            if BW.Flags.Swim then h:ChangeState(Enum.HumanoidStateType.Swimming) end
            -- Phase
            if BW.Flags.Phase then h.PlatformStand=true; task.wait(0.1); h.PlatformStand=false end
            -- Invisible
            if BW.Flags.Invisible then
                local lv=(BW.Flags.InvisLevel or 5)/10
                for _, p in pairs(BW.char():GetDescendants()) do
                    if p:IsA("BasePart") then p.Transparency=lv
                    elseif p:IsA("Decal") then p.Transparency=lv end
                end
            end
        end
        task.wait(0.05)
    end
end)

-- Long Jump
task.spawn(function()
    while true do
        if BW.Flags.LongJump and BW.alive() then
            local h=BW.hum(); local my=BW.hrp()
            if h and my and h:GetState()==Enum.HumanoidStateType.Freefall then
                local p=BW.Flags.LJPower or 50; local v=my.Velocity
                my.Velocity=Vector3.new(v.X*p/50,40,v.Z*p/50)
            end
        end
        task.wait(0.1)
    end
end)

-- Inf Jump
BW.UserInputService.JumpRequest:Connect(function()
    if BW.Flags.InfJump and BW.alive() then local h=BW.hum() if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)

-- MouseTP
BW.UserInputService.InputBegan:Connect(function(input,gp)
    if gp then return end
    if BW.Flags.MouseTP and input.UserInputType==Enum.UserInputType.MouseButton2 then
        local mouse=BW.LocalPlayer:GetMouse()
        if mouse and mouse.Hit then local my=BW.hrp() if my then my.CFrame=CFrame.new(mouse.Hit.Position+Vector3.new(0,3,0)) end end
    end
end)

-- Spider
task.spawn(function()
    while true do
        if BW.Flags.Spider and BW.alive() then
            local my=BW.hrp(); local h=BW.hum()
            if my and h then
                local rp=RaycastParams.new(); rp.FilterDescendantsInstances={BW.char()}; rp.FilterType=Enum.RaycastFilterType.Exclude
                local r=BW.Workspace:Raycast(my.Position,my.CFrame.LookVector*2,rp)
                if r then h.WalkSpeed=0; my.Velocity=Vector3.new(0,30,0)
                else h.WalkSpeed=BW.Flags.Speed and (BW.Flags.SpeedVal or 32) or 16 end
            end
        end
        task.wait(0.05)
    end
end)

-- Spin Bot
task.spawn(function()
    local angle=0
    while true do
        if BW.Flags.SpinBot and BW.alive() then
            local my=BW.hrp()
            if my then angle=angle+(BW.Flags.SpinSpeed or 10); if angle>=360 then angle=angle-360 end
            my.CFrame=CFrame.new(my.Position)*CFrame.Angles(0,math.rad(angle),0) end
        end
        task.wait()
    end
end)

print("[Move] Module loaded")


-- shop.lua
-- ══════════════════════════════════════════════════════════════
-- SHOP MODULE
-- ══════════════════════════════════════════════════════════════
local S = BW.Win:Tab("Shop", "🛒")
S:Toggle({Name="Auto Buy Sword", Flag="AB_Sword"})
S:Toggle({Name="Auto Buy Armor", Flag="AB_Armor"})
S:Toggle({Name="Auto Buy Blocks", Flag="AB_Blocks"})
S:Toggle({Name="Auto Buy Tools", Flag="AB_Tools"})
S:Toggle({Name="Auto Buy Projectiles", Flag="AB_Proj"})
S:Toggle({Name="Auto Buy Endstone", Flag="AB_Endstone"})
S:Toggle({Name="Auto Buy Upgrades", Flag="AB_Upgrade"})
S:Dropdown({Name="Buy Priority", Flag="AB_Priority", Options={"Sword > Armor > Blocks > Tools","Blocks > Sword > Armor > Tools","Armor > Sword > Blocks > Tools"}, Default="Sword > Armor > Blocks > Tools"})
S:Toggle({Name="ShopTierBypass", Flag="ShopTierBypass"})

-- ═══ ENGINE ═══
local function findShopNPC()
    for _, obj in pairs(BW.Workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("shop") or obj.Name:lower():find("merchant") or obj.Name:lower():find("vendor")) then return obj end
    end
    return nil
end

task.spawn(function()
    while true do
        if BW.alive() then
            local shop=findShopNPC()
            if shop then
                local my=BW.hrp()
                if my then
                    local part=shop.PrimaryPart or shop:FindFirstChildWhichIsA("Part")
                    if part and (my.Position-part.Position).Magnitude<15 then
                        local _,iron,gold,diamond,emerald=BW.getInventory()
                        if BW.Flags.AB_Sword then
                            if emerald>=4 then BW.buyItem("Emerald Sword")
                            elseif gold>=7 then BW.buyItem("Diamond Sword")
                            elseif gold>=3 then BW.buyItem("Stone Sword") end
                        end
                        if BW.Flags.AB_Armor then
                            if emerald>=6 then BW.buyItem("Emerald Armor")
                            elseif diamond>=4 then BW.buyItem("Diamond Armor")
                            elseif iron>=40 then BW.buyItem("Iron Armor") end
                        end
                        if BW.Flags.AB_Blocks and iron>=12 then BW.buyItem("Wool") end
                        if BW.Flags.AB_Tools and iron>=10 then BW.buyItem("Pickaxe") end
                        if BW.Flags.AB_Proj and gold>=2 then BW.buyItem("Fireball") end
                        if BW.Flags.AB_Endstone and iron>=20 then BW.buyItem("Endstone") end
                        if BW.Flags.AB_Upgrade then BW.buyItem("Sharpness"); BW.buyItem("Protection"); BW.buyItem("Haste") end
                    end
                end
            end
        end
        task.wait(3)
    end
end)

-- ShopTierBypass
task.spawn(function()
    while true do
        if BW.Flags.ShopTierBypass and BW.alive() then
            pcall(function()
                for _, r in pairs(BW.ReplicatedStorage:GetDescendants()) do
                    if r:IsA("RemoteEvent") and r.Name:lower():find("shop") then
                        r:FireServer("Diamond Armor"); r:FireServer("Emerald Armor"); r:FireServer("Diamond Sword"); r:FireServer("Emerald Sword")
                    end
                end
            end)
        end
        task.wait(5)
    end
end)

print("[Shop] Module loaded")


-- util.lua
-- ══════════════════════════════════════════════════════════════
-- UTILITY MODULE
-- ══════════════════════════════════════════════════════════════
local U = BW.Win:Tab("Util", "⚙️")
U:Toggle({Name="Anti AFK", Flag="AntiAFK"})
U:Toggle({Name="Staff Detection", Flag="StaffDetect"})
U:Toggle({Name="Anti Staff: Auto Disconnect", Flag="AntiStaffDC"})
U:Toggle({Name="Anti Staff: Auto Rejoin", Flag="AntiStaffRejoin"})
U:Toggle({Name="Anti Staff: Panic on Staff", Flag="AntiStaffPanic"})
U:Toggle({Name="Anti Staff: Chat Warn", Flag="AntiStaffChat"})
U:Toggle({Name="Anti Staff: Full Scan", Flag="AntiStaffFull"})
U:Toggle({Name="Panic (disable ALL)", Flag="Panic"})
U:Toggle({Name="AutoVoidDrop", Flag="AutoVoidDrop"})
U:Toggle({Name="Blink", Flag="Blink"})
U:Toggle({Name="TrapDisabler", Flag="TrapDisabler"})
U:Separator()
U:Label("-- Discord Webhook --")
U:Input({Name="Webhook URL", Flag="WebhookURL", Placeholder="https://discord.com/api/webhooks/..."})
U:Toggle({Name="Webhook: On Kill", Flag="WH_Kill", Default=true})
U:Toggle({Name="Webhook: On Bed Break", Flag="WH_Bed", Default=true})
U:Toggle({Name="Webhook: On Death", Flag="WH_Death", Default=true})
U:Toggle({Name="Webhook: On Victory", Flag="WH_Win", Default=true})
U:Button({Name="Test Webhook", Color=Color3.fromRGB(80,60,140)}, function()
    BW.Config.DiscordWebhook=BW.Flags.WebhookURL or ""; BW.SaveConfig()
    BW.SendWebhook("Test","BedWars webhook working!",3447003)
    BW.StarterGui:SetCore("SendNotification",{Title="Webhook",Text="Test sent!",Duration=2})
end)
U:Separator()
U:Button({Name="Save Settings", Color=Color3.fromRGB(60,120,60)}, function()
    BW.Config.DiscordWebhook=BW.Flags.WebhookURL or ""
    BW.Config.WebhookOnKill=BW.Flags.WH_Kill; BW.Config.WebhookOnBedBreak=BW.Flags.WH_Bed
    BW.Config.WebhookOnDeath=BW.Flags.WH_Death; BW.Config.WebhookOnVictory=BW.Flags.WH_Win
    BW.SaveConfig(); BW.StarterGui:SetCore("SendNotification",{Title="Settings",Text="Saved!",Duration=2})
end)
U:Button({Name="Load Settings", Color=Color3.fromRGB(100,80,40)}, function()
    BW.LoadConfig(); BW.Flags.WebhookURL=BW.Config.DiscordWebhook
    BW.Flags.WH_Kill=BW.Config.WebhookOnKill; BW.Flags.WH_Bed=BW.Config.WebhookOnBedBreak
    BW.Flags.WH_Death=BW.Config.WebhookOnDeath; BW.Flags.WH_Win=BW.Config.WebhookOnVictory
    BW.StarterGui:SetCore("SendNotification",{Title="Settings",Text="Loaded!",Duration=2})
end)
U:Separator()
U:Button({Name="Rejoin Server", Color=Color3.fromRGB(140,90,30)}, function()
    BW.TeleportService:TeleportToPlaceInstance(game.PlaceId,game.JobId,BW.LocalPlayer)
end)
U:Button({Name="Leave Game", Color=Color3.fromRGB(160,40,40)}, function() game:Shutdown() end)

-- ═══ ENGINES ═══

-- Panic
task.spawn(function()
    while true do
        if BW.Flags.Panic then
            for k,_ in pairs(BW.Flags) do BW.Flags[k]=false end
            BW.Flags.Panic=false
            BW.StarterGui:SetCore("SendNotification",{Title="Panic",Text="All disabled!",Duration=2})
        end
        task.wait(0.2)
    end
end)

-- Anti AFK
task.spawn(function()
    while true do
        if BW.Flags.AntiAFK then
            BW.Perf:Throttle("AntiAFK",60,function()
                pcall(function()
                    BW.VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.W,false,game); task.wait(0.2)
                    BW.VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.W,false,game); task.wait(0.2)
                    BW.VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.W,false,game)
                end)
            end)
        end
        task.wait(1)
    end
end)

-- Staff Detection
local staffDetected=false
local StaffGroups={{Id=3252059,MinRank=100,Name="BedWars"},{Id=3281747,MinRank=100,Name="Easy.gg"},{Id=2868474,MinRank=100,Name="Roblox"}}
local StaffPatterns={"moderator","admin","staff","helper","builder","developer","dev","head admin","community manager","trial mod","senior mod","lead mod"}

local function checkStaff(player)
    for _,g in ipairs(StaffGroups) do
        pcall(function() local rank=player:GetRankInGroup(g.Id) if rank and rank>=g.MinRank then return true,g.Name.." Rank:"..rank end end)
    end
    local dn=player.DisplayName:lower()
    for _,p in ipairs(StaffPatterns) do if dn:find(p) then return true,"Display: "..p end end
    local un=player.Name:lower()
    for _,p in ipairs(StaffPatterns) do if un:find(p) then return true,"User: "..p end end
    return false,nil
end

task.spawn(function()
    while true do
        if BW.Flags.StaffDetect and not staffDetected then
            for _,p in pairs(BW.Players:GetPlayers()) do
                if p~=BW.LocalPlayer then
                    local isStaff,reason=checkStaff(p)
                    if isStaff then
                        staffDetected=true
                        pcall(function() BW.StarterGui:SetCore("SendNotification",{Title="STAFF!",Text=p.Name.." ("..reason..")",Duration=10}) end)
                        BW.SendWebhook("STAFF!",p.Name.."("..reason..")",16711680)
                        if BW.Flags.AntiStaffChat then pcall(function()
                            for _,r in pairs(BW.ReplicatedStorage:GetDescendants()) do if r:IsA("RemoteEvent") and r.Name:lower():find("chat") then r:FireServer("STAFF: "..p.Name.." LEAVE NOW") break end end
                        end) end
                        if BW.Flags.AntiStaffPanic then for k,_ in pairs(BW.Flags) do BW.Flags[k]=false end end
                        if BW.Flags.AntiStaffDC then task.wait(1); pcall(function() game:Shutdown() end) end
                        if BW.Flags.AntiStaffRejoin then task.wait(2); pcall(function() BW.TeleportService:Teleport(game.PlaceId,BW.LocalPlayer) end) end
                        break
                    end
                end
            end
        end
        task.wait(3)
    end
end)

-- AutoVoidDrop
task.spawn(function()
    while true do
        if BW.Flags.AutoVoidDrop and BW.alive() then
            local my=BW.hrp()
            if my and my.Position.Y<-30 then
                for _,tool in pairs(BW.char():GetChildren()) do if tool:IsA("Tool") then tool.Parent=BW.LocalPlayer.Backpack end end
            end
        end
        task.wait(0.1)
    end
end)

print("[Util] Module loaded")


-- legit.lua
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


-- autoload.lua
-- ══════════════════════════════════════════════════════════════
-- AUTOLOAD MODULE (Auto Farm + Silent Aim)
-- ══════════════════════════════════════════════════════════════
local PathfindingService = game:GetService("PathfindingService")

-- Auto Farm engine
local function findResourceSpawners()
    local spawners={}
    local target=BW.Flags.FarmTarget or "Iron Only"
    for _, obj in pairs(BW.Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n=obj.Name:lower(); local isTarget=false
            if target=="Iron Only" and n:find("iron") then isTarget=true
            elseif target=="Iron + Gold" and (n:find("iron") or n:find("gold")) then isTarget=true
            elseif target=="All Resources" and (n:find("iron") or n:find("gold") or n:find("diamond") or n:find("emerald")) then isTarget=true end
            if isTarget and obj.Anchored then table.insert(spawners, obj) end
        end
    end
    return spawners
end

local function walkTo(position)
    local my=BW.hrp(); local h=BW.hum()
    if not my or not h then return false end
    h.WalkSpeed=BW.Flags.FarmSpeed or 20
    local path=PathfindingService:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true,AgentCanClimb=false})
    local success=pcall(function() path:ComputeAsync(my.Position,position) end)
    if success and path.Status==Enum.PathStatus.Success then
        for _, wp in ipairs(path:GetWaypoints()) do
            if not BW.Flags.AutoFarm then return false end
            if BW.Flags.FarmAvoid then
                local enemy=BW.nearestEnemy(15)
                if enemy then
                    local fleeDir=(my.Position-enemy.HRP.Position).Unit
                    my.CFrame=CFrame.new(my.Position+fleeDir*10); task.wait(0.3); return false
                end
            end
            h.WalkToPoint=wp.Position; task.wait(0.2)
            local timeout=0
            while (my.Position-wp.Position).Magnitude>3 and timeout<20 do task.wait(0.1); timeout=timeout+0.1 end
        end
        return true
    else h.WalkToPoint=position; task.wait(1); return true end
end

task.spawn(function()
    while true do
        if BW.Flags.AutoFarm and BW.alive() then
            local spawners=findResourceSpawners()
            if #spawners>0 then
                local my=BW.hrp()
                if my then
                    table.sort(spawners,function(a,b) return (a.Position-my.Position).Magnitude<(b.Position-my.Position).Magnitude end)
                    walkTo(spawners[1].Position)
                    task.wait(1)
                    for _, obj in pairs(BW.Workspace:GetDescendants()) do
                        if obj:IsA("BasePart") then
                            local n=obj.Name:lower()
                            if n:find("iron") or n:find("gold") or n:find("diamond") or n:find("emerald") then
                                if (my.Position-obj.Position).Magnitude<8 then my.CFrame=CFrame.new(obj.Position+Vector3.new(0,2,0)); task.wait(0.1) end
                            end
                        end
                    end
                    if BW.Flags.FarmBuyBlocks then local _,iron=BW.getInventory(); if iron>=12 then BW.buyItem("Wool") end end
                end
            end
            if BW.Flags.FarmReturn then
                for _, obj in pairs(BW.Workspace:GetDescendants()) do
                    if obj.Name=="Bed" and obj:IsA("Model") then
                        local tag=obj:FindFirstChild("Team")
                        if tag and tag:IsA("StringValue") and tag.Value==(BW.LocalPlayer.Team and BW.LocalPlayer.Team.Name or "") then
                            local part=obj.PrimaryPart or obj:FindFirstChildWhichIsA("Part")
                            if part then walkTo(part.Position+Vector3.new(3,0,0)) end
                        end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

-- Silent Aim
local SilentAimTarget=nil
task.spawn(function()
    while true do
        if BW.Flags.SilentAim and BW.alive() then
            local fov=BW.Flags.SA_FOV or 120
            local hitChance=(BW.Flags.SA_HitChance or 100)/100
            if math.random()>hitChance then SilentAimTarget=nil
            else
                local my=BW.hrp()
                if my then
                    local best,bestDist=nil,fov
                    for _, e in pairs(BW.enemies()) do
                        local dist=(my.Position-e.HRP.Position).Magnitude
                        if dist<bestDist then
                            if BW.Flags.SA_WallCheck and not BW.hasLineOfSight(my.Position,e.HRP.Position) then goto continue_sa end
                            bestDist=dist; best=e
                        end
                        ::continue_sa::
                    end
                    if best then
                        local tp=BW.Flags.SA_Headshot and best.Char:FindFirstChild("Head") or best.HRP
                        SilentAimTarget=(tp and tp.Position) or nil
                    else SilentAimTarget=nil end
                end
            end
        else SilentAimTarget=nil end
        task.wait(0.01)
    end
end)

task.spawn(function()
    while true do
        if BW.Flags.SilentAim and BW.alive() and SilentAimTarget then
            local cam=BW.Camera.CFrame
            local myPos=cam.Position
            local targetDir=(SilentAimTarget-myPos).Unit
            local currentLook=cam.LookVector
            local newLook=currentLook:Lerp(targetDir,0.5)
            BW.Camera.CFrame=CFrame.new(myPos,myPos+newLook)
            task.wait(0.01)
        end
        task.wait(0.01)
    end
end)

print("[Autoload] Module loaded")


-- events.lua
-- ══════════════════════════════════════════════════════════════
-- EVENTS MODULE (Kill/Death/Bed/Victory tracking)
-- ══════════════════════════════════════════════════════════════
local killCount=0
local deathCount=0
local bedBreaks=0

-- Kill tracking
task.spawn(function()
    local prevHealth={}
    while true do
        for _,p in pairs(BW.Players:GetPlayers()) do
            if p~=BW.LocalPlayer and p.Character then
                local h=p.Character:FindFirstChildOfClass("Humanoid")
                if h then
                    local prev=prevHealth[p.UserId] or h.Health
                    if prev>0 and h.Health<=0 and p.Team~=BW.LocalPlayer.Team then
                        killCount=killCount+1
                        BW.SendWebhook("Kill #"..killCount,"Eliminated **"..p.Name.."**\nTotal: "..killCount,15158332)
                    end
                    prevHealth[p.UserId]=h.Health
                end
            end
        end
        task.wait(0.3)
    end
end)

-- Death tracking
task.spawn(function()
    while true do
        local c=BW.LocalPlayer.Character
        if c then
            local h=c:FindFirstChildOfClass("Humanoid")
            if h then
                h.Died:Connect(function()
                    deathCount=deathCount+1
                    BW.SendWebhook("Death #"..deathCount,"You were eliminated!",15158332)
                end)
            end
        end
        task.wait(1)
    end
end)

-- Bed break tracking
task.spawn(function()
    while true do
        for _, obj in pairs(BW.Workspace:GetDescendants()) do
            if obj.Name=="Bed" and obj:IsA("Model") and not obj:GetAttribute("_BW_Tracked") then
                obj:SetAttribute("_BW_Tracked",true)
                local tag=obj:FindFirstChild("Team")
                local isEnemy=tag and tag:IsA("StringValue") and tag.Value~=(BW.LocalPlayer.Team and BW.LocalPlayer.Team.Name or "")
                obj.AncestryChanged:Connect(function(_,parent)
                    if not parent and isEnemy then
                        bedBreaks=bedBreaks+1
                        BW.SendWebhook("Bed Destroyed!","Enemy bed destroyed! Total: "..bedBreaks,16776960)
                    end
                end)
            end
        end
        task.wait(2)
    end
end)

-- Victory detection
task.spawn(function()
    while true do
        task.wait(3)
        if BW.alive() then
            local enemyCount=0
            for _,p in pairs(BW.Players:GetPlayers()) do
                if p~=BW.LocalPlayer and p.Team~=BW.LocalPlayer.Team then
                    local c=p.Character
                    if c then local h=c:FindFirstChildOfClass("Humanoid") if h and h.Health>0 then enemyCount=enemyCount+1 end end
                end
            end
            if enemyCount==0 and BW.Flags.WH_Win then
                BW.SendWebhook("VICTORY!","Won! Kills: "..killCount,3066993)
            end
        end
    end
end)

-- Character respawn handler
BW.LocalPlayer.CharacterAdded:Connect(function(c)
    task.wait(1)
    local h=c:WaitForChild("Humanoid",5)
    if h then
        if BW.Flags.Speed then h.WalkSpeed=BW.Flags.SpeedVal or 32 end
        if BW.Flags.HighJump then h.JumpPower=BW.Flags.JumpPower or 100 end
    end
end)

-- Performance monitor
task.spawn(function()
    local perfGui=Instance.new("ScreenGui"); perfGui.Name="BW_Perf"; perfGui.ResetOnSpawn=false; perfGui.Parent=BW.LocalPlayer.PlayerGui
    local pf=Instance.new("Frame"); pf.Size=UDim2.new(0,160,0,80); pf.Position=UDim2.new(0,10,0,10); pf.BackgroundColor3=Color3.fromRGB(0,0,0); pf.BackgroundTransparency=0.5; pf.BorderSizePixel=0; pf.Parent=perfGui; Instance.new("UICorner",pf).CornerRadius=UDim.new(0,8)
    local fpsLbl=Instance.new("TextLabel",pf); fpsLbl.Size=UDim2.new(1,-10,0,20); fpsLbl.Position=UDim2.new(0,5,0,5); fpsLbl.BackgroundTransparency=1; fpsLbl.Text="FPS: 60"; fpsLbl.TextColor3=Color3.fromRGB(0,255,0); fpsLbl.TextSize=12; fpsLbl.Font=Enum.Font.GothamBold; fpsLbl.TextXAlignment=Enum.TextXAlignment.Left
    local memLbl=Instance.new("TextLabel",pf); memLbl.Size=UDim2.new(1,-10,0,20); memLbl.Position=UDim2.new(0,5,0,25); memLbl.BackgroundTransparency=1; memLbl.Text="MEM: 0 MB"; memLbl.TextColor3=Color3.fromRGB(255,255,0); memLbl.TextSize=12; memLbl.Font=Enum.Font.GothamBold; memLbl.TextXAlignment=Enum.TextXAlignment.Left
    local modLbl=Instance.new("TextLabel",pf); modLbl.Size=UDim2.new(1,-10,0,20); modLbl.Position=UDim2.new(0,5,0,45); modLbl.BackgroundTransparency=1; modLbl.Text="Modules: 0"; modLbl.TextColor3=Color3.fromRGB(100,200,255); modLbl.TextSize=12; modLbl.Font=Enum.Font.GothamBold; modLbl.TextXAlignment=Enum.TextXAlignment.Left
    pf.Visible=false
    BW.UserInputService.InputBegan:Connect(function(input,gp) if not gp and input.KeyCode==Enum.KeyCode.F3 then pf.Visible=not pf.Visible end end)
    while true do
        if pf.Visible then
            fpsLbl.Text="FPS: "..BW.Perf.FPS
            local mem=BW.Perf:GetMemory(); memLbl.Text="MEM: "..mem.." MB"
            local active=0; for _,v in pairs(BW.Flags) do if v==true then active=active+1 end end
            modLbl.Text="Modules: "..active
        end
        task.wait(0.5)
    end
end)

-- Garbage collection
task.spawn(function()
    while true do collectgarbage("collect"); collectgarbage("collect"); task.wait(30) end
end)

-- Init
BW.SendWebhook("Script Loaded","BedWars Ultimate v4.4 loaded by **"..BW.LocalPlayer.Name.."**",3447003)
BW.StarterGui:SetCore("SendNotification",{Title="BedWars Ultimate v4.4",Text=BW.deviceType.." | "..(BW.isMobile and "Touch ready!" or "RightAlt to toggle"),Duration=5})
print("[Events] Module loaded")
print("[BedWars Ultimate v4.4] All modules loaded! Device: "..BW.deviceType)
print("Press F3 for performance monitor | RightAlt to toggle UI")

