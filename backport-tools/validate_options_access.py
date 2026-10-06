"""Exercise Wrath menu/category entry points without building the settings UI."""
from pathlib import Path
import re
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime

def fixture():
    lua=LuaRuntime()
    lua.execute((root/'backport-tools/wrath_mock.lua').read_text())
    lua.execute('''
EUI335={IsWrath=true}; combat=false; loadOK=true; loads=0; opens=0; categories={}
function InCombatLockdown() return combat end
function IsLoggedIn() return true end
local m=getmetatable(UIParent).__index
function m:GetPoint(i) return unpack((self.points or {})[i or 1] or {}) end
function m:ClearAllPoints() self.points={} end
function m:SetPoint(...) assert(not combat,'Menu layout changed in combat'); self.points=self.points or {}; self.points[#self.points+1]={...} end
function m:HookScript(event,fn) self.hooks[event]=self.hooks[event] or {}; table.insert(self.hooks[event],fn) end
function m:RunScript(event,...) if self.scripts[event] then self.scripts[event](self,...) end; for _,fn in ipairs(self.hooks[event] or {}) do fn(self,...) end end
function m:Show() self.shown=true; self:RunScript('OnShow') end
function m:GetTop() return self.top end
function m:GetBottom() return self.bottom end
function m:GetChildren() return unpack(self.children) end
INTERFACEOPTIONS_ADDONCATEGORIES={}
function InterfaceOptions_AddCategory(panel) assert(panel.name=='EllesmereUI'); categories[#categories+1]=panel; table.insert(INTERFACEOPTIONS_ADDONCATEGORIES,panel) end
function HideUIPanel(frame) frame:Hide() end
function EllesmereUI.EnsureOptionsLoaded() loads=loads+1; return loadOK end
function EllesmereUI:Show() assert(self==EllesmereUI and not combat); opens=opens+1 end
function EllesmereUI.PrintError(message) lastError=message end
EllesmereUIDB={}; toggles=0
function EllesmereUI:ToggleUnlockMode() assert(self==EllesmereUI and not combat); toggles=toggles+1 end
GameMenuFrame=CreateFrame('Frame','GameMenuFrame',UIParent); GameMenuFrame:SetHeight(200); GameMenuFrame.top=300; GameMenuFrame:Hide()
GameMenuButtonMacros=CreateFrame('Button','GameMenuButtonMacros',GameMenuFrame)
GameMenuButtonLogout=CreateFrame('Button','GameMenuButtonLogout',GameMenuFrame)
GameMenuButtonLogout:SetWidth(180); GameMenuButtonLogout:SetHeight(20)
GameMenuButtonLogout:SetPoint('TOPLEFT',GameMenuButtonMacros,'BOTTOMLEFT',0,-16)
GameMenuButtonContinue=CreateFrame('Button','GameMenuButtonContinue',GameMenuFrame); GameMenuButtonContinue.bottom=85
InterfaceOptionsFrame=CreateFrame('Frame','InterfaceOptionsFrame',UIParent)
VideoOptionsFrame=CreateFrame('Frame','VideoOptionsFrame',UIParent)
AudioOptionsFrame=CreateFrame('Frame','AudioOptionsFrame',UIParent)
''')
    return lua

source=(root/'EllesmereUI/EUI_OptionsAccess_335.lua').read_text()
lua=fixture()
lua.execute(source)
lua.execute('''
local A=EllesmereUI._wrathOptionsAccess
assert(#categories==1 and categories[1]==A.category and not A.category:IsShown())
assert(A.menuButton:GetText()=='EllesmereUI' and loads==0 and opens==0,'Options loaded without an explicit click')
for i=1,5 do A.events:RunScript('OnEvent','PLAYER_ENTERING_WORLD'); GameMenuFrame:Show() end
assert(#categories==1 and #GameMenuFrame.hooks.OnShow==1)
assert(A.menuButton:GetWidth()==180 and A.menuButton:GetHeight()==20)
-- Unlock entry is shown by default on Wrath and sits between ours and Logout.
assert(EllesmereUIDB.hideUnlockMenuButton==false,'Unlock entry default not seeded')
assert(A.unlockButton:GetText()=='EUI Unlock Mode' and A.unlockButton:IsShown())
assert(A.unlockButton:GetWidth()==180 and A.unlockButton:GetHeight()==20)
assert(select(2,A.menuButton:GetPoint(1))==GameMenuButtonMacros)
assert(select(2,A.unlockButton:GetPoint(1))==A.menuButton)
assert(select(2,GameMenuButtonLogout:GetPoint(1))==A.unlockButton)
assert(select(5,GameMenuButtonLogout:GetPoint(1))==-16,'Logout lost its section gap')
assert(GameMenuFrame:GetHeight()==231,'Menu clipped buttons or expanded on every show')
-- Unlock click closes the menu and toggles; combat is refused without touching either.
A.unlockButton:RunScript('OnClick')
assert(toggles==1 and not GameMenuFrame:IsShown() and loads==0,'Unlock click failed or loaded options')
GameMenuFrame:Show(); combat=true; lastError=nil
A.unlockButton:RunScript('OnClick')
assert(toggles==1 and GameMenuFrame:IsShown() and lastError,'Unlock toggled in combat')
combat=false
-- The General "EUI Buttons" hide flags remove each entry and close the gap.
EllesmereUIDB.hideUnlockMenuButton=true; GameMenuFrame:Show()
assert(not A.unlockButton:IsShown() and select(2,GameMenuButtonLogout:GetPoint(1))==A.menuButton)
EllesmereUIDB.hideGameMenuButton=true; EllesmereUIDB.hideUnlockMenuButton=false; GameMenuFrame:Show()
assert(not A.menuButton:IsShown() and A.unlockButton:IsShown())
assert(select(2,A.unlockButton:GetPoint(1))==GameMenuButtonMacros and select(2,GameMenuButtonLogout:GetPoint(1))==A.unlockButton)
EllesmereUIDB.hideGameMenuButton=true; EllesmereUIDB.hideUnlockMenuButton=true; GameMenuFrame:Show()
assert(not A.menuButton:IsShown() and not A.unlockButton:IsShown() and select(2,GameMenuButtonLogout:GetPoint(1))==GameMenuButtonMacros)
EllesmereUIDB.hideGameMenuButton=nil; EllesmereUIDB.hideUnlockMenuButton=false; GameMenuFrame:Show()
assert(select(2,GameMenuButtonLogout:GetPoint(1))==A.unlockButton and A.menuButton:IsShown())
-- A saved explicit hide choice is not overwritten by the Wrath default.
EllesmereUIDB.hideUnlockMenuButton=true; A.Initialize(); assert(EllesmereUIDB.hideUnlockMenuButton==true)
EllesmereUIDB.hideUnlockMenuButton=false
GameMenuFrame:Show()
A.menuButton:RunScript('OnClick')
assert(loads==1 and opens==1 and not GameMenuFrame:IsShown() and not InterfaceOptionsFrame:IsShown())
-- Explicit category entry opens the same panel and closes native options.
InterfaceOptionsFrame:Show(); A.category:Show(); A.category.openButton:RunScript('OnClick')
assert(loads==2 and opens==2 and not InterfaceOptionsFrame:IsShown())
assert(not A.category.scripts.OnKeyDown and not A.menuButton.scripts.OnKeyDown)
-- Failed LOD load keeps the existing UI; combat cannot load or open options.
loadOK=false; GameMenuFrame:Show(); assert(A.Open()==false and loads==3 and opens==2 and GameMenuFrame:IsShown())
loadOK=true; combat=true; assert(A.Open()==false and loads==3 and opens==2 and lastError)
A.LayoutMenu(); combat=false
-- Coexist with another addon inserting its menu button after ours.
local other=CreateFrame('Button',nil,GameMenuFrame)
other:SetPoint('TOPLEFT',A.menuButton,'BOTTOMLEFT',0,-1)
GameMenuButtonLogout:ClearAllPoints(); GameMenuButtonLogout:SetPoint('TOPLEFT',other,'BOTTOMLEFT',0,-16)
GameMenuFrame:Show()
assert(select(2,GameMenuButtonLogout:GetPoint(1))==other and select(2,A.menuButton:GetPoint(1))==GameMenuButtonMacros)
assert(select(2,other:GetPoint(1))==A.unlockButton,'Other entry overlaps the Unlock entry')
-- Native re-layout drops our entries from the chain and resets the frame height.
other:Hide(); other:ClearAllPoints(); other:SetPoint('TOPLEFT',UIParent,'TOPLEFT',0,0)
GameMenuButtonLogout:ClearAllPoints(); GameMenuButtonLogout:SetPoint('TOPLEFT',GameMenuButtonMacros,'BOTTOMLEFT',0,-16)
GameMenuFrame:SetHeight(200); GameMenuFrame:Show(); assert(GameMenuFrame:GetHeight()==231)
assert(select(2,GameMenuButtonLogout:GetPoint(1))==A.unlockButton)
''')

# ElvUI's real OnShow hook re-inserts its entry above Logout; in either hook
# order the chain must stay acyclic with both EUI entries in it.
ELVUI_HOOK='''
elv=CreateFrame('Button','ElvUI_MenuButton',GameMenuFrame)
GameMenuFrame:HookScript('OnShow',function()
 local _,relTo=GameMenuButtonLogout:GetPoint()
 if relTo~=elv then
  elv:ClearAllPoints(); elv:SetPoint('TOPLEFT',relTo,'BOTTOMLEFT',0,-1)
  GameMenuButtonLogout:ClearAllPoints(); GameMenuButtonLogout:SetPoint('TOPLEFT',elv,'BOTTOMLEFT',0,-16)
 end
end)
'''
CHAIN_CHECK='''
for i=1,5 do GameMenuFrame:Hide(); GameMenuFrame:Show() end
local A=EllesmereUI._wrathOptionsAccess
local order,frame,seen={},GameMenuButtonLogout,{}
while frame and frame~=GameMenuButtonMacros do
 assert(not seen[frame],'Circular menu anchors'); seen[frame]=true
 order[#order+1]=frame; frame=select(2,frame:GetPoint(1))
end
assert(frame==GameMenuButtonMacros and #order==4,'Broken menu chain: '..#order)
local found={}; for _,f in ipairs(order) do found[f]=true end
assert(found[elv] and found[A.menuButton] and found[A.unlockButton])
'''
# A pre-0.40 saved hide flag (never honoured on Wrath) is cleared once; a later
# explicit choice through the General options is kept.
stale=fixture()
stale.execute('EllesmereUIDB.hideGameMenuButton=true')
stale.execute(source)
stale.execute('''
local A=EllesmereUI._wrathOptionsAccess
GameMenuFrame:Show()
assert(A.menuButton:IsShown() and EllesmereUIDB.hideGameMenuButton==nil and EllesmereUIDB.wrathGameMenuFlagsV1,'Stale hide flag kept the EllesmereUI entry hidden')
EllesmereUIDB.hideGameMenuButton=true
A.events:RunScript('OnEvent','PLAYER_ENTERING_WORLD'); GameMenuFrame:Show()
assert(not A.menuButton:IsShown() and EllesmereUIDB.hideGameMenuButton==true,'Explicit hide choice was reset')
''')
for elv_first in [True,False]:
    rt=fixture()
    if elv_first: rt.execute(ELVUI_HOOK)
    rt.execute(source)
    if not elv_first: rt.execute(ELVUI_HOOK)
    rt.execute(CHAIN_CHECK)
lua.execute(source)
lua.execute('assert(#categories==1 and #GameMenuFrame.hooks.OnShow==1)')

# Prefer the existing Retail entry on clients with a pooled modern menu.
modern=fixture()
modern.execute('GameMenuFrame.Layout=function() end; GameMenuFrame.buttonPool={}')
modern.execute(source)
modern.execute('assert(#categories==1 and not EllesmereUI._wrathOptionsAccess.menuButton)')

# APIs/frames can become available later; registration is retried once out of combat.
late=fixture()
late.execute('savedMenu=GameMenuFrame; GameMenuFrame=nil; combat=true')
late.execute(source)
late.execute('''
assert(#categories==0); combat=false
EllesmereUI._wrathOptionsAccess.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED')
assert(#categories==1 and not EllesmereUI._wrathOptionsAccess.menuButton)
GameMenuFrame=savedMenu
EllesmereUI._wrathOptionsAccess.events:RunScript('OnEvent','PLAYER_ENTERING_WORLD')
assert(EllesmereUI._wrathOptionsAccess.menuButton)
''')
# The Retail core's own entry goes through the Settings shim; only one
# "EllesmereUI" entry may be listed whichever side registers first.
compat=(root/'EllesmereUI/EllesmereUI_3.3.5_Compat.lua').read_text(encoding='utf-8-sig')
shim=re.search(r'-- Retail Settings API.*?\nSettings\.RegisterAddOnCategory=.*?\nend\n',compat,re.S).group(0)
RETAIL_PANEL='''
retailPanel=CreateFrame('Frame'); retailPanel.name='EllesmereUI'
retailButton=CreateFrame('Button',nil,retailPanel,'UIPanelButtonTemplate')
retailButton:SetScript('OnClick',function() retailClicked=true end)
Settings.RegisterAddOnCategory(Settings.RegisterCanvasLayoutCategory(retailPanel,'EllesmereUI'))
'''
retailFirst=fixture()
retailFirst.execute(shim)
retailFirst.execute(RETAIL_PANEL)
retailFirst.execute(source)
retailFirst.execute('''
local A=EllesmereUI._wrathOptionsAccess
assert(#categories==1 and A.category==retailPanel and retailPanel.openButton==retailButton)
InterfaceOptionsFrame:Show(); retailButton:RunScript('OnClick')
assert(not retailClicked and opens==1 and not InterfaceOptionsFrame:IsShown(),'Retail entry opens through the Wrath path')
''')
wrathFirst=fixture()
wrathFirst.execute(shim)
wrathFirst.execute(source)
wrathFirst.execute(RETAIL_PANEL)
wrathFirst.execute('''
local A=EllesmereUI._wrathOptionsAccess
assert(#categories==1,#categories)
assert(categories[1]==A.category and A.category~=retailPanel,tostring(A.category))
''')
print('PASS: single EllesmereUI Interface/AddOns entry in either registration order;')
print('PASS: Wrath Escape menu and Interface/AddOns entries; click-only LOD/open, native panel close, missing-options/combat guards, idempotent registration/layout, other-addon anchor chain, native re-layout, late frames and pooled-menu fallback.')
print('PASS: EUI Unlock Mode Escape entry; shown by default, closes menu and toggles, combat guard, General hide flags for both entries, saved choice kept, acyclic chain with ElvUI in either hook order.')
