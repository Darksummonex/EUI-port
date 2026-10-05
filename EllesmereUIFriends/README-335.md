# Friends 3.3.5 — 0.1

Open /efriends or EllesmereUI > Friends. The native social window and friend
list keep their existing actions, tabs, tooltips and client-supported data.
EUI adds readable outlined text, localized class colors/icons, row/background
opacity, window scale and borders. Blizzard/classic styles use native Wrath art.
Disabling the module restores its fonts/art/scale; Blizzard Skin resumes its
configured social skin. Window and row construction defers during combat.

Settings use EllesmereUIFriendsDB through EUI Lite and join EUI profiles,
presets and global font settings. This module reads native friend information;
no other addon is required. Retail Lua/media are retained unchanged and unloaded.
Modern Retail-only social/group/collection APIs are not emulated.

validate_friends_questtracker.py verifies real lifecycle, native actions,
recycled/localized/offline rows, styles, fonts, combat deferral and Options.
validate_blizzardskin.py verifies social-window ownership handoff. Confirm
appearance and native interaction in the real client.
