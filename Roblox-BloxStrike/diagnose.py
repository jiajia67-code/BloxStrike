#!/usr/bin/env python3
"""Find orphaned blocks in specific modules."""
import re, os, sys

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
        if ch == '[' and i + 1 < len(code) and code[i + 1] == '[':
            idx = code.find(']]', i + 2)
            if idx >= 0:
                i = idx + 2
            else:
                i = len(code)
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
    
    depth = 0
    for i, line in enumerate(lines, 1):
        stripped = strip_sc(line)
        for m in re.finditer(r'\b(function|if|for|while|do|repeat|end|until)\b', stripped):
            w = m.group()
            if w in ('end', 'until'):
                depth -= 1
            elif w == 'do':
                before = stripped[:m.start()].rstrip()
                if not re.search(r'\b(for|while)\s', before):
                    depth += 1
            elif w == 'repeat':
                depth += 1
            else:
                depth += 1
        
        if depth < 0:
            print(f"  FIRST ORPHAN at line {i}, depth={depth}: {line.rstrip()[:100]}")
            # Show context
            start = max(0, i - 5)
            for j in range(start, min(len(lines), i + 3)):
                marker = ">>>" if j == i - 1 else "   "
                print(f"    {marker} {j+1}: {lines[j].rstrip()[:100]}")
            break
    
    print(f"  Final depth: {depth}")

for name in ['bypass.lua', 'stealth.lua']:
    filepath = os.path.join(MODULES_DIR, name)
    print(f"\n=== {name} ===")
    analyze_file(filepath)
