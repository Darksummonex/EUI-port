"""Raid Frames Targeted Spells (3.3.5): casters seen through unit tokens, victim = caster's target."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
lua=LuaRuntime(unpack_returned_tuples=True)
for file in ['backport-tools/wrath_mock.lua','backport-tools/inventory_resources_mock.lua','backport-tools/raidframes_mock.lua','EllesmereUI/EllesmereUI_Lite.lua','EllesmereUI/EllesmereUI_Absorbs_335.lua','EllesmereUI/EUI_AuraFilters_335.lua','EllesmereUI/EUI_AuraIndicators_335.lua','EllesmereUIOptions/EUI_AuraFilters_335_Options.lua','EllesmereUIOptions/EUI_AuraIndicators_335_Options.lua']:
    lua.execute((root/file).read_text(encoding='utf-8-sig'))
toc=(root/'EllesmereUIRaidFrames/EllesmereUIRaidFrames.toc').read_text(encoding='utf-8-sig')
order=[l.strip() for l in toc.splitlines() if l.strip().endswith('.lua') and not l.startswith('#') and not l.strip().startswith('Libs')]
assert order.index('EUI_RaidFrames_335_Extras.lua')<order.index('EUI_RaidFrames_335_TargetedSpells.lua'),order
assert '## Version: 9.3.4-335-0.24' in toc
ns=lua.table()
for file in order:
    lua.execute((root/'EllesmereUIRaidFrames'/file).read_text(encoding='utf-8-sig'),'EllesmereUIRaidFrames',ns)
lua.globals().R=ns
lua.execute('''
-- Compound tokens resolve through each unit's target GUID (player owns "target").
mobs={}
local function ByGUID(g)
    if mobs[g] then return mobs[g] end
    for _,u in next,units do if u.guid==g then return u end end
end
setmetatable(units,{__index=function(t,k)
    if type(k)~='string' then return nil end
    local base
    if k=='target' then base='player' elseif k:sub(-6)=='target' then base=k:sub(1,-7) else return nil end
    local e=t[base]; return e and e.target and ByGUID(e.target)
end})
castCalls=0
function UnitCanAttack(_,u) return units[u] and units[u].hostile or false end
function UnitCastingInfo(u) castCalls=castCalls+1; local c=units[u] and units[u].cast
    if c then return c.name,'Rank 1',c.name,c.icon,c.start,c.finish,false,c.id or 1,c.notInt end end
function UnitChannelInfo(u) castCalls=castCalls+1; local c=units[u] and units[u].channel
    if c then return c.name,'Rank 1',c.name,c.icon,c.start,c.finish,false,c.notInt end end
''')
core=(root/'EllesmereUI/EllesmereUI_Lite.lua').read_text(encoding='utf-8-sig')
safe=lua.execute('local function errorhandler('+core.split('local function errorhandler(',1)[1].split('\n-------------------------------------------------------------------------------',1)[0]+'\nreturn safecall')
assert safe(ns.addon.OnInitialize,ns.addon) is True
lua.execute("R.GetSettings().raidLayoutMode='10'")
assert safe(ns.addon.OnEnable,ns.addon) is True
lua.execute('''
EllesmereUI.BuildDropdownControl=EllesmereUI.BuildDropdownControl or function(parent,_,_,values,order,get,set)
    local b=CreateFrame('Button',nil,parent); b.values,b.order,b.get,b.set=values,order,get,set; return b,b:CreateFontString(nil,'OVERLAY')
end
''')
lua.execute((root/'EllesmereUIOptions/EUI_RaidFrames_335_Options.lua').read_text(encoding='utf-8-sig'))
lua.execute("allFrames[#allFrames]:RunScript('OnEvent','PLAYER_LOGIN')")
lua.execute('''
local TS=R.TargetedSpells; local driver=TS.driver; local event=R.events; local p=R.GetSettings()
local function Tick() driver:RunScript('OnUpdate',.3) end
local function Fire(e,unit) driver:RunScript('OnEvent',e,unit) end
local function Find(unit) for _,b in ipairs(R.buttons) do if b:IsShown() and b:GetAttribute('unit')==unit then return b end end end
local function Icons(b) local n=0; for _,f in ipairs(b and b.tsIcons or {}) do if f:IsShown() then n=n+1 end end; return n end
local function Count(t) local n=0; for _ in pairs(t) do n=n+1 end; return n end
-- Retail defaults: party When Healing, raid Never (every raid layout has its own key).
assert(p.party.tsMode=='whenHealing' and R.GetRaidLayout('10').tsMode=='never' and R.GetRaidLayout('40').tsMode=='never')
assert(p.party.tsSize==20 and p.party.tsMax==3 and p.party.tsPreview==true and p.party.tsSwipe==true)
-- Disabled: no spell events, no OnUpdate and no cast queries.
units.player.role='DAMAGER'
for i=1,3 do units['raid'..i]={name='Raider '..i,guid='R'..i,group=1,class='PRIEST',health=100,maxHealth=100,power=100,maxPower=100} end
mobs.M1={name='Cultist',guid='M1',hostile=true,health=100,maxHealth=100}
units.raid1.target='M1'; mobs.M1.target='R2'
mobs.M1.cast={name='Shadow Bolt',icon='bolt-icon',start=now*1000,finish=now*1000+3000,id=7}
raidCount=3; R.Apply(); TickHeaders(); event:RunScript('OnEvent','RAID_ROSTER_UPDATE')
assert(R.activeRaidLayout=='10' and Find('raid2'),'raid2 frame')
assert(not TS.active and driver:GetScript('OnUpdate')==nil and not driver.events.UNIT_SPELLCAST_START and driver.events.RAID_ROSTER_UPDATE)
castCalls=0; event:RunScript('OnUpdate',.3); R.UpdateAll(false); Fire('PLAYER_TARGET_CHANGED')
assert(castCalls==0 and Icons(Find('raid2'))==0,'Disabled Targeted Spells still scanned')
-- Raid gets its own selectable mode.
R.GetSettings('raid').tsMode='always'; R.Apply()
assert(TS.active and driver:GetScript('OnUpdate') and driver.events.UNIT_SPELLCAST_START and driver.events.UNIT_SPELLCAST_CHANNEL_STOP)
local hasRaidToken=false; for _,t in ipairs(TS.tokens) do if t=='raid3target' then hasRaidToken=true end end; assert(hasRaidToken)
-- raid1target casts at raid2: the throttled scan finds it (raidNtarget fires no events).
Tick()
local b2,b3=Find('raid2'),Find('raid3')
assert(Icons(b2)==1 and Icons(b3)==0,'icon on the victim frame')
local f=b2.tsIcons[1]
assert(f.icon:GetTexture()=='bolt-icon' and f.cooldown.start==now and f.cooldown.duration==3 and f:GetWidth()==20,'icon texture and sweep')
assert(f.borderColor[1]==1 and f.borderColor[2]==.3,'interruptible color')
-- The same caster through several tokens is one cast.
units.raid3.target='M1'; units.player.target='M1'
Tick(); Fire('UNIT_SPELLCAST_START','target')
assert(Count(TS.casts)==1 and Icons(b2)==1,'deduped by GUID')
-- Target swap moves the icon (UNIT_TARGET on the event-driven caster).
mobs.M1.target='R3'; Fire('UNIT_TARGET','target')
assert(Icons(b2)==0 and Icons(b3)==1,'target swap moves the icon')
-- A member retargeting onto a casting enemy (UNIT_TARGET raidN) is read at once.
mobs.M1.target='R2'; units.raid1.target=nil; units.raid3.target=nil; units.player.target=nil
Tick(); assert(Count(TS.casts)==1,'out-of-reach cast kept until its end')
units.raid1.target='M1'; Fire('UNIT_TARGET','raid1'); assert(Icons(b2)==1 and Icons(b3)==0)
-- Stop clears.
units.player.target='M1'; mobs.M1.cast=nil; Fire('UNIT_SPELLCAST_STOP','target')
assert(Count(TS.casts)==0 and Icons(b2)==0,'stop clears')
-- Interrupted clears even if the API still reports the cast for a moment, and the
-- scan does not bring that cast back.
now=now+.1; mobs.M1.cast={name='Hex',icon='hex-icon',start=now*1000,finish=now*1000+2000,id=8,notInt=true}
Fire('UNIT_SPELLCAST_START','target'); assert(Icons(b2)==1 and b2.tsIcons[1].borderColor[1]==.6,'uninterruptible color')
Fire('UNIT_SPELLCAST_INTERRUPTED','target'); assert(Icons(b2)==0)
Tick(); assert(Icons(b2)==0,'interrupted cast came back')
mobs.M1.cast=nil; Tick(); now=now+.1
-- Channels, sorting by end time and the icon cap.
mobs.M2={name='Caster two',guid='M2',hostile=true,target='R2',channel={name='Mind Flay',icon='flay-icon',start=now*1000,finish=now*1000+1500}}
mobs.M3={name='Caster three',guid='M3',hostile=true,target='R2',cast={name='Frostbolt',icon='frost-icon',start=now*1000,finish=now*1000+2500}}
units.raid2.target='M2'; units.raid3.target='M3'; mobs.M1.cast={name='Shadow Bolt',icon='bolt-icon',start=now*1000,finish=now*1000+3000}
Tick(); assert(Icons(b2)==3 and b2.tsIcons[1].icon:GetTexture()=='flay-icon' and b2.tsIcons[3].icon:GetTexture()=='bolt-icon')
R.GetSettings('raid').tsMax=2; R.Apply(); Tick(); assert(Icons(b2)==2)
-- Centred row: top position grows right around the middle.
R.GetSettings('raid').tsPosition='top'; R.GetSettings('raid').tsGrowth='right'; R.Apply(); Tick()
assert(select(1,b2.tsIcons[1]:GetPoint(1))=='TOP' and select(4,b2.tsIcons[1]:GetPoint(1))==-11 and select(4,b2.tsIcons[2]:GetPoint(1))==11)
-- Cast timer and swipe toggles.
R.GetSettings('raid').tsTimer=true; R.GetSettings('raid').tsSwipe=false; R.Apply(); Tick()
assert(b2.tsIcons[1].time:GetText()=='1.5' and not b2.tsIcons[1].cooldown:IsShown())
-- Enemies that are not hostile, and victims outside the group, show nothing.
mobs.M2.hostile=false; mobs.M3.target='X9'; Tick(); assert(Icons(b2)==1 and TS.casts.M3 and not TS.casts.M2)
-- Out of reach: kept until its end time, then dropped.
units.raid1.target=nil; units.raid2.target=nil; units.raid3.target=nil; units.player.target=nil
Tick(); assert(TS.casts.M1); now=now+3.3; Tick(); assert(Count(TS.casts)==0 and Icons(b2)==0,'expired casts not dropped')
-- Options: the raid mode is selectable and Never stops scanning.
local cfg=modules.EllesmereUIRaidFrames
rows={}; cfg.buildPage('Raid',UIParent,0)
local mode=FindRow('Show Targeted Spells'); assert(mode.values.whenHealing and mode.order[3]=='always' and mode.getValue()=='always')
assert(FindRow('Targeted Spell Size') and FindRow('Icon Position') and FindRow('Targeted Spells Offset X') and FindRow('Show targeted spells on preview') and FindRow('Maximum Icons'))
FindRow('Targeted Spell Size').setValue(24); assert(R.GetSettings('raid').tsSize==24 and R.GetRaidLayout('25').tsSize==20)
mode.setValue('never'); assert(not TS.active and driver:GetScript('OnUpdate')==nil and not driver.events.UNIT_SPELLCAST_START and FindRow('Targeted Spell Size').disabled())
units.raid1.target='M1'; mobs.M1.target='R2'; mobs.M1.cast={name='Shadow Bolt',icon='bolt-icon',start=now*1000,finish=now*1000+3000}
castCalls=0; event:RunScript('OnUpdate',.3); R.UpdateAll(false); assert(castCalls==0 and Icons(b2)==0)
-- When Healing follows the player's role (then healing talents).
mode.setValue('whenHealing'); assert(not TS.active)
units.player.role='HEALER'; Fire('PLAYER_TALENT_UPDATE'); assert(TS.active)
Tick(); assert(Icons(b2)==1)
-- Leaving the group stops everything and hides icons.
raidCount=0; TickHeaders(); Fire('RAID_ROSTER_UPDATE'); assert(not TS.active and Icons(b2)==0)
-- Preview: fake casts on the preview frames, gated by the preview toggle.
R.GetRaidLayout('10').tsMode='always'; R.SetPreview(true)
local pv=R.previews.raid[2]; assert(R.previewHolders.raid:IsShown() and pv:IsShown() and Icons(pv)>=1,'preview icons')
assert(Icons(R.previews.raid[1])==0)
R.GetRaidLayout('10').tsPreview=false; R.Apply(); assert(Icons(pv)==0)
R.GetRaidLayout('10').tsPreview=true; R.GetRaidLayout('10').tsMode='never'; R.Apply(); assert(Icons(pv)==0)
R.SetPreview(false)
-- Party has its own key.
partyCount=2; units.party1={name='Pally',guid='Q1',class='PALADIN',health=100,maxHealth=100}; units.party2={name='Tank',guid='Q2',class='WARRIOR',health=100,maxHealth=100,target='M1'}
mobs.M1.target='Q1'; R.Apply(); TickHeaders(); event:RunScript('OnEvent','PARTY_MEMBERS_CHANGED')
assert(TS.active and TS.tokens[#TS.tokens]=='party2target'); Tick(); assert(Icons(Find('party1'))==1,'party frame icon')
p.party.tsMode='never'; R.Apply(); assert(not TS.active and Icons(Find('party1'))==0)
''')
print('PASS: Raid Frames Targeted Spells: per-group modes (party When Healing, raid selectable), throttled raidNtarget scan plus event tokens, GUID dedupe, victim from the caster target with swaps, stop/interrupt clearing, out-of-reach expiry, channel/cap/sort, layout, timer/swipe/interrupt colors, preview gating, options rows, and no scanning when off.')
