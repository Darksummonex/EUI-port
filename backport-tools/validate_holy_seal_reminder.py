"""Holy Paladin requires Wisdom; other seal reminders remain spec-appropriate."""
from validate_aurabuffreminders import lua
lua.execute(r'''
D._class='PALADIN'; names[20166]='Seal of Wisdom'; names[21084]='Seal of Righteousness'
names[20375]='Seal of Command'; names[31801]='Seal of Vengeance'
book={'Seal of Wisdom','Seal of Righteousness','Seal of Command','Seal of Vengeance'}
D.ScanSpellbook(); auras={}; mounted=false; fighting=false; resting=false
local p=D.db.profile; p.auras.whereToShow={}; p.display.showUnder=2
p.auras.enabled.seal_wisdom=true; p.auras.enabled.seal=true
local function collect()
 D._entryUsed=0; local list={}; D.CollectAuras(list,true); local keys={}
 for _,entry in ipairs(list) do keys[entry.key]=entry end; return keys
end
talentPoints={51,0,0}
local keys=collect(); assert(keys.seal_wisdom and keys.seal_wisdom.spellID==20166 and not keys.seal)
assert(keys.seal_wisdom.mode=='spell')
auras.player={{name='Seal of Righteousness',duration=1800,expires=now+1800,caster='player'}}
assert(collect().seal_wisdom,'wrong seal must not suppress Wisdom reminder')
auras.player={{name='Seal of Wisdom',duration=1800,expires=now+1800,caster='player'}}
assert(not collect().seal_wisdom)
auras.player[1].expires=now+30; assert(collect().seal_wisdom,'near expiry obeys duration threshold')
auras.player={}; p.auras.enabled.seal_wisdom=false; assert(not collect().seal_wisdom)
p.auras.enabled.seal_wisdom=true
book={'Seal of Righteousness'}; D.ScanSpellbook(); assert(not collect().seal_wisdom,'unknown Wisdom spell')
book={'Seal of Wisdom','Seal of Righteousness','Seal of Command','Seal of Vengeance'}; D.ScanSpellbook()
for _,tab in ipairs({2,3}) do
 talentPoints={0,0,0}; talentPoints[tab]=51
 local keys=collect(); assert(not keys.seal_wisdom and keys.seal)
 assert(keys.seal.spellID==(tab==2 and 31801 or 20375))
 auras.player={{name='Seal of Wisdom',duration=1800,expires=now+1800,caster='player'}}
 assert(not collect().seal); auras.player={}
end
talentPoints={0,0,0}; assert(collect().seal and not collect().seal_wisdom)
D._class='PRIEST'; talentPoints={51,0,0}; assert(not collect().seal_wisdom)
''')
print('PASS: Holy Wisdom reminder, correct click spell, missing/wrong/active/expiring seal, toggle, spell knowledge, spec switches and pre-talent/other-class behavior')