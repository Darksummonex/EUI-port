"""Incompatible-addon popup: the real confirm popup's extra-button row and the
real conflict check offering to disable the other addon or the EUI module."""
from pathlib import Path
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

lua = LuaRuntime()
lua.execute((root / 'backport-tools/wrath_mock.lua').read_text())
lua.execute('''
local methods=getmetatable(UIParent).__index
local noop=function() end
setmetatable(methods,{__index=function(_,k) if type(k)=="string" and k:find("^%u") then return noop end end})
function methods:GetStringWidth() return #(self.text or "")*6 end
function methods:GetName() return self.name end
function methods:SetPoint(...) self.points=self.points or {}; self.points[#self.points+1]={...} end
function methods:ClearAllPoints() self.points={} end
function methods:GetPoint(i) return unpack((self.points or {})[i or 1] or {}) end
function methods:SetSize(w,h) self.width,self.height=w,h end
function GetPhysicalScreenSize() return 1920,1080 end
local E={}
_G.EllesmereUI=E
E.PanelPP={Size=function(f,w,h) f:SetSize(w,h) end,Point=function(f,...) f:SetPoint(...) end}
E.MakeFont=function(parent) return parent:CreateFontString() end
E.MakeBorder=function() return {SetColor=function() end} end
E.SolidTex=function(parent) return parent:CreateTexture() end
E.lerp=function(a,b,t) return a+(b-a)*t end
E.ELLESMERE_GREEN={r=0,g=1,b=.5}; E.BORDER_COLOR={r=1,g=1,b=1}; E.TEXT_DIM={r=1,g=1,b=1,a=.6}
E.L=function(s) return s end
E.Lf=function(s,...) return string.format(s:gsub("%%%d%$",""),...) end
E.PadInUse=function() return false end; E.PadCP=function() return false end
E.PadHint=function() end; E.PadFocus=function() end
''')
lua.execute((root / 'EllesmereUI/EllesmereUI_Popups.lua').read_text(encoding='utf-8-sig'))
lua.execute('''
local E=EllesmereUI
local clicked
E:ShowConfirmPopup({title="Plain",message="m"})
local popup=EUIConfirmPopup
assert(popup and popup:GetHeight()==176 and #(popup._extraBtns or {})==0,"Plain popup changed")
E:ShowConfirmPopup({title="Extras",message="m",extraButtons={
    {text="Disable Bagnon",onClick=function() clicked="addon" end},
    {text="Disable EUI Bags",onClick=function() clicked="module" end}}})
local a,b=popup._extraBtns[1],popup._extraBtns[2]
assert(popup:GetHeight()==176+37 and a:IsShown() and b:IsShown())
assert(a._lbl:GetText()=="Disable Bagnon" and b._lbl:GetText()=="Disable EUI Bags")
assert(a:GetPoint(1)=="BOTTOMRIGHT" and select(5,a:GetPoint(1))==50 and b:GetPoint(1)=="BOTTOMLEFT")
assert(a:GetWidth()>=125 and a:GetWidth()<=172 and a:GetWidth()+b:GetWidth()+16<390,"Two buttons must fit the popup")
assert(popup._dimmer:IsShown())
b:GetScript("OnClick")(b); assert(clicked=="module" and not popup._dimmer:IsShown())
E:ShowConfirmPopup({title="One",message="m",extraButtons={{text="Disable Something Long Enough",onClick=function() clicked="one" end}}})
assert(a:IsShown() and not b:IsShown() and a:GetPoint(1)=="BOTTOM" and popup:GetHeight()==213)
a:GetScript("OnClick")(a); assert(clicked=="one")
E:ShowConfirmPopup({title="Plain again",message="m"})
assert(not a:IsShown() and not b:IsShown() and popup:GetHeight()==176,"Pooled extra buttons leaked")
''')
core = (root / 'EllesmereUI/EllesmereUI.lua').read_text(encoding='utf-8-sig')
body = 'EllesmereUI._RunConflictCheck = function()' + core.split('EllesmereUI._RunConflictCheck = function()', 1)[1].split('\n-- Auto-run the conflict check', 1)[0]
lua.execute('local EUI_HOST_ADDON="EllesmereUI"\nlocal modules={EllesmereUIBags={title="Bags"},EllesmereUIActionBars={title="Action Bars"}}\n' + body)
lua.execute('''
local E=EllesmereUI
local popup=EUIConfirmPopup
loaded,disabledList,reloads={},{},{}
C_AddOns={IsAddOnLoaded=function(n) return loaded[n] or false end,DisableAddOn=function(n) disabledList[#disabledList+1]=n end}
function E.RequestReload(title,message) reloads[#reloads+1]={title,message} end
local function Run(set)
    loaded,disabledList,reloads=set,{},{}
    EllesmereUIDB={}; _G._EUI_ConflictCheckRan=nil
    E._RunConflictCheck()
end
Run({EllesmereUIBags=true,Bagnon=true})
assert(popup._title:GetText()=="Incompatible Addon Detected" and popup._msg:GetText():find("Bagnon is not compatible"))
local a,b=popup._extraBtns[1],popup._extraBtns[2]
assert(a:IsShown() and a._lbl:GetText()=="Disable Bagnon" and b:IsShown() and b._lbl:GetText()=="Disable EUI Bags")
assert(popup._confirmBtn._lbl:GetText()=="Okay" and popup._cancelBtn._lbl:GetText()=="Don't show again")
b:GetScript("OnClick")(b)
assert(#disabledList==1 and disabledList[1]=="EllesmereUIBags" and reloads[1][2]=="EllesmereUI Bags will be disabled after a reload.")
Run({EllesmereUIBags=true,Bagnon=true}); a:GetScript("OnClick")(a)
assert(#disabledList==1 and disabledList[1]=="Bagnon" and reloads[1][2]=="Bagnon will be disabled after a reload.")
Run({EllesmereUIBags=true,Bagnon=true}); popup._cancelBtn:GetScript("OnClick")()
assert(EllesmereUIDB.dismissedConflicts.Bagnon and #disabledList==0,"Don't show again still dismisses")
-- Whole-suite and custom-message conflicts only offer disabling the other addon.
Run({EllesmereUIActionBars=true,idTip=true})
assert(a:IsShown() and a._lbl:GetText()=="Disable idTip" and not b:IsShown() and a:GetPoint(1)=="BOTTOM")
Run({EllesmereUIBags=true,EllesmereUIActionBars=true,Bagnon=true,idTip=true})
assert(popup._msg:GetText():find("Bagnon") and b:IsShown())
popup._confirmBtn:GetScript("OnClick")()
assert(popup._msg:GetText():find("idTip") and not b:IsShown(),"Okay moves to the next conflict")
''')
print('PASS: confirm popup extra-button row (two/one/none, pooled reuse, sizing, click closes and runs), conflict popup offers Disable <addon> always and Disable EUI <module> for whole-module conflicts, disables via C_AddOns and requests a reload; Okay/Don\'t show again unchanged.')
