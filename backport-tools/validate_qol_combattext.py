"""QoL Self Combat Text: combat-log damage/heals/avoids on the player or vehicle,
combat enter/leave, scrolling and fading, Blizzard CombatText hidden, Unlock Mode and options."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
toc=(root/'EllesmereUIQoL/EllesmereUIQoL.toc').read_text(encoding='utf-8-sig')
assert 'EUI_QoL_335_Group.lua\r\nEUI_QoL_335_CombatText.lua' in toc or 'EUI_QoL_335_Group.lua\nEUI_QoL_335_CombatText.lua' in toc
lua=LuaRuntime(unpack_returned_tuples=True)
for source in ['backport-tools/wrath_mock.lua','backport-tools/inventory_resources_mock.lua','backport-tools/qol_mock.lua','EllesmereUI/EllesmereUI_Lite.lua']:
    lua.execute((root/source).read_text(encoding='utf-8-sig'))
ns=lua.table()
for name in ['EUI_QoL_335.lua','EUI_QoL_335_Displays.lua','EUI_QoL_335_Panels.lua','EUI_QoL_335_Mail.lua','EUI_QoL_335_Extras.lua','EUI_QoL_335_Group.lua','EUI_QoL_335_CombatText.lua']:
    lua.execute((root/'EllesmereUIQoL'/name).read_text(encoding='utf-8-sig'),'EllesmereUIQoL',ns)
lua.globals().Q=ns
lua.execute(r'''
local clock=100; function GetTime() return clock end
do local fs=UIParent:CreateFontString(); local mt=getmetatable(fs); local idx=mt and type(mt.__index)=='table' and mt.__index or fs
    if not fs.SetShadowOffset then idx.SetShadowOffset=function() end end
    if not fs.SetShadowColor then idx.SetShadowColor=function() end end
    if not fs.GetTextColor then local set=fs.SetTextColor; idx.SetTextColor=function(self,r,g,b,a) self._rgb={r,g,b}; if set then set(self,r,g,b,a) end end; idx.GetTextColor=function(self) return unpack(self._rgb or {}) end end
end
function UnitGUID(u) return 'guid-'..u end
vehicleUI=false; function UnitHasVehicleUI() return vehicleUI end
ENTERING_COMBAT='+Combat'; LEAVING_COMBAT='-Combat'; COMBAT_TEXT_DODGE='Dodge'
CombatText=CreateFrame('Frame','CombatText',UIParent); CombatText:Show()
Q.addon:OnInitialize(); Q.addon:OnEnable()
local p=Q.GetSettings(); local t=p.selfCombatText
assert(t and t.enabled==false and t.size==16 and t.anim=='straight' and t.damage==true,'defaults')
assert(not Q.sctAnchor and CombatText:IsShown(),'nothing built while off')
t.enabled=true; Q.Apply()
local a,ev=Q.sctAnchor,Q.sctEvents
assert(a and a:IsShown() and not CombatText:IsShown(),'on: anchor shown, Blizzard combat text hidden')
assert(ev.events.COMBAT_LOG_EVENT_UNFILTERED and ev.events.PLAYER_REGEN_DISABLED)
local function CL(sub,dst,...) ev:RunScript('OnEvent','COMBAT_LOG_EVENT_UNFILTERED',0,sub,'guid-mob','Mob',0,dst,'Me',0,...) end
local function Shown() local out={}; for i,fs in ipairs(Q.sctPool) do if fs:IsShown() then out[#out+1]=fs end end; return out end
local function Last() local best; for _,fs in ipairs(Q.sctPool) do if fs.live and (not best or fs.t0>=best.t0) then best=fs end end; return best end
CL('SWING_DAMAGE','guid-player',1234,0,1,0,0,0,nil)
local m=Last(); assert(m and m:GetText()=='-1,234' and m:IsShown(),'swing damage')
local r,g,b=m:GetTextColor(); assert(r==1 and g<.2,'damage color')
CL('SPELL_DAMAGE','guid-player',133,'Fireball',4,25000,0,4,0,0,0,1)
m=Last(); assert(m:GetText()=='-25,000' and m.fontKind==2,'crit spell damage uses crit size')
CL('SPELL_HEAL','guid-player',2061,'Flash Heal',2,3000,500,0,nil)
m=Last(); assert(m:GetText()=='+3,000','heal')
CL('SWING_MISSED','guid-player','DODGE'); assert(Last():GetText()=='Dodge','avoid label')
CL('SPELL_MISSED','guid-player',133,'Fireball',4,'REFLECT'); assert(Last():GetText()=='Reflect','fallback label')
local n=#Shown(); CL('SWING_DAMAGE','guid-party1',50,0,1,0,0,0,nil); assert(#Shown()==n,'other targets ignored')
CL('SWING_DAMAGE','guid-vehicle',50,0,1,0,0,0,nil); assert(#Shown()==n,'vehicle ignored outside a vehicle')
vehicleUI=true; CL('SWING_DAMAGE','guid-vehicle',50,0,1,0,0,0,nil); assert(Last():GetText()=='-50','vehicle hits shown'); vehicleUI=false
ev:RunScript('OnEvent','PLAYER_REGEN_DISABLED'); assert(Last():GetText()=='+Combat')
-- Stagger keeps the newest at the anchor and pushes older ones up.
local newest=Last(); assert(newest.y0==0)
for _,fs in ipairs(Q.sctPool) do if fs.live and fs~=newest then assert(fs.y0>0,'older messages pushed') end end
-- Scrolling and fading run on OnUpdate and stop when the last one ends.
assert(a.scripts.OnUpdate)
clock=clock+1.9*0.85; a:RunScript('OnUpdate',0.1); local alpha=newest:GetAlpha(); assert(alpha>0 and alpha<1,'fading near the end '..tostring(alpha))
clock=clock+5; a:RunScript('OnUpdate',0.1); assert(#Shown()==0 and not a.scripts.OnUpdate,'idle once all faded')
-- Abbreviation and per-type toggles.
assert(Q.SCT_FormatAmount(1234567,true)=='1.2M' and Q.SCT_FormatAmount(25000,true)=='25K' and Q.SCT_FormatAmount(1500,true)=='1.5K' and Q.SCT_FormatAmount(950,true)=='950')
t.damage=false; t.heal=false; t.avoid=false; Q.Apply(); assert(not ev.events.COMBAT_LOG_EVENT_UNFILTERED,'combat log only when needed')
t.combat=false; Q.Apply(); assert(not ev.events.PLAYER_REGEN_DISABLED)
t.damage=true; t.heal=true; t.avoid=true; t.combat=true
-- Fountain alternates sides.
t.anim='fountain'; Q.Apply(); CL('SWING_DAMAGE','guid-player',1,0,1,0,0,0,nil); local l1=Last().lane; clock=clock+.01
CL('SWING_DAMAGE','guid-player',2,0,1,0,0,0,nil); assert(Last().lane==-l1 and l1~=0,'fountain lanes')
-- Unlock Mode element and saved position.
local el=Q.SCT_UnlockElement(); assert(el.key=='EUI_SelfCombatText' and el.getFrame()==a and not el.isHidden())
el.savePos(nil,'CENTER','CENTER',10,-20); assert(p.positions.selfCombatText.x==10)
local pt,rel,_,x,y=a:GetPoint(1); assert(pt=='CENTER' and x==10 and y==-20,'saved position applied')
el.clearPos(); assert(not p.positions.selfCombatText)
assert(EllesmereUI._ELEMENT_SETTINGS_MAP.EUI_SelfCombatText.sectionName=='SELF COMBAT TEXT')
-- Off: events dropped, Blizzard combat text back.
t.enabled=false; Q.Apply(); assert(not a:IsShown() and CombatText:IsShown() and not next(ev.events),'off restores Blizzard')
''')
opts=(root/'EllesmereUIOptions'/'EUI_QoL_335_Options.lua').read_text(encoding='utf-8')
for needle in ['Section("SELF COMBAT TEXT")','Toggle("selfCombatText","enabled","Self Combat Text")','"anim","Animation"','Color("selfCombatText","combatColor"']:
    assert needle in opts, needle
print('PASS: Self Combat Text off by default; combat-log damage (crits larger), heals, avoids on the player or vehicle only; combat enter/leave; stagger, fade and idle OnUpdate; fountain lanes; abbreviation; events only for enabled types; Blizzard CombatText hidden and restored; Unlock Mode position and Element Options; options section.')
