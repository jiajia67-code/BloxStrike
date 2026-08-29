--[[
    BloxStrike Console Capture
    ========================
    捕獲所有控制台輸出並保存到檔案
    
    用法:
    1. 先貼這段到執行器執行
    2. 然後貼 BloxStrike 腳本執行
    3. 所有控制台輸出會自動保存
    4. 執行 BS.ExportLogs() 匯出到檔案
]]

-- ═══ Init ═══
_G.BS = _G.BS or {}
local Players = game:GetService("Players")
local lplr = Players.LocalPlayer
local LOG_FILE = "BloxStrike_Logs.txt"
local logs = {}
local startTime = tick()

-- ═══ Capture print/warn ═══
local origPrint = print
local origWarn = warn

local function timestamp()
    return string.format("[%02d:%02d:%02d]",
        math.floor((tick() - startTime) / 3600) % 24,
        math.floor((tick() - startTime) / 60) % 60,
        math.floor(tick() - startTime) % 60)
end

print = function(...)
    local args = {...}
    local msg = table.concat(args, "\t")
    local line = timestamp() .. " [PRINT] " .. msg
    table.insert(logs, line)
    origPrint(...)
end

warn = function(...)
    local args = {...}
    local msg = table.concat(args, "\t")
    local line = timestamp() .. " [WARN] " .. msg
    table.insert(logs, line)
    origWarn(...)
end

-- ═══ Capture ScriptContext errors ═══
pcall(function()
    game:GetService("ScriptContext").Error:Connect(function(msg, trace, source)
        local line = timestamp() .. " [ERROR] " .. tostring(msg)
        if trace and #trace > 0 then
            line = line .. "\n    Trace: " .. trace:sub(1, 200)
        end
        table.insert(logs, line)
    end)
end)

-- ═══ Export function ═══
function _G.BS.ExportLogs()
    local content = "=== BloxStrike Console Logs ===\n"
    content = content .. "Game: " .. game.PlaceId .. "\n"
    content = content .. "Player: " .. lplr.Name .. " (" .. lplr.UserId .. ")\n"
    content = content .. "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"
    content = content .. "Executor: " .. (identifyexecutor and identifyexecutor() or "Unknown") .. "\n"
    content = content .. "Logs: " .. #logs .. " lines\n"
    content = content .. "================================\n\n"
    
    for _, log in ipairs(logs) do
        content = content .. log .. "\n"
    end
    
    -- Method 1: writefile (most executors)
    local ok1 = pcall(function()
        writefile(LOG_FILE, content)
    end)
    
    -- Method 2: Clipboard
    local ok2 = pcall(function()
        if setclipboard then
            setclipboard(content)
        end
    end)
    
    -- Method 3: tofile
    local ok3 = pcall(function()
        if tofile then
            tofile(LOG_FILE, content)
        end
    end)
    
    origPrint("[BloxStrike] Logs exported!")
    origPrint("[BloxStrike] " .. #logs .. " lines captured")
    
    if ok1 then
        origPrint("[BloxStrike] Saved to: " .. LOG_FILE)
        origPrint("[BloxStrike] Path: " .. (getcustomasset and getcustomasset(LOG_FILE) or LOG_FILE))
    end
    if ok2 then
        origPrint("[BloxStrike] Also copied to clipboard!")
    end
    
    return content
end

-- ═══ Auto-save every 30 seconds ═══
task.spawn(function()
    while true do
        task.wait(30)
        if #logs > 0 then
            pcall(function()
                local content = "=== Auto-save ===\n"
                for _, log in ipairs(logs) do
                    content = content .. log .. "\n"
                end
                writefile(LOG_FILE, content)
            end)
        end
    end
end)

-- ═══ Print Instructions ═══
origPrint("")
origPrint("========================================")
origPrint("  BloxStrike Console Capture ACTIVE")
origPrint("========================================")
origPrint("  All print/warn output is being captured")
origPrint("  Errors are being captured")
origPrint("")
origPrint("  To export logs:")
origPrint("    BS.ExportLogs()")
origPrint("")
origPrint("  Logs auto-save every 30s")
origPrint("========================================")
origPrint("")

print("[ConsoleCapture] Ready! Now paste your script.")
