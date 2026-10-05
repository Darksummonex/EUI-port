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
    "MinimapZoomIn","MinimapZoomOut","MiniMapTrackingButton","MiniMapMailFrame","GameTimeFrame"}) do
    local f=CreateFrame("Button",name,Minimap); f:SetPoint("CENTER",Minimap,"CENTER",2,3)
end
MiniMapMailFrame:Hide()
addonButton=CreateFrame("Button","LibDBIcon10_Test",Minimap)
addonButton:SetPoint("CENTER",Minimap,"CENTER",7,9)
buttonClicks=0
addonButton:SetScript("OnClick",function() buttonClicks=buttonClicks+1 end)
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
assert(M.clock.text=="01:07 PM" and M.zone.text=="Orgrimmar")
assert(not MiniMapMailFrame:IsShown(),"mail must retain Blizzard visibility")
p.showCoords=true; p.coordPrecision=1; p.showFPS=true; p.zoneReactiveColor=true; M.Apply()
assert(M.coords.text=="25.0, 75.0" and M.fps.text=="60 FPS  120 ms")
assert(M.zone.color[2]==.9)
local before=mapResets
WorldMapFrame:Show(); M.UpdateText(); assert(M.coords.text=="" and mapResets==before)
WorldMapFrame:Hide(); M.UpdateText(); assert(M.coords.text=="25.0, 75.0" and mapResets==before+1)
p.clockServer=true; p.clockFormat="24h"; p.zoneShowSubZone=true; M.UpdateText()
assert(M.clock.text=="22:15" and M.zone.text=="Valley")
p.shape="circle"; M.Apply(); assert(GetMinimapShape()=="ROUND" and Minimap.mask=="Textures\\\\MinimapMask")
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
p.groupAddonButtons=true; M.Apply()
assert(addonButton:GetParent()==M.popup and M.groupButton:IsShown())
M.groupButton:GetScript("OnClick")(M.groupButton); assert(M.popup:IsShown())
addonButton:GetScript("OnClick")(addonButton); addonButton.hooks.OnClick(addonButton)
assert(buttonClicks==1 and not M.popup:IsShown())
p.hideAddonButtons=true; M.Apply(); assert(addonButton:GetParent()==M.hidden and addonButton:IsShown())
p.hideAddonButtons=false; p.groupAddonButtons=false; M.Apply()
assert(addonButton:GetParent()==Minimap and addonButton:GetWidth()==200 and addonButton:GetPoint()=="CENTER")
p.hideTrackingButton=true; M.Apply(); assert(MiniMapTrackingButton:GetAlpha()==0 and not MiniMapTrackingButton:IsMouseEnabled())
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
    WideButton=function(_,parent,label,y,fn) resetPosition=fn; return {},50 end,
}
local height=testModule.buildPage("Minimap",UIParent,0)
assert(height>0 and #rows==17)
rows[2][1].setValue(190); assert(Minimap:GetWidth()==190 and rows[2][1].getValue()==190)
rows[2][2].setValue("square"); assert(GetMinimapShape()=="SQUARE")
M.GetSettings().position={point="CENTER",relPoint="CENTER",x=1,y=1}
resetPosition(); assert(M.GetSettings().position==nil)
''')
print('PASS: real Lua51 Core lifecycle; middle-click menu without EasyMenu, securecall dispatch for native toggles/clicks, Spellbook open/close, optional entries, disabled controls, theme/font, dismissal/combat/restore; Minimap layout/clock/zone/map/zoom/movers/buttons/options; native taint requires client confirmation.')
