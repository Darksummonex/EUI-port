"""Exercise the native Wrath plate lifecycle with the real Core Lua 5.1 dispatcher."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
retail=Path('D:/World of Warcraft/_retail_/Interface/AddOns/EllesmereUINameplates')
for original in retail.rglob('*'):
    if original.is_file() and original.suffix.lower()!='.toc':
        assert original.read_bytes()==(root/'EllesmereUINameplates'/original.relative_to(retail)).read_bytes(),original
toc=(root/'EllesmereUINameplates/EllesmereUINameplates.toc').read_text()
assert 'EUI_Nameplates_335.lua\nEUI_Nameplates_335_Display.lua' in toc and 'EllesmereUINameplates.lua' not in toc
for path in ['background','execute-glow','shield','striped-v2','Arrows/arrow_leftx2']:
    assert (root/'EllesmereUINameplates/Media_335'/(path+'.tga')).is_file(),path
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
for name in ['EUI_Nameplates_335.lua','EUI_Nameplates_335_Display.lua']:
    loader((root/'EllesmereUINameplates'/name).read_text(),name)('EllesmereUINameplates',ns)
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
-- Retail default look: 150x17 bar, name above, health % right, level left, .12 bg, 1 px .067 border.
assert(a.root:GetWidth()==150 and a.root:GetHeight()==17 and a.cast:GetHeight()==17)
assert(a.name.slot=='top' and a.healthText.slot=='right' and a.level.slot=='left')
assert(a.name.point[1]=='BOTTOM' and a.name.point[3]=='TOP' and a.name.point[5]==4)
assert(a.healthText.point[1]=='RIGHT' and a.healthText.point[4]==-2 and a.level.point[1]=='LEFT')
assert(a.healthBg.color[1]==.12 and a.healthBg.color[4]==1 and a.border.t.color[1]==.067 and a.border.t.height==1)
assert(a.health.barColor[1]==.8 and a.health.barColor[2]==.137,'Retail enemy color')
assert(a.native.health:GetAlpha()==0 and a.healthText:GetText()=='60%')
a.native.health:SetValue(17); assert(a.healthText:GetText()=='17%' and a.health:GetValue()==.17)
a.native.health:SetMinMaxValues(0,0); NP.Update(); assert(a.healthText:GetText()=='0%')
a.native.health:SetMinMaxValues(0,100)
local fonts=fontWrites; NP.Update(); NP.Update(); assert(fontWrites==fonts,'Fonts reset each tick')
a.native.cast:Show(); a.native.icon:SetTexture('native-icon'); NP.Update()
assert(a.cast:IsShown() and a.cast:GetValue()==1/3 and a.castText:GetText()=='' and a.castIcon.tex:GetTexture()=='native-icon')
assert(a.cast.barColor[1]==.7 and a.cast.barColor[2]==.4,'Retail purple cast color')
assert(a.castIcon.point[1]=='TOPRIGHT' and a.castIcon.point[3]=='TOPLEFT' and a.castIcon:GetWidth()==17)
assert(a.castSpark.texture:find('cast_spark.tga',1,true) and a.castSpark:IsShown() and a.castBg.color[4]==.9)
-- Smooth fill: anonymous plates mirror the native bar every frame, not only on the throttled refresh.
assert(a.cast:GetScript('OnUpdate'),'cast fill needs a per-frame OnUpdate while casting')
a.native.cast:SetValue(1.5); a.cast:RunScript('OnUpdate',.016); assert(a.cast:GetValue()==.5,'native cast not mirrored per frame')
a.native.cast:SetValue(1)
units.target={name='Mob',guid='GUID-A',cast=true,auras={HARMFUL={{name='other',caster='party1'},{name='mine',caster='player',stacks=3},{name='pet',caster='pet'}},HELPFUL={{name='buff'}}}}
NP.Update()
assert(a.unit=='target' and a.guid=='GUID-A' and a.isTarget and a.root:GetScale()==1)
assert(a.glow:IsShown() and a.glow.pieces[1].color[1]==.41 and a.glow.pieces[1].texture:find('background.tga',1,true))
assert(a.castText:GetText()=='Fireball' and a.castTimer:GetText()=='4.0' and math.abs(a.cast:GetValue()-.2)<1e-9)
-- Identified casts advance from GetTime() each frame between throttled refreshes (no 20 Hz steps).
local tick=a.cast:GetScript('OnUpdate'); assert(tick,'cast fill needs a per-frame OnUpdate while casting')
local updates=0; local realUpdate=NP.Update; NP.Update=function(...) updates=updates+1; return realUpdate(...) end
now=2.016; a.cast:RunScript('OnUpdate',.016); assert(math.abs(a.cast:GetValue()-(1.016/5))<1e-9,'fill stepped instead of following GetTime')
now=2.033; a.cast:RunScript('OnUpdate',.017); assert(math.abs(a.cast:GetValue()-(1.033/5))<1e-9 and a.castTimer:GetText()=='4.0')
now=3.5; a.cast:RunScript('OnUpdate',.016); assert(math.abs(a.cast:GetValue()-.5)<1e-9 and a.castTimer:GetText()=='2.5')
now=6.5; a.cast:RunScript('OnUpdate',.016); assert(a.cast:GetValue()==1 and not a.castSpark:IsShown(),'finished cast clamps full')
assert(updates==0,'per-frame fill must not run the full plate refresh'); NP.Update=realUpdate
now=2; NP.Update(); assert(a.cast:GetScript('OnUpdate')==tick and a.castSpark:IsShown() and a.castTimer:GetText()=='4.0')
assert(a.auras[1]:IsShown() and a.auras[1].count:GetText()==3 and a.auras[2]:IsShown() and not a.auras[3]:IsShown())
assert(a.auras[1].time:GetText()=='10' and a.auras[1].time.point[1]=='TOPLEFT')
-- Debuffs centred above the name (2 x 26 + 2 spacing), enemy buffs left of the bar.
assert(a.auras[1].point[1]=='BOTTOMLEFT' and a.auras[1].point[2]==a.name and a.auras[1].point[4]==-27 and a.auras[1].point[5]==2)
assert(a.auras[2].point[4]==1 and a.auras[1]:GetWidth()==26)
assert(a.buffs[1]:IsShown() and a.buffs[1].point[1]=='BOTTOMRIGHT' and a.buffs[1].point[3]=='BOTTOMLEFT' and a.buffs[1].point[4]==-2 and a.buffs[1]:GetWidth()==24)
units.target.locked=true; NP.Update(); assert(a.cast.barColor[1]==.45 and a.castShield:IsShown())
units.target.locked=false; NP.Update(); assert(not a.castShield:IsShown())
-- The Retail swatch "Interrupt on CD" tints while the kick cools down.
EllesmereUI.ComputeCastBarTint=function(ready,base) return ready.r,ready.g,ready.b end
NP.Update(); assert(a.cast.barColor[1]==.92); EllesmereUI.ComputeCastBarTint=nil
-- Kick tick sits where the cast will be when the kick is ready: 1 - (4-1)/5 = .4 of 150.
EllesmereUI.GetKickCooldownRemaining=function() return 1 end
NP.Update(); assert(a.kickTick:IsShown() and a.kickTick.point[4]==60)
EllesmereUI.GetKickCooldownRemaining=function() return 0 end; NP.Update(); assert(not a.kickTick:IsShown())
EllesmereUI.GetKickCooldownRemaining=nil
p.hideEnemyNameWhileCasting=true; NP.Update(); assert(a.name:GetText()=='')
p.hideEnemyNameWhileCasting=false; NP.Update(); assert(a.name:GetText()=='Mob')
units.target.cast=false; units.target.channel=true; NP.Update(); assert(a.castText:GetText()=='Drain Life' and a.cast:GetValue()==.8)
-- Channels drain smoothly per frame.
now=2.5; a.cast:RunScript('OnUpdate',.016); assert(math.abs(a.cast:GetValue()-.7)<1e-9 and a.castTimer:GetText()=='3.5'); now=2; NP.Update()
-- Interrupted flash on identified casts.
units.target.channel=false; a.native.cast:Hide()
NP.events:RunScript('OnEvent','UNIT_SPELLCAST_INTERRUPTED','target')
assert(a.cast:IsShown() and a.cast.barColor[1]==.8 and a.cast.barColor[2]==0 and a.castText:GetText()=='Interrupted')
assert(not a.cast:GetScript('OnUpdate'),'interrupted flash keeps a per-frame fill running')
now=2.7; NP.Update(); assert(not a.cast:IsShown() and not a.cast:GetScript('OnUpdate'),'OnUpdate must stop once the cast ends'); now=2; a.flashUntil=nil
p.onlyPlayerDebuffs=false; p.maxAuras=2; NP.Apply(); assert(a.auras[2]:IsShown() and not a.auras[3]:IsShown())
p.maxAuras=8; NP.Apply(); assert(a.auras[3]:IsShown())
-- Imported settings cannot address more icons than the allocated pool.
local savedAuras=units.target.auras
units.target.auras={HARMFUL={}}; for i=1,20 do units.target.auras.HARMFUL[i]={name='many',caster='player'} end
p.maxAuras=100; NP.Apply(); assert(a.auras[8]:IsShown() and #a.auras==8)
units.target.auras=savedAuras; p.maxAuras=5; p.onlyPlayerDebuffs=true; NP.Apply()
units.mouseover={name='Other',guid='GUID-B',auras={HARMFUL={{name='hover',caster='player'}}}}
b.native.highlight:Show(); NP.Update(); assert(b.unit=='mouseover' and b.auras[1]:IsShown() and b.hover:IsShown())
-- Same-name candidates at full alpha are ambiguous: never clone target data.
b.native.name:SetText('Mob'); plateB:SetAlpha(1); NP.Update()
assert(not a.unit and not b.unit and not a.auras[1]:IsShown() and not b.auras[1]:IsShown())
plateB:SetAlpha(.5); b.native.name:SetText('Other'); NP.Update(); assert(a.unit=='target' and b.unit=='mouseover')
-- Recycled plate / same-name new GUID discards the old aura immediately.
plateA:Hide(); assert(not a.root:IsShown() and not a.auras[1]:IsShown())
units.target={name='Mob',guid='GUID-C'}; plateA:Show()
assert(a.guid=='GUID-C' and not a.auras[1]:IsShown() and not a.cast:IsShown())
units.target=nil; units.mouseover=nil; b.native.highlight:Hide(); NP.Update(); assert(not a.unit and not b.unit and not b.auras[1]:IsShown())
a.native.raid:SetTexture('raid-icons'); a.native.raid:SetTexCoord(.25,.5,.5,.75); a.native.raid:Show()
a.native.elite:Show(); NP.Update(); assert(a.raid:GetTexture()=='raid-icons' and a.raid.texcoords[1]==.25 and a.level:GetText()=='80+')
assert(a.raid.point[1]=='BOTTOMRIGHT' and a.raid.point[3]=='TOPRIGHT' and a.raid:GetWidth()==24)
assert(a.health.barColor[1]==.8,'Elite color is instance-only')
instanceType='party'; NP.Update(); assert(a.health.barColor[1]==.518); instanceType='none'
a.native.boss:SetTexture('skull'); a.native.boss:Show(); NP.Update()
assert(a.class:IsShown() and a.class:GetTexture()=='skull' and a.level:GetText()=='??' and a.health.barColor[1]==.518)
a.native.boss:Hide(); a.native.elite:Hide(); NP.Update(); assert(not a.class:IsShown() and a.health.barColor[1]==.8)
-- Threat: native glow for anonymous plates, unit API once identified; Retail role palette.
a.native.threat:SetVertexColor(1,0,0); a.native.threat:Show()
p.threatColorMode='always'; NP.Apply(); assert(a.health.barColor[1]==.8,'Solo non-tank has no threat colors')
groupSize=1; NP.Update(); assert(a.health.barColor[1]==1 and a.health.barColor[2]==.5)
a.native.threat:SetVertexColor(1,.6,0); NP.Update(); assert(a.health.barColor[1]==.81)
p.threatRole='tank'; a.native.threat:SetVertexColor(1,0,0); NP.Apply(); assert(a.health.barColor[1]==.8)
p.classicTankAggro=true; NP.Apply(); assert(a.health.barColor[1]==.05)
units.target={name='Mob',guid='GUID-T',threat=0,combat=true}; NP.Update()
assert(a.unit=='target' and a.health.barColor[1]==1 and a.health.barColor[2]==.22)
p.threatColorBorder=true; p.threatColorHealth=false; NP.Apply()
assert(a.border.t.color[1]==1 and a.border.t.color[2]==.22 and a.health.barColor[1]==.8)
p.threatColorMode='instances'; NP.Apply(); assert(a.border.t.color[1]==.067)
p.threatColorBorder=false; p.threatColorHealth=true; p.threatRole='auto'; p.classicTankAggro=false; groupSize=0; units.target=nil
-- Older profiles keep their choices under the Retail keys.
p.threatColors=true; p.tankMode=true; p.showTargetBorder=false; NP.Apply()
assert(p.threatColorMode=='always' and p.threatRole=='tank' and p.targetEffect=='none' and p.threatColors==nil and p.tankMode==nil)
p.threatColorMode='instances'; p.threatRole='auto'; p.targetEffect='glow'
-- Friendly plates are name-only by default, at the Retail friendly name size.
b.native.health:SetStatusBarColor(0,1,0); NP.Apply()
assert(not b.health:IsShown() and not b.cast:IsShown() and b.root:IsShown() and b.name:GetText()=='Other' and b.name.font[2]==15)
b.native.health:SetStatusBarColor(1,0,0); NP.Apply(); assert(b.health:IsShown() and b.name.font[2]==11)
-- Deferral is essential: native CVars and layout only change after combat.
local width=a.root:GetWidth(); combat=true; p.width=200; NP.Apply(); NP.SetNativeCVar('nameplateShowFriends',true)
assert(a.root:GetWidth()==width and cvars.nameplateShowFriends=='0')
combat=false; NP.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED')
assert(a.root:GetWidth()==200 and a.cast:GetWidth()==200 and cvars.nameplateShowFriends=='1')
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
assert(s.friendlyClass=='MAGE' and s.name.textColor[1]==.25 and s.health.barColor[1]==.314)
assert(not s.unit and not s.guid and not s.auras[1]:IsShown(),'Roster class hints leaked into unit binding')
p.friendlyHealthClassColored=true; NP.Apply(); assert(s.health.barColor[1]==.25 and s.health.barColor[2]==.78)
p.classColoredNames=false; NP.Apply(); assert(s.name.textColor[1]==1 and s.health.barColor[1]==.25)
p.classColoredNames=true; p.friendlyHealthClassColored=false; NP.Apply()
assert(s.name.textColor[1]==.25 and s.health.barColor[1]==.314)
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
s.native.name:SetText('Unknown'); NP.Update(); assert(not s.friendlyClass and s.health.barColor[1]==.314)
s.native.name:SetText('Ally'); NP.Update(); assert(s.friendlyClass=='MAGE')
NP.events:RunScript('OnEvent','PLAYER_ENTERING_WORLD'); assert(not s.friendlyClass,'Old zone class hints must be cleared')
-- The existing name option still colors an identified enemy, without recoloring its bar.
units.target={name='Ally',guid='GUID-ENEMY',player=true,class='MAGE',reaction=2}
plate:SetAlpha(1); s.native.health:SetStatusBarColor(1,0,0); NP.Update()
assert(s.unit=='target' and not s.friendlyClass and s.name.textColor[1]==.25 and s.health.barColor[1]==.8)
units.target=nil; NP.Update(); assert(s.name.textColor[1]==1)
units.focus={name='Ally',guid='GUID-MAGE',player=true,class='MAGE',reaction=5}
s.native.health:SetStatusBarColor(0,0,1); NP.Update(); units.focus=nil; NP.Update()
assert(s.friendlyClass=='MAGE' and s.name.textColor[1]==.25 and s.health.barColor[1]==.25)
colorState=s
''')
loader((root/'EllesmereUIOptions/EUI_Nameplates_335_Options.lua').read_text(),'EUI_Nameplates_335_Options.lua')()
lua.execute('''
local pages=testModule.pages
assert(pages[1]=='Display' and pages[2]=='Colors' and pages[3]=='General' and pages[4]=='Aura Filters' and #pages==4)
for _,page in ipairs(pages) do rows={}; assert(testModule.buildPage(page,UIParent,0)>0) end
local function Find(label)
    for _,row in ipairs(rows) do for _,cfg in ipairs(row) do if cfg.text==label then return cfg end end end
    error('Missing option '..label)
end
local p,a=NP.GetSettings(),NP.plates[plateA]
rows={}; testModule.buildPage('Display',UIParent,0)
Find('Health Bar Width').setValue(180); assert(p.width==180 and a.root:GetWidth()==180)
Find('Top Text').setValue('healthPercent'); assert(a.healthText.slot=='top' and not a.name.slot and a.name:GetText()=='')
Find('Top Text').setValue('enemyName'); assert(a.name.slot=='top' and a.name:GetText()=='Mob')
Find('Background').setValue(50); assert(p.bgAlpha==.5 and a.healthBg.color[4]==.5 and Find('Background').getValue()==50)
Find('Background').setValue(100)
Find('Border').setValue('none'); assert(p.showBorder==false and not a.border.t:IsShown() and not a.castBorder.l:IsShown() and Find('Border').getValue()=='none')
assert(a.castBorder:IsShown(),'Border None must keep cast text, timer, shield and kick tick')
Find('Border').setValue('basic'); assert(a.border.t:IsShown() and a.castBorder.l:IsShown() and a.border.t.height==1)
-- Core positions: one element per slot, written back as the engine's per-element slot.
assert(Find('Top').getValue()=='debuffs' and Find('Left').getValue()=='buffs' and Find('Right').getValue()=='none')
assert(Find('Top Right').getValue()=='raidmarker' and Find('Top Left').getValue()=='classification' and Find('Bottom').getValue()=='none')
Find('Right').setValue('debuffs'); assert(p.debuffSlot=='right' and Find('Top').getValue()=='none')
Find('Top Right').setValue('buffs'); assert(p.buffSlot=='topright' and p.raidMarkerSlot=='none')
Find('Bottom').setValue('raidmarker'); assert(p.raidMarkerSlot=='bottom' and a.raid.point[1]=='TOP' and a.raid.point[2]==a.cast)
p.debuffSlot,p.buffSlot,p.raidMarkerSlot='top','left','topright'; NP.Apply()
Find('Right Text').setValue('enemyName'); assert(p.textSlotRight=='enemyName' and p.textSlotTop=='none' and a.name.slot=='right')
p.textSlotTop,p.textSlotRight='enemyName','healthPercent'; NP.Apply()
-- Older Wrath profiles stored the enemy name as 'name'.
p.textSlotTop='name'; NP.Apply(); assert(p.textSlotTop=='enemyName' and a.name.slot=='top')
-- Every Retail text element is offered, in Retail order.
local top=Find('Top Text')
local expected={'none','---','enemyName','levelName','nameLevel','level','targetOfTarget','healthPercent','healthPercentNoSign',
    'healthNumber','healthPctNum','healthNumPct','healthPctNumDash','healthNumPctDash'}
assert(#top.order==#expected)
for i,k in ipairs(expected) do assert(top.order[i]==k,'order '..i); assert(k=='---' or top.values[k],'missing value '..k) end
assert(top.values.nameLevel=='Name | Level' and top.values.levelName=='Level | Name' and top.values.targetOfTarget=='Target of Target')
assert(top.values.healthPercentNoSign=='Health % (No Sign)' and top.values.healthPctNum=='Health % | #' and top.values.healthNumPctDash=='Health # - %')
-- Blizzard default abbreviation tiers, as Retail's health numbers.
for n,text in pairs({[999]='999',[1000]='1K',[1234]='1.2K',[12345]='12K',[1234567]='1.2M',[12345678]='12M',[1500000000]='1.5B'}) do
    assert(NP.AbbreviateNumber(n)==text,n..' -> '..NP.AbbreviateNumber(n))
end
-- Health text elements read the native bar's absolute values.
a.native.health:SetMinMaxValues(0,250000); a.native.health:SetValue(123456)
for element,text in pairs({healthPercent='49%',healthPercentNoSign='49',healthNumber='123K',healthPctNum='49% | 123K',
    healthNumPct='123K | 49%',healthPctNumDash='49% - 123K',healthNumPctDash='123K - 49%'}) do
    Find('Right Text').setValue(element); local fs=NP.TextString(a,element)
    assert(fs.slot=='right' and fs:GetText()==text,element..': '..tostring(fs:GetText()))
    assert(fs.font[2]==p.healthTextSize)
end
p.healthPctDecimal=true; Find('Right Text').setValue('healthPercent'); assert(a.healthText:GetText()=='49.4%')
Find('Right Text').setValue('healthPercentNoSign'); assert(NP.TextString(a,'healthPercentNoSign'):GetText()=='49.4')
p.healthPctDecimal=false; p.showHealthText=false; NP.Apply(); assert(NP.TextString(a,'healthPercentNoSign'):GetText()=='')
p.showHealthText=true; Find('Right Text').setValue('healthNumber'); Find('Left Text').setValue('healthPercent')
assert(NP.TextString(a,'healthNumber'):GetText()=='123K' and a.healthText.slot=='left' and a.healthText:GetText()=='49%','two health texts coexist')
-- Name family: level combos share the name string, so one evicts another; standalone level coexists.
Find('Left Text').setValue('level'); Find('Top Text').setValue('nameLevel')
assert(a.name.slot=='top' and a.name.element=='nameLevel' and a.name:GetText()=='Mob | |cffffffff80|r' and a.level:GetText()=='80')
Find('Center Text').setValue('levelName'); assert(p.textSlotTop=='none' and a.name.slot=='center' and a.name:GetText()=='|cffffffff80|r | Mob')
p.showLevel=false; NP.Apply(); assert(a.name:GetText()=='Mob' and a.level:GetText()==''); p.showLevel=true
-- Retail: combined health text is unavailable beside a centered name.
assert(Find('Right Text').disabledValues('healthPctNum') and Find('Left Text').disabledValues('healthNumPctDash'))
assert(not Find('Right Text').disabledValues('healthNumber') and not Find('Top Text').disabledValues and not Find('Center Text').disabledValues)
Find('Center Text').setValue('none'); assert(not Find('Right Text').disabledValues('healthPctNum'))
-- Target of Target: identified plates show their unit's target, players by class.
units.target={name='Mob',guid='GUID-TOT'}; units.targettarget={name='Healer',player=true,class='MAGE',reaction=5}
Find('Center Text').setValue('targetOfTarget'); local tot=NP.TextString(a,'targetOfTarget')
assert(a.unit=='target' and tot.slot=='center' and tot:GetText()=='Healer' and tot.textColor[1]==.25 and tot.font[2]==p.totSize)
units.targettarget={name='Boar'}; NP.Update(); assert(tot:GetText()=='Boar' and tot.textColor[1]==1)
units.target=nil; units.targettarget=nil; NP.Update(); assert(not a.unit and tot:GetText()=='','anonymous plates have no target of target')
p.textSlotTop,p.textSlotLeft,p.textSlotRight,p.textSlotCenter='enemyName','level','healthPercent','none'
a.native.health:SetMinMaxValues(0,100); a.native.health:SetValue(60); NP.Apply()
assert(a.name:GetText()=='Mob' and a.healthText:GetText()=='60%' and tot:GetText()=='' and not tot.slot)
p.borderSize=0; p.showBorder=true; NP.Apply(); assert(p.showBorder==false and p.borderSize==1); p.showBorder=true; NP.Apply()
Find('Class Colored Names').setValue(false); assert(colorState.name.textColor[1]==1)
Find('Class Colored Names').setValue(true); assert(colorState.name.textColor[1]==.25)
rows={}; testModule.buildPage('Colors',UIParent,0)
Find('Class Colored Health Bar').setValue(false); assert(colorState.health.barColor[1]==.314)
Find('Class Colored Health Bar').setValue(true); assert(colorState.health.barColor[1]==.25)
Find('Enemy').setValue(.5,.1,.1); assert(a.health.barColor[1]==.5); Find('Enemy').setValue(.8,.137,.137)
rows={}; testModule.buildPage('General',UIParent,0)
Find('Show Friendly Nameplates').setValue(false); assert(cvars.nameplateShowFriends=='0')
assert(Find('Stacking Nameplates').getValue()==true)
Find('Stacking Nameplates').setValue(false); assert(cvars.nameplateAllowOverlap=='1')
Find('Stacking Nameplates').setValue(true); assert(cvars.nameplateAllowOverlap=='0')
Find('Show Enemy Pet Nameplates').setValue(true); assert(cvars.nameplateShowEnemyPets=='1')
local buffFilter=Find('Enemy Buff Filter'); assert(buffFilter.getValue()=='timed')
buffFilter.setValue('showall'); assert(not p.buffHasDuration and not p.buffStealable and p.buffFilterMode=='all' and buffFilter.getValue()=='showall')
assert(NP.GetSettings().buffHasDuration==false and NP.plates[plateA])
buffFilter.setValue('dispellable'); assert(p.buffStealable and buffFilter.getValue()=='dispellable')
buffFilter.setValue('timed'); assert(p.buffHasDuration and not p.buffStealable)
Find('Hide Enemy Nameplates out of Combat').setValue(true); assert(cvars.nameplateShowEnemies=='0')
NP.events:RunScript('OnEvent','PLAYER_REGEN_DISABLED'); assert(cvars.nameplateShowEnemies=='1')
NP.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); assert(cvars.nameplateShowEnemies=='0')
Find('Hide Enemy Nameplates out of Combat').setValue(false); assert(cvars.nameplateShowEnemies=='1')
''')
lua.execute('''
-- Inline Retail widgets: rows with real half-regions and the core inline builders.
local W=EllesmereUI.Widgets; local oldRow,oldHeader=W.DualRow,W.SectionHeader
local swatches,cogs,popups,refreshers,headerBuilt,headerH={}, {}, {}, {}, nil, nil
local function Half(row) local r=CreateFrame('Frame',nil,row); r._control=CreateFrame('Frame',nil,r); return r end
function W:DualRow(parent,y,left,right) local row=CreateFrame('Frame',nil,parent); row._leftRegion,row._rightRegion=Half(row),Half(row); rows[#rows+1]={left,right}; return row,50 end
function W:SectionHeader(parent,text,y) local f=CreateFrame('Frame',nil,parent); local fs=f:CreateFontString(); fs:SetText(text)
    f.label=text; f.GetPoint=function() return 'TOPLEFT',parent,'TOPLEFT',0,y end; return f,30 end
local hits,glowed,scrolledTo,dismissed={},nil,nil,0
function EllesmereUI.CreatePreviewHitOverlay(el,navigate,key,isText)
    local b=CreateFrame('Button',nil,el.CreateTexture and el or el.parent); b.key,b.navigate=key,navigate; hits[#hits+1]=b
    if isText then b._resizeToText=function() b.resized=(b.resized or 0)+1 end end
    return b
end
function EllesmereUI.MakeSettingGlow() return function(target) glowed=target end end
function EllesmereUI.SmoothScrollTo(y) scrolledTo=y end
function EllesmereUI.DismissPreviewHint(hint) dismissed=dismissed+1; EllesmereUIDB=EllesmereUIDB or {}; EllesmereUIDB.previewHintDismissed=true end
function EllesmereUI.MakeFont(parent) return parent:CreateFontString() end
C_Timer={After=function(_,fn) fn() end}
function EllesmereUI.BuildColorSwatch(rgn,level,get,set) local sw=CreateFrame('Button',nil,rgn); sw.get,sw.set=get,set; swatches[#swatches+1]=sw; return sw,function() end end
function EllesmereUI.BuildInlineCog(rgn,opts) assert(not opts.disabled or opts.disabledTooltip,'cog needs disabledTooltip'); local b=CreateFrame('Button',nil,rgn); b.opts=opts; cogs[#cogs+1]=b; return b,opts.show end
function EllesmereUI.BuildCogPopup(opts) popups[#popups+1]=opts; return {},function(btn) opts.shownFor=btn end end
function EllesmereUI.RegisterWidgetRefresh(fn) refreshers[#refreshers+1]=fn end
function EllesmereUI.ShowWidgetTooltip() end; function EllesmereUI.HideWidgetTooltip() end
function EllesmereUI:SetContentHeader(fn) headerBuilt=fn(UIParent) end
function EllesmereUI:SetContentHeaderHeightSilent(h) headerH=h end
EllesmereUI.RESIZE_ICON,EllesmereUI.EYE_VISIBLE_ICON,EllesmereUI.EYE_INVISIBLE_ICON='resize','eye','eye-off'
local p=NP.GetSettings()
for _,page in ipairs({'Display','Colors','General'}) do rows={}; assert(testModule.buildPage(page,UIParent,0)>0,page) end
local firstNew=#allFrames+1
rows={}; swatches,cogs,refreshers={}, {}, {}; testModule.buildPage('Display',UIParent,0)
local made={}; for i=firstNew,#allFrames do made[#made+1]=allFrames[i] end
local function IsEye(f) local t=f.regions and f.regions[1]; return t and (t.texture=='eye' or t.texture=='eye-off') end
assert(headerBuilt and headerBuilt>40 and NP.preview.plate.parent==UIParent,'Display page builds the preview header')
assert(#swatches>=10 and #cogs>=12,'inline swatches/cogs: '..#swatches..'/'..#cogs)
for _,fn in ipairs(refreshers) do fn() end
-- The border swatch dims with Border: None and writes the border color.
local border=swatches[1]; assert(border:GetAlpha()==1)
p.showBorder=false; for _,fn in ipairs(refreshers) do fn() end; assert(border:GetAlpha()==.15); p.showBorder=true
border.set(.5,.5,.5); assert(p.borderColor.r==.5 and headerH); border.set(.067,.067,.067)
-- Slot cogs open the popup of the element held by their slot; eyes follow their element.
local slotCog
for _,b in ipairs(cogs) do if b.opts.title=='Slot' and b.opts.show and not b.opts.disabled() then slotCog=slotCog or b end end
assert(slotCog); slotCog.opts.show(slotCog); assert(popups[#popups].title=='Debuffs' and popups[#popups].shownFor==slotCog)
local eyes={}
for _,f in ipairs(made) do if IsEye(f) then eyes[#eyes+1]=f end end
assert(#eyes==2,'raid marker and classification eyes: '..#eyes)
for _,f in ipairs(eyes) do assert(f.shown and f.parent~=UIParent,'eye sits on its slot row') end
p.raidMarkerSlot='none'; p.classificationSlot='none'; for _,fn in ipairs(refreshers) do fn() end
local hiddenEyes=0; for _,f in ipairs(eyes) do if not f.shown then hiddenEyes=hiddenEyes+1 end end
assert(hiddenEyes==2,'Eyes hide when their element has no slot')
p.raidMarkerSlot='topright'; for _,fn in ipairs(refreshers) do fn() end
local before=NP.previewHidden.raidmarker
for _,f in ipairs(eyes) do if f.shown and f.regions[1].texture=='eye' then f.scripts.OnClick(f) end end
local anyHidden=false; for k,v in pairs(NP.previewHidden) do if v then anyHidden=true end end
assert(anyHidden and NP.previewHidden.classification==nil,'eye toggles its element on the preview')
for k in pairs(NP.previewHidden) do NP.previewHidden[k]=nil end
-- Header cache cycle: hiding the preview must not reset it, showing it repaints it.
local pv=NP.preview
pv.plate.hooks.OnHide(); assert(pv.root:IsShown() and pv.isTarget,'cache hide reset the preview')
pv.root:Hide(); pv.auras[1]:Hide(); pv.plate.hooks.OnShow(); assert(pv.root:IsShown() and pv.auras[1]:IsShown(),'cache restore did not repaint')
-- Click-to-navigate: every element has an overlay; clicking scrolls to and glows its row.
local byKey={}; for _,b in ipairs(hits) do byKey[b.key]=byKey[b.key] or b end
for _,key in ipairs({'healthBar','castBar','castIcon','castName','castTimer','enemyName','healthText','levelText','raidMarker','classIcon',
    'targetArrows','classResource','debuffIcon','buffIcon','auraStack','auraDuration'}) do assert(byKey[key],'missing preview overlay '..key) end
local function Click(key) glowed,scrolledTo=nil,nil; byKey[key].navigate(key); return glowed end
assert(Click('healthBar') and scrolledTo and scrolledTo>0 and dismissed==1)
local spellName=Click('castName'); local castTimer=Click('castTimer')
assert(spellName and castTimer and spellName~=castTimer and spellName.parent==castTimer.parent,'spell name and timer glow the two halves of one row')
p.textSlotRight='enemyName'; p.textSlotTop='none'; local nameRight=Click('enemyName')
p.textSlotTop='enemyName'; p.textSlotRight='healthPercent'; local nameTop=Click('enemyName')
assert(nameRight and nameTop and nameRight~=nameTop,'enemy name follows its text slot')
-- Every text element has a preview overlay that glows the slot holding it.
for _,key in ipairs({'targetOfTarget','healthPercentNoSign','healthNumber','healthPctNum','healthNumPct','healthPctNumDash','healthNumPctDash'}) do
    assert(byKey[key],'missing preview overlay '..key)
end
p.textSlotTop='nameLevel'; assert(Click('enemyName')==nameTop,'name combos navigate with the name'); p.textSlotTop='enemyName'
p.textSlotLeft='healthNumber'; local hpNum=Click('healthNumber'); p.textSlotLeft='level'; assert(hpNum and hpNum==Click('levelText'))
p.textSlotCenter='targetOfTarget'; local totCenter=Click('targetOfTarget'); p.textSlotCenter='none'
assert(totCenter and totCenter~=nameTop and totCenter~=hpNum)
-- Text cogs: health elements share the size and % decimal settings; empty slots are disabled.
local textCogs={}; for _,b in ipairs(cogs) do if b.opts.title=='Text' then textCogs[#textCogs+1]=b end end
assert(#textCogs==4 and textCogs[4].opts.disabled() and not textCogs[2].opts.disabled())
p.textSlotRight='healthNumPct'; textCogs[2].opts.show(textCogs[2])
assert(popups[#popups].title=='Health # | %' and popups[#popups].rows[2].label=='Show % Decimal')
-- Each text slot also has a gear cog for the outline of the text it holds.
local outlineCogs={}; for _,b in ipairs(cogs) do if b.opts.title=='Outline' then outlineCogs[#outlineCogs+1]=b end end
assert(#outlineCogs==4 and outlineCogs[4].opts.disabled() and not outlineCogs[2].opts.disabled())
outlineCogs[2].opts.show(outlineCogs[2]); local ol=popups[#popups].rows[1]
assert(ol.label=='Outline' and ol.get()=='module'); ol.set('thick'); assert(p.healthTextOutline=='thick'); ol.set('module')
p.textSlotRight='healthPercent'
p.textSlotCenter='targetOfTarget'; textCogs[4].opts.show(textCogs[4]); assert(popups[#popups].title=='Target of Target' and popups[#popups].rows[1].label=='Size')
p.textSlotCenter='none'
p.raidMarkerSlot='bottom'; local raidBottom=Click('raidMarker'); p.raidMarkerSlot='topright'; local raidTR=Click('raidMarker')
assert(raidBottom and raidTR and raidBottom~=raidTR,'raid marker follows its core slot'); NP.Apply()
p.showClassPower=true; NP.PaintPreview(); assert(pv.pips[1]:IsShown(),'preview shows sample class resource')
p.raidMarkerSlot='topright'; p.classificationSlot='topleft'; NP.Apply()
W.DualRow,W.SectionHeader=oldRow,oldHeader
EllesmereUI.SetContentHeader=nil; EllesmereUI.SetContentHeaderHeightSilent=nil
''')
for file in ['EUI_Fonts_Options.lua','EUI_Textures_Options.lua']:
    source=(root/'EllesmereUIOptions'/file).read_text(encoding='utf-8-sig')
    body=source.split('local function TileNameplates(',1)[1].split('local function TileUnitFrames(',1)[0]
    card=lua.execute('''local NS=function(folder) return EllesmereUI._ModuleNS[folder] end
local ModuleOutlineCfg=function() return {type='dropdown'} end
local BLANK=function() return {type='label'} end
local LinkRow=function(_,y,_,_,page,section) assert(page=='Display' and section=='STYLE'); return y-30 end
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
p.width=240; p.height=22; p.yOffset=16; p.targetScale=1.4
NP.Apply()
-- The client can animate alpha after our tick. Its old-size texture must not leak.
s.native.threat:SetAlpha(.9)
assert(s.native.threat:GetTexture()=='' or not s.native.threat:GetTexture(),'Animated native aggro texture still renders at the old size')
assert(s.root:GetWidth()==240 and s.root:GetHeight()==22 and s.root.point[5]==16 and s.cast:GetWidth()==240)
assert(plateA:GetWidth()==110 and plateA:GetHeight()==45 and plateA.point[4]==10)
units.target={name='Mob',guid='GUID-AGGRO'}; NP.Update()
assert(s.root:GetScale()==1.4 and s.glow:IsShown() and s.glow.point[4]==6)
p.showTargetArrows=true; p.targetArrowStyle='double'; NP.Apply()
assert(s.arrowL:IsShown() and s.arrowR:IsShown() and s.arrowL:GetWidth()==22 and s.arrowL.texture:find('arrow_leftx2.tga',1,true))
assert(s.arrowL.point[1]=='RIGHT' and s.arrowL.point[4]==-8)
p.targetArrowClassColor=true; NP.Apply(); assert(s.arrowL.color[1]==RAID_CLASS_COLORS.WARRIOR.r)
p.showTargetArrows=false; p.targetArrowClassColor=false; NP.Apply(); assert(not s.arrowL:IsShown())
-- Execute pulse glow: a Warrior with Execute learnt glows at 20%.
s.native.health:SetValue(15); NP.Update(); assert(not s.exec:IsShown())
knownSpells.Execute=true; NP.events:RunScript('OnEvent','SPELLS_CHANGED')
NP.Update(); assert(s.exec:IsShown() and s.exec.pieces[1].texture:find('execute-glow.tga',1,true))
s.native.health:SetValue(60); NP.Update(); assert(not s.exec:IsShown())
p.hashLineEnabled=true; NP.Apply(); assert(s.hash:IsShown() and s.hash.point[4]==71)
p.hashLineEnabled=false; NP.Apply(); assert(not s.hash:IsShown())
p.targetTexture='striped-v2'; NP.Apply(); assert(s.targetTex:IsShown() and s.targetTex.texture:find('striped-v2.tga',1,true))
p.targetTexture='none'; NP.Apply(); assert(not s.targetTex:IsShown())
p.targetEffect='border'; NP.Apply(); assert(not s.glow:IsShown() and s.border.t.color[1]==1)
p.targetEffect='highlight'; NP.Apply(); assert(s.highlight:IsShown() and s.border.t.color[1]==.067)
p.targetEffect='glow'; p.enableTargetColor=true; NP.Apply(); assert(s.health.barColor[1]==.41)
p.enableTargetColor=false
-- Combo points only for Rogue/Druid, on the target plate.
comboPoints=3; NP.Update(); assert(not s.pips[1]:IsShown())
units.player={name='Me',guid='ME',class='ROGUE'}; NP.Update()
local rogue=RAID_CLASS_COLORS.ROGUE or {r=1}
assert(s.pips[3]:IsShown() and s.pips[3].color[1]==rogue.r and s.pips[4].color[1]==.2 and s.pips[1]:GetWidth()==14)
units.player=nil; comboPoints=0; NP.Update(); assert(not s.pips[1]:IsShown())
-- Native warning state stays synchronized across recycle and restore.
plateA:Hide(); assert(not s.root:IsShown()); plateA:Show(); assert(s.root:IsShown())
units.target=nil; s.native.health:SetStatusBarColor(0,1,0)
p.friendlyNameOnly=true; NP.Apply(); assert(not s.health:IsShown())
p.enabled=false; NP.Apply()
assert(s.native.threat:GetTexture()=='Interface\\\\TargetingFrame\\\\UI-TargetingFrame-Flash.blp' and s.native.threat:GetAlpha()==1)
p.enabled=true; NP.Apply(); assert(s.native.threat:GetTexture()=='')
''')
lua.execute('''
-- Options header preview: the real renderer on a stand-in plate, outside the live plate list.
local p=NP.GetSettings(); p.friendlyNameOnly=true; p.width=150; p.height=17; p.yOffset=0; p.targetScale=1; NP.Apply()
local header=CreateFrame('Frame'); local s=NP.CreatePreview(header); local h=NP.PaintPreview()
for _,state in pairs(NP.plates) do assert(state~=s,'Preview joined the live plates') end
assert(h>40 and s.root:IsShown() and s.health:IsShown() and s.glow:IsShown() and s.health.barColor[1]==.8)
assert(s.name:GetText()=='Enemy Name Text' and s.healthText:GetText()=='72%' and s.level:GetText()=='80')
assert(s.auras[1]:IsShown() and s.auras[1].count:GetText()==3 and s.auras[2]:IsShown() and s.buffs[1]:IsShown())
assert(s.castText:GetText()=='Spell Name' and s.castTimer:GetText()=='2.3' and s.castIcon:IsShown())
assert(s.raid:IsShown() and s.class:IsShown() and s.plate.point[3]=='TOP')
NP.previewHidden.raidmarker=true; NP.previewHidden.classification=true; NP.PaintPreview()
assert(not s.raid:IsShown() and not s.class:IsShown())
NP.previewHidden.raidmarker=nil; NP.previewHidden.classification=nil
p.showCastBar=false; local short=NP.PaintPreview(); assert(not s.cast:IsShown() and short<h); p.showCastBar=true
s.plate:Hide(); s.plate:Show(); NP.PaintPreview(); assert(s.auras[1]:IsShown(),'Header cache restore dropped preview auras')
assert(NP.CreatePreview(UIParent)==s and s.plate.parent==UIParent)
-- Every text element paints sample text on the preview (72% of 10,000; the player stands in as Target of Target).
local samples={enemyName='Enemy Name Text',levelName='|cffffd10080|r | Enemy Name Text',nameLevel='Enemy Name Text | |cffffd10080|r',
    level='80',targetOfTarget='Player',healthPercent='72%',healthPercentNoSign='72',healthNumber='7.2K',
    healthPctNum='72% | 7.2K',healthNumPct='7.2K | 72%',healthPctNumDash='72% - 7.2K',healthNumPctDash='7.2K - 72%'}
for _,element in ipairs(NP.TEXT_ORDER) do
    if element~='none' and element~='---' then
        assert(samples[element],'no preview sample for '..element)
        p.textSlotTop,p.textSlotLeft,p.textSlotRight,p.textSlotCenter='none','none',element,'none'; NP.PaintPreview()
        local fs=NP.TextString(s,element)
        assert(fs.slot=='right' and fs:GetText()==samples[element],element..': '..tostring(fs:GetText()))
    end
end
assert(NP.TextString(s,'targetOfTarget').textColor[1]==RAID_CLASS_COLORS.WARRIOR.r)
p.textSlotTop,p.textSlotLeft,p.textSlotRight,p.textSlotCenter='enemyName','level','healthPercent','none'; NP.PaintPreview()
assert(s.name:GetText()=='Enemy Name Text' and s.healthText:GetText()=='72%' and not NP.TextString(s,'healthNumber').slot)
''')
print('PASS: real Core Lua 5.1 lifecycle; native plate detection/clicks/alpha, Retail look (size, text slots, palette, glow, arrows, hash line, execute glow, target texture, combo points), casts (smooth per-frame fill/drain only while casting, tint, shield, spark, kick tick, interrupted flash), unique mappings, top/left aura slots and recycling, threat roles and channels, friendly class colors, profile migration, combat deferral and real module/shared options (live header preview surviving the header cache, click-to-navigate preview elements, inline swatches/cogs, one-per-slot core and text positions, preview eyes, every Retail text element: name/level combos, Target of Target, health %/#/combos with K/M abbreviation, live and preview). Rendering and taint require in-game confirmation.')
