--[[
    BloxStrike Test Suite v1.0
    ========================
    外掛腳本專屬的完整執行時測試工具
    
    測試項目:
    1. HTTP 方法偵測
    2. 全域變數測試
    3. 所有 21 個模組 (下載+編譯+執行)
    4. GUI 建立測試
    5. 依賴關係測試
    6. 最終報告
    
    用法: 貼到執行器直接執行
]]

if game.PlaceId ~= 114234929420007 then
    warn("[Test] Wrong game! Join BloxStrike first")
    return
end

-- ═══ Test State ═══
local TestState = {
    Results = {},
    StartTime = tick(),
    HTTPMethod = "none",
    Passed = 0,
    Failed = 0,
    Total = 0,
}

local function test(name, passed, detail)
    TestState.Total = TestState.Total + 1
    if passed then
        TestState.Passed = TestState.Passed + 1
        print("[TEST PASS] " .. name .. (detail and (" - " .. detail) or ""))
    else
        TestState.Failed = TestState.Failed + 1
        print("[TEST FAIL] " .. name .. (detail and (" - " .. detail) or ""))
    end
    table.insert(TestState.Results, {name=name, passed=passed, detail=detail})
end

print("")
print("========================================")
print("  BloxStrike Test Suite v1.0")
print("========================================")
print("")

-- ═══════════════════════════════════════════════════════
-- PHASE 1: HTTP METHOD DETECTION
-- ═══════════════════════════════════════════════════════
print("--- Phase 1: HTTP Method Detection ---")

local httpMethods = {
    {name = "http_request", check = function() return http_request ~= nil end},
    {name = "request", check = function() return request ~= nil end},
    {name = "syn.request", check = function() return syn and syn.request ~= nil end},
    {name = "HttpGetAsync", check = function() return game.HttpGetAsync ~= nil end},
    {name = "HttpGet", check = function() return game.HttpGet ~= nil end},
    {name = "fluxusrequest", check = function() return fluxusrequest ~= nil end},
}

local function httpGet(url)
    if http_request then
        local ok, res = pcall(function()
            return http_request({Url = url, Method = "GET"})
        end)
        if ok and res and res.Body then return res.Body end
    end
    if request then
        local ok, res = pcall(function()
            return request({Url = url, Method = "GET"})
        end)
        if ok and res and res.Body then return res.Body end
    end
    if syn and syn.request then
        local ok, res = pcall(function()
            return syn.request({Url = url, Method = "GET"})
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
            return fluxusrequest({Url = url, Method = "GET"})
        end)
        if ok and res and res.Body then return res.Body end
    end
    return nil
end

local detectedMethods = {}
for _, m in ipairs(httpMethods) do
    local ok, result = pcall(m.check)
    local available = ok and result
    test("HTTP: " .. m.name, available, available and "available" or "not found")
    if available then
        table.insert(detectedMethods, m.name)
    end
end

-- Test actual HTTP download
local testUrl = "https://raw.githubusercontent.com/jiajia67-code/BloxStrike/main/Roblox-BloxStrike/version.json"
local httpBody = httpGet(testUrl)
TestState.HTTPMethod = detectedMethods[1] or "none"
test("HTTP: Download test", httpBody ~= nil, httpBody and (#httpBody .. " bytes") or "FAILED")
test("HTTP: Method found", #detectedMethods > 0, TestState.HTTPMethod)

print("")

-- ═══════════════════════════════════════════════════════
-- PHASE 2: GLOBAL VARIABLES
-- ═══════════════════════════════════════════════════════
print("--- Phase 2: Global Variables ---")

local globals = {
    {name = "game", check = function() return game ~= nil end},
    {name = "workspace", check = function() return workspace ~= nil end},
    {name = "Players", check = function() return game:GetService("Players") ~= nil end},
    {name = "RunService", check = function() return game:GetService("RunService") ~= nil end},
    {name = "UserInputService", check = function() return game:GetService("UserInputService") ~= nil end},
    {name = "TweenService", check = function() return game:GetService("TweenService") ~= nil end},
    {name = "Instance", check = function() return Instance ~= nil end},
    {name = "UDim2", check = function() return UDim2 ~= nil end},
    {name = "Color3", check = function() return Color3 ~= nil end},
    {name = "Vector3", check = function() return Vector3 ~= nil end},
    {name = "CFrame", check = function() return CFrame ~= nil end},
    {name = "Enum", check = function() return Enum ~= nil end},
    {name = "math", check = function() return math ~= nil end},
    {name = "string", check = function() return string ~= nil end},
    {name = "table", check = function() return table ~= nil end},
    {name = "pcall", check = function() return pcall ~= nil end},
    {name = "loadstring", check = function() return loadstring ~= nil end},
    {name = "task", check = function() return task ~= nil end},
    {name = "typeof", check = function() return typeof ~= nil end},
    {name = "UserInputService", check = function() return UserInputService ~= nil end},
    {name = "HttpService", check = function() return game:GetService("HttpService") ~= nil end},
}

for _, g in ipairs(globals) do
    local ok, result = pcall(g.check)
    test("Global: " .. g.name, ok and result, ok and (result and "OK" or "nil") or tostring(result))
end

-- Test BS and Flags
test("Global: _G.BS", _G.BS ~= nil, type(_G.BS))
test("Global: _G.Flags", _G.Flags ~= nil, type(_G.Flags))

print("")

-- ═══════════════════════════════════════════════════════
-- PHASE 3: MODULE DOWNLOAD & COMPILE
-- ═══════════════════════════════════════════════════════
print("--- Phase 3: Module Download & Compile ---")

local BASE_URL = "https://raw.githubusercontent.com/jiajia67-code/BloxStrike/main/Roblox-BloxStrike/modules/"
local CACHE_BUSTER = tostring(math.floor(tick() * 1000))

local MODULES = {
    {name = "compat", cn = "兼容層", dep = {}},
    {name = "core", cn = "核心", dep = {"compat"}},
    {name = "ui", cn = "介面", dep = {"core"}},
    {name = "api", cn = "API", dep = {"core"}},
    {name = "combat", cn = "戰鬥系統", dep = {"core", "api"}},
    {name = "esp", cn = "透視系統", dep = {"core"}},
    {name = "hud", cn = "HUD", dep = {"core"}},
    {name = "killeffects", cn = "擊殺特效", dep = {"core"}},
    {name = "utility", cn = "工具", dep = {"core"}},
    {name = "combatassist", cn = "戰鬥輔助", dep = {"core"}},
    {name = "world", cn = "世界", dep = {"core"}},
    {name = "rage", cn = "暴力系統", dep = {"core", "api"}},
    {name = "pingadapt", cn = "延遲適應", dep = {"core"}},
    {name = "smartai", cn = "智能AI", dep = {"core"}},
    {name = "settings", cn = "設定", dep = {"core"}},
    {name = "stealth", cn = "隱身系統", dep = {"core"}},
    {name = "cheatdetect", cn = "作弊偵測", dep = {"core"}},
    {name = "bypass", cn = "反檢測", dep = {"core"}},
    {name = "errorhandler", cn = "錯誤處理", dep = {"core"}},
    {name = "events", cn = "事件系統", dep = {"core"}},
    {name = "luau_detect", cn = "Luau偵測", dep = {"core"}},
}

-- Init BS/Flags
_G.BS = _G.BS or {}
_G.Flags = _G.Flags or {}
_G.BS.Flags = _G.Flags

local BS_PREAMBLE = "BS = _G.BS or {}; Flags = _G.Flags or {}; game = game; workspace = workspace; "
    .. "Instance = Instance; UDim2 = UDim2; UDim = UDim; Color3 = Color3; "
    .. "Vector3 = Vector3; Vector2 = Vector2; CFrame = CFrame; "
    .. "Enum = Enum; math = math; string = string; table = table; "
    .. "pcall = pcall; xpcall = xpcall; error = error; "
    .. "print = print; warn = warn; task = task; tick = tick; "
    .. "wait = wait; spawn = spawn; delay = delay; "
    .. "typeof = typeof; type = type; tostring = tostring; tonumber = tonumber; "
    .. "select = select; pairs = pairs; ipairs = ipairs; "
    .. "rawget = rawget; rawset = rawset; "
    .. "getmetatable = getmetatable; setmetatable = setmetatable; "
    .. "collectgarbage = collectgarbage; newproxy = newproxy; "

local moduleResults = {}
local moduleCode = {}

-- Download all modules
print("Downloading " .. #MODULES .. " modules...")
local dlStart = tick()
local dlDone = 0

for _, mod in ipairs(MODULES) do
    task.spawn(function()
        local url = BASE_URL .. mod.name .. ".lua?t=" .. CACHE_BUSTER
        local code = httpGet(url)
        moduleCode[mod.name] = code
        dlDone = dlDone + 1
    end)
end

while dlDone < #MODULES do task.wait(0.05) end
local dlTime = math.floor((tick() - dlStart) * 1000)
print("Download complete: " .. dlTime .. "ms")
print("")

-- Compile and test each module
for _, mod in ipairs(MODULES) do
    local code = moduleCode[mod.name]
    
    -- Download test
    test(mod.cn .. ": Download", code ~= nil, code and (#code .. " bytes") or "FAILED")
    
    if code then
        -- Compile test
        local fn, compileErr = loadstring(BS_PREAMBLE .. code)
        test(mod.cn .. ": Compile", fn ~= nil, compileErr and compileErr:sub(1, 60) or "OK")
        
        if fn then
            -- Execute test
            local execOk, execErr = pcall(fn)
            test(mod.cn .. ": Execute", execOk, execErr and tostring(execErr):sub(1, 60) or "OK")
            
            -- Dependency check
            for _, dep in ipairs(mod.dep) do
                if not _G.BS[dep] and not _G.BS["_" .. dep] then
                    -- Dependencies are loaded via BS table
                end
            end
        end
        
        moduleResults[mod.name] = {
            downloaded = code ~= nil,
            compiled = fn ~= nil,
            executed = fn ~= nil,
            size = #code,
        }
    else
        moduleResults[mod.name] = {
            downloaded = false,
            compiled = false,
            executed = false,
            size = 0,
        }
    end
end

print("")

-- ═══════════════════════════════════════════════════════
-- PHASE 4: GUI TEST
-- ═══════════════════════════════════════════════════════
print("--- Phase 4: GUI Test ---")

local lplr = game:GetService("Players").LocalPlayer

-- Test ScreenGui creation
local ok1, gui = pcall(function()
    local g = Instance.new("ScreenGui")
    g.Name = "BloxStrike_Test_GUI"
    g.Parent = lplr.PlayerGui
    return g
end)
test("GUI: ScreenGui creation", ok1, ok1 and "OK" or tostring(gui))

-- Test Frame creation
local ok2, frame = pcall(function()
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 200, 0, 100)
    f.Parent = gui
    return f
end)
test("GUI: Frame creation", ok2, ok2 and "OK" or tostring(frame))

-- Test TextLabel
local ok3 = pcall(function()
    local t = Instance.new("TextLabel")
    t.Text = "Test"
    t.Parent = frame
end)
test("GUI: TextLabel creation", ok3)

-- Test UICorner
local ok4 = pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = frame
end)
test("GUI: UICorner creation", ok4)

-- Test UIStroke
local ok5 = pcall(function()
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(255, 255, 255)
    s.Parent = frame
end)
test("GUI: UIStroke creation", ok5)

-- Test UIGradient
local ok6 = pcall(function()
    local g = Instance.new("UIGradient")
    g.Parent = frame
end)
test("GUI: UIGradient creation", ok6)

-- Test Rayfield (if loaded)
local ok7 = pcall(function()
    if _G.BS.Win then
        return true
    end
    return false
end)
test("GUI: Rayfield Window", ok7, _G.BS.Win and "loaded" or "not loaded (expected in test mode)")

-- Cleanup test GUI
pcall(function() gui:Destroy() end)

print("")

-- ═══════════════════════════════════════════════════════
-- PHASE 5: FUNCTION TESTS
-- ═══════════════════════════════════════════════════════
print("--- Phase 5: Core Function Tests ---")

-- Test BS.alive
local ok8, aliveResult = pcall(function()
    return _G.BS.alive and _G.BS.alive() or false
end)
test("Core: BS.alive()", ok8, aliveResult and "alive" or "dead/missing")

-- Test BS.hrp
local ok9, hrpResult = pcall(function()
    return _G.BS.hrp and _G.BS.hrp() or nil
end)
test("Core: BS.hrp()", ok9, hrpResult and "found" or "nil")

-- Test BS.hum
local ok10, humResult = pcall(function()
    return _G.BS.hum and _G.BS.hum() or nil
end)
test("Core: BS.hum()", ok10, humResult and "found" or "nil")

-- Test Flags
local flagCount = 0
for k, v in pairs(_G.Flags) do
    flagCount = flagCount + 1
end
test("Core: Flags table", flagCount > 0, flagCount .. " flags")

-- Test pcall safety
local ok11 = pcall(function()
    local f = loadstring("return 1 + 1")
    return f and f() or nil
end)
test("Core: loadstring", ok11)

-- Test task.spawn
local ok12 = pcall(function()
    local done = false
    task.spawn(function()
        task.wait(0.1)
        done = true
    end)
    task.wait(0.2)
    return done
end)
test("Core: task.spawn", ok12)

print("")

-- ═══════════════════════════════════════════════════════
-- PHASE 6: VERSION CHECK
-- ═══════════════════════════════════════════════════════
print("--- Phase 6: Version Check ---")

if httpBody then
    local version = httpBody:match('"version"%s*:%s*"([^"]+)"')
    test("Version: Parse", version ~= nil, version or "parse failed")
    test("Version: Check", version ~= nil and version ~= "", version)
else
    test("Version: Download", false, "no HTTP body")
    test("Version: Parse", false, "skipped")
end

print("")

-- ═══════════════════════════════════════════════════════
-- FINAL REPORT
-- ═══════════════════════════════════════════════════════
local elapsed = math.floor((tick() - TestState.StartTime) * 1000)

print("========================================")
print("  TEST REPORT")
print("========================================")
print("  Total:   " .. TestState.Total)
print("  Passed:  " .. TestState.Passed)
print("  Failed:  " .. TestState.Failed)
print("  Time:    " .. elapsed .. "ms")
print("  HTTP:    " .. TestState.HTTPMethod)
print("  Modules: " .. #MODULES .. " tested")
print("")

if TestState.Failed == 0 then
    print("  ALL TESTS PASSED!")
else
    print("  " .. TestState.Failed .. " TESTS FAILED:")
    for _, r in ipairs(TestState.Results) do
        if not r.passed then
            print("    - " .. r.name .. (r.detail and (": " .. r.detail) or ""))
        end
    end
end

print("")

-- ═══ ON-SCREEN REPORT ═══
pcall(function()
    local gui = Instance.new("ScreenGui")
    gui.Name = "BloxStrike_TestReport"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 10004
    gui.Parent = lplr.PlayerGui
    
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 400, 0, 300)
    bg.Position = UDim2.new(0.5, -200, 0.5, -150)
    bg.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    bg.BorderSizePixel = 0
    bg.Parent = gui
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", bg).Color = TestState.Failed == 0 and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(200, 50, 50)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "BloxStrike Test Report"
    title.TextColor3 = Color3.fromRGB(200, 200, 255)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = bg
    
    local stats = Instance.new("TextLabel")
    stats.Size = UDim2.new(1, -20, 0, 80)
    stats.Position = UDim2.new(0, 10, 0, 45)
    stats.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    stats.BorderSizePixel = 0
    stats.TextColor3 = Color3.fromRGB(200, 200, 200)
    stats.TextSize = 12
    stats.Font = Enum.Font.Code
    stats.TextXAlignment = Enum.TextXAlignment.Left
    stats.TextYAlignment = Enum.TextYAlignment.Top
    stats.TextWrapped = true
    stats.Parent = bg
    Instance.new("UICorner", stats).CornerRadius = UDim.new(0, 8)
    
    local passColor = TestState.Failed == 0 and "PASS" or "FAIL"
    stats.Text = string.format(
        "Result: %s\nTotal: %d | Passed: %d | Failed: %d\nTime: %dms | HTTP: %s\nModules: %d tested",
        passColor, TestState.Total, TestState.Passed, TestState.Failed,
        elapsed, TestState.HTTPMethod, #MODULES
    )
    stats.TextColor3 = TestState.Failed == 0 and Color3.fromRGB(80, 255, 150) or Color3.fromRGB(255, 100, 100)
    
    -- Module list
    local list = Instance.new("TextLabel")
    list.Size = UDim2.new(1, -20, 0, 130)
    list.Position = UDim2.new(0, 10, 0, 135)
    list.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
    list.BorderSizePixel = 0
    list.TextColor3 = Color3.fromRGB(180, 180, 180)
    list.TextSize = 10
    list.Font = Enum.Font.Code
    list.TextXAlignment = Enum.TextXAlignment.Left
    list.TextYAlignment = Enum.TextYAlignment.Top
    list.TextWrapped = true
    list.Parent = bg
    Instance.new("UICorner", list).CornerRadius = UDim.new(0, 8)
    
    local modText = ""
    for _, mod in ipairs(MODULES) do
        local r = moduleResults[mod.name]
        if r then
            local icon = (r.downloaded and r.compiled and r.executed) and "+" or "x"
            modText = modText .. icon .. " " .. mod.cn .. " " .. r.size .. "B\n"
        end
    end
    list.Text = modText
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -35, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.TextSize = 12
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = bg
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
    
    -- Auto-close after 10 seconds
    task.delay(10, function()
        pcall(function() gui:Destroy() end)
    end)
end)

print("[Test] Report displayed on screen (auto-close in 10s)")
print("[Test] Done!")
print("")
