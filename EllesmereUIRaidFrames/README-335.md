# Raid Frames 3.3.5 — 0.6

0.6 adds Color Frame by Debuff Type (Debuffs tab, Dispel Frame Color). When a debuff your
character can currently remove is on a unit, the health bar swaps to the type colour
(Magic blue, Curse purple, Disease brown, Poison green). Removability comes from the
client's RAID debuff filter, so class, spec and talents are respected without tables.
Priority when several are present: Magic, Curse, Disease, Poison. Color Strength blends
between the normal bar colour and the type colour. Preview frames demo the effect.

# Raid Frames 3.3.5 — 0.5.1

0.5.1 fixes the header never appearing: the Buffs/Debuffs page build now asks the panel to
show the header (getHeaderBuilder alone is only the cache hook, and nothing was requesting it).

0.5 notes:

0.5 moves the retail-style Buffs/Debuffs indicator editor into this module
(EUI_RaidFrames_335_Indicators.lua); no other addon folder needs changes.
- Fixed header: preview built from settings (no group/raid needed), Editing Spec
  dropdown (All Specs + the three talent trees) and the indicator list with enable
  switch, delete and an Add New menu.
- Scrolling page: Group Selection, selected indicator (enable/name), Assigned Buffs,
  Position (position, growth, X/Y) and Display.
- Per-spec lists: the first edit while a spec is selected copies the shared list for
  that spec; "Use Shared List" removes the copy. The active talent tree's list is used
  by the frames, and they refresh on respec / talent-group change.
- The editor installs itself when the load-on-demand options addon loads and applies
  to Raid Frames only; Unit Frames keep the stock Buffs/Debuffs builders.

# Raid Frames 3.3.5 — 0.4

0.4 uses shared geometry for native live aura icons and the options preview.
The old automatically-created broad Buff Icons default becomes explicit
healer assignments while retaining its visual settings. Named/manual or
custom-filter indicators are preserved. Personal defensive and external
presets occupy separate positions; other buffs are assigned manually.
Defaults use a 3+2+2 icon budget, with eight shared per aura type.
Externals accept other casters independently of global Own filtering;
per-indicator Own Only, exclusions and hard aura constraints still apply.
The preview follows the selected raid layout/party config, supports clickable
indicator selection and live position/growth/size/text/style changes.
Native secure roster/click casting, subgroup sorting and combat rules remain.

0.3 defaults existing/new profiles to Tank > Healer > DPS sorting inside
each raid subgroup and in the party. Unknown roles remain last; the module
does not infer healers from class. Both native Boolean and string role APIs
are supported, with native main-tank assignment fallback. Member Sorting
can still use Name or Roster Order. Hide DPS Role Icons hides only their
icons, keeping DPS frames visible; tank/healer icons follow Role Icons.
Role ordering uses Wrath secure header nameList order and updates outside
combat. Role/name/roster changes to those lists wait until combat ends;
new names/subgroup changes can therefore wait for that refresh. Roster/Name
sorting retains native automatic membership updates in combat.

Buffs and Debuffs now have separate pages with group/layout selection and
independent icon indicators: selector, add/remove/rename/enable, assigned
spell IDs, filter/own-only, raid/party display, custom spell order, anchor,
growth/offsets, icon limit, size/spacing/opacity/border, swipe/duration text,
stacks and hide-icon controls. Each aura type shares eight preallocated
icons across up to eight indicators per frame; the UI enforces that budget.
Global aura exclusions/filters apply before indicator selection. The existing
Aura Filters page remains available. Settings are separate per raid layout
and party, and protected layout changes defer until combat ends.

Open Raid Frames in EUI or use /erf (/rf). Requires Core 0.23 and Options
0.26. The TOC loads only the three native EUI_RaidFrames_335 Lua files and
their secure XML template. Retail Lua/media originals remain unchanged,
unloaded references. Settings and positions use the Core's EllesmereUIDB
profiles, including profile switches, imports and resets.

Pages: Raid, Party, Aura Filters, Click Casting. Raid and party have separate
dimensions, textures, fonts, power bars, health text, class colors, range
fading, sorting, roles, leader/raid markers, ready checks and aura settings.
Raid groups can run across or down, with up to eight groups of five members.
The preview uses separate nonsecure buttons; it never replaces live members.
Unlock Mode moves Raid Frames and Party Frames. Global Fonts and Textures
edit the same live settings used by the module.

Raid > RAID LAYOUTS: Use Raid Layout selects Automatic, 10 Players, 25 Players
or 40 Players. Automatic uses the raid/battleground instance capacity when
available, otherwise the current raid roster size (10 or fewer, 11–25, 26–40).
Outside a raid it returns to the 40-player layout. Edit Raid Layout selects
which size to configure without forcing the live layout. Each size stores its
own dimensions, appearance, auras/filter lists and Unlock position. Global
Fonts, Textures and Aura Filters have the same layout selector. Existing 0.1
raid settings/position are copied independently into all three layouts.

VISIBLE GROUPS: Show Group 1–2, 1–5 or 1–8 hides individual subgroups for the
edited size. Visible groups pack together without gaps, retaining their native
group numbers and membership. Group Limit caps the last group shown; enabling
a group raises that limit if necessary. Hiding every group hides the raid
holder. Both size changes and group visibility defer during combat. Preview
while outside a raid shows the edited layout, including its hidden groups.

Native SecureGroupHeaderTemplate headers own roster membership, subgroup
sorting, unit assignment and visibility. All 45 secure buttons are allocated
before combat. Layout and binding changes requested in combat apply after
combat ends; native roster changes can still update existing secure buttons.
Vehicle health/power and clicks follow the secure effective unit. Normal
left-click targets and right-click opens the native unit menu.

Buff/debuff icons read each member's native UnitAura list, independently of
the selected target. Timers, stacks, own-caster rules, dispellable debuffs and
dispel borders are supported. Raid and party have separate tracked/excluded
spell-ID filters. Icons allow clicks through to the secure unit button; their
tooltips use cursor position without covering healer click targets.

Built-in click casting starts disabled. Enable it to assign a learned spell
ID, target, menu, focus or assist to mouse buttons 1–5 and modifier keys.
Invalid spell IDs preserve the previous binding. When disabled, registered
ClickCastFrames remain available to Clique; the module clears only attributes
it previously wrote and still owns.

Native party frames are hidden by reparenting outside combat, preserving
their original parent, points, scripts and events. Disabling the replacement
restores them. Other addons' group frames and manually opened native raid
pullouts are not replaced. Disable competing group-frame modules separately
if you want only one set of raid frames.

Retail private auras, modern heal/absorb prediction, advanced buff-manager
containers, portrait layouts and shared battle-res resources are not exposed.
Wrath-compatible role icons and 15 health textures have separate uncompressed
TGA copies, so this module can be installed independently of UnitFrames.

validate_raidframes.py exercises the real runtime in Lua 5.1 with an explicit
Wrath API/secure-header contract fixture: roster changes, aura ownership,
vehicles, combat deferral, bindings, range/status, preview, native restoration,
profiles, movers and the actual options/global-font/global-texture builders.
It also checks XML, TGA headers and Retail byte integrity. Native rendering
and protected behavior still require verification inside the game client.
