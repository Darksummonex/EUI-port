"""Native Wrath Resource Bars: Retail schema, bars, cast/GCD, swing, totems, unlock elements and option pages; in-game QA still required."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime

FOLDER='EllesmereUIResourceBars'
FILES=['EUI_ResourceBars_335.lua','EUI_ResourceBars_335_Bars.lua','EUI_ResourceBars_335_Cast.lua','EUI_ResourceBars_335_Swing.lua','EUI_ResourceBars_335_Totems.lua']

retail=Path('D:/World of Warcraft/_retail_/Interface/AddOns')/FOLDER
for original in retail.rglob('*'):
    if original.is_file() and original.suffix.lower()!='.toc':
        assert original.read_bytes()==(root/FOLDER/original.relative_to(retail)).read_bytes(),original
toc=(root/FOLDER/(FOLDER+'.toc')).read_text(encoding='utf-8-sig')
assert '## Interface: 30300' in toc and '## Version: 9.3.4-335-0.5' in toc
assert [l.strip() for l in toc.splitlines() if l.strip() and not l.startswith('#')]==FILES

import re
for name in FILES+['../EllesmereUIOptions/EUI_ResourceBars_335_Options.lua']:
    text=(root/FOLDER/name).read_text(encoding='utf-8-sig')
    assert not re.search(r'\bC_[A-Z]',text),name
    for bad in ['SetRotatesTexture','SetSize(','SetShown(','SetReverseFill','SetClipsChildren','SetAtlas','.png']:
        assert bad not in text,(name,bad)

def runtime(player_class):
    lua=LuaRuntime(unpack_returned_tuples=True)
    for path in ['backport-tools/wrath_mock.lua','backport-tools/inventory_resources_mock.lua','EllesmereUI/EllesmereUI_Lite.lua']:
        lua.execute((root/path).read_text(encoding='utf-8-sig'))
    lua.globals().playerClass=player_class
    lua.execute('''
function GetSpellInfo(id) return id==689 and "Drain Life" or id==78 and "Heroic Strike" or id==845 and "Cleave" or id==75 and "Auto Shot" or id==5019 and "Shoot" or tostring(id) end
local m=getmetatable(UIParent).__index
function m:SetVertexColor(...) self.vc={...} end
function m:SetGradientAlpha(...) self.grad={...} end
function m:SetTexCoord(...) self.texcoords={...} end
function m:GetFrameLevel() return self.level or 1 end
function m:SetFrameLevel(v) self.level=v end
formID=0; function GetShapeshiftFormID() return formID end
function GetNetStats() return 0,0,100 end
attackSpeed,offSpeed=2,nil
function UnitAttackSpeed() return attackSpeed,offSpeed end
function OffhandHasWeapon() return offSpeed~=nil end
function UnitRangedDamage() return 2.5 end
function UnitExists(u) return u=="player" or targetExists end
function MouseIsOver(f) return f.hover end
sections={}
function EllesmereUI.Widgets:SectionHeader(parent,label,y) sections[#sections+1]=label; return {},30 end
''')
    for helper in ['EUI_ChannelTicks_335.lua']:
        lua.execute((root/'EllesmereUI'/helper).read_text())
    core=(root/'EllesmereUI/EllesmereUI_Lite.lua').read_text(encoding='utf-8-sig')
    safe=lua.execute('local function errorhandler('+core.split('local function errorhandler(',1)[1].split('\n-------------------------------------------------------------------------------',1)[0]+'\nreturn safecall')
    return lua,safe

def load(lua,folder,file,namespace=None):
    ns=namespace or lua.table()
    lua.eval('function(s,n) return assert(loadstring(s,n)) end')((root/folder/file).read_text(encoding='utf-8-sig'),file)(folder,ns)
    return ns

def tile(lua,file,name,next_name):
    source=(root/'EllesmereUIOptions'/file).read_text(encoding='utf-8-sig')
    body='local function '+name+source.split('local function '+name,1)[1].split('local function '+next_name,1)[0]
    context='''
local NS=EllesmereUI.ModuleNS
local function ModuleOutlineCfg() return {type='label',text='Outline'} end
local function BLANK() return {type='label',text=''} end
local function LinkRow(parent,y,label,folder,page,section,highlight) links=links or {}; links[#links+1]={folder,page,section,highlight}; return y-40 end
local function CopyBarDD(names,order,lookup) return names,order end
'''
    return lua.execute(context+body+'\nreturn '+name)

COMMON='''
local p=RB.GetSettings(); local f=RB.frames
local function near(a,b) return math.abs(a-b)<1e-6 end
assert(_ERB_AceDB==RB.addon.db and type(_ERB_Apply)=='function' and p._wrathSchema==1)
assert(f.primary:IsShown() and not f.health:IsShown() and not f.castBar:IsShown() and not f.gcdBar:IsShown() and not f.swingTimer:IsShown())
-- Power: Retail default text "Power %", fill sized from the value.
assert(f.primary._value==50 and f.primary._max==100 and f.primary.text:GetText()=='50%',f.primary.text:GetText())
assert(near(f.primary.fill.width,f.primary:GetWidth()*.5) and f.primary.text.font[3]=='OUTLINE')
assert(CastingBarFrame:GetAlpha()==.7)
maxPower=0; RB.UpdateAll(); assert(not f.primary:IsShown())
maxPower=100; powerType=1; powerToken='RAGE'; RB.UpdateAll(); assert(f.primary:IsShown())
p.primary.textFormat='smart'; RB.Apply(); assert(f.primary.text:GetText()=='50')
p.primary.textFormat='both'; p.primary.showPercent=false; RB.Apply(); assert(f.primary.text:GetText()=='50 | 50')
p.primary.textFormat='perpp'; p.primary.showPercent=true; powerType=0; powerToken='MANA'
-- Thresholds: power uses the color above the percent unless "below only".
p.primary.thresholdEnabled=true; p.primary.thresholdPct=40; RB.Apply(); assert(f.primary.fill.vc[1]==1 and f.primary.fill.vc[2]==.2)
p.primary.thresholdPartialOnly=true; RB.Apply(); assert(f.primary.fill.vc[1]==0)
p.primary.thresholdEnabled=false; p.primary.thresholdPartialOnly=false
-- Health: off by default; text formats, class color, threshold, bands, hash lines, vertical orientation.
p.health.enabled=true; p.health.textFormat='both'; RB.Apply()
assert(f.health:IsShown() and f.health._value==25 and f.health.text:GetText()=='25 | 25%')
p.health.textFormat='perhpnum'; RB.Apply(); assert(f.health.text:GetText()=='25% | 25')
p.health.thresholdEnabled=true; RB.Apply(); assert(f.health.fill.vc[1]==1 and f.health.fill.vc[2]==.2)
p.health.thresholdEnabled=false; p.health.multiBandEnabled=true
p.health.bands={{to=20,r=1,g=0,b=0},{to=60,r=1,g=1,b=0},{to=100,r=0,g=1,b=0}}; RB.Apply()
assert(f.health.fill.vc[1]==1 and f.health.fill.vc[2]==1 and f.health.fill.vc[3]==0)
p.health.multiBandEnabled=false; p.health.hashEnabled=true; p.health.hashValues='25, 50, 75'; RB.Apply()
assert(#f.health._erbHash==3 and f.health._erbHash[3]:IsShown())
p.health.gradientEnabled=true; RB.Apply(); assert(f.health.fill.grad and f.health.fill.grad[1]=='HORIZONTAL')
p.health.orientation='VERTICAL_UP'; RB.Apply()
assert(f.health:GetWidth()==16 and f.health:GetHeight()==214 and near(f.health.fill.height,214*.25) and f.health.fill.texcoords[1]==.25)
p.health.orientation='HORIZONTAL'; p.health.fillOpacity=50; RB.Apply(); assert(f.health._bgEmpty and f.health._fillAlpha==.5)
p.health.fillOpacity=100
-- Visibility modes, out-of-combat fade, mouseover.
p.primary.visibility='in_combat'; RB.UpdateVisibility(); assert(not f.primary:IsShown())
RB.events:RunScript('OnEvent','PLAYER_REGEN_DISABLED'); assert(f.primary:IsShown())
RB.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); assert(not f.primary:IsShown())
p.primary.visibility='mouseover'; RB.UpdateVisibility(); assert(f.primary:IsShown() and f.primary:GetAlpha()==0)
f.primary.hover=true; RB.events:RunScript('OnUpdate',.1); assert(f.primary:GetAlpha()==1); f.primary.hover=nil
p.primary.visibility='always'; p.primary.oocFadeEnabled=true; p.primary.oocAlpha=.4; RB.UpdateVisibility(); assert(f.primary:GetAlpha()==.4)
p.primary.oocFadeEnabled=false; RB.UpdateVisibility()
-- Unlock elements: Retail keys, resize through setWidth/Height, positions, settings map.
local els=unlockByFolder.EllesmereUIResourceBars; local byKey={}
for _,e in ipairs(els) do byKey[e.key]=e end
for bar,key in pairs(RB.KEYS) do
    local e=byKey[key]; assert(e and e.getFrame()==f[bar] and e.label==RB.LABELS[bar],key)
    local m=EllesmereUI._ELEMENT_SETTINGS_MAP[key]; assert(m and m.module=='EllesmereUIResourceBars' and m.page and m.sectionName and m.highlightText,key)
end
assert(#els==8 and byKey.ERB_Health.order==500 and byKey.ERB_Power.order==501 and byKey.ERB_ClassResource.order==502)
assert(byKey.ERB_TotemBar.noResize and not byKey.ERB_Power.noResize)
byKey.ERB_Power.setWidth(nil,260); assert(p.primary.width==260 and f.primary:GetWidth()==260)
p.primary.orientation='VERTICAL_DOWN'; RB.Apply(); byKey.ERB_Power.setWidth(nil,18); assert(p.primary.height==18 and p.primary.width==260)
p.primary.orientation='HORIZONTAL'; RB.Apply()
local w,h=byKey.ERB_Power.getSize(); assert(w==260 and h==18)
byKey.ERB_Power.savePos(nil,'CENTER','CENTER',10,-40); assert(p.primary.unlockPos.x==10 and select(5,f.primary:GetPoint(1))==-40)
local pos=byKey.ERB_Power.loadPos(); assert(pos.point=='CENTER' and pos.y==-40)
byKey.ERB_Power.clearPos(); byKey.ERB_Power.applyPos(); assert(p.primary.unlockPos==nil and select(5,f.primary:GetPoint(1))==-157)
assert(byKey.ERB_TotemBar.isHidden()==(playerClass~='SHAMAN'))
-- Cast bar: native frame hidden, cast/channel/latency/failed, ticks.
p.castBar.enabled=true; p.gcdBar.enabled=true; RB.Apply(); assert(CastingBarFrame:GetAlpha()==0)
CastingBarFrame:SetAlpha(1); assert(CastingBarFrame:GetAlpha()==0)
local cb=f.castBar.bar; assert(cb:GetWidth()==200 and f.castBar.icon:IsShown())
now=10; nativeCast={'Fireball','Rank 1','Fireball','fire-icon',9000,12000,false,1}; RB.events:RunScript('OnEvent','UNIT_SPELLCAST_START','player')
assert(f.castBar:IsShown() and cb._value==1 and f.castBar.timer:GetText()=='2.0' and f.castBar.spell:GetText()=='Fireball')
nativeCast[6]=13000; RB.events:RunScript('OnEvent','UNIT_SPELLCAST_DELAYED','player'); assert(cb._max==4)
p.castBar.showTotalDuration=true; p.castBar.latencyEnabled=true; p.castBar.latencyShowText=true; RB.Apply()
nativeCast=nil; RB.events:RunScript('OnEvent','UNIT_SPELLCAST_STOP','player'); assert(not f.castBar:IsShown())
RB.events:RunScript('OnEvent','UNIT_SPELLCAST_SENT','player')
nativeCast={'Frostbolt','Rank 1','Frostbolt','frost-icon',10000,14000,false,2}; RB.events:RunScript('OnEvent','UNIT_SPELLCAST_START','player')
assert(f.castBar.timer:GetText()=='4.0 / 4.0 (100ms)',f.castBar.timer:GetText()); assert(f.castBar.latency:IsShown() and near(f.castBar.latency.width,200*.1/4))
-- Queue-proof: no SENT event; prefer world and fall back to Wrath/home.
function GetNetStats() return 0,0,100,250 end
nativeCast={'Queued Cast','Rank 1','Queued Cast','icon',10000,14000,false,3}
RB.events:RunScript('OnEvent','UNIT_SPELLCAST_START','player')
assert(near(f.castBar.latency.width,200*.25/4) and f.castBar.timer:GetText():find('250ms',1,true))
nativeCast=nil; nativeChannel={'Queued Channel','Rank 1','Queued Channel','icon',10000,14000}
RB.events:RunScript('OnEvent','UNIT_SPELLCAST_CHANNEL_START','player')
assert(f.castBar.latencyFront:IsShown() and not f.castBar.latency:IsShown() and near(f.castBar.latencyFront.width,200*.25/4))
function GetNetStats() return 0,0,100,0 end
nativeChannel=nil; nativeCast={'Fallback','Rank 1','Fallback','icon',10000,14000,false,4}
RB.events:RunScript('OnEvent','UNIT_SPELLCAST_START','player')
assert(f.castBar.latency:IsShown() and not f.castBar.latencyFront:IsShown() and near(f.castBar.latency.width,200*.1/4))
nativeCast=nil; RB.events:RunScript('OnEvent','UNIT_SPELLCAST_INTERRUPTED','player'); RB.events:RunScript('OnEvent','UNIT_SPELLCAST_STOP','player')
assert(f.castBar:IsShown() and f.castBar.spell:GetText()=='Interrupted')
now=11; RB.events:RunScript('OnUpdate',.016); assert(not f.castBar:IsShown())
p.castBar.showTotalDuration=false; p.castBar.latencyEnabled=false; now=10
nativeChannel={'Drain Life','Rank 1','Drain Life','drain-icon',9000,13000}
RB.events:RunScript('OnEvent','UNIT_SPELLCAST_CHANNEL_START','player'); assert(RB.CastPart.state.mode=='channel' and cb._value==3)
local tick=cb._euiChannelTicks[1]
assert(#cb._euiChannelTicks==4 and cb._euiChannelTicks[4]:IsShown() and near(select(4,tick:GetPoint(1)),cb:GetWidth()*.8))
p.castBar.showLastTick=true; RB.CastPart.UpdateCast(); assert(cb._euiChannelTicks[4].vc[3]==0 and cb._euiChannelTicks[1].vc[3]==1)
now=10.016; RB.events:RunScript('OnUpdate',.016); assert(near(cb._value,2.984),'Cast fill throttled')
nativeChannel[6]=12000; RB.events:RunScript('OnEvent','UNIT_SPELLCAST_CHANNEL_UPDATE','player')
assert(cb._euiChannelTicks[3]:IsShown() and not cb._euiChannelTicks[4]:IsShown())
p.castBar.showChannelTicks=false; RB.CastPart.ReadCast(); assert(not tick:IsShown())
p.castBar.showChannelTicks=true; now=10
nativeChannel=nil; RB.events:RunScript('OnEvent','UNIT_SPELLCAST_CHANNEL_STOP','player'); assert(not f.castBar:IsShown())
p.castBar.alwaysShow=true; RB.UpdateVisibility(); assert(f.castBar:IsShown()); p.castBar.alwaysShow=false; RB.UpdateVisibility()
-- GCD bar.
gcdStart=10; gcdDuration=1.5; RB.events:RunScript('OnEvent','SPELL_UPDATE_COOLDOWN'); assert(f.gcdBar:IsShown())
now=10.75; RB.events:RunScript('OnUpdate',.1); assert(near(f.gcdBar._value,.5))
now=12; RB.events:RunScript('OnUpdate',.1); assert(not f.gcdBar:IsShown())
gcdStart=12; gcdDuration=10; RB.CastPart.ReadGCD(); RB.UpdateVisibility(); assert(not f.gcdBar:IsShown())
-- Unlock Mode preview shows every enabled element, then restores.
EllesmereUI.listeners.EllesmereUIResourceBars(true); assert(f.castBar:IsShown() and f.gcdBar:IsShown() and f.castBar.spell:GetText()=='Cast Bar')
EllesmereUI.listeners.EllesmereUIResourceBars(false); assert(not f.castBar:IsShown() and not f.gcdBar:IsShown())
-- Fonts/textures follow the Retail keys used by the Global tiles.
p.primary.textSize=16; p.general.barTexture='plating'; _ERB_Apply(); assert(f.primary.text.font[2]==16 and f.primary._tex==_ERB_BarTextures.plating)
p.splitTex=true; p.health.barTexture='fade'; RB.Apply(); assert(f.health._tex==_ERB_BarTextures.fade and f.primary._tex==_ERB_BarTextures.plating)
p.splitTex=false; RB.Apply(); assert(f.health._tex==_ERB_BarTextures.plating)
p.castBar.texture='glass'; RB.Apply(); assert(cb._tex==_ERB_BarTextures.glass)
'''

CLASS_TESTS={
'ROGUE':'''
local s=f.secondary
assert(s:IsShown() and s.pips[3].fill:IsShown() and not s.pips[4].fill:IsShown() and not s.pips[6]:IsShown() and s.text:GetText()=='3')
p.secondary.thresholdEnabled=true; p.secondary.thresholdCount=3; RB.Apply(); assert(near(s.pips[1].fill.vc[1],0x0c/255))
p.secondary.classColored=false; p.secondary.thresholdEnabled=false; RB.Apply(); assert(s.pips[1].fill.vc[1]==.95)
p.secondary.pipOrientation='VERTICAL_UP'; RB.Apply(); assert(s:GetWidth()==20 and s:GetHeight()==214)
p.secondary.pipOrientation='HORIZONTAL'; comboPoints=0; RB.events:RunScript('OnEvent','UNIT_COMBO_POINTS','player'); assert(s.text:GetText()=='')
''',
'DRUID':'''
local s=f.secondary
assert(not s:IsShown()); formID=1; RB.events:RunScript('OnEvent','UPDATE_SHAPESHIFT_FORM'); assert(s:IsShown() and s.pips[3].fill:IsShown())
p.primary.foreverDruidMana.enabled=true; powerType=3; RB.Apply(); assert(f.druidMana:IsShown() and f.druidMana._value==50)
powerType=0; RB.UpdateAll(); assert(not f.druidMana:IsShown())
p.primary.barDisabledForms.energy=true; RB.Apply(); assert(not f.primary:IsShown())
formID=0; RB.events:RunScript('OnEvent','UPDATE_SHAPESHIFT_FORM'); assert(f.primary:IsShown() and not s:IsShown())
''',
'DEATHKNIGHT':'''
local s=f.secondary
assert(s:IsShown() and s.pips[6]:IsShown())
runes[1]={start=10,duration=10,ready=false,type=4}; now=15; RB.BarsPart.UpdateResource()
assert(near(s.pips[1].fill.width,s.pips[1]:GetWidth()*.5) and s.pips[1].timer:GetText()=='5')
p.secondary.runeSortReady=true; RB.Apply(); assert(s.pips[6].timer:GetText()=='5' and s.pips[1].timer:GetText()=='')
p.secondary.runesSimple=true; RB.Apply(); assert(s.text:GetText()=='5' and not s.pips[6].fill:IsShown())
p.secondary.runesSimple=false; p.secondary.runeSortReady=false
runes[1].ready=true; RB.events:RunScript('OnEvent','RUNE_POWER_UPDATE',1); assert(s.pips[1].timer:GetText()=='' and s.pips[1].fill:IsShown())
''',
'SHAMAN':'''
local t=f.totemBar
assert(not t:IsShown())
totems[1]={name='Searing Totem',start=10,duration=30}; now=15; RB.events:RunScript('OnEvent','PLAYER_TOTEM_UPDATE',1)
assert(t:IsShown() and t.icons[1]:IsShown() and not t.icons[2]:IsShown() and t.icons[1].timer:GetText()=='25' and t.icons[1].cd.duration==30)
assert(select(4,t.icons[1]:GetPoint(1))==0 and EllesmereUI.GetTotemGrowDir()=='RIGHT')
totems[2]={name='Stoneskin Totem',start=10,duration=120}; RB.events:RunScript('OnEvent','PLAYER_TOTEM_UPDATE',2)
assert(select(4,t.icons[2]:GetPoint(1))==0 and select(4,t.icons[1]:GetPoint(1))==32 and t.icons[2].timer:GetText()=='2m')
p.totemBar.growDirection='LEFT'; EllesmereUI.LayoutTotemBar(); assert(t.icons[2]:GetPoint(1)=='RIGHT')
assert(TotemFrame:GetParent()~=UIParent); p.totemBar.hideBlizzard=false; RB.Apply(); assert(TotemFrame:GetParent()==UIParent)
totems[2]=nil; now=41; RB.events:RunScript('OnUpdate',.1); assert(not t:IsShown())
local bar=MultiCastActionBarFrame
p.callTotemBar.enabled=true; RB.Apply(); assert(bar:GetParent()==f.callTotemBar and f.callTotemBar:IsShown())
bar:SetPoint('BOTTOMLEFT',UIParent,'BOTTOMLEFT',0,0); assert(bar:GetPoint(1)=='CENTER')
combat=true; p.callTotemBar.enabled=false; RB.Apply(); assert(bar:GetParent()==f.callTotemBar)
combat=false; RB.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); assert(bar:GetParent()==UIParent)
''',
'WARRIOR':'''
assert(not f.secondary:IsShown() and not f.totemBar:IsShown())
p.swingTimer.enabled=true; RB.Apply(); assert(not f.swingTimer:IsShown())
RB.events:RunScript('OnEvent','PLAYER_REGEN_DISABLED'); assert(f.swingTimer:IsShown() and #f.swingTimer._rows==1)
now=20; RB.events:RunScript('OnEvent','COMBAT_LOG_EVENT_UNFILTERED',0,'SWING_DAMAGE','player','Me',0,'boss','Boss',0)
local mh=f.swingTimer.bars.mh
now=21; RB.events:RunScript('OnUpdate',.1); assert(near(mh._value,.5) and mh.text:GetText()=='1.0')
RB.events:RunScript('OnEvent','COMBAT_LOG_EVENT_UNFILTERED',0,'SWING_MISSED','boss','Boss',0,'player','Me',0,'PARRY')
assert(near(RB.SwingPart.timers.mh.start,19.4))
RB.events:RunScript('OnEvent','COMBAT_LOG_EVENT_UNFILTERED',0,'SPELL_DAMAGE','player','Me',0,'boss','Boss',0,78,'Heroic Strike',1)
assert(RB.SwingPart.timers.mh.start==21)
offSpeed=1.5; RB.events:RunScript('OnEvent','PLAYER_EQUIPMENT_CHANGED'); assert(#f.swingTimer._rows==2 and f.swingTimer._rows[2]=='oh')
now=21.1; RB.events:RunScript('OnEvent','COMBAT_LOG_EVENT_UNFILTERED',0,'SWING_DAMAGE','player','Me',0,'boss','Boss',0)
assert(RB.SwingPart.timers.oh.start==21.1 and RB.SwingPart.timers.mh.start==21)
attackSpeed=1; RB.events:RunScript('OnEvent','UNIT_ATTACKSPEED','player'); assert(RB.SwingPart.timers.mh.duration==1)
p.swingTimer.combineHands=true; RB.Apply(); assert(#f.swingTimer._rows==1)
RB.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED')
''',
}

for player_class in ['WARRIOR','ROGUE','DRUID','DEATHKNIGHT','SHAMAN']:
    lua,safe=runtime(player_class)
    lua.execute('''
TotemFrame=CreateFrame("Frame","TotemFrame",UIParent); TotemFrame:SetParent(UIParent)
MultiCastActionBarFrame=CreateFrame("Frame","MultiCastActionBarFrame",UIParent); MultiCastActionBarFrame:SetParent(UIParent)
''')
    resource=load(lua,FOLDER,FILES[0]); lua.globals().RB=resource
    for extra in FILES[1:]: load(lua,FOLDER,extra,resource)
    safe(resource.addon.OnInitialize,resource.addon); safe(resource.addon.OnEnable,resource.addon)
    lua.execute(COMMON+CLASS_TESTS[player_class]+'''
p.enabled=false; RB.Apply(); for k,frame in pairs(f) do assert(not frame:IsShown() or k=='druidMana' and not frame:IsVisible(),k) end
assert(CastingBarFrame:GetAlpha()==.7)
p.enabled=true; p.castBar.enabled=false; RB.Apply(); assert(f.primary:IsShown() and CastingBarFrame:GetAlpha()==.7)
''')
    load(lua,'EllesmereUIOptions','EUI_ResourceBars_335_Options.lua')
    lua.execute('''
allFrames[#allFrames]:RunScript('OnEvent','PLAYER_LOGIN')
local cfg=modules.EllesmereUIResourceBars; local p=RB.GetSettings()
assert(cfg and #cfg.pages==5 and cfg.pages[1]=='Class, Power and Health Bars' and cfg.pages[5]=='Totem Bar')
local built={}
for _,page in ipairs(cfg.pages) do
    rows={}; sections={}; local h=cfg.buildPage(page,UIParent,0); assert(h>0)
    local labels,secs={}, {}
    for _,r in ipairs(rows) do if r.text then labels[r.text]=r end end
    for _,s in ipairs(sections) do secs[s]=true end
    built[page]={labels=labels,sections=secs}
end
-- Every unlock element's Element Options target resolves to a real section and row.
for key,m in pairs(EllesmereUI._ELEMENT_SETTINGS_MAP) do
    if m.module=='EllesmereUIResourceBars' then
        local b=built[m.page]
        local reachable=b and b.sections[m.sectionName] and b.labels[m.highlightText]
        assert(reachable or (key=='ERB_CallTotemBar' and playerClass~='SHAMAN'),key)
    end
end
rows={}; cfg.buildPage('Class, Power and Health Bars',UIParent,0)
FindRow('Show Health Bar').setValue(false); assert(p.health.enabled==false and not RB.frames.health:IsShown())
FindRow('Power Text').setValue('curpp'); assert(RB.frames.primary.text:GetText()=='50')
FindRow('Opacity').setValue(60); assert(p.health.barAlpha==.6)
FindRow('Bar Texture').setValue('glass'); assert(p.general.barTexture=='glass')
rows={}; cfg.buildPage('Cast Bar',UIParent,0)
FindRow('Enable Player Cast Bar').setValue(true); assert(p.castBar.enabled and CastingBarFrame:GetAlpha()==0)
FindRow('Tick Color').setValue(1,0,0,1); assert(p.castBar.tickMarksR==1 and p.castBar.tickMarksG==0)
FindRow('Enable Player Cast Bar').setValue(false); assert(CastingBarFrame:GetAlpha()==.7)
rows={}; cfg.buildPage('Swing Timer',UIParent,0); FindRow('Combine Hands').setValue(true); assert(p.swingTimer.combineHands)
rows={}; cfg.buildPage('Totem Bar',UIParent,0); FindRow('Grow Direction').setValue('DOWN'); assert(p.totemBar.growDirection=='DOWN')
cfg.onReset(); assert(RB.GetSettings().totemBar.growDirection=='RIGHT' and invalidated)
''')
    if player_class=='SHAMAN':
        rb_font=tile(lua,'EUI_Fonts_Options.lua','TileResourceBars','TileAuraBuffReminders')
        lua.execute('rows={}')
        rb_font(lua.globals().UIParent,0,lua.globals().EllesmereUI.Widgets,lua.table_from({'folder':FOLDER,'display':'Resource Bars'}))
        lua.execute('''
FindRow('Totem Timer Size').setValue(14); assert(RB.frames.totemBar.icons[1].timer.font[2]==14)
''')
        rb_texture=tile(lua,'EUI_Textures_Options.lua','TileResourceBars','TileChat')
        lua.execute('rows={}; links={}; RB.GetSettings().splitTex=true')
        rb_texture(lua.globals().UIParent,0,lua.globals().EllesmereUI.Widgets,lua.table_from({'folder':FOLDER,'display':'Resource Bars'}))
        lua.execute('''
FindRow('Power Bar Texture').setValue('fade'); assert(RB.frames.primary._tex==_ERB_BarTextures.fade)
FindRow('Cast Bar Texture').setValue('glass'); assert(RB.frames.castBar.bar._tex==_ERB_BarTextures.glass)
assert(links[#links][2]=='Class, Power and Health Bars' and links[#links][3]=='GENERAL' and links[#links][4]=='Bar Texture')
''')
        print('PASS: Global Fonts/Textures Resource Bars tiles write live timer/fonts/textures and link to the Wrath page')
    print(f'PASS: {player_class} health/power/class bars, thresholds, visibility, cast/channel/latency, GCD, swing, totems, unlock elements and option pages')
