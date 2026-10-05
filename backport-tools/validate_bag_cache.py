"""Real bag runtime: live bag equipment versus independent offline snapshots."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
lua=LuaRuntime()
for file in ['backport-tools/wrath_mock.lua','backport-tools/inventory_resources_mock.lua','EllesmereUI/EllesmereUI_Lite.lua']:
    lua.execute((root/file).read_text(encoding='utf-8-sig'))
ns=lua.table()
for file in ['EUI_Bags_335.lua','EUI_Bags_335_Cache.lua','EUI_Bags_335_Categories.lua','EUI_Bags_335_Window.lua','EUI_Bags_335_Broker.lua']:
    lua.execute((root/'EllesmereUIBags'/file).read_text(encoding='utf-8-sig'),'EllesmereUIBags',ns)
lua.globals().B=ns
lua.execute('''
function CopyTable(t) local copy={}; for k,v in pairs(t) do copy[k]=type(v)=='table' and CopyTable(v) or v end; return copy end
B.addon:OnInitialize(); B.addon:OnEnable()
local p=B.GetSettings(); local f,bank=B.views.bags,B.views.bank
local store=B.InventoryStore(); local record=B.CharacterRecord('Test Realm','player')
assert(record.bags and not record.bank and record.money==12345)
assert(p.bagShowSlots==false)
p.bagShowSlots=true; B.Show('bags'); assert(f.bagSlots[0]:IsShown() and f.bagSlots[1]:IsShown() and f.bagSlots[-2]:IsShown())
assert(f.bagWindow:IsShown() and select(2,f.bagWindow:GetPoint(1))==f and f.bagSlots[0]:GetParent()==f.bagWindow)
f.bagSlots[1]:RunScript('OnClick'); assert(f.selectedBag==1 and f.pool['1:1']:IsShown() and not f.pool['0:1']:IsShown())
f.bagSlots[1]:RunScript('OnClick'); assert(f.selectedBag==nil and f.pool['0:1']:IsShown())
cursorItem=true; f.bagSlots[1]:RunScript('OnReceiveDrag'); f.bagSlots[0]:RunScript('OnClick'); f.bagSlots[-2]:RunScript('OnReceiveDrag')
assert(bagActions[1][1]=='put' and bagActions[1][2]==ContainerIDToInventoryID(1) and bagActions[2][1]=='backpack' and bagActions[3][1]=='keyring')
cursorItem=false; f.bagSlots[1]:RunScript('OnDragStart'); assert(bagActions[4][1]=='pickup')
f.bankButton:RunScript('OnClick'); assert(bank:IsShown() and bank.title:GetText():find('(Saved)',1,true) and bank.footer:GetText():find('not ready',1,true) and not bank.native:IsShown())
assert(not next(bank.pool) and not next(bank.savedPool) and closeBankCount==0)
bank:Hide(); assert(closeBankCount==0,'Offline close contacted bank server')
-- Keep recording while the unified window is closed and during combat.
f:Hide(); items['0:2'].count=18; combat=true; B.events:RunScript('OnEvent','BAG_UPDATE')
assert(record.bags.containers[0].items[2].count==18 and not f:IsShown())
combat=false; B.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED')
bankSession=true; BankFrame:Show(); B.events:RunScript('OnEvent','BANKFRAME_OPENED')
assert(record.bank and record.bank.containers[-1].items[1].link=='item:6' and bank.pool['-1:1']:GetScript('OnClick')==NativeItemClick)
assert(bank.bagSlots[5].purchased and not bank.bagSlots[6].purchased)
cursorItem=true; bank.bagSlots[5]:RunScript('OnReceiveDrag'); cursorItem=false
assert(bagActions[#bagActions][2]==BankButtonIDToInvSlotID(5,1))
bank.bagSlots[6]:RunScript('OnClick'); assert(purchasePopup[1]=='EUI335_BUY_BANK_SLOT' and purchasedBankSlots==1)
combat=true; StaticPopupDialogs.EUI335_BUY_BANK_SLOT.OnAccept(); assert(purchasedBankSlots==1)
combat=false; bank.bagSlots[6]:RunScript('OnClick'); StaticPopupDialogs.EUI335_BUY_BANK_SLOT.OnAccept(); assert(purchasedBankSlots==2)
bagSlots[6]=2; B.events:RunScript('OnEvent','PLAYERBANKBAGSLOTS_CHANGED'); assert(bank.bagSlots[6].purchased and record.bank.purchased==2)
-- Bank changes remove stale entries rather than merging into old contents.
items['-1:1'].count=4; B.events:RunScript('OnEvent','PLAYERBANKSLOTS_CHANGED'); assert(record.bank.containers[-1].items[1].count==4)
items['-1:1']=nil; B.events:RunScript('OnEvent','PLAYERBANKSLOTS_CHANGED'); assert(not record.bank.containers[-1].items[1])
items['-1:1']={link='item:6',name='Bank Sword',quality=2,level=180,type='Weapon',equip='INVTYPE_WEAPON',count=4}
B.events:RunScript('OnEvent','PLAYERBANKSLOTS_CHANGED')
bankSession=false; B.events:RunScript('OnEvent','BANKFRAME_CLOSED'); assert(not bank:IsShown())
B.OpenCharacterBank(); local saved=bank.savedPool['-1:1']
assert(saved.kind=='Button' and saved.SetCheckedTexture==nil)
assert(bank.pool['-1:1'].kind=='CheckButton' and bank.pool['-1:1'].checked=='')
assert(saved:IsShown() and not bank.pool['-1:1']:IsShown() and not saved.template and not saved:GetScript('OnClick') and not saved:GetScript('OnDragStart') and not saved:GetScript('OnReceiveDrag'))
assert(saved.stackCount:IsShown() and saved.stackCount:GetText()=='4' and saved.stackCount:GetDrawLayer()=='OVERLAY')
saved:RunScript('OnEnter'); assert(GameTooltip.link=='item:6')
local bankData=record.bank; B.events:RunScript('OnEvent','PLAYER_ENTERING_WORLD'); B.events:RunScript('OnEvent','PLAYER_MONEY'); assert(record.bank==bankData,'Closed bank snapshot was overwritten')
-- Account records are keyed by both realm and name, and survive profile reset.
local alt=B.CharacterRecord('Test Realm','Alt',true); alt.money=500; alt.bags=CopyTable(record.bags); alt.bank=CopyTable(record.bank)
alt.bags.containers[0].items[2].count=7; alt.bank.containers[-1].items[1].count=9
local duplicate=B.CharacterRecord('Other Realm','Alt',true); duplicate.bags=CopyTable(alt.bags); duplicate.bags.containers[0].items[2].count=2
assert(#B.Characters()==3 and record.bags.containers[0].items[2].count==18)
local actions=#itemActions; local equipment=#bagActions
B.SelectCharacter('bags','Test Realm','Alt'); assert(not B.IsLiveView(f) and f.savedPool['0:2'].stackCount:GetText()=='7' and not f.pool['0:2']:IsShown())
assert(f.savedPool['0:2'].stackCount:IsShown() and not f.savedPool['0:1'].stackCount:IsShown() and not f.savedPool['0:4'])
cursorItem=true; f.bagSlots[1]:RunScript('OnReceiveDrag'); f.bagSlots[1]:RunScript('OnDragStart'); f.savedPool['0:2']:RunScript('OnClick','RightButton')
assert(#itemActions==actions and #bagActions==equipment,'Saved view changed live items'); cursorItem=false
f.search:SetText('potion'); assert(f.savedPool['0:2']:GetAlpha()==1 and f.savedPool['0:1']:GetAlpha()==.2); f.search:SetText('')
f.bagSlots[1]:RunScript('OnClick'); assert(f.selectedBag==1 and f.savedPool['1:1']:IsShown() and not f.savedPool['0:2']:IsShown())
f.bagSlots[1]:RunScript('OnClick'); assert(f.selectedBag==nil)
B.SelectCharacter('bank','Test Realm','Alt'); assert(bank.savedPool['-1:1'].stackCount:GetText()=='9' and not B.IsLiveView(bank))
bank.bagSlots[6]:RunScript('OnClick'); assert(#bagActions==equipment)
B.SelectCharacter('bags','Other Realm','Alt'); assert(f.savedPool['0:2'].stackCount:GetText()=='2')
local totals=B.ItemTotals('item:2'); assert(#totals==3); local sum=0; for _,t in ipairs(totals) do sum=sum+t.bags end; assert(sum==27)
f.characters:RunScript('OnClick'); assert(f.selector:IsShown() and #f.selector.rows==3); f.selector.rows[3]:RunScript('OnClick'); assert(not f.selector:IsShown())
local cache=B.InventoryStore(); B.addon.db:ResetProfile(); B.Apply(); assert(B.InventoryStore()==cache and B.CharacterRecord('Test Realm','Alt').bank.containers[-1].items[1].count==9)
EllesmereUIInventoryDB=CopyTable(cache); B.SelectCharacter('bank','Test Realm','Alt'); assert(bank.savedPool['-1:1'].stackCount:GetText()=='9','Reloaded SavedVariables snapshot inaccessible')
local frames=#allFrames; B.Refresh('bank'); B.Refresh('bank'); assert(#allFrames==frames)
B.OpenCharacterBank(); assert(bank.savedPool['-1:1'].stackCount:GetText()=='4')
B.Show('bags'); assert(B.IsLiveView(f) and f.pool['0:2']:IsShown() and not f.savedPool['0:2']:IsShown())
p=B.GetSettings(); p.bagShowSlots=false; B.Apply(); assert(not f.bagWindow:IsShown())
-- A bank opening switches from saved/alt content to the current live bank.
bankSession=true; B.events:RunScript('OnEvent','BANKFRAME_OPENED'); assert(B.IsLiveView(bank) and bank.pool['-1:1']:IsShown() and not bank.savedPool['-1:1']:IsShown())
bank.pool['-1:1']:RunScript('OnClick','RightButton'); assert(itemActions[#itemActions][1]==-1)
B.UseNativeBank(); assert(BankFrame:GetAlpha()==.8 and not bank:IsShown() and bankSession)
B.events:RunScript('OnEvent','BANKFRAME_CLOSED'); bankSession=false
''')
lua.execute((root/'EllesmereUIOptions/EUI_Bags_335_Options.lua').read_text(encoding='utf-8-sig'))
lua.execute('''
allFrames[#allFrames]:RunScript('OnEvent','PLAYER_LOGIN'); rows={}; modules.EllesmereUIBags.buildPage('Bags',UIParent,0)
FindRow('Show Bag Slot Bar').setValue(true); assert(B.GetSettings().bagShowSlots)
FindRow('Show Character Item Counts').setValue(false); assert(not B.GetSettings().bagShowAltCounts)
buttons['Show Character Bank'](); assert(B.views.bank:IsShown())
''')
lua.execute('''
local f=B.views.bags; B.Show('bags'); f.view='onebag'; items['0:3'].locked=false; items['0:2'].count=12
local function Drain() for _=1,60 do now=now+1; for _,fr in ipairs(allFrames) do if fr.scripts and fr.scripts.OnUpdate then fr:RunScript('OnUpdate',1) end end; if not B.IsSorting() then return end end; error('sort never finished') end
local function Order() local out={}; for _,k in ipairs({'0:1','0:2','0:3','0:4','1:1','1:2'}) do out[#out+1]=items[k] and items[k].name or '-' end; return table.concat(out,',') end
B.SortClick(f); assert(B.confirmDialog:IsShown() and not B.IsSorting())
B.confirmDialog.check:RunScript('OnClick'); B.confirmDialog.ok:RunScript('OnClick'); assert(EllesmereUIDB.bagSortWarningDismissed and B.IsSorting())
Drain(); assert(Order()=='Armor,Sword,Healing Potion,Junk,-,-',Order())
B.GetSettings().bagSortToBottom=true; f._sortLocked=nil; B.SortClick(f); assert(B.IsSorting()); Drain()
assert(Order()=='-,-,Armor,Sword,Healing Potion,Junk',Order())
''')
print('PASS: physical OneBag sort (confirm/dismiss, gear-first order, Sort to Bottom) using native pickups')
lua.execute('''
local f=B.views.bags; B.Show('bags')
assert(f.settingsBtn:IsShown()); shownModule=nil; f.settingsBtn:RunScript('OnClick'); assert(optionsLoaded and shownModule=='EllesmereUIBags')
B.SelectCharacter('bags','Other Realm','Alt'); assert(f.selectedRealm=='Other Realm')
EllesmereUIDB.bagCurrencyByChar={['Other Realm-Alt']={1}}
f.characters:RunScript('OnClick'); local list=f.selector.rows
assert(list[1].del:IsShown() and list[2].del:IsShown() and not list[3].del:IsShown(),'Logged-in character offers delete')
list[1].del:RunScript('OnClick'); assert(B.confirmDialog:IsShown() and B.CharacterRecord('Other Realm','Alt'))
B.confirmDialog.ok:RunScript('OnClick')
assert(not B.CharacterRecord('Other Realm','Alt') and not B.InventoryStore().realms['Other Realm'] and not EllesmereUIDB.bagCurrencyByChar['Other Realm-Alt'])
assert(f.selectedRealm=='Test Realm' and f.selectedName=='player' and B.IsLiveView(f) and not list[3]:IsShown())
assert(not B.DeleteCharacter('Test Realm','player') and B.CharacterRecord('Test Realm','player'))
rows={}; modules.EllesmereUIBags.buildPage('Bags',UIParent,0); local dd=FindRow('Delete Saved Character')
assert(dd.values['Test Realm\\001Alt'] and not dd.values['Test Realm\\001player'] and not dd.disabled())
invalidated=false; dd.setValue('Test Realm\\001Alt'); B.confirmDialog.ok:RunScript('OnClick')
assert(not B.CharacterRecord('Test Realm','Alt') and invalidated and #B.Characters()==1)
rows={}; modules.EllesmereUIBags.buildPage('Bags',UIParent,0); assert(FindRow('Delete Saved Character').disabled())
''')
print('PASS: header settings button, character deletion from the selector and options (confirmed, current character protected, views reset)')
print('PASS: bags/bank floating slot strips, native equip/drop/filter/purchase, bank cached away from banker, independent realm/alt snapshots, closed-window/combat recording, stale removal, read-only pools, search/counts, profile/reset/reload persistence, selector/options and exact live/native bank restoration.')
