"""Core compat defines issecretvalue/issecrettable before any Core file runs. Options also
defines them, but it is LoadOnDemand, so Core glows (Cooldown Manager) called the bare
global before the panel was first opened."""
from pathlib import Path
import re
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

mock = (root / 'backport-tools/wrath_mock.lua').read_text()
compat = (root / 'EllesmereUI/EllesmereUI_3.3.5_Compat.lua').read_text(encoding='utf-8-sig')
toc = (root / 'EllesmereUI/EllesmereUI.toc').read_text(encoding='utf-8-sig')
files = [l.strip() for l in toc.splitlines() if l.strip().endswith('.lua')]
assert files[0] == 'EllesmereUI_3.3.5_Compat.lua', 'compat must load first'
assert '## LoadOnDemand: 1' in (root / 'EllesmereUIOptions/EllesmereUIOptions.toc').read_text(encoding='utf-8-sig')

lua = LuaRuntime()
lua.execute(mock)
lua.execute('issecretvalue=nil; issecrettable=nil')
lua.execute(compat)
assert lua.eval('type(issecretvalue)=="function" and issecretvalue(1)==false and issecretvalue(nil)==false')
assert lua.eval('type(issecrettable)=="function" and issecrettable({})==false')

native = LuaRuntime()
native.execute(mock)
native.execute('nativeISV=function() return true end; issecretvalue=nativeISV')
native.execute(compat)
assert native.eval('issecretvalue==nativeISV'), 'native issecretvalue replaced'

# The glow size resolver that crashed calls it unguarded; it must run with only Core loaded.
glows = (root / 'EllesmereUI/EllesmereUI_Glows.lua').read_text(encoding='utf-8-sig')
assert re.search(r'^\s+if issecretvalue\(w\) or issecretvalue\(h\) then', glows, re.M)
lua.execute('assert(not (issecretvalue(24) or issecretvalue(246)))')

print('PASS: Core compat (first in the TOC) defines issecretvalue/issecrettable returning false '
      'before LoadOnDemand Options, keeps a native version, and covers the unguarded glow size check.')
