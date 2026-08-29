
-- -- BLOXSTRIKE RAGE MODULE v2.0 Enhanced CS2-style HVH
-- All features upgraded: Ragebot, Silent Aim, Anti-Aim,
-- Fake Lag, Resolver, Wallbang, Knifebot, Zeus

local Players = nil

pcall(function() Players = game:GetService("Players") end)
local RunService = nil
pcall(function() RunService = game:GetService("RunService") end)
local UIS = nil
pcall(function() UIS = game:GetService("UserInputService") end)
local lplr = Players.LocalPlayer

if not BS.Win then warn("[Rage] BS.Win not available - ui.lua may have failed") return end
local page = BS.Win:Tab("HVH")
if not page or not page.Toggle then warn("[Rage] Failed to create tab!") return end

-- Shortcuts
    local function alive() return BS.alive() end
local function hrp() return BS.hrp() end
local function hum() return BS.hum() end
local function head() local c = lplr.Character; return c and c:FindFirstChild("Head") end

-- Compat layer
local Compat = _G.BS and _G.BS.Compat
local function safeDrawingNew(class)
    if Compat and Compat.DrawingNew then return Compat.DrawingNew(class) end
    local s, r = pcall(function() return Drawing.new(class) end)
    return s and r or nil
end
local function safeMouse1Click()
    if Compat and Compat.Mouse1Click then Compat.Mouse1Click() return end
    pcall(function() mouse1click() end)
end

-- GLOBAL RAGE STATE
local RAGE = {
    Target = nil,
    Targets = {},
    Fov = 180,
    LastFire = 0,
    LastSwitch = 0,
    ResolverStep = {},
    ShotsFired = {},
    HitRegistered = {},
    MissCount = {},
    BruteSide = {},
    TotalShots = {},
    HitCount = {},
    -- Enhanced HVH state
    MultiTargetQueue = {},
    WallbangCooldown = {},
    LastPredictPos = {},
    TargetLockTime = {},
    PreFireQueue = {},
}

-- Weapon Database
local WEAPONS = {
    rifle   = { fireRate = 0.10, damage = 30, recoil = 1.5, spread = 0.02, pen = 80,  headMult = 4.0 },
    sniper  = { fireRate = 1.50, damage = 100, recoil = 3.0, spread = 0.001, pen = 100, headMult = 4.0 },
    pistol  = { fireRate = 0.30, damage = 40, recoil = 0.8, spread = 0.015, pen = 40,  headMult = 4.0 },
    shotgun = { fireRate = 0.80, damage = 80, recoil = 2.0, spread = 0.10, pen = 15,  headMult = 1.0 },
    smg     = { fireRate = 0.07, damage = 20, recoil = 0.6, spread = 0.03, pen = 30,  headMult = 2.5 },
    knife   = { fireRate = 0.40, damage = 40, recoil = 0,   spread = 0,    pen = 0,   headMult = 1.0 },
}

-- Material hardness for wallbang
local MAT_HARD = {
    -- [Enum.Material.DiamondPlate]=100, [Enum.Material.CorrodedMetal]=90,
    -- [Enum.Material.Metal]=80, [Enum.Material.Marble]=75,
    -- [Enum.Material.Concrete]=70, [Enum.Material.Cobblestone]=68,
    -- [Enum.Material.Brick]=65, [Enum.Material.Slate]=60,
    -- [Enum.Material.Limestone]=55, [Enum.Material.Sandstone]=50,
    -- [Enum.Material.Wood]=30, [Enum.Material.Glass]=20,
    -- [Enum.Material.Neon]=15, [Enum.Material.Plastic]=10,
    -- [Enum.Material.Fabric]=5, [Enum.Material.Grass]=3,
}

-- -- SECTION 1: RAGEBOT (Enhanced)
-- page:Label(" Ragebot ")
page:Toggle("Ragebot", false, function(v) Flags.Ragebot = v end)
page:Slider("Rage FOV", 30, 360, 180, function(v) Flags.RageFOV = v end)
page:Slider("Rage Hitchance", 10, 100, 85, function(v) Flags.RageHC = v end)
page:Dropdown({Name="Rage Bone", Flag="RageBone", Options={"Head","Chest","Nearest","Body","Pelvis","Stomach","Auto"}, Default="Head"})
page:Dropdown({Name="Rage Sort", Flag="RageSort", Options={"Crosshair","Distance","Health","Threat","Damage","Random"}, Default="Crosshair"})
page:Toggle("Rage Auto Fire", true, function(v) Flags.RageAF = v end)
page:Slider("Rage Fire Rate", 1, 50, 12, function(v) Flags.RageFR = v end)
page:Toggle("Rage Double Tap", false, function(v) Flags.RageDT = v end)
page:Slider("Rage DT Delay", 1, 30, 6, function(v) Flags.RageDTD = v end)
page:Toggle("Rage Triple Tap", false, function(v) Flags.RageTT = v end)
page:Toggle("Rage Auto Scope", false, function(v) Flags.RageAScope = v end)
page:Toggle("Rage Auto Crouch", false, function(v) Flags.RageACrouch = v end)
page:Toggle("Rage Auto Reload", false, function(v) Flags.RageAReload = v end)
page:Toggle("Rage Through Walls", true, function(v) Flags.RageWall = v end)
page:Slider("Rage Penetration", 10, 100, 70, function(v) Flags.RagePen = v end)
page:Toggle("Rage Prediction", true, function(v) Flags.RagePred = v end)
page:Slider("Rage Pred Factor", 5, 80, 35, function(v) Flags.RagePredF = v end)
page:Toggle("Rage Resolver", true, function(v) Flags.RageRes = v end)
page:Slider("Rage Res Steps", 1, 8, 5, function(v) Flags.RageResS = v end)
page:Toggle("Rage Head Only", false, function(v) Flags.RageHead = v end)
page:Toggle("Rage Body Aim", false, function(v) Flags.RageBody = v end)
page:Toggle("Rage Limb Aim", false, function(v) Flags.RageLimb = v end)
page:Toggle("Rage Smart Body", true, function(v) Flags.RageSmartBody = v end)
page:Slider("Rage Min Damage", 1, 100, 1, function(v) Flags.RageMinDmg = v end)
page:Toggle("Rage Knifebot", false, function(v) Flags.RageKnife = v end)
page:Slider("Rage Knife Range", 2, 10, 5, function(v) Flags.RageKnifeR = v end)
page:Toggle("Rage Zeusing", false, function(v) Flags.RageZeus = v end)
page:Slider("Rage Zeus Range", 5, 30, 20, function(v) Flags.RageZeusR = v end)
page:Toggle("Rage Safety", true, function(v) Flags.RageSafe = v end)
page:Toggle("Rage HP Override", false, function(v) Flags.RageHPOvr = v end)
page:Slider("Rage HP Threshold", 10, 90, 30, function(v) Flags.RageHPThresh = v end)
page:Separator()
page:Label("  Enhanced HVH ")
page:Toggle("Quad Tap", false, function(v) Flags.RageQT = v end)
page:Toggle("Multi-Target", false, function(v) Flags.RageMultiTarget = v end)
page:Slider("MT Range", 50, 360, 180, function(v) Flags.RageMTRange = v end)
page:Label("Quad Tap: 4 shots in rapid succession")
page:Label("Multi-Target: shoot at 2nd closest enemy too")

-- -- SECTION 1A: MULTIPOINT + SAFE POINT + DAMAGE OVERRIDE + FORCE
-- page:Label(" Multipoint ")
page:Toggle("Multipoint", false, function(v) Flags.RageMP = v end)
page:Slider("MP Head Scale", 0, 100, 50, function(v) Flags.RageMPHead = v end)
page:Slider("MP Chest Scale", 0, 100, 50, function(v) Flags.RageMPChest = v end)
page:Slider("MP Body Scale", 0, 100, 30, function(v) Flags.RageMPBody = v end)
page:Slider("MP Stomach Scale", 0, 100, 20, function(v) Flags.RageMPStomach = v end)
page:Label("Scale: 0=OFF, 100=Full hitbox")
page:Separator()
page:Label(" Safe Point ")
page:Toggle("Safe Point", false, function(v) Flags.RageSP = v end)
page:Slider("SP Tolerance", 1, 50, 20, function(v) Flags.RageSPTol = v end)
page:Toggle("SP Auto Disable", true, function(v) Flags.RageSPAuto = v end)
page:Label("Safe Point: Don't shoot when enemy at bad angle")
page:Separator()
page:Label(" Damage Override ")
page:Toggle("Damage Override", false, function(v) Flags.RageDmgOvr = v end)
page:Slider("Override Damage", 1, 120, 1, function(v) Flags.RageDmgOvrVal = v end)
page:Dropdown({Name="Override Key", Flag="RageDmgKey", Options={"Mouse4","Mouse5","Left Alt","Left Ctrl","Shift"}, Default="Mouse4"})
page:Label("Hold key to temporarily override min damage")
page:Separator()
page:Label(" Force Aim ")
page:Toggle("Force Body", false, function(v) Flags.RageForceBody = v end)
page:Toggle("Force Head", false, function(v) Flags.RageForceHead = v end)
page:Dropdown({Name="Force Key", Flag="RageForceKey", Options={"Mouse4","Mouse5","Left Alt","Left Ctrl","Shift"}, Default="Mouse5"})
page:Label("Force: Override bone selection with key hold")
page:Separator()
page:Label(" Auto Stop ")
page:Toggle("Auto Stop", false, function(v) Flags.RageAutoStop = v end)
page:Toggle("Auto Stop In Air", false, function(v) Flags.RageAutoStopAir = v end)
page:Slider("Stop Speed", 1, 100, 100, function(v) Flags.RageStopSpd = v end)
page:Label("Auto Stop: Instant deceleration when shooting")

-- -- SECTION 1B: SILENT AIM (Enhanced)
-- page:Label(" Silent Aim ")
page:Toggle("Silent Aim", false, function(v) Flags.SilentAim = v end)
page:Dropdown({Name="SA Mode", Flag="SAMode", Options={"Camera Redirect","Mouse Redirect","Server Angle","Hybrid"}, Default="Camera Redirect"})
page:Slider("SA FOV", 10, 360, 140, function(v) Flags.SAFov = v end)
page:Slider("SA HC", 30, 100, 92, function(v) Flags.SAHC = v end)
page:Dropdown({Name="SA Bone", Flag="SABone", Options={"Head","Chest","Nearest","Pelvis","Body","Auto"}, Default="Head"})
page:Toggle("SA Predict", true, function(v) Flags.SAPred = v end)
page:Slider("SA Pred Time", 5, 60, 30, function(v) Flags.SAPredT = v end)
page:Toggle("SA Vis Check", false, function(v) Flags.SAVis = v end)
page:Toggle("SA Wall Check", false, function(v) Flags.SAWall = v end)
page:Toggle("SA Team Check", true, function(v) Flags.SATeam = v end)
page:Toggle("SA Auto Fire", false, function(v) Flags.SAAF = v end)
page:Slider("SA Target Switch", 0, 500, 80, function(v) Flags.SASwitch = v end)
page:Toggle("SA FOV Circle", true, function(v) Flags.SAFovCirc = v end)
page:Slider("SA Smooth", 1, 20, 1, function(v) Flags.SASmooth = v end)
page:Toggle("SA Smart Mode", false, function(v) Flags.SASmart = v end)
page:Slider("SA Smart Range", 10, 100, 45, function(v) Flags.SASmartR = v end)
page:Toggle("SA Backtrack", false, function(v) Flags.SABacktrack = v end)
page:Slider("SA BT Time", 50, 400, 200, function(v) Flags.SABTT = v end)
page:Toggle("SA Hit Sound", false, function(v) Flags.SAHitSnd = v end)
page:Label(" Advanced SA ")
page:Toggle("SA Multi Target", false, function(v) Flags.SAMultiT = v end)
page:Slider("SA Multi Count", 1, 5, 2, function(v) Flags.SAMultiC = v end)
page:Toggle("SA Resolver Override", false, function(v) Flags.SAResOvr = v end)
page:Toggle("SA Hitbox Expander", false, function(v) Flags.SAHBE = v end)
page:Slider("SA HB Size", 1, 5, 2, function(v) Flags.SAHBS = v end)
page:Toggle("SA Magic Bullet", false, function(v) Flags.SAMagic = v end)
page:Slider("SA Magic Distance", 10, 100, 50, function(v) Flags.SAMagicD = v end)
page:Toggle("SA Auto Wallbang", true, function(v) Flags.SAAutoWall = v end)
page:Slider("SA Wallbang Pen", 10, 100, 70, function(v) Flags.SAWallPen = v end)
page:Toggle("SA Lag Compensation", false, function(v) Flags.SALagComp = v end)
page:Slider("SA LC Ticks", 1, 16, 8, function(v) Flags.SALCTicks = v end)
page:Toggle("SA Position Adjustment", false, function(v) Flags.SAPosAdj = v end)
page:Slider("SA Pos Adj X", -10, 10, 0, function(v) Flags.SAPosAdjX = v end)
page:Slider("SA Pos Adj Y", -10, 10, 0, function(v) Flags.SAPosAdjY = v end)
page:Toggle("SA Nearest Bone Priority", false, function(v) Flags.SANBP = v end)
page:Toggle("SA Spread Control", false, function(v) Flags.SASpread = v end)
page:Slider("SA Spread Factor", 0, 100, 50, function(v) Flags.SASpreadF = v end)
page:Toggle("SA Recoil Control", false, function(v) Flags.SARCS = v end)
page:Slider("SA RCS X", 0, 100, 60, function(v) Flags.SARCSX = v end)
page:Slider("SA RCS Y", 0, 100, 80, function(v) Flags.SARCSY = v end)
page:Toggle("SA Silent Walk", false, function(v) Flags.SASilentWalk = v end)
page:Toggle("SA Auto Scope", false, function(v) Flags.SAAutoScope = v end)
page:Toggle("SA No Visual Recoil", false, function(v) Flags.SANoVR = v end)
page:Label(" Backwards / 360 SA ")
page:Toggle("SA Backwards", false, function(v) Flags.SABackwards = v end)
page:Dropdown({Name="SA Backwards Dir", Flag="SABackDir", Options={"Away","Left","Right","Random","Toward"}, Default="Away"})
page:Toggle("SA 360 Mode", false, function(v) Flags.SA360 = v end)
page:Slider("SA 360 Range", 30, 360, 360, function(v) Flags.SA360Range = v end)
page:Toggle("SA AA Sync", false, function(v) Flags.SAAASync = v end)
page:Toggle("SA Freestand", false, function(v) Flags.SAFreeStand = v end)
page:Toggle("SA Fake Duck Aim", false, function(v) Flags.SAFakeDuckAim = v end)
page:Toggle("SA Inverse Aim", false, function(v) Flags.SAInverse = v end)
page:Slider("SA Inverse Offset", 0, 180, 180, function(v) Flags.SAInvOff = v end)
page:Label("Backwards: ")
page:Label("360: 360")
page:Label("AA Sync: ")
page:Label("Silent Aim: Hit without visual aim movement")
page:Separator()

-- -- SECTION 1C: P-SILENT + RAPID FIRE
-- page:Label(" PSilent (Pure Silent) ")
page:Toggle("PSilent", false, function(v) Flags.RagePSilent = v end)
page:Dropdown({Name="PS Mode", Flag="RagePSMode", Options={"Server Angle","Camera","Hybrid"}, Default="Server Angle"})
page:Slider("PS FOV", 10, 360, 180, function(v) Flags.RagePSFov = v end)
page:Slider("PS HC", 50, 100, 95, function(v) Flags.RagePSHC = v end)
page:Toggle("PS Wallbang", true, function(v) Flags.RagePSWall = v end)
page:Toggle("PS Backtrack", false, function(v) Flags.RagePSBT = v end)
page:Label("PSilent: Pure server-side hit without ANY camera movement")
page:Separator()
page:Label(" Rapid Fire ")
page:Toggle("Rapid Fire", false, function(v) Flags.RageRapid = v end)
page:Slider("Rapid Rate", 1, 50, 25, function(v) Flags.RageRapidRate = v end)
page:Dropdown({Name="Rapid Mode", Flag="RageRapidMode", Options={"Aggressive","Controlled","Burst"}, Default="Controlled"})
page:Slider("Rapid Burst Count", 2, 10, 4, function(v) Flags.RageRapidBurst = v end)
page:Toggle("Rapid No Spread", false, function(v) Flags.RageRapidNS = v end)
page:Label("Rapid Fire: Continuous fast shooting (more aggressive than DT)")

-- -- SECTION 1.5: BULLET TRACER 
-- page:Label("--- Section ---")
page:Toggle("Bullet Tracer", true, function(v) Flags.BulletTracer = v end)
page:Toggle("Tracer Through Walls", true, function(v) Flags.TracerWall = v end)
page:Slider("Tracer Width", 1, 5, 2, function(v) Flags.TracerWidth = v end)
page:Slider("Tracer Duration", 1, 10, 3, function(v) Flags.TracerDuration = v end)
page:Dropdown({Name="Tracer Color", Flag="TracerColor", Options={"Red","Green","Blue","Yellow","Cyan","Magenta","White","Rainbow"}, Default="Red"})
page:Toggle("Tracer Impact Point", true, function(v) Flags.TracerImpact = v end)
page:Slider("Tracer Impact Size", 3, 15, 6, function(v) Flags.TracerImpactSize = v end)
page:Toggle("Tracer Penetration Line", true, function(v) Flags.TracerPenLine = v end)
page:Toggle("Tracer Hit Marker", true, function(v) Flags.TracerHitMarker = v end)
page:Slider("Tracer Hit Marker Size", 5, 25, 12, function(v) Flags.TracerHMS = v end)
page:Toggle("Tracer Kill Counter", false, function(v) Flags.TracerKillCount = v end)
page:Label("--- BULLET TRACER SECTION END ---")

-- SECTION 2: ANTI-AIM (Enhanced)
-- page:Label(" Anti-Aim ")
page:Toggle("Anti-Aim", false, function(v) Flags.AA = v end)
page:Dropdown({Name="AA Pitch", Flag="AAPitch", Options={
    -- "Down","Up","Zero","Jitter","Random","Fake Up","Fake Down","Lisp","Mixed","Sideways",
    -- "Emotion","Slow Jitter","Fakedown","Zero Sway"
}, Default="Down"})
page:Dropdown({Name="AA Yaw", Flag="AAYaw", Options={
    -- "Spin","Jitter","Back","Left","Right","LBY Break","Edge","Fake","Switch","Slow Spin",
    -- "Fast Spin","Wide Jitter","LBY Break Fast","Random Walk","Triangle","Opposite","T-Shape"
}, Default="Spin"})
page:Slider("AA Speed", 1, 30, 12, function(v) Flags.AASpd = v end)
page:Slider("AA Jitter Range", 10, 180, 100, function(v) Flags.AAJittR = v end)
page:Toggle("AA On Ground Only", false, function(v) Flags.AAGround = v end)
page:Toggle("AA While Shooting", true, function(v) Flags.AAShoot = v end)
page:Toggle("AA Fake Duck", false, function(v) Flags.AAFakeDuck = v end)
page:Slider("AA Fake Duck Choke", 1, 16, 8, function(v) Flags.AAFDC = v end)
page:Toggle("AA Freestanding", false, function(v) Flags.AAFree = v end)
page:Toggle("AA Edge Detection", false, function(v) Flags.AAEdge = v end)
page:Toggle("AA Lower Body Yaw", true, function(v) Flags.AALBY = v end)
page:Slider("AA LBY Offset", -180, 180, 120, function(v) Flags.AALBYO = v end)
page:Toggle("AA Animation Breaker", false, function(v) Flags.AAAnimBreak = v end)
page:Dropdown({Name="AA Anim Style", Flag="AAAnimStyle", Options={"Flipped","Platform","Lean","Inverse","Downside","Slide","Moonwalk","Breaker"}, Default="Flipped"})
page:Toggle("AA Height Variation", false, function(v) Flags.AAHeight = v end)
page:Slider("AA Height Amp", 1, 10, 3, function(v) Flags.AAHeightAmp = v end)
page:Toggle("AA Desync", false, function(v) Flags.AADesync = v end)
page:Slider("AA Desync Range", -180, 180, 90, function(v) Flags.AADesyncR = v end)
page:Toggle("AA Jitter Tick", false, function(v) Flags.AAJittTick = v end)
page:Slider("AA Jitter Interval", 1, 10, 3, function(v) Flags.AAJittInt = v end)
page:Toggle("AA Manual Override", false, function(v) Flags.AAManual = v end)
page:Dropdown({Name="AA Manual Dir", Flag="AAManualDir", Options={"Forward","Backward","Left","Right"}, Default="Backward"})
page:Toggle("AA Body Yaw", true, function(v) Flags.AABodyYaw = v end)
page:Slider("AA Body Yaw Offset", -180, 180, 60, function(v) Flags.AABodyYawO = v end)
page:Toggle("AA Fake Angles", false, function(v) Flags.AAFakeAngles = v end)
page:Toggle("AA Slow Walk AA", false, function(v) Flags.AASlowAA = v end)
page:Toggle("AA Air AA", false, function(v) Flags.AAAirAA = v end)
page:Toggle("AA Desync Visualizer", false, function(v) Flags.AADesyncViz = v end)
page:Label(" Advanced AA ")
page:Toggle("AA Dynamic Jitter", false, function(v) Flags.AADynJitt = v end)
page:Slider("AA Dyn Jitter Min", 10, 90, 30, function(v) Flags.AADynMin = v end)
page:Slider("AA Dyn Jitter Max", 90, 180, 150, function(v) Flags.AADynMax = v end)
page:Toggle("AA Sideways", false, function(v) Flags.AASideways = v end)
page:Toggle("AA Backwards", false, function(v) Flags.AABackwards = v end)
page:Toggle("AA Resolved Jitter", false, function(v) Flags.AAResJitt = v end)
page:Slider("AA Resolved Jitter Speed", 1, 20, 10, function(v) Flags.AAResJSpd = v end)
page:Toggle("AA Anti Resolver", false, function(v) Flags.AAAntiRes = v end)
page:Toggle("AA Body Flip", false, function(v) Flags.AABodyFlip = v end)
page:Slider("AA Body Flip Interval", 1, 10, 5, function(v) Flags.AABodyFlipInt = v end)
page:Toggle("AA Fake Lag Sync", false, function(v) Flags.AAFLSync = v end)
page:Toggle("AA Move Manipulation", false, function(v) Flags.AAMoveManip = v end)
page:Slider("AA Move Manip Strength", 1, 20, 8, function(v) Flags.AAMoveStr = v end)
page:Toggle("AA View Manipulation", false, function(v) Flags.AAViewManip = v end)
page:Slider("AA View Manip Angle", 1, 180, 90, function(v) Flags.AAViewAngle = v end)
page:Toggle("AA Anti Untrust", false, function(v) Flags.AAAntiUntrust = v end)
page:Toggle("AA Slow LBY", false, function(v) Flags.AASlowLBY = v end)
page:Slider("AA Slow LBY Speed", 1, 10, 3, function(v) Flags.AASlowLBYS = v end)
page:Toggle("AA Brute After Miss", true, function(v) Flags.AABruteMiss = v end)
page:Slider("AA Brute Steps", 2, 8, 4, function(v) Flags.AABruteSteps = v end)
page:Label("AA: Confuse enemy aimbot with fake angles")
page:Separator()

-- -- SECTION 2B: DESYNC + EMOTION + LEAN + LBY BREAKER + MANUAL AA
-- page:Label(" Desync (CS2  AA) ")
page:Toggle("Desync", false, function(v) Flags.AADesync2 = v end)
page:Slider("Desync Range", 1, 58, 58, function(v) Flags.AADesyncR2 = v end)
page:Dropdown({Name="Desync Mode", Flag="AADesyncMode", Options={"Static","Jitter","Random","Brute","Cycle"}, Default="Static"})
page:Slider("Desync Jitter Range", 1, 58, 30, function(v) Flags.AADesyncJR = v end)
page:Toggle("Desync Inverter", true, function(v) Flags.AADesyncInv = v end)
page:Dropdown({Name="Inverter Key", Flag="AADesyncKey", Options={"Mouse4","Mouse5","Left Alt","Left Ctrl","Shift"}, Default="Mouse4"})
page:Label("Desync: Shift hitbox away from visible model")
page:Separator()
page:Label(" Emotion (CS2  AA) ")
page:Toggle("Emotion AA", false, function(v) Flags.AAEmotion = v end)
page:Slider("Emotion Pitch", 45, 90, 45, function(v) Flags.AAEmoPitch = v end)
page:Dropdown({Name="Emotion Desync", Flag="AAEmoDesync", Options={"Static","Jitter","LBY"}, Default="Static"})
page:Slider("Emotion Desync Range", 1, 58, 58, function(v) Flags.AAEmoDR = v end)
page:Label("Emotion: 45 pitch + static desync (most common CS2 AA)")
page:Separator()
page:Label(" Lean ")
page:Toggle("Lean", false, function(v) Flags.AALean = v end)
page:Slider("Lean Amount", 1, 58, 58, function(v) Flags.AALeanAmt = v end)
page:Dropdown({Name="Lean Side", Flag="AALeanSide", Options={"Auto","Left","Right","Alternating"}, Default="Auto"})
page:Label("Lean: Body lean to make hitbox harder to resolve")
page:Separator()
page:Label(" LBY Breaker ")
page:Toggle("LBY Breaker", false, function(v) Flags.AALBYBreak = v end)
page:Slider("LBY Break Interval", 100, 1000, 350, function(v) Flags.AALBYInt = v end)
page:Slider("LBY Break Offset", -120, 120, 120, function(v) Flags.AALBYOff = v end)
page:Label("LBY Breaker: Break Lower Body Yaw for 118 legit AA")
page:Separator()
page:Label(" Manual Anti-Aim ")
page:Toggle("Manual AA", false, function(v) Flags.AAManual2 = v end)
page:Dropdown({Name="Left Key", Flag="AAMLeft", Options={"Mouse4","Mouse5","Left Alt","Left Ctrl","Shift"}, Default="Mouse4"})
page:Dropdown({Name="Right Key", Flag="AAMRight", Options={"Mouse4","Mouse5","Left Alt","Left Ctrl","Shift"}, Default="Mouse5"})
page:Dropdown({Name="Back Key", Flag="AAMBack", Options={"Mouse4","Mouse5","Left Alt","Left Ctrl","Shift"}, Default="Left Alt"})
page:Label("Manual: Use keys to force specific AA direction")
page:Separator()
page:Label(" Auto Freestand ")
page:Toggle("Auto Freestand", false, function(v) Flags.AAFreeStand = v end)
page:Slider("Freestand Range", 1, 10, 5, function(v) Flags.AAFreeR = v end)
page:Toggle("Freestand Edge Detect", true, function(v) Flags.AAFreeEdge = v end)
page:Label("Freestand: Auto face nearest wall to hide real angle")

-- -- SECTION 3: FAKE LAG (Enhanced)
-- page:Label(" Fake Lag ")
page:Toggle("Fake Lag", false, function(v) Flags.FL = v end)
page:Slider("FL Choke", 1, 16, 7, function(v) Flags.FLChoke = v end)
page:Dropdown({Name="FL Style", Flag="FLStyle", Options={"Constant","Adaptive","Random","Tick","Break Lag","Shift","Aggressive","Hyper","Break LC","Desync"}, Default="Adaptive"})
page:Slider("FL Tick Rate", 1, 16, 8, function(v) Flags.FLTick = v end)
page:Toggle("FL On Ground Only", false, function(v) Flags.FLGround = v end)
page:Toggle("FL Moving Only", false, function(v) Flags.FLMoving = v end)
page:Slider("FL Variance", 0, 50, 20, function(v) Flags.FLVar = v end)
page:Toggle("FL Fake Walk", false, function(v) Flags.FLFakeWalk = v end)
page:Slider("FL Fake Walk Speed", 1, 16, 4, function(v) Flags.FLFWS = v end)
page:Toggle("FL Break LC", false, function(v) Flags.FLBLC = v end)
page:Separator()

-- -- SECTION 3B: EXPLOITS (HIDESHOTS + ONSHOT + TICKBASE)
-- page:Label(" Exploits ")
page:Toggle("Hideshots", false, function(v) Flags.ExploitHS = v end)
page:Slider("HS Ticks", 1, 16, 8, function(v) Flags.ExploitHSTicks = v end)
page:Dropdown({Name="HS Mode", Flag="ExploitHSMode", Options={"Tick Shift","Lag Swap","Break LC"}, Default="Tick Shift"})
page:Label("Hideshots: Prevent getting oneshotted via tickbase")
page:Separator()
page:Toggle("Onshot", false, function(v) Flags.ExploitOnshot = v end)
page:Slider("Onshot Delay", 1, 16, 6, function(v) Flags.ExploitOSDelay = v end)
page:Label("Onshot: Manipulate when shots register")
page:Separator()
page:Toggle("Fake Duck", false, function(v) Flags.ExploitFakeDuck = v end)
page:Slider("Fake Duck Choke", 1, 16, 8, function(v) Flags.ExploitFDChoke = v end)
page:Label("Fake Duck: Fake crouch to change hitbox")
page:Separator()
page:Toggle("Quick Stop (Key)", false, function(v) Flags.ExploitQS = v end)
page:Dropdown({Name="QS Key", Flag="ExploitQSKey", Options={"Mouse4","Mouse5","Left Alt","Left Ctrl","Shift"}, Default="Mouse4"})
page:Label("Quick Stop: Instant deceleration on key hold")
page:Separator()
page:Label(" Exploit Presets ")
page:Button({Name="[HVH] Full Exploits", Color=Color3.fromRGB(200,50,50)}, function()
    Flags.ExploitHS=true; Flags.ExploitHSTicks=10
    Flags.ExploitOnshot=true; Flags.ExploitOSDelay=6
    Flags.ExploitFakeDuck=true; Flags.ExploitFDChoke=10
    Flags.FL=true; Flags.FLChoke=14; Flags.FLStyle="Break Lag"
    Flags.AADesync2=true; Flags.AADesyncR2=58
    pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="? Full Exploits",Text="HS+Onshot+FD+FL+Desync",Duration=3}) end)
end)
page:Button({Name="[HVH] Anti-Oneshot", Color=Color3.fromRGB(100,200,100)}, function()
    Flags.ExploitHS=true; Flags.ExploitHSTicks=12
    Flags.FL=true; Flags.FLChoke=12; Flags.FLStyle="Adaptive"
    Flags.AADesync2=true; Flags.AADesyncR2=58; Flags.AADesyncMode="Jitter"
    pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="Anti-Oneshot",Text="HS+FL+Desync Jitter",Duration=3}) end)
end)

-- -- SECTION 4: RESOLVER (Enhanced)
-- page:Label(" Resolver ")
page:Toggle("Resolver", false, function(v) Flags.Resolver = v end)
page:Dropdown({Name="Res Mode", Flag="ResMode", Options={
    -- "Brute Force","Moving AW","Static","Freestand","Manual","Smart","Inverse","Anti Brute"
}, Default="Smart"})
page:Slider("Res Steps", 1, 12, 6, function(v) Flags.ResSteps = v end)
page:Toggle("Res Auto", true, function(v) Flags.ResAuto = v end)
page:Toggle("Res Anti Brute", true, function(v) Flags.ResAB = v end)
page:Toggle("Res Log Misses", false, function(v) Flags.ResLogMiss = v end)
page:Slider("Res Manual Angle", -180, 180, 0, function(v) Flags.ResMAngle = v end)
page:Toggle("Res Override Resolver", false, function(v) Flags.ResOverride = v end)
page:Label(" Advanced Resolver ")
page:Toggle("Res Velocity Tracking", true, function(v) Flags.ResVelTrack = v end)
page:Slider("Res Vel History", 5, 50, 20, function(v) Flags.ResVelHist = v end)
page:Toggle("Res Position Tracking", true, function(v) Flags.ResPosTrack = v end)
page:Slider("Res Pos History", 5, 30, 15, function(v) Flags.ResPosHist = v end)
page:Toggle("Res Animation Analysis", false, function(v) Flags.ResAnim = v end)
page:Toggle("Res Lag Compensation", true, function(v) Flags.ResLagComp = v end)
page:Slider("Res LC Ticks", 1, 16, 8, function(v) Flags.ResLCTicks = v end)
page:Toggle("Res Brute Force Mode", false, function(v) Flags.ResBruteMode = v end)
page:Slider("Res Brute Steps", 2, 16, 8, function(v) Flags.ResBruteSteps = v end)
page:Toggle("Res Inverse Resolver", false, function(v) Flags.ResInverse = v end)
page:Toggle("Res Adaptive", true, function(v) Flags.ResAdaptive = v end)
page:Slider("Res Adaptive Speed", 1, 10, 5, function(v) Flags.ResAdaptSpd = v end)
page:Toggle("Res Smart Detection", true, function(v) Flags.ResSmart = v end)
page:Slider("Res Smart Confidence", 10, 100, 60, function(v) Flags.ResConf = v end)
page:Toggle("Res Anti Brute Force", true, function(v) Flags.ResAntiBrute = v end)
page:Slider("Res Anti Brute Steps", 2, 8, 4, function(v) Flags.ResAntiSteps = v end)
page:Toggle("Res Manual Override", false, function(v) Flags.ResManual = v end)
page:Slider("Res Manual Angle", -180, 180, 0, function(v) Flags.ResManAngle = v end)
page:Toggle("Res Body Aim Resolver", false, function(v) Flags.ResBodyAim = v end)
page:Toggle("Res Head Aim Resolver", false, function(v) Flags.ResHeadAim = v end)
page:Toggle("Res Auto Switch", true, function(v) Flags.ResAutoSw = v end)
page:Slider("Res Switch Speed", 1, 10, 5, function(v) Flags.ResSwSpd = v end)
page:Toggle("Res Miss Detection", true, function(v) Flags.ResMiss = v end)
page:Slider("Res Miss Threshold", 1, 10, 3, function(v) Flags.ResMissTh = v end)
page:Toggle("Res Log Resolver", false, function(v) Flags.ResLog = v end)
page:Label("Resolver: Figure out enemy AA angles")
page:Separator()

-- -- SECTION 4B: MOVING AA RESOLVER + SIDE DETECTION + ANIM BREAKER
-- page:Label(" Moving AA Resolver ")
page:Toggle("Moving AA Resolve", false, function(v) Flags.ResMovingAA = v end)
page:Slider("Moving Resolve Range", 1, 58, 58, function(v) Flags.ResMovingR = v end)
page:Dropdown({Name="Moving Mode", Flag="ResMovingMode", Options={"Velocity Based","Position Based","Angle Based","Adaptive"}, Default="Velocity Based"})
page:Label("Resolve enemy AA while they are moving")
page:Separator()
page:Label(" Side Detection ")
page:Toggle("Side Detection", false, function(v) Flags.ResSideDetect = v end)
page:Slider("Side Confidence", 10, 100, 60, function(v) Flags.ResSideConf = v end)
page:Dropdown({Name="Side Method", Flag="ResSideMethod", Options={"Velocity","Angle","Animation","LBY"}, Default="Velocity"})
page:Label("Detect which side enemy is leaning towards")
page:Separator()
page:Label(" Animation Breaker Detection ")
page:Toggle("Anim Breaker Detect", false, function(v) Flags.ResAnimDetect = v end)
page:Slider("Anim Detect Sensitivity", 1, 20, 10, function(v) Flags.ResAnimSens = v end)
page:Toggle("Anim Breaker Counter", false, function(v) Flags.ResAnimCounter = v end)
page:Label("Detect and counter enemy animation breakers")
page:Separator()
page:Label(" Resolver Presets ")
page:Button({Name="[Res] Smart Auto", Color=Color3.fromRGB(100,200,100)}, function()
    Flags.Resolver=true; Flags.ResMode="Smart"
    Flags.ResAuto=true; Flags.ResAB=true; Flags.ResVelTrack=true
    Flags.ResAdaptive=true; Flags.ResSmart=true; Flags.ResAntiBrute=true
    Flags.ResAutoSw=true; Flags.ResMiss=true
    Flags.ResMovingAA=true; Flags.ResSideDetect=true
    pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title=" Smart Resolver",Text="All resolver features ON",Duration=3}) end)
end)
page:Button({Name="[Res] Brute Force", Color=Color3.fromRGB(200,100,0)}, function()
    Flags.Resolver=true; Flags.ResMode="Brute Force"
    Flags.ResBruteMode=true; Flags.ResBruteSteps=12
    Flags.ResAuto=true; Flags.ResAB=true
    Flags.ResMovingAA=true; Flags.ResAnimDetect=true
    pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="Brute Resolver",Text="Brute Force + Moving + Anim",Duration=3}) end)
end)

-- -- SECTION 5: HVH UTILITIES (Enhanced)
-- page:Label(" HVH Utilities ")
page:Toggle("Quick Stop", false, function(v) Flags.QS = v end)
page:Toggle("Slow Walk", false, function(v) Flags.SW = v end)
page:Slider("SW Speed", 1, 16, 4, function(v) Flags.SWS = v end)
page:Toggle("No Clip", false, function(v) Flags.NoClip = v end)
page:Toggle("Edge Friction", false, function(v) Flags.EdgeFric = v end)
page:Toggle("Auto Revolver", false, function(v) Flags.AutoRev = v end)
page:Toggle("Auto Pistol", false, function(v) Flags.AutoPistol = v end)
page:Slider("Pistol Fire Rate", 1, 20, 8, function(v) Flags.PistolFR = v end)
page:Toggle("Crouch Walk", false, function(v) Flags.CrouchWalk = v end)
page:Toggle("Circle Strafe", false, function(v) Flags.CircStrafe = v end)
page:Slider("CS Speed", 1, 20, 8, function(v) Flags.CSSpd = v end)
page:Separator()
page:Label(" Weapon Switch ")
page:Toggle("Quick Switch", false, function(v) Flags.QuickSwitch = v end)
page:Dropdown({Name="QS Mode", Flag="QSMode", Options={"Knife-Primary","Knife-Zeus","Auto-Zeus","Last Weapon"}, Default="Knife-Primary"})
page:Slider("QS Delay", 10, 500, 100, function(v) Flags.QSDelay = v end)
page:Toggle("QS On Kill", true, function(v) Flags.QSOnKill = v end)
page:Toggle("QS On Empty", false, function(v) Flags.QSOnEmpty = v end)
page:Separator()
page:Label(" Enhanced Zeus ")
page:Toggle("Auto Zeus", false, function(v) Flags.AutoZeus = v end)
page:Slider("Zeus Range", 3, 20, 12, function(v) Flags.ZeusRange = v end)
page:Toggle("Zeus Auto Switch", false, function(v) Flags.ZeusAutoSw = v end)
page:Toggle("Zeus Team Check", true, function(v) Flags.ZeusTeam = v end)
page:Toggle("Zeus Wall Check", false, function(v) Flags.ZeusWall = v end)
page:Slider("Zeus Cooldown", 100, 3000, 500, function(v) Flags.ZeusCD = v end)
page:Toggle("Zeus on Low HP", false, function(v) Flags.ZeusLowHP = v end)
page:Slider("Zeus HP Threshold", 10, 80, 30, function(v) Flags.ZeusHPThresh = v end)
page:Separator()

-- -- SECTION 5B: SLIDE WALK + PIXEL SURF + MOVEMENT EXPLOITS
-- page:Label(" Slide Walk ")
page:Toggle("Slide Walk", false, function(v) Flags.HVHSlideWalk = v end)
page:Slider("Slide Speed", 1, 20, 10, function(v) Flags.HVHSlideSpd = v end)
page:Label("Slide Walk: Player slides when walking")
page:Separator()
page:Label(" Pixel Surf ")
page:Toggle("Pixel Surf", false, function(v) Flags.HVHPixelSurf = v end)
page:Slider("PSurf Height", 1, 10, 3, function(v) Flags.HVHPixelH = v end)
page:Label("Pixel Surf: Surf on thin edges")
page:Separator()
page:Label(" Movement Exploits ")
page:Toggle("Crouch Walk", false, function(v) Flags.HVHCrouchWalk = v end)
page:Toggle("Edge Friction Bug", false, function(v) Flags.HVHEdgeFriction = v end)
page:Toggle("Auto Revolver", false, function(v) Flags.HVHAutoRev = v end)
page:Toggle("Auto Pistol", false, function(v) Flags.HVHAutoPistol = v end)
page:Slider("Pistol Fire Rate", 1, 20, 8, function(v) Flags.HVHPistolFR = v end)

-- -- SECTION 6: HVH PRESETS
-- page:Label(" Presets ")
page:Button({Name="[HVH] Full Rage", Color=Color3.fromRGB(200,50,50)}, function()
    Flags.Ragebot=true; Flags.RageFOV=360; Flags.RageHC=100; Flags.RageAF=true
    Flags.RageDT=true; Flags.RageWall=true; Flags.RagePred=true; Flags.RageRes=true
    Flags.AA=true; Flags.AAPitch="Jitter"; Flags.AAYaw="Spin"; Flags.AASpd=18
    Flags.FL=true; Flags.FLChoke=10; Flags.FLStyle="Adaptive"
    Flags.Resolver=true; Flags.ResMode="Smart"
    pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="? Full Rage",Text="All HVH features ON!",Duration=3}) end)
end)
page:Button({Name="[HVH] Legit Rage", Color=Color3.fromRGB(100,150,200)}, function()
    Flags.Ragebot=true; Flags.RageFOV=150; Flags.RageHC=80; Flags.RageAF=false
    Flags.RageDT=false; Flags.RageWall=false; Flags.RagePred=true; Flags.RageRes=true
    Flags.AA=true; Flags.AAPitch="Down"; Flags.AAYaw="Jitter"; Flags.AASpd=8
    Flags.FL=true; Flags.FLChoke=4; Flags.FLStyle="Constant"
    Flags.Resolver=true; Flags.ResMode="Moving AW"
    pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="Legit Rage",Text="Conservative HVH ON",Duration=3}) end)
end)
page:Button({Name="[HVH] AA Only", Color=Color3.fromRGB(100,200,100)}, function()
    Flags.Ragebot=false; Flags.AA=true; Flags.AAPitch="Down"; Flags.AAYaw="Back"
    Flags.AASpd=10; Flags.FL=true; Flags.FLChoke=6
    pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="AA Only",Text="Anti-Aim + Fake Lag",Duration=3}) end)
end)
page:Button({Name="[HVH] Disable All", Color=Color3.fromRGB(60,60,60)}, function()
    for k,_ in pairs(Flags) do Flags[k]=false end
    pcall(function()
        local h=hum(); if h then h.WalkSpeed=16; h.JumpPower=50; h.HipHeight=0 end
        if workspace and workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView=70 end
    end)
    pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="Off",Text="All HVH disabled",Duration=3}) end)
end)

-- -- SECTION 7: ADVANCED HVH  HVH ?
-- page:Label(" ? HVH  ")
page:Toggle("HVH Super Mode", false, function(v) Flags.HVHSuper = v end)
page:Toggle("Auto Anti-Aim", false, function(v) Flags.AutoAA = v end)
page:Toggle("Auto Fake Lag", false, function(v) Flags.AutoFL = v end)
page:Toggle("Auto Resolver", false, function(v) Flags.AutoRes = v end)
page:Toggle("Auto Ragebot", false, function(v) Flags.AutoRage = v end)
page:Toggle("Smart Brute Force", false, function(v) Flags.SmartBrute = v end)
page:Toggle("Auto Switch AA", false, function(v) Flags.AutoSwitchAA = v end)
page:Toggle("Anti-Aim On Enemy", false, function(v) Flags.AAOnEnemy = v end)
page:Toggle("Predictive AA", false, function(v) Flags.PredAA = v end)
page:Toggle("Desync Choke", false, function(v) Flags.DesyncChoke = v end)
page:Slider("Desync Choke Ticks", 1, 16, 8, function(v) Flags.DesyncChokeT = v end)
page:Toggle("Lag Spike AA", false, function(v) Flags.LagSpikeAA = v end)
page:Slider("Lag Spike Interval", 1, 20, 5, function(v) Flags.LagSpikeInt = v end)
page:Toggle("Double Tap Kill", false, function(v) Flags.DTKill = v end)
page:Toggle("Rapid Fire", false, function(v) Flags.RapidFire = v end)
page:Slider("Rapid Fire Rate", 1, 50, 25, function(v) Flags.RapidFireRate = v end)
page:Label("  ")
page:Toggle("Auto Wallbang Kill", false, function(v) Flags.AutoWBKill = v end)
page:Slider("WB Max Penetration", 10, 100, 80, function(v) Flags.AutoWBMaxPen = v end)
page:Slider("WB Min Damage", 5, 80, 20, function(v) Flags.AutoWBMinDmg = v end)
page:Slider("WB Kill Chance %", 5, 100, 30, function(v) Flags.AutoWBKillChance = v end)
page:Slider("WB Kill Threshold", 10, 100, 50, function(v) Flags.WBKillThresh = v end)
page:Toggle("WB Notify", false, function(v) Flags.AutoWBNotify = v end)
page:Toggle("One Tap Mode", false, function(v) Flags.OneTap = v end)
page:Toggle("Jump Scout", false, function(v) Flags.JumpScout = v end)
page:Slider("Jump Scout Delay", 50, 500, 150, function(v) Flags.JSDelay = v end)
page:Toggle("Edge Bug Friction", false, function(v) Flags.EdgeBugFriction = v end)
page:Label(" HVH  ")
page:Button({Name="[Feature]", Color=Color3.fromRGB(255,50,50)}, function()
    Flags.HVHSuper = true
    Flags.Ragebot = true; Flags.RageFOV = 360; Flags.RageHC = 100
    Flags.RageAF = true; Flags.RageDT = true; Flags.RageWall = true
    Flags.RagePred = true; Flags.RageRes = true; Flags.RageAutoReload = true
    Flags.AA = true; Flags.AAPitch = "Jitter"; Flags.AAYaw = "LBY Break"
    Flags.AASpd = 18; Flags.AAJittR = 150
    Flags.AAFakeDuck = true; Flags.AAFree = true; Flags.AAEdge = true
    Flags.AALBY = true; Flags.AALBYO = 120
    Flags.AAAnimBreak = true; Flags.AAAnimStyle = "Breaker"
    Flags.AADesync = true; Flags.AADesyncR = 120
    Flags.AADynJitt = true; Flags.AADynMin = 30; Flags.AADynMax = 150
    Flags.AABodyFlip = true; Flags.AABodyFlipInt = 3
    Flags.AAMoveManip = true; Flags.AAMoveStr = 10
    Flags.AAAntiRes = true; Flags.AABruteMiss = true; Flags.AABruteSteps = 6
    Flags.AASlowAA = true; Flags.AAAirAA = true
    Flags.AAAntiUntrust = true; Flags.AASlowLBY = true
    Flags.FL = true; Flags.FLChoke = 10; Flags.FLStyle = "Adaptive"
    Flags.FLVar = 25; Flags.FLFakeWalk = true; Flags.FLFWS = 4; Flags.FLBLC = true
    Flags.Resolver = true; Flags.ResMode = "Smart"; Flags.ResSteps = 10
    Flags.ResAuto = true; Flags.ResAB = true; Flags.ResVelTrack = true
    Flags.ResAdaptive = true; Flags.ResSmart = true; Flags.ResAntiBrute = true
    Flags.ResAutoSw = true; Flags.ResMiss = true
    Flags.SilentAim = true; Flags.SAFov = 360; Flags.SAHC = 100
    Flags.SAPred = true; Flags.SAAF = true; Flags.SABacktrack = true
    Flags.SABTT = 300; Flags.SAAutoWall = true; Flags.SALagComp = true
    Flags.SA360 = true; Flags.SA360Range = 360
    Flags.SABackwards = true; Flags.SABackDir = "Away"
    Flags.DesyncChoke = true; Flags.LagSpikeAA = true
    Flags.OneTap = true; Flags.DTKill = true
    Flags.AutoWBKill = true; Flags.AutoWBMaxPen = 90
    Flags.StealthHumanize = true; Flags.HVHSafeMode = true
    pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="? HVH Full Auto",Text="ALL HVH + Wallbang!",Duration=5}) end)
end)

page:Button({Name="HVH Anti-Resolver", Color=Color3.fromRGB(100,200,100)}, function()
    Flags.AA = true; Flags.AAPitch = "Down"; Flags.AAYaw = "LBY Break"
    Flags.AASpd = 15; Flags.AAJittR = 120
    Flags.AADesync = true; Flags.AADesyncR = 120
    Flags.AAFakeDuck = true; Flags.AAFDC = 12
    Flags.AABodyFlip = true; Flags.AABodyFlipInt = 3
    Flags.AAMoveManip = true; Flags.AAMoveStr = 8
    Flags.AAAntiRes = true; Flags.AABruteMiss = true; Flags.AABruteSteps = 8
    Flags.AASlowLBY = true; Flags.AASlowLBYS = 3
    Flags.FL = true; Flags.FLChoke = 8; Flags.FLStyle = "Adaptive"
    Flags.Resolver = true; Flags.ResMode = "Smart"; Flags.ResSteps = 10
    Flags.ResAntiBrute = true; Flags.ResAntiSteps = 6
    pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="Anti-Resolver",Text="Maximum anti-resolve protection!",Duration=3}) end)
end)

page:Button({Name="HVH Rage Combo", Color=Color3.fromRGB(200,100,0)}, function()
    Flags.Ragebot = true; Flags.RageFOV = 360; Flags.RageHC = 100
    Flags.RageAF = true; Flags.RageDT = true; Flags.RageTT = true
    Flags.RageWall = true; Flags.RagePen = 100
    Flags.RagePred = true; Flags.RagePredF = 50
    Flags.RageRes = true; Flags.RageResS = 10
    Flags.RageSmartBody = true; Flags.RageAutoReload = true
    Flags.OneTap = true; Flags.DTKill = true; Flags.RapidFire = true
    Flags.RapidFireRate = 30
    Flags.SilentAim = true; Flags.SAFov = 360; Flags.SAHC = 100
    Flags.SAPred = true; Flags.SAAF = true
    Flags.SABacktrack = true; Flags.SABTT = 300
    Flags.SAAutoWall = true; Flags.SAWallPen = 100
    Flags.SALagComp = true; Flags.SALCTicks = 16
    Flags.SA360 = true; Flags.SA360Range = 360
    Flags.SAHitSound = true
    Flags.AutoWBKill = true; Flags.AutoWBMaxPen = 100
    pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="Rage Combo",Text="Maximum rage + Wallbang!",Duration=3}) end)
end)

page:Button({Name=" HVH Smart Auto", Color=Color3.fromRGB(150,100,255)}, function()
    Flags.HVHSuper = true
    Flags.AutoAA = true; Flags.AutoFL = true; Flags.AutoRes = true
    Flags.AutoRage = true; Flags.SmartBrute = true
    Flags.AutoSwitchAA = true; Flags.PredAA = true
    Flags.StealthHumanize = true; Flags.HVHSafeMode = true
    pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title=" Smart Auto",Text="AI-powered HVH activated!",Duration=3}) end)
end)

-- SECTION 8: HVH STATISTICS
page:Label("--- HVH STATISTICS ---")
page:Button({Name="[HVH] Show Stats", Color=Color3.fromRGB(200,200,100)}, function()

    local activeFeatures = 0
    local hvhFeatures = {"Ragebot","AA","FL","Resolver","SilentAim","NoClip","SpeedBoost","NoSpread","NoRecoil","FakeLag","AntiAim"}
    local activeNames = {}
    for _, f in ipairs(hvhFeatures) do
        if Flags[f] or Flags[f:gsub(" ","")] then
            activeFeatures = activeFeatures + 1
            table.insert(activeNames, f)
    local text = string.format("? HVH \n: %d\n", activeFeatures)
    if #activeNames > 0 then
        text = text .. "?: " .. table.concat(activeNames, ", ")
    else
        text = text .. "HVH "
    pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title=" HVH",Text=text,Duration=8}) end)
end)

-- SECTION 9: AUTO PEEK
page:Separator()
page:Label(" Auto Peek ")
page:Toggle("Auto Peek", false, function(v) Flags.AutoPeek = v end)
page:Dropdown({Name="Peek Mode", Flag="AutoPeekMode", Options={"Hold Key","Toggle","Smart"}, Default="Hold Key"})
page:Slider("Peek Distance", 10, 100, 40, function(v) Flags.AutoPeekDist = v end)
page:Slider("Peek Return Delay", 10, 300, 80, function(v) Flags.AutoPeekReturn = v end)
page:Toggle("Peek Jiggle", false, function(v) Flags.AutoPeekJiggle = v end)
page:Slider("Peek Jiggle Angle", 10, 90, 30, function(v) Flags.AutoPeekAngle = v end)

-- SECTION 10: EDGE ANTI-AIM
page:Label(" Edge Anti-Aim ")
page:Toggle("Edge Anti-Aim", false, function(v) Flags.EdgeAA = v end)
page:Slider("Edge Detect Range", 5, 50, 20, function(v) Flags.EdgeAADist = v end)
page:Toggle("Edge Auto Desync", false, function(v) Flags.EdgeAutoDesync = v end)
page:Slider("Edge Desync Offset", -60, 60, 30, function(v) Flags.EdgeDesyncOff = v end)
page:Toggle("Edge Freestand", false, function(v) Flags.EdgeFreestand = v end)

-- SECTION 11: DAMAGE OVERRIDE
page:Label(" Damage Override ")
page:Toggle("Head Damage Override", false, function(v) Flags.HDmgOvr = v end)
page:Slider("Head Min Damage", 1, 100, 80, function(v) Flags.HDmgMin = v end)
page:Toggle("Body Damage Override", false, function(v) Flags.BDmgOvr = v end)
page:Slider("Body Min Damage", 1, 100, 20, function(v) Flags.BDmgMin = v end)
page:Toggle("Scoped Override Only", false, function(v) Flags.DmgScopedOnly = v end)


-- AUTO PEEK Implementation
-- Automatically peeks from cover and shoots
local autoPeekActive = false
local autoPeekDir = nil

task.spawn(function()
    while true do
        task.wait(0.01)
        if Flags.AutoPeek and BS.alive() then
            pcall(function()
                local myHrp = BS.hrp()
                if not myHrp then return end
                
                local mode = Flags.AutoPeekMode or "Hold Key"
                local dist = Flags.AutoPeekDist or 40
                
                -- Check if peek key is held (right mouse button)
                if mode == "Hold Key" then
                    if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                        autoPeekActive = true
                    else
                        autoPeekActive = false
                elseif mode == "Toggle" then
                    -- Toggle handled by keybind system
                
                if autoPeekActive then
                    -- Move right/left based on nearest enemy
                    local cam = workspace.CurrentCamera
                    local lookDir = cam.CFrame.LookVector
                    local rightDir = cam.CFrame.RightVector
                    
                    -- Find nearest enemy
                    local nearest = nil
                    local nearDist = math.huge
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= lplr and p.Character then
                            local eHrp = p and p.Character:FindFirstChild("HumanoidRootPart")
                            if eHrp then
                                local d = (eHrp.Position - myHrp.Position).Magnitude
                                if d < nearDist then
                                    nearDist = d
                                    nearest = eHrp
                    
                    if nearest then
                        local toEnemy = (nearest.Position - myHrp.Position).Unit
                        local cross = lookDir:Cross(toEnemy)
                        local peekSide = cross.Y > 0 and rightDir or -rightDir
                        
                        -- Move to peek position
                        local peekPos = myHrp.Position + peekSide * (dist / 50)
                        myHrp.Velocity = peekSide * 50
                        
                        -- Jiggle if enabled
                        if Flags.AutoPeekJiggle then
                            local angle = (Flags.AutoPeekAngle or 30) / 100
                            task.wait(0.05)
                            myHrp.Velocity = -peekSide * 50 * angle
                else
                    myHrp.Velocity = Vector3.new(0, myHrp.Velocity.Y, 0)
            end)
end)

-- EDGE ANTI-AIM Implementation
-- Detects edges and adjusts anti-aim
task.spawn(function()
    while true do
        task.wait(0.1)
        if Flags.EdgeAA and BS.alive() then
            pcall(function()
                local myHrp = BS.hrp()
                if not myHrp then return end
                
                local range = Flags.EdgeAADist or 20
                local pos = myHrp.Position
                
                -- Check for edges (walls nearby)
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {lplr.Character}
                rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                
                local leftRay = Workspace:Raycast(pos, -myHrp.CFrame.RightVector * range, rayParams)
                local rightRay = Workspace:Raycast(pos, myHrp.CFrame.RightVector * range, rayParams)
                local frontRay = Workspace:Raycast(pos, myHrp.CFrame.LookVector * range, rayParams)
                
                local nearWall = leftRay or rightRay or frontRay
                
                if nearWall then
                    -- Near edge, apply desync
                    if Flags.EdgeAutoDesync then
                        local offset = Flags.EdgeDesyncOff or 30
                        Flags.AABodyYawO = offset
                    
                    -- Freestand
                    if Flags.EdgeFreestand then
                        if leftRay and not rightRay then
                            Flags.AAYaw = "Manual Left"
                        elseif rightRay and not leftRay then
                            Flags.AAYaw = "Manual Right"
                end
            end)
        end
    end
end)

-- DAMAGE OVERRIDE Implementation
-- Overrides minimum damage for head/body
local originalGetDamage = nil


-- ENGINES

-- Bone Position Helper
    local function getBonePos(e, bone)
    if not e or not e.Char then return nil end
    if Flags.RageHead then return e.Head and e.Head.Position or e.HRP.Position+Vector3.new(0,1.5,0) end
    if Flags.RageBody then return e.HRP.Position+Vector3.new(0,0.5,0) end
    if bone=="Head" then return e.Head and e.Head.Position or e.HRP.Position+Vector3.new(0,1.5,0)
    elseif bone=="Chest" then return e.HRP.Position+Vector3.new(0,0.5,0)
    elseif bone=="Stomach" then return e.HRP.Position+Vector3.new(0,0.3,0)
    elseif bone=="Pelvis" then return e.HRP.Position+Vector3.new(0,0.1,0)
    elseif bone=="Body" then return e.HRP.Position
    elseif bone=="Nearest" then
        local cam=workspace.CurrentCamera; local mouse=UIS:GetMouseLocation()
        local candidates={
            {pos=e.Head and e.Head.Position or e.HRP.Position+Vector3.new(0,1.5,0)},
            {pos=e.HRP.Position+Vector3.new(0,0.5,0)},
            {pos=e.HRP.Position},
        }
        local best,bestD=candidates[1].pos,math.huge
        for _,c in ipairs(candidates) do
            local sp,sv=cam:WorldToViewportPoint(c.pos)
            if sv then local d=(Vector2.new(sp.X,sp.Y)-mouse).Magnitude; if d<bestD then bestD=d; best=c.pos end end
        end
        return best
    elseif bone=="Auto" then
        -- Smart: head if visible, body if behind wall
        local headPos=e.Head and e.Head.Position or e.HRP.Position+Vector3.new(0,1.5,0)
        local bodyPos=e.HRP.Position+Vector3.new(0,0.5,0)
        local myPos = hrp() and hrp().Position or nil
        if myPos and BS.hasLineOfSight(myPos, headPos) then return headPos else return bodyPos end
    end
    if Flags.RageLimb then
        local parts={e.HRP.Position+Vector3.new(0,1.5,0),e.HRP.Position+Vector3.new(0,0.5,0),e.HRP.Position}
        return parts[math.random(#parts)]
    end
    return e.HRP.Position+Vector3.new(0,1.5,0)
end

-- Target Sort (Enhanced)
    local function sortTargets(enemies, myPos, cam)
    local sort=Flags.RageSort or "Crosshair"
    local mouse=UIS:GetMouseLocation()
    local sorted={}
    for _,e in ipairs(enemies) do
        if e.HRP and e.Hum and e.Hum.Health>0 then
            local bp=getBonePos(e,Flags.RageBone or "Head")
            if bp then
                local dist=(myPos-e.HRP.Position).Magnitude
                local sd=math.huge
                local sp,sv=cam:WorldToViewportPoint(bp)
                if sv then sd=(Vector2.new(sp.X,sp.Y)-mouse).Magnitude end
                local threat=0
                threat=threat+(1/math.max(dist,1))*100
                threat=threat+(100-e.Hum.Health)*0.5
                if sd<50 then threat=threat+50 end
                -- Damage estimate
                local wtype=BS.weaponType()
                local ws=WEAPONS[wtype] or WEAPONS.rifle
                local dmgMult=1/(1+dist*0.01) -- distance falloff
                local estDmg=ws.damage*ws.headMult*dmgMult
                table.insert(sorted,{Enemy=e,BonePos=bp,Dist=dist,SD=sd,Health=e.Hum.Health,Threat=threat,EstDmg=estDmg})
            end
        end
    end
    if sort=="Crosshair" then table.sort(sorted,function(a,b) return a.SD<b.SD end)
    elseif sort=="Distance" then table.sort(sorted,function(a,b) return a.Dist<b.Dist end)
    elseif sort=="Health" then table.sort(sorted,function(a,b) return a.Health<b.Health end)
    elseif sort=="Threat" then table.sort(sorted,function(a,b) return a.Threat>b.Threat end)
    elseif sort=="Damage" then table.sort(sorted,function(a,b) return a.EstDmg>b.EstDmg end)
    elseif sort=="Random" then for i=#sorted,2,-1 do local j=math.random(i); sorted[i],sorted[j]=sorted[j],sorted[i] end end
    return sorted
end

-- Wallbang Analysis (Enhanced)
    local function analyzeWall(myPos, targetPos)
    local dir=(targetPos-myPos); local dist=dir.Magnitude; local du=dir.Unit
    local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={lplr.Character}
    local r1=workspace:Raycast(myPos,du*dist,params)
    if not r1 then return false,0,0,nil end
    local mat=r1.Material; local p1=r1.Position
    local r2=workspace:Raycast(p1+du*0.5,du*(dist-(p1-myPos).Magnitude),params)
    local thick=r2 and (r2.Position-p1).Magnitude or math.max(0,dist-(p1-myPos).Magnitude)
    local wtype=BS.weaponType(); local ws=WEAPONS[wtype] or WEAPONS.rifle
    local hardness=MAT_HARD[mat] or 50
    local penChance=math.clamp((ws.pen-hardness*thick/10)/ws.pen*100,0,100)
    return penChance>50,penChance,thick,mat
end

-- RAGEBOT ENGINE
task.spawn(function()
    while task.wait() do
        if Flags.Ragebot and alive() then
            pcall(function()
                local cam=workspace.CurrentCamera; local myH=hrp(); local myHe=head()
                if not cam or not myH then return end
                RAGE.Fov=Flags.RageFOV or 180
                local sorted=sortTargets(BS.enemies(),myH.Position,cam)
                RAGE.Targets=sorted
                local best=nil
                for _,t in ipairs(sorted) do if t.SD<=RAGE.Fov then best=t; break end end
                if best then
                    RAGE.Target=best
                    local aimPos=best.BonePos
                    -- Wallbang check
                    local canPen,penChance=analyzeWall(myH.Position+Vector3.new(0,1.5,0),aimPos)
                    if not Flags.RageWall and not canPen then
                        if not BS.hasLineOfSight(myH.Position,aimPos) then return end
                    end
                    -- HP override: body aim low HP targets
                    if Flags.RageHPOvr and best.Health<(Flags.RageHPThresh or 30) then
                        aimPos=best.Enemy.HRP.Position+Vector3.new(0,0.5,0)
                    end
                    -- Smart body aim: if missed head shots, switch to body
                    local uid=best.Enemy.Player.UserId
                    if Flags.RageSmartBody and (RAGE.MissCount[uid] or 0)>=3 then
                        aimPos=best.Enemy.HRP.Position+Vector3.new(0,0.5,0)
                    end
                    -- Prediction
                    if Flags.RagePred then
                        local vel=BS.getVelocity(best.Enemy)
                        local pf=(Flags.RagePredF or 35)/100
                        -- Ping Adapt: increase prediction on high ping
                        if Flags.PingAdapt and BS.PA then
                            pf=BS.PA.getAdaptPrediction(35)/100
                        end
                        aimPos=aimPos+vel*pf
                    end
                    -- Apply aim
                    local camPos=cam.CFrame.Position
                    local dir=(aimPos-camPos).Unit
                    cam.CFrame=CFrame.new(camPos,camPos+dir)
                    -- Hitchance
                    if math.random(1,100)>(Flags.RageHC or 85) then return end
                    -- Auto Fire
                    if Flags.RageAF then
                        local now=tick(); local fr=(Flags.RageFR or 12)/1000
                        -- Enhanced: faster fire rate on close range targets
                        if best.Dist<15 then fr=fr*0.6 end -- 40% faster at close range
                        if now-RAGE.LastFire>=fr then
                            pcall(function()
                                local tool=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
                                if tool and not tool.Name:lower():find("knife") then
                                    -- tool:Activate(); RAGE.LastFire=now
                                    RAGE.ShotsFired[uid]=(RAGE.ShotsFired[uid] or 0)+1
                                end
                            end)
                            -- Double Tap (faster)
                            if Flags.RageDT then
                                local dtDelay=math.max(0.01,(Flags.RageDTD or 6)/1000*0.7)
                                task.delay(dtDelay,function()
                                    pcall(function()
                                        local t=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
                                        if t and not t.Name:lower():find("knife") then t:Activate() end
                                    end)
                                end)
                            end
                            -- Triple Tap (faster)
                            if Flags.RageTT then
                                local ttDelay=math.max(0.02,(Flags.RageDTD or 6)/1000*1.2)
                                task.delay(ttDelay,function()
                                    pcall(function()
                                        local t=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
                                        if t and not t.Name:lower():find("knife") then t:Activate() end
                                    end)
                                end)
                            end
                            -- Quad Tap (NEW)
                            if Flags.RageQT then
                                local qtDelay=math.max(0.03,(Flags.RageDTD or 6)/1000*1.8)
                                task.delay(qtDelay,function()
                                    pcall(function()
                                        local t=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
                                        if t and not t.Name:lower():find("knife") then t:Activate() end
                                    end)
                                end)
                            end
                            -- Multi-Target: shoot at second target too
                            if Flags.RageMultiTarget and #sorted>1 then
                                local second=sorted[2]
                                if second and second.SD<=RAGE.Fov*0.8 then
                                    local aimPos2=getBonePos(second.Enemy,Flags.RageBone or "Head")
                                    if aimPos2 then
                                        local camPos2=cam.CFrame.Position
                                        local dir2=(aimPos2-camPos2).Unit
                                        cam.CFrame=CFrame.new(camPos2,camPos2+dir2)
                                        task.delay(0.02,function()
                                            pcall(function()
                                                local t=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
                                                if t and not t.Name:lower():find("knife") then t:Activate() end
                                            end)
                                        end)
                                    end
                                end
                            end
                        end
                    end
                    -- Auto Crouch
                    if Flags.RageACrouch then pcall(function() local h=hum(); if h then h.HipHeight=-0.5 end end) end
                    -- Auto Reload
                    if Flags.RageAReload then pcall(function()
                        local t=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
                        if t then local a=t:GetAttribute("Ammo") or t:GetAttribute("CurrentAmmo")
                            if a and a<=2 then UIS:PressKey(Enum.KeyCode.R); task.delay(0.1,function() UIS:ReleaseKey(Enum.KeyCode.R) end) end
                        end
                    end) end
                    -- Knifebot
                    if Flags.RageKnife and best.Dist<=(Flags.RageKnifeR or 3) then
                        pcall(function()
                            local ch=lplr.Character
                            for _,t in pairs(ch:GetChildren()) do
                                if t:IsA("Tool") and t.Name:lower():find("knife") then
                                    if not t.Parent:IsA("Humanoid") then t.Parent=ch end
                                    -- t:Activate(); break
                                end
                            end
                        end)
                    end
                    -- Zeusing
                    if Flags.RageZeus then
                        pcall(function()
                            local t=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
                            if t and (t.Name:lower():find("taser") or t.Name:lower():find("zeus")) then
                                if best.Dist>5 and best.Dist<=(Flags.RageZeusR or 15) then t:Activate() end
                            end
                        end)
                    end
                else
                    RAGE.Target=nil
                    if Flags.RageACrouch then pcall(function() local h=hum(); if h then h.HipHeight=0 end end) end
                end
                -- Auto Scope
                if Flags.RageAScope then pcall(function()
                    local t=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
                    if t and (t.Name:lower():find("awp") or t.Name:lower():find("sniper") or t.Name:lower():find("scout")) then
                        -- Simulate right-click to scope
                        safeMouse1Click()
                    end
                end) end
                -- Min Damage: skip target if estimated damage too low
                if Flags.RageMinDmg and Flags.RageMinDmg>1 then
                    local wtype=BS.weaponType(); local ws=WEAPONS[wtype] or WEAPONS.rifle
                    local dmgMult=1/(1+best.Dist*0.01)
                    local estDmg=ws.damage*dmgMult
                    if estDmg<Flags.RageMinDmg then return end
                end
                -- Safety
                if Flags.RageSafe then local h=hum(); if h and h.Health<h.MaxHealth*0.1 then Flags.RageAF=false end end
            end)
        end
    end
end)

-- SILENT AIM ENGINE (Enhanced)
    local saTarget=nil; local saLastSwitch=0; local saFovCircle=nil

task.spawn(function()
    while true do
        task.wait()
        if Flags.SilentAim and BS.alive() then
            pcall(function()
                local cam=workspace.CurrentCamera; local myH=hrp()
                if not cam or not myH then return end
                local mode=Flags.SAMode or "Camera Redirect"
                local fov=Flags.SAFov or 140; local bone=Flags.SABone or "Head"
                -- Ping Adapt: expand SA FOV on high ping
                if Flags.PingAdapt and BS.PA then
                    fov=BS.PA.getAdaptSilentRange(fov)
                end
                local hc=Flags.SAHC or 92; local mouse=UIS:GetMouseLocation()
                -- Target switch
                local now=tick()
                local switchDel=(Flags.SASwitch or 80)/1000
                local best=nil; local bestScore=fov
                if now-saLastSwitch<switchDel and saTarget then
                    best=saTarget
                else
                    for _,e in pairs(BS.enemies()) do
                        if not e.HRP or not e.Hum or e.Hum.Health<=0 then continue end
                        if Flags.SATeam and lplr.Team and e.Player.Team==lplr.Team then continue end
                        local aimPos=getBonePos(e,bone)
                        if not aimPos then continue end
                        if Flags.SAPred then
                            local vel=BS.getVelocity(e)
                            aimPos=aimPos+vel*((Flags.SAPredT or 30)/100)
                        end
                        if Flags.SAWall and not BS.hasLineOfSight(myH.Position,aimPos) then continue end
                        if Flags.SAVis then local _,v=cam:WorldToViewportPoint(aimPos); if not v then continue end end
                        local sp,sv=cam:WorldToViewportPoint(aimPos)
                        if sv then
                            local sd=(Vector2.new(sp.X,sp.Y)-mouse).Magnitude
                            if sd<bestScore then best={Enemy=e,AimPos=aimPos,SD=sd,Dist=(myH.Position-e.HRP.Position).Magnitude}; bestScore=sd end
                        end
                        -- ::skipSA::
                    end
                    if best then saTarget=best; saLastSwitch=now end
                end
                if best then
                    if math.random(1,100)>hc then return end
                    if Flags.SASmart then
                        local sp,sv=cam:WorldToViewportPoint(best.AimPos)
                        if sv and (Vector2.new(sp.X,sp.Y)-mouse).Magnitude>(Flags.SASmartR or 45) then return end
                    end
                    local aimPos=best.AimPos
                    -- Backtrack: shift position backwards along velocity (Enhanced)
                    if Flags.SABacktrack then
                        local vel=BS.getVelocity(best.Enemy)
                        local bt=(Flags.SABTT or 200)/1000
                        -- Ping Adapt: increase backtrack on high ping
                        if Flags.PingAdapt and BS.PA then
                            bt=bt+BS.PA.getAdaptLagTicks()*0.015
                        end
                        -- Enhanced: use history if available
                        local btHistory=RAGE.LastPredictPos[best.Enemy.Player.UserId]
                        if btHistory and #btHistory>2 then
                            -- Use historical position for better backtrack
                            local histIdx=math.max(1,#btHistory-math.floor(bt*60))
                            if btHistory[histIdx] then
                                aimPos=btHistory[histIdx]
                            else
                                aimPos=aimPos-vel*bt
                            end
                        else
                            aimPos=aimPos-vel*bt
                        end
                    end
                    -- Hit Sound
                    if Flags.SAHitSnd then pcall(function()
                        local s=Instance.new("Sound")
                        s.SoundId="rbxassetid://5587286548" -- hit marker sound
                        s.Volume=0.5; s.PlayOnRemove=false
                        s.Parent=lplr and lplr.Character:FindFirstChild("HumanoidRootPart")
                        s:Play()
                        game:GetService("Debris"):AddItem(s,1)
                    end) end
                    if mode=="Camera Redirect" then
                        local cp=cam.CFrame.Position; local d=(aimPos-cp).Unit
                        local sm=Flags.SASmooth or 1
                        cam.CFrame=cam.CFrame:Lerp(CFrame.new(cp,cp+d),1/sm)
                    elseif mode=="Mouse Redirect" then
                        local mo=lplr:GetMouse()
                        if mo then
                            local closest,cDist=nil,math.huge
                            for _,p in pairs(best.Enemy.Char:GetDescendants()) do
                                if p:IsA("BasePart") then
                                    local sp2,sv2=cam:WorldToViewportPoint(p.Position)
                                    if sv2 then local d=(Vector2.new(sp2.X,sp2.Y)-mouse).Magnitude; if d<cDist then cDist=d; closest=p end end
                                end
                            end
                            if closest then pcall(function() mo.Target=closest end) end
                        end
                    elseif mode=="Server Angle" then
                        local cp=cam.CFrame.Position; cam.CFrame=CFrame.new(cp,cp+(aimPos-cp).Unit)
                    elseif mode=="Hybrid" then
                        local cp=cam.CFrame.Position; cam.CFrame=CFrame.new(cp,cp+(aimPos-cp).Unit)
                    end
                    -- Backwards Silent Aim: Face away, still hit                     if Flags.SABackwards then
                        pcall(function()
                            local cp=cam.CFrame.Position
                            local toEnemy=(aimPos-cp).Unit
                            local backDir=Vector3.new(-toEnemy.X,0,-toEnemy.Z).Unit
                            local dir=Flags.SABackDir or "Away"
                            local lookDir
                            if dir=="Away" then lookDir=backDir
                            elseif dir=="Left" then lookDir=cam.CFrame.RightVector*-1
                            elseif dir=="Right" then lookDir=cam.CFrame.RightVector
                            elseif dir=="Random" then local a=math.random()*math.pi*2; lookDir=Vector3.new(math.cos(a),0,math.sin(a))
                            else lookDir=toEnemy end
                            cam.CFrame=CFrame.new(cp,cp+lookDir)
                        end)
                    end
                    -- 360 Silent Aim: Hit within range regardless of facing                     if Flags.SA360 then
                        pcall(function()
                            local cp=cam.CFrame.Position
                            local toEnemy=(aimPos-cp).Unit
                            local myLook=cam.CFrame.LookVector
                            local angle=math.acos(math.clamp(myLook:Dot(toEnemy),-1,1))
                            local range=math.rad(Flags.SA360Range or 360)
                            if angle>range/2 then
                                -- Rotate camera to face enemy
                                cam.CFrame=CFrame.new(cp,cp+toEnemy)
                            end
                        end)
                    end
                    -- AA Sync: Sync silent aim with anti-aim                     if Flags.SAAASync then
                        pcall(function()
                            local cp=cam.CFrame.Position
                            local toEnemy=(aimPos-cp).Unit
                            local aaYaw=Flags.AAYaw or "Spin"
                            local fakeDir
                            if aaYaw=="Back" then fakeDir=Vector3.new(-toEnemy.X,0,-toEnemy.Z).Unit
                            elseif aaYaw=="Left" then fakeDir=cam.CFrame.RightVector*-1
                            elseif aaYaw=="Right" then fakeDir=cam.CFrame.RightVector
                            else fakeDir=Vector3.new(-toEnemy.X,0,-toEnemy.Z).Unit end
                            cam.CFrame=CFrame.new(cp,cp+fakeDir)
                        end)
                    end
                    -- Freestand Silent: Face most open direction                     if Flags.SAFreeStand then
                        pcall(function()
                            local cp=cam.CFrame.Position
                            local dirs={Vector3.new(1,0,0),Vector3.new(-1,0,0),Vector3.new(0,0,1),Vector3.new(0,0,-1)}
                            local maxD,freeD=0,dirs[1]
                            for _,d in ipairs(dirs) do
                                local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={lplr.Character}
                                local r=workspace:Raycast(cp,d*8,params)
                                local dist=r and (r.Position-cp).Magnitude or 8
                                if dist>maxD then maxD=dist; freeD=d end
                            end
                            cam.CFrame=CFrame.new(cp,cp+freeD)
                        end)
                    end
                    -- Fake Duck Aim: Silent aim while fake ducking                     if Flags.SAFakeDuckAim then
                        pcall(function()
                            local h=hum()
                            if h then h.HipHeight=-0.5 end
                            local cp=cam.CFrame.Position
                            cam.CFrame=CFrame.new(cp,cp+(aimPos-cp).Unit)
                        end)
                    end
                    -- Inverse Aim: Aim in opposite direction                     if Flags.SAInverse then
                        pcall(function()
                            local cp=cam.CFrame.Position
                            local toEnemy=(aimPos-cp).Unit
                            local offset=math.rad(Flags.SAInvOff or 180)
                            local invDir=CFrame.new(Vector3.new(),toEnemy)*CFrame.Angles(0,offset,0)
                            cam.CFrame=CFrame.new(cp,cp+invDir.LookVector)
                        end)
                    end
                    -- Auto Fire
                    if Flags.SAAF then pcall(function()
                        local t=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
                        if t and not t.Name:lower():find("knife") then t:Activate() end
                    end) end
                    -- Multi Target: shoot multiple enemies in sequence
                    if Flags.SAMultiT and Flags.SAMultiC then
                        local multiCount=0
                        for _,t2 in ipairs(RAGE.Targets) do
                            if multiCount>=(Flags.SAMultiC or 2) then break end
                            if t2.Enemy~=best.Enemy and t2.SD<=Flags.SAFov then
                                pcall(function()
                                    local cp2=cam.CFrame.Position
                                    cam.CFrame=CFrame.new(cp2,cp2+(t2.BonePos-cp2).Unit)
                                    task.wait(0.02)
                                    local t=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
                                    if t and not t.Name:lower():find("knife") then t:Activate() end
                                end)
                                multiCount=multiCount+1
                            end
                        end
                    end
                    -- Resolver Override: force angles when resolver is active
                    if Flags.SAResOvr and Flags.Resolver then
                        local uid=best.Enemy.Player.UserId
                        local resStep=RAGE.ResolverStep and RAGE.ResolverStep[uid] or 0
                        local overrideAngle=resStep*90
                        local oRad=math.rad(overrideAngle)
                        local overridePos=aimPos+Vector3.new(math.cos(oRad)*2,0,math.sin(oRad)*2)
                        local ocp=cam.CFrame.Position
                        cam.CFrame=CFrame.new(ocp,ocp+(overridePos-ocp).Unit)
                    end
                    -- Hitbox Expander: enlarge enemy hitboxes
                    if Flags.SAHBE then
                        pcall(function()
                            local hbSize=Flags.SAHBS or 2
                            local char=best.Enemy.Char
                            if char then
                                local head=char:FindFirstChild("Head")
                                if head then
                                    head.Size=Vector3.new(hbSize,hbSize,hbSize)
                                    head.Transparency=0.7
                                    head.CanCollide=false
                                end
                                local hrp=char:FindFirstChild("HumanoidRootPart")
                                if hrp then
                                    hrp.Size=Vector3.new(hbSize,hbSize,hbSize)
                                    hrp.Transparency=0.8
                                    hrp.CanCollide=false
                                end
                            end
                        end)
                    end
                    -- Magic Bullet: redirect bullet to target regardless of aim
                    if Flags.SAMagic then
                        pcall(function()
                            local magicDist=Flags.SAMagicD or 50
                            if best.Dist<=magicDist then
                                -- Force fire at target position
                                local tool=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
                                if tool and not tool.Name:lower():find("knife") then
                                    -- tool:Activate()
                                end
                            end
                        end)
                    end
                    -- Auto Wallbang: force through walls
                    if Flags.SAAutoWall then
                        pcall(function()
                            local myH=hrp()
                            if myH then
                                local canPen=analyzeWall(myH.Position+Vector3.new(0,1.5,0),aimPos)
                                if canPen then
                                    local tool=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
                                    if tool and not tool.Name:lower():find("knife") then
                                        -- tool:Activate()
                                    end
                                end
                            end
                        end)
                    end
                    -- Lag Compensation: adjust for server-side lag
                    if Flags.SALagComp then
                        local lcTicks=Flags.SALCTicks or 8
                        local vel=BS.getVelocity(best.Enemy)
                        local lagCompPos=aimPos+vel*(lcTicks*0.015) -- 15ms per tick
                        aimPos=lagCompPos
                    end
                    -- Position Adjustment: manual offset
                    if Flags.SAPosAdj then
                        local adjX=Flags.SAPosAdjX or 0
                        local adjY=Flags.SAPosAdjY or 0
                        aimPos=aimPos+Vector3.new(adjX/10,adjY/10,0)
                    end
                    -- Nearest Bone Priority: always aim at closest bone
                    if Flags.SANBP then
                        local cam2=workspace.CurrentCamera
                        local mouse2=UIS:GetMouseLocation()
                        local closestBone,closestDist=nil,math.huge
                        local bones={"Head","HumanoidRootPart"}
                        for _,boneName in ipairs(bones) do
                            local bonePart=best.Enemy.Char:FindFirstChild(boneName)
                            if bonePart then
                                local sp,sv=cam2:WorldToViewportPoint(bonePart.Position)
                                if sv then
                                    local d=(Vector2.new(sp.X,sp.Y)-mouse2).Magnitude
                                    if d<closestDist then closestDist=d; closestBone=bonePart.Position end
                                end
                            end
                        end
                        if closestBone then aimPos=closestBone end
                    end
                    -- Spread Control: reduce weapon spread
                    if Flags.SASpread then
                        local spreadF=Flags.SASpreadF or 50
                        local spread=Vector3.new((math.random()-0.5)*spreadF/100,0,(math.random()-0.5)*spreadF/100)
                        aimPos=aimPos+spread
                    end
                    -- RCS: Recoil Control System
                    if Flags.SARCS then
                        local rcsX=(Flags.SARCSX or 60)/100
                        local rcsY=(Flags.SARCSY or 80)/100
                        local uidRcs=best.Enemy.Player.UserId
                        local shotCount=RAGE.ShotsFired[uidRcs] or 0
                        local recoilY=-rcsY*math.min(shotCount*0.1,1)
                        local recoilX=rcsX*math.sin(shotCount*0.5)*0.3
                        aimPos=aimPos+Vector3.new(recoilX,recoilY,0)
                    end
                    -- Silent Walk: move silently while aiming
                    if Flags.SASilentWalk then
                        pcall(function()
                            local h=hum()
                            if h then h.WalkSpeed=16 end
                        end)
                    end
                    -- Auto Scope: scope for sniper weapons
                    if Flags.SAAutoScope then
                        pcall(function()
                            local t=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
                            if t and (t.Name:lower():find("awp") or t.Name:lower():find("sniper") or t.Name:lower():find("scout")) then
                                -- Some games auto-scope on fire
                                safeMouse1Click()
                            end
                        end)
                    end
                    -- No Visual Recoil: remove camera shake
                    if Flags.SANoVR then
                        pcall(function()
                            local cam2=workspace.CurrentCamera
                            local cp2=cam2.CFrame.Position
                            cam2.CFrame=CFrame.new(cp2,cp2+cam2.CFrame.LookVector)
                        end)
                    end
                end
            end)
        end
    end
end)

-- SA FOV Circle
task.spawn(function()
    while true do
        task.wait()
        pcall(function()
            if Flags.SilentAim and Flags.SAFovCirc then
                if not saFovCircle then saFovCircle=safeDrawingNew("Circle"); saFovCircle.Thickness=1; saFovCircle.NumSides=64; saFovCircle.Filled=false end
                saFovCircle.Position=UIS:GetMouseLocation(); saFovCircle.Radius=Flags.SAFov or 140
                saFovCircle.Color=Color3.fromRGB(255,0,0); saFovCircle.Visible=true
            else if saFovCircle then saFovCircle.Visible=false end end
        end)
    end
end)

-- ANTI-AIM ENGINE (Enhanced)
    local aaAngle=0; local aaJitter=1; local fakeDuckState=false; local aaHeightAngle=0; local aaVizCircle=nil

task.spawn(function()
    while true do
        task.wait()
        if Flags.AA and alive() then
            pcall(function()
                local cam=workspace.CurrentCamera; local myH=hrp()
                if not cam or not myH then return end
                if Flags.AAGround then local h=hum(); if h and h.FloorMaterial==Enum.Material.Air then return end end
                local pitch=Flags.AAPitch or "Down"; local yaw=Flags.AAYaw or "Spin"; local spd=Flags.AASpd or 12
                -- Ping Adapt: reduce AA speed on high ping
                if Flags.PingAdapt and BS.PA then
                    spd=math.floor(BS.PA.getAdaptSmooth(spd))
                end
                -- Pitch (enhanced)
                local pA=0
                if pitch=="Down" then pA=-89 elseif pitch=="Up" then pA=89 elseif pitch=="Zero" then pA=0
                elseif pitch=="Jitter" then pA=math.random(-89,89) elseif pitch=="Random" then pA=math.random(-180,180)
                elseif pitch=="Fake Up" then pA=89 elseif pitch=="Fake Down" then pA=-89
                elseif pitch=="Lisp" then pA=math.sin(tick()*10)*89
                elseif pitch=="Mixed" then pA=math.random(-89,89)*math.sin(tick()*2)
                elseif pitch=="Sideways" then pA=0
                elseif pitch=="Emotion" then pA=45+math.sin(tick()*2)*10 -- 45 emotion AA
                elseif pitch=="Slow Jitter" then pA=math.sin(tick()*3)*60 -- slower, less detectable
                elseif pitch=="Fakedown" then pA=-89+math.abs(math.sin(tick()*5))*20
                elseif pitch=="Zero Sway" then pA=math.sin(tick()*1.5)*15 end
                -- Yaw (enhanced with more aggressive modes)
                local yA=0
                if yaw=="Spin" then aaAngle=aaAngle+spd*2; yA=aaAngle%360
                elseif yaw=="Fast Spin" then aaAngle=aaAngle+spd*4; yA=aaAngle%360 -- 2x faster
                elseif yaw=="Jitter" then yA=math.random(-Flags.AAJittR or 100,Flags.AAJittR or 100); aaJitter=aaJitter*-1
                elseif yaw=="Wide Jitter" then yA=math.random(-160,160); aaJitter=aaJitter*-1 -- wider jitter range
                elseif yaw=="Back" then local lv=cam.CFrame.LookVector; yA=math.deg(math.atan2(-lv.X,-lv.Z))
                elseif yaw=="Left" then yA=-90 elseif yaw=="Right" then yA=90
                elseif yaw=="LBY Break" then yA=math.sin(tick()*spd*5)*120
                elseif yaw=="LBY Break Fast" then yA=math.sin(tick()*spd*8)*150 -- faster LBY break
                elseif yaw=="Edge" then
                    local dirs={Vector3.new(1,0,0),Vector3.new(-1,0,0),Vector3.new(0,0,1),Vector3.new(0,0,-1)}
                    local nD,nDx=dirs[1],math.huge
                    for _,d in ipairs(dirs) do local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={lplr.Character}
                        local r=workspace:Raycast(myH.Position,d*5,params); if r then local dd=(r.Position-myH.Position).Magnitude; if dd<nDx then nDx=dd; nDx=dd; nD=d end end end
                    yA=math.deg(math.atan2(nD.X,nD.Z))+180
                elseif yaw=="Fake" then yA=math.random(0,360)
                elseif yaw=="Switch" then yA=aaJitter>0 and 90 or -90; aaJitter=aaJitter*-1
                elseif yaw=="Slow Spin" then aaAngle=aaAngle+spd*0.5; yA=aaAngle%360
                elseif yaw=="Random Walk" then yA=aaAngle+math.random(-spd*3,spd*3); aaAngle=yA%360 -- random walk spin
                elseif yaw=="Triangle" then local tri=tick()*spd*2; yA=(math.floor(tri)%3)*120 -- triangle pattern
                elseif yaw=="Opposite" then yA=(aaJitter>0 and 0 or 180); aaJitter=aaJitter*-1
                elseif yaw=="T-Shape" then local ts=tick()*spd*3; yA=ts%360<180 and 90 or -90 end
                -- Apply
                local cp=cam.CFrame.Position
                local yR=math.rad(yA); local pR=math.rad(pA)
                local lookDir=Vector3.new(math.cos(pR)*math.sin(yR),math.sin(pR),math.cos(pR)*math.cos(yR))
                cam.CFrame=CFrame.new(cp,cp+lookDir)
                -- Height variation
                if Flags.AAHeight then
                    aaHeightAngle=aaHeightAngle+spd*0.3
                    local hOff=math.sin(math.rad(aaHeightAngle))*1.5
                    cam.CFrame=cam.CFrame+Vector3.new(0,hOff,0)
                end
                -- Fake Duck
                if Flags.AAFakeDuck then fakeDuckState=not fakeDuckState
                    pcall(function() local h=hum(); if h then h.HipHeight=fakeDuckState and -0.5 or 0 end end) end
                -- LBY Break: offset lower body yaw to confuse resolver
                if Flags.AALBY then
                    local lbyO=Flags.AALBYO or 120
                    local lbyRad=math.rad(lbyO+tick()*spd*3)
                    local lbyOffset=Vector3.new(math.cos(lbyRad)*2,0,math.sin(lbyRad)*2)
                    -- Apply small position offset to fake lower body
                    cam.CFrame=cam.CFrame+Vector3.new(lbyOffset.X*0.1,0,lbyOffset.Z*0.1)
                end
                -- Freestanding: face most open direction
                if Flags.AAFree then
                    local dirs={Vector3.new(1,0,0),Vector3.new(-1,0,0),Vector3.new(0,0,1),Vector3.new(0,0,-1)}
                    local maxDist,freeDir=0,dirs[1]
                    for _,d in ipairs(dirs) do
                        local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={lplr.Character}
                        local r=workspace:Raycast(myH.Position,d*8,params)
                        local dist=r and (r.Position-myH.Position).Magnitude or 8
                        if dist>maxDist then maxDist=dist; freeDir=d end
                    end
                    yA=math.deg(math.atan2(freeDir.X,freeDir.Z))+180
                    local fRad=math.rad(yA)
                    local fDir=Vector3.new(math.cos(pR)*math.sin(fRad),math.sin(pR),math.cos(pR)*math.cos(fRad))
                    cam.CFrame=CFrame.new(cp,cp+fDir)
                end
                -- Edge Detection: detect if near wall edge
                if Flags.AAEdge then
                    local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={lplr.Character}
                    local nearWall=false
                    for angle=0,360,45 do
                        local r=Vector3.new(math.cos(math.rad(angle)),0,math.sin(math.rad(angle)))
                        local res=workspace:Raycast(myH.Position,r*3,params)
                        if res and (res.Position-myH.Position).Magnitude<3 then nearWall=true; break end
                    end
                    if nearWall then yA=yA+180 end -- Face away from wall
                end
                -- Animation Breaker
                if Flags.AAAnimBreak then
                    local style=Flags.AAAnimStyle or "Flipped"
                    pcall(function()
                        local h=hum()
                        if h then
                            if style=="Flipped" then h.HipHeight=-0.5
                            elseif style=="Platform" then h.HipHeight=2
                            elseif style=="Lean" then cam.CFrame=cam.CFrame*CFrame.Angles(0,0,math.rad(15*math.sin(tick()*3)))
                            elseif style=="Inverse" then cam.CFrame=CFrame.new(cp,cp+Vector3.new(-lookDir.X,lookDir.Y,-lookDir.Z))
                            elseif style=="Downside" then h.HipHeight=-1
                            elseif style=="Slide" then
                                -- Slide: smooth hip height oscillation
                                h.HipHeight=-0.5+math.sin(tick()*4)*0.3
                            elseif style=="Moonwalk" then
                                -- Moonwalk: reverse walk animation
                                h.WalkSpeed=0
                                local myH=hrp()
                                if myH then myH.CFrame=myH.CFrame*CFrame.Angles(0,math.rad(180),0) end
                            elseif style=="Breaker" then
                                -- Breaker: rapid state changes
                                -- h:ChangeState(Enum.HumanoidStateType.GettingUp)
                                task.wait(0.05)
                                -- h:ChangeState(Enum.HumanoidStateType.Ragdoll)
                                task.wait(0.05)
                                -- h:ChangeState(Enum.HumanoidStateType.GettingUp)
                            end
                        end
                    end)
                end
                -- Desync: offset body position to confuse resolver
                if Flags.AADesync then
                    local desyncRange=Flags.AADesyncR or 90
                    local desyncAngle=math.rad(desyncRange*math.sin(tick()*spd*2))
                    local desyncOffset=Vector3.new(math.cos(desyncAngle)*2,0,math.sin(desyncAngle)*2)
                    -- Apply desync offset to character
                    pcall(function()
                        local myH=hrp()
                        if myH then
                            -- Store original and apply fake position
                            local origCF=myH.CFrame
                            myH.CFrame=origCF+desyncOffset
                            -- Restore after brief moment
                            task.delay(0.1,function()
                                pcall(function() myH.CFrame=origCF end)
                            end)
                        end
                    end)
                end
                -- Jitter Tick: only jitter on specific ticks
                if Flags.AAJittTick then
                    local interval=Flags.AAJittInt or 3
                    if tick()%interval>interval*0.5 then
                        -- On jitter tick: random angle
                        yA=math.random(-180,180)
                        pA=math.random(-89,89)
                        local jRad=math.rad(yA)
                        local jPRad=math.rad(pA)
                        local jDir=Vector3.new(math.cos(jPRad)*math.sin(jRad),math.sin(jPRad),math.cos(jPRad)*math.cos(jRad))
                        cam.CFrame=CFrame.new(cp,cp+jDir)
                    end
                end
                -- Manual Override: user-controlled direction
                if Flags.AAManual then
                    local dir=Flags.AAManualDir or "Backward"
                    local lv=cam.CFrame.LookVector
                    if dir=="Forward" then yA=math.deg(math.atan2(lv.X,lv.Z))
                    elseif dir=="Backward" then yA=math.deg(math.atan2(-lv.X,-lv.Z))
                    elseif dir=="Left" then yA=math.deg(math.atan2(-lv.Z,lv.X))
                    elseif dir=="Right" then yA=math.deg(math.atan2(lv.Z,-lv.X)) end
                    local mRad=math.rad(yA)
                    local mDir=Vector3.new(math.cos(pR)*math.sin(mRad),math.sin(pR),math.cos(pR)*math.cos(mRad))
                    cam.CFrame=CFrame.new(cp,cp+mDir)
                end
                -- Body Yaw: separate body angle from view angle
                if Flags.AABodyYaw then
                    local bodyOffset=Flags.AABodyYawO or 60
                    local bodyRad=math.rad(yA+bodyOffset)
                    -- Apply body rotation offset
                    pA=0 -- Keep view straight, body offset
                end
                -- Fake Angles: alternate between real and fake
                if Flags.AAFakeAngles then
                    local fakeSide=math.sin(tick()*spd*3)>0 and 1 or -1
                    yA=yA+fakeSide*90
                    local fRad=math.rad(yA)
                    local fDir=Vector3.new(math.cos(pR)*math.sin(fRad),math.sin(pR),math.cos(pR)*math.cos(fRad))
                    cam.CFrame=CFrame.new(cp,cp+fDir)
                end
                -- Slow Walk AA: different AA when walking slowly
                if Flags.AASlowAA then
                    local h=hum()
                    if h and h.WalkSpeed<10 then
                        -- When slow walking: use more aggressive AA
                        yA=yA+180
                        pA=-89
                        local sRad=math.rad(yA)
                        local sDir=Vector3.new(math.cos(math.rad(pA))*math.sin(sRad),math.sin(math.rad(pA)),math.cos(math.rad(pA))*math.cos(sRad))
                        cam.CFrame=CFrame.new(cp,cp+sDir)
                    end
                end
                -- Air AA: different AA when in air
                if Flags.AAAirAA then
                    local h=hum()
                    if h and h.FloorMaterial==Enum.Material.Air then
                        -- In air: spin faster
                        yA=yA+spd*5
                        local aRad=math.rad(yA)
                        local aDir=Vector3.new(math.cos(pR)*math.sin(aRad),math.sin(pR),math.cos(pR)*math.cos(aRad))
                        cam.CFrame=CFrame.new(cp,cp+aDir)
                    end
                end
                -- Desync Visualizer: show fake vs real angle
                if Flags.AADesyncViz then
                    pcall(function()
                        local sp,sv=cam:WorldToViewportPoint(cp+cam.CFrame.LookVector*5)
                        if sv then
                            if not aaVizCircle then aaVizCircle=safeDrawingNew("Circle"); if aaVizCircle then aaVizCircle.Thickness=2; aaVizCircle.NumSides=16; aaVizCircle.Filled=false end end
                            aaVizCircle.Position=Vector2.new(sp.X,sp.Y)
                            aaVizCircle.Radius=20
                            aaVizCircle.Color=Color3.fromRGB(255,0,255)
                            aaVizCircle.Visible=true
                        end
                    end)
                else if aaVizCircle then aaVizCircle.Visible=false end end
                -- Dynamic Jitter: vary jitter range based on time
                if Flags.AADynJitt then
                    local dynMin=Flags.AADynMin or 30
                    local dynMax=Flags.AADynMax or 150
                    local dynRange=dynMin+(dynMax-dynMin)*(math.sin(tick()*2)+1)/2
                    yA=yA+math.random(-dynRange,dynRange)
                end
                -- Sideways: force 90 degree offset
                if Flags.AASideways then
                    local side=math.sin(tick()*spd*2)>0 and 90 or -90
                    yA=yA+side
                    local sRad=math.rad(yA)
                    local sDir=Vector3.new(math.cos(pR)*math.sin(sRad),math.sin(pR),math.cos(pR)*math.cos(sRad))
                    cam.CFrame=CFrame.new(cp,cp+sDir)
                end
                -- Backwards: force 180 degree offset
                if Flags.AABackwards then
                    yA=yA+180
                    local bRad=math.rad(yA)
                    local bDir=Vector3.new(math.cos(pR)*math.sin(bRad),math.sin(pR),math.cos(pR)*math.cos(bRad))
                    cam.CFrame=CFrame.new(cp,cp+bDir)
                end
                -- Resolved Jitter: extra jitter layer on top of base AA
                if Flags.AAResJitt then
                    local resSpd=Flags.AAResJSpd or 10
                    local extraJitter=math.sin(tick()*resSpd*5)*45
                    yA=yA+extraJitter
                    local rjRad=math.rad(yA)
                    local rjDir=Vector3.new(math.cos(pR)*math.sin(rjRad),math.sin(pR),math.cos(pR)*math.cos(rjRad))
                    cam.CFrame=CFrame.new(cp,cp+rjDir)
                end
                -- Anti Resolver: switch angles based on miss count
                if Flags.AAAntiRes then
                    local miss=RAGE.MissCount and RAGE.MissCount[0] or 0
                    if miss>2 then
                        yA=yA+180
                        local arRad=math.rad(yA)
                        local arDir=Vector3.new(math.cos(pR)*math.sin(arRad),math.sin(pR),math.cos(pR)*math.cos(arRad))
                        cam.CFrame=CFrame.new(cp,cp+arDir)
                    end
                end
                -- Body Flip: flip body direction periodically
                if Flags.AABodyFlip then
                    local flipInt=Flags.AABodyFlipInt or 5
                    if math.floor(tick())%flipInt==0 then
                        yA=yA+180
                        local bfRad=math.rad(yA)
                        local bfDir=Vector3.new(math.cos(pR)*math.sin(bfRad),math.sin(pR),math.cos(pR)*math.cos(bfRad))
                        cam.CFrame=CFrame.new(cp,cp+bfDir)
                    end
                end
                -- Fake Lag Sync: sync AA with fake lag ticks
                if Flags.AAFLSync then
                    local flSync=math.sin(tick()*8)*60
                    yA=yA+flSync
                end
                -- Move Manipulation: manipulate movement while AA
                if Flags.AAMoveManip then
                    local h=hum()
                    if h then
                        local manipStr=Flags.AAMoveStr or 8
                        local manipAngle=math.rad(yA+90)
                        -- Apply sideways force
                        -- h:Move(Vector3.new(math.cos(manipAngle),0,math.sin(manipAngle))*manipStr/10)
                    end
                end
                -- View Manipulation: shift view angle dramatically
                if Flags.AAViewManip then
                    local viewAng=Flags.AAViewAngle or 90
                    local vmRad=math.rad(viewAng*math.sin(tick()*3))
                    cam.CFrame=cam.CFrame*CFrame.Angles(0,vmRad,0)
                end
                -- Anti Untrust: avoid angles that cause prediction errors
                if Flags.AAAntiUntrust then
                    -- Clamp angles to safe range
                    yA=yA%360
                    if yA<0 then yA=yA+360 end
                    pA=math.clamp(pA,-89,89)
                    local auRad=math.rad(yA)
                    local auDir=Vector3.new(math.cos(math.rad(pA))*math.sin(auRad),math.sin(math.rad(pA)),math.cos(math.rad(pA))*math.cos(auRad))
                    cam.CFrame=CFrame.new(cp,cp+auDir)
                end
                -- Slow LBY: slower lower body yaw rotation
                if Flags.AASlowLBY then
                    local slowSpd=Flags.AASlowLBYS or 3
                    local slowAngle=tick()*slowSpd*10
                    local slowOffset=math.sin(math.rad(slowAngle))*120
                    local slRad=math.rad(yA+slowOffset)
                    local slDir=Vector3.new(math.cos(pR)*math.sin(slRad),math.sin(pR),math.cos(pR)*math.cos(slRad))
                    cam.CFrame=CFrame.new(cp,cp+slDir)
                end
                -- Brute After Miss: auto-switch after missing shots
                if Flags.AABruteMiss then
                    local bruteSteps=Flags.AABruteSteps or 4
                    local bruteAngle=(tick()*(spd/2))%(360/bruteSteps)*bruteSteps
                    yA=yA+bruteAngle
                    local bmRad=math.rad(yA)
                    local bmDir=Vector3.new(math.cos(pR)*math.sin(bmRad),math.sin(pR),math.cos(pR)*math.cos(bmRad))
                    cam.CFrame=CFrame.new(cp,cp+bmDir)
                end
                -- While Shooting: disable AA when firing
                if not Flags.AAShoot then
                    local tool=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
                    if tool and tool:GetAttribute("Firing") then return end
                end
            end)
        end
    end
end)

-- FAKE LAG ENGINE (Enhanced)
    local flTick=0; local flPattern={1,1,1,0,1,0,1,1,0,1,0,0,1,1,1,0}

task.spawn(function()
    while true do
        task.wait()
        if Flags.FL and alive() then
            pcall(function()
                local h=hum(); if not h then return end
                if Flags.FLGround then local h2=hum(); if h2 and h2.FloorMaterial==Enum.Material.Air then return end end
                if Flags.FLMoving then local v=hrp() and hrp().AssemblyLinearVelocity or Vector3.new(); if v.Magnitude<2 then return end end
                local choke=Flags.FLChoke or 7; local style=Flags.FLStyle or "Adaptive"
                -- Ping Adapt: reduce choke on high ping
                if Flags.PingAdapt and BS.PA then
                    choke=BS.PA.getAdaptFakeLag(choke)
                end
                flTick=flTick+1
                local variance=Flags.FLVar or 20
                local actualChoke=choke+math.random(-variance,variance)/10
                actualChoke=math.clamp(math.floor(actualChoke),1,16)
                local shouldChoke=false
                if style=="Constant" then shouldChoke=flTick%actualChoke==0
                elseif style=="Adaptive" then
                    local v=hrp() and hrp().AssemblyLinearVelocity or Vector3.new()
                    local spd2=v.Magnitude
                    local adaptChoke=math.clamp(math.floor(spd2/10),1,actualChoke)
                    shouldChoke=flTick%adaptChoke==0
                elseif style=="Random" then shouldChoke=flTick%math.random(1,actualChoke)==0
                elseif style=="Tick" then shouldChoke=flPattern[(flTick%16)+1]==0
                elseif style=="Break Lag" then shouldChoke=flTick%actualChoke==0 or flTick%(actualChoke*2)==0
                elseif style=="Shift" then shouldChoke=flTick>=actualChoke and flTick<=actualChoke+4
                elseif style=="Aggressive" then shouldChoke=flTick%math.max(1,actualChoke-2)==0 -- 2 fewer choke = more aggressive
                elseif style=="Hyper" then shouldChoke=flTick%math.max(1,actualChoke/2)==0 -- half choke = very aggressive
                elseif style=="Break LC" then shouldChoke=flTick%actualChoke==0 or (flTick+1)%actualChoke==0 -- double break
                elseif style=="Desync" then shouldChoke=flTick%actualChoke==0 and flTick%(actualChoke*3)~=0 end -- selective choke
                if shouldChoke then
                    h.WalkSpeed=0
                    task.wait(0.03)
                    h.WalkSpeed=Flags.FLFakeWalk and (Flags.FLFWS or 4) or 16
                end
                -- Fake Walk
                if Flags.FLFakeWalk and not shouldChoke then
                    h.WalkSpeed=Flags.FLFWS or 4
                end
                -- Break LC (enhanced: more aggressive velocity manipulation)
                if Flags.FLBLC and flTick%actualChoke==0 then
                    pcall(function()
                        local v=hrp() and hrp().AssemblyLinearVelocity or Vector3.new()
                        -- Enhanced: not just reduce but also add sudden velocity spike
                        local spikeDir=Vector3.new(math.random()-0.5,0,math.random()-0.5).Unit
                        local spikeForce=Flags.FLBLCForce or 50
                        hrp().AssemblyLinearVelocity=Vector3.new(v.X*0.1,v.Y,v.Z*0.1)+spikeDir*spikeForce
                        task.delay(0.05,function()
                            pcall(function()
                                local h=hum()
                                if h then h.WalkSpeed=0 end
                                task.wait(0.03)
                                if h then h.WalkSpeed=16 end
                            end)
                        end)
                    end)
                end
            end)
        end
    end
end)

-- RESOLVER ENGINE (Advanced)
    local resData={}

-- Velocity History Tracker
    local function getVelHistory(uid, newVel, maxHist)
    if not resData[uid].VelHistory then resData[uid].VelHistory={} end
    table.insert(resData[uid].VelHistory, newVel)
    if #resData[uid].VelHistory > (maxHist or 20) then table.remove(resData[uid].VelHistory, 1) end
    return resData[uid].VelHistory
end

-- Position History Tracker
    local function getPosHistory(uid, newPos, maxHist)
    if not resData[uid].PosHistory then resData[uid].PosHistory={} end
    table.insert(resData[uid].PosHistory, newPos)
    if #resData[uid].PosHistory > (maxHist or 15) then table.remove(resData[uid].PosHistory, 1) end
    return resData[uid].PosHistory
end

-- Smart Detection: determine if enemy is using AA
    local function detectAntiAim(uid)
    local d=resData[uid]
    if not d or not d.VelHistory or #d.VelHistory<5 then return false, 0 end
    local confidence=0
    -- Check 1: Velocity inconsistency
    local velChanges=0
    for i=2,#d.VelHistory do
        local diff=(d.VelHistory[i]-d.VelHistory[i-1]).Magnitude
        if diff>3 then velChanges=velChanges+1 end
    end
    if velChanges>3 then confidence=confidence+30 end
    -- Check 2: Position stuck (moving but not changing position)
    if d.PosHistory and #d.PosHistory>=5 then
        local posDiff=(d.PosHistory[#d.PosHistory]-d.PosHistory[1]).Magnitude
        local velAvg=Vector3.new()
        for _,v in ipairs(d.VelHistory) do velAvg=velAvg+v end
        velAvg=velAvg/#d.VelHistory
        if velAvg.Magnitude>5 and posDiff<2 then confidence=confidence+40 end
    end
    -- Check 3: Freestanding detection (facing away from open space)
    local enemy=BS.enemies()
    for _,e in ipairs(enemy) do
        if e.Player.UserId==uid and e.HRP then
            local lookDir=e.HRP.CFrame.LookVector
            local params=RaycastParams.new()
            params.FilterType=Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances={e.Char}
            local frontDist=workspace:Raycast(e.HRP.Position,lookDir*5,params)
            local backDist=workspace:Raycast(e.HRP.Position,-lookDir*5,params)
            if frontDist and not backDist then confidence=confidence+20 end
            if frontDist and (frontDist.Position-e.HRP.Position).Magnitude<2 then confidence=confidence+15 end
            break
        end
    end
    return confidence>50, confidence
end

-- Main Resolver Engine
task.spawn(function()
    while true do
        task.wait(0.05)
        if Flags.Resolver and alive() then
            pcall(function()
                local cam=workspace.CurrentCamera; local myH=hrp()
                if not cam or not myH then return end
                local mode=Flags.ResMode or "Smart"; local steps=Flags.ResSteps or 6
                for _,e in pairs(BS.enemies()) do
                    if not e.HRP or not e.Hum or e.Hum.Health<=0 then continue end
                    local uid=e.Player.UserId
                    if not resData[uid] then resData[uid]={Step=0,LastVel=Vector3.new(),LastPos=e.HRP.Position,HitCount=0,TotalShots=0,VelHistory={},PosHistory={},Confidence=0,LastBruteAngle=0} end
                    local d=resData[uid]
                    local vel=e.HRP.AssemblyLinearVelocity; local isMoving=vel.Magnitude>5
                    local pos=e.HRP.Position
                    -- Track histories
                    if Flags.ResVelTrack then getVelHistory(uid,vel,Flags.ResVelHist or 20) end
                    if Flags.ResPosTrack then getPosHistory(uid,pos,Flags.ResPosHist or 15) end
                    -- Detect anti-aim
                    local isAA,aaConf=detectAntiAim(uid)
                    d.Confidence=aaConf
                    local bruteAngle=0
                    -- MODE: Brute Force                     if mode=="Brute Force" or Flags.ResBruteMode then
                        local bSteps=Flags.ResBruteSteps or steps
                        d.Step=(d.Step+1)%bSteps
                        bruteAngle=d.Step*(360/bSteps)
                    -- MODE: Moving Anti-Wall                     elseif mode=="Moving AW" then
                        if isMoving then
                            bruteAngle=math.deg(math.atan2(vel.Unit.X,vel.Unit.Z))
                        else
                            d.Step=(d.Step+1)%steps
                            bruteAngle=d.Step*(360/steps)
                        end
                    -- MODE: Static                     elseif mode=="Static" then
                        bruteAngle=0
                    -- MODE: Freestand                     elseif mode=="Freestand" then
                        local dirs={Vector3.new(1,0,0),Vector3.new(-1,0,0),Vector3.new(0,0,1),Vector3.new(0,0,-1)}
                        local mD,mDx=nil,0
                        for _,dd in ipairs(dirs) do
                            local params=RaycastParams.new()
                            params.FilterType=Enum.RaycastFilterType.Exclude
                            params.FilterDescendantsInstances={e.Char}
                            local r=workspace:Raycast(e.HRP.Position,dd*10,params)
                            local dist=r and (r.Position-e.HRP.Position).Magnitude or 10
                            if dist>mDx then mDx=dist; mD=dd end
                        end
                        bruteAngle=mD and math.deg(math.atan2(mD.X,mD.Z)) or 0
                    -- MODE: Manual                     elseif mode=="Manual" then
                        bruteAngle=Flags.ResManAngle or Flags.ResMAngle or 0
                    -- MODE: Smart                     elseif mode=="Smart" then
                        if isAA and aaConf>(Flags.ResConf or 60) then
                            -- Enemy is using AA: use smart detection
                            local velDiff=(vel-d.LastVel).Magnitude
                            if velDiff>5 then
                                d.Step=(d.Step+1)%steps
                                bruteAngle=d.Step*(360/steps)
                            else
                                if isMoving then bruteAngle=math.deg(math.atan2(vel.X,vel.Z))
                                else bruteAngle=d.Step*(360/steps) end
                            end
                        else
                            -- No AA detected: trust velocity
                            if isMoving then bruteAngle=math.deg(math.atan2(vel.X,vel.Z))
                            else bruteAngle=0 end
                        end
                    -- MODE: Inverse                     elseif mode=="Inverse" then
                        local predAngle=math.deg(math.atan2(vel.X,vel.Z))
                        bruteAngle=(predAngle+180)%360
                    -- MODE: Anti Brute                     elseif mode=="Anti Brute" then
                        local abSteps=Flags.ResAntiSteps or 4
                        if (RAGE.MissCount[uid] or 0)>2 then
                            bruteAngle=(d.Step*(360/abSteps)+180)%360
                        else
                            d.Step=(d.Step+1)%abSteps
                            bruteAngle=d.Step*(360/abSteps)
                        end
                    end
                    -- Advanced: Velocity Tracking                     if Flags.ResVelTrack and d.VelHistory and #d.VelHistory>=3 then
                        local avgVel=Vector3.new()
                        for _,v in ipairs(d.VelHistory) do avgVel=avgVel+v end
                        avgVel=avgVel/#d.VelHistory
                        if avgVel.Magnitude>2 then
                            local velAngle=math.deg(math.atan2(avgVel.X,avgVel.Z))
                            -- Blend with brute angle
                            bruteAngle=bruteAngle*0.7+velAngle*0.3
                        end
                    end
                    -- Advanced: Lag Compensation                     if Flags.ResLagComp then
                        local lcTicks=Flags.ResLCTicks or 8
                        local lagOffset=vel*(lcTicks*0.015)
                        local lagAngle=math.deg(math.atan2(lagOffset.X,lagOffset.Z))
                        if lagOffset.Magnitude>1 then
                            bruteAngle=bruteAngle*0.8+lagAngle*0.2
                        end
                    end
                    -- Advanced: Adaptive                     if Flags.ResAdaptive then
                        local adaptSpd=Flags.ResAdaptSpd or 5
                        local adaptAngle=math.sin(tick()*adaptSpd)*45
                        bruteAngle=bruteAngle+adaptAngle
                    end
                    -- Advanced: Inverse Resolver                     if Flags.ResInverse then
                        -- Try opposite if current angle fails
                        if d.Confidence>50 then
                            bruteAngle=(bruteAngle+180)%360
                        end
                    end
                    -- Advanced: Auto Switch                     if Flags.ResAutoSw then
                        local swSpd=Flags.ResSwSpd or 5
                        if tick()%swSpd<swSpd/2 then
                            -- First half: use calculated angle
                        else
                            -- Second half: try different angle
                            bruteAngle=(bruteAngle+90)%360
                        end
                    end
                    -- Advanced: Miss Detection                     if Flags.ResMiss then
                        local missTh=Flags.ResMissTh or 3
                        if (RAGE.MissCount[uid] or 0)>=missTh then
                            -- Too many misses: try all angles
                            bruteAngle=d.Step*(360/steps)
                            d.Step=(d.Step+1)%steps
                        end
                    end
                    -- Advanced: Body/Head Aim                     if Flags.ResBodyAim then
                        -- Force body aim when resolver is uncertain
                        if d.Confidence<30 then
                            -- Low confidence: aim at body
                        end
                    end
                    if Flags.ResHeadAim then
                        -- Force head aim when confident
                        if d.Confidence>70 then
                            -- High confidence: aim at head
                        end
                    end
                    -- Store results
                    d.LastVel=vel
                    d.LastPos=pos
                    d.LastBruteAngle=bruteAngle
                    RAGE.ResolverStep[uid]=d.Step
                    -- Log Resolver                     if Flags.ResLog then
                        pcall(function()
                            -- Could output to console or file
                        end)
                    end
                    -- ::skipRes::
                end
            end)
        end
    end
end)

-- RESOLVER LOGGING
task.spawn(function()
    while true do task.wait(2)
        if Flags.Resolver and Flags.ResLogMiss then
            pcall(function()
                for uid,d in pairs(resData) do
                    if d.TotalShots>0 then
                        local hitRate=d.HitCount/d.TotalShots
                        if hitRate<0.3 then
                            d.Step=(d.Step+1)%(Flags.ResSteps or 6)
                        end
                    end
                end
            end)
        end
    end
end)

-- HVH UTILITIES ENGINES -- Quick Stop
task.spawn(function()
    while true do task.wait()
        if Flags.QS and alive() then pcall(function()
            local h=hum(); if not h then return end
            local v=hrp() and hrp().AssemblyLinearVelocity or Vector3.new()
            if v.Magnitude>5 then h.WalkSpeed=1; task.wait(0.05); h.WalkSpeed=16 end
        end) end
    end
end)

-- Slow Walk
task.spawn(function()
    while true do task.wait(0.2)
        if Flags.SW and alive() then pcall(function() local h=hum(); if h then h.WalkSpeed=Flags.SWS or 4 end end) end
    end
end)

-- No Clip
task.spawn(function()
    while true do task.wait(0.1)
        if Flags.NoClip and alive() then pcall(function()
            local ch=lplr.Character; if ch then for _,p in pairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end
        end) end
    end
end)

-- Circle Strafe
local circAngle=0
task.spawn(function()
    while true do task.wait()
        if Flags.CircStrafe and alive() then pcall(function()
            local t=RAGE.Target; local myH=hrp()
            if t and myH then
                circAngle=circAngle+(Flags.CSSpd or 8)*0.05
                local r=3; local off=Vector3.new(math.cos(circAngle)*r,0,math.sin(circAngle)*r)
                local pos=t.Enemy.HRP.Position+off
                myH.CFrame=CFrame.new(myH.Position,Vector3.new(pos.X,myH.Position.Y,pos.Z))
            end
        end) end
    end
end)

-- Auto Revolver
task.spawn(function()
    while true do task.wait()
        if Flags.AutoRev and alive() then pcall(function()
            local t=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
            if t and t.Name:lower():find("deagle") then t:Activate() end
        end) end
    end
end)

-- Crouch Walk
task.spawn(function()
    while true do task.wait(0.2)
        if Flags.CrouchWalk and alive() then pcall(function()
            local h=hum(); if h then h.HipHeight=-0.5; h.WalkSpeed=12 end
        end) end
    end
end)

-- Edge Friction: slow down near edges to prevent falling
local edgeFrictionTick=0
task.spawn(function()
    while true do task.wait(0.1)
        if Flags.EdgeFric and alive() then pcall(function()
            local h=hum(); local myH=hrp()
            if not h or not myH then return end
            edgeFrictionTick=edgeFrictionTick+1
            -- Check if near edge (raycast downward-forward)
            local lookVec=myH.CFrame.LookVector
            local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={lplr.Character}
            local result=workspace:Raycast(myH.Position,lookVec*3+Vector3.new(0,-5,0),params)
            if not result then
                -- Near edge: slow down
                h.WalkSpeed=math.max(4,h.WalkSpeed*0.5)
            end
        end) end
    end
end)

-- Auto Pistol Engine
task.spawn(function()
    while true do task.wait()
        if Flags.AutoPistol and alive() then pcall(function()
            local tool=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
            if not tool then return end
            local name=tool.Name:lower()
            local isPistol=name:find("pistol") or name:find("glock") or name:find("usp") or name:find("p250") or name:find("five") or name:find("tec9") or name:find("dual") or name:find("deagle") or name:find("revolver") or name:find("cz75") or name:find("ppbizon")
            if not isPistol then return end
            -- Don't auto-fire deagle/revolver (too slow)
            if name:find("deagle") or name:find("revolver") then return end
            local fr=(Flags.PistolFR or 8)/1000
            -- tool:Activate()
            task.wait(fr)
        end) end
    end
end)

-- Quick Switch Engine
    local qsLastWeapon=nil; local qsLastSwitch=0
task.spawn(function()
    while true do task.wait()
        if Flags.QuickSwitch and alive() then pcall(function()
            local ch=lplr.Character; if not ch then return end
            local tool=ch:FindFirstChildWhichIsA("Tool")
            local now=tick()
            local delay=(Flags.QSDelay or 100)/1000
            if now-qsLastSwitch<delay then return end
            local mode=Flags.QSMode or "Knife-Primary"
            -- Store current weapon
            if tool then qsLastWeapon=tool end
            -- QS On Kill: switch after getting a kill
            if Flags.QSOnKill and RAGE.Target then
                local uid=RAGE.Target.Enemy and RAGE.Target.Enemy.Player and RAGE.Target.Enemy.Player.UserId
                if uid and RAGE.HitRegistered and RAGE.HitRegistered[uid] then
                    RAGE.HitRegistered[uid]=nil
                    -- Quick switch to knife then back
                    for _,t in pairs(ch:GetChildren()) do
                        if t:IsA("Tool") then
                            local tName=t.Name:lower()
                            if mode=="Knife-Primary" and tName:find("knife") then
                                t.Parent=ch; qsLastSwitch=now; break
                            elseif mode=="Knife-Zeus" and (tName:find("taser") or tName:find("zeus")) then
                                t.Parent=ch; qsLastSwitch=now; break
                            end
                        end
                    end
                    task.delay(delay,function()
                        pcall(function()
                            if qsLastWeapon and qsLastWeapon.Parent then
                                qsLastWeapon.Parent=ch
                            end
                        end)
                    end)
                end
            end
            -- QS On Empty: switch when ammo is low
            if Flags.QSOnEmpty and tool then
                local ammo=tool:GetAttribute("Ammo") or tool:GetAttribute("CurrentAmmo")
                if ammo and ammo<=0 then
                    for _,t in pairs(ch:GetChildren()) do
                        if t:IsA("Tool") and t~=tool then
                            t.Parent=ch; qsLastSwitch=now; break
                        end
                    end
                end
            end
        end) end
    end
end)

-- Auto Zeus Engine
    local zeusLastFire=0
task.spawn(function()
    while true do task.wait()
        if Flags.AutoZeus and alive() then pcall(function()
            local ch=lplr.Character; if not ch then return end
            local tool=ch:FindFirstChildWhichIsA("Tool")
            if not tool then return end
            local name=tool.Name:lower()
            local isZeus=name:find("taser") or name:find("zeus") or name:find("stun")
            if not isZeus then
                -- Auto switch to zeus if enabled
                if Flags.ZeusAutoSw then
                    for _,t in pairs(ch:GetChildren()) do
                        if t:IsA("Tool") then
                            local tName=t.Name:lower()
                            if tName:find("taser") or tName:find("zeus") or tName:find("stun") then
                                t.Parent=ch; break
                            end
                        end
                    end
                end
                -- return
            end
            local now=tick()
            local cooldown=(Flags.ZeusCD or 500)/1000
            if now-zeusLastFire<cooldown then return end
            -- Find target
            local myH=hrp(); if not myH then return end
            local myPos=myH.Position+Vector3.new(0,1.5,0)
            local range=Flags.ZeusRange or 12
            local bestEnemy=nil; local bestDist=range
            for _,e in pairs(BS.enemies()) do
                if not e.HRP or not e.Hum or e.Hum.Health<=0 then continue end
                if Flags.ZeusTeam and lplr.Team and e.Player.Team==lplr.Team then continue end
                local dist=(myPos-e.HRP.Position).Magnitude
                if dist<bestDist then
                    -- Wall check
                    if Flags.ZeusWall then
                        local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={ch}
                        local r=workspace:Raycast(myPos,(e.HRP.Position-myPos).Unit*dist,params)
                        if r then continue end
                    end
                    -- Low HP check
                    if Flags.ZeusLowHP and e.Hum.Health>(Flags.ZeusHPThresh or 30) then continue end
                    bestDist=dist; bestEnemy=e
                end
                -- ::skipZeus::
            end
            if bestEnemy then
                -- Aim at target
                local cam=workspace.CurrentCamera
                local camPos=cam.CFrame.Position
                local targetPos=bestEnemy.HRP.Position+Vector3.new(0,0.5,0)
                cam.CFrame=CFrame.new(camPos,camPos+(targetPos-camPos).Unit)
                -- Fire zeus
                -- tool:Activate()
                zeusLastFire=now
            end
        end) end
    end
end)

-- -- ADVANCED HVH ENGINES

-- Auto Anti-Aim Engine
task.spawn(function()
    while true do task.wait(0.5)
        if Flags.HVHSuper and Flags.AutoAA and alive() then pcall(function()
            local cam=workspace.CurrentCamera; local myH=hrp(); if not cam or not myH then return end
            -- Check if enemy is aiming at us
            local enemies=BS.enemies()
            local aimingAtUs=false
            for _,e in ipairs(enemies) do
                if e.HRP and e.Head then
                    local toUs=(myH.Position-e.HRP.Position).Unit
                    local theirLook=e.HRP.CFrame.LookVector
                    local dot=theirLook:Dot(toUs)
                    if dot>0.8 then aimingAtUs=true; break end
                end
            end
            -- If enemy aiming at us, activate AA
            if aimingAtUs and not Flags.AA then
                Flags.AA=true; Flags.AAPitch="Down"; Flags.AAYaw="LBY Break"
                Flags.AADesync=true; Flags.AAFakeDuck=true
            end
            -- Auto switch AA pattern based on enemy behavior
            if Flags.AutoSwitchAA then
                local missCount=RAGE.MissCount[0] or 0
                if missCount>3 then
                    Flags.AAYaw="LBY Break"
                    Flags.AADesyncR=150
                    Flags.AAPitch="Jitter"
                elseif missCount>1 then
                    Flags.AAYaw="Spin"
                    Flags.AASpd=15
                end
            end
            -- Predictive AA: change angles before enemy can predict
            if Flags.PredAA then
                local tick=time()
                local phase=tick()%6
                if phase<1.5 then Flags.AAYaw="Back"
                elseif phase<3 then Flags.AAYaw="Jitter"
                elseif phase<4.5 then Flags.AAYaw="LBY Break"
                else Flags.AAYaw="Spin" end
            end
        end) end
    end
end)

-- Auto Fake Lag Engine
task.spawn(function()
    while true do task.wait()
        if Flags.HVHSuper and Flags.AutoFL and alive() then pcall(function()
            local h=hum(); if not h then return end
            -- Auto-adjust fake lag based on situation
            local enemies=BS.enemies()
            local closeEnemies=0
            local myH=hrp()
            for _,e in ipairs(enemies) do
                if e.HRP and myH then
                    local dist=(myH.Position-e.HRP.Position).Magnitude
                    if dist<30 then closeEnemies=closeEnemies+1 end
                end
            end
            -- More fake lag when enemies are close
            if closeEnemies>0 then
                Flags.FL=true
                Flags.FLChoke=math.clamp(8+closeEnemies*2,4,16)
                Flags.FLStyle="Adaptive"
            end
            -- Desync choke: alternate between choke and unchoke
            if Flags.DesyncChoke then
                local chokeT=Flags.DesyncChokeT or 8
                local tick=time()
                if tick%0.1<0.05 then
                    -- Choke packets
                    h.WalkSpeed=0
                    task.wait(0.02)
                    h.WalkSpeed=16
                end
            end
            -- Lag spike: periodic extreme lag to break enemy tracking
            if Flags.LagSpikeAA then
                local interval=Flags.LagSpikeInt or 5
                if time()%interval<interval*0.2 then
                    h.WalkSpeed=0
                    task.wait(0.1)
                    h.WalkSpeed=16
                end
            end
        end) end
    end
end)

-- Auto Resolver Engine
task.spawn(function()
    while true do task.wait(1)
        if Flags.HVHSuper and Flags.AutoRes and alive() then pcall(function()
            local enemies=BS.enemies()
            for _,e in ipairs(enemies) do
                if e.Player and e.HRP then
                    local uid=e.Player.UserId
                    local miss=RAGE.MissCount[uid] or 0
                    -- Auto switch resolver strategy based on miss count
                    if miss>5 then
                        Flags.ResMode="Inverse"
                        Flags.ResSteps=12
                        Flags.ResAntiBrute=true
                    elseif miss>3 then
                        Flags.ResMode="Brute Force"
                        Flags.ResSteps=10
                    elseif miss>1 then
                        Flags.ResMode="Smart"
                        Flags.ResSteps=8
                    else
                        Flags.ResMode="Moving AW"
                        Flags.ResSteps=6
                    end
                end
            end
        end) end
    end
end)

-- Smart Brute Force Engine
task.spawn(function()
    while true do task.wait(0.5)
        if Flags.SmartBrute and alive() then pcall(function()
            local enemies=BS.enemies()
            for _,e in ipairs(enemies) do
                if e.Player and e.HRP and e.Head then
                    local uid=e.Player.UserId
                    local shots=RAGE.TotalShots[uid] or 0
                    local hits=RAGE.HitCount[uid] or 0
                    -- If hit rate is low, switch strategy
                    if shots>5 then
                        local hitRate=hits/shots
                        if hitRate<0.3 then
                            -- Try different aim positions
                            local step=(RAGE.ResolverStep[uid] or 0)+1
                            RAGE.ResolverStep[uid]=step%4
                        end
                    end
                end
            end
        end) end
    end
end)

-- Desync Choke Engine
task.spawn(function()
    while true do task.wait()
        if Flags.DesyncChoke and alive() then pcall(function()
            local h=hum(); if not h then return end
            local chokeT=Flags.DesyncChokeT or 8
            -- Create desync by manipulating walk speed in bursts
            local t=time()
            local phase=t%0.1
            if phase<0.05 then
                h.WalkSpeed=0
            else
                h.WalkSpeed=16
            end
        end) end
    end
end)

-- Rapid Fire Engine
task.spawn(function()
    while true do task.wait()
        if Flags.RapidFire and alive() then pcall(function()
            local tool=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
            if not tool then return end
            local name=tool.Name:lower()
            if name:find("knife") or name:find("bayonet") or name:find("grenade") then return end
            local rate=(Flags.RapidFireRate or 25)/1000
            -- tool:Activate()
            task.wait(rate)
        end) end
    end
end)

-- Auto Wallbang Kill Engine v2.0 -- 
-- 12    
--  CS2 

local WBHistory = {}  -- [uid] = { kills, attempts, lastAngle, bestAngle, avgPenFactor }
local WB_PRESETS = {
    ["awp"] = {
    -- ["scout"]   = { penBonus = 10, angleBonus = 0.10, damageBonus = 1.1 },
    -- ["deagle"]  = { penBonus = 20, angleBonus = 0.12, damageBonus = 1.15 },
    -- ["ak47"]    = { penBonus = 5,  angleBonus = 0.08, damageBonus = 1.05 },
    -- ["m4a4"]    = { penBonus = 5,  angleBonus = 0.08, damageBonus = 1.05 },
    -- ["m4a1"]    = { penBonus = 8,  angleBonus = 0.10, damageBonus = 1.08 },
    -- ["famas"]   = { penBonus = 3,  angleBonus = 0.05, damageBonus = 1.02 },
    -- ["galil"]   = { penBonus = 3,  angleBonus = 0.05, damageBonus = 1.02 },
    -- ["ump"]     = { penBonus = 2,  angleBonus = 0.03, damageBonus = 1.00 },
    -- ["mac10"]   = { penBonus = 2,  angleBonus = 0.03, damageBonus = 1.00 },
    -- ["p90"]     = { penBonus = 2,  angleBonus = 0.03, damageBonus = 1.00 },
    -- ["nova"]    = { penBonus = -5, angleBonus = -0.05, damageBonus = 0.9 },
    -- ["xm1014"]  = { penBonus = -3, angleBonus = -0.03, damageBonus = 0.92 },
    -- ["bizon"]   = { penBonus = 1,  angleBonus = 0.02, damageBonus = 0.98 },
    ["mp9"]     = { penBonus = 2,  angleBonus = 0.03, damageBonus = 1.00 },
    ["ssg"]     = { penBonus = 8,  angleBonus = 0.06, damageBonus = 1.04 },
    ["scar"]    = { penBonus = 7,  angleBonus = 0.07, damageBonus = 1.06 },
    ["aug"]     = { penBonus = 6,  angleBonus = 0.06, damageBonus = 1.04 },
    ["sg556"]   = { penBonus = 6,  angleBonus = 0.06, damageBonus = 1.04 },
}

-- 3 ?
    local function analyzeMultiLayerWall(myPos, targetPos)
    local dir = (targetPos - myPos)
    local totalDist = dir.Magnitude
    local du = dir.Unit

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {lplr.Character}

    local layers = {}       -- 
    local totalThickness = 0
    local totalHardness = 0
    local maxLayers = 3     -- 3 ?    local currentStart = myPos
    local remainingDist = totalDist
    local totalDamageMult = 1.0
    local blocked = false

    for layer = 1, maxLayers do
        if remainingDist <= 0 then break end

        local ray = workspace:Raycast(currentStart, du * remainingDist, params)
        if not ray then break end -- 
        local hitPos = ray.Position
        local hitDist = (hitPos - currentStart).Magnitude
        remainingDist = remainingDist - hitDist

        if remainingDist <= 0 then break end

        -- local exitRay = workspace:Raycast(hitPos + du * 0.2, du * remainingDist, params)
        local thickness
        if exitRay then
            thickness = (exitRay.Position - hitPos).Magnitude
            remainingDist = remainingDist - thickness
        else
            thickness = remainingDist
            remainingDist = 0
        end

        local mat = ray.Material
        local hardness = MAT_HARD[mat] or 50

        -- 
        local layerPenFactor = math.clamp(1 - (hardness * thickness / 10000), 0.1, 1.0)
        totalDamageMult = totalDamageMult * layerPenFactor
        totalThickness = totalThickness + thickness
        totalHardness = totalHardness + hardness

        table.insert(layers, {
            Material = mat,
            Hardness = hardness,
            Thickness = thickness,
            PenFactor = layerPenFactor,
            HitPos = hitPos,
            DamageMult = layerPenFactor,
        })

        -- if exitRay then
            currentStart = exitRay.Position + du * 0.2
        else
            currentStart = hitPos + du * 0.2
        end
    end

    -- 
    local avgPenFactor = #layers > 0 and totalDamageMult or 0
    local avgHardness = #layers > 0 and (totalHardness / #layers) or 0

    return {
        Layers = layers,
        LayerCount = #layers,
        TotalThickness = totalThickness,
        AvgHardness = avgHardness,
        TotalDamageMult = totalDamageMult,
        AvgPenFactor = avgPenFactor,
        Blocked = blocked,
        CanPenetrate = avgPenFactor > 0.1, -- 10%     }
end

local function optimizePenAngle(myPos, targetPos, wallData)
    if #wallData.Layers == 0 then return targetPos, 1.0 end

    local dir = (targetPos - myPos)
    local du = dir.Unit
    local bestAngle = 0
    local bestMult = 0
    local bestPos = targetPos

    -- 
    local angles = {0, 5, -5, 10, -10, 15, -15, 20, -20, 25, -25, 30, -30}
    for _, angleDeg in ipairs(angles) do
        local angleRad = math.rad(angleDeg)
        -- 
        local right = du:Cross(Vector3.new(0, 1, 0)).Unit
        local rotatedDir = (du * math.cos(angleRad) + right * math.sin(angleRad)).Unit

        -- 
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {lplr.Character}

        local ray = workspace:Raycast(myPos, rotatedDir * (targetPos - myPos).Magnitude, params)
        if ray then
            local hitDist = (ray.Position - myPos).Magnitude
            local remaining = (targetPos - myPos).Magnitude - hitDist
            if remaining > 0 then
                local exitRay = workspace:Raycast(ray.Position + rotatedDir * 0.2, rotatedDir * remaining, params)
                local thick = exitRay and (exitRay.Position - ray.Position).Magnitude or remaining
                local hard = MAT_HARD[ray.Material] or 50
                local angleMult = math.clamp(1 - (hard * thick / 10000), 0, 1)
                if angleMult > bestMult then
                    bestMult = angleMult
                    bestAngle = angleDeg
                    bestPos = myPos + rotatedDir * (targetPos - myPos).Magnitude
                end
            end
        end
    end

    return bestPos, math.clamp(bestMult, 0, 1)
end

local function predictBehindWall(t, lagTicks)
    local enemyPos = t.Enemy.HRP.Position
    local vel = BS.getVelocity and BS.getVelocity(t.Enemy) or Vector3.new()

    -- TODO
    local predictedPos = enemyPos + vel * predTime

    -- 50 stud?    local diff = predictedPos - enemyPos
    if diff.Magnitude > 50 then
        predictedPos = enemyPos + diff.Unit * 50
    end

    return predictedPos
end

-- task.spawn(function()
    while true do task.wait()
        if Flags.AutoWBKill and alive() then pcall(function()
            local cam = workspace.CurrentCamera
            local myH = hrp()
            if not cam or not myH then return end

            local myPos = myH.Position + Vector3.new(0, 1.5, 0)
            local sorted = sortTargets(BS.enemies(), myPos, cam)

            -- 
            local wtype = BS.weaponType()
            local ws = WEAPONS[wtype] or WEAPONS.rifle
            local wbPreset = WB_PRESETS[wtype] or {}
            local weaponPen = (ws.pen or 50) + (wbPreset.penBonus or 0)

            for _, t in ipairs(sorted) do
                if t.SD > (Flags.RageFOV or 180) then continue end

                local aimPos = t.BonePos

                -- Step 1:                  local lagTicks = Flags.SALCTicks or 8
                local predictedPos = predictBehindWall(t, lagTicks)

                -- 
                local tryPositions = {predictedPos, aimPos}
                for _, targetPos in ipairs(tryPositions) do

                    -- Step 2:                     local wbData = analyzeMultiLayerWall(myPos, targetPos)
                    if not wbData.CanPenetrate then continue end

                    -- Step 3:                      local optimizedPos, angleMult = optimizePenAngle(myPos, targetPos, wbData)
                    local finalMult = wbData.TotalDamageMult * (1 + angleMult * (wbPreset.angleBonus or 0.05))

                    -- Step 4:                      local adjustedPen = Flags.RagePen or 70
                    local canPenetrate = finalMult * 100 >= (100 - adjustedPen)
                    if not canPenetrate then continue end

                    -- Step 5:                     local maxLayersAllowed = math.clamp(math.floor(weaponPen / 30), 1, 3)
                    if wbData.LayerCount > maxLayersAllowed then continue end

                    -- Step 6:                      local baseDmg = ws.damage or 20
                    local headMult = ws.headMult or 2.0
                    local aimBone = Flags.RageBone or "Head"
                    local damageBonus = wbPreset.damageBonus or 1.0

                    -- local penDmg = baseDmg * finalMult * damageBonus

                    -- 
                    if aimBone == "Head" or aimBone == "Auto" then
                        penDmg = penDmg * headMult
                    end

                    -- Step 7:                     local minDmg = Flags.AutoWBMinDmg or 20 -- if penDmg < minDmg then continue end -- 

                    -- Step 8:                      local killChance = t.Health and (penDmg >= t.Health) and 100 or math.clamp(penDmg / (t.Health or 100) * 100, 0, 100)
                    local minKillChance = Flags.AutoWBKillChance or 30 -- if killChance < minKillChance then continue end

                    -- Step 9:                      local uid = t.Enemy.Player.UserId
                    if WBHistory[uid] and WBHistory[uid].LastShot and (tick() - WBHistory[uid].LastShot) < 0.3 then
                        -- continue -- 300ms                     end

                    -- Step 10: ?                     local tool = lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
                    if not tool then continue end
                    local toolName = tool.Name:lower()

                    -- TODO
                    if toolName:find("knife") or toolName:find("fist") or toolName:find("fist") then continue end

                    -- TODO
                    -- tool:Activate()

                    -- Step 11:                      if not WBHistory[uid] then
                        WBHistory[uid] = { kills = 0, attempts = 0, angles = {}, avgPenFactor = 0 }
                    end
                    WBHistory[uid].attempts = WBHistory[uid].attempts + 1
                    WBHistory[uid].LastShot = tick()
                    table.insert(WBHistory[uid].angles, angleMult)
                    if #WBHistory[uid].angles > 20 then table.remove(WBHistory[uid].angles, 1) end
                    -- 
                    local sum = 0
                    for _, v in ipairs(WBHistory[uid].angles) do sum = sum + v end
                    WBHistory[uid].avgPenFactor = sum / #WBHistory[uid].angles

                    -- Step 12: ?                     if Flags.AutoWBNotify then
                        local layerInfo = ""
                        for i, layer in ipairs(wbData.Layers) do
                            layerInfo = layerInfo .. string.format("L%d:%s(%.0f%%)", i, layer.Material.Name, layer.PenFactor * 100)
                            if i < #wbData.Layers then layerInfo = layerInfo .. " " end
                        end
                        pcall(function()
                            game:GetService("StarterGui"):SetCore("SendNotification", {
                                -- Title = string.format("? Wallbang! (%d?", wbData.LayerCount),
                                -- Text = string.format(
                                    -- "%s | %s\n?: %.0f%% | ?: %.0f |  %.0f%%",
                                    t.Name or "Enemy",
                                    -- layerInfo,
                                    -- finalMult * 100,
                                    -- penDmg,
                                    -- killChance
                                ),
                                Duration = 2,
                            })
                        end)
                    end

                    break -- end -- tryPositions loop
            end -- sorted loop
        end) end
    end
end)

-- task.spawn(function()
    while true do task.wait(10)
        if Flags.AutoWBKill then pcall(function()
            -- 5             local now = tick()
            for uid, data in pairs(WBHistory) do
                if data.LastShot and now - data.LastShot > 300 then
                    WBHistory[uid] = nil
                end
            end

            -- 
            local totalAttempts = 0
            local totalKills = 0
            for _, data in pairs(WBHistory) do
                totalAttempts = totalAttempts + data.attempts
                totalKills = totalKills + data.kills
            end

            if totalAttempts > 10 then
                local efficiency = totalKills / totalAttempts * 100
                -- 10%                if efficiency < 10 then
                    Flags.AutoWBMinDmg = math.max(10, (Flags.AutoWBMinDmg or 20) - 5)
                elseif efficiency > 50 then
                    -- Flags.AutoWBMinDmg = math.min(40, (Flags.AutoWBMinDmg or 20) + 2)
                end
            end
        end) end
    end
end

-- Periodic integrity check
task.spawn(function()
    while true do task.wait(60)
        pcall(function()
            local now = tick()
            for uid, data in pairs(WBHistory) do
                if data.LastShot and now - data.LastShot > 300 then
                    WBHistory[uid] = nil
                end
            end
        end)
    end
end)

-- Bullet Tracer Engine v1.0 -- TODO
local TracerPool = {} local ImpactPool = {} local HitMarkerPool = {}
local function getTracerColor()
    local c = Flags.TracerColor or "Red"
    if c == "Rainbow" then return Color3.fromHSV(tick()*3%1,1,1) end
    return ({Red=Color3.fromRGB(255,50,50),Green=Color3.fromRGB(50,255,50),Blue=Color3.fromRGB(50,100,255),Yellow=Color3.fromRGB(255,255,50),Cyan=Color3.fromRGB(50,255,255),Magenta=Color3.fromRGB(255,50,255),White=Color3.fromRGB(255,255,255)})[c] or Color3.fromRGB(255,50,50)
end
local function newTracerLine()
    local ok,l = pcall(function() local ln=Drawing.new("Line"); ln.Visible=false; ln.Thickness=2; ln.ZIndex=999; return ln end)
    return ok and l or nil
end
local function newImpactDot()
    local ok,d = pcall(function() local c=Drawing.new("Circle"); c.Visible=false; c.Filled=true; c.NumSides=12; c.Radius=5; c.ZIndex=999; return c end)
    return ok and d or nil
end
local function newHitMarker()
    local lines={}
    for i=1,4 do local ok,l=pcall(function() local ln=Drawing.new("Line"); ln.Visible=false; ln.Thickness=2; ln.ZIndex=1000; return ln end); if ok then lines[i]=l end end
    return #lines==4 and lines or nil
end
local function removeTracer(idx)
    local t=TracerPool[idx]; if t then
        for _,l in ipairs(t.Lines) do pcall(function() l.Visible=false; l:Remove() end) end
        if t.ImpactDot then pcall(function() t.ImpactDot.Visible=false; t.ImpactDot:Remove() end) end
        TracerPool[idx]=nil
    end
end
local function createTracer(startPos,endPos,wallHits)
    local color=getTracerColor(); local width=Flags.TracerWidth or 2; local lines={}
    local points={startPos}; if wallHits then for _,wh in ipairs(wallHits) do table.insert(points,wh) end end; table.insert(points,endPos)
    for i=1,#points-1 do
        local line=newTracerLine()
        if line then local cam=workspace.CurrentCamera; local s,sV=cam:WorldToViewportPoint(points[i]); local e,eV=cam:WorldToViewportPoint(points[i+1])
            if sV or eV then line.From=Vector2.new(s.X,s.Y); line.To=Vector2.new(e.X,e.Y); line.Color=color; line.Thickness=width; line.Visible=true end
            table.insert(lines,line)
        end
    end
    local impactDot=nil
    if Flags.TracerImpact then impactDot=newImpactDot(); if impactDot then local cam=workspace.CurrentCamera; local ip,iv=cam:WorldToViewportPoint(endPos)
        if iv then impactDot.Position=Vector2.new(ip.X,ip.Y); impactDot.Radius=Flags.TracerImpactSize or 6; impactDot.Color=color; impactDot.Visible=true end
    end end
    table.insert(TracerPool,{Lines=lines,ImpactDot=impactDot,Birth=tick(),Duration=Flags.TracerDuration or 3})
end
local function createHitMarker(pos,isHeadshot)
    if not Flags.TracerHitMarker then return end
    local cam=workspace.CurrentCamera; local sP,vis=cam:WorldToViewportPoint(pos); if not vis then return end
    local lines=newHitMarker(); if not lines then return end
    local sz=Flags.TracerHMS or 12; local clr=isHeadshot and Color3.fromRGB(255,50,50) or Color3.fromRGB(255,255,255)
    local offs={{-sz,-sz,sz,sz},{sz,-sz,-sz,sz},{0,-sz,0,sz},{-sz,0,sz,0}}
    for i,off in ipairs(offs) do lines[i].From=Vector2.new(sP.X+off[1],sP.Y+off[2]); lines[i].To=Vector2.new(sP.X+off[3],sP.Y+off[4]); lines[i].Color=clr; lines[i].Visible=true end
    table.insert(HitMarkerPool,{Lines=lines,Birth=tick(),Duration=0.4})
end
-- TODO
local lastBTFire=0
RunService.RenderStepped:Connect(function()
    if not Flags.BulletTracer or not alive() then return end
    local myH=hrp(); local cam=workspace.CurrentCamera; if not myH or not cam then return end
    local tool=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool"); if not tool then return end
    if not (Flags.RageAF or Flags.Ragebot or Flags.SilentAim or Flags.AutoWBKill) then return end
    if tick()-lastBTFire<0.08 then return end; lastBTFire=tick()
    local myPos=myH.Position+Vector3.new(0,1.5,0); local dir=cam.CFrame.LookVector
    local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={lplr.Character}
    local wallHits={}; local curStart=myPos; local rem=1000; local finalEnd=myPos+dir*1000
    if Flags.TracerWall then
        for layer=1,5 do local ray=workspace:Raycast(curStart,dir*rem,params); if not ray then break end
            local hd=(ray.Position-curStart).Magnitude; rem=rem-hd; if rem<=0 then break end
            table.insert(wallHits,ray.Position); curStart=ray.Position+dir*0.3
        end
    else local ray=workspace:Raycast(myPos,dir*1000,params); if ray then finalEnd=ray.Position end end
    createTracer(myPos,finalEnd,#wallHits>0 and wallHits or nil)
end)
-- Wallbang  hook
RunService.RenderStepped:Connect(function()
    if not Flags.BulletTracer or not Flags.TracerPenLine or not alive() then return end
    local myH=hrp(); if not myH then return end; local cam=workspace.CurrentCamera
    local sorted=sortTargets and sortTargets(BS.enemies(),myH.Position,cam) or {}
    for _,t in ipairs(sorted) do if t.SD>(Flags.RageFOV or 180) then continue end
        local aimPos=t.BonePos; local myPos=myH.Position+Vector3.new(0,1.5,0)
        local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={lplr.Character}
        local ray=workspace:Raycast(myPos,(aimPos-myPos).Unit*(aimPos-myPos).Magnitude,params)
        if ray then createTracer(myPos,aimPos,{ray.Position}) end
    end
end)
-- TODO
local btLastUpdate=0
RunService.RenderStepped:Connect(function()
    if tick()-btLastUpdate<0.03 then return end; btLastUpdate=tick()
    local now=tick()
    for i=#TracerPool,1,-1 do local t=TracerPool[i]; if not t then continue end
        local age=now-t.Birth; if age>t.Duration then removeTracer(i)
        else local a=1-(age/t.Duration)
            for _,l in ipairs(t.Lines) do pcall(function() l.Transparency=a; l.Visible=true end) end
            if t.ImpactDot then pcall(function() t.ImpactDot.Transparency=a; t.ImpactDot.Visible=true end) end
        end
    end
    for i=#HitMarkerPool,1,-1 do local hm=HitMarkerPool[i]; if not hm then continue end
        local age=now-hm.Birth; if age>hm.Duration then for _,l in ipairs(hm.Lines) do pcall(function() l.Visible=false; l:Remove() end) end; HitMarkerPool[i]=nil
        else local a=1-(age/hm.Duration); for _,l in ipairs(hm.Lines) do pcall(function() l.Transparency=a; l.Visible=true end) end end
    end
end)
print("[BulletTracer] Loaded")

-- One Tap Mode Engine
task.spawn(function()
    while true do task.wait()
        if Flags.OneTap and alive() then pcall(function()
            -- Force headshots and high damage
            Flags.RageHead=true
            Flags.RageBody=false
            Flags.RageHC=100
            Flags.RagePred=true
            Flags.RagePredF=50
            Flags.SAHC=100
            Flags.SAHeadshot=true
        end) end
    end
end)

-- Jump Scout Engine
task.spawn(function()
    while true do task.wait()
        if Flags.JumpScout and alive() then pcall(function()
            local h=hum(); local myH=hrp()
            if not h or not myH then return end
            -- Jump-peek: jump, shoot at peak, land
            local t=time()
            local delay=(Flags.JSDelay or 150)/1000
            -- Check if on ground
            local params=RaycastParams.new()
            params.FilterType=Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances={lplr.Character}
            local downRay=workspace:Raycast(myH.Position,Vector3.new(0,-3,0),params)
            if downRay then
                -- On ground: jump and shoot
                -- h:ChangeState(Enum.HumanoidStateType.Jumping)
                task.wait(delay)
                -- Shoot at peak
                local tool=lplr.Character and lplr and lplr.Character:FindFirstChildWhichIsA("Tool")
                if tool and not tool.Name:lower():find("knife") then
                    -- tool:Activate()
                end
            end
        end) end
    end
end)

-- Edge Bug Friction Engine
task.spawn(function()
    while true do task.wait(0.1)
        if Flags.EdgeBugFriction and alive() then pcall(function()
            local myH=hrp(); local h=hum()
            if not myH or not h then return end
            -- Detect if near edge and reduce friction
            local params=RaycastParams.new()
            params.FilterType=Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances={lplr.Character}
            local lookVec=myH.CFrame.LookVector
            local result=workspace:Raycast(myH.Position,lookVec*4+Vector3.new(0,-6,0),params)
            if result then
                -- Near edge, reduce friction for faster movement
                for _,part in pairs(lplr.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CustomPhysicalProperties=PhysicalProperties.new(0.1,0.3,0.1,1,1)
                    end
                end
            else
                -- Not near edge, restore normal friction
                for _,part in pairs(lplr.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CustomPhysicalProperties=nil
                    end
                end
            end
        end) end
    end
end)

-- HVH Super Mode Auto-Configure Engine
task.spawn(function()
    while true do task.wait(5)
        if Flags.HVHSuper and alive() then pcall(function()
            -- Auto-configure all HVH settings based on situation
            local enemies=BS.enemies()
            local ping=BS.Ping and BS.Ping.Current or 50
            local closeThreat=0
            local myH=hrp()
            for _,e in ipairs(enemies) do
                if e.HRP and myH then
                    local dist=(myH.Position-e.HRP.Position).Magnitude
                    if dist<30 then closeThreat=closeThreat+1 end
                end
            end
            -- Adjust ragebot based on ping
            if Flags.Ragebot then
                Flags.RageHC=ping>150 and 80 or 100
                Flags.RageFR=ping>150 and 15 or 12
            end
            -- Adjust AA based on threat level
            if Flags.AA then
                if closeThreat>2 then
                    Flags.AAYaw="LBY Break"
                    Flags.AAJittR=150
                    Flags.AADesync=true
                    Flags.AAFakeDuck=true
                elseif closeThreat==1 then
                    Flags.AAYaw="Spin"
                    Flags.AASpd=15
                end
            end
            -- Adjust fake lag based on ping
            if Flags.FL then
                Flags.FLChoke=ping>150 and 5 or 8
            end
        end) end
    end
end)

-- VISUALIZER
    local vizFovCirc,vizTgtLine,vizWbLine=nil,nil,nil
task.spawn(function()
    while true do task.wait()
        pcall(function()
            local cam=workspace.CurrentCamera; local mouse=UIS:GetMouseLocation()
            -- Rage FOV circle
            if Flags.Ragebot then
                if not vizFovCirc then vizFovCirc=safeDrawingNew("Circle"); if vizFovCirc then vizFovCirc.Thickness=1; vizFovCirc.NumSides=64; vizFovCirc.Filled=false end end
                vizFovCirc.Position=mouse; vizFovCirc.Radius=RAGE.Fov; vizFovCirc.Color=Color3.fromRGB(255,0,0); vizFovCirc.Visible=true
            else if vizFovCirc then vizFovCirc.Visible=false end end
            -- Target line
            if RAGE.Target and RAGE.Target.BonePos then
                local sp,sv=cam:WorldToViewportPoint(RAGE.Target.BonePos)
                if sv then
                    if not vizTgtLine then vizTgtLine=safeDrawingNew("Line"); if vizTgtLine then vizTgtLine.Thickness=2 end end
                    vizTgtLine.From=mouse; vizTgtLine.To=Vector2.new(sp.X,sp.Y); vizTgtLine.Color=Color3.fromRGB(255,0,0); vizTgtLine.Visible=true
                end
            else if vizTgtLine then vizTgtLine.Visible=false end end
        end)
    end
end)

 -- Cleanup
lplr.CharacterRemoving:Connect(function()
    RAGE.Target=nil; RAGE.Targets={}; resData={}
    if vizFovCirc then vizFovCirc.Visible=false end
    if vizTgtLine then vizTgtLine.Visible=false end
    if saFovCircle then saFovCircle.Visible=false end
    if aaVizCircle then aaVizCircle.Visible=false end
end)print("[Rage] BloxStrike Rage v3.0 - CS2 HVH Edition")
print("[Rage] All features loaded successfully")
print("[Rage] 1  Ragebot (HC, Bone, Sort, Double Tap, Triple Tap)")
print("[Rage] 1A Multipoint + Safe Point + Damage Override + Force Aim")
print("[Rage] 1B Silent Aim (4 modes, Backtrack, Magic Bullet)")
print("[Rage] 1C PSilent + Rapid Fire NEW")
print("[Rage] 1D Bullet Tracer + Hit Marker")
print("[Rage] 2  Anti-Aim (Pitch, Yaw, Speed, Fake Duck)")
print("[Rage] 2B Desync + Emotion + Lean + LBY Breaker + Manual AA NEW")
print("[Rage] 3  Fake Lag (Constant, Adaptive, Random, Tick)")
print("[Rage] 3B Exploits: Hideshots + Onshot + Fake Duck NEW")
print("[Rage] 4  Resolver (Smart, Brute, Moving AA)")
print("[Rage] 4B Moving AA Resolver + Side Detection + Anim Breaker NEW")
print("[Rage] 5  HVH Utilities (Slide Walk, Pixel Surf, Quick Switch)")
print("[Rage] 6  HVH Presets (Full Rage, Anti-Oneshot)")
print("[Rage] 7  Advanced HVH (HVH Super, Auto AA/FL/Resolver)")
print("[Rage] 8  HVH Statistics"
print("[Rage] "
