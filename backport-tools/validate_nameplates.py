"""Exercise the native Wrath plate lifecycle with the real Core Lua 5.1 dispatcher."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
retail=Path('D:/World of Warcraft/_retail_/Interface/AddOns/EllesmereUINameplates')
for original in retail.rglob('*'):
    if original.is_file() and original.suffix.lower()!='.toc':
        assert original.read_bytes()==(root/'EllesmereUINameplates'/original.relative_to(retail)).read_bytes(),original
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
lua=LuaRuntime()
lua.execute((root/'backport-tools/wrath_mock.lua').read_text())
lua.execute((root/'backport-tools/nameplates_mock.lua').read_text())
core=(root/'EllesmereUI/EllesmereUI_Lite.lua').read_text(encoding='utf-8-sig')
lua.execute(core)
lua.execute((root/'EllesmereUI/EUI_AuraFilters_335.lua').read_text())
lua.execute((root/'EllesmereUIOptions/EUI_AuraFilters_335_Options.lua').read_text())
lua.execute('function EllesmereUI.Widgets:WideButton() return {},40 end')
lua.execute('lifecycleErrors={}; function geterrorhandler() return function(err) lifecycleErrors[#lifecycleErrors+1]=err end end')
safe_source='local function errorhandler('+core.split('local function errorhandler(',1)[1].split('\n-------------------------------------------------------------------------------',1)[0]
safe=lua.execute(safe_source+'\nreturn safecall')
loader=lua.eval('function(s,n) return assert(loadstring(s,n)) end')
ns=lua.table()
loader((root/'EllesmereUINameplates/EUI_Nameplates_335.lua').read_text(),'EUI_Nameplates_335.lua')('EllesmereUINameplates',ns)
lua.globals().NP=ns
safe(ns.addon.OnInitialize,ns.addon); safe(ns.addon.OnEnable,ns.addon)
lua.execute('assert(#lifecycleErrors==0,lifecycleErrors[1])')
lua.execute('''
local a,b=NP.plates[plateA],NP.plates[plateB]; local p=NP.GetSettings()
assert(a and b and not NP.plates[irrelevant] and not NP.plates[foreign] and rendererWarning)
assert(not C_NamePlate and not C_UnitAuras and not C_Spell)
assert(cvars.showVKeyCastbar=='1' and _ENP_RefreshAllSettings==NP.Apply)
-- Owned overlays preserve the clickable native rectangle and selection alpha.
assert(plateA:GetWidth()==110 and plateA:GetHeight()==45 and plateA:GetAlpha()==1 and plateB:GetAlpha()==.5)
assert(plateA.parent==WorldFrame and plateA.point[4]==10 and plateA.mouse and a.root.mouse==false)
plateA:RunScript('OnMouseDown'); assert(plateA.clicks==1)
assert(a.native.health:GetAlpha()==0 and a.healthText:GetText()=='60%')
a.native.health:SetValue(17); assert(a.healthText:GetText()=='17%' and a.health:GetValue()==.17)
a.native.health:SetMinMaxValues(0,0); NP.Update(); assert(a.healthText:GetText()=='0%')
a.native.health:SetMinMaxValues(0,100)
local fonts=fontWrites; NP.Update(); NP.Update(); assert(fontWrites==fonts,'Fonts reset each tick')
a.native.cast:Show(); a.native.icon:SetTexture('native-icon'); NP.Update()
assert(a.cast:IsShown() and a.cast:GetValue()==1/3 and a.castText:GetText()=='' and a.castIcon:GetTexture()=='native-icon')
units.target={name='Mob',guid='GUID-A',cast=true,auras={HARMFUL={{name='other',caster='party1'},{name='mine',caster='player',stacks=3},{name='pet',caster='pet'}},HELPFUL={{name='buff'}}}}
NP.Update()
assert(a.unit=='target' and a.guid=='GUID-A' and a.isTarget and a.root:GetScale()==1.1)
assert(a.castText:GetText()=='Fireball' and a.castTimer:GetText()=='4.0' and math.abs(a.cast:GetValue()-.2)<1e-9)
assert(a.auras[1]:IsShown() and a.auras[1].count:GetText()==3 and a.auras[2]:IsShown() and not a.auras[3]:IsShown())
units.target.locked=true; NP.Update(); assert(a.cast.barColor[1]==.55)
units.target.cast=false; units.target.channel=true; NP.Update(); assert(a.castText:GetText()=='Drain Life' and a.cast:GetValue()==.8)
p.showBuffs=true; p.maxAuras=2; NP.Apply(); assert(not a.auras[3]:IsShown())
p.maxAuras=8; NP.Apply(); assert(a.auras[3]:IsShown())
-- Imported settings cannot address more icons than the allocated pool.
local savedAuras=units.target.auras
units.target.auras={HARMFUL={}}; for i=1,20 do units.target.auras.HARMFUL[i]={name='many',caster='player'} end
p.maxAuras=100; NP.Apply(); assert(a.auras[8]:IsShown())
units.target.auras=savedAuras; p.maxAuras=8; NP.Apply()
units.mouseover={name='Other',guid='GUID-B',auras={HARMFUL={{name='hover',caster='player'}}}}
b.native.highlight:Show(); NP.Update(); assert(b.unit=='mouseover' and b.auras[1]:IsShown())
-- Same-name candidates at full alpha are ambiguous: never clone target data.
b.native.name:SetText('Mob'); plateB:SetAlpha(1); NP.Update()
assert(not a.unit and not b.unit and not a.auras[1]:IsShown() and not b.auras[1]:IsShown())
plateB:SetAlpha(.5); b.native.name:SetText('Other'); NP.Update(); assert(a.unit=='target' and b.unit=='mouseover')
-- Recycled plate / same-name new GUID discards the old aura immediately.
plateA:Hide(); assert(not a.root:IsShown() and not a.auras[1]:IsShown())
units.target={name='Mob',guid='GUID-C'}; plateA:Show()
assert(a.guid=='GUID-C' and not a.auras[1]:IsShown() and a.castText:GetText()=='')
units.target=nil; units.mouseover=nil; NP.Update(); assert(not a.unit and not b.unit and not b.auras[1]:IsShown())
a.native.raid:SetTexture('raid-icons'); a.native.raid:SetTexCoord(.25,.5,.5,.75); a.native.raid:Show()
a.native.elite:Show(); NP.Update(); assert(a.raid:GetTexture()=='raid-icons' and a.raid.texcoords[1]==.25 and a.level:GetText()=='80+')
p.threatColors=true; a.native.threat:SetVertexColor(1,0,0); a.native.threat:Show(); NP.Apply()
assert(a.health.barColor[1]==1 and a.health.barColor[2]==.2)
p.tankMode=true; NP.Apply(); assert(a.health.barColor[1]==.1 and a.health.barColor[2]==.8)
p.friendlyNameOnly=true; b.native.health:SetStatusBarColor(0,1,0); NP.Apply()
assert(not b.health:IsShown() and not b.cast:IsShown() and b.root:IsShown() and b.name:GetText()=='Other')
-- Deferral is essential: native CVars and layout only change after combat.
local width=a.root:GetWidth(); combat=true; p.width=200; NP.Apply(); NP.SetNativeCVar('nameplateShowFriends',true)
assert(a.root:GetWidth()==width and cvars.nameplateShowFriends=='0')
combat=false; NP.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED')
assert(a.root:GetWidth()==200 and cvars.nameplateShowFriends=='1')
local state=a; p.enabled=false; NP.Apply()
assert(a.native.health:GetAlpha()==1 and a.native.name:GetAlpha()==1 and not a.root:IsShown() and cvars.showVKeyCastbar=='0')
plateA:RunScript('OnMouseDown'); assert(plateA.clicks==2)
p.enabled=true; NP.Apply(); assert(NP.plates[plateA]==state and a.root:IsShown())
local late=NativePlate('Late',.5); NP.events:RunScript('OnUpdate',.3); assert(NP.plates[late])
SlashCmdList.ELLESMERENAMEPLATES(); assert(optionsLoaded and shownModule=='EllesmereUINameplates')
''')
lua.execute('''
local p=NP.GetSettings(); p.classColoredNames=true; p.friendlyHealthClassColored=false; p.friendlyNameOnly=false
units.party1={name='Ally',guid='GUID-MAGE',player=true,class='MAGE',reaction=5}
local plate=NativePlate('Ally',.5); plate.children[1]:SetStatusBarColor(0,0,1)
NP.events:RunScript('OnEvent','PARTY_MEMBERS_CHANGED'); NP.Apply()
local s=NP.plates[plate]
assert(s.friendlyClass=='MAGE' and s.name.textColor[1]==.25 and s.health.barColor[3]==1)
assert(not s.unit and not s.guid and not s.auras[1]:IsShown(),'Roster class hints leaked into unit binding')
p.friendlyHealthClassColored=true; NP.Apply(); assert(s.health.barColor[1]==.25 and s.health.barColor[2]==.78)
p.classColoredNames=false; NP.Apply(); assert(s.name.textColor[1]==1 and s.health.barColor[1]==.25)
p.classColoredNames=true; p.friendlyHealthClassColored=false; NP.Apply()
assert(s.name.textColor[1]==.25 and s.health.barColor[1]==0)
p.friendlyNameOnly=true; NP.Apply(); assert(not s.health:IsShown() and s.name.textColor[1]==.25)
p.friendlyNameOnly=false; NP.Apply()
-- Members are removed/replaced when the native roster changes.
units.party1=nil; NP.events:RunScript('OnEvent','PARTY_MEMBERS_CHANGED')
assert(not s.friendlyClass and s.name.textColor[1]==1)
units.raid1={name='Ally',guid='GUID-PRIEST',player=true,class='PRIEST',reaction=5}
NP.events:RunScript('OnEvent','RAID_ROSTER_UPDATE'); assert(s.friendlyClass=='PRIEST')
units.raid2={name='Ally',guid='GUID-MAGE',player=true,class='MAGE',reaction=5}
NP.events:RunScript('OnEvent','RAID_ROSTER_UPDATE'); assert(not s.friendlyClass,'Duplicate roster names must be ambiguous')
units.raid1=nil; units.raid2=nil; NP.events:RunScript('OnEvent','RAID_ROSTER_UPDATE')
-- A non-group ally stays colored after mouseover/target is cleared.
units.mouseover={name='Ally',guid='GUID-MAGE',player=true,class='MAGE',reaction=5}
s.native.highlight:Show(); NP.Update(); assert(s.unit=='mouseover' and s.friendlyClass=='MAGE')
units.mouseover=nil; s.native.highlight:Hide(); NP.Update()
assert(not s.unit and not s.guid and s.friendlyClass=='MAGE' and s.name.textColor[1]==.25)
p.friendlyHealthClassColored=true; NP.Apply(); assert(s.health.barColor[1]==.25)
plate:Hide(); plate:Show(); assert(s.friendlyClass=='MAGE')
-- Do not paint a recycled NPC/enemy or an unresolved same-name player.
s.native.health:SetStatusBarColor(0,1,0); NP.Update(); assert(not s.friendlyClass and s.health.barColor[2]==1)
s.native.health:SetStatusBarColor(1,0,0); NP.Update(); assert(not s.friendlyClass and s.name.textColor[1]==1)
s.native.health:SetStatusBarColor(0,0,1)
local duplicate=NativePlate('Ally',.5); duplicate.children[1]:SetStatusBarColor(0,0,1); NP.Apply()
assert(not s.friendlyClass and not NP.plates[duplicate].friendlyClass)
duplicate:Hide(); NP.Update(); assert(s.friendlyClass=='MAGE')
s.native.name:SetText('Unknown'); NP.Update(); assert(not s.friendlyClass and s.health.barColor[3]==1)
s.native.name:SetText('Ally'); NP.Update(); assert(s.friendlyClass=='MAGE')
NP.events:RunScript('OnEvent','PLAYER_ENTERING_WORLD'); assert(not s.friendlyClass,'Old zone class hints must be cleared')
-- The existing name option still colors an identified enemy, without recoloring its bar.
units.target={name='Ally',guid='GUID-ENEMY',player=true,class='MAGE',reaction=2}
plate:SetAlpha(1); s.native.health:SetStatusBarColor(1,0,0); NP.Update()
assert(s.unit=='target' and not s.friendlyClass and s.name.textColor[1]==.25 and s.health.barColor[1]==1)
units.target=nil; NP.Update(); assert(s.name.textColor[1]==1)
units.focus={name='Ally',guid='GUID-MAGE',player=true,class='MAGE',reaction=5}
s.native.health:SetStatusBarColor(0,0,1); NP.Update(); units.focus=nil; NP.Update()
assert(s.friendlyClass=='MAGE' and s.name.textColor[1]==.25 and s.health.barColor[1]==.25)
colorState=s
''')
loader((root/'EllesmereUIOptions/EUI_Nameplates_335_Options.lua').read_text(),'EUI_Nameplates_335_Options.lua')()
lua.execute('''
assert(testModule.pages[1]=='Nameplates' and testModule.pages[2]=='Cast & Auras' and testModule.pages[3]=='Aura Filters' and testModule.pages[4]=='Fonts')
for _,page in ipairs(testModule.pages) do rows={}; assert(testModule.buildPage(page,UIParent,0)>0) end
rows={}; testModule.buildPage('Nameplates',UIParent,0)
rows[4][1].setValue(180); assert(NP.GetSettings().width==180 and NP.plates[plateA].root:GetWidth()==180)
rows[2][2].setValue(false); assert(cvars.nameplateShowFriends=='0')
local names,bars=0,0
for _,row in ipairs(rows) do for _,cfg in ipairs(row) do
    if cfg.text=='Class Colored Names' then
        names=names+1; cfg.setValue(false); assert(colorState.name.textColor[1]==1)
        cfg.setValue(true); assert(colorState.name.textColor[1]==.25)
    elseif cfg.text=='Class Colored Health Bar' then
        bars=bars+1; cfg.setValue(false); assert(colorState.health.barColor[1]==0)
        cfg.setValue(true); assert(colorState.health.barColor[1]==.25)
    end
end end
assert(names==1 and bars==1,'Reuse the existing name option with one new health-color option')
''')
for file in ['EUI_Fonts_Options.lua','EUI_Textures_Options.lua']:
    source=(root/'EllesmereUIOptions'/file).read_text(encoding='utf-8-sig')
    body=source.split('local function TileNameplates(',1)[1].split('local function TileUnitFrames(',1)[0]
    card=lua.execute('''local NS=function(folder) return EllesmereUI._ModuleNS[folder] end
local ModuleOutlineCfg=function() return {type='dropdown'} end
local BLANK=function() return {type='label'} end
local LinkRow=function(_,y,_,_,page) assert(page=='Nameplates'); return y-30 end
local function TileNameplates('''+body+'\nreturn TileNameplates')
    lua.globals().cardBuilder=card
    lua.execute("rows={}; assert(cardBuilder(UIParent,0,EllesmereUI.Widgets,{folder='EllesmereUINameplates',display='Nameplates'})<0)")
    if file=='EUI_Fonts_Options.lua':
        lua.execute("rows[1][2].setValue(14); assert(NP.GetSettings().nameSize==14 and NP.plates[plateA].name.font[2]==14)")
    else:
        lua.execute("rows[1][1].setValue('blizzard'); assert(NP.GetSettings().healthBarTexture=='blizzard' and NP.plates[plateA].health.barTexture=='Interface\\\\TargetingFrame\\\\UI-StatusBar')")
lua.execute('''
local p=NP.GetSettings(); local s=NP.plates[plateA]
units.target=nil; units.mouseover=nil; units.focus=nil
s.native.name:SetText('Mob'); s.native.health:SetStatusBarColor(1,0,0)
s.native.threat:SetVertexColor(1,0,0); s.native.threat:Show()
p.width=240; p.height=22; p.yOffset=16; p.targetScale=1.4; p.threatColors=false
NP.Apply()
-- The client can animate alpha after our tick. Its old-size texture must not leak.
s.native.threat:SetAlpha(.9)
assert(s.native.threat:GetTexture()=='' or not s.native.threat:GetTexture(),'Animated native aggro texture still renders at the old size')
assert(s.aggro and s.aggro:IsShown() and s.aggro.parent==s.health and s.aggro.allPoints==s.health)
assert(s.aggro.borderColor[1]==1 and s.aggro.borderColor[2]==0 and s.aggro.mouse==false)
assert(s.root:GetWidth()==240 and s.root:GetHeight()==22 and s.root.point[5]==16)
assert(plateA:GetWidth()==110 and plateA:GetHeight()==45 and plateA.point[4]==10)
units.target={name='Mob',guid='GUID-AGGRO'}; NP.Update()
assert(s.root:GetScale()==1.4 and s.aggro.allPoints==s.health)
-- Native warning colors, ending threat and hidden/recycled plates stay synchronized.
s.native.threat:SetVertexColor(1,1,0); NP.Update(); assert(s.aggro.borderColor[2]==1)
s.native.threat:Hide(); NP.Update(); assert(not s.aggro:IsShown())
s.native.threat:Show(); NP.Update(); assert(s.aggro:IsShown())
plateA:Hide(); assert(not s.aggro:IsShown()); s.native.threat:Hide(); plateA:Show(); assert(not s.aggro:IsShown())
units.target=nil; s.native.health:SetStatusBarColor(0,1,0); s.native.threat:Show()
p.friendlyNameOnly=true; NP.Apply(); assert(not s.aggro:IsShown() and not s.health:IsShown())
p.enabled=false; NP.Apply()
assert(s.native.threat:GetTexture()=='Interface\\\\TargetingFrame\\\\UI-TargetingFrame-Flash.blp' and s.native.threat:GetAlpha()==1)
assert(not s.aggro:IsShown())
p.enabled=true; NP.Apply(); assert(s.native.threat:GetTexture()=='' and not s.aggro:IsShown())
''')
print('PASS: real Core Lua 5.1 lifecycle; native plate detection/clicks/alpha, health/casts, unique mappings, aura recycling, friendly class colors, native animated aggro suppression and health-aligned border/resize/scale/reuse/restore, combat deferral and real module/shared options. Rendering and taint require in-game confirmation.')
