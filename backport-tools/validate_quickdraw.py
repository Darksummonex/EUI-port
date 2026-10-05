"""Execute actual release/cancel/wheel snippets in a restricted Wrath fixture."""
from pathlib import Path
import sys
import xml.etree.ElementTree as ET
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
function GetSpellInfo(id) if id==99999 or id==nil then return end; return 'Spell '..id,nil,'spell-icon-'..id end
function GetSpellCooldown(name) assert(type(name)=='string'); return 1,20,1 end
function GetItemInfo(id) return 'Item '..tostring(id),nil,nil,nil,nil,nil,nil,nil,nil,'item-icon' end
function GetItemCooldown(id) return 2,30,1 end
function GetItemCount() return 4 end
function GetMacroInfo(value) if value==1 or value=='Test Macro' then return 'Test Macro','macro-icon','/cast Spell 100' end end
function GetCompanionInfo(kind,index) if index==1 then return 1,kind=='MOUNT' and 'Mount' or 'Pet',500,'companion-icon',false end end
function GetCursorInfo() return cursorKind,cursorID,cursorBook,cursorSpellID end
function ClearCursor() cursorCleared=true; cursorKind=nil end
function GetSpellLink(slot,book) return 'spell:100' end
bindingKeys['ALT-Q']='EUI_RADIAL1'; bindingKeys['SHIFT-Q']='OTHER_ACTION'
LibStub=function() error('External dependency') end
spellbook={'Spell 100','Spell 200','Spell 556'}
function GetNumSpellTabs() return 1 end
function GetSpellTabInfo() return 'General',nil,0,#spellbook end
function GetSpellName(i) return spellbook[i] end
function IsPassiveSpell() return false end
usableSpell,noPowerSpell=true,false
function IsUsableSpell() return usableSpell,noPowerSpell end
function EllesmereUI:ShowConfirmPopup(o) popup=o end
''')
ns=lua.table()
for file in ['EUI_Quickdraw_335.lua','EUI_Quickdraw_335_Catalog.lua','EUI_Quickdraw_335_Secure.lua','EUI_Quickdraw_335_Display.lua']:
    lua.execute((root/'EllesmereUIQuickdraw'/file).read_text(encoding='utf-8-sig'),'EllesmereUIQuickdraw',ns)
lua.globals().D=ns
lua.execute('''
lifecycle:RunScript('OnEvent','ADDON_LOADED','EllesmereUIQuickdraw'); assert(#lifecycleErrors==0,lifecycleErrors[1])
function IsLoggedIn() return true end
Combat(true)
lifecycle:RunScript('OnEvent','PLAYER_LOGIN'); assert(#lifecycleErrors==0,lifecycleErrors[1])
assert(not D.header and D.pending)
Combat(false); D.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED')
assert(#D.live==16 and #D.live[1].pool==20)
-- No sample actions ship in palette 1, so an emptied palette survives the login merge.
assert(#D.defaults.profile.palettes[1].slots==0 and #D.Selected().slots==0)
local saved={palettes={{slots={}}}}; EllesmereUI.Lite.DeepMergeDefaults(saved,D.defaults.profile); assert(#saved.palettes[1].slots==0)
local legacy={palettes={{slots={{},{id='talents'},{kind='spell',id=5}}}}}; D.MigrateProfile(legacy)
local ls=legacy.palettes[1].slots; assert(legacy.slotsV2 and #ls==3 and ls[1].kind=='item' and ls[1].id==6948 and ls[2].kind=='panel' and ls[2].id=='talents' and ls[3].id==5)
legacy.palettes[1].slots[1]={}; D.MigrateProfile(legacy); assert(legacy.palettes[1].slots[1].kind==nil)
D.Selected().slots={{kind='item',id=6948},{kind='panel',id='character'},{kind='panel',id='spellbook'},{kind='panel',id='talents'},{kind='panel',id='quests'}}; D.Apply()
local live=D.live[1]; local view,driver=live.view,live.driver
assert(overrides[D.header]['ALT-Q'] and not overrides[D.header]['SHIFT-Q'])
assert(D.Action({kind='panel',id='spellbook'})=='macrotext')
local kind,value=D.Action({kind='panel',id='spellbook'}); assert(value=='/click SpellbookMicroButton')
local guildKind,guildMacro=D.Action({kind='panel',id='guild'}); assert(guildKind=='macrotext' and guildMacro=='/click SocialsMicroButton\\n/click FriendsFrameTab3')
assert(not D.Action({kind='raidtarget',id=1.5}))
assert(not D.Action({kind='spell',id=99999}) and not D.Action({kind='panel',id='housing'}))
assert(D.Action({kind='companion',id=1,companionType='MOUNT'})=='spell')
assert(D.Action({kind='equipmentset',id='Tank'})=='macrotext')
local count=#secureActions; Click(driver,'LeftButton',true); assert(#secureActions==count and view:IsShown() and overrides[view].ESCAPE)
view.mouseX,view.mouseY=.5,.95; Click(driver,'LeftButton',false)
assert(#secureActions==count+1 and secureActions[#secureActions].kind=='item' and secureActions[#secureActions].value=='item:6948')
assert(not view:IsShown() and not overrides[view].ESCAPE and driver:GetAttribute('type')==nil)
Click(driver,'LeftButton',true); view.mouseX,view.mouseY=.5,.5; count=#secureActions; Click(driver,'LeftButton',false); assert(#secureActions==count)
Click(driver,'LeftButton',true); Click(D.cancel,'LeftButton',false); assert(not view:IsShown() and not overrides[view].ESCAPE)
Click(driver,'LeftButton',false); assert(#secureActions==count)
Combat(true); local frames=#allFrames
Click(driver,'LeftButton',true); view.mouseX,view.mouseY=.5,.95; Click(driver,'LeftButton',false); assert(#secureActions==count+1 and #allFrames==frames)
Click(driver,'LeftButton',true); view:RunScript('OnMouseWheel',-1); assert(view:GetAttribute('wheel')==1)
view:RunScript('OnMouseWheel',-1); assert(view:GetAttribute('wheel')==2)
Click(driver,'LeftButton',false); assert(secureActions[#secureActions].macrotext=='/click CharacterMicroButton')
Click(driver,'LeftButton',true); Click(D.cancel,'LeftButton',false); assert(not view:IsShown() and not driver:GetAttribute('held') and not overrides[view].ESCAPE)
local oldWidth=view:GetWidth(); D.Selected().layout='GRID'; D.Apply(); assert(D.pending and view:GetWidth()==oldWidth)
Combat(false); D.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); assert(not D.pending and view:GetAttribute('layout')=='GRID')
D.Selected().slots={{kind='spell',id=100,unit='focus'},{kind='macro',id=1},{kind='raidtarget',id=8},{kind='companion',id=1,companionType='CRITTER'}}; D.Selected().columns=2; D.Apply()
local function PointSlot(index)
 view.mouseX=.5+view:GetAttribute('x'..index)/view:GetWidth(); view.mouseY=.5+view:GetAttribute('y'..index)/view:GetHeight()
end
Click(driver,'LeftButton',true); PointSlot(1); Click(driver,'LeftButton',false); assert(secureActions[#secureActions].kind=='spell' and secureActions[#secureActions].unit=='focus')
Click(driver,'LeftButton',true); PointSlot(2); Click(driver,'LeftButton',false); assert(secureActions[#secureActions].kind=='macro' and secureActions[#secureActions].value=='Test Macro')
Click(driver,'LeftButton',true); PointSlot(3); Click(driver,'LeftButton',false); assert(secureActions[#secureActions].macrotext=='/run SetRaidTarget("target",8)')
Click(driver,'LeftButton',true); view.mouseX,view.mouseY=nil,nil; count=#secureActions; Click(driver,'LeftButton',false); assert(#secureActions==count)
Click(driver,'LeftButton',true); PointSlot(1); Click(live.pool[1],'LeftButton',false); assert(not view:IsShown() and not driver:GetAttribute('held')); count=#secureActions; Click(driver,'LeftButton',false); assert(#secureActions==count)
-- A release routed via another unbound modifier proxy still commits the held palette.
count=#secureActions; Click(driver,'LeftButton',true); PointSlot(1); Click(D.live[2].driver,'LeftButton',false); assert(#secureActions==count+1 and secureActions[#secureActions].value=='Spell 100' and not view:IsShown())
assert(D.Bind(1,'CTRL-R') and bindingKeys['CTRL-R']=='EUI_RADIAL1' and bindingSaved)
assert(not D.Bind(1,'ESCAPE'))
cursorKind,cursorID,cursorBook='spell',1,'spell'; assert(D.AddCursor() and cursorCleared and D.Selected().slots[5].id==100)
assert(D.AddSlot('macrotext','/cast Spell 200')); assert(not D.AddSlot('spell',99999))
local first=D.Selected(); local second=D.NewPalette(); assert(second and D.selectedPalette==2); D.RemovePalette(2); assert(not second.enabled and first.enabled)
D.selectedPalette=1; D.Selected().layout='FAN'; D.Apply(); assert(view:GetAttribute('layout')=='FAN')
Click(driver,'LeftButton',true); view:RunScript('OnMouseWheel',1); assert(view:GetAttribute('wheel')==#D.Selected().slots); Click(D.cancel,'LeftButton',false)
D.Profile().enabled=false; D.Apply(); assert(not overrides[D.header]['ALT-Q']); count=#secureActions; Click(driver,'LeftButton',true); Click(driver,'LeftButton',false); assert(not view:IsShown() and #secureActions==count)
D.Profile().enabled=true; D.Apply()
Combat(true); D.Selected().name='New Name'; D.Apply(); assert(D.pending); Combat(false); D.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); assert(not D.pending)
D.Selected().layout='ARC'; D.Selected().arcSpan=90; D.Selected().arcRotation=0; D.Apply()
Click(driver,'LeftButton',true); view.mouseX,view.mouseY=.5,.05; count=#secureActions; Click(driver,'LeftButton',false); assert(#secureActions==count)
Click(driver,'LeftButton',true); view.mouseX,view.mouseY=.5,.95; Click(driver,'LeftButton',false); assert(#secureActions==count+1)
Click(driver,'LeftButton',true); view:SetAttribute('initialX',.8); view:SetAttribute('initialY',.8); view.mouseX,view.mouseY=.8,.8; count=#secureActions; Click(driver,'LeftButton',false); assert(#secureActions==count)
-- Repeated Escape cycles leave no temporary bindings or stale actions.
Combat(true); for i=1,10 do Click(driver,'LeftButton',true); Click(D.cancel,'LeftButton',false); Click(driver,'LeftButton',false); assert(not view:IsShown() and not overrides[view].ESCAPE) end; assert(#secureActions==count); Combat(false)
D.UpdateVisuals(1)
-- Server world marker spells, dynamic entries and presets.
local wk,wv=D.Action({kind='worldmarker',id=8}); assert(wk=='macrotext' and wv=='/cast [@cursor] Spell 80951')
assert(select(2,D.Action({kind='worldmarker',id=5}))=='/cast [@cursor] Spell 80950' and select(2,D.Action({kind='worldmarker',id=7}))=='/cast [@cursor] Spell 80949' and not D.Action({kind='worldmarker',id=9}))
wk,wv=D.Action({kind='worldmarker',id=8},{worldMarkerCursor=false}); assert(wk=='spell' and wv=='Spell 80951')
local ck,cv=D.Action({kind='cycleworldmarker'}); assert(ck=='macrotext' and cv:find('^/castsequence %[@cursor%] reset=60 Spell 80952, Spell 80947'))
ck,cv=D.Action({kind='cycleworldmarker'},{worldMarkerCursor=false}); assert(cv:find('^/castsequence reset=60 Spell 80952'))
assert(D.Action({kind='cycleraidtarget'})=='macrotext' and D.Action({kind='randommount'})=='macrotext' and D.Action({kind='lastmount'})=='macrotext' and D.Action({kind='cancelform'})=='macrotext')
assert(select(2,D.Action({kind='panel',id='reputation'}))=='/run ToggleCharacter("ReputationFrame")')
assert(#D.PresetSlots('targetmarkers')==10 and #D.PresetSlots('worldmarkers')==8 and #D.PresetSlots('panels')==19)
for _,slot in ipairs(D.PresetSlots('worldmarkers')) do assert(slot.kind=='worldmarker') end
local hasCycle=false; for _,entry in ipairs(D.Catalog('dynamic')) do if entry.slot.kind=='cycleworldmarker' then hasCycle=true end end; assert(hasCycle)
for _,key in ipairs(D.catalogOrder) do assert(type(D.Catalog(key))=='table',key) end
local select1=D.selectedPalette; local preset=D.NewPresetPalette('worldmarkers'); assert(preset and preset.name=='World Markers' and #preset.slots==8 and preset.slots[8].id==8); D.selectedPalette=select1
assert(D.Display({kind='worldmarker',id=5}):find('Moon') and D.Display({kind='worldmarker',id=8}):find('Skull') and D.Display({kind='worldmarker',id=7}):find('Cross'))
local old={palettes={{name='World Markers',slots={}}}}; for i=1,8 do old.palettes[1].slots[i]={kind='worldmarker',id=i} end; old.palettes[1].slots[9]={kind='cycleworldmarker'}
D.MigrateWorldMarkerPreset(old); assert(#old.palettes[1].slots==8 and old.worldMarkerPresetV2)
old.palettes[1].slots[9]={kind='cycleworldmarker'}; D.MigrateWorldMarkerPreset(old); assert(#old.palettes[1].slots==9)
-- The ring has no panel behind it; only the selected entry is outlined, and labelled rings get extra room.
assert(view.backdrop==nil and live.pool[1].backdrop.bgFile==nil)
D.Selected().slots={{kind='spell',id=100},{kind='spell',id=200}}; D.Selected().radius=100; D.Apply(); assert(view:GetWidth()==2*124+48)
D.Selected().showLabels=false; D.Apply(); assert(view:GetWidth()==2*100+48); D.Selected().showLabels=true
-- Hide Unusable drops unknown spells; Dim Unusable desaturates.
D.Selected().layout='ARC'; D.Selected().arcSpan=360; D.Selected().slots={{kind='spell',id=100},{kind='spell',id=101},{kind='item',id=6948}}; D.spellCache=nil; D.Apply()
assert(view:GetAttribute('count')==2 and live.pool[2].slot.kind=='item')
D.Selected().hideUnusable=false; D.Apply(); assert(view:GetAttribute('count')==3); D.Selected().hideUnusable=true; D.Apply()
usableSpell=false; live.nextState=nil; D.UpdateVisuals(1); assert(live.pool[1].icon.desaturated==true); usableSpell=true; live.nextState=nil; D.UpdateVisuals(1); assert(live.pool[1].icon.desaturated==false)
-- Caption and needle follow the selection.
D.Selected().showActionText=true; D.Apply(); view:SetAttribute('wheel',2); D.UpdateVisuals(1)
assert(live.caption:IsShown() and live.caption:GetText()=='Item 6948' and live.needle[1]:IsShown() and live.hub:IsShown())
view:SetAttribute('wheel',nil); D.Selected().showActionText=false; D.Apply()
-- A world marker entry fires the cursor cast from a live menu and keeps spell tracking.
D.Selected().slots={{kind='worldmarker',id=7},{kind='spell',id=100}}; D.Apply(); assert(live.pool[1].spellName=='Spell 80949')
Click(driver,'LeftButton',true); PointSlot(1); count=#secureActions; Click(driver,'LeftButton',false); assert(secureActions[#secureActions].macrotext=='/cast [@cursor] Spell 80949')
D.Selected().worldMarkerCursor=false; D.Apply(); Click(driver,'LeftButton',true); PointSlot(1); Click(driver,'LeftButton',false); assert(secureActions[#secureActions].kind=='spell' and secureActions[#secureActions].value=='Spell 80949'); D.Selected().worldMarkerCursor=true
-- Pointing moves the selection off a wheel-chosen entry.
D.Selected().slots={{kind='spell',id=100},{kind='macro',id=1},{kind='raidtarget',id=8},{kind='spell',id=200}}; D.Apply()
Click(driver,'LeftButton',true); view:RunScript('OnMouseWheel',-1); assert(view:GetAttribute('wheel')==1)
PointSlot(3); count=#secureActions; Click(driver,'LeftButton',false); assert(#secureActions==count+1 and secureActions[#secureActions].macrotext=='/run SetRaidTarget("target",8)')
Click(driver,'LeftButton',true); view:RunScript('OnMouseWheel',-1); view:RunScript('OnMouseWheel',-1); count=#secureActions; Click(driver,'LeftButton',false); assert(secureActions[#secureActions].value=='Test Macro')
-- Toggle mode latches open; the Select key fires the pointed entry, the menu key closes.
D.Profile().confirmKey='BUTTON3'; D.Profile().cancelKey='X'; D.Selected().toggleMode=true; D.Apply(); assert(driver:GetAttribute('toggle'))
Combat(true)
Click(driver,'LeftButton',true); assert(overrides[view].BUTTON3.name=='EUI335QuickdrawConfirm' and overrides[view].X.name=='EUI335QuickdrawCancel')
count=#secureActions; PointSlot(2); Click(driver,'LeftButton',false); assert(view:IsShown() and driver:GetAttribute('latched') and #secureActions==count)
PointSlot(4); Click(D.confirm,'LeftButton',true); assert(#secureActions==count+1 and secureActions[#secureActions].value=='Spell 200' and not view:IsShown() and not driver:GetAttribute('latched') and not overrides[view].BUTTON3)
Click(D.confirm,'LeftButton',true); assert(#secureActions==count+1)
Click(driver,'LeftButton',true); Click(driver,'LeftButton',false); Click(driver,'LeftButton',true); assert(not view:IsShown() and not driver:GetAttribute('latched')); Click(driver,'LeftButton',false); assert(#secureActions==count+1 and not view:IsShown())
Click(driver,'LeftButton',true); Click(driver,'LeftButton',false); Click(D.cancel,'LeftButton',false); assert(not view:IsShown() and not driver:GetAttribute('latched') and not driver:GetAttribute('held'))
Combat(false)
D.Profile().confirmKey=''; D.Apply(); assert(not driver:GetAttribute('toggle')); D.Selected().toggleMode=false; D.Profile().cancelKey=''; D.Apply()
-- Vertical fan is one column.
D.Selected().layout='FAN'; D.Selected().fanOrientation='VERTICAL'; D.Apply(); assert(view:GetWidth()==D.Selected().iconSize+2*D.Selected().spacing and view:GetAttribute('x1')==0)
D.Selected().fanOrientation='HORIZONTAL'; D.Selected().layout='ARC'; D.Apply()
-- A key already used elsewhere asks before rebinding.
local ok,message,action=D.Bind(1,'SHIFT-Q'); assert(not ok and message=='conflict' and action=='OTHER_ACTION' and bindingKeys['SHIFT-Q']=='OTHER_ACTION')
assert(D.Bind(1,'SHIFT-Q',true) and bindingKeys['SHIFT-Q']=='EUI_RADIAL1'); bindingKeys['SHIFT-Q']='OTHER_ACTION'; D.Apply()
-- Nested menus: an Action Menu entry lays out another menu's actions one level out.
local profile=D.Profile(); local savedSlots=D.Selected().slots
local sub=D.NewPalette('Sub',{{kind='spell',id=200},{kind='macro',id=1},{kind='palette',id=1},{kind='spell',id=101}}); local subIndex=#profile.palettes; D.selectedPalette=1
assert(#D.NestChildren(sub)==2 and D.NestChildren(sub)[2].kind=='macro')
local ok,message=D.AddSlot('palette',1); assert(not ok and message=='A menu cannot open itself')
local menus=D.Catalog('menus'); local listed=false; for _,entry in ipairs(menus) do assert(entry.slot.id~=1); if entry.slot.id==subIndex then listed=true end end; assert(listed)
D.Selected().slots={{kind='spell',id=100},{kind='palette',id=subIndex},{kind='raidtarget',id=8}}; D.Selected().radius=100; D.Apply()
assert(view:GetAttribute('nest2')==2 and view:GetAttribute('nest1')==nil and live.pool[2]:GetAttribute('actionKind')==nil and live.pool[2].name=='Sub')
assert(view:GetWidth()>2*124+48 and view:GetAttribute('ck2_2')=='macro')
local function PointChild(j,k) view.mouseX=.5+view:GetAttribute('cx'..j..'_'..k)/view:GetWidth(); view.mouseY=.5+view:GetAttribute('cy'..j..'_'..k)/view:GetHeight() end
Click(driver,'LeftButton',true); PointSlot(2); count=#secureActions; Click(driver,'LeftButton',false); assert(#secureActions==count and not view:IsShown())
Click(driver,'LeftButton',true); PointChild(2,1); Click(driver,'LeftButton',false); assert(#secureActions==count+1 and secureActions[#secureActions].value=='Spell 200')
Combat(true); Click(driver,'LeftButton',true); PointChild(2,2); Click(driver,'LeftButton',false); assert(secureActions[#secureActions].value=='Test Macro' and not view:IsShown()); Combat(false)
Click(driver,'LeftButton',true); PointSlot(1); Click(driver,'LeftButton',false); assert(secureActions[#secureActions].value=='Spell 100')
-- The ring draws the nest under the selection; a plain entry closes it again.
view:SetAttribute('wheel',2); D.UpdateVisuals(1); assert(live.focus==2 and live.childPool[1].parent==2 and live.childPool[1].icon:IsShown() and not live.childPool[3].icon:IsShown())
view:SetAttribute('wheel',1); D.UpdateVisuals(1); assert(live.focus==nil and not live.childPool[1].icon:IsShown()); view:SetAttribute('wheel',nil)
-- Grid lanes sit outside the block and pick by position.
D.Selected().layout='GRID'; D.Selected().autoColumns=false; D.Selected().columns=3; D.Apply(); assert(view:GetAttribute('cy2_1')>0)
Click(driver,'LeftButton',true); assert(live.childPool[1].icon:IsShown() and live.childPool[2].icon:IsShown()); PointChild(2,2); count=#secureActions; Click(driver,'LeftButton',false); assert(#secureActions==count+1 and secureActions[#secureActions].value=='Test Macro')
Click(driver,'LeftButton',true); PointSlot(3); Click(driver,'LeftButton',false); assert(secureActions[#secureActions].macrotext=='/run SetRaidTarget("target",8)')
Click(driver,'LeftButton',true); view.mouseX,view.mouseY=.5,.5+(view:GetAttribute('cy2_1')+60)/view:GetHeight(); count=#secureActions; Click(driver,'LeftButton',false); assert(#secureActions==count)
-- A nested menu with nothing usable is hidden.
sub.slots={{kind='spell',id=101}}; D.Apply(); assert(view:GetAttribute('count')==2 and view:GetAttribute('nest2')==nil)
D.Selected().layout='ARC'; D.Selected().slots=savedSlots; profile.palettes[subIndex]=nil; D.Apply()
''')
lua.execute('''
local methods=getmetatable(UIParent).__index
function methods:EnableKeyboard(value) self.keyboard=value end
function IsAltKeyDown() return keyAlt or false end
function IsControlKeyDown() return keyCtrl or false end
function IsShiftKeyDown() return keyShift or false end
function GetCurrentKeyBoardFocus() return keyboardFocus end
function methods:ClearFocus() self.focus=false; if keyboardFocus==self then keyboardFocus=nil end end
''')
lua.execute((root/'EllesmereUIOptions/EUI_Quickdraw_335_Options.lua').read_text(encoding='utf-8-sig'))
lua.execute('''
local cfg=modules.EllesmereUIQuickdraw; assert(cfg and #cfg.pages==1)
cfg.buildPage('Palettes',UIParent,0); FindRow('Layout').setValue('GRID'); assert(D.live[1].view:GetAttribute('layout')=='GRID')
FindRow('Action Type').setValue('item'); FindRow('Action ID / Name / Text').setValue('6948'); local count=#D.Selected().slots; buttons['Add Action'](); assert(#D.Selected().slots==count+1)
rows={}; cfg.buildPage('Palettes',UIParent,0); buttons['Move Action Up'](); buttons['Remove Action'](); assert(#D.Selected().slots==count)
-- Assign Key actually listens to keyboard scripts, rather than binding typed text.
local capture=EUI335QuickdrawKeyCapture
assert(capture and not capture.keyboard and not capture:IsShown())
keyboardFocus=CreateFrame('EditBox',nil,UIParent); keyboardFocus.focus=true; local oldFocus=keyboardFocus
buttons['Assign Key'](); assert(capture.keyboard and capture:IsShown() and not keyboardFocus and not oldFocus.focus)
keyCtrl=true; capture:RunScript('OnKeyDown','LCTRL'); assert(not bindingKeys.LCTRL)
bindingSaved=false; capture:RunScript('OnKeyDown','T'); assert(not bindingKeys['CTRL-T'] and not bindingSaved)
keyCtrl=false; capture:RunScript('OnKeyUp','T'); assert(bindingKeys['CTRL-T']=='EUI_RADIAL1' and bindingSaved)
assert(not capture.keyboard and not capture:IsShown() and not next(capture.events))
-- Modifier state is sampled on press; key repeats/other releases cannot overwrite it.
buttons['Assign Key'](); keyAlt=true; keyShift=true; capture:RunScript('OnKeyDown','F8')
capture:RunScript('OnKeyDown','F8'); capture:RunScript('OnKeyDown','Z'); capture:RunScript('OnKeyUp','LSHIFT')
assert(capture.keyboard and not bindingKeys['ALT-SHIFT-F8'])
keyAlt=false; keyShift=false; capture:RunScript('OnKeyUp','F8'); assert(bindingKeys['ALT-SHIFT-F8']=='EUI_RADIAL1' and not capture.keyboard)
-- Escape, page teardown, options close, combat, timeout and focus transfer all release input.
for i=1,10 do buttons['Assign Key'](); capture:RunScript('OnKeyDown','ESCAPE'); assert(not capture.keyboard and not capture:IsShown()) end
buttons['Assign Key'](); capture:RunScript('OnKeyDown','J'); capture:Hide(); capture:RunScript('OnKeyUp','J'); assert(not capture.keyboard and not bindingKeys.J)
buttons['Assign Key'](); cfg.buildPage('Palettes',UIParent,0); assert(not capture.keyboard and not capture:IsShown())
buttons['Assign Key'](); hideOptions(); assert(not capture.keyboard and not capture:IsShown())
buttons['Assign Key'](); Combat(true); capture:RunScript('OnEvent','PLAYER_REGEN_DISABLED'); assert(not capture.keyboard and not capture:IsShown())
buttons['Assign Key'](); assert(not capture.keyboard and not capture:IsShown()); Combat(false)
buttons['Assign Key'](); capture:RunScript('OnUpdate',20); assert(not capture.keyboard and not capture:IsShown())
buttons['Assign Key'](); keyboardFocus=CreateFrame('EditBox',nil,UIParent); capture:RunScript('OnUpdate',.1); assert(not capture.keyboard); keyboardFocus=nil
buttons['Assign Key'](); for _,child in ipairs(capture.children) do if child.kind=='Button' then child:RunScript('OnClick','LeftButton') end end; assert(not capture.keyboard)
-- Failed binding never retains the keyboard, and the next captured chord works.
buttons['Assign Key'](); capture:RunScript('OnKeyDown','INVALID'); capture:RunScript('OnKeyUp','INVALID'); assert(not bindingKeys.INVALID and not capture.keyboard)
buttons['Assign Key'](); keyCtrl=true; capture:RunScript('OnKeyDown','T'); capture:RunScript('OnKeyUp','T'); keyCtrl=false
buttons['Clear Palette Keybinds'](); assert(not GetBindingKey('EUI_RADIAL1'))
SlashCmdList.EQD(); assert(shownModule=='EllesmereUIQuickdraw')
rows={}; buttons={}; cfg.buildPage('Palettes',UIParent,0)
for _,label in ipairs({'Toggle Menu Open','Copy Settings From','Add Action Menu','Fan Direction','Auto Grid Columns','Hide Unusable Entries','Dim Unusable Entries','Show Action Text Label','Selection Needle','Open Animation','World Markers at Cursor'}) do FindRow(label) end
-- Category picker adds the server's world marker spells.
FindRow('Category').setValue('worldmarkers'); rows={}; buttons={}; cfg.buildPage('Palettes',UIParent,0)
local count=#D.Selected().slots; FindRow('Action').setValue(8); buttons['Add Selected Action']()
assert(#D.Selected().slots==count+1 and D.Selected().slots[count+1].kind=='worldmarker' and D.Selected().slots[count+1].id==8)
-- Select/Cancel keys capture keyboard chords and extra mouse buttons.
buttons['Set Select Key'](); assert(capture.keyboard); capture:RunScript('OnMouseDown','MiddleButton'); assert(D.Profile().confirmKey=='BUTTON3' and not capture.keyboard)
buttons['Set Cancel Key'](); capture:RunScript('OnKeyDown','X'); capture:RunScript('OnKeyUp','X'); assert(D.Profile().cancelKey=='X' and not capture.keyboard)
buttons['Clear Select And Cancel Keys'](); assert(D.Profile().confirmKey=='' and D.Profile().cancelKey=='')
-- A conflicting hotkey asks before it is taken from its current action.
bindingKeys['F9']='OTHER_ACTION'; popup=nil; buttons['Assign Key'](); capture:RunScript('OnKeyDown','F9'); capture:RunScript('OnKeyUp','F9')
assert(popup and popup.confirmText=='Rebind' and bindingKeys['F9']=='OTHER_ACTION' and not capture.keyboard); popup.onConfirm(); assert(bindingKeys['F9']=='EUI_RADIAL1')
-- Presets create filled menus; Copy Settings brings layout but not name or actions.
local palettes=#D.Profile().palettes; FindRow('Add Action Menu').setValue('targetmarkers'); assert(#D.Profile().palettes==palettes+1 and #D.Selected().slots==10 and D.Selected().slots[9].id==0)
D.selectedPalette=1; D.Profile().palettes[palettes+1].iconSize=60
rows={}; buttons={}; cfg.buildPage('Palettes',UIParent,0); local before=#D.Selected().slots
FindRow('Copy Settings From').setValue(palettes+1); assert(D.Selected().iconSize==60 and D.Selected().name~='Target Markers' and #D.Selected().slots==before)
-- Preview icons reorder by drag and remove on right click.
rows={}; buttons={}; local mark=#allFrames; cfg.buildPage('Palettes',UIParent,0)
local preview={}; for i=mark+1,#allFrames do local f=allFrames[i]; if f.scripts.OnDragStart and f.dragButtons then preview[#preview+1]=f end end
assert(#preview==#D.Selected().slots and #preview>=3)
local firstSlot=D.Selected().slots[1]; preview[1]:RunScript('OnDragStart'); preview[3]:RunScript('OnEnter'); preview[1]:RunScript('OnDragStop'); assert(D.Selected().slots[3]==firstSlot)
local total=#D.Selected().slots; preview[2]:RunScript('OnClick','RightButton'); assert(#D.Selected().slots==total-1)
-- The Action Menus category nests another menu, and the preview draws its actions.
FindRow('Category').setValue('menus'); rows={}; buttons={}; cfg.buildPage('Palettes',UIParent,0)
local pickIndex; for j,entry in ipairs(D.Catalog('menus')) do if entry.slot.id==palettes+1 then pickIndex=j end end
FindRow('Action').setValue(pickIndex); buttons['Add Selected Action']()
local last=D.Selected().slots[#D.Selected().slots]; assert(last.kind=='palette' and last.id==palettes+1)
rows={}; buttons={}; cfg.buildPage('Palettes',UIParent,0)
''')
original=Path('D:/World of Warcraft/_retail_/Interface/AddOns/EllesmereUIQuickdraw')
assert (original/'EllesmereUIQuickdraw.lua').read_bytes()==(root/'EllesmereUIQuickdraw/EllesmereUIQuickdraw.lua').read_bytes()
assert (original/'Bindings.xml').read_bytes()==(root/'EllesmereUIQuickdraw/Bindings_Retail.xml').read_bytes()
bindings=ET.parse(root/'EllesmereUIQuickdraw/Bindings.xml').getroot()
assert [b.attrib['name'] for b in bindings]==[f'EUI_RADIAL{i}' for i in range(1,17)]
assert 'Bindings.xml' not in [line.strip() for line in (root/'EllesmereUIQuickdraw/EllesmereUIQuickdraw.toc').read_text().splitlines() if not line.startswith('#')]
print('PASS: actual native Quickdraw lifecycle and restricted hold/release/wheel/cancel snippets; arc/grid/fan selection and deadzone, combat actions without insecure mutations/allocation, modifier release routing, deferred combat edits, secure micro-menu macros, spells/items/macros/markers/companions/equipment sets, cursor actions; press/release hotkey capture with modifier snapshots and keyboard cleanup on Escape/hide/page/options/combat/timeout/focus/cancel/failure; keybind persistence, settings, unchanged Retail source and single 16-binding registration; empty shipped palette with legacy-slot migration, server world marker spells, presets/catalog, pointer-over-wheel takeover, toggle mode with Select/Cancel keys, hide/dim unusable, caption/needle/hub, vertical fan, key conflict prompt, preview drag/remove and copy settings; nested action menus on ring and grid with secure child release, one-level filtering, self-nest rejection and the Action Menus picker.')
