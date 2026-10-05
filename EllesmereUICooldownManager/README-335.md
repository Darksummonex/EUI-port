# EllesmereUI Cooldown Manager — Wrath 3.3.5a — 0.1

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
