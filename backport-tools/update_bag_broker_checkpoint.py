"""Record build 0.23 LibDataBroker and Bagnon Forever inventory integration once."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
for folder,old,new in [('EllesmereUIBags','0.3','0.4'),('EllesmereUIOptions','0.27','0.28')]:
    path=root/folder/(folder+'.toc'); text=path.read_text(encoding='utf-8-sig')
    before='## Version: 9.3.4-335-'+old; assert before in text,path
    path.write_text(text.replace(before,'## Version: 9.3.4-335-'+new),encoding='utf-8')
path=root/'backport-tools/package_unitframes.py'; text=path.read_text(encoding='utf-8-sig')
for before,after in [("'EllesmereUIBags':'9.3.4-335-0.3'","'EllesmereUIBags':'9.3.4-335-0.4'"),("'EllesmereUIOptions':'9.3.4-335-0.27'","'EllesmereUIOptions':'9.3.4-335-0.28'"),('EllesmereUIBags-3.3.5-0.3.zip','EllesmereUIBags-3.3.5-0.4.zip'),('EllesmereUIOptions-3.3.5-0.27.zip','EllesmereUIOptions-3.3.5-0.28.zip'),('EllesmereUI-3.3.5-HUD-test-0.22.zip','EllesmereUI-3.3.5-HUD-test-0.23.zip')]:
    assert before in text,before; text=text.replace(before,after)
path.write_text(text,encoding='utf-8')
path=root/'EllesmereUIBags/README-335.md'; text=path.read_text(encoding='utf-8-sig').replace('# Bags 3.3.5a — 0.3','# Bags 3.3.5a — 0.4')
entry='''0.4 adds the LibDataBroker data source "EllesmereUI Bags" using the libraries
already loaded by the Core. Broker displays can show free/total slots, open
bags with left-click and saved bank with right-click. The tooltip summarizes
items held in each character's bags/bank. GetCharacters/GetInventory expose
copies for broker consumers; account SavedVariables remain the persistence
layer. LibDataBroker itself does not save inventory data.

Bags > Use Bagnon Saved Data and Import Bagnon Alt Data read the installed
Bagnon Forever format when that optional addon is loaded. Imports include
realms, alts, equipped bags, bank slots, quantities and full item variants.
They fill missing EUI snapshots and refresh prior imports; directly observed
EUI data always wins. Bagnon's database is never changed or force-loaded.
Uncached imported items retain IDs/counts and hydrate icons when item metadata
arrives. Bagnon Forever has no snapshot timestamps, so imported views say
"save time unknown". Purchased bank slots alone do not imply a cached bank.
Imported data stays in EUI's account cache if Bagnon is subsequently disabled.
EUI's own recorder works independently of Bagnon and broker display addons.

'''
text=text.replace('0.3 fixes missing stack quantities.',entry+'0.3 fixes missing stack quantities.',1)
text=text.replace('only EUI_Bags_335.lua and EUI_Bags_335_Cache.lua are loaded. Retail Warband, housing, upgrade-rank and','only EUI_Bags_335.lua, EUI_Bags_335_Cache.lua and EUI_Bags_335_Broker.lua\nare loaded. Retail Warband, housing, upgrade-rank and')
text+='\nvalidate_bag_broker.py executes the actual Core LDB/CallbackHandler libraries\nand installed Bagnon Forever access methods, checking import format, immutable\nsource data, direct-data priority, absent/late provider, persisted account\nviews, broker events/tooltip/clicks and copied inventory APIs.\n'
path.write_text(text,encoding='utf-8')
entry='''Latest build: HUD-test-0.23. Bags 0.4 / Options 0.28; other versions unchanged.

User requested DataBroker like Bagnon for cross-alt inventory. The installed
Bagnon version uses Bagnon Forever for persistence; LDB is its display/plugin
interface. EUI now publishes "EllesmereUI Bags" through the real Core LDB
library: free/total slot text, left-click inventory, right-click saved bank,
per-character bag/bank totals in tooltip, GetCharacters/GetInventory copied
data for consumers. Persistence remains EllesmereUIDB.wrathInventoryCache,
independent of layout profiles and optional display addons.

Use Bagnon Saved Data defaults on; Import Bagnon Alt Data syncs available
BagnonForeverDB records when Bagnon_Forever is loaded (optional dependency).
Import handles realm/name isolation, negative bank/keyring indices, equipped
bag headers, purchased slots, short/full item variants, stack counts and money.
Uncached item IDs/counts remain present and icons hydrate on item-cache retry.
Imported views identify unknown original save time. Purchased slot metadata
alone does not fabricate bank contents. EUI direct snapshots always win; only
missing or previously imported snapshots refresh. Bagnon data is not modified
or force-loaded. Imported snapshots remain usable after Bagnon is disabled.
EUI's own recording does not require Bagnon or a broker display.

Validation: validate_bag_broker.py executes actual LDB/CallbackHandler libraries
and installed Bagnon Forever access methods. Checks cover registration/change
events, clicks/tooltip, copied data APIs, provider format, realms/alts/stacks/
suffixes, uncached icons, immutable source, direct priority, unknown banks/time,
save/reload/profile survival, absent/late provider and native options. Inventory,
resource and account-cache regressions pass; 193 Lua 5.1 files compile. Client
confirmation pending. Twelve addon folders/thirteen release archives plus the
updated project pack are verified. Project pack includes Bagnon_Forever/db.lua
as a narrow test reference; player SavedVariables are excluded.

Previous checkpoint: HUD-test-0.22. Bags 0.3; other versions unchanged.'''
for name in ['CODEX_HANDOFF_EllesmereUI_335_CURRENT.md','ELLESMEREUI_335_BACKPORT_STATUS.md']:
    path=root/name; text=path.read_text(encoding='utf-8-sig')
    before='Latest build: HUD-test-0.22. Bags 0.3; other versions unchanged.'; assert before in text,name
    text=text.replace(before,entry,1)
    if name.startswith('CODEX'):
        text=text.replace('| EllesmereUIBags | 9.3.4-335-0.3 |','| EllesmereUIBags | 9.3.4-335-0.4 |').replace('| EllesmereUIOptions | 9.3.4-335-0.27 |','| EllesmereUIOptions | 9.3.4-335-0.28 |').replace('Full build: EllesmereUI-3.3.5-HUD-test-0.22.zip','Full build: EllesmereUI-3.3.5-HUD-test-0.23.zip')
    path.write_text(text,encoding='utf-8')
path=root/'ELLESMEREUI_PROJECT_PACK.md'; text=path.read_text(encoding='utf-8-sig').replace('build 0.22','build 0.23').replace('EllesmereUI-3.3.5-HUD-test-0.22.zip','EllesmereUI-3.3.5-HUD-test-0.23.zip')
text=text.replace('Build 0.22 fixes hidden stack counts in live/saved bag and bank views, following\nbuild 0.21 bag-slot strips, bank/alt caching and HUD consolidation. Checks pass and','Build 0.23 adds a LibDataBroker inventory source and optional Bagnon Forever\nalt cache import, following build 0.22 stack fixes and 0.21 inventory updates.\nChecks pass and')
text=text.replace('installation. Earlier build ZIPs and unrelated addons are not part of the pack.','installation. Bagnon_Forever/db.lua is also included as an exact test reference;\nthis is not a Bagnon installation. Earlier build ZIPs and unrelated addons are\nnot part of the pack.')
path.write_text(text,encoding='utf-8')
print('PASS: Bags 0.4 / Options 0.28 / build 0.23 broker/import checkpoint recorded.')
