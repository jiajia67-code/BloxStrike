#!/usr/bin/env python3
"""
BloxStrike Lua Test Suite v2.0
外掛腳本專屬的 Lua 語法 + 結構測試工具
"""
import os, re, sys
from dataclasses import dataclass, field
from typing import List

class C:
    R = "\033[0m"; RED = "\033[91m"; GRN = "\033[92m"; YLW = "\033[93m"
    BLU = "\033[94m"; CYN = "\033[96m"; BLD = "\033[1m"; DIM = "\033[2m"

@dataclass
class Result:
    line: int; severity: str; category: str; message: str
    fixable: bool = False

@dataclass
class Report:
    filename: str; total_lines: int = 0
    results: List[Result] = field(default_factory=list)
    @property
    def errors(self): return [r for r in self.results if r.severity == "ERROR"]
    @property
    def warnings(self): return [r for r in self.results if r.severity == "WARN"]
    @property
    def passed(self): return len(self.errors) == 0

def strip_strings_and_comments(line):
    """Remove strings and comments from a line for code analysis"""
    # Remove inline comments
    code = re.sub(r'--[^\n]*$', '', line)
    # Remove double-quoted strings (handle escaped quotes)
    code = re.sub(r'"(?:[^"\\]|\\.)*"', '""', code)
    # Remove single-quoted strings (handle escaped quotes)
    code = re.sub(r"'(?:[^'\\]|\\.)*'", "''", code)
    # Remove [[ ]] strings (multiline)
    code = re.sub(r'\[\[.*?\]\]', '[[]]', code)
    return code

def check_file(filepath):
    filename = os.path.basename(filepath)
    with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
        lines = f.readlines()
    report = Report(filename=filename, total_lines=len(lines))
    
    # === 1. Unicode escapes ===
    for i, line in enumerate(lines, 1):
        s = line.strip()
        if s.startswith('--'): continue
        for m in re.findall(r'\\u[0-9A-Fa-f]{4}', line):
            report.results.append(Result(i, "ERROR", "Unicode",
                f"Lua does not support {m} - use string.char() or ASCII", True))
    
    # === 2. Block balance ===
    depth = 0
    for i, line in enumerate(lines, 1):
        s = line.strip()
        if s.startswith('--'): continue
        code = strip_strings_and_comments(s)
        # Count openers (but not after . like :Wait() or table.func)
        openers = len(re.findall(r'(?<![.\w])(?:function|if|for|while|do)\b', code))
        ends = len(re.findall(r'\bend\b', code))
        depth += openers - ends
    if depth > 0:
        report.results.append(Result(report.total_lines, "ERROR", "Block",
            f"Missing {depth} 'end' keyword(s)", False))
    elif depth < 0:
        report.results.append(Result(1, "ERROR", "Block",
            f"{abs(depth)} extra 'end' keyword(s)", False))
    
    # === 3. Unterminated strings ===
    for i, line in enumerate(lines, 1):
        s = line.strip()
        if s.startswith('--'): continue
        code = strip_strings_and_comments(line)
        # After removing strings, count remaining quotes
        sq = code.count("'")
        dq = code.count('"')
        if sq % 2 != 0:
            report.results.append(Result(i, "ERROR", "String",
                "Unterminated single quote", True))
        if dq % 2 != 0:
            report.results.append(Result(i, "ERROR", "String",
                "Unterminated double quote", True))
    
    # === 4. Orphaned keywords ===
    for i, line in enumerate(lines, 1):
        s = line.strip()
        if s.startswith('--'): continue
        if s in ('and', 'or'):
            report.results.append(Result(i, "ERROR", "Syntax",
                f"Orphaned '{s}' as standalone statement", True))
    
    # === 5. Trailing and/or (likely continuation issue) ===
    for i, line in enumerate(lines, 1):
        s = line.strip()
        if s.startswith('--'): continue
        if re.search(r'\b(and|or)\s*$', s):
            # Check if next line continues the expression
            if i < len(lines):
                next_s = lines[i].strip()
                if next_s.startswith('--') or not next_s:
                    report.results.append(Result(i, "WARN", "Syntax",
                        f"Trailing '{s}' with no continuation", False))
    
    # === 6. BS.alive() without nil check ===
    for i, line in enumerate(lines, 1):
        s = line.strip()
        if s.startswith('--'): continue
        if 'BS.alive()' in s and 'BS.alive and' not in s:
            report.results.append(Result(i, "WARN", "Safety",
                "BS.alive() without nil check", True))
    
    # === 7. Unicode escape in strings ===
    for i, line in enumerate(lines, 1):
        s = line.strip()
        if s.startswith('--'): continue
        if re.search(r'"[^"]*\\u[0-9A-Fa-f]{4}[^"]*"', line):
            report.results.append(Result(i, "ERROR", "Escape",
                "Unicode escape in double-quoted string", True))
        if re.search(r"'[^']*\\u[0-9A-Fa-f]{4}[^']*'", line):
            report.results.append(Result(i, "ERROR", "Escape",
                "Unicode escape in single-quoted string", True))
    
    # === 8. Console flood ===
    prints = sum(1 for l in lines if not l.strip().startswith('--') and 'print(' in l)
    if prints > 30:
        report.results.append(Result(1, "WARN", "Output",
            f"{prints} print statements - may flood console"))
    
    return report

def print_report(r):
    status = f"{C.GRN}PASS{C.R}" if r.passed else f"{C.RED}FAIL{C.R}"
    print(f"\n{'='*55}")
    print(f" {C.BLD}{r.filename}{C.R} [{status}] ({r.total_lines} lines)")
    print(f"{'='*55}")
    
    if r.errors:
        print(f"\n {C.RED}ERRORS ({len(r.errors)}):{C.R}")
        for e in r.errors:
            fix = f" {C.YLW}[FIXABLE]{C.R}" if e.fixable else ""
            print(f"   L{e.line:>4} | {C.RED}{e.category}{C.R}: {e.message}{fix}")
    if r.warnings:
        print(f"\n {C.YLW}WARNINGS ({len(r.warnings)}):{C.R}")
        for w in r.warnings:
            fix = f" {C.YLW}[FIXABLE]{C.R}" if w.fixable else ""
            print(f"   L{w.line:>4} | {C.YLW}{w.category}{C.R}: {w.message}{fix}")
    if not r.errors and not r.warnings:
        print(f"\n {C.GRN}No issues found!{C.R}")

def main():
    args = sys.argv[1:]
    verbose = '-v' in args
    
    print(f"\n{C.BLD}{C.CYN}{'='*55}{C.R}")
    print(f"{C.BLD}{C.CYN}  BloxStrike Lua Test Suite v2.0{C.R}")
    print(f"{C.BLD}{C.CYN}{'='*55}{C.R}")
    
    script_dir = os.path.dirname(os.path.abspath(__file__))
    modules_dir = os.path.join(script_dir, 'modules')
    all_reports = []
    
    # Test modules
    if os.path.isdir(modules_dir):
        for f in sorted(os.listdir(modules_dir)):
            if f.endswith('.lua'):
                r = check_file(os.path.join(modules_dir, f))
                all_reports.append(r)
                print_report(r)
    
    # Test Standalone
    standalone = os.path.join(script_dir, 'BloxStrike_Standalone.lua')
    if os.path.isfile(standalone):
        r = check_file(standalone)
        all_reports.append(r)
        print_report(r)
    
    # Summary
    te = sum(len(r.errors) for r in all_reports)
    tw = sum(len(r.warnings) for r in all_reports)
    passed = sum(1 for r in all_reports if r.passed)
    total = len(all_reports)
    
    print(f"\n{'='*55}")
    print(f" SUMMARY")
    print(f"{'='*55}")
    print(f"  Files: {total}  Passed: {C.GRN}{passed}/{total}{C.R}")
    print(f"  Errors: {C.RED if te else C.GRN}{te}{C.R}  Warnings: {C.YLW if tw else C.GRN}{tw}{C.R}")
    
    if te == 0:
        print(f"\n  {C.GRN}{C.BLD}ALL TESTS PASSED!{C.R}\n")
    else:
        print(f"\n  {C.RED}{C.BLD}FIX {te} ERRORS BEFORE DEPLOYING!{C.R}\n")
    return 0 if te == 0 else 1

if __name__ == '__main__':
    sys.exit(main())
