"""Audit a Retail Nameplates profile against the port's Nameplates defaults.

Usage: audit_nameplate_import.py <label>
Reads .codex-backups/profile-strings/<label>.json, takes the defaults table
from EllesmereUINameplates/EUI_Nameplates_335.lua and prints:
  * values the importer applies (same key, same type, different value);
  * Retail keys dropped although the port has a setting under another name.
"""
import json
import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

src = (root / 'EllesmereUINameplates' / 'EUI_Nameplates_335.lua').read_text(encoding='utf-8-sig')
body = re.search(r'local defaults=\{(.*?)\n\}\nns\.defaults', src, re.S).group(1)
lua = LuaRuntime(unpack_returned_tuples=True)
ltab = lua.execute('local function C(r,g,b) return {r=r,g=g,b=b} end\nreturn {' + body + '\n}')
lua_type = lua.eval('type')


def to_py(v):
    if lua_type(v) != 'table':
        return v
    return {str(k): to_py(x) for k, x in v.items()}


defaults = to_py(ltab)
p = json.loads((root / '.codex-backups' / 'profile-strings' / (sys.argv[1] + '.json')).read_text(encoding='utf-8'))
blob = p['data']['addons']['EllesmereUINameplates']

# Retail key -> port key for settings that exist on both sides under different names.
RENAMES = {
    'healthBarWidth': 'width', 'healthBarHeight': 'height', 'castBarHeight': 'castHeight',
    'enemyNameTextSize': 'nameSize', 'castBar': 'castBarColor', 'nameplateYOffset': 'yOffset',
    'friendlyNameTextSize': 'friendlyNameSize', 'interruptedFlashEnabled': 'showInterruptedFlash',
    'interruptedFlashColor': 'interruptedColor', 'targetColorEnabled': 'enableTargetColor',
    'target': 'targetColor', 'maxDebuffs': 'maxAuras', 'debuffIconSize': 'auraSize',
    'buffIconSize': 'buffSize', 'debuffSpacing': 'auraSpacing', 'showCastIcon': 'castIconPosition',
    'raidMarkerPos': 'raidMarkerSlot', 'rareEliteIconSize': 'classificationSize',
    'nameRaidMarkerSize': 'raidMarkerSize', 'customBorderColor': 'borderColor',
    'customBorderSize': 'borderSize', 'debuffTimerPosition': 'auraTimerPosition',
}


def num(v):
    return isinstance(v, (int, float)) and not isinstance(v, bool)


applied, dropped, renamed = [], [], []
for k, v in sorted(blob.items()):
    if k in defaults:
        d = defaults[k]
        same_type = (num(v) and num(d)) or type(v) is type(d)
        if same_type and v != d:
            applied.append((k, v, d))
        elif not same_type:
            dropped.append((k, v, 'type differs from port %r' % (d,)))
    elif k in RENAMES and RENAMES[k] in defaults:
        renamed.append((k, RENAMES[k], v, defaults[RENAMES[k]]))
    else:
        dropped.append((k, v, 'no port setting'))

print('APPLIED (%d):' % len(applied))
for k, v, d in applied:
    print('  %-24s %-40s port default %s' % (k, repr(v)[:40], repr(d)[:40]))
print('\nLOST TO A DIFFERENT KEY NAME (%d):' % len(renamed))
for k, pk, v, d in renamed:
    print('  %-24s -> %-20s %-34s port default %s' % (k, pk, repr(v)[:34], repr(d)[:34]))
print('\nDROPPED, no port setting: %d' % sum(1 for x in dropped if x[2] == 'no port setting'))
for k, v, why in dropped:
    if why != 'no port setting':
        print('  %-24s %s %s' % (k, repr(v)[:40], why))
