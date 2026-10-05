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
for name in ['EUI_QoL_335.lua','EUI_QoL_335_Displays.lua','EUI_QoL_335_Panels.lua']:
    lua.execute((root/'EllesmereUIQoL'/name).read_text(encoding='utf-8-sig'),'EllesmereUIQoL',ns)
lua.globals().Q=ns
core=(root/'EllesmereUI/EllesmereUI_Lite.lua').read_text(encoding='utf-8-sig')
safe=lua.execute('local function errorhandler('+core.split('local function errorhandler(',1)[1].split('\n-------------------------------------------------------------------------------',1)[0]+'\nreturn safecall')
safe(ns.addon.OnInitialize,ns.addon)
safe(ns.addon.OnEnable,ns.addon)
lua.execute('''
local p=Q.GetSettings(); local e=Q.events
assert(p and p.enabled and not p.autoRepair and not p.cursor.enabled and not p.raidTools.enabled)
assert(#unlockByFolder.EllesmereUIQoL==11 and not Q.frames.fps:IsShown())
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
autoLootToggle=true; e:RunScript('OnEvent','LOOT_OPENED'); assert(#loot==3)
cvars.autoLootDefault='0'; e:RunScript('OnEvent','LOOT_OPENED'); assert(#loot==6)
assert(not e.events.LOOT_READY)
p.fillDelete=true; Q.Apply(); StaticPopup1.which='DELETE_GOOD_ITEM'; StaticPopup1:Show(); assert(StaticPopup1.editBox:GetText()=='DELETE')
StaticPopup1:Hide(); StaticPopup1.which='OTHER'; StaticPopup1.editBox:SetText(''); StaticPopup1:Show(); assert(StaticPopup1.editBox:GetText()=='')
p.trainAll=true; Q.Apply(); ClassTrainerFrame:Show(); Q.trainButton:RunScript('OnClick'); e:RunScript('OnUpdate',.3); assert(#trained==1 and trained[1]==1)
TrainerServices[2].kind='available'; Q.trainButton:RunScript('OnClick'); e:RunScript('OnEvent','TRAINER_CLOSED'); e:RunScript('OnUpdate',.3); assert(#trained==2)
p.hideErrors=true; p.hideTutorials=true; p.skipCinematics=true; Q.Apply()
UIErrorsFrame:RunScript('OnEvent','UI_ERROR_MESSAGE','bad'); UIErrorsFrame:RunScript('OnEvent','UI_INFO_MESSAGE','info'); assert(#errorEvents==1)
assert(cvars.showTutorials=='0'); e:RunScript('OnEvent','CINEMATIC_START'); assert(cinematicSkipped)
p.hideErrors=false; p.hideTutorials=false; Q.Apply(); UIErrorsFrame:RunScript('OnEvent','UI_ERROR_MESSAGE','visible'); assert(#errorEvents==2 and cvars.showTutorials=='1')
inside=true; instanceKind='raid'; logging=true; p.logging.enabled=true; Q.Apply(); assert(#logCalls==0)
inside=false; Q.UpdateLogging(); assert(logging,'Stopped a manual log')
logging=false; inside=true; Q.UpdateLogging(); assert(logCalls[1]==true)
instanceKind='party'; Q.UpdateLogging(); assert(logCalls[2]==false)
p.logging.dungeons=true; Q.UpdateLogging(); assert(logCalls[3]==true)
p.logging.enabled=false; Q.Apply(); assert(logCalls[4]==false)
for _,key in ipairs({'fps','stats','coordinates','crosshair','durability','combatAlert','deathAlert','bloodlust','battleRes','movement'}) do p[key]=true end
Q.Apply(); assert(Q.frames.fps.text:GetText()=='144 FPS  |  80 ms')
assert(Q.frames.stats.text:GetText()=='Crit 14.0%  |  Haste 15.0%')
assert(Q.frames.coordinates.text:GetText()=='25.0, 75.0' and Q.frames.durability:IsShown())
local reads,sets=mapReads,mapSets; WorldMapFrame:Show(); Q.UpdateDisplays(); assert(mapReads==reads and mapSets==sets and not Q.frames.coordinates:IsShown())
WorldMapFrame:Hide(); Q.UpdateDisplays(); assert(mapSets==sets+1)
durability=80; Q.UpdateDisplays(); assert(not Q.frames.durability:IsShown())
assert(Q.frames.battleRes:IsShown() and Q.frames.battleRes.text:GetText()=='599s' and not Q.frames.movement:IsShown())
p.showReady=true; Q.UpdateDisplays(); assert(Q.frames.movement.text:GetText()=='Ready' and Q.frames.movement:IsShown())
p.movementSpellID=1953; Q.UpdateDisplays(); assert(not Q.frames.movement:IsShown(),'Unlearned spell rendered ready')
playerAuras={{name='Sated',id=57724,duration=600,expires=602}}; Q.UpdateDisplays(); assert(Q.frames.bloodlust:IsShown() and Q.frames.bloodlust.text:GetText()=='600s')
playerAuras={}; p.showReady=false; Q.UpdateDisplays(); assert(not Q.frames.bloodlust:IsShown())
groupDead=true; Q.UpdateDisplays(); Q.UpdateDisplays(); assert(Q.frames.deathAlert.text:GetText()=='party1 died' and Q.frames.deathAlert:IsShown())
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
lua.execute((root/'EllesmereUIOptions/EUI_QoL_335_Options.lua').read_text(encoding='utf-8-sig'))
lua.execute("allFrames[#allFrames]:RunScript('OnEvent','PLAYER_LOGIN')")
lua.execute('''
local module=modules.EllesmereUIQoL; assert(module and #module.pages==5)
for _,page in ipairs(module.pages) do rows={}; assert(module.buildPage(page,UIParent,0)>0) end
rows={}; module.buildPage('QoL',UIParent,0); FindRow('Auto Repair').setValue(false); assert(not Q.GetSettings().autoRepair)
FindRow('Movement Spell ID').setValue('junk'); assert(Q.GetSettings().movementSpellID==1953)
FindRow('Movement Spell ID').setValue('1850'); assert(Q.GetSettings().movementSpellID==1850)
rows={}; module.buildPage('Cursor',UIParent,0); FindRow('Cursor Size').setValue(48); assert(Q.cursor.frame:GetWidth()==48)
''')
font=(root/'EllesmereUIOptions/EUI_Fonts_Options.lua').read_text(encoding='utf-8-sig')
body='local function TileQoL'+font.split('local function TileQoL',1)[1].split('\nlocal function ',1)[0]
tile=lua.execute("local NS=EllesmereUI.ModuleNS; local function ModuleOutlineCfg() return {type='label',text='Outline'} end; local function BLANK() return {type='label',text=''} end; "+body+'\nreturn TileQoL')
lua.execute('rows={}')
tile(lua.globals().UIParent,0,lua.globals().EllesmereUI.Widgets,lua.table(folder='EllesmereUIQoL',display='Quality of Life'))
lua.execute("FindRow('FPS / Latency Text Size').setValue(18); assert(Q.GetSettings().fpsTextSize==18 and Q.frames.fps.text.font[2]==18)")
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
print('PASS: QoL Lua51 lifecycle, merchant safety/repair/loot/trainer/delete, logging ownership, native stats/map/durability/death/timers/cursor, secure raid controls, combat-safe window dragging, profile swaps, movers, options and global fonts; Retail references unchanged.')
