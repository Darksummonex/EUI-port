"""Run real Wrath collector/UI with Details absent, through the Core lifecycle."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
lua=LuaRuntime()
for file in ['backport-tools/wrath_mock.lua','backport-tools/inventory_resources_mock.lua','EllesmereUI/EllesmereUI_Lite.lua']:
    lua.execute((root/file).read_text(encoding='utf-8-sig'),'EllesmereUI',lua.table())
lua.execute('''
lifecycleErrors={}; function geterrorhandler() return function(e) lifecycleErrors[#lifecycleErrors+1]=e end end
for _,f in ipairs(allFrames) do if f.events.ADDON_LOADED and f.events.PLAYER_LOGIN then lifecycle=f end end
assert(lifecycle); lifecycle:RunScript('OnEvent','ADDON_LOADED','EllesmereUI')
local m=getmetatable(UIParent).__index
function m:EnableMouseWheel(v) self.wheel=v end
function m:GetStringWidth() return #(self.text or '')*6 end
function m:SetMultiLine(v) self.multiLine=v end
function m:SetShadowColor(...) self.shadowColor={...} end
function m:SetShadowOffset(...) self.shadowOffset={...} end
function m:SetNumeric(v) self.numeric=v end
function m:SetMaxLetters(v) self.maxLetters=v end
function m:SetTextInsets() end
function m:SetVertexColor(...) self.vertex={...} end
-- Geometry: a TOPLEFT/BOTTOMLEFT anchor on UIParent sets the edges; anything
-- else sits at a fixed spot well inside the 1920x1080 screen.
local setPoint,clearPoints=m.SetPoint,m.ClearAllPoints
function m:SetPoint(p,rel,rp,x,y,...)
    setPoint(self,p,rel,rp,x,y,...)
    if p=='TOPLEFT' and rel==UIParent and rp=='BOTTOMLEFT' then self.left,self.top=x,y end
end
function m:ClearAllPoints() clearPoints(self); self.left,self.top=nil,nil end
function m:GetLeft() return self.left or 100 end
function m:GetTop() return self.top or 700 end
function m:GetRight() return (self.left or 100)+self.width end
function m:GetBottom() return (self.top or 700)-self.height end
function m:GetStringHeight() return 14 end
mouseOver=nil; function m:IsMouseOver() return mouseOver==self end
UIParent.width,UIParent.height=1920,1080
shift,alt,ctrl=false,false,false
function IsShiftKeyDown() return shift end; function IsAltKeyDown() return alt end; function IsControlKeyDown() return ctrl end
overrides={}
function ClearOverrideBindings(owner) overrides[owner]=nil end
function SetOverrideBindingClick(owner,_,key,button) overrides[owner]={key=key,button=button} end
instanceInside,instanceKind=nil,'none'
function IsInInstance() return instanceInside,instanceKind end
function time() return 1790840000 end
bit={band=function(a,b) local v,p=0,1; while a>0 and b>0 do if a%2==1 and b%2==1 then v=v+p end; a=math.floor(a/2); b=math.floor(b/2); p=p*2 end; return v end}
units={player={guid='P',name='Player',class='WARRIOR'},party1={guid='H',name='Healer',class='PRIEST'},pet={guid='PET',name='Pet',class='WARRIOR'},target={guid='BOSS',name='Boss'}}
function UnitGUID(u) return units[u] and units[u].guid end
function UnitName(u) return units[u] and units[u].name end
function UnitClass(u) local c=units[u] and units[u].class; return c,c end
function UnitExists(u) return units[u]~=nil end
function UnitAura() end
function UnitAffectingCombat(u) return fighting or false end
function UnitCanAttack(_,u) return u=='target' end
function GetNumPartyMembers() return 1 end
function GetNumRaidMembers() return 0 end
function UnitDetailedThreatSituation(u) return u=='player',1,u=='player' and 100 or 30,40,u=='player' and 1000 or 300 end
function IsInGuild() return true end
function GetSpellInfo(id) return 'Spell '..id,nil,'spell-icon' end
RAID_CLASS_COLORS.PRIEST={r=1,g=1,b=1}
function EllesmereUI.GetFontOutlineFlag() return '' end -- global None must not remove the meter's default outline
specHooks={}; inspected=nil; inspectCalls={}; inspectRange=true
function hooksecurefunc(name,fn) specHooks[name]=fn end
function NotifyInspect(unit)
 inspected=unit; inspectCalls[#inspectCalls+1]=unit
 if specHooks.NotifyInspect then specHooks.NotifyInspect(unit) end
end
function ClearInspectPlayer() if specHooks.ClearInspectPlayer then specHooks.ClearInspectPlayer() end end
function CanInspect(unit) return inspectRange and units[unit]~=nil end
function UnitIsVisible(unit) return units[unit]~=nil end
playerTalentGroup=1
function GetActiveTalentGroup(inspect) return inspect and 2 or playerTalentGroup end
function GetTalentTabInfo(tab,inspect,pet,group)
 assert(pet==false and group==(inspect and 2 or playerTalentGroup))
 local best=inspect and 1 or playerTalentGroup==1 and 2 or 3
 local name=(inspect and 'Discipline' or best==2 and 'Fury' or 'Protection')
 return name,inspect and 'priest-spec-icon' or 'warrior-spec-'..best,tab==best and 51 or 10
end
function GameTooltip:AddLine(text) self.tooltipText=text end
function GameTooltip:SetHyperlink(link) self.link=link end
sent={}; function SendChatMessage(text,channel) sent[#sent+1]={text,channel} end
modules={}; function EllesmereUI:RegisterModule(name,cfg) modules[name]=cfg end
unlock={}; function EllesmereUI:RegisterUnlockElements(elements) for _,e in ipairs(elements) do unlock[e.key]=e end end
function EllesmereUI.GetAccentColor() return .1,.8,.7 end
function EllesmereUI:InvalidatePageCache() end
function EllesmereUI:RefreshPage() end
function EllesmereUI:ShowModule(folder) shownModule=folder end
function EllesmereUI.EnsureOptionsLoaded() end
-- Reading a Details runtime/library would fail immediately.
_detalhes=setmetatable({},{__index=function() error('Details dependency') end})
DetailsFramework=nil; LibStub=function() error('External library dependency') end
''')
ns=lua.table()
for file in ['EUI_DamageMeters_335.lua','EUI_DamageMeters_335_Absorbs.lua','EUI_DamageMeters_335_Parser.lua','EUI_DamageMeters_335_Specs.lua','EUI_DamageMeters_335_Display.lua','EUI_DamageMeters_335_Breakdown.lua','EUI_DamageMeters_335_Home.lua','EUI_DamageMeters_335_Extras.lua','EUI_DamageMeters_335_SpellHistory.lua']:
    lua.execute((root/'EllesmereUIDamageMeters'/file).read_text(encoding='utf-8-sig'),'EllesmereUIDamageMeters',ns)
lua.globals().D=ns
lua.execute('''
lifecycle:RunScript('OnEvent','ADDON_LOADED','EllesmereUIDamageMeters')
assert(#lifecycleErrors==0,lifecycleErrors[1]); assert(D.addon.db and D.history)
function IsLoggedIn() return true end
lifecycle:RunScript('OnEvent','PLAYER_LOGIN')
assert(#lifecycleErrors==0,lifecycleErrors[1]); assert(D.events.events.COMBAT_LOG_EVENT_UNFILTERED)
assert(#D.Profile().windows==2 and #D.windows[1].rows==40 and unlock.EDM_1)
-- Retail look: flat black window, dark header, accent title, Atrocity bars.
local w1cfg=D.Profile().windows[1]
assert(D.Profile().styleVersion==2 and D.Profile().windowCount==2 and w1cfg.alpha==.75 and w1cfg.rowHeight==18)
assert(w1cfg.borderSize==0 and w1cfg.barTexture=='atrocity' and w1cfg.barSpacing==2 and w1cfg.titleUseAccent and w1cfg.chromeAlpha==1)
assert(D.windows[1].header.bg.vertex[1]==.106 and D.windows[1].title.text.textColor[1]==.1)
local legacy=D.Copy(D.Profile()); legacy.styleVersion=nil
local lw,cw=legacy.windows[1],legacy.windows[2]
lw.alpha,lw.borderSize,lw.barTexture,lw.rowHeight,lw.titleUseAccent,lw.titleColor=.92,1,'none',20,nil,{r=1,g=1,b=1}
cw.alpha,cw.barTexture,cw.titleUseAccent,cw.titleColor=.5,'glass',nil,{r=1,g=0,b=0}
D.MigrateStyle(legacy)
assert(lw.alpha==.75 and lw.borderSize==0 and lw.barTexture=='atrocity' and lw.rowHeight==18 and lw.titleUseAccent==true)
assert(cw.alpha==.5 and cw.barTexture=='glass' and cw.titleUseAccent==false and legacy.styleVersion==2)
assert(D.specs.P.icon=='warrior-spec-2' and D.specs.P.name=='Fury')
assert(D.Profile().windows[1].fontOutline=='OUTLINE' and D.Profile().windows[1].showSpecIcons)
D.UpdateSpecs(); assert(inspectCalls[1]=='party1' and D.pendingSpec.guid=='H')
D.events:RunScript('OnEvent','INSPECT_TALENT_READY','UNRELATED'); assert(not D.specs.H and D.pendingSpec)
D.events:RunScript('OnEvent','INSPECT_TALENT_READY'); assert(D.specs.H.icon=='priest-spec-icon' and not D.pendingSpec)
local nativeFactory=CreateFrame
local frameCount=#allFrames
function Event(kind,sg,sn,sf,dg,dn,df,...)
    D.events:RunScript('OnEvent','COMBAT_LOG_EVENT_UNFILTERED',1000,kind,sg,sn,sf,dg,dn,df,...)
end
-- Eight legacy common fields, including spell school vs damage school.
Event('SPELL_DAMAGE','P','Player',1,'BOSS','Boss',0,133,'Fireball',4,100,0,4,0,0,0,true)
assert(D.current and D.current.label=='Boss' and D.current.actors.P.values.damage==100)
Event('SWING_DAMAGE','P','Player',1,'BOSS','Boss',0,50,0,1,0,0,0,false)
Event('SPELL_PERIODIC_DAMAGE','P','Player',1,'BOSS','Boss',0,172,'Corruption',32,25,0,32,0,0,0,false)
Event('SPELL_DAMAGE','PET','Pet',1,'BOSS','Boss',0,400,'Bite',1,25,0,1,0,0,0,false)
Event('SPELL_SUMMON','P','Player',1,'GUARD','Guardian',1,123,'Guardian',1)
Event('SPELL_DAMAGE','GUARD','Guardian',1,'BOSS','Boss',0,401,'Strike',1,30,0,1,0,0,0,false)
assert(D.current.actors.P.values.damage==230 and not D.current.actors.PET and not D.current.actors.GUARD)
Event('SPELL_HEAL','H','Healer',2,'P','Player',1,2061,'Flash Heal',2,150,50,0,true)
Event('SPELL_PERIODIC_HEAL','H','Healer',2,'P','Player',1,139,'Renew',2,30,0,0,false)
assert(D.current.actors.H.values.healing==130 and D.current.actors.H.values.overheal==50)
assert(D.current.actors.P.values.healingReceived==130)
Event('SPELL_DAMAGE','BOSS','Boss',0,'P','Player',1,500,'Boss Spell',4,70,0,4,0,0,20,false)
Event('SWING_MISSED','BOSS','Boss',0,'P','Player',1,'ABSORB',30)
Event('ENVIRONMENTAL_DAMAGE',nil,nil,0,'P','Player',1,'FALLING',10,0,1,0,0,0,false)
assert(D.current.actors.P.values.taken==80 and D.current.actors.P.values.absorbed==50)
assert(D.current.actors.P.values.avoided==1)
assert(not D.current.actors.H.values.absorbed) -- no invented shield caster
Event('SPELL_INTERRUPT','P','Player',1,'BOSS','Boss',0,6552,'Pummel',1,600,'Enemy cast',4)
Event('SPELL_DISPEL','H','Healer',2,'P','Player',1,527,'Dispel',2,601,'Curse',32,'DEBUFF')
Event('SPELL_STOLEN','P','Player',1,'BOSS','Boss',0,30449,'Spellsteal',64,602,'Buff',64,'BUFF')
Event('SPELL_CAST_SUCCESS','P','Player',1,'BOSS','Boss',0,133,'Fireball',4)
Event('SPELL_RESURRECT','H','Healer',2,'P','Player',1,2006,'Resurrection',2)
Event('SPELL_AURA_BROKEN_SPELL','P','Player',1,'BOSS','Boss',0,118,'Polymorph',64,133,'Fireball',4,'DEBUFF')
Event('SPELL_ENERGIZE','H','Healer',2,'P','Player',1,29166,'Innervate',8,1000,0)
Event('SPELL_PERIODIC_ENERGIZE','P','Player',1,'P','Player',1,1,'Energy',1,20,3)
assert(D.current.actors.P.values.mana==1000 and D.current.actors.P.values.energy==20 and D.current.actors.P.values.resources==2)
assert(D.current.actors.P.values.interrupts==1 and D.current.actors.H.values.dispels==1 and D.current.actors.P.values.dispels==1)
assert(D.current.actors.P.values.casts==1 and D.current.actors.H.values.resurrections==1 and D.current.actors.P.values.ccbreaks==1)
-- Refresh does not reset uptime; concurrent targets count separately.
Event('SPELL_AURA_APPLIED','H','Healer',2,'P','Player',1,139,'Renew',2,'BUFF')
Event('SPELL_AURA_APPLIED','P','Player',1,'BOSS','Boss',0,172,'Corruption',32,'DEBUFF')
now=now+2; Event('SPELL_AURA_REFRESH','H','Healer',2,'P','Player',1,139,'Renew',2,'BUFF')
now=now+2; Event('SPELL_AURA_REMOVED','H','Healer',2,'P','Player',1,139,'Renew',2,'BUFF')
assert(D.current.actors.P.values.buffUptime==4)
D.FlushAuras(now); assert(D.current.actors.P.values.debuffUptime==4)
Event('UNIT_DIED',nil,nil,0,'P','Player',1)
Event('UNIT_DIED',nil,nil,0,'PET','Pet',1)
assert(D.current.actors.P.values.deaths==1 and #D.current.deaths==1 and #D.current.deaths[1].logs==4)
local rows,s=D.Rows('current','damage'); assert(#rows==1 and rows[1].value==230 and rows[1].percent==100)
local rates=D.Rows('current','dps'); assert(rates[1].value==57.5)
local initialOverallRates=D.Rows('overall','dps'); assert(initialOverallRates[1].value==rates[1].value)
local spells=D.Breakdown(rows[1],'damage','spells'); assert(spells[1].id==133 and spells[1].crit==1)
local targets=D.Breakdown(rows[1],'damage','targets'); assert(targets[1].name=='Boss' and targets[1].total==230)
local enemies=D.Rows('current','enemyTaken'); assert(#enemies==1 and enemies[1].name=='Boss' and enemies[1].value==230)
local threat=D.Rows('current','threat'); assert(#threat==2 and threat[1].name=='Player' and threat[1].value==1000)
D.Refresh(); assert(D.windows[1].rows[1].label:GetText()=='1. Player')
assert(D.windows[1].rows[1].icon:IsShown() and D.windows[1].rows[1].icon.texture=='warrior-spec-2')
local healerRow=D.windows[2].rows[1]
assert(healerRow.icon.texture=='priest-spec-icon' and healerRow.specName=='Discipline')
assert(healerRow.label.font[3]=='OUTLINE' and healerRow.value.font[3]=='OUTLINE')
assert(healerRow.label.shadowColor[4]==1 and healerRow.label.shadowOffset[2]==-1)
-- Actual row mouseover and left click: no popup allocation, accurate actor
-- percentages and native spell icons, same meter changes to player detail.
local hover=D.breakdownTooltip; local row=D.windows[1].rows[1]
local beforeHover=#allFrames
row:RunScript('OnEnter'); assert(hover:IsShown() and hover.title:GetText()=="Player's Damage Done Breakdown")
assert(hover.lines[1].kind=='spell' and hover.lines[1].name=='Fireball' and hover.lines[1].value=='100' and hover.lines[1].fill==1)
assert(math.abs(hover.lines[1].percent-100/230*100)<.0001 and hover.rows[1].icon.texture=='spell-icon')
local targetLine=hover.lines[#hover.lines-1]; assert(targetLine.kind=='label' and targetLine.name=='Targets' and hover.rows[#hover.lines-1].line:IsShown())
assert(hover.lines[#hover.lines].kind=='target' and hover.lines[#hover.lines].name=='Boss' and hover.lines[#hover.lines].percent==100)
assert(hover:GetPoint()=='BOTTOMRIGHT' and select(2,hover:GetPoint())==row and hover.scale==1 and hover.width==275)
assert(hover.header.bg.vertex[1]==.106 and hover.title.textColor[1]==.1 and row.hl:IsShown())
row:RunScript('OnLeave'); assert(not hover:IsShown() and not row.hl:IsShown())
row:RunScript('OnClick','LeftButton')
assert(D.windows[1].focusGUID=='P' and D.windows[1].back:IsShown())
assert(D.windows[1].rows[1].data.breakdown and D.windows[1].rows[1].label:GetText()=='Fireball')
assert(D.windows[1].rows[1].icon.texture=='spell-icon' and D.windows[1].title.text:GetText():find('Player'))
local focusReport=D.ReportLines(1); assert(focusReport[1]:find('Player') and focusReport[2]:find('Fireball'))
assert(not hover:IsShown() and #allFrames==beforeHover)
D.windows[1].rows[1]:RunScript('OnEnter'); assert(hover.lines[2].name=='1 hits / 1 critical')
local fireballID=D.windows[1].rows[1].data.entry.id
assert(fireballID and fireballID>0 and hover.lines[#hover.lines].name=='Spell ID: '..fireballID,'spell ID missing from the spell breakdown')
D.windows[1].title:RunScript('OnClick','LeftButton'); assert(D.menu.items[2].text=='Targets')
D.menu.items[2].fn(); D.CloseMenu()
assert(D.windows[1].rows[1].label:GetText()=='Boss' and not D.windows[1].rows[1].icon:IsShown())
D.windows[1].back:RunScript('OnClick'); assert(not D.windows[1].focusGUID and not D.windows[1].back:IsShown())
assert(D.windows[1].rows[1].label:GetText()=='1. Player')
-- Right click: bookmark home from group view, back from focus.
local w1,wc=D.windows[1],D.Profile().windows[1]; local origSegment=wc.segment
w1.rows[1]:RunScript('OnClick','RightButton'); assert(w1.home and w1.home:IsShown() and w1.home.tiles[1].metric=='damage')
assert(w1.home.tiles[6].addNew and not w1.home.segments)
w1.home.tiles[2]:RunScript('OnClick','LeftButton'); assert(wc.metric=='healing' and not w1.home:IsShown())
w1.title:RunScript('OnClick','RightButton'); assert(w1.home:IsShown() and not D.menu:IsShown())
w1.home.tiles[5]:RunScript('OnClick','MiddleButton'); assert(#wc.bookmarks==4 and w1.home.tiles[5].addNew)
w1.home.tiles[5]:RunScript('OnClick','LeftButton'); assert(D.menu:IsShown())
for _,item in ipairs(D.menu.items) do if item.text=='Damage Taken' then item.fn() end end
D.CloseMenu(); assert(#wc.bookmarks==5 and wc.bookmarks[5]=='taken' and w1.home:IsShown())
w1.frame:RunScript('OnMouseUp','RightButton'); assert(not w1.home:IsShown())
w1.frame:RunScript('OnMouseUp','RightButton'); assert(w1.home:IsShown())
w1.home:RunScript('OnMouseUp','RightButton'); assert(not w1.home:IsShown())
wc.metric='damage'; wc.segment=origSegment; D.RefreshWindow(1)
w1.rows[1]:RunScript('OnClick','LeftButton'); assert(w1.focusGUID=='P')
w1.rows[1]:RunScript('OnClick','RightButton'); assert(not w1.focusGUID and not w1.home:IsShown())
assert(w1.rows[1].label:GetText()=='1. Player')
-- Header, right to left: Settings, Segment, Meter Type, Reset, then + on window 1 / x elsewhere.
local hh=wc.headerHeight
assert(w1.settings:GetPoint()=='RIGHT' and select(4,w1.settings:GetPoint())==0 and select(4,w1.segment:GetPoint())==-(hh-2))
assert(select(4,w1.mode:GetPoint())==-(2*hh-4) and select(4,w1.reset:GetPoint())==-(3*hh-6) and select(4,w1.action:GetPoint())==-(4*hh-8))
assert(w1.action.icon.texture:find('dm_open') and D.windows[2].action.icon.texture:find('dm_close') and w1.mode.icon.texture:find('dm_home_damage'))
assert(w1.settings.icon.desaturated and w1.settings.icon.alpha==.4 and w1.settings.width==hh and math.abs(w1.frame:GetHeight()-D.WindowHeight(wc))<.01)
w1.settings:RunScript('OnEnter'); assert(w1.settings.icon.alpha==.9 and GameTooltip.tooltipText=='Settings'); w1.settings:RunScript('OnLeave')
assert(w1.title.text:GetText()=='Damage Done - Current' and w1.timer:IsShown() and w1.timer:GetText():find('^%(%d:%d%d%)$'),w1.title.text:GetText())
assert(w1.rows[1]:GetPoint()=='TOPLEFT' and select(5,w1.rows[1]:GetPoint())==-hh and w1.rows[1].width==wc.width)
assert(w1.rows[1].icon.width==wc.rowHeight and select(4,w1.rows[1].bar:GetPoint())==wc.rowHeight)
local w2seg=D.Profile().windows[2].segment
w1.segment:RunScript('OnClick','LeftButton'); assert(D.menu:IsShown() and D.menu.items[1].isActive and D.menu.items[2].text=='Overall')
wc.syncSegments=true; D.Profile().windows[2].syncSegments=true
D.menu.buttons[2]:RunScript('OnClick','LeftButton'); assert(not D.menu:IsShown())
assert(wc.segment=='overall' and D.Profile().windows[2].segment=='overall' and w1.title.text:GetText():find('Overall'))
wc.syncSegments=false; D.Profile().windows[2].syncSegments=false
D.SelectSegment(1,'current'); assert(wc.segment=='current' and D.Profile().windows[2].segment=='overall')
D.Profile().windows[2].segment=w2seg
D.SelectSegment(1,'overall'); assert(wc.segment=='overall')
-- Settings menu: Retail-style toggles, inputs and Settings entry.
w1.settings:RunScript('OnClick','LeftButton'); local menu=D.menu
assert(menu:IsShown() and menu.items[1].text=='Hide in Dungeons' and menu.items[5]=='---' and menu.items[#menu.items].text=='Settings')
assert(menu.buttons[5].input:IsShown() and menu.buttons[5].input:GetText()==tostring(wc.width) and not menu.buttons[5].input.autoFocus)
menu.buttons[4]:RunScript('OnClick','LeftButton'); assert(wc.hideOutOfInstance and menu:IsShown() and not w1.frame:IsShown())
instanceInside,instanceKind=1,'party'; D.Refresh(); assert(w1.frame:IsShown())
menu.buttons[1]:RunScript('OnClick','LeftButton'); assert(wc.hideInDungeon and not w1.frame:IsShown())
menu.buttons[1]:RunScript('OnClick','LeftButton'); menu.buttons[4]:RunScript('OnClick','LeftButton')
instanceInside,instanceKind=nil,'none'; D.Refresh(); assert(w1.frame:IsShown() and not wc.hideInDungeon and not wc.hideOutOfInstance)
menu.buttons[5].input:SetText('300'); menu.buttons[5].input:RunScript('OnEnterPressed'); assert(wc.width==300 and w1.frame:GetWidth()==300)
local oldRows=wc.rows; menu.buttons[6].input:SetText(tostring(2*wc.borderSize+hh+4*(wc.rowHeight+wc.barSpacing))); menu.buttons[6].input:RunScript('OnEnterPressed')
assert(wc.rows==4 and menu.buttons[6].input:GetText()==tostring(D.WindowHeight(wc)))
wc.rows=oldRows; wc.width=310
menu.buttons[8]:RunScript('OnClick','LeftButton'); assert(wc.hideTimer and not w1.timer:IsShown())
menu.buttons[8]:RunScript('OnClick','LeftButton')
menu.buttons[9]:RunScript('OnClick','LeftButton'); assert(wc.autoSwapInstance)
D.InstanceChanged(); instanceInside,instanceKind=1,'raid'; D.InstanceChanged(); assert(wc.segment=='current')
instanceInside,instanceKind=nil,'none'; D.InstanceChanged(); assert(wc.segment=='overall')
menu.buttons[9]:RunScript('OnClick','LeftButton')
assert(menu.buttons[10].text:GetText()=='Auto Current on Combat'); menu.buttons[10]:RunScript('OnClick','LeftButton'); assert(wc.autoCurrentOnCombat==false)
menu.buttons[10]:RunScript('OnClick','LeftButton'); assert(wc.autoCurrentOnCombat==true)
assert(menu.buttons[12].text:GetText()=='Report' and menu.buttons[13].text:GetText()=='Settings')
menu.buttons[13]:RunScript('OnClick','LeftButton'); assert(shownModule=='EllesmereUIDamageMeters' and not menu:IsShown())
w1.settings:RunScript('OnClick','LeftButton'); assert(D.menu.buttons[7].text:GetText()=='Disable Snapping')
D.menu.buttons[7]:RunScript('OnClick','LeftButton'); assert(wc.snapDisabled and not D.menu:IsShown())
w1.settings:RunScript('OnClick','LeftButton'); assert(D.menu.buttons[7].text:GetText()=='Enable Snapping')
D.menu.buttons[7]:RunScript('OnClick','LeftButton'); assert(not wc.snapDisabled)
shownModule=nil; wc.segment=origSegment; D.Apply()
-- Death view drills into the latest native recap rather than spell counts.
D.Profile().windows[1].metric='deaths'; D.RefreshWindow(1)
D.windows[1].rows[1]:RunScript('OnEnter')
assert(hover.title:GetText()=="Player's Death Recap" and hover.lines[1].kind=='recap' and hover.lines[1].fill==.25)
assert(hover.lines[#hover.lines].name:find('^%-%d+%.%ds ') and hover.lines[1].value:find('%(25%%%)'))
D.windows[1].rows[1]:RunScript('OnLeave')
D.windows[1].rows[1]:RunScript('OnClick','LeftButton')
assert(D.windows[1].focusGUID=='P' and D.windows[1].rows[1].data.recap)
assert(D.windows[1].rows[1].label:GetText():find('Flash Heal'))
-- Recap rows draw the victim's health at each hit, green for heals, red for damage.
local recapRow=D.windows[1].rows[1]
assert(recapRow.bar.maximum==1 and recapRow.bar.value==.25 and recapRow.bar.color[2]==.5 and recapRow.value:GetText()=='+100 (25%)')
assert(D.windows[1].rows[3].bar.color[1]==.6 and D.windows[1].rows[3].value:GetText():find('^%-70'))
assert(D.RecapAmount({kind='damage',amount=1200,overkill=300,hp=0},true)=='-1.2k |cffff3333(300 overkill)|r (0%)')
assert(D.RecapAmount({kind='damage',amount=1200,overkill=300},false)=='-1.2k')
D.BackToGroup(1); D.Profile().windows[1].metric='damage'; D.RefreshWindow(1)
D.ShowDetail(rows[1],'damage',s,'spells'); assert(D.detail.rows[1].text:GetText():find('Fireball'))
assert(D.detail.rows[1].text:GetText():find('|cff808080ID '..D.detail.rows[1].entry.id..'|r',1,true),'spell ID missing from the detail window')
D.ShowDetail(rows[1],'damage',s,'targets'); assert(not D.detail.rows[1].text:GetText():find('ID ',1,true))
D.ShowDetail(rows[1],'deaths',s,'spells'); assert(#D.detail.deathList==1 and D.detail.rows[1].text:GetText():find('Flash Heal'))
assert(#allFrames>frameCount) -- explicit user detail opening is allowed to allocate
frameCount=#allFrames; combat=true; fighting=true
row:RunScript('OnClick','LeftButton')
Event('SPELL_DAMAGE','P','Player',1,'BOSS','Boss',0,133,'Fireball',4,10,0,4,0,0,0,false)
D.Refresh(); assert(#allFrames==frameCount)
assert(D.windows[1].rows[1].data.value==110)
D.BackToGroup(1); row:RunScript('OnEnter'); assert(hover.lines[1].value=='110' and #allFrames==frameCount)
D.BackToGroup(1)
assert(not D.Reset()); combat=false; fighting=false
D.Finish(); assert(#D.history.segments==1 and D.history.overall.actors.P.values.damage==240)
local firstID=D.history.segments[1].id
assert(D.history.overall.duration==4)
now=now+3; Event('SPELL_DAMAGE','P','Player',1,'BOSS','Boss',0,133,'Fireball',4,60,0,4,0,0,0,false)
now=now+2
local overall=D.Rows('overall','damage'); assert(overall[1].value==300)
local overallSpells=D.Breakdown(overall[1],'damage','spells'); assert(overallSpells[1].id==133 and overallSpells[1].total==170)
local overallRates=D.Rows('overall','dps'); assert(overallRates[1].value==50)
D.Finish(); assert(#D.history.segments==2 and D.history.overall.actors.P.values.damage==300)
assert(D.Segment(firstID).actors.P.values.damage==240)
-- History survives own SavedVariables rebind, not another addon's storage.
local saved=D.history; D.addon:OnInitialize(); assert(D.history==saved and #D.history.segments==2)
D.Profile().historyLimit=1; D.Apply(); assert(#D.history.segments==1 and D.history.overall.actors.P.values.damage==300)
-- Out-of-combat heals do not open a segment; unrelated outsiders ignored.
Event('SPELL_HEAL','H','Healer',2,'P','Player',1,2061,'Flash Heal',2,100,0,0,false); assert(not D.current)
Event('SPELL_DAMAGE','OTHER','Other',0,'OTHER2','Other 2',0,1,'Spell',1,100,0,1,0,0,0,false); assert(not D.current)
-- Disable detaches CLEU and hides windows, enable restores it.
D.Profile().enabled=false; D.Apply(); assert(not D.events.events.COMBAT_LOG_EVENT_UNFILTERED and not D.windows[1].frame:IsShown())
D.Parse(0,'SWING_DAMAGE','P','Player',1,'B','Boss',0,100,0,1,0,0,0,false); assert(not D.current)
D.Profile().enabled=true; D.Apply(); assert(D.events.events.COMBAT_LOG_EVENT_UNFILTERED)
local e=unlock.EDM_1; e.savePos(nil,'TOPLEFT','TOPLEFT',20,-40); e.applyPos(); assert(e.loadPos().y==-40)
-- Profile replacement callbacks read the active config rather than old tables.
local old=D.Profile(); D.addon.db.profile=D.Copy(old)
D.windows[1].settings:RunScript('OnClick','LeftButton'); D.menu.buttons[1]:RunScript('OnClick','LeftButton')
assert(D.Profile().windows[1].hideInDungeon and not old.windows[1].hideInDungeon)
D.Profile().windows[1].hideInDungeon=false; D.CloseMenu(); D.Apply()
-- Talent switches update the live cache while known past segments keep their specialization.
playerTalentGroup=2; D.events:RunScript('OnEvent','ACTIVE_TALENT_GROUP_CHANGED')
assert(D.specs.P.icon=='warrior-spec-3' and D.history.segments[1].actors.P.specIcon=='warrior-spec-2')
local oldRow=D.Rows('current','damage')[1]; assert(D.RowIcon(oldRow)=='warrior-spec-2')
-- Unknown talent data has a class icon, not an invented specialization.
local icon,coords=D.RowIcon({guid='UNKNOWN',class='PRIEST'})
assert(icon:find('UI%-CHARACTERCREATE%-CLASSES') and coords[1]==.5)
assert(D.RowIcon({guid='BOSS'})==nil)
-- Respect someone else's inspection and token reassignment. No shared result is misattributed.
D.specs.H=nil; D.specAttempts.H=nil; now=now+31; D.UpdateSpecs(); assert(D.pendingSpec)
NotifyInspect('target'); assert(not D.pendingSpec)
D.events:RunScript('OnEvent','INSPECT_TALENT_READY'); assert(not D.specs.H)
now=now+31; D.UpdateSpecs(); assert(D.pendingSpec)
units.party1.guid='NEW'; D.events:RunScript('OnEvent','INSPECT_TALENT_READY'); assert(not D.specs.H and not D.specs.NEW)
units.party1.guid='H'; D.specAttempts.H=nil; now=now+31
InspectFrame=CreateFrame('Frame'); D.UpdateSpecs(); assert(not D.pendingSpec)
InspectFrame:Hide(); combat=true; D.UpdateSpecs(); assert(not D.pendingSpec)
combat=false; inspectRange=false; D.UpdateSpecs(); assert(not D.pendingSpec)
inspectRange=true; now=now+6; D.UpdateSpecs(); assert(D.pendingSpec)
ClearInspectPlayer(); assert(not D.pendingSpec)
D.specAttempts.H=nil; now=now+31; D.UpdateSpecs(); assert(D.pendingSpec)
now=now+10; D.UpdateSpecs(); assert(not D.pendingSpec) -- timeout, then per-player retry throttle
now=now+21; D.UpdateSpecs(); assert(D.pendingSpec)
D.events:RunScript('OnEvent','INSPECT_TALENT_READY'); assert(D.specs.H.icon=='priest-spec-icon')
D.windows[1].title:RunScript('OnClick'); assert(D.menu:IsShown() and #D.menu.items==#D.metrics)
D.CloseMenu(); assert(not D.menu:IsShown() and not D.menu.cover:IsShown())
D.ShowReport(1); assert(#sent==0 and not D.report.box.autoFocus and not D.report.box.focus)
D.report.channel='PARTY'; D.report.send:RunScript('OnClick'); assert(D.reportQueue and #sent==0)
for _,f in ipairs(allFrames) do if f.scripts.OnUpdate then f:RunScript('OnUpdate',1) end end
assert(#sent>0 and sent[1][2]=='PARTY')
assert(CreateFrame==nativeFactory)
-- "+" copies window 1 into up to five windows, stacked above the highest one.
D.NewWindow(); assert(D.windows[3].home:IsShown() and D.Profile().windows[3].metric=='healing' and D.Profile().windows[3].savedPos.point=='CENTER')
D.NewWindow(); D.NewWindow(); assert(#D.Profile().windows==5 and D.Profile().windowCount==5 and D.windows[1].action.disabled)
D.windows[1].action:RunScript('OnClick','LeftButton'); assert(#D.Profile().windows==5)
local legacy=D.Profile().windows[5]
legacy.barAlpha=nil; legacy.chromeAlpha=0; legacy.showSpecIcons=false; legacy.fontOutline=nil
D.Apply(); assert(legacy.barAlpha==1 and legacy.fontOutline=='OUTLINE' and legacy.chromeAlpha==0 and not legacy.showSpecIcons)
-- "x" deletes an unlocked window; window 1 and locked windows stay.
D.Profile().windows[4].locked=true; D.Apply(); assert(D.windows[4].action.disabled)
D.windows[4].action:RunScript('OnClick','LeftButton'); assert(#D.Profile().windows==5)
D.Profile().windows[4].locked=false; D.Apply()
D.windows[5].action:RunScript('OnClick','LeftButton')
assert(#D.Profile().windows==4 and D.Profile().windowCount==4 and not D.windows[5].frame:IsShown() and not D.windows[1].action.disabled)
-- Login re-adds stripped default windows; the stored count keeps deleted ones gone.
D.Profile().windows[5]=D.Copy(D.Profile().windows[1]); D.Apply(); assert(#D.Profile().windows==4)
D.DeleteWindow(4); D.DeleteWindow(3); D.DeleteWindow(1); assert(#D.Profile().windows==2 and D.Profile().windowCount==2)
-- Flush/reconcile unknown pre-combat casters without double-counting.
now=now+10; D.Start('Aura Test')
D.Aura('SPELL_AURA_APPLIED',nil,nil,nil,'P','Player',1,139,'Renew','BUFF')
D.Aura('SPELL_AURA_APPLIED','H','Healer',2,'BOSS','Boss',0,118,'Polymorph','DEBUFF')
now=now+2; D.Aura('SPELL_AURA_REFRESH','H','Healer',2,'P','Player',1,139,'Renew','BUFF')
now=now+2; D.Aura('SPELL_AURA_REMOVED','H','Healer',2,'P','Player',1,139,'Renew','BUFF')
Event('SPELL_AURA_BROKEN_SPELL','P','Player',1,'BOSS','Boss',0,118,'Polymorph',64,133,'Fireball',4,'DEBUFF')
assert(D.current.actors.P.values.buffUptime==4 and D.current.actors.H.values.debuffUptime==4 and next(D.activeAuras)==nil)
D.Finish()
-- End grace continues while another group member is fighting, then freezes.
now=now+10; fighting=true; Event('SWING_DAMAGE','P','Player',1,'BOSS','Boss',0,10,0,1,0,0,0,false)
now=now+4; D.events:RunScript('OnUpdate',.4); assert(D.current)
fighting=false; now=now+2; D.events:RunScript('OnUpdate',.4); assert(D.current)
local frozen=D.Duration(D.current)
now=now+4; D.events:RunScript('OnUpdate',.4); assert(not D.current and D.history.segments[1].duration==frozen)
local duration=D.history.segments[1].duration; now=now+30; assert(D.Duration(D.history.segments[1])==duration)
''')
lua.execute('''
-- Isolated fixture: many spells/targets, hover reordering and transient focus.
local saved=D.history; local p=D.Profile(); local cfg=p.windows[1]
local originalMetric,originalSegment=cfg.metric,cfg.segment
local s=D.NewSegment(999,'Breakdown'); s.duration=10
local a=D.Actor(s,'P','Player',1); local h=D.Actor(s,'H','Healer',2)
for i=1,12 do D.Touch(a,'damage',i*10,i,'Ability '..i,'T'..i,'Target '..i) end
D.Touch(h,'damage',10,1,'Other Spell','T1','Target 1')
D.history={segments={s},overall=s,nextID=999}; cfg.metric='damage'; cfg.segment=999
D.Refresh(); local r=D.windows[1]; local count=#allFrames
r.rows[1]:RunScript('OnEnter'); local hover=D.breakdownTooltip
-- Retail breakdown: up to 15 spells, then the top three targets in red.
assert(hover:IsShown() and #hover.lines==16 and hover.lines[13].kind=='label' and hover.lines[13].name=='Targets')
local spellSum=0
for i=1,12 do spellSum=spellSum+hover.lines[i].percent end
assert(math.abs(spellSum-100)<.00001 and hover.lines[1].name=='Ability 12' and hover.lines[12].fill==10/120)
assert(hover.lines[14].name=='Target 12' and hover.lines[16].name=='Target 10' and hover.rows[14].bar.color[1]==.867)
p.tooltipMoreSpells=false; r.rows[1]:RunScript('OnLeave'); r.rows[1]:RunScript('OnEnter'); assert(#hover.lines==12)
p.tooltipMoreSpells=true; p.tooltipScale=150; p.tooltipAnchor='right'; r.rows[1]:RunScript('OnLeave'); r.rows[1]:RunScript('OnEnter')
assert(hover.scale==1.5 and hover:GetPoint()=='TOPLEFT' and select(2,hover:GetPoint())==r.frame)
p.tooltipAnchor='center'; r.rows[1]:RunScript('OnLeave'); r.rows[1]:RunScript('OnEnter'); assert(hover:GetPoint()=='CENTER')
p.tooltipScale=100; p.tooltipAnchor='row'; r.rows[1]:RunScript('OnLeave'); r.rows[1]:RunScript('OnEnter')
-- A reordered bar must never retain the old player's hover.
D.Touch(h,'damage',1000,1,'Other Spell','T1','Target 1'); D.Refresh()
assert(r.rows[1].data.guid=='H' and not hover:IsShown())
r.rows[2]:RunScript('OnClick','LeftButton'); assert(r.focusGUID=='P')
r.frame:RunScript('OnMouseWheel',-1); assert(r.offset==1 and r.rows[1].label:GetText()=='Ability 11')
assert(#allFrames==count)
cfg.metric='dps'; D.Refresh(); assert(not r.focusGUID)
local player
for _,row in ipairs(D.Rows(999,'dps')) do if row.guid=='P' then player=row end end
D.FocusWindow(1,player); assert(r.rows[1].data.value==12 and r.rows[1].value:GetText():find('12'))
s.duration=10000; D.Refresh(); assert(r.rows[1].bar.maximum==.012); s.duration=10; D.Refresh()
r.rows[1]:RunScript('OnEnter'); assert(hover.lines[1].name=='DPS: 12')
cfg.segment='overall'; D.Refresh(); assert(not r.focusGUID and not hover:IsShown())
D.FocusWindow(1,player)
local replacement=D.Copy(p); D.addon.db.profile=replacement; D.Apply(); assert(not r.focusGUID)
D.addon.db.profile=p; D.Apply()
D.FocusWindow(1,player); s.actors.P=nil; D.Refresh()
assert(r.focusGUID=='P' and not r.rows[1]:IsShown() and r.back:IsShown())
r.back:RunScript('OnClick'); assert(not r.focusGUID)
r.rows[1]:RunScript('OnEnter'); cfg.enabled=false; D.Apply(); assert(not hover:IsShown())
cfg.enabled=true; D.history=saved; cfg.metric, cfg.segment=originalMetric,originalSegment; D.Apply()
''')
lua.execute('''
-- Classic WoW UI (Style page): seeded once, the tooltip box, vanilla header art.
local p=D.Profile(); local r=D.windows[1]; local w=p.windows[1]
local oldBg,oldTex,oldTrack=w.bgColor,w.barTexture,w.barBgColor
local boxes={}; r.frame.SetBackdrop=function(_,b) boxes[#boxes+1]=b end
p.useClassicStyle=true; p.classicSeeded=nil; D._dmStyle=nil
D.Apply()
assert(D.DMClassic() and p.classicSeeded and w.barTexture=='blizzard' and w.barBgColor.a==.25 and w.bgColor.r==16/255)
assert(w.bgColor~=oldBg and w.barBgColor~=oldTrack, 'seed writes new tables so the Style slot keeps the old ones')
assert(boxes[#boxes].edgeFile=='Interface\\\\Tooltips\\\\UI-Tooltip-Border')
assert(r.header:GetPoint() and select(4,r.header:GetPoint())==5, 'header sits inside the box')
assert(r.settings.classic and r.settings.icon:GetTexture()=='Interface\\\\Icons\\\\Trade_Engineering' and not r.settings.icon.desaturated)
assert(r.mode.icon:GetTexture():find('INV_Sword_04') or r.mode.icon:GetTexture():find('Spell_Holy_Heal'))
w.bgColor.r=.5; p.classicSeeded=true; D.Apply(); assert(w.bgColor.r==.5, 'seed runs once per profile')
p.useClassicStyle=nil; p.classicSeeded=nil; D._dmStyle=nil
w.bgColor,w.barTexture,w.barBgColor=oldBg,oldTex,oldTrack
r.frame.SetBackdrop=nil; D.Apply()
''')
lua.execute('''
rows={}; buttons={}; EllesmereUI.Widgets={}
function EllesmereUI.Widgets:DualRow(parent,y,a,b) rows[#rows+1]=a; rows[#rows+1]=b; return {},50 end
function EllesmereUI.Widgets:SectionHeader(parent,text,y) return {},30 end
function EllesmereUI.Widgets:WideButton(parent,text,y,fn) buttons[text]=fn; return {},30 end
function Find(text) for _,r in ipairs(rows) do if r.text==text then return r end end end
function IsLoggedIn() return true end
''')
lua.execute((root/'EllesmereUIOptions/EUI_DamageMeters_335_Options.lua').read_text(encoding='utf-8-sig'))
lua.execute('''
local cfg=modules.EllesmereUIDamageMeters; assert(cfg and #cfg.pages==3 and cfg.pages[2]=='Spell History')
cfg.buildPage('Windows',UIParent,0); assert(Find('Select Window') and Find('Display'))
Find('Select Window').setValue(2); rows={}; cfg.buildPage('Windows',UIParent,0)
Find('Display').setValue('interrupts'); assert(D.Profile().windows[2].metric=='interrupts')
Find('Left Text Size').setValue(15); assert(D.Profile().windows[2].fontSize==15)
Find('Display').setValue('damage'); assert(D.windows[2].rows[1]:IsShown())
Find('Background Opacity').setValue(0); assert(D.windows[2].frame.backdropColor[4]==0)
Find('Bar Opacity').setValue(.3); assert(D.windows[2].rows[1].bar.color[4]==.3)
Find('Header / Footer Opacity').setValue(0); assert(D.windows[2].header.bg.vertex[4]==0)
D.windows[2].title:RunScript('OnEnter'); D.windows[2].title:RunScript('OnLeave'); assert(D.windows[2].header.bg.vertex[4]==0)
Find('Header / Footer Opacity').setValue(1)
Find('Font Outline').setValue('THICKOUTLINE'); assert(D.windows[2].rows[1].label.font[3]=='THICKOUTLINE')
Find('Icon Style').setValue('none'); assert(not D.windows[2].rows[1].icon:IsShown() and D.Profile().windows[2].showSpecIcons==false)
local point=D.windows[2].rows[1].label:GetPoint(); assert(point=='LEFT')
Find('Icon Style').setValue('spec'); assert(D.windows[2].rows[1].icon:IsShown() and Find('Icon Style').getValue()=='spec')
Find('Refresh Rate (Seconds)').setValue(1); assert(D.Profile().refreshRate==1)
Find('Number Format').setValue('full'); assert(not D.windows[2].rows[1].value:GetText():find('k'))
Find('Hide Rank Numbers').setValue(true); assert(not D.windows[2].rows[1].label:GetText():find('^%d+%.'))
Find('Hide Rank Numbers').setValue(false); assert(D.windows[2].rows[1].label:GetText():find('^1%.'))
Find('Bar Color').swatches[2].setValue(1,0,0); assert(D.Profile().windows[2].barColorMode=='custom')
assert(D.windows[2].rows[1].bar.color[1]==1 and D.windows[2].rows[1].bar.color[2]==0)
Find('Bar Color').swatches[1].onClick(); assert(D.Profile().windows[2].barColorMode=='class')
Find('Border Color').swatches[2].setValue(1,0,0); assert(D.Profile().windows[2].borderUseAccent==false)
Find('Border Color').swatches[1].onClick(); assert(D.Profile().windows[2].borderUseAccent==true)
Find('Background Color').setValue(.2,.3,.4); assert(D.Profile().windows[2].bgColor.b==.4)
Find('Bar Background').setValue(.1,.1,.1,.5); assert(D.Profile().windows[2].barBgColor.a==.5)
Find('Header Height').setValue(28); Find('Spacing').setValue(3); Find('Bar Border Size').setValue(1)
Find('Header Bottom Border').setValue(2); Find('Always Show Player').setValue(true)
local texNames,texOrder=D.BarTextureChoices(); Find('Bar Texture').setValue(texOrder[#texOrder])
assert(D.windows[2].rows[1]:IsShown() and #lifecycleErrors==0)
Find('Header Height').setValue(22); Find('Spacing').setValue(2); Find('Bar Border Size').setValue(0)
Find('Header Bottom Border').setValue(0); Find('Always Show Player').setValue(false); Find('Bar Texture').setValue('atrocity')
assert(D.Profile().windows[1].barAlpha==1 and D.Profile().windows[1].alpha==.75)
-- New Retail window options.
D.hoverDriver:RunScript('OnUpdate',.2); assert(not D.windows[2].headerHover)
Find('Show Header Icons on Mouseover').setValue(true); assert(D.Profile().windows[2].mouseoverIcons and D.windows[2].iconCount==0)
Find('Show Header Icons on Mouseover').setValue(false); Find('Hide Reset Button').setValue(true)
assert(not D.windows[2].reset:IsShown() and D.windows[2].iconCount==4); Find('Hide Reset Button').setValue(false)
Find('Snap to Other Windows').setValue(false); assert(D.Profile().windows[2].snapDisabled); Find('Snap to Other Windows').setValue(true)
Find('Accent Colored Header Text').setValue(false); assert(D.Profile().windows[2].titleUseAccent==false); Find('Accent Colored Header Text').setValue(true)
Find('Breakdown Scale (%)').setValue(120); Find('Breakdown Position').setValue('left'); Find('Show 15 Spells (Otherwise 8)').setValue(false)
assert(D.Profile().tooltipScale==120 and D.Profile().tooltipAnchor=='left' and D.TooltipSpellLimit()==8)
Find('Breakdown Scale (%)').setValue(100); Find('Breakdown Position').setValue('row'); Find('Show 15 Spells (Otherwise 8)').setValue(true)
assert(Find('Standalone Combat Timer') and Find('Reset Data Keybind (Example: CTRL-R)') and (Find('Delete Selected Window') or buttons['Delete Selected Window']))
rows={}; cfg.buildPage('Spell History',UIParent,0); assert(Find('Enable Icon History') and Find('Enable Bar History') and Find('Bar Color'))
assert(D.optionsOpen)
rows={}; cfg.buildPage('Combat Data',UIParent,0); assert(Find('Save History Between Sessions'))
Find('Save History Between Sessions').setValue(false)
D.events:RunScript('OnEvent','PLAYER_LOGOUT'); assert(EllesmereUIDamageMetersHistory==nil)
SlashCmdList.EUI335DM(''); assert(shownModule=='EllesmereUIDamageMeters')
-- Retail corner grip and padlock: hidden until hovered, faded in over 0.12 s.
cursorX,cursorY=500,500; function GetCursorPosition() return cursorX,cursorY end
local p=D.Profile(); local c1,c2=p.windows[1],p.windows[2]
c1.enabled,c2.enabled,c1.visibility,c2.visibility=true,true,'always','always'
local w1,r1,w2,r2=c1.width,c1.rows,c2.width,c2.rows
c1.width,c1.rows,c2.width,c2.rows=300,10,250,5; D.SetOptionsOpen(false); D.Apply()
local W1,W2=D.windows[1],D.windows[2]
assert(W1.frame:IsShown() and W2.frame:IsShown())
local g,l=W2.grip,W2.lock
assert(g.tex.texture:find('resize_element') and g.tex.desaturated and l.tex.texture:find('dm_unlocked') and g.alpha==0 and l.alpha==0)
assert(l:GetPoint()=='RIGHT' and select(2,l:GetPoint())==g)
mouseOver=W2.frame; W2.frame:RunScript('OnEnter'); assert(D.hoverDriver:IsShown())
D.hoverDriver:RunScript('OnUpdate',.2); assert(W2.fade==1 and g.alpha==.3 and l.alpha==.3)
g:RunScript('OnEnter'); assert(g.alpha==.7); g:RunScript('OnLeave'); assert(g.alpha==.3)
mouseOver=nil; D.hoverDriver:RunScript('OnUpdate',.06); D.hoverDriver:RunScript('OnUpdate',.2)
assert(W2.fade==0 and g.alpha==0 and not D.hoverDriver:IsShown())
-- Header icons can stay hidden until the header is hovered.
c2.mouseoverIcons=true; D.Apply(); assert(W2.iconCount==0 and W2.settings.alpha==0)
mouseOver=W2.header; W2.title:RunScript('OnEnter'); assert(W2.iconCount==5 and W2.settings.alpha==1)
mouseOver=nil; D.hoverDriver:RunScript('OnUpdate',.2); assert(W2.iconCount==0 and not W2.headerHover)
c2.mouseoverIcons=false; c2.hideResetButton=true; D.Apply()
assert(not W2.reset:IsShown() and select(4,W2.action:GetPoint())==-(3*c2.headerHeight-6))
c2.hideResetButton=false; D.Apply()
-- Resizing: free width, whole rows, Shift locks the first axis, sizes snap to the other window.
local step=c2.rowHeight+c2.barSpacing
local function Drag(moves)
    cursorX,cursorY=500,500; g:RunScript('OnMouseDown','LeftButton'); assert(W2.resizing and g.scripts.OnUpdate)
    for _,m in ipairs(moves) do cursorX,cursorY=500+m[1],500-m[2]; g.scripts.OnUpdate(g) end
    g:RunScript('OnMouseUp'); assert(not W2.resizing and not g.scripts.OnUpdate)
end
Drag({{60,3*step}}); assert(c2.width==310 and c2.rows==8 and c1.width==300 and c1.rows==10)
assert(c2.savedPos.point=='CENTER' and W2.frame.width==c2.width)
shift=true; Drag({{20,2},{40,3*step}}); shift=false; assert(c2.width==350 and c2.rows==8,'shift locks the width axis')
Drag({{-47,0}}); assert(c2.width==300,'width snaps to window 1')
Drag({{5000,-5000}}); assert(c2.width==1200 and c2.rows==1,'resize respects width and row limits')
c2.width,c2.rows=250,5; D.Apply()
-- Padlock: a locked window cannot be resized, dragged or closed.
l:RunScript('OnClick'); assert(c2.locked and l.tex.texture:find('dm_locked') and l:GetPoint()=='BOTTOMRIGHT' and W2.action.disabled)
assert(g.alpha==0); g:RunScript('OnMouseDown','LeftButton'); assert(not W2.resizing)
W2.title:RunScript('OnMouseDown','LeftButton'); assert(not W2.drag)
W2.action:RunScript('OnClick','LeftButton'); assert(#p.windows==2)
l:RunScript('OnClick'); assert(not c2.locked and l.tex.texture:find('dm_unlocked') and not W2.action.disabled)
-- Title drag snaps to the other window's edges; a click without movement opens the menu.
W1.frame:ClearAllPoints(); W1.frame:SetPoint('TOPLEFT',UIParent,'BOTTOMLEFT',400,600)
local function Move(dx,dy)
    cursorX,cursorY=500,500; W2.title:RunScript('OnMouseDown','LeftButton'); assert(W2.drag)
    cursorX,cursorY=500+dx,500+dy; W2.title.scripts.OnUpdate()
    local left,top=W2.frame.left,W2.frame.top
    W2.title:RunScript('OnMouseUp','LeftButton'); W2.title:RunScript('OnClick','LeftButton')
    assert(not W2.drag and not W2.title.scripts.OnUpdate); return left,top
end
local left,top=Move(603,-98); assert(left==700 and top==600 and not D.menu:IsShown(),'drag snaps to the right edge')
W2.title:RunScript('OnMouseDown','LeftButton'); W2.title:RunScript('OnMouseUp','LeftButton'); W2.title:RunScript('OnClick','LeftButton')
assert(D.menu:IsShown()); D.CloseMenu()
c2.snapDisabled=true; c2.savedPos=nil; D.Apply(); W1.frame:ClearAllPoints(); W1.frame:SetPoint('TOPLEFT',UIParent,'BOTTOMLEFT',400,600)
left,top=Move(603,-98); assert(left==703 and top==602,'snapping can be disabled'); c2.snapDisabled=false
D.Apply()
-- Standalone combat timer: preview while options are open, live while fighting.
local t
p.standaloneTimer=true; D.SetOptionsOpen(true); D.Apply(); t=D.standaloneTimer
assert(t:IsShown() and t.text:GetText()=='11:37' and unlock.EDM_CombatTimer)
D.SetOptionsOpen(false); assert(not t:IsShown())
D.Start('Timer'); now=now+65; D.UpdateTimer(); assert(t:IsShown() and t.text:GetText()=='1:05')
now=now+1; t:RunScript('OnUpdate',.2); assert(t.text:GetText()=='1:06')
p.standaloneTimerDecimal=true; D.Apply(); assert(t.text:GetText()=='1:06.0')
p.standaloneTimerAnchor='topright'; D.Apply(); assert(t:GetPoint()=='BOTTOMRIGHT' and select(2,t:GetPoint())==W1.frame)
p.toggleIncludeTimer=true; D.ToggleWindows(); assert(D.toggleHidden and not t:IsShown() and not W1.frame:IsShown())
D.ToggleWindows(); assert(not D.toggleHidden and t:IsShown() and W1.frame:IsShown())
D.Finish(); D.UpdateTimer(); assert(not t:IsShown())
p.standaloneTimerShowOOC=true; D.UpdateTimer(); assert(t:IsShown())
p.standaloneTimer=false; p.standaloneTimerAnchor='free'; p.standaloneTimerDecimal=false; p.standaloneTimerShowOOC=false; D.Apply(); assert(not t:IsShown())
-- Keybinds: override bindings on hidden buttons, deferred out of combat, restored after LoadBindings.
chat={}; DEFAULT_CHAT_FRAME={AddMessage=function(_,text) chat[#chat+1]=text end}
local function Bound(key) for owner,o in pairs(overrides) do if o.key==key then return owner,o.button end end end
p.resetDataKey='ctrl-r'; p.toggleWindowsKey=' alt-m '; D.Apply()
local rb,rname=Bound('CTRL-R'); local tb,tname=Bound('ALT-M')
assert(rb==EllesmereUIDMResetBindBtn and rname=='EllesmereUIDMResetBindBtn' and tname=='EllesmereUIDMToggleBindBtn')
tb:RunScript('OnClick'); assert(D.toggleHidden and not W1.frame:IsShown()); tb:RunScript('OnClick'); assert(not D.toggleHidden and W1.frame:IsShown())
combat=true; p.resetDataKey='CTRL-T'; D.ApplyKeybinds(); assert(Bound('CTRL-R') and D.bindWatch.events.PLAYER_REGEN_ENABLED)
rb:RunScript('OnClick'); assert(chat[1] and chat[1]:find('finish combat'))
combat=false; D.bindWatch:RunScript('OnEvent','PLAYER_REGEN_ENABLED')
assert(Bound('CTRL-T') and not Bound('CTRL-R') and not D.bindWatch.events.PLAYER_REGEN_ENABLED)
overrides={}; D.bindWatch:RunScript('OnEvent','UPDATE_BINDINGS'); assert(not Bound('CTRL-T'),'own binding writes are ignored')
now=now+1; D.bindWatch:RunScript('OnEvent','UPDATE_BINDINGS'); assert(Bound('CTRL-T') and Bound('ALT-M'))
D.Touch(D.Actor(D.history.overall,'P','Player',1),'damage',10,1,'Hit','BOSS','Boss'); D.history.segments[1]=D.NewSegment(50,'Old')
EllesmereUIDMResetBindBtn:RunScript('OnClick'); assert(#D.history.segments==0)
p.resetDataKey=''; p.toggleWindowsKey=''; D.Apply(); assert(next(overrides)==nil and not D.bindWatch.events.UPDATE_BINDINGS)
-- Spell History: no cast events while both displays are off.
local sh,ev,H=p.spellHistory,D.castEvents,D.castHistory
assert(next(ev.events)==nil and not sh.iconEnabled and not sh.barEnabled)
sh.iconEnabled,sh.barEnabled=true,true; D.Apply(); assert(ev.events.UNIT_SPELLCAST_SENT and ev.events.UNIT_SPELLCAST_CHANNEL_STOP)
local win=EllesmereUIDMBarHistory; local bars=win.bars; local strip=EllesmereUIDMIconStrip
assert(win:IsShown() and not EllesmereUIDMIconHistoryFrame:IsShown() and unlock.EDM_IconHistory)
D.SetOptionsOpen(true); assert(EllesmereUIDMIconHistoryFrame:IsShown() and strip.children[5].shown,'options preview fills the strip')
D.SetOptionsOpen(false); assert(not EllesmereUIDMIconHistoryFrame:IsShown())
local function Cast(event,name,target) ev:RunScript('OnEvent',event,'player',name,'Rank 1',target) end
local function Icon(i) return strip.children[i].children[2] end
nativeCast={'Frostbolt','Rank 1','Frostbolt','frost-icon',now*1000,(now+2)*1000}
Cast('UNIT_SPELLCAST_SENT','Frostbolt','Boss'); Cast('UNIT_SPELLCAST_START','Frostbolt')
assert(H[1].spellName=='Frostbolt' and H[1].status=='casting' and H[1].target=='Boss' and H[1].icon=='frost-icon')
assert(bars[1].row:IsShown() and bars[1].fill.value==0 and Icon(1).texture=='frost-icon')
now=now+1; D.RefreshBarWindow(); assert(bars[1].fill.value==.5 and bars[1].right:GetText()=='1.0  Boss')
Cast('UNIT_SPELLCAST_FAILED','Frostbolt'); assert(H[1].status=='casting','re-pressing a key mid-cast is not a failure')
nativeCast=nil; Cast('UNIT_SPELLCAST_SUCCEEDED','Frostbolt'); Cast('UNIT_SPELLCAST_STOP','Frostbolt')
assert(H[1].status=='success' and #H==1 and bars[1].fill.value==1 and bars[1].right:GetText()=='1.0s  Boss')
assert(bars[1].fill.color[1]==.298)
nativeCast={'Polymorph','Rank 1','Polymorph','poly-icon',now*1000,(now+1.5)*1000}
Cast('UNIT_SPELLCAST_START','Polymorph'); nativeCast=nil; Cast('UNIT_SPELLCAST_INTERRUPTED','Polymorph')
assert(H[1].status=='interrupted' and bars[1].fill.color[1]==.859 and Icon(1).vertex[1]==.859 and bars[1].right:GetText():find('Interrupted'))
now=now+.2; Cast('UNIT_SPELLCAST_SUCCEEDED','Polymorph'); assert(H[1].status=='success' and #H==2,'a late success repairs the entry')
nativeCast={'Fireball','Rank 1','Fireball','fire-icon',now*1000,(now+2)*1000}
Cast('UNIT_SPELLCAST_START','Fireball'); now=now+.5; nativeCast=nil; Cast('UNIT_SPELLCAST_STOP','Fireball'); assert(H[1].status=='casting')
D.castStopDriver:RunScript('OnUpdate',.01); assert(H[1].status=='failed' and H[1].fillProgress==.25 and bars[1].fill.value==.25)
Cast('UNIT_SPELLCAST_SENT','Ice Lance','Boss'); Cast('UNIT_SPELLCAST_SUCCEEDED','Ice Lance')
assert(H[1].isInstant and H[1].icon=='spell-icon' and bars[1].right:GetText()=='Boss' and #H==4)
Cast('UNIT_SPELLCAST_SUCCEEDED','Spell 75'); assert(#H==4,'Auto Shot is not recorded')
nativeChannel={'Drain Life','Rank 1','Drain Life','drain-icon',now*1000,(now+3)*1000}
Cast('UNIT_SPELLCAST_CHANNEL_START','Drain Life'); Cast('UNIT_SPELLCAST_SUCCEEDED','Drain Life')
assert(H[1].status=='channeling' and #H==5)
now=now+1; D.RefreshBarWindow(); assert(math.abs(bars[1].fill.value-2/3)<.0001)
nativeChannel=nil; Cast('UNIT_SPELLCAST_CHANNEL_STOP','Drain Life'); assert(H[1].status=='success' and H[1].castDuration==1)
assert(bars[5].row:IsShown() and bars[5].label:GetText()=='Frostbolt' and not bars[6].row:IsShown() and strip.children[5].shown)
-- Hide rules and the Show / Hide keybind include.
sh.iconHideOutOfInstance=true; D.ApplySpellHistory(); assert(not EllesmereUIDMIconHistoryFrame:IsShown() and win:IsShown())
instanceInside,instanceKind=1,'party'; D.ApplySpellHistory(); assert(EllesmereUIDMIconHistoryFrame:IsShown())
sh.barHideInDungeon=true; D.ApplySpellHistory(); assert(not win:IsShown())
sh.iconHideOutOfInstance,sh.barHideInDungeon=false,false; instanceInside,instanceKind=nil,'none'; D.ApplySpellHistory()
p.toggleIncludeSpellHistory=true; D.ToggleWindows(); assert(not win:IsShown() and not EllesmereUIDMIconHistoryFrame:IsShown())
D.ToggleWindows(); assert(win:IsShown() and EllesmereUIDMIconHistoryFrame:IsShown()); p.toggleIncludeSpellHistory=false
-- Bar window lock button.
win.lockButton:RunScript('OnClick','LeftButton'); assert(sh.barLocked and win.lockButton.icon.texture:find('dm_locked_top'))
win.hdr:RunScript('OnMouseDown','LeftButton'); assert(not win.moving)
win.lockButton:RunScript('OnClick','LeftButton'); assert(not sh.barLocked and win.lockButton.icon.texture:find('dm_unlock_top'))
sh.iconEnabled,sh.barEnabled=false,false; D.Apply()
assert(next(ev.events)==nil and not win:IsShown() and not EllesmereUIDMIconHistoryFrame:IsShown())
c1.width,c1.rows,c2.width,c2.rows=w1,r1,w2,r2; D.Apply()
assert(#lifecycleErrors==0,lifecycleErrors[1])
''')
original=Path('D:/World of Warcraft/_retail_/Interface/AddOns/EllesmereUIDamageMeters')
for p in original.rglob('*'):
    if p.is_file() and p.suffix!='.toc': assert p.read_bytes()==(root/'EllesmereUIDamageMeters'/p.relative_to(original)).read_bytes(),p
compile_lua=lua.eval('function(s,n) local f,e=loadstring(s,n); assert(f,e) end')
for p in (root/'EllesmereUIDamageMeters').rglob('*.lua'):
    compile_lua(p.read_text(encoding='utf-8-sig'),str(p))
active=0
for folder in root.glob('EllesmereUI*'):
    if not folder.is_dir(): continue
    for toc in folder.glob('*.toc'):
        for line in toc.read_text(encoding='utf-8-sig').splitlines():
            if line.strip() and not line.startswith('#') and line.endswith('.lua'):
                p=folder/line.replace('\\','/'); compile_lua(p.read_text(encoding='utf-8-sig'),str(p)); active+=1
print(f'PASS: {active} active Lua 5.1 files; actual Core/meter lifecycle and independent collector/history; Retail look migration, header icons/5 windows/delete, grip fade/padlock/axis lock/size+edge snapping, breakdown scale/anchor/15 spells/top targets, death recap HP%/overkill, standalone timer, keybinds, Spell History icons/bars/cast outcomes; real mouseover spell/target bars/icons/percentages, actor focus/back/targets/death recap/rates/scroll/live updates, row reorder/segment/metric/profile/hide cleanup without combat allocation; native specs and opacity/outline settings; unlock, explicit reports and unchanged Retail references.')
