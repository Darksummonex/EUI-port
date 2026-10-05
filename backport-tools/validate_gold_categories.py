"""Gold recording with no bag capacity and independent native item subclasses."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
lua=LuaRuntime()
for file in ['backport-tools/wrath_mock.lua','backport-tools/inventory_resources_mock.lua','EllesmereUI/EllesmereUI_Lite.lua']:
    lua.execute((root/file).read_text(encoding='utf-8-sig'))
ns=lua.table(); lua.globals().B=ns
for file in ['EUI_Bags_335.lua','EUI_Bags_335_Cache.lua','EUI_Bags_335_Broker.lua']:
    lua.execute((root/'EllesmereUIBags'/file).read_text(encoding='utf-8-sig'),'EllesmereUIBags',ns)
lua.execute('''
B.addon:OnInitialize(); B.addon:OnEnable()
local original=UnitName; local money=0; function GetMoney() return money end
function UnitName(unit) if unit=='player' then return 'Alt' end; return original(unit) end
bagSlots[0]=0; B.events:RunScript('OnEvent','PLAYER_MONEY'); assert(B.CharacterRecord('Test Realm','Alt').money==0 and not B.CharacterRecord('Test Realm','Alt').bags)
money=200000; bagSlots[0]=4; B.events:RunScript('OnEvent','PLAYER_MONEY')
UnitName=original; money=50000; B.events:RunScript('OnEvent','PLAYER_MONEY')
local total,realmTotal=B.GoldTotals(); assert(total==250000 and realmTotal==250000)
B.SelectCharacter('bags','Test Realm','Alt'); local f=B.views.bags
assert(f.footer:GetText():find(B.MoneyText(200000),1,true))
f.footerHover:RunScript('OnEnter'); local combined,alt=false,false
for _,line in ipairs(GameTooltip.lines) do combined=combined or line:find('Combined Total:',1,true); alt=alt or line:find('Alt - Test Realm:',1,true) end
assert(combined and alt); f.footerHover:RunScript('OnLeave'); assert(not GameTooltip:IsShown())
assert(B.Category('item:1',1,'Trade Goods','')==4 and B.Category('item:1',1,'Reagent','')==4)
assert(B.Category('item:1',1,'Consumable','','Food & Drink')==9 and B.Category('item:1',1,'Consumable','','Potion')==10)
assert(B.Category('item:1',1,'Consumable','','Flask')==11 and B.Category('item:1',1,'Consumable','','Elixir')==11 and B.Category('item:1',1,'Consumable','','Scroll')==3)
items['0:2'].subtype='Potion'; B.Show('bags'); local p=B.GetSettings(); p.bagCategoryFilter=10; B.Refresh('bags')
assert(f.pool['0:2']:IsShown() and not f.pool['0:1']:IsShown() and f.pool['0:2'].bagID==0 and f.pool['0:2'].slotID==2)
local snapshot=B.CharacterRecord('Test Realm','player').bags; assert(snapshot.containers[0].items[2].itemSubType=='Potion')
p.bagCategoryFilter=0; B.Refresh('bags'); assert(f.pool['0:1']:IsShown())
''')
print('PASS: gold zero/updates without inventory capacity, alt balances/footer/combined tooltip, native crafting/food/potion/flask categories, view-only category filtering and cached subclasses.')
