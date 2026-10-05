-- Wrath secure group headers own roster sorting, unit assignment and visibility.
local ADDON_NAME,ns=...
local E=EllesmereUI
if not E or not E.Lite then return end
local addon=E.Lite.NewAddon(ADDON_NAME)
E._ModuleNS[ADDON_NAME]=ns
ns.addon,ns.ERF,ns.IsWrath=addon,addon,true
_G.EllesmereUIRaidFrames=addon
local function Config(width,height)
    return {enabled=true,frameWidth=width,frameHeight=height,cellSpacing=3,groupSpacing=8,
        orientation="horizontal",maxGroups=8,sortMethod="ROLE",showPlayer=true,showSolo=false,
        showPower=true,powerHeight=4,showPowerText=false,healthClassColored=true,classColoredNames=true,
        healthBarTexture="atrocity",healthDisplay="percent",nameSize=11,healthTextSize=10,powerTextSize=9,statusTextSize=11,
        showGroupNumber=true,groupNumberSize=10,showRole=true,hideDpsRoleIcons=false,showLeader=true,showRaidMarker=true,showReadyCheck=true,
        rangeFade=true,outOfRangeAlpha=.4,showThreat=true,showTargetBorder=true,dispelHighlight=true,dispelFrameColor=true,dispelFrameColorStrength=1,
        showBuffs=true,showDebuffs=true,onlyPlayerBuffs=true,onlyPlayerDebuffs=false,onlyDispellable=false,
        maxBuffs=3,maxDebuffs=3,auraSize=18,auraDurationTextSize=9,auraStackTextSize=10,showAuraTooltips=true}
end
local defaults={profile={enabled=true,raid=Config(125,52),raidLayoutMode="auto",raidLayouts={},party=Config(145,54),positions={},clickCasting={enabled=false,bindings={}}}}
ns.defaults=defaults
ns.holders,ns.headers,ns.buttons,ns.previews,ns.previewHolders={},{},{},{},{}
local pending=false
local nativeFrames={}
local hidden
local layoutSizes={"10","25","40"}
local validLayout={["10"]=true,["25"]=true,["40"]=true}
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
function ns.SortedNames(kind,group,c)
    local list={}
    local function Add(unit,index)
        local name=UnitName(unit)
        if name and UnitExists(unit) then list[#list+1]={name=name,index=index,role=roleOrder[ns.UnitRole(unit)] or 3} end
    end
    if kind=="raid" then
        for i=1,GetNumRaidMembers() do if select(3,GetRaidRosterInfo(i))==group then Add("raid"..i,i) end end
    else
        if c.showPlayer then Add("player",0) end
        for i=1,GetNumPartyMembers() do Add("party"..i,i) end
    end
    table.sort(list,function(a,b) return a.role~=b.role and a.role<b.role or a.role==b.role and a.index<b.index end)
    local names={}; for i,entry in ipairs(list) do names[i]=entry.name end
    return table.concat(names,",")
end
local function ApplySorting(h,kind,group,c)
    if c.sortMethod=="ROLE" then
        -- Wrath preserves nameList order with INDEX. groupFilter overrides
        -- nameList, so membership in each subgroup is collected explicitly.
        h:SetAttribute("groupFilter",nil); h:SetAttribute("sortMethod","INDEX")
        h:SetAttribute("nameList",ns.SortedNames(kind,group,c))
    else
        h:SetAttribute("nameList",nil); h:SetAttribute("groupFilter",kind=="raid" and tostring(group) or nil)
        h:SetAttribute("sortMethod",c.sortMethod=="NAME" and "NAME" or "INDEX")
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
    ns._layoutProfile=p; return p
end
function ns.GetRaidLayout(size)
    local p=ns.EnsureRaidLayouts(); return p and p.raidLayouts[tostring(size)]
end
function ns.GetSettings(kind)
    local p=addon.db and addon.db.profile
    if kind=="raid" then return ns.GetRaidLayout(ns.activeRaidLayout or "40") end
    return p and (kind and p[kind] or p)
end
function ns.GetOptionSettings(kind)
    if kind=="raid" then return ns.GetRaidLayout(ns.selectedRaidLayout or ns.activeRaidLayout or "40") end
    return ns.GetSettings(kind)
end
function ns.RaidLayoutDropdown()
    return {type="dropdown",text="Edit Raid Layout",values={["10"]="10 Players",["25"]="25 Players",["40"]="40 Players"},order=layoutSizes,
        getValue=function() return ns.selectedRaidLayout or ns.activeRaidLayout or "40" end,
        setValue=function(v) if not validLayout[v] then return end; ns.selectedRaidLayout=v; ns.Apply(); E:InvalidatePageCache(); E:RefreshPage(true) end}
end
local function DesiredRaidLayout()
    if ns.preview and GetNumRaidMembers()==0 then return ns.selectedRaidLayout or "40" end
    local p=ns.GetSettings(); if validLayout[p.raidLayoutMode] then return p.raidLayoutMode end
    local _,instanceType,_,_,capacity=GetInstanceInfo()
    -- Instance capacity avoids switching a partially formed 25-player raid
    -- to the 10-player layout. Outside instances use the current roster size.
    local count=(instanceType=="raid" or instanceType=="pvp") and tonumber(capacity) or 0
    if not count or count<=0 then count=GetNumRaidMembers(); if count==0 then return "40" end end
    return count<=10 and "10" or count<=25 and "25" or "40"
end
function ns.Size(f,w,h) f:SetWidth(w); f:SetHeight(h) end
function ns.Font(fs,size)
    local path=(E.GetFontPath and E.GetFontPath("raidFrames")) or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    local flags=((E.GetFontOutlineFlag and E.GetFontOutlineFlag("raidFrames")) or "OUTLINE"):gsub(",?%s*SLUG","")
    if not fs:SetFont(path,math.max(8,tonumber(size) or 11),flags) then fs:SetFont("Fonts\\FRIZQT__.TTF",11,"OUTLINE") end
end
local function Position(kind)
    local pos=ns.GetSettings().positions[kind=="raid" and "raid"..ns.activeRaidLayout or kind]; local f=ns.holders[kind]; f:ClearAllPoints()
    if pos then f:SetPoint(pos.point,UIParent,pos.relPoint,pos.x,pos.y)
    else f:SetPoint("TOPLEFT",UIParent,"CENTER",kind=="raid" and -480 or -500,kind=="raid" and 230 or 100) end
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
    -- Native 3.3.5 configureChildren counts five slots even with an empty roster
    -- at this startingIndex. Preallocate every button before combat can begin.
    h:SetAttribute("startingIndex",-4); h:Show(); h:SetAttribute("startingIndex",1)
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
end
function ns.Apply()
    local p=ns.GetSettings(); if not p then return end
    if InCombatLockdown() then pending=true; return end; pending=false
    ns.EnsureRaidLayouts(true); ns.activeRaidLayout=DesiredRaidLayout()
    if not ns.holders.raid then CreateGroups() end
    NativeParty()
    for _,kind in ipairs({"raid","party"}) do
        local c=ns.GetSettings(kind); local w=math.max(60,math.min(300,tonumber(c.frameWidth) or 125)); local height=math.max(30,math.min(120,tonumber(c.frameHeight) or 52))
        local spacing=math.max(0,math.min(20,tonumber(c.cellSpacing) or 3)); local gap=math.max(0,math.min(40,tonumber(c.groupSpacing) or 8))
        local groups=kind=="raid" and math.max(1,math.min(tonumber(ns.activeRaidLayout)/5,math.floor(tonumber(c.maxGroups) or 8))) or 1
        local slots,visibleGroups={},0
        for group=1,groups do if kind~="raid" or not c.hiddenGroups[group] then slots[group]=visibleGroups; visibleGroups=visibleGroups+1 end end
        local across=kind=="raid" and c.orientation=="horizontal"
        if kind=="raid" and not across and c.showGroupNumber then gap=math.max(gap,(tonumber(c.groupNumberSize) or 10)+6) end
        local groupW=across and w or (kind=="raid" and 5*w+4*spacing or w)
        local groupH=across and 5*height+4*spacing or (kind=="raid" and height or 5*height+4*spacing)
        local drawn=math.max(1,visibleGroups)
        ns.Size(ns.holders[kind],across and drawn*groupW+(drawn-1)*gap or groupW,across and groupH or drawn*groupH+(drawn-1)*gap)
        Position(kind)
        for group,h in ipairs(ns.headers[kind]) do
            local slot=slots[group] or 0
            h:ClearAllPoints(); h:SetPoint("TOPLEFT",ns.holders[kind],"TOPLEFT",across and slot*(groupW+gap) or 0,across and 0 or -slot*(groupH+gap))
            h:SetAttribute("point",kind=="raid" and not across and "LEFT" or "TOP")
            h:SetAttribute("xOffset",kind=="raid" and not across and spacing or 0); h:SetAttribute("yOffset",kind=="raid" and not across and 0 or -spacing)
            ApplySorting(h,kind,group,c)
            h:SetAttribute("showPlayer",kind=="party" and c.showPlayer); h:SetAttribute("showSolo",kind=="party" and c.showSolo and c.showPlayer)
            if slots[group]~=nil then h:Show() else h:Hide() end
            ns.Font(h.label,c.groupNumberSize)
            for _,b in ipairs({h:GetChildren()}) do if b._euiKind then ns.LayoutButton(b); ns.ApplyBindings(b) end end
        end
        local visibility="hide"
        if p.enabled and c.enabled and visibleGroups>0 then visibility=kind=="raid" and "[group:raid] show; hide" or ("[group:raid] hide; [group:party] show; "..(c.showSolo and c.showPlayer and "show" or "hide")) end
        RegisterStateDriver(ns.holders[kind],"visibility",visibility)
        local ph=ns.previewHolders[kind]
        local live=kind=="raid" and GetNumRaidMembers()>0 or kind=="party" and GetNumRaidMembers()==0 and (GetNumPartyMembers()>0 or c.showSolo and c.showPlayer)
        if ns.preview and not live and p.enabled and c.enabled and visibleGroups>0 then
            for i,b in ipairs(ns.previews[kind]) do
                local group,slot=math.ceil(i/5),((i-1)%5)
                local groupSlot=slots[group] or 0
                ns.LayoutButton(b); b:ClearAllPoints()
                local x=across and groupSlot*(groupW+gap) or (kind=="raid" and slot*(w+spacing) or 0)
                local y=across and -slot*(height+spacing) or (kind=="raid" and -groupSlot*(groupH+gap) or -slot*(height+spacing))
                b:SetPoint("TOPLEFT",ph,"TOPLEFT",x,y); if slots[group]~=nil then b:Show(); ns.UpdateFrame(b,true) else b:Hide() end
            end
            ph:Show()
        else ph:Hide() end
    end
    ns.UpdateAll(true)
end
ns.ReloadFrames,ns.ReloadPartyFrames=ns.Apply,ns.Apply
function ns.SetPreview(value) ns.preview=value and not InCombatLockdown() or false; ns.Apply() end
local function RegisterMovers()
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
    E:RegisterUnlockElements(elements,ADDON_NAME)
end
function addon:OnInitialize()
    addon.db=E.Lite.NewDB("EllesmereUIRaidFramesDB",defaults); ns.db=addon.db
    ns.EnsureRaidLayouts()
    _G._ERF_RefreshAll=ns.Apply
    SLASH_EUI335RAID1="/erf"; SLASH_EUI335RAID2="/rf"
    SlashCmdList.EUI335RAID=function() if InCombatLockdown() then return end; if E.EnsureOptionsLoaded then E.EnsureOptionsLoaded() end; E:ShowModule(ADDON_NAME) end
end
function addon:OnEnable()
    ns.Apply(); RegisterMovers()
    if E.RegisterUnlockModeListener then E:RegisterUnlockModeListener(ADDON_NAME,ns.SetPreview) end
    local events=CreateFrame("Frame"); ns.events=events
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","ZONE_CHANGED_NEW_AREA","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED","RAID_ROSTER_UPDATE","PARTY_MEMBERS_CHANGED","PARTY_LEADER_CHANGED","PLAYER_TARGET_CHANGED","RAID_TARGET_UPDATE","READY_CHECK","READY_CHECK_CONFIRM","READY_CHECK_FINISHED","UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_MANA","UNIT_MAXMANA","UNIT_RAGE","UNIT_MAXRAGE","UNIT_ENERGY","UNIT_MAXENERGY","UNIT_FOCUS","UNIT_RUNIC_POWER","UNIT_MAXRUNIC_POWER","UNIT_DISPLAYPOWER","UNIT_AURA","UNIT_NAME_UPDATE","UNIT_FLAGS","UNIT_CONNECTION","UNIT_THREAT_SITUATION_UPDATE","UNIT_ENTERED_VEHICLE","UNIT_EXITED_VEHICLE","UNIT_PET","SPELLS_CHANGED","ADDON_LOADED"}) do events:RegisterEvent(event) end
    events:SetScript("OnEvent",function(_,event,unit,duration)
        if event=="PLAYER_ENTERING_WORLD" or event=="ZONE_CHANGED_NEW_AREA" or event=="ADDON_LOADED" or event=="SPELLS_CHANGED" or (event=="PLAYER_REGEN_ENABLED" and pending) then ns.Apply()
        elseif event=="PLAYER_REGEN_DISABLED" then ns.preview=false; for _,f in pairs(ns.previewHolders) do f:Hide() end
        elseif event=="RAID_ROSTER_UPDATE" or event=="PARTY_MEMBERS_CHANGED" then if InCombatLockdown() then pending=true; ns.UpdateAll(true) else ns.Apply() end
        elseif event=="READY_CHECK" then ns.readyUntil=GetTime()+(tonumber(duration) or 35)+10; ns.UpdateAll(false)
        elseif event=="READY_CHECK_FINISHED" then ns.readyUntil=GetTime()+10; ns.UpdateAll(false)
        elseif event:find("UNIT_",1,true)==1 then
            for _,b in ipairs(ns.buttons) do if b:IsShown() and (b:GetAttribute("unit")==unit or b.unit==unit) then ns.UpdateFrame(b,event=="UNIT_AURA" or event=="UNIT_PET" or event:find("VEHICLE",1,true)) end end
        else ns.UpdateAll(event=="RAID_ROSTER_UPDATE" or event=="PARTY_MEMBERS_CHANGED") end
    end)
    local elapsed,roleElapsed=0,0
    events:SetScript("OnUpdate",function(_,dt)
        if ns.UpdateTooltip then ns.UpdateTooltip() end
        roleElapsed=roleElapsed+dt
        if roleElapsed>=1 then
            roleElapsed=0
            for kind,headers in pairs(ns.headers) do local c=ns.GetSettings(kind)
                if c and c.sortMethod=="ROLE" then for group,h in ipairs(headers) do
                    if h:GetAttribute("nameList")~=ns.SortedNames(kind,group,c) then ns.Apply(); break end
                end end
            end
        end
        elapsed=elapsed+dt; if elapsed<.2 then return end; elapsed=0
        local p=ns.GetSettings(); if not p or not p.enabled then return end
        if DesiredRaidLayout()~=ns.activeRaidLayout then ns.Apply() end
        ns.UpdateAll(false)
        if ns.preview then for kind,list in pairs(ns.previews) do if ns.previewHolders[kind]:IsShown() then for _,b in ipairs(list) do if b:IsShown() then ns.UpdateFrame(b,false) end end end end end
    end)
end
