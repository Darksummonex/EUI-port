"""Ready results persist and render above central debuffs without secure writes."""
from validate_raidframes import lua
lua.execute(r'''
combat=false
local b=R.headers.party[1].nativeButtons[2]; b:SetAttribute('unit','party1'); b._euiKind='party'; b._euiPreview=nil
local c=R.GetSettings('party'); c.showReadyCheck=true; c.raidDebuffs=true
units.party1={name='Check',guid='CHECK1',class='PRIEST',health=100,maxHealth=100,power=50,maxPower=100,debuffs={{name='Beacon',id=70126,duration=30,expires=now+30}}}
local e=R.events
combat=true; e:RunScript('OnEvent','READY_CHECK','Player',20); R.UpdateFrame(b,true)
assert(b.ready:IsShown() and b.ready:GetTexture():find('Waiting',1,true))
assert(b.raidDebuff:IsShown() and b.ready:GetParent():GetFrameLevel()>b.raidDebuff:GetFrameLevel(),'Debuff covers ready icon')
e:RunScript('OnEvent','READY_CHECK_CONFIRM','party1',true); R.UpdateFrame(b,false)
assert(b.ready:GetTexture():find('Ready',1,true) and R.readyResults.CHECK1=='ready')
e:RunScript('OnEvent','READY_CHECK_FINISHED'); R.UpdateFrame(b,false)
assert(b.ready:IsShown() and R.readyResults.CHECK1=='ready','Lost completed result after API clears')
now=now+11; R.UpdateFrame(b,false); assert(not b.ready:IsShown())
e:RunScript('OnEvent','READY_CHECK','Player',20); R.UpdateFrame(b,false); assert(R.readyResults.CHECK1=='waiting','Previous check leaked')
e:RunScript('OnEvent','READY_CHECK_CONFIRM','party1',false); R.UpdateFrame(b,false); assert(b.ready:GetTexture():find('NotReady',1,true))
e:RunScript('OnEvent','READY_CHECK','Player',20); R.UpdateFrame(b,false)
e:RunScript('OnEvent','READY_CHECK_FINISHED'); R.UpdateFrame(b,false); assert(R.readyResults.CHECK1=='notready','Unanswered check')
c.showReadyCheck=false; R.UpdateFrame(b,false); assert(not b.ready:IsShown())
c.showReadyCheck=true; units.party1.guid='REPLACEMENT'; R.UpdateFrame(b,false); assert(not b.ready:IsShown(),'Result transferred to different player')
combat=false
''')
print('PASS: ready waiting/yes/no, event confirmation, retained finish status, timeout/new check, unanswered conversion, layering, toggle, GUID isolation and combat')
