"""Execute the real General combat-text callbacks against strict client CVars."""
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

general = (root / 'EllesmereUIOptions/EUI__General_Options.lua').read_text(encoding='utf-8-sig')
helpers = '-- Stock Wrath names differ' + general.split('-- Stock Wrath names differ', 1)[1].split('--- Returns current, default', 1)[0]
rows = 'local showDmgRow' + general.split('local showDmgRow', 1)[1].split('-- Swiftmend Brightness Fix', 1)[0]

for wrath in (True, False):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.globals().EUI_WOW_335 = wrath
    lua.execute('''
local names = EUI_WOW_335 and {
 "CombatDamage", "CombatHealing", "CombatLogPeriodicSpells", "PetMeleeDamage", "PetSpellDamage"
} or {
 "floatingCombatTextCombatDamage_v2", "floatingCombatTextCombatHealing_v2",
 "floatingCombatTextCombatLogPeriodicSpells_v2", "floatingCombatTextPetMeleeDamage_v2",
 "floatingCombatTextPetSpellDamage_v2"
}
values={}; writes={}; combat=false; refreshes=0
for _,key in ipairs(names) do values[key]="0" end
values[names[2]]="1"
GetCVar=function(key) assert(values[key]~=nil,"unknown client CVar: "..key); return values[key] end
SetCVar=function(key,value)
 assert(values[key]~=nil,"unknown client CVar: "..key)
 writes[#writes+1]={key,value}; values[key]=value
end
InCombatLockdown=function() return combat end
EllesmereUI={RefreshPage=function() refreshes=refreshes+1 end,
 BuildInlineCog=function(parent,opts) cog=opts end}
local W={DualRow=function(self,parent,y,left,right)
 damage=left; healing=right; return {_leftRegion={}},50
end}
local parent,y,h={},0,0
''' + helpers + rows + '''
assert(not damage.getValue() and healing.getValue())
assert(cog.disabled())
damage.setValue(true)
assert(values[names[1]]=="1" and values[names[2]]=="1" and refreshes==1)
assert(damage.getValue() and not cog.disabled())
healing.setValue(false)
assert(not healing.getValue() and damage.getValue())
for i,row in ipairs(cog.rows) do
 assert(not row.get())
 row.set(true); assert(row.get() and values[names[i+2]]=="1")
 row.set(false); assert(not row.get() and values[names[i+2]]=="0")
end
damage.setValue(false); assert(not damage.getValue() and cog.disabled())
healing.setValue(true); assert(healing.getValue() and not damage.getValue())
assert(#writes==10)
-- Preserve the page's existing combat restriction and safe unknown-CVar behavior.
combat=true; damage.setValue(true); healing.setValue(false)
assert(#writes==10 and not damage.getValue() and healing.getValue())
combat=false
assert(SafeGetCVar("unsupportedSetting")==nil)
assert(not SetCVarSafe("unsupportedSetting","1"))
assert(#writes==10)
''')

print('PASS: General damage/healing and periodic/pet callbacks read/write native Wrath CVars; independent toggles, combat guard, unknown CVars and Retail names preserved.')
