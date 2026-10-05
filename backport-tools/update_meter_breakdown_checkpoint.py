"""One-time 0.34 checkpoint: native hover breakdown and inline player focus."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
changes=[('EllesmereUIOptions','9.3.4-335-0.38','9.3.4-335-0.39'),
         ('EllesmereUIDamageMeters','9.3.4-335-0.2','9.3.4-335-0.3')]
for folder,old,new in changes:
    p=root/folder/(folder+'.toc'); text=p.read_text(encoding='utf-8-sig')
    assert '## Version: '+old in text
    p.write_text(text.replace('## Version: '+old,'## Version: '+new),encoding='utf-8')
p=root/'backport-tools/package_unitframes.py'; text=p.read_text(encoding='utf-8-sig')
for old,new in [("'"+folder+"':'"+old+"'","'"+folder+"':'"+new+"'") for folder,old,new in changes]+[
    ('EllesmereUIOptions-3.3.5-0.38.zip','EllesmereUIOptions-3.3.5-0.39.zip'),
    ('EllesmereUIDamageMeters-3.3.5-0.2.zip','EllesmereUIDamageMeters-3.3.5-0.3.zip'),
    ('HUD-test-0.33.zip','HUD-test-0.34.zip')]:
    assert old in text; text=text.replace(old,new)
p.write_text(text,encoding='utf-8')
note='''Latest build: HUD-test-0.34. Damage Meters 0.3 / Options 0.39;
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

'''
for name in ['CODEX_HANDOFF_EllesmereUI_335_CURRENT.md','ELLESMEREUI_335_BACKPORT_STATUS.md']:
    p=root/name; text=p.read_text(encoding='utf-8-sig'); i=text.index('\n\n')+2
    p.write_text(text[:i]+note+text[i:],encoding='utf-8')
for folder,title,entry in [
    ('EllesmereUIOptions','# Options 3.3.5 — 0.39','0.39 updates Damage Meters window help for hover breakdown, inline player\nfocus, Back and the focused footer Spells/Targets selector.\n\n'),
    ('EllesmereUIDamageMeters','# EllesmereUI Damage Meters — Wrath 3.3.5a — 0.3',
    '''0.3 adds a live hover breakdown with spell icons, amounts/percentages,
target bars and Other totals. Left-click a player to replace that meter
with the person's spell bars. Its footer selects Spells/Targets; Back
returns to group. Spell bars include native icons and hover hit/crit/range
information. Mouse wheel scrolls. Death focus provides recorded recaps;
right-click opens the separate detailed statistics window. Reports follow
the displayed group/focus view and still require explicit Send.
Focus is transient per-window state. View/profile changes and reset clear
it; hover is cleaned up on reorder/hide. Tooltip rows are preallocated.

''')]:
    p=root/folder/'README-335.md'; text=p.read_text(encoding='utf-8-sig'); i=text.index('\n\n')+2
    text=title+'\n\n'+entry+text[i:]
    if folder=='EllesmereUIDamageMeters':
        text=text.replace('Only the four EUI_DamageMeters_335 files run.','Only the five EUI_DamageMeters_335 files run.')
        text=text.replace('left click opens spell statistics, right click opens target statistics.','left click focuses that player inside the meter, right click opens statistics.')
    p.write_text(text,encoding='utf-8')
p=root/'ELLESMEREUI_PROJECT_PACK.md'; text=p.read_text(encoding='utf-8-sig')
text=text.replace('build 0.33','build 0.34').replace('HUD-test-0.33.zip','HUD-test-0.34.zip')
start,end=text.index('Saved checkpoint:'),text.index('This project pack contains')
text=text[:start]+'''Saved checkpoint: 1 October 2026. Build 0.34 adds meter hover spell/target
breakdowns and left-click player focus inside the same window, with spell
icons, live totals, scrolling, Spells/Targets selection and Back.
Automated Lua 5.1 regressions pass; native appearance needs client review.

'''+text[end:]
p.write_text(text,encoding='utf-8')
print('PASS: 0.34 Damage Meters/Options versions, package selection and checkpoint documentation saved.')
