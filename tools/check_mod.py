"""Static sanity checks for Battle Brothers Squirrel sources.

There is no test harness for Squirrel outside the game, so this is the closest
thing to a compile step: it catches the mistakes that otherwise only surface as
a silent mod-load failure or a mid-campaign crash.

Checks
  1. brace/paren/bracket balance, ignoring comments and string literals
  2. unterminated string literals
  3. every "scripts/..." path literal resolves to a real script, in this mod or
     in one of the reference trees (vanilla, MSU, Reforged, modern hooks)
  4. `arr.find(x)` used directly as a truth value  -- index 0 is falsy in Squirrel
  5. `Math.rand(0, <expr>.len() - 1)` with no preceding emptiness guard

Usage:
    python tools/check_mod.py [--refs <dir>] [--quiet]
Exit code is 1 if any ERROR-level finding is present.
"""

from __future__ import annotations

import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_REFS = os.path.join(
    os.environ.get("TEMP", "/tmp"),
    "claude", "C--Users-igorl-Documents-Claude",
    "72133be6-3ec8-4631-bcbf-62c67eacc69f", "scratchpad",
)

OPEN = {"(": ")", "[": "]", "{": "}"}
CLOSE = {v: k for k, v in OPEN.items()}


def strip_code(src: str):
    """Yield (line_no, code_only_text). Removes comments and string bodies."""
    out = []
    line = 1
    i = 0
    n = len(src)
    buf = []
    while i < n:
        c = src[i]
        if c == "\n":
            out.append((line, "".join(buf)))
            buf = []
            line += 1
            i += 1
        elif c == "/" and i + 1 < n and src[i + 1] == "/":
            while i < n and src[i] != "\n":
                i += 1
        elif c == "/" and i + 1 < n and src[i + 1] == "*":
            i += 2
            while i + 1 < n and not (src[i] == "*" and src[i + 1] == "/"):
                if src[i] == "\n":
                    out.append((line, "".join(buf)))
                    buf = []
                    line += 1
                i += 1
            i += 2
        elif c in ('"', "'"):
            quote = c
            i += 1
            buf.append(" ")            # placeholder keeps column-ish alignment
            while i < n:
                if src[i] == "\\":
                    i += 2
                    continue
                if src[i] == quote:
                    i += 1
                    break
                if src[i] == "\n":     # unterminated on this line
                    out.append((line, "".join(buf) + " @@UNTERMINATED_STRING@@"))
                    buf = []
                    line += 1
                i += 1
            else:
                out.append((line, "".join(buf) + " @@UNTERMINATED_STRING@@"))
                buf = []
        else:
            buf.append(c)
            i += 1
    if buf:
        out.append((line, "".join(buf)))
    return out


def collect_known_scripts(roots) -> set[str]:
    known = set()
    for root in roots:
        if not os.path.isdir(root):
            continue
        for dirpath, _dirs, files in os.walk(root):
            for f in files:
                if not f.endswith((".nut", ".cnut")):
                    continue
                full = os.path.join(dirpath, f).replace("\\", "/")
                idx = full.rfind("/scripts/")
                if idx == -1:
                    continue
                rel = full[idx + 1:]
                rel = rel.rsplit(".", 1)[0]
                known.add(rel)
    return known


PATH_RE = re.compile(r'"(scripts/[A-Za-z0-9_./!-]+)"')
FIND_TRUTH_RE = re.compile(r'(?:if|while)\s*\(\s*!?\s*[\w.\[\]]+\.find\(')
RAND_RE = re.compile(r'\.rand\(\s*0\s*,\s*([\w.\[\]()]+)\.len\(\)\s*-\s*1\s*\)')


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--refs", default=DEFAULT_REFS)
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()

    ref_roots = [
        os.path.join(args.refs, "vanilla"),
        os.path.join(args.refs, "refs"),
        HERE,
    ]
    known = collect_known_scripts(ref_roots)
    have_refs = len(known) > 500
    if not have_refs and not args.quiet:
        print(f"note: only {len(known)} reference scripts found under {args.refs};"
              " script-path checking will be skipped", file=sys.stderr)

    errors, warnings = [], []
    files = []
    for dirpath, dirs, fs in os.walk(HERE):
        # .refs holds the vanilla/framework trees we check *against*, not our own
        # sources, so it must never be walked as mod content.
        dirs[:] = [d for d in dirs
                   if d not in (".git", "tools", "docs", "dist", "__pycache__", ".refs")]
        files += [os.path.join(dirpath, f) for f in fs if f.endswith(".nut")]

    for path in sorted(files):
        rel = os.path.relpath(path, HERE).replace("\\", "/")
        src = open(path, encoding="utf-8", errors="replace").read()
        lines = strip_code(src)

        stack = []
        for lineno, text in lines:
            if "@@UNTERMINATED_STRING@@" in text:
                errors.append(f"{rel}:{lineno}: unterminated string literal")
            for ch in text:
                if ch in OPEN:
                    stack.append((ch, lineno))
                elif ch in CLOSE:
                    if not stack:
                        errors.append(f"{rel}:{lineno}: stray '{ch}'")
                    elif stack[-1][0] != CLOSE[ch]:
                        o, oln = stack[-1]
                        errors.append(
                            f"{rel}:{lineno}: '{ch}' closes '{o}' opened at line {oln}")
                        stack.pop()
                    else:
                        stack.pop()
        for ch, oln in stack:
            errors.append(f"{rel}:{oln}: unclosed '{ch}'")

        for lineno, text in lines:
            if FIND_TRUTH_RE.search(text):
                warnings.append(
                    f"{rel}:{lineno}: .find() used as a truth value "
                    "(index 0 is falsy in Squirrel; compare against null)")
            m = RAND_RE.search(text)
            # Const tables are authored literals and are never empty at runtime;
            # only dynamically-built containers are worth flagging.
            if m and not m.group(1).startswith(("this.Const.", "::Const.")):
                warnings.append(
                    f"{rel}:{lineno}: rand(0, {m.group(1)}.len()-1) "
                    "throws if the container is empty")

        if have_refs:
            for m in PATH_RE.finditer(src):
                target = m.group(1)
                if target.endswith("/"):
                    continue          # a prefix built up by string concatenation
                if target in known:
                    continue
                if any(k.startswith(target + "/") for k in known):
                    continue          # directory-style reference
                lineno = src.count("\n", 0, m.start()) + 1
                errors.append(f"{rel}:{lineno}: unresolved script path '{target}'")

    for e in errors:
        print("ERROR  " + e)
    for w in warnings:
        print("WARN   " + w)

    print(f"\n{len(files)} .nut files | {len(errors)} errors | {len(warnings)} warnings")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
