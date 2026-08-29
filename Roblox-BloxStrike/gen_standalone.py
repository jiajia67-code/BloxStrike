#!/usr/bin/env python3
"""Generate a standalone BloxStrike script with all modules embedded."""
import os

MODULES_DIR = "modules"
OUTPUT = "BloxStrike_Standalone.lua"

# Read all modules
modules = {}
for fname in sorted(os.listdir(MODULES_DIR)):
    if fname.endswith(".lua"):
        with open(os.path.join(MODULES_DIR, fname), "r", encoding="utf-8") as f:
            modules[fname] = f.read()

# Also read the loader
with open("BloxStrike.lua", "r", encoding="utf-8") as f:
    loader = f.read()

lines = []
lines.append("--[[")
lines.append("    BloxStrike v3.0 - One-Click Standalone Version")
lines.append("    Direct paste and run - all modules embedded")
lines.append("--]]")
lines.append("")
lines.append('print("[BloxStrike] v3.0 Standalone Loading...")')
lines.append("")
lines.append("pcall(function() makefolder('BloxStrike') end)")
lines.append("pcall(function() makefolder('BloxStrike/modules') end)")
lines.append("")

# Write each module using [[ ]] multiline strings
for name, content in sorted(modules.items()):
    lines.append(f'-- Write {name}')
    lines.append(f'writefile("BloxStrike/modules/{name}", [[')
    lines.append(content)
    lines.append(']])')
    lines.append("")

# Write the loader
lines.append("-- Write loader")
lines.append("writefile('BloxStrike/BloxStrike.lua', [[")
lines.append(loader)
lines.append("]])")
lines.append("")

# Execute the loader
lines.append('-- Execute')
lines.append("print('[BloxStrike] All files written! Executing...')")
lines.append("print('')")
lines.append("local fn = loadstring(readfile('BloxStrike/BloxStrike.lua'), 'BloxStrike')")
lines.append("if fn then fn() else print('[BloxStrike] Load failed!') end")

with open(OUTPUT, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))

size = os.path.getsize(OUTPUT)
print(f"Generated: {OUTPUT}")
print(f"Modules: {len(modules)}")
print(f"Lines: {len(lines)}")
print(f"Size: {size:,} bytes ({size/1024:.1f} KB)")
