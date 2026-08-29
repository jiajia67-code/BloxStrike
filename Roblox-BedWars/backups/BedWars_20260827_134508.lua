--!nocheck
-- BED WARS ULTIMATE v5.1 (CatVape-style)
-- Built: 2026-08-27 13:45:08
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

function Perf:Throttle(name, interval, func)
    local now = tick()
    if not self.CacheTime["throttle_" .. name] or (now - (self.CacheTime["throttle_" .. name] or 0)) > interval then
        self.CacheTime["throttle_" .. name] = now
        func()
    end
end

function Perf:GetMemory()
    return math.floor(game:GetService("Stats").LuaHeapExtensionUsage or 0)
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
-- BEDWARS API MODULE v5.1 — Full Real API (1696 remotes)
-- Based on actual game dump from 2026-08-27
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local lplr = Players.LocalPlayer

local api = {}

-- ═══ 1. Knit Framework ═══
local KnitInit, Knit = false, nil
pcall(function()
    KnitInit, Knit = pcall(function()
        return debug.getupvalue(require(lplr.PlayerScripts.TS.knit).setup, 9)
    end)
end)
if KnitInit and Knit then
    pcall(function() repeat task.wait() until debug.getupvalue(Knit.Start, 1) end)
    api.Knit = Knit
end

-- ═══ 2. Client Remotes ═══
local Client = nil
pcall(function()
    Client = require(ReplicatedStorage.TS.remotes).default.Client
end)
api.Client = Client

-- ═══ 3. _NetManaged (1696 remotes!) ═══
api.NetManaged = nil
pcall(function()
    api.NetManaged = ReplicatedStorage
        :WaitForChild("rbxts_include")
        :WaitForChild("node_modules")
        :WaitForChild("@rbxts")
        :WaitForChild("net")
        :WaitForChild("out")
        :WaitForChild("_NetManaged")
end)

-- ═══ 4. Store ═══
api.Store = nil
pcall(function()
    api.Store = require(lplr.PlayerScripts.TS.ui.store).ClientStore
end)

-- ═══ 5. bedwars Table ═══
api.bw = {}
if Knit then
    api.bw = setmetatable({
        Client = Client,
        Store = api.Store,
        NetManaged = api.NetManaged,
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
end

-- ═══ 6. Dump ═══
if Knit then
    local count = 0
    for _ in pairs(Knit.Controllers) do count = count + 1 end
    print("[API] Controllers: " .. count)
end
if api.NetManaged then
    print("[API] _NetManaged: " .. #api.NetManaged:GetChildren())
end

-- ═══════════════════════════════════════════════════════════════
-- PLAYER STATE
-- ═══════════════════════════════════════════════════════════════

function api.isAlive()
    local c = lplr.Character
    return c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChildOfClass("Humanoid")
end

function api.getHealth()
    local h = lplr.Character and lplr.Character:FindFirstChildOfClass("Humanoid")
    return h and h.Health or 0
end

function api.getMaxHealth()
    local h = lplr.Character and lplr.Character:FindFirstChildOfClass("Humanoid")
    return h and h.MaxHealth or 100
end

function api.getHRP()
    local c = lplr.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

function api.getHumanoid()
    local c = lplr.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

function api.getTeam()
    return lplr:GetAttribute("Team") or ""
end

function api.getKit()
    return lplr:GetAttribute("PlayingAsKits") or ""
end

-- ═══════════════════════════════════════════════════════════════
-- ENEMY DETECTION
-- ═══════════════════════════════════════════════════════════════

function api.getEnemies()
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lplr and p.Character then
            local h = p.Character:FindFirstChild("HumanoidRootPart")
            local hu = p.Character:FindFirstChildOfClass("Humanoid")
            if h and hu and hu.Health > 0 then
                table.insert(t, {Player = p, HRP = h, Char = p.Character, Hum = hu})
            end
        end
    end
    return t
end

function api.getNearestEnemy(maxDist)
    local myHrp = api.getHRP()
    if not myHrp then return nil, math.huge end
    local best, bestDist = nil, maxDist or math.huge
    for _, e in pairs(api.getEnemies()) do
        local d = (myHrp.Position - e.HRP.Position).Magnitude
        if d < bestDist then best = e; bestDist = d end
    end
    return best, bestDist
end

function api.isOnScreen(position)
    local cam = workspace.CurrentCamera
    local pos, vis = cam:WorldToViewportPoint(position)
    return vis, Vector2.new(pos.X, pos.Y)
end

-- ═══════════════════════════════════════════════════════════════
-- BED SYSTEM (CollectionService tag: "bed")
-- ═══════════════════════════════════════════════════════════════

function api.getBeds()
    return CollectionService:GetTagged("bed")
end

function api.getEnemyBeds()
    local myTeam = api.getTeam()
    local beds = {}
    for _, bed in pairs(CollectionService:GetTagged("bed")) do
        local id = bed:GetAttribute("id") or ""
        local bedTeam = string.split(id, "_")[1]
        if bedTeam ~= myTeam and not bed:GetAttribute("NoBreak") then
            table.insert(beds, bed)
        end
    end
    return beds
end

function api.getTeamBed()
    local myTeam = api.getTeam()
    for _, bed in pairs(CollectionService:GetTagged("bed")) do
        local id = bed:GetAttribute("id") or ""
        if id == myTeam .. "_bed" then
            return bed
        end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════
-- ITEM DROP SYSTEM (CollectionService tag: "ItemDrop")
-- ═══════════════════════════════════════════════════════════════

function api.getItemDrops()
    return CollectionService:GetTagged("ItemDrop")
end

function api.getNearestItemDrop(maxDist, itemType)
    local myHrp = api.getHRP()
    if not myHrp then return nil, math.huge end
    local best, bestDist = nil, maxDist or math.huge
    for _, drop in pairs(CollectionService:GetTagged("ItemDrop")) do
        local dropType = drop:GetAttribute("itemType") or drop.Name
        if not itemType or dropType == itemType then
            local d = (myHrp.Position - drop.Position).Magnitude
            if d < bestDist then best = drop; bestDist = d end
        end
    end
    return best, bestDist
end

-- ═══════════════════════════════════════════════════════════════
-- INVENTORY
-- ═══════════════════════════════════════════════════════════════

function api.hasItem(itemName)
    local c = lplr.Character
    if c then
        for _, tool in pairs(c:GetChildren()) do
            if tool:IsA("Tool") and tool.Name == itemName then return true end
        end
    end
    local bp = lplr:FindFirstChild("Backpack")
    if bp then
        for _, tool in pairs(bp:GetChildren()) do
            if tool:IsA("Tool") and tool.Name == itemName then return true end
        end
    end
    return false
end

function api.getEquippedTool()
    local c = lplr.Character
    return c and c:FindFirstChildWhichIsA("Tool")
end

function api.getBlockCount()
    local count = 0
    local c = lplr.Character
    if c then
        for _, tool in pairs(c:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:find("wool") or tool.Name:find("stone") or tool.Name:find("obsidian") or tool.Name:find("end_stone")) then
                count = count + 1
            end
        end
    end
    return count
end

function api.getAllTools()
    local tools = {}
    local c = lplr.Character
    if c then
        for _, tool in pairs(c:GetChildren()) do
            if tool:IsA("Tool") then table.insert(tools, tool) end
        end
    end
    local bp = lplr:FindFirstChild("Backpack")
    if bp then
        for _, tool in pairs(bp:GetChildren()) do
            if tool:IsA("Tool") then table.insert(tools, tool) end
        end
    end
    return tools
end

-- ═══════════════════════════════════════════════════════════════
-- STORE STATE
-- ═══════════════════════════════════════════════════════════════

function api.getResources()
    local res = {iron = 0, gold = 0, diamond = 0, emerald = 0}
    if api.Store then
        pcall(function()
            local state = api.Store:getState()
            if state.Bedwars then
                res.iron = state.Bedwars.Iron or state.Bedwars.iron or 0
                res.gold = state.Bedwars.Gold or state.Bedwars.gold or 0
                res.diamond = state.Bedwars.Diamond or state.Bedwars.diamond or 0
                res.emerald = state.Bedwars.Emerald or state.Bedwars.emerald or 0
            end
        end)
    end
    return res
end

function api.getBedwarsState()
    if api.Store then
        local s, state = pcall(function() return api.Store:getState() end)
        if s and state then return state.Bedwars or {} end
    end
    return {}
end

function api.getKills()
    local state = api.getBedwarsState()
    return state.kills or 0
end

function api.getBedBreaks()
    local state = api.getBedwarsState()
    return state.bedBreaks or 0
end

-- ═══════════════════════════════════════════════════════════════
-- REMOTE CALLS (Real BedWars Remotes)
-- ═══════════════════════════════════════════════════════════════

function api.fireRemote(namespace, remote, params)
    if Client then
        pcall(function()
            Client:GetNamespace(namespace):Get(remote):SendToServer(params or {})
        end)
    end
end

function api.callRemote(remote, params)
    if Client then
        local s, r = pcall(function()
            return Client:Get(remote):CallServer(params or {})
        end)
        return s and r or nil
    end
    return nil
end

function api.fireNetManaged(remoteName, ...)
    if api.NetManaged then
        pcall(function()
            api.NetManaged[remoteName]:FireServer(...)
        end)
    end
end

function api.invokeNetManaged(remoteName, ...)
    if api.NetManaged then
        local s, r = pcall(function()
            return api.NetManaged[remoteName]:InvokeServer(...)
        end)
        return s and r or nil
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════
-- CONTROLLER SHORTCUTS
-- ═══════════════════════════════════════════════════════════════

function api.startSprint()
    pcall(function() api.bw.SprintController:startSprinting() end)
end
function api.stopSprint()
    pcall(function() api.bw.SprintController:stopSprinting() end)
end

function api.placeBlock(blockType, position, normal)
    pcall(function()
        api.bw.BlockController:placeBlock(blockType, position, normal or Vector3.new(0, 1, 0))
    end)
end

function api.getBlockAt(position)
    local s, r = pcall(function() return api.bw.BlockController:getBlockAt(position) end)
    return s and r or nil
end

function api.buyItem(itemType, shopId)
    pcall(function()
        api.bw.ShopController:purchaseItem(itemType, shopId or "main")
    end)
end

function api.equipItem(slot)
    pcall(function()
        api.bw.BedwarsInventoryController:equipItemInHotbar(slot)
    end)
end

function api.equipPickaxe()
    pcall(function()
        api.bw.PickaxeController:equipPickaxe()
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- REAL REMOTE SHORTCUTS (from dump)
-- ═══════════════════════════════════════════════════════════════

-- Sprint
function api.sprintStart()
    api.fireNetManaged("SprintStart")
end
function api.sprintStop()
    api.fireNetManaged("SprintStop")
end

-- Shop
function api.purchaseItem(params)
    return api.invokeNetManaged("BedwarsPurchaseItem", params)
end
function api.purchaseTeamUpgrade(params)
    return api.invokeNetManaged("BedwarsPurchaseTeamUpgrade", params)
end
function api.shopCategoriesUpdate()
    api.fireNetManaged("BedwarsShopCategoriesUpdate")
end

-- Kit
function api.selectKit(kitName)
    return api.invokeNetManaged("SelectKit", kitName)
end
function api.swapKit(kitName)
    return api.invokeNetManaged("SwapKit", kitName)
end
function api.activateKit(kitName)
    return api.invokeNetManaged("BedwarsActivateKit", kitName)
end

-- Inventory
function api.setInvItem(params)
    return api.invokeNetManaged("SetInvItem", params)
end
function api.setArmorInvItem(params)
    return api.invokeNetManaged("SetArmorInvItem", params)
end
function api.setBackpackInvItem(params)
    return api.invokeNetManaged("SetBackpackInvItem", params)
end
function api.dropItem(params)
    return api.invokeNetManaged("DropItem", params)
end
function api.consumeItem(params)
    return api.invokeNetManaged("ConsumeItem", params)
end

-- Block
function api.fortifyBlock(params)
    api.fireNetManaged("FortifyBlock", params)
end
function api.getWool(params)
    return api.invokeNetManaged("GetWool", params)
end

-- Combat
function api.swordHit(params)
    api.fireNetManaged("SwordHit", params)
end
function api.projectileFire(params)
    return api.invokeNetManaged("ProjectileFire", params)
end
function api.useAbility(params)
    api.fireNetManaged("UseAbility", params)
end

-- Pickup
function api.pickupItemDrop(params)
    return api.invokeNetManaged("PickupItemDrop", params)
end

-- Milestone
function api.claimMilestone(rewardId)
    return api.invokeNetManaged("ClaimMilestoneReward", rewardId)
end

-- Kit-specific (from dump)
function api.upgradeAdetunde(upgradeType)
    return api.invokeNetManaged("UpgradeFrostyHammer", upgradeType)
end
function api.useEmberSaber(params)
    api.fireNetManaged("HellBladeRelease", params)
end
function api.useSkyScythe()
    api.fireNetManaged("SkyScytheSpin")
end
function api.useVoidHunterMark(params)
    api.fireNetManaged("VoidHunter_MarkAbilityRequest", params)
end
function api.useVoidHunterDetonate(params)
    api.fireNetManaged("VoidHunter_TargetDetonated", params)
end

-- Bed
function api.bedBreak(params)
    api.fireNetManaged("BedwarsBedBreak", params)
end

-- Team
function api.setTeamUpgrade(params)
    api.fireNetManaged("BedwarsSetTeamUpgradeTier", params)
end

-- Device
function api.sendUserInputType(deviceType)
    api.fireNetManaged("SendUserInputType", {userInputType = deviceType})
end

-- Harvest
function api.harvestCrop(params)
    return api.invokeNetManaged("BedwarsHarvestCrop", params)
end

print("[API] Loaded (Controllers=" .. tostring(Knit ~= nil)
    .. ", Net=" .. tostring(api.NetManaged ~= nil)
    .. ", Store=" .. tostring(api.Store ~= nil) .. ")")
return api

end

-- UI
local function createUI(bw, flags, api)
--!nocheck
-- ══════════════════════════════════════════════════════════════
-- UI LIBRARY MODULE (CatVape-style Dark Theme)
-- ══════════════════════════════════════════════════════════════

BW = bw

local Library = {}
Library.__index = Library

-- ═══ Color Palette ═══
local Colors = {
    Background = Color3.fromRGB(18, 18, 24),
    Sidebar = Color3.fromRGB(22, 22, 30),
    Content = Color3.fromRGB(26, 26, 36),
    Card = Color3.fromRGB(32, 32, 44),
    CardHover = Color3.fromRGB(38, 38, 52),
    Accent = Color3.fromRGB(90, 130, 255),
    AccentDark = Color3.fromRGB(60, 100, 220),
    Green = Color3.fromRGB(80, 200, 120),
    Red = Color3.fromRGB(240, 70, 70),
    Yellow = Color3.fromRGB(255, 200, 50),
    Text = Color3.fromRGB(220, 220, 230),
    TextDim = Color3.fromRGB(140, 140, 160),
    TextMuted = Color3.fromRGB(80, 80, 100),
    Border = Color3.fromRGB(40, 40, 55),
    ToggleOn = Color3.fromRGB(80, 200, 120),
    ToggleOff = Color3.fromRGB(60, 60, 75),
    SliderFill = Color3.fromRGB(90, 130, 255),
    SliderBG = Color3.fromRGB(40, 40, 55),
}

local function ifelse(cond, a, b)
    if cond then return a else return b end
end

local function addCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = parent
    return c
end

local function addStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Colors.Border
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end

-- ═══ Create Library Instance ═══
function Library:New(config)
    local self = setmetatable({}, Library)
    self.Flags = BW.Flags
    self.Config = config or {Title = "BedWars", Sub = "v5.1"}
    self.IsMobile = BW.isMobile or BW.isTablet

    -- Remove old UI
    if game.CoreGui:FindFirstChild("BW_UI") then
        game.CoreGui:FindFirstChild("BW_UI"):Destroy()
    end

    -- ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name = "BW_UI"
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.Parent = game.CoreGui
    self.SG = sg

    -- Main Frame
    local main = Instance.new("Frame")
    if BW.isMobile then
        main.Size = UDim2.new(0.92, 0, 0.65, 0)
        main.Position = UDim2.new(0.04, 0, 0.175, 0)
    else
        main.Size = UDim2.new(0, 580, 0, 420)
        main.Position = UDim2.new(0.5, -290, 0.5, -210)
    end
    main.BackgroundColor3 = Colors.Background
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = not BW.isMobile
    main.Parent = sg
    addCorner(main, 12)
    self.Main = main

    -- Drop Shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
    shadow.Size = UDim2.new(1, 50, 1, 50)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6015897843"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.65
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.ZIndex = -1
    shadow.Parent = main

    -- ═══ Title Bar ═══
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 44)
    titleBar.BackgroundColor3 = Colors.Sidebar
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main
    addCorner(titleBar, 12)

    -- Title gradient
    local titleGrad = Instance.new("Frame")
    titleGrad.Name = "GradFix"
    titleGrad.Size = UDim2.new(1, 0, 0, 12)
    titleGrad.Position = UDim2.new(0, 0, 1, -12)
    titleGrad.BackgroundColor3 = Colors.Sidebar
    titleGrad.BorderSizePixel = 0
    titleGrad.Parent = titleBar

    -- Title icon
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 30, 0, 44)
    icon.Position = UDim2.new(0, 12, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text = "⚔️"
    icon.TextSize = 18
    icon.Font = Enum.Font.GothamBold
    icon.TextColor3 = Colors.Accent
    icon.Parent = titleBar

    -- Title text
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.5, 0, 1, 0)
    title.Position = UDim2.new(0, 40, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = self.Config.Title .. " | " .. self.Config.Sub
    title.TextColor3 = Colors.Text
    title.TextSize = 15
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    -- Keybind hint
    local hint = Instance.new("TextLabel")
    hint.Size = UDim2.new(0, 120, 1, 0)
    hint.Position = UDim2.new(1, -170, 0, 0)
    hint.BackgroundTransparency = 1
    hint.Text = ifelse(BW.isMobile, "📱 Tap X", "RightAlt to toggle")
    hint.TextColor3 = Colors.TextMuted
    hint.TextSize = 11
    hint.Font = Enum.Font.Gotham
    hint.TextXAlignment = Enum.TextXAlignment.Right
    hint.Parent = titleBar

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -38, 0, 8)
    closeBtn.BackgroundColor3 = Colors.Red
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.TextSize = 12
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = titleBar
    addCorner(closeBtn, 6)

    -- ═══ Sidebar ═══
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    if BW.isMobile then
        sidebar.Size = UDim2.new(1, -16, 0, 36)
        sidebar.Position = UDim2.new(0, 8, 0, 50)
    else
        sidebar.Size = UDim2.new(0, 120, 1, -58)
        sidebar.Position = UDim2.new(0, 6, 0, 50)
    end
    sidebar.BackgroundColor3 = Colors.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.Parent = main
    addCorner(sidebar, 8)

    if BW.isMobile then
        local layout = Instance.new("UIListLayout", sidebar)
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.Padding = UDim.new(0, 4)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    else
        Instance.new("UIListLayout", sidebar).Padding = UDim.new(0, 3)
    end

    -- ═══ Content Area ═══
    local content = Instance.new("Frame")
    content.Name = "Content"
    if BW.isMobile then
        content.Size = UDim2.new(1, -16, 1, -100)
        content.Position = UDim2.new(0, 8, 0, 92)
    else
        content.Size = UDim2.new(1, -144, 1, -64)
        content.Position = UDim2.new(0, 132, 0, 52)
    end
    content.BackgroundColor3 = Colors.Content
    content.BorderSizePixel = 0
    content.ClipsDescendants = true
    content.Parent = main
    addCorner(content, 8)

    self.Content = content
    self.Sidebar = sidebar
    self.Open = true
    self.Pages = {}
    self.CurrentPage = nil

    -- ═══ Toggle Visibility ═══
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

-- ═══ Tab System ═══
function Library:Tab(name, icon)
    local page = {}
    local tabName = (icon or "") .. " " .. name

    -- Tab Button
    local btn = Instance.new("TextButton")
    if BW.isMobile then
        btn.Size = UDim2.new(0, 64, 1, -4)
    else
        btn.Size = UDim2.new(1, -8, 0, 30)
    end
    btn.BackgroundColor3 = Colors.Card
    btn.BorderSizePixel = 0
    btn.Text = "  " .. tabName
    btn.TextColor3 = Colors.TextDim
    btn.TextSize = ifelse(BW.isMobile, 10, 12)
    btn.Font = Enum.Font.GothamMedium
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = self.Sidebar
    addCorner(btn, 6)

    -- Scroll Frame
    local pf = Instance.new("ScrollingFrame")
    pf.Size = UDim2.new(1, -12, 1, -12)
    pf.Position = UDim2.new(0, 6, 0, 6)
    pf.BackgroundTransparency = 1
    pf.ScrollBarThickness = 3
    pf.ScrollBarImageColor3 = Colors.Accent
    pf.CanvasSize = UDim2.new(0, 0, 0, 0)
    pf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    pf.Visible = false
    pf.BorderSizePixel = 0
    pf.Parent = self.Content
    local listLayout = Instance.new("UIListLayout", pf)
    listLayout.Padding = UDim.new(0, 4)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    Instance.new("UIPadding", pf).PaddingLeft = UDim.new(0, 2)

    -- Auto-select first tab
    if not self.CurrentPage then
        self.CurrentPage = name
        pf.Visible = true
        btn.BackgroundColor3 = Colors.Accent
        btn.TextColor3 = Color3.new(1, 1, 1)
    end

    -- Tab click handler
    btn.MouseButton1Click:Connect(function()
        for _, c in pairs(self.Content:GetChildren()) do
            if c:IsA("ScrollingFrame") then c.Visible = false end
        end
        for _, c in pairs(self.Sidebar:GetChildren()) do
            if c:IsA("TextButton") then
                c.BackgroundColor3 = Colors.Card
                c.TextColor3 = Colors.TextDim
            end
        end
        pf.Visible = true
        btn.BackgroundColor3 = Colors.Accent
        btn.TextColor3 = Color3.new(1, 1, 1)
        self.CurrentPage = name
    end)

    -- ═══ Toggle Component ═══
    function page:Toggle(name, default, callback, category, tooltip)
        -- Support both formats: Toggle({Name=...}) or Toggle("name", default, func)
        local cfg
        if type(name) == 'table' then
            cfg = name
        else
            cfg = {Name = name or 'Toggle', Flag = (name or 'Toggle'):gsub('%s+', ''), Default = default, Callback = callback}
        end
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 36)
        f.BackgroundColor3 = Colors.Card
        f.BorderSizePixel = 0
        f.LayoutOrder = #pf:GetChildren()
        f.Parent = pf
        addCorner(f, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.7, 0, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = cfg.Name
        lbl.TextColor3 = Colors.Text
        lbl.TextSize = 12
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = f

        -- Toggle Track
        local track = Instance.new("TextButton")
        track.Size = UDim2.new(0, 36, 0, 20)
        track.Position = UDim2.new(1, -46, 0.5, -10)
        track.BackgroundColor3 = ifelse(cfg.Default, Colors.ToggleOn, Colors.ToggleOff)
        track.BorderSizePixel = 0
        track.Text = ""
        track.Parent = f
        addCorner(track, 10)

        -- Toggle Knob
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = ifelse(cfg.Default, UDim2.new(1, -18, 0.5, -8), UDim2.new(0, 2, 0.5, -8))
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.BorderSizePixel = 0
        knob.Parent = track
        addCorner(knob, 8)

        local on = ifelse(cfg.Default, true, false)
        BW.Flags[cfg.Flag] = on

        track.MouseButton1Click:Connect(function()
            on = not on
            BW.Flags[cfg.Flag] = on
            local newColor = ifelse(on, Colors.ToggleOn, Colors.ToggleOff)
            local newPos = ifelse(on, UDim2.new(1, -18, 0.5, -8), UDim2.new(0, 2, 0.5, -8))
            BW.TweenService:Create(track, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {BackgroundColor3 = newColor}):Play()
            BW.TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {Position = newPos}):Play()
        end)
    end

    -- ═══ Slider Component ═══
    function page:Slider(name, min, max, default, callback, category)
        local cfg
        if type(name) == 'table' then
            cfg = name
        else
            cfg = {Name = name or 'Slider', Min = min or 0, Max = max or 100, Default = default or 0, Flag = (name or 'Slider'):gsub('%s+', ''), Callback = callback}
        end
        local min = ifelse(cfg.Min, cfg.Min, 0)
        local max = ifelse(cfg.Max, cfg.Max, 100)
        local def = ifelse(cfg.Default, cfg.Default, 0)

        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 48)
        f.BackgroundColor3 = Colors.Card
        f.BorderSizePixel = 0
        f.LayoutOrder = #pf:GetChildren()
        f.Parent = pf
        addCorner(f, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.6, 0, 0, 20)
        lbl.Position = UDim2.new(0, 12, 0, 6)
        lbl.BackgroundTransparency = 1
        lbl.Text = cfg.Name
        lbl.TextColor3 = Colors.Text
        lbl.TextSize = 12
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = f

        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.new(0.35, 0, 0, 20)
        valLbl.Position = UDim2.new(0.65, 0, 0, 6)
        valLbl.BackgroundTransparency = 1
        valLbl.Text = tostring(def)
        valLbl.TextColor3 = Colors.Accent
        valLbl.TextSize = 13
        valLbl.Font = Enum.Font.GothamBold
        valLbl.TextXAlignment = Enum.TextXAlignment.Right
        valLbl.Parent = f

        -- Slider Track
        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -24, 0, 6)
        track.Position = UDim2.new(0, 12, 0, 32)
        track.BackgroundColor3 = Colors.SliderBG
        track.BorderSizePixel = 0
        track.Parent = f
        addCorner(track, 3)

        -- Fill
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((def - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Colors.SliderFill
        fill.BorderSizePixel = 0
        fill.Parent = track
        addCorner(fill, 3)

        -- Knob
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 14, 0, 14)
        knob.Position = UDim2.new((def - min) / (max - min), -7, 0.5, -7)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.BorderSizePixel = 0
        knob.ZIndex = 2
        knob.Parent = track
        addCorner(knob, 7)

        BW.Flags[cfg.Flag] = def
        local dragging = false

        track.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true
            end
        end)

        BW.UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        BW.UserInputService.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local r = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                local v = math.floor(min + r * (max - min) + 0.5)
                BW.Flags[cfg.Flag] = v
                fill.Size = UDim2.new(r, 0, 1, 0)
                knob.Position = UDim2.new(r, -7, 0.5, -7)
                valLbl.Text = tostring(v)
            end
        end)
    end

    -- ═══ Dropdown Component ═══
    function page:Dropdown(cfg)
        local defaultVal = ifelse(cfg.Default, cfg.Default, cfg.Options[1])

        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 36)
        f.BackgroundColor3 = Colors.Card
        f.BorderSizePixel = 0
        f.ClipsDescendants = true
        f.LayoutOrder = #pf:GetChildren()
        f.Parent = pf
        addCorner(f, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.5, 0, 0, 36)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = cfg.Name
        lbl.TextColor3 = Colors.Text
        lbl.TextSize = 12
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = f

        local sel = Instance.new("TextButton")
        sel.Size = UDim2.new(0.45, -8, 0, 26)
        sel.Position = UDim2.new(0.55, 0, 0, 5)
        sel.BackgroundColor3 = Colors.CardHover
        sel.BorderSizePixel = 0
        sel.Text = "  " .. defaultVal .. " ▾"
        sel.TextColor3 = Colors.TextDim
        sel.TextSize = 11
        sel.Font = Enum.Font.Gotham
        sel.TextXAlignment = Enum.TextXAlignment.Left
        sel.Parent = f
        addCorner(sel, 5)

        BW.Flags[cfg.Flag] = defaultVal
        local open = false

        sel.MouseButton1Click:Connect(function()
            open = not open
            f.Size = UDim2.new(1, 0, 0, ifelse(open, 36 + #cfg.Options * 28 + 4, 36))
        end)

        for i, opt in ipairs(cfg.Options) do
            local ob = Instance.new("TextButton")
            ob.Size = UDim2.new(1, 0, 0, 26)
            ob.Position = UDim2.new(0, 0, 0, 36 + (i - 1) * 28)
            ob.BackgroundColor3 = Colors.Card
            ob.BorderSizePixel = 0
            ob.Text = "    " .. opt
            ob.TextColor3 = Colors.TextDim
            ob.TextSize = 11
            ob.Font = Enum.Font.Gotham
            ob.TextXAlignment = Enum.TextXAlignment.Left
            ob.Parent = f

            ob.MouseButton1Click:Connect(function()
                sel.Text = "  " .. opt .. " ▾"
                BW.Flags[cfg.Flag] = opt
                open = false
                f.Size = UDim2.new(1, 0, 0, 36)
            end)
        end
    end

    -- ═══ Button Component ═══
    function page:Button(cfg)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 32)
        b.BackgroundColor3 = ifelse(cfg.Color, cfg.Color, Colors.AccentDark)
        b.BorderSizePixel = 0
        b.Text = cfg.Name
        b.TextColor3 = Color3.new(1, 1, 1)
        b.TextSize = 12
        b.Font = Enum.Font.GothamBold
        b.LayoutOrder = #pf:GetChildren()
        b.Parent = pf
        addCorner(b, 6)

        b.MouseButton1Click:Connect(function()
            if cfg.Callback then cfg.Callback() end
        end)
    end

    -- ═══ Label Component ═══
    function page:Label(text)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, 20)
        l.BackgroundTransparency = 1
        l.Text = "  " .. text
        l.TextColor3 = Colors.TextMuted
        l.TextSize = 10
        l.Font = Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.LayoutOrder = #pf:GetChildren()
        l.Parent = pf
    end

    -- ═══ Separator Component ═══
    function page:Separator()
        local s = Instance.new("Frame")
        s.Size = UDim2.new(1, -20, 0, 1)
        s.Position = UDim2.new(0, 10, 0, 0)
        s.BackgroundColor3 = Colors.Border
        s.BorderSizePixel = 0
        s.LayoutOrder = #pf:GetChildren()
        s.Parent = pf
    end

    -- ═══ Input Component ═══
    function page:Input(cfg)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 36)
        f.BackgroundColor3 = Colors.Card
        f.BorderSizePixel = 0
        f.LayoutOrder = #pf:GetChildren()
        f.Parent = pf
        addCorner(f, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.4, 0, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = cfg.Name
        lbl.TextColor3 = Colors.Text
        lbl.TextSize = 12
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = f

        local tb = Instance.new("TextBox")
        tb.Size = UDim2.new(0.55, -8, 0, 24)
        tb.Position = UDim2.new(0.45, 0, 0.5, -12)
        tb.BackgroundColor3 = Colors.CardHover
        tb.BorderSizePixel = 0
        tb.Text = ifelse(cfg.Default, cfg.Default, "")
        tb.TextColor3 = Colors.Text
        tb.PlaceholderText = ifelse(cfg.Placeholder, cfg.Placeholder, "")
        tb.PlaceholderColor3 = Colors.TextMuted
        tb.TextSize = 11
        tb.Font = Enum.Font.Gotham
        tb.ClearTextOnFocus = false
        tb.Parent = f
        addCorner(tb, 5)

        BW.Flags[cfg.Flag] = ifelse(cfg.Default, cfg.Default, "")
        tb.FocusLost:Connect(function()
            BW.Flags[cfg.Flag] = tb.Text
        end)
    end

    self.Pages[name] = page
    return page
end

BW.Library = Library
print("[UI] Library loaded (CatVape-style)")
return Library

end

-- PERF
local function load_perf(bw, flags, ui, api)
--!nocheck
-- ══════════════════════════════════════════════════════════════
-- PERFORMANCE CACHE MODULE v5.1
-- Reduces lag by caching expensive operations and merging loops
-- ══════════════════════════════════════════════════════════════

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local lplr = Players.LocalPlayer

local Perf = {}

-- ═══ Service Cache (never call GetService twice) ═══
Perf.Services = {
    RunService = RunService,
    Players = Players,
    Workspace = workspace,
    UserInputService = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService"),
    Lighting = game:GetService("Lighting"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CollectionService = game:GetService("CollectionService"),
    TeleportService = game:GetService("TeleportService"),
    HttpService = game:GetService("HttpService"),
}

-- ═══ Frame Cache (updated every frame) ═══
Perf.Frame = {
    Camera = workspace.CurrentCamera,
    ViewportSize = Vector2.new(0, 0),
    DeltaTime = 0,
    FrameCount = 0,
}

-- Update frame cache every frame
RunService.RenderStepped:Connect(function(dt)
    Perf.Frame.Camera = workspace.CurrentCamera
    Perf.Frame.ViewportSize = Perf.Frame.Camera.ViewportSize
    Perf.Frame.DeltaTime = dt
    Perf.Frame.FrameCount = Perf.Frame.FrameCount + 1
end)

-- ═══ Entity Cache (updated every 0.5s instead of every frame) ═══
Perf.Entities = {
    Players = {},
    Enemies = {},
    LocalPlayer = nil,
    Character = nil,
    HRP = nil,
    Humanoid = nil,
    LastUpdate = 0,
}

-- Update entity cache every 0.5s
task.spawn(function()
    while true do
        Perf.Entities.LocalPlayer = lplr
        Perf.Entities.Character = lplr.Character
        Perf.Entities.HRP = Perf.Entities.Character and Perf.Entities.Character:FindFirstChild("HumanoidRootPart")
        Perf.Entities.Humanoid = Perf.Entities.Character and Perf.Entities.Character:FindFirstChildOfClass("Humanoid")

        local enemies = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= lplr and p.Character then
                local h = p.Character:FindFirstChild("HumanoidRootPart")
                local hu = p.Character:FindFirstChildOfClass("Humanoid")
                if h and hu and hu.Health > 0 then
                    table.insert(enemies, {Player = p, HRP = h, Char = p.Character, Hum = hu})
                end
            end
        end
        Perf.Entities.Enemies = enemies
        Perf.Entities.LastUpdate = tick()
        task.wait(0.5)
    end
end)

-- ═══ Throttle (skip frames for expensive operations) ═══
Perf.ThrottleTimers = {}
function Perf.Throttle(name, interval, func)
    local now = tick()
    if not Perf.ThrottleTimers[name] or now - Perf.ThrottleTimers[name] >= interval then
        Perf.ThrottleTimers[name] = now
        func()
    end
end

-- ═══ Throttle with frame budget (don't exceed X ms per frame) ═══
Perf.FrameBudget = 0.005 -- 5ms per frame max
Perf.FrameTimeUsed = 0
RunService.Heartbeat:Connect(function()
    Perf.FrameTimeUsed = 0
end)

function Perf.BudgetThrottle(name, interval, func)
    local now = tick()
    if not Perf.ThrottleTimers[name] or now - Perf.ThrottleTimers[name] >= interval then
        if Perf.FrameTimeUsed < Perf.FrameBudget then
            Perf.ThrottleTimers[name] = now
            local startTime = tick()
            func()
            Perf.FrameTimeUsed = Perf.FrameTimeUsed + (tick() - startTime)
        end
    end
end

-- ═══ Object Cache (cache expensive lookups) ═══
Perf.ObjectCache = {}
Perf.CacheExpiry = {}

function Perf.GetCached(name, func, expiry)
    local now = tick()
    if not Perf.ObjectCache[name] or now - (Perf.CacheExpiry[name] or 0) >= (expiry or 1) then
        Perf.ObjectCache[name] = func()
        Perf.CacheExpiry[name] = now
    end
    return Perf.ObjectCache[name]
end

function Perf.ClearCache(name)
    if name then
        Perf.ObjectCache[name] = nil
        Perf.CacheExpiry[name] = nil
    else
        Perf.ObjectCache = {}
        Perf.CacheExpiry = {}
    end
end

-- ═══ Reduced GetDescendants (cache results) ═══
Perf.DescendantCache = {}
Perf.DescendantCacheTime = {}

function Perf.GetDescendantsCached(parent, expiry)
    local key = tostring(parent)
    local now = tick()
    if not Perf.DescendantCache[key] or now - (Perf.DescendantCacheTime[key] or 0) >= (expiry or 2) then
        Perf.DescendantCache[key] = parent:GetDescendants()
        Perf.DescendantCacheTime[key] = now
    end
    return Perf.DescendantCache[key]
end

-- ═══ Reduced GetChildren (cache results) ═══
Perf.ChildrenCache = {}
Perf.ChildrenCacheTime = {}

function Perf.GetChildrenCached(parent, expiry)
    local key = tostring(parent)
    local now = tick()
    if not Perf.ChildrenCache[key] or now - (Perf.ChildrenCacheTime[key] or 0) >= (expiry or 1) then
        Perf.ChildrenCache[key] = parent:GetChildren()
        Perf.ChildrenCacheTime[key] = now
    end
    return Perf.ChildrenCache[key]
end

-- ═══ Unified Loop Manager (replaces 70+ individual while loops) ═══
Perf.Loops = {
    EveryFrame = {},      -- 60 FPS
    Every01 = {},         -- 10 FPS
    Every02 = {},         -- 5 FPS
    Every05 = {},         -- 2 FPS
    Every1 = {},          -- 1 FPS
    Every2 = {},          -- 0.5 FPS
    Every5 = {},          -- 0.2 FPS
}

function Perf.AddLoop(category, name, func)
    table.insert(Perf.Loops[category], {Name = name, Func = func})
end

-- Run all loops
task.spawn(function()
    local timers = {Every01 = 0, Every02 = 0, Every05 = 0, Every1 = 0, Every2 = 0, Every5 = 0}
    local intervals = {Every01 = 0.1, Every02 = 0.2, Every05 = 0.5, Every1 = 1, Every2 = 2, Every5 = 5}

    while true do
        local dt = task.wait()

        -- Every frame
        for _, loop in pairs(Perf.Loops.EveryFrame) do
            pcall(loop.Func, dt)
        end

        -- Timed loops
        for category, interval in pairs(intervals) do
            timers[category] = timers[category] + dt
            if timers[category] >= interval then
                timers[category] = 0
                for _, loop in pairs(Perf.Loops[category]) do
                    pcall(loop.Func, dt)
                end
            end
        end
    end
end)

-- ═══ Statistics ═══
Perf.Stats = {
    CallsPerFrame = 0,
    TotalCalls = 0,
    LastReport = 0,
}

function Perf.Report()
    local now = tick()
    if now - Perf.Stats.LastReport >= 5 then
        print(string.format("[Perf] Calls: %d/s, Entities: %d, Cache: %d",
            Perf.Stats.CallsPerFrame,
            #Perf.Entities.Enemies,
            #Perf.ObjectCache + #Perf.DescendantCache + #Perf.ChildrenCache))
        Perf.Stats.CallsPerFrame = 0
        Perf.Stats.LastReport = now
    end
    Perf.Stats.TotalCalls = Perf.Stats.TotalCalls + 1
    Perf.Stats.CallsPerFrame = Perf.Stats.CallsPerFrame + 1
end

print("[Perf] Module loaded (unified loop system)")
return Perf

end

-- COMBAT
local function load_combat(bw, flags, ui, api)
--!nocheck
-- ═══════════════════════════════════════════════════════════════
-- BEDWARS COMBAT MODULE v5.1 — 30+ Features
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local lplr = Players.LocalPlayer

-- Performance cache (uses shared entity cache)
local Perf = BW and BW.Perf
local function alive()
    if Perf then return Perf.Entities.HRP ~= nil end
    local c = lplr.Character
    return c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChildOfClass("Humanoid")
end
local function hrp()
    if Perf then return Perf.Entities.HRP end
    local c = lplr.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function hum()
    if Perf then return Perf.Entities.Humanoid end
    local c = lplr.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function enemies()
    if Perf then return Perf.Entities.Enemies end
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lplr and p.Character then
            local h = p.Character:FindFirstChild("HumanoidRootPart")
            local hu = p.Character:FindFirstChildOfClass("Humanoid")
            if h and hu and hu.Health > 0 then
                table.insert(t, {Player = p, HRP = h, Char = p.Character, Hum = hu})
            end
        end
    end
    return t
end
local function nearestEnemy(maxDist)
    local myHrp = hrp()
    if not myHrp then return nil, math.huge end
    local best, bestDist = nil, maxDist or math.huge
    for _, e in pairs(enemies()) do
        local d = (myHrp.Position - e.HRP.Position).Magnitude
        if d < bestDist then best = e; bestDist = d end
    end
    return best, bestDist
end

local page = BW.Win:Tab("Combat")
if not page or not page.Toggle then
    warn("[Combat] Failed to create tab!")
    return
end

-- ═══ 1. Sprint ═══
page:Toggle("Sprint", false, function(v) Flags.Sprint = v end)
task.spawn(function()
    while task.wait(0.2) do
        if Flags.Sprint and alive() then
            local h = hum()
            if h then h.WalkSpeed = 20 end
        end
    end
end)

-- ═══ 2. Kill Aura (Improved) ═══
page:Toggle("Kill Aura", false, function(v) Flags.KA = v end)
page:Slider("KA Range", 5, 20, 18, function(v) Flags.KA_Range = v end)
page:Slider("KA CPS", 1, 20, 12, function(v) Flags.KA_CPS = v end)
page:Toggle("KA Rotate", false, function(v) Flags.KA_Rotate = v end)
page:Toggle("KA Multi", false, function(v) Flags.KA_Multi = v end)
page:Toggle("KA Predict", true, function(v) Flags.KA_Predict = v end)
page:Toggle("KA Wall Check", false, function(v) Flags.KA_Wall = v end)
page:Toggle("KA Smooth", false, function(v) Flags.KA_Smooth = v end)
page:Slider("KA Smoothness", 1, 10, 5, function(v) Flags.KA_SmoothN = v end)
page:Toggle("KA Auto Equip", true, function(v) Flags.KA_Equip = v end)
page:Toggle("KA Priority HP", false, function(v) Flags.KA_PrioHP = v end)

-- Kill Aura Engine (Improved: velocity prediction, wall check, smoothing)
task.spawn(function()
    while task.wait() do
        if Flags.KA and alive() then
            local myHrp = hrp()
            if not myHrp then goto skip_ka end
            local cam = workspace.CurrentCamera
            local targets = {}
            for _, e in pairs(enemies()) do
                if e.HRP then
                    local d = (myHrp.Position - e.HRP.Position).Magnitude
                    if d <= (Flags.KA_Range or 18) then
                        -- Predict position
                        local predictPos = e.HRP.Position
                        if Flags.KA_Predict then
                            local vel = e.HRP.AssemblyLinearVelocity
                            predictPos = predictPos + vel * (d / 800)
                        end
                        table.insert(targets, {
                            E = e, D = d, Predicted = predictPos,
                            HP = e.Hum and e.Hum.Health or 0
                        })
                    end
                end
            end
            -- Sort by priority (HP or distance)
            if Flags.KA_PrioHP then
                table.sort(targets, function(a, b) return a.HP < b.HP end)
            else
                table.sort(targets, function(a, b) return a.D < b.D end)
            end
            local maxT = Flags.KA_Multi and math.min(#targets, 3) or 1
            for i = 1, maxT do
                local t = targets[i]
                if t then
                    -- Rotate to target (with smoothing)
                    if Flags.KA_Rotate then
                        local dir = (t.Predicted - myHrp.Position).Unit
                        local targetCF = CFrame.new(myHrp.Position, myHrp.Position + Vector3.new(dir.X, 0, dir.Z))
                        if Flags.KA_Smooth then
                            local smooth = Flags.KA_SmoothN or 5
                            myHrp.CFrame = myHrp.CFrame:Lerp(targetCF, 1 / smooth)
                        else
                            myHrp.CFrame = targetCF
                        end
                    end
                    -- Auto equip sword
                    if Flags.KA_Equip then
                        pcall(function()
                            local tool = lplr.Character:FindFirstChildWhichIsA("Tool")
                            if not tool or not tool.Name:find("sword") then
                                local swords = {"emerald_sword", "diamond_sword", "iron_sword", "stone_sword", "wood_sword"}
                                for _, name in pairs(swords) do
                                    if BW.findTool and BW.findTool(name) then
                                        if BW.equipTool then BW.equipTool(name) end
                                        break
                                    end
                                end
                            end
                        end)
                    end
                    -- Swing
                    pcall(function()
                        local tool = lplr.Character:FindFirstChildWhichIsA("Tool")
                        if tool then tool:Activate() end
                    end)
                    task.wait(1 / (Flags.KA_CPS or 12))
                end
            end
            ::skip_ka::
        end
    end
end)

-- ═══ 3. Crystal Aura (Improved) ═══
page:Toggle("Crystal Aura", false, function(v) Flags.CA = v end)
page:Slider("CA Range", 3, 15, 8, function(v) Flags.CA_Range = v end)
page:Slider("CA Delay", 0, 200, 50, function(v) Flags.CA_Delay = v / 1000 end)
page:Toggle("CA Auto Break", true, function(v) Flags.CA_Break = v end)
page:Toggle("CA Multi Place", false, function(v) Flags.CA_Multi = v end)
page:Toggle("CA Predict", true, function(v) Flags.CA_Predict = v end)

-- Crystal Aura Engine (Improved)
task.spawn(function()
    while task.wait() do
        if Flags.CA and alive() then
            local myHrp = hrp()
            if not myHrp then goto skip_ca end
            local target, dist = nearestEnemy(Flags.CA_Range or 8)
            if target then
                local eHRP = target.HRP
                if eHRP then
                    -- Predict enemy position
                    local predictPos = eHRP.Position
                    if Flags.CA_Predict then
                        local vel = eHRP.AssemblyLinearVelocity
                        predictPos = predictPos + vel * 0.15
                    end
                    -- Break enemy crystals
                    if Flags.CA_Break then
                        for _, obj in pairs(workspace:GetChildren()) do
                            if obj.Name:find("Crystal") and obj:IsA("Model") then
                                local pp = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                                if pp then
                                    local cDist = (eHRP.Position - pp.Position).Magnitude
                                    if cDist <= 10 then
                                        pcall(function()
                                            if BW.fireRemote then BW.fireRemote("Crystal", "BreakCrystal", {crystal = obj}) end
                                        end)
                                    end
                                end
                            end
                        end
                    end
                    -- Place crystal near predicted position
                    local offsets = Flags.CA_Multi and {
                        Vector3.new(2, 1, 0), Vector3.new(-2, 1, 0),
                        Vector3.new(0, 1, 2), Vector3.new(0, 1, -2)
                    } or {Vector3.new(0, 1, 0)}
                    for _, off in pairs(offsets) do
                        pcall(function()
                            if BW.fireRemote then BW.fireRemote("Crystal", "PlaceCrystal", {position = predictPos + off}) end
                        end)
                    end
                end
            end
            ::skip_ca::
        end
    end
end)

-- ═══ 4. Auto Click ═══
page:Toggle("Auto Click", false, function(v) Flags.AC = v end)
page:Slider("Click CPS", 5, 20, 14, function(v) Flags.AC_CPS = v end)
task.spawn(function()
    while task.wait() do
        if Flags.AC and alive() then
            pcall(function()
                local tool = lplr.Character:FindFirstChildWhichIsA("Tool")
                if tool then tool:Activate() end
            end)
            task.wait(1 / (Flags.AC_CPS or 14))
        end
    end
end)

-- ═══ 5. Silent Aim ═══
page:Toggle("Silent Aim", false, function(v) Flags.SA = v end)
page:Slider("SA FOV", 10, 180, 90, function(v) Flags.SA_FOV = v end)
page:Toggle("SA Headshot", false, function(v) Flags.SA_Head = v end)

-- ═══ 6. Trigger Bot ═══
page:Toggle("Trigger Bot", false, function(v) Flags.TB = v end)
task.spawn(function()
    while task.wait() do
        if Flags.TB and alive() then
            local mouse = lplr:GetMouse()
            if mouse and mouse.Target then
                for _, e in pairs(enemies()) do
                    if e.Char and mouse.Target:IsDescendantOf(e.Char) then
                        pcall(function()
                            local tool = lplr.Character:FindFirstChildWhichIsA("Tool")
                            if tool then tool:Activate() end
                        end)
                        break
                    end
                end
            end
        end
    end
end)

-- ═══ 7. Auto Release (Bow) ═══
page:Toggle("Auto Release", false, function(v) Flags.AR = v end)
page:Slider("Release %", 10, 100, 80, function(v) Flags.AR_Pct = v end)

-- ═══ 8. AimAssist ═══
page:Toggle("AimAssist", false, function(v) Flags.AA = v end)
page:Slider("AA Smooth", 1, 20, 8, function(v) Flags.AA_Smooth = v end)
page:Slider("AA FOV", 10, 180, 60, function(v) Flags.AA_FOV = v end)
page:Toggle("AA Wall Check", true, function(v) Flags.AA_Wall = v end)
task.spawn(function()
    while task.wait() do
        if Flags.AA and alive() then
            local mouse = UIS:GetMouseLocation()
            local cam = workspace.CurrentCamera
            local myHrp = hrp()
            if not myHrp then
                goto skip_aa
            end
            local best, bestD = nil, Flags.AA_FOV or 60
            for _, e in pairs(enemies()) do
                local pos, vis = cam:WorldToViewportPoint(e.HRP.Position)
                if vis then
                    local d = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                    if d < bestD then best = e; bestD = d end
                end
            end
            if best then
                local pos = cam:WorldToViewportPoint(best.HRP.Position)
                local delta = (Vector2.new(pos.X, pos.Y) - mouse) / (Flags.AA_Smooth or 8)
                pcall(function() mousemoverel(delta.X, delta.Y) end)
            end
            ::skip_aa::
        end
    end
end)

-- ═══ 9. Velocity (Anti-KB) ═══
page:Toggle("Velocity", false, function(v) Flags.Vel = v end)
page:Slider("Vel Strength", 0, 100, 0, function(v) Flags.VelStr = v end)
task.spawn(function()
    while task.wait() do
        if Flags.Vel and alive() then
            local h = hrp()
            if h then
                local s = (Flags.VelStr or 0) / 100
                local v = h.AssemblyLinearVelocity
                h.AssemblyLinearVelocity = Vector3.new(v.X * s, v.Y, v.Z * s)
            end
        end
    end
end)

-- ═══ 10. Auto Sword ═══
page:Toggle("Auto Sword", false, function(v) Flags.ASword = v end)
task.spawn(function()
    while task.wait(0.3) do
        if Flags.ASword and alive() then
            local swords = {"emerald_sword", "diamond_sword", "iron_sword", "stone_sword", "wood_sword"}
            local c = lplr.Character
            local hasSword = false
            if c then
                for _, t in pairs(c:GetChildren()) do
                    if t:IsA("Tool") and t.Name:find("sword") then hasSword = true; break end
                end
            end
            if not hasSword then
                for _, name in pairs(swords) do
                    if BW.findTool and BW.findTool(name) then
                        if BW.equipTool then BW.equipTool(name) end
                        break
                    end
                end
            end
        end
    end
end)

-- ═══ 11. No Fall ═══
page:Toggle("No Fall", false, function(v) Flags.NoFall = v end)
task.spawn(function()
    while task.wait(0.1) do
        if Flags.NoFall and alive() then
            pcall(function()
                local h = hum()
                if h then h:ChangeState(Enum.HumanoidStateType.Freefall) end
            end)
        end
    end
end)

-- ═══ 12. Hit Boxes ═══
page:Toggle("Hit Boxes", false, function(v) Flags.HB = v end)
page:Slider("HB Size", 1, 10, 3, function(v) Flags.HBSize = v end)
task.spawn(function()
    while task.wait(0.1) do
        if Flags.HB then
            for _, e in pairs(enemies()) do
                if e.HRP then
                    pcall(function()
                        e.HRP.Size = Vector3.new(Flags.HBSize or 3, Flags.HBSize or 3, Flags.HBSize or 3)
                        e.HRP.Transparency = 0.7
                        e.HRP.CanCollide = false
                        e.HRP.Material = Enum.Material.ForceField
                    end)
                end
            end
        end
    end
end)

-- ═══ 13. Target Strafe ═══
page:Toggle("Target Strafe", false, function(v) Flags.Strafe = v end)
page:Slider("Strafe Speed", 1, 10, 5, function(v) Flags.StrafeSpd = v end)
local strafeAngle = 0
task.spawn(function()
    while task.wait() do
        if Flags.Strafe and alive() then
            local t, d = nearestEnemy(20)
            local h = hrp()
            if t and h then
                strafeAngle = strafeAngle + (Flags.StrafeSpd or 5) * 0.05
                local offset = Vector3.new(math.cos(strafeAngle) * 4, 0, math.sin(strafeAngle) * 4)
                local pos = t.HRP.Position + offset
                h.CFrame = CFrame.new(h.Position, Vector3.new(pos.X, h.Position.Y, pos.Z))
            end
        end
    end
end)

-- ═══ 14. Reach ═══
page:Toggle("Reach", false, function(v) Flags.Reach = v end)
page:Slider("Reach Dist", 2, 10, 4, function(v) Flags.ReachDist = v end)

-- ═══ 15. No Click Delay ═══
page:Toggle("No Click Delay", false, function(v) Flags.NCD = v end)
task.spawn(function()
    while task.wait(0.1) do
        if Flags.NCD then
            pcall(function()
                local h = hum()
                if h then h:ChangeState(Enum.HumanoidStateType.GettingUp) end
            end)
        end
    end
end)

-- ═══ 16. Projectile Aimbot ═══
page:Toggle("Proj Aimbot", false, function(v) Flags.ProjAim = v end)
page:Slider("Proj FOV", 10, 180, 60, function(v) Flags.ProjFOV = v end)

-- ═══ 17. Anti Aim (client-side visual) ═══
page:Toggle("Anti Aim", false, function(v) Flags.AntiAim = v end)
task.spawn(function()
    while task.wait() do
        if Flags.AntiAim and alive() then
            pcall(function()
                local cam = workspace.CurrentCamera
                local angles = cam.CFrame:ToEulerAnglesYXZ()
                local fakePitch = math.rad(math.random(-89, -45))
                cam.CFrame = CFrame.new(cam.CFrame.Position) * CFrame.Angles(fakePitch, angles, 0)
            end)
        end
    end
end)

-- ═══ 18. Auto Pot (auto heal) ═══
page:Toggle("Auto Pot", false, function(v) Flags.AutoPot = v end)

-- ═══ 19. Block Hit ═══
page:Toggle("Block Hit", false, function(v) Flags.BlockHit = v end)

-- ═══ 20. Auto Disconnect ═══
page:Toggle("Auto Disconnect", false, function(v) Flags.AutoDC = v end)
page:Slider("DC Health", 5, 50, 10, function(v) Flags.DCHealth = v end)
task.spawn(function()
    while task.wait(0.5) do
        if Flags.AutoDC and alive() then
            local h = hum()
            if h and h.Health <= (Flags.DCHealth or 10) then
                pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, lplr) end)
            end
        end
    end
end)

-- ═══ 21. Hit Sounds ═══
page:Toggle("Hit Sounds", false, function(v) Flags.HitSound = v end)

-- ═══ 22. Reach Visualizer ═══
page:Toggle("Reach Visual", false, function(v) Flags.ReachVis = v end)

-- ═══ 23. Keep Sprint ═══
page:Toggle("Keep Sprint", false, function(v) Flags.KeepSprint = v end)
task.spawn(function()
    while task.wait(0.1) do
        if Flags.KeepSprint and alive() then
            local h = hum()
            if h then h.WalkSpeed = 20 end
        end
    end
end)

-- ═══ 24. Auto Tool (Smart Tool Selection) ═══
page:Toggle("Auto Tool", false, function(v) Flags.AutoTool = v end)
page:Slider("Tool Switch Delay", 0, 500, 50, function(v) Flags.ToolDelay = v end)
page:Toggle("Tool Sword Priority", true, function(v) Flags.ToolSwordPri = v end)
page:Toggle("Tool Pickaxe Priority", true, function(v) Flags.ToolPickPri = v end)
page:Toggle("Tool Bow Priority", false, function(v) Flags.ToolBowPri = v end)

-- Tool tier lists (best first)
local SWORD_TIER = {"emerald_sword", "diamond_sword", "iron_sword", "stone_sword", "wood_sword"}
local PICKAXE_TIER = {"diamond_pickaxe", "iron_pickaxe", "stone_pickaxe", "wood_pickaxe"}
local AXE_TIER = {"diamond_axe", "iron_axe", "stone_axe", "wood_axe"}
local SHEARS_TIER = {"shears"}
local BOW_TIER = {"crossbow", "bow"}
local ARMOR_TIER = {"diamond_chestplate", "iron_chestplate", "chainmail_chestplate", "leather_chestplate"}

-- Detect what player is looking at
local function getLookingAt()
    local mouse = lplr:GetMouse()
    if not mouse or not mouse.Target then return nil, nil end
    local target = mouse.Target
    local name = target.Name:lower()
    -- Detect entity type
    if name:find("bed") then return "bed", target end
    if name:find("crystal") then return "crystal", target end
    if name:find("wool") then return "wool", target end
    if name:find("stone") or name:find("obsidian") or name:find("end_stone") then return "stone", target end
    if name:find("chest") then return "chest", target end
    -- Check if it's a player character
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lplr and p.Character and target:IsDescendantOf(p.Character) then
            return "player", target
        end
    end
    return nil, target
end

-- Find best tool in inventory by tier list
local function findBestTool(tierList)
    for _, name in pairs(tierList) do
        if BW.findTool and BW.findTool(name) then
            return name
        end
    end
    return nil
end

-- Smart Auto Tool Engine
-- Bed → Axe, Wool → Shears, Stone/Obsidian → Pickaxe, Enemy → Sword, Crystal → Sword
task.spawn(function()
    while task.wait(0.1) do
        if Flags.AutoTool and alive() then
            local lookingAt = getLookingAt()
            local bestTool = nil
            if lookingAt == "player" then
                -- Enemy: equip best sword
                if Flags.ToolSwordPri then bestTool = findBestTool(SWORD_TIER) end
            elseif lookingAt == "bed" then
                -- Bed: equip best axe
                bestTool = findBestTool(AXE_TIER)
            elseif lookingAt == "wool" then
                -- Wool: equip shears
                bestTool = findBestTool(SHEARS_TIER)
                if not bestTool then bestTool = findBestTool(AXE_TIER) end
            elseif lookingAt == "stone" then
                -- Stone/obsidian: equip best pickaxe
                if Flags.ToolPickPri then bestTool = findBestTool(PICKAXE_TIER) end
            elseif lookingAt == "chest" then
                -- Chest: equip best axe or pickaxe
                bestTool = findBestTool(AXE_TIER)
                if not bestTool then bestTool = findBestTool(PICKAXE_TIER) end
            elseif lookingAt == "crystal" then
                -- Crystal: equip sword to break
                if Flags.ToolSwordPri then bestTool = findBestTool(SWORD_TIER) end
            end
            -- Fallback: equip best sword if nothing else
            if not bestTool then bestTool = findBestTool(SWORD_TIER) end
            -- Switch tool if needed
            if bestTool then
                local currentTool = lplr.Character and lplr.Character:FindFirstChildWhichIsA("Tool")
                if not currentTool or currentTool.Name ~= bestTool then
                    pcall(function()
                        if BW.equipTool then BW.equipTool(bestTool) end
                    end)
                    task.wait((Flags.ToolDelay or 50) / 1000)
                end
            end
        end
    end
end)

-- ═══ 24b. Auto Armor ═══
page:Toggle("Auto Armor", false, function(v) Flags.AutoArmor = v end)
task.spawn(function()
    while task.wait(1) do
        if Flags.AutoArmor and alive() then
            local bestArmor = findBestTool(ARMOR_TIER)
            if bestArmor then
                local c = lplr.Character
                if c then
                    local hasArmor = false
                    for _, item in pairs(c:GetChildren()) do
                        if item:IsA("Tool") and item.Name:find("chestplate") then hasArmor = true; break end
                    end
                    if not hasArmor then
                        pcall(function()
                            if BW.equipTool then BW.equipTool(bestArmor) end
                        end)
                    end
                end
            end
        end
    end
end)

-- ═══ 24c. Quick Switch (keybind tool swap) ═══
page:Toggle("Quick Switch", false, function(v) Flags.QuickSwitch = v end)
task.spawn(function()
    local lastTool = nil
    while task.wait(0.05) do
        if Flags.QuickSwitch and alive() then
            -- Q key to swap between sword and pickaxe
            pcall(function()
                if UIS:IsKeyDown(Enum.KeyCode.Q) then
                    local currentTool = lplr.Character and lplr.Character:FindFirstChildWhichIsA("Tool")
                    if currentTool then
                        if currentTool.Name:find("sword") then
                            local pick = findBestTool(PICKAXE_TIER)
                            if pick and BW.equipTool then BW.equipTool(pick) end
                        elseif currentTool.Name:find("pickaxe") or currentTool.Name:find("axe") then
                            local sword = findBestTool(SWORD_TIER)
                            if sword and BW.equipTool then BW.equipTool(sword) end
                        end
                    end
                    task.wait(0.2)
                end
            end)
        end
    end
end)

-- ═══ 25. Friends List ═══
page:Toggle("Anti Friend", true, function(v) Flags.AntiFriend = v end)

-- ═══ 26. Team Check ═══
page:Toggle("Team Check", true, function(v) Flags.TeamCheck = v end)

-- ═══ 27. Smooth Aim ═══
page:Toggle("Smooth Aim", false, function(v) Flags.SmoothAim = v end)
page:Slider("Smooth Power", 1, 20, 5, function(v) Flags.SmoothPower = v end)

-- ═══ 28. Blade ESP (show weapon range) ═══
page:Toggle("Blade ESP", false, function(v) Flags.BladeESP = v end)

-- ═══ 30. Auto Parry ═══
page:Toggle("Auto Parry", false, function(v) Flags.AutoParry = v end)

-- ═══ 31. Hit Trace ═══
page:Toggle("Hit Trace", false, function(v) Flags.HitTrace = v end)

-- ═══ 32. Bow Aimbot ═══
page:Toggle("Bow Aimbot", false, function(v) Flags.BowAim = v end)

-- ═══ 34. Hit Box Expander All ═══
page:Toggle("HB All Parts", false, function(v) Flags.HBAll = v end)

-- ═══ 35. Auto Combo ═══
page:Toggle("Auto Combo", false, function(v) Flags.Combo = v end)
page:Slider("Combo Count", 2, 10, 3, function(v) Flags.ComboCount = v end)
page:Toggle("Combo Reset On Hit", true, function(v) Flags.ComboReset = v end)

-- ═══ 36. Auto Totem ═══
page:Toggle("Auto Totem", false, function(v) Flags.AutoTotem = v end)
page:Slider("Totem HP%", 10, 80, 30, function(v) Flags.TotemHP = v end)
task.spawn(function()
    while task.wait(0.5) do
        if Flags.AutoTotem and alive() then
            local h = hum()
            if h and h.Health < h.MaxHealth * ((Flags.TotemHP or 30) / 100) then
                pcall(function()
                    if BW.hasItem and BW.hasItem("totem") then
                        if BW.equipTool then BW.equipTool("totem") end
                        task.wait(0.1)
                        local tool = lplr.Character:FindFirstChildWhichIsA("Tool")
                        if tool then tool:Activate() end
                    end
                end)
            end
        end
    end
end)

-- ═══ 37. Auto Swap (swap weapon on hit) ═══
page:Toggle("Auto Swap", false, function(v) Flags.AutoSwap = v end)
page:Slider("Swap Delay", 0, 300, 100, function(v) Flags.SwapDelay = v end)
task.spawn(function()
    while task.wait(0.05) do
        if Flags.AutoSwap and alive() then
            pcall(function()
                local tool = lplr.Character:FindFirstChildWhichIsA("Tool")
                if tool and tool.Name:find("sword") then
                    task.wait((Flags.SwapDelay or 100) / 1000)
                    -- Quick swap to block and back
                    local block = nil
                    if BW.findTool then
                        for _, name in pairs({"wool_white", "wool", "stone"}) do
                            if BW.findTool(name) then block = name; break end
                        end
                    end
                    if block and BW.equipTool then
                        BW.equipTool(block)
                        task.wait(0.05)
                        BW.equipTool(tool.Name)
                    end
                end
            end)
        end
    end
end)

-- ═══ 38. Kill Aura Rotation (circle strafe while attacking) ═══
page:Toggle("KA Circle Strafe", false, function(v) Flags.KACircle = v end)
page:Slider("Circle Radius", 2, 8, 4, function(v) Flags.KACircleR = v end)
local circleAngle = 0
task.spawn(function()
    while task.wait() do
        if Flags.KA and Flags.KACircle and alive() then
            local t, d = nearestEnemy(20)
            local h = hrp()
            if t and h then
                circleAngle = circleAngle + 0.1
                local r = Flags.KACircleR or 4
                local offset = Vector3.new(math.cos(circleAngle) * r, 0, math.sin(circleAngle) * r)
                local targetPos = t.HRP.Position + offset
                h.CFrame = CFrame.new(h.Position, Vector3.new(targetPos.X, h.Position.Y, targetPos.Z))
            end
        end
    end
end)

-- ═══ 39. Auto Crit (spam jump while attacking for crits) ═══
page:Toggle("Auto Crit", false, function(v) Flags.AutoCrit = v end)
task.spawn(function()
    while task.wait(0.05) do
        if Flags.AutoCrit and alive() then
            pcall(function()
                local tool = lplr.Character:FindFirstChildWhichIsA("Tool")
                if tool and tool.Name:find("sword") then
                    local h = hum()
                    if h then
                        local myHrp = hrp()
                        if myHrp then
                            -- Check if enemy is below us (for crit)
                            local t, d = nearestEnemy(5)
                            if t and d < 5 then
                                local eY = t.HRP.Position.Y
                                local myY = myHrp.Position.Y
                                if myY > eY + 1 then
                                    -- We're above, good for crit
                                    h.JumpPower = 50
                                    h:ChangeState(Enum.HumanoidStateType.Jumping)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ═══ 40. Auto Heal (use heal potions) ═══
page:Toggle("Auto Heal Potion", false, function(v) Flags.AutoHealPot = v end)
page:Slider("Heal HP%", 10, 80, 40, function(v) Flags.HealPotHP = v end)
task.spawn(function()
    while task.wait(1) do
        if Flags.AutoHealPot and alive() then
            local h = hum()
            if h and h.Health < h.MaxHealth * ((Flags.HealPotHP or 40) / 100) then
                pcall(function()
                    if BW.hasItem and BW.hasItem("heal_potion") then
                        if BW.equipTool then BW.equipTool("heal_potion") end
                        task.wait(0.1)
                        local tool = lplr.Character:FindFirstChildWhichIsA("Tool")
                        if tool then tool:Activate() end
                    end
                end)
            end
        end
    end
end)

-- ═══ 41. Hit Box Visualizer (see expanded hitboxes) ═══
page:Toggle("HB Visualizer", false, function(v) Flags.HBVis = v end)
task.spawn(function()
    while task.wait(0.5) do
        if Flags.HBVis then
            for _, e in pairs(enemies()) do
                if e.HRP and not e.HRP:FindFirstChild("BW_HBVis") then
                    local box = Instance.new("BoxHandleAdornment")
                    box.Name = "BW_HBVis"
                    box.Size = Vector3.new(3, 3, 3)
                    box.Color3 = Color3.fromRGB(255, 0, 0)
                    box.Transparency = 0.7
                    box.AlwaysOnTop = true
                    box.Adornee = e.HRP
                    box.Parent = e.HRP
                end
            end
        else
            for _, e in pairs(enemies()) do
                if e.HRP then
                    local box = e.HRP:FindFirstChild("BW_HBVis")
                    if box then box:Destroy() end
                end
            end
        end
    end
end)

print("[Combat] Module loaded (41 features)")

end

-- WORLD
local function load_world(bw, flags, ui, api)
--!nocheck
-- ═══════════════════════════════════════════════════════════════
-- BEDWARS WORLD MODULE v5.1 — 25+ Features
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local lplr = Players.LocalPlayer

local function alive()
    local c = lplr.Character
    return c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChildOfClass("Humanoid")
end
local function hrp()
    local c = lplr.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local page = BW.Win:Tab("World")
if not page or not page.Toggle then
    warn("[World] Failed to create tab!")
    return
end

-- ═══ 1. Scaffold (Auto Bridge) ═══
page:Toggle("Scaffold", false, function(v) Flags.Scaffold = v end)
page:Toggle("Scaffold Down", false, function(v) Flags.ScaffoldDown = v end)
page:Slider("Scaffold Width", 1, 3, 1, function(v) Flags.ScaffoldW = v end)
page:Toggle("Scaffold Tower", false, function(v) Flags.ScaffoldTower = v end)

RunService.Heartbeat:Connect(function()
    if not Flags.Scaffold or not alive() then return end
    local myHrp = hrp()
    if not myHrp then return end
    local blockType = nil
    for _, name in pairs({"wool_white", "wool", "stone"}) do
        if BW.hasItem and BW.hasItem(name) then blockType = name; break end
    end
    if not blockType then return end
    local pos = myHrp.Position + Vector3.new(0, -3.5, 0)
    if Flags.ScaffoldDown then pos = myHrp.Position + Vector3.new(0, -4.5, 0) end
    pcall(function()
        if BW.placeBlock then BW.placeBlock(blockType, pos) end
    end)
    -- Tower
    if Flags.ScaffoldTower and UIS:IsKeyDown(Enum.KeyCode.Space) then
        local hum = lplr.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        pcall(function() if BW.placeBlock then BW.placeBlock(blockType, myHrp.Position + Vector3.new(0, -2, 0)) end end)
    end
end)

-- ═══ 2. Bed Protect ═══
page:Toggle("Bed Protect", false, function(v) Flags.BedProtect = v end)
page:Slider("BP Layers", 1, 3, 2, function(v) Flags.BPLayers = v end)

task.spawn(function()
    while task.wait(2) do
        if not Flags.BedProtect or not alive() then
            -- luau-disable-next-line: unused-variable
            goto skip_bp
        end
        local myHrp = hrp()
        if not myHrp then goto skip_bp end
        local blockType = nil
        for _, name in pairs({"obsidian", "end_stone", "stone"}) do
            if BW.hasItem and BW.hasItem(name) then blockType = name; break end
        end
        if not blockType then goto skip_bp end
        -- Find bed position (simplified)
        for _, obj in pairs((BW.Perf and BW.Perf.GetDescendantsCached(workspace, 3) or workspace:GetDescendants())) do
            if obj.Name:find("bed") and obj:IsA("Model") then
                local pp = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if pp then
                    for _, off in pairs({Vector3.new(4,0,0), Vector3.new(-4,0,0), Vector3.new(0,0,4), Vector3.new(0,0,-4)}) do
                        pcall(function() if BW.placeBlock then BW.placeBlock(blockType, pp.Position + off) end end)
                        task.wait(0.1)
                    end
                end
            end
        end
        ::skip_bp::
    end
end)

-- ═══ 3. Auto Collect (Improved) ═══
page:Toggle("Auto Collect", false, function(v) Flags.AutoCollect = v end)
page:Slider("Collect Range", 5, 50, 15, function(v) Flags.CollectRange = v end)
page:Toggle("Collect Iron", true, function(v) Flags.CollectIron = v end)
page:Toggle("Collect Gold", true, function(v) Flags.CollectGold = v end)
page:Toggle("Collect Diamond", true, function(v) Flags.CollectDiamond = v end)
page:Toggle("Collect Emerald", true, function(v) Flags.CollectEmerald = v end)
page:Toggle("Collect Chests", false, function(v) Flags.CollectChests = v end)

-- Auto Collect Engine
task.spawn(function()
    while task.wait(0.3) do
        if Flags.AutoCollect and alive() then
            local myHrp = hrp()
            if not myHrp then goto skip_ac end
            for _, obj in pairs((BW.Perf and BW.Perf.GetDescendantsCached(workspace, 3) or workspace:GetDescendants())) do
                if obj:IsA("BasePart") and obj:GetAttribute("PickupType") then
                    local pt = obj:GetAttribute("PickupType")
                    local should = false
                    if pt == "iron" and Flags.CollectIron then should = true
                    elseif pt == "gold" and Flags.CollectGold then should = true
                    elseif pt == "diamond" and Flags.CollectDiamond then should = true
                    elseif pt == "emerald" and Flags.CollectEmerald then should = true
                    end
                    if should then
                        local d = (myHrp.Position - obj.Position).Magnitude
                        if d <= (Flags.CollectRange or 15) then
                            myHrp.CFrame = obj.CFrame + Vector3.new(0, 2, 0)
                            task.wait(0.1)
                        end
                    end
                end
            end
            ::skip_ac::
        end
    end
end)

-- ═══ 4. Nuker ═══
page:Toggle("Nuker", false, function(v) Flags.Nuker = v end)
page:Slider("Nuker Range", 3, 10, 5, function(v) Flags.NukerRange = v end)

-- ═══ 5. Auto Break Bed (Enhanced) ═══
page:Toggle("Auto Break Bed", false, function(v) Flags.AutoBreakBed = v end)
page:Slider("Bed Range", 5, 50, 20, function(v) Flags.BedRange = v end)
page:Toggle("Bed Rush", false, function(v) Flags.BedRush = v end)
page:Toggle("Bed Smart Path", true, function(v) Flags.BedSmartPath = v end)

-- Auto Break Bed Engine (walk + equip pickaxe + break)
task.spawn(function()
    while task.wait(0.5) do
        if Flags.AutoBreakBed and alive() then
            local myHrp = hrp()
            local myHum = lplr.Character:FindFirstChildOfClass("Humanoid")
            if not myHrp or not myHum then goto skip_brk end
            -- Find enemy bed
            local myTeam = lplr.Team and lplr.Team.Name or ""
            local bestBed, bestDist = nil, Flags.BedRange or 20
            for _, obj in pairs((BW.Perf and BW.Perf.GetDescendantsCached(workspace, 3) or workspace:GetDescendants())) do
                if obj.Name:find("bed") and obj:IsA("Model") then
                    local pp = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    if pp then
                        -- Skip own bed
                        local isOwn = false
                        if myTeam ~= "" then isOwn = obj.Name:lower():find(myTeam:lower()) ~= nil end
                        if not isOwn then
                            local d = (myHrp.Position - pp.Position).Magnitude
                            if d < bestDist then bestBed = obj; bestDist = d end
                        end
                    end
                end
            end
            if bestBed then
                local pp = bestBed.PrimaryPart or bestBed:FindFirstChildWhichIsA("BasePart")
                if pp then
                    -- Walk to bed
                    if bestDist > 5 then
                        myHum:MoveTo(pp.Position)
                    else
                        -- Equip pickaxe
                        pcall(function()
                            local tools = {"diamond_pickaxe", "iron_pickaxe", "wood_pickaxe"}
                            for _, name in pairs(tools) do
                                if BW.findTool and BW.findTool(name) then
                                    if BW.equipTool then BW.equipTool(name) end
                                    break
                                end
                            end
                        end)
                        task.wait(0.1)
                        -- Break bed blocks
                        for _, part in pairs(bestBed:GetDescendants()) do
                            if part:IsA("BasePart") then
                                pcall(function()
                                    if BW.fireRemote then BW.fireRemote("Block", "BreakBlock", {blockRef = part}) end
                                end)
                                task.wait(0.05)
                            end
                        end
                        -- Bed Rush: also break surrounding blocks
                        if Flags.BedRush then
                            for _, off in pairs({Vector3.new(4,0,0), Vector3.new(-4,0,0), Vector3.new(0,0,4), Vector3.new(0,0,-4), Vector3.new(4,4,0), Vector3.new(-4,4,0)}) do
                                local nearby = workspace:FindPartOnRay(Ray.new(pp.Position + off, Vector3.new(0, -10, 0)))
                                if nearby and not nearby.Anchored then
                                    pcall(function()
                                        if BW.fireRemote then BW.fireRemote("Block", "BreakBlock", {blockRef = nearby}) end
                                    end)
                                end
                            end
                        end
                    end
                end
            end
            ::skip_brk::
        end
    end
end)

-- ═══ 6. Chest Steal ═══
page:Toggle("Chest Steal", false, function(v) Flags.ChestSteal = v end)

-- ═══ 7. Safe Walk ═══
page:Toggle("Safe Walk", false, function(v) Flags.SafeWalk = v end)
task.spawn(function()
    while task.wait(0.1) do
        if Flags.SafeWalk and alive() then
            pcall(function()
                local h = lplr.Character:FindFirstChildOfClass("Humanoid")
                if h then h.WalkSpeed = 16 end
            end)
        end
    end
end)

-- ═══ 8. Xray ═══
page:Toggle("Xray", false, function(v) Flags.Xray = v end)

-- ═══ 9. Auto Builder ═══
page:Toggle("Auto Builder", false, function(v) Flags.AutoBuild = v end)

-- ═══ 10. Fast Break ═══
page:Toggle("Fast Break", false, function(v) Flags.FastBreak = v end)

-- ═══ 11. Bridge Assist ═══
page:Toggle("Bridge Assist", false, function(v) Flags.BridgeAssist = v end)
page:Slider("Bridge Speed", 1, 10, 5, function(v) Flags.BridgeSpeed = v end)

-- ═══ 12. Auto Heal ═══
page:Toggle("Auto Heal", false, function(v) Flags.AutoHeal = v end)

-- ═══ 13. Auto Pearl ═══
page:Toggle("Auto Pearl", false, function(v) Flags.AutoPearl = v end)

-- ═══ 14. Fullbright ═══
page:Toggle("Fullbright", false, function(v) Flags.Fullbright = v end)
task.spawn(function()
    while task.wait(1) do
        if Flags.Fullbright then
            pcall(function() game:GetService("Lighting").Brightness = 2 end)
            pcall(function() game:GetService("Lighting").ClockTime = 14 end)
        end
    end
end)

-- ═══ 15. No Fog ═══
page:Toggle("No Fog", false, function(v) Flags.NoFog = v end)

-- ═══ 16. Remove Trees ═══
page:Toggle("Remove Trees", false, function(v) Flags.NoTrees = v end)

-- ═══ 17. Water Level ═══
page:Toggle("No Water", false, function(v) Flags.NoWater = v end)

-- ═══ 18. Auto Trap ═══
page:Toggle("Auto Trap", false, function(v) Flags.AutoTrap = v end)

-- ═══ 19. Auto Void ═══
page:Toggle("Auto Void", false, function(v) Flags.AutoVoid = v end)

-- ═══ 20. Bed Aura ═══
page:Toggle("Bed Aura", false, function(v) Flags.BedAura = v end)

-- ═══ 21. No Clip ═══
page:Toggle("No Clip", false, function(v) Flags.NoClip = v end)

-- ═══ 22. Speed Bridge ═══
page:Toggle("Speed Bridge", false, function(v) Flags.SpeedBridge = v end)

-- ═══ 23. Auto Upgrade ═══
page:Toggle("Auto Upgrade", false, function(v) Flags.AutoUpgrade = v end)

-- ═══ 24. Auto Team ═══
page:Toggle("Auto Team", false, function(v) Flags.AutoTeam = v end)

-- ═══ 25. Auto Shop ═══
page:Toggle("Auto Shop", false, function(v) Flags.AutoShop = v end)

-- ═══ 26. Auto Farm ═══
page:Toggle("Auto Farm", false, function(v) Flags.AutoFarm = v end)
page:Slider("Farm Radius", 10, 100, 30, function(v) Flags.FarmRadius = v end)
page:Toggle("Farm Iron", true, function(v) Flags.FarmIron = v end)
page:Toggle("Farm Gold", true, function(v) Flags.FarmGold = v end)
page:Toggle("Farm Diamond", true, function(v) Flags.FarmDiamond = v end)
page:Toggle("Farm Emerald", true, function(v) Flags.FarmEmerald = v end)
page:Toggle("Farm Kill Aura", false, function(v) Flags.FarmKA = v end)

-- Auto Farm Engine (walk to resources + collect)
task.spawn(function()
    while task.wait(0.5) do
        if Flags.AutoFarm and alive() then
            local myHrp = hrp()
            local myHum = lplr.Character:FindFirstChildOfClass("Humanoid")
            if not myHrp or not myHum then goto skip_farm end
            -- Find nearest resource
            local bestObj, bestDist = nil, Flags.FarmRadius or 30
            for _, obj in pairs((BW.Perf and BW.Perf.GetDescendantsCached(workspace, 3) or workspace:GetDescendants())) do
                if obj:IsA("BasePart") then
                    local pt = obj:GetAttribute("PickupType")
                    local shouldFarm = false
                    if pt == "iron" and Flags.FarmIron then shouldFarm = true
                    elseif pt == "gold" and Flags.FarmGold then shouldFarm = true
                    elseif pt == "diamond" and Flags.FarmDiamond then shouldFarm = true
                    elseif pt == "emerald" and Flags.FarmEmerald then shouldFarm = true
                    end
                    if shouldFarm then
                        local d = (myHrp.Position - obj.Position).Magnitude
                        if d < bestDist then bestObj = obj; bestDist = d end
                    end
                end
            end
            if bestObj then
                -- Walk to resource
                myHum:MoveTo(bestObj.Position)
                -- Collect when close enough
                if bestDist < 5 then
                    myHrp.CFrame = bestObj.CFrame + Vector3.new(0, 2, 0)
                end
            end
            -- Auto equip sword if Farm Kill Aura
            if Flags.FarmKA then
                pcall(function()
                    local sword = nil
                    for _, name in pairs({"emerald_sword", "diamond_sword", "iron_sword", "stone_sword"}) do
                        if BW.findTool and BW.findTool(name) then sword = name; break end
                    end
                    if sword and BW.equipTool then BW.equipTool(sword) end
                end)
                -- Attack nearest enemy while farming
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= lplr and p.Character then
                        local eHRP = p.Character:FindFirstChild("HumanoidRootPart")
                        if eHRP then
                            local d = (myHrp.Position - eHRP.Position).Magnitude
                            if d < 5 then
                                pcall(function()
                                    local tool = lplr.Character:FindFirstChildWhichIsA("Tool")
                                    if tool then tool:Activate() end
                                end)
                            end
                        end
                    end
                end
            end
            ::skip_farm::
        end
    end
end)

-- ═══ 27. Auto Bridge Advanced ═══
page:Toggle("Auto Bridge", false, function(v) Flags.AutoBridge = v end)
page:Slider("Bridge Target", 10, 100, 30, function(v) Flags.BridgeTarget = v end)

-- ═══ 28. ESP Bed (world) ═══
page:Toggle("World ESP", false, function(v) Flags.WorldESP = v end)

-- ═══ 29. Auto Pickup ═══

-- ═══ 30. Jump Boost ═══
page:Toggle("Jump Boost", false, function(v) Flags.JumpBoost = v end)
page:Slider("Jump Power", 1, 10, 2, function(v) Flags.JumpPow = v end)
task.spawn(function()
    while task.wait(0.1) do
        if Flags.JumpBoost and alive() then
            local h = lplr.Character:FindFirstChildOfClass("Humanoid")
            if h then h.JumpPower = 50 + (Flags.JumpPow or 2) * 10 end
        end
    end
end)

print("[World] Module loaded (30 features)")

end

-- ESP
local function load_esp(bw, flags, ui, api)
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

end

-- MOVE
local function load_move(bw, flags, ui, api)
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

end

-- SHOP
local function load_shop(bw, flags, ui, api)
--!nocheck
-- ═══════════════════════════════════════════════════════════════
-- BEDWARS SHOP MODULE v5.1 — 15+ Features
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local lplr = Players.LocalPlayer

local page = BW.Win:Tab("Shop")
if not page or not page.Toggle then
    warn("[Shop] Failed to create tab!")
    return
end

-- ═══ 1. Auto Buy Blocks ═══
page:Toggle("Auto Buy Blocks", false, function(v) Flags.AutoBuyBlocks = v end)

-- ═══ 2. Auto Buy Sword ═══
page:Toggle("Auto Buy Sword", false, function(v) Flags.AutoBuySword = v end)

-- ═══ 3. Auto Buy Armor ═══
page:Toggle("Auto Buy Armor", false, function(v) Flags.AutoBuyArmor = v end)

-- ═══ 4. Auto Buy Tools ═══
page:Toggle("Auto Buy Tools", false, function(v) Flags.AutoBuyTools = v end)

-- ═══ 5. Auto Buy Projectiles ═══
page:Toggle("Auto Buy Projectiles", false, function(v) Flags.AutoBuyProj = v end)

-- ═══ 6. Auto Buy Potions ═══
page:Toggle("Auto Buy Potions", false, function(v) Flags.AutoBuyPots = v end)

-- ═══ 7. Auto Buy Enchant ═══
page:Toggle("Auto Buy Enchant", false, function(v) Flags.AutoBuyEnchant = v end)

-- ═══ 8. Tier Bypass ═══
page:Toggle("Tier Bypass", false, function(v) Flags.ShopTierBypass = v end)

-- ═══ 9. Buy Delay ═══
page:Slider("Buy Delay", 100, 2000, 500, function(v) Flags.BuyDelay = v end)

-- ═══ 10. Auto Team Upgrade ═══

-- ═══ 11. Auto Ultimates ═══
page:Toggle("Auto Ultimates", false, function(v) Flags.AutoUltimates = v end)

-- ═══ 12. Auto Armor Upgrade ═══
page:Toggle("Auto Armor Upgrade", false, function(v) Flags.AutoArmorUp = v end)

-- ═══ 13. Auto Sword Upgrade ═══
page:Toggle("Auto Sword Upgrade", false, function(v) Flags.AutoSwordUp = v end)

-- ═══ 14. Shop UI Highlight ═══
page:Toggle("Shop Highlight", false, function(v) Flags.ShopHighlight = v end)

-- ═══ 15. Auto Refill ═══
page:Toggle("Auto Refill", false, function(v) Flags.AutoRefill = v end)

-- ═══ Shop Config (Enhanced) ═══
local SHOP = {
    Blocks = {
        {item = "wool_white", cost = 4, res = "iron", tier = 1},
        {item = "wool_light_gray", cost = 4, res = "iron", tier = 1},
        {item = "stone", cost = 12, res = "iron", tier = 2},
        {item = "obsidian", cost = 12, res = "emerald", tier = 3},
        {item = "end_stone", cost = 8, res = "diamond", tier = 3},
    },
    Swords = {
        {item = "wood_sword", cost = 10, res = "iron", tier = 1},
        {item = "stone_sword", cost = 20, res = "iron", tier = 2},
        {item = "iron_sword", cost = 75, res = "iron", tier = 3},
        {item = "diamond_sword", cost = 4, res = "emerald", tier = 4},
        {item = "emerald_sword", cost = 12, res = "emerald", tier = 5},
    },
    Armor = {
        {item = "leather_chestplate", cost = 20, res = "iron", tier = 1},
        {item = "chainmail_chestplate", cost = 40, res = "iron", tier = 2},
        {item = "iron_chestplate", cost = 80, res = "iron", tier = 3},
        {item = "diamond_chestplate", cost = 8, res = "diamond", tier = 4},
    },
    Tools = {
        {item = "wood_axe", cost = 10, res = "iron", tier = 1},
        {item = "stone_axe", cost = 20, res = "iron", tier = 2},
        {item = "iron_pickaxe", cost = 60, res = "iron", tier = 2},
        {item = "diamond_pickaxe", cost = 6, res = "diamond", tier = 3},
    },
    Projectiles = {
        {item = "fireball", cost = 7, res = "iron", tier = 1},
        {item = "snowball", cost = 5, res = "iron", tier = 1},
        {item = "telepearl", cost = 3, res = "diamond", tier = 2},
        {item = "rocket", cost = 8, res = "iron", tier = 3},
    },
    Potions = {
        {item = "speed_potion", cost = 3, res = "emerald", tier = 1},
        {item = "heal_potion", cost = 5, res = "emerald", tier = 2},
        {item = "invisibility_potion", cost = 8, res = "emerald", tier = 3},
    },
    Enchants = {
        {item = "sharpness", cost = 20, res = "emerald", tier = 1},
        {item = "protection", cost = 20, res = "emerald", tier = 1},
    },
}

-- Get resources from game state
local function getResources()
    local res = {iron = 0, gold = 0, diamond = 0, emerald = 0}
    pcall(function()
        local state = BW.getBedwarsState and BW.getBedwarsState()
        if state and state.resources then
            res.iron = state.resources.iron or 0
            res.gold = state.resources.gold or 0
            res.diamond = state.resources.diamond or 0
            res.emerald = state.resources.emerald or 0
        end
    end)
    return res
end

-- Check if player already has this item or better
local function hasBetterItem(category)
    local c = game.Players.LocalPlayer.Character
    if not c then return false end
    for _, tool in pairs(c:GetChildren()) do
        if tool:IsA("Tool") then
            for _, item in pairs(SHOP[category] or {}) do
                if tool.Name == item.item then return true end
            end
        end
    end
    return false
end

-- Buy best item we can afford in category
local function buyBest(category)
    local items = SHOP[category]
    if not items then return end
    local res = getResources()
    for i = #items, 1, -1 do
        local item = items[i]
        local have = res[item.res] or 0
        if have >= item.cost then
            pcall(function()
                if BW.buyItem then BW.buyItem(item.item) end
            end)
            task.wait(0.2)
            return true
        end
    end
    return false
end

-- ═══ Auto Buy Engine (with resource checking) ═══
task.spawn(function()
    while task.wait(0.5) do
        local delay = (Flags.BuyDelay or 500) / 1000
        if Flags.AutoBuyBlocks then buyBest("Blocks") end
        task.wait(delay * 0.2)
        if Flags.AutoBuySword then buyBest("Swords") end
        task.wait(delay * 0.2)
        if Flags.AutoBuyArmor then buyBest("Armor") end
        task.wait(delay * 0.2)
        if Flags.AutoBuyTools then buyBest("Tools") end
        task.wait(delay * 0.2)
        if Flags.AutoBuyProj then buyBest("Projectiles") end
        task.wait(delay * 0.2)
        if Flags.AutoBuyPots then buyBest("Potions") end
        task.wait(delay * 0.2)
        if Flags.AutoBuyEnchant then buyBest("Enchants") end
    end
end)

-- ═══ Auto Upgrade Engine ═══
task.spawn(function()
    while task.wait(2) do
        -- Auto team upgrade
        if Flags.AutoTeamUpgrade then
            pcall(function()
                local Client = require(game.ReplicatedStorage.TS.remotes).default.Client
                Client:GetNamespace("Team"):Get("UpgradeTeam"):SendToServer({})
            end)
        end
        -- Auto sword upgrade (buy best available)
        if Flags.AutoSwordUp then
            buyBest("Swords")
        end
        -- Auto armor upgrade
        if Flags.AutoArmorUp then
            buyBest("Armor")
        end
    end
end)

-- ═══ Auto Refill Engine ═══
task.spawn(function()
    while task.wait(3) do
        if Flags.AutoRefill then
            -- Refill blocks if low
            pcall(function()
                local hasBlocks = false
                local c = game.Players.LocalPlayer.Character
                if c then
                    for _, tool in pairs(c:GetChildren()) do
                        if tool:IsA("Tool") and (tool.Name:find("wool") or tool.Name:find("stone") or tool.Name:find("obsidian")) then
                            hasBlocks = true
                            break
                        end
                    end
                end
                if not hasBlocks then buyBest("Blocks") end
            end)
        end
    end
end)

print("[Shop] Module loaded (15+ features with resource checking)")

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
    while true do pcall(collectgarbage, "collect"); pcall(collectgarbage, "collect"); task.wait(30) end
end)

-- Init
BW.SendWebhook("Script Loaded","BedWars Ultimate v4.4 loaded by **"..BW.LocalPlayer.Name.."**",3447003)
BW.StarterGui:SetCore("SendNotification",{Title="BedWars Ultimate v4.4",Text="PC".." | "..(BW.isMobile and "Touch ready!" or "RightAlt to toggle"),Duration=5})
print("[Events] Module loaded")
print("[BedWars Ultimate v4.4] All modules loaded! Device: ".."PC")
print("Press F3 for performance monitor | RightAlt to toggle UI")

end

-- GAME
local function load_game(bw, flags, ui, api)
--!nocheck
-- ═══════════════════════════════════════════════════════════════
-- BEDWARS GAME MODULE v5.1 — Real API Features from Dump
-- Kit System, Resources, Shop, Inventory, Abilities
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local lplr = Players.LocalPlayer

local page = BW.Win:Tab("Game")
if not page or not page.Toggle then warn("[Game] Failed to create tab!") return end

-- ═══ 1. Kit System ═══
page:Toggle("Auto Select Kit", false, function(v) Flags.AutoSelectKit = v end)
page:Toggle("Kit Locker", false, function(v) Flags.KitLocker = v end)

-- Known kits from dump
local KITS = {
    "sword_shield", "axolotl", "angel", "barbarian", "blood_assassin",
    "bounty_hunter", "cactus", "can_of_beans", "captain_pirate",
    "crab_dance", "dragon", "elk", "ember", "frosty_gun",
    "grim_reaper", "gun_blade", "hannah", "hunter", "ice_queen",
    "jade", "juggernaut", "laser_sword", "lich", "lumberjack",
    "magnet", "mimic_block", "necromancer", "ninja", "paladin",
    "piggy", "pirate", "raven", "reaper_scythe", "scythe",
    "seahorse", "shield", "sigrid", "sky_scythe", "snake_shrine",
    "sorcerer", "spirit_assassin", "spirit_summoner", "star_caller",
    "steve", "summoner", "tinker", "turtle", "umbra",
    "void_axe", "void_hunter", "void_walker", "warlock", "warrior",
    "wind_walker", "wizard", "yeti", "yuzi"
}

page:Dropdown({Name="Select Kit", Flag="SelectedKit", Options=KITS, Default="sword_shield"})

-- ═══ 2. Resource Tracking ═══
page:Toggle("Resource HUD", false, function(v) Flags.ResourceHUD = v end)
page:Toggle("Auto Buy Best", false, function(v) Flags.AutoBuyBest = v end)

-- Resource tracking engine
task.spawn(function()
    while true do
        if Flags.ResourceHUD and BW.alive() then
            pcall(function()
                local res = BW.api and BW.api.getResources and BW.api.getResources() or {}
                local myTeam = BW.api and BW.api.getTeam and BW.api.getTeam() or ""
                -- Update display if we have a HUD
            end)
        end
        task.wait(1)
    end
end)

-- ═══ 3. Team Upgrades ═══
page:Toggle("Auto Team Upgrade", false, function(v) Flags.AutoTeamUpgrade = v end)
page:Toggle("Auto Upgrade Armor", false, function(v) Flags.AutoUpgradeArmor = v end)
page:Toggle("Auto Upgrade Sword", false, function(v) Flags.AutoUpgradeSword = v end)

-- ═══ 4. Shop System ═══
page:Toggle("Smart Auto Buy", false, function(v) Flags.SmartAutoBuy = v end)
page:Slider("Buy Interval", 1, 10, 3, function(v) Flags.BuyInterval = v end)
page:Toggle("Buy Priority Sword", true, function(v) Flags.BuySword = v end)
page:Toggle("Buy Priority Armor", true, function(v) Flags.BuyArmor = v end)
page:Toggle("Buy Priority Blocks", true, function(v) Flags.BuyBlocks = v end)
page:Toggle("Buy Priority Pickaxe", false, function(v) Flags.BuyPickaxe = v end)
page:Toggle("Buy Priority Projectiles", false, function(v) Flags.BuyProjectiles = v end)

-- ═══ 5. Inventory System ═══
page:Toggle("Auto Sort Inventory", false, function(v) Flags.AutoSortInv = v end)
page:Toggle("Auto Consume", false, function(v) Flags.AutoConsume = v end)
page:Toggle("Auto Pickup", false, function(v) Flags.AutoPickup = v end)

-- Auto Pickup Engine (uses real remote)
task.spawn(function()
    while true do
        if Flags.AutoPickup and BW.alive() then
            pcall(function()
                local myHrp = BW.hrp()
                if myHrp then
                    local drops = BW.api and BW.api.getItemDrops and BW.api.getItemDrops() or {}
                    for _, drop in pairs(drops) do
                        if drop:IsA("BasePart") then
                            local dist = (myHrp.Position - drop.Position).Magnitude
                            if dist < 5 then
                                -- Use real remote
                                if BW.api and BW.api.pickupItemDrop then
                                    BW.api.pickupItemDrop({itemDrop = drop})
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- ═══ 6. Block System ═══
page:Toggle("Auto Fortify", false, function(v) Flags.AutoFortify = v end)
page:Slider("Fortify Delay", 100, 1000, 300, function(v) Flags.FortifyDelay = v end)

-- Auto Fortify Engine
task.spawn(function()
    while true do
        if Flags.AutoFortify and BW.alive() then
            pcall(function()
                if BW.api and BW.api.fortifyBlock then
                    BW.api.fortifyBlock({})
                end
            end)
        end
        task.wait((Flags.FortifyDelay or 300) / 1000)
    end
end)

-- ═══ 7. Kit Abilities ═══
page:Toggle("Adetunde Auto Upgrade", false, function(v) Flags.AdetundeAuto = v end)
page:Dropdown({Name="Adetunde Priority", Flag="AdetundePriority", Options={"shield", "speed", "strength"}, Default="shield"})
page:Toggle("Ember Auto Saber", false, function(v) Flags.EmberAuto = v end)
page:Toggle("Sky Scythe Auto", false, function(v) Flags.SkyScytheAuto = v end)
page:Toggle("Void Hunter Auto Mark", false, function(v) Flags.VoidHunterAuto = v end)

-- Adetunde Auto Upgrade Engine
task.spawn(function()
    while true do
        if Flags.AdetundeAuto and BW.alive() then
            pcall(function()
                local priority = Flags.AdetundePriority or "shield"
                if BW.api and BW.api.upgradeAdetunde then
                    BW.api.upgradeAdetunde(priority)
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- Ember Auto Saber Engine
task.spawn(function()
    while true do
        if Flags.EmberAuto and BW.alive() then
            pcall(function()
                if BW.api and BW.api.hasItem and BW.api.hasItem("infernal_saber") then
                    if BW.api.useEmberSaber then
                        BW.api.useEmberSaber({
                            weapon = "infernal_saber",
                            player = lplr,
                            chargeTime = 0.9
                        })
                    end
                end
            end)
        end
        task.wait(0.2)
    end
end)

-- Sky Scythe Auto Engine
task.spawn(function()
    while true do
        if Flags.SkyScytheAuto and BW.alive() then
            pcall(function()
                if BW.api and BW.api.useSkyScythe then
                    BW.api.useSkyScythe()
                end
            end)
        end
        task.wait(0.2)
    end
end)

-- Void Hunter Auto Mark Engine
task.spawn(function()
    while true do
        if Flags.VoidHunterAuto and BW.alive() then
            pcall(function()
                local target, dist = BW.nearestEnemy(20)
                if target then
                    local dir = (target.HRP.Position - BW.hrp().Position).Unit
                    if BW.api and BW.api.useVoidHunterMark then
                        BW.api.useVoidHunterMark({direction = dir})
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- ═══ 8. Match Info ═══
page:Toggle("Kill Tracker", false, function(v) Flags.KillTracker = v end)
page:Toggle("Bed Break Tracker", false, function(v) Flags.BedTracker = v end)
page:Toggle("Match Stats", false, function(v) Flags.MatchStats = v end)

-- ═══ 9. Device Spoof ═══
page:Toggle("Device Spoof", false, function(v) Flags.DeviceSpoof = v end)
page:Dropdown({Name="Spoof Device", Flag="SpoofDevice", Options={"MOBILE", "PC", "GAMEPAD"}, Default="PC"})

-- Device Spoof Engine
task.spawn(function()
    while true do
        if Flags.DeviceSpoof then
            pcall(function()
                local device = Flags.SpoofDevice or "PC"
                if BW.api and BW.api.sendUserInputType then
                    BW.api.sendUserInputType(device)
                end
            end)
        end
        task.wait(5)
    end
end)

-- ═══ 10. Auto Crop Harvest ═══
page:Toggle("Auto Harvest", false, function(v) Flags.AutoHarvest = v end)

-- ═══ 11. Wool Get ═══
page:Toggle("Auto Get Wool", false, function(v) Flags.AutoGetWool = v end)
page:Slider("Wool Amount", 1, 64, 32, function(v) Flags.WoolAmount = v end)

-- Auto Wool Engine
task.spawn(function()
    while true do
        if Flags.AutoGetWool and BW.alive() then
            pcall(function()
                if BW.api and BW.api.getWool then
                    BW.api.getWool({amount = Flags.WoolAmount or 32})
                end
            end)
        end
        task.wait(2)
    end
end)

-- ═══ 12. Sprint Control ═══
page:Toggle("Smart Sprint", false, function(v) Flags.SmartSprint = v end)

-- Smart Sprint Engine (auto sprint, auto stop when not moving)
task.spawn(function()
    local wasSprinting = false
    while true do
        if Flags.SmartSprint and BW.alive() then
            local h = BW.hum()
            local my = BW.hrp()
            if h and my then
                local isMoving = my.Velocity.Magnitude > 1
                if isMoving and not wasSprinting then
                    if BW.api and BW.api.startSprint then
                        BW.api.startSprint()
                    end
                    wasSprinting = true
                elseif not isMoving and wasSprinting then
                    if BW.api and BW.api.stopSprint then
                        BW.api.stopSprint()
                    end
                    wasSprinting = false
                end
            end
        else
            wasSprinting = false
        end
        task.wait(0.2)
    end
end)

-- ═══ 13. Smart Combat (uses real SwordHit remote) ═══
page:Toggle("Smart Sword Hit", false, function(v) Flags.SmartSwordHit = v end)

-- ═══ 14. Auto Projectile (uses real ProjectileFire remote) ═══
page:Toggle("Smart Projectile", false, function(v) Flags.SmartProjectile = v end)
page:Slider("Proj Lead", 0, 100, 30, function(v) Flags.ProjLead = v end)

-- Smart Projectile Engine
task.spawn(function()
    while true do
        if Flags.SmartProjectile and BW.alive() then
            pcall(function()
                local target, dist = BW.nearestEnemy(50)
                if target and dist then
                    local myHrp = BW.hrp()
                    if myHrp then
                        -- Predict target position
                        local vel = target.HRP.AssemblyLinearVelocity
                        local lead = (Flags.ProjLead or 30) / 100
                        local predictPos = target.HRP.Position + vel * (dist * lead / 100)
                        local dir = (predictPos - myHrp.Position).Unit
                        if BW.api and BW.api.projectileFire then
                            BW.api.projectileFire({
                                position = myHrp.Position,
                                direction = dir,
                                chargeTime = 0.5
                            })
                        end
                    end
                end
            end)
        end
        task.wait(0.3)
    end
end)

-- ═══ 15. Smart Ability (uses real UseAbility remote) ═══
page:Toggle("Auto Use Ability", false, function(v) Flags.AutoUseAbility = v end)

-- ═══ 16. Auto Bed Break (uses real BedwarsBedBreak remote) ═══
page:Toggle("Smart Bed Break", false, function(v) Flags.SmartBedBreak = v end)

-- Smart Bed Break Engine
task.spawn(function()
    while true do
        if Flags.SmartBedBreak and BW.alive() then
            pcall(function()
                local enemyBeds = BW.api and BW.api.getEnemyBeds and BW.api.getEnemyBeds() or {}
                for _, bed in pairs(enemyBeds) do
                    local bedPart = bed.PrimaryPart or bed:FindFirstChildWhichIsA("BasePart")
                    if bedPart then
                        local myHrp = BW.hrp()
                        if myHrp then
                            local dist = (myHrp.Position - bedPart.Position).Magnitude
                            if dist < 5 then
                                if BW.api and BW.api.bedBreak then
                                    BW.api.bedBreak({bed = bed})
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

print("[Game] Module loaded (16 features)")

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
    bw.Win = ui
    BW = bw  -- Make global BW available to all modules
    -- Performance cache
    local perf = load_perf(bw, flags, ui, api)
    bw.Perf = perf
    BW.Perf = perf

    local moduleList = {'perf', 'combat', 'world', 'esp', 'move', 'shop', 'util', 'legit', 'autoload', 'events'}
    for _, name in pairs(moduleList) do
        local success, err = pcall(function()
            if name == 'perf' then load_perf(bw, flags, ui, api)
            elseif name == 'combat' then load_combat(bw, flags, ui, api)
            elseif name == 'world' then load_world(bw, flags, ui, api)
            elseif name == 'esp' then load_esp(bw, flags, ui, api)
            elseif name == 'move' then load_move(bw, flags, ui, api)
            elseif name == 'shop' then load_shop(bw, flags, ui, api)
            elseif name == 'util' then load_util(bw, flags, ui, api)
            elseif name == 'legit' then load_legit(bw, flags, ui, api)
            elseif name == 'autoload' then load_autoload(bw, flags, ui, api)
            elseif name == 'events' then load_events(bw, flags, ui, api)
            elseif name == 'game' then load_game(bw, flags, ui, api)
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