"""Wrath Cooldown Manager 0.2: Retail bar model and migration, Unlock Mode movers with
Element Options targets, CDM icons, tracking bars, bar glows, options pages, combat
allocation, Lua limits, combined EUI memory and untouched Retail references."""
from pathlib import Path
import re
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
module=root/'EllesmereUICooldownManager'
toc=(module/'EllesmereUICooldownManager.toc').read_text(encoding='utf-8-sig')
assert '## Version: 9.3.4-335-0.9' in toc
files=[l.strip() for l in toc.splitlines() if l.strip().endswith('.lua')]
assert files==['EUI_CooldownManager_335_Catalog.lua','EUI_CooldownManager_335_TrinketData.lua','EUI_CooldownManager_335.lua','EUI_CooldownManager_335_Display.lua',
    'EUI_CooldownManager_335_TrackingBars.lua','EUI_CooldownManager_335_Glows.lua'],files
options_toc=(root/'EllesmereUIOptions/EllesmereUIOptions.toc').read_text(encoding='utf-8-sig')
version=re.search(r'## Version: 9\.3\.4-335-0\.(\d+)',options_toc)
assert version and int(version.group(1))>=70 and 'EUI_CooldownManager_335_Options.lua' in options_toc
readme=(module/'README-335.md').read_text(encoding='utf-8-sig')
assert '0.2' in readme and 'Não portado' in readme
sources={f:(module/f).read_text(encoding='utf-8-sig') for f in files}
sources['Options']=(root/'EllesmereUIOptions/EUI_CooldownManager_335_Options.lua').read_text(encoding='utf-8-sig')
for name,src in sources.items():
    for banned in ('C_CooldownViewer','C_Spell.','C_Timer','SetRotatesTexture','SetColorTexture','SetAtlas','SetShown','SetSwipeColor','CreateMaskTexture','.png'):
        assert banned not in src,(name,banned)
assert '_dbg' not in sources['Options'] and 'message=="debug"' not in sources['EUI_CooldownManager_335_Display.lua'],'temporary debug code'
lua=LuaRuntime()
# Lua 5.1 compile of every chunk, and the 200-locals limit per function.
for name,src in sources.items():
    ok=lua.eval('function(s,n) local f,e=loadstring(s,n); return f~=nil,e end')(src,name)
    assert ok[0],(name,ok[1])
for file in ['backport-tools/wrath_mock.lua','backport-tools/inventory_resources_mock.lua','EllesmereUI/EllesmereUI_Lite.lua']:
    if file.endswith('EllesmereUI_Lite.lua'):
        lua.execute('lifecycleErrors={}; function geterrorhandler() return function(e) lifecycleErrors[#lifecycleErrors+1]=e end end')
    lua.execute((root/file).read_text(encoding='utf-8-sig'),'EllesmereUI',lua.table())
lua.execute('''
lifecycleErrors={}; function geterrorhandler() return function(e) lifecycleErrors[#lifecycleErrors+1]=e end end
for _,f in ipairs(allFrames) do if f.events.ADDON_LOADED and f.events.PLAYER_LOGIN then lifecycle=f end end
lifecycle:RunScript('OnEvent','ADDON_LOADED','EllesmereUI')
local m=getmetatable(UIParent).__index
function m:SetShadowColor(...) self.shadowColor={...} end
function m:SetShadowOffset(...) self.shadowOffset={...} end
function m:SetClampedToScreen() end
function m:SetMovable() end
function m:SetSize(w,h) self.width,self.height=w,h end
function m:SetPoint(p,rel,rp,x,y) self.point={p,rel,rp,x,y} end
function m:ClearAllPoints() self.point=nil end
function m:GetPoint() if self.point then return unpack(self.point) end end
function m:SetVertexColor(...) self.color={...} end
function m:SetFrameStrata(s) self.strata=s end
function m:SetAlpha(a) self.alpha=a end
function MouseIsOver() return false end
function UnitHasVehicleUI() return false end
combat=false; function InCombatLockdown() return combat end
spells={{id=100,name='Charge'},{id=200,name='Charge'},{id=300,name='Passive',passive=true},{id=600,name='Kick'}}
function GetSpellName(slot,book) local s=(book=='pet' and {{id=400,name='Pet Skill'}} or spells)[slot]; if s then return s.name,'Rank '..slot end end
function GetSpellLink(slot,book) local name=GetSpellName(slot,book); if name then return 'spell:'..(book=='pet' and 400 or spells[slot].id) end end
function GetSpellTexture(slot,book) return 'icon-'..slot..book end
function IsPassiveSpell(slot,book) return book~='pet' and spells[slot].passive end
function HasPetSpells() return 1 end
function GetSpellInfo(id) id=tonumber(id); if not id or id<=0 or id==999999 then return end
    return (id==100 or id==200) and 'Charge' or id==300 and 'Passive' or id==400 and 'Pet Skill' or id==600 and 'Kick' or 'Spell '..id,nil,'icon-'..id end
cooldowns={}; gcd={0,0,1}; now=10
function GetSpellCooldown(slot,book) if slot==61304 then return unpack(gcd) end; assert(book=='spell' or book=='pet'); return unpack(cooldowns[book..slot] or {0,0,1}) end
function IsUsableSpell() return true end
function IsSpellInRange() return 1 end
function GetInventoryItemID(_,slot) if slot==13 then return 500 end end
function GetItemInfo(id) if id==501 then return end; return 'Item '..id,nil,nil,nil,nil,nil,nil,nil,nil,'item-icon-'..id end
function GetItemIcon(id) if id~=501 then return 'item-icon-'..id end end
function GetInventoryItemCooldown() return 5,20,1 end
function GetItemCooldown() return 7,30,1 end
function GetItemCount() return 4 end
auras={player={HELPFUL={}},target={HARMFUL={}},focus={HELPFUL={}}}
function UnitAura(unit,i,filter) local a=auras[unit] and auras[unit][filter] and auras[unit][filter][i]; if a then return a.name,nil,a.icon,a.count,nil,a.duration,a.expires,a.caster,false,false,a.id end end
function GetActiveTalentGroup() return spec or 1 end
function GetNumTalentTabs() return 1 end
function GetNumTalents() return 1 end
talentRank=0; function GetTalentInfo() return 'Improved Charge',nil,nil,nil,talentRank end
function GetBindingKey(command) if command=='ACTIONBUTTON1' then return 'SHIFT-1' end end
function GetActionInfo(slot) if slot==1 then return 'spell',2,'spell',200 end end
function HasAction(slot) return slot==1 end
function GameTooltip:SetOwner(owner) self.owner=owner end
function GameTooltip:GetOwner() return self.owner end
function GameTooltip:SetSpell(slot,book) self.slot,self.book=slot,book end
function GameTooltip:AddLine(text) self.tooltipText=text end
function GameTooltip:SetUnitAura(unit,i,filter) self.unit,self.index,self.filter=unit,i,filter end
sounds={}; function PlaySound(s) sounds[#sounds+1]=s end
modules={}; function EllesmereUI:RegisterModule(name,cfg) modules[name]=cfg end
unlock={}; registrations=0
function EllesmereUI:RegisterUnlockElements(elements) registrations=registrations+1; for _,e in ipairs(elements) do unlock[e.key]=e end end
function EllesmereUI.MakeUnlockElement(c)
    return {key=c.key,label=c.label,group=c.group,order=c.order,getFrame=c.getFrame,getSize=c.getSize,savePosition=c.savePos,loadPosition=c.loadPos,
        clearPosition=c.clearPos,applyPosition=c.applyPos,isHidden=c.isHidden,noResize=c.noResize,noAnchorTarget=c.noAnchorTarget}
end
function EllesmereUI:RegisterUnlockModeListener(_,fn) unlockListener=fn end
function EllesmereUI:RegisterOnHide(fn) hideOptions=fn end
function EllesmereUI:InvalidatePageCache() end
function EllesmereUI:RefreshPage() refreshed=(refreshed or 0)+1 end
function EllesmereUI:ShowModule(folder) shownModule=folder end
function EllesmereUI.EnsureOptionsLoaded() end
function EllesmereUI.GetAccentColor() return .1,.8,.7 end
LibStub=function() error('External dependency') end
C_CooldownViewer=setmetatable({},{__index=function() error('Retail cooldown viewer') end})
''')
ns=lua.table()
for file in files:
    lua.execute(sources[file],'EllesmereUICooldownManager',ns)
lua.globals().D=ns
lua.execute('''
lifecycle:RunScript('OnEvent','ADDON_LOADED','EllesmereUICooldownManager')
assert(#lifecycleErrors==0,lifecycleErrors[1])
function IsLoggedIn() return true end
lifecycle:RunScript('OnEvent','PLAYER_LOGIN'); assert(#lifecycleErrors==0,lifecycleErrors[1])

-- Retail bar model: three seeded bars with Retail keys and type sizes.
local bars=D.Bars()
assert(#bars==3 and bars[1].barType=='cooldowns' and bars[3].barType=='buffs')
assert(D.Config('cooldowns').iconSize==42 and D.Config('utility').iconSize==36 and D.Config('buffs').iconSize==32)
assert(D.Config('cooldowns').barVisibility=='always' and D.Config('cooldowns').spellDefaults)

-- Every bar and tracking bar has a mover and an Element Options target.
local MAP=EllesmereUI._ELEMENT_SETTINGS_MAP
for _,k in ipairs({'cooldowns','utility','buffs'}) do
    local u=unlock['CDM_'..k]; assert(u and u.getFrame()==D.frames[k],k)
    local t=MAP['CDM_'..k]; assert(t and t.module=='EllesmereUICooldownManager' and t.page=='CDM Bars' and t.sectionName=='BAR LAYOUT' and t.highlightText=='Icon Size',k)
    t.preSelectFn(); assert(D.selectedBar==k)
end
for i=1,20 do assert(unlock['TBB_'..i] and MAP['TBB_'..i].page=='Tracking Bars' and MAP['TBB_'..i].sectionName=='BAR LAYOUT' and MAP['TBB_'..i].highlightText=='Width') end
for g=1,4 do assert(unlock['TBBG_'..g] and MAP['TBBG_'..g].sectionName=='GROUP SETTINGS' and MAP['TBBG_'..g].highlightText=='Grow Direction') end
MAP.TBB_2.preSelectFn(); assert(D.selectedTBB==2)
local regs=registrations; D.Apply(); D.Apply(); assert(registrations==regs,'unlock re-registered without changes')

-- Resolution: ranks, passives, pet book, items and equipment slots.
assert(D.Resolve({kind='spell',id=100}).slot==2)
assert(not D.Resolve({kind='spell',id=300}) and not D.Resolve({kind='spell',id=999999}))
assert(D.Resolve({kind='spell',id=400}).book=='pet')
assert(D.Resolve({kind='preset',id='healthstone'}).preset.key=='healthstone')

local lists=D.Lists()
lists.cooldowns={{kind='spell',id=100},{kind='spell',id=400}}
lists.utility={{kind='slot',id=13},{kind='item',id=500},{kind='item',id=501}}
lists.buffs={{kind='aura',id=700,unit='target',filter='HARMFUL',ownOnly=true}}
lists.tbb={{spellID=701,unit='player'},{spellID=702,trackType='aura',hideWhenInactive=true}}
auras.player.HELPFUL={{id=700,name='Spell 700',icon='wrong-unit',count=2,duration=10,expires=20,caster='player'},{id=701,name='Spell 701',icon='permanent',count=3,duration=0,expires=0,caster='other'}}
auras.target.HARMFUL={{id=700,name='Spell 700',icon='other-caster',count=1,duration=15,expires=25,caster='other'},{id=700,name='Spell 700',icon='correct',count=2,duration=12,expires=22,caster='player'}}
cooldowns.spell2={9,20,1}; D.Config('cooldowns').showTooltip=true; D.Apply()
assert(#D.compiled.utility==2 and D.compiled.cooldowns[1].remaining==19)
assert(D.compiled.buffs[1].aura.icon=='correct' and D.compiled.buffs[1].count==2)
assert(D.frames.buffs.pool[1].icon.texture=='correct' and D.frames.buffs.pool[1].count.text=='2')
assert(D.frames.cooldowns.pool[1].timer.text=='19' and D.frames.cooldowns.pool[1].cooldown.duration==20)
assert(D.frames.utility.pool[2].count.text=='4')

-- Tracking bars: permanent aura fills, stacks text, inactive bar hidden.
local tb=D.tbbFrames[1]; assert(tb and tb:IsShown() and tb.value==1 and tb.stacks.text=='3',tostring(tb and tb.value))
assert(not D.tbbFrames[2]:IsShown())
auras.player.HELPFUL[3]={id=702,name='Spell 702',icon='timed',count=1,duration=10,expires=15,caster='player'}
D.ScanAuras(); D.Update(); local t2=D.tbbFrames[2]
assert(t2:IsShown() and math.abs(t2.value-.5)<.001 and t2.timer.text=='5' and t2.fill.texcoords[2]==t2.value)
lists.tbb[2].reverseFill=true; D.Apply(); D.Update(); assert(t2.fill.texcoords[1]==.5 and t2.fill.point[1]=='BOTTOMRIGHT')
lists.tbb[2].stackBasedBar=true; lists.tbb[2].stackThresholdMax=4; D.Apply(); assert(D.tbbFrames[2].value==.25)
lists.tbb[2].stackBasedBar=false; lists.tbb[2].reverseFill=false
-- Pandemic glow on the last 30%: falls back to the edge pulse when Core glows are absent.
now=12.5; D.Update(); assert(t2.glow.edges and t2.glow.edges[1]:IsShown())
now=10; D.Update(); assert(not t2.glow.edges[1]:IsShown())
-- Groups: members chain under one mover.
lists.tbb[1].groupID=1; lists.tbb[2].groupID=1; D.Apply(); D.Update()
assert(D.tbbGroupFrames[1]:IsShown() and t2.point[2]==D.tbbFrames[1] and t2.point[1]=='TOP')
unlock.TBBG_1.savePosition(nil,'LEFT','LEFT',5,6); assert(D.Profile().positions.TBBG_1.x==5 and D.tbbGroupFrames[1].point[4]==5)
lists.tbb[1].groupID=0; lists.tbb[2].groupID=0; D.Apply()
unlock.TBB_1.savePosition(nil,'TOP','TOP',7,8); assert(D.tbbFrames[1].point[1]=='TOP' and D.Profile().positions.TBB_1.y==8)

-- Tooltip, GCD suppression, ready sound.
D.frames.cooldowns.pool[1]:RunScript('OnEnter'); assert(GameTooltip.slot==2 and GameTooltip.book=='spell')
D.frames.cooldowns.pool[1]:RunScript('OnLeave'); assert(not GameTooltip:IsShown())
gcd={9.5,1.5,1}; cooldowns.spell2={9.5,1.5,1}; D.Update(); assert(not D.compiled.cooldowns[1].onCD and D.compiled.cooldowns[1].remaining==1)
D.Config('cooldowns').suppressGCD=true; D.Update(); assert(D.compiled.cooldowns[1].remaining==0)
D.Config('cooldowns').suppressGCD=false; gcd={0,0,1}; cooldowns.spell2={9.6,1.6,1}; D.Update(); assert(D.compiled.cooldowns[1].onCD)
D.Profile().readySound=true; now=11.5; D.Update(); assert(#sounds==1); D.Update(); assert(#sounds==1); D.Profile().readySound=false

-- Cooldown states (Retail cdStateEffect) and glows.
cooldowns.spell2={10.5,20,1}; D.Config('cooldowns').spellDefaults.cdStateEffect='hiddenOnCDShift'; D.Update()
assert(D.frames.cooldowns.pool[2]:IsShown()==false and D.frames.cooldowns.pool[1].state.meta.book=='pet')
D.Config('cooldowns').spellDefaults.cdStateEffect='lowerAlphaOnCD'; D.Config('cooldowns').spellDefaults.cdStateLowerAlpha=.3; D.Update()
assert(D.frames.cooldowns.pool[1].alpha==.3)
cooldowns.spell2=nil; D.Config('cooldowns').spellDefaults.cdStateEffect='pixelGlowReady'; D.Update()
assert(D.frames.cooldowns.pool[1].glow.edges and D.frames.cooldowns.pool[1].glow.edges[1]:IsShown())
D.Profile().glowsOnlyInCombat=true; D.Update(); assert(not D.frames.cooldowns.pool[1].glow.edges[1]:IsShown()); D.Profile().glowsOnlyInCombat=false
D.Config('cooldowns').spellDefaults.cdStateEffect=nil
-- Talent conditions hide entries until the talent is taken.
lists.cooldowns[2].talentName='Improved Charge'; D.Apply(); assert(#D.compiled.cooldowns==1)
talentRank=1; D.Apply(); assert(#D.compiled.cooldowns==2); lists.cooldowns[2].talentName=nil

-- Overflow: extra icons move to another bar.
D.Config('cooldowns').maxIcons=1; D.Config('cooldowns').overflowTarget='utility'; D.Apply()
assert(D.frames.utility.pool[3]:IsShown() and not D.frames.cooldowns.pool[2]:IsShown())
D.Config('cooldowns').maxIcons=0; D.Config('cooldowns').overflowTarget=nil; D.Apply()

-- Custom and FocusKick bars get movers and Element Options; FocusKick targets its section.
local custom=D.AddBar('utility'); D.AddBar('focuskick'); D.Apply()
assert(unlock['CDM_'..custom.key] and MAP['CDM_'..custom.key].highlightText=='Icon Size')
assert(unlock.CDM_focuskick and MAP.CDM_focuskick.sectionName=='FOCUSKICK OPTIONS' and MAP.CDM_focuskick.highlightText=='Interrupt Spell')
D.Config('focuskick').focusKickInterruptSpellID=600; D.Apply(); assert(D.compiled.focuskick[1].meta.name=='Kick')
function UnitCanAttack() return true end; function UnitChannelInfo() end
local before=#sounds; nativeCast={'Fireball','Rank 1','Fireball','fire-icon',1000,4000,false,19,false}; D.Update()
assert(D.frames.focuskick:IsShown() and #sounds==before+1 and sounds[#sounds]=='RaidWarning' and D.frames.focuskick.reminder.text=='Interrupt: Fireball')
nativeCast={'Shield','Rank 1','Shield','icon',1000,4000,false,20,true}; D.Update(); assert(not D.frames.focuskick:IsShown())
nativeCast=nil; D.Update(); assert(not D.frames.focuskick:IsShown())
assert(D.RemoveBar(custom.key) and not D.RemoveBar('cooldowns'))

-- Anchoring to another bar.
D.Config('utility').anchorTo='cooldowns'; D.Config('utility').anchorPosition='bottom'; D.Apply()
assert(D.frames.utility.point[2]==D.frames.cooldowns and D.frames.utility.point[1]=='TOP')
assert(unlock.CDM_utility.isHidden()); D.Config('utility').anchorTo='none'; D.Apply()

-- No frames are created in combat; Bar Glow wrappers wait for combat to end.
D.OnEvent(nil,'PLAYER_REGEN_DISABLED'); combat=true
local frames=#allFrames; for i=1,20 do now=now+.1; D.Update() end; D.PrepareActionGlows(); assert(#allFrames==frames)
now=23; D.ScanAuras(); D.Update(); assert(not D.compiled.buffs[1].active and not D.frames.buffs:IsShown())
combat=false; D.OnEvent(nil,'PLAYER_REGEN_ENABLED')
unlockListener(true); assert(D.frames.buffs:IsShown() and D.tbbFrames[2]:IsShown()); unlockListener(false)
unlock.CDM_cooldowns.savePosition(nil,'BOTTOM','BOTTOM',12,34); D.Apply(); assert(D.frames.cooldowns:GetPoint()=='BOTTOM' and D.Profile().positions.cooldowns.y==34)
spec=2; D.Apply(); assert(D.Lists()~=lists); spec=1; D.Apply(); assert(D.Lists()==lists)

-- Bar Glows on action buttons, keybinds from the same buttons.
now=10
local abButton=CreateFrame('Button',nil,UIParent); abButton.config={keyBoundTarget='ACTIONBUTTON1'}; abButton.action=1
EllesmereUI._ModuleNS.EllesmereUIActionBars={bars={bar1={buttons={abButton}}}}
lists.barGlows={enabled=true,list={D.NewBarGlowRule(700,200)}}
lists.barGlows.list[1].unit='target'; lists.barGlows.list[1].filter='HARMFUL'
auras.target.HARMFUL[2].expires=30; D.Config('cooldowns').showKeybind=true; D.Apply(); D.Update()
assert(abButton._eui335CdmGlow and abButton._eui335CdmGlow.edges and abButton._eui335CdmGlow.edges[1]:IsShown())
assert(D.frames.cooldowns.pool[1].keybind.text=='S1',tostring(D.frames.cooldowns.pool[1].keybind.text))
lists.barGlows.list[1].mode='missing'; D.Update(); assert(not abButton._eui335CdmGlow.edges[1]:IsShown())
lists.barGlows.list[1].mode='active'; D.Profile().enabled=false; D.Apply(); assert(not abButton._eui335CdmGlow.edges[1]:IsShown() and not D.frames.cooldowns:IsShown())
D.Profile().enabled=true; D.Apply()

-- 0.1 profiles: indexed bars (defaults stripped) become Retail bars.
local old={cdmBars={enabled=true,bars={{iconSize=50,growDirection='UP'},{},{show='always'},{width=300}}},positions={tracking={point='TOP',x=1,y=2}}}
D.Migrate(old)
local b1=old.cdmBars.bars[1]
assert(#old.cdmBars.bars==3 and b1.barType=='cooldowns' and b1.iconSize==50 and b1.rowGrowDirection=='UP' and b1.growDirection=='RIGHT')
assert(old.cdmBars.bars[3].showInactiveBuffIcons==true and old.positions.TBB_1.y==2 and old.tbbLegacy.width==300)
local fresh={cdmBars={enabled=true}}; D.Migrate(fresh); assert(type(fresh.cdmBars.bars)=='table' and #fresh.cdmBars.bars==0)
-- Broken saves: a built-in key used twice, or Cooldowns saved with the Buffs type/name.
local dup={{key='utility',barType='buffs',name='Buffs'},{key='utility',barType='utility',name='Utility'},{key='buffs',barType='buffs',name='Buffs'},{key='custom_1',barType='buffs',name='Buffs'}}
D.RepairBuiltins(dup)
assert(dup[1].key=='cooldowns' and dup[1].barType=='cooldowns' and dup[1].name=='Cooldowns', 'duplicate utility -> cooldowns')
assert(dup[2].key=='utility' and dup[2].name=='Utility' and dup[3].key=='buffs' and dup[4].key=='custom_1' and dup[4].name=='Buffs')
local wrong={{key='cooldowns',barType='buffs',name='Buffs'},{key='utility',barType='utility',name='Utility'},{key='buffs',barType='buffs',name='Buffs'}}
D.RepairBuiltins(wrong); assert(wrong[1].barType=='cooldowns' and wrong[1].name=='Cooldowns' and wrong[3].name=='Buffs')
local twice={{key='buffs',barType='buffs',name='Buffs'},{key='cooldowns',barType='cooldowns',name='Cooldowns'},{key='buffs',barType='buffs',name='Buffs'}}
D.RepairBuiltins(twice); assert(twice[1].key=='utility' and twice[1].barType=='utility' and twice[1].name=='Utility' and twice[3].key=='buffs', 'one buffs -> utility')
local three={{key='buffs',barType='buffs',name='Buffs'},{key='cooldowns',barType='cooldowns',name='Cooldowns'},{key='utility',barType='utility',name='Utility'},{key='buffs',barType='buffs',name='Buffs'}}
D.RepairBuiltins(three); assert(three[1].key=='buffs' and three[4].key=='custom_1' and three[4].barType=='buffs', 'extra buffs -> custom')
local v1lists={cooldowns={},utility={},buffs={{kind='aura',id=700,highlightSpellID=200}},tracking={{kind='aura',id=701,unit='player'}}}
D.Profile().wrathSpecLists['TEST:1']=v1lists; local conv=D.ListsFor('TEST:1')
assert(conv.tbb[1].spellID==701 and conv.tbb[1].width==270 and conv.barGlows.list[1].spellID==200 and conv.tracking==nil)

-- Options widgets
rows={}; buttons={}; EllesmereUI.Widgets={}
function EllesmereUI.Widgets:DualRow(parent,y,a,b)
    -- The real widget calls cfg.disabled(); a tooltip string in that slot errors in game.
    for _,c in ipairs({a,b}) do
        assert(type(c)~='table' or c.disabled==nil or type(c.disabled)=='function',
            'disabled must be a function: '..tostring(c.text))
    end
    rows[#rows+1]=a; rows[#rows+1]=b; return {},40
end
function EllesmereUI.Widgets:SectionHeader(parent,text) rows[#rows+1]={type='section',text=text}; return {},30 end
function EllesmereUI.Widgets:WideButton(parent,text,y,fn) buttons[text]=fn; return {},30 end
function Find(text) for _,r in ipairs(rows) do if r.text==text then return r end end end
''')
lua.execute(sources['Options'])
lua.execute('''
local c=modules.EllesmereUICooldownManager; assert(c and #c.pages==3 and c.pages[1]=='CDM Bars' and c.pages[2]=='Bar Glows' and c.pages[3]=='Tracking Bars')
local MAP=EllesmereUI._ELEMENT_SETTINGS_MAP
D.selectedBar='cooldowns'
rows={}; c.buildPage('CDM Bars',UIParent,0)
for _,name in ipairs({'BAR LAYOUT','ICON DISPLAY','EXTRAS','ADDITIONAL BAR OFFSET','TRACKED SPELLS','ADD ENTRY'}) do assert(Find(name),name) end
assert(Find(MAP.CDM_cooldowns.highlightText))
Find('Icon Size').setValue(50); assert(D.Config('cooldowns').iconSize==50)
Find('Rows').setValue(2); assert(D.Config('cooldowns').numRows==2)
Find('Cooldown State').setValue('lowerAlphaOnCD'); assert(D.Config('cooldowns').spellDefaults.cdStateEffect=='lowerAlphaOnCD')
Find('Border Color').setValue(.1,.2,.3,.4); assert(D.Config('cooldowns').borderR==.1 and D.Config('cooldowns').borderA==.4)
Find('Entry Type').setValue('aura'); Find('Spell / Item ID').setValue('702'); buttons['Add Entry'](); assert(D.Lists().cooldowns[3].id==702)
rows={}; c.buildPage('CDM Bars',UIParent,0); Find('Aura Unit').setValue('focus'); Find('Aura Type').setValue('HARMFUL'); assert(D.Lists().cooldowns[3].unit=='focus')
buttons['Move Entry Up'](); assert(D.Lists().cooldowns[2].id==702); buttons['Remove Entry'](); assert(#D.Lists().cooldowns==2)
rows={}; c.buildPage('CDM Bars',UIParent,0)
Find('Edit Entry').setValue(1); rows={}; c.buildPage('CDM Bars',UIParent,0)
local cs; for _,r in ipairs(rows) do if r.text=='Cooldown State' then cs=r end end
assert(cs~=Find('Cooldown State') and cs.getValue()=='default')
cs.setValue('hiddenReady'); assert(D.Lists().cooldowns[1].cdStateEffect=='hiddenReady' and D.Config('cooldowns').spellDefaults.cdStateEffect=='lowerAlphaOnCD')
cs.setValue('default'); assert(D.Lists().cooldowns[1].cdStateEffect==nil)
Find('Talent Must Be').setValue('missing'); assert(D.Lists().cooldowns[1].talentTaken==false)
Find('Add Item Preset').setValue('runic_mana'); assert(D.Lists().cooldowns[3].kind=='preset')
Find('Add Buff Preset').setValue('bloodlust'); assert(D.Lists().cooldowns[4].preset=='bloodlust' and D.Lists().cooldowns[4].kind=='aura')
buttons['Copy This Bar to Other Talent Group'](); assert(#D.ListsFor(D.OtherSpecKey()).cooldowns==4)
-- Retail header: bar dropdown (select, add, rename, delete) and the icon row.
local header,confirm,input
local fm=getmetatable(UIParent).__index
for k,v in pairs({GetStringHeight=function() return 14 end,SetHighlightTexture=function() end,RegisterForClicks=function() end,
    SetDesaturated=function(self,d) self.desaturated=d end,SetTexCoord=function() end,EnableMouse=function() end,SetJustifyH=function() end,
    GetCenter=function() return 0,0 end,GetEffectiveScale=function() return 1 end,IsMouseOver=function() return false end}) do
    if not fm[k] then fm[k]=v end
end
if not strtrim then function strtrim(s) return (s:gsub('^%s+',''):gsub('%s+$','')) end end
function EllesmereUI:SetContentHeader(fn) header=fn end
function EllesmereUI:ShowConfirmPopup(o) confirm=o end
function EllesmereUI:ShowInputPopup(o) input=o end
rows={}; c.buildPage('CDM Bars',UIParent,0)
assert(header and c.getHeaderBuilder('CDM Bars')==header and c.getHeaderBuilder('Bar Glows')==nil)
assert(not Find('Select Bar') and not Find('New Bar Type') and Find('Show This Bar'))
local O=D.Options; local hdr=CreateFrame('Frame',nil,UIParent)
assert(header(hdr)>64 and #O.slots==#D.Lists().cooldowns+2 and O.slots[1].index==1 and O.slots[#O.slots].add=='buff')
O.slots[2]:RunScript('OnClick','LeftButton'); assert(O.entry==2)
local first=D.Lists().cooldowns[1]; O.MoveEntry(1,4); assert(D.Lists().cooldowns[3]==first and O.entry==3)
local n=#D.Lists().cooldowns; header(hdr); O.slots[1]:RunScript('OnClick','MiddleButton'); assert(#D.Lists().cooldowns==n-1)
-- 0.7: Retail add pickers under the '+' slots.
do
  local scroll=getmetatable(UIParent).__index
  for k,v in pairs({SetScrollChild=function(self,c) self.scrollChild=c end,SetVerticalScroll=function(self,v) self.vscroll=v end,
      GetVerticalScroll=function(self) return self.vscroll or 0 end,EnableMouseWheel=function() end}) do if not scroll[k] then scroll[k]=v end end
  local keepList,stubRefresh=D.Lists().cooldowns,EllesmereUI.RefreshPage
  function EllesmereUI:RefreshPage() rows={}; c.buildPage('CDM Bars',UIParent,0); header(hdr) end
  D.Lists().cooldowns={{kind='spell',id=100,enabled=true}}
  local function L() local l=D.Lists().cooldowns; return l[#l],#l end
  header(hdr); local main=O.slots[#O.slots-1]; assert(main.add=='main' and O.slots[#O.slots].add=='buff')
  main:RunScript('OnClick','LeftButton'); local p=O.picker
  assert(p and p:IsShown() and not p.buff and p.anchor==main and p.strata=='FULLSCREEN_DIALOG')
  for _,k in ipairs({'Custom Spell ID','Custom Item ID','Equipment Slot','Trinket Slot 1','Trinket Slot 2','Racial','Potions & Healthstone','Charge','Kick'}) do assert(p.items[k],'main picker: '..k) end
  assert(not p.items.Passive and not p.items['Bloodlust / Heroism'])
  assert(p.items.Charge.used and not p.items.Charge:GetScript('OnClick'),'spell already on the bar is disabled')
  main:RunScript('OnClick','LeftButton'); assert(not p:IsShown(),'second click closes')
  main:RunScript('OnClick','LeftButton'); p=O.picker
  p.items.Kick:RunScript('OnClick'); local e=L(); assert(e.kind=='spell' and e.id==600)
  assert(O.picker~=p and O.picker:IsShown() and O.picker.anchor==O.slots[#O.slots-1] and O.picker.anchor~=main,'picker reopens on the rebuilt +')
  assert(O.picker.items.Kick.used,'added spell greys out')
  p=O.picker; p.items['Trinket Slot 1']:RunScript('OnClick'); e=L(); assert(e.kind=='slot' and e.id==13 and not p:IsShown())
  O.slots[#O.slots-1]:RunScript('OnClick','LeftButton'); p=O.picker; assert(p.items['Trinket Slot 1'].used)
  p.items['Potions & Healthstone']:RunScript('OnClick'); assert(p.sub and p.items.Healthstone and p.items['Runic Mana Potion'])
  p.items.Healthstone:RunScript('OnClick'); e=L(); assert(e.kind=='preset' and e.id=='healthstone')
  O.slots[#O.slots-1]:RunScript('OnClick','LeftButton'); O.picker.items.Racial:RunScript('OnClick'); e=L(); assert(e.kind=='spell' and e.id==59752)
  O.slots[#O.slots-1]:RunScript('OnClick','LeftButton'); assert(O.picker.items.Racial.used)
  O.picker.items['Custom Spell ID']:RunScript('OnClick'); assert(input.title=='Custom Spell ID' and not O.picker:IsShown())
  input.onConfirm(' 702 '); e=L(); assert(e.kind=='spell' and e.id==702)
  O.slots[#O.slots-1]:RunScript('OnClick','LeftButton'); O.picker.items['Custom Item ID']:RunScript('OnClick'); input.onConfirm('500'); e=L(); assert(e.kind=='item' and e.id==500)
  O.slots[#O.slots-1]:RunScript('OnClick','LeftButton'); O.picker.items['Equipment Slot']:RunScript('OnClick'); input.onConfirm('5'); e=L(); assert(e.kind=='slot' and e.id==5)
  -- Gold '+': buff picker adds auras and buff presets.
  local gold=O.slots[#O.slots]; gold:RunScript('OnClick','LeftButton'); p=O.picker
  assert(p.buff and p.anchor==gold and p.items['Custom Spell ID'] and p.items['Bloodlust / Heroism'] and p.items.Charge and p.items['Spell 46916'])
  assert(not p.items['Custom Item ID'] and not p.items['Trinket Slot 1'] and not p.items.Charge.used,'aura Charge is not on the bar yet')
  p.items.Charge:RunScript('OnClick'); e=L(); assert(e.kind=='aura' and e.id==200 and e.filter=='HELPFUL')
  assert(O.picker.buff and O.picker.anchor==O.slots[#O.slots] and O.picker.items.Charge.used)
  O.picker.items['Bloodlust / Heroism']:RunScript('OnClick'); e=L(); assert(e.kind=='aura' and e.preset=='bloodlust')
  assert(O.picker.items['Bloodlust / Heroism'].used)
  O.picker.items['Custom Spell ID']:RunScript('OnClick'); input.onConfirm('701'); e=L(); assert(e.kind=='aura' and e.id==701)
  -- Long lists scroll with the wheel; a click outside closes.
  local maxH=O.PICK_MAX_H; O.PICK_MAX_H=100
  O.slots[#O.slots-1]:RunScript('OnClick','LeftButton'); p=O.picker; assert(p.height==100)
  assert(p.items['Custom Spell ID']:IsShown() and not p.items.Kick:IsShown(), 'rows outside the view are hidden')
  p:RunScript('OnMouseWheel',-1); assert(p.offset==40 and not p.items['Custom Spell ID']:IsShown(), 'wheel scrolls the rows')
  O.PICK_MAX_H=maxH
  local oldDown=IsMouseButtonDown; function IsMouseButtonDown() return true end; p:RunScript('OnUpdate',.1); assert(not p:IsShown()); IsMouseButtonDown=oldDown
  D.selectedBar='utility'; header(hdr); O.slots[#O.slots]:RunScript('OnClick','LeftButton')
  assert(O.picker.buff and D.selectedBar=='utility' and O.Bar().key=='utility','gold + keeps Utility selected'); O.picker:Hide()
  -- A Buffs bar's single '+' opens the buff picker; the cap stays at 40.
  D.selectedBar='buffs'; header(hdr); assert(O.slots[#O.slots].add=='main')
  O.slots[#O.slots]:RunScript('OnClick','LeftButton'); assert(O.picker.buff and O.picker.items['Bloodlust / Heroism'])
  O.picker:Hide(); D.selectedBar='cooldowns'
  local full={}; for i=1,40 do full[i]={kind='spell',id=100} end; D.Lists().cooldowns=full; header(hdr)
  O.slots[#O.slots-1]:RunScript('OnClick','LeftButton'); O.picker.items['Trinket Slot 2']:RunScript('OnClick'); assert(#D.Lists().cooldowns==40)
  if O.picker then O.picker:Hide() end
  EllesmereUI.RefreshPage=stubRefresh; D.Lists().cooldowns=keepList; D.Apply(); header(hdr)
end
-- Spec Overrides read-trace swaps db.profile for proxies (# and ipairs see them empty).
do
  local unwrap=setmetatable({}, {__mode='k'})
  local function Proxy(real)
    local p=setmetatable({}, {__index=function(_,k) local v=real[k]; if type(v)=='table' then return Proxy(v) end; return v end,
      __newindex=function(_,k,v) real[k]=unwrap[v] or v end})
    unwrap[p]=real; return p
  end
  local db=D.addon.db; local real=db.profile; local before={}
  for i,b in ipairs(real.cdmBars.bars) do before[i]=b.key end
  D.selectedBar='utility'; db.profile=Proxy(real)
  local ok,err=pcall(function() assert(O.Bar().key=='utility' and #D.Bars()==#before) end)
  db.profile=real; assert(ok, err)
  assert(D.selectedBar=='utility', 'trace keeps Utility selected')
  for i,k in ipairs(before) do assert(real.cdmBars.bars[i].key==k, 'trace must not reseed bars') end
  assert(#real.cdmBars.bars==#before, 'bars '..#real.cdmBars.bars..' vs '..#before)
  D.selectedBar='cooldowns'
end
O.dropdown:RunScript('OnClick'); local m=O.menu
assert(m.items.Cooldowns and not m.items.Cooldowns.del and m.items['+ Add New Buff Bar'] and m.items.FocusKick and not m.items['+ Add FocusKick Bar'])
m.items.FocusKick.edit:RunScript('OnClick'); input.onConfirm('  Kicks  '); assert(D.BarByKey('focuskick').name=='Kicks')
O.dropdown:RunScript('OnClick'); O.menu.items.Kicks.del:RunScript('OnClick'); confirm.onConfirm()
assert(not D.BarByKey('focuskick') and D.selectedBar=='cooldowns')
O.dropdown:RunScript('OnClick'); O.menu.items['+ Add FocusKick Bar']:RunScript('OnClick'); assert(D.selectedBar=='focuskick')
rows={}; c.buildPage('CDM Bars',UIParent,0); assert(Find('FOCUSKICK OPTIONS') and Find(MAP.CDM_focuskick.highlightText))
Find('Interrupt Spell').setValue('600'); assert(D.Config('focuskick').focusKickInterruptSpellID==600)
header(hdr); assert(#O.slots==1 and not O.slots[1].index)
D.RemoveBar('focuskick'); D.selectedBar='cooldowns'
O.dropdown:RunScript('OnClick'); O.menu.items['+ Add New Utility Bar']:RunScript('OnClick')
local added=D.BarByKey(D.selectedBar); assert(added.barType=='utility' and not D.IsBuffBar(added))
O.SelectBar('utility'); rows={}; c.buildPage('CDM Bars',UIParent,0); header(hdr)
local cx,cy=0,0; function GetCursorPosition() return cx,cy end
local stubRefresh=EllesmereUI.RefreshPage
function EllesmereUI:RefreshPage() rows={}; c.buildPage('CDM Bars',UIParent,0); header(hdr) end
O.slots[1]:RunScript('OnMouseDown','LeftButton'); O.slots[1]:RunScript('OnMouseUp','LeftButton'); O.slots[1]:RunScript('OnClick','LeftButton')
assert(D.selectedBar=='utility','after rebuild: '..tostring(D.selectedBar))
EllesmereUI.RefreshPage=stubRefresh
assert(D.selectedBar=='utility',tostring(D.selectedBar))
rows={}; c.buildPage('CDM Bars',UIParent,0); header(hdr); assert(D.selectedBar=='utility',tostring(D.selectedBar))
O.slots[1]:RunScript('OnMouseDown','LeftButton'); cx=10; O.slots[1]:RunScript('OnUpdate'); O.slots[1]:RunScript('OnMouseUp','LeftButton')
assert(D.selectedBar=='utility',tostring(D.selectedBar))
D.RemoveBar(added.key); D.selectedBar='cooldowns'
rows={}; c.buildPage('CDM Bars',UIParent,0)
Find('Preview').setValue(true); assert(D.preview); hideOptions(); assert(not D.preview)

rows={}; c.buildPage('Tracking Bars',UIParent,0)
D.selectedTBB=1; rows={}; c.buildPage('Tracking Bars',UIParent,0)
for _,name in ipairs({'BAR LAYOUT','TRACKING','TEXT','STACKS','PANDEMIC GLOW','GROUP SETTINGS'}) do assert(Find(name),name) end
assert(Find(MAP.TBB_1.highlightText))
Find('Width').setValue(350); assert(D.Lists().tbb[1].width==350 and D.tbbFrames[1].width==350)
Find('Group').setValue(2); rows={}; c.buildPage('Tracking Bars',UIParent,0)
Find(MAP.TBBG_2.highlightText).setValue('RIGHT'); assert(D.Profile().tbbGroups[2].growDirection=='RIGHT')
local n=#D.Lists().tbb; buttons['Add Tracking Bar'](); assert(#D.Lists().tbb==n+1 and D.selectedTBB==n+1)
buttons['Remove Selected Bar'](); assert(#D.Lists().tbb==n)

rows={}; c.buildPage('Bar Glows',UIParent,0); assert(Find('BAR GLOWS') and Find('Enable Bar Glows'))
buttons['Add Glow'](); rows={}; c.buildPage('Bar Glows',UIParent,0)
Find('Aura Spell ID').setValue('701'); Find('Glow When').setValue('missing'); local g=D.Lists().barGlows.list[#D.Lists().barGlows.list]
assert(g.auraID==701 and g.mode=='missing')
Find('Glow Color').setValue(.2,.3,.4); assert(g.glowR==.2)
buttons['Remove Glow'](); assert(D.Lists().barGlows.list[#D.Lists().barGlows.list]~=g)
SlashCmdList.EUI335CDM(''); assert(shownModule=='EllesmereUICooldownManager')
shownModule=nil; SlashCmdList.EUI335CDM('debug')
assert(shownModule=='EllesmereUICooldownManager' and rawget(D,'_dbg')==nil and rawget(D,'_selLog')==nil,'/ecdm debug is gone')
c.onReset(); assert(#D.Bars()==3 and D.Config('cooldowns').iconSize==42)
assert(#lifecycleErrors==0,lifecycleErrors[1])
''')
# 0.5: racial variants (three Arcane Torrents) and passive proc trinkets with internal cooldowns.
lua.execute('''
local c=modules.EllesmereUICooldownManager; local O=D.Options
local oldInfo,oldRace=GetSpellInfo,UnitRace
function GetSpellInfo(id) id=tonumber(id); if id==28730 or id==25046 or id==50613 then return 'Arcane Torrent',nil,'icon-at' end; return oldInfo(id) end
function UnitRace() return 'Blood Elf','BloodElf' end
local n=0; for _,e in ipairs(D.SeedLists('PALADIN').utility) do if D.RACIAL_GROUP[e.id] then n=n+1 end end
assert(n==1,'one racial seed per race: '..n)
function UnitRace() return 'Unknown','Unknown' end
local groups={}; for _,e in ipairs(D.SeedLists('PALADIN').utility) do local g=D.RACIAL_GROUP[e.id]; if g then assert(not groups[g],'duplicate racial group'); groups[g]=true end end
UnitRace=oldRace
D.Profile().wrathSpecLists['RACE:1']={utility={{kind='spell',id=28730,enabled=false},{kind='spell',id=100},{kind='spell',id=25046},{kind='spell',id=50613},{kind='aura',id=25046}},
    cooldowns={},buffs={}}
local saved=D.ListsFor('RACE:1').utility
assert(#saved==3 and saved[1].id==28730 and saved[1].enabled==true and saved[2].id==100 and saved[3].kind=='aura','saved racial variants collapse')
spells[5]={id=28730,name='Arcane Torrent'}
local lists=D.Lists(); local keepUtility=lists.utility
lists.utility={{kind='spell',id=28730},{kind='spell',id=25046},{kind='spell',id=50613},{kind='spell',id=100}}
D.Apply(); assert(#D.compiled.utility==2 and D.compiled.utility[1].meta.name=='Arcane Torrent' and D.compiled.utility[2].meta.name=='Charge')
rows={}; c.buildPage('CDM Bars',UIParent,0)
local at=0; for _,r in ipairs(rows) do if r.text=='Add Racial' then for _,v in pairs(r.values) do if v=='Arcane Torrent' then at=at+1 end end end end
assert(at==1,'Add Racial lists Arcane Torrent once: '..at)
spells[5]=nil; GetSpellInfo=oldInfo

-- Trinkets: on-use slot uses the item cooldown, a passive proc trinket shows its icon and internal cooldown.
local oldID,oldCD,oldSpell=GetInventoryItemID,GetInventoryItemCooldown,GetItemSpell
equipped={[13]=500,[14]=27683}
function GetInventoryItemID(_,slot) return equipped[slot] end
function GetInventoryItemCooldown(_,slot) if slot==13 then return 5,20,1 end; return 0,0,0 end
function GetItemSpell(id) if id==500 then return 'Use Trinket' end end
D.Config('utility').showPassiveTrinkets=false
lists.utility={{kind='slot',id=13},{kind='slot',id=14}}
now=40; D.Apply()
local st=D.compiled.utility[2]
assert(#D.compiled.utility==2 and D.compiled.utility[1].meta.useSpell=='Use Trinket' and not D.compiled.utility[1].meta.procs)
assert(st.meta.procs and st.meta.procs.icd==45 and st.icon=='item-icon-27683' and not st.onCD)
assert(D.events.events.COMBAT_LOG_EVENT_UNFILTERED,'combat log registered while a proc trinket is tracked')
local frames=#allFrames
D.OnEvent(nil,'COMBAT_LOG_EVENT_UNFILTERED',1,'SPELL_DAMAGE','other','X',0,'target','T',0,33370); assert(not st.onCD,'other players do not start the ICD')
now=50; D.OnEvent(nil,'COMBAT_LOG_EVENT_UNFILTERED',1,'SPELL_AURA_APPLIED','player','Me',0,'player','Me',0,33370)
assert(st.onCD and st.remaining==45 and st.duration==45)
auras.player.HELPFUL={{id=33370,name='Spell 33370',icon='proc',count=0,duration=10,expires=60,caster='player'}}
D.ScanAuras(); D.Update(); assert(st.activeAura and st.activeAura.expires==60,'proc buff shows while active')
now=70; auras.player.HELPFUL={}; D.ScanAuras(); D.Update(); assert(st.onCD and st.remaining==25 and not st.activeAura)
assert(D.frames.utility.pool[2].timer.text=='25')
now=96; D.Update(); assert(not st.onCD)
auras.player.HELPFUL={{id=33370,name='Spell 33370',icon='proc',count=0,duration=10,expires=104,caster='player'}}
D.ScanAuras(); D.Update(); assert(st.start==94 and math.abs(st.remaining-43)<.001,'aura start after /reload')
assert(#allFrames==frames,'no frames created by ICD updates')
auras.player.HELPFUL={}
-- No-cooldown procs show the trinket without a timer; unknown passives stay hidden unless enabled.
equipped[14]=40432; D.Apply(); st=D.compiled.utility[2]
assert(st.meta.procs.nocd and not st.onCD and st.remaining==0 and not D.events.events.COMBAT_LOG_EVENT_UNFILTERED)
equipped[14]=502; D.Apply(); assert(#D.compiled.utility==1)
O.SelectBar('utility'); rows={}; c.buildPage('CDM Bars',UIParent,0)
local hdr=CreateFrame('Frame',nil,UIParent); c.getHeaderBuilder('CDM Bars')(hdr)
assert(O.slots[2].icon.texture=='bag-icon:14' and O.slots[2].icon.desaturated,'hidden passive trinket shows its icon, not ?')
D.Config('utility').showPassiveTrinkets=true; D.Apply(); assert(#D.compiled.utility==2 and D.compiled.utility[2].icon=='item-icon-502')
GetInventoryItemID,GetInventoryItemCooldown,GetItemSpell=oldID,oldCD,oldSpell
lists.utility=keepUtility; D.Config('utility').showPassiveTrinkets=false; D.Apply()
assert(#lifecycleErrors==0,lifecycleErrors[1])
''')
panel=(root/'EllesmereUI/EllesmereUI_Panel.lua').read_text(encoding='utf-8-sig')
helper=panel.split('function EllesmereUI.GetCombinedAddonMemoryUsage()',1)[1].split('\nend',1)[0]
lua.execute('''
memoryUpdated=0; function UpdateAddOnMemoryUsage() memoryUpdated=memoryUpdated+1 end
function GetNumAddOns() return 5 end
function GetAddOnInfo(i) return ({'EllesmereUI','EllesmereUIOptions','EllesmereUICooldownManager','OtherAddon','EllesmereUIDisabled'})[i] end
function GetAddOnMemoryUsage(i) return ({1024,512,256,9999,9999})[i] end
IsAddonLoaded=function(name) return name~='EllesmereUIDisabled' end
''')
lua.execute('function EllesmereUI.GetCombinedAddonMemoryUsage()'+helper+'\nend')
lua.execute('assert(EllesmereUI.GetCombinedAddonMemoryUsage()==1792 and memoryUpdated==1); GetAddOnMemoryUsage=nil; assert(EllesmereUI.GetCombinedAddonMemoryUsage()==nil)')
assert 'resCpuLabel:SetText("Memory Usage:")' in panel and 'memory / 1024' in panel
original=Path('D:/World of Warcraft/_retail_/Interface/AddOns/EllesmereUICooldownManager')
for p in original.rglob('*.lua'):
    assert p.read_bytes()==(module/p.name).read_bytes(),p
print('PASS: cooldown manager 0.2 - Retail bar model and 0.1 migration, CDM/TBB/group movers with Element Options targets, '
      'spell/item/aura/preset resolution, timers/GCD/stacks/states/glows/talent conditions/overflow/anchors/FocusKick, '
      'tracking bars (fill, reverse, stacks, pandemic, groups), bar glows and keybinds, options pages, one entry per racial, '
      'passive trinket icons and internal cooldowns, Retail add/buff picker menus, no combat frame '
      'allocation, Lua 5.1 compile, combined EUI memory, unchanged Retail references.')
