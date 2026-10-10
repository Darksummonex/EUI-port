"""Compile Lua files with Lua 5.1 (lupa) and report syntax errors.

Usage: check_lua_syntax.py <file.lua> [<file.lua> ...]
"""
import pathlib
import sys

root = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

lua = LuaRuntime(unpack_returned_tuples=True)
compile_chunk = lua.eval('function(src, name) local f, err = loadstring(src, name); return f ~= nil, err end')
bad = 0
for path in sys.argv[1:]:
    src = pathlib.Path(path).read_text(encoding='utf-8-sig')
    ok, err = compile_chunk(src, '@' + path)
    print(('ok    ' if ok else 'ERROR ') + path + ('' if ok else ': ' + str(err)))
    bad += 0 if ok else 1
sys.exit(1 if bad else 0)
