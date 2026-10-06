"""Lists every addon media path the Unit Frames engine/options name and whether
3.3.5 can load it (exists, not PNG, power-of-two 24/32-bit TGA)."""
from pathlib import Path
import re
import struct
import sys

root = Path(__file__).resolve().parents[1]
retail = Path('D:/World of Warcraft/_retail_/Interface/AddOns')
sources = [root / 'EllesmereUIUnitFrames' / n for n in (
    'EllesmereUIUnitFrames.lua', 'EUI_UnitFrames_Engine.lua', 'EUI_UnitFrames_335.lua',
    'EUI_UnitFrames_335_Auras.lua', 'EUI_UnitFrames_335_FormBar.lua')]
sources.append(root / 'EllesmereUIOptions' / 'EUI_UnitFrames_Options.lua')
lit = re.compile(r'"(Interface\\\\AddOns\\\\[^"]+)"')


def tga_ok(p):
    b = p.read_bytes()
    if len(b) < 18:
        return 'short'
    if b[2] not in (2, 10):
        return f'image type {b[2]}'
    w, h, depth = struct.unpack('<HHB', b[12:17])
    if not (w and h and w & (w - 1) == 0 and h & (h - 1) == 0):
        return f'NPOT {w}x{h}'
    if depth not in (24, 32):
        return f'depth {depth}'
    return 'ok'


redirect = {}
for gen in ('EUI_UnitFrames_335_Textures.lua', 'EUI_UnitFrames_335_Media.lua'):
    for old, new in re.findall(r'paths\[ \[\[([^\]]+)\]\] \] = \[\[([^\]]+)\]\]',
                               (root / 'EllesmereUIUnitFrames' / gen).read_text(encoding='utf-8')):
        redirect[old.replace('\\', '/')[len('interface/addons/'):]] = new.replace('\\', '/')[len('Interface/AddOns/'):]


def status(rel):
    if rel.lower() in redirect:
        return status(redirect[rel.lower()])
    p = root / rel
    if rel.lower().endswith('.png'):
        tga = p.with_suffix('.tga')
        return 'PNG' + (' (tga twin ' + tga_ok(tga) + ')' if tga.is_file() else ' (no tga)')
    if not p.suffix:
        for ext in ('.tga', '.blp'):
            if p.with_suffix(ext).is_file():
                p = p.with_suffix(ext)
                break
        else:
            return 'MISSING'
    if not p.is_file():
        return 'MISSING' + (' (retail has it)' if (retail / rel).is_file() else '')
    if p.suffix.lower() == '.tga':
        return tga_ok(p)
    return 'ok'


seen = {}
for src in sources:
    text = src.read_text(encoding='utf-8-sig', errors='replace')
    for n, line in enumerate(text.splitlines(), 1):
        for m in lit.finditer(line):
            path = m.group(1).replace('\\\\', '/')
            rel = path[len('Interface/AddOns/'):]
            seen.setdefault(rel, f'{src.name}:{n}')
for folder in ('combat', 'portraits', 'icons/roles', 'icons/class-full'):
    for p in sorted((root / 'EllesmereUI/media' / folder).glob('*.tga')):
        seen.setdefault(p.relative_to(root).as_posix(), 'media folder')
# Paths the frames never draw on 3.3.5, with the reason.
IGNORED = {
    'EllesmereUI/media/combat/': 'prefix of the combat art below',
    'EllesmereUI/media/icons/': 'prefix of the class icon sprites',
    'EllesmereUI/media/enemy-portrait.png': 'unused constant (not shipped by Retail either)',
}
ABSORB_ONLY = 'EllesmereUI/media/textures/shields/'  # absorb art: no absorb API on 3.3.5
only_bad = '--bad' in sys.argv
failures = 0
for rel in sorted(seen):
    st = status(rel)
    note = IGNORED.get(rel) or (rel.startswith(ABSORB_ONLY) and 'absorb art (no absorb API)')
    if st != 'ok' and not note:
        failures += 1
    if only_bad and (st == 'ok' or note):
        continue
    print(f'{st:28} {rel}   [{seen[rel]}]')
print(f'{"FAIL" if failures else "PASS"}: {failures} unloadable unit frame media path(s)')
sys.exit(1 if failures else 0)
