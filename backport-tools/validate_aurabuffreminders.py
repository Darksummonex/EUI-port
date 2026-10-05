"""Exercise actual native collectors, secure OOC actions and settings."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
lua=LuaRuntime()
for file in ['backport-tools/wrath_mock.lua','backport-tools/inventory_resources_mock.lua','backport-tools/wrath_secure_palette_mock.lua','EllesmereUI/EllesmereUI_Lite.lua']:
    if file.endswith('EllesmereUI_Lite.lua'):
        lua.execute('lifecycleErrors={}; function geterrorhandler() return function(e) lifecycleErrors[#lifecycleErrors+1]=e end end')
    lua.execute((root/file).read_text(encoding='utf-8-sig'),'EllesmereUI',lua.table())
lua.execute('''
for _,f in ipairs(allFrames) do if f.events.ADDON_LOADED and f.events.PLAYER_LOGIN then lifecycle=f end end
lifecycle:RunScript('OnEvent','ADDON_LOADED','EllesmereUI')
spells={{id=1243,name='Fortitude'},{id=48161,name='Fortitude'},{id=21562,name='Prayer of Fortitude'},{id=588,name='Inner Fire'}}
function GetSpellName(slot) return spells[slot] and spells[slot].name end
function GetSpellLink(slot) return spells[slot] and 'spell:'..spells[slot].id end
function GetSpellTexture(slot) return 'icon-'..slot end
function GetSpellInfo(id)
 if id==99999 then return end
 for _,s in ipairs(spells) do if s.id==id then return s.name,nil,'icon-'..id end end
 return 'Spell '..id,nil,'icon-'..id
end
playerClass='PRIEST'; now=10; group=2; unreachable={}; dead={}; auras={}; inventoryCounts={[43015]=4,[46376]=2}
function GetNumPartyMembers() return group end
function GetNumRaidMembers() return 0 end
function UnitExists(u) return u=='player' or u=='party1' or u=='party2' end
function UnitClass(u) local c=u=='party1' and 'MAGE' or 'PRIEST'; return c,c end
function UnitIsDeadOrGhost(u) return dead[u] or false end
function UnitInRange(u) return not unreachable[u] end
function UnitAura(u,i,filter) local a=auras[u] and auras[u][filter] and auras[u][filter][i]; if a then return a.name,nil,a.icon,a.count,nil,a.duration,a.expires,a.caster,false,false,a.id end end
function GetItemCount(id) return inventoryCounts[id] or 0 end
function GetItemInfo(id) return 'Item '..tostring(id),nil,nil,nil,nil,nil,nil,nil,id=='item:shield' and 'INVTYPE_SHIELD' or 'INVTYPE_WEAPON','item-icon' end
function GetInventoryItemLink(_,slot) if slot==16 then return 'item:weapon' else return 'item:shield' end end
function GetInventoryItemTexture() return 'weapon-icon' end
function GetWeaponEnchantInfo() return weaponEnchant,weaponTime,0,false,0,0 end
function IsInInstance() return instanced or false,'party' end
function IsMounted() return mounted or false end
function GetRealZoneText() return zone or 'Dalaran' end
function GetTalentTabInfo(tab) return 'Tree',nil,tab==1 and 51 or 0 end
playedSounds={}; function PlaySoundFile(path) playedSounds[#playedSounds+1]=path end
LibStub=function() error('External addon dependency') end
''')
ns=lua.table()
for file in ['EUI_AuraBuffReminders_335_Catalog.lua','EUI_AuraBuffReminders_335.lua','EUI_AuraBuffReminders_335_Display.lua']:
    lua.execute((root/'EllesmereUIAuraBuffReminders'/file).read_text(encoding='utf-8-sig'),'EllesmereUIAuraBuffReminders',ns)
lua.globals().D=ns
lua.execute('''
lifecycle:RunScript('OnEvent','ADDON_LOADED','EllesmereUIAuraBuffReminders'); assert(#lifecycleErrors==0,lifecycleErrors[1])
function IsLoggedIn() return true end
Combat(true)
lifecycle:RunScript('OnEvent','PLAYER_LOGIN'); assert(#lifecycleErrors==0,lifecycleErrors[1])
assert(not D.frame and D.pending)
Combat(false); D.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED')
assert(D.events and unlock.EABR_Reminders and #D.actions==40 and not D.frame:IsProtected())
local p=D.Profile(); p.raidBuffs.where='always'; p.auras.where='always'; p.consumables.where='always'
function Missing(key) for i,r in ipairs(D.missing) do if r.key==key then return r,i end end end
D.Apply(); local fort,index=Missing('raid:fort'); assert(fort.count==3 and fort.spell.id==21562)
assert(D.actions[index]:GetAttribute('type1')=='spell' and D.actions[index]:GetAttribute('unit')=='player')
auras.player={HELPFUL={{id=48161,name='Fortitude',icon='fort-icon',count=1,duration=1800,expires=1810,caster='other'},{id=588,name='Inner Fire',icon='fire-icon',count=20,duration=1800,expires=1810,caster='player'}}}
auras.party1={HELPFUL={{id=48162,name='Prayer of Fortitude',icon='prayer-icon',count=1,duration=1800,expires=1810,caster='other'}}}
unreachable.party2=true; D.Refresh(); assert(not Missing('raid:fort') and not Missing('aura:innerfire'))
unreachable.party2=false; D.Refresh(); fort,index=Missing('raid:fort'); assert(fort.count==1 and fort.unit=='party2')
Click(D.actions[index],'LeftButton',false); assert(secureActions[#secureActions].unit=='party2')
Click(D.actions[index],'MiddleButton',false); assert(not Missing('raid:fort'))
D.events:RunScript('OnEvent','PLAYER_ENTERING_WORLD'); assert(Missing('raid:fort'))
local food,foodIndex=Missing('consume:food'); assert(food.item==43015 and food.count==4)
assert(Missing('consume:mainhand') and not Missing('consume:offhand'))
weaponEnchant=true; weaponTime=600000; D.Refresh(); assert(not Missing('consume:mainhand'))
auras.player.HELPFUL[#auras.player.HELPFUL+1]={id=19705,name='Spell 19705',icon='food',duration=0,expires=0,count=1,caster='player'}
auras.player.HELPFUL[#auras.player.HELPFUL+1]={id=53755,name='Spell 53755',icon='flask',duration=3600,expires=3610,count=1,caster='player'}
D.Refresh(); assert(not Missing('consume:food') and not Missing('consume:flask'))
local frames=#allFrames; Combat(true); D.Refresh(); assert(#allFrames==frames)
for _,a in ipairs(D.actions) do assert(not a:IsShown()) end
assert(D.frame:IsShown()); D.pending=true; Combat(false); D.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); assert(not D.pending)
auras.party2={HELPFUL={{id=1243,name='Fortitude',icon='fort',duration=1800,expires=40,count=1,caster='player'}}}
D.Refresh(); assert(Missing('raid:fort')); Combat(true); D.Refresh(); assert(not Missing('raid:fort')); Combat(false)
p.customReminders={{spellID=700,unit='party1',filter='HARMFUL',ownOnly=true,enabled=true,where='always',showUnder=0}}
auras.party1.HARMFUL={{id=700,name='Spell 700',icon='wrongcaster',duration=10,expires=20,count=1,caster='other'}}
D.Refresh(); assert(Missing('custom:1')); auras.party1.HARMFUL[1].caster='player'; D.Refresh(); assert(not Missing('custom:1'))
p.talentReminders={{spellID=800,zone='Icecrown',enabled=true}}; D.Refresh(); assert(not Missing('talent:1')); zone='Icecrown'; D.Refresh(); assert(Missing('talent:1'))
p.auras.sound='WaterDrop'; p.customReminders[1].spellID=701; D.Refresh(); assert(#playedSounds>0); local sounds=#playedSounds; D.Refresh(); assert(#playedSounds==sounds)
mounted=true; D.Refresh(); assert(#D.missing==0); mounted=false
unlockListener(true); D.Refresh(); assert(D.frame:IsShown()); unlockListener(false)
unlock.EABR_Reminders.savePosition(nil,'CENTER','CENTER',15,25); D.Apply(); assert(D.Profile().unlockPos.y==25)
''')
lua.execute((root/'EllesmereUIOptions/EUI_AuraBuffReminders_335_Options.lua').read_text(encoding='utf-8-sig'))
lua.execute('''
local cfg=modules.EllesmereUIAuraBuffReminders; assert(#cfg.pages==3)
cfg.buildPage('Auras, Buffs & Consumables',UIParent,0); FindRow('Icon Size').setValue(55); assert(D.frame.pool[1]:GetWidth()==55)
FindRow('Preview').setValue(true); hideOptions(); assert(not D.preview)
rows={}; cfg.buildPage('Custom Reminders',UIParent,0); FindRow('Aura Spell ID').setValue('702'); buttons['Add Reminder'](); assert(#D.Profile().customReminders==2)
rows={}; cfg.buildPage('Talent Reminders',UIParent,0); FindRow('Expected Talent Spell ID').setValue('803'); buttons['Add Reminder'](); assert(#D.Profile().talentReminders==2)
SlashCmdList.EABR(); assert(shownModule=='EllesmereUIAuraBuffReminders')
''')
original=Path('D:/World of Warcraft/_retail_/Interface/AddOns/EllesmereUIAuraBuffReminders')
for p in original.rglob('*'):
    if p.is_file() and p.suffix!='.toc': assert p.read_bytes()==(root/'EllesmereUIAuraBuffReminders'/p.relative_to(original)).read_bytes(),p
print('PASS: native ABR lifecycle, group/single rank equivalence, reachable/dead-unit filtering, personal auras, consumable counts/permanent buffs, weapon-vs-shield enchants, own debuffs, zone/talent checks, sound deduplication, dismiss/preview/unlock/settings; secure OOC casts and combat read-only display without protected writes or frame allocation; unchanged Retail Lua/sounds.')
