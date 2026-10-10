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
e:RunScript('OnEvent','READY_CHECK','Player',20); R.UpdateFrame(b,false)
e:RunScript('OnEvent','READY_CHECK_FINISHED'); e:RunScript('OnEvent','READY_CHECK_CONFIRM','party1',1); R.UpdateFrame(b,false)
assert(R.readyResults.CHECK1=='ready' and b.ready:GetTexture():find('Ready',1,true) and not b.ready:GetTexture():find('NotReady',1,true),'Answer after FINISHED was dropped')
e:RunScript('OnEvent','READY_CHECK','Player',20); units.party1.ready='ready'; e:RunScript('OnEvent','READY_CHECK_FINISHED'); R.UpdateFrame(b,false)
assert(R.readyResults.CHECK1=='ready','Live status read at FINISHED'); units.party1.ready=nil
e:RunScript('OnEvent','READY_CHECK','Check',20); R.UpdateFrame(b,false)
assert(R.readyResults.CHECK1=='ready','Initiator counts as ready')
e:RunScript('OnEvent','READY_CHECK_FINISHED'); R.UpdateFrame(b,false); assert(R.readyResults.CHECK1=='ready','Initiator stays ready after FINISHED')
e:RunScript('OnEvent','READY_CHECK','Player',20); units.party1.ready='ready'; e:RunScript('OnEvent','READY_CHECK_CONFIRM','party1',nil)
units.party1.ready=nil; e:RunScript('OnEvent','READY_CHECK_FINISHED'); R.UpdateFrame(b,false)
assert(R.readyResults.CHECK1=='ready','Live status wins over an unexpected CONFIRM argument')
e:RunScript('OnEvent','READY_CHECK','Player',20); e:RunScript('OnEvent','READY_CHECK_CONFIRM','party1',nil); R.UpdateFrame(b,false)
assert(R.readyResults.CHECK1=='waiting','Unknown answer is not turned into not ready early')
e:RunScript('OnEvent','READY_CHECK','Player',20); e:RunScript('OnEvent','READY_CHECK_CONFIRM','party1',true)
units.party1.ready='notready'; e:RunScript('OnEvent','READY_CHECK_FINISHED'); R.UpdateFrame(b,false); units.party1.ready=nil
assert(R.readyResults.CHECK1=='ready','Confirmed answer is final at FINISHED')
if ConfirmReadyCheck and units.player then
    local pb=R.headers.party[1].nativeButtons[1]; SetNativeAttribute(pb,'unit','player'); pb._euiKind='party'; pb._euiPreview=nil
    local pguid=units.player.guid
    e:RunScript('OnEvent','READY_CHECK','Leader',20); ConfirmReadyCheck(1); e:RunScript('OnEvent','READY_CHECK_FINISHED'); R.UpdateFrame(pb,false)
    assert(R.readyResults[pguid]=='ready' and not pb.ready:GetTexture():find('NotReady',1,true),'Own Yes click without a CONFIRM event')
    e:RunScript('OnEvent','READY_CHECK','Leader',20); ConfirmReadyCheck(); e:RunScript('OnEvent','READY_CHECK_FINISHED')
    assert(R.readyResults[pguid]=='notready','Own No click')
    SetNativeAttribute(pb,'unit',nil)
else error('ConfirmReadyCheck hook not testable: mock missing') end
local oldParty,oldRaid=partyCount,raidCount; partyCount,raidCount=1,0
e:RunScript('OnEvent','READY_CHECK','Player',20); e:RunScript('OnEvent','READY_CHECK_CONFIRM','Check',1); R.UpdateFrame(b,false)
assert(R.readyResults.CHECK1=='ready','Confirm by name resolves the group member')
partyCount,raidCount=oldParty,oldRaid
e:RunScript('OnEvent','READY_CHECK','Player',20); e:RunScript('OnEvent','READY_CHECK_FINISHED'); R.UpdateFrame(b,false)
c.showReadyCheck=false; R.UpdateFrame(b,false); assert(not b.ready:IsShown())
c.showReadyCheck=true; units.party1.guid='REPLACEMENT'; R.UpdateFrame(b,false); assert(not b.ready:IsShown(),'Result transferred to different player')
combat=false
''')
print('PASS: ready waiting/yes/no, event confirmation, retained finish status, timeout/new check, unanswered conversion, layering, toggle, GUID isolation and combat')
