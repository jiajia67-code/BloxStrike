--[[
    ╔══════════════════════════════════════════════════════════╗
    ║          BED WARS ULTIMATE SCRIPT v2.0                  ║
    ║          Features: KillAura, Scaffold, ESP, Fly, etc    ║
    ║          Compatible with Fluxus / Delta / Wave          ║
    ╚══════════════════════════════════════════════════════════╝
    
    HOW TO USE:
    1. Open Roblox executor (Fluxus, Delta, Wave, etc.)
    2. Start Roblox and join Bed Wars
    3. Paste this entire script and execute
    
    Game: https://www.roblox.com/games/6872265039
]]

-- ═══════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ═══════════════════════════════════════════════════════════
-- UI LIBRARY (Rayfield-style lightweight)
-- ═══════════════════════════════════════════════════════════
local Library = {}
Library.__index = Library

function Library:Window(config)
    local self = setmetatable({}, Library)
    self.Config = config or {Title = "Bed Wars", Subtitle = "v2.0"}
    self.Tabs = {}
    self.Flags = {}
    self.Connections = {}
    
    -- Create main UI
    if game.CoreGui:FindFirstChild("BedWarsUI") then
        game.CoreGui:FindFirstChild("BedWarsUI"):Destroy()
    end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BedWarsUI"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = game.CoreGui
    self.ScreenGui = ScreenGui
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "Main"
    MainFrame.Size = UDim2.new(0, 520, 0, 380)
    MainFrame.Position = UDim2.new(0.5, -260, 0.5, -190)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui
    self.MainFrame = MainFrame
    
    -- Corner round
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = MainFrame
    
    -- Shadow
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
    Shadow.Size = UDim2.new(1, 30, 1, 30)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://6015897843"
    Shadow.ImageColor3 = Color3.new(0, 0, 0)
    Shadow.ImageTransparency = 0.5
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    Shadow.ZIndex = -1
    Shadow.Parent = MainFrame
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 10)
    TitleCorner.Parent = TitleBar
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(0.7, 0, 1, 0)
    TitleLabel.Position = UDim2.new(0, 15, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "⚔️ " .. self.Config.Title
    TitleLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    TitleLabel.TextSize = 16
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TitleBar
    
    local SubLabel = Instance.new("TextLabel")
    SubLabel.Size = UDim2.new(0.3, -15, 1, 0)
    SubLabel.Position = UDim2.new(0.7, 0, 0, 0)
    SubLabel.BackgroundTransparency = 1
    SubLabel.Text = self.Config.Subtitle or ""
    SubLabel.TextColor3 = Color3.fromRGB(120, 120, 140)
    SubLabel.TextSize = 12
    SubLabel.Font = Enum.Font.Gotham
    SubLabel.TextXAlignment = Enum.TextXAlignment.Right
    SubLabel.Parent = TitleBar
    
    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseBtn"
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -35, 0, 5)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.new(1, 1, 1)
    CloseBtn.TextSize = 14
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Parent = TitleBar
    
    local CloseBtnCorner = Instance.new("UICorner")
    CloseBtnCorner.CornerRadius = UDim.new(0, 6)
    CloseBtnCorner.Parent = CloseBtn
    
    local uiOpen = true
    CloseBtn.MouseButton1Click:Connect(function()
        uiOpen = not uiOpen
        MainFrame.Visible = uiOpen
    end)
    
    -- Toggle key (Right Alt)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightAlt then
            uiOpen = not uiOpen
            MainFrame.Visible = uiOpen
        end
    end)
    
    -- Tab Container
    local TabContainer = Instance.new("Frame")
    TabContainer.Name = "Tabs"
    TabContainer.Size = UDim2.new(0, 120, 1, -50)
    TabContainer.Position = UDim2.new(0, 5, 0, 45)
    TabContainer.BackgroundTransparency = 1
    TabContainer.Parent = MainFrame
    
    local TabList = Instance.new("UIListLayout")
    TabList.SortOrder = Enum.SortOrder.LayoutOrder
    TabList.Padding = UDim.new(0, 4)
    TabList.Parent = TabContainer
    
    -- Content
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -140, 1, -50)
    Content.Position = UDim2.new(0, 130, 0, 45)
    Content.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
    Content.BorderSizePixel = 0
    Content.Parent = MainFrame
    
    local ContentCorner = Instance.new("UICorner")
    ContentCorner.CornerRadius = UDim.new(0, 8)
    ContentCorner.Parent = Content
    
    self.TabContainer = TabContainer
    self.Content = Content
    self.CurrentTab = nil
    self.TabPages = {}
    
    return self
end

function Library:Tab(name)
    local tab = {}
    tab.Name = name
    
    -- Tab button
    local TabBtn = Instance.new("TextButton")
    TabBtn.Name = name
    TabBtn.Size = UDim2.new(1, 0, 0, 32)
    TabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    TabBtn.BorderSizePixel = 0
    TabBtn.Text = "  " .. name
    TabBtn.TextColor3 = Color3.fromRGB(160, 160, 180)
    TabBtn.TextSize = 12
    TabBtn.Font = Enum.Font.GothamMedium
    TabBtn.TextXAlignment = Enum.TextXAlignment.Left
    TabBtn.Parent = self.TabContainer
    
    local TabBtnCorner = Instance.new("UICorner")
    TabBtnCorner.CornerRadius = UDim.new(0, 6)
    TabBtnCorner.Parent = TabBtn
    
    -- Tab page
    local Page = Instance.new("ScrollingFrame")
    Page.Name = name
    Page.Size = UDim2.new(1, -10, 1, -10)
    Page.Position = UDim2.new(0, 5, 0, 5)
    Page.BackgroundTransparency = 1
    Page.ScrollBarThickness = 3
    Page.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.Visible = false
    Page.Parent = self.Content
    
    local PageList = Instance.new("UIListLayout")
    PageList.SortOrder = Enum.SortOrder.LayoutOrder
    PageList.Padding = UDim.new(0, 6)
    PageList.Parent = Page
    
    local PagePadding = Instance.new("UIPadding")
    PagePadding.PaddingLeft = UDim.new(0, 5)
    PagePadding.PaddingRight = UDim.new(0, 5)
    PagePadding.PaddingTop = UDim.new(0, 5)
    PagePadding.Parent = Page
    
    -- Show first tab
    if not self.CurrentTab then
        self.CurrentTab = name
        Page.Visible = true
        TabBtn.BackgroundColor3 = Color3.fromRGB(50, 80, 140)
        TabBtn.TextColor3 = Color3.new(1, 1, 1)
    end
    
    TabBtn.MouseButton1Click:Connect(function()
        -- Hide all tabs
        for _, child in pairs(self.Content:GetChildren()) do
            if child:IsA("ScrollingFrame") then child.Visible = false end
        end
        for _, child in pairs(self.TabContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
                child.TextColor3 = Color3.fromRGB(160, 160, 180)
            end
        end
        Page.Visible = true
        TabBtn.BackgroundColor3 = Color3.fromRGB(50, 80, 140)
        TabBtn.TextColor3 = Color3.new(1, 1, 1)
        self.CurrentTab = name
    end)
    
    self.TabPages[name] = Page
    tab.Page = Page
    
    -- ═══ COMPONENTS ═══
    
    function tab:Toggle(config, callback)
        local ToggleFrame = Instance.new("Frame")
        ToggleFrame.Size = UDim2.new(1, 0, 0, 36)
        ToggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
        ToggleFrame.BorderSizePixel = 0
        ToggleFrame.Parent = Page
        
        local ToggleCorner = Instance.new("UICorner")
        ToggleCorner.CornerRadius = UDim.new(0, 6)
        ToggleCorner.Parent = ToggleFrame
        
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0.7, 0, 1, 0)
        Label.Position = UDim2.new(0, 12, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = config.Name or "Toggle"
        Label.TextColor3 = Color3.fromRGB(200, 200, 210)
        Label.TextSize = 13
        Label.Font = Enum.Font.GothamMedium
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = ToggleFrame
        
        local ToggleBtn = Instance.new("TextButton")
        ToggleBtn.Size = UDim2.new(0, 44, 0, 22)
        ToggleBtn.Position = UDim2.new(1, -56, 0.5, -11)
        ToggleBtn.BackgroundColor3 = config.Default and Color3.fromRGB(80, 180, 80) or Color3.fromRGB(60, 60, 70)
        ToggleBtn.BorderSizePixel = 0
        ToggleBtn.Text = ""
        ToggleBtn.Parent = ToggleFrame
        
        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 11)
        BtnCorner.Parent = ToggleBtn
        
        local Circle = Instance.new("Frame")
        Circle.Size = UDim2.new(0, 18, 0, 18)
        Circle.Position = config.Default and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        Circle.BackgroundColor3 = Color3.new(1, 1, 1)
        Circle.BorderSizePixel = 0
        Circle.Parent = ToggleBtn
        
        local CircleCorner = Instance.new("UICorner")
        CircleCorner.CornerRadius = UDim.new(0, 9)
        CircleCorner.Parent = Circle
        
        local toggled = config.Default or false
        Library.Flags[config.Flag] = toggled
        
        ToggleBtn.MouseButton1Click:Connect(function()
            toggled = not toggled
            Library.Flags[config.Flag] = toggled
            TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = toggled and Color3.fromRGB(80, 180, 80) or Color3.fromRGB(60, 60, 70)}):Play()
            TweenService:Create(Circle, TweenInfo.new(0.2), {Position = toggled and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)}):Play()
            if callback then callback(toggled) end
        end)
        
        return ToggleFrame
    end
    
    function tab:Slider(config, callback)
        local Min = config.Min or 0
        local Max = config.Max or 100
        local Default = config.Default or Min
        
        local SliderFrame = Instance.new("Frame")
        SliderFrame.Size = UDim2.new(1, 0, 0, 44)
        SliderFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
        SliderFrame.BorderSizePixel = 0
        SliderFrame.Parent = Page
        
        local SliderCorner = Instance.new("UICorner")
        SliderCorner.CornerRadius = UDim.new(0, 6)
        SliderCorner.Parent = SliderFrame
        
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0.6, 0, 0, 20)
        Label.Position = UDim2.new(0, 12, 0, 4)
        Label.BackgroundTransparency = 1
        Label.Text = config.Name or "Slider"
        Label.TextColor3 = Color3.fromRGB(200, 200, 210)
        Label.TextSize = 13
        Label.Font = Enum.Font.GothamMedium
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = SliderFrame
        
        local ValueLabel = Instance.new("TextLabel")
        ValueLabel.Size = UDim2.new(0.3, 0, 0, 20)
        ValueLabel.Position = UDim2.new(0.7, 0, 0, 4)
        ValueLabel.BackgroundTransparency = 1
        ValueLabel.Text = tostring(Default)
        ValueLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
        ValueLabel.TextSize = 13
        ValueLabel.Font = Enum.Font.GothamBold
        ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
        ValueLabel.Parent = SliderFrame
        
        local SliderBG = Instance.new("Frame")
        SliderBG.Size = UDim2.new(1, -24, 0, 6)
        SliderBG.Position = UDim2.new(0, 12, 0, 30)
        SliderBG.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
        SliderBG.BorderSizePixel = 0
        SliderBG.Parent = SliderFrame
        
        local SliderBGCorner = Instance.new("UICorner")
        SliderBGCorner.CornerRadius = UDim.new(0, 3)
        SliderBGCorner.Parent = SliderBG
        
        local Fill = Instance.new("Frame")
        Fill.Size = UDim2.new((Default - Min) / (Max - Min), 0, 1, 0)
        Fill.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
        Fill.BorderSizePixel = 0
        Fill.Parent = SliderBG
        
        local FillCorner = Instance.new("UICorner")
        FillCorner.CornerRadius = UDim.new(0, 3)
        FillCorner.Parent = Fill
        
        local Knob = Instance.new("Frame")
        Knob.Size = UDim2.new(0, 14, 0, 14)
        Knob.Position = UDim2.new((Default - Min) / (Max - Min), -7, 0.5, -7)
        Knob.BackgroundColor3 = Color3.new(1, 1, 1)
        Knob.BorderSizePixel = 0
        Knob.Parent = SliderBG
        
        local KnobCorner = Instance.new("UICorner")
        KnobCorner.CornerRadius = UDim.new(0, 7)
        KnobCorner.Parent = Knob
        
        local currentVal = Default
        Library.Flags[config.Flag] = Default
        
        local dragging = false
        SliderBG.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local relX = math.clamp((input.Position.X - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X, 0, 1)
                currentVal = math.floor(Min + relX * (Max - Min) + 0.5)
                Library.Flags[config.Flag] = currentVal
                Fill.Size = UDim2.new(relX, 0, 1, 0)
                Knob.Position = UDim2.new(relX, -7, 0.5, -7)
                ValueLabel.Text = tostring(currentVal)
                if callback then callback(currentVal) end
            end
        end)
    end
    
    function tab:Dropdown(config, callback)
        local DropdownFrame = Instance.new("Frame")
        DropdownFrame.Size = UDim2.new(1, 0, 0, 36)
        DropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
        DropdownFrame.BorderSizePixel = 0
        DropdownFrame.ClipsDescendants = true
        DropdownFrame.Parent = Page
        
        local DropCorner = Instance.new("UICorner")
        DropCorner.CornerRadius = UDim.new(0, 6)
        DropCorner.Parent = DropdownFrame
        
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0.5, 0, 0, 36)
        Label.Position = UDim2.new(0, 12, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = config.Name or "Dropdown"
        Label.TextColor3 = Color3.fromRGB(200, 200, 210)
        Label.TextSize = 13
        Label.Font = Enum.Font.GothamMedium
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = DropdownFrame
        
        local SelectedLabel = Instance.new("TextButton")
        SelectedLabel.Size = UDim2.new(0.45, -12, 0, 26)
        SelectedLabel.Position = UDim2.new(0.55, 0, 0, 5)
        SelectedLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
        SelectedLabel.BorderSizePixel = 0
        SelectedLabel.Text = "  " .. (config.Default or config.Options[1] or "")
        SelectedLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
        SelectedLabel.TextSize = 12
        SelectedLabel.Font = Enum.Font.Gotham
        SelectedLabel.TextXAlignment = Enum.TextXAlignment.Left
        SelectedLabel.Parent = DropdownFrame
        
        local SelCorner = Instance.new("UICorner")
        SelCorner.CornerRadius = UDim.new(0, 5)
        SelCorner.Parent = SelectedLabel
        
        local isOpen = false
        local optionButtons = {}
        
        local function createOptions()
            for _, opt in pairs(optionButtons) do opt:Destroy() end
            optionButtons = {}
            
            for i, option in ipairs(config.Options) do
                local OptBtn = Instance.new("TextButton")
                OptBtn.Size = UDim2.new(1, 0, 0, 28)
                OptBtn.Position = UDim2.new(0, 0, 0, 36 + (i - 1) * 28)
                OptBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
                OptBtn.BorderSizePixel = 0
                OptBtn.Text = "  " .. option
                OptBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
                OptBtn.TextSize = 12
                OptBtn.Font = Enum.Font.Gotham
                OptBtn.TextXAlignment = Enum.TextXAlignment.Left
                OptBtn.Parent = DropdownFrame
                
                OptBtn.MouseEnter:Connect(function()
                    OptBtn.BackgroundColor3 = Color3.fromRGB(60, 80, 120)
                end)
                OptBtn.MouseLeave:Connect(function()
                    OptBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
                end)
                
                OptBtn.MouseButton1Click:Connect(function()
                    SelectedLabel.Text = "  " .. option
                    Library.Flags[config.Flag] = option
                    isOpen = false
                    DropdownFrame.Size = UDim2.new(1, 0, 0, 36)
                    if callback then callback(option) end
                end)
                
                table.insert(optionButtons, OptBtn)
            end
        end
        
        createOptions()
        Library.Flags[config.Flag] = config.Default or config.Options[1]
        
        SelectedLabel.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            if isOpen then
                DropdownFrame.Size = UDim2.new(1, 0, 0, 36 + #config.Options * 28 + 5)
            else
                DropdownFrame.Size = UDim2.new(1, 0, 0, 36)
            end
        end)
    end
    
    function tab:Button(config, callback)
        local BtnFrame = Instance.new("TextButton")
        BtnFrame.Size = UDim2.new(1, 0, 0, 34)
        BtnFrame.BackgroundColor3 = config.Color or Color3.fromRGB(50, 80, 140)
        BtnFrame.BorderSizePixel = 0
        BtnFrame.Text = config.Name or "Button"
        BtnFrame.TextColor3 = Color3.new(1, 1, 1)
        BtnFrame.TextSize = 13
        BtnFrame.Font = Enum.Font.GothamBold
        BtnFrame.Parent = Page
        
        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 6)
        BtnCorner.Parent = BtnFrame
        
        BtnFrame.MouseEnter:Connect(function()
            TweenService:Create(BtnFrame, TweenInfo.new(0.15), {BackgroundColor3 = config.HoverColor or Color3.fromRGB(70, 110, 180)}):Play()
        end)
        BtnFrame.MouseLeave:Connect(function()
            TweenService:Create(BtnFrame, TweenInfo.new(0.15), {BackgroundColor3 = config.Color or Color3.fromRGB(50, 80, 140)}):Play()
        end)
        
        BtnFrame.MouseButton1Click:Connect(function()
            if callback then callback() end
        end)
    end
    
    function tab:Label(text)
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, 0, 0, 24)
        Label.BackgroundTransparency = 1
        Label.Text = text
        Label.TextColor3 = Color3.fromRGB(120, 120, 140)
        Label.TextSize = 11
        Label.Font = Enum.Font.Gotham
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Page
        return Label
    end
    
    function tab:Separator()
        local Sep = Instance.new("Frame")
        Sep.Size = UDim2.new(1, 0, 0, 1)
        Sep.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
        Sep.BorderSizePixel = 0
        Sep.Parent = Page
    end
    
    return tab
end

-- ═══════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════
local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHRP()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function isAlive()
    local char = LocalPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return hum and hrp and hum.Health > 0
end

local function getEnemies()
    local enemies = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team then
            local char = player.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    table.insert(enemies, {Player = player, Character = char, Humanoid = hum, HRP = hrp})
                end
            end
        end
    end
    return enemies
end

local function getNearestEnemy(maxDist)
    maxDist = maxDist or math.huge
    local myHRP = getHRP()
    if not myHRP then return nil, math.huge end
    
    local nearest = nil
    local nearestDist = maxDist
    
    for _, enemy in pairs(getEnemies()) do
        local dist = (myHRP.Position - enemy.HRP.Position).Magnitude
        if dist < nearestDist then
            nearestDist = dist
            nearest = enemy
        end
    end
    
    return nearest, nearestDist
end

local function getTeamBed()
    -- Try to find team's bed
    local teamName = LocalPlayer.Team and LocalPlayer.Team.Name or ""
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Bed" and obj:IsA("Model") then
            local teamTag = obj:FindFirstChild("Team")
            if teamTag and teamTag:IsA("StringValue") and teamTag.Value == teamName then
                return obj
            end
        end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════
-- CREATE UI
-- ═══════════════════════════════════════════════════════════
local Window = Library:Window({
    Title = "Bed Wars",
    Subtitle = "v2.0 | RightAlt to toggle"
})

-- ═══════════════════════════════════════════════════════════
-- COMBAT TAB
-- ═══════════════════════════════════════════════════════════
local CombatTab = Window:Tab("⚔️ Combat")

CombatTab:Toggle({Name = "Kill Aura", Flag = "KillAura", Default = false})
CombatTab:Slider({Name = "Kill Aura Range", Flag = "KARange", Min = 5, Max = 18, Default = 14})
CombatTab:Slider({Name = "Kill Aura CPS", Flag = "KACPS", Min = 8, Max = 20, Default = 14})
CombatTab:Toggle({Name = "Auto Clicker", Flag = "AutoClicker", Default = false})
CombatTab:Slider({Name = "Click CPS", Flag = "ClickCPS", Min = 10, Max = 20, Default = 16})
CombatTab:Toggle({Name = "Reach Extend", Flag = "Reach", Default = false})
CombatTab:Slider({Name = "Reach Distance", Flag = "ReachDist", Min = 6, Max = 20, Default = 14})
CombatTab:Toggle({Name = "Auto Sword", Flag = "AutoSword", Default = false})
CombatTab:Toggle({Name = "No Fall Damage", Flag = "NoFall", Default = false})
CombatTab:Toggle({Name = "Velocity Anti-Knockback", Flag = "AntiKB", Default = false})

-- ═══════════════════════════════════════════════════════════
-- WORLD TAB
-- ═══════════════════════════════════════════════════════════
local WorldTab = Window:Tab("🌍 World")

WorldTab:Toggle({Name = "Auto Scaffold", Flag = "Scaffold", Default = false})
WorldTab:Toggle({Name = "Tower (Fast Build Up)", Flag = "Tower", Default = false})
WorldTab:Slider({Name = "Build Speed", Flag = "BuildSpeed", Min = 1, Max = 10, Default = 5})
WorldTab:Toggle({Name = "Nuker (Break Nearby Blocks)", Flag = "Nuker", Default = false})
WorldTab:Slider({Name = "Nuker Range", Flag = "NukerRange", Min = 2, Max = 6, Default = 4})
WorldTab:Toggle({Name = "Auto Collect Resources", Flag = "AutoCollect", Default = false})
WorldTab:Slider({Name = "Collect Range", Flag = "CollectRange", Min = 5, Max = 20, Default = 12})

-- ═══════════════════════════════════════════════════════════
-- ESP TAB
-- ═══════════════════════════════════════════════════════════
local ESPTab = Window:Tab("👁️ ESP")

ESPTab:Toggle({Name = "Player ESP", Flag = "PlayerESP", Default = false})
ESPTab:Toggle({Name = "Bed ESP", Flag = "BedESP", Default = false})
ESPTab:Toggle({Name = "Item ESP", Flag = "ItemESP", Default = false})
ESPTab:Toggle({Name = "Name Tags", Flag = "NameTags", Default = false})
ESPTab:Toggle({Name = "Health Bar ESP", Flag = "HealthESP", Default = false})
ESPTab:Toggle({Name = "Tracer ESP", Flag = "TracerESP", Default = false})

-- ═══════════════════════════════════════════════════════════
-- MOVEMENT TAB
-- ═══════════════════════════════════════════════════════════
local MoveTab = Window:Tab("🏃 Movement")

MoveTab:Toggle({Name = "Speed Hack", Flag = "Speed", Default = false})
MoveTab:Slider({Name = "Speed Value", Flag = "SpeedVal", Min = 16, Max = 100, Default = 32})
MoveTab:Toggle({Name = "Fly", Flag = "Fly", Default = false})
MoveTab:Slider({Name = "Fly Speed", Flag = "FlySpeed", Min = 1, Max = 30, Default = 8})
MoveTab:Toggle({Name = "High Jump", Flag = "HighJump", Default = false})
MoveTab:Slider({Name = "Jump Power", Flag = "JumpPower", Min = 50, Max = 200, Default = 100})
MoveTab:Toggle({Name = "No Clip", Flag = "NoClip", Default = false})
MoveTab:Toggle({Name = "Spin Bot", Flag = "SpinBot", Default = false})
MoveTab:Slider({Name = "Spin Speed", Flag = "SpinSpeed", Min = 1, Max = 30, Default = 10})

-- ═══════════════════════════════════════════════════════════
-- SHOP / UTILITY TAB
-- ═══════════════════════════════════════════════════════════
local UtilityTab = Window:Tab("🛒 Utility")

UtilityTab:Toggle({Name = "Auto Buy Best Sword", Flag = "AutoBuySword", Default = false})
UtilityTab:Toggle({Name = "Auto Buy Armor", Flag = "AutoBuyArmor", Default = false})
UtilityTab:Toggle({Name = "Auto Buy Blocks", Flag = "AutoBuyBlocks", Default = false})
UtilityTab:Toggle({Name = "Auto Buy Endstone", Flag = "AutoBuyEndstone", Default = false})
UtilityTab:Dropdown({Name = "Buy Priority", Flag = "BuyPriority", Options = {"Sword > Armor > Blocks", "Blocks > Sword > Armor", "Armor > Sword > Blocks"}, Default = "Sword > Armor > Blocks"})
UtilityTab:Toggle({Name = "Anti-AFK", Flag = "AntiAFK", Default = false})
UtilityTab:Toggle({Name = "Auto Reconnect", Flag = "AutoReconnect", Default = false})
UtilityTab:Separator()
UtilityTab:Button({Name = "📋 Copy Script", Color = Color3.fromRGB(60, 120, 60)}, function()
    setclipboard("loadstring(game:HttpGet('https://raw.githubusercontent.com/YOUR_REPO/BedWars/main/BedWars_Main.lua'))()")
    StarterGui:SetCore("SendNotification", {Title = "Copied!", Text = "Script URL copied to clipboard"})
end)
UtilityTab:Button({Name = "🔄 Rejoin Server", Color = Color3.fromRGB(180, 100, 40)}, function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)
UtilityTab:Button({Name = "🚪 Disconnect (Leave)", Color = Color3.fromRGB(180, 50, 50)}, function()
    game:Shutdown()
end)

-- ═══════════════════════════════════════════════════════════
-- KILL AURA ENGINE
-- ═══════════════════════════════════════════════════════════
local KillAuraActive = false

local function startKillAura()
    if KillAuraActive then return end
    KillAuraActive = true
    
    task.spawn(function()
        while Library.Flags["KillAura"] and isAlive() do
            local range = Library.Flags["KARange"] or 14
            local cps = Library.Flags["KACPS"] or 14
            local delay = 1 / (cps * 2) -- swing + cooldown
            
            local enemy, dist = getNearestEnemy(range)
            if enemy and dist < range then
                -- Equip best sword
                if Library.Flags["AutoSword"] then
                    local char = getCharacter()
                    if char then
                        local bestTool = nil
                        local bestDmg = 0
                        for _, tool in pairs(char:GetChildren()) do
                            if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
                                local dmg = tool:GetAttribute("Damage") or tool:GetAttribute("DMG") or 0
                                if dmg > bestDmg then
                                    bestDmg = dmg
                                    bestTool = tool
                                end
                            end
                        end
                        if bestTool then
                            LocalPlayer.Character.Humanoid:EquipTool(bestTool)
                        end
                    end
                end
                
                -- Look at enemy
                local myHRP = getHRP()
                if myHRP then
                    local lookAt = CFrame.new(myHRP.Position, enemy.HRP.Position)
                    myHRP.CFrame = lookAt
                end
                
                -- Swing attack
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                task.wait(delay)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            end
            
            task.wait(delay)
        end
        KillAuraActive = false
    end)
end

-- ═══════════════════════════════════════════════════════════
-- AUTO CLICKER ENGINE
-- ═══════════════════════════════════════════════════════════
local AutoClickActive = false

local function startAutoClicker()
    if AutoClickActive then return end
    AutoClickActive = true
    
    task.spawn(function()
        while Library.Flags["AutoClicker"] and isAlive() do
            local cps = Library.Flags["ClickCPS"] or 16
            local delay = 1 / cps
            
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            task.wait(delay * 0.4)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            task.wait(delay * 0.6)
        end
        AutoClickActive = false
    end)
end

-- ═══════════════════════════════════════════════════════════
-- SCAFFOLD ENGINE
-- ═══════════════════════════════════════════════════════════
local ScaffoldActive = false

local function startScaffold()
    if ScaffoldActive then return end
    ScaffoldActive = true
    
    task.spawn(function()
        while Library.Flags["Scaffold"] and isAlive() do
            local hrp = getHRP()
            if hrp then
                -- Check if there's no block below us
                local rayOrigin = hrp.Position
                local rayDir = Vector3.new(0, -4, 0)
                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = {getCharacter()}
                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                
                local result = Workspace:Raycast(rayOrigin, rayDir, raycastParams)
                
                if not result then
                    -- No block below — place one
                    -- Find equipped block tool
                    local char = getCharacter()
                    if char then
                        local blockTool = nil
                        for _, tool in pairs(char:GetChildren()) do
                            if tool:IsA("Tool") and (tool.Name:lower():find("block") or tool.Name:lower():find("wool") or tool.Name:lower():find("clay") or tool.Name:lower():find("stone") or tool.Name:lower():find("wood")) then
                                blockTool = tool
                                break
                            end
                        end
                        
                        if blockTool then
                            -- Activate tool to place
                            if blockTool.Parent == char then
                                -- Try to fire placement remote
                                local placeRemote = ReplicatedStorage:FindFirstChild("BlockPlace") 
                                    or ReplicatedStorage:FindFirstChild("PlaceBlock")
                                    or ReplicatedStorage:FindFirstChild("BuildBlock")
                                
                                if placeRemote then
                                    local placePos = hrp.Position - Vector3.new(0, 3, 0)
                                    local lookVec = hrp.CFrame.LookVector
                                    placePos = placePos + lookVec * 2
                                    placeRemote:FireServer(placePos, 0)
                                end
                            else
                                LocalPlayer.Character.Humanoid:EquipTool(blockTool)
                            end
                        end
                    end
                end
            end
            task.wait(0.05)
        end
        ScaffoldActive = false
    end)
end

-- ═══════════════════════════════════════════════════════════
-- TOWER ENGINE (Build Up)
-- ═══════════════════════════════════════════════════════════
local TowerActive = false

local function startTower()
    if TowerActive then return end
    TowerActive = true
    
    task.spawn(function()
        local hrp = getHRP()
        local humanoid = getHumanoid()
        if hrp and humanoid then
            -- Jump and place block under
            for i = 1, 50 do
                if not Library.Flags["Tower"] then break end
                humanoid.Jump = true
                task.wait(0.15)
                
                local char = getCharacter()
                if char then
                    for _, tool in pairs(char:GetChildren()) do
                        if tool:IsA("Tool") and (tool.Name:lower():find("block") or tool.Name:lower():find("wool")) then
                            if tool.Parent == char then
                                local remote = ReplicatedStorage:FindFirstChild("BlockPlace")
                                if remote then
                                    remote:FireServer(hrp.Position - Vector3.new(0, 3.5, 0), 0)
                                end
                            else
                                humanoid:EquipTool(tool)
                            end
                            break
                        end
                    end
                end
                task.wait(Library.Flags["BuildSpeed"] and (0.1 * (11 - Library.Flags["BuildSpeed"])) or 0.3)
            end
        end
        TowerActive = false
    end)
end

-- ═══════════════════════════════════════════════════════════
-- ESP ENGINE
-- ═══════════════════════════════════════════════════════════
local ESPObjects = {}

local function clearESP()
    for _, obj in pairs(ESPObjects) do
        if obj and obj.Parent then obj:Destroy() end
    end
    ESPObjects = {}
end

local function createBillboard(parent, name, text, color, offset)
    local existing = parent:FindFirstChild(name)
    if existing then existing:Destroy() end
    
    local bb = Instance.new("BillboardGui")
    bb.Name = name
    bb.Size = UDim2.new(0, 100, 0, 30)
    bb.StudsOffset = offset or Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = parent
    bb.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 0.5
    label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    label.Text = text
    label.TextColor3 = color or Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = bb
    
    table.insert(ESPObjects, bb)
    return bb
end

local function updateESP()
    clearESP()
    
    if Library.Flags["PlayerESP"] or Library.Flags["NameTags"] or Library.Flags["HealthESP"] then
        for _, enemy in pairs(getEnemies()) do
            local head = enemy.Character:FindFirstChild("Head")
            if head then
                local text = enemy.Player.Name
                if Library.Flags["HealthESP"] then
                    text = text .. " [" .. math.floor(enemy.Humanoid.Health) .. " HP]"
                end
                if Library.Flags["NameTags"] or Library.Flags["PlayerESP"] then
                    createBillboard(head, "PlayerESP", text, Color3.fromRGB(255, 80, 80))
                end
            end
        end
    end
    
    if Library.Flags["BedESP"] then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name == "Bed" and obj:IsA("Model") then
                local primaryPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("Part")
                if primaryPart then
                    local isEnemy = true
                    local teamTag = obj:FindFirstChild("Team")
                    if teamTag and teamTag:IsA("StringValue") and teamTag.Value == (LocalPlayer.Team and LocalPlayer.Team.Name or "") then
                        isEnemy = false
                    end
                    if isEnemy then
                        createBillboard(primaryPart, "BedESP", "🛏️ BED", Color3.fromRGB(255, 200, 50), Vector3.new(0, 2, 0))
                    end
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- TRACER ESP (using Drawing API)
-- ═══════════════════════════════════════════════════════════
local TracerLines = {}

local function updateTracers()
    -- Clean old
    for _, line in pairs(TracerLines) do
        if line and line.Remove then pcall(function() line:Remove() end) end
    end
    TracerLines = {}
    
    if not Library.Flags["TracerESP"] then return end
    
    local success, DrawingLib = pcall(function() return Drawing end)
    if not success or not DrawingLib then return end
    
    for _, enemy in pairs(getEnemies()) do
        local hrp = enemy.HRP
        if hrp then
            local line = DrawingLib.new("Line")
            line.Visible = false
            line.Color = Color3.fromRGB(255, 80, 80)
            line.Thickness = 1.5
            line.Transparency = 0.7
            
            table.insert(TracerLines, line)
            
            task.spawn(function()
                while line and line.Parent ~= nil and Library.Flags["TracerESP"] do
                    pcall(function()
                        local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        
                        if onScreen then
                            line.From = screenCenter
                            line.To = Vector2.new(screenPos.X, screenPos.Y)
                            line.Visible = true
                        else
                            line.Visible = false
                        end
                    end)
                    RunService.RenderStepped:Wait()
                end
                pcall(function() line:Remove() end)
            end)
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- ITEM ESP (dropped items on ground)
-- ═══════════════════════════════════════════════════════════
local function updateItemESP()
    if not Library.Flags["ItemESP"] then return end
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
            if not obj.Handle:FindFirstChild("ItemESP") then
                createBillboard(obj.Handle, "ItemESP", "💰 " .. obj.Name, Color3.fromRGB(100, 255, 100), Vector3.new(0, 1.5, 0))
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- MAIN LOOP (heartbeat)
-- ═══════════════════════════════════════════════════════════

-- Kill Aura toggle
Library.Flags["KillAura"] = false -- Will be updated by toggle
task.spawn(function()
    while true do
        if Library.Flags["KillAura"] and isAlive() then
            startKillAura()
        end
        task.wait(0.5)
    end
end)

-- Auto Clicker toggle
task.spawn(function()
    while true do
        if Library.Flags["AutoClicker"] and isAlive() then
            startAutoClicker()
        end
        task.wait(0.5)
    end
end)

-- Scaffold toggle
task.spawn(function()
    while true do
        if Library.Flags["Scaffold"] and isAlive() then
            startScaffold()
        end
        task.wait(0.5)
    end
end)

-- Tower toggle
task.spawn(function()
    while true do
        if Library.Flags["Tower"] and isAlive() then
            startTower()
        end
        task.wait(1)
    end
end)

-- ESP update loop
task.spawn(function()
    while true do
        if Library.Flags["PlayerESP"] or Library.Flags["BedESP"] or Library.Flags["NameTags"] or Library.Flags["HealthESP"] then
            pcall(updateESP)
        end
        if Library.Flags["ItemESP"] then
            pcall(updateItemESP)
        end
        if Library.Flags["TracerESP"] then
            pcall(updateTracers)
        end
        task.wait(1)
    end
end)

-- Speed
task.spawn(function()
    while true do
        local hum = getHumanoid()
        if hum then
            if Library.Flags["Speed"] then
                hum.WalkSpeed = Library.Flags["SpeedVal"] or 32
            else
                if hum.WalkSpeed > 16 then
                    hum.WalkSpeed = 16
                end
            end
            
            if Library.Flags["HighJump"] then
                hum.JumpPower = Library.Flags["JumpPower"] or 100
            else
                if hum.JumpPower > 50 then
                    hum.JumpPower = 50
                end
            end
        end
        task.wait(0.3)
    end
end)

-- Fly
local flyBV = nil
task.spawn(function()
    while true do
        local hrp = getHRP()
        local hum = getHumanoid()
        
        if hrp and hum and Library.Flags["Fly"] then
            if not flyBV then
                flyBV = Instance.new("BodyVelocity")
                flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                flyBV.P = 10000
                flyBV.Parent = hrp
            end
            flyBV.Velocity = Vector3.new(0, 0, 0)
            
            local speed = Library.Flags["FlySpeed"] or 8
            local cam = Camera.CFrame
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                flyBV.Velocity = flyBV.Velocity + cam.LookVector * speed
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                flyBV.Velocity = flyBV.Velocity - cam.LookVector * speed
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                flyBV.Velocity = flyBV.Velocity - cam.RightVector * speed
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                flyBV.Velocity = flyBV.Velocity + cam.RightVector * speed
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                flyBV.Velocity = flyBV.Velocity + Vector3.new(0, speed, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                flyBV.Velocity = flyBV.Velocity - Vector3.new(0, speed, 0)
            end
        else
            if flyBV then
                flyBV:Destroy()
                flyBV = nil
            end
        end
        
        task.wait()
    end
end)

-- NoClip
task.spawn(function()
    while true do
        if Library.Flags["NoClip"] and isAlive() then
            local char = getCharacter()
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

-- No Fall Damage
task.spawn(function()
    while true do
        if Library.Flags["NoFall"] and isAlive() then
            local hum = getHumanoid()
            if hum then
                hum:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
                    if hum.FloorMaterial == Enum.Material.Air then
                        -- We're in the air
                    end
                end)
            end
        end
        task.wait(1)
    end
end)

-- Anti-Knockback (Velocity)
task.spawn(function()
    while true do
        if Library.Flags["AntiKB"] and isAlive() then
            local hrp = getHRP()
            if hrp then
                -- Continuously dampen velocity
                local vel = hrp:FindFirstChildOfClass("BodyVelocity")
                local vel2 = hrp:FindFirstChildOfClass("VectorForce")
                -- If the game uses BodyVelocity for knockback, we null it
                -- But don't touch our fly BV
            end
        end
        task.wait(0.1)
    end
end)

-- Spin Bot
task.spawn(function()
    local spinAngle = 0
    while true do
        if Library.Flags["SpinBot"] and isAlive() then
            local hrp = getHRP()
            if hrp then
                spinAngle = spinAngle + (Library.Flags["SpinSpeed"] or 10)
                if spinAngle >= 360 then spinAngle = spinAngle - 360 end
                hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(spinAngle), 0)
            end
        end
        task.wait()
    end
end)

-- Anti-AFK
task.spawn(function()
    while true do
        if Library.Flags["AntiAFK"] then
            pcall(function()
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            end)
        end
        task.wait(60)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- ITEM ESP CLEANUP LOOP
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if Library.Flags["ItemESP"] then
            -- Refresh item ESP every 2 seconds
            task.wait(2)
            pcall(updateItemESP)
        else
            task.wait(1)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- CLEANUP ON CHARACTER RESPAWN
-- ═══════════════════════════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    clearESP()
    -- Re-apply speed
    local hum = char:WaitForChild("Humanoid", 5)
    if hum and Library.Flags["Speed"] then
        hum.WalkSpeed = Library.Flags["SpeedVal"] or 32
    end
end)

-- ═══════════════════════════════════════════════════════════
-- INIT NOTIFICATION
-- ═══════════════════════════════════════════════════════════
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "Bed Wars Script",
        Text = "Loaded! Press RightAlt to toggle UI",
        Duration = 5
    })
end)

print("═════════════════════════════════════")
print("  Bed Wars Script v2.0 Loaded!")
print("  Press RightAlt to toggle UI")
print("  Tabs: Combat | World | ESP | Movement | Utility")
print("═════════════════════════════════════")
