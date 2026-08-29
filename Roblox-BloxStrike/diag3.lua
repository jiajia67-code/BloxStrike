--[[BloxStrike Final Diagnostic v3]]
local BASE = "https://raw.githubusercontent.com/jiajia67-code/BloxStrike/main/Roblox-BloxStrike/modules/"

local function httpGet(url)
    if http_request then
        local ok, res = pcall(function() return http_request({Url=url, Method='GET'}) end)
        if ok and res and res.Body then return res.Body end
    end
    if request then
        local ok, res = pcall(function() return request({Url=url, Method='GET'}) end)
        if ok and res and res.Body then return res.Body end
    end
    return nil
end

local PREAMBLE = "BS = _G.BS or {} Flags = _G.Flags or {} _G.BS = BS _G.Flags = Flags\nlocal game = game local workspace = workspace local Instance = Instance\nlocal Color3 = Color3 local UDim2 = UDim2 local UDim = UDim\nlocal Vector3 = Vector3 local Vector2 = Vector2 local CFrame = CFrame\nlocal Enum = Enum local tick = tick local wait = wait\nlocal pcall = pcall local error = error local warn = warn local print = print\nlocal pairs = pairs local ipairs = ipairs local table = table local string = string\nlocal math = math local task = task local unpack = unpack or table.unpack\nlocal Players = game:GetService('Players') local RunService = game:GetService('RunService')\nlocal UserInputService = game:GetService('UserInputService')\nlocal StarterGui = game:GetService('StarterGui') local HttpService = game:GetService('HttpService')\nlocal TweenService = game:GetService('TweenService') local ReplicatedStorage = game:GetService('ReplicatedStorage')\nlocal lplr = Players.LocalPlayer local http_request = http_request local request = request\n"

-- Load deps first
local DEPS = {'compat','core','ui','api'}
print("=== Loading deps ===")
for _, name in ipairs(DEPS) do
    local code = httpGet(BASE .. name .. ".lua")
    if code then
        local fn, err = loadstring(PREAMBLE .. code)
        if fn then
            local ok, e = pcall(fn)
            print("  " .. name .. ": " .. (ok and "OK" or "ERR: " .. tostring(e):sub(1,60)))
        else
            print("  " .. name .. ": COMPILE: " .. tostring(err):sub(1,80))
        end
    end
end

-- Test ALL modules
local ALL = {'combat','combatassist','esp','hud','killeffects','utility','world',
    'rage','pingadapt','smartai','settings','stealth','cheatdetect',
    'bypass','errorhandler','events','luau_detect'}

print("\n=== All modules ===")
local ok_count, fail_count = 0, 0
for _, name in ipairs(ALL) do
    local code = httpGet(BASE .. name .. ".lua")
    if not code then
        print(name .. ": DOWNLOAD FAIL")
        fail_count = fail_count + 1
    else
        local fn, cerr = loadstring(PREAMBLE .. code)
        if not fn then
            print(name .. ": COMPILE: " .. tostring(cerr):sub(1,80))
            fail_count = fail_count + 1
        else
            local rok, rerr = pcall(fn)
            if rok then
                print(name .. ": OK")
                ok_count = ok_count + 1
            else
                print(name .. ": RUNTIME: " .. tostring(rerr):sub(1,80))
                fail_count = fail_count + 1
            end
        end
    end
end
print("\n=== Result: " .. ok_count .. " OK / " .. fail_count .. " FAIL ===")
