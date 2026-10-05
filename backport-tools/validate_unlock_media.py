"""Every Unlock Mode texture path must resolve to a power-of-two TGA Wrath can load."""
from pathlib import Path
import re
from PIL import Image

root = Path(__file__).resolve().parents[1]
source = (root / 'EllesmereUI/EUI_UnlockMode.lua').read_text(encoding='utf-8-sig')
assert '.png' not in source, 'Wrath cannot load PNG'

paths = set(re.findall(r'"Interface\\\\AddOns\\\\EllesmereUI\\\\media\\\\([^"]+\.tga)"', source))
icon_dir = re.search(r'local ICON_PATH = "Interface\\\\AddOns\\\\EllesmereUI\\\\media\\\\([^"]+)"', source).group(1)
paths |= {icon_dir + name for name in re.findall(r'ICON_PATH \.\. "([^"]+\.tga)"', source)}
for stem in re.findall(r'"Interface\\\\AddOns\\\\EllesmereUI\\\\media\\\\([^"]+)" \.\. ov \.\. "\.tga"', source):
    paths |= {stem + '.tga', stem + '-override.tga'}
assert len(paths) >= 18, sorted(paths)

for rel in sorted(paths):
    file = root / 'EllesmereUI/media' / rel.replace('\\\\', '/')
    assert file.is_file(), rel
    w, h = Image.open(file).size
    assert w & (w - 1) == 0 and h & (h - 1) == 0 and max(w, h) <= 1024, (rel, w, h)
print('PASS: %d Unlock Mode textures resolve to power-of-two TGA files' % len(paths))
