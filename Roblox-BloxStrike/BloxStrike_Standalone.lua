--[[BloxStrike v4.0 - Error Prevention System]]

if game.PlaceId ~= 114234929420007 then
    warn('[BloxStrike] Wrong game!')
    return
end

Flags = {}
_G.BS = _G.BS or {}
_G.Flags = Flags
_G.BS.Flags = Flags

local CURRENT_VERSION = '3.5'
local t0 = tick()
local BASE_URL = "https://raw.githubusercontent.com/jiajia67-code/BloxStrike/main/Roblox-BloxStrike/modules/"

-- Universal HTTP
local function httpGet(url)
    if http_request then
        local ok, res = pcall(function()
            return http_request({Url = url, Method = 'GET'})
        end)
        if ok and res and res.Body then return res.Body end
    end
    if request then
        local ok, res = pcall(function()
            return request({Url = url, Method = 'GET'})
        end)
        if ok and res and res.Body then return res.Body end
    end
    if syn and syn.request then
        local ok, res = pcall(function()
            return syn.request({Url = url, Method = 'GET'})
        end)
        if ok and res and res.Body then return res.Body end
    end
    if game.HttpGetAsync then
        local ok, body = pcall(function() return game:HttpGetAsync(url) end)
        if ok and body then return body end
    end
    if game.HttpGet then
        local ok, body = pcall(function() return game:HttpGet(url, true) end)
        if ok and body then return body end
    end
    if fluxusrequest then
        local ok, res = pcall(function()
            return fluxusrequest({Url = url, Method = 'GET'})
        end)
        if ok and res and res.Body then return res.Body end
    end
    return nil
end

-- Version check
local VERSION_URL = "https://raw.githubusercontent.com/jiajia67-code/BloxStrike/main/Roblox-BloxStrike/version.json"
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

-- LOADING GUI
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local lplr = Players.LocalPlayer

pcall(function()
    for _, g in ipairs(lplr.PlayerGui:GetChildren()) do
        if g.Name == "BloxStrike_Load" then g:Destroy() end
    end
end)

local GUI = Instance.new("ScreenGui")
GUI.Name = "BloxStrike_Load"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.Parent = lplr.PlayerGui

-- Dark overlay
local Overlay = Instance.new("Frame")
Overlay.Size = UDim2.new(1, 0, 1, 0)
Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Overlay.BackgroundTransparency = 0.15
Overlay.BorderSizePixel = 0
Overlay.Parent = GUI

-- Main panel
local Panel = Instance.new("Frame")
Panel.Size = UDim2.new(0, 440, 0, 320)
Panel.Position = UDim2.new(0.5, -220, 0.5, -160)
Panel.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
Panel.BackgroundTransparency = 0.05
Panel.BorderSizePixel = 0
Panel.Parent = GUI
Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 20)

-- Glow border
local GlowBorder = Instance.new("UIStroke")
GlowBorder.Color = Color3.fromRGB(100, 150, 255)
GlowBorder.Thickness = 2
GlowBorder.Transparency = 0.3
GlowBorder.Parent = Panel

-- Inner border
local InnerBorder = Instance.new("Frame")
InnerBorder.Size = UDim2.new(1, -4, 1, -4)
InnerBorder.Position = UDim2.new(0, 2, 0, 2)
InnerBorder.BackgroundTransparency = 1
InnerBorder.BorderSizePixel = 0
InnerBorder.Parent = Panel
Instance.new("UICorner", InnerBorder).CornerRadius = UDim.new(0, 18)
local InnerStroke = Instance.new("UIStroke")
InnerStroke.Color = Color3.fromRGB(80, 120, 200)
InnerStroke.Thickness = 1
InnerStroke.Transparency = 0.6
InnerStroke.Parent = InnerBorder

-- Scanline
local Scanline = Instance.new("Frame")
Scanline.Size = UDim2.new(1, 0, 0, 2)
Scanline.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
Scanline.BackgroundTransparency = 0.5
Scanline.BorderSizePixel = 0
Scanline.Parent = Panel

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -30, 0, 36)
Title.Position = UDim2.new(0, 15, 0, 15)
Title.BackgroundTransparency = 1
Title.Text = "BLOXSTRIKE"
Title.TextColor3 = Color3.fromRGB(200, 200, 255)
Title.TextSize = 28
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Panel

-- Version badge
local VerBadge = Instance.new("TextLabel")
VerBadge.Size = UDim2.new(0, 60, 0, 20)
VerBadge.Position = UDim2.new(1, -75, 0, 18)
VerBadge.BackgroundColor3 = Color3.fromRGB(40, 60, 100)
VerBadge.Text = "v4.0"
VerBadge.TextColor3 = Color3.fromRGB(150, 180, 255)
VerBadge.TextSize = 11
VerBadge.Font = Enum.Font.Code
VerBadge.Parent = Panel
Instance.new("UICorner", VerBadge).CornerRadius = UDim.new(0, 10)

-- Gradient separator
local Sep = Instance.new("Frame")
Sep.Size = UDim2.new(1, -30, 0, 1)
Sep.Position = UDim2.new(0, 15, 0, 56)
Sep.BorderSizePixel = 0
Sep.Parent = Panel
local SepGrad = Instance.new("UIGradient")
SepGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 120, 200)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 80, 200)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 120, 200)),
})

-- Status label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -30, 0, 20)
StatusLabel.Position = UDim2.new(0, 15, 0, 62)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Starting..."
StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = Panel

-- Progress bar bg
local BarBG = Instance.new("Frame")
BarBG.Size = UDim2.new(1, -30, 0, 18)
BarBG.Position = UDim2.new(0, 15, 0, 88)
BarBG.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
BarBG.BorderSizePixel = 0
BarBG.Parent = Panel
Instance.new("UICorner", BarBG).CornerRadius = UDim.new(0, 9)

-- Progress bar fill
local BarFill = Instance.new("Frame")
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
BarFill.BorderSizePixel = 0
BarFill.Parent = BarBG
Instance.new("UICorner", BarFill).CornerRadius = UDim.new(0, 9)
local BarGrad = Instance.new("UIGradient")
BarGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 120, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 80, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 200, 255)),
})
BarGrad.Parent = BarFill

-- Bar glow
local BarGlow = Instance.new("Frame")
BarGlow.Size = UDim2.new(0, 0, 0, 6)
BarGlow.Position = UDim2.new(0, 0, 0.5, -3)
BarGlow.BackgroundTransparency = 0.5
BarGlow.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
BarGlow.BorderSizePixel = 0
BarGlow.ZIndex = 0
BarGlow.Parent = BarBG
Instance.new("UICorner", BarGlow).CornerRadius = UDim.new(0, 3)

-- Percentage
local PctLabel = Instance.new("TextLabel")
PctLabel.Size = UDim2.new(1, -30, 0, 18)
PctLabel.Position = UDim2.new(0, 15, 0, 110)
PctLabel.BackgroundTransparency = 1
PctLabel.Text = "0%"
PctLabel.TextColor3 = Color3.fromRGB(150, 180, 255)
PctLabel.TextSize = 11
PctLabel.Font = Enum.Font.Code
PctLabel.TextXAlignment = Enum.TextXAlignment.Right
PctLabel.Parent = Panel

-- Log area
local LogFrame = Instance.new("ScrollingFrame")
LogFrame.Size = UDim2.new(1, -30, 0, 130)
LogFrame.Position = UDim2.new(0, 15, 0, 132)
LogFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 15)
LogFrame.BorderSizePixel = 0
LogFrame.ScrollBarThickness = 3
LogFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 120, 200)
LogFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
LogFrame.Parent = Panel
Instance.new("UICorner", LogFrame).CornerRadius = UDim.new(0, 8)
local LogLayout = Instance.new("UIListLayout", LogFrame)
LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
LogLayout.Padding = UDim.new(0, 1)

local logCount = 0
local function logModule(name, ok, extra)
    logCount = logCount + 1
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -5, 0, 14)
    lbl.BackgroundTransparency = 1
    local icon = ok and "+" or "x"
    local color = ok and Color3.fromRGB(80, 255, 150) or Color3.fromRGB(255, 80, 80)
    lbl.TextColor3 = color
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Code
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local cn = MOD_CN[name] or name
    lbl.Text = "  " .. icon .. " " .. cn .. (extra and (" (" .. extra .. ")") or "")
    lbl.LayoutOrder = logCount
    lbl.Parent = LogFrame
    LogFrame.CanvasSize = UDim2.new(0, 0, 0, logCount * 15)
    LogFrame.CanvasPosition = Vector2.new(0, math.max(0, logCount * 15 - 130))
end

-- Result
local ResultLabel = Instance.new("TextLabel")
ResultLabel.Size = UDim2.new(1, -30, 0, 20)
ResultLabel.Position = UDim2.new(0, 15, 1, -30)
ResultLabel.BackgroundTransparency = 1
ResultLabel.Text = ""
ResultLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
ResultLabel.TextSize = 12
ResultLabel.Font = Enum.Font.GothamBold
ResultLabel.TextXAlignment = Enum.TextXAlignment.Center
ResultLabel.Parent = Panel

-- Hint
local HintLabel = Instance.new("TextLabel")
HintLabel.Size = UDim2.new(1, 0, 0, 18)
HintLabel.Position = UDim2.new(0, 0, 1, -14)
HintLabel.BackgroundTransparency = 1
HintLabel.Text = "Press INSERT to open menu"
HintLabel.TextColor3 = Color3.fromRGB(80, 80, 100)
HintLabel.TextSize = 11
HintLabel.Font = Enum.Font.Gotham
HintLabel.Parent = Overlay

-- RGB Animation
local hueOffset = 0
local animConn
animConn = RunService.RenderStepped:Connect(function(dt)
    hueOffset = (hueOffset + dt * 40) % 360
    local h = hueOffset
    GlowBorder.Color = hsl(h, 0.8, 0.6)
    InnerStroke.Color = hsl(h + 30, 0.6, 0.5)
    Title.TextColor3 = hsl(h, 0.7, 0.75)
    BarGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, hsl(h, 0.8, 0.5)),
        ColorSequenceKeypoint.new(0.5, hsl(h + 60, 0.8, 0.5)),
        ColorSequenceKeypoint.new(1, hsl(h + 120, 0.8, 0.5)),
    })
    SepGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, hsl(h, 0.6, 0.4)),
        ColorSequenceKeypoint.new(0.5, hsl(h + 90, 0.7, 0.5)),
        ColorSequenceKeypoint.new(1, hsl(h + 180, 0.6, 0.4)),
    })
    BarGlow.BackgroundColor3 = hsl(h + 45, 0.7, 0.5)
    local scanY = (tick() * 0.3 % 1)
    Scanline.Position = UDim2.new(0, 0, scanY, 0)
    Scanline.BackgroundColor3 = hsl(h, 0.5, 0.6)
    BarFill.BackgroundColor3 = hsl(h, 0.7, 0.55)
end)

-- Version display
task.spawn(function()
    while not updateCheckDone do task.wait(0.1) end
    if latestVersion and isNewer(latestVersion, CURRENT_VERSION) then
        Title.Text = "BLOXSTRIKE -> " .. latestVersion
        ResultLabel.Text = "New version available!"
        ResultLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "BloxStrike Update",
                Text = "v" .. latestVersion .. " available!",
                Duration = 5,
            })
        end)
    end
end)

-- Module CN names
local MOD_CN = {
    ['api'] = 'API',
    ['bypass'] = '反檢測',
    ['cheatdetect'] = '作弊偵測',
    ['combat'] = '戰鬥系統',
    ['combatassist'] = '戰鬥輔助',
    ['compat'] = '兼容層',
    ['core'] = '核心',
    ['errorhandler'] = '錯誤處理',
    ['esp'] = '透視系統',
    ['events'] = '事件系統',
    ['hud'] = 'HUD顯示',
    ['killeffects'] = '擊殺特效',
    ['luau_compat'] = 'Luau兼容',
    ['luau_detect'] = 'Luau偵測',
    ['pingadapt'] = '延遲適應',
    ['rage'] = '暴力系統',
    ['settings'] = '設定',
    ['smartai'] = '智能AI',
    ['stealth'] = '隱身系統',
    ['ui'] = '介面',
    ['utility'] = '工具',
    ['viewmodel'] = '視角模型',
    ['webhook'] = 'Webhook',
    ['world'] = '世界',
}

-- Module load order (defines tab order)
local MODULE_ORDER = {
    'compat', 'core', 'ui', 'api',
    'combat',
    'esp',
    'hud', 'killeffects', 'utility', 'combatassist',
    'world',
    'rage', 'pingadapt', 'smartai',
    'settings', 'stealth', 'cheatdetect',
    'bypass', 'errorhandler', 'events', 'luau_detect',
}

-- Globals preamble injected into each module
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local lplr = Players.LocalPlayer
local http_request = http_request local request = request

local BS_PREAMBLE = "_G.BS = _G.BS or {}; BS = _G.BS; _G.Flags = _G.Flags or {}; Flags = _G.Flags; game = game; workspace = workspace; "
    .. "Instance = Instance; UDim2 = UDim2; UDim = UDim; Color3 = Color3; "
    .. "Vector3 = Vector3; Vector2 = Vector2; CFrame = CFrame; "
    .. "Enum = Enum; math = math; string = string; table = table; "
    .. "pcall = pcall; xpcall = xpcall; error = error; "
    .. "RunService = game:GetService('RunService'); "
    .. "UserInputService = game:GetService('UserInputService'); "
    .. "TweenService = game:GetService('TweenService'); "
    .. "HttpService = game:GetService('HttpService'); "
    .. "Players = game:GetService('Players'); "
    .. "print = print; warn = warn; task = task; tick = tick; "
    .. "wait = wait; spawn = spawn; delay = delay; "
    .. "typeof = typeof; type = type; tostring = tostring; tonumber = tonumber; "
    .. "select = select; pairs = pairs; ipairs = ipairs; "
    .. "rawget = rawget; rawset = rawset; "
    .. "getmetatable = getmetatable; setmetatable = setmetatable; "
    .. "collectgarbage = collectgarbage; newproxy = newproxy; "
    .. "utf8 = utf8; bit32 = bit32; "

-- ═══ OPTIMIZED PARALLEL DOWNLOAD ═══
-- Features: concurrency limit, timeout, retry, speed tracking
local total = #MODULE_ORDER
local downloaded = {}
local dlDone = 0
local dlTotalBytes = 0
local MAX_RETRY = 2

-- Timestamp cache buster
local CACHE_BUSTER = tostring(math.floor(tick() * 1000))
print("[BloxStrike] Sequential download, " .. MAX_RETRY .. " retries max")

-- HTTP download with timeout (task.spawn + polling)
local DL_TIMEOUT = 12  -- seconds before giving up on a download

local function httpGetFast(url)
    local result = nil
    local done = false
    
    task.spawn(function()
        local ok, res = pcall(function()
            if http_request then
                return http_request({Url = url, Method = 'GET'})
            elseif request then
                return request({Url = url, Method = 'GET'})
            elseif game.HttpGet then
                local b = game:HttpGet(url, true)
                return {Body = b}
            end
        end)
        if ok and res and res.Body then
            result = res.Body
        end
        done = true
    end)
    
    local t0 = tick()
    while not done and (tick() - t0) < DL_TIMEOUT do
        task.wait(0.1)
    end
    
    if not done then
        warn('[BS] HTTP timeout (' .. DL_TIMEOUT .. 's) for: ' .. url:match('/([^/]+)$'))
        return nil
    end
    return result
end

-- Download with validation
local function downloadModule(name, attempt)
    attempt = attempt or 1
    local url = BASE_URL .. name .. '.lua?t=' .. CACHE_BUSTER .. '&r=' .. attempt
    
    local startTime = tick()
    local result = httpGetFast(url)
    local elapsed = tick() - startTime
    
    if result and #result > 100 and not result:find('<!DOCTYPE') and not result:find('404') then
        dlTotalBytes = dlTotalBytes + #result
        return result, elapsed
    elseif attempt < MAX_RETRY then
        task.wait(0.3)
        return downloadModule(name, attempt + 1)
    else
        return nil, elapsed
    end
end

-- Speed formatter
local function formatSpeed(bytes, seconds)
    if seconds <= 0 then return '∞' end
    local kb = bytes / 1024
    local speed = kb / seconds
    if speed > 1 then
        return string.format('%.1f KB/s', speed)
    else
        return string.format('%.0f B/s', bytes / seconds)
    end
end

-- ═══ PHASE 1: SEQUENTIAL DOWNLOAD (prevents hanging) ═══
StatusLabel.Text = 'Download ' .. total .. ' modules...'
task.wait(0.05)

local dlStartTime = tick()

for _, name in ipairs(MODULE_ORDER) do
    local code, elapsed = downloadModule(name)
    downloaded[name] = code
    dlDone = dlDone + 1
    
    local pct = math.floor(dlDone / total * 50)
    BarFill.Size = UDim2.new(pct / 100, 0, 1, 0)
    BarGlow.Size = UDim2.new(pct / 100, 0, 1, 0)
    PctLabel.Text = pct .. '%'
    
    local speed = formatSpeed(dlTotalBytes, tick() - dlStartTime)
    local status = code and '✓' or '✗'
    local sizeStr = code and string.format('%.1fKB', #code / 1024) or 'failed'
    StatusLabel.Text = status .. ' ' .. (MOD_CN[name] or name) .. ' ' .. sizeStr .. ' (' .. dlDone .. '/' .. total .. ') ' .. speed
    
    task.wait()  -- yield to keep GUI responsive
end

local phase1Time = math.floor((tick() - dlStartTime) * 1000)

-- Count failures (no retry - skip immediately to prevent hanging)
local retryFailed = {}
for _, name in ipairs(MODULE_ORDER) do
    if not downloaded[name] then
        retryFailed[#retryFailed + 1] = name
        logModule(name, false, 'download failed, skipped')
    end
end
if #retryFailed > 0 then
    warn('[BS] ' .. #retryFailed .. ' modules failed: ' .. table.concat(retryFailed, ', '))
end

-- ═══ PHASE 3: VALIDATION ═══
local validCount = 0
local totalSize = 0
for _, name in ipairs(MODULE_ORDER) do
    if downloaded[name] then
        validCount = validCount + 1
        totalSize = totalSize + #downloaded[name]
    end
end

local dlTime = math.floor((tick() - t0) * 1000)
local avgSpeed = formatSpeed(totalSize, (tick() - dlStartTime))
local summary = string.format('%d/%d modules, %.1fKB total, %s, phase1:%dms',
    validCount, total, totalSize / 1024, avgSpeed, phase1Time)
logModule('_dl', validCount == total, summary)
print("[BloxStrike] Download complete: " .. summary)

-- SEQUENTIAL EXECUTE
local ok, fail = 0, 0
local failedModules = {}

for i, name in ipairs(MODULE_ORDER) do
    local progress = 50 + math.floor(i / total * 50)
    BarFill.Size = UDim2.new(progress / 100, 0, 1, 0)
    BarGlow.Size = UDim2.new(progress / 100, 0, 1, 0)
    PctLabel.Text = progress .. '%'
    StatusLabel.Text = 'Load: ' .. (MOD_CN[name] or name) .. ' (' .. i .. '/' .. total .. ')'

    local code = downloaded[name]
    local loaded = false

    -- Try up to 3 times with improved error extraction
    for attempt = 1, 3 do
        if loaded then break end
        if attempt > 1 and code then
            code = httpGet(BASE_URL .. name .. '.lua?t=' .. CACHE_BUSTER .. '&retry=' .. attempt)
            task.wait(0.1 * attempt)
        end
        if code then
            local execOk, execErr = pcall(function()
                local fn, compileErr = loadstring(BS_PREAMBLE .. code)
                if not fn then error('Compile: ' .. (compileErr or 'unknown')) end
                fn()
            end)
            if execOk then
                loaded = true
                ok = ok + 1
                logModule(name, true, attempt > 1 and 'retry OK' or nil)
            else
                local errStr = tostring(execErr)
                local errLine = errStr:match(': (%d+):') or errStr:match('line (%d+)')
                local errType = 'Runtime'
                if errStr:find('Compile:') then errType = 'Compile'
                elseif errStr:find('Timeout') then errType = 'Timeout'
                elseif errStr:find('attempt to index') then errType = 'Index'
                elseif errStr:find('attempt to call') then errType = 'Call'
                elseif errStr:find('Expected') then errType = 'Syntax'
                end
                local detail = errType
                if errLine then detail = detail .. ' L' .. errLine end
                detail = detail .. ': ' .. errStr:sub(1, 30)
                if attempt == 3 then
                    fail = fail + 1
                    failedModules[#failedModules + 1] = name
                    logModule(name, false, detail)
                else
                    logModule(name, false, detail .. ' (retry ' .. attempt .. ')')
                end
            end
        elseif attempt == 3 then
            fail = fail + 1
            failedModules[#failedModules + 1] = name
            logModule(name, false, 'download failed')
        end
    end
    if i % 5 == 0 then task.wait() end
end

-- No second pass: failed modules are skipped to prevent hanging

-- Finalize
BarFill.Size = UDim2.new(1, 0, 1, 0)
BarGlow.Size = UDim2.new(1, 0, 1, 0)
PctLabel.Text = '100%'
StatusLabel.Text = 'Done!'
task.wait(0.3)

local elapsed = math.floor((tick() - t0) * 1000)
ResultLabel.Text = '[OK] ' .. ok .. '  [FAIL] ' .. fail .. '  ' .. elapsed .. 'ms (' .. dlTime .. 'ms dl)'
ResultLabel.TextColor3 = fail == 0 and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(255, 200, 50)
ResultLabel.TextSize = 13
ResultLabel.Font = Enum.Font.GothamBold

logCount = logCount + 1
local sumLbl = Instance.new("TextLabel")
sumLbl.Size = UDim2.new(1, -5, 0, 16)
sumLbl.BackgroundTransparency = 1
sumLbl.Text = "  [OK] " .. ok .. " loaded  [FAIL] " .. fail .. " failed  " .. elapsed .. "ms"
sumLbl.TextColor3 = fail == 0 and Color3.fromRGB(80, 255, 150) or Color3.fromRGB(255, 200, 80)
sumLbl.TextSize = 12
sumLbl.Font = Enum.Font.GothamBold
sumLbl.LayoutOrder = logCount
sumLbl.Parent = LogFrame
LogFrame.CanvasSize = UDim2.new(0, 0, 0, logCount * 15)

task.wait(0.3)

-- Fade out
task.spawn(function()
    task.wait(1.5)
    if animConn then animConn:Disconnect() end
    local info = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tw1 = TweenService:Create(Panel, info, {Position = UDim2.new(0.5, -220, 0, -200), BackgroundTransparency = 1})
    local tw2 = TweenService:Create(Overlay, info, {BackgroundTransparency = 1})
    tw1:Play() tw2:Play()
    for _, child in ipairs(Panel:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            TweenService:Create(child, info, {TextTransparency = 1}):Play()
        elseif child:IsA("Frame") or child:IsA("ScrollingFrame") then
            TweenService:Create(child, info, {BackgroundTransparency = 1}):Play()
        elseif child:IsA("UIStroke") then
            TweenService:Create(child, info, {Transparency = 1}):Play()
        end
    end
    tw1.Completed:Wait()
    pcall(function() GUI:Destroy() end)
end)

print("[BloxStrike] v4.0 loaded (" .. ok .. "/" .. total .. " modules, " .. elapsed .. "ms)")
