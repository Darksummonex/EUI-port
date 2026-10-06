"""World map reveal, zone levels, fitted panel and inset check boxes on Lua 5.1."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
lua=LuaRuntime()
lua.execute((root/'backport-tools/wrath_mock.lua').read_text())
lua.execute((root/'backport-tools/blizzardskin_mock.lua').read_text())
lua.execute((root/'backport-tools/character_mock.lua').read_text())
lua.execute((root/'EllesmereUI/EllesmereUI_Lite.lua').read_text(encoding='utf-8-sig'))
lua.execute(r'''
local function Bounds(f,l,b,r,t) f.GetLeft=function() return l end; f.GetBottom=function() return b end; f.GetRight=function() return r end; f.GetTop=function() return t end end
Bounds(WorldMapFrame,0,0,1200,900)
WorldMapDetailFrame=CreateFrame('Frame','WorldMapDetailFrame',WorldMapFrame); Bounds(WorldMapDetailFrame,100,200,800,700)
WorldMapDetailFrame:SetWidth(700); WorldMapDetailFrame:SetHeight(500)
WorldMapButton=CreateFrame('Button','WorldMapButton',WorldMapFrame)
WorldMapButton.width,WorldMapButton.height=700,500
WorldMapButton.GetCenter=function() return 450,450 end
WorldMapFrameCloseButton=CreateFrame('Button','WorldMapFrameCloseButton',WorldMapFrame); Bounds(WorldMapFrameCloseButton,1000,820,1030,850)
WorldMapQuestScrollFrame=CreateFrame('Frame','WorldMapQuestScrollFrame',WorldMapFrame); Bounds(WorldMapQuestScrollFrame,810,300,1010,700)
WorldMapQuestScrollFrame:Hide()
WorldMapFrameAreaLabel=WorldMapFrame:CreateFontString()
local check=CreateFrame('CheckButton','WorldMapTrackQuest',WorldMapFrame); check:SetWidth(26); check:SetHeight(26); Bounds(check,100,150,126,176)
check.normal=check:CreateTexture(); check.normal:SetTexture('Interface\\Buttons\\UI-CheckBox-Up')
check.checkedTexture=check:CreateTexture(); check.checkedTexture:SetTexture('Interface\\Buttons\\UI-CheckBox-Check')
check.highlight=check:CreateTexture(); check.highlight:SetTexture('Interface\\Buttons\\UI-CheckBox-Highlight')
mapFile,continent,zone='Dragonblight',4,3
overlayPaths={'Interface\\WorldMap\\Dragonblight\\WYRMRESTTEMPLE'}
function GetMapInfo() return mapFile,768 end
function GetCurrentMapContinent() return continent end
function GetCurrentMapZone() return zone end
function GetMapZones() return 'Borean Tundra','Crystalsong Forest','Dragonblight','Grizzly Hills' end
function GetNumMapOverlays() return #overlayPaths end
function GetMapOverlayInfo(i) return overlayPaths[i],256,256,0,0 end
function GetCursorPosition() return 450,450 end
function UpdateMapHighlight(x,y) assert(math.abs(x-.5)<1e-9 and math.abs(y-.5)<1e-9); return 'Grizzly Hills','GrizzlyHills' end
function WorldMapFrame_Update() nativeMapUpdates=(nativeMapUpdates or 0)+1 end
Bounds(WorldMapButton,100,200,800,700); WorldMapButton:SetWidth(700); WorldMapButton:SetHeight(500)
mapAreaID,dungeonFloor,faction=0,0,'Horde'
function GetCurrentMapAreaID() return mapAreaID end
function GetCurrentMapDungeonLevel() return dungeonFloor end
function UnitFactionGroup() return faction,faction end
playerX,playerY=.4567,.1234
function GetPlayerMapPosition() return playerX,playerY end
local m=getmetatable(UIParent).__index
function m:IsMouseOver() return self==mouseOverTarget end
WorldMapTooltip=CreateFrame('GameTooltip','WorldMapTooltip',UIParent)
function WorldMapTooltip:SetOwner(o) self.owner=o; self.lines={} end
function WorldMapTooltip:IsOwned(o) return self.owner==o end
function WorldMapTooltip:AddLine(t) self.lines[#self.lines+1]=t end
function WorldMapTooltip:AddDoubleLine(l,r) self.lines[#self.lines+1]=l..'|'..r end
local register=m.RegisterEvent
function m:RegisterEvent(e) if e=='TAXIMAP_OPENED' then taxiEvents=self end; return register(self,e) end
taxiList={}
function NumTaxiNodes() return #taxiList end
function TaxiNodeName(i) return taxiList[i][1] end
function TaxiNodeGetType(i) return taxiList[i][2] end
local unitName=UnitName
function UnitName(u) if u=='npc' then return npcName end return unitName(u) end
''')
loader=lua.eval('function(s,n) return assert(loadstring(s,n)) end')
ns=lua.table()
for name in ['EUI_BlizzardSkin_335.lua','EUI_CharacterSheet_335.lua','EUI_WorldMap_335_Data.lua','EUI_WorldMap_335_Points.lua','EUI_WorldMap_335.lua']:
    loader((root/'EllesmereUIBlizzardSkin'/name).read_text(encoding='utf-8-sig'),name)('EllesmereUIBlizzardSkin',ns)
lua.globals().BS=ns
lua.execute(r'''
EllesmereUIDB={}
BS.addon:OnInitialize(); BS.addon:OnEnable()
assert(BS.WorldMapOverlays.Dragonblight.WyrmrestTemple and BS.WorldMapLevels.Dragonblight[1]==71)
local function Fog()
    local shown,paths={},{}
    for _,r in ipairs(WorldMapDetailFrame.regions or {}) do
        if r.kind=='Texture' and r.shown and type(r.texture)=='string' and r.texture:find('Interface\\WorldMap\\Dragonblight\\',1,true) then shown[#shown+1]=r; paths[#paths+1]=r.texture end
    end
    return shown,table.concat(paths,';')
end
-- Default keeps native fog; reveal draws only undiscovered areas, tinted.
WorldMapFrame_Update(); assert(#Fog()==0)
BS.SetValue('worldMapReveal',true)
local shown,paths=Fog()
assert(#shown>0 and not paths:lower():find('wyrmresttemple',1,true) and paths:find('AgmarsHammer1',1,true))
assert(shown[1].color[1]==.55 and shown[1].texcoords[2]<=1)
BS.SetValue('worldMapRevealTint',false); shown=Fog(); assert(shown[1].color[1]==1)
mapFile='Northrend'; zone=0; WorldMapFrame_Update(); assert(#Fog()==0)
mapFile='Dragonblight'; zone=3; WorldMapFrame_Update(); assert(#Fog()>0)
BS.SetValue('worldMapReveal',false); assert(#Fog()==0)
-- Zone map label and continent hover ranges.
local label=BS.worldMapZoneLabel
assert(label:GetText()=='Dragonblight  |cffffffff71-75|r' and label:GetParent():IsShown())
zone=0; mapFile='Northrend'; WorldMapFrame_Update(); assert(not label:GetParent():IsShown())
WorldMapFrameAreaLabel:SetText('Grizzly Hills'); WorldMapButton:RunScript('OnUpdate',.01)
assert(WorldMapFrameAreaLabel:GetText()=='Grizzly Hills  |cffffffff73-75|r')
WorldMapFrameAreaLabel:SetText('Grizzly Hills'); WorldMapButton:RunScript('OnUpdate',.01)
assert(WorldMapFrameAreaLabel:GetText()=='Grizzly Hills  |cffffffff73-75|r')
BS.SetValue('worldMapZoneLevels',false)
WorldMapFrameAreaLabel:SetText('Grizzly Hills'); WorldMapButton:RunScript('OnUpdate',.01)
assert(WorldMapFrameAreaLabel:GetText()=='Grizzly Hills')
zone=3; mapFile='Dragonblight'; WorldMapFrame_Update(); assert(not label:GetParent():IsShown())
BS.SetValue('worldMapZoneLevels',true); assert(label:GetParent():IsShown())
-- Fill hugs visible map controls; hidden quest panes do not widen it.
local s=BS.states[WorldMapFrame]; BS.Apply()
assert(s.panel.point[1]=='TOPRIGHT' and s.panel.point[4]==1036 and s.panel.point[5]==856,table.concat({tostring(s.panel.point[4]),tostring(s.panel.point[5])},','))
WorldMapQuestScrollFrame:Show(); BS.Apply(); assert(s.panel.point[4]==1036)
-- Inset check box: native-size box, solid accent fill, exact restoration.
local d=s.buttons[WorldMapTrackQuest]; assert(d and d.check)
assert(d.panel.point[1]=='BOTTOMRIGHT' and d.panel.point[4]==-5 and d.panel.point[5]==5)
local checked=WorldMapTrackQuest.checkedTexture
assert(checked.texture=='Interface\\Buttons\\WHITE8X8' and checked.color[4]==1 and checked.point[4]==-8 and checked.point[5]==8)
BS.SetValue('reskinWorldMap',false)
assert(checked.texture=='Interface\\Buttons\\UI-CheckBox-Check' and checked.allPoints==WorldMapTrackQuest)
BS.SetValue('reskinWorldMap',true); assert(checked.texture=='Interface\\Buttons\\WHITE8X8' and checked.point[4]==-8)
-- Instance entrances and faction flight points on the native area ID.
for id,list in pairs(BS.WorldMapInstances) do
    for _,entry in ipairs(list) do if entry[3][1][1]=='Naxxramas' then mapAreaID=id end end
end
assert(mapAreaID>0)
local function Markers()
    local list={}
    for _,f in ipairs(WorldMapButton.children) do if f.kind=='Frame' and f.shown and f.icon then list[#list+1]=f end end
    return list
end
WorldMapFrame_Update()
local raid,shared,dungeon,horde,neutral,alliance
for _,f in ipairs(Markers()) do
    assert(BS.owned[f] and BS.owned[f.icon] and BS.owned[f.ring] and f.point[2]==WorldMapButton and not f.backdrop)
    assert(math.abs(f.width-(f.markerKind=='flight' and 15.84 or 22))<1e-6)
    assert(f.shadow.texture:find('EllesmereUIBlizzardSkin\\Media\\WorldMapMarker'..(f.markerKind=='flight' and 'Shadow' or 'RingShadow'),1,true) and not f.fill)
    if f.markerKind=='raid' and f.data[1][1]=='Naxxramas' then raid=f end
    if f.markerKind=='raid' and #f.data==2 then shared=f end
    if f.markerKind=='dungeon' then dungeon=f end
    if f.markerKind=='flight' and f.data[5]=='H' then horde=f end
    if f.markerKind=='flight' and f.data[5]=='AH' then neutral=f end
    if f.markerKind=='flight' and f.data[5]=='A' then alliance=f end
end
assert(raid and shared and dungeon and horde and neutral and not alliance)
assert(math.abs(raid.point[4]-.874*700)<1e-6 and math.abs(raid.point[5]+.511*500)<1e-6)
local function Color(t,r,g,b) return math.abs(t.color[1]-r)<1e-6 and math.abs(t.color[2]-g)<1e-6 and math.abs(t.color[3]-b)<1e-6 end
assert(raid.ring.shown and not raid.icon.shown and Color(raid.ring,.3,.9,.35))
assert(dungeon.ring.shown and Color(dungeon.ring,.25,.62,1))
assert(horde.icon.shown and not horde.ring.shown and not horde.icon.desaturated and Color(horde.icon,1,.22,.18))
assert(horde.icon.texture:find('Media\\WorldMapMarkerFlight',1,true))
assert(Color(neutral.icon,1,.82,0))
assert(horde.data[6]>0 and BS.WorldMapTaxiNodes[horde.data[6]] and neutral.data[6]>0)
mouseOverTarget=shared; WorldMapButton:RunScript('OnUpdate',.01)
assert(WorldMapTooltip.owner==shared and WorldMapTooltip:IsShown() and #WorldMapTooltip.lines==2)
assert(WorldMapTooltip.lines[1]=='The Obsidian Sanctum|Raid 80  (10/25)')
assert(math.abs(shared.width-22*1.3)<1e-6)
mouseOverTarget=horde; WorldMapButton:RunScript('OnUpdate',.01)
assert(math.abs(shared.width-22)<1e-6 and math.abs(horde.width-15.84*1.3)<1e-6)
assert(WorldMapTooltip.owner==horde and WorldMapTooltip.lines[1]==horde.data[3] and WorldMapTooltip.lines[2]==horde.data[4] and #WorldMapTooltip.lines==2)
mouseOverTarget=nil; WorldMapButton:RunScript('OnUpdate',.01); assert(not WorldMapTooltip:IsShown() and math.abs(horde.width-15.84)<1e-6)
-- A flight master map scan marks undiscovered nodes green; translated node names match too.
local hordeNode,neutralNode=horde.data[6],neutral.data[6]
local translated=BS.WorldMapTaxiNodes[neutralNode][2] or BS.WorldMapTaxiNodes[neutralNode][1]
taxiList={{BS.WorldMapTaxiNodes[hordeNode][1],'NONE'},{translated,'REACHABLE'},{'Unknown Node','NONE'}}
taxiEvents:RunScript('OnEvent','TAXIMAP_OPENED')
assert(EllesmereUIBlizzardSkinCharDB.taxi[hordeNode]==false and EllesmereUIBlizzardSkinCharDB.taxi[neutralNode]==true)
assert(Color(horde.icon,.3,.9,.35) and Color(neutral.icon,1,.82,0))
mouseOverTarget=horde; WorldMapButton:RunScript('OnUpdate',.01)
assert(WorldMapTooltip.lines[1]==horde.data[3] and WorldMapTooltip.lines[3]=='Undiscovered')
mouseOverTarget=nil; WorldMapButton:RunScript('OnUpdate',.01)
taxiList={}; npcName=horde.data[3]; taxiEvents:RunScript('OnEvent','TAXIMAP_OPENED'); npcName=nil
assert(EllesmereUIBlizzardSkinCharDB.taxi[hordeNode]==true and Color(horde.icon,1,.22,.18))
faction='Alliance'; WorldMapFrame_Update()
local seenAlliance
for _,f in ipairs(Markers()) do
    assert(not (f.markerKind=='flight' and f.data[5]=='H'))
    if f.markerKind=='flight' and f.data[5]=='A' then seenAlliance=true; assert(Color(f.icon,.3,.6,1)) end
end
assert(seenAlliance)
BS.SetValue('worldMapFlightPoints',false)
for _,f in ipairs(Markers()) do assert(f.markerKind~='flight') end
BS.SetValue('worldMapInstances',false); assert(#Markers()==0)
BS.SetValue('worldMapInstances',true); BS.SetValue('worldMapFlightPoints',true); assert(#Markers()>0)
dungeonFloor=2; WorldMapFrame_Update(); assert(#Markers()==0)
dungeonFloor=0; mapAreaID=999999; WorldMapFrame_Update(); assert(#Markers()==0)
-- Player and cursor coordinates update while the map is open.
WorldMapButton:RunScript('OnUpdate',.1)
local c=BS.worldMapCoords
assert(c:GetText()=='|cffffd100Player|r 45.7, 12.3     |cffffd100Cursor|r 50.0, 50.0',c:GetText())
assert(BS.owned[c:GetParent()] and c:GetParent():IsShown())
WorldMapFrameAreaLabel:SetText(''); playerX,playerY=0,0; function GetCursorPosition() return 50,50 end
WorldMapButton:RunScript('OnUpdate',.1)
assert(c:GetText()=='|cffffd100Player|r --     |cffffd100Cursor|r --')
BS.SetValue('worldMapCoords',false); WorldMapButton:RunScript('OnUpdate',.1); assert(not c:GetParent():IsShown())
BS.SetValue('worldMapCoords',true)
''')
loader((root/'EllesmereUIOptions/EUI_BlizzardSkin_335_Options.lua').read_text(encoding='utf-8-sig'),'EUI_BlizzardSkin_335_Options.lua')()
lua.execute(r'''
rows={}; testModule.buildPage('Blizzard Window Skins',UIParent,0)
local reveal,levels
for _,row in ipairs(rows) do
    if row[1].text=='Reveal Unexplored Areas' then reveal=row end
    if row[1].text=='Zone Level Ranges' then levels=row end
end
assert(reveal and reveal[2].text=='Dim Unexplored Areas' and levels and levels[2].text=='Player & Cursor Coordinates')
local markersRow
for _,row in ipairs(rows) do if row[1].text=='Dungeon & Raid Entrances' then markersRow=row end end
assert(markersRow and markersRow[2].text=='Flight Points')
markersRow[2].setValue(false); assert(EllesmereUIDB.worldMapFlightPoints==false); markersRow[2].setValue(true)
reveal[1].setValue(true); assert(EllesmereUIDB.worldMapReveal==true)
levels[1].setValue(false); assert(EllesmereUIDB.worldMapZoneLevels==false)
testModule.onReset(); assert(EllesmereUIDB.worldMapReveal==nil and BS.GetValue('worldMapZoneLevels')==true)
''')
print('PASS: world map unexplored reveal/tint from EUI overlay data, zone and hover level ranges, fitted map fill, inset check boxes with exact restoration, instance/raid entrance and faction flight markers with tooltips, player/cursor coordinates, options rows and reset.')
