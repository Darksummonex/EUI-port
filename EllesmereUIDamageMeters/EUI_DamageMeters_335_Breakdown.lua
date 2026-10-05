-- Shared preallocated hover breakdown and per-window actor drilldown.
local _,ns=...
local white="Interface\\Buttons\\WHITE8X8"
local function Icon(entry)
    if entry.id and entry.id>0 then local _,_,icon=GetSpellInfo(entry.id); if icon then return icon end end
    return "Interface\\Icons\\Ability_MeleeDamage"
end
local function Deaths(actor,segment)
    local list={}
    for _,death in ipairs(segment and segment.deaths or {}) do if death.guid==actor.guid then list[#list+1]=death end end
    return list
end
function ns.FocusWindow(index,actor)
    local r,cfg=ns.windows[index],ns.Profile().windows[index]
    if not r or not cfg or cfg.metric=="threat" then return end
    ns.HideBreakdownTooltip()
    r.focusGUID,r.focusName,r.focusMode,r.offset=actor.guid,actor.name,"spells",0
    r.focusMetric,r.focusSegment,r.focusConfig=cfg.metric,cfg.segment,cfg
    r.focusDeath=nil; ns.RefreshWindow(index)
end
function ns.BackToGroup(index)
    local r=ns.windows[index]; if not r then return end
    ns.HideWindowBreakdown(index); r.focusGUID=nil; r.focusActor=nil; r.offset=0
    ns.RefreshWindow(index)
end
function ns.FocusRows(index,cfg,actors,segment)
    local r=ns.windows[index]; local actor
    for _,a in ipairs(actors) do if a.guid==r.focusGUID then actor=a; break end end
    r.focusActor=actor; local rows={}; if not actor then return rows end
    local m=ns.metricMap[cfg.metric] or ns.metricMap.damage
    local entries,death
    if cfg.metric=="deaths" then
        local list=Deaths(actor,segment); r.focusDeath=ns.Clamp(r.focusDeath or #list,1,math.max(1,#list))
        death=list[r.focusDeath]; entries=death and death.logs or {}
    else entries=ns.Breakdown(actor,cfg.metric,r.focusMode) end
    for _,entry in ipairs(entries) do
        local amount=death and entry.amount or entry.total
        local name=entry.name
        if death then name=string.format("%+.1fs %s (%s)",entry.at-death.at,name,entry.source or "Environment") end
        rows[#rows+1]={guid=actor.guid,breakdown=true,entry=entry,icon=r.focusMode~="targets" and Icon(entry) or nil,
            name=name,class=actor.class,amount=amount,value=m.rate and amount/ns.Duration(segment) or amount,
            rate=amount/ns.Duration(segment),percent=not death and actor.amount>0 and amount/actor.amount*100 or 0,recap=death~=nil}
    end
    return rows,actor
end
function ns.FocusModeMenu(index,anchor)
    local r=ns.windows[index]; if not r or not r.focusGUID then return end
    local items={}
    if r.focusMetric=="deaths" then
        local cfg=ns.Profile().windows[index]; local segment=ns.Segment(cfg.segment)
        for i,death in ipairs(Deaths({guid=r.focusGUID},segment)) do local choice=i
            items[#items+1]={text="Death "..i.." ("..string.format("%.1fs",death.at)..")",fn=function() r.focusDeath=choice; r.offset=0; ns.RefreshWindow(index) end}
        end
    else
        for _,mode in ipairs({"spells","targets"}) do local choice=mode
            items[#items+1]={text=mode=="spells" and "Spells" or "Targets",fn=function() r.focusMode=choice; r.offset=0; ns.RefreshWindow(index) end}
        end
    end
    if r.focusActor and r.focusMetric~="deaths" then
        items[#items+1]={text="Detailed window",fn=function()
            local cfg=ns.Profile().windows[index]; local _,segment=ns.Rows(cfg.segment,cfg.metric)
            ns.ShowDetail(r.focusActor,r.focusMetric,segment,r.focusMode)
        end}
    end
    items[#items+1]={text="Back to group",fn=function() ns.BackToGroup(index) end}; ns.OpenMenu(anchor,items)
end
function ns.CreateBreakdownTooltip()
    if ns.breakdownTooltip then return end
    local f=CreateFrame("Frame",nil,UIParent); f:SetFrameStrata("TOOLTIP"); f:SetClampedToScreen(true); f:EnableMouse(false); ns.Skin(f,.97)
    ns.Size(f,360,80)
    f.title=ns.Text(f,12); f.title:SetPoint("TOPLEFT",f,"TOPLEFT",8,-7); f.title:SetWidth(344)
    f.title:SetHeight(16)
    f.note=ns.Text(f,10); f.note:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",8,6); f.note:SetWidth(344)
    f.note:SetHeight(14)
    f.rows={}
    for i=1,20 do
        local b=CreateFrame("Frame",nil,f); ns.Size(b,344,19); b:SetPoint("TOPLEFT",f,"TOPLEFT",8,-27-(i-1)*20)
        b.bar=CreateFrame("StatusBar",nil,b); b.bar:SetAllPoints(b); b.bar:SetStatusBarTexture(white); b.bar:SetMinMaxValues(0,100)
        b.host=CreateFrame("Frame",nil,b); b.host:SetAllPoints(b); b.host:SetFrameLevel(b.bar:GetFrameLevel()+1)
        b.icon=b.host:CreateTexture(nil,"ARTWORK"); ns.Size(b.icon,18,18); b.icon:SetPoint("LEFT",b.host,"LEFT",0,0); b.icon:SetTexCoord(.08,.92,.08,.92)
        b.name=ns.Text(b.host,11); b.name:SetPoint("LEFT",b.host,"LEFT",22,0); b.name:SetWidth(214)
        b.value=ns.Text(b.host,11); b.value:SetPoint("RIGHT",b.host,"RIGHT",-2,0); b.value:SetJustifyH("RIGHT"); b.value:SetWidth(104)
        b.name:SetHeight(19); b.value:SetHeight(19)
        f.rows[i]=b; b:Hide()
    end
    f:Hide(); ns.breakdownTooltip=f
end
function ns.HideBreakdownTooltip(owner)
    local f=ns.breakdownTooltip
    if f and (not owner or owner==f.owner) then f.owner=nil; f.identity=nil; f:Hide() end
end
function ns.HideWindowBreakdown(index)
    local f=ns.breakdownTooltip
    if f and f.owner and f.owner.windowIndex==index then ns.HideBreakdownTooltip() end
end
local function Identity(row)
    local d=row.data
    return d and (d.guid..":"..tostring(d.breakdown and (d.entry.id or d.entry.guid or d.name) or "actor")..":"..tostring(row.segment and row.segment.id)..":"..row.metric)
end
function ns.ShowBreakdownTooltip(row)
    local f=ns.breakdownTooltip; if not f or not row.data then return end
    f.owner=row; f.identity=Identity(row)
    f:ClearAllPoints()
    if row:GetCenter()>(UIParent:GetWidth()/2) then f:SetPoint("TOPRIGHT",row,"TOPLEFT",-5,0)
    else f:SetPoint("TOPLEFT",row,"TOPRIGHT",5,0) end
    ns.UpdateWindowBreakdown(row.windowIndex)
end
function ns.UpdateWindowBreakdown(index)
    local f=ns.breakdownTooltip; local owner=f and f.owner
    if not owner or owner.windowIndex~=index then return end
    if not owner.data or not owner:IsShown() or Identity(owner)~=f.identity then ns.HideBreakdownTooltip(); return end
    local actor=owner.actorRow or owner.data; local m=ns.metricMap[owner.metric] or ns.metricMap.damage
    local lines={}; local note="Click: player details. Shift-click: full window. Right click: bookmarks."
    local function Heading(text) lines[#lines+1]={name=text,heading=true} end
    local function Entries(entries,total,limit,targets,recap)
        local other=0
        for i,entry in ipairs(entries) do
            local amount=recap and entry.amount or entry.total
            if recap and i>=math.max(1,#entries-limit+1) or not recap and i<=limit then
                local label=entry.name
                if recap then label=string.format("%+.1fs %s",entry.at-recap.at,label) end
                local value=m.rate and amount/ns.Duration(owner.segment) or amount
                lines[#lines+1]={name=label,value=ns.Format(value),percent=not recap and total>0 and amount/total*100 or nil,
                    icon=not targets and Icon(entry) or nil,targets=targets}
            elseif not recap then other=other+amount end
        end
        if other>0 and not recap then lines[#lines+1]={name="Other",value=ns.Format(m.rate and other/ns.Duration(owner.segment) or other),percent=total>0 and other/total*100 or 0,targets=targets} end
    end
    if owner.data.breakdown then
        local entry=owner.data.entry
        f.title:SetText(entry.name.." - "..actor.name)
        Heading(m.label..": "..ns.Format(owner.data.value))
        if entry.hits and owner.metric~="buffUptime" and owner.metric~="debuffUptime" then Heading(entry.hits.." hits / "..entry.crit.." critical")
            Heading("Min / Max: "..ns.Format(entry.min).." / "..ns.Format(entry.max)) end
        if owner.data.recap then Heading("Source: "..(entry.source or "Environment")) end
        note="Right click returns to group. Title switches breakdown."
    elseif owner.metric=="threat" then
        f.title:SetText(actor.name.." - "..m.label); Heading(ns.Format(actor.value)..string.format(" (%.1f%%)",actor.percent or 0))
        note="Native threat for the current target."
    elseif owner.metric=="deaths" then
        f.title:SetText(actor.name.." - Last Death Recap")
        local list=Deaths(actor,owner.segment); local death=list[#list]
        if death then Entries(death.logs,0,15,false,death) else Heading("No recorded death recap") end
    else
        f.title:SetText(actor.name.."'s "..m.label.." Breakdown")
        Heading("Spells"); Entries(ns.Breakdown(actor,owner.metric,"spells"),actor.amount or 0,8,false)
        Heading("Targets"); Entries(ns.Breakdown(actor,owner.metric,"targets"),actor.amount or 0,5,true)
        if owner.metric=="absorbed" then note="Absorbs received; shield caster is not inferred."
        elseif owner.metric=="buffUptime" or owner.metric=="debuffUptime" then note="Observed aura seconds summed across targets." end
    end
    f.note:SetText(note); f.lines=lines
    for i,b in ipairs(f.rows) do
        local line=lines[i]
        if line then
            b.name:ClearAllPoints(); b.name:SetPoint("LEFT",b.host,"LEFT",line.icon and 22 or 2,0)
            b.name:SetWidth(line.heading and 340 or line.icon and 214 or 234)
            b.name:SetText(line.name); b.name:SetTextColor(line.heading and .65 or 1,line.heading and .7 or 1,line.heading and .75 or 1)
            b.value:SetText(line.value and (line.value..(line.percent and string.format("  %.1f%%",line.percent) or "")) or "")
            if line.icon then b.icon:SetTexture(line.icon); b.icon:Show() else b.icon:Hide() end
            b.bar:SetValue(line.percent or 0); b.bar:SetStatusBarColor(line.targets and .85 or .15,line.targets and .08 or .55,line.targets and .08 or .65,line.targets and .6 or .35)
            b:Show()
        else b:Hide() end
    end
    ns.Size(f,360,49+math.min(#lines,20)*20); f:Show()
end
