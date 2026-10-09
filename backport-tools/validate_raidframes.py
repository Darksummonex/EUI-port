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
for file in ['EUI_RaidFrames_335.lua','EUI_RaidFrames_335_RaidDebuffs.lua','EUI_RaidFrames_335_Display.lua','EUI_RaidFrames_335_Extras.lua','EUI_RaidFrames_335_ClickCast.lua']:
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
assert(#R.buttons==74 and #headers==11 and #unlockByFolder.EllesmereUIRaidFrames==6,#R.buttons..' '..#headers..' '..#unlockByFolder.EllesmereUIRaidFrames)
-- Wrath strupper(point/columnAnchorPoint): every secure header (raid, party, tank,
-- pet) has valid anchors before its preallocating Show, and no addon write reran
-- a shown header's layout (the recursive SecureGroupPetHeader_Update chain).
for _,h in ipairs(headers) do
    assert(h.firstShowPoint and WRATH_ANCHORS[h.firstShowPoint] and h.firstShowColumnAnchor and WRATH_ANCHORS[h.firstShowColumnAnchor],h:GetName()..' shown without valid anchors')
    assert((h.shownAttributeWrites or 0)==0,h:GetName()..' wrote '..tostring(h.lastShownWrite)..' while shown')
end
assert(R.extraHeaders.pet.firstShowPoint=='TOP' and R.extraHeaders.pet.firstShowColumnAnchor=='LEFT' and #R.extraHeaders.pet.nativeButtons==20,'Pet header shown before its anchors')
assert(not R.extraHolders.tank:IsShown() and not R.extraHolders.pet:IsShown() and not R.extraHolders.boss:IsShown())
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
assert(tostring(member.role:GetTexture()):find('Icons_335\\\\healer-modern.tga',1,true) and member.raidMarker.marker==4,tostring(member.role:GetTexture())..' '..tostring(member.raidMarker.marker))
assert(member.buffs[1]:IsShown() and member.buffs[1].spellID==139 and not member.buffs[2]:IsShown())
assert(not member.debuffs[1]:IsShown() and not other.debuffs[1]:IsShown(),'Highlighted debuff duplicated in bar')
-- Raid debuffs: no listed boss debuff, so the dispellable curse fills the centre icon.
assert(member.raidDebuff:IsShown() and member.raidDebuff.filter=='HARMFUL|RAID' and member.raidDebuff.icon:GetTexture()=='aura-172','dispellable fallback')
assert(not other.raidDebuff:IsShown())
-- A listed boss debuff outranks it, and the higher priority entry wins.
table.insert(units.party1.debuffs,{name='Instability',id=69766,caster='boss1',duration=8,expires=10,stacks=3,removable=false})
table.insert(units.party1.debuffs,{name='Frost Beacon',id=70126,caster='boss1',duration=7,expires=9,removable=false})
R.UpdateFrame(member,true)
assert(member.raidDebuff.icon:GetTexture()=='aura-70126' and member.raidDebuff.filter=='HARMFUL' and member.raidDebuff.index==3,'boss debuff priority')
R.GetSettings().party.raidDebuffs=false; R.UpdateFrame(member,true); assert(not member.raidDebuff:IsShown(),'raid debuffs off')
R.GetSettings().party.raidDebuffs=nil; R.UpdateFrame(member,true); assert(member.raidDebuff:IsShown(),'old profiles default on')
table.remove(units.party1.debuffs); table.remove(units.party1.debuffs); R.UpdateFrame(member,true)
assert(member.raidDebuff.icon:GetTexture()=='aura-172')
-- Remaining assertions exercise the regular debuff bar independently.
p.party.raidDebuffs=false; p.raid.raidDebuffs=false; R.UpdateFrame(member,true)
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
raidCount=3; R.GetSettings('raid').raidDebuffs=false; R.GetSettings('raid').sortMethod='INDEX'; R.Apply(); TickHeaders(); event:RunScript('OnEvent','RAID_ROSTER_UPDATE')
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
local original=R.addon.db.profile; EllesmereUIDB.activeProfile='Other'; R.addon.db.profile=EllesmereUI.Lite.NewDB('EllesmereUIRaidFramesDB',R.defaults).profile; _ERF_RefreshAll(); assert(R.holders.raid:GetWidth()==657)
R.addon.db.profile=original; EllesmereUIDB.activeProfile='Default'; _ERF_RefreshAll(); assert(R.holders.raid:GetWidth()==637)
SlashCmdList.EUI335RAID(); assert(optionsLoaded and shownModule=='EllesmereUIRaidFrames')
assert(rotationCalls==0 and not event.events.GROUP_ROSTER_UPDATE)
''')
lua.execute('''
EllesmereUI.BuildDropdownControl=EllesmereUI.BuildDropdownControl or function(parent,_,_,values,order,get,set)
    local b=CreateFrame('Button',nil,parent); b.values,b.order,b.get,b.set=values,order,get,set; return b,b:CreateFontString(nil,'OVERLAY')
end
''')
lua.execute((root/'EllesmereUIOptions/EUI_RaidFrames_335_Options.lua').read_text(encoding='utf-8-sig'))
lua.execute("allFrames[#allFrames]:RunScript('OnEvent','PLAYER_LOGIN')")
lua.execute('''
local cfg=modules.EllesmereUIRaidFrames; assert(#cfg.pages==7 and cfg.pages[5]=='Extras')
for _,page in ipairs(cfg.pages) do rows={}; assert(cfg.buildPage(page,UIParent,0)>0) end
rows={}; cfg.buildPage('Party',UIParent,0); FindRow('Frame Width').setValue(160); assert(R.GetSettings('party').frameWidth==160 and R.GetSettings('raid').frameWidth==125)
rows={}; cfg.buildPage('Aura Filters',UIParent,0); FindRow('Select Group').setValue('party'); FindRow('Tracked Spell IDs').setValue('139'); assert(R.GetSettings('party').debuffInclude[139] and not R.GetSettings('raid').debuffInclude)
local list=R.GetSettings('party').debuffInclude; FindRow('Tracked Spell IDs').setValue('bad'); assert(R.GetSettings('party').debuffInclude==list)
rows={}; cfg.buildPage('Click Casting',UIParent,0); FindRow('Spell ID').setValue('2061'); buttons['Save Binding'](); assert(R.GetSettings().clickCasting.bindings['shift:1'].spellID==2061)
buttons['Remove Selected Binding'](); assert(not R.GetSettings().clickCasting.bindings['shift:1'])
-- Party LAYOUT leads with Retail's Horizontal Frames toggle.
rows={}; cfg.buildPage('Party',UIParent,0); assert(FindRow('Horizontal Frames') and FindRow('Member Sorting') and FindRow('Self Position'))
assert(not pcall(FindRow,'Horizontal Layout'))
-- Preview Mode follows the open options page (Retail default: Overlay).
local p=R.GetSettings(); assert(p.previewMode=='overlay')
local shownPanel,activeModule,activePage=true,'EllesmereUIRaidFrames','Raid'
local savedIsShown,savedModule,savedPage=EllesmereUI.IsShown,EllesmereUI.GetActiveModule,EllesmereUI.GetActivePage
function EllesmereUI:IsShown() return shownPanel end
function EllesmereUI:GetActiveModule() return activeModule end
function EllesmereUI:GetActivePage() return activePage end
EllesmereUI._scrollFrame=EllesmereUI._scrollFrame or CreateFrame('ScrollFrame',nil,UIParent)
combat=false; R.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED')
rows={}; cfg.buildPage('Raid',UIParent,0); local dd=R.previewModeControl
assert(dd and dd.get()=='overlay' and dd.order[1]=='real' and dd.values.none=='No Preview')
R.SyncOptionsPreview(); local oc=R.overlay
assert(R.optionsPreview=='raid' and oc and oc:IsShown() and oc.title:GetText()=='Overlay Preview')
assert(R.previews.raid[1]:GetParent()==oc and R.previews.raid[1]:IsShown() and not R.previewHolders.raid:IsShown())
assert(not R.previews.raid[21]:IsShown(),'Overlay shows more than four groups')
assert(R.holders.raid:GetAlpha()==.2 and oc.groupLabels[1]:GetText()=='1' and oc.groupLabels[1]:IsShown())
dd.set('real'); assert(not oc:IsShown() and R.holders.raid:GetAlpha()==1 and R.previews.raid[1]:GetParent()==R.previewHolders.raid)
dd.set('none'); assert(R.optionsPreview==nil and not oc:IsShown())
dd.set('overlay'); activePage='Party'; R.events:RunScript('OnUpdate',.3)
assert(R.optionsPreview=='party' and oc:IsShown() and R.previews.party[1]:GetParent()==oc and R.holders.raid:GetAlpha()==1)
local function X(b) return select(4,b:GetPoint(1)) end
local function Y(b) return select(5,b:GetPoint(1)) end
R.GetSettings('party').partyHorizontal=false; R.Apply(); assert(X(R.previews.party[2])==X(R.previews.party[1]) and Y(R.previews.party[2])<Y(R.previews.party[1]))
R.GetSettings('party').partyHorizontal=true; R.Apply(); assert(Y(R.previews.party[2])==Y(R.previews.party[1]) and X(R.previews.party[2])>X(R.previews.party[1]))
R.GetSettings('party').partyHorizontal=false
activePage='Buffs'; R.SyncOptionsPreview(); assert(R.optionsPreview==nil and not oc:IsShown())
activePage='Raid'; R.SyncOptionsPreview(); assert(oc:IsShown())
combat=true; R.events:RunScript('OnEvent','PLAYER_REGEN_DISABLED'); assert(not oc:IsShown() and R.holders.raid:GetAlpha()==1 and R.optionsPreview==nil)
R.events:RunScript('OnUpdate',.3); assert(R.optionsPreview==nil,'Preview reopened in combat')
combat=false; R.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); R.SyncOptionsPreview(); assert(oc:IsShown())
shownPanel=false; R.SyncOptionsPreview(); assert(R.optionsPreview==nil and not oc:IsShown() and R.holders.raid:GetAlpha()==1)
EllesmereUI.IsShown,EllesmereUI.GetActiveModule,EllesmereUI.GetActivePage=savedIsShown,savedModule,savedPage
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
frames=#allFrames -- page builds above own their option widgets; the preview must add none
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
# Unlock Mode preview defaults to the 25-player layout, not the 40-player maximum.
lua.execute('''
local original,savedSelected=R.addon.db.profile,R.selectedRaidLayout
EllesmereUIDB.activeProfile='Unlock25'; local fresh=EllesmereUI.Lite.NewDB('EllesmereUIRaidFramesDB',R.defaults).profile
R.addon.db.profile=fresh; R.selectedRaidLayout=nil; raidCount=0; partyCount=0; instanceType,instanceCapacity='none',0
assert(R.DEFAULT_RAID_LAYOUT=='25' and fresh.raidLayoutMode=='auto')
R.Apply(); assert(R.activeRaidLayout=='25','No-raid fallback is not the 25-player layout')
R.SetPreview(true)
assert(R.activeRaidLayout=='25','Unlock Mode preview does not default to 25 players')
assert(R.previewHolders.raid:IsShown() and R.previews.raid[25]:IsShown() and not R.previews.raid[26]:IsShown(),'Unlock Mode preview drew more than 25 frames')
local c=R.GetRaidLayout('25'); assert(R.GetSettings('raid')==c and R.GetOptionSettings('raid')==c and R.RaidLayoutDropdown().getValue()=='25')
assert(c.orientation=='horizontal' and R.holders.raid:GetWidth()==5*c.frameWidth+4*c.groupSpacing and R.holders.raid:GetHeight()==5*c.frameHeight+4*c.cellSpacing,'Holder is not sized for five groups')
local mover=unlockByFolder.EllesmereUIRaidFrames[1]; local mw,mh=mover.getSize()
assert(mw==R.holders.raid:GetWidth() and mh==R.holders.raid:GetHeight() and not mover.isHidden())
mover.savePos(nil,'TOPLEFT','BOTTOMLEFT',55,66); assert(fresh.positions.raid25 and fresh.positions.raid25.x==55 and not fresh.positions.raid40,'Mover saved outside the 25-player layout')
assert(EllesmereUI._ELEMENT_SETTINGS_MAP.RF_RaidFrames.page=='Raid')
R.RaidLayoutDropdown().setValue('40'); assert(R.activeRaidLayout=='40' and R.previews.raid[40]:IsShown(),'Edit Raid Layout choice lost in preview')
R.selectedRaidLayout=nil; fresh.raidLayoutMode='10'; R.Apply(); assert(R.activeRaidLayout=='10' and not R.previews.raid[11]:IsShown(),'Forced layout ignored by preview')
R.SetPreview(false); fresh.raidLayoutMode='auto'
R.addon.db.profile=original; EllesmereUIDB.activeProfile='Default'; R.selectedRaidLayout=savedSelected; R.Apply()
''')
# 0.7 Retail looks, layout options, prediction/resurrection and Extras.
lua.execute('''
local m=getmetatable(UIParent).__index
m.SetFrameStrata=function(self,s) self.strata=s end; m.GetFrameStrata=function(self) return self.strata or 'MEDIUM' end
m.SetGradientAlpha=function(self,...) self.gradient={...} end
function UnitAffectingCombat(u) return units[u] and units[u].combat or false end
talentPoints={0,0,0}; function GetNumTalentTabs() return 3 end; function GetTalentTabInfo(i) return 'Tree '..i,nil,talentPoints[i] end
local p=R.GetSettings(); local event=R.events; local c=R.GetSettings('party')
raidCount=0; for i=1,40 do units['raid'..i]=nil end
p.raidLayoutMode='auto'; c.showPlayer=true; c.showSolo=false; c.sortMethod='NAME'; c.debuffInclude=nil
units.party1={name='Zed',guid='Z1',class='PRIEST',health=5000,maxHealth=10000,power=50,maxPower=100,role='HEALER'}
units.party2={name='Ann',guid='Z2',class='WARRIOR',health=10000,maxHealth=10000,power=10,maxPower=100,powerType=1,powerToken='RAGE',role='TANK'}
partyCount=2; R.Apply(); TickHeaders(); event:RunScript('OnEvent','PARTY_MEMBERS_CHANGED')
local h=R.headers.party[1]
local function Find(unit) for _,b in ipairs(h.nativeButtons) do if b:IsShown() and b:GetAttribute('unit')==unit then return b end end end
-- Self First / Last through the native nameList.
c.selfPosition='first'; R.Apply(); assert(h:GetAttribute('nameList')=='Player,Ann,Zed' and h.nativeButtons[1]:GetAttribute('unit')=='player')
c.selfPosition='last'; R.Apply(); assert(h:GetAttribute('nameList')=='Ann,Zed,Player' and h.nativeButtons[3]:GetAttribute('unit')=='player')
c.selfPosition='sorted'; R.Apply(); assert(not h:GetAttribute('nameList') and h:GetAttribute('sortMethod')=='NAME')
local member=Find('party1'); assert(member)
-- Health colour modes, background and status colours.
c.healthColorMode='custom'; c.customFillColor={r=.1,g=.2,b=.3}; R.UpdateAll(false); assert(member.Health.color[1]==.1 and member.Health.color[3]==.3)
c.healthColorMode='classic'; R.UpdateAll(false); assert(member.Health.color[1]==1 and member.Health.color[2]==1 and member.Health.color[3]==0)
c.healthColorMode='customDynamic'; c.dynamicColor50={r=0,g=0,b=1}; R.UpdateAll(false); assert(member.Health.color[3]==1 and member.Health.color[1]==0)
c.healthColorMode='class'; R.UpdateAll(false); assert(member.Health.color[1]==1 and member.Health.color[2]==1)
c.bgClassColored=true; c.bgDarkness=50; R.UpdateAll(false); assert(member.Health.bg.vertexColor[1]==.5 and member.Health.bg.vertexColor[3]==.5)
units.party1.dead=true; R.UpdateAll(false); assert(member.Health.bg.vertexColor[1]==c.statusColorDead.r); units.party1.dead=false
c.bgClassColored=false; R.UpdateAll(false); assert(member.Health.bg.vertexColor[1]==c.customBgColor.r)
-- Name colour / length and text placement.
c.nameColorMode='custom'; c.nameCustomColor={r=.2,g=.4,b=.6}; c.nameMaxLength=2; R.UpdateAll(false)
assert(member.name:GetText()=='Ze' and member.name.textColor[2]==.4); c.nameMaxLength=0; c.nameColorMode='class'
c.namePosition='center'; c.healthTextPosition='bottomright'; R.Apply()
assert(select(1,member.name:GetPoint(1))=='CENTER' and select(1,member.healthText:GetPoint(1))=='BOTTOMRIGHT')
c.healthTextColorMode='class'; R.UpdateAll(false); assert(member.healthText.textColor[1]==1)
c.namePosition='topleft'; c.healthTextPosition='topright'; c.healthTextColorMode='custom'
-- Role icon styles, per-role toggles, combat hiding and placement.
assert(member.role:IsShown() and member.role:GetTexture():find('healer-modern.tga',1,true))
c.roleIconStyle='pixels'; R.UpdateAll(false); assert(member.role:GetTexture():find('pixels-healer.tga',1,true))
c.roleIconStyle='light'; R.UpdateAll(false); assert(member.role:GetTexture():find('Icons_335'..string.char(92)..'healer.tga',1,true))
c.roleIconStyle='blizzard'; R.UpdateAll(false); assert(member.role:GetTexture():find('UI-LFG-ICON-PORTRAITROLES',1,true) and member.role.texcoords[1]==20/64)
c.roleIconStyle='modern'; c.showRoleForHealer=false; R.UpdateAll(false); assert(not member.role:IsShown()); c.showRoleForHealer=true
c.roleIconHideInCombat=true; combat=true; R.UpdateAll(false); assert(not member.role:IsShown())
combat=false; R.UpdateAll(false); assert(member.role:IsShown()); c.roleIconHideInCombat=false
c.roleIconPosition='topright'; c.roleIconSize=20; R.Apply(); assert(select(1,member.role:GetPoint(1))=='TOPRIGHT' and member.role:GetWidth()==20)
c.raidMarkerPosition='bottom'; R.Apply(); assert(select(1,member.raidMarker:GetPoint(1))=='BOTTOM')
-- Combat indicator.
c.showCombatIndicator=true; units.party1.combat=true; R.UpdateAll(false); assert(member.combat:IsShown() and member.combat.texcoords[1]==.5)
units.party1.combat=false; R.UpdateAll(false); assert(not member.combat:IsShown())
-- Heal prediction (LibHealComm-4.0) and incoming resurrection (LibResComm-1.0).
local callbacks,heal,rezName={},3000,nil
local libs={['LibHealComm-4.0']={ALL_HEALS=15,GetHealAmount=function(_,guid) return guid=='Z1' and heal or nil end,GetHealModifier=function() return 1 end,RegisterCallback=function(_,e,fn) callbacks[e]=fn end},
 ['LibResComm-1.0']={IsUnitBeingRessed=function(_,name) return name==rezName end,RegisterCallback=function(_,e,fn) callbacks[e]=fn end}}
LibStub=setmetatable({},{__call=function(_,name) return libs[name] end}); R._predictionReady=nil; R.InitPrediction()
assert(callbacks.HealComm_HealStarted and callbacks.HealComm_HealStopped and callbacks.ResComm_ResStart)
c.healPrediction=true; c.healPredOpacity=50; R.Apply()
local W=member._healthW; assert(member.healPred:IsShown() and math.abs(member.healPred:GetWidth()-W*.3)<.01 and select(4,member.healPred:GetPoint(1))==W*.5 and member.healPred.vertexColor[4]==.5)
heal=0; callbacks.HealComm_HealStopped('HealComm_HealStopped','C',2061,1,false,'Z1'); assert(not member.healPred:IsShown())
heal=9000; callbacks.HealComm_HealStarted('HealComm_HealStarted','C',2061,1,GetTime()+2,'Z1'); assert(member.healPred:IsShown() and math.abs(member.healPred:GetWidth()-W*.5)<.01,'Prediction not capped at missing health')
c.healthVerticalFill=true; R.Apply(); assert(member.Health.orientation=='VERTICAL' and member.healPred:GetWidth()==W)
c.healthVerticalFill=false; c.healPrediction=false; R.Apply(); assert(not member.healPred:IsShown())
units.party1.dead=true; rezName='Zed'; R.UpdateAll(false); assert(member.rez:IsShown())
rezName=nil; callbacks.ResComm_ResEnd('ResComm_ResEnd','Priest','Zed'); assert(not member.rez:IsShown())
c.showIncomingRez=false; rezName='Zed'; R.UpdateAll(false); assert(not member.rez:IsShown()); units.party1.dead=false; rezName=nil; c.showIncomingRez=true
-- Retail DISPELS: overlay modes/opacity, health-bar border, type icon, Color Custom
-- Borders, per-type alpha opt-out, Only Show Dispellable, border priority and Sated hiding.
units.party1.debuffs={{name='Hex',id=172,caster='enemy',dispel='Curse',duration=10,expires=now+10}}
assert(c.dispelOverlay=='fill' and c.dispelOverlayOpacity==100 and c.dispelShowAll==true and c.dispelBorderSize==0)
c.dispelColorCurse={r=.6,g=0,b=.6}
event:RunScript('OnEvent','UNIT_AURA','party1'); local ov=member.dispelOverlay
assert(ov:IsShown() and ov.allPoints==member.Health:GetStatusBarTexture() and ov.vertexColor[1]==.6 and ov.vertexColor[4]==1 and member.borderColor[1]==.6)
c.dispelOverlay='full'; c.dispelOverlayOpacity=40; R.UpdateAll(false); assert(ov.allPoints==member.Health and math.abs(ov.vertexColor[4]-.4)<1e-6)
c.dispelOverlay='gradient'; R.UpdateAll(false); assert(ov.texture:find('Textures_335\\\\dispel-gradient.tga',1,true) and ov.allPoints==member.Health)
c.dispelOverlay='gradient_sharp'; R.UpdateAll(false); assert(ov.texture:find('Textures_335\\\\dispel-gradient-sharp.tga',1,true))
c.dispelOverlay='none'; R.UpdateAll(false); assert(not ov:IsShown() and member.borderColor[1]==.6,'Color Custom Borders depends on the overlay')
c.dispelBorderSize=2; R.UpdateAll(false); assert(member.dispelBorder:IsShown() and member.dispelBorder.backdrop.edgeSize==2 and member.dispelBorder.borderColor[1]==.6)
c.showDispelIcons=true; c.dispelIconPosition='topright'; c.dispelIconSize=20; R.Apply()
assert(member.dispelIcon:IsShown() and member.dispelIcon.texture:find('RemoveCurse',1,true) and member.dispelIcon:GetWidth()==20 and select(1,member.dispelIcon:GetPoint(1))=='TOPRIGHT')
c.dispelHighlight=false; R.UpdateAll(false); assert(member.borderColor[1]==c.borderColor.r,'Color Custom Borders off kept the type color'); c.dispelHighlight=true
c.dispelColorCurse={r=.6,g=0,b=.6,a=0}; R.UpdateAll(false); assert(not member.dispelBorder:IsShown() and not member.dispelIcon:IsShown() and member.borderColor[1]~=.6,'Alpha 0 type not opted out')
c.dispelColorCurse={r=.6,g=0,b=.6}; c.dispelOverlay='fill'; c.dispelOverlayOpacity=100
units.party1.debuffs[1].removable=false; c.dispelShowAll=false; event:RunScript('OnEvent','UNIT_AURA','party1'); assert(not ov:IsShown() and not member.dispelBorder:IsShown(),'Only Show Dispellable showed a debuff the player cannot remove')
c.dispelShowAll=true; event:RunScript('OnEvent','UNIT_AURA','party1'); assert(ov:IsShown()); units.party1.debuffs[1].removable=nil
c.dispelIconBorderSize=3; event:RunScript('OnEvent','UNIT_AURA','party1'); assert(member.debuffs[1]._edge==3 and member.debuffs[1].borderColor[1]==.6)
c.dispelIconBorderSize=0; event:RunScript('OnEvent','UNIT_AURA','party1'); assert(member.debuffs[1].borderColor[1]==0); c.dispelIconBorderSize=-1
units.party1.threat=3; R.UpdateAll(false); assert(member.borderColor[1]==c.threatBorderColor.r and member.borderColor[2]==c.threatBorderColor.g); units.party1.threat=nil
units.party1.debuffs={}; event:RunScript('OnEvent','UNIT_AURA','party1'); assert(not member.dispelOverlay:IsShown() and not member.dispelBorder:IsShown() and not member.dispelIcon:IsShown())
c.dispelBorderSize=0; c.showDispelIcons=false; R.Apply()
-- Legacy frame-colour keys migrate once into the Retail DISPELS keys.
local lp=R.addon.db.profile; local saved=lp.dispelsVersion
lp.party.dispelFrameColor=false; lp.raidLayouts['25'].dispelFrameColorStyle='gradient'; lp.raidLayouts['25'].dispelFrameColorStrength=.5; lp.dispelsVersion=nil
R.EnsureRaidLayouts(true)
assert(lp.party.dispelOverlay=='none' and lp.raidLayouts['25'].dispelOverlay=='gradient' and lp.raidLayouts['25'].dispelOverlayOpacity==50 and lp.raidLayouts['10'].dispelOverlay=='fill' and lp.dispelsVersion==1)
assert(lp.party.dispelFrameColor==nil and lp.raidLayouts['25'].dispelFrameColorStyle==nil)
lp.party.dispelOverlay='fill'; lp.raidLayouts['25'].dispelOverlay='fill'; lp.raidLayouts['25'].dispelOverlayOpacity=100
units.target={name='Ann',guid='Z2'}; R.UpdateAll(false); local tank=Find('party2'); assert(tank.borderColor[1]==c.targetBorderColor.r and tank.borderColor[2]==c.targetBorderColor.g); units.target=nil
c.borderColor={r=.3,g=.3,b=.3}; R.UpdateAll(false); assert(member.borderColor[1]==.3)
units.party1.debuffs={{name='Sated',id=57724,caster='enemy',duration=600,expires=now+600}}
c.hideLustDebuff=false; event:RunScript('OnEvent','UNIT_AURA','party1'); assert(member.debuffs[1]:IsShown() and member.debuffs[1].spellID==57724)
c.hideLustDebuff=true; event:RunScript('OnEvent','UNIT_AURA','party1'); assert(not member.debuffs[1]:IsShown()); units.party1.debuffs={}
-- Border size, hover border, tooltip modes.
c.borderSize=3; R.Apply(); assert(member.backdrop.edgeSize==3 and select(4,member.Health:GetPoint(1))==3); c.borderSize=1; R.Apply()
cursorX,cursorY=-999,-999; c.hoverBorderColor={r=.9,g=.8,b=.7}
GameTooltip.tooltipUnit=nil; c.tooltipMode='never'; member:RunScript('OnEnter'); assert(member.hover:IsShown() and member.hover.borderColor[2]==.8 and GameTooltip.tooltipUnit==nil); member:RunScript('OnLeave')
assert(not member.hover:IsShown()); c.hoverBorderEnabled=false; member:RunScript('OnEnter'); assert(not member.hover:IsShown()); member:RunScript('OnLeave'); c.hoverBorderEnabled=true
c.tooltipMode='outOfCombat'; combat=true; member:RunScript('OnEnter'); assert(GameTooltip.tooltipUnit==nil); member:RunScript('OnLeave'); combat=false
member:RunScript('OnEnter'); assert(GameTooltip.tooltipUnit=='party1'); member:RunScript('OnLeave')
GameTooltip.tooltipUnit=nil; c.tooltipMode='always'; combat=true; member:RunScript('OnEnter'); assert(GameTooltip.tooltipUnit=='party1'); member:RunScript('OnLeave'); combat=false; c.tooltipMode='outOfCombat'
-- Strata, party horizontal growth and reversed members/groups.
c.frameStrata='HIGH'; R.Apply(); assert(R.holders.party.strata=='HIGH'); c.frameStrata='BOGUS'; R.Apply(); assert(R.holders.party.strata=='LOW'); c.frameStrata='LOW'
local w,spacing=c.frameWidth,c.cellSpacing
c.partyHorizontal=true; R.Apply(); assert(h:GetAttribute('point')=='LEFT' and h:GetAttribute('xOffset')==spacing and R.holders.party:GetWidth()==5*w+4*spacing)
c.reverseUnits=true; R.Apply(); assert(h:GetAttribute('point')=='RIGHT' and h:GetAttribute('xOffset')==-spacing and select(1,h:GetPoint(1))=='TOPRIGHT')
c.partyHorizontal=false; R.Apply(); assert(h:GetAttribute('point')=='BOTTOM' and h:GetAttribute('yOffset')==spacing and select(1,h:GetPoint(1))=='BOTTOMLEFT'); c.reverseUnits=false; R.Apply()
for i=1,10 do units['raid'..i]={name='Member '..i,guid='G'..i,group=math.ceil(i/5),class='PRIEST',health=100,maxHealth=100,power=100,maxPower=100} end
raidCount=10; partyCount=0; R.Apply(); TickHeaders()
local rc=R.GetSettings('raid'); rc.orientation='horizontal'; rc.maxGroups=2; rc.hiddenGroups={}; rc.reverseGroups=true; R.Apply()
assert(R.activeRaidLayout=='10' and select(4,R.headers.raid[1]:GetPoint(1))==rc.frameWidth+rc.groupSpacing and select(4,R.headers.raid[2]:GetPoint(1))==0)
rc.reverseGroups=false; R.Apply(); assert(select(4,R.headers.raid[1]:GetPoint(1))==0)
-- Extras: Main Tank frames from raid MAINTANK / MAINASSIST assignments.
units.raid1.mainRole='MAINTANK'; units.raid2.mainRole='MAINASSIST'
p.tankFrames.enabled=true; R.Apply(); TickHeaders()
local th=R.extraHeaders.tank
assert(R.extraHolders.tank:IsShown() and th.nativeButtons[1]:GetAttribute('unit')=='raid1' and not th.nativeButtons[2]:IsShown() and th.nativeButtons[1].name:GetText()=='Member 1')
p.tankFrames.includeAssist=true; R.Apply(); assert(th:GetAttribute('groupFilter')=='MAINTANK,MAINASSIST' and th.nativeButtons[2]:GetAttribute('unit')=='raid2')
p.tankFrames.extraWidth=20; R.Apply(); assert(th.nativeButtons[1]:GetWidth()==rc.frameWidth+20)
p.tankFrames.horizontal=true; R.Apply(); assert(th:GetAttribute('point')=='LEFT'); p.tankFrames.horizontal=false; R.Apply()
-- Pets: 20 preallocated raid pet buttons, vehicle swap disabled.
units.raidpet1={name='Wolf',guid='PW',pet=true,health=50,maxHealth=100}
p.petFrames.raid=true; R.Apply(); TickHeaders()
local pet=R.extraHeaders.pet
assert(#pet.nativeButtons==20 and R.extraHolders.pet:IsShown() and pet.nativeButtons[1]:GetAttribute('unit')=='raidpet1' and not pet.nativeButtons[2]:IsShown())
assert(pet.nativeButtons[1]:GetAttribute('toggleForVehicle')==false and pet.nativeButtons[1].name:GetText()=='Wolf' and pet.nativeButtons[1]:GetHeight()==rc.frameHeight-14)
local frames=#allFrames; combat=true; units.raidpet2={name='Cat',guid='PC',pet=true,health=1,maxHealth=1}; TickHeaders(); event:RunScript('OnEvent','RAID_ROSTER_UPDATE')
assert(pet.nativeButtons[2]:GetAttribute('unit')=='raidpet2' and #allFrames==frames); combat=false; event:RunScript('OnEvent','PLAYER_REGEN_ENABLED')
raidCount=0; partyCount=2; units.pet={name='Imp',guid='PI',pet=true,health=10,maxHealth=10}
p.petFrames.raid=false; p.petFrames.party=true; R.Apply(); TickHeaders()
assert(R.extraHolders.pet:IsShown() and pet.nativeButtons[1]:GetAttribute('unit')=='pet' and not R.extraHolders.tank:IsShown())
-- Layout changes reach shown headers only through hidden writes, with valid anchors.
for _,hh in ipairs(headers) do hh.shownAttributeWrites=0 end
p.petFrames.horizontal=true; R.Apply(); assert(pet:GetAttribute('point')=='LEFT' and pet:GetAttribute('columnAnchorPoint')=='TOP' and pet:IsShown())
p.petFrames.horizontal=false; R.GetSettings('party').reverseUnits=true; R.Apply(); assert(pet:GetAttribute('point')=='TOP' and pet:GetAttribute('columnAnchorPoint')=='LEFT')
assert(R.headers.party[1]:GetAttribute('point')=='BOTTOM' and R.headers.party[1]:GetAttribute('columnAnchorPoint')=='LEFT' and R.headers.party[1]:IsShown())
R.GetSettings('party').reverseUnits=false; R.Apply()
for _,hh in ipairs(headers) do assert((hh.shownAttributeWrites or 0)==0,hh:GetName()..' wrote '..tostring(hh.lastShownWrite)..' while shown') end
local probe={}; R.HeaderAnchors(probe,nil,nil); assert(probe.point=='TOP' and probe.columnAnchorPoint=='LEFT')
R.HeaderAnchors(probe,'left',5); assert(probe.point=='LEFT' and probe.columnAnchorPoint=='TOP')
R.HeaderAnchors(probe,'bogus','bottomright'); assert(probe.point=='TOP' and probe.columnAnchorPoint=='BOTTOMRIGHT')
-- Secure Extras layout waits for PLAYER_REGEN_ENABLED in combat.
combat=true; p.petFrames.horizontal=true; R.ApplyExtras(); assert(pet:GetAttribute('point')=='TOP','Pet header changed in combat')
combat=false; event:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); assert(pet:GetAttribute('point')=='LEFT','Deferred Extras layout not applied')
p.petFrames.horizontal=false; R.Apply()
-- Friendly bosses: per-button [target=bossN,help] drivers; Healers Only uses role, then talents.
p.friendlyBoss.display='always'; units.boss1={name='Valithria',guid='B1',health=50,maxHealth=100}; R.Apply(); TickHeaders()
assert(R.extraHolders.boss:IsShown() and R.bossButtons[1]:IsShown() and not R.bossButtons[2]:IsShown() and R.bossButtons[1].name:GetText()=='Valithria')
assert(R.bossButtons[1]:GetAttribute('toggleForVehicle')==false and R.bossButtons[1]:GetAttribute('*type1')=='target')
units.boss1.hostile=true; TickHeaders(); assert(not R.bossButtons[1]:IsShown()); units.boss1=nil
p.friendlyBoss.display='healers'; units.player.role='DAMAGER'; R.Apply(); assert(not R.ExtraActive('boss') and not R.extraHolders.boss:IsShown())
units.player.role=nil; talentPoints={0,0,51}; R.Apply(); assert(R.ExtraActive('boss') and R.extraHolders.boss:IsShown())
talentPoints={51,0,0}; R.Apply(); assert(not R.ExtraActive('boss')); units.player.role='HEALER'; R.Apply(); assert(R.ExtraActive('boss'))
p.friendlyBoss.display='never'; units.player.role='DAMAGER'
-- Healer Mana text.
units.party1.power=500; units.party1.maxPower=1000
p.healerMana.mode='party'; R.Apply(); local hm=R.healerMana
assert(hm:IsShown() and hm.rows[1]:GetText()=='50%' and not hm.rows[2]:IsShown())
units.party1.power=250; event:RunScript('OnEvent','UNIT_MANA','party1'); assert(hm.rows[1]:GetText()=='25%')
p.healerMana.growth='UP'; R.Apply(); assert(select(1,hm.rows[1]:GetPoint(1))=='BOTTOMLEFT'); p.healerMana.growth='DOWN'
partyCount=0; raidCount=10; units.raid3.class='PALADIN'; p.healerMana.mode='raid'; R.Apply()
assert(hm:IsShown() and hm.rows[1]:GetText():find('Member',1,true))
p.healerMana.includeUnassigned=false; R.Apply(); assert(not hm.rows[1]:IsShown()); p.healerMana.includeUnassigned=true
raidCount=0; p.healerMana.mode='both'; R.SetPreview(true)
assert(hm:IsShown() and hm.rows[3]:IsShown() and hm.rows[1]:GetText():find('Healer One',1,true))
assert(R.extraPreviewHolders.tank:IsShown() and R.extraPreviews.tank[1].name:GetText()=='Main Tank 1' and R.extraPreviewHolders.pet:IsShown() and not R.extraPreviewHolders.boss:IsShown())
combat=true; event:RunScript('OnEvent','PLAYER_REGEN_DISABLED'); assert(not R.extraPreviewHolders.tank:IsShown() and not hm.preview); combat=false; event:RunScript('OnEvent','PLAYER_REGEN_ENABLED')
R.SetPreview(false); assert(not hm:IsShown() and not R.extraPreviewHolders.tank:IsShown())
-- Unlock Mode movers and their Element Options targets.
local byKey={}; for _,e in ipairs(unlockByFolder.EllesmereUIRaidFrames) do byKey[e.key]=e end
for _,key in ipairs({'RF_RaidFrames','RF_PartyFrames','RF_TankFrames','RF_PetFrames','RF_BossFrames','RF_HealerMana'}) do
    assert(byKey[key] and byKey[key].getFrame(),key)
    local map=EllesmereUI._ELEMENT_SETTINGS_MAP[key]; assert(map and map.module=='EllesmereUIRaidFrames' and map.page==R.ELEMENT_PANELS[key].page,key)
end
-- Core's deferred Unlock Mode body replaces the map with stale Retail labels after OnEnable.
EllesmereUI._unlockCoreInit=function() EllesmereUI._ELEMENT_SETTINGS_MAP={RF_RaidFrames={module='EllesmereUIRaidFrames',page='Raid',sectionName='FRAME SIZES',highlightText='20 Man Frame Width'}} end
R._panelHook=nil; R.RegisterElementPanels(); EllesmereUI._unlockCoreInit()
assert(EllesmereUI._ELEMENT_SETTINGS_MAP.RF_RaidFrames.highlightText=='Frame Width' and EllesmereUI._ELEMENT_SETTINGS_MAP.RF_HealerMana.page=='Extras')
EllesmereUI._unlockCoreInit=nil
byKey.RF_TankFrames.savePos(nil,'TOPLEFT','BOTTOMLEFT',123,45); R.Apply(); assert(select(4,R.extraHolders.tank:GetPoint(1))==123)
byKey.RF_HealerMana.savePos(nil,'TOPLEFT','BOTTOMLEFT',77,10); R.Apply(); assert(select(4,R.healerMana:GetPoint(1))==77)
byKey.RF_TankFrames.clearPos(); assert(not p.positions.tank and select(2,R.extraHolders.tank:GetPoint(1))==UIParent)
assert(byKey.RF_BossFrames.isHidden() and not byKey.RF_TankFrames.isHidden())
local cfg=modules.EllesmereUIRaidFrames; local sections={}; local section=EllesmereUI.Widgets.SectionHeader
EllesmereUI.Widgets.SectionHeader=function(self,parent,label,y) sections[label]=true; return section(self,parent,label,y) end
for key,panel in pairs(R.ELEMENT_PANELS) do
    rows={}; sections={}; cfg.buildPage(panel.page,UIParent,0)
    assert(sections[panel.sectionName] and FindRow(panel.highlightText),key)
end
EllesmereUI.Widgets.SectionHeader=section
rows={}; cfg.buildPage('Extras',UIParent,0); FindRow('Show Raid Pets').setValue(false); FindRow('Extra Height').setValue(5); assert(not p.petFrames.raid)
rows={}; cfg.buildPage('Party',UIParent,0); FindRow('Health Color').setValue('dark'); assert(c.healthColorMode=='dark' and c.healthClassColored==false)
FindRow('Border Color').setValue(.4,.5,.6); assert(c.borderColor.g==.5); FindRow('Self Position').setValue('first'); assert(c.selfPosition=='first'); c.selfPosition='sorted'
-- Retail DISPELS rows (per group; four swatches since Wrath has no Bleed).
assert(not pcall(FindRow,'Debuff Type Border') and FindRow('Overlay Opacity').min==5)
FindRow('Dispel Overlay').setValue('gradient'); assert(c.dispelOverlay=='gradient' and R.GetOptionSettings('raid').dispelOverlay=='fill')
FindRow('Type Icon Position').setValue('left'); assert(c.showDispelIcons and c.dispelIconPosition=='left')
FindRow('Type Icon Position').setValue('none'); assert(not c.showDispelIcons and c.dispelIconPosition=='left' and FindRow('Type Icon Position').getValue()=='none')
local sw=FindRow('Dispel Colors').swatches; assert(#sw==4 and sw[2].tooltip=='Curse'); sw[2].setValue(.1,.2,.3,.5); assert(c.dispelColorCurse.g==.2 and c.dispelColorCurse.a==.5)
FindRow('Only Show Dispellable').setValue(true); assert(c.dispelShowAll==false); FindRow('Only Show Dispellable').setValue(false); assert(c.dispelShowAll==true)
FindRow('Frame Border').setValue(1); assert(c.dispelBorderSize==1); c.dispelBorderSize=0; c.dispelOverlay='fill'; c.dispelColorCurse={r=.6,g=0,b=.6}
rows={}; cfg.buildPage('Raid',UIParent,0); FindRow('Reverse Group Order').setValue(true); assert(R.GetOptionSettings('raid').reverseGroups); R.GetOptionSettings('raid').reverseGroups=false
p.tankFrames.enabled=false; p.petFrames.party=false; p.healerMana.mode='none'; R.Apply()
assert(not R.extraHolders.tank:IsShown() and not R.extraHolders.pet:IsShown() and not R.healerMana:IsShown())
-- Mock fidelity: the 0.10 pet header (20 slots in 4 columns, shown before any
-- columnAnchorPoint) raises Wrath's strupper error.
local bad=CreateFrame('Frame','EUI335BadPetHeader',UIParent,'SecureGroupPetHeaderTemplate')
bad:Hide(); bad:SetAttribute('template','EUI335RaidUnitTemplate'); bad:SetAttribute('unitsPerColumn',5); bad:SetAttribute('maxColumns',4); bad:SetAttribute('startingIndex',-19)
local ok,err=pcall(bad.Show,bad); bad:Hide(); headers[#headers]=nil
assert(not ok and tostring(err):find("bad argument #1 to 'strupper'",1,true) and tostring(err):find('columnAnchorPoint',1,true),tostring(err))
''')
# Bundled libraries load before the module, and every Lua chunk respects Lua 5.1 limits.
toc_lines=[l.strip() for l in (root/'EllesmereUIRaidFrames/EllesmereUIRaidFrames.toc').read_text(encoding='utf-8-sig').splitlines() if l.strip() and not l.startswith('#')]
order=[l for l in toc_lines if l.endswith('.lua') or l.endswith('.xml')]
assert order[:3]==['Libs\\ChatThrottleLib\\ChatThrottleLib.lua','Libs\\LibHealComm-4.0\\LibHealComm-4.0.lua','Libs\\LibResComm-1.0\\LibResComm-1.0.lua'],order
assert order.index('EUI_RaidFrames_335_Display.lua')<order.index('EUI_RaidFrames_335_Extras.lua')<order.index('EUI_RaidFrames_335.xml'),order
compile=lua.eval('function(src,name) local f,err=loadstring(src,name); return f and "ok" or err end')
for name in order:
    path=root/'EllesmereUIRaidFrames'/name.replace('\\','/'); assert path.is_file(),path
    if name.endswith('.lua'):
        result=compile(path.read_text(encoding='utf-8-sig'),name)
        assert result=='ok',result
for role in ['tank','healer','dps']:
    for style in [role,role+'-modern','pixels-'+role]:
        assert (root/'EllesmereUIRaidFrames/Media/Icons_335'/(style+'.tga')).is_file(),style
retail=Path('D:/World of Warcraft/_retail_/Interface/AddOns/EllesmereUIRaidFrames')
for original in retail.rglob('*'):
    if original.is_file() and original.suffix.lower()!='.toc': assert original.read_bytes()==(root/'EllesmereUIRaidFrames'/original.relative_to(retail)).read_bytes(),original
toc=(root/'EllesmereUIRaidFrames/EllesmereUIRaidFrames.toc').read_text(encoding='utf-8-sig')
assert '## Interface: 30300' in toc and '\nEllesmereUIRaidFrames.lua' not in toc and '## SavedVariables:' not in toc
for directory in ['Icons_335','Textures_335']:
    for file in (root/'EllesmereUIRaidFrames/Media'/directory).glob('*.tga'):
        data=file.read_bytes(); width,height,depth,flags=struct.unpack('<HHBB',data[12:18])
        assert data[2]==2 and flags==8 and depth==32 and not width&(width-1) and not height&(height-1) and len(data)==18+width*height*4,file
print('PASS: Raid Frames Lua51 lifecycle, 74 preallocated secure buttons (raid/party/tank/pet/boss), native roster/auras/clicks; Retail looks (health/background/name/text colours and placement, role styles, borders, hover, dispel fill/gradient, Sated, tooltip modes), HealComm prediction, ResComm rez, self first/last, reverse/horizontal growth, strata, Extras (main tanks, pets, friendly bosses, healer mana) with movers and Element Options panels; separate 10/25/40 settings, automatic capacity/roster selection, manual override, group hiding/compaction, combat deferral, legacy migration, independent positions/filters/fonts/textures, selected-layout preview and a 25-player Unlock Mode default. Native secure rendering needs client confirmation.')
