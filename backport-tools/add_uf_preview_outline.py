"""One-off: Unit Frames options preview honours the per-slot text outline. Idempotent."""
import re
from pathlib import Path

PATH = Path(__file__).resolve().parent.parent / 'EllesmereUIOptions' / 'EUI_UnitFrames_Options.lua'
FS_KEYS = {
    'leftFS': 'leftText', 'rightFS': 'rightText', 'centerFS': 'centerText', 'extraFS': 'extraText',
    'btbLeftFS': 'btbLeft', 'btbRightFS': 'btbRight', 'btbCenterFS': 'btbCenter', 'ppPreviewFS': 'powerPercent',
}

data = PATH.read_bytes().decode('utf-8')
eol = '\r\n' if '\r\n' in data else '\n'
lines = data.split(eol)
changed = 0
for i, line in enumerate(lines):
    m = re.match(r'^(\s*)(\w+):SetFont\(PREVIEW_FONT, (.+), GetUFOptOutline\(\)\)\s*$', line)
    if m and m.group(2) in FS_KEYS:
        lines[i] = f'{m.group(1)}SetPVOutlineFont({m.group(2)}, {m.group(3)}, s.{FS_KEYS[m.group(2)]}Outline)'
        changed += 1
PATH.write_bytes(eol.join(lines).encode('utf-8'))
print(f'preview: {changed} lines')
