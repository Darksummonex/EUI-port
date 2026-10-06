"""Unit Frames visibility drivers on 3.3.5: RegisterAttributeDriver does not exist there, so
"state-X" attribute drivers go through ns.Wrath's adapter onto the state driver X."""
from pathlib import Path
import re
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime


def read(rel):
    return (root / rel).read_text(encoding='utf-8-sig')


compat = read('EllesmereUIUnitFrames/EUI_UnitFrames_335.lua')
start = compat.index('function W.RegisterAttributeDriver')
end = compat.index('local nativeCreateFrame')
adapter = compat[start:end]

lua = LuaRuntime()
lua.execute('W = {}; calls = {}\n'
            'function RegisterStateDriver(f, s, v) calls[#calls + 1] = "reg:" .. s .. "=" .. v end\n'
            'function UnregisterStateDriver(f, s) calls[#calls + 1] = "unreg:" .. s end\n')
lua.execute(adapter)
r = lua.execute('''
local f = {}
W.RegisterAttributeDriver(f, "state-visibility", "[@target,noexists] hide; show")
W.UnregisterAttributeDriver(f, "state-visibility")
W.RegisterAttributeDriver(f, "type-1", "spell")
return #calls, calls[1], calls[2]
''')
assert tuple(r) == (2, 'reg:visibility=[@target,noexists] hide; show', 'unreg:visibility'), tuple(r)

main = read('EllesmereUIUnitFrames/EllesmereUIUnitFrames.lua')
bare = re.findall(r'(?<![\w.])(?:Un)?[Rr]egisterAttributeDriver\(', main)
assert not bare, f'bare attribute driver calls left: {len(bare)}'
assert main.count('ns.Wrath.RegisterAttributeDriver(') == 4
assert main.count('ns.Wrath.UnregisterAttributeDriver(') == 3

compile_fn = lua.execute('return function(src) local f, e = loadstring(src) if not f then return e end return true end')
for rel in ('EllesmereUIUnitFrames/EUI_UnitFrames_335.lua', 'EllesmereUIUnitFrames/EllesmereUIUnitFrames.lua'):
    res = compile_fn(read(rel))
    assert res is True, f'{rel}: {res}'

print('UF attribute driver OK')
