local ADDON,ns=...
local E=EllesmereUI
if not ns.addon then return end
local white="Interface\\Buttons\\WHITE8X8"
local QUESTION="Interface\\Icons\\INV_Misc_QuestionMark"
local CLASSIC_RING="Interface\\Buttons\\UI-Quickslot2"
local PUSHED="Interface\\Buttons\\UI-Quickslot-Depress"
local D={}
ns.D=D
function D.Size(f,w,h) f:SetWidth(math.max(.01,w)); f:SetHeight(math.max(.01,h)) end
-- Alert-catalogue and SharedMedia keys play as files; the original choices are
-- Blizzard sound names (RaidWarning, ReadyCheck...) for PlaySound.
function D.PlayCastSound(key)
    if type(key)~="string" or key=="" or key=="none" then return end
    local paths=E._groupDeathSoundPaths or (E.GetAlertSoundCatalogue and E.GetAlertSoundCatalogue())
    local path=E.ResolveSoundPath and E.ResolveSoundPath(paths,key)
    if path then PlaySoundFile(path,"Master") elseif PlaySound then PlaySound(key) end
end
function D.Font(fs,size,flags)
    local path=E.GetFontPath and E.GetFontPath("cdm") or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    flags=flags or (E.GetFontOutlineFlag and E.GetFontOutlineFlag("cdm")) or "OUTLINE"
    flags=tostring(flags):gsub(",?%s*SLUG","")
    if not fs:SetFont(path,size,flags) then fs:SetFont("Fonts\\FRIZQT__.TTF",size,"OUTLINE") end
    fs:SetShadowColor(0,0,0,1); fs:SetShadowOffset(1,-1)
end
do local probe=CreateFrame("Cooldown"); D.HasDrawEdge=probe and probe.SetDrawEdge~=nil; if probe and probe.Hide then probe:Hide() end end
function D.Text(parent,size) local fs=parent:CreateFontString(nil,"OVERLAY"); D.Font(fs,size); fs:SetTextColor(1,1,1); return fs end
function D.Edges(parent)
    local edges={}
    for i=1,4 do local t=parent:CreateTexture(nil,"OVERLAY"); t:SetTexture(white); edges[i]=t; t:Hide() end
    local top,bottom,left,right=edges[1],edges[2],edges[3],edges[4]
    top:SetPoint("TOPLEFT",parent,"TOPLEFT",-1,1); top:SetPoint("TOPRIGHT",parent,"TOPRIGHT",1,1); top:SetHeight(2)
    bottom:SetPoint("BOTTOMLEFT",parent,"BOTTOMLEFT",-1,-1); bottom:SetPoint("BOTTOMRIGHT",parent,"BOTTOMRIGHT",1,-1); bottom:SetHeight(2)
    left:SetPoint("TOPLEFT",parent,"TOPLEFT",-1,1); left:SetPoint("BOTTOMLEFT",parent,"BOTTOMLEFT",-1,-1); left:SetWidth(2)
    right:SetPoint("TOPRIGHT",parent,"TOPRIGHT",1,1); right:SetPoint("BOTTOMRIGHT",parent,"BOTTOMRIGHT",1,-1); right:SetWidth(2)
    return edges
end
function D.PaintEdges(edges,size,r,g,b,a)
    for i,t in ipairs(edges) do
        if size>0 then t:SetVertexColor(r,g,b,a); if i<=2 then t:SetHeight(size) else t:SetWidth(size) end; t:Show() else t:Hide() end
    end
end
-- One glow per host: Core's shared engine (Retail CDM saved numbering), edge pulse fallback.
function D.SetGlow(host,style,w,h,r,g,b,bar,now)
    if not style then
        if host._cdmGlow then host._cdmGlow=nil; if E.Glows and E.Glows.StopGlow then E.Glows.StopGlow(host) end end
        if host.edges then D.PaintEdges(host.edges,0) end
        return
    end
    if E.Glows and E.Glows.StartSpecGlow then
        local spec=host._cdmSpec or {}; host._cdmSpec=spec
        spec.style=ns.GLOW_TO_SHARED[style] or 1; spec.r,spec.g,spec.b=r,g,b
        spec.lines,spec.thickness,spec.speed=bar and bar.pixelGlowLines or 8,bar and bar.pixelGlowThickness or 2,bar and bar.pixelGlowSpeed or 4
        host:Show(); E.Glows.StartSpecGlow(host,spec,w,h,bar and bar.glowHost or "icon"); host._cdmGlow=true
        return
    end
    host.edges=host.edges or D.Edges(host)
    if not r and E.GetAccentColor then r,g,b=E.GetAccentColor() end
    D.PaintEdges(host.edges,2,r or 1,g or .8,b or .2,.55+.4*math.sin((now or 0)*5)^2)
end
local function Tooltip(self)
    local st=self.state; if not st or not (st.bar.showTooltip or ns.preview) then return end
    local e,m=st.entry,st.meta; GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
    if m.kind=="spell" and GameTooltip.SetSpell then GameTooltip:SetSpell(m.slot,m.book)
    elseif m.kind=="slot" and GameTooltip.SetInventoryItem then GameTooltip:SetInventoryItem("player",m.slot)
    elseif (m.kind=="item" or m.kind=="preset") and GameTooltip.SetHyperlink then GameTooltip:SetHyperlink("item:"..(st.itemID or m.id))
    elseif st.aura and GameTooltip.SetUnitAura then GameTooltip:SetUnitAura(e.unit or "player",st.aura.index,e.filter or "HELPFUL")
    else GameTooltip:AddLine(m.name) end
    GameTooltip:Show()
end
local function HideTooltip(self) if GameTooltip.GetOwner and GameTooltip:GetOwner()==self then GameTooltip:Hide() end end
function D.NewIcon(parent,key)
    local b=CreateFrame("Button",nil,parent); b.key=key
    b.bg=b:CreateTexture(nil,"BACKGROUND"); b.bg:SetTexture(white); b.bg:SetAllPoints(b)
    b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetPoint("CENTER",b,"CENTER",0,0)
    b.cooldown=CreateFrame("Cooldown",nil,b); b.cooldown:SetAllPoints(b.icon); b.cooldown.noCooldownCount=true; b.cooldown.noOCC=true
    b.border=CreateFrame("Frame",nil,b); b.border:SetAllPoints(b.icon); b.border:SetFrameLevel(b.cooldown:GetFrameLevel()+1)
    b.host=CreateFrame("Frame",nil,b); b.host:SetAllPoints(b); b.host:SetFrameLevel(b.cooldown:GetFrameLevel()+3)
    b.glow=CreateFrame("Frame",nil,b.host); b.glow:SetAllPoints(b.icon)
    b.edgeHost=CreateFrame("Frame",nil,b); b.edgeHost:SetAllPoints(b.icon); b.edgeHost:SetFrameLevel(b.cooldown:GetFrameLevel()+2)
    b.edges=D.Edges(b.edgeHost)
    b.ring=b.host:CreateTexture(nil,"OVERLAY"); b.ring:SetTexture(CLASSIC_RING); b.ring:Hide()
    b.shape=b.host:CreateTexture(nil,"OVERLAY"); b.shape:SetAllPoints(b.icon); b.shape:Hide()
    b.push=b.host:CreateTexture(nil,"OVERLAY"); b.push:SetTexture(PUSHED); b.push:SetAllPoints(b.icon); b.push:SetBlendMode("ADD"); b.push:Hide()
    b.timer=D.Text(b.host,12); b.count=D.Text(b.host,11); b.keybind=D.Text(b.host,10)
    b:SetScript("OnEnter",Tooltip); b:SetScript("OnLeave",HideTooltip); b:SetScript("OnHide",HideTooltip)
    b:SetScript("OnClick",function(self)
        if not self.state then return end
        ns.selectedBar=self.key; ns.selectedEntry=self.state.entry
        if E.EnsureOptionsLoaded then E.EnsureOptionsLoaded() end
        if E.ShowModule then E:ShowModule(ADDON) end
    end)
    b:Hide(); return b
end
local POINTS={center="CENTER",top="TOP",bottom="BOTTOM",left="LEFT",right="RIGHT",topleft="TOPLEFT",topright="TOPRIGHT",bottomleft="BOTTOMLEFT",bottomright="BOTTOMRIGHT"}
function D.PlaceText(fs,host,pos,x,y)
    local pt=POINTS[pos or "center"] or "CENTER"; local inset=pt:find("LEFT") and 2 or pt:find("RIGHT") and -2 or 0
    local vin=pt:find("TOP") and -2 or pt:find("BOTTOM") and 2 or 0
    fs:ClearAllPoints(); fs:SetPoint(pt,host,pt,inset+(x or 0),vin+(y or 0))
end
function D.BarFrame(key)
    local f=ns.frames[key]; if f then return f end
    f=CreateFrame("Frame","EUI335Cooldown_"..key,UIParent); f:SetFrameStrata("MEDIUM"); f:SetClampedToScreen(true); f:SetMovable(true)
    f.pool,f.visible,f.key={}, {},key
    f.bg=f:CreateTexture(nil,"BACKGROUND"); f.bg:SetTexture(white); f.bg:Hide()
    f.preview=f:CreateTexture(nil,"BACKGROUND"); f.preview:SetTexture(white); f.preview:SetAllPoints(f); f.preview:SetVertexColor(.03,.04,.05,.5); f.preview:Hide()
    f.label=D.Text(f,11); f.label:SetPoint("BOTTOMLEFT",f,"TOPLEFT",0,3)
    f.reminder=D.Text(f,14); f.reminder:SetPoint("BOTTOM",f,"TOP",0,4); f.reminder:Hide()
    f:EnableMouse(false); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function() if ns.preview then f:StartMoving() end end)
    f:SetScript("OnDragStop",function()
        f:StopMovingOrSizing(); local x,y=f:GetCenter(); local ux,uy=UIParent:GetCenter(); local scale=f:GetEffectiveScale()/UIParent:GetEffectiveScale()
        ns.Profile().positions[key]={point="CENTER",relPoint="CENTER",x=x*scale-ux,y=y*scale-uy}
    end)
    ns.frames[key]=f
    return f
end
-- Icons a bar can hold: its own entries plus whatever overflows into it.
function D.Capacity(bar)
    local n=#(ns.compiled[bar.key] or {})
    for _,o in ipairs(ns.Bars()) do if o~=bar and (o.maxIcons or 0)>0 and o.overflowTarget==bar.key then n=n+#(ns.compiled[o.key] or {}) end end
    return math.min(40,n)
end
-- Pools grow at compile time only; painting never allocates frames.
function ns.EnsurePools()
    for _,bar in ipairs(ns.Bars()) do
        local f=D.BarFrame(bar.key)
        for i=#f.pool+1,math.max(3,D.Capacity(bar)) do f.pool[i]=D.NewIcon(f,bar.key) end
    end
end
function ns.CreateGroups()
    for _,bar in ipairs(ns.Bars()) do D.BarFrame(bar.key) end
    ns.EnsurePools()
end
function D.Position(bar)
    local f=ns.frames[bar.key]; if not f then return end
    local p=ns.Profile().positions[bar.key]; local target=bar.anchorTo and bar.anchorTo~="none" and bar.anchorTo~="mouse" and ns.frames[bar.anchorTo]
    f:ClearAllPoints()
    local ox,oy=E._unlockActive and 0 or (bar.addOffsetX or 0),E._unlockActive and 0 or (bar.addOffsetY or 0)
    if target and target~=f then
        local side=bar.anchorPosition or "left"
        local a,r=({left="RIGHT",right="LEFT",top="BOTTOM",bottom="TOP"})[side] or "RIGHT",({left="LEFT",right="RIGHT",top="TOP",bottom="BOTTOM"})[side] or "LEFT"
        f:SetPoint(a,target,r,(bar.anchorOffsetX or 0)+ox,(bar.anchorOffsetY or 0)+oy)
    elseif p then f:SetPoint(p.point or "CENTER",UIParent,p.relPoint or p.point or "CENTER",(p.x or 0)+ox,(p.y or 0)+oy)
    else
        local index=1; for i,b in ipairs(ns.Bars()) do if b==bar then index=i end end
        f:SetPoint("BOTTOM",UIParent,"BOTTOM",ox,300+(index-1)*64+oy)
    end
end
function D.Cell(bar)
    local w=ns.Clamp(bar.iconSize,16,80); local h=w
    if bar.iconShape=="cropped" then h=math.floor(w*(1-2*ns.Clamp(bar.iconCropPercent or 10,5,25)/100)+.5) end
    return w,h
end
function D.Grid(bar,count)
    local rows=ns.Clamp(bar.numRows or 1,1,6); count=math.max(1,count)
    local perRow=math.ceil(count/rows); rows=math.ceil(count/perRow)
    return perRow,rows
end
function D.FrameSize(bar,count)
    local w,h=D.Cell(bar); local sp=ns.Clamp(bar.spacing,0,20); local per,rows=D.Grid(bar,count)
    if bar.verticalOrientation then return rows*(w+sp)-sp,per*(h+sp)-sp end
    return per*(w+sp)-sp,rows*(h+sp)-sp
end
function D.StyleIcon(b,bar,classic,cls)
    local w,h=D.Cell(bar); D.Size(b,w,h); D.Size(b.icon,w,h)
    b.bg:SetVertexColor(bar.bgR or .08,bar.bgG or .08,bar.bgB or .08,bar.onlyShowNumbers and 0 or bar.bgA or .6)
    local zoom=classic and 0 or ns.Clamp(bar.iconZoom or .08,0,.3)
    local trim=bar.iconShape=="cropped" and ns.Clamp(bar.iconCropPercent or 10,5,25)/100 or 0
    b.circle=bar.iconShape=="circle" and not classic and SetPortraitToTexture and true or false
    if b.circle then b.icon:SetTexCoord(0,1,0,1) else b.icon:SetTexCoord(zoom,1-zoom,zoom+trim,1-zoom-trim) end
    local size=classic and 0 or ns.Clamp(bar.borderSize or 1,0,8)
    local r,g,bl=bar.borderR or 0,bar.borderG or 0,bar.borderB or 0
    if bar.borderClassColor and cls then r,g,bl=cls.r,cls.g,cls.b end
    b.borderColor={r,g,bl,bar.borderA or 1}; b.lastTex=nil; b.activeBorder=nil
    local textured=not b.circle and not classic and E.ApplyBorderStyle and E.PP and E.PP.CreateBorder and (bar.borderTexture or "solid")~="solid"
    if b.textured and not textured then E.ApplyBorderStyle(b.border,0,0,0,0,0,"solid"); b.textured=nil end
    if b.circle then
        D.PaintEdges(b.edges,0); b.shape:SetTexture(E.SHAPE_BORDERS and E.SHAPE_BORDERS.circle or white); b.shape:SetVertexColor(r,g,bl,size>0 and (bar.borderA or 1) or 0); b.shape:Show()
    elseif textured then
        D.PaintEdges(b.edges,0); b.shape:Hide(); b.border:Show(); E.ApplyBorderStyle(b.border,size,r,g,bl,bar.borderA or 1,bar.borderTexture,nil,nil,nil,nil,"cdm",size); b.textured=true
    else b.shape:Hide(); D.PaintEdges(b.edges,size,r,g,bl,bar.borderA or 1) end
    if b.edges then for i,t in ipairs(b.edges) do t:ClearAllPoints() end
        local s=size; local e=b.edges
        e[1]:SetPoint("TOPLEFT",b.icon,"TOPLEFT",0,0); e[1]:SetPoint("TOPRIGHT",b.icon,"TOPRIGHT",0,0)
        e[2]:SetPoint("BOTTOMLEFT",b.icon,"BOTTOMLEFT",0,0); e[2]:SetPoint("BOTTOMRIGHT",b.icon,"BOTTOMRIGHT",0,0)
        e[3]:SetPoint("TOPLEFT",b.icon,"TOPLEFT",0,0); e[3]:SetPoint("BOTTOMLEFT",b.icon,"BOTTOMLEFT",0,0)
        e[4]:SetPoint("TOPRIGHT",b.icon,"TOPRIGHT",0,0); e[4]:SetPoint("BOTTOMRIGHT",b.icon,"BOTTOMRIGHT",0,0)
        if s<=0 or b.textured or b.circle then D.PaintEdges(e,0) end
    end
    if classic then b.ring:ClearAllPoints(); D.Size(b.ring,w*66/36,h*66/36); b.ring:SetPoint("CENTER",b.icon,"CENTER",0,-h/36); b.ring:Show() else b.ring:Hide() end
    D.Font(b.timer,bar.cooldownFontSize or 12); b.timer:SetTextColor(bar.cooldownTextR or 1,bar.cooldownTextG or 1,bar.cooldownTextB or 1)
    D.PlaceText(b.timer,b.host,bar.cooldownTextPosition,bar.cooldownTextX,bar.cooldownTextY)
    D.Font(b.count,bar.stackCountSize or 11); b.count:SetTextColor(bar.stackCountR or 1,bar.stackCountG or 1,bar.stackCountB or 1)
    D.PlaceText(b.count,b.host,bar.stackCountPosition or "bottomright",bar.stackCountX,bar.stackCountY)
    D.Font(b.keybind,bar.keybindSize or 10); b.keybind:SetTextColor(bar.keybindR or 1,bar.keybindG or 1,bar.keybindB or 1,bar.keybindA or .9)
    b.keybind:ClearAllPoints(); local ka=bar.keybindAnchor or "TOPLEFT"; b.keybind:SetPoint(ka,b.host,ka,bar.keybindOffsetX or 2,bar.keybindOffsetY or -2)
    b.cooldown:SetAlpha((bar.onlyShowNumbers or bar.chargesOnly) and 0 or ns.Clamp(bar.swipeAlpha or .7,0,1))
    if b.cooldown.SetDrawEdge then b.cooldown:SetDrawEdge(bar.showCooldownEdge and true or false) end
    b.icon:SetAlpha((bar.onlyShowNumbers or bar.chargesOnly) and 0 or 1)
    b.glowW,b.glowH=w,h
end
function ns.Layout()
    local p=ns.Profile(); local _,class=UnitClass("player"); local cls=RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    ns.anyMouse=false
    for _,bar in ipairs(ns.Bars()) do
        local f=D.BarFrame(bar.key)
        f:SetFrameStrata(bar.barStrata or "MEDIUM"); f.label:SetText(bar.name or bar.key)
        for _,b in ipairs(f.pool) do D.StyleIcon(b,bar,p.useClassicStyle,cls) end
        D.Font(f.reminder,bar.focusReminderSize or 14)
        f.reminder:ClearAllPoints(); f.reminder:SetPoint("BOTTOM",f,"TOP",bar.focusReminderOffsetX or 0,bar.focusReminderOffsetY or 4)
        local fw,fh=D.FrameSize(bar,math.max(1,D.Capacity(bar))); D.Size(f,fw,fh)
        if bar.anchorTo=="mouse" then ns.anyMouse=true end
        D.Position(bar)
        if bar.barBgEnabled then local pad=ns.Clamp(bar.spacing,0,20)
            f.bg:ClearAllPoints(); f.bg:SetPoint("TOPLEFT",f,"TOPLEFT",-pad,pad); f.bg:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",pad,-pad)
            f.bg:SetVertexColor(bar.barBgR or 0,bar.barBgG or 0,bar.barBgB or 0,bar.barBgA or .5); f.bg:Show()
        else f.bg:Hide() end
    end
end
function D.TimeText(t)
    if t<=0 then return "" elseif t<3 then return string.format("%.1f",t) elseif t<60 then return tostring(math.ceil(t)) elseif t<3600 then return math.ceil(t/60).."m" end
    return math.ceil(t/3600).."h"
end
local groupState={}
function D.GroupState()
    local raid=(GetNumRaidMembers and GetNumRaidMembers() or 0)>0
    groupState.inCombat=ns.inCombat and true or false; groupState.inRaid=raid
    groupState.inParty=not raid and (GetNumPartyMembers and GetNumPartyMembers() or 0)>0
    return groupState
end
-- Same engine as Retail: multi-select modes + Show/Hide lanes (barVisibility legacy key).
function ns.BarVerdict(bar,key)
    if UnitHasVehicleUI and UnitHasVehicleUI("player") then return false end
    local state=D.GroupState()
    local v=E.EvalVisibilityExtended and E.EvalVisibilityExtended(bar,key or "barVisibility",state)
    if v==nil then
        local mode=bar[key or "barVisibility"] or "always"
        if mode=="mouseover" then v="mouseover" elseif E.CheckVisibilityMode then v=E.CheckVisibilityMode(mode,state) and true or false
        else v=mode~="never" and not (mode=="in_combat" and not state.inCombat) and not (mode=="out_of_combat" and state.inCombat) end
    end
    if v and E.CheckVisibilityOptions and E.CheckVisibilityOptions(bar) then v=false end
    return v
end
function D.FocusCast(bar)
    for _,unit in ipairs(bar.focusKickUseTarget and {"focus","target"} or {"focus"}) do
        if UnitExists(unit) and UnitCanAttack and UnitCanAttack("player",unit) then
            local name,_,_,_,_,_,_,_,lock=UnitCastingInfo(unit)
            if not name then name,_,_,_,_,_,_,lock=UnitChannelInfo(unit) end
            if name and not lock then return name,unit end
        end
    end
end
function D.Collect(bar)
    local list={}
    for _,st in ipairs(ns.compiled[bar.key] or {}) do
        local place,mode=ns.Placement(st)
        if ns.preview and not place then place="show"; mode="inactive" end
        if place then list[#list+1]={st=st,keep=place=="keep",mode=mode} end
    end
    if bar.sort=="remaining" then table.sort(list,function(a,b) local x,y=a.st.remaining or 0,b.st.remaining or 0; if x==y then return a.st.meta.name<b.st.meta.name end; return x>y end) end
    return list
end
function ns.PaintAll(now)
    local p=ns.Profile(); local bars=ns.Bars(); local lists={}
    for _,bar in ipairs(bars) do lists[bar.key]=D.Collect(bar) end
    for _,bar in ipairs(bars) do
        local max=tonumber(bar.maxIcons) or 0; local target=bar.overflowTarget and lists[bar.overflowTarget]
        if max>0 and target and bar.overflowTarget~=bar.key then
            local own=lists[bar.key]
            while #own>max do table.insert(target,table.remove(own,max+1)) end
        end
    end
    for _,bar in ipairs(bars) do ns.PaintBar(bar,lists[bar.key],now,p) end
end
function D.PaintIcon(b,item,bar,now,combat)
    local st=item and item.st; b.state=st
    if not st then
        b.icon:SetTexture(QUESTION); b.icon:SetDesaturated(false); b.icon:SetVertexColor(1,1,1,1); b.cooldown:Hide(); b.timer:SetText(""); b.count:SetText(""); b.keybind:SetText("")
        D.SetGlow(b.glow); b.push:Hide(); b:SetAlpha(1); return
    end
    local m,e=st.meta,st.entry
    local tex=st.aura and st.aura.icon or st.icon or m.icon or QUESTION
    if b.circle and SetPortraitToTexture and type(tex)=="string" then if b.lastTex~=tex then SetPortraitToTexture(b.icon,tex); b.lastTex=tex end
    elseif b.lastTex~=tex then b.icon:SetTexture(tex); b.lastTex=tex end
    local inactive=item.mode=="inactive"
    local desat=inactive and bar.desaturateInactiveBuffs or m.kind~="aura" and (bar.desaturateOnCD and st.onCD and not st.activeAura or st.missing)
    b.icon:SetDesaturated(desat and true or false)
    local r,g,bl=1,1,1
    if m.kind~="aura" and not inactive then
        if st.outOfRange then r,g,bl=bar.rangeR or .85,bar.rangeG or .15,bar.rangeB or .15
        elseif bar.showNoMana and st.noMana then r,g,bl=bar.manaR or .35,bar.manaG or .45,bar.manaB or 1
        elseif not st.usable and not st.onCD and not st.missing then r,g,bl=.4,.4,.4 end
    end
    b.icon:SetVertexColor(r,g,bl,1)
    local alpha=1
    if item.keep then alpha=0 elseif st.onCD and ns.Eff(st,"cdStateEffect")=="lowerAlphaOnCD" then alpha=ns.Clamp(ns.Eff(st,"cdStateLowerAlpha") or .5,0,1) end
    b:SetAlpha(alpha)
    local cs,cd,rev
    if st.activeAura then cd=st.activeAura.duration or 0; cs=(st.activeAura.expires or 0)-cd; rev=true
    elseif m.kind=="aura" then cs,cd,rev=st.start,st.duration,true
    else cs,cd,rev=st.start,st.duration,ns.Eff(st,"reverseSwipe") and true or false end
    local remaining=st.activeAura and math.max(0,(st.activeAura.expires or 0)-now) or st.remaining or 0
    if cd and cd>0 and remaining>0 and not ns.Eff(st,"hideCDSwipe") then
        if b.lastStart~=cs or b.lastDuration~=cd or b.lastRev~=rev then
            if b.cooldown.SetReverse then b.cooldown:SetReverse(rev) end
            b.cooldown:SetCooldown(cs,cd); b.lastStart,b.lastDuration,b.lastRev=cs,cd,rev
        end
        b.cooldown:Show()
    else b.cooldown:Hide(); b.lastStart,b.lastDuration=nil,nil end
    local text=bar.showCooldownText and not bar.chargesOnly and D.TimeText(remaining) or ""
    if b.timer:GetText()~=text then b.timer:SetText(text) end
    local count=st.count or 0; local ctext=""
    if bar.showItemCount then
        if m.kind=="aura" and count>1 then ctext=tostring(count)
        elseif (m.kind=="item" or m.kind=="preset") and (count>0 or not bar.hideZeroChargeText) then ctext=tostring(count) end
    end
    b.count:SetText(ctext)
    b.keybind:SetText(bar.showKeybind and m.kind~="aura" and ns.keybinds[m.name] or "")
    local active=st.activeAura and ns.Eff(st,"activeBorderEnabled")
    if active then D.PaintEdges(b.edges,math.max(1,ns.Clamp(bar.borderSize or 1,0,8)),ns.Eff(st,"activeBorderR") or 1,ns.Eff(st,"activeBorderG") or .776,ns.Eff(st,"activeBorderB") or .376,ns.Eff(st,"activeBorderA") or 1); b.activeBorder=true
    elseif b.activeBorder then b.activeBorder=nil; local c=b.borderColor; if c and not b.circle then D.PaintEdges(b.edges,ns.Clamp(bar.borderSize or 1,0,8),c[1],c[2],c[3],c[4]) end end
    local style,gr,gg,gb=nil
    if not item.keep and not inactive then style,gr,gg,gb=ns.GlowFor(st,now) end
    D.SetGlow(b.glow,style,b.glowW,b.glowH,gr,gg,gb,bar,now)
    local pressed=bar.pressMirror and ns.pressed[m.name]
    if pressed and now-pressed<.2 then b.push:Show() else b.push:Hide() end
end
function D.PlaceIcon(b,f,bar,i,count,w,h)
    local sp=ns.Clamp(bar.spacing,0,20); local per=D.Grid(bar,count)
    local idx=i-1; local major,minor=idx%per,math.floor(idx/per)
    local rowUp=bar.rowGrowDirection=="UP"; local dir=bar.growDirection or "RIGHT"
    b:ClearAllPoints()
    if bar.verticalOrientation then
        local up=dir=="UP"; local x=minor*(w+sp); local y=major*(h+sp)
        if up then b:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",x,y) else b:SetPoint("TOPLEFT",f,"TOPLEFT",x,-y) end
        return
    end
    local inRow=math.min(per,count-minor*per); local y=minor*(h+sp)
    local x=major*(w+sp)
    if dir=="CENTER" then x=x+(f:GetWidth()-(inRow*(w+sp)-sp))/2 end
    if dir=="LEFT" then
        if rowUp then b:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-x,y) else b:SetPoint("TOPRIGHT",f,"TOPRIGHT",-x,-y) end
    elseif rowUp then b:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",x,y) else b:SetPoint("TOPLEFT",f,"TOPLEFT",x,-y) end
end
function ns.PaintBar(bar,visible,now,p)
    local f=ns.frames[bar.key]; if not f then return end
    local combat=ns.inCombat
    local allowed=p.enabled and p.cdmBars.enabled and bar.enabled
    local verdict=allowed and (ns.preview or ns.BarVerdict(bar))
    local castName
    if bar.barType=="focuskick" and verdict and not ns.preview then castName=D.FocusCast(bar); if not castName then verdict=false end end
    if bar.barType=="focuskick" then
        if castName and castName~=f.lastCast then D.PlayCastSound(bar.focusCastSoundKey) end
        f.lastCast=castName
    end
    if not verdict then f:Hide(); for _,b in ipairs(f.pool) do D.SetGlow(b.glow) end; return end
    local count=#visible; local placeholder=ns.preview and count==0
    if count==0 and not ns.preview then f:Hide(); return end
    if placeholder then count=3 end
    local alpha=bar.barOpacity or 1
    if bar.oocFadeEnabled and not combat then alpha=bar.oocFadeAlpha or .5 end
    if verdict=="mouseover" and not ns.preview then alpha=(MouseIsOver and MouseIsOver(f)) and alpha or 0 end
    f:SetAlpha(alpha)
    if ns.preview then f.label:Show(); f.preview:Show() else f.label:Hide(); f.preview:Hide() end
    if bar.barType=="focuskick" and bar.focusReminderEnabled and (castName or ns.preview) then
        local r,g,b=bar.focusReminderR or 1,bar.focusReminderG or .2,bar.focusReminderB or .2
        if bar.focusReminderUseAccent and E.GetAccentColor then r,g,b=E.GetAccentColor() end
        f.reminder:SetTextColor(r,g,b); f.reminder:SetText("Interrupt: "..(castName or "Preview")); f.reminder:Show()
    else f.reminder:Hide() end
    f:Show()
    local w,h=D.Cell(bar)
    local mouse=bar.showTooltip or ns.preview
    for i,b in ipairs(f.pool) do
        if i<=count then
            D.PlaceIcon(b,f,bar,i,count,w,h)
            D.PaintIcon(b,visible[i],bar,now,combat)
            b:EnableMouse(mouse and true or false); b:Show()
        else b.state=nil; D.SetGlow(b.glow); b:Hide() end
    end
end
-- Keybinds (Retail stable keybind cache): EUI, Blizzard and ElvUI action buttons, abbreviated.
local ABBREV={{"SHIFT%-","S"},{"CTRL%-","C"},{"ALT%-","A"},{"MOUSEWHEELUP","MwU"},{"MOUSEWHEELDOWN","MwD"},{"MIDDLEMOUSE","M3"},{"BUTTON","M"},
 {"NUMPADDIVIDE","N/"},{"NUMPADMULTIPLY","N*"},{"NUMPADMINUS","N-"},{"NUMPADPLUS","N+"},{"NUMPADDECIMAL","N."},{"NUMPAD","N"},
 {"BACKSPACE","BS"},{"CAPSLOCK","Cp"},{"PAGEDOWN","PD"},{"PAGEUP","PU"},{"ESCAPE","Esc"},{"INSERT","Ins"},{"DELETE","Del"},{"SPACE","Sp"},{"HOME","Hm"},{"END","End"},{"TAB","Tb"}}
function ns.AbbrevKey(key)
    if not key or key=="" then return nil end
    local t=key:upper(); for _,pair in ipairs(ABBREV) do t=t:gsub(pair[1],pair[2]) end
    return t
end
function ns.ActionSpellName(slot)
    if not slot or not GetActionInfo then return end
    local kind,id,sub,global=GetActionInfo(slot)
    if kind=="spell" then
        if type(global)=="number" and global>0 then local n=GetSpellInfo(global); if n then return n end end
        if id and (sub=="spell" or sub=="pet") and GetSpellName then local n=GetSpellName(id,sub); if n then return n end end
        return id and GetSpellInfo(id)
    elseif kind=="macro" and GetMacroSpell then return (GetMacroSpell(id))
    elseif kind=="item" and GetItemInfo then return (GetItemInfo(id)) end
end
local BLIZZ={{"ActionButton","ACTIONBUTTON"},{"MultiBarBottomLeftButton","MULTIACTIONBAR1BUTTON"},{"MultiBarBottomRightButton","MULTIACTIONBAR2BUTTON"},
 {"MultiBarRightButton","MULTIACTIONBAR3BUTTON"},{"MultiBarLeftButton","MULTIACTIONBAR4BUTTON"}}
local function ButtonSlot(button)
    if button.GetAction then local kind,id=button:GetAction(); if kind=="action" then return id end end
    local slot=button._state_action or button.action
    if type(slot)~="number" and button.GetAttribute then slot=button:GetAttribute("action") end
    return type(slot)=="number" and slot or nil
end
ns.ButtonSlot=ButtonSlot
-- EUI ActionBars, Blizzard and ElvUI action buttons (Bar Glows targets).
function ns.ForEachActionButton(fn)
    local ab=E._ModuleNS and E._ModuleNS.EllesmereUIActionBars
    for _,bar in pairs(ab and ab.bars or {}) do for _,button in ipairs(bar.buttons or {}) do fn(button) end end
    for _,def in ipairs(BLIZZ) do for i=1,12 do local b=_G[def[1]..i]; if b then fn(b) end end end
    for barIndex=1,10 do for i=1,12 do local b=_G["ElvUI_Bar"..barIndex.."Button"..i]; if b then fn(b) end end end
end
function ns.BuildKeybinds()
    local map={}; ns.keybinds=map
    local function Add(button,command)
        if not button then return end
        local slot=ButtonSlot(button); local name=slot and ns.ActionSpellName(slot)
        if not name and button.GetAction then local kind,id=button:GetAction(); if kind=="spell" then name=GetSpellInfo(id) end end
        if not name or map[name] then return end
        local key=command and GetBindingKey and GetBindingKey(command)
        if not key and button.config and button.config.keyBoundTarget and GetBindingKey then key=GetBindingKey(button.config.keyBoundTarget) end
        if not key and button.bindingAction and GetBindingKey then key=GetBindingKey(button.bindingAction) end
        if not key and button.GetName and button:GetName() and GetBindingKey then key=GetBindingKey("CLICK "..button:GetName()..":LeftButton") end
        if key then map[name]=ns.AbbrevKey(key) end
    end
    local ab=E._ModuleNS and E._ModuleNS.EllesmereUIActionBars
    for _,bar in pairs(ab and ab.bars or {}) do for _,button in ipairs(bar.buttons or {}) do Add(button) end end
    for _,def in ipairs(BLIZZ) do for i=1,12 do Add(_G[def[1]..i],def[2]..i) end end
    for barIndex=1,10 do for i=1,12 do Add(_G["ElvUI_Bar"..barIndex.."Button"..i]) end end
    for _,entries in pairs(ns.compiled) do for _,st in ipairs(entries) do
        local n=st.meta.name
        if n and not map[n] and GetBindingKey then local k=GetBindingKey("SPELL "..n); if k then map[n]=ns.AbbrevKey(k) end end
    end end
end
-- Unlock Mode: one mover per bar (Retail CDM_<key>) and its Element Options target.
-- Re-registered only when the set of bars/tracking bars or their names change.
function ns.RegisterUnlock()
    local sig={}
    for _,bar in ipairs(ns.Bars()) do sig[#sig+1]=bar.key.."="..tostring(bar.name) end
    local lists=ns.Lists(); for i,t in ipairs(lists and lists.tbb or {}) do sig[#sig+1]="T"..i.."="..tostring(t.name)..tostring(t.groupID) end
    sig=table.concat(sig,";")
    if sig==ns.unlockSig then return end
    ns.unlockSig=sig
    E._ELEMENT_SETTINGS_MAP=E._ELEMENT_SETTINGS_MAP or {}
    local elements={}
    for index,bar in ipairs(ns.Bars()) do
        local key=bar.key; local uk="CDM_"..key
        E._ELEMENT_SETTINGS_MAP[uk]={module=ADDON,page="CDM Bars",sectionName=bar.barType=="focuskick" and "FOCUSKICK OPTIONS" or "BAR LAYOUT",
            highlightText=bar.barType=="focuskick" and "Interrupt Spell" or "Icon Size",preSelectFn=function() ns.selectedBar=key end}
        if E.MakeUnlockElement then
            local isBuff=ns.IsBuffBar(bar)
            elements[#elements+1]=E.MakeUnlockElement({key=uk,label="CDM: "..(bar.name or key),group="Cooldown Manager",order=600+index,noResize=true,
                noAnchorTarget=isBuff or nil,
                getFrame=function() return ns.frames[key] end,
                getSize=function() local f=ns.frames[key]; if f then return f:GetWidth(),f:GetHeight() end; return 100,40 end,
                isHidden=function() local b=ns.BarByKey(key); local p=ns.Profile(); return not b or not p.enabled or not b.enabled or (b.anchorTo and b.anchorTo~="none") end,
                savePos=function(_,point,relPoint,x,y) if not point then return end; ns.Profile().positions[key]={point=point,relPoint=relPoint or point,x=x,y=y}
                    if not E._unlockActive then local b=ns.BarByKey(key); if b then D.Position(b) end end end,
                loadPos=function() return ns.Profile().positions[key] end,clearPos=function() ns.Profile().positions[key]=nil end,
                applyPos=function() local b=ns.BarByKey(key); if b then D.Position(b) end end})
        end
    end
    if ns.TrackingUnlockElements then ns.TrackingUnlockElements(elements) end
    if E.RegisterUnlockElements and #elements>0 then E:RegisterUnlockElements(elements,ADDON) end
end
-- Cursor-anchored bars follow the mouse (Retail anchorTo "mouse").
local follow=CreateFrame("Frame")
follow:SetScript("OnUpdate",function()
    if not ns.ready or not ns.anyMouse then return end
    for _,bar in ipairs(ns.Bars()) do if bar.anchorTo=="mouse" and ns.frames[bar.key] and ns.frames[bar.key]:IsShown() then
        local x,y=GetCursorPosition(); local s=UIParent:GetEffectiveScale(); local f=ns.frames[bar.key]
        f:ClearAllPoints(); f:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",x/s+(bar.anchorOffsetX or 0)+12,y/s+(bar.anchorOffsetY or 0)+12)
    end end
end)
E.GetCDMBarFrame=function(key) return ns.frames[key] end
E.LayoutCDMBar=function() ns.Layout(); ns.Update() end
EllesmereUICDM=ns
SLASH_EUI335CDM1="/ecdm"
SlashCmdList.EUI335CDM=function(message)
    if message=="show" then ns.Profile().enabled=true; ns.Apply()
    elseif message=="hide" then ns.Profile().enabled=false; ns.Apply()
    else if E.EnsureOptionsLoaded then E.EnsureOptionsLoaded() end; if E.ShowModule then E:ShowModule(ADDON) end end
end
