"""Native Wrath API/lifecycle checks for both new modules; in-game QA still required."""
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

BAG_FILES=['EUI_Bags_335.lua','EUI_Bags_335_Cache.lua','EUI_Bags_335_Categories.lua','EUI_Bags_335_Window.lua','EUI_Bags_335_Broker.lua']
for folder in ['EllesmereUIBags','EllesmereUIResourceBars']:
    retail=Path('D:/World of Warcraft/_retail_/Interface/AddOns')/folder
    for original in retail.rglob('*'):
        if original.is_file() and original.suffix.lower()!='.toc':
            assert original.read_bytes()==(root/folder/original.relative_to(retail)).read_bytes(),original
    toc=(root/folder/(folder+'.toc')).read_text(encoding='utf-8-sig')
    assert '## Interface: 30300' in toc
    loaded=[line.strip() for line in toc.splitlines() if line.strip() and not line.startswith('#')]
    assert loaded==(BAG_FILES if folder.endswith('Bags') else ['EUI_ResourceBars_335.lua'])

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
assert(Sidebar()=='All Items|OneBag|MultiBag|Pinned Items|Recent Items|The Armory|Weapons / Trinkets|Armor|Adventure Prep|Consumables|Keys|Miscellaneous|Add Category',Sidebar())
assert(Headers()=='Pinned Items|Recent Items|The Armory (2)|Adventure Prep (1)|Keys (1)|Miscellaneous (1)',Headers())
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
    'Hide OneBag/MultiBag Warning','Group Armory by Slot','Hide OneBag Randomize Button','Stack Splitter','Show Bag Slot Bar','Show Character Item Counts','Include Keyring'}) do FindRow(label) end
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

for player_class in ['WARRIOR','ROGUE','DRUID','DEATHKNIGHT','SHAMAN']:
    lua,safe=runtime(player_class)
    resource=load(lua,'EllesmereUIResourceBars','EUI_ResourceBars_335.lua'); lua.globals().RB=resource
    safe(resource.addon.OnInitialize,resource.addon); safe(resource.addon.OnEnable,resource.addon)
    lua.execute('''
local p=RB.GetSettings(); local f=RB.frames
assert(_ERB_AceDB==RB.addon.db and _ERB_Apply==RB.Apply)
assert(f.primary:IsShown() and not f.health:IsShown() and not f.castBar:IsShown())
assert(f.primary.bar.value==50 and f.primary.bar.maximum==100 and f.primary.bar.text:GetText()=='50 / 100')
assert(CastingBarFrame:GetAlpha()==.7)
maxPower=0; RB.UpdateVitals(); assert(not f.primary:IsShown() and f.primary.bar.maximum==1)
maxPower=100; powerType=1; powerToken='RAGE'; RB.UpdateVitals(); assert(f.primary.bar.color[1]==1 and f.primary.bar.color[2]==0)
p.castBar.enabled=true; p.gcdBar.enabled=true; p.health.enabled=true; RB.Apply(); assert(CastingBarFrame:GetAlpha()==0)
CastingBarFrame:SetAlpha(1); assert(CastingBarFrame:GetAlpha()==0)
now=10; nativeCast={'Fireball','Rank 1','Fireball','fire-icon',9000,12000,false,1}; RB.events:RunScript('OnEvent','UNIT_SPELLCAST_START','player')
assert(f.castBar:IsShown() and f.castBar.bar.value==1 and f.castBar.timer:GetText()=='2.0')
nativeCast[6]=13000; RB.events:RunScript('OnEvent','UNIT_SPELLCAST_DELAYED','player'); assert(f.castBar.bar.maximum==4)
nativeCast={'Frostbolt','Rank 1','Frostbolt','frost-icon',10000,14000,false,2}
RB.events:RunScript('OnEvent','UNIT_SPELLCAST_STOP','player','Fireball',1,1); assert(RB.cast.name=='Frostbolt')
nativeCast=nil; nativeChannel={'Drain Life','Rank 1','Drain Life','drain-icon',9000,13000}
RB.events:RunScript('OnEvent','UNIT_SPELLCAST_CHANNEL_START','player'); assert(RB.cast.channel and f.castBar.bar.value==3)
local cb=f.castBar.bar; local tick=cb._euiChannelTicks[1]
assert(#cb._euiChannelTicks==4 and cb._euiChannelTicks[4]:IsShown() and math.abs(select(4,tick:GetPoint(1))-cb:GetWidth()*.8)<.00001)
now=10.016; RB.events:RunScript('OnUpdate',.016); assert(math.abs(cb.value-2.984)<.00001,'Cast fill still throttled at 20Hz')
nativeChannel[6]=12000; RB.events:RunScript('OnEvent','UNIT_SPELLCAST_CHANNEL_UPDATE','player')
assert(RB.cast.ticks.interval==.8 and cb._euiChannelTicks[3]:IsShown() and not cb._euiChannelTicks[4]:IsShown())
p.castBar.showChannelTicks=false; RB.ReadCast(); assert(not tick:IsShown())
p.castBar.showChannelTicks=true; RB.ReadCast(); assert(tick:IsShown() and cb._euiChannelTicks[1]==tick)
now=10
nativeChannel=nil; RB.events:RunScript('OnEvent','UNIT_SPELLCAST_CHANNEL_STOP','player'); assert(not f.castBar:IsShown())
gcdStart=10; gcdDuration=1.5; RB.events:RunScript('OnEvent','SPELL_UPDATE_COOLDOWN'); assert(f.gcdBar:IsShown())
now=10.5; RB.events:RunScript('OnUpdate',.1); assert(f.gcdBar.bar.value==1)
now=12; RB.events:RunScript('OnUpdate',.1); assert(not f.gcdBar:IsShown())
gcdDuration=10; RB.ReadGCD(); assert(not f.gcdBar:IsShown())
local mover=unlockByFolder.EllesmereUIResourceBars[2]; mover.savePos(nil,'CENTER','CENTER',10,0); RB.Apply(); assert(select(5,f.primary:GetPoint(1))==0)
local db=RB.addon.db; RB.addon.db=nil; assert(mover.loadPos()==nil and mover.isHidden()); mover.savePos(nil,'CENTER','CENTER',1,1); mover.clearPos(); mover.applyPos(); RB.addon.db=db
local width=f.primary:GetWidth(); combat=true; p.primary.width=300; RB.Apply(); assert(f.primary:GetWidth()==width)
combat=false; RB.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); assert(f.primary:GetWidth()==300)
p.primary.textSize=16; p.general.barTexture='plating'; _ERB_Apply(); assert(f.primary.bar.text.font[2]==16 and f.primary.bar.statusTexture==_ERB_BarTextures.plating)
p.splitTex=true; p.health.barTexture='fade'; RB.Apply(); assert(f.health.bar.statusTexture==_ERB_BarTextures.fade and f.secondary.bars[1].statusTexture==_ERB_BarTextures.plating)
if playerClass=='ROGUE' then
    assert(f.secondary:IsShown() and f.secondary.bars[3].value==1 and f.secondary.bars[4].value==0 and not f.secondary.bars[6]:IsShown())
elseif playerClass=='DRUID' then
    assert(not f.secondary:IsShown()); powerType=3; RB.events:RunScript('OnEvent','UNIT_DISPLAYPOWER','player'); assert(f.secondary:IsShown()); powerType=0; RB.UpdateClass(); assert(not f.secondary:IsShown())
elseif playerClass=='DEATHKNIGHT' then
    assert(f.secondary:IsShown() and f.secondary.bars[6]:IsShown())
    runes[1]={start=10,duration=10,ready=false,type=4}; now=15; RB.UpdateClass(); assert(f.secondary.bars[1].value==.5 and f.secondary.bars[1].text:GetText()=='5.0')
    runes[1].ready=true; RB.events:RunScript('OnEvent','RUNE_POWER_UPDATE',1); assert(f.secondary.bars[1].value==1 and f.secondary.bars[1].text:GetText()=='')
elseif playerClass=='SHAMAN' then
    totems[1]={name='Searing Totem',start=10,duration=30}; now=15; RB.events:RunScript('OnEvent','PLAYER_TOTEM_UPDATE',1)
    assert(f.totemBar:IsShown() and f.totemBar.bars[1].value==25 and f.totemBar.bars[1].text:GetText()=='25')
    now=41; RB.events:RunScript('OnUpdate',.1); assert(not f.totemBar:IsShown())
else assert(not f.secondary:IsShown() and not f.totemBar:IsShown()) end
EllesmereUI.listeners.EllesmereUIResourceBars(true); assert(f.castBar:IsShown() and f.gcdBar:IsShown())
EllesmereUI.listeners.EllesmereUIResourceBars(false); assert(not f.castBar:IsShown() and not f.gcdBar:IsShown())
p.enabled=false; RB.Apply(); for _,frame in pairs(f) do assert(not frame:IsShown()) end; assert(CastingBarFrame:GetAlpha()==.7)
p.enabled=true; p.castBar.enabled=false; RB.Apply(); assert(f.primary:IsShown() and CastingBarFrame:GetAlpha()==.7)
''')
    load(lua,'EllesmereUIOptions','EUI_ResourceBars_335_Options.lua')
    lua.execute('''
allFrames[#allFrames]:RunScript('OnEvent','PLAYER_LOGIN')
local cfg=modules.EllesmereUIResourceBars; assert(cfg and #cfg.pages==1)
for _,key in ipairs(RB.order) do
    rows={}; RB.SelectWrathBar(key,false); cfg.buildPage('Bars',UIParent,0)
    assert(FindRow('Select Bar').getValue()==key)
    FindRow('Width').setValue(240); assert(RB.frames[key]:GetWidth()==240)
end
FindRow('Select Bar').setValue('primary'); assert(RB.selectedWrathBar=='primary' and invalidated and refreshed)
EllesmereUI._ELEMENT_SETTINGS_MAP.ERB_CastBar.preSelectFn(); assert(RB.selectedWrathBar=='castBar')
''')
    if player_class=='SHAMAN':
        rb_font=tile(lua,'EUI_Fonts_Options.lua','TileResourceBars','TileAuraBuffReminders')
        lua.execute('rows={}')
        rb_font(lua.globals().UIParent,0,lua.globals().EllesmereUI.Widgets,lua.table_from({'folder':'EllesmereUIResourceBars','display':'Resource Bars'}))
        lua.execute("FindRow('Totem Timer Size').setValue(14); assert(RB.frames.totemBar.bars[1].text.font[2]==14)")
        rb_texture=tile(lua,'EUI_Textures_Options.lua','TileResourceBars','TileChat')
        lua.execute('rows={}; links={}')
        rb_texture(lua.globals().UIParent,0,lua.globals().EllesmereUI.Widgets,lua.table_from({'folder':'EllesmereUIResourceBars','display':'Resource Bars'}))
        lua.execute('''
FindRow('Power Bar Texture').setValue('fade'); assert(RB.frames.primary.bar.statusTexture==_ERB_BarTextures.fade)
FindRow('Cast Bar Texture').setValue('glass'); assert(RB.frames.castBar.bar.statusTexture==_ERB_BarTextures.glass)
assert(links[#links][2]=='Bars')
''')
        print('PASS: real Global Fonts/Textures Resource Bars tiles write live timer/fonts/textures and navigate to the Wrath page')
    print(f'PASS: {player_class} power/class bars, cast/channel events, GCD, native restoration, combat, fonts/textures, Edit Mode and all option selections')
