-- EllesmereUI Minimap: native Wrath implementation. Retail reference stays unloaded.
local ADDON_NAME, ns = ...
local E = EllesmereUI
if not E or not E.Lite or not Minimap then return end
E._ModuleNS[ADDON_NAME] = ns
local addon = E.Lite.NewAddon(ADDON_NAME)
ns.addon, ns.IsWrath = addon, true
local defaults = {profile={minimap={
    enabled=true, shape="square", size=180, borderSize=1,
    borderR=0, borderG=0, borderB=0, borderA=1, useClassColor=false,
    lock=false, scrollZoom=true, savedZoom=0, zoomResetSeconds=0,
    rotateMinimap=false, openMicroMenuOnMiddleClick=true,
    showCoords=false, coordPrecision=0, showFPS=false,
    clockMode="inside", clockFormat="12h", clockServer=false,
    locationMode="inside", zoneShowSubZone=false, zoneReactiveColor=false,
    hideZoomButtons=false, hideTrackingButton=false, hideMail=false,
    hideGameTime=false, hideRaidDifficulty=false, hideQueueStatus=false, hideAddonButtons=false,
    groupAddonButtons=false, addonBtnSize=24,
    visibility="always", opacity=100, visHideMounted=false, visHideNoTarget=false,
}}}
ns.defaults = defaults
local owned, buttonState = {}, {}
local original, active, pending, dragging, zoomTimer
local border, borderTex, texts, groupButton, popup, menuFrame, menuDismiss
local elapsed, mapDirty, mapWasOpen = 0, true, false
local oldGetShape = GetMinimapShape

local function Size(frame,w,h) frame:SetWidth(w); frame:SetHeight(h) end
local function Frame(kind,parent)
    local f=CreateFrame(kind,nil,parent); owned[f]=true; return f
end
local function Points(frame)
    local points={}
    for i=1,frame:GetNumPoints() do points[i]={frame:GetPoint(i)} end
    return points
end
local function RestorePoints(frame,points)
    frame:ClearAllPoints()
    for _,point in ipairs(points) do frame:SetPoint(unpack(point)) end
end
local function Snapshot(frame)
    return {parent=frame:GetParent(),points=Points(frame),width=frame:GetWidth(),height=frame:GetHeight(),
        scale=frame:GetScale(),alpha=frame:GetAlpha(),level=frame:GetFrameLevel(),
        mouse=frame.IsMouseEnabled and frame:IsMouseEnabled()}
end
local function RestoreFrame(frame,s)
    frame:SetParent(s.parent); RestorePoints(frame,s.points)
    Size(frame,s.width,s.height); frame:SetScale(s.scale); frame:SetAlpha(s.alpha)
    frame:SetFrameLevel(s.level)
    if s.mouse~=nil and frame.EnableMouse then frame:EnableMouse(s.mouse) end
end
function ns.GetSettings() return addon.db and addon.db.profile.minimap end
function ns.GetShape()
    local p=ns.GetSettings()
    if p and (p.useClassicStyle or p.useBlizzardStyle) then return "circle" end
    return p and p.shape or "square"
end
local function SnapshotNative()
    if original then return end
    original=Snapshot(Minimap)
    original.mask=Minimap.GetMaskTexture and Minimap:GetMaskTexture() or "Textures\\MinimapMask"
    original.wheel=Minimap:GetScript("OnMouseWheel")
    original.mouseUp=Minimap:GetScript("OnMouseUp")
    original.wheelEnabled=Minimap.IsMouseWheelEnabled and Minimap:IsMouseWheelEnabled()
    original.movable=Minimap.IsMovable and Minimap:IsMovable()
    original.clamped=Minimap.IsClampedToScreen and Minimap:IsClampedToScreen()
    original.rotate=GetCVar("rotateMinimap")
    original.zoom=Minimap:GetZoom()
    original.shown=Minimap:IsShown()
    original.decorations={}
    for _,name in ipairs({"MinimapBorder","MinimapBorderTop","MinimapNorthTag","MinimapZoneTextButton","MinimapZoneText","TimeManagerClockButton"}) do
        local f=_G[name]
        if f then original.decorations[f]={alpha=f:GetAlpha(),mouse=f.IsMouseEnabled and f:IsMouseEnabled()} end
    end
end
local nativeNames={"MinimapZoomIn","MinimapZoomOut","MiniMapTrackingButton","MiniMapMailFrame","GameTimeFrame",
    "MiniMapInstanceDifficulty","GuildInstanceDifficulty","MiniMapWorldMapButton","MiniMapBattlefieldFrame"}
local native={}
for _,name in ipairs(nativeNames) do if _G[name] then native[_G[name]]=true end end
local function RememberButton(f)
    if not buttonState[f] then buttonState[f]=Snapshot(f) end
    return buttonState[f]
end
function ns.ScanButtons()
    local buttons, seen={},{}
    local function Add(f)
        if not f or seen[f] or owned[f] or native[f] then return end
        if not f.GetName or not f:GetName() or not f:IsObjectType("Button") then return end
        if f.IsProtected and f:IsProtected() then return end
        seen[f]=true; RememberButton(f); buttons[#buttons+1]=f
    end
    for _,f in ipairs({Minimap:GetChildren()}) do Add(f) end
    for f in pairs(buttonState) do if not native[f] then Add(f) end end
    table.sort(buttons,function(a,b) return a:GetName()<b:GetName() end)
    ns.buttons=buttons
    return buttons
end
local function MakeText(parent,size)
    local f=parent:CreateFontString(nil,"OVERLAY")
    E.ApplyModuleFont(f,nil,size,"minimap")
    f:SetTextColor(1,1,1,1); return f
end
local function EnsureUI()
    if border then return end
    border=Frame("Frame",UIParent)
    border:SetFrameLevel(math.max(0,Minimap:GetFrameLevel()-1))
    borderTex=border:CreateTexture(nil,"BACKGROUND"); borderTex:SetAllPoints()
    texts=Frame("Frame",Minimap); texts:SetAllPoints(); texts:SetFrameLevel(Minimap:GetFrameLevel()+5)
    ns.clock=MakeText(texts,11); ns.clock:SetPoint("TOP",Minimap,"TOP",0,-5)
    ns.zone=MakeText(texts,11); ns.zone:SetPoint("BOTTOM",Minimap,"BOTTOM",0,5)
    ns.coords=MakeText(texts,10); ns.coords:SetPoint("TOPLEFT",Minimap,"TOPLEFT",5,-22)
    ns.fps=MakeText(texts,10); ns.fps:SetPoint("BOTTOMLEFT",Minimap,"BOTTOMLEFT",5,22)
    popup=Frame("Frame",Minimap)
    popup:SetFrameStrata("DIALOG"); popup:SetFrameLevel(Minimap:GetFrameLevel()+15)
    popup:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    popup:SetBackdropColor(.06,.06,.06,.95); popup:SetBackdropBorderColor(0,0,0,1)
    popup:SetPoint("TOPRIGHT",Minimap,"BOTTOMRIGHT",0,-4); popup:Hide()
    groupButton=Frame("Button",Minimap); Size(groupButton,20,20)
    groupButton:SetFrameLevel(Minimap:GetFrameLevel()+10)
    groupButton:SetPoint("BOTTOMLEFT",Minimap,"BOTTOMLEFT",3,3)
    local label=MakeText(groupButton,16); label:SetPoint("CENTER"); label:SetText("+")
    groupButton:RegisterForClicks("LeftButtonUp")
    groupButton:SetScript("OnClick",function() if popup:IsShown() then popup:Hide() else popup:Show() end end)
    groupButton:Hide()
    ns.popup, ns.groupButton, ns.border = popup,groupButton,border
    Minimap:HookScript("OnHide",function() border:Hide(); popup:Hide(); if menuFrame then menuFrame:Hide() end end)
    Minimap:HookScript("OnShow",function()
        local p=ns.GetSettings(); if active and p and p.borderSize>0 then border:Show() end
    end)
    Minimap:HookScript("OnMouseDown",function(self,button)
        local p=ns.GetSettings()
        if active and button=="LeftButton" and IsShiftKeyDown() and not p.lock and not InCombatLockdown() then
            dragging=true; self:StartMoving()
        end
    end)
end
function ns.ReadCoordinates()
    -- Legacy map position uses the world-map context. Never move the map while
    -- the player is browsing it; resume the current-zone context after it closes.
    if WorldMapFrame and WorldMapFrame:IsShown() then mapWasOpen=true; return end
    if mapDirty or mapWasOpen then SetMapToCurrentZone(); mapDirty=false; mapWasOpen=false end
    local x,y=GetPlayerMapPosition("player")
    if not x or not y or (x==0 and y==0) then return end
    return x*100,y*100
end
function ns.UpdateText()
    if not active or not texts then return end
    local p=ns.GetSettings()
    if p.clockMode~="none" then
        local hour,minute
        if p.clockServer then hour,minute=GetGameTime() else local t=date("*t"); hour,minute=t.hour,t.min end
        local suffix=""
        if p.clockFormat~="24h" then suffix=hour>=12 and " PM" or " AM"; hour=hour%12; if hour==0 then hour=12 end end
        ns.clock:SetText(string.format("%02d:%02d%s",hour,minute,suffix)); ns.clock:Show()
    else ns.clock:Hide() end
    if p.locationMode~="none" then
        local zone=p.zoneShowSubZone and GetSubZoneText() or GetZoneText()
        if not zone or zone=="" then zone=GetZoneText() end
        ns.zone:SetText(zone or "")
        local r,g,b=1,1,1
        if p.zoneReactiveColor and GetZonePVPInfo then
            local kind=GetZonePVPInfo()
            if kind=="friendly" then r,g,b=.1,.9,.1 elseif kind=="sanctuary" then r,g,b=.1,.6,1
            elseif kind=="hostile" or kind=="combat" or kind=="arena" then r,g,b=1,.2,.2 else r,g,b=1,.9,.1 end
        end
        ns.zone:SetTextColor(r,g,b,1); ns.zone:Show()
    else ns.zone:Hide() end
    if p.showCoords then
        local x,y=ns.ReadCoordinates()
        local precision=math.max(0,math.min(2,p.coordPrecision or 0))
        ns.coords:SetText(x and string.format("%."..precision.."f, %."..precision.."f",x,y) or ""); ns.coords:Show()
    else ns.coords:Hide() end
    if p.showFPS then
        local _,_,latency=GetNetStats()
        ns.fps:SetText(string.format("%d FPS  %d ms",math.floor(GetFramerate()+.5),latency or 0)); ns.fps:Show()
    else ns.fps:Hide() end
end
local function SavePosition()
    local x,y=Minimap:GetCenter()
    if not x or not y then return end
    local scale=Minimap:GetEffectiveScale()/UIParent:GetEffectiveScale()
    ns.GetSettings().position={point="CENTER",relPoint="BOTTOMLEFT",x=x*scale,y=y*scale}
end
local menuItems={
    {text="Character",buttons={"CharacterMicroButton"},fn="ToggleCharacter",args={"PaperDollFrame"}},
    {text="Talents",buttons={"TalentMicroButton","PlayerSpellsMicroButton"},fn="ToggleTalentFrame"},
    {text="Spellbook",buttons={"SpellbookMicroButton"},fn="ToggleSpellBook",args={"spell"}},
    {text="Professions",buttons={"ProfessionMicroButton"},fn="ToggleCharacter",args={"SkillFrame"}},
    {divider=true},
    {text="Group Finder",buttons={"LFDMicroButton"},fn="ToggleLFDParentFrame"},
    {text="Adventure Guide",buttons={"EJMicroButton"},optional=true},
    {text="Achievements",buttons={"AchievementMicroButton"},fn="ToggleAchievementFrame"},
    {text="Collections",buttons={"CollectionsMicroButton"},optional=true},
    {text="Quest Log",buttons={"QuestLogMicroButton"},fn="ToggleQuestLog"},
    {text="PvP",buttons={"PVPMicroButton"},fn="TogglePVPFrame"},
    {divider=true},
    {text="Friends",buttons={"SocialsMicroButton","QuickJoinToastButton"},fn="ToggleFriendsFrame",args={1}},
    {text="Guild",buttons={"GuildMicroButton"},fn="ToggleFriendsFrame",args={3},guild=true},
    {text="Housing",buttons={"HousingMicroButton"},optional=true},
    {text="Calendar",fn="ToggleCalendar"},
    {divider=true},
    {text="Game Menu",buttons={"MainMenuMicroButton"},fn="ToggleFrame",frame="GameMenuFrame"},
    {text="Shop",buttons={"StoreMicroButton"},optional=true},
    {text="Support",buttons={"HelpMicroButton"},fn="ToggleHelpFrame"},
}
local function MenuAction(item)
    local fn=item.fn and _G[item.fn]
    local function ToggleNative()
        local args=item.frame and {_G[item.frame]} or item.args or {}
        -- Keep native UIPanel bookkeeping in Blizzard's call path so Escape
        -- can close the window without inheriting the menu callback's taint.
        if securecall then return securecall(item.fn,unpack(args)) end
        return fn(unpack(args))
    end
    for _,name in ipairs(item.buttons or {}) do
        local b=_G[name]
        if b and type(b.Click)=="function" and b.GetScript and b:GetScript("OnClick") then
            local enabled=not b.IsEnabled or b:IsEnabled()
            local action=type(fn)=="function" and (not item.frame or _G[item.frame]) and ToggleNative or function()
                if securecall then return securecall(b.Click,b,"LeftButton") end
                return b:Click("LeftButton")
            end
            return action,enabled and enabled~=0
        end
    end
    if type(fn)=="function" and (not item.frame or _G[item.frame]) then
        return ToggleNative,
            not item.guild or not IsInGuild or IsInGuild()
    end
end
local function CloseMenu() if menuFrame then menuFrame:Hide() end end
ns.CloseMicroMenu=CloseMenu
local function EnsureMenu()
    if menuFrame then return end
    -- The native dismissal surface works on Wrath without GLOBAL_MOUSE_DOWN,
    -- EasyMenu, modern menu factories or any external menu library.
    menuDismiss=CreateFrame("Frame","EUI335MinimapMicroMenuDismiss",UIParent); owned[menuDismiss]=true
    menuDismiss:SetAllPoints(UIParent); menuDismiss:SetFrameStrata("DIALOG"); menuDismiss:SetFrameLevel(100)
    menuDismiss:EnableMouse(true); menuDismiss:Hide()
    menuDismiss:SetScript("OnMouseUp",CloseMenu)
    menuFrame=CreateFrame("Frame","EUI335MinimapMicroMenu",UIParent); owned[menuFrame]=true
    menuFrame:SetFrameStrata("DIALOG"); menuFrame:SetFrameLevel(101); menuFrame:SetClampedToScreen(true)
    menuFrame:EnableMouse(true); menuFrame:Hide()
    menuFrame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    menuFrame:SetBackdropColor(.035,.04,.045,.98); menuFrame:SetBackdropBorderColor(.2,.25,.25,1)
    menuFrame.rows,menuFrame.dividers={},{}
    menuFrame:SetScript("OnHide",function() menuDismiss:Hide() end)
    if UISpecialFrames then UISpecialFrames[#UISpecialFrames+1]="EUI335MinimapMicroMenu" end
    ns.microMenu,ns.microMenuDismiss=menuFrame,menuDismiss
end
function ns.ToggleMicroMenu()
    local p=ns.GetSettings()
    if not active or not p or not p.enabled or not p.openMicroMenuOnMiddleClick or InCombatLockdown() then return end
    if menuFrame and menuFrame:IsShown() then CloseMenu(); return end
    EnsureMenu()
    for _,b in pairs(menuFrame.rows) do b:Hide() end
    for _,t in ipairs(menuFrame.dividers) do t:Hide() end
    local y,dividers=6,0
    for index,item in ipairs(menuItems) do
        if item.divider then
            dividers=dividers+1
            local t=menuFrame.dividers[dividers]
            if not t then t=menuFrame:CreateTexture(nil,"ARTWORK"); t:SetTexture("Interface\\Buttons\\WHITE8X8"); menuFrame.dividers[dividers]=t end
            t:ClearAllPoints(); t:SetPoint("TOPLEFT",menuFrame,"TOPLEFT",8,-y-4); Size(t,144,1); t:SetVertexColor(.3,.3,.3,.6); t:Show(); y=y+9
        else
            local action,enabled=MenuAction(item)
            if not item.optional or action then
                local b=menuFrame.rows[index]
                if not b then
                    b=Frame("Button",menuFrame); menuFrame.rows[index]=b; b.item=item
                    b:RegisterForClicks("LeftButtonUp")
                    b.highlight=b:CreateTexture(nil,"HIGHLIGHT"); b.highlight:SetAllPoints(b); b.highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
                    b.label=MakeText(b,11); b.label:SetPoint("LEFT",b,"LEFT",7,0)
                    b:SetScript("OnClick",function(self)
                        if InCombatLockdown() then return end
                        local run,canRun=MenuAction(self.item)
                        if run and canRun then CloseMenu(); run() end
                    end)
                end
                E.ApplyModuleFont(b.label,nil,11,"minimap")
                local r,g,blue=.047,.824,.616
                if E.GetAccentColor then r,g,blue=E.GetAccentColor() end
                b.highlight:SetVertexColor(r,g,blue,.15)
                b.label:SetText(E.L and E.L(item.text) or item.text)
                b.label:SetTextColor(enabled and .92 or .4,enabled and .92 or .4,enabled and .92 or .4,1)
                b:ClearAllPoints(); b:SetPoint("TOPLEFT",menuFrame,"TOPLEFT",3,-y); Size(b,154,20)
                if action and enabled then b:Enable() else b:Disable() end
                b:Show(); y=y+20
            end
        end
    end
    Size(menuFrame,160,y+6); menuFrame:ClearAllPoints(); menuFrame:SetPoint("TOPRIGHT",Minimap,"TOPLEFT",-4,0)
    popup:Hide(); menuDismiss:Show(); menuFrame:Show()
end
ns._ToggleMicroMenu=ns.ToggleMicroMenu
local function RestartZoomTimer()
    if zoomTimer then zoomTimer:Cancel(); zoomTimer=nil end
    local seconds=ns.GetSettings().zoomResetSeconds or 0
    if seconds>0 then zoomTimer=C_Timer.NewTimer(seconds,function()
        zoomTimer=nil
        if active then Minimap:SetZoom(0); ns.GetSettings().savedZoom=0 end
    end) end
end
local function MouseUp(self,button)
    if dragging then dragging=false; self:StopMovingOrSizing(); SavePosition(); return end
    if button=="MiddleButton" and ns.GetSettings().openMicroMenuOnMiddleClick then ns.ToggleMicroMenu(); return end
    if original.mouseUp then original.mouseUp(self,button) end
end
local function Wheel(self,delta)
    local max=(self.GetZoomLevels and self:GetZoomLevels() or 6)-1
    local zoom=math.max(0,math.min(max,self:GetZoom()+(delta>0 and 1 or -1)))
    self:SetZoom(zoom); ns.GetSettings().savedZoom=zoom; RestartZoomTimer()
end
local function LayoutButtons()
    local p=ns.GetSettings()
    local controls={
        {"MinimapZoomIn","hideZoomButtons","BOTTOMRIGHT",-4,22},
        {"MinimapZoomOut","hideZoomButtons","BOTTOMRIGHT",-4,3},
        {"MiniMapTrackingButton","hideTrackingButton","TOPLEFT",-2,2},
        {"MiniMapMailFrame","hideMail","TOPRIGHT",0,0},
        {"GameTimeFrame","hideGameTime","TOPRIGHT",-22,0},
        {"MiniMapInstanceDifficulty","hideRaidDifficulty","TOPLEFT",24,0},
        {"GuildInstanceDifficulty","hideRaidDifficulty","TOPLEFT",24,0},
        {"MiniMapWorldMapButton","hideWorldMapButton","BOTTOMRIGHT",-24,3},
        {"MiniMapBattlefieldFrame","hideQueueStatus","BOTTOMLEFT",24,3},
        {"MiniMapLFGFrame","hideQueueStatus","BOTTOMLEFT",24,3},
    }
    for _,spec in ipairs(controls) do
        local f=_G[spec[1]]
        if f then
            native[f]=true; RememberButton(f)
            f:SetParent(Minimap); f:ClearAllPoints(); f:SetPoint(spec[3],Minimap,spec[3],spec[4],spec[5])
            f:SetFrameLevel(Minimap:GetFrameLevel()+10)
            f:SetAlpha(p[spec[2]] and 0 or 1)
            if f.EnableMouse then f:EnableMouse(not p[spec[2]]) end
        end
    end
    local buttons=ns.ScanButtons()
    local count=0
    for _,f in ipairs(buttons) do
        local s=buttonState[f]
        if p.hideAddonButtons then
            -- Hide the parent rather than the button: the addon's own Show/Hide
            -- continues to express whether it wants its button visible.
            if not ns.hidden then ns.hidden=Frame("Frame",UIParent); ns.hidden:Hide() end
            f:SetParent(ns.hidden)
        elseif p.groupAddonButtons then
            f:SetParent(popup); Size(f,p.addonBtnSize,p.addonBtnSize); f:SetScale(1)
            f:ClearAllPoints()
            f:SetPoint("TOPLEFT",popup,"TOPLEFT",4+(count%4)*(p.addonBtnSize+4),-4-math.floor(count/4)*(p.addonBtnSize+4))
            count=count+1
            if not s.closeHook then s.closeHook=true; f:HookScript("OnClick",function() popup:Hide() end) end
        else RestoreFrame(f,s) end
    end
    Size(popup,4+math.min(4,count)*(p.addonBtnSize+4),4+math.max(1,math.ceil(count/4))*(p.addonBtnSize+4))
    popup:Hide()
    if count>0 then groupButton:Show() else groupButton:Hide() end
end
function ns.Restore()
    if not original or not active then return end
    if InCombatLockdown() then pending=true; return end
    if zoomTimer then zoomTimer:Cancel(); zoomTimer=nil end
    if dragging then Minimap:StopMovingOrSizing(); dragging=false end
    active=false
    CloseMenu()
    RestoreFrame(Minimap,original); Minimap:SetMaskTexture(original.mask)
    Minimap:SetScript("OnMouseWheel",original.wheel); Minimap:SetScript("OnMouseUp",original.mouseUp)
    Minimap:EnableMouseWheel(original.wheelEnabled==true); Minimap:SetMovable(original.movable==true)
    if original.clamped~=nil then Minimap:SetClampedToScreen(original.clamped) end
    Minimap:SetZoom(original.zoom); SetCVar("rotateMinimap",original.rotate)
    for f,s in pairs(original.decorations) do
        f:SetAlpha(s.alpha); if s.mouse~=nil and f.EnableMouse then f:EnableMouse(s.mouse) end
    end
    for f,s in pairs(buttonState) do RestoreFrame(f,s) end
    GetMinimapShape=oldGetShape
    border:Hide(); texts:Hide(); popup:Hide(); groupButton:Hide()
    -- Restoring visibility after an explicit disable prevents a prior Never
    -- setting from leaving the native minimap hidden.
    if original.shown then Minimap:Show() else Minimap:Hide() end
end
function ns.UpdateVisibility()
    local p=ns.GetSettings()
    if not active or not p then return end
    if Minimap.IsProtected and Minimap:IsProtected() and InCombatLockdown() then return end
    local state={inCombat=UnitAffectingCombat("player") and true or false,
        inRaid=GetNumRaidMembers()>0,inParty=GetNumPartyMembers()>0}
    local mode=p.visibility or "always"
    local verdict=E.EvalVisibilityExtended and E.EvalVisibilityExtended(p,"visibility",state)
    if verdict==nil then
        if mode=="mouseover" then verdict="mouseover"
        elseif E.CheckVisibilityMode then verdict=E.CheckVisibilityMode(mode,state) else verdict=mode~="never" end
    end
    if verdict=="mouseover" then
        -- Keep the map's hit surface available at alpha zero for hover reveal.
        Minimap:Show(); verdict=MouseIsOver(Minimap) or (popup:IsShown() and MouseIsOver(popup))
        Minimap:SetAlpha(verdict and p.opacity/100 or 0)
    elseif verdict then Minimap:Show(); Minimap:SetAlpha(p.opacity/100)
    else Minimap:Hide() end
    if E.CheckVisibilityOptions and E.CheckVisibilityOptions(p) then Minimap:Hide(); verdict=false end
    if verdict and p.borderSize>0 and Minimap:IsShown() then border:SetAlpha(p.opacity/100); border:Show() else border:Hide() end
end
function ns.Apply()
    local p=ns.GetSettings(); if not p then return end
    if InCombatLockdown() then pending=true; return end
    pending=false
    if not p.enabled then ns.Restore(); return end
    SnapshotNative(); EnsureUI(); active=true
    CloseMenu(); Minimap:EnableMouse(true)
    local size=math.max(100,math.min(400,tonumber(p.size) or 180))
    Minimap:SetParent(UIParent); Size(Minimap,size,size); Minimap:SetScale(1)
    Minimap:ClearAllPoints()
    local position=p.position
    if position then Minimap:SetPoint(position.point,UIParent,position.relPoint,position.x,position.y)
    else Minimap:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-24,-24) end
    Minimap:SetMovable(not p.lock); Minimap:SetClampedToScreen(true)
    local circle=ns.GetShape()=="circle"
    Minimap:SetMaskTexture(circle and "Textures\\MinimapMask" or "Interface\\Buttons\\WHITE8X8")
    GetMinimapShape=function() return active and (ns.GetShape()=="circle" and "ROUND" or "SQUARE") or (oldGetShape and oldGetShape() or "ROUND") end
    border:ClearAllPoints(); border:SetPoint("CENTER",Minimap,"CENTER")
    Size(border,size+2*p.borderSize,size+2*p.borderSize)
    borderTex:SetTexture(circle and "Interface\\AddOns\\EllesmereUI\\media\\portraits\\circle_mask.tga" or "Interface\\Buttons\\WHITE8X8")
    local r,g,b=p.borderR,p.borderG,p.borderB
    if p.useClassColor then local c=E.GetClassColor(select(2,UnitClass("player"))); if c then r,g,b=c.r,c.g,c.b end end
    borderTex:SetVertexColor(r,g,b,p.borderA)
    for f in pairs(original.decorations) do f:SetAlpha(0); if f.EnableMouse then f:EnableMouse(false) end end
    SetCVar("rotateMinimap",p.rotateMinimap and "1" or "0")
    Minimap:SetScript("OnMouseUp",MouseUp)
    Minimap:EnableMouseWheel(p.scrollZoom)
    Minimap:SetScript("OnMouseWheel",p.scrollZoom and Wheel or original.wheel)
    local max=(Minimap.GetZoomLevels and Minimap:GetZoomLevels() or 6)-1
    Minimap:SetZoom(math.max(0,math.min(max,p.savedZoom or 0)))
    if zoomTimer then zoomTimer:Cancel(); zoomTimer=nil end
    texts:Show(); LayoutButtons(); ns.UpdateText(); ns.UpdateVisibility()
end
function addon:OnInitialize()
    addon.db=E.Lite.NewDB("EllesmereUIMinimapDB",defaults)
    _G._EMM_DB=addon.db
    _G._EMM_ApplyMinimap=ns.Apply
    _G._EMM_FullRebuildMinimap=ns.Apply
    _G._EMM_ApplyMapAlpha=ns.UpdateVisibility
    if E.RegisterVisibilityUpdater then E.RegisterVisibilityUpdater(ns.UpdateVisibility) end
end
function addon:OnEnable()
    ns.Apply()
    if E.RegisterUnlockElements and E.MakeUnlockElement then
        E:RegisterUnlockElements({E.MakeUnlockElement({key="EBS_Minimap",label="Minimap",group="Minimap",order=500,
            noResize=true,noAnchorTo=true,getFrame=function() return Minimap end,
            getSize=function() return Minimap:GetWidth(),Minimap:GetHeight() end,
            isHidden=function() local p=ns.GetSettings(); return not p or not p.enabled end,
            savePos=function(_,point,relPoint,x,y) ns.GetSettings().position={point=point,relPoint=relPoint,x=x,y=y} end,
            loadPos=function() return ns.GetSettings().position end,
            clearPos=function() ns.GetSettings().position=nil end,applyPos=ns.Apply,
        })},ADDON_NAME)
    end
    local events=Frame("Frame",UIParent)
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","ZONE_CHANGED","ZONE_CHANGED_INDOORS",
        "ZONE_CHANGED_NEW_AREA","ADDON_LOADED","UPDATE_PENDING_MAIL","PLAYER_TARGET_CHANGED","UNIT_AURA",
        "PARTY_MEMBERS_CHANGED","RAID_ROSTER_UPDATE","PLAYER_REGEN_DISABLED"}) do events:RegisterEvent(event) end
    events:SetScript("OnEvent",function(_,event,unit)
        if event=="UNIT_AURA" and unit~="player" then return end
        if event=="PLAYER_REGEN_DISABLED" then CloseMenu() end
        if event=="PLAYER_REGEN_ENABLED" and pending then ns.Apply()
        elseif event=="ADDON_LOADED" then if active then ns.Apply() end
        elseif event=="PLAYER_ENTERING_WORLD" then mapDirty=true; ns.Apply()
        else mapDirty=true; ns.UpdateText(); ns.UpdateVisibility() end
    end)
    events:SetScript("OnUpdate",function(_,dt)
        if not active then return end
        elapsed=elapsed+dt
        if elapsed>=.5 then elapsed=0; ns.UpdateText(); ns.UpdateVisibility() end
    end)
    ns.events=events
end
