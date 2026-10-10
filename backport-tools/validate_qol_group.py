"""QoL group automation (ElvUI Misc parity): interrupt announce, accepting invites
from friends and guildmates, and the Disband button in Raid Tools."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
toc=(root/'EllesmereUIQoL/EllesmereUIQoL.toc').read_text(encoding='utf-8-sig')
assert 'EUI_QoL_335_Extras.lua\nEUI_QoL_335_Group.lua' in toc
lua=LuaRuntime(unpack_returned_tuples=True)
for source in ['backport-tools/wrath_mock.lua','backport-tools/inventory_resources_mock.lua','backport-tools/qol_mock.lua','EllesmereUI/EllesmereUI_Lite.lua']:
    lua.execute((root/source).read_text(encoding='utf-8-sig'))
ns=lua.table()
lua.execute("function SecureHandlerSetFrameRef(f,label,ref) f['ref_'..label]=ref end; function SecureHandlerExecute() end")
for name in ['EUI_QoL_335.lua','EUI_QoL_335_Displays.lua','EUI_QoL_335_Panels.lua','EUI_QoL_335_RaidTools.lua','EUI_QoL_335_Mail.lua','EUI_QoL_335_Extras.lua','EUI_QoL_335_Group.lua']:
    lua.execute((root/'EllesmereUIQoL'/name).read_text(encoding='utf-8-sig'),'EllesmereUIQoL',ns)
lua.globals().Q=ns
core=(root/'EllesmereUI/EllesmereUI_Lite.lua').read_text(encoding='utf-8-sig')
safe=lua.execute('local function errorhandler('+core.split('local function errorhandler(',1)[1].split('\n-------------------------------------------------------------------------------',1)[0]+'\nreturn safecall')
safe(ns.addon.OnInitialize,ns.addon)
safe(ns.addon.OnEnable,ns.addon)
lua.execute(r'''
getmetatable(UIParent).__index.IsEventRegistered=function(self,e) return self.events[e]==true end
local p=Q.GetSettings(); local g=Q.groupEvents
assert(p.interruptAnnounce=='NONE' and p.autoAcceptInvites==false,'defaults')
assert(not g:IsEventRegistered('COMBAT_LOG_EVENT_UNFILTERED') and not g:IsEventRegistered('PARTY_INVITE_REQUEST'),'idle when off')
-- Group state.
raidCount,partyCount=0,0
function GetNumRaidMembers() return raidCount end
function GetNumPartyMembers() return partyCount end
function UnitGUID(u) return 'guid-'..u end
INTERRUPTED='Interrupted'
function GetSpellLink(id) return '|cff71d5ff|Hspell:'..id..'|h[Spell'..id..']|h|r' end
-- Interrupt announce: only our own (or pet) SPELL_INTERRUPT, channel by mode.
local function CL(sub,src,dst,extra) g:RunScript('OnEvent','COMBAT_LOG_EVENT_UNFILTERED',0,sub,src,'Me',0,'guid-boss',dst,0,2139,'Counterspell',64,extra,'Frostbolt') end
p.interruptAnnounce='PARTY'; Q.Apply(); assert(g:IsEventRegistered('COMBAT_LOG_EVENT_UNFILTERED'))
chatSent={}; CL('SPELL_INTERRUPT','guid-player','Boss',116); assert(#chatSent==0,'solo: no party channel')
partyCount=2; CL('SPELL_INTERRUPT','guid-player','Boss',116)
assert(chatSent[1][2]=='PARTY' and chatSent[1][1]=="Interrupted Boss's |cff71d5ff|Hspell:116|h[Spell116]|h|r!",chatSent[1][1])
CL('SPELL_INTERRUPT','guid-pet','Boss',116); assert(#chatSent==2,'pet interrupts count')
CL('SPELL_INTERRUPT','guid-party1','Boss',116); CL('SPELL_CAST_SUCCESS','guid-player','Boss',116); assert(#chatSent==2,'others and non-interrupts ignored')
inside,instanceKind=true,'pvp'; CL('SPELL_INTERRUPT','guid-player','Boss',116); assert(chatSent[3][2]=='BATTLEGROUND'); inside,instanceKind=false,'none'
p.interruptAnnounce='RAID'; Q.Apply(); CL('SPELL_INTERRUPT','guid-player','Boss',116); assert(chatSent[4][2]=='PARTY','raid falls back to party')
p.interruptAnnounce='RAID_ONLY'; Q.Apply(); CL('SPELL_INTERRUPT','guid-player','Boss',116); assert(#chatSent==4)
raidCount=10; CL('SPELL_INTERRUPT','guid-player','Boss',116); assert(chatSent[5][2]=='RAID')
p.interruptAnnounce='SAY'; Q.Apply(); raidCount,partyCount=0,0; CL('SPELL_INTERRUPT','guid-player','Boss',116); assert(chatSent[6][2]=='SAY')
p.interruptAnnounce='NONE'; Q.Apply(); assert(not g:IsEventRegistered('COMBAT_LOG_EVENT_UNFILTERED'))
p.interruptAnnounce='SAY'; p.enabled=false; Q.Apply(); assert(not g:IsEventRegistered('COMBAT_LOG_EVENT_UNFILTERED'),'module off'); p.enabled=true; p.interruptAnnounce='NONE'; Q.Apply()
-- Auto-accept invites from friends and guildmates.
accepts,hidden,friendRefresh,guildRefresh=0,nil,0,0
function AcceptGroup() accepts=accepts+1 end
function StaticPopup_Hide(which) hidden=which end
function GetNumFriends() return 1 end; function GetFriendInfo(i) return 'Pal' end
inGuild=true; function IsInGuild() return inGuild end
function GetNumGuildMembers() return 2 end; function GetGuildRosterInfo(i) return ({'Guildie','Other'})[i] end
function ShowFriends() friendRefresh=friendRefresh+1 end; function GuildRoster() guildRefresh=guildRefresh+1 end
g:RunScript('OnEvent','PARTY_INVITE_REQUEST','Pal'); assert(accepts==0,'off by default')
p.autoAcceptInvites=true; Q.Apply(); assert(g:IsEventRegistered('PARTY_INVITE_REQUEST'))
g:RunScript('OnEvent','PLAYER_ENTERING_WORLD'); assert(friendRefresh==1 and guildRefresh==1,'friend and guild caches refreshed')
g:RunScript('OnEvent','PARTY_INVITE_REQUEST','Stranger'); assert(accepts==0)
g:RunScript('OnEvent','PARTY_INVITE_REQUEST','Pal'); assert(accepts==1 and hidden=='PARTY_INVITE')
hidden=nil; g:RunScript('OnEvent','PARTY_MEMBERS_CHANGED'); assert(hidden=='PARTY_INVITE','late popup closed')
hidden=nil; g:RunScript('OnEvent','PARTY_MEMBERS_CHANGED'); assert(hidden==nil,'only once per accept')
g:RunScript('OnEvent','PARTY_INVITE_REQUEST','Guildie-Icecrown'); assert(accepts==2,'guildmate with realm suffix')
inGuild=false; g:RunScript('OnEvent','PARTY_INVITE_REQUEST','Guildie'); assert(accepts==2); inGuild=true
partyCount=1; g:RunScript('OnEvent','PARTY_INVITE_REQUEST','Pal'); assert(accepts==2,'already grouped'); partyCount=0
MiniMapLFGFrame=CreateFrame('Frame','MiniMapLFGFrame',UIParent); MiniMapLFGFrame:Show()
g:RunScript('OnEvent','PARTY_INVITE_REQUEST','Pal'); assert(accepts==2,'queued in Dungeon Finder'); MiniMapLFGFrame:Hide()
p.autoAcceptInvites=false; Q.Apply(); assert(not g:IsEventRegistered('PARTY_INVITE_REQUEST'))
-- Disband: leader only, everyone but us removed, then we leave.
removed,left,popup={},0,nil
function UninviteUnit(n) removed[#removed+1]=n end
function LeaveParty() left=left+1 end
function UnitName(u) return ({player='Me',party1='A',party2='B'})[u] end
function GetRaidRosterInfo(i) return ({'Me','R2','R3'})[i],0,1,80,'Mage','MAGE','Zone',i~=3 end
function StaticPopup_Show(which) popup=which end
leader=false; raidLeader=false; function IsRaidLeader() return raidLeader end
Q.ConfirmDisband(); assert(popup==nil,'nothing to disband solo')
partyCount=2; Q.ConfirmDisband(); assert(popup=='EUI335_DISBAND_GROUP' and StaticPopupDialogs.EUI335_DISBAND_GROUP.OnAccept)
StaticPopupDialogs.EUI335_DISBAND_GROUP.OnAccept(); assert(#removed==0 and left==0,'non-leader cannot disband')
leader=true; StaticPopupDialogs.EUI335_DISBAND_GROUP.OnAccept(); assert(removed[1]=='B' and removed[2]=='A' and left==1)
removed,left={},0; partyCount=2; raidCount=3; leader=false; raidLeader=true; Q.DisbandGroup()
assert(#removed==2 and removed[1]=='R2' and removed[2]=='R3' and left==1,'raid: offline members removed too')
removed,left={},0; combat=true; function InCombatLockdown() return combat end; Q.DisbandGroup(); assert(#removed==0 and left==0,'combat guard'); combat=false
-- Rebuild as party: a raid of five or fewer is emptied, then invited back once the old group is gone.
local rb=Q.rebuildEvents; invited={}; function InviteUnit(n) invited[#invited+1]=n end; now=100; function GetTime() return now end
raidCount=6; popup=nil; Q.ConfirmRebuildParty(); assert(popup==nil,'over five')
raidCount=3; raidLeader=false; leader=false; Q.ConfirmRebuildParty(); assert(popup==nil,'leader only')
raidLeader=true; combat=true; Q.ConfirmRebuildParty(); assert(popup==nil,'combat'); combat=false
Q.ConfirmRebuildParty(); assert(popup=='EUI335_REBUILD_PARTY')
removed,left={},0; StaticPopupDialogs.EUI335_REBUILD_PARTY.OnAccept(); assert(#removed==2 and left==1 and #invited==0)
rb:RunScript('OnEvent','RAID_ROSTER_UPDATE'); assert(#invited==0,'still grouped')
raidCount,partyCount=0,0; rb:RunScript('OnEvent','RAID_ROSTER_UPDATE'); assert(invited[1]=='R2' and invited[2]=='R3' and not rb:IsEventRegistered('RAID_ROSTER_UPDATE'))
rb:RunScript('OnEvent','PARTY_MEMBERS_CHANGED'); assert(#invited==2,'invites once')
raidCount=3; Q.RebuildAsParty(); now=200; raidCount=0; rb:RunScript('OnEvent','RAID_ROSTER_UPDATE'); assert(#invited==2,'stale rebuild expires')
-- Reinvite: a party comes back as a party.
invited,removed,left,popup={},{},0,nil; raidCount,partyCount=0,2; Q.ConfirmReinvite(); assert(popup=='EUI335_REINVITE_GROUP')
StaticPopupDialogs.EUI335_REINVITE_GROUP.OnAccept(); assert(#removed==2 and left==1)
partyCount=0; rb:RunScript('OnEvent','PARTY_MEMBERS_CHANGED'); assert(invited[1]=='A' and invited[2]=='B' and not rb:IsEventRegistered('PARTY_MEMBERS_CHANGED'))
-- A raid of seven: four invites, convert once someone joins, then the rest.
local big={'Me','R2','R3','R4','R5','R6','R7'}; function GetRaidRosterInfo(i) return big[i] end
converted=0; function ConvertToRaid() converted=converted+1 end
invited,removed,left={},{},0; raidCount,partyCount=7,0; Q.ReinviteGroup(); assert(#removed==6 and left==1)
raidCount=0; rb:RunScript('OnEvent','RAID_ROSTER_UPDATE'); assert(#invited==4 and invited[4]=='R5' and converted==0)
rb:RunScript('OnEvent','PARTY_MEMBERS_CHANGED'); assert(#invited==4 and converted==0,'nobody joined yet')
partyCount=1; rb:RunScript('OnEvent','PARTY_MEMBERS_CHANGED'); assert(converted==1 and #invited==4)
raidCount,partyCount=2,0; rb:RunScript('OnEvent','RAID_ROSTER_UPDATE'); assert(#invited==6 and invited[6]=='R7' and not rb:IsEventRegistered('RAID_ROSTER_UPDATE'))
-- A raid of three stays a raid.
big={'Me','R2','R3'}; invited,converted={},0; raidCount=3; Q.ReinviteGroup(); raidCount=0; rb:RunScript('OnEvent','RAID_ROSTER_UPDATE'); assert(#invited==2 and rb:IsEventRegistered('PARTY_MEMBERS_CHANGED'))
partyCount=1; rb:RunScript('OnEvent','PARTY_MEMBERS_CHANGED'); assert(converted==1); raidCount,partyCount=2,0; rb:RunScript('OnEvent','RAID_ROSTER_UPDATE'); assert(not rb:IsEventRegistered('RAID_ROSTER_UPDATE'))
raidCount,partyCount=0,0; popup=nil; Q.ConfirmReinvite(); assert(popup==nil,'solo')
raidCount,partyCount=0,0
assert(Q.StartPull and Q.StopPull and Q.ApplyRaidTools and not Q.raidFrame,'Raid Tools on Never builds no frames')
''')
lua.execute((root/'EllesmereUIOptions/EUI_QoL_335_Options.lua').read_text(encoding='utf-8-sig'))
lua.execute("allFrames[#allFrames]:RunScript('OnEvent','PLAYER_LOGIN')")
lua.execute(r'''
local module=modules.EllesmereUIQoL
rows={}; module.buildPage('QoL',UIParent,0)
local announce=FindRow('Announce Interrupts'); assert(announce.values.RAID_ONLY=='Raid Only' and announce.order[1]=='NONE')
announce.setValue('RAID'); assert(Q.GetSettings().interruptAnnounce=='RAID' and Q.groupEvents:IsEventRegistered('COMBAT_LOG_EVENT_UNFILTERED'))
FindRow('Accept Invites from Friends & Guild').setValue(true); assert(Q.GetSettings().autoAcceptInvites and Q.groupEvents:IsEventRegistered('PARTY_INVITE_REQUEST'))
assert(FindRow('Accept Invites from Friends & Guild').tooltip:find('Dungeon Finder',1,true))
rows={}; buttons={}; module.buildPage('Raid Tools',UIParent,0); assert(buttons['Move Raid Tools'] and not buttons['Disband Group'])
FindRow('Show Reinvite').setValue(false); assert(Q.GetSettings().raidTools.showReinvite==false); FindRow('Show Reinvite').setValue(true)
''')
print('PASS: QoL interrupt announce (self/pet only, party/raid/battleground/say channels, off when disabled), friend and guild invite auto-accept (realm suffix, grouped/LFG guards, popup closed), leader-only Disband with confirmation and combat guard, options rows.')
