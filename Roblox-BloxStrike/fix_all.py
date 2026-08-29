#!/usr/bin/env python3
"""
BloxStrike One-Click Fix Tool
==============================
All-in-one script that scans and fixes all issues in one pass.

Fixes:
  PHASE 1: Comment Fixes (from fix_comments.py)
    1. Commented closing parens:     -- )
    2. Commented function calls:     -- StarterGui:SetCore(...)
    3. Commented :Play() calls:      -- tween:Play()
    4. Commented table keys:         -- ["key"] = {
    5. Commented function defs:      -- function foo()
    6. Commented local tables:       -- local X = {
    7. Double commas:                ,,
    8. Broken gsub patterns:         [^\n-- ]

  PHASE 2: Nil Index Fixes (from fix_nil.py)
    9. GetService without pcall:     → pcall wrapper
   10. stats.Network chains:         → pcall wrapper
   11. tool.Handle.Position:         → nil check
   12. player.Character access:      → nil check

  PHASE 3: Syntax Validation
   13. Brace balance check
   14. Report remaining issues

Usage:
  python3 fix_all.py              # Fix all modules
  python3 fix_all.py --scan       # Scan only, no fixes
  python3 fix_all.py --verbose    # Show all details
"""

import os
import re
import glob
import sys

MODULES_DIR = "modules"
VERBOSE = "--verbose" in sys.argv
SCAN_ONLY = "--scan" in sys.argv

# ═══════════════════════════════════════════════════════════════
# PHASE 1: COMMENT FIXES
# ═══════════════════════════════════════════════════════════════

def fix_comments(filepath):
    """Fix incorrectly commented code."""
    with open(filepath, "r", encoding="utf-8", errors="replace") as f:
        lines = f.readlines()
    
    original = lines.copy()
    fixes = 0
    details = []
    
    # Pattern 1: Fix orphaned -- ) (closing paren without opening)
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("--"):
            content = stripped[2:].strip()
            if re.match(r'^\)\s*(then|else|elseif|do|end)?', content):
                depth = 0
                for j in range(i - 1, max(i - 30, -1), -1):
                    above = lines[j].rstrip("\n").rstrip("\r")
                    depth += above.count(")") - above.count("(")
                    if depth < 0:
                        lines[i] = line.replace(stripped, content, 1)
                        if lines[i] != original[i]:
                            fixes += 1
                            details.append(f"  L{i+1}: uncommented -- ) ...")
                        break
    
    # Pattern 2: Fix commented StarterGui:SetCore / :Play()
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("--"):
            content = stripped[2:].strip()
            if "StarterGui" in content and "SetCore" in content:
                lines[i] = line.replace(stripped, content, 1)
                if lines[i] != original[i]:
                    fixes += 1
                    details.append(f"  L{i+1}: uncommented StarterGui:SetCore")
            elif re.search(r':Play\s*\(', content) or "tween:Play" in content:
                lines[i] = line.replace(stripped, content, 1)
                if lines[i] != original[i]:
                    fixes += 1
                    details.append(f"  L{i+1}: uncommented :Play()")
    
    # Pattern 3: Fix commented table keys with loose bodies
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("--"):
            content = stripped[2:].strip()
            # -- ["key"] = {
            if re.match(r'^\["[^"]+"\]\s*=\s*\{', content):
                if i + 1 < len(lines):
                    next_stripped = lines[i + 1].strip()
                    if next_stripped and not next_stripped.startswith("--"):
                        lines[i] = line.replace(stripped, content, 1)
                        if lines[i] != original[i]:
                            fixes += 1
                            details.append(f"  L{i+1}: uncommented table key")
            # -- local X = {
            elif re.match(r'^local\s+\w+\s*=\s*\{', content):
                if i + 1 < len(lines):
                    next_stripped = lines[i + 1].strip()
                    if next_stripped and not next_stripped.startswith("--"):
                        lines[i] = line.replace(stripped, content, 1)
                        if lines[i] != original[i]:
                            fixes += 1
                            details.append(f"  L{i+1}: uncommented local table")
            # -- function foo()
            elif re.match(r'^function\s+\w+', content):
                if i + 1 < len(lines):
                    next_stripped = lines[i + 1].strip()
                    if next_stripped and not next_stripped.startswith("--"):
                        lines[i] = line.replace(stripped, content, 1)
                        if lines[i] != original[i]:
                            fixes += 1
                            details.append(f"  L{i+1}: uncommented function def")
    
    # Pattern 4: Fix double commas: ,, → ,
    for i, line in enumerate(lines):
        if not line.strip().startswith("--"):
            new_line = re.sub(r',(\s*),', r',\1', line)
            if new_line != line:
                lines[i] = new_line
                fixes += 1
                details.append(f"  L{i+1}: fixed double comma")
    
    # Pattern 5: Fix broken gsub patterns
    for i, line in enumerate(lines):
        if not line.strip().startswith("--"):
            new_line = line.replace('[^\\n-- ]', '.-')
            new_line = new_line.replace('[^\\n--  ]', '.-')
            if new_line != line:
                lines[i] = new_line
                fixes += 1
                details.append(f"  L{i+1}: fixed gsub pattern")
    
    # Write if changed
    if lines != original and not SCAN_ONLY:
        with open(filepath, "w", encoding="utf-8", newline="\n") as f:
            f.writelines(lines)
    
    return fixes, details


# ═══════════════════════════════════════════════════════════════
# PHASE 2: NIL INDEX FIXES
# ═══════════════════════════════════════════════════════════════

def fix_nil_index(filepath):
    """Fix nil index runtime errors."""
    with open(filepath, "r", encoding="utf-8", errors="replace") as f:
        content = f.read()
    
    original = content
    fixes = 0
    details = []
    
    # Fix 1: GetService without pcall
    def fix_getservice(m):
        nonlocal fixes
        indent = m.group(1)
        varname = m.group(2)
        service = m.group(3)
        fixes += 1
        details.append(f"  GetService → pcall: {varname}")
        return (f"{indent}local {varname} = nil\n"
                f"{indent}pcall(function() {varname} = game:GetService({service}) end)")
    
    content = re.sub(
        r'^(\s*)local (\w+)\s*=\s*game:GetService\(([^)]+)\)\s*$',
        fix_getservice,
        content,
        flags=re.MULTILINE
    )
    
    # Fix 2: stats.Network.ServerStatsItem chain
    old1 = 'local pingVal = stats.Network.ServerStatsItem["Data Ping"].Value'
    new1 = ('local pingVal = 0\n'
            '            pcall(function() pingVal = stats.Network.ServerStatsItem["Data Ping"].Value end)')
    if old1 in content:
        content = content.replace(old1, new1)
        fixes += 1
        details.append("  ServerStatsItem chain → pcall")
    
    old2 = 'local basePing = stats.Network.ServerStatsItem["Data Ping"]:GetValue()'
    new2 = ('local basePing = 0\n'
            '                    pcall(function() basePing = stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)')
    if old2 in content:
        content = content.replace(old2, new2)
        fixes += 1
        details.append("  ServerStatsItem:GetValue → pcall")
    
    # Fix 3: tool.Handle.Position without nil check
    def fix_tool_handle(m):
        nonlocal fixes
        fixes += 1
        return '(tool.Handle and tool.Handle.Position or hrp.Position)'
    
    content = re.sub(
        r'(?<!\band\s)(?<!\?)tool\.Handle\.Position(?!\s*or\b)',
        fix_tool_handle,
        content
    )
    
    # Fix 4: player.Character:FindFirstChild without nil check
    def fix_character(m):
        nonlocal fixes
        var = m.group(1)
        method = m.group(2) or ""
        fixes += 1
        return f'{var} and {var}.Character:FindFirstChild{method}('
    
    content = re.sub(
        r'(\w+)\.Character:FindFirstChild(OfClass|WhichIsA)?\s*\(',
        fix_character,
        content
    )
    
    # Deduplicate: "X and X and X" → "X and X"
    content = re.sub(r'(\w+) and \1 and \1', r'\1 and \1', content)
    
    # Write if changed
    if content != original and not SCAN_ONLY:
        with open(filepath, "w", encoding="utf-8", newline="\n") as f:
            f.write(content)
    
    return fixes, details


# ═══════════════════════════════════════════════════════════════
# PHASE 3: VALIDATION
# ═══════════════════════════════════════════════════════════════

def validate_file(filepath):
    """Check brace balance and report issues."""
    with open(filepath, "r", encoding="utf-8", errors="replace") as f:
        lines = f.readlines()
    
    issues = []
    
    # Brace balance
    depth = 0
    for i, line in enumerate(lines):
        s = line.strip()
        if s.startswith("--"):
            continue
        depth += s.count("{") - s.count("}")
    if depth != 0:
        issues.append(f"Brace imbalance: {depth}")
    
    # Paren balance (rough)
    depth = 0
    for i, line in enumerate(lines):
        s = line.strip()
        if s.startswith("--"):
            continue
        depth += s.count("(") - s.count(")")
    if abs(depth) > 2:  # Allow small imbalance (multi-line expressions)
        issues.append(f"Paren imbalance: {depth}")
    
    # Check for remaining known issues
    for i, line in enumerate(lines):
        s = line.strip()
        if s.startswith("--"):
            continue
        
        # Double comma
        if ",," in s:
            issues.append(f"L{i+1}: double comma still present")
        
        # Broken gsub pattern
        if "[^\\\\n-- ]" in s or "[^\\\\n--  ]" in s:
            issues.append(f"L{i+1}: broken gsub pattern")
    
    return issues


# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════

def main():
    mode = "SCAN" if SCAN_ONLY else "FIX"
    
    print("=" * 60)
    print(f"  BloxStrike One-Click Fix Tool [{mode}]")
    print("=" * 60)
    
    lua_files = sorted(glob.glob(os.path.join(MODULES_DIR, "*.lua")))
    
    if not lua_files:
        print(f"  ERROR: No .lua files found in {MODULES_DIR}/")
        return
    
    total_comment_fixes = 0
    total_nil_fixes = 0
    total_validation_issues = 0
    files_with_issues = []
    
    for filepath in lua_files:
        name = os.path.basename(filepath)
        
        # Phase 1: Comment fixes
        comment_fixes, comment_details = fix_comments(filepath)
        total_comment_fixes += comment_fixes
        
        # Phase 2: Nil index fixes
        nil_fixes, nil_details = fix_nil_index(filepath)
        total_nil_fixes += nil_fixes
        
        # Phase 3: Validation
        val_issues = validate_file(filepath)
        total_validation_issues += len(val_issues)
        
        # Report
        has_issues = comment_fixes > 0 or nil_fixes > 0 or len(val_issues) > 0
        
        if has_issues:
            files_with_issues.append(name)
            print(f"\n  {name}")
            print("  " + "-" * 50)
            
            if comment_fixes > 0:
                print(f"    Comments: {comment_fixes} fixes")
                if VERBOSE:
                    for d in comment_details:
                        print(f"      {d}")
            
            if nil_fixes > 0:
                print(f"    Nil fixes: {nil_fixes} fixes")
                if VERBOSE:
                    for d in nil_details:
                        print(f"      {d}")
            
            if val_issues:
                print(f"    Warnings: {len(val_issues)}")
                for d in val_issues:
                    print(f"      ! {d}")
        else:
            print(f"  {name}: OK")
    
    # Also check loader
    loader = "BloxStrike.lua"
    if os.path.exists(loader):
        cf, cd = fix_comments(loader)
        nf, nd = fix_nil_index(loader)
        vi = validate_file(loader)
        total_comment_fixes += cf
        total_nil_fixes += nf
        total_validation_issues += len(vi)
        if cf > 0 or nf > 0 or vi:
            print(f"\n  {loader}")
            if cf > 0: print(f"    Comments: {cf} fixes")
            if nf > 0: print(f"    Nil fixes: {nf} fixes")
            for d in vi: print(f"    ! {d}")
    
    # Summary
    print("\n" + "=" * 60)
    print(f"  SUMMARY")
    print("=" * 60)
    print(f"  Comment fixes:  {total_comment_fixes}")
    print(f"  Nil fixes:      {total_nil_fixes}")
    print(f"  Total fixes:    {total_comment_fixes + total_nil_fixes}")
    print(f"  Validation:     {total_validation_issues} warnings")
    print(f"  Files scanned:  {len(lua_files)}")
    print(f"  Files changed:  {len(files_with_issues)}")
    
    if total_validation_issues > 0:
        print(f"\n  ! {total_validation_issues} validation warnings remain")
        print("  Run with --verbose for details")
    
    print("=" * 60)


if __name__ == "__main__":
    main()
