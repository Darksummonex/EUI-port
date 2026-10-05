"""Colour picker on Wrath: Retail texture contract over foreign polyfills, then the real popup."""
from pathlib import Path
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

# Core compat replaces a foreign SetColorTexture polyfill and makes gradients render.
lua = LuaRuntime()
lua.execute((root / 'backport-tools/wrath_mock.lua').read_text())
lua.execute(r'''
function GetBuildInfo() return "3.3.5","12340","Jun 24 2010",30300 end
local m=getmetatable(CreateFrame("Frame"):CreateTexture()).__index
function m:SetTexture(...) self.texArgs={...}; self.texture=(...) end
function m:SetGradient(...) self.nativeGradient={...} end
function m:SetGradientAlpha(...) self.gradient={...} end
function m:SetAlpha(a) self.alpha=a end
-- AruiQOL's polyfill loads first (alphabetical) and applies alpha through SetAlpha.
m.SetColorTexture=function(self,r,g,b,a) self:SetTexture(r,g,b); if a then self:SetAlpha(a) end end
''')
lua.execute((root / 'EllesmereUI/EllesmereUI_3.3.5_Compat.lua').read_text(encoding='utf-8-sig'))
lua.execute(r'''
local t=CreateFrame("Frame"):CreateTexture()
t:SetColorTexture(.1,.2,.3,0)
assert(t.alpha==nil and t.texArgs[1]==.1 and t.texArgs[4]==0, "alpha must stay on the colour texture")
t:SetColorTexture(1,1,1)
assert(t.texArgs[4]==1 and t.alpha==nil)
t:SetGradient("VERTICAL",CreateColor(0,0,0,1),CreateColor(0,0,0,0))
assert(t.texture=="Interface\\Buttons\\WHITE8X8", "solid textures move onto a file before a gradient")
local g=t.gradient
assert(g[1]=="VERTICAL" and g[5]==1 and g[9]==0 and #g==9)
-- Repeated gradients (alpha bar during drags) keep the file and only update colours.
t.texArgs=nil; t:SetGradient("VERTICAL",{r=1,g=0,b=0,a=0},{r=1,g=0,b=0,a=1})
assert(t.texArgs==nil and t.gradient[2]==1 and t.gradient[9]==1)
local art=CreateFrame("Frame"):CreateTexture()
art:SetTexture("Interface\\Some\\Art")
art:SetGradient("HORIZONTAL",CreateColor(1,1,1,1),CreateColor(1,1,1,0))
assert(art.texture=="Interface\\Some\\Art" and art.gradient)
art:SetGradient("HORIZONTAL",1,1,1,0,0,0)
assert(art.nativeGradient and art.nativeGradient[2]==1)
assert(getmetatable(t).__index._euiGradient)
''')

# Real picker popup: colour square, hue bar and hex input.
src = (root / 'backport-tools/validate_widgets.py').read_text()
head = src[:src.index("lua.execute('''\nlocal E=EllesmereUI\nE._deferredInits[1]()")]
head = head.replace(
    "E.MakeDropdownArrow=function(parent) return parent:CreateTexture() end",
    "E.MakeDropdownArrow=function(parent) return parent:CreateTexture() end\n"
    "E.MEDIA_PATH='m/'; E.RB_COLOURS={}\n"
    "E.MakeStyledButton=function(btn,text,size,colours,onClick) btn:SetScript('OnClick',onClick) end\n"
    "CreateColor=function(r,g,b,a) return {r=r,g=g,b=b,a=a} end")
scope = {'__file__': str(Path(__file__))}
exec(head, scope)
lua = scope['lua']
lua.execute(r'''
local E=EllesmereUI
E._deferredInits[1]()
C_Timer={After=function(_,f) f() end}
E.RegisterEscapeClose=function() end
E.PadCP=function() return false end
local methods=getmetatable(CreateFrame("Frame")).__index
local tm=getmetatable(CreateFrame("Frame"):CreateTexture()).__index
for _,t in ipairs({methods,tm}) do setmetatable(t,{__index=function() return function() end end}) end
methods.GetLeft=function() return 0 end
methods.GetBottom=function() return 0 end
methods.GetTop=function() return 200 end
local pads,hex={},nil
local setScript=methods.SetScript
methods.SetScript=function(self,name,fn)
    if name=='OnMouseDown' and fn then pads[#pads+1]=self end
    if name=='OnEnterPressed' and self.kind=='EditBox' and not hex then hex=self end
    return setScript(self,name,fn)
end
cursorX,cursorY=100,150
GetCursorPosition=function() return cursorX,cursorY end
local picks={}
local info={r=1,g=.9,b=.4,cancelFunc=function() end,swatchFunc=function()
    local r,g,b=E._colorPickerPopup:GetColorRGB(); picks[#picks+1]={r,g,b}
end}
-- In game, children that kept their automatic level drew under the popup background; model
-- that tie and a level cap so only explicitly raised content passes.
EUI_WOW_335=true
methods.SetFrameLevel=function(self,l) rawset(self,'level',l) end
methods.GetFrameLevel=function(self)
    local level,parent=rawget(self,'level'),rawget(self,'parent')
    if level then return level end
    return parent and parent:GetFrameLevel() or 0
end
E:ShowColorPicker(info)
assert(hex and hex:GetText()=='FFE666', tostring(hex and hex:GetText()))
local popup=E._colorPickerPopup
local base=popup:GetFrameLevel()
local regions,closeTex=0,nil
local function Walk(f)
    for _,c in ipairs(f.children) do
        if c.kind=='Texture' or c.kind=='FontString' then
            if f~=popup then
                regions=regions+1
                assert(f:GetFrameLevel()>base, 'content region under the popup background on a '..f.kind)
            end
            if type(c.texture)=='string' and c.texture:find('close') then closeTex=c.texture end
        else
            assert(c:GetFrameLevel()<256, 'frame level over the Wrath cap: '..c:GetFrameLevel())
            Walk(c)
        end
    end
end
assert(base<256)
Walk(popup)
assert(regions>20, regions)
assert(closeTex and closeTex:find('icons_335\\close%-popup%-4%.tga$') and not closeTex:find('%.png'), tostring(closeTex))
local function Hex(c) return string.format('%02X%02X%02X',math.floor(c[1]*255+.5),math.floor(c[2]*255+.5),math.floor(c[3]*255+.5)) end
local sv,hue=pads[1],pads[2]
sv:GetScript('OnMouseDown')(sv,'LeftButton')
local first=picks[#picks]
-- Cursor at 50% across / 75% up the square: saturation .5, value .75 at the opening hue.
assert(first and math.abs(first[1]-.75)<.01 and math.abs(first[3]-.375)<.01)
assert(hex:GetText()==Hex(first), hex:GetText())
cursorY=60; sv:GetScript('OnUpdate')(sv)
assert(math.abs(picks[#picks][1]-.3)<.01 and hex:GetText()==Hex(picks[#picks]), hex:GetText())
local beforeHue=hex:GetText()
cursorY=100; hue:GetScript('OnMouseDown')(hue,'LeftButton')
assert(hex:GetText()~=beforeHue and hex:GetText()==Hex(picks[#picks]), hex:GetText())
local afterHue=hex:GetText()
-- One failing step must not lock the picker: the next drag still updates the hex.
local hasFocus=methods.HasFocus
local errors={}
geterrorhandler=function() return function(err) errors[#errors+1]=err end end
methods.HasFocus=function() error('boom') end
cursorY=150; sv:GetScript('OnMouseDown')(sv,'LeftButton')
assert(#errors==1)
methods.HasFocus=hasFocus
cursorY=20; sv:GetScript('OnMouseDown')(sv,'LeftButton')
assert(hex:GetText()~=afterHue and hex:GetText()==Hex(picks[#picks]) and #errors==1, hex:GetText())
''')
assert((root / 'EllesmereUI/media/icons_335/close-popup-4.tga').exists())
print('PASS: Wrath colour textures keep alpha over foreign polyfills, Retail gradients move solid textures onto a file and render; real picker content sits above the popup under the level cap with a TGA close icon; colour square, hue bar and hex update, and recover after a failing step.')
