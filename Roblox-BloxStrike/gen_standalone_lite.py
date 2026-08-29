#!/usr/bin/env python3
"""Generate a compressed standalone BloxStrike script."""
import os, re

MODULES_DIR = "modules"
OUTPUT = "BloxStrike_Standalone.lua"

def strip_comments(code):
    """Remove comments and blank lines to reduce size."""
    result = []
    for line in code.split("\n"):
        stripped = line.strip()
        # Skip blank lines
        if not stripped:
            continue
        # Skip pure comment lines (but keep --!nocheck and shebang)
        if stripped.startswith("--") and not stripped.startswith("--!"):
            # Keep comments that are section headers
            if stripped.startswith("-- ═══") or stripped.startswith("-- SECTION"):
                result.append(line)
            continue
        # Remove inline comments (careful with strings)
        # Simple approach: only remove -- at end of line if not in string
        if "--" in stripped:
            # Rough check: if -- is preceded by space and not inside quotes
            in_string = False
            quote_char = None
            for i, ch in enumerate(stripped):
                if ch in ('"', "'") and (i == 0 or stripped[i-1] != "\\"):
                    if not in_string:
                        in_string = True
                        quote_char = ch
                    elif ch == quote_char:
                        in_string = False
                elif ch == "-" and i + 1 < len(stripped) and stripped[i+1] == "-" and not in_string:
                    stripped = stripped[:i].rstrip()
                    break
        result.append(stripped)
    return "\n".join(result)

# Read all modules
modules = {}
for fname in sorted(os.listdir(MODULES_DIR)):
    if fname.endswith(".lua"):
        with open(os.path.join(MODULES_DIR, fname), "r", encoding="utf-8") as f:
            raw = f.read()
        modules[fname] = strip_comments(raw)

# Read loader
with open("BloxStrike.lua", "r", encoding="utf-8") as f:
    loader = strip_comments(f.read())

lines = []
lines.append('--[[ BloxStrike v3.0 Standalone - Direct paste and run ]]')
lines.append('print("[BloxStrike] v3.0 Standalone Loading...")')
lines.append("pcall(function() makefolder('BloxStrike') end)")
lines.append("pcall(function() makefolder('BloxStrike/modules') end)")

for name, content in sorted(modules.items()):
    lines.append(f'writefile("BloxStrike/modules/{name}", [[')
    lines.append(content)
    lines.append(']])')

lines.append("writefile('BloxStrike/BloxStrike.lua', [[")
lines.append(loader)
lines.append("]])")
lines.append("print('[BloxStrike] All files written! Executing...')")
lines.append("local fn = loadstring(readfile('BloxStrike/BloxStrike.lua'), 'BloxStrike')")
lines.append("if fn then fn() else print('[BloxStrike] Load failed!') end")

with open(OUTPUT, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))

size = os.path.getsize(OUTPUT)
print(f"Generated: {OUTPUT}")
print(f"Modules: {len(modules)}")
print(f"Lines: {len(lines)}")
print(f"Size: {size:,} bytes ({size/1024:.1f} KB)")

# Show per-module sizes
print("\nPer-module (compressed):")
for name, content in sorted(modules.items()):
    print(f"  {name:25s} {len(content):6d} bytes")
