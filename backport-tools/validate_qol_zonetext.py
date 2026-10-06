"""Zone Text on Wrath: Blizzard anchors ZoneTextFrame/SubZoneTextFrame at UIParent
BOTTOM +512, which sits mid-screen at small UI scales. The QoL Zone Text mover pins
both frames by CENTER to a mover anchored at UIParent CENTER +9,+322 physical pixels
(the Unlock Mode readout), re-applies after Blizzard/other re-anchors, keeps custom
positions, migrates a broken CENTER 0,0 once, and restores Blizzard's spot when off."""
from pathlib import Path
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

lua = LuaRuntime(unpack_returned_tuples=True)
for source in ['backport-tools/wrath_mock.lua', 'backport-tools/inventory_resources_mock.lua', 'backport-tools/qol_mock.lua', 'EllesmereUI/EllesmereUI_Lite.lua']:
    lua.execute((root / source).read_text(encoding='utf-8-sig'))
lua.execute('''
-- Alex's setup: 1920x1080, EUI UI scale 0.62 -> PP.mult = (768/1080)/0.62.
local PP=EllesmereUI.PP
PP.mult=(768/1080)/0.62
function PP.FromPixels(px) if px==0 then return 0 end; return px*PP.mult end
function PP.ToPixels(v) if v==0 then return 0 end; return math.floor(v/PP.mult+0.5+0.001) end
function GetZoneText() return 'Dalaran' end
-- Wrath ZoneText.xml anchors.
ZoneTextFrame=CreateFrame('Frame','ZoneTextFrame',UIParent); ZoneTextFrame:SetPoint('BOTTOM',UIParent,'BOTTOM',0,512)
SubZoneTextFrame=CreateFrame('Frame','SubZoneTextFrame',UIParent); SubZoneTextFrame:SetPoint('BOTTOM',UIParent,'BOTTOM',0,512)
setZoneTextCalls=0
function SetZoneText() setZoneTextCalls=setZoneTextCalls+1 end
-- Worst case: a layout pass that writes the anchor without the hooked SetPoint.
function UIParent_ManageFramePositions() ZoneTextFrame.points={{'BOTTOM',UIParent,'BOTTOM',0,512}} end
globalHooks={}
local tableHook=hooksecurefunc
function hooksecurefunc(target,key,fn)
    if type(target)=='string' then
        local original=_G[target]; globalHooks[target]=true
        _G[target]=function(...) local out={original(...)}; key(...); return unpack(out) end
    else tableHook(target,key,fn) end
end
''')
ns = lua.table()
lua.execute("ERR_INV_FULL='Inventory is full.'")
for name in ['EUI_QoL_335.lua', 'EUI_QoL_335_Displays.lua', 'EUI_QoL_335_Panels.lua', 'EUI_QoL_335_Mail.lua', 'EUI_QoL_335_Extras.lua']:
    lua.execute((root / 'EllesmereUIQoL' / name).read_text(encoding='utf-8-sig'), 'EllesmereUIQoL', ns)
lua.globals().Q = ns
core = (root / 'EllesmereUI/EllesmereUI_Lite.lua').read_text(encoding='utf-8-sig')
safe = lua.execute('local function errorhandler(' + core.split('local function errorhandler(', 1)[1].split('\n-------------------------------------------------------------------------------', 1)[0] + '\nreturn safecall')
safe(ns.addon.OnInitialize, ns.addon)
safe(ns.addon.OnEnable, ns.addon)
lua.execute('''
local p=Q.GetSettings(); local PP=EllesmereUI.PP
local mover=Q.frames.zoneText
assert(p.zoneText==true and p.zoneTextPosV1==true and p.positions.zoneText==nil,'Zone Text should default on with no saved position')
local function OnMover(z)
    local point,rel,relPoint,x,y=z:GetPoint(1)
    return z:GetNumPoints()==1 and point=='CENTER' and rel==mover and relPoint=='CENTER' and x==0 and y==0
end
local function MoverAt(px,py)
    local point,rel,relPoint,x,y=mover:GetPoint(1)
    return point=='CENTER' and rel==UIParent and relPoint=='CENTER' and PP.ToPixels(x)==px and PP.ToPixels(y)==py,
        tostring(point)..' '..tostring(relPoint)..' '..tostring(x)..','..tostring(y)
end
-- Default: zone text centred at UIParent CENTER +9,+322 physical pixels.
local ok,where=MoverAt(9,322); assert(ok,'Default mover position '..where)
local _,_,_,dx,dy=mover:GetPoint(1); assert(math.abs(dx-9*PP.mult)<1e-6 and math.abs(dy-322*PP.mult)<1e-6,'Default must be stored as pixels*mult')
assert(OnMover(ZoneTextFrame) and OnMover(SubZoneTextFrame),'Zone frames not pinned to the mover')
-- Blizzard / other re-anchors through SetPoint are undone.
ZoneTextFrame:ClearAllPoints(); ZoneTextFrame:SetPoint('BOTTOM',UIParent,'BOTTOM',0,512)
assert(OnMover(ZoneTextFrame),'SetPoint re-anchor survived')
SubZoneTextFrame:SetPoint('TOP',UIParent,'TOP',0,-100); assert(OnMover(SubZoneTextFrame),'Second anchor point survived')
-- ...and through the global layout passes.
assert(globalHooks.SetZoneText and globalHooks.UIParent_ManageFramePositions,'Global re-anchor hooks missing')
UIParent_ManageFramePositions(); assert(OnMover(ZoneTextFrame),'Layout pass re-anchor survived')
ZoneTextFrame.points={{'BOTTOM',UIParent,'BOTTOM',0,512}}; SetZoneText(true); assert(OnMover(ZoneTextFrame) and setZoneTextCalls==1)
-- Repeated applies keep a single anchor and never stack hooks.
Q.Apply(); Q.Apply(); assert(OnMover(ZoneTextFrame) and ZoneTextFrame:GetNumPoints()==1)
-- Unlock Mode: mover registered with Element Options, shown in preview with the zone name.
local el; for _,e in ipairs(unlockByFolder.EllesmereUIQoL) do if e.key=='EUI_ZoneText' then el=e end end
assert(el and el.label=='Zone Text' and el.getFrame()==mover and el.loadPos()==nil,'Zone Text mover missing')
local map=EllesmereUI._ELEMENT_SETTINGS_MAP.EUI_ZoneText
assert(map and map.module=='EllesmereUIQoL' and map.page=='Displays' and map.sectionName=='ZONE TEXT' and map.highlightText=='Move Zone Text')
assert(not mover:IsShown() and el.isHidden(),'Mover box must stay hidden outside Unlock Mode')
EllesmereUI.listeners.EllesmereUIQoL(true); assert(mover:IsShown() and not el.isHidden() and mover.text:GetText()=='Dalaran')
EllesmereUI.listeners.EllesmereUIQoL(false); assert(not mover:IsShown())
-- A custom position is kept and the zone text follows it.
el.savePos(nil,'CENTER','CENTER',PP.FromPixels(-40),PP.FromPixels(200)); Q.Apply()
ok,where=MoverAt(-40,200); assert(ok,'Custom position '..where); assert(OnMover(ZoneTextFrame))
-- A deliberate CENTER 0,0 after the migration flag is respected.
el.savePos(nil,'CENTER','CENTER',0,0); Q.Apply(); ok=MoverAt(0,0); assert(ok,'Deliberate 0,0 overridden')
el.clearPos(); ok,where=MoverAt(9,322); assert(ok and p.positions.zoneText==nil,'Reset must return to 9,322 '..where)
-- Off: Blizzard's own anchor comes back and is no longer fought.
p.zoneText=false; Q.Apply()
local point,rel,relPoint,x,y=ZoneTextFrame:GetPoint(1)
assert(ZoneTextFrame:GetNumPoints()==1 and point=='BOTTOM' and rel==UIParent and relPoint=='BOTTOM' and x==0 and y==512,'Blizzard anchor not restored')
point,rel,relPoint,x,y=SubZoneTextFrame:GetPoint(1); assert(point=='BOTTOM' and y==512)
ZoneTextFrame:ClearAllPoints(); ZoneTextFrame:SetPoint('TOP',UIParent,'TOP',0,-50); assert(select(1,ZoneTextFrame:GetPoint(1))=='TOP','Disabled mover fought another anchor')
p.zoneText=true; Q.Apply(); assert(OnMover(ZoneTextFrame))
-- QoL master switch off also restores.
p.enabled=false; Q.Apply(); assert(select(1,ZoneTextFrame:GetPoint(1))=='TOP'); p.enabled=true; Q.Apply(); assert(OnMover(ZoneTextFrame))
''')
# One-time migration of a broken CENTER 0,0 saved position.
lua.execute('''
local p=Q.GetSettings(); local PP=EllesmereUI.PP
p.zoneTextPosV1=nil; p.positions.zoneText={point='CENTER',relPoint='CENTER',x=0,y=0}; Q.Apply()
assert(p.positions.zoneText==nil and p.zoneTextPosV1==true,'Broken 0,0 position not migrated')
local _,_,_,x,y=Q.frames.zoneText:GetPoint(1); assert(PP.ToPixels(x)==9 and PP.ToPixels(y)==322)
p.zoneTextPosV1=nil; p.positions.zoneText={point='CENTER',relPoint='CENTER',x=50,y=-100}; Q.Apply()
assert(p.positions.zoneText and p.positions.zoneText.x==50 and p.zoneTextPosV1==true,'Custom position wrongly migrated')
p.positions.zoneText=nil; Q.Apply()
''')
# Static guards: the Displays chunk stays under Wrath's 200-local limit and avoids SetRotatesTexture.
src = (root / 'EllesmereUIQoL/EUI_QoL_335_Displays.lua').read_text(encoding='utf-8-sig')
assert 'SetRotatesTexture' not in src
assert '"zoneText","Zone Text",512,64,9,322,nil,"EUI_ZoneText","ZONE TEXT","Move Zone Text",true' in src
top_locals = sum(1 for line in src.splitlines() if line.startswith('local '))
assert top_locals < 200, top_locals
opts = (root / 'EllesmereUIOptions/EUI_QoL_335_Options.lua').read_text(encoding='utf-8-sig')
assert 'Section("ZONE TEXT")' in opts and 'Toggle(nil,"zoneText","Move Zone Text")' in opts
print('PASS: Zone Text pinned by CENTER to UIParent CENTER +9,+322 physical pixels (Unlock Mode readout) at UI scale 0.62; '
      'SetPoint/SetAllPoints/SetZoneText/UIParent_ManageFramePositions re-anchors undone; custom and deliberate 0,0 positions kept; '
      'broken 0,0 migrated once; Blizzard BOTTOM +512 restored when off; mover, preview and Element Options wired.')
