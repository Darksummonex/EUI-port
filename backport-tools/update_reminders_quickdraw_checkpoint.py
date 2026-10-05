"""One-time 0.36 checkpoint: Wrath AuraBuff Reminders and Quickdraw."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=root/'EllesmereUIOptions/EllesmereUIOptions.toc'; s=p.read_text(encoding='utf-8-sig')
assert '## Version: 9.3.4-335-0.40' in s
p.write_text(s.replace('## Version: 9.3.4-335-0.40','## Version: 9.3.4-335-0.41'),encoding='utf-8')
p=root/'backport-tools/package_unitframes.py'; s=p.read_text(encoding='utf-8-sig')
for old,new in [("'EllesmereUIOptions':'9.3.4-335-0.40'","'EllesmereUIOptions':'9.3.4-335-0.41'"),('Options-3.3.5-0.40.zip','Options-3.3.5-0.41.zip'),('HUD-test-0.35.zip','HUD-test-0.36.zip')]:
    assert old in s; s=s.replace(old,new)
old="'EllesmereUICooldownManager':'9.3.4-335-0.1'}"
assert old in s
s=s.replace(old,"'EllesmereUICooldownManager':'9.3.4-335-0.1','EllesmereUIAuraBuffReminders':'9.3.4-335-0.1','EllesmereUIQuickdraw':'9.3.4-335-0.1'}")
s=s.replace("    'EllesmereUI-3.3.5-HUD-test-0.36.zip':", "    'EllesmereUIAuraBuffReminders-3.3.5-0.1.zip':['EllesmereUIAuraBuffReminders'],\n    'EllesmereUIQuickdraw-3.3.5-0.1.zip':['EllesmereUIQuickdraw'],\n    'EllesmereUI-3.3.5-HUD-test-0.36.zip':")
p.write_text(s,encoding='utf-8')
note='''Latest build: HUD-test-0.36. Options 0.41 / AuraBuff Reminders 0.1 /
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

'''
for filename in ['CODEX_HANDOFF_EllesmereUI_335_CURRENT.md','ELLESMEREUI_335_BACKPORT_STATUS.md']:
    p=root/filename; s=p.read_text(encoding='utf-8-sig'); i=s.index('\n\n')+2; p.write_text(s[:i]+note+s[i:],encoding='utf-8')
p=root/'EllesmereUIOptions/README-335.md'; s=p.read_text(encoding='utf-8-sig'); i=s.index('\n\n')+2
p.write_text('# Options 3.3.5 — 0.41\n\n0.41 adds native AuraBuff Reminders and Quickdraw settings, assignments,\nreminder preview/filters and palette layout/action/keybind controls.\n\n'+s[i:],encoding='utf-8')
(root/'EllesmereUIAuraBuffReminders/README-335.md').write_text('''# EllesmereUI AuraBuff Reminders — Wrath 3.3.5a — 0.1

Only the three EUI_AuraBuffReminders_335 files execute. The original Retail
main/talent Lua and five sound files are retained unchanged as references.
Requires EllesmereUI; no external libraries or addon data are used.

Open /eabr or /ebr. The main settings page edits learned class raid buffs,
personal armor/auras/shields/pets, food/flasks and weapon enchant reminders.
Raid checks skip dead, disconnected, invisible and out-of-range members.
Single/group buff names and spell ranks match natively. Configure player-only
or party/raid checks, giving/requesting buffs, visibility, expiry threshold
in seconds, text/counts, opacity, accent border, sounds and preferred items.
The threshold is ignored during combat; only fully missing buffs remind there.
Unavailable consumables can show a desaturated restock prompt. Shields and
offhand frills never trigger weapon enchant warnings. Generic poisons/oils
are reminder-only; Shaman imbues can expose a learned spell action.

Custom Reminders accepts manual native aura IDs, player/target/focus, buffs or
debuffs, own caster and expiry/visibility rules. Talent Reminders accepts an
expected learned spell ID and optional exact localized zone name. It prompts
when that spell is not learned; it does not alter talents or choose builds.

Use Preview and Unlock Mode to position the display. The icons wrap downward
within the screen width. Left-click casts/uses an available action outside
combat. Secure click layers are separate UIParent children hidden by native
combat state drivers; the regular display continues updating in combat.
Middle/right click dismisses a prompt until the next loading screen; settings
can restore dismissed prompts. Sound alerts fire once per newly visible prompt,
with no startup burst. No chat or addon messages are sent.

validate_aurabuffreminders.py tests actual Core lifecycle, rank/group buffs,
ownership/expiry, reachable units, food/flasks and stacks, weapon-vs-shield,
custom/zone/talent settings, sounds, dismissals, preview, unlock, secure OOC
actions and combat updates without protected mutations or UI allocation.
Native appearance/secure actions need client review.
''',encoding='utf-8')
(root/'EllesmereUIQuickdraw/README-335.md').write_text('''# EllesmereUI Quickdraw — Wrath 3.3.5a — 0.1

Only the three EUI_Quickdraw_335 files execute. Original Retail Lua remains
unchanged and unloaded; original XML is stored in Bindings_Retail.xml. The
native Bindings.xml auto-registers 16 EUI_RADIAL actions and is not in the TOC.
Requires EllesmereUI only, without outside libraries/data.

Open /eqd. Configure up to 16 numbered palettes with 20 entries each. Assign
a holdable key in settings or the game's keybindings menu. Hold to open,
point or scroll to choose, release to fire. The center/deadzone, empty space
or no pointer movement cancels. Escape cancels without leaving a keyboard
handler or temporary Escape binding behind. Numbered palettes retain their
binding identities when cleared/disabled.

Ring/arc (30–360 degree span and rotation), horizontal fan and grid layouts
support cursor/screen placement, offsets, radius, size/spacing/scale, opacity,
outlined labels, item stack counts and cooldown swipes. Palettes clamp to the
screen; no-motion cancellation prevents unintended release at a clamped edge.
The fan displays its entries in a horizontal strip; wheel selection cycles
all actions. Retail nesting/coverflow/world-marker features are not loaded.

Add native spell or item IDs, macro name/index or text, raid marker 0–8,
equipment set name, companion index or whitelisted micro-menu panels. The
cursor button accepts dragged spells, items, macros and companions. Spell
targets support automatic/player/target/focus/mouseover. Actions can be
reordered or removed. Micro-menu panels execute /click on native micro buttons.

SecureActionButton hold/release/click execution is wrapped in native secure
handlers. Selection/wheel/cancel run in Wrath's restricted environment;
no anonymous functions or direct tables appear in snippets. Configuration,
binding and frame changes defer until combat ends; cache changes while a
palette is held defer until it closes. Rendering retains a snapshot matching
the secure attributes. Direct slot clicks also close/cancel the held palette
to prevent a second cast when the key is released. No chat is sent unless a
user deliberately assigns a macro that sends chat.

validate_quickdraw.py executes real restricted snippets with native owner
frame references, no-function/no-table checks and combat mutation guards.
Tests cover lifecycle, layouts/arc bounds, deadzone/no-motion, wheel, release
and direct actions, repeated Escape cleanup, modifier routing, deferred edits,
keybindings, cursor pickup, supported action types and source integrity.
Native visual rendering and secure behavior need in-game verification.

Wrath client reference: https://github.com/wowgaming/3.3.5-interface-files
(SecureHandlers.lua, RestrictedFrames.lua, RestrictedExecution.lua and
SecureTemplates.lua). These are references only; no downloaded runtime is used.
''',encoding='utf-8')
p=root/'ELLESMEREUI_PROJECT_PACK.md'; s=p.read_text(encoding='utf-8-sig')
s=s.replace('build 0.35','build 0.36').replace('HUD-test-0.35.zip','HUD-test-0.36.zip').replace('fifteen','seventeen').replace('sixteen current','eighteen current')
start,end=s.index('Saved checkpoint:'),s.index('This project pack contains')
s=s[:start]+'''Saved checkpoint: 1 October 2026. Build 0.36 adds independent Wrath AuraBuff
Reminders and Quickdraw with settings, custom reminders, zone/talent checks,
secure palette actions, layouts and bindings. Automated Lua 5.1 and restricted
snippet checks pass. Native appearance and execution need in-game review.

'''+s[end:]
p.write_text(s,encoding='utf-8')
print('PASS: build 0.36 versions, 17 addon folders/18 archives and documentation updated.')
