"""Build Wrath TGA copies of the Retail nameplate art.

Wrath reads only power-of-two TGA/BLP. Every nameplate texture is drawn
stretched to a size set in Lua (arrows w x 16, glows as 9-slices, stripes
across the bar), so resizing the source to the nearest power of two keeps
the drawn result. Output goes to EllesmereUINameplates/Media_335; the PNG
sources stay byte-identical to Retail.
"""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
src = root / 'EllesmereUINameplates' / 'Media'
dst = root / 'EllesmereUINameplates' / 'Media_335'


def pot(n):
    p = 1
    while p < n:
        p *= 2
    # Nearest power of two keeps fine art (66 -> 64, 90 -> 128, 400 -> 512).
    return p if (p - n) <= (n - p // 2) else p // 2


def convert(rel):
    img = Image.open(src / rel).convert('RGBA')
    w, h = img.size
    size = (max(8, pot(w)), max(8, pot(h)))
    if size != img.size:
        img = img.resize(size, Image.LANCZOS)
    out = dst / Path(rel).with_suffix('.tga')
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out, compression=None)
    print('wrote', out.relative_to(root), size)


for name in ('background', 'execute-glow', 'shield', 'striped-v2', 'striped-wide-v2',
             'stripes-medium', 'stripes-small-close', 'stripes-small-spread', 'striped-tiny'):
    convert(name + '.png')
for arrow in sorted((src / 'Arrows').glob('*.png')):
    convert(Path('Arrows') / arrow.name)
