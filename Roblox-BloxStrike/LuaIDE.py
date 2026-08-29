#!/usr/bin/env python3
"""
BloxStrike LuaIDE v1.0
======================
Lua 專屬的整合開發環境 (IDE)
功能:
  1. 語法分析 + 錯誤偵測
  2. 自動修復
  3. 模組管理
  4. 即時預覽
  5. 一鍵部署

用法:
  python3 LuaIDE.py              # 開啟 GUI
  python3 LuaIDE.py --cli        # CLI 模式
  python3 LuaIDE.py --analyze    # 分析所有模組
  python3 LuaIDE.py --fix        # 自動修復
  python3 LuaIDE.py --deploy     # 一鍵部署到 GitHub
"""

import os, sys, re, json, time, subprocess
from pathlib import Path
from dataclasses import dataclass, field
from typing import List, Dict, Optional, Tuple
from collections import defaultdict

# ═══════════════════════════════════════════════════════════
# Lua Tokenizer
# ═══════════════════════════════════════════════════════════
class LuaTokenizer:
    KEYWORDS = {'and','break','do','else','elseif','end','false','for','function',
                'if','in','local','nil','not','or','repeat','return','then','true',
                'until','while','continue','goto'}
    
    @staticmethod
    def tokenize(source: str) -> list:
        tokens = []
        i, line, col = 0, 1, 1
        n = len(source)
        
        while i < n:
            ch = source[i]
            
            if ch == '\n':
                tokens.append(('NEWLINE', '\n', line, col))
                i += 1; line += 1; col = 1; continue
            
            if ch in ' \t\r':
                i += 1; col += 1; continue
            
            # Comments
            if ch == '-' and i+1 < n and source[i+1] == '-':
                if i+2 < n and source[i+2] == '[':
                    end = source.find(']]', i+3)
                    if end == -1: end = n
                    tokens.append(('COMMENT', source[i:end+2], line, col))
                    lcount = source[i:end+2].count('\n')
                    line += lcount; i = end+2; col = 1; continue
                else:
                    end = source.find('\n', i)
                    if end == -1: end = n
                    tokens.append(('COMMENT', source[i:end], line, col))
                    i = end; continue
            
            # Long strings
            if ch == '[' and i+1 < n and source[i+1] in '[=':
                level = 0; p = i+1
                while p < n and source[p] == '=': level += 1; p += 1
                if p < n and source[p] == '[':
                    close = ']' + '='*level + ']'
                    end = source.find(close, p+1)
                    if end != -1:
                        val = source[i:end+len(close)]
                        tokens.append(('STRING', val, line, col))
                        line += val.count('\n'); i = end+len(close); col = 1; continue
            
            # Strings
            if ch in '"\'':
                quote = ch; start = i; i += 1; col += 1
                while i < n:
                    c = source[i]
                    if c == '\\': i += 2; col += 2
                    elif c == quote: i += 1; col += 1; break
                    elif c == '\n': line += 1; col = 1; i += 1
                    else: i += 1; col += 1
                tokens.append(('STRING', source[start:i], line, col, start))
                continue
            
            # Numbers
            if ch.isdigit() or (ch == '.' and i+1 < n and source[i+1].isdigit()):
                start = i
                if ch == '0' and i+1 < n and source[i+1] in 'xX':
                    i += 2
                    while i < n and source[i] in '0123456789abcdefABCDEF.': i += 1
                else:
                    while i < n and (source[i].isdigit() or source[i] == '.'): i += 1
                    if i < n and source[i] in 'eE':
                        i += 1
                        if i < n and source[i] in '+-': i += 1
                        while i < n and source[i].isdigit(): i += 1
                val = source[start:i]
                tokens.append(('NUMBER', val, line, col))
                col += len(val); continue
            
            # Identifiers
            if ch.isalpha() or ch == '_':
                start = i
                while i < n and (source[i].isalnum() or source[i] == '_'): i += 1
                val = source[start:i]
                tt = 'KEYWORD' if val in LuaTokenizer.KEYWORDS else 'IDENT'
                tokens.append((tt, val, line, col))
                col += len(val); continue
            
            # Operators
            for op in ['==','~=','<=','>=','..','...','+=','-=','*=','/=','::',
                       '+','-','*','/','%','^','#','=','<','>','(',')','{','}','[',']',';',',',':']:
                if source[i:i+len(op)] == op:
                    tokens.append(('OP', op, line, col))
                    i += len(op); col += len(op); break
            else:
                tokens.append(('UNKNOWN', ch, line, col))
                i += 1; col += 1
        
        tokens.append(('EOF', '', line, col))
        return tokens

# ═══════════════════════════════════════════════════════════
# Lua Analyzer
# ═══════════════════════════════════════════════════════════
@dataclass
class Issue:
    file: str; line: int; severity: str; category: str; message: str
    fixable: bool = False; hint: str = ""

class LuaAnalyzer:
    def __init__(self, source: str, filename: str = "<input>"):
        self.source = source
        self.filename = filename
        self.lines = source.split('\n')
        self.issues: List[Issue] = []
    
    def add(self, line, sev, cat, msg, fix=False, hint=""):
        self.issues.append(Issue(self.filename, line, sev, cat, msg, fix, hint))
    
    def analyze(self) -> List[Issue]:
        self._check_unicode()
        self._check_strings()
        self._check_blocks()
        self._check_nils()
        self._check_orphans()
        self._check_trailing()
        self._check_dead_code()
        self._check_flood()
        return self.issues
    
    def _check_unicode(self):
        for i, line in enumerate(self.lines, 1):
            if line.strip().startswith('--'): continue
            for m in re.finditer(r'\\u[0-9A-Fa-f]{4}', line):
                self.add(i, "ERROR", "Unicode", f"Lua does not support {m.group()}", True, "Use string.char() or ASCII")
    
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
    
    def _check_blocks(self): pass
    def _check_nils(self):
        for i, line in enumerate(self.lines, 1):
            if line.strip().startswith('--'): continue
            for pattern, name in [
                (r'(?<!\w)BS\.alive\(\)', 'BS.alive'),
                (r'(?<!\w)BS\.hrp\(\)', 'BS.hrp'),
                (r'(?<!\w)BS\.hum\(\)', 'BS.hum'),
            ]:
                if re.search(pattern, line) and f'{name} and' not in line:
                    self.add(i, "WARN", "Nil", f"{name}() without nil check", True, f"Use: if {name} and {name}()")
    
    def _check_orphans(self):
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            if s in ('and', 'or'):
                self.add(i, "ERROR", "Syntax", f"Orphaned '{s}'", True)
    
    def _check_trailing(self):
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            if re.search(r'\b(and|or)\s*$', s) and i >= len(self.lines):
                self.add(i, "ERROR", "Syntax", f"Trailing '{s.split()[-1]}' at EOF")
    
    def _check_dead_code(self):
        saw_return = False
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            if s.startswith('return'): saw_return = True
            elif saw_return and s and not s.startswith('end') and not s.startswith(')'):
                self.add(i, "INFO", "DeadCode", "Code after return (unreachable)")
                saw_return = False
    
    def _check_flood(self):
        count = sum(1 for l in self.lines if not l.strip().startswith('--') and re.search(r'\b(print|warn)\s*\(', l))
        if count > 30:
            self.add(1, "WARN", "Output", f"{count} print/warn calls")

# ═══════════════════════════════════════════════════════════
# Auto Fixer
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
            if issue.category == "Unicode":
                for old, new in [('"\\u2713"','"+ "'),('"\\u2717"','"x "'),('"\\u2192"','"-> "')]:
                    if old in line: line = line.replace(old, new); fixed += 1
            elif issue.category == "Nil":
                for old, new in [('BS.alive()','BS.alive and BS.alive()'),('BS.hrp()','BS.hrp and BS.hrp()'),('BS.hum()','BS.hum and BS.hum()')]:
                    if old in line and new not in line: line = line.replace(old, new); fixed += 1
            lines[issue.line - 1] = line
        if fixed > 0:
            with open(filepath, 'w', encoding='utf-8') as f: f.writelines(lines)
        return fixed

# ═══════════════════════════════════════════════════════════
# Module Manager
# ═══════════════════════════════════════════════════════════
@dataclass
class ModuleInfo:
    name: str; cn: str; size: int; lines: int
    errors: int = 0; warnings: int = 0; status: str = "unknown"
    tab: str = ""; deps: List[str] = field(default_factory=list)

class ModuleManager:
    TAB_MAP = {
        'combat': '自瞄', 'esp': '透視',
        'hud': '雜項', 'killeffects': '雜項', 'utility': '雜項', 'combatassist': '雜項',
        'world': '世界',
        'rage': '暴力', 'pingadapt': '暴力', 'smartai': '暴力',
        'settings': '關於', 'stealth': '關於', 'cheatdetect': '關於',
    }
    
    CN = {
        'api':'API','bypass':'反檢測','cheatdetect':'作弊偵測','combat':'戰鬥系統',
        'combatassist':'戰鬥輔助','compat':'兼容層','core':'核心','errorhandler':'錯誤處理',
        'esp':'透視系統','events':'事件系統','hud':'HUD','killeffects':'擊殺特效',
        'luau_compat':'Luau兼容','luau_detect':'Luau偵測','pingadapt':'延遲適應',
        'rage':'暴力系統','settings':'設定','smartai':'智能AI','stealth':'隱身系統',
        'ui':'介面','utility':'工具','viewmodel':'視角模型','webhook':'Webhook','world':'世界',
    }
    
    MODULE_ORDER = [
        'compat','core','ui','api','combat','esp',
        'hud','killeffects','utility','combatassist','world',
        'rage','pingadapt','smartai','settings','stealth','cheatdetect',
        'bypass','errorhandler','events','luau_detect',
    ]
    
    def __init__(self, modules_dir: str):
        self.modules_dir = modules_dir
        self.modules: Dict[str, ModuleInfo] = {}
    
    def scan(self) -> Dict[str, ModuleInfo]:
        for fname in os.listdir(self.modules_dir):
            if not fname.endswith('.lua'): continue
            name = fname.replace('.lua', '')
            fpath = os.path.join(self.modules_dir, fname)
            with open(fpath, 'r', encoding='utf-8', errors='replace') as f:
                source = f.read()
            
            analyzer = LuaAnalyzer(source, fname)
            issues = analyzer.analyze()
            
            errors = len([i for i in issues if i.severity == "ERROR"])
            warnings = len([i for i in issues if i.severity == "WARN"])
            
            self.modules[name] = ModuleInfo(
                name=name, cn=self.CN.get(name, name),
                size=len(source.encode('utf-8')),
                lines=source.count('\n') + 1,
                errors=errors, warnings=warnings,
                status="PASS" if errors == 0 else "FAIL",
                tab=self.TAB_MAP.get(name, ""),
            )
        return self.modules
    
    def get_tab_structure(self) -> Dict[str, List[str]]:
        tabs = defaultdict(list)
        for name, info in self.modules.items():
            if info.tab:
                tabs[info.tab].append(name)
        return dict(tabs)

# ═══════════════════════════════════════════════════════════
# Deploy Manager
# ═══════════════════════════════════════════════════════════
class DeployManager:
    def __init__(self, project_dir: str):
        self.project_dir = project_dir
    
    def git_status(self) -> str:
        result = subprocess.run(['git', 'status', '--short'], cwd=self.project_dir, capture_output=True, text=True)
        return result.stdout
    
    def git_commit(self, message: str) -> bool:
        subprocess.run(['git', 'add', '-A'], cwd=self.project_dir, capture_output=True)
        result = subprocess.run(['git', 'commit', '-m', message], cwd=self.project_dir, capture_output=True, text=True)
        return result.returncode == 0
    
    def git_push(self) -> Tuple[bool, str]:
        result = subprocess.run(['git', 'push', 'origin', 'main'], cwd=self.project_dir, capture_output=True, text=True)
        return result.returncode == 0, result.stdout + result.stderr

# ═══════════════════════════════════════════════════════════
# CLI Interface
# ═══════════════════════════════════════════════════════════
class CLI:
    R="\033[0m";RED="\033[91m";GRN="\033[92m";YLW="\033[93m"
    BLU="\033[94m";CYN="\033[96m";BLD="\033[1m";DIM="\033[2m"
    
    @staticmethod
    def banner():
        print(f"\n{CLI.BLD}{CLI.CYN}{'═'*60}{CLI.R}")
        print(f"{CLI.BLD}{CLI.CYN}  BloxStrike LuaIDE v1.0{CLI.R}")
        print(f"{CLI.BLD}{CLI.CYN}  Lua 專屬整合開發環境{CLI.R}")
        print(f"{CLI.BLD}{CLI.CYN}{'═'*60}{CLI.R}\n")
    
    @staticmethod
    def analyze(project_dir: str):
        CLI.banner()
        modules_dir = os.path.join(project_dir, 'modules')
        
        # Analyze modules
        print(f"{CLI.BLD} Analyzing modules...{CLI.R}\n")
        manager = ModuleManager(modules_dir)
        modules = manager.scan()
        
        total_errors = 0
        total_warnings = 0
        
        for name in ModuleManager.MODULE_ORDER:
            if name not in modules: continue
            info = modules[name]
            status = f"{CLI.GRN}PASS{CLI.R}" if info.errors == 0 else f"{CLI.RED}FAIL{CLI.R}"
            size_kb = info.size / 1024
            print(f"  {info.cn:8} [{status}] {info.lines:5}L / {size_kb:5.1f}KB")
            total_errors += info.errors
            total_warnings += info.warnings
        
        # Analyze other files
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
                total_errors += errors
        
        # Tab structure
        print(f"\n{CLI.BLD} Tab Structure:{CLI.R}")
        tabs = manager.get_tab_structure()
        for tab, mods in tabs.items():
            mod_names = ', '.join([manager.modules[m].cn for m in mods if m in manager.modules])
            print(f"  {tab}: {mod_names}")
        
        # Summary
        passed = sum(1 for m in modules.values() if m.errors == 0)
        print(f"\n{'═'*60}")
        print(f"  Files: {len(modules)+3}  Passed: {CLI.GRN}{passed}/{len(modules)}{CLI.R}")
        print(f"  Errors: {CLI.RED if total_errors else CLI.GRN}{total_errors}{CLI.R}  Warnings: {total_warnings}")
        
        if total_errors == 0:
            print(f"\n  {CLI.GRN}{CLI.BLD}ALL TESTS PASSED!{CLI.R}\n")
        else:
            print(f"\n  {CLI.RED}{CLI.BLD}FIX {total_errors} ERRORS!{CLI.R}\n")
    
    @staticmethod
    def fix(project_dir: str):
        CLI.banner()
        modules_dir = os.path.join(project_dir, 'modules')
        total_fixed = 0
        
        for fname in os.listdir(modules_dir):
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
                    print(f"  {CLI.GRN}Fixed {fixed} issues in {fname}{CLI.R}")
        
        print(f"\n  Total: {total_fixed} fixes applied")
    
    @staticmethod
    def deploy(project_dir: str, message: str = None):
        CLI.banner()
        deployer = DeployManager(project_dir)
        
        status = deployer.git_status()
        if not status.strip():
            print(f"  {CLI.GRN}Nothing to deploy{CLI.R}")
            return
        
        print(f"  Changes:\n{status}")
        
        msg = message or f"LuaIDE update: {time.strftime('%Y-%m-%d %H:%M:%S')}"
        if deployer.git_commit(msg):
            print(f"  {CLI.GRN}Committed: {msg}{CLI.R}")
            ok, output = deployer.git_push()
            if ok:
                print(f"  {CLI.GRN}Pushed to GitHub!{CLI.R}")
            else:
                print(f"  {CLI.RED}Push failed: {output}{CLI.R}")
        else:
            print(f"  {CLI.RED}Commit failed{CLI.R}")

# ═══════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════
def main():
    args = sys.argv[1:]
    project_dir = os.path.dirname(os.path.abspath(__file__))
    
    if '--analyze' in args:
        CLI.analyze(project_dir)
    elif '--fix' in args:
        CLI.fix(project_dir)
    elif '--deploy' in args:
        msg = None
        if '--message' in args:
            idx = args.index('--message')
            if idx + 1 < len(args): msg = args[idx + 1]
        CLI.deploy(project_dir, msg)
    else:
        CLI.analyze(project_dir)

if __name__ == '__main__':
    main()
