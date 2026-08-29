-- ══════════════════════════════════════════════════════════════
-- UTILITY MODULE
-- ══════════════════════════════════════════════════════════════
local U = BW.Win:Tab("Util", "⚙️")
U:Toggle({Name="Anti AFK", Flag="AntiAFK"})
U:Toggle({Name="Staff Detection", Flag="StaffDetect"})
U:Toggle({Name="Anti Staff: Auto Disconnect", Flag="AntiStaffDC"})
U:Toggle({Name="Anti Staff: Auto Rejoin", Flag="AntiStaffRejoin"})
U:Toggle({Name="Anti Staff: Panic on Staff", Flag="AntiStaffPanic"})
U:Toggle({Name="Anti Staff: Chat Warn", Flag="AntiStaffChat"})
U:Toggle({Name="Anti Staff: Full Scan", Flag="AntiStaffFull"})
U:Toggle({Name="Panic (disable ALL)", Flag="Panic"})
U:Toggle({Name="AutoVoidDrop", Flag="AutoVoidDrop"})
U:Toggle({Name="Blink", Flag="Blink"})
U:Toggle({Name="TrapDisabler", Flag="TrapDisabler"})
U:Separator()
U:Label("-- Discord Webhook --")
U:Input({Name="Webhook URL", Flag="WebhookURL", Placeholder="https://discord.com/api/webhooks/..."})
U:Toggle({Name="Webhook: On Kill", Flag="WH_Kill", Default=true})
U:Toggle({Name="Webhook: On Bed Break", Flag="WH_Bed", Default=true})
U:Toggle({Name="Webhook: On Death", Flag="WH_Death", Default=true})
U:Toggle({Name="Webhook: On Victory", Flag="WH_Win", Default=true})
U:Button({Name="Test Webhook", Color=Color3.fromRGB(80,60,140)}, function()
    BW.Config.DiscordWebhook=BW.Flags.WebhookURL or ""; BW.SaveConfig()
    BW.SendWebhook("Test","BedWars webhook working!",3447003)
    BW.StarterGui:SetCore("SendNotification",{Title="Webhook",Text="Test sent!",Duration=2})
end)
U:Separator()
U:Button({Name="Save Settings", Color=Color3.fromRGB(60,120,60)}, function()
    BW.Config.DiscordWebhook=BW.Flags.WebhookURL or ""
    BW.Config.WebhookOnKill=BW.Flags.WH_Kill; BW.Config.WebhookOnBedBreak=BW.Flags.WH_Bed
    BW.Config.WebhookOnDeath=BW.Flags.WH_Death; BW.Config.WebhookOnVictory=BW.Flags.WH_Win
    BW.SaveConfig(); BW.StarterGui:SetCore("SendNotification",{Title="Settings",Text="Saved!",Duration=2})
end)
U:Button({Name="Load Settings", Color=Color3.fromRGB(100,80,40)}, function()
    BW.LoadConfig(); BW.Flags.WebhookURL=BW.Config.DiscordWebhook
    BW.Flags.WH_Kill=BW.Config.WebhookOnKill; BW.Flags.WH_Bed=BW.Config.WebhookOnBedBreak
    BW.Flags.WH_Death=BW.Config.WebhookOnDeath; BW.Flags.WH_Win=BW.Config.WebhookOnVictory
    BW.StarterGui:SetCore("SendNotification",{Title="Settings",Text="Loaded!",Duration=2})
end)
U:Separator()
U:Button({Name="Rejoin Server", Color=Color3.fromRGB(140,90,30)}, function()
    BW.TeleportService:TeleportToPlaceInstance(game.PlaceId,game.JobId,BW.LocalPlayer)
end)
U:Button({Name="Leave Game", Color=Color3.fromRGB(160,40,40)}, function() game:Shutdown() end)

-- ═══ ENGINES ═══

-- Panic
task.spawn(function()
    while true do
        if BW.Flags.Panic then
            for k,_ in pairs(BW.Flags) do BW.Flags[k]=false end
            BW.Flags.Panic=false
            BW.StarterGui:SetCore("SendNotification",{Title="Panic",Text="All disabled!",Duration=2})
        end
        task.wait(0.2)
    end
end)

-- Anti AFK
task.spawn(function()
    while true do
        if BW.Flags.AntiAFK then
            BW.Perf:Throttle("AntiAFK",60,function()
                pcall(function()
                    BW.VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.W,false,game); task.wait(0.2)
                    BW.VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.W,false,game); task.wait(0.2)
                    BW.VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.W,false,game)
                end)
            end)
        end
        task.wait(1)
    end
end)

-- Staff Detection
local staffDetected=false
local StaffGroups={{Id=3252059,MinRank=100,Name="BedWars"},{Id=3281747,MinRank=100,Name="Easy.gg"},{Id=2868474,MinRank=100,Name="Roblox"}}
local StaffPatterns={"moderator","admin","staff","helper","builder","developer","dev","head admin","community manager","trial mod","senior mod","lead mod"}

local function checkStaff(player)
    for _,g in ipairs(StaffGroups) do
        pcall(function() local rank=player:GetRankInGroup(g.Id) if rank and rank>=g.MinRank then return true,g.Name.." Rank:"..rank end end)
    end
    local dn=player.DisplayName:lower()
    for _,p in ipairs(StaffPatterns) do if dn:find(p) then return true,"Display: "..p end end
    local un=player.Name:lower()
    for _,p in ipairs(StaffPatterns) do if un:find(p) then return true,"User: "..p end end
    return false,nil
end

task.spawn(function()
    while true do
        if BW.Flags.StaffDetect and not staffDetected then
            for _,p in pairs(BW.Players:GetPlayers()) do
                if p~=BW.LocalPlayer then
                    local isStaff,reason=checkStaff(p)
                    if isStaff then
                        staffDetected=true
                        pcall(function() BW.StarterGui:SetCore("SendNotification",{Title="STAFF!",Text=p.Name.." ("..reason..")",Duration=10}) end)
                        BW.SendWebhook("STAFF!",p.Name.."("..reason..")",16711680)
                        if BW.Flags.AntiStaffChat then pcall(function()
                            for _,r in pairs(BW.ReplicatedStorage:GetDescendants()) do if r:IsA("RemoteEvent") and r.Name:lower():find("chat") then r:FireServer("STAFF: "..p.Name.." LEAVE NOW") break end end
                        end) end
                        if BW.Flags.AntiStaffPanic then for k,_ in pairs(BW.Flags) do BW.Flags[k]=false end end
                        if BW.Flags.AntiStaffDC then task.wait(1); pcall(function() game:Shutdown() end) end
                        if BW.Flags.AntiStaffRejoin then task.wait(2); pcall(function() BW.TeleportService:Teleport(game.PlaceId,BW.LocalPlayer) end) end
                        break
                    end
                end
            end
        end
        task.wait(3)
    end
end)

-- AutoVoidDrop
task.spawn(function()
    while true do
        if BW.Flags.AutoVoidDrop and BW.alive() then
            local my=BW.hrp()
            if my and my.Position.Y<-30 then
                for _,tool in pairs(BW.char():GetChildren()) do if tool:IsA("Tool") then tool.Parent=BW.LocalPlayer.Backpack end end
            end
        end
        task.wait(0.1)
    end
end)

-- ═══ Ping HUD ═══
U:Toggle({Name="Ping HUD", Flag="PingHUD"})
U:Toggle({Name="Ping Auto-Adapt", Flag="PingAdapt", Default=true})

-- Ping HUD Engine
task.spawn(function()
    local pingLabel = nil
    local fpsLabel = nil
    local qualityLabel = nil
    while true do
        if BW.Flags.PingHUD then
            pcall(function()
                local sg = game.CoreGui:FindFirstChild("BW_PingHUD")
                if not sg then
                    sg = Instance.new("ScreenGui")
                    sg.Name = "BW_PingHUD"
                    sg.ResetOnSpawn = false
                    sg.Parent = game.CoreGui

                    local frame = Instance.new("Frame")
                    frame.Size = UDim2.new(0, 160, 0, 70)
                    frame.Position = UDim2.new(0, 10, 0, 10)
                    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
                    frame.BackgroundTransparency = 0.2
                    frame.BorderSizePixel = 0
                    frame.Parent = sg
                    local corner = Instance.new("UICorner")
                    corner.CornerRadius = UDim.new(0, 8)
                    corner.Parent = frame

                    pingLabel = Instance.new("TextLabel")
                    pingLabel.Size = UDim2.new(1, -10, 0, 20)
                    pingLabel.Position = UDim2.new(0, 5, 0, 5)
                    pingLabel.BackgroundTransparency = 1
                    pingLabel.Text = "Ping: 0ms"
                    pingLabel.TextColor3 = Color3.fromRGB(80, 200, 120)
                    pingLabel.TextSize = 14
                    pingLabel.Font = Enum.Font.GothamBold
                    pingLabel.TextXAlignment = Enum.TextXAlignment.Left
                    pingLabel.Parent = frame

                    fpsLabel = Instance.new("TextLabel")
                    fpsLabel.Size = UDim2.new(1, -10, 0, 20)
                    fpsLabel.Position = UDim2.new(0, 5, 0, 25)
                    fpsLabel.BackgroundTransparency = 1
                    fpsLabel.Text = "FPS: 60"
                    fpsLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
                    fpsLabel.TextSize = 12
                    fpsLabel.Font = Enum.Font.Gotham
                    fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
                    fpsLabel.Parent = frame

                    qualityLabel = Instance.new("TextLabel")
                    qualityLabel.Size = UDim2.new(1, -10, 0, 20)
                    qualityLabel.Position = UDim2.new(0, 5, 0, 45)
                    qualityLabel.BackgroundTransparency = 1
                    qualityLabel.Text = "Quality: Good"
                    qualityLabel.TextColor3 = Color3.fromRGB(80, 200, 120)
                    qualityLabel.TextSize = 12
                    qualityLabel.Font = Enum.Font.Gotham
                    qualityLabel.TextXAlignment = Enum.TextXAlignment.Left
                    qualityLabel.Parent = frame
                end

                -- Update display
                if pingLabel then
                    local ping = BW.Ping and BW.Ping.Current or 0
                    local quality = BW.Ping and BW.Ping.Quality or "Unknown"
                    local fps = BW.Perf and BW.Perf.FPS or 0
                    local jitter = BW.Ping and BW.Ping.Jitter or 0

                    -- Color based on quality
                    local color
                    if quality == "Good" then color = Color3.fromRGB(80, 200, 120)
                    elseif quality == "Fair" then color = Color3.fromRGB(255, 200, 50)
                    elseif quality == "Poor" then color = Color3.fromRGB(255, 150, 50)
                    else color = Color3.fromRGB(240, 70, 70) end

                    pingLabel.Text = string.format("Ping: %dms (±%d)", ping, jitter)
                    pingLabel.TextColor3 = color
                    fpsLabel.Text = string.format("FPS: %d", fps)
                    qualityLabel.Text = string.format("Quality: %s", quality)
                    qualityLabel.TextColor3 = color
                end
            end)
        else
            pcall(function()
                local sg = game.CoreGui:FindFirstChild("BW_PingHUD")
                if sg then sg:Destroy() end
            end)
        end
        task.wait(0.5)
    end
end)

-- Ping Auto-Adapt Engine (adjust all features based on ping)
task.spawn(function()
    while true do
        if BW.Flags.PingAdapt and BW.Ping then
            local q = BW.Ping.Quality
            if q == "Terrible" then
                -- Reduce all aggressive features when ping is bad
                if BW.Flags.AC then BW.Flags.AC_CPS = math.min(BW.Flags.AC_CPS or 14, 8) end
                if BW.Flags.CA then BW.Flags.CA_Delay = math.max(BW.Flags.CA_Delay or 0.03, 0.15) end
            elseif q == "Poor" then
                if BW.Flags.AC then BW.Flags.AC_CPS = math.min(BW.Flags.AC_CPS or 14, 10) end
                if BW.Flags.CA then BW.Flags.CA_Delay = math.max(BW.Flags.CA_Delay or 0.03, 0.08) end
            elseif q == "Good" then
                -- Allow faster speeds when ping is good
                if BW.Flags.AC and (BW.Flags.AC_CPS or 14) < 12 then BW.Flags.AC_CPS = 14 end
                if BW.Flags.CA and (BW.Flags.CA_Delay or 0.03) > 0.05 then BW.Flags.CA_Delay = 0.03 end
            end
        end
        task.wait(2)
    end
end)

print("[Util] Module loaded (with Ping HUD)")
