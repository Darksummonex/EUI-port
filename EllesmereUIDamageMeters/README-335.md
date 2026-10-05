# EllesmereUI Damage Meters — Wrath 3.3.5a — 0.3

0.3 adds a live hover breakdown with spell icons, amounts/percentages,
target bars and Other totals. Left-click a player to replace that meter
with the person's spell bars. Its footer selects Spells/Targets; Back
returns to group. Spell bars include native icons and hover hit/crit/range
information. Mouse wheel scrolls. Death focus provides recorded recaps;
right-click opens the separate detailed statistics window. Reports follow
the displayed group/focus view and still require explicit Send.
Focus is transient per-window state. View/profile changes and reset clear
it; hover is cleaned up on reorder/hide. Tooltip rows are preallocated.

0.2 adds independent background, bar and header/footer opacity controls.
Names and values default to OUTLINE with black shadow so white class bars
stay readable. Font Outline and Show Specialization Icons are per-window.
Player talent data and throttled native group inspection provide spec icons;
class icons appear until talent data is available. Inspection runs outside
combat, respects the native Inspect UI/other queries and verifies GUIDs.
Known segment icons are retained across talent switches. No external
cache/library is used. Existing windows retain their values and gain the
new defaults. Native talent availability/range can delay group icons.

An independent implementation of the combat functions needed on Wrath.
The installed Details main addon was inspected as a protocol reference;
no separate Details plugins were installed. No Details code, libraries,
globals, plugin APIs or SavedVariables are required or loaded here.
The original EllesmereUI Retail Lua/media are retained byte for byte as
unloaded references. Only the five EUI_DamageMeters_335 files run.

Open `/edm` or EllesmereUI > Damage Meters. Two windows (damage/healing)
start enabled; create up to four in Windows. Change metric by clicking
the header and segment by clicking the footer. Scroll those menus for
additional entries. Drag the header or use Unlock Mode. Scroll rows;
left click focuses that player inside the meter, right click opens statistics.
The deaths view opens the last 20 seconds (up to 40 damage/heal events)
before each observed death. Spell entries have native spell tooltips.

Included: damage/DPS, healing/HPS, overheal, healing received, damage taken,
enemy damage taken, friendly/self damage, absorbs received, blocked/resisted
damage, misses/avoidance, interrupts, dispels/spellsteal, casts, resurrections,
crowd-control breaks, resource gain events and separate mana/rage/focus/
energy/runic amounts, buff/debuff uptime and current-target native threat.
Default collection concerns combat involving the player/group; unrelated
outsider combat is ignored. Group Only controls actor display, while enemy
damage taken deliberately displays affected enemies. Pet/guardian merging
uses roster ownership and summon events; toggling affects future events.

Current/last, overall and 1–30 saved segments are selectable. DPS/HPS divide
by encounter duration, rather than per-actor activity. The end grace allows
late/continuing combat to join the segment; duration freezes when group
combat stops. Overall rows combine live/current summaries without copying
the full spell/target history on each refresh. Spell tables merge on demand.

Settings live in EllesmereUIDamageMetersDB through the EllesmereUI profile
system. Combat history is separate, per character, in this module's own
EllesmereUIDamageMetersHistory SavedVariables. It survives logout/reload
when Save History Between Sessions is enabled and is excluded from UI
profile exports. Reset requires confirmation and is blocked during combat.
Disabling collection unregisters CLEU and hides its windows/popups.

Wrath limits: absorbed damage belongs to the recipient. The collector does
not invent a shield caster from ambiguous damage-log absorption fields;
shield healing is not added to Healing Done. Aura uptime is the sum of
observed aura seconds across targets, not a universal 0–100% percentage;
pre-combat helpful auras are seeded from native UnitAura. Resource amounts
of different power types are not mixed. Threat is live for the selected
target and is not a historical combat-log estimate. Combat-log visibility,
unseen pet ownership and server-specific events can limit completeness.
This implementation does not load arbitrary Details plugins or import its
historical data, and is not a promise of parity with every Details feature.

The R button opens a local copy/preview. Only Send queues chat messages;
channel availability is checked, messages are paced, and module disable
cancels the queue. `/edm show`, `hide`, `reset`, `report` are also supported.
All runtime frames are unprotected, rows are preallocated, native frame
creation/Escape bindings/game menus are untouched. Report EditBoxes never
autofocus and clear focus on hide. Client rendering/real encounter totals
still require in-game review.

Validation: `python backport-tools/validate_damagemeters.py` executes the
actual Lua 5.1 Core lifecycle, native eight-field CLEU parser, segmented/
overall calculations, pets, statistics, recaps, aura timing/reconciliation,
history reload/retention, threat, profile callbacks, windows, options,
Unlock Mode and explicit report flow with Details unavailable. It checks
native CreateFrame identity, font-before-text, no row allocation during
combat refresh, Lua compilation and unchanged Retail references.
