"""Expanded paper doll contracts; native rendering still needs in-game review."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
lua=LuaRuntime()
for name in ['backport-tools/wrath_mock.lua','backport-tools/blizzardskin_mock.lua','backport-tools/character_mock.lua','EllesmereUI/EllesmereUI_Lite.lua']:
    lua.execute((root/name).read_text(encoding='utf-8-sig'))
lua.execute('CreateCharacterFixture(); EllesmereUIDB={}; lifecycleErrors={}; function geterrorhandler() return function(e) lifecycleErrors[#lifecycleErrors+1]=e end end')
ns=lua.table()
for name in ['EUI_BlizzardSkin_335.lua','EUI_Items_335.lua','EUI_CharacterSheet_335.lua']:
    lua.execute((root/'EllesmereUIBlizzardSkin'/name).read_text(encoding='utf-8-sig'),'EllesmereUIBlizzardSkin',ns)
lua.globals().BS=ns
lua.execute('''
local nativeModelWidth,nativeModelHeight=CharacterModelFrame:GetWidth(),CharacterModelFrame:GetHeight()
local headPoint={CharacterHeadSlot:GetPoint()}; local headParent=CharacterHeadSlot:GetParent()
local headClick=CharacterHeadSlot:GetScript('OnClick')
local nativeAttribute=CharacterFrame:GetAttribute('UIPanelLayout-width')
local titleParent=PlayerTitlePickerFrame:GetParent()
BS.addon:OnInitialize(); BS.addon:OnEnable()
local s=BS.states[CharacterFrame]; local c=s.character
assert(c.enhanced and CharacterFrame:GetWidth()==660 and CharacterFrame:GetHeight()==580)
assert(CharacterFrame:GetAttribute('UIPanelLayout-width')==660)
assert(CharacterModelFrame:GetWidth()==278 and CharacterModelFrame:GetHeight()==375)
assert(CharacterHeadSlot:GetWidth()==40 and CharacterHeadSlot:GetParent()==headParent)
assert(CharacterHeadSlot:GetScript('OnClick')==headClick)
CharacterHeadSlot:RunScript('OnClick'); assert(CharacterHeadSlot.nativeClicks==1)
assert(not CharacterAttributesFrame:IsShown() and not PlayerStatFrameLeftDropDown:IsShown())
assert(CharacterNameText:GetAlpha()==0 and c.name:GetText()=='player')
assert(c.itemLabels.Head:GetText()=='201' and c.summary:GetText()=='209.82')
assert(c.health:GetText():match('^GearScore: %d+$') and c.health:GetText()~='GearScore: 0','GearScore missing: '..tostring(c.health:GetText()))
assert(c.flags.Head and c.flags.Head[1]:IsShown() and c.flags.Head[1].tip=='Missing enchant','unenchanted head not flagged')
assert(not c.flags.Neck or not c.flags.Neck[1]:IsShown(),'neck flagged as enchantable')
assert(not c.flags.Finger0 or not c.flags.Finger0[1]:IsShown(),'ring flagged for non-enchanter')
assert(c.itemLabels.Head.point[5]==7,'item level not raised above flags')
local realLevel=UnitLevel; UnitLevel=function() return 79 end; BS.Apply()
assert(not c.flags.Head[1]:IsShown() and c.itemLabels.Head.point[5]==0,'flags shown below max level')
UnitLevel=realLevel; BS.SetValue('characterMissingEnhancements',false); assert(not c.flags.Head[1]:IsShown())
BS.SetValue('characterMissingEnhancements',true); assert(c.flags.Head[1]:IsShown())
assert(c.sections[1].rows[1].label:GetText()=='Stat 1' and c.sections[1].rows[1].value:GetText()==101)
assert(not c.sections[1].rows[6]:IsShown(),'native-hidden rows were exposed')
assert(c.maxScroll>0 and c.scroll:GetHeight()==340)
local previousRight=0
for _,i in ipairs({1,3,4,5}) do
    local tab=_G['CharacterFrameTab'..i]; local pt={tab:GetPoint()}
    assert(pt[4]>=previousRight,'Character tabs overlap')
    previousRight=pt[4]+tab:GetWidth()+6
end
assert(not CharacterFrameTab2:IsShown(),'layout revealed unavailable Pet tab')
-- Pet availability and longer localized labels reflow without changing IDs.
CharacterFrameTab2:Show(); CharacterFrameTab3.label:SetText('A very long localized reputation tab with more text')
BS.RequestRefresh(); BS.events:RunScript('OnUpdate',.3)
assert(CharacterFrameTab2:GetID()==2 and CharacterFrameTab2.point[4]>CharacterFrameTab1.point[4])
assert(CharacterFrameTab5.point[5]<CharacterFrameTab1.point[5],'overflowing tab row did not wrap')
assert(CharacterFrame:GetHeight()==611,'wrapped tabs fell outside the window bounds')
CharacterFrameTab2:Hide(); CharacterFrameTab3.label:SetText('Reputation'); BS.Apply()
-- Client stat tooltips and collapsible/scrollable sections remain functional.
c.sections[1].rows[1]:RunScript('OnEnter'); assert(nativeStatTooltip=='Native stat tooltip')
local expanded=c.child:GetHeight(); c.sections[1].header:RunScript('OnClick')
assert(c.child:GetHeight()<expanded and not c.sections[1].rows[1]:IsShown())
BS.Apply(); assert(not c.sections[1].rows[1]:IsShown(),'refresh forgot collapsed state')
c.sections[1].header:RunScript('OnClick'); assert(c.child:GetHeight()==expanded)
c.scroll:RunScript('OnMouseWheel',-1); assert(c.scroll:GetVerticalScroll()==42)
c.scroll:RunScript('OnMouseWheel',100); assert(c.scroll:GetVerticalScroll()==0)
-- Native title picker and equipment manager actions, no copied inventory.
c.tabs.titles:RunScript('OnClick'); assert(PlayerTitlePickerFrame:IsShown() and PlayerTitlePickerFrame:GetParent()==CharacterFrame)
c.tabs.titles:RunScript('OnClick'); assert(not PlayerTitlePickerFrame:IsShown())
local sets={{'Raid','Interface\\Icons\\raid'},{'PvP','Interface\\Icons\\pvp'}}
function GetNumEquipmentSets() return #sets end
function GetEquipmentSetInfo(i) return sets[i][1],sets[i][2] end
function GetEquipmentSetInfoByName(n) for i,s in ipairs(sets) do if s[1]==n then return s[2],i end end end
function GetEquipmentSetItemIDs(n) local t={}; for i=1,19 do t[i]=n=='Raid' and i or 999 end; return t end
function GetInventoryItemID(_,slot) return slot end
equipped={}; function EquipmentManager_EquipSet(n) equipped[#equipped+1]=n end
c.tabs.equipment:RunScript('OnClick')
assert(c.equipment:IsShown() and not c.scroll:IsShown() and not c.summary:IsShown(),'equipment pane not shown')
assert(not GearManagerDialog:IsShown(),'legacy Equipment Manager box opened')
local rows=c.equipment.rows
assert(rows[1].text:GetText()=='Raid' and rows[1].check:IsShown() and not rows[2].check:IsShown())
assert(rows[3].text:GetText()=='New Set' and rows[3]:IsShown() and not rows[4]:IsShown())
assert(not c.equipment.equip.enabled,'equip enabled without a selection')
rows[2]:RunScript('OnClick'); assert(c.selectedSet=='PvP' and c.equipment.equip.enabled)
c.equipment.equip:RunScript('OnClick'); assert(equipped[1]=='PvP')
rows[1]:RunScript('OnDoubleClick'); assert(equipped[2]=='Raid')
GearManagerDialogPopup=NativeWindow('GearManagerDialogPopup'); GearManagerDialogPopup:Hide()
popupParent=GearManagerDialogPopup:GetParent()
-- Wrath's already-shown Save path updates without initializing icon totals.
local iconTotal; local rebuilds=0
function RecalculateGearManagerDialogPopup()
 iconTotal=20; rebuilds=rebuilds+1
 local selected=GearManagerDialog.selectedSet
 GearManagerDialogPopup.selectedTexture=selected and selected.icon:GetTexture() or nil
 assert(iconTotal>0)
end
function GearManagerDialogSaveSet_OnClick()
 assert(iconTotal and iconTotal>0,'Uninitialized icon list')
end
GearManagerDialogPopup:Show(); iconTotal=nil
c.equipment.save:RunScript('OnClick')
assert(rebuilds==1 and GearManagerDialog.selectedSet==rows[2] and GearManagerDialogPopup.selectedTexture==rows[2].icon:GetTexture(),'Save did not rebuild already-shown popup')
c.equipment.save:RunScript('OnClick'); assert(rebuilds==2)

rows[3]:RunScript('OnClick')
assert(GearManagerDialogPopup:IsShown() and GearManagerDialogPopup:GetParent()==CharacterFrame and c.selectedSet==nil)
assert(c.popupBg and c.popupBg:IsShown(),'icon picker not skinned')
c.tabs.stats:RunScript('OnClick')
assert(not c.equipment:IsShown() and c.scroll:IsShown() and c.summary:IsShown() and not GearManagerDialog:IsShown())
-- Data refresh handles uncached items and counts a two-hand weapon correctly.
gearCacheMissing=true; BS.RequestRefresh(); BS.events:RunScript('OnUpdate',.3)
assert(c.summary:GetText()=='...' and c.itemLabels.Head:GetText()=='' and c.health:GetText()=='GearScore: ...')
gearCacheMissing=false; BS.events:RunScript('OnUpdate',.3)
assert(c.summary:GetText()=='209.82' and c.itemLabels.Head:GetText()=='201')
gearCacheMissing=true; BS.RequestRefresh(); BS.events:RunScript('OnUpdate',.3)
for i=1,80 do BS.events:RunScript('OnUpdate',.3) end
assert(c.cacheRetries==0 and not BS.CharacterNeedsRefresh(),'cache retry did not stop')
CharacterFrame:Hide(); assert(not BS.CharacterNeedsRefresh())
CharacterFrame:Show(); assert(BS.CharacterNeedsRefresh(),'reopen did not retry the missing item')
gearCacheMissing=false; BS.events:RunScript('OnUpdate',.3)
assert(c.summary:GetText()=='209.82')
gearTwoHand=true; BS.Apply(); assert(c.summary:GetText()=='209.76')
gearTwoHand=false
local calls=statCalls; BS.events:RunScript('OnEvent','COMBAT_RATING_UPDATE'); BS.events:RunScript('OnUpdate',.3)
assert(statCalls>calls)
BS.SetValue('characterItemLevels',false); assert(not c.itemLabels.Head:IsShown())
BS.SetValue('characterItemLevels',true); assert(c.itemLabels.Head:IsShown())
-- Queued disable and exact restoration; button scripts/current tabs are native.
combat=true; BS.SetValue('enhancedCharacterSheet',false); BS.Apply()
assert(CharacterFrame:GetWidth()==660 and c.enhanced)
combat=false; BS.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED')
assert(not c.enhanced and not c.host:IsShown() and not c.header:IsShown())
assert(CharacterFrame:GetWidth()==384 and CharacterFrame:GetHeight()==512)
assert(CharacterModelFrame:GetWidth()==nativeModelWidth and CharacterModelFrame:GetHeight()==nativeModelHeight)
assert(CharacterFrame:GetAttribute('UIPanelLayout-width')==nativeAttribute)
assert(CharacterAttributesFrame:IsShown() and CharacterNameText:GetAlpha()==1)
assert(CharacterHeadSlot:GetPoint()==headPoint[1] and CharacterHeadSlot:GetWidth()==36)
assert(PlayerTitlePickerFrame:GetParent()==titleParent)
assert(GearManagerDialogPopup:GetParent()==popupParent and not c.popupBg:IsShown(),'icon picker not restored')
assert(CharacterHeadSlot:GetScript('OnClick')==headClick)
BS.SetValue('enhancedCharacterSheet',true); assert(c.enhanced and c.host:IsShown())
local count=#allFrames; BS.Apply(); BS.Apply(); assert(#allFrames==count,'repaint duplicated sheet frames')
BS.SetValue('themedCharacterSheet',false)
assert(not s.active and not c.enhanced and CharacterFrame:GetWidth()==384)
assert(CharacterFrameTab1.point[1]=='CENTER','disabled skin did not restore native tabs')
BS.SetValue('themedCharacterSheet',true); assert(c.enhanced)
BS.SetWindowsEnabled(false); assert(not c.enhanced and CharacterFrame:GetWidth()==384)
BS.SetWindowsEnabled(true); assert(c.enhanced)
assert(not next(lifecycleErrors),lifecycleErrors[1])
assert(not C_Item and not C_Spell and not C_Timer)
''')
profiles=(root/'EllesmereUI/EllesmereUI_Profiles.lua').read_text(encoding='utf-8-sig')
bundle='local BLIZZ_SKIN_GLOBAL_KEYS = {}'+profiles.split('local BLIZZ_SKIN_GLOBAL_KEYS = {}',1)[1].split('function EllesmereUI.ExportProfile(',1)[0]
snapshot=lua.execute('local function DeepCopy(v) return v end\n'+bundle+'\nreturn SnapshotBlizzSkinGlobals')
lua.globals().snapshotSkin=snapshot
lua.execute('''
EllesmereUIDB.enhancedCharacterSheet=false; EllesmereUIDB.characterItemLevels=true
local saved=snapshotSkin(); assert(saved.enhancedCharacterSheet==false and saved.characterItemLevels==true)
EllesmereUI.ApplyBlizzSkinGlobals({enhancedCharacterSheet=true,characterItemLevels=false})
assert(EllesmereUIDB.enhancedCharacterSheet==true and EllesmereUIDB.characterItemLevels==false)
EllesmereUI.ApplyBlizzSkinGlobals({}); assert(EllesmereUIDB.enhancedCharacterSheet==nil and EllesmereUIDB.characterItemLevels==nil)
''')
print('PASS: character tab spacing/wrapping/pet visibility; expanded model/native equipment; real legacy stat-row contracts, collapse/scroll/tooltips; titles/equipment actions; item cache/two-hand averages/events; combat deferral; exact geometry restoration and frame reuse.')
