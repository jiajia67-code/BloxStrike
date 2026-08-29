--[[BloxStrike HTTP 診斷工具]]
-- 貼到執行器，看控制台輸出

print('========================================')
print('  BloxStrike HTTP 診斷')
print('========================================')

-- Test 1: game:HttpGet
local ok1, err1 = pcall(function()
    local r = game:HttpGet("https://httpbin.org/get", true)
    print('[1] game:HttpGet = ' .. tostring(type(r)))
    if r then print('    長度: ' .. #r) end
end)
if not ok1 then print('[1] game:HttpGet = FAILED: ' .. tostring(err1)) end

-- Test 2: game:HttpGetAsync
local ok2, err2 = pcall(function()
    local r = game:HttpGetAsync("https://httpbin.org/get")
    print('[2] game:HttpGetAsync = ' .. tostring(type(r)))
    if r then print('    長度: ' .. #r) end
end)
if not ok2 then print('[2] game:HttpGetAsync = FAILED: ' .. tostring(err2)) end

-- Test 3: syn.request
local ok3, err3 = pcall(function()
    if syn and syn.request then
        local r = syn.request({Url = "https://httpbin.org/get", Method = "GET"})
        print('[3] syn.request = ' .. tostring(type(r)))
        if r then print('    Body: ' .. tostring(r.Body and #r.Body or 'nil')) end
    else
        print('[3] syn.request = NOT AVAILABLE')
    end
end)
if not ok3 then print('[3] syn.request = FAILED: ' .. tostring(err3)) end

-- Test 4: http_request
local ok4, err4 = pcall(function()
    if http_request then
        local r = http_request({Url = "https://httpbin.org/get", Method = "GET"})
        print('[4] http_request = ' .. tostring(type(r)))
        if r then print('    Body: ' .. tostring(r.Body and #r.Body or 'nil')) end
    else
        print('[4] http_request = NOT AVAILABLE')
    end
end)
if not ok4 then print('[4] http_request = FAILED: ' .. tostring(err4)) end

-- Test 5: request
local ok5, err5 = pcall(function()
    if request then
        local r = request({Url = "https://httpbin.org/get", Method = "GET"})
        print('[5] request = ' .. tostring(type(r)))
        if r then print('    Body: ' .. tostring(r.Body and #r.Body or 'nil')) end
    else
        print('[5] request = NOT AVAILABLE')
    end
end)
if not ok5 then print('[5] request = FAILED: ' .. tostring(err5)) end

-- Test 6: HttpService
local ok6, err6 = pcall(function()
    local hs = game:GetService("HttpService")
    local r = hs:GetAsync("https://httpbin.org/get")
    print('[6] HttpService:GetAsync = ' .. tostring(type(r)))
    if r then print('    長度: ' .. #r) end
end)
if not ok6 then print('[6] HttpService:GetAsync = FAILED: ' .. tostring(err6)) end

-- Test 7: fluxusrequest
local ok7, err7 = pcall(function()
    if fluxusrequest then
        local r = fluxusrequest({Url = "https://httpbin.org/get", Method = "GET"})
        print('[7] fluxusrequest = ' .. tostring(type(r)))
        if r then print('    Body: ' .. tostring(r.Body and #r.Body or 'nil')) end
    else
        print('[7] fluxusrequest = NOT AVAILABLE')
    end
end)
if not ok7 then print('[7] fluxusrequest = FAILED: ' .. tostring(err7)) end

-- Test 8: loadstring test
local ok8, err8 = pcall(function()
    local fn = loadstring("return 1+1")
    if fn then
        print('[8] loadstring = ' .. tostring(fn()))
    else
        print('[8] loadstring = nil')
    end
end)
if not ok8 then print('[8] loadstring = FAILED: ' .. tostring(err8)) end

-- Summary
print('========================================')
print('  把以上輸出截圖給我')
print('========================================')
