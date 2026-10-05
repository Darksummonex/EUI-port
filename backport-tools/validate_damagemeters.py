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
for file in ['EUI_DamageMeters_335.lua','EUI_DamageMeters_335_Parser.lua','EUI_DamageMeters_335_Specs.lua','EUI_DamageMeters_335_Display.lua','EUI_DamageMeters_335_Breakdown.lua','EUI_DamageMeters_335_Home.lua']:
    lua.execute((root/'EllesmereUIDamageMeters'/file).read_text(encoding='utf-8-sig'),'EllesmereUIDamageMeters',ns)
lua.globals().D=ns
lua.execute('''
lifecycle:RunScript('OnEvent','ADDON_LOADED','EllesmereUIDamageMeters')
assert(#lifecycleErrors==0,lifecycleErrors[1]); assert(D.addon.db and D.history)
function IsLoggedIn() return true end
lifecycle:RunScript('OnEvent','PLAYER_LOGIN')
assert(#lifecycleErrors==0,lifecycleErrors[1]); assert(D.events.events.COMBAT_LOG_EVENT_UNFILTERED)
assert(#D.Profile().windows==2 and #D.windows[1].rows==40 and unlock.EDM_1)
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
row:RunScript('OnEnter'); assert(hover:IsShown() and hover.title:GetText():find("Player's Damage Done"))
assert(hover.lines[2].name=='Fireball' and hover.lines[2].value=='100')
assert(math.abs(hover.lines[2].percent-100/230*100)<.0001 and hover.rows[2].icon.texture=='spell-icon')
assert(hover.lines[#hover.lines].name=='Boss' and hover.lines[#hover.lines].percent==100)
row:RunScript('OnLeave'); assert(not hover:IsShown())
row:RunScript('OnClick','LeftButton')
assert(D.windows[1].focusGUID=='P' and D.windows[1].back:IsShown())
assert(D.windows[1].rows[1].data.breakdown and D.windows[1].rows[1].label:GetText()=='Fireball')
assert(D.windows[1].rows[1].icon.texture=='spell-icon' and D.windows[1].title.text:GetText():find('Player'))
local focusReport=D.ReportLines(1); assert(focusReport[1]:find('Player') and focusReport[2]:find('Fireball'))
assert(not hover:IsShown() and #allFrames==beforeHover)
D.windows[1].rows[1]:RunScript('OnEnter'); assert(hover.lines[2].name=='1 hits / 1 critical')
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
-- Header: no footer controls; segment picker beside settings, synced windows follow.
local hh=wc.headerHeight
assert(w1.close:GetPoint()=='TOPRIGHT' and select(5,w1.settings:GetPoint())==-3 and select(4,w1.segment:GetPoint())==-3-2*(hh+2))
assert(select(4,w1.report:GetPoint())==-3-4*(hh+2) and math.abs(w1.frame:GetHeight()-D.WindowHeight(wc))<.01)
assert(w1.title.text:GetText():find('Damage Done %- Current') and w1.title.text:GetText():find('%d:%d%d'),w1.title.text:GetText())
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
local oldRows=wc.rows; menu.buttons[6].input:SetText(tostring(hh+8+4*(wc.rowHeight+wc.barSpacing))); menu.buttons[6].input:RunScript('OnEnterPressed')
assert(wc.rows==4 and menu.buttons[6].input:GetText()==tostring(D.WindowHeight(wc)))
wc.rows=oldRows; wc.width=310
menu.buttons[8]:RunScript('OnClick','LeftButton'); assert(wc.hideTimer and not w1.title.text:GetText():find('%d:%d%d'))
menu.buttons[8]:RunScript('OnClick','LeftButton')
menu.buttons[9]:RunScript('OnClick','LeftButton'); assert(wc.autoSwapInstance)
D.InstanceChanged(); instanceInside,instanceKind=1,'raid'; D.InstanceChanged(); assert(wc.segment=='current')
instanceInside,instanceKind=nil,'none'; D.InstanceChanged(); assert(wc.segment=='overall')
menu.buttons[9]:RunScript('OnClick','LeftButton')
assert(menu.buttons[10].text:GetText()=='Auto Current on Combat'); menu.buttons[10]:RunScript('OnClick','LeftButton'); assert(wc.autoCurrentOnCombat==false)
menu.buttons[10]:RunScript('OnClick','LeftButton'); assert(wc.autoCurrentOnCombat==true)
menu.buttons[12]:RunScript('OnClick','LeftButton'); assert(shownModule=='EllesmereUIDamageMeters' and not menu:IsShown())
shownModule=nil; wc.segment=origSegment; D.Apply()
-- Death view drills into the latest native recap rather than spell counts.
D.Profile().windows[1].metric='deaths'; D.RefreshWindow(1)
D.windows[1].rows[1]:RunScript('OnClick','LeftButton')
assert(D.windows[1].focusGUID=='P' and D.windows[1].rows[1].data.recap)
assert(D.windows[1].rows[1].label:GetText():find('Flash Heal'))
D.BackToGroup(1); D.Profile().windows[1].metric='damage'; D.RefreshWindow(1)
D.ShowDetail(rows[1],'damage',s,'spells'); assert(D.detail.rows[1].text:GetText():find('Fireball'))
D.ShowDetail(rows[1],'deaths',s,'spells'); assert(#D.detail.deathList==1 and D.detail.rows[1].text:GetText():find('Flash Heal'))
assert(#allFrames>frameCount) -- explicit user detail opening is allowed to allocate
frameCount=#allFrames; combat=true; fighting=true
row:RunScript('OnClick','LeftButton')
Event('SPELL_DAMAGE','P','Player',1,'BOSS','Boss',0,133,'Fireball',4,10,0,4,0,0,0,false)
D.Refresh(); assert(#allFrames==frameCount)
assert(D.windows[1].rows[1].data.value==110)
D.BackToGroup(1); row:RunScript('OnEnter'); assert(hover.lines[2].value=='110' and #allFrames==frameCount)
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
local old=D.Profile(); D.addon.db.profile=D.Copy(old); D.windows[1].close:RunScript('OnClick')
assert(not D.Profile().windows[1].enabled and old.windows[1].enabled)
D.Profile().windows[1].enabled=true; D.Apply()
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
D.NewWindow(); D.NewWindow(); D.NewWindow(); assert(#D.Profile().windows==4)
local legacy=D.Profile().windows[4]
legacy.barAlpha=nil; legacy.chromeAlpha=0; legacy.showSpecIcons=false; legacy.fontOutline=nil
D.Apply(); assert(legacy.barAlpha==1 and legacy.fontOutline=='OUTLINE' and legacy.chromeAlpha==0 and not legacy.showSpecIcons)
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
assert(hover:IsShown() and #hover.lines==17)
assert(hover.lines[10].name=='Other' and hover.lines[17].name=='Other')
local spellSum,targetSum=0,0
for i,line in ipairs(hover.lines) do if line.percent then
 if i<11 then spellSum=spellSum+line.percent else targetSum=targetSum+line.percent end
end end
assert(math.abs(spellSum-100)<.00001 and math.abs(targetSum-100)<.00001)
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
rows={}; buttons={}; EllesmereUI.Widgets={}
function EllesmereUI.Widgets:DualRow(parent,y,a,b) rows[#rows+1]=a; rows[#rows+1]=b; return {},50 end
function EllesmereUI.Widgets:SectionHeader(parent,text,y) return {},30 end
function EllesmereUI.Widgets:WideButton(parent,text,y,fn) buttons[text]=fn; return {},30 end
function Find(text) for _,r in ipairs(rows) do if r.text==text then return r end end end
function IsLoggedIn() return true end
''')
lua.execute((root/'EllesmereUIOptions/EUI_DamageMeters_335_Options.lua').read_text(encoding='utf-8-sig'))
lua.execute('''
local cfg=modules.EllesmereUIDamageMeters; assert(cfg and #cfg.pages==2)
cfg.buildPage('Windows',UIParent,0); assert(Find('Select Window') and Find('Display'))
Find('Select Window').setValue(2); rows={}; cfg.buildPage('Windows',UIParent,0)
Find('Display').setValue('interrupts'); assert(D.Profile().windows[2].metric=='interrupts')
Find('Left Text Size').setValue(15); assert(D.Profile().windows[2].fontSize==15)
Find('Display').setValue('damage'); assert(D.windows[2].rows[1]:IsShown())
Find('Background Opacity').setValue(0); assert(D.windows[2].frame.backdropColor[4]==0)
Find('Bar Opacity').setValue(.3); assert(D.windows[2].rows[1].bar.color[4]==.3)
Find('Header / Footer Opacity').setValue(0); assert(D.windows[2].title.backdropColor[4]==0)
D.windows[2].title:RunScript('OnEnter'); D.windows[2].title:RunScript('OnLeave')
assert(D.windows[2].title.backdropColor[4]==0 and D.windows[2].segment.backdropColor[4]==0)
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
Find('Header Height').setValue(22); Find('Spacing').setValue(1); Find('Bar Border Size').setValue(0)
Find('Header Bottom Border').setValue(0); Find('Always Show Player').setValue(false); Find('Bar Texture').setValue('none')
assert(D.Profile().windows[1].barAlpha==1 and D.Profile().windows[1].alpha==.92)
rows={}; cfg.buildPage('Combat Data',UIParent,0); assert(Find('Save History Between Sessions'))
Find('Save History Between Sessions').setValue(false)
D.events:RunScript('OnEvent','PLAYER_LOGOUT'); assert(EllesmereUIDamageMetersHistory==nil)
SlashCmdList.EUI335DM(''); assert(shownModule=='EllesmereUIDamageMeters')
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
print(f'PASS: {active} active Lua 5.1 files; actual Core/meter lifecycle and independent collector/history; real mouseover spell/target bars/icons/percentages/Other totals, actor focus/back/targets/death recap/rates/scroll/live updates, row reorder/segment/metric/profile/hide cleanup without combat allocation; native specs and opacity/outline settings; unlock, explicit reports and unchanged Retail references.')
