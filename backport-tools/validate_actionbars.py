"""Run real Wrath LAB, module, secure snippets and options against explicit legacy contracts."""
from pathlib import Path
import sys
import xml.etree.ElementTree as ET
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
lua=LuaRuntime()
lua.execute((root/'backport-tools/wrath_mock.lua').read_text())
lua.execute((root/'backport-tools/actionbars_mock.lua').read_text())
lua.execute((root/'backport-tools/nativehud_mock.lua').read_text())
unlock_source=(root/'EllesmereUI/EUI_UnlockMode.lua').read_text(encoding='utf-8-sig')
active_method='function EllesmereUI:IsUnlockModeActive()'+unlock_source.split('function EllesmereUI:IsUnlockModeActive()',1)[1].split('\n    end',1)[0]+'\nend'
lua.execute(active_method)
lua.execute('''
local function Copy(value)
    if type(value)~='table' then return value end
    local result={}; for k,v in pairs(value) do result[k]=Copy(v) end; return result
end
function EllesmereUI.Lite.NewDB(_,defaults) return {profile=Copy(defaults.profile)} end
''')
for file in ['EllesmereUI/Libs/LibStub/LibStub.lua','EllesmereUI/Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua']:
    lua.execute((root/file).read_text(encoding='utf-8-sig'))
lua.execute('local k=LibStub:NewLibrary("LibKeyBound-1.0",999); function k:Set() error("key capture reached") end')
lua.execute((root/'EllesmereUIActionBars/Libs/LibActionButton-1.0-335.lua').read_text())
ns=lua.table()
lua.execute((root/'EllesmereUIActionBars/EUI_ActionBars_335.lua').read_text(),'EllesmereUIActionBars',ns)
lua.execute((root/'EllesmereUIActionBars/EUI_NativeHUD_335.lua').read_text(),'EllesmereUIActionBars',ns)
lua.globals().AB=ns
core_source=(root/'EllesmereUI/EllesmereUI_Lite.lua').read_text(encoding='utf-8-sig')
safe_body='local function errorhandler'+core_source.split('local function errorhandler',1)[1].split('\n--------------------------------------------------------------------------------',1)[0]
lua.execute('lifecycleErrors={}; function geterrorhandler() return function(err) lifecycleErrors[#lifecycleErrors+1]=err end end')
safe=lua.execute(safe_body+'\nreturn safecall')
# Use the real Core dispatcher and native Lua 5.1 xpcall argument behavior.
safe(ns.addon.OnInitialize,ns.addon)
lua.execute('assert(#lifecycleErrors==0,lifecycleErrors[1])')
safe(ns.addon.OnEnable,ns.addon)
lua.execute('assert(#lifecycleErrors==0,lifecycleErrors[1])')
lua.execute('''
local main=AB.bars.bar1
local button=main.buttons[1]
assert(button:GetAttribute("action")==1 and button._state_action==1 and button.icon:GetTexture()=="icon-1")
assert(button.cooldown.duration==3 and button.count:GetText()==5)
button:GetScript("OnEnter")(button); assert(GameTooltip.action==1)
button:GetScript("OnLeave")(button)
assert(main.bindings["1"][1]==button:GetName() and main.bindings["SHIFT-1"])
assert(AB.bars.bar2.buttons[1]:GetAttribute("action")==61)
assert(AB.bars.bar3.buttons[1]:GetAttribute("action")==49)
assert(AB.bars.bar4.buttons[1]:GetAttribute("action")==25)
assert(AB.bars.bar5.buttons[1]:GetAttribute("action")==37)
assert(not AB.bars.bar6:IsShown() and next(AB.bars.bar6.bindings)==nil)
assert(ActionButton1:GetParent()~=nativeParent)
assert(VehicleMenuBar:GetParent()==nativeParent and PossessBarFrame:GetParent()==nativeParent)
assert(CharacterMicroButton:GetParent()==AB.NativeHUD.holders.micro and MainMenuBarBackpackButton:GetParent()==AB.NativeHUD.holders.bags)
assert(PetActionButton1:GetParent()==AB.bars.petBar)
-- Blizzard stance/bonus animations can Show and reset alpha in combat.
-- They cannot expose the native shells through their hidden parent.
for _,f in ipairs({ShapeshiftBarFrame,PetActionBarFrame,BonusActionBarFrame}) do
    assert(f:GetParent()~=nativeParent and not f:IsVisible())
    combat=true; f:SetAlpha(1); f:Show(); assert(not f:IsVisible())
    combat=false
end
assert(ShapeshiftButton1:GetParent()==AB.bars.stanceBar and ShapeshiftButton1:IsVisible())
AB.GetSettings().bars.stanceBar.enabled=false; AB.Apply()
combat=true; ShapeshiftBarFrame:Show(); ShapeshiftButton1:Show(); TickDrivers()
assert(not ShapeshiftBarFrame:IsVisible() and not ShapeshiftButton1:IsVisible())
combat=false; AB.GetSettings().bars.stanceBar.enabled=true; AB.Apply()
AB.GetSettings().enabled=false; AB.Apply()
assert(ShapeshiftBarFrame:GetParent()==nativeParent and BonusActionBarFrame:GetParent()==nativeParent)
assert(ShapeshiftButton1:GetParent()==nativeParent)
AB.GetSettings().enabled=true; AB.Apply()
PetActionButton1:GetScript("OnClick")(PetActionButton1); assert(nativeClicks==1)
assert(unlockFolder=="EllesmereUIActionBars" and #unlockElements==14)
-- Mover shortcut works before the lazy options module has ever loaded.
EllesmereUI._ELEMENT_SETTINGS_MAP.EUI335_HUD_xp.preSelectFn()
assert(AB.selectedWrathBar=='xp')
assert(MainMenuBarTexture0:GetTexture()==nil and MainMenuBarTexture0:GetAlpha()==0)
assert(MainMenuBarArtFrame.art:GetTexture()==nil and MainMenuBarArtFrame.art:GetAlpha()==0)
assert(MainMenuBar:IsShown() and MainMenuBarArtFrame:IsShown() and MainMenuBarArtFrame.functionalChild:IsShown())
MainMenuBarTexture0:SetAlpha(1); MainMenuBarArtFrame.art:SetTexture('native-animation'); AB.UpdateAlpha()
assert(MainMenuBarTexture0:GetTexture()==nil and MainMenuBarTexture0:GetAlpha()==0 and MainMenuBarArtFrame.art:GetTexture()==nil)
AB.GetSettings().hideArtwork=false; AB.Apply()
assert(MainMenuBarTexture0:GetTexture()=='Interface\\\\MainMenuBar\\\\UI-MainMenuBar-Left' and MainMenuBarTexture0:GetAlpha()==.8)
assert(MainMenuBarArtFrame.art:GetTexture()=='Interface\\\\MainMenuBar\\\\UI-MainMenuBar-Right' and MainMenuBarArtFrame.art:GetAlpha()==.7)
assert(CharacterMicroButton:GetParent()==AB.NativeHUD.holders.micro)
combat=true; AB.GetSettings().hideArtwork=true; AB.Apply(); assert(MainMenuBarTexture0:GetAlpha()==.8)
combat=false; AB.events:GetScript('OnEvent')(AB.events,'PLAYER_REGEN_ENABLED'); assert(MainMenuBarTexture0:GetTexture()==nil)
combat=true; AB.GetSettings().hideArtwork=false; AB.Apply(); assert(MainMenuBarTexture0:GetAlpha()==0)
combat=false; AB.events:GetScript('OnEvent')(AB.events,'PLAYER_REGEN_ENABLED'); assert(MainMenuBarTexture0:GetAlpha()==.8)
AB.GetSettings().hideArtwork=true; AB.Apply()
local savedDB=AB.addon.db
AB.addon.db=nil
for _,element in ipairs(unlockElements) do
    assert(element.loadPos()==nil and element.isHidden())
    element.savePos(nil,"CENTER","CENTER",1,2); element.clearPos(); element.applyPos()
end
AB.addon.db=savedDB
-- Combat paging runs the exact snippets installed in real headers/buttons.
combat=true
for i=1,6 do page=i; TickDrivers(); assert(button:GetAttribute("action")==1+(i-1)*12) end
page=1
for i=1,5 do bonus=i; TickDrivers(); assert(button:GetAttribute("action")==1+(i+5)*12) end
bonus=0; vehicle=true; TickDrivers()
assert(not main:IsShown() and next(main.bindings)==nil and not AB.bars.petBar:IsShown())
vehicle=false; TickDrivers(); assert(main:IsShown() and main.bindings["1"])
AB.GetSettings("bar1").size=48; AB.Apply()
assert(button:GetWidth()==36, "combat layout must be deferred")
combat=false; AB.events:GetScript("OnEvent")(AB.events,"PLAYER_REGEN_ENABLED")
assert(button:GetWidth()==48)
class="DRUID"; bonus=1; stealth=true; TickDrivers()
RegisterStateDriver(main,"page",AB.GetPageDriver()); assert(button:GetAttribute("action")==85)
stealth=false; TickDrivers(); assert(button:GetAttribute("action")==73)
class="ROGUE"; bonus=0; form=3; RegisterStateDriver(main,"page",AB.GetPageDriver())
assert(button:GetAttribute("action")==73)
form=0; TickDrivers()
-- Real library's secure drag contract preserves slot and lock semantics.
assert(not MainMenuBar:IsMouseEnabled() and not MainMenuBarArtFrame:IsMouseEnabled(), 'Invisible native shell intercepted Bar 1 drops')
assert(CharacterMicroButton:IsMouseEnabled() and MainMenuBarBackpackButton:IsMouseEnabled(), 'Native children lost their mouse input')
modified=false
assert(RunSnippet(button,button:GetAttribute("OnDragStart"))==false)
modified=true
local kind,slot=RunSnippet(button,button:GetAttribute("OnDragStart"))
assert(kind=="action" and slot==1)
local receiveKind,receiveSlot=RunSnippet(button,button:GetAttribute("OnReceiveDrag"),nil,"spell",42,"spell",42)
assert(receiveKind=="action" and receiveSlot==1)
assert(button.wrapped.OnDragStart and button.wrapped.OnReceiveDrag and button.wrapped.OnClick)
-- Bind changes, reduced counts, cosmetics and optional sixth bar.
bindingKeys.ACTIONBUTTON1={"F1"}; AB.Apply()
assert(main.bindings.F1 and not main.bindings["1"])
AB.GetSettings("bar6").enabled=true; AB.Apply()
assert(AB.bars.bar6.bindings.F6 and AB.bars.bar6.buttons[1]:GetAttribute("action")==13)
AB.GetSettings("bar1").buttons=6; AB.GetSettings("bar1").buttonsPerRow=3
AB.GetSettings().showHotkeys=false; AB.GetSettings().showMacroNames=false; AB.GetSettings().clickOnDown=true
AB.Apply(); assert(not main.buttons[7]:IsShown() and main:GetWidth()==152 and main:GetHeight()==100)
assert(button.config.hideElements.hotkey and button.config.hideElements.macro and button.clicks[1]=="AnyDown")
AB.GetSettings("bar1").visibility="in_combat"; AB.Apply(); assert(not main:IsShown() and next(main.bindings)==nil)
combat=true; TickDrivers(); assert(main:IsShown() and main.bindings.F1)
combat=false; TickDrivers(); assert(not main:IsShown())
AB.GetSettings("bar1").visibility="mouseover"; AB.Apply(); hover=false; AB.UpdateAlpha(); assert(main:GetAlpha()==0)
hover=true; AB.UpdateAlpha(); assert(main:GetAlpha()==1)
hover=false; EllesmereUI._unlockModeSessionActive=true; AB.UpdateAlpha(); assert(main:GetAlpha()==1)
EllesmereUI._unlockModeSessionActive=false; AB.UpdateAlpha(); assert(main:GetAlpha()==0)
hover=true
unlockElements[1].savePos(nil,"CENTER","BOTTOMLEFT",500,300); AB.Apply()
assert(main:GetPoint(1)=="CENTER")
AB.GetSettings().enabled=false; AB.Apply()
assert(MainMenuBar:IsMouseEnabled() and MainMenuBarArtFrame:IsMouseEnabled(), 'Native shell input was not restored')
assert(ActionButton1:GetParent()==nativeParent and PetActionButton1:GetParent()==nativeParent)
assert(PetActionButton1:GetScale()==.9 and MainMenuBarTexture0:GetAlpha()==.8)
assert(MainMenuBarArtFrame.art:GetTexture()=='Interface\\\\MainMenuBar\\\\UI-MainMenuBar-Right' and MainMenuBarArtFrame.art:GetAlpha()==.7)
assert(next(main.bindings)==nil and not main:IsShown())
AB.GetSettings().enabled=true; AB.Apply(); assert(main:IsShown() and main.bindings.F1)
assert(not button.scripts.OnKeyDown and not button.SetPropagateKeyboardInput)
-- Native library visuals/events remain functional.
local lib=LibStub("LibActionButton-1.0-Ellesmere335")
lib.eventFrame:GetScript("OnEvent")(lib.eventFrame,"ACTIONBAR_UPDATE_COOLDOWN")
lib.eventFrame:GetScript("OnEvent")(lib.eventFrame,"ACTIONBAR_SLOT_CHANGED",0)
lib.eventFrame:GetScript("OnUpdate")(lib.eventFrame,.3)
''')
lua.execute('''
local H=AB.NativeHUD
local micro,bags,experience,rep,buffs,debuffs=H.holders.micro,H.holders.bags,H.holders.xp,H.holders.reputation,H.holders.buffs,H.holders.debuffs
assert(CharacterMicroButton.normalTexture:GetTexture()==nil and H.states.micro.buttons[CharacterMicroButton].icon:GetTexture()=='portrait-player')
assert(CharacterMicroButton:GetWidth()==28 and CharacterMicroButton:GetHeight()==28)
assert(CharacterMicroButton:GetHitRectInsets()==0 and select(3,CharacterMicroButton:GetHitRectInsets())==0)
assert(StoreMicroButton:GetParent()==micro and CollectionsMicroButton:GetParent()==micro and ParagonMicroButton:GetParent()==micro)
assert(H.states.micro.buttons[StoreMicroButton].icon:GetTexture()=='Interface\\\\Store\\\\StoreButton')
CharacterMicroButton:RunScript('OnClick'); CharacterMicroButton:RunScript('OnEnter')
assert(CharacterMicroButton.nativeClicks==1 and nativeHover==CharacterMicroButton)
MainMenuBarBackpackButton:RunScript('OnClick'); CharacterBag0Slot:RunScript('OnReceiveDrag')
assert(MainMenuBarBackpackButton.nativeClicks==1 and CharacterBag0Slot.nativeDrags==1)
assert(CharacterBag0SlotIconTexture:GetTexture()=='bag-icon-CharacterBag0Slot' and CharacterBag0SlotIconTexture.texcoords[1]==.07)
assert(KeyRingButton:GetParent()==bags and H.states.bags.buttons[KeyRingButton].icon:GetTexture()=='Interface\\\\Icons\\\\INV_Misc_Key_03')
KeyRingButton:RunScript('OnClick'); assert(KeyRingButton.nativeClicks==1)
assert(MainMenuExpBar:GetAlpha()==0 and ReputationWatchBar:GetAlpha()==0)
assert(ExhaustionLevelFillBar.GetScale==nil and ExhaustionTick.GetRegions==nil)
assert(ExhaustionLevelFillBar:GetTexture()==nil and ExhaustionTick:GetTexture()==nil and ExhaustionTick:GetAlpha()==0)
assert(H.states.xp.frames[ExhaustionTick]==nil and H.states.xp.textures[ExhaustionTick])
assert(experience.fill.value==250 and experience.fill.maximum==1000 and experience.rested.value==450 and experience:IsShown())
assert(experience.text.font[1] and rep.text.font[1] and experience.text:GetText()=='XP: 25.0%  R: 20.0%')
assert(rep.text:GetText()=='Test Faction: 25.0%')
AB.GetSettings().fontSize=15; H.UpdateData()
assert(experience.text.font[2]==15 and rep.text.font[2]==15)
AB.GetSettings().fontSize=11; H.UpdateData()
assert(experience.fill:GetStatusBarTexture():GetTexture()=='Interface\\\\AddOns\\\\EllesmereUIActionBars\\\\Media\\\\Textures_335\\\\elvui-norm.tga')
assert(experience.rested:GetStatusBarTexture():GetTexture()==experience.fill:GetStatusBarTexture():GetTexture())
assert(experience:GetFrameStrata()=='LOW' and experience.fill:GetFrameLevel()>experience.rested:GetFrameLevel())
assert(experience.bgColor[1]==.06 and experience.bgColor[2]==.06 and experience.bgColor[3]==.06)
assert(experience.fill.barColor[1]==0 and experience.fill.barColor[2]==.4 and experience.fill.barColor[3]==1)
assert(experience.rested.barColor[1]==.5 and experience.rested.barColor[2]==0 and experience.rested.barColor[3]==.5 and experience.rested.barColor[4]==.8)
assert(experience.fill:GetPoint(1)=='TOPLEFT' and select(4,experience.fill:GetPoint(1))==1 and select(5,experience.fill:GetPoint(1))==-1)
assert(experience.fill:GetPoint(2)=='BOTTOMRIGHT' and select(4,experience.fill:GetPoint(2))==-1 and select(5,experience.fill:GetPoint(2))==1)
assert(rep.fill.value==1500 and rep.fill.maximum==6000 and rep:IsShown() and rep.fill.text==nil)
experience:RunScript('OnEnter'); assert(GameTooltip.owner==experience and #GameTooltip.lines==3)
experience:RunScript('OnMouseDown','RightButton'); assert(xpRightClick[1]==MainMenuExpBar and xpRightClick[2]=='RightButton')
xp=600; rested=0; H.events:RunScript('OnEvent','PLAYER_XP_UPDATE','player')
assert(experience.fill.value==600 and experience.rested.value==0 and not experience.rested:IsShown())
xp=0; class='MAGE'; H.UpdateData()
assert(experience.fill.value==0 and experience.rested.value==0 and not experience.rested:IsShown())
assert(experience.fill.barColor[1]==0 and experience.fill.barColor[2]==.4 and experience.fill.barColor[3]==1 and experience.bgColor[1]==.06)
xp=600; rested=800; H.UpdateData(); assert(experience.rested.value==1000 and experience.rested:IsShown())
rested=nil; H.UpdateData(); assert(experience.rested.value==0 and not experience.rested:IsShown())
faction={'Another Faction',5,-3000,0,-1200}; H.events:RunScript('OnEvent','UPDATE_FACTION')
assert(rep.fill.value==1800 and rep.fill.maximum==3000 and rep.faction=='Another Faction')
level=80; faction={}; H.UpdateData(); assert(not experience:IsShown() and not rep:IsShown())
EllesmereUI._unlockModeSessionActive=true; H.UpdateData(); assert(experience:IsShown() and rep:IsShown())
EllesmereUI._unlockModeSessionActive=false; H.UpdateData(); assert(not experience:IsShown() and not rep:IsShown())
EllesmereUI._unlockModeSessionActive=true
-- Buffs/debuffs have independent real movers even with no auras or data.
assert(unlockElements[13].getFrame()==buffs and unlockElements[14].getFrame()==debuffs and not unlockElements[13].isHidden())
for i=9,14 do
    local element=unlockElements[i]
    element.savePos(nil,'CENTER','CENTER',i*10,i*5); element.applyPos()
    assert(element.getFrame():GetPoint(1)=='CENTER' and element.loadPos().x==i*10)
end
assert(select(2,BuffFrame:GetPoint(1))==buffs and BuffFrame:GetWidth()==buffs:GetWidth())
assert(select(2,BuffButton1:GetPoint(1))==buffs and select(2,DebuffButton1:GetPoint(1))==debuffs)
assert(select(2,TempEnchant1:GetPoint(1))==buffs)
BuffButton1:RunScript('OnMouseUp','RightButton'); BuffButton1:RunScript('OnUpdate')
assert(auraAction[1]==BuffButton1 and auraAction[2]=='RightButton' and BuffButton1.timerTicks==1)
assert(BuffFrame_UpdateAllBuffAnchors()=='native-buff-result'); DebuffButton_UpdateAnchors()
assert(select(2,BuffButton1:GetPoint(1))==buffs and select(2,DebuffButton1:GetPoint(1))==debuffs)
-- Simulate live drag before Core commits, then native layout/timer churn.
buffs:ClearAllPoints(); buffs:SetPoint('CENTER',UIParent,'CENTER',321,123)
UIParent_ManageFramePositions(); H.events:RunScript('OnUpdate',.3)
assert(select(4,buffs:GetPoint(1))==321 and select(5,buffs:GetPoint(1))==123,'HUD refresh interrupted live dragging')
local buffRight,buffTop=321+buffs:GetWidth()/2,123+buffs:GetHeight()/2
unlockElements[13].savePos(nil,'CENTER','CENTER',321,123); EllesmereUI._unlockModeSessionActive=false; H.Apply()
assert(buffs:GetPoint(1)=='TOPRIGHT' and select(4,buffs:GetPoint(1))==buffRight and select(5,buffs:GetPoint(1))==buffTop)
local oldHeight=buffs:GetHeight(); AB.GetSettings().nativeHUD.buffsColumns=1; H.UpdateAuras()
assert(buffs:GetHeight()>oldHeight and select(5,buffs:GetPoint(1))==buffTop,'Buff rows moved their first row upward')
assert(select(5,BuffButton2:GetPoint(1))<0,'Buff rows do not grow down')
AB.GetSettings().nativeHUD.buffsColumns=nil; H.UpdateAuras()
assert(select(5,buffs:GetPoint(1))==buffTop and AB.GetSettings().barPositions.hud_buffs.point=='TOPRIGHT')
BuffButton1:Hide(); H.UpdateAuras(); assert(select(4,BuffButton2:GetPoint(1))==-36)
BuffButton1:Show(); H.UpdateAuras(); assert(select(4,BuffButton1:GetPoint(1))==-36)
-- Protected aura reanchors and saved position changes defer safely in combat.
BuffButton13=CreateFrame('Button','BuffButton13',BuffFrame); BuffButton13:SetPoint('TOPRIGHT',UIParent,'TOPRIGHT',-10,-10); BuffButton13:Hide()
DebuffButton12:ClearAllPoints(); DebuffButton12:SetPoint('TOPRIGHT',UIParent,'TOPRIGHT',-10,-10)
DebuffButton12.protected=true
combat=true
AB.GetSettings().nativeHUD.buttonSize=36; H.Apply(); assert(CharacterMicroButton:GetWidth()==28)
local before={DebuffButton12:GetPoint(1)}; H.UpdateAuras(); assert(select(4,DebuffButton12:GetPoint(1))==before[4])
BuffButton13:Show(); H.events:RunScript('OnEvent','UNIT_AURA','player')
assert(select(2,BuffButton13:GetPoint(1))==buffs,'New unprotected aura ignored its moved holder')
BuffFrame_UpdateAllBuffAnchors(); assert(select(2,BuffButton1:GetPoint(1))==buffs)
xp=700; level=79; H.UpdateData(); assert(experience.fill.value==700 and experience:IsShown())
combat=false; H.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); H.events:RunScript('OnUpdate',.3)
assert(CharacterMicroButton:GetWidth()==36)
assert(select(2,DebuffButton12:GetPoint(1))==debuffs,'Protected aura not reapplied after combat')
DebuffButton12.protected=false
-- Settings/off restore original native geometry/art; dynamic bag contents survive.
CharacterBag0SlotIconTexture:SetTexture('changed-bag-icon')
AB.GetSettings().nativeHUD.micro=false; AB.GetSettings().nativeHUD.bags=false
AB.GetSettings().nativeHUD.xp=false; AB.GetSettings().nativeHUD.reputation=false
AB.GetSettings().nativeHUD.buffs=false; AB.GetSettings().nativeHUD.debuffs=false; H.Apply()
assert(CharacterMicroButton:GetParent()==nativeParent and CharacterMicroButton:GetHeight()==58 and CharacterMicroButton.normalTexture:GetTexture()=='native-normal-CharacterMicroButton')
assert(select(3,CharacterMicroButton:GetHitRectInsets())==20 and StoreMicroButtonIcon:GetTexture()=='Interface\\\\Store\\\\StoreButton')
assert(CharacterBag0Slot:GetParent()==nativeParent and CharacterBag0SlotIconTexture:GetTexture()=='changed-bag-icon' and CharacterBag0SlotIconTexture.texcoords[1]==0)
assert(MainMenuExpBar:GetAlpha()==.8 and ReputationWatchBar:GetAlpha()==.75)
assert(ExhaustionLevelFillBar:GetTexture()=='native-ExhaustionLevelFillBar' and ExhaustionTick:GetTexture()=='native-ExhaustionTick')
assert(ExhaustionTick:GetAlpha()==.65 and select(1,ExhaustionTick:GetTexCoord())==.1 and select(4,ExhaustionTick:GetTexCoord())==.8)
assert(select(2,BuffButton1:GetPoint(1))==UIParent and BuffFrame:GetWidth()==200 and BuffFrame:GetHeight()==60)
assert(select(2,DebuffButton1:GetPoint(1))==UIParent and not debuffs:IsShown())
for _,definition in ipairs(H.definitions) do AB.GetSettings().nativeHUD[definition.key]=true end
H.Apply(); local frames=#allFrames; H.Apply(); assert(#allFrames==frames,'HUD duplicated frames on refresh')
assert(ExhaustionLevelFillBar:GetTexture()==nil and ExhaustionTick:GetTexture()==nil)
assert(select(4,buffs:GetPoint(1))==buffRight and select(2,DebuffButton1:GetPoint(1))==debuffs)
''')
# Exercise actual shared Fonts/Textures card builders through their Wrath branch.
lua.execute('''
function EllesmereUI.ModuleNS(folder) return EllesmereUI._ModuleNS[folder] end
function EllesmereUI.AppendSharedMediaTextures() error("unsupported data-bar catalogue reached") end
EllesmereUI.Widgets={DualRow=function(_,parent,y,left,right) rows[#rows+1]={left,right}; return {},50 end}
''')
for file in ['EUI_Fonts_Options.lua','EUI_Textures_Options.lua']:
    source=(root/'EllesmereUIOptions'/file).read_text(encoding='utf-8-sig')
    body=source.split('local function TileActionBars(',1)[1].split('local function TileNameplates(',1)[0]
    card=lua.execute('''
local NS=EllesmereUI.ModuleNS
local ModuleOutlineCfg=function() return {type="dropdown"} end
local NoteRow=function(_,y) return y-30 end
local LinkRow=function(_,y,_,_,page) assert(page=="Action Bars"); return y-30 end
local function TileActionBars('''+body+'\nreturn TileActionBars')
    lua.globals().cardBuilder=card
    lua.execute('rows={}; assert(cardBuilder(UIParent,0,EllesmereUI.Widgets,{folder="EllesmereUIActionBars",display="Action Bars"})<0)')
    if file=='EUI_Fonts_Options.lua':
        lua.execute('rows[1][2].setValue(14); assert(AB.GetSettings().fontSize==14)')
lua.execute('IsLoggedIn=function() return true end; function EllesmereUI:RefreshPage(force) refreshForced=force end')
lua.execute((root/'EllesmereUIOptions/EUI_ActionBars_335_Options.lua').read_text())
lua.execute('''
assert(testModule and #testModule.pages==1 and testModule.pages[1]=='Action Bars' and SlashCmdList.EUI335ACTIONBARS)
rows={}
EllesmereUI.Widgets={
    DualRow=function(_,parent,y,left,right) rows[#rows+1]={left,right}; return {},50 end,
    SectionHeader=function() return {},30 end,
    WideButton=function(_,parent,text,y,fn) optionButtons[text]=fn; return {},40 end,
}
local function Build(key)
    AB.SelectWrathBar(key,false); rows={}; optionButtons={}; assert(testModule.buildPage('Action Bars',UIParent,0)>0)
end
Build('bar1'); assert(#rows[1][1].order==14 and rows[1][1].values.buffs=='Player Buffs')
rows[1][1].setValue('bar2'); assert(AB.selectedWrathBar=='bar2' and refreshForced==true)
Build('bar2')
rows[2][1].setValue(42); assert(AB.bars.bar2.buttons[1]:GetWidth()==42)
assert(AB.bars.bar1.buttons[1]:GetWidth()==48)
rows[1][2].setValue(false); assert(not AB.bars.bar2:IsShown()); rows[1][2].setValue(true)
local oldSizeSetter=rows[2][1].setValue
Build('bar3'); oldSizeSetter(43); assert(AB.bars.bar2.buttons[1]:GetWidth()==43 and AB.bars.bar3.buttons[1]:GetWidth()==36)
Build('micro'); assert(rows[2][1].getValue()==36 and rows[1][2].text=='Enable Skin')
rows[1][2].setValue(false); assert(CharacterMicroButton:GetParent()==nativeParent)
assert(MainMenuBarArtFrame:IsShown() and MainMenuBarArtFrame.functionalChild:IsShown() and MainMenuBarTexture0:GetTexture()==nil)
rows[1][2].setValue(true); assert(CharacterMicroButton:GetParent()==AB.NativeHUD.holders.micro)
rows[2][1].setValue(32); assert(CharacterMicroButton:GetWidth()==32 and MainMenuBarBackpackButton:GetWidth()==36)
rows[2][2].setValue(7); assert(AB.GetSettings().nativeHUD.microSpacing==7 and AB.GetSettings().nativeHUD.bagsSpacing==nil)
Build('bags'); rows[2][1].setValue(24); assert(MainMenuBarBackpackButton:GetWidth()==24 and CharacterMicroButton:GetWidth()==32)
assert(rows[3][1].text=='Consolidate Bags'); rows[3][1].setValue(true)
assert(AB.NativeHUD.holders.bags:GetWidth()==24 and MainMenuBarBackpackButton:GetParent()==AB.NativeHUD.holders.bags)
assert(CharacterBag0Slot:GetParent()==AB.NativeHUD.hiddenBags and not AB.NativeHUD.hiddenBags:IsShown() and KeyRingButton:GetParent()==AB.NativeHUD.hiddenBags)
local consolidate=rows[3][1].setValue
combat=true; consolidate(false); assert(CharacterBag0Slot:GetParent()==AB.NativeHUD.hiddenBags)
combat=false; AB.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED')
assert(CharacterBag0Slot:GetParent()==AB.NativeHUD.holders.bags and KeyRingButton:GetParent()==AB.NativeHUD.holders.bags and AB.NativeHUD.holders.bags:GetWidth()>24)
Build('xp'); rows[2][1].setValue(520); rows[2][2].setValue(18)
assert(AB.NativeHUD.holders.xp:GetWidth()==520 and AB.NativeHUD.holders.xp:GetHeight()==18)
assert(AB.NativeHUD.holders.reputation:GetWidth()==AB.GetSettings().nativeHUD.barWidth)
Build('reputation'); rows[2][1].setValue(610); rows[2][2].setValue(20)
assert(AB.NativeHUD.holders.reputation:GetWidth()==610 and AB.NativeHUD.holders.xp:GetWidth()==520)
Build('buffs'); assert(rows[1][2].text=='Enable Aura Mover'); rows[2][1].setValue(5)
assert(AB.NativeHUD.holders.buffs:GetWidth()==174 and AB.NativeHUD.holders.debuffs:GetWidth()==282)
Build('debuffs'); rows[2][1].setValue(4); assert(AB.NativeHUD.holders.debuffs:GetWidth()==138)
rows[1][2].setValue(false); assert(select(2,DebuffButton1:GetPoint(1))==UIParent)
rows[1][2].setValue(true); assert(select(2,DebuffButton1:GetPoint(1))==AB.NativeHUD.holders.debuffs)
-- Position resets apply only to the selected bar; switching never clears saves.
local p=AB.GetSettings(); local buffPos=p.barPositions.hud_buffs; local barPos=p.barPositions.bar1
assert(p.barPositions.hud_debuffs and buffPos and barPos)
optionButtons['Reset Selected Bar Position'](); assert(not p.barPositions.hud_debuffs and p.barPositions.hud_buffs==buffPos and p.barPositions.bar1==barPos)
Build('bar1'); assert(p.barPositions.bar1==barPos)
optionButtons['Reset Selected Bar Position'](); assert(not p.barPositions.bar1 and p.barPositions.hud_buffs==buffPos)
AB.SelectWrathBar('invalid'); assert(AB.selectedWrathBar=='bar1')
for _,key in ipairs(rows[1][1].order) do Build(key); assert(rows[1][1].getValue()==key) end
local mapping=EllesmereUI._ELEMENT_SETTINGS_MAP.EUI335_HUD_xp
assert(mapping.page=='Action Bars' and mapping.sectionName=='BAR SELECTION')
mapping.preSelectFn(); assert(AB.selectedWrathBar=='xp')
Build('xp'); assert(rows[4][2].text=='Hide Blizzard Bar Art')
rows[4][2].setValue(false); assert(MainMenuBarTexture0:GetAlpha()==.8)
rows[4][2].setValue(true); assert(MainMenuBarTexture0:GetTexture()==nil)
optionButtons['Reset All Bar Positions'](); assert(next(p.barPositions)==nil)
''')
bindings=ET.parse(root/'EllesmereUIActionBars/Bindings.xml').getroot()
assert len(bindings)==12
for i,binding in enumerate(bindings,1):
    assert binding.attrib['name']==f'EUI335_BAR6_BUTTON{i}'
    assert f'EllesmereUIActionBars_bar6Button{i}:Click' in binding.text
# Check real Core default migration and mover adapters instead of only fixture stubs.
lua.execute(core_source)
lua.execute('''
EllesmereUIDB={activeProfile='Existing',profiles={Existing={addons={EllesmereUIActionBars={enabled=true,
    barPositions={bar1={point='CENTER',relPoint='CENTER',x=555,y=222}},bars={bar1={size=45}}}}}}}
local migrated=EllesmereUI.Lite.NewDB('EllesmereUIActionBarsDB',AB.defaults)
assert(migrated.profile.bars.bar1.size==45 and migrated.profile.barPositions.bar1.x==555)
assert(migrated.profile.nativeHUD.micro and migrated.profile.nativeHUD.buffs and migrated.profile.nativeHUD.auraColumns==8)
assert(migrated.profile.hideArtwork==true and migrated.profile.nativeHUD.xpWidth==nil)
AB.addon.db=migrated
''')
core_main=(root/'EllesmereUI/EllesmereUI.lua').read_text(encoding='utf-8-sig')
make='function EllesmereUI.MakeUnlockElement('+core_main.split('function EllesmereUI.MakeUnlockElement(',1)[1].split('\n-------------------------------------------------------------------------------',1)[0]
lua.execute(make)
lua.execute('''
local elements=AB.NativeHUD.Elements()
for _,element in ipairs(elements) do
    assert(element.savePosition and element.loadPosition and element.applyPosition and not element.savePos)
    local expectedX=44+(element.key=='EUI335_HUD_buffs' and element.getFrame():GetWidth()/2 or 0)
    element.savePosition(element.key,'CENTER','CENTER',44,55); element.applyPosition()
    assert(element.loadPosition(element.key).x==expectedX and select(4,element.getFrame():GetPoint(1))==expectedX)
    element.clearPosition(element.key); assert(element.loadPosition(element.key)==nil)
end
''')
assert (root/'EllesmereUIActionBars/Media/Textures_335/elvui-norm.tga').read_bytes()==(root/'ElvUI/Media/Textures/normTex2.tga').read_bytes()
# Execute the real Core overlay catalogue/show logic. It must defer to each
# enabled Wrath aura mover and retire overlays from earlier unlock sessions.
overlay_defs='local function BlizzAuraOverlayFrame('+unlock_source.split('local function BlizzAuraOverlayFrame(',1)[1].split('local function CreateBlizzOwnedOverlay(',1)[0]
overlay_show=unlock_source.split('local function ShowBlizzOwnedOverlays(',1)[1].split('local function HideBlizzOwnedOverlays(',1)[0]
lua.execute('''
overlayFrames={}
local _blizzOwnedOverlays=overlayFrames
local function CreateBlizzOwnedOverlay(def,parent)
    local f=CreateFrame('Frame',nil,parent)
    f._forceCollapse=function() f.collapses=(f.collapses or 0)+1 end
    return f
end
'''+overlay_defs+'\nlocal function ShowBlizzOwnedOverlays('+overlay_show+'\nShowAuraOverlayFixture=ShowBlizzOwnedOverlays')
lua.execute('''
DebuffFrame=CreateFrame('Frame','DebuffFrame',UIParent); DebuffFrame:SetWidth(200)
EllesmereUI._unlockRegisteredElements={}
ShowAuraOverlayFixture(UIParent)
assert(overlayFrames.Buffs:IsShown() and overlayFrames.Debuffs:IsShown())
for _,element in ipairs(unlockElements) do EllesmereUI._unlockRegisteredElements[element.key]=element end
local p=AB.GetSettings(); AB.NativeHUD.Apply()
ShowAuraOverlayFixture(UIParent)
assert(not overlayFrames.Buffs:IsShown() and not overlayFrames.Debuffs:IsShown(),'Duplicate read-only aura overlay beside the real mover')
assert(BuffFrame:IsShown() and BuffButton1:IsShown(),'Removing the overlay hid native buff icons')
assert(select(2,BuffButton1:GetPoint(1))==AB.NativeHUD.holders.buffs)
p.nativeHUD.buffs=false; AB.NativeHUD.Apply(); ShowAuraOverlayFixture(UIParent)
assert(overlayFrames.Buffs:IsShown() and not overlayFrames.Debuffs:IsShown())
p.nativeHUD.buffs=true; AB.NativeHUD.Apply(); ShowAuraOverlayFixture(UIParent)
assert(not overlayFrames.Buffs:IsShown())
local buffHolder=AB.NativeHUD.holders.buffs; AB.NativeHUD.holders.buffs=nil
ShowAuraOverlayFixture(UIParent); assert(overlayFrames.Buffs:IsShown(),'Uninitialized mover suppressed the native fallback')
AB.NativeHUD.holders.buffs=buffHolder; ShowAuraOverlayFixture(UIParent); assert(not overlayFrames.Buffs:IsShown())
p.enabled=false; AB.NativeHUD.Apply(); ShowAuraOverlayFixture(UIParent)
assert(overlayFrames.Buffs:IsShown() and overlayFrames.Debuffs:IsShown())
p.enabled=true; AB.NativeHUD.Apply(); ShowAuraOverlayFixture(UIParent)
assert(not overlayFrames.Buffs:IsShown() and not overlayFrames.Debuffs:IsShown())
local count=#allFrames; ShowAuraOverlayFixture(UIParent); assert(#allFrames==count)
''')
lua.execute('''
local p=AB.GetSettings(); p.nativeHUD.xp=true; p.nativeHUD.reputation=true
level=70; faction={'Test Faction',5,3000,9000,4500}; AB.NativeHUD.Apply()
assert(AB.NativeHUD.holders.xp:IsShown() and AB.NativeHUD.holders.reputation:IsShown())
EllesmereUI._ModuleNS.EllesmereUIDataBars={ProgressUsed=function(key) return key=='xp' end}
AB.NativeHUD.UpdateData(); assert(not AB.NativeHUD.holders.xp:IsShown() and AB.NativeHUD.holders.reputation:IsShown())
assert(MainMenuExpBar:GetAlpha()==0,'DataBars handoff restored duplicate native XP bar')
local elems=AB.NativeHUD.Elements(); assert(elems[3].isHidden() and not elems[4].isHidden())
EllesmereUI._ModuleNS.EllesmereUIDataBars=nil; AB.NativeHUD.UpdateData()
assert(AB.NativeHUD.holders.xp:IsShown() and not elems[3].isHidden(),'Removing DataBars did not restore HUD XP')
''')
print('PASS: real Wrath LAB/secure paging/bindings/vehicle/drag; ElvUI XP texture/colors/empty/rested layers; native HUD and aura movers, combat/restore; reversible art toggle; DataBars XP/rep handoff and fallback; one settings page with 14 choices, isolated layouts/position resets/mover shortcuts; shared cards, real Core profile migration/MakeUnlockElement and XML. Native taint/rendering require in-game testing.')
