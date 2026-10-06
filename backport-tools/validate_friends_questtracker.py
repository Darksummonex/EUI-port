"""Run both native modules with the actual EUI Lite lifecycle and native UI hooks."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
lua=LuaRuntime()
for name in ['wrath_mock.lua','inventory_resources_mock.lua','wrath_secure_palette_mock.lua']:
    lua.execute((root/'backport-tools'/name).read_text())
lua.execute('lifecycleErrors={}; function geterrorhandler() return function(e) lifecycleErrors[#lifecycleErrors+1]=e end end')
lua.execute((root/'EllesmereUI/EllesmereUI_Lite.lua').read_text(),'EllesmereUI',lua.table())
lua.execute('''
for _,f in ipairs(allFrames) do if f.events.ADDON_LOADED and f.events.PLAYER_LOGIN then lifecycle=f end end
lifecycle:RunScript('OnEvent','ADDON_LOADED','EllesmereUI')
local m=getmetatable(UIParent).__index
UIParent:SetWidth(1920); UIParent:SetHeight(1080)
function m:GetRegions() local regions={}; for _,c in ipairs(self.children) do if c.kind=='Texture' or c.kind=='FontString' then regions[#regions+1]=c end end; return unpack(regions) end
function m:GetTextColor() return unpack(self.textColor or {1,1,1,1}) end
function m:GetFontString() return self.label end
function m:GetBottom() return self.bottom or 400 end
function m:GetTop() return self.top or 600 end
function UnregisterStateDriver(f) assert(not combat); secureDrivers[f]=nil end
function IsMounted() return mounted or false end
function IsInInstance() return instance or false end
function IsShiftKeyDown() return shift or false end
function GetNumRaidMembers() return raidCount or 0 end
function UnitExists(unit) return unit~='target' or target~=false end
function hooksecurefunc(name,fn)
 local old=_G[name]; _G[name]=function(...) local result={old(...)}; fn(...); return unpack(result) end
end
RAID_CLASS_COLORS.MAGE={r=.2,g=.8,b=1}; RAID_CLASS_COLORS.PRIEST={r=1,g=1,b=1}
LOCALIZED_CLASS_NAMES_MALE={MAGE='Mago',PRIEST='Sacerdote'}
CLASS_ICON_TCOORDS={MAGE={.25,.5,0,.25},PRIEST={.5,.75,.25,.5}}
friends={{'Mage',80,'Mago','Dalaran',true},{'Priest',80,'Sacerdote','Icecrown',true},{'Away',0,nil,nil,false}}
function GetFriendInfo(id) return unpack(friends[id]) end
function BNGetFriendInfo() return 1,'BNet','Friend',nil,nil,nil,bnetOnline end
FriendsFrame=CreateFrame('Frame','FriendsFrame',UIParent); FriendsFrame:SetScale(1)
FriendsFrameTitleText=FriendsFrame:CreateFontString(); FriendsFrameTitleText:SetFont('original-font',12,''); FriendsFrameTitleText:SetText('Friends')
art=FriendsFrame:CreateTexture(); art:SetAlpha(.8)
FriendsFrameFriendsScrollFrame=CreateFrame('Frame',nil,FriendsFrame); FriendsFrameFriendsScrollFrame.buttons={}
nativeFriendClicks=0
function FriendRow(id)
 local b=CreateFrame('Button',nil,FriendsFrameFriendsScrollFrame); b.id=id; b.buttonType=3
 b.name=b:CreateFontString(); b.name:SetFont('original-font',12,'')
 b.info=b:CreateFontString(); b.info:SetFont('original-font',10,'')
 b.background=b:CreateTexture(); b:SetScript('OnClick',function() nativeFriendClicks=nativeFriendClicks+1 end)
 FriendsFrameFriendsScrollFrame.buttons[#FriendsFrameFriendsScrollFrame.buttons+1]=b; return b
end
row=FriendRow(1); originalFriendClick=row:GetScript('OnClick')
function FriendsFrame_SetButton(b,id) b.id=id; local name=GetFriendInfo(id); b.name:SetText(name); b.name:SetTextColor(1,.9,.3) end
WatchFrame=CreateFrame('Frame','WatchFrame',UIParent); WatchFrame:SetWidth(204); WatchFrame:SetHeight(140); WatchFrame:SetPoint('TOPRIGHT',UIParent,'TOPRIGHT',0,-200)
WatchFrameTitle=WatchFrame:CreateFontString(); WatchFrameTitle:SetFont('original-font',12,''); WatchFrameTitle:SetText('Objectives')
questTitle=CreateFrame('Frame',nil,WatchFrame); questTitle.bottom=540; questTitle.text=questTitle:CreateFontString(); questTitle.text:SetFont('original-font',12,'')
objective=CreateFrame('Frame',nil,WatchFrame); objective.bottom=510; objective.text=objective:CreateFontString(); objective.text:SetFont('original-font',10,''); objective.dash=objective:CreateFontString(); objective.dash:SetFont('original-font',10,'')
function WatchFrame_SetLine(line,anchor,offset,header,text,dash,item,complete) line.text:SetText(text); line.text:SetTextColor(.4,.4,.4) end
function WatchFrame_Update() WatchFrame_SetLine(questTitle,nil,0,true,'Native Quest',nil,nil,questComplete); WatchFrame_SetLine(objective,nil,0,false,'Objective 1/2',nil,nil,objectiveComplete) end
function WatchFrame_SetWidth(value) WatchFrame:SetWidth(value=='1' and 306 or 204); WatchFrame_Update() end
nativeItemClicks=0; WATCHFRAME_NUM_ITEMS=2
WatchFrameItem1=CreateFrame('Button','WatchFrameItem1',WatchFrame); WatchFrameItem1:SetScript('OnClick',function() nativeItemClicks=nativeItemClicks+1 end)
WatchFrameItem2=CreateFrame('Button','WatchFrameItem2',WatchFrame); WatchFrameItem2:Hide()
accepted,completed,rewarded=0,0,0
function AcceptQuest() accepted=accepted+1 end
function CompleteQuest() completed=completed+1 end
function IsQuestCompletable() return completable or false end
function GetQuestReward(index) rewardIndex=index; rewarded=rewarded+1 end
function IsInInstance() return instance or false,instanceType end
function UnitGUID(u) return u=='npc' and npcGUID or u end
gossipActive={}; gossipPicks={}; activeStride=4
function GetNumGossipActiveQuests() return #gossipActive end
function GetGossipActiveQuests() local out={}; for _,q in ipairs(gossipActive) do out[#out+1]=q[1]; out[#out+1]=80; out[#out+1]=false; if activeStride==4 then out[#out+1]=q[2] end end; return unpack(out) end
function SelectGossipActiveQuest(i) gossipPicks[#gossipPicks+1]='active'..i end
function GetNumGossipAvailableQuests() return gossipAvailableCount or 0 end
function SelectGossipAvailableQuest(i) gossipPicks[#gossipPicks+1]='available'..i end
function GetNumAvailableQuests() return greetingCount or 0 end
function SelectAvailableQuest(i) gossipPicks[#gossipPicks+1]='greeting'..i end
function GetNumQuestChoices() return choices or 0 end
function GetRequiredMoney() return questMoney or 0 end
function GetNumQuestItems() return questItems or 0 end
LibStub=function() error('External addon dependency') end
function m:SetVertexColor(...) self.vertex={...} end
function m:EnableMouse(v) self.mouseEnabled=v end
function MouseIsOver(f) return hovered==f end
WatchFrameCollapseExpandButton=CreateFrame('Button','WatchFrameCollapseExpandButton',WatchFrame)
WatchFrameLinkButton1=CreateFrame('Button','WatchFrameLinkButton1',WatchFrame)
WatchFrameLinkButton1.lines={questTitle,objective}; WatchFrameLinkButton1.startLine=1; WatchFrameLinkButton1.lastLine=2
function WatchFrameLinkButtonTemplate_Highlight(self,onEnter) questTitle.text:SetTextColor(1,.82,0) end
''')
lua.execute('EllesmereUI._deferredInits=EllesmereUI._deferredInits or {}; function GetInstanceInfo() return "zone",instance and "party" or "none" end')
for name in ['EllesmereUI/EllesmereUI_VisibilityRules.lua','EllesmereUI/EllesmereUI_Visibility.lua']:
    lua.execute((root/name).read_text(encoding='utf-8-sig'))
for folder,file,var in [('EllesmereUIFriends','EUI_Friends_335.lua','F'),('EllesmereUIQuestTracker','EUI_QuestTracker_335.lua','Q')]:
    ns=lua.table(); lua.execute((root/folder/file).read_text(),folder,ns); lua.globals()[var]=ns
    lua.execute("lifecycle:RunScript('OnEvent','ADDON_LOADED',...)",folder)
lua.execute('''
function IsLoggedIn() return true end
Combat(true); lifecycle:RunScript('OnEvent','PLAYER_LOGIN'); assert(#lifecycleErrors==0,lifecycleErrors[1])
assert(not F.panel and not Q.original and F.pending and Q.pending)
Combat(false); F.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); F.events:RunScript('OnUpdate',.1)
Q.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); Q.events:RunScript('OnUpdate',.1)
assert(F.panel and Q.original and not Q.applying and not Q.dirty)
assert(_EFR_DB==F.addon.db and _EQT_DB==Q.addon.db and unlock.EQT_Tracker)
assert(row:GetScript('OnClick')==originalFriendClick); row:RunScript('OnClick','RightButton'); assert(nativeFriendClicks==1)
assert(row.name.textColor[3]==1 and F.rows[row].icon:IsShown())
FriendsFrame_SetButton(row,2); assert(row.name.textColor[1]==1 and F.rows[row].icon.texcoords[1]==.5)
FriendsFrame_SetButton(row,3); local st=F.rows[row]
assert(row.name.textColor[1]==.6 and st.icon:IsShown() and st.icon.texture:find('Media_335',1,true) and st.icon.texture:find('offline.tga',1,true) and st.icon:GetAlpha()==.5)
assert(st.orb.texture:find('Offline') and st.banner.texture:find('neutral.tga',1,true) and st.banner:GetAlpha()==.2)
-- Retail class icon themes read the shared sprite sheets; Blizzard keeps the native class atlas.
EllesmereUI.CLASS_ICON_SPRITE_COORDS={MAGE={.125,.25,0,.125},PRIEST={.5,.625,.125,.25}}
FriendsFrame_SetButton(row,1); assert(st.icon.texture:find('class-full',1,true) and st.icon.texture:find('modern.tga',1,true) and st.icon.texcoords[1]==.125)
F.Config().iconStyle='runic'; FriendsFrame_SetButton(row,1); assert(st.icon.texture:find('runic.tga',1,true))
F.Config().iconStyle='blizzard'; FriendsFrame_SetButton(row,1); assert(st.icon.texture:find('UI-CharacterCreate-Classes',1,true) and st.icon.texcoords[1]==.25)
F.Config().iconStyle='modern'; EllesmereUI.CLASS_ICON_SPRITE_COORDS=nil
-- Status orb from the friend's AFK/DND flag, note appended once to the details line, faction banner.
friends[1]={'Mage',80,'Mago','Dalaran',true,'<AFK>','Raid lead'}; row.info:SetText('Dalaran')
FriendsFrame_SetButton(row,1); assert(st.orb.texture:find('Away') and row.info.text=='Dalaran  |cff888888|  Raid lead|r')
F.Apply(); F.Apply(); assert(row.info.text=='Dalaran  |cff888888|  Raid lead|r')
friends[1][6]='<DND>'; F.Config().factionBanners=true; FriendsFrame_SetButton(row,1); assert(st.orb.texture:find('DnD') and st.banner.texture:find('alliance.tga',1,true))
friends[1]={'Mage',80,'Mago','Dalaran',true}; F.Config().factionBanners=false; FriendsFrame_SetButton(row,1); assert(row.info.text=='Dalaran' and st.orb.texture:find('Online'))
F.Config().showClassIcons=false; FriendsFrame_SetButton(row,1); assert(not F.rows[row].icon:IsShown())
F.Config().classColorNames=false; F.Apply(); assert(row.name.textColor[1]==1 and row.name.textColor[3]==.65)
local late=FriendRow(2); F.Apply(); assert(F.rows[late] and late.name.font[3]=='OUTLINE')
local oldPanel=F.panel; F.Config().scale=1.2; F.Apply(); F.Apply(); assert(F.panel==oldPanel and FriendsFrame:GetScale()==1.2)
F.Config().enabled=false; F.Apply(); assert(not F.panel:IsShown() and art:GetAlpha()==.8 and FriendsFrame:GetScale()==1 and row.name.font[1]=='original-font')
F.Config().enabled=true; F.Config().useBlizzardStyle=true; F.Apply(); assert(not F.panel:IsShown() and F.FR_Style()=='blizzard')
-- Stock styles keep Blizzard's rows but still add class icons and class-coloured names.
F.Config().showClassIcons=true; F.Config().classColorNames=true; FriendsFrame_SetButton(row,1)
assert(F.decorate and row.name.textColor[3]==1 and F.rows[row].icon:IsShown() and not F.rows[row].fill:IsShown() and not F.rows[row].banner:IsShown() and row.name.font[1]=='original-font')
F.Config().useBlizzardStyle=false; F.Apply(); assert(F.active and not F.decorate and F.panel:IsShown())
-- Border size/colour (0.2 accent toggle migrates to Accent Colored) and the accent tab underline.
assert(F.Config().borderMigrated and F.Config().useClassColor and F.panel.backdrop.edgeSize==1)
F.Config().borderSize=3; F.Config().useClassColor=false; F.Config().borderR=.5; F.Apply(); assert(F.panel.backdrop.edgeSize==3 and F.panel.borderColor[1]==.5)
F.Config().borderSize=0; F.Apply(); assert(F.panel.backdrop==nil); F.Config().borderSize=1; F.Apply()
FriendsFrame.numTabs=2; FriendsFrameTab1=CreateFrame('Button','FriendsFrameTab1',FriendsFrame); FriendsFrameTab2=CreateFrame('Button','FriendsFrameTab2',FriendsFrame)
FriendsFrame.selectedTab=2; F.TabAccent(); assert(F.tabLines[FriendsFrameTab2]:IsShown() and not F.tabLines[FriendsFrameTab1]:IsShown())
F.Config().accentColors=false; F.TabAccent(); assert(not F.tabLines[FriendsFrameTab2]:IsShown()); F.Config().accentColors=true
-- Auto-accept group invites from friends, Battle.net toons and (from the cog) guildmates.
accepts,hidden=0,nil; function AcceptGroup() accepts=accepts+1 end; function StaticPopup_Hide(n) hidden=n end
function GetNumFriends() return #friends end; function IsInGuild() return true end; function GetNumGuildMembers() return 1 end; function GetGuildRosterInfo() return 'Guildie' end
F.inviteFrame:RunScript('OnEvent','PARTY_INVITE_REQUEST','Mage'); assert(accepts==0)
F.Config().autoAcceptFriendInvites=true; F.Apply(); assert(F.inviteFrame.events.PARTY_INVITE_REQUEST)
F.inviteFrame:RunScript('OnEvent','PARTY_INVITE_REQUEST','Stranger'); F.inviteFrame:RunScript('OnEvent','PARTY_INVITE_REQUEST','Guildie'); assert(accepts==0)
F.inviteFrame:RunScript('OnEvent','PARTY_INVITE_REQUEST','Priest-Icecrown'); assert(accepts==1)
F.inviteFrame:RunScript('OnEvent','PARTY_MEMBERS_CHANGED'); assert(hidden=='PARTY_INVITE')
F.Config().autoAcceptGuildInvites=true; F.inviteFrame:RunScript('OnEvent','PARTY_INVITE_REQUEST','Guildie'); assert(accepts==2)
raidCount=5; F.inviteFrame:RunScript('OnEvent','PARTY_INVITE_REQUEST','Mage'); assert(accepts==2); raidCount=0
F.Config().autoAcceptFriendInvites=false; F.Config().autoAcceptGuildInvites=false; F.Apply(); assert(not F.inviteFrame.events.PARTY_INVITE_REQUEST)
assert(questTitle.text.font[3]=='OUTLINE' and objective.text.textColor[1]==.92 and Q.background:GetHeight()==104 and Q.background:IsShown() and WatchFrame:GetHeight()==500)
questComplete=true; objectiveComplete=true; WatchFrame_Update(); assert(questTitle.text.textColor[2]==1 and objective.text.textColor[2]==1)
questTitle:Hide(); objective:Hide(); Q.Visibility(); assert(not Q.background:IsShown()); questTitle:Show(); objective:Show()
-- Pre-checklist profiles migrate to the shared visibility keys.
Q.Config().visibility='outofcombat'; Q.Apply(); assert(Q.Config().visibility=='out_of_combat' and Q.driver=='[combat] hide; show')
Combat(true); local frameCount=#allFrames; F.Apply(); Q.Apply(); Q.Visibility(); assert(F.pending and Q.pending and #allFrames==frameCount and not WatchFrame:IsShown())
Combat(false); Q.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); Q.events:RunScript('OnUpdate',.1); assert(WatchFrame:IsShown())
Q.Config().visibility='always'; Q.Config().hideInRaidMode='always'; raidCount=10; Q.Apply(); assert(Q.driver=='hide')
Q.Config().hideInRaidMode='combat'; Q.Apply(); assert(Q.driver=='[group:raid,combat] hide; show')
Q.Config().hideInRaidMode='boss'; Q.Apply(); assert(Q.driver=='[group:raid,combat,@boss1,exists] hide; show')
Q.Config().hideInRaidMode='never'
-- Conditions that can flip mid-fight keep the driver open in combat and fade through alpha.
raidCount=0; Q.Config().visHideMounted=true; mounted=true; Q.Apply(); assert(Q.driver=='[combat] show; hide' and WatchFrame:GetAlpha()==0 and WatchFrameLinkButton1.mouseEnabled==false)
mounted=false; Q.Apply(); assert(Q.driver=='show' and WatchFrame:GetAlpha()==1 and WatchFrameLinkButton1.mouseEnabled==true)
Combat(true); mounted=true; Q.events:RunScript('OnEvent','COMPANION_UPDATE'); assert(WatchFrame:GetAlpha()==0 and Q.driver=='show')
mounted=false; Q.events:RunScript('OnEvent','COMPANION_UPDATE'); assert(WatchFrame:GetAlpha()==1); Combat(false); Q.events:RunScript('OnUpdate',.1)
Q.Config().visHideMounted=false
Q.Config().visOnlyInstances=true; Q.Apply(); assert(Q.driver=='hide'); instance=true; Q.Apply(); assert(Q.driver=='show')
Q.Config().visOnlyInstances=false; _EQT_SetSuppressed('test',true); assert(Q.driver=='hide'); _EQT_SetSuppressed('test',false); assert(Q.driver=='show')
-- Mouseover reveals on hover only, polled by the tracker's own updater.
Q.Config().visibility='mouseover'; Q.Apply(); assert(Q.driver=='show' and WatchFrame:GetAlpha()==0)
hovered=Q.background; Q.events:RunScript('OnUpdate',.15); assert(WatchFrame:GetAlpha()==1)
hovered=nil; Q.events:RunScript('OnUpdate',.15); assert(WatchFrame:GetAlpha()==0)
Q.Config().visibility='always'; Q.Apply(); assert(WatchFrame:GetAlpha()==1)
-- Retail hides the tracker in arenas regardless of the visibility rules.
instanceType='arena'; Q.Apply(); assert(Q.driver=='hide' and WatchFrame:GetAlpha()==0); instanceType=nil; Q.Apply(); assert(Q.driver=='show' and WatchFrame:GetAlpha()==1)
-- Font colours, focus highlight, header/line colour modes, background colour and header hide.
local p=Q.Config(); questComplete=false; objectiveComplete=false
p.objectiveR,p.objectiveG,p.objectiveB=.1,.2,.3; Q.Apply(); assert(objective.text.textColor[1]==.1 and objective.dash.textColor[3]==.3)
WatchFrameLinkButtonTemplate_Highlight(WatchFrameLinkButton1,true); assert(questTitle.text.textColor[1]==.871 and questTitle.text.textColor[3]==1)
WatchFrameLinkButtonTemplate_Highlight(WatchFrameLinkButton1,false); assert(questTitle.text.textColor[1]==1 and questTitle.text.textColor[2]==.91)
assert(Q.line.vertex[1]==.1 and Q.line.vertex[2]==.8 and WatchFrameTitle.textColor[1]==.1)
p.headerShowClassColor=true; p.lineUseAccent=false; p.lineR,p.lineG,p.lineB=.4,.5,.6; Q.Apply()
assert(WatchFrameTitle.textColor[1]==1 and WatchFrameTitle.textColor[2]==.5 and Q.headerLine.vertex[1]==.4 and Q.headerLine.vertex[3]==.6 and Q.line.vertex[1]==.1)
WatchFrameCollapseExpandButton:SetNormalTexture('toggle'); Q.Apply(); toggleTex=WatchFrameCollapseExpandButton:GetNormalTexture()
assert(toggleTex.desaturated and toggleTex.vertex[1]==1 and toggleTex.vertex[2]==.5 and Q.headerLine:IsShown())
local oldPrime,oldShadow=EllesmereUI.PrimeFontShadow,EllesmereUI.GetFontUseShadow; primed={}
function EllesmereUI.PrimeFontShadow(fs,on) primed[fs]=on end; function EllesmereUI.GetFontUseShadow(key) assert(key=='questTracker'); return true end
Q.Apply(); assert(primed[questTitle.text]==true and primed[WatchFrameTitle]==true); EllesmereUI.PrimeFontShadow,EllesmereUI.GetFontUseShadow=oldPrime,oldShadow
p.bgR,p.bgG,p.bgB=.2,.3,.4; p.bgAlpha=.5; Q.Apply(); assert(Q.fill.vertex[1]==.2 and Q.fill.vertex[4]==.5)
p.hideAllObjectivesHeader=true; Q.Apply(); assert(WatchFrameTitle:GetAlpha()==0 and WatchFrameCollapseExpandButton:GetAlpha()==0 and WatchFrameCollapseExpandButton.mouseEnabled==false and not Q.headerLine:IsShown())
p.hideAllObjectivesHeader=false; Q.Apply(); assert(WatchFrameTitle:GetAlpha()==1 and WatchFrameCollapseExpandButton.mouseEnabled==true)
p.objectiveR,p.objectiveG,p.objectiveB=.92,.92,.92; p.headerShowClassColor=false; p.lineUseAccent=true; p.bgAlpha=.75; Q.Apply()
Q.Config().questItemHotkey='ALT-X'; Q.Apply(); assert(overrides[Q.itemButton]['ALT-X'] and Q.itemButton:GetAttribute('clickbutton')==WatchFrameItem1)
-- Secure click delegation points at the untouched native quest-item handler.
Q.itemButton:GetAttribute('clickbutton'):RunScript('OnClick','LeftButton'); assert(nativeItemClicks==1)
WatchFrameItem1:Hide(); WatchFrameItem2:Show(); WatchFrame_Update(); Q.events:RunScript('OnUpdate',.1); assert(Q.itemButton:GetAttribute('clickbutton')==WatchFrameItem2)
Q.Config().questItemHotkey='ESCAPE'; Q.Apply(); assert(not next(overrides[Q.itemButton]))
-- Retail scans the quest log for a usable item, watched quests first; native watch items are the fallback.
questLog={{'Zone',true},{'Q1',false},{'Q2',false,'|cffffffff|Hitem:1|h[Bomb]|h|r',false},{'Q3',false,'|Hitem:2|h[Rope]|h',true}}
function GetNumQuestLogEntries() return #questLog end
function GetQuestLogTitle(i) return questLog[i][1],80,nil,nil,questLog[i][2] end
function GetQuestLogSpecialItemInfo(i) return questLog[i][3] end
function IsQuestWatched(i) return questLog[i][4] end
local oldNow=now; now=10
Q.Config().questItemHotkey='ALT-X'; Q.Apply(); local b=Q.itemButton
assert(b:GetAttribute('type')=='item' and b:GetAttribute('item')=='Rope' and not b:GetAttribute('clickbutton') and overrides[b]['ALT-X'].name=='EUI335QuestItemHotkey')
questLog[4][4]=false; Q.events:RunScript('OnEvent','QUEST_LOG_UPDATE'); Q.events:RunScript('OnUpdate',.1); assert(b:GetAttribute('item')=='Bomb')
-- Our own override write echoes UPDATE_BINDINGS (ignored); an external LoadBindings wipe is re-laid.
overrides[b]={}; Q.events:RunScript('OnEvent','UPDATE_BINDINGS'); Q.events:RunScript('OnUpdate',.1); assert(not next(overrides[b]))
now=20; Q.events:RunScript('OnEvent','UPDATE_BINDINGS'); Q.events:RunScript('OnUpdate',.1); assert(overrides[b]['ALT-X'])
questLog={}; Q.Apply(); assert(b:GetAttribute('type')=='click' and b:GetAttribute('clickbutton')==WatchFrameItem2)
WatchFrameItem2:Hide(); Q.Apply(); assert(not next(overrides[b]) and not b:GetAttribute('type')); WatchFrameItem2:Show(); now=oldNow
Q.Config().questItemHotkey='ESCAPE'; Q.Apply()
Q.Config().autoAccept=true; Q.Config().autoTurnIn=true
Q.QuestEvent('QUEST_DETAIL'); assert(accepted==1); shift=true; Q.QuestEvent('QUEST_DETAIL'); assert(accepted==1); shift=false
completable=true; Q.QuestEvent('QUEST_PROGRESS'); Q.QuestEvent('QUEST_COMPLETE'); assert(completed==1 and rewarded==1)
choices=2; Q.QuestEvent('QUEST_COMPLETE'); assert(rewarded==1); choices=0
questMoney=1; Q.QuestEvent('QUEST_PROGRESS'); Q.QuestEvent('QUEST_COMPLETE'); assert(completed==1 and rewarded==1); questMoney=0
questItems=1; Q.QuestEvent('QUEST_PROGRESS'); Q.QuestEvent('QUEST_COMPLETE'); assert(completed==1 and rewarded==1); questItems=0
Combat(true); Q.QuestEvent('QUEST_DETAIL'); assert(accepted==1); Combat(false)
-- Retail turns in single-reward quests and drives gossip/greeting pickers (Prevent Multi Quest Accept).
choices=1; Q.QuestEvent('QUEST_COMPLETE'); assert(rewarded==2 and rewardIndex==1); choices=0
gossipActive={{'Pending',false},{'Ready',true}}; Q.QuestEvent('GOSSIP_SHOW'); assert(gossipPicks[1]=='active2')
activeStride=3; Q.QuestEvent('GOSSIP_SHOW'); assert(#gossipPicks==1); activeStride=4; gossipActive={}
npcGUID='A'; gossipAvailableCount=2; Q.QuestEvent('GOSSIP_SHOW'); assert(#gossipPicks==1)
gossipAvailableCount=1; Q.QuestEvent('GOSSIP_SHOW'); assert(#gossipPicks==1)
npcGUID='B'; Q.QuestEvent('GOSSIP_SHOW'); assert(gossipPicks[2]=='available1')
shift=true; npcGUID='C'; Q.QuestEvent('GOSSIP_SHOW'); assert(#gossipPicks==2); shift=false
Q.Config().autoAcceptPreventMulti=false; npcGUID='A'; gossipAvailableCount=3; Q.QuestEvent('GOSSIP_SHOW'); assert(gossipPicks[3]=='available1')
gossipAvailableCount=0; greetingCount=1; Q.QuestEvent('QUEST_GREETING'); assert(gossipPicks[4]=='greeting1')
Combat(true); Q.QuestEvent('QUEST_GREETING'); assert(#gossipPicks==4); Combat(false); greetingCount=0; Q.Config().autoAcceptPreventMulti=true
local link=EllesmereUI._ELEMENT_SETTINGS_MAP.EQT_Tracker; assert(link.module=='EllesmereUIQuestTracker' and link.page=='Quest Tracker' and link.sectionName=='DISPLAY' and link.highlightText=='Visibility')
local p=Q.Config(); p.unlockPos={point='TOPRIGHT',relPoint='TOPRIGHT',x=-100,y=-300}; Q.Apply(); assert(select(4,WatchFrame:GetPoint())==-100)
p.enabled=false; Q.Apply(); assert(not Q.driver and not Q.background:IsShown() and not next(overrides[Q.itemButton]) and WatchFrame:GetHeight()==140 and WatchFrame:GetWidth()==204 and objective.text.font[1]=='original-font')
assert(not toggleTex.desaturated and toggleTex.vertex[1]==1 and toggleTex.vertex[2]==1)
p.enabled=true; Q.Apply(); assert(WatchFrame:GetWidth()==306)
function EllesmereUI.ResolveFontName(name) return 'custom/'..name end
function EllesmereUI.GetModuleFontEntry(key) return fontEntries and fontEntries[key] end
function EllesmereUI.GetFontOutlineFlag() return 'THICKOUTLINE, SLUG' end
fontEntries={questTracker={outline='thick'},friends={outline='thick'}}
p.font='TestFace'; p.titleFontSize=15; Q.EQT.RestyleAll()
assert(questTitle.text.font[1]=='custom/TestFace' and questTitle.text.font[2]==15 and questTitle.text.font[3]=='THICKOUTLINE')
F.Apply(); assert(row.name.font[3]=='THICKOUTLINE')
fontEntries=nil; p.font=nil; Q.Apply(); F.Apply()
''')
for file in ['EUI_Friends_335_Options.lua','EUI_QuestTracker_335_Options.lua']:
    lua.execute((root/'EllesmereUIOptions'/file).read_text())
lua.execute('''
modules.EllesmereUIFriends.buildPage('Friends',UIParent,0); FindRow('Show Class Icons').setValue(true); assert(F.Config().showClassIcons)
FindRow('Class Icon Theme').setValue('glyph'); assert(F.Config().iconStyle=='glyph' and FindRow('Class Icon Theme').values.runic and #FindRow('Class Icon Theme').order==9)
FindRow('Border Size').setValue(2); assert(F.panel.backdrop.edgeSize==2); local bc=FindRow('Border Color')
bc.swatches[2].onClick(); assert(F.Config().useClassColor and bc.swatches[2].refreshAlpha()==1); bc.swatches[1].onClick(); assert(not F.Config().useClassColor)
bc.swatches[1].setValue(.2,.3,.4); assert(F.panel.borderColor[2]==.3); FindRow('Border Size').setValue(0); assert(bc.disabled()); FindRow('Border Size').setValue(1)
FindRow('Enable Faction Banners').setValue(true); assert(F.Config().factionBanners); FindRow('Enable Faction Banners').setValue(false)
FindRow('Auto-Accept Friend Invites').setValue(true); assert(F.inviteFrame.events.PARTY_INVITE_REQUEST); FindRow('Auto-Accept Friend Invites').setValue(false)
assert(FindRow('Enable Accent Colors') and FindRow('Window Scale') and FindRow('Name Font Size'))
function EllesmereUI:ToggleUnlockMode() unlockOpened=true end
-- Retail-layout rows: real half regions so inline swatches and cogs attach.
local W=EllesmereUI.Widgets; local oldRow=W.DualRow; swatches={}; cogs={}
local function Half(row,cfg) local r=CreateFrame('Frame',nil,row); r._control=CreateFrame('Frame',nil,r); r.cfg=cfg; return r end
function W:DualRow(parent,y,a,b) local row=CreateFrame('Frame',nil,parent); row._leftRegion,row._rightRegion=Half(row,a),Half(row,b); rows[#rows+1]=a; rows[#rows+1]=b; return row,50 end
function EllesmereUI.BuildColorSwatch(rgn,level,get,set) local sw=CreateFrame('Button',nil,rgn); sw.get,sw.set=get,set; swatches[rgn.cfg.text]=sw; return sw,function() end end
function EllesmereUI.BuildInlineCog(rgn,opts) cogs[opts.title]=opts; return CreateFrame('Button',nil,rgn) end
function EllesmereUI.RegisterWidgetRefresh() end
function EllesmereUI.BuildFontDropdownData() return {__global='Global',TestFace='Test Face'},{'__global','TestFace'} end
rows={}; local height=modules.EllesmereUIQuestTracker.buildPage('Quest Tracker',UIParent,0); assert(height>0)
FindRow('Wide Tracker').setValue(false); assert(WatchFrame:GetWidth()==204)
local force=Q.Config().forceOnScreen; Q.optionsLink:RunScript('OnClick'); assert(unlockOpened and Q.Config().forceOnScreen==not force and WatchFrame:IsClampedToScreen()==Q.Config().forceOnScreen)
Q.optionsLink:RunScript('OnClick'); assert(Q.Config().forceOnScreen==force)
FindRow('Auto Turn In Quests').setValue(false); assert(not Q.Config().autoTurnIn)
assert(FindRow('Visibility').values.mouseover and FindRow('Hide When In Raid').values.boss and FindRow(EllesmereUI._ELEMENT_SETTINGS_MAP.EQT_Tracker.highlightText))
swatches['Objective Color'].set(.3,.4,.5); assert(Q.Config().objectiveR==.3 and objective.text.textColor[2]==.4)
assert(select(3,swatches['Focused Color'].get())==1 and swatches['Title Color'].get()==1 and select(2,swatches['Completed Color'].get())==1)
swatches['Background Opacity'].set(.1,.1,.1); assert(Q.fill.vertex[1]==.1)
local header=FindRow('Header Color').swatches; header[1].onClick(); assert(Q.Config().headerShowClassColor and header[1].refreshAlpha()==1 and header[3].refreshAlpha()==.3)
header[3].onClick(); assert(not Q.Config().headerShowClassColor and Q.Config().headerUseAccent and header[3].refreshAlpha()==1)
FindRow('Line Color').swatches[2].setValue(.7,.6,.5); assert(Q.Config().lineUseAccent==false and Q.headerLine.vertex[1]==.7)
FindRow('Hide All Objectives').setValue(true); assert(WatchFrameTitle:GetAlpha()==0); FindRow('Hide All Objectives').setValue(false)
local accept=cogs['Auto Accept Settings'].rows; assert(accept[1].label=='Prevent Multi Quest Accept' and accept[2].label=='Hold Shift to Skip' and cogs['Auto Turn In Settings'].rows[1].get())
accept[1].set(false); assert(Q.Config().autoAcceptPreventMulti==false); accept[1].set(true)
cogs['Font Settings'].rows[1].set('THICKOUTLINE'); assert(questTitle.text.font[3]=='THICKOUTLINE'); cogs['Font Settings'].rows[1].set('OUTLINE')
FindRow('Quest Item Hotkey').setValue('ALT-Q'); assert(Q.Config().questItemHotkey=='ALT-Q'); FindRow('Quest Item Hotkey').setValue('')
FindRow('Enable Quest Tracker').setValue(false); assert(not Q.background:IsShown()); FindRow('Enable Quest Tracker').setValue(true)
-- Blizzard/Classic style: Retail drops the EllesmereUI-only background, font and colour rows.
EllesmereUI.BlizzStyle={Get=function(key) assert(key=='questtracker'); return true end,Note=function(_,y,key) noted=key=='questtracker'; return y-40 end}
rows={}; modules.EllesmereUIQuestTracker.buildPage('Quest Tracker',UIParent,0)
assert(noted and FindRow('Hide All Objectives') and FindRow('Auto Accept Quests') and not pcall(FindRow,'Background Opacity') and not pcall(FindRow,'Title Color'))
EllesmereUI.BlizzStyle=nil; W.DualRow=oldRow
SlashCmdList.EQT('hide'); assert(not Q.Config().enabled); SlashCmdList.EQT('toggle'); assert(Q.Config().enabled)
SlashCmdList.EQT(); assert(shownModule=='EllesmereUIQuestTracker'); SlashCmdList.EFRIENDS(); assert(shownModule=='EllesmereUIFriends')
assert(#lifecycleErrors==0,lifecycleErrors[1])
''')
for folder in ['EllesmereUIFriends','EllesmereUIQuestTracker']:
    original=Path('D:/World of Warcraft/_retail_/Interface/AddOns')/folder
    for file in original.rglob('*'):
        if file.is_file() and file.suffix!='.toc': assert file.read_bytes()==(root/folder/file.relative_to(original)).read_bytes()
print('PASS: real Lite lifecycle/combat-login deferral; native social actions and localized/recycled/offline class rows; reversible styles; native quest/achievement line hooks, readable fonts, content-sized background, visibility/state drivers, item hotkey updates, unlock/profile restoration, optional quest helpers with Shift/reward/cost/combat guards, both Options pages and unchanged Retail Lua/media.')
