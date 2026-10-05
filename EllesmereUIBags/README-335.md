# Bags 3.3.5a — 0.7

0.7 records each character's gold independently of bag capacity in the
EUI-owned account SavedVariables cache. Saved bag views display that alt's
balance; hover the footer for individual balances, realm total and combined
total. Offline balances are the last recorded values, not live server data.
Broker tooltips include the same totals. Item subclasses are cached with
snapshots. Categories now include Crafting Reagents (Trade Goods/Reagents),
Food & Drink, Potions, Flasks & Elixirs, and Other Consumables. Item Category
filters the view without changing physical slots or moving items. Localized
class/subclass names are resolved from native cached item information.

0.6 fixes SetCheckedTexture on saved bank/alt buttons. These are plain
Button objects for read-only snapshots; only live CheckButtons clear checked
textures. The fixture now enforces this native method distinction, reproduces
the reported error before the fix, and passes afterward.

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
