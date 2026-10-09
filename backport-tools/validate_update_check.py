"""Update notices: release stamp from the Core TOC, guild/group broadcasts with a
throttle, newer stamps announce once (unless disabled), older stamps get a reply
on the same channel, and /euiupdate opens the copy popup with the releases URL."""
from pathlib import Path
import re
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

toc = (root / 'EllesmereUI/EllesmereUI.toc').read_text(encoding='utf-8')
m = re.search(r'^## X-EUI-Release: (\d{10})\s*$', toc, re.M)
assert m, 'Core TOC needs "## X-EUI-Release: YYYYMMDDNN"'
stamp = int(m.group(1))
assert 'EllesmereUI_UpdateCheck_335.lua' in toc.splitlines(), 'update check not listed in the Core TOC'
src = (root / 'EllesmereUI/EllesmereUI_UpdateCheck_335.lua').read_text(encoding='utf-8-sig')

lua = LuaRuntime()
lua.execute((root / 'backport-tools/wrath_mock.lua').read_text(encoding='utf-8-sig'))
lua.globals().releaseStamp = str(stamp)
lua.execute('''
EllesmereUIDB={}
sent={}; printed={}; timers={}
SendAddonMessage=function(prefix,msg,channel,target) sent[#sent+1]={prefix,msg,channel,target} end
GetAddOnMetadata=function(addon,field) assert(addon=="EllesmereUI" and field=="X-EUI-Release"); return releaseStamp end
inGuild=true; instanceType="none"; raid=0; party=0
IsInGuild=function() return inGuild end
IsInInstance=function() return instanceType~="none", instanceType end
GetNumRaidMembers=function() return raid end
GetNumPartyMembers=function() return party end
UnitName=function() return "Me" end
print=function(s) printed[#printed+1]=s end
C_Timer.After=function(_,fn) timers[#timers+1]=fn end
popup=nil
EllesmereUI.ShowCopyPopup=function(self,title,sub,str) popup={title,sub,str} end
''')
lua.execute(src, 'EllesmereUI')
lua.execute('''
local f
for _,fr in ipairs(allFrames) do if fr.events.CHAT_MSG_ADDON then f=fr end end
assert(f and f.events.PLAYER_LOGIN and f.events.PARTY_MEMBERS_CHANGED and f.events.RAID_ROSTER_UPDATE)
local fire=f:GetScript("OnEvent")
local mine=tonumber(releaseStamp)
assert(EllesmereUI.UpdateCheck.Release()==mine)

-- Login broadcasts to the guild after a delay.
fire(f,"PLAYER_LOGIN"); assert(#sent==0 and #timers==1); timers[1]()
assert(#sent==1 and sent[1][1]=="EUIVER" and sent[1][2]==releaseStamp and sent[1][3]=="GUILD")
-- Throttled: a group change right after does not resend to the guild.
party=2; fire(f,"PARTY_MEMBERS_CHANGED")
assert(#sent==2 and sent[2][3]=="PARTY")
fire(f,"PARTY_MEMBERS_CHANGED"); assert(#sent==2, "throttle")
now=now+61; raid=10; fire(f,"RAID_ROSTER_UPDATE")
assert(#sent==4 and sent[3][3]=="GUILD" and sent[4][3]=="RAID")
now=now+61; instanceType="pvp"; inGuild=false; fire(f,"RAID_ROSTER_UPDATE")
assert(#sent==5 and sent[5][3]=="BATTLEGROUND")

-- Own echo, other prefixes and junk are ignored.
fire(f,"CHAT_MSG_ADDON","EUIVER",tostring(mine+5),"GUILD","Me")
fire(f,"CHAT_MSG_ADDON","OTHER",tostring(mine+5),"GUILD","Bob")
fire(f,"CHAT_MSG_ADDON","EUIVER","abc","GUILD","Bob")
assert(#printed==0 and #sent==5)

-- An older client gets our stamp back on the same channel (throttled).
now=now+61
fire(f,"CHAT_MSG_ADDON","EUIVER",tostring(mine-1),"GUILD","Old")
assert(#sent==6 and sent[6][3]=="GUILD" and sent[6][2]==releaseStamp)
fire(f,"CHAT_MSG_ADDON","EUIVER",tostring(mine-1),"WHISPER","Old")
assert(#sent==7 and sent[7][3]=="WHISPER" and sent[7][4]=="Old")
-- Same release: nothing.
fire(f,"CHAT_MSG_ADDON","EUIVER",releaseStamp,"PARTY","Same")
assert(#sent==7 and #printed==0)

-- A newer release announces once per session.
fire(f,"CHAT_MSG_ADDON","EUIVER",tostring(mine+1),"GUILD","New")
assert(#printed==1 and printed[1]:find("newer release",1,true) and printed[1]:find("/euiupdate",1,true))
fire(f,"CHAT_MSG_ADDON","EUIVER",tostring(mine+2),"GUILD","Newer")
assert(#printed==1 and EllesmereUI.UpdateCheck.Newest()==mine+2)

-- /euiupdate shows the link and both releases.
SlashCmdList.EUIUPDATE("")
assert(popup and popup[3]=="https://github.com/Darksummonex/EUI-port/releases")
assert(popup[2]:find("Installed release",1,true) and popup[2]:find("Newer release seen",1,true))
''')

# Notices off: a newer stamp is recorded silently.
lua2 = LuaRuntime()
lua2.execute((root / 'backport-tools/wrath_mock.lua').read_text(encoding='utf-8-sig'))
lua2.globals().releaseStamp = str(stamp)
lua2.execute('''
EllesmereUIDB={updateCheckDisabled=true}; printed={}
SendAddonMessage=function() end
GetAddOnMetadata=function() return releaseStamp end
IsInGuild=function() return false end
IsInInstance=function() return false,"none" end
print=function(s) printed[#printed+1]=s end
''')
lua2.execute(src, 'EllesmereUI')
lua2.execute('''
local f
for _,fr in ipairs(allFrames) do if fr.events.CHAT_MSG_ADDON then f=fr end end
f:GetScript("OnEvent")(f,"CHAT_MSG_ADDON","EUIVER",tostring(tonumber(releaseStamp)+1),"GUILD","New")
assert(#printed==0, "notice shown while disabled")
assert(EllesmereUI.UpdateCheck.Newest()==tonumber(releaseStamp)+1)
''')

general = (root / 'EllesmereUIOptions/EUI__General_Options.lua').read_text(encoding='utf-8-sig')
assert 'text="Update Notices"' in general and 'updateCheckDisabled' in general, 'Update Notices toggle missing'
print('PASS: update notices (release %d): login/group broadcasts with throttle, BG channel, older clients answered, '
      'newer release announced once, disabled stays silent, /euiupdate link popup, options toggle' % stamp)
