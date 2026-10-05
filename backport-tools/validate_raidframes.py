"""Real module/secure child initializer, with explicit native Wrath contracts."""
from pathlib import Path
import sys,struct,xml.etree.ElementTree as ET
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
lua=LuaRuntime(unpack_returned_tuples=True)
for file in ['backport-tools/wrath_mock.lua','backport-tools/inventory_resources_mock.lua','backport-tools/raidframes_mock.lua','EllesmereUI/EllesmereUI_Lite.lua','EllesmereUI/EUI_AuraFilters_335.lua','EllesmereUI/EUI_AuraIndicators_335.lua','EllesmereUIOptions/EUI_AuraFilters_335_Options.lua','EllesmereUIOptions/EUI_AuraIndicators_335_Options.lua']:
    lua.execute((root/file).read_text(encoding='utf-8-sig'))
ns=lua.table()
for file in ['EUI_RaidFrames_335.lua','EUI_RaidFrames_335_Display.lua','EUI_RaidFrames_335_ClickCast.lua']:
    lua.execute((root/'EllesmereUIRaidFrames'/file).read_text(encoding='utf-8-sig'),'EllesmereUIRaidFrames',ns)
lua.globals().R=ns
xml=ET.parse(root/'EllesmereUIRaidFrames/EUI_RaidFrames_335.xml'); tag='{http://www.blizzard.com/wow/ui/}'
button=xml.getroot().find(tag+'Button')
assert button.attrib['inherits']=='SecureUnitButtonTemplate,SecureHandlerEnterLeaveTemplate' and button.attrib['virtual']=='true'
assert button.find(tag+'Scripts/'+tag+'OnLoad').text.strip()=='EUI335RaidFrames_OnLoad(self)'
core=(root/'EllesmereUI/EllesmereUI_Lite.lua').read_text(encoding='utf-8-sig')
safe=lua.execute('local function errorhandler('+core.split('local function errorhandler(',1)[1].split('\n-------------------------------------------------------------------------------',1)[0]+'\nreturn safecall')
assert safe(ns.addon.OnInitialize,ns.addon) is True
lua.execute("R.GetSettings().raidLayoutMode='40'")
assert safe(ns.addon.OnEnable,ns.addon) is True
lua.execute('''
assert(#R.buttons==45 and #headers==9 and #unlockByFolder.EllesmereUIRaidFrames==2)
assert(not R.holders.raid:IsShown() and not R.holders.party:IsShown())
assert(PartyMemberFrame1:GetParent()~=UIParent and PartyMemberFrame1.events.UNIT_HEALTH and PartyMemberFrame1.nativeCallback)
local p=R.GetSettings(); local event=R.events
assert(p.party.sortMethod=='ROLE'); p.party.sortMethod='INDEX'; R.Apply()
units.party1={name='Zora',guid='A',class='PRIEST',health=8000,maxHealth=10000,power=800,maxPower=1000,role='HEALER',range=false,threat=3,marker=4,
 buffs={{name='Own Renew',id=139,caster='player',duration=15,expires=17},{name='Other Shield',id=17,caster='party2',duration=30,expires=32}},
 debuffs={{name='Curse',id=172,caster='enemy',dispel='Curse',duration=10,expires=12,stacks=2}}}
units.party2={name='Alpha',guid='B',class='WARRIOR',health=4000,maxHealth=12000,power=20,maxPower=100,powerType=1,powerToken='RAGE',role='TANK'}
partyCount=2; TickHeaders(); event:RunScript('OnEvent','PARTY_MEMBERS_CHANGED')
local h=R.headers.party[1]; local first,member,other=h.nativeButtons[1],h.nativeButtons[2],h.nativeButtons[3]
assert(first:GetAttribute('unit')=='player' and member:GetAttribute('unit')=='party1')
assert(member.Health.value==8000 and member.healthText:GetText()=='80%' and member.name:GetText()=='Zora')
assert(member.Power.value==800 and member:GetAlpha()==.4 and member.borderColor[1]==1 and member.borderColor[2]==.15)
assert(member.role:GetTexture():find('healer.tga',1,true) and member.raidMarker.marker==4)
assert(member.buffs[1]:IsShown() and member.buffs[1].spellID==139 and not member.buffs[2]:IsShown())
assert(member.debuffs[1]:IsShown() and member.debuffs[1].count:GetText()=='2' and not other.debuffs[1]:IsShown())
assert(not member.buffs[1]:IsMouseEnabled() and member:GetAttribute('*type1')=='target' and ClickCastFrames[member])
local savedFrames=#allFrames; R.SetPreview(true)
assert(not R.previewHolders.party:IsShown() and R.previewHolders.raid:IsShown() and R.holders.party:IsShown(),'Preview covered live group members')
assert(#allFrames==savedFrames); R.SetPreview(false)
member:RunScript('OnEnter'); assert(GameTooltip.tooltipUnit=='party1' and not GameTooltip.auraIndex)
cursorX,cursorY=5,5; R.UpdateTooltip(); assert(GameTooltip.auraIndex==1 and GameTooltip.auraFilter=='HELPFUL')
member:RunScript('OnLeave'); assert(not GameTooltip:IsShown())
member.menu(member,'party1'); assert(lastUnitMenu[1]=='PARTY' and lastUnitMenu[2]=='party1')
p.party.sortMethod='NAME'; R.Apply(); assert(h.nativeButtons[1]:GetAttribute('unit')=='party2' and h.nativeButtons[3]:GetAttribute('unit')=='party1')
member=h.nativeButtons[3]; other=h.nativeButtons[1]
p.clickCasting.enabled=true; assert(R.SaveBinding('shift',1,'spell',2061)); assert(member:GetAttribute('shift-type1')=='spell' and member:GetAttribute('shift-spell1')=='Spell 2061')
assert(not R.SaveBinding('shift',1,'spell',999999) and not R.SaveBinding('invalid',1,'target') and not R.SaveBinding('shift',1.5,'target'))
assert(R.SaveBinding('alt-ctrl-shift',5,'focus') and member:GetAttribute('alt-ctrl-shift-type5')=='focus')
local width=member:GetWidth(); combat=true; p.party.frameWidth=180; R.Apply(); assert(member:GetWidth()==width)
assert(R.SaveBinding('shift',1,'spell',139) and member:GetAttribute('shift-spell1')=='Spell 2061','Protected binding changed in combat')
units.party1.health=3000; units.party1.debuffs={}; event:RunScript('OnEvent','UNIT_HEALTH','party1'); event:RunScript('OnEvent','UNIT_AURA','party1')
assert(member.Health.value==3000 and not member.debuffs[1]:IsShown() and #allFrames==savedFrames)
-- Secure native roster changes must repaint the new occupant without leaking
-- the old occupant's aura, and keep click attributes targeting the same token.
units.party1={name='New member',guid='C',class='MAGE',health=5000,maxHealth=9000,power=20,maxPower=100}
TickHeaders(); event:RunScript('OnEvent','PARTY_MEMBERS_CHANGED')
for _,b in ipairs(h.nativeButtons) do if b:GetAttribute('unit')=='party1' then member=b end end
assert(member._euiGUID=='C' and member.name:GetText()=='New member' and not member.buffs[1]:IsShown() and not member.debuffs[1]:IsShown())
units.party1.vehicle='partypet1'; units.partypet1={name='Vehicle',guid='V',pet=true,health=100,maxHealth=200,power=30,maxPower=60}
event:RunScript('OnEvent','UNIT_ENTERED_VEHICLE','party1'); assert(member.unit=='partypet1' and member.Health.value==100)
units.party1.vehicle=nil; event:RunScript('OnEvent','UNIT_EXITED_VEHICLE','party1'); assert(member.unit=='party1' and member.Health.value==5000)
combat=false; event:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); assert(member:GetWidth()==180 and member:GetAttribute('shift-spell1')=='Spell 139')
p.clickCasting.enabled=false; R.Apply(); assert(member:GetAttribute('shift-type1')==nil and member:GetAttribute('*type1')=='target')
member:SetAttribute('shift-type1','external'); R.Apply(); assert(member:GetAttribute('shift-type1')=='external','Disabled binding editor overwrote Clique')
units.party1.connected=false; R.UpdateAll(false); assert(member.status:GetText()=='Offline' and member.healthText:GetText()=='')
units.party1.connected=true; units.party1.dead=true; R.UpdateAll(false); assert(member.status:GetText()=='Dead')
units.party1.dead=false; units.party1.ghost=true; R.UpdateAll(false); assert(member.status:GetText()=='Ghost')
units.party1.ghost=false; units.party1.afk=true; R.UpdateAll(false); assert(member.status:GetText()=='AFK'); units.party1.afk=false
units.party1.ready='ready'; event:RunScript('OnEvent','READY_CHECK','Player',20); assert(member.ready:IsShown())
event:RunScript('OnEvent','READY_CHECK_FINISHED'); now=13; R.UpdateAll(false); assert(not member.ready:IsShown())
units.raid1={name='Raid one',guid='R1',group=1,rank=2,class='DRUID',health=100,maxHealth=100,power=100,maxPower=100}
units.raid2={name='Raid two',guid='R2',group=1,class='PRIEST',health=75,maxHealth=100,power=50,maxPower=100,debuffs={{name='Mine',id=172,caster='player',dispel='Magic',duration=5,expires=18}}}
units.raid3={name='Raid three',guid='R3',group=2,class='WARRIOR',health=25,maxHealth=100,power=10,maxPower=100}
raidCount=3; R.GetSettings('raid').sortMethod='INDEX'; R.Apply(); TickHeaders(); event:RunScript('OnEvent','RAID_ROSTER_UPDATE')
assert(R.holders.raid:IsShown() and not R.holders.party:IsShown() and R.headers.raid[1].label:GetText()=='Group 1' and R.headers.raid[3].label:GetText()=='')
local raid=R.headers.raid[1].nativeButtons[2]; assert(raid:GetAttribute('unit')=='raid2' and raid.debuffs[1]:IsShown())
R.headers.raid[1].nativeButtons[1].menu(R.headers.raid[1].nativeButtons[1],'raid1'); assert(lastUnitMenu[1]=='RAID_PLAYER')
combat=true; units.raid2.group=2; TickHeaders(); event:RunScript('OnEvent','RAID_ROSTER_UPDATE'); assert(#allFrames==savedFrames)
local assigned; for _,b in ipairs(R.headers.raid[2].nativeButtons) do if b:GetAttribute('unit')=='raid2' then assigned=b end end
assert(assigned and assigned.debuffs[1]:IsShown() and not raid.debuffs[1]:IsShown(),'Subgroup move copied an aura')
now=19; event:RunScript('OnUpdate',.3); assert(not assigned.debuffs[1]:IsShown() and assigned.borderColor[1]==0,'Expired debuff retained its highlight')
combat=false; R.GetSettings('raid').orientation='vertical'; R.GetSettings('raid').maxGroups=2; R.Apply(); assert(R.holders.raid:GetWidth()==637 and R.holders.raid:GetHeight()==120)
assert(not R.headers.raid[3]:IsShown() and R.headers.raid[1]:GetAttribute('point')=='LEFT')
local mover=unlockByFolder.EllesmereUIRaidFrames[1]; mover.savePos(nil,'TOPLEFT','BOTTOMLEFT',300,0); R.Apply(); assert(select(5,R.holders.raid:GetPoint(1))==0)
p.enabled=false; R.Apply(); assert(not R.holders.raid:IsShown() and PartyMemberFrame1:GetParent()==UIParent and select(4,PartyMemberFrame1:GetPoint(1))==10 and PartyMemberFrame1.events.UNIT_HEALTH)
p.enabled=true; R.Apply(); raidCount=0; partyCount=0; TickHeaders(); assert(not R.holders.party:IsShown())
p.party.showSolo=true; R.Apply(); assert(R.holders.party:IsShown())
p.party.showPlayer=false; R.Apply(); assert(not R.holders.party:IsShown())
R.SetPreview(true); assert(R.previewHolders.party:IsShown()); combat=true; event:RunScript('OnEvent','PLAYER_REGEN_DISABLED'); assert(not R.previewHolders.party:IsShown()); combat=false
local original=R.addon.db.profile; EllesmereUIDB.activeProfile='Other'; R.addon.db.profile=EllesmereUI.Lite.NewDB('EllesmereUIRaidFramesDB',R.defaults).profile; _ERF_RefreshAll(); assert(R.holders.raid:GetWidth()==1056)
R.addon.db.profile=original; EllesmereUIDB.activeProfile='Default'; _ERF_RefreshAll(); assert(R.holders.raid:GetWidth()==637)
SlashCmdList.EUI335RAID(); assert(optionsLoaded and shownModule=='EllesmereUIRaidFrames')
assert(rotationCalls==0 and not event.events.GROUP_ROSTER_UPDATE)
''')
lua.execute((root/'EllesmereUIOptions/EUI_RaidFrames_335_Options.lua').read_text(encoding='utf-8-sig'))
lua.execute("allFrames[#allFrames]:RunScript('OnEvent','PLAYER_LOGIN')")
lua.execute('''
local cfg=modules.EllesmereUIRaidFrames; assert(#cfg.pages==6)
for _,page in ipairs(cfg.pages) do rows={}; assert(cfg.buildPage(page,UIParent,0)>0) end
rows={}; cfg.buildPage('Party',UIParent,0); FindRow('Frame Width').setValue(160); assert(R.GetSettings('party').frameWidth==160 and R.GetSettings('raid').frameWidth==125)
rows={}; cfg.buildPage('Aura Filters',UIParent,0); FindRow('Select Group').setValue('party'); FindRow('Tracked Spell IDs').setValue('139'); assert(R.GetSettings('party').debuffInclude[139] and not R.GetSettings('raid').debuffInclude)
local list=R.GetSettings('party').debuffInclude; FindRow('Tracked Spell IDs').setValue('bad'); assert(R.GetSettings('party').debuffInclude==list)
rows={}; cfg.buildPage('Click Casting',UIParent,0); FindRow('Spell ID').setValue('2061'); buttons['Save Binding'](); assert(R.GetSettings().clickCasting.bindings['shift:1'].spellID==2061)
buttons['Remove Selected Binding'](); assert(not R.GetSettings().clickCasting.bindings['shift:1'])
''')
def tile(file,next_name):
    source=(root/'EllesmereUIOptions'/file).read_text(encoding='utf-8-sig')
    body='local function TileRaidFrames'+source.split('local function TileRaidFrames',1)[1].split('local function '+next_name,1)[0]
    context="local NS=EllesmereUI.ModuleNS; local function ModuleOutlineCfg() return {type='label',text='Outline'} end; local function BLANK() return {type='label',text=''} end; local function LinkRow(_,y) return y-40 end; local function CopyBarDD(names,order) return names,order end; "
    return lua.execute(context+body+'\nreturn TileRaidFrames')
lua.execute('rows={}')
tile('EUI_Fonts_Options.lua','TileCooldownManager')(lua.globals().UIParent,0,lua.globals().EllesmereUI.Widgets,lua.table(folder='EllesmereUIRaidFrames',display='Raid Frames'))
lua.execute("FindRow('Text Group').setValue('party'); FindRow('Name Size').setValue(14); assert(R.GetSettings('party').nameSize==14 and R.GetSettings('raid').nameSize==11)")
lua.execute('rows={}')
tile('EUI_Textures_Options.lua','TileCooldownManager')(lua.globals().UIParent,0,lua.globals().EllesmereUI.Widgets,lua.table(folder='EllesmereUIRaidFrames'))
lua.execute("FindRow('Raid Health Texture').setValue('fade'); assert(R.GetSettings('raid').healthBarTexture=='fade' and R.GetSettings('party').healthBarTexture=='atrocity')")
lua.execute('''
local p=R.GetSettings(); local cfg=modules.EllesmereUIRaidFrames; local mover=unlockByFolder.EllesmereUIRaidFrames[1]
-- Upgrade copies existing settings/filter tables and positions independently.
local original=p; local legacy=CopyTable(p); legacy.raidLayouts={}; legacy.positions={raid={point='TOPLEFT',relPoint='BOTTOMLEFT',x=100,y=0}}
legacy.raid.frameWidth=170; legacy.raid.maxGroups=8; legacy.raid.debuffInclude={[139]=true}
R.addon.db.profile=legacy; R.Apply()
for _,size in ipairs({'10','25','40'}) do
    local c=R.GetRaidLayout(size); assert(c.frameWidth==170 and c.maxGroups==tonumber(size)/5 and c.debuffInclude[139])
    assert(legacy.positions['raid'..size].x==100)
end
R.GetRaidLayout('10').debuffInclude[139]=nil; R.GetRaidLayout('10').hiddenGroups[1]=true
assert(R.GetRaidLayout('25').debuffInclude[139] and not R.GetRaidLayout('25').hiddenGroups[1])
R.addon.db.profile=original; R.Apply(); p=original
for i=1,40 do units['raid'..i]={name='Member '..i,guid='Layout'..i,group=math.ceil(i/5),class='PRIEST',health=100,maxHealth=100} end
for _,size in ipairs({'10','25','40'}) do local c=R.GetRaidLayout(size); c.maxGroups=tonumber(size)/5; c.orientation='horizontal'; c.hiddenGroups={} end
R.GetRaidLayout('10').frameWidth=100; R.GetRaidLayout('25').frameWidth=120; R.GetRaidLayout('40').frameWidth=140
p.raidLayoutMode='auto'; raidCount=3; R.Apply(); assert(R.activeRaidLayout=='10' and R.headers.raid[2]:IsShown() and not R.headers.raid[3]:IsShown())
-- An underfilled 25-player instance keeps its capacity layout, not roster 10.
instanceType,instanceCapacity='raid',25; R.events:RunScript('OnEvent','ZONE_CHANGED_NEW_AREA')
assert(R.activeRaidLayout=='25' and R.headers.raid[5]:IsShown() and not R.headers.raid[6]:IsShown() and R.buttons[1]:GetWidth()==120)
instanceCapacity=10; R.events:RunScript('OnUpdate',.3); assert(R.activeRaidLayout=='10')
instanceCapacity=40; R.events:RunScript('OnEvent','PLAYER_ENTERING_WORLD'); assert(R.activeRaidLayout=='40' and R.headers.raid[8]:IsShown())
instanceType,instanceCapacity='none',0
raidCount=25; R.events:RunScript('OnEvent','RAID_ROSTER_UPDATE'); assert(R.activeRaidLayout=='25')
raidCount=26; R.events:RunScript('OnEvent','RAID_ROSTER_UPDATE'); assert(R.activeRaidLayout=='40')
raidCount=10; R.events:RunScript('OnEvent','RAID_ROSTER_UPDATE'); assert(R.activeRaidLayout=='10')
local frames=#allFrames; combat=true; raidCount=11; TickHeaders(); R.events:RunScript('OnEvent','RAID_ROSTER_UPDATE')
assert(R.activeRaidLayout=='10' and not R.headers.raid[3]:IsShown() and #allFrames==frames)
combat=false; R.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); assert(R.activeRaidLayout=='25' and R.headers.raid[3]:IsShown())
p.raidLayoutMode='10'; instanceType,instanceCapacity='raid',40; R.Apply(); assert(R.activeRaidLayout=='10','Manual choice ignored')
local c=R.GetRaidLayout('10'); c.hiddenGroups[1]=true; R.Apply()
assert(not R.headers.raid[1]:IsShown() and R.headers.raid[2]:IsShown())
assert(R.headers.raid[2]:GetAttribute('groupFilter')=='2' or R.headers.raid[2]:GetAttribute('nameList')=='Member 6,Member 7,Member 8,Member 9,Member 10')
assert(select(4,R.headers.raid[2]:GetPoint(1))==0 and R.holders.raid:GetWidth()==100,'Hidden group left a layout gap')
assert(R.headers.raid[2].label:GetText()=='Group 2','Group numbering changed after hiding')
c.hiddenGroups[2]=true; R.Apply(); assert(not R.holders.raid:IsShown() and mover.isHidden())
c.hiddenGroups[1]=nil; R.Apply(); assert(R.holders.raid:IsShown())
-- Defer hide/show edits in combat, preserving the native header unit roster.
combat=true; c.hiddenGroups[1]=true; R.Apply(); assert(R.headers.raid[1]:IsShown())
combat=false; R.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); assert(not R.headers.raid[1]:IsShown())
c.hiddenGroups={}; R.Apply(); mover.savePos(nil,'TOPLEFT','BOTTOMLEFT',101,0)
p.raidLayoutMode='25'; R.Apply(); mover.savePos(nil,'TOPLEFT','BOTTOMLEFT',202,50)
p.raidLayoutMode='10'; R.Apply(); assert(select(4,R.holders.raid:GetPoint(1))==101 and select(5,R.holders.raid:GetPoint(1))==0)
p.raidLayoutMode='25'; R.Apply(); assert(select(4,R.holders.raid:GetPoint(1))==202)
-- Editing an inactive layout never resizes live members, and affects only it.
rows={}; cfg.buildPage('Raid',UIParent,0); FindRow('Edit Raid Layout').setValue('10')
rows={}; cfg.buildPage('Raid',UIParent,0); assert(FindRow('Group Limit').max==2)
FindRow('Frame Width').setValue(110); FindRow('Show Group 2').setValue(false)
assert(R.GetRaidLayout('10').frameWidth==110 and R.GetRaidLayout('10').hiddenGroups[2] and R.GetRaidLayout('25').frameWidth==120 and R.activeRaidLayout=='25')
assert(R.buttons[1]:GetWidth()==120 and not R.GetRaidLayout('25').hiddenGroups[2])
rows={}; cfg.buildPage('Aura Filters',UIParent,0); FindRow('Select Group').setValue('raid')
rows={}; cfg.buildPage('Aura Filters',UIParent,0); FindRow('Tracked Spell IDs').setValue('172')
assert(R.GetRaidLayout('10').debuffInclude[172] and not R.GetRaidLayout('25').debuffInclude)
-- Solo preview honors the edited size even if a different mode is forced.
raidCount=0; partyCount=0; instanceType,instanceCapacity='none',0; R.SetPreview(true)
assert(R.activeRaidLayout=='10' and R.previewHolders.raid:IsShown() and R.previews.raid[1]:IsShown() and not R.previews.raid[6]:IsShown())
R.RaidLayoutDropdown().setValue('40'); assert(R.activeRaidLayout=='40' and R.previews.raid[40]:IsShown())
R.SetPreview(false); assert(R.activeRaidLayout=='25' and not R.previewHolders.raid:IsShown() and #allFrames==frames)
''')
lua.execute('rows={}; R.selectedWrathFontGroup="raid"; R.selectedRaidLayout="10"')
tile('EUI_Fonts_Options.lua','TileCooldownManager')(lua.globals().UIParent,0,lua.globals().EllesmereUI.Widgets,lua.table(folder='EllesmereUIRaidFrames',display='Raid Frames'))
lua.execute("FindRow('Name Size').setValue(18); assert(R.GetRaidLayout('10').nameSize==18 and R.GetRaidLayout('25').nameSize==11)")
lua.execute('rows={}')
tile('EUI_Textures_Options.lua','TileCooldownManager')(lua.globals().UIParent,0,lua.globals().EllesmereUI.Widgets,lua.table(folder='EllesmereUIRaidFrames'))
lua.execute("FindRow('Raid Health Texture').setValue('glass'); assert(R.GetRaidLayout('10').healthBarTexture=='glass' and R.GetRaidLayout('25').healthBarTexture=='atrocity')")
retail=Path('D:/World of Warcraft/_retail_/Interface/AddOns/EllesmereUIRaidFrames')
for original in retail.rglob('*'):
    if original.is_file() and original.suffix.lower()!='.toc': assert original.read_bytes()==(root/'EllesmereUIRaidFrames'/original.relative_to(retail)).read_bytes(),original
toc=(root/'EllesmereUIRaidFrames/EllesmereUIRaidFrames.toc').read_text(encoding='utf-8-sig')
assert '## Interface: 30300' in toc and '\nEllesmereUIRaidFrames.lua' not in toc and '## SavedVariables:' not in toc
for directory in ['Icons_335','Textures_335']:
    for file in (root/'EllesmereUIRaidFrames/Media'/directory).glob('*.tga'):
        data=file.read_bytes(); width,height,depth,flags=struct.unpack('<HHBB',data[12:18])
        assert data[2]==2 and flags==8 and depth==32 and not width&(width-1) and not height&(height-1) and len(data)==18+width*height*4,file
print('PASS: Raid Frames Lua51 lifecycle, 45 secure buttons, native roster/auras/clicks; separate 10/25/40 settings, automatic capacity/roster selection, manual override, group hiding/compaction, combat deferral, legacy migration, independent positions/filters/fonts/textures and selected-layout preview. Native secure rendering needs client confirmation.')
