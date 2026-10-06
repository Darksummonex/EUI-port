"""Compile-check DataBars 3.3.5 Lua files under Lua 5.1 (syntax + 200-locals limit).

Usage: python syntax_databars.py [file ...]
Without arguments every *_335*.lua of EllesmereUIDataBars, its Blocks_335 folder
and the DataBars 3.3.5 options file are checked.
"""
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime  # noqa: E402

lua = LuaRuntime(unpack_returned_tuples=True)
compile_chunk = lua.eval('function(src, name) local f, err = loadstring(src, name); return f ~= nil, err end')

files = [Path(a) for a in sys.argv[1:]]
if not files:
    mod = root / 'EllesmereUIDataBars'
    files = sorted(mod.glob('EUI_DataBars_335*.lua')) + sorted((mod / 'Blocks_335').glob('*.lua'))
    files.append(root / 'EllesmereUIOptions' / 'EUI_DataBars_335_Options.lua')
bad = 0
for f in files:
    f = f if f.is_absolute() else (Path.cwd() / f)
    ok, err = compile_chunk(f.read_text(encoding='utf-8'), '@' + f.name)
    print(('OK   ' if ok else 'FAIL ') + str(f.relative_to(root)) + ('' if ok else '  ' + str(err)))
    bad += 0 if ok else 1
sys.exit(1 if bad else 0)
