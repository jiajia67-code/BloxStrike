-- BLOXSTRIKE RAGE MODULE v4.0 (Minimal Stable Version)
-- HVH, Anti-Aim, Silent Aim, Fake Lag, Resolver

local Players = nil
pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local UIS = nil
pcall(function() UIS = game:GetService("UserInputService") end)
local lplr = Players and Players.LocalPlayer

if not BS.Win then warn("[Rage] BS.Win not available") return end
local page = nil
pcall(function() page = BS.Win:Tab("暴力") end)
if not page then warn("[Rage] Failed to create tab!") return end

-- ═══ SILENT AIM ═══
page:Label(" Silent Aim ")
page:Toggle("靜默瞄準", false, function(v) Flags.SilentAim = v end)
page:Slider("FOV", 10, 360, 140, function(v) Flags.SAFov = v end)
page:Dropdown({Name="部位", Flag="SABone", Options={"Head","Chest","Pelvis"}, Default="Head"})
page:Toggle("牆壁穿透", false, function(v) Flags.SAWall = v end)

-- ═══ ANTI-AIM ═══
page:Label(" Anti-Aim ")
page:Toggle("反瞄準", false, function(v) Flags.AA = v end)
page:Dropdown({Name="Pitch", Flag="AAPitch", Options={"Static","Jitter","Spin","Down"}, Default="Static"})
page:Dropdown({Name="Yaw", Flag="AAYaw", Options={"Spin","Back","Left","Right","Jitter"}, Default="Spin"})
page:Slider("旋轉速度", 1, 36, 18, function(v) Flags.AASpd = v end)
page:Toggle("身體旋轉", false, function(v) Flags.AABodyYaw = v end)

-- ═══ FAKE LAG ═══
page:Label(" Fake Lag ")
page:Toggle("假延遲", false, function(v) Flags.FL = v end)
page:Slider("封包數", 1, 16, 8, function(v) Flags.FLChoke = v end)
page:Dropdown({Name="模式", Flag="FLStyle", Options={"Static","Break","Adaptive"}, Default="Static"})

-- ═══ RESOLVER ═══
page:Label(" Resolver ")
page:Toggle("解析器", false, function(v) Flags.Resolver = v end)
page:Toggle("自動反制", false, function(v) Flags.AutoResolve = v end)

-- ═══ RAGE BOT ═══
page:Label(" Rage Bot ")
page:Toggle("暴力瞄準", false, function(v) Flags.Ragebot = v end)
page:Slider("命中率", 50, 100, 100, function(v) Flags.RageHC = v end)
page:Toggle("自動開火", false, function(v) Flags.RageAF = v end)
page:Toggle("雙發", false, function(v) Flags.RageDT = v end)
page:Toggle("刀殺", false, function(v) Flags.RageKnife = v end)

-- ═══ LOGIC ═══
local RAGE = {}
BS.Rage = RAGE

-- Main anti-aim loop
task.spawn(function()
    while true do
        task.wait()
        if Flags.AA and BS.alive and BS.alive() then
            pcall(function()
                local pitch = Flags.AAPitch or "Static"
                local yaw = Flags.AAYaw or "Spin"
                local speed = Flags.AASpd or 18
                
                local char = lplr.Character
                if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                
                -- Apply pitch
                if pitch == "Down" then
                    hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(-89), 0, 0)
                elseif pitch == "Jitter" then
                    hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(math.random(-89, 89)), 0, 0)
                end
                
                -- Apply yaw
                if yaw == "Spin" then
                    local angle = tick() * speed * 10
                    hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(angle % 360), 0)
                elseif yaw == "Back" then
                    hrp.CFrame = CFrame.new(hrp.Position) * hrp.CFrame.Rotation * CFrame.Angles(0, math.rad(180), 0)
                end
            end)
        end
    end
end)

print("[Rage] BloxStrike Rage v4.0 loaded (simplified)")
