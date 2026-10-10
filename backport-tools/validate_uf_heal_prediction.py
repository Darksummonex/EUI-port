"""Unit Frames 3.3.5 incoming heals (EUI_UnitFrames_335_HealPred.lua) over LibHealComm-4.0."""
from pathlib import Path
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

uf = root / 'EllesmereUIUnitFrames'
toc = [l.strip() for l in (uf / 'EllesmereUIUnitFrames.toc').read_text(encoding='utf-8-sig').splitlines()]
for lib in ('Libs\\ChatThrottleLib\\ChatThrottleLib.lua', 'Libs\\LibHealComm-4.0\\LibHealComm-4.0.lua'):
    assert lib in toc and (uf / lib.replace('\\', '/')).exists(), lib
    assert toc.index(lib) < toc.index('EUI_UnitFrames_335.lua'), lib
assert toc.index('EUI_UnitFrames_335_Absorbs.lua') < toc.index('EUI_UnitFrames_335_HealPred.lua')
rf = root / 'EllesmereUIRaidFrames' / 'Libs' / 'LibHealComm-4.0' / 'LibHealComm-4.0.lua'
assert rf.read_bytes() == (uf / 'Libs' / 'LibHealComm-4.0' / 'LibHealComm-4.0.lua').read_bytes(), 'lib copies differ'

src = (uf / 'EUI_UnitFrames_335_HealPred.lua').read_text(encoding='utf-8')
lua = LuaRuntime()
lua.execute(r'''
now = 100
function GetTime() return now end
guids = { player = "P", target = "T" }
function UnitGUID(u) return guids[u] end
function UnitExists(u) return guids[u] ~= nil end
pending = { mine = 0, others = 0, mod = 1 }
callbacks = {}
HC = { ALL_HEALS = 15 }
function HC:GetHealModifier() return pending.mod end
function HC:GetHealAmount(guid, flag, t, caster)
    assert(caster == "P" and flag == 15 and t == now + 4)
    return pending.mine > 0 and pending.mine or nil
end
function HC:GetOthersHealAmount() return pending.others > 0 and pending.others or nil end
function HC.RegisterCallback(owner, event, fn) callbacks[event] = fn end
LibStub = function(name) assert(name == "LibHealComm-4.0"); return HC end
events = {}
function CreateFrame()
    return { RegisterEvent = function(_, e) events[e] = true end,
             SetScript = function(self, _, fn) self.onEvent = fn end }
end
local function Tex()
    local t = { shown = false, points = {} }
    function t:Hide() self.shown = false end
    function t:Show() self.shown = true end
    function t:ClearAllPoints() self.points = {} end
    function t:SetPoint(p, rel, rp, x, y) self.points[#self.points + 1] = { p, x, y } end
    function t:SetWidth(w) self.w = w end
    function t:SetHeight(h) self.h = h end
    function t:SetTexCoord(...) self.coords = { ... } end
    function t:SetTexture(p) self.path = p end
    function t:SetVertexColor(r, g, b, a) self.color = { r, g, b, a } end
    return t
end
function NewFrame()
    local hooks = {}
    local bar = { value = 50, min = 0, max = 100, width = 200, height = 20, hooks = hooks }
    function bar:GetMinMaxValues() return self.min, self.max end
    function bar:GetValue() return self.value end
    function bar:GetWidth() return self.width end
    function bar:GetHeight() return self.height end
    function bar:GetOrientation() return self.orient or "HORIZONTAL" end
    function bar:CreateTexture() return Tex() end
    function bar:GetStatusBarTexture() return { GetTexture = function() return "health.tga" end } end
    function bar:HookScript(s, fn) hooks[s] = fn end
    local f = { Health = bar, shown = true }
    function f:IsShown() return self.shown end
    function f:HookScript(s, fn) hooks["frame" .. s] = fn end
    return f
end
EllesmereUI = { ResolveTexturePath = function(_, key) return "tex/" .. key end }
profile = { player = { healPrediction = true }, target = { healPrediction = true, healPredOpacity = 50,
    healPredColor = { r = 1, g = 0, b = 0 }, healPredOtherColor = { r = 0, g = 0, b = 1 } } }
ns = { db = { profile = profile }, healthBarTextures = {},
       UF_HEAL_PRED_MY = { r = .4, g = .95, b = .4 }, UF_HEAL_PRED_OTHER = { r = .15, g = .67, b = .15 } }
attached = {}
function ns.UF_AttachEngineFrame(frame, unit) attached[#attached + 1] = unit end
reloaded = 0
function ns.UF_ReloadAllAuraContainers() reloaded = reloaded + 1 end
''')
lua.execute('local chunk = assert(loadstring(...)); chunk("EllesmereUIUnitFrames", ns)', src)
lua.execute(r'''
assert(events.PLAYER_TARGET_CHANGED and events.UNIT_MAXHEALTH and events.PLAYER_FOCUS_CHANGED)
for _, e in ipairs({ "HealComm_HealStarted", "HealComm_HealUpdated", "HealComm_HealDelayed",
    "HealComm_HealStopped", "HealComm_ModifierChanged", "HealComm_GUIDDisappeared" }) do
    assert(callbacks[e], e)
end
local f = NewFrame()
ns.UF_AttachEngineFrame(f, "target")
assert(attached[1] == "target", "original attach kept")
local o = f._euiWrathHealPred
assert(o and not o.my.shown and not o.other.shown)
local boss = NewFrame()
ns.UF_AttachEngineFrame(boss, "boss1")
assert(not boss._euiWrathHealPred, "only player/target/focus")

-- 20 mine + 10 others on a half-full 200px bar.
pending.mine, pending.others = 20, 10
callbacks.HealComm_HealStarted("HealComm_HealStarted", "P", 1, 1, 0, "X", "T")
assert(o.my.shown and o.other.shown)
assert(o.my.w == 40 and o.other.w == 20, "segment widths")
assert(o.my.points[1][2] == 100 and o.other.points[1][2] == 140, "segments start at the fill edge")
assert(o.my.color[1] == 1 and o.my.color[4] == .5 and o.other.color[3] == 1)
assert(o.my.path == "health.tga", "health texture by default")
assert(math.abs(o.my.coords[1] - .5) < 1e-9 and math.abs(o.my.coords[2] - .7) < 1e-9)

-- Overheal 0: capped at the missing health, yours first.
pending.mine, pending.others = 40, 40
callbacks.HealComm_HealUpdated("HealComm_HealUpdated", "P", 1, 1, 0, "T")
assert(o.my.w == 80 and o.other.w == 20, "clamped to missing health")
-- Overheal 10%: 10 more value units of room.
profile.target.healPredOverheal = 10
f.Health.hooks.OnValueChanged()
assert(o.my.w == 80 and o.other.w == 40, "overheal allowance")
profile.target.healPredOverheal = nil

-- Healing modifier scales both.
pending.mine, pending.others, pending.mod = 10, 0, 1.5
callbacks.HealComm_ModifierChanged("HealComm_ModifierChanged", "T")
assert(o.my.w == 30 and not o.other.shown)
pending.mod = 1

-- Vertical fill stacks upwards.
f.Health.orient = "VERTICAL"
f.Health.hooks.OnSizeChanged()
assert(o.my.h == 2 and o.my.points[1][3] == 10, "vertical segment")
f.Health.orient = nil

-- Other GUIDs do not repaint; full health hides; turning the option off hides.
o.my.w = nil
callbacks.HealComm_HealStarted("HealComm_HealStarted", "P", 1, 1, 0, "SOMEONE")
assert(o.my.w == nil)
f.Health.value = 100
f.Health.hooks.OnValueChanged()
assert(not o.my.shown and not o.other.shown, "full health")
f.Health.value = 50
profile.target.healPrediction = false
ns.UF_ReloadAllAuraContainers()
assert(reloaded == 1 and not o.my.shown, "off hides")
profile.target.healPrediction = true
profile.target.healPredTexture = "flat"
f.Health.hooks.OnValueChanged()
assert(o.my.path == "Interface\\Buttons\\WHITE8X8")
profile.target.healPredTexture = "smooth"
f.Health.hooks.OnValueChanged()
assert(o.my.path == "tex/smooth")
pending.mine = 0
f.Health.hooks.OnValueChanged()
assert(not o.my.shown, "no heals")
''')
print('Unit Frames heal prediction validation passed')
