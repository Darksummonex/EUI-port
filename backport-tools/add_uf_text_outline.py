"""One-off: per-slot text outline for Unit Frames (runtime call sites + options cog rows).

Idempotent: lines already carrying an outline key are left alone.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RUNTIME = ROOT / 'EllesmereUIUnitFrames' / 'EllesmereUIUnitFrames.lua'
OPTIONS = ROOT / 'EllesmereUIOptions' / 'EUI_UnitFrames_Options.lua'

# FontString variable -> settings key prefix. btb FontStrings only exist in the btb block.
FS_KEYS = {
    'leftText': 'leftText', 'rightText': 'rightText', 'centerText': 'centerText', 'extraText': 'extraText',
    'leftFS': 'btbLeft', 'rightFS': 'btbRight', 'centerFS': 'btbCenter', 'ppFS': 'powerPercent',
}
SLOTS = ['leftText', 'rightText', 'centerText', 'extraText', 'btbLeft', 'btbRight', 'btbCenter', 'powerPercent']


def read(path):
    data = path.read_bytes().decode('utf-8')
    eol = '\r\n' if '\r\n' in data else '\n'
    return data.split(eol), eol


def write(path, lines, eol):
    path.write_bytes(eol.join(lines).encode('utf-8'))


def patch_runtime():
    lines, eol = read(RUNTIME)
    changed = 0
    for i, line in enumerate(lines):
        if line.strip() == 'local function SetFSFont(fs, size, flags)':
            lines[i] = line.replace('(fs, size, flags)', '(fs, size, flags, outline)')
            body = lines[i + 1]
            indent = body[:len(body) - len(body.lstrip())]
            lines[i + 1:i + 1] = [indent + 'if outline and EllesmereUI.ApplyTextOutline'
                                  ' and EllesmereUI.ApplyTextOutline(fs, GetSelectedFont(), size or 12, outline, "unitFrames") then return end']
            changed += 1
            continue
        m = re.match(r'^(\s*)SetFSFont\((\w+), (.+)\)\s*$', line)
        if not m or 'Outline' in line:
            continue
        fs, size = m.group(2), m.group(3)
        key = FS_KEYS.get(fs)
        if not key:
            continue
        tm = re.match(r'^(\w+)\.\w+', size)
        tbl = tm.group(1) if tm else None
        if not tbl and re.fullmatch(r'\w+', size):
            for j in range(i - 1, max(0, i - 120), -1):
                dm = re.match(r'^\s*local ' + re.escape(size) + r'\s*=\s*(\w+)\.', lines[j])
                if dm:
                    tbl = dm.group(1)
                    break
        if not tbl:
            raise SystemExit(f'no settings table for line {i + 1}: {line.strip()}')
        lines[i] = f'{m.group(1)}SetFSFont({fs}, {size}, nil, {tbl}.{key}Outline)'
        changed += 1
    write(RUNTIME, lines, eol)
    print(f'runtime: {changed} lines')


def patch_options():
    lines, eol = read(OPTIONS)
    out, i, added = [], 0, 0
    while i < len(lines):
        line = lines[i]
        out.append(line)
        m = re.search(r'get=function\(\) return (SVal|MVal)\("(\w+)Size"', line)
        if m and m.group(2) in SLOTS and 'type="slider"' in lines[i - 1]:
            getter, slot = m.group(1), m.group(2)
            setter = 'SSet' if getter == 'SVal' else 'MSet'
            nxt = lines[i + 1]
            out.append(nxt)
            i += 2
            if 'Outline' in lines[i]:
                continue
            indent = lines[i - 3][:len(lines[i - 3]) - len(lines[i - 3].lstrip())]
            inner = nxt[:len(nxt) - len(nxt.lstrip())]
            refresh = '; UpdatePreview()' if 'UpdatePreview()' in nxt else ''
            out.append(f'{indent}{{ type="dropdown", label="Outline", values=EllesmereUI.TEXT_OUTLINE_VALUES, order=EllesmereUI.TEXT_OUTLINE_ORDER,')
            out.append(f'{inner}get=function() return {getter}("{slot}Outline", "module") end,')
            out.append(f'{inner}set=function(v) {setter}("{slot}Outline", v){refresh} end }},')
            added += 1
            continue
        i += 1
    write(OPTIONS, out, eol)
    print(f'options: {added} dropdowns')


if __name__ == '__main__':
    patch_runtime()
    patch_options()
