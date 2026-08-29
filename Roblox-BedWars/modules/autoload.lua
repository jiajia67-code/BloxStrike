-- ══════════════════════════════════════════════════════════════
-- AUTOLOAD MODULE (Auto Farm + Silent Aim)
-- ══════════════════════════════════════════════════════════════
local PathfindingService = game:GetService("PathfindingService")

-- Auto Farm engine
local function findResourceSpawners()
    local spawners={}
    local target=BW.Flags.FarmTarget or "Iron Only"
    for _, obj in pairs(BW.Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n=obj.Name:lower(); local isTarget=false
            if target=="Iron Only" and n:find("iron") then isTarget=true
            elseif target=="Iron + Gold" and (n:find("iron") or n:find("gold")) then isTarget=true
            elseif target=="All Resources" and (n:find("iron") or n:find("gold") or n:find("diamond") or n:find("emerald")) then isTarget=true end
            if isTarget and obj.Anchored then table.insert(spawners, obj) end
        end
    end
    return spawners
end

local function walkTo(position)
    local my=BW.hrp(); local h=BW.hum()
    if not my or not h then return false end
    h.WalkSpeed=BW.Flags.FarmSpeed or 20
    local path=PathfindingService:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true,AgentCanClimb=false})
    local success=pcall(function() path:ComputeAsync(my.Position,position) end)
    if success and path.Status==Enum.PathStatus.Success then
        for _, wp in ipairs(path:GetWaypoints()) do
            if not BW.Flags.AutoFarm then return false end
            if BW.Flags.FarmAvoid then
                local enemy=BW.nearestEnemy(15)
                if enemy then
                    local fleeDir=(my.Position-enemy.HRP.Position).Unit
                    my.CFrame=CFrame.new(my.Position+fleeDir*10); task.wait(0.3); return false
                end
            end
            h.WalkToPoint=wp.Position; task.wait(0.2)
            local timeout=0
            while (my.Position-wp.Position).Magnitude>3 and timeout<20 do task.wait(0.1); timeout=timeout+0.1 end
        end
        return true
    else h.WalkToPoint=position; task.wait(1); return true end
end

task.spawn(function()
    while true do
        if BW.Flags.AutoFarm and BW.alive() then
            local spawners=findResourceSpawners()
            if #spawners>0 then
                local my=BW.hrp()
                if my then
                    table.sort(spawners,function(a,b) return (a.Position-my.Position).Magnitude<(b.Position-my.Position).Magnitude end)
                    walkTo(spawners[1].Position)
                    task.wait(1)
                    for _, obj in pairs(BW.Workspace:GetDescendants()) do
                        if obj:IsA("BasePart") then
                            local n=obj.Name:lower()
                            if n:find("iron") or n:find("gold") or n:find("diamond") or n:find("emerald") then
                                if (my.Position-obj.Position).Magnitude<8 then my.CFrame=CFrame.new(obj.Position+Vector3.new(0,2,0)); task.wait(0.1) end
                            end
                        end
                    end
                    if BW.Flags.FarmBuyBlocks then local _,iron=BW.getInventory(); if iron>=12 then BW.buyItem("Wool") end end
                end
            end
            if BW.Flags.FarmReturn then
                for _, obj in pairs(BW.Workspace:GetDescendants()) do
                    if obj.Name=="Bed" and obj:IsA("Model") then
                        local tag=obj:FindFirstChild("Team")
                        if tag and tag:IsA("StringValue") and tag.Value==(BW.LocalPlayer.Team and BW.LocalPlayer.Team.Name or "") then
                            local part=obj.PrimaryPart or obj:FindFirstChildWhichIsA("Part")
                            if part then walkTo(part.Position+Vector3.new(3,0,0)) end
                        end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

-- Silent Aim
local SilentAimTarget=nil
task.spawn(function()
    while true do
        if BW.Flags.SilentAim and BW.alive() then
            local fov=BW.Flags.SA_FOV or 120
            local hitChance=(BW.Flags.SA_HitChance or 100)/100
            if math.random()>hitChance then SilentAimTarget=nil
            else
                local my=BW.hrp()
                if my then
                    local best,bestDist=nil,fov
                    for _, e in pairs(BW.enemies()) do
                        local dist=(my.Position-e.HRP.Position).Magnitude
                        if dist<bestDist then
                            if not (BW.Flags.SA_WallCheck and not BW.hasLineOfSight(my.Position,e.HRP.Position)) then
                                bestDist=dist; best=e
                            end
                        end
                    end
                    if best then
                        local tp=BW.Flags.SA_Headshot and best.Char:FindFirstChild("Head") or best.HRP
                        SilentAimTarget=(tp and tp.Position) or nil
                    else SilentAimTarget=nil end
                end
            end
        else SilentAimTarget=nil end
        task.wait(0.01)
    end
end)

task.spawn(function()
    while true do
        if BW.Flags.SilentAim and BW.alive() and SilentAimTarget then
            local cam=BW.Camera.CFrame
            local myPos=cam.Position
            local targetDir=(SilentAimTarget-myPos).Unit
            local currentLook=cam.LookVector
            local newLook=currentLook:Lerp(targetDir,0.5)
            BW.Camera.CFrame=CFrame.new(myPos,myPos+newLook)
            task.wait(0.01)
        end
        task.wait(0.01)
    end
end)

print("[Autoload] Module loaded")
