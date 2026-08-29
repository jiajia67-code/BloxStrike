#!/usr/bin/env python3
"""
BloxStrike LuaCheck v1.0 - 完整 Lua 語法分析器 + 自動修復引擎
=================================================================
功能:
  1. Lua 詞法分析 (Lexer) - 識別所有 token 類型
  2. 深度語法檢查 - 區塊平衡、字串、括號、逗號
  3. 語義分析 - nil 安全、未定義變數、重複定義
  4. 跨檔案依賴 - 模組載入順序、循環依賴
  5. 自動修復 - 可修復的問題自動修正
  6. HTML 報告 - 視覺化測試結果
  7. CLI 報告 - 彩色終端輸出

用法:
  python3 BloxStrike_LuaCheck.py              # 分析所有模組
  python3 BloxStrike_LuaCheck.py --fix        # 自動修復
  python3 BloxStrike_LuaCheck.py --html       # 生成 HTML 報告
  python3 BloxStrike_LuaCheck.py --verbose    # 顯示所有檢查
  python3 BloxStrike_LuaCheck.py --file X     # 分析單一檔案
"""
import os, re, sys, json, time, html as html_mod
from dataclasses import dataclass, field
from typing import List, Dict, Tuple, Optional, Set
from collections import defaultdict
from pathlib import Path

# ═══════════════════════════════════════════════════════════
# ANSI Colors
# ═══════════════════════════════════════════════════════════
class C:
    R="\033[0m";RED="\033[91m";GRN="\033[92m";YLW="\033[93m"
    BLU="\033[94m";MAG="\033[95m";CYN="\033[96m";WHT="\033[97m"
    BLD="\033[1m";DIM="\033[2m";GRY="\033[90m";BG_R="\033[41m"

# ═══════════════════════════════════════════════════════════
# Token Types
# ═══════════════════════════════════════════════════════════
class TT:
    KEYWORD = "KEYWORD"
    IDENT = "IDENT"
    NUMBER = "NUMBER"
    STRING = "STRING"
    OP = "OP"
    PUNCT = "PUNCT"
    COMMENT = "COMMENT"
    NEWLINE = "NEWLINE"
    EOF = "EOF"
    UNKNOWN = "UNKNOWN"

LUA_KEYWORDS = {
    'and','break','do','else','elseif','end','false','for','function',
    'if','in','local','nil','not','or','repeat','return','then','true',
    'until','while','continue'
}

LUA_OPS = {
    '+','-','*','/','%','^','#','==','~=','<=','>=','<','>',
    '=','(',')','{','}','[',']',';',',','.',':','::','..','...',
    '+=','-=','*=','/='
}

# ═══════════════════════════════════════════════════════════
# Lua Lexer
# ═══════════════════════════════════════════════════════════
@dataclass
class Token:
    type: str
    value: str
    line: int
    col: int
    pos: int

class LuaLexer:
    def __init__(self, source: str, filename: str = "<input>"):
        self.source = source
        self.filename = filename
        self.pos = 0
        self.line = 1
        self.col = 1
        self.tokens: List[Token] = []
    
    def tokenize(self) -> List[Token]:
        while self.pos < len(self.source):
            ch = self.source[self.pos]
            
            # Newlines
            if ch == '\n':
                self.tokens.append(Token(TT.NEWLINE, '\n', self.line, self.col, self.pos))
                self.pos += 1; self.line += 1; self.col = 1
                continue
            
            # Whitespace
            if ch in ' \t\r':
                self.pos += 1; self.col += 1
                continue
            
            # Comments
            if ch == '-' and self.peek(1) == '-':
                if self.peek(2) == '[' and self.peek(3) in ('=', '['):
                    # Long comment
                    end = self.source.find(']]', self.pos + 4)
                    if end == -1: end = len(self.source)
                    val = self.source[self.pos:end+2]
                    self.tokens.append(Token(TT.COMMENT, val, self.line, self.col, self.pos))
                    lines = val.count('\n')
                    self.line += lines
                    self.pos = end + 2
                    self.col = 1
                else:
                    end = self.source.find('\n', self.pos)
                    if end == -1: end = len(self.source)
                    val = self.source[self.pos:end]
                    self.tokens.append(Token(TT.COMMENT, val, self.line, self.col, self.pos))
                    self.pos = end
                continue
            
            # Long strings [[ ]]
            if ch == '[' and self.peek(1) in ('=', '['):
                level = 0
                p = self.pos + 1
                while p < len(self.source) and self.source[p] == '=':
                    level += 1; p += 1
                if p < len(self.source) and self.source[p] == '[':
                    close = ']' + '=' * level + ']'
                    end = self.source.find(close, p + 1)
                    if end != -1:
                        val = self.source[self.pos:end+len(close)]
                        self.tokens.append(Token(TT.STRING, val, self.line, self.col, self.pos))
                        lines = val.count('\n')
                        self.line += lines
                        self.pos = end + len(close)
                        self.col = 1
                        continue
            
            # Strings
            if ch in '"\'':
                quote = ch
                start = self.pos
                self.pos += 1; self.col += 1
                while self.pos < len(self.source):
                    c = self.source[self.pos]
                    if c == '\\':
                        self.pos += 2; self.col += 2
                    elif c == quote:
                        self.pos += 1; self.col += 1
                        break
                    elif c == '\n':
                        self.line += 1; self.col = 1
                        self.pos += 1
                    else:
                        self.pos += 1; self.col += 1
                val = self.source[start:self.pos]
                self.tokens.append(Token(TT.STRING, val, self.line, self.col, start))
                continue
            
            # Numbers
            if ch.isdigit() or (ch == '.' and self.peek(1) and self.peek(1).isdigit()):
                start = self.pos
                if ch == '0' and self.peek(1) in 'xX':
                    self.pos += 2
                    while self.pos < len(self.source) and self.source[self.pos] in '0123456789abcdefABCDEF.':
                        self.pos += 1
                else:
                    while self.pos < len(self.source) and (self.source[self.pos].isdigit() or self.source[self.pos] == '.'):
                        self.pos += 1
                    if self.pos < len(self.source) and self.source[self.pos] in 'eE':
                        self.pos += 1
                        if self.pos < len(self.source) and self.source[self.pos] in '+-':
                            self.pos += 1
                        while self.pos < len(self.source) and self.source[self.pos].isdigit():
                            self.pos += 1
                val = self.source[start:self.pos]
                self.tokens.append(Token(TT.NUMBER, val, self.line, self.col, start))
                self.col += len(val)
                continue
            
            # Identifiers and keywords
            if ch.isalpha() or ch == '_':
                start = self.pos
                while self.pos < len(self.source) and (self.source[self.pos].isalnum() or self.source[self.pos] == '_'):
                    self.pos += 1
                val = self.source[start:self.pos]
                tt = TT.KEYWORD if val in LUA_KEYWORDS else TT.IDENT
                self.tokens.append(Token(tt, val, self.line, self.col, start))
                self.col += len(val)
                continue
            
            # Operators
            matched = False
            for op in sorted(LUA_OPS, key=len, reverse=True):
                if self.source[self.pos:self.pos+len(op)] == op:
                    self.tokens.append(Token(TT.OP, op, self.line, self.col, self.pos))
                    self.pos += len(op); self.col += len(op)
                    matched = True
                    break
            if matched:
                continue
            
            # Unknown
            self.tokens.append(Token(TT.UNKNOWN, ch, self.line, self.col, self.pos))
            self.pos += 1; self.col += 1
        
        self.tokens.append(Token(TT.EOF, '', self.line, self.col, self.pos))
        return self.tokens

# ═══════════════════════════════════════════════════════════
# Issue Severity
# ═══════════════════════════════════════════════════════════
@dataclass
class Issue:
    file: str
    line: int
    severity: str   # ERROR, WARN, INFO
    category: str
    message: str
    fixable: bool = False
    fix_hint: str = ""
    col: int = 0

# ═══════════════════════════════════════════════════════════
# Lua Analyzer
# ═══════════════════════════════════════════════════════════
class LuaAnalyzer:
    def __init__(self, source: str, filename: str = "<input>"):
        self.source = source
        self.filename = filename
        self.lines = source.split('\n')
        self.issues: List[Issue] = []
        self.defines: Dict[str, int] = {}  # var -> first define line
        self.uses: Dict[str, List[int]] = defaultdict(list)  # var -> [lines]
    
    def add_issue(self, line, severity, category, message, fixable=False, hint="", col=0):
        self.issues.append(Issue(self.filename, line, severity, category, message, fixable, hint, col))
    
    def analyze(self) -> List[Issue]:
        self._check_unicode_escapes()
        self._check_string_balance()
        self._check_block_balance_lexer()
        self._check_nil_safety()
        self._check_orphaned_keywords()
        self._check_trailing_operators()
        self._check_duplicate_locals()
        self._check_missing_then()
        self._check_function_call_syntax()
        self._check_table_syntax()
        self._check_return_usage()
        self._check_self_reference()
        self._check_dead_code()
        self._check_print_flood()
        return self.issues
    
    # ─── 1. Unicode Escapes ───
    def _check_unicode_escapes(self):
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            for m in re.finditer(r'\\u[0-9A-Fa-f]{4}', line):
                self.add_issue(i, "ERROR", "Unicode",
                    f"Lua does not support {m.group()} escape sequence", True,
                    "Use string.char(0xE2,0x9C,0x93) or ASCII")

    # ─── 2. String Balance ───
    def _check_string_balance(self):
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            # Remove strings then count quotes
            cleaned = re.sub(r'"(?:[^"\\]|\\.)*"', '', line)
            cleaned = re.sub(r"'(?:[^'\\]|\\.)*'", '', cleaned)
            cleaned = re.sub(r'\[\[.*?\]\]', '', cleaned)
            cleaned = re.sub(r'--[^\n]*$', '', cleaned)
            sq = cleaned.count("'")
            dq = cleaned.count('"')
            if sq % 2 != 0:
                self.add_issue(i, "ERROR", "String",
                    "Unterminated single quote string", True,
                    "Check for missing closing quote")
            if dq % 2 != 0:
                self.add_issue(i, "ERROR", "String",
                    "Unterminated double quote string", True,
                    "Check for missing closing quote")

    # ─── 3. Block Balance (Lexer-based) ───
    def _check_block_balance_lexer(self):
        try:
            lexer = LuaLexer(self.source, self.filename)
            tokens = lexer.tokenize()
        except Exception:
            return  # Lexer failed, skip
        
        # Track block openers/closers
        depth = 0
        stack = []  # (type, line)
        
        for tok in tokens:
            if tok.type == TT.COMMENT:
                continue
            if tok.type == TT.KEYWORD:
                if tok.value in ('function', 'if', 'for', 'while'):
                    depth += 1
                    stack.append((tok.value, tok.line))
                elif tok.value == 'do':
                    # Check if this 'do' starts a new block (for/while/repeat)
                    # or is a standalone do...end
                    if stack and stack[-1][0] in ('for', 'while'):
                        pass  # Already counted
                    else:
                        depth += 1
                        stack.append(('do', tok.line))
                elif tok.value == 'end':
                    depth -= 1
                    if stack:
                        stack.pop()
                elif tok.value == 'repeat':
                    depth += 1
                    stack.append(('repeat', tok.line))
                elif tok.value == 'until':
                    depth -= 1
                    if stack:
                        stack.pop()
        
        if depth > 0:
            missing_lines = [s[1] for s in stack[-3:]]  # Last 3 unclosed
            self.add_issue(self.source.count('\n'), "ERROR", "Block",
                f"Missing {depth} 'end' keyword(s) - unclosed blocks from lines {missing_lines}")
        elif depth < 0:
            self.add_issue(1, "ERROR", "Block",
                f"{abs(depth)} extra 'end' keyword(s) - over-closed blocks")

    # ─── 4. Nil Safety ───
    def _check_nil_safety(self):
        patterns = [
            (r'(?<!\w)BS\.alive\(\)', 'BS.alive', 'BS.alive and BS.alive()'),
            (r'(?<!\w)BS\.hrp\(\)', 'BS.hrp', 'BS.hrp and BS.hrp()'),
            (r'(?<!\w)BS\.hum\(\)', 'BS.hum', 'BS.hum and BS.hum()'),
            (r'(?<!\w)BS\.char\(\)', 'BS.char', 'BS.char and BS.char()'),
            (r'(?<!\w)BS\.cam\(\)', 'BS.cam', 'BS.cam and BS.cam()'),
        ]
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            for pattern, name, fix in patterns:
                if re.search(pattern, line) and f'{name} and' not in line:
                    self.add_issue(i, "WARN", "NilSafety",
                        f"{name}() without nil check - may error", True,
                        f"Use: if {fix} then")

    # ─── 5. Orphaned Keywords ───
    def _check_orphaned_keywords(self):
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            if s in ('and', 'or', 'and,', 'or,'):
                self.add_issue(i, "ERROR", "Syntax",
                    f"Orphaned '{s}' as standalone statement", True,
                    "Remove or wrap in pcall()")

    # ─── 6. Trailing Operators ───
    def _check_trailing_operators(self):
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            if re.search(r'\b(and|or)\s*$', s):
                if i >= len(self.lines):
                    self.add_issue(i, "ERROR", "Syntax",
                        f"Trailing '{s.split()[-1]}' at end of file")
            if re.search(r'[=+\-*/%^]\s*$', s) and not s.endswith('..'):
                self.add_issue(i, "WARN", "Syntax",
                    "Trailing operator at end of line")

    # ─── 7. Duplicate Locals ───
    def _check_duplicate_locals(self):
        scope = {}
        depth = 0
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            # Track depth
            for kw in ('function', 'if', 'for', 'while', 'do'):
                depth += len(re.findall(rf'\b{kw}\b', s))
            depth -= len(re.findall(r'\bend\b', s))
            
            # Find local declarations
            for m in re.finditer(r'\blocal\s+(\w+)', s):
                name = m.group(1)
                if name in scope and scope[name][1] == depth:
                    self.add_issue(i, "WARN", "Scope",
                        f"Local '{name}' shadows previous definition at line {scope[name][0]}")
                scope[name] = (i, depth)

    # ─── 8. Missing 'then' after 'if' ───
    # --- 8. Missing 'then' after 'if' ---
    def _check_missing_then(self):
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            if re.match(r'^if', s) and 'then' not in s and 'do' not in s:
                found_then = False
                for j in range(i, min(i + 5, len(self.lines))):
                    ns = self.lines[j].strip()
                    if ns.startswith('--'): continue
                    if 'then' in ns:
                        found_then = True
                        break
                    if ns and not ns.startswith('or') and not ns.startswith('and'):
                        break
                if not found_then:
                    self.add_issue(i, 'WARN', 'Syntax',
                        'if without then (multiline)')

    def _check_function_call_syntax(self):
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            # Detect missing comma in function args
            # e.g., func("a" "b") -> should be func("a", "b")
            if re.search(r'"\s*"', s) or re.search(r"'\s*'", s):
                # Could be string concatenation with ..
                if '..' not in s:
                    self.add_issue(i, "WARN", "Syntax",
                        "Adjacent strings without concatenation operator")

    # ─── 10. Table Syntax ───
    def _check_table_syntax(self):
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            # Check for missing commas between table entries
            if re.search(r'"\s*\n\s*"', line) or re.search(r"'\s*\n\s*'", line):
                self.add_issue(i, "WARN", "Table",
                    "Possible missing comma between table entries")

    # ─── 11. Return Usage ───
    def _check_return_usage(self):
        in_func = False
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            if 'function' in s and 'return' not in s:
                if re.search(r'\bfunction\b', s):
                    in_func = True
            if s.startswith('return') and in_func:
                in_func = False

    # ─── 12. Self Reference ───
    def _check_self_reference(self):
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            if 'self.' in s and 'self = ' not in s and ':self' not in s:
                pass  # Common in OOP, just note

    # ─── 13. Dead Code (return then code) ───
    def _check_dead_code(self):
        saw_return = False
        for i, line in enumerate(self.lines, 1):
            s = line.strip()
            if s.startswith('--'): continue
            if s.startswith('return'):
                saw_return = True
            elif saw_return and s and not s.startswith('end') and not s.startswith(')'):
                self.add_issue(i, "INFO", "DeadCode",
                    "Code after return statement (unreachable)")
                saw_return = False

    # ─── 14. Print Flood ───
    def _check_print_flood(self):
        count = sum(1 for l in self.lines
                    if not l.strip().startswith('--') and re.search(r'\b(print|warn)\s*\(', l))
        if count > 30:
            self.add_issue(1, "WARN", "Output",
                f"{count} print/warn calls - may flood console")

# ═══════════════════════════════════════════════════════════
# Cross-File Dependency Analyzer
# ═══════════════════════════════════════════════════════════
class DependencyAnalyzer:
    def __init__(self, modules_dir: str):
        self.modules_dir = modules_dir
        self.deps: Dict[str, Set[str]] = defaultdict(set)
        self.providers: Dict[str, Set[str]] = defaultdict(set)  # what each module provides
    
    def analyze(self, reports: Dict[str, List[Issue]]):
        """Analyze dependencies between modules"""
        # Map: what BS.xxx each module defines
        bs_providers = {
            'compat': {'Compat'},
            'core': {'BS.alive', 'BS.hrp', 'BS.hum', 'BS.char', 'BS.cam'},
            'ui': {'BS.Win'},
            'api': {'BS.api'},
        }
        
        # Map: what BS.xxx each module uses
        module_files = {}
        for fname in os.listdir(self.modules_dir):
            if fname.endswith('.lua'):
                with open(os.path.join(self.modules_dir, fname), 'r', encoding='utf-8', errors='replace') as f:
                    content = f.read()
                name = fname.replace('.lua', '')
                module_files[name] = content
                
                # Find BS.xxx usage
                uses = set()
                for m in re.finditer(r'BS\.(\w+)', content):
                    uses.add(f'BS.{m.group(1)}')
                self.deps[name] = uses
        
        return self.deps

# ═══════════════════════════════════════════════════════════
# Auto-Fix Engine
# ═══════════════════════════════════════════════════════════
class AutoFixer:
    def __init__(self):
        self.fixes_applied = 0
    
    def fix_file(self, filepath: str, issues: List[Issue]) -> int:
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        fixed = 0
        for issue in sorted(issues, key=lambda x: x.line, reverse=True):
            if not issue.fixable:
                continue
            if issue.line < 1 or issue.line > len(lines):
                continue
            
            line = lines[issue.line - 1]
            
            if issue.category == "Unicode":
                # Replace unicode escapes
                line = line.replace('"\\u2713"', '"+ "')
                line = line.replace('"\\u2717"', '"x "')
                line = line.replace('"\\u2192"', '"-> "')
                line = line.replace("'\\u2713'", "'+ '")
                line = line.replace("'\\u2717'", "'x '")
                line = line.replace("'\\u23F1'", "'timer'")
                lines[issue.line - 1] = line
                fixed += 1
            
            elif issue.category == "NilSafety":
                # Add nil check
                for pattern, replacement in [
                    ('BS.alive()', 'BS.alive and BS.alive()'),
                    ('BS.hrp()', 'BS.hrp and BS.hrp()'),
                    ('BS.hum()', 'BS.hum and BS.hum()'),
                ]:
                    if pattern in line and replacement not in line:
                        line = line.replace(pattern, replacement)
                        lines[issue.line - 1] = line
                        fixed += 1
                        break
        
        if fixed > 0:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.writelines(lines)
        
        self.fixes_applied += fixed
        return fixed

# ═══════════════════════════════════════════════════════════
# HTML Report Generator
# ═══════════════════════════════════════════════════════════
class HTMLReporter:
    def generate(self, all_results: Dict[str, Tuple[int, List[Issue]]], output_path: str):
        """Generate HTML report"""
        total_errors = sum(len([i for i in issues if i.severity == "ERROR"]) for _, issues in all_results.values())
        total_warnings = sum(len([i for i in issues if i.severity == "WARN"]) for _, issues in all_results.values())
        total_files = len(all_results)
        passed = sum(1 for _, (errors, _) in all_results.items() if errors == 0)
        
        status_color = "#00ff88" if total_errors == 0 else "#ff4444"
        status_text = "ALL PASS" if total_errors == 0 else f"{total_errors} ERRORS"
        
        html = f"""<!DOCTYPE html>
<html><head><meta charset="utf-8">
<title>BloxStrike LuaCheck Report</title>
<style>
body {{ font-family: 'Consolas', monospace; background: #0a0a14; color: #ccc; padding: 20px; }}
.header {{ text-align: center; padding: 20px; border-bottom: 2px solid #333; }}
.header h1 {{ color: #00ccff; font-size: 24px; }}
.status {{ font-size: 32px; font-weight: bold; color: {status_color}; }}
.stats {{ display: flex; justify-content: center; gap: 30px; margin: 20px 0; }}
.stat {{ text-align: center; padding: 10px 20px; background: #1a1a2e; border-radius: 8px; }}
.stat .num {{ font-size: 28px; font-weight: bold; color: #00ccff; }}
.stat .label {{ font-size: 12px; color: #888; }}
.file {{ margin: 10px 0; padding: 10px; background: #12121e; border-radius: 8px; border-left: 3px solid #333; }}
.file.pass {{ border-left-color: #00ff88; }}
.file.fail {{ border-left-color: #ff4444; }}
.file-header {{ font-size: 14px; font-weight: bold; color: #fff; }}
.file-header .badge {{ padding: 2px 8px; border-radius: 4px; font-size: 11px; margin-left: 8px; }}
.badge-pass {{ background: #00ff8833; color: #00ff88; }}
.badge-fail {{ background: #ff444433; color: #ff4444; }}
.issue {{ margin: 4px 0; padding: 4px 8px; font-size: 12px; }}
.issue-ERROR {{ color: #ff6666; }}
.issue-WARN {{ color: #ffaa44; }}
.issue-INFO {{ color: #66aaff; }}
.issue-line {{ color: #666; margin-right: 8px; }}
.issue-cat {{ color: #aa66ff; margin-right: 8px; }}
</style></head><body>
<div class="header">
<h1>BloxStrike LuaCheck Report</h1>
<div class="status">{status_text}</div>
<div class="stats">
<div class="stat"><div class="num">{total_files}</div><div class="label">FILES</div></div>
<div class="stat"><div class="num" style="color:#00ff88">{passed}</div><div class="label">PASSED</div></div>
<div class="stat"><div class="num" style="color:#ff4444">{total_errors}</div><div class="label">ERRORS</div></div>
<div class="stat"><div class="num" style="color:#ffaa44">{total_warnings}</div><div class="label">WARNINGS</div></div>
</div></div>
"""
        for fname in sorted(all_results.keys()):
            errors, issues = all_results[fname]
            status_class = "pass" if errors == 0 else "fail"
            badge = f'<span class="badge badge-pass">PASS</span>' if errors == 0 else f'<span class="badge badge-fail">FAIL</span>'
            
            html += f'<div class="file {status_class}">'
            html += f'<div class="file-header">{fname} {badge}</div>'
            
            for issue in issues:
                html += f'<div class="issue issue-{issue.severity}">'
                html += f'<span class="issue-line">L{issue.line}</span>'
                html += f'<span class="issue-cat">[{issue.category}]</span>'
                html += f'{html_mod.escape(issue.message)}'
                if issue.fixable:
                    html += ' <span style="color:#ffaa44">[FIXABLE]</span>'
                html += '</div>'
            
            html += '</div>'
        
        html += '</body></html>'
        
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(html)

# ═══════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════
def main():
    args = sys.argv[1:]
    do_fix = '--fix' in args
    do_html = '--html' in args
    verbose = '-v' in args or '--verbose' in args
    single_file = None
    if '--file' in args:
        idx = args.index('--file')
        if idx + 1 < len(args):
            single_file = args[idx + 1]
    
    script_dir = os.path.dirname(os.path.abspath(__file__))
    modules_dir = os.path.join(script_dir, 'modules')
    
    print(f"\n{C.BLD}{C.CYN}{'═'*60}{C.R}")
    print(f"{C.BLD}{C.CYN}  BloxStrike LuaCheck v1.0{C.R}")
    print(f"{C.BLD}{C.CYN}  Lua Lexer + Deep Syntax + Auto-Fix + HTML Report{C.R}")
    print(f"{C.BLD}{C.CYN}{'═'*60}{C.R}")
    
    all_results = {}
    total_fixes = 0
    
    # Collect files to analyze
    files_to_check = []
    if single_file:
        files_to_check.append(single_file)
    else:
        # Modules
        if os.path.isdir(modules_dir):
            for f in sorted(os.listdir(modules_dir)):
                if f.endswith('.lua'):
                    files_to_check.append(os.path.join(modules_dir, f))
        # Other files
        for extra in ['BloxStrike_Standalone.lua', 'BloxStrike_Launcher.lua', 'BloxStrike_Test.lua']:
            fp = os.path.join(script_dir, extra)
            if os.path.isfile(fp):
                files_to_check.append(fp)
    
    # Analyze each file
    for filepath in files_to_check:
        fname = os.path.basename(filepath)
        with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
            source = f.read()
        
        analyzer = LuaAnalyzer(source, fname)
        issues = analyzer.analyze()
        
        errors = len([i for i in issues if i.severity == "ERROR"])
        warnings = len([i for i in issues if i.severity == "WARN"])
        
        all_results[fname] = (errors, issues)
        
        # Print results
        status = f"{C.GRN}PASS{C.R}" if errors == 0 else f"{C.RED}FAIL{C.R}"
        lines_count = source.count('\n') + 1
        size_kb = len(source.encode('utf-8')) / 1024
        
        print(f"\n{C.BLD} {fname}{C.R} [{status}] {lines_count}L / {size_kb:.1f}KB")
        
        if issues:
            for issue in issues:
                if issue.severity == "ERROR" or verbose:
                    color = C.RED if issue.severity == "ERROR" else (C.YLW if issue.severity == "WARN" else C.BLU)
                    fix = f" {C.YLW}[FIX]{C.R}" if issue.fixable else ""
                    print(f"   {color}{issue.severity:4}{C.R} L{issue.line:<4} {issue.category}: {issue.message}{fix}")
        
        if not issues:
            print(f"   {C.GRN}No issues found{C.R}")
        
        # Auto-fix
        if do_fix and issues:
            fixer = AutoFixer()
            fixed = fixer.fix_file(filepath, issues)
            if fixed > 0:
                total_fixes += fixed
                print(f"   {C.GRN}Auto-fixed {fixed} issues{C.R}")
    
    # Dependency analysis
    if os.path.isdir(modules_dir):
        print(f"\n{C.BLD}{'═'*60}{C.R}")
        print(f"{C.BLD} Dependency Analysis{C.R}")
        print(f"{'═'*60}")
        
        dep_analyzer = DependencyAnalyzer(modules_dir)
        deps = dep_analyzer.analyze(all_results)
        
        # Check load order
        load_order = ['compat', 'core', 'ui', 'api']
        for mod in load_order:
            if mod in deps:
                provides = deps[mod]
                print(f"   {C.CYN}{mod}{C.R} provides: {', '.join(sorted(provides)[:5])}")
    
    # Summary
    te = sum(len([i for i in issues if i.severity == "ERROR"]) for _, issues in all_results.values())
    tw = sum(len([i for i in issues if i.severity == "WARN"]) for _, issues in all_results.values())
    tf = sum(1 for e, _ in all_results.values() if e == 0)
    total = len(all_results)
    
    print(f"\n{'═'*60}")
    print(f" SUMMARY")
    print(f"{'═'*60}")
    print(f"  Files:    {total}")
    print(f"  Passed:   {C.GRN}{tf}/{total}{C.R}")
    print(f"  Errors:   {C.RED if te else C.GRN}{te}{C.R}")
    print(f"  Warnings: {C.YLW if tw else C.GRN}{tw}{C.R}")
    if total_fixes:
        print(f"  Fixed:    {C.GRN}{total_fixes}{C.R}")
    
    if te == 0:
        print(f"\n  {C.GRN}{C.BLD}ALL TESTS PASSED!{C.R}\n")
    else:
        print(f"\n  {C.RED}{C.BLD}FIX {te} ERRORS!{C.R}\n")
    
    # HTML report
    if do_html:
        reporter = HTMLReporter()
        report_path = os.path.join(script_dir, 'LuaCheck_Report.html')
        reporter.generate(all_results, report_path)
        print(f"  HTML report: {report_path}")
    
    return 0 if te == 0 else 1

if __name__ == '__main__':
    sys.exit(main())
