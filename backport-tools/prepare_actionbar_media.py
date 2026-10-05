"""Build Wrath TGA copies of the Retail action bar interaction art.

Wrath reads only power-of-two TGA/BLP. The highlight/pushed textures are
stretched over the whole button (80x80 -> 64x64). The cooldown edge is not
converted: Wrath cooldown models have no edge texture. Output goes to
EllesmereUIActionBars/Media/Textures_335; the PNG sources stay byte-identical
to Retail.
"""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
src = root / 'EllesmereUIActionBars' / 'Media'
dst = src / 'Textures_335'


def pot(n):
    p = 1
    while p < n:
        p *= 2
    return p if (p - n) <= (n - p // 2) else p // 2


for name in ('highlight-2', 'highlight-3', 'highlight-4'):
    img = Image.open(src / (name + '.png')).convert('RGBA')
    size = (max(8, pot(img.size[0])), max(8, pot(img.size[1])))
    if size != img.size:
        img = img.resize(size, Image.LANCZOS)
    out = dst / (name + '.tga')
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out, compression=None)
    print('wrote', out.relative_to(root), size)
