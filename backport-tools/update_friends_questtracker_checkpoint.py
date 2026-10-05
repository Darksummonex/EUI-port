"""One-time checkpoint 0.38: native Wrath Friends and Quest Tracker."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
for folder,old,new in [('EllesmereUIOptions','0.42','0.43'),('EllesmereUIBlizzardSkin','0.6','0.7')]:
    p=root/folder/(folder+'.toc'); s=p.read_text(encoding='utf-8-sig')
    old_line='## Version: 9.3.4-335-'+old
    assert old_line in s
    p.write_text(s.replace(old_line,'## Version: 9.3.4-335-'+new),encoding='utf-8')
p=root/'backport-tools/package_unitframes.py'; s=p.read_text(encoding='utf-8-sig')
for old,new in [("'EllesmereUIOptions':'9.3.4-335-0.42'","'EllesmereUIOptions':'9.3.4-335-0.43'"),
                ("'EllesmereUIBlizzardSkin':'9.3.4-335-0.6'","'EllesmereUIBlizzardSkin':'9.3.4-335-0.7'"),
                ('Options-3.3.5-0.42.zip','Options-3.3.5-0.43.zip'),
                ('BlizzardSkin-3.3.5-0.6.zip','BlizzardSkin-3.3.5-0.7.zip'),
                ("'EllesmereUIQuickdraw':'9.3.4-335-0.1'}","'EllesmereUIQuickdraw':'9.3.4-335-0.1','EllesmereUIFriends':'9.3.4-335-0.1','EllesmereUIQuestTracker':'9.3.4-335-0.1'}"),
                ("    'EllesmereUI-3.3.5-HUD-test-0.37.zip':list(versions),", "    'EllesmereUIFriends-3.3.5-0.1.zip':['EllesmereUIFriends'],\n    'EllesmereUIQuestTracker-3.3.5-0.1.zip':['EllesmereUIQuestTracker'],\n    'EllesmereUI-3.3.5-HUD-test-0.38.zip':list(versions),")]:
    assert old in s,old
    s=s.replace(old,new)
p.write_text(s,encoding='utf-8')
note='''Latest build: HUD-test-0.38. Friends 0.1 and Quest Tracker 0.1 added.
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

'''
for filename in ['CODEX_HANDOFF_EllesmereUI_335_CURRENT.md','ELLESMEREUI_335_BACKPORT_STATUS.md']:
    p=root/filename; s=p.read_text(encoding='utf-8-sig'); i=s.index('\n\n')+2
    p.write_text(s[:i]+note+s[i:],encoding='utf-8')
for folder,title,version,addition in [
 ('EllesmereUIOptions','Options','0.43','0.43 adds native Friends and Quest Tracker settings, including visibility,\nUnlock Mode placement, fonts and optional quest helpers.\n\n'),
 ('EllesmereUIBlizzardSkin','Blizz UI Enhanced','0.7','0.7 hands FriendsFrame ownership to the enabled native Friends module and\nrestores its own social skin when that module is disabled. Other windows retain\ntheir existing skin behavior. Skin changes defer in combat.\n\n')]:
    p=root/folder/'README-335.md'; s=p.read_text(encoding='utf-8-sig'); i=s.index('\n\n')+2
    p.write_text(f'# {title} 3.3.5 — {version}\n\n'+addition+s[i:],encoding='utf-8')
(root/'EllesmereUIFriends/README-335.md').write_text('''# Friends 3.3.5 — 0.1

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
''',encoding='utf-8')
(root/'EllesmereUIQuestTracker/README-335.md').write_text('''# Quest Tracker 3.3.5 — 0.1

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
''',encoding='utf-8')
p=root/'ELLESMEREUI_PROJECT_PACK.md'; s=p.read_text(encoding='utf-8-sig')
s=s.replace('build 0.37','build 0.38').replace('HUD-test-0.37.zip','HUD-test-0.38.zip').replace('seventeen','nineteen').replace('eighteen','twenty')
start=s.index('Saved checkpoint:'); end=s.index('\n\nThis project pack',start)
s=s[:start]+'''Saved checkpoint: 1 October 2026. Build 0.38 adds Friends 0.1 and Quest
Tracker 0.1, updates Options to 0.43 and Blizzard Skin to 0.7 for social-window
ownership handoff. Native social actions and Wrath WatchFrame behavior remain
in place, with EUI styling/settings, tracker movement and optional quest helpers.
Prior modules and Quickdraw hotkey capture remain included. Automated Lua 5.1,
native lifecycle, combat deferral, Options input and skin regressions pass.
Rendering and native interaction need in-game review.'''+s[end:]
p.write_text(s,encoding='utf-8')
print('Updated checkpoint 0.38: nineteen EUI modules, twenty archives; Options 0.43, Blizzard Skin 0.7.')
