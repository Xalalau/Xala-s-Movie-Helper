#!/usr/bin/env python3
"""Run isolated client regressions with stock Lua, without modifying shipped GLua.

Requires Python 3.9+ and lua5.4, lua5.3, lua, luajit, or texlua on PATH.
Only GLua operator aliases are normalized, outside strings/comments. The unchanged
server contains `continue` and is deliberately not executed or syntax-checked.
"""
from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

TOKENS = re.compile(
    r'--\[(?P<ceq>=*)\[.*?\](?P=ceq)\]|--[^\n]*'
    r'|\[(?P<seq>=*)\[.*?\](?P=seq)\]'
    r'|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\''
    r'|!=|&&|\|\||!', re.DOTALL,
)
ALIASES = {'!=': '~=', '&&': ' and ', '||': ' or ', '!': 'not '}


def normalize(source: str) -> str:
    return TOKENS.sub(lambda match: ALIASES.get(match[0], match[0]), source)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, default=Path(__file__).resolve().parents[1],
                        help='Addon root; can point to an unmodified baseline for comparison.')
    args = parser.parse_args()
    root = args.source.resolve()
    if not (root / 'lua/xmh/client/xmh_cl.lua').is_file():
        parser.error(f'Not an XMH addon root: {root}')
    runtime = next((p for name in ('lua5.4', 'lua5.3', 'lua', 'luajit', 'texlua')
                    if (p := shutil.which(name))), None)
    if runtime is None:
        parser.error('A Lua interpreter is required (lua5.4, lua5.3, lua, luajit, or texlua).')
    # Check that literals and comments are not rewritten by the test adapter.
    probe = 'if !ok && a != b then print("! && !=") end -- ! ||\n'
    assert normalize(probe) == 'if not ok  and  a ~= b then print("! && !=") end -- ! ||\n'
    with tempfile.TemporaryDirectory(prefix='xmh-regression-') as tmp:
        staged = Path(tmp)
        for path in (root / 'lua').rglob('*.lua'):
            dest = staged / path.relative_to(root)
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_text(normalize(path.read_text(encoding='utf-8')), encoding='utf-8')
        harness = Path(__file__).with_name('regression.lua')
        result = subprocess.run([runtime, str(harness), str(staged), str(root)], check=False)
        return result.returncode


if __name__ == '__main__':
    raise SystemExit(main())
