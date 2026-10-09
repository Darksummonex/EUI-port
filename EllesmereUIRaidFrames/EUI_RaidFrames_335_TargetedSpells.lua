-- Retail "Targeted Spells": icons on the group member an enemy is casting at.
-- Wrath has no nameplate tokens and no spell-target API, so the victim is the
-- caster's own target (UnitGUID(token.."target")) while the cast runs. Casters
-- are only seen through tokens: the client sends UNIT_SPELLCAST_* for target,
-- focus, mouseover, bossN and arenaN; compound tokens (raidNtarget, partyNtarget,
-- targettarget, focustarget, pettarget) never fire events and are polled every
-- 0.2 s with UnitCastingInfo/UnitChannelInfo while the feature is active.
local ADDON_NAME,ns=...
local E=EllesmereUI
if not ns.addon then return end
local white="Interface\\Buttons\\WHITE8X8"
local TS={casts={},ended={},victims={},tokens={},active=false,healer=false}
ns.TargetedSpells=TS
local function RGB(r,g,b) return {r=r,g=g,b=b} end
-- Retail keys: party defaults to When Healing, raid to Never (each raid layout
-- keeps its own choice).
for kind,mode in pairs({party="whenHealing",raid="never"}) do
    local c=ns.defaults.profile[kind]
    c.tsMode=mode; c.tsPreview=true; c.tsSize=20; c.tsMax=3; c.tsPosition="right"; c.tsGrowth="left"
    c.tsOffsetX=0; c.tsOffsetY=0; c.tsSwipe=true; c.tsTimer=false; c.tsColorInterrupt=true
    c.tsInterruptibleColor=RGB(1,.3,.3); c.tsUninterruptibleColor=RGB(.6,.6,.6)
end
TS.MODE_VALUES={never="Never",whenHealing="When Healing",always="Always"}
TS.MODE_ORDER={"never","whenHealing","always"}
TS.GROWTH_VALUES={right="Right",left="Left",up="Up",down="Down"}
TS.GROWTH_ORDER={"right","left","up","down"}
local function ModeOn(c,preview)
    local mode=c and c.tsMode or "never"
    if mode=="never" or not c.enabled then return false end
    return preview or mode=="always" or (mode=="whenHealing" and TS.healer)
end
TS.ModeOn=ModeOn
-------------------------------------------------------------------------------
-- Cast tracking (one entry per caster GUID, whatever token it was seen through).
-------------------------------------------------------------------------------
local eventUnits={target=true,focus=true,mouseover=true}
for i=1,4 do eventUnits["boss"..i]=true end
for i=1,5 do eventUnits["arena"..i]=true end
local victimTokens=setmetatable({},{__index=function(t,token) local v=token.."target"; t[token]=v; return v end})
local dirty=false
local function Remove(guid,entry)
    TS.casts[guid]=nil; TS.ended[guid]=entry.start; dirty=true
end
-- Reads the caster behind token; seen dedupes tokens within one scan.
function TS.Observe(token,seen,interrupted)
    if not UnitExists(token) then return end
    local guid=UnitGUID(token); if not guid or (seen and seen[guid]) then return end
    if seen then seen[guid]=true end
    local entry=TS.casts[guid]
    if not UnitCanAttack("player",token) then if entry then Remove(guid,entry) end; return end
    local name,_,_,icon,start,finish,_,castID,notInterruptible=UnitCastingInfo(token)
    local channel=false
    if not name then
        name,_,_,icon,start,finish,_,notInterruptible=UnitChannelInfo(token); channel=true; castID=nil
    end
    if not name or not start or not finish then if entry then Remove(guid,entry) end; return end
    if interrupted and entry and entry.start==start then Remove(guid,entry); return end
    if TS.ended[guid]==start then return end
    TS.ended[guid]=nil
    local victim=UnitGUID(victimTokens[token])
    if not entry then entry={guid=guid}; TS.casts[guid]=entry; dirty=true end
    if entry.start~=start or entry.finish~=finish or entry.victim~=victim or entry.name~=name then dirty=true end
    entry.name,entry.icon,entry.start,entry.finish,entry.channel=name,icon,start,finish,channel
    entry.castID,entry.notInterruptible,entry.victim,entry.token=castID,notInterruptible and true or false,victim,token
    return entry
end
local seen={}
function TS.Scan()
    for k in pairs(seen) do seen[k]=nil end
    for _,token in ipairs(TS.tokens) do TS.Observe(token,seen) end
    local nowMs=GetTime()*1000
    -- Casters out of reach of every token stay until their cast would have ended.
    for guid,entry in pairs(TS.casts) do
        if not seen[guid] and nowMs>entry.finish+250 then Remove(guid,entry) end
    end
    for guid,start in pairs(TS.ended) do if start<nowMs-60000 then TS.ended[guid]=nil end end
    TS.Flush(true)
end
local function ByFinish(a,b) return a.finish<b.finish end
function TS.Flush(timers)
    if dirty then
        dirty=false
        local victims={}
        for _,entry in pairs(TS.casts) do
            local v=entry.victim
            if v then local list=victims[v]; if not list then list={}; victims[v]=list end; list[#list+1]=entry end
        end
        for _,list in pairs(victims) do table.sort(list,ByFinish) end
        TS.victims=victims; TS.PaintAll()
    elseif timers and TS.anyShown then TS.PaintAll() end
end
-------------------------------------------------------------------------------
-- Icons
-------------------------------------------------------------------------------
local function NewIcon(b)
    local f=CreateFrame("Frame",nil,b.textHost); f:EnableMouse(false); f:Hide()
    f:SetFrameLevel(b.textHost:GetFrameLevel()+8)
    f:SetBackdrop({edgeFile=white,edgeSize=1})
    f.icon=f:CreateTexture(nil,"ARTWORK"); f.icon:SetPoint("TOPLEFT",f,"TOPLEFT",1,-1); f.icon:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-1,1); f.icon:SetTexCoord(.08,.92,.08,.92)
    f.cooldown=CreateFrame("Cooldown",nil,f,"CooldownFrameTemplate"); f.cooldown:SetAllPoints(f.icon)
    f.time=f:CreateFontString(nil,"OVERLAY"); f.time:SetPoint("CENTER",f,"CENTER",0,0)
    return f
end
local steps={right={1,0},left={-1,0},up={0,1},down={0,-1}}
local function Layout(b,c,count)
    local size=math.max(10,math.min(40,tonumber(c.tsSize) or 20))
    local position=c.tsPosition or "right"; local growth=steps[c.tsGrowth] and c.tsGrowth or "left"
    local key=size..position..growth..count..tostring(c.tsOffsetX)..tostring(c.tsOffsetY)
    if b._tsLayout==key then return end; b._tsLayout=key
    local dx,dy=steps[growth][1]*(size+2),steps[growth][2]*(size+2)
    -- A row centred on its anchor when the growth runs along that edge's middle.
    local horizontal=dx~=0
    local centred=(horizontal and (position=="top" or position=="center" or position=="bottom")) or (not horizontal and (position=="left" or position=="center" or position=="right"))
    local ox,oy=tonumber(c.tsOffsetX) or 0,tonumber(c.tsOffsetY) or 0
    if centred then ox,oy=ox-dx*(count-1)/2,oy-dy*(count-1)/2 end
    for i=1,count do
        local f=b.tsIcons[i]
        ns.Place(f,b,position,size,ox+dx*(i-1),oy+dy*(i-1))
        ns.Font(f.time,math.max(8,math.floor(size*.45)))
    end
end
local function Timer(f,finish)
    local remaining=(finish-GetTime()*1000)/1000
    local text=remaining<=0 and "" or remaining<10 and string.format("%.1f",remaining) or tostring(math.ceil(remaining))
    if f.time:GetText()~=text then f.time:SetText(text) end
end
local PREVIEW={{icon="Interface\\Icons\\Spell_Shadow_ShadowBolt",duration=3,notInterruptible=false},{icon="Interface\\Icons\\Spell_Fire_Fireball02",duration=2.5,notInterruptible=true}}
local function PreviewList(index)
    if index%4~=2 then return nil end
    local nowMs=GetTime()*1000; local list={}
    for i,p in ipairs(PREVIEW) do
        if i==1 or index%8==2 then
            local d=p.duration*1000; local start=math.floor(nowMs/d)*d
            list[#list+1]={icon=p.icon,start=start,finish=start+d,notInterruptible=p.notInterruptible}
        end
    end
    return list
end
local function Hide(b)
    if not b.tsIcons then return end
    for _,f in ipairs(b.tsIcons) do f:Hide() end
    b._tsCount=0
end
function TS.PaintButton(b)
    if not b.textHost then return end
    local c=ns.GetSettings(b._euiKind)
    local list
    if b._euiPreview then
        if c and c.tsPreview~=false and ModeOn(c,true) then list=PreviewList(b._euiPreview) end
    elseif TS.active and b._euiGUID and c and ModeOn(c) then
        list=TS.victims[b._euiGUID]
    end
    local max=math.max(1,math.min(5,math.floor(tonumber(c and c.tsMax) or 3)))
    local count=list and math.min(#list,max) or 0
    if count==0 then if (b._tsCount or 0)>0 then Hide(b) end; return end
    b.tsIcons=b.tsIcons or {}
    for i=1,count do if not b.tsIcons[i] then b.tsIcons[i]=NewIcon(b); b._tsLayout=nil end end
    Layout(b,c,count)
    for i=1,count do
        local entry,f=list[i],b.tsIcons[i]
        f.icon:SetTexture(entry.icon)
        local col=c.tsColorInterrupt~=false and (entry.notInterruptible and (c.tsUninterruptibleColor or RGB(.6,.6,.6)) or (c.tsInterruptibleColor or RGB(1,.3,.3))) or RGB(0,0,0)
        f:SetBackdropBorderColor(col.r,col.g,col.b,1)
        if c.tsSwipe~=false then
            if f._start~=entry.start or f._finish~=entry.finish or not f.cooldown:IsShown() then
                f.cooldown:SetCooldown(entry.start/1000,(entry.finish-entry.start)/1000); f.cooldown:Show()
            end
        else f.cooldown:Hide() end
        f._start,f._finish=entry.start,entry.finish
        if c.tsTimer then Timer(f,entry.finish) elseif f.time:GetText()~="" then f.time:SetText("") end
        f:Show()
    end
    for i=count+1,#b.tsIcons do b.tsIcons[i]:Hide() end
    b._tsCount=count
    if not b._euiPreview then TS.anyShown=true end
end
function TS.PaintAll()
    TS.anyShown=false
    for _,b in ipairs(ns.buttons) do
        if b:IsShown() then TS.PaintButton(b) elseif (b._tsCount or 0)>0 then Hide(b) end
    end
end
-------------------------------------------------------------------------------
-- Activation: events and the scan run only while a shown group wants icons.
-------------------------------------------------------------------------------
local driver=CreateFrame("Frame"); TS.driver=driver
local SPELL_EVENTS={"UNIT_SPELLCAST_START","UNIT_SPELLCAST_STOP","UNIT_SPELLCAST_FAILED","UNIT_SPELLCAST_INTERRUPTED","UNIT_SPELLCAST_DELAYED",
    "UNIT_SPELLCAST_CHANNEL_START","UNIT_SPELLCAST_CHANNEL_UPDATE","UNIT_SPELLCAST_CHANNEL_STOP","UNIT_TARGET","PLAYER_TARGET_CHANGED","PLAYER_FOCUS_CHANGED","UPDATE_MOUSEOVER_UNIT"}
local STATE_EVENTS={"PLAYER_ENTERING_WORLD","RAID_ROSTER_UPDATE","PARTY_MEMBERS_CHANGED","PLAYER_TALENT_UPDATE","CHARACTER_POINTS_CHANGED","ACTIVE_TALENT_GROUP_CHANGED"}
local function LiveKind()
    if GetNumRaidMembers()>0 then return "raid" end
    local party=ns.GetSettings("party")
    if GetNumPartyMembers()>0 or (party and party.showSolo and party.showPlayer) then return "party" end
end
local function BuildTokens(kind)
    local tokens={"target","focus","mouseover","targettarget","focustarget","pettarget","boss1","boss2","boss3","boss4"}
    if kind=="raid" then for i=1,GetNumRaidMembers() do tokens[#tokens+1]="raid"..i.."target" end
    else for i=1,GetNumPartyMembers() do tokens[#tokens+1]="party"..i.."target" end end
    return tokens
end
local elapsed=0
local function OnUpdate(_,dt)
    elapsed=elapsed+dt; if elapsed<.2 then return end; elapsed=0
    TS.Scan()
end
function TS.Refresh()
    local p=ns.GetSettings()
    TS.healer=ns.IsHealerSpec and ns.IsHealerSpec() and true or false
    local kind=p and p.enabled and LiveKind()
    local active=kind and ModeOn(ns.GetSettings(kind)) and true or false
    if active then TS.tokens=BuildTokens(kind) end
    if active~=TS.active then
        TS.active=active
        for _,event in ipairs(SPELL_EVENTS) do
            if active then pcall(driver.RegisterEvent,driver,event) else driver:UnregisterEvent(event) end
        end
        if active then elapsed=0; driver:SetScript("OnUpdate",OnUpdate)
        else
            driver:SetScript("OnUpdate",nil); TS.tokens={}
            for guid in pairs(TS.casts) do TS.casts[guid]=nil end
            for guid in pairs(TS.ended) do TS.ended[guid]=nil end
            TS.victims={}; dirty=false
        end
    end
    TS.PaintAll()
end
local function ObserveUnit(unit,interrupted)
    TS.Observe(unit,nil,interrupted); TS.Flush()
end
driver:SetScript("OnEvent",function(_,event,unit)
    if not TS.active then if event=="PLAYER_ENTERING_WORLD" or event=="RAID_ROSTER_UPDATE" or event=="PARTY_MEMBERS_CHANGED" or event:find("TALENT",1,true) or event=="CHARACTER_POINTS_CHANGED" then TS.Refresh() end; return end
    if event=="PLAYER_TARGET_CHANGED" then ObserveUnit("target")
    elseif event=="PLAYER_FOCUS_CHANGED" then ObserveUnit("focus")
    elseif event=="UPDATE_MOUSEOVER_UNIT" then ObserveUnit("mouseover")
    elseif event=="UNIT_TARGET" then
        -- A member's new target may be a caster; an enemy's new target is its victim.
        if unit=="player" then ObserveUnit("target")
        elseif unit and (unit:match("^raid%d+$") or unit:match("^party%d+$")) then ObserveUnit(victimTokens[unit])
        elseif unit and eventUnits[unit] then ObserveUnit(unit) end
    elseif event:find("UNIT_SPELLCAST_",1,true)==1 then
        if unit and eventUnits[unit] then ObserveUnit(unit,event=="UNIT_SPELLCAST_INTERRUPTED") end
    else TS.Refresh() end
end)
for _,event in ipairs(STATE_EVENTS) do pcall(driver.RegisterEvent,driver,event) end
-------------------------------------------------------------------------------
-- Hooks into the frame runtime (it calls these through ns).
-------------------------------------------------------------------------------
local apply,layoutButton,updateFrame=ns.Apply,ns.LayoutButton,ns.UpdateFrame
function ns.Apply(...) apply(...); TS.Refresh() end
ns.ReloadFrames,ns.ReloadPartyFrames=ns.Apply,ns.Apply
function ns.LayoutButton(b,...) layoutButton(b,...); b._tsLayout=nil end
function ns.UpdateFrame(b,...)
    updateFrame(b,...)
    if b._euiPreview or (b._tsCount or 0)>0 or (TS.active and b._euiGUID and TS.victims[b._euiGUID]) then TS.PaintButton(b) end
end
