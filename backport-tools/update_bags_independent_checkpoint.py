"""Build 0.24: independent EUI inventory persistence; remove external imports."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
path=root/'EllesmereUIBags/EUI_Bags_335_Broker.lua'; text=path.read_text(encoding='utf-8-sig')
assert 'local function IDs(kind)' in text and 'function ns.RefreshBagnonData()' in text
text=text[:text.index('local function IDs(kind)')]+text[text.index('local function Totals(snapshot)'):text.index('function ns.RefreshBagnonData()')]
assert 'Bagnon' not in text
path.write_text(text,encoding='utf-8')
for file in ['validate_bag_cache.py']:
    path=root/'backport-tools'/file; text=path.read_text(encoding='utf-8-sig').replace('EllesmereUIDB.wrathInventoryCache=CopyTable(cache)','EllesmereUIInventoryDB=CopyTable(cache)').replace("bank.footer:GetText():find('not saved',1,true)","bank.footer:GetText():find('not ready',1,true)")
    path.write_text(text,encoding='utf-8')
path=root/'backport-tools/package_project.py'; text=path.read_text(encoding='utf-8-sig').replace("add(root/'Bagnon_Forever/db.lua')\n",'')
path.write_text(text,encoding='utf-8')
for folder,old,new in [('EllesmereUIBags','0.4','0.5'),('EllesmereUIOptions','0.28','0.29')]:
    path=root/folder/(folder+'.toc'); text=path.read_text(encoding='utf-8-sig')
    before='## Version: 9.3.4-335-'+old; assert before in text,path
    path.write_text(text.replace(before,'## Version: 9.3.4-335-'+new),encoding='utf-8')
path=root/'backport-tools/package_unitframes.py'; text=path.read_text(encoding='utf-8-sig')
for before,after in [("'EllesmereUIBags':'9.3.4-335-0.4'","'EllesmereUIBags':'9.3.4-335-0.5'"),("'EllesmereUIOptions':'9.3.4-335-0.28'","'EllesmereUIOptions':'9.3.4-335-0.29'"),('EllesmereUIBags-3.3.5-0.4.zip','EllesmereUIBags-3.3.5-0.5.zip'),('EllesmereUIOptions-3.3.5-0.28.zip','EllesmereUIOptions-3.3.5-0.29.zip'),('EllesmereUI-3.3.5-HUD-test-0.23.zip','EllesmereUI-3.3.5-HUD-test-0.24.zip')]:
    assert before in text,before; text=text.replace(before,after)
path.write_text(text,encoding='utf-8')
path=root/'EllesmereUIBags/README-335.md'
path.write_text('''# Bags 3.3.5a — 0.5

Inventory storage is entirely owned by EllesmereUI. EllesmereUIInventoryDB is
declared as account SavedVariables in the Bags TOC and saved in the game's
EllesmereUIBags.lua file. Realm/character inventories are separate from layout
profiles and the Core database. Each character records its bags automatically
on login, item events, every five seconds and logout, even with the window
closed or during combat. Bank snapshots record only during a banker session.
Startup with unavailable backpack/bank capacity cannot overwrite good data.
Visit each alt and its bank to populate data; logout/reload writes it to disk.

Bags > Save Inventory & Reload UI captures current contents and requests a
normal UI reload to persist them. The cache summary shows recorded characters,
inventories and banks. Characters in the inventory/bank windows selects saved
views. Saved item buttons are read-only and show snapshot timestamps. The
native bank window can be restored during an active bank session.

Existing directly recorded EUI snapshots migrate once from the old Core cache.
External import functions, preferences and optional addon dependencies have
been removed. Legacy externally sourced snapshots are excluded from migration.
No data from other addons is accessed. The LibDataBroker object uses libraries
already bundled with the EUI Core; EUI recording and views work without any
external broker display or other inventory addon. Broker inventory APIs return
copies, with slot-count text, per-character tooltip and bag/bank clicks.

Native item buttons retain item clicks, stack splitting and drag actions.
Stack quantities above one explicitly show as white OVERLAY text; empty/single
slots hide the label and native numeric count metadata stays separate.
Search dims nonmatching items; category/name sorting rearranges only the view.
Bag slot strips show equipped bags/capacities, support click filters and live
item drop/bag pickup. Unpurchased bank slots require purchase confirmation.
Keyring, empty slots, quality borders, cooldowns, item levels, global fonts,
window/grid/scale/crop settings and Edit Mode positions remain available.
Action Bars > Select Bar > Bag Bar > Consolidate Bags reduces only the HUD.

Only EUI_Bags_335.lua, EUI_Bags_335_Cache.lua and EUI_Bags_335_Broker.lua load.
Retail Lua/media remain unchanged unloaded references. Automated selling and
physical item sorting are not included.

Tests: validate_inventory_resources.py covers native actions/layout/bank and
shared fonts. validate_bag_cache.py covers bag slots, saved views and ownership
counts. validate_bag_broker.py covers bundled LDB with EUI-recorded data only.
validate_inventory_persistence.py uses separate Lua client sessions and real
SavedVariables serialization/load to check alts, bank/stack data, startup,
periodic/combat recording, migration and explicit save/reload. Real client
rendering and character switch/relogin confirmation still require testing.
''',encoding='utf-8')
entry='''Latest build: HUD-test-0.24. Bags 0.5 / Options 0.29; other versions unchanged.

User reported inventory not storing and explicitly removed authorization to
use other addons' data. All external import functions/options/optional deps
are removed. Inventory is now EllesmereUIInventoryDB, an account SavedVariables
global owned by the Bags TOC, separate from Core/layout profiles. Legacy direct
EUI snapshots migrate once; externally sourced snapshots are excluded. The
actual existing EUI save file contained two direct characters, two bag snapshots
and two banks, confirming at least some earlier recording occurred; no precise
client failure cause is claimed. Startup with zero backpack/bank capacity no
longer replaces existing data. Pure-data recording runs every five seconds,
on native events and logout, even with windows closed/in combat. Bank reads
remain restricted to active banker sessions. Save Inventory & Reload UI gives
an explicit native serialization action; options include cache totals.

The broker object uses only the libraries bundled in EUI Core. Recording,
saved views and account persistence work without an external display or any
other inventory addon. Project pack no longer includes the external database
test reference; historical transition scripts are not to be rerun.

Validation includes separate Lua sessions with actual SavedVariables text
serialization and reloading for character/realm switching, direct bank/stack
records, startup-empty preservation, periodic/combat capture, explicit reload,
old direct-data migration, Core/profile replacement independence and absent
external addons. Bundled LDB, inventory/resource, account-cache checks and
193 Lua 5.1 compilation pass. Twelve addon folders/thirteen archives verified;
client persistence/display confirmation pending. Old archives retained.

Previous checkpoint: HUD-test-0.23. Bags 0.4 / Options 0.28; other versions unchanged.
The following external integration has been superseded and removed in 0.24.'''
for name in ['CODEX_HANDOFF_EllesmereUI_335_CURRENT.md','ELLESMEREUI_335_BACKPORT_STATUS.md']:
    path=root/name; text=path.read_text(encoding='utf-8-sig')
    before='Latest build: HUD-test-0.23. Bags 0.4 / Options 0.28; other versions unchanged.'; assert before in text,name
    text=text.replace(before,entry,1)
    if name.startswith('CODEX'):
        text=text.replace('| EllesmereUIBags | 9.3.4-335-0.4 |','| EllesmereUIBags | 9.3.4-335-0.5 |').replace('| EllesmereUIOptions | 9.3.4-335-0.28 |','| EllesmereUIOptions | 9.3.4-335-0.29 |').replace('Full build: EllesmereUI-3.3.5-HUD-test-0.23.zip','Full build: EllesmereUI-3.3.5-HUD-test-0.24.zip')
    path.write_text(text,encoding='utf-8')
path=root/'ELLESMEREUI_PROJECT_PACK.md'; text=path.read_text(encoding='utf-8-sig').replace('build 0.23','build 0.24').replace('EllesmereUI-3.3.5-HUD-test-0.23.zip','EllesmereUI-3.3.5-HUD-test-0.24.zip')
text=text.replace('Build 0.23 adds a LibDataBroker inventory source and optional Bagnon Forever\nalt cache import, following build 0.22 stack fixes and 0.21 inventory updates.','Build 0.24 makes inventory storage independent with its own account save file,\nstartup guards, periodic recording and explicit save/reload; external imports\nand dependencies are removed. Only Core-bundled libraries power the broker.')
text=text.replace('installation. Bagnon_Forever/db.lua is also included as an exact test reference;\nthis is not a Bagnon installation. Earlier build ZIPs and unrelated addons are\nnot part of the pack.','installation. Earlier build ZIPs and unrelated addons are not part of the pack.')
path.write_text(text,encoding='utf-8')
print('PASS: Bags 0.5 / Options 0.29 / build 0.24 independent inventory checkpoint recorded.')
