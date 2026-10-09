"""Central raid debuffs are excluded before the regular indicator slots fill."""
from validate_raidframes import lua
lua.execute(r'''
combat=false
local b=R.headers.party[1].nativeButtons[2]; b:SetAttribute('unit','party1'); b._euiKind='party'; b._euiPreview=nil
local c=R.GetSettings('party'); c.raidDebuffs=true; c.raidDebuffDispellable=true; c.showDebuffs=true; c.onlyDispellable=false; c.hideLustDebuff=false
units.party1={name='Debuff Test',guid='DEDUP',class='PRIEST',health=100,maxHealth=100,power=50,maxPower=100,debuffs={
 {name='Other',id=99990,duration=20,expires=now+20,removable=false},
 {name='Curse',id=172,dispel='Curse',duration=20,expires=now+20},
 {name='Frost Beacon',id=70126,duration=20,expires=now+20,removable=false}}}
local function check(id)
 R.UpdateFrame(b,true); assert(b.raidDebuff:IsShown() and b.raidDebuff.spellID==id)
 for _,a in ipairs(b.debuffs) do assert(not a:IsShown() or a.spellID~=id,'Duplicate central debuff') end
end
combat=true; check(70126)
local other=false; for _,a in ipairs(b.debuffs) do if a:IsShown() and a.spellID==99990 then other=true end end; assert(other,'Other debuff lost')
table.remove(units.party1.debuffs,3); check(172)
c.onlyDispellable=true; check(172); assert(not b.debuffs[1]:IsShown(),'RAID-filter index differs from HARMFUL index')
c.raidDebuffs=false; R.UpdateFrame(b,true); assert(not b.raidDebuff:IsShown() and b.debuffs[1]:IsShown() and b.debuffs[1].spellID==172)
c.raidDebuffs=true; c.raidDebuffDispellable=false; R.UpdateFrame(b,true); assert(not b.raidDebuff:IsShown() and b.debuffs[1]:IsShown())
c.raidDebuffDispellable=true; units.party1.debuffs={}; R.UpdateFrame(b,true); assert(not b.raidDebuff:IsShown() and not b.debuffs[1]:IsShown())
combat=false
''')
print('PASS: boss and dispellable highlights excluded from regular bar, filter index mismatch, remaining debuffs, disabling highlight/fallback, removal and combat updates')
