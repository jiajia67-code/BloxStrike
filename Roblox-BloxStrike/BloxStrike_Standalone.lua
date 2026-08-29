--[[BloxStrike v3.4 - Fixed HTTP for all executors]]

if game.PlaceId ~= 114234929420007 then
    warn('[BloxStrike] Wrong game!')
    return
end

Flags = {}
_G.BS = _G.BS or {}
_G.Flags = Flags
_G.BS.Flags = Flags

local CURRENT_VERSION = '3.4'
local t0 = tick()
local BASE_URL = "https://raw.githubusercontent.com/jiajia67-code/BloxStrike/main/Roblox-BloxStrike/modules/"
local VERSION_URL = "https://raw.githubusercontent.com/jiajia67-code/BloxStrike/main/Roblox-BloxStrike/version.json"

-- ═══ Universal HTTP ═══
local function httpGet(url)
    -- Method 1: http_request (Fluxus, Potassium - confirmed working)
    if http_request then
        local ok, res = pcall(function()
            return http_request({Url = url, Method = 'GET'})
        end)
        if ok and res and res.Body then return res.Body end
    end
    -- Method 2: request (also confirmed working)
    if request then
        local ok, res = pcall(function()
            return request({Url = url, Method = 'GET'})
        end)
        if ok and res and res.Body then return res.Body end
    end
    -- Method 3: syn.request
    if syn and syn.request then
        local ok, res = pcall(function()
            return syn.request({Url = url, Method = 'GET'})
        end)
        if ok and res and res.Body then return res.Body end
    end
    -- Method 4: game:HttpGetAsync
    local ok4, res4 = pcall(function()
        return game:HttpGetAsync(url)
    end)
    if ok4 and res4 and #res4 > 0 then return res4 end
    -- Method 5: game:HttpGet
    local ok5, res5 = pcall(function()
        return game:HttpGet(url, true)
    end)
    if ok5 and res5 and #res5 > 0 then return res5 end
    -- Method 6: HttpService
    local ok6, res6 = pcall(function()
        return game:GetService("HttpService"):GetAsync(url)
    end)
    if ok6 and res6 and #res6 > 0 then return res6 end
    return nil
end

-- Test HTTP on startup
local httpTest = httpGet("https://httpbin.org/get")
if not httpTest then
    warn('[BloxStrike] CRITICAL: No HTTP method works!')
    return
end

-- Module names
local MOD_CN = {
    ['compat'] = '兼容層',
    ['core'] = '核心',
    ['ui'] = '介面',
    ['api'] = 'API',
    ['combat'] = '戰鬥系統',
    ['esp'] = '透視系統',
    ['rage'] = '暴力系統',
    ['stealth'] = '隱蔽系統',
    ['utility'] = '工具系統',
    ['world'] = '世界系統',
    ['pingadapt'] = '延遲適應',
    ['hud'] = 'HUD介面',
    ['killeffects'] = '擊殺特效',
    ['cheatdetect'] = '反作弊',
    ['settings'] = '設定',
    ['combatassist'] = '戰鬥輔助',
    ['smartai'] = '智能AI',
    ['bypass'] = '繞過系統',
    ['errorhandler'] = '錯誤處理',
    ['events'] = '事件系統',
    ['luau_detect'] = '語言偵測'
}

local MODULE_ORDER = {
    'compat', 'core', 'ui', 'api',
    'combat', 'esp', 'rage', 'stealth',
    'utility', 'world', 'pingadapt', 'hud',
    'killeffects', 'cheatdetect', 'settings',
    'combatassist', 'smartai', 'bypass',
    'errorhandler', 'events', 'luau_detect'
}

-- HSL
local function hsl(h, s, l)
    h = h % 360
    local c = (1 - math.abs(2*l-1)) * s
    local x = c * (1 - math.abs((h/60) % 2 - 1))
    local m = l - c/2
    local r,g,b = 0,0,0
    if h < 60 then r,g,b = c,x,0
    elseif h < 120 then r,g,b = x,c,0
    elseif h < 180 then r,g,b = 0,c,x
    elseif h < 240 then r,g,b = 0,x,c
    elseif h < 300 then r,g,b = x,0,c
    else r,g,b = c,0,x end
    return Color3.new(r+m, g+m, b+m)
end

local function isNewer(a, b)
    local pa, pb = {}, {}
    for s in a:gmatch('%d+') do pa[#pa+1] = tonumber(s) end
    for s in b:gmatch('%d+') do pb[#pb+1] = tonumber(s) end
    for i = 1, math.max(#pa, #pb) do
        local va = pa[i] or 0
        local vb = pb[i] or 0
        if va > vb then return true end
        if va < vb then return false end
    end
    return false
end

-- Auto update check
local latestVersion = nil
local changelog = {}
local updateCheckDone = false

task.spawn(function()
    local response = httpGet(VERSION_URL)
    if response then
        pcall(function()
            local ver = response:match('"version"%s*:%s*"([^"]+)"')
            if ver then latestVersion = ver end
            for item in response:gmatch('"([^"]+)"') do
                if item:match('^v%d') then changelog[#changelog+1] = item end
            end
        end)
    end
    updateCheckDone = true
end)

-- Services
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local Player = Players.LocalPlayer

-- Cleanup
pcall(function()
    for _, g in ipairs(Player.PlayerGui:GetChildren()) do
        if g.Name == 'BloxStrike_Load' then g:Destroy() end
    end
end)

-- ═══ Loading GUI ═══
local GUI = Instance.new('ScreenGui')
GUI.Name = 'BloxStrike_Load'
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.Parent = Player.PlayerGui

local Overlay = Instance.new('Frame')
Overlay.Size = UDim2.new(1, 0, 1, 0)
Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Overlay.BackgroundTransparency = 0.15
Overlay.BorderSizePixel = 0
Overlay.Parent = GUI

local Panel = Instance.new('Frame')
Panel.Size = UDim2.new(0, 420, 0, 300)
Panel.Position = UDim2.new(0.5, -210, 0.5, -150)
Panel.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
Panel.BorderSizePixel = 0
Panel.Parent = GUI
Instance.new('UICorner', Panel).CornerRadius = UDim.new(0, 16)

local Border = Instance.new('UIStroke')
Border.Thickness = 2
Border.Color = Color3.fromRGB(0, 255, 255)
Border.Parent = Panel

local Title = Instance.new('TextLabel')
Title.Size = UDim2.new(1, -20, 0, 50)
Title.Position = UDim2.new(0, 10, 0, 15)
Title.BackgroundTransparency = 1
Title.Text = 'BLOXSTRIKE v' .. CURRENT_VERSION
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.TextSize = 28
Title.Font = Enum.Font.GothamBold
Title.Parent = Panel

local UpdateLabel = Instance.new('TextLabel')
UpdateLabel.Size = UDim2.new(1, -20, 0, 20)
UpdateLabel.Position = UDim2.new(0, 10, 0, 48)
UpdateLabel.BackgroundTransparency = 1
UpdateLabel.Text = ''
UpdateLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
UpdateLabel.TextSize = 12
UpdateLabel.Font = Enum.Font.GothamBold
UpdateLabel.TextXAlignment = Enum.TextXAlignment.Right
UpdateLabel.Parent = Panel

local StatusLabel = Instance.new('TextLabel')
StatusLabel.Size = UDim2.new(1, -20, 0, 25)
StatusLabel.Position = UDim2.new(0, 10, 0, 75)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = '初始化...'
StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
StatusLabel.TextSize = 14
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Parent = Panel

local BarBG = Instance.new('Frame')
BarBG.Size = UDim2.new(1, -40, 0, 20)
BarBG.Position = UDim2.new(0, 20, 0, 110)
BarBG.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
BarBG.BorderSizePixel = 0
BarBG.Parent = Panel
Instance.new('UICorner', BarBG).CornerRadius = UDim.new(0, 10)

local BarFill = Instance.new('Frame')
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
BarFill.BorderSizePixel = 0
BarFill.Parent = BarBG
Instance.new('UICorner', BarFill).CornerRadius = UDim.new(0, 10)

local PctLabel = Instance.new('TextLabel')
PctLabel.Size = UDim2.new(1, -40, 0, 25)
PctLabel.Position = UDim2.new(0, 20, 0, 138)
PctLabel.BackgroundTransparency = 1
PctLabel.Text = '0%'
PctLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
PctLabel.TextSize = 16
PctLabel.Font = Enum.Font.GothamBold
PctLabel.Parent = Panel

local LogFrame = Instance.new('ScrollingFrame')
LogFrame.Size = UDim2.new(1, -40, 0, 110)
LogFrame.Position = UDim2.new(0, 20, 0, 170)
LogFrame.BackgroundTransparency = 1
LogFrame.BorderSizePixel = 0
LogFrame.ScrollBarThickness = 4
LogFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
LogFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
LogFrame.Parent = Panel

local LogLayout = Instance.new('UIListLayout')
LogLayout.Padding = UDim.new(0, 3)
LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
LogLayout.Parent = LogFrame

-- RGB Animation
local rgbTime = 0
local animConn = RunService.Heartbeat:Connect(function(dt)
    rgbTime = rgbTime + dt * 80
    Border.Color = hsl(rgbTime % 360, 1, 0.6)
    BarFill.BackgroundColor3 = hsl((rgbTime * 0.7) % 360, 0.8, 0.55)
    PctLabel.TextColor3 = hsl((rgbTime * 1.2 + 60) % 360, 0.8, 0.7)
    Title.TextColor3 = hsl(rgbTime % 360, 1, 0.75)
end)

local ok, fail = 0, 0
local function logModule(name, success, msg)
    if success then ok = ok + 1
    else fail = fail + 1 end
    local label = Instance.new('TextLabel')
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    local icon = success and '¹4' or '¹8'
    local color = success and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(255, 80, 80)
    label.Text = icon .. ' ' .. (MOD_CN[name] or name) .. (msg and (' (' .. msg .. ')') or '')
    label.TextColor3 = color
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.LayoutOrder = ok + fail
    label.Parent = LogFrame
end

local function updateProgress(i, total, name)
    local pct = math.floor(i / total * 100)
    BarFill.Size = UDim2.new(pct / 100, 0, 1, 0)
    PctLabel.Text = pct .. '%'
    if name then
        StatusLabel.Text = '載入: ' .. (MOD_CN[name] or name) .. ' (' .. i .. '/' .. total .. ')'
    end
end

-- Wait for version check
local waitStart = tick()
while not updateCheckDone and (tick() - waitStart) < 3 do
    task.wait(0.1)
end

if latestVersion and isNewer(latestVersion, CURRENT_VERSION) then
    UpdateLabel.Text = 'A0 v' .. latestVersion .. ' available'
    for i = 1, math.min(#changelog, 3) do
        local cl = Instance.new('TextLabel')
        cl.Size = UDim2.new(1, 0, 0, 16)
        cl.BackgroundTransparency = 1
        cl.Text = '  ' .. changelog[i]
        cl.TextColor3 = Color3.fromRGB(200, 200, 200)
        cl.TextSize = 11
        cl.Font = Enum.Font.Gotham
        cl.TextXAlignment = Enum.TextXAlignment.Left
        cl.LayoutOrder = 1000 + i
        cl.Parent = LogFrame
    end
    task.wait(2)
end

-- ═══ PARALLEL DOWNLOAD ═══
local total = #MODULE_ORDER
local downloaded = {}
local dlDone = 0

StatusLabel.Text = 'Parallel download ' .. total .. ' modules...'
task.wait(0.1)

for _, name in ipairs(MODULE_ORDER) do
    task.spawn(function()
        local result = httpGet(BASE_URL .. name .. '.lua')
        downloaded[name] = result  -- nil if failed
        dlDone = dlDone + 1
        local pct = math.floor(dlDone / total * 50)
        BarFill.Size = UDim2.new(pct / 100, 0, 1, 0)
        PctLabel.Text = pct .. '%'
        StatusLabel.Text = 'Download: ' .. (MOD_CN[name] or name) .. ' (' .. dlDone .. '/' .. total .. ')'
    end)
end

while dlDone < total do
    task.wait(0.05)
end

local dlTime = math.floor((tick() - t0) * 1000)
logModule('_dl', true, dlTime .. 'ms parallel download')

-- ═══ SEQUENTIAL EXECUTE ═══
for i, name in ipairs(MODULE_ORDER) do
    local progress = 50 + math.floor(i / total * 50)
    BarFill.Size = UDim2.new(progress / 100, 0, 1, 0)
    PctLabel.Text = progress .. '%'
    StatusLabel.Text = 'Load: ' .. (MOD_CN[name] or name) .. ' (' .. i .. '/' .. total .. ')'

    local code = downloaded[name]
    if not code then
        logModule(name, false, 'download failed')
    else
        local execOk, execErr = pcall(function()
            local fn, compileErr = loadstring(code)
            if not fn then error('Compile: ' .. (compileErr or 'unknown')) end
            fn()
        end)
        logModule(name, execOk, not execOk and tostring(execErr):sub(1, 50) or nil)
    end
    if i % 5 == 0 then task.wait() end
end

-- Finalize
BarFill.Size = UDim2.new(1, 0, 1, 0)
PctLabel.Text = '100%'
StatusLabel.Text = 'Done!'
task.wait(0.3)

local elapsed = math.floor((tick() - t0) * 1000)
local ResultLabel = Instance.new('TextLabel')
ResultLabel.Size = UDim2.new(1, -20, 0, 30)
ResultLabel.Position = UDim2.new(0, 10, 1, -35)
ResultLabel.BackgroundTransparency = 1
ResultLabel.Text = '¹4 ' .. ok .. ' OK  ¹8 ' .. fail .. ' FAIL  F1 ' .. elapsed .. 'ms (' .. dlTime .. 'ms dl)'
ResultLabel.TextColor3 = fail == 0 and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(255, 200, 50)
ResultLabel.TextSize = 13
ResultLabel.Font = Enum.Font.GothamBold
ResultLabel.Parent = Panel

local HintLabel = Instance.new('TextLabel')
HintLabel.Size = UDim2.new(1, -20, 0, 20)
HintLabel.Position = UDim2.new(0, 10, 1, -55)
HintLabel.BackgroundTransparency = 1
HintLabel.Text = 'Press INSERT to open menu'
HintLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
HintLabel.TextSize = 12
HintLabel.Font = Enum.Font.Gotham
HintLabel.Parent = Panel

task.wait(1.5)

if animConn then animConn:Disconnect() end
for t = 0, 1, 0.05 do
    pcall(function()
        Overlay.BackgroundTransparency = 0.15 + t * 0.85
        Panel.BackgroundTransparency = t
        for _, v in ipairs(Panel:GetDescendants()) do
            if v:IsA('TextLabel') then v.TextTransparency = t end
            if v:IsA('Frame') then v.BackgroundTransparency = t end
            if v:IsA('UIStroke') then v.Transparency = t end
        end
    end)
    task.wait(0.03)
end
GUI:Destroy()

print('[BloxStrike] v' .. CURRENT_VERSION .. ' loaded! ' .. ok .. '/' .. total .. ' modules (' .. elapsed .. 'ms)')
