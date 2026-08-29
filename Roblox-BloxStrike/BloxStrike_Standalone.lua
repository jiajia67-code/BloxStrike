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
    'combat',
    'esp',
    'hud', 'killeffects', 'utility', 'combatassist',
    'world',
    'rage', 'pingadapt', 'smartai',
    'settings', 'stealth', 'cheatdetect',
    'bypass', 'errorhandler', 'events', 'luau_detect'
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

-- ═══ Premium Loading GUI ═══
local GUI = Instance.new('ScreenGui')
GUI.Name = 'BloxStrike_Load'
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.DisplayOrder = 999
GUI.Parent = Player.PlayerGui

-- Full-screen gradient overlay
local Overlay = Instance.new('Frame')
Overlay.Size = UDim2.new(1, 0, 1, 0)
Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Overlay.BackgroundTransparency = 0.05
Overlay.BorderSizePixel = 0
Overlay.Parent = GUI

-- Animated scanline effect
local Scanline = Instance.new('Frame')
Scanline.Size = UDim2.new(1, 0, 0, 2)
Scanline.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
Scanline.BackgroundTransparency = 0.7
Scanline.BorderSizePixel = 0
Scanline.ZIndex = 5
Scanline.Parent = Overlay

-- Main panel with glass effect
local Panel = Instance.new('Frame')
Panel.Size = UDim2.new(0, 460, 0, 340)
Panel.Position = UDim2.new(0.5, -230, 0.5, -170)
Panel.BackgroundColor3 = Color3.fromRGB(8, 8, 16)
Panel.BackgroundTransparency = 0.1
Panel.BorderSizePixel = 0
Panel.Parent = GUI
Instance.new('UICorner', Panel).CornerRadius = UDim.new(0, 20)

-- Glass overlay
local Glass = Instance.new('Frame')
Glass.Size = UDim2.new(1, 0, 1, 0)
Glass.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Glass.BackgroundTransparency = 0.92
Glass.BorderSizePixel = 0
Glass.Parent = Panel
Instance.new('UICorner', Glass).CornerRadius = UDim.new(0, 20)

-- Outer glow border (thick, transparent)
local GlowBorder = Instance.new('UIStroke')
GlowBorder.Thickness = 4
GlowBorder.Color = Color3.fromRGB(0, 200, 255)
GlowBorder.Transparency = 0.5
GlowBorder.Parent = Panel

-- Inner border
local Border = Instance.new('UIStroke')
Border.Thickness = 1.5
Border.Color = Color3.fromRGB(0, 255, 220)
Border.Parent = Panel

-- Top accent line
local AccentLine = Instance.new('Frame')
AccentLine.Size = UDim2.new(1, -40, 0, 2)
AccentLine.Position = UDim2.new(0, 20, 0, 70)
AccentLine.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
AccentLine.BackgroundTransparency = 0.5
AccentLine.BorderSizePixel = 0
AccentLine.Parent = Panel

-- Title with shadow
local TitleShadow = Instance.new('TextLabel')
TitleShadow.Size = UDim2.new(1, -20, 0, 50)
TitleShadow.Position = UDim2.new(0, 12, 0, 17)
TitleShadow.BackgroundTransparency = 1
TitleShadow.Text = 'BLOXSTRIKE v' .. CURRENT_VERSION
TitleShadow.TextColor3 = Color3.fromRGB(0, 80, 120)
TitleShadow.TextSize = 30
TitleShadow.Font = Enum.Font.GothamBlack
TitleShadow.TextTransparency = 0.5
TitleShadow.Parent = Panel

local Title = Instance.new('TextLabel')
Title.Size = UDim2.new(1, -20, 0, 50)
Title.Position = UDim2.new(0, 10, 0, 15)
Title.BackgroundTransparency = 1
Title.Text = 'BLOXSTRIKE v' .. CURRENT_VERSION
Title.TextColor3 = Color3.fromRGB(0, 255, 220)
Title.TextSize = 30
Title.Font = Enum.Font.GothamBlack
Title.Parent = Panel

-- Version tag
local VersionTag = Instance.new('TextLabel')
VersionTag.Size = UDim2.new(0, 60, 0, 18)
VersionTag.Position = UDim2.new(1, -70, 0, 20)
VersionTag.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
VersionTag.BackgroundTransparency = 0.85
VersionTag.BorderSizePixel = 0
VersionTag.Text = 'v' .. CURRENT_VERSION
VersionTag.TextColor3 = Color3.fromRGB(0, 255, 200)
VersionTag.TextSize = 11
VersionTag.Font = Enum.Font.GothamBold
VersionTag.Parent = Panel
Instance.new('UICorner', VersionTag).CornerRadius = UDim.new(0, 8)
Instance.new('UIStroke', VersionTag).Color = Color3.fromRGB(0, 255, 200)
Instance.new('UIStroke', VersionTag).Thickness = 0.5
Instance.new('UIStroke', VersionTag).Transparency = 0.5

-- Update label
local UpdateLabel = Instance.new('TextLabel')
UpdateLabel.Size = UDim2.new(1, -20, 0, 18)
UpdateLabel.Position = UDim2.new(0, 10, 0, 50)
UpdateLabel.BackgroundTransparency = 1
UpdateLabel.Text = ''
UpdateLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
UpdateLabel.TextSize = 12
UpdateLabel.Font = Enum.Font.GothamBold
UpdateLabel.TextXAlignment = Enum.TextXAlignment.Right
UpdateLabel.Parent = Panel

-- Status
local StatusLabel = Instance.new('TextLabel')
StatusLabel.Size = UDim2.new(1, -40, 0, 22)
StatusLabel.Position = UDim2.new(0, 20, 0, 78)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = 'Initializing...'
StatusLabel.TextColor3 = Color3.fromRGB(140, 140, 160)
StatusLabel.TextSize = 13
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = Panel

-- Progress bar background with gradient
local BarBG = Instance.new('Frame')
BarBG.Size = UDim2.new(1, -40, 0, 8)
BarBG.Position = UDim2.new(0, 20, 0, 108)
BarBG.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
BarBG.BorderSizePixel = 0
BarBG.Parent = Panel
Instance.new('UICorner', BarBG).CornerRadius = UDim.new(1, 0)

-- Progress bar glow (behind main bar)
local BarGlow = Instance.new('Frame')
BarGlow.Size = UDim2.new(0, 0, 0, 12)
BarGlow.Position = UDim2.new(0, 0, -2, 0)
BarGlow.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
BarGlow.BackgroundTransparency = 0.6
BarGlow.BorderSizePixel = 0
BarGlow.Parent = BarBG
Instance.new('UICorner', BarGlow).CornerRadius = UDim.new(1, 0)

-- Progress bar fill
local BarFill = Instance.new('Frame')
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
BarFill.BorderSizePixel = 0
BarFill.Parent = BarBG
Instance.new('UICorner', BarFill).CornerRadius = UDim.new(1, 0)

-- Gradient on bar
local BarGradient = Instance.new('UIGradient')
BarGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 180, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 200)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 150)),
})
BarGradient.Parent = BarFill

-- Percentage
local PctLabel = Instance.new('TextLabel')
PctLabel.Size = UDim2.new(1, -40, 0, 22)
PctLabel.Position = UDim2.new(0, 20, 0, 120)
PctLabel.BackgroundTransparency = 1
PctLabel.Text = '0%'
PctLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
PctLabel.TextSize = 18
PctLabel.Font = Enum.Font.GothamBlack
PctLabel.TextXAlignment = Enum.TextXAlignment.Right
PctLabel.Parent = Panel

-- Module log
local LogFrame = Instance.new('ScrollingFrame')
LogFrame.Size = UDim2.new(1, -40, 0, 130)
LogFrame.Position = UDim2.new(0, 20, 0, 150)
LogFrame.BackgroundTransparency = 1
LogFrame.BorderSizePixel = 0
LogFrame.ScrollBarThickness = 3
LogFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 200)
LogFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
LogFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
LogFrame.Parent = Panel

local LogLayout = Instance.new('UIListLayout')
LogLayout.Padding = UDim.new(0, 2)
LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
LogLayout.Parent = LogFrame

-- Premium RGB Animation
local rgbTime = 0
local scanY = 0
local animConn = RunService.Heartbeat:Connect(function(dt)
    rgbTime = rgbTime + dt * 60
    
    -- Smooth color cycling
    local mainHue = rgbTime % 360
    local c1 = hsl(mainHue, 1, 0.55)
    local c2 = hsl((mainHue + 120) % 360, 0.9, 0.6)
    local c3 = hsl((mainHue + 240) % 360, 0.8, 0.5)
    
    -- Border glow
    Border.Color = c1
    GlowBorder.Color = c2
    GlowBorder.Transparency = 0.4 + math.sin(rgbTime * 0.05) * 0.2
    
    -- Title color
    Title.TextColor3 = hsl(mainHue, 1, 0.75)
    TitleShadow.TextColor3 = hsl(mainHue, 0.8, 0.2)
    
    -- Progress bar gradient offset
    BarGradient.Offset = Vector2.new(math.sin(rgbTime * 0.02) * 0.3, 0)
    BarFill.BackgroundColor3 = c1
    BarGlow.BackgroundColor3 = c2
    PctLabel.TextColor3 = c1
    AccentLine.BackgroundColor3 = c3
    
    -- Scanline animation
    scanY = (scanY + dt * 200) % 800
    Scanline.Position = UDim2.new(0, 0, 0, scanY - 100)
    Scanline.BackgroundColor3 = hsl(mainHue, 1, 0.7)
    
    -- Version tag pulse
    local pulse = 0.85 + math.sin(rgbTime * 0.08) * 0.1
    VersionTag.BackgroundTransparency = pulse
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

-- ═══ Global Preamble for modules ═══
local BS_PREAMBLE = [[
BS = _G.BS or {} Flags = _G.Flags or {} _G.BS = BS _G.Flags = Flags
local game = game local workspace = workspace local Instance = Instance
local Color3 = Color3 local UDim2 = UDim2 local UDim = UDim
local Vector3 = Vector3 local Vector2 = Vector2 local CFrame = CFrame
local Enum = Enum local tick = tick local wait = wait
local pcall = pcall local xpcall = xpcall local error = error
local warn = warn local print = print local pairs = pairs
local ipairs = ipairs local table = table local string = string
local math = math local task = task local unpack = unpack or table.unpack
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lplr = Players.LocalPlayer
local http_request = http_request local request = request
]]

-- ═══ PARALLEL DOWNLOAD ═══
local total = #MODULE_ORDER
local downloaded = {}
local dlDone = 0

StatusLabel.Text = 'Parallel download ' .. total .. ' modules...'
task.wait(0.1)

for _, name in ipairs(MODULE_ORDER) do
    task.spawn(function()
        local result = httpGet(BASE_URL .. name .. '.lua?v=' .. CURRENT_VERSION)
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
            -- Prepend globals to ensure BS/Flags are available
            local preamble = BS_PREAMBLE
            local fn, compileErr = loadstring(preamble .. code)
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

task.wait(2)

-- Premium fade out
if animConn then animConn:Disconnect() end

-- Panel slide up + fade
local panelStart = Panel.Position
for t = 0, 1, 0.02 do
    pcall(function()
        -- Fade overlay
        Overlay.BackgroundTransparency = 0.05 + t * 0.95
        
        -- Panel slide up + fade + shrink
        Panel.Position = UDim2.new(
            panelStart.X.Scale, panelStart.X.Offset,
            panelStart.Y.Scale - t * 0.05, panelStart.Y.Offset - t * 20
        )
        Panel.BackgroundTransparency = t * 0.5
        
        -- All descendants fade
        for _, v in ipairs(Panel:GetDescendants()) do
            pcall(function()
                if v:IsA('TextLabel') then
                    v.TextTransparency = t
                    v.TextStrokeTransparency = t
                elseif v:IsA('Frame') then
                    v.BackgroundTransparency = math.min(1, v.BackgroundTransparency + t * 0.5)
                elseif v:IsA('UIStroke') then
                    v.Transparency = t
                elseif v:IsA('UIGradient') then
                    v.Transparency = NumberSequence.new(t)
                end
            end)
        end
    end)
    task.wait(0.016) -- ~60fps
end

-- Final cleanup
pcall(function() GUI:Destroy() end)

print('[BloxStrike] v' .. CURRENT_VERSION .. ' loaded! ' .. ok .. '/' .. total .. ' modules (' .. elapsed .. 'ms)')
