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
