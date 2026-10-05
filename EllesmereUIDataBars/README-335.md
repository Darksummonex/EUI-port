# DataBars 3.3.5a — 0.2

0.2 fixes OnInitialize through the actual Lua 5.1 Lite dispatcher: xpcall
does not forward the self argument on this client, so initialization uses
the captured addon reference. Tests now dispatch ADDON_LOADED/PLAYER_LOGIN
through the real Core rather than invoking lifecycle methods directly.

Open EllesmereUI > DataBars or /edb. A bottom information bar appears on first
login. Create additional bars from Bottom Info Bar, Minimap Companion, Micro
Menu Strip or Empty Bar. Select a bar, rename it and configure its layout,
length/thickness, scale, fonts, visibility and accent/dark appearance. Move it
in Unlock Mode. Bars and their ordered blocks/positions follow EUI profiles.
Global Fonts uses the existing DataBars entry; its Text Scale link opens this
page. Hide/delete bars or add/reorder/remove individual blocks in the same page.

The twenty supported block types use native Wrath data: clock, FPS, latency,
location, coordinates, gold, bag capacity, durability, combat state, XP/rep,
talent specialization/dual spec, professions, secondary professions,
hearthstone, micro menu, currency, equipped average item level, audio, EUI Bags
broker and spacer. Hover for information and click for the relevant native
window. The Hearthstone button uses SecureActionButtonTemplate with item 6948.
Audio supports mute and wheel volume adjustments. Bag/broker clicks integrate
with EUI inventory/bank when available and use native bags otherwise.

XP/rep mode selects XP, watched reputation or automatic XP below max level /
reputation at max. A visible progress block hides the corresponding existing
EUI ActionBars progress holder and mover. Removing/disabling it restores that
bar without rewriting the ActionBars settings. The default information-bar
template leaves the existing XP/rep bars in place. No native frame is reparented
by the DataBars micro-menu shortcuts. Combat/group visibility uses native
secure state drivers; bar creation/deletion/layout changes defer until combat
ends. Information continues updating once per second and on native events.

Only EUI_DataBars_335.lua and EUI_DataBars_335_Blocks.lua load. Copied Retail
engine/Blocks/media remain unchanged, unloaded references. No external addon
data or dependency is used. The broker block reads only the EUI Bags object.
The EUI Core central profile database owns settings; no separate inventory
store is added. Retail-only Great Vault/Crests, loot spec, warbank and modern
profession systems are not exposed. Coordinates never change map selection;
they may be unavailable when a different map is selected or in instances.
Currency/skills show native expanded categories. Item level is an average of
occupied equipment slots (shirt excluded), with uncached items retried later.

validate_databars.py tests all block values/clicks/fonts, native TOC, original
byte integrity, multiple bars/CRUD, layout bounds and vertical behavior without
native texture rotation, secure actions/drivers, combat queue, profile changes,
frame reuse, Edit Mode callbacks, options/search and slash commands.
validate_actionbars.py verifies progress handoff/fallback. validate_unitframes.py
compiles every module Lua file under Lua 5.1. In-game rendering/input and taint
verification still require client testing.
