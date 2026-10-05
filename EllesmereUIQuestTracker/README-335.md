# Quest Tracker 3.3.5 — 0.1

Open /eqt or EllesmereUI > Quest Tracker. Wrath's native WatchFrame continues
to handle quests, achievements, timers, map links, collapse controls and
quest-item clicks/cooldowns. EUI adds readable fonts, a background sized to
visible content, accent line, scale, width/height and visibility settings.
Move it using Unlock Mode. Disabling restores native geometry and text.

Quest Helpers are optional and default off. Auto accept/turn-in can be skipped
with Shift. Reward choices, gossip/shared choices and paid/material turn-ins
remain manual. Quest Item Hotkey, e.g. ALT-X, securely clicks the first visible
native tracker item button. Leave blank to disable. Rebinding and structural
changes defer during combat; no persistent keyboard capture or Escape hook.

EllesmereUIQuestTrackerDB is owned by EUI Lite and participates in EUI profiles,
presets and global/module font settings. No external addons/data are required.
Original Retail Lua/media remain unchanged and unloaded. Retail-only objectives
systems are not loaded on Wrath. The tracker displays what the native client
watches; this port does not invent Retail campaign/world-quest APIs.

validate_friends_questtracker.py verifies lifecycle/combat deferral, native
line hooks, background/font/visibility behavior, quest item hotkeys and native
clicks, Unlock Mode position, restoration, helper guards and Options pages.
Confirm rendering and native interactions in the real client.
