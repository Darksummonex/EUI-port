"""Soulstone builtin and custom creation reminders are Warlock-only."""
from validate_aurabuffreminders import lua
lua.execute(r'''
names[693]='Create Soulstone'; names[20752]='Create Soulstone'; names[99998]='Other Reminder'
book={'Create Soulstone'}; D.ScanSpellbook(); auras={}; fighting=false; resting=false
D.db.profile.consumables.warlockWhereToShow={}
local custom=D.GetCustomSettings(); custom.customIDs={693,20752,99998}; custom.whereToShow={}
local def
for _,v in ipairs(D.AURAS) do if v.key=='soulstone' then def=v end end
assert(def)
for _,class in ipairs({'WARRIOR','PALADIN','HUNTER','ROGUE','PRIEST','DEATHKNIGHT','SHAMAN','MAGE','DRUID','WARLOCK'}) do
 D._class=class; D._entryUsed=0; local list={}; D.CollectCustom(list,true)
 assert(#list==(class=='WARLOCK' and 3 or 1),class)
 D._entryUsed=0; list={}; D.CollectSoulstone(list,def,true)
 assert(#list==(class=='WARLOCK' and 1 or 0),class)
end
''')
print('PASS: built-in and custom Create Soulstone reminders are Warlock-only across all ten classes; other custom reminders preserved')
