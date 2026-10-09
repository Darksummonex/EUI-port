"""Wrath single-return and modern range checks update alpha safely in combat."""
from validate_raidframes import lua
lua.execute(r'''
combat=false
local b=R.headers.party[1].nativeButtons[2]
b:SetAttribute('unit','party1'); b._euiKind='party'; b._euiPreview=nil
units.party1={name='Range Test',guid='RANGE',class='PRIEST',health=100,maxHealth=100,power=50,maxPower=100,connected=true}
local c=R.GetSettings('party'); c.rangeFade=true; c.outOfRangeAlpha=.4
local native=UnitInRange; local result=1; local checked=nil
UnitInRange=function() return result,checked end
combat=true
for _,v in ipairs({false,0}) do result=v; R.UpdateFrame(b,false); assert(b:GetAlpha()==.4) end
result=nil; R.UpdateFrame(b,false); assert(b:GetAlpha()==.4,'Wrath nil range')
result=1; R.UpdateFrame(b,false); assert(b:GetAlpha()==1)
result=true; R.UpdateFrame(b,false); assert(b:GetAlpha()==1)
result=false; checked=false; R.UpdateFrame(b,false); assert(b:GetAlpha()==1,'explicit unchecked result')
checked=true; R.UpdateFrame(b,false); assert(b:GetAlpha()==.4)
c.outOfRangeAlpha=.25; R.UpdateFrame(b,false); assert(b:GetAlpha()==.25)
c.rangeFade=false; R.UpdateFrame(b,false); assert(b:GetAlpha()==1)
c.rangeFade=true; units.party1.connected=false; R.UpdateFrame(b,false); assert(b:GetAlpha()==1)
units.party1.connected=true; b._euiPreview=1; R.UpdateFrame(b,false); assert(b:GetAlpha()==1)
b._euiPreview=nil; combat=false; b:SetAttribute('unit','player'); combat=true
R.UpdateFrame(b,false); assert(b:GetAlpha()==1)
combat=false; UnitInRange=native
''')
print('PASS: Wrath nil/false/0 out-of-range fade, return to range, modern unchecked results, custom alpha, toggle, offline/self/preview exclusions and combat-safe alpha changes')
