"""Exercise the Wrath DataBars engine, native data, options and secure contracts."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
lua=LuaRuntime()
for file in ['backport-tools/wrath_mock.lua','backport-tools/inventory_resources_mock.lua','EllesmereUI/EllesmereUI_Lite.lua']:
    if file.endswith('EllesmereUI_Lite.lua'):
        lua.execute('lifecycleErrors={}; function geterrorhandler() return function(err) lifecycleErrors[#lifecycleErrors+1]=err end end')
        lua.execute((root/file).read_text(encoding='utf-8-sig'),'EllesmereUI',lua.table())
    else:
        lua.execute((root/file).read_text(encoding='utf-8-sig'))
lua.execute('''
for _,frame in ipairs(allFrames) do
    if frame.events.ADDON_LOADED and frame.events.PLAYER_LOGIN then lifecycle=frame end
end
assert(lifecycle)
lifecycle:RunScript('OnEvent','ADDON_LOADED','EllesmereUI')
''')
lua.execute('''
local m=getmetatable(UIParent).__index
function m:EnableMouseWheel(enabled) self.wheel=enabled end
function m:IsEnabled() return true end
function m:Click() self:RunScript('OnClick','LeftButton') end
UIParent:SetWidth(1920); UIParent:SetHeight(1080)
unlockElements={}
function EllesmereUI:RegisterUnlockElements(elements,folder) for _,e in ipairs(elements) do unlockElements[e.key]=e end end
-- Use native state-driver behavior, including combat changes outside addon Lua.
drivers={}
function RegisterStateDriver(f,key,condition)
    assert(not combat,'Protected state driver changed during combat')
    drivers[f]=condition; f.driver=condition; f.shown=condition~='hide'
end
function Combat(value)
    combat=value
    for f,driver in pairs(drivers) do
        if driver=='[combat] show; hide' then f.shown=value
        elseif driver=='[combat] hide; show' then f.shown=not value end
    end
end
function GetFramerate() return 75.5 end
function GetContainerNumFreeSlots(bag) local free=GetContainerNumSlots(bag); for slot=1,free do if items[bag..':'..slot] then free=free-1 end end; return free,0 end
function GetNetStats() return 2,3,80,95 end
function GetGameTime() return 13,7 end
function GetZoneText() return 'Icecrown' end
function GetSubZoneText() return 'Citadel' end
function GetPlayerMapPosition() return .25,.625 end
function IsInInstance() return inInstance or false end
function UnitLevel() return level or 79 end
function UnitXP() return 250 end
function UnitXPMax() return 1000 end
function GetXPExhaustion() return 300 end
function GetWatchedFactionInfo() if noRep then return end; return 'Argent Crusade',5,3000,9000,4500 end
FACTION_BAR_COLORS={[5]={r=0,g=.6,b=0}}
function GetActiveTalentGroup() return activeSpec or 1 end
function GetNumTalentGroups() return 2 end
function SetActiveTalentGroup(n) assert(not combat); activeSpec=n end
function GetTalentTabInfo(tab) return ({'Arms','Fury','Protection'})[tab],'spec-icon',tab==2 and 51 or 10 end
function GetSkillLineInfo(i) if i==1 then return 'Professions',true,true,0,0,0,0 else return 'Alchemy',false,false,400,0,0,450 end end
function GetNumSkillLines() return 2 end
local info=GetSpellInfo
function GetSpellInfo(id) if id==2259 then return 'Alchemy' end; if info then return info(id) end end
function GetInventoryItemDurability(i) if i==1 then return 50,100 end end
function GetInventoryItemLink(_,slot) if slot==1 then return 'item:1' end end
function GetItemCooldown(id) assert(id==6948); return 0,0 end
function GetBindLocation() return 'Dalaran' end
function HasNewMail() return true end
function GetCurrencyListSize() return 2 end
function GetCurrencyListInfo(i) if i==1 then return 'Dungeon',true,true,false,false,0 end; return 'Valor',false,false,false,true,40,0,'valor-icon',40753 end
function UnitFactionGroup() return 'Horde' end
cvars={Sound_EnableAllSound='1',Sound_MasterVolume='.5',Sound_EnableSFX='1',Sound_SFXVolume='.2'}
function GetCVar(key) return cvars[key] or '1' end
function SetCVar(key,value) cvars[key]=tostring(value) end
function ToggleCharacter(tab) openedTab=tab end
function ToggleCalendar() calendar=true end
function ToggleTimeManager() clock=true end
function ToggleTalentFrame() talents=true end
function ToggleWorldMap() map=true end
CharacterMicroButton=CreateFrame('Button','CharacterMicroButton',UIParent)
CharacterMicroButton:SetScript('OnClick',function() microClicked=true end)
''')
bags=lua.table()
for file in ['EUI_Bags_335.lua','EUI_Bags_335_Cache.lua','EUI_Bags_335_Categories.lua','EUI_Bags_335_Window.lua','EUI_Bags_335_Broker.lua']:
    lua.execute((root/'EllesmereUIBags'/file).read_text(encoding='utf-8-sig'),'EllesmereUIBags',bags)
lua.globals().B=bags
lua.execute("lifecycle:RunScript('OnEvent','ADDON_LOADED','EllesmereUIBags'); assert(#lifecycleErrors==0,lifecycleErrors[1])")
ns=lua.table()
for file in ['EUI_DataBars_335.lua','EUI_DataBars_335_Blocks.lua']:
    lua.execute((root/'EllesmereUIDataBars'/file).read_text(encoding='utf-8-sig'),'EllesmereUIDataBars',ns)
lua.globals().D=ns
lua.execute('''
lifecycle:RunScript('OnEvent','ADDON_LOADED','EllesmereUIDataBars')
assert(#lifecycleErrors==0,lifecycleErrors[1])
assert(D.addon.db and D.db==D.addon.db)
function IsLoggedIn() return true end
lifecycle:RunScript('OnEvent','PLAYER_LOGIN')
assert(#lifecycleErrors==0,lifecycleErrors[1])
assert(D.events and B.events)
assert(#D.BarsInOrder()==1 and D.GetProfile().initialized and D.live[1].frame:GetWidth()==1920)
assert(unlockElements.EDB_1 and unlockElements.EDB_1.getFrame()==D.live[1].frame)
local bar=D.CreateBar('empty'); testBar=bar
bar.length=1200; bar.thickness=32
allBlocks={}
for _,type in ipairs(D.BLOCK_TYPES) do allBlocks[type.key]=D.AddBlock(bar.id,type.key) end
assert(#bar.blocks==20)
local rec=D.live[bar.id]
function Slot(key) return rec.slots[allBlocks[key].id] end
assert(Slot('clock').text:GetText():find('%[Mail%]'))
assert(Slot('fps').text:GetText()=='76 FPS' and Slot('ms').text:GetText()=='80 ms')
assert(Slot('location').text:GetText()=='Citadel' and Slot('coords').text:GetText()=='25.0, 62.5')
assert(Slot('gold').text:GetText()=='1g 23s 45c' and Slot('bags').text:GetText()=='2/6 Free')
assert(Slot('durability').text:GetText()=='Durability: 50%' and Slot('spec').text:GetText()=='Fury')
assert(Slot('profession').text:GetText()=='Alchemy 400/450')
assert(Slot('travel').secure.template=='SecureActionButtonTemplate' and Slot('travel').secure:GetAttribute('item')=='item:6948')
assert(Slot('xprep').fill.value==250 and Slot('xprep').rested.value==550 and D.ProgressUsed('xp'))
assert(Slot('ilvl').text:GetText()=='iLvl: 200' and Slot('audio').text:GetText()=='Master: 50%')
assert(Slot('ldb').text:GetText()=='2/6 Free' and not B.views.bags:IsShown())
Slot('bags'):RunScript('OnClick','LeftButton'); assert(B.views.bags:IsShown())
Slot('bags'):RunScript('OnClick','RightButton'); assert(B.views.bank:IsShown())
Slot('spec'):RunScript('OnClick','RightButton'); assert(activeSpec==2)
Slot('spec'):RunScript('OnClick','LeftButton'); assert(talents)
Slot('clock'):RunScript('OnClick','LeftButton'); Slot('clock'):RunScript('OnClick','RightButton'); assert(calendar and clock)
Slot('location'):RunScript('OnClick','LeftButton'); assert(map)
Slot('ilvl'):RunScript('OnClick','LeftButton'); assert(openedTab=='PaperDollFrame')
Slot('micromenu').micro[1]:RunScript('OnClick'); assert(microClicked and CharacterMicroButton:GetParent()==UIParent)
Slot('audio'):RunScript('OnMouseWheel',1); assert(tonumber(cvars.Sound_MasterVolume)==.55)
Slot('audio'):RunScript('OnClick','LeftButton'); D.Update(); assert(Slot('audio').text:GetText()=='Master: Muted')
local values,order=D.BuildCurrencyList(); assert(values['40753']=='Valor' and #order==2)
allBlocks.currency.settings.currencyKey='40753'; D.Update(); assert(Slot('currency').text:GetText()=='Valor: 40')
Slot('currency'):RunScript('OnEnter'); assert(GameTooltip.tooltipText=='Currency' and GameTooltip:IsShown())
Slot('currency'):RunScript('OnClick','LeftButton'); assert(openedTab=='TokenFrame')
level=80; D.Update(); assert(Slot('xprep').fill.value==1500 and Slot('xprep').fill.maximum==6000 and D.ProgressUsed('reputation') and not D.ProgressUsed('xp'))
noRep=true; D.Update(); assert(Slot('xprep').text:GetText()=='No Watched Reputation' and Slot('xprep').fill.value==0); noRep=false
inInstance=true; D.Update(); assert(Slot('coords').text:GetText()=='--, --'); inInstance=false
-- Repeated refresh/reconfiguration reuse native objects.
local count=#allFrames; D.Update(); D.Apply(); D.Apply(); assert(#allFrames==count)
local first=bar.blocks[1].id; D.MoveBlock(bar.id,first,1); assert(bar.blocks[2].id==first)
local segments=D.SolveLayout(bar,1192)
local last=segments[#segments]; assert(math.abs(last.offset+last.length-1192)<.001)
bar.sizingMode='weighted'; bar.blocks[1].width=200; bar.blocks[2].width=100
segments=D.SolveLayout(bar,1192); assert(segments[1].length==segments[2].length*2)
bar.orientation='V'; D.Apply(); assert(rec.frame:GetWidth()==32 and rec.frame:GetHeight()==1200 and rotationCalls==0)
local elem=unlockElements['EDB_'..bar.id]
elem.savePos(nil,'TOPLEFT','TOPLEFT',20,-60); elem.applyPos()
assert(select(4,rec.frame:GetPoint(1))==20 and elem.loadPos().y==-60)
D.RenameBar(bar.id,'Test Bar'); assert(elem.label=='Test Bar')
bar.visibility='combat'; D.Apply(); assert(rec.frame.driver=='[combat] show; hide')
Combat(true); D.Update(); assert(rec.frame:IsShown())
Slot('spec'):RunScript('OnClick','RightButton'); assert(activeSpec==2)
local old=bar.length; bar.length=1000; D.Apply(); assert(D.pending and rec.frame:GetHeight()==old)
assert(not D.CreateBar('empty')); D.DeleteBar(bar.id); assert(D.GetBar(bar.id))
Combat(false); D.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); assert(not D.pending and rec.frame:GetHeight()==1000)
EllesmereUI.listeners.EllesmereUIDataBars(true); assert(rec.frame.driver=='show' and D.preview)
EllesmereUI.listeners.EllesmereUIDataBars(false); assert(rec.frame.driver=='[combat] show; hide')
D.RemoveBlock(bar.id,allBlocks.xprep.id); assert(not D.ProgressUsed('reputation') and not Slot('xprep'):IsShown())
D.DeleteBar(bar.id); assert(not D.GetBar(bar.id) and rec.frame.driver=='hide' and elem.isHidden())
local nextBar=D.CreateBar('minimapc'); assert(nextBar.id>bar.id and #nextBar.blocks==3)
D.CreateBar('microstrip'); assert(#D.BarsInOrder()==3)
-- Core profile replacement must rebind callbacks to the current block settings.
local copied=D.Copy(D.GetProfile()); D.addon.db.profile=copied
local audio=D.GetBlock(1,1)
local extra=D.AddBlock(3,'audio'); extra.settings.channel='SFX'; D.Apply()
local audioSlot=D.live[3].slots[extra.id]
local copyAgain=D.Copy(D.GetProfile()); D.addon.db.profile=copyAgain
D.GetBlock(3,extra.id).settings.channel='Master'; D.Apply()
audioSlot:RunScript('OnMouseWheel',1); assert(tonumber(cvars.Sound_MasterVolume)==.6 and tonumber(cvars.Sound_SFXVolume)==.2)
''')
lua.execute((root/'EllesmereUIOptions/EUI_DataBars_335_Options.lua').read_text(encoding='utf-8-sig'))
lua.execute('''
allFrames[#allFrames]:RunScript('OnEvent','PLAYER_LOGIN')
local cfg=modules.EllesmereUIDataBars; assert(cfg and cfg.pages[1]=='DataBars')
rows={}; cfg.buildPage('DataBars',UIParent,0)
assert(FindRow('Select Bar') and FindRow('Text Scale'))
FindRow('Select Bar').setValue(3); rows={}; cfg.buildPage('DataBars',UIParent,0)
FindRow('Text Scale').setValue(120); assert(D.GetBar(3).fontScale==120)
FindRow('Block To Add').setValue('currency'); buttons['Add Block'](); rows={}; cfg.buildPage('DataBars',UIParent,0)
FindRow('Currency').setValue('40753'); assert(D.GetBar(3).blocks[#D.GetBar(3).blocks].settings.currencyKey=='40753')
SlashCmdList.EUI335DATABARS(); assert(shownModule=='EllesmereUIDataBars')
''')
# Verify preserved source, native TOC and no external data dependency.
original=Path('D:/World of Warcraft/_retail_/Interface/AddOns/EllesmereUIDataBars')
for p in original.rglob('*'):
    if p.is_file() and p.suffix!='.toc':
        assert p.read_bytes()==(root/'EllesmereUIDataBars'/p.relative_to(original)).read_bytes(),p
toc=(root/'EllesmereUIDataBars/EllesmereUIDataBars.toc').read_text(encoding='utf-8-sig')
assert [l for l in toc.splitlines() if l and not l.startswith('#')]==['EUI_DataBars_335.lua','EUI_DataBars_335_Blocks.lua']
print('PASS: actual Core ADDON_LOADED/PLAYER_LOGIN dispatcher with Lua 5.1 xpcall and no implicit self; DataBars DB/enable/events, 20 block types, values/clicks/fonts, EUI-only inventory, secure hearthstone and combat visibility, layout bounds/vertical/scale, positions, profiles/CRUD/reuse, options/search/slash, native TOC and unchanged Retail references.')
