# Estado do backport — 01/10/2026

Latest build: HUD-test-0.38. Friends 0.1 and Quest Tracker 0.1 added.
Options 0.43; Blizzard Skin 0.7; Core 0.28 and other runtimes unchanged.
Nineteen EUI addon folders; twenty selected release archives.

Friends styles Wrath's native social window and recycled friend rows with
readable outlined fonts, localized class colors/icons, background/scale settings
and exact native-style restoration. Native tabs, clicks, whisper/invite/context
actions and available Battle.net data remain native. Blizzard Skin yields only
FriendsFrame while this enabled module owns it, and resumes when disabled.

Quest Tracker styles Wrath WatchFrame while retaining native quest/achievement
lines, timers, map links, collapse controls and quest-item buttons. Settings
include readable fonts, content-sized background, scale/width/height, visibility
and Unlock Mode position. Optional auto-accept/turn-in helpers default off;
Shift skips them, reward choices and paid/material turn-ins stay manual. An
optional hotkey securely clicks the first visible native quest-item button;
rebinding and structural edits defer during combat. /efriends and /eqt open
their new settings. Profiles, style presets and global font settings integrate.
Retail sources/media remain byte-identical and unloaded; no external addon
dependency or external character data is used. Retail-only tracking/social
systems are not loaded or fabricated on Wrath.

Lua 5.1 checks pass for both real Lite lifecycles, combat login/deferred refresh,
native/recycled rows and clicks, fonts, state drivers, quest-item hotkeys,
positions/restoration, helper guards, Options pages, Blizzard Skin ownership
and private Options factory/input cleanup. Rendering and taint still need
in-game review. ACP's separate menu patch is not part of the EUI archives.

Previous checkpoint: HUD-test-0.37.

Latest build: HUD-test-0.37. Options 0.42. Core and all module versions
remain unchanged from 0.36; Quickdraw runtime remains 0.1.

Quickdraw Assign Key now opens a temporary hotkey capture dialog instead of
trying to bind a typed key string. It samples Ctrl/Alt/Shift on the first
non-modifier key press, shows the selected chord, and saves the binding when
that key is released. Bare modifiers and key repeats never become bindings.
Escape, Cancel/right-click, page teardown, closing Options, combat start,
focus transfer or a 20-second timeout always disable the dialog's keyboard
input and clear its event registration. Capture never uses keyboard propagation,
global Escape hooks or persistent keyboard handlers. Existing native binding
and secure Quickdraw hold/release behavior remains in place.

Lua 5.1 tests exercise actual capture scripts, modifier snapshots, repeat and
release handling, persistence, invalid bindings, ten Escape cycles, hide/page/
Options/combat/timeout/focus/cancel cleanup, and rearming after failure.
Quickdraw secure regressions, Options factory/focus and all active Lua compile
checks pass. Native in-game input and appearance still need client review.

Previous checkpoint: HUD-test-0.36.

Latest build: HUD-test-0.36. Options 0.41 / AuraBuff Reminders 0.1 /
Quickdraw 0.1. Core 0.28 and other module versions unchanged.

AuraBuff Reminders is independently implemented for Wrath: learned raid-buff
providers, group/single-rank name equivalence, reachable/alive member counts,
personal armor/aura/shield/pet reminders, flask/food/restock counts, weapon
enchant checks (excluding shields/frills), missing or expiring auras, manual
player/target/focus buff/debuff/own-caster filters, location-gated expected
talent spell reminders, sounds, dismissal, preview and Unlock Mode positions.
Click-to-cast/use overlays exist separately from the dynamic reminder display;
native state drivers hide them in combat. The read-only display can refresh
in combat without protected frame writes or allocation. Open /eabr or /ebr.
Settings pages: Auras, Buffs & Consumables / Custom Reminders / Talent Reminders.
Talent/zone assignments are manual, using native Wrath learned spells.

Quickdraw supports 16 numbered palettes, each with up to 20 actions. Hold its
key, point or scroll, release to execute; center/empty-space/no-motion cancels.
Escape cancels and removes temporary overrides. Ring/arc (span + rotation),
horizontal fan and grid layouts, cursor/screen positioning, size/opacity/fonts,
counts and cooldowns are configurable. Add spell/item IDs, named macros or
macro text, equipment sets, mounts/companions, raid markers and native micro
buttons; cursor pickup is supported. Bind through settings or native bindings.
Secure restricted click/wheel/cancel snippets work in combat without insecure
attribute writes. Combat edits and held-palette cache updates defer. Display
uses a snapshot matching the secure actions. /eqd opens settings.
Retail nested palettes, world markers and Retail collection APIs are not loaded.

All original Retail Lua and ABR sound files remain unchanged and unloaded.
Quickdraw's original XML is retained as Bindings_Retail.xml; native Bindings.xml
registers exactly 16 stable EUI_RADIAL action names and is not listed in the TOC.
No external addon runtime, data or libraries are needed by either new module.

Validated in Lua 5.1: real Core lifecycle, aura rank/group ownership/expiry,
reachable units, consumable/weapon checks, zone/talent reminders, sound dedup,
OOC secure casts and combat read-only updates, preview/dismiss/unlock/settings.
Quickdraw executes real source snippets in a restricted fixture enforcing
Wrath's no-function/no-table-creation parser rules, native owner frame refs,
combat mutation guards, release actions, arc/grid/fan/wheel/deadzone/no-motion,
modifier routing, repeated Escape cleanup, deferred edits, direct-slot cleanup,
native micro-button macros, keybindings and cursor assignments. 110 active Lua
files compile. CDM/memory, Damage Meters and private Options regressions pass.
Native rendering and real client secure execution still need in-game review.

Previous checkpoint: HUD-test-0.35.

Latest build: HUD-test-0.35. Core 0.28 / Options 0.40 / Cooldown Manager 0.1.
Other module versions unchanged.

Cooldown Manager now runs independently on Wrath, with cooldown, utility,
buff icon groups and tracking bars. Class defaults include learned spells,
equipped trinkets and player proc/buff auras. Manual spell/aura/item/equipment
assignments, unit/buff/debuff/own-caster filters, ordering/removal and per-dual-
talent-group storage are available in CDM Bars / Tracking Bars / Bar Glows.
Display controls include dimensions, growth, visibility, duration/stack/keybind
labels, opacity, outline, range tint, observed-GCD suppression, previews and
Unlock Mode positions. Native cooldowns follow the highest learned rank or
pet spellbook; permanent auras render without fake durations. Optional aura
triggers highlight owned EUI action buttons. Icons are tracking displays;
clicking opens settings. Retail rotation/talent-condition systems are not loaded.
All 11 original Retail Lua files remain unchanged as unloaded references.

The Options sidebar now shows Memory Usage for all loaded EllesmereUI-named
addons including the load-on-demand Options addon. Native memory accounting
is refreshed every five seconds while visible and displayed in MB. Disabled
addons and unrelated addons are excluded; no forced garbage collection.

Validated with actual Lite lifecycle in Lua 5.1: rank/passive/pet handling,
strict unit and caster aura ownership, permanent/expired auras, cooldown/GCD,
items/stacks, spec-list persistence, previews/unlock callbacks, manual settings,
action glows/keybinds and no combat UI allocation. Combined memory totals include
Options. 102 active Lua files compile. Existing theme/preset, private options
factory, Unit Frames and Damage Meters regressions pass. Native appearance and
real class spell coverage require client review.

Previous checkpoint: HUD-test-0.34.

Latest build: HUD-test-0.34. Damage Meters 0.3 / Options 0.39;
Core 0.27 and all other modules unchanged.

Hover an actor bar to see its top spells with native spell icons, amounts,
percentages and affected-target bars. Hidden entries are summed as Other,
so top-entry percentages remain accurate. Hover updates with live data and
is dismissed when the bar changes identity, hides or the view changes.
One native tooltip and its rows are preallocated; hover/combat refresh does
not allocate UI frames. The death metric shows the latest recap; threat
shows native target threat rather than invented spell attribution.

Left-click an actor to replace that same meter with the person's spell
breakdown. The footer switches Spells/Targets; Back restores the group.
Spell bars have icons and hover hit/crit/min/max information. Death focus
uses the recorded recap with a death selector. Mouse wheel scrolls focus
rows; live totals/percentages/rates update. Right-click retains the separate
statistics window. Report preview uses the current group or focused view;
only explicit Send sends chat, as before.

Focus is per-window transient state, excluded from saved profiles. Metric,
segment and profile changes clear it; missing-player data stays empty with
Back available. Reset clears focus and hover. Actor rows retain their class/
specialization icons. Existing window opacity/outline settings are preserved.
No external addon data, libraries or runtime is consulted.

Validated in Lua 5.1: 98 active files, real row OnEnter/OnClick/OnLeave,
native spell icons, exact actor percentages, combined Other totals, targets,
inline focus/back/footer/death recap, DPS including fractional bar scaling,
live updates and scrolling without frame allocation, row reorder/metric/
segment/profile/hide cleanup, focused reports and prior native collector,
history/specification/opacity/font/unlock/report regressions. Retail
reference files remain unchanged. Native rendering requires client review.

Previous checkpoint: HUD-test-0.33.

Latest build: HUD-test-0.33. Core 0.27 / Options 0.38 / Damage Meters 0.2;
all other modules unchanged.

Damage Meters > Windows now provides independent Background Opacity,
Bar Opacity and Header / Footer Opacity settings. Text does not fade with
the bars/background. Meter names/values default to OUTLINE with black
shadow, independent of the global EUI outline; a per-window dropdown
selects Outline, Thick Outline, None or the EUI font setting.

Specialization icons appear beside actor names. The player uses native
active talent-group information. Group members are inspected sequentially
out of combat with cooldown, timeout, GUID/token and inspection ownership
checks. Native Inspect UI takes priority; no shared inspection data is
cleared and no global native function is replaced. Class icons are the
fallback while talents are unknown/out of range. Existing known combat
segment specializations survive later talent switches; previously unknown
history entries are backfilled. No other addon cache/library is used.
The icon toggle, outline and opacity fields also migrate older extra windows.

Options theme art now occupies native BORDER above the permanent BACKGROUND
base on Wrath. Pixels accent and collapse-box strips/glyphs use higher
native layers. Retail texture sublevels cannot reliably order this art on
Wrath; instant switching alone in 0.32 did not fix the base occlusion.
Retail retains its original layering/crossfade.

Validated: 97 active Lua 5.1 files, actual Core/meter lifecycle, native
specialization groups/events, class fallback, historical icons, inspection
ownership/GUID changes/throttles/timeouts/combat/range/user-inspect guards,
independent opacity settings including zero, hover restoration, default
outline and black shadow. Real theme layer construction ignores sublevels
in the fixture; palette/art/overlay and prior Presets regressions pass.
Unit Frames and private options factory regressions pass. Native appearance
still requires client review.

Previous checkpoint: HUD-test-0.32.

Latest build: HUD-test-0.32. Core 0.26 / Options 0.37;
all other modules unchanged.

Options theme changes now apply the selected background and menu accent
together. Wrath switches the background/collapse-box layers immediately,
hides the outgoing art and clears the Pixels overlay without relying on
a crossfade ticker under a hidden or collapsed panel. The live background
handle follows the selected layer. Retail retains its animated transition.
Match Accent to Theme still controls theme versus independent profile color.

General combat damage/healing toggles and the periodic/pet damage cog now
read/write stock Wrath CombatDamage, CombatHealing,
CombatLogPeriodicSpells, PetMeleeDamage and PetSpellDamage. Retail v2 names
remain used on Retail. Existing combat restrictions and safe handling of
unavailable CVars are preserved.

Validated in Lua 5.1: real theme API/menu colors, every native TGA path,
visible background/collapse layers, rapid hidden-panel selections, Pixels
overlay removal and Retail transition; actual combat-text row/cog callbacks
against strict native and Retail CVar sets; independent toggles, combat
guard and unavailable CVars. Unit Frames, private options factory and
search/focus regressions pass. Native appearance requires client review.

Previous checkpoint: HUD-test-0.31.

Latest build: HUD-test-0.31. Damage Meters 0.1 / Options 0.36;
Core 0.25 and all other modules unchanged.

EllesmereUIDamageMeters now runs its own Wrath CLEU collector and saved
history. The installed Details main addon was examined as a reference;
there were no separate installed Details plugins. No Details runtime,
libraries, globals, saved data or copied parser are used. Retail EUI
sources/media remain unloaded and unchanged. Native combat collection
replaces Retail C_DamageMeter, which is not available on stock 3.3.5.

Two default windows (damage/healing), up to four, support damage/DPS,
healing/HPS, overheal/received healing, incoming/enemy/friendly damage,
absorbs received, blocks/resists/misses/avoidance, deaths/recaps, interrupts,
dispels, casts, resurrections, CC breaks, distinct power gains, buff/debuff
uptime and native current-target threat. Header selects metric, footer
selects current/last, overall or one of up to 30 saved segments; menus and
rows scroll. Left click opens spells, right click targets. R previews a
report; only the explicit Send button sends paced chat messages.

Open /edm or the Damage Meters sidebar. Windows move by header drag or
Unlock Mode; profiles and per-window display/visibility settings apply.
Combat history is per-character EllesmereUIDamageMetersHistory, separate
from exported UI profiles. Save History controls logout persistence.
Clearing data requires confirmation and is blocked during combat.

Absorbs belong to the recipient: no guessed shield caster/healing credit.
Aura uptime sums observed target-seconds and does not claim a universal
percentage. Resource types stay separate. DPS/HPS use encounter duration,
which freezes during the end grace; active group combat keeps collecting.
Overall refresh merges summaries; spell/target breakdowns merge on demand.
Rows are preallocated; native frame factory, Escape and game menus remain
untouched. Report inputs do not autofocus and clear focus on hide.

Validated: actual Lua 5.1 Core lifecycle with Details absent, eight-field
CLEU/spells/pets/statistics, recaps, aura timing/reconciliation, segments/
overall/rates/frozen duration, history reload/retention/disable, threat,
options/profile rebind/unlock/window pooling and explicit report flow.
Native client appearance and actual encounter totals require review.

Previous checkpoint: HUD-test-0.30.

Latest build: HUD-test-0.30. Core 0.25 / Options 0.35 / UnitFrames 0.8 /
RaidFrames 0.4; other modules unchanged.

Buffs/Debuffs pages share a non-secure header preview and indicator editor
for Raid Frames and Unit Frames. Click a preview spell or indicator list
entry to edit it. Positions, growth, size, offsets, stacks, duration/swipe,
opacity, border and manual spell assignments refresh the preview in place.
The whole preview layout scales to fit its canvas; live icon sizes do not.

Default buff indicators are healer assignments, personal defensives and
external active effects (3+2+2 icons). Other buffs start empty and must be
added manually. An explicit Wrath-only catalogue matches rank variants by
native localized spell name, without importing another addon's filters or
saved data. Externals may come from other casters even with the global Own
filter; indicator Own Only and global exclusions/hard constraints apply.
These indicators show active effect durations, not remote cooldown readiness.

Unit Frames > Buffs > Select Frame: Player > Use Indicator Layout enables
the new player display and hides only its previous aura row. Disabling the
mode restores the old row/settings. Buff/debuff and player/target/focus/boss
settings remain independent. Sixteen plain icons are preallocated per
unit frame (eight per aura type); aura events/expiry reuse this pool.
Raid/party and 10/25/40 settings are independent. The old automatic broad
Buff Icons default migrates to healing, retaining its visual edits; named,
manual and custom-filter indicators are retained.

Validated: real raid/UF lifecycle and registration, shared editor/preview,
all nine anchors and four growth directions compared to live raid layout,
rank matching/exclusions, external any-caster, healing Own Only, manual-only
ordinary buffs, selected-layout isolation, live player pools/expiration,
no combat allocations, old-row restore, header reuse/input/native-factory
safety and 217 Lua 5.1 files. Native rendering still needs client review.

Previous checkpoint: HUD-test-0.29.

HUD-test-0.29. Options 0.34 / BlizzardSkin 0.6;
Core 0.24 / Minimap 0.3 and all other modules unchanged.

User confirmed the 0.28 blocked-action warning was fixed, then reported
keyboard input locking after repeated Escape closes. The compatibility
EditBox probe had native autofocus after the global factory removal. All
probe widgets now live under a hidden input-disabled parent, are themselves
hidden/input-disabled, and the EditBox explicitly disables autofocus and
clears focus. Native frame creation remains unchanged; EUI search fields
retain click-to-focus and normal typing.

Glyphs no longer paint a second full-window panel over talents. The higher
glyph sheet fill is bounded to the body and has no duplicate accent/header;
shared tabs, portrait and close button remain visible. Talent-only content
is hidden while glyphs are active and its prior visibility restored when
leaving or disabling the skin. Native glyph socket art/clicks/tooltips and
native show/hide handlers remain intact. Combat defers skin writes.

Validated: probe visibility/focus/input across show/hide cycles, native
CreateFrame identity, actual search/widget behavior, six glyph sockets and
repeated talent/glyph switching, footer/body bounds, native callbacks,
inactive control restoration, skin disable/combat deferral/frame reuse,
existing currency/LFD/mail/quest/character skins and 215 Lua 5.1 files.
Client rendering and repeated Escape/input flow still need confirmation.

Previous checkpoint: HUD-test-0.28.

HUD-test-0.28. Core 0.24 / Options 0.33 / Minimap 0.3;
other modules unchanged.

Reported trigger: middle-click minimap menu > Spellbook or another native
window > Escape produced an EllesmereUIOptions blocked-action popup.
Options globally replaced CreateFrame; that adapter is now private and
bound only inside 18 active EUI options builders. Panel/global search use
it locally; UnitFrames retains its private Wrath frame adapter. Native
CreateFrame stays unchanged after options loads, and native EditBoxes no
longer receive EUI autofocus/OnHide modifications.

All minimap menu actions now use securecall for native named toggles or
native micro-button clicks, preserving disabled state, arguments and OOC
guards. Native close handlers, Escape bindings and blocked-action reports
are retained. Restart clears the previous session's existing taint.

Validated: unchanged native factory identity, template filtering/private
focus cleanup, idempotent compatibility loading, active builder bindings,
secure menu routes, Spellbook open/close, existing search/options access,
widget setters and 215 Lua 5.1 compilation/UnitFrames regressions. Native
client taint confirmation is still required for the exact reported flow.

Previous checkpoint: HUD-test-0.27.

HUD-test-0.27. Minimap 0.2 / QoL 0.2 / ActionBars 0.12 /
Options 0.32; Core and other modules unchanged.

Middle-click micro menu uses an EUI-owned native popup without EasyMenu.
Native window/button actions, optional entries, shared font/accent,
outside-click/Escape dismissal, combat close and exact disable restore
are covered by the real Lua 5.1 Core lifecycle regression.

QoL > Raid Tools now selects a 3-60 second pull duration (default 10).
Broadcast and chat countdown are independent toggles. Chat announces the
start duration, 10 and the final 5/4/3/2/1, then Pull!, choosing Raid Warning
when permitted, Raid otherwise, or Party. Solo countdown stays local.
Broadcast uses native DBMv4-PT, D4 PT and legacy BigWigs BWCustomBar Pull
formats, without requiring a boss mod here. Raid leader/assistant or party
leader permissions apply; recipient filters and throttles remain in force.
Legacy BigWigs displays a custom timer/finish alert; compatible later Pull
plugins have their own countdown UI. Cancel/early combat/disable/profile
and group transitions stop the local countdown without stale chat.

The original stance/pet controllers and bonus shell now have a hidden
parent while EUI handles the buttons and bonus paging. Blizzard Show/alpha
updates during stance changes cannot reveal duplicate native bar shells.
Their events stay registered. Disabling restores original appearance.

Validated: lifecycle/menu native actions and dismissal/theme, timer
scheduling/channel priority/packets/cancellation, actual installed DBM PT
receiver, secure stance/bonus shell suppression, button/paging/restore,
existing ActionBars/QoL and UnitFrames compile/regression checks. Native
rendering, taint and remote boss-mod sounds still need client confirmation.

Previous checkpoint: HUD-test-0.26.

HUD-test-0.26. DataBars 0.2 / Bags 0.7 / BlizzardSkin 0.5 /
RaidFrames 0.3 / Options 0.31; other versions unchanged.

DataBars initialization uses the captured addon reference with Lua 5.1
xpcall. The regression now runs the real Core loading/login dispatcher.
Mail quantities remain above skinned icons; dark quest/gossip text and
inline colors remain readable, including after native refresh. Actions,
empty counts and original appearance restoration are preserved.

Bags owns alt gold snapshots even when inventory is not yet ready. Saved
bags show the character balance; footer/broker hover includes each alt,
realm total and combined total, explicitly last recorded for offline alts.
Cached item subclasses support Crafting Reagents, Food & Drink, Potions,
Flasks & Elixirs and Other Consumables plus a view-only category filter.

Raid/party defaults to Tank > Healer > DPS within each subgroup. Hide DPS
Role Icons keeps all player frames visible. Role/name lists update outside
combat; membership changes in this sorting mode can wait until combat ends.
Unknown roles sort last. Name/Roster sorting remains selectable. Separate
Buffs/Debuffs pages offer independent indicators and filters, spell lists,
custom order, show-in raid/party, anchors/growth/offsets, sizes, opacity,
borders, duration swipe/text, stack counts and hide-icon options. Eight
preallocated icons per aura type are shared across indicators. Existing
group/layout profiles, aura filters and click casting are retained.

Validated: actual lifecycle, serialized SavedVariables across three
character/realm sessions, gold updates/tooltip/categories, native mail
stack layers/actions/restore, quest colors including inline codes,
secure header role ordering, icon hiding only, independent indicator
filters/options/render state, combat deferral and existing module checks.
215 Lua 5.1 files compile. Thirteen addon folders/fourteen release ZIPs
are current. Rendering and taint still require client confirmation.

Previous checkpoint: HUD-test-0.25.

HUD-test-0.25. DataBars 0.1 / Bags 0.6 / Options 0.30 /
ActionBars 0.11; other versions unchanged.

Added the requested EllesmereUIDataBars Retail folder as unchanged Lua/media
references with a native 3.3.5 TOC loading only EUI_DataBars_335.lua and
EUI_DataBars_335_Blocks.lua. /edb opens a single native settings page: bar
selection, four templates, CRUD, ordered blocks, horizontal/vertical layouts,
full-screen/custom length, equal/custom width weights, scale, fonts, opacity,
EUI accent/flat themes, border and secure combat/group visibility. A bottom
information bar is seeded once on a fresh profile. Every bar has its own Edit
Mode mover and profile position. Core profile refresh already invokes _EDB_Apply.

Twenty native block types: clock, FPS, latency, location, coordinates, gold,
bags, durability, combat, XP/reputation, talents/dual spec, primary/secondary
professions, hearthstone, micro menu, currency, equipped item-level average,
audio, EUI inventory broker and spacer. The travel action is a native secure
item button. Data comes from the client or EUI's own inventory namespace only;
no external addon data or dependency. Retail-only Crests/Great Vault/loot spec,
warbank, random hearthstones and arbitrary external broker plugins are absent.
Coordinates do not alter the user's map selection and can be unavailable;
currency/skill lists follow native expanded categories. Equipped iLvl is a
local average of occupied slots, not a Retail item-level API value.

ActionBars hides its own XP/reputation holder and Edit Mode entry while an
active DataBars block presents the same progress type. Its suppression of
native Blizzard bars is retained; removing/disabling the block restores the
configured ActionBars holder without changing saved preferences. The default
bottom template uses information blocks, leaving the existing progress bars.

Bags saved bank/alt item buttons remain read-only plain Buttons. They no
longer call CheckButton-only SetCheckedTexture; live item CheckButtons still
clear their checked texture. A stricter fixture reproduced the exact reported
line-109 failure before the fix. Cache, serialization/persistence, broker and
inventory/resource tests now pass with native button types enforced.

DataBars tests execute actual Lite/module/options code and verify all block
values/actions, secure hearthstone, state drivers, combat deferral, profile
replacement, frame reuse, layout bounds/vertical, positions, option writes,
source byte integrity and native TOC. ActionBars regressions include progress
handoff/fallback. 215 Lua 5.1 files compile. Thirteen addon folders/fourteen
release archives are current; project pack excludes player data. Native
rendering, input and taint confirmation still require the in-game test.

Previous checkpoint: HUD-test-0.24. Bags 0.5 / Options 0.29 / ActionBars 0.10;
other versions unchanged.

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

Player Buffs: the user requested downward growth within the screen. Aura row
offsets already used negative Y, but CENTER/BOTTOM holder anchors shifted the
top row upward as height changed. ActionBars 0.10 fixes the top-right corner
before resizing and persists a top anchor. Live Edit Mode dragging and combat
deferral remain intact; debuff layout is unchanged. The secure ActionBars/HUD
regression checks growth/shrink, position persistence and native behavior.

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
The following external integration has been superseded and removed in 0.24.

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

Previous checkpoint: HUD-test-0.22. Bags 0.3; other versions unchanged.

User reported missing item stack information. Wrath ItemButtonTemplate Count
starts hidden; setting its text did not reveal live bag/bank quantities. The
renderer now shows counts above one, hides single/empty counts and promotes
white stack text to OVERLAY. The label is stored as stackCount separately from
the native numeric button.count expected by item/refund handlers. Saved bank
and alt views follow the same visibility rule; existing count font settings
still apply.

Validation: the legacy fixture models the native hidden Count region and its
BORDER layer. Visibility regression failed before the correction and passes
afterward. Inventory/resource and cache checks cover live counts, stack changes,
empty/single slots, saved bank/alts, numeric count metadata and Global Fonts.
All 192 Lua 5.1 sources compile. Build archives and project pack are verified;
client display confirmation pending. Older archives retained.

Native references: https://github.com/wowgaming/3.3.5-interface-files/blob/main/ItemButtonTemplate.xml
and https://github.com/wowgaming/3.3.5-interface-files/blob/main/ItemButtonTemplate.lua

Previous checkpoint: HUD-test-0.21. Core 0.23 / Options 0.27 / Bags 0.2 /
ActionBars 0.9. Other module versions are unchanged.

Inventory and bank now include bag-equipment slot strips with capacities,
click filters, native item drop/bag pickup and confirmed bank-slot purchases.
Bank opens the current character's last saved bank away from a banker;
Characters selects saved bag/bank contents for alts across realms. Saved items
use separate plain buttons with no native item-action handlers. Search, bag
filters, saved timestamps and cross-character item counts work on snapshots.
Unknown bank contents are identified instead of reported as an empty bank.

Account snapshots live in EllesmereUIDB.wrathInventoryCache outside layout
profiles. Bags record even while closed/in combat; bank reads occur only in
an active bank session. Each alt must be logged into, and its bank visited,
to populate the cache. Normal game logout/reload persists SavedVariables.
The project pack contains code, not player inventory data.

Action Bars > Select Bar > Bag Bar > Consolidate Bags reduces the HUD strip
to one native backpack button opening the unified inventory. It preserves
the interior bag-slot strips, native events/scripts and full-strip restoration;
changes made during combat wait until combat ends.

Validation: validate_bag_cache.py covers native slot IDs/drop/pickup/purchase,
saved banks away from bankers, realm/alt isolation, stale removal, closed-window
and combat recording, read-only pools, search/counts, profile/reset/reload
persistence, selector/options and exact bank-session/native restoration.
Inventory/resource and secure ActionBars/HUD regressions pass, as do Raid/QoL
regressions and compilation of 192 Lua 5.1 files. Client rendering/input and
real logout/relogin persistence still require user confirmation. Twelve addon
folders/thirteen release archives are saved and verified against installed
sources with SHA-256. Older archives retained.

Previous checkpoint: HUD-test-0.20. Core 0.23 / Options 0.26 / BlizzardSkin 0.4.
User confirmed its currency, dungeon rewards, talent icons and tab skins look
good in the client; project-0.20 was saved and verified.

Other module versions are unchanged, including Raid Frames 0.2.

User reported unreadable Currency rows, missing random-dungeon reward icons,
missing talent icons, overlapping talent tabs and asked to check other tab
indicators. Shared skin fills now use an owned BACKGROUND texture on the
native owner; the child panel draws only borders. This prevents filled child
frames covering native icons/text when frame levels change. Native icons
are promoted to ARTWORK, including iconTexture/IconTexture fields, with
original layer/sublevel/coords restored when disabled. Currency uses native
sheet dimensions and header while PaperDoll is hidden; the expanded character
layout returns only on its own tab. Native Currency/LFD refresh functions and
TokenFrameContainer.update get guarded hooks even after delayed addon loading.

Talent footer tabs measure labels, pack with 6px gaps and retain IDs/native
clicks/selection. The point bar stays above the tab rows. Native geometry
restores on disable. Other native footer/header tab panels respect 10px
transparent margins rather than drawing over adjacent selection indicators;
FriendsTabHeader is recognized. Other tabs retain their native geometry/input.

Validation: validate_skin_content.py covers Currency sizing/text/icons,
LFD icons/tooltips/late refresh, talent icons/clicks/tab spacing, seven native
window tab strips (Merchant/Friends/GuildBank/Auction/Inspect/Achievement/
Options), selection state, combat deferral, native restoration and reuse.
Full BlizzardSkin/character-sheet checks and compilation of all 191 Lua 5.1
sources pass. Tests model native API contracts; in-game rendering still needs
confirmation. Thirteen current archives match the installed source and are
recorded with SHA-256 in the current manifest. Older archives retained.

Previous checkpoint: HUD-test-0.19. Core 0.23 / Options 0.26 / Raid Frames 0.2.
Other module versions are unchanged.

Raid Frames now saves independent 10-, 25- and 40-player layouts, including
dimensions, appearance, aura/filter settings and Unlock positions. Raid >
RAID LAYOUTS separates Use Raid Layout (Automatic or forced size) from Edit
Raid Layout (which size to configure). Automatic chooses native instance
capacity first, otherwise roster size; outside raids it uses 40. Nonsecure
preview outside a raid follows the edited size. Global Fonts, Textures and
Aura Filters also expose the layout selector. Migration copies the previous
raid settings, filter tables and position independently to all three layouts.
The old raid table remains a migration source, not the live runtime profile.

Show Group 1–2 / 1–5 / 1–8 toggles hide individual subgroups per layout.
Remaining headers pack without gaps and preserve their native groupFilter
and group labels. Group Limit still caps the last subgroup; showing a group
raises that limit as needed. All hidden means the raid holder and mover hide.
Native roster assignment remains with secure headers. Layout/visibility/size
switches during combat defer until PLAYER_REGEN_ENABLED. Roster/zone events
and the existing native poll detect automatic layout changes.

Validation: actual Lua 5.1 runtime/options tests cover 10/25/40 thresholds,
underfilled instance capacity, manual override, hidden-group compaction and
all-hidden state, combat roster/visibility deferral, legacy migration without
shared filter tables, separate positions, inactive-layout editing, preview,
and Global Fonts/Textures/filter isolation. All 191 Lua sources compile;
UnitFrames, nameplate GUID/channel/aura filters and Bags/Resource Bars shared
option regressions pass. Thirteen current archives are checked against the
installed source and recorded in the SHA-256 manifest. In-game secure behavior
and appearance still require client confirmation. Older archives retained.

Previous checkpoint: HUD-test-0.18. Core 0.23 / Options 0.25 / Raid Frames 0.1.
Other module versions are unchanged.

Raid Frames: native secure raid and party headers with 45 preallocated unit
buttons, separate layouts, class colors, health/power, range, threat, roles,
leader/raid markers, ready checks, vehicles and offline/dead/AFK status.
Native headers own membership and sorting; layout and click-binding edits
defer until combat ends. Aura icons follow each member independently of target
selection, retain click-through behavior and support native tooltips, timers,
stacks, dispellable rules and separate raid/party tracked/excluded ID filters.
Click casting is opt-in with modifiers and mouse buttons 1–5; default target
and native unit menu remain. Clique registration is available. Native party
frames preserve scripts/events and restore their original parent/positions
when the replacement is disabled. Other group addons and native raid pullouts
are not modified. Preview uses independent nonsecure buttons and does not
cover live groups. Unlock movers, central profiles, Global Fonts and Textures
use the live native settings. /erf and /rf open the four options pages.

Retail sources remain unchanged, unloaded. Converted roles/textures are
independent native TGA assets. Unsupported Retail private-aura, prediction,
portrait and advanced manager controls are not exposed. Other preset menus
remain available; the unsupported Retail raid style selector is omitted.

Validation: 191 Lua 5.1 sources compile. Actual native Raid Frames runtime and
options builders pass explicit Wrath contract tests for roster/subgroup/GUID
changes, aura ownership/removal/expiry, vehicles, secure combat deferral,
click bindings, range/status/ready checks, preview, native restoration,
profiles and movers. Shared UnitFrames, nameplate GUID/aura filters,
themes/presets, Bags/Resource Bars and QoL regression checks pass.
The contract fixture does not replace in-game native secure/rendering checks.
Current build contains twelve addon folders and thirteen archives including
the bundle; the current manifest verifies every ZIP member and SHA-256 hash.
Older archives remain after the prior approval-review deletion block.

Previous checkpoint: HUD-test-0.17. Core 0.23 / Options 0.24 / ActionBars 0.8 /
Nameplates 0.6 / Quality of Life 0.1. Other module versions are unchanged.

User confirmed plate identity is now correct and asked for DEBUFF indicators
to persist after deselection. Nameplates refreshes LibAuraInfo directly from
an identified unit's native aura list before the target/mouseover token is
lost. This learns unknown spell IDs/durations independently of library event
ordering. Cached debuffs stay on that verified visible plate and clear on
removal, expiry, death or frame hide/reuse. No name-only mapping is restored.
The new regression fails against the previous 0.5 archive and passes with 0.6.

ActionBars: Bar 1 could be covered by the retained invisible native MainMenuBar
art containers. Disable their mouse surfaces while EUI bars are enabled;
restore the saved mouse state on disable. Native micro/bag children keep their
click/drop handlers. Actual LAB secure drag/drop/paging/lock tests pass.
In-game confirmation of the reported Bar 1 drop problem is still required.

QoL: new native runtime and five pages (QoL, Cursor, Shifter, Raid Tools,
Logging). Supports merchant repair/junk, quick loot, trainer button, delete
text, cinematic/error/tutorial toggles, FPS/stats/coords/crosshair/durability,
combat/death alerts, player cooldown/lockout displays, cursor, window dragging,
secure target markers/ready check/local pull countdown and instance logging.
Automation and overlays start opt-in. Core profile refresh now reapplies QoL;
Global Fonts edits the native profile. Native overlays and raid tools have
Unlock movers. /eqol and /qol open the module. Retail originals are preserved,
unloaded; no modern shared battle-res charges/Mythic+ upgrade/key tools are
emulated. Cursor textures have separate power-of-two bottom-origin copies.

Validation: QoL native Lua 5.1 lifecycle, automation gates/ownership/restore,
logging, live spell/aura tuples, timers/cursor, protected-frame combat guards,
profiles/movers/options/global fonts and Retail byte integrity passed.
Nameplates + real GUID cache/filter tests, ActionBars + native HUD tests and
compilation of all 178 Lua sources passed. ZIPs are checked against every
installed source member and hashed in ELLESMEREUI_335_CURRENT_BUILD.json.
Current build has eleven modules and twelve archives including the bundle.
Visual appearance and native secure behavior still need client confirmation.

Previous correction: Nameplates 0.5, HUD-test-0.16. User reported debuffs also
appearing on nearby nameplates. Removed the 0.4 name/GUID cache shortcut:
a single visible same-name plate cannot prove it is the combat-log recipient,
particularly after the affected plate hides or the native frame is reused.
Auras now require GUID observation through native target selection/mouseover;
verified GUIDs stay with that plate only for its visible lifetime. Unknown
plates stay empty until observed. No name-only aura lookup remains.
A freshly observed GUID has one plate owner; previous owners clear immediately.
If selection alpha lags a conflicting native mouseover highlight, mouseover
wins and the alpha candidate is unbound. Duplicate retained GUIDs are rejected;
missing GUIDs cannot authorize native aura rendering. Aura filters unchanged.

Validation: validate_channel_aura_filters.py reproduces the name-copy bug when
run against the previous Nameplates 0.4 ZIP and passes with installed 0.5.
Covers nearby same-name plates, original plate disappearing, reuse, two separately
observed same-name units with different debuffs, independent removal, cache
updates after target changes, and one-GUID/one-owner target-alpha transitions.
Nameplates lifecycle/options and Lua 5.1 syntax checks pass. In-game visual
confirmation pending. Current manifest identifies the 11 current archives.
Older ZIPs retained following earlier approval-review deletion block.


Previous checkpoint: HUD-test-0.15. Core 0.22 / Options 0.23 / UnitFrames 0.7 /
Nameplates 0.4 / ResourceBars 0.2. User clarified BOTH castbars have animation
and channel tick problems, then added non-target nameplate debuffs and filters.
Cast/GCD fill now updates every render frame; UF fill/text/expiry share one
engine driver, without the generic shim's competing OnUpdate. Known Wrath
channels use localized counts from the provided ElvUI channel catalogue, native
haste endpoints, and fixed initial pulse intervals through pushback. Penance
accounts for the initial pulse; unknown spells get no invented timing.
Show Channel Ticks defaults on: /erb > Bars > Player Cast Bar; /euf > Main
Frames > CAST BAR. Resource preview timer cache stays consistent.

Nameplates now bundles unchanged local ElvUI Libraries/LibAuraInfo-1.0 by
Cyprias (major LibAuraInfo-1.0-ElvUI revision 19) and spellIdData.lua. LibStub/
CallbackHandler are already in Core; ElvUI need not be enabled. Native Wrath
combat log tracks aura apply/refresh/dose/remove/death, native UnitAura learns
unknown IDs/durations. Verified plate GUIDs remain while visible after changing
target; unique active name/GUID pairs can identify anonymous plates. Inferred
mappings immediately invalidate on ambiguity. Identical-name packs require
target/mouseover first. Hide/reuse discards identity. Cached duration can be an
estimate; combat log does not provide native Stealable metadata.

New Aura Filters pages in /euf and /enp: all/own/tracked, tracked/excluded spell
IDs, timed-only, stealable buffs and reset. UF player/target/focus/boss filters
stay separate. Tracked IDs supplement own mode; exclusions win; own includes
pet/vehicle. Includes/excludes use existing tables and per-ID caster scoping.
Invalid IDs preserve existing lists. Display/layout toggles stay on old pages.

Validation: 163 Lua sources compile with Lua 5.1. UnitFrames and inventory/
resources checks cover .016s progression, tick pooling/toggle/stop/expiry,
Penance/pushback and native aura render filters. New
validate_channel_aura_filters.py loads real LibStub/CallbackHandler/LibAuraInfo,
uses native hex GUID/raw combat payloads, and checks never-selected plate auras,
refresh/stacks/removal/expiry/pet ownership/ambiguity/recycling and both actual
filter page builders with UF per-frame isolation. Rendering/taint in-game pending.
Earlier HUD-test-0.14 and old individual ZIPs retained after prior approval
review deletion block; use manifest. No deletion workaround.


Checkpoint anterior: HUD-test-0.14, Core 0.21 / Options 0.22, com Bags 0.1 e
ResourceBars 0.1. Bags: inventário/banco/keyring nativos, busca, categorias,
qualidade/ilvl/cooldown, scroll e movers; ações mantêm bag/slot reais.
Banco apenas em sessão ativa; botão Native Bank permite comprar/gerenciar
bags do banco, com restauração da janela nativa. /ebags alterna inventário.
ResourceBars: vida/poder, combo Rogue/Cat, runas DK, totems Shaman, cast/channel
e GCD opcionais; /erb, seletor de barra, preview e movers independentes.
Health/Cast começam desligados. Native cast é restaurado ao desativar;
castbar de UnitFrames possui controle separado. Fontes/texturas globais
escrevem campos reais; recursos sem suporte e estilos Retail ficam ocultos.
Originais Retail preservados; somente adaptadores nativos carregam.
validate_inventory_resources.py e regressões Search/Presets/UnitFrames passam;
158 arquivos Lua compilados em Lua 5.1. Confirmação visual/no cliente pendente.

Core 0.20: usuário esclareceu que não conseguia digitar nos dois campos Search.
ReleaseWrathPanelKeyboard desativava teclado dos EditBoxes em cada show/hide.
Agora libera foco e habilita teclado dos EditBoxes; frames de captura de
keybind continuam desativados até click/armamento. Autofocus permanece off.
validate_search.py reproduziu falha antes da correção e passou cleanup/reopen,
handlers reais de digitação/debounce/Escape/Enter, filtro/restauração da página,
popup de features, indexação de páginas não visitadas e navegação do resultado.
140 Lua compilados e regressões Widgets/UnitFrames/Esc Options passaram.
Checkpoint atual HUD-test-0.13; digitação no cliente aguarda confirmação.

Core 0.19 / Options 0.21: usuário retomou Presets. Profiles > Presets usa o
seletor EllesmereUI/Blizzard/Classic em jogo; nenhuma gravação antes de confirmar
reload. Remove o intercept Wrath do popup VideoGuides ausente. Temas usam
cópias TGA RGBA power-of-two em media/backgrounds_335, incluindo base/sombra,
overlay e o Lich King fornecido pelo usuário. PNGs originais preservados.
Lich King acrescentado com accent azul-gelo #5CC3EB. Match Accent to Theme
em Global Settings > General > DISPLAY segue a paleta por padrão no Wrath;
desligar restaura accent do perfil. Swatches custom/class desligam matching.
Show Spell ID on Tooltip em General > DEVELOPER agora usa hooks nativos de
spell/action/macro/buff/debuff/chat-link em GameTooltip/ItemRefTooltip;
dedup por tooltip, suporte a modificadores, aura ID na posição 11 do Wrath.
Não usa TooltipDataProcessor nem CVar Retail no Wrath. Validadores específicos
de Presets/temas e IDs passaram. 140 Lua compilados e regressões UnitFrames,
Widgets, Minimap, Esc Options e Character. Checkpoint dessa etapa HUD-test-0.12;
visuais e IDs no cliente aguardam confirmação.

BlizzardSkin 0.3 / Options 0.20 / Core 0.18: corrigido overlap das abas Character
e ampliada a aparência do paper doll conforme a referência enviada. Novo
EUI_CharacterSheet_335.lua: 660x580, slots/modelo reposicionados, ilvl individual
e média equipada, header nome/título/classe, sidebar de stats Wrath nativos com
scroll/collapse/tooltips. Titles/Equipment abrem ações nativas. Abas usam tamanho
do texto/gap e wrap com footer adicional; Pet segue disponibilidade nativa.
Ammo e slots mantêm parent/scripts; duas mãos contam em ambos os slots da média.
Cache não usa GET_ITEM_INFO_RECEIVED (ausente no Wrath): retry visível limitado
a 15s. Restaura geometria/visibilidade/alpha/UIPanel-width/picker ao desligar;
skin Character off restaura também abas. Combate adia mudanças, frames reusados.
Controles /ebs > Blizzard Window Skins > CHARACTER ENHANCEMENT; Core exporta
as duas novas chaves no bundle opcional de skins. Passaram character_sheet,
blizzardskin e UnitFrames/sintaxe dos 139 Lua, incluindo roundtrip das chaves.
Referências Retail preservadas. Presets retomado em Options 0.21 acima.
Visual no cliente ainda aguarda confirmação; pacote dessa etapa HUD-test-0.11.

Core 0.17: usuário reportou tutorial Unlock Mode sobre botões do sidebar e
botão vazio no tutorial Edit Mode. Sidebar Wrath agora mostra orientação
somente no mouseover de Unlock Mode, ancorada à direita; hide imediato em
leave/hide/click, sem popup automático ao abrir o painel. Edit Mode Okay
recebe fonte/limites/alpha/ordem de desenho explícitos; clique fecha, cancela
fade e grava unlockTipSeen. Executados handlers reais em fixture local e
compilação dos 138 Lua/UnitFrames. Confirmação visual no jogo pendente.
Presets foi pausado por "hold on"; proposta preservada em
backport-tools/paused-presets-navigation.patch. Retomado e aplicado em 0.21.

UnitFrames 0.6: corrigido SetText(): Font not set em UF_BlizzLevelRefresh
(visual Blizzard, primeiro InitializeFrames). A fonte numérica Retail é
opcional; antes do primeiro texto, define fonte selecionada/tamanho do nível
ou do nome e usa fonte nativa se o arquivo for rejeitado. Mantém herança do
nome quando disponível. Regressão reproduziu a ausência do FontObject antes
da correção; passaram criação sem fonte/nome para player/target/focus, tamanho
personalizado, herança posterior, arquivo ausente, eventos de nível, skull,
ocultação e demais testes de UnitFrames; 138 arquivos Lua 5.1 compilados.
Pacotes UnitFrames 0.6 e HUD-test-0.9; confirmação no cliente pendente.

Base instalada para teste: Core 0.21, Options 0.22, UnitFrames 0.6, Minimap 0.1,
ActionBars 0.7, Chat 0.3, Nameplates 0.3, BlizzardSkin 0.3, Bags 0.1 e ResourceBars 0.1.
Core 0.16 acrescenta acesso pelo Esc/Interface; 0.15 ajustou os overlays de
auras no Unlock. Core 0.14 do handoff original permanece a base histórica.

Checkpoint atual — 30/09/2026: após Core 0.15, o usuário confirmou "Great so far
so good" e pediu excluir os builds antigos e salvar o atual. A combinação
confirmada tinha Core 0.15. Core 0.16 está em teste para o novo pedido Esc;
UnitFrames 0.6 corrige o nível no visual Blizzard e aguarda confirmação no jogo.
Pacote atual EllesmereUI-3.3.5-HUD-test-0.14.zip.
Versões, tamanhos e hashes SHA-256 estão em ELLESMEREUI_335_CURRENT_BUILD.json;
continuidade em CODEX_HANDOFF_EllesmereUI_335_CURRENT.md.

Limpeza autorizada: manter somente os onze ZIPs atuais (bundle completo e dez
addons individuais); excluir ZIPs antigos EllesmereUI no diretório AddOns.
Isso substitui as recomendações históricas abaixo para preservar esses ZIPs.
Código instalado, ferramentas, notas, fontes Retail e arquivos de outros addons
ficam fora do escopo da limpeza. A confirmação não detalha cobertura de combate,
taint ou todas as telas.

Checkpoint histórico — 30/09/2026: usuário informou "sem erros" após
Nameplates 0.1 / Options 0.15, pedindo cores de classe nos jogadores aliados.
Combinação: Core 0.14 / Options 0.15 / UnitFrames 0.5 / Minimap 0.1 /
ActionBars 0.2 / Chat 0.2 / Nameplates 0.1. O relato não especifica cobertura
completa de funcionalidades, aparência, combate ou taint. Preservar o pacote
Nameplates-test-0.1 como checkpoint anterior ao ajuste de cores.

Checkpoint histórico de teste no cliente — 30/09/2026: após a correção da
inicialização e dos callbacks do Unlock Mode no ActionBars 0.2 e reinício do
WoW, o usuário informou "ok no errors to report".
Combinação confirmada sem erros reportados: Core 0.14 / Options 0.12 /
UnitFrames 0.5 / Minimap 0.1 / ActionBars 0.2. Preservar como base para as
próximas etapas. Checkpoint anterior: Core 0.14 / Options 0.11 / UnitFrames 0.5 /
Minimap 0.1, confirmado com "ok no bugg report" após a correção de texturas.
O relato não detalhou quais cenários foram testados; não implica cobertura
completa de todos os recursos. O checkpoint anterior, Core 0.14 / Options 0.10 /
UnitFrames 0.4, também havia recebido "ok sem erros a reportar".

Preferência do usuário (30/09/2026): após cada correção concluída, iniciar
D:/Jogo/Whitemane/Games/FrostmourneRebuffed/Wow.exe, com essa pasta como diretório
de trabalho, para teste manual. Pedido atualizado: se esse executável já estiver
rodando, encerrar seu processo e iniciar novamente após a correção validada.
O usuário autorizou explicitamente fechar o processo para testar as correções.

UnitFrames original: D:/World of Warcraft/_retail_/Interface/AddOns/EllesmereUIUnitFrames.
Os arquivos originais dessa pasta foram apenas lidos/copiados.
As adaptações estão no addon do cliente Wrath.

Mudanças: adaptadores locais de CreateFrame/eventos/renderização;
eventos de recursos antigos, filtros por unidade, talento -> especialização;
tuplas e timers de casting/canais, menus seguros via ação menu do Wrath;
UnitAura para auras básicas; indicadores de liderança/assistência;
vida/poder percentuais e curvas numéricas/de cor; combo points/runas.

Options 0.8 habilita EUI_UnitFrames_Options.lua com Main Frames, Boss Frames e
Mini Frames. Player Aura Bars permanece desabilitado. Mantém as proteções de
foco de Options 0.6 e o ajuste GetSpellInfo de 0.7.
Durante o trabalho havia uma pasta Options com metadados 0.1: foi preservada
em EllesmereUIOptions-before-UnitFrames-backport.zip e a base 0.7 restaurada.

Limitações: veja EllesmereUIUnitFrames/README-335.md. Não anunciar os controles
de classificações Retail, escudos/previsões, masks/clipping e atlas como portados.
Não adicionar namespaces falsos nem propagação fictícia de teclado.

Validação: backport-tools/validate_unitframes.py usa Lupa Lua 5.1 instalado em
.codex-tools; sintaxe de todos os Lua dos três addons, testes de eventos/foco,
casting e canalização, timers/curvas, construção dos frames, registro das opções,
filtros de auras. Ambiente simulado, sem validação in-game ou visual.
backport-tools/package_unitframes.py valida TOCs, nomes internos e integridade ZIP.

0.2 corrige a dependência de issecretvalue antes de Options carregar. Predicado
local ns.Wrath.IsSecretValue fornece false no Wrath e preserva uma API nativa
existente. Engine e main capturam esse adaptador. O mock agora deixa as APIs de
secret values ausentes; reproduziu o erro original na linha 4075 e passou após
a correção. Nenhuma alteração nas proteções de foco ou na versão de Options.

0.3 trata o crash nativo do relatório 2026-09-30 00.57.26 Crash.txt:
ERROR #132 / ACCESS_VIOLATION, addon EllesmereUIUnitFrames, função
SetRotatesTexture, objeto (null). O relatório identifica a chamada; não prova
a causa interna do cliente. ApplyFillRotation agora retorna antes dessa API
no Wrath, mantendo SetOrientation e a rotação padrão da textura. Fora do Wrath,
também evita chamar a API quando GetStatusBarTexture não retorna uma textura.
O mock passou a expor SetRotatesTexture como uma chamada fatal: o código 0.2
atingiu a chamada durante InitializeFrames -> CreateHealthBar ->
ApplyHealthBarTexture. Após a correção, inicialização/reload e casos de ambas
as orientações, com/sem textura, passam sem chamar o método. Crash nativo e
renderização ainda precisam de confirmação no cliente real.

0.4 corrige AtlasUtil:Unpack(nameplates-icon-elite-gold) no preview da página
UnitFrames (Options linha 3165). O cliente tem SetAtlas, porém o atlas não existe.
O adaptador agora protege a chamada por região, com consulta C_Texture/AtlasUtil,
preservando atlas válidos. Fallbacks: badge elite/rare TGA, sprite de classe do
Core, felicidade do pet da textura Wrath, UI-StatusBar para o fill de casting.
Atlas desconhecidos limpam a textura; wrappers abrangem CreateTexture,
CreateMaskTexture e GetStatusBarTexture. Badge convertido do PNG existente do
Core para TGA RGBA 64x64, preservando os pixels 43x43 e sem alterar o Core.
O mock com SetAtlas existente/registro vazio reproduziu o erro informado antes
da correção. Testes de registro vazio/válido, C_Texture/AtlasUtil, fallbacks e
regiões retornadas passam após a correção. Options continua 0.8; a fábrica local
da sua página usa ns.Wrath.CreateFrame, por isso recebe a proteção do módulo.

Options 0.9 corrige SpecOverrides_EditSessionActive ausente em Widgets:9727.
O Core não carrega o sistema de Spec Overrides; a linha de visibilidade agora
consulta as funções opcionais somente se existem e edita os valores compartilhados
normalmente quando ausentes. Protege SlotOverridable, EditSessionActive e
ClearStoreKey nos widgets e CloseEditSessions na confirmação da troca de estilo.
Nenhum sistema falso foi criado e nenhum arquivo adicional do Core foi habilitado.
validate_visibility.py reproduziu o erro informado antes da correção e depois
passou com APIs ausentes/presentes, edição compartilhada, limpeza/ownership,
slots excluídos e checklists duplos/direita. Executa funções reais dos Widgets e
do Core de visibilidade, com a construção gráfica do dropdown em mock.

Pacotes atuais: EllesmereUIUnitFrames-3.3.5-0.5.zip;
EllesmereUIOptions-3.3.5-0.17.zip;
EllesmereUIMinimap-3.3.5-0.1.zip;
EllesmereUIActionBars-3.3.5-0.2.zip;
EllesmereUIChat-3.3.5-0.2.zip;
EllesmereUINameplates-3.3.5-0.3.zip;
EllesmereUIBlizzardSkin-3.3.5-0.1.zip;
EllesmereUI-3.3.5-BlizzardSkin-test-0.1.zip (os oito addons juntos).

Options 0.10 corrige _NotifySettingWrite ausente em Widgets:1363 ao iniciar
arraste do slider. O hook pertence à captura opcional de Spec Overrides e não
existe no Core Wrath. Todos os usos dos widgets compartilhados e da página
UnitFrames agora consultam sua existência, preservando a gravação do valor,
_settingsChanged, refresh e a notificação quando o hook existe. Nenhuma API
fictícia foi adicionada. validate_widgets.py reproduziu exatamente a pilha do
erro antes da correção. Depois passaram arraste/release/commit digitado do slider,
toggle, callbacks de cor/cancelamento e hook ausente/presente/removido.

Minimap 0.1: referência Retail em
D:/World of Warcraft/_retail_/Interface/AddOns/EllesmereUIMinimap. Cópia do main
preservada com SHA256 igual ao original. O TOC carrega apenas a implementação
EUI_Minimap_335.lua, específica para APIs Wrath; main Retail e Media ficam como
referência. Options 0.11 carrega EUI_Minimap_335_Options.lua, uma página com controles
implementados, /emm e integração com Unlock Mode. Veja README-335.md do Minimap.
Inclui quadrado/círculo, borda sólida, tamanho/posição/opacity, Shift + arrastar,
rotação/zoom/timer real, relógio/zone/coords/FPS, elementos nativos e popup de addons.
GetPlayerMapPosition respeita o contexto do mapa-múndi aberto. Desabilitar restaura
o minimapa e os botões capturados. Alterações de layout em combate ficam pendentes.
Não depende de UnitFrames, SetAtlas, secret values ou eventos Retail.
Recursos Retail exclusivos e bordas texturizadas/retangular não são expostos.

Validação Minimap: validate_minimap.py executa a implementação e a página reais
em mock com APIs antigas, contexto do mapa, timers, cliques/menu, arraste/unlock,
agrupamento/ocultação/restauração, visibilidade e fila de combate. Passaram também
99 arquivos Lua 5.1, regressões UnitFrames, widgets e visibilidade. ZIPs validados
quanto a TOCs, estrutura, integridade e conteúdo dos arquivos ativos.

Próximas etapas: partir do checkpoint confirmado Core 0.14 / Options 0.12 /
UnitFrames 0.5 / Minimap 0.1 / ActionBars 0.2. Preservar teste de teclado e reiniciar WoW após
cada correção, encerrando antes o processo do caminho autorizado se estiver aberto.

UnitFrames 0.5: usuário reportou nil em CreatePowerBar:7546 com healthBarTexture
"fade" após instalar Minimap. A falha é no fill retornado por GetStatusBarTexture,
independente do Minimap. Fade e outras 14 texturas do catálogo original medem
256x40. Foram criadas cópias BGRA32 256x64 no módulo e um manifest de caminhos;
Core 0.14 e seus assets permanecem intactos. Adaptador local de SetTexture/
SetStatusBarTexture e catálogo do módulo usam os caminhos convertidos. Falha de
carregamento de barra usa WHITE8X8 real; nil explícito não cria fill fictício.
validate_unitframes.py agora executa catálogo/resolver reais e simula rejeição
de dimensões/arquivos. Antes da correção reproduziu a pilha exata da linha 7546.
Após a correção passaram Fade na inicialização, rebuild de todas as seleções,
preview, arquivo ausente, caminho nativo válido e limpeza explícita. Após reinício,
o usuário confirmou ausência de bugs reportados; essa combinação é o checkpoint
atual registrado no início deste documento.

ActionBars 0.1: referência Retail copiada de
D:/World of Warcraft/_retail_/Interface/AddOns/EllesmereUIActionBars sem alterar
o original. Main/Flyout Retail ficam fora do TOC. Implementação Wrath própria,
com LibActionButton local BSD do ElvUI instalado, identidade isolada e sem
captura LibKeyBound. Não depende de ElvUI. Seis barras, páginas/poses/formas,
atalhos seguros, drag/drop, pet/stance nativos, controles de layout/cosméticos.
Vehicle UI, saída/mira, possessão, XP/Rep, bolsas, micro e totems ficam nativos.
Layout adiado em combate; scripts seguros cuidam de páginas/visibilidade/atalhos.
Ao desabilitar, restaura frames nativos e libera bindings sem regravar as teclas.
Options 0.12 tem nove páginas de ActionBars e adapta seus cards Fonts/Textures/
Styles para não expor recursos Retail ausentes. /eab e Unlock Mode disponíveis.
Recursos não portados e roteiro de teste em EllesmereUIActionBars/README-335.md.
validate_actionbars.py executa biblioteca, módulo, snippets, opções e cards reais
com fixture legacy que rejeita escritas inseguras em atributos em combate.
Não valida taint, renderização ou casts reais; aguarda teste manual no cliente.
Preservar o checkpoint Core 0.14 / Options 0.11 / UnitFrames 0.5 / Minimap 0.1.

ActionBars 0.2: usuário reportou self nil em OnInitialize:261 e depois banco
ausente no loadPosition:282 do Unlock. Core safecall usa xpcall(func,handler,...),
que não encaminha argumentos em Lua 5.1. OnInitialize agora captura addon.db,
como o Minimap, sem alterar Core 0.14. OnEnable exige banco e callbacks de
posição toleram ausência temporária. validate_actionbars.py executa safecall
real do Core com xpcall nativo Lua 5.1; reproduziu o erro 261 antes da correção.
Inclui callbacks do Unlock com banco ausente e preserva os testes de combate/
páginas/atalhos. Após reinício do WoW, o usuário confirmou "ok no errors to report".
Essa combinação é o checkpoint atual. O relato não especifica cobertura de todos
os cenários de combate, veículos, formas, pet, renderização ou taint.

Chat 0.1: referência Retail copiada sem modificar o original. TOC carrega só
EUI_Chat_335.lua. Mantém o backend/janelas/abas/input nativos do Wrath; acrescenta
fundo/borda/fontes, timestamps, URLs/cópia, buffer de sessão, scroll/fading,
posição pelo Unlock e restauração. Não carrega engines Retail/bubbles/Forever.
Options 0.13 acrescenta Chat/Fonts e limita cards Fonts/Textures/Styles ao que
foi implementado. /echat abre as opções, /ecopy copia; veja README-335.md.
validate_chat.py usa Lite/NewDB/safecall reais e funções de FrameXML 3.3.5;
testa inicialização, input/events/links preservados, URL/link integrity,
cópia/ClearFocus, buffer/Clear, janelas temporárias, combate/unlock/reset,
restore/re-enable/wrappers externos e opções/cards. Aguarda confirmação no
cliente após reinício. Preservar o checkpoint Options 0.12 / ActionBars 0.2.

Chat 0.2 / Options 0.14: usuário pediu skin quadrada como ElvUI. Square Skin
fica em /echat > Chat, ligada por padrão; troca a arte das abas/scroll por
painéis planos, bordas retas e underline da aba ativa. Mantém os botões nativos,
seus scripts de click/docking/drag e alertas. Sem dependência ElvUI. Desligar
a opção ou módulo restaura alpha/níveis/arte nativa. Teste local inclui funções
FCFTab_UpdateColors e FCF_Tab_OnClick reais, seleção/menu e restauração.
A aparência da nova skin ainda aguarda confirmação no cliente.

Nameplates 0.1 / Options 0.15: referência Retail preservada e engines fora do
TOC. Overlay próprio sobre as placas anônimas de WorldFrame; vida percentual,
cast/progresso/ícone, nomes/nível/elite, raid marker, ameaça, seleção e fontes.
Alvo/mouseover inferidos por nome + alpha/highlight nativo e candidato único,
com GUID validado e dados de UnitAura/cast somente nessas placas. Sem aliases
nameplate1 ou namespaces Retail falsos. Preserva click rect, scripts, parent,
tamanho e alpha do frame nativo; restaura arte/CVar ao desligar. Layout/CVars
adiados em combate. Cache de layout evita reconfigurar fontes por tick.
Options inclui três páginas /enp e cards globais limitados às funções Wrath.
validate_nameplates.py passa com o Lite/safecall real Lua 5.1, incluindo casos
de nomes iguais, reciclagem/GUIDs, casts/canais, filtragem/cap de auras, ameaça,
click/alpha, combate/restauração/reuso, descoberta e opções/cards reais.
Contratos das placas consultados no ElvUI-WotLK instalado e fonte primária;
sem dependência dele. README documenta limites e roteiro de teste. O cliente
ainda precisa confirmar aparência, combate e taint. Preservar o checkpoint
confirmado Core 0.14 / Options 0.12 / UnitFrames 0.5 / Minimap 0.1 / ActionBars 0.2.

Nameplates 0.2 / Options 0.16: a pedido do usuário, a opção existente Class
Colored Names continua colorindo jogadores aliados conhecidos após remover
target/mouseover. Nova opção somente para a barra: Class Colored Health Bar,
em FRIENDLY PLAYERS, desligada por padrão. Roster Wrath de player/party/raid
fornece classe sem seleção; target/mouseover/focus alimentam cache de aliados
fora do grupo até PLAYER_ENTERING_WORLD. Hints por nome são exclusivamente
cosméticos e só se aplicam à placa nativa azul de jogador aliado quando não
há unit identificado. NPCs/nomes ambíguos/classes desconhecidas conservam
cor nativa. Não são usados para GUID/cast/auras. Testes ampliados: classes
Mage/Priest/Warrior, controle independente de barra/nome, opção existente única,
grupo/raid atualizados, persistência sem mouseover, same-name/NPC/reuso/cache.
Cliente aguarda teste do ajuste; checkpoint confirmado agora é Nameplates 0.1
com Options 0.15 e os demais addons descritos no início deste documento.

Nameplates 0.3: usuário reportou caixa vermelha de aggro fora da barra de vida.
O flash nativo conserva as dimensões antigas, e o cliente pode reescrever alpha
durante a animação. A borda de ameaça própria é filha e SetAllPoints da barra
de vida, seguindo tamanho, offset e escala; mantém cores/visibilidade nativas
sem mudar o clique/layout do frame original. O flash nativo tem a textura
esvaziada e restaurada ao desligar o módulo, enquanto seu estado e cores
continuam disponíveis. Não há mudança no Core ou no código de Options 0.16.
Regressão local reproduziu a textura nativa reaparecendo após alpha animado;
com o ajuste passam supressão do desenho antigo, ancoragem, tamanho/offset/
Target Scale, mudanças de ameaça, hide/reuso, friendly name only e restauração.
Sintaxe Lua 5.1 dos 121 arquivos também passou. Aguarda confirmação visual
da caixa de aggro no cliente. Pacotes 0.1 e 0.2 continuam preservados.

BlizzardSkin 0.1 / Options 0.17: referência Retail preservada byte a byte, fora
do TOC; implementation Wrath própria. Catálogo de janelas nativas com painel
escuro/borda/accents/fonts, botões e close buttons, equipamentos Character/
Inspect com quality borders/crop; tooltips, pause menu, popups e context menus
legados. Backend/conteúdo/cliques/input/models/rects permanecem nativos. LOD e
OnShow descobrem telas sem forçar addon load. Skin writes adiados em combate,
restore/re-enable preservam scripts sem duplicar frames. Dados de conta usam
as chaves já exportadas no bundle Core BlizzardSkin; disableWindowSkins segue
o perfil. Opções /ebs /ebui têm duas páginas. Cards Fonts/Textures adaptados e
Styles exclui Character Sheet Retail/Skyriding. Não há Core novo ou namespace
moderno falso. Recursos exclusivamente Retail e layouts especiais não são
anunciados como portados; limites/roteiro em BlizzardSkin/README-335.md.
validate_blizzardskin.py passou com Lite/safecall real Lua 5.1 e controles
nativos em fixture restrita: capture/off inicial, fontes/contraste, gear,
input/cliques/rects, LOD, combate, restore/re-enable, kill switch, tooltips/
menus e opções/cards. Guard de scripts GameTooltip evita aplicá-los em Frame
comum. Sintaxe dos 136 arquivos e regressões Unit/Chat/ActionBars/Minimap/
Nameplates/widgets/visibility passaram. Aparência e taint aguardam teste real.
Preservar Nameplates-test-0.3 e o checkpoint confirmado Nameplates-test-0.1.

BlizzardSkin 0.2: usuário relatou que a versão 0.1 mantinha grande parte da
aparência Blizzard e autorizou DragonUI como referência alternativa. Ampliado
o tratamento dos painéis internos conhecidos e famílias de chrome, com insets,
campos de texto/dropdowns, abas com accent de seleção nativa, botões/checks,
setas/thumbs planos e ícones de spells/itens quadrados. A arte decorativa é
esvaziada para resistir a alpha animado; hooks de atualizações nativas e OnShow
reaplicam. Desligar restaura texturas, alphas, backdrops/cores/fontes/crop,
preservando ações e estado atual dos controles. Mapas, árvores de talentos,
modelos, cooldowns e overlays de aceite do Trade permanecem como conteúdo.
DragonUI/characterpanel chrome e tabs foram lidos como referência, sem editar
ou carregar seus módulos/assets. Core 0.14 e código/versão Options 0.17 intactos.
Regressões Lua 5.1 ampliadas em validate_blizzardskin.py passaram: child art,
abas/hover, input/scroll/checks/dropdown/cliques, ícones/cooldowns, animação e
refresh, conteúdo preservado, restore/reuse, combate e opções. Aparência e
taint ainda dependem da verificação no cliente. Pacotes BlizzardSkin 0.1
preservados; novo combinado BlizzardSkin-test-0.2 para os oito addons.

ActionBars 0.3 / Options 0.18: usuário reportou Micro Menu/Bag Bar/XP/Rep ainda
sem skin e Player Buffs/Debuffs sem mover editável. Novo NativeHUD_335 oferece
skins quadradas com ações/tooltip/drag nativos, hit rects corretos, KeyRing e
botões Rebuffed (Store/Collections/Paragon); barras próprias planas atualizadas
por XP/rested/facção observada, max level/facção vazia com preview no Unlock.
Seis elementos reais registrados na mesma integração Unlock do ActionBars;
auras/enchants mantêm botões, timers e cancelamento, com grupos separados e
posições persistidas no perfil ActionBars. Refresh nativo não desfaz drag ao
vivo. Layout/protected writes adiados em combate e restore/reuse cobertos.
Core 0.14 e BlizzardSkin 0.2 intactos; menus/opções novas em /eab > Blizzard UI.
validate_actionbars executou biblioteca/snippets reais e novos cenários HUD;
NewDB/MakeUnlockElement reais verificaram migração e contrato dos movers.
Detalhes/roteiro manual em ActionBars/README-335.md. Renderização, taint e
persistência no cliente ainda aguardam teste. Preservar BlizzardSkin-test-0.2
e os checkpoints anteriores; novo combinado HUD-test-0.1 com os oito addons.

ActionBars 0.4 / Options 0.19: usuário pediu XP com skin ElvUI, controle para
remover arte Blizzard e consolidação de opções. XP azul, rested roxo, fundo
escuro/borda plana e fill inset usam ElvUI Norm copiado do asset instalado;
zero XP e rested zero/ausente não pintam a área vazia. Reputação mantém standing.
Hide Blizzard Bar Art esvazia/restaura somente texturas dos containers de arte,
preservando scripts/children e micro/bags quando suas skins são desligadas;
alterações em combate aguardam regen. /eab tem uma página Action Bars com
Select Bar para 14 grupos, layout/reset da seleção e Global Settings. Dimensões
HUD e colunas de auras separadas usam fallback dos campos antigos até edição.
Atalhos dos movers selecionam o grupo correto, inclusive antes do lazy load.
Core 0.14 e demais módulos intactos. validate_actionbars passou com biblioteca,
snippets e NewDB reais, cores/asset/layers XP, art on/off/combate/restore,
14 seleções, isolamento de dimensões/resets/callbacks e atalhos. Compilação
Lua 5.1 dos 137 arquivos, UnitFrames e widgets passaram; pacotes/TOCs/ZIP
verificados. HUD-test-0.1/ActionBars 0.3/Options 0.18 preservados; novo combinado
HUD-test-0.2 contém os oito addons. Aparência e taint ainda aguardam teste real.

ActionBars 0.5: usuário reportou GetScale nil em NativeHUD linha 38 durante
OnEnable. Texturas nativas ExhaustionLevelFillBar/ExhaustionTick não oferecem
APIs de Frame no Wrath. Apply agora usa captura/restore de textura para esses
objetos; snapshots de geometria só leem/restauram escala quando disponível.
A fixture foi restringida para essas regiões e reproduziu exatamente GetScale
nil antes do ajuste. Inicialização real via safecall, restore path/alpha/coords,
re-enable e cenários ActionBars/HUD/options passaram após o ajuste. Compilação
dos 137 arquivos Lua 5.1 e regressões UnitFrames passaram. Options 0.19/Core
0.14 e demais módulos preservados. Pacotes ActionBars 0.4 e HUD-test-0.2
preservados; novo combinado HUD-test-0.3. Ainda aguarda confirmação no cliente.

ActionBars 0.6: usuário reportou SetText(): Font not set em UpdateData linha
187. Fonte era aplicada depois de SetText; movida para antes de todos os
ramos de texto de XP/reputação. Fixture agora rejeita texto sem fonte nos data
bars sem template: reproduziu o erro antes da correção e passa depois.
Verificados primeira atualização e mudanças de tamanho nas duas barras, além
dos cenários existentes ActionBars/HUD/options. Sintaxe dos 137 Lua e regressão
UnitFrames passaram. Options 0.19/Core e demais versões mantidos; pacotes
anteriores preservados, novo ActionBars 0.6 e combinado HUD-test-0.4.

ActionBars 0.7: usuário reportou self nil no método IsUnlockModeActive do Core
linha 77 a partir de UpdateData. Corrigidas as três chamadas no ActionBars/HUD
para E:IsUnlockModeActive(): previews, refresh/drag e alpha mouseover. O Core
não foi alterado. Teste substituiu o stub permissivo pelo método real extraído
de EUI_UnlockMode.lua, reproduziu self nil antes da mudança e passou depois;
cobre sessão aberta/fechada, XP max level/Rep vazio, hover e drag/refresh.
Regressão ActionBars completa e sintaxe dos 137 Lua/UnitFrames passaram.
Options 0.19 e demais módulos mantidos. Novos pacotes ActionBars 0.7 e
HUD-test-0.5; anteriores preservados. Confirmação no cliente ainda pendente.

Chat 0.3: usuário pediu poder arrastar o chat até Y=0. FrameXML Wrath reserva
50px abaixo do chat via inset bottom=-50. Style agora aplica bottom=0 mantendo
laterais/topo e clamping existentes; capture/restore preservam os quatro insets
originais. Apply/OnShow reaplicam, adiando em combate. Posições existentes não
são alteradas; Unlock salva/reaplica Y=0. Regressão validate_chat usa Lite e
callbacks nativos, modelo da margem original e verifica Y=0/posição salva,
refresh/temporárias/combate e restore/re-enable. Passaram Chat e compilação
dos 137 Lua/UnitFrames. Core 0.14/Options 0.19 e demais módulos intactos.
Chat 0.2 e HUD-test-0.5 preservados; novos Chat 0.3 e HUD-test-0.6.

Core 0.15: usuário confirmou que Player Buffs move corretamente, mas via uma
segunda barra Buffs não arrastável somente no Edit Mode. Identificado overlay
nativo somente leitura do Core, não outra coleção de ícones. Catálogo agora
cede Buffs/Debuffs a EUI335_HUD_buffs/debuffs quando o mover está registrado,
inicializado e habilitado. Show retira overlays criados antes da integração.
Sem mover/disabled mantém fallback nativo. Nenhuma aura é escondida/recriada;
timers/cancelamento/posições continuam no ActionBars 0.7. Regresso real do
catálogo/Show reproduziu duplicação antes do ajuste e passou depois: ownership,
desligar/religar, mover ausente, ausência de novos frames e ícones preservados.
ActionBars completo e sintaxe dos 137 Lua/UnitFrames passaram. Demais versões
inalteradas. Core 0.14/HUD-test-0.6 preservados; novos Core 0.15 e HUD-test-0.7.

Core 0.16: usuário pediu EllesmereUI nas opções do Esc. Core original só
adicionava botão no menu Layout/buttonPool Retail. Novo OptionsAccess_335
registra botão Wrath GameMenuButtonTemplate e categoria Interface > AddOns
com Open EllesmereUI, ambos usando EnsureOptionsLoaded e E:Show sob clique.
Sem autoload ao registrar/abrir categoria, sem bindings/input; guard combate,
falha LOD preserva telas nativas. Layout segue Logout e ajusta altura com
Continue, tolerando entradas de outros addons sem ciclo ou expansão repetida.
Registro idempotente/retry em login/PEW/regen e menu pooled preservado.
validate_options_access.py passou; compilação dos 138 Lua e UnitFrames também.
Options/módulos mantêm as versões. Pacotes Core 0.16 e HUD-test-0.8 e manifesto
atualizados; confirmação visual no cliente ainda pendente. Revisão automática
de aprovação bloqueou Remove-Item para Core 0.15/HUD-test-0.7 (motivo: "blocked
by policy"); esses dois ZIPs anteriores permanecem junto aos nove atuais.
