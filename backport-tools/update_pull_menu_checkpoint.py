"""Record build 0.27 once after menu, raid countdown and stance-shell fixes."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
changes={'EllesmereUIMinimap':('0.1','0.2'),'EllesmereUIQoL':('0.1','0.2'),'EllesmereUIActionBars':('0.11','0.12'),'EllesmereUIOptions':('0.31','0.32')}
path=root/'backport-tools/package_unitframes.py'; text=path.read_text(encoding='utf-8-sig')
for folder,(old,new) in changes.items():
    before=f"'{folder}':'9.3.4-335-{old}'"; assert before in text
    text=text.replace(before,f"'{folder}':'9.3.4-335-{new}'")
    text=text.replace(f'{folder}-3.3.5-{old}.zip',f'{folder}-3.3.5-{new}.zip')
    toc=root/folder/(folder+'.toc'); content=toc.read_text(encoding='utf-8-sig')
    assert f'## Version: 9.3.4-335-{old}' in content
    toc.write_text(content.replace(f'## Version: 9.3.4-335-{old}',f'## Version: 9.3.4-335-{new}'),encoding='utf-8')
assert 'HUD-test-0.26.zip' in text
path.write_text(text.replace('HUD-test-0.26.zip','HUD-test-0.27.zip'),encoding='utf-8')
notes={
'EllesmereUIMinimap':'''0.2 restores the middle-click micro menu using a native EUI popup rather
than depending on EasyMenu. Character, talents, spellbook, professions,
group finder, achievements, quests, PvP, friends, guild, calendar, game menu
and support use native buttons or native window toggles. Professions falls
back to the Wrath Skills tab. Optional modern windows appear only when a
native button exists. Menu fonts and hover accent follow EUI. Outside click,
Escape, minimap hide, setting/module disable and combat entry close it.
Open Micro Menu on Middle Click remains selectable in Minimap options.
Original minimap scripts and mouse state are restored when disabled.''',
'EllesmereUIQoL':'''0.2 adds Raid Tools > Pull Timer Length (3-60 seconds, default 10), Send to
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
needs in-game confirmation.''',
'EllesmereUIActionBars':'''0.12 places the native stance/pet controllers and unused bonus bar shell
under a hidden parent while EUI is active. Blizzard Show/alpha/animation
updates cannot reveal a duplicate shell when entering a stance. Native
event registrations and EUI-reparented pet/stance buttons remain active;
EUI secure paging continues to handle bonus action pages. Disabling EUI
restores original parents, positions, alpha, visibility and native updates.
Checks simulate native Show/alpha reset in combat, enabled/disabled stance
headers, native button actions, restoration and existing secure paging.''',
'EllesmereUIOptions':'''0.32 retains the Minimap middle-click switch and adds Raid Tools pull
duration, DBM/BigWigs broadcast and chat countdown controls under Quality
of Life. The chat channel priority and synchronization permissions are
shown alongside the settings. Existing module options are retained.'''}
for folder,entry in notes.items():
    path=root/folder/'README-335.md'; text=path.read_text(encoding='utf-8-sig'); lines=text.splitlines()
    lines[0]=lines[0].rsplit(' — ',1)[0]+' — '+changes[folder][1]
    path.write_text(lines[0]+'\n\n'+entry+'\n\n'+'\n'.join(lines[2:])+'\n',encoding='utf-8')
entry='''Latest build: HUD-test-0.27. Minimap 0.2 / QoL 0.2 / ActionBars 0.12 /
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

Previous checkpoint: HUD-test-0.26.'''
for filename in ['CODEX_HANDOFF_EllesmereUI_335_CURRENT.md','ELLESMEREUI_335_BACKPORT_STATUS.md']:
    path=root/filename; text=path.read_text(encoding='utf-8-sig')
    old='Latest build: HUD-test-0.26.'; assert old in text
    text=text.replace(old,entry+'\n\nHUD-test-0.26.',1)
    for folder,(old,new) in changes.items(): text=text.replace(f'| {folder} | 9.3.4-335-{old} |',f'| {folder} | 9.3.4-335-{new} |')
    text=text.replace('Full build: EllesmereUI-3.3.5-HUD-test-0.26.zip','Full build: EllesmereUI-3.3.5-HUD-test-0.27.zip')
    path.write_text(text,encoding='utf-8')
path=root/'ELLESMEREUI_PROJECT_PACK.md'; text=path.read_text(encoding='utf-8-sig')
start=text.index('Saved checkpoint:'); end=text.index('This project pack contains')
text=text[:start]+'''Saved checkpoint: 1 October 2026. Build 0.27 restores the middle-click
minimap menu, adds adjustable pull timers with boss-mod packets/chat
countdown, and prevents native stance/bonus shells reappearing.
Automated checks passed; client rendering/taint and remote audio still need
confirmation. See QoL README for permissions and legacy BigWigs behavior.

'''+text[end:]
text=text.replace('build 0.26','build 0.27').replace('HUD-test-0.26.zip','HUD-test-0.27.zip'); path.write_text(text,encoding='utf-8')
print('PASS: build 0.27 TOCs, package versions and handoff/project docs updated.')
