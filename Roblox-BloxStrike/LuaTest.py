#!/usr/bin/env python3
"""
BloxStrike Lua Test Suite v3.1
外掛腳本專屬的 Lua 語法 + 結構測試工具
專注在真正會導致編譯/執行錯誤的問題
"""
import os, re, sys
from dataclasses import dataclass, field
from typing import List

class C:
    R = "\033[0m"; RED = "\033[91m"; GRN = "\033[92m"; YLW = "\033[93m"
    BLU = "\033[94m"; CYN = "\033[96m"; BLD = "\033[1m"; DIM = "\033[2m"
    GRAY = "\033[90m"

@dataclass
class Result:
    line: int; severity: str; category: str; message: str
    fixable: bool = False; hint: str = ""

@dataclass
class Report:
    filename: str; total_lines: int = 0; total_bytes: int = 0
    results: List[Result] = field(default_factory=list)
    @property
    def errors(self): return [r for r in self.results if r.severity == "ERROR"]
    @property
    def warnings(self): return [r for r in self.results if r.severity == "WARN"]
    @property
    def infos(self): return [r for r in self.results if r.severity == "INFO"]
    @property
    def passed(self): return len(self.errors) == 0

def strip_line(line):
    """Remove strings THEN comments from a line (order matters!)"""
    # Step 1: Remove strings FIRST (before comments)
    # This prevents --- inside strings from being treated as comments
    code = re.sub(r'"(?:[^"\\]|\\.)*"', '""', line)
    code = re.sub(r"'(?:[^'\\]|\\.)*'", "''", code)
    code = re.sub(r'\[\[.*?\]\]', '[[]]', code)
    # Step 2: Now remove comments (strings are already gone)
    code = re.sub(r'--[^\n]*$', '', code)
    return code

def count_quotes_outside_strings(line):
    """Count quotes that are NOT inside strings"""
    # Remove all strings first
    cleaned = re.sub(r'"(?:[^"\\]|\\.)*"', '', line)
    cleaned = re.sub(r"'(?:[^'\\]|\\.)*'", '', cleaned)
    cleaned = re.sub(r'\[\[.*?\]\]', '', cleaned)
    # Remove comments
    cleaned = re.sub(r'--[^\n]*$', '', cleaned)
    return cleaned.count("'"), cleaned.count('"')

def check_file(filepath):
    filename = os.path.basename(filepath)
    with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
        raw = f.read()
        lines = raw.split('\n')
    report = Report(filename=filename, total_lines=len(lines), total_bytes=len(raw.encode('utf-8')))

    # === 1. Unicode escapes (REAL COMPILE ERROR) ===
    for i, line in enumerate(lines, 1):
        s = line.strip()
        if s.startswith('--'): continue
        for m in re.findall(r'\\u[0-9A-Fa-f]{4}', line):
            report.results.append(Result(i, "ERROR", "Unicode",
                f"Lua does not support {m} escape", True,
                "Use string.char() or ASCII alternative"))

    # === 2. Unterminated strings (REAL COMPILE ERROR) ===
    for i, line in enumerate(lines, 1):
        s = line.strip()
        if s.startswith('--'): continue
        sq, dq = count_quotes_outside_strings(line)
        if sq % 2 != 0:
            report.results.append(Result(i, "ERROR", "String",
                "Unterminated single quote string", True,
                "Check for missing closing '"))
        if dq % 2 != 0:
            report.results.append(Result(i, "ERROR", "String",
                "Unterminated double quote string", True,
                'Check for missing closing "'))

    # === 3. Orphaned and/or (REAL RUNTIME ERROR) ===
    for i, line in enumerate(lines, 1):
        s = line.strip()
        if s.startswith('--'): continue
        if s in ('and', 'or', 'and,', 'or,'):
            report.results.append(Result(i, "ERROR", "Syntax",
                f"Orphaned '{s}' as standalone statement", True,
                "Remove or wrap in pcall()"))

    # === 4. BS.alive() without nil check ===
    for i, line in enumerate(lines, 1):
        s = line.strip()
        if s.startswith('--'): continue
        if 'BS.alive()' in s and 'BS.alive and' not in s:
            report.results.append(Result(i, "WARN", "Safety",
                "BS.alive() without nil check", True,
                "Use: if BS.alive and BS.alive() then"))

    # === 5. BS.hrp() without nil check ===
    for i, line in enumerate(lines, 1):
        s = line.strip()
        if s.startswith('--'): continue
        if 'BS.hrp()' in s and 'BS.hrp and' not in s:
            report.results.append(Result(i, "WARN", "Safety",
                "BS.hrp() without nil check", True,
                "Use: if BS.hrp and BS.hrp() then"))

    # === 6. BS.hum() without nil check ===
    for i, line in enumerate(lines, 1):
        s = line.strip()
        if s.startswith('--'): continue
        if 'BS.hum()' in s and 'BS.hum and' not in s:
            report.results.append(Result(i, "WARN", "Safety",
                "BS.hum() without nil check", True,
                "Use: if BS.hum and BS.hum() then"))

    # === 7. setfenv/getfenv (EXECUTOR COMPAT) ===
    for i, line in enumerate(lines, 1):
        s = line.strip()
        if s.startswith('--'): continue
        if 'setfenv(' in s:
            report.results.append(Result(i, "WARN", "Compat",
                "setfenv may not work on all executors", False))
        if 'getfenv(' in s:
            report.results.append(Result(i, "WARN", "Compat",
                "getfenv may not work on all executors", False))

    # === 8. Trailing and/or at EOF ===
    for i, line in enumerate(lines, 1):
        s = line.strip()
        if s.startswith('--'): continue
        if re.search(r'\b(and|or)\s*$', s):
            if i >= len(lines):
                report.results.append(Result(i, "ERROR", "Syntax",
                    f"Trailing '{s.split()[-1]}' at end of file", True))

    # === 9. Console flood ===
    prints = sum(1 for l in lines if not l.strip().startswith('--') and 'print(' in l)
    if prints > 30:
        report.results.append(Result(1, "WARN", "Output",
            f"{prints} print() calls - may flood console"))

    return report

def print_report(r, verbose=False):
    status = f"{C.GRN}PASS{C.R}" if r.passed else f"{C.RED}FAIL{C.R}"
    size_kb = r.total_bytes / 1024

    print(f"\n{'─'*55}")
    print(f" {C.BLD}{r.filename}{C.R} [{status}] {r.total_lines}L / {size_kb:.1f}KB")
    print(f"{'─'*55}")

    if r.errors:
        for e in r.errors:
            fix = f" {C.YLW}[FIX]{C.R}" if e.fixable else ""
            print(f"   {C.RED}ERR{C.R} L{e.line:<4} {e.category}: {e.message}{fix}")
            if e.hint and verbose:
                print(f"        {C.GRAY}{e.hint}{C.R}")

    if r.warnings and verbose:
        for w in r.warnings:
            fix = f" {C.YLW}[FIX]{C.R}" if w.fixable else ""
            print(f"   {C.YLW}WRN{C.R} L{w.line:<4} {w.category}: {w.message}{fix}")

    if not r.errors and not r.warnings:
        print(f"   {C.GRN}No issues found{C.R}")

def main():
    args = sys.argv[1:]
    verbose = '-v' in args or '--verbose' in args

    print(f"\n{C.BLD}{C.CYN}{'═'*55}{C.R}")
    print(f"{C.BLD}{C.CYN}  BloxStrike Lua Test Suite v3.1{C.R}")
    print(f"{C.BLD}{C.CYN}{'═'*55}{C.R}")

    script_dir = os.path.dirname(os.path.abspath(__file__))
    modules_dir = os.path.join(script_dir, 'modules')
    all_reports = []

    # Test modules
    if os.path.isdir(modules_dir):
        for f in sorted(os.listdir(modules_dir)):
            if f.endswith('.lua'):
                r = check_file(os.path.join(modules_dir, f))
                all_reports.append(r)
                print_report(r, verbose)

    # Test other files
    for extra in ['BloxStrike_Standalone.lua', 'BloxStrike_Launcher.lua', 'BloxStrike_Test.lua']:
        fp = os.path.join(script_dir, extra)
        if os.path.isfile(fp):
            r = check_file(fp)
            all_reports.append(r)
            print_report(r, verbose)

    # Summary
    te = sum(len(r.errors) for r in all_reports)
    tw = sum(len(r.warnings) for r in all_reports)
    passed = sum(1 for r in all_reports if r.passed)
    total = len(all_reports)
    total_bytes = sum(r.total_bytes for r in all_reports)

    print(f"\n{'═'*55}")
    print(f" SUMMARY")
    print(f"{'═'*55}")
    print(f"  Files:    {total} ({total_bytes/1024:.0f}KB)")
    print(f"  Passed:   {C.GRN}{passed}/{total}{C.R}")
    print(f"  Errors:   {C.RED if te else C.GRN}{te}{C.R} (compile blockers)")
    print(f"  Warnings: {C.YLW if tw else C.GRN}{tw}{C.R} (runtime risks)")

    if te == 0:
        print(f"\n  {C.GRN}{C.BLD}ALL TESTS PASSED - Ready to deploy!{C.R}\n")
    else:
        print(f"\n  {C.RED}{C.BLD}FIX {te} ERRORS BEFORE DEPLOYING{C.R}\n")
        for r in all_reports:
            for e in r.errors:
                print(f"    {C.RED}x{C.R} {r.filename}:{e.line} - {e.message}")

    print()
    return 0 if te == 0 else 1

if __name__ == '__main__':
    sys.exit(main())
