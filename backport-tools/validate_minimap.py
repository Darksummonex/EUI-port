"""Wrath Minimap contracts and actual options-page wiring; no in-game rendering."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
lua=LuaRuntime()
lua.execute((root/'backport-tools/wrath_mock.lua').read_text())
lua.execute('''
local methods=getmetatable(CreateFrame("Frame")).__index
local create=CreateFrame
function CreateFrame(kind,name,parent,template)
    local f=create(kind,name,parent,template); f.name=name; return f
end
function methods:GetName() return self.name end
function methods:GetNumPoints() return #(self.points or {}) end
function methods:GetPoint(i) return unpack((self.points or {})[i or 1] or {}) end
function methods:SetPoint(...) self.points=self.points or {}; self.points[#self.points+1]={...} end
function methods:ClearAllPoints() self.points={} end
function methods:SetScale(v) self.scale=v end
function methods:GetScale() return self.scale or 1 end
function methods:GetEffectiveScale() return self:GetScale() end
function methods:SetAlpha(v) self.alpha=v end
function methods:GetAlpha() return self.alpha or 1 end
function methods:SetFrameLevel(v) self.level=v end
function methods:GetFrameLevel() return self.level or 1 end
function methods:SetTextColor(...) self.color={...} end
function methods:SetVertexColor(...) self.vertexColor={...} end
function methods:GetChildren() return unpack(self.children) end
function methods:SetParent(parent)
    if self.parent then
        for i=#self.parent.children,1,-1 do if self.parent.children[i]==self then table.remove(self.parent.children,i) end end
    end
    self.parent=parent
    if parent then parent.children[#parent.children+1]=self end
end
function methods:EnableMouse(v) self.mouse=v end
function methods:IsMouseEnabled() return self.mouse~=false end
function methods:EnableMouseWheel(v) self.wheelEnabled=v end
function methods:IsMouseWheelEnabled() return self.wheelEnabled==true end
function methods:SetMovable(v) self.movable=v end
function methods:IsMovable() return self.movable==true end
function methods:SetClampedToScreen(v) self.clamped=v end
function methods:IsClampedToScreen() return self.clamped==true end
function methods:StartMoving() self.moving=true end
function methods:StopMovingOrSizing() self.moving=false end
function methods:GetMaskTexture() return self.mask end
function methods:SetMaskTexture(v) self.mask=v end
function methods:GetZoom() return self.zoom or 0 end
function methods:GetZoomLevels() return 6 end
function methods:SetZoom(v) assert(v>=0 and v<6); self.zoom=v end
function methods:SetBackdrop() end
function methods:SetBackdropColor() end
function methods:SetBackdropBorderColor() end
function methods:Enable() self.enabled=true end
function methods:Disable() self.enabled=false end
function methods:IsEnabled() return self.enabled~=false end
function methods:Click(button) if self:IsEnabled() and self.scripts.OnClick then self.scripts.OnClick(self,button or 'LeftButton') end end
function methods:GetStringWidth() return #(self.text or "")*5 end
function methods:GetRegions()
    local regions={}
    for _,c in ipairs(self.children) do if c.kind=="Texture" or c.kind=="FontString" then regions[#regions+1]=c end end
    return unpack(regions)
end
function methods:GetTexCoord() return unpack(self.texcoords or {0,0,0,1,1,0,1,1}) end
function methods:SetHitRectInsets(...) self.hitInsets={...} end
cursorX,cursorY,mouseDown=0,0,false
function GetCursorPosition() return cursorX,cursorY end
function IsMouseButtonDown() return mouseDown end
function methods:Show()
    local changed=not self.shown; self.shown=true
    if changed and self.scripts.OnShow then self.scripts.OnShow(self) end
    if changed and self.hooks.OnShow then self.hooks.OnShow(self) end
end
function methods:Hide()
    local changed=self.shown; self.shown=false
    if changed and self.scripts.OnHide then self.scripts.OnHide(self) end
    if changed and self.hooks.OnHide then self.hooks.OnHide(self) end
end
combat,shift,hover=false,false,false
function InCombatLockdown() return combat end
function UnitAffectingCombat() return combat end
function IsShiftKeyDown() return shift end
function MouseIsOver() return hover end
function IsInGroup() return false end
function IsInRaid() return false end
cvars={rotateMinimap="1"}
function GetCVar(k) return cvars[k] end
function SetCVar(k,v) cvars[k]=v end
function GetZoneText() return "Orgrimmar" end
function GetSubZoneText() return "Valley" end
function GetZonePVPInfo() return "friendly" end
function date() return {hour=13,min=7} end
function GetGameTime() return 22,15 end
function GetNetStats() return 0,0,120 end
function GetFramerate() return 60 end
mapResets=0
function SetMapToCurrentZone() mapResets=mapResets+1 end
function GetPlayerMapPosition() return .25,.75 end
timers={}
function C_Timer.NewTimer(delay,fn)
    local timer={delay=delay,fn=fn,Cancel=function(self) self.cancelled=true end}
    timers[#timers+1]=timer; return timer
end
function EasyMenu() error('Minimap menu must not depend on EasyMenu') end
UISpecialFrames={}; nativeMenuCalls={}; fallbackMenuCalls={}
secureMenuCalls={}; inNativeCall=false
function securecall(fn,...)
    secureMenuCalls[#secureMenuCalls+1]=fn
    local before=inNativeCall; inNativeCall=true
    local result
    if type(fn)=='string' then result={_G[fn](...)} else result={fn(...)} end
    inNativeCall=before; return unpack(result)
end
for _,name in ipairs({'CharacterMicroButton','TalentMicroButton','SpellbookMicroButton','AchievementMicroButton','QuestLogMicroButton','SocialsMicroButton','LFDMicroButton','HelpMicroButton'}) do
    local b=CreateFrame('Button',name,UIParent)
    b:SetScript('OnClick',function(self,button) assert(inNativeCall and self==b and button=='LeftButton'); nativeMenuCalls[#nativeMenuCalls+1]=name end)
end
function ToggleCharacter(tab) fallbackMenuCalls[#fallbackMenuCalls+1]=tab end
SpellBookFrame=CreateFrame('Frame','SpellBookFrame',UIParent); SpellBookFrame:Hide()
function ToggleSpellBook(book)
    assert(inNativeCall and book=='spell','Spellbook was opened in the addon callback context')
    SpellBookFrame.bookType=book; SpellBookFrame:Show()
    nativeMenuCalls[#nativeMenuCalls+1]='SpellbookMicroButton'
end
function TogglePVPFrame() fallbackMenuCalls[#fallbackMenuCalls+1]='pvp' end
function ToggleCalendar() fallbackMenuCalls[#fallbackMenuCalls+1]='calendar' end
function ToggleFriendsFrame(tab) fallbackMenuCalls[#fallbackMenuCalls+1]=tab end
function IsInGuild() return true end
GameMenuFrame=CreateFrame('Frame','GameMenuFrame',UIParent)
function ToggleFrame(frame) assert(frame==GameMenuFrame); fallbackMenuCalls[#fallbackMenuCalls+1]='game' end
GetMinimapShape=function() return "ROUND" end
MinimapCluster=CreateFrame("Frame","MinimapCluster",UIParent)
Minimap=CreateFrame("Minimap","Minimap",MinimapCluster)
Minimap:SetWidth(140); Minimap:SetHeight(140); Minimap:SetAlpha(.8)
Minimap:SetPoint("CENTER",MinimapCluster,"CENTER",0,0)
Minimap:SetMaskTexture("Textures\\\\MinimapMask"); Minimap:SetZoom(2)
Minimap:SetFrameLevel(10)
originalMouseUp=0
local oldMouseUp=function() originalMouseUp=originalMouseUp+1 end
Minimap:SetScript("OnMouseUp",oldMouseUp)
WorldMapFrame=CreateFrame("Frame","WorldMapFrame",UIParent); WorldMapFrame:Hide()
for _,name in ipairs({"MinimapBorder","MinimapBorderTop","MinimapNorthTag","MinimapZoneTextButton",
    "MinimapZoomIn","MinimapZoomOut","MiniMapTrackingButton","MiniMapMailFrame","GameTimeFrame","MiniMapInstanceDifficulty"}) do
    local f=CreateFrame("Button",name,Minimap); f:SetPoint("CENTER",Minimap,"CENTER",2,3)
end
MiniMapMailFrame:Hide()
addonButton=CreateFrame("Button","LibDBIcon10_Test",Minimap)
addonButton:SetPoint("CENTER",Minimap,"CENTER",7,9)
addonButton.icon=addonButton:CreateTexture(); addonButton.icon:SetTexture("Interface\\\\Icons\\\\Test")
addonButton.icon:SetPoint("TOPLEFT",addonButton,"TOPLEFT",7,-5); addonButton.icon:SetTexCoord(0,1,0,1)
junkBorder=addonButton:CreateTexture(); junkBorder:SetTexture("Interface\\\\Minimap\\\\MiniMap-TrackingBorder")
buttonClicks=0
addonButton:SetScript("OnClick",function() buttonClicks=buttonClicks+1 end)
libDrag=function() end
addonButton:SetScript("OnDragStart",libDrag)
mailFlag=false
function HasNewMail() return mailFlag end
function GetLatestThreeSenders() return "Thrall" end
instanceInfo={"Orgrimmar","none",0,"",0,0,false}
function GetInstanceInfo() return unpack(instanceInfo) end
function GetNumSavedInstances() return 1 end
function GetSavedInstanceInfo() return "Naxxramas",1,3600,2,true,false,0,true,25,"25 Player" end
function SecondsToTime() return "1 Hr" end
function RequestRaidInfo() end
function GuildRoster() end
LOCALIZED_CLASS_NAMES_MALE={WARRIOR="Warrior"}
function GetNumGuildMembers() return 2 end
function GetGuildRosterInfo(i)
    if i==1 then return "Garrosh","Rank",1,80,"Warrior","Orgrimmar","",nil,true,0,"WARRIOR" end
    return "Offline","Rank",1,80,"Warrior","","",nil,false,0,"WARRIOR"
end
function GetNumFriends() return 2 end
function GetFriendInfo(i)
    if i==1 then return "Bob",80,"Warrior","Dalaran",true,"","tank" end
    return "Garrosh",80,"Warrior","Orgrimmar",true,"",""
end
function BNGetNumFriends() return 1,1 end
function BNGetFriendInfo() return 1,"Jane","Doe","Janetoon",5,"WoW",true,0,false,false,"","bn note" end
function BNGetToonInfo() return false,"Janetoon","WoW","Realm","Horde","Orc","Warrior","","Undercity","79" end
tells,invites={},{}
function ChatFrame_SendTell(name) tells[#tells+1]=name end
function InviteUnit(name) invites[#invites+1]=name end
EllesmereUI._deferredInits={}
EllesmereUI.L=function(s) return s end
EllesmereUI.MakeUnlockElement=function(opts) return opts end
EllesmereUI.RegisterUnlockElements=function(_,elements) unlock=elements[1] end
''')
for path in ['EllesmereUI/EllesmereUI_VisibilityRules.lua','EllesmereUI/EllesmereUI_Visibility.lua']:
    lua.execute((root/path).read_text(encoding='utf-8-sig'))
lua.execute((root/'EllesmereUI/EllesmereUI_Lite.lua').read_text(encoding='utf-8-sig'),'EllesmereUI',lua.table())
lua.execute("lifecycle=allFrames[#allFrames]; lifecycleErrors={}; function geterrorhandler() return function(err) lifecycleErrors[#lifecycleErrors+1]=err end end; lifecycle:GetScript('OnEvent')(lifecycle,'ADDON_LOADED','EllesmereUI')")
ns=lua.table()
lua.execute((root/'EllesmereUIMinimap/EUI_Minimap_335.lua').read_text(), 'EllesmereUIMinimap',ns)
lua.globals().M=ns
lua.execute('''
lifecycle:GetScript('OnEvent')(lifecycle,'ADDON_LOADED','EllesmereUIMinimap')
function IsLoggedIn() return true end
lifecycle:GetScript('OnEvent')(lifecycle,'PLAYER_LOGIN'); assert(#lifecycleErrors==0,lifecycleErrors[1])
local p=M.GetSettings()
assert(Minimap:GetParent()==UIParent and Minimap:GetWidth()==180 and GetMinimapShape()=="SQUARE")
assert(M.clock.text=="1:07 PM" and M.zone.text=="Orgrimmar",M.clock.text)
assert(not MiniMapMailFrame:IsShown(),"mail must retain Blizzard visibility")
assert(MiniMapMailFrame:GetAlpha()==0 and GameTimeFrame:GetAlpha()==0 and MiniMapTrackingButton:GetAlpha()==0)
assert(M.tracking:IsShown() and M.calendar:IsShown() and not M.mail:IsShown() and M.friends:IsShown())
assert(M.border:IsShown() and M.layout:GetHeight()==180 and Minimap.hitInsets[3]==0)
p.showCoords=true; p.coordPrecision=1; p.showFPS=true; p.zoneReactiveColor=true; M.Apply()
assert(M.coords.text=="25.0, 75.0" and M.fps.text=="60 |cffffffffFPS|r" and M.fpsLocal.text=="120 |cffffffffMS|r",M.fps.text)
assert(M.zone.color[2]==.85)
p.fpsUseAccent=true; p.fpsColorClockAMPM=true; EllesmereUI.GetAccentColor=function() return 1,0,0 end; M.Apply()
assert(M.fps.text=="60 |cffff0000FPS|r" and M.clock.text=="1:07 |cffff0000PM|r",M.clock.text)
p.fpsShowLocalMS=false; M.UpdateFPS(); assert(not M.fpsLocal:IsShown())
p.fpsUseAccent=false; p.fpsColorClockAMPM=false; p.fpsShowLocalMS=true; EllesmereUI.GetAccentColor=nil; M.Apply()
local before=mapResets
WorldMapFrame:Show(); M.UpdateText(); assert(M.coords.text=="" and mapResets==before)
WorldMapFrame:Hide(); M.UpdateText(); assert(M.coords.text=="25.0, 75.0" and mapResets==before+1)
p.clockServer=true; p.clockFormat="24h"; p.zoneShowSubZone=true; M.UpdateText()
assert(M.clock.text=="22:15" and M.zone.text=="Valley")
p.shape="circle"; M.Apply(); assert(GetMinimapShape()=="ROUND" and Minimap.mask=="Textures\\\\MinimapMask")
assert(M.disc:IsShown() and not M.border:IsShown() and math.abs(M.disc:GetWidth()-182*128/104)<.01)
p.clockMode="inside"; p.clockPosition="top"; M.Apply()
assert(M.tracking:GetPoint()=="RIGHT" and select(2,M.tracking:GetPoint())==M.clockBg and select(2,M.calendar:GetPoint())==M.clockBg)
p.shape="textured_circle"; M.Apply(); assert(M.ring:IsShown() and not M.disc:IsShown() and GetMinimapShape()=="ROUND")
p.shape="rectangular"; M.Apply()
assert(GetMinimapShape()=="SQUARE" and Minimap.mask:find("rectangular%-crop%-mask") and Minimap.hitInsets[3]==22.5 and Minimap.hitInsets[4]==22.5)
assert(M.layout:GetHeight()==135 and M.layout:GetWidth()==180 and M.border:IsShown() and not M.ring:IsShown())
local e=M.border.edges[1]; assert(e.points[1][2]==M.layout and e.points[1][3]=="TOPLEFT")
borderCalls=0; EllesmereUI.ResolveBorderTexture=function(k) return k~="solid" and "tex" end
EllesmereUI.ApplyBorderStyle=function(frame,size,r,g,b,a,key) borderCalls=borderCalls+1; assert(frame~=M.border and key=="thin" and size==1) end
p.borderTexture="thin"; M.Apply(); assert(borderCalls==1 and not M.border:IsShown())
p.borderTexture="solid"; p.borderUseClassColor=true; M.Apply(); assert(M.border:IsShown() and M.border.edges[1].vertexColor[2]==.5)
p.borderUseClassColor=false; p.useClassColor=true; EllesmereUI.GetAccentColor=function() return .2,.4,.6 end; M.Apply()
assert(M.border.edges[1].vertexColor[3]==.6); p.useClassColor=false; EllesmereUI.GetAccentColor=nil
p.clockMode="edge"; p.clockPosition="bottomRight"; M.Apply()
local pt,rel,relPt,x,y=M.clockBg:GetPoint(); assert(pt=="BOTTOMRIGHT" and rel==M.layout and x==7 and y==-7)
assert(M.tracking:GetPoint()=="TOPRIGHT" and select(3,M.tracking:GetPoint())=="TOPLEFT" and select(4,M.tracking:GetPoint())==-1)
p.elementRowPosition="blRight"; p.elementRowSpacing=2; p.elementRowDistance=3; M.Apply()
local _,_,_,x1,y1=M.tracking:GetPoint(); local _,_,_,x2=M.calendar:GetPoint(); assert(x1==0 and y1==-4 and x2==23)
p.elementRowPosition="tlDown"; p.elementRowSpacing=0; p.elementRowDistance=0
p.clockMode="inside"; p.clockPosition="top"; p.shape="square"; M.Apply()
p.useClassicStyle=true; M.Apply()
assert(GetMinimapShape()=="ROUND" and M.classicRing:IsShown() and M.classicHeader:IsShown() and not M.border:IsShown())
assert(MinimapZoomIn:GetAlpha()==1 and MinimapZoomIn:GetWidth()==32*180/140 and not M.zoomIn:IsShown() and M.tracking:GetWidth()==31)
assert(select(2,M.zoneBg:GetPoint())==M.classicHeader.slot and M.tracking.ring:IsShown())
p.useClassicStyle=false; M.Apply()
assert(not M.classicRing:IsShown() and MinimapZoomIn:GetAlpha()==0 and M.zoomIn:IsShown() and M.tracking:GetWidth()==21 and not M.tracking.ring:IsShown())
p.diffTextEnabled=true; p.diffTextReactive=true; instanceInfo={"Naxxramas","raid",4,"25 Player (Heroic)",25,0,false}; M.Apply()
assert(M.diff.text=="25|cff0070ddH|r" and MiniMapInstanceDifficulty:GetAlpha()==0,M.diff.text)
instanceInfo={"Utgarde Keep","party",1,"5 Player",5,0,false}; M.UpdateText(); assert(M.diff.text=="5|cffc69b6dN|r")
instanceInfo={"Orgrimmar","none",0,"",0,0,false}; M.UpdateText(); assert(M.diff.text=="")
p.diffTextEnabled=false; M.Apply(); assert(MiniMapInstanceDifficulty:GetAlpha()==1 and not M.diff:IsShown())
mailFlag=true; M.events:GetScript("OnEvent")(M.events,"UPDATE_PENDING_MAIL"); assert(M.mail:IsShown() and select(2,M.mail:GetPoint())==M.layout)
p.mailPosition="TOPRIGHT"; p.mailOffsetX=-3; M.Apply(); local mpt,_,_,mx,my=M.mail:GetPoint(); assert(mpt=="TOPRIGHT" and mx==-5 and my==-2)
p.hideMail=true; M.Apply(); assert(not M.mail:IsShown()); p.hideMail=false; p.mailPosition="button"; mailFlag=false; M.Apply()
p.clockHoverTooltip="lockouts"; M.clockBg:GetScript("OnEnter")(M.clockBg)
assert(M.lockoutTooltip:IsShown() and M.lockoutTooltip.rows[1][1].text=="Naxxramas" and M.lockoutTooltip.rows[2][1].text=="Server Time")
M.clockBg:GetScript("OnLeave")(M.clockBg); assert(not M.lockoutTooltip:IsShown())
M.friends:GetScript("OnEnter")(M.friends); local ftt=M.friendsTooltip
assert(ftt:IsShown() and ftt.rows[1].entry.name=="Garrosh" and ftt.rows[2].entry.name=="Bob" and ftt.rows[3].entry.bnetTag=="Jane Doe" and not ftt.rows[4])
assert(ftt.rows[3].entry.class=="WARRIOR" and ftt.rows[3].entry.zone=="Undercity" and ftt.rows[3].entry.name=="Janetoon" and ftt.headers[1].text:find("Guild"))
ftt.rows[3]:GetScript("OnClick")(ftt.rows[3],"LeftButton"); assert(tells[1]=="Jane Doe" and not ftt:IsShown())
M.ShowFriends(M.friends); ftt.rows[2]:GetScript("OnClick")(ftt.rows[2],"RightButton"); assert(invites[1]=="Bob")
p.friendsShowNotes=true; p.friendsMaxRows=1; M.ShowFriends(M.friends)
assert(ftt.rows[2].note.text=="tank" and ftt.rows[2].note:IsShown() and ftt.rows[3].name.text:find("and 1 more") and not ftt.rows[3].entry)
p.friendsShowNotes=false; p.friendsMaxRows=0
M.ShowFriends(M.friends); M.friends:GetScript("OnLeave")(M.friends); assert(ftt._hideAt)
now=now+1; hover=false; M.HoverTick(); assert(not ftt:IsShown())
p.hideExtraBtns.friendsOnline=true; M.Apply(); assert(not M.friends:IsShown()); p.hideExtraBtns.friendsOnline=false; M.Apply()
p.zoomResetSeconds=3
Minimap:GetScript("OnMouseWheel")(Minimap,1); assert(Minimap:GetZoom()==1 and p.savedZoom==1)
local timer=timers[#timers]; assert(timer.delay==3)
Minimap:GetScript("OnMouseWheel")(Minimap,1); assert(timer.cancelled)
timers[#timers].fn(); assert(Minimap:GetZoom()==0 and p.savedZoom==0)
Minimap:GetScript("OnMouseUp")(Minimap,"LeftButton"); assert(originalMouseUp==1)
Minimap:GetScript("OnMouseUp")(Minimap,"MiddleButton"); assert(M.microMenu:IsShown() and M.microMenuDismiss:IsShown())
local labels={}; for _,b in pairs(M.microMenu.rows) do if b:IsShown() then labels[b.item.text]=b end end
assert(labels.Character and labels.Talents and labels.Professions and labels['Group Finder'] and labels.Achievements and labels.PvP and labels.Guild and labels.Calendar and labels.Support)
assert(not labels.Housing and not labels.Collections and not labels.Shop and not labels['Adventure Guide'])
assert(M.microMenu:GetWidth()==160 and M.microMenu:GetPoint()=='TOPRIGHT')
labels.Character:GetScript('OnClick')(labels.Character); assert(fallbackMenuCalls[1]=='PaperDollFrame' and secureMenuCalls[1]=='ToggleCharacter' and not M.microMenu:IsShown() and not M.microMenuDismiss:IsShown())
for _,label in ipairs({'Talents','Spellbook','Group Finder','Achievements','Quest Log','Friends','Support','Professions','Guild','Calendar','PvP','Game Menu'}) do
    M.ToggleMicroMenu(); labels[label]:GetScript('OnClick')(labels[label]); assert(not M.microMenu:IsShown())
end
assert(nativeMenuCalls[1]=='TalentMicroButton' and nativeMenuCalls[2]=='SpellbookMicroButton' and nativeMenuCalls[3]=='LFDMicroButton')
assert(secureMenuCalls[3]=='ToggleSpellBook' and SpellBookFrame:IsShown() and SpellBookFrame.bookType=='spell')
SpellBookFrame:Hide(); assert(not SpellBookFrame:IsShown() and not M.microMenu:IsShown())
assert(fallbackMenuCalls[2]==1 and fallbackMenuCalls[3]=='SkillFrame' and fallbackMenuCalls[4]==3 and fallbackMenuCalls[5]=='calendar' and fallbackMenuCalls[6]=='pvp' and fallbackMenuCalls[7]=='game')
local frames=#allFrames; M.ToggleMicroMenu(); M.ToggleMicroMenu(); assert(not M.microMenu:IsShown() and frames==#allFrames)
EasyMenu=nil; M.ToggleMicroMenu(); assert(M.microMenu:IsShown())
M.microMenuDismiss:GetScript('OnMouseUp')(M.microMenuDismiss,'LeftButton'); assert(not M.microMenu:IsShown() and not M.microMenuDismiss:IsShown())
M.ToggleMicroMenu(); M.microMenu:Hide(); assert(not M.microMenuDismiss:IsShown() and UISpecialFrames[1]=='EUI335MinimapMicroMenu')
TalentMicroButton:Disable(); M.ToggleMicroMenu(); assert(not labels.Talents:IsEnabled())
local calls=#nativeMenuCalls; labels.Talents:GetScript('OnClick')(labels.Talents); assert(#nativeMenuCalls==calls)
M.CloseMicroMenu(); TalentMicroButton:Enable()
local optional=CreateFrame('Button','CollectionsMicroButton',UIParent); optional:SetScript('OnClick',function() assert(inNativeCall); nativeMenuCalls[#nativeMenuCalls+1]='collections' end)
M.ToggleMicroMenu(); local collections; for _,b in pairs(M.microMenu.rows) do if b.item.text=='Collections' then collections=b end end
assert(collections and collections:IsShown()); collections:GetScript('OnClick')(collections); assert(nativeMenuCalls[#nativeMenuCalls]=='collections')
M.ToggleMicroMenu(); combat=true; M.events:GetScript('OnEvent')(M.events,'PLAYER_REGEN_DISABLED'); assert(not M.microMenu:IsShown() and not M.microMenuDismiss:IsShown())
M.ToggleMicroMenu(); assert(not M.microMenu:IsShown()); combat=false
EllesmereUI.GetAccentColor=function() return .1,.3,.8 end
M.ToggleMicroMenu(); assert(labels.Character.highlight.vertexColor[3]==.8)
Minimap:Hide(); assert(not M.microMenu:IsShown() and not M.microMenuDismiss:IsShown()); Minimap:Show()
M.ToggleMicroMenu(); assert(M.microMenu:IsShown())
p.openMicroMenuOnMiddleClick=false; M.Apply(); local savedNative=originalMouseUp
Minimap:GetScript('OnMouseUp')(Minimap,'MiddleButton'); assert(originalMouseUp==savedNative+1 and not M.microMenu:IsShown())
p.openMicroMenuOnMiddleClick=true
shift=true; Minimap.hooks.OnMouseDown(Minimap,"LeftButton"); assert(Minimap.moving)
Minimap:GetScript("OnMouseUp")(Minimap,"LeftButton"); assert(not Minimap.moving and p.position)
shift=false
assert(addonButton:GetParent()==Minimap and addonButton:GetWidth()==21 and not M.groupButton:IsShown(),"a lone button sits ungrouped on the row")
assert(not junkBorder:IsShown() and addonButton:GetScript("OnDragStart")==nil and addonButton.icon.texcoords[1]==.05)
local origClick=addonButton:GetScript("OnClick")
second=CreateFrame("Button","LibDBIcon10_Second",Minimap); second:SetScript("OnClick",function() end)
M.Apply()
assert(addonButton:GetParent()==M.popup and second:GetParent()==M.popup and M.groupButton:IsShown() and addonButton:GetWidth()==24)
assert(M.groupButton:GetPoint()=="BOTTOMRIGHT" and select(3,M.groupButton:GetPoint())=="BOTTOMLEFT")
local fpt,frel,frelPt=M.popup:GetPoint(); assert(fpt=="BOTTOMRIGHT" and frel==M.groupButton and frelPt=="BOTTOMLEFT")
assert(M.popup:GetWidth()==16+2*24+4 and M.groupButton.icon.desaturated)
M.groupButton:GetScript("OnClick")(M.groupButton); assert(M.popup:IsShown())
addonButton:GetScript("OnClick")(addonButton); addonButton.hooks.OnClick(addonButton)
assert(buttonClicks==1 and not M.popup:IsShown())
M.groupButton:GetScript("OnClick")(M.groupButton); mouseDown=true; hover=false; M.HoverTick(); assert(not M.popup:IsShown()); mouseDown=false
p.ungroupedButtons.LibDBIcon10_Test=1; M.Apply()
assert(addonButton:GetParent()==Minimap and second:GetParent()==M.popup and M.rowButtons[1]==M.groupButton and M.rowButtons[2]==addonButton and M.rowButtons[3]==M.friends)
p.hideExtraBtns.groupButton=true; M.Apply(); assert(not M.groupButton:IsShown() and M.rowButtons[1]==addonButton); p.hideExtraBtns.groupButton=false
p.btnRowPosition="tlRight"; M.Apply(); assert(M.FlyoutDirection(p)=="up" and M.popup:GetPoint()=="BOTTOMLEFT"); p.btnRowPosition="blUp"
p.freeMoveBtns=true; M.Apply()
local menuCalls=#fallbackMenuCalls
shift=true; cursorX,cursorY=100,100; M.friends.hooks.OnMouseDown(M.friends,"LeftButton")
cursorX,cursorY=110,95; M.UpdateMove(); M.friends.hooks.OnMouseUp(M.friends,"LeftButton")
assert(p.btnPositions.friendsOnline.x==10 and p.btnPositions.friendsOnline.y==-5)
M.friends:GetScript("OnClick")(M.friends); assert(#fallbackMenuCalls==menuCalls,"a drag must not click through")
M.friends:GetScript("OnClick")(M.friends); assert(fallbackMenuCalls[#fallbackMenuCalls]==1)
M.Apply(); local _,_,_,fx,fy=M.friends:GetPoint(); assert(fx==9 and fy==37)
addonButton._euiDragged=true; addonButton:GetScript("OnClick")(addonButton); assert(buttonClicks==1)
addonButton:GetScript("OnClick")(addonButton); assert(buttonClicks==2); shift=false
p.freeMoveBtns=false; M.Apply(); assert(addonButton:GetScript("OnClick")==origClick)
p.freeMoveBtns=true; p.btnPositions={}; M.Apply(); local _,_,_,rx=M.friends:GetPoint(); assert(rx==-1); p.freeMoveBtns=false
p.mouseoverExtraBtns=true; M.Apply(); hover=false; M.HoverTick(); now=now+1; M.HoverTick()
assert(M.friends:GetAlpha()==0 and M.groupButton:GetAlpha()==0)
hover=true; M.HoverTick(); assert(M.groupButton:GetAlpha()==1 and M.friends:GetAlpha()==.85 and M.zoomIn:GetAlpha()==1)
hover=false; M.HoverTick(); assert(M.zoomIn:GetAlpha()==0); p.mouseoverExtraBtns=false
p.coordsMode="hover"; M.Apply(); assert(not M.coordsBox:IsShown()); hover=true; M.HoverTick(); assert(M.coordsBox:IsShown()); hover=false; p.coordsMode="always"
p.hideAddonButtons=true; M.Apply(); assert(addonButton:GetParent()==M.hidden and addonButton:IsShown() and junkBorder:IsShown())
p.hideAddonButtons=false; M.Apply()
p.hideTrackingButton=true; M.Apply(); assert(MiniMapTrackingButton:GetAlpha()==0 and not MiniMapTrackingButton:IsMouseEnabled() and not M.tracking:IsShown())
p.visibility="never"; M.Apply(); assert(not Minimap:IsShown())
p.visibility="mouseover"; M.Apply(); assert(Minimap:IsShown() and Minimap:GetAlpha()==0)
hover=true; M.UpdateVisibility(); assert(Minimap:GetAlpha()==1); hover=false
combat=true; p.size=220; M.Apply(); assert(Minimap:GetWidth()==180)
combat=false; M.events:GetScript("OnEvent")(M.events,"PLAYER_REGEN_ENABLED"); assert(Minimap:GetWidth()==220)
assert(unlock.key=="EBS_Minimap" and unlock.getFrame()==Minimap)
unlock.savePos(nil,"TOP", "TOP",1,-2); unlock.applyPos()
assert(p.position.x==1 and Minimap:GetPoint()=="TOP")
M.ToggleMicroMenu(); assert(M.microMenu:IsShown())
p.enabled=false; M.Apply(); assert(not M.microMenu:IsShown() and not M.microMenuDismiss:IsShown())
assert(Minimap:GetParent()==MinimapCluster and Minimap:GetWidth()==140 and Minimap:GetAlpha()==.8)
assert(cvars.rotateMinimap=="1" and Minimap:GetZoom()==2 and GetMinimapShape()=="ROUND")
assert(MiniMapTrackingButton:GetAlpha()==1 and MiniMapTrackingButton:IsMouseEnabled())
assert(not M.border:IsShown() and not M.groupButton:IsShown() and not M.popup:IsShown())
assert(addonButton:GetParent()==Minimap and addonButton:GetWidth()==200 and addonButton:GetPoint()=="CENTER" and second:GetParent()==Minimap)
assert(junkBorder:IsShown() and addonButton:GetScript("OnDragStart")==libDrag and addonButton.icon.texcoords[2]==1 and addonButton.icon:GetPoint()=="TOPLEFT")
assert(Minimap.hitInsets[3]==0 and not M.tracking:IsShown() and not M.friends:IsShown() and not M.zoomIn:IsShown())
assert(MinimapZoomIn:GetAlpha()==1 and GameTimeFrame:GetAlpha()==1 and MiniMapMailFrame:IsMouseEnabled())
Minimap:GetScript("OnMouseUp")(Minimap,"LeftButton"); assert(originalMouseUp==3)
p.enabled=true; M.Apply(); assert(Minimap:GetWidth()==220 and nativeAtlasCalls==0 and rotationCalls==0)
''')
lua.execute('IsLoggedIn=function() return true end')
lua.execute((root/'EllesmereUIOptions/EUI_Minimap_335_Options.lua').read_text())
lua.execute('''
assert(testModule and #testModule.pages==1 and testModule.pages[1]=="Minimap" and SlashCmdList.EMM)
local rows={}
EllesmereUI.Widgets={
    DualRow=function(_,parent,y,left,right) rows[#rows+1]={left,right}; return {},50 end,
    SectionHeader=function() return {},30 end,
    WideButton=function(_,parent,label,y,fn) buttons=buttons or {}; buttons[label]=fn; return {},50 end,
}
local height=testModule.buildPage("Minimap",UIParent,0)
assert(height>0 and #rows==46,#rows)
rows[2][1].setValue(190); assert(Minimap:GetWidth()==190 and rows[2][1].getValue()==190)
rows[2][2].setValue("rectangular"); assert(GetMinimapShape()=="SQUARE" and M.layout:GetHeight()==190*192/256)
rows[2][2].setValue("square"); assert(GetMinimapShape()=="SQUARE")
rows[3][1].setValue("classic"); assert(GetMinimapShape()=="ROUND" and M.classicRing:IsShown() and rows[2][2].disabled())
rows[3][1].setValue("eui"); assert(not M.classicRing:IsShown() and rows[3][1].getValue()=="eui")
local labels={}
for _,row in ipairs(rows) do for i=1,2 do if row[i] and row[i].text then labels[row[i].text]=row[i] end end end
for _,label in ipairs({"Border Color Source","Visibility Options","Ungrouped Buttons","Show Friends Online","Flyout Direction",
    "Button Row Position","Element Row Position","Mail Position","Clock Hover","FPS Hover","Difficulty as Text","Coordinates Mode","Free Move Buttons"}) do
    assert(labels[label],label)
end
labels["Border Color Source"].setValue("class"); assert(M.GetSettings().borderUseClassColor and labels["Border Color Source"].getValue()=="class")
labels["Border Color Source"].setValue("custom"); assert(not M.GetSettings().borderUseClassColor and not M.GetSettings().useClassColor)
labels["Show Friends Online"].setValue(false); assert(not M.friends:IsShown()); labels["Show Friends Online"].setValue(true); assert(M.friends:IsShown())
labels["Show Tracking"].setValue(true); assert(M.tracking:IsShown())
M.GetSettings().position={point="CENTER",relPoint="CENTER",x=1,y=1}
buttons["Reset Position"](); assert(M.GetSettings().position==nil)
M.GetSettings().btnPositions={friendsOnline={x=1,y=1}}; buttons["Reset Button Positions"](); assert(next(M.GetSettings().btnPositions)==nil)
''')
print('PASS: real Lua51 Core lifecycle; middle-click menu without EasyMenu, securecall dispatch for native toggles/clicks, Spellbook open/close, optional entries, disabled controls, theme/font, dismissal/combat/restore; Minimap layout/clock/zone/map/zoom/movers/buttons/options; Retail port: square/rectangular/circle/textured shapes, solid/textured/class/accent borders, Classic WoW UI chrome, indicator and button rows, flyout/ungroup/free move, mail corner, edge text boxes, FPS/MS segments, difficulty text, lockouts and friends tooltips, mouseover extras; native taint requires client confirmation.')
