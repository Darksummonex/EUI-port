"""Native header name ordering, DPS icon visibility, independent aura indicators."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
lua=LuaRuntime()
# Same load order as the shipped TOCs: Core aura filters + indicator model, the
# options builders, then every Lua file listed in the RaidFrames TOC.
for name in ['backport-tools/wrath_mock.lua','backport-tools/inventory_resources_mock.lua','backport-tools/raidframes_mock.lua','EllesmereUI/EllesmereUI_Lite.lua','EllesmereUI/EUI_AuraFilters_335.lua','EllesmereUI/EUI_AuraIndicators_335.lua','EllesmereUIOptions/EUI_AuraFilters_335_Options.lua','EllesmereUIOptions/EUI_AuraIndicators_335_Options.lua']:
    lua.execute((root/name).read_text(encoding='utf-8-sig'))
ns=lua.table(); lua.globals().R=ns
toc=(root/'EllesmereUIRaidFrames/EllesmereUIRaidFrames.toc').read_text(encoding='utf-8-sig')
# Bundled Libs (LibHealComm/LibResComm/ChatThrottleLib) are compiled by
# validate_unitframes.py; the module itself treats them as optional.
toc_lua=[l.strip() for l in toc.splitlines() if l.strip().startswith('EUI_') and l.strip().endswith('.lua')]
assert toc_lua[0]=='EUI_RaidFrames_335_Indicators.lua' and 'EUI_RaidFrames_335_Display.lua' in toc_lua, toc_lua
for name in toc_lua:
    lua.execute((root/'EllesmereUIRaidFrames'/name).read_text(encoding='utf-8-sig'),'EllesmereUIRaidFrames',ns)
lua.execute('''
R.addon:OnInitialize(); R.addon:OnEnable()
local p=R.GetSettings(); assert(p.party.sortMethod=='ROLE')
units.player.role='DAMAGER'
units.party1={name='Dps',guid='D',class='MAGE',health=100,maxHealth=100,role='DAMAGER'}
units.party2={name='Healer',guid='H',class='PRIEST',health=100,maxHealth=100,role='HEALER',
 buffs={{name='Other',id=17,caster='party1',duration=10,expires=12,stacks=3},{name='Own',id=139,caster='player',duration=10,expires=12,stacks=2}}}
units.party3={name='Tank',guid='T',class='WARRIOR',health=100,maxHealth=100,role='TANK'}
partyCount=3; R.events:RunScript('OnEvent','PARTY_MEMBERS_CHANGED')
local h=R.headers.party[1]; local buttons=h.nativeButtons
assert(h:GetAttribute('nameList')=='Tank,Healer,Player,Dps' and not h:GetAttribute('groupFilter'))
assert(buttons[1]:GetAttribute('unit')=='party3' and buttons[2]:GetAttribute('unit')=='party2' and buttons[3]:GetAttribute('unit')=='player')
p.party.hideDpsRoleIcons=true; R.Apply()
assert(buttons[1].role:IsShown() and buttons[2].role:IsShown() and not buttons[3].role:IsShown() and buttons[3]:IsShown())
units.party1.role='TANK'; R.events:RunScript('OnUpdate',1)
assert(buttons[1]:GetAttribute('unit')=='party1' and buttons[2]:GetAttribute('unit')=='party3')
local before=h:GetAttribute('nameList'); combat=true; units.party1.role='DAMAGER'; R.events:RunScript('OnUpdate',1)
assert(h:GetAttribute('nameList')==before)
combat=false; R.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); assert(buttons[1]:GetAttribute('unit')=='party3')
local old=UnitGroupRolesAssigned; function UnitGroupRolesAssigned(unit) return units[unit] and units[unit].role or 'NONE' end
assert(R.UnitRole('party3')=='tank' and R.UnitRole('party2')=='healer' and R.UnitRole('party1')=='dps'); UnitGroupRolesAssigned=old
p.party.buffFilterMode='all'; p.party.buffIndicators={
 {name='Own',enabled=true,position='TOPLEFT',growth='RIGHT',maxIcons=1,ownOnly=true,showIn='party',durationSwipe=false,durationText=false,showStacks=false,opacity=.5,size=12,border=0},
 {name='Shield',enabled=true,position='BOTTOMRIGHT',growth='LEFT',maxIcons=2,filter='tracked',spells={[17]=true},customOrder=true,spellOrder={17},showStacks=true}}
R.Apply(); local healer=buttons[2]
assert(healer:GetAttribute('unit')=='party2')
assert(healer.buffs[1].spellID==139 and healer.buffs[2].spellID==17 and not healer.buffs[3]:IsShown())
assert(select(1,healer.buffs[1]:GetPoint())=='TOPLEFT' and healer.buffs[1]:GetAlpha()==.5)
assert(not healer.buffs[1].cooldown:IsShown() and healer.buffs[1].count:GetText()=='' and healer.buffs[1].time:GetText()=='')
assert(healer.buffs[2].count:GetText()=='3' and healer.buffs[2].cooldown:IsShown())
p.party.buffIndicators[1].showIn='raid'; R.Apply(); assert(not healer.buffs[1]:IsShown() and healer.buffs[2]:IsShown())
p.party.buffIndicators[1].showIn='party'; p.party.buffIndicators[1].enabled=false; R.Apply(); assert(not healer.buffs[1]:IsShown())
for i=1,4 do units['raid'..i]={name='Raid '..i,guid='R'..i,class='PRIEST',health=100,maxHealth=100,group=i==4 and 2 or 1,role=i==1 and 'DAMAGER' or i==2 and 'HEALER' or 'TANK'} end
raidCount=4; R.Apply()
assert(R.headers.raid[1]:GetAttribute('nameList')=='Raid 3,Raid 2,Raid 1' and R.headers.raid[2]:GetAttribute('nameList')=='Raid 4')
assert(R.headers.raid[1].nativeButtons[1]:GetAttribute('unit')=='raid3')
''')
lua.execute('''
EllesmereUI.BuildDropdownControl=EllesmereUI.BuildDropdownControl or function(parent,_,_,values,order,get,set)
    local b=CreateFrame('Button',nil,parent); b.values,b.order,b.get,b.set=values,order,get,set; return b,b:CreateFontString(nil,'OVERLAY')
end
''')
lua.execute((root/'EllesmereUIOptions/EUI_RaidFrames_335_Options.lua').read_text(encoding='utf-8-sig'))
lua.execute('''
allFrames[#allFrames]:RunScript('OnEvent','PLAYER_LOGIN')
local m=getmetatable(UIParent).__index
m.EnableKeyboard=m.EnableKeyboard or function(self,v) self.keyboard=v end
m.SetShown=m.SetShown or function(self,v) if v then self:Show() else self:Hide() end end
-- The Retail-style Buffs/Debuffs editor installs when the options addon loads
-- (EUI_RaidFrames_335_Indicators.lua); fire that event like the client does.
local waiters={}; for _,f in ipairs(allFrames) do if f.events and f.events.ADDON_LOADED then waiters[#waiters+1]=f end end
for _,f in ipairs(waiters) do f:RunScript('OnEvent','ADDON_LOADED','EllesmereUIOptions') end
assert(EllesmereUI._rfIndicatorUI,'Raid Frames indicator editor not installed')
local cfg=modules.EllesmereUIRaidFrames
local function Find(text) for _,field in ipairs(rows) do if field.text==text then return field end end; error(text) end
rows={}; cfg.buildPage('Party',UIParent,0); assert(Find('Member Sorting').values.ROLE); Find('Hide DPS Role Icons').setValue(true); assert(R.GetSettings('party').hideDpsRoleIcons)
rows={}; cfg.buildPage('Buffs',UIParent,0); Find('Select Group').setValue('party')
assert(cfg.getHeaderBuilder('Buffs')(UIParent,900)==292)
local v=EllesmereUI.WrathAuraIndicatorViewsRF.EllesmereUIRaidFramesbuff
rows={}; cfg.buildPage('Buffs',UIParent,0); assert(Find('Indicator Filter') and Find('Position') and Find('Show Stacks'))
local function Count() return #R.AuraIndicators(R.GetSettings('party'),'buff') end
local before=Count(); assert(v.items[before]:IsShown() and not v.items[before+1]:IsShown())
v.add:RunScript('OnClick'); assert(v.addMenu:IsShown() and v.addMenu.buttons[4]:IsShown())
v.addMenu.buttons[1]:RunScript('OnClick'); assert(Count()==before+1 and R.selectedbuffIndicator==before+1)
rows={}; cfg.buildPage('Buffs',UIParent,0); Find('Extra Spell IDs').setValue('139, 17'); Find('Position').setValue('TOPRIGHT'); Find('Duration Text').setValue(false)
local d=R.GetSettings('party').buffIndicators[before+1]; assert(d.spells[139] and d.spellOrder[1]==139 and d.position=='TOPRIGHT' and not d.durationText)
v.items[1]:RunScript('OnClick'); assert(R.selectedbuffIndicator==1)
local wasOn=R.GetSettings('party').buffIndicators[1].enabled~=false
v.items[1].switch:RunScript('OnClick'); assert((R.GetSettings('party').buffIndicators[1].enabled~=false)==not wasOn)
v.items[1].switch:RunScript('OnClick'); assert((R.GetSettings('party').buffIndicators[1].enabled~=false)==wasOn)
v.items[before+1].del:RunScript('OnClick'); assert(Count()==before and R.GetSettings('party').buffIndicators[before+1]==nil)
rows={}; cfg.buildPage('Debuffs',UIParent,0)
assert(Find('Indicator Filter').values.own and Find('Hide Sated / Exhaustion') and not pcall(Find,'Color Frame by Debuff Type'))
rows={}; cfg.buildPage('Party',UIParent,0)
Find('Dispel Overlay').setValue('gradient'); assert(R.GetSettings('party').dispelOverlay=='gradient' and R.GetSettings('raid').dispelOverlay=='fill')
Find('Dispel Colors').swatches[2].setValue(.1,.2,.3,1); assert(R.GetSettings('party').dispelColorCurse.g==.2)
rows={}; cfg.buildPage('Debuffs',UIParent,0)
local dv=(cfg.getHeaderBuilder('Debuffs')(UIParent,900) and EllesmereUI.WrathAuraIndicatorViewsRF.EllesmereUIRaidFramesdebuff)
dv.add:RunScript('OnClick'); assert(dv.addMenu.buttons[1]:IsShown() and not dv.addMenu.buttons[2])
assert(not R.GetSettings('party').debuffIndicators[1].spells)
''')
print('PASS: role ordering per raid subgroup/party, Boolean/string roles, DPS icons only, role changes and combat deferral; independent multi-indicator buffs/debuffs, filtering/position/opacity/stacks/swipe/time; Retail-style editor cards, Add New presets, toggle/delete and dispel colour options.')
