#!/usr/bin/env bash
# Syntax-check fenced code blocks in skill markdown.
#
# Catches the class of defect where a snippet is copied into a doc and does not
# parse -- duplicate declarations, missing imports, unbalanced braces. Skills
# ship code that agents paste verbatim, so a snippet that cannot parse is a bug.
#
# Checks the languages with a parser available on the runner: JavaScript (as an
# ES module, so top-level await is allowed), Python, and Go. Blocks in any other
# language are counted and skipped -- this is a syntax gate, not a type checker,
# so it will not catch undefined identifiers in any language.
set -uo pipefail

cd "$(dirname "$0")/.."

python3 - "$@" <<'PYEOF'
import pathlib, re, subprocess, sys, tempfile, os

FENCE = re.compile(r"^```([A-Za-z0-9_+-]*)[^\n]*$")
CHECKED = {"javascript": "js", "js": "js", "python": "py", "py": "python", "go": "go"}

def check(lang, code):
    """Return None if it parses, else the parser's complaint."""
    kind = CHECKED[lang]
    if kind in ("py", "python"):
        try:
            compile(code, "<fence>", "exec")
            return None
        except SyntaxError as e:
            return f"line {e.lineno}: {e.msg}"
    suffix = ".mjs" if kind == "js" else ".go"
    with tempfile.NamedTemporaryFile("w", suffix=suffix, delete=False) as fh:
        fh.write(code)
        path = fh.name
    try:
        cmd = ["node", "--check", path] if kind == "js" else ["gofmt", "-e", path]
        proc = subprocess.run(cmd, capture_output=True, text=True)
        if proc.returncode != 0:
            err = (proc.stderr or proc.stdout).strip().splitlines()
            return next((l for l in err if l.strip()), "parse failed").replace(path, "<fence>")
        return None
    except FileNotFoundError:
        MISSING.add(kind)
        return None
    finally:
        os.unlink(path)

failures, checked, skipped, MISSING = [], 0, 0, set()
by_lang = {}

for md in sorted(pathlib.Path("plugins").rglob("*.md")):
    lines = md.read_text().split("\n")
    lang, start, buf = None, 0, []
    for i, line in enumerate(lines, 1):
        m = FENCE.match(line)
        if lang is None:
            if m:
                lang, start, buf = (m.group(1) or "").lower(), i, []
        elif line.startswith("```"):
            code = "\n".join(buf)
            if lang in CHECKED and code.strip():
                checked += 1
                by_lang[lang] = by_lang.get(lang, 0) + 1
                problem = check(lang, code)
                if problem:
                    failures.append((md, start, lang, problem))
            elif code.strip():
                skipped += 1
            lang = None
        else:
            buf.append(line)

if failures:
    for md, line, lang, problem in failures:
        print(f"::error file={md},line={line}::{lang} fence does not parse -- {problem}")
    print(f"\n{len(failures)} of {checked} checked fences failed to parse.", file=sys.stderr)
    sys.exit(1)

verified = checked - sum(n for l, n in by_lang.items() if CHECKED[l] in MISSING)
if MISSING:
    tools = {"js": "node", "go": "gofmt"}
    names = ", ".join(sorted(tools.get(k, k) for k in MISSING))
    print(f"::warning::{names} not installed on this runner -- "
          f"{checked - verified} fence(s) were NOT verified. Install the toolchain "
          f"to make this check meaningful.")
print(f"{verified} of {checked} checkable code fences verified to parse "
      f"({skipped} skipped -- no parser exists for their language).")
PYEOF
