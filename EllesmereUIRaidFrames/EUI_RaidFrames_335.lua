-- Wrath secure group headers own roster sorting, unit assignment and visibility.
local ADDON_NAME,ns=...
local E=EllesmereUI
if not E or not E.Lite then return end
local addon=E.Lite.NewAddon(ADDON_NAME)
E._ModuleNS[ADDON_NAME]=ns
ns.addon,ns.ERF,ns.IsWrath=addon,addon,true
_G.EllesmereUIRaidFrames=addon
local function RGB(r,g,b) return {r=r,g=g,b=b} end
local function Config(width,height)
    return {enabled=true,frameWidth=width,frameHeight=height,cellSpacing=3,groupSpacing=8,
        orientation="horizontal",maxGroups=8,sortMethod="ROLE",selfPosition="sorted",reverseGroups=false,reverseUnits=false,partyHorizontal=false,frameStrata="LOW",
        showPlayer=true,showSolo=false,
        showPower=true,powerHeight=4,showPowerText=false,healthClassColored=true,classColoredNames=true,
        healthBarTexture="atrocity",healthDisplay="percent",nameSize=11,healthTextSize=10,powerTextSize=9,statusTextSize=11,
        showGroupNumber=true,groupNumberSize=10,showRole=true,hideDpsRoleIcons=false,showLeader=true,showRaidMarker=true,showReadyCheck=true,
        rangeFade=true,outOfRangeAlpha=.4,showThreat=true,showTargetBorder=true,dispelHighlight=true,
        dispelOverlay="fill",dispelOverlayOpacity=100,dispelBorderSize=0,dispelIconBorderSize=-1,dispelShowAll=true,
        showDispelIcons=false,dispelIconPosition="center",dispelIconSize=16,dispelIconOffsetX=0,dispelIconOffsetY=0,
        showBuffs=true,showDebuffs=true,onlyPlayerBuffs=true,onlyPlayerDebuffs=false,onlyDispellable=false,
        maxBuffs=3,maxDebuffs=3,auraSize=18,auraDurationTextSize=9,auraStackTextSize=10,showAuraTooltips=true,
        -- Retail looks (0.7): colours, borders, text and indicator placement.
        healthColorMode="class",customFillColor=RGB(37/255,193/255,29/255),dynamicColor100=RGB(0,1,0),dynamicColor50=RGB(1,1,0),dynamicColor0=RGB(1,0,0),
        bgClassColored=false,bgDarkness=50,customBgColor=RGB(.08,.08,.09),statusColorOffline=RGB(.4,.4,.4),statusColorDead=RGB(.14,.09,.09),
        healthVerticalFill=false,healPrediction=false,healPredColor=RGB(102/255,243/255,102/255),healPredOpacity=75,
        absorbStyle="striped",absorbOpacity=90,absorbColor=RGB(1,1,1),absorbEdgeMode="overlay",showOvershield=true,
        borderSize=1,borderColor=RGB(0,0,0),hoverBorderEnabled=true,hoverBorderColor=RGB(1,1,1),targetBorderColor=RGB(.05,.82,.61),threatBorderColor=RGB(1,.15,.15),
        nameColorMode="class",nameCustomColor=RGB(1,1,1),namePosition="topleft",nameOutline="module",nameOffsetX=0,nameOffsetY=0,nameMaxLength=0,
        healthTextPosition="topright",healthTextOffsetX=0,healthTextOffsetY=0,healthTextColorMode="custom",healthTextCustomColor=RGB(1,1,1),statusShowAFK=true,
        roleIconStyle="modern",roleIconSize=13,roleIconPosition="bottomleft",roleIconOffsetX=0,roleIconOffsetY=0,showRoleForTank=true,showRoleForHealer=true,roleIconHideInCombat=false,
        raidMarkerSize=16,raidMarkerPosition="center",raidMarkerOffsetX=0,raidMarkerOffsetY=0,
        readyCheckSize=20,readyCheckPosition="center",readyCheckOffsetX=0,readyCheckOffsetY=0,showIncomingRez=true,
        leaderIconSize=14,leaderIconPosition="top",leaderIconOffsetX=0,leaderIconOffsetY=0,showLeaderIconInCombat=true,
        showCombatIndicator=false,combatIndicatorSize=16,combatIndicatorPosition="right",combatIndicatorOffsetX=0,combatIndicatorOffsetY=0,
        dispelColorMagic=RGB(.349,.475,1),dispelColorCurse=RGB(.636,0,.64),dispelColorDisease=RGB(.671,.384,.098),dispelColorPoison=RGB(0,.706,.286),
        hideLustDebuff=true,tooltipMode="outOfCombat",
        raidDebuffs=true,raidDebuffSize=22,raidDebuffDispellable=true,raidDebuffOffsetX=0,raidDebuffOffsetY=0}
end
local defaults={profile={enabled=true,previewMode="overlay",raid=Config(125,52),raidLayoutMode="auto",raidLayouts={},party=Config(145,54),positions={},clickCasting={enabled=false,bindings={}},
    tankFrames={enabled=false,includeAssist=false,horizontal=false,extraWidth=0,extraHeight=0},
    petFrames={party=false,raid=false,horizontal=false,extraWidth=0,extraHeight=-14},
    friendlyBoss={display="never",horizontal=false,extraWidth=0,extraHeight=0},
    healerMana={mode="none",textSize=12,spacing=2,showNames=true,classNames=true,align="LEFT",growth="DOWN",includeUnassigned=true}}}
ns.defaults=defaults
ns.holders,ns.headers,ns.buttons,ns.previews,ns.previewHolders={},{},{},{},{}
local pending=false
local nativeFrames={}
local hidden
local layoutSizes={"10","25","40"}
local validLayout={["10"]=true,["25"]=true,["40"]=true}
-- Unlock Mode/options previews and the no-raid fallback use the 25-player layout, not the maximum.
local DEFAULT_RAID_LAYOUT="25"
ns.DEFAULT_RAID_LAYOUT=DEFAULT_RAID_LAYOUT
-- Unlock Mode "Element Options" targets. Registered by the runtime so the cog menu
-- works before the load-on-demand options addon loads (and replaces Core's static
-- entries, whose highlight labels belong to the Retail options pages).
ns.ELEMENT_PANELS={
    RF_RaidFrames={page="Raid",sectionName="FRAME SIZES",highlightText="Frame Width"},
    RF_PartyFrames={page="Party",sectionName="FRAME SIZES",highlightText="Frame Width"},
    RF_TankFrames={page="Extras",sectionName="MAIN TANK FRAMES",highlightText="Show Main Tank Frames"},
    RF_PetFrames={page="Extras",sectionName="PET FRAMES",highlightText="Show Party Pets"},
    RF_BossFrames={page="Extras",sectionName="FRIENDLY BOSS FRAMES",highlightText="Show Friendly Bosses"},
    RF_HealerMana={page="Extras",sectionName="HEALER MANA",highlightText="Healer Mana Display"}}
local function WritePanels()
    E._ELEMENT_SETTINGS_MAP=E._ELEMENT_SETTINGS_MAP or {}
    for key,panel in pairs(ns.ELEMENT_PANELS) do
        E._ELEMENT_SETTINGS_MAP[key]={module=ADDON_NAME,page=panel.page,sectionName=panel.sectionName,highlightText=panel.highlightText}
    end
end
-- Core's deferred Unlock Mode body (EnsureUnlockCore, after OnEnable) assigns its
-- static map and keeps only earlier keys it lacks, so rewrite ours after it runs.
function ns.RegisterElementPanels()
    WritePanels()
    local pending=E._unlockCoreInit
    if type(pending)=="function" and not ns._panelHook then
        ns._panelHook=true
        E._unlockCoreInit=function(...) pending(...); WritePanels() end
    end
end
function ns.UnitRole(unit)
    if UnitGroupRolesAssigned then
        local tank,healer,dps=UnitGroupRolesAssigned(unit)
        if type(tank)=="string" then
            if tank=="TANK" then return "tank" elseif tank=="HEALER" then return "healer" elseif tank=="DAMAGER" then return "dps" end
        else
            if tank and tank~=0 then return "tank" elseif healer and healer~=0 then return "healer" elseif dps and dps~=0 then return "dps" end
        end
    end
    if GetPartyAssignment and GetPartyAssignment("MAINTANK",unit) then return "tank" end
end
local roleOrder={tank=1,healer=2,dps=3}
-- Wrath secure headers only honour a fixed order through nameList, so Role order
-- and Self First/Last both build the list here; Roster/Name without a self
-- position keep the header's native sorting (which also follows combat joins).
function ns.UsesNameList(c)
    return c.sortMethod=="ROLE" or (c.selfPosition=="first" or c.selfPosition=="last")
end
function ns.SortedNames(kind,group,c)
    local list={}
    local function Add(unit,index)
        local name=UnitName(unit)
        if name and UnitExists(unit) then list[#list+1]={name=name,index=index,role=roleOrder[ns.UnitRole(unit)] or 3,self=UnitIsUnit(unit,"player") and true or false} end
    end
    if kind=="raid" then
        for i=1,GetNumRaidMembers() do if select(3,GetRaidRosterInfo(i))==group then Add("raid"..i,i) end end
    else
        if c.showPlayer then Add("player",0) end
        for i=1,GetNumPartyMembers() do Add("party"..i,i) end
    end
    local method,selfPos=c.sortMethod,c.selfPosition
    table.sort(list,function(a,b)
        if a.self~=b.self and (selfPos=="first" or selfPos=="last") then
            if selfPos=="first" then return a.self else return b.self end
        end
        if method=="NAME" then if a.name~=b.name then return a.name<b.name end
        elseif method=="ROLE" and a.role~=b.role then return a.role<b.role end
        return a.index<b.index
    end)
    local names={}; for i,entry in ipairs(list) do names[i]=entry.name end
    return table.concat(names,",")
end
local function SortingAttributes(attrs,kind,group,c)
    if ns.UsesNameList(c) then
        -- Wrath preserves nameList order with INDEX. groupFilter overrides
        -- nameList, so membership in each subgroup is collected explicitly.
        attrs.groupFilter=ns.NIL; attrs.sortMethod="INDEX"
        attrs.nameList=ns.SortedNames(kind,group,c)
    else
        attrs.nameList=ns.NIL; attrs.groupFilter=kind=="raid" and tostring(group) or ns.NIL
        attrs.sortMethod=c.sortMethod=="NAME" and "NAME" or "INDEX"
    end
end
function ns.EnsureRaidLayouts(force)
    local p=addon.db and addon.db.profile; if not p then return end
    if not p.roleSortingVersion then
        p.party.sortMethod="ROLE"; p.raid.sortMethod="ROLE"
        for _,c in pairs(p.raidLayouts or {}) do c.sortMethod="ROLE" end
        p.roleSortingVersion=1
    end
    if not force and ns._layoutProfile==p and p.raidLayouts and p.raidLayouts["10"] and p.raidLayouts["25"] and p.raidLayouts["40"] then return p end
    p.raidLayouts=p.raidLayouts or {}; p.positions=p.positions or {}
    for _,size in ipairs(layoutSizes) do
        local c=p.raidLayouts[size]
        if not c then
            c=E.Lite.DeepCopy(p.raid or defaults.profile.raid); p.raidLayouts[size]=c
            c.maxGroups=math.min(tonumber(c.maxGroups) or 8,tonumber(size)/5)
            if p.positions.raid then p.positions["raid"..size]=E.Lite.DeepCopy(p.positions.raid) end
        end
        E.Lite.DeepMergeDefaults(c,defaults.profile.raid)
        c.hiddenGroups=c.hiddenGroups or {}
    end
    -- 0.7: older profiles stored only the class-colour toggles; keep their look.
    if not p.retailLooksVersion then
        for _,c in pairs({p.party,p.raidLayouts["10"],p.raidLayouts["25"],p.raidLayouts["40"]}) do
            if c.healthClassColored==false and c.healthColorMode=="class" then c.healthColorMode="custom"; c.customFillColor=RGB(.15,.8,.25) end
            if c.classColoredNames==false and c.nameColorMode=="class" then c.nameColorMode="custom" end
        end
        p.retailLooksVersion=1
    end
    -- 0.9: Retail DISPELS keys replace the frame-colour toggle, style and strength.
    if not p.dispelsVersion then
        for _,c in pairs({p.party,p.raidLayouts["10"],p.raidLayouts["25"],p.raidLayouts["40"]}) do
            c.dispelOverlay=c.dispelFrameColor==false and "none" or c.dispelFrameColorStyle=="gradient" and "gradient" or "fill"
            c.dispelOverlayOpacity=math.max(5,math.min(100,math.floor((tonumber(c.dispelFrameColorStrength) or 1)*100+.5)))
            c.dispelFrameColor,c.dispelFrameColorStyle,c.dispelFrameColorStrength=nil,nil,nil
        end
        p.dispelsVersion=1
    end
    ns._layoutProfile=p; return p
end
function ns.GetRaidLayout(size)
    local p=ns.EnsureRaidLayouts(); return p and p.raidLayouts[tostring(size)]
end
function ns.GetSettings(kind)
    local p=addon.db and addon.db.profile
    if kind=="raid" then return ns.GetRaidLayout(ns.activeRaidLayout or DEFAULT_RAID_LAYOUT) end
    if kind and ns.ExtraSettings and ns.extraKinds and ns.extraKinds[kind] then return ns.ExtraSettings(kind) end
    return p and (kind and p[kind] or p)
end
function ns.GetOptionSettings(kind)
    if kind=="raid" then return ns.GetRaidLayout(ns.selectedRaidLayout or ns.activeRaidLayout or DEFAULT_RAID_LAYOUT) end
    return ns.GetSettings(kind)
end
function ns.RaidLayoutDropdown()
    return {type="dropdown",text="Edit Raid Layout",values={["10"]="10 Players",["25"]="25 Players",["40"]="40 Players"},order=layoutSizes,
        getValue=function() return ns.selectedRaidLayout or ns.activeRaidLayout or DEFAULT_RAID_LAYOUT end,
        setValue=function(v) if not validLayout[v] then return end; ns.selectedRaidLayout=v; ns.Apply(); E:InvalidatePageCache(); E:RefreshPage(true) end}
end
local function DesiredRaidLayout()
    local p=ns.GetSettings(); local forced=validLayout[p.raidLayoutMode] and p.raidLayoutMode
    -- Previews follow Edit Raid Layout, then a forced Use Raid Layout (whose position is the one used).
    if (ns.preview or ns.optionsPreview) and GetNumRaidMembers()==0 then return ns.selectedRaidLayout or forced or DEFAULT_RAID_LAYOUT end
    if forced then return forced end
    local _,instanceType,_,_,capacity=GetInstanceInfo()
    -- Instance capacity avoids switching a partially formed 25-player raid
    -- to the 10-player layout. Outside instances use the current roster size.
    local count=(instanceType=="raid" or instanceType=="pvp") and tonumber(capacity) or 0
    if not count or count<=0 then count=GetNumRaidMembers(); if count==0 then return DEFAULT_RAID_LAYOUT end end
    return count<=10 and "10" or count<=25 and "25" or "40"
end
function ns.Size(f,w,h) f:SetWidth(w); f:SetHeight(h) end
function ns.InCombat() return ns.inCombat or InCombatLockdown() end
function ns.DeferApply() pending=true end
-- Wrath configureChildren passes point (default TOP) and, once a header lays out
-- more than one column, columnAnchorPoint (no default) through strupper.
ns.HEADER_ANCHORS={TOP=true,BOTTOM=true,LEFT=true,RIGHT=true,TOPLEFT=true,TOPRIGHT=true,BOTTOMLEFT=true,BOTTOMRIGHT=true}
function ns.HeaderAnchors(attrs,point,columnAnchor)
    point=type(point)=="string" and point:upper() or ""
    if not ns.HEADER_ANCHORS[point] then point="TOP" end
    columnAnchor=type(columnAnchor)=="string" and columnAnchor:upper() or ""
    if not ns.HEADER_ANCHORS[columnAnchor] then columnAnchor=(point=="LEFT" or point=="RIGHT") and "TOP" or "LEFT" end
    attrs.point,attrs.columnAnchorPoint=point,columnAnchor
    return attrs
end
function ns.SetHeaderAnchors(h,point,columnAnchor)
    local attrs=ns.HeaderAnchors({},point,columnAnchor)
    h:SetAttribute("point",attrs.point); h:SetAttribute("columnAnchorPoint",attrs.columnAnchorPoint)
end
-- Every SetAttribute on a shown Wrath header reruns its layout (recursively while
-- it creates children), so changed attributes are written while it is hidden.
-- ns.NIL stands for an attribute that must be cleared.
ns.NIL={}
function ns.ConfigureHeader(h,attrs,show)
    local changed={}
    for key,value in pairs(attrs) do
        if value==ns.NIL then value=nil end
        if h:GetAttribute(key)~=value then changed[#changed+1]=key end
    end
    if #changed>0 and h:IsShown() then h:Hide() end
    for _,key in ipairs(changed) do local value=attrs[key]; if value==ns.NIL then value=nil end; h:SetAttribute(key,value) end
    if not show then h:Hide() elseif not h:IsShown() then h:Show() end
end
function ns.Font(fs,size)
    local path=(E.GetFontPath and E.GetFontPath("raidFrames")) or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    local flags=((E.GetFontOutlineFlag and E.GetFontOutlineFlag("raidFrames")) or "OUTLINE"):gsub(",?%s*SLUG","")
    if not fs:SetFont(path,math.max(8,tonumber(size) or 11),flags) then fs:SetFont("Fonts\\FRIZQT__.TTF",11,"OUTLINE") end
end
local validStrata={BACKGROUND=true,LOW=true,MEDIUM=true,HIGH=true}
function ns.Strata(c) return validStrata[c and c.frameStrata] and c.frameStrata or "LOW" end
function ns.PositionHolder(f,key,defaultX,defaultY)
    local pos=ns.GetSettings().positions[key]; f:ClearAllPoints()
    if pos then f:SetPoint(pos.point,UIParent,pos.relPoint,pos.x,pos.y)
    else f:SetPoint("TOPLEFT",UIParent,"CENTER",defaultX,defaultY) end
end
local function Position(kind)
    ns.PositionHolder(ns.holders[kind],kind=="raid" and "raid"..ns.activeRaidLayout or kind,kind=="raid" and -480 or -500,kind=="raid" and 230 or 100)
end
local function NativeParty()
    local p=ns.GetSettings(); local suppress=p.enabled and p.party.enabled
    if not hidden then hidden=CreateFrame("Frame",nil,UIParent); hidden:Hide() end
    for i=1,4 do local f=_G["PartyMemberFrame"..i]
        if f then
            if suppress then
                if not nativeFrames[f] then nativeFrames[f]={parent=f:GetParent(),points={}}; for n=1,f:GetNumPoints() do nativeFrames[f].points[n]={f:GetPoint(n)} end end
                f:SetParent(hidden)
            elseif nativeFrames[f] then
                local saved=nativeFrames[f]; f:SetParent(saved.parent); f:ClearAllPoints(); for _,point in ipairs(saved.points) do f:SetPoint(unpack(point)) end
                nativeFrames[f]=nil
            end
        end
    end
end
local function Header(kind,group)
    local h=CreateFrame("Frame","EUI335RaidHeader_"..kind..group,ns.holders[kind],"SecureGroupHeaderTemplate")
    h._euiKind,h._euiGroup=kind,group
    h:Hide(); h:SetAttribute("template","EUI335RaidUnitTemplate")
    h:SetAttribute("showRaid",kind=="raid"); h:SetAttribute("showParty",kind=="party")
    h:SetAttribute("showPlayer",kind=="party"); h:SetAttribute("showSolo",kind=="party")
    h:SetAttribute("sortMethod","INDEX"); h:SetAttribute("unitsPerColumn",5); h:SetAttribute("maxColumns",1)
    if kind=="raid" then h:SetAttribute("groupFilter",tostring(group)) end
    ns.SetHeaderAnchors(h,"TOP")
    -- Native 3.3.5 configureChildren counts five slots even with an empty roster
    -- at this startingIndex. Preallocate every button before combat can begin;
    -- LayoutGroup shows the header again once it is configured.
    h:SetAttribute("startingIndex",-4); h:Show(); h:Hide(); h:SetAttribute("startingIndex",1)
    h.label=h:CreateFontString(nil,"OVERLAY"); ns.Font(h.label,10); h.label:SetPoint("BOTTOMLEFT",h,"TOPLEFT",0,3)
    return h
end
local function CreateGroups()
    for _,kind in ipairs({"raid","party"}) do
        local holder=CreateFrame("Frame","EUI335RaidHolder_"..kind,UIParent,"SecureHandlerStateTemplate")
        holder:SetFrameStrata("LOW"); ns.holders[kind]=holder; ns.headers[kind]={}; ns.previews[kind]={}
        local preview=CreateFrame("Frame",nil,UIParent); preview:SetFrameStrata("LOW"); preview:SetAllPoints(holder); preview:Hide(); ns.previewHolders[kind]=preview
        for group=1,(kind=="raid" and 8 or 1) do ns.headers[kind][group]=Header(kind,group) end
        for i=1,(kind=="raid" and 40 or 5) do
            local b=CreateFrame("Button",nil,preview); b._euiKind=kind; b._euiGroup=math.ceil(i/5); b._euiPreview=i
            ns.InitButton(b); b:EnableMouse(false); ns.previews[kind][i]=b
        end
    end
end
function ns.UpdateGroupLabels()
    for kind,headers in pairs(ns.headers) do local c=ns.GetSettings(kind)
        for i,h in ipairs(headers) do
            local populated=false
            for _,b in ipairs({h:GetChildren()}) do local unit=b:GetAttribute("unit"); if unit and UnitExists(unit) then populated=true; break end end
            h.label:SetText(kind=="raid" and c.showGroupNumber and populated and ("Group "..i) or "")
        end
    end
end
function ns.UpdateAll(auras)
    for _,b in ipairs(ns.buttons) do if b:IsShown() then ns.UpdateFrame(b,auras) end end
    ns.UpdateGroupLabels()
    if ns.UpdateExtras then ns.UpdateExtras() end
end
-- Member growth inside a group and the order groups are packed. Units run down
-- (or up) when groups go across, and right (or left) when groups go down.
function ns.GrowthAnchors(unitsVertical,reverseUnits,spacing)
    if unitsVertical then
        return reverseUnits and "BOTTOM" or "TOP",reverseUnits and "BOTTOMLEFT" or "TOPLEFT",0,reverseUnits and spacing or -spacing
    end
    return reverseUnits and "RIGHT" or "LEFT",reverseUnits and "TOPRIGHT" or "TOPLEFT",reverseUnits and -spacing or spacing,0
end
local function LayoutGroup(kind,p)
    local c=ns.GetSettings(kind); local raid=kind=="raid"
    local w=math.max(60,math.min(300,tonumber(c.frameWidth) or 125)); local height=math.max(30,math.min(120,tonumber(c.frameHeight) or 52))
    local spacing=math.max(0,math.min(20,tonumber(c.cellSpacing) or 3)); local gap=math.max(0,math.min(40,tonumber(c.groupSpacing) or 8))
    local groups=raid and math.max(1,math.min(tonumber(ns.activeRaidLayout)/5,math.floor(tonumber(c.maxGroups) or 8))) or 1
    local slots,visibleGroups={},0
    for group=1,groups do if not raid or not c.hiddenGroups[group] then slots[group]=visibleGroups; visibleGroups=visibleGroups+1 end end
    local across=raid and c.orientation=="horizontal"
    -- "Down and then Right" (Retail grid flow): two groups per column, columns run right.
    local grid=raid and c.orientation=="grid"
    local unitsVertical=across or (not raid and not c.partyHorizontal)
    if raid and not across and c.showGroupNumber then gap=math.max(gap,(tonumber(c.groupNumberSize) or 10)+6) end
    local groupW=unitsVertical and w or 5*w+4*spacing
    local groupH=unitsVertical and 5*height+4*spacing or height
    local drawn=math.max(1,visibleGroups)
    local function Footprint(count)
        local cols,rows=1,count
        if across then cols,rows=count,1 elseif grid then cols,rows=math.ceil(count/2),math.min(count,2) end
        return cols*groupW+(cols-1)*gap,rows*groupH+(rows-1)*gap
    end
    local holder,ph=ns.holders[kind],ns.previewHolders[kind]
    ns.Size(holder,Footprint(drawn))
    holder:SetFrameStrata(ns.Strata(c)); ph:SetFrameStrata(ns.Strata(c))
    Position(kind)
    local reverseUnits=c.reverseUnits and true or false; local reverseGroups=raid and c.reverseGroups
    local point,corner,xOffset,yOffset=ns.GrowthAnchors(unitsVertical,reverseUnits,spacing)
    local function Origin(slot,count)
        local index=reverseGroups and ((count or drawn)-1-slot) or slot
        if grid then return math.floor(index/2)*(groupW+gap),-(index%2)*(groupH+gap) end
        return across and index*(groupW+gap) or 0,across and 0 or -index*(groupH+gap)
    end
    for group,h in ipairs(ns.headers[kind]) do
        local x,y=Origin(slots[group] or 0)
        h:ClearAllPoints(); h:SetPoint(corner,holder,"TOPLEFT",x+(corner:find("RIGHT") and groupW or 0),y-(corner:find("BOTTOM") and groupH or 0))
        local attrs=ns.HeaderAnchors({xOffset=xOffset,yOffset=yOffset},point)
        SortingAttributes(attrs,kind,group,c)
        attrs.showPlayer=kind=="party" and c.showPlayer and true or false
        attrs.showSolo=kind=="party" and c.showSolo and c.showPlayer and true or false
        ns.ConfigureHeader(h,attrs,slots[group]~=nil)
        ns.Font(h.label,c.groupNumberSize)
        for _,b in ipairs({h:GetChildren()}) do if b._euiKind then ns.LayoutButton(b); ns.ApplyBindings(b) end end
    end
    local visibility="hide"
    if p.enabled and c.enabled and visibleGroups>0 then visibility=raid and "[group:raid] show; hide" or ("[group:raid] hide; [group:party] show; "..(c.showSolo and c.showPlayer and "show" or "hide")) end
    RegisterStateDriver(holder,"visibility",visibility)
    local live=raid and GetNumRaidMembers()>0 or kind=="party" and GetNumRaidMembers()==0 and (GetNumPartyMembers()>0 or c.showSolo and c.showPlayer)
    -- Options preview (Retail Preview Mode): Real draws the fakes in place,
    -- Overlay docks them beside the options panel and dims the live frames.
    local optionsHere=ns.optionsPreview==kind and not ns.preview
    local mode=p.previewMode or "overlay"
    local overlay=optionsHere and mode=="overlay"
    local inPlace=ns.preview or (optionsHere and mode=="real")
    holder:SetAlpha(overlay and .2 or 1)
    if p.enabled and c.enabled and visibleGroups>0 and (overlay or (inPlace and not live)) then
        local oc=overlay and ns.OverlayContainer() or nil
        local parent=oc or ph
        local pad,top=oc and 20 or 0,oc and 25 or 0
        -- Overlay keeps Retail's compact 20-player preview: the first four visible groups.
        local count=oc and math.min(drawn,4) or drawn
        for i,b in ipairs(ns.previews[kind]) do
            local group,slot=math.ceil(i/5),((i-1)%5)
            local s=slots[group]
            local x,y=Origin(s or 0,count)
            local u=reverseUnits and (4-slot) or slot
            if unitsVertical then y=y-u*(height+spacing) else x=x+u*(w+spacing) end
            if b:GetParent()~=parent then b:SetParent(parent) end
            ns.LayoutButton(b); b:ClearAllPoints()
            b:SetPoint("TOPLEFT",parent,"TOPLEFT",x+pad,y-pad-top)
            if s~=nil and s<count then b:Show(); ns.UpdateFrame(b,true) else b:Hide() end
        end
        if oc then
            local cw,chh=Footprint(count)
            ns.Size(oc,cw+pad*2,chh+pad*2+top)
            for group=1,8 do
                local lbl=ns.OverlayLabel(group); local s=slots[group]
                local first=ns.previews[kind][(group-1)*5+1]
                if raid and s~=nil and s<count then
                    ns.Font(lbl,c.groupNumberSize); lbl:SetText(tostring(group)); lbl:ClearAllPoints()
                    if unitsVertical then
                        if reverseUnits then lbl:SetPoint("TOP",first,"BOTTOM",0,-4) else lbl:SetPoint("BOTTOM",first,"TOP",0,4) end
                    elseif reverseUnits then lbl:SetPoint("LEFT",first,"RIGHT",3,0)
                    else lbl:SetPoint("RIGHT",first,"LEFT",-3,0) end
                    lbl:Show()
                else lbl:Hide() end
            end
            ph:Hide(); oc:Show()
        else ph:Show() end
    else ph:Hide() end
end
function ns.OverlayContainer()
    local oc=ns.overlay
    if not oc then
        oc=CreateFrame("Frame",nil,UIParent); ns.overlay=oc
        oc:SetFrameStrata("FULLSCREEN_DIALOG"); oc:SetFrameLevel(10); oc:SetClampedToScreen(true); oc:Hide()
        local bg=oc:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(); bg:SetTexture("Interface\\Buttons\\WHITE8X8"); bg:SetVertexColor(0,0,0,.9)
        oc.title=oc:CreateFontString(nil,"OVERLAY"); oc.title:SetPoint("TOP",oc,"TOP",0,-7)
        oc.labels=CreateFrame("Frame",nil,oc); oc.labels:SetAllPoints(); oc.labels:SetFrameLevel(oc:GetFrameLevel()+50)
    end
    ns.Font(oc.title,13); oc.title:SetText("Overlay Preview"); oc.title:SetTextColor(1,1,1,.9)
    oc:ClearAllPoints()
    -- Docked to the options panel's left edge (not draggable, not saved), like Retail.
    if E._scrollFrame then oc:SetPoint("BOTTOMRIGHT",E._scrollFrame,"BOTTOMLEFT",0,0) else oc:SetPoint("CENTER",UIParent,"CENTER",0,0) end
    return oc
end
function ns.OverlayLabel(group)
    local oc=ns.OverlayContainer(); oc.groupLabels=oc.groupLabels or {}
    local lbl=oc.groupLabels[group]
    if not lbl then lbl=oc.labels:CreateFontString(nil,"OVERLAY"); lbl:SetTextColor(1,1,1,.75); oc.groupLabels[group]=lbl end
    return lbl
end
-- The options preview follows the open page: Raid or Party, unless Preview Mode is None.
function ns.OptionsPreviewKind()
    if ns.InCombat() or not (E.IsShown and E:IsShown()) or not E.GetActiveModule or E:GetActiveModule()~=ADDON_NAME then return nil end
    local p=ns.GetSettings(); if not p or (p.previewMode or "overlay")=="none" then return nil end
    local page=E.GetActivePage and E:GetActivePage()
    return page=="Raid" and "raid" or page=="Party" and "party" or nil
end
function ns.SyncOptionsPreview(force)
    local want=ns.OptionsPreviewKind()
    if want~=ns.optionsPreview or force then ns.optionsPreview=want; ns.Apply() end
end
function ns.Apply()
    local p=ns.GetSettings(); if not p then return end
    if InCombatLockdown() then pending=true; return end; pending=false
    ns.EnsureRaidLayouts(true); ns.activeRaidLayout=DesiredRaidLayout()
    if not ns.holders.raid then CreateGroups() end
    NativeParty()
    if ns.overlay then ns.overlay:Hide() end
    for _,kind in ipairs({"raid","party"}) do LayoutGroup(kind,p) end
    if ns.ApplyExtras then ns.ApplyExtras() end
    ns.UpdateAll(true)
end
ns.ReloadFrames,ns.ReloadPartyFrames=ns.Apply,ns.Apply
function ns.SetPreview(value) ns.preview=value and not InCombatLockdown() or false; ns.Apply() end
local function RegisterMovers()
    ns.RegisterElementPanels()
    if not E.RegisterUnlockElements or not E.MakeUnlockElement then return end
    local elements={}
    for i,kind in ipairs({"raid","party"}) do local key=kind
        local function PositionKey() return key=="raid" and "raid"..ns.activeRaidLayout or key end
        elements[#elements+1]=E.MakeUnlockElement({key=kind=="raid" and "RF_RaidFrames" or "RF_PartyFrames",label=kind=="raid" and "Raid Frames" or "Party Frames",group="Raid Frames",order=800+i,noResize=true,noAnchorTo=true,
            getFrame=function() return ns.holders[key] end,getSize=function() local f=ns.holders[key]; return f:GetWidth(),f:GetHeight() end,
            isHidden=function() local p=ns.GetSettings(); return not p or not p.enabled or not ns.GetSettings(key).enabled or (not ns.holders[key]:IsShown() and not ns.previewHolders[key]:IsShown()) end,
            savePos=function(_,point,relPoint,x,y) local p=ns.GetSettings(); if p then p.positions[PositionKey()]={point=point,relPoint=relPoint,x=x,y=y} end end,
            loadPos=function() local p=ns.GetSettings(); return p and p.positions[PositionKey()] end,
            clearPos=function() local p=ns.GetSettings(); if p then p.positions[PositionKey()]=nil; ns.Apply() end end,applyPos=ns.Apply})
    end
    if ns.ExtraUnlockElements then for _,element in ipairs(ns.ExtraUnlockElements()) do elements[#elements+1]=E.MakeUnlockElement(element) end end
    E:RegisterUnlockElements(elements,ADDON_NAME)
end
function addon:OnInitialize()
    addon.db=E.Lite.NewDB("EllesmereUIRaidFramesDB",defaults); ns.db=addon.db
    ns.EnsureRaidLayouts()
    _G._ERF_RefreshAll=ns.Apply
    SLASH_EUI335RAID1="/erf"; SLASH_EUI335RAID2="/rf"
    SlashCmdList.EUI335RAID=function() if InCombatLockdown() then return end; if E.EnsureOptionsLoaded then E.EnsureOptionsLoaded() end; E:ShowModule(ADDON_NAME) end
end
local function OnEvent(_,event,unit,duration)
    if event=="PLAYER_REGEN_ENABLED" then ns.inCombat=false end
    if event=="PLAYER_ENTERING_WORLD" or event=="ZONE_CHANGED_NEW_AREA" or event=="ADDON_LOADED" or event=="SPELLS_CHANGED" or event=="PLAYER_TALENT_UPDATE" or (event=="PLAYER_REGEN_ENABLED" and pending) then ns.Apply()
    elseif event=="PLAYER_REGEN_DISABLED" then
        ns.inCombat=true; ns.preview=false; ns.optionsPreview=nil
        for _,f in pairs(ns.previewHolders) do f:Hide() end
        for _,h in pairs(ns.holders) do h:SetAlpha(1) end
        if ns.overlay then ns.overlay:Hide() end
        if ns.HideExtraPreviews then ns.HideExtraPreviews() end; ns.UpdateAll(false)
    elseif event=="PLAYER_REGEN_ENABLED" then ns.inCombat=false; ns.UpdateAll(false)
    elseif event=="RAID_ROSTER_UPDATE" or event=="PARTY_MEMBERS_CHANGED" then if InCombatLockdown() then pending=true; ns.UpdateAll(true) else ns.Apply() end
    elseif event=="READY_CHECK" then
        ns.readyResults={}; ns.readyFinished=false; ns.readyInitiator=unit
        ns.readyUntil=GetTime()+(tonumber(duration) or 35)+10; ns.UpdateAll(false)
    elseif event=="READY_CHECK_CONFIRM" then
        -- The client can fire FINISHED before the last CONFIRM, so late answers still count.
        local guid=ns.ReadyGUID(unit)
        local status=ns.ReadyConfirmStatus(unit,duration)
        if guid and status and ns.readyResults and ns.readyUntil and GetTime()<ns.readyUntil then
            ns.readyResults[guid]=status
            if ns.readyFinished then ns.readyUntil=GetTime()+10 end
        end
        ns.UpdateAll(false)
    elseif event=="READY_CHECK_FINISHED" then
        local results=ns.readyResults or {}; ns.readyResults=results
        for _,b in ipairs(ns.buttons) do
            local token=b:GetAttribute("unit") or b.unit
            local guid=token and UnitGUID(token)
            if guid then
                local live=GetReadyCheckStatus(token)
                local known=results[guid]
                if (live=="ready" or live=="notready") and (known==nil or known=="waiting") then results[guid]=live end
                if ns.IsReadyInitiator(token) then results[guid]="ready" end
            end
        end
        ns.readyFinished=true; ns.readyUntil=GetTime()+10
        for guid,status in pairs(results) do if status=="waiting" then results[guid]="notready" end end
        ns.UpdateAll(false)
    elseif event:find("UNIT_",1,true)==1 then
        for _,b in ipairs(ns.buttons) do if b:IsShown() and (b:GetAttribute("unit")==unit or b.unit==unit) then ns.UpdateFrame(b,event=="UNIT_AURA" or event=="UNIT_PET" or event:find("VEHICLE",1,true)) end end
        if ns.UpdateHealerMana and (event=="UNIT_MANA" or event=="UNIT_MAXMANA" or event=="UNIT_DISPLAYPOWER") then ns.UpdateHealerMana() end
    else ns.UpdateAll(event=="RAID_ROSTER_UPDATE" or event=="PARTY_MEMBERS_CHANGED" or event=="INSTANCE_ENCOUNTER_ENGAGE_UNIT") end
end
function addon:OnEnable()
    ns.Apply(); RegisterMovers()
    if E.RegisterUnlockModeListener then E:RegisterUnlockModeListener(ADDON_NAME,ns.SetPreview) end
    if E.RegisterOnShow then E:RegisterOnShow(function() ns.SyncOptionsPreview() end) end
    if E.RegisterOnHide then E:RegisterOnHide(function() ns.SyncOptionsPreview() end) end
    if ns.InitPrediction then ns.InitPrediction() end
    local events=CreateFrame("Frame"); ns.events=events
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","ZONE_CHANGED_NEW_AREA","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED","RAID_ROSTER_UPDATE","PARTY_MEMBERS_CHANGED","PARTY_LEADER_CHANGED","PLAYER_TARGET_CHANGED","RAID_TARGET_UPDATE","READY_CHECK","READY_CHECK_CONFIRM","READY_CHECK_FINISHED","UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_MANA","UNIT_MAXMANA","UNIT_RAGE","UNIT_MAXRAGE","UNIT_ENERGY","UNIT_MAXENERGY","UNIT_FOCUS","UNIT_RUNIC_POWER","UNIT_MAXRUNIC_POWER","UNIT_DISPLAYPOWER","UNIT_AURA","UNIT_NAME_UPDATE","UNIT_FLAGS","UNIT_CONNECTION","UNIT_THREAT_SITUATION_UPDATE","UNIT_ENTERED_VEHICLE","UNIT_EXITED_VEHICLE","UNIT_PET","SPELLS_CHANGED","ADDON_LOADED","INSTANCE_ENCOUNTER_ENGAGE_UNIT","PLAYER_TALENT_UPDATE"}) do pcall(events.RegisterEvent,events,event) end
    events:SetScript("OnEvent",OnEvent)
    -- The answering client may get no READY_CHECK_CONFIRM for itself; record the click.
    if ConfirmReadyCheck and not ns.readyHooked then
        ns.readyHooked=true
        hooksecurefunc("ConfirmReadyCheck",function(isReady)
            local guid=UnitGUID("player")
            local status=(isReady and isReady~=0 and isReady~=false) and "ready" or "notready"
            if guid and ns.readyResults and ns.readyUntil and GetTime()<ns.readyUntil then
                ns.readyResults[guid]=status; ns.UpdateAll(false)
            end
        end)
    end
    local elapsed,roleElapsed=0,0
    events:SetScript("OnUpdate",function(_,dt)
        if ns.UpdateTooltip then ns.UpdateTooltip() end
        roleElapsed=roleElapsed+dt
        if roleElapsed>=1 then
            roleElapsed=0
            for kind,headers in pairs(ns.headers) do local c=ns.GetSettings(kind)
                if c and ns.UsesNameList(c) then for group,h in ipairs(headers) do
                    if h:GetAttribute("nameList")~=ns.SortedNames(kind,group,c) then ns.Apply(); break end
                end end
            end
        end
        elapsed=elapsed+dt; if elapsed<.2 then return end; elapsed=0
        if ns.OptionsPreviewKind()~=ns.optionsPreview then ns.SyncOptionsPreview() end
        local p=ns.GetSettings(); if not p or not p.enabled then return end
        if DesiredRaidLayout()~=ns.activeRaidLayout then ns.Apply() end
        ns.UpdateAll(false)
        if ns.preview then for kind,list in pairs(ns.previews) do if ns.previewHolders[kind]:IsShown() then for _,b in ipairs(list) do if b:IsShown() then ns.UpdateFrame(b,false) end end end end end
    end)
end
