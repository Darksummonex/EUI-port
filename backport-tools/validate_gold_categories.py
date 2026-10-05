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
for file in ['EUI_Bags_335.lua','EUI_Bags_335_Cache.lua','EUI_Bags_335_Categories.lua','EUI_Bags_335_Window.lua','EUI_Bags_335_Broker.lua']:
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
assert(f.money:GetText()==B.MoneyString(200000) and f.footer:GetText():find('Saved',1,true))
f.moneyHit:RunScript('OnEnter'); local tip=B.goldTip; assert(tip:IsShown() and tip.totalR:GetText()==B.MoneyString(250000))
local names={}; for _,row in ipairs(tip.rows) do if row.l:IsShown() then names[#names+1]=row.l:GetText() end end
assert(names[1]=='Alt' and tip.rows[1].r:GetText()==B.MoneyString(200000),table.concat(names,','))
f.moneyHit:RunScript('OnLeave'); now=(now or 0)+1; for _,fr in ipairs(allFrames) do if fr.scripts and fr.scripts.OnUpdate then fr:RunScript('OnUpdate',1) end end
assert(not tip:IsShown())
local p=B.GetSettings(); p.enableGoldTracking=false; f.moneyHit:RunScript('OnEnter'); assert(not tip:IsShown()); p.enableGoldTracking=true
local function CatOf(itemType,sub) local list={{link='item:9',itemID=9,itemType=itemType,itemSubType=sub,quality=1,bag=0,slot=1}}; B.CM:ClassifyAll(list,false); return B.CM:GetCategories()[list[1].categoryIndex].name end
assert(CatOf('Trade Goods','Cloth')=='Trade Goods' and CatOf('Reagent','Reagent')=='Trade Goods')
assert(CatOf('Consumable','Food & Drink')=='Consumables' and CatOf('Consumable','Potion')=='Consumables' and CatOf('Consumable','Flask')=='Consumables')
assert(CatOf('Gem','Red')=='Gear Enhancements' and CatOf('Recipe','Tailoring')=='Professions' and CatOf('Junk','Junk')=='Miscellaneous')
items['0:2'].subtype='Potion'; B.Show('bags'); f.view,f.viewKey='cat','Consumables'; B.Refresh('bags')
assert(f.pool['0:2']:IsShown() and not f.pool['0:1']:IsShown() and f.pool['0:2'].bagID==0 and f.pool['0:2'].slotID==2)
local snapshot=B.CharacterRecord('Test Realm','player').bags; assert(snapshot.containers[0].items[2].itemSubType=='Potion')
f.view,f.viewKey='all',nil; B.Refresh('bags'); assert(f.pool['0:1']:IsShown())
''')
print('PASS: gold zero/updates without inventory capacity, alt balances, footer money and Gold Summary panel (tracking toggle), native trade/consumable/gem/recipe categories, view-only category filtering and cached subclasses.')
