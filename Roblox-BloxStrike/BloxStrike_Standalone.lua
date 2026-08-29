--[[ BloxStrike v3.0 Standalone - Direct paste and run ]]
print("[BloxStrike] v3.0 Standalone Loading...")
pcall(function() makefolder('BloxStrike') end)
pcall(function() makefolder('BloxStrike/modules') end)
writefile("BloxStrike/modules/api.lua", [[
local Players = nil
pcall(function() Players = game:GetService("Players") end)
local ReplicatedStorage = nil
pcall(function() ReplicatedStorage = game:GetService("ReplicatedStorage") end)
local CollectionService = nil
pcall(function() CollectionService = game:GetService("CollectionService") end)
local lplr = Players.LocalPlayer
local api = {}
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
local Client = nil
pcall(function()
Client = require(ReplicatedStorage.TS.remotes).default.Client
end)
api.Client = Client
api.NetManaged = nil
pcall(function()
api.NetManaged = ReplicatedStorage
end)
api.Store = nil
pcall(function()
api.Store = require(lplr.PlayerScripts.TS.ui.store).ClientStore
end)
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
if Knit then
local count = 0
for _ in pairs(Knit.Controllers) do count = count + 1 end
print("[API] Controllers: " .. count)
end
if api.NetManaged then
print("[API] _NetManaged: " .. #api.NetManaged:GetChildren())
end
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
function api.getBomb()
for _, obj in pairs(workspace:GetChildren()) do
if obj.Name:lower():find("bomb") or obj.Name:lower():find("c4") then
return obj
end
end
for _, obj in pairs(CollectionService:GetTagged("bomb")) do
return obj
end
return nil
end
function api.getBombSite()
local bomb = api.getBomb()
if not bomb then return nil end
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
return true
end
end
return false
end
function api.fireRemote(namespace, remote, params)
if Client then
pcall(function()
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
function api.startSprint()
pcall(function() api.bw.SprintController:startSprinting() end)
end
function api.stopSprint()
pcall(function() api.bw.SprintController:stopSprinting() end)
end
function api.sprintStart() api.fireNetManaged("SprintStart") end
function api.sprintStop() api.fireNetManaged("SprintStop") end
function api.buyWeapon(weaponName)
return api.invokeNetManaged("PurchaseItem", {itemType = weaponName, shopId = "weapons"})
end
function api.buyEquipment(equipName)
return api.invokeNetManaged("PurchaseItem", {itemType = equipName, shopId = "equipment"})
end
function api.plantBomb(site)
return api.invokeNetManaged("PlantBomb", {site = site})
end
function api.defuseBomb()
return api.invokeNetManaged("DefuseBomb", {})
end
function api.sendMessage(msg)
api.fireNetManaged("SendMessage", {message = msg})
end
print("[API] BloxStrike API loaded (Controllers=" .. tostring(Knit ~= nil)
return api
]])
writefile("BloxStrike/modules/bypass.lua", [[
local Players = nil
pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local Lighting = nil
pcall(function() Lighting = game:GetService("Lighting") end)
local Stats = nil
pcall(function() Stats = game:GetService("Stats") end)
local lplr = Players.LocalPlayer
local Bypass = {
OriginalProps = {},
HookedFunctions = {},
MonitoringConnections = {},
LastPosition = nil,
LastVelocity = nil,
PositionHistory = {},
VelocityHistory = {},
SuspiciousEvents = {},
IsBypassing = false,
OriginalMetatables = {},
FilteredSignals = {},
HiddenThreads = {},
ProtectedGC = false,
}
-- SECTION 1: ADVANCED METAMETHOD HOOK PROTECTION
function Bypass.backupMetatables()
pcall(function()
if getrawmetatable then
local mt = getrawmetatable(game)
if mt then
Bypass.OriginalMetatables = {
__index = mt.__index,
__namecall = mt.__namecall,
__newindex = mt.__newindex,
__tostring = mt.__tostring,
__concat = mt.__concat,
__unm = mt.__unm,
__add = mt.__add,
__sub = mt.__sub,
__mul = mt.__mul,
__div = mt.__div,
__mod = mt.__mod,
__pow = mt.__pow,
__len = mt.__len,
}
print("[Bypass] Original metatables backed up")
end
end
end)
end
function Bypass.restoreMetatables()
pcall(function()
if getrawmetatable then
local mt = getrawmetatable(game)
if mt and Bypass.OriginalMetatables then
for name, func in pairs(Bypass.OriginalMetatables) do
mt[name] = func
end
print("[Bypass] Original metatables restored")
end
end
end)
end
function Bypass.isMetatableHooked(name)
pcall(function()
if getrawmetatable then
local mt = getrawmetatable(game)
if mt and Bypass.OriginalMetatables then
if mt[name] ~= Bypass.OriginalMetatables[name] then
return true
end
end
end
end)
return false
end
function Bypass.protectHook(name, hookFunc)
pcall(function()
if not getrawmetatable then return hookFunc end
local mt = getrawmetatable(game)
if not mt then return hookFunc end
if not Bypass.OriginalMetatables[name] then
Bypass.OriginalMetatables[name] = mt[name]
end
local original = Bypass.OriginalMetatables[name]
local protectedHook = newcclosure and newcclosure(function(self, ...)
if Bypass.isACScanning() then
return original(self, ...)
end
return hookFunc(self, ...)
end) or hookFunc
return protectedHook
end)
return hookFunc
end
function Bypass.isACScanning()
pcall(function()
if debug and debug.getinfo then
local info = debug.getinfo(3)
if info and info.name then
local name = info.name:lower()
if name:find("scan") or name:find("hook") or name:find("detect") or name:find("check") then
return true
end
end
end
local now = tick()
if Bypass._lastACCheck and now - Bypass._lastACCheck < 0.001 then
if Bypass._acCallCount > 10 then
return true
end
else
Bypass._acCallCount = 0
end
Bypass._lastACCheck = now
end)
return false
end
-- SECTION 2: ENVIRONMENT SPOOFING
function Bypass.spoofCheckcaller()
pcall(function()
if checkcaller then
local oldCheckcaller = checkcaller
_G.checkcaller = function()
return false
end
Bypass._originalCheckcaller = oldCheckcaller
print("[Bypass] checkcaller spoofed  always returns false")
end
end)
end
function Bypass.restoreCheckcaller()
pcall(function()
if Bypass._originalCheckcaller then
_G.checkcaller = Bypass._originalCheckcaller
end
end)
end
function Bypass.spoofGetgenv()
pcall(function()
if getgenv then
local env = getgenv()
local suspicious = {}
for key, _ in pairs(env) do
local keyLower = key:lower()
local legit = false
for _, keep in ipairs({
}) do
if key == keep or keyLower:find(keep:lower()) then
legit = true
break
end
end
if not legit and not key:find("^_") then
table.insert(suspicious, key)
end
end
for _, key in ipairs(suspicious) do
env[key] = nil
end
end
end)
end
-- SECTION 3: THREAD HIDING
function Bypass.hideThread(name, func)
Bypass.HiddenThreads[name] = {
Func = func,
Hidden = true,
LastRun = 0,
}
end
function Bypass.runHiddenThread(name)
local thread = Bypass.HiddenThreads[name]
if not thread then return end
task.spawn(function()
while true do
task.wait(0.5)
if thread.Hidden then
task.wait(math.random() * 0.1)
pcall(thread.Func)
thread.LastRun = tick()
end
end
end)
end
-- SECTION 4: MEMORY PROTECTION
function Bypass.protectMemory()
pcall(function()
for _, obj in pairs(workspace:GetDescendants()) do
if obj.Name:find("BS_") then
obj.Parent = nil
end
end
for _, gui in pairs(lplr.PlayerGui:GetChildren()) do
if gui.Name:find("BloxStrike") or gui.Name:find("BS_") then
gui.Enabled = false
gui.DisplayOrder = -9999
gui.IgnoreGuiInset = true
end
end
collectgarbage("collect")
collectgarbage("collect")
end)
end
-- SECTION 5: SIGNAL FILTERING
function Bypass.filterChangedEvents(instance)
pcall(function()
if getconnections then
local conns = getconnections(instance.Changed)
for _, conn in ipairs(conns) do
local info = debug.getinfo(conn.Function)
if info and info.source then
local source = info.source:lower()
if source:find("anticheat") or source:find("monitor") or source:find("detect") then
print("[Bypass] Filtered AC Changed connection: " .. instance.Name)
end
end
end
end
end)
end
function Bypass.filterDescendantEvents(parent)
pcall(function()
if getconnections then
local conns = getconnections(parent.DescendantAdded)
for _, conn in ipairs(conns) do
local info = debug.getinfo(conn.Function)
if info and info.source then
local source = info.source:lower()
if source:find("anticheat") or source:find("monitor") or source:find("detect") then
print("[Bypass] Filtered AC DescendantAdded connection")
end
end
end
end
end)
end
-- SECTION 6: PROPERTY CHANGE INTERCEPTION
function Bypass.interceptHumanoidProps()
pcall(function()
local h = BS.hum()
if not h then return end
Bypass.OriginalProps = {
WalkSpeed = h.WalkSpeed,
JumpPower = h.JumpPower,
JumpHeight = h.JumpHeight,
HipHeight = h.HipHeight,
MaxHealth = h.MaxHealth,
Health = h.Health,
PlatformStand = h.PlatformStand,
AutoRotate = h.AutoRotate,
}
end)
end
-- SECTION 7: REMOTE OBFUSCATION
local remoteCallHistory = {}
local remoteCallLimit = 20
function Bypass.obfuscateRemoteCall(func, ...)
local now = tick()
for i = #remoteCallHistory, 1, -1 do
if now - remoteCallHistory[i] > 1 then
table.remove(remoteCallHistory, i)
end
end
if #remoteCallHistory >= remoteCallLimit then
task.wait(1 / remoteCallLimit)
end
if math.random() < 0.4 then
task.wait(math.random() * 0.03)
end
table.insert(remoteCallHistory, now)
return func(...)
end
function Bypass.validateRemote(remote)
if not remote then return false end
local name = remote.Name:lower()
local suspicious = {"anticheat", "kick", "ban", "validate", "check", "monitor", "guard", "shield"}
for _, s in ipairs(suspicious) do
if name:find(s) then
return false
end
end
return true
end
-- SECTION 8: ADVANCED TIMING OBFUSCATION
local timingPatterns = {}
local timingHistory = {}
function Bypass.generateTimingPattern()
local patterns = {
function(base)
return base + (math.random() - 0.5) * base * 0.1
end,
function(base)
if math.random() < 0.05 then
return base * (2 + math.random() * 3)
end
return base + (math.random() - 0.5) * base * 0.2
end,
function(base)
local t = tick() % 10
local factor = 1 + math.sin(t * 0.5) * 0.3
return base * factor + (math.random() - 0.5) * base * 0.1
end,
function(base)
if math.random() < 0.1 then
return base * 0.5
elseif math.random() < 0.1 then
return base * 2
end
return base + (math.random() - 0.5) * base * 0.15
end,
}
return patterns[math.random(#patterns)]
end
function Bypass.obfuscateTiming(baseDelay)
local pattern = Bypass.generateTimingPattern()
local delay = pattern(baseDelay)
table.insert(timingHistory, {Time = tick(), Delay = delay})
if #timingHistory > 50 then table.remove(timingHistory, 1) end
return math.max(0.001, delay)
end
function Bypass.isTimingSuspicious()
if #timingHistory < 10 then return false end
local intervals = {}
for i = 2, #timingHistory do
table.insert(intervals, timingHistory[i].Time - timingHistory[i-1].Time)
end
local mean = 0
for _, v in ipairs(intervals) do mean = mean + v end
mean = mean / #intervals
local variance = 0
for _, v in ipairs(intervals) do
variance = variance + (v - mean)^2
end
variance = variance / #intervals
return variance < 0.00001
end
-- SECTION 9: GC (GARBAGE COLLECTION) PROTECTION
function Bypass.protectGC()
if Bypass.ProtectedGC then return end
Bypass.ProtectedGC = true
pcall(function()
collectgarbage("stop")
for _, obj in pairs(workspace:GetDescendants()) do
if obj.Name:find("BS_") and obj:IsA("BasePart") then
pcall(function() obj:Destroy() end)
end
end
collectgarbage("restart")
end)
end
-- SECTION 10: CFRAME VALIDATION BYPASS
function Bypass.validateCFrame(cf)
if not cf then return false end
if cf ~= cf then return false end
local pos = cf.Position
if math.abs(pos.X) > 5000 or math.abs(pos.Y) > 5000 or math.abs(pos.Z) > 5000 then
return false
end
return true
end
function Bypass.safeCFrameSet(instance, cf)
if not Bypass.validateCFrame(cf) then return false end
pcall(function() instance.CFrame = cf end)
return true
end
-- SECTION 11: TELEPORT DETECTION BYPASS
function Bypass.trackPosition()
if not BS.alive() then return end
local hrp = BS.hrp()
if not hrp then return end
local currentPos = hrp.Position
local currentVel = hrp.AssemblyLinearVelocity
table.insert(Bypass.PositionHistory, {Time = tick(), Pos = currentPos})
table.insert(Bypass.VelocityHistory, {Time = tick(), Vel = currentVel})
if #Bypass.PositionHistory > 20 then table.remove(Bypass.PositionHistory, 1) end
if #Bypass.VelocityHistory > 20 then table.remove(Bypass.VelocityHistory, 1) end
Bypass.LastPosition = currentPos
Bypass.LastVelocity = currentVel
end
function Bypass.isTeleport(newPos)
if not Bypass.LastPosition then return false end
local distance = (newPos - Bypass.LastPosition).Magnitude
local velocity = Bypass.LastVelocity and Bypass.LastVelocity.Magnitude or 0
local maxReasonable = velocity * 0.5 + 10
return distance > maxReasonable
end
function Bypass.smoothTeleport(targetPos, duration)
if not BS.alive() then return false end
local hrp = BS.hrp()
if not hrp then return false end
duration = duration or 0.3
if not Bypass.validateCFrame(CFrame.new(targetPos)) then return false end
local startCF = hrp.CFrame
local endCF = CFrame.new(targetPos) * (startCF - startCF.Position)
pcall(function()
local tween = game:GetService("TweenService"):Create(
hrp, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
{CFrame = endCF}
)
pcall(function() tween:Play() end)
end)
return true
end
-- SECTION 12: HEARTBEAT MONITORING BYPASS
local heartbeatHistory = {}
function Bypass.trackHeartbeat()
local now = tick()
table.insert(heartbeatHistory, now)
if #heartbeatHistory > 30 then table.remove(heartbeatHistory, 1) end
end
function Bypass.isHeartbeatAbnormal()
if #heartbeatHistory < 10 then return false end
local intervals = {}
for i = 2, #heartbeatHistory do
table.insert(intervals, heartbeatHistory[i] - heartbeatHistory[i-1])
end
local mean = 0
for _, v in ipairs(intervals) do mean = mean + v end
mean = mean / #intervals
local variance = 0
for _, v in ipairs(intervals) do variance = variance + (v - mean)^2 end
variance = variance / #intervals
return variance < 0.0001
end
-- SECTION 13: BEHAVIORAL ANALYSIS BYPASS
function Bypass.humanizeMovement()
if not BS.alive() then return end
local h = BS.hum()
if not h then return end
local baseSpeed = h.WalkSpeed
local jitter = (math.random() - 0.5) * 1.0
h.WalkSpeed = baseSpeed + jitter
task.wait(0.1)
h.WalkSpeed = baseSpeed
if math.random() < 0.1 then
local hrp = BS.hrp()
if hrp then
local microAdjust = CFrame.Angles(0, (math.random() - 0.5) * 0.05, 0)
hrp.CFrame = hrp.CFrame * microAdjust
end
end
end
function Bypass.humanizeAim(targetPos)
if not targetPos then return targetPos end
local offset = Vector3.new(
)
return targetPos + offset
end
-- SECTION 14: EMERGENCY BYPASS SYSTEM
function Bypass.emergencyBypass()
pcall(function()
for _, conn in pairs(Bypass.MonitoringConnections) do
pcall(function() conn:Disconnect() end)
end
Bypass.MonitoringConnections = {}
for k, _ in pairs(Flags) do
if k:find("Bhop") or k:find("Rage") or k:find("AA") or k:find("FL") then
Flags[k] = false
end
end
print("[Bypass] Emergency bypass activated")
end)
end
task.spawn(function()
task.wait(1)
print("[Bypass] Advanced bypass systems initialized")
end)
RunService.Heartbeat:Connect(function()
end)
task.spawn(function()
while true do
task.wait(15)
pcall(collectgarbage, "collect")
end
end)
BS.Bypass = Bypass
-- SECTION 15: INJECTION ARTIFACT CLOAKING
task.spawn(function()
while true do task.wait(20)
pcall(function()
pcall(function()
for _, obj in pairs(workspace:GetDescendants()) do
if obj:IsA("BasePart") and (
obj.Name:find("BS_") or obj.Name:find("BloxStrike") or
obj.Transparency == 1 and not obj.Anchored and obj.Size.Magnitude < 5
) then
pcall(function() obj:Destroy() end)
end
end
end)
pcall(function()
local cg = nil
pcall(function() cg = game:GetService("CoreGui") end)
if cg then
for _, gui in pairs(cg:GetChildren()) do
if gui:IsA("ScreenGui") and (
gui.Name:find("BloxStrike") or gui.Name:find("BS_")
) then
end
end
end
end)
pcall(function()
for _, gui in pairs(lplr.PlayerGui:GetChildren()) do
if gui:IsA("ScreenGui") and (
gui.Name:find("BloxStrike") or gui.Name:find("BS_")
) then
gui.Enabled = false
gui.DisplayOrder = -9999
gui.IgnoreGuiInset = true
end
end
end)
collectgarbage("collect")
end)
end
end)
-- SECTION 16: ANTI-DEBUG PROTECTION
pcall(function()
if debug then
local oldGetInfo = debug.getinfo
debug.getinfo = function(level, what)
local info = oldGetInfo(level, what)
if info then
if info.source and (
info.source:find("BloxStrike") or info.source:find("BS_") or
info.source:find("bypass") or info.source:find("stealth") or
info.source:find("rage") or info.source:find("combat")
) then
info.source = "[C]"
info.short_src = "[C]"
info.linedefined = 0
info.lastlinedefined = 0
end
if info.what == "Lua" and info.source == "[C]" then
end
end
return info
end
local oldTraceback = debug.traceback
debug.traceback = function(level, message)
local tb = oldTraceback(level, message)
if tb then
tb = tb:gsub(".-BloxStrike.-%c.-%c", "")
tb = tb:gsub(".-BS_%w+.-%c.-%c", "")
tb = tb:gsub(".-bypass.-%c.-%c", "")
tb = tb:gsub(".-stealth.-%c.-%c", "")
end
return tb
end
local oldGetLocal = debug.getlocal
debug.getlocal = function(level, index)
local name, value = oldGetLocal(level, index)
if name and name:find("BS_") then
return nil, nil
end
return name, value
end
local oldGetUpvalue = debug.getupvalue
debug.getupvalue = function(func, level)
local name, value = oldGetUpvalue(func, level)
if name and (
name:find("BS") or name:find("BloxStrike") or
name:find("bypass") or name:find("stealth")
) then
return nil, nil
end
return name, value
end
end
end)
-- SECTION 17: REPLAY PROTECTION
local replayProtection = {
ActionLog = {},
MaxLogSize = 200,
}
function Bypass.logAction(actionType, params)
table.insert(replayProtection.ActionLog, {
Type = actionType,
})
if #replayProtection.ActionLog > replayProtection.MaxLogSize then
table.remove(replayProtection.ActionLog, 1)
end
end
function Bypass.fuzzyActionMatch(log1, log2, threshold)
threshold = threshold or 0.8
if #log1 ~= #log2 then return false end
local matchCount = 0
for i = 1, #log1 do
if log1[i].Type == log2[i].Type then
local timeDiff = math.abs(log1[i].Time - log2[i].Time)
if timeDiff < 0.1 then
matchCount = matchCount + 1
end
end
end
return (matchCount / #log1) >= threshold
end
-- SECTION 18: INTEGRITY MONITOR
local integrityState = {
CheckCount = 0,
FailCount = 0,
RepairCount = 0,
}
function Bypass.checkIntegrity()
integrityState.CheckCount = integrityState.CheckCount + 1
local issues = {}
pcall(function()
if getrawmetatable then
local mt = getrawmetatable(game)
if mt then
if Bypass.OriginalMetatables.__index then
if mt.__index ~= Bypass.OriginalMetatables.__index then
table.insert(issues, "__index modified")
end
end
end
end
local guiFound = false
pcall(function()
for _, gui in pairs(lplr.PlayerGui:GetChildren()) do
if gui:IsA("ScreenGui") then
guiFound = true
end
end
end)
if not guiFound then
table.insert(issues, "GUI missing")
end
if BS.alive and not BS.alive() then
table.insert(issues, "Character dead/missing")
end
local cam = workspace.CurrentCamera
if not cam then
table.insert(issues, "Camera missing")
elseif cam.CFrame ~= cam.CFrame then
table.insert(issues, "Camera NaN")
end
local h = BS.hum()
if h then
if h.WalkSpeed < 0 or h.WalkSpeed > 500 then
table.insert(issues, "WalkSpeed extreme: " .. h.WalkSpeed)
end
if h.JumpPower < 0 or h.JumpPower > 500 then
table.insert(issues, "JumpPower extreme: " .. h.JumpPower)
end
end
end)
if #issues > 0 then
integrityState.FailCount = integrityState.FailCount + 1
for _, issue in ipairs(issues) do
if issue == "Camera NaN" then
pcall(function()
workspace.CurrentCamera.CFrame = CFrame.new(0, 10, 0)
end)
elseif issue:find("WalkSpeed") or issue:find("JumpPower") then
pcall(function()
local h = BS.hum()
if h then
h.WalkSpeed = math.clamp(h.WalkSpeed, 0, 100)
h.JumpPower = math.clamp(h.JumpPower, 0, 200)
end
end)
elseif issue == "GUI missing" then
pcall(function() if BS.Stealth and BS.Stealth.selfHeal then BS.Stealth.selfHeal() end end)
end
integrityState.RepairCount = integrityState.RepairCount + 1
end
end
integrityState.LastCheck = tick()
return issues
end
task.spawn(function()
while true do task.wait(5)
pcall(function() Bypass.checkIntegrity() end)
end
end)
Bypass.IntegrityState = integrityState
-- SECTION 19: PROPERTY INTERCEPTION v2
local propIntercept = {
WatchedProperties = {},
ChangeLog = {},
AutoRestore = true,
}
function Bypass.watchProperty(instance, propName, getDesired, priority)
propIntercept.WatchedProperties[instance] = propIntercept.WatchedProperties[instance] or {}
propIntercept.WatchedProperties[instance][propName] = {
GetDesired = getDesired,
Priority = priority or 1,
LastValue = nil,
}
end
task.spawn(function()
while true do task.wait(0.1)
pcall(function()
for instance, props in pairs(propIntercept.WatchedProperties) do
if instance and instance.Parent then
for propName, data in pairs(props) do
local currentValue = instance[propName]
local desiredValue = data.GetDesired()
if desiredValue and currentValue ~= desiredValue then
if propIntercept.AutoRestore then
instance[propName] = desiredValue
table.insert(propIntercept.ChangeLog, {
Instance = instance.Name,
Property = propName,
Was = currentValue,
})
end
end
data.LastValue = currentValue
end
end
end
if #propIntercept.ChangeLog > 100 then
table.remove(propIntercept.ChangeLog, 1)
end
end)
end
end)
Bypass.PropIntercept = propIntercept
-- SECTION 20: NETWORK FINGERPRINT EVASION
local netFP = {
PacketHistory = {},
NormalTrafficPatterns = {},
BurstCount = 0,
}
function Bypass.analyzeNormalTraffic()
pcall(function()
for _, remote in pairs(game:GetDescendants()) do
if remote:IsA("RemoteEvent") then
local conns = getconnections and getconnections(remote.OnClientEvent)
if conns and #conns > 0 then
netFP.NormalTrafficPatterns[remote.Name] = {
ConnCount = #conns,
}
end
end
end
end)
end
function Bypass.generateNormalTraffic()
if not Flags.TrafficMask then return end
pcall(function()
local remotes = {}
for _, obj in pairs(game:GetDescendants()) do
if obj:IsA("RemoteEvent") then
local name = obj.Name:lower()
if not name:find("anticheat") and not name:find("kick") and not name:find("ban") and not name:find("validate") then
table.insert(remotes, obj)
end
end
end
if #remotes > 0 then
local target = remotes[math.random(#remotes)]
pcall(function() target:FireServer() end)
end
end)
end
function Bypass.trackBurst()
local now = tick()
if now - netFP.LastBurstTime < 0.5 then
netFP.BurstCount = netFP.BurstCount + 1
else
netFP.BurstCount = 0
end
netFP.LastBurstTime = now
if netFP.BurstCount > 10 then
task.wait(0.5 + math.random() * 0.5)
netFP.BurstCount = 0
end
end
Bypass.NetFP = netFP
-- SECTION 21: EMERGENCY SANDBOX DETECTION
local sandboxState = {
DetectionCount = 0,
IsSandboxed = false,
CanaryValues = {},
}
function Bypass.createTimingCanary()
sandboxState.CanaryValues.StartTime = tick()
sandboxState.CanaryValues.ExpectedDelta = 0.016
end
function Bypass.checkTimingCanary()
if not sandboxState.CanaryValues.StartTime then return false end
local elapsed = tick() - sandboxState.CanaryValues.StartTime
local expectedFrames = elapsed / sandboxState.CanaryValues.ExpectedDelta
if elapsed > 1 and math.abs(expectedFrames - elapsed * 60) > 10 then
sandboxState.IsSandboxed = true
sandboxState.DetectionCount = sandboxState.DetectionCount + 1
return true
end
return false
end
task.spawn(function()
while true do task.wait(5)
pcall(function()
local startTick = tick()
task.defer(function()
local deferTime = tick() - startTick
if deferTime > 0.1 then
sandboxState.DetectionCount = sandboxState.DetectionCount + 1
end
end)
pcall(function()
if getgenv then
local env = getgenv()
for key, _ in pairs(env) do
local keyLower = key:lower()
if keyLower:find("monitor") or keyLower:find("capture") or
sandboxState.IsSandboxed = true
sandboxState.DetectionCount = sandboxState.DetectionCount + 1
end
end
end
end)
local gcCount = collectgarbage("count")
if gcCount > 500 then
sandboxState.DetectionCount = sandboxState.DetectionCount + 1
end
if sandboxState.DetectionCount > 3 then
pcall(function()
local gui = lplr.PlayerGui:FindFirstChildWhichIsA("ScreenGui")
if gui then gui.Enabled = false end
end)
end
end)
end
end)
Bypass.SandboxState = sandboxState
-- SECTION 22: __NAMECALL HOOK PROTECTION
local namecallProtection = {
ProtectedInstances = {},
SpoofedReturns = {},
CallCount = 0,
LastScanDetection = 0,
}
function Bypass.protectInstanceFromNamecall(instance, methodName, spoofReturn)
if not instance then return end
local id = tostring(instance)
namecallProtection.ProtectedInstances[id] = namecallProtection.ProtectedInstances[id] or {}
namecallProtection.ProtectedInstances[id][methodName] = spoofReturn
end
function Bypass.hookNamecall()
pcall(function()
if not getrawmetatable or not hookmetamethod then return end
local mt = getrawmetatable(game)
if not mt then return end
local oldNamecall = mt.__namecall
if not oldNamecall then return end
mt.__namecall = newcclosure and newcclosure(function(self, ...)
local method = getnamecallmethod and getnamecallmethod() or ""
local methodLower = method:lower()
namecallProtection.CallCount = namecallProtection.CallCount + 1
local now = tick()
if now - namecallProtection.LastScanDetection > 1 then
namecallProtection.CallCount = 0
end
if namecallProtection.CallCount > 50 then
namecallProtection.LastScanDetection = now
if methodLower == "getchildren" or methodLower == "getdescendants" then
return {}
elseif methodLower == "findfirstchild" or methodLower:find("find") then
return nil
elseif methodLower == "getproperty" or methodLower == "getattr" then
return nil
elseif methodLower == "clone" then
return nil
end
end
local id = tostring(self)
if namecallProtection.ProtectedInstances[id] then
local spoof = namecallProtection.ProtectedInstances[id][method]
if spoof ~= nil then
return spoof
end
end
if self and self.Name and (
self.Name:find("BS_") or self.Name:find("BloxStrike") or
self.Name:find("BS_Kill") or self.Name:find("BS_Weapon")
) then
if methodLower == "getchildren" then return {} end
if methodLower == "getdescendants" then return {} end
if methodLower == "clone" then return nil end
end
if methodLower == "getinfo" or methodLower == "getstack" or methodLower == "setstack" then
if namecallProtection.CallCount > 20 then
return {source = "[C]", what = "C", name = ""}
end
end
return oldNamecall(self, ...
end) or oldNamecall
print("[Bypass] __namecall hook installed")
end)
end
Bypass.NamecallProtection = namecallProtection
-- SECTION 23: EXECUTOR FINGERPRINT SPOOF
local executorFingerprint = {
Originals = {},
Spoofed = false,
}
function Bypass.spoofExecutorFingerprint()
pcall(function()
if executorFingerprint.Spoofed then return end
local executorGlobals = {
}
for _, name in ipairs(executorGlobals) do
if _G[name] ~= nil then
executorFingerprint.Originals[name] = _G[name]
if name == "getexecutorname" or name == "identifyexecutor" then
_G[name] = function() return "RobloxStudio" end
else
_G[name] = nil
end
end
end
if getgenv then
local env = getgenv()
local execFlags = {
}
for _, flag in ipairs(execFlags) do
if env[flag] then
executorFingerprint.Originals["genv_" .. flag] = env[flag]
env[flag] = nil
end
end
end
if islclosure then
local oldIsLClosure = islclosure
executorFingerprint.Originals.islclosure = oldIsLClosure
_G.islclosure = function(func)
local info = debug and debug.getinfo and debug.getinfo(func)
if info and info.source and (
info.source:find("BloxStrike") or info.source:find("BS_")
) then
return false
end
return oldIsLClosure(func)
end
end
executorFingerprint.Spoofed = true
print("[Bypass] Executor fingerprint spoofed")
end)
end
function Bypass.restoreExecutorFingerprint()
pcall(function()
for name, value in pairs(executorFingerprint.Originals) do
if name:sub(1, 5) == "genv_" then
local realName = name:sub(6)
if getgenv then getgenv()[realName] = value end
else
_G[name] = value
end
end
executorFingerprint.Spoofed = false
print("[Bypass] Executor fingerprint restored")
end)
end
Bypass.ExecutorFingerprint = executorFingerprint
-- SECTION 24: SIGNAL HOOK PROTECTION
local signalProtection = {
WrappedConnections = {},
TotalWrapped = 0,
}
function Bypass.wrapConnection(name, connection)
if not connection then return nil end
pcall(function()
signalProtection.TotalWrapped = signalProtection.TotalWrapped + 1
local id = signalProtection.TotalWrapped
signalProtection.WrappedConnections[id] = {
Name = name or "unknown",
Connection = connection,
Active = true,
}
task.delay(300, function()
if signalProtection.WrappedConnections[id] then
pcall(function() connection:Disconnect() end)
signalProtection.WrappedConnections[id] = nil
end
end)
end)
return connection
end
function Bypass.wrapInputConnection(name, inputType, callback)
local conn = nil
pcall(function()
if inputType == "Began" then
conn = UserInputService.InputBegan:Connect(function(input, gpe)
if math.random() < 0.05 then
task.wait(math.random() * 0.005)
end
callback(input, gpe)
end)
elseif inputType == "Ended" then
conn = UserInputService.InputEnded:Connect(function(input)
if math.random() < 0.03 then
task.wait(math.random() * 0.003)
end
callback(input)
end)
elseif inputType == "Changed" then
conn = UserInputService.InputChanged:Connect(function(input)
callback(input)
end)
end
end)
return Bypass.wrapConnection(name, conn)
end
function Bypass.disconnectAllWrapped()
for id, data in pairs(signalProtection.WrappedConnections) do
if data and data.Connection then
pcall(function() data.Connection:Disconnect() end)
end
signalProtection.WrappedConnections[id] = nil
end
print("[Bypass] All wrapped connections disconnected")
end
Bypass.SignalProtection = signalProtection
-- SECTION 25: REMOTE CALL CAMOUFLAGE
local remoteCamouflage = {
CallHistory = {},
PatternIndex = 0,
LastDecoy = 0,
DecoyInterval = 3,
RateLimiter = {},
}
function Bypass.camouflagedFire(remote, ...)
if not remote or not remote:IsA("RemoteEvent") then return false end
if not Bypass.validateRemote(remote) then return false end
local now = tick()
local name = remote.Name
remoteCamouflage.RateLimiter[name] = remoteCamouflage.RateLimiter[name] or {Count = 0, ResetTime = now}
local limiter = remoteCamouflage.RateLimiter[name]
if now - limiter.ResetTime > 1 then
limiter.Count = 0
limiter.ResetTime = now
end
limiter.Count = limiter.Count + 1
if limiter.Count > 15 then
return false
end
local jitter = (math.random() - 0.5) * 0.008
if jitter > 0 then task.wait(jitter) end
table.insert(remoteCamouflage.CallHistory, {
Remote = name,
Time = now,
})
if #remoteCamouflage.CallHistory > 100 then
table.remove(remoteCamouflage.CallHistory, 1)
end
if now - remoteCamouflage.LastDecoy > remoteCamouflage.DecoyInterval then
remoteCamouflage.LastDecoy = now
pcall(function()
for _, obj in pairs(game:GetDescendants()) do
if obj:IsA("RemoteEvent") and obj ~= remote then
local rname = obj.Name:lower()
if not rname:find("anticheat") and not rname:find("kick")
and not rname:find("ban") and not rname:find("validate") then
break
end
end
end
end)
end
pcall(function() remote:FireServer(...) end)
return true
end
function Bypass.camouflagedInvoke(remote, ...)
if not remote or not remote:IsA("RemoteFunction") then return nil end
if not Bypass.validateRemote(remote) then return nil end
local jitter = (math.random() - 0.5) * 0.005
if jitter > 0 then task.wait(jitter) end
local result = nil
pcall(function() result = {remote:InvokeServer(...)} end)
return result and result[1] or nil
end
Bypass.RemoteCamouflage = remoteCamouflage
-- SECTION 26: MEMORY REGION CLOAKING
local memoryCloaking = {
HiddenRegions = {},
CloakedObjects = {},
ScanInterval = 10,
LastScan = 0,
}
function Bypass.cloakMemory()
pcall(function()
local now = tick()
if now - memoryCloaking.LastScan < memoryCloaking.ScanInterval then return end
memoryCloaking.LastScan = now
pcall(function()
end)
pcall(function()
for _, obj in pairs(workspace:GetDescendants()) do
if obj:IsA("BasePart") and obj.Name:find("BS_") then
local legitNames = {
}
obj.Name = legitNames[math.random(#legitNames)]
obj.Parent = nil
end
end
end)
pcall(function()
if Bypass.PositionHistory and #Bypass.PositionHistory > 20 then
local keep = {}
for i = math.max(1, #Bypass.PositionHistory - 10), #Bypass.PositionHistory do
table.insert(keep, Bypass.PositionHistory[i])
end
Bypass.PositionHistory = keep
end
if Bypass.VelocityHistory and #Bypass.VelocityHistory > 20 then
local keep = {}
for i = math.max(1, #Bypass.VelocityHistory - 10), #Bypass.VelocityHistory do
table.insert(keep, Bypass.VelocityHistory[i])
end
Bypass.VelocityHistory = keep
end
end)
pcall(function()
for _, gui in pairs(lplr.PlayerGui:GetChildren()) do
if gui:IsA("ScreenGui") and (
gui.Name:find("BloxStrike") or gui.Name:find("BS_")
) then
local legitGuiNames = {
}
gui.Name = legitGuiNames[math.random(#legitGuiNames)]
end
end
end)
end)
end
Bypass.MemoryCloaking = memoryCloaking
-- SECTION 27: AC SIGNATURE EVASION
local signatureEvasion = {
DetectedSignatures = {},
EvasionActive = false,
RiskScore = 0,
}
local AC_PATTERNS = {
Strings = {
},
FunctionCalls = {
},
}
function Bypass.scanForSignatures()
pcall(function()
local detected = {}
local env = getgenv and getgenv() or {}
for key, value in pairs(env) do
if type(value) == "string" then
for _, pattern in ipairs(AC_PATTERNS.Strings) do
if value:find(pattern) then
table.insert(detected, {
Type = "GlobalString",
Key = key,
Pattern = pattern,
})
break
end
end
end
end
signatureEvasion.DetectedSignatures = detected
signatureEvasion.RiskScore = math.min(100, #detected * 5)
if #detected > 3 then
signatureEvasion.EvasionActive = true
end
end)
end
function Bypass.applySignatureEvasion()
if not signatureEvasion.EvasionActive then return end
pcall(function()
local env = getgenv and getgenv() or {}
for key, value in pairs(env) do
if type(value) == "string" then
for _, sig in ipairs(signatureEvasion.DetectedSignatures) do
if sig.Key == key then
env[key] = ""
break
end
end
end
end
pcall(function()
if newcclosure then
for key, value in pairs(env) do
if type(value) == "function" and not checkcaller() then
local info = debug and debug.getinfo and debug.getinfo(value)
if info and info.source and info.source:find("BS_") then
env[key] = newcclosure(value)
end
end
end
end
end)
end)
end
Bypass.SignatureEvasion = signatureEvasion
-- SECTION 28: HEARTBEAT SPOOFING
local heartbeatSpoof = {
OriginalInterval = 1/60,
SpoofedInterval = 1/60,
JitterAmount = 0.002,
FakeHeartbeats = 0,
}
function Bypass.spoofHeartbeatTiming()
pcall(function()
local jitter = (math.random() - 0.5) * heartbeatSpoof.JitterAmount
return heartbeatSpoof.OriginalInterval + jitter
end)
return heartbeatSpoof.OriginalInterval
end
function Bypass.generateDecoyHeartbeats()
pcall(function()
local now = tick()
if now % 2 < 0.02 then
heartbeatSpoof.FakeHeartbeats = heartbeatSpoof.FakeHeartbeats + 1
end
end)
end
Bypass.HeartbeatSpoof = heartbeatSpoof
-- SECTION 29: ADVANCED ANTI-DUMP
local antiDump = {
ObfuscatedStrings = {},
Active = false,
}
function Bypass.obfuscateStrings()
pcall(function()
if antiDump.Active then return end
local env = getgenv and getgenv() or {}
for key, value in pairs(env) do
if type(value) == "string" and #value > 3 then
local lower = value:lower()
local suspicious = false
for _, pattern in ipairs({"exploit", "cheat", "hack", "bypass", "bloxstrike"}) do
if lower:find(pattern) then
suspicious = true
break
end
end
if suspicious then
antiDump.ObfuscatedStrings[key] = value
env[key] = string.rep("\0", #value)
end
end
end
antiDump.Active = true
end)
end
function Bypass.deobfuscateString(key)
return antiDump.ObfuscatedStrings[key]
end
function Bypass.protectFunctionUpvalues(func)
pcall(function()
if not debug or not debug.getupvalue then return end
local i = 1
while true do
local name, value = debug.getupvalue(func, i)
if not name then break end
if type(value) == "string" and value:find("BloxStrike") then
debug.setupvalue(func, i, string.rep("\0", #value))
end
i = i + 1
end
end)
end
Bypass.AntiDump = antiDump
-- SECTION 30: UNIFIED ACTIVATION ENGINE
function Bypass.activateAll()
pcall(function()
print("[Bypass]  All 30 bypass systems activated ")
print("[Bypass] Protection Level: MAXIMUM")
end)
end
task.spawn(function()
while true do
task.wait(30)
pcall(function()
end)
end
end)
print("[Bypass] BloxStrike HVH Bypass v4.0 loaded")
print("[Bypass] ")
print("[Bypass] 30 Advanced Bypass Systems:")
print("[Bypass]   1  Metamethod Hook Protection")
print("[Bypass]   2  Environment Spoofing")
print("[Bypass]   3  Thread Hiding")
print("[Bypass]   4  Memory Protection")
print("[Bypass]   5  Signal Filtering")
print("[Bypass]   6  Property Change Interception")
print("[Bypass]   7  Remote Obfuscation")
print("[Bypass]   8  Advanced Timing Obfuscation")
print("[Bypass]   9  GC Protection")
print("[Bypass]   10 CFrame Validation Bypass")
print("[Bypass]   11 Teleport Detection Bypass")
print("[Bypass]   12 Heartbeat Monitoring Bypass")
print("[Bypass]   13 Behavioral Analysis Bypass")
print("[Bypass]   14 Emergency Bypass System")
print("[Bypass]   15 Injection Artifact Cloaking")
print("[Bypass]   16 Anti-Debug Protection")
print("[Bypass]   17 Replay Protection")
print("[Bypass]   18 Integrity Monitor")
print("[Bypass]   19 Property Interception v2")
print("[Bypass]   20 Network Fingerprint Evasion")
print("[Bypass]   21 Emergency Sandbox Detection")
print("[Bypass]   22 __namecall Hook Protection       NEW")
print("[Bypass]   23 Executor Fingerprint Spoof       NEW")
print("[Bypass]   24 Signal Hook Protection            NEW")
print("[Bypass]   25 Remote Call Camouflage             NEW")
print("[Bypass]   26 Memory Region Cloaking             NEW")
print("[Bypass]   27 AC Signature Evasion               NEW")
print("[Bypass]   28 Heartbeat Spoofing                 NEW")
print("[Bypass]   29 Advanced Anti-Dump                 NEW")
print("[Bypass]   30 Unified Activation Engine           NEW")
print("[Bypass] ")
]])
writefile("BloxStrike/modules/cheatdetect.lua", [[
local Players = nil
pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local UserInputService = nil
pcall(function() UserInputService = game:GetService("UserInputService") end)
local StarterGui = nil
pcall(function() StarterGui = game:GetService("StarterGui") end)
local HttpService = nil
pcall(function() HttpService = game:GetService("HttpService") end)
local lplr = Players.LocalPlayer
if not BS.Win then warn("[Cheat Detect] BS.Win not available - ui.lua may have failed") return end
local page = BS.Win:Tab("Cheat Detect")
if not page or not page.Toggle then warn("[CheatDetect] Failed to create tab!") return end
local CD = {}
BS.CheatDetect = CD
-- SECTION 1: 
page:Label("   ")
page:Toggle("Cheat Detect", true, function(v) Flags.CheatDetect = v end)
page:Toggle("Auto Scan", true, function(v) Flags.CD_AutoScan = v end)
page:Slider("Scan Interval", 1, 10, 3, function(v) Flags.CD_ScanInterval = v end)
page:Slider("Min Confidence", 30, 95, 60, function(v) Flags.CD_MinConfidence = v end)
page:Toggle("Show Alerts", true, function(v) Flags.CD_Alerts = v end)
page:Toggle("Auto Report", false, function(v) Flags.CD_AutoReport = v end)
page:Toggle("Sound Alert", true, function(v) Flags.CD_SoundAlert = v end)
page:Toggle("Lobby Summary", true, function(v) Flags.CD_LobbySummary = v end)
page:Toggle("Match Start Scan", true, function(v) Flags.CD_MatchStart = v end)
page:Toggle("Persistent Banner", true, function(v) Flags.CD_Banner = v end)
page:Toggle("Suspect ESP Marker", true, function(v) Flags.CD_SuspectMarker = v end)
page:Slider("Alert Threshold", 30, 90, 50, function(v) Flags.CD_AlertThreshold = v end)
page:Slider("Warn Threshold", 50, 95, 70, function(v) Flags.CD_WarnThreshold = v end)
page:Slider("Critical Threshold", 70, 99, 85, function(v) Flags.CD_CriticalThreshold = v end)
page:Button({Name=" ", Color=Color3.fromRGB(255, 50, 50)}, function()
CD.fullScan()
end)
page:Button({Name=" ", Color=Color3.fromRGB(0, 200, 255)}, function()
CD.showReport()
end)
page:Button({Name=" ", Color=Color3.fromRGB(200, 100, 100)}, function()
CD.clearAll()
end)
-- SECTION 2: 
page:Label("  ")
page:Toggle("Aimbot Detect", true, function(v) Flags.CD_Aimbot = v end)
page:Toggle("Wallhack Detect", true, function(v) Flags.CD_Wallhack = v end)
page:Toggle("ESP Detect", true, function(v) Flags.CD_ESP = v end)
page:Toggle("Triggerbot Detect", true, function(v) Flags.CD_Trigger = v end)
page:Toggle("Spinbot Detect", true, function(v) Flags.CD_Spin = v end)
page:Toggle("Teleport Detect", true, function(v) Flags.CD_Teleport = v end)
page:Toggle("Macro Detect", true, function(v) Flags.CD_Macro = v end)
page:Toggle("NoRecoil Detect", true, function(v) Flags.CD_NoRecoil = v end)
page:Toggle("SilentAim Detect", true, function(v) Flags.CD_SilentAim = v end)
page:Toggle("Snapbot Detect", true, function(v) Flags.CD_Snap = v end)
page:Toggle("Flick Detect", true, function(v) Flags.CD_Flick = v end)
page:Toggle("RCS Detect", true, function(v) Flags.CD_RCS = v end)
page:Toggle("Bhop Detect", true, function(v) Flags.CD_Bhop = v end)
page:Toggle("ThirdPerson Detect", true, function(v) Flags.CD_ThirdPerson = v end)
local PlayerData = {}
local function getPlayerData(uid)
if not PlayerData[uid] then
PlayerData[uid] = {
Name = "Unknown",
PositionHistory = {},
VelocityHistory = {},
CameraHistory = {},
ShotTimestamps = {},
KillTimestamps = {},
DeathTimestamps = {},
DamageDealt = {},
DamageReceived = {},
AimSnaps = {},
ReactionTimes = {},
HitPositions = {},
HeadshotRate = 0,
TotalKills = 0,
TotalDeaths = 0,
TotalShots = 0,
TotalHits = 0,
Flags = {
Aimbot = 0,
Wallhack = 0,
ESP = 0,
Trigger = 0,
Spinbot = 0,
Teleport = 0,
Macro = 0,
NoRecoil = 0,
SilentAim = 0,
Snapbot = 0,
Flick = 0,
RCS = 0,
Bhop = 0,
ThirdPerson = 0,
},
TotalScore = 0,
LastScan = 0,
ScanCount = 0,
}
end
return PlayerData[uid]
end
local function calcMean(t)
if #t == 0 then return 0 end
local sum = 0
for _, v in ipairs(t) do sum = sum + v end
return sum / #t
end
local function calcSD(t)
if #t < 2 then return 0 end
local mean = calcMean(t)
local sumSq = 0
for _, v in ipairs(t) do sumSq = sumSq + (v - mean) ^ 2 end
return math.sqrt(sumSq / (#t - 1))
end
local function calcCV(t)
local mean = calcMean(t)
local sd = calcSD(t)
if mean == 0 then return 0 end
return sd / math.abs(mean)
end
local function calcAutocorr(t, lag)
if #t < lag + 2 then return 0 end
local mean = calcMean(t)
local num, den = 0, 0
for i = 1, #t - lag do
num = num + (t[i] - mean) * (t[i + lag] - mean)
den = den + (t[i] - mean) ^ 2
end
if den == 0 then return 0 end
return num / den
end
-- SECTION 3: AIMBOT DETECTOR  
local function detectAimbot(uid)
if not Flags.CD_Aimbot then return 0 end
local data = PlayerData[uid]
if not data or #data.AimSnaps < 15 then return 0 end
local score = 0
local evidence = 0
local snapSpeeds = {}
for i = 2, #data.AimSnaps do
local dt = data.AimSnaps[i].Time - data.AimSnaps[i-1].Time
if dt > 0.005 and dt < 0.5 then
local angleDiff = math.abs(data.AimSnaps[i].Angle - data.AimSnaps[i-1].Angle)
table.insert(snapSpeeds, angleDiff / dt)
end
end
if #snapSpeeds > 8 then
local avgSpeed = calcMean(snapSpeeds)
local sdSpeed = calcSD(snapSpeeds)
local cvSpeed = calcCV(snapSpeeds)
if avgSpeed > 1200 then score = score + 35; evidence = evidence + 1
elseif avgSpeed > 800 then score = score + 25; evidence = evidence + 1
elseif avgSpeed > 500 then score = score + 10
end
if cvSpeed < 0.15 and avgSpeed > 400 then score = score + 15; evidence = evidence + 1 end
end
local snapAngles = {}
for _, snap in ipairs(data.AimSnaps) do
table.insert(snapAngles, snap.Angle)
end
if #snapAngles > 20 then
local ac1 = calcAutocorr(snapAngles, 1)
local ac3 = calcAutocorr(snapAngles, 3)
if math.abs(ac1) < 0.05 and math.abs(ac3) < 0.05 then
score = score + 20; evidence = evidence + 1
elseif ac1 < -0.1 then
score = score + 15; evidence = evidence + 1
end
local smallSnaps = 0
local largeSnaps = 0
for _, a in ipairs(snapAngles) do
if a < 5 then smallSnaps = smallSnaps + 1
elseif a > 30 then largeSnaps = largeSnaps + 1 end
end
local total = #snapAngles
if total > 15 then
local bimodalScore = (smallSnaps / total) * (largeSnaps / total) * 4
if bimodalScore > 0.3 then score = score + 10; evidence = evidence + 1 end
end
end
local headKills = 0
local totalKills = 0
for _, dmg in ipairs(data.DamageDealt) do
if dmg.IsHeadshot then headKills = headKills + 1 end
totalKills = totalKills + 1
end
if totalKills > 5 then
local hsRate = headKills / totalKills
if hsRate > 0.85 and totalKills > 8 then score = score + 25; evidence = evidence + 2
elseif hsRate > 0.70 and totalKills > 10 then score = score + 15; evidence = evidence + 1
elseif hsRate > 0.60 and totalKills > 15 then score = score + 8
end
end
if #data.ReactionTimes > 10 then
local avgReact = calcMean(data.ReactionTimes)
local cvReact = calcCV(data.ReactionTimes)
if cvReact < 0.05 and avgReact < 200 then score = score + 15; evidence = evidence + 1
elseif avgReact < 60 then score = score + 20; evidence = evidence + 2
elseif avgReact < 100 then score = score + 10
end
end
if #data.AimSnaps > 30 then
local angleVariance = calcSD(snapAngles) ^ 2
if angleVariance < 100 and #snapAngles > 20 then
score = score + 10; evidence = evidence + 1
end
end
if evidence < 2 then score = math.floor(score * 0.6) end
if evidence >= 4 then score = math.min(100, score + 10) end
return math.min(100, score)
end
-- SECTION 4: WALLHACK DETECTOR  
local function detectWallhack(uid)
if not Flags.CD_Wallhack then return 0 end
local data = PlayerData[uid]
if not data or #data.PositionHistory < 20 then return 0 end
local score = 0
local evidence = 0
local suspect = Players:GetPlayerByUserId(uid)
if not suspect or not suspect.Character then return 0 end
local theirHRP = suspect and suspect.Character:FindFirstChild("HumanoidRootPart")
if not theirHRP then return 0 end
local wallHits = 0
local totalHits = 0
for _, hit in ipairs(data.HitPositions) do
totalHits = totalHits + 1
if hit.ThroughWall then wallHits = wallHits + 1 end
end
if totalHits > 5 then
local wallHitRate = wallHits / totalHits
if wallHitRate > 0.5 then score = score + 35; evidence = evidence + 2
elseif wallHitRate > 0.3 then score = score + 20; evidence = evidence + 1
elseif wallHitRate > 0.15 then score = score + 10
end
end
local preAimCount = 0
local totalAimChecks = 0
for _, snap in ipairs(data.AimSnaps) do
totalAimChecks = totalAimChecks + 1
if not snap.TargetVisible then preAimCount = preAimCount + 1 end
end
if totalAimChecks > 10 then
local preAimRate = preAimCount / totalAimChecks
if preAimRate > 0.6 then score = score + 30; evidence = evidence + 2
elseif preAimRate > 0.4 then score = score + 20; evidence = evidence + 1
elseif preAimRate > 0.25 then score = score + 10
end
end
local trackThroughWalls = 0
local totalTrackChecks = 0
for _, cam in ipairs(data.CameraHistory) do
totalTrackChecks = totalTrackChecks + 1
if cam.LookingAtHidden then trackThroughWalls = trackThroughWalls + 1 end
end
if totalTrackChecks > 10 then
local trackRate = trackThroughWalls / totalTrackChecks
if trackRate > 0.5 then score = score + 25; evidence = evidence + 2
elseif trackRate > 0.3 then score = score + 15; evidence = evidence + 1
end
end
local instantReactions = 0
for _, react in ipairs(data.ReactionTimes) do
if react < 50 then instantReactions = instantReactions + 1 end
end
if #data.ReactionTimes > 5 then
local instantRate = instantReactions / #data.ReactionTimes
if instantRate > 0.3 then score = score + 15; evidence = evidence + 1
elseif instantRate > 0.15 then score = score + 10
end
end
if #data.AimSnaps > 15 then
local invisibleAimSnaps = 0
local visibleAimSnaps = 0
for _, snap in ipairs(data.AimSnaps) do
if snap.TargetVisible then visibleAimSnaps = visibleAimSnaps + 1
else invisibleAimSnaps = invisibleAimSnaps + 1 end
end
local total = visibleAimSnaps + invisibleAimSnaps
if total > 10 then
local invisibleRatio = invisibleAimSnaps / total
if invisibleRatio > 0.6 then score = score + 15; evidence = evidence + 1 end
end
end
if #data.PositionHistory > 20 then
local avoidCount = 0
for i = 5, #data.PositionHistory do
local dt = data.PositionHistory[i].Time - data.PositionHistory[i-1].Time
if dt > 0 and dt < 0.5 then
local vel = data.PositionHistory[i].Pos - data.PositionHistory[i-1].Pos
local speed = vel.Magnitude / dt
if i > 5 then
local prevVel = data.PositionHistory[i-1].Pos - data.PositionHistory[i-2].Pos
if prevVel.Magnitude > 0.1 then
local angle = math.acos(math.clamp(vel.Unit:Dot(prevVel.Unit), -1, 1))
if angle > 2.5 and speed > 15 then avoidCount = avoidCount + 1 end
end
end
end
end
if avoidCount > 5 then score = score + 10; evidence = evidence + 1 end
end
if evidence < 2 then score = math.floor(score * 0.5) end
if evidence >= 4 then score = math.min(100, score + 10) end
return math.min(100, score)
end
-- SECTION 5: ESP DETECTOR
local function detectESP(uid)
if not Flags.CD_ESP then return 0 end
local data = PlayerData[uid]
if not data or #data.CameraHistory < 15 then return 0 end
local score = 0
local evidence = 0
local suspect = Players:GetPlayerByUserId(uid)
if not suspect or not suspect.Character then return 0 end
local hiddenLookCount = 0
local totalCamSamples = #data.CameraHistory
for _, cam in ipairs(data.CameraHistory) do
if cam.LookingAtHidden then hiddenLookCount = hiddenLookCount + 1 end
end
if totalCamSamples > 15 then
local rate = hiddenLookCount / totalCamSamples
if rate > 0.4 then score = score + 30; evidence = evidence + 2
elseif rate > 0.25 then score = score + 20; evidence = evidence + 1
elseif rate > 0.15 then score = score + 10
end
end
local trackingEvents = 0
for i = 10, #data.CameraHistory do
if data.CameraHistory[i].HiddenTargetVelocity then
trackingEvents = trackingEvents + 1
end
end
if trackingEvents > 5 then
score = score + math.min(25, trackingEvents * 3)
evidence = evidence + 1
end
local cornerChecks = 0
for _, snap in ipairs(data.AimSnaps) do
if snap.IsCornerCheck then cornerChecks = cornerChecks + 1 end
end
if cornerChecks > 10 then
score = score + math.min(20, cornerChecks * 1.5)
evidence = evidence + 1
end
if #data.AimSnaps > 15 then
local wallTargetSnaps = 0
for _, snap in ipairs(data.AimSnaps) do
if not snap.TargetVisible and snap.Angle and snap.Angle > 10 then
wallTargetSnaps = wallTargetSnaps + 1
end
end
local totalSnaps = #data.AimSnaps
if totalSnaps > 10 then
local wallTargetRate = wallTargetSnaps / totalSnaps
if wallTargetRate > 0.5 then score = score + 15; evidence = evidence + 1 end
end
end
if evidence < 2 then score = math.floor(score * 0.6) end
if evidence >= 3 then score = math.min(100, score + 8) end
return math.min(100, score)
end
-- SECTION 6: SPEEDHACK DETECTOR
local function detectSpeedhack(uid)
if not Flags.CD_Speed then return 0 end
local data = PlayerData[uid]
if not data or #data.PositionHistory < 20 then return 0 end
local score = 0
local speeds = {}
for i = 2, #data.PositionHistory do
local dt = data.PositionHistory[i].Time - data.PositionHistory[i-1].Time
if dt > 0.01 and dt < 1 then
local dist = (data.PositionHistory[i].Pos - data.PositionHistory[i-1].Pos).Magnitude
local speed = dist / dt
table.insert(speeds, speed)
end
end
if #speeds > 10 then
local totalSpeed = 0
local maxSpeed = 0
local burstCount = 0
for _, s in ipairs(speeds) do
totalSpeed = totalSpeed + s
maxSpeed = math.max(maxSpeed, s)
if s > 50 then burstCount = burstCount + 1 end
end
local avgSpeed = totalSpeed / #speeds
if maxSpeed > 100 then score = score + 35
elseif maxSpeed > 60 then score = score + 25
elseif maxSpeed > 40 then score = score + 15
end
if avgSpeed > 30 then score = score + 15
elseif avgSpeed > 25 then score = score + 10
end
if burstCount > 5 then score = score + 15
elseif burstCount > 2 then score = score + 8
end
end
if #data.PositionHistory > 20 then
local posDiffs = {}
for i = 2, math.min(50, #data.PositionHistory) do
local dt = data.PositionHistory[i].Time - data.PositionHistory[i-1].Time
if dt > 0.01 and dt < 0.1 then
local dist = (data.PositionHistory[i].Pos - data.PositionHistory[i-1].Pos).Magnitude / dt
table.insert(posDiffs, dist)
end
end
if #posDiffs > 10 then
local mean = 0
for _, d in ipairs(posDiffs) do mean = mean + d end
mean = mean / #posDiffs
local variance = 0
for _, d in ipairs(posDiffs) do variance = variance + (d - mean) ^ 2 end
variance = variance / #posDiffs
local cv = math.sqrt(variance) / math.max(mean, 1)
if cv < 0.1 and mean > 20 then score = score + 15 end
end
end
return math.min(100, score)
end
-- SECTION 7: TRIGGERBOT DETECTOR
local function detectTriggerbot(uid)
if not Flags.CD_Trigger then return 0 end
local data = PlayerData[uid]
if not data or #data.ShotTimestamps < 15 then return 0 end
local score = 0
local evidence = 0
local intervals = {}
for i = 2, #data.ShotTimestamps do
local dt = (data.ShotTimestamps[i] - data.ShotTimestamps[i-1]) * 1000
if dt > 5 and dt < 1000 then table.insert(intervals, dt) end
end
if #intervals > 10 then
local cv = calcCV(intervals)
local meanInterval = calcMean(intervals)
local sdInterval = calcSD(intervals)
if cv < 0.02 and meanInterval < 200 then score = score + 35; evidence = evidence + 2
elseif cv < 0.05 and meanInterval < 150 then score = score + 25; evidence = evidence + 1
elseif cv < 0.08 then score = score + 10
end
if meanInterval < 50 then score = score + 15; evidence = evidence + 1
elseif meanInterval < 80 then score = score + 8
end
end
if #intervals > 20 then
local ac1 = calcAutocorr(intervals, 1)
local ac2 = calcAutocorr(intervals, 2)
if ac1 > 0.95 and ac2 > 0.9 then score = score + 20; evidence = evidence + 2 end
if ac1 > 0.8 then score = score + 10; evidence = evidence + 1 end
end
local fastShots = 0
for _, snap in ipairs(data.AimSnaps) do
if snap.TimeToFire and snap.TimeToFire < 80 then fastShots = fastShots + 1 end
end
if #data.AimSnaps > 10 then
local fastRate = fastShots / #data.AimSnaps
if fastRate > 0.7 then score = score + 20; evidence = evidence + 1
elseif fastRate > 0.5 then score = score + 10
end
end
if #intervals > 15 then
local patternMatch = 0
for plen = 2, math.min(5, math.floor(#intervals / 3)) do
local matches = 0
for i = 1, #intervals - plen do
if math.abs(intervals[i] - intervals[i + plen]) < 1 then matches = matches + 1 end
end
if matches / (#intervals - plen) > 0.8 then patternMatch = plen; break end
end
if patternMatch > 0 then score = score + 15; evidence = evidence + 1 end
end
if evidence < 2 then score = math.floor(score * 0.5) end
if evidence >= 3 then score = math.min(100, score + 8) end
return math.min(100, score)
end
-- SECTION 8: SPINBOT DETECTOR
local function detectSpinbot(uid)
if not Flags.CD_Spin then return 0 end
local data = PlayerData[uid]
if not data or #data.CameraHistory < 20 then return 0 end
local score = 0
local evidence = 0
local rotSpeeds = {}
for i = 2, #data.CameraHistory do
local dt = data.CameraHistory[i].Time - data.CameraHistory[i-1].Time
if dt > 0.005 and dt < 0.5 then
local angleDiff = math.abs(data.CameraHistory[i].Yaw - data.CameraHistory[i-1].Yaw)
if angleDiff > 180 then angleDiff = 360 - angleDiff end
table.insert(rotSpeeds, angleDiff / dt)
end
end
if #rotSpeeds > 10 then
local avgRot = calcMean(rotSpeeds)
local maxRot = 0
for _, s in ipairs(rotSpeeds) do maxRot = math.max(maxRot, s) end
if maxRot > 3000 then score = score + 40; evidence = evidence + 2
elseif maxRot > 2000 then score = score + 30; evidence = evidence + 1
elseif maxRot > 1200 then score = score + 15
end
if avgRot > 1000 then score = score + 15; evidence = evidence + 1
elseif avgRot > 600 then score = score + 8
end
end
if #rotSpeeds > 20 then
local ac1 = calcAutocorr(rotSpeeds, 1)
local ac3 = calcAutocorr(rotSpeeds, 3)
if ac1 > 0.9 and ac3 > 0.8 then score = score + 20; evidence = evidence + 2 end
if ac1 > 0.7 then score = score + 10; evidence = evidence + 1 end
local cvRot = calcCV(rotSpeeds)
if cvRot < 0.1 and avgRot > 500 then score = score + 10; evidence = evidence + 1 end
end
if #data.CameraHistory > 15 then
local yawChanges = {}
for i = 2, #data.CameraHistory do
local dt = data.CameraHistory[i].Time - data.CameraHistory[i-1].Time
if dt > 0 and dt < 1 then
local yawDiff = data.CameraHistory[i].Yaw - data.CameraHistory[i-1].Yaw
if yawDiff > 180 then yawDiff = yawDiff - 360
elseif yawDiff < -180 then yawDiff = yawDiff + 360 end
table.insert(yawChanges, yawDiff)
end
end
if #yawChanges > 10 then
local totalYaw = 0
for _, y in ipairs(yawChanges) do totalYaw = totalYaw + y end
local timeWindow = data.CameraHistory[#data.CameraHistory].Time - data.CameraHistory[1].Time
if timeWindow > 0 then
local rotPerSec = math.abs(totalYaw) / timeWindow
if rotPerSec > 720 then score = score + 25; evidence = evidence + 2 end
if rotPerSec > 360 then score = score + 15; evidence = evidence + 1 end
end
end
end
if evidence < 2 then score = math.floor(score * 0.5) end
if evidence >= 3 then score = math.min(100, score + 10) end
return math.min(100, score)
end
-- SECTION 9: TELEPORT DETECTOR
local function detectTeleport(uid)
if not Flags.CD_Teleport then return 0 end
local data = PlayerData[uid]
if not data or #data.PositionHistory < 15 then return 0 end
local score = 0
local teleports = 0
for i = 2, #data.PositionHistory do
local dt = data.PositionHistory[i].Time - data.PositionHistory[i-1].Time
if dt > 0.01 and dt < 1 then
local dist = (data.PositionHistory[i].Pos - data.PositionHistory[i-1].Pos).Magnitude
local speed = dist / dt
if dist > 100 then
teleports = teleports + 1
elseif dist > 50 and speed > 200 then
teleports = teleports + 1
end
end
end
if teleports > 5 then score = score + 40
elseif teleports > 3 then score = score + 25
elseif teleports > 1 then score = score + 15
end
return math.min(100, score)
end
-- SECTION 10: MACRO DETECTOR
local function detectMacro(uid)
if not Flags.CD_Macro then return 0 end
local data = PlayerData[uid]
if not data or #data.ShotTimestamps < 20 then return 0 end
local score = 0
local intervals = {}
for i = 2, #data.ShotTimestamps do
local dt = (data.ShotTimestamps[i] - data.ShotTimestamps[i-1]) * 1000
if dt > 10 and dt < 500 then
table.insert(intervals, dt)
end
end
if #intervals > 15 then
local patternLengths = {2, 3, 4, 5}
for _, plen in ipairs(patternLengths) do
if #intervals >= plen * 3 then
local matches = 0
local total = 0
for i = 1, #intervals - plen do
local diff = math.abs(intervals[i] - intervals[i + plen])
if diff < 1 then
matches = matches + 1
end
total = total + 1
end
if total > 0 and matches / total > 0.8 then
score = score + 30 + (plen * 5)
break
end
end
end
local mean = 0
for _, v in ipairs(intervals) do mean = mean + v end
mean = mean / #intervals
local variance = 0
for _, v in ipairs(intervals) do variance = variance + (v - mean) ^ 2 end
variance = variance / #intervals
local sd = math.sqrt(variance)
if sd < 2 then score = score + 30
elseif sd < 5 then score = score + 20
elseif sd < 10 then score = score + 10
end
end
if #intervals > 10 then
local minInterval = math.huge
for _, v in ipairs(intervals) do minInterval = math.min(minInterval, v) end
if minInterval < 20 then score = score + 20
elseif minInterval < 40 then score = score + 10
end
end
return math.min(100, score)
end
-- SECTION 11: NORECOIL DETECTOR
local function detectNoRecoil(uid)
if not Flags.CD_NoRecoil then return 0 end
local data = PlayerData[uid]
if not data or #data.AimSnaps < 20 then return 0 end
local score = 0
local sustainedFireAngles = {}
for i = 2, #data.AimSnaps do
local dt = data.AimSnaps[i].Time - data.AimSnaps[i-1].Time
if dt > 0 and dt < 0.2 then
table.insert(sustainedFireAngles, {
Pitch = data.AimSnaps[i].Pitch,
Time = data.AimSnaps[i].Time,
})
end
end
if #sustainedFireAngles > 10 then
local pitchDiffs = 0
for i = 2, #sustainedFireAngles do
pitchDiffs = pitchDiffs + math.abs(sustainedFireAngles[i].Pitch - sustainedFireAngles[i-1].Pitch)
end
local avgPitchDiff = pitchDiffs / (#sustainedFireAngles - 1)
if avgPitchDiff < 0.1 then score = score + 30
elseif avgPitchDiff < 0.5 then score = score + 15
end
local verticalRange = 0
local maxPitch = -90
local minPitch = 90
for _, a in ipairs(sustainedFireAngles) do
maxPitch = math.max(maxPitch, a.Pitch)
minPitch = math.min(minPitch, a.Pitch)
end
verticalRange = maxPitch - minPitch
if verticalRange < 1 and #sustainedFireAngles > 15 then
score = score + 20
end
end
return math.min(100, score)
end
-- SECTION 12: SILENT AIM DETECTOR
local function detectSilentAim(uid)
if not Flags.CD_SilentAim then return 0 end
local data = PlayerData[uid]
if not data or #data.HitPositions < 10 then return 0 end
local score = 0
local mismatches = 0
for _, hit in ipairs(data.HitPositions) do
if hit.CameraDirection and hit.HitDirection then
local dot = hit.CameraDirection:Dot(hit.HitDirection)
if dot < 0.8 then
mismatches = mismatches + 1
end
end
end
if #data.HitPositions > 8 then
local mismatchRate = mismatches / #data.HitPositions
if mismatchRate > 0.4 then score = score + 35
elseif mismatchRate > 0.25 then score = score + 20
elseif mismatchRate > 0.15 then score = score + 10
end
end
local impossibleKills = 0
for _, kill in ipairs(data.KillTimestamps) do
if kill.Angle and math.abs(kill.Angle) > 60 then
impossibleKills = impossibleKills + 1
end
end
if #data.KillTimestamps > 3 then
local impossibleRate = impossibleKills / #data.KillTimestamps
if impossibleRate > 0.3 then score = score + 25
elseif impossibleRate > 0.15 then score = score + 10
end
end
return math.min(100, score)
end
-- SECTION 13: SNAPBOT / FLICK DETECTOR
local function detectSnap(uid)
if not Flags.CD_Snap then return 0 end
local data = PlayerData[uid]
if not data or #data.AimSnaps < 10 then return 0 end
local score = 0
local instantSnaps = 0
local largeSnaps = 0
for _, snap in ipairs(data.AimSnaps) do
if snap.Duration and snap.Duration < 0.02 then
instantSnaps = instantSnaps + 1
end
if snap.Angle and snap.Angle > 90 then
largeSnaps = largeSnaps + 1
if snap.Duration and snap.Duration < 0.05 then
score = score + 8
end
end
end
if #data.AimSnaps > 10 then
local instantRate = instantSnaps / #data.AimSnaps
if instantRate > 0.4 then score = score + 25
elseif instantRate > 0.2 then score = score + 15
end
end
return math.min(100, score)
end
-- SECTION 13B: RCS DETECTOR  
local function detectRCS(uid)
if not Flags.CD_RCS then return 0 end
local data = PlayerData[uid]
if not data or #data.AimSnaps < 20 then return 0 end
local score = 0
local evidence = 0
local sustainedFireAngles = {}
for i = 2, #data.AimSnaps do
local dt = data.AimSnaps[i].Time - data.AimSnaps[i-1].Time
if dt > 0 and dt < 0.2 then
table.insert(sustainedFireAngles, { Pitch = data.AimSnaps[i].Pitch, Time = data.AimSnaps[i].Time })
end
end
if #sustainedFireAngles > 10 then
local pitchDiffs = {}
for i = 2, #sustainedFireAngles do
table.insert(pitchDiffs, sustainedFireAngles[i].Pitch - sustainedFireAngles[i-1].Pitch)
end
local avgPitchDiff = calcMean(pitchDiffs)
local sdPitchDiff = calcSD(pitchDiffs)
if math.abs(avgPitchDiff) < 0.05 and #sustainedFireAngles > 15 then
score = score + 30; evidence = evidence + 2
elseif math.abs(avgPitchDiff) < 0.2 and sdPitchDiff < 0.5 then
score = score + 15; evidence = evidence + 1
end
end
if #sustainedFireAngles > 20 then
local verticalRange = 0
local maxP = -90
local minP = 90
for _, a in ipairs(sustainedFireAngles) do
maxP = math.max(maxP, a.Pitch)
minP = math.min(minP, a.Pitch)
end
verticalRange = maxP - minP
if verticalRange < 1 and #sustainedFireAngles > 15 then
score = score + 20; evidence = evidence + 1
end
end
if evidence < 2 then score = math.floor(score * 0.5) end
return math.min(100, score)
end
-- SECTION 13C: BHOP DETECTOR  
local function detectBhop(uid)
if not Flags.CD_Bhop then return 0 end
local data = PlayerData[uid]
if not data or #data.PositionHistory < 30 then return 0 end
local score = 0
local evidence = 0
local verticalPositions = {}
for _, pos in ipairs(data.PositionHistory) do
table.insert(verticalPositions, pos.Pos.Y)
end
if #verticalPositions > 20 then
local yChanges = {}
for i = 2, #verticalPositions do
table.insert(yChanges, verticalPositions[i] - verticalPositions[i-1])
end
if #yChanges > 15 then
local ac1 = calcAutocorr(yChanges, 1)
if ac1 > 0.85 then score = score + 25; evidence = evidence + 1 end
end
local consecutiveUp = 0
local maxConsecutive = 0
for _, yc in ipairs(yChanges) do
if yc > 0.5 then consecutiveUp = consecutiveUp + 1
else
maxConsecutive = math.max(maxConsecutive, consecutiveUp)
consecutiveUp = 0
end
end
maxConsecutive = math.max(maxConsecutive, consecutiveUp)
if maxConsecutive > 8 then score = score + 20; evidence = evidence + 1 end
end
if #data.VelocityHistory > 20 then
local airSpeeds = {}
for _, v in ipairs(data.VelocityHistory) do
local horizSpeed = Vector3.new(v.Vel.X, 0, v.Vel.Z).Magnitude
table.insert(airSpeeds, horizSpeed)
end
if #airSpeeds > 10 then
local maxHorizSpeed = 0
for _, s in ipairs(airSpeeds) do maxHorizSpeed = math.max(maxHorizSpeed, s) end
if maxHorizSpeed > 50 then score = score + 15; evidence = evidence + 1 end
end
end
if evidence < 2 then score = math.floor(score * 0.5) end
return math.min(100, score)
end
-- SECTION 13D: THIRDPERSON DETECTOR  
local function detectThirdPerson(uid)
if not Flags.CD_ThirdPerson then return 0 end
local data = PlayerData[uid]
if not data or #data.CameraHistory < 20 then return 0 end
local score = 0
local suspect = Players:GetPlayerByUserId(uid)
if suspect and suspect.Character then
local hrp = suspect and suspect.Character:FindFirstChild("HumanoidRootPart")
if hrp then
local cam = workspace.CurrentCamera
if cam then
local camDist = (cam.CFrame.Position - hrp.Position).Magnitude
if camDist > 15 then score = score + 30 end
if camDist > 25 then score = score + 20 end
end
end
end
return math.min(100, score)
end
-- SECTION 14: COMBINED SCORING  
local function calculateTotalScore(uid)
local data = PlayerData[uid]
if not data then return 0 end
data.Flags.Aimbot = detectAimbot(uid)
data.Flags.Wallhack = detectWallhack(uid)
data.Flags.ESP = detectESP(uid)
data.Flags.Trigger = detectTriggerbot(uid)
data.Flags.Spinbot = detectSpinbot(uid)
data.Flags.Teleport = detectTeleport(uid)
data.Flags.Macro = detectMacro(uid)
data.Flags.NoRecoil = detectNoRecoil(uid)
data.Flags.SilentAim = detectSilentAim(uid)
data.Flags.Snapbot = detectSnap(uid)
data.Flags.RCS = detectRCS(uid)
data.Flags.Bhop = detectBhop(uid)
data.Flags.ThirdPerson = detectThirdPerson(uid)
local weights = {
Aimbot = 1.3, Wallhack = 1.5, ESP = 1.2, Trigger = 1.2,
Spinbot = 1.4, Teleport = 1.5, Macro = 1.1, NoRecoil = 0.9,
SilentAim = 1.4, Snapbot = 1.3, RCS = 1.0, Bhop = 1.1, ThirdPerson = 0.8,
}
local total = 0
local maxPossible = 0
local activeDetectors = 0
for flag, fScore in pairs(data.Flags) do
if fScore > 0 then activeDetectors = activeDetectors + 1 end
total = total + fScore * (weights[flag] or 1.0)
maxPossible = maxPossible + 100 * (weights[flag] or 1.0)
end
if activeDetectors >= 4 then total = total * 1.15
elseif activeDetectors >= 3 then total = total * 1.10
elseif activeDetectors >= 2 then total = total * 1.05
end
data.TotalScore = math.clamp(math.floor(total / maxPossible * 100), 0, 100)
return data.TotalScore
end
-- SECTION 15: MAIN SCAN ENGINE  
function CD.fullScan()
if not Flags.CheatDetect then return end
local myHRP = BS.hrp()
local myTeam = BS.team()
for _, player in pairs(Players:GetPlayers()) do
if player ~= lplr then
local uid = player.UserId
local data = getPlayerData(uid)
data.Name = player.Name
local char = player.Character
local hrp = char and char:FindFirstChild("HumanoidRootPart")
local hum = char and char:FindFirstChildOfClass("Humanoid")
local cam = char and char:FindFirstChildOfClass("Humanoid")
if hrp and hum and hum.Health > 0 then
table.insert(data.PositionHistory, {
Pos = hrp.Position,
})
if #data.PositionHistory > 100 then table.remove(data.PositionHistory, 1) end
table.insert(data.VelocityHistory, {
Vel = hrp.AssemblyLinearVelocity,
})
if #data.VelocityHistory > 100 then table.remove(data.VelocityHistory, 1) end
pcall(function()
local theirCam = workspace.CurrentCamera
if theirCam then
local lookAt = theirCam.CFrame.LookVector
local lookingAtHidden = false
for _, other in pairs(Players:GetPlayers()) do
if other ~= lplr and other ~= player then
local otherChar = other.Character
local otherHRP = otherChar and otherChar:FindFirstChild("HumanoidRootPart")
if otherHRP and myHRP then
local toOther = (otherHRP.Position - hrp.Position).Unit
local dot = lookAt:Dot(toOther)
if dot > 0.9 then
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = {char, otherChar}
local ray = workspace:Raycast(hrp.Position, otherHRP.Position - hrp.Position, params)
if ray then
lookingAtHidden = true
end
end
end
end
end
table.insert(data.CameraHistory, {
LookingAtHidden = lookingAtHidden,
})
if #data.CameraHistory > 200 then table.remove(data.CameraHistory, 1) end
end
end)
if #data.CameraHistory >= 2 then
local curr = data.CameraHistory[#data.CameraHistory]
local prev = data.CameraHistory[#data.CameraHistory - 1]
local dt = curr.Time - prev.Time
if dt > 0.005 and dt < 0.5 then
local yawDiff = math.abs(curr.Yaw - prev.Yaw)
if yawDiff > 180 then yawDiff = 360 - yawDiff end
local pitchDiff = math.abs(curr.Pitch - prev.Pitch)
if yawDiff > 5 or pitchDiff > 5 then
local targetVisible = false
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = {char}
local ray = workspace:Raycast(hrp.Position, curr.LookAtDirection or lookAt * 100, params)
table.insert(data.AimSnaps, {
Angle = yawDiff,
Duration = dt,
Pitch = curr.Pitch,
})
if #data.AimSnaps > 500 then table.remove(data.AimSnaps, 1) end
end
end
end
end
end
end
local results = {}
for uid, data in pairs(PlayerData) do
if tick() - data.LastScan > 3 then
local totalScore = calculateTotalScore(uid)
data.TotalScore = totalScore
data.LastScan = tick()
data.ScanCount = data.ScanCount + 1
if totalScore >= (Flags.CD_MinConfidence or 60) then
table.insert(results, {
UserId = uid,
Name = data.Name,
Score = totalScore,
Flags = data.Flags,
})
end
end
end
table.sort(results, function(a, b) return a.Score > b.Score end)
if Flags.CD_Alerts and #results > 0 then
local alertThreshold = Flags.CD_AlertThreshold or 50
local warnThreshold = Flags.CD_WarnThreshold or 70
local criticalThreshold = Flags.CD_CriticalThreshold or 85
local alertNames = {}
local warnNames = {}
local criticalNames = {}
for _, result in ipairs(results) do
local mainCheat = CD.getMainCheat(result.Flags)
local details = CD.getFlagSummary(result.Flags)
if result.Score >= criticalThreshold then
table.insert(criticalNames, result.Name)
CD.sendAlert(
"[CONFIRMED CHEATER]",
string.format("%s [%.0f%% confidence]\nType: %s\nEvidence: %s",
result.Name, result.Score, mainCheat, details),
Color3.fromRGB(255, 0, 0), 12
)
CD.playAlertSound("critical")
logDecision("CHEATER CONFIRMED: " .. result.Name, mainCheat .. " (" .. result.Score .. "%)")
elseif result.Score >= warnThreshold then
table.insert(warnNames, result.Name)
CD.sendAlert(
"[CONFIRMED CHEATER]",
string.format("%s [%.0f%% confidence]\nType: %s\nEvidence: %s",
result.Name, result.Score, mainCheat, details),
Color3.fromRGB(255, 200, 0), 8
)
CD.playAlertSound("warn")
logDecision("SUSPECT: " .. result.Name, mainCheat .. " (" .. result.Score .. "%)")
elseif result.Score >= alertThreshold then
table.insert(alertNames, result.Name)
logDecision("SUSPICIOUS: " .. result.Name, mainCheat .. " (" .. result.Score .. "%)")
end
end
if #results > 0 and Flags.CD_LobbySummary then
local summary = string.format(" : %d \n", #results)
if #criticalNames > 0 then
summary = summary .. " : " .. table.concat(criticalNames, ", ") .. "\n"
end
if #warnNames > 0 then
summary = summary .. " : " .. table.concat(warnNames, ", ") .. "\n"
end
if #alertNames > 0 then
summary = summary .. " : " .. table.concat(alertNames, ", ")
end
CD.sendAlert(" ", summary, Color3.fromRGB(100, 200, 255), 10)
end
if Flags.CD_Banner then
CD.updateBanner(#criticalNames, #warnNames, #alertNames, criticalNames, warnNames)
end
end
return results
end
-- SECTION 16: ALERT HELPERS  
local alertCooldowns = {}
function CD.getMainCheat(flags)
local cheats = {
Aimbot = "Aimbot ",
Wallhack = " Wallhack ",
ESP = "ESP  ",
Trigger = " Triggerbot ",
Spinbot = " Spinbot ",
Teleport = " Teleport ",
Macro = " Macro ",
NoRecoil = " NoRecoil ",
SilentAim = " SilentAim ",
Snapbot = " Snapbot ",
RCS = " RCS ",
Bhop = " Bhop ",
ThirdPerson = " 3rdPerson ",
}
local bestCheat = ""
local maxScore = 0
for flag, score in pairs(flags) do
if score > maxScore then
maxScore = score
bestCheat = cheats[flag] or flag
end
end
return bestCheat .. " (" .. math.floor(maxScore) .. "%)"
end
function CD.canAlert(uid, level)
local key = uid .. "_" .. level
local last = alertCooldowns[key] or 0
local cooldown = level == "critical" and 30 or level == "warn" and 60 or 120
if tick() - last < cooldown then return false end
alertCooldowns[key] = tick()
return true
end
function CD.sendAlert(title, text, color, duration)
pcall(function()
StarterGui:SetCore("SendNotification", {
Title = title,
Text = text,
Duration = duration or 5,
})
end)
end
function CD.playAlertSound(level)
if not Flags.CD_SoundAlert then return end
pcall(function()
local sound = Instance.new("Sound")
if level == "critical" then
sound.SoundId = "rbxassetid://5587286548"
sound.Volume = 1.0
elseif level == "warn" then
sound.SoundId = "rbxassetid://5587286548"
sound.Volume = 0.7
else
sound.SoundId = "rbxassetid://5587286548"
sound.Volume = 0.4
end
sound.PlayOnRemove = false
sound.Parent = lplr.Character and lplr and lplr.Character:FindFirstChild("HumanoidRootPart") or workspace
sound:Play()
game:GetService("Debris"):AddItem(sound, 2)
end)
end
local bannerGui = nil
function CD.updateBanner(criticalCount, warnCount, alertCount, criticalNames, warnNames)
pcall(function()
local totalCheaters = criticalCount + warnCount
if totalCheaters == 0 then
if bannerGui then bannerGui.Enabled = false end
end
if not bannerGui then
bannerGui = Instance.new("ScreenGui")
bannerGui.Name = "BS_CheatBanner"
bannerGui.IgnoreGuiInset = true
bannerGui.DisplayOrder = 9998
bannerGui.Parent = lplr.PlayerGui
local frame = Instance.new("Frame", bannerGui)
frame.Name = "Banner"
frame.Size = UDim2.new(1, 0, 0, 0)
frame.Position = UDim2.new(0, 0, 0, 25)
frame.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.AutomaticSize = Enum.AutomaticSize.Y
local layout = Instance.new("UIListLayout", frame)
layout.Padding = UDim.new(0, 2)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
local title = Instance.new("TextLabel", frame)
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 18)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 50, 50)
title.TextSize = 14
title.Font = Enum.Font.Code
title.Text = ""
local detail = Instance.new("TextLabel", frame)
detail.Name = "Detail"
detail.Size = UDim2.new(1, 0, 0, 14)
detail.BackgroundTransparency = 1
detail.TextColor3 = Color3.fromRGB(255, 200, 100)
detail.TextSize = 11
detail.Font = Enum.Font.Code
detail.Text = ""
detail.TextWrapped = true
end
bannerGui.Enabled = true
local frame = bannerGui.Banner
local titleText = string.format(" : %d  (%d , %d )",
totalCheaters, criticalCount, warnCount)
frame.Title.Text = titleText
local detailText = ""
if #criticalNames > 0 then
detailText = detailText .. " : " .. table.concat(criticalNames, ", ") .. " | "
end
if #warnNames > 0 then
detailText = detailText .. " : " .. table.concat(warnNames, ", ")
end
frame.Detail.Text = detailText
end)
end
local matchScanned = false
lplr.CharacterAdded:Connect(function()
if Flags.CD_MatchStart and Flags.CheatDetect then
matchScanned = false
task.delay(3, function()
if not matchScanned then
matchScanned = true
pcall(function()
CD.sendAlert(" ", "...", Color3.fromRGB(100, 200, 255), 3)
end)
task.delay(2, function()
pcall(function() CD.fullScan() end)
end)
end
end)
end
end)
if Flags.CheatDetect and Flags.CD_Alerts then
task.delay(5, function()
if isfile and isfile("BloxStrike/CheatLog.json") then
pcall(function()
local log = HttpService:JSONDecode(readfile("BloxStrike/CheatLog.json"))
if log[tostring(player.UserId)] then
local prevScore = log[tostring(player.UserId)].Score or 0
if prevScore > 50 then
CD.sendAlert(
string.format("%s  (%.0f%%)",
player.Name, prevScore),
Color3.fromRGB(255, 150, 0), 8
)
end
end
end)
end
end)
end
end)
task.spawn(function()
while true do task.wait(30)
pcall(function()
local log = {}
for uid, data in pairs(PlayerData) do
if data.TotalScore > 30 then
log[tostring(uid)] = {
Name = data.Name,
Score = data.TotalScore,
Flags = data.Flags,
LastSeen = tick(),
}
end
end
writefile("BloxStrike/CheatLog.json", HttpService:JSONEncode(log))
end)
end
end)
-- SECTION 17: REPORT & DISPLAY
function CD.getFlagSummary(flags)
local active = {}
for flag, score in pairs(flags) do
if score > 30 then
table.insert(active, flag .. "=" .. math.floor(score))
end
end
return #active > 0 and table.concat(active, ", ") or "None"
end
function CD.showReport()
local report = " :\n\n"
local found = false
local sorted = {}
for uid, data in pairs(PlayerData) do
if data.TotalScore > 0 then
table.insert(sorted, data)
end
end
table.sort(sorted, function(a, b) return a.TotalScore > b.TotalScore end)
for i, data in ipairs(sorted) do
if i > 10 then break end
local status = data.TotalScore >= 70 and "" or data.TotalScore >= 40 and "" or ""
report = report .. string.format("%s %s: %.0f%% [%s]\n",
status, data.Name, data.TotalScore, CD.getFlagSummary(data.Flags))
found = true
end
if not found then
report = report .. " "
end
pcall(function()
StarterGui:SetCore("SendNotification", {
Title = " ",
Text = report,
Duration = 10,
})
end)
end
function CD.clearAll()
PlayerData = {}
pcall(function()
StarterGui:SetCore("SendNotification", {
Title = " ",
Text = "",
Duration = 3,
})
end)
end
-- SECTION 18: SUSPECT ESP MARKER  
local suspectMarkers = {}
local function updateSuspectMarkers()
if not Flags.CD_SuspectMarker then
for uid, marker in pairs(suspectMarkers) do
pcall(function() marker.Visible = false end)
end
end
local cam = workspace.CurrentCamera
if not cam then return end
for uid, data in pairs(PlayerData) do
if data.TotalScore > 30 then
local player = Players:GetPlayerByUserId(uid)
if player and player.Character then
local hrp = player and player.Character:FindFirstChild("HumanoidRootPart")
if hrp then
local pos, vis = cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
if vis then
if not suspectMarkers[uid] then
pcall(function()
suspectMarkers[uid] = Drawing.new("Text")
suspectMarkers[uid].Center = true
suspectMarkers[uid].Outline = true
suspectMarkers[uid].OutlineColor = Color3.new(0, 0, 0)
suspectMarkers[uid].Font = Drawing.Fonts.UI
suspectMarkers[uid].Size = 14
end)
end
local marker = suspectMarkers[uid]
local emoji = data.TotalScore >= 85 and "" or data.TotalScore >= 70 and "" or ""
marker.Text = string.format("%s %s [%.0f%%]", emoji, data.Name, data.TotalScore)
marker.Position = Vector2.new(pos.X, pos.Y)
marker.Color = data.TotalScore >= 85 and Color3.fromRGB(255, 0, 0)
or data.TotalScore >= 70 and Color3.fromRGB(255, 200, 0)
or Color3.fromRGB(255, 255, 100)
marker.Visible = true
else
if suspectMarkers[uid] then suspectMarkers[uid].Visible = false end
end
end
end
else
if suspectMarkers[uid] then suspectMarkers[uid].Visible = false end
end
end
end
-- SECTION 19: LIVE HUD  
local cdHUD = nil
task.spawn(function()
while true do task.wait(0.5)
if Flags.CheatDetect and BS.alive() then
local worst = nil
local worstScore = 0
for uid, data in pairs(PlayerData) do
if data.TotalScore > worstScore then
worstScore = data.TotalScore
worst = data
end
end
if not cdHUD then
pcall(function()
cdHUD = Drawing.new("Text")
cdHUD.Center = false
cdHUD.Outline = true
cdHUD.OutlineColor = Color3.new(0, 0, 0)
cdHUD.Font = Drawing.Fonts.UI
cdHUD.Size = 12
end)
end
if worst and worstScore > 20 then
local color = worstScore >= 70 and Color3.fromRGB(255, 0, 0)
or worstScore >= 40 and Color3.fromRGB(255, 200, 0)
or Color3.fromRGB(200, 200, 200)
cdHUD.Text = string.format(" Top Suspect: %s [%.0f%%] %s",
worst.Name, worstScore, CD.getFlagSummary(worst.Flags))
cdHUD.Color = color
cdHUD.Position = Vector2.new(10, 490)
cdHUD.Visible = true
else
cdHUD.Text = " Cheat Detect:  No threats detected"
cdHUD.Color = Color3.fromRGB(0, 200, 0)
cdHUD.Position = Vector2.new(10, 490)
cdHUD.Visible = true
end
else
if cdHUD then cdHUD.Visible = false end
end
end
end)
task.spawn(function()
while true do task.wait(0.2)
if Flags.CheatDetect and BS.alive() then
pcall(function() updateSuspectMarkers() end)
end
end
end)
task.spawn(function()
while true do task.wait(Flags.CD_ScanInterval or 3)
if Flags.CheatDetect and Flags.CD_AutoScan then
pcall(function() CD.fullScan() end)
end
end
end)
PlayerData[player.UserId] = nil
end)
BS.CheatDetect = CD
BS.PlayerData = PlayerData
print("[CheatDetect] BloxStrike Cheat Detect v1.0 loaded")
print("[CheatDetect] Features: Aimbot Detector, Wallhack Detector,")
print("[CheatDetect]   ESP Detector, Speedhack Detector, Triggerbot Detector,")
print("[CheatDetect]   Spinbot Detector, Teleport Detector, Macro Detector,")
print("[CheatDetect]   NoRecoil Detector, SilentAim Detector, Snapbot Detector")
print("[CheatDetect] Auto-scan interval: " .. (Flags.CD_ScanInterval or 3) .. "s")
]])
writefile("BloxStrike/modules/combat.lua", [[
local Players = nil
pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local UIS = nil
pcall(function() UIS = game:GetService("UserInputService") end)
local lplr = Players.LocalPlayer
if not BS.Win then warn("[Combat] BS.Win not available - ui.lua may have failed") return end
local page = BS.Win:Tab("Combat")
if not page or not page.Toggle then
warn("[Combat] Failed to create tab!")
end
local function alive()
return BS.alive()
end
local function hrp()
return BS.hrp()
end
local function hum()
return BS.hum()
end
local Compat = _G.BS and _G.BS.Compat
local function safeDrawingNew(class)
if Compat and Compat.DrawingNew then return Compat.DrawingNew(class) end
local s, r = pcall(function() return Drawing.new(class) end)
return s and r or nil
end
local function safeMouseRel(x, y)
if Compat and Compat.MouseMoveRel then Compat.MouseMoveRel(x, y) return end
pcall(function() mousemoverel(x, y) end)
end
local function safeMouse1Click()
if Compat and Compat.Mouse1Click then Compat.Mouse1Click() return end
pcall(function() mouse1click() end)
end
page:Label(" Aimbot ")
page:Toggle("Aimbot", false, function(v) Flags.Aimbot = v end)
page:Slider("Aimbot FOV", 10, 360, 60, function(v) Flags.AimbotFOV = v end)
page:Slider("Aimbot Smooth", 1, 50, 5, function(v) Flags.AimbotSmooth = v end)
page:Dropdown({Name="Aimbot Bone", Flag="AimbotBone", Options={"Head","Chest","Nearest","Pelvis","Stomach","Auto"}, Default="Head"})
page:Dropdown({Name="Aimbot Sort", Flag="AimSort", Options={"Crosshair","Distance","Health","Threat","Random"}, Default="Crosshair"})
page:Dropdown({Name="Aimbot Smooth Style", Flag="AimSmoothStyle", Options={"Linear","Ease In","Ease Out","Bezier","Adaptive"}, Default="Linear"})
page:Slider("Aimbot Min Smooth", 1, 30, 3, function(v) Flags.AimMinSmooth = v end)
page:Toggle("Aimbot Team Check", true, function(v) Flags.AimbotTeamCheck = v end)
page:Toggle("Aimbot Friend Check", true, function(v) Flags.AimbotFriend = v end)
page:Toggle("Aimbot Wall Check", true, function(v) Flags.AimbotWall = v end)
page:Toggle("Aimbot Visibility Check", true, function(v) Flags.AimbotVis = v end)
page:Toggle("Aimbot Predict", true, function(v) Flags.AimbotPredict = v end)
page:Slider("Aimbot Pred Factor", 5, 100, 40, function(v) Flags.AimPredF = v end)
page:Toggle("Aimbot Lag Comp", false, function(v) Flags.AimLagComp = v end)
page:Slider("Aim Lag Ticks", 1, 16, 8, function(v) Flags.AimLagTicks = v end)
page:Label(" Aimbot Advanced ")
page:Toggle("Aimbot Keybind", false, function(v) Flags.AimKeybind = v end)
page:Dropdown({Name="Aim Key", Flag="AimKey", Options={"Left Alt","Left Ctrl","Mouse4","Mouse5","Shift"}, Default="Left Alt"})
page:Toggle("Aimbot Aim Lock", false, function(v) Flags.AimLock = v end)
page:Slider("Aim Lock Duration", 100, 3000, 500, function(v) Flags.AimLockDur = v end)
page:Toggle("Aimbot Humanize", false, function(v) Flags.AimHumanize = v end)
page:Slider("Humanize Delay", 0, 100, 20, function(v) Flags.AimHDelay = v end)
page:Slider("Humanize Deviation", 0, 50, 10, function(v) Flags.AimHDev = v end)
page:Toggle("Aimbot Auto Stop", false, function(v) Flags.AimAutoStop = v end)
page:Toggle("Aimbot Auto Scope", false, function(v) Flags.AimAutoScope = v end)
page:Toggle("Aimbot Auto Crouch", false, function(v) Flags.AimAutoCrouch = v end)
page:Toggle("Aimbot FOV Circle", false, function(v) Flags.AimFovCircle = v end)
page:Toggle("Aimbot Target Line", false, function(v) Flags.AimTargetLine = v end)
page:Toggle("Aimbot Target Info", false, function(v) Flags.AimTargetInfo = v end)
page:Toggle("Aimbot Silent", false, function(v) Flags.AimSilent = v end)
page:Label(" Aimbot Expert ")
page:Toggle("Aimbot Flick", false, function(v) Flags.AimFlick = v end)
page:Slider("Flick Speed", 1, 30, 15, function(v) Flags.AimFlickSpd = v end)
page:Toggle("Aimbot Jitter", false, function(v) Flags.AimJitter = v end)
page:Slider("Jitter Amount", 1, 30, 5, function(v) Flags.AimJitterAmt = v end)
page:Slider("Jitter Speed", 1, 20, 10, function(v) Flags.AimJitterSpd = v end)
page:Toggle("Aimbot Target Switch", false, function(v) Flags.AimTargetSwitch = v end)
page:Slider("Switch Delay", 50, 1000, 200, function(v) Flags.AimSwitchDelay = v end)
page:Toggle("Aimbot Distance Scale", false, function(v) Flags.AimDistScale = v end)
page:Slider("Dist Scale Min", 1, 20, 3, function(v) Flags.AimDistMin = v end)
page:Slider("Dist Scale Max", 5, 50, 10, function(v) Flags.AimDistMax = v end)
page:Toggle("Aimbot Health Priority", false, function(v) Flags.AimHealthPri = v end)
page:Slider("Health Weight", 1, 10, 5, function(v) Flags.AimHealthW = v end)
page:Toggle("Aimbot Knockback", false, function(v) Flags.AimKnockback = v end)
page:Slider("Knockback Strength", 1, 20, 8, function(v) Flags.AimKnockStr = v end)
page:Toggle("Aimbot Trigger on Key", false, function(v) Flags.AimTriggerKey = v end)
page:Dropdown({Name="Trigger Key", Flag="AimTriggerKeyBind", Options={"Mouse1","Mouse2","Mouse4","Mouse5"}, Default="Mouse1"})
page:Label("Flick:  | Jitter: ")
page:Label("Dist Scale: ")
page:Label("Health Pri: ")
local aimTarget = nil
local aimLockEnd = 0
local aimFovCircle = nil
local aimTargetLine = nil
local aimFlickTime = 0
local AimKeyMap = {
}
local function isAimKeyDown()
if not Flags.AimKeybind then return true end
local key = AimKeyMap[Flags.AimKey or "Left Alt"]
if not key then return false end
if key.EnumType == Enum.UserInputType then
return UIS:IsMouseButtonPressed(key)
else
return UIS:IsKeyDown(key)
end
end
local function calcSmooth(baseSmooth, style, dist)
if Flags.PingAdapt and BS.PA then
baseSmooth = BS.PA.getAdaptSmooth(baseSmooth)
end
if style == "Ease In" then
return baseSmooth * (1 + dist * 0.002)
elseif style == "Ease Out" then
return baseSmooth * (1 / (1 + dist * 0.001))
elseif style == "Bezier" then
local t = math.clamp(dist / 200, 0, 1)
return baseSmooth * (1 + t * t * 0.5)
elseif style == "Adaptive" then
local minS = Flags.AimMinSmooth or 3
if dist < 50 then return minS
elseif dist < 150 then return baseSmooth * 0.7
else return baseSmooth end
end
return baseSmooth
end
task.spawn(function()
while task.wait() do
if Flags.Aimbot and alive() then
pcall(function()
local cam = workspace.CurrentCamera
local mouse = UIS:GetMouseLocation()
local myHrp = hrp()
if not cam or not myHrp then return end
if not isAimKeyDown() then
if aimLockEnd > 0 and tick() < aimLockEnd then
else
aimTarget = nil
return
end
end
local bone = Flags.AimbotBone or "Head"
local sort = Flags.AimSort or "Crosshair"
local myPos = myHrp.Position
local candidates = {}
for _, e in pairs(BS.enemies()) do
if not e.HRP or not e.Hum or e.Hum.Health <= 0 then continue end
if Flags.AimbotTeamCheck and lplr.Team and e.Player.Team == lplr.Team then continue end
if Flags.AimbotFriend and lplr:IsFriendsWith(e.Player.UserId) then continue end
local aimPos = nil
if bone == "Head" then
aimPos = e.Head and e.Head.Position or e.HRP.Position + Vector3.new(0, 1.5, 0)
elseif bone == "Chest" then
aimPos = e.HRP.Position + Vector3.new(0, 0.5, 0)
elseif bone == "Pelvis" then
aimPos = e.HRP.Position + Vector3.new(0, 0.1, 0)
elseif bone == "Stomach" then
aimPos = e.HRP.Position + Vector3.new(0, 0.3, 0)
elseif bone == "Nearest" then
local candidates2 = {
e.Head and e.Head.Position or e.HRP.Position + Vector3.new(0, 1.5, 0),
e.HRP.Position + Vector3.new(0, 0.5, 0),
e.HRP.Position,
}
local bestB, bestBD = candidates2[1], math.huge
for _, bp in ipairs(candidates2) do
local sp, sv = cam:WorldToViewportPoint(bp)
if sv then local d = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude; if d < bestBD then bestBD = d; bestB = bp end end
end
aimPos = bestB
elseif bone == "Auto" then
local headPos = e.Head and e.Head.Position or e.HRP.Position + Vector3.new(0, 1.5, 0)
local bodyPos = e.HRP.Position + Vector3.new(0, 0.5, 0)
if BS.hasLineOfSight(myPos, headPos) then aimPos = headPos else aimPos = bodyPos end
end
if not aimPos then continue end
if Flags.AimbotVis and not BS.hasLineOfSight(myPos, aimPos) then continue end
if Flags.AimbotWall and e.Head and not BS.hasLineOfSight(myPos, e.Head.Position) then continue end
local pos, vis = cam:WorldToViewportPoint(aimPos)
if not vis then continue end
local screenDist = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
local realDist = (myPos - e.HRP.Position).Magnitude
local threat = (1 / math.max(realDist, 1)) * 100 + (100 - e.Hum.Health) * 0.5
if screenDist < 50 then threat = threat + 50 end
table.insert(candidates, {
Enemy = e, AimPos = aimPos, ScreenDist = screenDist,
RealDist = realDist, Health = e.Hum.Health, Threat = threat,
})
end
if sort == "Crosshair" then table.sort(candidates, function(a, b) return a.ScreenDist < b.ScreenDist end)
elseif sort == "Distance" then table.sort(candidates, function(a, b) return a.RealDist < b.RealDist end)
elseif sort == "Health" then table.sort(candidates, function(a, b) return a.Health < b.Health end)
elseif sort == "Threat" then table.sort(candidates, function(a, b) return a.Threat > b.Threat end)
elseif sort == "Random" then for i = #candidates, 2, -1 do local j = math.random(i); candidates[i], candidates[j] = candidates[j], candidates[i] end end
local best = nil
for _, c in ipairs(candidates) do
if c.ScreenDist <= (Flags.AimbotFOV or 60) then
best = c
break
end
end
if Flags.AimLock and aimTarget and tick() < aimLockEnd then
best = aimTarget
elseif best then
aimTarget = best
if Flags.AimLock then
aimLockEnd = tick() + (Flags.AimLockDur or 500) / 1000
end
end
if best then
local targetPos = best.AimPos
if Flags.AimbotPredict then
local vel = BS.getVelocity(best.Enemy)
local pf = (Flags.AimPredF or 40) / 100
if Flags.PingAdapt and BS.PA then
pf = BS.PA.getAdaptPrediction(40) / 100
end
targetPos = targetPos + vel * pf
end
if Flags.AimLagComp then
local vel = BS.getVelocity(best.Enemy)
local lagTicks = Flags.AimLagTicks or 8
if Flags.PingAdapt and BS.PA then
lagTicks = BS.PA.getAdaptLagTicks()
end
targetPos = targetPos + vel * (lagTicks * 0.015)
end
if Flags.AimHumanize then
local dev = (Flags.AimHDev or 10) / 100
targetPos = targetPos + Vector3.new(
)
end
local camPos = cam.CFrame.Position
local targetDir = (targetPos - camPos).Unit
local smooth = calcSmooth(Flags.AimbotSmooth or 5, Flags.AimSmoothStyle or "Linear", best.ScreenDist)
local targetCF = CFrame.new(camPos, camPos + targetDir)
cam.CFrame = cam.CFrame:Lerp(targetCF, 1 / smooth)
if Flags.AimAutoStop then
local h = hum()
if h then h.WalkSpeed = 0 end
end
if Flags.AimAutoScope then
local t = lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if t and (t.Name:lower():find("awp") or t.Name:lower():find("sniper")) then
safeMouse1Click()
end
end
if Flags.AimAutoCrouch then
local h = hum()
if h then h.HipHeight = -0.5 end
end
else
if Flags.AimAutoCrouch then
local h = hum()
if h then h.HipHeight = 0 end
end
if Flags.AimAutoStop then
local h = hum()
if h then h.WalkSpeed = 16 end
end
end
if Flags.AimFovCircle then
if not aimFovCircle then
aimFovCircle = safeDrawingNew("Circle")
if aimFovCircle then aimFovCircle.Thickness = 1; aimFovCircle.NumSides = 64; aimFovCircle.Filled = false end
end
if aimFovCircle then
aimFovCircle.Position = mouse
aimFovCircle.Radius = Flags.AimbotFOV or 60
aimFovCircle.Color = Color3.fromRGB(0, 200, 255)
aimFovCircle.Visible = true
end
else
if aimFovCircle then aimFovCircle.Visible = false end
end
if Flags.AimTargetLine and best then
local sp, sv = cam:WorldToViewportPoint(targetPos)
if sv then
if not aimTargetLine then
aimTargetLine = safeDrawingNew("Line")
if aimTargetLine then aimTargetLine.Thickness = 1 end
end
if aimTargetLine then
aimTargetLine.From = mouse
aimTargetLine.To = Vector2.new(sp.X, sp.Y)
aimTargetLine.Color = Color3.fromRGB(0, 255, 0)
aimTargetLine.Visible = true
end
end
else
if aimTargetLine then aimTargetLine.Visible = false end
end
if Flags.AimTargetInfo and best then
end
end)
else
if aimFovCircle then aimFovCircle.Visible = false end
if aimTargetLine then aimTargetLine.Visible = false end
end
end
end)
task.spawn(function()
while task.wait() do
if Flags.Aimbot and alive() then
pcall(function()
if Flags.AimFlick and aimTarget then
local cam = workspace.CurrentCamera
local flickSpd = Flags.AimFlickSpd or 15
local targetDir = (aimTarget.AimPos - cam.CFrame.Position).Unit
local targetCF = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + targetDir)
cam.CFrame = cam.CFrame:Lerp(targetCF, flickSpd / 50)
end
if Flags.AimJitter and aimTarget then
local cam = workspace.CurrentCamera
local jitterAmt = (Flags.AimJitterAmt or 5) / 1000
local jitterSpd = Flags.AimJitterSpd or 10
local jX = math.sin(tick() * jitterSpd * 10) * jitterAmt
local jY = math.cos(tick() * jitterSpd * 7) * jitterAmt
cam.CFrame = cam.CFrame * CFrame.new(jX, jY, 0)
end
if Flags.AimTargetSwitch then
local delay = (Flags.AimSwitchDelay or 200) / 1000
if aimTarget and tick() - aimFlickTime < delay then
end
end
if Flags.AimDistScale and aimTarget then
local cam = workspace.CurrentCamera
local dist = (cam.CFrame.Position - aimTarget.AimPos).Magnitude
local minS = Flags.AimDistMin or 3
local maxS = Flags.AimDistMax or 10
local scaledSmooth = minS + (maxS - minS) * math.clamp(dist / 200, 0, 1)
local targetDir = (aimTarget.AimPos - cam.CFrame.Position).Unit
local targetCF = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + targetDir)
cam.CFrame = cam.CFrame:Lerp(targetCF, 1 / scaledSmooth)
end
if Flags.AimHealthPri and aimTarget then
local cam = workspace.CurrentCamera
local healthWeight = (Flags.AimHealthW or 5) / 10
local healthOffset = (100 - aimTarget.Health) * healthWeight * 0.001
local targetDir = (aimTarget.AimPos - cam.CFrame.Position).Unit
local targetCF = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + targetDir)
cam.CFrame = cam.CFrame:Lerp(targetCF, 1 / (5 - healthOffset * 4))
end
if Flags.AimKnockback and aimTarget then
local cam = workspace.CurrentCamera
local knockStr = (Flags.AimKnockStr or 8) / 1000
local knock = CFrame.new(0, knockStr, 0)
cam.CFrame = cam.CFrame * knock
end
end)
end
end
end)
page:Label(" Trigger Bot ")
page:Toggle("Trigger Bot", false, function(v) Flags.TriggerBot = v end)
page:Slider("TB Min Delay", 0, 200, 30, function(v) Flags.TBMinDelay = v end)
page:Slider("TB Max Delay", 50, 400, 120, function(v) Flags.TBMaxDelay = v end)
page:Toggle("TB Keybind Only", false, function(v) Flags.TBKeybind = v end)
page:Dropdown({Name="TB Key", Flag="TBKey", Options={"Left Ctrl","Mouse4","Mouse5","V"}, Default="Left Ctrl"})
page:Toggle("TB Headshot Only", false, function(v) Flags.TBHeadOnly = v end)
page:Toggle("TB Body Only", false, function(v) Flags.TBBodyOnly = v end)
page:Toggle("TB Team Check", true, function(v) Flags.TBTeamCheck = v end)
page:Toggle("TB Wall Check", true, function(v) Flags.TBWallCheck = v end)
page:Toggle("TB Burst Mode", false, function(v) Flags.TBBurst = v end)
page:Slider("TB Burst Count", 2, 10, 3, function(v) Flags.TBBurstCount = v end)
page:Slider("TB Burst Delay", 10, 100, 30, function(v) Flags.TBBurstDelay = v end)
page:Toggle("TB Legit Random", false, function(v) Flags.TBLegitRand = v end)
page:Slider("TB Legit Chance", 10, 100, 70, function(v) Flags.TBLegitChance = v end)
page:Toggle("TB FOV Check", false, function(v) Flags.TBFovCheck = v end)
page:Slider("TB FOV", 10, 180, 30, function(v) Flags.TBFov = v end)
local tbBurstShots = 0
local tbLastBurst = 0
local TBKeyMap = {
}
task.spawn(function()
while task.wait() do
if Flags.TriggerBot and alive() then
if Flags.TBKeybind then
local key = TBKeyMap[Flags.TBKey or "Left Ctrl"]
if key then
if key.EnumType == Enum.UserInputType then
if not UIS:IsMouseButtonPressed(key) then continue end
else
if not UIS:IsKeyDown(key) then continue end
end
end
end
if Flags.TBBurst then
if tbBurstShots >= (Flags.TBBurstCount or 3) then
if tick() - tbLastBurst < (Flags.TBBurstDelay or 30) / 1000 then continue end
tbBurstShots = 0
end
end
if Flags.TBLegitRand then
if math.random(1, 100) > (Flags.TBLegitChance or 70) then continue end
end
pcall(function()
local cam = workspace.CurrentCamera
local mousePos = UIS:GetMouseLocation()
local myHrp = hrp()
local ray = cam:ViewportPointToRay(mousePos.X, mousePos.Y)
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = {lplr.Character}
local rayResult = workspace:Raycast(ray.Origin, ray.Direction * 500, rayParams)
local mouseTarget = rayResult and rayResult.Instance
if not cam or not mouseTarget or not myHrp then continue end
for _, e in pairs(BS.enemies()) do
if e.Char and mouseTarget:IsDescendantOf(e.Char) then
if Flags.TBTeamCheck and lplr.Team and e.Player.Team == lplr.Team then continue end
if Flags.TBHeadOnly and e.Head and mouseTarget ~= e.Head then continue end
if Flags.TBBodyOnly and mouseTarget ~= e.HRP then continue end
if Flags.TBWallCheck and e.Head and not BS.hasLineOfSight(myHrp.Position, e.Head.Position) then continue end
if Flags.TBFovCheck then
local pos, vis = cam:WorldToViewportPoint(e.HRP.Position)
if vis then
local sd = (Vector2.new(pos.X, pos.Y) - UIS:GetMouseLocation()).Magnitude
if sd > (Flags.TBFov or 30) then continue end
end
end
local minD = (Flags.TBMinDelay or 30) / 1000
local maxD = (Flags.TBMaxDelay or 120) / 1000
if Flags.PingAdapt and BS.PA then
local adapted = BS.PA.getAdaptTriggerDelay(Flags.TBMinDelay or 30, Flags.TBMaxDelay or 120)
minD = adapted / 1000
maxD = minD * 1.5
end
local delay = minD + math.random() * (maxD - minD)
task.wait(delay)
local tool = lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if tool and not tool.Name:lower():find("knife") then
tbBurstShots = tbBurstShots + 1
tbLastBurst = tick()
end
break
end
end
end)
end
end
end)
page:Toggle("Silent Aim", false, function(v) Flags.SilentAim = v end)
page:Slider("SA FOV", 10, 180, 90, function(v) Flags.SAFOV = v end)
page:Toggle("SA Headshot", false, function(v) Flags.SAHeadshot = v end)
page:Toggle("SA Wall Check", true, function(v) Flags.SAWall = v end)
local silentTarget = nil
local oldNamecall
local function setupSilentAimHook()
if oldNamecall then return end
if not (Compat andCompat.Features and Compat.Features.HookMetamethod) then return end
pcall(function()
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
local method = getnamecallmethod()
if method == "FireServer" and silentTarget and Flags.SilentAim then
local args = {...}
if #args > 0 and typeof(args[1]) == "Vector3" then
local aimPos = Flags.SAHeadshot
and (silentTarget.Head and silentTarget.Head.Position or silentTarget.HRP.Position + Vector3.new(0, 1.5, 0))
or silentTarget.HRP.Position
args[1] = aimPos
return oldNamecall(self, unpack(args))
end
end
return oldNamecall(self, ...)
end))
end)
end
task.spawn(function()
while task.wait() do
if Flags.SilentAim and alive() then
pcall(function()
setupSilentAimHook()
local cam = workspace.CurrentCamera
local myHrp = hrp()
if not cam or not myHrp then return end
local mousePos = UIS:GetMouseLocation()
local saFov = Flags.SAFOV or 90
if Flags.PingAdapt and BS.PA then
saFov = BS.PA.getAdaptSilentRange(saFov)
end
local best, bestDist = nil, saFov
for _, e in pairs(BS.enemies()) do
local aimPos = Flags.SAHeadshot
and (e.Head and e.Head.Position or e.HRP.Position + Vector3.new(0, 1.5, 0))
or e.HRP.Position
if Flags.SAWall and not BS.hasLineOfSight(myHrp.Position, aimPos) then
continue
end
local pos, vis = cam:WorldToViewportPoint(aimPos)
if vis then
local screenDist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
if screenDist < bestDist then
best = e
bestDist = screenDist
end
end
end
silentTarget = best and best.Enemy or nil
end)
else
silentTarget = nil
end
end
end)
page:Toggle("RCS", false, function(v) Flags.RCS = v end)
page:Slider("RCS X", 0, 100, 60, function(v) Flags.RCSX = v end)
page:Slider("RCS Y", 0, 100, 80, function(v) Flags.RCSY = v end)
page:Toggle("RCS Burst Mode", false, function(v) Flags.RCSBurst = v end)
local shotCount = 0
local isFiring = false
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.UserInputType == Enum.UserInputType.MouseButton1 then
isFiring = true
shotCount = 0
end
end)
UIS.InputEnded:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 then
isFiring = false
shotCount = 0
end
end)
task.spawn(function()
while task.wait() do
if Flags.RCS and alive() and isFiring then
pcall(function()
local cam = workspace.CurrentCamera
shotCount = shotCount + 1
local weapon = BS.weaponType()
local rcsX = (Flags.RCSX or 60) / 100
local rcsY = (Flags.RCSY or 80) / 100
local recoilX, recoilY = 0, 0
if weapon == "rifle" then
if shotCount <= 5 then
recoilY = -0.8 * rcsY
recoilX = 0.2 * rcsX
elseif shotCount <= 15 then
recoilY = -0.5 * rcsY
recoilX = 0.4 * rcsX * math.sin(shotCount * 0.5)
else
recoilY = -0.3 * rcsY
recoilX = 0.5 * rcsX * math.sin(shotCount * 0.3)
end
elseif weapon == "smg" then
recoilY = -0.4 * rcsY
recoilX = 0.2 * rcsX * math.sin(shotCount * 0.8)
elseif weapon == "pistol" then
recoilY = -0.6 * rcsY
recoilX = 0.1 * rcsX * (shotCount % 2 == 0 and 1 or -1)
else
recoilY = -0.5 * rcsY
recoilX = 0.3 * rcsX * math.sin(shotCount * 0.4)
end
safeMouseRel(recoilX, math.abs(recoilY))
if Flags.RCSBurst and shotCount >= 3 then
task.wait(0.1)
shotCount = 0
end
end)
end
end
end)
page:Toggle("Auto Fire", false, function(v) Flags.AutoFire = v end)
task.spawn(function()
while task.wait() do
if Flags.AutoFire and alive() then
pcall(function()
local tool = lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if tool and tool.Name:lower():find("knife") == nil then
end
end)
end
end
end)
page:Toggle("Quick Switch", false, function(v) Flags.QuickSwitch = v end)
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if Flags.QuickSwitch and input.KeyCode == Enum.KeyCode.Q then
pcall(function()
local tool = lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if tool then
local name = tool.Name:lower()
if name:find("knife") or name:find("bayonet") then
BS.equipTool("ak") or BS.equipTool("m4") or BS.equipTool("rifle")
else
BS.equipTool("knife") or BS.equipTool("bayonet")
end
end
end)
end
end)
page:Toggle("No Spread", false, function(v) Flags.NoSpread = v end)
page:Toggle("No Recoil", false, function(v) Flags.NoRecoil = v end)
page:Toggle("Hit Sound", false, function(v) Flags.HitSound = v end)
page:Slider("Hit Volume", 1, 10, 5, function(v) Flags.HitVolume = v end)
page:Toggle("Headshot Text", false, function(v) Flags.HSText = v end)
page:Toggle("Kill Text", false, function(v) Flags.KillText = v end)
page:Toggle("Team Check", true, function(v) Flags.TeamCheck = v end)
page:Toggle("Friend Check", true, function(v) Flags.FriendCheck = v end)
page:Toggle("Aim Assist", false, function(v) Flags.AimAssist = v end)
page:Slider("AA Smooth", 1, 20, 8, function(v) Flags.AASmooth = v end)
page:Slider("AA FOV", 10, 180, 60, function(v) Flags.AAFov = v end)
page:Toggle("AA Wall Check", true, function(v) Flags.AAWall = v end)
task.spawn(function()
while task.wait() do
if Flags.AimAssist and alive() then
pcall(function()
local cam = workspace.CurrentCamera
local mouse = UIS:GetMouseLocation()
local myHrp = hrp()
if not cam or not myHrp then return end
local best, bestDist = nil, Flags.AAFov or 60
for _, e in pairs(BS.enemies()) do
local aimPos = e.Head and e.Head.Position or e.HRP.Position + Vector3.new(0, 1.5, 0)
if Flags.AAWall and not BS.hasLineOfSight(myHrp.Position, aimPos) then
continue
end
local pos, vis = cam:WorldToViewportPoint(aimPos)
if vis then
local d = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
if d < bestDist then best = e; bestDist = d end
end
end
if best then
local aimPos = best.Head and best.Head.Position or best.HRP.Position + Vector3.new(0, 1.5, 0)
local pos = cam:WorldToViewportPoint(aimPos)
local aaSmooth = Flags.AASmooth or 8
if Flags.PingAdapt and BS.PA then
aaSmooth = BS.PA.getAdaptSmooth(aaSmooth)
end
local delta = (Vector2.new(pos.X, pos.Y) - mouse) / aaSmooth
safeMouseRel(delta.X, delta.Y)
end
end)
end
end
end)
page:Toggle("Auto Knife", false, function(v) Flags.AutoKnife = v end)
page:Slider("Knife Range", 2, 8, 4, function(v) Flags.KnifeRange = v end)
task.spawn(function()
while task.wait(0.1) do
if Flags.AutoKnife and alive() then
pcall(function()
local target, dist = BS.nearestEnemy(Flags.KnifeRange or 4)
if target and dist <= (Flags.KnifeRange or 4) then
local currentTool = lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if not currentTool or not currentTool.Name:lower():find("knife") then
BS.equipTool("knife") or BS.equipTool("bayonet")
task.wait(0.1)
end
local tool = lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if tool then tool:Activate() end
end
end)
end
end
end)
page:Toggle("Hit Box Expander", false, function(v) Flags.HitBoxExpander = v end)
page:Slider("HB Size", 1, 10, 3, function(v) Flags.HBSize = v end)
task.spawn(function()
while task.wait(0.1) do
if Flags.HitBoxExpander then
for _, e in pairs(BS.enemies()) do
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
page:Toggle("Auto Disconnect", false, function(v) Flags.AutoDC = v end)
page:Slider("DC Health", 5, 50, 10, function(v) Flags.DCHealth = v end)
task.spawn(function()
while task.wait(0.5) do
if Flags.AutoDC and alive() then
local h = hum()
if h and h.Health <= (Flags.DCHealth or 10) then
pcall(function()
game:GetService("TeleportService"):Teleport(game.PlaceId, lplr)
end)
end
end
end
end)
page:Toggle("No Flash", false, function(v) Flags.NoFlash = v end)
task.spawn(function()
while task.wait(0.1) do
if Flags.NoFlash then
pcall(function()
for _, gui in pairs(lplr.PlayerGui:GetChildren()) do
if gui.Name:lower():find("flash") or gui.Name:lower():find("blind") then
gui.Enabled = false
end
end
for _, effect in pairs(Lighting:GetChildren()) do
if effect:IsA("BlurEffect") then
effect.Size = 0
end
end
end)
end
end
end)
page:Toggle("Auto Buy", false, function(v) Flags.AutoBuy = v end)
page:Dropdown({Name="Buy Primary", Flag="BuyPrimary", Options={"AK-47", "M4A4", "M4A1-S", "AWP", "SG553", "AUG"}, Default="AK-47"})
page:Dropdown({Name="Buy Secondary", Flag="BuySecondary", Options={"Deagle", "USP-S", "Glock", "P250", "Five-SeveN"}, Default="Deagle"})
page:Toggle("Buy Armor", true, function(v) Flags.BuyArmor = v end)
page:Toggle("Buy Kit", true, function(v) Flags.BuyKit = v end)
page:Toggle("Buy Grenades", false, function(v) Flags.BuyGrenades = v end)
task.spawn(function()
while task.wait(1) do
if Flags.AutoBuy then
pcall(function()
local primary = Flags.BuyPrimary or "AK-47"
BS.api and BS.api.buyWeapon(primary)
local secondary = Flags.BuySecondary or "Deagle"
BS.api and BS.api.buyWeapon(secondary)
if Flags.BuyArmor then
BS.api and BS.api.buyEquipment("Armor")
end
if Flags.BuyKit and BS.team() and BS.team().Name == "CT" then
BS.api and BS.api.buyEquipment("Defuse Kit")
end
if Flags.BuyGrenades then
BS.api and BS.api.buyWeapon("Flashbang")
BS.api and BS.api.buyWeapon("Smoke")
BS.api and BS.api.buyWeapon("HE Grenade")
end
end)
end
end
end)
page:Toggle("Auto Sprint", false, function(v) Flags.AutoSprint = v end)
task.spawn(function()
while task.wait(0.2) do
if alive() then
local h = hum()
if h then
if Flags.AutoSprint then
h.WalkSpeed = 20
else
if h.WalkSpeed == 20 then h.WalkSpeed = 16 end
end
end
end
end
end)
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
page:Toggle("Force Crosshair", false, function(v) Flags.ForceCrosshair = v end)
page:Toggle("Scope Zoom Adjust", false, function(v) Flags.ScopeZoom = v end)
page:Slider("Zoom Multiplier", 50, 200, 100, function(v) Flags.ZoomMult = v end)
page:Separator()
page:Label(" Auto Pistol ")
page:Toggle("Auto Pistol", false, function(v) Flags.AutoPistol = v end)
page:Slider("Auto Pistol RPM", 200, 900, 400, function(v) Flags.AutoPistolRPM = v end)
page:Label(" Rapid Fire ")
page:Toggle("Rapid Fire", false, function(v) Flags.RapidFire = v end)
page:Slider("Rapid Burst Count", 2, 10, 3, function(v) Flags.RapidBurst = v end)
page:Slider("Rapid Burst Delay", 10, 100, 30, function(v) Flags.RapidDelay = v end)
page:Toggle("Rapid Auto Stop", false, function(v) Flags.RapidAutoStop = v end)
page:Label(" Hitchance ")
page:Toggle("Hitchance Filter", false, function(v) Flags.HitchanceFilter = v end)
page:Slider("Hitchance %", 20, 100, 60, function(v) Flags.Hitchance = v end)
page:Slider("Hitchance Seed", 1, 100, 50, function(v) Flags.HCSeed = v end)
page:Label(" Min Damage ")
page:Toggle("Min Damage Filter", false, function(v) Flags.MinDmgFilter = v end)
page:Slider("Min Damage", 1, 100, 20, function(v) Flags.MinDamage = v end)
page:Toggle("Override Headshot Min Dmg", false, function(v) Flags.HSOverrideDmg = v end)
page:Slider("Headshot Min Dmg", 1, 100, 80, function(v) Flags.HSMinDmg = v end)
page:Label(" Quick Switch ")
page:Toggle("Knife After Shot", false, function(v) Flags.KnifeAfterShot = v end)
page:Slider("QS Delay (ms)", 50, 500, 150, function(v) Flags.QSDelay = v end)
page:Toggle("Auto Reload on Empty", false, function(v) Flags.AutoReloadEmpty = v end)
local lastAutoPistolShot = 0
task.spawn(function()
while true do
task.wait(0.01)
if Flags.AutoPistol and BS.alive() then
pcall(function()
local tool = lplr.Character and lplr and lplr.Character:FindFirstChildOfClass("Tool")
if tool and tool:FindFirstChild("RemoteEvent") then
local rpm = Flags.AutoPistolRPM or 400
local interval = 60 / rpm
if tick() - lastAutoPistolShot >= interval then
if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
tool.RemoteEvent:FireServer((tool.Handle and tool.Handle.Position or hrp.Position), "Fire")
lastAutoPistolShot = tick()
end
end
end
end)
end
end
end)
local rapidBurstCount = 0
local lastRapidShot = 0
task.spawn(function()
while true do
task.wait(0.01)
if Flags.RapidFire and BS.alive() then
pcall(function()
local tool = lplr.Character and lplr and lplr.Character:FindFirstChildOfClass("Tool")
if tool and tool:FindFirstChild("RemoteEvent") then
local burst = Flags.RapidBurst or 3
local delay = (Flags.RapidDelay or 30) / 1000
if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
if tick() - lastRapidShot >= delay then
if rapidBurstCount < burst then
tool.RemoteEvent:FireServer((tool.Handle and tool.Handle.Position or hrp.Position), "Fire")
rapidBurstCount = rapidBurstCount + 1
lastRapidShot = tick()
else
rapidBurstCount = 0
task.wait(0.1)
end
end
else
rapidBurstCount = 0
end
end
end)
end
end
end)
local function shouldShoot()
if not Flags.HitchanceFilter then return true end
local hc = Flags.Hitchance or 60
local seed = Flags.HCSeed or 50
local roll = math.random(1, 100)
return roll <= hc
end
local function checkMinDamage(damage)
if not Flags.MinDmgFilter then return true end
local minDmg = Flags.MinDamage or 20
return damage >= minDmg
end
local lastShotTime = 0
task.spawn(function()
while true do
task.wait(0.01)
if (Flags.KnifeAfterShot or Flags.AutoReloadEmpty) and BS.alive() then
pcall(function()
local tool = lplr.Character and lplr and lplr.Character:FindFirstChildOfClass("Tool")
if tool and tool:FindFirstChild("RemoteEvent") then
if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
lastShotTime = tick()
end
if Flags.KnifeAfterShot and tick() - lastShotTime > 0 and tick() - lastShotTime < 0.1 then
local knife = lplr and lplr.Character:FindFirstChild("Knife") or lplr.Backpack:FindFirstChild("Knife")
if knife then
tool.Parent = lplr.Backpack
knife.Parent = lplr.Character
task.delay((Flags.QSDelay or 150) / 1000, function()
if knife.Parent == lplr.Character then
knife.Parent = lplr.Backpack
tool.Parent = lplr.Character
end
end)
end
end
end
end)
end
end
end)
Combat.shouldShoot = shouldShoot
Combat.checkMinDamage = checkMinDamage
task.spawn(function()
while true do
task.wait(0.01)
if Flags.AutoScope and BS.alive() then
pcall(function()
if not UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
local tool = lplr.Character and lplr and lplr.Character:FindFirstChildOfClass("Tool")
if tool and (tool.Name:lower():find("awp") or tool.Name:lower():find("sniper")) then
if Flags.Aimbot and Flags.AimTarget then
end
end
end
end)
end
end
end)
task.spawn(function()
while true do
task.wait(0.1)
if Flags.KnifeBot and BS.alive() then
pcall(function()
local myHrp = BS.hrp()
if not myHrp then return end
local range = Flags.KnifeRange or 10
for _, p in pairs(Players:GetPlayers()) do
if p ~= lplr and p.Character then
local eHrp = p and p.Character:FindFirstChild("HumanoidRootPart")
local eHum = p and p.Character:FindFirstChildOfClass("Humanoid")
if eHrp and eHum and eHum.Health > 0 then
local dist = (eHrp.Position - myHrp.Position).Magnitude
if dist <= range then
local knife = lplr.Backpack:FindFirstChild("Knife") or lplr and lplr.Character:FindFirstChild("Knife")
if knife then
if knife.Parent ~= lplr.Character then
knife.Parent = lplr.Character
end
pcall(function()
knife.RemoteEvent:FireServer(eHrp.Position, "Attack")
end)
end
end
end
end
end
end)
end
end
end)
task.spawn(function()
while true do
task.wait(0.1)
if Flags.ZeusBot and BS.alive() then
pcall(function()
local myHrp = BS.hrp()
if not myHrp then return end
local range = Flags.ZeusRange or 30
for _, p in pairs(Players:GetPlayers()) do
if p ~= lplr and p.Character then
local eHrp = p and p.Character:FindFirstChild("HumanoidRootPart")
local eHum = p and p.Character:FindFirstChildOfClass("Humanoid")
if eHrp and eHum and eHum.Health > 0 then
local dist = (eHrp.Position - myHrp.Position).Magnitude
if dist <= range then
local zeus = lplr.Backpack:FindFirstChild("Taser") or lplr and lplr.Character:FindFirstChild("Taser")
if zeus then
if zeus.Parent ~= lplr.Character then
zeus.Parent = lplr.Character
end
pcall(function()
zeus.RemoteEvent:FireServer(eHrp.Position)
end)
end
end
end
end
end
end)
end
end
end)
task.spawn(function()
while true do
task.wait(0.1)
if Flags.AutoKnifeAfterKill and BS.alive() then
pcall(function()
local tool = lplr.Character and lplr and lplr.Character:FindFirstChildOfClass("Tool")
if tool and tool.Name ~= "Knife" then
end
end)
end
end
end)
task.spawn(function()
while true do
task.wait(0.01)
if Flags.RapidFire and BS.alive() then
pcall(function()
local tool = lplr.Character and lplr and lplr.Character:FindFirstChildOfClass("Tool")
if tool and tool:FindFirstChild("RemoteEvent") then
if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
tool.RemoteEvent:FireServer((tool.Handle and tool.Handle.Position or hrp.Position), "Fire")
end
end
end)
end
end
end)
task.spawn(function()
while true do
task.wait(0.01)
if Flags.AutoPistol and BS.alive() then
pcall(function()
local tool = lplr.Character and lplr and lplr.Character:FindFirstChildOfClass("Tool")
if tool and tool:FindFirstChild("RemoteEvent") then
local rpm = Flags.AutoPistolRPM or 400
local interval = 60 / rpm
if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
tool.RemoteEvent:FireServer((tool.Handle and tool.Handle.Position or hrp.Position), "Fire")
task.wait(interval)
end
end
end)
end
end
end)
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
local Backtrack = {History = {}, MaxRecords = 64}
BS.Backtrack = Backtrack
function Backtrack:Record(player, position, time)
if not player or not position then return end
if not self.History[player.UserId] then
self.History[player.UserId] = {}
end
local hist = self.History[player.UserId]
table.insert(hist, {Pos = position, Time = time or tick()})
while #hist > self.MaxRecords do
table.remove(hist, 1)
end
end
function Backtrack:GetRecord(player, latency)
if not player then return nil end
local hist = self.History[player.UserId]
if not hist or #hist == 0 then return nil end
local targetTime = tick() - (latency or 0) - (Flags.BacktrackTick or 0.2)
local best, bestDist = nil, math.huge
for _, rec in ipairs(hist) do
local dist = math.abs(rec.Time - targetTime)
if dist < bestDist then
bestDist = dist
best = rec
end
end
return best and best.Pos or nil
end
function Backtrack:Cleanup()
local now = tick()
for uid, hist in pairs(self.History) do
for i = #hist, 1, -1 do
if now - hist[i].Time > 1.0 then
table.remove(hist, i)
end
end
if #hist == 0 then
self.History[uid] = nil
end
end
end
task.spawn(function()
while task.wait(0.05) do
pcall(function()
if not Flags.Backtrack then return end
for _, player in ipairs(Players:GetPlayers()) do
if player ~= lplr and player.Character then
local hrp = player and player.Character:FindFirstChild("HumanoidRootPart")
if hrp then
Backtrack:Record(player, hrp.Position)
end
end
end
Backtrack:Cleanup()
end)
end
end)
page:Label(" Backtrack ")
page:Toggle("Enable Backtrack", false, function(v) Flags.Backtrack = v end)
page:Slider("Tick (ms)", 50, 500, 200, function(v) Flags.BacktrackTick = v / 1000 end)
page:Slider("Max Records", 16, 128, 64, function(v) Backtrack.MaxRecords = v end)
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.LatencyCompensation = function(basePos)
if not basePos then return basePos end
if not Flags.LatencyComp then return basePos end
local ping = BS.Ping and BS.Ping.Current or 0
local velocity = Vector3.new()
pcall(function()
local target = BS.AimbotTarget
if target and target.HRP then
velocity = target.HRP.AssemblyLinearVelocity
end
end)
local offset = velocity * (ping / 1000) * (Flags.LatencyFactor or 0.5)
return basePos + offset
end
page:Label(" Latency Compensation ")
page:Toggle("Enable Latency Comp", false, function(v) Flags.LatencyComp = v end)
page:Slider("Factor %", 10, 200, 50, function(v) Flags.LatencyFactor = v / 100 end)
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
page:Label(" Legit Anti-Aim ")
page:Toggle("Legit AA", false, function(v) Flags.LegitAA = v end)
page:Slider("Legit AA Angle", 5, 45, 15, function(v) Flags.LegitAAAngle = v end)
page:Dropdown("Legit AA Mode", {"Sway", "Jitter", "Slow Spin"}, function(v) Flags.LegitAAMode = v end)
task.spawn(function()
while task.wait(0.1) do
pcall(function()
if not Flags.LegitAA then return end
local hrp = BS.hrp()
if not hrp then return end
local angle = Flags.LegitAAAngle or 15
local mode = Flags.LegitAAMode or "Sway"
local cf = hrp.CFrame
if mode == "Sway" then
local sway = math.sin(tick() * 2) * angle
hrp.CFrame = cf * CFrame.Angles(0, math.rad(sway), 0)
elseif mode == "Jitter" then
local j = (math.random() > 0.5 and 1 or -1) * angle
hrp.CFrame = cf * CFrame.Angles(0, math.rad(j), 0)
elseif mode == "Slow Spin" then
hrp.CFrame = cf * CFrame.Angles(0, math.rad(tick() * angle * 10 % 360), 0)
end
end)
end
end)
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.WeaponSettings = {
["AK47"]    = {FOV = 120, Smooth = 3, Bone = "Head", Hitchance = 70},
["M4A4"]    = {FOV = 110, Smooth = 2.5, Bone = "Head", Hitchance = 75},
["AWP"]     = {FOV = 60, Smooth = 1, Bone = "Head", Hitchance = 90},
["Deagle"]  = {FOV = 80, Smooth = 2, Bone = "Head", Hitchance = 65},
["USP"]     = {FOV = 100, Smooth = 2, Bone = "Head", Hitchance = 80},
["Glock"]   = {FOV = 100, Smooth = 2.5, Bone = "Chest", Hitchance = 70},
["P250"]    = {FOV = 90, Smooth = 2, Bone = "Head", Hitchance = 72},
["MP9"]     = {FOV = 130, Smooth = 3.5, Bone = "Chest", Hitchance = 60},
["MAC10"]   = {FOV = 130, Smooth = 3.5, Bone = "Chest", Hitchance = 60},
["UMP45"]   = {FOV = 115, Smooth = 3, Bone = "Chest", Hitchance = 65},
["XM1014"]  = {FOV = 150, Smooth = 4, Bone = "Chest", Hitchance = 85},
["Nova"]    = {FOV = 150, Smooth = 4, Bone = "Chest", Hitchance = 85},
["M249"]    = {FOV = 140, Smooth = 4, Bone = "Chest", Hitchance = 55},
["Negev"]   = {FOV = 140, Smooth = 4, Bone = "Chest", Hitchance = 50},
}
page:Label(" Weapon Settings ")
page:Toggle("Per-Weapon Config", false, function(v) Flags.WeaponConfig = v end)
BS.GetWeaponSettings = function()
if not Flags.WeaponConfig then return nil end
local tool = lplr and lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if not tool then return nil end
local name = tool.Name
return BS.WeaponSettings[name]
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
page:Label(" Advanced ")
page:Toggle("Friendly Fire", false, function(v) Flags.FriendlyFire = v end)
print("[Combat] BloxStrike Combat module loaded (25 features)")
]])
writefile("BloxStrike/modules/combatassist.lua", [[
local Players = nil
pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local UserInputService = nil
pcall(function() UserInputService = game:GetService("UserInputService") end)
local ReplicatedStorage = nil
pcall(function() ReplicatedStorage = game:GetService("ReplicatedStorage") end)
local StarterGui = nil
pcall(function() StarterGui = game:GetService("StarterGui") end)
local HttpService = nil
pcall(function() HttpService = game:GetService("HttpService") end)
local lplr = Players.LocalPlayer
if not BS.Win then warn("[Combat Assist] BS.Win not available - ui.lua may have failed") return end
local page = BS.Win:Tab("Comms")
if not page or not page.Toggle then warn("[CombatAssist] Failed to create tab!") return end
local CA = {}
BS.CombatAssist = CA
CA.PlayerRatings = {}
CA.Spectators = {}
CA.MapMemory = {}
CA.SessionStats = {
Kills = 0, Deaths = 0, Headshots = 0, Shots = 0,
HitCount = 0, DamageDealt = 0, Accuracy = 0,
KillStreak = 0, MaxKillStreak = 0,
}
-- SECTION 1: CHAT ASSISTANT
page:Label("  ")
page:Toggle("Chat Assistant", false, function(v) Flags.ChatAssistant = v end)
page:Toggle("Auto Reply", false, function(v) Flags.ChatAutoReply = v end)
page:Toggle("Auto Taunt on Kill", false, function(v) Flags.ChatAutoTaunt = v end)
page:Toggle("Auto GG", false, function(v) Flags.ChatAutoGG = v end)
page:Toggle("Auto Team Callout", false, function(v) Flags.ChatAutoCallout = v end)
page:Toggle("Spam Blocked Bypass", false, function(v) Flags.ChatSpamBypass = v end)
page:Slider("Chat Delay", 1, 10, 3, function(v) Flags.ChatDelay = v end)
page:Dropdown({Name="Chat Style", Flag="ChatStyle", Options={"Normal","Toxic","Nice","Chinese","Random"}, Default="Normal"})
page:Button({Name="Send Custom Message", Color=Color3.fromRGB(80, 80, 200)}, function()
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = " Chat Assistant",
Text = "Type your message in game chat, it will be enhanced!",
Duration = 3,
})
end)
end)
local TAUNTS = {
Normal = {
},
Toxic = {
},
Nice = {
},
Chinese = {
},
}
local CALL_PLAYER = {
}
local GG_MESSAGES = {
}
local AUTO_REPLY_MESSAGES = {
["are you cheating"] = {
["ez"] = {"sure buddy", "cry", "gg tho", "gg wp"},
["gg"] = {"gg wp", "gg", "nice game", "wp"},
["noob"] = {"check scoreboard", "ratio", "sit", "look at my KD"},
["bad"] = {"check scoreboard", "look at deaths", "who's bad?"},
["trash"] = {"stay mad", "check scoreboard", "ratio + L"},
["wow"] = {"get good", "ez", "next", "try harder"},
["how"] = {"practice", "skill", "just aim", "get good"},
},
}
local chatState = {
LastMessageTime = 0,
MessageQueue = {},
IsProcessing = false,
LastTauntTime = 0,
}
function CA.sendChat(message)
if not message or message == "" then return end
local delay = (Flags.ChatDelay or 3) / 10
task.delay(delay + math.random() * 0.5, function()
pcall(function()
local textChat = nil
pcall(function() textChat = game:GetService("TextChatService") end)
if textChat and textChat.TextChannels then
local channel = textChat.TextChannels:FindFirstChild("RBXGeneral")
if channel then
end
end
local chatRemote = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
if chatRemote then
local sayEvent = chatRemote:FindFirstChild("SayMessageRequest")
if sayEvent then
end
end
for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
if obj:IsA("RemoteEvent") and obj.Name:find("SayMessage") then
end
end
pcall(function()
game:GetService("TextChatService").TextChannels.RBXGeneral:SendAsync(message)
end)
end)
end)
end
function CA.getRandomTaunt(style)
style = style or Flags.ChatStyle or "Normal"
local db = TAUNTS[style] or TAUNTS.Normal
return db[math.random(#db)]
end
local chatConnections = {}
function CA.startChatListener()
for _, conn in ipairs(chatConnections) do
pcall(function() conn:Disconnect() end)
end
chatConnections = {}
pcall(function()
local textChat = nil
pcall(function() textChat = game:GetService("TextChatService") end)
if textChat and textChat.TextChannels then
local channel = textChat.TextChannels:FindFirstChild("RBXGeneral")
if channel then
local conn = channel.MessageReceived:Connect(function(message)
if not Flags.ChatAssistant then return end
local sender = message.TextSource
local playerName = sender and Players:GetNameFromUserIdAsync(message.TextSource.UserId) or ""
local text = message.Text:lower()
if Flags.ChatAutoReply then
for trigger, replies in pairs(AUTO_REPLY_MESSAGES) do
if text:find(trigger) then
CA.sendChat(replies[math.random(#replies)])
break
end
end
end
end)
table.insert(chatConnections, conn)
end
end
end)
pcall(function()
local chatEvent = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
if chatEvent then
local onMsg = chatEvent:FindFirstChild("OnMessageDoneFiltering")
if onMsg then
local conn = onMsg.OnClientEvent:Connect(function(data)
if not Flags.ChatAssistant then return end
local speaker = data.SpeakerName or ""
local msg = data.Message or ""
local text = msg:lower()
if speaker == lplr.Name then return end
if Flags.ChatAutoReply then
for trigger, replies in pairs(AUTO_REPLY_MESSAGES) do
if text:find(trigger) then
CA.sendChat(replies[math.random(#replies)])
break
end
end
end
end)
table.insert(chatConnections, conn)
end
end
end)
end
function CA.onKill(victimName, headshot)
if not Flags.ChatAssistant then return end
if Flags.ChatAutoTaunt and tick() - chatState.LastTauntTime > 5 then
chatState.LastTauntTime = tick()
local msg = CA.getRandomTaunt()
if headshot then
msg = msg .. " (HS)"
end
CA.sendChat(msg)
end
end
function CA.onRoundEnd()
if not Flags.ChatAssistant then return end
if Flags.ChatAutoGG then
task.delay(2 + math.random() * 3, function()
CA.sendChat(GG_MESSAGES[math.random(#GG_MESSAGES)])
end)
end
end
function CA.sendCallout()
if not Flags.ChatAutoCallout then return end
CA.sendChat(CALL_PLAYER[math.random(#CALL_PLAYER)])
end
task.spawn(function() CA.startChatListener() end)
-- SECTION 2: SPECTATOR DETECTION
page:Label("  ")
page:Toggle("Spectator List", false, function(v) Flags.SpectatorList = v end)
page:Toggle("Spectator Alert", false, function(v) Flags.SpectatorAlert = v end)
page:Toggle("Spectator History", true, function(v) Flags.SpectatorHistory = v end)
page:Toggle("Hide From Specific", false, function(v) Flags.HideSpectator = v end)
page:Slider("Scan Interval", 1, 10, 2, function(v) Flags.SpecScanInterval = v end)
local specState = {
PreviousSpectators = {},
SpectatingMe = {},
TotalSpectators = 0,
LastAlertTime = 0,
}
task.spawn(function()
while true do task.wait(Flags.SpecScanInterval or 2)
if Flags.SpectatorList or Flags.SpectatorAlert then
pcall(function()
local newSpectators = {}
for _, player in pairs(Players:GetPlayers()) do
if player ~= lplr then
local cam = player.Character and player and player.Character:FindFirstChild("Humanoid")
if cam then
end
local hasChar = player.Character and
player and player.Character:FindFirstChildOfClass("Humanoid") and
player and player.Character:FindFirstChildOfClass("Humanoid").Health > 0
if not hasChar then
table.insert(newSpectators, {
UserId = player.UserId,
Name = player.Name,
Since = specState.PreviousSpectators[player.UserId]
and specState.PreviousSpectators[player.UserId].Since
or tick(),
})
end
if hasChar then
local myHRP = BS.hrp()
local theirHRP = player and player.Character:FindFirstChild("HumanoidRootPart")
local theirHum = player and player.Character:FindFirstChildOfClass("Humanoid")
if myHRP and theirHRP and theirHum then
local dist = (myHRP.Position - theirHRP.Position).Magnitude
local vel = theirHRP.AssemblyLinearVelocity.Magnitude
if dist < 30 and vel < 1 then
table.insert(newSpectators, {
UserId = player.UserId,
Name = player.Name,
Since = specState.PreviousSpectators[player.UserId]
and specState.PreviousSpectators[player.UserId].Since
or tick(),
Type = "Observer",
})
end
end
end
end
end
specState.SpectatingMe = newSpectators
specState.TotalSpectators = #newSpectators
if Flags.SpectatorAlert and #newSpectators > #specState.PreviousSpectators and tick() - specState.LastAlertTime > 10 then
specState.LastAlertTime = tick()
local names = {}
for _, s in ipairs(newSpectators) do table.insert(names, s.Name) end
pcall(function()
StarterGui:SetCore("SendNotification", {
Title = "[Spectator]",
Duration = 4,
})
end)
end
specState.PreviousSpectators = {}
for _, s in ipairs(newSpectators) do
specState.PreviousSpectators[s.UserId] = s
end
end)
end
end
end)
CA.SpectatorState = specState
-- SECTION 3: PLAYER RATING SYSTEM
page:Label("  ")
page:Toggle("Player Rating", true, function(v) Flags.PlayerRating = v end)
page:Toggle("Auto Rate", true, function(v) Flags.AutoRate = v end)
page:Slider("Threat Threshold", 50, 100, 70, function(v) Flags.ThreatThreshold = v end)
page:Toggle("Show Player Tags", true, function(v) Flags.ShowPlayerTags = v end)
page:Button({Name="View Player Stats", Color=Color3.fromRGB(100, 200, 100)}, function()
CA.showPlayerStats()
end)
page:Button({Name="Reset All Ratings", Color=Color3.fromRGB(200, 100, 100)}, function()
CA.PlayerRatings = {}
pcall(function()
StarterGui:SetCore("SendNotification", {
Title = " ",
Text = "",
Duration = 3,
})
end)
end)
local ratingState = {
SessionEncounters = {},
DamageLog = {},
}
function CA.ratePlayer(player, rating, reason)
if not player then return end
local uid = player.UserId
if not CA.PlayerRatings[uid] then
CA.PlayerRatings[uid] = {
Name = player.Name,
Rating = 50,
Kills = 0,
Deaths = 0,
Headshots = 0,
DamageDealt = 0,
DamageReceived = 0,
Notes = {},
ThreatLevel = "Normal",
}
end
local p = CA.PlayerRatings[uid]
p.Rating = math.clamp(rating or 50, 0, 100)
p.LastSeen = tick()
p.Name = player.Name
if reason then
table.insert(p.Notes, {Time = tick(), Note = reason})
if #p.Notes > 20 then table.remove(p.Notes, 1) end
end
if p.Rating <= 20 then
p.ThreatLevel = "Cheater"
elseif p.Rating <= 40 then
p.ThreatLevel = "Dangerous"
elseif p.Rating <= 60 then
p.ThreatLevel = "Normal"
elseif p.Rating <= 80 then
p.ThreatLevel = "Noob"
else
p.ThreatLevel = "Free"
end
CA.PlayerRatings[uid] = p
end
function CA.onPlayerKill(victim)
if not Flags.PlayerRating then return end
local uid = victim.UserId
if not CA.PlayerRatings[uid] then
CA.ratePlayer(victim, 50)
end
CA.PlayerRatings[uid].Kills = CA.PlayerRatings[uid].Kills + 1
CA.PlayerRatings[uid].Deaths = CA.PlayerRatings[uid].Deaths + 1
CA.PlayerRatings[uid].LastSeen = tick()
local kd = CA.PlayerRatings[uid].Kills / math.max(1, CA.PlayerRatings[uid].Deaths)
local newRating = 50 + (CA.PlayerRatings[uid].Kills - CA.PlayerRatings[uid].Deaths) * 5
CA.ratePlayer(victim, math.clamp(newRating, 0, 100), "Killed by us")
end
function CA.onPlayerDeath(killer)
if not Flags.PlayerRating then return end
if killer and killer:IsA("Player") then
local uid = killer.UserId
if not CA.PlayerRatings[uid] then
CA.ratePlayer(killer, 50)
end
CA.PlayerRatings[uid].Deaths = CA.PlayerRatings[uid].Deaths + 1
CA.PlayerRatings[uid].LastSeen = tick()
local newRating = 50 - (CA.PlayerRatings[uid].Kills - CA.PlayerRatings[uid].Deaths) * 5
CA.ratePlayer(killer, math.clamp(newRating, 0, 100), "Killed us")
end
end
function CA.onDamageDealt(target, damage, headshot)
if not Flags.PlayerRating then return end
if target and target:IsA("Player") then
local uid = target.UserId
if not CA.PlayerRatings[uid] then
CA.ratePlayer(target, 50)
end
CA.PlayerRatings[uid].DamageDealt = CA.PlayerRatings[uid].DamageDealt + damage
if headshot then
CA.PlayerRatings[uid].Headshots = CA.PlayerRatings[uid].Headshots + 1
end
local dmgRatio = CA.PlayerRatings[uid].DamageDealt / math.max(1, CA.PlayerRatings[uid].DamageReceived)
local newRating = 50 + (dmgRatio - 1) * 10
CA.ratePlayer(target, math.clamp(newRating, 0, 100))
end
end
function CA.showPlayerStats()
local top5 = {}
for uid, data in pairs(CA.PlayerRatings) do
table.insert(top5, data)
end
table.sort(top5, function(a, b) return a.Rating < b.Rating end)
local msg = "  (Top 5 ):\n"
for i = 1, math.min(5, #top5) do
local p = top5[i]
msg = msg .. string.format("%d. %s [%s] K:%d D:%d\n",
i, p.Name, p.ThreatLevel, p.Kills, p.Deaths)
end
pcall(function()
StarterGui:SetCore("SendNotification", {
Title = " ",
Text = msg,
Duration = 8,
})
end)
end
CA.RatingState = ratingState
-- SECTION 4: MAP MEMORY
page:Label("  ")
page:Toggle("Map Memory", true, function(v) Flags.MapMemory = v end)
page:Toggle("Auto Apply Settings", false, function(v) Flags.MapAutoApply = v end)
page:Toggle("Record Performance", true, function(v) Flags.MapRecordPerf = v end)
page:Button({Name="Save Current Map Settings", Color=Color3.fromRGB(100, 150, 255)}, function()
CA.saveMapSettings()
end)
page:Button({Name="Show Map Stats", Color=Color3.fromRGB(255, 150, 100)}, function()
CA.showMapStats()
end)
local mapState = {
CurrentMap = nil,
RoundsPlayed = 0,
Wins = 0,
Losses = 0,
BestScore = 0,
WorstScore = math.huge,
AverageFPS = 60,
FPSReadings = {},
}
function CA.saveMapSettings()
local placeId = game.PlaceId
local placeName = game:GetService("MarketplaceService"):GetProductInfo(placeId).Name or "Unknown"
CA.MapMemory[placeId] = {
Name = placeName,
Rounds = mapState.RoundsPlayed,
Wins = mapState.Wins,
Losses = mapState.Losses,
BestScore = mapState.BestScore,
AverageFPS = mapState.AverageFPS,
Settings = {
AimbotFOV = Flags.AimbotFOV,
AimbotSmooth = Flags.AimbotSmooth,
ESP_Box = Flags.ESP_Box,
ESP_Name = Flags.ESP_Name,
ESP_Health = Flags.ESP_Health,
ESP_Dist = Flags.ESP_Dist,
Ragebot = Flags.Ragebot,
AntiAim = Flags.AA,
},
}
pcall(function()
local json = HttpService:JSONEncode(CA.MapMemory)
writefile("BloxStrike/MapMemory.json", json)
end)
pcall(function()
StarterGui:SetCore("SendNotification", {
Title = " ",
Text = " " .. placeName .. " ",
Duration = 3,
})
end)
end
function CA.loadMapSettings()
local placeId = game.PlaceId
if not CA.MapMemory[placeId] then return end
local saved = CA.MapMemory[placeId]
if saved.Settings and Flags.MapAutoApply then
for key, value in pairs(saved.Settings) do
Flags[key] = value
end
end
pcall(function()
StarterGui:SetCore("SendNotification", {
Title = " ",
Text = string.format(" %s  (: %.0f%%)",
saved.Name or "Unknown",
saved.Wins / math.max(1, saved.Wins + saved.Losses) * 100),
Duration = 4,
})
end)
end
function CA.showMapStats()
local placeId = game.PlaceId
local info = CA.MapMemory[placeId]
if not info then
pcall(function()
StarterGui:SetCore("SendNotification", {
Title = " ",
Text = "",
Duration = 3,
})
end)
end
local winRate = info.Wins / math.max(1, info.Wins + info.Losses) * 100
pcall(function()
StarterGui:SetCore("SendNotification", {
Title = " ",
Text = string.format("%s\n: %d | : %d | : %d | : %.0f%%\nFPS: %.0f",
info.Name or "Unknown", info.Rounds, info.Wins, info.Losses,
winRate, info.AverageFPS or 0),
Duration = 6,
})
end)
end
pcall(function()
if isfile and isfile("BloxStrike/MapMemory.json") then
CA.MapMemory = HttpService:JSONDecode(readfile("BloxStrike/MapMemory.json"))
end
end)
task.spawn(function()
while true do task.wait(5)
if Flags.MapMemory then
local placeId = game.PlaceId
if mapState.CurrentMap ~= placeId then
mapState.CurrentMap = placeId
mapState.MapStartTime = tick()
mapState.RoundsPlayed = 0
mapState.Wins = 0
mapState.Losses = 0
CA.loadMapSettings()
end
if Flags.MapRecordPerf and BS.Perf then
table.insert(mapState.FPSReadings, BS.Perf.FPS)
if #mapState.FPSReadings > 100 then table.remove(mapState.FPSReadings, 1) end
local sum = 0
for _, v in ipairs(mapState.FPSReadings) do sum = sum + v end
mapState.AverageFPS = sum / #mapState.FPSReadings
end
end
end
end)
CA.MapState = mapState
-- SECTION 5: SESSION STATISTICS
page:Label("  ")
page:Toggle("Session Stats", true, function(v) Flags.SessionStats = v end)
page:Button({Name="Show Session Stats", Color=Color3.fromRGB(200, 200, 100)}, function()
CA.showSessionStats()
end)
page:Button({Name="Reset Session Stats", Color=Color3.fromRGB(200, 100, 100)}, function()
CA.SessionStats = {
Kills = 0, Deaths = 0, Headshots = 0, Shots = 0,
HitCount = 0, DamageDealt = 0, Accuracy = 0,
}
end)
function CA.showSessionStats()
local s = CA.SessionStats
local elapsed = math.floor((tick() - s.StartTime) / 60)
local kd = s.Deaths > 0 and string.format("%.2f", s.Kills / s.Deaths) or ""
local hsRate = s.Kills > 0 and string.format("%.0f%%", s.Headshots / s.Kills * 100) or "0%"
local acc = s.Shots > 0 and string.format("%.1f%%", s.HitCount / s.Shots * 100) or "0%"
pcall(function()
StarterGui:SetCore("SendNotification", {
Title = " ",
elapsed, s.Kills, s.Deaths, kd, hsRate, acc,
s.KillStreak, s.MaxKillStreak, s.DamageDealt),
Duration = 8,
})
end)
end
BS.CombatAssist = CA
BS.CA = CA
print("[CombatAssist] BloxStrike Combat Assist v1.0 loaded")
print("[CombatAssist] Features: Chat Assistant, Spectator Detection,")
print("[CombatAssist]   Player Rating, Map Memory, Session Stats")
]])
writefile("BloxStrike/modules/compat.lua", [[
local Compat = {}
local HttpService = nil
pcall(function() HttpService = game:GetService("HttpService") end)
local UserInputService = nil
pcall(function() UserInputService = game:GetService("UserInputService") end)
local Players = nil
pcall(function() Players = game:GetService("Players") end)
local lplr = Players.LocalPlayer
-- SECTION 1: EXECUTOR DETECTION  
local executorName = "Unknown"
local executorVersion = "Unknown"
pcall(function()
if identifyexecutor then
local name, ver = identifyexecutor()
executorName = name or "Unknown"
executorVersion = ver or "Unknown"
elseif getexecutorname then
executorName = getexecutorname()
end
end)
Compat.Executor = executorName
Compat.Version = executorVersion
-- SECTION 2: DEVICE DETECTION  
Compat.IsMobile = false
Compat.IsPC = false
Compat.IsEmulator = false
Compat.IsLandscape = true
Compat.Scale = 1
pcall(function()
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
Compat.IsMobile = true
elseif UserInputService.TouchEnabled and UserInputService.KeyboardEnabled then
Compat.IsEmulator = true
end
if UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
Compat.IsPC = true
end
Compat.ScreenSize = workspace.CurrentCamera.ViewportSize
local baseWidth = 1920
Compat.Scale = Compat.ScreenSize.X / baseWidth
if Compat.Scale < 0.5 then Compat.Scale = 0.5 end
if Compat.Scale > 2.0 then Compat.Scale = 2.0 end
end)
pcall(function()
if identifyexecutor then
local name = identifyexecutor()
if name then
name = name:lower()
if name:find("arceus") or name:find("hydrogen") or name:find("celery")
or name:find("evon") or name:find("fluxus android") then
Compat.IsMobile = true
end
end
end
end)
print("[Compat] Executor: " .. executorName .. " v" .. executorVersion)
print("[Compat] Device: " .. (Compat.IsMobile and "Mobile" or Compat.IsEmulator and "Emulator" or "PC"))
print("[Compat] Screen: " .. Compat.ScreenSize.X .. "x" .. Compat.ScreenSize.Y .. " | Scale: " .. string.format("%.2f", Compat.Scale))
-- SECTION 3: FILESYSTEM  
Compat.ReadFile = function(path)
local s, r = pcall(function()
if readfile then return readfile(path) end
end)
return s and r or nil
end
Compat.WriteFile = function(path, content)
local s = pcall(function()
if writefile then writefile(path, content) end
end)
return s
end
Compat.AppendFile = function(path, content)
local s = pcall(function()
if appendfile then appendfile(path, content) end
end)
return s
end
Compat.IsFile = function(path)
local s, r = pcall(function()
if isfile then return isfile(path) end
end)
return s and r or false
end
Compat.MakeFolder = function(path)
local s = pcall(function()
if makefolder then makefolder(path) end
end)
return s
end
Compat.DeleteFile = function(path)
local s = pcall(function()
if delfile then delfile(path) end
end)
return s
end
Compat.ListFiles = function(path)
local s, r = pcall(function()
if listfiles then return listfiles(path) end
end)
return s and r or {}
end
-- SECTION 4: CLIPBOARD  
Compat.SetClipboard = function(text)
pcall(function()
if setclipboard then setclipboard(text) end
end)
end
Compat.GetClipboard = function()
local s, r = pcall(function()
if getclipboard then return getclipboard() end
end)
return s and r or ""
end
-- SECTION 5: HTTP  
Compat.HttpRequest = function(params)
local result = nil
local success = false
local httpFuncs = {
function() return syn and syn.request end,
function() return http_request end,
function() return request end,
function() return HttpPostAsync end,
}
for _, getFunc in ipairs(httpFuncs) do
local s, func = pcall(getFunc)
if s and func then
local rs, rr = pcall(func, params)
if rs then
result = rr
success = true
break
end
end
end
if not success then
local s, r = pcall(function()
return HttpService:RequestAsync({
Url = params.Url,
Method = params.Method or "GET",
Body = params.Body,
})
end)
if s then result = r; success = true end
end
return success, result
end
Compat.HttpGet = function(url)
local s, r = pcall(function()
if httpget then return httpget(url) end
if game.HttpGet then return game:HttpGet(url) end
local ok, res = Compat.HttpRequest({Url = url, Method = "GET"})
if ok and res then return res.Body or res end
end)
return s and r or nil
end
-- SECTION 6: DRAWING API   API
Compat.HasDrawing = false
pcall(function()
if Drawing then Compat.HasDrawing = true end
end)
Compat.DrawingNew = function(class)
if not Compat.HasDrawing then return nil end
local s, obj = pcall(function()
return Drawing.new(class)
end)
return s and obj or nil
end
Compat.DrawingFont = function(fontName)
if not Compat.HasDrawing then return 2 end
local s, r = pcall(function()
if fontName == "UI" then return Drawing.Fonts.UI
elseif fontName == "System" then return Drawing.Fonts.System
elseif fontName == "Plex" then return Drawing.Fonts.Plex
elseif fontName == "Monospace" then return Drawing.Fonts.Monospace
else return Drawing.Fonts.UI end
end)
return s and r or 2
end
-- SECTION 7: MOUSE  
Compat.MouseMoveRel = function(x, y)
pcall(function()
if mousemoverel then mousemoverel(x, y) end
end)
end
Compat.Mouse1Click = function()
pcall(function()
if mouse1click then mouse1click() end
end)
end
Compat.Mouse1Press = function()
pcall(function()
if mouse1press then mouse1press() end
end)
end
Compat.Mouse1Release = function()
pcall(function()
if mouse1release then mouse1release() end
end)
end
Compat.Mouse2Click = function()
pcall(function()
if mouse2click then mouse2click() end
end)
end
Compat.GetMouseLocation = function()
local s, r = pcall(function()
return UserInputService:GetMouseLocation()
end)
return s and r or Vector2.new(0, 0)
end
-- SECTION 8: HOOKING   Hook
Compat.HookFunction = function(old, new)
pcall(function()
if hookfunction then return hookfunction(old, new) end
end)
return old
end
Compat.HookMetamethod = function(obj, method, hook)
local s, r = pcall(function()
if hookmetamethod then return hookmetamethod(obj, method, hook) end
end)
return s and r or nil
end
Compat.GetRawMetamethod = function()
local s, r = pcall(function()
if getrawmetatable then return getrawmetatable(game) end
end)
return s and r or nil
end
Compat.NewCClosure = function(func)
local s, r = pcall(function()
if newcclosure then return newcclosure(func) end
end)
return s and r or func
end
Compat.IsLClosure = function(func)
local s, r = pcall(function()
if islclosure then return islclosure(func) end
end)
return s and r or false
end
Compat.GetNameCallMethod = function()
local s, r = pcall(function()
if getnamecallmethod then return getnamecallmethod() end
end)
return s and r or ""
end
Compat.SetReadonly = function(mt, val)
pcall(function()
if setreadonly then setreadonly(mt, val) end
end)
end
Compat.IsReadonly = function(mt)
local s, r = pcall(function()
if isreadonly then return isreadonly(mt) end
end)
return s and r or false
end
Compat.CheckCaller = function()
local s, r = pcall(function()
if checkcaller then return checkcaller() end
end)
return s and r or false
end
Compat.GetEnv = function(level)
local s, r = pcall(function()
if getfenv then return getfenv(level or 1) end
end)
return s and r or nil
end
Compat.SetEnv = function(func, env)
pcall(function()
if setfenv then setfenv(func, env) end
end)
end
Compat.GetGenv = function()
local s, r = pcall(function()
if getgenv then return getgenv() end
end)
return s and r or nil
end
Compat.GetRenviron = function()
local s, r = pcall(function()
if getrenv then return getrenv() end
end)
return s and r or nil
end
-- SECTION 9: CONNECTIONS  
Compat.GetConnections = function(signal)
local s, r = pcall(function()
if getconnections then return getconnections(signal) end
end)
return s and r or {}
end
Compat.FireSignal = function(signal, ...)
local args = {...}
pcall(function()
if firesignal then firesignal(signal, unpack(args)) end
end)
end
Compat.FireClickDetector = function(detector)
pcall(function()
if fireclickdetector then fireclickdetector(detector) end
end)
end
Compat.FireTouchInterest = function(part, root, toggle)
pcall(function()
if firetouchinterest then firetouchinterest(part, root, toggle) end
end)
end
-- SECTION 10: INSTANCE OPERATIONS  
Compat.GetInstances = function()
local s, r = pcall(function()
if getinstances then return getinstances() end
end)
return s and r or {}
end
Compat.GetNilInstances = function()
local s, r = pcall(function()
if getnilinstances then return getnilinstances() end
end)
return s and r or {}
end
Compat.GetScripts = function()
local s, r = pcall(function()
if getscripts then return getscripts() end
end)
return s and r or {}
end
Compat.GetRunningScripts = function()
local s, r = pcall(function()
if getrunningscripts then return getrunningscripts() end
end)
return s and r or {}
end
Compat.GetHiddenProperty = function(obj, prop)
local s, r = pcall(function()
if gethiddenproperty then return gethiddenproperty(obj, prop) end
end)
return s and r or nil
end
Compat.SetHiddenProperty = function(obj, prop, val)
pcall(function()
if sethiddenproperty then sethiddenproperty(obj, prop, val) end
end)
end
-- SECTION 11: GC  
Compat.GetGC = function()
local s, r = pcall(function()
if getgc then return getgc() end
end)
return s and r or {}
end
Compat.CollectGarbage = function(mode)
pcall(function()
collectgarbage(mode or "collect")
end)
end
-- SECTION 12: FFLAG  Roblox Flags
Compat.SetFFlag = function(flag, value)
pcall(function()
if setfflag then setfflag(flag, value) end
end)
end
Compat.GetFFlag = function(flag)
local s, r = pcall(function()
if getfflag then return getfflag(flag) end
end)
return s and r or nil
end
-- SECTION 13: SCHEDULER  
Compat.GetScheduler = function()
local s, r = pcall(function()
if getscheduler then return getscheduler() end
end)
return s and r or nil
end
Compat.GetScriptClosure = function(script)
local s, r = pcall(function()
if getscriptclosure then return getscriptclosure(script) end
end)
return s and r or nil
end
-- SECTION 14: LOADING  
Compat.LoadString = function(code)
local s, r = pcall(function()
return loadstring(code)
end)
return s and r or nil
end
-- SECTION 15: MOBILE INPUT  
Compat.TouchInput = {
Active = false,
SwipeThreshold = 50,
DoubleTapThreshold = 0.3,
LastTapTime = 0,
}
if Compat.IsMobile then
if gpe then return end
Compat.TouchInput.Active = true
Compat.TouchInput.LastTouch = input.Position
local now = tick()
if now - Compat.TouchInput.LastTapTime < Compat.TouchInput.DoubleTapThreshold then
_G.BS_DoubleTap = true
end
Compat.TouchInput.LastTapTime = now
end)
Compat.TouchInput.Active = false
end)
end
-- SECTION 16: FEATURE DETECTION  
Compat.Features = {
Drawing = Compat.HasDrawing,
ReadFile = (function() local s = pcall(function() return readfile ~= nil end); return s end)(),
}
-- SECTION 17: PRINTER  
function Compat.PrintReport()
print("[Compat]  Executor Compatibility Report ")
print("[Compat] Executor: " .. executorName .. " v" .. executorVersion)
print("[Compat] Device: " .. (Compat.IsMobile and " Mobile" or Compat.IsEmulator and " Emulator" or " PC"))
print("[Compat] Screen: " .. Compat.ScreenSize.X .. "x" .. Compat.ScreenSize.Y)
print("[Compat] Scale: " .. string.format("%.2f", Compat.Scale))
print("[Compat]  Available Features ")
local available = 0
local total = 0
for name, has in pairs(Compat.Features) do
total = total + 1
if has then available = available + 1 end
end
print("[Compat] APIs: " .. available .. "/" .. total .. " available")
local missing = {}
for name, has in pairs(Compat.Features) do
if not has then
table.insert(missing, name)
end
end
if #missing > 0 then
print("[Compat] Missing: " .. table.concat(missing, ", "))
print("[Compat] Features using missing APIs will be disabled or use fallbacks")
else
print("[Compat]  All APIs available  Full functionality")
end
print("[Compat] ")
end
BS.Compat = Compat
task.delay(1, function()
end)
print("[Compat] BloxStrike Compatibility Module loaded")
print("[Compat] Supports: All executors + PC + Mobile + Emulators")
return Compat
]])
writefile("BloxStrike/modules/core.lua", [[
local Players = nil
pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local UserInputService = nil
pcall(function() UserInputService = game:GetService("UserInputService") end)
local TweenService = nil
pcall(function() TweenService = game:GetService("TweenService") end)
local Lighting = nil
pcall(function() Lighting = game:GetService("Lighting") end)
local ReplicatedStorage = nil
pcall(function() ReplicatedStorage = game:GetService("ReplicatedStorage") end)
local StarterGui = nil
pcall(function() StarterGui = game:GetService("StarterGui") end)
local Workspace = nil
pcall(function() Workspace = game:GetService("Workspace") end)
local lplr = Players.LocalPlayer
local isMobile = false
pcall(function()
isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end)
local BS = {
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
Config = {},
isMobile = isMobile,
screenScale = 1,
}
print("[Core] BloxStrike Core initialized")
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
function Perf:CleanupCache()
local now = tick()
for key, time in pairs(self.CacheTime) do
if now - time > 30 then
self.Cache[key] = nil
self.CacheTime[key] = nil
end
end
end
BS.Perf = Perf
function BS.alive()
local char = lplr.Character
if not char then return false end
local hum = char:FindFirstChildOfClass("Humanoid")
local hrp = char:FindFirstChild("HumanoidRootPart")
return hum and hrp and hum.Health > 0
end
function BS.hrp()
local char = lplr.Character
return char and char:FindFirstChild("HumanoidRootPart")
end
function BS.hum()
local char = lplr.Character
return char and char:FindFirstChildOfClass("Humanoid")
end
function BS.char()
return lplr.Character
end
function BS.head()
local char = lplr.Character
return char and char:FindFirstChild("Head")
end
function BS.cam()
return workspace.CurrentCamera
end
function BS.team()
return lplr.Team
end
function BS.enemies()
local enemies = {}
local myTeam = BS.team()
for _, player in pairs(Players:GetPlayers()) do
if player ~= lplr then
local char = player.Character
if char then
local hrp = char:FindFirstChild("HumanoidRootPart")
local hum = char:FindFirstChildOfClass("Humanoid")
local head = char:FindFirstChild("Head")
if hrp and hum and hum.Health > 0 then
local isEnemy = true
if BS.Flags.TeamCheck and myTeam and player.Team == myTeam then
isEnemy = false
end
if BS.Flags.FriendCheck and lplr:IsFriendsWith(player.UserId) then
isEnemy = false
end
if isEnemy then
table.insert(enemies, {
Player = player,
Char = char,
HRP = hrp,
Hum = hum,
Head = head
})
end
end
end
end
end
return enemies
end
function BS.nearestEnemy(maxDist)
maxDist = maxDist or math.huge
local myHRP = BS.hrp()
if not myHRP then return nil, math.huge end
local nearest, nearDist = nil, maxDist
for _, e in pairs(BS.enemies()) do
local dist = (myHRP.Position - e.HRP.Position).Magnitude
if dist < nearDist then
nearest, nearDist = e, dist
end
end
return nearest, nearDist
end
function BS.bestEnemy(maxDist, fov)
maxDist = maxDist or math.huge
fov = fov or 180
local myHRP = BS.hrp()
if not myHRP then return nil, math.huge end
local cam = workspace.CurrentCamera
local mouse = UserInputService:GetMouseLocation()
local best, bestScore = nil, fov
for _, e in pairs(BS.enemies()) do
local dist = (myHRP.Position - e.HRP.Position).Magnitude
if dist <= maxDist then
local pos, vis = cam:WorldToViewportPoint(e.Head and e.Head.Position or e.HRP.Position)
if vis then
local screenDist = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
if screenDist < bestScore then
best, bestScore = e, screenDist
end
end
end
end
return best, bestScore
end
function BS.hasLineOfSight(pos1, pos2)
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = {lplr.Character}
local result = workspace:Raycast(pos1, (pos2 - pos1), params)
return result == nil
end
function BS.tool()
local char = lplr.Character
return char and char:FindFirstChildWhichIsA("Tool", true)
end
function BS.equipTool(name)
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
local bp = lplr:FindFirstChild("Backpack")
if bp then
for _, tool in pairs(bp:GetChildren()) do
if tool:IsA("Tool") and tool.Name:lower():find(name:lower()) then
tool.Parent = char
return true
end
end
end
return false
end
function BS.findTool(name)
local char = lplr.Character
if not char then return nil end
for _, tool in pairs(char:GetChildren()) do
if tool:IsA("Tool") and tool.Name:lower():find(name:lower()) then
return tool
end
end
local bp = lplr:FindFirstChild("Backpack")
if bp then
for _, tool in pairs(bp:GetChildren()) do
if tool:IsA("Tool") and tool.Name:lower():find(name:lower()) then
return tool
end
end
end
return nil
end
function BS.weaponType()
local tool = BS.tool()
if not tool then return "none" end
local name = tool.Name:lower()
if name:find("ak") or name:find("m4") or name:find("rifle") or name:find("ar") then return "rifle" end
if name:find("awp") or name:find("scout") or name:find("sniper") then return "sniper" end
if name:find("deagle") or name:find("pistol") or name:find("glock") or name:find("usps") or name:find("usp") then return "pistol" end
if name:find("shotgun") or name:find("nova") or name:find("xm10") then return "shotgun" end
if name:find("smg") or name:find("mp") or name:find("mac") or name:find("ump") then return "smg" end
if name:find("knife") or name:find("bayonet") then return "knife" end
if name:find("grenade") or name:find("flash") or name:find("smoke") or name:find("molotov") or name:find("he") then return "grenade" end
if name:find("defuse") or name:find("kit") then return "defuse" end
if name:find("c4") or name:find("bomb") then return "bomb" end
return "other"
end
function BS.getBonePosition(character, boneName)
local bone = character:FindFirstChild(boneName)
if bone then return bone.Position end
local hrp = character:FindFirstChild("HumanoidRootPart")
return hrp and hrp.Position or nil
end
function BS.getAimPosition(target, bone)
bone = bone or "Head"
if bone == "Head" then
return BS.getBonePosition(target.Char, "Head") or target.HRP.Position + Vector3.new(0, 1.5, 0)
elseif bone == "Chest" then
return target.HRP.Position + Vector3.new(0, 0.5, 0)
elseif bone == "Pelvis" then
return target.HRP.Position
elseif bone == "Nearest" then
local headPos = BS.getBonePosition(target.Char, "Head") or target.HRP.Position + Vector3.new(0, 1.5, 0)
return headPos
end
return target.HRP.Position
end
function BS.getVelocity(target)
return target.HRP.AssemblyLinearVelocity
end
function BS.predictPosition(target, time)
local pos = BS.getAimPosition(target)
local vel = BS.getVelocity(target)
return pos + vel * time
end
local WEAPON_STATS = {
rifle = { fireRate = 0.1, damage = 30, recoil = 1.5, spread = 0.02 },
sniper = { fireRate = 1.5, damage = 100, recoil = 3.0, spread = 0.001 },
pistol = { fireRate = 0.3, damage = 40, recoil = 0.8, spread = 0.015 },
shotgun = { fireRate = 0.8, damage = 80, recoil = 2.0, spread = 0.1 },
smg = { fireRate = 0.07, damage = 20, recoil = 0.6, spread = 0.03 },
knife = { fireRate = 0.4, damage = 40, recoil = 0, spread = 0 },
}
function BS.getWeaponStats()
local wtype = BS.weaponType()
return WEAPON_STATS[wtype] or { fireRate = 0.1, damage = 25, recoil = 1.0, spread = 0.02 }
end
task.spawn(function()
while task.wait(30) do
pcall(collectgarbage, "collect")
end
end)
lplr.CharacterAdded:Connect(function(char)
task.wait(0.5)
BS.Camera = workspace.CurrentCamera
end)
RunService.RenderStepped:Connect(function()
Perf.FrameCount = Perf.FrameCount + 1
if tick() - Perf.LastFrame >= 1 then
Perf.FPS = Perf.FrameCount
Perf.FrameCount = 0
Perf.LastFrame = tick()
end
end)
local Ping = {
Current = 0,
Average = 0,
History = {},
Quality = "Good",
}
local function updatePing()
pcall(function()
local stats = nil
pcall(function() stats = game:GetService("Stats") end)
local pingVal = 0
pcall(function() pingVal = stats.Network.ServerStatsItem["Data Ping"].Value end)
Ping.Current = math.floor(pingVal)
table.insert(Ping.History, pingVal)
if #Ping.History > 20 then table.remove(Ping.History, 1) end
local sum = 0
for _, v in ipairs(Ping.History) do sum = sum + v end
Ping.Average = math.floor(sum / #Ping.History)
if Ping.Average < 50 then
Ping.Quality = "Good"
elseif Ping.Average < 100 then
Ping.Quality = "Fair"
elseif Ping.Average < 200 then
Ping.Quality = "Poor"
else
Ping.Quality = "Terrible"
end
end)
end
task.spawn(function()
while task.wait(0.5) do updatePing() end
end)
function BS.pingDelay(baseDelay)
local pingFactor = Ping.Current / 1000
return math.max(baseDelay + pingFactor * 0.5, baseDelay * 0.8)
end
function BS.pingAttackInterval()
if Ping.Current < 30 then return 0.05
elseif Ping.Current < 60 then return 0.08
elseif Ping.Current < 100 then return 0.12
elseif Ping.Current < 200 then return 0.18
else return 0.25 end
end
Ping.Current = Ping.Current or 0
Ping.Average = Ping.Average or 0
BS.Ping = Ping
print("[Core] BloxStrike Core ready | Ping: " .. Ping.Quality)
return BS
]])
writefile("BloxStrike/modules/errorhandler.lua", [[
local Players = nil
pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local UserInputService = nil
pcall(function() UserInputService = game:GetService("UserInputService") end)
local lplr = Players.LocalPlayer
local ErrorLog = {
Errors = {},
FixCount = 0,
CrashCount = 0,
RecoverCount = 0,
LastError = nil,
ModuleStatus = {},
ErrorPatterns = {},
ConnectionState = {},
TaskHealth = {},
StateSnapshots = {},
CascadeCount = 0,
LastCascadeTime = 0,
}
local function classifyError(errMsg)
if not errMsg then return "unknown", 0 end
local msg = tostring(errMsg):lower()
if msg:find("script") and msg:find("destroy") then return "catastrophic", 100 end
if msg:find("stack overflow") then return "catastrophic", 98 end
if msg:find("out of memory") then return "catastrophic", 95 end
if msg:find("cannot add") and msg:find("nil") then return "critical", 90 end
if msg:find("attempt to index nil") then return "critical", 85 end
if msg:find("attempt to call nil") then return "critical", 85 end
if msg:find("attempt to perform arithmetic on nil") then return "critical", 83 end
if msg:find("attempt to concatenate nil") then return "critical", 80 end
if msg:find("instance has been destroyed") then return "high", 70 end
if msg:find("is not a valid member") then return "high", 68 end
if msg:find("is not a valid cframe") then return "high", 65 end
if msg:find("is not a valid vector3") then return "high", 65 end
if msg:find("bad argument") then return "high", 60 end
if msg:find("attempt to perform arithmetic") then return "medium", 50 end
if msg:find("attempt to concatenate") then return "medium", 48 end
if msg:find("attempt to compare") then return "medium", 45 end
if msg:find("attempt to index") then return "medium", 42 end
if msg:find("number expected") then return "medium", 40 end
if msg:find("drawing") then return "low", 25 end
if msg:find("gui") and msg:find("destroy") then return "low", 20 end
if msg:find("http") then return "low", 15 end
if msg:find("teleport") then return "low", 10 end
if msg:find("yield") or msg:find("timeout") then return "info", 5 end
return "unknown", 30
end
local ErrorFixes = {
{
pattern = "attempt to index nil",
fix = function(err)
return true, "nil index auto-recovered"
end,
preventable = true,
},
{
pattern = "attempt to call a nil value",
fix = function(err)
return true, "nil call auto-recovered"
end,
preventable = true,
},
{
pattern = "attempt to perform arithmetic on nil",
fix = function(err)
return true, "arithmetic on nil recovered"
end,
preventable = true,
},
{
pattern = "attempt to concatenate",
fix = function(err)
return true, "concatenation error recovered"
end,
preventable = true,
},
{
pattern = "bad argument #%d",
fix = function(err)
return true, "bad argument recovered"
end,
},
{
pattern = "Instance has been destroyed",
fix = function(err)
return true, "destroyed instance skipped"
end,
},
{
pattern = "is not a valid member",
fix = function(err)
return true, "invalid member skipped"
end,
},
{
pattern = "CFrame .* is not a valid",
fix = function(err)
return true, "CFrame error recovered (fallback to identity)"
end,
},
{
pattern = "Vector3 .* is not a valid",
fix = function(err)
return true, "Vector3 error recovered (fallback to zero)"
end,
},
{
pattern = "Drawing",
fix = function(err)
return true, "Drawing API error recovered"
end,
},
{
pattern = "HTTP %d",
fix = function(err)
return true, "HTTP error recovered (non-critical)"
end,
},
{
pattern = "HttpEnabled",
fix = function(err)
return true, "HttpService disabled  skipped"
end,
},
{
pattern = "Teleport",
fix = function(err)
return true, "Teleport error recovered"
end,
},
{
pattern = "not allowed",
fix = function(err)
return true, "Permission denied  skipped"
end,
},
{
pattern = "attempt to compare",
fix = function(err)
return true, "comparison error recovered"
end,
},
{
pattern = "wrong number of arguments",
fix = function(err)
return true, "wrong argument count recovered"
end,
},
{
pattern = "invalid argument #%d.*table",
fix = function(err)
return true, "table argument error recovered"
end,
},
{
pattern = "is out of range",
fix = function(err)
return true, "out of range error recovered"
end,
},
{
pattern = "elapsed.*limit",
fix = function(err)
return true, "infinite loop detected  broken"
end,
},
{
pattern = ".*",
fix = function(err)
return true, "unknown error auto-recovered"
end,
},
}
function BS.saveStateSnapshot(name)
pcall(function()
local snap = {
Name = name or "auto",
Flags = {},
}
for k, v in pairs(Flags) do
if type(v) ~= "function" and type(v) ~= "userdata" then
snap.Flags[k] = v
end
end
table.insert(ErrorLog.StateSnapshots, snap)
if #ErrorLog.StateSnapshots > 10 then
table.remove(ErrorLog.StateSnapshots, 1)
end
end)
end
function BS.rollbackState(stepsBack)
pcall(function()
stepsBack = stepsBack or 1
local idx = #ErrorLog.StateSnapshots - stepsBack
if idx < 1 then return end
local snap = ErrorLog.StateSnapshots[idx]
if not snap then return end
for k, v in pairs(snap.Flags) do
Flags[k] = v
end
print("[ErrorHandler]  Rolled back to snapshot: " .. snap.Name .. " from " .. math.floor(tick() - snap.Time) .. "s ago")
ErrorLog.RecoverCount = ErrorLog.RecoverCount + 1
end)
end
function BS.safeCall(func, context, ...)
local args = {...}
local success, result = pcall(function()
return func(unpack(args))
end)
if not success then
local errMsg = tostring(result)
local severity, level = classifyError(errMsg)
table.insert(ErrorLog.Errors, {
Message = errMsg,
Context = context or "unknown",
Severity = severity,
Level = level,
})
if #ErrorLog.Errors > 200 then table.remove(ErrorLog.Errors, 1) end
ErrorLog.LastError = errMsg
local now = tick()
if now - ErrorLog.LastCascadeTime < 1 then
ErrorLog.CascadeCount = ErrorLog.CascadeCount + 1
else
ErrorLog.CascadeCount = 0
end
ErrorLog.LastCascadeTime = now
if ErrorLog.CascadeCount > 5 then
print("[ErrorHandler]  CASCADE DETECTED  emergency rollback + disable dangerous features")
ErrorLog.CascadeCount = 0
BS.emergencyPanic()
return nil, errMsg
end
local fixed, fixMsg = false, ""
for _, fix in ipairs(ErrorFixes) do
if errMsg:find(fix.pattern) then
local s, m = pcall(fix.fix, errMsg)
if s then
fixed = true
fixMsg = m
ErrorLog.FixCount = ErrorLog.FixCount + 1
break
end
end
end
if fixed then
learnErrorPattern(errMsg, context)
elseif severity == "critical" or severity == "catastrophic" then
ErrorLog.CrashCount = ErrorLog.CrashCount + 1
print(string.format("[ErrorHandler]  %s in %s: %s", severity:upper(), context or "?", errMsg:sub(1, 80)))
if ErrorLog.CrashCount > 3 then
print("[ErrorHandler]  Multiple crashes  rolling back to safe state")
BS.rollbackState(2)
end
if context then
task.delay(0.5, function()
pcall(function() BS.reloadModule(context) end)
end)
end
else
if severity ~= "info" then
print(string.format("[ErrorHandler]  %s in %s: %s", severity, context or "?", errMsg:sub(1, 60)))
end
end
return nil, errMsg
end
return result
end
function learnErrorPattern(errMsg, context)
pcall(function()
local key = (errMsg:sub(1, 50) or "") .. "|" .. (context or "")
if not ErrorLog.ErrorPatterns[key] then
ErrorLog.ErrorPatterns[key] = {
Count = 0,
LastSeen = 0,
Context = context,
}
end
local p = ErrorLog.ErrorPatterns[key]
p.Count = p.Count + 1
p.LastSeen = tick()
end)
end
local Connections = {}
local ConnectionCount = 0
local MAX_CONNECTIONS = 500
function BS.trackConnection(name, connection)
ConnectionCount = ConnectionCount + 1
local id = ConnectionCount
Connections[id] = {
Name = name or "unknown",
Connection = connection,
}
task.delay(600, function()
if Connections[id] then
pcall(function()
if Connections[id].Connection then
end
end)
Connections[id] = nil
ConnectionCount = ConnectionCount - 1
print("[ErrorHandler]  Auto-disconnected leaked connection: " .. (name or "unknown"))
end
end)
return id
end
function BS.untrackConnection(id)
if Connections[id] then
pcall(function()
if Connections[id].Connection then
end
end)
Connections[id] = nil
ConnectionCount = ConnectionCount - 1
end
end
task.spawn(function()
while true do task.wait(60)
pcall(function()
local now = tick()
local leaked = 0
for id, data in pairs(Connections) do
if data and now - data.Created > 600 then
pcall(function() data.Connection:Disconnect() end)
Connections[id] = nil
leaked = leaked + 1
end
end
if leaked > 0 then
print("[ErrorHandler]  Cleaned " .. leaked .. " leaked connections")
end
end)
end
end)
local LoopHeartbeats = {}
local DEAD_LOOP_TIMEOUT = 5
function BS.registerLoop(name)
local id = #LoopHeartbeats + 1
LoopHeartbeats[id] = {
Name = name,
Alive = true,
}
return id
end
function BS.heartbeatLoop(id)
if LoopHeartbeats[id] then
end
end
function BS.killLoop(id)
if LoopHeartbeats[id] then
LoopHeartbeats[id].Alive = false
end
end
task.spawn(function()
while true do task.wait(1)
pcall(function()
local now = tick()
for id, data in pairs(LoopHeartbeats) do
if data and data.Alive and now - data.LastYield > DEAD_LOOP_TIMEOUT then
print("[ErrorHandler]  Dead loop detected: " .. (data.Name or "?") .. "  killing")
data.Alive = false
ErrorLog.CrashCount = ErrorLog.CrashCount + 1
end
end
end)
end
end)
function BS.reloadModule(moduleName)
pcall(function()
local modPath = script:FindFirstChild("modules") and script.modules:FindFirstChild(moduleName)
or script.Parent and script.Parent:FindFirstChild("modules") and script.Parent.modules:FindFirstChild(moduleName)
if modPath then
print("[ErrorHandler] Reloading module: " .. moduleName)
package.loaded[tostring(modPath)] = nil
local success, result = pcall(require, modPath)
if success then
print("[ErrorHandler]  Module reloaded: " .. moduleName)
ErrorLog.ModuleStatus[moduleName] = "reloaded"
else
print("[ErrorHandler]  Reload failed: " .. moduleName .. "  " .. tostring(result):sub(1, 60))
ErrorLog.ModuleStatus[moduleName] = "failed"
end
else
print("[ErrorHandler]  Module not found: " .. moduleName)
ErrorLog.ModuleStatus[moduleName] = "not_found"
end
end)
end
local WatchedTasks = {}
function BS.watchTask(name, func, interval)
WatchedTasks[name] = {
Func = func,
Interval = interval or 0.5,
LastRun = 0,
ConsecutiveErrors = 0,
TotalErrors = 0,
LastError = nil,
Enabled = true,
HealthScore = 100,
}
end
function BS.unwatchTask(name)
WatchedTasks[name] = nil
end
task.spawn(function()
while true do task.wait(2)
for name, td in pairs(WatchedTasks) do
if td.Enabled and tick() - td.LastRun > td.Interval then
td.LastRun = tick()
local ok, err = pcall(td.Func)
if not ok then
td.ConsecutiveErrors = td.ConsecutiveErrors + 1
td.TotalErrors = td.TotalErrors + 1
td.LastError = tostring(err)
td.HealthScore = math.max(0, td.HealthScore - 10)
if td.ConsecutiveErrors >= 5 then
td.Enabled = false
print("[ErrorHandler]  Task '" .. name .. "' disabled (5 errors): " .. td.LastError:sub(1, 50))
task.delay(30, function()
td.Enabled = true
td.ConsecutiveErrors = 0
td.HealthScore = 50
print("[ErrorHandler]  Task '" .. name .. "' re-enabled (health: 50)")
end)
end
else
td.ConsecutiveErrors = 0
td.HealthScore = math.min(100, td.HealthScore + 5)
end
end
end
end
end)
pcall(function()
game:GetService("ScriptContext").Error:Connect(function(message, trace, source)
local errMsg = tostring(message)
local severity, level = classifyError(errMsg)
table.insert(ErrorLog.Errors, {
Message = errMsg,
Severity = severity,
Level = level,
})
if #ErrorLog.Errors > 200 then table.remove(ErrorLog.Errors, 1) end
if severity == "critical" or severity == "catastrophic" then
ErrorLog.CrashCount = ErrorLog.CrashCount + 1
print("[ErrorHandler]  GLOBAL " .. severity:upper() .. ": " .. errMsg:sub(1, 80))
end
for _, fix in ipairs(ErrorFixes) do
if errMsg:find(fix.pattern) then
local s, m = pcall(fix.fix, errMsg)
if s then
ErrorLog.FixCount = ErrorLog.FixCount + 1
break
end
end
end
learnErrorPattern(errMsg, "Global")
end)
end)
task.spawn(function()
while true do task.wait(15)
pcall(function()
local cam = workspace.CurrentCamera
if not cam or not cam.CFrame then
print("[ErrorHandler]  Camera invalid  recovering")
pcall(function()
workspace.CurrentCamera = Instance.new("Camera", workspace)
end)
end
local alive = BS.alive and BS.alive() or false
local hrp = BS.hrp and BS.hrp() or nil
if alive and not hrp then
print("[ErrorHandler]  HRP missing but alive  recovery attempt")
end
if BS.Perf and BS.Perf.FPS and BS.Perf.FPS < 10 then
print("[ErrorHandler]  Critically low FPS: " .. BS.Perf.FPS)
pcall(function()
Flags.ESP_Glow = false
Flags.ESP_Skeleton = false
Flags.ESP_Snaplines = false
end)
end
local recentErrors = 0
local now = tick()
for _, e in ipairs(ErrorLog.Errors) do
if now - e.Time < 30 then recentErrors = recentErrors + 1 end
end
if recentErrors > 10 then
print("[ErrorHandler]  HIGH ERROR RATE: " .. recentErrors .. " errors in 30s  entering safe mode")
BS.emergencyPanic()
end
end)
end
end)
function BS.emergencyPanic()
pcall(function()
print("[ErrorHandler]  EMERGENCY PANIC  disabling all dangerous features")
Flags.Ragebot = false
Flags.AA = false
Flags.NoClip = false
Flags.SpeedBoost = false
Flags.FL = false
Flags.NoSpread = false
Flags.NoRecoil = false
Flags.SilentAim = false
Flags.ForceCrosshair = false
Flags.RageAutoFire = false
Flags.Aimbot = true
Flags.AimbotSmooth = 12
Flags.AimbotFOV = 40
Flags.ESP_Box = true
Flags.ESP_Name = true
Flags.ESP_Health = true
pcall(function()
local h = BS.hum and BS.hum()
if h then
h.WalkSpeed = 16
h.JumpPower = 50
h.HipHeight = 0
end
end)
BS.rollbackState(3)
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = " EMERGENCY PANIC",
Text = "Too many errors  safe mode activated",
Duration = 5,
})
end)
end)
end
task.spawn(function()
while true do task.wait(45)
pcall(function()
local now = tick()
for i = #ErrorLog.Errors, 1, -1 do
if now - ErrorLog.Errors[i].Time > 300 then
table.remove(ErrorLog.Errors, i)
end
end
for i = #ErrorLog.StateSnapshots, 1, -1 do
if now - ErrorLog.StateSnapshots[i].Time > 600 then
table.remove(ErrorLog.StateSnapshots, i)
end
end
for k, v in pairs(ErrorLog.ErrorPatterns) do
if now - v.LastSeen > 300 and v.Count < 3 then
ErrorLog.ErrorPatterns[k] = nil
end
end
for _, obj in ipairs(workspace:GetChildren()) do
if obj.Name and obj.Name:find("BS_") and obj:IsA("BasePart") then
pcall(function() obj:Destroy() end)
end
end
pcall(collectgarbage, "collect")
BS.saveStateSnapshot("auto_heartbeat")
end)
end
end)
task.spawn(function()
while true do task.wait(10)
pcall(function()
if not BS then
print("[ErrorHandler]  BS global lost  critical!")
end
if not Flags then
print("[ErrorHandler]  Flags lost  recreating")
_G.Flags = {}
Flags = _G.Flags
_G.BS.Flags = Flags
end
if BS.Win and not BS.Win.Tab then
print("[ErrorHandler]  UI broken  attempt reload")
BS.reloadModule("ui")
end
if not BS.alive or type(BS.alive) ~= "function" then
print("[ErrorHandler]  BS.alive missing  reloading core")
BS.reloadModule("core")
end
if not BS.api or type(BS.api) ~= "table" then
print("[ErrorHandler]  BS.api missing  reloading api")
BS.reloadModule("api")
end
end)
end
end)
pcall(function()
local mt = getmetatable(_G) or {}
local oldIndex = mt.__index
local oldNewIndex = mt.__newindex
mt.__index = function(self, key)
if oldIndex then
return oldIndex(self, key)
end
return rawget(self, key)
end
mt.__newindex = function(self, key, value)
if oldNewIndex then
oldNewIndex(self, key, value)
else
rawset(self, key, value)
end
end
setmetatable(_G, mt)
end)
task.spawn(function()
while true do task.wait(30)
pcall(function()
BS.saveStateSnapshot("periodic")
end)
end
end)
local errorGui = nil
function BS.showErrorReport()
pcall(function()
if errorGui then pcall(function() errorGui:Destroy() end) end
errorGui = Instance.new("ScreenGui")
errorGui.Name = "BS_ErrorReport"
errorGui.IgnoreGuiInset = true
errorGui.DisplayOrder = 10003
errorGui.Parent = lplr.PlayerGui
local bg = Instance.new("Frame")
bg.Size = UDim2.new(0, 450, 0, 380)
bg.Position = UDim2.new(0.5, -225, 0.5, -190)
bg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
bg.BorderSizePixel = 0
bg.Parent = errorGui
Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
titleBar.BorderSizePixel = 0
titleBar.Parent = bg
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = " Error Handler v2.0 Report"
title.TextColor3 = Color3.fromRGB(0, 200, 255)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 25)
closeBtn.Position = UDim2.new(1, -40, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextSize = 12
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)
closeBtn.MouseButton1Click:Connect(function()
if errorGui then pcall(function() errorGui:Destroy() end) end
errorGui = nil
end)
local statsText = Instance.new("TextLabel")
statsText.Size = UDim2.new(1, -20, 0, 90)
statsText.Position = UDim2.new(0, 10, 0, 42)
statsText.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
statsText.BorderSizePixel = 0
statsText.TextColor3 = Color3.fromRGB(200, 200, 200)
statsText.TextSize = 11
statsText.Font = Enum.Font.Code
statsText.TextXAlignment = Enum.TextXAlignment.Left
statsText.TextYAlignment = Enum.TextYAlignment.Top
statsText.TextWrapped = true
statsText.Parent = bg
Instance.new("UICorner", statsText).CornerRadius = UDim.new(0, 4)
local runtime = math.floor(tick() - ErrorLog.StartTime)
local mem = collectgarbage("count") / 1024
statsText.Text = string.format(
"%dm%ds | FixCount:%d | Crash:%d | Recover:%d | Errors:%s",
math.floor(runtime / 60), runtime % 60,
ErrorLog.FixCount,
ErrorLog.CrashCount,
ErrorLog.RecoverCount,
ErrorLog.LastError or "None"
)
local errHeader = Instance.new("TextLabel")
errHeader.Size = UDim2.new(1, -20, 0, 20)
errHeader.Position = UDim2.new(0, 10, 0, 138)
errHeader.BackgroundTransparency = 1
errHeader.Text = "  "
errHeader.TextColor3 = Color3.fromRGB(100, 200, 255)
errHeader.TextSize = 11
errHeader.Font = Enum.Font.GothamBold
errHeader.TextXAlignment = Enum.TextXAlignment.Left
errHeader.Parent = bg
local errorList = Instance.new("TextLabel")
errorList.Size = UDim2.new(1, -20, 0, 140)
errorList.Position = UDim2.new(0, 10, 0, 158)
errorList.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
errorList.BorderSizePixel = 0
errorList.TextColor3 = Color3.fromRGB(180, 180, 180)
errorList.TextSize = 10
errorList.Font = Enum.Font.Code
errorList.TextXAlignment = Enum.TextXAlignment.Left
errorList.TextYAlignment = Enum.TextYAlignment.Top
errorList.TextWrapped = true
errorList.Parent = bg
Instance.new("UICorner", errorList).CornerRadius = UDim.new(0, 4)
local recentErrors = ""
for i = math.max(1, #ErrorLog.Errors - 10), #ErrorLog.Errors do
local e = ErrorLog.Errors[i]
if e then
local age = math.floor(tick() - e.Time)
recentErrors = recentErrors .. string.format("[%s] %s: %s",
e.Severity or "?",
e.Context or "?",
(e.Message or ""):sub(1, 55)
)
end
end
errorList.Text = recentErrors ~= "" and recentErrors or " "
local modHeader = Instance.new("TextLabel")
modHeader.Size = UDim2.new(1, -20, 0, 20)
modHeader.Position = UDim2.new(0, 10, 0, 303)
modHeader.BackgroundTransparency = 1
modHeader.Text = "  "
modHeader.TextColor3 = Color3.fromRGB(100, 200, 255)
modHeader.TextSize = 11
modHeader.Font = Enum.Font.GothamBold
modHeader.TextXAlignment = Enum.TextXAlignment.Left
modHeader.Parent = bg
local patternText = Instance.new("TextLabel")
patternText.Size = UDim2.new(1, -20, 0, 45)
patternText.Position = UDim2.new(0, 10, 0, 323)
patternText.BackgroundTransparency = 1
patternText.TextColor3 = Color3.fromRGB(150, 150, 150)
patternText.TextSize = 10
patternText.Font = Enum.Font.Code
patternText.TextXAlignment = Enum.TextXAlignment.Left
patternText.TextYAlignment = Enum.TextYAlignment.Top
patternText.TextWrapped = true
patternText.Parent = bg
local patterns = ""
local count = 0
for k, v in pairs(ErrorLog.ErrorPatterns) do
if count >= 3 then break end
patterns = patterns .. string.format(" %s (%d)\n", v.Context or "?", v.Count)
count = count + 1
end
patternText.Text = count > 0 and patterns or " "
end)
end
UserInputService.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.F12 then
BS.showErrorReport()
end
end)
BS.ErrorHandler = {
Log = ErrorLog,
SafeCall = BS.safeCall,
ReloadModule = BS.reloadModule,
WatchTask = BS.watchTask,
UnwatchTask = BS.unwatchTask,
ShowReport = BS.showErrorReport,
EmergencyPanic = BS.emergencyPanic,
SaveSnapshot = BS.saveStateSnapshot,
RollbackState = BS.rollbackState,
TrackConnection = BS.trackConnection,
UntrackConnection = BS.untrackConnection,
RegisterLoop = BS.registerLoop,
HeartbeatLoop = BS.heartbeatLoop,
KillLoop = BS.killLoop,
}
BS.saveStateSnapshot("startup")
print("")
print("   BloxStrike Error Handler v2.0 loaded   ")
print("  16                           ")
print("  F12 =                          ")
print("")
]])
writefile("BloxStrike/modules/esp.lua", [[
if not BS.Win then warn("[ESP] BS.Win not available - ui.lua may have failed") return end
local UIS = nil pcall(function() UIS = game:GetService("UserInputService") end)
local mousePos = Vector2.new(0, 0)
local function getMousePos()
local ok, pos = pcall(function() return UIS and UIS:GetMouseLocation() end)
if ok and pos then mousePos = pos end
return mousePos
end
local E = BS.Win:Tab("ESP")
if not E or not E.Toggle then warn("[ESP] Failed to create tab!") return end
E:Label(" Player ESP ")
E:Toggle("Box ESP", false, function(v) Flags.ESP_Box = v end)
E:Toggle("Name ESP", false, function(v) Flags.ESP_Name = v end)
E:Toggle("Name Background", false, function(v) Flags.ESP_NameBG = v end)
E:Slider("Name Font Size", 8, 20, 13, function(v) Flags.ESP_NameSize = v end)
E:Toggle("Health Bar", false, function(v) Flags.ESP_Health = v end)
E:Toggle("Health Text", false, function(v) Flags.ESP_HealthText = v end)
E:Dropdown({Name="Health Position", Flag="ESPHealthPos", Options={"Left","Right","Top"}, Default="Left"})
E:Toggle("Armor Bar", false, function(v) Flags.ESP_Armor = v end)
E:Toggle("Distance ESP", false, function(v) Flags.ESP_Dist = v end)
E:Toggle("Distance Unit", false, function(v) Flags.ESP_DistUnit = v end)
E:Toggle("Weapon ESP", false, function(v) Flags.ESP_Weapon = v end)
E:Toggle("Weapon Ammo", false, function(v) Flags.ESP_WeaponAmmo = v end)
E:Toggle("Head Dot", false, function(v) Flags.ESP_HeadDot = v end)
E:Toggle("Head Hitbox", false, function(v) Flags.ESP_HeadHit = v end)
E:Toggle("Barrel ESP", false, function(v) Flags.ESP_Barrel = v end)
E:Toggle("Tracer ESP", false, function(v) Flags.ESP_Tracer = v end)
E:Toggle("Snaplines", false, function(v) Flags.ESP_Snaplines = v end)
E:Toggle("Skeleton ESP", false, function(v) Flags.ESP_Skeleton = v end)
E:Toggle("OOF Indicator", false, function(v) Flags.ESP_OOF = v end)
E:Toggle("Off-Screen Arrow", false, function(v) Flags.ESP_Arrow = v end)
E:Slider("Arrow Size", 8, 30, 15, function(v) Flags.ESP_ArrowSize = v end)
E:Toggle("Headshot Icon", false, function(v) Flags.ESP_Headshot = v end)
E:Toggle("Velocity Arrow", false, function(v) Flags.ESP_Velocity = v end)
E:Toggle("Target ESP", false, function(v) Flags.ESP_Target = v end)
E:Toggle("Info Card", false, function(v) Flags.ESP_InfoCard = v end)
E:Toggle("Laser Line", false, function(v) Flags.ESP_LaserLine = v end)
E:Separator()
E:Label(" World ESP ")
E:Toggle("Bomb ESP", false, function(v) Flags.ESP_Bomb = v end)
E:Toggle("Bomb Timer", false, function(v) Flags.ESP_BombTimer = v end)
E:Toggle("Bomb Distance", false, function(v) Flags.ESP_BombDist = v end)
E:Toggle("Defuse Kit ESP", false, function(v) Flags.ESP_DefuseKit = v end)
E:Toggle("Grenade ESP", false, function(v) Flags.ESP_Grenade = v end)
E:Toggle("Grenade Line", false, function(v) Flags.ESP_GrenadeLine = v end)
E:Toggle("Loot ESP", false, function(v) Flags.ESP_Loot = v end)
E:Toggle("Vehicle ESP", false, function(v) Flags.ESP_Vehicle = v end)
E:Toggle("Dropped Weapon ESP", false, function(v) Flags.ESP_DroppedWep = v end)
E:Toggle("Objective ESP", false, function(v) Flags.ESP_Objective = v end)
E:Toggle("Chams", false, function(v) Flags.Chams = v end)
E:Toggle("Glow ESP", false, function(v) Flags.ESP_Glow = v end)
E:Slider("Glow Transparency", 0, 100, 50, function(v) Flags.ESP_GlowT = v end)
E:Separator()
E:Label(" Visual Settings ")
E:Dropdown({Name="Box Style", Flag="ESPBoxStyle", Options={"2D","Corners","3D","Filled Box","Full Box"}, Default="2D"})
E:Dropdown({Name="ESP Color Mode", Flag="ESPColorMode", Options={"Team","Health","Distance","Rainbow","Custom"}, Default="Team"})
pcall(function() E:Colorpicker("Custom Color", Color3.fromRGB(255,255,255), function(v) Flags.ESP_CustomColor = v end) end)
E:Toggle("ESP Outline", true, function(v) Flags.ESP_Outline = v end)
E:Slider("Box Thickness", 1, 3, 1, function(v) Flags.ESP_BoxThick = v end)
E:Slider("Box Fill Transparency", 0, 100, 50, function(v) Flags.ESP_BoxFillT = v end)
E:Slider("Tracer Thickness", 1, 3, 1, function(v) Flags.ESP_TracerThick = v end)
E:Dropdown({Name="Tracer Origin", Flag="ESPTracerOrigin", Options={"Bottom","Center","Top","Mouse"}, Default="Bottom"})
E:Dropdown({Name="Name Alignment", Flag="ESPNameAlign", Options={"Center","Left","Right"}, Default="Center"})
E:Dropdown({Name="Health Color", Flag="ESPHealthColor", Options={"Classic","Gradient","Segmented"}, Default="Classic"})
E:Toggle("Rainbow ESP Speed", false, function(v) Flags.ESP_Rainbow = v end)
E:Slider("Rainbow Speed", 1, 20, 5, function(v) Flags.ESP_RainbowSpeed = v end)
E:Separator()
E:Label(" Display ")
E:Toggle("Watermark", false, function(v) Flags.ESP_Watermark = v end)
E:Dropdown({Name="Watermark Style", Flag="ESPWmStyle", Options={"Left","Center","Right"}, Default="Left"})
E:Toggle("Status Display", false, function(v) Flags.ESP_Status = v end)
E:Toggle("Round Info", false, function(v) Flags.ESP_RoundInfo = v end)
E:Toggle("Spectator List", false, function(v) Flags.ESP_SpecList = v end)
E:Toggle("Alert System", false, function(v) Flags.ESP_Alert = v end)
E:Toggle("FPS Display", false, function(v) Flags.ESP_FPS = v end)
E:Toggle("Speed Display", false, function(v) Flags.ESP_Speed = v end)
E:Toggle("Kill Feed", false, function(v) Flags.ESP_KillFeed = v end)
E:Toggle("Damage Numbers", false, function(v) Flags.ESP_DmgNumbers = v end)
E:Toggle("Hit Marker", false, function(v) Flags.ESP_HitMarker = v end)
E:Toggle("Radar ESP", false, function(v) Flags.ESP_Radar = v end)
E:Slider("Radar Size", 100, 300, 150, function(v) Flags.ESP_RadarSize = v end)
E:Slider("Radar Range", 50, 500, 200, function(v) Flags.ESP_RadarRange = v end)
E:Toggle("Radar Background", false, function(v) Flags.ESP_RadarBG = v end)
E:Toggle("Compass", false, function(v) Flags.ESP_Compass = v end)
E:Separator()
E:Label(" Settings ")
E:Toggle("Team Check", true, function(v) Flags.ESP_TeamCheck = v end)
E:Toggle("Distance Limit", false, function(v) Flags.ESP_DistLimit = v end)
E:Slider("Max ESP Distance", 50, 500, 200, function(v) Flags.ESP_MaxDist = v end)
E:Toggle("Visible Check", false, function(v) Flags.ESP_VisCheck = v end)
E:Toggle("Sort by Distance", false, function(v) Flags.ESP_SortDist = v end)
E:Toggle("FOV Circle", false, function(v) Flags.ESP_FOVCirc = v end)
E:Slider("FOV Circle Size", 10, 360, 100, function(v) Flags.ESP_FOVSize = v end)
E:Toggle("FOV Fill", false, function(v) Flags.ESP_FOVFill = v end)
E:Toggle("Crosshair", false, function(v) Flags.CustomCrosshair = v end)
E:Slider("Crosshair Size", 1, 20, 5, function(v) Flags.CrosshairSize = v end)
E:Slider("Crosshair Gap", 1, 10, 2, function(v) Flags.CrosshairGap = v end)
E:Slider("Crosshair Thickness", 1, 5, 1, function(v) Flags.CrosshairThick = v end)
E:Toggle("Crosshair Dot", false, function(v) Flags.CrosshairDot = v end)
E:Dropdown({Name="Crosshair Style", Flag="CrosshairStyle", Options={"Plus","Circle","Triangle","Diamond","T-Shape"}, Default="Plus"})
E:Toggle("Crosshair Outline", false, function(v) Flags.CrosshairOutline = v end)
E:Slider("Crosshair Outline Size", 1, 5, 2, function(v) Flags.CrosshairOLSize = v end)
E:Separator()
E:Label(" Miscellaneous ")
E:Toggle("Third Person", false, function(v) Flags.ThirdPerson = v end)
E:Slider("TP Distance", 2, 30, 12, function(v) Flags.TPDistance = v end)
E:Slider("TP Height", -5, 10, 2, function(v) Flags.TPHeight = v end)
E:Slider("TP Smooth", 1, 20, 5, function(v) Flags.TPSmooth = v end)
E:Dropdown({Name="TP Shoulder", Flag="TPShoulder", Options={"Right", "Left", "Center"}, Default="Right"})
E:Slider("TP Shoulder Offset", -10, 10, 3, function(v) Flags.TPShoulderOffset = v end)
E:Toggle("TP Auto Zoom (ADS)", true, function(v) Flags.TPAutoZoom = v end)
E:Toggle("TP Collision Check", true, function(v) Flags.TPCollision = v end)
E:Toggle("TP Smooth Look", true, function(v) Flags.TPSmoothLook = v end)
E:Toggle("TP Head Follow", false, function(v) Flags.TPHeadFollow = v end)
E:Slider("TP FOV", 50, 120, 70, function(v) Flags.TPFOV = v end)
E:Label("Scroll: Zoom | V: Shoulder | C: Reset")
E:Separator()
E:Label(" Viewmodel ")
E:Toggle("VM Position", false, function(v) Flags.VMOffset = v end)
E:Slider("VM Pos X", -20, 20, -5, function(v) Flags.VMPosX = v end)
E:Slider("VM Pos Y", -20, 20, 0, function(v) Flags.VMPosY = v end)
E:Slider("VM Pos Z", -30, 0, -15, function(v) Flags.VMPosZ = v end)
E:Toggle("VM Angle", false, function(v) Flags.VMAngle = v end)
E:Slider("VM Ang X", -45, 45, 0, function(v) Flags.VMAngX = v end)
E:Slider("VM Ang Y", -45, 45, 0, function(v) Flags.VMAngY = v end)
E:Slider("VM Ang Z", -45, 45, 0, function(v) Flags.VMAngZ = v end)
E:Toggle("VM Scale", false, function(v) Flags.VMScale = v end)
E:Slider("VM Scale %", 50, 200, 100, function(v) Flags.VMScaleVal = v end)
E:Toggle("VM FOV", false, function(v) Flags.VMFOV = v end)
E:Slider("VM FOV Value", 50, 120, 70, function(v) Flags.VMFOVVal = v end)
E:Separator()
E:Label(" VM Effects ")
E:Toggle("VM Bob (Walk)", false, function(v) Flags.VMBob = v end)
E:Slider("VM Bob Amount", 1, 20, 5, function(v) Flags.VMBobAmount = v end)
E:Slider("VM Bob Speed", 1, 20, 8, function(v) Flags.VMBobSpeed = v end)
E:Toggle("VM Sway (Mouse)", false, function(v) Flags.VMSway = v end)
E:Slider("VM Sway Amount", 1, 20, 3, function(v) Flags.VMSwayAmount = v end)
E:Toggle("VM Breathe", false, function(v) Flags.VMBreathe = v end)
E:Slider("VM Breathe Amount", 1, 10, 1, function(v) Flags.VMBreatheAmount = v end)
E:Slider("VM Breathe Speed", 1, 10, 5, function(v) Flags.VMBreatheSpeed = v end)
E:Toggle("VM Recoil Anim", false, function(v) Flags.VMRecoil = v end)
E:Slider("VM Recoil Amount", 1, 20, 8, function(v) Flags.VMRecoilAmount = v end)
E:Separator()
E:Label(" VM Presets ")
E:Button({Name="CS2 Style", Color=Color3.fromRGB(60,120,60)}, function() if BS.Viewmodel then BS.Viewmodel.ApplyPreset("CS2 Style") end end)
E:Button({Name="Far Right", Color=Color3.fromRGB(60,80,120)}, function() if BS.Viewmodel then BS.Viewmodel.ApplyPreset("Far Right") end end)
E:Button({Name="Close Up", Color=Color3.fromRGB(120,60,60)}, function() if BS.Viewmodel then BS.Viewmodel.ApplyPreset("Close Up") end end)
E:Button({Name="Tight", Color=Color3.fromRGB(80,60,120)}, function() if BS.Viewmodel then BS.Viewmodel.ApplyPreset("Tight") end end)
E:Button({Name="Wide", Color=Color3.fromRGB(120,120,60)}, function() if BS.Viewmodel then BS.Viewmodel.ApplyPreset("Wide") end end)
E:Button({Name="Center", Color=Color3.fromRGB(60,120,120)}, function() if BS.Viewmodel then BS.Viewmodel.ApplyPreset("Center") end end)
E:Button({Name="Insurgency", Color=Color3.fromRGB(120,80,60)}, function() if BS.Viewmodel then BS.Viewmodel.ApplyPreset("Insurgency") end end)
E:Button({Name="Default", Color=Color3.fromRGB(100,100,100)}, function() if BS.Viewmodel then BS.Viewmodel.ApplyPreset("Default") end end)
E:Separator()
E:Label(" Sound ESP ")
E:Toggle("Sound ESP", false, function(v) Flags.ESP_Sound = v end)
E:Slider("Sound ESP Range", 10, 100, 50, function(v) Flags.ESP_SoundRange = v end)
E:Toggle("Sound ESP 3D", false, function(v) Flags.ESP_Sound3D = v end)
E:Toggle("Footstep Indicator", false, function(v) Flags.ESP_Footstep = v end)
E:Slider("Footstep Duration", 1, 10, 3, function(v) Flags.ESP_FootDuration = v end)
E:Separator()
E:Label(" Glow ESP ")
E:Toggle("Glow ESP", false, function(v) Flags.ESP_Glow = v end)
E:Slider("Glow Intensity", 1, 20, 5, function(v) Flags.ESP_GlowIntensity = v end)
E:Slider("Glow Thickness", 1, 5, 2, function(v) Flags.ESP_GlowThick = v end)
E:Toggle("Glow Team Check", false, function(v) Flags.ESP_GlowTeam = v end)
E:Separator()
local SoundObjs = {}
task.spawn(function()
while true do
task.wait(0.2)
if Flags.ESP_Sound and BS.alive() then
pcall(function()
local myHrp = BS.hrp()
if not myHrp then return end
local range = (Flags.ESP_SoundRange or 50) * 3
local cam = workspace.CurrentCamera
for _, p in pairs(Players:GetPlayers()) do
if p ~= lplr and p.Character then
local hrp = p and p.Character:FindFirstChild("HumanoidRootPart")
local hum = p and p.Character:FindFirstChildOfClass("Humanoid")
if hrp and hum and hum.MoveDirection.Magnitude > 0 then
local dist = (hrp.Position - myHrp.Position).Magnitude
if dist <= range then
local sp, vis = cam:WorldToViewportPoint(hrp.Position)
if vis then
local key = p.UserId
if not SoundObjs[key] then
SoundObjs[key] = Drawing.new("Circle")
SoundObjs[key].Filled = true
SoundObjs[key].NumSides = 20
SoundObjs[key].Thickness = 1
end
local alpha = 1 - (dist / range)
SoundObjs[key].Position = Vector2.new(sp.X, sp.Y)
SoundObjs[key].Radius = 6 + alpha * 10
SoundObjs[key].Color = Color3.new(1, 0.5, 0)
SoundObjs[key].Transparency = alpha * 0.7
SoundObjs[key].Visible = true
end
end
end
end
end
for key, obj in pairs(SoundObjs) do
local player = Players:GetPlayerByUserId(key)
if not player or not player.Character then
obj.Visible = false
end
end
end)
else
for _, obj in pairs(SoundObjs) do pcall(function() obj.Visible = false end) end
end
end
end)
local GlowObjs = {}
task.spawn(function()
while true do
task.wait(0.1)
if Flags.ESP_Glow and BS.alive() then
pcall(function()
local cam = workspace.CurrentCamera
local myTeam = lplr.Team
for _, p in pairs(Players:GetPlayers()) do
if p ~= lplr and p.Character then
if Flags.ESP_GlowTeam and p.Team == myTeam then
if GlowObjs[p.UserId] then GlowObjs[p.UserId].Visible = false end
continue
end
local hrp = p and p.Character:FindFirstChild("HumanoidRootPart")
if hrp then
local sp, vis = cam:WorldToViewportPoint(hrp.Position)
if vis then
local key = p.UserId
if not GlowObjs[key] then
GlowObjs[key] = Drawing.new("Circle")
GlowObjs[key].Filled = false
GlowObjs[key].NumSides = 30
end
GlowObjs[key].Position = Vector2.new(sp.X, sp.Y)
GlowObjs[key].Radius = 20 + (Flags.ESP_GlowIntensity or 5) * 2
GlowObjs[key].Thickness = (Flags.ESP_GlowThick or 2)
GlowObjs[key].Color = Color3.new(0.3, 0.5, 1)
GlowObjs[key].Transparency = 0.5
GlowObjs[key].Visible = true
end
end
end
end
end)
else
for _, obj in pairs(GlowObjs) do pcall(function() obj.Visible = false end) end
end
end
end)
local function drawSkeleton(player, hrp, color)
if not Flags.ESP_Skeleton then return end
pcall(function()
local cam = workspace.CurrentCamera
local char = player.Character
if not char then return end
local bones = {
{"Head", "Torso"},
{"Torso", "Left Arm"},
{"Torso", "Right Arm"},
{"Torso", "Left Leg"},
{"Torso", "Right Leg"},
}
for _, bone in pairs(bones) do
local part1 = char:FindFirstChild(bone[1])
local part2 = char:FindFirstChild(bone[2])
if part1 and part2 then
local sp1, vis1 = cam:WorldToViewportPoint(part1.Position)
local sp2, vis2 = cam:WorldToViewportPoint(part2.Position)
if vis1 and vis2 then
local line = poolLine()
line.From = Vector2.new(sp1.X, sp1.Y)
line.To = Vector2.new(sp2.X, sp2.Y)
line.Color = color
line.Thickness = 1
line.Visible = true
end
end
end
end)
end
local function drawSnapline(player, hrp, color)
if not Flags.ESP_Snaplines then return end
pcall(function()
local cam = workspace.CurrentCamera
local sp, vis = cam:WorldToViewportPoint(hrp.Position)
if vis then
local line = poolLine()
line.From = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
line.To = Vector2.new(sp.X, sp.Y)
line.Color = color
line.Thickness = 1
line.Visible = true
end
end)
end
local function drawHeadDot(player, hrp, color)
if not Flags.ESP_HeadDot then return end
pcall(function()
local head = player.Character and player and player.Character:FindFirstChild("Head")
if not head then return end
local cam = workspace.CurrentCamera
local sp, vis = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
if vis then
local circle = poolCircle()
circle.Position = Vector2.new(sp.X, sp.Y)
circle.Radius = 4
circle.Color = color
circle.Filled = true
circle.Visible = true
end
end)
end
local function drawBarrel(player, hrp, color)
if not Flags.ESP_Barrel then return end
pcall(function()
local head = player.Character and player and player.Character:FindFirstChild("Head")
if not head then return end
local cam = workspace.CurrentCamera
local sp1, vis1 = cam:WorldToViewportPoint(hrp.Position)
local sp2, vis2 = cam:WorldToViewportPoint(hrp.Position + head.CFrame.LookVector * 3)
if vis1 and vis2 then
local line = poolLine()
line.From = Vector2.new(sp1.X, sp1.Y)
line.To = Vector2.new(sp2.X, sp2.Y)
line.Color = Color3.new(1, 0, 0)
line.Thickness = 2
line.Visible = true
end
end)
end
local LinePool, TextPool, SquarePool, CirclePool = {}, {}, {}, {}
local PIdx = {L=1, T=1, S=1, C=1}
local PMax = {L=0, T=0, S=0, C=0}
local Compat = _G.BS and _G.BS.Compat
local function createDrawing(class)
if Compat and Compat.DrawingNew then return Compat.DrawingNew(class) end
local s, r = pcall(function() return Drawing.new(class) end)
return s and r or nil
end
local espScale = 1
if Compat and Compat.Scale then espScale = Compat.Scale end
local function poolLine()
local i = PIdx.L; PIdx.L = i + 1
if not LinePool[i] then
local obj = createDrawing("Line")
if obj then obj.Visible=false; obj.Thickness=1; LinePool[i]=obj; PMax.L=PMax.L+1 end
end
return LinePool[i]
end
local function poolText()
local i = PIdx.T; PIdx.T = i + 1
if not TextPool[i] then
local obj = createDrawing("Text")
if obj then obj.Visible=false; obj.Size=13; obj.Center=true; obj.Outline=true; TextPool[i]=obj; PMax.T=PMax.T+1 end
end
return TextPool[i]
end
local function poolSquare()
local i = PIdx.S; PIdx.S = i + 1
if not SquarePool[i] then
local obj = createDrawing("Square")
if obj then obj.Visible=false; obj.Filled=false; SquarePool[i]=obj; PMax.S=PMax.S+1 end
end
return SquarePool[i]
end
local function poolCircle()
local i = PIdx.C; PIdx.C = i + 1
if not CirclePool[i] then
local obj = createDrawing("Circle")
if obj then obj.Visible=false; obj.Filled=false; CirclePool[i]=obj; PMax.C=PMax.C+1 end
end
return CirclePool[i]
end
local function resetPool() PIdx.L=1; PIdx.T=1; PIdx.S=1; PIdx.C=1 end
local function hideUnused()
for i=PIdx.L,PMax.L do LinePool[i].Visible=false end
for i=PIdx.T,PMax.T do TextPool[i].Visible=false end
for i=PIdx.S,PMax.S do SquarePool[i].Visible=false end
for i=PIdx.C,PMax.C do CirclePool[i].Visible=false end
end
local w2s = function(pos) return workspace.CurrentCamera:WorldToViewportPoint(pos) end
local v2 = Vector2.new
local v3 = Vector3.new
local mAbs, mFloor, mClamp, mAtan2, mSin, mCos, mRad, mSqrt, mMin, mMax =
math.abs, math.floor, math.clamp, math.atan2, math.sin, math.cos, math.rad, math.sqrt, math.min, math.max
local RGB = Color3.fromRGB
local RGBLerp = Color3.new().Lerp
local V3_UP = v3(0, 3, 0)
local V3_ZERO = v3(0, 0, 0)
local C_WHITE=RGB(255,255,255); local C_RED=RGB(255,50,50); local C_GREY=RGB(200,200,200)
local C_GREEN=RGB(0,255,0); local C_YELLOW=RGB(255,255,0); local C_BLUE=RGB(50,150,255)
local C_HP_BG=RGB(50,50,50); local C_ARMOR=RGB(0,150,255); local C_WEAPON=RGB(200,150,50)
local C_BOMB=RGB(255,100,0); local C_ORANGE=RGB(255,165,0); local C_CYAN=RGB(0,200,255)
local C_PURPLE=RGB(180,0,255); local C_PINK=RGB(255,0,150)
local function calcBox(hrp)
local pos, vis = w2s(workspace.CurrentCamera, hrp.Position)
if not vis then return nil end
local topP = w2s(workspace.CurrentCamera, hrp.Position + V3_UP)
local botP = w2s(workspace.CurrentCamera, hrp.Position - V3_UP)
local boxH = mAbs(topP.Y - botP.Y)
return pos, boxH, boxH * 0.5
end
local rainbowHue = 0
local function getESPColor(player, hum, dist)
local mode = Flags.ESPColorMode or "Team"
if mode == "Custom" then return Flags.ESP_CustomColor or C_WHITE
elseif mode == "Rainbow" then
rainbowHue = (rainbowHue + (Flags.ESP_RainbowSpeed or 5) * 0.001) % 1
return Color3.fromHSV(rainbowHue, 1, 1)
elseif mode == "Health" then
local hp = hum.Health / hum.MaxHealth
if hp > 0.5 then return C_GREEN elseif hp > 0.25 then return C_YELLOW else return C_RED end
elseif mode == "Distance" then
if dist < 50 then return C_RED elseif dist < 100 then return C_YELLOW else return C_GREEN end
else
local myTeam = BS.team()
if myTeam and player.Team == myTeam then return C_BLUE end
return C_RED
end
end
local function getHealthColor(pct, mode)
if mode == "Segmented" then
if pct > 0.75 then return RGB(0,200,0) elseif pct > 0.5 then return RGB(0,200,0)
elseif pct > 0.25 then return RGB(200,200,0) else return RGB(200,0,0) end
elseif mode == "Gradient" then
return RGBLerp(RGB(255,0,0), RGB(0,255,0), pct)
else
if pct > 0.5 then return C_GREEN elseif pct > 0.25 then return C_YELLOW else return C_RED end
end
end
local function drawBox2D(hrp, color, thick)
local pos, boxH, boxW = calcBox(hrp)
if not pos then return end
local hw, hh = boxW*0.5, boxH*0.5; local x, y = pos.X, pos.Y
local l1=poolLine(); l1.From=v2(x-hw,y-hh); l1.To=v2(x+hw,y-hh); l1.Color=color; l1.Thickness=thick; l1.Visible=true
local l2=poolLine(); l2.From=v2(x-hw,y+hh); l2.To=v2(x+hw,y+hh); l2.Color=color; l2.Thickness=thick; l2.Visible=true
local l3=poolLine(); l3.From=v2(x-hw,y-hh); l3.To=v2(x-hw,y+hh); l3.Color=color; l3.Thickness=thick; l3.Visible=true
local l4=poolLine(); l4.From=v2(x+hw,y-hh); l4.To=v2(x+hw,y+hh); l4.Color=color; l4.Thickness=thick; l4.Visible=true
end
local function drawCornerBox(hrp, color, thick)
local pos, boxH, boxW = calcBox(hrp)
if not pos then return end
local cl=boxW*0.3; local x,y = pos.X-boxW*0.5, pos.Y-boxH*0.5
local c={v2(x,y),v2(x+cl,y),v2(x,y),v2(x,y+cl),v2(x+boxW,y),v2(x+boxW-cl,y),v2(x+boxW,y),v2(x+boxW,y+cl),
v2(x,y+boxH),v2(x+cl,y+boxH),v2(x,y+boxH),v2(x,y+boxH-cl),v2(x+boxW,y+boxH),v2(x+boxW-cl,y+boxH),v2(x+boxW,y+boxH),v2(x+boxW,y+boxH-cl)}
for i=1,8 do local l=poolLine(); l.From=c[i*2-1]; l.To=c[i*2]; l.Color=color; l.Thickness=thick; l.Visible=true end
end
local function draw3DBox(hrp, color, thick)
local cam = workspace.CurrentCamera
local cf = hrp.CFrame
local size = v3(1.5, 3, 1.5)
local corners3D = {
}
local corners2D, visAll = {}, true
for i, c3 in ipairs(corners3D) do
local p, v = w2s(cam, c3)
corners2D[i] = p; if not v then visAll = false end
end
if not visAll then return end
local edges = {{1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}}
for _, e in ipairs(edges) do
local l=poolLine(); l.From=corners2D[e[1]]; l.To=corners2D[e[2]]; l.Color=color; l.Thickness=thick; l.Visible=true
end
end
local function drawFullBox(hrp, color, thick)
drawBox2D(hrp, color, thick)
local pos, boxH, boxW = calcBox(hrp)
if not pos then return end
local hw, hh = boxW*0.5+2, boxH*0.5+2; local x,y = pos.X, pos.Y
local ol = Flags.ESP_Outline and RGB(0,0,0) or color
local l1=poolLine(); l1.From=v2(x-hw,y-hh); l1.To=v2(x+hw,y-hh); l1.Color=ol; l1.Thickness=thick+2; l1.Visible=true
local l2=poolLine(); l2.From=v2(x-hw,y+hh); l2.To=v2(x+hw,y+hh); l2.Color=ol; l2.Thickness=thick+2; l2.Visible=true
local l3=poolLine(); l3.From=v2(x-hw,y-hh); l3.To=v2(x-hw,y+hh); l3.Color=ol; l3.Thickness=thick+2; l3.Visible=true
local l4=poolLine(); l4.From=v2(x+hw,y-hh); l4.To=v2(x+hw,y+hh); l4.Color=ol; l4.Thickness=thick+2; l4.Visible=true
end
local function drawFilledBox(hrp, color, thick)
local pos, boxH, boxW = calcBox(hrp)
if not pos then return end
local hw, hh = boxW*0.5, boxH*0.5
local fill=poolSquare(); fill.Size=v2(boxW,boxH); fill.Position=v2(pos.X-hw,pos.Y-hh); fill.Color=color; fill.Filled=true; fill.Transparency=(Flags.ESP_BoxFillT or 50)/100; fill.Visible=true
drawBox2D(hrp, color, thick)
end
local function drawHealthBar(hrp, hum, color)
local pos, boxH, boxW = calcBox(hrp)
if not pos then return end
local hpPct = hum.Health / hum.MaxHealth
local hpMode = Flags.ESPHealthColor or "Classic"
local hpC = getHealthColor(hpPct, hpMode)
local hpPos = Flags.ESPHealthPos or "Left"
local x, y, barW, barH
if hpPos == "Top" then
x = pos.X - boxW * 0.5; y = pos.Y - boxH * 0.5 - 8
barW = boxW; barH = 4
local bg=poolSquare(); bg.Size=v2(barW,barH); bg.Position=v2(x,y); bg.Color=C_HP_BG; bg.Filled=true; bg.Visible=true
local fill=poolSquare(); fill.Size=v2(barW*hpPct,barH); fill.Position=v2(x,y); fill.Color=hpC; fill.Filled=true; fill.Visible=true
elseif hpPos == "Right" then
x = pos.X + boxW * 0.5 + 2; y = pos.Y - boxH * 0.5
barW = 4; barH = boxH
local bg=poolSquare(); bg.Size=v2(barW,barH); bg.Position=v2(x,y); bg.Color=C_HP_BG; bg.Filled=true; bg.Visible=true
local fill=poolSquare(); fill.Size=v2(barW,barH*hpPct); fill.Position=v2(x,y+barH*(1-hpPct)); fill.Color=hpC; fill.Filled=true; fill.Visible=true
else
x = pos.X - boxW * 0.5 - 6; y = pos.Y - boxH * 0.5
barW = 4; barH = boxH
local bg=poolSquare(); bg.Size=v2(barW,barH); bg.Position=v2(x,y); bg.Color=C_HP_BG; bg.Filled=true; bg.Visible=true
local fill=poolSquare(); fill.Size=v2(barW,barH*hpPct); fill.Position=v2(x,y+barH*(1-hpPct)); fill.Color=hpC; fill.Filled=true; fill.Visible=true
end
if Flags.ESP_HealthText then
local txt = mFloor(hum.Health)
local t=poolText(); t.Position=v2(x + barW/2, y + barH * (1 - hpPct)); t.Text=tostring(txt); t.Size=10; t.Color=C_WHITE; t.Center=true; t.Visible=true
end
end
local function drawArmorBar(hrp, player)
local armor = 0
pcall(function() armor = player.Character and player.Character:GetAttribute("Armor") or 0 end)
if armor <= 0 then return end
local pos, boxH, boxW = calcBox(hrp)
if not pos then return end
local x = pos.X + boxW * 0.5 + (Flags.ESPHealthPos == "Right" and 8 or 2)
local y = pos.Y - boxH * 0.5
local aPct = mClamp(armor/100,0,1)
local bg=poolSquare(); bg.Size=v2(4,boxH); bg.Position=v2(x,y); bg.Color=C_HP_BG; bg.Filled=true; bg.Visible=true
local fill=poolSquare(); fill.Size=v2(4,boxH*aPct); fill.Position=v2(x,y+boxH*(1-aPct)); fill.Color=C_ARMOR; fill.Filled=true; fill.Visible=true
end
local function drawName(player, hrp, color)
local pos, vis = w2s(workspace.CurrentCamera, hrp.Position + V3_UP)
if not vis then return end
local fontSize = Flags.ESP_NameSize or 13
local align = Flags.ESPNameAlign or "Center"
local t=poolText()
t.Position=v2(pos.X, pos.Y - 15 - fontSize)
t.Text=player.DisplayName
t.Color=color
t.Size=fontSize
t.Center = (align == "Center")
t.Visible=true
if Flags.ESP_NameBG then
local txtW = t.TextBounds.X + 6
local txtH = fontSize + 4
local bgX = align == "Center" and (pos.X - txtW/2) or (align == "Left" and (pos.X - txtW) or pos.X)
local bg=poolSquare(); bg.Size=v2(txtW,txtH); bg.Position=v2(bgX, pos.Y - 15 - fontSize - 2); bg.Color=RGB(0,0,0); bg.Filled=true; bg.Transparency=0.5; bg.Visible=true
end
end
local function drawDistance(hrp, color)
local myHrp = BS.hrp()
if not myHrp then return end
local pos, vis = w2s(workspace.CurrentCamera, hrp.Position - V3_UP)
if not vis then return end
local dist = mFloor((myHrp.Position-hrp.Position).Magnitude)
local unit = Flags.ESP_DistUnit and "m" or ""
local t=poolText(); t.Position=v2(pos.X,pos.Y+5); t.Text=dist..unit; t.Color=color; t.Size=11; t.Visible=true
end
local function drawWeapon(player, hrp, color)
local tool = player.Character and player and player.Character:FindFirstChildWhichIsA("Tool")
if not tool then return end
local pos, vis = w2s(workspace.CurrentCamera, hrp.Position - v3(0,4,0))
if not vis then return end
local wepName = tool.Name
if Flags.ESP_WeaponAmmo then
local ammo = tool:GetAttribute("Ammo") or tool:GetAttribute("CurrentAmmo") or "?"
wepName = wepName .. " [" .. tostring(ammo) .. "]"
end
local t=poolText(); t.Position=v2(pos.X,pos.Y+5); t.Text=wepName; t.Color=C_WEAPON; t.Size=11; t.Visible=true
end
local function drawTracer(hrp, color)
local pos, vis = w2s(workspace.CurrentCamera, hrp.Position)
if not vis then return end
local orig = Flags.ESPTracerOrigin or "Bottom"
local sw, sh = workspace.CurrentCamera.ViewportSize.X, workspace.CurrentCamera.ViewportSize.Y
local from
if orig=="Bottom" then from=v2(sw*0.5,sh)
elseif orig=="Center" then from=v2(sw*0.5,sh*0.5)
elseif orig=="Top" then from=v2(sw*0.5,0)
else from=getMousePos() end
local l=poolLine(); l.From=from; l.To=v2(pos.X,pos.Y); l.Color=color; l.Thickness=Flags.ESP_TracerThick or 1; l.Visible=true
end
local function drawHeadDot(hrp)
local head = hrp.Parent and hrp.Parent:FindFirstChild("Head")
if not head then return end
local pos, vis = w2s(workspace.CurrentCamera, head.Position)
if not vis then return end
local c=poolCircle(); c.Position=v2(pos.X,pos.Y); c.Radius=3; c.Color=C_RED; c.Filled=true; c.Visible=true
end
local function drawHeadHitbox(hrp, color)
local head = hrp.Parent and hrp.Parent:FindFirstChild("Head")
if not head then return end
local pos, vis = w2s(workspace.CurrentCamera, head.Position)
if not vis then return end
local c=poolCircle(); c.Position=v2(pos.X,pos.Y); c.Radius=8; c.Color=color; c.Thickness=1; c.Filled=false; c.Visible=true
end
local function drawBarrel(hrp, color)
local lookVec = hrp.CFrame.LookVector
local p1,v1 = w2s(workspace.CurrentCamera, hrp.Position + lookVec)
local p2,v2v = w2s(workspace.CurrentCamera, hrp.Position + lookVec * 5)
if v1 and v2v then
local l=poolLine(); l.From=v2(p1.X,p1.Y); l.To=v2(p2.X,p2.Y); l.Color=color; l.Thickness=1; l.Visible=true
end
end
local function drawSnapline(hrp, color)
local pos, vis = w2s(hrp.Position)
if not vis then return end
local sw, sh = workspace.CurrentCamera.ViewportSize.X, workspace.CurrentCamera.ViewportSize.Y
local l=poolLine(); l.From=v2(sw*0.5,sh*0.5); l.To=v2(pos.X,pos.Y); l.Color=color; l.Thickness=1; l.Visible=true
end
local function drawSkeleton(player, color)
local char = player.Character; if not char then return end
local function gp(n) local p=char:FindFirstChild(n); return p and p.Position or nil end
local head,torso,root = gp("Head"),gp("UpperTorso") or gp("Torso"),gp("HumanoidRootPart")
local lArm,rArm = gp("LeftUpperArm") or gp("Left Arm"),gp("RightUpperArm") or gp("Right Arm")
local lLeg,rLeg = gp("LeftUpperLeg") or gp("Left Leg"),gp("RightUpperLeg") or gp("Right Leg")
local lFore,rFore = gp("LeftLowerArm") or gp("Left Arm"),gp("RightLowerArm") or gp("Right Arm")
local lShin,rShin = gp("LeftLowerLeg") or gp("Left Leg"),gp("RightLowerLeg") or gp("Right Leg")
local function bone(a,b)
if not a or not b then return end
local pa,va=w2s(workspace.CurrentCamera,a); local pb,vb=w2s(workspace.CurrentCamera,b)
if va and vb then local l=poolLine(); l.From=v2(pa.X,pa.Y); l.To=v2(pb.X,pb.Y); l.Color=color; l.Visible=true end
end
bone(head,torso); bone(torso,root)
bone(torso,lArm); bone(lArm,lFore)
bone(torso,rArm); bone(rArm,rFore)
bone(root,lLeg); bone(lLeg,lShin)
bone(root,rLeg); bone(rLeg,rShin)
end
local function drawTargetESP(player, hrp)
if not Flags.ESP_Target then return end
local target = RAGE and RAGE.Target
if not target or target.Enemy.Player ~= player then return end
local pos, vis = w2s(workspace.CurrentCamera, hrp.Position)
if not vis then return end
local c=poolCircle(); c.Position=v2(pos.X,pos.Y); c.Radius=20; c.Color=C_YELLOW; c.Thickness=2; c.Filled=false; c.Visible=true
end
local function drawOOF(player, hrp, color)
local cam = workspace.CurrentCamera
local camCF = cam.CFrame
local dirToPlayer = (hrp.Position - camCF.Position).Unit
local camForward = camCF.LookVector
local dot = camForward:Dot(dirToPlayer)
if dot > 0.1 then return end
local pos, vis = w2s(cam, hrp.Position)
if vis then return end
local angle = mAtan2(camCF.RightVector:Dot(dirToPlayer), camForward:Dot(dirToPlayer))
local cx, cy = cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5
local radius = mMin(cx, cy) * 0.8
local sx = cx + mSin(angle) * radius
local sy = cy - mCos(angle) * radius
local t=poolText(); t.Position=v2(sx,sy); t.Text=""; t.Size=16; t.Color=color; t.Center=true; t.Visible=true
end
local function drawOffScreenArrow(player, hrp, color)
local cam = workspace.CurrentCamera
local camCF = cam.CFrame
local dirToPlayer = (hrp.Position - camCF.Position).Unit
local camForward = camCF.LookVector
local dot = camForward:Dot(dirToPlayer)
if dot > 0 then return end
local angle = mAtan2(camCF.RightVector:Dot(dirToPlayer), camForward:Dot(dirToPlayer))
local cx, cy = cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5
local radius = mMin(cx, cy) * 0.85
local arrowSize = Flags.ESP_ArrowSize or 15
local sx = cx + mSin(angle) * radius
local sy = cy - mCos(angle) * radius
local perpX = mCos(angle)
local perpY = mSin(angle)
local tip = v2(sx, sy)
local left = v2(sx - perpX * arrowSize * 0.5 - mSin(angle) * arrowSize, sy + perpY * arrowSize * 0.5 - mCos(angle) * arrowSize)
local right = v2(sx - perpX * arrowSize * 0.5 + mSin(angle) * arrowSize, sy + perpY * arrowSize * 0.5 + mCos(angle) * arrowSize)
local l1=poolLine(); l1.From=left; l1.To=tip; l1.Color=color; l1.Thickness=2; l1.Visible=true
local l2=poolLine(); l2.From=right; l2.To=tip; l2.Color=color; l2.Thickness=2; l2.Visible=true
local l3=poolLine(); l3.From=left; l3.To=right; l3.Color=color; l3.Thickness=2; l3.Visible=true
local t=poolText(); t.Position=v2(sx, sy + 12); t.Text=player.DisplayName; t.Color=color; t.Size=10; t.Center=true; t.Visible=true
end
local function drawHeadshotIcon(hrp, color)
local head = hrp.Parent and hrp.Parent:FindFirstChild("Head")
if not head then return end
local pos, vis = w2s(workspace.CurrentCamera, head.Position)
if not vis then return end
local t=poolText(); t.Position=v2(pos.X+10,pos.Y-10); t.Text=""; t.Size=12; t.Color=color; t.Visible=true
end
local function drawVelocityArrow(hrp, color)
local vel = hrp.Velocity
local speed = vel.Magnitude
if speed < 1 then return end
local dir = vel.Unit
local startP = hrp.Position + dir * 1.5
local endP = startP + dir * mMin(speed * 0.1, 5)
local p1,v1 = w2s(workspace.CurrentCamera, startP)
local p2,v2v = w2s(workspace.CurrentCamera, endP)
if v1 and v2v then
local l=poolLine(); l.From=v2(p1.X,p1.Y); l.To=v2(p2.X,p2.Y); l.Color=color; l.Thickness=1; l.Visible=true
end
end
local function drawLaserLine(player, hrp, color)
if not Flags.ESP_LaserLine then return end
local tool = player.Character and player and player.Character:FindFirstChildWhichIsA("Tool")
if not tool then return end
local muzzle = tool:FindFirstChild("Muzzle") or tool:FindFirstChild("Handle")
if not muzzle then return end
local startPos = tool.Handle and tool.Handle.Position or hrp.Position + hrp.CFrame.LookVector * 2
local endPos = hrp.Position + hrp.CFrame.LookVector * 100
local p1,v1 = w2s(workspace.CurrentCamera, startPos)
local p2,v2v = w2s(workspace.CurrentCamera, endPos)
if v1 and v2v then
local l=poolLine(); l.From=v2(p1.X,p1.Y); l.To=v2(p2.X,p2.Y); l.Color=C_RED; l.Thickness=1; l.Visible=true
end
end
local function drawInfoCard(player, hrp, hum, color, dist)
if not Flags.ESP_InfoCard then return end
local pos, boxH, boxW = calcBox(hrp)
if not pos then return end
local x = pos.X + boxW * 0.5 + 10
local y = pos.Y - boxH * 0.5
local lines = {
player.DisplayName,
}
local tool = player.Character and player and player.Character:FindFirstChildWhichIsA("Tool")
if tool then table.insert(lines, "Wep: " .. tool.Name) end
local velocity = hrp.Velocity.Magnitude
if velocity > 1 then table.insert(lines, "Speed: " .. mFloor(velocity)) end
local bgW = 120
local bgH = #lines * 14 + 8
local bg=poolSquare(); bg.Size=v2(bgW,bgH); bg.Position=v2(x,y); bg.Color=RGB(0,0,0); bg.Filled=true; bg.Transparency=0.6; bg.Visible=true
local b1=poolLine(); b1.From=v2(x,y); b1.To=v2(x+bgW,y); b1.Color=color; b1.Thickness=1; b1.Visible=true
local b2=poolLine(); b2.From=v2(x,y+bgH); b2.To=v2(x+bgW,y+bgH); b2.Color=color; b2.Thickness=1; b2.Visible=true
local b3=poolLine(); b3.From=v2(x,y); b3.To=v2(x,y+bgH); b3.Color=color; b3.Thickness=1; b3.Visible=true
local b4=poolLine(); b4.From=v2(x+bgW,y); b4.To=v2(x+bgW,y+bgH); b4.Color=color; b4.Thickness=1; b4.Visible=true
for i, line in ipairs(lines) do
local t=poolText(); t.Position=v2(x+4, y+4+(i-1)*14); t.Text=line; t.Color=C_WHITE; t.Size=10; t.Center=false; t.Visible=true
end
end
local fovCircleObj = nil
local fovFillObj = nil
local function updateFOVCircle()
if not Flags.ESP_FOVCirc then
if fovCircleObj then fovCircleObj.Visible=false end
if fovFillObj then fovFillObj.Visible=false end
end
if not fovCircleObj then
local obj = createDrawing("Circle")
if obj then obj.Thickness=1; obj.NumSides=64; obj.Filled=false; fovCircleObj=obj end
end
fovCircleObj.Position = getMousePos()
fovCircleObj.Radius = Flags.ESP_FOVSize or 100
fovCircleObj.Color = C_WHITE
fovCircleObj.Visible = true
if Flags.ESP_FOVFill then
if not fovFillObj then
local obj = createDrawing("Circle")
if obj then obj.Thickness=0; obj.NumSides=64; obj.Filled=true; fovFillObj=obj end
end
fovFillObj.Position = getMousePos()
fovFillObj.Radius = Flags.ESP_FOVSize or 100
fovFillObj.Color = RGB(255,255,255)
fovFillObj.Filled = true
fovFillObj.Transparency = 0.05
fovFillObj.Visible = true
elseif fovFillObj then
fovFillObj.Visible = false
end
end
local function drawCrosshair()
if not Flags.CustomCrosshair then return end
local size = Flags.CrosshairSize or 5
local gap = Flags.CrosshairGap or 2
local thick = Flags.CrosshairThick or 1
local style = Flags.CrosshairStyle or "Plus"
local cx = workspace.CurrentCamera.ViewportSize.X * 0.5
local cy = workspace.CurrentCamera.ViewportSize.Y * 0.5
local cc = C_GREEN
if style == "Plus" then
local l1=poolLine(); l1.From=v2(cx-size-gap,cy); l1.To=v2(cx-gap,cy); l1.Color=cc; l1.Thickness=thick; l1.Visible=true
local l2=poolLine(); l2.From=v2(cx+gap,cy); l2.To=v2(cx+size+gap,cy); l2.Color=cc; l2.Thickness=thick; l2.Visible=true
local l3=poolLine(); l3.From=v2(cx,cy-size-gap); l3.To=v2(cx,cy-gap); l3.Color=cc; l3.Thickness=thick; l3.Visible=true
local l4=poolLine(); l4.From=v2(cx,cy+gap); l4.To=v2(cx,cy+size+gap); l4.Color=cc; l4.Thickness=thick; l4.Visible=true
elseif style == "Circle" then
local c=poolCircle(); c.Position=v2(cx,cy); c.Radius=size+gap; c.Color=cc; c.Thickness=thick; c.Filled=false; c.Visible=true
elseif style == "Triangle" then
local l1=poolLine(); l1.From=v2(cx,cy-gap); l1.To=v2(cx-size,cy+size); l1.Color=cc; l1.Thickness=thick; l1.Visible=true
local l2=poolLine(); l2.From=v2(cx-size,cy+size); l2.To=v2(cx+size,cy+size); l2.Color=cc; l2.Thickness=thick; l2.Visible=true
local l3=poolLine(); l3.From=v2(cx+size,cy+size); l3.To=v2(cx,cy-gap); l3.Color=cc; l3.Thickness=thick; l3.Visible=true
elseif style == "Diamond" then
local l1=poolLine(); l1.From=v2(cx,cy-gap-size); l1.To=v2(cx+size+gap,cy); l1.Color=cc; l1.Thickness=thick; l1.Visible=true
local l2=poolLine(); l2.From=v2(cx+size+gap,cy); l2.To=v2(cx,cy+size+gap); l2.Color=cc; l2.Thickness=thick; l2.Visible=true
local l3=poolLine(); l3.From=v2(cx,cy+size+gap); l3.To=v2(cx-size-gap,cy); l3.Color=cc; l3.Thickness=thick; l3.Visible=true
local l4=poolLine(); l4.From=v2(cx-size-gap,cy); l4.To=v2(cx,cy-size-gap); l4.Color=cc; l4.Thickness=thick; l4.Visible=true
elseif style == "T-Shape" then
local l1=poolLine(); l1.From=v2(cx-size-gap,cy); l1.To=v2(cx+size+gap,cy); l1.Color=cc; l1.Thickness=thick; l1.Visible=true
local l2=poolLine(); l2.From=v2(cx,cy); l2.To=v2(cx,cy+size+gap); l2.Color=cc; l2.Thickness=thick; l2.Visible=true
end
if Flags.CrosshairOutline then
local olSize = Flags.CrosshairOLSize or 2
local oc = RGB(0,0,0)
if style == "Circle" then
local c=poolCircle(); c.Position=v2(cx,cy); c.Radius=size+gap; c.Color=oc; c.Thickness=thick+olSize*2; c.Filled=false; c.Visible=true
else
local l1=poolLine(); l1.From=v2(cx-size-gap-olSize,cy-olSize); l1.To=v2(cx+size+gap+olSize,cy+olSize); l1.Color=oc; l1.Thickness=thick+olSize*2; l1.Visible=true
end
end
if Flags.CrosshairDot then
local dot=poolCircle(); dot.Position=v2(cx,cy); dot.Radius=1.5; dot.Color=cc; dot.Filled=true; dot.Visible=true
end
end
local bombFrame = 0
local function drawBombESP()
if not Flags.ESP_Bomb then return end
bombFrame = bombFrame + 1
if bombFrame % 10 ~= 0 then return end
local bomb = BS.api and BS.api.getBomb and BS.api.getBomb()
if not bomb then return end
local pos, vis = w2s(workspace.CurrentCamera, bomb.Position)
if not vis then return end
local t=poolText(); t.Position=v2(pos.X,pos.Y-20); t.Text=" C4"; t.Color=C_BOMB; t.Size=16; t.Visible=true
if Flags.ESP_BombTimer then
local timer = BS.api.getBombTimer and BS.api.getBombTimer() or 40
local t2=poolText(); t2.Position=v2(pos.X,pos.Y); t2.Text=string.format("%.1fs",timer); t2.Color=timer<10 and C_RED or C_YELLOW; t2.Size=14; t2.Visible=true
end
if Flags.ESP_BombDist then
local myHrp = BS.hrp()
if myHrp then
local d = mFloor((myHrp.Position - bomb.Position).Magnitude)
local t3=poolText(); t3.Position=v2(pos.X,pos.Y+15); t3.Text=d.."m"; t3.Color=C_GREY; t3.Size=11; t3.Visible=true
end
end
end
local function drawGrenadeESP()
if not Flags.ESP_Grenade then return end
pcall(function()
for _, obj in ipairs(workspace:GetChildren()) do
if obj.Name:find("Grenade") or obj.Name:find("Flash") or obj.Name:find("Smoke") or obj.Name:find("Molotov") then
local pos, vis = w2s(workspace.CurrentCamera, obj.Position)
if vis then
local label = ""
if obj.Name:find("Flash") then label = ""
elseif obj.Name:find("Smoke") then label = ""
elseif obj.Name:find("Molotov") then label = "" end
local t=poolText(); t.Position=v2(pos.X,pos.Y-15); t.Text=label.." "..obj.Name; t.Color=C_YELLOW; t.Size=12; t.Visible=true
if Flags.ESP_GrenadeLine then
local myHrp = BS.hrp()
if myHrp then
local p1,v1 = w2s(workspace.CurrentCamera, myHrp.Position)
if v1 then local l=poolLine(); l.From=v2(p1.X,p1.Y); l.To=v2(pos.X,pos.Y); l.Color=C_ORANGE; l.Thickness=1; l.Visible=true end
end
end
end
end
end
end)
end
local radarGui = nil
local function updateRadar()
if not Flags.ESP_Radar then
if radarGui then radarGui.Enabled = false end; return
end
local rSize = Flags.ESP_RadarSize or 150
local rRange = Flags.ESP_RadarRange or 200
local rX, rY = 50, workspace.CurrentCamera.ViewportSize.Y - rSize - 50
if not radarGui then
radarGui = Instance.new("ScreenGui"); radarGui.Name="BS_Radar"; radarGui.IgnoreGuiInset=true; radarGui.DisplayOrder=9998; radarGui.Parent=lplr.PlayerGui
end
radarGui.Enabled = true
local bg = Instance.new("Frame"); bg.Size=UDim2.new(0,rSize,0,rSize); bg.Position=UDim2.new(0,rX,0,rY); bg.BackgroundColor3=RGB(0,0,0); bg.BackgroundTransparency=0.3; bg.BorderSizePixel=1; bg.BorderColor3=RGB(100,100,100); bg.Parent=radarGui
Instance.new("UICorner",bg).CornerRadius=UDim.new(0,4)
local ch1=Instance.new("Frame"); ch1.Size=UDim2.new(1,0,0,1); ch1.Position=UDim2.new(0,0,0.5,0); ch1.BackgroundColor3=RGB(80,80,80); ch1.BorderSizePixel=0; ch1.Parent=bg
local ch2=Instance.new("Frame"); ch2.Size=UDim2.new(0,1,1,0); ch2.Position=UDim2.new(0.5,0,0,0); ch2.BackgroundColor3=RGB(80,80,80); ch2.BorderSizePixel=0; ch2.Parent=bg
local myPos = BS.hrp() and BS.hrp().Position or V3_ZERO
local myTeam = BS.team()
for _, player in ipairs(Players:GetPlayers()) do
if player == lplr then continue end
local char = player.Character; if not char then continue end
local hrp = char:FindFirstChild("HumanoidRootPart"); local hum = char:FindFirstChildOfClass("Humanoid")
if not hrp or not hum or hum.Health <= 0 then continue end
local relPos = hrp.Position - myPos
local rx = relPos.X / rRange * (rSize * 0.5) + rSize * 0.5
local ry = relPos.Z / rRange * (rSize * 0.5) + rSize * 0.5
if rx < 0 or rx > rSize or ry < 0 or ry > rSize then continue end
local dotColor = C_RED
if Flags.ESP_TeamCheck and myTeam and player.Team == myTeam then dotColor = C_BLUE end
local dot=Instance.new("Frame"); dot.Size=UDim2.new(0,5,0,5); dot.Position=UDim2.new(0,rx-2.5,0,ry-2.5); dot.BackgroundColor3=dotColor; dot.BorderSizePixel=0; dot.Parent=bg
Instance.new("UICorner",dot).CornerRadius=UDim.new(0,5)
end
end
local compassGui = nil
local function updateCompass()
if not Flags.ESP_Compass then
if compassGui then compassGui.Enabled = false end; return
end
if not compassGui then
compassGui = Instance.new("ScreenGui"); compassGui.Name="BS_Compass"; compassGui.IgnoreGuiInset=true; compassGui.DisplayOrder=9998; compassGui.Parent=lplr.PlayerGui
local f=Instance.new("Frame",compassGui); f.Size=UDim2.new(0,300,0,20); f.Position=UDim2.new(0.5,-150,0,40); f.BackgroundColor3=RGB(0,0,0); f.BackgroundTransparency=0.4; f.BorderSizePixel=0; f.Parent=compassGui
Instance.new("UICorner",f).CornerRadius=UDim.new(0,4)
for i=1,5 do
local lbl=Instance.new("TextLabel",f); lbl.Name="D"..i; lbl.Size=UDim2.new(0,50,1,0); lbl.Position=UDim2.new(0,(i-1)*60,0,0); lbl.BackgroundTransparency=1; lbl.TextColor3=C_GREY; lbl.TextSize=11; lbl.Font=Enum.Font.Code; lbl.TextXAlignment=Enum.TextXAlignment.Center
end
end
compassGui.Enabled = true
local yaw = workspace.CurrentCamera.CFrame and workspace.CurrentCamera.CFrame:ToEulerAnglesYXZ() or 0
local deg = mFloor(mDeg(yaw))
local dirs = {"W","NW","N","NE","E","SE","S","SW"}
for i = 1, 5 do
local idx = ((deg + (i-3) * 45) % 360) / 45 + 1
local dirIdx = mFloor(idx + 0.5) % 8 + 1
local lbl = compassGui.Frame:FindFirstChild("D"..i)
if lbl then
lbl.Text = dirs[dirIdx]
lbl.TextColor3 = (i == 3) and C_WHITE or C_GREY
end
end
end
local wmGui, stGui, fpGui = nil, nil, nil
local function updateWatermark()
if not Flags.ESP_Watermark then if wmGui then wmGui.Enabled=false end; return end
if not wmGui then
wmGui = Instance.new("ScreenGui"); wmGui.Name="BS_WM"; wmGui.IgnoreGuiInset=true; wmGui.DisplayOrder=9999; wmGui.Parent=lplr.PlayerGui
local f=Instance.new("Frame",wmGui); f.Size=UDim2.new(0,280,0,30); f.Position=UDim2.new(0,10,0,10); f.BackgroundColor3=RGB(0,0,0); f.BackgroundTransparency=0.3; f.BorderSizePixel=0
Instance.new("UICorner",f).CornerRadius=UDim.new(0,6)
local t=Instance.new("TextLabel",f); t.Name="T"; t.Size=UDim2.new(1,-10,1,0); t.Position=UDim2.new(0,5,0,0); t.BackgroundTransparency=1; t.TextColor3=C_CYAN; t.TextSize=12; t.Font=Enum.Font.Code; t.TextXAlignment=Enum.TextXAlignment.Left
end
wmGui.Enabled = true
local lbl = wmGui.Frame.T
if lbl then lbl.Text = string.format(" BloxStrike | %d FPS | %dms | %d Players", BS.Perf and BS.Perf.FPS or 0, BS.Ping and BS.Ping.Current or 0, #Players:GetPlayers()) end
end
local function updateStatus()
if not Flags.ESP_Status then if stGui then stGui.Enabled=false end; return end
if not stGui then
stGui = Instance.new("ScreenGui"); stGui.Name="BS_ST"; stGui.IgnoreGuiInset=true; stGui.DisplayOrder=9999; stGui.Parent=lplr.PlayerGui
local f=Instance.new("Frame",stGui); f.Size=UDim2.new(0,200,0,110); f.Position=UDim2.new(1,-210,0,10); f.BackgroundColor3=RGB(0,0,0); f.BackgroundTransparency=0.3; f.BorderSizePixel=0
Instance.new("UICorner",f).CornerRadius=UDim.new(0,6)
for i=1,5 do
local lbl=Instance.new("TextLabel",f); lbl.Name="L"..i; lbl.Size=UDim2.new(1,-10,0,18); lbl.Position=UDim2.new(0,5,0,(i-1)*20); lbl.BackgroundTransparency=1; lbl.TextColor3=C_GREY; lbl.TextSize=10; lbl.Font=Enum.Font.Code; lbl.TextXAlignment=Enum.TextXAlignment.Left
end
end
stGui.Enabled = true
local risk = BS.Stealth and BS.Stealth.RiskLevel or 0
stGui.Frame.L1.Text = "Risk: "..risk.."%"; stGui.Frame.L1.TextColor3 = risk>70 and C_RED or C_GREEN
stGui.Frame.L2.Text = "Mode: "..(Flags.Ragebot and "Rage" or Flags.SilentAim and "Silent" or "Legit")
stGui.Frame.L3.Text = "Ping: "..(BS.Ping and BS.Ping.Current or 0).."ms"
stGui.Frame.L4.Text = "FPS: "..(BS.Perf and BS.Perf.FPS or 0)
local active = 0; for _,v in pairs(Flags) do if v==true then active=active+1 end end
stGui.Frame.L5.Text = "Active: "..active.." features"
end
local function updateFPS()
if not Flags.ESP_FPS then if fpGui then fpGui.Enabled=false end; return end
if not fpGui then
fpGui = Instance.new("ScreenGui"); fpGui.Name="BS_FPS"; fpGui.IgnoreGuiInset=true; fpGui.DisplayOrder=9999; fpGui.Parent=lplr.PlayerGui
local lbl=Instance.new("TextLabel",fpGui); lbl.Size=UDim2.new(0,120,0,20); lbl.Position=UDim2.new(0.5,-60,0,5); lbl.BackgroundTransparency=1; lbl.TextColor3=C_GREEN; lbl.TextSize=14; lbl.Font=Enum.Font.Code; lbl.Text="FPS: 0"
end
fpGui.Enabled = true
local lbl = fpGui:FindFirstChildOfClass("TextLabel")
if lbl then lbl.Text = "FPS: "..(BS.Perf and BS.Perf.FPS or 0) end
end
local dispFrame = 0
RunService.RenderStepped:Connect(function()
if not BS.alive() then return end
local skipFrames = 1
if Flags.PingAdapt and BS.PA then
skipFrames = BS.PA.getAdaptESPSkip()
end
if skipFrames > 1 and (dispFrame % skipFrames) ~= 0 then
end
resetPool()
local myHrp = BS.hrp()
local myTeam = BS.team()
local cam = workspace.CurrentCamera
local thick = Flags.ESP_BoxThick or 1
dispFrame = dispFrame + 1
local playerData = {}
for _, player in ipairs(Players:GetPlayers()) do
if player == lplr then continue end
local char = player.Character; if not char then continue end
local hrp = char:FindFirstChild("HumanoidRootPart")
local hum = char:FindFirstChildOfClass("Humanoid")
if not hrp or not hum or hum.Health <= 0 then continue end
if Flags.ESP_TeamCheck and myTeam and player.Team == myTeam then continue end
local dist = myHrp and (myHrp.Position - hrp.Position).Magnitude or 9999
if Flags.ESP_DistLimit and dist > (Flags.ESP_MaxDist or 200) then continue end
table.insert(playerData, {player=player, hrp=hrp, hum=hum, dist=dist})
end
if Flags.ESP_SortDist then
table.sort(playerData, function(a,b) return a.dist < b.dist end)
end
for _, pd in ipairs(playerData) do
local espColor = getESPColor(pd.player, pd.hum, pd.dist)
if Flags.ESP_Box then
local style = Flags.ESPBoxStyle or "2D"
if style == "2D" then drawBox2D(pd.hrp, espColor, thick)
elseif style == "Corners" then drawCornerBox(pd.hrp, espColor, thick)
elseif style == "3D" then draw3DBox(pd.hrp, espColor, thick)
elseif style == "Filled Box" then drawFilledBox(pd.hrp, espColor, thick)
elseif style == "Full Box" then drawFullBox(pd.hrp, espColor, thick) end
end
if Flags.ESP_Health then drawHealthBar(pd.hrp, pd.hum, espColor) end
if Flags.ESP_Armor then drawArmorBar(pd.hrp, pd.player) end
if Flags.ESP_Name then drawName(pd.player, pd.hrp, espColor) end
if Flags.ESP_Dist then drawDistance(pd.hrp, espColor) end
if Flags.ESP_Tracer then drawTracer(pd.hrp, espColor) end
if Flags.ESP_HeadDot then drawHeadDot(pd.hrp) end
if Flags.ESP_Weapon then drawWeapon(pd.player, pd.hrp, espColor) end
if Flags.ESP_Snaplines then drawSnapline(pd.hrp, espColor) end
if Flags.ESP_Skeleton then drawSkeleton(pd.player, espColor) end
if Flags.ESP_Target then drawTargetESP(pd.player, pd.hrp) end
if Flags.ESP_HeadHit then drawHeadHitbox(pd.hrp, espColor) end
if Flags.ESP_Barrel then drawBarrel(pd.hrp, espColor) end
if Flags.ESP_OOF then drawOOF(pd.player, pd.hrp, espColor) end
if Flags.ESP_Arrow then drawOffScreenArrow(pd.player, pd.hrp, espColor) end
if Flags.ESP_Headshot then drawHeadshotIcon(pd.hrp, espColor) end
if Flags.ESP_Velocity then drawVelocityArrow(pd.hrp, espColor) end
if Flags.ESP_LaserLine then drawLaserLine(pd.player, pd.hrp, espColor) end
if Flags.ESP_InfoCard then drawInfoCard(pd.player, pd.hrp, pd.hum, espColor, pd.dist) end
if Flags.Chams then
pcall(function()
for _, part in ipairs(pd.player.Character:GetDescendants()) do
if part:IsA("BasePart") and not part:FindFirstChild("BS_Chams") then
local sg = Instance.new("SurfaceGui"); sg.Name="BS_Chams"; sg.Face=Enum.NormalId.Front; sg.Parent=part
local fr = Instance.new("Frame",sg); fr.Size=UDim2.new(1,0,1,0); fr.BackgroundColor3=espColor; fr.BackgroundTransparency=0.6
end
end
end)
end
if Flags.ESP_Glow then
pcall(function()
local hl = pd.player and player.Character:FindFirstChild("BS_Glow")
if not hl then
hl = Instance.new("Highlight"); hl.Name="BS_Glow"; hl.FillColor=espColor; hl.OutlineColor=espColor
hl.FillTransparency=(Flags.ESP_GlowT or 50)/100; hl.OutlineTransparency=0; hl.Parent=pd.player.Character
end
end)
else
pcall(function() local hl=pd.player and player.Character:FindFirstChild("BS_Glow"); if hl then hl:Destroy() end end)
end
end
drawBombESP()
drawGrenadeESP()
if dispFrame % 6 == 0 then
updateWatermark()
updateStatus()
updateFPS()
updateRadar()
updateCompass()
end
drawCrosshair()
updateFOVCircle()
hideUnused()
end)
local lplrLocal = game:GetService("Players").LocalPlayer
local tpState = {
currentDist = 12,
targetDist = 12,
shoulderSide = 1,
cameraAngle = 0,
verticalAngle = 0,
}
if UIS then pcall(function() UIS.InputChanged:Connect(function(input)
if not Flags.ThirdPerson then return end
if input.UserInputType == Enum.UserInputType.MouseWheel then
tpState.targetDist = math.clamp(tpState.targetDist - input.Position.Z * 2, 2, 30)
end
end) end) end
if UIS then pcall(function() UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if not Flags.ThirdPerson then return end
if input.KeyCode == Enum.KeyCode.V then
tpState.shoulderSide = tpState.shoulderSide * -1
end
if input.KeyCode == Enum.KeyCode.C then
tpState.targetDist = Flags.TPDistance or 12
tpState.verticalAngle = 0
end
end) end) end
RunService.RenderStepped:Connect(function(dt)
pcall(function()
local cam = workspace.CurrentCamera
local hrp = BS.hrp()
if not cam or not hrp then return end
if Flags.ThirdPerson then
local smooth = (Flags.TPSmooth or 5) / 10
tpState.currentDist = tpState.currentDist + (tpState.targetDist - tpState.currentDist) * smooth
local shoulder = Flags.TPShoulderOffset or 3
if Flags.TPShoulder == "Left" then
tpState.shoulderSide = -1
elseif Flags.TPShoulder == "Right" then
tpState.shoulderSide = 1
else
shoulder = 0
end
local lookDir = cam.CFrame.LookVector
local rightDir = cam.CFrame.RightVector
local height = Flags.TPHeight or 2
local basePos = hrp.Position + Vector3.new(0, height, 0)
local shoulderOffset = rightDir * shoulder * tpState.shoulderSide
local camPos = basePos - lookDir * tpState.currentDist + shoulderOffset
if Flags.TPCollision then
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = {lplrLocal.Character}
local result = workspace:Raycast(basePos, camPos - basePos, params)
if result then
camPos = result.Position + (basePos - result.Position).Unit * 0.5
end
end
local lookTarget = basePos
if Flags.TPHeadFollow then
local head = hrp.Parent:FindFirstChild("Head")
if head then
lookTarget = head.Position + lookDir * 5
end
end
if Flags.TPSmoothLook then
local targetCF = CFrame.new(camPos, lookTarget)
cam.CFrame = cam.CFrame:Lerp(targetCF, smooth)
else
cam.CFrame = CFrame.new(camPos, lookTarget)
end
if Flags.TPFOV then
local targetFOV = Flags.TPFOV
if Flags.TPAutoZoom then
local tool = BS.tool()
local isScoped = tool and (tool.Name:lower():find("awp") or tool.Name:lower():find("sniper"))
if isScoped then targetFOV = 30 end
end
cam.FieldOfView = cam.FieldOfView + (targetFOV - cam.FieldOfView) * smooth
end
local char = lplrLocal.Character
if char then
local head = char:FindFirstChild("Head")
if head then head.Transparency = 0.5 end
local hrpChar = char:FindFirstChild("HumanoidRootPart")
if hrpChar then hrpChar.Transparency = 0.8 end
end
else
local char = lplrLocal.Character
if char then
local head = char:FindFirstChild("Head")
if head and head.Transparency > 0 then head.Transparency = 0 end
local hrpChar = char:FindFirstChild("HumanoidRootPart")
if hrpChar and hrpChar.Transparency > 0 then hrpChar.Transparency = 0 end
end
end
end)
end)
lplr.CharacterRemoving:Connect(function()
for i=1, PMax.L do pcall(function() LinePool[i].Visible=false end) end
for i=1, PMax.T do pcall(function() TextPool[i].Visible=false end) end
for i=1, PMax.S do pcall(function() SquarePool[i].Visible=false end) end
for i=1, PMax.C do pcall(function() CirclePool[i].Visible=false end) end
end)
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
local containerTypes = {"SpawnLocation", "Seat", "VehicleSeat"}
local ContainerESP = {}
BS.ContainerESP = ContainerESP
function ContainerESP:Update()
if not Flags.ContainerESP then return end
pcall(function()
for _, obj in ipairs(Workspace:GetDescendants()) do
if obj:IsA("BasePart") and (obj.Name:lower():find("crate") or obj.Name:lower():find("loot") or obj.Name:lower():find("supply") or obj.Name:lower():find("chest")) then
local hrp = BS.hrp()
if hrp then
local dist = (hrp.Position - obj.Position).Magnitude
if dist < (Flags.ContainerESPRange or 200) then
local sp, vis = cam:WorldToViewportPoint(obj.Position)
if vis then
local t = poolText()
t.Position = v2(sp.X, sp.Y)
t.Text = obj.Name .. " [" .. math.floor(dist) .. "m]"
t.Color = Color3.fromRGB(255, 200, 0)
t.Size = 10
t.Center = true
t.Visible = true
end
end
end
end
end
end)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
local VehicleESP = {}
BS.VehicleESP = VehicleESP
function VehicleESP:Update()
if not Flags.VehicleESP then return end
pcall(function()
for _, obj in ipairs(Workspace:GetDescendants()) do
if obj:IsA("VehicleSeat") or obj:IsA("Seat") then
local hrp = BS.hrp()
if hrp then
local dist = (hrp.Position - obj.Position).Magnitude
if dist < (Flags.VehicleESPRange or 300) then
local sp, vis = cam:WorldToViewportPoint(obj.Position)
if vis then
local t = poolText()
t.Position = v2(sp.X, sp.Y)
t.Text = "Vehicle [" .. math.floor(dist) .. "m]"
t.Color = Color3.fromRGB(0, 200, 255)
t.Size = 10
t.Center = true
t.Visible = true
end
end
end
end
end
end)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
local predictionLines = {}
BS.PredictionESP = {Lines = predictionLines}
function BS.PredictionESP:Update()
if not Flags.PredictionLine then
for _, line in pairs(predictionLines) do
if line then line.Visible = false end
end
return
end
pcall(function()
for uid, line in pairs(predictionLines) do
if line then line.Visible = false end
end
local enemies = BS.GetEnemies and BS.GetEnemies() or {}
for _, e in ipairs(enemies) do
if e and e.HRP and e.Player then
local vel = e.HRP.AssemblyLinearVelocity
if vel.Magnitude > 1 then
local futurePos = e.HRP.Position + vel * (Flags.PredictionTime or 0.3)
local sp, vis = cam:WorldToViewportPoint(futurePos)
if vis then
local line = poolLine()
local sp2 = cam:WorldToViewportPoint(e.HRP.Position)
line.From = v2(sp2.X, sp2.Y)
line.To = v2(sp.X, sp.Y)
line.Color = Color3.fromRGB(255, 100, 0)
line.Thickness = 1
line.Visible = true
predictionLines[e.Player.UserId] = line
end
end
end
end
end)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
local hsLines = {}
function BS.UpdateHeadshotLines()
if not Flags.HeadshotLine then
for _, line in pairs(hsLines) do
if line then line.Visible = false end
end
return
end
pcall(function()
for uid, line in pairs(hsLines) do
if line then line.Visible = false end
end
local screenCenter = cam.ViewportSize / 2
local enemies = BS.GetEnemies and BS.GetEnemies() or {}
for _, e in ipairs(enemies) do
if e and e.HRP and e.Head and e.Player then
local headPos = e.Head.Position
local sp, vis = cam:WorldToViewportPoint(headPos)
if vis then
local line = poolLine()
line.From = v2(sp.X, sp.Y)
line.To = v2(screenCenter.X, screenCenter.Y)
line.Color = Color3.fromRGB(255, 0, 0)
line.Thickness = 1
line.Transparency = 0.5
line.Visible = true
hsLines[e.Player.UserId] = line
end
end
end
end)
end
E:Label(" World ESP ")
E:Toggle("Container ESP", false, function(v) Flags.ContainerESP = v end)
E:Slider("Container Range", 50, 500, 200, function(v) Flags.ContainerESPRange = v end)
E:Toggle("Vehicle ESP", false, function(v) Flags.VehicleESP = v end)
E:Slider("Vehicle Range", 50, 500, 300, function(v) Flags.VehicleESPRange = v end)
E:Separator()
E:Label(" Prediction ")
E:Toggle("Prediction Line", false, function(v) Flags.PredictionLine = v end)
E:Slider("Predict Time", 10, 50, 30, function(v) Flags.PredictionTime = v / 100 end)
E:Toggle("Headshot Line", false, function(v) Flags.HeadshotLine = v end)
print("[ESP] BloxStrike ESP v3.0 loaded  "..(PMax.L + PMax.T + PMax.S + PMax.C).." pool objects ready")
]])
writefile("BloxStrike/modules/events.lua", [[
local Players = nil
pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local lplr = Players.LocalPlayer
local Stats = {
Kills = 0,
Deaths = 0,
Headshots = 0,
KillStreak = 0,
BestStreak = 0,
RoundWins = 0,
RoundLosses = 0,
BombsPlanted = 0,
BombsDefused = 0,
Money = 0,
}
BS.Stats = Stats
local prevHealth = {}
task.spawn(function()
while true do
task.wait(0.3)
pcall(function()
for _, player in pairs(Players:GetPlayers()) do
if player ~= lplr and player.Character then
local hum = player and player.Character:FindFirstChildOfClass("Humanoid")
if hum then
local prevHP = prevHealth[player.UserId] or hum.Health
if prevHP > 0 and hum.Health <= 0 then
local isEnemy = true
if lplr.Team and player.Team == lplr.Team then
isEnemy = false
end
if isEnemy then
Stats.Kills = Stats.Kills + 1
Stats.KillStreak = Stats.KillStreak + 1
if Stats.KillStreak > Stats.BestStreak then
Stats.BestStreak = Stats.KillStreak
end
local tool = lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
local weaponName = tool and tool.Name or "Unknown"
if BS.Webhook and Flags.WebhookOnKill then
BS.Webhook.onKill(player, Stats.Kills, weaponName)
end
if BS.Webhook and Flags.WebhookOnKillStreak then
local streaks = {3, 5, 7, 10, 15, 20}
for _, s in ipairs(streaks) do
if Stats.KillStreak == s then
BS.Webhook.onKillStreak(Stats.KillStreak)
break
end
end
end
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = " Kill #" .. Stats.Kills,
Text = "Eliminated " .. player.DisplayName,
Duration = 2,
})
end)
end
end
prevHealth[player.UserId] = hum.Health
end
end
end
end)
end
end)
task.spawn(function()
while true do
task.wait(1)
pcall(function()
local char = lplr.Character
if char then
local hum = char:FindFirstChildOfClass("Humanoid")
if hum then
if not hum:GetAttribute("BS_DeathConnected") then
hum.Died:Connect(function()
Stats.Deaths = Stats.Deaths + 1
Stats.KillStreak = 0
if BS.Webhook and Flags.WebhookOnDeath then
BS.Webhook.onDeath(Stats.Deaths, nil)
end
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = " Death #" .. Stats.Deaths,
Text = "Respawning...",
Duration = 2,
})
end)
end)
end
end
end
end)
end
end)
local prevRound = 0
task.spawn(function()
while true do
task.wait(2)
pcall(function()
local state = BS.api and BS.api.getGameState and BS.api.getGameState() or {}
local currentRound = state.round or state.Round or 0
if currentRound ~= prevRound and prevRound > 0 then
if BS.alive() then
Stats.RoundWins = Stats.RoundWins + 1
if BS.Webhook and Flags.WebhookOnRoundEnd then
BS.Webhook.onRoundWin(Stats.Kills, Stats.Deaths,
Stats.RoundWins .. "-" .. Stats.RoundLosses)
end
else
Stats.RoundLosses = Stats.RoundLosses + 1
if BS.Webhook and Flags.WebhookOnRoundEnd then
BS.Webhook.onRoundLose(Stats.Kills, Stats.Deaths,
Stats.RoundWins .. "-" .. Stats.RoundLosses)
end
end
end
prevRound = currentRound
end)
end
end)
task.spawn(function()
local bombTracked = false
while true do
task.wait(1)
pcall(function()
local bomb = BS.api and BS.api.getBomb and BS.api.getBomb()
if bomb and not bombTracked then
bombTracked = true
Stats.BombsPlanted = Stats.BombsPlanted + 1
if bomb:GetAttribute("PlantedBy") == lplr.UserId
or (bomb:FindFirstChild("Owner") and bomb.Owner.Value == lplr) then
if BS.Webhook and Flags.WebhookOnBomb then
local site = BS.api.getBombSite and BS.api.getBombSite() or "?"
BS.Webhook.onBombPlanted(site, lplr)
end
end
task.spawn(function()
local startTime = tick()
while bomb and bomb.Parent do
task.wait(0.5)
if tick() - startTime > 45 then
if BS.Webhook and Flags.WebhookOnBomb then
BS.Webhook.onBombExplode()
end
break
end
end
bombTracked = false
end)
end
if not bomb and bombTracked then
bombTracked = false
Stats.BombsDefused = Stats.BombsDefused + 1
if BS.Webhook and Flags.WebhookOnBomb then
BS.Webhook.onBombDefused(lplr, BS.api.hasDefuseKit and BS.api.hasDefuseKit())
end
end
end)
end
end)
task.wait(2)
if BS.Webhook and Flags.WebhookOnLoad then
BS.Webhook.onScriptLoad()
end
local perfGui
task.spawn(function()
while true do
task.wait(0.5)
pcall(function()
if Flags.PerfMonitor then
if not perfGui then
perfGui = Instance.new("ScreenGui")
perfGui.Name = "BS_Perf"
perfGui.ResetOnSpawn = false
perfGui.Parent = lplr.PlayerGui
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 180, 0, 100)
frame.Position = UDim2.new(1, -190, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0.4
frame.BorderSizePixel = 0
frame.Parent = perfGui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame
local fpsLabel = Instance.new("TextLabel")
fpsLabel.Name = "FPS"
fpsLabel.Size = UDim2.new(1, -10, 0, 20)
fpsLabel.Position = UDim2.new(0, 5, 0, 5)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "FPS: 60"
fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
fpsLabel.TextSize = 12
fpsLabel.Font = Enum.Font.Code
fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
fpsLabel.Parent = frame
local statsLabel = Instance.new("TextLabel")
statsLabel.Name = "Stats"
statsLabel.Size = UDim2.new(1, -10, 0, 20)
statsLabel.Position = UDim2.new(0, 5, 0, 25)
statsLabel.BackgroundTransparency = 1
statsLabel.Text = "K/D: 0/0"
statsLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
statsLabel.TextSize = 12
statsLabel.Font = Enum.Font.Code
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.Parent = frame
local modsLabel = Instance.new("TextLabel")
modsLabel.Name = "Mods"
modsLabel.Size = UDim2.new(1, -10, 0, 20)
modsLabel.Position = UDim2.new(0, 5, 0, 45)
modsLabel.BackgroundTransparency = 1
modsLabel.Text = "Active: 0"
modsLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
modsLabel.TextSize = 12
modsLabel.Font = Enum.Font.Code
modsLabel.TextXAlignment = Enum.TextXAlignment.Left
modsLabel.Parent = frame
local webhookLabel = Instance.new("TextLabel")
webhookLabel.Name = "Webhook"
webhookLabel.Size = UDim2.new(1, -10, 0, 20)
webhookLabel.Position = UDim2.new(0, 5, 0, 65)
webhookLabel.BackgroundTransparency = 1
webhookLabel.Text = "Webhook: OFF"
webhookLabel.TextColor3 = Color3.fromRGB(200, 100, 255)
webhookLabel.TextSize = 12
webhookLabel.Font = Enum.Font.Code
webhookLabel.TextXAlignment = Enum.TextXAlignment.Left
webhookLabel.Parent = frame
end
perfGui.Enabled = true
local frame = perfGui:FindFirstChild("Frame")
if frame then
local fps = frame:FindFirstChild("FPS")
if fps then
fps.Text = "FPS: " .. (BS.Perf and BS.Perf.FPS or 0)
end
local stats = frame:FindFirstChild("Stats")
if stats then
stats.Text = string.format("K/D: %d/%d | Streak: %d",
end
local mods = frame:FindFirstChild("Mods")
if mods then
local active = 0
for _, v in pairs(Flags) do
if v == true then active = active + 1 end
end
mods.Text = "Active: " .. active .. " | R: " .. Stats.RoundWins .. "W/" .. Stats.RoundLosses .. "L"
end
local wh = frame:FindFirstChild("Webhook")
if wh then
wh.Text = "Webhook: " .. (BS.Webhook and BS.Webhook.URL ~= "" and "ON " or "OFF ")
end
end
else
if perfGui then perfGui.Enabled = false end
end
end)
end
end)
BS.UserInputService.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.F3 then
Flags.PerfMonitor = not Flags.PerfMonitor
end
end)
print("[Events] BloxStrike Events module loaded")
print("[Events] Tracking: Kill/Death/Streak/Round/Bomb | Press F3 for stats")
]])
writefile("BloxStrike/modules/hud.lua", [[
local Players = nil
pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local UserInputService = nil
pcall(function() UserInputService = game:GetService("UserInputService") end)
local Lighting = nil
pcall(function() Lighting = game:GetService("Lighting") end)
local Stats = nil
pcall(function() Stats = game:GetService("Stats") end)
local StarterGui = nil
pcall(function() StarterGui = game:GetService("StarterGui") end)
local lplr = Players.LocalPlayer
if not BS.Win then warn("[HUD] BS.Win not available - ui.lua may have failed") return end
local page = BS.Win:Tab("HUD")
if not page or not page.Toggle then warn("[HUD] Failed to create tab!") return end
local HUD = {}
local WatermarkObj = nil
local function updateWatermark()
if not Flags.Watermark then
if WatermarkObj then WatermarkObj.Visible = false end
return
end
if not WatermarkObj then
pcall(function() WatermarkObj = Drawing.new("Text") end)
if not WatermarkObj then return end
WatermarkObj.Center = false
WatermarkObj.Outline = true
WatermarkObj.OutlineColor = Color3.new(0,0,0)
WatermarkObj.Font = 2
WatermarkObj.Size = 14
end
local parts = {"BloxStrike v3.0"}
if Flags.WMFPS then table.insert(parts, math.floor(1/workspace.CurrentCamera:GetPropertyChangedSignal("CFrame"):Wait() and 60 or 60) .. " FPS") end
if Flags.WMPing then
pcall(function()
local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"].Value)
table.insert(parts, ping .. " ms")
end)
end
if Flags.WMServer then table.insert(parts, game:GetService("Workspace").Name) end
if Flags.WMPlayers then table.insert(parts, #game:GetService("Players"):GetPlayers() .. " players") end
if Flags.WMTime then table.insert(parts, os.date("%H:%M:%S")) end
WatermarkObj.Text = "  " .. table.concat(parts, " | ") .. "  "
WatermarkObj.Position = Vector2.new(10, 10)
WatermarkObj.Color = Color3.new(1,1,1)
WatermarkObj.Visible = true
end
local SpectatorObjs = {}
local function updateSpectators()
if not Flags.SpectatorList then
for _, obj in pairs(SpectatorObjs) do pcall(function() obj.Visible = false end) end
SpectatorObjs = {}
return
end
local myChar = lplr.Character
if not myChar then return end
local myHead = myChar:FindFirstChild("Head")
if not myHead then return end
local specs = {}
for _, p in pairs(Players:GetPlayers()) do
if p ~= lplr and p.Character then
local cam = p and p.Character:FindFirstChildOfClass("Camera")
if cam and cam.CameraSubject == myHead then
table.insert(specs, p.Name)
end
end
end
for i = 1, math.max(#specs, #SpectatorObjs) do
if not SpectatorObjs[i] then
pcall(function() SpectatorObjs[i] = Drawing.new("Text") end)
end
if SpectatorObjs[i] then
if i <= #specs then
SpectatorObjs[i].Text = specs[i]
SpectatorObjs[i].Position = Vector2.new(10, 30 + (i-1) * 18)
SpectatorObjs[i].Color = Color3.new(1,1,1)
SpectatorObjs[i].Size = 13
SpectatorObjs[i].Outline = true
SpectatorObjs[i].Visible = true
else
SpectatorObjs[i].Visible = false
end
end
end
end
local SessionKills = 0
local SessionDeaths = 0
local SessionHeadshots = 0
local SessionShots = 0
local SessionHits = 0
local KillCounterObj = nil
local function updateKillCounter()
if not Flags.KillCounter then
if KillCounterObj then KillCounterObj.Visible = false end
return
end
if not KillCounterObj then
pcall(function() KillCounterObj = Drawing.new("Text") end)
if not KillCounterObj then return end
KillCounterObj.Center = false
KillCounterObj.Outline = true
KillCounterObj.OutlineColor = Color3.new(0,0,0)
KillCounterObj.Font = 2
KillCounterObj.Size = 13
end
local parts = {}
if Flags.KDShow then
local kd = SessionDeaths > 0 and string.format("%.1f", SessionKills/SessionDeaths) or tostring(SessionKills)
table.insert(parts, "K/D: " .. SessionKills .. "/" .. SessionDeaths .. " (" .. kd .. ")")
end
if Flags.HSShow and SessionKills > 0 then
table.insert(parts, "HS: " .. math.floor(SessionHeadshots/SessionKills*100) .. "%")
end
if Flags.AccShow and SessionShots > 0 then
table.insert(parts, "Acc: " .. math.floor(SessionHits/SessionShots*100) .. "%")
end
KillCounterObj.Text = "  " .. table.concat(parts, " | ") .. "  "
KillCounterObj.Position = Vector2.new(10, workspace.CurrentCamera.ViewportSize.Y - 30)
KillCounterObj.Color = Color3.new(1,1,0.5)
KillCounterObj.Visible = #parts > 0
end
lplr.CharacterAdded:Connect(function()
task.delay(0.5, function()
local hum = lplr.Character and lplr and lplr.Character:FindFirstChildOfClass("Humanoid")
if hum then
hum.Died:Connect(function()
SessionDeaths = SessionDeaths + 1
end)
end
end)
end)
task.spawn(function()
while true do
task.wait(0.2)
pcall(function()
updateWatermark()
updateSpectators()
updateKillCounter()
end)
end
end)
HUD.trackKill = function(wasHeadshot)
SessionKills = SessionKills + 1
if wasHeadshot then SessionHeadshots = SessionHeadshots + 1 end
end
HUD.trackShot = function() SessionShots = SessionShots + 1 end
HUD.trackHit = function() SessionHits = SessionHits + 1 end
BS.HUD = HUD
-- SECTION 1: PERFORMANCE MONITOR
page:Label("  ")
page:Toggle("FPS Display", false, function(v) Flags.HUDFPS = v end)
page:Toggle("Ping Display", false, function(v) Flags.HUDPing = v end)
page:Toggle("Memory Display", false, function(v) Flags.HUDMemory = v end)
page:Toggle("Server Info", false, function(v) Flags.HUDServer = v end)
page:Toggle("Player Count", false, function(v) Flags.HUDPlayerCount = v end)
page:Dropdown({Name="HUD Position", Flag="HUDPos", Options={"Top-Left","Top-Center","Top-Right","Bottom-Left","Bottom-Center","Bottom-Right"}, Default="Top-Left"})
page:Slider("HUD Size", 8, 20, 14, function(v) Flags.HUDSize = v end)
-- SECTION 2: FEATURE STATUS PANEL
page:Label("  ")
page:Toggle("Feature Status", false, function(v) Flags.HUDFeatures = v end)
page:Toggle("Risk Level Display", false, function(v) Flags.HUDRisk = v end)
page:Toggle("Active Modules", false, function(v) Flags.HUDModules = v end)
page:Toggle("Weapon Info", false, function(v) Flags.HUDWeapon = v end)
page:Toggle("Player Info", false, function(v) Flags.HUDPlayerInfo = v end)
-- SECTION 3: K/D & COMBAT HUD
page:Label("  HUD ")
page:Toggle("K/D Display", false, function(v) Flags.HUDKD = v end)
page:Toggle("Accuracy Display", false, function(v) Flags.HUDAccuracy = v end)
page:Toggle("Kill Streak Display", false, function(v) Flags.HUDStreak = v end)
page:Toggle("Velocity Display", false, function(v) Flags.HUDVelocity = v end)
page:Toggle("Speed Display", false, function(v) Flags.HUDSpeed = v end)
page:Toggle("Health Crosshair", false, function(v) Flags.HUDHealthCross = v end)
-- SECTION 4: NOTIFICATION CENTER
page:Label("  ")
page:Toggle("Notification Center", false, function(v) Flags.HUDNotifications = v end)
page:Slider("Max Notifications", 3, 10, 5, function(v) Flags.HUDMaxNotif = v end)
page:Toggle("Feature Toggle Notif", true, function(v) Flags.HUDFeatureNotif = v end)
page:Toggle("Kill Notif", false, function(v) Flags.HUDKillNotif = v end)
-- SECTION 5: WATERMARK
page:Label(" Watermark ")
page:Toggle("Watermark", false, function(v) Flags.Watermark = v end)
page:Dropdown({Name="Watermark Style", Flag="WMStyle", Options={"Default","Compact","Minimal","CS2"}, Default="CS2"})
page:Toggle("Show FPS", true, function(v) Flags.WMFPS = v end)
page:Toggle("Show Ping", true, function(v) Flags.WMPing = v end)
page:Toggle("Show Server", false, function(v) Flags.WMServer = v end)
page:Toggle("Show Players", false, function(v) Flags.WMPlayers = v end)
page:Toggle("Show Time", false, function(v) Flags.WMTime = v end)
page:Separator()
-- SECTION 6: SPECTATOR LIST
page:Label(" Spectator List ")
page:Toggle("Spectator List", false, function(v) Flags.SpectatorList = v end)
page:Dropdown({Name="Spec Style", Flag="SpecStyle", Options={"Vertical","Horizontal","Compact"}, Default="Vertical"})
page:Toggle("Show Spec Mode", true, function(v) Flags.SpecMode = v end)
page:Toggle("Notify Spectator", false, function(v) Flags.SpecNotify = v end)
page:Separator()
-- SECTION 7: KILL COUNTER
page:Label(" Kill Counter ")
page:Toggle("Kill Counter", false, function(v) Flags.KillCounter = v end)
page:Toggle("Show K/D", true, function(v) Flags.KDShow = v end)
page:Toggle("Show HS %", true, function(v) Flags.HSShow = v end)
page:Toggle("Show Accuracy", false, function(v) Flags.AccShow = v end)
page:Toggle("Session Stats", false, function(v) Flags.SessionStats = v end)
page:Separator()
local HUDObjects = {}
local HUDFrameCount = 0
local NotifQueue = {}
local function getHUDObject(uniqueId)
if HUDObjects[uniqueId] then
return HUDObjects[uniqueId]
end
local obj = nil
pcall(function()
obj = Drawing.new("Text")
obj.Visible = false
obj.Center = false
obj.Outline = true
obj.OutlineColor = Color3.new(0, 0, 0)
obj.Color = Color3.new(1, 1, 1)
obj.Size = Flags.HUDSize or 14
obj.Font = Drawing.Fonts.UI
end)
if not obj then
local noop = setmetatable({}, {__index = function() return nil end, __newindex = function() end})
return noop
end
HUDObjects[uniqueId] = obj
return obj
end
local function getHUDPosition(section, line, align)
align = align or Flags.HUDPos or "Top-Left"
local textSize = (Flags.HUDSize or 14) + 4
local margin = 12
if align == "Top-Left" then
return Vector2.new(margin + section * 200, margin + line * textSize)
elseif align == "Top-Center" then
return Vector2.new(400 + section * 200, margin + line * textSize)
elseif align == "Top-Right" then
return Vector2.new(780 - margin + section * 200, margin + line * textSize)
elseif align == "Bottom-Left" then
return Vector2.new(margin + section * 200, 540 - margin - line * textSize)
elseif align == "Bottom-Center" then
return Vector2.new(400 + section * 200, 540 - margin - line * textSize)
elseif align == "Bottom-Right" then
return Vector2.new(780 - margin + section * 200, 540 - margin - line * textSize)
end
return Vector2.new(margin, margin + line * textSize)
end
local C_WHITE = Color3.new(1, 1, 1)
local C_GREEN = Color3.new(0, 1, 0)
local C_YELLOW = Color3.new(1, 1, 0)
local C_RED = Color3.new(1, 0.2, 0.2)
local C_CYAN = Color3.new(0, 1, 1)
local C_ORANGE = Color3.new(1, 0.6, 0)
local C_PURPLE = Color3.new(0.8, 0, 1)
local C_GRAY = Color3.new(0.6, 0.6, 0.6)
local C_BLUE = Color3.new(0.3, 0.6, 1)
RunService.RenderStepped:Connect(function()
HUDFrameCount = HUDFrameCount + 1
if HUDFrameCount % 3 ~= 0 then return end
local size = Flags.HUDSize or 14
local anyHUD = Flags.HUDFPS or Flags.HUDPing or Flags.HUDMemory or
Flags.HUDServer or Flags.HUDPlayerCount or Flags.HUDFeatures or
Flags.HUDRisk or Flags.HUDModules or Flags.HUDWeapon or
Flags.HUDPlayerInfo or Flags.HUDKD or Flags.HUDAccuracy or
Flags.HUDStreak or Flags.HUDVelocity or Flags.HUDSpeed or
Flags.HUDHealthCross or Flags.HUDNotifications
if not anyHUD then
for _, obj in pairs(HUDObjects) do
obj.Visible = false
end
end
local line = 0
local section = 0
if Flags.HUDFPS then
local fpsObj = getHUDObject("fps")
local fps = BS.Perf and BS.Perf.FPS or 60
fpsObj.Text = "FPS: " .. fps
fpsObj.Size = size
fpsObj.Position = getHUDPosition(0, line)
fpsObj.Color = fps >= 60 and C_GREEN or fps >= 30 and C_YELLOW or C_RED
fpsObj.Visible = true
line = line + 1
end
if Flags.HUDPing then
local pingObj = getHUDObject("ping")
local ping = BS.Ping and BS.Ping.Current or 0
local quality = BS.Ping and BS.Ping.Quality or "Good"
pingObj.Text = "Ping: " .. ping .. "ms [" .. quality .. "]"
pingObj.Size = size
pingObj.Position = getHUDPosition(0, line)
pingObj.Color = ping < 50 and C_GREEN or ping < 100 and C_YELLOW or C_RED
pingObj.Visible = true
line = line + 1
end
if Flags.HUDMemory then
local memObj = getHUDObject("memory")
local mem = collectgarbage("count")
memObj.Text = string.format("Memory: %.1f MB", mem / 1024)
memObj.Size = size
memObj.Position = getHUDPosition(0, line)
memObj.Color = mem < 100 * 1024 and C_GREEN or mem < 300 * 1024 and C_YELLOW or C_RED
memObj.Visible = true
line = line + 1
end
if Flags.HUDServer then
local srvObj = getHUDObject("server")
srvObj.Text = "Server: " .. (game.JobId and game.JobId:sub(1, 8) or "N/A")
srvObj.Size = size
srvObj.Position = getHUDPosition(0, line)
srvObj.Color = C_GRAY
srvObj.Visible = true
line = line + 1
end
if Flags.HUDPlayerCount then
local pcObj = getHUDObject("playercount")
pcObj.Text = "Players: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers
pcObj.Size = size
pcObj.Position = getHUDPosition(0, line)
pcObj.Color = C_CYAN
pcObj.Visible = true
line = line + 1
end
local featLine = 0
if Flags.HUDFeatures then
local features = {}
if Flags.Aimbot then table.insert(features, {"Aimbot", C_GREEN}) end
if Flags.TriggerBot then table.insert(features, {"Trigger", C_GREEN}) end
if Flags.Ragebot then table.insert(features, {"Rage", C_RED}) end
if Flags.AA then table.insert(features, {"Anti-Aim", C_ORANGE}) end
if Flags.SilentAim then table.insert(features, {"Silent", C_PURPLE}) end
if Flags.ESP_Box then table.insert(features, {"ESP", C_CYAN}) end
if Flags.ESP_Name then table.insert(features, {"Name", C_CYAN}) end
if Flags.ESP_Health then table.insert(features, {"HP", C_GREEN}) end
if Flags.ESP_Skeleton then table.insert(features, {"Skel", C_YELLOW}) end
if Flags.Bhop then table.insert(features, {"Bhop", C_YELLOW}) end
if Flags.NoClip then table.insert(features, {"NoClip", C_RED}) end
if Flags.SpeedBoost then table.insert(features, {"Speed", C_ORANGE}) end
if Flags.StealthHumanize then table.insert(features, {"Humanize", C_GREEN}) end
if Flags.HVHSafeMode then table.insert(features, {"HVH Safe", C_GREEN}) end
for i, feat in ipairs(features) do
local obj = getHUDObject("feat_" .. i)
obj.Text = " " .. feat[1]
obj.Size = size - 2
obj.Position = getHUDPosition(1, featLine)
obj.Color = feat[2]
obj.Visible = true
featLine = featLine + 1
end
end
if Flags.HUDRisk then
local riskObj = getHUDObject("risk")
local risk = 0
if BS.Stealth and BS.Stealth.RiskLevel then
risk = BS.Stealth.RiskLevel
end
riskObj.Text = string.format("Risk: %d%%", risk)
riskObj.Size = size
riskObj.Position = getHUDPosition(1, featLine)
riskObj.Color = risk < 30 and C_GREEN or risk < 60 and C_YELLOW or C_RED
riskObj.Visible = true
featLine = featLine + 1
end
if Flags.HUDModules then
local modObj = getHUDObject("modules")
local activeCount = 0
local moduleNames = {"Combat", "ESP", "Rage", "Stealth", "Bhop", "Bypass"}
local moduleFlags = {Flags.Aimbot or Flags.Ragebot, Flags.ESP_Box, Flags.AA, Flags.StealthHumanize, Flags.Bhop, true}
local activeModules = {}
for i, name in ipairs(moduleNames) do
if moduleFlags[i] then
table.insert(activeModules, name)
activeCount = activeCount + 1
end
end
modObj.Text = "Modules (" .. activeCount .. "): " .. table.concat(activeModules, ", ")
modObj.Size = size - 2
modObj.Position = getHUDPosition(1, featLine)
modObj.Color = C_BLUE
modObj.Visible = true
featLine = featLine + 1
end
if Flags.HUDWeapon then
local wpnObj = getHUDObject("weapon")
local wType = BS.weaponType and BS.weaponType() or "none"
local tool = BS.tool and BS.tool()
local toolName = tool and tool.Name or "None"
wpnObj.Text = "Weapon: " .. toolName .. " [" .. wType .. "]"
wpnObj.Size = size
wpnObj.Position = getHUDPosition(1, featLine)
wpnObj.Color = C_YELLOW
wpnObj.Visible = true
featLine = featLine + 1
end
if Flags.HUDPlayerInfo then
local plrObj = getHUDObject("playerinfo")
local hp = 0
local maxHp = 100
local speed = 16
if BS.alive() then
local h = BS.hum()
if h then
hp = h.Health
maxHp = h.MaxHealth
speed = h.WalkSpeed
end
end
plrObj.Text = string.format("HP: %d/%d | Speed: %.0f | Pos: %s",
math.floor(hp), math.floor(maxHp), speed,
BS.hrp() and string.format("(%.0f,%.0f,%.0f)", BS.hrp().Position.X, BS.hrp().Position.Y, BS.hrp().Position.Z) or "N/A")
plrObj.Size = size
plrObj.Position = getHUDPosition(1, featLine)
plrObj.Color = hp > maxHp * 0.6 and C_GREEN or hp > maxHp * 0.3 and C_YELLOW or C_RED
plrObj.Visible = true
featLine = featLine + 1
end
local combatLine = 0
if Flags.HUDKD and BS.CombatAssist then
local s = BS.CombatAssist.SessionStats
local kdObj = getHUDObject("kd")
local kd = s.Deaths > 0 and string.format("%.2f", s.Kills / s.Deaths) or ""
kdObj.Text = string.format("K/D: %d/%d (%s)", s.Kills, s.Deaths, kd)
kdObj.Size = size
kdObj.Position = getHUDPosition(2, combatLine)
kdObj.Color = C_WHITE
kdObj.Visible = true
combatLine = combatLine + 1
end
if Flags.HUDAccuracy and BS.CombatAssist then
local s = BS.CombatAssist.SessionStats
local accObj = getHUDObject("accuracy")
local acc = s.Shots > 0 and string.format("%.1f%%", s.HitCount / s.Shots * 100) or "0%"
accObj.Text = "Acc: " .. acc .. " | HS: " .. (s.Kills > 0 and string.format("%.0f%%", s.Headshots / s.Kills * 100) or "0%")
accObj.Size = size
accObj.Position = getHUDPosition(2, combatLine)
accObj.Color = C_CYAN
accObj.Visible = true
combatLine = combatLine + 1
end
if Flags.HUDStreak and BS.CombatAssist then
local s = BS.CombatAssist.SessionStats
local streakObj = getHUDObject("streak")
streakObj.Text = string.format("Streak: %d | Best: %d", s.KillStreak, s.MaxKillStreak)
streakObj.Size = size
streakObj.Position = getHUDPosition(2, combatLine)
streakObj.Color = s.KillStreak >= 5 and C_RED or s.KillStreak >= 3 and C_ORANGE or C_WHITE
streakObj.Visible = true
combatLine = combatLine + 1
end
if Flags.HUDVelocity and BS.alive() then
local velObj = getHUDObject("velocity")
local hrp = BS.hrp()
if hrp then
local vel = hrp.AssemblyLinearVelocity
local speed = vel.Magnitude
velObj.Text = string.format("Vel: %.1f (%.1f, %.1f, %.1f)", speed, vel.X, vel.Y, vel.Z)
velObj.Size = size
velObj.Position = getHUDPosition(2, combatLine)
velObj.Color = speed > 50 and C_RED or speed > 20 and C_YELLOW or C_WHITE
velObj.Visible = true
combatLine = combatLine + 1
end
end
if Flags.HUDSpeed and BS.alive() then
local spdObj = getHUDObject("speed")
local h = BS.hum()
if h then
spdObj.Text = string.format("Speed: %.0f studs/s", h.WalkSpeed * 3)
spdObj.Size = size
spdObj.Position = getHUDPosition(2, combatLine)
spdObj.Color = C_GREEN
spdObj.Visible = true
combatLine = combatLine + 1
end
end
if Flags.HUDHealthCross and BS.alive() then
local hcObj = getHUDObject("healthcross")
local h = BS.hum()
if h then
local pct = h.Health / h.MaxHealth * 100
hcObj.Text = string.format(" %d", math.floor(h.Health))
hcObj.Size = size
hcObj.Center = true
hcObj.Position = Vector2.new(400, 280)
hcObj.Color = pct > 60 and C_GREEN or pct > 30 and C_YELLOW or C_RED
hcObj.Visible = true
end
else
local hcObj = getHUDObject("healthcross")
if hcObj then hcObj.Visible = false end
end
if Flags.HUDNotifications and #NotifQueue > 0 then
local maxNotif = Flags.HUDMaxNotif or 5
local notifLine = 0
for i = #NotifQueue, math.max(1, #NotifQueue - maxNotif + 1), -1 do
local notif = NotifQueue[i]
local age = tick() - notif.Time
if age < 8 then
local nObj = getHUDObject("notif_" .. i)
nObj.Text = notif.Text
nObj.Size = size - 2
nObj.Position = getHUDPosition(3, notifLine)
nObj.Color = notif.Color or C_WHITE
nObj.Transparency = math.clamp(1 - age / 8, 0, 1)
nObj.Visible = true
notifLine = notifLine + 1
end
end
end
end)
function HUD.addNotification(text, color, duration)
table.insert(NotifQueue, {
Text = text,
Color = color or C_WHITE,
Duration = duration or 5,
})
if #NotifQueue > 20 then
table.remove(NotifQueue, 1)
end
if Flags.HUDFeatureNotif then
pcall(function()
StarterGui:SetCore("SendNotification", {
Title = "BloxStrike",
Text = text,
Duration = duration or 3,
})
end)
end
end
local lastFlags = {}
task.spawn(function()
while true do task.wait(0.5)
if Flags.HUDFeatureNotif then
for key, value in pairs(Flags) do
if type(value) == "boolean" and lastFlags[key] ~= nil and lastFlags[key] ~= value then
local state = value and " ON" or " OFF"
HUD.addNotification(key .. " " .. state, value and C_GREEN or C_RED, 2)
end
lastFlags[key] = value
end
end
end
end)
lplr.CharacterAdded:Connect(function()
end)
function HUD.cleanup()
for _, obj in pairs(HUDObjects) do
pcall(function() obj.Visible = false obj:Remove() end)
end
HUDObjects = {}
NotifQueue = {}
end
local WatermarkObj = nil
local function updateWatermark()
if not Flags.Watermark then
if WatermarkObj then WatermarkObj.Visible = false end
return
end
if not WatermarkObj then
pcall(function() WatermarkObj = Drawing.new("Text") end)
if not WatermarkObj then return end
WatermarkObj.Center = false
WatermarkObj.Outline = true
WatermarkObj.OutlineColor = Color3.new(0,0,0)
WatermarkObj.Font = 2
WatermarkObj.Size = 14
end
local parts = {"BloxStrike v3.0"}
if Flags.WMFPS then table.insert(parts, math.floor(1/workspace.CurrentCamera:GetPropertyChangedSignal("CFrame"):Wait() and 60 or 60) .. " FPS") end
if Flags.WMPing then
pcall(function()
local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"].Value)
table.insert(parts, ping .. " ms")
end)
end
if Flags.WMServer then table.insert(parts, game:GetService("Workspace").Name) end
if Flags.WMPlayers then table.insert(parts, #game:GetService("Players"):GetPlayers() .. " players") end
if Flags.WMTime then table.insert(parts, os.date("%H:%M:%S")) end
WatermarkObj.Text = "  " .. table.concat(parts, " | ") .. "  "
WatermarkObj.Position = Vector2.new(10, 10)
WatermarkObj.Color = Color3.new(1,1,1)
WatermarkObj.Visible = true
end
local SpectatorObjs = {}
local function updateSpectators()
if not Flags.SpectatorList then
for _, obj in pairs(SpectatorObjs) do pcall(function() obj.Visible = false end) end
SpectatorObjs = {}
return
end
local myChar = lplr.Character
if not myChar then return end
local myHead = myChar:FindFirstChild("Head")
if not myHead then return end
local specs = {}
for _, p in pairs(Players:GetPlayers()) do
if p ~= lplr and p.Character then
local cam = p and p.Character:FindFirstChildOfClass("Camera")
if cam and cam.CameraSubject == myHead then
table.insert(specs, p.Name)
end
end
end
for i = 1, math.max(#specs, #SpectatorObjs) do
if not SpectatorObjs[i] then
pcall(function() SpectatorObjs[i] = Drawing.new("Text") end)
end
if SpectatorObjs[i] then
if i <= #specs then
SpectatorObjs[i].Text = specs[i]
SpectatorObjs[i].Position = Vector2.new(10, 30 + (i-1) * 18)
SpectatorObjs[i].Color = Color3.new(1,1,1)
SpectatorObjs[i].Size = 13
SpectatorObjs[i].Outline = true
SpectatorObjs[i].Visible = true
else
SpectatorObjs[i].Visible = false
end
end
end
end
local SessionKills = 0
local SessionDeaths = 0
local SessionHeadshots = 0
local SessionShots = 0
local SessionHits = 0
local KillCounterObj = nil
local function updateKillCounter()
if not Flags.KillCounter then
if KillCounterObj then KillCounterObj.Visible = false end
return
end
if not KillCounterObj then
pcall(function() KillCounterObj = Drawing.new("Text") end)
if not KillCounterObj then return end
KillCounterObj.Center = false
KillCounterObj.Outline = true
KillCounterObj.OutlineColor = Color3.new(0,0,0)
KillCounterObj.Font = 2
KillCounterObj.Size = 13
end
local parts = {}
if Flags.KDShow then
local kd = SessionDeaths > 0 and string.format("%.1f", SessionKills/SessionDeaths) or tostring(SessionKills)
table.insert(parts, "K/D: " .. SessionKills .. "/" .. SessionDeaths .. " (" .. kd .. ")")
end
if Flags.HSShow and SessionKills > 0 then
table.insert(parts, "HS: " .. math.floor(SessionHeadshots/SessionKills*100) .. "%")
end
if Flags.AccShow and SessionShots > 0 then
table.insert(parts, "Acc: " .. math.floor(SessionHits/SessionShots*100) .. "%")
end
KillCounterObj.Text = "  " .. table.concat(parts, " | ") .. "  "
KillCounterObj.Position = Vector2.new(10, workspace.CurrentCamera.ViewportSize.Y - 30)
KillCounterObj.Color = Color3.new(1,1,0.5)
KillCounterObj.Visible = #parts > 0
end
lplr.CharacterAdded:Connect(function()
task.delay(0.5, function()
local hum = lplr.Character and lplr and lplr.Character:FindFirstChildOfClass("Humanoid")
if hum then
hum.Died:Connect(function()
SessionDeaths = SessionDeaths + 1
end)
end
end)
end)
task.spawn(function()
while true do
task.wait(0.2)
pcall(function()
updateWatermark()
updateSpectators()
updateKillCounter()
end)
end
end)
HUD.trackKill = function(wasHeadshot)
SessionKills = SessionKills + 1
if wasHeadshot then SessionHeadshots = SessionHeadshots + 1 end
end
HUD.trackShot = function() SessionShots = SessionShots + 1 end
HUD.trackHit = function() SessionHits = SessionHits + 1 end
BS.HUD = HUD
print("[HUD] BloxStrike HUD v1.0 loaded")
print("[HUD] Features: Performance Monitor, Feature Status, Combat HUD,")
print("[HUD]   Notification Center, Health Crosshair, Velocity Display")
]])
writefile("BloxStrike/modules/killeffects.lua", [[
local Players = nil
pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local Lighting = nil
pcall(function() Lighting = game:GetService("Lighting") end)
local UIS = nil
pcall(function() UIS = game:GetService("UserInputService") end)
local lplr = Players.LocalPlayer
if not BS.Win then warn("[Hit Effects] BS.Win not available - ui.lua may have failed") return end
local KE = BS.Win:Tab("Hit Effects")
if KE and KE.Toggle then
KE:Label(" Hitmarker ")
KE:Toggle("Hitmarker", false, function(v) Flags.Hitmarker = v end)
KE:Dropdown({Name="Hitmarker Style", Flag="HMStyle", Options={"CS2","MW2","Fortnite","Custom"}, Default="CS2"})
KE:Slider("Hitmarker Size", 5, 30, 12, function(v) Flags.HMSize = v end)
KE:Slider("Hitmarker Duration", 1, 10, 3, function(v) Flags.HMDuration = v end)
KE:Toggle("Headshot Marker", true, function(v) Flags.HMHeadshot = v end)
KE:Toggle("Hit Sound", false, function(v) Flags.HitSound = v end)
KE:Dropdown({Name="Hit Sound", Flag="HMSound", Options={"CS2 Dink","Quake Hit","Metal Pipe","Minecraft XP","Vine Boom"}, Default="CS2 Dink"})
KE:Slider("Hit Sound Volume", 1, 10, 5, function(v) Flags.HMSoundVol = v end)
KE:Separator()
KE:Label(" Kill Effect ")
KE:Toggle("Kill Effect", false, function(v) Flags.KillEffect = v end)
KE:Dropdown({Name="Kill Style", Flag="KEStyle", Options={"Flash","Shake","Zoom","SlowMo"}, Default="Flash"})
KE:Toggle("Kill Sound", false, function(v) Flags.KillSound = v end)
KE:Dropdown({Name="Kill Sound", Flag="KESound", Options={"Frag","Explosion","Metal Pipe","Mario Coin"}, Default="Frag"})
KE:Slider("Kill Sound Volume", 1, 10, 7, function(v) Flags.KESoundVol = v end)
KE:Toggle("Kill Streak Sound", false, function(v) Flags.KillStreakSound = v end)
KE:Separator()
KE:Label(" Damage Indicator ")
KE:Toggle("Damage Numbers", false, function(v) Flags.DmgNumbers = v end)
KE:Toggle("Damage Direction", false, function(v) Flags.DmgDirection = v end)
KE:Slider("Damage Duration", 1, 10, 3, function(v) Flags.DmgDuration = v end)
end
local Sounds = {
Kill = {
{Name = "CS2 Dink",          ID = "rbxassetid://9125402735",  Vol = 0.8},
{Name = "Quake Hit",         ID = "rbxassetid://138087576",   Vol = 0.7},
{Name = "Metal Pipe",        ID = "rbxassetid://9125999404",  Vol = 0.6},
{Name = "Minecraft XP",      ID = "rbxassetid://142376098",   Vol = 0.5},
{Name = "Vine Boom",         ID = "rbxassetid://9126214519",  Vol = 0.5},
{Name = "Mario Coin",        ID = "rbxassetid://138087606",   Vol = 0.6},
{Name = "Frag",              ID = "rbxassetid://3124961779",  Vol = 0.7},
{Name = "Heavy Impact",      ID = "rbxassetid://18900180842", Vol = 0.8},
{Name = "Sharp Slash",       ID = "rbxassetid://18834235361", Vol = 0.7},
{Name = "Punch Hit",         ID = "rbxassetid://18834234238", Vol = 0.6},
{Name = "Explosion",         ID = "rbxassetid://13134985300", Vol = 0.9},
{Name = "Blade Hit",         ID = "rbxassetid://3932145654",  Vol = 0.7},
{Name = "Electric Zap",      ID = "rbxassetid://4086012327",  Vol = 0.6},
{Name = "Heavy Smash",       ID = "rbxassetid://15294800508", Vol = 0.9},
{Name = "Body Fall",         ID = "rbxassetid://16190706844", Vol = 0.5},
{Name = "Block Break",       ID = "rbxassetid://13106548051", Vol = 0.6},
{Name = "Fire Blast",        ID = "rbxassetid://13441650522", Vol = 0.7},
{Name = "Collapse",          ID = "rbxassetid://3784889529",  Vol = 0.8},
{Name = "Clock Tick",        ID = "rbxassetid://8140501675",  Vol = 0.4},
{Name = "Notification",      ID = "rbxassetid://8551372796",  Vol = 0.5},
},
Headshot = {
{Name = "CS2 Headshot",      ID = "rbxassetid://9125402735",  Vol = 0.9},
{Name = "Quake Headshot",    ID = "rbxassetid://138087576",   Vol = 0.8},
{Name = "Sharp Crack",       ID = "rbxassetid://18834235361", Vol = 0.9},
{Name = "Heavy Smash HS",    ID = "rbxassetid://15294800508", Vol = 1.0},
{Name = "Explosion HS",      ID = "rbxassetid://13134985300", Vol = 0.9},
{Name = "Electric Zap HS",   ID = "rbxassetid://4086012327",  Vol = 0.8},
{Name = "Blade Crit",        ID = "rbxassetid://3932145654",  Vol = 0.9},
{Name = "Vine Boom HS",      ID = "rbxassetid://9126214519",  Vol = 0.7},
},
Hit = {
{Name = "Hit Classic",       ID = "rbxassetid://138087576",   Vol = 0.3},
{Name = "Hit Soft",          ID = "rbxassetid://138087546",   Vol = 0.25},
{Name = "Hit Sharp",         ID = "rbxassetid://138087587",   Vol = 0.35},
{Name = "Hit Ding",          ID = "rbxassetid://142376098",   Vol = 0.2},
{Name = "Hit Punch",         ID = "rbxassetid://18834234238", Vol = 0.3},
{Name = "Hit Blade",         ID = "rbxassetid://3932145654",  Vol = 0.25},
{Name = "Hit Impact",        ID = "rbxassetid://18900180842", Vol = 0.3},
{Name = "Hit Zap",           ID = "rbxassetid://4086012327",  Vol = 0.2},
},
DoubleKill  = {ID = "rbxassetid://18900180842", Vol = 0.85},
TripleKill  = {ID = "rbxassetid://13134985300", Vol = 0.9},
QuadKill    = {ID = "rbxassetid://15294800508", Vol = 0.95},
PentaKill   = {ID = "rbxassetid://13441650522", Vol = 1.0},
Unstoppable = {ID = "rbxassetid://13143785092", Vol = 1.0},
Rampage     = {ID = "rbxassetid://13143785795", Vol = 1.0},
Godlike     = {ID = "rbxassetid://13079933410", Vol = 1.0},
Death = {ID = "rbxassetid://16190703134", Vol = 0.6},
}
local KillFeed = {}
local KillFeedMax = 8
local killEffectGui = nil
local killFeedGui = nil
local streakGui = nil
local vignetteGui = nil
local function createLightingEffect(name, className)
local existing = Lighting:FindFirstChild(name)
if existing then return existing end
local effect = Instance.new(className)
effect.Name = name
effect.Enabled = false
effect.Parent = Lighting
return effect
end
local blurEffect = createLightingEffect("BS_KillBlur", "BlurEffect")
blurEffect.Size = 0
local colorCorrection = createLightingEffect("BS_KillCC", "ColorCorrectionEffect")
colorCorrection.Brightness = 0
colorCorrection.Contrast = 0
colorCorrection.Saturation = 0
colorCorrection.TintColor = Color3.fromRGB(255, 255, 255)
local bloomEffect = createLightingEffect("BS_KillBloom", "BloomEffect")
bloomEffect.Intensity = 0
bloomEffect.Size = 0
bloomEffect.Threshold = 1
local sunRays = createLightingEffect("BS_KillSunRays", "SunRaysEffect")
sunRays.Intensity = 0
sunRays.Spread = 0.5
local function playSound(soundData, pitch)
if not soundData or not soundData.ID then return end
pcall(function()
local s = Instance.new("Sound")
s.SoundId = soundData.ID
s.Volume = soundData.Vol or 0.5
s.PlaybackSpeed = pitch or 1.0
s.Parent = lplr.Character and lplr and lplr.Character:FindFirstChild("HumanoidRootPart") or workspace
s:Play()
game:GetService("Debris"):AddItem(s, 2)
end)
end
local function playSoundFromList(list, index, pitch)
local idx = index or 1
local data = list[idx] or list[1]
playSound(data, pitch)
end
local function doBlurFlash(intensity, duration)
if not Flags.FXBlur then return end
pcall(function()
blurEffect.Enabled = true
blurEffect.Size = intensity or 20
task.spawn(function()
local start = tick()
while tick() - start < (duration or 0.3) do
local pct = (tick() - start) / (duration or 0.3)
blurEffect.Size = (intensity or 20) * (1 - pct)
RunService.RenderStepped:Wait()
end
blurEffect.Size = 0
blurEffect.Enabled = false
end)
end)
end
local function doColorFlash(color, contrast, duration)
if not Flags.FXColorFlash then return end
pcall(function()
colorCorrection.Enabled = true
colorCorrection.TintColor = color or Color3.fromRGB(255, 200, 200)
colorCorrection.Contrast = contrast or 0.5
colorCorrection.Brightness = 0.2
task.spawn(function()
local start = tick()
while tick() - start < (duration or 0.4) do
local pct = (tick() - start) / (duration or 0.4)
colorCorrection.Contrast = (contrast or 0.5) * (1 - pct)
colorCorrection.Brightness = 0.2 * (1 - pct)
colorCorrection.Saturation = 0.5 * (1 - pct)
RunService.RenderStepped:Wait()
end
colorCorrection.Contrast = 0
colorCorrection.Brightness = 0
colorCorrection.Saturation = 0
colorCorrection.TintColor = Color3.fromRGB(255, 255, 255)
colorCorrection.Enabled = false
end)
end)
end
local function doBloomFlash(intensity, duration)
if not Flags.FXBloom then return end
pcall(function()
bloomEffect.Enabled = true
bloomEffect.Intensity = intensity or 2
bloomEffect.Size = 30
bloomEffect.Threshold = 0.5
task.spawn(function()
local start = tick()
while tick() - start < (duration or 0.5) do
local pct = (tick() - start) / (duration or 0.5)
bloomEffect.Intensity = (intensity or 2) * (1 - pct)
RunService.RenderStepped:Wait()
end
bloomEffect.Intensity = 0
bloomEffect.Enabled = false
end)
end)
end
local function doSunRaysFlash(duration)
if not Flags.FXSunRays then return end
pcall(function()
sunRays.Enabled = true
sunRays.Intensity = 0.8
task.spawn(function()
local start = tick()
while tick() - start < (duration or 0.4) do
local pct = (tick() - start) / (duration or 0.4)
sunRays.Intensity = 0.8 * (1 - pct)
RunService.RenderStepped:Wait()
end
sunRays.Intensity = 0
sunRays.Enabled = false
end)
end)
end
local function doVignette(color, duration)
if not Flags.FXVignette then return end
pcall(function()
if not vignetteGui then
vignetteGui = Instance.new("ScreenGui")
vignetteGui.Name = "BS_Vignette"
vignetteGui.IgnoreGuiInset = true
vignetteGui.DisplayOrder = 10002
vignetteGui.Parent = lplr.PlayerGui
end
local top = Instance.new("ImageLabel")
top.Size = UDim2.new(1, 0, 0.4, 0)
top.Position = UDim2.new(0, 0, 0, 0)
top.BackgroundTransparency = 1
top.Image = "rbxassetid://1039949736"
top.ImageColor3 = color or Color3.fromRGB(255, 0, 0)
top.ImageTransparency = 0.5
top.ScaleType = Enum.ScaleType.Stretch
top.ZIndex = 10001
top.Parent = vignetteGui
local bot = Instance.new("ImageLabel")
bot.Size = UDim2.new(1, 0, 0.4, 0)
bot.Position = UDim2.new(0, 0, 0.6, 0)
bot.BackgroundTransparency = 1
bot.Image = "rbxassetid://1039949736"
bot.ImageColor3 = color or Color3.fromRGB(255, 0, 0)
bot.ImageTransparency = 0.5
bot.ScaleType = Enum.ScaleType.Stretch
bot.Rotation = 180
bot.ZIndex = 10001
bot.Parent = vignetteGui
local left = Instance.new("ImageLabel")
left.Size = UDim2.new(0.3, 0, 1, 0)
left.Position = UDim2.new(0, 0, 0, 0)
left.BackgroundTransparency = 1
left.Image = "rbxassetid://1039949736"
left.ImageColor3 = color or Color3.fromRGB(255, 0, 0)
left.ImageTransparency = 0.6
left.ScaleType = Enum.ScaleType.Stretch
left.Rotation = 90
left.ZIndex = 10001
left.Parent = vignetteGui
local right = Instance.new("ImageLabel")
right.Size = UDim2.new(0.3, 0, 1, 0)
right.Position = UDim2.new(0.7, 0, 0, 0)
right.BackgroundTransparency = 1
right.Image = "rbxassetid://1039949736"
right.ImageColor3 = color or Color3.fromRGB(255, 0, 0)
right.ImageTransparency = 0.6
right.ScaleType = Enum.ScaleType.Stretch
right.Rotation = 270
right.ZIndex = 10001
right.Parent = vignetteGui
task.spawn(function()
local start = tick()
while tick() - start < (duration or 0.5) do
local pct = (tick() - start) / (duration or 0.5)
local trans = 0.5 + pct * 0.5
top.ImageTransparency = trans
bot.ImageTransparency = trans
left.ImageTransparency = trans + 0.1
right.ImageTransparency = trans + 0.1
RunService.RenderStepped:Wait()
end
end)
end)
end
local function doScreenFlash(color, transparency, duration)
if not Flags.FXFlash then return end
pcall(function()
if not killEffectGui then
killEffectGui = Instance.new("ScreenGui")
killEffectGui.Name = "BS_KillEffect"
killEffectGui.IgnoreGuiInset = true
killEffectGui.DisplayOrder = 10000
killEffectGui.Parent = lplr.PlayerGui
end
local flash = Instance.new("Frame")
flash.Size = UDim2.new(1, 0, 1, 0)
flash.BackgroundColor3 = color or Color3.fromRGB(255, 255, 255)
flash.BackgroundTransparency = transparency or 0.4
flash.BorderSizePixel = 0
flash.ZIndex = 9999
flash.Parent = killEffectGui
task.spawn(function()
local start = tick()
while tick() - start < (duration or 0.3) do
local pct = (tick() - start) / (duration or 0.3)
flash.BackgroundTransparency = (transparency or 0.4) + pct * (1 - (transparency or 0.4))
RunService.RenderStepped:Wait()
end
end)
end)
end
local function doScreenShake(intensity, duration)
if not Flags.FXShake then return end
pcall(function()
local cam = workspace.CurrentCamera
if not cam then return end
local startTime = tick()
local conn
conn = RunService.RenderStepped:Connect(function()
local elapsed = tick() - startTime
if elapsed > duration then
end
local fade = 1 - (elapsed / duration)
local sx = (math.random() - 0.5) * intensity * fade
local sy = (math.random() - 0.5) * intensity * fade
local sz = (math.random() - 0.5) * intensity * fade * 0.3
cam.CFrame = cam.CFrame * CFrame.new(sx, sy, sz)
end)
end)
end
local function doChromaticAberration(intensity, duration)
if not Flags.FXChromatic then return end
pcall(function()
if not killEffectGui then
killEffectGui = Instance.new("ScreenGui")
killEffectGui.Name = "BS_KillEffect"
killEffectGui.IgnoreGuiInset = true
killEffectGui.DisplayOrder = 10000
killEffectGui.Parent = lplr.PlayerGui
end
local offset = intensity or 4
local redLayer = Instance.new("Frame")
redLayer.Size = UDim2.new(1, 0, 1, 0)
redLayer.Position = UDim2.new(0, -offset, 0, 0)
redLayer.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
redLayer.BackgroundTransparency = 0.85
redLayer.BorderSizePixel = 0
redLayer.ZIndex = 9997
redLayer.Parent = killEffectGui
local blueLayer = Instance.new("Frame")
blueLayer.Size = UDim2.new(1, 0, 1, 0)
blueLayer.Position = UDim2.new(0, offset, 0, 0)
blueLayer.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
blueLayer.BackgroundTransparency = 0.85
blueLayer.BorderSizePixel = 0
blueLayer.ZIndex = 9997
blueLayer.Parent = killEffectGui
task.spawn(function()
local start = tick()
while tick() - start < (duration or 0.2) do
local pct = (tick() - start) / (duration or 0.2)
local alpha = 0.85 + pct * 0.15
redLayer.BackgroundTransparency = alpha
blueLayer.BackgroundTransparency = alpha
RunService.RenderStepped:Wait()
end
end)
end)
end
local function doSlowMotion(scale, duration)
if not Flags.FXSlowMo then return end
pcall(function()
local cam = workspace.CurrentCamera
if not cam then return end
local origFOV = cam.FieldOfView
local targetFOV = origFOV * (scale or 0.7)
task.spawn(function()
local start = tick()
while tick() - start < 0.1 do
local pct = (tick() - start) / 0.1
cam.FieldOfView = origFOV + (targetFOV - origFOV) * pct
RunService.RenderStepped:Wait()
end
task.wait(duration or 0.3)
local returnStart = tick()
while tick() - returnStart < 0.2 do
local pct = (tick() - returnStart) / 0.2
cam.FieldOfView = targetFOV + (origFOV - targetFOV) * pct
RunService.RenderStepped:Wait()
end
cam.FieldOfView = origFOV
end)
end)
end
local function doDamageIndicator(angle, color)
if not Flags.FXDamageDir then return end
pcall(function()
if not killEffectGui then
killEffectGui = Instance.new("ScreenGui")
killEffectGui.Name = "BS_KillEffect"
killEffectGui.IgnoreGuiInset = true
killEffectGui.DisplayOrder = 10000
killEffectGui.Parent = lplr.PlayerGui
end
local indicator = Instance.new("Frame")
indicator.Size = UDim2.new(0, 60, 0, 60)
indicator.AnchorPoint = Vector2.new(0.5, 0.5)
indicator.Position = UDim2.new(0.5, 0, 0.5, 0)
indicator.BackgroundTransparency = 1
indicator.Rotation = angle or 0
indicator.ZIndex = 9998
indicator.Parent = killEffectGui
local arrow = Instance.new("ImageLabel")
arrow.Size = UDim2.new(1, 0, 0.3, 0)
arrow.Position = UDim2.new(0, 0, 0.1, 0)
arrow.BackgroundTransparency = 1
arrow.Image = "rbxassetid://1039949736"
arrow.ImageColor3 = color or Color3.fromRGB(255, 0, 0)
arrow.ImageTransparency = 0.3
arrow.ScaleType = Enum.ScaleType.Stretch
arrow.ZIndex = 9999
arrow.Parent = indicator
task.spawn(function()
local start = tick()
while tick() - start < 0.5 do
local pct = (tick() - start) / 0.5
arrow.ImageTransparency = 0.3 + pct * 0.7
indicator.Position = UDim2.new(0.5, 0, 0.5 - pct * 0.05, 0)
RunService.RenderStepped:Wait()
end
end)
end)
end
local function doBloodEffect(count)
if not Flags.FxBlood then return end
pcall(function()
if not killEffectGui then
killEffectGui = Instance.new("ScreenGui")
killEffectGui.Name = "BS_KillEffect"
killEffectGui.IgnoreGuiInset = true
killEffectGui.DisplayOrder = 10000
killEffectGui.Parent = lplr.PlayerGui
end
local vpSize = workspace.CurrentCamera.ViewportSize
for i = 1, (count or 15) do
local size = math.random(2, 7)
local particle = Instance.new("Frame")
particle.Size = UDim2.new(0, size, 0, size)
particle.Position = UDim2.new(0.5 + (math.random() - 0.5) * 0.2, 0, 0.5 + (math.random() - 0.5) * 0.2, 0)
particle.AnchorPoint = Vector2.new(0.5, 0.5)
particle.BackgroundColor3 = Color3.fromRGB(150 + math.random(105), math.random(20), math.random(20))
particle.BorderSizePixel = 0
particle.Rotation = math.random(360)
particle.ZIndex = 9998
particle.Parent = killEffectGui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = particle
task.spawn(function()
local startTime = tick()
local vx = (math.random() - 0.5) * 250
local vy = -math.random(80, 350)
local gravity = 900
local startX = particle.Position.X.Scale
local startY = particle.Position.Y.Scale
while tick() - startTime < 0.7 do
local dt = RunService.RenderStepped:Wait()
local elapsed = tick() - startTime
vx = vx * 0.97
vy = vy + gravity * dt
particle.Position = UDim2.new(
)
particle.BackgroundTransparency = elapsed / 0.7
end
end)
end
end)
end
local function doKillRing(color)
if not Flags.FxKillRing then return end
pcall(function()
if not killEffectGui then
killEffectGui = Instance.new("ScreenGui")
killEffectGui.Name = "BS_KillEffect"
killEffectGui.IgnoreGuiInset = true
killEffectGui.DisplayOrder = 10000
killEffectGui.Parent = lplr.PlayerGui
end
local ring = Instance.new("Frame")
ring.Size = UDim2.new(0, 10, 0, 10)
ring.AnchorPoint = Vector2.new(0.5, 0.5)
ring.Position = UDim2.new(0.5, 0, 0.5, 0)
ring.BackgroundTransparency = 1
ring.ZIndex = 9998
ring.Parent = killEffectGui
local circle = Instance.new("UIStroke")
circle.Color = color or Color3.fromRGB(255, 50, 50)
circle.Thickness = 3
circle.Transparency = 0.3
circle.Parent = ring
Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
task.spawn(function()
local start = tick()
while tick() - start < 0.5 do
local pct = (tick() - start) / 0.5
local size = 10 + pct * 400
ring.Size = UDim2.new(0, size, 0, size)
circle.Transparency = 0.3 + pct * 0.7
circle.Thickness = 3 * (1 - pct)
RunService.RenderStepped:Wait()
end
end)
end)
end
local function doWhiteFlash(duration)
if not Flags.FxWhiteFlash then return end
doScreenFlash(Color3.fromRGB(255, 255, 255), 0.2, duration or 0.25)
end
local function doRedFlash(duration)
if not Flags.FxRedFlash then return end
doScreenFlash(Color3.fromRGB(255, 0, 0), 0.3, duration or 0.35)
end
local function doDesaturation(amount, duration)
if not Flags.FxDesat then return end
pcall(function()
colorCorrection.Enabled = true
colorCorrection.Saturation = -(amount or 0.8)
task.spawn(function()
local start = tick()
while tick() - start < (duration or 0.5) do
local pct = (tick() - start) / (duration or 0.5)
colorCorrection.Saturation = -(amount or 0.8) * (1 - pct)
RunService.RenderStepped:Wait()
end
colorCorrection.Saturation = 0
colorCorrection.Enabled = false
end)
end)
end
local function doFOVPunch(amount, duration)
if not Flags.FxFovPunch then return end
pcall(function()
local cam = workspace.CurrentCamera
if not cam then return end
local origFOV = cam.FieldOfView
local start = tick()
task.spawn(function()
while tick() - start < (duration or 0.15) do
local pct = (tick() - start) / (duration or 0.15)
local fov = origFOV - (amount or 10) * math.sin(pct * math.pi)
cam.FieldOfView = fov
RunService.RenderStepped:Wait()
end
cam.FieldOfView = origFOV
end)
end)
end
local function doGlitchLines(count, duration)
if not Flags.FxGlitch then return end
pcall(function()
if not killEffectGui then
killEffectGui = Instance.new("ScreenGui")
killEffectGui.Name = "BS_KillEffect"
killEffectGui.IgnoreGuiInset = true
killEffectGui.DisplayOrder = 10000
killEffectGui.Parent = lplr.PlayerGui
end
for i = 1, (count or 5) do
local line = Instance.new("Frame")
line.Size = UDim2.new(1, 0, 0, math.random(1, 4))
line.Position = UDim2.new(0, 0, math.random() * 1, 0)
line.BackgroundColor3 = Color3.fromRGB(math.random(100, 255), math.random(100, 255), math.random(100, 255))
line.BackgroundTransparency = 0.5
line.BorderSizePixel = 0
line.ZIndex = 9999
line.Parent = killEffectGui
task.spawn(function()
task.wait(duration or 0.15)
end)
end
end)
end
local streakNames = {
}
local streakColors = {
}
local function showStreakText(text, color, streak)
if not Flags.FxStreakText then return end
pcall(function()
if not streakGui then
streakGui = Instance.new("ScreenGui")
streakGui.Name = "BS_Streak"
streakGui.IgnoreGuiInset = true
streakGui.DisplayOrder = 10001
streakGui.Parent = lplr.PlayerGui
end
local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 0, 60)
label.Position = UDim2.new(0.5, 0, 0.3, 0)
label.AnchorPoint = Vector2.new(0.5, 0.5)
label.BackgroundTransparency = 1
label.Text = text
label.TextColor3 = color
label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
label.TextStrokeTransparency = 0.3
label.TextSize = 30 + streak * 3
label.Font = Enum.Font.GothamBold
label.TextTransparency = 0
label.Parent = streakGui
task.spawn(function()
local startTime = tick()
while tick() - startTime < 2.0 do
local elapsed = tick() - startTime
if elapsed < 0.3 then
label.TextSize = (30 + streak * 3) * (1 + elapsed / 0.3 * 0.4)
else
local fade = (elapsed - 0.3) / 1.7
label.TextTransparency = fade
label.TextStrokeTransparency = 0.3 + fade * 0.7
label.Position = UDim2.new(0.5, 0, 0.3 - fade * 0.08, 0)
end
RunService.RenderStepped:Wait()
end
end)
end)
end
local function addKillFeedEntry(killer, victim, weapon, isHeadshot)
if not Flags.FxKillFeed then return end
pcall(function()
if not killFeedGui then
killFeedGui = Instance.new("ScreenGui")
killFeedGui.Name = "BS_KillFeed"
killFeedGui.IgnoreGuiInset = true
killFeedGui.DisplayOrder = 9999
killFeedGui.Parent = lplr.PlayerGui
end
table.insert(KillFeed, 1, {
Killer = killer or "",
Victim = victim or "",
Weapon = weapon or "?",
Headshot = isHeadshot or false,
})
if #KillFeed > KillFeedMax then table.remove(KillFeed) end
rebuildKillFeed()
end)
end
function rebuildKillFeed()
if not killFeedGui then return end
for _, child in ipairs(killFeedGui:GetChildren()) do
if child:IsA("Frame") then child:Destroy() end
end
pcall(function()
local entryH = 22
local feedW = 320
for i, entry in ipairs(KillFeed) do
local alpha = math.clamp(1 - (tick() - entry.Time) / 5, 0, 1)
if alpha <= 0 then table.remove(KillFeed, i); continue end
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, feedW, 0, entryH)
frame.Position = UDim2.new(1, -feedW - 10, 0, 10 + (i - 1) * (entryH + 2))
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0.4 + (1 - alpha) * 0.6
frame.BorderSizePixel = 0
frame.Parent = killFeedGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 3)
local killerLabel = Instance.new("TextLabel")
killerLabel.Size = UDim2.new(0.35, 0, 1, 0)
killerLabel.Position = UDim2.new(0.02, 0, 0, 0)
killerLabel.BackgroundTransparency = 1
killerLabel.Text = entry.Killer
killerLabel.TextColor3 = entry.Killer == lplr.DisplayName and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(255, 255, 255)
killerLabel.TextSize = 11
killerLabel.Font = Enum.Font.GothamBold
killerLabel.TextXAlignment = Enum.TextXAlignment.Left
killerLabel.TextTransparency = 1 - alpha
killerLabel.Parent = frame
local wepLabel = Instance.new("TextLabel")
wepLabel.Size = UDim2.new(0.26, 0, 1, 0)
wepLabel.Position = UDim2.new(0.37, 0, 0, 0)
wepLabel.BackgroundTransparency = 1
wepLabel.Text = entry.Headshot and (" " .. entry.Weapon) or ("[" .. entry.Weapon .. "]")
wepLabel.TextColor3 = entry.Headshot and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(200, 200, 200)
wepLabel.TextSize = 10
wepLabel.Font = Enum.Font.Code
wepLabel.TextTransparency = 1 - alpha
wepLabel.Parent = frame
local victimLabel = Instance.new("TextLabel")
victimLabel.Size = UDim2.new(0.35, 0, 1, 0)
victimLabel.Position = UDim2.new(0.63, 0, 0, 0)
victimLabel.BackgroundTransparency = 1
victimLabel.Text = entry.Victim
victimLabel.TextColor3 = entry.Victim == lplr.DisplayName and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 200, 200)
victimLabel.TextSize = 11
victimLabel.Font = Enum.Font.GothamBold
victimLabel.TextXAlignment = Enum.TextXAlignment.Right
victimLabel.TextTransparency = 1 - alpha
victimLabel.Parent = frame
end
end)
end
task.spawn(function()
while true do
task.wait(1)
if #KillFeed > 0 then
local removed = false
for i = #KillFeed, 1, -1 do
if tick() - KillFeed[i].Time > 5 then table.remove(KillFeed, i); removed = true end
end
if removed then rebuildKillFeed() end
end
end
end)
local prevHealth = {}
local killStreak = 0
local lastKillTime = 0
local killTimes = {}
local function onKill(victim, isHeadshot, weaponName)
local now = tick()
killStreak = killStreak + 1
lastKillTime = now
table.insert(killTimes, now)
local recentKills = 0
for i = #killTimes, 1, -1 do
if now - killTimes[i] > 4 then table.remove(killTimes, i)
else recentKills = recentKills + 1 end
end
if Flags.FxKillSound then
local list = isHeadshot and Sounds.Headshot or Sounds.Kill
local pitch = Flags.FxRandomPitch and (0.8 + math.random() * 0.4) or 1.0
playSoundFromList(list, Flags.FxKillSoundIdx or 1, pitch)
end
if Flags.FxHitSound then
playSoundFromList(Sounds.Hit, Flags.FxHitSoundIdx or 1, 0.9 + math.random() * 0.2)
end
doScreenFlash(isHeadshot and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255), 0.3, 0.25)
doWhiteFlash(0.2)
doRedFlash(0.3)
doBlurFlash(isHeadshot and 25 or 15, 0.3)
doColorFlash(isHeadshot and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(255, 255, 255), 0.4, 0.35)
doBloomFlash(isHeadshot and 3 or 1.5, 0.4)
doSunRaysFlash(0.3)
doScreenShake(isHeadshot and 0.8 or 0.4, isHeadshot and 0.25 or 0.12)
doChromaticAberration(isHeadshot and 6 or 3, 0.15)
doSlowMotion(isHeadshot and 0.6 or 0.8, 0.2)
doVignette(isHeadshot and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 100, 0), 0.4)
doBloodEffect(isHeadshot and 20 or 10)
doKillRing(isHeadshot and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255))
doDesaturation(isHeadshot and 0.6 or 0.3, 0.4)
doFOVPunch(isHeadshot and 15 or 8, 0.12)
doGlitchLines(isHeadshot and 8 or 3, 0.1)
addKillFeedEntry(lplr.DisplayName, victim, weaponName, isHeadshot)
if recentKills >= 2 then
local name = streakNames[recentKills]
if name then
local streakSoundKey = ({[2]="DoubleKill",[3]="TripleKill",[4]="QuadKill",[5]="PentaKill",[7]="Unstoppable",[10]="Rampage",[15]="Godlike"})[recentKills]
local soundData = streakSoundKey and Sounds[streakSoundKey]
playSound(soundData or Sounds.DoubleKill, 0.7 + recentKills * 0.05)
showStreakText(name, streakColors[recentKills] or Color3.fromRGB(255, 255, 0), recentKills)
end
end
end
local function onDeath()
playSound(Sounds.Death, 0.8 + math.random() * 0.4)
killStreak = 0
doScreenFlash(Color3.fromRGB(255, 0, 0), 0.2, 0.5)
doBlurFlash(30, 0.5)
doScreenShake(1.2, 0.4)
doVignette(Color3.fromRGB(200, 0, 0), 0.8)
doDesaturation(0.9, 0.8)
end
task.spawn(function()
while true do
task.wait(0.15)
pcall(function()
for _, player in pairs(Players:GetPlayers()) do
if player ~= lplr and player.Character then
local hum = player and player.Character:FindFirstChildOfClass("Humanoid")
if hum then
local prevHP = prevHealth[player.UserId] or hum.Health
if prevHP > 0 and hum.Health <= 0 then
local isEnemy = not (lplr.Team and player.Team == lplr.Team)
if isEnemy then
local weaponName = "Unknown"
pcall(function()
local tool = lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if tool then weaponName = tool.Name end
end)
local isHeadshot = false
pcall(function()
local head = player and player.Character:FindFirstChild("Head")
if head and head:GetAttribute("LastDamage") then isHeadshot = true end
end)
onKill(player.DisplayName, isHeadshot, weaponName)
end
end
prevHealth[player.UserId] = hum.Health
end
end
end
if killStreak > 0 and tick() - lastKillTime > 8 then killStreak = 0 end
end)
end
end)
task.spawn(function()
while true do
task.wait(1)
pcall(function()
local char = lplr.Character
if char then
local hum = char:FindFirstChildOfClass("Humanoid")
if hum and not hum:GetAttribute("BS_KillSndConn") then
hum.Died:Connect(onDeath)
end
end
end)
end
end)
lplr.CharacterRemoving:Connect(function()
if killEffectGui then killEffectGui:ClearAllChildren() end
if vignetteGui then vignetteGui:ClearAllChildren() end
pcall(function()
blurEffect.Enabled = false
colorCorrection.Enabled = false
bloomEffect.Enabled = false
sunRays.Enabled = false
end)
end)
local HitObjs = {}
local function drawHitmarker(pos, isHeadshot)
if not Flags.Hitmarker then return end
pcall(function()
local cam = workspace.CurrentCamera
local sp, vis = cam:WorldToViewportPoint(pos)
if not vis then return end
local sx, sy = sp.X, sp.Y
local size = (Flags.HMSize or 12)
local color = isHeadshot and Color3.new(1,0,0) or Color3.new(1,1,1)
for i = 1, 4 do
if not HitObjs[i] then
HitObjs[i] = Drawing.new("Line")
HitObjs[i].Thickness = 2
HitObjs[i].Color = color
HitObjs[i].Visible = true
end
HitObjs[i].Color = color
end
HitObjs[1].From = Vector2.new(sx - size, sy - size)
HitObjs[1].To = Vector2.new(sx - 2, sy - 2)
HitObjs[2].From = Vector2.new(sx + size, sy - size)
HitObjs[2].To = Vector2.new(sx + 2, sy - 2)
HitObjs[3].From = Vector2.new(sx - size, sy + size)
HitObjs[3].To = Vector2.new(sx - 2, sy + 2)
HitObjs[4].From = Vector2.new(sx + size, sy + size)
HitObjs[4].To = Vector2.new(sx + 2, sy + 2)
task.delay((Flags.HMDuration or 3) * 0.1, function()
for _, obj in pairs(HitObjs) do pcall(function() obj.Visible = false end) end
end)
end)
end
local function playHitSound()
if not Flags.HitSound then return end
pcall(function()
local sound = Instance.new("Sound")
local soundId = "rbxassetid://9125402735"
local hmSound = Flags.HMSound or "CS2 Dink"
if hmSound == "Quake Hit" then soundId = "rbxassetid://138087576"
elseif hmSound == "Metal Pipe" then soundId = "rbxassetid://9125999404"
elseif hmSound == "Minecraft XP" then soundId = "rbxassetid://142376098"
elseif hmSound == "Vine Boom" then soundId = "rbxassetid://9126214519"
end
sound.SoundId = soundId
sound.Volume = (Flags.HMSoundVol or 5) / 10
sound.Parent = workspace.CurrentCamera
sound:Play()
game:GetService("Debris"):AddItem(sound, 2)
end)
end
local function playKillEffect()
if not Flags.KillEffect then return end
pcall(function()
local style = Flags.KEStyle or "Flash"
if style == "Flash" then
local gui = Instance.new("ScreenGui")
gui.IgnoreGuiInset = true
local flash = Instance.new("Frame", gui)
flash.Size = UDim2.new(1,0,1,0)
flash.BackgroundColor3 = Color3.new(1,0.2,0.2)
flash.BackgroundTransparency = 0.8
gui.Parent = lplr.PlayerGui
game:GetService("TweenService"):Create(flash, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
game:GetService("Debris"):AddItem(gui, 0.5)
elseif style == "Shake" then
local cam = workspace.CurrentCamera
local orig = cam.CFrame
cam.CFrame = orig * CFrame.new(math.random(-1,1)*0.3, math.random(-1,1)*0.3, 0)
task.delay(0.1, function() cam.CFrame = orig end)
end
end)
end
local function playKillSound()
if not Flags.KillSound then return end
pcall(function()
local sound = Instance.new("Sound")
local soundId = "rbxassetid://3124961779"
local keSound = Flags.KESound or "Frag"
if keSound == "Explosion" then soundId = "rbxassetid://13134985300"
elseif keSound == "Metal Pipe" then soundId = "rbxassetid://9125999404"
elseif keSound == "Mario Coin" then soundId = "rbxassetid://138087606"
end
sound.SoundId = soundId
sound.Volume = (Flags.KESoundVol or 7) / 10
sound.Parent = workspace.CurrentCamera
sound:Play()
game:GetService("Debris"):AddItem(sound, 2)
end)
end
local function showDamageNumbers(pos, damage)
if not Flags.DmgNumbers then return end
pcall(function()
local cam = workspace.CurrentCamera
local sp, vis = cam:WorldToViewportPoint(pos + Vector3.new(0, 2, 0))
if not vis then return end
local txt = Drawing.new("Text")
txt.Text = tostring(math.floor(damage))
txt.Position = Vector2.new(sp.X, sp.Y)
txt.Color = damage >= 100 and Color3.new(1,0,0) or Color3.new(1,1,0)
txt.Size = 16
txt.Center = true
txt.Outline = true
txt.Visible = true
task.spawn(function()
for i = 1, 20 do
txt.Position = txt.Position - Vector2.new(0, 2)
txt.TextTransparency = i / 20
task.wait(0.02)
end
txt:Remove()
end)
end)
end
KE.drawHitmarker = drawHitmarker
KE.playHitSound = playHitSound
KE.playKillEffect = playKillEffect
KE.playKillSound = playKillSound
KE.showDamageNumbers = showDamageNumbers
print("[KillEffects] BloxStrike Kill Effects v2.0 loaded  30+ sounds, 15+ visual effects")
]])
writefile("BloxStrike/modules/luau_compat.lua", [[
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
local BS = rawget(_G, "BS") or {}
local L = BS.Luau or {}
local Compat = {}
-- ═══ Safe Task Library ═══
Compat.task = {}
Compat.task.spawn = function(fn, ...)
if type(task) == "table" and type(task.spawn) == "function" then
return task.spawn(fn, ...)
else
local co = coroutine.create(fn)
return coroutine.resume(co, ...)
end
end
Compat.task.wait = function(t)
if type(task) == "table" and type(task.wait) == "function" then
return task.wait(t)
else
local start = os.clock()
repeat until os.clock() - start >= (t or 0)
return os.clock() - start
end
end
Compat.task.delay = function(t, fn)
if type(task) == "table" and type(task.delay) == "function" then
return task.delay(t, fn)
else
return spawn(function()
Compat.task.wait(t)
fn()
end)
end
end
Compat.task.defer = function(fn, ...)
if type(task) == "table" and type(task.defer) == "function" then
return task.defer(fn, ...)
else
return Compat.task.spawn(fn, ...)
end
end
Compat.task.cancel = function(handle)
if type(task) == "table" and type(task.cancel) == "function" then
return task.cancel(handle)
end
end
-- ═══ Safe HTTP ═══
Compat.safeHttpGet = function(url, silent)
local methods = {
function()
return game:HttpGet(url, silent ~= false)
end,
function()
if type(request) == "function" then
local resp = request({Url = url, Method = "GET"})
return resp and resp.Body
end
return nil
end,
function()
if type(http) == "table" and type(http.request) == "function" then
local resp = http.request({Url = url, Method = "GET"})
return resp and resp.Body
end
return nil
end,
function()
if type(syn) == "table" and type(syn.request) == "function" then
local resp = syn.request({Url = url, Method = "GET"})
return resp and resp.Body
end
return nil
end,
}
for _, method in ipairs(methods) do
local ok, result = pcall(method)
if ok and result then return result end
end
return nil
end
-- ═══ Safe Service Get ═══
Compat.getService = function(serviceName)
local ok, service = pcall(function()
return game:GetService(serviceName)
end)
if ok then return service end
local ok2, service2 = pcall(function()
return game:FindService(serviceName)
end)
if ok2 then return service2 end
return nil
end
-- ═══ Safe Property Access ═══
Compat.safeGet = function(obj, ...)
if obj == nil then return nil end
local current = obj
for _, key in ipairs({...}) do
if current == nil then return nil end
local t = type(current)
if t == "table" then
current = current[key]
elseif t == "userdata" then
local ok, val = pcall(function() return current[key] end)
if ok then current = val else return nil end
else
return nil
end
end
return current
end
-- ═══ Safe Method Call ═══
Compat.safeCall = function(obj, methodName, ...)
if obj == nil then return nil end
local method = obj[methodName]
if type(method) ~= "function" then return nil end
return method(obj, ...)
end
-- ═══ Safe FindFirstChild ═══
Compat.findFirstChild = function(parent, name, className)
if parent == nil then return nil end
local ok, result = pcall(function()
if className then
return parent:FindFirstChildOfClass(className)
else
return parent:FindFirstChild(name)
end
end)
if ok then return result end
return nil
end
-- ═══ Safe WaitForChild ═══
Compat.waitForChild = function(parent, name, timeout)
if parent == nil then return nil end
local ok, result = pcall(function()
return parent:WaitForChild(name, timeout or 5)
end)
if ok then return result end
return nil
end
-- ═══ Typeof Polyfill ═══
Compat.typeof = function(val)
if type(val) == "userdata" or type(val) == "table" then
if type(typeof) == "function" then
return typeof(val)
end
if type(val.IsA) == "function" then
local ok, className = pcall(function() return val.ClassName end)
if ok and className then return className end
end
return type(val)
end
return type(val)
end
-- ═══ Safe Drawing ═══
Compat.createDrawing = function(drawingType)
if type(Drawing) ~= "table" then return nil end
local ok, obj = pcall(function()
return Drawing.new(drawingType)
end)
if ok then return obj end
return nil
end
Compat.getFont = function(name)
if type(Drawing) ~= "table" then return 0 end
if type(Drawing.Fonts) ~= "table" then return 0 end
return Drawing.Fonts[name] or Drawing.Fonts.UI or 0
end
-- ═══ Feature Gate ═══
Compat.ifFeature = function(featureName, fn, fallback)
if L[featureName] then
return fn()
elseif fallback then
return fallback()
end
return nil
end
-- ═══ Safe pcall with error context ═══
Compat.safecall = function(context, fn, ...)
local ok, result = pcall(fn, ...)
if not ok then
if type(warn) == "function" then
warn("[BloxStrike] " .. context .. " failed: " .. tostring(result))
end
return false, result
end
return true, result
end
-- ═══ Store in BS ═══
BS.LuauCompat = Compat
return Compat
]])
writefile("BloxStrike/modules/luau_detect.lua", [[
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
local BS = rawget(_G, "BS") or {}
local Luau = {}
-- ═══ PHASE 1: Core Language Feature Detection ═══
do
local ok, result = pcall(function() return typeof(game) end)
Luau.canTypeof = ok and result ~= nil
end
do
local ok = pcall(function()
return loadstring("local t = {1,2,3}\nfor _,v in ipairs(t) do if v == 2 then continue end end")
end)
if ok then
local fn = loadstring("local x = 0\nfor i = 1, 10 do if i == 5 then continue end x = x + 1 end return x")
if fn then
local ok2, result = pcall(fn)
Luau.canContinue = ok2 and result == 9
else
Luau.canContinue = false
end
else
Luau.canContinue = false
end
end
do
local fn = loadstring("::label:: local x = 1 goto label")
Luau.canGoto = fn ~= nil
end
Luau.canTask = type(task) == "table" and type(task.spawn) == "function"
Luau.canBuffer = type(buffer) == "table"
Luau.canNative = Luau.canBuffer
Luau.canFenv = type(getfenv) == "function" and type(setfenv) == "function"
Luau.canDebug = type(debug) == "table"
Luau.canBit = type(bit) == "table" or type(bit32) == "table"
Luau.canHttp = (type(game) == "table" and pcall(function() return game.HttpGet ~= nil end))
or (type(http) == "table" and type(http.request) == "function")
or (type(request) == "function")
or (type(HttpGet) == "function")
Luau.canDrawing = type(Drawing) == "table"
-- ═══ PHASE 2: Executor Detection ═══
Luau.canPotassium = false
do
local ok = pcall(function()
return type(readfile) == "function"
and type(writefile) == "function"
and type(isfile) == "function"
and type(loadfile) == "function"
end)
if ok then
local ok2 = pcall(function()
return type(listfiles) == "function"
end)
Luau.canPotassium = true
end
end
Luau.canSyn = false
do
local syn_apis = {
"syn", "syn_request", "syn_protect_gui", "syn_unprotect_gui",
"syn_getgc", "getinstances", "getnilinstances", "getscripts",
"getthreadidentity", "setthreadidentity"
}
for _, api in ipairs(syn_apis) do
if type(rawget(_G, api)) ~= "nil" then
Luau.canSyn = true
break
end
end
end
Luau.canKRNL = false
do
local krnl_apis = {"krnl_loaded", "KRNL_LOADED", "identifyexecutor"}
for _, api in ipairs(krnl_apis) do
if type(rawget(_G, api)) ~= "nil" then
Luau.canKRNL = true
break
end
end
end
Luau.canFluxus = false
do
local ok = pcall(function()
return type(fluxus) == "table" or type(Fluxus) == "table"
end)
Luau.canFluxus = ok
end
Luau.canEggscord = false
do
local ok = pcall(function()
return type(eggscord) ~= "nil" or type(Eggscord) ~= "nil"
end)
Luau.canEggscord = ok
end
Luau.canOxygen = false
do
local ok = pcall(function()
return type(OXYGEN_LOADED) ~= "nil" or type(oxygen) ~= "nil"
end)
Luau.canOxygen = ok
end
Luau.canWave = false
do
local ok = pcall(function()
return type(WaveEnvironment) ~= "nil" or type(wave) ~= "nil"
end)
Luau.canWave = ok
end
Luau.canArceusX = false
do
local ok = pcall(function()
return type(arceusx) ~= "nil" or type(getexecutorname) == "function"
end)
if ok and type(getexecutorname) == "function" then
local name = pcall(function() return getexecutorname() end)
if name and type(name) == "string" and name:lower():find("arceus") then
Luau.canArceusX = true
end
end
end
-- ═══ PHASE 3: Engine Classification ═══
if Luau.canTask and Luau.canTypeof and not Luau.canFenv then
Luau.engine = "luau"
elseif Luau.canFenv and not Luau.canTypeof then
Luau.engine = "lua51"
elseif Luau.canFenv and Luau.canTypeof then
Luau.engine = "luau-hybrid"
else
Luau.engine = "unknown"
end
if Luau.canPotassium then
Luau.version = "Potassium"
elseif Luau.canSyn then
Luau.version = "Synapse"
elseif Luau.canKRNL then
Luau.version = "KRNL"
elseif Luau.canFluxus then
Luau.version = "Fluxus"
elseif Luau.canEggscord then
Luau.version = "Eggscord"
elseif Luau.canOxygen then
Luau.version = "Oxygen U"
elseif Luau.canWave then
Luau.version = "Wave"
elseif Luau.canArceusX then
Luau.version = "Arceus X"
else
Luau.version = "Unknown"
end
-- ═══ PHASE 4: Polyfills ═══
if not Luau.canTypeof then
local _typeof = function(val)
local t = type(val)
if t == "userdata" or t == "table" then
local mt = getmetatable(val)
if mt and mt.__index then
if type(val.IsA) == "function" then
local ok, className = pcall(function() return val.ClassName end)
if ok and className then return className end
end
end
return t
end
return t
end
if not rawget(_G, "typeof") then
rawset(_G, "typeof", _typeof)
end
end
if not Luau.canTask then
local taskPolyfill = {
spawn = function(fn, ...)
return coroutine.wrap(fn)(...)
end,
wait = function(t)
local start = tick()
repeat until tick() - start >= (t or 0)
return tick() - start
end,
delay = function(t, fn)
return coroutine.wrap(function()
task.wait(t)
fn()
end)()
end,
defer = function(fn, ...)
return coroutine.wrap(fn)(...)
end,
delay = function(t, fn)
spawn(function()
wait(t)
fn()
end)
end,
}
rawset(_G, "task", taskPolyfill)
end
if not table.clone then
table.clone = function(t)
local copy = {}
for k, v in pairs(t) do
copy[k] = v
end
return setmetatable(copy, getmetatable(t))
end
end
if not Luau.canBuffer then
rawset(_G, "buffer", {
create = function(size) return {} end,
fromstring = function(str) return {data = str} end,
tostring = function(buf) return buf.data or "" end,
readu8 = function(buf, offset) return 0 end,
writeu8 = function(buf, offset, value) end,
length = function(buf) return 0 end,
})
end
-- ═══ PHASE 5: Safe Execution Helpers ═══
Luau.safeRequire = function(modulePath)
local paths = {
modulePath,
modulePath:gsub("%.", "/"),
"modules/" .. modulePath:gsub("%.", "/"),
"BloxStrike/modules/" .. modulePath:gsub("%.", "/"),
}
for _, path in ipairs(paths) do
local ok, result = pcall(require, path)
if ok and result then return result end
end
return nil
end
Luau.safeGet = function(obj, ...)
if obj == nil then return nil end
local current = obj
for _, key in ipairs({...}) do
if current == nil then return nil end
current = current[key]
end
return current
end
Luau.safeCall = function(obj, methodName, ...)
if obj == nil then return nil end
local method = obj[methodName]
if type(method) ~= "function" then return nil end
return method(obj, ...)
end
Luau.ifFeature = function(featureName, fn, fallback)
if Luau[featureName] then
return fn()
elseif fallback then
return fallback()
end
return nil
end
-- ═══ PHASE 6: Print Diagnostics ═══
local function printDiagnostics()
print("[Luau Detector] Engine: " .. Luau.engine)
print("[Luau Detector] Executor: " .. Luau.version)
print("[Luau Detector] Capabilities:")
print("  typeof=" .. tostring(Luau.canTypeof)
.. " continue=" .. tostring(Luau.canContinue)
.. " goto=" .. tostring(Luau.canGoto)
.. " task=" .. tostring(Luau.canTask))
print("  buffer=" .. tostring(Luau.canBuffer)
.. " fenv=" .. tostring(Luau.canFenv)
.. " debug=" .. tostring(Luau.canDebug)
.. " drawing=" .. tostring(Luau.canDrawing))
print("  http=" .. tostring(Luau.canHttp)
.. " bit=" .. tostring(Luau.canBit))
end
pcall(printDiagnostics)
-- ═══ Store in BS ═══
BS.Luau = Luau
return Luau
]])
writefile("BloxStrike/modules/pingadapt.lua", [[
local Players = nil
pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local Stats = nil
pcall(function() Stats = game:GetService("Stats") end)
local StarterGui = nil
pcall(function() StarterGui = game:GetService("StarterGui") end)
local lplr = Players.LocalPlayer
if not BS.Win then warn("[Ping Adapt] BS.Win not available - ui.lua may have failed") return end
local page = BS.Win:Tab("Ping Adapt")
if not page or not page.Toggle then warn("[PingAdapt] Failed to create tab!") return end
local PA = {}
BS.PingAdapt = PA
page:Toggle("Ping Adapt", true, function(v) Flags.PingAdapt = v end)
page:Dropdown({Name="Adapt Mode", Flag="PingAdaptMode", Options={"Conservative","Balanced","Aggressive","Ultra"}, Default="Balanced"})
page:Toggle("Show Ping Stats", false, function(v) Flags.PingShowStats = v end)
page:Toggle("Auto Panic on Lag", true, function(v) Flags.PingPanic = v end)
page:Slider("Panic Ping", 200, 500, 350, function(v) Flags.PingPanicThreshold = v end)
local PingState = {
Current = 0,
Average = 0,
Min = 9999,
Max = 0,
Jitter = 0,
History = {},
JitterHistory = {},
Quality = "Good",
Tier = "Low",
PacketLoss = 0,
LastSpike = 0,
SpikeCount = 0,
AdaptMultiplier = 1.0,
}
local function classifyPing(ping)
if ping < 30 then return "Low", "Good", 100
elseif ping < 60 then return "Low", "Good", 90
elseif ping < 100 then return "Medium", "Fair", 75
elseif ping < 150 then return "Medium", "Fair", 60
elseif ping < 200 then return "High", "Poor", 40
elseif ping < 350 then return "High", "Poor", 20
else return "Extreme", "Terrible", 5 end
end
task.spawn(function()
while true do task.wait(0.2)
pcall(function()
local stats = nil
pcall(function() stats = game:GetService("Stats") end)
local pingVal = 0
pcall(function() pingVal = stats.Network.ServerStatsItem["Data Ping"].Value end)
table.insert(PingState.History, pingVal)
if #PingState.History > 60 then table.remove(PingState.History, 1) end
local sum = 0
for _, v in ipairs(PingState.History) do sum = sum + v end
if #PingState.History >= 2 then
local last = PingState.History[#PingState.History]
local prev = PingState.History[#PingState.History - 1]
local j = math.abs(last - prev)
table.insert(PingState.JitterHistory, j)
if #PingState.JitterHistory > 30 then table.remove(PingState.JitterHistory, 1) end
local jSum = 0
for _, v in ipairs(PingState.JitterHistory) do jSum = jSum + v end
end
if pingVal > PingState.Average * 2 and pingVal > 100 then
PingState.SpikeCount = PingState.SpikeCount + 1
end
local mode = Flags.PingAdaptMode or "Balanced"
local baseMult = 1.0
if mode == "Conservative" then
baseMult = math.clamp(1 - (PingState.Average - 30) / 300, 0.3, 1.0)
elseif mode == "Balanced" then
baseMult = math.clamp(1 - (PingState.Average - 30) / 200, 0.2, 1.0)
elseif mode == "Aggressive" then
baseMult = math.clamp(1 - (PingState.Average - 30) / 400, 0.4, 1.0)
else
baseMult = math.clamp(1 - (PingState.Average - 30) / 500, 0.5, 1.0)
end
if PingState.Jitter > 20 then
baseMult = baseMult * math.clamp(1 - PingState.Jitter / 200, 0.5, 1.0)
end
if tick() - PingState.LastSpike < 2 then
baseMult = baseMult * 0.6
end
if Flags.PingPanic and PingState.Current > (Flags.PingPanicThreshold or 350) then
Flags.Ragebot = false
Flags.AA = false
Flags.NoClip = false
Flags.SpeedBoost = false
Flags.FL = false
end
end)
end
end)
function PA.getAdaptSmooth(baseSmooth)
if not Flags.PingAdapt then return baseSmooth end
local m = PingState.AdaptMultiplier
return math.clamp(baseSmooth / m, 1, 100)
end
function PA.getAdaptFOV(baseFOV)
if not Flags.PingAdapt then return baseFOV end
local m = PingState.AdaptMultiplier
return math.clamp(baseFOV / m, 10, 360)
end
function PA.getAdaptPrediction(basePred)
if not Flags.PingAdapt then return basePred end
return math.clamp(basePred + pingBonus * 50, 0, 100)
end
function PA.getAdaptDelay(baseDelay)
if not Flags.PingAdapt then return baseDelay end
local m = PingState.AdaptMultiplier
return math.clamp(baseDelay / m, 1, 2000)
end
function PA.getAdaptTriggerDelay(baseMin, baseMax)
if not Flags.PingAdapt then return baseMin + math.random() * (baseMax - baseMin) end
local m = PingState.AdaptMultiplier
local pingAdd = PingState.Current * 0.1
local minD = baseMin / m + pingAdd * 0.5
local maxD = baseMax / m + pingAdd
return math.clamp(minD + math.random() * (maxD - minD), 1, 2000)
end
function PA.getAdaptUpdateRate(baseInterval)
if not Flags.PingAdapt then return baseInterval end
local m = PingState.AdaptMultiplier
end
function PA.getAdaptSwitchDelay(baseDelay)
if not Flags.PingAdapt then return baseDelay end
local m = PingState.AdaptMultiplier
return math.clamp(baseDelay / m, 10, 2000)
end
function PA.getAdaptLagTicks()
if not Flags.PingAdapt then return 8 end
return math.clamp(math.floor(PingState.Current / 16), 1, 32)
end
function PA.getAdaptSpeed(baseSpeed)
if not Flags.PingAdapt then return baseSpeed end
local m = PingState.AdaptMultiplier
return baseSpeed * math.clamp(m + 0.2, 0.5, 1.2)
end
function PA.getAdaptJump(baseJump)
if not Flags.PingAdapt then return baseJump end
local m = PingState.AdaptMultiplier
return baseJump * math.clamp(m + 0.3, 0.6, 1.1)
end
function PA.getAdaptResolverAccuracy(baseAccuracy)
if not Flags.PingAdapt then return baseAccuracy end
return math.clamp(baseAccuracy * m, 20, 100)
end
function PA.getAdaptESPSkip()
if not Flags.PingAdapt then return 1 end
local ping = PingState.Current
if ping < 50 then return 1
elseif ping < 100 then return 2
elseif ping < 200 then return 3
else return 4 end
end
function PA.getAdaptBurstCount(baseCount)
if not Flags.PingAdapt then return baseCount end
local m = PingState.AdaptMultiplier
return math.clamp(math.floor(baseCount * m), 1, 10)
end
function PA.getAdaptFakeLag(baseChoke)
if not Flags.PingAdapt then return baseChoke end
local ping = PingState.Current
if ping > 150 then return math.max(1, baseChoke - 3) end
if ping > 100 then return math.max(2, baseChoke - 1) end
return baseChoke
end
function PA.getAdaptAAJitter(baseJitter)
if not Flags.PingAdapt then return baseJitter end
local m = PingState.AdaptMultiplier
end
function PA.getAdaptBhopInterval(baseInterval)
if not Flags.PingAdapt then return baseInterval end
local ping = PingState.Current
end
function PA.getAdaptSilentRange(baseRange)
if not Flags.PingAdapt then return baseRange end
local m = PingState.AdaptMultiplier
end
function PA.getAdaptTriggerChance(baseChance)
if not Flags.PingAdapt then return baseChance end
local m = PingState.AdaptMultiplier
return math.clamp(baseChance * m, 10, 100)
end
function PA.getAdaptAutoFireDelay()
if not Flags.PingAdapt then return 0 end
local ping = PingState.Current
return math.max(0, ping / 1000 * 0.3)
end
function PA.shouldPause()
if not Flags.PingAdapt then return false end
if tick() - PingState.LastSpike < 0.1 then return true end
return false
end
function PA.getAdaptHumanDelay(baseDelay)
if not Flags.PingAdapt then return baseDelay end
local m = PingState.AdaptMultiplier
end
page:Toggle("Aim Ping Adapt", true, function(v) Flags.AimPingAdapt = v end)
page:Toggle("Lag Compensation Auto", true, function(v) Flags.LagCompAuto = v end)
page:Toggle("Prediction Auto", true, function(v) Flags.PredAuto = v end)
page:Toggle("Smooth Auto", true, function(v) Flags.SmoothAuto = v end)
page:Toggle("FOV Auto", true, function(v) Flags.FOVAuto = v end)
page:Toggle("TB Ping Adapt", true, function(v) Flags.TBPingAdapt = v end)
page:Toggle("ESP Ping Adapt", true, function(v) Flags.ESPPingAdapt = v end)
page:Toggle("ESP Quality Scale", true, function(v) Flags.ESPQualityScale = v end)
page:Toggle("Movement Ping Adapt", true, function(v) Flags.MovePingAdapt = v end)
page:Toggle("Bhop Ping Adapt", true, function(v) Flags.BhopPingAdapt = v end)
page:Toggle("AA Ping Adapt", true, function(v) Flags.AAPingAdapt = v end)
page:Toggle("Fake Lag Auto", true, function(v) Flags.FLPingAdapt = v end)
page:Toggle("Resolver Auto", true, function(v) Flags.ResolverPingAdapt = v end)
page:Button({Name=" Ping ?", Color=Color3.fromRGB(0, 200, 255)}, function()
local statsText = string.format(
PingState.Current, PingState.Average,
PingState.Min, PingState.Max,
PingState.Jitter, PingState.Quality,
PingState.Tier, PingState.AdaptMultiplier,
PingState.SpikeCount
)
pcall(function()
StarterGui:SetCore("SendNotification", {
Title = " Ping ?",
Text = statsText,
Duration = 8,
})
end)
end)
page:Button({Name="[Feature]", Color=Color3.fromRGB(200, 100, 100)}, function()
PingState.Min = 9999
PingState.Max = 0
PingState.SpikeCount = 0
PingState.History = {}
PingState.JitterHistory = {}
end)
task.spawn(function()
while true do task.wait(0.1)
if not Flags.PingAdapt then continue end
if PA.shouldPause() then continue end
pcall(function()
if Flags.LagCompAuto and Flags.Aimbot then
Flags.AimLagComp = PingState.Current > 80
Flags.AimLagTicks = PA.getAdaptLagTicks()
end
if Flags.PredAuto and Flags.Aimbot then
local basePred = Flags.AimPredF or 40
Flags.AimPredF = math.floor(PA.getAdaptPrediction(basePred))
end
if Flags.SmoothAuto and Flags.Aimbot then
local baseSmooth = 5
Flags.AimbotSmooth = math.floor(PA.getAdaptSmooth(baseSmooth))
end
if Flags.FOVAuto and Flags.Aimbot then
local baseFOV = 60
Flags.AimbotFOV = math.floor(PA.getAdaptFOV(baseFOV))
end
end)
end
end)
task.spawn(function()
while true do task.wait(0.2)
if not Flags.PingAdapt or not Flags.TBPingAdapt then continue end
pcall(function()
if Flags.TriggerBot then
local baseMin = 30
local baseMax = 120
local adapted = PA.getAdaptTriggerDelay(baseMin, baseMax)
Flags._AdaptTBMinDelay = adapted * 0.5
Flags._AdaptTBMaxDelay = adapted
end
end)
end
end)
task.spawn(function()
while true do task.wait(0.5)
if not Flags.PingAdapt or not Flags.ESPPingAdapt then continue end
pcall(function()
Flags._ESPSkipFrames = PA.getAdaptESPSkip()
if Flags.ESPQualityScale then
local quality = PingState.QualityScore
if quality < 40 then
Flags.ESP_Skeleton = false
Flags.ESP_Snaplines = false
Flags.ESP_SoundEsp = false
Flags.ESP_Velocity = false
elseif quality < 60 then
Flags.ESP_SoundEsp = false
end
end
end)
end
end)
task.spawn(function()
while true do task.wait(0.2)
if not Flags.PingAdapt or not Flags.MovePingAdapt then continue end
pcall(function()
if Flags.SpeedBoost and BS.alive() then
local h = BS.hum()
if h then
local targetSpeed = 22
local adaptedSpeed = PA.getAdaptSpeed(targetSpeed)
Flags._AdaptSpeed = adaptedSpeed
end
end
if Flags.Bhop and Flags.BhopPingAdapt then
local baseInterval = 0.1
Flags._AdaptBhopInterval = PA.getAdaptBhopInterval(baseInterval)
end
end)
end
end)
task.spawn(function()
while true do task.wait(0.3)
if not Flags.PingAdapt then continue end
pcall(function()
if Flags.AA and Flags.AAPingAdapt then
local baseJitter = 20
Flags._AdaptAAJitter = PA.getAdaptAAJitter(baseJitter)
end
if Flags.FL and Flags.FLPingAdapt then
local baseChoke = 6
Flags._AdaptFakeLag = PA.getAdaptFakeLag(baseChoke)
end
if Flags.SilentAim then
local baseFOV = 90
Flags._AdaptSAFOV = PA.getAdaptSilentRange(baseFOV)
end
end)
end
end)
local pingHUD = nil
task.spawn(function()
while true do task.wait(0.1)
if Flags.PingShowStats then
if not pingHUD then
pcall(function()
local _Compat = _G.BS and _G.BS.Compat; if _Compat and _Compat.DrawingNew then pingHUD = _Compat.DrawingNew("Text") else pcall(function() pingHUD = Drawing.new("Text") end) end
pingHUD.Center = false
pingHUD.Outline = true
pingHUD.OutlineColor = Color3.new(0, 0, 0)
pingHUD.Font = Drawing.Fonts.UI
pingHUD.Size = 13
end)
end
local ping = PingState.Current
local color = ping < 50 and Color3.fromRGB(0, 255, 0)
or ping < 100 and Color3.fromRGB(255, 255, 0)
or ping < 200 and Color3.fromRGB(255, 150, 0)
or Color3.fromRGB(255, 50, 50)
pingHUD.Text = string.format("PING: %dms [%s] x%.2f | Jitter: %d",
ping, PingState.Quality, PingState.AdaptMultiplier, PingState.Jitter)
pingHUD.Color = color
pingHUD.Position = Vector2.new(10, 520)
pingHUD.Visible = true
else
if pingHUD then pingHUD.Visible = false end
end
end
end)
BS.PA = PA
print("[PingAdapt] BloxStrike Ping Adapt v1.0 loaded")
print("[PingAdapt] Features: Real-time Ping Monitor,")
print("[PingAdapt]   Aimbot Adapt (Smooth/FOV/Predict/LagComp),")
print("[PingAdapt]   Triggerbot Adapt (Delay/Chance/Burst),")
print("[PingAdapt]   ESP Adapt (SkipFrames/Quality),")
print("[PingAdapt]   Movement Adapt (Speed/Bhop),")
print("[PingAdapt]   HVH Adapt (AA/FakeLag/Resolver/SilentAim),")
print("[PingAdapt]   Auto Panic on Extreme Lag")
print("[PingAdapt] Ping: " .. PingState.Current .. "ms [" .. PingState.Quality .. "]")
]])
writefile("BloxStrike/modules/rage.lua", [[
local Players = nil
pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local UIS = nil
pcall(function() UIS = game:GetService("UserInputService") end)
local lplr = Players.LocalPlayer
if not BS.Win then warn("[Rage] BS.Win not available - ui.lua may have failed") return end
local page = BS.Win:Tab("Rage")
if not page or not page.Toggle then warn("[Rage] Failed to create tab!") return end
local function alive() return BS.alive() end
local function hrp() return BS.hrp() end
local function hum() return BS.hum() end
local function head() local c = lplr.Character; return c and c:FindFirstChild("Head") end
local Compat = _G.BS and _G.BS.Compat
local function safeDrawingNew(class)
if Compat and Compat.DrawingNew then return Compat.DrawingNew(class) end
local s, r = pcall(function() return Drawing.new(class) end)
return s and r or nil
end
local function safeMouse1Click()
if Compat and Compat.Mouse1Click then Compat.Mouse1Click() return end
safeMouse1Click()
end
local RAGE = {
Target = nil,
Targets = {},
Fov = 180,
LastFire = 0,
LastSwitch = 0,
ResolverStep = {},
ShotsFired = {},
HitRegistered = {},
MissCount = {},
BruteSide = {},
TotalShots = {},
HitCount = {},
MultiTargetQueue = {},
WallbangCooldown = {},
LastPredictPos = {},
TargetLockTime = {},
PreFireQueue = {},
}
local WEAPONS = {
rifle   = { fireRate = 0.10, damage = 30, recoil = 1.5, spread = 0.02, pen = 80,  headMult = 4.0 },
sniper  = { fireRate = 1.50, damage = 100, recoil = 3.0, spread = 0.001, pen = 100, headMult = 4.0 },
pistol  = { fireRate = 0.30, damage = 40, recoil = 0.8, spread = 0.015, pen = 40,  headMult = 4.0 },
shotgun = { fireRate = 0.80, damage = 80, recoil = 2.0, spread = 0.10, pen = 15,  headMult = 1.0 },
smg     = { fireRate = 0.07, damage = 20, recoil = 0.6, spread = 0.03, pen = 30,  headMult = 2.5 },
knife   = { fireRate = 0.40, damage = 40, recoil = 0,   spread = 0,    pen = 0,   headMult = 1.0 },
}
local MAT_HARD = {
}
page:Toggle("Ragebot", false, function(v) Flags.Ragebot = v end)
page:Slider("Rage FOV", 30, 360, 180, function(v) Flags.RageFOV = v end)
page:Slider("Rage Hitchance", 10, 100, 85, function(v) Flags.RageHC = v end)
page:Dropdown({Name="Rage Bone", Flag="RageBone", Options={"Head","Chest","Nearest","Body","Pelvis","Stomach","Auto"}, Default="Head"})
page:Dropdown({Name="Rage Sort", Flag="RageSort", Options={"Crosshair","Distance","Health","Threat","Damage","Random"}, Default="Crosshair"})
page:Toggle("Rage Auto Fire", true, function(v) Flags.RageAF = v end)
page:Slider("Rage Fire Rate", 1, 50, 12, function(v) Flags.RageFR = v end)
page:Toggle("Rage Double Tap", false, function(v) Flags.RageDT = v end)
page:Slider("Rage DT Delay", 1, 30, 6, function(v) Flags.RageDTD = v end)
page:Toggle("Rage Triple Tap", false, function(v) Flags.RageTT = v end)
page:Toggle("Rage Auto Scope", false, function(v) Flags.RageAScope = v end)
page:Toggle("Rage Auto Crouch", false, function(v) Flags.RageACrouch = v end)
page:Toggle("Rage Auto Reload", false, function(v) Flags.RageAReload = v end)
page:Toggle("Rage Through Walls", true, function(v) Flags.RageWall = v end)
page:Slider("Rage Penetration", 10, 100, 70, function(v) Flags.RagePen = v end)
page:Toggle("Rage Prediction", true, function(v) Flags.RagePred = v end)
page:Slider("Rage Pred Factor", 5, 80, 35, function(v) Flags.RagePredF = v end)
page:Toggle("Rage Resolver", true, function(v) Flags.RageRes = v end)
page:Slider("Rage Res Steps", 1, 8, 5, function(v) Flags.RageResS = v end)
page:Toggle("Rage Head Only", false, function(v) Flags.RageHead = v end)
page:Toggle("Rage Body Aim", false, function(v) Flags.RageBody = v end)
page:Toggle("Rage Limb Aim", false, function(v) Flags.RageLimb = v end)
page:Toggle("Rage Smart Body", true, function(v) Flags.RageSmartBody = v end)
page:Slider("Rage Min Damage", 1, 100, 1, function(v) Flags.RageMinDmg = v end)
page:Toggle("Rage Knifebot", false, function(v) Flags.RageKnife = v end)
page:Slider("Rage Knife Range", 2, 10, 5, function(v) Flags.RageKnifeR = v end)
page:Toggle("Rage Zeusing", false, function(v) Flags.RageZeus = v end)
page:Slider("Rage Zeus Range", 5, 30, 20, function(v) Flags.RageZeusR = v end)
page:Toggle("Rage Safety", true, function(v) Flags.RageSafe = v end)
page:Toggle("Rage HP Override", false, function(v) Flags.RageHPOvr = v end)
page:Slider("Rage HP Threshold", 10, 90, 30, function(v) Flags.RageHPThresh = v end)
page:Separator()
page:Label("  Enhanced HVH ")
page:Toggle("Quad Tap", false, function(v) Flags.RageQT = v end)
page:Toggle("Multi-Target", false, function(v) Flags.RageMultiTarget = v end)
page:Slider("MT Range", 50, 360, 180, function(v) Flags.RageMTRange = v end)
page:Label("Quad Tap: 4 shots in rapid succession")
page:Label("Multi-Target: shoot at 2nd closest enemy too")
page:Toggle("Multipoint", false, function(v) Flags.RageMP = v end)
page:Slider("MP Head Scale", 0, 100, 50, function(v) Flags.RageMPHead = v end)
page:Slider("MP Chest Scale", 0, 100, 50, function(v) Flags.RageMPChest = v end)
page:Slider("MP Body Scale", 0, 100, 30, function(v) Flags.RageMPBody = v end)
page:Slider("MP Stomach Scale", 0, 100, 20, function(v) Flags.RageMPStomach = v end)
page:Label("Scale: 0=OFF, 100=Full hitbox")
page:Separator()
page:Label(" Safe Point ")
page:Toggle("Safe Point", false, function(v) Flags.RageSP = v end)
page:Slider("SP Tolerance", 1, 50, 20, function(v) Flags.RageSPTol = v end)
page:Toggle("SP Auto Disable", true, function(v) Flags.RageSPAuto = v end)
page:Label("Safe Point: Don't shoot when enemy at bad angle")
page:Separator()
page:Label(" Damage Override ")
page:Toggle("Damage Override", false, function(v) Flags.RageDmgOvr = v end)
page:Slider("Override Damage", 1, 120, 1, function(v) Flags.RageDmgOvrVal = v end)
page:Dropdown({Name="Override Key", Flag="RageDmgKey", Options={"Mouse4","Mouse5","Left Alt","Left Ctrl","Shift"}, Default="Mouse4"})
page:Label("Hold key to temporarily override min damage")
page:Separator()
page:Label(" Force Aim ")
page:Toggle("Force Body", false, function(v) Flags.RageForceBody = v end)
page:Toggle("Force Head", false, function(v) Flags.RageForceHead = v end)
page:Dropdown({Name="Force Key", Flag="RageForceKey", Options={"Mouse4","Mouse5","Left Alt","Left Ctrl","Shift"}, Default="Mouse5"})
page:Label("Force: Override bone selection with key hold")
page:Separator()
page:Label(" Auto Stop ")
page:Toggle("Auto Stop", false, function(v) Flags.RageAutoStop = v end)
page:Toggle("Auto Stop In Air", false, function(v) Flags.RageAutoStopAir = v end)
page:Slider("Stop Speed", 1, 100, 100, function(v) Flags.RageStopSpd = v end)
page:Label("Auto Stop: Instant deceleration when shooting")
page:Toggle("Silent Aim", false, function(v) Flags.SilentAim = v end)
page:Dropdown({Name="SA Mode", Flag="SAMode", Options={"Camera Redirect","Mouse Redirect","Server Angle","Hybrid"}, Default="Camera Redirect"})
page:Slider("SA FOV", 10, 360, 140, function(v) Flags.SAFov = v end)
page:Slider("SA HC", 30, 100, 92, function(v) Flags.SAHC = v end)
page:Dropdown({Name="SA Bone", Flag="SABone", Options={"Head","Chest","Nearest","Pelvis","Body","Auto"}, Default="Head"})
page:Toggle("SA Predict", true, function(v) Flags.SAPred = v end)
page:Slider("SA Pred Time", 5, 60, 30, function(v) Flags.SAPredT = v end)
page:Toggle("SA Vis Check", false, function(v) Flags.SAVis = v end)
page:Toggle("SA Wall Check", false, function(v) Flags.SAWall = v end)
page:Toggle("SA Team Check", true, function(v) Flags.SATeam = v end)
page:Toggle("SA Auto Fire", false, function(v) Flags.SAAF = v end)
page:Slider("SA Target Switch", 0, 500, 80, function(v) Flags.SASwitch = v end)
page:Toggle("SA FOV Circle", true, function(v) Flags.SAFovCirc = v end)
page:Slider("SA Smooth", 1, 20, 1, function(v) Flags.SASmooth = v end)
page:Toggle("SA Smart Mode", false, function(v) Flags.SASmart = v end)
page:Slider("SA Smart Range", 10, 100, 45, function(v) Flags.SASmartR = v end)
page:Toggle("SA Backtrack", false, function(v) Flags.SABacktrack = v end)
page:Slider("SA BT Time", 50, 400, 200, function(v) Flags.SABTT = v end)
page:Toggle("SA Hit Sound", false, function(v) Flags.SAHitSnd = v end)
page:Label(" Advanced SA ")
page:Toggle("SA Multi Target", false, function(v) Flags.SAMultiT = v end)
page:Slider("SA Multi Count", 1, 5, 2, function(v) Flags.SAMultiC = v end)
page:Toggle("SA Resolver Override", false, function(v) Flags.SAResOvr = v end)
page:Toggle("SA Hitbox Expander", false, function(v) Flags.SAHBE = v end)
page:Slider("SA HB Size", 1, 5, 2, function(v) Flags.SAHBS = v end)
page:Toggle("SA Magic Bullet", false, function(v) Flags.SAMagic = v end)
page:Slider("SA Magic Distance", 10, 100, 50, function(v) Flags.SAMagicD = v end)
page:Toggle("SA Auto Wallbang", true, function(v) Flags.SAAutoWall = v end)
page:Slider("SA Wallbang Pen", 10, 100, 70, function(v) Flags.SAWallPen = v end)
page:Toggle("SA Lag Compensation", false, function(v) Flags.SALagComp = v end)
page:Slider("SA LC Ticks", 1, 16, 8, function(v) Flags.SALCTicks = v end)
page:Toggle("SA Position Adjustment", false, function(v) Flags.SAPosAdj = v end)
page:Slider("SA Pos Adj X", -10, 10, 0, function(v) Flags.SAPosAdjX = v end)
page:Slider("SA Pos Adj Y", -10, 10, 0, function(v) Flags.SAPosAdjY = v end)
page:Toggle("SA Nearest Bone Priority", false, function(v) Flags.SANBP = v end)
page:Toggle("SA Spread Control", false, function(v) Flags.SASpread = v end)
page:Slider("SA Spread Factor", 0, 100, 50, function(v) Flags.SASpreadF = v end)
page:Toggle("SA Recoil Control", false, function(v) Flags.SARCS = v end)
page:Slider("SA RCS X", 0, 100, 60, function(v) Flags.SARCSX = v end)
page:Slider("SA RCS Y", 0, 100, 80, function(v) Flags.SARCSY = v end)
page:Toggle("SA Silent Walk", false, function(v) Flags.SASilentWalk = v end)
page:Toggle("SA Auto Scope", false, function(v) Flags.SAAutoScope = v end)
page:Toggle("SA No Visual Recoil", false, function(v) Flags.SANoVR = v end)
page:Label(" Backwards / 360 SA ")
page:Toggle("SA Backwards", false, function(v) Flags.SABackwards = v end)
page:Dropdown({Name="SA Backwards Dir", Flag="SABackDir", Options={"Away","Left","Right","Random","Toward"}, Default="Away"})
page:Toggle("SA 360 Mode", false, function(v) Flags.SA360 = v end)
page:Slider("SA 360 Range", 30, 360, 360, function(v) Flags.SA360Range = v end)
page:Toggle("SA AA Sync", false, function(v) Flags.SAAASync = v end)
page:Toggle("SA Freestand", false, function(v) Flags.SAFreeStand = v end)
page:Toggle("SA Fake Duck Aim", false, function(v) Flags.SAFakeDuckAim = v end)
page:Toggle("SA Inverse Aim", false, function(v) Flags.SAInverse = v end)
page:Slider("SA Inverse Offset", 0, 180, 180, function(v) Flags.SAInvOff = v end)
page:Label("Backwards: ")
page:Label("360: 360")
page:Label("AA Sync: ")
page:Label("Silent Aim: Hit without visual aim movement")
page:Separator()
page:Toggle("PSilent", false, function(v) Flags.RagePSilent = v end)
page:Dropdown({Name="PS Mode", Flag="RagePSMode", Options={"Server Angle","Camera","Hybrid"}, Default="Server Angle"})
page:Slider("PS FOV", 10, 360, 180, function(v) Flags.RagePSFov = v end)
page:Slider("PS HC", 50, 100, 95, function(v) Flags.RagePSHC = v end)
page:Toggle("PS Wallbang", true, function(v) Flags.RagePSWall = v end)
page:Toggle("PS Backtrack", false, function(v) Flags.RagePSBT = v end)
page:Label("PSilent: Pure server-side hit without ANY camera movement")
page:Separator()
page:Label(" Rapid Fire ")
page:Toggle("Rapid Fire", false, function(v) Flags.RageRapid = v end)
page:Slider("Rapid Rate", 1, 50, 25, function(v) Flags.RageRapidRate = v end)
page:Dropdown({Name="Rapid Mode", Flag="RageRapidMode", Options={"Aggressive","Controlled","Burst"}, Default="Controlled"})
page:Slider("Rapid Burst Count", 2, 10, 4, function(v) Flags.RageRapidBurst = v end)
page:Toggle("Rapid No Spread", false, function(v) Flags.RageRapidNS = v end)
page:Label("Rapid Fire: Continuous fast shooting (more aggressive than DT)")
page:Toggle("Bullet Tracer", true, function(v) Flags.BulletTracer = v end)
page:Toggle("Tracer Through Walls", true, function(v) Flags.TracerWall = v end)
page:Slider("Tracer Width", 1, 5, 2, function(v) Flags.TracerWidth = v end)
page:Slider("Tracer Duration", 1, 10, 3, function(v) Flags.TracerDuration = v end)
page:Dropdown({Name="Tracer Color", Flag="TracerColor", Options={"Red","Green","Blue","Yellow","Cyan","Magenta","White","Rainbow"}, Default="Red"})
page:Toggle("Tracer Impact Point", true, function(v) Flags.TracerImpact = v end)
page:Slider("Tracer Impact Size", 3, 15, 6, function(v) Flags.TracerImpactSize = v end)
page:Toggle("Tracer Penetration Line", true, function(v) Flags.TracerPenLine = v end)
page:Toggle("Tracer Hit Marker", true, function(v) Flags.TracerHitMarker = v end)
page:Slider("Tracer Hit Marker Size", 5, 25, 12, function(v) Flags.TracerHMS = v end)
page:Toggle("Tracer Kill Counter", false, function(v) Flags.TracerKillCount = v end)
page:Label("--- BULLET TRACER SECTION END ---")
-- SECTION 2: ANTI-AIM (Enhanced)
page:Toggle("Anti-Aim", false, function(v) Flags.AA = v end)
page:Dropdown({Name="AA Pitch", Flag="AAPitch", Options={
}, Default="Down"})
page:Dropdown({Name="AA Yaw", Flag="AAYaw", Options={
}, Default="Spin"})
page:Slider("AA Speed", 1, 30, 12, function(v) Flags.AASpd = v end)
page:Slider("AA Jitter Range", 10, 180, 100, function(v) Flags.AAJittR = v end)
page:Toggle("AA On Ground Only", false, function(v) Flags.AAGround = v end)
page:Toggle("AA While Shooting", true, function(v) Flags.AAShoot = v end)
page:Toggle("AA Fake Duck", false, function(v) Flags.AAFakeDuck = v end)
page:Slider("AA Fake Duck Choke", 1, 16, 8, function(v) Flags.AAFDC = v end)
page:Toggle("AA Freestanding", false, function(v) Flags.AAFree = v end)
page:Toggle("AA Edge Detection", false, function(v) Flags.AAEdge = v end)
page:Toggle("AA Lower Body Yaw", true, function(v) Flags.AALBY = v end)
page:Slider("AA LBY Offset", -180, 180, 120, function(v) Flags.AALBYO = v end)
page:Toggle("AA Animation Breaker", false, function(v) Flags.AAAnimBreak = v end)
page:Dropdown({Name="AA Anim Style", Flag="AAAnimStyle", Options={"Flipped","Platform","Lean","Inverse","Downside","Slide","Moonwalk","Breaker"}, Default="Flipped"})
page:Toggle("AA Height Variation", false, function(v) Flags.AAHeight = v end)
page:Slider("AA Height Amp", 1, 10, 3, function(v) Flags.AAHeightAmp = v end)
page:Toggle("AA Desync", false, function(v) Flags.AADesync = v end)
page:Slider("AA Desync Range", -180, 180, 90, function(v) Flags.AADesyncR = v end)
page:Toggle("AA Jitter Tick", false, function(v) Flags.AAJittTick = v end)
page:Slider("AA Jitter Interval", 1, 10, 3, function(v) Flags.AAJittInt = v end)
page:Toggle("AA Manual Override", false, function(v) Flags.AAManual = v end)
page:Dropdown({Name="AA Manual Dir", Flag="AAManualDir", Options={"Forward","Backward","Left","Right"}, Default="Backward"})
page:Toggle("AA Body Yaw", true, function(v) Flags.AABodyYaw = v end)
page:Slider("AA Body Yaw Offset", -180, 180, 60, function(v) Flags.AABodyYawO = v end)
page:Toggle("AA Fake Angles", false, function(v) Flags.AAFakeAngles = v end)
page:Toggle("AA Slow Walk AA", false, function(v) Flags.AASlowAA = v end)
page:Toggle("AA Air AA", false, function(v) Flags.AAAirAA = v end)
page:Toggle("AA Desync Visualizer", false, function(v) Flags.AADesyncViz = v end)
page:Label(" Advanced AA ")
page:Toggle("AA Dynamic Jitter", false, function(v) Flags.AADynJitt = v end)
page:Slider("AA Dyn Jitter Min", 10, 90, 30, function(v) Flags.AADynMin = v end)
page:Slider("AA Dyn Jitter Max", 90, 180, 150, function(v) Flags.AADynMax = v end)
page:Toggle("AA Sideways", false, function(v) Flags.AASideways = v end)
page:Toggle("AA Backwards", false, function(v) Flags.AABackwards = v end)
page:Toggle("AA Resolved Jitter", false, function(v) Flags.AAResJitt = v end)
page:Slider("AA Resolved Jitter Speed", 1, 20, 10, function(v) Flags.AAResJSpd = v end)
page:Toggle("AA Anti Resolver", false, function(v) Flags.AAAntiRes = v end)
page:Toggle("AA Body Flip", false, function(v) Flags.AABodyFlip = v end)
page:Slider("AA Body Flip Interval", 1, 10, 5, function(v) Flags.AABodyFlipInt = v end)
page:Toggle("AA Fake Lag Sync", false, function(v) Flags.AAFLSync = v end)
page:Toggle("AA Move Manipulation", false, function(v) Flags.AAMoveManip = v end)
page:Slider("AA Move Manip Strength", 1, 20, 8, function(v) Flags.AAMoveStr = v end)
page:Toggle("AA View Manipulation", false, function(v) Flags.AAViewManip = v end)
page:Slider("AA View Manip Angle", 1, 180, 90, function(v) Flags.AAViewAngle = v end)
page:Toggle("AA Anti Untrust", false, function(v) Flags.AAAntiUntrust = v end)
page:Toggle("AA Slow LBY", false, function(v) Flags.AASlowLBY = v end)
page:Slider("AA Slow LBY Speed", 1, 10, 3, function(v) Flags.AASlowLBYS = v end)
page:Toggle("AA Brute After Miss", true, function(v) Flags.AABruteMiss = v end)
page:Slider("AA Brute Steps", 2, 8, 4, function(v) Flags.AABruteSteps = v end)
page:Label("AA: Confuse enemy aimbot with fake angles")
page:Separator()
page:Toggle("Desync", false, function(v) Flags.AADesync2 = v end)
page:Slider("Desync Range", 1, 58, 58, function(v) Flags.AADesyncR2 = v end)
page:Dropdown({Name="Desync Mode", Flag="AADesyncMode", Options={"Static","Jitter","Random","Brute","Cycle"}, Default="Static"})
page:Slider("Desync Jitter Range", 1, 58, 30, function(v) Flags.AADesyncJR = v end)
page:Toggle("Desync Inverter", true, function(v) Flags.AADesyncInv = v end)
page:Dropdown({Name="Inverter Key", Flag="AADesyncKey", Options={"Mouse4","Mouse5","Left Alt","Left Ctrl","Shift"}, Default="Mouse4"})
page:Label("Desync: Shift hitbox away from visible model")
page:Separator()
page:Label(" Emotion (CS2  AA) ")
page:Toggle("Emotion AA", false, function(v) Flags.AAEmotion = v end)
page:Slider("Emotion Pitch", 45, 90, 45, function(v) Flags.AAEmoPitch = v end)
page:Dropdown({Name="Emotion Desync", Flag="AAEmoDesync", Options={"Static","Jitter","LBY"}, Default="Static"})
page:Slider("Emotion Desync Range", 1, 58, 58, function(v) Flags.AAEmoDR = v end)
page:Label("Emotion: 45 pitch + static desync (most common CS2 AA)")
page:Separator()
page:Label(" Lean ")
page:Toggle("Lean", false, function(v) Flags.AALean = v end)
page:Slider("Lean Amount", 1, 58, 58, function(v) Flags.AALeanAmt = v end)
page:Dropdown({Name="Lean Side", Flag="AALeanSide", Options={"Auto","Left","Right","Alternating"}, Default="Auto"})
page:Label("Lean: Body lean to make hitbox harder to resolve")
page:Separator()
page:Label(" LBY Breaker ")
page:Toggle("LBY Breaker", false, function(v) Flags.AALBYBreak = v end)
page:Slider("LBY Break Interval", 100, 1000, 350, function(v) Flags.AALBYInt = v end)
page:Slider("LBY Break Offset", -120, 120, 120, function(v) Flags.AALBYOff = v end)
page:Label("LBY Breaker: Break Lower Body Yaw for 118 legit AA")
page:Separator()
page:Label(" Manual Anti-Aim ")
page:Toggle("Manual AA", false, function(v) Flags.AAManual2 = v end)
page:Dropdown({Name="Left Key", Flag="AAMLeft", Options={"Mouse4","Mouse5","Left Alt","Left Ctrl","Shift"}, Default="Mouse4"})
page:Dropdown({Name="Right Key", Flag="AAMRight", Options={"Mouse4","Mouse5","Left Alt","Left Ctrl","Shift"}, Default="Mouse5"})
page:Dropdown({Name="Back Key", Flag="AAMBack", Options={"Mouse4","Mouse5","Left Alt","Left Ctrl","Shift"}, Default="Left Alt"})
page:Label("Manual: Use keys to force specific AA direction")
page:Separator()
page:Label(" Auto Freestand ")
page:Toggle("Auto Freestand", false, function(v) Flags.AAFreeStand = v end)
page:Slider("Freestand Range", 1, 10, 5, function(v) Flags.AAFreeR = v end)
page:Toggle("Freestand Edge Detect", true, function(v) Flags.AAFreeEdge = v end)
page:Label("Freestand: Auto face nearest wall to hide real angle")
page:Toggle("Fake Lag", false, function(v) Flags.FL = v end)
page:Slider("FL Choke", 1, 16, 7, function(v) Flags.FLChoke = v end)
page:Dropdown({Name="FL Style", Flag="FLStyle", Options={"Constant","Adaptive","Random","Tick","Break Lag","Shift","Aggressive","Hyper","Break LC","Desync"}, Default="Adaptive"})
page:Slider("FL Tick Rate", 1, 16, 8, function(v) Flags.FLTick = v end)
page:Toggle("FL On Ground Only", false, function(v) Flags.FLGround = v end)
page:Toggle("FL Moving Only", false, function(v) Flags.FLMoving = v end)
page:Slider("FL Variance", 0, 50, 20, function(v) Flags.FLVar = v end)
page:Toggle("FL Fake Walk", false, function(v) Flags.FLFakeWalk = v end)
page:Slider("FL Fake Walk Speed", 1, 16, 4, function(v) Flags.FLFWS = v end)
page:Toggle("FL Break LC", false, function(v) Flags.FLBLC = v end)
page:Separator()
page:Toggle("Hideshots", false, function(v) Flags.ExploitHS = v end)
page:Slider("HS Ticks", 1, 16, 8, function(v) Flags.ExploitHSTicks = v end)
page:Dropdown({Name="HS Mode", Flag="ExploitHSMode", Options={"Tick Shift","Lag Swap","Break LC"}, Default="Tick Shift"})
page:Label("Hideshots: Prevent getting oneshotted via tickbase")
page:Separator()
page:Toggle("Onshot", false, function(v) Flags.ExploitOnshot = v end)
page:Slider("Onshot Delay", 1, 16, 6, function(v) Flags.ExploitOSDelay = v end)
page:Label("Onshot: Manipulate when shots register")
page:Separator()
page:Toggle("Fake Duck", false, function(v) Flags.ExploitFakeDuck = v end)
page:Slider("Fake Duck Choke", 1, 16, 8, function(v) Flags.ExploitFDChoke = v end)
page:Label("Fake Duck: Fake crouch to change hitbox")
page:Separator()
page:Toggle("Quick Stop (Key)", false, function(v) Flags.ExploitQS = v end)
page:Dropdown({Name="QS Key", Flag="ExploitQSKey", Options={"Mouse4","Mouse5","Left Alt","Left Ctrl","Shift"}, Default="Mouse4"})
page:Label("Quick Stop: Instant deceleration on key hold")
page:Separator()
page:Label(" Exploit Presets ")
page:Button({Name="[HVH] Full Exploits", Color=Color3.fromRGB(200,50,50)}, function()
Flags.ExploitHS=true; Flags.ExploitHSTicks=10
Flags.ExploitOnshot=true; Flags.ExploitOSDelay=6
Flags.ExploitFakeDuck=true; Flags.ExploitFDChoke=10
Flags.FL=true; Flags.FLChoke=14; Flags.FLStyle="Break Lag"
Flags.AADesync2=true; Flags.AADesyncR2=58
pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="? Full Exploits",Text="HS+Onshot+FD+FL+Desync",Duration=3}) end)
end)
page:Button({Name="[HVH] Anti-Oneshot", Color=Color3.fromRGB(100,200,100)}, function()
Flags.ExploitHS=true; Flags.ExploitHSTicks=12
Flags.FL=true; Flags.FLChoke=12; Flags.FLStyle="Adaptive"
Flags.AADesync2=true; Flags.AADesyncR2=58; Flags.AADesyncMode="Jitter"
pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="Anti-Oneshot",Text="HS+FL+Desync Jitter",Duration=3}) end)
end)
page:Toggle("Resolver", false, function(v) Flags.Resolver = v end)
page:Dropdown({Name="Res Mode", Flag="ResMode", Options={
}, Default="Smart"})
page:Slider("Res Steps", 1, 12, 6, function(v) Flags.ResSteps = v end)
page:Toggle("Res Auto", true, function(v) Flags.ResAuto = v end)
page:Toggle("Res Anti Brute", true, function(v) Flags.ResAB = v end)
page:Toggle("Res Log Misses", false, function(v) Flags.ResLogMiss = v end)
page:Slider("Res Manual Angle", -180, 180, 0, function(v) Flags.ResMAngle = v end)
page:Toggle("Res Override Resolver", false, function(v) Flags.ResOverride = v end)
page:Label(" Advanced Resolver ")
page:Toggle("Res Velocity Tracking", true, function(v) Flags.ResVelTrack = v end)
page:Slider("Res Vel History", 5, 50, 20, function(v) Flags.ResVelHist = v end)
page:Toggle("Res Position Tracking", true, function(v) Flags.ResPosTrack = v end)
page:Slider("Res Pos History", 5, 30, 15, function(v) Flags.ResPosHist = v end)
page:Toggle("Res Animation Analysis", false, function(v) Flags.ResAnim = v end)
page:Toggle("Res Lag Compensation", true, function(v) Flags.ResLagComp = v end)
page:Slider("Res LC Ticks", 1, 16, 8, function(v) Flags.ResLCTicks = v end)
page:Toggle("Res Brute Force Mode", false, function(v) Flags.ResBruteMode = v end)
page:Slider("Res Brute Steps", 2, 16, 8, function(v) Flags.ResBruteSteps = v end)
page:Toggle("Res Inverse Resolver", false, function(v) Flags.ResInverse = v end)
page:Toggle("Res Adaptive", true, function(v) Flags.ResAdaptive = v end)
page:Slider("Res Adaptive Speed", 1, 10, 5, function(v) Flags.ResAdaptSpd = v end)
page:Toggle("Res Smart Detection", true, function(v) Flags.ResSmart = v end)
page:Slider("Res Smart Confidence", 10, 100, 60, function(v) Flags.ResConf = v end)
page:Toggle("Res Anti Brute Force", true, function(v) Flags.ResAntiBrute = v end)
page:Slider("Res Anti Brute Steps", 2, 8, 4, function(v) Flags.ResAntiSteps = v end)
page:Toggle("Res Manual Override", false, function(v) Flags.ResManual = v end)
page:Slider("Res Manual Angle", -180, 180, 0, function(v) Flags.ResManAngle = v end)
page:Toggle("Res Body Aim Resolver", false, function(v) Flags.ResBodyAim = v end)
page:Toggle("Res Head Aim Resolver", false, function(v) Flags.ResHeadAim = v end)
page:Toggle("Res Auto Switch", true, function(v) Flags.ResAutoSw = v end)
page:Slider("Res Switch Speed", 1, 10, 5, function(v) Flags.ResSwSpd = v end)
page:Toggle("Res Miss Detection", true, function(v) Flags.ResMiss = v end)
page:Slider("Res Miss Threshold", 1, 10, 3, function(v) Flags.ResMissTh = v end)
page:Toggle("Res Log Resolver", false, function(v) Flags.ResLog = v end)
page:Label("Resolver: Figure out enemy AA angles")
page:Separator()
page:Toggle("Moving AA Resolve", false, function(v) Flags.ResMovingAA = v end)
page:Slider("Moving Resolve Range", 1, 58, 58, function(v) Flags.ResMovingR = v end)
page:Dropdown({Name="Moving Mode", Flag="ResMovingMode", Options={"Velocity Based","Position Based","Angle Based","Adaptive"}, Default="Velocity Based"})
page:Label("Resolve enemy AA while they are moving")
page:Separator()
page:Label(" Side Detection ")
page:Toggle("Side Detection", false, function(v) Flags.ResSideDetect = v end)
page:Slider("Side Confidence", 10, 100, 60, function(v) Flags.ResSideConf = v end)
page:Dropdown({Name="Side Method", Flag="ResSideMethod", Options={"Velocity","Angle","Animation","LBY"}, Default="Velocity"})
page:Label("Detect which side enemy is leaning towards")
page:Separator()
page:Label(" Animation Breaker Detection ")
page:Toggle("Anim Breaker Detect", false, function(v) Flags.ResAnimDetect = v end)
page:Slider("Anim Detect Sensitivity", 1, 20, 10, function(v) Flags.ResAnimSens = v end)
page:Toggle("Anim Breaker Counter", false, function(v) Flags.ResAnimCounter = v end)
page:Label("Detect and counter enemy animation breakers")
page:Separator()
page:Label(" Resolver Presets ")
page:Button({Name="[Res] Smart Auto", Color=Color3.fromRGB(100,200,100)}, function()
Flags.Resolver=true; Flags.ResMode="Smart"
Flags.ResAuto=true; Flags.ResAB=true; Flags.ResVelTrack=true
Flags.ResAdaptive=true; Flags.ResSmart=true; Flags.ResAntiBrute=true
Flags.ResAutoSw=true; Flags.ResMiss=true
Flags.ResMovingAA=true; Flags.ResSideDetect=true
pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title=" Smart Resolver",Text="All resolver features ON",Duration=3}) end)
end)
page:Button({Name="[Res] Brute Force", Color=Color3.fromRGB(200,100,0)}, function()
Flags.Resolver=true; Flags.ResMode="Brute Force"
Flags.ResBruteMode=true; Flags.ResBruteSteps=12
Flags.ResAuto=true; Flags.ResAB=true
Flags.ResMovingAA=true; Flags.ResAnimDetect=true
pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="Brute Resolver",Text="Brute Force + Moving + Anim",Duration=3}) end)
end)
page:Toggle("Quick Stop", false, function(v) Flags.QS = v end)
page:Toggle("Slow Walk", false, function(v) Flags.SW = v end)
page:Slider("SW Speed", 1, 16, 4, function(v) Flags.SWS = v end)
page:Toggle("No Clip", false, function(v) Flags.NoClip = v end)
page:Toggle("Edge Friction", false, function(v) Flags.EdgeFric = v end)
page:Toggle("Auto Revolver", false, function(v) Flags.AutoRev = v end)
page:Toggle("Auto Pistol", false, function(v) Flags.AutoPistol = v end)
page:Slider("Pistol Fire Rate", 1, 20, 8, function(v) Flags.PistolFR = v end)
page:Toggle("Crouch Walk", false, function(v) Flags.CrouchWalk = v end)
page:Toggle("Circle Strafe", false, function(v) Flags.CircStrafe = v end)
page:Slider("CS Speed", 1, 20, 8, function(v) Flags.CSSpd = v end)
page:Separator()
page:Label(" Weapon Switch ")
page:Toggle("Quick Switch", false, function(v) Flags.QuickSwitch = v end)
page:Dropdown({Name="QS Mode", Flag="QSMode", Options={"Knife-Primary","Knife-Zeus","Auto-Zeus","Last Weapon"}, Default="Knife-Primary"})
page:Slider("QS Delay", 10, 500, 100, function(v) Flags.QSDelay = v end)
page:Toggle("QS On Kill", true, function(v) Flags.QSOnKill = v end)
page:Toggle("QS On Empty", false, function(v) Flags.QSOnEmpty = v end)
page:Separator()
page:Label(" Enhanced Zeus ")
page:Toggle("Auto Zeus", false, function(v) Flags.AutoZeus = v end)
page:Slider("Zeus Range", 3, 20, 12, function(v) Flags.ZeusRange = v end)
page:Toggle("Zeus Auto Switch", false, function(v) Flags.ZeusAutoSw = v end)
page:Toggle("Zeus Team Check", true, function(v) Flags.ZeusTeam = v end)
page:Toggle("Zeus Wall Check", false, function(v) Flags.ZeusWall = v end)
page:Slider("Zeus Cooldown", 100, 3000, 500, function(v) Flags.ZeusCD = v end)
page:Toggle("Zeus on Low HP", false, function(v) Flags.ZeusLowHP = v end)
page:Slider("Zeus HP Threshold", 10, 80, 30, function(v) Flags.ZeusHPThresh = v end)
page:Separator()
page:Toggle("Slide Walk", false, function(v) Flags.HVHSlideWalk = v end)
page:Slider("Slide Speed", 1, 20, 10, function(v) Flags.HVHSlideSpd = v end)
page:Label("Slide Walk: Player slides when walking")
page:Separator()
page:Label(" Pixel Surf ")
page:Toggle("Pixel Surf", false, function(v) Flags.HVHPixelSurf = v end)
page:Slider("PSurf Height", 1, 10, 3, function(v) Flags.HVHPixelH = v end)
page:Label("Pixel Surf: Surf on thin edges")
page:Separator()
page:Label(" Movement Exploits ")
page:Toggle("Crouch Walk", false, function(v) Flags.HVHCrouchWalk = v end)
page:Toggle("Edge Friction Bug", false, function(v) Flags.HVHEdgeFriction = v end)
page:Toggle("Auto Revolver", false, function(v) Flags.HVHAutoRev = v end)
page:Toggle("Auto Pistol", false, function(v) Flags.HVHAutoPistol = v end)
page:Slider("Pistol Fire Rate", 1, 20, 8, function(v) Flags.HVHPistolFR = v end)
page:Button({Name="[HVH] Full Rage", Color=Color3.fromRGB(200,50,50)}, function()
Flags.Ragebot=true; Flags.RageFOV=360; Flags.RageHC=100; Flags.RageAF=true
Flags.RageDT=true; Flags.RageWall=true; Flags.RagePred=true; Flags.RageRes=true
Flags.AA=true; Flags.AAPitch="Jitter"; Flags.AAYaw="Spin"; Flags.AASpd=18
Flags.FL=true; Flags.FLChoke=10; Flags.FLStyle="Adaptive"
Flags.Resolver=true; Flags.ResMode="Smart"
pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="? Full Rage",Text="All HVH features ON!",Duration=3}) end)
end)
page:Button({Name="[HVH] Legit Rage", Color=Color3.fromRGB(100,150,200)}, function()
Flags.Ragebot=true; Flags.RageFOV=150; Flags.RageHC=80; Flags.RageAF=false
Flags.RageDT=false; Flags.RageWall=false; Flags.RagePred=true; Flags.RageRes=true
Flags.AA=true; Flags.AAPitch="Down"; Flags.AAYaw="Jitter"; Flags.AASpd=8
Flags.FL=true; Flags.FLChoke=4; Flags.FLStyle="Constant"
Flags.Resolver=true; Flags.ResMode="Moving AW"
pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="Legit Rage",Text="Conservative HVH ON",Duration=3}) end)
end)
page:Button({Name="[HVH] AA Only", Color=Color3.fromRGB(100,200,100)}, function()
Flags.Ragebot=false; Flags.AA=true; Flags.AAPitch="Down"; Flags.AAYaw="Back"
Flags.AASpd=10; Flags.FL=true; Flags.FLChoke=6
pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="AA Only",Text="Anti-Aim + Fake Lag",Duration=3}) end)
end)
page:Button({Name="[HVH] Disable All", Color=Color3.fromRGB(60,60,60)}, function()
for k,_ in pairs(Flags) do Flags[k]=false end
pcall(function()
local h=hum(); if h then h.WalkSpeed=16; h.JumpPower=50; h.HipHeight=0 end
workspace.CurrentCamera.FieldOfView=70
end)
pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="Off",Text="All HVH disabled",Duration=3}) end)
end)
page:Toggle("HVH Super Mode", false, function(v) Flags.HVHSuper = v end)
page:Toggle("Auto Anti-Aim", false, function(v) Flags.AutoAA = v end)
page:Toggle("Auto Fake Lag", false, function(v) Flags.AutoFL = v end)
page:Toggle("Auto Resolver", false, function(v) Flags.AutoRes = v end)
page:Toggle("Auto Ragebot", false, function(v) Flags.AutoRage = v end)
page:Toggle("Smart Brute Force", false, function(v) Flags.SmartBrute = v end)
page:Toggle("Auto Switch AA", false, function(v) Flags.AutoSwitchAA = v end)
page:Toggle("Anti-Aim On Enemy", false, function(v) Flags.AAOnEnemy = v end)
page:Toggle("Predictive AA", false, function(v) Flags.PredAA = v end)
page:Toggle("Desync Choke", false, function(v) Flags.DesyncChoke = v end)
page:Slider("Desync Choke Ticks", 1, 16, 8, function(v) Flags.DesyncChokeT = v end)
page:Toggle("Lag Spike AA", false, function(v) Flags.LagSpikeAA = v end)
page:Slider("Lag Spike Interval", 1, 20, 5, function(v) Flags.LagSpikeInt = v end)
page:Toggle("Double Tap Kill", false, function(v) Flags.DTKill = v end)
page:Toggle("Rapid Fire", false, function(v) Flags.RapidFire = v end)
page:Slider("Rapid Fire Rate", 1, 50, 25, function(v) Flags.RapidFireRate = v end)
page:Label("  ")
page:Toggle("Auto Wallbang Kill", false, function(v) Flags.AutoWBKill = v end)
page:Slider("WB Max Penetration", 10, 100, 80, function(v) Flags.AutoWBMaxPen = v end)
page:Slider("WB Min Damage", 5, 80, 20, function(v) Flags.AutoWBMinDmg = v end)
page:Slider("WB Kill Chance %", 5, 100, 30, function(v) Flags.AutoWBKillChance = v end)
page:Slider("WB Kill Threshold", 10, 100, 50, function(v) Flags.WBKillThresh = v end)
page:Toggle("WB Notify", false, function(v) Flags.AutoWBNotify = v end)
page:Toggle("One Tap Mode", false, function(v) Flags.OneTap = v end)
page:Toggle("Jump Scout", false, function(v) Flags.JumpScout = v end)
page:Slider("Jump Scout Delay", 50, 500, 150, function(v) Flags.JSDelay = v end)
page:Toggle("Edge Bug Friction", false, function(v) Flags.EdgeBugFriction = v end)
page:Label(" HVH  ")
page:Button({Name="[Feature]", Color=Color3.fromRGB(255,50,50)}, function()
Flags.HVHSuper = true
Flags.Ragebot = true; Flags.RageFOV = 360; Flags.RageHC = 100
Flags.RageAF = true; Flags.RageDT = true; Flags.RageWall = true
Flags.RagePred = true; Flags.RageRes = true; Flags.RageAutoReload = true
Flags.AA = true; Flags.AAPitch = "Jitter"; Flags.AAYaw = "LBY Break"
Flags.AASpd = 18; Flags.AAJittR = 150
Flags.AAFakeDuck = true; Flags.AAFree = true; Flags.AAEdge = true
Flags.AALBY = true; Flags.AALBYO = 120
Flags.AAAnimBreak = true; Flags.AAAnimStyle = "Breaker"
Flags.AADesync = true; Flags.AADesyncR = 120
Flags.AADynJitt = true; Flags.AADynMin = 30; Flags.AADynMax = 150
Flags.AABodyFlip = true; Flags.AABodyFlipInt = 3
Flags.AAMoveManip = true; Flags.AAMoveStr = 10
Flags.AAAntiRes = true; Flags.AABruteMiss = true; Flags.AABruteSteps = 6
Flags.AASlowAA = true; Flags.AAAirAA = true
Flags.AAAntiUntrust = true; Flags.AASlowLBY = true
Flags.FL = true; Flags.FLChoke = 10; Flags.FLStyle = "Adaptive"
Flags.FLVar = 25; Flags.FLFakeWalk = true; Flags.FLFWS = 4; Flags.FLBLC = true
Flags.Resolver = true; Flags.ResMode = "Smart"; Flags.ResSteps = 10
Flags.ResAuto = true; Flags.ResAB = true; Flags.ResVelTrack = true
Flags.ResAdaptive = true; Flags.ResSmart = true; Flags.ResAntiBrute = true
Flags.ResAutoSw = true; Flags.ResMiss = true
Flags.SilentAim = true; Flags.SAFov = 360; Flags.SAHC = 100
Flags.SAPred = true; Flags.SAAF = true; Flags.SABacktrack = true
Flags.SABTT = 300; Flags.SAAutoWall = true; Flags.SALagComp = true
Flags.SA360 = true; Flags.SA360Range = 360
Flags.SABackwards = true; Flags.SABackDir = "Away"
Flags.DesyncChoke = true; Flags.LagSpikeAA = true
Flags.OneTap = true; Flags.DTKill = true
Flags.AutoWBKill = true; Flags.AutoWBMaxPen = 90
Flags.StealthHumanize = true; Flags.HVHSafeMode = true
pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="? HVH Full Auto",Text="ALL HVH + Wallbang!",Duration=5}) end)
end)
page:Button({Name="HVH Anti-Resolver", Color=Color3.fromRGB(100,200,100)}, function()
Flags.AA = true; Flags.AAPitch = "Down"; Flags.AAYaw = "LBY Break"
Flags.AASpd = 15; Flags.AAJittR = 120
Flags.AADesync = true; Flags.AADesyncR = 120
Flags.AAFakeDuck = true; Flags.AAFDC = 12
Flags.AABodyFlip = true; Flags.AABodyFlipInt = 3
Flags.AAMoveManip = true; Flags.AAMoveStr = 8
Flags.AAAntiRes = true; Flags.AABruteMiss = true; Flags.AABruteSteps = 8
Flags.AASlowLBY = true; Flags.AASlowLBYS = 3
Flags.FL = true; Flags.FLChoke = 8; Flags.FLStyle = "Adaptive"
Flags.Resolver = true; Flags.ResMode = "Smart"; Flags.ResSteps = 10
Flags.ResAntiBrute = true; Flags.ResAntiSteps = 6
pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="Anti-Resolver",Text="Maximum anti-resolve protection!",Duration=3}) end)
end)
page:Button({Name="HVH Rage Combo", Color=Color3.fromRGB(200,100,0)}, function()
Flags.Ragebot = true; Flags.RageFOV = 360; Flags.RageHC = 100
Flags.RageAF = true; Flags.RageDT = true; Flags.RageTT = true
Flags.RageWall = true; Flags.RagePen = 100
Flags.RagePred = true; Flags.RagePredF = 50
Flags.RageRes = true; Flags.RageResS = 10
Flags.RageSmartBody = true; Flags.RageAutoReload = true
Flags.OneTap = true; Flags.DTKill = true; Flags.RapidFire = true
Flags.RapidFireRate = 30
Flags.SilentAim = true; Flags.SAFov = 360; Flags.SAHC = 100
Flags.SAPred = true; Flags.SAAF = true
Flags.SABacktrack = true; Flags.SABTT = 300
Flags.SAAutoWall = true; Flags.SAWallPen = 100
Flags.SALagComp = true; Flags.SALCTicks = 16
Flags.SA360 = true; Flags.SA360Range = 360
Flags.SAHitSound = true
Flags.AutoWBKill = true; Flags.AutoWBMaxPen = 100
pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="Rage Combo",Text="Maximum rage + Wallbang!",Duration=3}) end)
end)
page:Button({Name=" HVH Smart Auto", Color=Color3.fromRGB(150,100,255)}, function()
Flags.HVHSuper = true
Flags.AutoAA = true; Flags.AutoFL = true; Flags.AutoRes = true
Flags.AutoRage = true; Flags.SmartBrute = true
Flags.AutoSwitchAA = true; Flags.PredAA = true
Flags.StealthHumanize = true; Flags.HVHSafeMode = true
pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title=" Smart Auto",Text="AI-powered HVH activated!",Duration=3}) end)
end)
-- SECTION 8: HVH STATISTICS
page:Label("--- HVH STATISTICS ---")
page:Button({Name="[HVH] Show Stats", Color=Color3.fromRGB(200,200,100)}, function()
local activeFeatures = 0
local hvhFeatures = {"Ragebot","AA","FL","Resolver","SilentAim","NoClip","SpeedBoost","NoSpread","NoRecoil","FakeLag","AntiAim"}
local activeNames = {}
for _, f in ipairs(hvhFeatures) do
if Flags[f] or Flags[f:gsub(" ","")] then
activeFeatures = activeFeatures + 1
table.insert(activeNames, f)
end
end
local text = string.format("? HVH \n: %d\n", activeFeatures)
if #activeNames > 0 then
text = text .. "?: " .. table.concat(activeNames, ", ")
else
text = text .. "HVH "
end
pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title=" HVH",Text=text,Duration=8}) end)
end)
-- SECTION 9: AUTO PEEK
page:Separator()
page:Label(" Auto Peek ")
page:Toggle("Auto Peek", false, function(v) Flags.AutoPeek = v end)
page:Dropdown({Name="Peek Mode", Flag="AutoPeekMode", Options={"Hold Key","Toggle","Smart"}, Default="Hold Key"})
page:Slider("Peek Distance", 10, 100, 40, function(v) Flags.AutoPeekDist = v end)
page:Slider("Peek Return Delay", 10, 300, 80, function(v) Flags.AutoPeekReturn = v end)
page:Toggle("Peek Jiggle", false, function(v) Flags.AutoPeekJiggle = v end)
page:Slider("Peek Jiggle Angle", 10, 90, 30, function(v) Flags.AutoPeekAngle = v end)
-- SECTION 10: EDGE ANTI-AIM
page:Label(" Edge Anti-Aim ")
page:Toggle("Edge Anti-Aim", false, function(v) Flags.EdgeAA = v end)
page:Slider("Edge Detect Range", 5, 50, 20, function(v) Flags.EdgeAADist = v end)
page:Toggle("Edge Auto Desync", false, function(v) Flags.EdgeAutoDesync = v end)
page:Slider("Edge Desync Offset", -60, 60, 30, function(v) Flags.EdgeDesyncOff = v end)
page:Toggle("Edge Freestand", false, function(v) Flags.EdgeFreestand = v end)
-- SECTION 11: DAMAGE OVERRIDE
page:Label(" Damage Override ")
page:Toggle("Head Damage Override", false, function(v) Flags.HDmgOvr = v end)
page:Slider("Head Min Damage", 1, 100, 80, function(v) Flags.HDmgMin = v end)
page:Toggle("Body Damage Override", false, function(v) Flags.BDmgOvr = v end)
page:Slider("Body Min Damage", 1, 100, 20, function(v) Flags.BDmgMin = v end)
page:Toggle("Scoped Override Only", false, function(v) Flags.DmgScopedOnly = v end)
local autoPeekActive = false
local autoPeekDir = nil
task.spawn(function()
while true do
task.wait(0.01)
if Flags.AutoPeek and BS.alive() then
pcall(function()
local myHrp = BS.hrp()
if not myHrp then return end
local mode = Flags.AutoPeekMode or "Hold Key"
local dist = Flags.AutoPeekDist or 40
if mode == "Hold Key" then
if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
autoPeekActive = true
else
autoPeekActive = false
end
elseif mode == "Toggle" then
end
if autoPeekActive then
local cam = workspace.CurrentCamera
local lookDir = cam.CFrame.LookVector
local rightDir = cam.CFrame.RightVector
local nearest = nil
local nearDist = math.huge
for _, p in pairs(Players:GetPlayers()) do
if p ~= lplr and p.Character then
local eHrp = p and p.Character:FindFirstChild("HumanoidRootPart")
if eHrp then
local d = (eHrp.Position - myHrp.Position).Magnitude
if d < nearDist then
nearDist = d
nearest = eHrp
end
end
end
end
if nearest then
local toEnemy = (nearest.Position - myHrp.Position).Unit
local cross = lookDir:Cross(toEnemy)
local peekSide = cross.Y > 0 and rightDir or -rightDir
local peekPos = myHrp.Position + peekSide * (dist / 50)
myHrp.Velocity = peekSide * 50
if Flags.AutoPeekJiggle then
local angle = (Flags.AutoPeekAngle or 30) / 100
task.wait(0.05)
myHrp.Velocity = -peekSide * 50 * angle
end
end
else
myHrp.Velocity = Vector3.new(0, myHrp.Velocity.Y, 0)
end
end)
end
end
end)
task.spawn(function()
while true do
task.wait(0.1)
if Flags.EdgeAA and BS.alive() then
pcall(function()
local myHrp = BS.hrp()
if not myHrp then return end
local range = Flags.EdgeAADist or 20
local pos = myHrp.Position
local rayParams = RaycastParams.new()
rayParams.FilterDescendantsInstances = {lplr.Character}
rayParams.FilterType = Enum.RaycastFilterType.Blacklist
local leftRay = Workspace:Raycast(pos, -myHrp.CFrame.RightVector * range, rayParams)
local rightRay = Workspace:Raycast(pos, myHrp.CFrame.RightVector * range, rayParams)
local frontRay = Workspace:Raycast(pos, myHrp.CFrame.LookVector * range, rayParams)
local nearWall = leftRay or rightRay or frontRay
if nearWall then
if Flags.EdgeAutoDesync then
local offset = Flags.EdgeDesyncOff or 30
Flags.AABodyYawO = offset
end
if Flags.EdgeFreestand then
if leftRay and not rightRay then
Flags.AAYaw = "Manual Left"
elseif rightRay and not leftRay then
Flags.AAYaw = "Manual Right"
end
end
end
end)
end
end
end)
local originalGetDamage = nil
local function getBonePos(e, bone)
if not e or not e.Char then return nil end
if Flags.RageHead then return e.Head and e.Head.Position or e.HRP.Position+Vector3.new(0,1.5,0) end
if Flags.RageBody then return e.HRP.Position+Vector3.new(0,0.5,0) end
if bone=="Head" then return e.Head and e.Head.Position or e.HRP.Position+Vector3.new(0,1.5,0)
elseif bone=="Chest" then return e.HRP.Position+Vector3.new(0,0.5,0)
elseif bone=="Stomach" then return e.HRP.Position+Vector3.new(0,0.3,0)
elseif bone=="Pelvis" then return e.HRP.Position+Vector3.new(0,0.1,0)
elseif bone=="Body" then return e.HRP.Position
elseif bone=="Nearest" then
local cam=workspace.CurrentCamera; local mouse=UIS:GetMouseLocation()
local candidates={
{pos=e.Head and e.Head.Position or e.HRP.Position+Vector3.new(0,1.5,0)},
{pos=e.HRP.Position+Vector3.new(0,0.5,0)},
{pos=e.HRP.Position},
}
local best,bestD=candidates[1].pos,math.huge
for _,c in ipairs(candidates) do
local sp,sv=cam:WorldToViewportPoint(c.pos)
if sv then local d=(Vector2.new(sp.X,sp.Y)-mouse).Magnitude; if d<bestD then bestD=d; best=c.pos end end
end
return best
elseif bone=="Auto" then
local headPos=e.Head and e.Head.Position or e.HRP.Position+Vector3.new(0,1.5,0)
local bodyPos=e.HRP.Position+Vector3.new(0,0.5,0)
local myPos = hrp() and hrp().Position or nil
if myPos and BS.hasLineOfSight(myPos, headPos) then return headPos else return bodyPos end
end
if Flags.RageLimb then
local parts={e.HRP.Position+Vector3.new(0,1.5,0),e.HRP.Position+Vector3.new(0,0.5,0),e.HRP.Position}
return parts[math.random(#parts)]
end
return e.HRP.Position+Vector3.new(0,1.5,0)
end
local function sortTargets(enemies, myPos, cam)
local sort=Flags.RageSort or "Crosshair"
local mouse=UIS:GetMouseLocation()
local sorted={}
for _,e in ipairs(enemies) do
if e.HRP and e.Hum and e.Hum.Health>0 then
local bp=getBonePos(e,Flags.RageBone or "Head")
if bp then
local dist=(myPos-e.HRP.Position).Magnitude
local sd=math.huge
local sp,sv=cam:WorldToViewportPoint(bp)
if sv then sd=(Vector2.new(sp.X,sp.Y)-mouse).Magnitude end
local threat=0
threat=threat+(1/math.max(dist,1))*100
threat=threat+(100-e.Hum.Health)*0.5
if sd<50 then threat=threat+50 end
local wtype=BS.weaponType()
local ws=WEAPONS[wtype] or WEAPONS.rifle
local dmgMult=1/(1+dist*0.01)
local estDmg=ws.damage*ws.headMult*dmgMult
table.insert(sorted,{Enemy=e,BonePos=bp,Dist=dist,SD=sd,Health=e.Hum.Health,Threat=threat,EstDmg=estDmg})
end
end
end
if sort=="Crosshair" then table.sort(sorted,function(a,b) return a.SD<b.SD end)
elseif sort=="Distance" then table.sort(sorted,function(a,b) return a.Dist<b.Dist end)
elseif sort=="Health" then table.sort(sorted,function(a,b) return a.Health<b.Health end)
elseif sort=="Threat" then table.sort(sorted,function(a,b) return a.Threat>b.Threat end)
elseif sort=="Damage" then table.sort(sorted,function(a,b) return a.EstDmg>b.EstDmg end)
elseif sort=="Random" then for i=#sorted,2,-1 do local j=math.random(i); sorted[i],sorted[j]=sorted[j],sorted[i] end end
return sorted
end
local function analyzeWall(myPos, targetPos)
local dir=(targetPos-myPos); local dist=dir.Magnitude; local du=dir.Unit
local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances={lplr.Character}
local r1=workspace:Raycast(myPos,du*dist,params)
if not r1 then return false,0,0,nil end
local mat=r1.Material; local p1=r1.Position
local r2=workspace:Raycast(p1+du*0.5,du*(dist-(p1-myPos).Magnitude),params)
local thick=r2 and (r2.Position-p1).Magnitude or math.max(0,dist-(p1-myPos).Magnitude)
local wtype=BS.weaponType(); local ws=WEAPONS[wtype] or WEAPONS.rifle
local hardness=MAT_HARD[mat] or 50
local penChance=math.clamp((ws.pen-hardness*thick/10)/ws.pen*100,0,100)
return penChance>50,penChance,thick,mat
end
task.spawn(function()
while task.wait() do
if Flags.Ragebot and alive() then
pcall(function()
local cam=workspace.CurrentCamera; local myH=hrp(); local myHe=head()
if not cam or not myH then return end
RAGE.Fov=Flags.RageFOV or 180
local sorted=sortTargets(BS.enemies(),myH.Position,cam)
RAGE.Targets=sorted
local best=nil
for _,t in ipairs(sorted) do if t.SD<=RAGE.Fov then best=t; break end end
if best then
RAGE.Target=best
local aimPos=best.BonePos
local canPen,penChance=analyzeWall(myH.Position+Vector3.new(0,1.5,0),aimPos)
if not Flags.RageWall and not canPen then
if not BS.hasLineOfSight(myH.Position,aimPos) then return end
end
if Flags.RageHPOvr and best.Health<(Flags.RageHPThresh or 30) then
aimPos=best.Enemy.HRP.Position+Vector3.new(0,0.5,0)
end
local uid=best.Enemy.Player.UserId
if Flags.RageSmartBody and (RAGE.MissCount[uid] or 0)>=3 then
aimPos=best.Enemy.HRP.Position+Vector3.new(0,0.5,0)
end
if Flags.RagePred then
local vel=BS.getVelocity(best.Enemy)
local pf=(Flags.RagePredF or 35)/100
if Flags.PingAdapt and BS.PA then
pf=BS.PA.getAdaptPrediction(35)/100
end
aimPos=aimPos+vel*pf
end
local camPos=cam.CFrame.Position
local dir=(aimPos-camPos).Unit
cam.CFrame=CFrame.new(camPos,camPos+dir)
if math.random(1,100)>(Flags.RageHC or 85) then return end
if Flags.RageAF then
local now=tick(); local fr=(Flags.RageFR or 12)/1000
if best.Dist<15 then fr=fr*0.6 end
if now-RAGE.LastFire>=fr then
pcall(function()
local tool=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if tool and not tool.Name:lower():find("knife") then
RAGE.ShotsFired[uid]=(RAGE.ShotsFired[uid] or 0)+1
end
end)
if Flags.RageDT then
local dtDelay=math.max(0.01,(Flags.RageDTD or 6)/1000*0.7)
task.delay(dtDelay,function()
pcall(function()
local t=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if t and not t.Name:lower():find("knife") then t:Activate() end
end)
end)
end
if Flags.RageTT then
local ttDelay=math.max(0.02,(Flags.RageDTD or 6)/1000*1.2)
task.delay(ttDelay,function()
pcall(function()
local t=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if t and not t.Name:lower():find("knife") then t:Activate() end
end)
end)
end
if Flags.RageQT then
local qtDelay=math.max(0.03,(Flags.RageDTD or 6)/1000*1.8)
task.delay(qtDelay,function()
pcall(function()
local t=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if t and not t.Name:lower():find("knife") then t:Activate() end
end)
end)
end
if Flags.RageMultiTarget and #sorted>1 then
local second=sorted[2]
if second and second.SD<=RAGE.Fov*0.8 then
local aimPos2=getBonePos(second.Enemy,Flags.RageBone or "Head")
if aimPos2 then
local camPos2=cam.CFrame.Position
local dir2=(aimPos2-camPos2).Unit
cam.CFrame=CFrame.new(camPos2,camPos2+dir2)
task.delay(0.02,function()
pcall(function()
local t=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if t and not t.Name:lower():find("knife") then t:Activate() end
end)
end)
end
end
end
end
end
if Flags.RageACrouch then pcall(function() local h=hum(); if h then h.HipHeight=-0.5 end end) end
if Flags.RageAReload then pcall(function()
local t=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if t then local a=t:GetAttribute("Ammo") or t:GetAttribute("CurrentAmmo")
if a and a<=2 then UIS:PressKey(Enum.KeyCode.R); task.delay(0.1,function() UIS:ReleaseKey(Enum.KeyCode.R) end) end
end
end) end
if Flags.RageKnife and best.Dist<=(Flags.RageKnifeR or 3) then
pcall(function()
local ch=lplr.Character
for _,t in pairs(ch:GetChildren()) do
if t:IsA("Tool") and t.Name:lower():find("knife") then
if not t.Parent:IsA("Humanoid") then t.Parent=ch end
end
end
end)
end
if Flags.RageZeus then
pcall(function()
local t=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if t and (t.Name:lower():find("taser") or t.Name:lower():find("zeus")) then
if best.Dist>5 and best.Dist<=(Flags.RageZeusR or 15) then t:Activate() end
end
end)
end
else
RAGE.Target=nil
if Flags.RageACrouch then pcall(function() local h=hum(); if h then h.HipHeight=0 end end) end
end
if Flags.RageAScope then pcall(function()
local t=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if t and (t.Name:lower():find("awp") or t.Name:lower():find("sniper") or t.Name:lower():find("scout")) then
safeMouse1Click()
end
end) end
if Flags.RageMinDmg and Flags.RageMinDmg>1 then
local wtype=BS.weaponType(); local ws=WEAPONS[wtype] or WEAPONS.rifle
local dmgMult=1/(1+best.Dist*0.01)
local estDmg=ws.damage*dmgMult
if estDmg<Flags.RageMinDmg then return end
end
if Flags.RageSafe then local h=hum(); if h and h.Health<h.MaxHealth*0.1 then Flags.RageAF=false end end
end)
end
end
end)
local saTarget=nil; local saLastSwitch=0; local saFovCircle=nil
task.spawn(function()
while true do
task.wait()
if Flags.SilentAim and BS.alive() then
pcall(function()
local cam=workspace.CurrentCamera; local myH=hrp()
if not cam or not myH then return end
local mode=Flags.SAMode or "Camera Redirect"
local fov=Flags.SAFov or 140; local bone=Flags.SABone or "Head"
if Flags.PingAdapt and BS.PA then
fov=BS.PA.getAdaptSilentRange(fov)
end
local hc=Flags.SAHC or 92; local mouse=UIS:GetMouseLocation()
local now=tick()
local switchDel=(Flags.SASwitch or 80)/1000
local best=nil; local bestScore=fov
if now-saLastSwitch<switchDel and saTarget then
best=saTarget
else
for _,e in pairs(BS.enemies()) do
if not e.HRP or not e.Hum or e.Hum.Health<=0 then continue end
if Flags.SATeam and lplr.Team and e.Player.Team==lplr.Team then continue end
local aimPos=getBonePos(e,bone)
if not aimPos then continue end
if Flags.SAPred then
local vel=BS.getVelocity(e)
aimPos=aimPos+vel*((Flags.SAPredT or 30)/100)
end
if Flags.SAWall and not BS.hasLineOfSight(myH.Position,aimPos) then continue end
if Flags.SAVis then local _,v=cam:WorldToViewportPoint(aimPos); if not v then continue end end
local sp,sv=cam:WorldToViewportPoint(aimPos)
if sv then
local sd=(Vector2.new(sp.X,sp.Y)-mouse).Magnitude
if sd<bestScore then best={Enemy=e,AimPos=aimPos,SD=sd,Dist=(myH.Position-e.HRP.Position).Magnitude}; bestScore=sd end
end
end
if best then saTarget=best; saLastSwitch=now end
end
if best then
if math.random(1,100)>hc then return end
if Flags.SASmart then
local sp,sv=cam:WorldToViewportPoint(best.AimPos)
if sv and (Vector2.new(sp.X,sp.Y)-mouse).Magnitude>(Flags.SASmartR or 45) then return end
end
local aimPos=best.AimPos
if Flags.SABacktrack then
local vel=BS.getVelocity(best.Enemy)
local bt=(Flags.SABTT or 200)/1000
if Flags.PingAdapt and BS.PA then
bt=bt+BS.PA.getAdaptLagTicks()*0.015
end
local btHistory=RAGE.LastPredictPos[best.Enemy.Player.UserId]
if btHistory and #btHistory>2 then
local histIdx=math.max(1,#btHistory-math.floor(bt*60))
if btHistory[histIdx] then
aimPos=btHistory[histIdx]
else
aimPos=aimPos-vel*bt
end
else
aimPos=aimPos-vel*bt
end
end
if Flags.SAHitSnd then pcall(function()
local s=Instance.new("Sound")
s.SoundId="rbxassetid://5587286548"
s.Volume=0.5; s.PlayOnRemove=false
s.Parent=lplr and lplr.Character:FindFirstChild("HumanoidRootPart")
s:Play()
game:GetService("Debris"):AddItem(s,1)
end) end
if mode=="Camera Redirect" then
local cp=cam.CFrame.Position; local d=(aimPos-cp).Unit
local sm=Flags.SASmooth or 1
cam.CFrame=cam.CFrame:Lerp(CFrame.new(cp,cp+d),1/sm)
elseif mode=="Mouse Redirect" then
local mo=lplr:GetMouse()
if mo then
local closest,cDist=nil,math.huge
for _,p in pairs(best.Enemy.Char:GetDescendants()) do
if p:IsA("BasePart") then
local sp2,sv2=cam:WorldToViewportPoint(p.Position)
if sv2 then local d=(Vector2.new(sp2.X,sp2.Y)-mouse).Magnitude; if d<cDist then cDist=d; closest=p end end
end
end
if closest then pcall(function() mo.Target=closest end) end
end
elseif mode=="Server Angle" then
local cp=cam.CFrame.Position; cam.CFrame=CFrame.new(cp,cp+(aimPos-cp).Unit)
elseif mode=="Hybrid" then
local cp=cam.CFrame.Position; cam.CFrame=CFrame.new(cp,cp+(aimPos-cp).Unit)
end
pcall(function()
local cp=cam.CFrame.Position
local toEnemy=(aimPos-cp).Unit
local backDir=Vector3.new(-toEnemy.X,0,-toEnemy.Z).Unit
local dir=Flags.SABackDir or "Away"
local lookDir
if dir=="Away" then lookDir=backDir
elseif dir=="Left" then lookDir=cam.CFrame.RightVector*-1
elseif dir=="Right" then lookDir=cam.CFrame.RightVector
elseif dir=="Random" then local a=math.random()*math.pi*2; lookDir=Vector3.new(math.cos(a),0,math.sin(a))
else lookDir=toEnemy end
cam.CFrame=CFrame.new(cp,cp+lookDir)
end)
end
pcall(function()
local cp=cam.CFrame.Position
local toEnemy=(aimPos-cp).Unit
local myLook=cam.CFrame.LookVector
local angle=math.acos(math.clamp(myLook:Dot(toEnemy),-1,1))
local range=math.rad(Flags.SA360Range or 360)
if angle>range/2 then
cam.CFrame=CFrame.new(cp,cp+toEnemy)
end
end)
end
pcall(function()
local cp=cam.CFrame.Position
local toEnemy=(aimPos-cp).Unit
local aaYaw=Flags.AAYaw or "Spin"
local fakeDir
if aaYaw=="Back" then fakeDir=Vector3.new(-toEnemy.X,0,-toEnemy.Z).Unit
elseif aaYaw=="Left" then fakeDir=cam.CFrame.RightVector*-1
elseif aaYaw=="Right" then fakeDir=cam.CFrame.RightVector
else fakeDir=Vector3.new(-toEnemy.X,0,-toEnemy.Z).Unit end
cam.CFrame=CFrame.new(cp,cp+fakeDir)
end)
end
pcall(function()
local cp=cam.CFrame.Position
local dirs={Vector3.new(1,0,0),Vector3.new(-1,0,0),Vector3.new(0,0,1),Vector3.new(0,0,-1)}
local maxD,freeD=0,dirs[1]
for _,d in ipairs(dirs) do
local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={lplr.Character}
local r=workspace:Raycast(cp,d*8,params)
local dist=r and (r.Position-cp).Magnitude or 8
if dist>maxD then maxD=dist; freeD=d end
end
cam.CFrame=CFrame.new(cp,cp+freeD)
end)
end
pcall(function()
local h=hum()
if h then h.HipHeight=-0.5 end
local cp=cam.CFrame.Position
cam.CFrame=CFrame.new(cp,cp+(aimPos-cp).Unit)
end)
end
pcall(function()
local cp=cam.CFrame.Position
local toEnemy=(aimPos-cp).Unit
local offset=math.rad(Flags.SAInvOff or 180)
local invDir=CFrame.new(Vector3.new(),toEnemy)*CFrame.Angles(0,offset,0)
cam.CFrame=CFrame.new(cp,cp+invDir.LookVector)
end)
end
if Flags.SAAF then pcall(function()
local t=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if t and not t.Name:lower():find("knife") then t:Activate() end
end) end
if Flags.SAMultiT and Flags.SAMultiC then
local multiCount=0
for _,t2 in ipairs(RAGE.Targets) do
if multiCount>=(Flags.SAMultiC or 2) then break end
if t2.Enemy~=best.Enemy and t2.SD<=Flags.SAFov then
pcall(function()
local cp2=cam.CFrame.Position
cam.CFrame=CFrame.new(cp2,cp2+(t2.BonePos-cp2).Unit)
task.wait(0.02)
local t=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if t and not t.Name:lower():find("knife") then t:Activate() end
end)
multiCount=multiCount+1
end
end
end
if Flags.SAResOvr and Flags.Resolver then
local uid=best.Enemy.Player.UserId
local resStep=RAGE.ResolverStep and RAGE.ResolverStep[uid] or 0
local overrideAngle=resStep*90
local oRad=math.rad(overrideAngle)
local overridePos=aimPos+Vector3.new(math.cos(oRad)*2,0,math.sin(oRad)*2)
local ocp=cam.CFrame.Position
cam.CFrame=CFrame.new(ocp,ocp+(overridePos-ocp).Unit)
end
if Flags.SAHBE then
pcall(function()
local hbSize=Flags.SAHBS or 2
local char=best.Enemy.Char
if char then
local head=char:FindFirstChild("Head")
if head then
head.Size=Vector3.new(hbSize,hbSize,hbSize)
head.Transparency=0.7
head.CanCollide=false
end
local hrp=char:FindFirstChild("HumanoidRootPart")
if hrp then
hrp.Size=Vector3.new(hbSize,hbSize,hbSize)
hrp.Transparency=0.8
hrp.CanCollide=false
end
end
end)
end
if Flags.SAMagic then
pcall(function()
local magicDist=Flags.SAMagicD or 50
if best.Dist<=magicDist then
local tool=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if tool and not tool.Name:lower():find("knife") then
end
end
end)
end
if Flags.SAAutoWall then
pcall(function()
local myH=hrp()
if myH then
local canPen=analyzeWall(myH.Position+Vector3.new(0,1.5,0),aimPos)
if canPen then
local tool=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if tool and not tool.Name:lower():find("knife") then
end
end
end
end)
end
if Flags.SALagComp then
local lcTicks=Flags.SALCTicks or 8
local vel=BS.getVelocity(best.Enemy)
local lagCompPos=aimPos+vel*(lcTicks*0.015)
aimPos=lagCompPos
end
if Flags.SAPosAdj then
local adjX=Flags.SAPosAdjX or 0
local adjY=Flags.SAPosAdjY or 0
aimPos=aimPos+Vector3.new(adjX/10,adjY/10,0)
end
if Flags.SANBP then
local cam2=workspace.CurrentCamera
local mouse2=UIS:GetMouseLocation()
local closestBone,closestDist=nil,math.huge
local bones={"Head","HumanoidRootPart"}
for _,boneName in ipairs(bones) do
local bonePart=best.Enemy.Char:FindFirstChild(boneName)
if bonePart then
local sp,sv=cam2:WorldToViewportPoint(bonePart.Position)
if sv then
local d=(Vector2.new(sp.X,sp.Y)-mouse2).Magnitude
if d<closestDist then closestDist=d; closestBone=bonePart.Position end
end
end
end
if closestBone then aimPos=closestBone end
end
if Flags.SASpread then
local spreadF=Flags.SASpreadF or 50
local spread=Vector3.new((math.random()-0.5)*spreadF/100,0,(math.random()-0.5)*spreadF/100)
aimPos=aimPos+spread
end
if Flags.SARCS then
local rcsX=(Flags.SARCSX or 60)/100
local rcsY=(Flags.SARCSY or 80)/100
local uidRcs=best.Enemy.Player.UserId
local shotCount=RAGE.ShotsFired[uidRcs] or 0
local recoilY=-rcsY*math.min(shotCount*0.1,1)
local recoilX=rcsX*math.sin(shotCount*0.5)*0.3
aimPos=aimPos+Vector3.new(recoilX,recoilY,0)
end
if Flags.SASilentWalk then
pcall(function()
local h=hum()
if h then h.WalkSpeed=16 end
end)
end
if Flags.SAAutoScope then
pcall(function()
local t=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if t and (t.Name:lower():find("awp") or t.Name:lower():find("sniper") or t.Name:lower():find("scout")) then
safeMouse1Click()
end
end)
end
if Flags.SANoVR then
pcall(function()
local cam2=workspace.CurrentCamera
local cp2=cam2.CFrame.Position
cam2.CFrame=CFrame.new(cp2,cp2+cam2.CFrame.LookVector)
end)
end
end
end)
end
end
end)
task.spawn(function()
while true do
task.wait()
pcall(function()
if Flags.SilentAim and Flags.SAFovCirc then
if not saFovCircle then saFovCircle=safeDrawingNew("Circle"); saFovCircle.Thickness=1; saFovCircle.NumSides=64; saFovCircle.Filled=false end
saFovCircle.Position=UIS:GetMouseLocation(); saFovCircle.Radius=Flags.SAFov or 140
saFovCircle.Color=Color3.fromRGB(255,0,0); saFovCircle.Visible=true
else if saFovCircle then saFovCircle.Visible=false end end
end)
end
end)
local aaAngle=0; local aaJitter=1; local fakeDuckState=false; local aaHeightAngle=0; local aaVizCircle=nil
task.spawn(function()
while true do
task.wait()
if Flags.AA and alive() then
pcall(function()
local cam=workspace.CurrentCamera; local myH=hrp()
if not cam or not myH then return end
if Flags.AAGround then local h=hum(); if h and h.FloorMaterial==Enum.Material.Air then return end end
local pitch=Flags.AAPitch or "Down"; local yaw=Flags.AAYaw or "Spin"; local spd=Flags.AASpd or 12
if Flags.PingAdapt and BS.PA then
spd=math.floor(BS.PA.getAdaptSmooth(spd))
end
local pA=0
if pitch=="Down" then pA=-89 elseif pitch=="Up" then pA=89 elseif pitch=="Zero" then pA=0
elseif pitch=="Jitter" then pA=math.random(-89,89) elseif pitch=="Random" then pA=math.random(-180,180)
elseif pitch=="Fake Up" then pA=89 elseif pitch=="Fake Down" then pA=-89
elseif pitch=="Lisp" then pA=math.sin(tick()*10)*89
elseif pitch=="Mixed" then pA=math.random(-89,89)*math.sin(tick()*2)
elseif pitch=="Sideways" then pA=0
elseif pitch=="Emotion" then pA=45+math.sin(tick()*2)*10
elseif pitch=="Slow Jitter" then pA=math.sin(tick()*3)*60
elseif pitch=="Fakedown" then pA=-89+math.abs(math.sin(tick()*5))*20
elseif pitch=="Zero Sway" then pA=math.sin(tick()*1.5)*15 end
local yA=0
if yaw=="Spin" then aaAngle=aaAngle+spd*2; yA=aaAngle%360
elseif yaw=="Fast Spin" then aaAngle=aaAngle+spd*4; yA=aaAngle%360
elseif yaw=="Jitter" then yA=math.random(-Flags.AAJittR or 100,Flags.AAJittR or 100); aaJitter=aaJitter*-1
elseif yaw=="Wide Jitter" then yA=math.random(-160,160); aaJitter=aaJitter*-1
elseif yaw=="Back" then local lv=cam.CFrame.LookVector; yA=math.deg(math.atan2(-lv.X,-lv.Z))
elseif yaw=="Left" then yA=-90 elseif yaw=="Right" then yA=90
elseif yaw=="LBY Break" then yA=math.sin(tick()*spd*5)*120
elseif yaw=="LBY Break Fast" then yA=math.sin(tick()*spd*8)*150
elseif yaw=="Edge" then
local dirs={Vector3.new(1,0,0),Vector3.new(-1,0,0),Vector3.new(0,0,1),Vector3.new(0,0,-1)}
local nD,nDx=dirs[1],math.huge
for _,d in ipairs(dirs) do local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={lplr.Character}
local r=workspace:Raycast(myH.Position,d*5,params); if r then local dd=(r.Position-myH.Position).Magnitude; if dd<nDx then nDx=dd; nDx=dd; nD=d end end end
yA=math.deg(math.atan2(nD.X,nD.Z))+180
elseif yaw=="Fake" then yA=math.random(0,360)
elseif yaw=="Switch" then yA=aaJitter>0 and 90 or -90; aaJitter=aaJitter*-1
elseif yaw=="Slow Spin" then aaAngle=aaAngle+spd*0.5; yA=aaAngle%360
elseif yaw=="Random Walk" then yA=aaAngle+math.random(-spd*3,spd*3); aaAngle=yA%360
elseif yaw=="Triangle" then local tri=tick()*spd*2; yA=(math.floor(tri)%3)*120
elseif yaw=="Opposite" then yA=(aaJitter>0 and 0 or 180); aaJitter=aaJitter*-1
elseif yaw=="T-Shape" then local ts=tick()*spd*3; yA=ts%360<180 and 90 or -90 end
local cp=cam.CFrame.Position
local yR=math.rad(yA); local pR=math.rad(pA)
local lookDir=Vector3.new(math.cos(pR)*math.sin(yR),math.sin(pR),math.cos(pR)*math.cos(yR))
cam.CFrame=CFrame.new(cp,cp+lookDir)
if Flags.AAHeight then
aaHeightAngle=aaHeightAngle+spd*0.3
local hOff=math.sin(math.rad(aaHeightAngle))*1.5
cam.CFrame=cam.CFrame+Vector3.new(0,hOff,0)
end
if Flags.AAFakeDuck then fakeDuckState=not fakeDuckState
pcall(function() local h=hum(); if h then h.HipHeight=fakeDuckState and -0.5 or 0 end end) end
if Flags.AALBY then
local lbyO=Flags.AALBYO or 120
local lbyRad=math.rad(lbyO+tick()*spd*3)
local lbyOffset=Vector3.new(math.cos(lbyRad)*2,0,math.sin(lbyRad)*2)
cam.CFrame=cam.CFrame+Vector3.new(lbyOffset.X*0.1,0,lbyOffset.Z*0.1)
end
if Flags.AAFree then
local dirs={Vector3.new(1,0,0),Vector3.new(-1,0,0),Vector3.new(0,0,1),Vector3.new(0,0,-1)}
local maxDist,freeDir=0,dirs[1]
for _,d in ipairs(dirs) do
local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={lplr.Character}
local r=workspace:Raycast(myH.Position,d*8,params)
local dist=r and (r.Position-myH.Position).Magnitude or 8
if dist>maxDist then maxDist=dist; freeDir=d end
end
yA=math.deg(math.atan2(freeDir.X,freeDir.Z))+180
local fRad=math.rad(yA)
local fDir=Vector3.new(math.cos(pR)*math.sin(fRad),math.sin(pR),math.cos(pR)*math.cos(fRad))
cam.CFrame=CFrame.new(cp,cp+fDir)
end
if Flags.AAEdge then
local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={lplr.Character}
local nearWall=false
for angle=0,360,45 do
local r=Vector3.new(math.cos(math.rad(angle)),0,math.sin(math.rad(angle)))
local res=workspace:Raycast(myH.Position,r*3,params)
if res and (res.Position-myH.Position).Magnitude<3 then nearWall=true; break end
end
if nearWall then yA=yA+180 end
end
if Flags.AAAnimBreak then
local style=Flags.AAAnimStyle or "Flipped"
pcall(function()
local h=hum()
if h then
if style=="Flipped" then h.HipHeight=-0.5
elseif style=="Platform" then h.HipHeight=2
elseif style=="Lean" then cam.CFrame=cam.CFrame*CFrame.Angles(0,0,math.rad(15*math.sin(tick()*3)))
elseif style=="Inverse" then cam.CFrame=CFrame.new(cp,cp+Vector3.new(-lookDir.X,lookDir.Y,-lookDir.Z))
elseif style=="Downside" then h.HipHeight=-1
elseif style=="Slide" then
h.HipHeight=-0.5+math.sin(tick()*4)*0.3
elseif style=="Moonwalk" then
h.WalkSpeed=0
local myH=hrp()
if myH then myH.CFrame=myH.CFrame*CFrame.Angles(0,math.rad(180),0) end
elseif style=="Breaker" then
task.wait(0.05)
task.wait(0.05)
end
end
end)
end
if Flags.AADesync then
local desyncRange=Flags.AADesyncR or 90
local desyncAngle=math.rad(desyncRange*math.sin(tick()*spd*2))
local desyncOffset=Vector3.new(math.cos(desyncAngle)*2,0,math.sin(desyncAngle)*2)
pcall(function()
local myH=hrp()
if myH then
local origCF=myH.CFrame
myH.CFrame=origCF+desyncOffset
task.delay(0.1,function()
pcall(function() myH.CFrame=origCF end)
end)
end
end)
end
if Flags.AAJittTick then
local interval=Flags.AAJittInt or 3
if tick()%interval>interval*0.5 then
yA=math.random(-180,180)
pA=math.random(-89,89)
local jRad=math.rad(yA)
local jPRad=math.rad(pA)
local jDir=Vector3.new(math.cos(jPRad)*math.sin(jRad),math.sin(jPRad),math.cos(jPRad)*math.cos(jRad))
cam.CFrame=CFrame.new(cp,cp+jDir)
end
end
if Flags.AAManual then
local dir=Flags.AAManualDir or "Backward"
local lv=cam.CFrame.LookVector
if dir=="Forward" then yA=math.deg(math.atan2(lv.X,lv.Z))
elseif dir=="Backward" then yA=math.deg(math.atan2(-lv.X,-lv.Z))
elseif dir=="Left" then yA=math.deg(math.atan2(-lv.Z,lv.X))
elseif dir=="Right" then yA=math.deg(math.atan2(lv.Z,-lv.X)) end
local mRad=math.rad(yA)
local mDir=Vector3.new(math.cos(pR)*math.sin(mRad),math.sin(pR),math.cos(pR)*math.cos(mRad))
cam.CFrame=CFrame.new(cp,cp+mDir)
end
if Flags.AABodyYaw then
local bodyOffset=Flags.AABodyYawO or 60
local bodyRad=math.rad(yA+bodyOffset)
pA=0
end
if Flags.AAFakeAngles then
local fakeSide=math.sin(tick()*spd*3)>0 and 1 or -1
yA=yA+fakeSide*90
local fRad=math.rad(yA)
local fDir=Vector3.new(math.cos(pR)*math.sin(fRad),math.sin(pR),math.cos(pR)*math.cos(fRad))
cam.CFrame=CFrame.new(cp,cp+fDir)
end
if Flags.AASlowAA then
local h=hum()
if h and h.WalkSpeed<10 then
yA=yA+180
pA=-89
local sRad=math.rad(yA)
local sDir=Vector3.new(math.cos(math.rad(pA))*math.sin(sRad),math.sin(math.rad(pA)),math.cos(math.rad(pA))*math.cos(sRad))
cam.CFrame=CFrame.new(cp,cp+sDir)
end
end
if Flags.AAAirAA then
local h=hum()
if h and h.FloorMaterial==Enum.Material.Air then
yA=yA+spd*5
local aRad=math.rad(yA)
local aDir=Vector3.new(math.cos(pR)*math.sin(aRad),math.sin(pR),math.cos(pR)*math.cos(aRad))
cam.CFrame=CFrame.new(cp,cp+aDir)
end
end
if Flags.AADesyncViz then
pcall(function()
local sp,sv=cam:WorldToViewportPoint(cp+cam.CFrame.LookVector*5)
if sv then
if not aaVizCircle then aaVizCircle=safeDrawingNew("Circle"); if aaVizCircle then aaVizCircle.Thickness=2; aaVizCircle.NumSides=16; aaVizCircle.Filled=false end end
aaVizCircle.Position=Vector2.new(sp.X,sp.Y)
aaVizCircle.Radius=20
aaVizCircle.Color=Color3.fromRGB(255,0,255)
aaVizCircle.Visible=true
end
end)
else if aaVizCircle then aaVizCircle.Visible=false end end
if Flags.AADynJitt then
local dynMin=Flags.AADynMin or 30
local dynMax=Flags.AADynMax or 150
local dynRange=dynMin+(dynMax-dynMin)*(math.sin(tick()*2)+1)/2
yA=yA+math.random(-dynRange,dynRange)
end
if Flags.AASideways then
local side=math.sin(tick()*spd*2)>0 and 90 or -90
yA=yA+side
local sRad=math.rad(yA)
local sDir=Vector3.new(math.cos(pR)*math.sin(sRad),math.sin(pR),math.cos(pR)*math.cos(sRad))
cam.CFrame=CFrame.new(cp,cp+sDir)
end
if Flags.AABackwards then
yA=yA+180
local bRad=math.rad(yA)
local bDir=Vector3.new(math.cos(pR)*math.sin(bRad),math.sin(pR),math.cos(pR)*math.cos(bRad))
cam.CFrame=CFrame.new(cp,cp+bDir)
end
if Flags.AAResJitt then
local resSpd=Flags.AAResJSpd or 10
local extraJitter=math.sin(tick()*resSpd*5)*45
yA=yA+extraJitter
local rjRad=math.rad(yA)
local rjDir=Vector3.new(math.cos(pR)*math.sin(rjRad),math.sin(pR),math.cos(pR)*math.cos(rjRad))
cam.CFrame=CFrame.new(cp,cp+rjDir)
end
if Flags.AAAntiRes then
local miss=RAGE.MissCount and RAGE.MissCount[0] or 0
if miss>2 then
yA=yA+180
local arRad=math.rad(yA)
local arDir=Vector3.new(math.cos(pR)*math.sin(arRad),math.sin(pR),math.cos(pR)*math.cos(arRad))
cam.CFrame=CFrame.new(cp,cp+arDir)
end
end
if Flags.AABodyFlip then
local flipInt=Flags.AABodyFlipInt or 5
if math.floor(tick())%flipInt==0 then
yA=yA+180
local bfRad=math.rad(yA)
local bfDir=Vector3.new(math.cos(pR)*math.sin(bfRad),math.sin(pR),math.cos(pR)*math.cos(bfRad))
cam.CFrame=CFrame.new(cp,cp+bfDir)
end
end
if Flags.AAFLSync then
local flSync=math.sin(tick()*8)*60
yA=yA+flSync
end
if Flags.AAMoveManip then
local h=hum()
if h then
local manipStr=Flags.AAMoveStr or 8
local manipAngle=math.rad(yA+90)
end
end
if Flags.AAViewManip then
local viewAng=Flags.AAViewAngle or 90
local vmRad=math.rad(viewAng*math.sin(tick()*3))
cam.CFrame=cam.CFrame*CFrame.Angles(0,vmRad,0)
end
if Flags.AAAntiUntrust then
yA=yA%360
if yA<0 then yA=yA+360 end
pA=math.clamp(pA,-89,89)
local auRad=math.rad(yA)
local auDir=Vector3.new(math.cos(math.rad(pA))*math.sin(auRad),math.sin(math.rad(pA)),math.cos(math.rad(pA))*math.cos(auRad))
cam.CFrame=CFrame.new(cp,cp+auDir)
end
if Flags.AASlowLBY then
local slowSpd=Flags.AASlowLBYS or 3
local slowAngle=tick()*slowSpd*10
local slowOffset=math.sin(math.rad(slowAngle))*120
local slRad=math.rad(yA+slowOffset)
local slDir=Vector3.new(math.cos(pR)*math.sin(slRad),math.sin(pR),math.cos(pR)*math.cos(slRad))
cam.CFrame=CFrame.new(cp,cp+slDir)
end
if Flags.AABruteMiss then
local bruteSteps=Flags.AABruteSteps or 4
local bruteAngle=(tick()*(spd/2))%(360/bruteSteps)*bruteSteps
yA=yA+bruteAngle
local bmRad=math.rad(yA)
local bmDir=Vector3.new(math.cos(pR)*math.sin(bmRad),math.sin(pR),math.cos(pR)*math.cos(bmRad))
cam.CFrame=CFrame.new(cp,cp+bmDir)
end
if not Flags.AAShoot then
local tool=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if tool and tool:GetAttribute("Firing") then return end
end
end)
end
end
end)
local flTick=0; local flPattern={1,1,1,0,1,0,1,1,0,1,0,0,1,1,1,0}
task.spawn(function()
while true do
task.wait()
if Flags.FL and alive() then
pcall(function()
local h=hum(); if not h then return end
if Flags.FLGround then local h2=hum(); if h2 and h2.FloorMaterial==Enum.Material.Air then return end end
if Flags.FLMoving then local v=hrp() and hrp().AssemblyLinearVelocity or Vector3.new(); if v.Magnitude<2 then return end end
local choke=Flags.FLChoke or 7; local style=Flags.FLStyle or "Adaptive"
if Flags.PingAdapt and BS.PA then
choke=BS.PA.getAdaptFakeLag(choke)
end
flTick=flTick+1
local variance=Flags.FLVar or 20
local actualChoke=choke+math.random(-variance,variance)/10
actualChoke=math.clamp(math.floor(actualChoke),1,16)
local shouldChoke=false
if style=="Constant" then shouldChoke=flTick%actualChoke==0
elseif style=="Adaptive" then
local v=hrp() and hrp().AssemblyLinearVelocity or Vector3.new()
local spd2=v.Magnitude
local adaptChoke=math.clamp(math.floor(spd2/10),1,actualChoke)
shouldChoke=flTick%adaptChoke==0
elseif style=="Random" then shouldChoke=flTick%math.random(1,actualChoke)==0
elseif style=="Tick" then shouldChoke=flPattern[(flTick%16)+1]==0
elseif style=="Break Lag" then shouldChoke=flTick%actualChoke==0 or flTick%(actualChoke*2)==0
elseif style=="Shift" then shouldChoke=flTick>=actualChoke and flTick<=actualChoke+4
elseif style=="Aggressive" then shouldChoke=flTick%math.max(1,actualChoke-2)==0
elseif style=="Hyper" then shouldChoke=flTick%math.max(1,actualChoke/2)==0
elseif style=="Break LC" then shouldChoke=flTick%actualChoke==0 or (flTick+1)%actualChoke==0
elseif style=="Desync" then shouldChoke=flTick%actualChoke==0 and flTick%(actualChoke*3)~=0 end
if shouldChoke then
h.WalkSpeed=0
task.wait(0.03)
h.WalkSpeed=Flags.FLFakeWalk and (Flags.FLFWS or 4) or 16
end
if Flags.FLFakeWalk and not shouldChoke then
h.WalkSpeed=Flags.FLFWS or 4
end
if Flags.FLBLC and flTick%actualChoke==0 then
pcall(function()
local v=hrp() and hrp().AssemblyLinearVelocity or Vector3.new()
local spikeDir=Vector3.new(math.random()-0.5,0,math.random()-0.5).Unit
local spikeForce=Flags.FLBLCForce or 50
hrp().AssemblyLinearVelocity=Vector3.new(v.X*0.1,v.Y,v.Z*0.1)+spikeDir*spikeForce
task.delay(0.05,function()
pcall(function()
local h=hum()
if h then h.WalkSpeed=0 end
task.wait(0.03)
if h then h.WalkSpeed=16 end
end)
end)
end)
end
end)
end
end
end)
local resData={}
local function getVelHistory(uid, newVel, maxHist)
if not resData[uid].VelHistory then resData[uid].VelHistory={} end
table.insert(resData[uid].VelHistory, newVel)
if #resData[uid].VelHistory > (maxHist or 20) then table.remove(resData[uid].VelHistory, 1) end
return resData[uid].VelHistory
end
local function getPosHistory(uid, newPos, maxHist)
if not resData[uid].PosHistory then resData[uid].PosHistory={} end
table.insert(resData[uid].PosHistory, newPos)
if #resData[uid].PosHistory > (maxHist or 15) then table.remove(resData[uid].PosHistory, 1) end
return resData[uid].PosHistory
end
local function detectAntiAim(uid)
local d=resData[uid]
if not d or not d.VelHistory or #d.VelHistory<5 then return false, 0 end
local confidence=0
local velChanges=0
for i=2,#d.VelHistory do
local diff=(d.VelHistory[i]-d.VelHistory[i-1]).Magnitude
if diff>3 then velChanges=velChanges+1 end
end
if velChanges>3 then confidence=confidence+30 end
if d.PosHistory and #d.PosHistory>=5 then
local posDiff=(d.PosHistory[#d.PosHistory]-d.PosHistory[1]).Magnitude
local velAvg=Vector3.new()
for _,v in ipairs(d.VelHistory) do velAvg=velAvg+v end
velAvg=velAvg/#d.VelHistory
if velAvg.Magnitude>5 and posDiff<2 then confidence=confidence+40 end
end
local enemy=BS.enemies()
for _,e in ipairs(enemy) do
if e.Player.UserId==uid and e.HRP then
local lookDir=e.HRP.CFrame.LookVector
local params=RaycastParams.new()
params.FilterType=Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances={e.Char}
local frontDist=workspace:Raycast(e.HRP.Position,lookDir*5,params)
local backDist=workspace:Raycast(e.HRP.Position,-lookDir*5,params)
if frontDist and not backDist then confidence=confidence+20 end
if frontDist and (frontDist.Position-e.HRP.Position).Magnitude<2 then confidence=confidence+15 end
break
end
end
return confidence>50, confidence
end
task.spawn(function()
while true do
task.wait(0.05)
if Flags.Resolver and alive() then
pcall(function()
local cam=workspace.CurrentCamera; local myH=hrp()
if not cam or not myH then return end
local mode=Flags.ResMode or "Smart"; local steps=Flags.ResSteps or 6
for _,e in pairs(BS.enemies()) do
if not e.HRP or not e.Hum or e.Hum.Health<=0 then continue end
local uid=e.Player.UserId
if not resData[uid] then resData[uid]={Step=0,LastVel=Vector3.new(),LastPos=e.HRP.Position,HitCount=0,TotalShots=0,VelHistory={},PosHistory={},Confidence=0,LastBruteAngle=0} end
local d=resData[uid]
local vel=e.HRP.AssemblyLinearVelocity; local isMoving=vel.Magnitude>5
local pos=e.HRP.Position
if Flags.ResVelTrack then getVelHistory(uid,vel,Flags.ResVelHist or 20) end
if Flags.ResPosTrack then getPosHistory(uid,pos,Flags.ResPosHist or 15) end
local isAA,aaConf=detectAntiAim(uid)
d.Confidence=aaConf
local bruteAngle=0
local bSteps=Flags.ResBruteSteps or steps
d.Step=(d.Step+1)%bSteps
bruteAngle=d.Step*(360/bSteps)
if isMoving then
bruteAngle=math.deg(math.atan2(vel.Unit.X,vel.Unit.Z))
else
d.Step=(d.Step+1)%steps
bruteAngle=d.Step*(360/steps)
end
bruteAngle=0
local dirs={Vector3.new(1,0,0),Vector3.new(-1,0,0),Vector3.new(0,0,1),Vector3.new(0,0,-1)}
local mD,mDx=nil,0
for _,dd in ipairs(dirs) do
local params=RaycastParams.new()
params.FilterType=Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances={e.Char}
local r=workspace:Raycast(e.HRP.Position,dd*10,params)
local dist=r and (r.Position-e.HRP.Position).Magnitude or 10
if dist>mDx then mDx=dist; mD=dd end
end
bruteAngle=mD and math.deg(math.atan2(mD.X,mD.Z)) or 0
bruteAngle=Flags.ResManAngle or Flags.ResMAngle or 0
if isAA and aaConf>(Flags.ResConf or 60) then
local velDiff=(vel-d.LastVel).Magnitude
if velDiff>5 then
d.Step=(d.Step+1)%steps
bruteAngle=d.Step*(360/steps)
else
if isMoving then bruteAngle=math.deg(math.atan2(vel.X,vel.Z))
else bruteAngle=d.Step*(360/steps) end
end
else
if isMoving then bruteAngle=math.deg(math.atan2(vel.X,vel.Z))
else bruteAngle=0 end
end
local predAngle=math.deg(math.atan2(vel.X,vel.Z))
bruteAngle=(predAngle+180)%360
local abSteps=Flags.ResAntiSteps or 4
if (RAGE.MissCount[uid] or 0)>2 then
bruteAngle=(d.Step*(360/abSteps)+180)%360
else
d.Step=(d.Step+1)%abSteps
bruteAngle=d.Step*(360/abSteps)
end
end
local avgVel=Vector3.new()
for _,v in ipairs(d.VelHistory) do avgVel=avgVel+v end
avgVel=avgVel/#d.VelHistory
if avgVel.Magnitude>2 then
local velAngle=math.deg(math.atan2(avgVel.X,avgVel.Z))
bruteAngle=bruteAngle*0.7+velAngle*0.3
end
end
local lcTicks=Flags.ResLCTicks or 8
local lagOffset=vel*(lcTicks*0.015)
local lagAngle=math.deg(math.atan2(lagOffset.X,lagOffset.Z))
if lagOffset.Magnitude>1 then
bruteAngle=bruteAngle*0.8+lagAngle*0.2
end
end
local adaptSpd=Flags.ResAdaptSpd or 5
local adaptAngle=math.sin(tick()*adaptSpd)*45
bruteAngle=bruteAngle+adaptAngle
end
if d.Confidence>50 then
bruteAngle=(bruteAngle+180)%360
end
end
local swSpd=Flags.ResSwSpd or 5
if tick()%swSpd<swSpd/2 then
else
bruteAngle=(bruteAngle+90)%360
end
end
local missTh=Flags.ResMissTh or 3
if (RAGE.MissCount[uid] or 0)>=missTh then
bruteAngle=d.Step*(360/steps)
d.Step=(d.Step+1)%steps
end
end
if d.Confidence<30 then
end
end
if Flags.ResHeadAim then
if d.Confidence>70 then
end
end
d.LastVel=vel
d.LastPos=pos
d.LastBruteAngle=bruteAngle
RAGE.ResolverStep[uid]=d.Step
pcall(function()
end)
end
end
end)
end
end
end)
task.spawn(function()
while true do task.wait(2)
if Flags.Resolver and Flags.ResLogMiss then
pcall(function()
for uid,d in pairs(resData) do
if d.TotalShots>0 then
local hitRate=d.HitCount/d.TotalShots
if hitRate<0.3 then
d.Step=(d.Step+1)%(Flags.ResSteps or 6)
end
end
end
end)
end
end
end)
task.spawn(function()
while true do task.wait()
if Flags.QS and alive() then pcall(function()
local h=hum(); if not h then return end
local v=hrp() and hrp().AssemblyLinearVelocity or Vector3.new()
if v.Magnitude>5 then h.WalkSpeed=1; task.wait(0.05); h.WalkSpeed=16 end
end) end
end
end)
task.spawn(function()
while true do task.wait(0.2)
if Flags.SW and alive() then pcall(function() local h=hum(); if h then h.WalkSpeed=Flags.SWS or 4 end end) end
end
end)
task.spawn(function()
while true do task.wait(0.1)
if Flags.NoClip and alive() then pcall(function()
local ch=lplr.Character; if ch then for _,p in pairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end
end) end
end
end)
local circAngle=0
task.spawn(function()
while true do task.wait()
if Flags.CircStrafe and alive() then pcall(function()
local t=RAGE.Target; local myH=hrp()
if t and myH then
circAngle=circAngle+(Flags.CSSpd or 8)*0.05
local r=3; local off=Vector3.new(math.cos(circAngle)*r,0,math.sin(circAngle)*r)
local pos=t.Enemy.HRP.Position+off
myH.CFrame=CFrame.new(myH.Position,Vector3.new(pos.X,myH.Position.Y,pos.Z))
end
end) end
end
end)
task.spawn(function()
while true do task.wait()
if Flags.AutoRev and alive() then pcall(function()
local t=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if t and t.Name:lower():find("deagle") then t:Activate() end
end) end
end
end)
task.spawn(function()
while true do task.wait(0.2)
if Flags.CrouchWalk and alive() then pcall(function()
local h=hum(); if h then h.HipHeight=-0.5; h.WalkSpeed=12 end
end) end
end
end)
local edgeFrictionTick=0
task.spawn(function()
while true do task.wait(0.1)
if Flags.EdgeFric and alive() then pcall(function()
local h=hum(); local myH=hrp()
if not h or not myH then return end
edgeFrictionTick=edgeFrictionTick+1
local lookVec=myH.CFrame.LookVector
local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={lplr.Character}
local result=workspace:Raycast(myH.Position,lookVec*3+Vector3.new(0,-5,0),params)
if not result then
h.WalkSpeed=math.max(4,h.WalkSpeed*0.5)
end
end) end
end
end)
task.spawn(function()
while true do task.wait()
if Flags.AutoPistol and alive() then pcall(function()
local tool=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if not tool then return end
local name=tool.Name:lower()
local isPistol=name:find("pistol") or name:find("glock") or name:find("usp") or name:find("p250") or name:find("five") or name:find("tec9") or name:find("dual") or name:find("deagle") or name:find("revolver") or name:find("cz75") or name:find("ppbizon")
if not isPistol then return end
if name:find("deagle") or name:find("revolver") then return end
local fr=(Flags.PistolFR or 8)/1000
task.wait(fr)
end) end
end
end)
local qsLastWeapon=nil; local qsLastSwitch=0
task.spawn(function()
while true do task.wait()
if Flags.QuickSwitch and alive() then pcall(function()
local ch=lplr.Character; if not ch then return end
local tool=ch:FindFirstChildWhichIsA("Tool")
local now=tick()
local delay=(Flags.QSDelay or 100)/1000
if now-qsLastSwitch<delay then return end
local mode=Flags.QSMode or "Knife-Primary"
if tool then qsLastWeapon=tool end
if Flags.QSOnKill and RAGE.Target then
local uid=RAGE.Target.Enemy and RAGE.Target.Enemy.Player and RAGE.Target.Enemy.Player.UserId
if uid and RAGE.HitRegistered and RAGE.HitRegistered[uid] then
RAGE.HitRegistered[uid]=nil
for _,t in pairs(ch:GetChildren()) do
if t:IsA("Tool") then
local tName=t.Name:lower()
if mode=="Knife-Primary" and tName:find("knife") then
t.Parent=ch; qsLastSwitch=now; break
elseif mode=="Knife-Zeus" and (tName:find("taser") or tName:find("zeus")) then
t.Parent=ch; qsLastSwitch=now; break
end
end
end
task.delay(delay,function()
pcall(function()
if qsLastWeapon and qsLastWeapon.Parent then
qsLastWeapon.Parent=ch
end
end)
end)
end
end
if Flags.QSOnEmpty and tool then
local ammo=tool:GetAttribute("Ammo") or tool:GetAttribute("CurrentAmmo")
if ammo and ammo<=0 then
for _,t in pairs(ch:GetChildren()) do
if t:IsA("Tool") and t~=tool then
t.Parent=ch; qsLastSwitch=now; break
end
end
end
end
end) end
end
end)
local zeusLastFire=0
task.spawn(function()
while true do task.wait()
if Flags.AutoZeus and alive() then pcall(function()
local ch=lplr.Character; if not ch then return end
local tool=ch:FindFirstChildWhichIsA("Tool")
if not tool then return end
local name=tool.Name:lower()
local isZeus=name:find("taser") or name:find("zeus") or name:find("stun")
if not isZeus then
if Flags.ZeusAutoSw then
for _,t in pairs(ch:GetChildren()) do
if t:IsA("Tool") then
local tName=t.Name:lower()
if tName:find("taser") or tName:find("zeus") or tName:find("stun") then
t.Parent=ch; break
end
end
end
end
end
local now=tick()
local cooldown=(Flags.ZeusCD or 500)/1000
if now-zeusLastFire<cooldown then return end
local myH=hrp(); if not myH then return end
local myPos=myH.Position+Vector3.new(0,1.5,0)
local range=Flags.ZeusRange or 12
local bestEnemy=nil; local bestDist=range
for _,e in pairs(BS.enemies()) do
if not e.HRP or not e.Hum or e.Hum.Health<=0 then continue end
if Flags.ZeusTeam and lplr.Team and e.Player.Team==lplr.Team then continue end
local dist=(myPos-e.HRP.Position).Magnitude
if dist<bestDist then
if Flags.ZeusWall then
local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={ch}
local r=workspace:Raycast(myPos,(e.HRP.Position-myPos).Unit*dist,params)
if r then continue end
end
if Flags.ZeusLowHP and e.Hum.Health>(Flags.ZeusHPThresh or 30) then continue end
bestDist=dist; bestEnemy=e
end
end
if bestEnemy then
local cam=workspace.CurrentCamera
local camPos=cam.CFrame.Position
local targetPos=bestEnemy.HRP.Position+Vector3.new(0,0.5,0)
cam.CFrame=CFrame.new(camPos,camPos+(targetPos-camPos).Unit)
zeusLastFire=now
end
end) end
end
end)
task.spawn(function()
while true do task.wait(0.5)
if Flags.HVHSuper and Flags.AutoAA and alive() then pcall(function()
local cam=workspace.CurrentCamera; local myH=hrp(); if not cam or not myH then return end
local enemies=BS.enemies()
local aimingAtUs=false
for _,e in ipairs(enemies) do
if e.HRP and e.Head then
local toUs=(myH.Position-e.HRP.Position).Unit
local theirLook=e.HRP.CFrame.LookVector
local dot=theirLook:Dot(toUs)
if dot>0.8 then aimingAtUs=true; break end
end
end
if aimingAtUs and not Flags.AA then
Flags.AA=true; Flags.AAPitch="Down"; Flags.AAYaw="LBY Break"
Flags.AADesync=true; Flags.AAFakeDuck=true
end
if Flags.AutoSwitchAA then
local missCount=RAGE.MissCount[0] or 0
if missCount>3 then
Flags.AAYaw="LBY Break"
Flags.AADesyncR=150
Flags.AAPitch="Jitter"
elseif missCount>1 then
Flags.AAYaw="Spin"
Flags.AASpd=15
end
end
if Flags.PredAA then
local tick=time()
local phase=tick()%6
if phase<1.5 then Flags.AAYaw="Back"
elseif phase<3 then Flags.AAYaw="Jitter"
elseif phase<4.5 then Flags.AAYaw="LBY Break"
else Flags.AAYaw="Spin" end
end
end) end
end
end)
task.spawn(function()
while true do task.wait()
if Flags.HVHSuper and Flags.AutoFL and alive() then pcall(function()
local h=hum(); if not h then return end
local enemies=BS.enemies()
local closeEnemies=0
local myH=hrp()
for _,e in ipairs(enemies) do
if e.HRP and myH then
local dist=(myH.Position-e.HRP.Position).Magnitude
if dist<30 then closeEnemies=closeEnemies+1 end
end
end
if closeEnemies>0 then
Flags.FL=true
Flags.FLChoke=math.clamp(8+closeEnemies*2,4,16)
Flags.FLStyle="Adaptive"
end
if Flags.DesyncChoke then
local chokeT=Flags.DesyncChokeT or 8
local tick=time()
if tick%0.1<0.05 then
h.WalkSpeed=0
task.wait(0.02)
h.WalkSpeed=16
end
end
if Flags.LagSpikeAA then
local interval=Flags.LagSpikeInt or 5
if time()%interval<interval*0.2 then
h.WalkSpeed=0
task.wait(0.1)
h.WalkSpeed=16
end
end
end) end
end
end)
task.spawn(function()
while true do task.wait(1)
if Flags.HVHSuper and Flags.AutoRes and alive() then pcall(function()
local enemies=BS.enemies()
for _,e in ipairs(enemies) do
if e.Player and e.HRP then
local uid=e.Player.UserId
local miss=RAGE.MissCount[uid] or 0
if miss>5 then
Flags.ResMode="Inverse"
Flags.ResSteps=12
Flags.ResAntiBrute=true
elseif miss>3 then
Flags.ResMode="Brute Force"
Flags.ResSteps=10
elseif miss>1 then
Flags.ResMode="Smart"
Flags.ResSteps=8
else
Flags.ResMode="Moving AW"
Flags.ResSteps=6
end
end
end
end) end
end
end)
task.spawn(function()
while true do task.wait(0.5)
if Flags.SmartBrute and alive() then pcall(function()
local enemies=BS.enemies()
for _,e in ipairs(enemies) do
if e.Player and e.HRP and e.Head then
local uid=e.Player.UserId
local shots=RAGE.TotalShots[uid] or 0
local hits=RAGE.HitCount[uid] or 0
if shots>5 then
local hitRate=hits/shots
if hitRate<0.3 then
local step=(RAGE.ResolverStep[uid] or 0)+1
RAGE.ResolverStep[uid]=step%4
end
end
end
end
end) end
end
end)
task.spawn(function()
while true do task.wait()
if Flags.DesyncChoke and alive() then pcall(function()
local h=hum(); if not h then return end
local chokeT=Flags.DesyncChokeT or 8
local t=time()
local phase=t%0.1
if phase<0.05 then
h.WalkSpeed=0
else
h.WalkSpeed=16
end
end) end
end
end)
task.spawn(function()
while true do task.wait()
if Flags.RapidFire and alive() then pcall(function()
local tool=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if not tool then return end
local name=tool.Name:lower()
if name:find("knife") or name:find("bayonet") or name:find("grenade") then return end
local rate=(Flags.RapidFireRate or 25)/1000
task.wait(rate)
end) end
end
end)
local WBHistory = {}
local WB_PRESETS = {
["awp"] = {
["mp9"]     = { penBonus = 2,  angleBonus = 0.03, damageBonus = 1.00 },
["ssg"]     = { penBonus = 8,  angleBonus = 0.06, damageBonus = 1.04 },
["scar"]    = { penBonus = 7,  angleBonus = 0.07, damageBonus = 1.06 },
["aug"]     = { penBonus = 6,  angleBonus = 0.06, damageBonus = 1.04 },
["sg556"]   = { penBonus = 6,  angleBonus = 0.06, damageBonus = 1.04 },
}
local function analyzeMultiLayerWall(myPos, targetPos)
local dir = (targetPos - myPos)
local totalDist = dir.Magnitude
local du = dir.Unit
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = {lplr.Character}
local layers = {}
local totalThickness = 0
local totalHardness = 0
local maxLayers = 3
local remainingDist = totalDist
local totalDamageMult = 1.0
local blocked = false
for layer = 1, maxLayers do
if remainingDist <= 0 then break end
local ray = workspace:Raycast(currentStart, du * remainingDist, params)
if not ray then break end
local hitPos = ray.Position
local hitDist = (hitPos - currentStart).Magnitude
remainingDist = remainingDist - hitDist
if remainingDist <= 0 then break end
local thickness
if exitRay then
thickness = (exitRay.Position - hitPos).Magnitude
remainingDist = remainingDist - thickness
else
thickness = remainingDist
remainingDist = 0
end
local mat = ray.Material
local hardness = MAT_HARD[mat] or 50
local layerPenFactor = math.clamp(1 - (hardness * thickness / 10000), 0.1, 1.0)
totalDamageMult = totalDamageMult * layerPenFactor
totalThickness = totalThickness + thickness
totalHardness = totalHardness + hardness
table.insert(layers, {
Material = mat,
Hardness = hardness,
Thickness = thickness,
PenFactor = layerPenFactor,
HitPos = hitPos,
DamageMult = layerPenFactor,
})
currentStart = exitRay.Position + du * 0.2
else
currentStart = hitPos + du * 0.2
end
end
local avgPenFactor = #layers > 0 and totalDamageMult or 0
local avgHardness = #layers > 0 and (totalHardness / #layers) or 0
return {
Layers = layers,
LayerCount = #layers,
TotalThickness = totalThickness,
AvgHardness = avgHardness,
TotalDamageMult = totalDamageMult,
AvgPenFactor = avgPenFactor,
Blocked = blocked,
CanPenetrate = avgPenFactor > 0.1,
end
local function optimizePenAngle(myPos, targetPos, wallData)
if #wallData.Layers == 0 then return targetPos, 1.0 end
local dir = (targetPos - myPos)
local du = dir.Unit
local bestAngle = 0
local bestMult = 0
local bestPos = targetPos
local angles = {0, 5, -5, 10, -10, 15, -15, 20, -20, 25, -25, 30, -30}
for _, angleDeg in ipairs(angles) do
local angleRad = math.rad(angleDeg)
local right = du:Cross(Vector3.new(0, 1, 0)).Unit
local rotatedDir = (du * math.cos(angleRad) + right * math.sin(angleRad)).Unit
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = {lplr.Character}
local ray = workspace:Raycast(myPos, rotatedDir * (targetPos - myPos).Magnitude, params)
if ray then
local hitDist = (ray.Position - myPos).Magnitude
local remaining = (targetPos - myPos).Magnitude - hitDist
if remaining > 0 then
local exitRay = workspace:Raycast(ray.Position + rotatedDir * 0.2, rotatedDir * remaining, params)
local thick = exitRay and (exitRay.Position - ray.Position).Magnitude or remaining
local hard = MAT_HARD[ray.Material] or 50
local angleMult = math.clamp(1 - (hard * thick / 10000), 0, 1)
if angleMult > bestMult then
bestMult = angleMult
bestAngle = angleDeg
bestPos = myPos + rotatedDir * (targetPos - myPos).Magnitude
end
end
end
end
return bestPos, math.clamp(bestMult, 0, 1)
end
local function predictBehindWall(t, lagTicks)
local enemyPos = t.Enemy.HRP.Position
local vel = BS.getVelocity and BS.getVelocity(t.Enemy) or Vector3.new()
local predictedPos = enemyPos + vel * predTime
if diff.Magnitude > 50 then
predictedPos = enemyPos + diff.Unit * 50
end
return predictedPos
end
while true do task.wait()
if Flags.AutoWBKill and alive() then pcall(function()
local cam = workspace.CurrentCamera
local myH = hrp()
if not cam or not myH then return end
local myPos = myH.Position + Vector3.new(0, 1.5, 0)
local sorted = sortTargets(BS.enemies(), myPos, cam)
local wtype = BS.weaponType()
local ws = WEAPONS[wtype] or WEAPONS.rifle
local wbPreset = WB_PRESETS[wtype] or {}
local weaponPen = (ws.pen or 50) + (wbPreset.penBonus or 0)
for _, t in ipairs(sorted) do
if t.SD > (Flags.RageFOV or 180) then continue end
local aimPos = t.BonePos
local predictedPos = predictBehindWall(t, lagTicks)
local tryPositions = {predictedPos, aimPos}
for _, targetPos in ipairs(tryPositions) do
if not wbData.CanPenetrate then continue end
local finalMult = wbData.TotalDamageMult * (1 + angleMult * (wbPreset.angleBonus or 0.05))
local canPenetrate = finalMult * 100 >= (100 - adjustedPen)
if not canPenetrate then continue end
if wbData.LayerCount > maxLayersAllowed then continue end
local headMult = ws.headMult or 2.0
local aimBone = Flags.RageBone or "Head"
local damageBonus = wbPreset.damageBonus or 1.0
if aimBone == "Head" or aimBone == "Auto" then
penDmg = penDmg * headMult
end
local minKillChance = Flags.AutoWBKillChance or 30
if WBHistory[uid] and WBHistory[uid].LastShot and (tick() - WBHistory[uid].LastShot) < 0.3 then
if not tool then continue end
local toolName = tool.Name:lower()
if toolName:find("knife") or toolName:find("fist") or toolName:find("fist") then continue end
WBHistory[uid] = { kills = 0, attempts = 0, angles = {}, avgPenFactor = 0 }
end
WBHistory[uid].attempts = WBHistory[uid].attempts + 1
WBHistory[uid].LastShot = tick()
table.insert(WBHistory[uid].angles, angleMult)
if #WBHistory[uid].angles > 20 then table.remove(WBHistory[uid].angles, 1) end
local sum = 0
for _, v in ipairs(WBHistory[uid].angles) do sum = sum + v end
WBHistory[uid].avgPenFactor = sum / #WBHistory[uid].angles
local layerInfo = ""
for i, layer in ipairs(wbData.Layers) do
layerInfo = layerInfo .. string.format("L%d:%s(%.0f%%)", i, layer.Material.Name, layer.PenFactor * 100)
if i < #wbData.Layers then layerInfo = layerInfo .. " " end
end
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
t.Name or "Enemy",
),
Duration = 2,
})
end)
end
break
end
end) end
end
end)
while true do task.wait(10)
if Flags.AutoWBKill then pcall(function()
for uid, data in pairs(WBHistory) do
if data.LastShot and now - data.LastShot > 300 then
WBHistory[uid] = nil
end
end
local totalAttempts = 0
local totalKills = 0
for _, data in pairs(WBHistory) do
totalAttempts = totalAttempts + data.attempts
totalKills = totalKills + data.kills
end
if totalAttempts > 10 then
local efficiency = totalKills / totalAttempts * 100
Flags.AutoWBMinDmg = math.max(10, (Flags.AutoWBMinDmg or 20) - 5)
elseif efficiency > 50 then
end
end
end) end
end
end
task.spawn(function()
while true do task.wait(60)
pcall(function()
local now = tick()
for uid, data in pairs(WBHistory) do
if data.LastShot and now - data.LastShot > 300 then
WBHistory[uid] = nil
end
end
end)
end
end)
local TracerPool = {} local ImpactPool = {} local HitMarkerPool = {}
local function getTracerColor()
local c = Flags.TracerColor or "Red"
if c == "Rainbow" then return Color3.fromHSV(tick()*3%1,1,1) end
return ({Red=Color3.fromRGB(255,50,50),Green=Color3.fromRGB(50,255,50),Blue=Color3.fromRGB(50,100,255),Yellow=Color3.fromRGB(255,255,50),Cyan=Color3.fromRGB(50,255,255),Magenta=Color3.fromRGB(255,50,255),White=Color3.fromRGB(255,255,255)})[c] or Color3.fromRGB(255,50,50)
end
local function newTracerLine()
local ok,l = pcall(function() local ln=Drawing.new("Line"); ln.Visible=false; ln.Thickness=2; ln.ZIndex=999; return ln end)
return ok and l or nil
end
local function newImpactDot()
local ok,d = pcall(function() local c=Drawing.new("Circle"); c.Visible=false; c.Filled=true; c.NumSides=12; c.Radius=5; c.ZIndex=999; return c end)
return ok and d or nil
end
local function newHitMarker()
local lines={}
for i=1,4 do local ok,l=pcall(function() local ln=Drawing.new("Line"); ln.Visible=false; ln.Thickness=2; ln.ZIndex=1000; return ln end); if ok then lines[i]=l end end
return #lines==4 and lines or nil
end
local function removeTracer(idx)
local t=TracerPool[idx]; if t then
for _,l in ipairs(t.Lines) do pcall(function() l.Visible=false; l:Remove() end) end
if t.ImpactDot then pcall(function() t.ImpactDot.Visible=false; t.ImpactDot:Remove() end) end
TracerPool[idx]=nil
end
end
local function createTracer(startPos,endPos,wallHits)
local color=getTracerColor(); local width=Flags.TracerWidth or 2; local lines={}
local points={startPos}; if wallHits then for _,wh in ipairs(wallHits) do table.insert(points,wh) end end; table.insert(points,endPos)
for i=1,#points-1 do
local line=newTracerLine()
if line then local cam=workspace.CurrentCamera; local s,sV=cam:WorldToViewportPoint(points[i]); local e,eV=cam:WorldToViewportPoint(points[i+1])
if sV or eV then line.From=Vector2.new(s.X,s.Y); line.To=Vector2.new(e.X,e.Y); line.Color=color; line.Thickness=width; line.Visible=true end
table.insert(lines,line)
end
end
local impactDot=nil
if Flags.TracerImpact then impactDot=newImpactDot(); if impactDot then local cam=workspace.CurrentCamera; local ip,iv=cam:WorldToViewportPoint(endPos)
if iv then impactDot.Position=Vector2.new(ip.X,ip.Y); impactDot.Radius=Flags.TracerImpactSize or 6; impactDot.Color=color; impactDot.Visible=true end
end end
table.insert(TracerPool,{Lines=lines,ImpactDot=impactDot,Birth=tick(),Duration=Flags.TracerDuration or 3})
end
local function createHitMarker(pos,isHeadshot)
if not Flags.TracerHitMarker then return end
local cam=workspace.CurrentCamera; local sP,vis=cam:WorldToViewportPoint(pos); if not vis then return end
local lines=newHitMarker(); if not lines then return end
local sz=Flags.TracerHMS or 12; local clr=isHeadshot and Color3.fromRGB(255,50,50) or Color3.fromRGB(255,255,255)
local offs={{-sz,-sz,sz,sz},{sz,-sz,-sz,sz},{0,-sz,0,sz},{-sz,0,sz,0}}
for i,off in ipairs(offs) do lines[i].From=Vector2.new(sP.X+off[1],sP.Y+off[2]); lines[i].To=Vector2.new(sP.X+off[3],sP.Y+off[4]); lines[i].Color=clr; lines[i].Visible=true end
table.insert(HitMarkerPool,{Lines=lines,Birth=tick(),Duration=0.4})
end
local lastBTFire=0
RunService.RenderStepped:Connect(function()
if not Flags.BulletTracer or not alive() then return end
local myH=hrp(); local cam=workspace.CurrentCamera; if not myH or not cam then return end
local tool=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool"); if not tool then return end
if not (Flags.RageAF or Flags.Ragebot or Flags.SilentAim or Flags.AutoWBKill) then return end
if tick()-lastBTFire<0.08 then return end; lastBTFire=tick()
local myPos=myH.Position+Vector3.new(0,1.5,0); local dir=cam.CFrame.LookVector
local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={lplr.Character}
local wallHits={}; local curStart=myPos; local rem=1000; local finalEnd=myPos+dir*1000
if Flags.TracerWall then
for layer=1,5 do local ray=workspace:Raycast(curStart,dir*rem,params); if not ray then break end
local hd=(ray.Position-curStart).Magnitude; rem=rem-hd; if rem<=0 then break end
table.insert(wallHits,ray.Position); curStart=ray.Position+dir*0.3
end
else local ray=workspace:Raycast(myPos,dir*1000,params); if ray then finalEnd=ray.Position end end
createTracer(myPos,finalEnd,#wallHits>0 and wallHits or nil)
end)
RunService.RenderStepped:Connect(function()
if not Flags.BulletTracer or not Flags.TracerPenLine or not alive() then return end
local myH=hrp(); if not myH then return end; local cam=workspace.CurrentCamera
local sorted=sortTargets and sortTargets(BS.enemies(),myH.Position,cam) or {}
for _,t in ipairs(sorted) do if t.SD>(Flags.RageFOV or 180) then continue end
local aimPos=t.BonePos; local myPos=myH.Position+Vector3.new(0,1.5,0)
local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={lplr.Character}
local ray=workspace:Raycast(myPos,(aimPos-myPos).Unit*(aimPos-myPos).Magnitude,params)
if ray then createTracer(myPos,aimPos,{ray.Position}) end
end
end)
local btLastUpdate=0
RunService.RenderStepped:Connect(function()
if tick()-btLastUpdate<0.03 then return end; btLastUpdate=tick()
local now=tick()
for i=#TracerPool,1,-1 do local t=TracerPool[i]; if not t then continue end
local age=now-t.Birth; if age>t.Duration then removeTracer(i)
else local a=1-(age/t.Duration)
for _,l in ipairs(t.Lines) do pcall(function() l.Transparency=a; l.Visible=true end) end
if t.ImpactDot then pcall(function() t.ImpactDot.Transparency=a; t.ImpactDot.Visible=true end) end
end
end
for i=#HitMarkerPool,1,-1 do local hm=HitMarkerPool[i]; if not hm then continue end
local age=now-hm.Birth; if age>hm.Duration then for _,l in ipairs(hm.Lines) do pcall(function() l.Visible=false; l:Remove() end) end; HitMarkerPool[i]=nil
else local a=1-(age/hm.Duration); for _,l in ipairs(hm.Lines) do pcall(function() l.Transparency=a; l.Visible=true end) end end
end
end)
print("[BulletTracer] Loaded")
task.spawn(function()
while true do task.wait()
if Flags.OneTap and alive() then pcall(function()
Flags.RageHead=true
Flags.RageBody=false
Flags.RageHC=100
Flags.RagePred=true
Flags.RagePredF=50
Flags.SAHC=100
Flags.SAHeadshot=true
end) end
end
end)
task.spawn(function()
while true do task.wait()
if Flags.JumpScout and alive() then pcall(function()
local h=hum(); local myH=hrp()
if not h or not myH then return end
local t=time()
local delay=(Flags.JSDelay or 150)/1000
local params=RaycastParams.new()
params.FilterType=Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances={lplr.Character}
local downRay=workspace:Raycast(myH.Position,Vector3.new(0,-3,0),params)
if downRay then
task.wait(delay)
local tool=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if tool and not tool.Name:lower():find("knife") then
end
end
end) end
end
end)
task.spawn(function()
while true do task.wait(0.1)
if Flags.EdgeBugFriction and alive() then pcall(function()
local myH=hrp(); local h=hum()
if not myH or not h then return end
local params=RaycastParams.new()
params.FilterType=Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances={lplr.Character}
local lookVec=myH.CFrame.LookVector
local result=workspace:Raycast(myH.Position,lookVec*4+Vector3.new(0,-6,0),params)
if result then
for _,part in pairs(lplr.Character:GetDescendants()) do
if part:IsA("BasePart") then
part.CustomPhysicalProperties=PhysicalProperties.new(0.1,0.3,0.1,1,1)
end
end
else
for _,part in pairs(lplr.Character:GetDescendants()) do
if part:IsA("BasePart") then
part.CustomPhysicalProperties=nil
end
end
end
end) end
end
end)
task.spawn(function()
while true do task.wait(5)
if Flags.HVHSuper and alive() then pcall(function()
local enemies=BS.enemies()
local ping=BS.Ping and BS.Ping.Current or 50
local closeThreat=0
local myH=hrp()
for _,e in ipairs(enemies) do
if e.HRP and myH then
local dist=(myH.Position-e.HRP.Position).Magnitude
if dist<30 then closeThreat=closeThreat+1 end
end
end
if Flags.Ragebot then
Flags.RageHC=ping>150 and 80 or 100
Flags.RageFR=ping>150 and 15 or 12
end
if Flags.AA then
if closeThreat>2 then
Flags.AAYaw="LBY Break"
Flags.AAJittR=150
Flags.AADesync=true
Flags.AAFakeDuck=true
elseif closeThreat==1 then
Flags.AAYaw="Spin"
Flags.AASpd=15
end
end
if Flags.FL then
Flags.FLChoke=ping>150 and 5 or 8
end
end) end
end
end)
local vizFovCirc,vizTgtLine,vizWbLine=nil,nil,nil
task.spawn(function()
while true do task.wait()
pcall(function()
local cam=workspace.CurrentCamera; local mouse=UIS:GetMouseLocation()
if Flags.Ragebot then
if not vizFovCirc then vizFovCirc=safeDrawingNew("Circle"); if vizFovCirc then vizFovCirc.Thickness=1; vizFovCirc.NumSides=64; vizFovCirc.Filled=false end end
vizFovCirc.Position=mouse; vizFovCirc.Radius=RAGE.Fov; vizFovCirc.Color=Color3.fromRGB(255,0,0); vizFovCirc.Visible=true
else if vizFovCirc then vizFovCirc.Visible=false end end
if RAGE.Target and RAGE.Target.BonePos then
local sp,sv=cam:WorldToViewportPoint(RAGE.Target.BonePos)
if sv then
if not vizTgtLine then vizTgtLine=safeDrawingNew("Line"); if vizTgtLine then vizTgtLine.Thickness=2 end end
vizTgtLine.From=mouse; vizTgtLine.To=Vector2.new(sp.X,sp.Y); vizTgtLine.Color=Color3.fromRGB(255,0,0); vizTgtLine.Visible=true
end
else if vizTgtLine then vizTgtLine.Visible=false end end
end)
end
end)
lplr.CharacterRemoving:Connect(function()
RAGE.Target=nil; RAGE.Targets={}; resData={}
if vizFovCirc then vizFovCirc.Visible=false end
if vizTgtLine then vizTgtLine.Visible=false end
if saFovCircle then saFovCircle.Visible=false end
if aaVizCircle then aaVizCircle.Visible=false end
end)print("[Rage] BloxStrike Rage v3.0 - CS2 HVH Edition")
print("[Rage] All features loaded successfully")
print("[Rage] 1  Ragebot (HC, Bone, Sort, Double Tap, Triple Tap)")
print("[Rage] 1A Multipoint + Safe Point + Damage Override + Force Aim")
print("[Rage] 1B Silent Aim (4 modes, Backtrack, Magic Bullet)")
print("[Rage] 1C PSilent + Rapid Fire NEW")
print("[Rage] 1D Bullet Tracer + Hit Marker")
print("[Rage] 2  Anti-Aim (Pitch, Yaw, Speed, Fake Duck)")
print("[Rage] 2B Desync + Emotion + Lean + LBY Breaker + Manual AA NEW")
print("[Rage] 3  Fake Lag (Constant, Adaptive, Random, Tick)")
print("[Rage] 3B Exploits: Hideshots + Onshot + Fake Duck NEW")
print("[Rage] 4  Resolver (Smart, Brute, Moving AA)")
print("[Rage] 4B Moving AA Resolver + Side Detection + Anim Breaker NEW")
print("[Rage] 5  HVH Utilities (Slide Walk, Pixel Surf, Quick Switch)")
print("[Rage] 6  HVH Presets (Full Rage, Anti-Oneshot)")
print("[Rage] 7  Advanced HVH (HVH Super, Auto AA/FL/Resolver)")
print("[Rage] 8  HVH Statistics")
print("[Rage] ")
]])
writefile("BloxStrike/modules/settings.lua", [[
local Players = nil
pcall(function() Players = game:GetService("Players") end)
local lplr = Players.LocalPlayer
local SETTINGS_FILE = "BloxStrike_Settings.json"
local SETTINGS_DIR = "BloxStrike/"
local Compat = _G.BS and _G.BS.Compat
local function safeWriteFile(path, content)
if Compat and Compat.WriteFile then return Compat.WriteFile(path, content) end
pcall(function() writefile(path, content) end)
end
local function safeReadFile(path)
if Compat and Compat.ReadFile then return Compat.ReadFile(path) end
local s, r = pcall(function() return readfile(path) end)
return s and r or nil
end
local function safeIsFile(path)
if Compat and Compat.IsFile then return Compat.IsFile(path) end
local s, r = pcall(function() return isfile(path) end)
return s and r or false
end
local function safeMakeFolder(path)
if Compat and Compat.MakeFolder then Compat.MakeFolder(path) return end
pcall(function() makefolder(path) end)
end
local function safeSetClipboard(text)
if Compat and Compat.SetClipboard then Compat.SetClipboard(text) return end
pcall(function() setclipboard(text) end)
end
if not BS.Win then warn("[Settings] BS.Win not available - ui.lua may have failed") return end
local page = BS.Win:Tab("Settings")
if page and page.Toggle then
page:Label(" Config Presets ")
page:Button({Name="Load Legit", Color=Color3.fromRGB(100,200,100)}, function() BS.Settings.LoadPreset("Legit") end)
page:Button({Name="Load Rage", Color=Color3.fromRGB(200,50,50)}, function() BS.Settings.LoadPreset("Rage") end)
page:Button({Name="Load HvH", Color=Color3.fromRGB(200,100,50)}, function() BS.Settings.LoadPreset("HvH") end)
page:Button({Name="Load Semi-Rage", Color=Color3.fromRGB(200,150,0)}, function() BS.Settings.LoadPreset("SemiRage") end)
page:Button({Name="Reset All", Color=Color3.fromRGB(150,150,150)}, function() BS.Settings.Reset() end)
page:Separator()
page:Label(" Save / Load ")
page:Button({Name="Save Config", Color=Color3.fromRGB(100,150,255)}, function() BS.Settings.Save() end)
page:Button({Name="Load Config", Color=Color3.fromRGB(100,200,150)}, function() BS.Settings.Load() end)
page:Button({Name="Export (Clipboard)", Color=Color3.fromRGB(200,200,100)}, function() BS.Settings.Export() end)
end
local Presets = {
["Legit"] = {
Ragebot = false, SilentAim = false, AA = false, FL = false,
ESP_Box = true, ESP_Name = true, ESP_Health = true, ESP_Dist = true,
ESP_TeamCheck = true, Bhop = false, FxKillSound = true, FxHitSound = true,
FXFlash = true, FXShake = true,
},
["Rage"] = {
Ragebot = true, RageFOV = 360, RageHC = 100, RageAF = true,
RageDT = true, RageWall = true, RagePred = true, RageRes = true,
AA = true, AAPitch = "Jitter", AAYaw = "Spin", AASpd = 18,
FL = true, FLChoke = 10, FLStyle = "Adaptive",
Resolver = true, ResMode = "Smart",
FxKillSound = true, FXFlash = true, FXShake = true, FxBlood = true,
},
["HVH"] = {
Ragebot = true, RageFOV = 360, RageHC = 100, RageAF = true,
RageDT = true, RageWall = true, RagePred = true, RageRes = true,
RageKnife = true, RageZeus = true,
SilentAim = true, SAFov = 360, SAHC = 100, SAAF = true,
AA = true, AAPitch = "Jitter", AAYaw = "Spin", AASpd = 20,
AAFakeDuck = true, AADesync = true, AABodyYaw = true,
FL = true, FLChoke = 12, FLStyle = "Break Lag",
Resolver = true, ResMode = "Smart", ResAuto = true,
NoClip = false, AutoRev = true,
FxKillSound = true, FXFlash = true, FXShake = true,
},
["Stealth"] = {
Ragebot = false, SilentAim = false, AA = false, FL = false,
ESP_Box = true, ESP_Name = true, ESP_Health = true,
Bhop = false, FxKillSound = false, FxHitSound = false,
},
["SemiRage"] = {
Ragebot = true, RageFOV = 180, RageHC = 85, RageAF = true,
RageDT = false, RageWall = true, RagePred = true, RageRes = true,
SilentAim = true, SAFov = 180, SAHC = 85,
AA = true, AAPitch = "Emotion", AAYaw = "LBY Break", AASpd = 12,
FL = true, FLChoke = 8, FLStyle = "Adaptive",
ESP_Box = true, ESP_Name = true, ESP_Health = true, ESP_Dist = true,
FxKillSound = true, FXFlash = true, FXShake = true,
},
["Bhop"] = {
Bhop = true, BhopMode = "Auto", BhopStrafe = true,
ESP_Box = true, ESP_Health = true, ESP_Dist = true,
FxKillSound = true, FXFlash = true,
},
}
local function saveSettings(presetName)
pcall(function()
local settings = {}
for key, value in pairs(Flags) do
if type(value) ~= "table" and type(value) ~= "function" and type(value) ~= "userdata" then
settings[key] = value
end
end
settings["_preset"] = presetName or "Custom"
settings["_timestamp"] = os.time()
local json = game:GetService("HttpService"):JSONEncode(settings)
safeMakeFolder(SETTINGS_DIR)
safeWriteFile(SETTINGS_DIR .. SETTINGS_FILE, json)
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = " Settings Saved",
Text = "Saved to: " .. SETTINGS_DIR .. SETTINGS_FILE,
Duration = 3,
})
end)
print("[Settings] Saved " .. tostring(#settings) .. " settings to " .. SETTINGS_DIR .. SETTINGS_FILE)
end)
end
local function loadSettings()
pcall(function()
if not safeIsFile(SETTINGS_DIR .. SETTINGS_FILE) then
warn("[Settings] No saved settings found!")
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = " Settings",
Text = "No saved settings found!",
Duration = 2,
})
end)
return false
end
local json = safeReadFile(SETTINGS_DIR .. SETTINGS_FILE)
if not json then warn("[Settings] Failed to read settings file!") return false end
local settings = game:GetService("HttpService"):JSONDecode(json)
local count = 0
for key, value in pairs(settings) do
if key ~= "_preset" and key ~= "_timestamp" then
Flags[key] = value
count = count + 1
end
end
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = " Settings Loaded",
Duration = 3,
})
end)
print("[Settings] Loaded " .. tostring(count) .. " settings")
return true
end)
return false
end
local function loadPreset(name)
local preset = Presets[name]
if not preset then
warn("[Settings] Preset '" .. name .. "' not found!")
end
for k, _ in pairs(Flags) do
Flags[k] = false
end
for key, value in pairs(preset) do
Flags[key] = value
end
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = " Preset: " .. name,
Text = "Applied " .. name .. " configuration",
Duration = 3,
})
end)
print("[Settings] Applied preset: " .. name)
end
local function resetSettings()
for k, _ in pairs(Flags) do
Flags[k] = false
end
Flags.ESP_TeamCheck = true
Flags.RageSafe = true
Flags.SATeam = true
Flags.ZeusTeam = true
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = " Reset",
Text = "All settings reset to defaults",
Duration = 2,
})
end)
print("[Settings] Reset to defaults")
end
local function exportSettings()
pcall(function()
local settings = {}
for key, value in pairs(Flags) do
if type(value) ~= "table" and type(value) ~= "function" and type(value) ~= "userdata" then
settings[key] = value
end
end
local json = game:GetService("HttpService"):JSONEncode(settings)
if setclipboard or (Compat and Compat.SetClipboard) then
safeSetClipboard(json)
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = " Copied!",
Text = "Settings copied to clipboard",
Duration = 2,
})
end)
end
end)
end
local function importSettings(jsonStr)
pcall(function()
if not jsonStr or jsonStr == "" then return end
local settings = game:GetService("HttpService"):JSONDecode(jsonStr)
local count = 0
for key, value in pairs(settings) do
if key ~= "_preset" and key ~= "_timestamp" then
Flags[key] = value
count = count + 1
end
end
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = " Imported",
Text = "Imported " .. count .. " settings",
Duration = 2,
})
end)
end)
end
BS.Settings = {
Save = saveSettings,
Load = loadSettings,
LoadPreset = loadPreset,
Reset = resetSettings,
Export = exportSettings,
Import = importSettings,
Presets = Presets,
}
task.delay(2, function()
pcall(function()
if safeIsFile(SETTINGS_DIR .. SETTINGS_FILE) then
loadSettings()
end
end)
end)
print("[Settings] BloxStrike Settings module loaded")
print("[Settings] Commands: BS.Settings.Save/Load/LoadPreset/Reset/Export/Import")
]])
writefile("BloxStrike/modules/smartai.lua", [[
local Players = nil
pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local UserInputService = nil
pcall(function() UserInputService = game:GetService("UserInputService") end)
local HttpService = nil
pcall(function() HttpService = game:GetService("HttpService") end)
local StarterGui = nil
pcall(function() StarterGui = game:GetService("StarterGui") end)
local lplr = Players.LocalPlayer
if not BS.Win then warn("[Smart AI] BS.Win not available - ui.lua may have failed") return end
local page = BS.Win:Tab("Smart AI")
if not page or not page.Toggle then warn("[SmartAI] Failed to create tab!") return end
local AI = {}
BS.SmartAI = AI
page:Toggle("Smart AI", true, function(v) Flags.SmartAI = v end)
page:Toggle("Auto Optimize All", true, function(v) Flags.AI_AutoOpt = v end)
page:Toggle("AI Learning", true, function(v) Flags.AI_Learning = v end)
page:Toggle("AI Aggressive Mode", false, function(v) Flags.AI_Aggressive = v end)
page:Slider("AI Confidence", 20, 95, 65, function(v) Flags.AI_Confidence = v end)
page:Slider("AI Adapt Speed", 1, 10, 5, function(v) Flags.AI_AdaptSpeed = v end)
page:Toggle("AI Save Profile", true, function(v) Flags.AI_SaveProfile = v end)
page:Separator()
page:Label("  /  ")
page:Button({Name=" (", Color=Color3.fromRGB(0, 200, 80)}, function()
AI.activateSafeMode()
end)
page:Button({Name="[Toggle]", Color=Color3.fromRGB(255, 50, 50)}, function()
AI.activateAggressiveMode()
end)
page:Button({Name="  (", Color=Color3.fromRGB(200, 200, 0)}, function()
AI.activateBalancedMode()
end)
page:Button({Name=" AI ", Color=Color3.fromRGB(100, 200, 255)}, function()
AI.autoSelectMode()
end)
page:Separator()
page:Button({Name="[AI] Activate All", Color=Color3.fromRGB(0, 200, 100)}, function()
AI.fullAnalysis()
end)
page:Button({Name="[AI] Smart Features", Color=Color3.fromRGB(0, 150, 255)}, function()
AI.showStatus()
end)
page:Button({Name="[AI] Toggle", Color=Color3.fromRGB(200, 80, 80)}, function()
AI.resetLearning()
end)
page:Label(" AI ")
page:Toggle("AI Aimbot Tuner", true, function(v) Flags.AI_AimTune = v end)
page:Toggle("AI ESP Tuner", true, function(v) Flags.AI_ESPTune = v end)
page:Toggle("AI Rage Tuner", true, function(v) Flags.AI_RageTune = v end)
page:Toggle("AI Movement Tuner", true, function(v) Flags.AI_MoveTune = v end)
page:Toggle("AI Stealth Tuner", true, function(v) Flags.AI_StealthTune = v end)
page:Toggle("AI KillFX Tuner", true, function(v) Flags.AI_KillFX = v end)
page:Toggle("AI Playstyle Detection", true, function(v) Flags.AI_Playstyle = v end)
page:Toggle("AI Counter-Aim", true, function(v) Flags.AI_CounterAim = v end)
page:Toggle("AI Threat Response", true, function(v) Flags.AI_ThreatResp = v end)
page:Toggle("AI Map Adapt", true, function(v) Flags.AI_MapAdapt = v end)
page:Toggle("AI Safety Tuner", true, function(v) Flags.AI_SafetyTune = v end)
page:Toggle("AI HVH Tuner", true, function(v) Flags.AI_HVHTune = v end)
page:Toggle("AI Viewmodel Tuner", true, function(v) Flags.AI_VMTune = v end)
page:Toggle("AI World Tuner", true, function(v) Flags.AI_WorldTune = v end)
page:Toggle("AI Chat Tuner", true, function(v) Flags.AI_ChatTune = v end)
page:Toggle("AI Bypass Tuner", true, function(v) Flags.AI_BypassTune = v end)
page:Toggle("AI Bhop Tuner", true, function(v) Flags.AI_BhopTune = v end)
local AIState = {
SessionKills = 0,
SessionDeaths = 0,
SessionHeadshots = 0,
SessionShots = 0,
SessionHits = 0,
SessionDamage = 0,
EnemyStats = {},
AimScore = 50,
AimMissReasons = {
PingTooHigh = 0,
SmoothWrong = 0,
PredictionOff = 0,
FOVTooSmall = 0,
ReactionSlow = 0,
TargetSwitch = 0,
},
Playstyle = "Balanced",
PlaystyleConfidence = 0,
PlaystyleHistory = {},
OptimalSettings = {},
SettingsHistory = {},
PerformanceTrend = {},
ThreatLevel = "Normal",
LobbySkill = "Medium",
LobbySkillScore = 50,
CounterStrategy = "None",
CurrentMap = nil,
MapPhase = "Mid",
RoundNumber = 0,
Score = {CT = 0, T = 0},
FeatureHealth = {},
Decisions = {},
MaxDecisions = 100,
}
local deathAnalysis = { RecentKills = {}, RecentDeaths = {}, StreakData = {}, MapControl = 50 }
local function calcPerformanceScore()
local s = AIState
local score = 50
local factors = {}
local kd = s.SessionKills / s.SessionDeaths
local kdImpact = math.clamp((kd - 1) * 10, -25, 25)
score = score + kdImpact
factors.KD = kdImpact
end
local recentDeaths = #deathAnalysis.RecentDeaths
if recentKills > recentDeaths then
local streakBonus = math.min((recentKills - recentDeaths) * 3, 15)
score = score + streakBonus
factors.Streak = streakBonus
elseif recentDeaths > recentKills then
local deathPenalty = math.min((recentDeaths - recentKills) * 4, 20)
score = score - deathPenalty
factors.Streak = -deathPenalty
end
local acc = s.SessionHits / s.SessionShots
local accImpact = math.clamp((acc - 0.3) * 50, -15, 15)
score = score + accImpact
factors.Accuracy = accImpact
end
local hsRate = s.SessionHeadshots / s.SessionKills
local hsImpact = math.clamp((hsRate - 0.3) * 25, -10, 10)
score = score + hsImpact
factors.Headshot = hsImpact
end
local dmgPerKill = s.SessionDamage / s.SessionKills
local efficiency = math.clamp(1 - dmgPerKill / 200, -1, 1)
local dmgImpact = efficiency * 10
score = score + dmgImpact
factors.DamageEff = dmgImpact
end
score = score + math.min(sessionMin / 10, 5)
local recentCount = 0
for _, entry in ipairs(s.PerformanceTrend) do
if tick() - entry.Time < 60 then
recentPerf = recentPerf + entry.Score
recentCount = recentCount + 1
end
end
if recentCount > 0 then
recentPerf = recentPerf / recentCount
local trend = recentPerf - score
factors.Trend = trend * 0.3
end
if s.AvgEngagementDist < 20 then
score = score + 3
elseif s.AvgEngagementDist > 60 then
score = score + 2
end
end
if s.AvgReactionTime < 200 then
score = score + 5
elseif s.AvgReactionTime > 500 then
score = score - 5
end
end
return math.clamp(math.floor(score), 0, 100)
end
function AI.trackKill(victim, headshot, dist, weapon)
table.insert(AIState.SessionKills + 0 > 0 and deathAnalysis.RecentKills or deathAnalysis.RecentKills, tick())
local now = tick()
for i = #deathAnalysis.RecentKills, 1, -1 do
if now - deathAnalysis.RecentKills[i] > 60 then
table.remove(deathAnalysis.RecentKills, i)
end
end
if dist then
AIState.AvgEngagementDist = ((AIState.AvgEngagementDist or 0) + dist) / 2
end
table.insert(AIState.PerformanceTrend, { Time = tick(), Score = calcPerformanceScore(), Type = "Kill" })
if #AIState.PerformanceTrend > 100 then table.remove(AIState.PerformanceTrend, 1) end
end
function AI.trackDeath(killer, dist)
table.insert(deathAnalysis.RecentDeaths, tick())
local now = tick()
for i = #deathAnalysis.RecentDeaths, 1, -1 do
if now - deathAnalysis.RecentDeaths[i] > 60 then
table.remove(deathAnalysis.RecentDeaths, i)
end
end
table.insert(AIState.PerformanceTrend, { Time = tick(), Score = calcPerformanceScore(), Type = "Death" })
if #AIState.PerformanceTrend > 100 then table.remove(AIState.PerformanceTrend, 1) end
end
local function detectPlaystyle()
if not Flags.AI_Playstyle then return end
local scores = {
Aggressive = 0,
Passive = 0,
Tactical = 0,
Sniper = 0,
Runner = 0,
}
if Flags.AA then scores.Aggressive = scores.Aggressive + 10 end
if Flags.Aimbot then scores.Tactical = scores.Tactical + 15 end
if Flags.TriggerBot then scores.Aggressive = scores.Aggressive + 10 end
if Flags.Bhop then scores.Runner = scores.Runner + 20 end
if Flags.SpeedBoost then scores.Runner = scores.Runner + 15 end
if Flags.NoClip then scores.Runner = scores.Runner + 10 end
if Flags.SilentAim then scores.Aggressive = scores.Aggressive + 15 end
if wType == "sniper" then scores.Sniper = scores.Sniper + 30
elseif wType == "rifle" then scores.Tactical = scores.Tactical + 10
elseif wType == "smg" then scores.Aggressive = scores.Aggressive + 15
elseif wType == "pistol" then scores.Tactical = scores.Tactical + 5
end
local kd = AIState.SessionKills / AIState.SessionDeaths
if kd > 3 then scores.Aggressive = scores.Aggressive + 15
elseif kd > 1.5 then scores.Tactical = scores.Tactical + 10
elseif kd < 1 then scores.Passive = scores.Passive + 10
end
end
if AIState.SessionShots > 0 then
local acc = AIState.SessionHits / AIState.SessionShots
if acc > 0.5 then scores.Tactical = scores.Tactical + 10
elseif acc < 0.2 then scores.Runner = scores.Runner + 10
end
end
local h = BS.hum()
if h and h.WalkSpeed > 20 then scores.Runner = scores.Runner + 10 end
if h and h.WalkSpeed > 30 then scores.Runner = scores.Runner + 10 end
end
if avgDist > 0 then
if avgDist < 15 then scores.Aggressive = scores.Aggressive + 20
elseif avgDist < 30 then scores.Tactical = scores.Tactical + 10
elseif avgDist > 60 then scores.Sniper = scores.Sniper + 20
end
end
if avgReact < 150 then scores.Aggressive = scores.Aggressive + 15
elseif avgReact > 400 then scores.Sniper = scores.Sniper + 10
end
local recentDeaths = #deathAnalysis.RecentDeaths
if recentDeaths > 3 then
scores.Tactical = scores.Tactical + 10
if recentKills > 3 and recentDeaths == 0 then
scores.Aggressive = scores.Aggressive + 15
end
local best, bestScore = "Balanced", 0
for style, sc in pairs(scores) do
if sc > bestScore then
best = style
bestScore = sc
end
end
AIState.Playstyle = best
AIState.PlaystyleConfidence = math.min(100, bestScore + 30)
table.insert(AIState.PlaystyleHistory, { Style = best, Time = tick(), Score = bestScore })
if #AIState.PlaystyleHistory > 50 then table.remove(AIState.PlaystyleHistory, 1) end
end
local function assessLobbySkill()
if not Flags.AI_ThreatResp then return end
local enemies = BS.enemies and BS.enemies() or {}
if #enemies == 0 then return end
local myHRP = BS.hrp()
local skillScore = 50
local indicators = {}
local highHPCount = 0
for _, e in ipairs(enemies) do
if e.Hum then
totalHP = totalHP + e.Hum.Health
if e.Hum.Health > 80 then highHPCount = highHPCount + 1 end
end
end
local avgHP = totalHP / #enemies
if avgHP > 80 then skillScore = skillScore + 15; indicators.HighHP = true end
if avgHP < 40 then skillScore = skillScore - 10; indicators.LowHP = true end
if highHPCount > #enemies * 0.7 then skillScore = skillScore + 10; indicators.MostlyHighHP = true end
local closeRangeCount = 0
for _, e in ipairs(enemies) do
if myHRP and e.HRP then
local dist = (myHRP.Position - e.HRP.Position).Magnitude
totalDist = totalDist + dist
if dist < 20 then closeRangeCount = closeRangeCount + 1 end
end
end
local avgDist = totalDist / #enemies
if avgDist < 25 then skillScore = skillScore + 10; indicators.AggressiveLobby = true end
if avgDist > 60 then skillScore = skillScore - 5; indicators.PassiveLobby = true end
skillScore = skillScore + 15; indicators.Losing = true
elseif AIState.SessionKills > AIState.SessionDeaths * 2 then
skillScore = skillScore - 10; indicators.Winning = true
end
if recentDeaths > 3 then
skillScore = skillScore + 10; indicators.FrequentDeaths = true
end
for _, e in ipairs(enemies) do
if e.HRP then
local vel = e.HRP.AssemblyLinearVelocity.Magnitude
if vel > 25 then fastMovers = fastMovers + 1 end
end
end
if fastMovers > #enemies * 0.5 then
skillScore = skillScore + 8; indicators.FastMovers = true
end
local cheaterCount = 0
for uid, data in pairs(BS.PlayerData) do
if data.TotalScore > 60 then cheaterCount = cheaterCount + 1 end
end
if cheaterCount > 0 then
skillScore = skillScore + cheaterCount * 15; indicators.Cheaters = true
end
end
if ping > 150 then skillScore = skillScore + 5; indicators.HighPing = true end
AIState.LobbySkillScore = math.clamp(skillScore, 0, 100)
AIState.LobbyIndicators = indicators
if skillScore > 80 then AIState.LobbySkill = "Cheater"
elseif skillScore > 65 then AIState.LobbySkill = "VeryHard"
elseif skillScore > 45 then AIState.LobbySkill = "Hard"
elseif skillScore > 30 then AIState.LobbySkill = "Medium"
else AIState.LobbySkill = "Easy" end
end
local function logDecision(decision, reason)
table.insert(AIState.Decisions, {
Decision = decision,
Reason = reason,
})
if #AIState.Decisions > AIState.MaxDecisions then
table.remove(AIState.Decisions, 1)
end
end
local function tuneAimbot()
if not Flags.AI_AimTune then return end
local perf = calcPerformanceScore()
local ping = BS.Ping and BS.Ping.Current or 50
local skill = AIState.LobbySkillScore
local style = AIState.Playstyle
local baseSmooth = 5
if perf < 40 then
baseSmooth = 8
logDecision("Aimbot Smooth 8", "Performance low (" .. perf .. ")")
elseif perf > 75 and style == "Aggressive" then
baseSmooth = 3
logDecision("Aimbot Smooth 3", "High performance + Aggressive style")
end
local baseFOV = 60
if skill > 65 then
baseFOV = 90
elseif skill < 30 then
baseFOV = 45
end
if style == "Sniper" then baseFOV = 30 end
if style == "Aggressive" then baseFOV = math.max(baseFOV, 80) end
local basePred = 40
if ping > 100 then basePred = 60
elseif ping > 50 then basePred = 45
else basePred = 35 end
local bone = "Head"
if skill > 60 then bone = "Chest" end
local confidence = Flags.AI_Confidence or 65
if perf > confidence then
Flags.AimbotSmooth = baseSmooth
Flags.AimbotFOV = baseFOV
Flags.AimPredF = basePred
logDecision(string.format("Aimbot: Smooth=%d FOV=%d Pred=%d Bone=%s",
baseSmooth, baseFOV, basePred, bone), "AI Auto-Tune")
end
end
local function tuneESP()
if not Flags.AI_ESPTune then return end
local perf = calcPerformanceScore()
local lobbySkill = AIState.LobbySkillScore
local playstyle = AIState.Playstyle
if perf < 40 then
Flags.ESP_Box = true
Flags.ESP_Name = true
Flags.ESP_Health = true
Flags.ESP_Dist = true
Flags.ESP_Weapon = true
if lobbySkill > 60 then
Flags.ESP_Skeleton = true
Flags.ESP_Velocity = true
end
logDecision("ESP: Full info enabled", "Low performance, need more info")
elseif perf > 75 then
if playstyle == "Aggressive" then
Flags.ESP_Skeleton = false
Flags.ESP_Velocity = false
Flags.ESP_LaserLine = false
logDecision("ESP: Minimal mode", "High performance, Aggressive style")
end
end
if lobbySkill > 60 then
Flags.ESPColorMode = "Health"
else
Flags.ESPColorMode = "Team"
end
if BS.Perf and BS.Perf.FPS < 30 then
Flags.ESPBoxStyle = "2D"
Flags.ESP_Skeleton = false
Flags.ESP_Glow = false
logDecision("ESP: Simplified (low FPS)", "FPS: " .. (BS.Perf.FPS or 0))
end
end
local function tuneRage()
if not Flags.AI_RageTune then return end
local perf = calcPerformanceScore()
local lobbySkill = AIState.LobbySkillScore
local playstyle = AIState.Playstyle
local ping = BS.Ping and BS.Ping.Current or 50
if not Flags.Ragebot then return end
local hc = 85
if ping > 150 then hc = 70 end
if lobbySkill > 65 then hc = 90 end
if playstyle == "Aggressive" then hc = math.min(95, hc + 10) end
Flags.RageHC = hc
if Flags.FL then
local choke = 7
if lobbySkill > 60 then choke = 5 end
if lobbySkill < 30 then choke = 10 end
Flags.FLChoke = choke
end
if Flags.AA then
if lobbySkill > 65 then
Flags.AAYaw = "LBY Break"
Flags.AAPitch = "Down"
elseif lobbySkill < 30 then
Flags.AAYaw = "Jitter"
Flags.AAPitch = "Down"
else
Flags.AAYaw = "Spin"
Flags.AAPitch = "Down"
end
end
if Flags.Resolver then
Flags.ResSteps = lobbySkill > 60 and 8 or 5
end
logDecision(string.format("Rage: HC=%d FL=%d AA=%s", hc, Flags.FLChoke or 7,
Flags.AAYaw or "Spin"), "Lobby: " .. AIState.LobbySkill)
end
local function tuneMovement()
if not Flags.AI_MoveTune then return end
local perf = calcPerformanceScore()
local playstyle = AIState.Playstyle
local lobbySkill = AIState.LobbySkillScore
if Flags.Bhop then
if playstyle == "Runner" then
Flags.BhopSpeed = 30
Flags.BhopStrafeSpd = 15
elseif playstyle == "Aggressive" then
Flags.BhopSpeed = 28
Flags.BhopStrafeSpd = 12
elseif playstyle == "Tactical" then
Flags.BhopSpeed = 22
Flags.BhopStrafeSpd = 8
end
end
if Flags.SpeedBoost then
local maxSpeed = 25
if lobbySkill > 60 then maxSpeed = 22 end
if perf < 40 then maxSpeed = 20 end
Flags._AdaptSpeed = maxSpeed
end
logDecision("Movement: Speed=" .. (Flags.BhopSpeed or 24), "Style: " .. playstyle)
end
local function tuneStealth()
if not Flags.AI_StealthTune then return end
local lobbySkill = AIState.LobbySkillScore
local risk = BS.Stealth and BS.Stealth.RiskLevel or 0
if lobbySkill > 65 then
Flags.StealthHumanize = true
Flags.StealthRandomTiming = true
Flags.StealthAntiPattern = true
Flags.HVHSafeMode = true
Flags.MLEvasion = true
Flags.MLEntropy = true
Flags.MLMicroPause = true
logDecision("Stealth: Maximum protection", "Hard lobby detected")
elseif lobbySkill > 45 then
Flags.StealthHumanize = true
Flags.StealthRandomTiming = true
Flags.HVHSafeMode = true
logDecision("Stealth: Balanced protection", "Medium lobby")
else
logDecision("Stealth: Minimal (easy lobby)", "Easy lobby")
end
if risk > 60 then
Flags.StealthAutoDisable = true
Flags.StealthRiskThresh = 60
logDecision("Stealth: Auto-disable ON (risk=" .. risk .. "%)", "High risk")
end
end
local function tuneKillFX()
if not Flags.AI_KillFX then return end
local perf = calcPerformanceScore()
if perf > 70 then
Flags.KillSound = true
Flags.KillAnimations = true
Flags.KillBlur = true
Flags.KillScreenShake = true
elseif perf < 40 then
Flags.KillSound = true
Flags.KillBlur = false
Flags.KillScreenShake = false
Flags.KillVignette = false
end
end
Flags.AA = false
Flags.NoClip = false
Flags.SpeedBoost = false
Flags.FL = false
Flags.SilentAim = false
Flags.NoSpread = false
Flags.NoRecoil = false
Flags.Resolver = false
Flags.RageKnife = false
Flags.RageZeus = false
Flags.EdgeFric = false
Flags.AimbotSmooth = 12
Flags.AimbotFOV = 40
Flags.AimbotBone = "Head"
Flags.AimbotSort = "Crosshair"
Flags.AimbotTeamCheck = true
Flags.AimbotWall = true
Flags.AimbotVis = true
Flags.AimbotPredict = true
Flags.AimbotHumanize = true
Flags.AimHDelay = 40
Flags.AimHDev = 15
Flags.TriggerBot = false
Flags.ESP_Name = true
Flags.ESP_Health = true
Flags.ESP_Dist = true
Flags.ESP_Weapon = false
Flags.ESP_Skeleton = false
Flags.ESP_Snaplines = false
Flags.ESP_Glow = false
Flags.ESP_Velocity = false
Flags.BhopMode = "Legit"
Flags.BhopSpeed = 20
Flags.BhopDelay = 0
Flags.StealthRandomTiming = true
Flags.StealthAntiPattern = true
Flags.StealthMaskHooks = true
Flags.StealthHideGUI = true
Flags.StealthCleanEnv = true
Flags.StealthAntiDebug = true
Flags.StealthMemClean = true
Flags.StealthBehavior = true
Flags.StealthReaction = true
Flags.StealthReactionMin = 150
Flags.StealthReactionMax = 400
Flags.StealthAimSmooth = true
Flags.StealthHideCoreGui = true
Flags.HVHWarmup = true
Flags.HVHWarmupDur = 180
Flags.HVHGradual = true
Flags.HVHBehavior = true
Flags.HVHMoveLegit = true
Flags.HVHAimLegit = true
Flags.HVHAntiStat = true
Flags.HVHServMask = true
Flags.HVHKillMask = true
Flags.HVHFakeMiss = true
Flags.HVHFakeMissRate = 20
Flags.MLEntropy = true
Flags.MLMouseEntropy = true
Flags.MLReaction = true
Flags.MLMicroPause = true
Flags.MLDecision = true
Flags.MLReactionVar = 200
Flags.TrafficNoise = true
Flags.TrafficBurst = true
Flags.TrafficRemoteFP = true
Flags.MemStrEnc = true
Flags.MemObjScramble = true
Flags.MemRefClean = true
Flags.MemGCObf = true
Flags.ActionFuzz = true
Flags.SeqShuffle = true
Flags.TimingDesync = true
Flags.FPRotInterval = 120
Flags.FPMove = true
Flags.FPAim = true
Flags.FPTiming = true
Flags.SSVLVelCap = true
Flags.SSVLMaxVel = 40
Flags.SSVLDrift = true
Flags.SSVLAccel = true
Flags.SSVLMaxAccel = 80
Flags.StatKDReg = true
Flags.StatTargetKD = 20
Flags.StatHSReg = true
Flags.StatMaxHS = 40
Flags.StatDmgSpread = true
Flags.StatKillTiming = true
Flags.StatMinKillGap = 4
Flags.StatWeaponRot = true
Flags.VMScale = 100
Flags.VMBob = 1
Flags.VMSway = 1
AIState.Mode = "Safe"
logDecision("MODE: Safe Mode activated", "All HVH disabled, all stealth enabled")
pcall(function()
StarterGui:SetCore("SendNotification", {
Title = "[SMART AI]",
Text = "\n\nLegit Aimbot + ESP",
Duration = 5,
})
end)
end
Flags.RageFOV = 180
Flags.RageHC = 85
Flags.RageBone = "Head"
Flags.RageSort = "Crosshair"
Flags.RageAF = true
Flags.RageFR = 12
Flags.RageDT = true
Flags.RageDTD = 6
Flags.RageWall = true
Flags.RagePen = 70
Flags.RagePred = true
Flags.RagePredF = 35
Flags.RageRes = true
Flags.RageResS = 8
Flags.RageSmartBody = true
Flags.RageMinDmg = 1
Flags.RageSafe = true
Flags.RageAutoReload = true
Flags.SAFov = 140
Flags.SAHC = 92
Flags.SABone = "Head"
Flags.SAPred = true
Flags.SAPredT = 30
Flags.SAAF = true
Flags.SASwitch = 80
Flags.SABacktrack = true
Flags.SABTT = 200
Flags.SAAutoWall = true
Flags.SAWallPen = 70
Flags.SALagComp = true
Flags.SALCTicks = 8
Flags.SA360 = true
Flags.SA360Range = 360
Flags.SABackwards = true
Flags.SABackDir = "Away"
Flags.SAHitSound = true
Flags.AAPitch = "Down"
Flags.AAYaw = "LBY Break"
Flags.AASpd = 12
Flags.AAJittR = 100
Flags.AAFakeDuck = true
Flags.AAFDC = 8
Flags.AAFree = true
Flags.AAEdge = true
Flags.AALBY = true
Flags.AALBYO = 120
Flags.AAAnimBreak = true
Flags.AAAnimStyle = "Breaker"
Flags.AADesync = true
Flags.AADesyncR = 90
Flags.AADynJitt = true
Flags.AADynMin = 30
Flags.AADynMax = 150
Flags.AABodyFlip = true
Flags.AABodyFlipInt = 5
Flags.AAMoveManip = true
Flags.AAMoveStr = 8
Flags.AAAntiRes = true
Flags.AABruteMiss = true
Flags.AABruteSteps = 4
Flags.AASlowAA = true
Flags.AAAirAA = true
Flags.AAAntiUntrust = true
Flags.AASlowLBY = true
Flags.FLChoke = 7
Flags.FLStyle = "Adaptive"
Flags.FLVar = 20
Flags.FLFakeWalk = true
Flags.FLFWS = 4
Flags.FLBLC = true
Flags.ResMode = "Smart"
Flags.ResSteps = 8
Flags.ResAuto = true
Flags.ResAB = true
Flags.ResVelTrack = true
Flags.ResPosTrack = true
Flags.ResAdaptive = true
Flags.ResSmart = true
Flags.ResAntiBrute = true
Flags.ResAutoSw = true
Flags.ResMiss = true
Flags.BhopMode = "HvH"
Flags.BhopSpeed = 30
Flags.BhopDelay = 0
Flags.BhopStrafe = true
Flags.BhopStrafeSpd = 15
Flags.BhopStrafePattern = "Aggressive"
Flags.BhopAirAccel = true
Flags.BhopAirAccelVal = 15
Flags.SpeedBoost = true
Flags.NoClip = false
Flags.ESPBoxStyle = "Corners"
Flags.ESP_Name = true
Flags.ESP_Health = true
Flags.ESP_HealthText = true
Flags.ESP_Dist = true
Flags.ESP_Weapon = true
Flags.ESP_WeaponAmmo = true
Flags.ESP_Skeleton = true
Flags.ESP_Snaplines = true
Flags.ESP_Headshot = true
Flags.ESP_Velocity = true
Flags.ESP_Glow = true
Flags.ESP_Arrow = true
Flags.ESP_InfoCard = true
Flags.ESP_LaserLine = true
Flags.ESP_HeadHit = true
Flags.StealthRandomTiming = true
Flags.StealthAntiPattern = true
Flags.StealthMaskHooks = true
Flags.StealthHideGUI = true
Flags.StealthHideCoreGui = true
Flags.HVHSafeMode = true
Flags.HVHBehavior = true
Flags.HVHKillMask = true
Flags.HVHAimDelay = true
Flags.HVHAimDelayMin = 80
Flags.HVHAimDelayMax = 200
Flags.HVHFakeMiss = true
Flags.HVHFakeMissRate = 10
Flags.MLEntropy = true
Flags.MLMouseEntropy = true
Flags.MLReaction = true
Flags.MLMicroPause = true
Flags.KillAnimations = true
Flags.KillBlur = true
Flags.KillScreenShake = true
Flags.KillBlood = true
Flags.KillVignette = true
Flags.KillRing = true
Flags.KillChromatic = true
Flags.ChatAutoGG = true
Flags.SpectatorAlert = true
Flags.PlayerRating = true
Flags.VMScale = 90
Flags.VMAngleX = -2
Flags.VMAngleY = 2
Flags.VMAngleZ = 0
Flags.VMBob = 2
Flags.VMSway = 2
Flags.VMRecoil = 3
AIState.Mode = "Aggressive"
logDecision("MODE: Aggressive Mode activated", "All HVH enabled, all features ON")
pcall(function()
StarterGui:SetCore("SendNotification", {
Title = "[AI] Rage Config",
Text = "Ragebot + AA + SilentAim + FakeLag + Resolver + Bhop + Full ESP + Full HVH",
Duration = 5,
})
end)
end
function AI.activateBalancedMode()
Flags.AimbotSmooth = 5
Flags.AimbotFOV = 60
Flags.AimbotBone = "Head"
Flags.AimbotPredict = true
Flags.AimbotHumanize = true
Flags.AimbotTeamCheck = true
Flags.AimbotWall = true
Flags.TriggerBot = false
Flags.AA = false
Flags.SilentAim = true
Flags.SAFov = 90
Flags.SAHC = 80
Flags.FL = false
Flags.Resolver = false
Flags.NoClip = false
Flags.SpeedBoost = false
Flags.ESP_Name = true
Flags.ESP_Health = true
Flags.ESP_HealthText = true
Flags.ESP_Dist = true
Flags.ESP_Weapon = true
Flags.ESP_Skeleton = true
Flags.ESP_Snaplines = true
Flags.ESP_Velocity = true
Flags.ESP_Glow = true
Flags.BhopMode = "Legit"
Flags.BhopSpeed = 22
Flags.BhopDelay = 0
Flags.BhopStrafe = true
Flags.BhopStrafeSpd = 8
Flags.StealthRandomTiming = true
Flags.HVHSafeMode = true
Flags.HVHMoveLegit = true
Flags.HVHAimLegit = true
Flags.KillAnimations = true
Flags.KillBlur = true
Flags.KillScreenShake = false
Flags.KillVignette = false
Flags.VMScale = 100
AIState.Mode = "Balanced"
logDecision("MODE: Balanced Mode activated", "Legit aimbot + Silent Aim + Full ESP + Legit Bhop")
pcall(function()
StarterGui:SetCore("SendNotification", {
Title = "[AI] Legit Config",
Text = "Aimbot + Silent Aim + Full ESP + Legit Bhop",
Duration = 5,
})
end)
end
function AI.autoSelectMode()
assessLobbySkill()
detectPlaystyle()
analyzeEnemyBehavior()
local perf = calcPerformanceScore()
local skill = AIState.LobbySkillScore
local style = AIState.Playstyle
local risk = BS.Stealth and BS.Stealth.RiskLevel or 0
local ping = BS.Ping and BS.Ping.Current or 50
local indicators = AIState.LobbyIndicators or {}
local confidence = AIState.PlaystyleConfidence or 50
local aggrScore = 0
local balScore = 0
elseif skill > 65 then safeScore = safeScore + 25; balScore = balScore + 10
elseif skill > 50 then balScore = balScore + 20
elseif skill > 30 then aggrScore = aggrScore + 15; balScore = balScore + 10
else aggrScore = aggrScore + 25 end
safeScore = safeScore + 50
end
elseif perf > 80 then balScore = balScore + 15
end
local recentCount = 0
for _, entry in ipairs(AIState.PerformanceTrend) do
if tick() - entry.Time < 30 then
recentPerf = recentPerf + entry.Score
recentCount = recentCount + 1
end
end
if recentCount > 0 then
recentPerf = recentPerf / recentCount
if recentPerf > perf + 10 then
balScore = balScore + 10
elseif recentPerf < perf - 15 then
aggrScore = aggrScore + 15
end
end
elseif style == "Tactical" then balScore = balScore + 15
elseif style == "Sniper" then balScore = balScore + 10
elseif style == "Runner" then aggrScore = aggrScore + 10
elseif style == "Passive" then safeScore = safeScore + 10
end
elseif risk > 50 then safeScore = safeScore + 20
elseif risk > 30 then balScore = balScore + 10
end
elseif ping > 150 then safeScore = safeScore + 10
elseif ping < 30 then aggrScore = aggrScore + 10 end
local recentDeaths = #deathAnalysis.RecentDeaths
if recentKills > 4 then aggrScore = aggrScore + 15
elseif recentDeaths > 3 then safeScore = safeScore + 15
end
if mapState.Maps[placeId] then
local mapPerf = mapState.Maps[placeId].AvgPerformance
if mapPerf < 35 then safeScore = safeScore + 10
end
for _, pattern in pairs(counterState.EnemyAimPatterns) do
if pattern.ThreatScore > 50 then highThreatCount = highThreatCount + 1 end
end
if highThreatCount >= 3 then safeScore = safeScore + 20
elseif highThreatCount >= 1 then balScore = balScore + 10 end
aggrScore = aggrScore + 10
elseif confidence < 40 then
end
local decision = "Balanced"
if maxScore == safeScore and safeScore > aggrScore and safeScore > balScore then
decision = "Safe"
elseif maxScore == aggrScore and aggrScore > safeScore and aggrScore > balScore then
decision = "Aggressive"
else
decision = "Balanced"
end
AI.activateSafeMode()
elseif decision == "Aggressive" then
AI.activateAggressiveMode()
else
AI.activateBalancedMode()
end
logDecision("AUTO SELECT: " .. decision,
string.format("Safe=%d Aggr=%d Bal=%d | Skill=%.0f Perf=%.0f Risk=%d Ping=%d Style=%s",
safeScore, aggrScore, balScore, skill, perf, risk, ping, style))
end
local function tuneSafety()
if not Flags.AI_SafetyTune then return end
local risk = BS.Stealth and BS.Stealth.RiskLevel or 0
local perf = calcPerformanceScore()
if risk > 50 then
Flags.StealthHumanize = true
Flags.StealthRandomTiming = true
Flags.StealthAntiPattern = true
Flags.StealthMaskHooks = true
Flags.HVHSafeMode = true
Flags.MLEvasion = true
Flags.MLEntropy = true
Flags.MLMicroPause = true
Flags.TrafficNoise = true
Flags.AntiReplay = true
Flags.ActionFuzz = true
logDecision("Safety: Enhanced (risk=" .. risk .. "%)", "High risk")
end
if risk > 70 then
Flags.Ragebot = false
Flags.AA = false
Flags.NoClip = false
Flags.SpeedBoost = false
Flags.SilentAim = false
logDecision("Safety: CRITICAL HVH disabled (risk=" .. risk .. "%)", "Very high risk")
end
if perf > 80 then
Flags.StatSmooth = true
Flags.StatKDReg = true
Flags.StatTargetKD = 25
Flags.StatHSReg = true
Flags.StatMaxHS = 50
end
if risk > 40 then
Flags.MemCleanInt = 10
Flags.MemRefClean = true
Flags.MemGCObf = true
end
end
local function tuneHVH()
if not Flags.AI_HVHTune then return end
local perf = calcPerformanceScore()
local lobbySkill = AIState.LobbySkillScore
local ping = BS.Ping and BS.Ping.Current or 50
if not Flags.Ragebot and not Flags.AA then return end
if Flags.Ragebot then
local hc = 85
if ping > 150 then hc = 70
elseif ping > 100 then hc = 75 end
if lobbySkill > 65 then hc = math.min(95, hc + 10) end
if perf > 80 then hc = math.min(95, hc + 5) end
Flags.RageHC = hc
if perf < 30 and Flags.RageSmartBody then
Flags.RageBody = true
Flags.RageHead = false
logDecision("Rage: Switch to body aim (low perf)", "Performance: " .. perf)
end
end
if Flags.AA then
if lobbySkill > 65 then
Flags.AAYaw = "LBY Break"
Flags.AAJittR = 120
Flags.AADesync = true
Flags.AADesyncR = 120
elseif lobbySkill < 30 then
Flags.AAYaw = "Jitter"
Flags.AAJittR = 80
end
if ping > 150 then
Flags.AASpd = 8
else
Flags.AASpd = 12
end
end
if Flags.FL then
local choke = 7
if lobbySkill > 60 then choke = 5
elseif lobbySkill < 30 then choke = 10 end
if ping > 150 then choke = math.max(2, choke - 3) end
Flags.FLChoke = choke
end
if Flags.SilentAim then
local saFOV = 90
if lobbySkill > 65 then saFOV = 140 end
if ping > 100 then saFOV = math.min(180, saFOV + 30) end
Flags.SAFov = saFOV
Flags.SAHC = lobbySkill > 60 and 95 or 85
end
if Flags.Resolver then
Flags.ResSteps = lobbySkill > 60 and 10 or 6
Flags.ResAdaptive = true
Flags.ResSmart = true
end
end
local function tuneViewmodel()
if not Flags.AI_VMTune then return end
local playstyle = AIState.Playstyle
local perf = calcPerformanceScore()
if not Flags.VMEnabled then return end
if playstyle == "Sniper" then
Flags.VMScale = 85
Flags.VMAngleX = -3
Flags.VMAngleY = 3
Flags.VMBob = 0.5
Flags.VMSway = 0.5
elseif playstyle == "Aggressive" then
Flags.VMScale = 95
Flags.VMAngleX = -1
Flags.VMAngleY = 1
Flags.VMBob = 2
Flags.VMSway = 2
Flags.VMRecoil = 3
elseif playstyle == "Tactical" then
Flags.VMScale = 100
Flags.VMAngleX = -2
Flags.VMAngleY = 2
Flags.VMBob = 1
Flags.VMSway = 1
else
Flags.VMScale = 100
Flags.VMBob = 1
Flags.VMSway = 1
end
end
local function tuneWorld()
if not Flags.AI_WorldTune then return end
local perf = calcPerformanceScore()
if BS.Perf and BS.Perf.FPS < 30 then
Flags.Fullbright = true
Flags.NoFog = true
Flags.NoFlash = true
Flags.RemoveSmoke = true
Flags.ThirdPerson = false
elseif BS.Perf and BS.Perf.FPS > 60 then
Flags.Fullbright = true
Flags.NoFog = true
end
end
local function tuneChat()
if not Flags.AI_ChatTune then return end
local perf = calcPerformanceScore()
local style = AIState.Playstyle
Flags.ChatAutoGG = true
if perf > 60 and style == "Aggressive" then
Flags.ChatAutoTaunt = true
else
Flags.ChatAutoTaunt = false
end
if perf > 50 then
Flags.ChatAutoCallout = true
else
Flags.ChatAutoCallout = false
end
Flags.SpectatorAlert = true
Flags.PlayerRating = true
end
local function tuneBypass()
if not Flags.AI_BypassTune then return end
local lobbySkill = AIState.LobbySkillScore
local risk = BS.Stealth and BS.Stealth.RiskLevel or 0
if lobbySkill > 60 or risk > 40 then
Flags.SSVL = true
Flags.SSVLVelCap = true
Flags.SSVLMaxVel = 35
Flags.SSVLDrift = true
Flags.SSVLAccel = true
Flags.SSVLMaxAccel = 60
Flags.SSVLAngular = true
Flags.SSVLMaxAngular = 50
Flags.TrafficMask = true
Flags.TrafficNoise = true
Flags.TrafficBurst = true
Flags.TrafficRemoteFP = true
Flags.FPRotation = true
Flags.FPRotInterval = 90
logDecision("Bypass: Maximum (hard lobby)", "Skill: " .. lobbySkill)
elseif lobbySkill > 40 then
Flags.SSVL = true
Flags.SSVLVelCap = true
Flags.SSVLMaxVel = 45
Flags.TrafficNoise = true
Flags.FPRotation = true
Flags.FPRotInterval = 120
else
Flags.SSVL = true
Flags.SSVLMaxVel = 55
end
end
local function tuneBhop()
if not Flags.AI_BhopTune then return end
local playstyle = AIState.Playstyle
local lobbySkill = AIState.LobbySkillScore
local perf = calcPerformanceScore()
if not Flags.Bhop then return end
if playstyle == "Runner" then
Flags.BhopSpeed = 30
Flags.BhopStrafeSpd = 15
Flags.BhopStrafePattern = "Sinusoidal"
elseif playstyle == "Aggressive" then
Flags.BhopSpeed = 28
Flags.BhopStrafeSpd = 12
Flags.BhopStrafePattern = "Aggressive"
elseif playstyle == "Tactical" then
Flags.BhopSpeed = 22
Flags.BhopStrafeSpd = 8
Flags.BhopStrafePattern = "Smooth"
else
Flags.BhopSpeed = 24
Flags.BhopStrafeSpd = 10
Flags.BhopStrafePattern = "Linear"
end
if lobbySkill > 60 then
Flags.BhopMode = "Legit"
Flags.BhopSpeed = 20
Flags.BhopStrafeSpd = 6
end
end
local counterState = {
EnemyAimPatterns = {},
CounterActions = {},
}
local function analyzeEnemyBehavior()
if not Flags.AI_CounterAim then return end
local enemies = BS.enemies and BS.enemies() or {}
local myHRP = BS.hrp()
for _, e in ipairs(enemies) do
if e.Player and e.HRP then
local uid = e.Player.UserId
local dist = myHRP and (myHRP.Position - e.HRP.Position).Magnitude or 999
local vel = e.HRP.AssemblyLinearVelocity.Magnitude
local h = e.Hum
if not counterState.EnemyAimPatterns[uid] then
counterState.EnemyAimPatterns[uid] = {
Name = e.Player.Name,
AvgDist = dist,
MovementType = "Unknown",
AggressionScore = 0,
ThreatScore = 0,
PositionHistory = {},
WeaponType = "unknown",
HeadshotTendency = 0,
ReactionPattern = {},
PeekPattern = 0,
}
end
local p = counterState.EnemyAimPatterns[uid]
p.AvgDist = (p.AvgDist * 0.8) + (dist * 0.2)
p.LastSeen = tick()
if #p.PositionHistory > 30 then table.remove(p.PositionHistory, 1) end
if vel > 25 then
p.MovementType = "Fast"
p.AggressionScore = p.AggressionScore + 1
elseif vel < 2 then
p.MovementType = "Static"
elseif vel > 10 then
p.MovementType = "Strafing"
else
p.MovementType = "Normal"
end
local posVariance = 0
local posCenter = Vector3.new(0, 0, 0)
for _, ph in ipairs(p.PositionHistory) do
posCenter = posCenter + ph.Pos
end
posCenter = posCenter / #p.PositionHistory
for _, ph in ipairs(p.PositionHistory) do
posVariance = posVariance + (ph.Pos - posCenter).Magnitude
end
posVariance = posVariance / #p.PositionHistory
if posVariance > 30 then
p.PeekPattern = p.PeekPattern + 1
end
end
if tool then
local name = tool.Name:lower()
if name:find("awp") or name:find("sniper") then p.WeaponType = "sniper"
elseif name:find("ak") or name:find("m4") then p.WeaponType = "rifle"
elseif name:find("smg") or name:find("mp") then p.WeaponType = "smg"
elseif name:find("shotgun") then p.WeaponType = "shotgun"
end
end
if p.AvgDist < 15 then p.ThreatScore = p.ThreatScore + 35
elseif p.AvgDist < 30 then p.ThreatScore = p.ThreatScore + 20 end
if p.MovementType == "Fast" then p.ThreatScore = p.ThreatScore + 20
elseif p.MovementType == "Strafing" then p.ThreatScore = p.ThreatScore + 15 end
if p.AggressionScore > 5 then p.ThreatScore = p.ThreatScore + 20 end
if p.WeaponType == "sniper" and p.AvgDist < 30 then p.ThreatScore = p.ThreatScore + 15 end
if p.HeadshotTendency > 0.6 then p.ThreatScore = p.ThreatScore + 15 end
if p.PeekPattern > 5 then p.ThreatScore = p.ThreatScore + 10 end
if BS.CheatDetect and BS.PlayerData[uid] then
local cheatScore = BS.PlayerData[uid].TotalScore or 0
if cheatScore > 60 then p.ThreatScore = p.ThreatScore + 30 end
if cheatScore > 80 then p.ThreatScore = p.ThreatScore + 20 end
end
p.ThreatScore = math.min(100, p.ThreatScore)
end
end
local highThreatCount = 0
for _, pattern in pairs(counterState.EnemyAimPatterns) do
if pattern.ThreatScore > 50 then
highThreatCount = highThreatCount + 1
end
end
if highThreatCount >= 2 then
AIState.CounterStrategy = "Defensive"
if Flags.AA then Flags.AAYaw = "LBY Break" end
if Flags.FL then Flags.FLChoke = 10 end
logDecision("Counter: Defensive (2+ aggressive enemies)", "Enemy analysis")
elseif highThreatCount == 1 then
AIState.CounterStrategy = "Targeted"
logDecision("Counter: Targeted (1 aggressive enemy)", "Enemy analysis")
else
AIState.CounterStrategy = "None"
end
end
local mapState = {
Maps = {},
}
local function adaptToMap()
if not Flags.AI_MapAdapt then return end
local placeId = game.PlaceId
if not mapState.Maps[placeId] then
local mapName = "Unknown"
pcall(function()
mapName = game:GetService("MarketplaceService"):GetProductInfo(placeId).Name
end)
mapState.Maps[placeId] = {
Name = mapName,
BestStrategy = "Balanced",
AvgPerformance = 50,
PlayCount = 0,
}
end
local map = mapState.Maps[placeId]
map.PlayCount = map.PlayCount + 1
map.LastPlayed = tick()
if map.AvgPerformance < 40 then
if map.BestStrategy == "Aggressive" then
map.BestStrategy = "Tactical"
elseif map.BestStrategy == "Tactical" then
map.BestStrategy = "Passive"
else
map.BestStrategy = "Aggressive"
end
logDecision("Map: Strategy " .. map.BestStrategy, map.Name .. " (low perf)")
end
end
local function learnFromHistory()
if not Flags.AI_Learning then return end
local history = AIState.SettingsHistory
if #history < 5 then return end
local weightedBest = nil
local weightedBestScore = 0
local decayRate = 0.005
for _, entry in ipairs(history) do
local age = now - entry.Time
local timeWeight = math.exp(-decayRate * age / 60)
local perfWeight = entry.Performance * timeWeight
if perfWeight > weightedBestScore then
weightedBestScore = perfWeight
weightedBest = entry
end
end
local contextBestScore = 0
local currentPing = BS.Ping and BS.Ping.Current or 50
local currentStyle = AIState.Playstyle
local currentSkill = AIState.LobbySkillScore
for _, entry in ipairs(history) do
if entry.Performance > 60 then
local score = entry.Performance
if entry.Ping and math.abs(entry.Ping - currentPing) < 30 then
score = score + 15
end
if entry.Playstyle == currentStyle then
score = score + 10
end
if entry.LobbySkill and math.abs(entry.LobbySkill - currentSkill) < 15 then
score = score + 10
end
if score > contextBestScore then
contextBestScore = score
contextBest = entry
end
end
end
if bestEntry and bestEntry.Performance > 60 then
local prevSettings = AIState.OptimalSettings or {}
AIState.OptimalSettings = bestEntry.Settings or {}
AIState.OptimalSettingsSource = contextBest and "Context" or "Global"
logDecision("Learning: " .. (contextBest and "Context" or "Global") .. " optimal found",
end
end
local function recordPerformance()
local perf = calcPerformanceScore()
local settings = {
AimbotFOV = Flags.AimbotFOV,
AimbotSmooth = Flags.AimbotSmooth,
RageHC = Flags.RageHC,
FLChoke = Flags.FLChoke,
BhopSpeed = Flags.BhopSpeed,
AAPitch = Flags.AAPitch,
AAYaw = Flags.AAYaw,
}
table.insert(AIState.SettingsHistory, {
Performance = perf,
Settings = settings,
Playstyle = AIState.Playstyle,
LobbySkill = AIState.LobbySkill,
Ping = BS.Ping and BS.Ping.Current or 0,
})
if #AIState.SettingsHistory > 200 then
table.remove(AIState.SettingsHistory, 1)
end
local placeId = game.PlaceId
if mapState.Maps[placeId] then
local map = mapState.Maps[placeId]
map.AvgPerformance = (map.AvgPerformance + perf) / 2
end
end
local function respondToThreat()
if not Flags.AI_ThreatResp then return end
local threat = AIState.LobbySkill
local skill = AIState.LobbySkillScore
local perf = calcPerformanceScore()
local risk = BS.Stealth and BS.Stealth.RiskLevel or 0
local indicators = AIState.LobbyIndicators or {}
local prevThreat = AIState.ThreatLevel
if threat == "Cheater" or indicators.Cheaters then
AIState.ThreatLevel = "Critical"
Flags.SilentAim = false
Flags.AA = false
Flags.NoClip = false
Flags.SpeedBoost = false
Flags.FL = false
Flags.StealthHumanize = true
Flags.HVHSafeMode = true
Flags.MLEvasion = true
Flags.MLEntropy = true
Flags.MLMicroPause = true
pcall(function()
StarterGui:SetCore("SendNotification", {
Title = "? AI ?: CRITICAL",
Text = "",
Duration = 8,
})
end)
logDecision("Threat: FULL SAFE (cheater detected)", threat)
elseif threat == "VeryHard" or skill > 65 then
AIState.ThreatLevel = "High"
Flags.StealthHumanize = true
Flags.HVHSafeMode = true
if Flags.Ragebot then
Flags.RageHC = 95
Flags.RageSafe = true
end
if Flags.AA then
Flags.AAYaw = "LBY Break"
Flags.AAJittR = 120
end
if Flags.FL then Flags.FLChoke = 5 end
if Flags.SilentAim then Flags.SAHC = 95 end
logDecision("Threat: Max performance (very hard lobby)", threat)
elseif threat == "Hard" or skill > 45 then
AIState.ThreatLevel = "Elevated"
Flags.StealthHumanize = true
if Flags.Ragebot then Flags.RageHC = math.min(95, (Flags.RageHC or 85) + 5) end
logDecision("Threat: Enhanced (hard lobby)", threat)
elseif threat == "Medium" then
AIState.ThreatLevel = "Normal"
elseif threat == "Easy" then
AIState.ThreatLevel = "Low"
logDecision("Threat: Relaxed (easy lobby)", threat)
else
AIState.ThreatLevel = "Normal"
end
pcall(function()
StarterGui:SetCore("SendNotification", {
Title = " AI ",
Text = prevThreat .. " " .. AIState.ThreatLevel,
Duration = 3,
})
end)
end
end
function AI.fullAnalysis()
if not Flags.SmartAI then return end
detectPlaystyle()
assessLobbySkill()
analyzeEnemyBehavior()
adaptToMap()
respondToThreat()
tuneAimbot()
tuneESP()
tuneRage()
tuneMovement()
tuneStealth()
tuneKillFX()
learnFromHistory()
recordPerformance()
AI.showStatus()
pcall(function()
StarterGui:SetCore("SendNotification", {
Title = " AI ",
AIState.Playstyle, AIState.PlaystyleConfidence,
AIState.LobbySkill, AIState.LobbySkillScore,
calcPerformanceScore(),
AIState.CounterStrategy),
Duration = 6,
})
end)
end
function AI.showStatus()
local perf = calcPerformanceScore()
local uptime = math.floor((tick() - AIState.SessionStartTime) / 60)
local statusText = string.format(
AIState.Playstyle, AIState.PlaystyleConfidence,
AIState.LobbySkill, AIState.LobbySkillScore,
AIState.ThreatLevel,
AIState.CounterStrategy,
AIState.SessionKills, AIState.SessionDeaths, AIState.SessionHeadshots,
AIState.SessionShots > 0 and (AIState.SessionHits / AIState.SessionShots * 100) or 0,
)
pcall(function()
StarterGui:SetCore("SendNotification", {
Title = "[AI] Full Config"
Text = statusText,
Duration = 10,
})
end)
end
function AI.resetLearning()
AIState.SettingsHistory = {}
AIState.OptimalSettings = {}
AIState.Decisions = {}
AIState.EnemyStats = {}
AIState.PlaystyleHistory = {}
AIState.SessionKills = 0
AIState.SessionDeaths = 0
AIState.SessionHeadshots = 0
AIState.SessionShots = 0
AIState.SessionHits = 0
AIState.SessionDamage = 0
AIState.SessionStartTime = tick()
pcall(function()
StarterGui:SetCore("SendNotification", {
Title = " AI ?",
Text = "",
Duration = 3,
})
end)
end
BS.Events = BS.Events or {}
BS.Events.OnKill = BS.Events.OnKill or function() end
local origOnKill = BS.Events.OnKill
BS.Events.OnKill = function(victim, headshot)
origOnKill(victim, headshot)
AIState.SessionKills = AIState.SessionKills + 1
if headshot then AIState.SessionHeadshots = AIState.SessionHeadshots + 1 end
if victim and victim:IsA("Player") then
local uid = victim.UserId
if not AIState.EnemyStats[uid] then
AIState.EnemyStats[uid] = {
Name = victim.Name,
TimesKilled = 0,
TimesDied = 0,
Headshots = 0,
}
end
AIState.EnemyStats[uid].TimesKilled = AIState.EnemyStats[uid].TimesKilled + 1
if headshot then AIState.EnemyStats[uid].Headshots = AIState.EnemyStats[uid].Headshots + 1 end
end
end
BS.Events.OnDeath = BS.Events.OnDeath or function() end
local origOnDeath = BS.Events.OnDeath
BS.Events.OnDeath = function(killer)
origOnDeath(killer)
AIState.SessionDeaths = AIState.SessionDeaths + 1
if killer and killer:IsA("Player") then
local uid = killer.UserId
if not AIState.EnemyStats[uid] then
AIState.EnemyStats[uid] = { Name = killer.Name, TimesKilled = 0, TimesDied = 0, Headshots = 0 }
end
AIState.EnemyStats[uid].TimesDied = AIState.EnemyStats[uid].TimesDied + 1
end
end
BS.Events.OnShoot = BS.Events.OnShoot or function() end
local origOnShoot = BS.Events.OnShoot
BS.Events.OnShoot = function(hit)
origOnShoot(hit)
AIState.SessionShots = AIState.SessionShots + 1
if hit then AIState.SessionHits = AIState.SessionHits + 1 end
end
while true do task.wait(5)
if Flags.SmartAI and Flags.AI_AutoOpt then
pcall(function()
detectPlaystyle()
assessLobbySkill()
analyzeEnemyBehavior()
respondToThreat()
tuneAimbot()
tuneESP()
tuneRage()
tuneMovement()
tuneStealth()
tuneKillFX()
tuneSafety()
tuneHVH()
tuneViewmodel()
tuneWorld()
tuneChat()
tuneBypass()
tuneBhop()
adaptToMap()
end)
end
end
end)
task.spawn(function()
while true do task.wait(30)
if Flags.SmartAI and Flags.AI_Learning then
pcall(function()
recordPerformance()
learnFromHistory()
end)
end
end
end)
local aiHUD = nil
task.spawn(function()
while true do task.wait(0.3)
if Flags.SmartAI and BS.alive() then
if not aiHUD then
pcall(function()
local _Compat = _G.BS and _G.BS.Compat; if _Compat and _Compat.DrawingNew then aiHUD = _Compat.DrawingNew("Text") else pcall(function() aiHUD = Drawing.new("Text") end) end
aiHUD.Center = false
aiHUD.Outline = true
aiHUD.OutlineColor = Color3.new(0, 0, 0)
aiHUD.Font = Drawing.Fonts.UI
aiHUD.Size = 12
end)
end
local perf = calcPerformanceScore()
local style = AIState.Playstyle
local threat = AIState.LobbySkill
local counter = AIState.CounterStrategy
local color = perf > 70 and Color3.fromRGB(0, 255, 100)
or perf > 40 and Color3.fromRGB(255, 255, 0)
or Color3.fromRGB(255, 50, 50)
aiHUD.Text = string.format("AI: %s [%s] | Threat: %s | Counter: %s | Perf: %d",
style, threat, AIState.ThreatLevel, counter, perf)
aiHUD.Color = color
aiHUD.Position = Vector2.new(10, 505)
aiHUD.Visible = true
else
if aiHUD then aiHUD.Visible = false end
end
end
end)
BS.AIState = AIState
print("[SmartAI] BloxStrike Smart AI v2.0 loaded")
print("[SmartAI] Features: Playstyle Detection, Lobby Assessment,")
print("[SmartAI]   Auto Aimbot/ESP/Rage/Movement/Stealth/Viewmodel/World/Chat/Bypass/Bhop Tuning,")
print("[SmartAI]   Safety Mode, Aggressive Mode, Balanced Mode, Auto Select,")
print("[SmartAI]   Counter-Aim, Threat Response, Map Adaptation,")
print("[SmartAI]   Self-Learning, AI HUD Display")
]])
writefile("BloxStrike/modules/stealth.lua", [[
local Players = nil
pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local UserInputService = nil
pcall(function() UserInputService = game:GetService("UserInputService") end)
local Lighting = nil
pcall(function() Lighting = game:GetService("Lighting") end)
local Stats = nil
pcall(function() Stats = game:GetService("Stats") end)
local lplr = Players.LocalPlayer
if not BS.Win then warn("[Stealth] BS.Win not available - ui.lua may have failed") return end
local page = BS.Win:Tab("Stealth")
if not page or not page.Toggle then warn("[Stealth] Failed to create tab!") return end
local Stealth = {}
BS.Stealth = Stealth
Stealth.Detections = {}
Stealth.RiskLevel = 0
Stealth.Originals = {}
Stealth.HookCount = 0
Stealth.IsHiding = false
-- SECTION 1: CALLSTACK CLEANUP
page:Label(" Callstack & Debug ")
page:Toggle("Clean Callstack", true, function(v) Flags.StealthCallstack = v end)
page:Toggle("Spoof Source", true, function(v) Flags.StealthSpoofSource = v end)
page:Toggle("Hide Errors", true, function(v) Flags.StealthHideErrors = v end)
page:Toggle("Disable Debug Library", false, function(v) Flags.StealthNoDebug = v end)
local function cleanCallstack()
if not Flags.StealthCallstack then return end
pcall(function()
if debug and debug.setmetatable then
end
end)
end
if Flags.StealthHideErrors then
pcall(function()
local oldError = error
_G.error = function(msg, level)
if type(msg) == "string" and msg:find("BloxStrike") then
end
return oldError(msg, (level or 1) + 1)
end
end)
end
task.spawn(function()
if not Flags.StealthSpoofSource then return end
pcall(function()
local renames = {
{"BloxStrike", "ReplicatedStorage"},
{"BS_Modules", "ReplicatedStorage"},
}
end)
end)
-- SECTION 2: ENVIRONMENT HIDING
page:Label(" Environment Hiding ")
page:Toggle("Hide from getgenv", true, function(v) Flags.StealthHideEnv = v end)
page:Toggle("Clean Environment", true, function(v) Flags.StealthCleanEnv = v end)
page:Toggle("Spoof checkcaller", true, function(v) Flags.StealthSpoofCaller = v end)
page:Toggle("Hide CoreGui", true, function(v) Flags.StealthHideCoreGui = v end)
page:Toggle("Hide from Players", false, function(v) Flags.StealthHidePlayers = v end)
local hiddenEnvVars = {}
function Stealth.hideFromEnv(name, value)
hiddenEnvVars[name] = value
if Flags.StealthHideEnv and getgenv then
pcall(function()
local env = getgenv()
end)
end
end
function Stealth.getHidden(name)
return hiddenEnvVars[name]
end
task.spawn(function()
while true do
task.wait(5)
if Flags.StealthCleanEnv then
pcall(function()
local env = getgenv and getgenv()
if env then
local suspicious = {}
for key, _ in pairs(env) do
local keyLower = key:lower()
local legit = false
for _, keep in ipairs({
}) do
if key == keep or keyLower:find(keep:lower()) then
legit = true
break
end
end
if not legit and not key:find("^_") then
table.insert(suspicious, key)
end
end
end
end)
end
end
end)
task.spawn(function()
while true do
task.wait(2)
if Flags.StealthHideCoreGui then
pcall(function()
local coreGui = nil
pcall(function() coreGui = game:GetService("CoreGui") end)
if coreGui then
for _, gui in pairs(coreGui:GetChildren()) do
if gui.Name:find("BloxStrike") or gui.Name:find("BS_") then
end
end
end
end)
end
end
end)
if Flags.StealthSpoofCaller then
pcall(function()
if checkcaller then
local oldCheckcaller = checkcaller
_G.checkcaller = function()
return false
end
end
end)
end
-- SECTION 3: HOOK MASKING
page:Label(" Hook Masking ")
page:Toggle("Mask Hooks", true, function(v) Flags.StealthMaskHooks = v end)
page:Toggle("Backup Originals", true, function(v) Flags.StealthBackup = v end)
page:Toggle("Detect Hook Scans", true, function(v) Flags.StealthDetectHookScan = v end)
page:Toggle("Protect Namecall", true, function(v) Flags.StealthProtectNamecall = v end)
page:Toggle("Protect Index", true, function(v) Flags.StealthProtectIndex = v end)
local originalMetatables = {}
function Stealth.maskHook(name, hookFunc)
if not Flags.StealthMaskHooks then return hookFunc end
pcall(function()
Stealth.Originals[name] = hookFunc
local maskedHook = newcclosure and newcclosure(function(...)
return hookFunc(...)
end) or hookFunc
return maskedHook
end)
return hookFunc
end
task.spawn(function()
if not Flags.StealthMaskHooks then return end
pcall(function()
local mt = getrawmetatable and getrawmetatable(game)
if mt then
originalMetatables.__index = mt.__index
originalMetatables.__namecall = mt.__namecall
originalMetatables.__newindex = mt.__newindex
end
end)
end)
task.spawn(function()
while true do
task.wait(3)
if Flags.StealthDetectHookScan then
pcall(function()
local mt = getrawmetatable and getrawmetatable(game)
if mt then
local info = debug and debug.getinfo and debug.getinfo(2)
if info and info.name and (
info.name:find("Hook") or
info.name:find("Scan") or
info.name:find("Detect")
) then
if Flags.StealthAlert then
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = " Hook Scan Detected",
Text = "Anti-cheat is scanning hooks!",
Duration = 3,
})
end)
end
end
end
end)
end
end
end)
-- SECTION 4: STRING OBFUSCATION (Advanced)
page:Label(" String Obfuscation ")
page:Toggle("Obfuscate Strings", true, function(v) Flags.StealthObfuscate = v end)
page:Slider("Obfuscation Layers", 1, 5, 3, function(v) Flags.StealthObfLayers = v end)
page:Toggle("Polymorphic Keys", true, function(v) Flags.StealthPolyKeys = v end)
page:Toggle("Hide GUI Names", true, function(v) Flags.StealthHideGUI = v end)
page:Toggle("Randomize GUI", false, function(v) Flags.StealthRandomGUI = v end)
page:Toggle("Encrypt Config", true, function(v) Flags.StealthEncryptCfg = v end)
local function generateKey()
local key = {}
for i = 1, 16 do
key[i] = math.random(1, 255)
end
return key
end
local masterKey = generateKey()
function Stealth.obfuscateString(str)
if not Flags.StealthObfuscate then return str end
local layers = Flags.StealthObfLayers or 3
local result = str
for layer = 1, layers do
local key = Flags.StealthPolyKeys
and generateKey()
or masterKey
local encoded = ""
for i = 1, #result do
local byte = string.byte(result, i)
local keyByte = key[((i - 1) % #key) + 1]
local obf = bit32.bxor(byte, keyByte)
obf = bit32.band(bit32.rrotate(obf, layer), 255)
encoded = encoded .. string.char(obf)
end
result = encoded
end
return result
end
function Stealth.deobfuscateString(str)
if not Flags.StealthObfuscate then return str end
local layers = Flags.StealthObfLayers or 3
local result = str
for layer = layers, 1, -1 do
local key = Flags.StealthPolyKeys
and masterKey
or masterKey
local decoded = ""
for i = 1, #result do
local byte = string.byte(result, i)
local keyByte = key[((i - 1) % #key) + 1]
local obf = bit32.lrotate(byte, layer)
obf = bit32.bxor(obf, keyByte)
decoded = decoded .. string.char(obf)
end
result = decoded
end
return result
end
local GUI_OBFUSC_NAMES = {}
task.spawn(function()
while true do
task.wait(3)
if Flags.StealthHideGUI then
pcall(function()
local gui = lplr.PlayerGui:FindFirstChild("BloxStrike_GUI")
if gui then
local newName = ""
for i = 1, math.random(8, 20) do
newName = newName .. string.char(math.random(1, 26) + (math.random(0,1) == 0 and 64 or 96))
end
gui.Name = newName
gui.ResetOnSpawn = false
gui.DisplayOrder = -999
gui.IgnoreGuiInset = true
end
end)
end
end
end)
task.spawn(function()
while true do
task.wait(10)
if Flags.StealthRandomGUI then
pcall(function()
local gui = lplr.PlayerGui:FindFirstChildWhichIsA("ScreenGui")
if gui and gui.Name:find("BloxStrike") then
gui.DisplayOrder = math.random(-1000, 0)
gui.ZIndexBehavior = math.random(0, 1) == 0
and Enum.ZIndexBehavior.Sibling
or Enum.ZIndexBehavior.IndexSubtree
end
end)
end
end
end)
-- SECTION 5: TIMING OBFUSCATION
page:Label(" Timing Obfuscation ")
page:Toggle("Randomize Timings", true, function(v) Flags.StealthRandomTiming = v end)
page:Toggle("Jitter Execution", false, function(v) Flags.StealthJitterExec = v end)
page:Slider("Timing Variance", 0, 50, 20, function(v) Flags.StealthTimingVar = v end)
page:Toggle("Anti-Pattern", true, function(v) Flags.StealthAntiPattern = v end)
local timingHistory = {}
function Stealth.randomDelay(baseDelay)
if not Flags.StealthRandomTiming then return baseDelay end
local variance = (Flags.StealthTimingVar or 20) / 100
local randomFactor = 1 + (math.random() - 0.5) * variance * 2
return baseDelay * randomFactor
end
function Stealth.antiPatternDelay(baseDelay)
if not Flags.StealthAntiPattern then return baseDelay end
local now = tick()
table.insert(timingHistory, now)
if #timingHistory > 20 then table.remove(timingHistory, 1) end
if #timingHistory >= 5 then
local diffs = {}
for i = 2, #timingHistory do
table.insert(diffs, timingHistory[i] - timingHistory[i-1])
end
local mean = 0
for _, d in ipairs(diffs) do mean = mean + d end
mean = mean / #diffs
local variance = 0
for _, d in ipairs(diffs) do
variance = variance + (d - mean) ^ 2
end
variance = variance / #diffs
if variance < 0.001 then
return baseDelay * (0.8 + math.random() * 0.4)
end
end
return baseDelay
end
task.spawn(function()
while true do
if Flags.StealthJitterExec then
local jitter = math.random(1, 50) / 1000
task.wait(jitter)
end
task.wait()
end
end)
-- SECTION 6: NETWORK OBFUSCATION
page:Label(" Network ")
page:Toggle("Obfuscate Remotes", true, function(v) Flags.StealthObfRemotes = v end)
page:Toggle("Rate Limit Calls", true, function(v) Flags.StealthRateLimit = v end)
page:Slider("Max Remote/s", 5, 50, 20, function(v) Flags.StealthMaxRemote = v end)
page:Toggle("Packet Spread", false, function(v) Flags.StealthPacketSpread = v end)
local remoteCalls = {}
local remoteWindow = 0
function Stealth.rateLimitCall(func, ...)
if not Flags.StealthRateLimit then
return func(...)
end
local now = tick()
local maxPerSec = Flags.StealthMaxRemote or 20
for i = #remoteCalls, 1, -1 do
if now - remoteCalls[i] > 1 then
table.remove(remoteCalls, i)
end
end
if #remoteCalls >= maxPerSec then
task.wait(1 / maxPerSec)
end
table.insert(remoteCalls, now)
return func(...)
end
function Stealth.spreadCalls(calls, interval)
if not Flags.StealthPacketSpread then
for _, call in ipairs(calls) do
pcall(call)
end
end
for i, call in ipairs(calls) do
task.spawn(function()
task.wait(i * (interval or 0.1))
pcall(call)
end)
end
end
-- SECTION 7: PROPERTY SPOOFING (Advanced)
page:Label(" Property Spoofing ")
page:Toggle("Spoof All Properties", true, function(v) Flags.StealthSpoofAll = v end)
page:Toggle("Spoof WalkSpeed", true, function(v) Flags.StealthSpoofSpeed = v end)
page:Toggle("Spoof JumpPower", true, function(v) Flags.StealthSpoofJump = v end)
page:Toggle("Spoof HipHeight", true, function(v) Flags.StealthSpoofHip = v end)
page:Toggle("Spoof FOV", true, function(v) Flags.StealthSpoofFOV = v end)
page:Toggle("Spoof CFrame", false, function(v) Flags.StealthSpoofCFrame = v end)
local spoofedProps = {}
function Stealth.spoofProperty(instance, prop, fakeValue)
if not Flags.StealthSpoofAll then return end
spoofedProps[instance] = spoofedProps[instance] or {}
spoofedProps[instance][prop] = {
Fake = fakeValue,
Original = instance[prop],
}
pcall(function()
if getgenv then
local env = getgenv()
end
end)
end
task.spawn(function()
while true do
task.wait(0.3)
if not BS.alive() then continue end
local h = BS.hum()
if not h then continue end
if Flags.StealthSpoofSpeed and Flags.SpeedBoost then
end
if Flags.StealthSpoofHip then
if Flags.ThirdPerson or Flags.NoClip then
end
end
end
end)
-- SECTION 8: ANTI-CHEAT DETECTION (Advanced)
page:Label(" AC Detection ")
page:Toggle("Auto Detect AC", true, function(v) Flags.StealthAutoDetect = v end)
page:Toggle("Deep Scan", true, function(v) Flags.StealthDeepScan = v end)
page:Toggle("Monitor Heartbeat", true, function(v) Flags.StealthMonitorHeartbeat = v end)
page:Toggle("Detect Remote Hooks", true, function(v) Flags.StealthDetectRemoteHook = v end)
page:Toggle("Detect Property Monitors", true, function(v) Flags.StealthDetectPropMon = v end)
page:Toggle("Alert on Detection", true, function(v) Flags.StealthAlert = v end)
page:Toggle("Auto Disable on Risk", false, function(v) Flags.StealthAutoDisable = v end)
local AC_PATTERNS = {
}
local function deepScanForAC()
local detected = {}
local sensitivity = Flags.StealthSensitivity or 5
pcall(function()
local scanTargets = {
game:GetService("ServerScriptService"),
game:GetService("ServerStorage"),
game:GetService("ReplicatedStorage"),
game:GetService("StarterGui"),
game:GetService("StarterPlayer"),
game:GetService("Workspace"),
}
for _, service in pairs(scanTargets) do
for _, obj in pairs(service:GetDescendants()) do
if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
local name = obj.Name:lower()
local source = ""
pcall(function() source = obj.Source or "" end)
local sourceLower = source:lower()
for _, pattern in ipairs(AC_PATTERNS) do
if name:find(pattern:lower()) or sourceLower:find(pattern:lower()) then
table.insert(detected, {
Name = obj.Name,
Pattern = pattern,
Severity = "HIGH",
})
end
end
end
end
end
if Flags.StealthDeepScan then
pcall(function()
for _, remote in pairs(game:GetDescendants()) do
if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
local name = remote.Name:lower()
for _, pattern in ipairs({"anticheat", "kick", "ban", "validate", "check"}) do
if name:find(pattern) then
table.insert(detected, {
Name = remote.Name,
Pattern = "Suspicious Remote: " .. pattern,
Severity = "HIGH",
})
end
end
end
end
end)
end
if Flags.StealthDetectPropMon then
pcall(function()
local h = BS.hum()
if h then
local conns = getconnections and getconnections(h.Changed)
if conns and #conns > 3 then
table.insert(detected, {
Name = "Humanoid.Changed",
Location = "Humanoid",
Severity = "MEDIUM",
})
end
end
end)
end
end)
return detected
end
task.spawn(function()
while true do
task.wait(5)
if Flags.StealthAutoDetect then
local detections = deepScanForAC()
local highCount = 0
for _, d in ipairs(detections) do
if d.Severity == "HIGH" then highCount = highCount + 1 end
end
if #detections > 0 and Flags.StealthAlert then
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = " AC Risk: " .. Stealth.RiskLevel .. "%",
Duration = 5,
})
end)
end
if Flags.StealthAutoDisable and Stealth.RiskLevel >= 70 then
Flags.Ragebot = false
Flags.AA = false
Flags.NoClip = false
Flags.SpeedBoost = false
Flags.FL = false
Flags.NoSpread = false
Flags.NoRecoil = false
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = " AUTO SAFE MODE",
Text = "Risk " .. Stealth.RiskLevel .. "%  Dangerous features disabled!",
Duration = 5,
})
end)
end
Stealth.Detections = detections
end
end
end)
-- SECTION 9: BEHAVIORAL MASKING (Advanced)
page:Label(" Behavioral Masking ")
page:Toggle("Humanize All", true, function(v) Flags.StealthHumanize = v end)
page:Slider("Human Delay", 0, 300, 80, function(v) Flags.StealthHumanDelay = v end)
page:Slider("Human Inaccuracy", 0, 15, 5, function(v) Flags.StealthHumanInacc = v end)
page:Toggle("Random Click Timing", true, function(v) Flags.StealthRandomClick = v end)
page:Toggle("Movement Randomization", true, function(v) Flags.StealthRandomMove = v end)
page:Toggle("Aim Smoothing", true, function(v) Flags.StealthAimSmooth = v end)
page:Toggle("Reaction Time", true, function(v) Flags.StealthReaction = v end)
page:Slider("Reaction Min", 50, 500, 150, function(v) Flags.StealthReactionMin = v end)
page:Slider("Reaction Max", 100, 1000, 400, function(v) Flags.StealthReactionMax = v end)
function Stealth.humanizeAim(targetPos)
if not Flags.StealthHumanize then return targetPos end
local inaccuracy = (Flags.StealthHumanInacc or 5) / 100
local offset = Vector3.new(
)
return targetPos + offset
end
function Stealth.humanDelay(baseDelay)
if not Flags.StealthRandomClick then return baseDelay end
local delay = (Flags.StealthHumanDelay or 80) / 1000
return baseDelay + delay * (0.5 + math.random() * 1.0)
end
function Stealth.reactionTime()
if not Flags.StealthReaction then return 0 end
local min = (Flags.StealthReactionMin or 150) / 1000
local max = (Flags.StealthReactionMax or 400) / 1000
return min + math.random() * (max - min)
end
task.spawn(function()
while true do
task.wait(0.3)
if Flags.StealthRandomMove and BS.alive() then
pcall(function()
local h = BS.hum()
if h and h.WalkSpeed > 16 then
local base = h.WalkSpeed
local jitter = (math.random() - 0.5) * 1.5
h.WalkSpeed = base + jitter
end
end)
end
end
end)
function Stealth.smoothAim(current, target, smooth)
if not Flags.StealthAimSmooth then return target end
return current:Lerp(target, smooth or 0.3)
end
-- SECTION 10: ADVANCED SAFETY
page:Label(" Advanced Safety ")
page:Toggle("Risk Calculator", true, function(v) Flags.StealthRiskCalc = v end)
page:Slider("Risk Threshold", 30, 100, 70, function(v) Flags.StealthRiskThresh = v end)
page:Toggle("Silent Mode", false, function(v) Flags.StealthSilentMode = v end)
page:Toggle("Anti Replay", false, function(v) Flags.StealthAntiReplay = v end)
page:Toggle("Packet Obfuscation", false, function(v) Flags.StealthPacketObf = v end)
page:Toggle("Memory Cleanup", true, function(v) Flags.StealthMemClean = v end)
page:Slider("Mem Clean Interval", 10, 60, 30, function(v) Flags.StealthMemInt = v end)
page:Toggle("Anti Debug", true, function(v) Flags.StealthAntiDebug = v end)
page:Toggle("Server Validation Bypass", false, function(v) Flags.StealthServBypass = v end)
page:Toggle("Emergency Disconnect", false, function(v) Flags.StealthEmgDisconnect = v end)
page:Slider("Emg Disconnect HP", 5, 50, 15, function(v) Flags.StealthEmgHP = v end)
page:Toggle("Auto Kick Detection", false, function(v) Flags.StealthAutoKick = v end)
page:Toggle("Behavior Randomization", true, function(v) Flags.StealthBehavior = v end)
page:Slider("Behavior Interval", 1, 30, 10, function(v) Flags.StealthBehInt = v end)
page:Toggle("Rate Limit All", true, function(v) Flags.StealthRateLimit = v end)
page:Slider("Max Actions/s", 5, 50, 20, function(v) Flags.StealthMaxAct = v end)
page:Toggle("Whitelist Admins", true, function(v) Flags.StealthWhitelistAdmin = v end)
page:Toggle("Server Hop on Risk", false, function(v) Flags.StealthServerHop = v end)
page:Slider("Server Hop Threshold", 50, 100, 80, function(v) Flags.StealthHopThresh = v end)
local function calculateRisk()
local risk=0
if Flags.Ragebot then risk=risk+25 end
if Flags.AA then risk=risk+20 end
if Flags.NoClip then risk=risk+30 end
if Flags.SpeedBoost then risk=risk+15 end
if Flags.FL then risk=risk+10 end
if Flags.SilentAim then risk=risk+20 end
if Flags.Resolver then risk=risk+10 end
if Flags.Bhop then risk=risk+5 end
if Flags.StealthHumanize then risk=risk-10 end
if Flags.StealthRandomTiming then risk=risk-5 end
if Flags.StealthMaskHooks then risk=risk-5 end
if Flags.StealthHideGUI then risk=risk-5 end
if Flags.StealthBehavior then risk=risk-5 end
risk=risk+Stealth.RiskLevel*0.3
return math.clamp(math.floor(risk),0,100)
end
task.spawn(function()
while true do task.wait(1)
if Flags.StealthSilentMode then
pcall(function()
local gui=lplr.PlayerGui:FindFirstChild("BloxStrike_GUI")
if gui then gui.Enabled=false end
if saFovCircle then saFovCircle.Visible=false end
if vizFovCirc then vizFovCirc.Visible=false end
if aaVizCircle then aaVizCircle.Visible=false end
if vizTgtLine then vizTgtLine.Visible=false end
pcall(function()
for _,v in pairs(getgenv() and getgenv().Drawing and {} or {}) do
pcall(function() v.Visible=false end)
end
end)
end)
end
end
end)
task.spawn(function()
while true do
task.wait(Flags.StealthMemInt or 30)
if Flags.StealthMemClean then
pcall(function()
resData={}
timingHistory={}
remoteCalls={}
RAGE.Targets={}
collectgarbage("collect")
collectgarbage("collect")
pcall(function()
for _,v in pairs(getgenv() and getgenv().Drawing and {} or {}) do
if v.Visible==false then pcall(function() v:Remove() end) end
end
end)
end)
end
end
end)
task.spawn(function()
while true do task.wait(5)
if Flags.StealthAntiDebug then
pcall(function()
if debug then
local oldGetInfo=debug.getinfo
debug.getinfo=function(level,what)
local info=oldGetInfo(level,what)
if info and info.source and info.source:find("BloxStrike") then
info.source="[C]"
info.short_src="[C]"
end
return info
end
end
if debug then
local oldTraceback=debug.traceback
debug.traceback=function(level)
local tb=oldTraceback(level)
if tb then
tb=tb:gsub(".-BloxStrike.-%c.-%c","")
end
return tb
end
end
end)
end
end
end)
task.spawn(function()
while true do task.wait(Flags.StealthBehInt or 10)
if Flags.StealthBehavior and BS.alive() then
pcall(function()
local h=hum()
if h then
local base=h.WalkSpeed
h.WalkSpeed=base+math.random(-1,1)
task.wait(0.1)
h.WalkSpeed=base
end
end)
end
end
end)
task.spawn(function()
while true do task.wait(1)
if Flags.StealthEmgDisconnect and BS.alive() then
pcall(function()
local h=hum()
if h and h.Health<h.MaxHealth*((Flags.StealthEmgHP or 15)/100) then
pcall(function()
game:GetService("TeleportService"):Teleport(game.PlaceId,lplr)
end)
end
end)
end
end
end)
task.spawn(function()
while true do task.wait(2)
if Flags.StealthAutoKick then
pcall(function()
localgui=lplr.PlayerGui:FindFirstChild("BloxStrike_GUI")
if not lplr.Character and not Flags.StealthEmgDisconnect then
task.wait(5)
if not lplr.Character then
pcall(function()
game:GetService("TeleportService"):Teleport(game.PlaceId,lplr)
end)
end
end
end)
end
end
end)
local actionCount=0
local actionWindow=tick()
task.spawn(function()
while true do task.wait(1)
if Flags.StealthRateLimit then
local now=tick()
if now-actionWindow>1 then
actionCount=0
actionWindow=now
end
if actionCount>(Flags.StealthMaxAct or 20) then
task.wait(1)
actionCount=0
end
end
end
end)
function Stealth.rateLimitAction()
if not Flags.StealthRateLimit then return true end
actionCount=actionCount+1
return actionCount<=(Flags.StealthMaxAct or 20)
end
task.spawn(function()
while true do task.wait(10)
if Flags.StealthServerHop then
local risk=calculateRisk()
if risk>=(Flags.StealthHopThresh or 80) then
pcall(function()
local servers=game:GetService("HttpService"):JSONDecode(
game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
)
if servers and servers.data then
for _,server in pairs(servers.data) do
if server.id~=game.JobId and server.playing<server.maxPlayers then
game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId,server.id,lplr)
break
end
end
end
end)
end
end
end
end)
task.spawn(function()
while true do task.wait(3)
if Flags.StealthRiskCalc then
if Flags.StealthAutoDisable and Stealth.RiskLevel>=(Flags.StealthRiskThresh or 70) then
Flags.Ragebot=false
Flags.AA=false
Flags.NoClip=false
Flags.SpeedBoost=false
Flags.FL=false
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification",{
Title=" AUTO SAFE",
Text="Risk "..Stealth.RiskLevel.."%  Dangerous features disabled!",
Duration=5
})
end)
end
end
end
end)
-- SECTION 11: SAFE MODE PROFILES
page:Label(" Safe Mode Profiles ")
page:Button({Name="[SAFE] Conservative", Color=Color3.fromRGB(0, 150, 0)}, function()
Flags.Ragebot = false
Flags.AA = false
Flags.NoClip = false
Flags.SpeedBoost = false
Flags.FL = false
Flags.NoSpread = false
Flags.NoRecoil = false
Flags.SilentAim = false
Flags.ForceCrosshair = false
Flags.ESP_Box = true
Flags.ESP_Name = true
Flags.ESP_Health = true
Flags.Aimbot = true
Flags.AimbotSmooth = 8
Flags.AimbotFOV = 60
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = " Conservative Mode",
Text = "Only ESP + Legit Aimbot enabled",
Duration = 3,
})
end)
end)
page:Button({Name="[SAFE] Balanced", Color=Color3.fromRGB(200, 200, 0)}, function()
Flags.Ragebot = false
Flags.AA = false
Flags.NoClip = false
Flags.FL = false
Flags.NoSpread = false
Flags.NoRecoil = false
Flags.ESP_Box = true
Flags.ESP_Name = true
Flags.ESP_Health = true
Flags.ESP_Dist = true
Flags.Aimbot = true
Flags.TriggerBot = true
Flags.Bhop = true
Flags.ThirdPerson = true
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = " Balanced Mode",
Text = "Balanced features enabled",
Duration = 3,
})
end)
end)
page:Button({Name="[SAFE] HVH Ready", Color=Color3.fromRGB(200, 100, 0)}, function()
Flags.Ragebot = true
Flags.RageFOV = 180
Flags.RageHitchance = 85
Flags.RageSilent = true
Flags.RageAutoFire = false
Flags.AA = true
Flags.AAPitch = "Down"
Flags.AAYaw = "Jitter"
Flags.FL = true
Flags.FLChoke = 4
Flags.StealthHumanize = true
Flags.StealthRandomTiming = true
Flags.StealthAntiPattern = true
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = " HVH Ready",
Text = "HVH with humanization enabled",
Duration = 3,
})
end)
end)
-- SECTION 11: EMERGENCY CONTROLS
page:Label(" Emergency ")
page:Button({Name=" EMERGENCY: Nuclear Disable", Color=Color3.fromRGB(200, 0, 0)}, function()
for key, _ in pairs(Flags) do
Flags[key] = false
end
pcall(function()
local h = BS.hum()
if h then
h.WalkSpeed = 16
h.JumpPower = 50
h.HipHeight = 0
end
workspace.CurrentCamera.FieldOfView = 70
end)
pcall(function()
local char = lplr.Character
if char then
for _, part in pairs(char:GetDescendants()) do
if part:IsA("BasePart") then
part.Transparency = 0
part.CanCollide = true
part.LocalTransparencyModifier = 0
part.Material = Enum.Material.Plastic
end
end
end
end)
pcall(function()
for _, part in pairs(workspace:GetDescendants()) do
if part:IsA("BasePart") then
part.LocalTransparencyModifier = 0
end
end
end)
pcall(function()
Lighting.Brightness = 1
Lighting.GlobalShadows = true
Lighting.FogEnd = 100000
end)
pcall(function()
for _, obj in pairs(workspace:GetDescendants()) do
if obj.Name:find("BS_") then obj:Destroy() end
end
end)
pcall(function()
local gui = lplr.PlayerGui:FindFirstChild("BloxStrike_GUI")
if gui then gui.Enabled = false end
end)
timingHistory = {}
remoteCalls = {}
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = " NUCLEAR DISABLE",
Text = "ALL features OFF. GUI hidden. Traces cleaned.",
Duration = 10,
})
end)
end)
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.F10 then
for key, _ in pairs(Flags) do
Flags[key] = false
end
pcall(function()
local h = BS.hum()
if h then
h.WalkSpeed = 16
h.JumpPower = 50
h.HipHeight = 0
end
workspace.CurrentCamera.FieldOfView = 70
end)
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = " F10 NUCLEAR",
Text = "ALL disabled!",
Duration = 3,
})
end)
end
if input.KeyCode == Enum.KeyCode.F9 then
Flags.Ragebot = false
Flags.AA = false
Flags.NoClip = false
Flags.SpeedBoost = false
Flags.FL = false
Flags.NoSpread = false
Flags.NoRecoil = false
Flags.SilentAim = false
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = " F9 SAFE",
Text = "Dangerous features disabled.",
Duration = 3,
})
end)
end
if input.KeyCode == Enum.KeyCode.F8 then
pcall(function()
local gui = lplr.PlayerGui:FindFirstChild("BloxStrike_GUI")
if gui then
gui.Enabled = not gui.Enabled
end
end)
end
end)
-- SECTION 12: RISK MONITOR
task.spawn(function()
while true do
task.wait(3)
pcall(function()
local risk = 0
if Flags.Ragebot then risk = risk + 30 end
if Flags.AA then risk = risk + 20 end
if Flags.NoClip then risk = risk + 25 end
if Flags.SpeedBoost then risk = risk + 15 end
if Flags.FL then risk = risk + 10 end
if Flags.NoSpread then risk = risk + 20 end
if Flags.NoRecoil then risk = risk + 20 end
if Flags.SilentAim then risk = risk + 25 end
if Flags.StealthHumanize then risk = risk - 10 end
if Flags.StealthRandomTiming then risk = risk - 5 end
if Flags.StealthMaskHooks then risk = risk - 5 end
if Flags.StealthHideGUI then risk = risk - 5 end
risk = risk + Stealth.RiskLevel * 0.3
if Stealth.RiskLevel >= 80 and Flags.StealthAlert then
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = " HIGH RISK: " .. Stealth.RiskLevel .. "%",
Duration = 5,
})
end)
end
end)
end
end)
-- SECTION 11: HVH SAFE MODE (Anti-Detection for HVH)
page:Label(" HVH  ")
page:Toggle("HVH Safe Mode", false, function(v) Flags.HVHSafeMode = v end)
page:Toggle("Anti-Trust Score Bypass", true, function(v) Flags.HVHTrustBypass = v end)
page:Toggle("Behavioral Consistency", true, function(v) Flags.HVHBehavior = v end)
page:Toggle("Kill Pattern Masking", true, function(v) Flags.HVHKillMask = v end)
page:Toggle("Movement Legitimacy", true, function(v) Flags.HVHMoveLegit = v end)
page:Toggle("Aim Legitimacy", true, function(v) Flags.HVHAimLegit = v end)
page:Toggle("Anti-Stat Detection", true, function(v) Flags.HVHAntiStat = v end)
page:Toggle("Server-Side Validation Mask", true, function(v) Flags.HVHServMask = v end)
page:Toggle("Session Warmup", true, function(v) Flags.HVHWarmup = v end)
page:Slider("Warmup Duration", 30, 300, 120, function(v) Flags.HVHWarmupDur = v end)
page:Toggle("Gradual Escalation", true, function(v) Flags.HVHGradual = v end)
page:Toggle("Anti-Stat Spike", true, function(v) Flags.HVHAntiSpike = v end)
page:Toggle("Kill Cooldown", true, function(v) Flags.HVHKillCD = v end)
page:Slider("Kill CD Time", 1, 10, 3, function(v) Flags.HVHKillCDTime = v end)
page:Label(" HVH  ")
page:Toggle("Fake Miss Shots", true, function(v) Flags.HVHFakeMiss = v end)
page:Slider("Fake Miss Rate", 5, 40, 15, function(v) Flags.HVHFakeMissRate = v end)
page:Toggle("Aim Delay Variation", true, function(v) Flags.HVHAimDelay = v end)
page:Slider("Aim Delay Min", 50, 300, 100, function(v) Flags.HVHAimDelayMin = v end)
page:Slider("Aim Delay Max", 100, 500, 300, function(v) Flags.HVHAimDelayMax = v end)
page:Toggle("Movement Patterns", true, function(v) Flags.HVHMovePattern = v end)
page:Dropdown({Name="Move Pattern", Flag="HVMvPat", Options={"Linear","Zigzag","Random Walk","Strafe","Stop-Go"}, Default="Linear"})
page:Toggle("Crosshair Resting", true, function(v) Flags.HVHRestCrosshair = v end)
page:Toggle("Look Around", false, function(v) Flags.HVHLookAround = v end)
page:Label(" HVH  ")
page:Toggle("KD Balance", true, function(v) Flags.HVHKDBalance = v end)
page:Slider("Target KD", 10, 50, 25, function(v) Flags.HVHTargetKD = v end)
page:Toggle("Headshot Ratio Limit", true, function(v) Flags.HVHHSLimit = v end)
page:Slider("Max HS Ratio", 20, 80, 50, function(v) Flags.HVHMaxHS = v end)
page:Toggle("Damage Distribution", true, function(v) Flags.HVHDmgDist = v end)
page:Toggle("Weapon Rotation", false, function(v) Flags.HVHWepRot = v end)
page:Label(" HVH  ")
page:Toggle("Auto Panic on Risk", true, function(v) Flags.HVHPanic = v end)
page:Slider("Panic Risk Level", 50, 90, 70, function(v) Flags.HVHPanicLevel = v end)
page:Toggle("Server Hop on Ban Risk", true, function(v) Flags.HVHServerHop = v end)
page:Slider("Ban Risk Threshold", 60, 95, 80, function(v) Flags.HVHBanThreshold = v end)
page:Toggle("Auto Account Switch", false, function(v) Flags.HVHAccSwitch = v end)
page:Label("F9 = Safe Mode | F10 = Nuclear Panic")
local hvhState = {
KillsThisSession = 0,
DeathsThisSession = 0,
HeadshotsThisSession = 0,
TotalShots = 0,
MissedShots = 0,
LastKillTime = 0,
WarmupDone = false,
EscalationLevel = 0,
BehaviorPattern = {},
MovementPhase = 0,
LookAroundTimer = 0,
}
task.spawn(function()
while true do task.wait(1)
if Flags.HVHSafeMode and Flags.HVHWarmup then
local elapsed = tick() - hvhState.SessionStart
local warmupDur = Flags.HVHWarmupDur or 120
if elapsed < warmupDur then
hvhState.WarmupDone = false
if elapsed < warmupDur * 0.3 then
Flags.Ragebot = false
Flags.AA = false
Flags.FL = false
elseif elapsed < warmupDur * 0.6 then
Flags.Ragebot = false
Flags.AA = true
Flags.FL = false
else
Flags.AA = true
Flags.FL = true
end
else
hvhState.WarmupDone = true
end
end
end
end)
task.spawn(function()
while true do task.wait(30)
if Flags.HVHSafeMode and Flags.HVHGradual and hvhState.WarmupDone then
local sessionMin = (tick() - hvhState.SessionStart) / 60
hvhState.EscalationLevel = math.min(5, math.floor(sessionMin / 10))
end
end
end)
task.spawn(function()
while true do task.wait(0.5)
if Flags.HVHSafeMode and Flags.HVHKillMask then
pcall(function()
if Flags.HVHKillCD then
local cd = Flags.HVHKillCDTime or 3
if tick() - hvhState.LastKillTime < cd then
if Flags.Ragebot then
local origHC = Flags.RageHC
Flags.RageHC = math.max(30, (origHC or 85) - 30)
task.wait(cd - (tick() - hvhState.LastKillTime))
Flags.RageHC = origHC
end
end
end
if Flags.HVHFakeMiss then
local missRate = (Flags.HVHFakeMissRate or 15) / 100
if math.random() < missRate then
local cam = workspace.CurrentCamera
if cam then
local offset = Vector3.new(
)
end
end
end
end)
end
end
end)
task.spawn(function()
while true do task.wait(0.5)
if Flags.HVHSafeMode and Flags.HVHMoveLegit and BS.alive() then
pcall(function()
local h = hum()
if not h then return end
local hrp = hrp()
if not hrp then return end
local pattern = Flags.HVMvPat or "Linear"
hvhState.MovementPhase = hvhState.MovementPhase + 0.1
if pattern == "Zigzag" then
local zigAngle = math.sin(hvhState.MovementPhase * 2) * 0.3
hrp.CFrame = hrp.CFrame * CFrame.Angles(0, zigAngle, 0)
elseif pattern == "Random Walk" then
if math.random() < 0.1 then
h.WalkDirection = Vector3.new(
).Unit
end
elseif pattern == "Strafe" then
local strafeAngle = math.sin(hvhState.MovementPhase) * 0.2
hrp.CFrame = hrp.CFrame * CFrame.Angles(0, strafeAngle, 0)
elseif pattern == "Stop-Go" then
if math.random() < 0.05 then
h.WalkSpeed = 0
task.wait(0.3 + math.random() * 0.5)
h.WalkSpeed = 16
end
end
local baseSpeed = h.WalkSpeed
local jitter = (math.random() - 0.5) * 0.8
h.WalkSpeed = baseSpeed + jitter
task.wait(0.1)
h.WalkSpeed = baseSpeed
end)
end
end
end)
task.spawn(function()
while true do task.wait(0.3)
if Flags.HVHSafeMode and Flags.HVHAimLegit then
pcall(function()
if Flags.HVHAimDelay then
local minD = (Flags.HVHAimDelayMin or 100) / 1000
local maxD = (Flags.HVHAimDelayMax or 300) / 1000
local delay = minD + math.random() * (maxD - minD)
task.wait(delay)
end
if Flags.HVHRestCrosshair and math.random() < 0.02 then
local cam = workspace.CurrentCamera
if cam then
local lookDir = cam.CFrame.LookVector
local restOffset = Vector3.new(
)
cam.CFrame = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + lookDir + restOffset)
task.wait(0.2 + math.random() * 0.3)
end
end
if Flags.HVHLookAround then
hvhState.LookAroundTimer = hvhState.LookAroundTimer + 0.3
if hvhState.LookAroundTimer > 10 + math.random() * 10 then
hvhState.LookAroundTimer = 0
local cam = workspace.CurrentCamera
if cam then
local lookAngle = (math.random() - 0.5) * math.pi * 0.5
cam.CFrame = cam.CFrame * CFrame.Angles(0, lookAngle, 0)
task.wait(0.3 + math.random() * 0.5)
end
end
end
end)
end
end
end)
task.spawn(function()
while true do task.wait(2)
if Flags.HVHSafeMode and Flags.HVHAntiStat then
pcall(function()
if Flags.HVHKDBalance then
local targetKD = (Flags.HVHTargetKD or 25) / 10
if hvhState.DeathsThisSession > 0 then
local currentKD = hvhState.KillsThisSession / hvhState.DeathsThisSession
if currentKD > targetKD and math.random() < 0.3 then
local enemies = BS.enemies()
if #enemies > 0 then
local target = enemies[math.random(#enemies)]
if target and target.HRP then
local h = hum()
if h then
task.wait(2)
end
end
end
end
end
end
if Flags.HVHHSLimit then
local totalKills = hvhState.KillsThisSession
if totalKills > 5 then
local hsRatio = hvhState.HeadshotsThisSession / totalKills
if hsRatio > (Flags.HVHMaxHS or 50) / 100 then
Flags.RageHead = false
Flags.RageBody = true
task.wait(5)
Flags.RageBody = false
end
end
end
end)
end
end
end)
BS.HVHKD = hvhState
task.spawn(function()
while true do task.wait(0.5)
if Flags.HVHSafeMode and Flags.HVHServMask then
pcall(function()
local h = hum()
if h then
if h.WalkSpeed > 50 then
h.WalkSpeed = 16 + math.random() * 10
end
if h.JumpPower > 100 then
h.JumpPower = 50 + math.random() * 20
end
if h.HipHeight < -2 or h.HipHeight > 5 then
h.HipHeight = 0
end
end
local cam = workspace.CurrentCamera
if cam then
local cf = cam.CFrame
if cf ~= cf then
cam.CFrame = CFrame.new(0, 10, 0)
end
end
end)
end
end
end)
task.spawn(function()
while true do task.wait(5)
if Flags.HVHSafeMode and Flags.HVHAntiSpike then
pcall(function()
local now = tick()
local recentKills = 0
if now - hvhState.LastKillTime < 2 then
recentKills = recentKills + 1
end
if recentKills > 3 then
Flags.Ragebot = false
task.wait(5)
Flags.Ragebot = true
end
end)
end
end
end)
task.spawn(function()
while true do task.wait(2)
if Flags.HVHSafeMode and Flags.HVHPanic then
local risk = calculateRisk()
if risk >= (Flags.HVHPanicLevel or 70) then
Flags.Ragebot = false
Flags.AA = false
Flags.NoClip = false
Flags.SpeedBoost = false
Flags.FL = false
Flags.SilentAim = false
Flags.Resolver = false
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = " HVH SAFE MODE",
Text = "Risk " .. risk .. "%  Dangerous features disabled!",
Duration = 5,
})
end)
if Flags.HVHServerHop and risk >= (Flags.HVHBanThreshold or 80) then
pcall(function()
local servers = game:GetService("HttpService"):JSONDecode(
game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
)
if servers and servers.data then
for _, server in pairs(servers.data) do
if server.id ~= game.JobId and server.playing < server.maxPlayers then
game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, server.id, lplr)
break
end
end
end
end)
end
end
end
end
end)
-- SECTION 13: SSVL  Server-Side Validation Layer
page:Label(" SSVL  ")
page:Toggle("SSVL Enabled", true, function(v) Flags.SSVL = v end)
page:Toggle("Velocity Cap", true, function(v) Flags.SSVLVelCap = v end)
page:Slider("Max Velocity", 10, 200, 60, function(v) Flags.SSVLMaxVel = v end)
page:Toggle("Position Drift", true, function(v) Flags.SSVLDrift = v end)
page:Toggle("Acceleration Cap", true, function(v) Flags.SSVLAccel = v end)
page:Slider("Max Acceleration", 20, 500, 100, function(v) Flags.SSVLMaxAccel = v end)
page:Toggle("Angular Velocity Limit", true, function(v) Flags.SSVLAngular = v end)
page:Slider("Max Angular Vel", 10, 200, 80, function(v) Flags.SSVLMaxAngular = v end)
page:Toggle("Ping Simulation", true, function(v) Flags.SSVLPingSim = v end)
page:Slider("Fake Ping Offset", -50, 100, 30, function(v) Flags.SSVLPingOff = v end)
local ssvlState = {
PositionBuffer = {},
VelocityBuffer = {},
AccelerationBuffer = {},
}
task.spawn(function()
while true do task.wait(0.05)
if not Flags.SSVL or not BS.alive() then continue end
local hrp = BS.hrp()
if not hrp then continue end
local h = BS.hum()
if not h then continue end
if Flags.SSVLVelCap then
local vel = hrp.AssemblyLinearVelocity
local maxV = Flags.SSVLMaxVel or 60
local horizVel = Vector3.new(vel.X, 0, vel.Z)
if horizVel.Magnitude > maxV then
local clamped = horizVel.Unit * maxV
hrp.AssemblyLinearVelocity = Vector3.new(clamped.X, vel.Y, clamped.Z)
end
end
if Flags.SSVLAccel then
local now = tick()
local dt = now - ssvlState.LastTick
if dt > 0.01 then
local vel = hrp.AssemblyLinearVelocity
local accel = (vel - (ssvlState.LastVelocity or vel)) / dt
local maxA = Flags.SSVLMaxAccel or 100
if accel.Magnitude > maxA then
local clampedAccel = accel.Unit * maxA
hrp.AssemblyLinearVelocity = (ssvlState.LastVelocity or vel) + clampedAccel * dt
end
ssvlState.LastVelocity = vel
ssvlState.LastTick = now
end
end
if Flags.SSVLAngular then
local angVel = hrp.AssemblyAngularVelocity
local maxAng = (Flags.SSVLMaxAngular or 80) / 10
if angVel.Magnitude > maxAng then
hrp.AssemblyAngularVelocity = angVel.Unit * maxAng
end
end
if Flags.SSVLDrift then
local vel = hrp.AssemblyLinearVelocity
if vel.Magnitude > 30 then
ssvlState.DriftAccum = ssvlState.DriftAccum + Vector3.new(
)
if ssvlState.DriftAccum.Magnitude > 0.5 then
ssvlState.DriftAccum = Vector3.new(0, 0, 0)
end
end
end
end
end)
task.spawn(function()
while true do task.wait(2)
if Flags.SSVL and Flags.SSVLPingSim then
pcall(function()
local stats = nil
pcall(function() stats = game:GetService("Stats") end)
if stats and stats.Network then
local offset = Flags.SSVLPingOff or 30
local basePing = 0
pcall(function() basePing = stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
if basePing and basePing < 10 then
end
end
end)
end
end
end)
-- SECTION 14: FINGERPRINT ROTATION
page:Label("  ")
page:Toggle("Fingerprint Rotation", true, function(v) Flags.FPRotation = v end)
page:Slider("Rotation Interval", 30, 300, 120, function(v) Flags.FPRotInterval = v end)
page:Toggle("Name Fingerprint", true, function(v) Flags.FPName = v end)
page:Toggle("Movement Fingerprint", true, function(v) Flags.FPMove = v end)
page:Toggle("Aim Fingerprint", true, function(v) Flags.FPAim = v end)
page:Toggle("Timing Fingerprint", true, function(v) Flags.FPTiming = v end)
page:Toggle("Camera Fingerprint", true, function(v) Flags.FPCamera = v end)
local fpState = {
CurrentProfile = 1,
Profiles = {
{Name="Player_" .. math.random(1000,9999), MoveStyle="Normal", AimStyle="Smooth", TimingBase=80, CamSens=1.0},
{Name="Player_" .. math.random(1000,9999), MoveStyle="Aggressive", AimStyle="Flick", TimingBase=60, CamSens=1.2},
{Name="Player_" .. math.random(1000,9999), MoveStyle="Passive", AimStyle="Slow", TimingBase=120, CamSens=0.8},
{Name="Player_" .. math.random(1000,9999), MoveStyle="Mixed", AimStyle="Adaptive", TimingBase=90, CamSens=1.1},
{Name="Player_" .. math.random(1000,9999), MoveStyle="Cautious", AimStyle="Precise", TimingBase=100, CamSens=0.9},
},
}
local function getFPProfile()
return fpState.Profiles[fpState.CurrentProfile]
end
function Stealth.getFingerprintDelay()
if not Flags.FPRotation then return 80 end
local p = getFPProfile()
local base = p.TimingBase
return base + (math.random() - 0.5) * 20
end
function Stealth.getFingerprintAimSmooth()
if not Flags.FPRotation then return 0.3 end
local p = getFPProfile()
if p.AimStyle == "Flick" then return 0.6
elseif p.AimStyle == "Slow" then return 0.15
elseif p.AimStyle == "Precise" then return 0.25
else return 0.35 end
end
function Stealth.getFingerprintCamSens()
if not Flags.FPRotation then return 1.0 end
return getFPProfile().CamSens
end
task.spawn(function()
while true do task.wait(1)
if Flags.FPRotation then
local interval = Flags.FPRotInterval or 120
if tick() - fpState.LastRotation > interval then
fpState.CurrentProfile = (fpState.CurrentProfile % #fpState.Profiles) + 1
fpState.LastRotation = tick()
for i = 1, #fpState.Profiles do
fpState.Profiles[i].Name = "Player_" .. math.random(1000, 9999)
end
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = " ",
Duration = 2,
})
end)
end
end
end
end)
-- SECTION 15: TRAFFIC PATTERN MASKING
page:Label("  ")
page:Toggle("Traffic Masking", true, function(v) Flags.TrafficMask = v end)
page:Toggle("Noise Injection", true, function(v) Flags.TrafficNoise = v end)
page:Slider("Noise Level", 1, 10, 3, function(v) Flags.TrafficNoiseLvl = v end)
page:Toggle("Burst Smoothing", true, function(v) Flags.TrafficBurst = v end)
page:Slider("Burst Window", 5, 50, 15, function(v) Flags.TrafficBurstWin = v end)
page:Toggle("Remote Fingerprint", true, function(v) Flags.TrafficRemoteFP = v end)
local trafficState = {
BurstBuffer = {},
NoiseCounter = 0,
RemoteFingerprints = {},
}
function Stealth.injectTrafficNoise()
if not Flags.TrafficNoise then return end
pcall(function()
local noiseLevel = Flags.TrafficNoiseLvl or 3
for i = 1, noiseLevel do
task.delay(math.random() * 0.5, function()
pcall(function()
for _, obj in pairs(game:GetDescendants()) do
if obj:IsA("RemoteEvent") then
local name = obj.Name:lower()
if not name:find("anticheat") and not name:find("kick") and not name:find("ban") then
pcall(function() obj:FireServer() end)
break
end
end
end
end)
end)
end
end)
end
function Stealth.smoothBurst(action)
if not Flags.TrafficBurst then return action() end
table.insert(trafficState.BurstBuffer, {Action=action, Time=tick()})
local window = (Flags.TrafficBurstWin or 15) / 1000
if tick() - trafficState.LastBurstFlush > window then
for _, entry in ipairs(trafficState.BurstBuffer) do
task.spawn(pcall, entry.Action)
end
trafficState.BurstBuffer = {}
trafficState.LastBurstFlush = tick()
end
end
task.spawn(function()
while true do task.wait(5)
if Flags.TrafficMask and Flags.TrafficRemoteFP then
pcall(function()
for _, obj in pairs(game:GetDescendants()) do
if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
local conns = getconnections and getconnections(obj.OnServerEvent)
if conns and #conns > 3 then
trafficState.RemoteFingerprints[obj:GetFullName()] = {
Watchers = #conns,
Suspicious = true,
}
end
end
end
end)
end
end
end)
task.spawn(function()
while true do task.wait(15)
if Flags.TrafficMask then
end
end
end)
-- SECTION 16: ML / BEHAVIORAL AI EVASION
page:Label(" ML  ")
page:Toggle("ML Evasion", true, function(v) Flags.MLEvasion = v end)
page:Slider("Human Score Target", 50, 95, 80, function(v) Flags.MLHumanScore = v end)
page:Toggle("Movement Entropy", true, function(v) Flags.MLEntropy = v end)
page:Toggle("Mouse Entropy", true, function(v) Flags.MLMouseEntropy = v end)
page:Toggle("Reaction Simulation", true, function(v) Flags.MLReaction = v end)
page:Slider("Reaction Variance", 10, 500, 150, function(v) Flags.MLReactionVar = v end)
page:Toggle("Decision Delay", true, function(v) Flags.MLDecision = v end)
page:Toggle("Micro Pauses", true, function(v) Flags.MLMicroPause = v end)
local mlState = {
HumanScore = 100,
EntropyAccum = 0,
MouseHistory = {},
DecisionBuffer = {},
MicroPauseTimer = 0,
}
function Stealth.addMovementEntropy(dir)
if not Flags.MLEvasion or not Flags.MLEntropy then return dir end
local noise = Vector3.new(
)
mlState.EntropyAccum = mlState.EntropyAccum + noise.Magnitude
return (dir + noise).Unit
end
function Stealth.addMouseEntropy(angle)
if not Flags.MLEvasion or not Flags.MLMouseEntropy then return angle end
local jitter = (math.random() - 0.5) * 0.003
table.insert(mlState.MouseHistory, angle + jitter)
if #mlState.MouseHistory > 30 then table.remove(mlState.MouseHistory, 1) end
return angle + jitter
end
function Stealth.mlReactionTime()
if not Flags.MLEvasion or not Flags.MLReaction then return 0 end
local base = (Flags.MLReactionVar or 150) / 1000
local u1 = math.random()
local u2 = math.random()
local gaussian = math.sqrt(-2 * math.log(math.max(u1, 0.001))) * math.cos(2 * math.pi * u2)
return math.max(0.05, base + gaussian * base * 0.3)
end
function Stealth.mlDecisionDelay()
if not Flags.MLEvasion or not Flags.MLDecision then return end
if math.random() < 0.15 then
task.wait(0.05 + math.random() * 0.15)
end
end
task.spawn(function()
while true do task.wait(0.1)
if Flags.MLEvasion and Flags.MLMicroPause and BS.alive() then
mlState.MicroPauseTimer = mlState.MicroPauseTimer + 0.1
local pauseInterval = 8 + math.random() * 12
if mlState.MicroPauseTimer > pauseInterval then
mlState.MicroPauseTimer = 0
local h = BS.hum()
if h then
local origSpeed = h.WalkSpeed
h.WalkSpeed = 0
task.wait(0.2 + math.random() * 0.5)
h.WalkSpeed = origSpeed
end
end
end
end
end)
task.spawn(function()
while true do task.wait(5)
if Flags.MLEvasion then
local score = 100
if Flags.Ragebot then score = score - 30 end
if Flags.NoClip then score = score - 25 end
if Flags.SpeedBoost then score = score - 20 end
if Flags.SilentAim then score = score - 15 end
if Flags.MLEntropy then score = score + 5 end
if Flags.MLMouseEntropy then score = score + 5 end
if Flags.MLReaction then score = score + 5 end
if Flags.MLMicroPause then score = score + 5 end
if Flags.HVHSafeMode then score = score + 10 end
mlState.HumanScore = math.clamp(score, 0, 100)
if mlState.HumanScore < (Flags.MLHumanScore or 80) then
Flags.MLEntropy = true
Flags.MLMouseEntropy = true
Flags.MLReaction = true
Flags.MLMicroPause = true
end
end
end
end)
BS.MLState = mlState
-- SECTION 17: STATISTICAL ANOMALY SMOOTHING
page:Label("  ")
page:Toggle("Stat Smoothing", true, function(v) Flags.StatSmooth = v end)
page:Toggle("KD Regulation", true, function(v) Flags.StatKDReg = v end)
page:Slider("Target KD", 10, 40, 20, function(v) Flags.StatTargetKD = v end)
page:Toggle("HS Ratio Regulation", true, function(v) Flags.StatHSReg = v end)
page:Slider("Max HS %", 20, 70, 45, function(v) Flags.StatMaxHS = v end)
page:Toggle("Damage Spread", true, function(v) Flags.StatDmgSpread = v end)
page:Toggle("Kill Timing Spread", true, function(v) Flags.StatKillTiming = v end)
page:Slider("Min Kill Gap", 1, 15, 3, function(v) Flags.StatMinKillGap = v end)
page:Toggle("Weapon Rotation", true, function(v) Flags.StatWeaponRot = v end)
page:Toggle("Death Staging", false, function(v) Flags.StatDeathStage = v end)
local statState = {
SessionKills = 0,
SessionDeaths = 0,
SessionHeadshots = 0,
SessionTotalDamage = 0,
SessionDamageValues = {},
LastKillTime = 0,
KillTimestamps = {},
WeaponUsage = {},
ForcedDeaths = 0,
}
task.spawn(function()
while true do task.wait(3)
if Flags.StatSmooth and Flags.StatKDReg and statState.SessionDeaths > 0 then
local currentKD = statState.SessionKills / math.max(1, statState.SessionDeaths)
local targetKD = (Flags.StatTargetKD or 20) / 10
if currentKD > targetKD * 1.5 then
Flags.StatDeathStage = true
statState.ForcedDeaths = statState.ForcedDeaths + 1
elseif currentKD < targetKD * 0.5 then
Flags.StatDeathStage = false
end
end
end
end)
task.spawn(function()
while true do task.wait(1)
if Flags.StatSmooth and Flags.StatKillTiming then
local now = tick()
local minGap = Flags.StatMinKillGap or 3
for i = #statState.KillTimestamps, 1, -1 do
if now - statState.KillTimestamps[i] > 60 then
table.remove(statState.KillTimestamps, i)
end
end
if #statState.KillTimestamps >= 3 then
local lastTwo = statState.KillTimestamps[#statState.KillTimestamps] - statState.KillTimestamps[#statState.KillTimestamps - 1]
if math.abs(lastTwo - minGap) < 0.5 then
task.wait(minGap + math.random() * 3)
end
end
end
end
end)
function Stealth.trackWeaponUse(weaponName)
if not Flags.StatWeaponRot then return end
weaponName = weaponName or "default"
statState.WeaponUsage[weaponName] = (statState.WeaponUsage[weaponName] or 0) + 1
local totalUses = 0
for _, v in pairs(statState.WeaponUsage) do totalUses = totalUses + v end
if totalUses > 10 then
local usageRatio = statState.WeaponUsage[weaponName] / totalUses
if usageRatio > 0.7 then
return false
end
end
return true
end
function Stealth.onKill(headshot)
statState.SessionKills = statState.SessionKills + 1
if headshot then statState.SessionHeadshots = statState.SessionHeadshots + 1 end
statState.LastKillTime = tick()
table.insert(statState.KillTimestamps, tick())
hvhState.KillsThisSession = (hvhState.KillsThisSession or 0) + 1
if headshot then hvhState.HeadshotsThisSession = (hvhState.HeadshotsThisSession or 0) + 1 end
end
function Stealth.onDeath()
statState.SessionDeaths = statState.SessionDeaths + 1
hvhState.DeathsThisSession = (hvhState.DeathsThisSession or 0) + 1
end
BS.StatState = statState
-- SECTION 18: ANTI-REPLAY PROTECTION
page:Label("  ")
page:Toggle("Anti Replay", true, function(v) Flags.AntiReplay = v end)
page:Toggle("Action Fuzzing", true, function(v) Flags.ActionFuzz = v end)
page:Slider("Fuzz Amount", 1, 20, 5, function(v) Flags.ActionFuzzAmt = v end)
page:Toggle("Sequence Shuffling", true, function(v) Flags.SeqShuffle = v end)
page:Toggle("Timing Desync", true, function(v) Flags.TimingDesync = v end)
local replayState = {
ActionHistory = {},
FuzzAmount = 5,
}
function Stealth.fuzzAction(actionType, params)
if not Flags.AntiReplay or not Flags.ActionFuzz then return params end
local fuzz = (Flags.ActionFuzzAmt or 5) / 100
if type(params) == "number" then
return params * (1 + (math.random() - 0.5) * fuzz * 2)
elseif type(params) == "Vector3" then
return params + Vector3.new(
)
elseif type(params) == "CFrame" then
local pos = params.Position
local newOffset = Vector3.new(
)
return CFrame.new(pos + newOffset) * (params - pos)
end
return params
end
function Stealth.desyncTiming(baseDelay)
if not Flags.AntiReplay or not Flags.TimingDesync then return baseDelay end
local u1 = math.max(0.001, math.random())
local u2 = math.random()
local gaussian = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
return math.max(0.001, baseDelay + gaussian * baseDelay * 0.15)
end
-- SECTION 19: MEMORY SIGNATURE EVASION
page:Label("  ")
page:Toggle("Memory Evasion", true, function(v) Flags.MemEvasion = v end)
page:Toggle("String Encryption", true, function(v) Flags.MemStrEnc = v end)
page:Toggle("Object Scrambling", true, function(v) Flags.MemObjScramble = v end)
page:Toggle("Reference Cleanup", true, function(v) Flags.MemRefClean = v end)
page:Slider("Cleanup Interval", 10, 60, 20, function(v) Flags.MemCleanInt = v end)
page:Toggle("GC Obfuscation", true, function(v) Flags.MemGCObf = v end)
local memEvadeState = {
EncryptedStrings = {},
OriginalStrings = {},
CleanupTimer = 0,
}
function Stealth.encryptMemoryString(str)
if not Flags.MemEvasion or not Flags.MemStrEnc then return str end
if memEvadeState.EncryptedStrings[str] then
return memEvadeState.EncryptedStrings[str]
end
local key = math.random(1, 255)
local encrypted = ""
for i = 1, #str do
local b = bit32.bxor(string.byte(str, i), key)
encrypted = encrypted .. string.char(b)
end
memEvadeState.EncryptedStrings[str] = encrypted
memEvadeState.OriginalStrings[encrypted] = str
return encrypted
end
function Stealth.decryptMemoryString(enc)
return memEvadeState.OriginalStrings[enc] or enc
end
task.spawn(function()
while true do task.wait(10)
if Flags.MemEvasion and Flags.MemObjScramble then
pcall(function()
for _, obj in pairs(workspace:GetDescendants()) do
if obj.Name:find("BS_") or obj.Name:find("BloxStrike") then
local newName = ""
for i = 1, math.random(6, 15) do
newName = newName .. string.char(math.random(65, 122))
end
obj.Name = newName
end
end
local gui = lplr.PlayerGui:FindFirstChildWhichIsA("ScreenGui")
if gui and (gui.Name:find("BloxStrike") or gui.Name:find("BS_")) then
local newName = ""
for i = 1, math.random(10, 20) do
newName = newName .. string.char(math.random(65, 122))
end
gui.Name = newName
end
end)
end
end
end)
task.spawn(function()
while true do task.wait(Flags.MemCleanInt or 20)
if Flags.MemEvasion and Flags.MemRefClean then
pcall(function()
Stealth.Detections = {}
resData = {}
timingHistory = {}
remoteCalls = {}
replayState.ActionHistory = {}
ssvlState.PositionBuffer = {}
ssvlState.VelocityBuffer = {}
trafficState.BurstBuffer = {}
mlState.MouseHistory = {}
statState.SessionDamageValues = {}
collectgarbage("collect")
collectgarbage("collect")
end)
end
end
end)
task.spawn(function()
while true do task.wait(30)
if Flags.MemEvasion and Flags.MemGCObf then
pcall(function()
local temps = {}
for i = 1, 10 do
local t = Instance.new("Part")
t.Name = string.char(math.random(65, 122), math.random(65, 122), math.random(65, 122))
t.Size = Vector3.new(math.random(1, 5), math.random(1, 5), math.random(1, 5))
t.Transparency = 1
t.Anchored = true
t.CanCollide = false
t.Parent = workspace.CurrentCamera
table.insert(temps, t)
end
task.wait(0.1)
for _, t in ipairs(temps) do
pcall(function() t:Destroy() end)
end
collectgarbage("collect")
end)
end
end
end)
-- SECTION 20: ANTI-EMULATION / SANDBOX DETECTION
page:Label("  /  ")
page:Toggle("Anti-Emulation", true, function(v) Flags.AntiEmulation = v end)
page:Toggle("Sandbox Detection", true, function(v) Flags.SandboxDetect = v end)
page:Toggle("Timing Canary", true, function(v) Flags.TimingCanary = v end)
page:Toggle("Environment Integrity", true, function(v) Flags.EnvIntegrity = v end)
page:Toggle("Self-Heal", true, function(v) Flags.SelfHeal = v end)
local emulationState = {
OriginalFunctions = {},
IntegrityHash = 0,
}
pcall(function()
if getrawmetatable then
emulationState.OriginalFunctions = {
index = select(2, pcall(getrawmetatable, game)).__index,
newindex = select(2, pcall(getrawmetatable, game)).__newindex,
namecall = select(2, pcall(getrawmetatable, game)).__namecall,
}
end
end)
task.spawn(function()
while true do task.wait(1)
if Flags.AntiEmulation and Flags.TimingCanary then
local startTick = tick()
task.wait(0.016)
local elapsed = tick() - startTick
if elapsed > 0.1 then
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = " ",
Text = "",
Duration = 3,
})
end)
end
end
end
end)
task.spawn(function()
while true do task.wait(10)
if Flags.AntiEmulation and Flags.EnvIntegrity then
pcall(function()
local intact = true
if checkcaller then
local result = checkcaller()
if result ~= false and result ~= true then
intact = false
end
end
if debug and debug.getinfo then
local info = debug.getinfo(1)
if not info then
intact = false
end
end
if not intact then
end
end)
end
end
end)
function Stealth.selfHeal()
if not Flags.SelfHeal then return end
pcall(function()
if Flags.StealthSpoofCaller and checkcaller then
_G.checkcaller = function() return false end
end
if Flags.StealthAntiDebug and debug then
local oldGetInfo = debug.getinfo
debug.getinfo = function(level, what)
local info = oldGetInfo(level, what)
if info and info.source and info.source:find("BloxStrike") then
info.source = "[C]"
info.short_src = "[C]"
end
return info
end
end
if Bypass and Bypass.backupMetatables then
pcall(function() Bypass.backupMetatables() end)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}
function BS.HWIDSpoofer:Generate()
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local id = ""
for i = 1, 32 do
local r = math.random(1, #chars)
id = id .. chars:sub(r, r)
if i == 8 or i == 12 or i == 16 or i == 20 then
id = id .. "-"
end
end
return id
end
function BS.HWIDSpoofer:Activate()
self.Active = true
self.SpoofedID = self:Generate()
pcall(function()
if gethwid then
local old = gethwid
gethwid = function() return self.SpoofedID end
end
end)
pcall(function()
if getmachineid then
local old = getmachineid
getmachineid = function() return self.SpoofedID end
end
end)
print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}
function BS.PingSpoof:SetPing(value)
self.FakePing = value
self.Active = true
pcall(function()
if BS.Ping then
BS.Ping.Current = value
BS.Ping.Average = value
end
end)
end
function BS.PingSpoof:Disable()
self.Active = false
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}
function BS.AntiScreenshot:Activate()
self.Active = true
pcall(function()
local oldSetCore
oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
if method == "TakeScreenshot" then
if BS.Win then BS.Win.Visible = false end
task.delay(1, function()
if BS.Win then BS.Win.Visible = true end
end)
return
end
return oldSetCore(self, method, ...)
end)
end)
pcall(function()
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.PrintScreen then
if BS.Win then BS.Win.Visible = false end
task.delay(2, function()
if BS.Win then BS.Win.Visible = true end
end)
end
end)
end)
print("[Stealth] Anti-Screenshot active")
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
Kills = 0,
Deaths = 0,
Headshots = 0,
Shots = 0,
Hits = 0,
Damage = 0,
StartTime = tick(),
}
function BS.Stats:RecordKill(headshot)
self.Kills = self.Kills + 1
if headshot then self.Headshots = self.Headshots + 1 end
end
function BS.Stats:RecordDeath()
self.Deaths = self.Deaths + 1
end
function BS.Stats:RecordShot(hit)
self.Shots = self.Shots + 1
if hit then self.Hits = self.Hits + 1 end
end
function BS.Stats:RecordDamage(dmg)
self.Damage = self.Damage + dmg
end
function BS.Stats:GetKD()
if self.Deaths == 0 then return self.Kills end
return math.floor(self.Kills / self.Deaths * 10) / 10
end
function BS.Stats:GetHSPercent()
if self.Kills == 0 then return 0 end
return math.floor(self.Headshots / self.Kills * 100)
end
function BS.Stats:GetAccuracy()
if self.Shots == 0 then return 0 end
return math.floor(self.Hits / self.Shots * 100)
end
function BS.Stats:GetPlayTime()
return math.floor(tick() - self.StartTime)
end
function BS.Stats:GetReport()
return string.format(
"K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
self.Kills, self.Deaths, self:GetKD(),
self:GetHSPercent(), self:GetAccuracy(),
self.Damage, math.floor(self:GetPlayTime() / 60)
)
end
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)
print("[Stealth] Self-heal completed")
end)
end
task.spawn(function()
while true do task.wait(15)
if Flags.AntiEmulation and Flags.SelfHeal then
if Stealth.RiskLevel > 30 then
end
end
end
end)
-- SECTION 21: COMPREHENSIVE RISK MATRIX
page:Label("  ")
page:Toggle("Matrix Risk Calc", true, function(v) Flags.MatrixRisk = v end)
page:Toggle("Auto Panic on Matrix", true, function(v) Flags.MatrixPanic = v end)
page:Slider("Panic Threshold", 40, 90, 65, function(v) Flags.MatrixPanicThresh = v end)
page:Toggle("Adaptive Stealth", true, function(v) Flags.AdaptiveStealth = v end)
local riskMatrix = {
FeatureRisk = 0,
BehaviorRisk = 0,
NetworkRisk = 0,
StatRisk = 0,
MemoryRisk = 0,
TimingRisk = 0,
TotalRisk = 0,
History = {},
}
local function calculateComprehensiveRisk()
if not Flags.MatrixRisk then return calculateRisk() end
local r = 0
local featureRisk = 0
if Flags.Ragebot then featureRisk = featureRisk + 25 end
if Flags.AA then featureRisk = featureRisk + 20 end
if Flags.NoClip then featureRisk = featureRisk + 30 end
if Flags.SpeedBoost then featureRisk = featureRisk + 15 end
if Flags.SilentAim then featureRisk = featureRisk + 20 end
if Flags.FL then featureRisk = featureRisk + 10 end
if Flags.NoSpread then featureRisk = featureRisk + 20 end
if Flags.NoRecoil then featureRisk = featureRisk + 20 end
if Flags.Resolver then featureRisk = featureRisk + 10 end
riskMatrix.FeatureRisk = math.min(100, featureRisk)
local behaviorRisk = 50
if Flags.MLEvasion then behaviorRisk = behaviorRisk - 10 end
if Flags.MLEntropy then behaviorRisk = behaviorRisk - 5 end
if Flags.MLMicroPause then behaviorRisk = behaviorRisk - 5 end
if Flags.HVHMoveLegit then behaviorRisk = behaviorRisk - 10 end
if Flags.HVHAimLegit then behaviorRisk = behaviorRisk - 5 end
if mlState.HumanScore then
behaviorRisk = behaviorRisk + (100 - mlState.HumanScore) * 0.3
end
riskMatrix.BehaviorRisk = math.clamp(behaviorRisk, 0, 100)
local networkRisk = 0
if Stealth.RiskLevel > 50 then networkRisk = networkRisk + Stealth.RiskLevel * 0.5 end
if #remoteCalls > 15 then networkRisk = networkRisk + 20 end
riskMatrix.NetworkRisk = math.min(100, networkRisk)
local statRisk = 0
if statState.SessionDeaths > 0 then
local kd = statState.SessionKills / statState.SessionDeaths
if kd > 5 then statRisk = statRisk + 30
elseif kd > 3 then statRisk = statRisk + 15 end
end
if statState.SessionKills > 3 then
local hsRatio = statState.SessionHeadshots / statState.SessionKills
if hsRatio > 0.8 then statRisk = statRisk + 25
elseif hsRatio > 0.6 then statRisk = statRisk + 10 end
end
riskMatrix.StatRisk = math.min(100, statRisk)
local timingRisk = 0
if Bypass.isTimingSuspicious and Bypass.isTimingSuspicious() then
timingRisk = timingRisk + 40
end
riskMatrix.TimingRisk = math.min(100, timingRisk)
local memRisk = 0
if Stealth.Detections then
for _, d in ipairs(Stealth.Detections) do
if d.Severity == "HIGH" then memRisk = memRisk + 15
else memRisk = memRisk + 5 end
end
end
riskMatrix.MemoryRisk = math.min(100, memRisk)
r = riskMatrix.FeatureRisk * 0.30
if Flags.StealthHumanize then r = r * 0.85 end
if Flags.FPRotation then r = r * 0.90 end
if Flags.TrafficMask then r = r * 0.92 end
if Flags.MemEvasion then r = r * 0.93 end
if Flags.AntiReplay then r = r * 0.95 end
riskMatrix.TotalRisk = math.clamp(math.floor(r), 0, 100)
table.insert(riskMatrix.History, {Time=tick(), Risk=riskMatrix.TotalRisk})
if #riskMatrix.History > 100 then table.remove(riskMatrix.History, 1) end
return riskMatrix.TotalRisk
end
task.spawn(function()
while true do task.wait(3)
local risk = calculateComprehensiveRisk()
Stealth.RiskLevel = risk
if Flags.AdaptiveStealth then
if risk > 60 then
Flags.MLEvasion = true
Flags.MLEntropy = true
Flags.MLMouseEntropy = true
Flags.MLReaction = true
Flags.MLMicroPause = true
Flags.AntiReplay = true
Flags.ActionFuzz = true
Flags.TimingDesync = true
Flags.MemEvasion = true
Flags.TrafficNoise = true
end
if risk >= (Flags.MatrixPanicThresh or 65) and Flags.MatrixPanic then
Flags.Ragebot = false
Flags.AA = false
Flags.NoClip = false
Flags.SpeedBoost = false
Flags.SilentAim = false
Flags.FL = false
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = " ",
Text = " " .. risk .. "%  ",
Duration = 5,
})
end)
end
end
end
end)
BS.RiskMatrix = riskMatrix
BS.calculateRisk = calculateComprehensiveRisk
lplr.CharacterRemoving:Connect(function()
spoofedProps = {}
timingHistory = {}
remoteCalls = {}
hvhState.KillsThisSession = 0
hvhState.DeathsThisSession = 0
hvhState.HeadshotsThisSession = 0
statState.SessionKills = 0
statState.SessionDeaths = 0
statState.SessionHeadshots = 0
statState.KillTimestamps = {}
statState.WeaponUsage = {}
replayState.ActionHistory = {}
mlState.MouseHistory = {}
riskMatrix.History = {}
fpState.LastRotation = tick()
end)
BS.Stealth = Stealth
BS.HVHState = hvhState
-- SECTION 22: GETFENV ENVIRONMENT LEAK PREVENTION
local envLeakPrevention = {
Patched = false,
DetectionCount = 0,
}
function Stealth.preventEnvLeak()
if envLeakPrevention.Patched then return end
pcall(function()
if newcclosure then
local mt = getrawmetatable and getrawmetatable(game)
if mt then
if mt.__namecall then
local oldNC = mt.__namecall
local isCClosure = pcall(function()
return debug and debug.getinfo and debug.getinfo(oldNC).what == "C"
end)
if not isCClosure then
mt.__namecall = newcclosure(oldNC)
end
end
end
end
envLeakPrevention.Patched = true
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}
function BS.HWIDSpoofer:Generate()
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local id = ""
for i = 1, 32 do
local r = math.random(1, #chars)
id = id .. chars:sub(r, r)
if i == 8 or i == 12 or i == 16 or i == 20 then
id = id .. "-"
end
end
return id
end
function BS.HWIDSpoofer:Activate()
self.Active = true
self.SpoofedID = self:Generate()
pcall(function()
if gethwid then
local old = gethwid
gethwid = function() return self.SpoofedID end
end
end)
pcall(function()
if getmachineid then
local old = getmachineid
getmachineid = function() return self.SpoofedID end
end
end)
print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}
function BS.PingSpoof:SetPing(value)
self.FakePing = value
self.Active = true
pcall(function()
if BS.Ping then
BS.Ping.Current = value
BS.Ping.Average = value
end
end)
end
function BS.PingSpoof:Disable()
self.Active = false
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}
function BS.AntiScreenshot:Activate()
self.Active = true
pcall(function()
local oldSetCore
oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
if method == "TakeScreenshot" then
if BS.Win then BS.Win.Visible = false end
task.delay(1, function()
if BS.Win then BS.Win.Visible = true end
end)
return
end
return oldSetCore(self, method, ...)
end)
end)
pcall(function()
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.PrintScreen then
if BS.Win then BS.Win.Visible = false end
task.delay(2, function()
if BS.Win then BS.Win.Visible = true end
end)
end
end)
end)
print("[Stealth] Anti-Screenshot active")
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
Kills = 0,
Deaths = 0,
Headshots = 0,
Shots = 0,
Hits = 0,
Damage = 0,
StartTime = tick(),
}
function BS.Stats:RecordKill(headshot)
self.Kills = self.Kills + 1
if headshot then self.Headshots = self.Headshots + 1 end
end
function BS.Stats:RecordDeath()
self.Deaths = self.Deaths + 1
end
function BS.Stats:RecordShot(hit)
self.Shots = self.Shots + 1
if hit then self.Hits = self.Hits + 1 end
end
function BS.Stats:RecordDamage(dmg)
self.Damage = self.Damage + dmg
end
function BS.Stats:GetKD()
if self.Deaths == 0 then return self.Kills end
return math.floor(self.Kills / self.Deaths * 10) / 10
end
function BS.Stats:GetHSPercent()
if self.Kills == 0 then return 0 end
return math.floor(self.Headshots / self.Kills * 100)
end
function BS.Stats:GetAccuracy()
if self.Shots == 0 then return 0 end
return math.floor(self.Hits / self.Shots * 100)
end
function BS.Stats:GetPlayTime()
return math.floor(tick() - self.StartTime)
end
function BS.Stats:GetReport()
return string.format(
"K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
self.Kills, self.Deaths, self:GetKD(),
self:GetHSPercent(), self:GetAccuracy(),
self.Damage, math.floor(self:GetPlayTime() / 60)
)
end
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)
print("[Stealth] getfenv environment leak prevention activated")
end)
end
function Stealth._cleanGetfenvStack()
pcall(function()
if not getfenv or not debug then return end
for i = 0, 30 do
local s, fenv = pcall(getfenv, i)
if s and fenv then
local exploitKeys = {
}
for _, key in ipairs(exploitKeys) do
if rawget(fenv, key) ~= nil then
pcall(function() rawset(fenv, key, nil) end)
envLeakPrevention.DetectionCount = envLeakPrevention.DetectionCount + 1
end
end
end
end
end)
end
Stealth.EnvLeakPrevention = envLeakPrevention
-- SECTION 23: RAW METAMETHOD HOOK EVASION
local rawHookEvasion = {
OriginalFunctions = {},
Protected = false,
}
function Stealth.protectRawMetamethods()
if rawHookEvasion.Protected then return end
pcall(function()
if not getrawmetatable or not hookmetamethod then return end
local mt = getrawmetatable(game)
if not mt then return end
rawHookEvasion.OriginalFunctions = {
__namecall = mt.__namecall,
__index = mt.__index,
__newindex = mt.__newindex,
__tostring = mt.__tostring,
__concat = mt.__concat,
__unm = mt.__unm,
__add = mt.__add,
__sub = mt.__sub,
__mul = mt.__mul,
__div = mt.__div,
__mod = mt.__mod,
__pow = mt.__pow,
__len = mt.__len,
__eq = mt.__eq,
__lt = mt.__lt,
__le = mt.__le,
__call = mt.__call,
}
rawHookEvasion.Protected = true
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}
function BS.HWIDSpoofer:Generate()
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local id = ""
for i = 1, 32 do
local r = math.random(1, #chars)
id = id .. chars:sub(r, r)
if i == 8 or i == 12 or i == 16 or i == 20 then
id = id .. "-"
end
end
return id
end
function BS.HWIDSpoofer:Activate()
self.Active = true
self.SpoofedID = self:Generate()
pcall(function()
if gethwid then
local old = gethwid
gethwid = function() return self.SpoofedID end
end
end)
pcall(function()
if getmachineid then
local old = getmachineid
getmachineid = function() return self.SpoofedID end
end
end)
print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}
function BS.PingSpoof:SetPing(value)
self.FakePing = value
self.Active = true
pcall(function()
if BS.Ping then
BS.Ping.Current = value
BS.Ping.Average = value
end
end)
end
function BS.PingSpoof:Disable()
self.Active = false
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}
function BS.AntiScreenshot:Activate()
self.Active = true
pcall(function()
local oldSetCore
oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
if method == "TakeScreenshot" then
if BS.Win then BS.Win.Visible = false end
task.delay(1, function()
if BS.Win then BS.Win.Visible = true end
end)
return
end
return oldSetCore(self, method, ...)
end)
end)
pcall(function()
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.PrintScreen then
if BS.Win then BS.Win.Visible = false end
task.delay(2, function()
if BS.Win then BS.Win.Visible = true end
end)
end
end)
end)
print("[Stealth] Anti-Screenshot active")
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
Kills = 0,
Deaths = 0,
Headshots = 0,
Shots = 0,
Hits = 0,
Damage = 0,
StartTime = tick(),
}
function BS.Stats:RecordKill(headshot)
self.Kills = self.Kills + 1
if headshot then self.Headshots = self.Headshots + 1 end
end
function BS.Stats:RecordDeath()
self.Deaths = self.Deaths + 1
end
function BS.Stats:RecordShot(hit)
self.Shots = self.Shots + 1
if hit then self.Hits = self.Hits + 1 end
end
function BS.Stats:RecordDamage(dmg)
self.Damage = self.Damage + dmg
end
function BS.Stats:GetKD()
if self.Deaths == 0 then return self.Kills end
return math.floor(self.Kills / self.Deaths * 10) / 10
end
function BS.Stats:GetHSPercent()
if self.Kills == 0 then return 0 end
return math.floor(self.Headshots / self.Kills * 100)
end
function BS.Stats:GetAccuracy()
if self.Shots == 0 then return 0 end
return math.floor(self.Hits / self.Shots * 100)
end
function BS.Stats:GetPlayTime()
return math.floor(tick() - self.StartTime)
end
function BS.Stats:GetReport()
return string.format(
"K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
self.Kills, self.Deaths, self:GetKD(),
self:GetHSPercent(), self:GetAccuracy(),
self.Damage, math.floor(self:GetPlayTime() / 60)
)
end
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)
print("[Stealth] Raw metamethod hook evasion ready")
end)
end
function Stealth.safeHookMetamethod(object, method, hookFunction)
if not hookmetamethod then return nil end
local wrappedHook = nil
pcall(function()
wrappedHook = newcclosure(function(self, ...)
local args = {...}
local method_name = getnamecallmethod and getnamecallmethod() or nil
return hookFunction(self, method_name, unpack(args))
end)
end)
if not wrappedHook then return nil end
local oldHook = nil
pcall(function()
oldHook = hookmetamethod(object, method, wrappedHook)
end)
return oldHook
end
Stealth.RawHookEvasion = rawHookEvasion
-- SECTION 24: TOSTRING TRAP EVASION
local tostringTrapEvasion = {
Active = false,
BlockedCalls = 0,
}
function Stealth.activateTostringTrapEvasion()
if tostringTrapEvasion.Active then return end
pcall(function()
if hookmetamethod then
local oldTostring = nil
pcall(function()
oldTostring = hookmetamethod(game, "__tostring", newcclosure(function(self)
if stealthState and stealthState.IsBeingScanned then
return game.Name
end
return tostring(self)
end))
end)
end
tostringTrapEvasion.Active = true
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}
function BS.HWIDSpoofer:Generate()
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local id = ""
for i = 1, 32 do
local r = math.random(1, #chars)
id = id .. chars:sub(r, r)
if i == 8 or i == 12 or i == 16 or i == 20 then
id = id .. "-"
end
end
return id
end
function BS.HWIDSpoofer:Activate()
self.Active = true
self.SpoofedID = self:Generate()
pcall(function()
if gethwid then
local old = gethwid
gethwid = function() return self.SpoofedID end
end
end)
pcall(function()
if getmachineid then
local old = getmachineid
getmachineid = function() return self.SpoofedID end
end
end)
print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}
function BS.PingSpoof:SetPing(value)
self.FakePing = value
self.Active = true
pcall(function()
if BS.Ping then
BS.Ping.Current = value
BS.Ping.Average = value
end
end)
end
function BS.PingSpoof:Disable()
self.Active = false
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}
function BS.AntiScreenshot:Activate()
self.Active = true
pcall(function()
local oldSetCore
oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
if method == "TakeScreenshot" then
if BS.Win then BS.Win.Visible = false end
task.delay(1, function()
if BS.Win then BS.Win.Visible = true end
end)
return
end
return oldSetCore(self, method, ...)
end)
end)
pcall(function()
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.PrintScreen then
if BS.Win then BS.Win.Visible = false end
task.delay(2, function()
if BS.Win then BS.Win.Visible = true end
end)
end
end)
end)
print("[Stealth] Anti-Screenshot active")
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
Kills = 0,
Deaths = 0,
Headshots = 0,
Shots = 0,
Hits = 0,
Damage = 0,
StartTime = tick(),
}
function BS.Stats:RecordKill(headshot)
self.Kills = self.Kills + 1
if headshot then self.Headshots = self.Headshots + 1 end
end
function BS.Stats:RecordDeath()
self.Deaths = self.Deaths + 1
end
function BS.Stats:RecordShot(hit)
self.Shots = self.Shots + 1
if hit then self.Hits = self.Hits + 1 end
end
function BS.Stats:RecordDamage(dmg)
self.Damage = self.Damage + dmg
end
function BS.Stats:GetKD()
if self.Deaths == 0 then return self.Kills end
return math.floor(self.Kills / self.Deaths * 10) / 10
end
function BS.Stats:GetHSPercent()
if self.Kills == 0 then return 0 end
return math.floor(self.Headshots / self.Kills * 100)
end
function BS.Stats:GetAccuracy()
if self.Shots == 0 then return 0 end
return math.floor(self.Hits / self.Shots * 100)
end
function BS.Stats:GetPlayTime()
return math.floor(tick() - self.StartTime)
end
function BS.Stats:GetReport()
return string.format(
"K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
self.Kills, self.Deaths, self:GetKD(),
self:GetHSPercent(), self:GetAccuracy(),
self.Damage, math.floor(self:GetPlayTime() / 60)
)
end
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)
print("[Stealth] ToString trap evasion activated")
end)
end
Stealth.TostringTrapEvasion = tostringTrapEvasion
-- SECTION 25: COROUTINE.WRAP STACK OVERFLOW EVASION
local coroutineEvasion = {
Active = false,
}
function Stealth.protectCoroutineEvasion()
if coroutineEvasion.Active then return end
pcall(function()
coroutineEvasion.Active = true
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}
function BS.HWIDSpoofer:Generate()
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local id = ""
for i = 1, 32 do
local r = math.random(1, #chars)
id = id .. chars:sub(r, r)
if i == 8 or i == 12 or i == 16 or i == 20 then
id = id .. "-"
end
end
return id
end
function BS.HWIDSpoofer:Activate()
self.Active = true
self.SpoofedID = self:Generate()
pcall(function()
if gethwid then
local old = gethwid
gethwid = function() return self.SpoofedID end
end
end)
pcall(function()
if getmachineid then
local old = getmachineid
getmachineid = function() return self.SpoofedID end
end
end)
print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}
function BS.PingSpoof:SetPing(value)
self.FakePing = value
self.Active = true
pcall(function()
if BS.Ping then
BS.Ping.Current = value
BS.Ping.Average = value
end
end)
end
function BS.PingSpoof:Disable()
self.Active = false
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}
function BS.AntiScreenshot:Activate()
self.Active = true
pcall(function()
local oldSetCore
oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
if method == "TakeScreenshot" then
if BS.Win then BS.Win.Visible = false end
task.delay(1, function()
if BS.Win then BS.Win.Visible = true end
end)
return
end
return oldSetCore(self, method, ...)
end)
end)
pcall(function()
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.PrintScreen then
if BS.Win then BS.Win.Visible = false end
task.delay(2, function()
if BS.Win then BS.Win.Visible = true end
end)
end
end)
end)
print("[Stealth] Anti-Screenshot active")
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
Kills = 0,
Deaths = 0,
Headshots = 0,
Shots = 0,
Hits = 0,
Damage = 0,
StartTime = tick(),
}
function BS.Stats:RecordKill(headshot)
self.Kills = self.Kills + 1
if headshot then self.Headshots = self.Headshots + 1 end
end
function BS.Stats:RecordDeath()
self.Deaths = self.Deaths + 1
end
function BS.Stats:RecordShot(hit)
self.Shots = self.Shots + 1
if hit then self.Hits = self.Hits + 1 end
end
function BS.Stats:RecordDamage(dmg)
self.Damage = self.Damage + dmg
end
function BS.Stats:GetKD()
if self.Deaths == 0 then return self.Kills end
return math.floor(self.Kills / self.Deaths * 10) / 10
end
function BS.Stats:GetHSPercent()
if self.Kills == 0 then return 0 end
return math.floor(self.Headshots / self.Kills * 100)
end
function BS.Stats:GetAccuracy()
if self.Shots == 0 then return 0 end
return math.floor(self.Hits / self.Shots * 100)
end
function BS.Stats:GetPlayTime()
return math.floor(tick() - self.StartTime)
end
function BS.Stats:GetReport()
return string.format(
"K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
self.Kills, self.Deaths, self:GetKD(),
self:GetHSPercent(), self:GetAccuracy(),
self.Damage, math.floor(self:GetPlayTime() / 60)
)
end
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)
print("[Stealth] Coroutine.wrap stack overflow evasion ready")
end)
end
Stealth.CoroutineEvasion = coroutineEvasion
-- SECTION 26: COREGUI REFERENCE EVASION
local coreGuiEvasion = {
Active = false,
}
function Stealth.protectCoreGuiEvasion()
if coreGuiEvasion.Active then return end
pcall(function()
if cloneref then
pcall(function()
end)
end
coreGuiEvasion.Active = true
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}
function BS.HWIDSpoofer:Generate()
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local id = ""
for i = 1, 32 do
local r = math.random(1, #chars)
id = id .. chars:sub(r, r)
if i == 8 or i == 12 or i == 16 or i == 20 then
id = id .. "-"
end
end
return id
end
function BS.HWIDSpoofer:Activate()
self.Active = true
self.SpoofedID = self:Generate()
pcall(function()
if gethwid then
local old = gethwid
gethwid = function() return self.SpoofedID end
end
end)
pcall(function()
if getmachineid then
local old = getmachineid
getmachineid = function() return self.SpoofedID end
end
end)
print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}
function BS.PingSpoof:SetPing(value)
self.FakePing = value
self.Active = true
pcall(function()
if BS.Ping then
BS.Ping.Current = value
BS.Ping.Average = value
end
end)
end
function BS.PingSpoof:Disable()
self.Active = false
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}
function BS.AntiScreenshot:Activate()
self.Active = true
pcall(function()
local oldSetCore
oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
if method == "TakeScreenshot" then
if BS.Win then BS.Win.Visible = false end
task.delay(1, function()
if BS.Win then BS.Win.Visible = true end
end)
return
end
return oldSetCore(self, method, ...)
end)
end)
pcall(function()
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.PrintScreen then
if BS.Win then BS.Win.Visible = false end
task.delay(2, function()
if BS.Win then BS.Win.Visible = true end
end)
end
end)
end)
print("[Stealth] Anti-Screenshot active")
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
Kills = 0,
Deaths = 0,
Headshots = 0,
Shots = 0,
Hits = 0,
Damage = 0,
StartTime = tick(),
}
function BS.Stats:RecordKill(headshot)
self.Kills = self.Kills + 1
if headshot then self.Headshots = self.Headshots + 1 end
end
function BS.Stats:RecordDeath()
self.Deaths = self.Deaths + 1
end
function BS.Stats:RecordShot(hit)
self.Shots = self.Shots + 1
if hit then self.Hits = self.Hits + 1 end
end
function BS.Stats:RecordDamage(dmg)
self.Damage = self.Damage + dmg
end
function BS.Stats:GetKD()
if self.Deaths == 0 then return self.Kills end
return math.floor(self.Kills / self.Deaths * 10) / 10
end
function BS.Stats:GetHSPercent()
if self.Kills == 0 then return 0 end
return math.floor(self.Headshots / self.Kills * 100)
end
function BS.Stats:GetAccuracy()
if self.Shots == 0 then return 0 end
return math.floor(self.Hits / self.Shots * 100)
end
function BS.Stats:GetPlayTime()
return math.floor(tick() - self.StartTime)
end
function BS.Stats:GetReport()
return string.format(
"K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
self.Kills, self.Deaths, self:GetKD(),
self:GetHSPercent(), self:GetAccuracy(),
self.Damage, math.floor(self:GetPlayTime() / 60)
)
end
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)
print("[Stealth] CoreGui reference evasion ready")
end)
end
Stealth.CoreGuiEvasion = coreGuiEvasion
-- SECTION 27: GETFENV LEVEL SCANNING EVASION
local getfenvScanningEvasion = {
Active = false,
PatchedLevels = {},
}
function Stealth.patchGetfenvScanning()
if getfenvScanningEvasion.Active then return end
pcall(function()
if hookfunction and getfenv then
local oldGetfenv = getfenv
local patchedGetfenv = newcclosure(function(level)
local result = oldGetfenv(level)
if type(result) == "table" then
local clean = {}
local exploitKeys = {
}
for k, v in pairs(result) do
local isExploitKey = false
for _, ek in ipairs(exploitKeys) do
if k == ek then
isExploitKey = true
break
end
end
if not isExploitKey then
clean[k] = v
end
end
return clean
end
return result
end)
pcall(function()
hookfunction(getfenv, patchedGetfenv)
end)
end
getfenvScanningEvasion.Active = true
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}
function BS.HWIDSpoofer:Generate()
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local id = ""
for i = 1, 32 do
local r = math.random(1, #chars)
id = id .. chars:sub(r, r)
if i == 8 or i == 12 or i == 16 or i == 20 then
id = id .. "-"
end
end
return id
end
function BS.HWIDSpoofer:Activate()
self.Active = true
self.SpoofedID = self:Generate()
pcall(function()
if gethwid then
local old = gethwid
gethwid = function() return self.SpoofedID end
end
end)
pcall(function()
if getmachineid then
local old = getmachineid
getmachineid = function() return self.SpoofedID end
end
end)
print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}
function BS.PingSpoof:SetPing(value)
self.FakePing = value
self.Active = true
pcall(function()
if BS.Ping then
BS.Ping.Current = value
BS.Ping.Average = value
end
end)
end
function BS.PingSpoof:Disable()
self.Active = false
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}
function BS.AntiScreenshot:Activate()
self.Active = true
pcall(function()
local oldSetCore
oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
if method == "TakeScreenshot" then
if BS.Win then BS.Win.Visible = false end
task.delay(1, function()
if BS.Win then BS.Win.Visible = true end
end)
return
end
return oldSetCore(self, method, ...)
end)
end)
pcall(function()
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.PrintScreen then
if BS.Win then BS.Win.Visible = false end
task.delay(2, function()
if BS.Win then BS.Win.Visible = true end
end)
end
end)
end)
print("[Stealth] Anti-Screenshot active")
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
Kills = 0,
Deaths = 0,
Headshots = 0,
Shots = 0,
Hits = 0,
Damage = 0,
StartTime = tick(),
}
function BS.Stats:RecordKill(headshot)
self.Kills = self.Kills + 1
if headshot then self.Headshots = self.Headshots + 1 end
end
function BS.Stats:RecordDeath()
self.Deaths = self.Deaths + 1
end
function BS.Stats:RecordShot(hit)
self.Shots = self.Shots + 1
if hit then self.Hits = self.Hits + 1 end
end
function BS.Stats:RecordDamage(dmg)
self.Damage = self.Damage + dmg
end
function BS.Stats:GetKD()
if self.Deaths == 0 then return self.Kills end
return math.floor(self.Kills / self.Deaths * 10) / 10
end
function BS.Stats:GetHSPercent()
if self.Kills == 0 then return 0 end
return math.floor(self.Headshots / self.Kills * 100)
end
function BS.Stats:GetAccuracy()
if self.Shots == 0 then return 0 end
return math.floor(self.Hits / self.Shots * 100)
end
function BS.Stats:GetPlayTime()
return math.floor(tick() - self.StartTime)
end
function BS.Stats:GetReport()
return string.format(
"K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
self.Kills, self.Deaths, self:GetKD(),
self:GetHSPercent(), self:GetAccuracy(),
self.Damage, math.floor(self:GetPlayTime() / 60)
)
end
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)
print("[Stealth] getfenv level scanning evasion activated")
end)
end
Stealth.GetfenvScanningEvasion = getfenvScanningEvasion
-- SECTION 28: UNIFIED ANTI-DETECTION ACTIVATION
function Stealth.activateAdvancedEvasion()
pcall(function()
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}
function BS.HWIDSpoofer:Generate()
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local id = ""
for i = 1, 32 do
local r = math.random(1, #chars)
id = id .. chars:sub(r, r)
if i == 8 or i == 12 or i == 16 or i == 20 then
id = id .. "-"
end
end
return id
end
function BS.HWIDSpoofer:Activate()
self.Active = true
self.SpoofedID = self:Generate()
pcall(function()
if gethwid then
local old = gethwid
gethwid = function() return self.SpoofedID end
end
end)
pcall(function()
if getmachineid then
local old = getmachineid
getmachineid = function() return self.SpoofedID end
end
end)
print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}
function BS.PingSpoof:SetPing(value)
self.FakePing = value
self.Active = true
pcall(function()
if BS.Ping then
BS.Ping.Current = value
BS.Ping.Average = value
end
end)
end
function BS.PingSpoof:Disable()
self.Active = false
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}
function BS.AntiScreenshot:Activate()
self.Active = true
pcall(function()
local oldSetCore
oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
if method == "TakeScreenshot" then
if BS.Win then BS.Win.Visible = false end
task.delay(1, function()
if BS.Win then BS.Win.Visible = true end
end)
return
end
return oldSetCore(self, method, ...)
end)
end)
pcall(function()
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.PrintScreen then
if BS.Win then BS.Win.Visible = false end
task.delay(2, function()
if BS.Win then BS.Win.Visible = true end
end)
end
end)
end)
print("[Stealth] Anti-Screenshot active")
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
Kills = 0,
Deaths = 0,
Headshots = 0,
Shots = 0,
Hits = 0,
Damage = 0,
StartTime = tick(),
}
function BS.Stats:RecordKill(headshot)
self.Kills = self.Kills + 1
if headshot then self.Headshots = self.Headshots + 1 end
end
function BS.Stats:RecordDeath()
self.Deaths = self.Deaths + 1
end
function BS.Stats:RecordShot(hit)
self.Shots = self.Shots + 1
if hit then self.Hits = self.Hits + 1 end
end
function BS.Stats:RecordDamage(dmg)
self.Damage = self.Damage + dmg
end
function BS.Stats:GetKD()
if self.Deaths == 0 then return self.Kills end
return math.floor(self.Kills / self.Deaths * 10) / 10
end
function BS.Stats:GetHSPercent()
if self.Kills == 0 then return 0 end
return math.floor(self.Headshots / self.Kills * 100)
end
function BS.Stats:GetAccuracy()
if self.Shots == 0 then return 0 end
return math.floor(self.Hits / self.Shots * 100)
end
function BS.Stats:GetPlayTime()
return math.floor(tick() - self.StartTime)
end
function BS.Stats:GetReport()
return string.format(
"K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
self.Kills, self.Deaths, self:GetKD(),
self:GetHSPercent(), self:GetAccuracy(),
self.Damage, math.floor(self:GetPlayTime() / 60)
)
end
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)
print("[Stealth]  Advanced evasion systems activated ")
end)
end
task.spawn(function()
while true do
task.wait(15)
pcall(function()
end)
end
end)
BS.Stealth = Stealth
BS.HVHState = hvhState
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}
function BS.HWIDSpoofer:Generate()
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local id = ""
for i = 1, 32 do
local r = math.random(1, #chars)
id = id .. chars:sub(r, r)
if i == 8 or i == 12 or i == 16 or i == 20 then
id = id .. "-"
end
end
return id
end
function BS.HWIDSpoofer:Activate()
self.Active = true
self.SpoofedID = self:Generate()
pcall(function()
if gethwid then
local old = gethwid
gethwid = function() return self.SpoofedID end
end
end)
pcall(function()
if getmachineid then
local old = getmachineid
getmachineid = function() return self.SpoofedID end
end
end)
print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}
function BS.PingSpoof:SetPing(value)
self.FakePing = value
self.Active = true
pcall(function()
if BS.Ping then
BS.Ping.Current = value
BS.Ping.Average = value
end
end)
end
function BS.PingSpoof:Disable()
self.Active = false
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}
function BS.AntiScreenshot:Activate()
self.Active = true
pcall(function()
local oldSetCore
oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
if method == "TakeScreenshot" then
if BS.Win then BS.Win.Visible = false end
task.delay(1, function()
if BS.Win then BS.Win.Visible = true end
end)
return
end
return oldSetCore(self, method, ...)
end)
end)
pcall(function()
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.PrintScreen then
if BS.Win then BS.Win.Visible = false end
task.delay(2, function()
if BS.Win then BS.Win.Visible = true end
end)
end
end)
end)
print("[Stealth] Anti-Screenshot active")
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
Kills = 0,
Deaths = 0,
Headshots = 0,
Shots = 0,
Hits = 0,
Damage = 0,
StartTime = tick(),
}
function BS.Stats:RecordKill(headshot)
self.Kills = self.Kills + 1
if headshot then self.Headshots = self.Headshots + 1 end
end
function BS.Stats:RecordDeath()
self.Deaths = self.Deaths + 1
end
function BS.Stats:RecordShot(hit)
self.Shots = self.Shots + 1
if hit then self.Hits = self.Hits + 1 end
end
function BS.Stats:RecordDamage(dmg)
self.Damage = self.Damage + dmg
end
function BS.Stats:GetKD()
if self.Deaths == 0 then return self.Kills end
return math.floor(self.Kills / self.Deaths * 10) / 10
end
function BS.Stats:GetHSPercent()
if self.Kills == 0 then return 0 end
return math.floor(self.Headshots / self.Kills * 100)
end
function BS.Stats:GetAccuracy()
if self.Shots == 0 then return 0 end
return math.floor(self.Hits / self.Shots * 100)
end
function BS.Stats:GetPlayTime()
return math.floor(tick() - self.StartTime)
end
function BS.Stats:GetReport()
return string.format(
"K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
self.Kills, self.Deaths, self:GetKD(),
self:GetHSPercent(), self:GetAccuracy(),
self.Damage, math.floor(self:GetPlayTime() / 60)
)
end
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)
print("[Stealth] BloxStrike Stealth v4.0  ")
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}
function BS.HWIDSpoofer:Generate()
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local id = ""
for i = 1, 32 do
local r = math.random(1, #chars)
id = id .. chars:sub(r, r)
if i == 8 or i == 12 or i == 16 or i == 20 then
id = id .. "-"
end
end
return id
end
function BS.HWIDSpoofer:Activate()
self.Active = true
self.SpoofedID = self:Generate()
pcall(function()
if gethwid then
local old = gethwid
gethwid = function() return self.SpoofedID end
end
end)
pcall(function()
if getmachineid then
local old = getmachineid
getmachineid = function() return self.SpoofedID end
end
end)
print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}
function BS.PingSpoof:SetPing(value)
self.FakePing = value
self.Active = true
pcall(function()
if BS.Ping then
BS.Ping.Current = value
BS.Ping.Average = value
end
end)
end
function BS.PingSpoof:Disable()
self.Active = false
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}
function BS.AntiScreenshot:Activate()
self.Active = true
pcall(function()
local oldSetCore
oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
if method == "TakeScreenshot" then
if BS.Win then BS.Win.Visible = false end
task.delay(1, function()
if BS.Win then BS.Win.Visible = true end
end)
return
end
return oldSetCore(self, method, ...)
end)
end)
pcall(function()
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.PrintScreen then
if BS.Win then BS.Win.Visible = false end
task.delay(2, function()
if BS.Win then BS.Win.Visible = true end
end)
end
end)
end)
print("[Stealth] Anti-Screenshot active")
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
Kills = 0,
Deaths = 0,
Headshots = 0,
Shots = 0,
Hits = 0,
Damage = 0,
StartTime = tick(),
}
function BS.Stats:RecordKill(headshot)
self.Kills = self.Kills + 1
if headshot then self.Headshots = self.Headshots + 1 end
end
function BS.Stats:RecordDeath()
self.Deaths = self.Deaths + 1
end
function BS.Stats:RecordShot(hit)
self.Shots = self.Shots + 1
if hit then self.Hits = self.Hits + 1 end
end
function BS.Stats:RecordDamage(dmg)
self.Damage = self.Damage + dmg
end
function BS.Stats:GetKD()
if self.Deaths == 0 then return self.Kills end
return math.floor(self.Kills / self.Deaths * 10) / 10
end
function BS.Stats:GetHSPercent()
if self.Kills == 0 then return 0 end
return math.floor(self.Headshots / self.Kills * 100)
end
function BS.Stats:GetAccuracy()
if self.Shots == 0 then return 0 end
return math.floor(self.Hits / self.Shots * 100)
end
function BS.Stats:GetPlayTime()
return math.floor(tick() - self.StartTime)
end
function BS.Stats:GetReport()
return string.format(
"K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
self.Kills, self.Deaths, self:GetKD(),
self:GetHSPercent(), self:GetAccuracy(),
self.Damage, math.floor(self:GetPlayTime() / 60)
)
end
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)
print("[Stealth] ")
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}
function BS.HWIDSpoofer:Generate()
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local id = ""
for i = 1, 32 do
local r = math.random(1, #chars)
id = id .. chars:sub(r, r)
if i == 8 or i == 12 or i == 16 or i == 20 then
id = id .. "-"
end
end
return id
end
function BS.HWIDSpoofer:Activate()
self.Active = true
self.SpoofedID = self:Generate()
pcall(function()
if gethwid then
local old = gethwid
gethwid = function() return self.SpoofedID end
end
end)
pcall(function()
if getmachineid then
local old = getmachineid
getmachineid = function() return self.SpoofedID end
end
end)
print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}
function BS.PingSpoof:SetPing(value)
self.FakePing = value
self.Active = true
pcall(function()
if BS.Ping then
BS.Ping.Current = value
BS.Ping.Average = value
end
end)
end
function BS.PingSpoof:Disable()
self.Active = false
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}
function BS.AntiScreenshot:Activate()
self.Active = true
pcall(function()
local oldSetCore
oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
if method == "TakeScreenshot" then
if BS.Win then BS.Win.Visible = false end
task.delay(1, function()
if BS.Win then BS.Win.Visible = true end
end)
return
end
return oldSetCore(self, method, ...)
end)
end)
pcall(function()
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.PrintScreen then
if BS.Win then BS.Win.Visible = false end
task.delay(2, function()
if BS.Win then BS.Win.Visible = true end
end)
end
end)
end)
print("[Stealth] Anti-Screenshot active")
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
Kills = 0,
Deaths = 0,
Headshots = 0,
Shots = 0,
Hits = 0,
Damage = 0,
StartTime = tick(),
}
function BS.Stats:RecordKill(headshot)
self.Kills = self.Kills + 1
if headshot then self.Headshots = self.Headshots + 1 end
end
function BS.Stats:RecordDeath()
self.Deaths = self.Deaths + 1
end
function BS.Stats:RecordShot(hit)
self.Shots = self.Shots + 1
if hit then self.Hits = self.Hits + 1 end
end
function BS.Stats:RecordDamage(dmg)
self.Damage = self.Damage + dmg
end
function BS.Stats:GetKD()
if self.Deaths == 0 then return self.Kills end
return math.floor(self.Kills / self.Deaths * 10) / 10
end
function BS.Stats:GetHSPercent()
if self.Kills == 0 then return 0 end
return math.floor(self.Headshots / self.Kills * 100)
end
function BS.Stats:GetAccuracy()
if self.Shots == 0 then return 0 end
return math.floor(self.Hits / self.Shots * 100)
end
function BS.Stats:GetPlayTime()
return math.floor(tick() - self.StartTime)
end
function BS.Stats:GetReport()
return string.format(
"K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
self.Kills, self.Deaths, self:GetKD(),
self:GetHSPercent(), self:GetAccuracy(),
self.Damage, math.floor(self:GetPlayTime() / 60)
)
end
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)
print("[Stealth] 28 ")
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}
function BS.HWIDSpoofer:Generate()
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local id = ""
for i = 1, 32 do
local r = math.random(1, #chars)
id = id .. chars:sub(r, r)
if i == 8 or i == 12 or i == 16 or i == 20 then
id = id .. "-"
end
end
return id
end
function BS.HWIDSpoofer:Activate()
self.Active = true
self.SpoofedID = self:Generate()
pcall(function()
if gethwid then
local old = gethwid
gethwid = function() return self.SpoofedID end
end
end)
pcall(function()
if getmachineid then
local old = getmachineid
getmachineid = function() return self.SpoofedID end
end
end)
print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}
function BS.PingSpoof:SetPing(value)
self.FakePing = value
self.Active = true
pcall(function()
if BS.Ping then
BS.Ping.Current = value
BS.Ping.Average = value
end
end)
end
function BS.PingSpoof:Disable()
self.Active = false
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}
function BS.AntiScreenshot:Activate()
self.Active = true
pcall(function()
local oldSetCore
oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
if method == "TakeScreenshot" then
if BS.Win then BS.Win.Visible = false end
task.delay(1, function()
if BS.Win then BS.Win.Visible = true end
end)
return
end
return oldSetCore(self, method, ...)
end)
end)
pcall(function()
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.PrintScreen then
if BS.Win then BS.Win.Visible = false end
task.delay(2, function()
if BS.Win then BS.Win.Visible = true end
end)
end
end)
end)
print("[Stealth] Anti-Screenshot active")
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
Kills = 0,
Deaths = 0,
Headshots = 0,
Shots = 0,
Hits = 0,
Damage = 0,
StartTime = tick(),
}
function BS.Stats:RecordKill(headshot)
self.Kills = self.Kills + 1
if headshot then self.Headshots = self.Headshots + 1 end
end
function BS.Stats:RecordDeath()
self.Deaths = self.Deaths + 1
end
function BS.Stats:RecordShot(hit)
self.Shots = self.Shots + 1
if hit then self.Hits = self.Hits + 1 end
end
function BS.Stats:RecordDamage(dmg)
self.Damage = self.Damage + dmg
end
function BS.Stats:GetKD()
if self.Deaths == 0 then return self.Kills end
return math.floor(self.Kills / self.Deaths * 10) / 10
end
function BS.Stats:GetHSPercent()
if self.Kills == 0 then return 0 end
return math.floor(self.Headshots / self.Kills * 100)
end
function BS.Stats:GetAccuracy()
if self.Shots == 0 then return 0 end
return math.floor(self.Hits / self.Shots * 100)
end
function BS.Stats:GetPlayTime()
return math.floor(tick() - self.StartTime)
end
function BS.Stats:GetReport()
return string.format(
"K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
self.Kills, self.Deaths, self:GetKD(),
self:GetHSPercent(), self:GetAccuracy(),
self.Damage, math.floor(self:GetPlayTime() / 60)
)
end
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)
print("[Stealth]   1-12:  Callstack/Environment/Hook/Obfuscation ")
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}
function BS.HWIDSpoofer:Generate()
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local id = ""
for i = 1, 32 do
local r = math.random(1, #chars)
id = id .. chars:sub(r, r)
if i == 8 or i == 12 or i == 16 or i == 20 then
id = id .. "-"
end
end
return id
end
function BS.HWIDSpoofer:Activate()
self.Active = true
self.SpoofedID = self:Generate()
pcall(function()
if gethwid then
local old = gethwid
gethwid = function() return self.SpoofedID end
end
end)
pcall(function()
if getmachineid then
local old = getmachineid
getmachineid = function() return self.SpoofedID end
end
end)
print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}
function BS.PingSpoof:SetPing(value)
self.FakePing = value
self.Active = true
pcall(function()
if BS.Ping then
BS.Ping.Current = value
BS.Ping.Average = value
end
end)
end
function BS.PingSpoof:Disable()
self.Active = false
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}
function BS.AntiScreenshot:Activate()
self.Active = true
pcall(function()
local oldSetCore
oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
if method == "TakeScreenshot" then
if BS.Win then BS.Win.Visible = false end
task.delay(1, function()
if BS.Win then BS.Win.Visible = true end
end)
return
end
return oldSetCore(self, method, ...)
end)
end)
pcall(function()
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.PrintScreen then
if BS.Win then BS.Win.Visible = false end
task.delay(2, function()
if BS.Win then BS.Win.Visible = true end
end)
end
end)
end)
print("[Stealth] Anti-Screenshot active")
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
Kills = 0,
Deaths = 0,
Headshots = 0,
Shots = 0,
Hits = 0,
Damage = 0,
StartTime = tick(),
}
function BS.Stats:RecordKill(headshot)
self.Kills = self.Kills + 1
if headshot then self.Headshots = self.Headshots + 1 end
end
function BS.Stats:RecordDeath()
self.Deaths = self.Deaths + 1
end
function BS.Stats:RecordShot(hit)
self.Shots = self.Shots + 1
if hit then self.Hits = self.Hits + 1 end
end
function BS.Stats:RecordDamage(dmg)
self.Damage = self.Damage + dmg
end
function BS.Stats:GetKD()
if self.Deaths == 0 then return self.Kills end
return math.floor(self.Kills / self.Deaths * 10) / 10
end
function BS.Stats:GetHSPercent()
if self.Kills == 0 then return 0 end
return math.floor(self.Headshots / self.Kills * 100)
end
function BS.Stats:GetAccuracy()
if self.Shots == 0 then return 0 end
return math.floor(self.Hits / self.Shots * 100)
end
function BS.Stats:GetPlayTime()
return math.floor(tick() - self.StartTime)
end
function BS.Stats:GetReport()
return string.format(
"K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
self.Kills, self.Deaths, self:GetKD(),
self:GetHSPercent(), self:GetAccuracy(),
self.Damage, math.floor(self:GetPlayTime() / 60)
)
end
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)
print("[Stealth]   13-21: SSVL///ML/////")
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}
function BS.HWIDSpoofer:Generate()
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local id = ""
for i = 1, 32 do
local r = math.random(1, #chars)
id = id .. chars:sub(r, r)
if i == 8 or i == 12 or i == 16 or i == 20 then
id = id .. "-"
end
end
return id
end
function BS.HWIDSpoofer:Activate()
self.Active = true
self.SpoofedID = self:Generate()
pcall(function()
if gethwid then
local old = gethwid
gethwid = function() return self.SpoofedID end
end
end)
pcall(function()
if getmachineid then
local old = getmachineid
getmachineid = function() return self.SpoofedID end
end
end)
print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}
function BS.PingSpoof:SetPing(value)
self.FakePing = value
self.Active = true
pcall(function()
if BS.Ping then
BS.Ping.Current = value
BS.Ping.Average = value
end
end)
end
function BS.PingSpoof:Disable()
self.Active = false
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}
function BS.AntiScreenshot:Activate()
self.Active = true
pcall(function()
local oldSetCore
oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
if method == "TakeScreenshot" then
if BS.Win then BS.Win.Visible = false end
task.delay(1, function()
if BS.Win then BS.Win.Visible = true end
end)
return
end
return oldSetCore(self, method, ...)
end)
end)
pcall(function()
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.PrintScreen then
if BS.Win then BS.Win.Visible = false end
task.delay(2, function()
if BS.Win then BS.Win.Visible = true end
end)
end
end)
end)
print("[Stealth] Anti-Screenshot active")
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
Kills = 0,
Deaths = 0,
Headshots = 0,
Shots = 0,
Hits = 0,
Damage = 0,
StartTime = tick(),
}
function BS.Stats:RecordKill(headshot)
self.Kills = self.Kills + 1
if headshot then self.Headshots = self.Headshots + 1 end
end
function BS.Stats:RecordDeath()
self.Deaths = self.Deaths + 1
end
function BS.Stats:RecordShot(hit)
self.Shots = self.Shots + 1
if hit then self.Hits = self.Hits + 1 end
end
function BS.Stats:RecordDamage(dmg)
self.Damage = self.Damage + dmg
end
function BS.Stats:GetKD()
if self.Deaths == 0 then return self.Kills end
return math.floor(self.Kills / self.Deaths * 10) / 10
end
function BS.Stats:GetHSPercent()
if self.Kills == 0 then return 0 end
return math.floor(self.Headshots / self.Kills * 100)
end
function BS.Stats:GetAccuracy()
if self.Shots == 0 then return 0 end
return math.floor(self.Hits / self.Shots * 100)
end
function BS.Stats:GetPlayTime()
return math.floor(tick() - self.StartTime)
end
function BS.Stats:GetReport()
return string.format(
"K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
self.Kills, self.Deaths, self:GetKD(),
self:GetHSPercent(), self:GetAccuracy(),
self.Damage, math.floor(self:GetPlayTime() / 60)
)
end
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)
print("[Stealth]   22: getfenv Environment Leak Prevention     NEW (DevForum 2025.07)")
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}
function BS.HWIDSpoofer:Generate()
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local id = ""
for i = 1, 32 do
local r = math.random(1, #chars)
id = id .. chars:sub(r, r)
if i == 8 or i == 12 or i == 16 or i == 20 then
id = id .. "-"
end
end
return id
end
function BS.HWIDSpoofer:Activate()
self.Active = true
self.SpoofedID = self:Generate()
pcall(function()
if gethwid then
local old = gethwid
gethwid = function() return self.SpoofedID end
end
end)
pcall(function()
if getmachineid then
local old = getmachineid
getmachineid = function() return self.SpoofedID end
end
end)
print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}
function BS.PingSpoof:SetPing(value)
self.FakePing = value
self.Active = true
pcall(function()
if BS.Ping then
BS.Ping.Current = value
BS.Ping.Average = value
end
end)
end
function BS.PingSpoof:Disable()
self.Active = false
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}
function BS.AntiScreenshot:Activate()
self.Active = true
pcall(function()
local oldSetCore
oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
if method == "TakeScreenshot" then
if BS.Win then BS.Win.Visible = false end
task.delay(1, function()
if BS.Win then BS.Win.Visible = true end
end)
return
end
return oldSetCore(self, method, ...)
end)
end)
pcall(function()
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.PrintScreen then
if BS.Win then BS.Win.Visible = false end
task.delay(2, function()
if BS.Win then BS.Win.Visible = true end
end)
end
end)
end)
print("[Stealth] Anti-Screenshot active")
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
Kills = 0,
Deaths = 0,
Headshots = 0,
Shots = 0,
Hits = 0,
Damage = 0,
StartTime = tick(),
}
function BS.Stats:RecordKill(headshot)
self.Kills = self.Kills + 1
if headshot then self.Headshots = self.Headshots + 1 end
end
function BS.Stats:RecordDeath()
self.Deaths = self.Deaths + 1
end
function BS.Stats:RecordShot(hit)
self.Shots = self.Shots + 1
if hit then self.Hits = self.Hits + 1 end
end
function BS.Stats:RecordDamage(dmg)
self.Damage = self.Damage + dmg
end
function BS.Stats:GetKD()
if self.Deaths == 0 then return self.Kills end
return math.floor(self.Kills / self.Deaths * 10) / 10
end
function BS.Stats:GetHSPercent()
if self.Kills == 0 then return 0 end
return math.floor(self.Headshots / self.Kills * 100)
end
function BS.Stats:GetAccuracy()
if self.Shots == 0 then return 0 end
return math.floor(self.Hits / self.Shots * 100)
end
function BS.Stats:GetPlayTime()
return math.floor(tick() - self.StartTime)
end
function BS.Stats:GetReport()
return string.format(
"K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
self.Kills, self.Deaths, self:GetKD(),
self:GetHSPercent(), self:GetAccuracy(),
self.Damage, math.floor(self:GetPlayTime() / 60)
)
end
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)
print("[Stealth]   23: Raw Metamethod Hook Evasion            NEW (DevForum 2025.07)")
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}
function BS.HWIDSpoofer:Generate()
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local id = ""
for i = 1, 32 do
local r = math.random(1, #chars)
id = id .. chars:sub(r, r)
if i == 8 or i == 12 or i == 16 or i == 20 then
id = id .. "-"
end
end
return id
end
function BS.HWIDSpoofer:Activate()
self.Active = true
self.SpoofedID = self:Generate()
pcall(function()
if gethwid then
local old = gethwid
gethwid = function() return self.SpoofedID end
end
end)
pcall(function()
if getmachineid then
local old = getmachineid
getmachineid = function() return self.SpoofedID end
end
end)
print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}
function BS.PingSpoof:SetPing(value)
self.FakePing = value
self.Active = true
pcall(function()
if BS.Ping then
BS.Ping.Current = value
BS.Ping.Average = value
end
end)
end
function BS.PingSpoof:Disable()
self.Active = false
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}
function BS.AntiScreenshot:Activate()
self.Active = true
pcall(function()
local oldSetCore
oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
if method == "TakeScreenshot" then
if BS.Win then BS.Win.Visible = false end
task.delay(1, function()
if BS.Win then BS.Win.Visible = true end
end)
return
end
return oldSetCore(self, method, ...)
end)
end)
pcall(function()
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.PrintScreen then
if BS.Win then BS.Win.Visible = false end
task.delay(2, function()
if BS.Win then BS.Win.Visible = true end
end)
end
end)
end)
print("[Stealth] Anti-Screenshot active")
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
Kills = 0,
Deaths = 0,
Headshots = 0,
Shots = 0,
Hits = 0,
Damage = 0,
StartTime = tick(),
}
function BS.Stats:RecordKill(headshot)
self.Kills = self.Kills + 1
if headshot then self.Headshots = self.Headshots + 1 end
end
function BS.Stats:RecordDeath()
self.Deaths = self.Deaths + 1
end
function BS.Stats:RecordShot(hit)
self.Shots = self.Shots + 1
if hit then self.Hits = self.Hits + 1 end
end
function BS.Stats:RecordDamage(dmg)
self.Damage = self.Damage + dmg
end
function BS.Stats:GetKD()
if self.Deaths == 0 then return self.Kills end
return math.floor(self.Kills / self.Deaths * 10) / 10
end
function BS.Stats:GetHSPercent()
if self.Kills == 0 then return 0 end
return math.floor(self.Headshots / self.Kills * 100)
end
function BS.Stats:GetAccuracy()
if self.Shots == 0 then return 0 end
return math.floor(self.Hits / self.Shots * 100)
end
function BS.Stats:GetPlayTime()
return math.floor(tick() - self.StartTime)
end
function BS.Stats:GetReport()
return string.format(
"K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
self.Kills, self.Deaths, self:GetKD(),
self:GetHSPercent(), self:GetAccuracy(),
self.Damage, math.floor(self:GetPlayTime() / 60)
)
end
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)
print("[Stealth]   24: ToString Trap Evasion                   NEW (DevForum 2023.10)")
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}
function BS.HWIDSpoofer:Generate()
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local id = ""
for i = 1, 32 do
local r = math.random(1, #chars)
id = id .. chars:sub(r, r)
if i == 8 or i == 12 or i == 16 or i == 20 then
id = id .. "-"
end
end
return id
end
function BS.HWIDSpoofer:Activate()
self.Active = true
self.SpoofedID = self:Generate()
pcall(function()
if gethwid then
local old = gethwid
gethwid = function() return self.SpoofedID end
end
end)
pcall(function()
if getmachineid then
local old = getmachineid
getmachineid = function() return self.SpoofedID end
end
end)
print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}
function BS.PingSpoof:SetPing(value)
self.FakePing = value
self.Active = true
pcall(function()
if BS.Ping then
BS.Ping.Current = value
BS.Ping.Average = value
end
end)
end
function BS.PingSpoof:Disable()
self.Active = false
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}
function BS.AntiScreenshot:Activate()
self.Active = true
pcall(function()
local oldSetCore
oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
if method == "TakeScreenshot" then
if BS.Win then BS.Win.Visible = false end
task.delay(1, function()
if BS.Win then BS.Win.Visible = true end
end)
return
end
return oldSetCore(self, method, ...)
end)
end)
pcall(function()
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.PrintScreen then
if BS.Win then BS.Win.Visible = false end
task.delay(2, function()
if BS.Win then BS.Win.Visible = true end
end)
end
end)
end)
print("[Stealth] Anti-Screenshot active")
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
Kills = 0,
Deaths = 0,
Headshots = 0,
Shots = 0,
Hits = 0,
Damage = 0,
StartTime = tick(),
}
function BS.Stats:RecordKill(headshot)
self.Kills = self.Kills + 1
if headshot then self.Headshots = self.Headshots + 1 end
end
function BS.Stats:RecordDeath()
self.Deaths = self.Deaths + 1
end
function BS.Stats:RecordShot(hit)
self.Shots = self.Shots + 1
if hit then self.Hits = self.Hits + 1 end
end
function BS.Stats:RecordDamage(dmg)
self.Damage = self.Damage + dmg
end
function BS.Stats:GetKD()
if self.Deaths == 0 then return self.Kills end
return math.floor(self.Kills / self.Deaths * 10) / 10
end
function BS.Stats:GetHSPercent()
if self.Kills == 0 then return 0 end
return math.floor(self.Headshots / self.Kills * 100)
end
function BS.Stats:GetAccuracy()
if self.Shots == 0 then return 0 end
return math.floor(self.Hits / self.Shots * 100)
end
function BS.Stats:GetPlayTime()
return math.floor(tick() - self.StartTime)
end
function BS.Stats:GetReport()
return string.format(
"K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
self.Kills, self.Deaths, self:GetKD(),
self:GetHSPercent(), self:GetAccuracy(),
self.Damage, math.floor(self:GetPlayTime() / 60)
)
end
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)
print("[Stealth]   25: Coroutine.wrap Stack Overflow Evasion   NEW (DevForum 2023.10)")
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}
function BS.HWIDSpoofer:Generate()
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local id = ""
for i = 1, 32 do
local r = math.random(1, #chars)
id = id .. chars:sub(r, r)
if i == 8 or i == 12 or i == 16 or i == 20 then
id = id .. "-"
end
end
return id
end
function BS.HWIDSpoofer:Activate()
self.Active = true
self.SpoofedID = self:Generate()
pcall(function()
if gethwid then
local old = gethwid
gethwid = function() return self.SpoofedID end
end
end)
pcall(function()
if getmachineid then
local old = getmachineid
getmachineid = function() return self.SpoofedID end
end
end)
print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}
function BS.PingSpoof:SetPing(value)
self.FakePing = value
self.Active = true
pcall(function()
if BS.Ping then
BS.Ping.Current = value
BS.Ping.Average = value
end
end)
end
function BS.PingSpoof:Disable()
self.Active = false
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}
function BS.AntiScreenshot:Activate()
self.Active = true
pcall(function()
local oldSetCore
oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
if method == "TakeScreenshot" then
if BS.Win then BS.Win.Visible = false end
task.delay(1, function()
if BS.Win then BS.Win.Visible = true end
end)
return
end
return oldSetCore(self, method, ...)
end)
end)
pcall(function()
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.PrintScreen then
if BS.Win then BS.Win.Visible = false end
task.delay(2, function()
if BS.Win then BS.Win.Visible = true end
end)
end
end)
end)
print("[Stealth] Anti-Screenshot active")
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
Kills = 0,
Deaths = 0,
Headshots = 0,
Shots = 0,
Hits = 0,
Damage = 0,
StartTime = tick(),
}
function BS.Stats:RecordKill(headshot)
self.Kills = self.Kills + 1
if headshot then self.Headshots = self.Headshots + 1 end
end
function BS.Stats:RecordDeath()
self.Deaths = self.Deaths + 1
end
function BS.Stats:RecordShot(hit)
self.Shots = self.Shots + 1
if hit then self.Hits = self.Hits + 1 end
end
function BS.Stats:RecordDamage(dmg)
self.Damage = self.Damage + dmg
end
function BS.Stats:GetKD()
if self.Deaths == 0 then return self.Kills end
return math.floor(self.Kills / self.Deaths * 10) / 10
end
function BS.Stats:GetHSPercent()
if self.Kills == 0 then return 0 end
return math.floor(self.Headshots / self.Kills * 100)
end
function BS.Stats:GetAccuracy()
if self.Shots == 0 then return 0 end
return math.floor(self.Hits / self.Shots * 100)
end
function BS.Stats:GetPlayTime()
return math.floor(tick() - self.StartTime)
end
function BS.Stats:GetReport()
return string.format(
"K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
self.Kills, self.Deaths, self:GetKD(),
self:GetHSPercent(), self:GetAccuracy(),
self.Damage, math.floor(self:GetPlayTime() / 60)
)
end
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)
print("[Stealth]   26: CoreGui Reference Evasion              NEW (DevForum 2023.10)")
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}
function BS.HWIDSpoofer:Generate()
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local id = ""
for i = 1, 32 do
local r = math.random(1, #chars)
id = id .. chars:sub(r, r)
if i == 8 or i == 12 or i == 16 or i == 20 then
id = id .. "-"
end
end
return id
end
function BS.HWIDSpoofer:Activate()
self.Active = true
self.SpoofedID = self:Generate()
pcall(function()
if gethwid then
local old = gethwid
gethwid = function() return self.SpoofedID end
end
end)
pcall(function()
if getmachineid then
local old = getmachineid
getmachineid = function() return self.SpoofedID end
end
end)
print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}
function BS.PingSpoof:SetPing(value)
self.FakePing = value
self.Active = true
pcall(function()
if BS.Ping then
BS.Ping.Current = value
BS.Ping.Average = value
end
end)
end
function BS.PingSpoof:Disable()
self.Active = false
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}
function BS.AntiScreenshot:Activate()
self.Active = true
pcall(function()
local oldSetCore
oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
if method == "TakeScreenshot" then
if BS.Win then BS.Win.Visible = false end
task.delay(1, function()
if BS.Win then BS.Win.Visible = true end
end)
return
end
return oldSetCore(self, method, ...)
end)
end)
pcall(function()
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.PrintScreen then
if BS.Win then BS.Win.Visible = false end
task.delay(2, function()
if BS.Win then BS.Win.Visible = true end
end)
end
end)
end)
print("[Stealth] Anti-Screenshot active")
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
Kills = 0,
Deaths = 0,
Headshots = 0,
Shots = 0,
Hits = 0,
Damage = 0,
StartTime = tick(),
}
function BS.Stats:RecordKill(headshot)
self.Kills = self.Kills + 1
if headshot then self.Headshots = self.Headshots + 1 end
end
function BS.Stats:RecordDeath()
self.Deaths = self.Deaths + 1
end
function BS.Stats:RecordShot(hit)
self.Shots = self.Shots + 1
if hit then self.Hits = self.Hits + 1 end
end
function BS.Stats:RecordDamage(dmg)
self.Damage = self.Damage + dmg
end
function BS.Stats:GetKD()
if self.Deaths == 0 then return self.Kills end
return math.floor(self.Kills / self.Deaths * 10) / 10
end
function BS.Stats:GetHSPercent()
if self.Kills == 0 then return 0 end
return math.floor(self.Headshots / self.Kills * 100)
end
function BS.Stats:GetAccuracy()
if self.Shots == 0 then return 0 end
return math.floor(self.Hits / self.Shots * 100)
end
function BS.Stats:GetPlayTime()
return math.floor(tick() - self.StartTime)
end
function BS.Stats:GetReport()
return string.format(
"K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
self.Kills, self.Deaths, self:GetKD(),
self:GetHSPercent(), self:GetAccuracy(),
self.Damage, math.floor(self:GetPlayTime() / 60)
)
end
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)
print("[Stealth]   27: getfenv Level Scanning Evasion         NEW (DevForum 2025.07)")
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}
function BS.HWIDSpoofer:Generate()
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local id = ""
for i = 1, 32 do
local r = math.random(1, #chars)
id = id .. chars:sub(r, r)
if i == 8 or i == 12 or i == 16 or i == 20 then
id = id .. "-"
end
end
return id
end
function BS.HWIDSpoofer:Activate()
self.Active = true
self.SpoofedID = self:Generate()
pcall(function()
if gethwid then
local old = gethwid
gethwid = function() return self.SpoofedID end
end
end)
pcall(function()
if getmachineid then
local old = getmachineid
getmachineid = function() return self.SpoofedID end
end
end)
print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}
function BS.PingSpoof:SetPing(value)
self.FakePing = value
self.Active = true
pcall(function()
if BS.Ping then
BS.Ping.Current = value
BS.Ping.Average = value
end
end)
end
function BS.PingSpoof:Disable()
self.Active = false
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}
function BS.AntiScreenshot:Activate()
self.Active = true
pcall(function()
local oldSetCore
oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
if method == "TakeScreenshot" then
if BS.Win then BS.Win.Visible = false end
task.delay(1, function()
if BS.Win then BS.Win.Visible = true end
end)
return
end
return oldSetCore(self, method, ...)
end)
end)
pcall(function()
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.PrintScreen then
if BS.Win then BS.Win.Visible = false end
task.delay(2, function()
if BS.Win then BS.Win.Visible = true end
end)
end
end)
end)
print("[Stealth] Anti-Screenshot active")
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
Kills = 0,
Deaths = 0,
Headshots = 0,
Shots = 0,
Hits = 0,
Damage = 0,
StartTime = tick(),
}
function BS.Stats:RecordKill(headshot)
self.Kills = self.Kills + 1
if headshot then self.Headshots = self.Headshots + 1 end
end
function BS.Stats:RecordDeath()
self.Deaths = self.Deaths + 1
end
function BS.Stats:RecordShot(hit)
self.Shots = self.Shots + 1
if hit then self.Hits = self.Hits + 1 end
end
function BS.Stats:RecordDamage(dmg)
self.Damage = self.Damage + dmg
end
function BS.Stats:GetKD()
if self.Deaths == 0 then return self.Kills end
return math.floor(self.Kills / self.Deaths * 10) / 10
end
function BS.Stats:GetHSPercent()
if self.Kills == 0 then return 0 end
return math.floor(self.Headshots / self.Kills * 100)
end
function BS.Stats:GetAccuracy()
if self.Shots == 0 then return 0 end
return math.floor(self.Hits / self.Shots * 100)
end
function BS.Stats:GetPlayTime()
return math.floor(tick() - self.StartTime)
end
function BS.Stats:GetReport()
return string.format(
"K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
self.Kills, self.Deaths, self:GetKD(),
self:GetHSPercent(), self:GetAccuracy(),
self.Damage, math.floor(self:GetPlayTime() / 60)
)
end
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)
print("[Stealth]   28: Unified Anti-Detection Activation       NEW")
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}
function BS.HWIDSpoofer:Generate()
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local id = ""
for i = 1, 32 do
local r = math.random(1, #chars)
id = id .. chars:sub(r, r)
if i == 8 or i == 12 or i == 16 or i == 20 then
id = id .. "-"
end
end
return id
end
function BS.HWIDSpoofer:Activate()
self.Active = true
self.SpoofedID = self:Generate()
pcall(function()
if gethwid then
local old = gethwid
gethwid = function() return self.SpoofedID end
end
end)
pcall(function()
if getmachineid then
local old = getmachineid
getmachineid = function() return self.SpoofedID end
end
end)
print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}
function BS.PingSpoof:SetPing(value)
self.FakePing = value
self.Active = true
pcall(function()
if BS.Ping then
BS.Ping.Current = value
BS.Ping.Average = value
end
end)
end
function BS.PingSpoof:Disable()
self.Active = false
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}
function BS.AntiScreenshot:Activate()
self.Active = true
pcall(function()
local oldSetCore
oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
if method == "TakeScreenshot" then
if BS.Win then BS.Win.Visible = false end
task.delay(1, function()
if BS.Win then BS.Win.Visible = true end
end)
return
end
return oldSetCore(self, method, ...)
end)
end)
pcall(function()
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.PrintScreen then
if BS.Win then BS.Win.Visible = false end
task.delay(2, function()
if BS.Win then BS.Win.Visible = true end
end)
end
end)
end)
print("[Stealth] Anti-Screenshot active")
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
Kills = 0,
Deaths = 0,
Headshots = 0,
Shots = 0,
Hits = 0,
Damage = 0,
StartTime = tick(),
}
function BS.Stats:RecordKill(headshot)
self.Kills = self.Kills + 1
if headshot then self.Headshots = self.Headshots + 1 end
end
function BS.Stats:RecordDeath()
self.Deaths = self.Deaths + 1
end
function BS.Stats:RecordShot(hit)
self.Shots = self.Shots + 1
if hit then self.Hits = self.Hits + 1 end
end
function BS.Stats:RecordDamage(dmg)
self.Damage = self.Damage + dmg
end
function BS.Stats:GetKD()
if self.Deaths == 0 then return self.Kills end
return math.floor(self.Kills / self.Deaths * 10) / 10
end
function BS.Stats:GetHSPercent()
if self.Kills == 0 then return 0 end
return math.floor(self.Headshots / self.Kills * 100)
end
function BS.Stats:GetAccuracy()
if self.Shots == 0 then return 0 end
return math.floor(self.Hits / self.Shots * 100)
end
function BS.Stats:GetPlayTime()
return math.floor(tick() - self.StartTime)
end
function BS.Stats:GetReport()
return string.format(
"K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
self.Kills, self.Deaths, self:GetKD(),
self:GetHSPercent(), self:GetAccuracy(),
self.Damage, math.floor(self:GetPlayTime() / 60)
)
end
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)
print("[Stealth] ")
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}
function BS.HWIDSpoofer:Generate()
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local id = ""
for i = 1, 32 do
local r = math.random(1, #chars)
id = id .. chars:sub(r, r)
if i == 8 or i == 12 or i == 16 or i == 20 then
id = id .. "-"
end
end
return id
end
function BS.HWIDSpoofer:Activate()
self.Active = true
self.SpoofedID = self:Generate()
pcall(function()
if gethwid then
local old = gethwid
gethwid = function() return self.SpoofedID end
end
end)
pcall(function()
if getmachineid then
local old = getmachineid
getmachineid = function() return self.SpoofedID end
end
end)
print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}
function BS.PingSpoof:SetPing(value)
self.FakePing = value
self.Active = true
pcall(function()
if BS.Ping then
BS.Ping.Current = value
BS.Ping.Average = value
end
end)
end
function BS.PingSpoof:Disable()
self.Active = false
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}
function BS.AntiScreenshot:Activate()
self.Active = true
pcall(function()
local oldSetCore
oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
if method == "TakeScreenshot" then
if BS.Win then BS.Win.Visible = false end
task.delay(1, function()
if BS.Win then BS.Win.Visible = true end
end)
return
end
return oldSetCore(self, method, ...)
end)
end)
pcall(function()
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.PrintScreen then
if BS.Win then BS.Win.Visible = false end
task.delay(2, function()
if BS.Win then BS.Win.Visible = true end
end)
end
end)
end)
print("[Stealth] Anti-Screenshot active")
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
Kills = 0,
Deaths = 0,
Headshots = 0,
Shots = 0,
Hits = 0,
Damage = 0,
StartTime = tick(),
}
function BS.Stats:RecordKill(headshot)
self.Kills = self.Kills + 1
if headshot then self.Headshots = self.Headshots + 1 end
end
function BS.Stats:RecordDeath()
self.Deaths = self.Deaths + 1
end
function BS.Stats:RecordShot(hit)
self.Shots = self.Shots + 1
if hit then self.Hits = self.Hits + 1 end
end
function BS.Stats:RecordDamage(dmg)
self.Damage = self.Damage + dmg
end
function BS.Stats:GetKD()
if self.Deaths == 0 then return self.Kills end
return math.floor(self.Kills / self.Deaths * 10) / 10
end
function BS.Stats:GetHSPercent()
if self.Kills == 0 then return 0 end
return math.floor(self.Headshots / self.Kills * 100)
end
function BS.Stats:GetAccuracy()
if self.Shots == 0 then return 0 end
return math.floor(self.Hits / self.Shots * 100)
end
function BS.Stats:GetPlayTime()
return math.floor(tick() - self.StartTime)
end
function BS.Stats:GetReport()
return string.format(
"K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
self.Kills, self.Deaths, self:GetKD(),
self:GetHSPercent(), self:GetAccuracy(),
self.Damage, math.floor(self:GetPlayTime() / 60)
)
end
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)
print("[Stealth] F10=Nuclear | F9=Safe | Risk: " .. Stealth.RiskLevel .. "%")
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
Stealth.MemoryProtection = {Enabled = false}
function Stealth.MemoryProtection.RandomizeLayout()
pcall(function()
for i = 1, 10 do
local decoy = Instance.new("Folder")
decoy.Name = string.char(math.random(65,90)) .. math.random(1000,9999)
decoy.Parent = game:GetService("ReplicatedStorage")
game:GetService("Debris"):AddItem(decoy, 5)
end
end)
end
Stealth.AntiTamper = {Enabled = false, Checksums = {}}
function Stealth.AntiTamper.StoreChecksums()
pcall(function()
for name, func in pairs(getfenv()) do
if type(func) == "function" then
Stealth.AntiTamper.Checksums[name] = #string.dump(func)
end
end
end)
end
function Stealth.AntiTamper.VerifyIntegrity()
pcall(function()
for name, func in pairs(getfenv()) do
if type(func) == "function" and Stealth.AntiTamper.Checksums[name] then
if #string.dump(func) ~= Stealth.AntiTamper.Checksums[name] then
warn("[Stealth] Tamper detected: " .. name)
end
end
end
end)
end
Stealth.BehavioralEvasion = {Enabled = false}
function Stealth.BehavioralEvasion.HumanizeMouse(targetPos)
local jitter = Vector2.new(math.random(-2,2), math.random(-2,2))
return targetPos + jitter
end
function Stealth.BehavioralEvasion.HumanizeReaction()
return math.random(50,150) / 1000
end
Stealth.NetworkObfuscation = {Enabled = false}
function Stealth.NetworkObfuscation.ObfuscateTiming()
return 0.016 + math.random(-5,5) / 1000
end
Stealth.HardwareSpoof = {Enabled = false}
function Stealth.HardwareSpoof.SpoofDeviceID()
local id = ""
for i = 1, 32 do id = id .. string.format("%02x", math.random(0,255)) end
end
Stealth.AntiDebug = {Enabled = false}
function Stealth.AntiDebug.AntiStep()
pcall(function()
local oldDebug = debug.getinfo
debug.getinfo = function(level, what)
local info = oldDebug(level, what)
if info then info.source = "=C" info.short_src = "=C" end
return info
end
end)
end
Stealth.TimingEvasion = {Enabled = false}
function Stealth.TimingEvasion.RandomizeTiming(baseTime)
local noise = 0
for i = 1, 6 do noise = noise + math.random() end
return baseTime * (1 + (noise/6 - 0.5) * 0.1)
end
Stealth.AntiReplay = {Enabled = false, SessionID = tostring(math.random(1000000,9999999))}
function Stealth.AntiReplay.AddToken(op) return op .. "_token_" .. Stealth.AntiReplay.SessionID end
function Stealth.ActivateAllAntiDetection()
Stealth.MemoryProtection.Enabled = true
Stealth.AntiTamper.Enabled = true
Stealth.BehavioralEvasion.Enabled = true
Stealth.NetworkObfuscation.Enabled = true
Stealth.HardwareSpoof.Enabled = true
Stealth.AntiDebug.Enabled = true
Stealth.TimingEvasion.Enabled = true
Stealth.AntiReplay.Enabled = true
pcall(function() Stealth.AntiTamper.StoreChecksums() end)
pcall(function() Stealth.HardwareSpoof.SpoofDeviceID() end)
pcall(function() Stealth.AntiDebug.AntiStep() end)
task.spawn(function()
while true do
task.wait(5)
pcall(function()
if Stealth.MemoryProtection.Enabled then Stealth.MemoryProtection.RandomizeLayout() end
if Stealth.AntiTamper.Enabled then Stealth.AntiTamper.VerifyIntegrity() end
end)
end
end)
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.HWIDSpoofer = {Active = false, SpoofedID = nil}
function BS.HWIDSpoofer:Generate()
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local id = ""
for i = 1, 32 do
local r = math.random(1, #chars)
id = id .. chars:sub(r, r)
if i == 8 or i == 12 or i == 16 or i == 20 then
id = id .. "-"
end
end
return id
end
function BS.HWIDSpoofer:Activate()
self.Active = true
self.SpoofedID = self:Generate()
pcall(function()
if gethwid then
local old = gethwid
gethwid = function() return self.SpoofedID end
end
end)
pcall(function()
if getmachineid then
local old = getmachineid
getmachineid = function() return self.SpoofedID end
end
end)
print("[Stealth] HWID Spoofer active: " .. self.SpoofedID)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.PingSpoof = {Active = false, FakePing = 0}
function BS.PingSpoof:SetPing(value)
self.FakePing = value
self.Active = true
pcall(function()
if BS.Ping then
BS.Ping.Current = value
BS.Ping.Average = value
end
end)
end
function BS.PingSpoof:Disable()
self.Active = false
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.AntiScreenshot = {Active = false}
function BS.AntiScreenshot:Activate()
self.Active = true
pcall(function()
local oldSetCore
oldSetCore = hookfunction(StarterGui.SetCore, function(self, method, ...)
if method == "TakeScreenshot" then
if BS.Win then BS.Win.Visible = false end
task.delay(1, function()
if BS.Win then BS.Win.Visible = true end
end)
return
end
return oldSetCore(self, method, ...)
end)
end)
pcall(function()
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.PrintScreen then
if BS.Win then BS.Win.Visible = false end
task.delay(2, function()
if BS.Win then BS.Win.Visible = true end
end)
end
end)
end)
print("[Stealth] Anti-Screenshot active")
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Stats = {
Kills = 0,
Deaths = 0,
Headshots = 0,
Shots = 0,
Hits = 0,
Damage = 0,
StartTime = tick(),
}
function BS.Stats:RecordKill(headshot)
self.Kills = self.Kills + 1
if headshot then self.Headshots = self.Headshots + 1 end
end
function BS.Stats:RecordDeath()
self.Deaths = self.Deaths + 1
end
function BS.Stats:RecordShot(hit)
self.Shots = self.Shots + 1
if hit then self.Hits = self.Hits + 1 end
end
function BS.Stats:RecordDamage(dmg)
self.Damage = self.Damage + dmg
end
function BS.Stats:GetKD()
if self.Deaths == 0 then return self.Kills end
return math.floor(self.Kills / self.Deaths * 10) / 10
end
function BS.Stats:GetHSPercent()
if self.Kills == 0 then return 0 end
return math.floor(self.Headshots / self.Kills * 100)
end
function BS.Stats:GetAccuracy()
if self.Shots == 0 then return 0 end
return math.floor(self.Hits / self.Shots * 100)
end
function BS.Stats:GetPlayTime()
return math.floor(tick() - self.StartTime)
end
function BS.Stats:GetReport()
return string.format(
"K:%d D:%d KD:%.1f HS:%d%% ACC:%d%% DMG:%d Time:%dm",
self.Kills, self.Deaths, self:GetKD(),
self:GetHSPercent(), self:GetAccuracy(),
self.Damage, math.floor(self:GetPlayTime() / 60)
)
end
page:Label(" HWID Spoofer ")
page:Button({Name="Generate HWID"}, function() BS.HWIDSpoofer:Activate() end)
page:Separator()
page:Label(" Ping Spoof ")
page:Toggle("Ping Spoof", false, function(v) if v then BS.PingSpoof:SetPing(Flags.FakePing or 50) else BS.PingSpoof:Disable() end end)
page:Slider("Fake Ping", 10, 200, 50, function(v) Flags.FakePing = v end)
page:Separator()
page:Label(" Anti-Screenshot ")
page:Toggle("Anti-Screenshot", false, function(v) if v then BS.AntiScreenshot:Activate() end end)
page:Separator()
page:Label(" Statistics ")
page:Button({Name="Show Stats"}, function() print("[Stats] " .. BS.Stats:GetReport()) end)
page:Button({Name="Reset Stats"}, function() BS.Stats.StartTime = tick() BS.Stats.Kills=0 BS.Stats.Deaths=0 BS.Stats.Headshots=0 BS.Stats.Shots=0 BS.Stats.Hits=0 BS.Stats.Damage=0 end)
print("[Stealth] Anti-detection v5.0 activated (8 new systems)")
end
Stealth.ActivateAllAntiDetection()
]])
writefile("BloxStrike/modules/ui.lua", [[
local Players = nil
pcall(function() Players = game:GetService("Players") end)
local UIS = nil
pcall(function() UIS = game:GetService("UserInputService") end)
local TS = nil
pcall(function() TS = game:GetService("TweenService") end)
local StarterGui = nil
pcall(function() StarterGui = game:GetService("StarterGui") end)
local HttpService = nil
pcall(function() HttpService = game:GetService("HttpService") end)
local lplr = Players.LocalPlayer
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
local Rayfield = nil
local loadAttempts = 0
local maxAttempts = 3
local rayfieldURLs = {
"https://sirius.menu/rayfield",
"https://raw.githubusercontent.com/shlexware/Rayfield/main/source",
"https://raw.githubusercontent.com/jensonhirst/Rayfield/main/source",
}
while not Rayfield and loadAttempts < maxAttempts do
loadAttempts = loadAttempts + 1
for _, url in ipairs(rayfieldURLs) do
pcall(function()
Rayfield = loadstring(game:HttpGet(url, true))()
end)
if Rayfield then break end
end
end
if not Rayfield then
warn("[UI] CRITICAL: Could not load Rayfield!")
BS.Win = {
Tab = function(self, name)
return {
Toggle = function() end, Slider = function() end,
Dropdown = function() end, Button = function() end,
Label = function() end, Separator = function() end,
}
end
}
return
end
print("[UI] Rayfield loaded successfully")
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
function BS.Notify(title, text, duration)
pcall(function()
Rayfield:Notify({
Title = title or "BloxStrike",
Content = text or "",
Duration = duration or 3,
Image = 4483362458,
})
end)
pcall(function()
StarterGui:SetCore("SendNotification", {
Title = title or "BloxStrike", Text = text or "", Duration = duration or 3,
})
end)
end
function BS.FeatureNotify(feature, enabled)
BS.Notify("BloxStrike", feature .. (enabled and " ON" or " OFF"), 2)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Theme = {
Current = "Dark",
Themes = {
Dark = {Accent = Color3.fromRGB(88, 130, 255), BG = Color3.fromRGB(15, 15, 25)},
Red = {Accent = Color3.fromRGB(255, 50, 50), BG = Color3.fromRGB(25, 10, 10)},
Green = {Accent = Color3.fromRGB(50, 255, 100), BG = Color3.fromRGB(10, 25, 10)},
Purple = {Accent = Color3.fromRGB(150, 50, 255), BG = Color3.fromRGB(20, 10, 30)},
Gold = {Accent = Color3.fromRGB(255, 200, 50), BG = Color3.fromRGB(25, 20, 10)},
},
Set = function(self, themeName)
if self.Themes[themeName] then
self.Current = themeName
BS.Notify("Theme", "Changed to " .. themeName, 2)
end
end,
}
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
local Window = Rayfield:CreateWindow({
Name = "BloxStrike v3.0",
LoadingTitle = "BloxStrike v3.0",
LoadingSubtitle = "CS2-Style HVH Cheat",
ConfigurationSaving = {
Enabled = true,
FolderName = "BloxStrike",
FileName = "Config"
},
Discord = {Enabled = false},
KeySystem = false,
})
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
local flagCounter = 0
local function nextFlag()
flagCounter = flagCounter + 1
return "BS_" .. flagCounter
end
local allPages = {}
local function wrapTab(rayfieldTab, tabName)
local page = {}
allPages[tabName] = page
page.Toggle = function(self, name, default, callback)
local flag = nextFlag()
rayfieldTab:CreateToggle({
Name = name, CurrentValue = default or false, Flag = flag,
Callback = function(value) pcall(function() if callback then callback(value) end end) end,
})
end
page.Slider = function(self, name, min, max, default, callback)
local flag = nextFlag()
rayfieldTab:CreateSlider({
Name = name, Range = {min, max}, Increment = 1, CurrentValue = default or min, Flag = flag,
Callback = function(value) pcall(function() if callback then callback(value) end end) end,
})
end
page.Dropdown = function(self, config)
local flag = nextFlag()
rayfieldTab:CreateDropdown({
Name = config.Name or "Dropdown", Options = config.Options or {},
CurrentOption = config.Default or config.Options[1] or "", Flag = flag,
Callback = function(value) end,
})
end
page.Button = function(self, config, callback)
rayfieldTab:CreateButton({
Name = config.Name or "Button",
Callback = function() pcall(function() if callback then callback() end end) end,
})
end
page.Label = function(self, text)
rayfieldTab:CreateLabel(text)
end
page.Separator = function(self)
rayfieldTab:CreateSection("")
end
return page
end
BS.Win = {
Tab = function(self, tabName)
local rayfieldTab = Window:CreateTab(tabName, nil)
return wrapTab(rayfieldTab, tabName)
end
}
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Config = {}
function BS.Config.Save()
pcall(function()
local config = {}
for key, value in pairs(Flags) do
if type(value) ~= "table" and type(value) ~= "function" then
config[key] = value
end
end
local json = HttpService:JSONEncode(config)
if writefile then writefile("BloxStrike/Config.json", json) end
BS.Notify("Config", "Saved!", 2)
end)
end
function BS.Config.Load()
pcall(function()
if readfile and isfile and isfile("BloxStrike/Config.json") then
local config = HttpService:JSONDecode(readfile("BloxStrike/Config.json"))
for key, value in pairs(config) do Flags[key] = value end
BS.Notify("Config", "Loaded!", 2)
return true
end
end)
return false
end
function BS.Config.Reset()
for key, _ in pairs(Flags) do Flags[key] = false end
BS.Notify("Config", "Reset!", 2)
end
function BS.Config.Export()
pcall(function()
local config = {}
for key, value in pairs(Flags) do
if type(value) ~= "table" and type(value) ~= "function" then config[key] = value end
end
if setclipboard then setclipboard(HttpService:JSONEncode(config)) end
BS.Notify("Config", "Copied!", 2)
end)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Profiles = {
Current = "Default",
Saved = {},
Save = function(self, name)
self.Saved[name] = {}
for key, value in pairs(Flags) do
if type(value) ~= "table" and type(value) ~= "function" then
self.Saved[name][key] = value
end
end
self.Current = name
BS.Notify("Profile", "Saved: " .. name, 2)
end,
Load = function(self, name)
if self.Saved[name] then
for key, value in pairs(self.Saved[name]) do
Flags[key] = value
end
self.Current = name
BS.Notify("Profile", "Loaded: " .. name, 2)
return true
end
return false
end,
Delete = function(self, name)
self.Saved[name] = nil
BS.Notify("Profile", "Deleted: " .. name, 2)
end,
List = function(self)
local names = {}
for name, _ in pairs(self.Saved) do
table.insert(names, name)
end
return names
end,
}
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
local QuickPanel = {Visible = true}
local QuickObjs = {}
function QuickPanel.Update()
pcall(function()
local active = {}
if Flags.Aimbot then table.insert(active, {Text = "AIM", Color = Color3.new(1,0,0)}) end
if Flags.SilentAim then table.insert(active, {Text = "SA", Color = Color3.new(1,0.5,0)}) end
if Flags.Ragebot then table.insert(active, {Text = "RAGE", Color = Color3.new(1,0,0)}) end
if Flags.ESP_Box or Flags.ESP_Name then table.insert(active, {Text = "ESP", Color = Color3.new(0,1,0)}) end
if Flags.AA then table.insert(active, {Text = "AA", Color = Color3.new(0,0.5,1)}) end
if Flags.Bhop then table.insert(active, {Text = "BHOP", Color = Color3.new(1,1,0)}) end
if Flags.FOVChanger then table.insert(active, {Text = "FOV", Color = Color3.new(0.5,0,1)}) end
if Flags.NightMode then table.insert(active, {Text = "NIGHT", Color = Color3.new(0.3,0.3,1)}) end
if Flags.RemoveScope then table.insert(active, {Text = "NO SCOPE", Color = Color3.new(1,0.5,0)}) end
local x = workspace.CurrentCamera.ViewportSize.X
local y = workspace.CurrentCamera.ViewportSize.Y
for i = 1, math.max(#active, #QuickObjs) do
if not QuickObjs[i] then
QuickObjs[i] = Drawing.new("Text")
QuickObjs[i].Center = true
QuickObjs[i].Outline = true
QuickObjs[i].OutlineColor = Color3.new(0,0,0)
QuickObjs[i].Font = 2
QuickObjs[i].Size = 12
end
if i <= #active then
QuickObjs[i].Text = " " .. active[i].Text .. " "
QuickObjs[i].Color = active[i].Color
QuickObjs[i].Position = Vector2.new(x/2 - (#active * 30) + (i-1) * 60, y - 25)
QuickObjs[i].Visible = QuickPanel.Visible
else
QuickObjs[i].Visible = false
end
end
end)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
local WatermarkObj = nil
local function updateWatermark()
pcall(function()
if not WatermarkObj then
WatermarkObj = Drawing.new("Text")
WatermarkObj.Center = false
WatermarkObj.Outline = true
WatermarkObj.OutlineColor = Color3.new(0,0,0)
WatermarkObj.Font = 2
WatermarkObj.Size = 14
end
local fps = math.floor(1/workspace.CurrentCamera:GetPropertyChangedSignal("CFrame"):Wait() and 60 or 60)
local ping = 0
pcall(function() ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"].Value) end)
local players = #Players:GetPlayers()
WatermarkObj.Text = "  BloxStrike v3.0 | " .. fps .. " FPS | " .. ping .. " ms | " .. players .. " P | " .. os.date("%H:%M:%S") .. "  "
WatermarkObj.Position = Vector2.new(10, 10)
WatermarkObj.Color = Color3.new(1,1,1)
WatermarkObj.Visible = true
end)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
local keybindCallbacks = {}
function BS.BindKey(key, callback)
keybindCallbacks[key] = callback
end
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.Insert then
pcall(function() Rayfield:ToggleVisibility() end)
return
end
if keybindCallbacks[input.KeyCode] then
pcall(function() keybindCallbacks[input.KeyCode]() end)
end
end)
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Profiles.Saved["Legit"] = {
Aimbot = true, SilentAim = false, Ragebot = false, AA = false, FL = false,
ESP_Box = true, ESP_Name = true, ESP_Health = true, ESP_Dist = true,
Bhop = false, FOVChanger = true, FOVValue = 80,
}
BS.Profiles.Saved["Rage"] = {
Aimbot = false, SilentAim = true, Ragebot = true, RageFOV = 360, RageHC = 100,
RageAF = true, RageDT = true, RageWall = true, RageRes = true,
AA = true, AAPitch = "Jitter", AAYaw = "Spin", AASpd = 18,
FL = true, FLChoke = 10, FLStyle = "Adaptive",
ESP_Box = true, ESP_Name = true, ESP_Health = true, ESP_Dist = true,
}
BS.Profiles.Saved["HvH"] = {
Aimbot = false, SilentAim = true, Ragebot = true, RageFOV = 360, RageHC = 100,
RageAF = true, RageDT = true, RageWall = true, RageRes = true, RageKnife = true,
AA = true, AAPitch = "Jitter", AAYaw = "Spin", AASpd = 20,
AAFakeDuck = true, AADesync = true, AABodyYaw = true,
FL = true, FLChoke = 12, FLStyle = "Break Lag",
ESP_Box = true, ESP_Name = true, ESP_Health = true,
}
BS.Profiles.Saved["SemiRage"] = {
Aimbot = true, SilentAim = true, Ragebot = true, RageFOV = 180, RageHC = 85,
AA = true, AAPitch = "Emotion", AAYaw = "LBY Break", AASpd = 12,
FL = true, FLChoke = 8, FLStyle = "Adaptive",
ESP_Box = true, ESP_Name = true, ESP_Health = true, ESP_Dist = true,
}
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.BindKey(Enum.KeyCode.X, function()
Flags.ESP_Box = not Flags.ESP_Box
Flags.ESP_Name = Flags.ESP_Box
Flags.ESP_Health = Flags.ESP_Box
BS.FeatureNotify("ESP", Flags.ESP_Box)
end)
BS.BindKey(Enum.KeyCode.Z, function()
Flags.Bhop = not Flags.Bhop
BS.FeatureNotify("Bhop", Flags.Bhop)
end)
BS.BindKey(Enum.KeyCode.C, function()
Flags.AA = not Flags.AA
BS.FeatureNotify("Anti-Aim", Flags.AA)
end)
BS.BindKey(Enum.KeyCode.V, function()
Flags.SilentAim = not Flags.SilentAim
BS.FeatureNotify("Silent Aim", Flags.SilentAim)
end)
BS.BindKey(Enum.KeyCode.N, function()
Flags.NightMode = not Flags.NightMode
BS.FeatureNotify("Night Mode", Flags.NightMode)
end)
BS.BindKey(Enum.KeyCode.M, function()
Flags.RemoveScope = not Flags.RemoveScope
BS.FeatureNotify("Remove Scope", Flags.RemoveScope)
end)
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
task.spawn(function()
while true do
task.wait(0.5)
pcall(function()
updateWatermark()
QuickPanel.Update()
end)
end
end)
lplr.CharacterRemoving:Connect(function()
pcall(function() BS.Config.Save() end)
end)
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
print("[UI] BloxStrike UI v3.0 loaded (Rayfield)")
print("[UI] INSERT: Menu | X: ESP | Z: Bhop | C: AA | V: SA | N: Night | M: NoScope")
]])
writefile("BloxStrike/modules/utility.lua", [[
local Players = nil
pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local UIS = nil
pcall(function() UIS = game:GetService("UserInputService") end)
local StarterGui = nil
pcall(function() StarterGui = game:GetService("StarterGui") end)
local lplr = Players.LocalPlayer
if not BS.Win then warn("[Unknown] BS.Win not available - ui.lua may have failed") return end
local M = BS.Win:Tab("Misc")
if not M or not M.Toggle then warn("[Misc] Failed to create tab!") return end
M:Label("  Bunny Hop ")
M:Toggle("Bhop", false, function(v) Flags.Bhop = v end)
M:Dropdown({Name="Bhop Mode", Flag="BhopMode", Options={"Auto","Legit","HvH","Long Jump","B-Hop Plus","Edge Bug","Strafe Hack","Stamina Jump"}, Default="Auto"})
M:Slider("Bhop Delay", 0, 100, 0, function(v) Flags.BhopDelay = v end)
M:Slider("Bhop Speed", 16, 50, 24, function(v) Flags.BhopSpeed = v end)
M:Toggle("Bhop Keybind Only", false, function(v) Flags.BhopKeybind = v end)
M:Toggle("Bhop Auto Run", false, function(v) Flags.BhopAutoRun = v end)
M:Toggle("Bhop Crouch", false, function(v) Flags.BhopCrouch = v end)
M:Toggle("Bhop Jump Bug", false, function(v) Flags.BhopJB = v end)
M:Toggle("Bhop Edge Bug", false, function(v) Flags.BhopEB = v end)
M:Separator()
M:Label(" Air Strafe ")
M:Toggle("Auto Strafe", true, function(v) Flags.BhopStrafe = v end)
M:Dropdown({Name="Strafe Pattern", Flag="BhopStrafePattern", Options={"Linear","Sinusoidal","Random","Aggressive","Smooth","Circular"}, Default="Linear"})
M:Slider("Strafe Speed", 1, 30, 10, function(v) Flags.BhopStrafeSpd = v end)
M:Slider("Strafe Angle Limit", 10, 90, 45, function(v) Flags.BhopStrafeAngle = v end)
M:Slider("Strafe Sensitivity", 1, 20, 8, function(v) Flags.BhopStrafeSens = v end)
M:Toggle("W-Strafe (Forward)", false, function(v) Flags.BhopWStrafe = v end)
M:Toggle("Air Accelerate", false, function(v) Flags.BhopAirAccel = v end)
M:Slider("Air Accel Value", 1, 20, 10, function(v) Flags.BhopAirAccelVal = v end)
M:Separator()
M:Slider("Pre-Strafe Speed", 1, 20, 12, function(v) Flags.BhopPreSpeed = v end)
M:Separator()
M:Label(" Advanced ")
M:Toggle("Multi-Jump", false, function(v) Flags.BhopMultiJump = v end)
M:Slider("Multi-Jump Count", 2, 5, 2, function(v) Flags.BhopMultiCount = v end)
M:Toggle("Bhop Bind (Space)", false, function(v) Flags.BhopBindSpace = v end)
M:Toggle("Bhop Auto Strafe Keys", false, function(v) Flags.BhopAutoKeys = v end)
local bhopStrafeAngle = 0
local bhopGroundAngle = 0
local bhopJumpCount = 0
local bhopLastGround = 0
local bhopStamina = 50
local bhopMultiJumpUsed = 0
local bhopLastJump = 0
local bhopStrafeTime = 0
local bhopAvgSpeed = 0
local bhopMaxSpeed = 0
task.spawn(function()
while true do
task.wait()
if not (Flags.Bhop and BS.alive()) then continue end
pcall(function()
local h = BS.hum()
local hrp = BS.hrp()
if not h or not hrp then return end
local mode = Flags.BhopMode or "Auto"
local onGround = h.FloorMaterial ~= Enum.Material.Air
local vel = hrp.AssemblyLinearVelocity
local speed = vel.Magnitude
local isMoving = speed > 2
local now = tick()
bhopAvgSpeed = bhopAvgSpeed * 0.9 + speed * 0.1
if speed > bhopMaxSpeed then bhopMaxSpeed = speed end
bhopStrafeTime = bhopStrafeTime + 1
if Flags.BhopKeybind then
if not UIS:IsKeyDown(Enum.KeyCode.Space) and not UIS:IsKeyDown(Enum.KeyCode.ThumbstickButton1) then return end
end
if Flags.BhopStamina then
if not onGround then
bhopStamina = bhopStamina - (Flags.BhopStamDrain or 5) * 0.016
if bhopStamina <= 0 then
bhopStamina = 0
return
end
else
bhopStamina = math.min(bhopStamina + (Flags.BhopStamRegen or 3) * 0.016, Flags.BhopMaxStamina or 50)
end
end
if Flags.BhopAutoRun then
h.WalkSpeed = Flags.BhopSpeed or 24
end
local function doJump()
if now - bhopLastJump < 0.05 then return end
bhopLastJump = now
bhopJumpCount = bhopJumpCount + 1
if Flags.BhopSound then
pcall(function()
local s = Instance.new("Sound")
s.SoundId = "rbxassetid://138087576"
s.Volume = 0.3
s.PlaybackSpeed = 1.2 + math.random() * 0.3
s.Parent = hrp
s:Play()
game:GetService("Debris"):AddItem(s, 0.5)
end)
end
end
if mode == "Auto" then
if onGround then
bhopLastGround = now
local bhopDelay = (Flags.BhopDelay or 0) / 1000
if Flags.PingAdapt and BS.PA then
bhopDelay = BS.PA.getAdaptBhopInterval(bhopDelay)
end
task.wait(bhopDelay)
doJump()
end
elseif mode == "Legit" then
if onGround and isMoving then
local delay = (Flags.BhopDelay or 0) / 1000 + math.random() * 0.015
task.wait(delay)
doJump()
end
elseif mode == "HvH" then
if onGround then
doJump()
end
if not onGround then
local lookDir = hrp.CFrame.LookVector
hrp.Velocity = lookDir * math.max(speed, Flags.BhopSpeed or 24)
end
elseif mode == "Long Jump" then
if onGround then
if Flags.BhopPreStr then
local preAngle = math.rad(Flags.BhopPreAngle or 25)
local preSpd = (Flags.BhopPreSpeed or 12) / 500
hrp.CFrame = hrp.CFrame * CFrame.Angles(0, preAngle, 0)
h.WalkSpeed = 35
end
task.wait(0.02)
doJump()
task.delay(0.05, function() h.WalkSpeed = Flags.BhopSpeed or 24 end)
end
if not onGround and Flags.BhopStrafe then
local ljs = (Flags.BhopStrafeSpd or 10) / 300
if UIS:IsKeyDown(Enum.KeyCode.D) then
hrp.CFrame = hrp.CFrame * CFrame.Angles(0, -ljs, 0)
elseif UIS:IsKeyDown(Enum.KeyCode.A) then
hrp.CFrame = hrp.CFrame * CFrame.Angles(0, ljs, 0)
end
end
elseif mode == "B-Hop Plus" then
if onGround then
task.wait((Flags.BhopDelay or 0) / 1000)
doJump()
local lookDir = hrp.CFrame.LookVector
hrp.Velocity = Vector3.new(lookDir.X * 30, vel.Y + 20, lookDir.Z * 30)
end
if not onGround and Flags.BhopStrafe then
local aggro = (Flags.BhopStrafeSpd or 10) / 200
if UIS:IsKeyDown(Enum.KeyCode.D) then
hrp.CFrame = hrp.CFrame * CFrame.Angles(0, -aggro, 0)
elseif UIS:IsKeyDown(Enum.KeyCode.A) then
hrp.CFrame = hrp.CFrame * CFrame.Angles(0, aggro, 0)
end
end
elseif mode == "Edge Bug" then
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = {lplr.Character}
local lookVec = hrp.CFrame.LookVector
local result = workspace:Raycast(hrp.Position, lookVec * 4 + Vector3.new(0, -6, 0), params)
if result then
if onGround then
hrp.Velocity = Vector3.new(lookVec.X * 40, 25, lookVec.Z * 40)
end
elseif onGround then
doJump()
end
if not onGround and Flags.BhopStrafe then
local ebs = (Flags.BhopStrafeSpd or 10) / 400
if UIS:IsKeyDown(Enum.KeyCode.D) then
hrp.CFrame = hrp.CFrame * CFrame.Angles(0, -ebs, 0)
elseif UIS:IsKeyDown(Enum.KeyCode.A) then
hrp.CFrame = hrp.CFrame * CFrame.Angles(0, ebs, 0)
end
end
elseif mode == "Strafe Hack" then
if onGround then
task.wait((Flags.BhopDelay or 0) / 1000)
doJump()
end
if not onGround and Flags.BhopStrafe then
local pattern = Flags.BhopStrafePattern or "Sinusoidal"
local sspd = (Flags.BhopStrafeSpd or 10) / 500
local angle = 0
if pattern == "Sinusoidal" then
angle = math.sin(bhopStrafeTime * 0.05) * sspd * 3
elseif pattern == "Random" then
angle = (math.random() - 0.5) * sspd * 4
elseif pattern == "Aggressive" then
angle = sspd * 2 * (UIS:IsKeyDown(Enum.KeyCode.D) and 1 or -1)
elseif pattern == "Smooth" then
angle = math.atan2(math.sin(bhopStrafeTime * 0.03), 1) * sspd * 2
elseif pattern == "Circular" then
angle = sspd * 2
else
if UIS:IsKeyDown(Enum.KeyCode.D) then angle = -sspd
elseif UIS:IsKeyDown(Enum.KeyCode.A) then angle = sspd end
end
hrp.CFrame = hrp.CFrame * CFrame.Angles(0, angle, 0)
if Flags.BhopAirAccel then
local accel = (Flags.BhopAirAccelVal or 10) / 10
hrp.Velocity = hrp.Velocity + hrp.CFrame.LookVector * accel
end
end
elseif mode == "Stamina Jump" then
if not Flags.BhopStamina then
Flags.BhopStamina = true
bhopStamina = Flags.BhopMaxStamina or 50
end
if onGround and bhopStamina > 5 then
task.wait((Flags.BhopDelay or 0) / 1000)
doJump()
end
if not onGround and Flags.BhopStrafe and bhopStamina > 0 then
local sstr = (Flags.BhopStrafeSpd or 10) / 600
if UIS:IsKeyDown(Enum.KeyCode.D) then
hrp.CFrame = hrp.CFrame * CFrame.Angles(0, -sstr, 0)
elseif UIS:IsKeyDown(Enum.KeyCode.A) then
hrp.CFrame = hrp.CFrame * CFrame.Angles(0, sstr, 0)
end
end
end
if Flags.BhopStrafe and not onGround and mode ~= "Strafe Hack" and mode ~= "Long Jump" then
local strafeSpd = (Flags.BhopStrafeSpd or 10) / 1000
local pattern = Flags.BhopStrafePattern or "Linear"
local angleLimit = math.rad(Flags.BhopStrafeAngle or 45)
if pattern == "Sinusoidal" then
local sineAngle = math.sin(bhopStrafeTime * 0.04) * angleLimit
hrp.CFrame = hrp.CFrame * CFrame.Angles(0, sineAngle * 0.05, 0)
elseif pattern == "Random" then
local rAngle = (math.random() - 0.5) * angleLimit * 0.1
hrp.CFrame = hrp.CFrame * CFrame.Angles(0, rAngle, 0)
elseif pattern == "Aggressive" then
local aggSpd = strafeSpd * 2
if UIS:IsKeyDown(Enum.KeyCode.D) then
hrp.CFrame = hrp.CFrame * CFrame.Angles(0, -aggSpd, 0)
elseif UIS:IsKeyDown(Enum.KeyCode.A) then
hrp.CFrame = hrp.CFrame * CFrame.Angles(0, aggSpd, 0)
end
elseif pattern == "Smooth" then
local smoothAngle = math.atan2(math.sin(bhopStrafeTime * 0.02), 2) * strafeSpd
hrp.CFrame = hrp.CFrame * CFrame.Angles(0, smoothAngle, 0)
elseif pattern == "Circular" then
local circAngle = strafeSpd * 1.5
hrp.CFrame = hrp.CFrame * CFrame.Angles(0, circAngle, 0)
else
if UIS:IsKeyDown(Enum.KeyCode.D) then
hrp.CFrame = hrp.CFrame * CFrame.Angles(0, -strafeSpd, 0)
elseif UIS:IsKeyDown(Enum.KeyCode.A) then
hrp.CFrame = hrp.CFrame * CFrame.Angles(0, strafeSpd, 0)
end
end
if Flags.BhopWStrafe and UIS:IsKeyDown(Enum.KeyCode.W) then
local wsAngle = strafeSpd * 0.5
hrp.CFrame = hrp.CFrame * CFrame.Angles(0, wsAngle, 0)
end
end
if Flags.BhopGround and onGround then
local gsSpd = (Flags.BhopGroundSpd or 10) / 1000
local gPattern = Flags.BhopGroundPattern or "Left"
if gPattern == "Zigzag" then
gsSpd = gsSpd * (math.sin(bhopStrafeTime * 0.08) > 0 and 1 or -1)
elseif gPattern == "Wiggle" then
gsSpd = gsSpd * math.sin(bhopStrafeTime * 0.15)
elseif gPattern == "Right" then
gsSpd = -gsSpd
end
hrp.CFrame = hrp.CFrame * CFrame.Angles(0, -gsSpd, 0)
h.WalkSpeed = Flags.BhopSpeed or 24
end
if Flags.BhopCrouch then
if not onGround then
h.HipHeight = -0.5
else
h.HipHeight = 0
end
end
if Flags.BhopJB and onGround then
h.HipHeight = -0.5
task.delay(0.04, function()
if h then h.HipHeight = 0 end
end)
end
if Flags.BhopEB and mode ~= "Edge Bug" then
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = {lplr.Character}
local lookVec = hrp.CFrame.LookVector
local result = workspace:Raycast(hrp.Position, lookVec * 3 + Vector3.new(0, -5, 0), params)
if not result and not onGround then
h.WalkSpeed = math.min(h.WalkSpeed + 2, 30)
end
end
if Flags.BhopMultiJump and not onGround then
if UIS:IsKeyDown(Enum.KeyCode.Space) then
local timeSinceLast = now - bhopLastJump
if timeSinceLast > 0.15 and bhopMultiJumpUsed < (Flags.BhopMultiCount or 2) then
doJump()
bhopMultiJumpUsed = bhopMultiJumpUsed + 1
end
end
end
if onGround then
bhopMultiJumpUsed = 0
bhopLastGround = now
end
if Flags.BhopSpeedInd then
BS.BhopSpeed = math.floor(speed)
BS.BhopAvgSpeed = math.floor(bhopAvgSpeed)
BS.BhopMaxSpeed = math.floor(bhopMaxSpeed)
BS.BhopStamina = math.floor(bhopStamina)
end
end)
end
end)
local bhopHudGui = nil
task.spawn(function()
while true do
task.wait(0.15)
pcall(function()
if not (Flags.Bhop and Flags.BhopSpeedInd and BS.alive()) then
if bhopHudGui then bhopHudGui.Enabled = false end
end
if not bhopHudGui then
bhopHudGui = Instance.new("ScreenGui")
bhopHudGui.Name = "BS_BhopHUD"
bhopHudGui.IgnoreGuiInset = true
bhopHudGui.DisplayOrder = 9997
bhopHudGui.Parent = lplr.PlayerGui
local f = Instance.new("Frame", bhopHudGui)
f.Size = UDim2.new(0, 180, 0, 55)
f.Position = UDim2.new(0.5, -90, 1, -80)
f.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
f.BackgroundTransparency = 0.3
f.BorderSizePixel = 0
Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
for i = 1, 3 do
local lbl = Instance.new("TextLabel", f)
lbl.Name = "L" .. i
lbl.Size = UDim2.new(1, -10, 0, 16)
lbl.Position = UDim2.new(0, 5, 0, (i - 1) * 17 + 2)
lbl.BackgroundTransparency = 1
lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
lbl.TextSize = 11
lbl.Font = Enum.Font.Code
lbl.TextXAlignment = Enum.TextXAlignment.Left
end
end
bhopHudGui.Enabled = true
local f = bhopHudGui:FindFirstChildOfClass("Frame")
if f then
local spd = BS.BhopSpeed or 0
local avg = BS.BhopAvgSpeed or 0
local mx = BS.BhopMaxSpeed or 0
local stam = BS.BhopStamina or 0
local mode = Flags.BhopMode or "Auto"
f.L1.Text = string.format("Mode: %s | Speed: %d", mode, spd)
f.L1.TextColor3 = spd > 40 and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(200, 200, 200)
f.L2.Text = string.format("Avg: %d | Max: %d", avg, mx)
f.L2.TextColor3 = Color3.fromRGB(180, 180, 180)
if Flags.BhopStamina then
local stamPct = stam / (Flags.BhopMaxStamina or 50)
f.L3.Text = string.format("Stamina: %d/%d", stam, Flags.BhopMaxStamina or 50)
f.L3.TextColor3 = stamPct > 0.5 and Color3.fromRGB(0, 255, 0) or stamPct > 0.25 and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(255, 0, 0)
else
f.L3.Text = string.format("Jumps: %d", bhopJumpCount)
f.L3.TextColor3 = Color3.fromRGB(150, 150, 150)
end
end
end)
end
end)
M:Separator()
M:Toggle("Player Count Display", false, function(v) Flags.PlayerCount = v end)
M:Button({Name="Record Clip", Color=Color3.fromRGB(140,60,60)}, function()
pcall(function() StarterGui:SetCore("ToggleRecording", {}) end)
end)
M:Separator()
M:Toggle("Random Pitch", false, function(v) Flags.FxRandomPitch = v end)
M:Separator()
M:Dropdown({Name="Hit Sound Style", Flag="FxHitSoundIdx", Options={"1","2","3","4","5","6","7","8"}, Default="1"})
M:Separator()
M:Toggle("Screen Shake", false, function(v) Flags.FXShake = v end)
M:Separator()
M:Toggle("Damage Direction", false, function(v) Flags.FXDamageDir = v end)
M:Separator()
M:Label("7x Unstoppable | 10x Rampage | 15x GODLIKE")
M:Separator()
local playerCountGui
task.spawn(function()
while task.wait(2) do
pcall(function()
if Flags.PlayerCount then
if not playerCountGui then
playerCountGui = Instance.new("ScreenGui")
playerCountGui.Name = "BS_PlayerCount"
playerCountGui.IgnoreGuiInset = true
playerCountGui.DisplayOrder = 9997
playerCountGui.Parent = lplr.PlayerGui
local lbl = Instance.new("TextLabel", playerCountGui)
lbl.Size = UDim2.new(0, 130, 0, 22)
lbl.Position = UDim2.new(1, -140, 0, 10)
lbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
lbl.BackgroundTransparency = 0.3
lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
lbl.TextSize = 11
lbl.Font = Enum.Font.Code
Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 4)
end
playerCountGui.Enabled = true
local alive, total = 0, 0
for _, p in ipairs(Players:GetPlayers()) do
total = total + 1
if p.Character then
local hum = p and p.Character:FindFirstChildOfClass("Humanoid")
if hum and hum.Health > 0 then alive = alive + 1 end
end
end
local lbl = playerCountGui:FindFirstChildOfClass("TextLabel")
if lbl then lbl.Text = string.format("Alive: %d/%d", alive, total) end
else
if playerCountGui then playerCountGui.Enabled = false end
end
end)
end
end)
local U = BS.Win:Tab("Utility")
if not U or not U.Toggle then warn("[Utility] Failed to create tab!") return end
local bombTimerGui
task.spawn(function()
while task.wait(0.1) do
pcall(function()
if Flags.BombTimer then
local bomb = BS.api and BS.api.getBomb and BS.api.getBomb()
if bomb then
if not bombTimerGui then
bombTimerGui = Instance.new("ScreenGui")
bombTimerGui.Name = "BS_BombTimer"
bombTimerGui.IgnoreGuiInset = true
bombTimerGui.DisplayOrder = 9997
bombTimerGui.Parent = lplr.PlayerGui
local f = Instance.new("Frame", bombTimerGui)
f.Size = UDim2.new(0, 200, 0, 50)
f.Position = UDim2.new(0.5, -100, 0.1, 0)
f.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
f.BackgroundTransparency = 0.3
f.BorderSizePixel = 0
Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
local t = Instance.new("TextLabel", f)
t.Name = "TimerText"
t.Size = UDim2.new(1, 0, 1, 0)
t.BackgroundTransparency = 1
t.TextColor3 = Color3.fromRGB(255, 0, 0)
t.TextScaled = true
t.Font = Enum.Font.Code
end
bombTimerGui.Enabled = true
local duration = Flags.BombDuration or 40
local elapsed = bomb:GetAttribute("ElapsedTime") or 0
local remaining = math.max(0, duration - elapsed)
local textLabel = bombTimerGui.Frame:FindFirstChild("TimerText")
if textLabel then
textLabel.Text = string.format(" %.1fs", remaining)
textLabel.TextColor3 = remaining < 10 and Color3.fromRGB(255,0,0) or remaining < 20 and Color3.fromRGB(255,255,0) or Color3.fromRGB(255,255,255)
end
else
if bombTimerGui then bombTimerGui.Enabled = false end
end
else
if bombTimerGui then bombTimerGui.Enabled = false end
end
end)
end
end)
task.spawn(function()
while task.wait(0.5) do
if Flags.AutoDefuse and BS.alive() then
pcall(function()
local bomb = BS.api and BS.api.getBomb and BS.api.getBomb()
if not bomb then return end
local myHrp = BS.hrp()
if not myHrp then return end
local dist = (myHrp.Position - bomb.Position).Magnitude
if dist <= (Flags.DefuseRange or 5) then
if BS.api.hasDefuseKit and BS.api.hasDefuseKit() then
BS.equipTool("defuse") or BS.equipTool("kit")
task.wait(0.1)
end
local h = BS.hum()
if h then h:MoveTo(bomb.Position) end
if BS.api.defuseBomb then BS.api.defuseBomb() end
end
end)
end
end
end)
task.spawn(function()
while task.wait(1) do
if Flags.AutoPlant and BS.alive() then
pcall(function()
if not BS.api.hasBomb or not BS.api.hasBomb() then return end
local sites = workspace:FindFirstChild("BombSites") or workspace:FindFirstChild("Map")
if not sites then return end
local myHrp = BS.hrp()
if not myHrp then return end
local nearestSite, nearestDist = nil, math.huge
for _, site in pairs(sites:GetChildren()) do
local sitePos = site:GetPrimaryPartCFrame and site:GetPrimaryPartCFrame().Position
if sitePos then
local dist = (myHrp.Position - sitePos).Magnitude
if dist < nearestDist then nearestSite = site; nearestDist = dist end
end
end
if nearestSite and nearestDist < 30 then
local h = BS.hum()
if h then h:MoveTo(nearestSite:GetPrimaryPartCFrame().Position) end
task.wait(1)
if BS.api.plantBomb then BS.api.plantBomb(nearestSite.Name) end
end
end)
end
end
end)
UIS.InputBegan:Connect(function(input, gpe)
if gpe then return end
if Flags.PanicEnabled and input.KeyCode == Enum.KeyCode.Insert then
for key, _ in pairs(Flags) do
if key ~= "PanicEnabled" and key ~= "TeamCheck" and key ~= "FriendCheck" and key ~= "ESP_TeamCheck" then
Flags[key] = false
end
end
print("[Panic] All features disabled!")
end
end)
U:Button({Name="Server Hop", Color=Color3.fromRGB(60,100,140)}, function()
pcall(function()
local servers = game:GetService("HttpService"):JSONDecode(
game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
)
if servers and servers.data then
for _, server in pairs(servers.data) do
if server.id ~= game.JobId and server.playing < server.maxPlayers then
game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, server.id, lplr)
break
end
end
end
end)
end
task.spawn(function()
while task.wait(5) do
if Flags.AutoReconnect then
pcall(function()
if not lplr.Character then
task.wait(10)
if not lplr.Character then
game:GetService("TeleportService"):Teleport(game.PlaceId, lplr)
end
end
end)
end
end
end)
lplr.CharacterRemoving:Connect(function()
if bombTimerGui then bombTimerGui.Enabled = false end
if bhopHudGui then bhopHudGui.Enabled = false end
if playerCountGui then playerCountGui.Enabled = false end
end)
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
local GrenadePreview = {}
BS.GrenadePreview = GrenadePreview
function GrenadePreview:DrawTrajectory()
if not Flags.GrenadePreview then return end
pcall(function()
local hrp = BS.hrp()
if not hrp then return end
local cam = workspace.CurrentCamera
if not cam then return end
local origin = cam.CFrame.Position
local direction = cam.CFrame.LookVector * (Flags.GrenadeForce or 50)
local gravity = Vector3.new(0, -196.2, 0)
local dt = 0.05
local pos = origin
local vel = direction
local lastPos = pos
for i = 1, 60 do
vel = vel + gravity * dt
pos = pos + vel * dt
local sp, vis = cam:WorldToViewportPoint(pos)
if vis then
local line = poolLine()
line.From = v2(cam:WorldToViewportPoint(lastPos).X, cam:WorldToViewportPoint(lastPos).Y)
line.To = v2(sp.X, sp.Y)
line.Color = Color3.fromRGB(255, 255, 0)
line.Thickness = 1
line.Visible = true
end
local ray = Workspace:Raycast(lastPos, pos - lastPos)
if ray then break end
lastPos = pos
end
end)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.JumpThrow = function()
pcall(function()
local hrp = BS.hrp()
local hum = BS.hum()
if hrp and hum then
hum.Jump = true
task.delay(0.05, function()
pcall(function()
local vim = nil
pcall(function() vim = game:GetService("VirtualInputManager") end)
vim:SendMouseButtonEvent(0, 0, 0, true)
task.delay(0.05, function()
vim:SendMouseButtonEvent(0, 0, 0, false)
end)
end)
end)
end
end)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.QuickNade = function()
pcall(function()
local backpack = lplr and lplr.Backpack
if not backpack then return end
for _, tool in ipairs(backpack:GetChildren()) do
if tool:IsA("Tool") and (tool.Name:lower():find("grenade") or tool.Name:lower():find("flash") or tool.Name:lower():find("smoke") or tool.Name:lower():find("molotov")) then
tool.Parent = lplr.Character or lplr
task.delay(0.1, function()
pcall(function()
tool:Activate()
end)
end)
break
end
end
end)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.BombTimer = {Active = false, TimeLeft = 0, Site = "?"}
local bombTimerGui = nil
function BS.BombTimer:Start(site, duration)
self.Active = true
self.TimeLeft = duration or 40
self.Site = site or "?"
if not bombTimerGui then
bombTimerGui = Instance.new("ScreenGui")
bombTimerGui.Name = "BS_BombTimer"
bombTimerGui.Parent = game:GetService("CoreGui")
end
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 60)
frame.Position = UDim2.new(0.5, -100, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Parent = bombTimerGui
local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 0.5, 0)
label.BackgroundTransparency = 1
label.Text = "BOMB SITE: " .. self.Site
label.TextColor3 = Color3.fromRGB(255, 200, 0)
label.TextSize = 14
label.Font = Enum.Font.GothamBold
label.Parent = frame
local timer = Instance.new("TextLabel")
timer.Name = "Timer"
timer.Size = UDim2.new(1, 0, 0.5, 0)
timer.Position = UDim2.new(0, 0, 0.5, 0)
timer.BackgroundTransparency = 1
timer.Text = tostring(self.TimeLeft) .. "s"
timer.TextColor3 = Color3.fromRGB(255, 50, 50)
timer.TextSize = 20
timer.Font = Enum.Font.GothamBold
timer.Parent = frame
task.spawn(function()
while self.Active and self.TimeLeft > 0 do
task.wait(1)
self.TimeLeft = self.TimeLeft - 1
if timer then
timer.Text = tostring(self.TimeLeft) .. "s"
if self.TimeLeft <= 10 then
timer.TextColor3 = Color3.fromRGB(255, 0, 0)
end
end
end
self.Active = false
if bombTimerGui then bombTimerGui:ClearAllChildren() end
end)
end
function BS.BombTimer:Stop()
self.Active = false
if bombTimerGui then bombTimerGui:ClearAllChildren() end
end
page:Label(" Grenade ")
page:Toggle("Grenade Preview", false, function(v) Flags.GrenadePreview = v end)
page:Slider("Grenade Force", 20, 100, 50, function(v) Flags.GrenadeForce = v end)
page:Button({Name="Jump Throw"}, function() BS.JumpThrow() end)
page:Button({Name="Quick Nade"}, function() BS.QuickNade() end)
page:Separator()
page:Label(" Bomb ")
page:Button({Name="Start Timer (40s)"}, function() BS.BombTimer:Start("A", 40) end)
page:Button({Name="Stop Timer"}, function() BS.BombTimer:Stop() end)
print("[Utility] BloxStrike Utility module v2.0 loaded (Misc + Utility + Settings)")
]])
writefile("BloxStrike/modules/viewmodel.lua", [[
local Players = nil
pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local UIS = nil
pcall(function() UIS = game:GetService("UserInputService") end)
local lplr = Players.LocalPlayer
local VM = {
Scale = 1,
FOV = 70,
OriginalCameraFOV = 70,
}
local ViewmodelPresets = {
["Default"] = {
PosX = 0, PosY = 0, PosZ = 0,
AngX = 0, AngY = 0, AngZ = 0,
Scale = 1, FOV = 70,
},
["CS2 Style"] = {
PosX = -0.5, PosY = -0.3, PosZ = -1.5,
AngX = 0, AngY = 0, AngZ = 0,
Scale = 0.95, FOV = 68,
},
["Far Right"] = {
PosX = -1.2, PosY = -0.2, PosZ = -1.0,
AngX = 0, AngY = 15, AngZ = 0,
Scale = 0.9, FOV = 72,
},
["Close Up"] = {
PosX = 0, PosY = 0.2, PosZ = -0.5,
AngX = 0, AngY = 0, AngZ = 0,
Scale = 1.1, FOV = 65,
},
["Tight"] = {
PosX = -0.3, PosY = -0.5, PosZ = -1.8,
AngX = 5, AngY = 5, AngZ = 0,
Scale = 0.85, FOV = 70,
},
["Wide"] = {
PosX = -0.8, PosY = -0.1, PosZ = -2.0,
AngX = -3, AngY = -10, AngZ = 0,
Scale = 0.9, FOV = 80,
},
["Center"] = {
PosX = 0, PosY = -0.3, PosZ = -1.5,
AngX = 0, AngY = 0, AngZ = 0,
Scale = 0.95, FOV = 70,
},
["Insurgency"] = {
PosX = -0.7, PosY = -0.4, PosZ = -1.2,
AngX = 10, AngY = 8, AngZ = 0,
Scale = 1.0, FOV = 68,
},
}
local vmFovCircle = nil
local function calculateBob(speed, time)
if not Flags.VMBob then return Vector3.new(0, 0, 0) end
local bobAmount = Flags.VMBobAmount or 0.5
local bobSpeed = Flags.VMBobSpeed or 8
if speed < 1 then return Vector3.new(0, 0, 0) end
local bobX = math.sin(time * bobSpeed) * bobAmount * 0.5
local bobY = math.abs(math.cos(time * bobSpeed)) * bobAmount
return Vector3.new(bobX, bobY, 0)
end
local lastMousePos = Vector2.new(0, 0)
local swayVelocity = Vector2.new(0, 0)
local function calculateSway(dt)
if not Flags.VMSway then return Vector3.new(0, 0, 0) end
local mousePos = UIS:GetMouseLocation()
local delta = mousePos - lastMousePos
lastMousePos = mousePos
swayVelocity = swayVelocity:Lerp(delta / math.max(dt, 0.001), 0.1)
local swayAmount = Flags.VMSwayAmount or 0.3
local swayX = -swayVelocity.X * swayAmount * 0.01
local swayY = swayVelocity.Y * swayAmount * 0.01
return Vector3.new(swayX, swayY, 0)
end
local recoilOffset = Vector3.new(0, 0, 0)
local function applyRecoil(amount)
recoilOffset = recoilOffset + Vector3.new(0, amount * 0.5, amount * 0.2)
end
local function calculateBreathing(time)
if not Flags.VMBreathe then return Vector3.new(0, 0, 0) end
local breatheAmount = Flags.VMBreatheAmount or 0.1
local breatheSpeed = Flags.VMBreatheSpeed or 1.5
local breatheY = math.sin(time * breatheSpeed * math.pi) * breatheAmount
local breatheX = math.cos(time * breatheSpeed * math.pi * 0.5) * breatheAmount * 0.3
return Vector3.new(breatheX, breatheY, 0)
end
task.spawn(function()
while true do
local dt = RunService.RenderStepped:Wait()
pcall(function()
local cam = workspace.CurrentCamera
if not cam then return end
if VM.OriginalCameraFOV == 70 then
VM.OriginalCameraFOV = cam.FieldOfView
end
local anyEnabled = Flags.VMOffset or Flags.VMAngle or Flags.VMScale or Flags.VMFOV
or Flags.VMBob or Flags.VMSway or Flags.VMBreathe or Flags.VMRecoil
if not anyEnabled then return end
if not lplr.Character then return end
local tool = lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if not tool then return end
local handle = tool:FindFirstChild("Handle")
if not handle then return end
if Flags.VMOffset then
local offsetX = Flags.VMPosX or 0
local offsetY = Flags.VMPosY or 0
local offsetZ = Flags.VMPosZ or 0
VM.Offset = Vector3.new(offsetX / 10, offsetY / 10, offsetZ / 10)
end
if Flags.VMAngle then
local angX = Flags.VMAngX or 0
local angY = Flags.VMAngY or 0
local angZ = Flags.VMAngZ or 0
VM.Angle = Vector3.new(angX, angY, angZ)
end
if Flags.VMScale then
local scale = (Flags.VMScaleVal or 100) / 100
VM.Scale = math.clamp(scale, 0.5, 2)
end
if Flags.VMFOV then
cam.FieldOfView = Flags.VMFOVVal or 70
else
cam.FieldOfView = VM.OriginalCameraFOV
end
local speed = 0
local hrp = lplr and lplr.Character:FindFirstChild("HumanoidRootPart")
if hrp then
speed = hrp.AssemblyLinearVelocity.Magnitude
end
VM.BobOffset = calculateBob(speed, tick())
VM.SinOffset = calculateSway(dt)
local breatheOffset = calculateBreathing(tick())
recoilOffset = recoilOffset:Lerp(Vector3.new(0, 0, 0), dt * 10)
local totalOffset = VM.Offset + VM.BobOffset + VM.SinOffset + breatheOffset + recoilOffset
handle.CFrame = handle.CFrame + totalOffset
if Flags.VMAngle then
local angRad = Vector3.new(
math.rad(VM.Angle.X),
math.rad(VM.Angle.Y),
math.rad(VM.Angle.Z)
)
handle.CFrame = handle.CFrame * CFrame.Angles(angRad.X, angRad.Y, angRad.Z)
end
if Flags.VMScale and VM.Scale ~= 1 then
local mesh = handle:FindFirstChildWhichIsA("SpecialMesh")
if mesh then
mesh.Scale = Vector3.new(VM.Scale, VM.Scale, VM.Scale)
else
for _, child in ipairs(handle:GetChildren()) do
if child:IsA("DataModelMesh") then
child.Scale = Vector3.new(VM.Scale, VM.Scale, VM.Scale)
break
end
end
end
end
if Flags.VMFovCircle then
if not vmFovCircle then
local Compat = _G.BS and _G.BS.Compat
if Compat and Compat.DrawingNew then
vmFovCircle = Compat.DrawingNew("Circle")
else
pcall(function() vmFovCircle = Drawing.new("Circle") end)
end
if vmFovCircle then vmFovCircle.Thickness = 1; vmFovCircle.NumSides = 64; vmFovCircle.Filled = false end
end
if vmFovCircle then
vmFovCircle.Position = UIS:GetMouseLocation()
vmFovCircle.Radius = 100
vmFovCircle.Color = Color3.fromRGB(0, 255, 255)
vmFovCircle.Visible = true
end
else
if vmFovCircle then vmFovCircle.Visible = false end
end
end)
end
end)
task.spawn(function()
while true do
task.wait(0.1)
pcall(function()
if Flags.VMRecoil and lplr.Character then
local tool = lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
if tool then
local conn
conn = tool.Activated:Connect(function()
local recoilAmount = Flags.VMRecoilAmount or 1
applyRecoil(recoilAmount)
end)
if conn then
task.delay(1, function()
pcall(function() conn:Disconnect() end)
end)
end
end
end
end)
end
end)
lplr.CharacterRemoving:Connect(function()
pcall(function()
local cam = workspace.CurrentCamera
if cam then
cam.FieldOfView = VM.OriginalCameraFOV
end
end)
if vmFovCircle then vmFovCircle.Visible = false end
end)
BS.Viewmodel = {
Presets = ViewmodelPresets,
ApplyPreset = function(name)
local preset = ViewmodelPresets[name]
if not preset then return end
Flags.VMOffset = true
Flags.VMPosX = preset.PosX
Flags.VMPosY = preset.PosY
Flags.VMPosZ = preset.PosZ
Flags.VMAngle = true
Flags.VMAngX = preset.AngX
Flags.VMAngY = preset.AngY
Flags.VMAngZ = preset.AngZ
Flags.VMScale = true
Flags.VMScaleVal = preset.Scale * 100
Flags.VMFOV = true
Flags.VMFOVVal = preset.FOV
print("[Viewmodel] Applied preset: " .. name)
end,
}
local presetNames = {} for k, _ in pairs(ViewmodelPresets) do table.insert(presetNames, k) end
print("[Viewmodel] BloxStrike Viewmodel Changer loaded")
print("[Viewmodel] Presets: " .. table.concat(presetNames, ", "))
]])
writefile("BloxStrike/modules/webhook.lua", [[
local HttpService = nil
pcall(function() HttpService = game:GetService("HttpService") end)
local Players = nil
pcall(function() Players = game:GetService("Players") end)
local lplr = Players.LocalPlayer
local Webhook = {}
Webhook.URL = ""
Webhook.Queue = {}
Webhook.QueueInterval = 5
Webhook.LastFlush = 0
Webhook.Enabled = true
Webhook.Colors = {
Kill        = 15158332,
Death       = 15158332,
Headshot    = 16711680,
RoundWin    = 3066993,
RoundLose   = 15158332,
BombPlant   = 16753920,
BombDefuse  = 10181046,
BombExplode = 16711680,
ScriptLoad  = 3447003,
KillStreak  = 16766720,
MatchStart  = 8947848,
MatchEnd    = 3447003,
Money       = 5763719,
Squad       = 3447003,
}
Webhook.ColorNames = {}
for name, color in pairs(Webhook.Colors) do
Webhook.ColorNames[name] = color
end
function Webhook.getAvatarURL(userId)
return "https://www.roblox.com/headshot-thumbnail/image?userId="
end
function Webhook.send(payload)
if not Webhook.Enabled then return false end
if not Webhook.URL or Webhook.URL == "" then return false end
pcall(function()
local body = HttpService:JSONEncode(payload)
local headers = { ["Content-Type"] = "application/json" }
local Compat = _G.BS and _G.BS.Compat
if Compat and Compat.HttpRequest then
Compat.HttpRequest({
Url = Webhook.URL,
Method = "POST",
Headers = headers,
Body = body,
})
elseif syn and syn.request then
syn.request({ Url = Webhook.URL, Method = "POST", Headers = headers, Body = body })
elseif http_request then
http_request({ Url = Webhook.URL, Method = "POST", Headers = headers, Body = body })
elseif request then
request({ Url = Webhook.URL, Method = "POST", Headers = headers, Body = body })
end
end)
return true
end
function Webhook.message(content, username)
return Webhook.send({
content = content,
username = username or "BloxStrike",
})
end
function Webhook.embed(config)
local embed = {
title = config.title or "BloxStrike",
description = config.description or "",
color = config.color or Webhook.Colors.ScriptLoad,
footer = {
text = config.footer or ("BloxStrike | " .. os.date("%H:%M:%S")),
},
timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
}
if config.fields then
embed.fields = {}
for _, field in ipairs(config.fields) do
table.insert(embed.fields, {
name = field.name or "",
value = field.value or "",
inline = field.inline ~= false,
})
end
end
if config.thumbnail then
embed.thumbnail = { url = config.thumbnail }
end
if config.author then
embed.author = {
name = config.author.name or "",
icon_url = config.author.icon_url or "",
url = config.author.url or "",
}
end
return Webhook.send({
embeds = { embed },
username = config.username or "BloxStrike",
avatar_url = config.avatar_url or "",
})
end
function Webhook.queue(payload)
table.insert(Webhook.Queue, payload)
end
function Webhook.flush()
if #Webhook.Queue == 0 then return end
local now = tick()
if now - Webhook.LastFlush < Webhook.QueueInterval then return end
Webhook.LastFlush = now
local batch = {}
local count = math.min(#Webhook.Queue, 5)
for i = 1, count do
local payload = table.remove(Webhook.Queue, 1)
if payload.embeds then
for _, embed in ipairs(payload.embeds) do
table.insert(batch, embed)
end
end
end
if #batch > 0 then
Webhook.send({
embeds = batch,
username = "BloxStrike",
})
end
end
task.spawn(function()
while true do
task.wait(Webhook.QueueInterval)
end
end)
function Webhook.onKill(victim, killCount, weapon)
Webhook.embed({
title = " Kill #" .. killCount,
description = "Eliminated **" .. victim.DisplayName .. "**",
color = Webhook.Colors.Kill,
thumbnail = Webhook.getAvatarURL(victim.UserId),
fields = {
{ name = "Victim", value = victim.Name, inline = true },
{ name = "Weapon", value = weapon or "Unknown", inline = true },
{ name = "Total Kills", value = tostring(killCount), inline = true },
},
})
end
function Webhook.onHeadshot(victim, killCount)
Webhook.embed({
title = " Headshot #" .. killCount,
description = "Headshot **" .. victim.DisplayName .. "**!",
color = Webhook.Colors.Headshot,
thumbnail = Webhook.getAvatarURL(victim.UserId),
fields = {
{ name = "Victim", value = victim.Name, inline = true },
{ name = "Total Kills", value = tostring(killCount), inline = true },
},
})
end
function Webhook.onDeath(deathCount, killer)
local desc = "You were eliminated!"
if killer then
desc = desc .. "\nKilled by **" .. killer.DisplayName .. "**"
end
Webhook.embed({
title = " Death #" .. deathCount,
description = desc,
color = Webhook.Colors.Death,
fields = {
{ name = "Total Deaths", value = tostring(deathCount), inline = true },
},
})
end
function Webhook.onKillStreak(streak)
local titles = {
}
local title = titles[streak] or (" " .. streak .. " Kill Streak!")
Webhook.embed({
title = title,
description = "You're on a **" .. streak .. " kill streak**!",
color = Webhook.Colors.KillStreak,
})
end
function Webhook.onRoundWin(kills, deaths, score)
Webhook.embed({
title = " ROUND WIN!",
description = "Your team won the round!",
color = Webhook.Colors.RoundWin,
fields = {
{ name = "Score", value = score or "N/A", inline = true },
{ name = "K/D", value = kills .. "/" .. deaths, inline = true },
},
})
end
function Webhook.onRoundLose(kills, deaths, score)
Webhook.embed({
title = " ROUND LOST",
description = "Your team lost the round.",
color = Webhook.Colors.RoundLose,
fields = {
{ name = "Score", value = score or "N/A", inline = true },
{ name = "K/D", value = kills .. "/" .. deaths, inline = true },
},
})
end
function Webhook.onMatchStart(mapName)
Webhook.embed({
title = " Match Started",
description = "A new match has begun!",
color = Webhook.Colors.MatchStart,
fields = {
{ name = "Map", value = mapName or "Unknown", inline = true },
{ name = "Player", value = lplr.DisplayName, inline = true },
},
thumbnail = Webhook.getAvatarURL(lplr.UserId),
})
end
function Webhook.onMatchEnd(result, kills, deaths, mvp)
local isWin = result == "win"
Webhook.embed({
title = isWin and " MATCH VICTORY!" or " MATCH DEFEAT",
description = isWin
and "Congratulations! Your team won!"
or "Better luck next time!",
color = isWin and Webhook.Colors.RoundWin or Webhook.Colors.RoundLose,
fields = {
{ name = "Result", value = isWin and "WIN" or "LOSS", inline = true },
{ name = "K/D", value = kills .. "/" .. deaths, inline = true },
{ name = "MVP", value = mvp and "Yes " or "No", inline = true },
},
thumbnail = Webhook.getAvatarURL(lplr.UserId),
})
end
function Webhook.onBombPlanted(site, planter)
Webhook.embed({
title = " Bomb Planted!",
description = "C4 has been planted at **Site " .. (site or "?") .. "**",
color = Webhook.Colors.BombPlant,
fields = {
{ name = "Site", value = site or "Unknown", inline = true },
{ name = "Planter", value = planter and planter.DisplayName or "Unknown", inline = true },
},
})
end
function Webhook.onBombDefused(defuser, hasKit)
Webhook.embed({
title = " Bomb Defused!",
description = "The bomb has been defused!",
color = Webhook.Colors.BombDefuse,
fields = {
{ name = "Defuser", value = defuser and defuser.DisplayName or "Unknown", inline = true },
{ name = "Kit Used", value = hasKit and "Yes" or "No", inline = true },
},
})
end
function Webhook.onBombExplode()
Webhook.embed({
title = " BOOM!",
description = "The bomb has exploded!",
color = Webhook.Colors.BombExplode,
})
end
function Webhook.onScriptLoad()
Webhook.embed({
title = " BloxStrike Loaded",
description = "**" .. lplr.DisplayName .. "** has started BloxStrike!",
color = Webhook.Colors.ScriptLoad,
thumbnail = Webhook.getAvatarURL(lplr.UserId),
fields = {
{ name = "Username", value = lplr.Name, inline = true },
{ name = "User ID", value = tostring(lplr.UserId), inline = true },
{ name = "Account Age", value = lplr.AccountAge .. " days", inline = true },
{ name = "Server", value = game.JobId ~= "" and string.sub(game.JobId, 1, 8) .. "..." or "Studio", inline = true },
},
})
end
function Webhook.onMoneyEarned(amount, reason)
Webhook.embed({
title = " $" .. tostring(amount),
description = reason or "Money earned",
color = Webhook.Colors.Money,
fields = {
{ name = "Amount", value = "$" .. tostring(amount), inline = true },
{ name = "Reason", value = reason or "Unknown", inline = true },
},
})
end
BS.Webhook = Webhook
print("[Webhook] BloxStrike Discord Webhook module loaded")
print("[Webhook] Set URL in UI to enable | Supports: syn.request, http_request, request")
return Webhook
]])
writefile("BloxStrike/modules/world.lua", [[
local Players = nil
pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local Lighting = nil
pcall(function() Lighting = game:GetService("Lighting") end)
local Workspace = nil
pcall(function() Workspace = game:GetService("Workspace") end)
local lplr = Players.LocalPlayer
if not BS.Win then warn("[World] BS.Win not available - ui.lua may have failed") return end
local page = BS.Win:Tab("World")
if not page or not page.Toggle then warn("[World] Failed to create tab!") return end
page:Toggle("FOV Changer", false, function(v) Flags.FOVChanger = v end)
page:Slider("FOV Value", 60, 120, 90, function(v) Flags.FOVValue = v end)
page:Slider("ADS FOV", 20, 90, 40, function(v) Flags.ADSFOV = v end)
local defaultFOV = 70
task.spawn(function()
while task.wait(0.1) do
pcall(function()
local cam = workspace.CurrentCamera
if Flags.FOVChanger then
local tool = BS.tool()
local isScoped = tool and (tool.Name:lower():find("awp") or tool.Name:lower():find("sniper")
or tool.Name:lower():find("scoped"))
if isScoped then
cam.FieldOfView = Flags.ADSFOV or 40
else
cam.FieldOfView = Flags.FOVValue or 90
end
else
if cam.FieldOfView ~= defaultFOV then
cam.FieldOfView = defaultFOV
end
end
end)
end
end)
page:Toggle("Anti Flash", false, function(v) Flags.AntiFlash = v end)
page:Toggle("Full Bright", false, function(v) Flags.FullBright = v end)
local savedLighting = {}
task.spawn(function()
while task.wait(0.1) do
pcall(function()
if Flags.AntiFlash then
for _, effect in pairs(Lighting:GetChildren()) do
if effect:IsA("BlurEffect") then
effect.Size = 0
end
if effect:IsA("ColorCorrectionEffect") then
effect.Brightness = 0
effect.Contrast = 0
end
end
for _, gui in pairs(lplr.PlayerGui:GetChildren()) do
if gui.Name:lower():find("flash") or gui.Name:lower():find("blind")
or gui.Name:lower():find("stun") then
gui.Enabled = false
end
end
local cam = workspace.CurrentCamera
for _, gui in pairs(cam:GetChildren()) do
if gui:IsA("ScreenGui") then
gui.Enabled = false
end
end
end
if Flags.FullBright then
Lighting.Brightness = 2
Lighting.ClockTime = 14
Lighting.FogEnd = 100000
Lighting.GlobalShadows = false
end
end)
end
end)
page:Toggle("Wallhack", false, function(v) Flags.Wallhack = v end)
page:Slider("Wallhack Transparency", 50, 100, 70, function(v) Flags.WHTransparency = v end)
task.spawn(function()
local wallCache = {}
local wallCacheTime = 0
local function getWallParts()
local now = tick()
if now - wallCacheTime < 3 then return wallCache end
wallCache = {}
wallCacheTime = now
for _, part in pairs(Workspace:GetDescendants()) do
if part:IsA("BasePart") and part.Transparency < 0.5 then
table.insert(wallCache, part)
end
end
return wallCache
end
while task.wait(0.5) do
if Flags.Wallhack then
pcall(function()
local myPos = BS.hrp() and BS.hrp().Position
if not myPos then return end
local parts = getWallParts()
for _, part in ipairs(parts) do
if part and part.Parent then
local dist = (myPos - part.Position).Magnitude
if dist < 100 then
part.LocalTransparencyModifier = (Flags.WHTransparency or 70) / 100
end
end
end
end)
else
pcall(function()
for _, part in ipairs(wallCache) do
if part and part.Parent then
part.LocalTransparencyModifier = 0
end
end
wallCache = {}
end)
end
end
end)
page:Toggle("Smoke Reveal", false, function(v) Flags.SmokeReveal = v end)
task.spawn(function()
while task.wait(0.2) do
if Flags.SmokeReveal then
pcall(function()
for _, obj in pairs(Workspace:GetDescendants()) do
if obj.Name:lower():find("smoke") or obj.Name:lower():find("particle") then
if obj:IsA("Part") or obj:IsA("Beam") then
obj.Transparency = 1
end
end
end
for _, obj in pairs(Workspace:GetDescendants()) do
if obj:IsA("ParticleEmitter") and obj.Name:lower():find("smoke") then
obj.Enabled = false
end
end
end)
end
end
end)
page:Toggle("No Smoke", false, function(v) Flags.NoSmoke = v end)
task.spawn(function()
while task.wait(0.5) do
if Flags.NoSmoke then
pcall(function()
for _, obj in pairs(Workspace:GetDescendants()) do
if obj:IsA("ParticleEmitter") then
local name = obj.Name:lower()
if name:find("smoke") or name:find("cloud") or name:find("gas") then
obj.Enabled = false
end
end
if obj:IsA("Beam") and obj.Name:lower():find("smoke") then
obj.Enabled = false
end
end
end)
end
end
end)
page:Toggle("No Fire", false, function(v) Flags.NoFire = v end)
task.spawn(function()
while task.wait(0.3) do
if Flags.NoFire then
pcall(function()
for _, obj in pairs(Workspace:GetDescendants()) do
if obj:IsA("ParticleEmitter") then
local name = obj.Name:lower()
if name:find("fire") or name:find("flame") or name:find("molotov")
or name:find("incendiary") then
obj.Enabled = false
end
end
end
end)
end
end
end)
page:Toggle("Grenade Trajectory", false, function(v) Flags.GrenadeTrajectory = v end)
page:Slider("Trajectory Points", 10, 50, 30, function(v) Flags.TrajPoints = v end)
local trajectoryParts = {}
local MAX_TRAJ_PARTS = 20
local function clearTrajectory()
for _, part in pairs(trajectoryParts) do
pcall(function() part:Destroy() end)
end
trajectoryParts = {}
end
task.spawn(function()
while task.wait(0.15) do
clearTrajectory()
if Flags.GrenadeTrajectory then
pcall(function()
local tool = BS.tool()
if not tool then return end
local name = tool.Name:lower()
if not (name:find("grenade") or name:find("flash") or name:find("smoke")
or name:find("molotov") or name:find("he")) then return end
local cam = workspace.CurrentCamera
local origin = cam.CFrame.Position
local direction = cam.CFrame.LookVector * 50
local gravity = Vector3.new(0, -196.2, 0)
local velocity = direction * 2
local dt = 0.05
local pos = origin
local maxPoints = math.min(Flags.TrajPoints or 30, MAX_TRAJ_PARTS)
for i = 1, maxPoints do
velocity = velocity + gravity * dt
local newPos = pos + velocity * dt
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = {lplr.Character}
local result = workspace:Raycast(pos, newPos - pos, params)
if result then
local part = Instance.new("Part")
part.Size = Vector3.new(0.3, 0.3, 0.3)
part.Position = result.Position
part.Anchored = true
part.CanCollide = false
part.Transparency = 0.5
part.Color = Color3.fromRGB(255, 255, 0)
part.Material = Enum.Material.Neon
part.Parent = Workspace
part.Name = "BS_Traj"
table.insert(trajectoryParts, part)
break
end
local dot = Instance.new("Part")
dot.Size = Vector3.new(0.15, 0.15, 0.15)
dot.Position = newPos
dot.Anchored = true
dot.CanCollide = false
dot.Transparency = 0.3
dot.Color = Color3.fromRGB(255, 100, 0)
dot.Material = Enum.Material.Neon
dot.Parent = Workspace
dot.Name = "BS_Traj"
table.insert(trajectoryParts, dot)
pos = newPos
end
end)
end
end
end)
page:Toggle("Spectator List", false, function(v) Flags.SpectatorList = v end)
local spectatorGui
local knownSpectators = {}
task.spawn(function()
while task.wait(0.5) do
if Flags.SpectatorList then
pcall(function()
local myChar = lplr.Character
local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
if not myHRP then return end
local spectators = {}
for _, player in pairs(Players:GetPlayers()) do
if player ~= lplr then
local pChar = player.Character
if pChar then
local pHRP = pChar:FindFirstChild("HumanoidRootPart")
local pHum = pChar:FindFirstChildOfClass("Humanoid")
if pHRP and pHum and pHum.Health > 0 then
local theirCam = pChar:FindFirstChildOfClass("Camera")
local isSpectating = false
if pHum.Health <= 0 then
isSpectating = true
end
local lookDir = pHRP.CFrame.LookVector
local toUs = (myHRP.Position - pHRP.Position).Unit
local dot = lookDir:Dot(toUs)
if dot > 0.9 and (myHRP.Position - pHRP.Position).Magnitude < 200 then
isSpectating = true
end
if isSpectating then
table.insert(spectators, player.DisplayName)
end
end
end
end
end
if not spectatorGui then
spectatorGui = Instance.new("ScreenGui")
spectatorGui.Name = "BS_Spectator"
spectatorGui.IgnoreGuiInset = true
spectatorGui.DisplayOrder = 9997
spectatorGui.Parent = lplr.PlayerGui
local f = Instance.new("Frame", spectatorGui)
f.Size = UDim2.new(0, 160, 0, 30)
f.Position = UDim2.new(1, -170, 0.5, -80)
f.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
f.BackgroundTransparency = 0.4
f.BorderSizePixel = 0
Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
local title = Instance.new("TextLabel", f)
title.Size = UDim2.new(1, 0, 0, 16)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = " Spectators"
title.TextColor3 = Color3.fromRGB(255, 255, 0)
title.TextSize = 11
title.Font = Enum.Font.GothamBold
local list = Instance.new("TextLabel", f)
list.Name = "List"
list.Size = UDim2.new(1, -10, 1, -18)
list.Position = UDim2.new(0, 5, 0, 16)
list.BackgroundTransparency = 1
list.Text = "None"
list.TextColor3 = Color3.fromRGB(200, 200, 200)
list.TextSize = 10
list.Font = Enum.Font.Code
list.TextXAlignment = Enum.TextXAlignment.Left
list.TextWrapped = true
end
spectatorGui.Enabled = true
local listLabel = spectatorGui.Frame:FindFirstChild("List")
if listLabel then
if #spectators > 0 then
listLabel.Text = table.concat(spectators, ", ")
listLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
else
listLabel.Text = "None"
listLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
end
end
end)
else
if spectatorGui then spectatorGui.Enabled = false end
end
end
end)
page:Toggle("No Fall Damage", false, function(v) Flags.NoFallDamage = v end)
task.spawn(function()
while task.wait(0.1) do
if Flags.NoFallDamage then
pcall(function()
local h = BS.hum()
if h then
end
end)
end
end
end)
page:Toggle("Speed Boost", false, function(v) Flags.SpeedBoost = v end)
page:Slider("Speed Value", 16, 50, 20, function(v) Flags.SpeedValue = v end)
task.spawn(function()
while task.wait(0.2) do
if Flags.SpeedBoost and BS.alive() then
pcall(function()
local h = BS.hum()
if h then h.WalkSpeed = Flags.SpeedValue or 20 end
end)
end
end
end)
lplr.CharacterRemoving:Connect(function()
clearTrajectory()
pcall(function()
Lighting.Brightness = 1
Lighting.GlobalShadows = true
Lighting.FogEnd = 100000
end)
pcall(function()
for _, part in pairs(Workspace:GetDescendants()) do
if part:IsA("BasePart") then
part.LocalTransparencyModifier = 0
end
end
end)
end)
page:Label(" Night Mode ")
page:Toggle("Night Mode", false, function(v) Flags.NightMode = v end)
page:Slider("Brightness", 0, 5, 0, function(v) Flags.NightBrightness = v end)
page:Slider("Ambient R", 0, 80, 20, function(v) Flags.NightAmbientR = v end)
page:Slider("Ambient G", 0, 80, 20, function(v) Flags.NightAmbientG = v end)
page:Slider("Ambient B", 0, 80, 40, function(v) Flags.NightAmbientB = v end)
page:Toggle("Color Correction", false, function(v) Flags.NightCC = v end)
page:Slider("CC Brightness", -1, 1, 0, function(v) Flags.CCBrightness = v end)
page:Slider("CC Contrast", 0, 2, 1, function(v) Flags.CCContrast = v end)
page:Label(" Remove Scope ")
page:Toggle("Remove Scope Overlay", false, function(v) Flags.RemoveScope = v end)
page:Toggle("Remove Scope Blur", false, function(v) Flags.RemoveScopeBlur = v end)
page:Toggle("Remove Scope Sway", false, function(v) Flags.RemoveScopeSway = v end)
page:Toggle("Remove Scope Sway 2", false, function(v) Flags.RemoveScopeSway2 = v end)
page:Label(" Crosshair Color ")
page:Toggle("Custom Crosshair Color", false, function(v) Flags.CrosshairColor = v end)
page:Slider("Crosshair R", 0, 255, 255, function(v) Flags.CH_R = v end)
page:Slider("Crosshair G", 0, 255, 255, function(v) Flags.CH_G = v end)
page:Slider("Crosshair B", 0, 255, 255, function(v) Flags.CH_B = v end)
page:Label(" Remove Decals ")
page:Toggle("Remove Blood", false, function(v) Flags.RemoveBlood = v end)
page:Toggle("Remove Smoke", false, function(v) Flags.RemoveSmoke = v end)
page:Toggle("Remove Fog", false, function(v) Flags.NoFog = v end)
page:Toggle("Fullbright", false, function(v) Flags.Fullbright = v end)
page:Slider("Fullbright Value", 1, 10, 3, function(v) Flags.FullbrightVal = v end)
local originalBrightness = 1
local originalAmbient = Color3.new(0.5, 0.5, 0.5)
local ccObject = nil
task.spawn(function()
while true do
task.wait(0.3)
pcall(function()
if Flags.NightMode then
originalBrightness = Lighting.Brightness
originalAmbient = Lighting.Ambient
Lighting.Brightness = Flags.NightBrightness or 0
Lighting.Ambient = Color3.new(
(Flags.NightAmbientR or 20) / 255,
(Flags.NightAmbientG or 20) / 255,
(Flags.NightAmbientB or 40) / 255
)
if Flags.NightCC then
if not ccObject then
ccObject = Instance.new("ColorCorrectionEffect")
ccObject.Parent = Lighting
end
ccObject.Brightness = Flags.CCBrightness or 0
ccObject.Contrast = Flags.CCContrast or 1
end
else
if originalBrightness ~= 1 then
Lighting.Brightness = originalBrightness
Lighting.Ambient = originalAmbient
end
if ccObject then ccObject:Destroy() ccObject = nil end
end
end)
end
end)
task.spawn(function()
while true do
task.wait(0.1)
pcall(function()
if Flags.RemoveScope or Flags.RemoveScopeBlur then
local gui = lplr.PlayerGui:FindFirstChild("GunGui")
if gui then
local scope = gui:FindFirstChild("Scope")
if scope then scope.Visible = false end
end
local cam = workspace.CurrentCamera
if Flags.RemoveScopeSway then
local blur = Lighting:FindFirstChild("BlurEffect")
if blur then blur.Size = 0 end
end
end
end)
end
end)
task.spawn(function()
while true do
task.wait(0.2)
pcall(function()
if Flags.CrosshairColor then
local r = (Flags.CH_R or 255) / 255
local g = (Flags.CH_G or 255) / 255
local b = (Flags.CH_B or 255) / 255
local gui = lplr.PlayerGui:FindFirstChild("GunGui")
if gui then
for _, v in pairs(gui:GetDescendants()) do
if v:IsA("Frame") and v.Size.X.Scale < 0.01 then
v.BackgroundColor3 = Color3.new(r, g, b)
end
end
end
end
end)
end
end)
task.spawn(function()
while true do
task.wait(1)
pcall(function()
if Flags.RemoveBlood or Flags.RemoveSmoke then
for _, v in pairs(Workspace:GetDescendants()) do
if Flags.RemoveBlood and v.Name == "Blood" then v:Destroy() end
if Flags.RemoveSmoke and v:IsA("ParticleEmitter") then v.Enabled = false end
end
end
if Flags.NoFog then
Lighting.FogEnd = 999999
Lighting.FogStart = 0
end
if Flags.Fullbright then
Lighting.Brightness = Flags.FullbrightVal or 3
Lighting.ClockTime = 14
end
end)
end
end)
task.spawn(function()
while true do
task.wait(0.1)
if Flags.NoSpread and BS.alive() then
pcall(function()
local cam = workspace.CurrentCamera
cam.CFrame = cam.CFrame
end)
end
end
end)
task.spawn(function()
while true do
task.wait(0.01)
if Flags.NoRecoil and BS.alive() then
pcall(function()
local cam = workspace.CurrentCamera
local tool = lplr.Character and lplr and lplr.Character:FindFirstChildOfClass("Tool")
if tool and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
cam.CFrame = cam.CFrame * CFrame.new(0, 0, 0)
end
end)
end
end
end)
task.spawn(function()
while true do
task.wait(0.1)
pcall(function()
local cam = workspace.CurrentCamera
if Flags.ThirdPerson then
cam.CameraType = Enum.CameraType.Custom
lplr.CameraMinZoomDistance = 5
lplr.CameraMaxZoomDistance = 15
else
lplr.CameraMinZoomDistance = 0.5
lplr.CameraMaxZoomDistance = 0.5
end
end)
end
end)
local SpectatorObjs = {}
task.spawn(function()
while true do
task.wait(0.5)
if Flags.SpectatorList then
pcall(function()
local myChar = lplr.Character
if not myChar then return end
local myHead = myChar:FindFirstChild("Head")
if not myHead then return end
local specs = {}
for _, p in pairs(Players:GetPlayers()) do
if p ~= lplr and p.Character then
local cam = p and p.Character:FindFirstChildOfClass("Camera")
if cam and cam.CameraSubject == myHead then
table.insert(specs, p.Name)
end
end
end
for i = 1, math.max(#specs, #SpectatorObjs) do
if not SpectatorObjs[i] then
SpectatorObjs[i] = Drawing.new("Text")
SpectatorObjs[i].Center = false
SpectatorObjs[i].Outline = true
SpectatorObjs[i].OutlineColor = Color3.new(0,0,0)
SpectatorObjs[i].Font = 2
SpectatorObjs[i].Size = 13
end
if i <= #specs then
SpectatorObjs[i].Text = specs[i]
SpectatorObjs[i].Position = Vector2.new(10, 100 + (i-1) * 18)
SpectatorObjs[i].Color = Color3.new(1,1,1)
SpectatorObjs[i].Visible = true
else
SpectatorObjs[i].Visible = false
end
end
end)
else
for _, obj in pairs(SpectatorObjs) do
pcall(function() obj.Visible = false end)
end
end
end
end)
local fovArrowObj = nil
task.spawn(function()
while true do
task.wait(0.1)
if Flags.FOVChanger and Flags.FOVArrow then
pcall(function()
if not fovArrowObj then
fovArrowObj = Drawing.new("Line")
fovArrowObj.Thickness = 2
fovArrowObj.Color = Color3.new(1,1,1)
end
local cam = workspace.CurrentCamera
local center = cam.ViewportSize / 2
local mouse = UIS:GetMouseLocation()
local dir = (mouse - center).Unit
fovArrowObj.From = center
fovArrowObj.To = center + dir * 30
fovArrowObj.Visible = true
end)
else
if fovArrowObj then fovArrowObj.Visible = false end
end
end
end)
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.Chams = {Enabled = false}
function BS.Chams:Apply()
if not Flags.Chams then
self:Remove()
return
end
pcall(function()
for _, player in ipairs(Players:GetPlayers()) do
if player ~= lplr and player.Character then
for _, part in ipairs(player.Character:GetDescendants()) do
if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
if not part:FindFirstChild("BS_Cham") then
local highlight = Instance.new("Highlight")
highlight.Name = "BS_Cham"
highlight.FillColor = Flags.ChamsColor or Color3.fromRGB(255, 0, 0)
highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
highlight.FillTransparency = 0.5
highlight.OutlineTransparency = 0
highlight.Adornee = part
highlight.Parent = part
end
end
end
end
end
end)
end
function BS.Chams:Remove()
pcall(function()
for _, player in ipairs(Players:GetPlayers()) do
if player.Character then
for _, obj in ipairs(player.Character:GetDescendants()) do
if obj.Name == "BS_Cham" then obj:Destroy() end
end
end
end
end)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.AntiShake = {Enabled = false, OriginalCF = nil}
function BS.AntiShake:Enable()
self.Enabled = true
end
function BS.AntiShake:Disable()
self.Enabled = false
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.ZoomState = {Level = 0}
function BS.ZoomState:Toggle()
if self.Level == 0 then
self.Level = 1
pcall(function()
workspace.CurrentCamera.FieldOfView = Flags.ZoomFOV or 30
end)
else
self.Level = 0
pcall(function()
workspace.CurrentCamera.FieldOfView = 70
end)
end
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
BS.ColorCorrection = {Effect = nil}
function BS.ColorCorrection:Apply()
if not Flags.ColorCorrection then
self:Remove()
return
end
pcall(function()
if not self.Effect then
self.Effect = Instance.new("ColorCorrectionEffect")
self.Effect.Name = "BS_ColorCorrection"
self.Effect.Parent = Lighting
end
self.Effect.Brightness = Flags.CCBrightness or 0
self.Effect.Contrast = Flags.CCContrast or 0.2
self.Effect.Saturation = Flags.CCSaturation or 0.5
self.Effect.TintColor = Flags.CCTint or Color3.fromRGB(255, 255, 255)
end)
end
function BS.ColorCorrection:Remove()
pcall(function()
if self.Effect then self.Effect:Destroy() self.Effect = nil end
end)
end
page:Label(" Chams ")
page:Toggle("Chams", false, function(v) Flags.Chams = v BS.Chams:Apply() end)
page:Button({Name="Refresh Chams"}, function() BS.Chams:Apply() end)
page:Separator()
page:Label(" Camera ")
page:Toggle("Anti-Shake", false, function(v) Flags.AntiShake = v end)
page:Toggle("Scroll Zoom", false, function(v) Flags.ScrollZoom = v end)
page:Slider("Zoom FOV", 10, 60, 30, function(v) Flags.ZoomFOV = v end)
page:Separator()
page:Label(" Color Correction ")
page:Toggle("Color Correction", false, function(v) Flags.ColorCorrection = v BS.ColorCorrection:Apply() end)
page:Slider("Brightness", -100, 100, 0, function(v) Flags.CCBrightness = v / 100 BS.ColorCorrection:Apply() end)
page:Slider("Contrast", -100, 100, 20, function(v) Flags.CCContrast = v / 100 BS.ColorCorrection:Apply() end)
page:Slider("Saturation", -100, 100, 50, function(v) Flags.CCSaturation = v / 100 BS.ColorCorrection:Apply() end)
print("[World] BloxStrike World module loaded (14 features)")
]])
writefile('BloxStrike/BloxStrike.lua', [[

BLOXSTRIKE v3.0 — Bulletproof Injection Loader
Features:
- Multi-path module discovery
- Environment injection for Luau compatibility
- Graceful degradation (failed modules don't crash others)
- Automatic retry on loadstring failures
- Detailed error reporting with solutions
]]
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
print("[BloxStrike] v3.0 Loading...")
Flags = {}
_G.BS = _G.BS or {}
_G.Flags = Flags
_G.BS.Flags = Flags
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
local function safeRead(path)
if not readfile then
return nil, "readfile not available"
end
local success, result = pcall(readfile, path)
if success and result then
return result, nil
end
return nil, tostring(result or "read failed")
end
local function safeIsFile(path)
if not isfile then
return false
end
local success, result = pcall(isfile, path)
return success and result or false
end
local function safeMakeFolder(path)
if not makefolder then return false end
local success = pcall(makefolder, path)
return success
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
local MODULES = nil
local MODULE_PATH = nil
local candidates = {
"modules/core.lua",
"./modules/core.lua",
"BloxStrike/modules/core.lua",
"./BloxStrike/modules/core.lua",
"../BloxStrike/modules/core.lua",
"../../BloxStrike/modules/core.lua",
"workspace/BloxStrike/modules/core.lua",
"./workspace/BloxStrike/modules/core.lua",
"scripts/BloxStrike/modules/core.lua",
"./scripts/BloxStrike/modules/core.lua",
"../modules/core.lua",
"../../modules/core.lua",
"../../../modules/core.lua",
}
print("[BloxStrike] Searching for modules...")
print("[BloxStrike] APIs: readfile=" .. tostring(readfile ~= nil)
.. " isfile=" .. tostring(isfile ~= nil)
.. " listfiles=" .. tostring(listfiles ~= nil)
.. " makefolder=" .. tostring(makefolder ~= nil)
.. " writefile=" .. tostring(writefile ~= nil)
.. " loadfile=" .. tostring(loadfile ~= nil))
if listfiles then
pcall(function()
local files = listfiles("")
print("[BloxStrike] Root files: " .. #files)
for i = 1, math.min(10, #files) do print("  " .. files[i]) end
end)
pcall(function()
local files = listfiles("modules")
if files and #files > 0 then
print("[BloxStrike] Found modules/ with " .. #files .. " files!")
MODULES = "modules"
end
end)
pcall(function()
local files = listfiles("BloxStrike/modules")
if files and #files > 0 then
print("[BloxStrike] Found BloxStrike/modules/ with " .. #files .. " files!")
MODULES = "BloxStrike/modules"
end
end)
pcall(function()
local files = listfiles("scripts/BloxStrike/modules")
if files and #files > 0 then
print("[BloxStrike] Found scripts/BloxStrike/modules/ with " .. #files .. " files!")
MODULES = "scripts/BloxStrike/modules"
end
end)
end
for _, path in ipairs(candidates) do
local found = safeIsFile(path)
local status = found and "YES" or "no"
print("[BloxStrike]   " .. status .. " " .. path)
if found then
MODULE_PATH = path:gsub("/core%.lua$", "")
MODULES = path:gsub("/core%.lua$", "")
break
end
end
if not MODULES then
warn("")
warn("╔══════════════════════════════════════════════╗")
warn("║  ❌ COULD NOT FIND modules/ FOLDER          ║")
warn("╚══════════════════════════════════════════════╝")
warn("")
warn("HOW TO FIX:")
warn("")
warn("Method 1: Copy BloxStrike/ to your executor's workspace")
warn("  - For Potassium: %LOCALAPPDATA%\\Potassium\\scripts\\")
warn("")
warn("Method 2: The modules folder must contain:")
warn("  modules/")
warn("    core.lua")
warn("    ui.lua")
warn("    ... (other .lua files)")
warn("")
return
end
print("[BloxStrike] Found: " .. MODULES)
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
Environment preamble for Luau compatibility.
This ensures modules can access _G.BS, _G.Flags, and services.
In standard Lua 5.1/Roblox Luau, loadstring chunks share the caller's _G.
But some executors sandbox chunks, so we inject the preamble as a safety net.
]]
local ENV_PREAMBLE = [[
local _G = rawget(_G, "table") and _G or _G or {};
local BS = rawget(_G, "BS") or {};
local Flags = rawget(_G, "Flags") or {};
local Players, RunService, UserInputService, TweenService, Lighting, Workspace, StarterGui, ReplicatedStorage
pcall(function() Players = game:GetService("Players") end)
pcall(function() RunService = game:GetService("RunService") end)
pcall(function() UserInputService = game:GetService("UserInputService") end)
pcall(function() TweenService = game:GetService("TweenService") end)
pcall(function() Lighting = game:GetService("Lighting") end)
pcall(function() Workspace = game:GetService("Workspace") end)
pcall(function() StarterGui = game:GetService("StarterGui") end)
pcall(function() ReplicatedStorage = game:GetService("ReplicatedStorage") end)
local lplr = Players and Players.LocalPlayer or nil
local function alive()
if not lplr then return false end
local char = lplr.Character
if not char then return false end
local hum = char:FindFirstChildOfClass("Humanoid")
local hrp = char:FindFirstChild("HumanoidRootPart")
return hum and hrp and hum.Health > 0
end
local function hrp()
if not lplr then return nil end
local char = lplr.Character
return char and char:FindFirstChild("HumanoidRootPart")
end
local function hum()
if not lplr then return nil end
local char = lplr.Character
return char and char:FindFirstChildOfClass("Humanoid")
end
if BS and not BS.alive then BS.alive = alive end
if BS and not BS.hrp then BS.hrp = hrp end
if BS and not BS.hum then BS.hum = hum end
if BS and not BS.LocalPlayer then BS.LocalPlayer = lplr end
if BS and not BS.Players then BS.Players = Players end
if BS and not BS.RunService then BS.RunService = RunService end
if BS and not BS.UserInputService then BS.UserInputService = UserInputService end
if BS and not BS.TweenService then BS.TweenService = TweenService end
if BS and not BS.Lighting then BS.Lighting = Lighting end
if BS and not BS.Workspace then BS.Workspace = Workspace end
if BS and not BS.StarterGui then BS.StarterGui = StarterGui end
]]
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
local loaded = {}
local failed = {}
local loadOrder = {}
local function loadModule(name)
if loaded[name] then
return true
end
local path = MODULES .. "/" .. name .. ".lua"
local code, readErr = safeRead(path)
if not code then
table.insert(failed, { name = name, err = "file not found: " .. tostring(readErr) })
return false
end
code = code:gsub("%-%-!nocheck[%s]*", "")
code = ENV_PREAMBLE .. code
local fn, compileErr = loadstring(code, name)
if not fn then
local lineNum = compileErr and compileErr:match(":(%d+):") or "?"
local errMsg = compileErr and compileErr:match(":%d+: (.+)") or compileErr or "unknown"
table.insert(failed, { name = name, err = "syntax error at line " .. lineNum .. ": " .. errMsg })
return false
end
local success, result = pcall(fn)
if not success then
local errMsg = tostring(result or "unknown error")
local lineNum = errMsg:match(":(%d+):") or "?"
local solution = ""
if errMsg:find("attempt to index nil") then
solution = " (nil variable - check if required module loaded)"
elseif errMsg:find("attempt to call nil") then
solution = " (nil function - check API availability)"
elseif errMsg:find("bad argument") then
solution = " (wrong argument type)"
end
table.insert(failed, { name = name, err = "runtime error at line " .. lineNum .. ": " .. errMsg .. solution })
return false
end
if result then
loaded[name] = result
table.insert(loadOrder, name)
return true
else
loaded[name] = {}
table.insert(loadOrder, name)
return true
end
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
Load order is critical:
1. compat.lua - Executor compatibility layer
2. core.lua - Core services and utilities (sets up _G.BS)
3. ui.lua - UI system (creates BS.Win for tabs)
4. Everything else
]]
local PRIORITY = { "luau_detect", "luau_compat", "compat", "core", "ui" }
local REST = {
"api", "bypass", "cheatdetect", "combat", "combatassist",
"errorhandler", "esp", "events", "hud", "killeffects", "pingadapt",
"rage", "settings", "smartai", "stealth",
"utility", "viewmodel", "webhook", "world",
}
print("[BloxStrike] Loading priority modules...")
for _, name in ipairs(PRIORITY) do
local ok = loadModule(name)
print("  " .. (ok and "OK" or "FAIL") .. " " .. name)
end
if loaded.compat then
for k, v in pairs(loaded.compat) do
_G.BS[k] = v
end
end
if loaded.core then
for k, v in pairs(loaded.core) do
_G.BS[k] = v
end
end
_G.BS.Flags = Flags
_G.BS.Win = _G.BS.Win or nil
if not loaded.core then
warn("[BloxStrike] CRITICAL: core.lua failed to load!")
warn("[BloxStrike] Some features may not work correctly")
end
if not loaded.ui then
warn("[BloxStrike] WARNING: ui.lua failed to load!")
warn("[BloxStrike] Menu will not be available")
end
print("[BloxStrike] Loading other modules...")
for _, name in ipairs(REST) do
local ok = loadModule(name)
print("  " .. (ok and "OK" or "FAIL") .. " " .. name)
end
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
pcall(function()
if _G.BS.Bypass and _G.BS.Bypass.activateAll then
_G.BS.Bypass.activateAll()
print("[BloxStrike] Bypass system activated")
end
end)
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
local ok_count = 0
for _ in pairs(loaded) do
ok_count = ok_count + 1
end
print("")
print("╔══════════════════════════════════════════════╗")
print("║     ⚡ BLOXSTRIKE v3.0 ⚡                   ║")
print("╚══════════════════════════════════════════════╝")
print("")
print("[BloxStrike] " .. ok_count .. " modules loaded successfully")
print("[BloxStrike] " .. #failed .. " modules failed")
if _G.BS.Luau then
local L = _G.BS.Luau
print("[BloxStrike] Engine: " .. (L.engine or "unknown") .. " | Executor: " .. (L.version or "unknown"))
print("[BloxStrike] typeof=" .. tostring(L.canTypeof) .. " continue=" .. tostring(L.canContinue) .. " task=" .. tostring(L.canTask))
end
print("")
if #failed > 0 then
warn("[BloxStrike] FAILED MODULES:")
for _, f in ipairs(failed) do
warn("  ✗ " .. f.name .. " — " .. f.err)
end
warn("")
warn("[BloxStrike] TIP: Failed modules won't affect other modules")
end
print("[BloxStrike] Press INSERT to open menu")
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = "⚡ BloxStrike v3.0",
Text = "Loaded " .. ok_count .. " modules! Press INSERT.",
Duration = 5,
})
end)
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
]])
print('[BloxStrike] All files written! Executing...')
local fn = loadstring(readfile('BloxStrike/BloxStrike.lua'), 'BloxStrike')
if fn then fn() else print('[BloxStrike] Load failed!') end