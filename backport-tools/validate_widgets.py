"""Run real widget setters/handlers with and without the optional capture hook."""
from pathlib import Path
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

lua = LuaRuntime()
lua.execute((root / 'backport-tools/wrath_mock.lua').read_text())
ns = lua.table()
lua.execute((root/'EllesmereUIUnitFrames/EUI_UnitFrames_335.lua').read_text(), 'EllesmereUIUnitFrames', ns)
lua.globals().W = ns.Wrath
lua.execute('''
CreateFrame=W.CreateFrame
local methods=getmetatable(CreateFrame("Frame")).__index
for _, name in ipairs({"SetIgnoreParentAlpha","SetNumeric","SetMaxLetters","RegisterForDrag","HighlightText","SetCursorPosition"}) do
    methods[name]=function() end
end
methods.HasFocus=function(self) return self.focus==true end
cursorX=50
GetCursorPosition=function() return cursorX,0 end
IsMouseButtonDown=function() return true end
local E=EllesmereUI
E._deferredInits={}
E.PanelPP=E.PP
E.PP.Scale=function(value) return value end
E.CS={BRD_THICK=1}
E.L=function(s) return s end
E.PadHint=function() end
E.PadCursorShown=function() return false end
E.RegisterWidgetRefresh=function() end
E.RegAccent=function() end
E.DisablePixelSnap=function() end
E.RefreshPage=function() end
E.lerp=function(a,b,t) return a+(b-a)*t end
E.ELLESMERE_GREEN={r=.05,g=.82,b=.62}
E.DARK_BG={r=.1,g=.1,b=.1}
E.TEXT_WHITE={r=1,g=1,b=1}
E.CONTENT_PAD=45
E.BORDER_R,E.BORDER_G,E.BORDER_B=1,1,1
E.EXPRESSWAY="Fonts\\\\FRIZQT__.TTF"
for _, name in ipairs({"SL_TRACK_R","SL_TRACK_G","SL_TRACK_B","SL_TRACK_A","SL_FILL_A",
    "SL_INPUT_R","SL_INPUT_G","SL_INPUT_B","SL_INPUT_A","SL_INPUT_BRD_A",
    "MW_INPUT_ALPHA_BOOST","MW_TRACK_ALPHA_BOOST","TEXT_DIM_R","TEXT_DIM_G","TEXT_DIM_B","TEXT_DIM_A",
    "TG_OFF_R","TG_OFF_G","TG_OFF_B","TG_OFF_A","TG_ON_A",
    "TG_KNOB_OFF_R","TG_KNOB_OFF_G","TG_KNOB_OFF_B","TG_KNOB_OFF_A",
    "TG_KNOB_ON_R","TG_KNOB_ON_G","TG_KNOB_ON_B","TG_KNOB_ON_A"}) do E[name]=.5 end
E.SolidTex=function(parent,layer,...) local t=parent:CreateTexture(); t:SetColorTexture(...); return t end
E.MakeFont=function(parent) return parent:CreateFontString() end
E.MakeBorder=function() return {SetColor=function() end} end
E.MakeDropdownArrow=function(parent) return parent:CreateTexture() end
''')
lua.execute((root/'EllesmereUIOptions/EllesmereUI_Widgets.lua').read_text())
lua.execute('''
local E=EllesmereUI
E._deferredInits[1]()
local function Upvalue(fn,wanted)
    for i=1,100 do
        local name,value=debug.getupvalue(fn,i)
        if not name then break end
        if name==wanted then return value end
    end
    error("missing upvalue: "..wanted)
end
local Slider=Upvalue(E.Widgets.Slider,"BuildSliderCore")
local owner=CreateFrame("Frame",nil,UIParent)
local value,writes=10,0
local track,input,refresh=Slider(owner,100,4,14,40,26,13,.5,0,100,1,
    function() return value end,function(v) value=v; writes=writes+1 end)
assert(E._NotifySettingWrite==nil)
track:GetScript("OnMouseDown")(track,"LeftButton")
assert(value==50 and writes==1 and E._settingsChanged)
cursorX=75; track:GetScript("OnUpdate")(track)
assert(value==75)
track:GetScript("OnMouseUp")(track,"LeftButton")
assert(not E._sliderDragging)
input:SetText("42"); input:GetScript("OnEnterPressed")(input)
assert(value==42 and input.autoFocus==false)
-- A hook supplied later is still called exactly once, after persisting the value.
local notified=0
E._NotifySettingWrite=function(host)
    assert(host==owner and value==37)
    notified=notified+1
end
E._settingsChanged=nil
input:SetText("37"); input:GetScript("OnEnterPressed")(input)
assert(value==37 and notified==1 and E._settingsChanged)
E._NotifySettingWrite=nil
input:SetText("41"); input:GetScript("OnEnterPressed")(input)
assert(value==41 and notified==1)
-- Toggle and color callbacks use the same optional notification contract.
local Toggle=Upvalue(E.Widgets.Toggle,"BuildToggleControl")
local on=false
local toggle=Toggle(owner,2,function() return on end,function(v) on=v end)
toggle:GetScript("OnClick")(toggle); assert(on==true)
E._NotifySettingWrite=function(host) assert(host==owner and on==false); notified=notified+1 end
toggle:GetScript("OnClick")(toggle); assert(on==false and notified==2)
E._NotifySettingWrite=nil
local rgba={1,1,1,1}
local colorInfo
E.ShowColorPicker=function(_,info) colorInfo=info end
E._colorPickerPopup={GetColorRGB=function() return .2,.3,.4 end,GetColorAlpha=function() return .5 end}
local swatch=E.BuildColorSwatch(owner,2,function() return unpack(rgba) end,
    function(...) rgba={...} end,true)
swatch:GetScript("OnClick")(swatch)
colorInfo.swatchFunc(); assert(rgba[1]==.2 and rgba[4]==.5)
colorInfo.cancelFunc(); assert(rgba[1]==1 and rgba[4]==1)
E._NotifySettingWrite=function(host) assert(host==owner and rgba[1]==.2); notified=notified+1 end
colorInfo.swatchFunc(); assert(rgba[1]==.2 and notified==3)
''')
print('PASS: real slider drag/release/typed commits, toggles, color changes/cancel and dirty state; capture hook absent/present/removed; EditBox autofocus.')
