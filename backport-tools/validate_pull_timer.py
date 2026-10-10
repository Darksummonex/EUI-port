"""Exercise timer scheduling, permissions and outgoing packets without sending chat."""
from pathlib import Path
import runpy
from game_paths import ADDONS, DATA, WTF
root=Path(__file__).resolve().parents[1]
context=runpy.run_path(str(root/'backport-tools/validate_qol.py'))
lua=context['lua']
lua.execute('''
DBM=setmetatable({}, {__index=function() error('QoL relied on DBM') end})
BigWigs=setmetatable({}, {__index=function() error('QoL relied on BigWigs') end})
chat,packets={},{}
function SendChatMessage(text,channel) chat[#chat+1]={text,channel} end
function SendAddonMessage(prefix,text,channel) packets[#packets+1]={prefix,text,channel} end
raidCount,partyCount,officer=0,1,false
function GetNumRaidMembers() return raidCount end
function GetNumPartyMembers() return partyCount end
function UnitIsRaidOfficer() return officer end
function ResetTraffic() chat={}; packets={} end
function AssertPackets(seconds,channel)
    assert(#packets==3,#packets)
    assert(packets[1][1]=='DBMv4-PT' and packets[1][2]==tostring(seconds))
    assert(packets[2][1]=='D4' and packets[2][2]=='PT\\t'..seconds)
    assert(packets[3][1]=='BigWigs' and packets[3][2]=='BWCustomBar '..seconds..' Pull')
    for _,packet in ipairs(packets) do assert(packet[3]==channel) end
end
local p=Q.GetSettings(); p.enabled=true; p.raidTools.mode='always'; p.raidTools.collapsedIcon=false
p.raidTools.pullSync=true; p.raidTools.pullChat=true
Q.Apply(); assert(Q.raidButtons.pull[3].label:GetText()=='10')
now=100; leader=true; ResetTraffic(); Q.raidButtons.pull[3]:RunScript('OnClick'); AssertPackets(10,'PARTY')
assert(#chat==1 and chat[1][1]=='Pull in 10 seconds' and chat[1][2]=='PARTY')
for i=1,20 do Q.UpdatePull() end; assert(#chat==1)
for i=1,4 do now=100+i; Q.UpdatePull() end; assert(#chat==1)
for i=5,9 do now=100+i; Q.UpdatePull(); Q.UpdatePull() end
assert(#chat==6)
for i=2,6 do assert(chat[i][1]=='Pull in '..(7-i)..' seconds') end
now=110; Q.UpdatePull(); assert(chat[7][1]=='Pull!' and Q.pullFrame.text:GetText()=='Pull!')
now=112; Q.UpdatePull(); assert(#chat==7 and not Q.pullFrame:IsShown() and #packets==3)
-- Long timer announces its start, then only 10 and 5..1; no 9..6 spam.
raidCount=10; partyCount=0; officer=1; leader=false
Q.Apply(); now=200; ResetTraffic(); Q.StartPull(20); AssertPackets(20,'RAID')
assert(chat[1][2]=='RAID_WARNING')
now=210; Q.UpdatePull(); assert(chat[2][1]=='Pull in 10 seconds')
for i=211,214 do now=i; Q.UpdatePull() end; assert(#chat==2)
now=216; Q.UpdatePull(); assert(chat[3][1]=='Pull in 4 seconds','Lag emitted stale checkpoints')
-- Rank changes immediately lower the channel; numeric zero is false.
officer=0; leader=0; now=217; Q.UpdatePull(); assert(chat[4][2]=='RAID')
officer=true; now=218; Q.UpdatePull(); assert(chat[5][2]=='RAID_WARNING')
ResetTraffic(); Q.raidButtons.stop:RunScript('OnClick'); AssertPackets(0,'RAID')
assert(chat[1][1]=='Pull canceled' and not Q.pullFrame:IsShown())
Q.CancelPull(); assert(#packets==3 and #chat==1)
now=219; Q.UpdatePull(); assert(#chat==1)
-- Stop with no local pull still cancels a synced timer someone else started.
ResetTraffic(); Q.StopPull(); AssertPackets(0,'RAID'); assert(#chat==0)
-- Non-officers still have raid chat and the local timer, no unauthorized sync.
officer=false; leader=false; ResetTraffic(); Q.StartPull(10)
assert(#packets==0 and chat[1][2]=='RAID'); Q.CancelPull()
raidCount=0; partyCount=1; ResetTraffic(); Q.StartPull(10)
assert(#packets==0 and chat[1][2]=='PARTY'); Q.CancelPull()
partyCount=0; ResetTraffic(); Q.StartPull(10); assert(#chat==0 and #packets==0 and Q.pullFrame:IsShown()); Q.CancelPull()
-- Independent opt-outs, clamped values and UI callbacks.
partyCount=1; leader=true
assert(Q.GetPullSeconds(-9)==1 and Q.GetPullSeconds(90)==60 and Q.GetPullSeconds('bad')==10 and Q.GetPullSeconds(3.9)==3)
p.raidTools.pullSync=false; ResetTraffic(); Q.StartPull(5)
assert(#packets==0 and chat[1][1]=='Pull in 5 seconds'); Q.CancelPull()
p.raidTools.pullSync=true; p.raidTools.pullChat=false; ResetTraffic(); Q.StartPull(5); AssertPackets(5,'PARTY')
assert(#chat==0); ResetTraffic(); Q.CancelPull(); AssertPackets(0,'PARTY'); assert(#chat==0)
p.raidTools.pullChat=true; ResetTraffic(); Q.StartPull(5)
now=now+2; ResetTraffic(); Q.events:RunScript('OnEvent','PLAYER_REGEN_DISABLED')
AssertPackets(0,'PARTY'); assert(not Q.pullFrame:IsShown()); Q.UpdatePull(); assert(#chat==1)
combat=true; ResetTraffic(); assert(not Q.StartPull(5) and #packets==0 and #chat==0); combat=false
ResetTraffic(); Q.StartPull(5); p.raidTools.mode='never'; ResetTraffic(); Q.UpdatePull()
AssertPackets(0,'PARTY'); assert(not Q.pullFrame:IsShown() and #chat==0)
p.raidTools.mode='always'; ResetTraffic(); Q.StartPull(5); partyCount=0; ResetTraffic(); Q.UpdatePull()
assert(not Q.pullFrame:IsShown() and #packets==0 and #chat==0)
partyCount=1; ResetTraffic(); Q.StartPull(5); Q.addon.db.profile={}; ResetTraffic(); Q.UpdatePull()
AssertPackets(0,'PARTY'); assert(#chat==0 and not Q.pullFrame:IsShown()); Q.addon.db.profile=p
rows={}; modules.EllesmereUIQoL.buildPage('Raid Tools',UIParent,0)
FindRow('Third Timer').setValue(25); assert(Q.RaidToolsPullTime(3)==25 and Q.raidButtons.pull[3].label:GetText()=='25')
FindRow('Send to DBM / BigWigs').setValue(false); assert(not p.raidTools.pullSync)
FindRow('Chat Countdown').setValue(false); assert(not p.raidTools.pullChat)
''')
print('PASS: pull duration/options, local countdown, 10 + 5..1 chat checkpoints, deduplication/lag, warning/raid/party/solo permissions, protocol packets, cancel/combat/disable/profile/group safety; no boss mod dependency or actual messages sent.')
# Optional extra check against the locally installed receiver, never loaded
# or consulted by the addon. The project remains testable without DBM.
dbm_path=ADDONS/'DBM-Core/DBM-Core.lua' if ADDONS else None
if dbm_path and dbm_path.exists():
    source=dbm_path.read_text(encoding='utf-8-sig')
    receiver='function(sender, timer, senderMapID, target)'+source.split('syncHandlers["DBMv4-PT"] = function(sender, timer, senderMapID, target)',1)[1].split('\n\tdo\n\t\tlocal dummyMod2',1)[0]
    handler=lua.execute('''
local starts,stops=0,0
local dummyMod={timer={},text={}}
function dummyMod.timer:Start(seconds) starts=seconds end
function dummyMod.timer:Stop() stops=stops+1 end
function dummyMod.text:Cancel() end
local DBM={Options={DontShowPTCountdownText=true,DontShowPTText=true,DontShowPTNoID=true}}
function DBM:GetRaidRank() return receiverRank end
function DBM:AntiSpam() return true end
function DBM:FlashClientIcon() end
local function IsPartyLFG() return false end
local function IsInGroup() return true end
local function UnitGroupRolesAssigned() return false end
local function IsInInstance() return true,'raid' end
local function sendSync() end
local L={TIMER_PULL='Pull'}
local receive='''+receiver+'''
return function(sender,seconds)
    receive(sender,seconds)
    return starts,stops
end
''')
    lua.globals().receiverRank=1
    assert handler('Leader','10')==(10,1)
    assert handler('Leader','0')==(10,2)
    lua.globals().receiverRank=0
    assert handler('Member','20')==(10,2)
    print('PASS: actual installed DBM PT receiver accepts the emitted start/cancel without map ID and rejects unauthorized senders.')
