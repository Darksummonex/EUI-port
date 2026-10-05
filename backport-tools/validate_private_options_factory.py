"""Verify Options never replaces the native frame factory; test EUI adapters."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
lua=LuaRuntime()
lua.execute((root/'backport-tools/wrath_mock.lua').read_text())
lua.execute('''
local m=getmetatable(UIParent).__index
function m:CreateAnimationGroup() return CreateFrame('AnimationGroup',nil,self) end
function m:CreateAnimation(kind) return CreateFrame(kind,nil,self) end
function m:SetChange(value) self.change=value end
function m:IsVisible() return self:IsShown() and (not self.parent or self.parent:IsVisible()) end
function m:EnableKeyboard(value) self.keyboard=value end
function m:EnableMouse(value) self.mouse=value end
local create=CreateFrame
function CreateFrame(kind,name,parent,template,id)
    assert(not template or not template:find('BackdropTemplate',1,true) and not template:find('CooldownFrameTemplate',1,true),'Retail template reached native factory')
    local f=create(kind,name,parent,template); f.template=template; f.id=id
    if kind=='EditBox' then f.autoFocus=true; f.focus=f:IsVisible() end
    return f
end
nativeFactory=CreateFrame
''')
compat=(root/'EllesmereUIOptions/EllesmereUIOptions_3.3.5_Compat.lua').read_text(encoding='utf-8-sig')
lua.execute(compat)
lua.execute('''
assert(CreateFrame==nativeFactory and EUI335_CreateFramePatched==nil,'Options replaced native CreateFrame')
-- Compatibility probes used to be visible native autofocus EditBoxes.
-- Closing/reopening other UI must never give one of these keyboard focus.
for _,probe in ipairs(allFrames) do
    if probe.kind=='EditBox' then
        assert(not probe:IsVisible() and not probe.focus and probe.autoFocus==false and probe.keyboard==false,'Compatibility probe captures gameplay keys')
        for i=1,6 do
            probe:Show(); assert(not probe:IsVisible()); probe:Hide()
            assert(not probe.focus,'Probe acquired focus during Escape cycle')
        end
    end
end
local make=EllesmereUI.CreateOptionsFrame; assert(type(make)=='function' and make~=nativeFactory)
local f=make('Button','PrivateOptionsTest',UIParent,'BackdropTemplate, SecureHandlerBaseTemplate, CooldownFrameTemplate',7)
assert(f.template=='SecureHandlerBaseTemplate' and f.id==7)
local edit=make('EditBox',nil,f); assert(edit.autoFocus==false and edit.hooks.OnHide)
edit.focus=true; edit.hooks.OnHide(edit); assert(not edit.focus)
local nativeEdit=CreateFrame('EditBox',nil,UIParent)
assert(nativeEdit.autoFocus==true and nativeEdit.hooks.OnHide==nil,'EUI focus rules affected native windows')
savedPrivate=make
''')
lua.execute(compat)
lua.execute('assert(CreateFrame==nativeFactory and EllesmereUI.CreateOptionsFrame==savedPrivate)')
for line in (root/'EllesmereUIOptions/EllesmereUIOptions.toc').read_text().splitlines():
    line=line.strip()
    if not line or line.startswith('#') or not line.endswith('.lua') or line=='EllesmereUIOptions_3.3.5_Compat.lua': continue
    source=(root/'EllesmereUIOptions'/line.replace('\\','/')).read_text(encoding='utf-8-sig')
    if 'CreateFrame(' in source:
        assert 'local CreateFrame = ' in source and 'EllesmereUI.CreateOptionsFrame' in source,line
for file in ['EllesmereUI_Panel.lua','EllesmereUI_GlobalSearch.lua']:
    source=(root/'EllesmereUI'/file).read_text(encoding='utf-8-sig')
    assert 'local nativeCreateFrame = CreateFrame' in source and 'EllesmereUI.CreateOptionsFrame or nativeCreateFrame' in source,file
print('PASS: compatibility probes hidden/unfocused with keyboard disabled across repeated show/hide cycles; native CreateFrame unchanged; private template/focus behavior; native windows untouched; active option builders and panel/search scoped.')
