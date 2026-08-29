-- ═══════════════════════════════════════════════════════
-- Enlisted Offset Finder — Paste this in CE Lua Engine
-- Tools → Lua Engine → Paste → Run
-- ═══════════════════════════════════════════════════════

print("═══════════════════════════════════════════════")
print("  Enlisted Offset Finder — Starting...")
print("═══════════════════════════════════════════════")

-- Get process
local pid = getOpenedProcessID()
if pid == 0 then
    print("ERROR: No process attached! Attach to enlisted.exe first!")
    return
end
print("[+] Attached to PID: " .. pid)

-- Search for strings in module memory
local results = {}

function searchForString(searchStr)
    print("[*] Searching for: " .. searchStr)
    local found = {}
    
    -- Get memory regions
    local memRegions =EnumMemoryRegions(pid, 0x40) -- PAGE_EXECUTE_READ
    for i=1, #memRegions do
        local r = memRegions[i]
        -- Read region
        local success, data = pcall(function() return readMemory(r.BaseAddress, r.RegionSize) end)
        if success and data then
            -- Convert to string for searching
            local str = ""
            for j=1, math.min(#data, 100) do
                str = str .. string.char(data[j])
            end
            
            -- Check if our target is in this region's readable data
            -- Use a different approach: scan byte by byte
            local baseAddr = r.BaseAddress
            local regionSize = r.RegionSize
            
            -- Read as string
            local s = readString(baseAddr, regionSize, true)
            if s then
                local pos = string.find(s, searchStr, 1, true)
                if pos then
                    local foundAddr = baseAddr + pos - 1
                    table.insert(found, foundAddr)
                    print("  [+] Found at: 0x" .. string.format("%X", foundAddr))
                end
            end
        end
    end
    
    -- Also try wider read
    local regions2 =EnumMemoryRegions(pid, 0x04) -- PAGE_READWRITE
    for i=1, #regions2 do
        local r = regions2[i]
        local s = pcall(function() return readString(r.BaseAddress, math.min(r.RegionSize, 1048576), true) end)
        if s then
            local pos = string.find(s, searchStr, 1, true)
            if pos then
                local foundAddr = r.BaseAddress + pos - 1
                -- Check if already found
                local exists = false
                for _, v in ipairs(found) do
                    if v == foundAddr then exists = true break end
                end
                if not exists then
                    table.insert(found, foundAddr)
                    print("  [+] Found at: 0x" .. string.format("%X", foundAddr))
                end
            end
        end
    end
    
    return found
end

-- Main search
local targets = {
    "globtm_psf_0",
    "globtm_psf_1",
    "ecs::EntityManager",
    "camera__look_at",
    "isAlive",
    "transform",
    "human_net_phys",
    "animchar",
    "velocity",
    "binded_camera"
}

for _, target in ipairs(targets) do
    local found = searchForString(target)
    results[target] = found
    print("")
end

-- Print results
print("═══════════════════════════════════════════════")
print("  RESULTS — Copy these to DagorSDK.cs")
print("═══════════════════════════════════════════════")

for target, addrs in pairs(results) do
    if #addrs > 0 then
        -- Calculate RVA (assuming first module is enlisted.exe)
        local moduleBase = getModuleBaseAddress(pid)
        if moduleBase == 0 then moduleBase = getModuleBase(pid, "enlisted.exe") end
        if moduleBase == 0 then moduleBase = addrs[1] end
        
        local rva = addrs[1] - moduleBase
        print(string.format('#define RVA_%s 0x%X  // abs: 0x%X', 
            string.upper(target:gsub("[^a-zA-Z0-9]", "_")), rva, addrs[1]))
    else
        print(string.format('// %s NOT FOUND', target))
    end
end

print("")
print("═══ DONE ═══")
