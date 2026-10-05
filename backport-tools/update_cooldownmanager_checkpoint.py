"""One-time build 0.35: native CDM and combined EUI memory footer."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
changes=[('EllesmereUI','3.3.5-core-0.27','3.3.5-core-0.28'),('EllesmereUIOptions','9.3.4-335-0.39','9.3.4-335-0.40')]
for folder,old,new in changes:
    p=root/folder/(folder+'.toc'); s=p.read_text(encoding='utf-8-sig'); assert '## Version: '+old in s
    p.write_text(s.replace('## Version: '+old,'## Version: '+new),encoding='utf-8')
p=root/'backport-tools/package_unitframes.py'; s=p.read_text(encoding='utf-8-sig')
for folder,old,new in changes:
    a=f"'{folder}':'{old}'"; assert a in s; s=s.replace(a,f"'{folder}':'{new}'")
for a,b in [('core-0.27.zip','core-0.28.zip'),('Options-3.3.5-0.39.zip','Options-3.3.5-0.40.zip'),('HUD-test-0.34.zip','HUD-test-0.35.zip')]:
    assert a in s; s=s.replace(a,b)
s=s.replace("'EllesmereUIDamageMeters':'9.3.4-335-0.3'}","'EllesmereUIDamageMeters':'9.3.4-335-0.3','EllesmereUICooldownManager':'9.3.4-335-0.1'}")
assert "'EllesmereUICooldownManager':'9.3.4-335-0.1'" in s
s=s.replace("    'EllesmereUI-3.3.5-HUD-test-0.35.zip':", "    'EllesmereUICooldownManager-3.3.5-0.1.zip':['EllesmereUICooldownManager'],\n    'EllesmereUI-3.3.5-HUD-test-0.35.zip':")
p.write_text(s,encoding='utf-8')
note='''Latest build: HUD-test-0.35. Core 0.28 / Options 0.40 / Cooldown Manager 0.1.
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

'''
for name in ['CODEX_HANDOFF_EllesmereUI_335_CURRENT.md','ELLESMEREUI_335_BACKPORT_STATUS.md']:
    p=root/name; s=p.read_text(encoding='utf-8-sig'); i=s.index('\n\n')+2; p.write_text(s[:i]+note+s[i:],encoding='utf-8')
for folder,title,entry in [('EllesmereUI','# EllesmereUI Wrath Core — 0.28','0.28 replaces the Options sidebar CPU readout with combined loaded EUI addon\nmemory, including Options. Native KB accounting is shown as MB every 5 seconds\nwhile the panel is visible.\n\n'),('EllesmereUIOptions','# Options 3.3.5 — 0.40','0.40 adds native Cooldown Manager pages: CDM Bars, Tracking Bars and Bar Glows,\nmanual assignments, aura filters, dual-spec lists, outlines and previews.\n\n')]:
    p=root/folder/'README-335.md'; s=p.read_text(encoding='utf-8-sig'); i=s.index('\n\n')+2; p.write_text(title+'\n\n'+entry+s[i:],encoding='utf-8')
(root/'EllesmereUICooldownManager/README-335.md').write_text('''# EllesmereUI Cooldown Manager — Wrath 3.3.5a — 0.1

Only the three EUI_CooldownManager_335 files in the TOC execute. Original Retail
Lua files are preserved, unloaded and unchanged. Requires EllesmereUI only;
optional button highlights use EllesmereUIActionBars when loaded.

Open Cooldown Manager settings or /ecdm. CDM Bars edits Cooldowns, Utility and
Buffs; Tracking Bars displays durations as horizontal bars. Manual assignments
accept native spell IDs, item IDs or equipment slots 1–19. Aura entries support
player/target/focus, buffs/debuffs and own-caster filtering. Each dual talent
group has its own assignments. Learned spell cooldowns resolve the highest
rank in the actual player/pet spellbook. Empty slots, invalid IDs and unlearned
cooldowns stay hidden. Item information can appear after the client caches it.

Configure growth, size, spacing, opacity, text outlines, remaining duration,
stacks, keybinds, range, visibility, entry order and GCD display. Move the four
groups in Unlock Mode. Preview reveals inactive/empty groups for positioning.
Icons monitor cooldowns; clicking opens settings. /ecdm show or hide toggles
the module. Restore Default Assignments affects only the selected group.

Bar Glows controls aura-active, ready or cooling icons. An aura's Highlight
Spell ID optionally lights the matching EUI action button. These overlays are
preallocated outside combat. There is an optional cooldown-ready sound.
Retail rotation assistants and Retail cooldown-viewer APIs are not used.
No external addon runtime, libraries or saved inventory data are consulted.

validate_cooldownmanager.py exercises actual Core lifecycle, native spellbook
ranks/pet/passives, aura ownership/expiry, GCD/cooldown/timers/items/stacks,
dual-spec assignments, preview/unlock, manual settings, glow/keybind behavior
and absence of combat frame allocation. Native rendering needs in-game review.
''',encoding='utf-8')
p=root/'ELLESMEREUI_PROJECT_PACK.md'; s=p.read_text(encoding='utf-8-sig')
s=s.replace('build 0.34','build 0.35').replace('HUD-test-0.34.zip','HUD-test-0.35.zip').replace('fourteen','fifteen').replace('15 current','16 current')
start,end=s.index('Saved checkpoint:'),s.index('This project pack contains')
s=s[:start]+'''Saved checkpoint: 1 October 2026. Build 0.35 adds independent native Wrath
Cooldown Manager with settings, manual assignments, aura filters, tracking
bars, glows and Unlock Mode. The sidebar now shows combined EUI addon memory
including Options. Automated regressions pass; native appearance needs review.

'''+s[end:]
p.write_text(s,encoding='utf-8')
print('PASS: build 0.35 versions, package selection and documentation updated.')
