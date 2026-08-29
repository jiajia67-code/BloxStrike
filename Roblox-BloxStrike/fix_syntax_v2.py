#!/usr/bin/env python3
"""Analyze and fix Lua syntax balance in BloxStrike modules."""
import re, os, sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
MODULES_DIR = os.path.join(SCRIPT_DIR, "modules")

def strip_strings_and_comments(code):
    """Remove Lua strings and comments for accurate block counting."""
    result = []
    i = 0
    in_block_comment = False
    
    while i < len(code):
        if in_block_comment:
            idx = code.find(']]', i)
            if idx >= 0:
                i = idx + 2
                in_block_comment = False
            else:
                break
            continue
        
        ch = code[i]
        
        # String literal
        if ch in ('"', "'"):
            quote = ch
            i += 1
            while i < len(code) and code[i] != quote:
                if code[i] == '\\' and i + 1 < len(code):
                    i += 2
                else:
                    i += 1
            i += 1  # skip closing quote
            result.append(' ')
            continue
        
        # Long string [[ ... ]]
        if ch == '[' and i + 1 < len(code) and code[i + 1] == '[':
            idx = code.find(']]', i + 2)
            if idx >= 0:
                i = idx + 2
            else:
                i = len(code)
            result.append(' ')
            continue
        
        # Comment
        if ch == '-' and i + 1 < len(code) and code[i + 1] == '-':
            if i + 3 < len(code) and code[i + 2] == '[' and code[i + 3] == '[':
                in_block_comment = True
                i += 4
            else:
                # Line comment - skip to end of line
                nl = code.find('\n', i)
                if nl >= 0:
                    i = nl + 1
                else:
                    break
            continue
        
        result.append(ch)
        i += 1
    
    return ''.join(result)


def analyze_balance(content):
    """Analyze Lua block/paren/bracket balance."""
    stripped = strip_strings_and_comments(content)
    
    depth = 0
    pd = 0
    bd = 0
    
    for m in re.finditer(r'\b(function|if|for|while|do|repeat|end|until)\b', stripped):
        word = m.group()
        if word in ('end', 'until'):
            depth -= 1
        elif word == 'do':
            before = stripped[:m.start()].rstrip()
            if not re.search(r'\b(for|while)\s', before):
                depth += 1  # Standalone do...end block
        elif word == 'repeat':
            depth += 1
        else:  # function, if, for, while
            depth += 1
    
    for ch in stripped:
        if ch == '(': pd += 1
        elif ch == ')': pd -= 1
        elif ch == '[': bd += 1
        elif ch == ']': bd -= 1
    
    return depth, pd, bd


def fix_orphaned_ends(content, excess):
    """Remove excess 'end' from the bottom of the file."""
    lines = content.split('\n')
    removed = 0
    
    # Go from bottom up, remove lines that are just 'end'
    for i in range(len(lines) - 1, -1, -1):
        if removed >= excess:
            break
        stripped = lines[i].strip()
        if stripped == 'end':
            lines[i] = ''
            removed += 1
        elif stripped == '' or stripped.startswith('--'):
            continue
        else:
            break
    
    return '\n'.join(lines)


def fix_paren_excess(content, excess):
    """Remove excess closing parens from the bottom."""
    lines = content.split('\n')
    removed = 0
    
    for i in range(len(lines) - 1, -1, -1):
        if removed >= excess:
            break
        line = lines[i]
        stripped = line.rstrip()
        if stripped.endswith(')'):
            lines[i] = stripped[:-1]
            removed += 1
    
    return '\n'.join(lines)


# ============================================================
print("=== BloxStrike Module Syntax Analyzer ===\n")

fixed_count = 0
ok_count = 0
fail_count = 0

for filename in sorted(os.listdir(MODULES_DIR)):
    if not filename.endswith('.lua'):
        continue
    
    filepath = os.path.join(MODULES_DIR, filename)
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    depth, pd, bd = analyze_balance(content)
    
    if depth == 0 and pd == 0 and bd == 0:
        ok_count += 1
        continue
    
    print(f"  {filename}: depth={depth} paren={pd} bracket={bd}")
    
    modified = content
    
    # Fix excess 'end'
    if depth < 0:
        print(f"    Removing {-depth} orphaned 'end' statements")
        modified = fix_orphaned_ends(modified, -depth)
    
    # Fix excess parens
    if pd < 0:
        print(f"    Removing {-pd} excess closing parens")
        modified = fix_paren_excess(modified, -pd)
    
    # Verify
    new_depth, new_pd, new_bd = analyze_balance(modified)
    if new_depth == 0 and new_pd == 0 and new_bd == 0:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(modified)
        print(f"    -> FIXED! Now balanced.")
        fixed_count += 1
    else:
        print(f"    -> Still broken: depth={new_depth} paren={new_pd}")
        fail_count += 1

print(f"\n=== Results: {ok_count} OK, {fixed_count} fixed, {fail_count} failed ===")
