

-- BLOXSTRIKE EVENTS MODULE v1.0
-- Kill/Death/Round/Bomb tracking + Webhook integration

local Players = nil

pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local lplr = Players.LocalPlayer

 -- Session Stats
local Stats = {
    Kills = 0,
    Deaths = 0,
    Headshots = 0,
    KillStreak = 0,
    BestStreak = 0,
    RoundWins = 0,
    RoundLosses = 0,
    BombsPlanted = 0,
    BombsDefused = 0,
    Money = 0,
    -- StartTime = tick(),
}

BS.Stats = Stats

-- KILL TRACKING

local prevHealth = {}

task.spawn(function()
    while true do
        task.wait(0.3)
        pcall(function()
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= lplr and player.Character then
                    local hum = player and player.Character:FindFirstChildOfClass("Humanoid")
                    if hum then
                        local prevHP = prevHealth[player.UserId] or hum.Health

                        -- Detect kill (health went from >0 to 0)
                        if prevHP > 0 and hum.Health <= 0 then
                            -- Check if we killed them (not team kill)
                            local isEnemy = true
                            if lplr.Team and player.Team == lplr.Team then
                                isEnemy = false
                            end

                            if isEnemy then
                                Stats.Kills = Stats.Kills + 1
                                Stats.KillStreak = Stats.KillStreak + 1

                                -- Track best streak
                                if Stats.KillStreak > Stats.BestStreak then
                                    Stats.BestStreak = Stats.KillStreak
                                end

                                -- Get weapon info
                                local tool = lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
                                local weaponName = tool and tool.Name or "Unknown"

                                -- Fire webhook
                                if BS.Webhook and Flags.WebhookOnKill then
                                    BS.Webhook.onKill(player, Stats.Kills, weaponName)
                                end

                                -- Kill streak webhook
                                if BS.Webhook and Flags.WebhookOnKillStreak then
                                    local streaks = {3, 5, 7, 10, 15, 20}
                                    for _, s in ipairs(streaks) do
                                        if Stats.KillStreak == s then
                                            BS.Webhook.onKillStreak(Stats.KillStreak)
                                            break
                                        end
                                    end
                                end

                                -- In-game notification
                                pcall(function()
                                    game:GetService("StarterGui"):SetCore("SendNotification", {
                                        Title = " Kill #" .. Stats.Kills,
                                        Text = "Eliminated " .. player.DisplayName,
                                        Duration = 2,
                                    })
                                end)
                            end
                        end

                        prevHealth[player.UserId] = hum.Health
                    end
                end
            end
        end)
    end
end)

-- DEATH TRACKING

task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            local char = lplr.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    -- Connect to Died event (only once per character)
                    if not hum:GetAttribute("BS_DeathConnected") then
                        -- hum:SetAttribute("BS_DeathConnected", true)
                        hum.Died:Connect(function()
                            Stats.Deaths = Stats.Deaths + 1
                            Stats.KillStreak = 0 -- Reset streak on death

                            -- Fire webhook
                            if BS.Webhook and Flags.WebhookOnDeath then
                                BS.Webhook.onDeath(Stats.Deaths, nil)
                            end

                            -- In-game notification
                            pcall(function()
                                game:GetService("StarterGui"):SetCore("SendNotification", {
                                    Title = " Death #" .. Stats.Deaths,
                                    Text = "Respawning...",
                                    Duration = 2,
                                })
                            end)
                        end)
                    end
                end
            end
        end)
    end
end)

-- ROUND TRACKING

local prevRound = 0

task.spawn(function()
    while true do
        task.wait(2)
        pcall(function()
            -- Try to detect round changes from game state
            local state = BS.api and BS.api.getGameState and BS.api.getGameState() or {}
            local currentRound = state.round or state.Round or 0

            if currentRound ~= prevRound and prevRound > 0 then
                -- Round changed - check if we won or lost
                -- This is a heuristic based on survival
                if BS.alive() then
                    Stats.RoundWins = Stats.RoundWins + 1
                    if BS.Webhook and Flags.WebhookOnRoundEnd then
                        BS.Webhook.onRoundWin(Stats.Kills, Stats.Deaths,
                            Stats.RoundWins .. "-" .. Stats.RoundLosses)
                    end
                else
                    Stats.RoundLosses = Stats.RoundLosses + 1
                    if BS.Webhook and Flags.WebhookOnRoundEnd then
                        BS.Webhook.onRoundLose(Stats.Kills, Stats.Deaths,
                            Stats.RoundWins .. "-" .. Stats.RoundLosses)
                    end
                end
            end
            prevRound = currentRound
        end)
    end
end)

-- BOMB TRACKING

task.spawn(function()
    local bombTracked = false

    while true do
        task.wait(1)
        pcall(function()
            local bomb = BS.api and BS.api.getBomb and BS.api.getBomb()

            if bomb and not bombTracked then
                bombTracked = true
                Stats.BombsPlanted = Stats.BombsPlanted + 1

                -- Check if we planted it
                if bomb:GetAttribute("PlantedBy") == lplr.UserId
                    or (bomb:FindFirstChild("Owner") and bomb.Owner.Value == lplr) then
                    if BS.Webhook and Flags.WebhookOnBomb then
                        local site = BS.api.getBombSite and BS.api.getBombSite() or "?"
                        BS.Webhook.onBombPlanted(site, lplr)
                    end
                end

                -- Track bomb explosion/defuse
                task.spawn(function()
                    local startTime = tick()
                    while bomb and bomb.Parent do
                        task.wait(0.5)
                        if tick() - startTime > 45 then
                            -- Bomb exploded
                            if BS.Webhook and Flags.WebhookOnBomb then
                                BS.Webhook.onBombExplode()
                            end
                            break
                        end
                    end
                    bombTracked = false
                end)
            end

            -- Track defuse (bomb disappears before timer expires)
            if not bomb and bombTracked then
                bombTracked = false
                Stats.BombsDefused = Stats.BombsDefused + 1
                if BS.Webhook and Flags.WebhookOnBomb then
                    BS.Webhook.onBombDefused(lplr, BS.api.hasDefuseKit and BS.api.hasDefuseKit())
                end
            end
        end)
    end
end)

-- MATCH START/END

-- Script loaded notification
task.wait(2)
if BS.Webhook and Flags.WebhookOnLoad then
    BS.Webhook.onScriptLoad()
end

-- PERFORMANCE MONITOR (F3 key)

local perfGui

task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            if Flags.PerfMonitor then
                if not perfGui then
                    perfGui = Instance.new("ScreenGui")
                    perfGui.Name = "BS_Perf"
                    perfGui.ResetOnSpawn = false
                    perfGui.Parent = lplr.PlayerGui

                    local frame = Instance.new("Frame")
                    frame.Size = UDim2.new(0, 180, 0, 100)
                    frame.Position = UDim2.new(1, -190, 0, 10)
                    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    frame.BackgroundTransparency = 0.4
                    frame.BorderSizePixel = 0
                    frame.Parent = perfGui

                    local corner = Instance.new("UICorner")
                    corner.CornerRadius = UDim.new(0, 8)
                    corner.Parent = frame

                    local fpsLabel = Instance.new("TextLabel")
                    fpsLabel.Name = "FPS"
                    fpsLabel.Size = UDim2.new(1, -10, 0, 20)
                    fpsLabel.Position = UDim2.new(0, 5, 0, 5)
                    fpsLabel.BackgroundTransparency = 1
                    fpsLabel.Text = "FPS: 60"
                    fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                    fpsLabel.TextSize = 12
                    fpsLabel.Font = Enum.Font.Code
                    fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
                    fpsLabel.Parent = frame

                    local statsLabel = Instance.new("TextLabel")
                    statsLabel.Name = "Stats"
                    statsLabel.Size = UDim2.new(1, -10, 0, 20)
                    statsLabel.Position = UDim2.new(0, 5, 0, 25)
                    statsLabel.BackgroundTransparency = 1
                    statsLabel.Text = "K/D: 0/0"
                    statsLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                    statsLabel.TextSize = 12
                    statsLabel.Font = Enum.Font.Code
                    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
                    statsLabel.Parent = frame

                    local modsLabel = Instance.new("TextLabel")
                    modsLabel.Name = "Mods"
                    modsLabel.Size = UDim2.new(1, -10, 0, 20)
                    modsLabel.Position = UDim2.new(0, 5, 0, 45)
                    modsLabel.BackgroundTransparency = 1
                    modsLabel.Text = "Active: 0"
                    modsLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
                    modsLabel.TextSize = 12
                    modsLabel.Font = Enum.Font.Code
                    modsLabel.TextXAlignment = Enum.TextXAlignment.Left
                    modsLabel.Parent = frame

                    local webhookLabel = Instance.new("TextLabel")
                    webhookLabel.Name = "Webhook"
                    webhookLabel.Size = UDim2.new(1, -10, 0, 20)
                    webhookLabel.Position = UDim2.new(0, 5, 0, 65)
                    webhookLabel.BackgroundTransparency = 1
                    webhookLabel.Text = "Webhook: OFF"
                    webhookLabel.TextColor3 = Color3.fromRGB(200, 100, 255)
                    webhookLabel.TextSize = 12
                    webhookLabel.Font = Enum.Font.Code
                    webhookLabel.TextXAlignment = Enum.TextXAlignment.Left
                    webhookLabel.Parent = frame
                end

                perfGui.Enabled = true

                -- Update display
                local frame = perfGui:FindFirstChild("Frame")
                if frame then
                    local fps = frame:FindFirstChild("FPS")
                    if fps then
                        fps.Text = "FPS: " .. (BS.Perf and BS.Perf.FPS or 0)
                    end
                    local stats = frame:FindFirstChild("Stats")
                    if stats then
                        stats.Text = string.format("K/D: %d/%d | Streak: %d",
                            -- Stats.Kills, Stats.Deaths, Stats.KillStreak)
                    end
                    local mods = frame:FindFirstChild("Mods")
                    if mods then
                        local active = 0
                        for _, v in pairs(Flags) do
                            if v == true then active = active + 1 end
                        end
                        mods.Text = "Active: " .. active .. " | R: " .. Stats.RoundWins .. "W/" .. Stats.RoundLosses .. "L"
                    end
                    local wh = frame:FindFirstChild("Webhook")
                    if wh then
                        wh.Text = "Webhook: " .. (BS.Webhook and BS.Webhook.URL ~= "" and "ON " or "OFF ")
                    end
                end
            else
                if perfGui then perfGui.Enabled = false end
            end
        end)
    end
end)

-- Toggle perf monitor with F3
BS.UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F3 then
        Flags.PerfMonitor = not Flags.PerfMonitor
    end
end)

print("[Events] BloxStrike Events module loaded")
print("[Events] Tracking: Kill/Death/Streak/Round/Bomb | Press F3 for stats")
