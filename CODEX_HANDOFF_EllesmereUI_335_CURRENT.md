# EllesmereUI 3.3.5a — Handoff — 2026-10-06

## Project layout (changed 2026-10-06)

The project lives in `C:\Users\Gaming\Desktop\EUI backport`, which is the git
repo (remote `https://github.com/Darksummonex/EUI-port.git`). Open this folder as
the workspace. It holds the 20 real `EllesmereUI*` addon folders,
`backport-tools/` (validators, mocks, extractors, packers), `.codex-tools/` (lupa
and mpyq for Python), `.codex-backups/`, these docs and the EUI ZIPs. The project
is strictly EllesmereUI: other addons are not part of it or its backups.

Alex plays on the `D:\Jogo\WLk` client: a customised 3.3.5 (build 12340)
client that ships Retail UI ports, including an addon-level `C_Texture` whose
`GetAtlasInfo` errors on unknown atlases (Core wraps it, see Core 0.49). Its
errors are in `D:\Jogo\WLk\WTF\Account\DARKSUMMON\SavedVariables\!BugGrabber.lua`
and `D:\Jogo\WLk\Logs\FrameXML.log`. `D:\Jogo\Whitemane\Games\FrostmourneRebuffed`
is the second install; `game_paths.py` points at it for the reference addons and
client MPQs. In both installs `Interface\AddOns` keeps the game's own addons plus
one directory junction per `EllesmereUI*` folder pointing back here, so each
client loads the project files directly. WLk's previous copies were moved to
`D:\Jogo\WLk\Interface\EUI-copies-20261006`. Edit files here and `/reload` in game. Do not replace the junctions
with copies. A new EUI module folder is created here and linked with
`New-Item -ItemType Junction -Path "<AddOns>\<Name>" -Target "<project>\<Name>"`.

**Do not use the game client folders** (Alex, 2026-10-06): no reading, copying,
syncing or inspecting `D:\Jogo\...` installs, their WTF/BugGrabber, logs or MPQs.
Ask Alex to paste in-game errors instead. `backport-tools/game_paths.py` is `None`
unless `EUI_GAME_DIR` is set explicitly; without it the checks against other
addons (ElvUI, DBM, AbilityTimeline, ACP) skip. Retail sources stay at
`D:/World of Warcraft/_retail_` (read only, never modify).

Blizzard files extracted from the client (`backport-tools/framexml-worldmap/`,
`framexml-skins/`, `_glyph_art/`) are listed in `.git/info/exclude`. Never commit
them. The project ZIP contains them, so keep it private.

## Workflow and rules

- Per module: compare Retail against Wrath, port, validate, bump the TOC
  version (no BOM), add a Portuguese entry to the module `README-335.md`, update
  the in-game patch notes in `EllesmereUIOptions/EUI__General_Options.lua` (one
  header per module, `version = "<Module> X.Y"` matching the TOC, with
  `heroes`/`features`/`fixes`), then report what was not ported.
- Every module needs Unlock Mode movers plus Element Options (Zone Text excepted).
- Never restart WoW; ask for `/reload`.
- Do not edit the byte-identical Retail copies kept in module folders (for example
  `EllesmereUIActionBars/EllesmereUIActionBars.lua`,
  `EllesmereUIOptions/EUI_ActionBars_Options.lua`); validators compare them.
- Keep Options EditBox autofocus and focus cleanup; no fake keyboard propagation.
  Avoid `SetRotatesTexture`.
- Compat shims only fill methods the client lacks. Never replace an existing method
  on a shared widget metatable: Blizzard frames share it and get tainted (Options
  0.87 did this and Esc showed "EllesmereUIOptions has been blocked"). Per-instance
  patches on EUI-owned objects (Unit Frames `PatchRegion`) are fine.
- Do not rerun `update_*_checkpoint.py`, `scope_options_factory.py`,
  `connect_indicator_editor.py` or `prepare_raidframe_textures.py`.
  `package_project.py` is the old 0.38 checkpoint packer and still expects the
  0.38 archives.
- Keep old backups, `.codex-backups` and checkpoint scripts.
- Commits: `cursor/` branch, stage only related files, concise message, push only
  when asked. Keep the exact addon folder names at the top level of ZIPs.

Python: `C:/Users/Gaming/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`.
Git: `C:\Program Files\Git\cmd\git.exe`. Full validator loop (55 validators, all
pass), run from the project folder:

```
$py='C:/Users/Gaming/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'; $all=Get-ChildItem backport-tools\validate_*.py; $fail=@(); $all | ForEach-Object { $out = & $py $_.FullName 2>&1 | Out-String; if ($LASTEXITCODE -ne 0) { $fail += $_.Name; $_.Name; ($out.Trim() -split "`n" | Select-Object -Last 6) } }; "Ran $($all.Count). Failures: $($fail.Count) -> $($fail -join ', ')"
```

Working-tree backups: `backport-tools/backup_project.py` writes
`EllesmereUI-3.3.5-HUD-backup-<stamp>.zip` (installable addon folders) and
`EllesmereUI-3.3.5-project-backup-<stamp>.zip` (plus tools and docs), each with a
`.sha256`, and records versions in `.codex-backups/`. Latest: `20261006-1240`.

## Current versions

Core 0.53; Action Bars 0.18; Arena 0.2; AuraBuff Reminders 0.3; Bags 0.10;
Blizz UI Enhanced (BlizzardSkin) 0.26; Chat 0.42; Cooldown Manager 0.2;
Damage Meters 0.6; Data Bars 0.4; Friends 0.3; Minimap 0.4; Nameplates 0.13;
Options 0.90; QoL 0.10; Quest Tracker 0.3; Quickdraw 0.3; Raid Frames 0.12;
Resource Bars 0.3; Unit Frames 0.16.

Git: branch `cursor/eui-shapes-bars-skins-qol`, built on
`cursor/eui-arena-and-fixes`. Neither is merged into `main`; no PR is open.

## Latest work (2026-10-05 / 06)

- Classic WoW UI green health (Unit Frames 0.14, Options 0.89):
  `ns.UF_SeedStock` sets `healthClassColored=false` and
  `customFillColor` = `ns.UF_CLASSIC_HEALTH_COLOR` (0,1,0) on every
  `ns.UF_TEXTURE_UNITS` frame once per profile (stamp `classicHealthSeeded`).
  The keys are in `ns.UF_StyleSlotKeys()` and `SLOT_KEYS.unitframes`; a
  profile already Classic banks its current colours into `_styleSlots.eui`
  first. Validator: `validate_classic_health.py`.
- Classic WoW UI power colours (Unit Frames 0.15, Options 0.90): every Unit
  Frames power colour read goes through `ns.UF_PowerColor(unit)` /
  `ns.UF_PowerInfo(token)`, which return the client's `PowerBarColor` under
  Classic only and EllesmereUI's palette otherwise. No settings change.

- Per-text outline (Core 0.50, Nameplates 0.13, Unit Frames 0.11, QoL 0.10,
  Options 0.86): `EllesmereUI.ApplyTextOutline(fs, path, size, mode, moduleKey)`
  in `EllesmereUI_Fonts.lua` maps module/none/outline/thick/shadow; "module"
  returns false so the caller keeps its own default. Keys: nameplates
  `<element>Outline` (cog dropdowns), Unit Frames `<slot>Outline` for
  left/right/center/extraText, btbLeft/Right/Center and powerPercent (38
  `SetFSFont` call sites, options cogs and preview), QoL `zoneTextOutline`
  (Blizzard zone strings, restored from their font object). Test:
  `validate_text_outline.py`. One-off patchers: `add_uf_text_outline.py`,
  `add_uf_preview_outline.py` (both idempotent).

- Action Bars 0.17: Custom Button Shape per bar (none, square, curved square,
  circle, portrait, diamond, hexagon, shield). Wrath has no mask textures: circle
  and portrait use `SetPortraitToTexture`; diamond, hexagon and shield crop the
  icon into horizontal strips cut from the mask rows (`SHAPE_ROWS`), with the icon
  as the first strip and the rest mirrored by hooks; square and curved square are
  outline only. The cooldown swipe is always square, so it shrinks to the
  inscribed square or the shape's `SHAPE_SWIPE` rectangle.
- Action Bars 0.18: Bars 7-10 on action pages 7-10 (slots 73-120), off by default,
  with bindings (`Bindings.xml`, 60 entries for bars 6-10), Unlock Mode and full
  Bar Display settings. Pages 7-10 are also stance/form pages for Warrior, Druid,
  Rogue (7) and Priest (7); `ns.PageShare` drives a warning in Bar Display unless
  Bar 1 has Disable Form Paging on.
- Core 0.48: the Incompatible Addon popup offers "Disable <addon>" and, where it
  applies, "Disable EUI <module>", then reloads (`ShowConfirmPopup` `extraButtons`).
- Blizz UI Enhanced 0.26: native dropdown panels inset to the visible box (ending
  at the arrow button); Raid Information uses its own inset instead of the Friends
  window's classic one.
- Earlier in this period: Arena module (pets, DR tracking, out-of-range fade),
  raid debuff highlight in Raid Frames, battleground capture bar and GM chat
  status skins, loot roll choices, QoL interrupt announce, auto-accept invites
  from guild and friends, disband raid.

## Waiting for in-game confirmation

Strip-cropped Diamond/Hexagon/Shield icons (possible seams at UI scales other
than 1), the conflict popup's disable buttons, Bars 7-10 and their keybinds (if
they are missing from Key Bindings after `/reload`, `Bindings.xml` may need a
client restart), the dropdown and Raid Information backgrounds, the per-text
outline dropdowns (Shadow rendering, Zone Text restore to Blizzard Default).

## Not ported (Wrath limits)

Masked button shapes: square and curved square stay outline only, and the swipe
stays square. Extra action bars cannot get their own slots on stance/form pages.

---

# Previous log — checkpoint 2026-10-01

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

Workspace: D:/Jogo/Whitemane/Games/FrostmourneRebuffed/Interface/AddOns.

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


User confirmed “Great so far so good” after the duplicate Buffs Edit Mode
overlay fix, then requested deleting old build files and saving the current build.
That combination was confirmed; Core 0.16 adds the requested Esc/Options access
and awaits in-game confirmation. UnitFrames 0.6 fixes the reported Blizzard
level font initialization error and also awaits in-game confirmation.
This is not a claim of complete coverage.
Core 0.17 fixes the two reported Unlock tutorial/tooltip issues; visual
confirmation pending. User explicitly resumed Presets; implemented in Options 0.21.
Latest: BlizzardSkin 0.3 fixes overlapping Character tabs and implements the
requested expanded reference-style Wrath paper doll. In-game visuals pending.
Latest: Core 0.19 / Options 0.21 restore the Presets style picker, repair all
Options theme textures and add the user's Lich King theme with icy-blue accents.
Native spell-ID tooltips now work through the existing Developer option.
Core 0.20 fixes both search fields being impossible to type into. User clarified
"Cannot type"; ReleaseWrathPanelKeyboard disabled every descendant's keyboard,
including native EditBoxes, on panel show/hide. Now EditBoxes clear focus and
keep keyboard enabled; ordinary keybind capture frames stay disabled until armed.
validate_search.py reproduced failure before fix, passes after: cleanup/reopen,
real typing/debounce/Escape/Enter handlers, current-page filtering/restoration,
feature popup/unvisited-page indexing/result navigation and hook idempotence.

| Addon | Version |
| --- | --- |
| EllesmereUI | 3.3.5-core-0.25 |
| EllesmereUIOptions | 9.3.4-335-0.35 |
| EllesmereUIUnitFrames | 9.3.4-335-0.8 |
| EllesmereUIMinimap | 9.3.4-335-0.3 |
| EllesmereUIActionBars | 9.3.4-335-0.12 |
| EllesmereUIChat | 9.3.4-335-0.3 |
| EllesmereUINameplates | 9.3.4-335-0.6 |
| EllesmereUIBlizzardSkin | 9.3.4-335-0.6 |
| EllesmereUIBags | 9.3.4-335-0.7 |
| EllesmereUIResourceBars | 9.3.4-335-0.2 |
| EllesmereUIQoL | 9.3.4-335-0.2 |
| EllesmereUIRaidFrames | 9.3.4-335-0.4 |
| EllesmereUIDataBars | 9.3.4-335-0.2 |

Full build: EllesmereUI-3.3.5-HUD-test-0.30.zip. Keep it together with the thirteen
current individual ZIPs. ELLESMEREUI_335_CURRENT_BUILD.json records exact
archive sizes and SHA-256 hashes. Older EllesmereUI ZIPs were removed by the
user's explicit request; historical “preserve old ZIP” notes are superseded.
Installed source, backport-tools and .codex-tools are preserved. Unrelated addon
files are outside this checkpoint's cleanup scope. After building Core 0.16,
automatic approval review blocked Remove-Item for the superseded Core 0.15 and
HUD-test-0.7 ZIPs (reason: “blocked by policy”); these two archives remain.
Superseded UnitFrames 0.5 and HUD-test-0.8 archives are also retained; no removal
workaround was attempted after that policy block. Use the manifest for current ZIPs.
Core 0.16/HUD-test-0.9 also remain after the next build; no deletion retry.
Core 0.17/Options 0.19/BlizzardSkin 0.2/HUD-test-0.10 remain after this build;
no deletion workaround. Current archives are exactly those in the manifest.
Core 0.18/Options 0.20/HUD-test-0.11 also remain after this build; no retry.
Core 0.19/HUD-test-0.12 remain after the search fix; no deletion retry.
Core 0.20/Options 0.21/HUD-test-0.13 remain after this build; no deletion retry.

Latest: user added Bags, then ResourceBars during Bags implementation. Both
are included; in-game confirmation pending. Retail sources are read-only and
copied originals are byte-identical except replacement TOCs. Only the new
EUI_Bags_335.lua and EUI_ResourceBars_335.lua adapters load.

Bags 0.1: unified player bags/keyring/bank; scrollable grid, live search dimming,
category/name view sorting (no physical moves), quality/count/ilvl/lock/cooldown
display. Native template item actions retain parent bag ID and button slot ID.
Bank reads require a server bank session; native BankFrame is temporarily
moved/alpha-hidden rather than Hide(), which would close the session. Native
Bank button restores purchases/bank bag management. Drag positions and visible
window Edit Mode movers supported. /ebags toggles inventory; EUI > Bags settings.

ResourceBars 0.1: health/power, Rogue/Cat combo points, six DK runes, Shaman
totems, optional player cast/channel and native 61304 GCD. Health/cast default
off; unsupported resources stay hidden. Native cast alpha is suppressed/restored;
UnitFrames' cast remains separately configured. Automatic Edit Mode previews,
independent movers, /erb, one Bars page with bar selector, global Fonts/Textures
live writes and 15 TGA fills. Retail styles/advanced helpers stay unloaded.
Core 0.21 adds Bags profile refresh; Options 0.22 adds native module pages and
guards unsupported Retail styles/labels and fixes the texture page deep link.

validate_inventory_resources.py executes real Core Lite/safecall in Lua 5.1.
Checks: native slot actions, search, pools, scrolling, cache retry, bank session/
restore/fallback, combat, positions, Warrior/Rogue/Cat/DK/Shaman resources,
casts/channels/delay/stale-stop/GCD expiry/native cast restore, all selector
pages, and real Global Fonts/Textures tile setters. 158 Lua files compile;
UnitFrames, Presets/themes and search regressions pass. Native taint and
in-game visuals/interactions still require testing.

Recent changes: ElvUI Norm XP/reputation skin (blue XP, purple rested, dark
empty background); reversible Blizzard bar art toggle; one /eab panel selecting
14 action/HUD/aura groups with independent layout/position controls. Corrected
Texture vs Frame snapshot APIs, font-before-text ordering, and Core method self
arguments. Chat 0.3 removes the native 50px bottom clamp margin to allow Y=0.
Core 0.15 removes read-only Buffs/Debuffs Edit Mode overlays when the real Player
Buffs/Player Debuffs mover owns that group, with native fallback when disabled.
Core 0.16 adds a native Esc menu EllesmereUI button and Interface/AddOns category
with Open EllesmereUI; click-only LOD load, combat guard and coexistence with
other addons' menu anchors. EUI_OptionsAccess_335.lua is loaded from the Core TOC.
UnitFrames 0.6 guards the optional GameNormalNumberFont and sets the selected
module font (native fallback if rejected) before Blizzard level SetText during
first layout. Later passes preserve name font inheritance and custom level size.
Core 0.17 shows Unlock sidebar guidance only on hover, anchored to the right,
with immediate leave/hide/click dismissal; automatic first-open tutorial skips
Wrath. Edit Mode's Okay label gets explicit font/bounds/alpha and button layering;
click stops fade, hides the tutorial and saves unlockTipSeen.
BlizzardSkin 0.3 adds EUI_CharacterSheet_335.lua after the skin adapter TOC entry.
Expanded 660x580 sheet, larger native model, square native slots around it,
per-item ilvl and equipped average (17 combat slots; two-hand fills empty offhand).
Native UpdatePaperdollStats/PaperDollStatTooltip drive named stat rows in a
collapsible/scrollable sidebar. Native Titles/Equipment actions retained.
Character tabs get measured widths/gaps/pet visibility/wrapped footer rows.
Timed bounded visible cache retry replaces nonexistent GET_ITEM_INFO_RECEIVED.
Toggle off restores geometry, alpha, visibility, UIPanel width and title parent;
skin off also restores tabs; combat changes defer and frames are reused.
Options 0.20 adds /ebs > Blizzard Window Skins > CHARACTER ENHANCEMENT toggles.
Core 0.18 only adds these two account keys to the optional skin export/import bundle.

Resumed Presets: the user explicitly requested resumption. The proposal in
backport-tools/paused-presets-navigation.patch is now applied (do not reapply).
Profiles > Presets / UI Style Presets open the existing in-game style builder;
Wrath no longer intercepts SelectPage with the absent Retail VideoGuides popup.
Hidden indexing and page-cache restore use the same style builder/cleanup.
Real card clicks tested for eui/blizzard/classic: profiles stay unchanged until
reload confirmation. Supported Wrath surfaces are UnitFrames/player auras and
Minimap; unsupported Retail style rows remain excluded/disabled as before.

Themes: all original PNGs remain untouched. prepare_theme_textures.py generates
uncompressed RGBA 1024x1024 TGA copies in media/backgrounds_335, rescaling the
whole canvas so normalized texture cuts stay aligned. Includes base/shadow,
Pixels accent overlay, and the user's eui-bg-lichking.png. Collapse/expand icon
gets a 32x32 TGA copy in media/icons_335. Wrath-only theme map rewrites occur
before preload and exports; native close-box specs copied to native paths.
Lich King is a native-color background with accent #5CC3EB. Global Settings >
General > DISPLAY has Match Accent to Theme (Wrath default on): resolver uses
selected palette for menu highlights/borders/tabs without rewriting saved
profile colors. Off restores profile custom/class accent; selecting a swatch
turns matching off. Login fallback/live resolution agree; reset clears override.
validate_themes_presets.py executes dropdown/matching, preload/crossfade,
tint, actual Presets registration/navigation/cards/switches/cache/prebuild.

Spell IDs: EUI_TooltipIDs_335.lua is TOC-loaded with the Core. Reuses saved
showSpellID / spellIDModifier and Global Settings > General > DEVELOPER >
Show Spell ID on Tooltip (kept reachable on Wrath). Native OnTooltipSetSpell,
SetSpellByID/SetAction/SetHyperlink/SetUnitBuff/SetUnitDebuff/SetUnitAura hooks
add one Spell ID line to GameTooltip/ItemRefTooltip. Wrath aura return 11,
macro resolved spell link, tooltip-clear reset, other-addon dedup and modifiers.
No Retail TooltipDataProcessor or unsupported aura-ID CVar is used on Wrath.
validate_tooltip_ids.py exercises real native hooks/IDs/toggles/modifiers/dedup.
Themes, Presets and spell IDs still await in-game visual confirmation.

Read ELLESMEREUI_335_BACKPORT_STATUS.md and each module README-335.md for history
and limits. Retail files at D:/World of Warcraft/_retail_/Interface/AddOns were
read/copied only; preserve them. The original Downloads handoff remains unchanged.
Keep exact addon folder names inside ZIPs; versions belong in TOCs and ZIP names.
Preserve Options EditBox autofocus/focus cleanup; no fake keyboard propagation.
Avoid SetRotatesTexture on this Wrath client (prior native crash).

Python runtime:
C:/Users/Gaming/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe.
Lua 5.1 tests use Lupa in .codex-tools. validate_unitframes.py compiles all 140
Lua files and now tests unfonted Blizzard level creation for player/target/focus,
custom sizes, name inheritance, missing file fallback, level events, skull and
visibility; validate_actionbars.py uses real Core methods/overlay logic and LAB
secure snippets; validate_chat.py covers native chat contracts and Y=0. Other
focused validators are in backport-tools; validate_options_access.py verifies
the new menu/category/lazy-load/layout contracts. package_unitframes.py builds and checks
the current nine archives. Local tests do not reproduce native taint/rendering.
validate_character_sheet.py covers new character geometry/tabs/actions/native
stat row names, cache bounds, two-hand averages, scroll/collapse, combat and exact
restoration/reuse; executes real Core skin-key snapshot/import functions too.
validate_blizzardskin.py loads the new module and tests both new option controls.

Persistent user preference: after each completed code correction, close only
Wow processes whose executable path is
D:/Jogo/Whitemane/Games/FrostmourneRebuffed/Wow.exe, then start that executable
with FrostmourneRebuffed as working directory. Do not restart for archive cleanup.
