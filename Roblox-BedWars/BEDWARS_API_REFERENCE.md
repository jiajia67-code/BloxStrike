# BedWars Complete API Reference (Roblox)
# Based on VapeV4, CatVape source code + dump script analysis
# Last updated: 2026-08-27

## ═══ 1. How to Connect to BedWars ═══

```lua
-- 1. Get Knit Framework
local KnitInit, Knit = pcall(function()
    return debug.getupvalue(require(lplr.PlayerScripts.TS.knit).setup, 9)
end)
repeat task.wait() until debug.getupvalue(Knit.Start, 1)

-- 2. Get Client Remotes
local Client = require(replicatedStorage.TS.remotes).default.Client

-- 3. Get Store (Redux state)
local Store = require(lplr.PlayerScripts.TS.ui.store).ClientStore

-- 4. Create bedwars table (auto-loads controllers)
local bedwars = setmetatable({Client = Client, Store = Store}, {
    __index = function(self, ind)
        rawset(self, ind, Knit.Controllers[ind])
        return rawget(self, ind)
    end
})
```

## ═══ 2. All Known Controllers ═══

### Combat Controllers:
| Controller | Methods | Description |
|-----------|---------|-------------|
| **SprintController** | `:startSprinting()`, `:stopSprinting()` | Sprint management |
| **DamageIndicatorController** | (visual damage numbers) | Damage indicators |
| **HitEffectController** | (hit effects) | Hit visual effects |

### World Controllers:
| Controller | Methods | Description |
|-----------|---------|-------------|
| **BlockController** | `:placeBlock(type, pos, normal)`, `:getBlockAt(pos)` | Block placement |
| **PickaxeController** | `:equipPickaxe()` | Equip pickaxe |
| **CrateAltarController** | `:pickCrate(consumable, slot)`, `.activeCrates` | Crate system |

### Shop/Inventory Controllers:
| Controller | Methods | Description |
|-----------|---------|-------------|
| **ShopController** | `:purchaseItem(itemType, shopId)` | Shop purchases |
| **BedwarsInventoryController** | `:equipItemInHotbar(slot)` | Inventory management |
| **InventoryController** | (inventory operations) | Item management |

### UI/Input Controllers:
| Controller | Methods | Description |
|-----------|---------|-------------|
| **UserInputController** | `:getUserInputType()` | Device type detection |
| **MilestoneController** | (milestone rewards) | Progression rewards |
| **SeasonPassController** | (season pass) | Season pass |

### Kit Controllers:
| Controller | Methods | Description |
|-----------|---------|-------------|
| **CrateController** | (crate rewards) | Lucky/diamond crates |

## ═══ 3. All Known Remote Namespaces ═══

### Block Remotes:
| Namespace | Remote | Parameters |
|-----------|--------|-----------|
| Block | `PlaceBlock` | `{blockType, position, normal}` |
| Block | `BreakBlock` | `{blockRef}` |

### Damage Remotes:
| Namespace | Remote | Parameters |
|-----------|--------|-----------|
| Damage | `DamagePlayer` | `{player, damage}` |

### Crystal Remotes:
| Namespace | Remote | Parameters |
|-----------|--------|-----------|
| Crystal | `PlaceCrystal` | `{position}` |
| Crystal | `BreakCrystal` | `{crystal}` |

### Shop Remotes:
| Namespace | Remote | Parameters |
|-----------|--------|-----------|
| Shop | `PurchaseItem` | `{shopItem: {itemType, shopId}}` |

### Team Remotes:
| Namespace | Remote | Parameters |
|-----------|--------|-----------|
| Team | `UpgradeTeam` | `{}` |

### Reward/Crate Remotes:
| Namespace | Remote | Parameters |
|-----------|--------|-----------|
| RewardCrate | `OpenRewardCrate` | `{crateId}` |
| RewardCrate | `CrateOpened` | (event listener) |

### Direct Remotes:
| Remote | Parameters |
|--------|-----------|
| `ClaimMilestoneReward` | `{rewardId}` |
| `SendUserInputType` | `{userInputType: "MOBILE"/"PC"/"GAMEPAD"}` |

### _NetManaged Remotes (direct fire):
| Remote | Parameters |
|--------|-----------|
| `UpgradeFrostyHammer` | `{"shield"}` / `{"speed"}` / `{"strength"}` |
| `HellBladeRelease` | `{weapon, player, chargeTime}` |
| `SkyScytheSpin` | `{}` |
| `ProjectileFire` | (projectile params) |
| `VoidHunter_MarkAbilityRequest` | `{direction}` |

## ═══ 4. All CollectionService Tags ═══

```lua
-- Beds
CollectionService:GetTagged("bed")
-- Attributes: id, NoBreak, PlacedByUserId

-- Item Drops
CollectionService:GetTagged("ItemDrop")
-- Attributes: itemType

-- Damage Indicators
CollectionService:GetTagged("DamageIndicatorPart")

-- Hotbar
CollectionService:GetTagged("HotbarHealthbarContainer")
```

## ═══ 5. Store State Structure ═══

```lua
local state = Store:getState()

-- Main state keys:
state.Bedwars          -- BedWars game state
state.Bedwars.playerLevel    -- Player level
state.Bedwars.milestoneRewardsClaimed  -- Claimed rewards
state.Consumable       -- Consumable items
state.Consumable.inventory  -- {consumable: "item_name", ...}
state.Inventory        -- Main inventory
state.Team             -- Team info
state.Match            -- Match state
```

## ═══ 6. Player Attributes ═══

```lua
-- LocalPlayer attributes:
lplr:GetAttribute("Team")        -- Current team name
lplr:GetAttribute("Health")      -- Current health

-- Character attributes:
char:GetAttribute("Health")      -- Health value
```

## ═══ 7. Bed System ═══

```lua
-- Find all beds
for _, bed in pairs(CollectionService:GetTagged("bed")) do
    local id = bed:GetAttribute("id")           -- "blue_bed", "red_bed", etc.
    local noBreak = bed:GetAttribute("NoBreak") -- true if unbreakable
    local placedBy = bed:GetAttribute("PlacedByUserId") -- who placed it

    -- Check if it's enemy bed
    local bedTeam = string.split(id, "_")[1]
    local myTeam = lplr:GetAttribute("Team")
    local isEnemy = bedTeam ~= myTeam
end
```

## ═══ 8. Item Drop System ═══

```lua
-- Find item drops
for _, drop in pairs(CollectionService:GetTagged("ItemDrop")) do
    local itemType = drop:GetAttribute("itemType") -- "iron", "gold", "diamond", etc.
    local position = drop.Position
end
```

## ═══ 9. Block System ═══

```lua
-- Place block
bedwars.BlockController:placeBlock("wool_white", position, Vector3.new(0, 1, 0))

-- Or via remote:
Client:GetNamespace("Block"):Get("PlaceBlock"):SendToServer({
    blockType = "wool_white",
    position = position,
    normal = Vector3.new(0, 1, 0)
})

-- Get block at position
local block = bedwars.BlockController:getBlockAt(roundedPosition)
```

## ═══ 10. Shop System ═══

```lua
-- Buy item
bedwars.ShopController:purchaseItem("diamond_sword", "main")

-- Or via remote:
Client:GetNamespace("Shop"):Get("PurchaseItem"):SendToServer({
    shopItem = {
        itemType = "diamond_sword",
        shopId = "main"
    }
})
```

## ═══ 11. Kit-Specific Remotes ═══

### Adetunde Kit:
```lua
-- Upgrade hammer
local net = ReplicatedStorage.rbxts_include.node_modules["@rbxts"].net.out._NetManaged
net.UpgradeFrostyHammer:InvokeServer("shield")  -- Shield upgrade
net.UpgradeFrostyHammer:InvokeServer("speed")   -- Speed upgrade
net.UpgradeFrostyHammer:InvokeServer("strength") -- Strength upgrade
```

### Ember Kit:
```lua
net.HellBladeRelease:FireServer({
    weapon = infernalSaber,
    player = lplr,
    chargeTime = 0.9
})
```

### Sky Scythe Kit:
```lua
net.SkyScytheSpin:FireServer()
```

## ═══ 12. Tool Names (All Known) ═══

### Swords:
```
emerald_sword (best) → diamond_sword → iron_sword → stone_sword → wood_sword (worst)
```

### Pickaxes:
```
diamond_pickaxe (best) → iron_pickaxe → stone_pickaxe → wood_pickaxe (worst)
```

### Axes:
```
diamond_axe (best) → iron_axe → stone_axe → wood_axe (worst)
```

### Special Weapons:
```
infernal_saber (Ember kit)
sky_scythe (Sky kit)
```

### Armor:
```
diamond_chestplate (best) → iron_chestplate → chainmail_chestplate → leather_chestplate (worst)
```

### Tools:
```
shears (wool)
bow, crossbow
grappling_hook
```

### Projectiles:
```
fireball, snowball, telepearl, rocket
```

### Consumables:
```
speed_potion, heal_potion, invisibility_potion
lucky_crate, diamond_crate
party_popper, train_whistle
```

### Blocks:
```
wool_white, wool_light_gray, wool_red, wool_blue, etc.
stone, obsidian, end_stone
```

## ═══ 13. How to Dump Remotes In-Game ═══

```lua
-- Run dump_all.lua to get full output!
-- Or manually:
for name, namespace in pairs(Client) do
    if type(namespace) == 'table' then
        for remoteName, _ in pairs(namespace) do
            print("Client:" .. name .. ":" .. remoteName)
        end
    end
end

-- Dump _NetManaged:
local net = ReplicatedStorage.rbxts_include.node_modules["@rbxts"].net.out._NetManaged
for _, child in pairs(net:GetChildren()) do
    print(child.Name .. " [" .. child.ClassName .. "]")
end

-- Dump all controllers:
for name, controller in pairs(Knit.Controllers) do
    local methods = {}
    for k, v in pairs(controller) do
        if type(v) == 'function' then table.insert(methods, k) end
    end
    print(name .. ": " .. table.concat(methods, ", "))
end
```

## ═══ 14. Common Exploit Patterns ═══

### Sprint:
```lua
bedwars.SprintController:startSprinting()
-- Hook to prevent stop:
local old = bedwars.SprintController.stopSprinting
bedwars.SprintController.stopSprinting = function(...)
    local call = old(...)
    bedwars.SprintController:startSprinting()
    return call
end
```

### Place Block:
```lua
bedwars.BlockController:placeBlock("wool_white", position, Vector3.new(0, 1, 0))
```

### Buy Item:
```lua
bedwars.ShopController:purchaseItem("diamond_sword", "main")
```

### Get Inventory:
```lua
local state = bedwars.Store:getState()
local inventory = state.Consumable.inventory
```

### Device Spoof:
```lua
bedwars.Client:Get('SendUserInputType'):SendToServer({userInputType = "MOBILE"})
```

### Open Crate:
```lua
bedwars.Client:GetNamespace('RewardCrate'):Get('OpenRewardCrate'):SendToServer({
    crateId = crateId
})
```

### Claim Milestone:
```lua
bedwars.Client:Get('ClaimMilestoneReward'):CallServer(rewardId)
```
