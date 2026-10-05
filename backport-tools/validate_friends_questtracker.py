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
function GetQuestReward(index) assert(index==0); rewarded=rewarded+1 end
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
FriendsFrame_SetButton(row,3); assert(row.name.textColor[1]==.6 and not F.rows[row].icon:IsShown())
F.Config().showClassIcons=false; FriendsFrame_SetButton(row,1); assert(not F.rows[row].icon:IsShown())
F.Config().classColorNames=false; F.Apply(); assert(row.name.textColor[1]==1 and row.name.textColor[3]==.65)
local late=FriendRow(2); F.Apply(); assert(F.rows[late] and late.name.font[3]=='OUTLINE')
local oldPanel=F.panel; F.Config().scale=1.2; F.Apply(); F.Apply(); assert(F.panel==oldPanel and FriendsFrame:GetScale()==1.2)
F.Config().enabled=false; F.Apply(); assert(not F.panel:IsShown() and art:GetAlpha()==.8 and FriendsFrame:GetScale()==1 and row.name.font[1]=='original-font')
F.Config().enabled=true; F.Config().useBlizzardStyle=true; F.Apply(); assert(not F.panel:IsShown() and F.FR_Style()=='blizzard')
F.Config().useBlizzardStyle=false; F.Apply()
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
-- Font colours, focus highlight, header/line colour modes, background colour and header hide.
local p=Q.Config(); questComplete=false; objectiveComplete=false
p.objectiveR,p.objectiveG,p.objectiveB=.1,.2,.3; Q.Apply(); assert(objective.text.textColor[1]==.1 and objective.dash.textColor[3]==.3)
WatchFrameLinkButtonTemplate_Highlight(WatchFrameLinkButton1,true); assert(questTitle.text.textColor[1]==.871 and questTitle.text.textColor[3]==1)
WatchFrameLinkButtonTemplate_Highlight(WatchFrameLinkButton1,false); assert(questTitle.text.textColor[1]==1 and questTitle.text.textColor[2]==.91)
assert(Q.line.vertex[1]==.1 and Q.line.vertex[2]==.8 and WatchFrameTitle.textColor[1]==.1)
p.headerShowClassColor=true; p.lineUseAccent=false; p.lineR,p.lineG,p.lineB=.4,.5,.6; Q.Apply()
assert(WatchFrameTitle.textColor[1]==1 and WatchFrameTitle.textColor[2]==.5 and Q.line.vertex[1]==.4 and Q.line.vertex[3]==.6)
p.bgR,p.bgG,p.bgB=.2,.3,.4; p.bgAlpha=.5; Q.Apply(); assert(Q.fill.vertex[1]==.2 and Q.fill.vertex[4]==.5)
p.hideAllObjectivesHeader=true; Q.Apply(); assert(WatchFrameTitle:GetAlpha()==0 and WatchFrameCollapseExpandButton:GetAlpha()==0 and WatchFrameCollapseExpandButton.mouseEnabled==false)
p.hideAllObjectivesHeader=false; Q.Apply(); assert(WatchFrameTitle:GetAlpha()==1 and WatchFrameCollapseExpandButton.mouseEnabled==true)
p.objectiveR,p.objectiveG,p.objectiveB=.92,.92,.92; p.headerShowClassColor=false; p.lineUseAccent=true; p.bgAlpha=.75; Q.Apply()
Q.Config().questItemHotkey='ALT-X'; Q.Apply(); assert(overrides[Q.itemButton]['ALT-X'] and Q.itemButton:GetAttribute('clickbutton')==WatchFrameItem1)
-- Secure click delegation points at the untouched native quest-item handler.
Q.itemButton:GetAttribute('clickbutton'):RunScript('OnClick','LeftButton'); assert(nativeItemClicks==1)
WatchFrameItem1:Hide(); WatchFrameItem2:Show(); WatchFrame_Update(); Q.events:RunScript('OnUpdate',.1); assert(Q.itemButton:GetAttribute('clickbutton')==WatchFrameItem2)
Q.Config().questItemHotkey='ESCAPE'; Q.Apply(); assert(not next(overrides[Q.itemButton]))
Q.Config().autoAccept=true; Q.Config().autoTurnIn=true
Q.QuestEvent('QUEST_DETAIL'); assert(accepted==1); shift=true; Q.QuestEvent('QUEST_DETAIL'); assert(accepted==1); shift=false
completable=true; Q.QuestEvent('QUEST_PROGRESS'); Q.QuestEvent('QUEST_COMPLETE'); assert(completed==1 and rewarded==1)
choices=2; Q.QuestEvent('QUEST_COMPLETE'); assert(rewarded==1); choices=0
questMoney=1; Q.QuestEvent('QUEST_PROGRESS'); Q.QuestEvent('QUEST_COMPLETE'); assert(completed==1 and rewarded==1); questMoney=0
questItems=1; Q.QuestEvent('QUEST_PROGRESS'); Q.QuestEvent('QUEST_COMPLETE'); assert(completed==1 and rewarded==1); questItems=0
Combat(true); Q.QuestEvent('QUEST_DETAIL'); assert(accepted==1); Combat(false)
local p=Q.Config(); p.unlockPos={point='TOPRIGHT',relPoint='TOPRIGHT',x=-100,y=-300}; Q.Apply(); assert(select(4,WatchFrame:GetPoint())==-100)
p.enabled=false; Q.Apply(); assert(not Q.driver and not Q.background:IsShown() and not next(overrides[Q.itemButton]) and WatchFrame:GetHeight()==140 and WatchFrame:GetWidth()==204 and objective.text.font[1]=='original-font')
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
modules.EllesmereUIFriends.buildPage('Friends',UIParent,0); FindRow('Class Icons').setValue(true); assert(F.Config().showClassIcons)
function EllesmereUI:ToggleUnlockMode() unlockOpened=true end
rows={}; modules.EllesmereUIQuestTracker.buildPage('Quest Tracker',UIParent,0); FindRow('Wide Tracker').setValue(false); assert(WatchFrame:GetWidth()==204)
buttons['Move In Unlock Mode'](); assert(unlockOpened)
FindRow('Auto Turn In Quests').setValue(false); assert(not Q.Config().autoTurnIn)
assert(FindRow('Visibility').values.mouseover and FindRow('Hide When In Raid').values.boss)
FindRow('Objective Color').setValue(.3,.4,.5); assert(Q.Config().objectiveR==.3 and objective.text.textColor[2]==.4)
assert(select(3,FindRow('Focused Color').getValue())==1 and FindRow('Title Color').getValue()==1)
local header=FindRow('Header Color').swatches; header[1].onClick(); assert(Q.Config().headerShowClassColor and header[1].refreshAlpha()==1 and header[3].refreshAlpha()==.3)
header[3].onClick(); assert(not Q.Config().headerShowClassColor and Q.Config().headerUseAccent and header[3].refreshAlpha()==1)
FindRow('Line Color').swatches[2].setValue(.7,.6,.5); assert(Q.Config().lineUseAccent==false and Q.line.vertex[1]==.7)
FindRow('Hide Objectives Header').setValue(true); assert(WatchFrameTitle:GetAlpha()==0); FindRow('Hide Objectives Header').setValue(false)
SlashCmdList.EQT(); assert(shownModule=='EllesmereUIQuestTracker'); SlashCmdList.EFRIENDS(); assert(shownModule=='EllesmereUIFriends')
assert(#lifecycleErrors==0,lifecycleErrors[1])
''')
for folder in ['EllesmereUIFriends','EllesmereUIQuestTracker']:
    original=Path('D:/World of Warcraft/_retail_/Interface/AddOns')/folder
    for file in original.rglob('*'):
        if file.is_file() and file.suffix!='.toc': assert file.read_bytes()==(root/folder/file.relative_to(original)).read_bytes()
print('PASS: real Lite lifecycle/combat-login deferral; native social actions and localized/recycled/offline class rows; reversible styles; native quest/achievement line hooks, readable fonts, content-sized background, visibility/state drivers, item hotkey updates, unlock/profile restoration, optional quest helpers with Shift/reward/cost/combat guards, both Options pages and unchanged Retail Lua/media.')
