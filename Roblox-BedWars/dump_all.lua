--!nocheck
-- ═══════════════════════════════════════════════════════════════
-- BEDWARS DUMP — Writes to file (Desktop)
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local lplr = Players.LocalPlayer

-- Write to file instead of console
local dumpFile = "bedwars_dump.txt"
local lines = {}

local function log(msg)
    table.insert(lines, msg)
end

log("═══════════════════════════════════════════")
log("  BEDWARS DUMP - " .. os.date("%Y-%m-%d %H:%M:%S"))
log("═══════════════════════════════════════════")

-- ═══ 1. Knit ═══
log("\n[1. KNIT FRAMEWORK]")
local KnitInit, Knit = pcall(function()
    return debug.getupvalue(require(lplr.PlayerScripts.TS.knit).setup, 9)
end)
if KnitInit and Knit then
    pcall(function() repeat task.wait() until debug.getupvalue(Knit.Start, 1) end)
    log("OK - Knit loaded")
else
    log("FAIL - Knit not available")
end

-- ═══ 2. Controllers ═══
log("\n[2. KNIT CONTROLLERS]")
if Knit then
    local names = {}
    for name, ctrl in pairs(Knit.Controllers) do
        local methods = {}
        for k, v in pairs(ctrl) do
            if type(v) == 'function' then
                table.insert(methods, k)
            end
        end
        table.insert(names, {name = name, methods = methods})
    end
    table.sort(names, function(a,b) return a.name < b.name end)
    log("Total: " .. #names)
    for _, item in pairs(names) do
        log("  " .. item.name .. " (" .. #item.methods .. " methods)")
        for _, m in pairs(item.methods) do
            log("    ." .. m .. "()")
        end
    end
end

-- ═══ 3. Client Remotes ═══
log("\n[3. CLIENT REMOTES]")
local Client = nil
pcall(function()
    Client = require(ReplicatedStorage.TS.remotes).default.Client
end)
if Client then
    local total = 0
    for name, ns in pairs(Client) do
        if type(ns) == 'table' then
            local remotes = {}
            for rName, _ in pairs(ns) do
                table.insert(remotes, rName)
                total = total + 1
            end
            table.sort(remotes)
            log("  " .. name .. " (" .. #remotes .. ")")
            for _, r in pairs(remotes) do
                log("    " .. r)
            end
        end
    end
    log("Total remotes: " .. total)
end

-- ═══ 4. _NetManaged ═══
log("\n[4. _NETMANAGED REMOTES]")
pcall(function()
    local net = ReplicatedStorage
        :WaitForChild("rbxts_include")
        :WaitForChild("node_modules")
        :WaitForChild("@rbxts")
        :WaitForChild("net")
        :WaitForChild("out")
        :WaitForChild("_NetManaged")
    local children = net:GetChildren()
    log("Total: " .. #children)
    for _, child in pairs(children) do
        log("  " .. child.Name .. " [" .. child.ClassName .. "]")
    end
end)

-- ═══ 5. Tags ═══
log("\n[5. COLLECTIONSERVICE TAGS]")
local tagData = {}
for _, tag in pairs(CollectionService:GetTags()) do
    local objects = CollectionService:GetTagged(tag)
    table.insert(tagData, {tag = tag, count = #objects})
end
table.sort(tagData, function(a,b) return a.count > b.count end)
log("Total tags: " .. #tagData)
for _, item in pairs(tagData) do
    log("  " .. item.tag .. " (" .. item.count .. " objects)")
end

-- ═══ 6. Beds ═══
log("\n[6. BEDS]")
pcall(function()
    for _, bed in pairs(CollectionService:GetTagged("bed")) do
        local id = bed:GetAttribute("id") or "?"
        local noBreak = bed:GetAttribute("NoBreak")
        log("  " .. id .. " NoBreak=" .. tostring(noBreak))
    end
end)

-- ═══ 7. Item Drops ═══
log("\n[7. ITEM DROPS]")
pcall(function()
    local drops = CollectionService:GetTagged("ItemDrop")
    log("Total: " .. #drops)
    local types = {}
    for _, d in pairs(drops) do
        local t = d:GetAttribute("itemType") or d.Name
        types[t] = (types[t] or 0) + 1
    end
    for t, c in pairs(types) do
        log("  " .. t .. ": " .. c)
    end
end)

-- ═══ 8. ReplicatedStorage ═══
log("\n[8. REPLICATEDSTORAGE]")
for _, child in pairs(ReplicatedStorage:GetChildren()) do
    log("  " .. child.Name .. " [" .. child.ClassName .. "] (" .. #child:GetChildren() .. " children)")
end

-- ═══ 9. TS Structure ═══
log("\n[9. TS STRUCTURE]")
pcall(function()
    local ts = ReplicatedStorage:WaitForChild("TS")
    for _, child in pairs(ts:GetChildren()) do
        log("  " .. child.Name .. " [" .. child.ClassName .. "]")
    end
end)

-- ═══ 10. rbxts Structure ═══
log("\n[10. RBXTS STRUCTURE]")
pcall(function()
    local rbxts = ReplicatedStorage:WaitForChild("rbxts_include")
    for _, child in pairs(rbxts:GetChildren()) do
        log("  " .. child.Name .. " [" .. child.ClassName .. "]")
    end
end)

-- ═══ 11. Player Attrs ═══
log("\n[11. PLAYER ATTRIBUTES]")
for name, value in pairs(lplr:GetAttributes()) do
    log("  " .. name .. " = " .. tostring(value))
end

-- ═══ 12. Char Attrs ═══
log("\n[12. CHARACTER ATTRIBUTES]")
pcall(function()
    local char = lplr.Character
    if char then
        for name, value in pairs(char:GetAttributes()) do
            log("  " .. name .. " = " .. tostring(value))
        end
    end
end)

-- ═══ 13. Store Keys ═══
log("\n[13. STORE STATE KEYS]")
pcall(function()
    local Store = require(lplr.PlayerScripts.TS.ui.store).ClientStore
    local state = Store:getState()
    for key, value in pairs(state) do
        if type(value) == 'table' then
            local subKeys = {}
            for k, _ in pairs(value) do
                table.insert(subKeys, k)
            end
            table.sort(subKeys)
            log("  " .. key .. " (" .. #subKeys .. " keys)")
            for _, k in pairs(subKeys) do
                log("    " .. k)
            end
        else
            log("  " .. key .. " = " .. tostring(value))
        end
    end
end)

-- ═══ 14. Tools ═══
log("\n[14. PLAYER TOOLS]")
pcall(function()
    local char = lplr.Character
    if char then
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") then log("  [Equipped] " .. tool.Name) end
        end
    end
    local bp = lplr:FindFirstChild("Backpack")
    if bp then
        for _, tool in pairs(bp:GetChildren()) do
            if tool:IsA("Tool") then log("  [Backpack] " .. tool.Name) end
        end
    end
end)

-- ═══ SAVE TO FILE ═══
log("\n═══════════════════════════════════════════")
log("  DUMP COMPLETE - " .. #lines .. " lines")
log("═══════════════════════════════════════════")

-- Write to multiple locations
local content = table.concat(lines, "\n")

-- Save to Desktop
pcall(function()
    writefile("bedwars_dump.txt", content)
    print("[DUMP] Saved to bedwars_dump.txt")
end)

-- Also try common paths
pcall(function()
    writefile("C:/Users/fff92/Desktop/bedwars_dump.txt", content)
    print("[DUMP] Saved to Desktop")
end)

-- Print summary to console
print("═══════════════════════════════════════")
print("  DUMP SAVED!")
print("  File: bedwars_dump.txt")
print("  Lines: " .. #lines)
print("  Open it to see full output")
print("═══════════════════════════════════════")
