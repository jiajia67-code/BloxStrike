

-- BLOXSTRIKE API MODULE v1.0
-- Game-specific remotes, state, and helpers

local Players = nil

pcall(function() Players = game:GetService("Players") end)
local ReplicatedStorage = nil
pcall(function() ReplicatedStorage = game:GetService("ReplicatedStorage") end)
local CollectionService = nil
pcall(function() CollectionService = game:GetService("CollectionService") end)
local lplr = Players.LocalPlayer

local api = {}

 -- 1. Framework Detection
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

 -- 2. Client Remotes
local Client = nil
pcall(function()
    Client = require(ReplicatedStorage.TS.remotes).default.Client
end)
api.Client = Client

 -- 3. _NetManaged
api.NetManaged = nil
pcall(function()
    api.NetManaged = ReplicatedStorage
        -- :WaitForChild("rbxts_include")
        -- :WaitForChild("node_modules")
        -- :WaitForChild("@rbxts")
        -- :WaitForChild("net")
        -- :WaitForChild("out")
        -- :WaitForChild("_NetManaged")
end)

 -- 4. Store
api.Store = nil
pcall(function()
    api.Store = require(lplr.PlayerScripts.TS.ui.store).ClientStore
end)

 -- 5. Controllers
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

 -- 6. Dump
if Knit then
    local count = 0
    for _ in pairs(Knit.Controllers) do count = count + 1 end
    print("[API] Controllers: " .. count)
end
if api.NetManaged then
    print("[API] _NetManaged: " .. #api.NetManaged:GetChildren())
end

-- PLAYER STATE

function api.isAlive()
    local c = lplr.Character
    return c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChildOfClass("Humanoid")
end

function api.getHealth()
    local h = lplr.Character and lplr and lplr.Character:FindFirstChildOfClass("Humanoid")
    return h and h.Health or 0
end

function api.getMaxHealth()
    local h = lplr.Character and lplr and lplr.Character:FindFirstChildOfClass("Humanoid")
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
    return lplr.Team
end

-- ENEMY DETECTION

function api.getEnemies()
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lplr and p.Character then
            local h = p and p.Character:FindFirstChild("HumanoidRootPart")
            local hu = p and p.Character:FindFirstChildOfClass("Humanoid")
            local head = p and p.Character:FindFirstChild("Head")
            if h and hu and hu.Health > 0 then
                table.insert(t, {Player = p, HRP = h, Char = p.Character, Hum = hu, Head = head})
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

-- BLOXSTRIKE GAME STATE

function api.getGameState()
    local state = {}
    if api.Store then
        pcall(function()
            local s = api.Store:getState()
            state = s.BloxStrike or s.Game or s or {}
        end)
    end
    return state
end

function api.getRound()
    local state = api.getGameState()
    return state.round or state.Round or 0
end

function api.getMoney()
    local state = api.getGameState()
    return state.money or state.Money or state.cash or state.Cash or 0
end

function api.isAlive()
    local c = lplr.Character
    return c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChildOfClass("Humanoid")
        and c:FindFirstChildOfClass("Humanoid").Health > 0
end

-- BOMB / C4

function api.getBomb()
    -- Find planted bomb in workspace
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name:lower():find("bomb") or obj.Name:lower():find("c4") then
            return obj
        end
    end
    -- Also check tagged items
    for _, obj in pairs(CollectionService:GetTagged("bomb")) do
        return obj
    end
    return nil
end

function api.getBombSite()
    local bomb = api.getBomb()
    if not bomb then return nil end
    -- Check bomb position against known bomb sites
    local pos = bomb.Position
    local bombSites = workspace:FindFirstChild("BombSites") or workspace:FindFirstChild("Map")
    if bombSites then
        for _, site in pairs(bombSites:GetChildren()) do
            local sitePos = site:GetPrimaryPartCFrame and site:GetPrimaryPartCFrame().Position
            if sitePos and (pos - sitePos).Magnitude < 20 then
                return site.Name
            end
        end
    end
    return "Unknown"
end

function api.getBombTimer()
    local bomb = api.getBomb()
    if not bomb then return 0 end
    -- Try to read timer attribute
    return bomb:GetAttribute("Timer") or bomb:GetAttribute("DefuseTime") or 40
end

function api.hasBomb()
    local char = lplr.Character
    if char then
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:lower():find("c4") or tool.Name:lower():find("bomb")) then
                return true
            end
        end
    end
    return false
end

-- DEFUSE KIT

function api.hasDefuseKit()
    local char = lplr.Character
    if char then
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:lower():find("defuse") or tool.Name:lower():find("kit")) then
                return true
            end
        end
    end
    return false
end

-- GRENADES

function api.getGrenades()
    local grenades = {}
    local char = lplr.Character
    local bp = lplr:FindFirstChild("Backpack")
    local function scan(container)
        if not container then return end
        for _, tool in pairs(container:GetChildren()) do
            if tool:IsA("Tool") then
                local name = tool.Name:lower()
                if name:find("flash") or name:find("smoke") or name:find("molotov")
                    or name:find("he") or name:find("grenade") or name:find("decoy")
                    or name:find("incendiary") then
                    table.insert(grenades, tool)
                end
            end
        end
    end
    scan(char)
    scan(bp)
    return grenades
end

function api.throwGrenade(grenadeName)
    local char = lplr.Character
    if not char then return end
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find(grenadeName:lower()) then
            tool.Parent = char
            task.wait(0.1)
            -- tool:Activate()
            return true
        end
    end
    return false
end

-- REMOTE CALLS

function api.fireRemote(namespace, remote, params)
    if Client then
        pcall(function()
            -- Client:GetNamespace(namespace):Get(remote):SendToServer(params or {})
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

-- CONTROLLER SHORTCUTS

function api.startSprint()
    pcall(function() api.bw.SprintController:startSprinting() end)
end

function api.stopSprint()
    pcall(function() api.bw.SprintController:stopSprinting() end)
end

-- REAL REMOTE SHORTCUTS

-- Sprint
function api.sprintStart() api.fireNetManaged("SprintStart") end
function api.sprintStop() api.fireNetManaged("SprintStop") end

-- Shop / Buy
function api.buyWeapon(weaponName)
    return api.invokeNetManaged("PurchaseItem", {itemType = weaponName, shopId = "weapons"})
end

function api.buyEquipment(equipName)
    return api.invokeNetManaged("PurchaseItem", {itemType = equipName, shopId = "equipment"})
end

-- Bomb
function api.plantBomb(site)
    return api.invokeNetManaged("PlantBomb", {site = site})
end

function api.defuseBomb()
    return api.invokeNetManaged("DefuseBomb", {})
end

-- Chat
function api.sendMessage(msg)
    api.fireNetManaged("SendMessage", {message = msg})
end

print("[API] BloxStrike API loaded (Controllers=" .. tostring(Knit ~= nil)
    -- .. ", Net=" .. tostring(api.NetManaged ~= nil)
    -- .. ", Store=" .. tostring(api.Store ~= nil) .. ")")
return api
