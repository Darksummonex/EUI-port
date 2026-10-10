"""Native Wrath API/lifecycle checks for Bags plus the shared Retail-copy/TOC checks for Resource Bars; in-game QA still required."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime

def runtime(player_class='WARRIOR'):
    lua=LuaRuntime(unpack_returned_tuples=True)
    for path in ['backport-tools/wrath_mock.lua','backport-tools/inventory_resources_mock.lua','EllesmereUI/EllesmereUI_Lite.lua']:
        lua.execute((root/path).read_text(encoding='utf-8-sig'))
    lua.globals().playerClass=player_class
    lua.execute('function GetSpellInfo(id) return id==689 and "Drain Life" or id==47540 and "Penance" or tostring(id) end')
    for helper in ['EUI_ChannelTicks_335.lua','EUI_AuraFilters_335.lua']:
        lua.execute((root/'EllesmereUI'/helper).read_text())
    # Use actual Core safecall: Lua 5.1 xpcall does NOT pass callback self.
    core=(root/'EllesmereUI/EllesmereUI_Lite.lua').read_text(encoding='utf-8-sig')
    safe=lua.execute('local function errorhandler('+core.split('local function errorhandler(',1)[1].split('\n-------------------------------------------------------------------------------',1)[0]+'\nreturn safecall')
    return lua,safe

def load(lua,folder,file,namespace=None):
    ns=namespace or lua.table()
    lua.eval('function(s) return assert(loadstring(s)) end')((root/folder/file).read_text(encoding='utf-8-sig'))(folder,ns)
    return ns

def tile(lua,file,name,next_name):
    source=(root/'EllesmereUIOptions'/file).read_text(encoding='utf-8-sig')
    body='local function '+name+source.split('local function '+name,1)[1].split('local function '+next_name,1)[0]
    context='''
local NS=EllesmereUI.ModuleNS
local function ModuleOutlineCfg() return {type='label',text='Outline'} end
local function BLANK() return {type='label',text=''} end
local function LinkRow(parent,y,label,folder,page) links=links or {}; links[#links+1]={folder,page}; return y-40 end
local function CopyBarDD(names,order,lookup) return names,order end
'''
    return lua.execute(context+body+'\nreturn '+name)

RB_FILES=['EUI_ResourceBars_335.lua','EUI_ResourceBars_335_Bars.lua','EUI_ResourceBars_335_Cast.lua','EUI_ResourceBars_335_Swing.lua','EUI_ResourceBars_335_Totems.lua']
BAG_FILES=['EUI_Bags_335.lua','EUI_Bags_335_Cache.lua','EUI_Bags_335_Categories.lua','EUI_Bags_335_Window.lua','EUI_Bags_335_Broker.lua']
for folder in ['EllesmereUIBags','EllesmereUIResourceBars']:
    retail=Path('D:/World of Warcraft/_retail_/Interface/AddOns')/folder
    for original in retail.rglob('*'):
        if original.is_file() and original.suffix.lower()!='.toc':
            assert original.read_bytes()==(root/folder/original.relative_to(retail)).read_bytes(),original
    toc=(root/folder/(folder+'.toc')).read_text(encoding='utf-8-sig')
    assert '## Interface: 30300' in toc
    loaded=[line.strip() for line in toc.splitlines() if line.strip() and not line.startswith('#')]
    assert loaded==(BAG_FILES if folder.endswith('Bags') else RB_FILES)

lua,safe=runtime()
bags=load(lua,'EllesmereUIBags',BAG_FILES[0]); lua.globals().BAGS=bags
for bag_file in BAG_FILES[1:]: load(lua,'EllesmereUIBags',bag_file,bags)
safe(bags.addon.OnInitialize,bags.addon); safe(bags.addon.OnEnable,bags.addon)
lua.execute('''
local p=BAGS.GetSettings(); local f=BAGS.views.bags
assert(EllesmereUI._bagsDB==BAGS.addon.db and _EBAGS_RefreshAll==BAGS.Apply)
assert(not f:IsShown() and not BAGS.views.bank:IsShown())
ToggleBackpack(); assert(f:IsShown() and #nativeCalls==0 and f.view=='all' and f.title:GetText()=='Bags')
assert(EllesmereUIDB.bagFirstOpenDone and EllesmereUIDB.bagPinnedItems[6948],'Hearthstone not pinned on first open')
local sword=f.pool['0:1']; local potion=f.pool['0:2']; local armor=f.pool['1:1']
assert(sword:GetName()=='EUI335Item_Bags_0_1' and sword.kind=='CheckButton' and sword.checked=='')
local function Labels(list,field) local out={}; for _,o in ipairs(list) do if o:IsShown() then out[#out+1]=field(o) end end; return table.concat(out,'|') end
local function Headers() return Labels(f.headers,function(h) return h.label:GetText() end) end
local function Sidebar() return Labels(f.sbButtons,function(b) return b.entry.label end) end
assert(Sidebar()=='All Items|OneBag|MultiBag|Pinned Items|Recent Items|The Armory|Weapons / Trinkets|Armor|Adventure Prep|Consumables|Keys|Junk|Add Category',Sidebar())
assert(Headers()=='Pinned Items|Recent Items|The Armory (2)|Adventure Prep (1)|Keys (1)|Junk (1)',Headers())
assert(sword:GetScript('OnClick')==NativeItemClick and sword:GetScript('OnDragStart')==NativeItemDrag and sword:GetScript('OnReceiveDrag')==NativeItemDrag)
sword:RunScript('OnClick','RightButton'); armor:RunScript('OnDragStart')
assert(itemActions[1][1]==0 and itemActions[1][2]==1 and itemActions[2][1]==1 and itemActions[2][2]==1)
assert(sword.level:GetText()=='200' and potion.stackCount:GetText()=='12' and armor.readable)
assert(potion.count==12 and sword.count==1,'Native numeric item count missing')
assert(not f.pool['0:4'],'All Items view should not draw empty slots')
assert(potion.stackCount:IsShown(),'Native template stack count remains hidden')
assert(potion.stackCount:GetDrawLayer()=='OVERLAY','Stack count is below the item icon')
assert(not sword.stackCount:IsShown(),'Single items have a stack count')
items['0:2'].count=1; BAGS.events:RunScript('OnEvent','BAG_UPDATE'); assert(not potion.stackCount:IsShown())
items['0:2'].count=20; BAGS.events:RunScript('OnEvent','BAG_UPDATE'); assert(potion.stackCount:IsShown() and potion.stackCount:GetText()=='20')
items['0:2'].count=12; BAGS.Refresh('bags')
assert(potion.cooldown.cooldown[2]==8 and f.pool['0:3'].icon.desaturated)
sword:RunScript('OnEnter'); assert(GameTooltip.bag==0 and GameTooltip.slot==1)
assert(f.pool['-2:1'] and f.scroll.scrollChild==f.content)
f.search:SetText('potion'); assert(sword:GetAlpha()==.2 and potion:GetAlpha()==1)
f.search:RunScript('OnEscapePressed'); assert(f.search:GetText()=='' and sword:GetAlpha()==1)
-- Middle-click pins; pinned items show in the Pinned quickview with their own pool.
sword:RunScript('OnMouseUp','MiddleButton'); assert(EllesmereUIDB.bagPinnedItems[1] and f.pinPool['0:1'] and f.pinPool['0:1']:IsShown())
sword:RunScript('OnMouseUp','MiddleButton'); assert(not EllesmereUIDB.bagPinnedItems[1] and not f.pinPool['0:1']:IsShown())
-- Duplicate stacks merge onto the first copy; mail/trade pause merging.
items['1:2']={link='item:2',name='Healing Potion',quality=1,type='Consumable',count=3}
BAGS.Refresh('bags'); assert(potion.stackCount:GetText()=='15' and not (f.pool['1:2'] and f.pool['1:2']:IsShown()))
BAGS.events:RunScript('OnEvent','MAIL_SHOW'); assert(potion.stackCount:GetText()=='12' and f.pool['1:2']:IsShown())
BAGS.events:RunScript('OnEvent','MAIL_CLOSED'); items['1:2']=nil; BAGS.Refresh('bags')
-- Newly looted items appear in Recent Items.
items['1:2']={link='item:7',name='Linen Cloth',quality=1,type='Trade Goods',count=5}
BAGS.events:RunScript('OnEvent','BAG_UPDATE'); assert(BAGS.recent[7] and f.recentPool['1:2'] and f.recentPool['1:2']:IsShown())
BAGS.ClearRecent(); assert(not f.recentPool['1:2']:IsShown()); items['1:2']=nil; BAGS.Refresh('bags')
-- Dropping a held item on a sidebar category assigns it there.
local misc; for _,b in ipairs(f.sbButtons) do if b:IsShown() and b.entry.label=='Consumables' then misc=b end end
cursorInfo={'item',3}; cursorItem=true; BAGS.SidebarClick(f,misc.entry,'LeftButton')
assert(EllesmereUIDB.bagItemAssignments and clearedCursor>0 and f.view=='all')
assert(Headers()=='Pinned Items|Recent Items|The Armory (2)|Adventure Prep (2)|Keys (1)',Headers())
BAGS.CM:UnassignItem(3); BAGS.RefreshAll()
-- Sidebar views filter the grid; right-click opens the category menu.
BAGS.SidebarClick(f,misc.entry,'LeftButton'); assert(f.view=='cat' and f.itemCount:GetText()=='1 Items')
BAGS.SidebarClick(f,misc.entry,'RightButton'); assert(lastMenu and lastMenu[1].text=='Consumables' and lastMenu[2].text=='Rename')
f.view='onebag'; BAGS.Refresh('bags')
assert(Headers()=='Pinned Items|Main Bags (4 / 6)|Keyring (1 / 1)',Headers())
assert(f.pool['0:4']:IsShown() and f.pool['0:4'].count==0 and not f.pool['0:4'].stackCount:IsShown())
armor:RunScript('OnClick','LeftButton'); assert(itemActions[3][1]==1 and itemActions[3][2]==1 and f.pool['1:1']==armor)
p.bagIncludeKeyring=false; BAGS.Apply(); assert(not f.pool['-2:1']:IsShown()); p.bagIncludeKeyring=true
f.view='multibag'; BAGS.Refresh('bags'); assert(Headers()=='Backpack (3 / 4)|Bag 1 (1 / 2)|Keyring (1 / 1)',Headers())
f.view='onebag'; bagSlots[1]=160; p.bagColumns=4; BAGS.Apply()
assert(f.content:GetHeight()>f:GetHeight() and f:GetHeight()<=650)
bagSlots[1]=2; p.bagColumns=12; f.view='all'
items['1:1'].uncached=true; BAGS.Refresh('bags'); assert(f._uncached)
items['1:1'].uncached=false; BAGS.events:RunScript('OnUpdate',.6); assert(not f._uncached and armor.level:GetText()=='232')
local w=f:GetWidth(); combat=true; p.bagColumns=6; BAGS.Apply(); assert(f:GetWidth()==w)
f:Hide(); OpenBackpack(); assert(f:IsShown() and f:GetWidth()==w)
ToggleBackpack(); assert(not f:IsShown()); ToggleBackpack(); assert(f:IsShown())
combat=false; BAGS.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); assert(f:GetWidth()<w)
assert(not BAGS.views.bank:IsShown())
bankSession=true; BankFrame:Show(); BAGS.events:RunScript('OnEvent','BANKFRAME_OPENED')
local bank=BAGS.views.bank
assert(bank:IsShown() and BankFrame:IsShown() and BankFrame:GetAlpha()==0 and closeBankCount==0)
local bankItem=bank.pool['-1:1']; assert(bankItem.template=='BankItemButtonGenericTemplate')
bankItem:RunScript('OnClick','RightButton'); assert(itemActions[4][1]==-1 and itemActions[4][2]==1)
BAGS.Apply(); assert(BankFrame:GetAlpha()==0)
BAGS.UseNativeBank(); assert(not bank:IsShown() and BankFrame:GetAlpha()==.8 and BankFrame:IsClampedToScreen() and closeBankCount==0)
assert(select(4,BankFrame:GetPoint(1))==20)
BAGS.Apply(); assert(not bank:IsShown() and BankFrame:GetAlpha()==.8)
BAGS.events:RunScript('OnEvent','BANKFRAME_CLOSED'); bankSession=false
bankSession=true; BAGS.events:RunScript('OnEvent','BANKFRAME_OPENED'); assert(bank:IsShown())
p.enhancedBank=false; BAGS.Apply(); assert(not bank:IsShown() and closeBankCount==0 and BankFrame:GetAlpha()==.8)
p.enhancedBank=true; BAGS.Apply(); bank:Hide(); assert(closeBankCount==1 and not bankSession)
BAGS.events:RunScript('OnEvent','BANKFRAME_CLOSED')
local elements=unlockByFolder.EllesmereUIBags
elements[1].savePos(nil,'CENTER','CENTER',50,0); BAGS.Apply(); assert(select(5,f:GetPoint(1))==0)
local db=BAGS.addon.db; BAGS.addon.db=nil; elements[1].savePos(nil,'CENTER','CENTER',0,0); assert(elements[1].loadPos()==nil); BAGS.Apply(); BAGS.addon.db=db
p.enhancedBags=false; BAGS.Apply(); assert(not f:IsShown()); assert(ToggleBackpack()=='native')
p.enhancedBags=true; BAGS.Apply(); ToggleBackpack(); assert(f:IsShown())
assert(IsBagOpen(0)); CloseBag(0); assert(not f:IsShown())
assert(ToggleBag(6)=='native')
''')
load(lua,'EllesmereUIOptions','EUI_Bags_335_Options.lua')
lua.execute('''
allFrames[#allFrames]:RunScript('OnEvent','PLAYER_LOGIN')
local cfg=modules.EllesmereUIBags; assert(cfg and #cfg.pages==2 and cfg.pages[2]=='Bank')
assert(EllesmereUI._ELEMENT_SETTINGS_MAP.EUI335_bank.page=='Bank')
local p=BAGS.GetSettings()
cfg.buildPage('Bags',UIParent,0); FindRow('Columns').setValue(10); assert(p.bagColumns==10)
FindRow('Window Scale').setValue(120); assert(p.bagScale==1.2 and FindRow('Window Scale').getValue()==120)
for _,label in ipairs({'Icon Zoom','Hide Categories with 0 Items','Auto-Size to Fit','Merge Duplicate Items','Desaturate Junk Items','Split Set Gear by Set','Show Set Name on Gear',
    'Default Bag Type','Show BoE Text','Category Title Size','Show Item Level','Enabled Categories','Enabled Currencies','Item Count Text Size','Item Level Text Size',
    'Show Sort Icon','Gold Tracking and History','Show Pinned Items','Show Recent Items','Show Pinned & Recent Tips',"Hide 'Add Category' Tab",'Move Bags Without Shift',
    'Hide OneBag/MultiBag Warning','Junk Marker','Group Armory by Slot','Hide OneBag Randomize Button','Stack Splitter','Show Bag Slot Bar','Show Character Item Counts','Include Keyring'}) do FindRow(label) end
FindRow('Default Bag Type').setValue('onebag'); assert(p.bagDefaultBagType=='onebag' and BAGS.views.bags.view=='onebag')
FindRow('Default Bag Type').setValue('all')
buttons['Show Bags'](); assert(BAGS.views.bags:IsShown() and BAGS.views.bags.sortBtn:IsShown())
FindRow('Show Sort Icon').setValue(false); assert(not BAGS.views.bags.sortBtn:IsShown()); FindRow('Show Sort Icon').setValue(true)
rows={}; cfg.buildPage('Bank',UIParent,0)
FindRow('Group by Category').setValue(true); assert(p.bankGroupByCategory and refreshed)
assert(not FindRow('Hide Empty Slots When Grouped').disabled() and FindRow('Hide Bank Bags in Sidebar').disabled())
FindRow('Columns').setValue(16); assert(p.bankColumns==16)
FindRow('Group by Category').setValue(false)
EllesmereUIDB.bagPinnedItems[1]=true; cfg.onReset(); assert(next(EllesmereUIDB.bagPinnedItems or {})==nil and invalidated)
''')
print('PASS: Bags lifecycle, native item actions, search, pins, merge, recent, assignment, views, bank session/restore, combat deferral, positions and both option pages')
bag_tile=tile(lua,'EUI_Fonts_Options.lua','TileBags','TileMinimap')
lua.execute('rows={}'); bag_tile(lua.globals().UIParent,0,lua.globals().EllesmereUI.Widgets,lua.table_from({'folder':'EllesmereUIBags','display':'Bags'}))
lua.execute('''
FindRow('Item Count Text Size').setValue(15); assert(BAGS.views.bags.pool['0:2'].stackCount.font[2]==15)
FindRow('Set Name Text Size').setValue(12); assert(BAGS.GetSettings().bagSetNameFontSize==12)
FindRow('BoE Text Size'); for _,row in ipairs(rows) do assert(row.text~='BoE / Warbound Text Size') end
''')
print('PASS: real Global Fonts Bags tile writes live item counts, set name and BoE sizes without the Warbound label')
off,_=runtime()
off_bags=load(off,'EllesmereUIBags',BAG_FILES[0]); off.globals().BAGS=off_bags
for bag_file in BAG_FILES[1:]: load(off,'EllesmereUIBags',bag_file,off_bags)
off.execute('nativeToggle=ToggleBackpack; nativeIsOpen=IsBagOpen')
off_bags.addon.OnInitialize(off_bags.addon); off.execute('BAGS.GetSettings().enhancedBags=false')
off_bags.addon.OnEnable(off_bags.addon)
off.execute('''
assert(ToggleBackpack==nativeToggle and IsBagOpen==nativeIsOpen,'Bags off: native bag globals must stay untouched')
BAGS.GetSettings().enhancedBags=true; BAGS.Apply()
assert(ToggleBackpack~=nativeToggle and BAGS.bagsTakenOver,'Enabling Bags later installs the bag hooks')
local hooked=ToggleBackpack; BAGS.Apply(); assert(ToggleBackpack==hooked,'Bag hooks install once')
''')
print('PASS: Bags leaves the native bag globals untouched while Enable Bags is off')
# Resource Bars behaviour lives in validate_resourcebars.py.
