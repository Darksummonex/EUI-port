"""EUI alongside !!!ClassicAPI (3.3.5 polyfill addon).

ClassicAPI injects Frame.SetClipsChildren (reparents the frame into a ScrollFrame
sized at call time, so EUI dropdowns never open) and a Frame.CreateMaskTexture that
returns nil. EUI must not call either on its own frames, and must never replace them
on the shared widget metatables.
"""
from pathlib import Path
import re
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

core = root / 'EllesmereUI'
opts = root / 'EllesmereUIOptions'
uf = root / 'EllesmereUIUnitFrames'

compat = (core / 'EllesmereUI_3.3.5_Compat.lua').read_text(encoding='utf-8')
start = compat.index('local function EUI335_NoOp()')
end = compat.index('EUI335.OwnFrame = function(frame)')
end = compat.index('\nend\n', end) + len('\nend\n')
block = compat[start:end]

lua = LuaRuntime()
lua.execute(r'''
classic = { reparented = 0 }
local textureMT = { __index = {
    Hide = function(self) self.hidden = true end,
    SetTexture = function(self, path) self.path = path end,
} }
frameMethods = {
    SetPoint = function() end,
    CreateTexture = function(self) return setmetatable({}, textureMT) end,
    SetClipsChildren = function(self) classic.reparented = classic.reparented + 1 end,
    CreateMaskTexture = function() return nil end,
}
frameMT = { __index = frameMethods }
originalClip, originalMask = frameMethods.SetClipsChildren, frameMethods.CreateMaskTexture
function NewFrame() return setmetatable({}, frameMT) end
''')
lua.execute(block)
lua.execute(r'''
local owned = EUI335.OwnFrame(NewFrame())
owned:SetClipsChildren(true)
assert(classic.reparented == 0, "owned frame used ClassicAPI clipping")
local mask = owned:CreateMaskTexture()
assert(mask and mask.hidden and mask._eui335FakeMask, "owned frame mask")
mask:SetTexture("x")

local plain = NewFrame()
EUI335.SetClipsChildren(plain, true)
assert(classic.reparented == 0, "helper used ClassicAPI clipping")
local m2 = EUI335.CreateMaskTexture(plain)
assert(m2 and m2.hidden and m2._eui335FakeMask, "helper mask")
assert(EUI335.CreateMaskTexture(nil) == nil)
assert(EUI335.OwnFrame(nil) == nil)

assert(frameMethods.SetClipsChildren == originalClip, "shared metatable clip replaced")
assert(frameMethods.CreateMaskTexture == originalMask, "shared metatable mask replaced")
''')

ocompat = (opts / 'EllesmereUIOptions_3.3.5_Compat.lua').read_text(encoding='utf-8')
assert 'if EUI335 and EUI335.OwnFrame then EUI335.OwnFrame(frame) end' in ocompat

ufsrc = (uf / 'EUI_UnitFrames_335.lua').read_text(encoding='utf-8')
assert 'if obj.CreateTexture then obj.SetClipsChildren = noop end' in ufsrc

# Core files build frames with the raw CreateFrame: no direct calls allowed.
for name in ('EllesmereUI_Panel.lua', 'EUI_UnlockMode.lua', 'EllesmereUI_Glows.lua'):
    src = (core / name).read_text(encoding='utf-8')
    assert ':SetClipsChildren(' not in src, (name, 'direct SetClipsChildren')
glows = (core / 'EllesmereUI_Glows.lua').read_text(encoding='utf-8')
assert 'wrapper:CreateMaskTexture()' not in glows
assert 'local mask = EUI335.CreateMaskTexture(wrapper)' in glows
panel = (core / 'EllesmereUI_Panel.lua').read_text(encoding='utf-8')
for var in re.findall(r'local (\w+) = \w+:CreateMaskTexture\(\)', panel):
    assert re.search(r'local %s = \w+:CreateMaskTexture\(\)\s*\n(\s*--[^\n]*\n)?\s*if %s then' % (var, var), panel), var

# Options/UF files may call it only on frames from the patched factories.
FACTORY = ('local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame',
           'local CreateFrame = ns.Wrath and ns.Wrath.CreateFrame or EllesmereUI.CreateOptionsFrame or CreateFrame',
           'local CreateFrame, CreateColor = ns.Wrath.CreateFrame, ns.Wrath.CreateColor')
for path in (opts / 'EllesmereUI_Widgets.lua', opts / 'EUI__General_Options.lua',
             opts / 'EUI_Glows_Options.lua', opts / 'EUI_UnitFrames_Options.lua',
             uf / 'EllesmereUIUnitFrames.lua'):
    head = path.read_text(encoding='utf-8-sig').splitlines()[:12]
    assert any(line.strip() in FACTORY for line in head), (path.name, 'raw CreateFrame')

print('ClassicAPI compat validation passed')
