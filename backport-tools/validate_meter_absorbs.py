"""Consumed shields contribute to caster healing without inventing an owner."""
from validate_damagemeters import lua
lua.execute(r'''
local p=D.Profile(); p.enabled=true; fighting=false; combat=false
D.Finish(); assert(D.Reset()); D.RefreshRoster(); now=100
local function event(kind,sg,dg,...)
 D.Parse(now,kind,sg,sg=='H' and 'Healer' or sg=='P' and 'Player' or sg,sg=='BOSS' and 0 or 1,
 dg,dg=='P' and 'Player' or dg,dg=='BOSS' and 0 or 1,...)
end
local function aura(kind,sg,id,name) event(kind,sg,'P',id,name,2,'BUFF') end
local function hit(amount) event('SPELL_DAMAGE','BOSS','P',500,'Boss Spell',4,70,0,4,0,0,amount,false) end
-- Cast before combat: capacity is never credited on application.
aura('SPELL_AURA_APPLIED','H',48066,'Power Word: Shield')
assert(not D.current)
hit(200)
assert(D.current.actors.H.values.healing==200 and D.current.actors.H.values.shielding==200)
assert(D.current.actors.P.values.absorbed==200 and not D.current.actors.P.values.healing)
assert(D.current.actors.H.spells.healing[48066].total==200)
assert(D.current.actors.H.targets.healing.P.total==200)
event('SWING_MISSED','BOSS','P','ABSORB',300)
assert(D.current.actors.H.values.healing==500 and D.current.actors.P.values.absorbed==500)
event('SPELL_HEAL','H','P',2061,'Flash Heal',2,150,50,0,false)
assert(D.current.actors.H.values.healing==600 and D.current.actors.H.values.overheal==50)
local rows=D.Rows('current','hps'); assert(rows[1].amount==600 and rows[1].value>0)
rows=D.Rows('current','shielding'); assert(rows[1].amount==500)
-- Refresh moves the expiry; removal ends attribution immediately.
now=125; aura('SPELL_AURA_REFRESH','H',48066,'Power Word: Shield')
now=140; hit(50); assert(D.current.actors.H.values.shielding==550)
aura('SPELL_AURA_REMOVED','H',48066,'Power Word: Shield'); hit(50)
assert(D.current.actors.H.values.shielding==550)
-- Same caster with two shields can be credited, but spell splitting is unknown.
aura('SPELL_AURA_APPLIED','H',48066,'Power Word: Shield')
aura('SPELL_AURA_APPLIED','H',47753,'Divine Aegis')
event('SPELL_AURA_APPLIED_DOSE','H','P',47753,'Divine Aegis',2,'BUFF',3)
hit(100)
assert(D.current.actors.H.spells.shielding[-3].total==100)
-- Different shield owners: keep the recipient's absorb but assign no healing.
aura('SPELL_AURA_APPLIED','P',58597,'Sacred Shield')
local before=D.current.actors.H.values.healing
hit(100); assert(D.current.actors.H.values.healing==before and not D.current.actors.P.values.healing)
aura('SPELL_AURA_REMOVED','P',58597,'Sacred Shield')
-- Aura breaks from another source must clear the shield.
aura('SPELL_AURA_REMOVED','H',47753,'Divine Aegis')
event('SPELL_AURA_BROKEN','BOSS','P',48066,'Power Word: Shield',2,'BUFF')
hit(20); assert(D.current.actors.H.values.healing==before)
-- Unknown caster blocks credit; later explicit ownership reconciles it.
D.ClearShields()
D.TrackShield('SPELL_AURA_APPLIED',nil,nil,nil,'P','Player',1,48066,'Power Word: Shield',2,'BUFF')
hit(30); assert(D.current.actors.H.values.healing==before)
aura('SPELL_AURA_APPLIED','H',48066,'Power Word: Shield'); hit(30)
assert(D.current.actors.H.values.healing==before+30)
-- Expired buffs and deaths never leave phantom healing.
now=200; hit(30); assert(D.current.actors.H.values.healing==before+30)
aura('SPELL_AURA_APPLIED','H',48066,'Power Word: Shield')
event('UNIT_DIED',nil,'P'); hit(30); assert(D.current.actors.H.values.healing==before+30)
-- A permanent Sacred Shield buff is not its six-second absorb proc.
aura('SPELL_AURA_APPLIED','H',53601,'Sacred Shield'); hit(30)
assert(D.current.actors.H.values.healing==before+30)
-- Fire Ward applies only to fire; Frost damage remains with Power Word: Shield.
aura('SPELL_AURA_APPLIED','H',48066,'Power Word: Shield')
aura('SPELL_AURA_APPLIED','P',43010,'Fire Ward')
event('SPELL_DAMAGE','BOSS','P',501,'Frostbolt',16,70,0,16,0,0,40,false)
assert(D.current.actors.H.values.healing==before+70)
-- Pre-combat UnitAura seeding identifies the shield caster.
D.Finish(); assert(D.Reset()); now=300
function UnitAura(unit,index,filter)
 if unit=='player' and index==1 then return 'Power Word: Shield','',nil,1,nil,30,330,'party1',false,false,48066 end
end
hit(90); assert(D.current.actors.H.values.healing==90)
D.Finish(); assert(D.history.overall.actors.H.values.healing==90)
assert(D.Reset())
function UnitAura() end
-- A fully absorbed attack can start its own combat segment.
aura('SPELL_AURA_APPLIED','H',48066,'Power Word: Shield')
event('SWING_MISSED','BOSS','P','ABSORB',75)
assert(D.current and D.current.actors.H.values.healing==75)
event('SWING_MISSED','BOSS','P','ABSORB',nil)
assert(D.current.actors.H.values.healing==75)
''')
print('PASS: shields in healing/HPS, caster/spell/target breakdowns, partial and full absorbs, precombat casts/seeding, refresh/removal/break/expiry/death/reset, conflicting/unknown owners and school restrictions')