--!nocheck
-- BED WARS ULTIMATE v5.1 (CatVape-style)
-- Built: 2026-08-27 10:41:02
if shared.BWLoaded then warn('[BedWars] Already loaded!') return end
shared.BWLoaded = true

-- CORE
local function createCore()
--!nocheck
-- ═══════════════════════════════════════════════════════════════
-- BEDWARS CORE MODULE (CatVape-style)
-- Services, Config, Performance, Utils
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local lplr = Players.LocalPlayer

-- ═══ Shared State ═══
local BW = {
    LocalPlayer = lplr,
    Camera = workspace.CurrentCamera,
    Workspace = workspace,
    Players = Players,
    RunService = RunService,
    UserInputService = UserInputService,
    TweenService = TweenService,
    Lighting = Lighting,
    ReplicatedStorage = ReplicatedStorage,
    StarterGui = StarterGui,
    Flags = {},
    Connections = {},
    ESP_BBs = {},
    Config = {},
    WebhookURL = "",
}

-- ═══ Performance Cache ═══
local Perf = {
    Cache = {},
    CacheTime = {},
    FPS = 60,
    LastFrame = tick(),
    FrameCount = 0,
}

function Perf:GetDescendants(interval)
    interval = interval or 2
    local key = "all"
    local now = tick()
    if not self.Cache[key] or (now - (self.CacheTime[key] or 0)) > interval then
        self.Cache[key] = workspace:GetDescendants()
        self.CacheTime[key] = now
    end
    return self.Cache[key]
end

function Perf:CleanupCache()
    local now = tick()
    for key, time in pairs(self.CacheTime) do
        if now - time > 30 then
            self.Cache[key] = nil
            self.CacheTime[key] = nil
        end
    end
end

BW.Perf = Perf

-- ═══ Utility Functions ═══
function BW.alive()
    local char = lplr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return hum and hrp and hum.Health > 0
end

function BW.hrp()
    local char = lplr.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

function BW.hum()
    local char = lplr.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

function BW.char()
    return lplr.Character
end

function BW.enemies()
    local enemies = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= lplr then
            local char = player.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local isEnemy = true
                    if BW.Flags.TeamCheck and lplr.Team and player.Team == lplr.Team then
                        isEnemy = false
                    end
                    if isEnemy then
                        table.insert(enemies, {Player = player, Char = char, HRP = hrp, Hum = hum})
                    end
                end
            end
        end
    end
    return enemies
end

function BW.nearestEnemy(maxDist)
    maxDist = maxDist or math.huge
    local myHRP = BW.hrp()
    if not myHRP then return nil, math.huge end
    local nearest, nearDist = nil, maxDist
    for _, e in pairs(BW.enemies()) do
        local dist = (myHRP.Position - e.HRP.Position).Magnitude
        if dist < nearDist then
            nearest, nearDist = e, dist
        end
    end
    return nearest, nearDist
end

function BW.hasLineOfSight(pos1, pos2)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {lplr.Character}
    local result = workspace:Raycast(pos1, (pos2 - pos1), params)
    return result == nil
end

function BW.tool()
    local char = lplr.Character
    return char and char:FindFirstChildWhichIsA("Tool", true)
end

function BW.equipTool(name)
    local char = lplr.Character
    if not char then return false end
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find(name:lower()) then
            if not tool.Parent:IsA("Humanoid") then
                tool.Parent = char
            end
            return true
        end
    end
    return false
end

function BW.findTool(name)
    local char = lplr.Character
    if not char then return nil end
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find(name:lower()) then
            return tool
        end
    end
    return nil
end

function BW.getInventory()
    return {iron = 0, gold = 0, diamond = 0, emerald = 0, blocks = 0}, 0
end

function BW.buyItem(itemType)
    pcall(function()
        local Client = require(ReplicatedStorage.TS.remotes).default.Client
        Client:GetNamespace("Shop"):Get("PurchaseItem"):SendToServer({
            shopItem = {itemType = itemType, shopId = "main"}
        })
    end)
end

function BW.placeBlock(blockType, position)
    pcall(function()
        local Client = require(ReplicatedStorage.TS.remotes).default.Client
        Client:GetNamespace("Block"):Get("PlaceBlock"):SendToServer({
            blockType = blockType,
            position = position,
            normal = Vector3.new(0, 1, 0)
        })
    end)
end

function BW.SendWebhook(title, desc, color)
    -- Placeholder
end

function BW.SaveConfig()
    -- Placeholder
end

function BW.LoadConfig()
    -- Placeholder
end

-- ═══ Auto Cleanup ═══
task.spawn(function()
    while task.wait(30) do
        Perf:CleanupCache()
        pcall(collectgarbage, "collect")
    end
end)

-- ═══ FPS Counter ═══
RunService.RenderStepped:Connect(function()
    Perf.FrameCount = Perf.FrameCount + 1
    if tick() - Perf.LastFrame >= 1 then
        Perf.FPS = Perf.FrameCount
        Perf.FrameCount = 0
        Perf.LastFrame = tick()
    end
end)

return BW

end

-- API
local function createAPI(bw)
--!nocheck
-- ═══════════════════════════════════════════════════════════════
-- BEDWARS API BRIDGE (CatVape-style)
-- Direct access to Knit controllers, Flamework, Client Remotes
-- ═══════════════════════════════════════════════════════════════

local API = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lplr = Players.LocalPlayer

-- ═══ Knit Framework ═══
local KnitInit, Knit
repeat
    KnitInit, Knit = pcall(function()
        return debug.getupvalue(require(lplr.PlayerScripts.TS.knit).setup, 9)
    end)
    if KnitInit then break end
    task.wait()
until KnitInit

if not debug.getupvalue(Knit.Start, 1) then
    repeat task.wait() until debug.getupvalue(Knit.Start, 1)
end

-- ═══ Flamework + Client Remotes ═══
local Flamework = require(
    ReplicatedStorage["rbxts_include"]["node_modules"]["@flamework"].core.out
).Flamework

local Client = require(ReplicatedStorage.TS.remotes).default.Client

-- ═══ BedWars Object (auto-loads Knit controllers) ═══
local bedwars = setmetatable({
    Client = Client,
    Store = require(lplr.PlayerScripts.TS.ui.store).ClientStore,
    Flamework = Flamework,
}, {
    __index = function(self, ind)
        local success, result = pcall(function()
            return Knit.Controllers[ind]
        end)
        if success and result then
            rawset(self, ind, result)
            return result
        end
        return nil
    end
})

API.bw = bedwars
API.Knit = Knit
API.Client = Client
API.Store = bedwars.Store

-- ═══ Remote Event Helper ═══
function API.fireRemote(namespace, method, data)
    pcall(function()
        Client:GetNamespace(namespace):Get(method):SendToServer(data or {})
    end)
end

function API.callRemote(namespace, method, data)
    local success, result = pcall(function()
        return Client:GetNamespace(namespace):Get(method):CallServer(data or {})
    end)
    return (success and result) or nil
end

-- ═══ State Access ═══
function API.getState()
    local success, state = pcall(function()
        return API.Store:getState()
    end)
    return success and state or {}
end

function API.getBedwarsState()
    local state = API.getState()
    return state.Bedwars or {}
end

-- ═══ Controller Shortcuts ═══
function API.getSprint()
    return bedwars.SprintController
end

function API.getShop()
    return bedwars.ShopController
end

function API.getInventory()
    return bedwars.BedwarsInventoryController or bedwars.InventoryController
end

function API.getBlock()
    return bedwars.BlockController
end

function API.getProjectile()
    return bedwars.ProjectileController
end

function API.getDamage()
    return bedwars.DamageController
end

function API.getBalloon()
    return bedwars.BalloonController
end

function API.getPickaxe()
    return bedwars.PickaxeController
end

function API.getWeld()
    return bedwars.WeldController
end

function API.getScreenGui()
    return bedwars.ScreenguiController
end

function API.getEffect()
    return bedwars.EffectController
end

function API.getSound()
    return bedwars.SoundController
end

function API.getEmote()
    return bedwars.EmoteShopController
end

function API.getAnimation()
    return bedwars.AnimationController
end

function API.getCrate()
    return bedwars.CrateAltarController
end

-- ═══ Item Metadata ═══
function API.getItemMeta(itemType)
    local success, meta = pcall(function()
        return require(ReplicatedStorage.TS.item["item-meta"]).getItemMeta(itemType)
    end)
    return (success and meta) or nil
end

-- ═══ Kit Abilities ═══
function API.useKitAbility(abilityName, data)
    API.fireRemote("Ability", "UseAbility", {
        ability = abilityName,
        ["data"] = data or {}
    })
end

-- ═══ Shop Buying ═══
function API.buyItem(itemType, shopType)
    local shop = API.getShop()
    if shop and shop.purchaseItem then
        pcall(function()
            shop:purchaseItem(itemType, shopType or "main")
        end)
    else
        API.fireRemote("Shop", "PurchaseItem", {
            itemType = itemType,
            shopType = shopType or "main"
        })
    end
end

-- ═══ Block Placing ═══
function API.placeBlock(blockType, position, normal)
    local block = API.getBlock()
    if block and block.placeBlock then
        pcall(function()
            block:placeBlock(blockType, position, normal or Vector3.new(0, 1, 0))
        end)
    else
        API.fireRemote("Block", "PlaceBlock", {
            blockType = blockType,
            position = position,
            normal = normal or Vector3.new(0, 1, 0)
        })
    end
end

-- ═══ Projectile Shooting ═══
function API.shootProjectile(projectileType, position, direction, shootPart, shootPos, meta)
    local proj = API.getProjectile()
    if proj and proj.fire then
        pcall(function()
            proj:fire(projectileType, position, direction, shootPart, shootPos, meta)
        end)
    end
end

-- ═══ Sprint ═══
function API.startSprint()
    local sprint = API.getSprint()
    if sprint then
        pcall(function() sprint:startSprinting() end)
    end
end

function API.stopSprint()
    local sprint = API.getSprint()
    if sprint then
        pcall(function() sprint:stopSprinting() end)
    end
end

-- ═══ Inventory ═══
function API.getInventoryItems()
    local state = API.getBedwarsState()
    return state.inventory or {}
end

function API.equipItem(slot)
    API.fireRemote("Inventory", "EquipItemInSlot", {slot = slot})
end

function API.dropItem(slot, count)
    API.fireRemote("Inventory", "DropItemInSlot", {slot = slot, count = count})
end

-- ═══ Utility Functions ═══

-- Check if a player is alive
function API.isAlive(player)
    player = player or lplr
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return hum and hrp and hum.Health > 0
end

-- Get character parts
function API.getCharacterParts(player)
    player = player or lplr
    local char = player.Character
    if not char then return nil end
    return {
        Character = char,
        Humanoid = char:FindFirstChildOfClass("Humanoid"),
        RootPart = char:FindFirstChild("HumanoidRootPart"),
        Head = char:FindFirstChild("Head"),
        HumanoidRootPart = char:FindFirstChild("HumanoidRootPart"),
    }
end

-- Get all enemy players
function API.getEnemies()
    local enemies = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= lplr and player.Team ~= lplr.Team then
            if API.isAlive(player) then
                table.insert(enemies, player)
            end
        end
    end
    return enemies
end

-- Get nearest enemy
function API.getNearestEnemy(maxDist)
    maxDist = maxDist or math.huge
    local myChar = lplr.Character
    if not myChar then return nil end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    
    local nearest, nearestDist = nil, maxDist
    for _, player in pairs(API.getEnemies()) do
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (myHRP.Position - hrp.Position).Magnitude
                if dist < nearestDist then
                    nearest, nearestDist = player, dist
                end
            end
        end
    end
    return nearest, nearestDist
end

-- Check line of sight
function API.hasLineOfSight(pos1, pos2)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {lplr.Character}
    local result = workspace:Raycast(pos1, (pos2 - pos1), params)
    return result == nil
end

-- Get equipped tool
function API.getEquippedTool()
    local char = lplr.Character
    if not char then return nil end
    return char:FindFirstChildWhichIsA("Tool", true)
end

-- Get block count in inventory
function API.getBlockCount(blockType)
    local items = API.getInventoryItems()
    local count = 0
    for _, item in pairs(items) do
        if item.itemType == blockType or (not blockType and item.itemType:find("block")) then
            count = count + (item.count or 1)
        end
    end
    return count
end

-- Get resource count
function API.getResourceCount(resourceType)
    local state = API.getBedwarsState()
    local resources = state.resources or {}
    return resources[resourceType] or 0
end

-- Check if has item
function API.hasItem(itemType)
    local items = API.getInventoryItems()
    for _, item in pairs(items) do
        if item.itemType == itemType then
            return true, item.count or 1
        end
    end
    return false, 0
end

return API

end

-- UI
local function createUI(bw, flags, api)
-- ══════════════════════════════════════════════════════════════
-- UI LIBRARY MODULE (Luau-safe, no nested and/or)
-- ══════════════════════════════════════════════════════════════
BW = bw  -- Make BW global for UI module
local Library = {}
Library.__index = Library

-- Helper: safe UDim2 with mobile support
local function mobileUDim2(w, h, mobileW, mobileH)
    if BW.isMobile then
        return UDim2.new(0, mobileW or w, 0, mobileH or h)
    end
    return UDim2.new(0, w, 0, h)
end

local function mobileScaleUDim2(w1, w2, h1, h2, mw1, mw2, mh1, mh2)
    if BW.isMobile then
        return UDim2.new(mw1 or w1, mw2 or w2, mh1 or h1, mh2 or h2)
    end
    return UDim2.new(w1, w2, h1, h2)
end

local function ifelse(cond, a, b)
    if cond then return a else return b end
end

function Library:New(config)
    local self = setmetatable({}, Library)
    self.Flags = BW.Flags
    self.Config = config or {Title="BedWars", Sub="v5.0"}
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
    tb.Size = UDim2.new(1, 0, 0, ifelse(BW.isMobile, 50, 38))
    tb.BackgroundColor3 = Color3.fromRGB(22, 22, 35)
    tb.BorderSizePixel = 0
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 12)

    local tl = Instance.new("TextLabel", tb)
    tl.Size = UDim2.new(0.5, 0, 1, 0)
    tl.Position = UDim2.new(0, 14, 0, 0)
    tl.BackgroundTransparency = 1
    tl.Text = "⚔️ " .. self.Config.Title .. " | " .. self.Config.Sub
    tl.TextColor3 = Color3.fromRGB(80, 180, 255)
    tl.TextSize = ifelse(BW.isMobile, 16, 14)
    tl.Font = Enum.Font.GothamBold
    tl.TextXAlignment = Enum.TextXAlignment.Left

    local kb = Instance.new("TextLabel", tb)
    kb.Size = UDim2.new(0.5, -14, 1, 0)
    kb.Position = UDim2.new(0.5, 0, 0, 0)
    kb.BackgroundTransparency = 1
    kb.Text = ifelse(BW.isMobile, "📱 Touch toggle", "RightAlt toggle")
    kb.TextColor3 = Color3.fromRGB(100, 100, 120)
    kb.TextSize = ifelse(BW.isMobile, 12, 11)
    kb.Font = Enum.Font.Gotham
    kb.TextXAlignment = Enum.TextXAlignment.Right

    local closeBtn = Instance.new("TextButton", tb)
    closeBtn.Size = UDim2.new(0, ifelse(BW.isMobile, 40, 30), 0, ifelse(BW.isMobile, 36, 26))
    closeBtn.Position = UDim2.new(1, ifelse(BW.isMobile, -48, -36), 0.5, ifelse(BW.isMobile, -18, -13))
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.TextSize = ifelse(BW.isMobile, 18, 14)
    closeBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

    local sidebar = Instance.new("Frame", main)
    if BW.isMobile then
        sidebar.Size = UDim2.new(1, -10, 0, 40)
        sidebar.Position = UDim2.new(0, 5, 0, 55)
        local layout = Instance.new("UIListLayout", sidebar)
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.Padding = UDim.new(0, 4)
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
    if BW.isMobile then
        btn.Size = UDim2.new(0, 70, 1, 0)
        btn.TextSize = 10
    else
        btn.Size = UDim2.new(1, 0, 0, 28)
        btn.TextSize = 11
    end
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
        for _, c in pairs(self.Content:GetChildren()) do
            if c:IsA("ScrollingFrame") then c.Visible = false end
        end
        for _, c in pairs(self.Sidebar:GetChildren()) do
            if c:IsA("TextButton") then
                c.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
                c.TextColor3 = Color3.fromRGB(140, 140, 160)
            end
        end
        pf.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(40, 70, 130)
        btn.TextColor3 = Color3.new(1, 1, 1)
        self.CurrentPage = name
    end)

    function page:Toggle(cfg)
        local f = Instance.new("Frame", pf)
        f.Size = UDim2.new(1, 0, 0, ifelse(BW.isMobile, 44, 32))
        f.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
        f.BorderSizePixel = 0
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        local lbl = Instance.new("TextLabel", f)
        lbl.Size = UDim2.new(0.7, 0, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = cfg.Name
        lbl.TextColor3 = Color3.fromRGB(190, 190, 200)
        lbl.TextSize = ifelse(BW.isMobile, 14, 12)
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local tb = Instance.new("TextButton", f)
        local tbW = ifelse(BW.isMobile, 50, 40)
        local tbH = ifelse(BW.isMobile, 26, 20)
        tb.Size = UDim2.new(0, tbW, 0, tbH)
        tb.Position = UDim2.new(1, ifelse(BW.isMobile, -60, -50), 0.5, ifelse(BW.isMobile, -13, -10))
        tb.BackgroundColor3 = ifelse(cfg.Default, Color3.fromRGB(70, 170, 70), Color3.fromRGB(50, 50, 62))
        tb.BorderSizePixel = 0
        tb.Text = ""
        Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 10)

        local ci = Instance.new("Frame", tb)
        local ciSize = ifelse(BW.isMobile, 20, 16)
        ci.Size = UDim2.new(0, ciSize, 0, ciSize)
        if cfg.Default then
            ci.Position = UDim2.new(1, ifelse(BW.isMobile, -23, -19), 0.5, -8)
        else
            ci.Position = UDim2.new(0, 3, 0.5, -8)
        end
        ci.BackgroundColor3 = Color3.new(1, 1, 1)
        ci.BorderSizePixel = 0
        Instance.new("UICorner", ci).CornerRadius = UDim.new(0, 8)

        local on = ifelse(cfg.Default, true, false)
        BW.Flags[cfg.Flag] = on

        tb.MouseButton1Click:Connect(function()
            on = not on
            BW.Flags[cfg.Flag] = on
            local bg = ifelse(on, Color3.fromRGB(70, 170, 70), Color3.fromRGB(50, 50, 62))
            local pos
            if on then
                pos = UDim2.new(1, ifelse(BW.isMobile, -23, -19), 0.5, -8)
            else
                pos = UDim2.new(0, 3, 0.5, -8)
            end
            BW.TweenService:Create(tb, TweenInfo.new(0.15), {BackgroundColor3 = bg}):Play()
            BW.TweenService:Create(ci, TweenInfo.new(0.15), {Position = pos}):Play()
        end)
    end

    function page:Slider(cfg)
        local min = ifelse(cfg.Min, cfg.Min, 0)
        local max = ifelse(cfg.Max, cfg.Max, 100)
        local def = ifelse(cfg.Default, cfg.Default, 0)
        local f = Instance.new("Frame", pf)
        f.Size = UDim2.new(1, 0, 0, 42)
        f.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
        f.BorderSizePixel = 0
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        local lbl = Instance.new("TextLabel", f)
        lbl.Size = UDim2.new(0.55, 0, 0, 18)
        lbl.Position = UDim2.new(0, 10, 0, 3)
        lbl.BackgroundTransparency = 1
        lbl.Text = cfg.Name
        lbl.TextColor3 = Color3.fromRGB(190, 190, 200)
        lbl.TextSize = 12
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        local vl = Instance.new("TextLabel", f)
        vl.Size = UDim2.new(0.4, 0, 0, 18)
        vl.Position = UDim2.new(0.6, 0, 0, 3)
        vl.BackgroundTransparency = 1
        vl.Text = tostring(def)
        vl.TextColor3 = Color3.fromRGB(80, 180, 255)
        vl.TextSize = 12
        vl.Font = Enum.Font.GothamBold
        vl.TextXAlignment = Enum.TextXAlignment.Right
        local bg = Instance.new("Frame", f)
        bg.Size = UDim2.new(1, -20, 0, 5)
        bg.Position = UDim2.new(0, 10, 0, 28)
        bg.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
        bg.BorderSizePixel = 0
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 3)
        local fill = Instance.new("Frame", bg)
        fill.Size = UDim2.new((def - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(70, 150, 255)
        fill.BorderSizePixel = 0
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)
        local knob = Instance.new("Frame", bg)
        knob.Size = UDim2.new(0, 12, 0, 12)
        knob.Position = UDim2.new((def - min) / (max - min), -6, 0.5, -6)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.BorderSizePixel = 0
        Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 6)
        BW.Flags[cfg.Flag] = def
        local drag = false
        bg.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true end
        end)
        BW.UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
        end)
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
        f.Size = UDim2.new(1, 0, 0, 32)
        f.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
        f.BorderSizePixel = 0
        f.ClipsDescendants = true
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        local lbl = Instance.new("TextLabel", f)
        lbl.Size = UDim2.new(0.5, 0, 0, 32)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = cfg.Name
        lbl.TextColor3 = Color3.fromRGB(190, 190, 200)
        lbl.TextSize = 12
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        local sel = Instance.new("TextButton", f)
        sel.Size = UDim2.new(0.45, -8, 0, 24)
        sel.Position = UDim2.new(0.55, 0, 0, 4)
        sel.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        sel.BorderSizePixel = 0
        local defaultVal = ifelse(cfg.Default, cfg.Default, cfg.Options[1])
        sel.Text = "  " .. defaultVal
        sel.TextColor3 = Color3.fromRGB(180, 180, 190)
        sel.TextSize = 11
        sel.Font = Enum.Font.Gotham
        sel.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", sel).CornerRadius = UDim.new(0, 5)
        BW.Flags[cfg.Flag] = defaultVal
        local open = false
        sel.MouseButton1Click:Connect(function()
            open = not open
            f.Size = UDim2.new(1, 0, 0, ifelse(open, 32 + #cfg.Options * 26 + 4, 32))
        end)
        for i, opt in ipairs(cfg.Options) do
            local ob = Instance.new("TextButton", f)
            ob.Size = UDim2.new(1, 0, 0, 24)
            ob.Position = UDim2.new(0, 0, 0, 32 + (i - 1) * 26)
            ob.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
            ob.BorderSizePixel = 0
            ob.Text = "  " .. opt
            ob.TextColor3 = Color3.fromRGB(170, 170, 180)
            ob.TextSize = 11
            ob.Font = Enum.Font.Gotham
            ob.TextXAlignment = Enum.TextXAlignment.Left
            ob.MouseButton1Click:Connect(function()
                sel.Text = "  " .. opt
                BW.Flags[cfg.Flag] = opt
                open = false
                f.Size = UDim2.new(1, 0, 0, 32)
            end)
        end
    end

    function page:Button(cfg)
        local b = Instance.new("TextButton", pf)
        b.Size = UDim2.new(1, 0, 0, 30)
        b.BackgroundColor3 = ifelse(cfg.Color, cfg.Color, Color3.fromRGB(45, 75, 130))
        b.BorderSizePixel = 0
        b.Text = cfg.Name
        b.TextColor3 = Color3.new(1, 1, 1)
        b.TextSize = 12
        b.Font = Enum.Font.GothamBold
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        b.MouseButton1Click:Connect(function()
            if cfg.Callback then cfg.Callback() end
        end)
    end

    function page:Label(text)
        local l = Instance.new("TextLabel", pf)
        l.Size = UDim2.new(1, 0, 0, 20)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = Color3.fromRGB(100, 100, 120)
        l.TextSize = 10
        l.Font = Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Left
    end

    function page:Separator()
        local s = Instance.new("Frame", pf)
        s.Size = UDim2.new(1, 0, 0, 1)
        s.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        s.BorderSizePixel = 0
    end

    function page:Input(cfg)
        local f = Instance.new("Frame", pf)
        f.Size = UDim2.new(1, 0, 0, 32)
        f.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
        f.BorderSizePixel = 0
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        local lbl = Instance.new("TextLabel", f)
        lbl.Size = UDim2.new(0.4, 0, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = cfg.Name
        lbl.TextColor3 = Color3.fromRGB(190, 190, 200)
        lbl.TextSize = 12
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        local tb = Instance.new("TextBox", f)
        tb.Size = UDim2.new(0.55, -8, 0, 22)
        tb.Position = UDim2.new(0.45, 0, 0.5, -11)
        tb.BackgroundColor3 = Color3.fromRGB(38, 38, 52)
        tb.BorderSizePixel = 0
        tb.Text = ifelse(cfg.Default, cfg.Default, "")
        tb.TextColor3 = Color3.fromRGB(200, 200, 210)
        tb.PlaceholderText = ifelse(cfg.Placeholder, cfg.Placeholder, "")
        tb.PlaceholderColor3 = Color3.fromRGB(80, 80, 100)
        tb.TextSize = 11
        tb.Font = Enum.Font.Gotham
        tb.ClearTextOnFocus = false
        Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 5)
        BW.Flags[cfg.Flag] = ifelse(cfg.Default, cfg.Default, "")
        tb.FocusLost:Connect(function()
            BW.Flags[cfg.Flag] = tb.Text
        end)
    end

    self.Pages[name] = page
    return page
end

BW.Library = Library
print("[UI] Library loaded")

BW.Library = Library
print("[UI] Library loaded")
return Library

end

-- COMBAT
local function load_combat(bw, flags, ui, api)
--!nocheck
-- ═══════════════════════════════════════════════════════════════
-- BEDWARS COMBAT MODULE (CatVape-style APIs)
-- Kill Aura, Crystal Aura, Auto Clicker, Sprint, Silent Aim
-- ═══════════════════════════════════════════════════════════════

return function(BW, Flags, UI, api)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local lplr = Players.LocalPlayer
    local bw = api.bw

    -- ═══ Sprint (Game Controller) ═══
    UI:Tab("Combat")
    UI:Toggle("Sprint", false, function(v)
        Flags.Sprint = v
        if v then
            pcall(function() bw.SprintController:startSprinting() end)
            -- Hook stopSprinting to auto-resume
            if not Flags._sprintHooked then
                Flags._sprintHooked = true
                Flags._oldStopSprint = bw.SprintController.stopSprinting
                bw.SprintController.stopSprinting = function(...)
                    local call = Flags._oldStopSprint(...)
                    if Flags.Sprint then
                        pcall(function() bw.SprintController:startSprinting() end)
                    end
                    return call
                end
            end
        else
            if Flags._oldStopSprint then
                bw.SprintController.stopSprinting = Flags._oldStopSprint
                Flags._oldStopSprint = nil
                Flags._sprintHooked = false
            end
            pcall(function() bw.SprintController:stopSprinting() end)
        end
    end, "Combat", "Auto sprint (uses game controller)")

    -- ═══ Kill Aura ═══
    UI:Toggle("Kill Aura", false, function(v) Flags.KA = v end, "Combat", "Auto attack nearest enemy")
    UI:Slider("KA Range", 5, 20, 18, function(v) Flags.KA_Range = v end, "Combat")
    UI:Slider("KA Speed", 1, 20, 12, function(v) Flags.KA_Speed = v end, "Combat")
    UI:Toggle("KA Auto Swing", true, function(v) Flags.KA_Swing = v end, "Combat")
    UI:Toggle("KA Rotate", false, function(v) Flags.KA_Rotate = v end, "Combat", "Rotate to face target")
    UI:Toggle("KA Multi", false, function(v) Flags.KA_Multi = v end, "Combat", "Attack multiple targets")

    task.spawn(function()
        while task.wait() do
            if Flags.KA and api.isAlive() then
                local myChar = lplr.Character
                local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if not myHRP then continue end

                -- Find enemies in range
                local targets = {}
                for _, enemy in pairs(api.getEnemies()) do
                    local eChar = enemy.Character
                    local eHRP = eChar and eChar:FindFirstChild("HumanoidRootPart")
                    if eHRP then
                        local dist = (myHRP.Position - eHRP.Position).Magnitude
                        if dist <= (Flags.KA_Range or 18) then
                            table.insert(targets, {Player = enemy, Dist = dist, HRP = eHRP})
                        end
                    end
                end

                -- Sort by distance
                table.sort(targets, function(a, b) return a.Dist < b.Dist end)

                -- Attack targets
                local maxTargets = Flags.KA_Multi and math.min(#targets, 3) or 1
                for i = 1, maxTargets do
                    local target = targets[i]
                    if target then
                        -- Rotate to face target
                        if Flags.KA_Rotate then
                            local lookDir = (target.HRP.Position - myHRP.Position).Unit
                            myHRP.CFrame = CFrame.new(myHRP.Position, myHRP.Position + Vector3.new(lookDir.X, 0, lookDir.Z))
                        end

                        -- Equip sword
                        local tool = api.getEquippedTool()
                        if not tool or not tool.Name:find("sword") then
                            -- Try to equip sword from inventory
                            pcall(function()
                                bw.BedwarsInventoryController:equipItemInHotbar(
                                    api.hasItem("sword") and 1 or api.hasItem("wood_sword") and 2 or 1
                                )
                            end)
                            task.wait(0.1)
                        end

                        -- Swing attack
                        if Flags.KA_Swing then
                            pcall(function()
                                tool:Activate()
                            end)
                        end

                        -- Fire damage remote
                        api.fireRemote("Damage", "DamagePlayer", {
                            player = target.Player,
                            damage = 20,
                            -- sword type will be auto-detected by server
                        })

                        task.wait(1 / (Flags.KA_Speed or 12))
                    end
                end
            end
        end
    end)

    -- ═══ Crystal Aura ═══
    UI:Toggle("Crystal Aura", false, function(v) Flags.CA = v end, "Combat", "Auto place & break crystals")
    UI:Slider("CA Range", 3, 15, 8, function(v) Flags.CA_Range = v end, "Combat")
    UI:Slider("CA Delay", 0, 200, 50, function(v) Flags.CA_Delay = v / 1000 end, "Combat")
    UI:Toggle("CA Auto Break", true, function(v) Flags.CA_Break = v end, "Combat")

    task.spawn(function()
        while task.wait() do
            if Flags.CA and api.isAlive() then
                local myHRP = lplr.Character:FindFirstChild("HumanoidRootPart")
                if not myHRP then continue end

                -- Find nearest enemy
                local enemy, dist = api.getNearestEnemy(Flags.CA_Range or 8)
                if enemy and dist then
                    -- Find crystals near enemy
                    local eHRP = enemy.Character:FindFirstChild("HumanoidRootPart")
                    if eHRP then
                        local crystals = {}
                        for _, obj in pairs(workspace:GetChildren()) do
                            if obj.Name:find("Crystal") and obj:IsA("Model") then
                                local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                                if primary then
                                    local cDist = (eHRP.Position - primary.Position).Magnitude
                                    if cDist <= 10 then
                                        table.insert(crystals, {Obj = obj, Part = primary, Dist = cDist})
                                    end
                                end
                            end
                        end

                        -- Break enemy crystals
                        if Flags.CA_Break and #crystals > 0 then
                            for _, c in pairs(crystals) do
                                api.fireRemote("Crystal", "BreakCrystal", {crystal = c.Obj})
                                task.wait(Flags.CA_Delay or 0.05)
                            end
                        end

                        -- Place crystal near enemy
                        local placePos = eHRP.Position + Vector3.new(
                            math.random(-3, 3), 1, math.random(-3, 3)
                        )
                        api.fireRemote("Crystal", "PlaceCrystal", {
                            position = placePos
                        })
                    end
                end

                task.wait(Flags.CA_Delay or 0.05)
            end
        end
    end)

    -- ═══ Auto Clicker ═══
    UI:Toggle("Auto Click", false, function(v) Flags.AutoClick = v end, "Combat", "Auto click attack")
    UI:Slider("Click CPS", 5, 20, 14, function(v) Flags.ClickCPS = v end, "Combat")

    task.spawn(function()
        while task.wait() do
            if Flags.AutoClick and api.isAlive() then
                local tool = api.getEquippedTool()
                if tool then
                    tool:Activate()
                    task.wait(1 / (Flags.ClickCPS or 14))
                end
            end
        end
    end)

    -- ═══ Silent Aim ═══
    UI:Toggle("Silent Aim", false, function(v) Flags.SilentAim = v end, "Combat", "Silent aimbot (no visual)")
    UI:Slider("SA FOV", 10, 180, 90, function(v) Flags.SA_FOV = v end, "Combat")
    UI:Toggle("SA Headshot", false, function(v) Flags.SA_Head = v end, "Combat")
    UI:Toggle("SA Wall Check", true, function(v) Flags.SA_Wall = v end, "Combat")

    -- ═══ Trigger Bot ═══
    UI:Toggle("Trigger Bot", false, function(v) Flags.TriggerBot = v end, "Combat", "Auto shoot when aimed at enemy")

    task.spawn(function()
        while task.wait() do
            if Flags.TriggerBot and api.isAlive() then
                local mouse = lplr:GetMouse()
                if mouse and mouse.Target then
                    local hit = mouse.Target
                    -- Check if it's an enemy part
                    for _, enemy in pairs(api.getEnemies()) do
                        if enemy.Character and hit:IsDescendantOf(enemy.Character) then
                            local tool = api.getEquippedTool()
                            if tool then
                                tool:Activate()
                            end
                            break
                        end
                    end
                end
            end
        end
    end)

    -- ═══ Auto Release (Bow) ═══
    UI:Toggle("Auto Release", false, function(v) Flags.AutoRelease = v end, "Combat", "Auto release bow")
    UI:Slider("Release %", 10, 100, 80, function(v) Flags.ReleasePercent = v end, "Combat")

    -- ═══ Projectile Aimbot ═══
    UI:Toggle("Proj Aimbot", false, function(v) Flags.ProjAim = v end, "Combat", "Predictive aim for projectiles")
    UI:Slider("Proj FOV", 10, 180, 60, function(v) Flags.ProjFOV = v end, "Combat")
end

end

-- WORLD
local function load_world(bw, flags, ui, api)
--!nocheck
-- ═══════════════════════════════════════════════════════════════
-- BEDWARS WORLD MODULE (CatVape-style APIs)
-- Scaffold, Nuker, Auto Collect, Bed Protector
-- ═══════════════════════════════════════════════════════════════

return function(BW, Flags, UI, api)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local lplr = Players.LocalPlayer
    local bw = api.bw

    -- ═══ Scaffold (Auto Bridge) ═══
    UI:Tab("World")
    UI:Toggle("Scaffold", false, function(v) Flags.Scaffold = v end, "World", "Auto place blocks under you")
    UI:Toggle("Scaffold Down", false, function(v) Flags.ScaffoldDown = v end, "World", "Place blocks downward")
    UI:Slider("Scaffold Width", 1, 3, 1, function(v) Flags.ScaffoldWidth = v end, "World")
    UI:Toggle("Scaffold Tower", false, function(v) Flags.ScaffoldTower = v end, "World", "Tower mode (hold space)")
    UI:Toggle("Scaffold Safe", true, function(v) Flags.ScaffoldSafe = v end, "World", "Extra safety checks")

    -- Track placed blocks to avoid duplicates
    local placedBlocks = {}

    RunService.Heartbeat:Connect(function()
        if not Flags.Scaffold or not api.isAlive() then return end

        local myChar = lplr.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if not myHRP or not myHum then return end

        -- Find best block to place
        local blockType = nil
        local blockNames = {"wool_white", "wool_light_gray", "wool", "stone", "obsidian", "end_stone"}
        for _, name in pairs(blockNames) do
            if api.hasItem(name) then
                blockType = name
                break
            end
        end
        if not blockType then return end

        -- Get placement position
        local lookDir = myHRP.CFrame.LookVector
        local velocity = myHRP.Velocity
        local movingForward = velocity.Magnitude > 2 and lookDir:Dot(velocity.Unit) > 0.5

        if movingForward or Flags.ScaffoldDown then
            local pos = myHRP.Position + Vector3.new(0, -3.5, 0)
            if Flags.ScaffoldDown then
                pos = myHRP.Position + Vector3.new(0, -4.5, 0)
            end

            -- Use BlockController to place
            local block = bw.BlockController
            if block and block.placeBlock then
                pcall(function()
                    block:placeBlock(blockType, pos, Vector3.new(0, 1, 0))
                end)
            else
                -- Fallback: use remote
                api.fireRemote("Block", "PlaceBlock", {
                    blockType = blockType,
                    position = pos,
                    normal = Vector3.new(0, 1, 0),
                })
            end
        end

        -- Scaffold width (place blocks to sides)
        if Flags.ScaffoldWidth and Flags.ScaffoldWidth > 1 then
            local right = myHRP.CFrame.RightVector
            for i = 1, Flags.ScaffoldWidth - 1 do
                local offset = right * i * 4
                local pos = myHRP.Position + Vector3.new(0, -3.5, 0) + offset
                api.fireRemote("Block", "PlaceBlock", {
                    blockType = blockType,
                    position = pos,
                    normal = Vector3.new(0, 1, 0),
                })
            end
        end

        -- Tower mode
        if Flags.ScaffoldTower and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            local pos = myHRP.Position + Vector3.new(0, -2, 0)
            api.fireRemote("Block", "PlaceBlock", {
                blockType = blockType,
                position = pos,
                normal = Vector3.new(0, 1, 0),
            })
            -- Jump up
            myHum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)

    -- ═══ Bed Protector ═══
    UI:Toggle("Bed Protect", false, function(v) Flags.BedProtect = v end, "World", "Auto place blocks around bed")
    UI:Slider("BP Layers", 1, 3, 2, function(v) Flags.BPLayers = v end, "World")

    task.spawn(function()
        while task.wait(2) do
            if not Flags.BedProtect or not api.isAlive() then continue end

            -- Find my bed
            local myTeam = lplr.Team
            if not myTeam then continue end

            local bed = nil
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj.Name:find("bed") and obj:IsA("Model") then
                    local teamPart = obj:FindFirstChild("Bed_" .. myTeam.Name)
                    if teamPart or obj.Name:lower():find(myTeam.Name:lower()) then
                        bed = obj
                        break
                    end
                end
            end

            if not bed then continue end

            local primary = bed.PrimaryPart or bed:FindFirstChildWhichIsA("BasePart")
            if not primary then continue end

            -- Find block type
            local blockType = nil
            local blockNames = {"obsidian", "end_stone", "stone", "wool_white"}
            for _, name in pairs(blockNames) do
                if api.hasItem(name) then
                    blockType = name
                    break
                end
            end
            if not blockType then continue end

            -- Place blocks around bed
            local pos = primary.Position
            local offsets = {
                Vector3.new(4, 0, 0), Vector3.new(-4, 0, 0),
                Vector3.new(0, 0, 4), Vector3.new(0, 0, -4),
                Vector3.new(4, 4, 0), Vector3.new(-4, 4, 0),
                Vector3.new(0, 4, 4), Vector3.new(0, 4, -4),
                Vector3.new(0, -4, 0),
                Vector3.new(4, 0, 4), Vector3.new(-4, 0, -4),
                Vector3.new(4, 0, -4), Vector3.new(-4, 0, 4),
            }

            for _, offset in pairs(offsets) do
                local placePos = pos + offset
                api.fireRemote("Block", "PlaceBlock", {
                    blockType = blockType,
                    position = placePos,
                    normal = Vector3.new(0, 1, 0),
                })
                task.wait(0.1)
            end
        end
    end)

    -- ═══ Auto Collect ═══
    UI:Toggle("Auto Collect", false, function(v) Flags.AutoCollect = v end, "World", "Auto collect resources")
    UI:Slider("Collect Range", 5, 50, 15, function(v) Flags.CollectRange = v end, "World")
    UI:Toggle("Collect Iron", true, function(v) Flags.CollectIron = v end, "World")
    UI:Toggle("Collect Gold", true, function(v) Flags.CollectGold = v end, "World")
    UI:Toggle("Collect Diamond", true, function(v) Flags.CollectDiamond = v end, "World")
    UI:Toggle("Collect Emerald", true, function(v) Flags.CollectEmerald = v end, "World")

    task.spawn(function()
        while task.wait(0.5) do
            if not Flags.AutoCollect or not api.isAlive() then continue end

            local myHRP = lplr.Character:FindFirstChild("HumanoidRootPart")
            if not myHRP then continue end

            -- Find resource pickups
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj:GetAttribute("PickupType") then
                    local pickupType = obj:GetAttribute("PickupType")
                    local shouldCollect = false

                    if pickupType == "iron" and Flags.CollectIron then shouldCollect = true
                    elseif pickupType == "gold" and Flags.CollectGold then shouldCollect = true
                    elseif pickupType == "diamond" and Flags.CollectDiamond then shouldCollect = true
                    elseif pickupType == "emerald" and Flags.CollectEmerald then shouldCollect = true
                    end

                    if shouldCollect then
                        local dist = (myHRP.Position - obj.Position).Magnitude
                        if dist <= (Flags.CollectRange or 15) then
                            -- Teleport to collect
                            myHRP.CFrame = obj.CFrame + Vector3.new(0, 2, 0)
                            task.wait(0.1)
                        end
                    end
                end
            end
        end
    end)

    -- ═══ Auto Break Bed ═══
    UI:Toggle("Auto Break Bed", false, function(v) Flags.AutoBreakBed = v end, "World", "Auto break enemy beds")

    task.spawn(function()
        while task.wait(1) do
            if not Flags.AutoBreakBed or not api.isAlive() then continue end

            local myHRP = lplr.Character:FindFirstChild("HumanoidRootPart")
            if not myHRP then continue end

            -- Find enemy beds
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj.Name:find("bed") and obj:IsA("Model") then
                    local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    if primary then
                        -- Check it's not our bed
                        local isOurBed = false
                        if lplr.Team then
                            isOurBed = obj.Name:lower():find(lplr.Team.Name:lower()) ~= nil
                        end

                        if not isOurBed then
                            local dist = (myHRP.Position - primary.Position).Magnitude
                            if dist <= 20 then
                                -- Equip pickaxe and break
                                pcall(function()
                                    bw.PickaxeController:equipPickaxe()
                                end)
                                task.wait(0.2)

                                -- Fire break remote
                                api.fireRemote("Block", "BreakBlock", {
                                    blockRef = primary
                                })
                            end
                        end
                    end
                end
            end
        end
    end)

    -- ═══ Nuker ═══
    UI:Toggle("Nuker", false, function(v) Flags.Nuker = v end, "World", "Auto break blocks around you")
    UI:Slider("Nuker Range", 3, 10, 5, function(v) Flags.NukerRange = v end, "World")

    task.spawn(function()
        while task.wait(0.3) do
            if not Flags.Nuker or not api.isAlive() then continue end

            local myHRP = lplr.Character:FindFirstChild("HumanoidRootPart")
            if not myHRP then continue end

            -- Find breakable blocks
            for _, obj in pairs(workspace:GetChildren()) do
                if obj:IsA("BasePart") and not obj.Anchored == false then
                    local dist = (myHRP.Position - obj.Position).Magnitude
                    if dist <= (Flags.NukerRange or 5) then
                        api.fireRemote("Block", "BreakBlock", {
                            blockRef = obj
                        })
                    end
                end
            end
        end
    end)

    -- ═══ Chest Steal ═══
    UI:Toggle("Chest Steal", false, function(v) Flags.ChestSteal = v end, "World", "Auto take items from chests")

    -- ═══ Safe Walk ═══
    UI:Toggle("Safe Walk", false, function(v) Flags.SafeWalk = v end, "World", "Prevent falling off edges")

    -- ═══ Xray ═══
    UI:Toggle("Xray", false, function(v) Flags.Xray = v end, "World", "See ores through walls")
end

end

-- ESP
local function load_esp(bw, flags, ui, api)
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
        if not (BW.Flags.ESP_TeamCheck and e.Player.Team==BW.LocalPlayer.Team) then
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
        end
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

end

-- MOVE
local function load_move(bw, flags, ui, api)
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

end

-- SHOP
local function load_shop(bw, flags, ui, api)
--!nocheck
-- ═══════════════════════════════════════════════════════════════
-- BEDWARS SHOP MODULE (CatVape-style APIs)
-- Auto Buy, Shop Tier Bypass
-- ═══════════════════════════════════════════════════════════════

return function(BW, Flags, UI, api)
    local Players = game:GetService("Players")
    local lplr = Players.LocalPlayer
    local bw = api.bw

    -- ═══ Shop Item Config ═══
    -- BedWars shop items organized by category
    local SHOP_CONFIG = {
        Blocks = {
            {item = "wool_white", cost = 4, resource = "iron", priority = 1},
            {item = "wool_light_gray", cost = 4, resource = "iron", priority = 2},
            {item = "stone", cost = 12, resource = "iron", priority = 3},
            {item = "obsidian", cost = 12, resource = "emerald", priority = 4},
            {item = "end_stone", cost = 8, resource = "diamond", priority = 5},
        },
        Swords = {
            {item = "wood_sword", cost = 10, resource = "iron", priority = 1},
            {item = "stone_sword", cost = 20, resource = "iron", priority = 2},
            {item = "iron_sword", cost = 75, resource = "iron", priority = 3},
            {item = "diamond_sword", cost = 4, resource = "emerald", priority = 4},
            {item = "emerald_sword", cost = 12, resource = "emerald", priority = 5},
        },
        Armor = {
            {item = "chainmail_chestplate", cost = 40, resource = "iron", priority = 1},
            {item = "iron_chestplate", cost = 80, resource = "iron", priority = 2},
            {item = "diamond_chestplate", cost = 8, resource = "diamond", priority = 3},
            {item = "emerald_chestplate", cost = 24, resource = "emerald", priority = 4},
        },
        Tools = {
            {item = "wood_axe", cost = 10, resource = "iron", priority = 1},
            {item = "iron_pickaxe", cost = 60, resource = "iron", priority = 2},
            {item = "diamond_pickaxe", cost = 6, resource = "diamond", priority = 3},
            {item = "bow", cost = 30, resource = "iron", priority = 4},
            {item = "crossbow", cost = 3, resource = "diamond", priority = 5},
        },
        Projectiles = {
            {item = "fireball", cost = 7, resource = "iron", priority = 1},
            {item = "snowball", cost = 5, resource = "iron", priority = 2},
            {item = "telepearl", cost = 3, resource = "diamond", priority = 3},
            {item = "rocket", cost = 8, resource = "iron", priority = 4},
        },
        Utilities = {
            {item = "telepearl", cost = 3, resource = "diamond", priority = 1},
            {item = "speed_v", cost = 3, resource = "emerald", priority = 2},
            {item = "heal_splash", cost = 5, resource = "emerald", priority = 3},
            {item = "grappling_hook", cost = 5, resource = "diamond", priority = 4},
        },
        Upgrades = {
            {item = "sharpness", cost = 20, resource = "emerald", priority = 1},
            {item = "protection", cost = 20, resource = "emerald", priority = 2},
        },
    }

    -- ═══ Auto Buy ═══
    UI:Tab("Shop")
    UI:Toggle("Auto Buy Blocks", false, function(v) Flags.AutoBuyBlocks = v end, "Shop", "Auto buy blocks")
    UI:Toggle("Auto Buy Sword", false, function(v) Flags.AutoBuySword = v end, "Shop", "Auto buy best sword")
    UI:Toggle("Auto Buy Armor", false, function(v) Flags.AutoBuyArmor = v end, "Shop", "Auto buy best armor")
    UI:Toggle("Auto Buy Tools", false, function(v) Flags.AutoBuyTools = v end, "Shop", "Auto buy best tools")
    UI:Toggle("Auto Buy Projectiles", false, function(v) Flags.AutoBuyProj = v end, "Shop", "Auto buy projectiles")
    UI:Slider("Buy Delay", 100, 2000, 500, function(v) Flags.BuyDelay = v end, "Shop")

    -- ═══ Shop Tier Bypass ═══
    UI:Toggle("Tier Bypass", false, function(v) Flags.ShopTierBypass = v end, "Shop", "Access higher shop tiers")

    -- ═══ Buy Function ═══
    local function buyItem(itemConfig)
        if not itemConfig then return false end

        -- Check if we have enough resources
        local resources = api.getBedwarsState().resources or {}
        local currentAmount = resources[itemConfig.resource] or 0

        if currentAmount < itemConfig.cost then
            return false
        end

        -- Try using the game controller first
        local shop = bw.ShopController
        if shop and shop.purchaseItem then
            local success = pcall(function()
                shop:purchaseItem(itemConfig.item, "main")
            end)
            if success then return true end
        end

        -- Fallback: use remote event
        api.fireRemote("Shop", "PurchaseItem", {
            shopItem = {
                itemType = itemConfig.item,
                shopId = "main",
            }
        })

        return true
    end

    -- ═══ Auto Buy Engine ═══
    task.spawn(function()
        while task.wait((Flags.BuyDelay or 500) / 1000) do
            if not api.isAlive() then continue end

            local resources = api.getBedwarsState().resources or {}

            -- Buy blocks
            if Flags.AutoBuyBlocks then
                local currentBlocks = api.getBlockCount()
                if currentBlocks < 30 then
                    for _, item in pairs(SHOP_CONFIG.Blocks) do
                        if (resources[item.resource] or 0) >= item.cost then
                            buyItem(item)
                            task.wait(0.2)
                            break
                        end
                    end
                end
            end

            -- Buy sword
            if Flags.AutoBuySword then
                local hasSword = api.hasItem("diamond_sword") or api.hasItem("emerald_sword")
                if not hasSword then
                    -- Try buying best available sword
                    for i = #SHOP_CONFIG.Swords, 1, -1 do
                        local item = SHOP_CONFIG.Swords[i]
                        if (resources[item.resource] or 0) >= item.cost then
                            buyItem(item)
                            break
                        end
                    end
                end
            end

            -- Buy armor
            if Flags.AutoBuyArmor then
                local hasArmor = api.hasItem("diamond_chestplate") or api.hasItem("emerald_chestplate")
                if not hasArmor then
                    for i = #SHOP_CONFIG.Armor, 1, -1 do
                        local item = SHOP_CONFIG.Armor[i]
                        if (resources[item.resource] or 0) >= item.cost then
                            buyItem(item)
                            break
                        end
                    end
                end
            end

            -- Buy tools
            if Flags.AutoBuyTools then
                local hasTool = api.hasItem("diamond_pickaxe")
                if not hasTool then
                    for i = #SHOP_CONFIG.Tools, 1, -1 do
                        local item = SHOP_CONFIG.Tools[i]
                        if (resources[item.resource] or 0) >= item.cost then
                            buyItem(item)
                            break
                        end
                    end
                end
            end

            -- Buy projectiles
            if Flags.AutoBuyProj then
                for _, item in pairs(SHOP_CONFIG.Projectiles) do
                    if (resources[item.resource] or 0) >= item.cost then
                        buyItem(item)
                        task.wait(0.1)
                    end
                end
            end
        end
    end)

    -- ═══ Shop Tier Bypass ═══
    if Flags.ShopTierBypass then
        -- This hooks into the shop UI to show all tiers
        pcall(function()
            bw.Client:GetNamespace("Shop"):Get("RequestTiers"):SendToServer({
                shopId = "all"
            })
        end)
    end
end

end

-- UTIL
local function load_util(bw, flags, ui, api)
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

end

-- LEGIT
local function load_legit(bw, flags, ui, api)
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

end

-- AUTOLOAD
local function load_autoload(bw, flags, ui, api)
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
                            if not (BW.Flags.SA_WallCheck and not BW.hasLineOfSight(my.Position,e.HRP.Position)) then
                                bestDist=dist; best=e
                            end
                        end
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

end

-- EVENTS
local function load_events(bw, flags, ui, api)
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

end

-- INITIALIZATION
(function()
    print('==========================================')
    print('  BED WARS ULTIMATE v5.1 (CatVape-style)')
    print('==========================================')

    local bw = createCore()
    local flags = bw.Flags
    local api = createAPI(bw)
    local Library = createUI(bw, flags, api)
    local ui = Library:New({Title='BedWars', Sub='v5.1'})

    local moduleList = {'combat', 'world', 'esp', 'move', 'shop', 'util', 'legit', 'autoload', 'events'}
    for _, name in pairs(moduleList) do
        local success, err = pcall(function()
            if name == 'combat' then load_combat(bw, flags, ui, api)
            elseif name == 'world' then load_world(bw, flags, ui, api)
            elseif name == 'esp' then load_esp(bw, flags, ui, api)
            elseif name == 'move' then load_move(bw, flags, ui, api)
            elseif name == 'shop' then load_shop(bw, flags, ui, api)
            elseif name == 'util' then load_util(bw, flags, ui, api)
            elseif name == 'legit' then load_legit(bw, flags, ui, api)
            elseif name == 'autoload' then load_autoload(bw, flags, ui, api)
            elseif name == 'events' then load_events(bw, flags, ui, api)
            end
        end)
        if success then print('[OK] ' .. name)
        else warn('[FAIL] ' .. name .. ': ' .. tostring(err)) end
    end

    print('==========================================')
    print('  All modules loaded!')
    if bw.isMobile then print('  Mobile: Tap X to toggle UI')
    else print('  PC: Press RightAlt to toggle UI') end
    print('==========================================')
end)()