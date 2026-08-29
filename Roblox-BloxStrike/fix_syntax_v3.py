#!/usr/bin/env python3
"""
BloxStrike Module Syntax Fixer v3
Uses line-by-line depth tracking to find and remove orphaned 'end' statements.
"""
import re, os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
MODULES_DIR = os.path.join(SCRIPT_DIR, "modules")

def strip_strings_and_comments(code):
    """Remove Lua strings and comments."""
    result = []
    i = 0
    in_bc = False
    while i < len(code):
        if in_bc:
            idx = code.find(']]', i)
            if idx >= 0:
                i = idx + 2; in_bc = False
            else:
                break
            continue
        ch = code[i]
        if ch in ('"', "'"):
            q = ch; i += 1
            while i < len(code) and code[i] != q:
                if code[i] == '\\' and i+1 < len(code): i += 2
                else: i += 1
            i += 1; result.append(' '); continue
        if ch == '[' and i+1 < len(code) and code[i+1] == '[':
            idx = code.find(']]', i+2)
            i = idx+2 if idx >= 0 else len(code)
            result.append(' '); continue
        if ch == '-' and i+1 < len(code) and code[i+1] == '-':
            if i+3 < len(code) and code[i+2] == '[' and code[i+3] == '[':
                in_bc = True; i += 4
            else:
                nl = code.find('\n', i)
                i = nl+1 if nl >= 0 else len(code)
            continue
        result.append(ch); i += 1
    return ''.join(result)

def calc_line_depth_change(line_stripped):
    """Calculate depth change for a single stripped line."""
    change = 0
    for m in re.finditer(r'\b(function|if|for|while|do|repeat|end|until)\b', line_stripped):
        word = m.group()
        if word in ('end', 'until'):
            change -= 1
        elif word == 'do':
            before = line_stripped[:m.start()].rstrip()
            if not re.search(r'\b(for|while)\s', before):
                change += 1
        elif word == 'repeat':
            change += 1
        else:
            change += 1
    return change

def calc_line_paren_change(line_stripped):
    """Calculate paren depth change."""
    return line_stripped.count('(') - line_stripped.count(')')

def fix_module(filepath):
    """Fix syntax issues in a module using line-by-line analysis."""
    filename = os.path.basename(filepath)
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    lines = content.split('\n')
    stripped_lines = [strip_strings_and_comments(line) for line in lines]
    
    # Phase 1: Calculate depth at each line
    depth = 0
    paren_depth = 0
    line_depths = []
    
    for sl in stripped_lines:
        # Handle 'do' on same line as 'for/while' - count together
        dc = calc_line_depth_change(sl)
        pc = calc_line_paren_change(sl)
        depth += dc
        paren_depth += pc
        line_depths.append((depth, paren_depth))
    
    if not line_depths:
        return False, "Empty"
    
    final_depth, final_paren = line_depths[-1]
    
    if final_depth == 0 and final_paren == 0:
        return False, "OK"
    
    print(f"  {filename}: depth={final_depth} paren={final_paren}")
    
    # Phase 2: Remove orphaned 'end' statements
    # Find 'end' lines where depth goes negative (extra end)
    if final_depth < 0:
        excess = -final_depth
        removed = 0
        new_lines = []
        new_stripped = []
        
        for i, (line, sl) in enumerate(zip(lines, stripped_lines)):
            stripped = sl.strip()
            
            if removed < excess and stripped == 'end':
                # Check: does removing this 'end' help?
                # Find the 'end' token position
                end_matches = list(re.finditer(r'\bend\b', sl))
                if end_matches:
                    # Remove this line (it's an orphaned end)
                    removed += 1
                    continue  # Skip this line
            
            new_lines.append(line)
            new_stripped.append(sl)
        
        lines = new_lines
        stripped_lines = new_stripped
        print(f"    Removed {removed} orphaned 'end' statements")
    
    # Phase 3: Fix paren imbalance
    # Re-analyze after removing ends
    depth = 0
    paren_depth = 0
    for sl in stripped_lines:
        depth += calc_line_depth_change(sl)
        paren_depth += calc_line_paren_change(sl)
    
    if paren_depth > 0:
        # Missing closing parens - add them at the end
        print(f"    Adding {paren_depth} missing closing parens")
        for _ in range(paren_depth):
            lines.append(')')
    elif paren_depth < 0:
        # Extra closing parens - remove from bottom
        excess_p = -paren_depth
        for i in range(len(lines) - 1, -1, -1):
            if excess_p <= 0:
                break
            if lines[i].rstrip().endswith(')'):
                lines[i] = lines[i].rstrip()[:-1]
                excess_p -= 1
        print(f"    Removed {-paren_depth} excess closing parens")
    
    new_content = '\n'.join(lines)
    
    # Verify
    new_stripped_content = strip_strings_and_comments(new_content)
    d2 = 0; p2 = 0
    for m in re.finditer(r'\b(function|if|for|while|do|repeat|end|until)\b', new_stripped_content):
        w = m.group()
        if w in ('end', 'until'): d2 -= 1
        elif w == 'do':
            before = new_stripped_content[:m.start()].rstrip()
            if not re.search(r'\b(for|while)\s', before): d2 += 1
        elif w == 'repeat': d2 += 1
        else: d2 += 1
    for ch in new_stripped_content:
        if ch == '(': p2 += 1
        elif ch == ')': p2 -= 1
    
    if d2 == 0 and p2 == 0:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"    -> FIXED!")
        return True, "Fixed"
    else:
        print(f"    -> Still broken: depth={d2} paren={p2}")
        return False, f"depth={d2} paren={p2}"


# ============================================================
print("=== BloxStrike Module Syntax Fixer v3 ===\n")

fixed = 0
ok = 0
fail = 0

for filename in sorted(os.listdir(MODULES_DIR)):
    if not filename.endswith('.lua'):
        continue
    filepath = os.path.join(MODULES_DIR, filename)
    success, msg = fix_module(filepath)
    if success: fixed += 1
    elif msg == "OK": ok += 1
    else: fail += 1

print(f"\n=== Results: {ok} OK, {fixed} fixed, {fail} failed ===")
