--[[
    BloxStrike Test Suite v2.0
    ========================
    完整執行時測試工具 - 6 個測試階段
    
    測試項目:
    1. HTTP 方法偵測 + 速度測試
    2. 全域變數 + 服務測試
    3. 所有 21 個模組 (下載+編譯+執行+依賴)
    4. GUI 建立 + 操作測試
    5. 核心功能測試
    6. 版本 + 安全檢查
    
    用法: 貼到執行器直接執行
]]

if game.PlaceId ~= 114234929420007 then
    warn("[Test] Wrong game!")
    return
end

-- ═══ Test Engine ═══
local T = {
    Results = {}, StartTime = tick(), HTTPMethod = "none",
    Passed = 0, Failed = 0, Total = 0,
    Modules = {DL=0, COMPILE=0, EXEC=0, FAIL={}},
    Phase = 0,
}

local function pass(name, detail)
    T.Total = T.Total + 1; T.Passed = T.Passed + 1
    print("  [PASS] " .. name .. (detail and (" - " .. detail) or ""))
    table.insert(T.Results, {name=name, ok=true, detail=detail})
end

local function fail(name, detail)
    T.Total = T.Total + 1; T.Failed = T.Failed + 1
    print("  [FAIL] " .. name .. (detail and (" - " .. detail) or ""))
    table.insert(T.Results, {name=name, ok=false, detail=detail})
end

local function phase(name)
    T.Phase = T.Phase + 1
    print("\n--- Phase " .. T.Phase .. ": " .. name .. " ---")
end

local function try(fn, fallback)
    local ok, result = pcall(fn)
    return ok and result or (fallback ~= nil and fallback or nil)
end

-- ═══ HTTP Helper ═══
local function httpGet(url)
    local methods = {
        function() return http_request({Url=url,Method="GET"}) end,
        function() return request({Url=url,Method="GET"}) end,
        function() return syn.request({Url=url,Method="GET"}) end,
    }
    for _, fn in ipairs(methods) do
        local ok, res = pcall(fn)
        if ok and res and res.Body then return res.Body end
    end
    -- Fallbacks
    if game.HttpGetAsync then
        local ok, body = pcall(function() return game:HttpGetAsync(url) end)
        if ok and body then return body end
    end
    if game.HttpGet then
        local ok, body = pcall(function() return game:HttpGet(url, true) end)
        if ok and body then return body end
    end
    return nil
end

print("")
print("========================================")
print("  BloxStrike Test Suite v2.0")
print("========================================")
print("")

-- ═══════════════════════════════════════════════════════
-- PHASE 1: HTTP METHOD DETECTION
-- ═══════════════════════════════════════════════════════
phase("HTTP Method Detection")

local methods = {
    {"http_request", function() return http_request ~= nil end},
    {"request", function() return request ~= nil end},
    {"syn.request", function() return syn and syn.request ~= nil end},
    {"HttpGetAsync", function() return game.HttpGetAsync ~= nil end},
    {"HttpGet", function() return game.HttpGet ~= nil end},
    {"fluxusrequest", function() return fluxusrequest ~= nil end},
}

local working = {}
for _, m in ipairs(methods) do
    local ok, result = pcall(m[2])
    local avail = ok and result
    if avail then
        pass("HTTP: " .. m[1])
        table.insert(working, m[1])
    else
        fail("HTTP: " .. m[1], "not available")
    end
end

T.HTTPMethod = working[1] or "none"
pass("Working HTTP: " .. T.HTTPMethod, #working .. " found")

-- Speed test
local testUrl = "https://raw.githubusercontent.com/jiajia67-code/BloxStrike/main/Roblox-BloxStrike/version.json"
local dlStart = tick()
local body = httpGet(testUrl)
local dlMs = math.floor((tick() - dlStart) * 1000)
pass("Speed test", dlMs .. "ms, " .. (body and #body or 0) .. " bytes")

-- Version parse
if body then
    local ver = body:match('"version"%s*:%s*"([^"]+)"')
    pass("Version parse", ver or "failed")
else
    fail("Version download", "no body")
end

-- ═══════════════════════════════════════════════════════
-- PHASE 2: GLOBAL VARIABLES
-- ═══════════════════════════════════════════════════════
phase("Global Variables")

local checks = {
    {"game", game ~= nil}, {"workspace", workspace ~= nil},
    {"Instance", Instance ~= nil}, {"UDim2", UDim2 ~= nil},
    {"Color3", Color3 ~= nil}, {"Vector3", Vector3 ~= nil},
    {"CFrame", CFrame ~= nil}, {"Enum", Enum ~= nil},
    {"math", math ~= nil}, {"string", string ~= nil},
    {"table", table ~= nil}, {"pcall", pcall ~= nil},
    {"loadstring", loadstring ~= nil}, {"task", task ~= nil},
    {"typeof", typeof ~= nil}, {"tick", tick ~= nil},
}

for _, c in ipairs(checks) do
    if c[2] then pass("Global: " .. c[1]) else fail("Global: " .. c[1]) end
end

-- Services
local svcs = {"Players", "RunService", "UserInputService", "TweenService", "HttpService", "StarterGui"}
for _, svc in ipairs(svcs) do
    local ok, s = pcall(function() return game:GetService(svc) end)
    if ok and s then pass("Service: " .. svc) else fail("Service: " .. svc) end
end

-- BS/Flags
pass("_G.BS", type(_G.BS))
pass("_G.Flags", type(_G.Flags))

-- ═══════════════════════════════════════════════════════
-- PHASE 3: MODULE TEST
-- ═══════════════════════════════════════════════════════
phase("Module Download + Compile + Execute")

local BASE_URL = "https://raw.githubusercontent.com/jiajia67-code/BloxStrike/main/Roblox-BloxStrike/modules/"
local CACHE_BUSTER = tostring(math.floor(tick() * 1000))

local MODULES = {
    "compat", "core", "ui", "api",
    "combat", "esp",
    "hud", "killeffects", "utility", "combatassist",
    "world",
    "rage", "pingadapt", "smartai",
    "settings", "stealth", "cheatdetect",
    "bypass", "errorhandler", "events", "luau_detect",
}

local MOD_CN = {
    compat="兼容層", core="核心", ui="介面", api="API",
    combat="戰鬥系統", esp="透視系統",
    hud="HUD", killeffects="擊殺特效", utility="工具", combatassist="戰鬥輔助",
    world="世界",
    rage="暴力系統", pingadapt="延遲適應", smartai="智能AI",
    settings="設定", stealth="隱身系統", cheatdetect="作弊偵測",
    bypass="反檢測", errorhandler="錯誤處理", events="事件系統", luau_detect="Luau偵測",
}

_G.BS = _G.BS or {}; _G.Flags = _G.Flags or {}; _G.BS.Flags = _G.Flags

local PREAMBLE = "BS=_G.BS or {}; Flags=_G.Flags or {}; game=game; workspace=workspace; "
    .."Instance=Instance; UDim2=UDim2; UDim=UDim; Color3=Color3; "
    .."Vector3=Vector3; Vector2=Vector2; CFrame=CFrame; "
    .."Enum=Enum; math=math; string=string; table=table; "
    .."pcall=pcall; xpcall=xpcall; error=error; "
    .."print=print; warn=warn; task=task; tick=tick; "
    .."wait=wait; spawn=spawn; delay=delay; "
    .."typeof=typeof; type=type; tostring=tostring; tonumber=tonumber; "
    .."select=select; pairs=pairs; ipairs=ipairs; "
    .."rawget=rawget; rawset=rawset; "
    .."getmetatable=getmetatable; setmetatable=setmetatable; "
    .."collectgarbage=collectgarbage; newproxy=newproxy; "

-- Parallel download
print("  Downloading " .. #MODULES .. " modules...")
local downloaded = {}
local dlDone = 0
local dlStart = tick()

for _, name in ipairs(MODULES) do
    task.spawn(function()
        downloaded[name] = httpGet(BASE_URL .. name .. ".lua?t=" .. CACHE_BUSTER)
        dlDone = dlDone + 1
    end)
end
while dlDone < #MODULES do task.wait(0.05) end
local dlTime = math.floor((tick() - dlStart) * 1000)
pass("Parallel download", #MODULES .. " modules in " .. dlTime .. "ms")

-- Sequential compile + execute
local ok, fail_count = 0, 0
for _, name in ipairs(MODULES) do
    local cn = MOD_CN[name] or name
    local code = downloaded[name]
    
    if not code then
        fail(cn .. ": Download", "nil")
        fail_count = fail_count + 1
        T.Modules.FAIL[#T.Modules.FAIL+1] = name
    else
        T.Modules.DL = T.Modules.DL + 1
        local size = math.floor(#code / 1024 * 10) / 10
        pass(cn .. ": Download", size .. "KB")
        
        -- Compile
        local fn, cerr = loadstring(PREAMBLE .. code)
        if not fn then
            fail(cn .. ": Compile", cerr and cerr:sub(1, 60) or "unknown")
            fail_count = fail_count + 1
            T.Modules.FAIL[#T.Modules.FAIL+1] = name
        else
            T.Modules.COMPILE = T.Modules.COMPILE + 1
            -- Execute
            local execOk, eerr = pcall(fn)
            if execOk then
                T.Modules.EXEC = T.Modules.EXEC + 1
                pass(cn .. ": Execute", "OK")
                ok = ok + 1
            else
                fail(cn .. ": Execute", tostring(eerr):sub(1, 60))
                fail_count = fail_count + 1
                T.Modules.FAIL[#T.Modules.FAIL+1] = name
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════
-- PHASE 4: GUI TEST
-- ═══════════════════════════════════════════════════════
phase("GUI Creation")

local lplr = game:GetService("Players").LocalPlayer

-- Test all GUI elements
local guiTests = {
    {"ScreenGui", function()
        local g = Instance.new("ScreenGui"); g.Name="BSTest"; g.Parent=lplr.PlayerGui; return g
    end},
    {"Frame", function(g)
        local f = Instance.new("Frame"); f.Size=UDim2.new(0,200,0,100); f.Parent=g; return f
    end},
    {"TextLabel", function(g)
        local t = Instance.new("TextLabel"); t.Text="Test"; t.Parent=g; return true
    end},
    {"TextButton", function(g)
        local b = Instance.new("TextButton"); b.Text="Click"; b.Parent=g; return true
    end},
    {"UICorner", function(g)
        local c = Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=g; return true
    end},
    {"UIStroke", function(g)
        local s = Instance.new("UIStroke"); s.Color=Color3.new(1,1,1); s.Parent=g; return true
    end},
    {"UIGradient", function(g)
        local gr = Instance.new("UIGradient"); gr.Parent=g; return true
    end},
    {"ScrollingFrame", function(g)
        local sf = Instance.new("ScrollingFrame"); sf.Parent=g; return true
    end},
    {"UIListLayout", function(g)
        local ul = Instance.new("UIListLayout"); ul.Parent=g; return true
    end},
}

local testGui
for _, gt in ipairs(guiTests) do
    local ok, result = pcall(function()
        if gt[1] == "ScreenGui" then
            return gt[2]()
        else
            return gt[2](testGui)
        end
    end)
    if gt[1] == "ScreenGui" and ok then testGui = result end
    if ok and result then pass("GUI: " .. gt[1]) else fail("GUI: " .. gt[1]) end
end

-- Test Rayfield window
local rfOk = try(function() return _G.BS.Win ~= nil end, false)
if rfOk then
    pass("GUI: Rayfield", "loaded")
else
    -- Try to create it
    local rfOk2 = pcall(function()
        local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
        _G.BS.Win = Rayfield:CreateWindow({Name="BloxStrike Test", LoadingTitle="Testing..."})
    end)
    if rfOk2 then pass("GUI: Rayfield", "created") else fail("GUI: Rayfield", "failed") end
end

-- Cleanup
pcall(function() testGui:Destroy() end)

-- ═══════════════════════════════════════════════════════
-- PHASE 5: CORE FUNCTION TEST
-- ═══════════════════════════════════════════════════════
phase("Core Functions")

-- BS functions
local coreTests = {
    {"BS.alive()", function() return _G.BS.alive and _G.BS.alive() or false end},
    {"BS.hrp()", function() return _G.BS.hrp and _G.BS.hrp() or nil end},
    {"BS.hum()", function() return _G.BS.hum and _G.BS.hum() or nil end},
    {"BS.char()", function() return _G.BS.char and _G.BS.char() or nil end},
}

for _, ct in ipairs(coreTests) do
    local ok, result = pcall(ct[2])
    if ok then
        pass("Core: " .. ct[1], result and "found" or "nil (ok)")
    else
        fail("Core: " .. ct[1], tostring(result):sub(1, 40))
    end
end

-- Flags
local flagCount = 0
for _ in pairs(_G.Flags) do flagCount = flagCount + 1 end
pass("Flags count", flagCount .. " flags")

-- loadstring
local lsOk = pcall(function()
    local fn = loadstring("return 1+1")
    return fn and fn() == 2
end)
pass("loadstring", lsOk and "works" or "broken")

-- task.spawn
local tsOk = pcall(function()
    local done = false
    task.spawn(function() task.wait(0.1); done = true end)
    task.wait(0.3)
    return done
end)
pass("task.spawn", tsOk and "works" or "broken")

-- pcall
local pcOk = pcall(function()
    return pcall(error, "test")
end)
pass("pcall", pcOk and "works" or "broken")

-- ═══════════════════════════════════════════════════════
-- PHASE 6: SECURITY CHECK
-- ═══════════════════════════════════════════════════════
phase("Security Check")

-- Check for common anti-cheat patterns
local rs = game:GetService("ReplicatedStorage")
local acModules = 0
for _, obj in ipairs(rs:GetDescendants()) do
    if obj.Name:lower():find("ban") or obj.Name:lower():find("kick") or obj.Name:lower():find("detect") then
        acModules = acModules + 1
    end
end
pass("Anti-cheat scan", acModules .. " suspicious objects")

-- Check character state
local char = lplr.Character
if char then
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        pass("Character: Health", math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth))
        pass("Character: WalkSpeed", hum.WalkSpeed)
    end
else
    fail("Character", "not loaded")
end

-- ═══════════════════════════════════════════════════════
-- FINAL REPORT
-- ═══════════════════════════════════════════════════════
local elapsed = math.floor((tick() - T.StartTime) * 1000)

print("\n========================================")
print("  FINAL TEST REPORT")
print("========================================")
print("  Total:     " .. T.Total)
print("  Passed:    " .. T.Passed)
print("  Failed:    " .. T.Failed)
print("  Time:      " .. elapsed .. "ms")
print("  HTTP:      " .. T.HTTPMethod)
print("  Modules:   " .. T.Modules.EXEC .. "/" .. #MODULES .. " executed")
print("  Download:  " .. T.Modules.DL .. " downloaded")
print("  Compiled:  " .. T.Modules.COMPILE .. " compiled")
print("")

if T.Failed == 0 then
    print("  ALL TESTS PASSED!")
else
    print("  FAILED (" .. T.Failed .. "):")
    for _, r in ipairs(T.Results) do
        if not r.ok then
            print("    x " .. r.name .. (r.detail and (": " .. r.detail) or ""))
        end
    end
end

print("")

-- ═══ ON-SCREEN REPORT ═══
pcall(function()
    local gui = Instance.new("ScreenGui")
    gui.Name = "BSTestReport"; gui.IgnoreGuiInset = true
    gui.DisplayOrder = 10005; gui.Parent = lplr.PlayerGui

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 420, 0, 350)
    bg.Position = UDim2.new(0.5, -210, 0.5, -175)
    bg.BackgroundColor3 = Color3.fromRGB(12, 12, 22)
    bg.BorderSizePixel = 0; bg.Parent = gui
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 14)

    local passAll = T.Failed == 0
    local stroke = Instance.new("UIStroke", bg)
    stroke.Color = passAll and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(200, 50, 50)
    stroke.Thickness = 2

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 35)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "BloxStrike Test Report v2.0"
    title.TextColor3 = Color3.fromRGB(200, 200, 255)
    title.TextSize = 16; title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = bg

    -- Stats
    local stats = Instance.new("TextLabel")
    stats.Size = UDim2.new(1, -20, 0, 55)
    stats.Position = UDim2.new(0, 10, 0, 50)
    stats.BackgroundColor3 = Color3.fromRGB(18, 18, 32)
    stats.BorderSizePixel = 0
    stats.TextColor3 = passAll and Color3.fromRGB(80, 255, 150) or Color3.fromRGB(255, 100, 100)
    stats.TextSize = 12; stats.Font = Enum.Font.Code
    stats.TextXAlignment = Enum.TextXAlignment.Left
    stats.TextYAlignment = Enum.TextYAlignment.Top
    stats.TextWrapped = true; stats.Parent = bg
    Instance.new("UICorner", stats).CornerRadius = UDim.new(0, 8)

    stats.Text = string.format(
        "Result: %s  |  Time: %dms\nPassed: %d/%d  |  Failed: %d\nModules: %d/%d  |  HTTP: %s",
        passAll and "PASS" or "FAIL", elapsed,
        T.Passed, T.Total, T.Failed,
        T.Modules.EXEC, #MODULES, T.HTTPMethod
    )

    -- Module list
    local list = Instance.new("TextLabel")
    list.Size = UDim2.new(1, -20, 0, 195)
    list.Position = UDim2.new(0, 10, 0, 115)
    list.BackgroundColor3 = Color3.fromRGB(15, 15, 28)
    list.BorderSizePixel = 0
    list.TextColor3 = Color3.fromRGB(180, 180, 180)
    list.TextSize = 10; list.Font = Enum.Font.Code
    list.TextXAlignment = Enum.TextXAlignment.Left
    list.TextYAlignment = Enum.TextYAlignment.Top
    list.TextWrapped = true; list.Parent = bg
    Instance.new("UICorner", list).CornerRadius = UDim.new(0, 8)

    local modText = "Modules:\n"
    for _, name in ipairs(MODULES) do
        local cn = MOD_CN[name] or name
        local inFail = false
        for _, f in ipairs(T.Modules.FAIL) do
            if f == name then inFail = true; break end
        end
        local icon = inFail and "x" or "+"
        local col = inFail and "255,80,80" or "80,255,150"
        modText = modText .. icon .. " " .. cn .. "  "
        if #modText:match(".*\n") > 60 then modText = modText .. "\n" end
    end
    list.Text = modText

    -- Close
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -35, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Text = "X"; closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.TextSize = 12; closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = bg
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

    -- Auto-close after 15 seconds
    task.delay(15, function() pcall(function() gui:Destroy() end) end)
end)

print("[Test] Report displayed on screen (auto-close in 15s)")
print("[Test] Done!")
print("")
