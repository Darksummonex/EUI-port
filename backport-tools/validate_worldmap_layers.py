"""World map art and pin layers share one coordinate space on Lua 5.1.

Models the Wrath 3.3.5 layout: WorldMapDetailFrame (1002x668 art) and its pin
layers are scaled by the native view functions (full 1.0, quest list 0.691,
windowed 0.573). The protected quest blob is anchored to the art, so a tainted
native view change in combat loses only the art's SetScale/SetPoint. EUI must
then keep every pin (party, corpse, arrow, quest POI, EUI markers) and the
cursor coordinates on the visible art, never touch the art in combat, never
write WORLDMAP_SETTINGS, and restore the native view after combat.
"""
from pathlib import Path
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime
lua = LuaRuntime()
lua.execute((root / 'backport-tools/wrath_mock.lua').read_text())
lua.execute(r'''
local m=getmetatable(UIParent).__index
function m:SetPoint(...) self.point={...} end
function m:GetPoint() return unpack(self.point or {}) end
function m:ClearAllPoints() self.point=nil end
function m:SetScale(s) self.scale=s end
function m:GetScale() return self.scale or 1 end
function m:GetEffectiveScale() local s,f=1,self; while f do s=s*(f.scale or 1); f=f.parent end; return s end
function m:SetFont(...) self.font={...} end
function m:SetFrameLevel(v) self.level=v end
function m:GetFrameLevel() return self.level or 1 end
function m:IsMouseOver() return false end
function m:HookScript(k,f) local prev=self.hooks[k]; self.hooks[k]=function(...) if prev then prev(...) end; f(...) end end
function m:RunScript(k,...) if self.scripts[k] then self.scripts[k](self,...) end; if self.hooks[k] then self.hooks[k](self,...) end end
function m:Show() local was=self.shown; self.shown=true; if not was then self:RunScript('OnShow') end end
function hooksecurefunc(target,key,callback)
    if type(target)=='string' then callback=key; key=target; target=_G end
    local original=target[key]
    target[key]=function(...) original(...); callback(...) end
end
combat,tainted,nativeDepth,blocked=false,false,0,{}
function InCombatLockdown() return combat end
local function Native(fn)
    return function(...)
        nativeDepth=nativeDepth+1
        local ok,err=pcall(fn,...)
        nativeDepth=nativeDepth-1
        if not ok then error(err,0) end
    end
end
WORLDMAP_WINDOWED_SIZE,WORLDMAP_QUESTLIST_SIZE,WORLDMAP_FULLMAP_SIZE=.573,.691,1
local store={size=WORLDMAP_QUESTLIST_SIZE,selectedQuestId=0}
WORLDMAP_SETTINGS=setmetatable({},{__index=store,__newindex=function(_,k,v)
    assert(nativeDepth>0,'EUI wrote WORLDMAP_SETTINGS.'..tostring(k)); store[k]=v
end})
-- Fullscreen layout: WorldMapFrame fills a 1024x768 screen at scale 1.
WorldMapFrame=CreateFrame('Frame','WorldMapFrame',nil); WorldMapFrame.width,WorldMapFrame.height=1024,768
WorldMapPositioningGuide=CreateFrame('Frame','WorldMapPositioningGuide',WorldMapFrame)
WorldMapDetailFrame=CreateFrame('Frame','WorldMapDetailFrame',WorldMapFrame)
WorldMapDetailFrame.width,WorldMapDetailFrame.height=1002,668
WorldMapButton=CreateFrame('Button','WorldMapButton',WorldMapFrame); WorldMapButton.width,WorldMapButton.height=1002,668
WorldMapFrameAreaFrame=CreateFrame('Frame','WorldMapFrameAreaFrame',WorldMapButton)
WorldMapPOIFrame=CreateFrame('Frame','WorldMapPOIFrame',WorldMapFrame); WorldMapPOIFrame.width,WorldMapPOIFrame.height=1002,668
WorldMapParty1=CreateFrame('Frame','WorldMapParty1',WorldMapButton)
WorldMapCorpse=CreateFrame('Frame','WorldMapCorpse',WorldMapButton)
WorldMapQuestPOI1=CreateFrame('Button','WorldMapQuestPOI1',WorldMapPOIFrame)
WorldMapTooltip=CreateFrame('GameTooltip','WorldMapTooltip',WorldMapFrame)
function WorldMapTooltip:IsOwned() return false end
-- The art belongs to the protected blob's anchor family.
local function Restricted(name)
    return function(self,...)
        if combat then
            assert(nativeDepth>0,'EUI touched the protected world map art in combat: '..name)
            if tainted then blocked[#blocked+1]=name; return end
        end
        return m[name](self,...)
    end
end
WorldMapDetailFrame.SetScale=Restricted('SetScale'); WorldMapDetailFrame.SetPoint=Restricted('SetPoint')
WorldMapDetailFrame.SetWidth=function() error('art width changed') end
WorldMapDetailFrame.SetHeight=function() error('art height changed') end
WorldMapDetailFrame.ClearAllPoints=function() error('art anchors cleared') end
m.SetPoint(WorldMapDetailFrame,'TOPLEFT',WorldMapPositioningGuide,'TOP',-726,-99)
m.SetScale(WorldMapDetailFrame,WORLDMAP_QUESTLIST_SIZE); WorldMapButton:SetScale(WORLDMAP_QUESTLIST_SIZE)
WorldMapButton:SetPoint('TOPLEFT',WorldMapDetailFrame,'TOPLEFT',0,0)
WorldMapPOIFrame:SetPoint('TOPLEFT',WorldMapDetailFrame,'TOPLEFT',0,0)

-- Native FrameXML view functions (WorldMapFrame.lua 3.3.5).
WorldMapFrame_SetFullMapView=Native(function()
    WORLDMAP_SETTINGS.size=WORLDMAP_FULLMAP_SIZE
    WorldMapDetailFrame:SetScale(WORLDMAP_FULLMAP_SIZE); WorldMapButton:SetScale(WORLDMAP_FULLMAP_SIZE)
    WorldMapFrameAreaFrame:SetScale(WORLDMAP_FULLMAP_SIZE)
    WorldMapDetailFrame:SetPoint('TOPLEFT',WorldMapPositioningGuide,'TOP',-502,-69)
end)
WorldMapFrame_SetQuestMapView=Native(function()
    WORLDMAP_SETTINGS.size=WORLDMAP_QUESTLIST_SIZE
    WorldMapDetailFrame:SetScale(WORLDMAP_QUESTLIST_SIZE); WorldMapButton:SetScale(WORLDMAP_QUESTLIST_SIZE)
    WorldMapFrameAreaFrame:SetScale(WORLDMAP_QUESTLIST_SIZE)
    WorldMapDetailFrame:SetPoint('TOPLEFT',WorldMapPositioningGuide,'TOP',-726,-99)
end)
WorldMap_ToggleSizeUp=Native(function()
    WORLDMAP_SETTINGS.size=WORLDMAP_QUESTLIST_SIZE
    WorldMapDetailFrame:SetScale(WORLDMAP_QUESTLIST_SIZE)
    WorldMapDetailFrame:SetPoint('TOPLEFT',WorldMapPositioningGuide,'TOP',-726,-99)
    WorldMapButton:SetScale(WORLDMAP_QUESTLIST_SIZE); WorldMapFrameAreaFrame:SetScale(WORLDMAP_QUESTLIST_SIZE)
end)
WorldMap_ToggleSizeDown=Native(function()
    WORLDMAP_SETTINGS.size=WORLDMAP_WINDOWED_SIZE
    WorldMapDetailFrame:SetScale(WORLDMAP_WINDOWED_SIZE); WorldMapButton:SetScale(WORLDMAP_WINDOWED_SIZE)
    WorldMapFrameAreaFrame:SetScale(WORLDMAP_WINDOWED_SIZE)
    WorldMapDetailFrame:SetPoint('TOPLEFT',37,-66)
end)
WorldMapFrame_Update=Native(function() end)
playerX,playerY,partyX,partyY,corpseX,corpseY,poiX,poiY=.372,.868,.55,.70,.10,.95,.80,.20
function GetPlayerMapPosition(unit) if unit=='player' then return playerX,playerY end; return partyX,partyY end
function PositionWorldMapArrowFrame(point,rel,relPoint,x,y) arrow={point=point,rel=rel,relPoint=relPoint,x=x,y=y,native=nativeDepth>0} end
WorldMapButton:SetScript('OnUpdate',Native(function()
    local w,h,size=WorldMapDetailFrame:GetWidth(),WorldMapDetailFrame:GetHeight(),WORLDMAP_SETTINGS.size
    PositionWorldMapArrowFrame('CENTER','WorldMapDetailFrame','TOPLEFT',playerX*w*size,-playerY*h*size)
    WorldMapParty1:SetPoint('CENTER','WorldMapDetailFrame','TOPLEFT',partyX*w,-partyY*h)
    WorldMapCorpse:SetPoint('CENTER','WorldMapDetailFrame','TOPLEFT',corpseX*w,-corpseY*h)
    local poiScale=size==WORLDMAP_WINDOWED_SIZE and WORLDMAP_WINDOWED_SIZE or WORLDMAP_QUESTLIST_SIZE
    WorldMapQuestPOI1:SetPoint('CENTER','WorldMapPOIFrame','TOPLEFT',poiX*w*poiScale,-poiY*h*poiScale)
end))

-- Screen geometry (WorldMapFrame units, origin top-left, y up).
function Art()
    local d=WorldMapDetailFrame; local p,ds=d.point,d:GetScale()
    local x,y
    if p[2]==WorldMapPositioningGuide then x,y=512+p[4]*ds,p[5]*ds else x,y=p[2]*ds,p[3]*ds end
    return x,y,d.width*ds,d.height*ds
end
function WorldMapDetailFrame:GetLeft() local x=Art(); return x/self:GetScale() end
function WorldMapDetailFrame:GetTop() local _,y=Art(); return (768+y)/self:GetScale() end
cursorX,cursorY=0,0
function GetCursorPosition() return cursorX,cursorY end
-- Fraction of the visible art a pin lands on, from its native offset and parent scale.
function Frac(offX,offY,parentScale)
    local _,_,w,h=Art(); return offX*parentScale/w,-offY*parentScale/h
end
''')
loader = lua.eval('function(s,n) return assert(loadstring(s,n)) end')
ns = lua.table()
lua.globals().BS = ns
lua.execute(r'''
EllesmereUIDB={}
BS.owned={}
local values={worldMapReveal=false,worldMapRevealTint=true,worldMapZoneLevels=true,worldMapInstances=true,worldMapFlightPoints=true,worldMapCoords=true}
function BS.GetValue(k) return values[k] end
function GetMapInfo() return 'UtgardeKeep',0 end
function GetNumMapOverlays() return 0 end
function GetCurrentMapContinent() return 4 end
function GetCurrentMapZone() return 0 end
function GetMapZones() end
mapAreaID,dungeonFloor=0,1
function GetCurrentMapAreaID() return mapAreaID end
function GetCurrentMapDungeonLevel() return dungeonFloor end
''')
for name in ['EUI_WorldMap_335_Data.lua', 'EUI_WorldMap_335_Points.lua', 'EUI_WorldMap_335.lua']:
    loader((root / 'EllesmereUIBlizzardSkin' / name).read_text(encoding='utf-8-sig'), name)('EllesmereUIBlizzardSkin', ns)
lua.execute(r'''
assert(type(BS.SyncWorldMapLayers)=='function')
for id,list in pairs(BS.WorldMapInstances) do
    for _,entry in ipairs(list) do if entry[3][1][1]=='Naxxramas' then naxx=id; naxxEntry=entry end end
end
assert(naxx)
markerSource={}
for _,entry in ipairs(BS.WorldMapInstances[naxx]) do markerSource[entry[3]]=entry end
local function Near(a,b,label) assert(math.abs(a-b)<1e-6,label..': '..tostring(a)..' vs '..tostring(b)) end
local function Aspect()
    local d=WorldMapDetailFrame
    assert(d.width==1002 and d.height==668,'art resized')
    local _,_,w,h=Art(); Near(w/h,1002/668,'art aspect')
end
function CheckPins(label,withPOI)
    WorldMapButton:RunScript('OnUpdate',.1)
    Aspect()
    local bs,ps=WorldMapButton:GetEffectiveScale(),WorldMapPOIFrame:GetEffectiveScale()
    local function Pin(f,x,y,what) local _,_,_,ox,oy=f:GetPoint(); local fx,fy=Frac(ox,oy,bs); Near(fx,x,label..' '..what..' x'); Near(fy,y,label..' '..what..' y') end
    Pin(WorldMapParty1,partyX,partyY,'party'); Pin(WorldMapCorpse,corpseX,corpseY,'corpse')
    assert(arrow and arrow.rel=='WorldMapDetailFrame' and arrow.relPoint=='TOPLEFT')
    local ax,ay=Frac(arrow.x,arrow.y,1); Near(ax,playerX,label..' arrow x'); Near(ay,playerY,label..' arrow y')
    if withPOI then
        local _,_,_,ox,oy=WorldMapQuestPOI1:GetPoint(); local qx,qy=Frac(ox,oy,ps)
        Near(qx,poiX,label..' quest POI x'); Near(qy,poiY,label..' quest POI y')
    end
    -- EUI markers live on WorldMapButton and use its 1002x668 space.
    for _,f in ipairs(WorldMapButton.children) do
        if f.markerKind and f.shown then
            local _,rel,_,ox,oy=f:GetPoint(); assert(rel==WorldMapButton)
            local src=f.markerKind=='flight' and f.data or markerSource[f.data]
            assert(src,label..' marker source')
            local fx,fy=Frac(ox,oy,bs); Near(fx,src[1]/100,label..' marker x'); Near(fy,src[2]/100,label..' marker y')
        end
    end
    -- Cursor at the centre of the visible art reads 50, 50; player text matches.
    local x,y,w,h=Art(); cursorX,cursorY=x+w/2,768+y-h/2
    WorldMapButton:RunScript('OnUpdate',.1)
    local text=BS.worldMapCoords:GetText()
    assert(text=='|cffffd100Player|r 37.2, 86.8     |cffffd100Cursor|r 50.0, 50.0',label..' coords '..tostring(text))
end
-- Untainted native views: art and pins share a scale in every mode.
WorldMapFrame:Show()
CheckPins('quest view',true)
WorldMapFrame_SetFullMapView(); CheckPins('full view',false)
WorldMapFrame_SetQuestMapView(); CheckPins('quest view again',true)
WorldMap_ToggleSizeDown(); CheckPins('windowed',true)
WorldMap_ToggleSizeUp(); WorldMapFrame_SetFullMapView(); CheckPins('size up full',false)
-- Outdoor zone with EUI raid entrance markers.
mapAreaID,dungeonFloor=naxx,0; WorldMapFrame_Update()
local markers=0; for _,f in ipairs(WorldMapButton.children) do if f.markerKind and f.shown then markers=markers+1 end end
assert(markers>0); CheckPins('outdoor markers',false)
mapAreaID,dungeonFloor=0,1; WorldMapFrame_Update()

-- Reported case: instance map in quest view, a tainted native switch to the
-- full view in combat keeps the art at 0.691 while size/button/arrow go to 1.0.
WorldMapFrame_SetQuestMapView()
combat,tainted=true,true; blocked={}
WorldMapFrame_SetFullMapView()
assert(#blocked==2 and WORLDMAP_SETTINGS.size==1 and math.abs(WorldMapDetailFrame:GetScale()-.691)<1e-9,'blocked art model')
CheckPins('combat-blocked full view (instance)',false)
Near(WorldMapButton:GetScale(),.691,'pins follow the art in combat')
assert(WORLDMAP_SETTINGS.size==1,'EUI must not rewrite the native view size')
-- Leaving combat restores the intended native full view on the art.
combat,tainted=false,false
for _,f in ipairs(allFrames) do if f.events and f.events.PLAYER_REGEN_ENABLED then f.scripts.OnEvent(f,'PLAYER_REGEN_ENABLED') end end
Near(WorldMapDetailFrame:GetScale(),1,'art restored'); Near(WorldMapButton:GetScale(),1,'pins restored')
local p=WorldMapDetailFrame.point; assert(p[2]==WorldMapPositioningGuide and p[4]==-502 and p[5]==-69,'full view anchor')
Near(WorldMapPOIFrame:GetScale(),1,'POI frame restored')
CheckPins('after combat full view',false)

-- Reverse: Show Quest Objectives switch blocked in combat (art stays 1.0).
combat,tainted=true,true
WorldMapFrame_SetQuestMapView()
assert(WORLDMAP_SETTINGS.size==WORLDMAP_QUESTLIST_SIZE and WorldMapDetailFrame:GetScale()==1)
CheckPins('combat-blocked quest view',true)
combat,tainted=false,false; BS.SyncWorldMapLayers()
Near(WorldMapDetailFrame:GetScale(),.691,'quest art restored'); p=WorldMapDetailFrame.point; assert(p[4]==-726 and p[5]==-99)
Near(WorldMapPOIFrame:GetScale(),1,'POI frame reset'); CheckPins('after combat quest view',true)

-- Windowed toggle blocked in combat.
combat,tainted=true,true
WorldMap_ToggleSizeDown()
CheckPins('combat-blocked windowed',true)
combat,tainted=false,false; BS.SyncWorldMapLayers()
Near(WorldMapDetailFrame:GetScale(),.573,'windowed art restored'); CheckPins('after combat windowed',true)

-- Untainted combat changes stay native; EUI does nothing to the art.
WorldMap_ToggleSizeUp(); combat=true; WorldMapFrame_SetFullMapView(); CheckPins('untainted combat full view',false)
combat=false
''')
print('PASS: world map art keeps 1002:668 at full/quest/windowed scale; party, corpse, arrow, quest POI, EUI markers and cursor/player coordinates land on the art in every view, in instance and outdoor maps, including native view changes blocked in combat; EUI never touches the protected art in combat nor writes WORLDMAP_SETTINGS, and restores the native view after combat.')
