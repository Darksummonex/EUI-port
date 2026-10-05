"""Include the requested downward Player Buff growth correction in build 0.24."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
path=root/'EllesmereUIActionBars/EllesmereUIActionBars.toc'; text=path.read_text(encoding='utf-8-sig')
assert '## Version: 9.3.4-335-0.9' in text
path.write_text(text.replace('## Version: 9.3.4-335-0.9','## Version: 9.3.4-335-0.10'),encoding='utf-8')
path=root/'backport-tools/package_unitframes.py'; text=path.read_text(encoding='utf-8-sig')
text=text.replace("'EllesmereUIActionBars':'9.3.4-335-0.9'","'EllesmereUIActionBars':'9.3.4-335-0.10'").replace('EllesmereUIActionBars-3.3.5-0.9.zip','EllesmereUIActionBars-3.3.5-0.10.zip')
path.write_text(text,encoding='utf-8')
path=root/'EllesmereUIActionBars/README-335.md'; text=path.read_text(encoding='utf-8-sig').replace('# Action Bars 3.3.5 — 0.9','# Action Bars 3.3.5 — 0.10',1)
text=text.replace('\n\n0.9 adds','''

0.10 keeps Player Buffs growing downward. Saved CENTER/BOTTOM anchors previously
moved the top row upward when the holder grew taller. The existing top-right
corner now stays fixed as rows are added/removed, and the saved position uses
that top anchor. Row offsets remain negative Y. Edit Mode drag sessions retain
their current anchor until committed; combat changes follow the existing queue.
Checks cover row growth/shrink, native timers/cancellation, drag, combat,
position persistence, restoration and independent debuff layout.

0.9 adds''',1)
path.write_text(text,encoding='utf-8')
for name in ['CODEX_HANDOFF_EllesmereUI_335_CURRENT.md','ELLESMEREUI_335_BACKPORT_STATUS.md']:
    path=root/name; text=path.read_text(encoding='utf-8-sig')
    text=text.replace('Latest build: HUD-test-0.24. Bags 0.5 / Options 0.29; other versions unchanged.','Latest build: HUD-test-0.24. Bags 0.5 / Options 0.29 / ActionBars 0.10;\nother versions unchanged.',1)
    text=text.replace('The broker object uses only the libraries bundled in EUI Core.','''Player Buffs: the user requested downward growth within the screen. Aura row
offsets already used negative Y, but CENTER/BOTTOM holder anchors shifted the
top row upward as height changed. ActionBars 0.10 fixes the top-right corner
before resizing and persists a top anchor. Live Edit Mode dragging and combat
deferral remain intact; debuff layout is unchanged. The secure ActionBars/HUD
regression checks growth/shrink, position persistence and native behavior.

The broker object uses only the libraries bundled in EUI Core.''',1)
    if name.startswith('CODEX'): text=text.replace('| EllesmereUIActionBars | 9.3.4-335-0.9 |','| EllesmereUIActionBars | 9.3.4-335-0.10 |',1)
    path.write_text(text,encoding='utf-8')
path=root/'ELLESMEREUI_PROJECT_PACK.md'; text=path.read_text(encoding='utf-8-sig').replace('and dependencies are removed. Only Core-bundled libraries power the broker.','and dependencies are removed. Player Buffs also keep their top row fixed as\nnew rows grow downward. Only Core-bundled libraries power the broker.')
path.write_text(text,encoding='utf-8')
print('PASS: ActionBars 0.10 downward buff growth included in build 0.24.')
