"""Classic WoW UI (vanilla) Unit Frames seed: the original green health fill on every
frame instead of class colours, once per profile, banked in the Style page slots."""
from pathlib import Path
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime


def read(rel):
    return (root / rel).read_text(encoding='utf-8-sig')


uf = read('EllesmereUIUnitFrames/EllesmereUIUnitFrames.lua')
start = uf.index('ns.UF_STOCK_COMBAT =')
end = uf.index('function ns.UF_AtlasOK')
block = uf[start:end]
assert 'classicHealthSeeded' in block

lua = LuaRuntime()
compiled = lua.execute('return function(src) local f, e = loadstring(src, "seed") '
                       'if not f then return e end f() return true end')
lua.execute('ns = {}')
res = compiled(block)
assert res is True, res

lua.execute(r'''
function Units(extra)
    local p = { player = { healthClassColored = true },
                target = { customFillColor = { r = .1, g = .2, b = .3 } },
                focus = {}, pet = {}, targettarget = {}, focustarget = {}, boss = {} }
    for k, v in pairs(extra or {}) do p[k] = v end
    return p
end
function IsGreen(s)
    local c = s.customFillColor
    return s.healthClassColored == false and c and c.r == 0 and c.g == 1 and c.b == 0
end
function AllGreen(p)
    for _, u in ipairs(ns.UF_TEXTURE_UNITS) do if not IsGreen(p[u]) then return u end end
    return true
end
''')

# Fresh switch to Classic: every frame gets the green fill, stamp set.
r = lua.execute(r'''
local p = Units()
ns.UF_SeedStock(p, "classic")
return AllGreen(p), p.classicHealthSeeded, p.healthBarTexture
''')
assert r[0] is True, f'frame not green: {r[0]}'
assert r[1] is True and r[2] == 'plating', r

# Fill colour tables are per frame (no shared reference across units).
r = lua.execute(r'''
local p = Units()
ns.UF_SeedStock(p, "classic")
p.player.customFillColor.r = .5
return p.target.customFillColor.r
''')
assert r == 0, r

# Once per profile: a later choice stands.
r = lua.execute(r'''
local p = Units()
ns.UF_SeedStock(p, "classic")
p.player.healthClassColored = true
ns.UF_SeedStock(p, "classic")
return p.player.healthClassColored
''')
assert r is True, r

# Blizzard Style leaves the health colours alone.
r = lua.execute(r'''
local p = Units()
ns.UF_SeedStock(p, "blizzard")
return p.player.healthClassColored, p.target.customFillColor.r, p.classicHealthSeeded
''')
assert r[0] is True and abs(r[1] - 0.1) < 1e-9 and r[2] is None, r

# A profile already Classic before this seed: its colours go to the EllesmereUI slot first.
r = lua.execute(r'''
local p = Units({ _styleSlots = { eui = { ["player.healthBarTexture"] = "x" } }, classicTextureSeeded = true })
ns.UF_SeedStock(p, "classic")
local e = p._styleSlots.eui
return e["player.healthClassColored"], e["target.customFillColor"] and e["target.customFillColor"].r,
       AllGreen(p), e["player.healthBarTexture"]
''')
assert r[0] is True and abs(r[1] - 0.1) < 1e-9 and r[2] is True and r[3] == 'x', r

# An EllesmereUI slot that already holds the colours is not overwritten.
r = lua.execute(r'''
local p = Units({ _styleSlots = { eui = { ["player.healthClassColored"] = false } } })
ns.UF_SeedStock(p, "classic")
return p._styleSlots.eui["player.healthClassColored"]
''')
assert r is False, r

# Slot keys carry the health colour keys.
r = lua.execute(r'''
local have = {}
for _, k in ipairs(ns.UF_StyleSlotKeys()) do have[k] = true end
for _, u in ipairs(ns.UF_TEXTURE_UNITS) do
    if not (have[u .. ".healthClassColored"] and have[u .. ".customFillColor"]) then return u end
end
return true
''')
assert r is True, f'slot keys missing for {r}'

assert 'and p.classicHealthSeeded == nil' in uf, 'enable-time bank must check the new stamp'

style = read('EllesmereUIOptions/EUI_Style_Options.lua')
assert '"classicTextureSeeded", "classicHealthSeeded", "stockCombatSeededStyle"' in style
assert 'k[#k + 1] = units[i] .. ".healthClassColored"' in style
assert 'k[#k + 1] = units[i] .. ".customFillColor"' in style
assert 'then return "classicHealthSeeded" end' in style

for rel in ('EllesmereUIUnitFrames/EllesmereUIUnitFrames.lua', 'EllesmereUIOptions/EUI_Style_Options.lua'):
    res = compiled('return function(...) ' + read(rel) + '\nend')
    assert res is True, f'{rel}: {res}'

print('classic health seed OK')
