-- EllesmereUI Minimap: native Wrath implementation. Retail reference stays unloaded.
local ADDON_NAME, ns = ...
local E = EllesmereUI
if not E or not E.Lite or not Minimap then return end
E._ModuleNS[ADDON_NAME] = ns
local addon = E.Lite.NewAddon(ADDON_NAME)
ns.addon, ns.IsWrath = addon, true
local floor, max, min, format = math.floor, math.max, math.min, string.format
local WHITE = "Interface\\Buttons\\WHITE8X8"
local MEDIA = "Interface\\AddOns\\EllesmereUIMinimap\\"
local CIRCLE = "Interface\\AddOns\\EllesmereUI\\media\\portraits\\circle_mask.tga"
local RING = "Interface\\AddOns\\EllesmereUI\\media\\portraits\\pixels_ring_textured.tga"
local ROUND_MASK, RECT_MASK = "Textures\\MinimapMask", MEDIA.."Media\\minimap_rectangular-crop-mask.tga"
-- circle_mask.tga draws a 104px disc on its 128px canvas; the textured ring's
-- inner edge sits at radius 55 of 64.
local DISC_FILL, RING_INNER = 104/128, 55/64
local defaults = {profile={minimap={
    enabled=true, useClassicStyle=false, shape="square", size=180, rotateMinimap=false,
    borderSize=1, borderR=0, borderG=0, borderB=0, borderA=1, useClassColor=false,
    borderUseClassColor=false, borderTexture="solid", borderBehind=false,
    lock=false, scrollZoom=true, savedZoom=0, zoomResetSeconds=0, openMicroMenuOnMiddleClick=true,
    showCoords=false, coordPrecision=0, coordsMode="always", coordsPosition="topLeft", coordsScale=1,
    showFPS=false, fpsTextSize=12, fpsScale=1, fpsShowLocalMS=true, fpsUseAccent=false,
    fpsColorClockAMPM=false, fpsPosition="bottomLeft", fpsOffsetX=0, fpsOffsetY=0,
    fpsHoverTooltip="none", fpsUpdateInterval=3, clockHoverTooltip="none",
    diffTextEnabled=false, diffTextPosition="topLeft", diffTextSize=12, diffTextOffsetX=0, diffTextOffsetY=0,
    fpsColorSuffix=true, diffTextAccent=false, diffTextReactive=false,
    clockMode="inside", clockPosition="top", clockFormat="12h", clockServer=false,
    clockScale=1.15, clockOffsetX=0, clockOffsetY=0,
    locationMode="inside", locationPosition="bottom", zoneShowSubZone=false, zoneReactiveColor=false,
    locationScale=1.15, locationOffsetX=0, locationOffsetY=0,
    hideZoomButtons=false, hideTrackingButton=false, hideMail=false, hideGameTime=false,
    hideRaidDifficulty=false, hideQueueStatus=false, hideWorldMapButton=true, hideAddonButtons=false,
    mailPosition="button", mailOffsetX=0, mailOffsetY=0,
    friendsMaxRows=0, friendsShowNotes=false, hideExtraBtns={friendsOnline=false, groupButton=false},
    mouseoverExtraBtns=false,
    addonBtnSize=24, interactableBtnSize=21, ungroupedButtons={}, freeMoveBtns=false, btnBackgrounds=true,
    btnPositions={}, btnRowPosition="blUp", btnRowSpacing=0, btnRowDistance=0, flyoutGrowDir="auto",
    elementRowPosition="tlDown", elementRowSpacing=0, elementRowDistance=0, customTooltipScale=1,
    visibility="always", opacity=100, visOnlyInstances=false, visHideMounted=false,
    visHideNoTarget=false, visHideNoEnemy=false,
}}}
ns.defaults = defaults
local owned, buttonState = {}, {}
local original, active, pending, dragging, zoomTimer, moving, extrasHideAt
local ui = {}
local menuFrame, menuDismiss
local elapsed, fpsElapsed, hoverElapsed, mapDirty, mapWasOpen, lastMail = 0, 0, 0, true, false, nil
local oldGetShape = GetMinimapShape

local function L(s) return E.L and E.L(s) or s end
local function Size(frame,w,h) frame:SetWidth(w); frame:SetHeight(h) end
local function Frame(kind,parent,name)
    local f=CreateFrame(kind,name,parent); owned[f]=true; return f
end
local function Tex(parent,layer,path)
    local t=parent:CreateTexture(nil,layer); t:SetTexture(path or WHITE); return t
end
local function Clamp(v,lo,hi,fallback) return max(lo,min(hi,tonumber(v) or fallback)) end
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
function ns.GetStyle()
    local p=ns.GetSettings()
    return p and p.useClassicStyle and "classic" or "eui"
end
function ns.GetShape()
    local p=ns.GetSettings()
    if p and (p.useClassicStyle or p.useBlizzardStyle) then return "circle" end
    return p and p.shape or "square"
end
ns.MinimapStyle=ns.GetStyle
local function IsRound(shape) return shape=="circle" or shape=="textured_circle" end
local function Accent()
    if E.GetAccentColor then local r,g,b=E.GetAccentColor(); if r then return r,g,b end end
    local c=E.ELLESMERE_GREEN
    if c then return c.r,c.g,c.b end
    return .047,.824,.616
end
local function Hex(r,g,b) return format("%02x%02x%02x",floor(r*255+.5),floor(g*255+.5),floor(b*255+.5)) end
local function DescColor(p)
    local r,g,b=1,1,1
    if p.fpsUseAccent then r,g,b=Accent()
    elseif p.fpsColor then r,g,b=p.fpsColor.r or 1,p.fpsColor.g or 1,p.fpsColor.b or 1 end
    return r,g,b,Hex(r,g,b)
end
-- Retail precedence: class colour, then accent (useClassColor), then the swatch.
local function BorderColor(p)
    local a=p.borderA or 1
    if p.borderUseClassColor and E.GetClassColor then
        local c=E.GetClassColor(select(2,UnitClass("player")))
        if c then return c.r,c.g,c.b,a end
    end
    if p.useClassColor then local r,g,b=Accent(); return r,g,b,a end
    if p.borderColor then return p.borderColor.r,p.borderColor.g,p.borderColor.b,a end
    return p.borderR or 0,p.borderG or 0,p.borderB or 0,a
end
ns.BorderColor=BorderColor
local function MakeText(parent,size)
    local f=parent:CreateFontString(nil,"OVERLAY")
    E.ApplyModuleFont(f,nil,size,"minimap")
    f:SetTextColor(1,1,1,1); return f
end
local MAP_POS={
    belowMap={"TOP","BOTTOM",0,-5}, aboveMap={"BOTTOM","TOP",0,5},
    topLeft={"TOPLEFT","TOPLEFT",4,-4}, top={"TOP","TOP",0,-4}, topRight={"TOPRIGHT","TOPRIGHT",-4,-4},
    left={"LEFT","LEFT",4,0}, right={"RIGHT","RIGHT",-4,0},
    bottomLeft={"BOTTOMLEFT","BOTTOMLEFT",4,4}, bottom={"BOTTOM","BOTTOM",0,4}, bottomRight={"BOTTOMRIGHT","BOTTOMRIGHT",-4,4},
}
ns.MAP_POS=MAP_POS
-- Edge boxes straddle the border: 7px out on squares, 3px in on circles.
local function ResolveAnchor(pos,style,round)
    local a=MAP_POS[pos] or MAP_POS.top
    local x,y=a[3],a[4]
    if style=="edge" and pos~="belowMap" and pos~="aboveMap" then
        if x~=0 then x=round and (x>0 and 3 or -3) or (x>0 and -7 or 7) end
        if y~=0 then y=round and (y>0 and 3 or -3) or (y>0 and -7 or 7) end
    end
    return a[1],a[2],x,y
end
local function SnapshotNative()
    if original then return end
    original=Snapshot(Minimap)
    original.mask=Minimap.GetMaskTexture and Minimap:GetMaskTexture() or ROUND_MASK
    original.wheel=Minimap:GetScript("OnMouseWheel")
    original.mouseUp=Minimap:GetScript("OnMouseUp")
    original.wheelEnabled=Minimap.IsMouseWheelEnabled and Minimap:IsMouseWheelEnabled()
    original.movable=Minimap.IsMovable and Minimap:IsMovable()
    original.clamped=Minimap.IsClampedToScreen and Minimap:IsClampedToScreen()
    original.rotate=GetCVar("rotateMinimap")
    original.zoom=Minimap:GetZoom()
    original.shown=Minimap:IsShown()
    original.decorations={}
    for _,name in ipairs({"MinimapBorder","MinimapBorderTop","MinimapNorthTag","MinimapCompassTexture",
        "MinimapZoneTextButton","MinimapZoneText","TimeManagerClockButton","MiniMapVoiceChatFrame",
        "MinimapToggleButton","MiniMapTracking"}) do
        local f=_G[name]
        if f then original.decorations[f]={alpha=f:GetAlpha(),mouse=f.IsMouseEnabled and f:IsMouseEnabled()}; ns.MarkNative(f) end
    end
end
local nativeNames={"MinimapZoomIn","MinimapZoomOut","MiniMapTracking","MiniMapTrackingButton","MiniMapMailFrame",
    "GameTimeFrame","MiniMapInstanceDifficulty","GuildInstanceDifficulty","MiniMapWorldMapButton",
    "MiniMapBattlefieldFrame","MiniMapLFGFrame","MiniMapVoiceChatFrame","MinimapToggleButton",
    "MinimapZoneTextButton","TimeManagerClockButton","MinimapBackdrop"}
local native={}
for _,name in ipairs(nativeNames) do if _G[name] then native[_G[name]]=true end end
function ns.MarkNative(f) native[f]=true end
local function RememberButton(f)
    if not buttonState[f] then buttonState[f]=Snapshot(f) end
    return buttonState[f]
end
local pinPatterns={"^HandyNotes","^TomTom","^HereBeDragons","^Questie","^GatherMate","^Carbonite","^Routes","^pin","^Pin"}
local function IsAddonButton(f)
    if not f or owned[f] or native[f] or not f.GetName then return false end
    local name=f:GetName()
    if not name then return false end
    for _,pattern in ipairs(pinPatterns) do if name:match(pattern) then return false end end
    if f.IsProtected and f:IsProtected() then return false end
    if f:IsObjectType("Button") then return not name:match("%d+$") end
    return name:match("^LibDBIcon10_")~=nil
end
function ns.ScanButtons()
    local buttons,seen={},{}
    local function Add(f)
        if seen[f] or not IsAddonButton(f) then return end
        seen[f]=true; RememberButton(f); buttons[#buttons+1]=f
    end
    for _,f in ipairs({Minimap:GetChildren()}) do Add(f) end
    if ui.flyout then for _,f in ipairs({ui.flyout:GetChildren()}) do Add(f) end end
    for f in pairs(buttonState) do if not native[f] then Add(f) end end
    table.sort(buttons,function(a,b) return a:GetName()<b:GetName() end)
    ns.buttons=buttons
    return buttons
end
-- Retail strips the round-button chrome LibDBIcon-style buttons draw.
local JUNK={"TrackingBorder","UI%-Minimap%-Background","ZoomButton%-Highlight"}
local function Strip(f,inset,bg)
    local s=buttonState[f]
    if not s.strip then
        s.strip={}
        for _,r in ipairs({f:GetRegions()}) do
            local path=r.IsObjectType and r:IsObjectType("Texture") and r:GetTexture()
            if type(path)=="string" then
                for _,pattern in ipairs(JUNK) do
                    if path:find(pattern) then s.strip[#s.strip+1]={r,r:IsShown()}; break end
                end
            end
        end
        local icon=f.icon
        if type(icon)=="table" and icon.GetTexCoord then
            s.icon={points=Points(icon),w=icon:GetWidth(),h=icon:GetHeight(),coords={icon:GetTexCoord()}}
        end
        s.dragStart,s.dragStop=f:GetScript("OnDragStart"),f:GetScript("OnDragStop")
    end
    for _,entry in ipairs(s.strip) do entry[1]:Hide() end
    if s.icon then
        f.icon:ClearAllPoints()
        f.icon:SetPoint("TOPLEFT",f,"TOPLEFT",inset,-inset); f.icon:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-inset,inset)
        f.icon:SetTexCoord(.05,.95,.05,.95)
    end
    -- Library drag handlers would orbit the button round a circular map.
    f:SetScript("OnDragStart",nil); f:SetScript("OnDragStop",nil)
    if not f._euiBg then f._euiBg=Tex(f,"BACKGROUND"); f._euiBg:SetVertexColor(0,0,0,.8); f._euiBg:SetAllPoints(f) end
    if bg then f._euiBg:Show() else f._euiBg:Hide() end
end
local function Unstrip(f)
    local s=buttonState[f]
    if not s or not s.strip then return end
    for _,entry in ipairs(s.strip) do if entry[2] then entry[1]:Show() end end
    if s.icon then
        RestorePoints(f.icon,s.icon.points); Size(f.icon,s.icon.w,s.icon.h); f.icon:SetTexCoord(unpack(s.icon.coords))
    end
    f:SetScript("OnDragStart",s.dragStart); f:SetScript("OnDragStop",s.dragStop)
    if s.click~=nil then f:SetScript("OnClick",s.click or nil); s.click=nil end
    if f._euiBg then f._euiBg:Hide() end
end

-------------------------------------------------------------------------------
--  Tooltips: lockouts (clock, FPS, calendar) and Friends Online
-------------------------------------------------------------------------------
local function TooltipScale()
    local p=ns.GetSettings(); return Clamp(p and p.customTooltipScale,.5,2,1)
end
local function TipFrame()
    local f=Frame("Frame",UIParent)
    f:SetFrameStrata("TOOLTIP"); f:SetClampedToScreen(true); f:Hide()
    f:SetBackdrop({bgFile=WHITE,edgeFile=WHITE,edgeSize=1})
    f:SetBackdropColor(.067,.067,.067,.92); f:SetBackdropBorderColor(1,1,1,.15)
    return f
end
local function AnchorTip(tt,anchor)
    tt:ClearAllPoints()
    local x=anchor:GetCenter()
    if x and x*anchor:GetEffectiveScale()>UIParent:GetWidth()*UIParent:GetEffectiveScale()/2 then
        tt:SetPoint("TOPRIGHT",anchor,"TOPLEFT",-4,0)
    else tt:SetPoint("TOPLEFT",anchor,"TOPRIGHT",4,0) end
end
local function ServerTimeText()
    local h,m=GetGameTime()
    if GetCVar("timeMgrUseMilitaryTime")=="1" then return format("%02d:%02d",h,m) end
    local suffix=h>=12 and "PM" or "AM"; h=h%12; if h==0 then h=12 end
    return format("%d:%02d %s",h,m,suffix)
end
function ns.LockoutEntries()
    local list={}
    if not GetNumSavedInstances or not GetSavedInstanceInfo then return list end
    for i=1,GetNumSavedInstances() or 0 do
        local name,_,reset,difficulty,locked,extended,_,_,_,diffName=GetSavedInstanceInfo(i)
        if name and (locked or extended) then
            -- Wrath saves expose no encounter progress; the reset timer stands in.
            local right=diffName or ""
            if reset and reset>0 and SecondsToTime then right=right.."  |cff8c8c8c"..SecondsToTime(reset,true).."|r" end
            list[#list+1]={left=name,right=right,diff=difficulty or 0}
        end
    end
    table.sort(list,function(a,b) if a.left~=b.left then return a.left<b.left end return a.diff<b.diff end)
    return list
end
local TIP_PAD, TIP_ROW = 8, 14
local function HideLockouts() if ui.lockTT then ui.lockTT:Hide() end end
function ns.ShowLockouts(anchor,always)
    local entries=ns.LockoutEntries()
    if #entries==0 and not always then return end
    if RequestRaidInfo then RequestRaidInfo() end
    local tt=ui.lockTT
    if not tt then
        tt=TipFrame(); ui.lockTT,ns.lockoutTooltip=tt,tt; tt.rows={}
        tt.title=MakeText(tt,12); tt.title:SetTextColor(1,1,1,.9)
    end
    tt:SetScale(TooltipScale())
    E.ApplyModuleFont(tt.title,nil,12,"minimap")
    tt.title:SetText(L("Calendar")); tt.title:ClearAllPoints(); tt.title:SetPoint("TOP",tt,"TOP",0,-TIP_PAD)
    for _,row in ipairs(tt.rows) do row[1]:Hide(); row[2]:Hide() end
    local lines={}
    for _,entry in ipairs(entries) do lines[#lines+1]={entry.left,entry.right,1,.9} end
    if #entries==0 then lines[1]={"|cff888888"..L("No saved instances").."|r","",1,.9} end
    lines[#lines+1]={false}
    lines[#lines+1]={L("Server Time"),ServerTimeText(),.65,.8}
    local y,leftW,rightW,index=-TIP_PAD-14-6,0,0,0
    for _,line in ipairs(lines) do
        if line[1]==false then y=y-6 else
            index=index+1
            local row=tt.rows[index]
            if not row then row={MakeText(tt,10),MakeText(tt,10)}; tt.rows[index]=row end
            row[1]:SetJustifyH("LEFT"); row[2]:SetJustifyH("RIGHT")
            row[1]:SetText(line[1]); row[2]:SetText(line[2]); row[1]:SetTextColor(1,1,1,line[3]); row[2]:SetTextColor(1,1,1,line[4])
            row[1]:ClearAllPoints(); row[1]:SetPoint("TOPLEFT",tt,"TOPLEFT",TIP_PAD,y)
            row[2]:ClearAllPoints(); row[2]:SetPoint("TOPRIGHT",tt,"TOPRIGHT",-TIP_PAD,y)
            row[1]:Show(); row[2]:Show()
            leftW=max(leftW,row[1]:GetStringWidth() or 0); rightW=max(rightW,row[2]:GetStringWidth() or 0)
            y=y-TIP_ROW
        end
    end
    Size(tt,max(180,TIP_PAD*2+leftW+16+rightW),-y+TIP_PAD)
    AnchorTip(tt,anchor); tt:Show()
    return tt
end
local function ClassToken(localized)
    if not localized or localized=="" then return end
    for _,names in ipairs({LOCALIZED_CLASS_NAMES_MALE or {},LOCALIZED_CLASS_NAMES_FEMALE or {}}) do
        for token,name in pairs(names) do if name==localized then return token end end
    end
    return (localized:upper():gsub(" ",""))
end
function ns.GatherFriends()
    local guild,friends,seen={}, {}, {}
    local me=UnitName("player")
    if IsInGuild and IsInGuild() and GetNumGuildMembers and GetGuildRosterInfo then
        for i=1,GetNumGuildMembers(true) or 0 do
            local name,_,_,level,_,zone,note,_,online,_,class=GetGuildRosterInfo(i)
            if online and name and name~=me then
                guild[#guild+1]={name=name,full=name,class=class,zone=zone or "",level=level,note=note}
            end
        end
    end
    if BNGetNumFriends and BNGetFriendInfo then
        local ok,total=pcall(BNGetNumFriends)
        for i=1,(ok and tonumber(total)) or 0 do
            local ok2,_,given,surname,toonName,toonID,client,isOnline,_,_,_,_,note=pcall(BNGetFriendInfo,i)
            if ok2 and isOnline and client==(BNET_CLIENT_WOW or "WoW") then
                local zone,level,class="",nil,nil
                if toonID and BNGetToonInfo then
                    local ok3,_,name,_,_,_,_,className,_,area,lvl=pcall(BNGetToonInfo,toonID)
                    if ok3 then toonName=name or toonName; class=ClassToken(className); zone=area or ""; level=tonumber(lvl) end
                end
                local tag=given and surname and (given.." "..surname) or given
                friends[#friends+1]={name=toonName or tag or "???",full=toonName,class=class,zone=zone,
                    level=level,bnetTag=tag,bnetName=tag,note=note}
                if toonName then seen[toonName]=true end
            end
        end
    end
    if GetNumFriends and GetFriendInfo then
        for i=1,GetNumFriends() or 0 do
            local name,level,class,area,connected,_,note=GetFriendInfo(i)
            if connected and name and not seen[name] then
                friends[#friends+1]={name=name,full=name,class=ClassToken(class),zone=area or "",level=level,note=note}
            end
        end
    end
    local inGuild={}
    for _,entry in ipairs(guild) do inGuild[entry.name]=true end
    for i=#friends,1,-1 do if inGuild[friends[i].name] then table.remove(friends,i) end end
    table.sort(guild,function(a,b)
        if (a.zone=="")~=(b.zone=="") then return a.zone~="" end
        if a.zone~=b.zone then return a.zone<b.zone end
        return a.name<b.name
    end)
    table.sort(friends,function(a,b) return (a.bnetTag or a.name):lower()<(b.bnetTag or b.name):lower() end)
    return guild,friends
end
local FTT_ROW, FTT_NOTE, FTT_HDR = 16, 12, 14
local function ScheduleFriendsHide() if ui.friendsTT then ui.friendsTT._hideAt=GetTime()+.15 end end
local function CancelFriendsHide() if ui.friendsTT then ui.friendsTT._hideAt=nil end end
local function FriendRow(tt,index)
    local row=tt.rows[index]
    if row then return row end
    row=Frame("Button",tt); row:RegisterForClicks("AnyUp"); row:SetHeight(FTT_ROW)
    row.hl=Tex(row,"BACKGROUND"); row.hl:SetAllPoints(row); row.hl:SetVertexColor(1,1,1,.08); row.hl:Hide()
    row.name=MakeText(row,10); row.name:SetJustifyH("LEFT"); row.name:SetPoint("LEFT",row,"TOPLEFT",0,-FTT_ROW/2)
    row.zone=MakeText(row,10); row.zone:SetJustifyH("RIGHT"); row.zone:SetPoint("RIGHT",row,"TOPRIGHT",0,-FTT_ROW/2)
    row.note=MakeText(row,9); row.note:SetJustifyH("LEFT"); row.note:SetTextColor(.75,.75,.75,.9); row.note:SetHeight(FTT_NOTE)
    row.note:SetPoint("LEFT",row,"TOPLEFT",10,-FTT_ROW-FTT_NOTE/2); row.note:SetPoint("RIGHT",row,"TOPRIGHT",0,-FTT_ROW-FTT_NOTE/2)
    row:SetScript("OnEnter",function(self) CancelFriendsHide(); if self.entry then self.hl:Show() end end)
    row:SetScript("OnLeave",function(self) self.hl:Hide(); ScheduleFriendsHide() end)
    row:SetScript("OnClick",function(self,button)
        local entry=self.entry
        if not entry then return end
        if button=="RightButton" then
            if entry.full and InviteUnit then InviteUnit(entry.full) end
        elseif ChatFrame_SendTell then
            ChatFrame_SendTell(entry.bnetName or entry.full or entry.name)
        end
        tt:Hide()
    end)
    tt.rows[index]=row
    return row
end
function ns.ShowFriends(anchor)
    if GuildRoster and IsInGuild and IsInGuild() then GuildRoster() end
    local guild,friends=ns.GatherFriends()
    local p=ns.GetSettings()
    local tt=ui.friendsTT
    if not tt then
        tt=TipFrame(); ui.friendsTT,ns.friendsTooltip=tt,tt; tt.rows,tt.headers,tt.dividers={}, {}, {}
        tt:EnableMouse(true)
        tt:SetScript("OnEnter",CancelFriendsHide); tt:SetScript("OnLeave",ScheduleFriendsHide)
    end
    tt._hideAt=nil
    tt:SetScale(TooltipScale())
    for _,row in ipairs(tt.rows) do row:Hide(); row.entry=nil; row.note:Hide(); row:SetHeight(FTT_ROW) end
    for _,f in ipairs(tt.headers) do f:Hide() end
    for _,f in ipairs(tt.dividers) do f:Hide() end
    local cap=tonumber(p.friendsMaxRows) or 0
    if cap<=0 or cap>30 then cap=30 end
    local sections={}
    if #guild>0 then sections[#sections+1]={title="Guild",list=guild} end
    if #friends>0 then sections[#sections+1]={title="Friends",list=friends} end
    local y,rowIndex,nameW,zoneW,noteW=-TIP_PAD,0,0,0,0
    local accent=Hex(Accent())
    local function AddRow(text,zone,entry,note)
        rowIndex=rowIndex+1
        local row=FriendRow(tt,rowIndex)
        row.entry=entry; row.name:SetText(text); row.name:SetTextColor(1,1,1,.85); row.zone:SetText(zone or "")
        local h=FTT_ROW
        if note and note~="" then row.note:SetText(note); row.note:Show(); noteW=max(noteW,min(220,row.note:GetStringWidth() or 0)); h=h+FTT_NOTE end
        row:SetHeight(h); row:ClearAllPoints()
        row:SetPoint("TOPLEFT",tt,"TOPLEFT",TIP_PAD,y); row:SetPoint("TOPRIGHT",tt,"TOPRIGHT",-TIP_PAD,y)
        row:Show(); row.name:Show(); row.zone:Show()
        nameW=max(nameW,row.name:GetStringWidth() or 0); zoneW=max(zoneW,row.zone:GetStringWidth() or 0)
        y=y-h
    end
    if #sections==0 then AddRow("|cff888888"..L("No friends online").."|r") end
    for index,section in ipairs(sections) do
        if index>1 then
            local div=tt.dividers[index]
            if not div then div=Tex(tt,"ARTWORK"); div:SetVertexColor(1,1,1,.12); div:SetHeight(1); tt.dividers[index]=div end
            y=y-4; div:ClearAllPoints()
            div:SetPoint("TOPLEFT",tt,"TOPLEFT",TIP_PAD,y); div:SetPoint("TOPRIGHT",tt,"TOPRIGHT",-TIP_PAD,y); div:Show(); y=y-5
        end
        local header=tt.headers[index]
        if not header then header=MakeText(tt,12); header:SetTextColor(1,1,1,.9); tt.headers[index]=header end
        y=y-5; header:SetText(L(section.title).." (|cff"..accent..#section.list.."|r)")
        header:ClearAllPoints(); header:SetPoint("TOP",tt,"TOP",0,y); header:Show(); y=y-FTT_HDR-5
        for i=1,min(cap,#section.list) do
            local e=section.list[i]
            local c=e.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[e.class]
            local text=c and format("|cff%s%s|r",Hex(c.r,c.g,c.b),e.name) or e.name
            if e.bnetTag then text="|cffffd100"..e.bnetTag.."|r ("..text..")" end
            if tonumber(e.level) and tonumber(e.level)>0 then text=text.." |cffb0b0b0"..e.level.."|r" end
            AddRow(text,e.zone~="" and "|cff8c8c8c"..e.zone.."|r" or "",e,p.friendsShowNotes and e.note)
        end
        if #section.list>cap then AddRow(format("|cff888888...and %d more|r",#section.list-cap)) end
    end
    Size(tt,max(160,TIP_PAD*2+nameW+16+zoneW,TIP_PAD*2+10+noteW),-y+TIP_PAD)
    AnchorTip(tt,anchor); tt:Show()
    return tt
end

-------------------------------------------------------------------------------
--  Frames
-------------------------------------------------------------------------------
local function GameTip(owner,title,lines)
    if not GameTooltip then return end
    GameTooltip:SetOwner(owner,"ANCHOR_NONE"); AnchorTip(GameTooltip,owner)
    GameTooltip:SetText(title,1,1,1)
    for _,line in ipairs(lines or {}) do GameTooltip:AddLine(line,.8,.8,.8) end
    GameTooltip:Show()
end
local function HideGameTip() if GameTooltip then GameTooltip:Hide() end end
local function BeginMove(b)
    local p=ns.GetSettings()
    if not active or not p.freeMoveBtns or not b._moveKey or not b._base or not IsShiftKeyDown() or InCombatLockdown() then return end
    local x,y=GetCursorPosition()
    local saved=p.btnPositions[b._moveKey] or {}
    moving={b=b,x=x,y=y,ox=saved.x or 0,oy=saved.y or 0}
end
local function UpdateMove()
    if not moving then return end
    local m,p=moving,ns.GetSettings()
    local x,y=GetCursorPosition()
    local scale=m.b:GetEffectiveScale()
    local dx,dy=(x-m.x)/scale,(y-m.y)/scale
    if not m.moved and math.abs(dx)+math.abs(dy)<3 then return end
    m.moved=true; m.b._euiDragged=true
    local pos={x=floor(m.ox+dx+.5),y=floor(m.oy+dy+.5)}
    p.btnPositions[m.b._moveKey]=pos
    local a=m.b._base
    m.b:ClearAllPoints(); m.b:SetPoint(a[1],a[2],a[3],a[4]+pos.x,a[5]+pos.y)
end
ns.UpdateMove=UpdateMove
local function HookFreeMove(b)
    if b._euiMoveHooked then return end
    b._euiMoveHooked=true
    b:HookScript("OnMouseDown",function(self,button)
        self._euiDragged=nil
        if button=="LeftButton" then BeginMove(self) end
    end)
    b:HookScript("OnMouseUp",function() if moving then UpdateMove(); moving=nil end end)
end
local function Indicator(key,icon,inset)
    local b=Frame("Button",Minimap)
    b._indicatorKey,b._moveKey,b._inset=key,key,inset or 3
    b:SetFrameLevel(Minimap:GetFrameLevel()+10); b:RegisterForClicks("AnyUp")
    b.bg=Tex(b,"BACKGROUND"); b.bg:SetAllPoints(b); b.bg:SetVertexColor(0,0,0,.8)
    b.icon=Tex(b,"ARTWORK",icon)
    b.hl=Tex(b,"HIGHLIGHT"); b.hl:SetAllPoints(b.icon); b.hl:SetVertexColor(1,1,1,.15)
    b:SetScript("OnMouseDown",function(self) self.icon:SetAlpha(.75) end)
    b:SetScript("OnMouseUp",function(self) self.icon:SetAlpha(1) end)
    HookFreeMove(b)
    return b
end
-- Vanilla ring dress for Classic WoW UI; the EUI dress is the flat black square.
local function Dress(b,classic,size)
    if classic then
        Size(b,31,31); b.bg:Hide()
        if not b.ring then
            b.ring=Tex(b,"OVERLAY","Interface\\Minimap\\MiniMap-TrackingBorder"); Size(b.ring,53,53)
            b.ring:SetPoint("TOPLEFT",b,"TOPLEFT",0,0)
            b.disc=Tex(b,"BACKGROUND","Interface\\Minimap\\UI-Minimap-Background"); Size(b.disc,20,20)
            b.disc:SetPoint("CENTER",b,"TOPLEFT",16.6,-16.2)
            b.ringHL=Tex(b,"HIGHLIGHT","Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"); b.ringHL:SetBlendMode("ADD"); b.ringHL:SetAllPoints(b)
        end
        b.ring:Show(); b.disc:Show(); b.ringHL:Show(); b.hl:Hide()
        b.icon:ClearAllPoints(); Size(b.icon,16,16); b.icon:SetPoint("CENTER",b,"TOPLEFT",16.6,-16.2)
    else
        Size(b,size,size); b.bg:Show()
        if b.ring then b.ring:Hide(); b.disc:Hide(); b.ringHL:Hide() end
        b.hl:Show(); b.icon:ClearAllPoints()
        b.icon:SetPoint("TOPLEFT",b,"TOPLEFT",b._inset,-b._inset); b.icon:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-b._inset,b._inset)
    end
end
local function ToggleTime()
    if TimeManager_Toggle then TimeManager_Toggle()
    elseif ToggleTimeManager then ToggleTimeManager()
    elseif TimeManagerFrame and ToggleFrame then ToggleFrame(TimeManagerFrame) end
end
local function SecureToggle(name,...)
    if type(_G[name])~="function" then return end
    if securecall then return securecall(name,...) end
    return _G[name](...)
end
local function EnsureUI()
    if ui.layout then return end
    local level=Minimap:GetFrameLevel()
    ui.layout=Frame("Frame",Minimap); ui.layout:EnableMouse(false)
    ui.border=Frame("Frame",Minimap); ui.border:EnableMouse(false); ui.border.edges={}
    for i=1,4 do ui.border.edges[i]=Tex(ui.border,"BORDER") end
    ui.texBorder=Frame("Frame",Minimap); ui.texBorder:SetAllPoints(ui.layout); ui.texBorder:EnableMouse(false)
    -- The disc sits under the map; children cannot reliably draw below their parent.
    ui.disc=Frame("Frame",UIParent); ui.disc:SetPoint("CENTER",Minimap,"CENTER"); ui.disc:EnableMouse(false)
    ui.disc.tex=Tex(ui.disc,"BACKGROUND",CIRCLE); ui.disc.tex:SetAllPoints(ui.disc)
    ui.ring=Frame("Frame",Minimap); ui.ring:SetPoint("CENTER",Minimap,"CENTER"); ui.ring:SetFrameLevel(level+3)
    ui.ring.tex=Tex(ui.ring,"OVERLAY",RING); ui.ring.tex:SetAllPoints(ui.ring)
    ui.classicRing=Frame("Frame",Minimap); ui.classicRing:EnableMouse(false)
    local ringTex=Tex(ui.classicRing,"ARTWORK","Interface\\Minimap\\UI-Minimap-Border")
    ringTex:SetAllPoints(ui.classicRing); ringTex:SetTexCoord(.25,1,.125,.875)
    local header=Frame("Frame",Minimap); header:EnableMouse(false); ui.classicHeader=header
    local file="Interface\\Minimap\\UI-Minimap-Border"
    local capL=Tex(header,"ARTWORK",file); capL:SetTexCoord(.3125,.453125,0,.109375); Size(capL,36,28); capL:SetPoint("TOPLEFT",header,"TOPLEFT")
    local capR=Tex(header,"ARTWORK",file); capR:SetTexCoord(.9375,1,0,.109375); Size(capR,16,28); capR:SetPoint("TOPRIGHT",header,"TOPRIGHT")
    local mid=Tex(header,"ARTWORK",file); mid:SetTexCoord(.453125,.9375,0,.109375)
    mid:SetPoint("TOPLEFT",capL,"TOPRIGHT"); mid:SetPoint("BOTTOMRIGHT",capR,"BOTTOMLEFT")
    header.slot=Frame("Frame",header); header.slot:SetHeight(12); header.slot:SetPoint("CENTER",header,"CENTER",0,1)
    ui.texts=Frame("Frame",Minimap); ui.texts:SetAllPoints(ui.layout); ui.texts:SetFrameLevel(level+5)
    ui.clockBg=Frame("Button",ui.texts); Size(ui.clockBg,80,16); ui.clockBg:SetBackdrop({bgFile=WHITE})
    ui.clockBg:RegisterForClicks("LeftButtonUp")
    ns.clock=MakeText(ui.clockBg,10)
    ui.clockBg:SetScript("OnClick",ToggleTime)
    ui.clockBg:SetScript("OnEnter",function(self)
        if (ns.GetSettings().clockHoverTooltip or "none")=="lockouts" then ns.ShowLockouts(self) end
    end)
    ui.clockBg:SetScript("OnLeave",HideLockouts)
    ui.zoneBg=Frame("Frame",ui.texts); Size(ui.zoneBg,120,18); ui.zoneBg:SetBackdrop({bgFile=WHITE})
    ns.zone=MakeText(ui.zoneBg,10)
    ui.coordsBox=Frame("Frame",ui.texts); Size(ui.coordsBox,80,14)
    ns.coords=MakeText(ui.coordsBox,11)
    ui.fpsBg=Frame("Frame",ui.texts); Size(ui.fpsBg,60,20)
    ns.fps=MakeText(ui.fpsBg,12); ns.fps:SetPoint("LEFT",ui.fpsBg,"LEFT",0,0)
    ui.fpsDivider=Tex(ui.fpsBg,"OVERLAY"); Size(ui.fpsDivider,1,10); ui.fpsDivider:SetPoint("LEFT",ns.fps,"RIGHT",6,0)
    ns.fpsLocal=MakeText(ui.fpsBg,12); ns.fpsLocal:SetPoint("LEFT",ui.fpsDivider,"RIGHT",6,0)
    ui.fpsBg:SetScript("OnEnter",function(self)
        if (ns.GetSettings().fpsHoverTooltip or "none")=="lockouts" then ns.ShowLockouts(self) end
    end)
    ui.fpsBg:SetScript("OnLeave",HideLockouts)
    ns.diff=MakeText(ui.texts,12)
    local function Zoom(delta) return function() if ns.Wheel then ns.Wheel(Minimap,delta) end end end
    for key,spec in pairs({zoomIn={"+",1},zoomOut={"-",-1}}) do
        local b=Frame("Button",Minimap); Size(b,16,16); b:SetFrameLevel(level+10); b:RegisterForClicks("LeftButtonUp")
        b.bg=Tex(b,"BACKGROUND"); b.bg:SetAllPoints(b); b.bg:SetVertexColor(0,0,0,.6)
        b.label=MakeText(b,14); b.label:SetPoint("CENTER",b,"CENTER",0,1); b.label:SetText(spec[1])
        b:SetScript("OnClick",Zoom(spec[2])); ui[key]=b
    end
    ui.tracking=Indicator("tracking","Interface\\Minimap\\Tracking\\None")
    ui.tracking:SetScript("OnClick",function(self)
        if self._euiDragged then self._euiDragged=nil; return end
        if MiniMapTrackingDropDown and ToggleDropDownMenu then ToggleDropDownMenu(1,nil,MiniMapTrackingDropDown,self,0,0) end
    end)
    ui.tracking:SetScript("OnEnter",function(self) GameTip(self,TRACKING or L("Tracking")) end)
    ui.tracking:SetScript("OnLeave",HideGameTip)
    ui.calendar=Indicator("calendar","Interface\\Calendar\\UI-Calendar-Button",2)
    ui.calendar.icon:SetTexCoord(0,.390625,0,.78125)
    ui.calendar.day=MakeText(ui.calendar,9); ui.calendar.day:SetPoint("CENTER",ui.calendar.icon,"CENTER",0,-1); ui.calendar.day:SetTextColor(0,0,0,1)
    ui.calendar:SetScript("OnClick",function(self)
        if self._euiDragged then self._euiDragged=nil; return end
        SecureToggle("ToggleCalendar")
    end)
    ui.calendar:SetScript("OnEnter",function(self) ns.ShowLockouts(self,true) end)
    ui.calendar:SetScript("OnLeave",HideLockouts)
    ui.mail=Indicator("mail","Interface\\Icons\\INV_Letter_15"); ui.mail.icon:SetTexCoord(.08,.92,.08,.92)
    ui.mail:SetScript("OnEnter",function(self)
        local lines={}
        if GetLatestThreeSenders then for _,name in ipairs({GetLatestThreeSenders()}) do lines[#lines+1]=name end end
        GameTip(self,HAVE_MAIL_FROM and #lines>0 and HAVE_MAIL_FROM or L("New Mail"),lines)
    end)
    ui.mail:SetScript("OnLeave",HideGameTip)
    ui.friends=Indicator("friendsOnline",MEDIA.."Media_335\\friends.tga",2)
    ui.friends.icon:SetDesaturated(true); ui.friends:SetAlpha(.85)
    ui.friends:SetScript("OnClick",function(self)
        if self._euiDragged then self._euiDragged=nil; return end
        SecureToggle("ToggleFriendsFrame",1)
    end)
    ui.friends:SetScript("OnEnter",function(self) self:SetAlpha(1); ns.ShowFriends(self) end)
    ui.friends:SetScript("OnLeave",function(self) self:SetAlpha(.85); ScheduleFriendsHide() end)
    ui.flyoutToggle=Indicator("flyoutToggle",MEDIA.."Media_335\\flyout.tga",3)
    ui.flyoutToggle.icon:SetDesaturated(true)
    ui.flyout=Frame("Frame",UIParent); ui.flyout:SetFrameStrata("DIALOG"); ui.flyout:SetClampedToScreen(true)
    ui.flyout:SetBackdrop({bgFile=WHITE,edgeFile=WHITE,edgeSize=1})
    ui.flyout:SetBackdropColor(.1,.1,.1,.9); ui.flyout:SetBackdropBorderColor(.3,.3,.3,1); ui.flyout:Hide()
    ui.flyoutToggle:SetScript("OnClick",function(self)
        if self._euiDragged then self._euiDragged=nil; return end
        if ui.flyout:IsShown() then ui.flyout:Hide() else ui.flyout:Show() end
    end)
    ui.flyoutToggle:SetScript("OnEnter",function(self) GameTip(self,L("Addon Buttons")) end)
    ui.flyoutToggle:SetScript("OnLeave",HideGameTip)
    ns.layout,ns.border,ns.disc,ns.ring,ns.classicRing,ns.classicHeader=ui.layout,ui.border,ui.disc,ui.ring,ui.classicRing,ui.classicHeader
    ns.clockBg,ns.zoneBg,ns.coordsBox,ns.fpsBg=ui.clockBg,ui.zoneBg,ui.coordsBox,ui.fpsBg
    ns.zoomIn,ns.zoomOut,ns.tracking,ns.calendar,ns.mail,ns.friends=ui.zoomIn,ui.zoomOut,ui.tracking,ui.calendar,ui.mail,ui.friends
    ns.flyout,ns.flyoutToggle=ui.flyout,ui.flyoutToggle
    ns.popup,ns.groupButton=ui.flyout,ui.flyoutToggle
    Minimap:HookScript("OnHide",function()
        ui.flyout:Hide(); ui.disc:Hide(); HideLockouts()
        if ui.friendsTT then ui.friendsTT:Hide() end
        if menuFrame then menuFrame:Hide() end
    end)
    Minimap:HookScript("OnShow",function() if active and ui.disc.wanted then ui.disc:Show() end end)
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
local function ClockText(p)
    local hour,minute
    if p.clockServer then hour,minute=GetGameTime() else local t=date("*t"); hour,minute=t.hour,t.min end
    if p.clockFormat=="24h" then return format("%02d:%02d",hour,minute) end
    local suffix=hour>=12 and "PM" or "AM"; hour=hour%12; if hour==0 then hour=12 end
    if p.fpsColorClockAMPM then local _,_,_,hex=DescColor(p); suffix="|cff"..hex..suffix.."|r" end
    return format("%d:%02d %s",hour,minute,suffix)
end
local REACTIVE_HEX={N="c69b6d",H="0070dd",PvP="ffffff"}
function ns.DifficultyText(p)
    if not GetInstanceInfo then return "" end
    local _,kind,diff,_,maxPlayers,dynamic,isDynamic=GetInstanceInfo()
    local letter,count
    if kind=="pvp" or kind=="arena" then letter="PvP"
    elseif kind=="raid" then
        letter=(diff==3 or diff==4 or (isDynamic and dynamic==1)) and "H" or "N"
        count=(maxPlayers and maxPlayers>0) and maxPlayers or ((diff==1 or diff==3) and 10 or 25)
    elseif kind=="party" then
        letter=diff==2 and "H" or "N"; count=(maxPlayers and maxPlayers>0) and maxPlayers or 5
    else return "" end
    local hex="ffffff"
    if p.diffTextReactive then hex=REACTIVE_HEX[letter] or hex
    elseif p.diffTextAccent then local _,_,_,h=DescColor(p); hex=h end
    return format("%s|cff%s%s|r",count or "",hex,letter)
end
function ns.UpdateText()
    if not active or not ui.texts then return end
    local p=ns.GetSettings()
    if (p.clockMode or "inside")~="none" then ns.clock:SetText(ClockText(p)) end
    if (p.locationMode or "inside")~="none" then
        local zone=p.zoneShowSubZone and GetSubZoneText() or GetZoneText()
        if not zone or zone=="" then zone=GetZoneText() end
        ns.zone:SetText(zone or "")
        local r,g,b,a=1,1,1,.9
        if p.zoneReactiveColor and GetZonePVPInfo then
            local kind=GetZonePVPInfo()
            a=1
            if kind=="friendly" then r,g,b=.05,.85,.03 elseif kind=="sanctuary" then r,g,b=.035,.58,.84
            elseif kind=="hostile" or kind=="combat" or kind=="arena" then r,g,b=.84,.03,.03 else r,g,b=.9,.85,.05 end
        end
        ns.zone:SetTextColor(r,g,b,a)
        ui.zoneBg:SetWidth(max(40,(ns.zone:GetStringWidth() or 100)+20))
    end
    if p.showCoords then
        local x,y=ns.ReadCoordinates()
        local precision=Clamp(p.coordPrecision,0,2,0)
        ns.coords:SetText(x and format("%."..precision.."f, %."..precision.."f",x,y) or "")
    end
    if p.diffTextEnabled then ns.diff:SetText(ns.DifficultyText(p)) end
    local t=date("*t")
    ui.calendar.day:SetText(t and t.day or "")
    local mail=HasNewMail and HasNewMail() and true or false
    if mail~=lastMail then lastMail=mail; if ns.LayoutRows then ns.LayoutRows() end end
end
function ns.UpdateFPS()
    if not active or not ui.fpsBg then return end
    local p=ns.GetSettings()
    if not p.showFPS then ui.fpsBg:Hide(); return end
    local hex="ffffff"
    if p.fpsColorSuffix~=false then local _,_,_,h=DescColor(p); hex=h end
    ns.fps:SetText(format("%d |cff%sFPS|r",floor(GetFramerate()+.5),hex))
    local width=ns.fps:GetStringWidth() or 0
    if p.fpsShowLocalMS~=false then
        local _,_,latency=GetNetStats()
        ns.fpsLocal:SetText(format("%d |cff%sMS|r",latency or 0,hex))
        ns.fpsLocal:Show(); ui.fpsDivider:Show()
        width=width+13+(ns.fpsLocal:GetStringWidth() or 0)
    else ns.fpsLocal:Hide(); ui.fpsDivider:Hide() end
    Size(ui.fpsBg,width+4,20); ui.fpsBg:Show()
end
local function SavePosition()
    local x,y=Minimap:GetCenter()
    if not x or not y then return end
    local scale=Minimap:GetEffectiveScale()/UIParent:GetEffectiveScale()
    ns.GetSettings().position={point="CENTER",relPoint="BOTTOMLEFT",x=x*scale,y=y*scale}
end

-------------------------------------------------------------------------------
--  Middle-click micro menu
-------------------------------------------------------------------------------
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
    menuFrame:SetBackdrop({bgFile=WHITE,edgeFile=WHITE,edgeSize=1})
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
            if not t then t=Tex(menuFrame,"ARTWORK"); menuFrame.dividers[dividers]=t end
            t:ClearAllPoints(); t:SetPoint("TOPLEFT",menuFrame,"TOPLEFT",8,-y-4); Size(t,144,1); t:SetVertexColor(.3,.3,.3,.6); t:Show(); y=y+9
        else
            local action,enabled=MenuAction(item)
            if not item.optional or action then
                local b=menuFrame.rows[index]
                if not b then
                    b=Frame("Button",menuFrame); menuFrame.rows[index]=b; b.item=item
                    b:RegisterForClicks("LeftButtonUp")
                    b.highlight=Tex(b,"HIGHLIGHT"); b.highlight:SetAllPoints(b)
                    b.label=MakeText(b,11); b.label:SetPoint("LEFT",b,"LEFT",7,0)
                    b:SetScript("OnClick",function(self)
                        if InCombatLockdown() then return end
                        local run,canRun=MenuAction(self.item)
                        if run and canRun then CloseMenu(); run() end
                    end)
                end
                E.ApplyModuleFont(b.label,nil,11,"minimap")
                local r,g,blue=Accent()
                b.highlight:SetVertexColor(r,g,blue,.15)
                b.label:SetText(L(item.text))
                b.label:SetTextColor(enabled and .92 or .4,enabled and .92 or .4,enabled and .92 or .4,1)
                b:ClearAllPoints(); b:SetPoint("TOPLEFT",menuFrame,"TOPLEFT",3,-y); Size(b,154,20)
                if action and enabled then b:Enable() else b:Disable() end
                b:Show(); y=y+20
            end
        end
    end
    Size(menuFrame,160,y+6); menuFrame:ClearAllPoints(); menuFrame:SetPoint("TOPRIGHT",Minimap,"TOPLEFT",-4,0)
    ui.flyout:Hide(); menuDismiss:Show(); menuFrame:Show()
end
ns._ToggleMicroMenu=ns.ToggleMicroMenu

-------------------------------------------------------------------------------
--  Zoom
-------------------------------------------------------------------------------
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
    local top=(self.GetZoomLevels and self:GetZoomLevels() or 6)-1
    local zoom=max(0,min(top,self:GetZoom()+(delta>0 and 1 or -1)))
    self:SetZoom(zoom); ns.GetSettings().savedZoom=zoom; RestartZoomTimer()
end
ns.Wheel=Wheel

-------------------------------------------------------------------------------
--  Rows, indicators and the addon-button flyout
-------------------------------------------------------------------------------
-- mode -> button point, map point, step direction, away-from-map direction.
local ROW_MODES={
    blUp={"BOTTOMRIGHT","BOTTOMLEFT",0,1,-1,0}, tlDown={"TOPRIGHT","TOPLEFT",0,-1,-1,0},
    brUp={"BOTTOMLEFT","BOTTOMRIGHT",0,1,1,0}, trDown={"TOPLEFT","TOPRIGHT",0,-1,1,0},
    tlRight={"BOTTOMLEFT","TOPLEFT",1,0,0,1}, trLeft={"BOTTOMRIGHT","TOPRIGHT",-1,0,0,1},
    blRight={"TOPLEFT","BOTTOMLEFT",1,0,0,-1}, brLeft={"TOPRIGHT","BOTTOMRIGHT",-1,0,0,-1},
}
ns.ROW_MODES=ROW_MODES
local function Place(b,point,rel,relPoint,x,y)
    local p=ns.GetSettings()
    b._base={point,rel,relPoint,x,y}
    local pos=p.freeMoveBtns and b._moveKey and p.btnPositions[b._moveKey]
    if pos then x,y=x+(pos.x or 0),y+(pos.y or 0) end
    b:ClearAllPoints(); b:SetPoint(point,rel,relPoint,x,y)
end
local function PlaceRow(list,mode,spacing,distance,size,out)
    local m=ROW_MODES[mode] or ROW_MODES.blUp
    local run,base=0,(tonumber(distance) or 0)+out
    for _,b in ipairs(list) do
        Place(b,m[1],ui.layout,m[2],m[5]*base+m[3]*run,m[6]*base+m[4]*run)
        run=run+size+(tonumber(spacing) or 0)
    end
end
-- Classic ring buttons orbit the map; the disc centre is 16.6,-16.2 from TOPLEFT.
local function PlaceArc(b,size,degrees)
    local r,t=(size/2)+10*size/140,math.rad(degrees)
    Place(b,"TOPLEFT",Minimap,"CENTER",r*math.cos(t)-16.6,r*math.sin(t)+16.2)
end
local function FlyoutDirection(p)
    local dir=p.flyoutGrowDir or "auto"
    if dir~="auto" then return dir end
    if p.useClassicStyle then return "left" end
    local mode=p.btnRowPosition or "blUp"
    if mode=="blUp" or mode=="tlDown" then return "left" elseif mode=="brUp" or mode=="trDown" then return "right"
    elseif mode=="tlRight" or mode=="trLeft" then return "up" end
    return "down"
end
ns.FlyoutDirection=FlyoutDirection
local function AnchorFlyout(p)
    local panel,toggle=ui.flyout,ui.flyoutToggle
    local m=ROW_MODES[p.btnRowPosition] or ROW_MODES.blUp
    local dir=FlyoutDirection(p)
    panel:ClearAllPoints()
    if dir=="left" or dir=="right" then
        local v=m[4]==1 and "BOTTOM" or "TOP"
        if dir=="left" then panel:SetPoint(v.."RIGHT",toggle,v.."LEFT",-2,0) else panel:SetPoint(v.."LEFT",toggle,v.."RIGHT",2,0) end
    else
        local h=m[3]==-1 and "RIGHT" or "LEFT"
        if dir=="up" then panel:SetPoint("BOTTOM"..h,toggle,"TOP"..h,0,2) else panel:SetPoint("TOP"..h,toggle,"BOTTOM"..h,0,-2) end
    end
end
local function UngroupOrder(p,f)
    local v=p.ungroupedButtons and p.ungroupedButtons[f:GetName()]
    if v==nil or v==false then return end
    return tonumber(v) or 0
end
function ns.LayoutRows()
    if not active or not ui.layout then return end
    local p=ns.GetSettings()
    local classic=ns.GetStyle()=="classic"
    local shape=ns.GetShape()
    local size=Clamp(p.size,100,600,180)
    local isz=Clamp(p.interactableBtnSize,14,40,21)
    local out=(not IsRound(shape) and not classic) and Clamp(p.borderSize,0,8,1) or 0
    local hasMail=HasNewMail and HasNewMail() and not p.hideMail
    lastMail=HasNewMail and HasNewMail() and true or false
    local accentR,accentG,accentB=Accent()
    ui.friends.icon:SetVertexColor(accentR,accentG,accentB,1)
    ui.flyoutToggle.icon:SetVertexColor(accentR,accentG,accentB,1)
    for _,b in ipairs({ui.tracking,ui.calendar,ui.mail,ui.friends,ui.flyoutToggle}) do Dress(b,classic,isz) end
    for _,b in ipairs({ui.friends,ui.flyoutToggle}) do if not classic then if p.btnBackgrounds~=false then b.bg:Show() else b.bg:Hide() end end end
    if p.hideTrackingButton then ui.tracking:Hide() else ui.tracking:Show() end
    if p.hideGameTime then ui.calendar:Hide() else ui.calendar:Show() end
    if hasMail then ui.mail:Show() else ui.mail:Hide() end
    local cornerMail=hasMail and not classic and (p.mailPosition or "button")~="button"
    if classic then
        if ui.tracking:IsShown() then PlaceArc(ui.tracking,size,140) end
        if ui.calendar:IsShown() then PlaceArc(ui.calendar,size,42) end
        if hasMail then PlaceArc(ui.mail,size,10) end
    else
        local left,right={},{}
        if ui.tracking:IsShown() then left[#left+1]=ui.tracking end
        if hasMail and not cornerMail then left[#left+1]=ui.mail end
        if ui.calendar:IsShown() then right[#right+1]=ui.calendar end
        if IsRound(shape) and ui.clockBg:IsShown() and (p.clockPosition or "top")=="top" then
            -- Round maps chain the elements beside the clock, as Retail does.
            local anchor=ui.clockBg
            for _,b in ipairs(left) do Place(b,"RIGHT",anchor,"LEFT",-2,0); anchor=b end
            anchor=ui.clockBg
            for _,b in ipairs(right) do Place(b,"LEFT",anchor,"RIGHT",2,0); anchor=b end
        else
            local row={}
            if ui.tracking:IsShown() then row[#row+1]=ui.tracking end
            if ui.calendar:IsShown() then row[#row+1]=ui.calendar end
            if hasMail and not cornerMail then row[#row+1]=ui.mail end
            PlaceRow(row,p.elementRowPosition,p.elementRowSpacing,p.elementRowDistance,isz,out)
        end
        if cornerMail then
            local corner=p.mailPosition
            local sx=corner:find("LEFT") and 2 or -2
            local sy=corner:find("TOP") and -2 or 2
            Place(ui.mail,corner,ui.layout,corner,sx+(p.mailOffsetX or 0),sy+(p.mailOffsetY or 0))
        end
    end
    local row={}
    if ui.flyoutToggle.wanted and not (p.hideExtraBtns and p.hideExtraBtns.groupButton) then
        ui.flyoutToggle:Show(); row[#row+1]=ui.flyoutToggle
    else ui.flyoutToggle:Hide(); ui.flyout:Hide() end
    for _,f in ipairs(ui.ungrouped or {}) do row[#row+1]=f end
    if p.hideExtraBtns and p.hideExtraBtns.friendsOnline then ui.friends:Hide()
    else ui.friends:Show(); row[#row+1]=ui.friends end
    if classic then
        for i,b in ipairs(row) do
            if b._euiAddon then Size(b,isz,isz) end
            PlaceArc(b,size,220+(i-1)*24)
        end
    else
        for _,f in ipairs(ui.ungrouped or {}) do Size(f,isz,isz) end
        PlaceRow(row,p.btnRowPosition,p.btnRowSpacing,p.btnRowDistance,isz,out)
    end
    AnchorFlyout(p)
    ns.rowButtons=row
end
function ns.LayoutButtons()
    local p=ns.GetSettings()
    local classic=ns.GetStyle()=="classic"
    local lvl=Minimap:GetFrameLevel()
    for _,name in ipairs({"MiniMapTrackingButton","MiniMapMailFrame","GameTimeFrame"}) do
        local f=_G[name]
        if f then native[f]=true; RememberButton(f); f:SetAlpha(0); if f.EnableMouse then f:EnableMouse(false) end end
    end
    local zoomHidden=p.hideZoomButtons
    for _,spec in ipairs({{"MinimapZoomIn",ui.zoomIn,true},{"MinimapZoomOut",ui.zoomOut,false}}) do
        local f,own,isIn=_G[spec[1]],spec[2],spec[3]
        if f then
            native[f]=true; RememberButton(f)
            if classic and not zoomHidden then
                -- Vanilla anchors on the 140px map, scaled to the current size.
                local s=Clamp(p.size,100,600,180)/140
                f:SetParent(Minimap); Size(f,32*s,32*s); f:ClearAllPoints()
                f:SetPoint("CENTER",Minimap,"CENTER",(isIn and 69 or 43)*s,(isIn and -37 or -65)*s)
                f:SetFrameLevel(lvl+10); f:SetAlpha(1); if f.EnableMouse then f:EnableMouse(true) end
            else f:SetAlpha(0); if f.EnableMouse then f:EnableMouse(false) end end
        end
        own:ClearAllPoints(); own:SetPoint("BOTTOMRIGHT",ui.layout,"BOTTOMRIGHT",-2,isIn and 20 or 2)
        if classic or zoomHidden then own:Hide() else own:Show(); own:SetAlpha(0) end
    end
    local controls={
        {"MiniMapInstanceDifficulty",p.hideRaidDifficulty or p.diffTextEnabled,"TOPRIGHT",2,2},
        {"GuildInstanceDifficulty",p.hideRaidDifficulty or p.diffTextEnabled,"TOPRIGHT",2,2},
        {"MiniMapWorldMapButton",p.hideWorldMapButton,"BOTTOMRIGHT",-20,2},
        {"MiniMapBattlefieldFrame",p.hideQueueStatus,"BOTTOMLEFT",2,2},
        {"MiniMapLFGFrame",p.hideQueueStatus,"BOTTOMLEFT",2,2},
    }
    for _,spec in ipairs(controls) do
        local f=_G[spec[1]]
        if f then
            native[f]=true; RememberButton(f)
            f:SetParent(Minimap); f:ClearAllPoints(); f:SetPoint(spec[3],ui.layout,spec[3],spec[4],spec[5])
            f:SetFrameLevel(lvl+10)
            f:SetAlpha(spec[2] and 0 or 1)
            if f.EnableMouse then f:EnableMouse(not spec[2]) end
        end
    end
    local buttons=ns.ScanButtons()
    local grouped,ungrouped={},{}
    local solo=#buttons==1
    for _,f in ipairs(buttons) do
        local s=buttonState[f]
        f._euiAddon,f._moveKey=true,f:GetName()
        if p.hideAddonButtons then
            -- Hide the parent rather than the button: the addon's own Show/Hide
            -- continues to express whether it wants its button visible.
            if not ns.hidden then ns.hidden=Frame("Frame",UIParent); ns.hidden:Hide() end
            Unstrip(f); f:SetParent(ns.hidden)
        elseif solo or UngroupOrder(p,f) then
            ungrouped[#ungrouped+1]=f
        else grouped[#grouped+1]=f end
    end
    table.sort(ungrouped,function(a,b)
        local oa,ob=UngroupOrder(p,a) or 0,UngroupOrder(p,b) or 0
        if oa~=ob then return oa<ob end
        return a:GetName()<b:GetName()
    end)
    local bsz=Clamp(p.addonBtnSize,14,40,24)
    for _,f in ipairs(ungrouped) do
        local s=buttonState[f]
        f:SetParent(Minimap); f:SetScale(1); f:SetAlpha(1); f:SetFrameLevel(lvl+10)
        Strip(f,3,p.btnBackgrounds~=false)
        HookFreeMove(f)
        if p.freeMoveBtns then
            if s.click==nil then
                s.click=f:GetScript("OnClick") or false
                f:SetScript("OnClick",function(self,...)
                    if self._euiDragged then self._euiDragged=nil; return end
                    local click=buttonState[self].click
                    if click then return click(self,...) end
                end)
            end
        elseif s.click~=nil then f:SetScript("OnClick",s.click or nil); s.click=nil end
    end
    local cols=min(4,max(1,#grouped))
    for index,f in ipairs(grouped) do
        local s=buttonState[f]
        if s.click~=nil then f:SetScript("OnClick",s.click or nil); s.click=nil end
        f:SetParent(ui.flyout); Size(f,bsz,bsz); f:SetScale(1); f:SetAlpha(1)
        Strip(f,2,true)
        local col,row=(index-1)%cols,floor((index-1)/cols)
        f:ClearAllPoints(); f:SetPoint("TOPLEFT",ui.flyout,"TOPLEFT",8+col*(bsz+4),-8-row*(bsz+4))
        if not s.closeHook then s.closeHook=true; f:HookScript("OnClick",function() if ui.flyout then ui.flyout:Hide() end end) end
    end
    local rows=max(1,math.ceil(#grouped/cols))
    Size(ui.flyout,16+cols*bsz+(cols-1)*4,16+rows*bsz+(rows-1)*4)
    ui.flyout:Hide()
    ui.flyoutToggle.wanted=#grouped>0
    ui.ungrouped,ns.ungrouped,ns.grouped=ungrouped,ungrouped,grouped
    ns.LayoutRows()
end

-------------------------------------------------------------------------------
--  Shape, border, chrome and text placement
-------------------------------------------------------------------------------
local function ApplyBorder(p,size,shape,classic)
    local bs=Clamp(p.borderSize,0,8,1)
    local r,g,b,a=BorderColor(p)
    local lvl=Minimap:GetFrameLevel()
    ui.border:Hide(); ui.texBorder:Hide(); ui.ring:Hide(); ui.disc:Hide(); ui.disc.wanted=false
    if classic then return end
    if shape=="textured_circle" then
        local d=(size-4)/RING_INNER
        Size(ui.ring,d,d); ui.ring.tex:SetVertexColor(r,g,b,1); ui.ring:Show()
        return
    end
    if bs<=0 then return end
    if shape=="circle" then
        local d=(size+2*bs)/DISC_FILL
        Size(ui.disc,d,d); ui.disc:SetFrameStrata(Minimap:GetFrameStrata()); ui.disc:SetFrameLevel(max(0,lvl-1))
        ui.disc.tex:SetVertexColor(r,g,b,a); ui.disc.wanted=true
        if Minimap:IsShown() then ui.disc:Show() end
        return
    end
    local level=p.borderBehind and max(0,lvl-1) or lvl+2
    local texture=p.borderTexture or "solid"
    if texture~="solid" and E.ApplyBorderStyle and E.ResolveBorderTexture and E.ResolveBorderTexture(texture) then
        ui.texBorder:SetFrameLevel(level); ui.texBorder:Show()
        if pcall(E.ApplyBorderStyle,ui.texBorder,bs,r,g,b,a,texture,nil,nil,nil,nil,"minimap",bs) then return end
        ui.texBorder:Hide()
    end
    -- Solid strips outside the visible rect: the rectangular crop leaves
    -- transparent bands, so a filled frame behind the map would show through.
    local e,lay=ui.border.edges,ui.layout
    for _,t in ipairs(e) do t:ClearAllPoints(); t:SetVertexColor(r,g,b,a) end
    e[1]:SetPoint("BOTTOMLEFT",lay,"TOPLEFT",-bs,0); e[1]:SetPoint("BOTTOMRIGHT",lay,"TOPRIGHT",bs,0); e[1]:SetHeight(bs)
    e[2]:SetPoint("TOPLEFT",lay,"BOTTOMLEFT",-bs,0); e[2]:SetPoint("TOPRIGHT",lay,"BOTTOMRIGHT",bs,0); e[2]:SetHeight(bs)
    e[3]:SetPoint("TOPRIGHT",lay,"TOPLEFT",0,0); e[3]:SetPoint("BOTTOMRIGHT",lay,"BOTTOMLEFT",0,0); e[3]:SetWidth(bs)
    e[4]:SetPoint("TOPLEFT",lay,"TOPRIGHT",0,0); e[4]:SetPoint("BOTTOMLEFT",lay,"BOTTOMRIGHT",0,0); e[4]:SetWidth(bs)
    ui.border:SetFrameLevel(level); ui.border:Show()
end
local function ApplyClassic(on,size)
    if not on then ui.classicRing:Hide(); ui.classicHeader:Hide(); return end
    local s,lvl=size/140,Minimap:GetFrameLevel()
    ui.classicRing:ClearAllPoints(); ui.classicRing:SetPoint("CENTER",Minimap,"CENTER",-8*s,-24*s)
    Size(ui.classicRing,192*s,192*s); ui.classicRing:SetFrameLevel(lvl+3); ui.classicRing:Show()
    local header=ui.classicHeader
    header:ClearAllPoints(); Size(header,size+36,28); header:SetPoint("BOTTOM",Minimap,"TOP",0,4)
    header.slot:SetWidth(max(40,size-16)); header:SetFrameLevel(lvl+1); header:Show()
end
local function ApplyTexts(p,shape,classic)
    local round=IsRound(shape)
    local br,bg,bb=BorderColor(p)
    local mode=p.clockMode or "inside"
    if mode=="none" then ui.clockBg:Hide() else
        E.ApplyModuleFont(ns.clock,nil,10,"minimap"); ns.clock:SetTextColor(1,1,1,.9)
        if mode=="inside" then ui.clockBg:SetBackdropColor(0,0,0,0) else ui.clockBg:SetBackdropColor(br,bg,bb,1) end
        local pt,rel,x,y=ResolveAnchor(p.clockPosition or "top",mode,round)
        ui.clockBg:ClearAllPoints(); ui.clockBg:SetPoint(pt,ui.layout,rel,x+(p.clockOffsetX or 0),y+(p.clockOffsetY or 0))
        ns.clock:ClearAllPoints()
        if mode=="inside" then ns.clock:SetPoint(pt,ui.clockBg,pt,0,0) else ns.clock:SetPoint("CENTER",ui.clockBg,"CENTER",0,0) end
        ui.clockBg:SetScale(Clamp(p.clockScale,.5,2,1.15)); ui.clockBg:Show()
    end
    mode=p.locationMode or "inside"
    if mode=="none" then ui.zoneBg:Hide() else
        E.ApplyModuleFont(ns.zone,nil,10,"minimap")
        local lx,ly=p.locationOffsetX or 0,p.locationOffsetY or 0
        ui.zoneBg:ClearAllPoints(); ns.zone:ClearAllPoints()
        if classic then
            -- Classic WoW UI: the zone rides the banner's text slot.
            ui.zoneBg:SetBackdropColor(0,0,0,0)
            ui.zoneBg:SetPoint("CENTER",ui.classicHeader.slot,"CENTER",lx,ly)
            ns.zone:SetPoint("CENTER",ui.zoneBg,"CENTER",0,0)
        else
            if mode=="inside" then ui.zoneBg:SetBackdropColor(0,0,0,0) else ui.zoneBg:SetBackdropColor(br,bg,bb,1) end
            local pt,rel,x,y=ResolveAnchor(p.locationPosition or "bottom",mode,round)
            ui.zoneBg:SetPoint(pt,ui.layout,rel,x+lx,y+ly)
            if mode=="inside" then ns.zone:SetPoint(pt,ui.zoneBg,pt,0,0) else ns.zone:SetPoint("CENTER",ui.zoneBg,"CENTER",0,0) end
        end
        ui.zoneBg:SetScale(Clamp(p.locationScale,.5,2,1.15)); ui.zoneBg:Show()
    end
    E.ApplyModuleFont(ns.coords,nil,11,"minimap"); ns.coords:SetTextColor(1,1,1,.9)
    local a=MAP_POS[p.coordsPosition or "topLeft"] or MAP_POS.topLeft
    ui.coordsBox:ClearAllPoints(); ui.coordsBox:SetPoint(a[1],ui.layout,a[2],a[3],a[4])
    ns.coords:ClearAllPoints(); ns.coords:SetPoint(a[1],ui.coordsBox,a[1],0,0)
    ui.coordsBox:SetScale(Clamp(p.coordsScale,.5,2,1))
    if p.showCoords and (p.coordsMode or "always")=="always" then ui.coordsBox:Show() else ui.coordsBox:Hide() end
    local size=Clamp(p.fpsTextSize,8,24,12)
    E.ApplyModuleFont(ns.fps,nil,size,"minimap"); E.ApplyModuleFont(ns.fpsLocal,nil,size,"minimap")
    a=MAP_POS[p.fpsPosition or "bottomLeft"] or MAP_POS.bottomLeft
    ui.fpsBg:ClearAllPoints(); ui.fpsBg:SetPoint(a[1],ui.layout,a[2],a[3]+(p.fpsOffsetX or 0),a[4]+(p.fpsOffsetY or 0))
    ui.fpsBg:SetScale(Clamp(p.fpsScale,.5,2,1))
    ui.fpsBg:EnableMouse((p.fpsHoverTooltip or "none")~="none")
    if p.showFPS then ui.fpsBg:Show() else ui.fpsBg:Hide() end
    if p.diffTextEnabled then
        E.ApplyModuleFont(ns.diff,nil,Clamp(p.diffTextSize,8,24,12),"minimap")
        a=MAP_POS[p.diffTextPosition or "topLeft"] or MAP_POS.topLeft
        ns.diff:ClearAllPoints(); ns.diff:SetPoint(a[1],ui.layout,a[2],a[3]+(p.diffTextOffsetX or 0),a[4]+(p.diffTextOffsetY or 0))
        ns.diff:Show()
    else ns.diff:Hide() end
end

-------------------------------------------------------------------------------
--  Apply / restore / visibility
-------------------------------------------------------------------------------
function ns.Restore()
    if not original or not active then return end
    if InCombatLockdown() then pending=true; return end
    if zoomTimer then zoomTimer:Cancel(); zoomTimer=nil end
    if dragging then Minimap:StopMovingOrSizing(); dragging=false end
    active,moving=false,nil
    CloseMenu()
    RestoreFrame(Minimap,original); Minimap:SetMaskTexture(original.mask)
    Minimap:SetHitRectInsets(0,0,0,0)
    Minimap:SetScript("OnMouseWheel",original.wheel); Minimap:SetScript("OnMouseUp",original.mouseUp)
    Minimap:EnableMouseWheel(original.wheelEnabled==true); Minimap:SetMovable(original.movable==true)
    if original.clamped~=nil then Minimap:SetClampedToScreen(original.clamped) end
    Minimap:SetZoom(original.zoom); SetCVar("rotateMinimap",original.rotate)
    for f,s in pairs(original.decorations) do
        f:SetAlpha(s.alpha); if s.mouse~=nil and f.EnableMouse then f:EnableMouse(s.mouse) end
    end
    for f,s in pairs(buttonState) do Unstrip(f); RestoreFrame(f,s) end
    GetMinimapShape=oldGetShape
    for _,key in ipairs({"border","texBorder","disc","ring","classicRing","classicHeader","texts","flyout","flyoutToggle",
        "zoomIn","zoomOut","tracking","calendar","mail","friends","lockTT","friendsTT"}) do
        if ui[key] then ui[key]:Hide() end
    end
    ui.disc.wanted=false
    HideGameTip()
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
        Minimap:Show(); verdict=MouseIsOver(Minimap) or (ui.flyout:IsShown() and MouseIsOver(ui.flyout))
        Minimap:SetAlpha(verdict and p.opacity/100 or 0)
    elseif verdict then Minimap:Show(); Minimap:SetAlpha(p.opacity/100)
    else Minimap:Hide() end
    if E.CheckVisibilityOptions and E.CheckVisibilityOptions(p) then Minimap:Hide() end
    ui.disc:SetAlpha(Minimap:GetAlpha())
    if ui.disc.wanted and Minimap:IsShown() then ui.disc:Show() else ui.disc:Hide() end
end
-- Zoom buttons, hover coordinates, mouseover extra buttons, outside-click
-- flyout dismissal and the friends tooltip grace period.
function ns.HoverTick()
    if not active then return end
    local p=ns.GetSettings()
    local overMap=MouseIsOver(ui.layout) or MouseIsOver(Minimap)
    if ns.GetStyle()~="classic" and not p.hideZoomButtons then
        local show=overMap or MouseIsOver(ui.zoomIn) or MouseIsOver(ui.zoomOut)
        ui.zoomIn:SetAlpha(show and 1 or 0); ui.zoomOut:SetAlpha(show and 1 or 0)
    end
    if p.showCoords and p.coordsMode=="hover" then
        if overMap then ui.coordsBox:Show() else ui.coordsBox:Hide() end
    end
    local extras={ui.flyoutToggle,ui.friends}
    if p.mouseoverExtraBtns then
        local over=overMap or (ui.flyout:IsShown() and MouseIsOver(ui.flyout))
            or (ui.friendsTT and ui.friendsTT:IsShown() and MouseIsOver(ui.friendsTT))
        for _,b in ipairs(extras) do if b:IsShown() and MouseIsOver(b) then over=true end end
        local alpha
        if over then extrasHideAt=nil; alpha=1
        elseif not extrasHideAt then extrasHideAt=GetTime()+.3
        elseif GetTime()>=extrasHideAt then alpha=0 end
        if alpha then for _,b in ipairs(extras) do b:SetAlpha(alpha==1 and (b==ui.friends and .85 or 1) or 0) end end
    else
        ui.flyoutToggle:SetAlpha(1)
        if not MouseIsOver(ui.friends) then ui.friends:SetAlpha(.85) end
    end
    if ui.flyout:IsShown() and IsMouseButtonDown and IsMouseButtonDown("LeftButton")
        and not MouseIsOver(ui.flyout) and not MouseIsOver(ui.flyoutToggle) then ui.flyout:Hide() end
    local tt=ui.friendsTT
    if tt and tt:IsShown() and tt._hideAt and GetTime()>=tt._hideAt then
        if MouseIsOver(tt) or MouseIsOver(ui.friends) then tt._hideAt=nil else tt:Hide() end
    end
end
function ns.Apply()
    local p=ns.GetSettings(); if not p then return end
    if InCombatLockdown() then pending=true; return end
    pending=false
    if not p.enabled then ns.Restore(); return end
    SnapshotNative(); EnsureUI(); active=true
    CloseMenu(); Minimap:EnableMouse(true)
    local size=Clamp(p.size,100,600,180)
    local shape=ns.GetShape()
    local classic=ns.GetStyle()=="classic"
    local rect=shape=="rectangular"
    Minimap:SetParent(UIParent); Size(Minimap,size,size); Minimap:SetScale(1)
    Minimap:ClearAllPoints()
    local position=p.position
    if position then Minimap:SetPoint(position.point,UIParent,position.relPoint,position.x,position.y)
    else Minimap:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-24,-24) end
    Minimap:SetMovable(not p.lock); Minimap:SetClampedToScreen(true)
    -- Rectangular keeps the square canvas and crops a 256x192 window out of it.
    Minimap:SetMaskTexture(IsRound(shape) and ROUND_MASK or rect and RECT_MASK or WHITE)
    local inset=rect and size*32/256 or 0
    Minimap:SetHitRectInsets(0,0,inset,inset)
    GetMinimapShape=function() return active and (IsRound(ns.GetShape()) and "ROUND" or "SQUARE") or (oldGetShape and oldGetShape() or "ROUND") end
    ui.layout:ClearAllPoints(); ui.layout:SetPoint("CENTER",Minimap,"CENTER")
    Size(ui.layout,size,rect and size*192/256 or size); ui.layout:SetFrameLevel(Minimap:GetFrameLevel())
    ApplyBorder(p,size,shape,classic)
    ApplyClassic(classic,size)
    for f in pairs(original.decorations) do f:SetAlpha(0); if f.EnableMouse then f:EnableMouse(false) end end
    SetCVar("rotateMinimap",p.rotateMinimap and "1" or "0")
    Minimap:SetScript("OnMouseUp",MouseUp)
    Minimap:EnableMouseWheel(p.scrollZoom)
    Minimap:SetScript("OnMouseWheel",p.scrollZoom and Wheel or original.wheel)
    local top=(Minimap.GetZoomLevels and Minimap:GetZoomLevels() or 6)-1
    Minimap:SetZoom(max(0,min(top,p.savedZoom or 0)))
    if zoomTimer then zoomTimer:Cancel(); zoomTimer=nil end
    ui.texts:Show(); ApplyTexts(p,shape,classic); ns.LayoutButtons()
    ns.UpdateText(); ns.UpdateFPS(); ns.UpdateVisibility()
end
function addon:OnInitialize()
    addon.db=E.Lite.NewDB("EllesmereUIMinimapDB",defaults)
    local p=addon.db.profile.minimap
    -- Until 0.4 the Wrath port read useClassColor as the class colour; Retail
    -- names that borderUseClassColor and uses useClassColor for the accent.
    if not p._wrath04 then
        if p.useClassColor then p.borderUseClassColor=true; p.useClassColor=false end
        p._wrath04=true
    end
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
        elseif event=="UPDATE_PENDING_MAIL" then ns.LayoutRows(); ns.UpdateText()
        else mapDirty=true; ns.UpdateText(); ns.UpdateVisibility() end
    end)
    events:SetScript("OnUpdate",function(_,dt)
        if not active then return end
        UpdateMove()
        elapsed,fpsElapsed,hoverElapsed=elapsed+dt,fpsElapsed+dt,hoverElapsed+dt
        if hoverElapsed>=.05 then hoverElapsed=0; ns.HoverTick() end
        if fpsElapsed>=Clamp(ns.GetSettings().fpsUpdateInterval,1,5,3) then fpsElapsed=0; ns.UpdateFPS() end
        if elapsed>=.5 then elapsed=0; ns.UpdateText(); ns.UpdateVisibility() end
    end)
    ns.events=events
end
