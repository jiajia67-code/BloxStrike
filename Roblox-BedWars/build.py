#!/usr/bin/env python3
"""BedWars Ultimate Build Script v5.1"""
import os, shutil
from datetime import datetime

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODULES_DIR = os.path.join(BASE_DIR, "modules")
OUTPUT_FILE = os.path.join(BASE_DIR, "BedWars_Ultimate.lua")
POTASSIUM_DIR = os.path.join(os.path.expanduser("~"), "AppData", "Local", "Potassium", "scripts", "\u5e8a\u6230")
BACKUP_DIR = os.path.join(BASE_DIR, "backups")

MODULE_ORDER = ["compat", "perf", "combat", "world", "esp", "move", "shop", "util", "legit", "autoload", "events", "game"]

def read_file(path):
    with open(path, "r", encoding="utf-8") as f:
        return f.read()

def main():
    print("[BUILD] BedWars Ultimate v5.1 (CatVape-style)...")
    core = read_file(os.path.join(MODULES_DIR, "core.lua"))
    api = read_file(os.path.join(MODULES_DIR, "api.lua"))
    ui = read_file(os.path.join(MODULES_DIR, "ui.lua"))
    modules = {}
    for name in MODULE_ORDER:
        path = os.path.join(MODULES_DIR, f"{name}.lua")
        if os.path.exists(path):
            modules[name] = read_file(path)
            print(f"  [OK] {name}.lua")

    L = []
    L.append("--!nocheck")
    L.append("-- BED WARS ULTIMATE v5.1 (CatVape-style)")
    L.append("-- Built: " + datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    L.append("if shared.BWLoaded then warn('[BedWars] Already loaded!') return end")
    L.append("shared.BWLoaded = true")
    L.append("")
    L.append("-- CORE")
    L.append("local function createCore()")
    L.append(core)
    L.append("end")
    L.append("")
    L.append("-- API")
    L.append("local function createAPI(bw)")
    L.append(api)
    L.append("end")
    L.append("")
    L.append("-- UI")
    L.append("local function createUI(bw, flags, api)")
    L.append(ui)
    L.append("end")
    L.append("")
    for name, content in modules.items():
        L.append("-- " + name.upper())
        L.append("local function load_" + name + "(bw, flags, ui, api)")
        L.append(content)
        L.append("end")
        L.append("")

    L.append("-- INITIALIZATION")
    L.append("(function()")
    L.append("    print('==========================================')")
    L.append("    print('  BED WARS ULTIMATE v5.1 (CatVape-style)')")
    L.append("    print('==========================================')")
    L.append("")
    L.append("    local bw = createCore()")
    L.append("    local flags = bw.Flags")
    L.append("    local api = createAPI(bw)")
    L.append("    local Library = createUI(bw, flags, api)")
    L.append("    local ui = Library:New({Title='BedWars', Sub='v5.1'})")
    L.append("    bw.Win = ui")
    L.append("    BW = bw  -- Make global BW available to all modules")
    L.append("    -- Performance cache")
    L.append("    local perf = load_perf(bw, flags, ui, api)")
    L.append("    bw.Perf = perf")
    L.append("    BW.Perf = perf")
    L.append("")
    L.append("    bw.Compat = load_compat(bw, flags, ui, api)")
    L.append("")
    L.append("    local moduleList = {'compat', 'perf', 'combat', 'world', 'esp', 'move', 'shop', 'util', 'legit', 'autoload', 'events', 'game'}")
    L.append("    for _, name in pairs(moduleList) do")
    L.append("        local success, err = pcall(function()")
    L.append("            if name == 'compat' then load_compat(bw, flags, ui, api)")
    L.append("            elseif name == 'perf' then load_perf(bw, flags, ui, api)")
    L.append("            elseif name == 'combat' then load_combat(bw, flags, ui, api)")
    L.append("            elseif name == 'world' then load_world(bw, flags, ui, api)")
    L.append("            elseif name == 'esp' then load_esp(bw, flags, ui, api)")
    L.append("            elseif name == 'move' then load_move(bw, flags, ui, api)")
    L.append("            elseif name == 'shop' then load_shop(bw, flags, ui, api)")
    L.append("            elseif name == 'util' then load_util(bw, flags, ui, api)")
    L.append("            elseif name == 'legit' then load_legit(bw, flags, ui, api)")
    L.append("            elseif name == 'autoload' then load_autoload(bw, flags, ui, api)")
    L.append("            elseif name == 'events' then load_events(bw, flags, ui, api)")
    L.append("            elseif name == 'game' then load_game(bw, flags, ui, api)")
    L.append("            end")
    L.append("        end)")
    L.append("        if success then print('[OK] ' .. name)")
    L.append("        else warn('[FAIL] ' .. name .. ': ' .. tostring(err)) end")
    L.append("    end")
    L.append("")
    L.append("    print('==========================================')")
    L.append("    print('  All modules loaded!')")
    L.append("    if bw.isMobile then print('  Mobile: Tap X to toggle UI')")
    L.append("    else print('  PC: Press RightAlt to toggle UI') end")
    L.append("    print('==========================================')")
    L.append("end)()")

    content = "\n".join(L)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"\n[OUTPUT] ({len(content)} bytes)")
    if os.path.exists(POTASSIUM_DIR):
        shutil.copy2(OUTPUT_FILE, os.path.join(POTASSIUM_DIR, "BedWars_Ultimate.lua"))
        shutil.copy2(OUTPUT_FILE, os.path.join(POTASSIUM_DIR, "main_full.lua"))
        print("[COPY] Potassium")
    os.makedirs(BACKUP_DIR, exist_ok=True)
    backup = os.path.join(BACKUP_DIR, "BedWars_" + datetime.now().strftime("%Y%m%d_%H%M%S") + ".lua")
    shutil.copy2(OUTPUT_FILE, backup)
    print("[DONE]")

if __name__ == "__main__":
    main()
