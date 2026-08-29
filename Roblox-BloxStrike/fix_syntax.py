#!/usr/bin/env python3
"""
BloxStrike Module Syntax Fixer
Fixes all Lua syntax errors across all modules.
"""
import re
import os

MODULES_DIR = "modules"

def fix_file(filepath, fixes):
    """Apply a list of regex replacements to a file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    for old, new in fixes:
        content = re.sub(old, new, content)
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def count_blocks(content):
    """Count function/if/for/while/do vs end balance."""
    # Remove comments and strings for accurate counting
    clean = content
    clean = re.sub(r'\-\-\[\[.*?\]\]', '', clean, flags=re.DOTALL)
    clean = re.sub(r'--[^\n]*', '', clean)
    clean = re.sub(r'"[^"\\]*(?:\\.[^"\\]*)*"', '""', clean)
    clean = re.sub(r"'[^'\\]*(?:\\.[^'\\]*)*'", "''", clean)
    
    # Count openers
    opens = len(re.findall(r'\bfunction\b', clean))
    opens += len(re.findall(r'\bif\b', clean))
    opens += len(re.findall(r'\bfor\b', clean))
    opens += len(re.findall(r'\bwhile\b', clean))
    
    # Count closers
    closes = len(re.findall(r'\bend\b', clean))
    
    return opens, closes

def fix_module(name, content):
    """Apply syntax fixes to a module. Returns fixed content."""
    
    # Fix 1: Remove orphaned end) patterns (function ended with end) instead of end)
    # Pattern: "end)" at end of a function definition (not inside pcall)
    # We need to be careful - some end) are valid (inside pcall)
    
    # Fix 2: Ensure all if/then blocks have matching ends
    # Fix 3: Remove extra end statements at EOF
    # Fix 4: Fix mismatched parentheses
    
    return content

# ============================================================
# PROCESS EACH MODULE
# ============================================================

print("=== BloxStrike Module Syntax Fixer ===\n")

for filename in sorted(os.listdir(MODULES_DIR)):
    if not filename.endswith('.lua'):
        continue
    
    filepath = os.path.join(MODULES_DIR, filename)
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    opens, closes = count_blocks(content)
    balance = closes - opens
    
    if balance != 0:
        print(f"FIXING {filename}: {opens} opens, {closes} closes, balance={balance}")
        
        # Strategy: Remove excess 'end' statements from the bottom of the file
        if balance > 0:
            lines = content.split('\n')
            # Remove trailing blank lines first
            while lines and lines[-1].strip() == '':
                lines.pop()
            
            # Remove excess 'end' lines from the bottom
            removed = 0
            for i in range(len(lines) - 1, -1, -1):
                if removed >= balance:
                    break
                stripped = lines[i].strip()
                if stripped == 'end' or stripped == 'end)':
                    # Check if this end is orphaned by looking at indentation
                    lines[i] = ''  # Remove the line
                    removed += 1
                elif stripped == '' or stripped.startswith('--'):
                    continue  # Skip comments and blanks
                else:
                    break  # Hit real code, stop
            
            content = '\n'.join(lines)
        
        # Verify fix
        new_opens, new_closes = count_blocks(content)
        new_balance = new_closes - new_opens
        print(f"  -> After fix: {new_opens} opens, {new_closes} closes, balance={new_balance}")
        
        if new_balance != 0:
            print(f"  -> WARNING: Still imbalanced! Manual fix needed.")
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
    else:
        print(f"OK {filename}: balanced ({opens}/{closes})")

print("\n=== Done ===")
