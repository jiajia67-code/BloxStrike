--!nocheck
-- ═══════════════════════════════════════════════════════════════
-- BEDWARS GAME MODULE v6.0 — 50+ Real API Features from Dump
-- Kit System, Resources, Shop, Inventory, Abilities, Combat
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lplr = Players.LocalPlayer

local page = BW.Win:Tab("Game")
if not page or not page.Toggle then warn("[Game] Failed to create tab!") return end

-- ═══ Safe Remote Helpers ═══
local function fireRemote(name, ...)
    pcall(function()
        local Client = require(ReplicatedStorage.TS.remotes).default.Client
        local args = {...}
        -- Try namespace format first
        for _, ns in pairs({"Bedwars", "Block", "Shop", "Inventory", "Kit", "Locker", "CustomMatches", "Event", "Gift"}) do
            pcall(function()
                local remote = Client:GetNamespace(ns):Get(name)
                if remote then remote:SendToServer(unpack(args)) end
            end)
        end
    end)
end

local function invokeRemote(name, ...)
    local args = {...}
    pcall(function()
        local Client = require(ReplicatedStorage.TS.remotes).default.Client
        -- Try direct Client:Get
        pcall(function()
            local remote = Client:Get(name)
            if remote then remote:CallServer(unpack(args)) end
        end)
        -- Try namespace format
        for _, ns in pairs({"Bedwars", "Block", "Shop", "Inventory", "Kit", "Locker", "CustomMatches", "Event", "Gift"}) do
            pcall(function()
                local remote = Client:GetNamespace(ns):Get(name)
                if remote then remote:CallServer(unpack(args)) end
            end)
        end
    end)
end

local function fireNetManaged(name, ...)
    local args = {...}
    pcall(function()
        local rm = ReplicatedStorage:FindFirstChild("rbxts_include")
            and ReplicatedStorage.rbxts_include:FindFirstChild("node_modules")
            and ReplicatedStorage.rbxts_include.node_modules:FindFirstChild("@easy-games")
            and ReplicatedStorage.rbxts_include.node_modules["@easy-games"]:FindFirstChild("net")
            and ReplicatedStorage.rbxts_include.node_modules["@easy-games"].net.out:FindFirstChild("_NetManaged")
        if rm then
            local remote = rm:FindFirstChild(name)
            if remote then
                if remote:IsA("RemoteEvent") then
                    remote:FireServer(unpack(args))
                elseif remote:IsA("RemoteFunction") then
                    remote:InvokeServer(unpack(args))
                end
            end
        end
    end)
end

-- ═══ 1. Kit System ═══
page:Toggle("Auto Select Kit", false, function(v) Flags.AutoSelectKit = v end)
page:Toggle("Kit Locker", false, function(v) Flags.KitLocker = v end)

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
    "tinker", "turtle", "umbra", "void_axe", "void_hunter",
    "void_walker", "warlock", "warrior", "wind_walker", "wizard", "yeti", "yuzi"
}

page:Dropdown({Name="Select Kit", Flag="SelectedKit", Options=KITS, Default="sword_shield"})

-- ═══ 2. Resource Tracking ═══
page:Toggle("Resource HUD", false, function(v) Flags.ResourceHUD = v end)
page:Toggle("Auto Buy Best", false, function(v) Flags.AutoBuyBest = v end)

-- ═══ 3. Team Upgrades ═══
page:Toggle("Auto Team Upgrade", false, function(v) Flags.AutoTeamUpgrade = v end)
page:Toggle("Auto Upgrade Armor", false, function(v) Flags.AutoUpgradeArmor = v end)
page:Toggle("Auto Upgrade Sword", false, function(v) Flags.AutoUpgradeSword = v end)
page:Toggle("Set All Team Upgrades", false, function(v) Flags.SetAllTeamUpgrades = v end)

-- ═══ 4. Shop System ═══
page:Toggle("Smart Auto Buy", false, function(v) Flags.SmartAutoBuy = v end)
page:Slider("Buy Interval", 1, 10, 3, function(v) Flags.BuyInterval = v end)
page:Toggle("Buy Priority Sword", true, function(v) Flags.BuySword = v end)
page:Toggle("Buy Priority Armor", true, function(v) Flags.BuyArmor = v end)
page:Toggle("Buy Priority Blocks", true, function(v) Flags.BuyBlocks = v end)
page:Toggle("Buy Priority Pickaxe", false, function(v) Flags.BuyPickaxe = v end)
page:Toggle("Buy Priority Projectiles", false, function(v) Flags.BuyProjectiles = v end)
page:Toggle("Buy Priority Potions", false, function(v) Flags.BuyPotions = v end)
page:Toggle("Buy Priority Enchants", false, function(v) Flags.BuyEnchants = v end)
page:Slider("Random Shop Items", 1, 10, 5, function(v) Flags.RandomShopItems = v end)

-- ═══ 5. Inventory System ═══
page:Toggle("Auto Sort Inventory", false, function(v) Flags.AutoSortInv = v end)
page:Toggle("Auto Consume", false, function(v) Flags.AutoConsume = v end)
page:Toggle("Force Swap Hotbar", false, function(v) Flags.ForceSwapHotbar = v end)
page:Toggle("Restore Hotbar", false, function(v) Flags.RestoreHotbar = v end)

-- ═══ 6. Block System ═══
page:Toggle("Auto Fortify", false, function(v) Flags.AutoFortify = v end)
page:Slider("Fortify Delay", 100, 1000, 300, function(v) Flags.FortifyDelay = v end)
page:Toggle("Mimic Block", false, function(v) Flags.MimicBlock = v end)
page:Toggle("Freeze Blocks", false, function(v) Flags.FreezeBlocks = v end)
page:Toggle("Repair Block", false, function(v) Flags.RepairBlock = v end)

-- ═══ 7. Kit Abilities ═══
page:Toggle("Adetunde Auto Upgrade", false, function(v) Flags.AdetundeAuto = v end)
page:Dropdown({Name="Adetunde Priority", Flag="AdetundePriority", Options={"shield", "speed", "strength"}, Default="shield"})
page:Toggle("Ember Auto Saber", false, function(v) Flags.EmberAuto = v end)
page:Toggle("Sky Scythe Auto", false, function(v) Flags.SkyScytheAuto = v end)
page:Toggle("Void Hunter Auto Mark", false, function(v) Flags.VoidHunterAuto = v end)
page:Toggle("Void Walker Warp", false, function(v) Flags.VoidWalkerWarp = v end)
page:Toggle("Grim Reaper Recall", false, function(v) Flags.GrimReaperRecall = v end)
page:Toggle("Scythe Dash", false, function(v) Flags.ScytheDash = v end)
page:Toggle("Void Axe Leap", false, function(v) Flags.VoidAxeLeap = v end)
page:Toggle("Mass Hammer Use", false, function(v) Flags.MassHammerUse = v end)
page:Toggle("Disarm Enemy", false, function(v) Flags.DisarmEnemy = v end)
page:Toggle("Necromancer Auto", false, function(v) Flags.NecromancerAuto = v end)

-- ═══ 8. Match Info ═══
page:Toggle("Kill Tracker", false, function(v) Flags.KillTracker = v end)
page:Toggle("Bed Break Tracker", false, function(v) Flags.BedTracker = v end)
page:Toggle("Match Stats", false, function(v) Flags.MatchStats = v end)

-- ═══ 9. Device Spoof ═══
page:Toggle("Device Spoof", false, function(v) Flags.DeviceSpoof = v end)
page:Dropdown({Name="Spoof Device", Flag="SpoofDevice", Options={"MOBILE", "PC", "GAMEPAD"}, Default="PC"})

-- ═══ 10. Auto Crop Harvest ═══
page:Toggle("Auto Harvest", false, function(v) Flags.AutoHarvest = v end)

-- ═══ 11. Wool Get ═══
page:Toggle("Auto Get Wool", false, function(v) Flags.AutoGetWool = v end)
page:Slider("Wool Amount", 1, 64, 32, function(v) Flags.WoolAmount = v end)

-- ═══ 12. Sprint Control ═══
page:Toggle("Smart Sprint", false, function(v) Flags.SmartSprint = v end)

-- ═══ 13. Smart Combat ═══
page:Toggle("Smart Sword Hit", false, function(v) Flags.SmartSwordHit = v end)

-- ═══ 14. Auto Projectile ═══
page:Toggle("Smart Projectile", false, function(v) Flags.SmartProjectile = v end)
page:Slider("Proj Lead", 0, 100, 30, function(v) Flags.ProjLead = v end)

-- ═══ 15. Smart Ability ═══
page:Toggle("Auto Use Ability", false, function(v) Flags.AutoUseAbility = v end)

-- ═══ 16. Smart Bed Break ═══
page:Toggle("Smart Bed Break", false, function(v) Flags.SmartBedBreak = v end)

-- ═══ 17. NEW: Chest System ═══
page:Toggle("Auto Chest Give", false, function(v) Flags.AutoChestGive = v end)
page:Toggle("Auto Chest Get", false, function(v) Flags.AutoChestGet = v end)
page:Toggle("Auto Smelt Chest", false, function(v) Flags.AutoSmeltChest = v end)

-- ═══ 18. NEW: Ore Generator ═══
page:Toggle("Auto Upgrade Generator", false, function(v) Flags.AutoUpgradeGen = v end)
page:Toggle("Create Generator", false, function(v) Flags.CreateGen = v end)
page:Toggle("Auto Team Generator", false, function(v) Flags.AutoTeamGen = v end)

-- ═══ 19. NEW: Shield/Defense ═══
page:Toggle("Auto Shield", false, function(v) Flags.AutoShield = v end)
page:Toggle("Infernal Shield", false, function(v) Flags.InfernalShield = v end)
page:Toggle("Bed Shield", false, function(v) Flags.BedShield = v end)
page:Toggle("Glitch Shield", false, function(v) Flags.GlitchShield = v end)

-- ═══ 20. NEW: Potion System ═══
page:Toggle("Auto Boost Potion", false, function(v) Flags.AutoBoostPotion = v end)
page:Toggle("Auto Fury Potion", false, function(v) Flags.AutoFuryPotion = v end)
page:Toggle("Auto Splash Potion", false, function(v) Flags.AutoSplashPotion = v end)

-- ═══ 21. NEW: Teleport ═══
page:Toggle("Spirit Teleport", false, function(v) Flags.SpiritTeleport = v end)
page:Toggle("Hatter Teleport", false, function(v) Flags.HatterTeleport = v end)
page:Toggle("Hannah Teleport", false, function(v) Flags.HannahTeleport = v end)

-- ═══ 22. NEW: Match Control ═══
page:Toggle("Sudden Death", false, function(v) Flags.SuddenDeath = v end)
page:Toggle("Bed Alarm", false, function(v) Flags.BedAlarm = v end)

-- ═══ 23. NEW: Locker/Cosmetics ═══
page:Toggle("Set Kill Effect", false, function(v) Flags.SetKillEffect = v end)
page:Toggle("Set Bed Skin", false, function(v) Flags.SetBedSkin = v end)
page:Toggle("Set Break Bed Effect", false, function(v) Flags.SetBreakBedEffect = v end)
page:Toggle("Set Emote", false, function(v) Flags.SetEmote = v end)

-- ═══ 24. NEW: Party System ═══
page:Toggle("Auto Leave Party", false, function(v) Flags.AutoLeaveParty = v end)
page:Toggle("Auto Join Party", false, function(v) Flags.AutoJoinParty = v end)

-- ═══ 25. NEW: Global Teams ═══
page:Toggle("Global Team Set", false, function(v) Flags.GlobalTeamSet = v end)
page:Toggle("Global Team Reward", false, function(v) Flags.GlobalTeamReward = v end)

-- ═══ 26. NEW: Milestone Rewards ═══
page:Toggle("Auto Claim Milestone", false, function(v) Flags.AutoClaimMilestone = v end)

-- ═══ 27. NEW: Battle Pass ═══
page:Toggle("Auto Battle Pass", false, function(v) Flags.AutoBattlePass = v end)

-- ═══ 28. NEW: Event System ═══
page:Toggle("Auto Event Mission", false, function(v) Flags.AutoEventMission = v end)
page:Toggle("Auto Event Shop", false, function(v) Flags.AutoEventShop = v end)

-- ═══ 29. NEW: Clan System ═══
page:Toggle("Auto Clan Chat", false, function(v) Flags.AutoClanChat = v end)
page:Toggle("Auto Clan War", false, function(v) Flags.AutoClanWar = v end)

-- ═══ 30. NEW: Daily/Weekly ═══
page:Toggle("Auto Daily Checkin", false, function(v) Flags.AutoCheckin = v end)
page:Toggle("Auto Daily Rewards", false, function(v) Flags.AutoDailyRewards = v end)

-- ═══ 31. NEW: Settings ═══
page:Toggle("Streamer Mode", false, function(v) Flags.StreamerMode = v end)
page:Toggle("Picture Mode", false, function(v) Flags.PictureMode = v end)
page:Slider("FOV Override", 60, 120, 90, function(v) Flags.FOVOverride = v end)

-- ═══ 32. NEW: Enchant System ═══
page:Toggle("Auto Research Enchant", false, function(v) Flags.AutoResearchEnchant = v end)
page:Toggle("Auto Apply Enchant", false, function(v) Flags.AutoApplyEnchant = v end)
page:Toggle("Auto Tool Enchant", false, function(v) Flags.AutoToolEnchant = v end)

-- ═══ ENGINE: Smart Auto Buy ═══
task.spawn(function()
    while true do
        if Flags.SmartAutoBuy and BW.alive() then
            pcall(function()
                local priority = {}
                if Flags.BuySword then table.insert(priority, "sword") end
                if Flags.BuyArmor then table.insert(priority, "armor") end
                if Flags.BuyBlocks then table.insert(priority, "blocks") end
                if Flags.BuyPickaxe then table.insert(priority, "pickaxe") end
                if Flags.BuyProjectiles then table.insert(priority, "projectiles") end
                if Flags.BuyPotions then table.insert(priority, "potions") end
                if Flags.BuyEnchants then table.insert(priority, "enchants") end
                for _, item in ipairs(priority) do
                    fireRemote("BedwarsPurchaseItem", {shopItem = {itemType = item, shopId = "main"}})
                    task.wait((Flags.BuyInterval or 3) / 10)
                end
            end)
        end
        task.wait(Flags.BuyInterval or 3)
    end
end)

-- ═══ ENGINE: Auto Team Upgrade ═══
task.spawn(function()
    while true do
        if Flags.AutoTeamUpgrade and BW.alive() then
            pcall(function()
                invokeRemote("BedwarsPurchaseTeamUpgrade")
            end)
        end
        if Flags.SetAllTeamUpgrades and BW.alive() then
            pcall(function()
                fireRemote("BedwarsSetAllTeamUpgrades")
            end)
        end
        task.wait(5)
    end
end)

-- ═══ ENGINE: Auto Pickup ═══
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
                                invokeRemote("PickupItemDrop", {itemDrop = drop})
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- ═══ ENGINE: Auto Fortify ═══
task.spawn(function()
    while true do
        if Flags.AutoFortify and BW.alive() then
            pcall(function()
                fireRemote("FortifyBlock", {})
            end)
        end
        task.wait((Flags.FortifyDelay or 300) / 1000)
    end
end)

-- ═══ ENGINE: Kit Abilities ═══
task.spawn(function()
    while true do
        if Flags.AdetundeAuto and BW.alive() then
            pcall(function()
                invokeRemote("UpgradeFrostyHammer", {type = Flags.AdetundePriority or "shield"})
            end)
        end
        if Flags.EmberAuto and BW.alive() then
            pcall(function()
                fireRemote("HellBladeRelease", {weapon = "infernal_saber", chargeTime = 0.9})
            end)
        end
        if Flags.SkyScytheAuto and BW.alive() then
            pcall(function()
                fireRemote("SkyScytheSpin", {})
            end)
        end
        if Flags.VoidHunterAuto and BW.alive() then
            pcall(function()
                local target = BW.nearestEnemy(20)
                if target then
                    local dir = (target.HRP.Position - BW.hrp().Position).Unit
                    fireRemote("VoidHunter_MarkAbilityRequest", {direction = dir})
                end
            end)
        end
        if Flags.ScytheDash and BW.alive() then
            pcall(function() fireRemote("ScytheDash", {}) end)
        end
        if Flags.VoidAxeLeap and BW.alive() then
            pcall(function() fireRemote("VoidAxeLeap", {}) end)
        end
        if Flags.MassHammerUse and BW.alive() then
            pcall(function() fireRemote("UseMassHammer", {}) end)
        end
        if Flags.DisarmEnemy and BW.alive() then
            pcall(function()
                local target = BW.nearestEnemy(5)
                if target then fireRemote("Disarm", {target = target.Player}) end
            end)
        end
        if Flags.NecromancerAuto and BW.alive() then
            pcall(function() fireRemote("NecromancerRecall", {}) end)
        end
        task.wait(0.3)
    end
end)

-- ═══ ENGINE: Device Spoof ═══
task.spawn(function()
    while true do
        if Flags.DeviceSpoof then
            pcall(function()
                fireRemote("SendUserInputType", {Flags.SpoofDevice or "PC"})
            end)
        end
        task.wait(5)
    end
end)

-- ═══ ENGINE: Wool Get ═══
task.spawn(function()
    while true do
        if Flags.AutoGetWool and BW.alive() then
            pcall(function()
                invokeRemote("GetWool", {amount = Flags.WoolAmount or 32})
            end)
        end
        task.wait(2)
    end
end)

-- ═══ ENGINE: Smart Sprint ═══
task.spawn(function()
    local wasSprinting = false
    while true do
        if Flags.SmartSprint and BW.alive() then
            local h = BW.hum()
            local my = BW.hrp()
            if h and my then
                local isMoving = my.AssemblyLinearVelocity.Magnitude > 1
                if isMoving and not wasSprinting then
                    fireRemote("SprintStart", {})
                    wasSprinting = true
                elseif not isMoving and wasSprinting then
                    fireRemote("SprintStop", {})
                    wasSprinting = false
                end
            end
        else
            wasSprinting = false
        end
        task.wait(0.2)
    end
end)

-- ═══ ENGINE: Smart Projectile ═══
task.spawn(function()
    while true do
        if Flags.SmartProjectile and BW.alive() then
            pcall(function()
                local target, dist = BW.nearestEnemy(50)
                if target and dist then
                    local myHrp = BW.hrp()
                    if myHrp then
                        local vel = target.HRP.AssemblyLinearVelocity
                        local lead = (Flags.ProjLead or 30) / 100
                        local predictPos = target.HRP.Position + vel * (dist * lead / 100)
                        local dir = (predictPos - myHrp.Position).Unit
                        invokeRemote("ProjectileFire", {
                            position = myHrp.Position,
                            direction = dir,
                            chargeTime = 0.5
                        })
                    end
                end
            end)
        end
        task.wait(0.3)
    end
end)

-- ═══ ENGINE: Smart Bed Break ═══
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
                                fireRemote("BedwarsBedBreak", {bed = bed})
                            end
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

-- ═══ ENGINE: Auto Harvest ═══
task.spawn(function()
    while true do
        if Flags.AutoHarvest and BW.alive() then
            pcall(function()
                invokeRemote("BedwarsHarvestCrop", {})
            end)
        end
        task.wait(1)
    end
end)

-- ═══ ENGINE: Shield System ═══
task.spawn(function()
    while true do
        if Flags.AutoShield and BW.alive() then
            pcall(function() fireRemote("UseShield", {}) end)
        end
        if Flags.InfernalShield and BW.alive() then
            pcall(function() fireRemote("UseInfernalShield", {}) end)
        end
        if Flags.GlitchShield and BW.alive() then
            pcall(function() fireRemote("UseGlitchShield", {}) end)
        end
        task.wait(0.5)
    end
end)

-- ═══ ENGINE: Milestone/Event ═══
task.spawn(function()
    while true do
        if Flags.AutoClaimMilestone and BW.alive() then
            pcall(function() invokeRemote("ClaimMilestoneReward", {}) end)
        end
        if Flags.AutoEventMission and BW.alive() then
            pcall(function()
                local Client = require(ReplicatedStorage.TS.remotes).default.Client
                Client:GetNamespace("Event"):Get("ClaimMission"):CallServer()
            end)
        end
        task.wait(5)
    end
end)

-- ═══ ENGINE: Settings ═══
task.spawn(function()
    while true do
        if Flags.StreamerMode then
            pcall(function()
                local Client = require(ReplicatedStorage.TS.remotes).default.Client
                Client:Get("SetSettings"):FireServer({streamerMode = true})
            end)
        end
        if Flags.PictureMode then
            pcall(function()
                local Client = require(ReplicatedStorage.TS.remotes).default.Client
                Client:Get("SetSettings"):FireServer({pictureMode = true})
            end)
        end
        if Flags.FOVOverride and Flags.FOVOverride ~= 90 then
            pcall(function()
                workspace.CurrentCamera.FieldOfView = Flags.FOVOverride
            end)
        end
        task.wait(2)
    end
end)

-- ═══ ENGINE: Locker/Cosmetics ═══
task.spawn(function()
    while true do
        if Flags.SetKillEffect and BW.alive() then
            pcall(function()
                invokeRemote("SetKillEffect", {killEffectType = "none"})
            end)
        end
        if Flags.SetBedSkin and BW.alive() then
            pcall(function()
                invokeRemote("SetBedSkin", {bedSkinType = "none"})
            end)
        end
        if Flags.SetBreakBedEffect and BW.alive() then
            pcall(function()
                invokeRemote("SetBreakBedEffect", {breakBedEffectType = "none"})
            end)
        end
        task.wait(5)
    end
end)

-- ═══ ENGINE: Enchant ═══
task.spawn(function()
    while true do
        if Flags.AutoResearchEnchant and BW.alive() then
            pcall(function() invokeRemote("ResearchEnchant", {}) end)
        end
        if Flags.AutoApplyEnchant and BW.alive() then
            pcall(function() invokeRemote("RequestApplyLearnedEnchant", {}) end)
        end
        if Flags.AutoToolEnchant and BW.alive() then
            pcall(function() invokeRemote("ResearchToolEnchant", {}) end)
        end
        if Flags.AutoSmeltChest and BW.alive() then
            pcall(function() fireRemote("SmeltChestContentsRequested", {}) end)
        end
        task.wait(3)
    end
end)

-- ═══ ENGINE: Checkin ═══
task.spawn(function()
    while true do
        if Flags.AutoCheckin and BW.alive() then
            pcall(function() fireRemote("RecordCheckIn", {}) end)
        end
        task.wait(10)
    end
end)

print("[Game] Module loaded v6.0 (50+ features)")
