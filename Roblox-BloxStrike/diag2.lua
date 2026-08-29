--[[BloxStrike Diagnostic v2]]
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

-- Only test the FAILING modules
local FAILING = {'combat','rage','utility','cheatdetect','smartai','bypass','stealth','events','luau_detect'}

-- First load compat+core+ui+api so BS exists
local DEPS = {'compat','core','ui','api'}
print("=== Loading dependencies ===")
for _, name in ipairs(DEPS) do
    local code = httpGet(BASE .. name .. ".lua")
    if code then
        local preamble = "BS = _G.BS or {} Flags = _G.Flags or {} _G.BS = BS _G.Flags = Flags\nlocal game = game local workspace = workspace local Instance = Instance\nlocal Color3 = Color3 local UDim2 = UDim2 local UDim = UDim\nlocal Vector3 = Vector3 local Vector2 = Vector2 local CFrame = CFrame\nlocal Enum = Enum local tick = tick local wait = wait\nlocal pcall = pcall local error = error local warn = warn local print = print\nlocal pairs = pairs local ipairs = ipairs local table = table local string = string\nlocal math = math local task = task local unpack = unpack or table.unpack\nlocal Players = game:GetService('Players') local RunService = game:GetService('RunService')\nlocal UserInputService = game:GetService('UserInputService')\nlocal StarterGui = game:GetService('StarterGui') local HttpService = game:GetService('HttpService')\nlocal TweenService = game:GetService('TweenService') local ReplicatedStorage = game:GetService('ReplicatedStorage')\nlocal lplr = Players.LocalPlayer local http_request = http_request local request = request\n"
        local fn, err = loadstring(preamble .. code)
        if fn then
            local ok, e = pcall(fn)
            print("  " .. name .. ": " .. (ok and "OK" or "RUNTIME: " .. tostring(e):sub(1,80)))
        else
            print("  " .. name .. ": COMPILE: " .. tostring(err))
        end
    end
end

print("\n=== Testing failing modules ===")
for _, name in ipairs(FAILING) do
    print("\n--- " .. name .. ".lua ---")
    local code = httpGet(BASE .. name .. ".lua")
    if not code then
        print("  DOWNLOAD FAILED")
    else
        print("  Size: " .. #code .. " bytes")
        local preamble = "BS = _G.BS or {} Flags = _G.Flags or {} _G.BS = BS _G.Flags = Flags\nlocal game = game local workspace = workspace local Instance = Instance\nlocal Color3 = Color3 local UDim2 = UDim2 local UDim = UDim\nlocal Vector3 = Vector3 local Vector2 = Vector2 local CFrame = CFrame\nlocal Enum = Enum local tick = tick local wait = wait\nlocal pcall = pcall local error = error local warn = warn local print = print\nlocal pairs = pairs local ipairs = ipairs local table = table local string = string\nlocal math = math local task = task local unpack = unpack or table.unpack\nlocal Players = game:GetService('Players') local RunService = game:GetService('RunService')\nlocal UserInputService = game:GetService('UserInputService')\nlocal StarterGui = game:GetService('StarterGui') local HttpService = game:GetService('HttpService')\nlocal TweenService = game:GetService('TweenService') local ReplicatedStorage = game:GetService('ReplicatedStorage')\nlocal lplr = Players.LocalPlayer local http_request = http_request local request = request\n"
        local fn, compileErr = loadstring(preamble .. code)
        if not fn then
            print("  COMPILE ERROR: " .. tostring(compileErr))
        else
            local runtimeOk, runtimeErr = pcall(fn)
            if runtimeOk then
                print("  OK!")
            else
                print("  RUNTIME ERROR: " .. tostring(runtimeErr):sub(1,200))
            end
        end
    end
end
print("\n=== Done ===")
