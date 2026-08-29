--[[
    BloxStrike One-Click Fixer v2.0 (無 readfile 版本)
    
    這個腳本包含所有修正後的小模組原始碼。
    大模組使用 writefile 補丁修復。
    
    用法：
    1. 貼上 BloxStrike.lua 到執行器（不要執行）
    2. 貼上這個腳本並執行
    3. 自動修復所有模組並載入 BloxStrike
]]

print("[Fixer] BloxStrike One-Click Fixer v2.0")
print("[Fixer] 正在掃描模組路徑...")

-- 找到模組路徑
local MODULE_PATH = nil
local candidates = {
    "BloxStrike/modules", "./BloxStrike/modules",
    "../BloxStrike/modules", "../../BloxStrike/modules",
    "modules", "./modules",
}

for _, path in ipairs(candidates) do
    pcall(function()
        local files = listfiles(path)
        if files then
            for _, f in ipairs(files) do
                if f:find("core%.lua") then
                    MODULE_PATH = path
                    break
                end
            end
        end
    end)
    if MODULE_PATH then break end
end

if not MODULE_PATH then MODULE_PATH = "BloxStrike/modules" end
print("[Fixer] 模組路徑: " .. MODULE_PATH)

-- ═══════════════════════════════════════
-- 輔助函數
-- ═══════════════════════════════════════
local function patchFile(name, patches)
    local path = MODULE_PATH .. "/" .. name
    local ok, content = pcall(readfile, path)
    if not ok or not content then
        print("[Fixer]   " .. name .. ": 找不到，跳過")
        return false
    end
    local original = content
    for _, p in ipairs(patches) do
        content = content:gsub(p[1], p[2])
    end
    if content ~= original then
        writefile(path, content)
        print("[Fixer]   " .. name .. ": 已修復")
        return true
    else
        print("[Fixer]   " .. name .. ": 已是最新")
        return false
    end
end

local function writeFile(name, content)
    local path = MODULE_PATH .. "/" .. name
    writefile(path, content)
    print("[Fixer]   " .. name .. ": 已寫入")
end

print("[Fixer] 開始修復...")
print("")

-- ═══════════════════════════════════════
-- 1. compat.lua - 取消註解所有函數定義
-- ═══════════════════════════════════════
print("[Fixer] 1/16 compat.lua")
patchFile("compat.lua", {
    { "%-%- (Compat%.%w+%s*=%s*function)", "%1" },
})

-- ═══════════════════════════════════════
-- 2. api.lua - 修復 KnitInit + Client
-- ═══════════════════════════════════════
print("[Fixer] 2/16 api.lua")
patchFile("api.lua", {
    { "%-%- (KnitInit, Knit = pcall%(function%)", "%1" },
    { "%-%- (Client = require)", "%1" },
})

-- ═══════════════════════════════════════
-- 3. bypass.lua - 修復空條件
-- ═══════════════════════════════════════
print("[Fixer] 3/16 bypass.lua")
patchFile("bypass.lua", {
    { "%-%- (name:find%(\"BS\"%) or name:find%(\"BloxStrike\"%) or)", "%1" },
    { "%-%- (name:find%(\"bypass\"%) or name:find%(\"stealth\"%))", "%1" },
})

-- ═══════════════════════════════════════
-- 4. cheatdetect.lua - 修復多餘的 )
-- ═══════════════════════════════════════
print("[Fixer] 4/16 cheatdetect.lua")
patchFile("cheatdetect.lua", {
    { '"%%%)")"', '"%%)"' },
})

-- ═══════════════════════════════════════
-- 5. combat.lua - continue → return
-- ═══════════════════════════════════════
print("[Fixer] 5/16 combat.lua")
patchFile("combat.lua", {
    { "(aimTarget = nil%s*\n%s*)continue", "%1return" },
})

-- ═══════════════════════════════════════
-- 6. combatassist.lua - 修復 Text + 改名
-- ═══════════════════════════════════════
print("[Fixer] 6/16 combatassist.lua")
patchFile("combatassist.lua", {
    { "%-%- (Text = string%.format)", "%1" },
    { '"Combat Assist"', '"Comms"' },
})

-- ═══════════════════════════════════════
-- 7. errorhandler.lua - 修復 Connect
-- ═══════════════════════════════════════
print("[Fixer] 7/16 errorhandler.lua")
patchFile("errorhandler.lua", {
    { "%-%- (UserInputService%.InputBegan:Connect)", "%1" },
})

-- ═══════════════════════════════════════
-- 8. esp.lua - Colorpicker 用 pcall
-- ═══════════════════════════════════════
print("[Fixer] 8/16 esp.lua")
patchFile("esp.lua", {
    { "(E:Colorpicker%(\"Custom Color\")", "pcall(function() %1" },
})

-- ═══════════════════════════════════════
-- 9. events.lua - 取消註解參數
-- ═══════════════════════════════════════
print("[Fixer] 9/16 events.lua")
patchFile("events.lua", {
    { "%-%- (Stats%.RoundWins)", "%1" },
})

-- ═══════════════════════════════════════
-- 10. pingadapt.lua - 分離 task.spawn
-- ═══════════════════════════════════════
print("[Fixer] 10/16 pingadapt.lua")
patchFile("pingadapt.lua", {
    { "(%-%- Auto%-apply ping adaptation to %w+) task%.spawn%(function%(%))", "%1\ntask.spawn(function()" },
})

-- ═══════════════════════════════════════
-- 11. rage.lua - 分離 task.spawn
-- ═══════════════════════════════════════
print("[Fixer] 11/16 rage.lua")
patchFile("rage.lua", {
    { "(%-%- RAGEBOT ENGINE) task%.spawn%(function%(%))", "%1\ntask.spawn(function()" },
    { "(%-%- [^\n]+) task%.spawn%(function%(%))", "%1\ntask.spawn(function()" },
    { "%-%- task%.spawn%(function%(%))", "task.spawn(function()" },
})

-- ═══════════════════════════════════════
-- 12. smartai.lua - 修復 elseif/end
-- ═══════════════════════════════════════
print("[Fixer] 12/16 smartai.lua")
patchFile("smartai.lua", {
    { "score = score %+ 3 %-%- elseif", "score = score + 3\n        elseif" },
    { "score = score %+ 2 %-%- end", "score = score + 2\n        end" },
    { "score = score %+ 5 %-%- elseif", "score = score + 5\n        elseif" },
    { "score = score %- 5 %-%- end", "score = score - 5\n        end" },
})

-- ═══════════════════════════════════════
-- 13. stealth.lua - 移除多餘的 )
-- ═══════════════════════════════════════
print("[Fixer] 13/16 stealth.lua")
patchFile("stealth.lua", {
    { "(end\nend%)\n\n%-%- Burst smoothing)", "end\nend\n\n%1" },
})

-- ═══════════════════════════════════════
-- 14. utility.lua - 修復空白分頁 + 取消註解
-- ═══════════════════════════════════════
print("[Fixer] 14/16 utility.lua")
patchFile("utility.lua", {
    { 'BS%.Win:Tab%("")', 'BS.Win:Tab("Misc")' },
    { "%-%- (U:Button)", "%1" },
    { "%-%- (M:Button)", "%1" },
})

-- ═══════════════════════════════════════
-- 15. viewmodel.lua - 取消註解 ApplyPreset
-- ═══════════════════════════════════════
print("[Fixer] 15/16 viewmodel.lua")
patchFile("viewmodel.lua", {
    { "%-%- (ApplyPreset = function)", "%1" },
})

-- ═══════════════════════════════════════
-- 16. webhook.lua - 取消註解 embed
-- ═══════════════════════════════════════
print("[Fixer] 16/16 webhook.lua")
patchFile("webhook.lua", {
    { "%-%- (Webhook%.embed%({)", "%1" },
    { "%-%- (Compat%.HttpRequest%({)", "%1" },
})

-- ═══════════════════════════════════════
-- 額外修復 ui.lua
-- ═══════════════════════════════════════
print("[Fixer] 修復 ui.lua...")
patchFile("ui.lua", {
    { "(Rayfield:ToggleVisibility%(%))", "pcall(function() %1 end)" },
})

print("")
print("[Fixer] ========================================")
print("[Fixer] 修復完成！正在重新載入 BloxStrike...")
print("[Fixer] ========================================")
print("")

task.wait(1)

-- 重新載入 BloxStrike
local bsPath = MODULE_PATH:gsub("/modules$", "") .. "/BloxStrike.lua"
local bsOk, bsContent = pcall(readfile, bsPath)
if bsOk and bsContent then
    local fn, err = loadstring(bsContent, "BloxStrike")
    if fn then
        fn()
    else
        print("[Fixer] 載入失敗: " .. tostring(err))
    end
else
    print("[Fixer] 找不到 BloxStrike.lua，請手動執行")
end
