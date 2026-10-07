"""Real Chat module/Core lifecycle and native FrameXML entry points on Lua 5.1."""
from pathlib import Path
import sys,re
root=Path(__file__).resolve().parents[1]
retail=Path('D:/World of Warcraft/_retail_/Interface/AddOns/EllesmereUIChat')
for original in retail.rglob('*'):
    if original.is_file() and original.suffix.lower()!='.toc':
        assert original.read_bytes()==(root/'EllesmereUIChat'/original.relative_to(retail)).read_bytes(),original
for icon in ['copy','durability','friends','guild','scroll2','settings','voice']:
    data=(root/'EllesmereUIChat/Media_335'/('chat_'+icon+'.tga')).read_bytes()
    # Uncompressed 32-bit true-colour TGA, power-of-two size for the Wrath client.
    assert data[2]==2 and data[16]==32 and int.from_bytes(data[12:14],'little')==64 and int.from_bytes(data[14:16],'little')==64,icon
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
def native_function(file,name):
    source=(root/'backport-tools/framexml-chat'/file).read_text(encoding='utf-8-sig')
    match=re.search(r'^function '+name+r'\(.*?(?=^function |\Z)',source,re.M|re.S)
    assert match,name
    # Keep just the complete top-level body, not later file-scope statements.
    return match[0].split('\nend',1)[0]+'\nend'
NATIVE=[('ChatFrame.lua','ChatFrame_OnHyperlinkShow'),('FloatingChatFrame.lua','FloatingChatFrame_OnMouseScroll'),
    ('FloatingChatFrame.lua','FCF_SetChatWindowFontSize'),('FloatingChatFrame.lua','FCF_SetWindowAlpha'),
    ('FloatingChatFrame.lua','FCF_SetWindowColor'),('FloatingChatFrame.lua','FCFTab_UpdateColors'),
    ('FloatingChatFrame.lua','FCF_Tab_OnClick'),('FloatingChatFrame.lua','FCFDock_UpdateTabs'),
    ('FloatingChatFrame.lua','FCF_UpdateDockPosition')]
core=(root/'EllesmereUI/EllesmereUI_Lite.lua').read_text(encoding='utf-8-sig')
def boot(saved=''):
    lua=LuaRuntime()
    lua.execute((root/'backport-tools/wrath_mock.lua').read_text())
    for file,name in NATIVE: lua.execute(native_function(file,name))
    lua.execute((root/'backport-tools/chat_mock.lua').read_text())
    lua.execute(core)
    lua.execute('lifecycleErrors={}; function geterrorhandler() return function(err) lifecycleErrors[#lifecycleErrors+1]=err end end')
    safe_source='local function errorhandler('+core.split('local function errorhandler(',1)[1].split('\n-------------------------------------------------------------------------------',1)[0]
    safe=lua.execute(safe_source+'\nreturn safecall')
    lua.execute(saved)
    ns=lua.table()
    loader=lua.eval('function(s,n) return assert(loadstring(s,n)) end')
    loader((root/'EllesmereUIChat/EUI_Chat_335.lua').read_text(),'EUI_Chat_335.lua')('EllesmereUIChat',ns)
    loader((root/'EllesmereUIChat/EUI_Chat_SpamFilter_335.lua').read_text(),'EUI_Chat_SpamFilter_335.lua')('EllesmereUIChat',ns)
    lua.globals().CHAT=ns
    safe(ns.addon.OnInitialize,ns.addon); safe(ns.addon.OnEnable,ns.addon)
    lua.execute('assert(#lifecycleErrors==0,lifecycleErrors[1])')
    return lua
lua=boot('''
-- Confirm the fixture reproduces the native 50px bottom limit before styling.
ChatFrame1:ClearAllPoints(); ChatFrame1:SetPoint('BOTTOMLEFT',UIParent,'BOTTOMLEFT',40,0)
assert(ChatFrame1:GetBottom()==50)
ChatFrame1:ClearAllPoints(); ChatFrame1:SetPoint('BOTTOMLEFT',UIParent,'BOTTOMLEFT',40,60)
''')
lua.execute('''
local function near(a,b) return math.abs(a-b)<1e-6 end
local p=CHAT.GetSettings()
local s1,s2=CHAT.states[ChatFrame1],CHAT.states[ChatFrame2]
assert(p.enabled and _ECHAT_DB==CHAT.addon.db and unlockFolder=="EllesmereUIChat" and CHAT.ChatStyle()=="eui")
assert(ChatFrame1:GetWidth()==420 and ChatFrame1:GetHeight()==180)
assert(ChatFrame1:IsClampedToScreen() and select(4,ChatFrame1:GetClampRectInsets())==0)
assert(select(1,ChatFrame1:GetClampRectInsets())==-35 and select(2,ChatFrame1:GetClampRectInsets())==35 and select(3,ChatFrame1:GetClampRectInsets())==38)
assert(s1.clampInsets[4]==-50)
assert(ChatFrame1Background:GetAlpha()==0 and not ChatFrame1:GetFading())
assert(select(2,ChatFrame1:GetFont())==12 and select(3,ChatFrame1:GetFont())=="OUTLINE")
assert(not ChatFrame1EditBox:HasFocus() and not ChatFrame1EditBox:IsAutoFocus())
-- Retail panel: background, divider, input field below with the EUI gap.
assert(s1.panel:IsShown() and s1.bg.vertex[1]==.03 and s1.bg.vertex[4]==.65)
local a,rel,b,x,y=s1.panel:GetPoint(1); assert(a=="TOPLEFT" and rel==ChatFrame1 and x==-6 and y==4)
a,rel,b,x,y=s1.panel:GetPoint(2); assert(a=="BOTTOMRIGHT" and x==6 and y==-29)
assert(select(2,s2.panel:GetPoint(1))==ChatFrame1)
a,rel,b,x,y=ChatFrame1EditBox:GetPoint(1); assert(a=="TOPLEFT" and b=="BOTTOMLEFT" and x==-6 and y==-6 and ChatFrame1EditBox:GetHeight()==23)
assert(ChatFrame1EditBoxLeft:GetAlpha()==0 and s1.divider:IsShown())
assert(not ChatFrame1.buttonFrame:IsShown() and not ChatFrameMenuButton:IsShown() and not FriendsMicroButton:IsShown())
ChatFrame1.buttonFrame:Show(); ChatFrameMenuButton:Show(); assert(not ChatFrame1.buttonFrame:IsShown() and not ChatFrameMenuButton:IsShown())
ChatFrame1EditBox:RunScript("OnEnterPressed"); assert(nativeSent==1)
ChatFrame1:RunScript("OnEvent"); assert(nativeEvents==1)
ChatFrame1.buttonFrame:RunScript("OnMouseDown"); assert(nativeButtonClicks==1)
-- URLs never nest inside links or texture escapes.
local originalLink="|cff00ff00|Hitem:123:0:0|h[www.item-name.com]|h|r"
assert(CHAT.LinkURLs(originalLink)==originalLink)
assert(CHAT.LinkURLs("|Twww.icon:16|t")=="|Twww.icon:16|t")
local url=CHAT.LinkURLs("visit https://example.com/a?b=2, and www.site.org!")
assert(url=="visit |cff0dd19c|Heuiurl:https://example.com/a?b=2|h[https://example.com/a?b=2]|h|r, and |cff0dd19c|Heuiurl:www.site.org|h[www.site.org]|h|r!",url)
assert(CHAT.LinkURLs(url)==url)
assert(CHAT.PlainText(originalLink)=="[www.item-name.com]")
-- Channel abbreviations and class-coloured names.
assert(CHAT.AbbreviateChannels("|Hchannel:channel:2|h[2. Trade - City]|h Bob: hi")=="|Hchannel:channel:2|h[2]|h Bob: hi")
assert(CHAT.AbbreviateChannels("|Hchannel:channel:2|h[2. Trade - City]|h Bob",true)=="|Hchannel:channel:2|h[T]|h Bob")
assert(CHAT.AbbreviateChannels("|Hchannel:PARTY|h[Party]|h Bob")=="|Hchannel:PARTY|h[P]|h Bob")
assert(#chatFilters.CHAT_MSG_SAY==3 and #chatFilters.CHAT_MSG_SYSTEM==1 and chatFilters.CHAT_MSG_SYSTEM[1]==CHAT.SpamFilter)
local keep,msg,extra=CHAT.NameFilter(ChatFrame1,"CHAT_MSG_SAY","hi player","Bob")
assert(keep==false and msg=="hi |cffff8033player|r" and extra=="Bob")
assert(CHAT.NameFilter(ChatFrame1,"CHAT_MSG_SAY","nobody here")==false and select(2,CHAT.NameFilter(ChatFrame1,"CHAT_MSG_SAY","nobody"))==nil)
-- Stamps: only filtered chat events by default, every line with Timestamp All.
assert(ChatFrame1:AddMessage("hello https://example.com",.2,.3,.4,17)=="native-result")
local message=ChatFrame1.messages[#ChatFrame1.messages]
assert(message[1]=="hello |cff0dd19c|Heuiurl:https://example.com|h[https://example.com]|h|r",message[1])
assert(message[2]==.2 and message[3]==.3 and message[4]==.4 and message[5]==17)
CHAT.StampFilter(ChatFrame1,"CHAT_MSG_SAY","said"); ChatFrame1:AddMessage("said")
assert(ChatFrame1.messages[#ChatFrame1.messages][1]=="13:07 said")
ChatFrame1:AddMessage("system"); assert(ChatFrame1.messages[#ChatFrame1.messages][1]=="system")
p.timestampAll=true; ChatFrame1:AddMessage("system"); assert(ChatFrame1.messages[#ChatFrame1.messages][1]=="13:07 system")
CHAT_TIMESTAMP_FORMAT="[%H:%M] "; BetterDate=function() return "[13:07] " end
ChatFrame1:AddMessage("[13:07] native"); assert(ChatFrame1.messages[#ChatFrame1.messages][1]=="13:07 native")
p.timestampFormat="__blizzard"; ChatFrame1:AddMessage("[13:07] native"); assert(ChatFrame1.messages[#ChatFrame1.messages][1]=="[13:07] native")
p.timestampFormat="none"; ChatFrame1:AddMessage("[13:07] native"); assert(ChatFrame1.messages[#ChatFrame1.messages][1]=="native")
CHAT_TIMESTAMP_FORMAT=nil; BetterDate=nil; p.timestampFormat="%I:%M "; p.timestampAll=false
ChatFrame1:AddMessage("|Hchannel:PARTY|h[Party]|h x"); assert(ChatFrame1.messages[#ChatFrame1.messages][1]=="|Hchannel:PARTY|h[P]|h x")
ChatFrame2:AddMessage("combat https://example.com"); assert(ChatFrame2.messages[1][1]=="combat https://example.com")
-- Links: native items, our URL popup at the cursor, tooltip on hover when enabled.
ChatFrame1:RunScript("OnHyperlinkClick","item:123",originalLink,"LeftButton")
assert(itemRef[1]=="item:123" and itemRef[4]==ChatFrame1)
ChatFrame1:RunScript("OnHyperlinkClick","euiurl:https://example.com","url","LeftButton")
assert(CHAT.urlPopup:IsShown() and CHAT.urlPopup.box:GetText()=="https://example.com" and CHAT.urlPopup.box:HasFocus())
CHAT.urlPopup.box:RunScript("OnEscapePressed")
assert(not CHAT.urlPopup:IsShown() and not CHAT.urlPopup.box:HasFocus())
ChatFrame1:RunScript("OnHyperlinkEnter","item:123",originalLink); assert(GameTooltip.link==nil)
p.hideTooltipOnHover=false; ChatFrame1:RunScript("OnHyperlinkEnter","item:123",originalLink)
assert(GameTooltip.link=="item:123" and GameTooltip:IsShown())
ChatFrame1:RunScript("OnHyperlinkLeave"); assert(not GameTooltip:IsShown())
ChatFrame1:RunScript("OnHyperlinkEnter","player:Bob",originalLink); assert(GameTooltip.link=="item:123" and not GameTooltip:IsShown())
p.hideTooltipOnHover=true
CHAT.CopyChat(ChatFrame1)
assert(CHAT.copyWindow:IsShown() and CHAT.copyWindow.box:GetText():find("hello [https://example.com]\\n13:07 said",1,true))
CHAT.copyWindow.close:RunScript("OnClick"); assert(not CHAT.copyWindow:IsShown() and not CHAT.copyWindow.box:HasFocus())
ChatFrame1:RunScript("OnMouseWheel",1); assert(ChatFrame1.scroll=="up")
shift=true; ChatFrame1:RunScript("OnMouseWheel",-1); assert(ChatFrame1.scroll=="bottom"); shift=false
-- A tab menu size choice becomes the profile size for every window.
FCF_SetChatWindowFontSize(nil,ChatFrame1,20)
assert(p.chatFontSize==20 and select(2,ChatFrame1:GetFont())==20 and select(2,ChatFrame3:GetFont())==20 and savedFontSize[2]==20)
FCF_SetWindowAlpha(ChatFrame1,.9); assert(ChatFrame1Background:GetAlpha()==0 and savedAlpha[2]==.9)
FCF_SetWindowColor(ChatFrame1,.5,.6,.7); assert(ChatFrame1Background:GetAlpha()==0)
local temp=FCF_OpenTemporaryWindow(); assert(CHAT.states[temp] and CHAT.states[temp].visual)
assert(select(4,temp:GetClampRectInsets())==0 and select(3,temp:GetClampRectInsets())==26)
temp:AddMessage("private"); assert(temp.messages[1][1]=="private")
''')
# Tabs, dock, sidebar, border, idle fade and the stock sidebar data.
lua.execute('''
local function near(a,b) return math.abs(a-b)<1e-6 end
local p=CHAT.GetSettings()
local s1,s2=CHAT.states[ChatFrame1],CHAT.states[ChatFrame2]
FCFDock_UpdateTabs(GENERAL_CHAT_DOCK,true)
assert(ChatFrame1Tab:GetWidth()==66 and ChatFrame2Tab:GetWidth()==84)
local a,rel,b,x,y=ChatFrame2Tab:GetPoint(1); assert(a=="LEFT" and rel==ChatFrame1Tab and b=="RIGHT" and x==1)
a,rel,b,x,y=GENERAL_CHAT_DOCK:GetPoint(1); assert(a=="BOTTOMLEFT" and rel==ChatFrame1 and x==-6 and y==7)
assert(select(2,GENERAL_CHAT_DOCK.scrollFrame:GetPoint(1))==ChatFrame2Tab)
assert(s1.visual:IsShown() and s1.visual:GetHeight()==24 and s1.visual.label:GetText()=="General")
assert(s1.visual.line:IsShown() and not s2.visual.line:IsShown() and s1.visual.edges[1]:IsShown())
assert(ChatFrame1Tab.leftTexture:GetAlpha()==0 and ChatFrame1TabText:GetAlpha()==0 and ChatFrame1Tab.glow:GetTexture()==nil)
ChatFrame2Tab:RunScript("OnClick","LeftButton")
assert(SELECTED_DOCK_FRAME==ChatFrame2 and s2.visual.line:IsShown() and not s1.visual.line:IsShown())
ChatFrame2Tab:RunScript("OnClick","RightButton"); assert(CURRENT_CHAT_FRAME_ID==2 and dropDownArgs[4]=="ChatFrame2Tab")
ChatFrame1Tab:RunScript("OnClick","LeftButton"); assert(SELECTED_DOCK_FRAME==ChatFrame1)
p.alignTabsToPanel=true; p.tabSpacing=4; p.tabHeight=30; CHAT.Apply()
assert(select(4,GENERAL_CHAT_DOCK:GetPoint(1))==-46 and select(4,ChatFrame2Tab:GetPoint(1))==4 and s1.visual:GetHeight()==30)
p.alignTabsToPanel=false; p.tabSpacing=1; p.tabHeight=24
p.inputOnTop=true; CHAT.Apply()
assert(ChatFrame1EditBox:GetPoint(1)=="BOTTOMLEFT" and select(5,GENERAL_CHAT_DOCK:GetPoint(1))==32)
assert(select(5,s1.panel:GetPoint(1))==29 and select(5,s1.panel:GetPoint(2))==-4)
p.inputOnTop=false; CHAT.Apply()
-- New-message glow becomes an accent tab label.
ChatFrame2Tab.glow:Show(); CHAT.driver:RunScript("OnUpdate",.2)
assert(s2.alert and s2.visual.label.textColor[1]==.05); ChatFrame2Tab.glow:Hide(); CHAT.driver:RunScript("OnUpdate",.2)
-- Sidebar: Retail icons, counts and clicks.
local sb,icons=CHAT.sidebar,CHAT.icons
assert(sb:IsShown() and sb:GetWidth()==40)
a,rel,b,x,y=sb:GetPoint(1); assert(a=="TOPRIGHT" and rel==ChatFrame1 and b=="TOPLEFT" and x==-6 and y==4)
assert(icons.showFriends:IsShown() and icons.showCopy:IsShown() and icons.showSettings:IsShown())
assert(not icons.showGuild:IsShown() and not icons.showVoice:IsShown() and not icons.showDurability:IsShown() and icons.showScroll:IsShown())
assert(icons.showFriends.icon:GetTexture()=="Interface\\\\AddOns\\\\EllesmereUIChat\\\\Media_335\\\\chat_friends")
assert(tostring(icons.showFriends.count:GetText())=="3")
assert(select(2,icons.showFriends:GetPoint(1))==sb and select(2,icons.showCopy:GetPoint(1))==icons.showFriends.count)
assert(select(2,icons.showSettings:GetPoint(1))==icons.showCopy)
-- Count events also reach hidden icons; their labels already carry a font.
CHAT.countEvents:RunScript("OnEvent","GUILD_ROSTER_UPDATE"); assert(tostring(icons.showGuild.count:GetText())=="2")
p.bgAlpha=0; CHAT.Apply(); assert(p.bgAlpha==0 and CHAT.states[ChatFrame1].bg.vertex[4]==0); p.bgAlpha=.65; CHAT.Apply()
p.showGuild=true; p.showDurability=true; p.showVoice=true; CHAT.Apply()
assert(tostring(icons.showGuild.count:GetText())=="2" and guildRosterCalls==1 and icons.showDurability.count:GetText()=="50%")
icons.showVoice:RunScript("OnClick"); assert(friendsTab==4)
icons.showGuild:RunScript("OnClick"); assert(friendsTab==3)
icons.showFriends:RunScript("OnClick"); assert(friendsTab==1)
icons.showCopy:RunScript("OnClick"); assert(CHAT.copyWindow:IsShown()); CHAT.copyWindow:Hide()
shownModule=nil; icons.showSettings:RunScript("OnClick"); assert(shownModule=="EllesmereUIChat")
ChatFrame1.scroll=nil; icons.showScroll:RunScript("OnClick"); assert(ChatFrame1.scroll=="bottom")
icons.showCopy:RunScript("OnEnter"); assert(GameTooltip.tipText=="Copy Chat" and near(icons.showCopy.icon.vertex[4],.9))
icons.showCopy:RunScript("OnLeave"); assert(not GameTooltip:IsShown())
p.showGuild=false; p.showDurability=false; p.showVoice=false
p.sidebarIconOrder={showSettings=1,showCopy=2}; CHAT.Apply()
assert(select(2,icons.showSettings:GetPoint(1))==icons.showFriends.count and select(2,icons.showCopy:GetPoint(1))==icons.showSettings)
p.freeMoveIcons=true; p.iconPositions={showCopy={x=3,y=-50}}; CHAT.Apply()
a,rel,b,x,y=icons.showCopy:GetPoint(1); assert(a=="TOP" and rel==sb and x==3 and y==-50)
icons.showSettings:RunScript("OnDragStart"); assert(icons.showSettings.moving)
icons.showSettings:RunScript("OnDragStop"); assert(p.iconPositions.showSettings and icons.showSettings.justDragged)
icons.showSettings:RunScript("OnClick"); assert(not icons.showSettings.justDragged)
p.freeMoveIcons=false; p.iconPositions={}; p.sidebarIconOrder={showCopy=1,showVoice=3,showSettings=4}
p.sidebarRight=true; CHAT.Apply()
a,rel,b,x,y=sb:GetPoint(1); assert(a=="TOPLEFT" and b=="TOPRIGHT" and x==6 and y==4)
p.sidebarRight=false; p.sidebarVisibility="never"; CHAT.Apply()
assert(not sb:IsShown() and not icons.showScroll:IsShown())
p.scrollButtonOnChat=true; CHAT.Apply(); assert(icons.showScroll:IsShown() and select(2,icons.showScroll:GetPoint(1))==ChatFrame1)
p.scrollButtonOnChat=false; p.sidebarVisibility="always"; CHAT.Apply(); assert(sb:IsShown())
-- One border around the panel and the attached sidebar; synced tab borders.
p.panelBorderThickness="thin"; CHAT.Apply()
assert(borderCalls[s1.border][1]==1 and s1.border:IsShown() and select(2,s1.border:GetPoint(1))==sb)
assert(borderCalls[s1.visual.border] and borderCalls[s1.visual.border][1]==1)
p.panelBorderThickness="none"; CHAT.Apply(); assert(not s1.border:IsShown())
-- Lock size hides the native resize grip until unlocked.
p.lockChatSize=true; CHAT.Apply(); assert(not ChatFrame1ResizeButton:IsShown())
ChatFrame1ResizeButton:Show(); assert(not ChatFrame1ResizeButton:IsShown())
p.lockChatSize=false; CHAT.Apply(); assert(ChatFrame1ResizeButton:IsShown())
-- Idle fade, hover, typing and visibility; hidden chat passes clicks through.
now=now+20; CHAT.driver:RunScript("OnUpdate",5)
assert(near(ChatFrame1:GetAlpha(),.6) and near(sb.alpha,.6) and near(s1.visual.alpha,.6))
hover[ChatFrame1]=true; CHAT.driver:RunScript("OnUpdate",5); assert(ChatFrame1:GetAlpha()==1); hover[ChatFrame1]=nil
p.visibility="never"; CHAT.driver:RunScript("OnUpdate",5)
assert(ChatFrame1:GetAlpha()==0 and ChatFrame1Tab.mouse==false and ChatFrame1.hyperlinks==false and icons.showCopy.mouse==false)
activeEdit=ChatFrame1EditBox; CHAT.driver:RunScript("OnUpdate",5)
assert(ChatFrame1:GetAlpha()==1 and ChatFrame1Tab.mouse==true and ChatFrame1.hyperlinks==true); activeEdit=nil
p.visibility="always"; p.sidebarVisibility="mouseover"; CHAT.driver:RunScript("OnUpdate",5); assert(sb.alpha==0)
hover[sb]=true; CHAT.driver:RunScript("OnUpdate",5); assert(sb.alpha==1); hover[sb]=nil
p.sidebarVisibility="always"; CHAT.driver:RunScript("OnUpdate",5)
-- Whisper sound and remembered history.
p.whisperSoundKey="airhorn"; now=now+5; CHAT.events:RunScript("OnEvent","CHAT_MSG_WHISPER","hi")
assert(playedSound=="Interface\\\\sounds\\\\airhorn.ogg"); playedSound=nil
CHAT.events:RunScript("OnEvent","CHAT_MSG_WHISPER","hi"); assert(playedSound==nil); p.whisperSoundKey="none"
CHAT.events:RunScript("OnEvent","PLAYER_LOGOUT")
local saved=EllesmereUIChatScrollDB.frames
assert(saved.ChatFrame1 and #saved.ChatFrame1<=100 and saved.ChatFrame2==nil and saved.ChatFrame11==nil)
assert(saved.ChatFrame1[#saved.ChatFrame1].t==s1.lines[#s1.lines])
p.persistChatHistory=false; CHAT.SaveHistory(); assert(EllesmereUIChatScrollDB==nil); p.persistChatHistory=true
''')
# Chat bubbles: Wrath WorldFrame bubbles, CVars, per-channel style and restore.
lua.execute('''
local bubble=CreateFrame("Frame",nil,WorldFrame); bubble:SetBackdrop({bgFile="Interface\\\\Tooltips\\\\ChatBubble-Background"})
local bfs=bubble:CreateFontString(); bfs:SetFont("bubble.ttf",14,""); bfs:SetText("hello there")
local tail=bubble:CreateTexture(); tail:SetTexture("Interface\\\\Tooltips\\\\ChatBubble-Tail")
local named=CreateFrame("Frame","NamedWorldThing",WorldFrame); named:SetBackdrop({bgFile="Interface\\\\Tooltips\\\\ChatBubble-Background"})
local b=CHAT.GetBubbleSettings()
assert(cvars.chatBubbles=="0" and CHAT.bubbles[bubble]==nil)
b.enabled=true; CHAT.ApplyBubbles()
assert(cvars.chatBubbles=="1" and cvars.chatBubblesParty=="1" and b._savedCVars.chatBubbles=="0")
local d=CHAT.bubbles[bubble]; assert(d and d.styled and CHAT.bubbles[named]==false)
assert(bubble:GetBackdrop()==nil and tail:GetAlpha()==0 and select(2,bfs:GetFont())==12 and d.bg:IsShown() and d.edges[1]:IsShown())
b.yell=false; bfs:SetText("shout"); CHAT.events:RunScript("OnEvent","CHAT_MSG_YELL","shout")
assert(CHAT.bubbleScan:IsShown()); CHAT.bubbleScan:RunScript("OnUpdate",.1)
assert(not d.styled and bubble:GetBackdrop().bgFile:find("ChatBubble") and tail:GetAlpha()==1 and select(2,bfs:GetFont())==14 and not d.bg:IsShown())
b.yell=true; CHAT.ApplyBubbles(); assert(d.styled)
b.hideInInstances=true; inInstance=true; CHAT.events:RunScript("OnEvent","ZONE_CHANGED_NEW_AREA")
assert(cvars.chatBubbles=="0" and cvars.chatBubblesParty=="0")
inInstance=false; CHAT.ApplyBubbles(); assert(cvars.chatBubbles=="1")
b.enabled=false; CHAT.ApplyBubbles()
assert(cvars.chatBubbles=="0" and cvars.chatBubblesParty=="0" and b._savedCVars==nil and not d.styled and bubble:GetBackdrop())
-- NPC bubbles that anchor the frame to its own text must not get the text anchored back.
local npc=CreateFrame("Frame",nil,WorldFrame); npc:SetBackdrop({bgFile="Interface\\\\Tooltips\\\\ChatBubble-Background"})
local nfs=npc:CreateFontString(); nfs:SetFont("bubble.ttf",14,""); nfs:SetText("Firalaine ruftos")
nfs:SetPoint("TOPLEFT",npc,"TOPLEFT",8,-8); npc:SetPoint("CENTER",nfs,"CENTER",0,0)
local setPoint=nfs.SetPoint
nfs.SetPoint=function(self,point,rel,...)
    for i=1,rel and rel.GetNumPoints and rel:GetNumPoints() or 0 do
        assert(select(2,rel:GetPoint(i))~=self,"circular bubble anchor")
    end
    return setPoint(self,point,rel,...)
end
b.enabled=true; CHAT.ApplyBubbles()
local nd=CHAT.bubbles[npc]; assert(nd and nd.styled and npc:GetBackdrop()==nil and nd.bg:IsShown())
b.enabled=false; CHAT.ApplyBubbles(); assert(not nd.styled and npc:GetBackdrop())
''')
# Unlock, clamps, combat deferral, restore/re-enable and external wrappers.
lua.execute('''
local p=CHAT.GetSettings()
local temp=ChatFrame11
local elem=unlockElements[1]
assert(elem.key=="ECHAT_MainChat" and elem.onLiveMove and EllesmereUI._unlockModeListeners.EllesmereUIChat)
local link=EllesmereUI._ELEMENT_SETTINGS_MAP.ECHAT_MainChat
assert(link.module=="EllesmereUIChat" and link.page=="Chat" and link.sectionName=="DISPLAY" and link.highlightText=="Main Chat Width")
-- Without user placement the stock dock code adds its corner point to ours.
assert(not ChatFrame1:IsUserPlaced())
elem.savePos(nil,"CENTER","CENTER",-300,-200)
assert(ChatFrame1:GetPoint(1)=="CENTER" and select(4,ChatFrame1:GetPoint(1))==-300 and ChatFrame1:IsUserPlaced())
FCF_UpdateDockPosition(); assert(ChatFrame1:GetNumPoints()==1)
-- In a session the drag owns the frame; save lands on close via the listener.
EllesmereUI._unlockActive=true
ChatFrame1:ClearAllPoints(); ChatFrame1:SetPoint("TOPLEFT",UIParent,"TOPLEFT",10,-700); elem.onLiveMove()
elem.savePos(nil,"CENTER","CENTER",-100,-50); assert(ChatFrame1:GetPoint(1)=="TOPLEFT")
EllesmereUI._unlockActive=false; EllesmereUI._unlockModeListeners.EllesmereUIChat(false,"save")
assert(ChatFrame1:GetPoint(1)=="CENTER" and select(4,ChatFrame1:GetPoint(1))==-100 and ChatFrame1:GetNumPoints()==1)
unlockElements[1].savePos(nil,"CENTER","BOTTOMLEFT",500,250); CHAT.Apply(); assert(ChatFrame1:GetPoint(1)=="CENTER")
-- Live drag can reach Y=0 and its saved anchor survives profile/world reapply.
ChatFrame1:ClearAllPoints(); ChatFrame1:SetPoint('BOTTOMLEFT',UIParent,'BOTTOMLEFT',40,0)
assert(ChatFrame1:GetBottom()==0)
unlockElements[1].savePos(nil,'BOTTOMLEFT','BOTTOMLEFT',40,0); CHAT.Apply()
CHAT.events:RunScript('OnEvent','PLAYER_ENTERING_WORLD')
assert(unlockElements[1].loadPos().y==0 and ChatFrame1:GetBottom()==0)
-- A native reset is corrected on show without modifying the other margins.
ChatFrame1:SetClampRectInsets(-35,35,38,-50); ChatFrame1:Hide(); ChatFrame1:Show()
assert(ChatFrame1:GetBottom()==0 and select(4,ChatFrame1:GetClampRectInsets())==0)
ChatFrame1:SetClampRectInsets(-35,35,38,-50); combat=true; ChatFrame1:Hide(); ChatFrame1:Show()
assert(select(4,ChatFrame1:GetClampRectInsets())==-50)
combat=false; CHAT.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED')
assert(ChatFrame1:GetBottom()==0 and select(4,ChatFrame1:GetClampRectInsets())==0)
unlockElements[1].savePos(nil,'CENTER','BOTTOMLEFT',500,250); CHAT.Apply()
combat=true; p.width=550; CHAT.Apply(); assert(ChatFrame1:GetWidth()==420)
CHAT.ResetPosition(); assert(ChatFrame1:GetPoint(1)=="CENTER")
combat=false; CHAT.events:RunScript("OnEvent","PLAYER_REGEN_ENABLED")
assert(ChatFrame1:GetWidth()==550 and ChatFrame1:GetPoint(1)=="BOTTOMLEFT")
local db=CHAT.addon.db; CHAT.addon.db=nil
assert(unlockElements[1].loadPos()==nil and unlockElements[1].isHidden())
unlockElements[1].savePos(nil,"CENTER","CENTER",1,1); unlockElements[1].clearPos(); unlockElements[1].applyPos()
CHAT.addon.db=db
-- A later addon wraps our AddMessage bridge. Re-apply must not recurse.
local previous=ChatFrame1.AddMessage
local later=function(self,...) return previous(self,...) end
ChatFrame1.AddMessage=later; CHAT.Apply(); ChatFrame1:AddMessage("later wrapper")
local s1=CHAT.states[ChatFrame1]
p.enabled=false; CHAT.Apply()
assert(ChatFrame1.AddMessage==later and ChatFrame1:GetWidth()==380 and ChatFrame1:GetHeight()==160)
assert(select(4,ChatFrame1:GetClampRectInsets())==-50 and select(3,ChatFrame1:GetClampRectInsets())==38 and ChatFrame1:IsClampedToScreen())
assert(select(4,temp:GetClampRectInsets())==-50 and select(3,temp:GetClampRectInsets())==26)
assert(ChatFrame1:GetFading() and ChatFrame1:GetTimeVisible()==75 and ChatFrame1Background:GetAlpha()==.7)
assert(ChatFrame1:GetScript("OnHyperlinkClick")==ChatFrame_OnHyperlinkShow and ChatFrame1:GetScript("OnHyperlinkEnter")==nil)
assert(ChatFrame1:GetScript("OnMouseWheel")==FloatingChatFrame_OnMouseScroll)
assert(not s1.panel:IsShown() and not CHAT.sidebar:IsShown() and not CHAT.icons.showScroll:IsShown() and not s1.visual:IsShown())
assert(ChatFrameMenuButton:IsShown() and FriendsMicroButton:IsShown() and ChatFrame1.buttonFrame:IsShown() and not ChatFrame1:IsUserPlaced())
assert(ChatFrame1Tab.leftTexture:GetAlpha()==.7 and ChatFrame1TabText:GetAlpha()==.7 and ChatFrame1Tab.glow:GetTexture():find("NewMessage"))
local a,rel,b,x,y=GENERAL_CHAT_DOCK:GetPoint(1); assert(rel==ChatFrame1 and x==0 and y==6 and ChatFrame1Tab:GetWidth()==50)
assert(ChatFrame1EditBox:GetHeight()==40 and select(4,ChatFrame1EditBox:GetPoint(1))==-5)
ChatFrame1:AddMessage("disabled https://example.com"); assert(ChatFrame1.messages[#ChatFrame1.messages][1]=="disabled https://example.com")
p.enabled=true; CHAT.Apply(); ChatFrame1:AddMessage("re-enabled https://x.org")
assert(select(4,ChatFrame1:GetClampRectInsets())==0 and select(4,temp:GetClampRectInsets())==0)
assert(ChatFrame1.messages[#ChatFrame1.messages][1]:find("|Heuiurl:https://x.org",1,true) and s1.panel:IsShown() and CHAT.sidebar:IsShown())
assert(not ChatFrameMenuButton:IsShown() and select(4,GENERAL_CHAT_DOCK:GetPoint(1))==-6)
-- The copy buffer can exceed the native scrollback limit and follows Clear.
p.copyLines=50
for i=1,65 do ChatFrame1:AddMessage("buffer "..i) end
assert(#s1.lines==50)
ChatFrame1:Clear(); assert(#s1.lines==0)
CHAT.CopyChat(ChatFrame1); assert(CHAT.copyWindow.box:GetText()=="(No chat history)"); CHAT.copyWindow:Hide()
ChatFrame1:AddMessage("after clear")
CHAT.CopyChat(ChatFrame1); assert(CHAT.copyWindow.box:GetText()=="after clear"); CHAT.copyWindow:Hide()
SlashCmdList.EUI335CHAT(); assert(optionsLoaded and shownModule=="EllesmereUIChat")
SlashCmdList.EUI335COPYCHAT(); assert(CHAT.copyWindow:IsShown()); CHAT.copyWindow:Hide()
assert(not ChatFrame1.scripts.OnKeyDown and not ChatFrame1EditBox.scripts.OnKeyDown)
assert(_ECHAT_RefreshAll==CHAT.Apply)
''')
# Build module pages and mutate real options controls.
lua.execute('''
IsLoggedIn=function() return true end
rows={}; buttons={}
function EllesmereUI:ToggleUnlockMode() unlockOpened=true end
EllesmereUI.Widgets={
    DualRow=function(_,parent,y,left,right) rows[#rows+1]={left,right}; return {},50 end,
    SectionHeader=function() return {},30 end,
    WideButton=function(_,parent,text,y,fn) buttons[text]=fn; return {},40 end,
}
function cfg(text)
    for _,row in ipairs(rows) do for i=1,2 do if type(row[i])=="table" and row[i].text==text then return row[i] end end end
    error("no option "..text)
end
''')
lua.execute((root/'EllesmereUIOptions/EUI_Chat_335_Options.lua').read_text())
lua.execute('''
local p=CHAT.GetSettings(); local s1=CHAT.states[ChatFrame1]
assert(testModule and #testModule.pages==5)
for _,page in ipairs(testModule.pages) do rows={}; assert(testModule.buildPage(page,UIParent,0)>0) end
rows={}; testModule.buildPage("Chat",UIParent,0)
local link=EllesmereUI._ELEMENT_SETTINGS_MAP.ECHAT_MainChat
assert(testModule.pages[1]==link.page and cfg(link.highlightText))
cfg("Background Opacity").setValue(.4); assert(s1.bg.vertex[4]==.4 and CHAT.sidebar.bg.vertex[4]==.4)
cfg("Font").setValue("native"); cfg("Font Size").setValue(16)
assert(select(1,ChatFrame1:GetFont())=="native.ttf" and select(2,ChatFrame1:GetFont())==16 and savedFontSize[2]==16)
assert(cfg("Timestamps").values["%I:%M "] and cfg("Whisper Sound").values.airhorn and cfg("Visibility"))
cfg("Edit Box Height").setValue(30); assert(ChatFrame1EditBox:GetHeight()==30)
cfg("Border Size").setValue("normal"); assert(borderCalls[s1.border][1]==2); cfg("Border Size").setValue("none")
assert(cfg("Border Opacity").disabled())
buttons["Copy Current Chat Window"](); assert(CHAT.copyWindow:IsShown()); CHAT.copyWindow:Hide()
buttons["Unlock Mode"](); assert(unlockOpened)
cfg("Enable Chat").setValue(false); assert(not s1.panel:IsShown())
cfg("Enable Chat").setValue(true); assert(s1.panel:IsShown())
rows={}; testModule.buildPage("Tabs",UIParent,0)
cfg("Tab Height").setValue(30); assert(s1.visual:GetHeight()==30)
cfg("Tab Font Color").setValue(1,0,0,.5); assert(p.tabFontColor.r==1 and p.tabFontColor.a==.5)
rows={}; testModule.buildPage("Sidebar",UIParent,0)
cfg("Sidebar Width").setValue(50); assert(CHAT.sidebar:GetWidth()==50)
cfg("Durability").setValue(true); assert(CHAT.icons.showDurability:IsShown())
p.iconPositions={showCopy={x=1,y=1}}; buttons["Reset Icon Positions"](); assert(next(p.iconPositions)==nil)
rows={}; testModule.buildPage("Chat Bubbles",UIParent,0)
assert(cfg("Say").disabled())
cfg("Enable Chat Bubbles").setValue(true); assert(cvars.chatBubbles=="1" and not cfg("Say").disabled())
cfg("Enable Chat Bubbles").setValue(false); assert(cvars.chatBubbles=="0")
''')
for file,next_card in [('EUI_Fonts_Options.lua','TileMythicTimer'),('EUI_Textures_Options.lua','TileQoL')]:
    source=(root/'EllesmereUIOptions'/file).read_text(encoding='utf-8-sig')
    body=source.split('local function TileChat(',1)[1].split('local function '+next_card+'(',1)[0]
    card=lua.execute('''local NS=function(folder) return EllesmereUI._ModuleNS[folder] end
local ModuleOutlineCfg=function() return {type="dropdown"} end
local BLANK=function() return {type="label"} end
local NoteRow=function(_,y) return y-30 end
local DisabledTile=function(_,y) return y-30 end
local CopyBarDD=function(names,order) local v,o={},{}; for _,k in ipairs(order) do v[k]=names[k]; o[#o+1]=k end; return v,o end
local LinkRow=function(_,y,_,_,page) assert(page=="Chat"); return y-30 end
local function TileChat('''+body+'\nreturn TileChat')
    lua.globals().cardBuilder=card
    lua.execute('rows={}; assert(cardBuilder(UIParent,0,EllesmereUI.Widgets,{folder="EllesmereUIChat",display="Chat"})<0)')
    if file=='EUI_Fonts_Options.lua':
        lua.execute('rows[1][2].setValue("native"); rows[2][1].setValue("thick"); assert(select(3,ChatFrame1:GetFont())=="THICKOUTLINE")')
        lua.execute('rows[2][2].setValue(18); assert(select(2,ChatFrame1:GetFont())==18)')
    else:
        lua.execute('''assert(#rows==1 and rows[1][1].text=="Background Texture")
rows[1][1].setValue("default"); rows[1][2].setValue("default")
local p=CHAT.GetSettings(); assert(p.bgTexture=="default" and p.tabBackgroundTexture=="default")''')
# Second session: 0.3 profile keys, a stock Blizzard style and saved history.
lua=boot('''
EllesmereUIDB={profiles={Default={addons={EllesmereUIChat={
    chat={borderSize=2,borderR=1,borderG=0,borderB=0,timestamps=false,squareSkin=false,hideButtons=true,useBlizzardStyle=true,bgAlpha=0},
}}}}}
EllesmereUIChatScrollDB={frames={ChatFrame1={{t="old line",r=1,g=.5,b=0}},ChatFrame99={{t="gone"}}}}
''')
lua.execute('''
local p=CHAT.GetSettings(); local s1=CHAT.states[ChatFrame1]
assert(p._wrath05 and p.bgAlpha==.65)
assert(p._wrath04 and p.panelBorderThickness=="normal" and p.panelBorderColor.r==1 and p.panelBorderOpacity==1)
assert(p.timestampFormat=="none" and p.borderSize==nil and p.squareSkin==nil and p.hideButtons==nil and p.timestamps==nil)
assert(CHAT.ChatStyle()=="blizzard")
local replay=ChatFrame1.messages[#ChatFrame1.messages]; assert(replay[1]=="old line" and replay[3]==.5 and s1.lines[#s1.lines]=="old line")
-- Stock look: native chrome, tabs, buttons and dock stay; text features still run.
assert(not s1.panel:IsShown() and ChatFrame1Background:GetAlpha()==.7 and ChatFrame1Tab.leftTexture:GetAlpha()==.7)
assert(not s1.visual:IsShown() and ChatFrameMenuButton:IsShown() and ChatFrame1.buttonFrame:IsShown())
assert(CHAT.sidebar==nil or not CHAT.sidebar:IsShown())
assert(select(4,GENERAL_CHAT_DOCK:GetPoint(1))==0 and ChatFrame1EditBox:GetHeight()==40)
assert(select(2,ChatFrame1:GetFont())==12 and select(4,ChatFrame1:GetClampRectInsets())==0)
CHAT.StampFilter(ChatFrame1); ChatFrame1:AddMessage("|Hchannel:PARTY|h[Party]|h www.site.org")
assert(ChatFrame1.messages[#ChatFrame1.messages][1]=="|Hchannel:PARTY|h[P]|h |cff0dd19c|Heuiurl:www.site.org|h[www.site.org]|h|r")
-- The latched style survives a profile toggle until the reload.
p.useBlizzardStyle=false; CHAT.Apply(); assert(CHAT.ChatStyle()=="blizzard" and not s1.panel:IsShown())
''')
lua.execute('''
IsLoggedIn=function() return true end
rows={}
EllesmereUI.Widgets={DualRow=function(_,parent,y,left,right) rows[#rows+1]={left,right}; return {},50 end,
    SectionHeader=function() return {},30 end,WideButton=function() return {},40 end}
''')
lua.execute((root/'EllesmereUIOptions/EUI_Chat_335_Options.lua').read_text())
lua.execute('rows={}; testModule.buildPage("Tabs",UIParent,0); assert(rows[1][1].type=="label" and rows[1][1].text:find("stock chat style",1,true))')
print('PASS: real Core Lite/Chat and native Wrath entry points; Retail panel/tab strip/dock layout, sidebar icons/counts/order/free-move/clicks, borders, lock size, idle fade/visibility/click-through; URL popup, filter stamps/Timestamp All, channel abbreviations, class names, link tooltips, whisper sound, history save/replay; chat bubbles/CVars; Y=0 drag/clamps, combat deferral, unlock, restore/re-enable/external wrappers; 0.3 migration and latched stock style; five option pages plus Fonts/Textures cards. Native rendering and taint require in-game confirmation.')
