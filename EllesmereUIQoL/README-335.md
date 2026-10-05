# Quality of Life 3.3.5 — 0.2

0.2 adds Raid Tools > Pull Timer Length (3-60 seconds, default 10), Send to
DBM / BigWigs and Chat Countdown. The Pull button displays the selected
duration. Countdown is owned by EUI; no external addon is required locally.
Chat announces the chosen duration, 10 seconds, 5/4/3/2/1 and Pull!, using
Raid Warning when permitted, otherwise Raid then Party. Solo stays local.
Updates deduplicate announcements and omit missed numbers after a stall.
Cancel, early combat, module/tools disable and profile/group changes stop
the local countdown; permitted cancellation is sent to the original group.
Boss-mod packets require raid leader/assistant or party leader. Recipient
addons retain their own permissions, filters, enable state and throttles.
Native Wrath DBM receives DBMv4-PT; D4 PT supports newer compatible Pull
plugins. Original Wrath BigWigs receives a BWCustomBar Pull timer and finish
alert (not its later voice countdown UI). Broadcast and chat are independent.
Protocol references reviewed:
https://github.com/bkader/BigWigs-WoTLK/blob/main/BigWigs/Plugins/Bars.lua
https://github.com/bkader/BigWigs-WoTLK/blob/main/BigWigs/Core/Core.lua
https://github.com/BigWigsMods/BigWigs/blob/v10/Plugins/Pull.lua
https://github.com/BigWigsMods/BigWigs/blob/v10/Loader.lua
Tests simulate scheduling/channels/packets and optionally run the actual
locally installed DBM PT receiver. Remote client rendering/audio still
needs in-game confirmation.

Native Wrath module, opened through Quality of Life in EUI or /eqol (/qol).
Use with Core 0.23 and Options 0.24. The three EUI_QoL_335 runtime files load;
the copied Retail Lua/media files remain unchanged, unloaded references.
Settings live in the Core's EllesmereUIDB profiles, including imports/resets.

Pages: QoL, Cursor, Shifter, Raid Tools, Logging. Automation and overlays
start disabled and can be enabled individually. The first-install Cursor
Circle checkbox is respected. Global Settings > Fonts edits native text sizes
and the module font; Unlock Mode moves enabled displays and the raid toolbar.

Supported: personal/guild repair with funds checks; bounded junk selling at a
merchant (quality zero, positive sell price, unlocked, non-quest/non-lootable);
quick loot honoring the native auto-loot modifier; trainer Train All button;
fill delete confirmation without accepting it; skip cinematics; error/tutorial
toggles with restoration; FPS/latency, native crit/haste, coordinates, crosshair,
durability, local combat/group-death alerts, player Sated/Exhaustion, player
Rebirth and a learned class/custom movement spell cooldown; cursor ring/trail
with GCD/cast/channel progress; native window dragging; target raid markers,
Ready Check and local pull countdown; optional raid/dungeon combat logging.

Shift + left-drag on a native window background saves its position. Ctrl +
left-drag moves it until it closes. Window changes and secure raid layout
wait until out of combat. Native mouse/movable/point state restores on disable.
Logging already active when QoL starts does not become owned by this module.

Wrath has no modern shared battle-res charges, Mythic+ keys, upgrade calculator,
teleport prompt, Mastery or Versatility. Those Retail pages are not exposed.
Rebirth tracks only the player's learned spell; Sated tracks the player's own
debuff. Cooldown displays cannot read arbitrary remote group cooldowns.
Cursor progress uses native textures and 32 pips, without masks/rotation APIs.
The 325px Retail trail texture has a separate 256px uncompressed native copy.

validate_qol.py runs the actual Lite dispatcher/native module in Lua 5.1 and
tests automation, ownership, native tuples/timers, combat guards, restoration,
profiles, movers, options/global fonts and original file integrity. Visual
appearance and native secure behavior still need confirmation in the client.
