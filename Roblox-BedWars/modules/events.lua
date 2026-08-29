-- ══════════════════════════════════════════════════════════════
-- EVENTS MODULE (Kill/Death/Bed/Victory tracking)
-- ══════════════════════════════════════════════════════════════
local killCount=0
local deathCount=0
local bedBreaks=0

-- Kill tracking
task.spawn(function()
    local prevHealth={}
    while true do
        for _,p in pairs(BW.Players:GetPlayers()) do
            if p~=BW.LocalPlayer and p.Character then
                local h=p.Character:FindFirstChildOfClass("Humanoid")
                if h then
                    local prev=prevHealth[p.UserId] or h.Health
                    if prev>0 and h.Health<=0 and p.Team~=BW.LocalPlayer.Team then
                        killCount=killCount+1
                        BW.SendWebhook("Kill #"..killCount,"Eliminated **"..p.Name.."**\nTotal: "..killCount,15158332)
                    end
                    prevHealth[p.UserId]=h.Health
                end
            end
        end
        task.wait(0.3)
    end
end)

-- Death tracking
task.spawn(function()
    while true do
        local c=BW.LocalPlayer.Character
        if c then
            local h=c:FindFirstChildOfClass("Humanoid")
            if h then
                h.Died:Connect(function()
                    deathCount=deathCount+1
                    BW.SendWebhook("Death #"..deathCount,"You were eliminated!",15158332)
                end)
            end
        end
        task.wait(1)
    end
end)

-- Bed break tracking
task.spawn(function()
    while true do
        for _, obj in pairs(BW.Workspace:GetDescendants()) do
            if obj.Name=="Bed" and obj:IsA("Model") and not obj:GetAttribute("_BW_Tracked") then
                obj:SetAttribute("_BW_Tracked",true)
                local tag=obj:FindFirstChild("Team")
                local isEnemy=tag and tag:IsA("StringValue") and tag.Value~=(BW.LocalPlayer.Team and BW.LocalPlayer.Team.Name or "")
                obj.AncestryChanged:Connect(function(_,parent)
                    if not parent and isEnemy then
                        bedBreaks=bedBreaks+1
                        BW.SendWebhook("Bed Destroyed!","Enemy bed destroyed! Total: "..bedBreaks,16776960)
                    end
                end)
            end
        end
        task.wait(2)
    end
end)

-- Victory detection
task.spawn(function()
    while true do
        task.wait(3)
        if BW.alive() then
            local enemyCount=0
            for _,p in pairs(BW.Players:GetPlayers()) do
                if p~=BW.LocalPlayer and p.Team~=BW.LocalPlayer.Team then
                    local c=p.Character
                    if c then local h=c:FindFirstChildOfClass("Humanoid") if h and h.Health>0 then enemyCount=enemyCount+1 end end
                end
            end
            if enemyCount==0 and BW.Flags.WH_Win then
                BW.SendWebhook("VICTORY!","Won! Kills: "..killCount,3066993)
            end
        end
    end
end)

-- Character respawn handler
BW.LocalPlayer.CharacterAdded:Connect(function(c)
    task.wait(1)
    local h=c:WaitForChild("Humanoid",5)
    if h then
        if BW.Flags.Speed then h.WalkSpeed=BW.Flags.SpeedVal or 32 end
        if BW.Flags.HighJump then h.JumpPower=BW.Flags.JumpPower or 100 end
    end
end)

-- Performance monitor
task.spawn(function()
    local perfGui=Instance.new("ScreenGui"); perfGui.Name="BW_Perf"; perfGui.ResetOnSpawn=false; perfGui.Parent=BW.LocalPlayer.PlayerGui
    local pf=Instance.new("Frame"); pf.Size=UDim2.new(0,160,0,80); pf.Position=UDim2.new(0,10,0,10); pf.BackgroundColor3=Color3.fromRGB(0,0,0); pf.BackgroundTransparency=0.5; pf.BorderSizePixel=0; pf.Parent=perfGui; Instance.new("UICorner",pf).CornerRadius=UDim.new(0,8)
    local fpsLbl=Instance.new("TextLabel",pf); fpsLbl.Size=UDim2.new(1,-10,0,20); fpsLbl.Position=UDim2.new(0,5,0,5); fpsLbl.BackgroundTransparency=1; fpsLbl.Text="FPS: 60"; fpsLbl.TextColor3=Color3.fromRGB(0,255,0); fpsLbl.TextSize=12; fpsLbl.Font=Enum.Font.GothamBold; fpsLbl.TextXAlignment=Enum.TextXAlignment.Left
    local memLbl=Instance.new("TextLabel",pf); memLbl.Size=UDim2.new(1,-10,0,20); memLbl.Position=UDim2.new(0,5,0,25); memLbl.BackgroundTransparency=1; memLbl.Text="MEM: 0 MB"; memLbl.TextColor3=Color3.fromRGB(255,255,0); memLbl.TextSize=12; memLbl.Font=Enum.Font.GothamBold; memLbl.TextXAlignment=Enum.TextXAlignment.Left
    local modLbl=Instance.new("TextLabel",pf); modLbl.Size=UDim2.new(1,-10,0,20); modLbl.Position=UDim2.new(0,5,0,45); modLbl.BackgroundTransparency=1; modLbl.Text="Modules: 0"; modLbl.TextColor3=Color3.fromRGB(100,200,255); modLbl.TextSize=12; modLbl.Font=Enum.Font.GothamBold; modLbl.TextXAlignment=Enum.TextXAlignment.Left
    pf.Visible=false
    BW.UserInputService.InputBegan:Connect(function(input,gp) if not gp and input.KeyCode==Enum.KeyCode.F3 then pf.Visible=not pf.Visible end end)
    while true do
        if pf.Visible then
            fpsLbl.Text="FPS: "..BW.Perf.FPS
            local mem=BW.Perf:GetMemory(); memLbl.Text="MEM: "..mem.." MB"
            local active=0; for _,v in pairs(BW.Flags) do if v==true then active=active+1 end end
            modLbl.Text="Modules: "..active
        end
        task.wait(0.5)
    end
end)

-- Garbage collection
task.spawn(function()
    while true do pcall(collectgarbage, "collect"); pcall(collectgarbage, "collect"); task.wait(30) end
end)

-- Init
BW.SendWebhook("Script Loaded","BedWars Ultimate v4.4 loaded by **"..BW.LocalPlayer.Name.."**",3447003)
BW.StarterGui:SetCore("SendNotification",{Title="BedWars Ultimate v4.4",Text="PC".." | "..(BW.isMobile and "Touch ready!" or "RightAlt to toggle"),Duration=5})
print("[Events] Module loaded")
print("[BedWars Ultimate v4.4] All modules loaded! Device: ".."PC")
print("Press F3 for performance monitor | RightAlt to toggle UI")
