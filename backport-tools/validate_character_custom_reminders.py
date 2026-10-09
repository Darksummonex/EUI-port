"""Independent Lua sessions prove per-character saved state and legacy migration."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
src=(root/'EllesmereUIAuraBuffReminders/EUI_AuraBuffReminders_335.lua').read_text()
getter='function EABR.GetCustomSettings()'+src.split('function EABR.GetCustomSettings()',1)[1].split('function EABR.CollectCustom',1)[0]
toc=(root/'EllesmereUIAuraBuffReminders/EllesmereUIAuraBuffReminders.toc').read_text()
assert '## SavedVariablesPerCharacter: EllesmereUIAuraBuffRemindersCharDB' in toc
base=r'''
EABR={}
local function P() return profile end
function Serialize(v)
 if type(v)=='table' then local t={'{'}; for k,x in pairs(v) do t[#t+1]='['..Serialize(k)..']='..Serialize(x)..',' end; t[#t+1]='}'; return table.concat(t) end
 if type(v)=='string' then return string.format('%q',v) end
 return tostring(v)
end
'''
def session(profile, char=None):
 lua=LuaRuntime(); lua.execute(base+getter)
 lua.execute('profile='+profile)
 if char: lua.execute('EllesmereUIAuraBuffRemindersCharDB='+char)
 return lua
first=session('{custom={customIDs={700,700,701},whereToShow={in_combat=false},sectionSound="airhorn"}}')
first.execute('''
local c=EABR.GetCustomSettings()
assert(#c.customIDs==2 and c.customIDs[1]==700 and c.customIDs[2]==701)
assert(c.whereToShow.in_combat==false and c.sectionSound=='airhorn')
assert(#profile.custom.customIDs==0)
c.customIDs[#c.customIDs+1]=702; c.sectionSound='bell'
assert(EABR.GetCustomSettings()==c and #c.customIDs==3)
''')
shared=first.eval('Serialize(profile)'); char=first.eval('Serialize(EllesmereUIAuraBuffRemindersCharDB)')
second=session(shared)
second.execute('''
local c=EABR.GetCustomSettings(); assert(#c.customIDs==0)
c.customIDs[1]=800; c.whereToShow.in_combat=true; c.sectionSound='other'
assert(#profile.custom.customIDs==0)
''')
restored=session(shared,char)
restored.execute('''
local c=EABR.GetCustomSettings()
assert(#c.customIDs==3 and c.customIDs[1]==700 and c.customIDs[3]==702)
assert(c.sectionSound=='bell' and c.whereToShow.in_combat==false)
-- Shared profile switches neither discard nor replace character settings.
profile={custom={customIDs={},whereToShow={in_combat=true},sectionSound='different'}}
assert(EABR.GetCustomSettings()==c and #c.customIDs==3 and c.sectionSound=='bell')
-- A legacy profile activated mid-session migrates exactly once and dedupes.
profile={custom={customIDs={700,900},whereToShow={}},customReminders={{spellID=901},{spellID=902,enabled=false}}}
assert(EABR.GetCustomSettings()==c and #c.customIDs==5 and c.customIDs[4]==900 and c.customIDs[5]==901)
assert(#profile.custom.customIDs==0 and profile.customReminders==nil)
assert(#EABR.GetCustomSettings().customIDs==5)
table.remove(c.customIDs,1); assert(#EABR.GetCustomSettings().customIDs==4)
''')
# Re-run real lifecycle/options add/remove storage paths in the existing harness.
import validate_aurabuffreminders
print('PASS: character SavedVariables ownership; independent character sessions; serialization/relogin; profile switches; one-time legacy migration/deduplication; settings and list isolation')