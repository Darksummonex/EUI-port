-- Retail "Extras" on native Wrath frames: Main Tank frames (raid MAINTANK /
-- MAINASSIST assignments), party/raid pet frames, friendly boss frames and the
-- Healer Mana text display. Secure frames are created once, before combat.
local ADDON_NAME,ns=...
local E=EllesmereUI
if not ns.addon then return end
ns.extraKinds={tank=true,pet=true,boss=true}
local configKey={tank="tankFrames",pet="petFrames",boss="friendlyBoss"}
local function ExtraConfig(kind) local p=ns.GetSettings(); return p and p[configKey[kind]] end
local function ExtraBase(kind)
    if GetNumRaidMembers()>0 or kind=="tank" then return ns.GetSettings("raid") end
    return ns.GetSettings("party")
end
-- Extras draw with the current group's look; only their size is offset.
local proxies={}
function ns.ExtraSettings(kind)
    local proxy=proxies[kind]
    if not proxy then
        proxy=setmetatable({},{__index=function(_,key)
            local base=ExtraBase(kind); if not base then return nil end
            if key=="frameWidth" or key=="frameHeight" then
                local cfg=ExtraConfig(kind) or {}
                local wide=key=="frameWidth"
                local value=(tonumber(base[key]) or (wide and 125 or 52))+(tonumber(cfg[wide and "extraWidth" or "extraHeight"]) or 0)
                return math.max(wide and 40 or 20,math.min(wide and 300 or 120,value))
            end
            return base[key]
        end,__newindex=function() end})
        proxies[kind]=proxy
    end
    return proxy
end
local healerTrees={PRIEST={[1]=true,[2]=true},PALADIN={[1]=true},SHAMAN={[3]=true},DRUID={[3]=true}}
-- LFD role first; outside LFD the primary talent tree decides.
function ns.IsHealerSpec()
    if ns.UnitRole("player")=="healer" then return true end
    local _,class=UnitClass("player"); local trees=healerTrees[class]
    if not trees or not GetNumTalentTabs then return false end
    local best,most=nil,0
    for i=1,(GetNumTalentTabs() or 0) do local _,_,points=GetTalentTabInfo(i); points=tonumber(points) or 0; if points>most then best,most=i,points end end
    return best and trees[best] or false
end
ns.extraHolders,ns.extraHeaders,ns.bossButtons,ns.extraPreviews,ns.extraPreviewHolders={},{},{},{},{}
local previewCounts={tank=2,pet=3,boss=1}
local previewNames={tank="Main Tank ",pet="Pet ",boss="Boss "}
local function NewHolder(kind)
    local holder=CreateFrame("Frame","EUI335RaidHolder_"..kind,UIParent,"SecureHandlerStateTemplate")
    holder:SetFrameStrata("LOW"); holder._euiKind=kind; ns.extraHolders[kind]=holder
    local preview=CreateFrame("Frame",nil,UIParent); preview:SetAllPoints(holder); preview:Hide(); ns.extraPreviewHolders[kind]=preview
    ns.extraPreviews[kind]={}
    for i=1,previewCounts[kind] do
        local b=CreateFrame("Button",nil,preview); b._euiKind=kind; b._euiPreview=i; b._euiPreviewName=previewNames[kind]..i
        b._euiNoRole=kind~="tank"; ns.InitButton(b); b:EnableMouse(false); ns.extraPreviews[kind][i]=b
    end
    return holder
end
local function CreateExtras()
    local tank=NewHolder("tank")
    local h=CreateFrame("Frame","EUI335RaidHeader_tank",tank,"SecureGroupHeaderTemplate"); h._euiKind="tank"
    h:Hide(); h:SetAttribute("template","EUI335RaidUnitTemplate"); h:SetAttribute("showRaid",true); h:SetAttribute("showParty",false)
    h:SetAttribute("groupFilter","MAINTANK"); h:SetAttribute("sortMethod","INDEX"); h:SetAttribute("unitsPerColumn",5); h:SetAttribute("maxColumns",1)
    ns.SetHeaderAnchors(h,"TOP","LEFT")
    h:SetAttribute("startingIndex",-4); h:Show(); h:Hide(); h:SetAttribute("startingIndex",1)
    ns.extraHeaders.tank=h
    local pet=NewHolder("pet")
    local ph=CreateFrame("Frame","EUI335RaidHeader_pet",pet,"SecureGroupPetHeaderTemplate"); ph._euiKind="pet"; ph._euiPet=true
    ph:Hide(); ph:SetAttribute("template","EUI335RaidUnitTemplate"); ph:SetAttribute("showRaid",true); ph:SetAttribute("showParty",true); ph:SetAttribute("showPlayer",true)
    ph:SetAttribute("sortMethod","INDEX"); ph:SetAttribute("unitsPerColumn",5); ph:SetAttribute("maxColumns",4)
    -- Twenty pet buttons cover a 25-player raid's usual pets; allocated before combat.
    -- Twenty slots make four columns, so columnAnchorPoint must already be valid.
    ns.SetHeaderAnchors(ph,"TOP","LEFT"); ph:SetAttribute("columnSpacing",0)
    ph:SetAttribute("startingIndex",-19); ph:Show(); ph:Hide(); ph:SetAttribute("startingIndex",1)
    ns.extraHeaders.pet=ph
    local boss=NewHolder("boss")
    for i=1,4 do
        local b=CreateFrame("Button","EUI335RaidBoss"..i,boss,"EUI335RaidUnitTemplate")
        b:SetAttribute("toggleForVehicle",false); b:SetAttribute("unit","boss"..i); ns.bossButtons[i]=b
    end
end
local function Clamp(v,lo,hi,default) return math.max(lo,math.min(hi,tonumber(v) or default)) end
-- Slot origin for index i (0-based) along the configured direction.
local function Slot(i,horizontal,w,h,spacing,columns)
    local per=5; local col,row=math.floor(i/per),i%per
    if columns==1 then col,row=0,i end
    if horizontal then return row*(w+spacing),-col*(h+spacing) end
    return col*(w+spacing),-row*(h+spacing)
end
local function HolderSize(kind,count,columns)
    local c=ns.ExtraSettings(kind); local cfg=ExtraConfig(kind) or {}
    local w,h=c.frameWidth,c.frameHeight; local spacing=Clamp(c.cellSpacing,0,20,3)
    local rows=math.min(count,5); columns=columns or 1
    if cfg.horizontal then return rows*w+(rows-1)*spacing,columns*h+(columns-1)*spacing,w,h,spacing end
    return columns*w+(columns-1)*spacing,rows*h+(rows-1)*spacing,w,h,spacing
end
local defaultsXY={tank={-700,230},pet={-480,-200},boss={300,230}}
local function LayoutPreview(kind,active,horizontal,w,h,spacing)
    local holder=ns.extraPreviewHolders[kind]
    if ns.preview and active then
        for i,b in ipairs(ns.extraPreviews[kind]) do
            local x,y=Slot(i-1,horizontal,w,h,spacing,1)
            ns.LayoutButton(b); b:ClearAllPoints(); b:SetPoint("TOPLEFT",holder,"TOPLEFT",x,y); b:Show(); ns.UpdateFrame(b,true)
        end
        holder:SetFrameStrata(ns.Strata(ns.ExtraSettings(kind))); holder:Show()
    else holder:Hide() end
end
function ns.ExtraActive(kind)
    local p=ns.GetSettings(); if not p or not p.enabled then return false end
    if kind=="tank" then return p.tankFrames.enabled and true or false end
    if kind=="pet" then return (p.petFrames.party or p.petFrames.raid) and true or false end
    if kind=="boss" then local d=p.friendlyBoss.display; return d=="always" or (d=="healers" and ns.IsHealerSpec()) end
    if kind=="healerMana" then return p.healerMana.mode~="none" end
end
local function LayoutHeader(h,kind,horizontal,spacing,columns,attrs)
    h:ClearAllPoints(); h:SetPoint("TOPLEFT",ns.extraHolders[kind],"TOPLEFT",0,0)
    ns.HeaderAnchors(attrs,horizontal and "LEFT" or "TOP",horizontal and "TOP" or "LEFT")
    attrs.xOffset=horizontal and spacing or 0; attrs.yOffset=horizontal and 0 or -spacing
    attrs.columnSpacing=spacing; attrs.maxColumns=columns
    ns.ConfigureHeader(h,attrs,true)
    for _,b in ipairs({h:GetChildren()}) do if b._euiKind then ns.LayoutButton(b); ns.ApplyBindings(b) end end
end
function ns.ApplyExtras()
    if InCombatLockdown() then ns.DeferApply(); return end
    if not ns.extraHolders.tank then CreateExtras() end
    local p=ns.GetSettings()
    -- Main tanks: native raid MAINTANK (and optionally MAINASSIST) assignments.
    local cfg=p.tankFrames; local active=ns.ExtraActive("tank")
    local width,height,w,h,spacing=HolderSize("tank",5)
    local holder=ns.extraHolders.tank; ns.Size(holder,width,height); holder:SetFrameStrata(ns.Strata(ns.ExtraSettings("tank")))
    ns.PositionHolder(holder,"tank",defaultsXY.tank[1],defaultsXY.tank[2])
    LayoutHeader(ns.extraHeaders.tank,"tank",cfg.horizontal,spacing,1,{groupFilter=cfg.includeAssist and "MAINTANK,MAINASSIST" or "MAINTANK"})
    RegisterStateDriver(holder,"visibility",active and "[group:raid] show; hide" or "hide")
    LayoutPreview("tank",active,cfg.horizontal,w,h,spacing)
    -- Pets: party pets (with your own) and/or raid pets.
    cfg=p.petFrames; active=ns.ExtraActive("pet")
    local columns=cfg.raid and 4 or 1
    width,height,w,h,spacing=HolderSize("pet",5,columns)
    holder=ns.extraHolders.pet; ns.Size(holder,width,height); holder:SetFrameStrata(ns.Strata(ns.ExtraSettings("pet")))
    ns.PositionHolder(holder,"pet",defaultsXY.pet[1],defaultsXY.pet[2])
    local party=cfg.party and true or false
    LayoutHeader(ns.extraHeaders.pet,"pet",cfg.horizontal,spacing,columns,{showParty=party,showPlayer=party,showRaid=cfg.raid and true or false})
    local driver="hide"
    if active then driver=cfg.party and cfg.raid and "[group:raid] show; [group:party] show; hide" or cfg.raid and "[group:raid] show; hide" or "[group:raid] hide; [group:party] show; hide" end
    RegisterStateDriver(holder,"visibility",driver)
    LayoutPreview("pet",active,cfg.horizontal,w,h,spacing)
    -- Friendly bosses (healable encounter NPCs such as Valithria Dreamwalker).
    cfg=p.friendlyBoss; active=ns.ExtraActive("boss")
    width,height,w,h,spacing=HolderSize("boss",4)
    holder=ns.extraHolders.boss; ns.Size(holder,width,height); holder:SetFrameStrata(ns.Strata(ns.ExtraSettings("boss")))
    ns.PositionHolder(holder,"boss",defaultsXY.boss[1],defaultsXY.boss[2])
    RegisterStateDriver(holder,"visibility",active and "show" or "hide")
    for i,b in ipairs(ns.bossButtons) do
        local x,y=Slot(i-1,cfg.horizontal,w,h,spacing,1)
        b:ClearAllPoints(); b:SetPoint("TOPLEFT",holder,"TOPLEFT",x,y); ns.LayoutButton(b); ns.ApplyBindings(b)
        RegisterStateDriver(b,"visibility",active and ("[target=boss"..i..",help] show; hide") or "hide")
    end
    LayoutPreview("boss",active,cfg.horizontal,w,h,spacing)
    ns.LayoutHealerMana()
end
function ns.HideExtraPreviews()
    for _,f in pairs(ns.extraPreviewHolders) do f:Hide() end
    if ns.healerMana then ns.healerMana.preview=false end
end
-------------------------------------------------------------------------------
-- Healer Mana: one text row per group healer (Retail Extras display).
-------------------------------------------------------------------------------
local manaClasses={PRIEST=true,PALADIN=true,SHAMAN=true,DRUID=true}
local MAX_ROWS=10
local function ManaFrame()
    local f=ns.healerMana
    if not f then
        f=CreateFrame("Frame","EUI335RaidHealerMana",UIParent); f:SetFrameStrata("MEDIUM"); f:EnableMouse(false); f.rows={}
        for i=1,MAX_ROWS do f.rows[i]=f:CreateFontString(nil,"OVERLAY"); ns.Font(f.rows[i],12); f.rows[i]:Hide() end
        ns.healerMana=f
    end
    return f
end
function ns.LayoutHealerMana()
    local f=ManaFrame(); local cfg=ns.GetSettings().healerMana
    local size=Clamp(cfg.textSize,8,24,12); local spacing=Clamp(cfg.spacing,0,12,2)
    ns.Size(f,170,MAX_ROWS*(size+spacing))
    ns.PositionHolder(f,"healerMana",-700,-60)
    local up=cfg.growth=="UP"; local align=cfg.align=="RIGHT" and "RIGHT" or cfg.align=="CENTER" and "CENTER" or "LEFT"
    for i,row in ipairs(f.rows) do
        ns.Font(row,size); row:ClearAllPoints(); row:SetWidth(170); row:SetHeight(size+2); row:SetJustifyH(align)
        local offset=(i-1)*(size+spacing)
        if up then row:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",0,offset) else row:SetPoint("TOPLEFT",f,"TOPLEFT",0,-offset) end
    end
    f.preview=ns.preview and ns.ExtraActive("healerMana")
    ns.UpdateHealerMana()
end
local function HealerUnits(cfg,raid)
    local list={}
    local function Add(unit)
        if not UnitExists(unit) then return end
        local role=ns.UnitRole(unit); local _,class=UnitClass(unit)
        if role=="healer" or (role==nil and cfg.includeUnassigned and manaClasses[class] and (UnitPowerType(unit) or 0)==0) then list[#list+1]=unit end
    end
    if raid then for i=1,GetNumRaidMembers() do Add("raid"..i) end
    else Add("player"); for i=1,GetNumPartyMembers() do Add("party"..i) end end
    return list
end
function ns.UpdateHealerMana()
    local f=ns.healerMana; if not f then return end
    local p=ns.GetSettings(); local cfg=p.healerMana
    local raid=GetNumRaidMembers()>0; local party=not raid and GetNumPartyMembers()>0
    local mode=cfg.mode
    local show=p.enabled and (raid and (mode=="raid" or mode=="both") or party and (mode=="party" or mode=="both"))
    local entries={}
    if f.preview and not raid and not party then
        entries={{name="Healer One",class="PRIEST",pct=92},{name="Healer Two",class="DRUID",pct=61},{name="Healer Three",class="SHAMAN",pct=34}}
        show=true
    elseif show then
        for _,unit in ipairs(HealerUnits(cfg,raid)) do
            local maximum=UnitPowerMax(unit,0) or 0; local _,class=UnitClass(unit)
            entries[#entries+1]={name=UnitName(unit) or "",class=class,pct=maximum>0 and math.floor((UnitPower(unit,0) or 0)/maximum*100+.5) or 0,dead=UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit)}
        end
    end
    if not show then f:Hide(); return end
    for i,row in ipairs(f.rows) do
        local e=entries[i]
        if e then
            local value=e.dead and "Dead" or (e.pct.."%")
            local label=value
            if cfg.showNames~=false and raid or f.preview and cfg.showNames~=false then
                local color=cfg.classNames~=false and RAID_CLASS_COLORS and RAID_CLASS_COLORS[e.class]
                local hex=color and string.format("|cff%02x%02x%02x",color.r*255,color.g*255,color.b*255) or "|cffffffff"
                label=hex..e.name.."|r "..value
            end
            if row:GetText()~=label then row:SetText(label) end; row:Show()
        else row:Hide() end
    end
    f:Show()
end
function ns.UpdateExtras()
    if ns.preview then
        for kind,list in pairs(ns.extraPreviews) do if ns.extraPreviewHolders[kind]:IsShown() then for _,b in ipairs(list) do ns.UpdateFrame(b,false) end end end
    end
    ns.UpdateHealerMana()
end
-------------------------------------------------------------------------------
-- Unlock Mode movers (Element Options panels: ns.ELEMENT_PANELS).
-------------------------------------------------------------------------------
function ns.ExtraUnlockElements()
    local list={}
    local function Add(key,label,order,positionKey,frame,hidden)
        list[#list+1]={key=key,label=label,group="Raid Frames",order=order,noResize=true,noAnchorTo=true,
            getFrame=frame,getSize=function() local f=frame(); return f:GetWidth(),f:GetHeight() end,
            isHidden=hidden,
            savePos=function(_,point,relPoint,x,y) local p=ns.GetSettings(); if p then p.positions[positionKey]={point=point,relPoint=relPoint,x=x,y=y} end end,
            loadPos=function() local p=ns.GetSettings(); return p and p.positions[positionKey] end,
            clearPos=function() local p=ns.GetSettings(); if p then p.positions[positionKey]=nil; ns.Apply() end end,applyPos=ns.Apply}
    end
    Add("RF_TankFrames","Main Tank Frames",803,"tank",function() return ns.extraHolders.tank end,function() return not ns.ExtraActive("tank") end)
    Add("RF_PetFrames","Pet Frames",804,"pet",function() return ns.extraHolders.pet end,function() return not ns.ExtraActive("pet") end)
    Add("RF_BossFrames","Friendly Boss Frames",805,"boss",function() return ns.extraHolders.boss end,function() return not ns.ExtraActive("boss") end)
    Add("RF_HealerMana","Healer Mana",806,"healerMana",function() return ManaFrame() end,function() return not ns.ExtraActive("healerMana") end)
    return list
end
