"""Core 3.3.5 shield estimate (EllesmereUI_Absorbs_335.lua) and its overlay.

Combat-log driven: apply/refresh/remove, absorbed parts of damage and
*_MISSED ABSORB, school-only wards, spell power for the player's own shields,
Divine Aegis from the caster's crit heal, capacity learned from a break,
UNIT_AURA seed/clear, callbacks, the native UnitGetTotalAbsorbs passthrough,
and the overlay geometry (overlay, overshield, edges, vertical, tiling).
"""
from pathlib import Path
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

src = (root / 'EllesmereUI/EllesmereUI_Absorbs_335.lua').read_text(encoding='utf-8-sig')
for bad in ('SetRotatesTexture', 'RegisterAttributeDriver', 'SetClipsChildren', 'RegisterUnitEvent', '.png"', 'OnUpdate'):
    assert bad not in src, bad
toc = [l.strip() for l in (root / 'EllesmereUI/EllesmereUI.toc').read_text(encoding='utf-8-sig').splitlines()]
assert toc.index('EllesmereUI_Absorbs_335.lua') > toc.index('EllesmereUI_Lite.lua')
for name in ('striped-5', 'striped-5-reversed', 'striped-thick', 'striped-thick-r', 'striped3', 'blizzard'):
    data = (root / 'EllesmereUI/media/textures/shields_335' / (name + '.tga')).read_bytes()
    w, h = int.from_bytes(data[12:14], 'little'), int.from_bytes(data[14:16], 'little')
    assert data[2] == 2 and data[16] == 32 and w & (w - 1) == 0 and h & (h - 1) == 0, name


def runtime(native=None):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute((root / 'backport-tools/wrath_mock.lua').read_text(encoding='utf-8-sig'))
    lua.execute('''
EllesmereUI = EllesmereUI or {}
_G.EllesmereUI = EllesmereUI
maxHP = { player = 20000, party1 = 10000 }
function UnitHealthMax(u) return maxHP[u] or 0 end
function UnitGUID(u) return u end
function GetSpellBonusHealing() return 1000 end
function GetSpellBonusDamage(school) return school == 5 and 500 or 0 end
function UnitAttackPower() return 4000, 0, 0 end
function GetNumPartyMembers() return 1 end
function GetNumRaidMembers() return 0 end
auras = {}
function UnitAura(unit, i)
    local a = auras[unit] and auras[unit][i]
    if a then return a.name, nil, "", 0, nil, 30, a.expires, a.caster, nil, nil, a.id end
end
errors = {}
function geterrorhandler() return function(e) errors[#errors + 1] = e end end
''')
    if native:
        lua.execute(native)
    lua.execute(src)
    return lua


lua = runtime()
lua.execute(r'''
local A = EllesmereUI.Absorbs
local Get, CL = EllesmereUI.GetUnitAbsorb, A.CombatLog
local fired = {}
EllesmereUI.RegisterAbsorbCallback("test", function(guid) fired[#fired + 1] = guid end)
EllesmereUI.RegisterAbsorbCallback("bad", function() error("boom") end)
A.OnEvent(nil, "PLAYER_LOGIN")
assert(Get("party1") == 0 and Get(nil) == 0)

-- Another priest's max-rank shield: base value only.
CL(0, "SPELL_AURA_APPLIED", "party2", nil, 0, "party1", nil, 0, 48066, "Power Word: Shield", 2, "BUFF")
assert(Get("party1") == 2230 and fired[#fired] == "party1" and #errors >= 1, Get("party1"))
-- Melee absorbed part, spell absorbed part, full absorb as a miss, environmental.
CL(0, "SWING_DAMAGE", "mob", nil, 0, "party1", nil, 0, 500, 0, 1, 0, 0, 230)
assert(Get("party1") == 2000)
CL(0, "SPELL_DAMAGE", "mob", nil, 0, "party1", nil, 0, 133, "Fireball", 4, 300, 0, 4, 0, 0, 500)
assert(Get("party1") == 1500)
CL(0, "SPELL_PERIODIC_MISSED", "mob", nil, 0, "party1", nil, 0, 172, "Corruption", 32, "ABSORB", 400)
assert(Get("party1") == 1100)
CL(0, "SWING_MISSED", "mob", nil, 0, "party1", nil, 0, "ABSORB", 100)
assert(Get("party1") == 1000)
CL(0, "SPELL_MISSED", "mob", nil, 0, "party1", nil, 0, 133, "Fireball", 4, "RESIST", 100)
assert(Get("party1") == 1000, "only ABSORB misses count")
CL(0, "ENVIRONMENTAL_DAMAGE", nil, nil, 0, "party1", nil, 0, "FALLING", 300, 0, 1, 0, 0, 200)
assert(Get("party1") == 800)
-- Refresh restarts the capacity.
CL(0, "SPELL_AURA_REFRESH", "party2", nil, 0, "party1", nil, 0, 48066, "Power Word: Shield", 2, "BUFF")
assert(Get("party1") == 2230)
-- Overflowing damage empties it; a break right after a hit teaches the real capacity.
CL(0, "SPELL_DAMAGE", "mob", nil, 0, "party1", nil, 0, 133, "Hit", 1, 0, 0, 1, 0, 0, 2600)
assert(Get("party1") == 0)
CL(0, "SPELL_AURA_REMOVED", "party2", nil, 0, "party1", nil, 0, 48066, "Power Word: Shield", 2, "BUFF")
CL(0, "SPELL_AURA_APPLIED", "party2", nil, 0, "party1", nil, 0, 48066, "Power Word: Shield", 2, "BUFF")
assert(Get("party1") == 2600, "learned capacity " .. Get("party1"))
CL(0, "SPELL_AURA_REMOVED", "party2", nil, 0, "party1", nil, 0, 48066, "Power Word: Shield", 2, "BUFF")
assert(Get("party1") == 0 and fired[#fired] == "party1")

-- Own shields add the spell-power share (bonus healing for priests, frost for Ice Barrier).
CL(0, "SPELL_AURA_APPLIED", "player", nil, 0, "player", nil, 0, 48066, "Power Word: Shield", 2, "BUFF")
assert(Get("player") == math.floor(2230 + 1000 * .8068 + .5), Get("player"))
CL(0, "SPELL_AURA_REMOVED", "player", nil, 0, "player", nil, 0, 48066, "Power Word: Shield", 2, "BUFF")
CL(0, "SPELL_AURA_APPLIED", "player", nil, 0, "player", nil, 0, 43039, "Ice Barrier", 16, "BUFF")
assert(Get("player") == math.floor(3300 + 500 * .8053 + .5))
CL(0, "SPELL_AURA_REMOVED", "player", nil, 0, "player", nil, 0, 43039, "Ice Barrier", 16, "BUFF")

-- School wards only soak their school; other shields take the rest in order.
CL(0, "SPELL_AURA_APPLIED", "party2", nil, 0, "party1", nil, 0, 43010, "Fire Ward", 4, "BUFF")
CL(0, "SPELL_AURA_APPLIED", "party2", nil, 0, "party1", nil, 0, 17, "Power Word: Shield", 2, "BUFF")
assert(Get("party1") == 1950 + 44)
CL(0, "SWING_DAMAGE", "mob", nil, 0, "party1", nil, 0, 100, 0, 1, 0, 0, 30)
assert(Get("party1") == 1950 + 14, "physical skips Fire Ward")
CL(0, "SPELL_DAMAGE", "mob", nil, 0, "party1", nil, 0, 133, "Fireball", 4, 300, 0, 4, 0, 0, 950)
assert(Get("party1") == 1000 + 14, "fire hits the ward first")
CL(0, "UNIT_DIED", nil, nil, 0, "party1", nil, 0)
assert(Get("party1") == 0)

-- Divine Aegis: 30% of the caster's last crit heal on that target, stacking.
CL(0, "SPELL_HEAL", "player", nil, 0, "party1", nil, 0, 48063, "Greater Heal", 2, 6000, 0, 0, 1)
CL(0, "SPELL_AURA_APPLIED", "player", nil, 0, "party1", nil, 0, 47753, "Divine Aegis", 2, "BUFF")
assert(Get("party1") == 1800)
CL(0, "SPELL_HEAL", "player", nil, 0, "party1", nil, 0, 48063, "Greater Heal", 2, 4000, 0, 0, 1)
CL(0, "SPELL_AURA_REFRESH", "player", nil, 0, "party1", nil, 0, 47753, "Divine Aegis", 2, "BUFF")
assert(Get("party1") == 3000)
CL(0, "SPELL_AURA_REMOVED", "player", nil, 0, "party1", nil, 0, 47753, "Divine Aegis", 2, "BUFF")
-- Anti-Magic Shell: half the target's max health, magic only.
CL(0, "SPELL_AURA_APPLIED", "party1", nil, 0, "party1", nil, 0, 48707, "Anti-Magic Shell", 32, "BUFF")
assert(Get("party1") == 5000)
CL(0, "SWING_DAMAGE", "mob", nil, 0, "party1", nil, 0, 100, 0, 1, 0, 0, 50)
assert(Get("party1") == 5000)
-- Debuffs with a known ID are ignored; expired shields drop out.
CL(0, "SPELL_AURA_APPLIED", "x", nil, 0, "party1", nil, 0, 17, "Power Word: Shield", 2, "DEBUFF")
assert(Get("party1") == 5000)
now = now + 6
assert(Get("party1") == 0, "expired")
now = now - 6
A.Reset()

-- UNIT_AURA: seed a shield the log never reported; clear one that is gone.
auras.party1 = { { name = "Power Word: Shield", id = 10901, caster = "raid5", expires = now + 20 } }
A.OnEvent(nil, "UNIT_AURA", "party1")
assert(Get("party1") == 942 and fired[#fired] == "party1")
A.OnEvent(nil, "UNIT_AURA", "party1")
assert(Get("party1") == 942, "rescan keeps the tracked amount")
CL(0, "SWING_DAMAGE", "mob", nil, 0, "party1", nil, 0, 100, 0, 1, 0, 0, 42)
A.OnEvent(nil, "UNIT_AURA", "party1")
assert(Get("party1") == 900, "rescan does not reset a drained shield")
auras.party1 = {}
A.OnEvent(nil, "UNIT_AURA", "party1")
assert(Get("party1") == 0)
A.Reset()
EllesmereUI.UnregisterAbsorbCallback("bad")

-- Overlay geometry: bar 200x20, health 60%, shield 25% (fits), 60% (overshield).
local bar = CreateFrame("StatusBar")
local o = A.CreateOverlay(bar)
local function VC(t) t.SetVertexColor = function(self, ...) self.vc = {...} end end
VC(o.fw); VC(o.os)
A.Paint(o, 60, 100, 25, "striped", 1, .5, .25, .9, "overlay", "always", false, false, 200, 20)
assert(o.fw:IsShown() and not o.os:IsShown() and o.fw:GetWidth() == 50 and o.fw:GetHeight() == 20)
assert(o.fw.texture:find("shields_335\\striped-5.tga", 1, true) and o.fw.vc[2] == .5 and o.fw.vc[4] == .9)
-- Tiled at native density: 256 px tile, segment 120..170 of a 200 px bar.
assert(math.abs(o.fw.texcoords[1] - 120 / 256) < 1e-9 and math.abs(o.fw.texcoords[2] - 170 / 256) < 1e-9)
assert(math.abs(o.fw.texcoords[4] - 20 / 128) < 1e-9)
local function near(a, b) return math.abs(a - b) < 1e-6 end
local function seg(t, a, b) return near(t.texcoords[1], a) and near(t.texcoords[2], b) end
A.Paint(o, 60, 100, 60, "clean", 1, 1, 1, 1, "overlay", "always", false, false, 200, 20)
assert(near(o.fw:GetWidth(), 80) and o.os:IsShown() and near(o.os:GetWidth(), 40) and seg(o.os, .4, .6))
A.Paint(o, 60, 100, 60, "clean", 1, 1, 1, 1, "overlay", "fromleft", false, false, 200, 20)
assert(seg(o.os, 0, .2))
A.Paint(o, 60, 100, 60, "clean", 1, 1, 1, 1, "overlay", "never", false, false, 200, 20)
assert(not o.os:IsShown())
A.Paint(o, 60, 100, 25, "clean", 1, 1, 1, 1, "overlayReverse", "always", false, false, 200, 20)
assert(seg(o.fw, .35, .6))
A.Paint(o, 60, 100, 25, "clean", 1, 1, 1, 1, "right", "always", false, false, 200, 20)
assert(seg(o.fw, .75, 1) and not o.os:IsShown())
A.Paint(o, 60, 100, 25, "clean", 1, 1, 1, 1, "left", "always", false, false, 200, 20)
assert(seg(o.fw, 0, .25))
A.Paint(o, 60, 100, 25, "clean", 1, 1, 1, 1, "overlay", "always", false, true, 200, 20)
assert(seg(o.fw, .15, .4), "reverse mirrors")
A.Paint(o, 60, 100, 25, "clean", 1, 1, 1, 1, "overlay", "always", true, false, 30, 100)
assert(near(o.fw:GetWidth(), 30) and near(o.fw:GetHeight(), 25) and near(o.fw.texcoords[3], .15) and near(o.fw.texcoords[4], .4))
A.Paint(o, 60, 100, 0, "clean", 1, 1, 1, 1, "overlay", "always", false, false, 200, 20)
assert(not o.fw:IsShown() and not o.os:IsShown())
A.Paint(o, 60, 100, 25, "none", 1, 1, 1, 1, "overlay", "always", false, false, 200, 20)
assert(not o.fw:IsShown())
A.Paint(o, 60, 100, 25, "stripedStretch", 1, 1, 1, 1, "overlay", "always", false, false, 200, 20, nil, {stripedStretch = A.STYLES.stripedStretch})
assert(o.fw.texture:find("striped3.tga", 1, true) and seg(o.fw, .6, .85))
local values, order = A.StyleMenu({["sm:Foo"] = "Foo"}, {"flat", "sm:Foo"})
assert(order[1] == "none" and order[#order - 1] == "---" and order[#order] == "sm:Foo" and values["sm:Foo"] == "Foo")
''')

# A client with a genuine (secure) UnitGetTotalAbsorbs is used directly; an
# addon-defined global of the same name is ignored.
native = runtime('function UnitGetTotalAbsorbs(u) return u == "player" and 777 or 0 end; function issecurevariable() return true end')
native.execute('''
local A = EllesmereUI.Absorbs
local fired
EllesmereUI.RegisterAbsorbCallback("t", function(g) fired = g end)
assert(EllesmereUI.GetUnitAbsorb("player") == 777)
A.OnEvent(nil, "COMBAT_LOG_EVENT_UNFILTERED", 0, "SPELL_AURA_APPLIED", "x", nil, 0, "target", nil, 0, 17, "PW:S", 2, "BUFF")
assert(EllesmereUI.GetUnitAbsorb("target") == 0, "native mode ignores the log")
A.OnEvent(nil, "UNIT_ABSORB_AMOUNT_CHANGED", "player")
assert(fired == "player")
''')
fake = runtime('function UnitGetTotalAbsorbs() return 999 end; function issecurevariable(n) return n ~= "UnitGetTotalAbsorbs" end')
fake.execute('''
EllesmereUI.Absorbs.CombatLog(0, "SPELL_AURA_APPLIED", "x", nil, 0, "player", nil, 0, 17, "PW:S", 2, "BUFF")
assert(EllesmereUI.GetUnitAbsorb("player") == 44, "addon-defined UnitGetTotalAbsorbs is not the client API")
''')
print('PASS: 3.3.5 shield estimate (apply/refresh/remove, absorbed damage and ABSORB misses, school wards, own spell power, Divine Aegis, AMS, learned capacity, expiry, UNIT_AURA seed/clear, callbacks), native passthrough, overlay geometry and Wrath shield textures.')
