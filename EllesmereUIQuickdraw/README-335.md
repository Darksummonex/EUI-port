# EllesmereUI Quickdraw — Wrath 3.3.5a — 0.3

Only the four EUI_Quickdraw_335 files execute. Original Retail Lua remains
unchanged and unloaded; original XML is stored in Bindings_Retail.xml. The
native Bindings.xml auto-registers 16 EUI_RADIAL actions and is not in the TOC.
Requires EllesmereUI only, without outside libraries/data.

Open /eqd. Configure up to 16 numbered palettes with 20 entries each. Assign
a holdable key in settings or the game's keybindings menu. Assign Key opens
a capture dialog: press the desired key with Ctrl/Alt/Shift as needed, then
release to save. A key already bound to another action asks Rebind/Keep.
Esc/Cancel closes without changing bindings; hiding the page, closing Options,
combat, focus transfer or a 20-second timeout releases capture.

Hold the assigned key to open, point or scroll to choose, release to fire.
After a wheel step, moving the pointer selects by pointer again. The
center/deadzone, empty space or no pointer movement cancels. Escape, and an
optional Cancel key, cancel without leaving temporary bindings behind.
Toggle Menu Open (per palette) latches the menu on release once a Select key
is set: the Select key fires the pointed entry, the menu key or Escape closes.
Select/Cancel keys accept keyboard chords and mouse buttons 3-5.

Ring/arc (30–360 degree span and rotation), horizontal/vertical fan and grid
(fixed or auto columns) layouts support cursor/screen placement, offsets,
radius, size/spacing/scale, opacity, labels, item counts and cooldown swipes.
Entries tint red out of range, blue short of power and grey when unusable;
Hide Unusable drops unknown spells, missing macros/companions/sets and
unavailable dynamic entries. The arc shows the EllesmereUI hub, a dotted
selection needle and an optional action caption; menus fade/pop open.

Nested menus: an "Action Menu" entry (Action Menus category, or Action Type
"Action Menu Number") shows up to 8 actions of another palette one level out.
On the ring they fan outward inside the parent's sector while it is pointed
at; release beyond the ring to fire the nearest child, or on the parent to
close without firing. Grid and fan layouts place child lanes outside the
block edge nearest the parent and pick children by position. Only one level
nests (a nested menu's own Action Menu entries are skipped), a menu cannot
contain itself, and a nested menu with nothing usable is hidden.
Retail coverflow remains unported.

Action types: spells (ID or name), items, macros, macro text, micro-menu and
interface panels, raid target markers 0–8, cycling target markers, the
server's world marker spells "Raid Marker: <Color>" (80945–80952: Yellow Star,
Orange Circle, Purple Diamond, Green Triangle, Silver Moon, Blue Square, Red
Cross, White Skull) and a /castsequence cycle, cast with [@cursor] so they
drop at the pointer (World Markers at Cursor off asks for a ground click),
equipment sets, mounts and
companions (tracked by spell), random/last mount, class resurrection
(druids: Rebirth in combat, Revive outside), dual-spec activation,
professions (including dynamic first/second primary) and Cancel Form.

The options page adds presets (markers, world markers, panels, hearthstones,
teleports, potions, forms, specs, professions, quest items, equipment sets,
mounts), a category picker, Copy Settings From, and a live preview: click to
edit, drag to reorder, right click to remove, drop cursor actions to add.
Palette 1 ships empty; saved entries written against the old sample defaults
are restored once on first load (slotsV2).

SecureActionButton hold/release/click execution is wrapped in native secure
handlers. Selection/wheel/cancel/confirm run in Wrath's restricted
environment; no anonymous functions or direct tables appear in snippets.
Configuration, binding and frame changes defer until combat ends and event
bursts rebuild once per frame; changes while a palette is held or latched
defer until it closes. Direct slot clicks also close the palette to prevent a
second cast when the key is released.

validate_quickdraw.py executes real restricted snippets with native owner
frame references, no-function/no-table checks and combat mutation guards.
Native visual rendering and secure behavior need in-game verification.

Wrath client reference: https://github.com/wowgaming/3.3.5-interface-files
(SecureHandlers.lua, RestrictedFrames.lua, RestrictedExecution.lua and
SecureTemplates.lua). These are references only; no downloaded runtime is used.
