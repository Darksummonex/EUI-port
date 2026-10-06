local ADDON,ns=...
local E=EllesmereUI
if not ns.addon or not ns.D then return end
local D=ns.D
local white="Interface\\Buttons\\WHITE8X8"
local MEDIA="Interface\\AddOns\\EllesmereUI\\media\\textures\\"
local T={}
ns.T=T
ns.tbbFrames,ns.tbbGroupFrames,ns.tbbStates={},{},{}
-- Retail TBB_TEXTURES keys on the Core TGA copies.
ns.TBB_TEXTURES={none=white,blizzard="Interface\\TargetingFrame\\UI-StatusBar"}
ns.TBB_TEXTURE_NAMES={none="Solid",blizzard="Blizzard"}
ns.TBB_TEXTURE_ORDER={"none","blizzard"}
for _,k in ipairs({"atrocity","beautiful","divide","fade","fade-right","glass","gradient-bt","gradient-lr","gradient-rl","gradient-tb","matte","melli","plating","sheer","pixels-fill","soft-line","thin-line-bottom","thin-line-top"}) do
    ns.TBB_TEXTURES[k]=MEDIA..k..".tga"; ns.TBB_TEXTURE_NAMES[k]=k:gsub("-"," "):gsub("^%l",string.upper); ns.TBB_TEXTURE_ORDER[#ns.TBB_TEXTURE_ORDER+1]=k
end
local SPARK="Interface\\CastingBar\\UI-CastingBar-Spark"
local CLASSIC_BORDER="Interface\\CastingBar\\UI-CastingBar-Border"
local MAX_BARS,MAX_TICKS=20,10
function ns.TBBList() local l=ns.Lists(); return l and l.tbb or {} end
function ns.TBBGroup(gid)
    local p=ns.Profile(); p.tbbGroups=p.tbbGroups or {}
    local g=p.tbbGroups[gid]
    if not g then g={name="Tracking Bar Group "..gid,growDirection="DOWN",spacing=2,autoAdd=false}; p.tbbGroups[gid]=g end
    return g
end
function ns.AddTrackedBar(spellID,name)
    local list=ns.TBBList(); if #list>=MAX_BARS then return end
    local cfg=ns.Fill({spellID=spellID or 0,name=name},ns.TBB_DEFAULTS)
    for gid,g in pairs(ns.Profile().tbbGroups or {}) do if g.autoAdd then cfg.groupID=gid end end
    if cfg.useClassColor then local _,c=UnitClass("player"); local cc=RAID_CLASS_COLORS and RAID_CLASS_COLORS[c]; if cc then cfg.fillR,cfg.fillG,cfg.fillB=cc.r,cc.g,cc.b end end
    list[#list+1]=cfg; return cfg,#list
end
function T.NewBar(i)
    local f=CreateFrame("Frame","EUI335TrackingBar"..i,UIParent); f:SetClampedToScreen(true); f:SetMovable(true); f.index=i
    f.bg=f:CreateTexture(nil,"BACKGROUND"); f.bg:SetTexture(white)
    -- Hand-sized fill texture: Wrath StatusBars cannot reverse their fill.
    f.bar=CreateFrame("Frame",nil,f); f.fill=f.bar:CreateTexture(nil,"ARTWORK"); f.fill:SetTexture(white)
    f.icon=f:CreateTexture(nil,"ARTWORK"); f.icon:SetTexCoord(.08,.92,.08,.92)
    f.iconEdges=D.Edges(f)
    f.edgeHost=CreateFrame("Frame",nil,f); f.edgeHost:SetAllPoints(f.bar); f.edgeHost:SetFrameLevel(f.bar:GetFrameLevel()+2)
    f.edges=D.Edges(f.edgeHost)
    f.host=CreateFrame("Frame",nil,f); f.host:SetAllPoints(f.bar); f.host:SetFrameLevel(f.bar:GetFrameLevel()+3)
    f.spark=f.host:CreateTexture(nil,"OVERLAY"); f.spark:SetTexture(SPARK); f.spark:SetBlendMode("ADD"); f.spark:Hide()
    f.classic=f.host:CreateTexture(nil,"OVERLAY"); f.classic:SetTexture(CLASSIC_BORDER); f.classic:Hide()
    f.name=D.Text(f.host,11); f.timer=D.Text(f.host,11); f.stacks=D.Text(f.host,11)
    f.ticks={}
    for t=1,MAX_TICKS do local tex=f.host:CreateTexture(nil,"OVERLAY"); tex:SetTexture(white); tex:Hide(); f.ticks[t]=tex end
    f.glow=CreateFrame("Frame",nil,f.host); f.glow:SetAllPoints(f.bar)
    f:Hide(); return f
end
function T.Frame(i) local f=ns.tbbFrames[i]; if not f then f=T.NewBar(i); ns.tbbFrames[i]=f end; return f end
function T.GroupFrame(gid)
    local g=ns.tbbGroupFrames[gid]
    if not g then g=CreateFrame("Frame","EUI335TrackingGroup"..gid,UIParent); g:SetClampedToScreen(true); g:SetMovable(true); ns.tbbGroupFrames[gid]=g end
    return g
end
function T.Fill(cfg)
    if cfg.useClassColor then
        local _,c=UnitClass("player"); local cc=RAID_CLASS_COLORS and RAID_CLASS_COLORS[c]
        if cc then return cc.r,cc.g,cc.b,cfg.fillA or 1 end
    end
    return cfg.fillR or .05,cfg.fillG or .82,cfg.fillB or .62,cfg.fillA or 1
end
function T.Texture(key) return ns.TBB_TEXTURES[key or "none"] or (type(key)=="string" and key:find("\\",1,true) and key) or white end
function T.Position(f,key,i)
    local p=ns.Profile().positions[key]; f:ClearAllPoints()
    if p then f:SetPoint(p.point or "CENTER",UIParent,p.relPoint or p.point or "CENTER",p.x or 0,p.y or 0)
    else f:SetPoint("BOTTOM",UIParent,"BOTTOM",340,300-(i-1)*30) end
end
function T.Members(gid)
    local out={}
    for i,cfg in ipairs(ns.TBBList()) do if (cfg.groupID or 0)==gid and cfg.enabled~=false then out[#out+1]=i end end
    return out
end
function T.Resolve(cfg)
    local id=tonumber(cfg.spellID) or 0
    local preset=cfg.preset and ns.BUFF_PRESET_BY_KEY[cfg.preset]
    if preset then
        local names={}; for _,x in ipairs(preset.ids) do local n=GetSpellInfo(x); if n then names[n]=true end end
        return {name=cfg.name or preset.name,names=names,icon=preset.icon or select(3,GetSpellInfo(preset.ids[1]))}
    end
    if id<=0 then return end
    local name,_,icon=GetSpellInfo(id); if not name then return end
    local meta={name=name,auraName=name,id=id,icon=icon,label=cfg.name~="New Bar" and cfg.name or name}
    if cfg.trackType=="cooldown" then
        local book=ns.spells[name] or ns.petSpells[name]
        if not book or book.passive then return end
        meta.slot,meta.book,meta.icon=book.slot,book.book,book.icon or icon
    end
    return meta
end
function ns.LayoutTrackingBars()
    local p=ns.Profile(); local list=ns.TBBList(); local classic=p.useClassicStyleBars
    ns.tbbStates={}
    for i=1,math.min(MAX_BARS,#list) do
        local cfg,f=list[i],T.Frame(i)
        ns.tbbStates[i]={cfg=cfg,meta=T.Resolve(cfg),frame=f}
        local w,h=ns.Clamp(cfg.width,40,800),ns.Clamp(cfg.height,4,80)
        local vertical=cfg.verticalOrientation
        local iconOn=cfg.iconDisplay and cfg.iconDisplay~="none"; local isz=iconOn and h or 0
        D.Size(f,vertical and h or w,vertical and w or h)
        f.vertical,f.reverse=vertical and true or false,cfg.reverseFill and true or false
        f.barW,f.barH=vertical and h or w-isz,vertical and w-isz or h
        f:SetFrameStrata(cfg.barStrata or "MEDIUM"); f:SetAlpha(ns.Clamp(cfg.opacity,0,1))
        f.icon:ClearAllPoints(); f.bar:ClearAllPoints()
        if iconOn then
            D.Size(f.icon,isz,isz); f.icon:Show()
            if vertical then
                if cfg.iconDisplay=="right" then f.icon:SetPoint("TOP",f,"TOP",cfg.iconX or 0,cfg.iconY or 0); f.bar:SetPoint("TOPLEFT",f,"TOPLEFT",0,-isz); f.bar:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",0,0)
                else f.icon:SetPoint("BOTTOM",f,"BOTTOM",cfg.iconX or 0,cfg.iconY or 0); f.bar:SetPoint("TOPLEFT",f,"TOPLEFT",0,0); f.bar:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",0,isz) end
            elseif cfg.iconDisplay=="right" then f.icon:SetPoint("RIGHT",f,"RIGHT",cfg.iconX or 0,cfg.iconY or 0); f.bar:SetPoint("TOPLEFT",f,"TOPLEFT",0,0); f.bar:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-isz,0)
            else f.icon:SetPoint("LEFT",f,"LEFT",cfg.iconX or 0,cfg.iconY or 0); f.bar:SetPoint("TOPLEFT",f,"TOPLEFT",isz,0); f.bar:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",0,0) end
        else f.icon:Hide(); f.bar:SetAllPoints(f) end
        local ib=ns.Clamp(cfg.iconBorderSize or 0,0,4)
        for k,t in ipairs(f.iconEdges) do t:ClearAllPoints() end
        local e=f.iconEdges
        e[1]:SetPoint("TOPLEFT",f.icon,"TOPLEFT"); e[1]:SetPoint("TOPRIGHT",f.icon,"TOPRIGHT")
        e[2]:SetPoint("BOTTOMLEFT",f.icon,"BOTTOMLEFT"); e[2]:SetPoint("BOTTOMRIGHT",f.icon,"BOTTOMRIGHT")
        e[3]:SetPoint("TOPLEFT",f.icon,"TOPLEFT"); e[3]:SetPoint("BOTTOMLEFT",f.icon,"BOTTOMLEFT")
        e[4]:SetPoint("TOPRIGHT",f.icon,"TOPRIGHT"); e[4]:SetPoint("BOTTOMRIGHT",f.icon,"BOTTOMRIGHT")
        D.PaintEdges(e,iconOn and ib or 0,0,0,0,1)
        f.bg:ClearAllPoints(); f.bg:SetAllPoints(f.bar); f.bg:SetVertexColor(cfg.bgR or 0,cfg.bgG or 0,cfg.bgB or 0,cfg.bgA or .4)
        local fill=f.fill; fill:SetTexture(T.Texture(cfg.texture)); fill:ClearAllPoints()
        local side=vertical and (f.reverse and "TOP" or "BOTTOM") or (f.reverse and "RIGHT" or "LEFT")
        if vertical then fill:SetPoint(side.."LEFT",f.bar,side.."LEFT"); fill:SetPoint(side.."RIGHT",f.bar,side.."RIGHT")
        else fill:SetPoint("TOP"..side,f.bar,"TOP"..side); fill:SetPoint("BOTTOM"..side,f.bar,"BOTTOM"..side) end
        local fr,fg,fb,fa=T.Fill(cfg)
        fill:SetVertexColor(fr,fg,fb,fa)
        if cfg.gradientEnabled and fill.SetGradientAlpha then
            fill:SetGradientAlpha(cfg.gradientDir or "HORIZONTAL",fr,fg,fb,fa,cfg.gradientR or 1,cfg.gradientG or 1,cfg.gradientB or 1,cfg.gradientA or 1)
        end
        for k,t in ipairs(f.edges) do t:ClearAllPoints() end
        e=f.edges
        e[1]:SetPoint("TOPLEFT",f,"TOPLEFT"); e[1]:SetPoint("TOPRIGHT",f,"TOPRIGHT")
        e[2]:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT"); e[2]:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT")
        e[3]:SetPoint("TOPLEFT",f,"TOPLEFT"); e[3]:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT")
        e[4]:SetPoint("TOPRIGHT",f,"TOPRIGHT"); e[4]:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT")
        D.PaintEdges(e,classic and 0 or ns.Clamp(cfg.borderSize or 1,0,8),cfg.borderR or 0,cfg.borderG or 0,cfg.borderB or 0,cfg.borderA or 1)
        if classic then f.classic:ClearAllPoints(); f.classic:SetPoint("TOPLEFT",f.bar,"TOPLEFT",-w*.105,h*1.1); f.classic:SetPoint("BOTTOMRIGHT",f.bar,"BOTTOMRIGHT",w*.105,-h*1.1); f.classic:Show() else f.classic:Hide() end
        D.Size(f.spark,16,h*2.2)
        D.Font(f.name,cfg.nameSize or 11); f.name:SetTextColor(cfg.nameTextR or 1,cfg.nameTextG or 1,cfg.nameTextB or 1,cfg.nameTextA or .9)
        D.PlaceText(f.name,f.host,cfg.namePosition or "left",(cfg.nameX or 0)+2,cfg.nameY or 0)
        D.Font(f.timer,cfg.timerSize or 11); f.timer:SetTextColor(cfg.timerTextR or 1,cfg.timerTextG or 1,cfg.timerTextB or 1,cfg.timerTextA or .9)
        D.PlaceText(f.timer,f.host,cfg.timerPosition or "right",(cfg.timerX or 0)-2,cfg.timerY or 0)
        D.Font(f.stacks,cfg.stacksSize or 11); f.stacks:SetTextColor(cfg.stacksTextR or 1,cfg.stacksTextG or 1,cfg.stacksTextB or 1,cfg.stacksTextA or .9)
        D.PlaceText(f.stacks,f.host,cfg.stacksPosition or "center",cfg.stacksX or 0,cfg.stacksY or 0)
        T.LayoutTicks(f,cfg,f.barW,f.barH)
        local meta=ns.tbbStates[i].meta
        f.name:SetText(cfg.showName~=false and (meta and (meta.label or meta.name) or cfg.name or "Tracking Bar") or "")
        f.cfg=cfg; f.smooth=p.tbbSmooth~=false; f.lastValue=nil
        f:SetScript("OnUpdate",f.smooth and T.Animate or nil)
    end
    for i=#list+1,#ns.tbbFrames do ns.tbbFrames[i]:Hide(); ns.tbbFrames[i]:SetScript("OnUpdate",nil) end
    T.Arrange()
end
-- Stack ticks (Retail "Ticks at Stacks") on a stack-based bar with a max.
function T.LayoutTicks(f,cfg,w,h)
    local values={}
    if cfg.stackBasedBar and cfg.stackThresholdMaxEnabled then for v in tostring(cfg.stackThresholdTicks or ""):gmatch("%d+") do values[#values+1]=tonumber(v) end end
    local max=ns.Clamp(cfg.stackThresholdMax or 10,1,100)
    for t,tex in ipairs(f.ticks) do
        local v=values[t]
        if v and v>0 and v<max then
            tex:ClearAllPoints(); tex:SetVertexColor(cfg.stackThresholdTickR or 1,cfg.stackThresholdTickG or 1,cfg.stackThresholdTickB or 1,cfg.stackThresholdTickA or 1)
            if cfg.verticalOrientation then D.Size(tex,w,1); tex:SetPoint("BOTTOM",f.bar,"BOTTOM",0,h*v/max)
            else D.Size(tex,1,h); tex:SetPoint("LEFT",f.bar,"LEFT",w*v/max,0) end
            tex:Show()
        else tex:Hide() end
    end
end
function T.Arrange()
    local list=ns.TBBList(); local used={}
    for i,cfg in ipairs(list) do
        local f=ns.tbbFrames[i]
        if f and (cfg.groupID or 0)==0 then T.Position(f,"TBB_"..i,i) end
        if (cfg.groupID or 0)>0 then used[cfg.groupID]=true end
    end
    for gid,g in pairs(ns.tbbGroupFrames) do if not used[gid] then g:Hide() end end
    for gid in pairs(used) do
        local g=T.GroupFrame(gid); local members=T.Members(gid); local first=members[1] or 1
        local cfg=list[first]; local w,h=ns.Clamp(cfg and cfg.width or 270,40,800),ns.Clamp(cfg and cfg.height or 24,4,80)
        if cfg and cfg.verticalOrientation then w,h=h,w end
        D.Size(g,w,h); T.Position(g,"TBBG_"..gid,first); g:Show()
    end
end
-- Grouped bars chain inside their group anchor; hidden members close the gap.
function T.Chain()
    local list=ns.TBBList(); local cursor={}
    for i,cfg in ipairs(list) do
        local gid=cfg.groupID or 0; local f=ns.tbbFrames[i]
        if gid>0 and f and f:IsShown() then
            local g=T.GroupFrame(gid); local grp=ns.TBBGroup(gid); local sp=ns.Clamp(grp.spacing or 2,0,40)
            local prev=cursor[gid]; local dir=grp.growDirection or "DOWN"
            f:ClearAllPoints()
            if not prev then f:SetPoint("CENTER",g,"CENTER",0,0)
            elseif dir=="UP" then f:SetPoint("BOTTOM",prev,"TOP",0,sp)
            elseif dir=="RIGHT" then f:SetPoint("LEFT",prev,"RIGHT",sp,0)
            elseif dir=="LEFT" then f:SetPoint("RIGHT",prev,"LEFT",-sp,0)
            else f:SetPoint("TOP",prev,"BOTTOM",0,-sp) end
            cursor[gid]=f
        end
    end
end
function T.State(st,now)
    local cfg,m=st.cfg,st.meta
    st.active,st.remaining,st.duration,st.count,st.expires=false,0,0,0,0
    if not m then return end
    if cfg.trackType=="cooldown" then
        local s,d,en=GetSpellCooldown(m.slot,m.book); s,d=tonumber(s) or 0,tonumber(d) or 0
        if d>1.5 then st.duration=d; st.expires=s+d; st.remaining=math.max(0,s+d-now); st.active=st.remaining>0 end
        st.icon=m.icon; return
    end
    local a=ns.FindAura(cfg.unit or "player",cfg.filter=="HARMFUL" and "HARMFUL" or "HELPFUL",m.id,m.auraName,m.names,cfg.ownOnly,now)
    st.aura=a; st.icon=a and a.icon or m.icon
    if a then st.active=true; st.count=a.count or 0; st.duration=a.duration or 0; st.expires=a.expires or 0; st.remaining=st.duration>0 and math.max(0,a.expires-now) or 0 end
end
function T.Value(f,st,now)
    local cfg=st.cfg; local remaining=st.duration>0 and math.max(0,st.expires-now) or 0
    if cfg.stackBasedBar then return math.min(1,(st.count or 0)/ns.Clamp(cfg.stackThresholdMax or 10,1,100)),remaining end
    if not st.active then
        if ns.preview then return .65,0 end
        return (cfg.trackType=="cooldown" and cfg.fillUp) and 1 or 0,0
    end
    if st.duration<=0 then return 1,0 end
    local v=remaining/st.duration
    if cfg.trackType=="cooldown" and cfg.fillUp then v=1-v end
    return v,remaining
end
function T.TimerText(cfg,t)
    if t<=0 then return "" end
    if cfg.decimals and t<(cfg.decimalThreshold or 5) then return string.format("%.1f",t) end
    return D.TimeText(t)
end
function T.SetValue(f,v)
    if f.lastValue==v then return end
    f.lastValue=v; f.value=v
    local fill=f.fill
    if v<=0 then fill:Hide(); return end
    if f.vertical then
        fill:SetHeight(math.max(.01,f.barH*v))
        if f.reverse then fill:SetTexCoord(0,1,0,v) else fill:SetTexCoord(0,1,1-v,1) end
    else
        fill:SetWidth(math.max(.01,f.barW*v))
        if f.reverse then fill:SetTexCoord(1-v,1,0,1) else fill:SetTexCoord(0,v,0,1) end
    end
    fill:Show()
end
function T.Paint(f,st,now)
    local cfg=st.cfg; local v,remaining=T.Value(f,st,now)
    T.SetValue(f,v)
    local text=cfg.showTimer and T.TimerText(cfg,remaining) or ""
    if f.timer:GetText()~=text then f.timer:SetText(text) end
    if cfg.showSpark and not f.vertical and st.active and v>0 and v<1 then
        f.spark:ClearAllPoints(); f.spark:SetPoint("CENTER",f.bar,"LEFT",f.barW*(f.reverse and (1-v) or v),0)
        f.spark:Show()
    else f.spark:Hide() end
end
function T.Animate(f)
    local st=f.state; if not st or not st.active then return end
    T.Paint(f,st,GetTime())
end
function ns.UpdateTrackingBars(now)
    local p=ns.Profile(); local allowed=p.enabled and p.cdmBars.enabled
    for i,st in ipairs(ns.tbbStates) do
        local cfg,f=st.cfg,st.frame; f.state=st
        T.State(st,now)
        local show=allowed and cfg.enabled~=false and st.meta~=nil
        if show and not ns.preview then
            if cfg.onlyInCombat and not ns.inCombat then show=false end
            if show and cfg.hideWhenInactive and not st.active then show=false end
            if show and not ns.BarVerdict(cfg) then show=false end
        end
        if ns.preview and allowed and cfg.enabled~=false then show=true end
        if show then
            f.icon:SetTexture(st.icon or (st.meta and st.meta.icon) or "Interface\\Icons\\INV_Misc_QuestionMark")
            local c=st.count or 0
            f.stacks:SetText((c>1 or cfg.stackBasedBar and c>0) and tostring(c) or "")
            local r,g,b,a=T.Fill(cfg)
            if cfg.stackThresholdEnabled and c>=(cfg.stackThreshold or 5) then r,g,b,a=cfg.stackThresholdR or .8,cfg.stackThresholdG or .1,cfg.stackThresholdB or .1,cfg.stackThresholdA or 1 end
            if not cfg.gradientEnabled then f.fill:SetVertexColor(r,g,b,a) end
            T.Paint(f,st,now)
            local pandemic=cfg.pandemicGlow and st.active and st.duration>0 and (st.expires-now)<=st.duration*.3 and (not p.glowsOnlyInCombat or ns.inCombat)
            if pandemic then
                local style=cfg.pandemicGlowStyle or 1; if style~=1 and style~=4 then style=1 end
                local gc=f.glowCfg or {glowHost="bar"}; f.glowCfg=gc
                gc.pixelGlowLines,gc.pixelGlowThickness,gc.pixelGlowSpeed=cfg.pandemicGlowLines,cfg.pandemicGlowThickness,cfg.pandemicGlowSpeed
                D.SetGlow(f.glow,style,f.barW,f.barH,cfg.pandemicGlowR,cfg.pandemicGlowG,cfg.pandemicGlowB,gc,now)
            else D.SetGlow(f.glow) end
            f:Show()
        else f:Hide(); D.SetGlow(f.glow) end
    end
    T.Chain()
end
-- Unlock Mode: TBB_<i> per independent bar, TBBG_<gid> per group (Retail keys).
function ns.TrackingUnlockElements(elements)
    if not E.MakeUnlockElement then return end
    local M=E._ELEMENT_SETTINGS_MAP
    for i=1,MAX_BARS do
        local idx=i; local key="TBB_"..i
        M[key]={module=ADDON,page="Tracking Bars",sectionName="BAR LAYOUT",highlightText="Width",preSelectFn=function() ns.selectedTBB=idx end}
        elements[#elements+1]=E.MakeUnlockElement({key=key,label="Tracking Bar "..i,group="Cooldown Manager",order=650+i,noResize=true,noAnchorTarget=true,
            getFrame=function() return ns.tbbFrames[idx] end,
            getSize=function() local f=ns.tbbFrames[idx]; if f then return f:GetWidth(),f:GetHeight() end; return 270,24 end,
            isHidden=function() local c=ns.TBBList()[idx]; return not c or (c.groupID or 0)>0 or not ns.Profile().enabled end,
            savePos=function(_,point,relPoint,x,y) if point then ns.Profile().positions[key]={point=point,relPoint=relPoint or point,x=x,y=y}; if not E._unlockActive then T.Arrange() end end end,
            loadPos=function() return ns.Profile().positions[key] end,clearPos=function() ns.Profile().positions[key]=nil end,
            applyPos=function() T.Arrange() end})
    end
    for gid=1,4 do
        local g=gid; local key="TBBG_"..gid
        M[key]={module=ADDON,page="Tracking Bars",sectionName="GROUP SETTINGS",highlightText="Grow Direction",preSelectFn=function() local m=T.Members(g); ns.selectedTBB=m[1] or ns.selectedTBB end}
        elements[#elements+1]=E.MakeUnlockElement({key=key,label="Tracking Bar Group "..gid,group="Cooldown Manager",order=670+gid,noResize=true,noAnchorTarget=true,
            getFrame=function() return ns.tbbGroupFrames[g] end,
            getSize=function() local f=ns.tbbGroupFrames[g]; if f then return f:GetWidth(),f:GetHeight() end; return 270,24 end,
            isHidden=function() return #T.Members(g)==0 or not ns.Profile().enabled end,
            savePos=function(_,point,relPoint,x,y) if point then ns.Profile().positions[key]={point=point,relPoint=relPoint or point,x=x,y=y}; if not E._unlockActive then T.Arrange() end end end,
            loadPos=function() return ns.Profile().positions[key] end,clearPos=function() ns.Profile().positions[key]=nil end,
            applyPos=function() T.Arrange() end})
    end
end
