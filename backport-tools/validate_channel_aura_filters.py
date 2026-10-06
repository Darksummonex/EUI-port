"""Real Lua 5.1 channel layout, GUID combat-log tracking and filter page contracts."""
from pathlib import Path
import sys
from game_paths import ADDONS, DATA, WTF

root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

lua = LuaRuntime(unpack_returned_tuples=True)
def execute(path):
    return lua.execute((root / path).read_text(encoding='utf-8-sig'))

execute('backport-tools/wrath_mock.lua')
execute('backport-tools/nameplates_mock.lua')
lua.globals().bit = lua.table_from({'band': lambda a, b: int(a) & int(b)})
lua.execute('''
strmatch=string.match; strfind=string.find; strsub=string.sub; tinsert=table.insert; tremove=table.remove; next=next
COMBATLOG_OBJECT_TYPE_PLAYER=1024
function GetSpellInfo(id) return id==689 and 'Drain Life' or id==47540 and 'Penance' or tostring(id),nil,'spell-icon' end
function GetSpellTexture(id) return 'spell-'..id end
function EllesmereUI:RefreshPage() refreshed=true end
buttons={}
function EllesmereUI.Widgets:WideButton(_,label,_,fn) buttons[label]=fn; return {},40 end
-- Full stock Wrath UnitAura tuple, with spell ID in position eleven.
function UnitAura(u,i,filter)
    local t=units[u]; local a=t and t.auras and t.auras[filter]; a=a and a[i]
    if a then return a.name,'Rank 1',a.icon or 'debuff-icon',a.stacks or 1,a.kind or 'Magic',a.duration or 10,a.expires or 12,a.caster,a.stealable,false,a.id or 172 end
end
units.player={name='Player',guid='0x0000000000000001',player=true,class='WARLOCK'}
units.pet={name='Pet',guid='0xF140000001000001'}
''')
execute('EllesmereUI/Libs/LibStub/LibStub.lua')
execute('EllesmereUI/Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua')
execute('EllesmereUI/EllesmereUI_Lite.lua')
execute('EllesmereUI/EUI_ChannelTicks_335.lua')
execute('EllesmereUI/EUI_AuraFilters_335.lua')
execute('EllesmereUIOptions/EUI_AuraFilters_335_Options.lua')

lua.execute('''
local T=EllesmereUI.WrathChannelTicks
local bar=CreateFrame('StatusBar'); bar:SetWidth(200); bar:SetHeight(20)
local schedule=T.Schedule('Drain Life',1,6)
T.Draw(bar,schedule,1,6,true)
assert(schedule.interval==1 and #bar._euiChannelTicks==4)
local first=bar._euiChannelTicks[1]
assert(first.point[4]==160 and first:GetWidth()==1 and first:GetHeight()==18)
bar:SetWidth(300); T.Draw(bar,schedule,1,6,true); assert(first.point[4]==240)
assert(T.Schedule('Drain Life',1,5,schedule,nil,true)==schedule)
T.Draw(bar,schedule,1,5,true)
assert(first.point[4]==225 and not bar._euiChannelTicks[4]:IsShown())
local haste=T.Schedule('Drain Life',10,12.5); assert(haste.interval==.5)
T.Draw(bar,T.Schedule('Penance',1,3),1,3,true)
assert(first:IsShown() and first.point[4]==150 and not bar._euiChannelTicks[2]:IsShown())
assert(T.Schedule('Unknown Spell',1,4)==nil)
T.Draw(bar,nil,1,4,true); assert(not first:IsShown())
T.Draw(bar,haste,10,12.5,false); assert(not first:IsShown())
local F=EllesmereUI.WrathAuraFilters
assert(F.Parse('12, garbage')==nil and F.Parse('-1')==nil and F.Parse('1.5')==nil)
assert(F.Format(F.Parse('172; 689, 172'))=='172, 689')
local s={debuffFilterMode='own',debuffInclude={[172]=true}}
assert(F.Allow(s,'debuff',172,false,10) and not F.Allow(s,'debuff',689,false,10))
s.debuffExclude={['172']=true}; assert(not F.Allow(s,'debuff',172,true,10))
s.debuffExclude={}; s.debuffIncludeMine={[172]=true}; assert(not F.Allow(s,'debuff',172,false,10))
s.debuffHasDuration=true; assert(not F.Allow(s,'debuff',172,true,0))
assert(F.Allow({buffFilterMode='all',buffStealable=true},'buff',17,false,10,true))
assert(not F.Allow({buffFilterMode='all',buffStealable=true},'buff',17,false,10,false))
''')

# The vendored library and its Wrath spell catalogue stay byte-for-byte intact.
source = ADDONS / 'ElvUI/Libraries/LibAuraInfo-1.0'
for file in source.iterdir():
    if file.is_file():
        assert file.read_bytes() == (root / 'EllesmereUINameplates/Libs/LibAuraInfo-1.0' / file.name).read_bytes()
execute('EllesmereUINameplates/Libs/LibAuraInfo-1.0/LibAuraInfo-1.0.lua')
execute('EllesmereUINameplates/Libs/LibAuraInfo-1.0/spellIdData.lua')
ns = lua.table()
for name in ('EUI_Nameplates_335.lua', 'EUI_Nameplates_335_Display.lua'):
    lua.eval('function(s) return assert(loadstring(s)) end')((root / 'EllesmereUINameplates' / name).read_text())('EllesmereUINameplates', ns)
lua.globals().NP = ns
ns.addon.OnInitialize(ns.addon)
ns.addon.OnEnable(ns.addon)

lua.execute('''
local lib=NP.auraLib; assert(lib and lib.frame.events.COMBAT_LOG_EVENT_UNFILTERED)
local a,b=NP.plates[plateA],NP.plates[plateB]; local p=NP.GetSettings()
function CombatAura(event,guid,name,id,source)
    lib.frame:RunScript('OnEvent','COMBAT_LOG_EVENT_UNFILTERED',now,event,source or '0x0000000000000001','Player',1024,guid,name,2048,id,'Aura '..id,32,'DEBUFF')
end
local otherGUID='0xF130000001000001'
local secondGUID='0xF130000001000002'
-- Combat-log names are not plate identities, even with one visible candidate.
CombatAura('SPELL_AURA_APPLIED',otherGUID,'Other',172)
NP.Update(); assert(not b.auraGUID and not b.auras[1]:IsShown(),'Unobserved nearby plate inherited a name-matched debuff')
units.mouseover={name='Other',guid=otherGUID,auras={HARMFUL={{name='Observed',id=172,caster='player',duration=12,expires=14}}}}
b.native.highlight:Show(); NP.Update()
assert(b.auraGUID==otherGUID and b.auraVerified and b.auras[1]:IsShown())
units.mouseover=nil; b.native.highlight:Hide(); NP.Update()
assert(not b.unit and b.auraGUID==otherGUID and b.auras[1]:IsShown(),'Observed plate lost auras when mouseover ended')
CombatAura('SPELL_AURA_APPLIED_DOSE',otherGUID,'Other',172); NP.Update(); assert(b.auras[1].count:GetText()==2)
now=3; CombatAura('SPELL_AURA_REFRESH',otherGUID,'Other',172); NP.Update(); assert(tonumber(b.auras[1].time:GetText())==lib.spellDuration[172])
units.target={name='Mob',guid='0xF130000001000003',auras={HARMFUL={{name='Observed',id=172,caster='player'}}}}
lib.frame:RunScript('OnEvent','PLAYER_TARGET_CHANGED'); NP.Update(); assert(a.unit=='target' and a.auraVerified)
units.target=nil; NP.Update(); assert(not a.unit and a.auraGUID=='0xF130000001000003' and a.auras[1]:IsShown())
-- A late native observation learns an unknown spell without depending on the
-- library's target event firing after our plate has been registered.
units.target={name='Mob',guid='0xF130000001000003',auras={HARMFUL={{name='Late snapshot',id=99999,icon='late-icon',caster='player',duration=7,expires=10}}}}
NP.Apply(); assert(a.auras[1]:IsShown() and lib.spellDuration[99999]==7)
units.target=nil; NP.Update(); assert(a.auras[1]:IsShown() and a.auras[1].icon:GetTexture()=='late-icon','Live debuff lost after deselection without a lib event')
CombatAura('SPELL_AURA_REMOVED','0xF130000001000003','Mob',99999); NP.Update(); assert(not a.auras[1]:IsShown())
-- Nearby equal-name plate must stay empty, including after the affected plate
-- disappears, when the previous name shortcut had only one visible candidate.
local duplicate=NativePlate('Other',.5); NP.Apply()
assert(b.auras[1]:IsShown() and not NP.plates[duplicate].auraGUID and not NP.plates[duplicate].auras[1]:IsShown())
plateB:Hide(); NP.Update(); assert(not NP.plates[duplicate].auras[1]:IsShown())
duplicate:Hide(); plateB:Show(); NP.Update()
assert(not b.auraGUID and not b.auras[1]:IsShown(),'Recycled plate inherited the former occupant aura by name')
units.mouseover={name='Other',guid=otherGUID,auras={HARMFUL={{name='Observed',id=172,caster='player',duration=12,expires=15}}}}
b.native.highlight:Show(); lib.frame:RunScript('OnEvent','UPDATE_MOUSEOVER_UNIT'); NP.Update()
units.mouseover=nil; b.native.highlight:Hide(); NP.Update()
CombatAura('SPELL_AURA_APPLIED',secondGUID,'Other',172); duplicate:Show(); NP.Update()
assert(b.auraGUID==otherGUID and b.auras[1]:IsShown() and not NP.plates[duplicate].auras[1]:IsShown())
-- Once independently observed, another same-name unit keeps only its own aura.
units.mouseover={name='Other',guid=secondGUID,auras={HARMFUL={{name='Different',id=689,icon='different-icon',caster='player'}}}}
NP.plates[duplicate].native.highlight:Show(); lib.frame:RunScript('OnEvent','UPDATE_MOUSEOVER_UNIT'); NP.Update()
units.mouseover=nil; NP.plates[duplicate].native.highlight:Hide(); NP.Update()
assert(b.auras[1].icon:GetTexture()=='debuff-icon' and NP.plates[duplicate].auras[1].icon:GetTexture()=='different-icon')
CombatAura('SPELL_AURA_REMOVED',secondGUID,'Other',689); NP.Update()
assert(b.auras[1]:IsShown() and not NP.plates[duplicate].auras[1]:IsShown(),'Removing one unit aura changed its neighbor')
duplicate:Hide()
p.debuffExclude={[172]=true}; NP.Apply(); assert(not a.auras[1]:IsShown() and not b.auras[1]:IsShown())
p.debuffExclude={}; p.debuffFilterMode='tracked'; p.debuffInclude={[689]=true}; NP.Apply(); assert(not b.auras[1]:IsShown())
p.debuffInclude={[172]=true}; NP.Apply(); assert(b.auras[1]:IsShown())
p.debuffInclude={}; p.debuffFilterMode='own'; NP.Apply()
CombatAura('SPELL_AURA_REMOVED',otherGUID,'Other',172)
CombatAura('SPELL_AURA_APPLIED',otherGUID,'Other',172,'0x0000000000000002'); NP.Update(); assert(not b.auras[1]:IsShown())
CombatAura('SPELL_AURA_REMOVED',otherGUID,'Other',172,'0x0000000000000002')
CombatAura('SPELL_AURA_APPLIED',otherGUID,'Other',172,'0xF140000001000001'); NP.Update(); assert(b.auras[1]:IsShown())
CombatAura('SPELL_AURA_REMOVED',otherGUID,'Other',172,'0xF140000001000001'); NP.Update(); assert(not b.auras[1]:IsShown())
CombatAura('SPELL_AURA_APPLIED',otherGUID,'Other',172); now=25; NP.Update(); assert(not b.auras[1]:IsShown())
-- Native alpha can lag the mouseover highlight during a target transition.
now=3
local sameGUID='0xF130000001000003'
units.target={name='Mob',guid=sameGUID,auras={HARMFUL={{name='Observed',id=172,caster='player'}}}}
local peer=NativePlate('Mob',.5); NP.Apply(); lib.frame:RunScript('OnEvent','PLAYER_TARGET_CHANGED'); NP.Update()
assert(a.auraGUID==sameGUID and a.auras[1]:IsShown())
units.mouseover=units.target; NP.plates[peer].native.highlight:Show(); NP.Update()
assert(not a.auraGUID and not a.auras[1]:IsShown() and not a.unit)
assert(NP.plates[peer].auraGUID==sameGUID and NP.plates[peer].auras[1]:IsShown(),'One GUID rendered on two plates during target transition')
units.target=nil; units.mouseover=nil; NP.plates[peer].native.highlight:Hide(); NP.Update()
assert(not a.auras[1]:IsShown() and NP.plates[peer].auras[1]:IsShown())
peer:Hide()
-- A missing GUID is never authority to display a native aura on a plate.
plateA:Hide(); units.target={name='Mob',auras={HARMFUL={{name='Unknown GUID',id=172,caster='player'}}}}
plateA:Show(); NP.Update(); assert(not a.auraGUID and not a.auras[1]:IsShown())
plateA:Hide(); units.target={name='Mob',guid='0xF130000001000004'}; plateA:Show()
assert(a.auraGUID=='0xF130000001000004' and not a.auras[1]:IsShown())
units.target=nil
''')
execute('EllesmereUIOptions/EUI_Nameplates_335_Options.lua')
lua.execute('''
local function Find(label,n)
    n=n or 1
    for _,row in ipairs(rows) do for _,cfg in ipairs(row) do if cfg.text==label then n=n-1; if n==0 then return cfg end end end end
    error('Missing option '..label)
end
rows={}; assert(testModule.buildPage('Aura Filters',UIParent,0)>0)
local p=NP.GetSettings()
Find('Debuff Filter').setValue('tracked'); assert(p.debuffFilterMode=='tracked')
Find('Tracked Spell IDs',1).setValue('172,689'); assert(p.debuffInclude[172] and p.debuffInclude[689])
local list=p.debuffInclude; Find('Tracked Spell IDs',1).setValue('bad input'); assert(p.debuffInclude==list and rendererWarning)
Find('Excluded Spell IDs',1).setValue('172'); assert(p.debuffExclude[172])
Find('Buff Filter').setValue('own'); Find('Tracked Spell IDs',2).setValue('17'); assert(p.buffInclude[17])
Find('Only Stealable Buffs').setValue(true); assert(p.buffStealable)
buttons['Reset Selected Aura Filters'](); assert(p.debuffFilterMode=='all' and p.buffFilterMode=='all' and not next(p.debuffInclude))
-- Use the same actual page builder to check UnitFrames per-frame isolation.
local settings={player={},target={},focus={},boss1={}}
local UF={UF_GetSettings=function(unit) return settings[unit] end,UF_ReloadAllAuraContainers=function() ufReloaded=true end}
EllesmereUI._ModuleNS.EllesmereUIUnitFrames=UF
rows={}; assert(EllesmereUI.BuildWrathAuraFilters('EllesmereUIUnitFrames',UIParent,0)>0)
Find('Select Frame').setValue('target'); assert(UF.selectedWrathAuraUnit=='target' and refreshed)
Find('Tracked Spell IDs',1).setValue('172'); assert(settings.target.debuffInclude[172] and settings.player.debuffInclude==nil and ufReloaded)
Find('Select Frame').setValue('boss1'); Find('Debuff Filter').setValue('own')
assert(settings.boss1.debuffFilterMode=='own' and settings.target.debuffFilterMode==nil)
-- All UF frames can be disabled before the aura-container getter is exported.
UF.UF_GetSettings=nil; UF.db={profile={boss={}}}
Find('Tracked Spell IDs',1).setValue('172'); assert(UF.db.profile.boss.debuffInclude[172])
''')
print('PASS: channel pulse layout/haste/pushback/pooling, verified GUID plate auras/refresh/stacks/removal/expiry/pet ownership/nearby-name rejection/recycling/one-owner transitions, actual aura filter pages and UnitFrames per-frame isolation')



