"""Addon unit menus: Set/Clear Focus go through secure overlays out of combat and are
hidden in combat (FocusUnit/ClearFocus are protected on 3.3.5); Blizzard menus untouched."""
from pathlib import Path
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

toc = (root / 'EllesmereUI/EllesmereUI.toc').read_text(encoding='utf-8')
assert 'EUI_UnitMenu_335.lua' in [l.strip() for l in toc.splitlines()]
for rel in ('EllesmereUIRaidFrames/EUI_RaidFrames_335_Display.lua', 'EllesmereUIUnitFrames/EUI_UnitFrames_335.lua'):
    assert 'UnitMenuWithoutFocus(dropdown)' in (root / rel).read_text(encoding='utf-8'), rel
source = (root / 'EllesmereUI/EUI_UnitMenu_335.lua').read_text(encoding='utf-8-sig')
for banned in ('FocusUnit(', 'ClearFocus(', 'RunMacroText'):
    assert banned not in source, banned

lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute(r'''
EllesmereUI={}; EUI_WOW_335=true; combat=false
function InCombatLockdown() return combat end
function hooksecurefunc(key,callback)
    local original=_G[key]
    _G[key]=function(...) original(...); callback(...) end
end
local Frame={}; Frame.__index=Frame
function Frame:Show() if combat and self.secure then error('secure frame shown in combat') end; self.shown=true end
function Frame:Hide() if combat and self.secure then error('secure frame hidden in combat') end; self.shown=false; if self.scripts.OnHide then self.scripts.OnHide(self) end end
function Frame:IsShown() return self.shown end
function Frame:SetScript(k,f) self.scripts[k]=f end
function Frame:HookScript(k,f) local old=self.scripts[k]; self.scripts[k]=function(...) if old then old(...) end; f(...) end end
function Frame:SetAttribute(k,v) if combat and self.secure then error('secure attribute in combat') end; self.attrs[k]=v end
function Frame:GetAttribute(k) return self.attrs[k] end
function Frame:SetPoint(_,rel,_,x,y) assert(rel==UIParent,'overlay anchored to the menu'); self.x,self.y=x,y end
function Frame:ClearAllPoints() self.x,self.y=nil,nil end
function Frame:SetWidth(w) self.w=w end
function Frame:SetHeight(h) self.h=h end
function Frame:GetWidth() return self.w end
function Frame:GetHeight() return self.h end
function Frame:GetLeft() return self.left end
function Frame:GetBottom() return self.bottom end
function Frame:GetEffectiveScale() return self.scale or 1 end
function Frame:SetFrameStrata(s) self.strata=s end
function Frame:RegisterForClicks() end
function Frame:RegisterEvent(e) self.events[e]=true end
function Frame:LockHighlight() self.lit=true end
function Frame:UnlockHighlight() self.lit=false end
function CreateFrame(_,name,_,template)
    local f=setmetatable({scripts={},attrs={},events={},shown=true,secure=template=='SecureActionButtonTemplate'},Frame)
    if name then _G[name]=f end
    watchers=watchers or {}; watchers[#watchers+1]=f
    return f
end
UIParent=CreateFrame('Frame','UIParent'); UIParent.scale=1
DropDownList1=CreateFrame('Frame','DropDownList1'); DropDownList1.shown=false; DropDownList1.numButtons=0
for i=1,4 do local b=CreateFrame('Button','DropDownList1Button'..i); b.w=120; b.h=16; b.left=200; b.bottom=500-i*16; b.scale=1 end
closed=0; function CloseDropDownMenus() closed=closed+1; DropDownList1:Hide() end
counting=nil; function UIDropDownMenu_StopCounting() counting=false end; function UIDropDownMenu_StartCounting() counting=true end
UnitPopupMenus={PARTY={'WHISPER','INSPECT','SET_FOCUS','CANCEL'},FOCUS={'RAID_TARGET_ICON','CLEAR_FOCUS','CANCEL'}}
UnitPopupShown={{},{},{}}
UIDROPDOWNMENU_MENU_LEVEL=1
function UnitPopup_HideButtons()
    local menu=UIDROPDOWNMENU_INIT_MENU; if type(menu)=='string' then menu=_G[menu] end
    for index in ipairs(UnitPopupMenus[menu.which]) do UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index]=1 end
end
function UnitPopup_ShowMenu(dropdown,which)
    dropdown.which=which; UIDROPDOWNMENU_INIT_MENU=dropdown.name
    UnitPopup_HideButtons()
    local out={}
    for index,value in ipairs(UnitPopupMenus[which]) do
        if UnitPopupShown[1][index]==1 then out[#out+1]=value end
    end
    return out
end
function ToggleDropDownMenu(_,_,dropdown)
    local out=UnitPopup_ShowMenu(dropdown,dropdown.menuWhich)
    for i=1,4 do local b=_G['DropDownList1Button'..i]; b.value=out[i]; b.shown=out[i]~=nil end
    DropDownList1.numButtons=#out; DropDownList1.shown=true
    lastMenu=out
end
EUIRaidMenu={name='EUIRaidMenu',unit='party1'}; PlayerFrameDropDown={name='PlayerFrameDropDown',unit='player'}
''')
lua.execute(source)
lua.execute(r'''
local E=EllesmereUI
E.UnitMenuWithoutFocus(EUIRaidMenu); E.UnitMenuWithoutFocus(EUIRaidMenu)
local watcher=watchers[#watchers]; assert(watcher.events.PLAYER_REGEN_DISABLED)
local function Has(list,v) for _,x in ipairs(list) do if x==v then return true end end end

EUIRaidMenu.menuWhich='PARTY'; ToggleDropDownMenu(1,nil,EUIRaidMenu)
assert(Has(lastMenu,'SET_FOCUS'),'Set Focus missing out of combat')
local o=EUI335UnitMenuSET_FOCUS
assert(o and o.secure and o:IsShown() and o.attrs.type=='focus' and o.attrs.unit=='party1','no secure focus overlay')
assert(o.strata=='TOOLTIP' and o.x==200 and o.y==500-3*16 and o.w==120 and o.h==16,'overlay not over the entry')
o.scripts.OnEnter(o); assert(DropDownList1Button3.lit and counting==false,'hover must keep the menu open')
o.scripts.OnLeave(o); assert(not DropDownList1Button3.lit and counting==true)
o.scripts.PostClick(o); assert(closed==1 and not o:IsShown(),'menu and overlay stay after focusing')

EUIRaidMenu.menuWhich='FOCUS'; EUIRaidMenu.unit='focus'; ToggleDropDownMenu(1,nil,EUIRaidMenu)
local c=EUI335UnitMenuCLEAR_FOCUS
assert(c and c:IsShown() and c.attrs.type=='macro' and c.attrs.macrotext=='/clearfocus','no secure clear focus overlay')

PlayerFrameDropDown.menuWhich='PARTY'; ToggleDropDownMenu(1,nil,PlayerFrameDropDown)
assert(Has(lastMenu,'SET_FOCUS') and not c:IsShown() and not o:IsShown(),'overlay leaked into a Blizzard menu')

EUIRaidMenu.menuWhich='PARTY'; EUIRaidMenu.unit='party2'; ToggleDropDownMenu(1,nil,EUIRaidMenu); assert(o:IsShown())
local before=closed; watcher.scripts.OnEvent(watcher,'PLAYER_REGEN_DISABLED')
assert(not o:IsShown() and closed==before+1,'open menu kept clickable focus entry into combat')
combat=true
ToggleDropDownMenu(1,nil,EUIRaidMenu); assert(not Has(lastMenu,'SET_FOCUS') and not o:IsShown(),'Set Focus offered in combat')
EUIRaidMenu.menuWhich='FOCUS'; ToggleDropDownMenu(1,nil,EUIRaidMenu); assert(not Has(lastMenu,'CLEAR_FOCUS'),'Clear Focus offered in combat')
PlayerFrameDropDown.menuWhich='PARTY'; ToggleDropDownMenu(1,nil,PlayerFrameDropDown); assert(Has(lastMenu,'SET_FOCUS'),'Blizzard menu lost Set Focus in combat')
DropDownList1:Hide()
combat=false
''')
print('PASS: Set/Clear Focus via secure overlays out of combat (placed over the entry, hover keeps menu, click closes), hidden in combat, closed on combat start, Blizzard menus untouched')
