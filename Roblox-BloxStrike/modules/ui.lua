-- BLOXSTRIKE UI - LinoriaLib Based v4.0
-- Features: LinoriaLib, Profiles, Quick Panel, Keybinds, Theme

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
local lplr = Players and Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════
-- LINORIALIB LOADING
-- ═══════════════════════════════════════════════════════════════

local Library = nil
local LINORIA_URLS = {
    "https://cdn.jsdelivr.net/gh/violin-suzutsuki/LinoriaLib@main/Library.lua",
    "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua",
}

local function fetchUrl(url)
    local ok, res = pcall(function() return game:HttpGet(url, true) end)
    if ok and res and #res > 0 then return res end
    return nil
end

local rayfieldStart = tick()
local LOAD_TIMEOUT = 15

for _, url in ipairs(LINORIA_URLS) do
    if (tick() - rayfieldStart) > LOAD_TIMEOUT then break end
    pcall(function()
        local src = fetchUrl(url)
        if src and #src > 0 then
            Library = loadstring(src)()
        end
    end)
    if Library then break end
end

if not Library then
    warn("[UI] CRITICAL: Could not load LinoriaLib!")
    -- Stub fallback
    local stubPage = {
        Toggle = function(self, n, d, c) pcall(function() Flags[n] = d end) end,
        Slider = function(self, n, mn, mx, d, c) pcall(function() Flags[n] = d end) end,
        Dropdown = function(self, c) pcall(function() if c and c.Options then Flags[c.Name or 'dropdown'] = c.Options[1] end end) end,
        Button = function(self, c, cb) end,
        Label = function(self, t) print('[BS] ' .. tostring(t)) end,
        Separator = function(self) end,
    }
    BS.Win = {
        Tab = function(self, name)
            return setmetatable({}, {__index = stubPage})
        end
    }
    BS.Notify = function(t, d) print('[BS] ' .. tostring(t) .. ': ' .. tostring(d)) end
    return
end

print("[UI] LinoriaLib loaded successfully")

-- ═══════════════════════════════════════════════════════════════
-- CREATE WINDOW
-- ═══════════════════════════════════════════════════════════════

local Window = Library:CreateWindow({
    Title = "BloxStrike v4.1",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2,
})

-- ═══════════════════════════════════════════════════════════════
-- NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════════════════════════

function BS.Notify(title, text, duration)
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
-- COMPATIBILITY WRAPPER (maps LinoriaLib to our BS.Win:Tab API)
-- ═══════════════════════════════════════════════════════════════

local tabCache = {}

local function wrapGroup(group)
    local page = {}
    
    page.Toggle = function(self, name, default, callback)
        group:AddToggle(name, {
            Text = name,
            Default = default or false,
            Callback = function(value) pcall(function() if callback then callback(value) end end) end,
        })
    end
    
    page.Slider = function(self, name, min, max, default, callback)
        group:AddSlider(name, {
            Text = name,
            Default = default or min,
            Min = min,
            Max = max,
            Rounding = 0,
            Callback = function(value) pcall(function() if callback then callback(value) end end) end,
        })
    end
    
    page.Dropdown = function(self, config)
        group:AddDropdown(config.Name or "dropdown", {
            Text = config.Name or "Dropdown",
            Values = config.Options or {},
            Default = config.Default or config.Options[1] or "",
            Callback = function(value) end,
        })
    end
    
    page.Button = function(self, config, callback)
        group:AddButton({
            Text = config.Name or "Button",
            Func = function() pcall(function() if callback then callback() end end) end,
        })
    end
    
    page.Label = function(self, text)
        group:AddLabel(text)
    end
    
    page.Separator = function(self)
        group:AddDivider()
    end
    
    return page
end

BS.Win = {
    Tab = function(self, tabName)
        if tabCache[tabName] then
            return tabCache[tabName]
        end
        
        local tab = Window:AddTab(tabName)
        local group = tab:AddLeftGroupbox(tabName)
        local page = wrapGroup(group)
        tabCache[tabName] = page
        return page
    end
}

-- ═══════════════════════════════════════════════════════════════
-- KEYBIND SYSTEM
-- ═══════════════════════════════════════════════════════════════

local keybindCallbacks = {}

function BS.BindKey(key, callback)
    keybindCallbacks[key] = callback
end

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if keybindCallbacks[input.KeyCode] then
        pcall(function() keybindCallbacks[input.KeyCode]() end)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- QUICK KEYBINDS
-- ═══════════════════════════════════════════════════════════════

BS.BindKey(Enum.KeyCode.X, function()
    Flags.ESP_Box = not Flags.ESP_Box
    Flags.ESP_Name = Flags.ESP_Box
    Flags.ESP_Health = Flags.ESP_Box
    BS.FeatureNotify("透視", Flags.ESP_Box)
end)

BS.BindKey(Enum.KeyCode.Z, function()
    Flags.Bhop = not Flags.Bhop
    BS.FeatureNotify("連跳", Flags.Bhop)
end)

BS.BindKey(Enum.KeyCode.C, function()
    Flags.AA = not Flags.AA
    BS.FeatureNotify("反瞄準", Flags.AA)
end)

BS.BindKey(Enum.KeyCode.V, function()
    Flags.SilentAim = not Flags.SilentAim
    BS.FeatureNotify("靜默瞄準", Flags.SilentAim)
end)

BS.BindKey(Enum.KeyCode.N, function()
    Flags.NightMode = not Flags.NightMode
    BS.FeatureNotify("夜視模式", Flags.NightMode)
end)

-- ═══════════════════════════════════════════════════════════════
-- WATERMARK
-- ═══════════════════════════════════════════════════════════════

local WatermarkObj = nil
task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            if not WatermarkObj then
                WatermarkObj = Drawing.new("Text")
                WatermarkObj.Center = false
                WatermarkObj.Outline = true
                WatermarkObj.Font = 2
                WatermarkObj.Size = 14
            end
            local ping = 0
            pcall(function() ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"].Value) end)
            local players = #Players:GetPlayers()
            WatermarkObj.Text = "  BloxStrike v4.0 | " .. ping .. " ms | " .. players .. " P | " .. os.date("%H:%M:%S") .. "  "
            WatermarkObj.Position = Vector2.new(10, 10)
            WatermarkObj.Color = Color3.new(1,1,1)
            WatermarkObj.Visible = true
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- LOADING COMPLETE
-- ═══════════════════════════════════════════════════════════════

print("[UI] BloxStrike UI v4.1 loaded (LinoriaLib)")
