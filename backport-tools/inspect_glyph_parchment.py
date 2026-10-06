"""Locate the parchment body inside the extracted UI-GlyphFrame art (run inspect_glyph_art.py first)."""
from pathlib import Path
from PIL import Image
import numpy as np
root = Path(__file__).resolve().parents[1]
img = np.array(Image.open(root / 'backport-tools' / '_glyph_art' / 'UI-GlyphFrame.png').convert('RGBA')).astype(int)
sheet = img[:441, :352]
r, g, b, a = sheet[..., 0], sheet[..., 1], sheet[..., 2], sheet[..., 3]
# Parchment: opaque, warm (red over blue) and not the grey border/title bar.
warm = (a > 200) & (r - b > 35) & (r > 70)
cols = warm.mean(axis=0)
rows = warm.mean(axis=1)
for label, prof in (('x', cols), ('y', rows)):
    dense = np.nonzero(prof > 0.6)[0]
    print(label, 'parchment >60% span', dense.min(), '-', dense.max())
for y in (30, 34, 36, 38, 40, 42, 44, 220, 420, 424, 426, 428, 430, 432, 434):
    line = warm[y]
    xs = np.nonzero(line)[0]
    print('row', y, 'warm x', (xs.min(), xs.max()) if len(xs) else None, 'ratio', round(line.mean(), 2))
for x in (14, 16, 18, 20, 22, 24, 338, 340, 342, 344, 346):
    col = warm[:, x]
    ys = np.nonzero(col)[0]
    print('col', x, 'warm y', (ys.min(), ys.max()) if len(ys) else None, 'ratio', round(col.mean(), 2))
