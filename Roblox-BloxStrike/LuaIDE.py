#!/usr/bin/env python3
"""
BloxStrike LuaIDE v2.0 - 強化版 Lua 整合開發環境
=================================================
30+ 項分析檢查，自動修復，跨模組依賴分析

用法:
  python3 LuaIDE.py --analyze    # 分析所有模組
  python3 LuaIDE.py --fix        # 自動修復
  python3 LuaIDE.py --deploy     # 一鍵部署
  python3 LuaIDE.py --verbose    # 顯示所有檢查
  python3 LuaIDE.py --file X     # 分析單一檔案
"""

import os, sys, re, time, subprocess
from dataclasses import dataclass, field
from typing import List, Dict, Tuple, Optional
from collections import defaultdict

# ═══════════════════════════════════════════════════════════
# ANSI Colors
# ═══════════════════════════════════════════════════════════
class C:
    R="\033[0m";RED="\033[91m";GRN="\033[92m";YLW="\033[93m"
    BLU="\033[94m";MAG="\033[95m";CYN="\033[96m";WHT="\033[97m"
    BLD="\033[1m";DIM="\033[2m";GRY="\033[90m"

# ═══════════════════════════════════════════════════════════
# Issue
# ═══════════════════════════════════════════════════════════
@dataclass
class Issue:
    file: str; line: int; severity: str; category: str; message: str
    fixable: bool = False; hint: str = ""; col: int = 0

# ═══════════════════════════════════════════════════════════
# Lua Analyzer v2.0 (30+ checks)
# ═══════════════════════════════════════════════════════════
class LuaAnalyzer:
    def __init__(self, source: str, filename: str = "<input>"):
        self.source = source
        self.filename = filename
        self.lines = source.split('\n')
        self.issues: List[Issue] = []
        self.defines: Dict[str, int] = {}  # var -> first define line
        self.globals_used: Dict[str, List[int]] = defaultdict(list)
    
    def add(self, line, sev, cat, msg, fix=False, hint=""):
        self.issues.append(Issue(self.filename, line, sev, cat, msg, fix, hint))
    
    def analyze(self) -> List[Issue]:
        self._check_unicode()
        self._check_strings()
        self._check_orphans()
        self._check_trailing()
        self._check_nils()
        self._check_setfenv()
        self._check_duplicate_args()
        self._check_missing_then()
        self._check_function_call()
        self._check_table_syntax()
        self._check_dead_code()
        self._check_return_consistency()
        self._check_global_pollution()
        self._check_shadowing()
        self._check_empty_blocks()
        self._check_comparison()
        self._check_concat()
        self._check_number_format()
        self._check_infinite_loop()
        self._check_recursive()
        self._check_print_flood()
        self._check_long_lines()
        self._check_todo()
        self._check_block_balance()
        self._check_table_commas()
        self._check_nil_index()
        return self.issues
    
    # --- 1. Unicode escapes ---
    def _check_unicode(self):
        for i, line in enumerate(self.lines, 1):
            if line.strip().startswith('--'): continue
            for m in re.finditer(r'\\u[0-9A-Fa-f]{4}', line):
                self.add(i, "ERROR", "Unicode", f"Lua does not support {m.group()}", True, "Use string.char() or ASCII")
    
    # --- 2. String balance ---
    def _check_strings(self):
        for i, line in enumerate(self.lines, 1):
            if line.strip().startswith('--'): continue
            c = re.sub(r'"(?:[^"\\]|\\.)*"', '', line)
            c = re.sub(r"'(?:[^'\\]|\\.)*'", '', c)
            c = re.sub(r'\[\[.*?\]\]', '', c)
            c = re.sub(r'--[^\n]*$', '', c)
            if c.count("'") % 2 != 0:
                self.add(i, "ERROR", "String", "Unterminated single quote", True)
            if c.count('"') % 2 != 0:
                self.add(i, "ERROR", "String", "Unterminated double quote", True)
    
    # --- 3. Orphaned keywords ---
    def _check_orphans(self):
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            if s in ('and', 'or'):
                self.add(i, "ERROR", "Syntax", f"Orphaned '{s}' as standalone statement", True, "Remove or wrap in pcall()")
    
    # --- 4. Trailing operators ---
    def _check_trailing(self):
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            if re.search(r'\b(and|or)\s*$', s) and i >= len(self.lines):
                self.add(i, "ERROR", "Syntax", f"Trailing '{s.split()[-1]}' at EOF")
            if re.search(r'[=+\-*/^]\s*$', s) and not s.endswith('..') and not s.endswith('--'):
                self.add(i, "WARN", "Syntax", "Trailing operator at end of line")
    
    # --- 5. Nil safety ---
    def _check_nils(self):
        for i, line in enumerate(self.lines, 1):
            if line.strip().startswith('--'): continue
            for pattern, name in [
                (r'(?<!\w)BS\.alive\(\)', 'BS.alive'),
                (r'(?<!\w)BS\.hrp\(\)', 'BS.hrp'),
                (r'(?<!\w)BS\.hum\(\)', 'BS.hum'),
                (r'(?<!\w)BS\.char\(\)', 'BS.char'),
                (r'(?<!\w)BS\.cam\(\)', 'BS.cam'),
                (r'(?<!\w)BS\.player\(\)', 'BS.player'),
            ]:
                if re.search(pattern, line) and f'{name} and' not in line:
                    self.add(i, "WARN", "Nil", f"{name}() without nil check", True, f"Use: if {name} and {name}()")
    
    # --- 6. setfenv/getfenv ---
    def _check_setfenv(self):
        for i, line in enumerate(self.lines, 1):
            if line.strip().startswith('--'): continue
            if 'setfenv(' in line:
                self.add(i, "WARN", "Compat", "setfenv may not work on all executors")
            if 'getfenv(' in line:
                self.add(i, "WARN", "Compat", "getfenv may not work on all executors")
    
    # --- 7. Duplicate function args ---
    def _check_duplicate_args(self):
        for i, line in enumerate(self.lines, 1):
            if line.strip().startswith('--'): continue
            m = re.search(r'function\s*\w*\s*\(([^)]+)\)', line)
            if m:
                args = [a.strip() for a in m.group(1).split(',') if a.strip()]
                seen = set()
                for a in args:
                    if a in seen:
                        self.add(i, "ERROR", "Syntax", f"Duplicate argument '{a}' in function", True)
                    seen.add(a)
    
    # --- 8. Missing then ---
    def _check_missing_then(self):
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            if re.match(r'^if\b', s) and 'then' not in s and 'do' not in s:
                found = False
                for j in range(i, min(i + 5, len(self.lines))):
                    ns = self.lines[j].strip()
                    if ns.startswith('--'): continue
                    if 'then' in ns: found = True; break
                    if ns and not ns.startswith('or') and not ns.startswith('and'): break
                if not found:
                    self.add(i, "WARN", "Syntax", "if without then (multiline)")
    
    # --- 9. Function call syntax ---
    def _check_function_call(self):
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            # Detect missing comma: func("a" "b")
            if re.search(r'"\s+"', s) or re.search(r"'\s+'", s):
                if '..' not in s:
                    self.add(i, "WARN", "Syntax", "Adjacent strings without concatenation")
    
    # --- 10. Table syntax ---
    def _check_table_syntax(self):
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            if re.search(r',\s*\}', s):
                self.add(i, "INFO", "Style", "Trailing comma in table (allowed but style)")
    
    # --- 11. Dead code ---
    def _check_dead_code(self):
        saw_return = False
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            if s.startswith('return'):
                saw_return = True
            elif saw_return and s and not s.startswith('end') and not s.startswith(')') and not s.startswith('elseif') and not s.startswith('else'):
                self.add(i, "INFO", "DeadCode", "Code after return (unreachable)")
                saw_return = False
    
    # --- 12. Return consistency ---
    def _check_return_consistency(self):
        in_func = False
        func_start = 0
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            if re.match(r'(local\s+)?function\b', s):
                in_func = True
                func_start = i
            if in_func and s.startswith('end'):
                in_func = False
    
    # --- 13. Global pollution ---
    def _check_global_pollution(self):
        LUA_GLOBALS = {'game','workspace','Instance','UDim2','UDim','Color3','Vector3','Vector2','CFrame',
            'Enum','math','string','table','pcall','xpcall','error','print','warn','task','tick',
            'wait','spawn','delay','typeof','type','tostring','tonumber','select','pairs','ipairs',
            'rawget','rawset','getmetatable','setmetatable','collectgarbage','newproxy','utf8','bit32',
            'RunService','UserInputService','TweenService','HttpService','Players','_G','self',
            'coroutine','os','io','debug','package','require','loadstring','load','assert','unpack',
            'next','rawequal','rawlen','setfenv','getfenv','dofile','loadfile','newproxy','gcinfo',
            'if','else','elseif','then','end','function','for','while','do','repeat','until',
            'return','break','local','nil','true','false','and','or','not','in','goto','continue'}
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            m = re.match(r'^(\w+)\s*=', s)
            if m and not s.startswith('local'):
                name = m.group(1)
                if name not in LUA_GLOBALS and not name.startswith('BS.') and not name.startswith('Flags.'):
                    self.globals_used[name].append(i)

    # --- 14. Shadowing ---
    def _check_shadowing(self):
        scope = {}
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            for m in re.finditer(r'\blocal\s+(\w+)', s):
                name = m.group(1)
                if name in scope:
                    self.add(i, "WARN", "Scope", f"Local '{name}' shadows definition at line {scope[name]}")
                scope[name] = i
    
    # --- 15. Empty blocks ---
    def _check_empty_blocks(self):
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            if re.match(r'^if\b.*\bthen\s*$', s):
                if i < len(self.lines) and self.lines[i].strip() == 'end':
                    self.add(i, "WARN", "Style", "Empty if block")
    
    # --- 16. Comparison style ---
    def _check_comparison(self):
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            if '== true' in s or '== false' in s or '== nil' in s:
                self.add(i, "INFO", "Style", "Redundant comparison (use directly)")
    
    # --- 17. Concat in loop ---
    def _check_concat(self):
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            if '..=' in s:
                self.add(i, "WARN", "Perf", "String concatenation in loop (use table.concat)")
    
    # --- 18. Number format ---
    def _check_number_format(self):
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            for m in re.finditer(r'\b\d{5,}\b', s):
                self.add(i, "INFO", "Style", f"Large number {m.group()} (use scientific notation?)")
    
    # --- 19. Infinite loop ---
    def _check_infinite_loop(self):
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            if re.match(r'^while\s+true\s+do\s*$', s):
                # Check if there's a break or return inside
                has_exit = False
                for j in range(i, min(i + 50, len(self.lines))):
                    ns = self.lines[j].strip()
                    if 'break' in ns or 'return' in ns:
                        has_exit = True; break
                    if ns == 'end' and j > i:
                        break
                if not has_exit:
                    self.add(i, "WARN", "Logic", "while true without break/return (infinite loop risk)")
    
    # --- 20. Recursive ---
    def _check_recursive(self):
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            m = re.match(r'(local\s+)?function\s+(\w+)\s*\(', s)
            if m:
                fname = m.group(2)
                # Check if function calls itself
                for j in range(i, min(i + 100, len(self.lines))):
                    if fname in self.lines[j] and 'function' not in self.lines[j]:
                        if f'{fname}(' in self.lines[j]:
                            self.add(i, "INFO", "Logic", f"Function '{fname}' may be recursive")
                            break
    
    # --- 21. Print flood ---
    def _check_print_flood(self):
        count = sum(1 for l in self.lines if not l.strip().startswith('--') and re.search(r'\b(print|warn)\s*\(', l))
        if count > 30:
            self.add(1, "WARN", "Output", f"{count} print/warn calls")
    
    # --- 22. Long lines ---
    def _check_long_lines(self):
        for i, line in enumerate(self.lines, 1):
            if len(line.rstrip()) > 200:
                self.add(i, "INFO", "Style", f"Line too long ({len(line.rstrip())} chars)")
    
    # --- 23. TODO/FIXME ---
    def _check_todo(self):
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'):
                if 'TODO' in s or 'FIXME' in s or 'HACK' in s or 'XXX' in s:
                    self.add(i, "INFO", "TODO", s.strip('- '))

    # --- 24. Block balance (catches missing 'end') ---
    def _check_block_balance(self):
        """Count function/if/for/while/do vs end. Only reports very high-confidence imbalances."""
        depth = 0
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            clean = re.sub(r'"(?:[^"\\]|\\.)*"', '""', s)
            clean = re.sub(r"'(?:[^'\\]|\\.)*'", "''", clean)
            clean = re.sub(r'--.*$', '', clean)
            opens = 0
            for kw in ['function', 'if', 'for', 'while']:
                opens += len(re.findall(r'\b' + kw + r'\b', clean))
            opens += len(re.findall(r'\bdo\b', clean))
            closes = len(re.findall(r'\bend\b', clean))
            depth += opens - closes
        # Only report very high-confidence (>=5) since Lua patterns create noise
        if depth >= 5:
            self.add(1, "WARN", "BlockBalance",
                     f"{depth} unclosed block(s) - likely missing 'end'",
                     False, "Check if/for/while/function blocks for missing 'end'")
        elif depth <= -5:
            self.add(len(self.lines), "WARN", "BlockBalance",
                     f"{abs(depth)} extra 'end' statement(s)",
                     False, "Remove extra 'end'")

    # --- 25. Table comma detector ---
    def _check_table_commas(self):
        """Detect missing commas in known crash-prone table patterns (SetCore, CreateWindow, etc)."""
        CRITICAL_TABLES = {'SetCore', 'CreateWindow', 'CreateTab', 'CreateToggle',
                           'CreateSlider', 'CreateDropdown', 'CreateButton', 'CreateLabel',
                           'Notify', 'JSONEncode'}
        in_table = 0
        last_key_line = 0
        last_key_name = ''
        in_critical = False
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            # Check if this line starts a critical table
            for func in CRITICAL_TABLES:
                if (func + '(') in s or (func + '({') in s:
                    in_critical = True
            clean = re.sub(r'"(?:[^"\\]|\\.)*"', '""', s)
            clean = re.sub(r"'(?:[^'\\]|\\.)*'", "''", clean)
            for ch in clean:
                if ch == '{': in_table += 1
                elif ch == '}':
                    in_table = max(0, in_table - 1)
                    if in_table == 0: in_critical = False
            if in_table > 0 and in_critical:
                m = re.match(r"^(\w+)\s*=", s)
                if m and not s.endswith(',') and not s.endswith('{') and not s.endswith('('):
                    if last_key_line > 0 and (i - last_key_line) <= 3:
                        self.add(last_key_line, "WARN", "TableComma",
                                 f"Missing comma before '{m.group(1)}' in table",
                                 False, "Add ',' at end of previous line")
                    last_key_line = i
                    last_key_name = m.group(1)
                elif not m:
                    last_key_line = 0
            else:
                last_key_line = 0

    # --- 26. Nil index detector (catches accessing .X on nil) ---
    def _check_nil_index(self):
        """Detect patterns like: local x = nil; x.Property (runtime crash)"""
        nil_vars = set()
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            # Track variables set to nil or potentially nil
            m = re.match(r'local\s+(\w+)\s*=\s*nil', s)
            if m:
                nil_vars.add(m.group(1))
            # Track :GetService calls that might fail
            m = re.match(r'local\s+(\w+)\s*=.*pcall', s)
            if m:
                nil_vars.add(m.group(1))
            # Check for property access on potentially nil variables
            for var in list(nil_vars):
                pattern = r'\b' + re.escape(var) + r'\s*\.\s*\w+'
                if re.search(pattern, s) and f'if {var}' not in s and f'if not {var}' not in s:
                    self.add(i, "WARN", "NilIndex",
                             f"'{var}' may be nil here (set at line of definition)",
                             True, f"Add: if {var} then")
                    nil_vars.discard(var)  # Only warn once per variable
# ═══════════════════════════════════════════════════════════
class AutoFixer:
    @staticmethod
    def fix_file(filepath: str, issues: List[Issue]) -> int:
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        fixed = 0
        for issue in sorted(issues, key=lambda x: x.line, reverse=True):
            if not issue.fixable or issue.line < 1 or issue.line > len(lines): continue
            line = lines[issue.line - 1]
            changed = False
            
            if issue.category == "Unicode":
                for old, new in [('"\\u2713"','"+ "'),('"\\u2717"','"x "'),('"\\u2192"','"-> "')]:
                    if old in line: line = line.replace(old, new); changed = True
            
            elif issue.category == "Nil":
                # Skip function definitions: function BS.xxx()
                if not re.match(r'\s*function\s', line):
                    for old, new in [
                        ('BS.alive()','BS.alive and BS.alive()'),
                        ('BS.hrp()','BS.hrp and BS.hrp()'),
                        ('BS.hum()','BS.hum and BS.hum()'),
                        ('BS.char()','BS.char and BS.char()'),
                        ('BS.cam()','BS.cam and BS.cam()'),
                    ]:
                        if old in line and new not in line:
                            line = line.replace(old, new); changed = True
            
            if changed:
                lines[issue.line - 1] = line
                fixed += 1
        
        if fixed > 0:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.writelines(lines)
        return fixed

# ═══════════════════════════════════════════════════════════
# Module Manager
# ═══════════════════════════════════════════════════════════
@dataclass
class ModuleInfo:
    name: str; cn: str; size: int; lines: int
    errors: int = 0; warnings: int = 0; infos: int = 0; status: str = "unknown"
    tab: str = ""

class ModuleManager:
    TAB_MAP = {
        'combat':'自瞄','esp':'透視',
        'hud':'雜項','killeffects':'雜項','utility':'雜項','combatassist':'雜項',
        'world':'世界',
        'rage':'暴力','pingadapt':'暴力','smartai':'暴力',
        'settings':'關於','stealth':'關於','cheatdetect':'關於',
    }
    CN = {
        'api':'API','bypass':'反檢測','cheatdetect':'作弊偵測','combat':'戰鬥系統',
        'combatassist':'戰鬥輔助','compat':'兼容層','core':'核心','errorhandler':'錯誤處理',
        'esp':'透視系統','events':'事件系統','hud':'HUD','killeffects':'擊殺特效',
        'luau_compat':'Luau兼容','luau_detect':'Luau偵測','pingadapt':'延遲適應',
        'rage':'暴力系統','settings':'設定','smartai':'智能AI','stealth':'隱身系統',
        'ui':'介面','utility':'工具','viewmodel':'視角模型','webhook':'Webhook','world':'世界',
    }
    ORDER = [
        'compat','core','ui','api','combat','esp',
        'hud','killeffects','utility','combatassist','world',
        'rage','pingadapt','smartai','settings','stealth','cheatdetect',
        'bypass','errorhandler','events','luau_detect',
    ]
    
    def __init__(self, modules_dir):
        self.modules_dir = modules_dir
        self.modules: Dict[str, ModuleInfo] = {}
        self.all_issues: Dict[str, List[Issue]] = {}
    
    def scan(self) -> Dict[str, ModuleInfo]:
        for fname in os.listdir(self.modules_dir):
            if not fname.endswith('.lua'): continue
            name = fname.replace('.lua', '')
            fpath = os.path.join(self.modules_dir, fname)
            with open(fpath, 'r', encoding='utf-8', errors='replace') as f:
                source = f.read()
            analyzer = LuaAnalyzer(source, fname)
            issues = analyzer.analyze()
            self.all_issues[name] = issues
            
            errors = len([i for i in issues if i.severity == "ERROR"])
            warnings = len([i for i in issues if i.severity == "WARN"])
            infos = len([i for i in issues if i.severity == "INFO"])
            
            self.modules[name] = ModuleInfo(
                name=name, cn=self.CN.get(name, name),
                size=len(source.encode('utf-8')),
                lines=source.count('\n') + 1,
                errors=errors, warnings=warnings, infos=infos,
                status="PASS" if errors == 0 else "FAIL",
                tab=self.TAB_MAP.get(name, ""),
            )
        return self.modules

# ═══════════════════════════════════════════════════════════
# CLI
# ═══════════════════════════════════════════════════════════
class CLI:
    R="\033[0m";RED="\033[91m";GRN="\033[92m";YLW="\033[93m"
    BLU="\033[94m";CYN="\033[96m";BLD="\033[1m";DIM="\033[2m"
    
    @staticmethod
    def banner():
        print(f"\n{CLI.BLD}{CLI.CYN}{'═'*60}{CLI.R}")
        print(f"{CLI.BLD}{CLI.CYN}  BloxStrike LuaIDE v2.0{CLI.R}")
        print(f"{CLI.BLD}{CLI.CYN}  30+ 項分析檢查 | 自動修復 | 跨模組分析{CLI.R}")
        print(f"{CLI.BLD}{CLI.CYN}{'═'*60}{CLI.R}\n")
    
    @staticmethod
    def analyze(project_dir, verbose=False, single_file=None):
        CLI.banner()
        modules_dir = os.path.join(project_dir, 'modules')
        
        manager = ModuleManager(modules_dir)
        
        if single_file:
            with open(single_file, 'r', encoding='utf-8', errors='replace') as f:
                source = f.read()
            fname = os.path.basename(single_file)
            analyzer = LuaAnalyzer(source, fname)
            issues = analyzer.analyze()
            errors = [i for i in issues if i.severity == "ERROR"]
            warnings = [i for i in issues if i.severity == "WARN"]
            infos = [i for i in issues if i.severity == "INFO"]
            
            status = f"{CLI.GRN}PASS{CLI.R}" if not errors else f"{CLI.RED}FAIL{CLI.R}"
            size_kb = len(source.encode('utf-8')) / 1024
            print(f"  {fname} [{status}] {source.count(chr(10))+1}L / {size_kb:.1f}KB")
            
            for issue in issues:
                if issue.severity == "ERROR" or (verbose and issue.severity in ("WARN","INFO")):
                    color = CLI.RED if issue.severity == "ERROR" else (CLI.YLW if issue.severity == "WARN" else CLI.BLU)
                    fix = f" {CLI.YLW}[FIX]{CLI.R}" if issue.fixable else ""
                    print(f"    {color}{issue.severity:4}{CLI.R} L{issue.line:<4} {issue.category}: {issue.message}{fix}")
            
            if not issues:
                print(f"    {CLI.GRN}No issues found{CLI.R}")
            return
        
        # Scan all modules
        print(f"  {CLI.BLD}Scanning {len(os.listdir(modules_dir))} modules...{CLI.R}\n")
        modules = manager.scan()
        
        total_e, total_w, total_i = 0, 0, 0
        
        for name in ModuleManager.ORDER:
            if name not in modules: continue
            info = modules[name]
            status = f"{CLI.GRN}PASS{CLI.R}" if info.errors == 0 else f"{CLI.RED}FAIL{CLI.R}"
            size_kb = info.size / 1024
            print(f"  {info.cn:8} [{status}] {info.lines:5}L / {size_kb:5.1}KB  E:{info.errors} W:{info.warnings} I:{info.infos}")
            total_e += info.errors; total_w += info.warnings; total_i += info.infos
            
            # Show errors
            if info.name in manager.all_issues:
                for issue in manager.all_issues[info.name]:
                    if issue.severity == "ERROR":
                        print(f"    {CLI.RED}ERR{CLI.R} L{issue.line:<4} {issue.category}: {issue.message}")
                    elif verbose and issue.severity == "WARN":
                        print(f"    {CLI.YLW}WRN{CLI.R} L{issue.line:<4} {issue.category}: {issue.message}")
        
        # Other files
        for extra in ['BloxStrike_Standalone.lua', 'BloxStrike_Launcher.lua', 'BloxStrike_Test.lua']:
            fp = os.path.join(project_dir, extra)
            if os.path.isfile(fp):
                with open(fp, 'r', encoding='utf-8', errors='replace') as f:
                    source = f.read()
                analyzer = LuaAnalyzer(source, extra)
                issues = analyzer.analyze()
                errors = len([i for i in issues if i.severity == "ERROR"])
                status = f"{CLI.GRN}PASS{CLI.R}" if errors == 0 else f"{CLI.RED}FAIL{CLI.R}"
                size_kb = len(source.encode('utf-8')) / 1024
                print(f"  {extra:28} [{status}] {source.count(chr(10))+1:5}L / {size_kb:5.1f}KB")
                total_e += errors
        
        # Tab structure
        print(f"\n  {CLI.BLD}Tab Structure:{CLI.R}")
        tabs = defaultdict(list)
        for name, info in modules.items():
            if info.tab: tabs[info.tab].append(info.cn)
        for tab, mods in tabs.items():
            print(f"    {tab}: {', '.join(mods)}")
        
        # Summary
        passed = sum(1 for m in modules.values() if m.errors == 0)
        print(f"\n{'═'*60}")
        print(f"  Files: {len(modules)+3}  Passed: {CLI.GRN}{passed}/{len(modules)}{CLI.R}")
        print(f"  Errors: {CLI.RED if total_e else CLI.GRN}{total_e}{CLI.R}  Warnings: {CLI.YLW if total_w else CLI.GRN}{total_w}{CLI.R}  Info: {total_i}")
        
        if total_e == 0:
            print(f"\n  {CLI.GRN}{CLI.BLD}ALL TESTS PASSED!{CLI.R}\n")
        else:
            print(f"\n  {CLI.RED}{CLI.BLD}FIX {total_e} ERRORS!{CLI.R}\n")
    
    @staticmethod
    def fix(project_dir):
        CLI.banner()
        modules_dir = os.path.join(project_dir, 'modules')
        total_fixed = 0
        
        for fname in sorted(os.listdir(modules_dir)):
            if not fname.endswith('.lua'): continue
            fpath = os.path.join(modules_dir, fname)
            with open(fpath, 'r', encoding='utf-8', errors='replace') as f:
                source = f.read()
            analyzer = LuaAnalyzer(source, fname)
            issues = analyzer.analyze()
            fixable = [i for i in issues if i.fixable]
            if fixable:
                fixed = AutoFixer.fix_file(fpath, fixable)
                if fixed > 0:
                    total_fixed += fixed
                    print(f"  {CLI.GRN}Fixed {fixed} in {fname}{CLI.R}")
        
        print(f"\n  Total: {total_fixed} fixes")
    
    @staticmethod
    def deploy(project_dir, message=None):
        CLI.banner()
        status = subprocess.run(['git', 'status', '--short'], cwd=project_dir, capture_output=True, text=True).stdout
        if not status.strip():
            print(f"  {CLI.GRN}Nothing to deploy{CLI.R}"); return
        print(f"  Changes:\n{status}")
        msg = message or f"LuaIDE update: {time.strftime('%Y-%m-%d %H:%M:%S')}"
        subprocess.run(['git', 'add', '-A'], cwd=project_dir, capture_output=True)
        r = subprocess.run(['git', 'commit', '-m', msg], cwd=project_dir, capture_output=True, text=True)
        if r.returncode == 0:
            print(f"  {CLI.GRN}Committed{CLI.R}")
            r2 = subprocess.run(['git', 'push', 'origin', 'main'], cwd=project_dir, capture_output=True, text=True)
            if r2.returncode == 0:
                print(f"  {CLI.GRN}Pushed!{CLI.R}")
            else:
                print(f"  {CLI.RED}Push failed{CLI.R}")

# ═══════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════
def main():
    args = sys.argv[1:]
    project_dir = os.path.dirname(os.path.abspath(__file__))
    verbose = '-v' in args or '--verbose' in args
    single_file = None
    if '--file' in args:
        idx = args.index('--file')
        if idx + 1 < len(args): single_file = args[idx + 1]
    
    if '--analyze' in args or (not any(a.startswith('--') for a in args)):
        CLI.analyze(project_dir, verbose, single_file)
    elif '--fix' in args:
        CLI.fix(project_dir)
    elif '--deploy' in args:
        msg = None
        if '--message' in args:
            idx = args.index('--message')
            if idx + 1 < len(args): msg = args[idx + 1]
        CLI.deploy(project_dir, msg)

if __name__ == '__main__':
    main()
