"""Classic WoW UI (vanilla) Unit Frames: the original green health fill on every frame
instead of class colours (once per profile, banked in the Style page slots), and power
bars in the client's own PowerBarColor instead of EllesmereUI's palette."""
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

# Classic power colours: the client's PowerBarColor under Classic, EUI's palette otherwise.
pstart = uf.index('-- Classic WoW UI paints power')
pend = uf.index('-- The class resource style that builds.')
res = compiled(uf[pstart:pend])
assert res is True, res
r = lua.execute(r'''
PowerBarColor = { MANA = { r = 0, g = 0, b = 1 }, [0] = { r = 0, g = 0, b = 1 },
                  RAGE = { r = 1, g = 0, b = 0 }, [1] = { r = 1, g = 0, b = 0 } }
local units = { player = { 0, "MANA" }, target = { 1, "RAGE" }, boss1 = { 8, "LUNAR_POWER" } }
function UnitPowerType(u) local t = units[u]; return t[1], t[2] end
EllesmereUI = { GetPowerColor = function(k)
    if k == "MANA" or k == 0 then return { r = 0, g = .55, b = 1 } end
    if k == "LUNAR_POWER" then return { r = 1, g = .5, b = 0 } end end }
function EllesmereUI.ResolveUnitPowerColor(u)
    local c = EllesmereUI.GetPowerColor(units[u][2]); if c then return c.r, c.g, c.b end end
local override
function EllesmereUI.GetPlayerPowerOverride() return override end
local out = {}
ns.UF_Style = function() return "classic" end
local _, g, b = ns.UF_PowerColor("player"); out[#out + 1] = (g == 0 and b == 1)
local r1, g1 = ns.UF_PowerColor("target"); out[#out + 1] = (r1 == 1 and g1 == 0)
local r2 = ns.UF_PowerColor("boss1"); out[#out + 1] = (r2 == 1)
out[#out + 1] = (ns.UF_PowerInfo("MANA").g == 0)
override = 1
local r3 = ns.UF_PowerColor("player"); out[#out + 1] = (r3 == 1)
override = nil
ns.UF_Style = function() return "eui" end
local _, g4 = ns.UF_PowerColor("player"); out[#out + 1] = (g4 == .55)
out[#out + 1] = (ns.UF_PowerInfo("MANA").g == .55)
ns.UF_Style = function() return "blizzard" end
local _, g5 = ns.UF_PowerColor("player"); out[#out + 1] = (g5 == .55)
return unpack(out)
''')
assert all(x is True for x in r), r

uf = read('EllesmereUIUnitFrames/EllesmereUIUnitFrames.lua')
assert uf.count('EllesmereUI.ResolveUnitPowerColor(') == 1, 'power colour must go through ns.UF_PowerColor'
assert uf.count('ns.UF_PowerColor(') >= 8
assert 'ns.UF_PowerInfo(S.token)' in read('EllesmereUIUnitFrames/EUI_UnitFrames_335_FormBar.lua')
ufo = read('EllesmereUIOptions/EUI_UnitFrames_Options.lua')
assert 'EllesmereUI.GetPowerColor(' not in ufo and 'EllesmereUI.ResolveUnitPowerColor(' not in ufo
assert ufo.count('ns.UF_PowerInfo(') == 17 and 'ns.UF_PowerColor("player")' in ufo

# Classic art over both bars on Wrath (no grouped clip container: the power bar sits at health + 2).
art = uf[uf.index('function ns.UF_ApplyBlizzFrameArt'):uf.index('function ns.UF_RefreshBlizzTargetArt')]
assert 'if EUI_WOW_335 and frame.Health then' in art
assert 'frame.Health:GetFrameLevel() + 3' in art
assert 'pw:GetParent() == clip then lvl = math.max(lvl, pw:GetFrameLevel() + 1)' in art
assert 'af:SetFrameLevel(lvl)' in art
assert 'frame.Power:SetFrameLevel(hpLevel + 2)' in uf

for rel in ('EllesmereUIUnitFrames/EllesmereUIUnitFrames.lua', 'EllesmereUIOptions/EUI_Style_Options.lua',
            'EllesmereUIOptions/EUI_UnitFrames_Options.lua', 'EllesmereUIUnitFrames/EUI_UnitFrames_335_FormBar.lua'):
    res = compiled('return function(...) ' + read(rel) + '\nend')
    assert res is True, f'{rel}: {res}'

print('classic health seed and power colours OK')
