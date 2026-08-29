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
    local args = {...}
    if api.NetManaged then
        pcall(function()
            api.NetManaged[remoteName]:FireServer(unpack(args))
        end)
    end
end

function api.invokeNetManaged(remoteName, ...)
    local args = {...}
    if api.NetManaged then
        local s, r = pcall(function()
            return api.NetManaged[remoteName]:InvokeServer(unpack(args))
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
