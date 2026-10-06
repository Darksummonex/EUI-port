"""3.3.5 options popups: screen-level nameless frames made by EllesmereUI.CreateOptionsFrame
keep every child above its parent on show and turn a nearly opaque solid background into an
opaque tinted file (some clients draw popup rows under the popup's background and render
solid colour textures see-through)."""
from pathlib import Path
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime


def read(rel):
    return (root / rel).read_text(encoding='utf-8-sig')


compat = read('EllesmereUIOptions/EllesmereUIOptions_3.3.5_Compat.lua')
block = compat[compat.index('-- 1. CreateFrame'):compat.index('-- 2. Widget-method shims')]
block = block[block.index('\ndo\n'):]

lua = LuaRuntime()
lua.execute(r'''
EllesmereUI = {}
local M = {}
M.__index = M
function M:GetFrameLevel() return self.level end
function M:SetFrameLevel(v) self.level = v end
function M:GetChildren() return unpack(self.kids) end
function M:GetRegions() return unpack(self.regions) end
function M:HookScript(ev, fn) self.hooks[ev] = self.hooks[ev] or {}; table.insert(self.hooks[ev], fn) end
function M:SetScript(ev, fn) self.scripts[ev] = fn end
function M:GetName() return self.name end
function M:Show() self.shown = true; for _, fn in ipairs(self.hooks.OnShow or {}) do fn(self) end end
function M:Hide() self.shown = false end
function M:IsShown() return self.shown end
function M:SetAutoFocus() end
function M:ClearFocus() end
function M:CreateTexture(_, layer)
    local t = { layer = layer or "ARTWORK" }
    function t:GetDrawLayer() return self.layer end
    function t:SetTexture(v) self.tex = v end
    function t:SetVertexColor(r, g, b, a) self.vc = { r, g, b, a } end
    table.insert(self.regions, t)
    return t
end
frames = {}
function CreateFrame(kind, name, parent)
    local f = setmetatable({ kind = kind, name = name, parent = parent, kids = {}, regions = {},
        hooks = {}, scripts = {}, shown = true, level = parent and parent.level + 1 or 0 }, M)
    if parent then table.insert(parent.kids, f) end
    frames[#frames + 1] = f
    return f
end
UIParent = CreateFrame("Frame", "UIParent")
''')
lua.execute(block)
r = lua.execute(r'''
local C = EllesmereUI.CreateOptionsFrame
local pop = C("Frame", nil, UIParent)
pop:Hide(); pop.level = 200
local bg = pop:CreateTexture(nil, "BACKGROUND")
bg._euiSolid, bg._euiR, bg._euiG, bg._euiB, bg._euiA = true, .1, .1, .12, .98
local dim = pop:CreateTexture(nil, "BACKGROUND")
dim._euiSolid, dim._euiR, dim._euiG, dim._euiB, dim._euiA = true, 0, 0, 0, .5
local row = C("Button", nil, pop); row.level = 150
local label = C("Frame", nil, row); label.level = 100
local named = C("Frame", "EllesmereUIFrame", UIParent); named:Hide()
local inner = C("Frame", nil, named); inner:Hide()
pop:Show()
local out = {}
out[1] = row.level > pop.level and label.level > row.level
out[2] = bg.tex == "Interface\\Buttons\\WHITE8X8" and bg.vc and bg.vc[4] == 1 and bg.vc[1] == .1
out[3] = dim.tex == nil
out[4] = named.hooks.OnShow == nil and inner.hooks.OnShow == nil
-- settle pass: the shared driver re-fixes once on the next frame
row.level = 1
local driver
for _, f in ipairs(frames) do if f.scripts.OnUpdate then driver = f end end
out[5] = driver ~= nil
if driver then driver.scripts.OnUpdate(driver) end
out[6] = row.level > pop.level
out[7] = type(EllesmereUI._FixOptionsPopup) == "function"
return unpack(out)
''')
assert all(x is True for x in r), r

core = read('EllesmereUI/EllesmereUI_3.3.5_Compat.lua')
assert 'self._euiR, self._euiG, self._euiB, self._euiA = r, g, b, a' in core, 'SetColorTexture shim must record its colour'
assert 'name == nil and frame.HookScript' in compat, 'only nameless popups are hooked'

compiled = lua.execute('return function(src) local f, e = loadstring(src) if not f then return e end return true end')
for rel in ('EllesmereUIOptions/EllesmereUIOptions_3.3.5_Compat.lua', 'EllesmereUI/EllesmereUI_3.3.5_Compat.lua'):
    res = compiled(read(rel))
    assert res is True, f'{rel}: {res}'

print('popup layers OK')
