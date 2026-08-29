

-- BLOXSTRIKE DISCORD WEBHOOK MODULE v1.0
-- Send rich embeds to Discord for kills, deaths, rounds, bombs

local HttpService = nil

pcall(function() HttpService = game:GetService("HttpService") end)
local Players = nil
pcall(function() Players = game:GetService("Players") end)
local lplr = Players.LocalPlayer

local Webhook = {}

 -- Config
Webhook.URL = ""
Webhook.Queue = {}
Webhook.QueueInterval = 5 -- seconds between flush
Webhook.LastFlush = 0
Webhook.Enabled = true

 -- Discord Embed Color Constants (Decimal)
Webhook.Colors = {
    Kill        = 15158332,  -- #E74C3C Red
    Death       = 15158332,  -- #E74C3C Red
    Headshot    = 16711680,  -- #FF0000 Bright Red
    RoundWin    = 3066993,   -- #2ECC71 Green
    RoundLose   = 15158332,  -- #E74C3C Red
    BombPlant   = 16753920,  -- #FFA500 Orange
    BombDefuse  = 10181046,  -- #9B59B6 Purple
    BombExplode = 16711680,  -- #FF0000 Red
    ScriptLoad  = 3447003,   -- #3498DB Blue
    KillStreak  = 16766720,  -- #FFD700 Gold
    MatchStart  = 8947848,   -- #888888 Gray
    MatchEnd    = 3447003,   -- #3498DB Blue
    Money       = 5763719,   -- #57F287 Green
    Squad       = 3447003,   -- #3498DB Blue
}

 -- Color name lookup
Webhook.ColorNames = {}
for name, color in pairs(Webhook.Colors) do
    Webhook.ColorNames[name] = color
end

 -- Get Roblox Thumbnail URL
function Webhook.getAvatarURL(userId)
    return "https://www.roblox.com/headshot-thumbnail/image?userId="
        -- .. tostring(userId) .. "&width=420&height=420&format=png"
end

 -- Send Raw Webhook
function Webhook.send(payload)
    if not Webhook.Enabled then return false end
    if not Webhook.URL or Webhook.URL == "" then return false end

    pcall(function()
        local body = HttpService:JSONEncode(payload)
        local headers = { ["Content-Type"] = "application/json" }
        -- Use compat layer first, then fallback
        local Compat = _G.BS and _G.BS.Compat
        if Compat and Compat.HttpRequest then
            Compat.HttpRequest({
                Url = Webhook.URL,
                Method = "POST",
                Headers = headers,
                Body = body,
            })
        elseif syn and syn.request then
            syn.request({ Url = Webhook.URL, Method = "POST", Headers = headers, Body = body })
        elseif http_request then
            http_request({ Url = Webhook.URL, Method = "POST", Headers = headers, Body = body })
        elseif request then
            request({ Url = Webhook.URL, Method = "POST", Headers = headers, Body = body })
        end
    end)
    return true
end

 -- Send Simple Message
function Webhook.message(content, username)
    return Webhook.send({
        content = content,
        username = username or "BloxStrike",
    })
end

 -- Send Rich Embed
function Webhook.embed(config)
    local embed = {
        title = config.title or "BloxStrike",
        description = config.description or "",
        color = config.color or Webhook.Colors.ScriptLoad,
        footer = {
            text = config.footer or ("BloxStrike | " .. os.date("%H:%M:%S")),
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    }

    -- Add fields if provided
    if config.fields then
        embed.fields = {}
        for _, field in ipairs(config.fields) do
            table.insert(embed.fields, {
                name = field.name or "",
                value = field.value or "",
                inline = field.inline ~= false,
            })
        end
    end

    -- Add thumbnail (player avatar)
    if config.thumbnail then
        embed.thumbnail = { url = config.thumbnail }
    end

    -- Add author
    if config.author then
        embed.author = {
            name = config.author.name or "",
            icon_url = config.author.icon_url or "",
            url = config.author.url or "",
        }
    end

    return Webhook.send({
        embeds = { embed },
        username = config.username or "BloxStrike",
        avatar_url = config.avatar_url or "",
    })
end

 -- Queue Message (for rate limit safety)
function Webhook.queue(payload)
    table.insert(Webhook.Queue, payload)
end

function Webhook.flush()
    if #Webhook.Queue == 0 then return end

    local now = tick()
    if now - Webhook.LastFlush < Webhook.QueueInterval then return end
    Webhook.LastFlush = now

    -- Batch up to 5 embeds
    local batch = {}
    local count = math.min(#Webhook.Queue, 5)
    for i = 1, count do
        local payload = table.remove(Webhook.Queue, 1)
        if payload.embeds then
            for _, embed in ipairs(payload.embeds) do
                table.insert(batch, embed)
            end
        end
    end

    if #batch > 0 then
        Webhook.send({
            embeds = batch,
            username = "BloxStrike",
        })
    end
end

-- Start flush timer
task.spawn(function()
    while true do
        task.wait(Webhook.QueueInterval)
        -- Webhook.flush()
    end
end)

-- PRESET EVENT FUNCTIONS

--- Kill event
---@param victim Player - the player who was killed
---@param killCount number - total kills this session
---@param weapon string - weapon used
function Webhook.onKill(victim, killCount, weapon)
    Webhook.embed({
        title = " Kill #" .. killCount,
        description = "Eliminated **" .. victim.DisplayName .. "**",
        color = Webhook.Colors.Kill,
        thumbnail = Webhook.getAvatarURL(victim.UserId),
        fields = {
            { name = "Victim", value = victim.Name, inline = true },
            { name = "Weapon", value = weapon or "Unknown", inline = true },
            { name = "Total Kills", value = tostring(killCount), inline = true },
        },
    })
end

--- Headshot kill event
---@param victim Player
---@param killCount number
function Webhook.onHeadshot(victim, killCount)
    Webhook.embed({
        title = " Headshot #" .. killCount,
        description = "Headshot **" .. victim.DisplayName .. "**!",
        color = Webhook.Colors.Headshot,
        thumbnail = Webhook.getAvatarURL(victim.UserId),
        fields = {
            { name = "Victim", value = victim.Name, inline = true },
            { name = "Total Kills", value = tostring(killCount), inline = true },
        },
    })
end

--- Death event
---@param deathCount number
---@param killer Player|nil - who killed you (if known)
function Webhook.onDeath(deathCount, killer)
    local desc = "You were eliminated!"
    if killer then
        desc = desc .. "\nKilled by **" .. killer.DisplayName .. "**"
    end

    Webhook.embed({
        title = " Death #" .. deathCount,
        description = desc,
        color = Webhook.Colors.Death,
        fields = {
            { name = "Total Deaths", value = tostring(deathCount), inline = true },
        },
    })
end

--- Kill streak event
---@param streak number
function Webhook.onKillStreak(streak)
    local titles = {
        -- [3] = " Triple Kill!",
        -- [4] = " Quadra Kill!",
        -- [5] = " PENTA KILL!",
        -- [7] = " UNSTOPPABLE!",
        -- [10] = " GODLIKE!",
    }
    local title = titles[streak] or (" " .. streak .. " Kill Streak!")

    Webhook.embed({
        title = title,
        description = "You're on a **" .. streak .. " kill streak**!",
        color = Webhook.Colors.KillStreak,
    })
end

--- Round win
---@param kills number
---@param deaths number
---@param score string - e.g. "13-11"
function Webhook.onRoundWin(kills, deaths, score)
    Webhook.embed({
        title = " ROUND WIN!",
        description = "Your team won the round!",
        color = Webhook.Colors.RoundWin,
        fields = {
            { name = "Score", value = score or "N/A", inline = true },
            { name = "K/D", value = kills .. "/" .. deaths, inline = true },
        },
    })
end

--- Round lose
---@param kills number
---@param deaths number
---@param score string
function Webhook.onRoundLose(kills, deaths, score)
    Webhook.embed({
        title = " ROUND LOST",
        description = "Your team lost the round.",
        color = Webhook.Colors.RoundLose,
        fields = {
            { name = "Score", value = score or "N/A", inline = true },
            { name = "K/D", value = kills .. "/" .. deaths, inline = true },
        },
    })
end

--- Match start
function Webhook.onMatchStart(mapName)
    Webhook.embed({
        title = " Match Started",
        description = "A new match has begun!",
        color = Webhook.Colors.MatchStart,
        fields = {
            { name = "Map", value = mapName or "Unknown", inline = true },
            { name = "Player", value = lplr.DisplayName, inline = true },
        },
        thumbnail = Webhook.getAvatarURL(lplr.UserId),
    })
end

--- Match end
---@param result string - "win" or "lose"
---@param kills number
---@param deaths number
---@param mvp boolean
function Webhook.onMatchEnd(result, kills, deaths, mvp)
    local isWin = result == "win"
    Webhook.embed({
        title = isWin and " MATCH VICTORY!" or " MATCH DEFEAT",
        description = isWin
            and "Congratulations! Your team won!"
            or "Better luck next time!",
        color = isWin and Webhook.Colors.RoundWin or Webhook.Colors.RoundLose,
        fields = {
            { name = "Result", value = isWin and "WIN" or "LOSS", inline = true },
            { name = "K/D", value = kills .. "/" .. deaths, inline = true },
            { name = "MVP", value = mvp and "Yes " or "No", inline = true },
        },
        thumbnail = Webhook.getAvatarURL(lplr.UserId),
    })
end

--- Bomb planted
---@param site string - "A" or "B"
---@param planter Player
function Webhook.onBombPlanted(site, planter)
    Webhook.embed({
        title = " Bomb Planted!",
        description = "C4 has been planted at **Site " .. (site or "?") .. "**",
        color = Webhook.Colors.BombPlant,
        fields = {
            { name = "Site", value = site or "Unknown", inline = true },
            { name = "Planter", value = planter and planter.DisplayName or "Unknown", inline = true },
        },
    })
end

--- Bomb defused
---@param defuser Player
---@param hasKit boolean
function Webhook.onBombDefused(defuser, hasKit)
    Webhook.embed({
        title = " Bomb Defused!",
        description = "The bomb has been defused!",
        color = Webhook.Colors.BombDefuse,
        fields = {
            { name = "Defuser", value = defuser and defuser.DisplayName or "Unknown", inline = true },
            { name = "Kit Used", value = hasKit and "Yes" or "No", inline = true },
        },
    })
end

--- Bomb exploded
function Webhook.onBombExplode()
    Webhook.embed({
        title = " BOOM!",
        description = "The bomb has exploded!",
        color = Webhook.Colors.BombExplode,
    })
end

--- Script loaded notification
function Webhook.onScriptLoad()
    Webhook.embed({
        title = " BloxStrike Loaded",
        description = "**" .. lplr.DisplayName .. "** has started BloxStrike!",
        color = Webhook.Colors.ScriptLoad,
        thumbnail = Webhook.getAvatarURL(lplr.UserId),
        fields = {
            { name = "Username", value = lplr.Name, inline = true },
            { name = "User ID", value = tostring(lplr.UserId), inline = true },
            { name = "Account Age", value = lplr.AccountAge .. " days", inline = true },
            { name = "Server", value = game.JobId ~= "" and string.sub(game.JobId, 1, 8) .. "..." or "Studio", inline = true },
        },
    })
end

--- Money earned
---@param amount number
---@param reason string
function Webhook.onMoneyEarned(amount, reason)
    Webhook.embed({
        title = " $" .. tostring(amount),
        description = reason or "Money earned",
        color = Webhook.Colors.Money,
        fields = {
            { name = "Amount", value = "$" .. tostring(amount), inline = true },
            { name = "Reason", value = reason or "Unknown", inline = true },
        },
    })
end

 -- Expose to BS
BS.Webhook = Webhook

print("[Webhook] BloxStrike Discord Webhook module loaded")
-- [optimized] print("[Webhook] Set URL in UI to enable | Supports: syn.request, http_request, request")

return Webhook
