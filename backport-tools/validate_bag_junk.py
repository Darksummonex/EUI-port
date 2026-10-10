"""Bags Junk Marker: Junk category, marking/unmarking with category restore, header coin, Sell Junk and options."""
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
local CM=B.CM; local p=B.GetSettings()
assert(p.bagShowJunkIcon==true and p.bagShowJunkCoin==false)
local function Names() local t={}; for i,c in ipairs(CM:GetCategories()) do t[i]=c.name end; return t end
local function CatOf(id,quality,itemType)
    local list={{link='item:'..id,itemID=id,itemType=itemType or 'Consumable',itemSubType='Potion',quality=quality,bag=0,slot=1}}
    CM:ClassifyAll(list,false); return CM:GetCategories()[list[1].categoryIndex].name
end
local names=Names(); assert(names[#names]=='Junk',table.concat(names,','))
assert(CatOf(3,0,'Miscellaneous')=='Junk' and CatOf(2,1)=='Consumables')
assert(CM:IsJunk(3,0) and not CM:IsJunk(2,1))
-- Custom categories never land after Junk; Junk cannot be moved.
local at=CM:AddCustomCategory('Mine'); names=Names(); assert(names[#names]=='Junk' and names[at]=='Mine')
-- Marking remembers the previous category; unmarking restores it.
local custom=CM:GetCategories()[at]._defaultName
CM:AssignItem(2,custom); assert(CatOf(2,1)=='Mine')
CM:ToggleJunk(2); assert(CM:IsJunk(2,1) and CatOf(2,1)=='Junk' and EllesmereUIDB.bagJunkPrev[2]==custom)
CM:ToggleJunk(2); assert(not CM:IsJunk(2,1) and CatOf(2,1)=='Mine' and not EllesmereUIDB.bagJunkPrev)
CM:UnassignItem(2); assert(CatOf(2,1)=='Consumables')
CM:ToggleJunk(2); CM:ToggleJunk(2); assert(CatOf(2,1)=='Consumables' and not EllesmereUIDB.bagItemAssignments[2])
-- Header coin on live bags; Sell Junk only while a merchant is open.
B.Show('bags'); local f=B.views.bags; f.view,f.viewKey='all',nil; B.Refresh('bags')
assert(f.junkBtn and f.junkBtn:IsShown() and not f.sellBtn:IsShown())
B.events:RunScript('OnEvent','MERCHANT_SHOW'); assert(B.merchantOpen and f.sellBtn:IsShown())
-- Coin badge and desaturation follow the mark.
CM:ToggleJunk(2); p.bagShowJunkCoin=true; p.bagDesaturateJunkItems=true; B.Refresh('bags')
assert(f.pool['0:2'].junkCoin:IsShown() and f.pool['0:3'].junkCoin:IsShown() and not f.pool['0:1'].junkCoin:IsShown())
-- Cursor item on the coin toggles it; a plain click enters mark mode.
cursorInfo={'item',2}; f.junkBtn:Click(); assert(not CM:IsJunk(2,1) and not cursorInfo)
f.junkBtn:Click(); assert(_G.EUI335BagSelectDim:IsShown() and _G.EUI335BagSelectDim.tip:GetText():find('junk',1,true))
B.ExitSelectMode(); CM:ToggleJunk(2)
-- Sell Junk: priced junk only, pinned and zero-price junk kept.
CM:ToggleJunk(1); EllesmereUIDB.bagPinnedItems=EllesmereUIDB.bagPinnedItems or {}; EllesmereUIDB.bagPinnedItems[1]=true
items['0:3'].locked=false
local prices={['item:1']=900,['item:2']=25,['item:3']=7}
local baseInfo=GetItemInfo
function GetItemInfo(link) local a={baseInfo(link)}; a[11]=prices[link]; return unpack(a,1,11) end
local used,printed={},{}
function UseContainerItem(bag,slot) used[#used+1]=bag..':'..slot end
local basePrint=print; print=function(msg) printed[#printed+1]=msg end
local queue={}; B.After=function(_,fn) queue[#queue+1]=fn end
local function Drain() while #queue>0 do table.remove(queue,1)() end end
B.SellJunk(); Drain()
print=basePrint
assert(#used==2 and used[1]=='0:2' and used[2]=='0:3',table.concat(used,','))
assert(printed[1]:find('Sold 2 junk item(s)',1,true) and printed[1]:find((25*12+7*2)..' copper',1,true),printed[1])
assert(printed[2]:find('1 junk item(s) could not be sold.',1,true),tostring(printed[2]))
-- Closing the merchant stops the sweep and hides Sell Junk.
used={}; print=function() end; B.SellJunk(); B.events:RunScript('OnEvent','MERCHANT_CLOSED'); Drain(); print=basePrint
assert(#used==1 and not B.merchantOpen and not f.sellBtn:IsShown())
B.events:RunScript('OnEvent','MERCHANT_SHOW'); combat=true; used={}; B.SellJunk(); assert(#used==0); combat=false
-- Turning the marker off drops the Junk category and the header buttons.
p.bagShowJunkIcon=false; CM:Invalidate(); B.Refresh('bags')
names=Names(); assert(names[#names]~='Junk' and not CM:IsJunk(3,0) and CatOf(3,0,'Miscellaneous')~='Junk')
assert(not f.junkBtn:IsShown() and not f.sellBtn:IsShown() and not f.pool['0:3'].junkCoin:IsShown())
p.bagShowJunkIcon=true; CM:Invalidate(); names=Names(); assert(names[#names]=='Junk')
''')
opts=(root/'EllesmereUIOptions'/'EUI_Bags_335_Options.lua').read_text(encoding='utf-8')
for needle in ['text="Junk Marker"','P().bagShowJunkIcon~=false','ns.CM:Invalidate()','CogToggle("bagShowJunkCoin","Show Coin on Junk"']:
    assert needle in opts, needle
print('PASS: Junk category last (custom categories before it), grey and marked junk, mark/unmark restores the previous category, header coin and mark mode, Sell Junk at merchants (pins, zero price, combat and merchant close), coin badge and option toggle.')
