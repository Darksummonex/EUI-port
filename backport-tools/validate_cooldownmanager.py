"""Native Wrath cooldown/aura/items, actual Lite lifecycle, settings and memory."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
lua=LuaRuntime()
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
spells={{id=100,name='Charge'},{id=200,name='Charge'},{id=300,name='Passive',passive=true}}
function GetSpellName(slot,book) local s=(book=='pet' and {{id=400,name='Pet Skill'}} or spells)[slot]; if s then return s.name,'Rank '..slot end end
function GetSpellLink(slot,book) local name=GetSpellName(slot,book); if name then return 'spell:'..(book=='pet' and 400 or spells[slot].id) end end
function GetSpellTexture(slot,book) return 'icon-'..slot..book end
function IsPassiveSpell(slot,book) return book~='pet' and spells[slot].passive end
function HasPetSpells() return 1 end
function GetSpellInfo(id) if id==999999 then return end; return (id==100 or id==200) and 'Charge' or id==300 and 'Passive' or id==400 and 'Pet Skill' or 'Spell '..id,nil,'icon-'..id end
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
function GetBindingKey(command) if command=='ACTIONBUTTON1' then return '1' end end
function GameTooltip:SetOwner(owner) self.owner=owner end
function GameTooltip:GetOwner() return self.owner end
function GameTooltip:SetSpell(slot,book) self.slot,self.book=slot,book end
function GameTooltip:AddLine(text) self.tooltipText=text end
function GameTooltip:SetUnitAura(unit,i,filter) self.unit,self.index,self.filter=unit,i,filter end
sounds=0; function PlaySound() sounds=sounds+1 end
modules={}; function EllesmereUI:RegisterModule(name,cfg) modules[name]=cfg end
unlock={}; function EllesmereUI:RegisterUnlockElements(elements) for _,e in ipairs(elements) do unlock[e.key]=e end end
function EllesmereUI.MakeUnlockElement(c) c.savePosition=c.savePos; return c end
function EllesmereUI:RegisterUnlockModeListener(_,fn) unlockListener=fn end
function EllesmereUI:RegisterOnHide(fn) hideOptions=fn end
function EllesmereUI:InvalidatePageCache() end
function EllesmereUI:RefreshPage() end
function EllesmereUI:ShowModule(folder) shownModule=folder end
function EllesmereUI.EnsureOptionsLoaded() end
function EllesmereUI.GetAccentColor() return .1,.8,.7 end
LibStub=function() error('External dependency') end
C_CooldownViewer=setmetatable({},{__index=function() error('Retail cooldown viewer') end})
''')
ns=lua.table()
for file in ['EUI_CooldownManager_335_Catalog.lua','EUI_CooldownManager_335.lua','EUI_CooldownManager_335_Display.lua']:
    lua.execute((root/'EllesmereUICooldownManager'/file).read_text(encoding='utf-8-sig'),'EllesmereUICooldownManager',ns)
lua.globals().D=ns
lua.execute('''
lifecycle:RunScript('OnEvent','ADDON_LOADED','EllesmereUICooldownManager')
assert(#lifecycleErrors==0,lifecycleErrors[1])
function IsLoggedIn() return true end
lifecycle:RunScript('OnEvent','PLAYER_LOGIN'); assert(#lifecycleErrors==0,lifecycleErrors[1])
assert(D.events and #D.frames.cooldowns.pool==40 and unlock.CDM_tracking,tostring(D.events)..' '..tostring(unlock.CDM_tracking)..' db '..tostring(D.addon.db)..' frames '..#allFrames)
assert(D.Resolve({kind='spell',id=100}).slot==2)
assert(not D.Resolve({kind='spell',id=300}) and not D.Resolve({kind='spell',id=999999}))
assert(D.Resolve({kind='spell',id=400}).book=='pet')
local lists=D.Lists(); lists.cooldowns={{kind='spell',id=100},{kind='spell',id=400}}
lists.utility={{kind='slot',id=13},{kind='item',id=500},{kind='item',id=501}}
lists.buffs={{kind='aura',id=700,unit='target',filter='HARMFUL',ownOnly=true}}
lists.tracking={{kind='aura',id=701,unit='player'}}
auras.player.HELPFUL={{id=700,name='Spell 700',icon='wrong-unit',count=2,duration=10,expires=20,caster='player'},{id=701,name='Spell 701',icon='permanent',count=3,duration=0,expires=0,caster='other'}}
auras.target.HARMFUL={{id=700,name='Spell 700',icon='other-caster',count=1,duration=15,expires=25,caster='other'},{id=700,name='Spell 700',icon='correct',count=2,duration=12,expires=22,caster='player'}}
cooldowns.spell2={9,20,1}; D.Apply()
assert(#D.compiled.utility==2 and D.compiled.cooldowns[1].remaining==19)
assert(D.compiled.buffs[1].aura.icon=='correct' and D.compiled.buffs[1].count==2)
assert(D.frames.buffs.pool[1].icon.texture=='correct' and D.frames.buffs.pool[1].count.text=='2')
assert(D.frames.tracking.pool[1].bar.value==1 and D.frames.tracking.pool[1].count.text=='3')
assert(D.frames.cooldowns.pool[1].timer.font[3]=='OUTLINE')
D.frames.cooldowns.pool[1]:RunScript('OnEnter'); assert(GameTooltip.slot==2 and GameTooltip.book=='spell')
D.frames.cooldowns.pool[1]:RunScript('OnLeave'); assert(not GameTooltip:IsShown())
gcd={9.5,1.5,1}; cooldowns.spell2={9.5,1.5,1}; D.Update(); assert(not D.compiled.cooldowns[1].active)
D.Config('cooldowns').showGCD=true; D.Update(); assert(D.compiled.cooldowns[1].remaining==1)
D.Config('cooldowns').showGCD=false; cooldowns.spell2={9.6,1,1}; D.Update(); assert(D.compiled.cooldowns[1].active)
D.Profile().readySound=true; now=11; D.Update(); assert(sounds==1); D.Update(); assert(sounds==1)
local frames=#allFrames; combat=true; for i=1,20 do D.Update() end; assert(#allFrames==frames)
now=23; D.Update(); assert(not D.compiled.buffs[1].active and not D.frames.buffs:IsShown())
unlockListener(true); assert(D.frames.buffs:IsShown()); unlockListener(false)
unlock.CDM_cooldowns.savePos(nil,'BOTTOM','BOTTOM',12,34); D.Apply(); assert(D.frames.cooldowns:GetPoint()=='BOTTOM' and D.Profile().positions.cooldowns.y==34)
spec=2; D.Apply(); assert(D.Lists()~=lists); spec=1; D.Apply(); assert(D.Lists()==lists)
D.Profile().cdmBars.bars={}; assert(D.Config('cooldowns').iconSize==42); D.Apply()
combat=false
local abButton=CreateFrame('Button',nil,UIParent); abButton.config={keyBoundTarget='ACTIONBUTTON1'}
function abButton:GetAction() return 'spell',200 end
EllesmereUI._ModuleNS.EllesmereUIActionBars={bars={bar1={buttons={abButton}}}}
D.PrepareActionGlows(); now=10; lists.buffs[1].highlightSpellID=100; D.Apply(); D.Profile().actionBarGlows=true; D.Update(); D.Update()
assert(D.actionGlows[abButton][1]:IsShown() and D.frames.cooldowns.pool[1].keybind.text=='1')
D.Profile().enabled=false; D.Update(); assert(not D.actionGlows[abButton][1]:IsShown() and not D.frames.cooldowns:IsShown())
D.Profile().enabled=true; D.Apply()
rows={}; buttons={}; EllesmereUI.Widgets={}
function EllesmereUI.Widgets:DualRow(parent,y,a,b) rows[#rows+1]=a; rows[#rows+1]=b; return {},40 end
function EllesmereUI.Widgets:SectionHeader() return {},30 end
function EllesmereUI.Widgets:WideButton(parent,text,y,fn) buttons[text]=fn; return {},30 end
function Find(text) for _,r in ipairs(rows) do if r.text==text then return r end end end
function IsLoggedIn() return true end
''')
lua.execute((root/'EllesmereUIOptions/EUI_CooldownManager_335_Options.lua').read_text(encoding='utf-8-sig'))
lua.execute('''
local c=modules.EllesmereUICooldownManager; assert(c and #c.pages==3)
c.buildPage('CDM Bars',UIParent,0); Find('Icon Size').setValue(50); assert(D.Config('cooldowns').iconSize==50)
Find('Entry Type').setValue('aura'); Find('Spell / Item ID').setValue('702'); buttons['Add Entry'](); assert(D.Lists().cooldowns[3].id==702)
rows={}; c.buildPage('CDM Bars',UIParent,0); Find('Aura Unit').setValue('focus'); Find('Aura Type').setValue('HARMFUL'); assert(D.Lists().cooldowns[3].unit=='focus')
buttons['Move Entry Up'](); assert(D.Lists().cooldowns[2].id==702); buttons['Remove Entry'](); assert(#D.Lists().cooldowns==2)
rows={}; c.buildPage('Tracking Bars',UIParent,0); Find('Bar Width').setValue(350); assert(D.Config('tracking').width==350)
Find('Preview').setValue(true); hideOptions(); assert(not D.preview)
rows={}; c.buildPage('Bar Glows',UIParent,0); assert(Find('Highlight EUI Action Buttons'))
SlashCmdList.EUI335CDM(''); assert(shownModule=='EllesmereUICooldownManager')
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
    assert p.read_bytes()==(root/'EllesmereUICooldownManager'/p.name).read_bytes(),p
print('PASS: cooldown manager native Lite lifecycle, ranks/passives/pet, own unit-filtered auras, timers/GCD/stacks/items, preview/unlock/spec persistence, settings assignments, action glows/bindings, no combat frame allocations, independent runtime, unchanged Retail references; combined loaded EUI memory including Options.')
