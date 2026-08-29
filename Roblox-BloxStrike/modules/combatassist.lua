

-- BLOXSTRIKE COMBAT ASSIST MODULE v1.0
-- Chat Assistant, Spectator Detection, Player Rating, Map Memory

local Players = nil

pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local UserInputService = nil
pcall(function() UserInputService = game:GetService("UserInputService") end)
local ReplicatedStorage = nil
pcall(function() ReplicatedStorage = game:GetService("ReplicatedStorage") end)
local StarterGui = nil
pcall(function() StarterGui = game:GetService("StarterGui") end)
local HttpService = nil
pcall(function() HttpService = game:GetService("HttpService") end)
local lplr = Players.LocalPlayer

if not BS.Win then warn("[Combat Assist] BS.Win not available - ui.lua may have failed") return end
local page = BS.Win:Tab("AIM")
if not page or not page.Toggle then warn("[CombatAssist] Failed to create tab!") return end

local CA = {}
BS.CombatAssist = CA

 -- Persistent State
CA.PlayerRatings = {} -- {userId = {name, rating, kills, deaths, headshots, lastSeen, notes}}
CA.Spectators = {} -- {userId = {name, since, duration}}
CA.MapMemory = {} -- {placeId = {name, lastPlayed, rounds, wins, notes}}
CA.SessionStats = {
    Kills = 0, Deaths = 0, Headshots = 0, Shots = 0,
    HitCount = 0, DamageDealt = 0, Accuracy = 0,
    -- StartTime = tick(),
    KillStreak = 0, MaxKillStreak = 0,
}

-- SECTION 1: CHAT ASSISTANT
-- Auto-reply, taunts, callouts, vote manipulation

page:Label("  ")
page:Toggle("Chat Assistant", false, function(v) Flags.ChatAssistant = v end)
page:Toggle("Auto Reply", false, function(v) Flags.ChatAutoReply = v end)
page:Toggle("Auto Taunt on Kill", false, function(v) Flags.ChatAutoTaunt = v end)
page:Toggle("Auto GG", false, function(v) Flags.ChatAutoGG = v end)
page:Toggle("Auto Team Callout", false, function(v) Flags.ChatAutoCallout = v end)
page:Toggle("Spam Blocked Bypass", false, function(v) Flags.ChatSpamBypass = v end)
page:Slider("Chat Delay", 1, 10, 3, function(v) Flags.ChatDelay = v end)
page:Dropdown({Name="Chat Style", Flag="ChatStyle", Options={"Normal","Toxic","Nice","Chinese","Random"}, Default="Normal"})
page:Button({Name="Send Custom Message", Color=Color3.fromRGB(80, 80, 200)}, function()
    -- Open a simple chat input prompt
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = " Chat Assistant",
            Text = "Type your message in game chat, it will be enhanced!",
            Duration = 3,
        })
    end)
end)

 -- Chat Databases
local TAUNTS = {
    Normal = {
        -- "nice shot", "good try", "ez", "gg", "where", "close one",
        -- "too slow", "whiffed", "nice peek", "atomized", "next",
        -- "sit", "one tap", "clean", "diff", "gap", "trash",
    },
    Toxic = {
        -- "sit down", "absolute trash", "too easy", "braindead peek",
        -- "nice whiff lol", "gap diff", "bot lobby", "uninstall",
        -- "where aim?", "0 IQ play", "free elo", "next bot please",
        -- "you're not him", "warmup btw", "not even trying",
    },
    Nice = {
        -- "nice try!", "good round", "well played", "you're good!",
        -- "close match!", "that was clean", "respect", "wp wp",
        -- "gg no re", "fun game", "that peek was sick",
    },
    Chinese = {
        -- "nice", "666", "", "", " gg ", "",
        -- "", "?", "", "", "",
        -- "", "", "", "", "",
    },
}

local CALL_PLAYER = {
    -- "He's low HP!", "One tap!", "He's lit!", "Nice trade!",
    -- "He's pushing!", "Crossfire!", "He's alone!", "Flanking!",
    -- "Flash out!", "Smoke out!", "He's behind!", "Rotate!",
    -- "A site!", "B site!", "Mid!", "Careful left!",
    -- "No armor!", "Sniper!", "He's close!", "Watch pit!",
}

local GG_MESSAGES = {
    -- "gg", "gg wp", "nice game", "well played", "fun match",
    -- "good lobby", "gg ez", "gg close", "wp everyone",
}

local AUTO_REPLY_MESSAGES = {
    ["are you cheating"] = {
    -- ["cheater"] = {"coping", "mad", "skill issue", "ratio", "cry more"},
    -- ["hacker"] = {"hold this L", "mad cause bad", "stay mad", "lol"},
    ["ez"] = {"sure buddy", "cry", "gg tho", "gg wp"},
    ["gg"] = {"gg wp", "gg", "nice game", "wp"},
    ["noob"] = {"check scoreboard", "ratio", "sit", "look at my KD"},
    ["bad"] = {"check scoreboard", "look at deaths", "who's bad?"},
    ["trash"] = {"stay mad", "check scoreboard", "ratio + L"},
    ["wow"] = {"get good", "ez", "next", "try harder"},
    ["how"] = {"practice", "skill", "just aim", "get good"},
    },
}

 -- Chat Assistant Engine
local chatState = {
    LastMessageTime = 0,
    MessageQueue = {},
    IsProcessing = false,
    LastTauntTime = 0,
}

-- Enhanced chat send with bypass for spam detection
function CA.sendChat(message)
    if not message or message == "" then return end

    local delay = (Flags.ChatDelay or 3) / 10

    -- Add small random delay to look human
    task.delay(delay + math.random() * 0.5, function()
        pcall(function()
            -- Method 1: TextChatService (new)
            local textChat = nil
            pcall(function() textChat = game:GetService("TextChatService") end)
            if textChat and textChat.TextChannels then
                local channel = textChat.TextChannels:FindFirstChild("RBXGeneral")
                if channel then
                    -- channel:SendAsync(message)
                    -- return
                end
            end

            -- Method 2: Legacy chat
            local chatRemote = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if chatRemote then
                local sayEvent = chatRemote:FindFirstChild("SayMessageRequest")
                if sayEvent then
                    -- sayEvent:FireServer(message, "All")
                    -- return
                end
            end

            -- Method 3: Direct SayMessageRequest
            for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
                if obj:IsA("RemoteEvent") and obj.Name:find("SayMessage") then
                    -- obj:FireServer(message, "All")
                    -- return
                end
            end

            -- Method 4: Player chatted (fallback)
            pcall(function()
                game:GetService("TextChatService").TextChannels.RBXGeneral:SendAsync(message)
            end)
        end)
    end)
end

-- Get random message from database
function CA.getRandomTaunt(style)
    style = style or Flags.ChatStyle or "Normal"
    local db = TAUNTS[style] or TAUNTS.Normal
    return db[math.random(#db)]
end

-- Listen for incoming messages
local chatConnections = {}

function CA.startChatListener()
    -- Disconnect old
    for _, conn in ipairs(chatConnections) do
        pcall(function() conn:Disconnect() end)
    end
    chatConnections = {}

    -- New chat system
    pcall(function()
        local textChat = nil
        pcall(function() textChat = game:GetService("TextChatService") end)
        if textChat and textChat.TextChannels then
            local channel = textChat.TextChannels:FindFirstChild("RBXGeneral")
            if channel then
                local conn = channel.MessageReceived:Connect(function(message)
                    if not Flags.ChatAssistant then return end
                    local sender = message.TextSource
                    local playerName = sender and Players:GetNameFromUserIdAsync(message.TextSource.UserId) or ""
                    local text = message.Text:lower()

                    -- Auto reply
                    if Flags.ChatAutoReply then
                        for trigger, replies in pairs(AUTO_REPLY_MESSAGES) do
                            if text:find(trigger) then
                                CA.sendChat(replies[math.random(#replies)])
                                break
                            end
                        end
                    end
                end)
                table.insert(chatConnections, conn)
            end
        end
    end)

    -- Legacy chat system
    pcall(function()
        local chatEvent = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if chatEvent then
            local onMsg = chatEvent:FindFirstChild("OnMessageDoneFiltering")
            if onMsg then
                local conn = onMsg.OnClientEvent:Connect(function(data)
                    if not Flags.ChatAssistant then return end
                    local speaker = data.SpeakerName or ""
                    local msg = data.Message or ""
                    local text = msg:lower()

                    if speaker == lplr.Name then return end

                    -- Auto reply
                    if Flags.ChatAutoReply then
                        for trigger, replies in pairs(AUTO_REPLY_MESSAGES) do
                            if text:find(trigger) then
                                CA.sendChat(replies[math.random(#replies)])
                                break
                            end
                        end
                    end
                end)
                table.insert(chatConnections, conn)
            end
        end
    end)
end

-- On kill: auto taunt
function CA.onKill(victimName, headshot)
    if not Flags.ChatAssistant then return end
    if Flags.ChatAutoTaunt and tick() - chatState.LastTauntTime > 5 then
        chatState.LastTauntTime = tick()
        local msg = CA.getRandomTaunt()
        if headshot then
            msg = msg .. " (HS)"
        end
        CA.sendChat(msg)
    end
end

-- On round end: auto GG
function CA.onRoundEnd()
    if not Flags.ChatAssistant then return end
    if Flags.ChatAutoGG then
        task.delay(2 + math.random() * 3, function()
            CA.sendChat(GG_MESSAGES[math.random(#GG_MESSAGES)])
        end)
    end
end

-- Team callout
function CA.sendCallout()
    if not Flags.ChatAutoCallout then return end
    CA.sendChat(CALL_PLAYER[math.random(#CALL_PLAYER)])
end

task.spawn(function() CA.startChatListener() end)

-- SECTION 2: SPECTATOR DETECTION
-- Detect who is watching you

page:Label("  ")
page:Toggle("Spectator List", false, function(v) Flags.SpectatorList = v end)
page:Toggle("Spectator Alert", false, function(v) Flags.SpectatorAlert = v end)
page:Toggle("Spectator History", true, function(v) Flags.SpectatorHistory = v end)
page:Toggle("Hide From Specific", false, function(v) Flags.HideSpectator = v end)
page:Slider("Scan Interval", 1, 10, 2, function(v) Flags.SpecScanInterval = v end)

 -- Spectator Detection Engine
local specState = {
    PreviousSpectators = {},
    SpectatingMe = {},
    TotalSpectators = 0,
    LastAlertTime = 0,
}

-- Detect spectators by monitoring camera subjects
task.spawn(function()
    while true do task.wait(Flags.SpecScanInterval or 2)
        if Flags.SpectatorList or Flags.SpectatorAlert then
            pcall(function()
                local newSpectators = {}

                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= lplr then
                        local cam = player.Character and player and player.Character:FindFirstChild("Humanoid")
                        if cam then
                            -- Check if their camera is following us
                            -- In Roblox, we can't directly check others' cameras
                            -- But we can check if they're in our server and observing
                        end

                        -- Check if player has no character (spectating)
                        local hasChar = player.Character and
                            player and player.Character:FindFirstChildOfClass("Humanoid") and
                            player and player.Character:FindFirstChildOfClass("Humanoid").Health > 0

                        if not hasChar then
                            -- Might be in spectator mode
                            table.insert(newSpectators, {
                                UserId = player.UserId,
                                Name = player.Name,
                                Since = specState.PreviousSpectators[player.UserId]
                                    and specState.PreviousSpectators[player.UserId].Since
                                    or tick(),
                            })
                        end

                        -- Alternative: Check if they're near us but not moving (watching)
                        if hasChar then
                            local myHRP = BS.hrp()
                            local theirHRP = player and player.Character:FindFirstChild("HumanoidRootPart")
                            local theirHum = player and player.Character:FindFirstChildOfClass("Humanoid")
                            if myHRP and theirHRP and theirHum then
                                local dist = (myHRP.Position - theirHRP.Position).Magnitude
                                local vel = theirHRP.AssemblyLinearVelocity.Magnitude
                                -- Close + not moving = likely spectating
                                if dist < 30 and vel < 1 then
                                    table.insert(newSpectators, {
                                        UserId = player.UserId,
                                        Name = player.Name,
                                        Since = specState.PreviousSpectators[player.UserId]
                                            and specState.PreviousSpectators[player.UserId].Since
                                            or tick(),
                                        Type = "Observer",
                                    })
                                end
                            end
                        end
                    end
                end

                -- Update state
                specState.SpectatingMe = newSpectators
                specState.TotalSpectators = #newSpectators

                -- Alert on new spectator
                if Flags.SpectatorAlert and #newSpectators > #specState.PreviousSpectators and tick() - specState.LastAlertTime > 10 then
                    specState.LastAlertTime = tick()
                    local names = {}
                    for _, s in ipairs(newSpectators) do table.insert(names, s.Name) end
                    pcall(function()
                         StarterGui:SetCore("SendNotification", {
                            Title = "[Spectator]",
                            -- Text = #newSpectators .. " : " .. table.concat(names, ", "),
                            Duration = 4,
                        })
                    end)
                end

                specState.PreviousSpectators = {}
                for _, s in ipairs(newSpectators) do
                    specState.PreviousSpectators[s.UserId] = s
                end
            end)
        end
    end
end)

CA.SpectatorState = specState

-- SECTION 3: PLAYER RATING SYSTEM
-- Rate and remember players across sessions

page:Label("  ")
page:Toggle("Player Rating", true, function(v) Flags.PlayerRating = v end)
page:Toggle("Auto Rate", true, function(v) Flags.AutoRate = v end)
page:Slider("Threat Threshold", 50, 100, 70, function(v) Flags.ThreatThreshold = v end)
page:Toggle("Show Player Tags", true, function(v) Flags.ShowPlayerTags = v end)
page:Button({Name="View Player Stats", Color=Color3.fromRGB(100, 200, 100)}, function()
    CA.showPlayerStats()
end)
page:Button({Name="Reset All Ratings", Color=Color3.fromRGB(200, 100, 100)}, function()
    CA.PlayerRatings = {}
    pcall(function()
         StarterGui:SetCore("SendNotification", {
            Title = " ",
            Text = "",
            Duration = 3,
        })
    end)
end)

 -- Player Rating Engine
local ratingState = {
    SessionEncounters = {}, -- Track who we've fought this session
    DamageLog = {}, -- Track damage dealt to each player
}

function CA.ratePlayer(player, rating, reason)
    if not player then return end
    local uid = player.UserId
    if not CA.PlayerRatings[uid] then
        CA.PlayerRatings[uid] = {
            Name = player.Name,
            Rating = 50, -- 0-100 (0=threat, 100=noob)
            Kills = 0,
            Deaths = 0,
            Headshots = 0,
            DamageDealt = 0,
            DamageReceived = 0,
            -- LastSeen = tick(),
            Notes = {},
            ThreatLevel = "Normal", -- Normal, Dangerous, Smurf, Cheater, Noob
        }
    end

    local p = CA.PlayerRatings[uid]
    p.Rating = math.clamp(rating or 50, 0, 100)
    p.LastSeen = tick()
    p.Name = player.Name

    if reason then
        table.insert(p.Notes, {Time = tick(), Note = reason})
        if #p.Notes > 20 then table.remove(p.Notes, 1) end
    end

    -- Auto-determine threat level
    if p.Rating <= 20 then
        p.ThreatLevel = "Cheater"
    elseif p.Rating <= 40 then
        p.ThreatLevel = "Dangerous"
    elseif p.Rating <= 60 then
        p.ThreatLevel = "Normal"
    elseif p.Rating <= 80 then
        p.ThreatLevel = "Noob"
    else
        p.ThreatLevel = "Free"
    end

    CA.PlayerRatings[uid] = p
end

function CA.onPlayerKill(victim)
    if not Flags.PlayerRating then return end
    local uid = victim.UserId
    if not CA.PlayerRatings[uid] then
        CA.ratePlayer(victim, 50)
    end
    CA.PlayerRatings[uid].Kills = CA.PlayerRatings[uid].Kills + 1
    CA.PlayerRatings[uid].Deaths = CA.PlayerRatings[uid].Deaths + 1 -- from their perspective
    CA.PlayerRatings[uid].LastSeen = tick()

    -- Lower rating = we killed them more = they're worse
    local kd = CA.PlayerRatings[uid].Kills / math.max(1, CA.PlayerRatings[uid].Deaths)
    local newRating = 50 + (CA.PlayerRatings[uid].Kills - CA.PlayerRatings[uid].Deaths) * 5
    CA.ratePlayer(victim, math.clamp(newRating, 0, 100), "Killed by us")
end

function CA.onPlayerDeath(killer)
    if not Flags.PlayerRating then return end
    if killer and killer:IsA("Player") then
        local uid = killer.UserId
        if not CA.PlayerRatings[uid] then
            CA.ratePlayer(killer, 50)
        end
        CA.PlayerRatings[uid].Deaths = CA.PlayerRatings[uid].Deaths + 1
        CA.PlayerRatings[uid].LastSeen = tick()

        local newRating = 50 - (CA.PlayerRatings[uid].Kills - CA.PlayerRatings[uid].Deaths) * 5
        CA.ratePlayer(killer, math.clamp(newRating, 0, 100), "Killed us")
    end
end

function CA.onDamageDealt(target, damage, headshot)
    if not Flags.PlayerRating then return end
    if target and target:IsA("Player") then
        local uid = target.UserId
        if not CA.PlayerRatings[uid] then
            CA.ratePlayer(target, 50)
        end
        CA.PlayerRatings[uid].DamageDealt = CA.PlayerRatings[uid].DamageDealt + damage
        if headshot then
            CA.PlayerRatings[uid].Headshots = CA.PlayerRatings[uid].Headshots + 1
        end

        -- Adjust rating based on damage dealt vs received
        local dmgRatio = CA.PlayerRatings[uid].DamageDealt / math.max(1, CA.PlayerRatings[uid].DamageReceived)
        local newRating = 50 + (dmgRatio - 1) * 10
        CA.ratePlayer(target, math.clamp(newRating, 0, 100))
    end
end

function CA.showPlayerStats()
    local top5 = {}
    for uid, data in pairs(CA.PlayerRatings) do
        table.insert(top5, data)
    end
    table.sort(top5, function(a, b) return a.Rating < b.Rating end)

    local msg = "  (Top 5 ):\n"
    for i = 1, math.min(5, #top5) do
        local p = top5[i]
        msg = msg .. string.format("%d. %s [%s] K:%d D:%d\n",
            i, p.Name, p.ThreatLevel, p.Kills, p.Deaths)
    end

    pcall(function()
         StarterGui:SetCore("SendNotification", {
            Title = " ",
            Text = msg,
            Duration = 8,
        })
    end)
end

CA.RatingState = ratingState

-- SECTION 4: MAP MEMORY
-- Remember settings per map

page:Label("  ")
page:Toggle("Map Memory", true, function(v) Flags.MapMemory = v end)
page:Toggle("Auto Apply Settings", false, function(v) Flags.MapAutoApply = v end)
page:Toggle("Record Performance", true, function(v) Flags.MapRecordPerf = v end)
page:Button({Name="Save Current Map Settings", Color=Color3.fromRGB(100, 150, 255)}, function()
    CA.saveMapSettings()
end)
page:Button({Name="Show Map Stats", Color=Color3.fromRGB(255, 150, 100)}, function()
    CA.showMapStats()
end)

 -- Map Memory Engine
local mapState = {
    CurrentMap = nil,
    -- MapStartTime = tick(),
    RoundsPlayed = 0,
    Wins = 0,
    Losses = 0,
    BestScore = 0,
    WorstScore = math.huge,
    AverageFPS = 60,
    FPSReadings = {},
}

function CA.saveMapSettings()
    local placeId = game.PlaceId
    local placeName = game:GetService("MarketplaceService"):GetProductInfo(placeId).Name or "Unknown"

    CA.MapMemory[placeId] = {
        Name = placeName,
        -- LastPlayed = tick(),
        Rounds = mapState.RoundsPlayed,
        Wins = mapState.Wins,
        Losses = mapState.Losses,
        BestScore = mapState.BestScore,
        AverageFPS = mapState.AverageFPS,
        -- Save current feature settings
        Settings = {
            AimbotFOV = Flags.AimbotFOV,
            AimbotSmooth = Flags.AimbotSmooth,
            ESP_Box = Flags.ESP_Box,
            ESP_Name = Flags.ESP_Name,
            ESP_Health = Flags.ESP_Health,
            ESP_Dist = Flags.ESP_Dist,
            Ragebot = Flags.Ragebot,
            AntiAim = Flags.AA,
        },
    }

    -- Save to file
    pcall(function()
        local json = HttpService:JSONEncode(CA.MapMemory)
        writefile("BloxStrike/MapMemory.json", json)
    end)

    pcall(function()
         StarterGui:SetCore("SendNotification", {
            Title = " ",
            Text = " " .. placeName .. " ",
            Duration = 3,
        })
    end)
end

function CA.loadMapSettings()
    local placeId = game.PlaceId
    if not CA.MapMemory[placeId] then return end

    local saved = CA.MapMemory[placeId]
    if saved.Settings and Flags.MapAutoApply then
        for key, value in pairs(saved.Settings) do
            Flags[key] = value
        end
    end

    pcall(function()
         StarterGui:SetCore("SendNotification", {
            Title = " ",
            Text = string.format(" %s  (: %.0f%%)",
                saved.Name or "Unknown",
                saved.Wins / math.max(1, saved.Wins + saved.Losses) * 100),
            Duration = 4,
        })
    end)
end

function CA.showMapStats()
    local placeId = game.PlaceId
    local info = CA.MapMemory[placeId]
    if not info then
        pcall(function()
             StarterGui:SetCore("SendNotification", {
                Title = " ",
                Text = "",
                Duration = 3,
            })
        end)
        -- return
    end

    local winRate = info.Wins / math.max(1, info.Wins + info.Losses) * 100
    pcall(function()
         StarterGui:SetCore("SendNotification", {
            Title = " ",
            Text = string.format("%s\n: %d | : %d | : %d | : %.0f%%\nFPS: %.0f",
                info.Name or "Unknown", info.Rounds, info.Wins, info.Losses,
                winRate, info.AverageFPS or 0),
            Duration = 6,
        })
    end)
end

-- Load saved map data on startup
pcall(function()
    if isfile and isfile("BloxStrike/MapMemory.json") then
        CA.MapMemory = HttpService:JSONDecode(readfile("BloxStrike/MapMemory.json"))
    end
end)

-- Track current map
task.spawn(function()
    while true do task.wait(5)
        if Flags.MapMemory then
            local placeId = game.PlaceId
            if mapState.CurrentMap ~= placeId then
                mapState.CurrentMap = placeId
                mapState.MapStartTime = tick()
                mapState.RoundsPlayed = 0
                mapState.Wins = 0
                mapState.Losses = 0
                CA.loadMapSettings()
            end

            -- Track FPS for this map
            if Flags.MapRecordPerf and BS.Perf then
                table.insert(mapState.FPSReadings, BS.Perf.FPS)
                if #mapState.FPSReadings > 100 then table.remove(mapState.FPSReadings, 1) end
                local sum = 0
                for _, v in ipairs(mapState.FPSReadings) do sum = sum + v end
                mapState.AverageFPS = sum / #mapState.FPSReadings
            end
        end
    end
end)

CA.MapState = mapState

-- SECTION 5: SESSION STATISTICS
-- Track session performance

page:Label("  ")
page:Toggle("Session Stats", true, function(v) Flags.SessionStats = v end)
page:Button({Name="Show Session Stats", Color=Color3.fromRGB(200, 200, 100)}, function()
    CA.showSessionStats()
end)
page:Button({Name="Reset Session Stats", Color=Color3.fromRGB(200, 100, 100)}, function()
    CA.SessionStats = {
        Kills = 0, Deaths = 0, Headshots = 0, Shots = 0,
        HitCount = 0, DamageDealt = 0, Accuracy = 0,
        -- StartTime = tick(), KillStreak = 0, MaxKillStreak = 0,
    }
end)

function CA.showSessionStats()
    local s = CA.SessionStats
    local elapsed = math.floor((tick() - s.StartTime) / 60)
    local kd = s.Deaths > 0 and string.format("%.2f", s.Kills / s.Deaths) or ""
    local hsRate = s.Kills > 0 and string.format("%.0f%%", s.Headshots / s.Kills * 100) or "0%"
    local acc = s.Shots > 0 and string.format("%.1f%%", s.HitCount / s.Shots * 100) or "0%"

    pcall(function()
         StarterGui:SetCore("SendNotification", {
            Title = "BloxStrike",
            Text = "Kills: " .. tostring(s.Kills) .. " Deaths: " .. tostring(s.Deaths) .. " KD: " .. tostring(kd),
            Duration = 8,
        })
    end)
end

 -- Expose
BS.CombatAssist = CA
BS.CA = CA

print("[CombatAssist] BloxStrike Combat Assist v1.0 loaded")
print("[CombatAssist] Features: Chat Assistant, Spectator Detection,")
print("[CombatAssist]   Player Rating, Map Memory, Session Stats"
