-- Wrath HUD: native menu/bag actions and aura buttons; independent data bars.
local _,ns=...
local E=EllesmereUI
if not ns.IsWrath then return end
local H={holders={},states={},dirty=true}
ns.NativeHUD=H
local flat="Interface\\Buttons\\WHITE8X8"
-- Bundled from the installed ElvUI Norm texture; ElvUI itself is not required.
local dataTexture="Interface\\AddOns\\EllesmereUIActionBars\\Media\\Textures_335\\elvui-norm.tga"
local definitions={
    {key="micro",label="Micro Menu",group="Action Bars",point="BOTTOMRIGHT",x=-10,y=10},
    {key="bags",label="Bag Bar",group="Action Bars",point="BOTTOMRIGHT",x=-10,y=48},
    {key="xp",label="Experience Bar",group="Data Bars",point="BOTTOM",x=0,y=16},
    {key="reputation",label="Reputation Bar",group="Data Bars",point="BOTTOM",x=0,y=36},
    {key="buffs",label="Player Buffs",group="Player Auras",point="TOPRIGHT",x=-200,y=-15},
    {key="debuffs",label="Player Debuffs",group="Player Auras",point="TOPRIGHT",x=-200,y=-110},
}
H.definitions=definitions
local micros={
    {"CharacterMicroButton","INV_Misc_Head_Human_01"},{"SpellbookMicroButton","INV_Misc_Book_09"},
    {"TalentMicroButton","Ability_Marksmanship"},{"AchievementMicroButton","Achievement_Level_80"},
    {"QuestLogMicroButton","INV_Misc_Note_01"},{"ParagonMicroButton","INV_Misc_Coin_01"},{"SocialsMicroButton","INV_Misc_GroupNeedMore"},
    {"PVPMicroButton","INV_BannerPVP_01"},{"LFDMicroButton","INV_Helmet_08"},
    {"CollectionsMicroButton","INV_Misc_Bag_10"},{"StoreMicroButton","INV_Misc_Coin_01"},
    {"MainMenuMicroButton","INV_Misc_Gear_01"},{"HelpMicroButton","INV_Misc_QuestionMark"},
}
local function Settings() local p=ns.GetSettings(); return p and p.nativeHUD,p end
local function Enabled(key) local p,r=Settings(); return r and r.enabled and p and p[key]~=false end
local function ProgressInDataBars(key)
    local bars=E._ModuleNS and E._ModuleNS.EllesmereUIDataBars
    return bars and bars.ProgressUsed and bars.ProgressUsed(key)
end
local function Clamp(v,a,b) return math.max(a,math.min(b,tonumber(v) or a)) end
local function Size(f,w,h) f:SetWidth(w); f:SetHeight(h) end
local function State(key)
    if not H.states[key] then H.states[key]={frames={},textures={},fonts={},buttons={},owned={}} end
    return H.states[key]
end
local function Remember(s,f)
    if not f or s.frames[f] then return end
    local points={}; for i=1,f:GetNumPoints() do points[i]={f:GetPoint(i)} end
    s.frames[f]={points=points,parent=f:GetParent(),w=f:GetWidth(),h=f:GetHeight(),scale=f.GetScale and f:GetScale(),
        alpha=f:GetAlpha(),mouse=f.IsMouseEnabled and f:IsMouseEnabled(),hitRect=f.GetHitRectInsets and {f:GetHitRectInsets()}}
end
local function Texture(s,t,clear)
    if not t or s.owned[t] then return end
    if not s.textures[t] then s.textures[t]={path=t:GetTexture(),alpha=t:GetAlpha(),coords={t:GetTexCoord()}} end
    if clear then s.textures[t].clear=true; t:SetTexture(nil); t:SetAlpha(0) end
end
local function Restore(key)
    local s=State(key); if not s.active then return end; s.active=false
    for f,d in pairs(s.frames) do
        f:SetParent(d.parent); f:ClearAllPoints(); for _,point in ipairs(d.points) do f:SetPoint(unpack(point)) end
        Size(f,d.w,d.h); if d.scale~=nil and f.SetScale then f:SetScale(d.scale) end; f:SetAlpha(d.alpha)
        if d.mouse~=nil then f:EnableMouse(d.mouse) end
        if d.hitRect and #d.hitRect==4 then f:SetHitRectInsets(unpack(d.hitRect)) end
    end
    for t,d in pairs(s.textures) do
        if d.clear then t:SetTexture(d.path) end
        t:SetAlpha(d.alpha); t:SetTexCoord(unpack(d.coords))
    end
    for fs,d in pairs(s.fonts) do fs:SetFont(unpack(d)) end
    for _,d in pairs(s.buttons) do d.panel:Hide(); if d.icon then d.icon:Hide() end end
    local f=H.holders[key]
    if f and f~=BuffFrame and f~=_G.DebuffFrame then f:Hide() end
end
local function Panel(parent)
    local f=CreateFrame("Frame",nil,parent); f:EnableMouse(false); f:SetAllPoints(parent)
    f:SetFrameLevel(math.max(0,parent:GetFrameLevel()-1))
    f:SetBackdrop({bgFile=flat,edgeFile=flat,edgeSize=1})
    f:SetBackdropColor(.045,.045,.045,.98); f:SetBackdropBorderColor(.2,.2,.2,1); return f
end
local function Holder(d)
    local f=H.holders[d.key]; if f then return f end
    f=CreateFrame("Frame","EUI335_HUD_"..d.key,UIParent)
    H.holders[d.key]=f; Size(f,240,32)
    return f
end
local function Position(d,f)
    local p=ns.GetSettings(); local pos=p and p.barPositions["hud_"..d.key]
    f:ClearAllPoints()
    if pos then f:SetPoint(pos.point,UIParent,pos.relPoint,pos.x,pos.y)
    else f:SetPoint(d.point,UIParent,d.point,d.x,d.y) end
end
local function Button(s,b,iconPath,micro)
    Remember(s,b)
    local d=s.buttons[b]
    if not d then
        d={panel=Panel(b)}; s.buttons[b]=d
        if micro then
            d.icon=b:CreateTexture(nil,"ARTWORK"); s.owned[d.icon]=true
            d.icon:SetPoint("TOPLEFT",b,"TOPLEFT",3,-3); d.icon:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-3,3)
            d.icon:SetTexCoord(.07,.93,.07,.93)
        end
        b:HookScript("OnEnter",function() if s.active then d.hover=true; d.panel:SetBackdropBorderColor(.047,.824,.616,1) end end)
        b:HookScript("OnLeave",function() d.hover=false; H.dirty=true end)
        b:HookScript("OnShow",function() H.dirty=true end)
    end
    local name=b:GetName() or ""
    local icon=not micro and (b.icon or _G[name.."IconTexture"])
    if micro then
        local source=_G[name.."Icon"] or _G[name.."IconTexture"]
        local sourcePath=source and (source:GetTexture() or s.textures[source] and s.textures[source].path)
        local sourceCoords=source and (s.textures[source] and s.textures[source].coords or {source:GetTexCoord()})
        for _,region in ipairs({b:GetRegions()}) do if region.GetObjectType and region:GetObjectType()=="Texture" then Texture(s,region,true) end end
        for _,suffix in ipairs({"Portrait","Background","BackgroundTexture"}) do Texture(s,_G[name..suffix],true) end
        d.icon:SetTexture("Interface\\Icons\\"..iconPath)
        if sourcePath then d.icon:SetTexture(sourcePath); d.icon:SetTexCoord(unpack(sourceCoords)) end
        if name=="CharacterMicroButton" and SetPortraitTexture then SetPortraitTexture(d.icon,"player") end
        d.icon:SetDesaturated(b.IsEnabled and not b:IsEnabled() or false); d.icon:Show()
    else
        for _,getter in ipairs({"GetNormalTexture","GetPushedTexture","GetHighlightTexture","GetDisabledTexture"}) do
            if b[getter] then local t=b[getter](b); if t~=icon then Texture(s,t,true) end end
        end
        if icon then Texture(s,icon,false); icon:SetTexCoord(.07,.93,.07,.93) end
        local fs=_G[name.."Count"]
        if fs and fs.GetFont then
            if not s.fonts[fs] then s.fonts[fs]={fs:GetFont()} end
            fs:SetFont(E.GetFontPath("actionBars"),11,"OUTLINE")
        end
    end
    local pressed=b.GetButtonState and b:GetButtonState()=="PUSHED"
    d.panel:SetBackdropBorderColor((d.hover or pressed) and .047 or .2,(d.hover or pressed) and .824 or .2,(d.hover or pressed) and .616 or .2,1)
    d.panel:Show()
end
local function LayoutButtons(key,f)
    local s=State(key); local p=Settings(); local list={}
    if key=="micro" then
        local paths={}; for _,entry in ipairs(micros) do paths[entry[1]]=entry[2] end
        local names=type(MICRO_BUTTONS)=="table" and #MICRO_BUTTONS>0 and MICRO_BUTTONS or nil
        if names then for _,value in ipairs(names) do
            local b=type(value)=="string" and _G[value] or value
            if b and b.GetName then list[#list+1]={b,paths[b:GetName()] or "INV_Misc_QuestionMark"} end
        end
        else for _,entry in ipairs(micros) do if _G[entry[1]] then list[#list+1]={_G[entry[1]],entry[2]} end end end
    else
        for _,name in ipairs({"MainMenuBarBackpackButton","CharacterBag0Slot","CharacterBag1Slot","CharacterBag2Slot","CharacterBag3Slot","KeyRingButton"}) do
            if _G[name] then list[#list+1]={_G[name]} end
        end
    end
    local size,gap=Clamp(p[key.."Size"] or p.buttonSize,20,48),Clamp(p[key.."Spacing"] or p.spacing,0,12)
    local consolidated=key=="bags" and p.bagsConsolidate
    if consolidated and not H.hiddenBags then H.hiddenBags=CreateFrame("Frame",nil,UIParent); H.hiddenBags:Hide() end
    Size(f,(consolidated and 1 or math.max(1,#list))*(size+gap)-gap,size); f:Show()
    for i,entry in ipairs(list) do
        local b=entry[1]; local keyring=b==_G.KeyRingButton
        Button(s,b,keyring and "INV_Misc_Key_03" or entry[2],key=="micro" or keyring)
        b:SetParent(consolidated and b~=_G.MainMenuBarBackpackButton and H.hiddenBags or f); b:SetScale(1); Size(b,size,size); b:ClearAllPoints()
        if b.SetHitRectInsets then b:SetHitRectInsets(0,0,0,0) end
        b:SetPoint("LEFT",f,"LEFT",(i-1)*(size+gap),0)
        -- Native events still decide availability and show/hide each slot.
    end
end
local function DataBar(key,f)
    if f.fill then return end
    f:SetFrameStrata("LOW")
    -- Keep the dark empty area on the holder, below its two inset status bars.
    f:SetBackdrop({bgFile=flat,edgeFile=flat,edgeSize=1})
    f:SetBackdropColor(.06,.06,.06,.95); f:SetBackdropBorderColor(.15,.15,.15,1)
    f.rested=CreateFrame("StatusBar",nil,f); f.rested:SetPoint("TOPLEFT",f,"TOPLEFT",1,-1); f.rested:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-1,1)
    f.rested:SetStatusBarTexture(dataTexture); f.rested:SetStatusBarColor(.5,0,.5,.8)
    f.fill=CreateFrame("StatusBar",nil,f); f.fill:SetPoint("TOPLEFT",f,"TOPLEFT",1,-1); f.fill:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-1,1)
    f.fill:SetStatusBarTexture(dataTexture)
    f.fill:SetFrameLevel(f.rested:GetFrameLevel()+1)
    f.text=f.fill:CreateFontString(nil,"OVERLAY"); f.text:SetPoint("CENTER",f,"CENTER",0,0)
    f:EnableMouse(true)
    f:SetScript("OnEnter",function()
        GameTooltip:SetOwner(f,"ANCHOR_TOP"); GameTooltip:AddLine(key=="xp" and "Experience" or f.faction or "Reputation",1,1,1)
        GameTooltip:AddLine(string.format("%d / %d (%.1f%%)",f.current or 0,f.maximum or 1,100*(f.current or 0)/(f.maximum or 1)),.9,.9,.9)
        if key=="xp" and GetXPExhaustion and GetXPExhaustion() then GameTooltip:AddLine("Rested: "..GetXPExhaustion(),.3,.6,1) end
        if key=="xp" and H.XP then H.XP.Tooltip(f) end
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave",function() GameTooltip:Hide() end)
    f:SetScript("OnMouseDown",function(_,button)
        local native=key=="xp" and MainMenuExpBar or ReputationWatchBar
        local handler=native and native:GetScript("OnMouseDown"); if handler then handler(native,button) end
    end)
end
-- Experience bar extras (Retail XP Bar tab): fill style, background, rested colour, Quest XP
-- Overlay, dividers with Smart Ticks and seven text positions. Retail's art styles (Professions
-- frame, flipbook fill, Forever border) need atlases this client does not have.
local XP={}
H.XP=XP
XP.POSITIONS={"Center","Left","Right","TopLeft","TopRight","BottomLeft","BottomRight"}
XP.POSITION_LABELS={Center="Center Text",Left="Left Text",Right="Right Text",TopLeft="Top Left Text",
    TopRight="Top Right Text",BottomLeft="Bottom Left Text",BottomRight="Bottom Right Text"}
XP.ITEM_VALUES={none="None",classic="XP and Rested %",pct="Percent",pctProjected="Percent (with Completed)",cur="Current XP",
    curMax="Current / Max",curMaxRem="Current / Max (Remaining)",restVal="Rested XP",restPct="Rested %",questVal="Completed Quest XP",
    questPct="Completed Quest %",completedRested="Completed % - Rested %",level="Level",xpPerHour="XP per Hour",
    levelingIn="Leveling In",timeLevel="Time This Level",timeSession="Time This Session"}
XP.ITEM_ORDER={"none","classic","pct","pctProjected","cur","curMax","curMaxRem","restVal","restPct","questVal","questPct",
    "completedRested","level","xpPerHour","levelingIn","timeLevel","timeSession"}
-- The "[Merfin] Experience Bar (Luxthos)" WeakAura's layout and colours.
XP.LUXTHOS={xpTextLeft="level",xpTextCenter="curMaxRem",xpTextRight="pctProjected",xpTextBottomLeft="levelingIn",
    xpTextBottomRight="completedRested",xpTextTopLeft="timeLevel",xpTextTopRight="timeSession",
    xpFillStyle="HORIZONTAL",xpColor={r=.3,g=.35,b=.97,a=1},xpGradEnd={r=.71,g=.34,b=1,a=1},
    xpQuestOverlay=true,xpQuestCompleted=false,xpQuestZone=false,xpQuestDoneColor={r=1,g=.59,b=0,a=.6},
    xpQuestColor={r=1,g=.8,b=0,a=.35},xpShowRested=true,xpRestedColor={r=.31,g=.56,b=1,a=.6},xpRestedAfterQuests=true,xpSpark=true}
function XP.ApplyLuxthos(p)
    for k,v in pairs(XP.LUXTHOS) do
        if type(v)=="table" then p[k]={r=v.r,g=v.g,b=v.b,a=v.a} else p[k]=v end
    end
end
-- Items with nothing to show at max level (the bar there carries the level and times).
local XP_MAX_HIDDEN={pct=true,pctProjected=true,restVal=true,restPct=true,questVal=true,questPct=true,
    completedRested=true,xpPerHour=true,levelingIn=true}
local XP_MAX_TEXT={classic=true,cur=true,curMax=true,curMaxRem=true}
XP.FILL_VALUES={flat="Flat",HORIZONTAL="Horizontal Gradient",VERTICAL="Vertical Gradient"}
XP.FILL_ORDER={"flat","HORIZONTAL","VERTICAL"}
XP.TICK_VALUES={dashed="Dashed",dotted="Dotted",solid="Solid",none="None"}
XP.TICK_ORDER={"dashed","dotted","solid","none"}
-- Text point, holder point, x, y, justification. Corners sit outside the bar.
local XP_PLACE={Center={"CENTER","CENTER",0,0,"CENTER"},Left={"LEFT","LEFT",4,0,"LEFT"},Right={"RIGHT","RIGHT",-4,0,"RIGHT"},
    TopLeft={"BOTTOMLEFT","TOPLEFT",0,2,"LEFT"},TopRight={"BOTTOMRIGHT","TOPRIGHT",0,2,"RIGHT"},
    BottomLeft={"TOPLEFT","BOTTOMLEFT",0,-2,"LEFT"},BottomRight={"TOPRIGHT","BOTTOMRIGHT",0,-2,"RIGHT"}}
local XP_QUEST_ITEMS={questVal=true,questPct=true,pctProjected=true,completedRested=true}
local XP_CLOCK_ITEMS={xpPerHour=true,levelingIn=true,timeLevel=true,timeSession=true}
local xpSession={gained=0}
local xpLevel={}
local xpQuest={done=0,open=0,all=0,dirty=true,last=-10}
local function XPColor(c,r,g,b,a)
    if type(c)~="table" then return r,g,b,a end
    return c.r or r,c.g or g,c.b or b,c.a or a
end
function XP.TextValue(p,pos)
    local v=p and p["xpText"..pos]
    if v==nil then v=pos=="Center" and "classic" or "none" end
    return XP.ITEM_VALUES[v] and v or "none"
end
-- In full below 10,000 (6,811), abbreviated from there (17.6K, 1.2M).
function XP.FmtNum(n)
    n=math.floor((tonumber(n) or 0)+.5)
    if n>=1e6 then return string.format("%.1fM",n/1e6) elseif n>=1e4 then return string.format("%.1fK",n/1e3) end
    local s=tostring(n); local k
    repeat s,k=s:gsub("^(-?%d+)(%d%d%d)","%1,%2") until k==0
    return s
end
function XP.FmtPct(v)
    v=tonumber(v) or 0
    if v==math.floor(v) then return string.format("%d%%",v) end
    return string.format("%.1f%%",v)
end
function XP.FmtDur(sec)
    sec=math.max(0,math.floor(tonumber(sec) or 0))
    local d,h,m=math.floor(sec/86400),math.floor(sec%86400/3600),math.floor(sec%3600/60)
    if d>0 then return string.format("%dd %dh",d,h) elseif h>0 then return string.format("%dh %dm",h,m) end
    return string.format("%dm",m)
end
-- XP per hour counts every gain since the UI loaded; a level-up adds what the old level
-- still needed plus the XP into the new one. A lower reading on the same level is taken
-- mid level-up and waits for the settled one.
-- The session, rate and level time are saved at logout (EllesmereUIDB.xpBarChars[guid]) and
-- taken back on a load within five minutes (a /reload): the level time always, which spares a
-- second /played, the session and rate only with Keep Session on Reload. GetTime() counts
-- on through a reload.
local XP_RESUME_WINDOW=300
function XP.Save()
    local guid=UnitGUID and UnitGUID("player"); if not guid then return end
    if not EllesmereUIDB then EllesmereUIDB={} end
    if not EllesmereUIDB.xpBarChars then EllesmereUIDB.xpBarChars={} end
    local s=xpSession
    EllesmereUIDB.xpBarChars[guid]={saved=GetTime(),start=s.start,gained=s.gained,cur=s.cur,max=s.max,level=s.level,
        levelBase=xpLevel.base,levelStamp=xpLevel.stamp,total=xpLevel.total,totalStamp=xpLevel.totalStamp}
end
function XP.Resume(p)
    local store=EllesmereUIDB and EllesmereUIDB.xpBarChars
    local guid=UnitGUID and UnitGUID("player")
    local e=store and guid and store[guid]
    if not e then return end
    store[guid]=nil
    local now=GetTime()
    if not (e.saved and e.saved<=now and now-e.saved<=XP_RESUME_WINDOW) then return end
    if e.levelBase and e.levelStamp and e.levelStamp<=now then
        xpLevel.base,xpLevel.stamp,xpLevel.total,xpLevel.totalStamp,xpLevel.asked=e.levelBase,e.levelStamp,e.total,e.totalStamp,true
    end
    if p and p.xpKeepSession and e.start and e.start<=now then
        xpSession.start,xpSession.gained,xpSession.cur,xpSession.max,xpSession.level=e.start,e.gained or 0,e.cur,e.max,e.level
    end
end
function XP.Track(cur,mx,level)
    local s=xpSession
    if not s.start then s.start=GetTime() end
    if s.level then
        if level>s.level then s.gained=s.gained+math.max(0,s.max-s.cur)+cur
        elseif level==s.level then
            if cur<s.cur then return end
            s.gained=s.gained+cur-s.cur
        end
    end
    s.cur,s.max,s.level=cur,mx,level
end
function XP.Rate(now)
    local s=xpSession; local elapsed=now-(s.start or now)
    if elapsed<60 or s.gained<=0 then return 0 end
    return s.gained/elapsed*3600
end
function XP.OnPlayed(total,thisLevel)
    local now=GetTime()
    if tonumber(thisLevel) then xpLevel.base,xpLevel.stamp=tonumber(thisLevel),now end
    if tonumber(total) then xpLevel.total,xpLevel.totalStamp=tonumber(total),now end
end
function XP.OnLevelUp()
    xpLevel.base,xpLevel.stamp=0,GetTime(); xpQuest.dirty=true
end
function XP.QuestsDirty() xpQuest.dirty=true end
-- Quest XP from the log. Completed quests feed the texts (every zone); the overlay's
-- completed and incomplete totals follow Completed Quests Only and Current Zone Only.
-- The Wrath reward XP reads the selected entry, so the selection is put back after.
-- Quests under collapsed headers are not listed by the client and are not counted.
function XP.ScanQuests(p)
    local all,done,open=0,0,0
    if GetNumQuestLogEntries and GetQuestLogTitle and SelectQuestLogEntry and GetQuestLogRewardXP then
        local previous=GetQuestLogSelection and GetQuestLogSelection() or 0
        local zone=GetRealZoneText and GetRealZoneText(); local header
        for i=1,GetNumQuestLogEntries() or 0 do
            local title,_,_,_,isHeader,_,isComplete=GetQuestLogTitle(i)
            if isHeader then header=title
            elseif title and isComplete~=-1 then
                SelectQuestLogEntry(i)
                local xp=tonumber(GetQuestLogRewardXP()) or 0
                local inZone=not p.xpQuestZone or header==zone
                if isComplete==1 then all=all+xp; if inZone then done=done+xp end
                elseif inZone and not p.xpQuestCompleted then open=open+xp end
            end
        end
        SelectQuestLogEntry(previous)
    end
    xpQuest.all,xpQuest.done,xpQuest.open,xpQuest.dirty,xpQuest.last=all,done,open,false,GetTime()
end
function XP.QuestXP() return xpQuest.all,xpQuest.done,xpQuest.open end
local function XPPct(v,mx) return XP.FmtPct(math.floor(v/mx*1000+.5)/10) end
function XP.ItemText(id,cur,mx,rested,level,now,atMax)
    local L=E.L or function(s) return s end
    if atMax then
        if XP_MAX_HIDDEN[id] then return "" elseif XP_MAX_TEXT[id] then return L("Max Level") end
        if id=="timeLevel" then
            return string.format(L("Time played: %s"),xpLevel.total and XP.FmtDur(xpLevel.total+now-xpLevel.totalStamp) or "--")
        end
    end
    if id=="pctProjected" then
        local t=XPPct(cur,mx)
        if xpQuest.all>0 then t=t.." ("..XPPct(math.min(mx,cur+xpQuest.all),mx)..")" end
        return t
    elseif id=="completedRested" then
        return string.format(L("Completed: %s - Rested: %s"),"|cFFFF9700"..XPPct(xpQuest.all,mx).."|r","|cFF4F90FF"..XPPct(rested,mx).."|r")
    elseif id=="classic" then
        if rested>0 then return string.format("XP: %.1f%%  R: %.1f%%",100*cur/mx,100*rested/mx) end
        return string.format("XP: %.1f%%",100*cur/mx)
    elseif id=="pct" then return XP.FmtPct(math.floor(cur/mx*1000+.5)/10)
    elseif id=="cur" then return XP.FmtNum(cur)
    elseif id=="curMax" then return XP.FmtNum(cur).." / "..XP.FmtNum(mx)
    elseif id=="curMaxRem" then return string.format("%s / %s (%s)",XP.FmtNum(cur),XP.FmtNum(mx),string.format(L("Remaining: %s"),XP.FmtNum(mx-cur)))
    elseif id=="restVal" then return string.format(L("Rested: %s"),XP.FmtNum(rested))
    elseif id=="restPct" then return string.format(L("Rested: %s"),XP.FmtPct(math.floor(rested/mx*1000+.5)/10))
    elseif id=="questVal" then return string.format(L("Completed: %s"),XP.FmtNum(xpQuest.all))
    elseif id=="questPct" then return string.format(L("Completed: %s"),XP.FmtPct(math.floor(xpQuest.all/mx*1000+.5)/10))
    elseif id=="level" then return string.format("%s %d",LEVEL or "Level",level)
    elseif id=="xpPerHour" then return string.format(L("%s XP/Hour"),XP.FmtNum(XP.Rate(now)))
    elseif id=="levelingIn" then
        local rate=XP.Rate(now)
        return string.format(L("Leveling in: %s (%s XP/Hour)"),rate>0 and XP.FmtDur((mx-cur)/rate*3600) or "--",XP.FmtNum(rate))
    elseif id=="timeLevel" then
        return string.format(L("Time this level: %s"),xpLevel.base and XP.FmtDur(xpLevel.base+now-xpLevel.stamp) or "--")
    elseif id=="timeSession" then
        return string.format(L("Time this session: %s"),xpSession.start and XP.FmtDur(now-xpSession.start) or "--")
    end
    return ""
end
local function XPOverlayBar(f)
    local b=CreateFrame("StatusBar",nil,f); b:SetPoint("TOPLEFT",f,"TOPLEFT",1,-1); b:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-1,1)
    b:SetStatusBarTexture(dataTexture); b:SetMinMaxValues(0,1); b:SetValue(0); b:Hide(); return b
end
-- One tick: a solid line, or a run of dashes/dots across the bar's height.
local function XPTick(f,index,x,innerH,style)
    local pool=f.xpTicks[index]
    if not pool then pool={}; f.xpTicks[index]=pool end
    local seg,gap=innerH,0
    if style=="dashed" then seg,gap=2,2 elseif style=="dotted" then seg,gap=1,1 end
    local count=gap>0 and math.max(1,math.floor((innerH+gap)/(seg+gap))) or 1
    local start=gap>0 and math.floor((innerH-(count*(seg+gap)-gap))/2) or 0
    for i=1,math.max(count,#pool) do
        local t=pool[i]
        if i<=count then
            if not t then t=f.xpTickHost:CreateTexture(nil,"OVERLAY"); t:SetTexture(flat); pool[i]=t end
            t:ClearAllPoints(); t:SetWidth(1); t:SetHeight(seg)
            t:SetPoint("TOPLEFT",f,"TOPLEFT",x,-(1+start+(i-1)*(seg+gap))); t:SetVertexColor(0,0,0,.6); t:Show()
        elseif t then t:Hide() end
    end
    pool.count,pool.at=count,0
end
-- Layout pass (size and style changes): background, overlay bars, ticks, text hosts.
function XP.Layout(f,p)
    if not (f and p) then return end
    local br,bg,bb=XPColor(p.xpBgColor,.06,.06,.06)
    f:SetBackdropColor(br,bg,bb,Clamp(p.xpBgOpacity or 95,0,100)/100)
    local base=f.rested:GetFrameLevel()
    if p.xpQuestOverlay and not f.questOpen then f.questOpen=XPOverlayBar(f); f.questDone=XPOverlayBar(f) end
    if f.questOpen then
        f.questOpen:SetFrameLevel(base+1); f.questDone:SetFrameLevel(base+2)
        if not p.xpQuestOverlay then f.questOpen:Hide(); f.questDone:Hide() end
    end
    f.fill:SetFrameLevel(base+3)
    if not f.xpTextHost then
        f.xpTextHost=CreateFrame("Frame",nil,f); f.xpTextHost:SetAllPoints(f); f.text:SetParent(f.xpTextHost)
        f.xpTexts={Center=f.text}
    end
    f.xpTextHost:SetFrameLevel(base+5)
    for _,pos in ipairs(XP.POSITIONS) do
        local value=XP.TextValue(p,pos); local fs=f.xpTexts[pos]
        if value~="none" and not fs then fs=f.xpTextHost:CreateFontString(nil,"OVERLAY"); f.xpTexts[pos]=fs end
        if fs then
            local place=XP_PLACE[pos]
            fs:ClearAllPoints(); fs:SetPoint(place[1],f,place[2],place[3],place[4]); fs:SetJustifyH(place[5])
            if value=="none" then fs:SetText(""); fs:Hide() else fs:Show() end
            fs._xpLast=nil
        end
    end
    local w,h=f:GetWidth()-2,f:GetHeight()-2
    if p.xpDividers then
        if not f.xpTickHost then f.xpTickHost=CreateFrame("Frame",nil,f); f.xpTickHost:SetAllPoints(f); f.xpTicks={}; f.xpTickLabels={} end
        f.xpTickHost:SetFrameLevel(base+4); f.xpTickHost:Show()
        local style=XP.TICK_VALUES[p.xpTickStyle] and p.xpTickStyle or "dashed"
        for k=1,19 do
            local major=k%2==0
            local x=1+math.floor(w*k/20+.5)
            if major or style~="none" then XPTick(f,k,x,h,major and "solid" or style)
            elseif f.xpTicks[k] then for _,t in ipairs(f.xpTicks[k]) do t:Hide() end; f.xpTicks[k].count=0 end
            if f.xpTicks[k] then f.xpTicks[k].frac=k/20 end
            if major then
                local label=f.xpTickLabels[k]
                if p.xpDividerText then
                    if not label then label=f.xpTickHost:CreateFontString(nil,"OVERLAY"); f.xpTickLabels[k]=label end
                    label:SetFont(E.GetFontPath("actionBars"),math.max(7,Clamp(ns.GetSettings().fontSize,8,20)-3),"OUTLINE")
                    label:ClearAllPoints(); label:SetPoint("CENTER",f,"LEFT",x,0); label:SetText((k*5).."%"); label:Show()
                elseif label then label:Hide() end
            end
        end
    elseif f.xpTickHost then f.xpTickHost:Hide() end
    if p.xpSpark and not f.xpSpark then
        f.xpSpark=f.xpTextHost:CreateTexture(nil,"ARTWORK")
        f.xpSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark"); f.xpSpark:SetBlendMode("ADD")
    end
    if f.xpSpark then
        f.xpSpark:SetWidth(math.max(8,h)); f.xpSpark:SetHeight(h*2.2)
        if not p.xpSpark then f.xpSpark:Hide() end
    end
    f._xpLayout=true
end
-- Smart Ticks: marks the fill has passed hide, the ones ahead stay.
local function XPSmartTicks(f,p,frac)
    if not (p.xpDividers and f.xpTicks) then return end
    for k=1,19 do
        local pool=f.xpTicks[k]
        if pool and pool.count then
            local hide=p.xpSmartTicks and frac>=(pool.frac or 1)
            for i=1,pool.count do if hide then pool[i]:Hide() else pool[i]:Show() end end
        end
    end
end
local function XPSetText(fs,text)
    if fs._xpLast~=text then fs._xpLast=text; fs:SetText(text) end
end
local function XPPaintFill(f,p)
    local r,g,b,a=XPColor(p.xpColor,0,.4,1,1)
    local style=p.xpFillStyle
    if style=="HORIZONTAL" or style=="VERTICAL" then
        local er,eg,eb,ea=XPColor(p.xpGradEnd,.3,.75,1,1)
        f.fill:SetStatusBarColor(1,1,1,1)
        local tex=f.fill:GetStatusBarTexture()
        if tex and tex.SetGradientAlpha then tex:SetGradientAlpha(style,r,g,b,a,er,eg,eb,ea) end
    else f.fill:SetStatusBarColor(r,g,b,a) end
end
function XP.Update(f,p,cur,mx,rested,level,atMax)
    if not f._xpLayout then XP.Layout(f,p) end
    if not xpSession.resumed then xpSession.resumed=true; XP.Resume(p) end
    local now=GetTime()
    XP.Track(cur,mx,level)
    XPPaintFill(f,p)
    if atMax then rested=0 end
    local needQuest,needPlayed=p.xpQuestOverlay and not atMax,false
    for _,pos in ipairs(XP.POSITIONS) do
        local v=XP.TextValue(p,pos)
        if XP_QUEST_ITEMS[v] and not atMax then needQuest=true elseif v=="timeLevel" then needPlayed=true end
    end
    if needQuest and xpQuest.dirty and now-xpQuest.last>=1 then XP.ScanQuests(p) end
    if needPlayed and not xpLevel.asked and RequestTimePlayed then xpLevel.asked=true; RequestTimePlayed() end
    -- Rested After Quest XP: the rested segment starts where the quest overlay ends.
    local restFrom=cur
    if p.xpRestedAfterQuests and p.xpQuestOverlay then restFrom=cur+xpQuest.done+xpQuest.open end
    if rested>0 and p.xpShowRested~=false then
        f.rested:SetMinMaxValues(0,mx); f.rested:SetValue(math.min(mx,restFrom+rested)); f.rested:Show()
    else f.rested:SetMinMaxValues(0,1); f.rested:SetValue(0); f.rested:Hide() end
    f.rested:SetStatusBarColor(XPColor(p.xpRestedColor,.5,0,.5,.8))
    if f.questOpen and p.xpQuestOverlay and atMax then f.questDone:Hide(); f.questOpen:Hide()
    elseif f.questOpen and p.xpQuestOverlay then
        local dr,dg,db,da=XPColor(p.xpQuestDoneColor,.2,.8,.2,.6)
        local or_,og,ob,oa=XPColor(p.xpQuestColor,1,.8,0,.6)
        f.questDone:SetStatusBarColor(dr,dg,db,da); f.questOpen:SetStatusBarColor(or_,og,ob,oa)
        f.questDone:SetMinMaxValues(0,mx); f.questDone:SetValue(math.min(mx,cur+xpQuest.done))
        f.questOpen:SetMinMaxValues(0,mx); f.questOpen:SetValue(math.min(mx,cur+xpQuest.done+xpQuest.open))
        if xpQuest.done>0 then f.questDone:Show() else f.questDone:Hide() end
        if xpQuest.open>0 then f.questOpen:Show() else f.questOpen:Hide() end
    end
    local path,size=E.GetFontPath("actionBars"),Clamp(ns.GetSettings().fontSize,8,20)
    for _,pos in ipairs(XP.POSITIONS) do
        local fs=f.xpTexts and f.xpTexts[pos]; local v=XP.TextValue(p,pos)
        if fs and v~="none" then
            if pos~="Center" then fs:SetFont(path,size,"OUTLINE") end
            XPSetText(fs,XP.ItemText(v,cur,mx,rested,level,now,atMax))
        end
    end
    XPSmartTicks(f,p,cur/mx)
    if f.xpSpark then
        if p.xpSpark and cur>0 and cur<mx then
            f.xpSpark:ClearAllPoints(); f.xpSpark:SetPoint("CENTER",f,"LEFT",1+(f:GetWidth()-2)*cur/mx,0); f.xpSpark:Show()
        else f.xpSpark:Hide() end
    end
end
function XP.Tooltip(f)
    local mx=f.maximum or 1; local cur=f.current or 0
    GameTooltip:AddLine(string.format("Remaining: %s",XP.FmtNum(mx-cur)),.9,.9,.9)
    if xpQuest.all>0 then GameTooltip:AddLine(string.format("Completed quests: %s",XP.FmtNum(xpQuest.all)),.2,.8,.2) end
    local rate=XP.Rate(GetTime())
    if rate>0 then GameTooltip:AddLine(string.format("%s XP/Hour",XP.FmtNum(rate)),.9,.9,.9) end
end
function H.UpdateData()
    for _,key in ipairs({"xp","reputation"}) do
        local f=H.holders[key]
        if Enabled(key) and f and f.fill then
            -- Un-templated FontStrings need their font before the first text
            -- write in Wrath. Refresh here also applies text-size/font changes.
            f.text:SetFont(E.GetFontPath("actionBars"),Clamp(ns.GetSettings().fontSize,8,20),"OUTLINE")
            local current,maximum=0,1; local show=false
            if key=="xp" then
                current=UnitXP and UnitXP("player") or 0; maximum=math.max(1,UnitXPMax and UnitXPMax("player") or 1)
                local p=Settings(); local level=UnitLevel("player") or 1
                local atMax=level>=(MAX_PLAYER_LEVEL or 80)
                show=not atMax or p.xpShowMaxLevel==true
                if atMax then current=maximum end
                XP.Update(f,p,current,maximum,GetXPExhaustion and GetXPExhaustion() or 0,level,atMax)
            else
                local name,standing,minRep,maxRep,value
                if GetWatchedFactionInfo then name,standing,minRep,maxRep,value=GetWatchedFactionInfo() end
                f.faction=name; show=name~=nil
                if name then
                    current=math.max(0,(value or 0)-(minRep or 0)); maximum=math.max(1,(maxRep or 1)-(minRep or 0))
                    local color=FACTION_BAR_COLORS and FACTION_BAR_COLORS[standing] or {r=.047,g=.824,b=.616}
                    f.fill:SetStatusBarColor(color.r,color.g,color.b,1); f.text:SetText(name..string.format(": %.1f%%",100*current/maximum))
                else f.text:SetText("Reputation") end
                f.rested:Hide()
            end
            f.current,f.maximum=current,maximum; f.fill:SetMinMaxValues(0,maximum); f.fill:SetValue(current)
            if not ProgressInDataBars(key) and (show or E.IsUnlockModeActive and E:IsUnlockModeActive()) then f:Show() else f:Hide() end
        end
    end
end
local function AuraPosition(s,b,f,index,columns)
    if InCombatLockdown() and b.IsProtected and b:IsProtected() then H.dirty=true; return end
    local x,y=-((index-1)%columns)*36,-math.floor((index-1)/columns)*44
    local point,relative,relPoint,oldX,oldY=b:GetPoint(1)
    if b:GetNumPoints()==1 and point=="TOPRIGHT" and relative==f and relPoint=="TOPRIGHT" and oldX==x and oldY==y then return end
    Remember(s,b); b:ClearAllPoints()
    b:SetPoint("TOPRIGHT",f,"TOPRIGHT",x,y)
end
local function KeepBuffTop(f)
    if E.IsUnlockModeActive and E:IsUnlockModeActive() then return end
    local point,relative,relPoint,x,y=f:GetPoint(1)
    if not point or point:find("TOP",1,true) then return end
    -- Edit Mode can save CENTER/BOTTOM anchors. A taller holder then moves
    -- its top row upward even though individual icons use negative row Y.
    -- Pin the existing top-right corner before changing the holder height.
    local px=point:find("LEFT",1,true) and 0 or point:find("RIGHT",1,true) and 1 or .5
    local py=point:find("BOTTOM",1,true) and 0 or .5
    x=(x or 0)+(1-px)*f:GetWidth(); y=(y or 0)+(1-py)*f:GetHeight()
    f:ClearAllPoints(); f:SetPoint("TOPRIGHT",relative,relPoint,x,y)
    if relative==UIParent then ns.GetSettings().barPositions.hud_buffs={point="TOPRIGHT",relPoint=relPoint,x=x,y=y} end
end
function H.UpdateAuras()
    for _,key in ipairs({"buffs","debuffs"}) do
        local f=H.holders[key]
        if Enabled(key) and f then
            local s=State(key); local p=Settings(); local columns=Clamp(p[key.."Columns"] or p.auraColumns,1,16); local list={}
            if key=="buffs" then
                for i=1,3 do local b=_G["TempEnchant"..i]; if b and b:IsShown() then list[#list+1]=b end end
                if ConsolidatedBuffs and ConsolidatedBuffs:IsShown() then list[#list+1]=ConsolidatedBuffs end
            end
            local prefix=key=="buffs" and "BuffButton" or "DebuffButton"
            local max=key=="buffs" and (BUFF_ACTUAL_DISPLAY or BUFF_MAX_DISPLAY or 32) or (DEBUFF_MAX_DISPLAY or 16)
            for i=1,max do local b=_G[prefix..i]; if b and b:IsShown() then list[#list+1]=b end end
            for i,b in ipairs(list) do AuraPosition(s,b,f,i,columns) end
            if not InCombatLockdown() then
                if key=="buffs" then KeepBuffTop(f) end
                Size(f,columns*36-6,math.max(1,math.ceil(#list/columns))*44)
            end
            local native=key=="buffs" and _G.BuffFrame or _G.DebuffFrame
            if native and (not InCombatLockdown() or not native.IsProtected or not native:IsProtected()) then
                Remember(s,native)
                local point,relative=native:GetPoint(1)
                if native:GetNumPoints()~=1 or point~="TOPRIGHT" or relative~=f then
                    native:ClearAllPoints(); native:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0)
                end
                if not InCombatLockdown() then Size(native,f:GetWidth(),f:GetHeight()) end
            end
        end
    end
end
function H.Apply(forcePosition)
    if not ns.GetSettings() then return end
    if InCombatLockdown() then H.dirty=true; return end
    H.dirty=false
    for _,d in ipairs(definitions) do
        if not Enabled(d.key) then Restore(d.key)
        else
            local s=State(d.key)
            if d.key=="buffs" then Remember(s,_G.BuffFrame) elseif d.key=="debuffs" then Remember(s,_G.DebuffFrame) end
            local f=Holder(d); s.active=true
            if forcePosition~=false or not (E.IsUnlockModeActive and E:IsUnlockModeActive()) then Position(d,f) end
            if d.key=="micro" or d.key=="bags" then LayoutButtons(d.key,f)
            elseif d.key=="xp" or d.key=="reputation" then
                local p=Settings(); Size(f,Clamp(p[d.key.."Width"] or p.barWidth,120,1000),Clamp(p[d.key.."Height"] or p.barHeight,8,32)); DataBar(d.key,f)
                if d.key=="xp" then XP.Layout(f,p) end
                local names=d.key=="xp" and {"MainMenuExpBar","MainMenuBarMaxLevelBar","ExhaustionLevelFillBar","ExhaustionTick"} or {"ReputationWatchBar"}
                for _,name in ipairs(names) do
                    local native=_G[name]
                    if native then
                        -- ExhaustionLevelFillBar/ExhaustionTick are Texture
                        -- regions in Wrath: they have no Frame scale/scripts.
                        if native.GetObjectType and native:GetObjectType()=="Texture" then Texture(s,native,true)
                        else
                            Remember(s,native); native:SetAlpha(0); if native.EnableMouse then native:EnableMouse(false) end
                            if native.GetRegions then for _,region in ipairs({native:GetRegions()}) do
                                if region.GetObjectType and region:GetObjectType()=="Texture" then Texture(s,region,true) end
                            end end
                            if native.GetStatusBarTexture then Texture(s,native:GetStatusBarTexture(),true) end
                        end
                    end
                end
            else f:Show() end
        end
    end
    H.UpdateAuras(); H.UpdateData()
end
function H.Elements()
    local elements={}
    for i,d in ipairs(definitions) do
        local key=d.key
        elements[#elements+1]=E.MakeUnlockElement({key="EUI335_HUD_"..key,label=d.label,group=d.group,order=120+i,
            noResize=true,noAnchorTo=true,getFrame=function() return H.holders[key] end,
            getSize=function() local f=H.holders[key]; return f and f:GetWidth() or 240,f and f:GetHeight() or 32 end,
            isHidden=function() return not Enabled(key) or (key=="xp" or key=="reputation") and ProgressInDataBars(key) end,
            savePos=function(_,point,relPoint,x,y) local p=ns.GetSettings(); if p then p.barPositions["hud_"..key]={point=point,relPoint=relPoint,x=x,y=y} end end,
            loadPos=function() local p=ns.GetSettings(); return p and p.barPositions["hud_"..key] end,
            clearPos=function() local p=ns.GetSettings(); if p then p.barPositions["hud_"..key]=nil end end,
            applyPos=function() H.Apply() end})
    end
    return elements
end
function H.Enable()
    if H.events then return end
    local f=CreateFrame("Frame"); H.events=f
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","PLAYER_XP_UPDATE","PLAYER_LEVEL_UP",
        "UPDATE_EXHAUSTION","UPDATE_FACTION","UNIT_AURA","BAG_UPDATE","ADDON_LOADED",
        "QUEST_LOG_UPDATE","ZONE_CHANGED_NEW_AREA","TIME_PLAYED_MSG","PLAYER_LOGOUT"}) do f:RegisterEvent(event) end
    f:SetScript("OnEvent",function(_,event,unit,arg2)
        if event=="UNIT_AURA" and unit~="player" then return end
        if event=="QUEST_LOG_UPDATE" or event=="ZONE_CHANGED_NEW_AREA" then XP.QuestsDirty(); if event=="QUEST_LOG_UPDATE" then return end end
        if event=="TIME_PLAYED_MSG" then XP.OnPlayed(unit,arg2); return end
        if event=="PLAYER_LOGOUT" then XP.Save(); return end
        if event=="PLAYER_LEVEL_UP" then XP.OnLevelUp() end
        if event=="PLAYER_XP_UPDATE" or event=="UPDATE_EXHAUSTION" or event=="UPDATE_FACTION" then H.UpdateData()
        elseif event=="UNIT_AURA" then H.UpdateAuras()
        else H.dirty=true end
    end)
    local elapsed=0
    f:SetScript("OnUpdate",function(_,dt)
        elapsed=elapsed+dt; if elapsed<.2 then return end; elapsed=0
        if H.dirty and not InCombatLockdown() then H.Apply(false) end
        H.UpdateData()
    end)
    for _,name in ipairs({"BuffFrame_UpdateAllBuffAnchors","DebuffButton_UpdateAnchors","BuffFrame_Update",
        "UIParent_ManageFramePositions","MainMenuBar_UpdateExperienceBars","ReputationWatchBar_Update",
        "UpdateMicroButtons","MoveMicroButtons","UpdateMicroButtonsParent","MainMenuBarBackpackButton_UpdateFreeSlots"}) do
        if type(_G[name])=="function" then hooksecurefunc(name,function()
            H.dirty=true
            if name=="BuffFrame_UpdateAllBuffAnchors" or name=="DebuffButton_UpdateAnchors" then H.UpdateAuras() end
        end) end
    end
end
