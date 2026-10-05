"""Separate Lua client sessions, real lifecycle and on-disk SavedVariables text."""
from pathlib import Path
from tempfile import TemporaryDirectory
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime

def session(name='Main',realm='Test Realm',saved=None,legacy=None,empty_start=False):
    lua=LuaRuntime()
    for file in ['backport-tools/wrath_mock.lua','backport-tools/inventory_resources_mock.lua']:
        lua.execute((root/file).read_text(encoding='utf-8-sig'))
    lua.globals().testName=name; lua.globals().testRealm=realm
    lua.execute('''
loggedIn=false; reloads=0
function IsLoggedIn() return loggedIn end
function UnitName(unit) if unit=='player' then return testName end; return unit end
function GetRealmName() return testRealm end
testMoney=testName=='Main' and 100000 or testRealm=='Other Realm' and 300000 or 200000
function GetMoney() return testMoney end
function CopyTable(t) local r={}; for k,v in pairs(t) do r[k]=type(v)=='table' and CopyTable(v) or v end; return r end
function Serialize(v)
 if type(v)=='table' then local parts={'{'}; for k,val in pairs(v) do parts[#parts+1]='['..Serialize(k)..']='..Serialize(val)..',' end; parts[#parts+1]='}'; return table.concat(parts) end
 if type(v)=='string' then return string.format('%q',v) end
 return tostring(v)
end
function SaveVariables() return 'EllesmereUIInventoryDB = '..Serialize(EllesmereUIInventoryDB) end
function ReloadUI() reloads=reloads+1; serialized=SaveVariables() end
''')
    lua.execute((root/'EllesmereUI/EllesmereUI_Lite.lua').read_text(encoding='utf-8-sig'),'EllesmereUI',lua.table())
    lua.execute("lifecycle=allFrames[#allFrames]; lifecycle:RunScript('OnEvent','ADDON_LOADED','EllesmereUI')")
    ns=lua.table()
    for file in ['EUI_Bags_335.lua','EUI_Bags_335_Cache.lua','EUI_Bags_335_Categories.lua','EUI_Bags_335_Window.lua','EUI_Bags_335_Broker.lua']:
        lua.execute((root/'EllesmereUIBags'/file).read_text(encoding='utf-8-sig'),'EllesmereUIBags',ns)
    lua.globals().B=ns
    if saved: lua.execute(saved)
    if legacy: lua.execute(legacy)
    if empty_start: lua.execute('bagSlots[0]=0')
    lua.execute("lifecycle:RunScript('OnEvent','ADDON_LOADED','EllesmereUIBags'); loggedIn=true; lifecycle:RunScript('OnEvent','PLAYER_LOGIN')")
    return lua

toc=(root/'EllesmereUIBags/EllesmereUIBags.toc').read_text(encoding='utf-8-sig')
assert '## SavedVariables: EllesmereUIInventoryDB' in toc and 'SavedVariablesPerCharacter' not in toc and 'OptionalDeps' not in toc
first=session(empty_start=True)
first.execute('''
assert(B.CharacterRecord('Test Realm','Main').money==100000 and not B.CharacterRecord('Test Realm','Main').bags,'Startup fabricated inventory contents')
bagSlots[0]=4; combat=true; B.events:RunScript('OnUpdate',5)
assert(B.CharacterRecord('Test Realm','Main').bags.containers[0].items[2].count==12)
assert(not B.views.bags:IsShown(),'Background recording opened inventory')
combat=false; bankSession=true; B.events:RunScript('OnEvent','BANKFRAME_OPENED')
items['-1:1'].count=9; B.events:RunScript('OnEvent','PLAYERBANKSLOTS_CHANGED')
B.events:RunScript('OnEvent','BANKFRAME_CLOSED'); bankSession=false
local original=B.CharacterRecord('Test Realm','Main').bags
bagSlots[0]=0; B.events:RunScript('OnEvent','PLAYER_ENTERING_WORLD'); B.events:RunScript('OnEvent','PLAYER_LOGOUT')
assert(B.CharacterRecord('Test Realm','Main').bags==original,'Startup/logout zero capacity destroyed saved contents')
bagSlots[0]=4; items['0:2'].count=18; B.SaveInventoryAndReload()
assert(reloads==1 and B.CharacterRecord('Test Realm','Main').bags.containers[0].items[2].count==18)
combat=true; B.SaveInventoryAndReload(); assert(reloads==1); combat=false
''')
with TemporaryDirectory(prefix='eui_inventory_') as temporary:
    file=Path(temporary)/'EllesmereUIBags.lua'
    file.write_text(first.globals().serialized,encoding='utf-8')
    second=session('Alt',saved=file.read_text(encoding='utf-8'),empty_start=True)
    second.execute('''
local main=B.CharacterRecord('Test Realm','Main')
assert(main.bags.containers[0].items[2].count==18 and main.bank.containers[-1].items[1].count==9)
assert(B.CharacterRecord('Test Realm','Alt').money==200000 and not B.CharacterRecord('Test Realm','Alt').bags)
assert(main.money==100000 and B.GoldTotals()==300000)
bagSlots[0]=4; items['0:2'].count=7; B.events:RunScript('OnEvent','BAG_UPDATE')
B.SelectCharacter('bank','Test Realm','Main'); assert(B.views.bank.savedPool['-1:1'].stackCount:GetText()=='9')
B.SelectCharacter('bags','Test Realm','Main'); assert(B.views.bags.savedPool['0:2'].stackCount:GetText()=='18')
local store=B.InventoryStore(); B.addon.db:ResetProfile(); B.Apply(); EllesmereUIDB={}
assert(B.InventoryStore()==store and B.CharacterRecord('Test Realm','Main').bank==main.bank)
testName=nil; B.CaptureInventory('bags'); assert(#B.Characters()==2 and not B.CharacterRecord('Test Realm','Unknown Character'))
testName='Alt'; B.events:RunScript('OnEvent','PLAYER_LOGOUT'); serialized=SaveVariables()
''')
    file.write_text(second.globals().serialized,encoding='utf-8')
    third=session('Alt','Other Realm',saved=file.read_text(encoding='utf-8'))
    third.execute('''
assert(#B.Characters()==3)
local total,realmTotal=B.GoldTotals(); assert(total==600000 and realmTotal==300000)
assert(B.CharacterRecord('Test Realm','Alt').bags.containers[0].items[2].count==7)
assert(B.CharacterRecord('Other Realm','Alt').bags.containers[0].items[2].count==12)
B.SelectCharacter('bank','Test Realm','Main'); assert(B.views.bank.savedPool['-1:1'].stackCount:GetText()=='9')
assert(B.InventoryCacheSummary()=='3 saved characters; 3 bags / 1 banks')
''')
legacy="""EllesmereUIDB={wrathInventoryCache={version=1,realms={['Old Realm']={
 Direct={name='Direct',bags={updated=1,containers={[0]={slots=1,items={[1]={link='item:2',count=6}}}}}},
 External={name='External',bags={updated=1,source='External provider',containers={}}},
 Mixed={name='Mixed',bags={updated=1,source='External provider',containers={}},bank={updated=1,containers={[-1]={slots=1,items={[1]={link='item:6',count=2}}}}}},
}}}}"""
fourth=session(legacy=legacy)
fourth.execute('''
assert(B.CharacterRecord('Old Realm','Direct').bags.containers[0].items[1].count==6)
assert(not B.CharacterRecord('Old Realm','External'))
assert(not B.CharacterRecord('Old Realm','Mixed').bags and B.CharacterRecord('Old Realm','Mixed').bank)
assert(not EllesmereUIDB.wrathInventoryCache and EllesmereUIInventoryDB.migratedCore)
''')
print('PASS: actual Core lifecycle, account TOC ownership, SavedVariables disk serialization/load across three character/realm sessions, bank/stack views, startup guards, periodic/combat recording, explicit reload, profile/Core independence and direct-only legacy migration; no external inventory addon.')
