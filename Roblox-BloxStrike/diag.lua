--[[BloxStrike Module Diagnostic]]
-- 貼到執行器，看控制台錯誤

local BASE = "https://raw.githubusercontent.com/jiajia67-code/BloxStrike/main/Roblox-BloxStrike/modules/"

-- Universal HTTP
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

local MODULES = {
    'compat', 'core', 'ui', 'api',
    'combat', 'esp', 'rage', 'stealth',
    'utility', 'world', 'pingadapt', 'hud',
    'killeffects', 'cheatdetect', 'settings',
    'combatassist', 'smartai', 'bypass',
    'errorhandler', 'events', 'luau_detect'
}

print("========================================")
print("  BloxStrike Module Diagnostic")
print("========================================")

local ok_count = 0
local fail_count = 0

for _, name in ipairs(MODULES) do
    print("\n--- " .. name .. ".lua ---")
    local code = httpGet(BASE .. name .. ".lua")
    if not code then
        print("  DOWNLOAD FAILED!")
        fail_count = fail_count + 1
    else
        print("  Downloaded: " .. #code .. " bytes")
        local fn, compileErr = loadstring(code)
        if not fn then
            print("  COMPILE ERROR: " .. tostring(compileErr))
            fail_count = fail_count + 1
        else
            local runtimeOk, runtimeErr = pcall(fn)
            if runtimeOk then
                print("  OK!")
                ok_count = ok_count + 1
            else
                print("  RUNTIME ERROR: " .. tostring(runtimeErr))
                fail_count = fail_count + 1
            end
        end
    end
end

print("\n========================================")
print("  Results: " .. ok_count .. " OK / " .. fail_count .. " FAIL")
print("========================================")
