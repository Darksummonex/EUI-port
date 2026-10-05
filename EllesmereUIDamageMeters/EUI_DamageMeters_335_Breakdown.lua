-- Shared preallocated hover breakdown and per-window actor drilldown.
local _,ns=...
local white="Interface\\Buttons\\WHITE8X8"
local TT_WIDTH,TT_HEADER,TT_BAR,TT_LABEL,TT_GAP,TT_ROWS=275,20,18,22,1,24
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
    for i,entry in ipairs(entries) do
        local amount=death and entry.amount or entry.total
        local name=entry.name
        if death then name=string.format("%+.1fs %s (%s)",entry.at-death.at,name,entry.source or "Environment") end
        rows[#rows+1]={guid=actor.guid,breakdown=true,entry=entry,icon=r.focusMode~="targets" and Icon(entry) or nil,
            name=name,class=actor.class,amount=amount,value=m.rate and amount/ns.Duration(segment) or amount,
            rate=amount/ns.Duration(segment),percent=not death and actor.amount>0 and amount/actor.amount*100 or 0,recap=death~=nil,
            hp=death and entry.hp,heal=death and entry.kind=="heal",fatal=death and i==#entries and entry.kind~="heal"}
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
-- "-1.2k (300 overkill) (25%)": overkill only on the killing blow, health
-- only when the victim was a group member when the hit landed.
function ns.RecapAmount(entry,fatal)
    if not entry then return "" end
    local text=(entry.kind=="heal" and "+" or "-")..ns.Format(entry.amount)
    if fatal and entry.overkill then text=text.." |cffff3333("..ns.Format(entry.overkill).." overkill)|r" end
    if entry.hp then text=text..string.format(" (%d%%)",math.floor(entry.hp*100+.5)) end
    return text
end
function ns.TooltipSpellLimit()
    local p=ns.Profile(); return p and p.tooltipMoreSpells==false and 8 or 15
end
function ns.CreateBreakdownTooltip()
    if ns.breakdownTooltip then return end
    local f=CreateFrame("Frame",nil,UIParent); f:SetFrameStrata("TOOLTIP"); f:SetClampedToScreen(true); f:EnableMouse(false)
    f:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1}); f:SetBackdropColor(0,0,0,.95); f:SetBackdropBorderColor(0,0,0,1)
    ns.Size(f,TT_WIDTH,TT_HEADER)
    f.header=CreateFrame("Frame",nil,f); f.header:SetPoint("TOPLEFT",f,"TOPLEFT",0,0); f.header:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0); f.header:SetHeight(TT_HEADER)
    f.header.bg=f.header:CreateTexture(nil,"BACKGROUND"); f.header.bg:SetTexture(white); f.header.bg:SetAllPoints(f.header)
    f.title=ns.Text(f.header,10); f.title:SetPoint("LEFT",f.header,"LEFT",5,0); f.title:SetWidth(TT_WIDTH-10); f.title:SetHeight(TT_HEADER)
    f.rows={}
    for i=1,TT_ROWS do
        local b=CreateFrame("Frame",nil,f); b:SetHeight(TT_BAR)
        b.icon=b:CreateTexture(nil,"ARTWORK"); ns.Size(b.icon,TT_BAR,TT_BAR); b.icon:SetPoint("TOPLEFT",b,"TOPLEFT",0,0); b.icon:SetTexCoord(.08,.92,.08,.92)
        b.bar=CreateFrame("StatusBar",nil,b); b.bar:SetStatusBarTexture(white); b.bar:SetMinMaxValues(0,1)
        b.host=CreateFrame("Frame",nil,b); b.host:SetAllPoints(b); b.host:SetFrameLevel(b.bar:GetFrameLevel()+2)
        b.line=b.host:CreateTexture(nil,"ARTWORK"); b.line:SetTexture(white); b.line:SetVertexColor(1,1,1,.15); b.line:SetHeight(1)
        b.line:SetPoint("TOPLEFT",b,"TOPLEFT",4,-1); b.line:SetPoint("TOPRIGHT",b,"TOPRIGHT",-4,-1); b.line:Hide()
        b.value=ns.Text(b.host,10); b.value:SetPoint("RIGHT",b,"RIGHT",-3,0); b.value:SetJustifyH("RIGHT")
        b.name=ns.Text(b.host,10); b.name:SetPoint("RIGHT",b.value,"LEFT",-3,0)
        b.name:SetHeight(TT_BAR); b.value:SetHeight(TT_BAR)
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
    local p=ns.Profile(); f:SetScale(ns.Clamp((p.tooltipScale or 100)/100,.8,1.5))
    local window=ns.windows[row.windowIndex]; local win=window and window.frame
    local anchor=p.tooltipAnchor or "row"
    f:ClearAllPoints()
    if anchor=="center" then f:SetPoint("CENTER",UIParent,"CENTER",0,0)
    elseif anchor=="left" and win then f:SetPoint("TOPRIGHT",win,"TOPLEFT",-4,0)
    elseif anchor=="right" and win then f:SetPoint("TOPLEFT",win,"TOPRIGHT",4,0)
    else f:SetPoint("BOTTOMRIGHT",row,"TOPRIGHT",0,2) end
    ns.UpdateWindowBreakdown(row.windowIndex)
end
local function Paint(f,lines,owner)
    local p=ns.Profile(); local cfg=p.windows[owner.windowIndex] or {}
    local key=p.tooltipBarTexture; if not key or key=="match" then key=cfg.barTexture end
    local texture=ns.BarTexturePath(key)
    local hc=cfg.headerColor or {}
    f.header.bg:SetVertexColor(hc.r or .106,hc.g or .106,hc.b or .106,1)
    if cfg.titleUseAccent~=false then f.title:SetTextColor(ns.Accent())
    else local c=cfg.titleColor or {}; f.title:SetTextColor(c.r or 1,c.g or 1,c.b or 1) end
    f.lines=lines
    local y=TT_HEADER
    for i,b in ipairs(f.rows) do
        local line=lines[i]
        if line then
            local h=line.kind=="label" and TT_LABEL or TT_BAR
            b:ClearAllPoints(); b:SetPoint("TOPLEFT",f,"TOPLEFT",0,-y); b:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,-y); b:SetHeight(h)
            local inset=line.icon and TT_BAR or 0
            if line.icon then b.icon:SetTexture(line.icon); b.icon:Show() else b.icon:Hide() end
            if line.fill then
                b.bar:ClearAllPoints(); b.bar:SetPoint("TOPLEFT",b,"TOPLEFT",inset,0); b.bar:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",0,0)
                b.bar:SetStatusBarTexture(texture); b.bar:SetValue(line.fill)
                if line.kind=="target" then b.bar:SetStatusBarColor(.867,.192,.192,1)
                elseif line.kind=="recap" and line.heal then b.bar:SetStatusBarColor(.1,.5,.1,1)
                elseif line.kind=="recap" then b.bar:SetStatusBarColor(.6,.08,.08,1)
                else b.bar:SetStatusBarColor(.2,.2,.2,1) end
                b.bar:Show()
            else b.bar:Hide() end
            if line.kind=="label" then b.line:Show() else b.line:Hide() end
            b.name:ClearAllPoints(); b.name:SetPoint("LEFT",b,"LEFT",inset+3,line.kind=="label" and -3 or 0); b.name:SetPoint("RIGHT",b.value,"LEFT",-3,0)
            b.name:SetText(line.name)
            if line.kind=="label" then b.name:SetTextColor(.6,.6,.6)
            elseif line.kind=="heading" then b.name:SetTextColor(.65,.7,.75)
            else b.name:SetTextColor(1,1,1) end
            b.value:SetText(line.value and (line.value..(line.percent and string.format("  %.1f%%",line.percent) or "")) or "")
            b:Show(); y=y+h+TT_GAP
        else b:Hide() end
    end
    ns.Size(f,TT_WIDTH,y+(#lines>0 and 2 or 0)); f:Show()
end
function ns.UpdateWindowBreakdown(index)
    local f=ns.breakdownTooltip; local owner=f and f.owner
    if not owner or owner.windowIndex~=index then return end
    if not owner.data or not owner:IsShown() or Identity(owner)~=f.identity then ns.HideBreakdownTooltip(); return end
    local actor=owner.actorRow or owner.data; local m=ns.metricMap[owner.metric] or ns.metricMap.damage
    local lines={}; local limit=ns.TooltipSpellLimit()
    local function Heading(text) lines[#lines+1]={kind="heading",name=text} end
    local function Entries(entries,total,count,kind)
        local top=entries[1] and entries[1].total or 0
        for i=1,math.min(count,#entries) do
            local entry=entries[i]; local value=m.rate and entry.total/ns.Duration(owner.segment) or entry.total
            lines[#lines+1]={kind=kind,name=entry.name,value=ns.Format(value),percent=total>0 and entry.total/total*100 or nil,
                icon=kind=="spell" and Icon(entry) or nil,fill=top>0 and entry.total/top or 0}
        end
    end
    if owner.data.breakdown then
        local entry=owner.data.entry
        f.title:SetText(entry.name.." - "..actor.name)
        Heading(m.label..": "..ns.Format(owner.data.value))
        if entry.hits and owner.metric~="buffUptime" and owner.metric~="debuffUptime" then Heading(entry.hits.." hits / "..entry.crit.." critical")
            Heading("Min / Max: "..ns.Format(entry.min).." / "..ns.Format(entry.max)) end
        if owner.data.recap then Heading("Source: "..(entry.source or "Environment")) end
    elseif owner.metric=="threat" then
        f.title:SetText(actor.name.." - "..m.label); Heading(ns.Format(actor.value)..string.format(" (%.1f%%)",actor.percent or 0))
    elseif owner.metric=="deaths" then
        f.title:SetText(actor.name.."'s Death Recap")
        local list=Deaths(actor,owner.segment); local death=list[#list]
        if death then
            local logs=death.logs
            for i=math.max(1,#logs-limit+1),#logs do
                local entry=logs[i]
                lines[#lines+1]={kind="recap",name=string.format("-%.1fs %s",death.at-entry.at,entry.name),
                    value=ns.RecapAmount(entry,i==#logs and entry.kind~="heal"),icon=Icon(entry),fill=entry.hp or 0,heal=entry.kind=="heal"}
            end
        else Heading("No recorded death recap") end
    else
        f.title:SetText(actor.name.."'s "..m.label.." Breakdown")
        Entries(ns.Breakdown(actor,owner.metric,"spells"),actor.amount or 0,limit,"spell")
        local targets=ns.Breakdown(actor,owner.metric,"targets")
        if #targets>0 then lines[#lines+1]={kind="label",name="Targets"}; Entries(targets,actor.amount or 0,3,"target") end
    end
    Paint(f,lines,owner)
end
