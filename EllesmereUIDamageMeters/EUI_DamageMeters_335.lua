-- Independent Wrath collector. No Details globals, libraries or saved data.
local ADDON,ns=...
local E=EllesmereUI
if not E or not E.Lite then return end
E._ModuleNS[ADDON]=ns
ns.IsWrath=true
local addon=E.Lite.NewAddon(ADDON)
ns.addon,ns.EDM=addon,addon
ns.roster,ns.pets,ns.windows,ns.registered={},{},{},{}
ns.metrics={
 {key="damage",label="Damage Done"},{key="dps",label="DPS",base="damage",rate=true},
 {key="healing",label="Healing Done"},{key="hps",label="HPS",base="healing",rate=true},
 {key="overheal",label="Overhealing"},{key="taken",label="Damage Taken"},
 {key="enemyTaken",label="Enemy Damage Taken",enemy=true},{key="friendlyFire",label="Friendly Fire / Self Damage"},
 {key="healingReceived",label="Healing Received"},{key="blocked",label="Damage Blocked"},{key="resisted",label="Damage Resisted"},
 {key="misses",label="Attacks Missed"},{key="avoided",label="Attacks Avoided"},
 {key="absorbed",label="Absorbs Received"},{key="interrupts",label="Interrupts"},
 {key="dispels",label="Dispels"},{key="deaths",label="Deaths"},
 {key="resources",label="Resources Gained"},{key="casts",label="Spell Casts"},
 {key="resurrections",label="Resurrections"},{key="ccbreaks",label="Crowd Control Breaks"},
 {key="buffUptime",label="Buff Uptime"},{key="debuffUptime",label="Debuff Uptime"},
 {key="threat",label="Threat (Current Target)"},
}
ns.metricMap={}; for _,m in ipairs(ns.metrics) do ns.metricMap[m.key]=m end
-- Appearance keys added after the first Wrath release; Apply fills them into
-- every saved window, preserving explicit false/zero values.
ns.windowExtras={
    borderSize=1,borderUseAccent=true,borderColor={r=.1,g=.8,b=.7},bgColor={r=.025,g=.035,b=.045},alwaysShowPlayer=false,
    headerHeight=22,headerColor={r=.025,g=.035,b=.045},headerBorderSize=0,headerBorderColor={r=0,g=0,b=0},
    titleFontSize=10,titleColor={r=1,g=1,b=1},
    barTexture="none",barColorMode="class",barColor={r=.97,g=.55,b=.75},barBgColor={r=.1,g=.1,b=.1,a=0},
    barSpacing=1,iconStyle="spec",barBorderSize=0,barBorderColor={r=0,g=0,b=0},
    numberFormat="short",hideRank=false,valueFontSize=11,hoverBreakdown=true,spellTooltips=false,
    bookmarks={"damage","healing","interrupts","deaths","taken"},
    hideInDungeon=false,hideInRaid=false,hideInPvP=false,hideOutOfInstance=false,
    hideTimer=false,autoSwapInstance=false,syncSegments=false,
}
ns.defaults={profile={enabled=true,historyLimit=15,saveHistory=true,mergePets=true,groupOnly=true,
    autoCurrent=true,endDelay=3,refreshRate=.3,windows={
    {name="Damage",enabled=true,metric="damage",segment="current",width=310,rows=8,rowHeight=20,
      fontSize=11,fontOutline="OUTLINE",alpha=.92,barAlpha=1,chromeAlpha=.85,showSpecIcons=true,scale=1,showRate=true,showPercent=true,locked=false,visibility="always",
      savedPos={point="BOTTOMRIGHT",relPoint="BOTTOMRIGHT",x=-10,y=180}},
    {name="Healing",enabled=true,metric="healing",segment="current",width=310,rows=8,rowHeight=20,
      fontSize=11,fontOutline="OUTLINE",alpha=.92,barAlpha=1,chromeAlpha=.85,showSpecIcons=true,scale=1,showRate=true,showPercent=true,locked=false,visibility="always",
      savedPos={point="BOTTOMRIGHT",relPoint="BOTTOMRIGHT",x=-325,y=180}},
}}}
function ns.Copy(t) if type(t)~="table" then return t end; local n={}; for k,v in pairs(t) do n[k]=ns.Copy(v) end; return n end
function ns.Clamp(v,a,b) return math.max(a,math.min(b,tonumber(v) or a)) end
function ns.Profile() return addon.db and addon.db.profile end
function ns.Size(f,w,h) f:SetWidth(w); f:SetHeight(h) end
function ns.NewSegment(id,label)
    return {id=id,label=label or "Combat",duration=0,actors={},totals={},deaths={},timestamp=time()}
end
function ns.Duration(s)
    if not s then return 1 end
    return math.max(.1,s.duration+(s==ns.current and math.max(0,(ns.endedAt or GetTime())-ns.started) or 0))
end
function ns.Actor(s,guid,name,flags)
    if not guid or guid=="" then guid="name:"..(name or "Environment") end
    local a=s.actors[guid]
    if not a then
        local r=ns.roster[guid]
        local spec=ns.specs and ns.specs[guid]
        a={guid=guid,name=name or (r and r.name) or "Unknown",class=r and r.class,
           specIcon=spec and spec.icon,specName=spec and spec.name,
           group=not not r or flags and bit.band(flags,7)~=0 or false,flags=flags,values={},spells={},targets={},logs={}}
        s.actors[guid]=a
    elseif ns.roster[guid] then a.group=true; a.class=ns.roster[guid].class or a.class end
    return a
end
function ns.Owner(guid,name,flags)
    local pet=ns.Profile().mergePets and ns.pets[guid]
    if pet then return pet.guid,pet.name,pet.flags end
    return guid,name,flags
end
function ns.Friendly(guid,flags)
    if ns.roster[guid] or ns.pets[guid] then return true end
    return flags and bit.band(flags,7)~=0 or false
end
function ns.Touch(a,key,amount,id,spellName,targetGUID,targetName,critical,school)
    amount=math.max(0,tonumber(amount) or 0); if amount==0 then return end
    a.values[key]=(a.values[key] or 0)+amount
    local spells=a.spells[key]; if not spells then spells={}; a.spells[key]=spells end
    id=id or 0; local sp=spells[id]
    if not sp then sp={id=id,name=spellName or "Melee",total=0,hits=0,crit=0,school=school,min=amount,max=amount}; spells[id]=sp end
    sp.total=sp.total+amount; sp.hits=sp.hits+1; sp.crit=sp.crit+(critical and 1 or 0)
    sp.min=math.min(sp.min,amount); sp.max=math.max(sp.max,amount)
    local targets=a.targets[key]; if not targets then targets={}; a.targets[key]=targets end
    local targetKey=targetGUID and targetGUID~="" and targetGUID or (targetName or "Unknown")
    local target=targets[targetKey]
    if not target then target={guid=targetKey,name=targetName or "Unknown",total=0}; targets[targetKey]=target end
    target.total=target.total+amount
end
function ns.Add(key,amount,guid,name,flags,id,spellName,targetGUID,targetName,critical,school)
    if not ns.current or (tonumber(amount) or 0)<=0 then return end
    guid,name,flags=ns.Owner(guid,name,flags)
    ns.Touch(ns.Actor(ns.current,guid,name,flags),key,amount,id,spellName,targetGUID,targetName,critical,school)
    ns.current.totals[key]=(ns.current.totals[key] or 0)+math.max(0,tonumber(amount) or 0)
end
local function MergeSegment(dst,src)
    dst.duration=dst.duration+src.duration
    for key,value in pairs(src.totals) do dst.totals[key]=(dst.totals[key] or 0)+value end
    for guid,a in pairs(src.actors) do
        local d=ns.Actor(dst,guid,a.name,a.flags); d.class=a.class or d.class; d.group=d.group or a.group
        d.specIcon=a.specIcon or d.specIcon; d.specName=a.specName or d.specName
        for key,value in pairs(a.values) do d.values[key]=(d.values[key] or 0)+value end
        for key,spells in pairs(a.spells) do
            d.spells[key]=d.spells[key] or {}
            for id,sp in pairs(spells) do
                local t=d.spells[key][id]
                if not t then d.spells[key][id]=ns.Copy(sp)
                else t.total=t.total+sp.total; t.hits=t.hits+sp.hits; t.crit=t.crit+sp.crit; t.min=math.min(t.min,sp.min); t.max=math.max(t.max,sp.max) end
            end
        end
        for key,targets in pairs(a.targets) do
            d.targets[key]=d.targets[key] or {}
            for id,t in pairs(targets) do
                if not d.targets[key][id] then d.targets[key][id]=ns.Copy(t)
                else d.targets[key][id].total=d.targets[key][id].total+t.total end
            end
        end
    end
    for _,death in ipairs(src.deaths) do dst.deaths[#dst.deaths+1]=ns.Copy(death) end
    while #dst.deaths>100 do table.remove(dst.deaths,1) end
end
ns.MergeSegment=MergeSegment
function ns.Start(label)
    if ns.current or not ns.Profile() or not ns.Profile().enabled then return end
    ns.history.nextID=ns.history.nextID+1
    ns.current=ns.NewSegment(ns.history.nextID,label); ns.started=GetTime(); ns.lastActivity=ns.started; ns.endedAt=nil
    ns.activeAuras={}
    if ns.SeedAuras then ns.SeedAuras() end
    for _,w in ipairs(ns.Profile().windows) do
        local auto=w.autoCurrentOnCombat; if auto==nil then auto=ns.Profile().autoCurrent end
        if auto and w.metric~="threat" then w.segment="current" end
    end
end
function ns.Finish()
    if not ns.current then return end
    if ns.FlushAuras then ns.FlushAuras(ns.endedAt or GetTime(),true) end
    local s=ns.current; s.duration=math.max(.1,(ns.endedAt or GetTime())-ns.started); ns.current=nil; ns.endedAt=nil
    if next(s.totals) then
        MergeSegment(ns.history.overall,s); table.insert(ns.history.segments,1,s)
        while #ns.history.segments>ns.Clamp(ns.Profile().historyLimit,1,30) do table.remove(ns.history.segments) end
    end
    ns.activeAuras={}; if ns.Refresh then ns.Refresh() end
end
function ns.Segment(key)
    if key=="overall" then
        if ns.current then local s=ns.Copy(ns.history.overall); local current=ns.Copy(ns.current); current.duration=ns.Duration(ns.current); MergeSegment(s,current); return s end
        return ns.history.overall
    end
    if key=="current" then return ns.current or ns.history.segments[1] end
    for _,s in ipairs(ns.history.segments) do if s.id==tonumber(key) then return s end end
end
function ns.Reset()
    if InCombatLockdown() or ns.current then return false end
    ns.history={version=1,nextID=0,segments={},overall=ns.NewSegment(0,"Overall")}
    EllesmereUIDamageMetersHistory=ns.history
    for _,w in ipairs(ns.Profile().windows) do w.segment="current" end
    for _,w in pairs(ns.windows) do w.focusGUID=nil; w.offset=0 end
    if ns.HideBreakdownTooltip then ns.HideBreakdownTooltip() end
    if ns.Refresh then ns.Refresh() end; return true
end
function ns.RefreshRoster()
    local roster,units={},{}
    local function Add(unit,owner)
        local guid=UnitGUID(unit); if not guid then return end
        local name=UnitName(unit); local _,class=UnitClass(unit)
        if owner then local r=roster[UnitGUID(owner)]; if r then ns.pets[guid]={guid=r.guid,name=r.name}; roster[guid]={guid=guid,name=name,class=r.class,unit=unit,pet=true} end
        else roster[guid]={guid=guid,name=name,class=class,unit=unit}; units[#units+1]=unit end
    end
    Add("player"); Add("pet","player")
    if GetNumRaidMembers()>0 then
        for i=1,GetNumRaidMembers() do Add("raid"..i) end
        for i=1,GetNumRaidMembers() do Add("raidpet"..i,"raid"..i) end
    else for i=1,GetNumPartyMembers() do Add("party"..i); Add("partypet"..i,"party"..i) end end
    ns.roster,ns.units=roster,units
    if ns.RefreshPlayerSpec then ns.RefreshPlayerSpec() end
end
function ns.GroupInCombat()
    for _,unit in ipairs(ns.units or {}) do if UnitAffectingCombat(unit) then return true end end
    return false
end
function ns.ThreatRows()
    local rows={}; if not UnitExists("target") or not UnitCanAttack("player","target") then return rows end
    for _,unit in ipairs(ns.units or {}) do
        local tank,status,scaled,raw,value=UnitDetailedThreatSituation(unit,"target")
        if value and value>0 then local guid=UnitGUID(unit); local r=ns.roster[guid]
            rows[#rows+1]={guid=guid,name=r and r.name or UnitName(unit),class=r and r.class,
                value=value,percent=scaled or 0,tank=tank}
        end
    end
    table.sort(rows,function(a,b) if a.value==b.value then return a.name<b.name end; return a.value>b.value end)
    return rows
end
function ns.Rows(segmentKey,metric)
    if metric=="threat" then return ns.ThreatRows(),nil end
    local s=segmentKey=="overall" and ns.history.overall or ns.Segment(segmentKey); local rows={}; if not s then return rows end
    local m=ns.metricMap[metric] or ns.metricMap.damage; local base=m.base or m.key; local duration=ns.Duration(s)
    local live=segmentKey=="overall" and ns.current; if live then duration=math.max(.1,s.duration+ns.Duration(live)) end
    local total,seen=0,{}
    local function Append(guid,a,extra)
        local amount=(a.values[base] or 0)+(extra and extra.values[base] or 0)
        if (m.enemy or not ns.Profile().groupOnly or a.group or extra and extra.group) and amount>0 then
            total=total+amount
            rows[#rows+1]={guid=guid,name=a.name,class=a.class or extra and extra.class,actor=a,extraActor=extra,
                specIcon=extra and extra.specIcon or a.specIcon,specName=extra and extra.specName or a.specName,
                amount=amount,value=m.rate and amount/duration or amount,rate=amount/duration}
        end
    end
    for guid,a in pairs(s.actors) do seen[guid]=true; Append(guid,a,live and live.actors[guid]) end
    if live then
        for guid,a in pairs(live.actors) do if not seen[guid] then Append(guid,a) end end
        -- Only summary rows are combined on the live refresh path. Spell and
        -- target tables are merged lazily when the user opens a breakdown.
        local deaths={}; for _,d in ipairs(s.deaths) do deaths[#deaths+1]=d end
        for _,d in ipairs(live.deaths) do deaths[#deaths+1]=d end
        s={id=0,label="Overall",duration=duration,deaths=deaths}
    end
    for _,r in ipairs(rows) do r.percent=total>0 and r.amount/total*100 or 0 end
    table.sort(rows,function(a,b) if a.value==b.value then return a.name<b.name end; return a.value>b.value end)
    return rows,s
end
function ns.Breakdown(row,metric,mode)
    local m=ns.metricMap[metric] or ns.metricMap.damage; local key=m.base or m.key; local rows,merged={},{}
    local function Add(actor)
        for id,r in pairs(actor and (mode=="targets" and actor.targets[key] or actor.spells[key]) or {}) do
            if not merged[id] then merged[id]=ns.Copy(r)
            else local t=merged[id]; t.total=t.total+r.total
                if r.hits then t.hits=t.hits+r.hits; t.crit=t.crit+r.crit; t.min=math.min(t.min,r.min); t.max=math.max(t.max,r.max) end
            end
        end
    end
    Add(row.actor); Add(row.extraActor); for _,r in pairs(merged) do rows[#rows+1]=r end
    table.sort(rows,function(a,b) if a.total==b.total then return a.name<b.name end; return a.total>b.total end)
    return rows
end
function ns.TrimHistory()
    while #ns.history.segments>ns.Clamp(ns.Profile().historyLimit,1,30) do table.remove(ns.history.segments) end
end
function addon:OnInitialize()
    addon.db=E.Lite.NewDB("EllesmereUIDamageMetersDB",ns.defaults); ns.db=addon.db; _EDM_DB=addon.db
    local h=EllesmereUIDamageMetersHistory
    if type(h)~="table" or h.version~=1 or type(h.segments)~="table" or type(h.overall)~="table" then
        h={version=1,nextID=0,segments={},overall=ns.NewSegment(0,"Overall")}
    end
    ns.history=h; EllesmereUIDamageMetersHistory=h; ns.RefreshRoster(); ns.TrimHistory()
end
function addon:OnEnable()
    ns.events=CreateFrame("Frame")
    if ns.InitializeSpecs then ns.InitializeSpecs() end
    for _,event in ipairs({"PARTY_MEMBERS_CHANGED","RAID_ROSTER_UPDATE","UNIT_PET","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","PLAYER_LOGOUT","PLAYER_TARGET_CHANGED","ZONE_CHANGED_NEW_AREA","PLAYER_ENTERING_WORLD","PLAYER_TALENT_UPDATE","ACTIVE_TALENT_GROUP_CHANGED","INSPECT_TALENT_READY"}) do ns.events:RegisterEvent(event) end
    ns.events:SetScript("OnEvent",function(_,event,...)
        if event=="COMBAT_LOG_EVENT_UNFILTERED" then ns.Parse(...)
        elseif event=="INSPECT_TALENT_READY" then if ns.InspectSpecReady then ns.InspectSpecReady(...) end
        elseif event=="PLAYER_TALENT_UPDATE" or event=="ACTIVE_TALENT_GROUP_CHANGED" then if ns.RefreshPlayerSpec then ns.RefreshPlayerSpec() end
        elseif event=="PLAYER_LOGOUT" then
            ns.Finish(); if not ns.Profile().saveHistory then EllesmereUIDamageMetersHistory=nil end
        elseif event=="PLAYER_REGEN_DISABLED" then ns.Start()
        elseif event=="PLAYER_REGEN_ENABLED" then if ns.current and not ns.GroupInCombat() then ns.endedAt=GetTime() end
        elseif event=="ZONE_CHANGED_NEW_AREA" or event=="PLAYER_ENTERING_WORLD" then
            if event=="ZONE_CHANGED_NEW_AREA" and not ns.GroupInCombat() then ns.Finish() end
            if ns.InstanceChanged then ns.InstanceChanged() end; ns.RefreshRoster()
        elseif event~="PLAYER_REGEN_ENABLED" and event~="PLAYER_TARGET_CHANGED" then ns.RefreshRoster() end
        if ns.Refresh then ns.Refresh() end
    end)
    local elapsed=0
    ns.events:SetScript("OnUpdate",function(_,dt)
        elapsed=elapsed+dt; if elapsed<ns.Clamp(ns.Profile().refreshRate or .3,.1,2) then return end; elapsed=0
        if ns.UpdateSpecs then ns.UpdateSpecs() end
        if ns.current then
            if ns.GroupInCombat() then ns.lastActivity=GetTime(); ns.endedAt=nil
            else ns.endedAt=ns.endedAt or GetTime()
                if GetTime()-ns.endedAt>=ns.Clamp(ns.Profile().endDelay,1,10) then ns.Finish() end
            end
            if ns.FlushAuras and ns.current then ns.FlushAuras(ns.endedAt or GetTime()) end
        end
        if ns.Refresh then ns.Refresh() end
    end)
    if E.RegisterUnlockModeListener then E:RegisterUnlockModeListener(ADDON,function(active) ns.preview=active; ns.Apply() end) end
    ns.Apply()
end
_EDM_Apply=function() if ns.Apply then ns.Apply() end end
