-- Native Wrath world map additions: unexplored-area reveal, zone level ranges,
-- instance entrances, flight points and player/cursor coordinates.
local _,ns=...
local E=EllesmereUI
if not E or not ns or not ns.GetValue then return end
local overlays=ns.WorldMapOverlays or {}
local owned=ns.owned or {}
local fmod,floor,ceil,format=math.fmod,math.floor,math.ceil,string.format

local levels={
    -- Eastern Kingdoms
    Elwynn={1,10},DunMorogh={1,10},Tirisfal={1,10},EversongWoods={1,10},
    Westfall={10,20},LochModan={10,20},Silverpine={10,20},Ghostlands={10,20},
    Redridge={15,25},Duskwood={18,30},Wetlands={20,30},Hilsbrad={20,30},
    Alterac={30,40},Arathi={30,40},Stranglethorn={30,45},Badlands={35,45},SwampOfSorrows={35,45},
    Hinterlands={40,50},SearingGorge={43,50},BlastedLands={45,55},BurningSteppes={50,58},
    WesternPlaguelands={51,58},EasternPlaguelands={53,60},DeadwindPass={55,60},
    ScarletEnclave={55,58},Sunwell={70,70},
    -- Kalimdor
    Durotar={1,10},Mulgore={1,10},Teldrassil={1,10},AzuremystIsle={1,10},
    Barrens={10,25},Darkshore={10,20},BloodmystIsle={10,20},StonetalonMountains={15,27},
    Ashenvale={18,30},ThousandNeedles={25,35},Desolace={30,40},Dustwallow={35,45},
    Feralas={40,50},Tanaris={40,50},Aszhara={45,55},Felwood={48,55},UngoroCrater={48,55},
    Silithus={55,60},Winterspring={55,60},
    -- Outland
    Hellfire={58,63},Zangarmarsh={60,64},TerokkarForest={62,65},Nagrand={64,67},
    BladesEdgeMountains={65,68},Netherstorm={67,70},ShadowmoonValley={67,70},
    -- Northrend
    BoreanTundra={68,72},HowlingFjord={68,72},Dragonblight={71,75},GrizzlyHills={73,75},
    ZulDrak={74,77},SholazarBasin={76,78},CrystalsongForest={77,80},TheStormPeaks={77,80},
    IcecrownGlacier={77,80},LakeWintergrasp={77,80},
}
ns.WorldMapLevels=levels

local levelTexts={}
local function LevelText(file)
    local text=levelTexts[file]
    if text~=nil then return text or nil end
    local range=levels[file]
    if not range then levelTexts[file]=false; return end
    text=range[1]==range[2] and tostring(range[1]) or range[1].."-"..range[2]
    local c=GetQuestDifficultyColor and GetQuestDifficultyColor(range[1])
    if c then text=format("|cff%02x%02x%02x%s|r",floor(c.r*255+.5),floor(c.g*255+.5),floor(c.b*255+.5),text) end
    levelTexts[file]=text
    return text
end

local fog,discovered={},{}
local function FileSize(pixels)
    local size=16
    while size<pixels do size=size*2 end
    return size
end
local function DrawOverlay(detail,path,id,used,shade)
    local width,height=fmod(id,1024),fmod(floor(id/1024),1024)
    local offsetX,offsetY=fmod(floor(id/1048576),1024),floor(id/1073741824)
    local wide,tall=ceil(width/256),ceil(height/256)
    for j=1,tall do
        local h=j<tall and 256 or (height%256==0 and 256 or height%256)
        local fileH=j<tall and 256 or FileSize(h)
        for k=1,wide do
            local w=k<wide and 256 or (width%256==0 and 256 or width%256)
            local fileW=k<wide and 256 or FileSize(w)
            used=used+1
            local t=fog[used]
            if not t then t=detail:CreateTexture(nil,"BORDER"); owned[t]=true; fog[used]=t end
            t:SetWidth(w); t:SetHeight(h); t:SetTexCoord(0,w/fileW,0,h/fileH)
            t:ClearAllPoints(); t:SetPoint("TOPLEFT",detail,"TOPLEFT",offsetX+256*(k-1),-(offsetY+256*(j-1)))
            t:SetTexture(path..((j-1)*wide+k)); t:SetVertexColor(shade,shade,shade); t:SetAlpha(1); t:Show()
        end
    end
    return used
end
local function UpdateFog()
    local detail=_G.WorldMapDetailFrame
    if not detail then return end
    local used=0
    local file=ns.GetValue("worldMapReveal") and GetMapInfo and GetMapInfo()
    local data=file and overlays[file]
    if data then
        for key in pairs(discovered) do discovered[key]=nil end
        local prefix="Interface\\WorldMap\\"..file.."\\"
        local start=#prefix+1
        for i=1,(GetNumMapOverlays and GetNumMapOverlays() or 0) do
            local path=GetMapOverlayInfo(i)
            if type(path)=="string" then discovered[path:sub(start):lower()]=true end
        end
        local shade=ns.GetValue("worldMapRevealTint") and .55 or 1
        for name,id in pairs(data) do
            if not discovered[name:lower()] then used=DrawOverlay(detail,prefix..name,id,used,shade) end
        end
    end
    for i=used+1,#fog do fog[i]:Hide() end
end

local zoneLabel
local function UpdateZoneLabel()
    local detail,button=_G.WorldMapDetailFrame,_G.WorldMapButton
    if not detail or not button then return end
    if not zoneLabel then
        local holder=CreateFrame("Frame",nil,_G.WorldMapFrame); holder:EnableMouse(false); owned[holder]=true
        holder:SetWidth(1); holder:SetHeight(1); holder:SetPoint("TOPLEFT",detail,"TOPLEFT",10,-10)
        zoneLabel=holder:CreateFontString(nil,"OVERLAY"); zoneLabel:SetPoint("TOPLEFT",holder,"TOPLEFT",0,0); zoneLabel:SetJustifyH("LEFT")
        ns.worldMapZoneLabel=zoneLabel
    end
    local holder=zoneLabel:GetParent()
    holder:SetFrameLevel(button:GetFrameLevel()+5)
    zoneLabel:SetFont(E.GetFontPath and E.GetFontPath("blizzardSkin") or "Fonts\\FRIZQT__.TTF",15,"OUTLINE")
    local text
    local continent=GetCurrentMapContinent and GetCurrentMapContinent() or 0
    local zone=GetCurrentMapZone and GetCurrentMapZone() or 0
    if ns.GetValue("worldMapZoneLevels") and continent>0 and zone>0 then
        local file=GetMapInfo and GetMapInfo()
        local level=file and LevelText(file)
        local name=level and select(zone,GetMapZones(continent))
        if level then text=(name and name.."  " or "")..level end
    end
    if text then zoneLabel:SetText(text); holder:Show() else zoneLabel:SetText(""); holder:Hide() end
end

local hoverName,hoverText
local function UpdateHoverLabel(button)
    local label=_G.WorldMapFrameAreaLabel
    if not label or not ns.GetValue("worldMapZoneLevels") then return end
    local text=label:GetText()
    if not text or text=="" or text==hoverText then return end
    if text~=hoverName then
        hoverName,hoverText=text,nil
        local x,y=GetCursorPosition()
        local scale=button:GetEffectiveScale()
        local cx,cy=button:GetCenter()
        local w,h=button:GetWidth(),button:GetHeight()
        if UpdateMapHighlight and cx and w>0 and h>0 then
            local _,file=UpdateMapHighlight((x/scale-(cx-w/2))/w,(cy+h/2-y/scale)/h)
            local level=file and LevelText(file)
            if level then hoverText=text.."  "..level end
        end
    end
    if hoverText then label:SetText(hoverText) end
end

local flat="Interface\\Buttons\\WHITE8X8"
local instances,flights=ns.WorldMapInstances or {},ns.WorldMapFlights or {}
local markerStyle={
    dungeon={r=.25,g=.62,b=1},
    raid={r=.3,g=.9,b=.35},
    neutral={r=1,g=.82,b=0},
    alliance={r=.3,g=.6,b=1},
    horde={r=1,g=.22,b=.18},
    undiscovered={r=.3,g=.9,b=.35},
}
local media="Interface\\AddOns\\EllesmereUIBlizzardSkin\\Media\\"
local flightIcon=media.."WorldMapMarkerFlight"
local markers,activeMarkers,hoveredMarker={},0,nil

local taxiByName,taxiByMaster={},{}
for node,names in pairs(ns.WorldMapTaxiNodes or {}) do
    for _,name in ipairs(names) do taxiByName[name]=node end
end
for _,list in pairs(flights) do
    for _,entry in ipairs(list) do if entry[6] and entry[6]>0 then taxiByMaster[entry[3]]=entry[6] end end
end
local function KnownTaxi()
    local db=_G.EllesmereUIBlizzardSkinCharDB
    if type(db)~="table" then db={}; _G.EllesmereUIBlizzardSkinCharDB=db end
    if type(db.taxi)~="table" then db.taxi={} end
    return db.taxi
end
local function FlightDiscovered(entry)
    local node=entry[6]
    if not node or node==0 then return true end
    return KnownTaxi()[node]~=false
end
ns.FlightDiscovered=FlightDiscovered
local function ScanTaxiMap()
    local known,count=KnownTaxi(),NumTaxiNodes and NumTaxiNodes() or 0
    for i=1,count do
        local node=taxiByName[TaxiNodeName(i) or ""]
        if node then known[node]=TaxiNodeGetType(i)~="NONE" end
    end
    local npc=UnitName and UnitName("npc")
    if npc and taxiByMaster[npc] then known[taxiByMaster[npc]]=true end
end
local function FlightStyle(entry)
    if not FlightDiscovered(entry) then return markerStyle.undiscovered end
    if entry[5]=="A" then return markerStyle.alliance end
    if entry[5]=="H" then return markerStyle.horde end
    return markerStyle.neutral
end
local function Layer(m,layer,file)
    local t=m:CreateTexture(nil,layer); owned[t]=true
    t:SetAllPoints(m)
    if file then t:SetTexture(media..file) end
    return t
end
local function Marker(index)
    local m=markers[index]
    if m then return m end
    m=CreateFrame("Frame",nil,_G.WorldMapButton); m:EnableMouse(false); owned[m]=true
    m.shadow=Layer(m,"BACKGROUND","WorldMapMarkerShadow")
    m.ring=Layer(m,"ARTWORK","WorldMapMarkerRing")
    m.icon=m:CreateTexture(nil,"OVERLAY"); owned[m.icon]=true
    m.icon:SetPoint("TOPLEFT",m,"TOPLEFT",2,-2); m.icon:SetPoint("BOTTOMRIGHT",m,"BOTTOMRIGHT",-2,2)
    m.icon:SetTexture(flightIcon)
    markers[index]=m
    return m
end
local function SizeMarker(m,size)
    m:SetWidth(size); m:SetHeight(size)
end
local function PlaceMarker(button,size,kind,x,y,data)
    activeMarkers=activeMarkers+1
    local m=Marker(activeMarkers)
    local style=kind=="flight" and FlightStyle(data) or markerStyle[kind]
    m.markerKind,m.data,m.style,m.baseSize=kind,data,style,size
    m:SetFrameLevel(button:GetFrameLevel()+(kind=="flight" and 10 or 11))
    SizeMarker(m,size)
    m:ClearAllPoints(); m:SetPoint("CENTER",button,"TOPLEFT",x/100*button:GetWidth(),-y/100*button:GetHeight())
    if kind=="flight" then
        m.ring:Hide(); m.shadow:SetTexture(media.."WorldMapMarkerShadow"); m.shadow:SetAlpha(.7)
        m.icon:SetVertexColor(style.r,style.g,style.b); m.icon:Show()
    else
        m.icon:Hide(); m.shadow:SetTexture(media.."WorldMapMarkerRingShadow"); m.shadow:SetAlpha(1)
        m.ring:SetVertexColor(style.r,style.g,style.b,1); m.ring:Show()
    end
    m:Show()
end
local function UpdateMarkers()
    local button,frame=_G.WorldMapButton,_G.WorldMapFrame
    activeMarkers=0
    if hoveredMarker then
        local tip=_G.WorldMapTooltip or GameTooltip
        if tip:IsOwned(hoveredMarker) then tip:Hide() end
        SizeMarker(hoveredMarker,hoveredMarker.baseSize)
        hoveredMarker=nil
    end
    local mapID=button and GetCurrentMapAreaID and GetCurrentMapAreaID()
    local mapFloor=GetCurrentMapDungeonLevel and GetCurrentMapDungeonLevel() or 0
    if mapID and mapFloor<=1 then
        local ratio=button:GetEffectiveScale()/frame:GetEffectiveScale()
        local size=math.max(12,math.min(32,22/(ratio>0 and ratio or 1)))
        if ns.GetValue("worldMapInstances") then
            for _,entry in ipairs(instances[mapID] or {}) do
                PlaceMarker(button,size,entry[3][1][2]==2 and "raid" or "dungeon",entry[1],entry[2],entry[3])
            end
        end
        if ns.GetValue("worldMapFlightPoints") then
            local faction=UnitFactionGroup and UnitFactionGroup("player")
            local side=faction=="Alliance" and "A" or faction=="Horde" and "H"
            for _,entry in ipairs(flights[mapID] or {}) do
                local owner=entry[5]
                if not side or owner=="" or owner:find(side,1,true) then
                    PlaceMarker(button,size*.72,"flight",entry[1],entry[2],entry)
                end
            end
        end
    end
    for i=activeMarkers+1,#markers do markers[i]:Hide() end
end
local function MarkerTooltip()
    local tip=_G.WorldMapTooltip or GameTooltip
    local found
    for i=1,activeMarkers do
        local m=markers[i]
        if m:IsMouseOver() then found=m; break end
    end
    if found==hoveredMarker then return end
    if hoveredMarker then
        if tip:IsOwned(hoveredMarker) then tip:Hide() end
        SizeMarker(hoveredMarker,hoveredMarker.baseSize)
    end
    hoveredMarker=found
    if not found then return end
    SizeMarker(found,found.baseSize*1.3)
    tip:SetOwner(found,"ANCHOR_RIGHT")
    if found.markerKind=="flight" then
        tip:AddLine(found.data[3],1,1,1)
        tip:AddLine(found.data[4],.8,.8,.8)
        if not FlightDiscovered(found.data) then tip:AddLine("Undiscovered",.6,.6,.6) end
    else
        for _,entry in ipairs(found.data) do
            local style=entry[2]==2 and markerStyle.raid or markerStyle.dungeon
            local detail=(entry[2]==2 and "Raid " or "Dungeon ")..entry[3]..(entry[4]~="" and "  ("..entry[4]..")" or "")
            tip:AddDoubleLine(entry[1],detail,style.r,style.g,style.b,.85,.85,.85)
        end
    end
    tip:Show()
end

local coords,coordElapsed
local function UpdateCoords(button,elapsed)
    if not ns.GetValue("worldMapCoords") then if coords then coords:GetParent():Hide() end; return end
    if not coords then
        local holder=CreateFrame("Frame",nil,_G.WorldMapFrame); holder:EnableMouse(false); owned[holder]=true
        holder:SetWidth(1); holder:SetHeight(1); holder:SetPoint("BOTTOMLEFT",_G.WorldMapDetailFrame,"BOTTOMLEFT",10,10)
        coords=holder:CreateFontString(nil,"OVERLAY"); coords:SetPoint("BOTTOMLEFT",holder,"BOTTOMLEFT",0,0); coords:SetJustifyH("LEFT")
        ns.worldMapCoords=coords
        coordElapsed=1
    end
    local holder=coords:GetParent()
    holder:SetFrameLevel(button:GetFrameLevel()+15); holder:Show()
    coordElapsed=coordElapsed+(elapsed or 0)
    if coordElapsed<.05 then return end
    coordElapsed=0
    coords:SetFont(E.GetFontPath and E.GetFontPath("blizzardSkin") or "Fonts\\FRIZQT__.TTF",13,"OUTLINE")
    local px,py=GetPlayerMapPosition("player")
    local player=(px and px>0 or py and py>0) and format("%.1f, %.1f",px*100,py*100) or "--"
    local cursor="--"
    local left,top,w,h=button:GetLeft(),button:GetTop(),button:GetWidth(),button:GetHeight()
    if left and top and w>0 and h>0 then
        local x,y=GetCursorPosition()
        local scale=button:GetEffectiveScale()
        local cx,cy=(x/scale-left)/w,(top-y/scale)/h
        if cx>=0 and cx<=1 and cy>=0 and cy<=1 then cursor=format("%.1f, %.1f",cx*100,cy*100) end
    end
    coords:SetText("|cffffd100Player|r "..player.."     |cffffd100Cursor|r "..cursor)
end

local function OnButtonUpdate(button,elapsed)
    UpdateHoverLabel(button)
    MarkerTooltip()
    UpdateCoords(button,elapsed)
end

local function Refresh()
    UpdateFog()
    UpdateZoneLabel()
    UpdateMarkers()
end
function ns.RefreshWorldMap()
    hoverName,hoverText=nil,nil
    if _G.WorldMapFrame and _G.WorldMapFrame:IsShown() then Refresh() end
end

if type(WorldMapFrame_Update)=="function" then hooksecurefunc("WorldMapFrame_Update",Refresh) end
if _G.WorldMapButton and _G.WorldMapButton.HookScript then _G.WorldMapButton:HookScript("OnUpdate",OnButtonUpdate) end
local events=CreateFrame("Frame")
events:RegisterEvent("PLAYER_LEVEL_UP")
events:RegisterEvent("TAXIMAP_OPENED")
events:SetScript("OnEvent",function(_,event)
    if event=="TAXIMAP_OPENED" then ScanTaxiMap()
    else for key in pairs(levelTexts) do levelTexts[key]=nil end end
    ns.RefreshWorldMap()
end)
