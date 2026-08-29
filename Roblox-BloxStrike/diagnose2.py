#!/usr/bin/env python3
"""Find missing end statements in specific modules."""
import re, os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
MODULES_DIR = os.path.join(SCRIPT_DIR, "modules")

def strip_sc(code):
    result = []
    i = 0
    in_bc = False
    while i < len(code):
        if in_bc:
            idx = code.find(']]', i)
            if idx >= 0:
                i = idx + 2
                in_bc = False
            else:
                break
            continue
        ch = code[i]
        if ch in ('"', "'"):
            q = ch
            i += 1
            while i < len(code) and code[i] != q:
                if code[i] == '\\' and i + 1 < len(code):
                    i += 2
                else:
                    i += 1
            i += 1
            result.append(' ')
            continue
        if ch == '-' and i + 1 < len(code) and code[i + 1] == '-':
            if i + 3 < len(code) and code[i + 2] == '[' and code[i + 3] == '[':
                in_bc = True
                i += 4
            else:
                nl = code.find('\n', i)
                i = nl + 1 if nl >= 0 else len(code)
            continue
        result.append(ch)
        i += 1
    return ''.join(result)

def analyze_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    filename = os.path.basename(filepath)
    depth = 0
    max_depth = 0
    max_depth_line = 0
    depth_history = []
    
    for i, line in enumerate(lines, 1):
        stripped = strip_sc(line)
        change = 0
        for m in re.finditer(r'\b(function|if|for|while|do|repeat|end|until)\b', stripped):
            w = m.group()
            if w in ('end', 'until'):
                change -= 1
            elif w == 'do':
                before = stripped[:m.start()].rstrip()
                if not re.search(r'\b(for|while)\s', before):
                    change += 1
            elif w == 'repeat':
                change += 1
            else:
                change += 1
        
        depth += change
        depth_history.append(depth)
        
        if depth > max_depth:
            max_depth = depth
            max_depth_line = i
    
    print(f"  {filename}: final_depth={depth}, max_depth={max_depth} at line {max_depth_line}")
    
    if depth > 0:
        # Find lines where depth was highest - these are likely the unclosed blocks
        # Show all lines at max depth
        print(f"  Lines at max depth ({max_depth}):")
        for i, d in enumerate(depth_history):
            if d == max_depth:
                print(f"    line {i+1}: {lines[i].rstrip()[:100]}")

for name in ['bypass.lua', 'stealth.lua']:
    filepath = os.path.join(MODULES_DIR, name)
    print(f"\n=== {name} ===")
    analyze_file(filepath)
