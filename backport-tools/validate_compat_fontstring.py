"""Core compat gives Wrath FontString:SetMaxLines/GetMaxLines and EditBox:HasFocus before
the Options addon loads, so Unlock Mode's mover snap dropdown builds without error, and
every other Retail-only widget call in EUI_UnlockMode.lua is shimmed, guarded or unreachable."""
from pathlib import Path
import re
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

mock = (root / 'backport-tools/wrath_mock.lua').read_text()
compat = (root / 'EllesmereUI/EllesmereUI_3.3.5_Compat.lua').read_text(encoding='utf-8-sig')
unlock = (root / 'EllesmereUI/EUI_UnlockMode.lua').read_text(encoding='utf-8-sig')

# Native Wrath 3.3.5 FontString wrap API the shim builds on (no SetMaxLines/HasFocus).
WRATH_EXTRA = r'''
GetBuildInfo=function() return "3.3.5","12340","Jun 24 2010",30300 end
local m=getmetatable(UIParent).__index
function m:SetWordWrap(v) self.wrap=v and true or false end
function m:CanWordWrap() return self.wrap~=false end
function m:SetNonSpaceWrap(v) self.nonSpace=v end
function m:SetSize(w,h) self:SetWidth(w); self:SetHeight(h) end
function m:EnableKeyboard(v) self.keyboard=v end
heightWrites=0
local setHeight=m.SetHeight
function m:SetHeight(v) heightWrites=heightWrites+1; return setHeight(self,v) end
'''


def runtime(with_compat, native=None):
    lua = LuaRuntime()
    lua.execute(mock)
    lua.execute(WRATH_EXTRA)
    if native:
        lua.execute(native)
    assert lua.eval('getmetatable(UIParent).__index.SetMaxLines') is None or native
    if with_compat:
        lua.execute(compat)
    return lua


# 1. Shim contract under the Wrath mock.
lua = runtime(True)
lua.execute(r'''
local fs=CreateFrame("Frame"):CreateFontString()
assert(type(fs.SetMaxLines)=="function" and type(fs.GetMaxLines)=="function", "FontString SetMaxLines missing after compat")
assert(fs:GetMaxLines()==0)
local h=heightWrites
-- n == 1: single-line truncation, wrap restored once the limit is lifted.
fs:SetMaxLines(1); assert(fs.wrap==false and fs:GetMaxLines()==1)
fs:SetMaxLines(2); assert(fs.wrap==true and fs:GetMaxLines()==2, "wrap not restored after 1 -> 2")
fs:SetMaxLines(1); fs:SetMaxLines(1); fs:SetMaxLines(0); assert(fs.wrap==true and fs:GetMaxLines()==0)
-- The caller's own SetWordWrap(false) is never undone (the Retail call sites pair them).
local nowrap=CreateFrame("Frame"):CreateFontString()
nowrap:SetWordWrap(false); nowrap:SetMaxLines(1); nowrap:SetMaxLines(0)
assert(nowrap.wrap==false, "shim re-enabled wrap the caller turned off")
-- n >= 2 records only: no forced height on wrapped text.
local wrapped=CreateFrame("Frame"):CreateFontString()
wrapped:SetWordWrap(true); wrapped:SetMaxLines(2)
assert(wrapped.wrap==true and wrapped:GetMaxLines()==2)
fs:SetMaxLines(-3); assert(fs:GetMaxLines()==0); fs:SetMaxLines(nil); assert(fs:GetMaxLines()==0)
assert(heightWrites==h, "SetMaxLines changed FontString height")
-- EditBox:HasFocus from the keyboard focus owner.
local eb=CreateFrame("EditBox")
focusOwner=nil
GetCurrentKeyBoardFocus=function() return focusOwner end
assert(eb:HasFocus()==false); focusOwner=eb; assert(eb:HasFocus()==true)
GetCurrentKeyBoardFocus=nil; assert(eb:HasFocus()==false)
-- The compat probe EditBox never takes keyboard focus.
local probes=0
for _,f in ipairs(allFrames) do
    if f.kind=="EditBox" and f~=eb then
        probes=probes+1
        assert(f.autoFocus==false and f.focus==false and f.shown==false and f.keyboard==false, "probe EditBox can take focus")
    end
end
assert(probes==1, probes)
''')

# Native methods (later clients / foreign polyfills loaded earlier) are left untouched.
nat = runtime(True, native=r'''
local m=getmetatable(UIParent).__index
nativeSML=function() end; nativeHF=function() return "native" end
m.SetMaxLines=nativeSML; m.HasFocus=nativeHF
''')
assert nat.eval('getmetatable(UIParent).__index.SetMaxLines==nativeSML and getmetatable(UIParent).__index.HasFocus==nativeHF')

# 2. The real Unlock Mode snap dropdown block (EUI_UnlockMode.lua, in CreateMover).
start = '    local snapDD = CreateFrame("Button", nil, unlockFrame)'
stop = '    mover._refreshSnapDD = RefreshSnapDDState'
assert start in unlock and stop in unlock, 'snap dropdown block moved'
block = unlock.split(start, 1)[1].split(stop, 1)[0]
assert 'snapDDLbl:SetMaxLines(1)' in block
block = start + block + stop
HARNESS = r'''
unlockFrame=CreateFrame("Frame",nil,UIParent)
EllesmereUI.MakeBorder=function() return {SetColor=function() end} end
EllesmereUI.MakeDropdownArrow=function(p) return p:CreateTexture() end
EllesmereUI.L=function(s) return s end
EllesmereUI.ShowWidgetTooltip=function() end
EllesmereUI.HideWidgetTooltip=function() end
'''
runner = ('function(snapEnabled) local mover=CreateFrame("Button",nil,unlockFrame)\n'
          'local DD_W, FONT_PATH = 180, "Fonts\\\\FRIZQT__.TTF"\n' + block +
          '\nreturn mover, snapDD, snapDDLbl end')

before = runtime(False)
before.execute(HARNESS)
before.execute('getmetatable(UIParent).__index.SetColorTexture=function() end')
try:
    before.eval(runner)(True)
    raise AssertionError('snap dropdown built without the shim: test no longer reproduces the crash')
except Exception as exc:  # lupa.LuaError
    assert 'SetMaxLines' in str(exc), exc

lua.execute(HARNESS)
make = lua.eval(runner)
for enabled in (True, False):
    mover, dd, lbl = make(enabled)
    assert lbl.GetMaxLines(lbl) == 1 and lbl.wrap is False and lbl.text == 'Snap to: Auto'
    for script in ('OnEnter', 'OnLeave'):
        dd.GetScript(dd, script)(dd)
    mover._refreshSnapDD()

# 3. Retail-only widget calls left in EUI_UnlockMode.lua: shimmed, feature-tested or unreachable.
SHIMMED = {'SetMaxLines', 'GetMaxLines', 'HasFocus', 'SetColorTexture', 'SetGradient'}
for name in ('SetMaxLines', 'GetMaxLines', 'HasFocus', 'SetColorTexture'):
    assert re.search(r'\b%s\s*=\s*function' % name, compat), name + ' not shimmed by core compat'
RETAIL_ONLY = {
    'SetClipsChildren', 'SetSnapToPixelGrid', 'SetTexelSnappingBias', 'CreateLine', 'RegisterUnitEvent',
    'SetPropagateKeyboardInput', 'SetIgnoreParentScale', 'SetIgnoreParentAlpha', 'SetMouseClickEnabled',
    'SetMouseMotionEnabled', 'CreateMaskTexture', 'AddMaskTexture', 'RemoveMaskTexture', 'SetAtlas',
    'SetResizeBounds', 'SetObeyStepOnDrag', 'SetTextScale', 'GetUnboundedStringWidth', 'SetShown',
    'SetAlphaFromBoolean', 'GetScaledRect', 'SetFlattensRenderLayers', 'SetIsFrameBuffer',
    'SetFixedFrameStrata', 'SetFixedFrameLevel', 'IsMouseMotionFocus', 'SetCollapsesLayout',
}
# Line objects only exist where CreateLine does, so a CreateLine test guards their methods.
GUARD_ALIAS = {
    'SetSnapToPixelGrid': ('SetSnapToPixelGrid', 'CreateLine'),
    'SetTexelSnappingBias': ('SetTexelSnappingBias', 'SetSnapToPixelGrid', 'CreateLine'),
}
assert ':SetRotatesTexture(' not in unlock, 'SetRotatesTexture crashes Wrath'
lines = unlock.split('\n')


def span(first, last):
    a = unlock.index(first)
    b = unlock.index(last, a)
    return unlock.count('\n', 0, a), unlock.count('\n', 0, b)


# SetPropagateKeyboardInput only runs on keyboard frames Wrath never enables.
arrow = span('local function SetupArrowKeyFrame()', 'local function GetActionBarVisualSize')
assert 'if _G.EUI_WOW_335 then return end' in '\n'.join(lines[arrow[0]:arrow[0] + 6])
keydown = span('unlockFrame:SetScript("OnKeyDown"', '\n    end)\n')
assert 'unlockFrame:EnableKeyboard(not _G.EUI_WOW_335)' in unlock
unreachable = {'SetPropagateKeyboardInput': [arrow, keydown]}

bad = []
for i, text in enumerate(lines):
    for name in re.findall(r':([A-Z]\w*)\(', text):
        if name not in RETAIL_ONLY or name in SHIMMED:
            continue
        window = '\n'.join(lines[max(0, i - 4):i + 1])
        if any(re.search(r'\.%s\b' % g, window) for g in GUARD_ALIAS.get(name, (name,))):
            continue
        if any(a <= i <= b for a, b in unreachable.get(name, ())):
            continue
        bad.append('%d: %s' % (i + 1, text.strip()))
assert not bad, 'Unguarded Retail-only calls in EUI_UnlockMode.lua:\n' + '\n'.join(bad)

print('PASS: Wrath FontStrings get SetMaxLines/GetMaxLines from core compat (1 line = no wrap, '
      'wrap restored when lifted, larger limits leave height alone), EditBoxes get HasFocus without a '
      'focus-stealing probe, native methods are kept; the real Unlock Mode snap dropdown fails on '
      'SetMaxLines without the shim and builds/hovers/refreshes with it; no unguarded Retail-only '
      'widget calls remain in EUI_UnlockMode.lua.')
