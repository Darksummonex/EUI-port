"""Drive the Wrath AuraBuff Reminders runtime and options page on Lua 5.1."""
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
lua.execute(r'''
local m=getmetatable(UIParent).__index
function m:SetSize(w,h) self:SetWidth(w); self:SetHeight(h) end
for _,k in ipairs({"SetWordWrap","SetMaxLines","SetSnapToPixelGrid","SetTexelSnappingBias","SetClipsChildren"}) do m[k]=m[k] or function() end end
for _,f in ipairs(allFrames) do if f.events.ADDON_LOADED and f.events.PLAYER_LOGIN then lifecycle=f end end
lifecycle:RunScript('OnEvent','ADDON_LOADED','EllesmereUI')
-- Pre-0.2 Wrath profile, migrated at OnInitialize.
EllesmereUIDB={profiles={Default={addons={EllesmereUIAuraBuffReminders={
  display={iconSize=60,scale=1,showUnder=120,hideInCombat=true},
  raidBuffs={where='instances',enabled={intellect=false},sound='AirHorn'},
  auras={where='outofcombat',enabled={innerfire=false}},
  consumables={where='always',food=false,preferredFood=34753},
  customReminders={{spellID=700,enabled=true}},
  talentReminders={{spellID=800,zone='Naxxramas',enabled=true}},
}}}}}
BOOKTYPE_SPELL='spell'; BOOKTYPE_PET='pet'; NUM_PET_ACTION_SLOTS=10
names={[1243]='Power Word: Fortitude',[21562]='Prayer of Fortitude',[588]='Inner Fire',[19705]='Well Fed',[433]='Food',
  [53755]='Flask of the Frost Wyrm',[8232]='Windfury Weapon',[8024]='Flametongue Weapon',[324]='Lightning Shield',
  [688]='Summon Imp',[691]='Summon Felhunter',[19505]='Devour Magic',[3110]='Firebolt',[6201]='Create Healthstone',
  [53428]='Runeforging',[700]='Custom Buff'}
function GetSpellInfo(id) if id==99999 then return end; return names[id] or ('Spell '..id),nil,'icon-'..id end
book={'Power Word: Fortitude','Prayer of Fortitude','Inner Fire'}; petBook={}
function GetSpellName(slot,kind) if kind=='pet' then return petBook[slot] end; return book[slot] end
function HasPetSpells() return #petBook>0 and #petBook or nil end
function IsUsableSpell() return true end
function GetSpellCooldown() return 0,0,1 end
function GetItemCooldown() return 0,0,1 end
function GetItemIcon(id) return 'item-icon-'..id end
classes={player='PRIEST',party1='MAGE',party2='WARRIOR'}; present={player=true,party1=true,party2=true}
function UnitClass(u) local c=classes[u]; return c,c end
function UnitExists(u) return present[u] or false end
dead={}; unreachable={}; auras={}
function UnitIsDeadOrGhost(u) return dead[u] or false end
function UnitIsDead(u) return dead[u] or false end
function UnitInRange(u) return not unreachable[u] end
function UnitIsFriend() return true end
function UnitGroupRolesAssigned() return false,false,false end
function GetPartyAssignment() return false end
function UnitAura(u,i,filter) local a=auras[u] and auras[u][i]; if a and (filter or 'HELPFUL')=='HELPFUL' then return a.name,nil,'aura-icon',1,nil,a.duration or 0,a.expires or 0,a.caster or 'player' end end
party=2; raid=0
function GetNumPartyMembers() return party end
function GetNumRaidMembers() return raid end
instanced=true; instanceType='party'; instanceName='Utgarde Keep'; difficulty=2
function IsInInstance() return instanced,instanced and instanceType or 'none' end
function GetInstanceInfo() return instanceName,instanced and instanceType or 'none',difficulty,'Heroic',5,0,false end
mounted=false; flying=false; resting=false
function IsMounted() return mounted end
function IsFlying() return flying end
function IsResting() return resting end
function UnitInVehicle() return false end
function GetNumShapeshiftForms() return 0 end
talentPoints={51,0,0}; talentRank=0
function GetNumTalentTabs() return 3 end
function GetActiveTalentGroup() return 1 end
function GetTalentTabInfo(tab) return 'Tree','tree-icon',talentPoints[tab] end
function GetNumTalents() return 3 end
function GetTalentInfo(tab,index) return 'Talent '..tab..'-'..index,'talent-icon',1,index,(tab==1 and index==3) and talentRank or 0,5 end
counts={[43015]=4}
function GetItemCount(id) return counts[id] or 0 end
weapons={[16]='item:1000:0:0'}; ohEquip='INVTYPE_WEAPON'
function GetInventoryItemLink(_,slot) return weapons[slot] end
function GetItemInfo(link) return 'Item',link,2,200,80,'Weapon','',1,link==weapons[17] and ohEquip or 'INVTYPE_WEAPON','item-icon' end
mhEnchant=false; ohEnchant=false
function GetWeaponEnchantInfo() return mhEnchant,mhEnchant and 3000000 or nil,0,ohEnchant,ohEnchant and 3000000 or nil,0 end
petActions={}
function GetPetActionInfo(i) local a=petActions[i]; if a then return unpack(a) end end
playedSounds={}; function PlaySoundFile(path) playedSounds[#playedSounds+1]=path end
UIErrorsFrame={AddMessage=function(_,msg) lastError=msg end}
C_Timer={After=function(_,fn) fn() end,NewTimer=function() return {Cancel=function() end} end}
EllesmereUI.L=function(s) return s end
EllesmereUI.GetFontUseShadow=function() return false end
EllesmereUI.SetElementVisibility=function(f,v) f.eabrVisible=v end
EllesmereUI.ShowWidgetTooltip=function(_,text) widgetTip=text end
EllesmereUI.HideWidgetTooltip=function() widgetTip=nil end
EllesmereUI.FRAME_STRATA_ORDER_FULL={'MEDIUM'}
EllesmereUI._groupDeathSoundPaths={airhorn='airhorn.ogg'}
''')
# Unlock Mode reads the field names produced by the real core factory.
core_src=(root/'EllesmereUI/EllesmereUI.lua').read_text(encoding='utf-8-sig')
mk_start=core_src.index('function EllesmereUI.MakeUnlockElement(opts)')
lua.execute(core_src[mk_start:core_src.index('\nend\n',mk_start)+5])
ns=lua.table()
for file in ['EUI_AuraBuffReminders_335_Catalog.lua','EUI_AuraBuffReminders_335_Display.lua','EUI_AuraBuffReminders_335.lua','EUI_AuraBuffReminders_335_Extras.lua']:
    lua.execute((root/'EllesmereUIAuraBuffReminders'/file).read_text(encoding='utf-8-sig'),'EllesmereUIAuraBuffReminders',ns)
lua.globals().NS=ns
lua.execute(r'''
D=NS.EABR
lifecycle:RunScript('OnEvent','ADDON_LOADED','EllesmereUIAuraBuffReminders'); assert(#lifecycleErrors==0,lifecycleErrors[1])
local p=D.db.profile
-- Migration from the 0.1 schema.
assert(p.display.iconSize==nil and math.abs(p.display.scale-1.5)<1e-9 and p.display.showUnder==2)
assert(p.raidBuffs.enabled.ai==false and p.raidBuffs.whereToShow.open_world==false and p.raidBuffs.sectionSound=='airhorn')
assert(p.auras.enabled.inner_fire==false and p.auras.whereToShow.in_combat==false)
assert(p.consumables.enabled.food==false and p.consumables.preferredFood=='great_feast' and p.consumables.where==nil)
assert(D.GetCustomSettings().customIDs[1]==700 and p.customReminders==nil)
assert(p.talentReminders[1].zoneNames[1]=='Naxxramas' and p.talentReminders[1].class=='PRIEST')
p.auras.enabled.inner_fire=true; p.auras.whereToShow={}; p.consumables.enabled.food=true; D.GetCustomSettings().customIDs={}
p.talentReminders={}; p.display.scale=1; p.raidBuffs.sectionSound=nil

function IsLoggedIn() return true end
lifecycle:RunScript('OnEvent','PLAYER_LOGIN'); assert(#lifecycleErrors==0,lifecycleErrors[1])
assert(unlock.EABR_Reminders and D.iconAnchor and D._providerCastBtn and not D.iconAnchor:IsProtected())
assert(_EABR_AceDB==D.db and _EABR_RAID_BUFFS==D.RAID_BUFFS and _EABR_Known(588) and not _EABR_Known(14752))
assert(_EABR_TALENT_REMINDER_ZONES[1].name=='Icecrown Citadel' and _EABR_GetSpecID()==33051)

function Missing(dk) for _,m in ipairs(D._missing) do if m.dismissKey==dk then return m end end end
function Overlay(dk) for _,b in ipairs(D.actions) do if b._visual and b._visual._entry and b._visual._entry.dismissKey==dk and b:IsShown() then return b end end end

-- Provider raid buff: group spell on the first missing member, held by the provider button.
D.Refresh()
local fort=Missing('raidbuff:fort'); assert(fort and fort.groupHave==0 and fort.groupTotal==3 and fort.unit=='player')
local pb=D._providerCastBtn
assert(D._providerReserved and pb:GetAttribute('type1')=='spell' and pb:GetAttribute('spell1')=='Prayer of Fortitude' and pb:GetAttribute('unit1')=='player')
assert(D.iconPool[1]._entry==fort and D.iconPool[1]:IsShown())
Click(pb,'LeftButton',false); assert(secureActions[#secureActions].value=='Prayer of Fortitude')
local fire=Overlay('aura:inner_fire'); assert(fire and fire:GetAttribute('spell1')=='Inner Fire' and fire:GetAttribute('unit1')=='player')
local food=Missing('consumable:food'); assert(food.mode=='item' and food.itemID==43015 and food.bagCount==4)
assert(Overlay('consumable:food'):GetAttribute('item1')=='item:43015')
local flask=Missing('consumable:flask'); assert(flask.desaturated and flask.mode==nil and flask.bagCount==0)
assert(D.iconPool[1]._bagCount.text=='0/3')

-- Reachable members only; the next missing member becomes the target.
auras.player={{name='Power Word: Fortitude',duration=3600,expires=3602},{name='Inner Fire',duration=1800,expires=1802}}
auras.party1={{name='Prayer of Fortitude',duration=3600,expires=3602,caster='other'}}
unreachable.party2=true; D.Refresh(); assert(not Missing('raidbuff:fort') and not Missing('aura:inner_fire'))
assert(not D._providerReserved)
unreachable.party2=false; D.Refresh(); fort=Missing('raidbuff:fort'); assert(fort.unit=='party2' and fort.groupHave==2)
-- Show Below: 2 minutes left on a 30 minute buff counts as missing.
auras.player[2].expires=now+60; D.Refresh(); assert(Missing('aura:inner_fire'))
auras.player[2].expires=1802; D.Refresh(); assert(not Missing('aura:inner_fire'))

-- Middle-click dismiss lasts until the next loading screen.
D.iconPool[1]:RunScript('OnMouseUp','MiddleButton'); assert(not Missing('raidbuff:fort') or D.dismissed['raidbuff:fort'])
assert(not D.iconPool[1]:IsShown() or D.iconPool[1]._entry.dismissKey~='raidbuff:fort')
D.OnEvent(nil,'PLAYER_ENTERING_WORLD'); assert(D.iconPool[1]._entry.dismissKey=='raidbuff:fort')

-- Combat: visuals stay live, secure frames are never touched, consumables drop out.
local frames=#allFrames
Combat(true); D.OnEvent(nil,'PLAYER_REGEN_DISABLED'); D.Refresh()
assert(#allFrames==frames and not Missing('consumable:food') and Missing('raidbuff:fort'))
for _,b in ipairs(D.actions) do assert(not b:IsShown()) end
assert(D._providerReserved and D.iconPool[1]._entry.dismissKey=='raidbuff:fort')
D.iconPool[1]:RunScript('OnMouseUp','LeftButton'); assert(lastError=='Click-to-use is disabled in combat')
Combat(false); D.OnEvent(nil,'PLAYER_REGEN_ENABLED'); assert(Missing('consumable:food') and Overlay('consumable:food'))

-- Eating countdown, then Well Fed satisfies food; last used flask is tracked.
auras.player[3]={name='Food',duration=30,expires=now+25}; D.Refresh()
food=Missing('consumable:food'); assert(food.isEating and food.eatingExpirationTime==now+25)
auras.player[3]={name='Well Fed',duration=3600,expires=3602}; D.Refresh(); assert(not Missing('consumable:food'))
counts[46377]=2; D.TrackItemUse(); counts[46377]=1; D.TrackItemUse(); assert(p.consumables.lastUsedFlask==46377)
D.Refresh(); flask=Missing('consumable:flask'); assert(flask.itemID==46377 and flask.mode=='item')
auras.player[4]={name='Flask of the Frost Wyrm',duration=3600,expires=3602}; D.Refresh(); assert(not Missing('consumable:flask'))

-- Where to Show and suppression states.
p.raidBuffs.whereToShow.dungeon_heroic=false; D.Refresh(); assert(not Missing('raidbuff:fort'))
p.raidBuffs.whereToShow.dungeon_heroic=nil
mounted=true; flying=true; D.Refresh(); assert(not D.iconPool[1]:IsShown()); mounted=false; flying=false
resting=true; D.Refresh(); assert(not D.iconPool[1]:IsShown()); resting=false

-- Appear sounds play once per new reminder.
p.auras.sectionSound='airhorn'; D.Refresh(); local before=#playedSounds
auras.player[2]=nil; D.Refresh(); assert(#playedSounds==before+1 and playedSounds[#playedSounds]=='airhorn.ogg')
D.Refresh(); assert(#playedSounds==before+1)

-- Custom spell reminder.
D.GetCustomSettings().customIDs={700}; D.Refresh(); assert(Missing('custom:700') and Missing('custom:700').mode==nil)
D.GetCustomSettings().customIDs={}

-- Rogue: one poison per hand from the bags, applied by slot macro.
D._class='ROGUE'; weapons[17]='item:1001:0:0'; counts[43231]=5; counts[43233]=3; D.Refresh()
local mh,oh=Missing('consumable:instant:mh'),Missing('consumable:deadly:oh')
assert(mh.macro=='/use item:43231\n/use 16' and oh.macro=='/use item:43233\n/use 17' and mh.bagCount==5)
ohEquip='INVTYPE_SHIELD'; D.Refresh(); assert(Missing('consumable:instant:mh') and not Missing('consumable:deadly:oh'))
ohEquip='INVTYPE_WEAPON'; mhEnchant=true; ohEnchant=true; D.Refresh(); assert(not Missing('consumable:instant:mh'))

-- Shaman (Enhancement): main hand imbue first, then off hand; shield.
D._class='SHAMAN'; talentPoints={0,51,0}; mhEnchant=false; ohEnchant=false
book={'Windfury Weapon','Flametongue Weapon','Lightning Shield'}; D.ScanSpellbook(); D.Refresh()
local imbue=Missing('consumable:windfury:mh'); assert(imbue and imbue.spellID==8232)
assert(Missing('consumable:shield_basic').spellID==324)
mhEnchant=true; D.Refresh(); assert(Missing('consumable:flametongue:oh') and not Missing('consumable:windfury:mh'))
mhEnchant=false

-- Warlock: demon cycle on right click, wrong demon, passive pet, healthstone.
D._class='WARLOCK'; book={'Summon Imp','Summon Felhunter','Create Healthstone'}; D.ScanSpellbook(); present.pet=false
D.Refresh(); local pet=Missing('consumable:pet'); assert(pet.petCycleTotal==2 and pet.spellID==688)
assert(Missing('consumable:healthstone').spellID==6201)
for i,f in ipairs(D.activeIcons) do if f._entry==pet then f:RunScript('OnMouseUp','RightButton') end end
assert(Missing('consumable:pet').spellID==691)
present.pet=true; petBook={'Devour Magic'}; p.consumables.wrongPetAllowed={imp=true}; D.Refresh()
assert(Missing('consumable:wrong_pet').spellID==688 and not Missing('consumable:pet'))
petActions[1]={'PET_MODE_PASSIVE',nil,'PET_MODE_PASSIVE',false,true}; D.Refresh()
assert(Missing('consumable:pet_passive').macro=='/petdefensive')
petActions={}; present.pet=false; petBook={}

-- Death Knight: bare weapon needs a rune.
D._class='DEATHKNIGHT'; book={'Runeforging'}; D.ScanSpellbook(); weapons={[16]='item:2000:0:0'}; D.Refresh()
assert(Missing('consumable:runeforge').spellID==53428)
weapons[16]='item:2000:3368:0'; D.Refresh(); assert(not Missing('consumable:runeforge'))

-- Talent reminders by instance name, with synthetic talent keys.
D._class='PRIEST'; talentPoints={51,0,0}
p.talentReminders={{spellID=900103,zoneNames={'Utgarde Keep'},spellName='Talent 1-3',class='PRIEST'}}
D.TR_Refresh(); assert(#D._talentActive==1 and D._talentActive[1]._icon.texture=='talent-icon')
talentRank=2; D.TR_Refresh(); assert(#D._talentActive==0)
p.talentReminders[1].showNotNeeded=true; instanceName='Naxxramas'; D.TR_Refresh()
assert(D._talentActive[1]._text.text=='Talent 1-3 (N/N)'); instanceName='Utgarde Keep'

-- Ready check mana warning for healers in a raid.
raid=10; power=50; maxPower=100; D.RCWUpdateRegistration(); assert(D._rcEvents.events.READY_CHECK)
D.RCWOnEvent(nil,'READY_CHECK'); assert(D._rcFrame:IsShown()); D.RCWHide(); assert(not D._rcFrame:IsShown())
power=90; D.RCWOnEvent(nil,'READY_CHECK'); assert(not D._rcFrame:IsShown()); raid=0

-- Unlock mode position and grow-edge conversion.
local mover=unlock.EABR_Reminders
assert(mover.noResize and mover.noAnchorTarget and mover.getFrame()==D.iconAnchor and mover.order==600)
local mw,mh=mover.getSize(); assert(mw>0 and mh>0)
mover.savePosition(nil,'CENTER','CENTER',15,25); assert(p.unlockPos.y==25)
EllesmereUI.SetAuraBuffGrowDir('RIGHT'); assert(p.unlockPos.point=='LEFT' and EllesmereUI.GetAuraBuffGrowDir()=='RIGHT')
local lp=mover.loadPosition(); assert(lp.point=='CENTER' and math.abs(lp.x-15)<0.01)
EllesmereUI.SetAuraBuffGrowDir('CENTER'); assert(p.unlockPos.point=='CENTER' and p.unlockPos.x==15)
mover.saveRawPosition(nil,{point='CENTER',relPoint='CENTER',x=3,y=4}); assert(mover.loadRawPosition().x==3)
mover.clearPosition(); assert(p.unlockPos==nil); mover.applyPosition()
SlashCmdList.EABR(); assert(shownModule=='EllesmereUIAuraBuffReminders')
''')
# Options page: registers on PLAYER_LOGIN against the Wrath globals.
source=(root/'EllesmereUIOptions/EUI_AuraBuffReminders_335_Options.lua').read_text(encoding='utf-8-sig')
for retail_only in ['C_Traits','C_ClassTalents','C_Map','GetSpecialization','134400','.png','augment_rune','inky_black','showUnderMPlus']:
    assert retail_only not in source,retail_only
# Unlock Mode right-click "Element Options" opens this page's DISPLAY section.
unlock_src=(root/'EllesmereUI/EUI_UnlockMode.lua').read_text(encoding='utf-8-sig')
assert '["EABR_Reminders"] = { module = "EllesmereUIAuraBuffReminders", page = "Auras, Buffs & Consumables", sectionName = "DISPLAY" }' in unlock_src
assert 'barKey == "EABR_Reminders"' in unlock_src and 'EllesmereUI.SetAuraBuffGrowDir(val)' in unlock_src
lua.execute(r'''
EllesmereUI.PanelPP=EllesmereUI.PP
EllesmereUI.CONTENT_PAD=45
EllesmereUI.EXPRESSWAY='Fonts\\FRIZQT__.TTF'
EllesmereUI.ELLESMERE_GREEN={r=0,g=.82,b=.62}
function EllesmereUI:SetContentHeader() end
function EllesmereUI:ClearContentHeader() end
function EllesmereUI.RegisterWidgetRefresh() end
function EllesmereUI.EnKey(s) return s end
function EllesmereUI.Lf(s,...) return s end
function EllesmereUI.DisabledTooltip(s) return s end
function EllesmereUI.MakeBorder() return {SetColor=function() end} end
function EllesmereUI.SolidTex(f) return f:CreateTexture() end
function EllesmereUI.MakeFont(f) local fs=f:CreateFontString(); fs:SetFont('Fonts\\FRIZQT__.TTF',12,''); return fs end
function EllesmereUI.MakeDropdownArrow(f) return f:CreateTexture() end
function EllesmereUI.lerp(a,b,t) return a+(b-a)*t end
function EllesmereUI.BuildFontDropdownData() return {},{} end
function EllesmereUI.BlankRowCfg() return {type='label',text=''} end
function EllesmereUI.BorderOffsetRowCfgs() return {type='label',text=''},{type='label',text=''} end
function EllesmereUI.BorderPxSliderCfg(t) return {type='slider',text=t or 'Border Size'} end
function EllesmereUI.GetBorderDefaults() return {} end
function EllesmereUI.GetBorderDefaultSize() return 1 end
function EllesmereUI.GetBorderStyleSelectDefaults() return {} end
function EllesmereUI.GetBorderTextureDropdown() return {solid='Solid'},{'solid'} end
function EllesmereUI.RowBg() end
function EllesmereUI:SetContentHeaderHeightSilent() end
function EllesmereUI.SmoothScrollTo() end
function EllesmereUI.MakeSettingGlow() end
function EllesmereUI.CreatePreviewHitOverlay() return CreateFrame('Frame') end
function EllesmereUI.DismissPreviewHint() end
function EllesmereUI.AttachSmoothScrollbar() end
EllesmereUI.DARK_BG={r=.05,g=.07,b=.09}
EllesmereUI.TEXT_SECTION_R,EllesmereUI.TEXT_SECTION_G,EllesmereUI.TEXT_SECTION_B,EllesmereUI.TEXT_SECTION_A=1,1,1,1
EllesmereUI.GlowOptions.Rows=function() return {} end
local m=getmetatable(UIParent).__index
function m:SetColorTexture(...) self.color={...} end
-- Remaining native widget setters (EditBox/ScrollFrame) are plain no-ops here.
setmetatable(m,{__index=function(_,k) if k:match('^Set') or k:match('^Enable') or k:match('^Register') then return function() end end end})
EllesmereUI.Widgets={}
''')
lua.execute(source)
lua.execute(r'''
local cfg=modules.EllesmereUIAuraBuffReminders; assert(cfg and #cfg.pages>=2)
-- Prebuild pass: every row of both pages, recording each control's config.
EllesmereUI._prebuilding=true
local W={}
local function Region() local r=CreateFrame('Frame',nil,UIParent); return r end
local function Row(...) local row={_leftRegion=Region(),_rightRegion=Region()}; for _,c in ipairs({...}) do if type(c)=='table' then rows[#rows+1]=c end end; return row,30 end
setmetatable(W,{__index=function(_,k) return function(_,parent,y,...) return Row(...) end end})
function W:DualRow(_,_,a,b) return Row(a,b) end
function W:SectionHeader(_,label) sections[#sections+1]=label; return Row() end
function W:Spacer() return {},10 end
EllesmereUI.Widgets=W
local function Control(text) for _,c in ipairs(rows) do if c.text==text then return c end end end
rows={}; sections={}
assert(cfg.buildPage('Auras, Buffs & Consumables',UIParent,0)>0)
local seen={}; for _,s in ipairs(sections) do seen[s]=true end
assert(seen['DISPLAY'] and seen['RAID BUFFS'] and seen['ROGUE POISONS'] and seen['WARLOCK'] and seen['CUSTOM REMINDERS'] and not seen['PALADIN RITES'])
assert(Control('Show Below') and not Control('Show Below Pre-Key') and not Control('Augment Rune') and not Control('Inky Black Potion'))
local p=_EABR_AceDB.profile
Control('Show Below').setValue(9); assert(p.display.showUnder==9)
Control('Runeforging').setValue(false); assert(p.consumables.enabled.runeforge==false)
Control('Add Custom Spell').setValue('700'); assert(D.GetCustomSettings().customIDs[1]==700)
Control('Add Custom Spell').setValue('99999'); assert(#D.GetCustomSettings().customIDs==1)
local flaskValues
for _,c in ipairs(rows) do if c.text=='Preferred (Click to Buff)' and c.values.frost_wyrm then flaskValues=c end end
assert(flaskValues.values.frost_wyrm=='Flask of the Frost Wyrm')
rows={}; sections={}
assert(cfg.buildPage('Talent Reminders',UIParent,0)>0)
''')
original=Path('D:/World of Warcraft/_retail_/Interface/AddOns/EllesmereUIAuraBuffReminders')
for p in original.rglob('*'):
    if p.is_file() and p.suffix!='.toc': assert p.read_bytes()==(root/'EllesmereUIAuraBuffReminders'/p.relative_to(original)).read_bytes(),p
print('PASS: Wrath ABR migration, provider raid buff button, reachable/Show Below group coverage, overlays, dismiss, combat-safe visuals, eating/flask/food tracking, where/suppression, sounds, custom IDs, rogue poisons, shaman imbues, warlock demons/passive/healthstone, DK runeforge, talent reminders, ready check warning, unlock, options registration; unchanged Retail Lua/sounds.')
