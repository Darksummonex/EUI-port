"""Execute the native QoL module and real Lite lifecycle in Lua 5.1."""
from pathlib import Path
import sys
import struct
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
lua=LuaRuntime(unpack_returned_tuples=True)
for source in ['backport-tools/wrath_mock.lua','backport-tools/inventory_resources_mock.lua','backport-tools/qol_mock.lua','EllesmereUI/EllesmereUI_Lite.lua']:
    lua.execute((root/source).read_text(encoding='utf-8-sig'))
ns=lua.table()
lua.execute("ERR_INV_FULL='Inventory is full.'")
for name in ['EUI_QoL_335.lua','EUI_QoL_335_Displays.lua','EUI_QoL_335_Panels.lua','EUI_QoL_335_Mail.lua','EUI_QoL_335_Extras.lua']:
    lua.execute((root/'EllesmereUIQoL'/name).read_text(encoding='utf-8-sig'),'EllesmereUIQoL',ns)
lua.globals().Q=ns
core=(root/'EllesmereUI/EllesmereUI_Lite.lua').read_text(encoding='utf-8-sig')
safe=lua.execute('local function errorhandler('+core.split('local function errorhandler(',1)[1].split('\n-------------------------------------------------------------------------------',1)[0]+'\nreturn safecall')
safe(ns.addon.OnInitialize,ns.addon)
safe(ns.addon.OnEnable,ns.addon)
lua.execute('''
local p=Q.GetSettings(); local e=Q.events
assert(p and p.enabled and not p.autoRepair and not p.cursor.enabled and not p.raidTools.enabled)
assert(#unlockByFolder.EllesmereUIQoL==12 and not Q.frames.fps:IsShown())
e:RunScript('OnEvent','MERCHANT_SHOW'); assert(#repairs==0 and #sales==0)
p.autoRepair=true; p.guildRepair=true; p.autoSellJunk=true; Q.Apply()
e:RunScript('OnEvent','MERCHANT_SHOW'); assert(#repairs==1 and repairs[1]==false and sales[1][2]==1)
e:RunScript('OnUpdate',.3); assert(#sales==1,'Repeated sale attempted')
items['0:6'].uncached=false; e:RunScript('OnUpdate',.3); assert(sales[2][2]==6)
items['0:3'].locked=false; e:RunScript('OnEvent','MERCHANT_CLOSED'); e:RunScript('OnUpdate',.3); assert(#sales==2)
guildLimit=-1; e:RunScript('OnEvent','MERCHANT_SHOW'); assert(repairs[2]==true)
cursorHeld=true; e:RunScript('OnUpdate',.3); assert(#sales==3); cursorHeld=false
combat=true; e:RunScript('OnUpdate',.3); assert(#sales==3); combat=false
e:RunScript('OnUpdate',.3); assert(sales[4][2]==3)
e:RunScript('OnEvent','MERCHANT_CLOSED')
p.quickLoot=true; e:RunScript('OnEvent','LOOT_OPENED'); assert(#loot==3 and loot[1]==3)
shift=true; e:RunScript('OnEvent','LOOT_OPENED'); assert(#loot==3,'Shift must show the loot window'); shift=false
cvars.autoLootDefault='0'; e:RunScript('OnEvent','LOOT_OPENED'); assert(#loot==6,'Quick Loot must ignore the Auto Loot setting')
function GetLootSlotInfo(i) return 'icon','Item',1,2,i==2 end
e:RunScript('OnEvent','LOOT_OPENED'); assert(#loot==8 and loot[7]==3 and loot[8]==1,'Locked loot slot clicked'); GetLootSlotInfo=nil
assert(not e.events.LOOT_READY)
p.fillDelete=true; Q.Apply(); StaticPopup1.which='DELETE_GOOD_ITEM'; StaticPopup1:Show(); assert(StaticPopup1.editBox:GetText()=='DELETE')
StaticPopup1:Hide(); StaticPopup1.which='OTHER'; StaticPopup1.editBox:SetText(''); StaticPopup1:Show(); assert(StaticPopup1.editBox:GetText()=='')
p.trainAll=true; Q.Apply(); ClassTrainerFrame:Show(); Q.trainButton:RunScript('OnClick'); e:RunScript('OnUpdate',.3); assert(#trained==1 and trained[1]==1)
TrainerServices[2].kind='available'; Q.trainButton:RunScript('OnClick'); e:RunScript('OnEvent','TRAINER_CLOSED'); e:RunScript('OnUpdate',.3); assert(#trained==2)
p.hideErrors=true; p.hideTutorials=true; p.skipCinematics=true; Q.Apply()
UIErrorsFrame:RunScript('OnEvent','UI_ERROR_MESSAGE','bad'); UIErrorsFrame:RunScript('OnEvent','UI_INFO_MESSAGE','info'); assert(#errorEvents==1)
UIErrorsFrame:RunScript('OnEvent','UI_ERROR_MESSAGE',ERR_INV_FULL); assert(#errorEvents==2 and errorEvents[2][2]==ERR_INV_FULL,'Whitelisted error hidden')
assert(cvars.showTutorials=='0'); e:RunScript('OnEvent','CINEMATIC_START'); assert(cinematicSkipped)
p.hideErrors=false; p.hideTutorials=false; Q.Apply(); UIErrorsFrame:RunScript('OnEvent','UI_ERROR_MESSAGE','visible'); assert(#errorEvents==3 and cvars.showTutorials=='1')
inside=true; instanceKind='raid'; logging=true; p.logging.enabled=true; Q.Apply(); assert(#logCalls==0)
inside=false; Q.UpdateLogging(); assert(logging,'Stopped a manual log')
logging=false; inside=true; Q.UpdateLogging(); assert(logCalls[1]==true)
instanceKind='party'; Q.UpdateLogging(); assert(logCalls[2]==false)
p.logging.dungeons=true; Q.UpdateLogging(); assert(logCalls[3]==true)
p.logging.enabled=false; Q.Apply(); assert(logCalls[4]==false)
for _,key in ipairs({'fps','stats','coordinates','crosshair','durability','combatAlert','deathAlert','bloodlust','battleRes','movement'}) do p[key]=true end
Q.Apply(); local fps=Q.frames.fps; assert(fps.text:GetText()=='144 fps' and fps.localMs:GetText()=='45 ms' and fps.localLabel:GetText()=='(local)' and not fps.world:IsShown())
assert(Q.frames.stats.text:GetText()=='|cffffd100Crit|r  14.0%\\n|cff2ecc71Haste|r  15.0%')
assert(Q.frames.coordinates.text:GetText()=='25.0, 75.0' and Q.frames.durability:IsShown())
local reads,sets=mapReads,mapSets; WorldMapFrame:Show(); Q.UpdateDisplays(); assert(mapReads==reads and mapSets==sets and not Q.frames.coordinates:IsShown())
WorldMapFrame:Hide(); Q.UpdateDisplays(); assert(mapSets==sets+1)
durability=80; Q.UpdateDisplays(); assert(not Q.frames.durability:IsShown())
assert(Q.frames.battleRes:IsShown() and Q.frames.battleRes.text:GetText()=='599s' and not Q.frames.movement:IsShown())
p.showReady=true; Q.UpdateDisplays(); assert(Q.frames.movement.text:GetText()=='Ready' and Q.frames.movement:IsShown())
p.movementSpellID=1953; Q.UpdateDisplays(); assert(not Q.frames.movement:IsShown(),'Unlearned spell rendered ready')
playerAuras={{name='Sated',id=57724,duration=600,expires=602}}; Q.UpdateDisplays(); assert(Q.frames.bloodlust:IsShown() and Q.frames.bloodlust.text:GetText()=='600s')
playerAuras={}; p.showReady=false; Q.UpdateDisplays(); assert(not Q.frames.bloodlust:IsShown())
groupDead=true; Q.UpdateDisplays(); Q.UpdateDisplays(); local deathText=Q.frames.deathAlert.text:GetText()
assert(deathText:find('|cffff7d0aparty1|r',1,true) and deathText:find('DIED!',1,true) and Q.frames.deathAlert:IsShown(),deathText)
e:RunScript('OnEvent','PLAYER_REGEN_DISABLED'); Q.UpdateDisplays(); assert(Q.frames.combatAlert:IsShown())
now=6; Q.UpdateDisplays(); assert(not Q.frames.combatAlert:IsShown() and not Q.frames.deathAlert:IsShown())
p.cursor.enabled=true; p.cursor.gcd=true; p.cursor.trail=true; spellCooldowns[61304]={5,1.5,1}; Q.Apply()
assert(Q.cursor.frame:IsShown() and Q.cursor.pips[21]:IsShown() and not Q.cursor.pips[22]:IsShown())
Q.UpdateCursor(.05); assert(Q.trail[1]:IsShown())
mouselook=true; Q.UpdateCursor(.01); assert(not Q.cursor.frame:IsShown() and not Q.trail[1]:IsShown()); mouselook=false
p.cursor.cast=true; nativeCast={'Cast','Rank','Cast','icon',5000,9000,false,1,false}; Q.UpdateCursor(.01)
assert(Q.cursor.pips[8]:IsShown() and not Q.cursor.pips[9]:IsShown(),'Wrong native cast tuple')
nativeCast=nil; nativeChannel={'Channel','Rank','Channel','icon',5000,9000,false,false}; Q.UpdateCursor(.01)
assert(Q.cursor.pips[24]:IsShown() and not Q.cursor.pips[25]:IsShown()); nativeChannel=nil
p.cursor.combatOnly=true; Q.UpdateCursor(.1); assert(not Q.cursor.frame:IsShown())
p.shifter.enabled=true; Q.Apply(); shift=true; mouseDown=true; CharacterFrame:RunScript('OnMouseDown','LeftButton'); assert(CharacterFrame.moving)
mouseDown=false; CharacterFrame:RunScript('OnMouseUp','LeftButton'); assert(not CharacterFrame.moving and p.shifter.positions.CharacterFrame.x==450)
CharacterFrame:Hide(); CharacterFrame:Show(); assert(select(3,CharacterFrame:GetPoint(1))=='BOTTOMLEFT')
shift=false; ctrl=true; mouseDown=true; CharacterFrame:RunScript('OnMouseDown','LeftButton'); mouseDown=false; CharacterFrame:RunScript('OnMouseUp','LeftButton')
CharacterFrame:Hide(); assert(select(3,CharacterFrame:GetPoint(1))=='BOTTOMLEFT'); CharacterFrame:Show(); ctrl=false
combat=true; p.shifter.enabled=false; Q.Apply(); assert(CharacterFrame:IsMouseEnabled()); CharacterFrame:RunScript('OnMouseDown','LeftButton'); assert(not CharacterFrame.moving)
combat=false; e:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); assert(not CharacterFrame:IsMouseEnabled() and select(3,CharacterFrame:GetPoint(1))=='TOPLEFT')
p.raidTools.enabled=true; p.raidTools.groupOnly=false; Q.Apply(); assert(Q.raidFrame:IsShown())
for i,b in ipairs(Q.markers) do assert(b:GetAttribute('type')=='macro' and b:GetAttribute('macrotext')=='/run SetRaidTarget("target",'..i..')') end
Q.readyButton:RunScript('OnClick'); assert(not readyChecks); leader=true; Q.readyButton:RunScript('OnClick'); assert(readyChecks==1)
Q.pullButton:RunScript('OnClick'); Q.UpdatePull(); assert(Q.pullFrame.text:GetText()=='Pull in 10')
now=now+12; Q.UpdatePull(); assert(not Q.pullFrame:IsShown())
local mover=unlockByFolder.EllesmereUIQoL[1]; mover.savePos(nil,'CENTER','BOTTOMLEFT',500,0); Q.Apply(); assert(select(5,Q.frames.fps:GetPoint(1))==0)
local originalProfile=Q.addon.db.profile
EllesmereUIDB.activeProfile='Other'; Q.addon.db.profile=EllesmereUI.Lite.NewDB('EllesmereUIQoLDB',Q.defaults).profile
_EQOL_RefreshAll(); assert(not Q.GetSettings().fps and not Q.frames.fps:IsShown() and not Q.raidFrame:IsShown())
EllesmereUIDB.activeProfile='Default'; Q.addon.db.profile=originalProfile
_EQOL_RefreshAll(); assert(Q.GetSettings().fps and Q.frames.fps:IsShown())
SlashCmdList.EUI335QOL(); assert(optionsLoaded and shownModule=='EllesmereUIQoL')
assert(rotationCalls==0)
''')
lua.execute(r'''
-- Retail extras ported natively: chat reports, trainer state, delete focus, screenshot, containers,
-- reset announce, role check, map coords, right-click guard, rested, transforms, flyout, FPS key.
local p=Q.GetSettings(); local e=Q.events; local x=Q.extraEvents
chat={}; DEFAULT_CHAT_FRAME={AddMessage=function(_,text) chat[#chat+1]=text end}; chatSent={}
p.guildRepair=true; e:RunScript('OnEvent','MERCHANT_SHOW'); assert(chat[#chat]:find('Repaired all items for 15s (guild bank)',1,true),chat[#chat])
p.guildRepair=false; local wallet=GetMoney; GetMoney=function() return 100 end
e:RunScript('OnEvent','MERCHANT_SHOW'); assert(chat[#chat]:find('Not enough gold to repair',1,true)); GetMoney=wallet
e:RunScript('OnEvent','MERCHANT_SHOW'); items['0:3'].locked=true; now=now+9; local before=#chat
e:RunScript('OnUpdate',.3); assert(#chat==before+1 and chat[#chat]:find('junk item(s) could not be sold.',1,true),chat[#chat])
e:RunScript('OnUpdate',.3); assert(#chat==before+1,'Junk report repeated'); e:RunScript('OnEvent','MERCHANT_CLOSED'); items['0:3'].locked=false
p.autoRepair=false; p.autoSellJunk=false
function GetTrainerServiceCost(i) local s=TrainerServices[i]; return s.cost,0,s.prof and 1 or 0 end
TrainerServices={{name='X',rank='1',kind='unavailable',cost=1}}; Q.Apply(); assert(Q.trainButton:IsShown() and not Q.trainButton:IsEnabled(),'Nothing trainable must disable Train All')
TrainerServices={{name='A',rank='1',kind='available',cost=100},{name='B',rank='1',kind='available',cost=200}}; Q.Apply(); assert(Q.trainButton:IsEnabled())
Q.trainButton:RunScript('OnEnter'); assert(GameTooltip.tooltipText=='Learn 2 skills for 3s',GameTooltip.tooltipText)
UnitCharacterPoints=function() return 0,0 end; TrainerServices[2].prof=true; Q.trainButton:RunScript('OnEnter'); assert(GameTooltip.tooltipText=='Learn 1 skill for 1s')
UnitCharacterPoints=nil; p.trainAll=false; Q.Apply(); assert(not Q.trainButton:IsShown())
StaticPopup1:Hide(); StaticPopup1.editBox.SetFocus=function(self) self.focus=true end; StaticPopup1.which='DELETE_GOOD_ITEM'; StaticPopup1:Show()
assert(StaticPopup1.editBox.focus and StaticPopup1.editBox:GetText()=='DELETE'); StaticPopup1:Hide(); p.fillDelete=false
ActionStatus=CreateFrame('Frame','ActionStatus',UIParent); x:RunScript('OnEvent','SCREENSHOT_SUCCEEDED'); assert(ActionStatus:IsShown(),'Screenshot hidden while off')
p.hideScreenshot=true; Q.Apply(); x:RunScript('OnEvent','SCREENSHOT_SUCCEEDED'); assert(not ActionStatus:IsShown())
ActionStatus:Show(); Q.ExtrasStep(); assert(not ActionStatus:IsShown(),'Status shown on the next frame must be hidden'); p.hideScreenshot=false
-- Auto Open Containers: tooltip ITEM_OPENABLE, one open at a time, gated by interaction windows.
ITEM_OPENABLE='<Right Click to Open>'
EUI335QoLOpenScanTextLeft1={GetText=function(self) return self.text end}
EUI335QoLOpenScan={SetOwner=function() end,ClearLines=function(self) self.n=0 end,NumLines=function(self) return self.n end,
    SetBagItem=function(self,bag,slot) local i=items[bag..':'..slot]; self.n=i and 1 or 0; EUI335QoLOpenScanTextLeft1.text=i and (i.open and ITEM_OPENABLE or 'Junk') end}
bagSlots={[0]=3}; items={['0:1']={link='item:100',quality=1,price=0},['0:2']={link='item:200',open=true,price=0},['0:3']={link='item:300',open=true,price=0}}
sales={}; x:RunScript('OnEvent','MERCHANT_CLOSED'); now=now+1
p.autoOpen=true; Q.Apply(); assert(x.events.BAG_UPDATE and Q.extraDriver:IsShown())
Q.ExtrasStep(); assert(#sales==1 and sales[1][2]==2); Q.ExtrasStep(); assert(#sales==1,'Opened twice before the verdict')
items['0:2']=nil; now=now+.7; Q.ExtrasStep(); now=now+.4; Q.ExtrasStep(); assert(#sales==2 and sales[2][2]==3)
now=now+.7; Q.ExtrasStep(); now=now+.4; Q.ExtrasStep(); assert(#sales==2 and not Q.extraDriver:IsShown(),'Unopenable container retried')
items['0:1']={link='item:400',open=true,price=0}
x:RunScript('OnEvent','MERCHANT_SHOW'); x:RunScript('OnEvent','BAG_UPDATE'); now=now+1; Q.ExtrasStep(); assert(#sales==2,'Opened with a merchant open')
x:RunScript('OnEvent','MERCHANT_CLOSED'); Q.ExtrasStep(); assert(#sales==2,'Opened before the settle delay')
combat=true; now=now+1; Q.ExtrasStep(); assert(#sales==2); combat=false; Q.ExtrasStep(); assert(#sales==3 and sales[3][2]==1)
p.autoOpen=false; Q.Apply(); assert(not x.events.BAG_UPDATE)
-- Instance reset announce.
INSTANCE_RESET_SUCCESS='%s has been reset.'; INSTANCE_RESET_FAILED='Cannot reset %s.  There are players still inside the instance.'
x:RunScript('OnEvent','CHAT_MSG_SYSTEM','Utgarde Keep has been reset.'); assert(#chatSent==0)
p.resetAnnounce=true; Q.Apply(); assert(x.events.CHAT_MSG_SYSTEM)
x:RunScript('OnEvent','CHAT_MSG_SYSTEM','Utgarde Keep has been reset.'); assert(chatSent[1][1]=='[EUI] Instance has been reset - you can re-enter now!' and chatSent[1][2]=='PARTY')
x:RunScript('OnEvent','CHAT_MSG_SYSTEM','Utgarde Keep has been reset.'); assert(#chatSent==1,'Reset announce not debounced')
now=now+3; p.resetMessage='Go again'; x:RunScript('OnEvent','CHAT_MSG_SYSTEM','Nexus has been reset.'); assert(chatSent[2][1]=='[EUI] Go again')
now=now+3; x:RunScript('OnEvent','CHAT_MSG_SYSTEM','Cannot reset Nexus.  There are players still inside the instance.'); assert(chatSent[3][1]:find('Reset failed',1,true))
now=now+3; x:RunScript('OnEvent','CHAT_MSG_SYSTEM','You are now AFK.'); assert(#chatSent==3)
p.resetAnnounce=false; Q.Apply(); assert(not x.events.CHAT_MSG_SYSTEM)
-- Role check auto-accept (Shift reviews manually).
LFDRoleCheckPopup=CreateFrame('Frame','LFDRoleCheckPopup',UIParent); LFDRoleCheckPopupAcceptButton=CreateFrame('Button','LFDRoleCheckPopupAcceptButton',LFDRoleCheckPopup)
LFDRoleCheckPopupAcceptButton:Enable(); roleClicks=0; LFDRoleCheckPopupAcceptButton.Click=function() roleClicks=roleClicks+1 end
p.roleCheck=true; Q.Apply(); shift=true; x:RunScript('OnEvent','LFG_ROLE_CHECK_SHOW'); now=now+.2; Q.ExtrasStep(); assert(roleClicks==0); shift=false
x:RunScript('OnEvent','LFG_ROLE_CHECK_SHOW'); Q.ExtrasStep(); assert(roleClicks==0,'Role check accepted before its delay'); now=now+.2; Q.ExtrasStep(); assert(roleClicks==1)
LFDRoleCheckPopupAcceptButton:Disable(); x:RunScript('OnEvent','LFG_ROLE_CHECK_SHOW'); now=now+.2; Q.ExtrasStep(); assert(roleClicks==1,'Disabled accept clicked'); p.roleCheck=false
-- World map coordinates.
WorldMapDetailFrame=CreateFrame('Frame','WorldMapDetailFrame',WorldMapFrame); WorldMapDetailFrame.GetLeft=function() return 100 end; WorldMapDetailFrame.GetTop=function() return 600 end
WorldMapDetailFrame:SetWidth(400); WorldMapDetailFrame:SetHeight(300)
p.mapCoords=true; Q.Apply(); local mc=Q.mapCoordFrame; assert(mc and mc:GetParent()==WorldMapDetailFrame and mc:IsShown())
mc:RunScript('OnUpdate',.1); assert(mc.cursor:GetText()=='C: 25, 100' and mc.player:GetText()=='P: 25, 75',mc.cursor:GetText())
cursorX=50; mc:RunScript('OnUpdate',.1); assert(mc.cursor:GetText()=='C: 0, 0'); cursorX=200
p.mapCoords=false; Q.Apply(); assert(not mc:IsShown())
-- Right-click guard: secure state driver binds BUTTON2 to camera turning over enemies.
p.rightClickEnemy=true; Q.Apply(); local rc=Q.rcState
assert(rc.drivers.rclick=='[target=mouseover,harm,nodead]1;0' and SecureStateDriverManager.events.UPDATE_MOUSEOVER_UNIT)
assert(rc:GetAttribute('_onstate-rclick'):find('SetBindingClick(true, "BUTTON2", "EUI335QoLMouseLook")',1,true))
mouseDown=true; EUI335QoLMouseLook:RunScript('OnClick','LeftButton',true); assert(mouselook and Q.rcGuard:IsShown())
Q.rcGuard:RunScript('OnUpdate',.01); assert(mouselook); mouseDown=false; Q.rcGuard:RunScript('OnUpdate',.01); assert(not mouselook and not Q.rcGuard:IsShown())
p.rightClickAlly=true; Q.Apply(); assert(rc.drivers.rclick=='[target=mouseover,harm,nodead]1;[target=mouseover,help,nodead,combat]1;0')
combat=true; p.rightClickEnemy=false; Q.Apply(); assert(rc.drivers.rclick:find('harm'),'Secure driver changed in combat'); combat=false
p.rightClickAlly=false; Q.Apply(); assert(not rc.drivers.rclick and rc:GetAttribute('state-rclick')=='0')
-- Rested indicator on the EUI player frame (account-wide keys).
EllesmereUIUnitFrames_Player={Health=CreateFrame('Frame'),_restIndicator=CreateFrame('Frame')}; local rest=EllesmereUIUnitFrames_Player._restIndicator
IsResting=function() return true end; EllesmereUIDB.showRestedIndicator=true; EllesmereUIDB.restedIndicatorXOffset=5
Q.ApplyRested(); assert(rest:IsShown() and select(4,rest:GetPoint(1))==8)
EllesmereUIDB.showRestedIndicator=false; Q.ApplyRested(); assert(not rest:IsShown()); IsResting=function() return false end
-- Hide Item Transforms: only Wrath transform auras, never in combat.
playerAuras={{name='Turkey',id=61781},{name='Mark',id=1126}}; p.hideTransforms=true
combat=true; Q.CancelTransforms(); assert(#cancelled==0); combat=false
Q.Apply(); assert(#cancelled==1 and cancelled[1][2]==1 and cancelled[1][3]=='HELPFUL' and x.events.UNIT_AURA)
playerAuras={}; p.hideTransforms=false; Q.Apply(); assert(not x.events.UNIT_AURA)
-- Equipment flyout item levels.
items={['0:3']={link='item:777',quality=4,price=0}}
function GetItemInfo(link) if link=='item:777' then return 'Sword',link,4,200 end end
ITEM_QUALITY_COLORS={[4]={r=.64,g=.21,b=.93}}
EquipmentManager_UnpackLocation=function() return false,false,true,3,0 end
local fb=CreateFrame('Button',nil,UIParent); fb.location=12345; EquipmentFlyoutFrame={buttons={fb}}
Q.RefreshFlyout(); assert(#fb.children==0,'Flyout level shown while off')
p.flyoutIlvl=true; Q.Apply(); local lvl=fb.children[#fb.children]; assert(lvl and lvl:GetText()==200 and lvl.textColor[1]==.64)
p.flyoutIlvl=false; Q.RefreshFlyout(); assert(lvl:GetText()=='')
-- FPS toggle keybind through an override binding click.
p.fpsKey='ctrl-f'; Q.Apply(); assert(#overrideBindings==1 and overrideBindings[1][2]=='CTRL-F' and overrideBindings[1][3]=='EUI335QoLFPSToggle')
local wasFps=p.fps; EUI335QoLFPSToggle:RunScript('OnClick'); assert(p.fps==not wasFps); EUI335QoLFPSToggle:RunScript('OnClick'); assert(p.fps==wasFps)
p.fpsKey='ctrl+f'; Q.Apply(); assert(#overrideBindings==0,'Invalid key bound'); p.fpsKey=''; Q.Apply(); assert(#overrideBindings==0)
''')
lua.execute(r'''
-- Retail display looks: FPS parts, extra stats, durability, alerts, crosshair, range, trackers, cursor, raid scale.
local p=Q.GetSettings(); local e=Q.events; local f=Q.frames
p.fps=true; p.fpsWorld=true; p.fpsLabels=true; Q.Apply()
assert(f.fps.world:GetText()=='80 ms' and f.fps.worldLabel:GetText()=='(world)' and f.fps.localMs:GetText()=='45 ms' and f.fps.world:IsShown())
p.fpsLabels=false; Q.Apply(); assert(not f.fps.worldLabel:IsShown() and not f.fps.localLabel:IsShown())
p.fpsColorMode='class'; Q.Apply(); assert(f.fps.text.textColor[1]==1 and f.fps.text.textColor[2]==.49)
p.fpsColorMode='custom'; p.fpsColor={r=0,g=1,b=0}; Q.Apply(); assert(f.fps.text.textColor[1]==0 and f.fps.text.textColor[2]==1)
-- Quality (default): FPS and each latency value in green/yellow/red bands; labels follow their value.
assert(Q.defaults.profile.fpsColorMode=='quality')
local frate,net=GetFramerate,GetNetStats
local function green(c) return c[2]>c[1] and c[2]>c[3] end
local function yellow(c) return c[1]>.5 and c[2]>.5 and c[3]<.5 end
local function red(c) return c[1]>c[2] and c[1]>c[3] end
p.fpsColorMode='quality'; p.fpsLabels=true; p.fpsColor={r=0,g=0,b=1}
GetFramerate=function() return 144 end; GetNetStats=function() return 1,1,45,80 end; Q.Apply()
assert(green(f.fps.text.textColor) and green(f.fps.localMs.textColor) and green(f.fps.world.textColor))
assert(f.fps.localLabel.textColor[2]==f.fps.localMs.textColor[2] and f.fps.localLabel.textColor[4]==.6)
GetFramerate=function() return 40 end; GetNetStats=function() return 1,1,180,400 end; Q.Apply()
assert(yellow(f.fps.text.textColor) and yellow(f.fps.localMs.textColor) and red(f.fps.world.textColor))
GetFramerate=function() return 20 end; Q.Apply(); assert(red(f.fps.text.textColor))
GetFramerate,GetNetStats=frate,net; p.fpsColorMode='custom'; p.fpsColor={r=0,g=1,b=0}; Q.Apply()
p.statsExtra=true; Q.Apply(); local stats=f.stats.text:GetText()
assert(stats:find('|cffff7d0aHit|r  0.0%',1,true) and stats:find('Expertise|r  0',1,true) and stats:find('Armor Pen|r',1,true),stats); p.statsExtra=false
durability=30; p.durabilityColor={r=1,g=1,b=0}; Q.Apply(); assert(f.durability.text:GetText()=='Low Durability (30%)' and f.durability.text.textColor[3]==0 and f.durability:IsShown())
combat=true; Q.UpdateDisplays(); assert(not f.durability:IsShown(),'Durability warning shown in combat'); combat=false; Q.UpdateDisplays(); assert(f.durability:IsShown())
now=now+10; Q.UpdateDisplays()
p.combatEnterText='GO'; p.combatEnterColor={r=0,g=1,b=0}; e:RunScript('OnEvent','PLAYER_REGEN_DISABLED'); Q.UpdateDisplays()
assert(f.combatAlert:IsShown() and f.combatAlert.text:GetText()=='GO' and f.combatAlert.text.textColor[2]==1 and f.combatAlert.text.textColor[1]==0)
now=now+1; Q.UpdateDisplays(); assert(f.combatAlert:IsShown()); now=now+1; Q.UpdateDisplays(); assert(not f.combatAlert:IsShown(),'Combat alert outlived 1.85s')
p.combatAlertMode='enter'; e:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); Q.UpdateDisplays(); assert(not f.combatAlert:IsShown(),'Leave alert in enter-only mode')
p.combatAlertMode='both'; p.combatLeaveText='Safe'; p.combatClassColor=true; e:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); Q.UpdateDisplays()
assert(f.combatAlert.text:GetText()=='Safe' and f.combatAlert.text.textColor[2]==.49); now=now+3; Q.UpdateDisplays()
Q.Sounds(); Q.soundPaths.ding='Sound\\ding.ogg'; p.deathSound='ding'; groupDead=false; Q.UpdateDisplays(); groupDead=true; Q.UpdateDisplays(); Q.UpdateDisplays()
assert(sounds[#sounds][1]=='Sound\\ding.ogg' and f.deathAlert:IsShown()); groupDead=false; now=now+4; Q.UpdateDisplays()
p.crosshairVisibility='combat'; Q.UpdateDisplays(); assert(not f.crosshair:IsShown()); combat=true; Q.UpdateDisplays(); assert(f.crosshair:IsShown())
combat=false; p.crosshairVisibility='instances'; inside=false; Q.UpdateDisplays(); assert(not f.crosshair:IsShown()); inside=true; Q.UpdateDisplays(); assert(f.crosshair:IsShown())
inside=false; p.crosshairVisibility='always'; p.crosshairSize=60; p.crosshairThickness=3; p.crosshairBorder=1; Q.Apply()
assert(f.crosshair.horizontal:GetWidth()==60 and f.crosshair.horizontal:GetHeight()==3 and f.crosshair.hBorder:IsShown() and f.crosshair.hBorder:GetWidth()==62)
local yards={[37727]=5,[34368]=8,[32321]=10,[33069]=15,[10645]=20,[24268]=25,[835]=30,[24269]=35,[28767]=40,[23836]=45,[32825]=60,[35278]=80}
targetYards=33; function IsItemInRange(item) local r=yards[item]; if r then return r>=targetYards and 1 or 0 end end
function CheckInteractDistance(_,index) return ({[3]=10,[2]=11,[4]=28})[index]>=targetYards end
UnitCanAttack=function() return true end
local lo,hi=Q.TargetRange('target'); assert(lo==30 and hi==35,tostring(lo)..'-'..tostring(hi))
assert(Q.FormatRange(lo,hi,'range')=='30-35' and Q.FormatRange(lo,hi,'plus')=='30+' and Q.FormatRange(lo,hi,'min')=='30')
p.crosshairRange=true; Q.UpdateDisplays(); assert(f.crosshair.horizontal.vertexColor[1]==1 and f.crosshair.horizontal.vertexColor[2]==0,'Out-of-range color')
targetYards=18; Q.UpdateDisplays(); assert(f.crosshair.horizontal.vertexColor[2]==1 and f.crosshair.horizontal.vertexColor[4]==.75,'In-range color')
p.targetDistance=true; Q.UpdateDisplays(); assert(f.targetDistance:IsShown() and f.targetDistance.text:GetText()=='15-20')
p.targetDistanceFormat='plus'; Q.UpdateDisplays(); assert(f.targetDistance.text:GetText()=='15+')
UnitCanAttack=function() return false end; IsItemInRange=nil; CheckInteractDistance=nil; p.crosshairRange=false; p.targetDistance=false; p.crosshair=false
p.trackerIconSize=40; Q.Apply(); assert(f.movement.icon:GetWidth()==40 and f.bloodlust.icon:GetWidth()==40)
p.movementSpellID=0; p.showReady=true; p.movementCombatOnly=true; Q.UpdateDisplays(); assert(not f.movement:IsShown(),'Combat-only movement shown out of combat')
combat=true; Q.UpdateDisplays(); assert(f.movement:IsShown() and f.movement.text:GetText()=='Ready'); combat=false; p.movementCombatOnly=false
Q.soundPaths.ready='Sound\\ready.ogg'; p.movementSound='ready'; spellCooldowns['Spell 1850']={now,30,1}; Q.UpdateDisplays(); local n=#sounds
spellCooldowns['Spell 1850']={0,0,1}; Q.UpdateDisplays(); assert(#sounds==n+1 and sounds[#sounds][1]=='Sound\\ready.ogg','Movement ready sound')
p.cursor.enabled=true; p.cursor.combatOnly=false; p.cursor.classColor=false; p.cursor.color={r=1,g=0,b=0}; p.cursor.opacity=50; p.cursor.reticle=true; Q.Apply()
assert(Q.cursor.frame:IsShown() and Q.cursor.ring.vertexColor[1]==1 and Q.cursor.ring.vertexColor[2]==0 and Q.cursor.ring.vertexColor[4]==.5 and Q.cursor.reticle:IsShown())
p.cursor.instancesOnly=true; Q.UpdateCursor(.01); assert(not Q.cursor.frame:IsShown()); inside=true; Q.UpdateCursor(.01); assert(Q.cursor.frame:IsShown()); inside=false
p.cursor.enabled=false; p.cursor.instancesOnly=false
p.raidTools.scale=150; Q.Apply(); assert(Q.raidFrame.scale==1.5); p.raidTools.scale=100; p.raidTools.enabled=false; Q.Apply()
for _,key in ipairs({'fps','stats','coordinates','durability','combatAlert','deathAlert','bloodlust','battleRes','movement'}) do p[key]=false end; Q.Apply()
''')
lua.execute('''
-- Mail: Open All walks the inbox from the end, one native take per inbox change.
local m=getmetatable(UIParent).__index
function m:Enable() self.enabled=true end
function m:Disable() self.enabled=false end
function IsAltKeyDown() return false end
chat={}; DEFAULT_CHAT_FRAME={AddMessage=function(_,text) chat[#chat+1]=text end}
ITEM_SOULBOUND,ITEM_BIND_ON_EQUIP,ITEM_BIND_QUEST,ITEM_BIND_ON_USE,ITEM_BIND_TO_ACCOUNT='Soulbound','Binds when equipped','Quest Item','Binds when used','Binds to account'
ERR_INV_FULL,ERR_ITEM_MAX_COUNT='Inventory is full.','You cannot carry any more of those items.'
nativeModified=0
local tableHook=hooksecurefunc
function hooksecurefunc(target,key,fn)
    if type(target)~='string' then return tableHook(target,key,fn) end
    local original=_G[target]; _G[target]=function(...) original(...); key(...) end
end
StackSplitFrame=CreateFrame('Frame','StackSplitFrame',UIParent); StackSplitFrame:Hide()
local nativeModifiedClick=function(self) nativeModified=nativeModified+1; StackSplitFrame.owner=self; StackSplitFrame:Show() end
ContainerFrameItemButton_OnModifiedClick=nativeModifiedClick
InboxFrame=CreateFrame('Frame','InboxFrame',UIParent); SendMailFrame=CreateFrame('Frame','SendMailFrame',UIParent); SendMailFrame:Hide()
mail={}; takes={}; invFull=false; stuck=false
local function Cleanup(i) local mm=mail[i]; if mm.money==0 and not next(mm.items) and not mm.text then table.remove(mail,i) end end
function GetInboxNumItems() return #mail,#mail end
function GetInboxHeaderInfo(i) local mm=mail[i]; local n=0; for _ in pairs(mm.items) do n=n+1 end; return nil,nil,'Sender','Subject',mm.money,mm.cod or 0,30,n,false,false,false,true,mm.gm end
function GetInboxItemLink(i,a) return mail[i] and mail[i].items[a] end
function TakeInboxItem(i,a) takes[#takes+1]='item'..i..':'..a; if not invFull and not stuck then mail[i].items[a]=nil; Cleanup(i) end end
function TakeInboxMoney(i) takes[#takes+1]='money'..i; mail[i].money=0; Cleanup(i) end
local function Pump(n) for _=1,n or 40 do now=now+.2; Q.MailStep() end end
local p=Q.GetSettings(); assert(p.mailOpenAll and p.mailBulkAttach,'Mail helpers should default on')
Q.Apply(); local b=Q.mailButton
assert(b and b:IsShown() and b:GetText()=='Open All' and not b.enabled,'Empty inbox should disable Open All')
mail={{money=500,items={[1]='a',[3]='b'}},{money=0,cod=100,items={[1]='cod'}},{money=10,gm=true,items={}},{money=0,text=true,items={}},{money=0,items={[2]='c'}}}
Q.mailEvents:RunScript('OnEvent','MAIL_INBOX_UPDATE'); assert(b.enabled)
b:RunScript('OnClick'); assert(b:GetText()=='Opening...' and Q.mailDriver:IsShown())
assert(#takes==1 and takes[1]=='item5:2'); Q.MailStep(); assert(#takes==1,'Took again before the minimum delay')
Pump(); assert(table.concat(takes,',')=='item5:2,item1:3,item1:1,money1',table.concat(takes,','))
assert(#mail==3 and mail[1].cod==100 and mail[2].gm and mail[3].text,'COD/GM/text mail must stay')
assert(not Q.mailDriver:IsShown() and b:GetText()=='Open All')
takes={}; mail={{money=50,items={[1]='x'}}}; invFull=true; b:RunScript('OnClick'); assert(takes[1]=='item1:1')
Q.mailEvents:RunScript('OnEvent','UI_ERROR_MESSAGE',ERR_INV_FULL); Pump()
assert(table.concat(takes,',')=='item1:1,money1' and chat[#chat]:find('bags are full'),'Full bags must still collect gold')
invFull=false; takes={}; stuck=true; mail={{money=0,items={[1]='y'}}}; b:RunScript('OnClick'); Pump(30)
assert(#takes==1 and not Q.mailDriver:IsShown(),'Unanswered take retried'); stuck=false
mail={{money=5,items={}}}; b:RunScript('OnClick'); Q.mailEvents:RunScript('OnEvent','MAIL_CLOSED'); assert(not Q.mailDriver:IsShown() and b:GetText()=='Open All')
PostalOpenAllButton=CreateFrame('Button','PostalOpenAllButton',InboxFrame); Q.Apply(); assert(not b:IsShown(),'Postal Open All already present')
PostalOpenAllButton:Hide(); Q.Apply(); assert(b:IsShown()); PostalOpenAllButton=nil
p.mailOpenAll=false; Q.Apply(); assert(not b:IsShown()); p.mailOpenAll=true; Q.Apply(); assert(b:IsShown())
-- Shift-click attaches the clicked item and same-category bag items into free send slots.
bagSlots={[0]=7,[1]=2}
items={['0:1']={link='ore1',class='Trade Goods',sub='Metal & Stone',q=1},['0:2']={link='herb',class='Trade Goods',sub='Herb',q=1},
    ['0:3']={link='ore2',class='Trade Goods',sub='Metal & Stone',q=1},['0:4']={link='boe2',class='Armor',sub='Mail',q=2,bind='Binds when equipped'},
    ['0:5']={link='boeSword',class='Weapon',sub='Swords',q=2,bind='Binds when equipped'},['0:6']={link='bound',class='Armor',sub='Mail',q=2,bind='Soulbound'},
    ['0:7']={link='cloth',class='Trade Goods',sub='Cloth',q=1},['1:1']={link='ore3',class='Trade Goods',sub='Metal & Stone',q=1},
    ['1:2']={link='boe3',class='Armor',sub='Plate',q=3,bind='Binds when equipped'}}
function GetContainerNumSlots(bag) return bagSlots[bag] or 0 end
function GetContainerItemLink(bag,slot) local i=items[bag..':'..slot]; return i and i.link end
function GetContainerItemInfo(bag,slot) local i=items[bag..':'..slot]; if i then return 'icon',1,i.locked end end
function GetItemInfo(link) for _,i in pairs(items) do if i.link==link then return link,link,i.q,1,1,i.class,i.sub,20,'' end end end
function GetAuctionItemClasses() return 'Weapon','Armor','Container' end
held=nil; sendSlots={}; cleared=0
function PickupContainerItem(bag,slot) held=bag..':'..slot end
function CursorHasItem() return held~=nil end
function ClearCursor() held=nil; cleared=cleared+1 end
function ClickSendMailItemButton(index) local i=held and items[held]; if i and not i.unmailable then assert(not sendSlots[index]); sendSlots[index]=i.link; i.locked=true; held=nil end end
function GetSendMailItem(i) return sendSlots[i] end
EUI335QoLMailScanTextLeft2={GetText=function(self) return self.text end}
EUI335QoLMailScan={SetOwner=function() end,ClearLines=function(self) self.n=0 end,NumLines=function(self) return self.n end,
    SetBagItem=function(self,bag,slot) local i=items[bag..':'..slot]; self.n=(i and i.bind) and 2 or 1; EUI335QoLMailScanTextLeft2.text=i and i.bind end}
local function Btn(bag,slot) return {GetParent=function() return {GetID=function() return bag end} end,GetID=function() return slot end} end
local click=ContainerFrameItemButton_OnModifiedClick
assert(click~=nativeModifiedClick,'Bulk attach must post-hook the native click')
shift=true; click(Btn(0,1),'LeftButton'); assert(nativeModified==1 and not next(sendSlots) and StackSplitFrame:IsShown(),'Mailbox closed: native split/link')
SendMailFrame:Show(); local ore=Btn(0,1); click(ore,'LeftButton')
assert(nativeModified==2 and sendSlots[1]=='ore1' and sendSlots[2]=='ore2' and sendSlots[3]=='ore3' and not sendSlots[4],'Ore category')
assert(not StackSplitFrame:IsShown(),'Attached click closes the native split-stack box')
click(Btn(0,4),'LeftButton'); assert(sendSlots[4]=='boe2' and sendSlots[5]=='boeSword' and not sendSlots[6],'BoE gear of the same quality only')
click(Btn(0,6),'LeftButton'); assert(nativeModified==4 and not sendSlots[6] and StackSplitFrame:IsShown(),'Soulbound keeps the native split box')
ChatEdit_GetActiveWindow=function() return {} end; click(Btn(0,2),'LeftButton'); assert(nativeModified==5 and not sendSlots[6],'Open chat keeps link insert'); ChatEdit_GetActiveWindow=nil
click(Btn(0,2),'RightButton'); assert(nativeModified==6 and not sendSlots[6])
shift=false; click(Btn(0,2),'LeftButton'); assert(nativeModified==7 and not sendSlots[6]); shift=true
p.mailBulkAttach=false; click(Btn(0,2),'LeftButton'); assert(nativeModified==8 and not sendSlots[6]); p.mailBulkAttach=true
items['0:7'].unmailable=true; click(Btn(0,7),'LeftButton'); assert(nativeModified==9 and cleared==1 and not held and not sendSlots[6],'Rejected attach must not keep the item on the cursor')
for i=6,12 do sendSlots[i]='filler' end; click(Btn(0,2),'LeftButton'); assert(nativeModified==10 and not items['0:2'].locked,'No free slot: nothing picked up')
for i=6,12 do sendSlots[i]=nil end; click(Btn(0,2),'LeftButton'); assert(sendSlots[6]=='herb')
sendSlots={}; for k,i in pairs(items) do i.locked=nil; i.unmailable=nil end
for n=2,11 do items['1:'..n]=nil end; bagSlots[1]=12; for n=3,12 do items['1:'..n]={link='ore'..(n+1),class='Trade Goods',sub='Metal & Stone',q=1} end
click(Btn(0,1),'LeftButton'); local count=0; for i=1,12 do if sendSlots[i] then count=count+1 end end
assert(count==12 and not items['1:12'].locked,'Attach stops at the 12 send slots')
shift=false; SendMailFrame:Hide()
-- Send Mail recipient list: alts (realm + faction), guild roster and recent successful sends.
local m=getmetatable(UIParent).__index
for _,k in ipairs({'SetBackdrop','SetBackdropColor','SetBackdropBorderColor','EnableMouseWheel','SetNormalTexture','SetPushedTexture','SetHighlightTexture'}) do if not m[k] then m[k]=function() end end end
if not m.SetFocus then m.SetFocus=function(self) self.focus=true end end
local createFont=m.CreateFontString
m.CreateFontString=function(self,name,layer,template) local fs=createFont(self,name,layer,template); if template then fs:SetFont('Fonts\\\\FRIZQT__.TTF',10,'') end; return fs end
function SendMail(name) end
SendMailNameEditBox=CreateFrame('EditBox','SendMailNameEditBox',SendMailFrame); SendMailSubjectEditBox=CreateFrame('EditBox','SendMailSubjectEditBox',SendMailFrame)
SendMailNameEditBox:SetFont('Fonts\\\\FRIZQT__.TTF',12,'')
roster={{'Zed',80,true,'MAGE'},{'player',80,true,'WARRIOR'},{'Abe',70,false,'PRIEST'},{'Bob',75,true,'ROGUE'}}
function IsInGuild() return true end
function GetNumGuildMembers() return #roster end
function GetGuildRosterInfo(i) local r=roster[i]; return r[1],'Rank',1,r[2],'Class','Zone','','',r[3] and 1 or nil,0,r[4] end
rosterRequests=0; function GuildRoster() rosterRequests=rosterRequests+1 end
EllesmereUIDB.mailRecipients={alts={['Test Realm']={Alt={class='PALADIN',level=80,faction='Alliance'},Enemy={class='MAGE',level=80,faction='Horde'}}}}
Q.Apply()
local db=EllesmereUIDB.mailRecipients
assert(db.alts['Test Realm'].player and db.alts['Test Realm'].player.faction=='Alliance' and db.alts['Test Realm'].player.level==80,'Current character recorded as an alt')
local alts=Q.MailRecipients('alts'); assert(#alts==1 and alts[1].name=='Alt','Alts: same faction, not yourself')
local guild=Q.MailRecipients('guild')
assert(#guild==3 and guild[1].name=='Bob' and guild[2].name=='Zed' and guild[3].name=='Abe','Guild: online first, then by name, without yourself')
local rb=Q.mailRecipientsButton; assert(rb and rb:IsShown())
Q.ToggleMailRecipients(); local f=Q.mailPicker; assert(f:IsShown() and f.rows[1].name=='Alt' and not f.rows[2]:IsShown())
f.tabs[2]:GetScript('OnClick')(); assert(rosterRequests==1 and f.rows[1].name=='Bob')
f.rows[2]:GetScript('OnClick')(f.rows[2]); assert(SendMailNameEditBox:GetText()=='Zed' and SendMailSubjectEditBox.focus and not f:IsShown())
local ev=Q.mailRecipientEvents
SendMail('  Carol ','Hi',''); ev:GetScript('OnEvent')(ev,'MAIL_SEND_SUCCESS')
SendMail('Dave','x',''); ev:GetScript('OnEvent')(ev,'MAIL_FAILED')
SendMail('carol','x',''); ev:GetScript('OnEvent')(ev,'MAIL_SEND_SUCCESS')
local recent=Q.MailRecipients('recent'); assert(#recent==1 and recent[1].name=='carol','Recent: successful sends only, newest first, no duplicates')
for i=1,20 do Q.MailRemember('N'..i) end; assert(#db.recent['Test Realm']==15 and db.recent['Test Realm'][1]=='N20','Recent keeps 15')
p.mailRecipients=false; Q.Apply(); assert(not rb:IsShown()); p.mailRecipients=true; Q.Apply(); assert(rb:IsShown())
-- Merchant mouse wheel turns pages through the native Prev/Next buttons.
MerchantFrame=CreateFrame('Frame','MerchantFrame',UIParent)
local turns={}
for _,name in ipairs({'MerchantPrevPageButton','MerchantNextPageButton'}) do
    local b=CreateFrame('Button',name,MerchantFrame); b:Enable(); b.Click=function() turns[#turns+1]=name end
end
Q.Apply(); Q.Apply(); local wheel=MerchantFrame.hooks.OnMouseWheel; assert(wheel,'Merchant wheel hook installed')
wheel(MerchantFrame,-1); wheel(MerchantFrame,1)
assert(turns[1]=='MerchantNextPageButton' and turns[2]=='MerchantPrevPageButton' and #turns==2,'Wheel down = next, up = previous')
MerchantPrevPageButton:Disable(); wheel(MerchantFrame,1); assert(#turns==2,'First page: no previous')
MerchantNextPageButton:Hide(); wheel(MerchantFrame,-1); assert(#turns==2,'Buyback tab hides the page buttons')
MerchantNextPageButton:Show(); p.merchantWheel=false; wheel(MerchantFrame,-1); assert(#turns==2,'Option off'); p.merchantWheel=true
''')
lua.execute((root/'EllesmereUIOptions/EUI_QoL_335_Options.lua').read_text(encoding='utf-8-sig'))
lua.execute("allFrames[#allFrames]:RunScript('OnEvent','PLAYER_LOGIN')")
lua.execute('''
local module=modules.EllesmereUIQoL; assert(module and #module.pages==6 and module.pages[2]=='Displays')
local W=EllesmereUI.Widgets; local header=W.SectionHeader; local sections
W.SectionHeader=function(self,parent,label,y) sections[label]=true; return header(self,parent,label,y) end
local built={}
for _,page in ipairs(module.pages) do
    rows={}; sections={}; assert(module.buildPage(page,UIParent,0)>0)
    for _,row in ipairs(rows) do if row.getValue then row.getValue() end end
    built[page]={rows=rows,sections=sections}
end
W.SectionHeader=header
-- Every QoL mover must open an Element Options section with a matching row.
local map=EllesmereUI._ELEMENT_SETTINGS_MAP; local mapped=0
for _,el in ipairs(unlockByFolder.EllesmereUIQoL) do
    local entry=map[el.key]; assert(entry and entry.module=='EllesmereUIQoL','No element options for '..el.key)
    local page=built[entry.page]; assert(page and page.sections[entry.sectionName],el.key..' section '..tostring(entry.sectionName))
    local found=false; for _,row in ipairs(page.rows) do if row.text==entry.highlightText then found=true end end
    assert(found,el.key..' row '..tostring(entry.highlightText)); mapped=mapped+1
end
assert(mapped==12 and map.EUI_TargetDistance.page=='Displays' and map.EUI_FPS.page=='Displays' and map.EUI_ZoneText==nil)
rows={}; module.buildPage('QoL',UIParent,0); FindRow('Auto Repair').setValue(false); assert(not Q.GetSettings().autoRepair)
-- Retail layout: Quick Loot | Auto-Fill Delete, then Auto Repair (guild funds in its cog) | Auto Sell Junk.
assert(rows[3].text=='Quick Loot' and rows[4].text=='Auto-Fill Delete Confirmation' and rows[5].text=='Auto Repair' and rows[6].text=='Auto Sell Junk')
assert(FindRow('Quick Loot').tooltip:find('Shift',1,true) and not pcall(FindRow,'Use Guild Repair First'))
local cog; local dual=W.DualRow; W.DualRow=function(self,parent,y,a,b) local r,h=dual(self,parent,y,a,b); r._leftRegion=r._leftRegion or {}; return r,h end
local build=EllesmereUI.BuildInlineCog; EllesmereUI.BuildInlineCog=function(region,spec) if spec.title=='Auto Repair Settings' then cog=spec end end
rows={}; module.buildPage('QoL',UIParent,0); W.DualRow=dual; EllesmereUI.BuildInlineCog=build
assert(cog and cog.rows[1].label=='Use Guild Bank Funds' and cog.disabled(),'Guild repair cog missing or enabled with Auto Repair off')
cog.rows[1].set(true); assert(Q.GetSettings().guildRepair==true and cog.rows[1].get()); cog.rows[1].set(false)
FindRow('Auto Open Containers').setValue(true); assert(Q.GetSettings().autoOpen); FindRow('Auto Open Containers').setValue(false)
FindRow('Reset Message').setValue('Reset!'); assert(Q.GetSettings().resetMessage=='Reset!')
FindRow('Rested Indicator').setValue(true); assert(EllesmereUIDB.showRestedIndicator==true and FindRow('Rested Indicator').getValue())
FindRow('Rested Indicator X Offset').setValue(-4); assert(EllesmereUIDB.restedIndicatorXOffset==-4)
rows={}; module.buildPage('Displays',UIParent,0)
local before=Q.GetSettings().movementSpellID
FindRow('Movement Spell ID').setValue('junk'); assert(Q.GetSettings().movementSpellID==before)
FindRow('Movement Spell ID').setValue('1850'); assert(Q.GetSettings().movementSpellID==1850)
FindRow('Crosshair Color').setValue(0,1,0,.5); local cc=Q.GetSettings().crosshairColor; assert(cc.r==0 and cc.g==1 and cc.a==.5)
assert(select(4,FindRow('Crosshair Color').getValue())==.5)
FindRow('Crosshair Visibility').setValue('combat'); assert(Q.GetSettings().crosshairVisibility=='combat')
assert(FindRow('Death Alert Sound').values.none and FindRow('Distance Format').values.plus)
FindRow('Toggle Keybind').setValue('ALT-F'); assert(overrideBindings[#overrideBindings][2]=='ALT-F'); FindRow('Toggle Keybind').setValue('')
rows={}; module.buildPage('Cursor',UIParent,0); FindRow('Cursor Size').setValue(48); assert(Q.cursor.frame:GetWidth()==48)
FindRow('Circle Opacity').setValue(40); assert(Q.GetSettings().cursor.opacity==40)
FindRow('Custom Color').setValue(0,0,1); assert(Q.GetSettings().cursor.color.b==1)
rows={}; module.buildPage('Raid Tools',UIParent,0); FindRow('Window Scale %').setValue(120); assert(Q.GetSettings().raidTools.scale==120)
''')
font=(root/'EllesmereUIOptions/EUI_Fonts_Options.lua').read_text(encoding='utf-8-sig')
body='local function TileQoL'+font.split('local function TileQoL',1)[1].split('\nlocal function ',1)[0]
tile=lua.execute("local NS=EllesmereUI.ModuleNS; local function ModuleOutlineCfg() return {type='label',text='Outline'} end; local function BLANK() return {type='label',text=''} end; "+body+'\nreturn TileQoL')
lua.execute('rows={}')
tile(lua.globals().UIParent,0,lua.globals().EllesmereUI.Widgets,lua.table(folder='EllesmereUIQoL',display='Quality of Life'))
lua.execute("FindRow('FPS / Latency Text Size').setValue(18); assert(Q.GetSettings().fpsTextSize==18 and Q.frames.fps.text.font[2]==18)")
lua.execute("FindRow('Target Distance Text Size').setValue(24); assert(Q.frames.targetDistance.text.font[2]==24)")
retail=Path('D:/World of Warcraft/_retail_/Interface/AddOns/EllesmereUIQoL')
for original in retail.rglob('*'):
    if original.is_file() and original.suffix.lower()!='.toc':
        assert original.read_bytes()==(root/'EllesmereUIQoL'/original.relative_to(retail)).read_bytes(),original
toc=(root/'EllesmereUIQoL/EllesmereUIQoL.toc').read_text(encoding='utf-8-sig')
assert '## Interface: 30300' in toc and '\nEllesmereUIQoL.lua' not in toc and '## SavedVariables:' not in toc
native_textures=list((root/'EllesmereUIQoL/Media/Textures_335').glob('*.tga'))
assert len(native_textures)==6
for texture in native_textures:
    data=texture.read_bytes(); width,height,depth,flags=struct.unpack('<HHBB',data[12:18])
    assert width&(width-1)==0 and height&(height-1)==0 and depth==32 and data[2]==2 and flags==8,texture
    assert len(data)==18+width*height*4,texture
print('PASS: QoL Lua51 lifecycle, merchant safety/repair/loot/trainer/delete with chat reports, error whitelist, mail Open All/category attach, logging ownership, screenshot/auto-open/reset announce/role check/world map coords/right-click guard/rested/transforms/flyout ilvl/FPS key, Retail display looks (FPS, stats, durability, alerts, crosshair, target range, trackers, cursor), secure raid controls and scale, combat-safe window dragging, profile swaps, 12 movers with Element Options, options and global fonts; Retail references unchanged.')
