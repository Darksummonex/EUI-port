-- Player spell history: icon strip and bar window. No cast events are
-- registered while both displays are off.
local ADDON,ns=...
local E=EllesmereUI
local white="Interface\\Buttons\\WHITE8X8"
local MAX_HISTORY,POOL_SIZE=80,40
local STOPPED={.859,.255,.255}
local OUTCOME={failed="|cffdb4141Failed|r",interrupted="|cffdb4141Interrupted|r"}
local ANIM_DUR,ANIM_SLIDE,FADE_DUR=.5,6,1.5
local MIN_BAR_WIDTH=150
local QUESTION="Interface\\Icons\\INV_Misc_QuestionMark"
local history,pending,targets={},{},{}
local channelName
ns.castHistory=history
local function DB()
    local p=ns.Profile(); p.spellHistory=p.spellHistory or {}
    return p.spellHistory
end
local function Hidden(sh,prefix)
    if ns.preview or ns.optionsOpen then return false end
    if ns.toggleHidden and ns.Profile().toggleIncludeSpellHistory then return true end
    local inside,kind
    if IsInInstance then inside,kind=IsInInstance() end
    if kind=="party" and sh[prefix.."HideInDungeon"] or kind=="raid" and sh[prefix.."HideInRaid"]
        or (kind=="pvp" or kind=="arena") and sh[prefix.."HideInPvP"] then return true end
    return not inside and sh[prefix.."HideOutOfInstance"] and true or false
end
local function BarTexture(sh)
    local key=sh.barTexture
    if not key or key=="match" then key=ns.Profile().windows[1].barTexture end
    return ns.BarTexturePath(key)
end
local function BarColor(sh,status)
    if status=="failed" or status=="interrupted" then return STOPPED[1],STOPPED[2],STOPPED[3] end
    if sh.barColorMode=="class" then
        local c=RAID_CLASS_COLORS[select(2,UnitClass("player"))]; if c then return c.r,c.g,c.b end
    elseif sh.barColorMode=="accent" then return ns.Accent() end
    local c=sh.barColor or {}; return c.r or .298,c.g or .565,c.b or .494
end
local function CastTime(entry)
    if entry.isInstant then return "" end
    if entry.status=="casting" or entry.status=="channeling" then
        local elapsed=GetTime()-entry.startTime
        return elapsed>0 and string.format("%.1f",elapsed) or ""
    end
    return entry.castDuration and entry.castDuration>0 and string.format("%.1fs",entry.castDuration) or ""
end
local function RightText(entry)
    local cast=CastTime(entry); local right=OUTCOME[entry.status] or (entry.target and entry.target~="" and entry.target) or nil
    if cast~="" and right then return cast.."  "..right end
    return cast~="" and cast or right or ""
end
local function Refresh()
    local sh=DB()
    if sh.iconEnabled and ns.BuildIconStrip then ns.BuildIconStrip() end
    if sh.barEnabled and ns.RefreshBarWindow then ns.RefreshBarWindow() end
end
local function Push(entry)
    table.insert(history,1,entry)
    if #history>MAX_HISTORY then history[#history]=nil end
    Refresh()
end
local function Finish(name,status)
    targets[name]=nil
    local entry=pending[name]; if not entry then return end
    pending[name]=nil
    if entry.status=="success" then return end
    local now=GetTime()
    if status~="success" then
        local d=entry.endTime-entry.startTime
        if d>0 then entry.fillProgress=math.max(0,math.min(1,entry.isChannel and (entry.endTime-now)/d or (now-entry.startTime)/d)) end
    end
    entry.status=status; entry.finishedAt=now; entry.castDuration=now-entry.startTime
    Refresh()
end
-- Wrath cast events carry only the spell name, so pending casts are keyed
-- by name. A STOP without SUCCEEDED becomes "failed" one frame later.
local stopQueue={}
local stopDriver=CreateFrame("Frame"); stopDriver:Hide(); ns.castStopDriver=stopDriver
stopDriver:SetScript("OnUpdate",function(self)
    self:Hide()
    for name in pairs(stopQueue) do
        stopQueue[name]=nil
        local entry=pending[name]; if entry and entry.status=="casting" then Finish(name,"failed") end
    end
end)
local repeating
local function Repeating(name)
    if not repeating then
        repeating={}
        for _,id in ipairs({75,5019}) do local n=GetSpellInfo(id); if n then repeating[n]=true end end
    end
    return repeating[name]
end
local function NewCast(name,texture,startMS,endMS,channel)
    local entry={spellName=name,icon=texture or QUESTION,target=targets[name],startTime=(startMS or 0)/1000,endTime=(endMS or 0)/1000,
        status=channel and "channeling" or "casting",isChannel=channel,timestamp=GetTime()}
    entry.castDuration=entry.endTime-entry.startTime
    pending[name]=entry; Push(entry)
    if ns.StartCastAnim then ns.StartCastAnim() end
end
local function OnEvent(_,event,unit,name,_,target)
    if unit~="player" or not name then return end
    if event=="UNIT_SPELLCAST_SENT" then targets[name]=target; return end
    if event=="UNIT_SPELLCAST_START" then
        local cast,_,_,texture,startMS,endMS=UnitCastingInfo("player")
        if cast then NewCast(cast,texture,startMS,endMS,false) end
    elseif event=="UNIT_SPELLCAST_CHANNEL_START" then
        local cast,_,_,texture,startMS,endMS=UnitChannelInfo("player")
        if cast then channelName=cast; NewCast(cast,texture,startMS,endMS,true) end
    elseif event=="UNIT_SPELLCAST_SUCCEEDED" then
        local entry=pending[name]
        if entry then if not entry.isChannel then Finish(name,"success") end; return end
        if channelName==name or Repeating(name) then return end
        local now=GetTime()
        -- A late SUCCEEDED repairs a cast just marked failed/interrupted.
        for i=1,math.min(#history,5) do
            local h=history[i]
            if h.spellName==name and (h.status=="failed" or h.status=="interrupted") and h.finishedAt and now-h.finishedAt<=.5 then
                h.status="success"; h.fillProgress=nil; Refresh(); return
            end
        end
        local _,_,icon=GetSpellInfo(name)
        if not icon then return end
        Push({spellName=name,icon=icon,target=targets[name],startTime=now,endTime=now,castDuration=0,status="success",isInstant=true,timestamp=now})
        targets[name]=nil
    elseif event=="UNIT_SPELLCAST_FAILED" or event=="UNIT_SPELLCAST_FAILED_QUIET" then
        -- Pressing the key again mid-cast fails the new attempt, not the cast.
        if UnitCastingInfo("player")==name or UnitChannelInfo("player")==name then return end
        Finish(name,"failed")
    elseif event=="UNIT_SPELLCAST_INTERRUPTED" then
        Finish(name,"interrupted")
    elseif event=="UNIT_SPELLCAST_STOP" then
        local entry=pending[name]
        if entry and entry.status=="casting" then stopQueue[name]=true; stopDriver:Show() end
    elseif event=="UNIT_SPELLCAST_CHANNEL_STOP" then
        if channelName==name then channelName=nil end
        targets[name]=nil
        local entry=pending[name]
        if entry then
            pending[name]=nil
            if entry.status=="channeling" then entry.status="success" end
            entry.endTime=GetTime(); entry.finishedAt=entry.endTime; entry.castDuration=entry.endTime-entry.startTime
            Refresh()
        end
    end
end
local events=CreateFrame("Frame"); local eventsActive=false; ns.castEvents=events
local EVENTS={"UNIT_SPELLCAST_SENT","UNIT_SPELLCAST_START","UNIT_SPELLCAST_SUCCEEDED","UNIT_SPELLCAST_FAILED","UNIT_SPELLCAST_FAILED_QUIET",
    "UNIT_SPELLCAST_INTERRUPTED","UNIT_SPELLCAST_STOP","UNIT_SPELLCAST_CHANNEL_START","UNIT_SPELLCAST_CHANNEL_STOP"}
local function RegisterEvents()
    if eventsActive then return end
    for _,event in ipairs(EVENTS) do pcall(events.RegisterEvent,events,event) end
    events:SetScript("OnEvent",OnEvent); eventsActive=true
end
local function UnregisterEvents()
    if not eventsActive then return end
    events:UnregisterAllEvents(); events:SetScript("OnEvent",nil); eventsActive=false
end
-------------------------------------------------------------------------------
--  Icon strip
-------------------------------------------------------------------------------
local container,strip
local icons={}
local lastAnim,lastCount,layoutKey=0,0,""
-- The saved iconPos is the TOPLEFT of the newest icon; the container grows
-- around it so length or direction changes never move the row.
local function Geometry(count)
    local sh=DB()
    local size=math.floor((sh.iconSize or 36)+.5); local gap=sh.iconSpacing or 1; local dir=sh.growDirection or "LEFT"
    count=math.max(1,count or sh.iconCount or 5)
    local span=count*size+(count-1)*gap; local horizontal=dir=="LEFT" or dir=="RIGHT"
    return size,gap,dir,horizontal and span or size,horizontal and size or span,dir=="LEFT" and span-size or 0,dir=="UP" and span-size or 0
end
local function PositionContainer(count)
    if not container then return end
    local size,_,dir,width,height,leftOffset,upOffset=Geometry(count)
    ns.Size(container,width,height); ns.Size(strip,size,size); strip:ClearAllPoints()
    if dir=="RIGHT" then strip:SetPoint("LEFT",container,"LEFT",0,0)
    elseif dir=="LEFT" then strip:SetPoint("RIGHT",container,"RIGHT",0,0)
    elseif dir=="DOWN" then strip:SetPoint("TOP",container,"TOP",0,0)
    else strip:SetPoint("BOTTOM",container,"BOTTOM",0,0) end
    if E.IsUnlockAnchored and E.IsUnlockAnchored("EDM_IconHistory") then return end
    local pos=DB().iconPos
    local left=pos and pos.x or UIParent:GetWidth()*.5-size*.5
    local top=pos and pos.y or UIParent:GetHeight()*.5+size*.5
    container:ClearAllPoints(); container:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",left-leftOffset,top+upOffset)
end
local function SaveIconPosition(count)
    local left,top=container:GetLeft(),container:GetTop(); if not left or not top then return end
    local _,_,_,_,_,leftOffset,upOffset=Geometry(count)
    DB().iconPos={x=left+leftOffset,y=top-upOffset}
end
local function StartIconDrag(_,button)
    local anchored=E.IsUnlockAnchored and E.IsUnlockAnchored("EDM_IconHistory")
    if button=="LeftButton" and IsShiftKeyDown() and container and not anchored then container.dragging=true; container:StartMoving() end
end
local function StopIconDrag()
    if not container or not container.dragging then return end
    container.dragging=nil; container:StopMovingOrSizing(); SaveIconPosition(container.layoutCount)
    if not IsShiftKeyDown() then strip:EnableMouse(false); for _,ic in ipairs(icons) do ic.frame:EnableMouse(false) end end
end
-- Out of combat each icon fades once older than iconFadeTime; in combat the
-- clock is parked and the time spent fighting is credited afterwards.
local fadeDriver=CreateFrame("Frame"); fadeDriver:Hide()
fadeDriver:SetScript("OnUpdate",function(self,dt)
    self.wait=(self.wait or 0)-dt
    if self.wait<=0 then self:Hide(); ns.BuildIconStrip() end
end)
local combatStart
local function FadeBase(entry) return entry.fadeBase or entry.timestamp or 0 end
local function ScheduleFade(fadeTime,maxIcons)
    fadeDriver:Hide()
    local n=math.min(#history,maxIcons); if n==0 then return end
    local now=GetTime(); local nextIn
    for i=1,n do
        local age=now-FadeBase(history[i])
        if age<fadeTime then local d=fadeTime-age; if not nextIn or d<nextIn then nextIn=d end
        elseif age<fadeTime+FADE_DUR then nextIn=.05; break
        else break end
    end
    if nextIn then fadeDriver.wait=math.max(.05,nextIn+.02); fadeDriver:Show() end
end
local fadeEvents=CreateFrame("Frame")
fadeEvents:SetScript("OnEvent",function(_,event)
    if event=="PLAYER_REGEN_DISABLED" then combatStart=GetTime(); fadeDriver:Hide(); return end
    local start=combatStart; combatStart=nil
    if (DB().iconFadeTime or 0)<=0 then return end
    local now=GetTime(); start=start or now
    for _,entry in ipairs(history) do local base=FadeBase(entry); entry.fadeBase=base+(now-math.max(start,base)) end
    ns.BuildIconStrip()
end)
local function PlayIconAnim(ic,kind,dir,alpha)
    local f=ic.frame
    f:SetScript("OnUpdate",nil); f:SetScale(1); f:ClearAllPoints(); f:SetPoint("CENTER",strip,"CENTER",0,0)
    local dx,dy=0,0
    if kind=="slide" then
        if dir=="LEFT" then dx=ANIM_SLIDE elseif dir=="RIGHT" then dx=-ANIM_SLIDE elseif dir=="UP" then dy=-ANIM_SLIDE else dy=ANIM_SLIDE end
    end
    local fly=kind=="fly"; local elapsed=0; local startAlpha=alpha*.5
    f:SetAlpha(startAlpha)
    if fly then f:SetScale(1.35) end
    if dx~=0 or dy~=0 then f:SetPoint("CENTER",strip,"CENTER",dx,dy) end
    f:SetScript("OnUpdate",function(self,dt)
        elapsed=elapsed+dt
        local t=math.min(1,elapsed/ANIM_DUR); local inv=1-t; local ease=1-inv*inv*inv
        self:SetAlpha(startAlpha+(alpha-startAlpha)*ease)
        if dx~=0 or dy~=0 then self:SetPoint("CENTER",strip,"CENTER",dx*(1-ease),dy*(1-ease)) end
        if fly then self:SetScale(1.35-.35*ease) end
        if t>=1 then self:SetScript("OnUpdate",nil); self:SetAlpha(alpha); self:SetScale(1); self:SetPoint("CENTER",strip,"CENTER",0,0) end
    end)
end
local function MakeIcon()
    local ic={frame=CreateFrame("Frame",nil,strip)}
    ic.frame:EnableMouse(false)
    ic.frame:SetScript("OnMouseDown",StartIconDrag); ic.frame:SetScript("OnMouseUp",StopIconDrag)
    ic.bg=ic.frame:CreateTexture(nil,"BACKGROUND"); ic.bg:SetAllPoints(ic.frame); ic.bg:SetTexture(white); ic.bg:SetVertexColor(0,0,0,.4)
    ic.tex=ic.frame:CreateTexture(nil,"ARTWORK"); ic.tex:SetAllPoints(ic.frame)
    ic.frame:Hide(); return ic
end
local previewIcons
local function PreviewIcons()
    if previewIcons then return previewIcons end
    previewIcons={}
    if GetActionInfo and GetActionTexture then
        local seen={}
        for slot=1,120 do
            if GetActionInfo(slot)=="spell" then
                local tex=GetActionTexture(slot)
                if tex and not seen[tex] then seen[tex]=true; previewIcons[#previewIcons+1]=tex; if #previewIcons>=10 then break end end
            end
        end
    end
    if #previewIcons==0 then previewIcons={QUESTION} end
    return previewIcons
end
local function CreateStrip()
    container=CreateFrame("Frame","EllesmereUIDMIconHistoryFrame",UIParent)
    container:SetFrameStrata("MEDIUM"); container:SetClampedToScreen(true); container:SetMovable(true); container:EnableMouse(false)
    strip=CreateFrame("Frame","EllesmereUIDMIconStrip",container); strip:EnableMouse(false)
    strip:SetScript("OnMouseDown",StartIconDrag); strip:SetScript("OnMouseUp",StopIconDrag)
    -- Click-through unless Shift is held.
    local modifiers=CreateFrame("Frame")
    local function ShiftMouse(on)
        if not on and container.dragging then return end
        strip:EnableMouse(on); for _,ic in ipairs(icons) do ic.frame:EnableMouse(on) end
    end
    modifiers:SetScript("OnEvent",function(_,_,key,down) if key=="LSHIFT" or key=="RSHIFT" then ShiftMouse(down==1) end end)
    container:SetScript("OnShow",function() modifiers:RegisterEvent("MODIFIER_STATE_CHANGED"); ShiftMouse(IsShiftKeyDown() and true or false) end)
    container:SetScript("OnHide",function() modifiers:UnregisterEvent("MODIFIER_STATE_CHANGED") end)
    container:Hide()
    for i=1,POOL_SIZE do icons[i]=MakeIcon() end
end
function ns.BuildIconStrip()
    local sh=DB()
    if not sh.iconEnabled or Hidden(sh,"icon") then if container then container:Hide() end; fadeDriver:Hide(); return end
    if not container then CreateStrip() end
    local size,gap,dir=Geometry()
    local zoom=sh.iconZoom or .08; local maxIcons=sh.iconCount or 5
    local count=math.min(#history,maxIcons)
    local fadeTime=sh.iconFadeTime or 0; local fadeNow
    if fadeTime>0 then
        fadeEvents:RegisterEvent("PLAYER_REGEN_DISABLED"); fadeEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
        if not InCombatLockdown() then
            fadeNow=GetTime()
            local visible=0
            for i=1,count do if fadeNow-FadeBase(history[i])<fadeTime+FADE_DUR then visible=i else break end end
            count=visible
            ScheduleFade(fadeTime,maxIcons)
        end
    else fadeEvents:UnregisterAllEvents(); fadeDriver:Hide() end
    local histCount=count
    -- Unlock Mode reserves the full footprint; the options preview fills empty slots.
    local preview=ns.preview or ns.optionsOpen and histCount<maxIcons and not (fadeTime>0 and #history>0)
    if preview then count=maxIcons end
    if count==0 then container:Hide(); return end
    local alpha=sh.iconOpacity or 1
    local key=size.."|"..gap.."|"..dir.."|"..count.."|"..alpha
    local relayout=key~=layoutKey
    if relayout then container.layoutCount=count; PositionContainer(count); layoutKey=key end
    for i=1,math.max(count,lastCount) do
        local ic=icons[i]; if not ic then break end
        if i<=count then
            if ic.zoom~=zoom then ic.zoom=zoom; ic.tex:SetTexCoord(zoom,1-zoom,zoom,1-zoom) end
            if relayout then
                ic.frame:SetScript("OnUpdate",nil); ic.frame:SetScale(1); ns.Size(ic.frame,size,size); ic.frame:ClearAllPoints()
                local offset=(i-1)*(size+gap)
                if dir=="RIGHT" then ic.frame:SetPoint("CENTER",strip,"CENTER",offset,0)
                elseif dir=="LEFT" then ic.frame:SetPoint("CENTER",strip,"CENTER",-offset,0)
                elseif dir=="DOWN" then ic.frame:SetPoint("CENTER",strip,"CENTER",0,-offset)
                else ic.frame:SetPoint("CENTER",strip,"CENTER",0,offset) end
                ic.frame:SetAlpha(alpha)
            end
            if i<=histCount then
                local entry=history[i]; ic.isPreview=nil
                if ic.entry~=entry then ic.entry=entry; ic.tex:SetTexture(entry.icon or QUESTION); ic.status=nil end
                if ic.status~=entry.status then
                    ic.status=entry.status
                    if entry.status=="failed" or entry.status=="interrupted" then ic.tex:SetVertexColor(STOPPED[1],STOPPED[2],STOPPED[3],1)
                    else ic.tex:SetVertexColor(1,1,1,1) end
                    ic.tex:SetAlpha(1)
                end
                if fadeNow then
                    local age=fadeNow-FadeBase(entry)
                    if age>fadeTime then ic.frame:SetAlpha(alpha*math.max(0,1-(age-fadeTime)/FADE_DUR)); ic.fading=true
                    elseif ic.fading then ic.frame:SetAlpha(alpha); ic.fading=nil end
                elseif ic.fading then ic.frame:SetAlpha(alpha); ic.fading=nil end
            elseif not ic.isPreview then
                local list=PreviewIcons()
                ic.isPreview=true; ic.entry=nil; ic.status=nil
                ic.tex:SetTexture(list[(i-1)%#list+1]); ic.tex:SetVertexColor(1,1,1,1); ic.tex:SetAlpha(.75)
            end
            ic.frame:Show()
            if i==1 and histCount>0 and history[1].timestamp~=lastAnim then
                lastAnim=history[1].timestamp
                local kind=sh.iconAnimation or "none"
                if kind~="none" then PlayIconAnim(ic,kind,dir,alpha) end
            end
        else ic.frame:SetScript("OnUpdate",nil); ic.frame:SetScale(1); ic.frame:Hide() end
    end
    lastCount=count
    strip:Show(); container:Show()
end
local function RegisterIconUnlock()
    if ns.iconUnlockRegistered or not E.RegisterUnlockElements or not E.MakeUnlockElement then return end
    ns.iconUnlockRegistered=true
    local function Unlock() return Geometry(DB().iconCount or 5) end
    E:RegisterUnlockElements({E.MakeUnlockElement({key="EDM_IconHistory",label="Icon History",group="Damage Meters",order=950+ns.MAX_WINDOWS+2,
        noResize=true,noAnchorTarget=true,noInitHook=true,
        getFrame=function() return container end,
        getSize=function() local _,_,_,w,h=Unlock(); return w,h end,
        isHidden=function() return not DB().iconEnabled end,
        savePos=function(_,_,_,x,y)
            -- Unlock Mode stores CENTER offsets; convert to the newest-icon TOPLEFT.
            local size,_,dir,w,h=Unlock()
            local left=UIParent:GetWidth()*.5+(x or 0)-w*.5; local top=UIParent:GetHeight()*.5+(y or 0)+h*.5
            if dir=="LEFT" then left=left+w-size end
            if dir=="UP" then top=top-h+size end
            DB().iconPos={x=left,y=top}
        end,
        loadPos=function()
            local pos=DB().iconPos; local size,_,dir,w,h=Unlock()
            local left=(pos and pos.x or UIParent:GetWidth()*.5-size*.5)-(dir=="LEFT" and w-size or 0)
            local top=(pos and pos.y or UIParent:GetHeight()*.5+size*.5)+(dir=="UP" and h-size or 0)
            return {point="CENTER",relPoint="CENTER",x=left+w*.5-UIParent:GetWidth()*.5,y=top-h*.5-UIParent:GetHeight()*.5}
        end,
        clearPos=function() DB().iconPos=nil end,
        applyPos=function() PositionContainer(ns.preview and DB().iconCount or container and container.layoutCount) end})},ADDON)
    E._ELEMENT_SETTINGS_MAP=E._ELEMENT_SETTINGS_MAP or {}
    E._ELEMENT_SETTINGS_MAP.EDM_IconHistory={module=ADDON,page="Spell History",sectionName="ICON HISTORY",highlightText="Enable Icon History"}
end
-------------------------------------------------------------------------------
--  Bar window
-------------------------------------------------------------------------------
local win
local bars={}
local scroll,fontKey,barLayout,lastVisible=0,"","",0
local function MakeBar(parent)
    local bar={}
    bar.row=CreateFrame("Frame",nil,parent); bar.row:SetHeight(18)
    bar.icon=bar.row:CreateTexture(nil,"OVERLAY"); ns.Size(bar.icon,18,18); bar.icon:SetPoint("LEFT",bar.row,"LEFT",0,0)
    bar.fill=CreateFrame("StatusBar",nil,bar.row); bar.fill:SetPoint("TOPLEFT",bar.icon,"TOPRIGHT",0,0); bar.fill:SetPoint("BOTTOMRIGHT",bar.row,"BOTTOMRIGHT",0,0)
    bar.fill:SetMinMaxValues(0,1); bar.fill:SetValue(1); bar.fill:SetStatusBarTexture(white)
    local host=CreateFrame("Frame",nil,bar.fill); host:SetAllPoints(bar.fill); host:SetFrameLevel(bar.fill:GetFrameLevel()+2)
    bar.right=ns.Text(host,11); bar.right:SetPoint("RIGHT",host,"RIGHT",-3,0); bar.right:SetJustifyH("RIGHT")
    bar.label=ns.Text(host,11); bar.label:SetPoint("LEFT",bar.icon,"RIGHT",4,0); bar.label:SetPoint("RIGHT",bar.right,"LEFT",-4,0)
    bar.row:Hide(); return bar
end
function ns.OpenSpellHistorySettings()
    if ns.optionsOpen and E.Hide then E:Hide(); return end
    if E.EnsureOptionsLoaded then E.EnsureOptionsLoaded() end
    if not E.ShowModule then return end
    E:ShowModule(ADDON)
    local defer=CreateFrame("Frame")
    defer:SetScript("OnUpdate",function(self) self:SetScript("OnUpdate",nil); if E.SelectPage then E:SelectPage("Spell History") end end)
end
local function HeaderHeight(sh) return sh.hideTopBar and 0 or 22 end
local function CreateBarWindow()
    local sh=DB()
    win=CreateFrame("Frame","EllesmereUIDMBarHistory",UIParent)
    win:SetClampedToScreen(true); win:SetMovable(true); win:SetFrameStrata("MEDIUM"); win:EnableMouse(false)
    win.visSlots=1
    win:SetScript("OnShow",function() if next(pending) and ns.StartCastAnim then ns.StartCastAnim(true) end end)
    win:Hide()
    win.bg=win:CreateTexture(nil,"BACKGROUND"); win.bg:SetAllPoints(win); win.bg:SetTexture(white)
    local hdr=CreateFrame("Frame",nil,win); hdr:SetHeight(22)
    hdr:SetPoint("TOPLEFT",win,"TOPLEFT",0,0); hdr:SetPoint("TOPRIGHT",win,"TOPRIGHT",0,0)
    hdr:SetFrameLevel(win:GetFrameLevel()+5); hdr:EnableMouse(true); win.hdr=hdr
    hdr.bg=hdr:CreateTexture(nil,"BACKGROUND"); hdr.bg:SetAllPoints(hdr); hdr.bg:SetTexture(white)
    win.title=ns.Text(hdr,11); win.title:SetPoint("LEFT",hdr,"LEFT",6,0); win.title:SetText("Spell History")
    local function Button(file,n,tip,fn)
        local b=ns.HeaderIcon(hdr,file,tip,fn); b:SetFrameLevel(hdr:GetFrameLevel()+2)
        b:SetPoint("RIGHT",hdr,"RIGHT",-(22*(n-1)-2*n+2),0); return b
    end
    Button("dm_settings.tga",1,"Settings",ns.OpenSpellHistorySettings)
    win.lockButton=Button(sh.barLocked and "dm_locked_top.tga" or "dm_unlock_top.tga",2,sh.barLocked and "Locked" or "Unlocked",function(self)
        local s=DB(); s.barLocked=not s.barLocked
        self.icon:SetTexture(ns.MEDIA..(s.barLocked and "dm_locked_top.tga" or "dm_unlock_top.tga"))
        self.tip=s.barLocked and "Locked" or "Unlocked"; ns.ShowTip(self,self.tip)
    end)
    local resize=Button("dm_width_resize.tga",3,"Resize Width")
    resize:SetScript("OnMouseDown",function(_,button)
        if button~="LeftButton" or DB().barLocked then return end
        local left,top=win:GetLeft(),win:GetTop()
        if left and top then win:ClearAllPoints(); win:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",left,top) end
        local x=GetCursorPosition(); win.resizeX=x/win:GetEffectiveScale(); win.resizeW=win:GetWidth(); win.resizing=true
        resize:SetScript("OnUpdate",function()
            local cx=GetCursorPosition()
            win:SetWidth(math.max(MIN_BAR_WIDTH,win.resizeW+(cx/win:GetEffectiveScale()-win.resizeX)))
        end)
    end)
    resize:SetScript("OnMouseUp",function(_,button)
        if button~="LeftButton" or not win.resizing then return end
        win.resizing=nil; resize:SetScript("OnUpdate",nil)
        local s=DB(); s.barWidth=math.floor(win:GetWidth()+.5)
        local left,top=win:GetLeft(),win:GetTop(); if left and top then s.barPos={x=left,y=top} end
    end)
    hdr:SetScript("OnMouseDown",function(_,button) if button=="LeftButton" and not DB().barLocked then win.moving=true; win:StartMoving() end end)
    hdr:SetScript("OnMouseUp",function()
        if not win.moving then return end
        win.moving=nil; win:StopMovingOrSizing()
        local left,top=win:GetLeft(),win:GetTop(); if left and top then DB().barPos={x=left,y=top} end
    end)
    local content=CreateFrame("Frame",nil,win); content:EnableMouse(false); win.content=content
    content:EnableMouseWheel(true)
    content:SetScript("OnMouseWheel",function(_,delta)
        scroll=math.max(0,math.min(scroll-delta,math.max(0,math.min(#history,DB().maxBars or 5)-(win.visSlots or 1))))
        ns.RefreshBarWindow()
    end)
    for i=1,POOL_SIZE do bars[i]=MakeBar(content) end
    win.bars=bars
end
local function BuildBarWindow()
    local sh=DB()
    if not sh.barEnabled or Hidden(sh,"bar") then if win then win:Hide() end; return end
    if not win then CreateBarWindow() end
    local w1=ns.Profile().windows[1]
    local bg=sh.bgColor or {}
    win.bg:SetVertexColor(bg.r or 0,bg.g or 0,bg.b or 0,sh.bgAlpha or .25)
    local hc=w1.headerColor or {}
    win.hdr.bg:SetVertexColor(hc.r or .106,hc.g or .106,hc.b or .106,w1.chromeAlpha==nil and 1 or w1.chromeAlpha)
    if w1.titleUseAccent~=false then win.title:SetTextColor(ns.Accent())
    else local c=w1.titleColor or {}; win.title:SetTextColor(c.r or 1,c.g or 1,c.b or 1) end
    local hh=HeaderHeight(sh)
    if hh==0 then win.hdr:Hide() else win.hdr:Show() end
    win.content:ClearAllPoints(); win.content:SetPoint("TOPLEFT",win,"TOPLEFT",0,-hh); win.content:SetPoint("BOTTOMRIGHT",win,"BOTTOMRIGHT",0,0)
    local stride=(sh.barHeight or 20)+(w1.barSpacing or 2)
    ns.Size(win,math.max(MIN_BAR_WIDTH,sh.barWidth or 300),hh+(sh.maxBars or 5)*stride)
    win.lockButton.icon:SetTexture(ns.MEDIA..(sh.barLocked and "dm_locked_top.tga" or "dm_unlock_top.tga"))
    win.lockButton.tip=sh.barLocked and "Locked" or "Unlocked"
    local pos=sh.barPos
    if not win.moving and not win.resizing then
        win:ClearAllPoints()
        if pos and pos.x and pos.y then win:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",pos.x,pos.y) else win:SetPoint("CENTER",UIParent,"CENTER",0,0) end
    end
    win:Show(); ns.RefreshBarWindow()
end
function ns.RefreshBarWindow()
    if not win or not win:IsShown() then return end
    local sh=DB(); local w1=ns.Profile().windows[1]
    local barH=sh.barHeight or 20; local stride=barH+(w1.barSpacing or 2)
    local texture=BarTexture(sh); local textSize=sh.textSize or 11
    local visSlots=math.max(1,sh.maxBars or 5); win.visSlots=visSlots
    local tr,tg,tb
    if sh.textColorMode=="accent" then tr,tg,tb=ns.Accent() else local c=sh.textColor or {}; tr,tg,tb=c.r or 1,c.g or 1,c.b or 1 end
    local fonts=textSize.."|"..tostring(w1.fontOutline)
    if fonts~=fontKey then
        fontKey=fonts
        for _,bar in ipairs(bars) do ns.Font(bar.label,textSize,w1.fontOutline); ns.Font(bar.right,textSize,w1.fontOutline) end
    end
    local nr,ng,nb=BarColor(sh,"success"); local alpha=sh.barOpacity or 1; local zoom=sh.iconZoom or .08
    local layout=barH.."|"..stride.."|"..texture; local relayout=layout~=barLayout; barLayout=layout
    local total=math.min(#history,sh.maxBars or 5)
    for i=1,math.max(visSlots,lastVisible) do
        local bar=bars[i]; if not bar then break end
        local entry=i<=visSlots and history[scroll+i]
        if entry and scroll+i<=total then
            if bar.zoom~=zoom then bar.zoom=zoom; bar.icon:SetTexCoord(zoom,1-zoom,zoom,1-zoom) end
            if relayout or bar.slot~=i then
                bar.slot=i; local y=-(i-1)*stride
                bar.row:ClearAllPoints(); bar.row:SetPoint("TOPLEFT",win.content,"TOPLEFT",0,y); bar.row:SetPoint("TOPRIGHT",win.content,"TOPRIGHT",0,y)
                bar.row:SetHeight(barH); bar.fill:SetStatusBarTexture(texture); ns.Size(bar.icon,barH,barH)
                bar.label:SetHeight(barH); bar.right:SetHeight(barH)
            end
            if entry.icon then bar.icon:SetTexture(entry.icon); bar.icon:Show() else bar.icon:Hide() end
            bar.label:SetText(entry.spellName or "?")
            if entry.status=="failed" or entry.status=="interrupted" then bar.fill:SetStatusBarColor(STOPPED[1],STOPPED[2],STOPPED[3],alpha)
            else bar.fill:SetStatusBarColor(nr,ng,nb,alpha) end
            if entry.fillProgress then bar.fill:SetValue(entry.fillProgress)
            elseif entry.status=="casting" or entry.status=="channeling" then
                local d=entry.endTime-entry.startTime; local now=GetTime()
                bar.fill:SetValue(d>0 and math.max(0,math.min(1,entry.status=="channeling" and (entry.endTime-now)/d or (now-entry.startTime)/d)) or 1)
            else bar.fill:SetValue(1) end
            bar.label:SetTextColor(tr,tg,tb,1); bar.right:SetTextColor(tr,tg,tb,1)
            bar.right:SetText(RightText(entry)); bar.row:Show()
        else bar.row:Hide(); bar.slot=nil end
    end
    lastVisible=visSlots
end
-- Per-frame fill/elapsed update, only while a cast is in progress and the
-- bar window is visible.
local castAnim=CreateFrame("Frame"); castAnim:Hide()
castAnim:SetScript("OnUpdate",function(self)
    if not next(pending) or not win or not win:IsVisible() then self:Hide(); return end
    local now=GetTime()
    for i=1,math.min(win.visSlots or 5,POOL_SIZE) do
        local entry=history[scroll+i]; if not entry then break end
        if entry.status=="casting" or entry.status=="channeling" then
            local bar=bars[i]
            if bar and bar.row:IsShown() then
                local d=entry.endTime-entry.startTime
                if d>0 then bar.fill:SetValue(math.max(0,math.min(1,entry.status=="channeling" and (entry.endTime-now)/d or (now-entry.startTime)/d))) end
                bar.right:SetText(RightText(entry))
            end
        end
    end
end)
function ns.StartCastAnim(onShow) if onShow or win and win:IsVisible() then castAnim:Show() end end
function ns.ApplySpellHistory()
    local p=ns.Profile(); if not p then return end
    local sh=DB()
    for key,value in pairs(ns.defaults.profile.spellHistory) do if sh[key]==nil then sh[key]=ns.Copy(value) end end
    if sh.iconEnabled or sh.barEnabled then RegisterEvents() else UnregisterEvents(); castAnim:Hide() end
    layoutKey=""
    if sh.iconEnabled then RegisterIconUnlock(); ns.BuildIconStrip() elseif container then container:Hide(); fadeDriver:Hide() end
    if sh.barEnabled then BuildBarWindow() elseif win then win:Hide() end
end
local zone=CreateFrame("Frame")
zone:RegisterEvent("ZONE_CHANGED_NEW_AREA"); zone:RegisterEvent("PLAYER_ENTERING_WORLD")
zone:SetScript("OnEvent",function() if ns.Profile() then ns.ApplySpellHistory() end end)
