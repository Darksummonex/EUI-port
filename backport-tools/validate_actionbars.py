"""Run real Wrath LAB, module, secure snippets and options against explicit legacy contracts."""
from pathlib import Path
import sys
import xml.etree.ElementTree as ET
from game_paths import ADDONS, DATA, WTF
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
lua.execute((root/'EllesmereUIActionBars/EUI_ActionBars_335_EndCaps.lua').read_text(),'EllesmereUIActionBars',ns)
lua.execute((root/'EllesmereUIActionBars/EUI_NativeHUD_335.lua').read_text(),'EllesmereUIActionBars',ns)
lua.execute('''
local m=getmetatable(UIParent).__index
function m:EnableKeyboard(v) self.keyboard=v end
function m:EnableMouseWheel(v) self.wheel=v end
function m:SetCheckedTexture(t) self.checkedTexture=t end
function m:GetChecked() return self.checked end
for _,k in ipairs({"SetMovable","SetClampedToScreen","StartMoving","StopMovingOrSizing"}) do m[k]=function() end end
StaticPopupDialogs,UISpecialFrames,tinsert={}, {}, table.insert
function StaticPopup_Show(name) shownPopup=name end
DEFAULT_CHAT_FRAME={AddMessage=function(_,msg) lastChat=msg end}
function IsControlKeyDown() return ctrlDown or false end
''')
lua.execute((root/'EllesmereUIActionBars/EUI_QuickKeybind_335.lua').read_text(),'EllesmereUIActionBars',ns)
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
-- Quick Keybind Mode: real binding writes through a modeled binding table, then restored.
local Q=AB.QuickKeybind
assert(Q and SLASH_EUI335QUICKKEYBIND1=="/kb" and SlashCmdList.EUI335QUICKKEYBIND==Q.Toggle)
local function Copy(t) local r={}; for k,v in pairs(t) do r[k]={unpack(v)} end; return r end
local savedKeys,blockSet=Copy(bindingKeys),SetBinding
local actions,saved,loaded={},nil,nil
for command,keys in pairs(bindingKeys) do for _,key in ipairs(keys) do actions[key]=command end end
function GetBindingAction(key) return actions[key] or "" end
function SetBinding(key,command)
    assert(not combat,"binding written in combat")
    local old=actions[key]
    if old and bindingKeys[old] then for i=#bindingKeys[old],1,-1 do if bindingKeys[old][i]==key then table.remove(bindingKeys[old],i) end end end
    actions[key]=command
    if command then bindingKeys[command]=bindingKeys[command] or {}; table.insert(bindingKeys[command],key) end
end
function SaveBindings(set) saved=set end
function LoadBindings(set) loaded=set end
function GetCurrentBindingSet() return 1 end
combat=true; Q.Open(); assert(not Q.open and lastChat:find("combat")); combat=false
local p2=AB.GetSettings("bar2"); p2.barVisibility="mouseover"; AB.Apply(); hover=false; AB.UpdateAlpha()
assert(AB.bars.bar2:GetAlpha()==0)
Q.Open()
assert(Q.open and AB.quickKeybind and EUI335QuickKeybindFrame:IsShown() and AB.bars.bar2:GetAlpha()==1)
local o=Q.overlays[AB.bars.bar1.buttons[1]]
assert(o and o:IsShown() and o.command=="ACTIONBUTTON1" and o.label=="Action Bar 1 - Button 1")
assert(Q.overlays[AB.bars.bar2.buttons[1]].command=="MULTIACTIONBAR1BUTTON1")
assert(not Q.overlays[AB.bars.bar6.buttons[1]] or not Q.overlays[AB.bars.bar6.buttons[1]]:IsShown())
local pet=Q.overlays[PetActionButton1]; assert(pet and pet.command=="BONUSACTIONBUTTON1")
assert(Q.overlays[ShapeshiftButton1].command=="SHAPESHIFTBUTTON1")
o:GetScript("OnEnter")(o); assert(o.keyboard==true and GameTooltip.owner==o)
o:GetScript("OnKeyDown")(o,"LSHIFT"); assert(GetBindingAction("LSHIFT")=="")
modified=true; o:GetScript("OnKeyDown")(o,"2"); modified=false
assert(GetBindingAction("SHIFT-2")=="ACTIONBUTTON1" and Q.dirty)
ctrlDown=true; o:GetScript("OnMouseDown")(o,"Button4"); ctrlDown=false
o:GetScript("OnMouseWheel")(o,1)
local keys={GetBindingKey("ACTIONBUTTON1")}
assert(#keys==2 and keys[1]=="CTRL-BUTTON4" and keys[2]=="MOUSEWHEELUP",table.concat(keys,","))
o:GetScript("OnMouseDown")(o,"LeftButton"); assert(#{GetBindingKey("ACTIONBUTTON1")}==2)
o:GetScript("OnMouseDown")(o,"RightButton"); assert(select("#",GetBindingKey("ACTIONBUTTON1"))==0)
o:GetScript("OnLeave")(o); assert(o.keyboard==false)
o:GetScript("OnKeyDown")(o,"ESCAPE")
assert(not Q.open and loaded==1 and saved==nil and not o:IsShown() and not EUI335QuickKeybindFrame:IsShown())
assert(not AB.quickKeybind and AB.bars.bar2:GetAlpha()==0)
Q.Open(); local check=EUI335QuickKeybindFrame.check; assert(check:GetChecked()==false)
check:SetChecked(true); check:GetScript("OnClick")(check); assert(Q.set==2)
check:SetChecked(false); check:GetScript("OnClick")(check); assert(check:GetChecked()==true and shownPopup=="EUI335_QK_ACCOUNT")
StaticPopupDialogs.EUI335_QK_ACCOUNT.OnAccept(); assert(Q.set==1 and loaded==1)
StaticPopupDialogs.EUI335_QK_RESET.OnAccept(); assert(loaded==0)
Q.Toggle(); assert(not Q.open and saved==1)
saved=nil; Q.Open(); combat=true
for _,f in ipairs(allFrames) do if f.events and f.events.PLAYER_REGEN_DISABLED and f.scripts.OnEvent then f.scripts.OnEvent(f,"PLAYER_REGEN_DISABLED") end end
assert(not Q.open and saved==1 and lastChat:find("combat")); combat=false
p2.barVisibility="always"; bindingKeys=savedKeys; SetBinding=blockSet; AB.Apply()
''')
lua.execute('''
local main=AB.bars.bar1
local button=main.buttons[1]
assert(button:GetAttribute("action")==1 and button._state_action==1 and button.icon:GetTexture()=="icon-1")
assert(button.cooldown.duration==3 and button.count:GetText()==5)
button:GetScript("OnEnter")(button); assert(GameTooltip.action==1)
button:GetScript("OnLeave")(button)
assert(main.bindings["1"][1]==button:GetName() and main.bindings["SHIFT-1"])
for raw,short in pairs({["SHIFT-1"]="S1",["CTRL-1"]="C1",["ALT-Q"]="AQ",["CTRL-SHIFT-2"]="CS2",["BUTTON4"]="M4",
    ["NUMPAD5"]="N5",["NUMPADPLUS"]="N+",["SHIFT-MOUSEWHEELUP"]="SMwU",["s-1"]="S1",["c-s-3"]="CS3",["Num Pad 7"]="N7",
    ["Middle Mouse"]="M3",["1"]="1",["F"]="F"}) do
    assert(AB.ShortKey(raw)==short,raw.." -> "..tostring(AB.ShortKey(raw)))
end
button.hotkey:SetText("CTRL-2"); assert(button.hotkey:GetText()=="C2")
PetActionButton1HotKey:SetText("s-1"); assert(PetActionButton1HotKey:GetText()=="S1")
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
assert(unlockFolder=="EllesmereUIActionBars" and #unlockElements==18)
-- Bars 7-10: off by default, pages 7-10 (slots 73-120), own bindings and movers.
for n=7,10 do
    local key="bar"..n
    assert(AB.GetSettings(key).enabled==false and not AB.bars[key]:IsShown() and next(AB.bars[key].bindings)==nil)
    assert(AB.bars[key].buttons[1]:GetAttribute("action")==(n-1)*12+1 and AB.bars[key].buttons[12]:GetAttribute("action")==n*12)
    assert(unlockElements[n].key=="EUI335_AB_"..key and unlockElements[n].label=="Action Bar "..n and unlockElements[n].isHidden())
    assert(_G["BINDING_NAME_EUI335_BAR"..n.."_BUTTON12"]=="Action Bar "..n.." - Button 12")
end
class="WARRIOR"; assert(AB.PageShare("bar7")=="Battle Stance" and AB.PageShare("bar10")==nil and AB.PageShare("bar6")==nil)
class="DRUID"; assert(AB.PageShare("bar10")=="Moonkin Form" and AB.PageShare("bar8")=="Prowl")
class="MAGE"; assert(AB.PageShare("bar7")==nil)
class="WARRIOR"; AB.GetSettings("bar1").disableFormPaging=true; assert(AB.PageShare("bar7")==nil)
AB.GetSettings("bar1").disableFormPaging=false
bindingKeys.EUI335_BAR7_BUTTON1={"F7"}; AB.GetSettings("bar7").enabled=true; AB.Apply()
assert(AB.bars.bar7:IsShown() and AB.bars.bar7.bindings.F7 and AB.bars.bar7.bindings.F7[1]=="EllesmereUIActionBars_bar7Button1")
combat=true; page=1; TickDrivers(); assert(AB.bars.bar7.buttons[1]:GetAttribute("action")==73,"Extra bars do not page")
combat=false; AB.GetSettings("bar7").enabled=false; bindingKeys.EUI335_BAR7_BUTTON1=nil; AB.Apply()
assert(not AB.bars.bar7:IsShown() and next(AB.bars.bar7.bindings)==nil)
-- Mover shortcut works before the lazy options module has ever loaded.
local hudMap=EllesmereUI._ELEMENT_SETTINGS_MAP.EUI335_HUD_xp
assert(hudMap.page=='Menu, Bags & XP Bars' and hudMap.sectionName=='EXPERIENCE BAR' and hudMap.preSelectFn==nil)
EllesmereUI._ELEMENT_SETTINGS_MAP.EUI335_AB_bar3.preSelectFn()
assert(AB.selectedWrathBar=='bar3' and EllesmereUI._ELEMENT_SETTINGS_MAP.EUI335_AB_bar3.page=='Bar Display')
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
AB.GetSettings("bar1").hideKeybind=true; AB.GetSettings("bar1").hideMacroText=true; AB.GetSettings().clickOnDown=true
AB.Apply(); assert(not main.buttons[7]:IsShown() and main:GetWidth()==152 and main:GetHeight()==100)
assert(button.config.hideElements.hotkey and button.config.hideElements.macro and button.clicks[1]=="AnyDown")
assert(not AB.bars.bar2.buttons[1].config.hideElements.hotkey,'Keybind text is per bar')
AB.GetSettings("bar1").hideKeybind=false; AB.GetSettings("bar1").hideMacroText=false; AB.Apply()
assert(not button.config.hideElements.hotkey and not button.config.hideElements.macro)
AB.GetSettings("bar1").barVisibility="in_combat"; AB.Apply(); assert(not main:IsShown() and next(main.bindings)==nil)
combat=true; TickDrivers(); assert(main:IsShown() and main.bindings.F1)
combat=false; TickDrivers(); assert(not main:IsShown())
AB.GetSettings("bar1").barVisibility="mouseover"; AB.Apply(); hover=false; AB.UpdateAlpha(); assert(main:GetAlpha()==0)
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
experience:RunScript('OnEnter'); assert(GameTooltip.owner==experience and #GameTooltip.lines==4)
experience:RunScript('OnMouseDown','RightButton'); assert(xpRightClick[1]==MainMenuExpBar and xpRightClick[2]=='RightButton')
xp=600; rested=0; H.events:RunScript('OnEvent','PLAYER_XP_UPDATE','player')
assert(experience.fill.value==600 and experience.rested.value==0 and not experience.rested:IsShown())
xp=0; class='MAGE'; H.UpdateData()
assert(experience.fill.value==0 and experience.rested.value==0 and not experience.rested:IsShown())
assert(experience.fill.barColor[1]==0 and experience.fill.barColor[2]==.4 and experience.fill.barColor[3]==1 and experience.bgColor[1]==.06)
xp=600; rested=800; H.UpdateData(); assert(experience.rested.value==1000 and experience.rested:IsShown())
rested=nil; H.UpdateData(); assert(experience.rested.value==0 and not experience.rested:IsShown())
-- XP bar extras: texts, Quest XP Overlay (selection restored), dividers + Smart Ticks, colours.
do
    local XP,hud=H.XP,AB.GetSettings().nativeHUD
    local snapshot={}; for k,v in pairs(hud) do snapshot[k]=v end
    assert(XP.FmtNum(6811)=='6,811' and XP.FmtNum(17600)=='17.6K' and XP.FmtPct(25)=='25%' and XP.FmtPct(89.6)=='89.6%')
    assert(XP.FmtDur(90)=='1m' and XP.FmtDur(5040)=='1h 24m' and XP.FmtDur(273600)=='3d 4h')
    local log={{'Elwynn',true},{'Done',false,1,100},{'Open',false,nil,120},{'Failed',false,-1,900},{'Westfall',true},{'Far',false,1,50}}
    local selected,zone=3,'Elwynn'
    function GetNumQuestLogEntries() return #log end
    function GetQuestLogTitle(i) local q=log[i]; return q[1],1,nil,nil,q[2],nil,q[3] end
    function GetQuestLogSelection() return selected end
    function SelectQuestLogEntry(i) selected=i end
    function GetQuestLogRewardXP() local q=log[selected]; return q and q[4] or 0 end
    function GetRealZoneText() return zone end
    hud.xpQuestOverlay=true; hud.xpTextLeft='questVal'; hud.xpTextRight='curMaxRem'; hud.xpTextTopLeft='level'
    hud.xpDividers=true; hud.xpSmartTicks=true; hud.xpDividerText=true; hud.xpFillStyle='flat'; hud.xpColor={r=1,g=0,b=0}
    level=20; xp=500; rested=0; H.Apply(); XP.QuestsDirty(); H.UpdateData()
    assert(selected==3,'quest selection not restored')
    assert(experience.questDone.value==650 and experience.questOpen.value==770 and experience.questDone:IsShown())
    assert(experience.xpTexts.Left:GetText()=='Completed: 150' and experience.xpTexts.Right:GetText()=='500 / 1,000 (Remaining: 500)')
    assert(experience.xpTexts.TopLeft:GetText()==(LEVEL or 'Level')..' 20' and experience.text:GetText()=='XP: 50.0%')
    assert(experience.fill.barColor[1]==1 and experience.fill:GetFrameLevel()>experience.questDone:GetFrameLevel())
    assert(experience.xpTickLabels[2]:GetText()=='10%' and experience.xpTicks[2].count==1 and experience.xpTicks[1].count>1)
    assert(not experience.xpTicks[9][1]:IsShown() and experience.xpTicks[11][1]:IsShown(),'Smart Ticks')
    hud.xpQuestZone=true; hud.xpQuestCompleted=true; XP.QuestsDirty(); XP.ScanQuests(hud)
    local all,done,open=XP.QuestXP(); assert(all==150 and done==100 and open==0)
    hud.xpTextLeft='none'; H.Apply(); assert(not experience.xpTexts.Left:IsShown())
    hud.xpTextCenter='none'; H.Apply(); H.UpdateData(); assert(not experience.text:IsShown())
    hud.xpQuestOverlay=false; hud.xpDividers=false; H.Apply(); H.UpdateData()
    assert(not experience.questDone:IsShown() and not experience.xpTickHost:IsShown())
    -- Luxthos layout: combined texts, rested after the quest XP, spark.
    XP.ApplyLuxthos(hud); XP.ScanQuests(hud); rested=100; H.Apply(); H.UpdateData()
    local t=experience.xpTexts
    assert(t.Left:GetText()==(LEVEL or 'Level')..' 20' and experience.text:GetText()=='500 / 1,000 (Remaining: 500)')
    assert(t.Right:GetText()=='50% (65%)',t.Right:GetText())
    assert(t.BottomRight:GetText()=='Completed: |cFFFF970015%|r - Rested: |cFF4F90FF10%|r',t.BottomRight:GetText())
    assert(t.TopRight:GetText():find('Time this session',1,true) and t.BottomLeft:GetText():find('Leveling in',1,true))
    assert(experience.rested.value==870 and experience.xpSpark:IsShown() and hud.xpColor.r==.3 and hud.xpFillStyle=='HORIZONTAL')
    -- Show at Max Level: full bar, Max Level, time played, no quest or rate texts.
    level=80; hud.xpShowMaxLevel=true; H.UpdateData()
    assert(experience:IsShown() and experience.fill.value==experience.fill.maximum and experience.text:GetText()=='Max Level')
    assert(t.Right:GetText()=='' and t.TopLeft:GetText()=='Time played: --' and not experience.questDone:IsShown())
    XP.OnPlayed(18000,600); H.UpdateData(); assert(t.TopLeft:GetText()=='Time played: 5h 0m',t.TopLeft:GetText())
    hud.xpShowMaxLevel=false; H.UpdateData(); assert(not experience:IsShown())
    XP.Save(); local saved=EllesmereUIDB.xpBarChars[UnitGUID('player')]; assert(saved and saved.total==18000 and saved.levelBase==600)
    EllesmereUIDB.xpBarChars=nil
    for k in pairs(hud) do hud[k]=nil end; for k,v in pairs(snapshot) do hud[k]=v end
    rested=0
    GetNumQuestLogEntries,GetQuestLogTitle,GetQuestLogSelection,SelectQuestLogEntry,GetQuestLogRewardXP,GetRealZoneText=nil,nil,nil,nil,nil,nil
    level=79; xp=600; H.Apply(); H.UpdateData(); assert(experience.text:IsShown() and experience.text:GetText()=='XP: 60.0%')
end
faction={'Another Faction',5,-3000,0,-1200}; H.events:RunScript('OnEvent','UPDATE_FACTION')
assert(rep.fill.value==1800 and rep.fill.maximum==3000 and rep.faction=='Another Faction')
level=80; faction={}; H.UpdateData(); assert(not experience:IsShown() and not rep:IsShown())
EllesmereUI._unlockModeSessionActive=true; H.UpdateData(); assert(experience:IsShown() and rep:IsShown())
EllesmereUI._unlockModeSessionActive=false; H.UpdateData(); assert(not experience:IsShown() and not rep:IsShown())
EllesmereUI._unlockModeSessionActive=true
-- Buffs/debuffs have independent real movers even with no auras or data.
assert(unlockElements[17].getFrame()==buffs and unlockElements[18].getFrame()==debuffs and not unlockElements[17].isHidden())
for i=13,18 do
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
unlockElements[17].savePos(nil,'CENTER','CENTER',321,123); EllesmereUI._unlockModeSessionActive=false; H.Apply()
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
local LinkRow=function(_,y,_,_,page,section) assert((page=="Bar Display" and section=="TEXT") or (page=="Menu, Bags & XP Bars" and section=="EXPERIENCE BAR")); return y-30 end
local function TileActionBars('''+body+'\nreturn TileActionBars')
    lua.globals().cardBuilder=card
    lua.execute('rows={}; assert(cardBuilder(UIParent,0,EllesmereUI.Widgets,{folder="EllesmereUIActionBars",display="Action Bars"})<0)')
    if file=='EUI_Fonts_Options.lua':
        lua.execute('rows[1][2].setValue(14); assert(AB.GetSettings().fontSize==14)')
lua.execute('IsLoggedIn=function() return true end; function EllesmereUI:RefreshPage(force) refreshForced=force end')
lua.execute((root/'EllesmereUIOptions/EUI_ActionBars_335_Options.lua').read_text())
lua.execute('''
local pages=testModule and testModule.pages
assert(pages and #pages==3 and pages[1]=='Bar Display' and pages[2]=='Menu, Bags & XP Bars' and pages[3]=='Bar Animations' and SlashCmdList.EUI335ACTIONBARS)
EllesmereUI.Widgets={
    DualRow=function(_,parent,y,left,right) rows[#rows+1]={left,right}; return {},50 end,
    SectionHeader=function(_,parent,label,y) local h={GetPoint=function() return 'TOPLEFT',parent,'TOPLEFT',0,y end}; sections[label]=h; return h,30 end,
    WideButton=function(_,parent,text,y,fn) optionButtons[text]=fn; return {},40 end,
}
function EllesmereUI:SetContentHeader(fn) headerBuilder=fn end
function EllesmereUI:InvalidateContentHeaderCache() headerInvalidated=true end
EllesmereUI.SmoothScrollTo=function(y) scrolledTo=y end
EllesmereUI.CreatePreviewHitOverlay=function(el,nav,key,isText) hits[#hits+1]={el=el,nav=nav,key=key,text=isText}; return CreateFrame('Button',nil,UIParent) end
local function Find(label,nth)
    nth=nth or 1
    for _,r in ipairs(rows) do for i=1,2 do if r[i] and r[i].text==label then nth=nth-1; if nth==0 then return r[i] end end end end
end
local function Build(page,key)
    if key then AB.SelectWrathBar(key,false) end
    rows,sections,optionButtons,headerBuilder={},{},{},nil
    assert(testModule.buildPage(page,UIParent,0)>0)
end
-- Bar Display: per-bar settings, Retail visibility lane, header preview.
AB.SelectWrathBar('bar2'); assert(AB.selectedWrathBar=='bar2' and refreshForced==true and headerInvalidated)
Build('Bar Display','bar2')
Find('Icon Size').setValue(42); assert(AB.bars.bar2.buttons[1]:GetWidth()==42 and AB.bars.bar1.buttons[1]:GetWidth()==48)
local vis=Find('Visibility'); assert(vis.values.never and vis.values.in_raid)
vis.setValue('never'); assert(not AB.bars.bar2:IsShown() and AB.GetSettings('bar2').enabled==false)
vis.setValue('always'); assert(AB.bars.bar2:IsShown() and AB.GetSettings('bar2').enabled==true)
local oldSizeSetter=Find('Icon Size').setValue
Build('Bar Display','bar3'); oldSizeSetter(43)
assert(AB.bars.bar2.buttons[1]:GetWidth()==43 and AB.bars.bar3.buttons[1]:GetWidth()==36,'Stale setter leaked across bars: '..AB.bars.bar2.buttons[1]:GetWidth()..' '..AB.bars.bar3.buttons[1]:GetWidth())
assert(Find('Shift Modifier')==nil and Find('Always Show Buttons'),'Bar 3 page rows')
assert(optionButtons['Quick Keybind Mode (/kb)'] and optionButtons['Open Unlock Mode'],'Top buttons')
optionButtons['Quick Keybind Mode (/kb)'](); assert(AB.QuickKeybind.open); AB.QuickKeybind.Close(false); assert(not AB.QuickKeybind.open)
Build('Bar Display','bar1')
assert(AB.GetSettings('bar1').buttons==6 and AB.GetSettings('bar1').buttonsPerRow==3)
Find('Number of Rows').setValue(1); assert(AB.GetSettings('bar1').buttonsPerRow==6 and AB.bars.bar1:GetHeight()==48)
Find('Number of Rows').setValue(2); Find('Number of Icons').setValue(12)
assert(AB.GetSettings('bar1').buttons==12 and AB.GetSettings('bar1').buttonsPerRow==6 and AB.bars.bar1.buttons[12]:IsShown())
Find('Shift Modifier').setValue(2); assert(AB.GetPageDriver():find('%[mod:shift%] 2;'))
local main1=AB.bars.bar1.buttons[1]
modShift=true; TickDrivers(); assert(main1:GetAttribute('action')==13,'Shift paging did not reach page 2')
modShift=false; TickDrivers(); assert(main1:GetAttribute('action')==1)
Find('Shift Modifier').setValue(0); assert(not AB.GetPageDriver():find('mod:shift'))
Find('Hide Keybind Text').setValue(true); assert(AB.bars.bar1.buttons[1].config.hideElements.hotkey and not AB.bars.bar2.buttons[1].config.hideElements.hotkey)
Find('Hide Keybind Text').setValue(false)
assert(Find('Hide Blizzard Bar Art'))
Find('Hide Blizzard Bar Art').setValue(false); assert(MainMenuBarTexture0:GetAlpha()==.8)
Find('Hide Blizzard Bar Art').setValue(true); assert(MainMenuBarTexture0:GetTexture()==nil)
-- Live preview mirrors the bar and each element navigates to its options.
assert(headerBuilder and testModule.getHeaderBuilder('Bar Display')==headerBuilder and testModule.getHeaderBuilder('Bar Animations')==nil,'Header builder registration')
hits={}; local hdr=CreateFrame('Frame',nil,UIParent); hdr:SetWidth(900); hdr:Show()
local headerH=headerBuilder(hdr,900)
assert(headerH>64 and #hits==1+12*4,'Header preview '..tostring(headerH)..' hits '..#hits)
local keybindHit
for _,hit in ipairs(hits) do if hit.key=='keybind' then keybindHit=hit; break end end
assert(keybindHit and keybindHit.text and keybindHit.el:GetParent():GetParent():GetWidth()==AB.GetSettings('bar1').size,'Preview button size')
assert(keybindHit.el:GetParent():GetParent().icon:GetTexture()=='icon-1','Preview shows the real action icon')
keybindHit.nav('keybind'); assert(scrolledTo==math.max(0,math.abs(select(5,sections.TEXT:GetPoint(1)))-40))
-- Menu, Bags & XP Bars page keeps every native HUD control.
Build('Menu, Bags & XP Bars')
-- XP Bar Style (Retail 9.4): Blizz Default hands XP and reputation back to Blizzard's bars.
local style=Find('XP Bar Style'); assert(style and style.order[1]=='eui' and style.order[2]=='luxthos' and style.order[3]=='default' and style.getValue()=='eui')
assert(style.values._menuOpts.onItemHover and Find('Width',1).disabled()==false)
-- Luxthos is a preset of the EllesmereUI bar; EllesmereUI puts the default look back.
style.setValue('luxthos'); local nh=AB.GetSettings().nativeHUD
assert(style.getValue()=='luxthos' and nh.xpFillStyle=='HORIZONTAL' and nh.xpTextLeft=='level' and nh.xp==true and Find('Width',1).disabled()==false)
nh.xpSpark=false; assert(style.getValue()=='eui'); nh.xpSpark=true; assert(style.getValue()=='luxthos')
style.setValue('eui')
assert(style.getValue()=='eui' and nh.xpFillStyle=='flat' and nh.xpTextLeft==nil and nh.xpTextCenter=='classic' and nh.xpSpark==false and nh.xpColor.r==0)
style.setValue('default')
assert(style.getValue()=='default' and MainMenuExpBar:GetAlpha()==.8 and ReputationWatchBar:GetAlpha()==.75)
assert(Find('Width',1).disabled()==true and Find('Width',1).rawTooltip and Find('Fill Style').disabled()==true)
style.setValue('eui'); assert(MainMenuExpBar:GetAlpha()==0 and ReputationWatchBar:GetAlpha()==0 and AB.GetSettings().nativeHUD.reputation)
Find('Micro Menu Skin').setValue(false); assert(CharacterMicroButton:GetParent()==nativeParent)
assert(MainMenuBarArtFrame:IsShown() and MainMenuBarArtFrame.functionalChild:IsShown() and MainMenuBarTexture0:GetTexture()==nil)
Find('Micro Menu Skin').setValue(true); assert(CharacterMicroButton:GetParent()==AB.NativeHUD.holders.micro)
assert(Find('Micro Button Size').getValue()==36)
Find('Micro Button Size').setValue(32); assert(CharacterMicroButton:GetWidth()==32 and MainMenuBarBackpackButton:GetWidth()==36)
Find('Micro Spacing').setValue(7); assert(AB.GetSettings().nativeHUD.microSpacing==7 and AB.GetSettings().nativeHUD.bagsSpacing==nil)
Find('Bag Button Size').setValue(24); assert(MainMenuBarBackpackButton:GetWidth()==24 and CharacterMicroButton:GetWidth()==32)
local consolidate=Find('Consolidate Bags').setValue; consolidate(true)
assert(AB.NativeHUD.holders.bags:GetWidth()==24 and MainMenuBarBackpackButton:GetParent()==AB.NativeHUD.holders.bags)
assert(CharacterBag0Slot:GetParent()==AB.NativeHUD.hiddenBags and not AB.NativeHUD.hiddenBags:IsShown() and KeyRingButton:GetParent()==AB.NativeHUD.hiddenBags)
combat=true; consolidate(false); assert(CharacterBag0Slot:GetParent()==AB.NativeHUD.hiddenBags)
combat=false; AB.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED')
assert(CharacterBag0Slot:GetParent()==AB.NativeHUD.holders.bags and KeyRingButton:GetParent()==AB.NativeHUD.holders.bags and AB.NativeHUD.holders.bags:GetWidth()>24)
Find('Width',1).setValue(520); Find('Height',1).setValue(18)
assert(AB.NativeHUD.holders.xp:GetWidth()==520 and AB.NativeHUD.holders.xp:GetHeight()==18)
assert(AB.NativeHUD.holders.reputation:GetWidth()==AB.GetSettings().nativeHUD.barWidth)
Find('Width',2).setValue(610); Find('Height',2).setValue(20)
assert(AB.NativeHUD.holders.reputation:GetWidth()==610 and AB.NativeHUD.holders.xp:GetWidth()==520)
Find('Buff Icons Per Row').setValue(5)
assert(AB.NativeHUD.holders.buffs:GetWidth()==174 and AB.NativeHUD.holders.debuffs:GetWidth()==282)
Find('Debuff Icons Per Row').setValue(4); assert(AB.NativeHUD.holders.debuffs:GetWidth()==138)
Find('Debuff Mover').setValue(false); assert(select(2,DebuffButton1:GetPoint(1))==UIParent)
Find('Debuff Mover').setValue(true); assert(select(2,DebuffButton1:GetPoint(1))==AB.NativeHUD.holders.debuffs)
Find('Text Size').setValue(14); assert(AB.GetSettings().fontSize==14); Find('Text Size').setValue(11)
-- Position resets are scoped: HUD page clears only HUD movers, bar page only the selected bar.
local p=AB.GetSettings(); local barPos=p.barPositions.bar1
assert(p.barPositions.hud_debuffs and p.barPositions.hud_buffs and barPos)
optionButtons['Reset Menu, Bags & XP Positions'](); assert(not p.barPositions.hud_debuffs and not p.barPositions.hud_buffs and p.barPositions.bar1==barPos)
Build('Bar Display','bar2'); p.barPositions.bar2={point='CENTER',relPoint='CENTER',x=1,y=2}
optionButtons['Reset Selected Bar Position'](); assert(not p.barPositions.bar2 and p.barPositions.bar1==barPos)
AB.selectedWrathBar='invalid'; Build('Bar Display'); assert(AB.selectedWrathBar=='bar1')
-- Extra bars: listed, warned when they share a stance page, reachable by modifier paging.
local notes={}; EllesmereUI.BuildNoteRow=function(_,y,text) notes[#notes+1]=text; return y-34 end
class='WARRIOR'
Build('Bar Display','bar7'); assert(#notes==2 and notes[1]=='Action Bar 7 shares its buttons with Action Bar 1 in Battle Stance.')
notes={}; Build('Bar Display','bar10'); assert(#notes==0)
AB.GetSettings('bar1').disableFormPaging=true; Build('Bar Display','bar7'); assert(#notes==0)
AB.GetSettings('bar1').disableFormPaging=false
Build('Bar Display','bar1'); local shift=Find('Shift Modifier'); assert(shift.values[10]=='Action Bar 10' and shift.order[#shift.order]==10)
EllesmereUI.BuildNoteRow=nil; class='WARRIOR'
-- Bar Animations drive the interaction looks.
Build('Bar Animations')
Find('Pushed Type').setValue(5); assert(p.pushedTextureType==5)
Find('Highlight Type').setValue(6); assert(p.highlightTextureType==6)
Find('Show Highlight on Spell Cast').setValue(false); assert(p.showCastHighlight==false)
Find('Pushed Type').setValue(2); Find('Highlight Type').setValue(2); Find('Show Highlight on Spell Cast').setValue(true)
Build('Bar Display','bar1')
p.barPositions.hud_buffs={point='CENTER',relPoint='CENTER',x=3,y=4}
optionButtons['Reset All Bar Positions']()
for key in pairs(p.barPositions) do assert(key:sub(1,4)=='hud_','Bar position survived reset') end
assert(p.barPositions.hud_buffs,'Bar reset cleared a HUD mover')
-- End Caps (Retail 9.4, Classic art only): per side, sized and offset, horizontal bars only.
assert(Find('End Caps') and Find('End Caps').disabled()==false,'End Caps row')
local s=AB.GetSettings('bar1'); local bar=AB.bars.bar1
assert(not bar._euiCaps or not bar._euiCaps.capHost:IsShown(),'caps off by default')
s.endCapLeft=true; AB.Apply()
local st=bar._euiCaps; local host=st.capHost
assert(host:IsShown() and host:GetParent()==bar and st.capL:IsShown() and not st.capR:IsShown())
assert(st.capL:GetTexture()=='Interface\\\\MainMenuBar\\\\UI-MainMenuBar-EndCap-Dwarf' and host:GetFrameLevel()==bar:GetFrameLevel()+17)
assert(host:GetScale()==1,'48px buttons keep the art at full size')
s.endCapRight=true; s.endCapScale=50; AB.Apply(); assert(st.capR:IsShown() and host:GetScale()==.5)
local l,r,t,b=AB.AB_CapsReach('bar1',36,36,false,nil,true,true)
assert(l==50 and r==49.5 and t==31.5 and b==0,'reach at 50% '..l..' '..r..' '..t..' '..b)
Build('Bar Display','bar1'); local hdr=CreateFrame('Frame',nil,UIParent); hdr:SetWidth(900); hdr:Show()
hits={}; headerBuilder(hdr,900)
local pv=hits[1].el; while pv and not pv._caps do pv=pv:GetParent() end
assert(pv and pv._caps.capHost:IsShown(),'preview shows the caps')
s.orientation='vertical'; AB.Apply(); assert(not host:IsShown(),'vertical bars show no caps')
assert(Find('End Caps').disabled()==true)
s.orientation='horizontal'; s.endCapLeft,s.endCapRight,s.endCapScale=nil,nil,nil; AB.Apply(); assert(not host:IsShown())
''')
bindings=ET.parse(root/'EllesmereUIActionBars/Bindings.xml').getroot()
assert len(bindings)==60
for index,binding in enumerate(bindings):
    bar,i=6+index//12,index%12+1
    assert binding.attrib['name']==f'EUI335_BAR{bar}_BUTTON{i}'
    assert binding.text==f'EllesmereUIActionBars_bar{bar}Button{i}:Click("LeftButton");'
    assert ('header' in binding.attrib)==(index==0)
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
if ADDONS and (ADDONS/'ElvUI/Media/Textures/normTex2.tga').exists():
    assert (root/'EllesmereUIActionBars/Media/Textures_335/elvui-norm.tga').read_bytes()==(ADDONS/'ElvUI/Media/Textures/normTex2.tga').read_bytes()
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
lua.execute('''
-- Show Equipped Item Color: LAB's equipped border hidden by default, rarity colored when on.
local b=AB.bars.bar1.buttons[1]; local bd=b.border
function bd:SetVertexColor(...) self.vc={...} end
local equipped,info,tex=IsEquippedAction,GetActionInfo,GetActionTexture
IsEquippedAction=function(slot) return slot==b._state_action end
GetActionInfo=function(slot) if slot==b._state_action then return "item",4242 end; return info(slot) end
GetInventoryItemID=function(_,slot) return slot==13 and 4242 or nil end
GetInventoryItemQuality=function(_,slot) return slot==13 and 4 or nil end
GetInventoryItemTexture=function() return nil end
GetItemQualityColor=function(q) assert(q==4); return .64,.21,.93,'ffa335ee' end
b:UpdateAction(true); assert(not bd:IsShown(),'Equipped border shown while off')
local p=AB.GetSettings(); p.showEquippedBorder=true; AB.Apply(); b:UpdateAction(true)
assert(bd:IsShown() and bd.vc[1]==.64 and bd.vc[3]==.93 and bd.vc[4]==1,'Equipped border not rarity colored')
GetInventoryItemID=function() return nil end; GetItemInfo=function() return nil end; b:UpdateAction(true)
assert(bd.vc[1]==0 and bd.vc[2]==1 and bd.vc[4]==.5,'Unknown equipped item must fall back to green')
p.showEquippedBorder=false; AB.Apply(); b:UpdateAction(true); assert(not bd:IsShown())
IsEquippedAction,GetActionInfo,GetActionTexture=equipped,info,tex
''')
print('PASS: real Wrath LAB/secure paging/bindings/vehicle/drag; ElvUI XP texture/colors/empty/rested layers; native HUD and aura movers, combat/restore; reversible art toggle; DataBars XP/rep handoff and fallback; Retail pages (Bar Display with live clickable preview, Menu/Bags/XP, Bar Animations), per-bar text/visibility/paging, scoped position resets and mover shortcuts; shared cards, real Core profile migration/MakeUnlockElement and XML. Native taint/rendering require in-game testing.')
