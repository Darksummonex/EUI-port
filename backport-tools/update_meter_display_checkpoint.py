"""One-time 0.33 checkpoint: meter readability/icons and Wrath theme layers."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]

changes=[('EllesmereUI','3.3.5-core-0.26','3.3.5-core-0.27'),
         ('EllesmereUIOptions','9.3.4-335-0.37','9.3.4-335-0.38'),
         ('EllesmereUIDamageMeters','9.3.4-335-0.1','9.3.4-335-0.2')]
for folder,old,new in changes:
    p=root/folder/(folder+'.toc'); text=p.read_text(encoding='utf-8-sig')
    assert '## Version: '+old in text
    p.write_text(text.replace('## Version: '+old,'## Version: '+new),encoding='utf-8')
p=root/'backport-tools/package_unitframes.py'; text=p.read_text(encoding='utf-8-sig')
for old,new in [("'"+a+"'","'"+b+"'") for _,a,b in changes]+[
    ('EllesmereUI-3.3.5-core-0.26.zip','EllesmereUI-3.3.5-core-0.27.zip'),
    ('EllesmereUIOptions-3.3.5-0.37.zip','EllesmereUIOptions-3.3.5-0.38.zip'),
    ('EllesmereUIDamageMeters-3.3.5-0.1.zip','EllesmereUIDamageMeters-3.3.5-0.2.zip'),
    ('HUD-test-0.32.zip','HUD-test-0.33.zip')]:
    assert old in text; text=text.replace(old,new)
p.write_text(text,encoding='utf-8')

note='''Latest build: HUD-test-0.33. Core 0.27 / Options 0.38 / Damage Meters 0.2;
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

'''
for name in ['CODEX_HANDOFF_EllesmereUI_335_CURRENT.md','ELLESMEREUI_335_BACKPORT_STATUS.md']:
    p=root/name; text=p.read_text(encoding='utf-8-sig'); i=text.index('\n\n')+2
    p.write_text(text[:i]+note+text[i:],encoding='utf-8')
readmes=[('EllesmereUI','# EllesmereUI Core — 3.3.5 — 0.27',
    '0.27 separates the Wrath theme image from the opaque base using native\nBORDER/BACKGROUND layers. Pixels/collapse decoration sits above the art;\nRetail retains its sublevels. This fixes the base occlusion left in 0.26.\n\n'),
    ('EllesmereUIOptions','# Options 3.3.5 — 0.38',
    '0.38 adds Damage Meters per-window bar/header/footer opacity, font outline\nand specialization-icon controls alongside the existing background opacity.\n\n'),
    ('EllesmereUIDamageMeters','# EllesmereUI Damage Meters — Wrath 3.3.5a — 0.2',
    '''0.2 adds independent background, bar and header/footer opacity controls.
Names and values default to OUTLINE with black shadow so white class bars
stay readable. Font Outline and Show Specialization Icons are per-window.
Player talent data and throttled native group inspection provide spec icons;
class icons appear until talent data is available. Inspection runs outside
combat, respects the native Inspect UI/other queries and verifies GUIDs.
Known segment icons are retained across talent switches. No external
cache/library is used. Existing windows retain their values and gain the
new defaults. Native talent availability/range can delay group icons.

''')]
for folder,title,entry in readmes:
    p=root/folder/'README-335.md'; text=p.read_text(encoding='utf-8-sig'); i=text.index('\n\n')+2
    text=title+'\n\n'+entry+text[i:]
    if folder=='EllesmereUIDamageMeters': text=text.replace('Only the three EUI_DamageMeters_335 files run.','Only the four EUI_DamageMeters_335 files run.')
    p.write_text(text,encoding='utf-8')
p=root/'ELLESMEREUI_PROJECT_PACK.md'; text=p.read_text(encoding='utf-8-sig')
text=text.replace('build 0.32','build 0.33').replace('HUD-test-0.32.zip','HUD-test-0.33.zip')
start,end=text.index('Saved checkpoint:'),text.index('This project pack contains')
text=text[:start]+'''Saved checkpoint: 1 October 2026. Build 0.33 adds independent meter
background/bar/header opacity, outlined text and native talent spec icons,
and fixes options theme artwork hidden by the opaque base on Wrath.
Automated Lua 5.1 regressions pass; native appearance needs client review.

'''+text[end:]
p.write_text(text,encoding='utf-8')
print('PASS: 0.33 Core/Options/Damage Meters versions, package selection and checkpoint documentation saved.')
