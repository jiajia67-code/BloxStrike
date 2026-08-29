

-- BLOXSTRIKE SETTINGS MODULE v1.0
-- Save/Load settings with writefile/readfile

local Players = nil

pcall(function() Players = game:GetService("Players") end)
local lplr = Players.LocalPlayer

local SETTINGS_FILE = "BloxStrike_Settings.json"
local SETTINGS_DIR = "BloxStrike/"

-- Use compat layer for file operations
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

-- SETTINGS GUI
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

 -- Preset Configs
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

 -- Save Settings
local function saveSettings(presetName)
    pcall(function()
        local settings = {}
        for key, value in pairs(Flags) do
            -- Only save non-table, non-function values
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

 -- Load Settings
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
                -- Text = string.format("Loaded %d settings (Preset: %s)", count, settings["_preset"] or "Custom"),
                Duration = 3,
            })
        end)
        print("[Settings] Loaded " .. tostring(count) .. " settings")
        return true
    end)
    return false
end

 -- Load Preset
local function loadPreset(name)
    local preset = Presets[name]
    if not preset then
        warn("[Settings] Preset '" .. name .. "' not found!")
        -- return
    end

    -- Reset all flags first
    for k, _ in pairs(Flags) do
        Flags[k] = false
    end

    -- Apply preset
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

 -- Reset Settings
local function resetSettings()
    for k, _ in pairs(Flags) do
        Flags[k] = false
    end
    -- Restore some defaults
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

 -- Export Settings (String)
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

 -- Import Settings (String)
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

 -- Expose API
BS.Settings = {
    Save = saveSettings,
    Load = loadSettings,
    LoadPreset = loadPreset,
    Reset = resetSettings,
    Export = exportSettings,
    Import = importSettings,
    Presets = Presets,
}

 -- Auto-load on start
task.delay(2, function()
    pcall(function()
        if safeIsFile(SETTINGS_DIR .. SETTINGS_FILE) then
            loadSettings()
        end
    end)
end)

print("[Settings] BloxStrike Settings module loaded")
print("[Settings] Commands: BS.Settings.Save/Load/LoadPreset/Reset/Export/Import")
