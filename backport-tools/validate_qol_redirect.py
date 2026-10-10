"""QoL Misdirection / Tricks of the Trade helper: secure macro order, tank pick,
combat deferral, display text and TOC / binding wiring."""
from pathlib import Path
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

toc = [l.strip() for l in (root / 'EllesmereUIQoL/EllesmereUIQoL.toc').read_text(encoding='utf-8').splitlines()]
assert toc.index('EUI_QoL_335_Redirect.lua') > toc.index('EUI_QoL_335_Displays.lua')
assert 'CLICK EUI335QoLRedirect:LeftButton' in (root / 'EllesmereUIQoL/Bindings.xml').read_text(encoding='utf-8')
source = (root / 'EllesmereUIQoL/EUI_QoL_335_Redirect.lua').read_text(encoding='utf-8')
for banned in ('CastSpellByName', 'TargetUnit', 'FocusUnit', 'RunMacroText'):
    assert banned not in source, banned

lua = LuaRuntime(unpack_returned_tuples=True)
for rel in ['backport-tools/wrath_mock.lua', 'backport-tools/inventory_resources_mock.lua', 'backport-tools/qol_mock.lua', 'EllesmereUI/EllesmereUI_Lite.lua']:
    lua.execute((root / rel).read_text(encoding='utf-8-sig'))
lua.execute(r'''
playerClass='HUNTER'; function UnitClass(u) if u=='player' then return 'Hunter','HUNTER' end; local x=unitClasses and unitClasses[u]; return x,x end
raid={}; roles={}; friendly={}; deadUnits={}; buffs={}; spellCD={0,0}; combat=false
function InCombatLockdown() return combat end
function GetNumRaidMembers() return #raid end
function GetNumPartyMembers() return partyCount or 0 end
function GetRaidRosterInfo(i) local r=raid[i]; if r then return r.name,0,1,80,'Warrior','WARRIOR','',true,false,r.role end end
function UnitGroupRolesAssigned(u) return roles[u]==true end
local baseName=UnitName
function UnitName(u) if names and names[u] then return names[u] end; local i=tonumber(tostring(u):match('^raid(%d+)$')); if i and raid[i] then return raid[i].name end
    for _,r in ipairs(raid) do if u==r.name then return r.name end end; return baseName and baseName(u) end
function UnitExists(u) return friendly[u]~=nil or (names and names[u]~=nil) end
function UnitCanAssist(_,u) return friendly[u]==true end
function UnitIsDeadOrGhost(u) return deadUnits[u]==true end
function UnitIsDead(u) return deadUnits[u]==true end
function UnitIsUnit(a,b) return a==b end
function UnitBuff(_,name) local b=buffs[name]; if b then return name,nil,nil,0,nil,30,b end end
function GetSpellCooldown() return spellCD[1],spellCD[2] end
function IsSpellKnown(id) return id==34477 end
''')
ns = lua.table()
for name in ['EUI_QoL_335.lua', 'EUI_QoL_335_Displays.lua', 'EUI_QoL_335_Redirect.lua']:
    lua.execute((root / 'EllesmereUIQoL' / name).read_text(encoding='utf-8-sig'), 'EllesmereUIQoL', ns)
lua.globals().Q = ns
core = (root / 'EllesmereUI/EllesmereUI_Lite.lua').read_text(encoding='utf-8-sig')
safe = lua.execute('local function errorhandler(' + core.split('local function errorhandler(', 1)[1].split('\n-------------------------------------------------------------------------------', 1)[0] + '\nreturn safecall')
safe(ns.addon.OnInitialize, ns.addon)
safe(ns.addon.OnEnable, ns.addon)
lua.execute(r'''
local p=Q.GetSettings(); local r=p.redirect
local b0=Q.redirectButton
assert(r and r.enabled==false and r.useFocus and r.tankName=='','defaults')
assert(b0 and not b0:IsShown() and b0:GetAttribute('macrotext')==nil,'helper must start hidden with no macro')
assert(Q.RedirectMacro('Misdirection','Tanky',true,true)=='/cast [target=focus,help,nodead] Misdirection; [target=Tanky,help,nodead] Misdirection; [help,nodead] Misdirection; [target=pet,exists,nodead] Misdirection')
assert(Q.RedirectMacro('Tricks of the Trade',nil,false,false)=='/cast [help,nodead] Tricks of the Trade')

raid={{name='Healz'},{name='Tanky',role='MAINTANK'},{name='Other'}}
r.enabled=true; Q.Apply()
local b=Q.redirectButton
assert(b and b:IsShown() and b:GetAttribute('type')=='macro' and b.tank=='Tanky','raid Main Tank')
assert(b:GetAttribute('macrotext'):find('[target=Tanky,help,nodead]',1,true) and b:GetAttribute('macrotext'):find('[target=pet,exists,nodead]',1,true))
r.tankName='  healz '; Q.Apply(); assert(b.tank=='Healz','typed tank name wins, case-insensitive')
r.tankName='Nobody'; Q.Apply(); assert(b.tank=='Tanky','absent typed name falls back')
r.tankName=''; raid={}; partyCount=2; names={party1='Lfgtank',party2='Dps'}; roles={party1=true}; Q.Apply()
assert(b.tank=='Lfgtank','Dungeon Finder tank role')
r.useFocus=false; Q.Apply(); assert(not b:GetAttribute('macrotext'):find('focus',1,true)); r.useFocus=true

combat=true; names.party1=nil; roles={party2=true}; names.party2='Newtank'
Q.redirectEvents:RunScript('OnEvent','PARTY_MEMBERS_CHANGED')
assert(b.tank=='Lfgtank','tank changed in combat')
combat=false; Q.redirectEvents:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); assert(b.tank=='Newtank','deferred update after combat')

friendly={Newtank=true}; Q.UpdateRedirect(); assert(b.name:GetText()=='Newtank','shows the tank')
friendly.focus=true; names.focus='Focusguy'; Q.UpdateRedirect(); assert(b.name:GetText()=='Focusguy','focus first')
deadUnits.focus=true; Q.UpdateRedirect(); assert(b.name:GetText()=='Newtank','dead focus skipped')
friendly={}; Q.UpdateRedirect(); assert(b.name:GetText()=='No target')
buffs[b.spell]=GetTime()+12.4; Q.UpdateRedirect(); assert(b.timer:GetText()=='12','buff timer')
buffs={}; Q.UpdateRedirect(); assert(b.timer:GetText()=='')

r.enabled=false; Q.Apply(); assert(not b:IsShown() and b:GetAttribute('macrotext')==nil)
''')
print('PASS: helper starts off; macro order focus > tank > friendly target > pet; typed/Main Tank/role tank pick with fallback; combat-deferred updates; live target name, buff timer; disable clears the macro')
