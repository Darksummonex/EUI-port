# EllesmereUI AuraBuff Reminders — Wrath 3.3.5a — 0.1

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
