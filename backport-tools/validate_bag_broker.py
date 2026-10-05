"""EUI-owned records and Core-bundled LDB; no external inventory providers."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
lua=LuaRuntime()
lua.execute('strmatch=string.match')
for file in ['backport-tools/wrath_mock.lua','backport-tools/inventory_resources_mock.lua',
             'EllesmereUI/Libs/LibStub/LibStub.lua','EllesmereUI/Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua',
             'EllesmereUI/Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua','EllesmereUI/EllesmereUI_Lite.lua']:
    lua.execute((root/file).read_text(encoding='utf-8-sig'))
lua.execute('''
function CopyTable(t) local r={}; for k,v in pairs(t) do r[k]=type(v)=='table' and CopyTable(v) or v end; return r end
local observer={}; brokerChanges=0
LibStub('LibDataBroker-1.1').RegisterCallback(observer,'LibDataBroker_AttributeChanged',function() brokerChanges=brokerChanges+1 end)
''')
ns=lua.table()
for file in ['EUI_Bags_335.lua','EUI_Bags_335_Cache.lua','EUI_Bags_335_Categories.lua','EUI_Bags_335_Window.lua','EUI_Bags_335_Broker.lua']:
    source=(root/'EllesmereUIBags'/file).read_text(encoding='utf-8-sig')
    assert 'Bagnon' not in source
    lua.execute(source,'EllesmereUIBags',ns)
lua.globals().B=ns
lua.execute('''
B.addon:OnInitialize(); B.addon:OnEnable()
local original=UnitName
function UnitName(unit) if unit=='player' then return 'Alt' end; return original(unit) end
items['0:2'].count=7; B.CaptureInventory('bags')
bankSession=true; B.events:RunScript('OnEvent','BANKFRAME_OPENED'); items['-1:1'].count=9; B.CaptureInventory('bank')
B.events:RunScript('OnEvent','BANKFRAME_CLOSED'); bankSession=false
UnitName=original; items['0:2'].count=12; B.CaptureInventory('bags')
local broker=LibStub('LibDataBroker-1.1'):GetDataObjectByName('EllesmereUI Bags')
assert(broker==B.broker and broker.type=='data source' and broker.text=='2 / 7 free')
local changes=brokerChanges; items['0:4']={link='item:2',name='Potion',count=2,quality=1,type='Consumable'}
B.events:RunScript('OnEvent','BAG_UPDATE'); assert(broker.text=='1 / 7 free' and brokerChanges>changes)
local exported=broker.GetInventory('Test Realm','Alt','bags'); exported.containers[0].items[2].count=100
assert(B.CharacterRecord('Test Realm','Alt').bags.containers[0].items[2].count==7)
assert(#broker.GetCharacters()==2)
broker.OnTooltipShow(GameTooltip); local bank,gold=false,false
for _,line in ipairs(GameTooltip.lines) do bank=bank or line:find('Bank',1,true); gold=gold or line:find('Combined Total:',1,true) end
assert(bank and gold)
B.InitializeBroker(); assert(B.broker==broker)
B.Show('bags'); broker.OnClick(nil,'LeftButton'); assert(not B.views.bags:IsShown()); broker.OnClick(nil,'LeftButton'); assert(B.views.bags:IsShown())
broker.OnClick(nil,'RightButton'); assert(B.views.bank:IsShown() and not B.IsLiveView(B.views.bank))
combat=true; broker.OnClick(nil,'LeftButton'); broker.OnClick(nil,'LeftButton'); assert(not B.views.bags:IsShown()); combat=false
assert(not B.ImportBagnon and not B.BagnonDataAvailable and not B.GetSettings().bagUseBagnonCache)
''')
lua.execute((root/'EllesmereUIOptions/EUI_Bags_335_Options.lua').read_text(encoding='utf-8-sig'))
lua.execute('''
allFrames[#allFrames]:RunScript('OnEvent','PLAYER_LOGIN'); rows={}; modules.EllesmereUIBags.buildPage('Bags',UIParent,0)
assert(not buttons['Import Bagnon Alt Data'] and buttons['Save Inventory & Reload UI'])
''')
print('PASS: Core-bundled LDB source, EUI-recorded alts/stacks/bank data, update events, copied APIs, clicks/tooltip/options; no external inventory source/dependency.')
