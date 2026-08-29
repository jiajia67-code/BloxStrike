-- BLOXSTRIKE UI - Enhanced Rayfield Based v3.0
-- Features: Rayfield, Profiles, Quick Panel, Keybinds, Theme, Mobile Support

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
-- RAYFIELD LOADING
-- ═══════════════════════════════════════════════════════════════

local Rayfield = nil
local loadAttempts = 0
local maxAttempts = 3

local rayfieldURLs = {
    "https://sirius.menu/rayfield",
    "https://raw.githubusercontent.com/shlexware/Rayfield/main/source",
    "https://raw.githubusercontent.com/jensonhirst/Rayfield/main/source",
}

local function fetchUrl(url)
    if http_request then
        local ok, res = pcall(function() return http_request({Url=url, Method='GET'}) end)
        if ok and res and res.Body then return res.Body end
    end
    if request then
        local ok, res = pcall(function() return request({Url=url, Method='GET'}) end)
        if ok and res and res.Body then return res.Body end
    end
    local ok, res = pcall(function() return game:HttpGet(url, true) end)
    if ok and res and #res > 0 then return res end
    return nil
end

while not Rayfield and loadAttempts < maxAttempts do
    loadAttempts = loadAttempts + 1
    for _, url in ipairs(rayfieldURLs) do
        pcall(function()
            local src = fetchUrl(url)
            if src and #src > 0 then
                Rayfield = loadstring(src)()
            end
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
-- NOTIFICATION SYSTEM
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
-- THEME SYSTEM
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
-- CREATE WINDOW
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
-- COMPATIBILITY LAYER
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
-- CONFIG SYSTEM
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
-- PROFILE SYSTEM
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
-- QUICK ACCESS PANEL (Bottom of screen)
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
-- WATERMARK
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
-- KEYBIND SYSTEM
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
-- PRESET PROFILES
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
-- QUICK KEYBINDS
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
-- MAIN UPDATE LOOP
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

-- Auto-save on disconnect
lplr.CharacterRemoving:Connect(function()
    pcall(function() BS.Config.Save() end)
end)

-- ═══════════════════════════════════════════════════════════════
-- LOADING COMPLETE
-- ═══════════════════════════════════════════════════════════════

print("[UI] BloxStrike UI v3.0 loaded (Rayfield)")
print("[UI] INSERT: Menu | X: ESP | Z: Bhop | C: AA | V: SA | N: Night | M: NoScope")
