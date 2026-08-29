--[[
    Bed Wars Quick Executor Loader
    Paste this into your executor to auto-load the full script
    
    Compatible with: Fluxus, Delta, Wave, Synapse X, Arceus X, Hydrogen
]]

-- Auto-detect and load the main script
local success, err = pcall(function()
    -- Method 1: Load from file if local
    if isfile and isfile("BedWars_Main.lua") then
        loadstring(readfile("BedWars_Main.lua"))()
        return
    end
    
    -- Method 2: Direct paste (you already have the script above)
    print("[BedWars] Please paste the full script from BedWars_Main.lua")
end)

if not success then
    warn("[BedWars Loader] Error: " .. tostring(err))
    -- Fallback: print instructions
    print("╔══════════════════════════════════════════════╗")
    print("║  BED WARS SCRIPT LOADER                     ║")
    print("║                                              ║")
    print("║  1. Copy the contents of BedWars_Main.lua    ║")
    print("║  2. Paste into your executor                 ║")
    print("║  3. Execute the script                       ║")
    print("║                                              ║")
    print("║  Press RightAlt to toggle the UI             ║")
    print("╚══════════════════════════════════════════════╝")
end
