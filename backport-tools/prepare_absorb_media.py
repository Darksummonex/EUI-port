"""Build Wrath TGA copies of the Retail absorb shield art.

Wrath reads only power-of-two TGA/BLP. The Retail shield styles are PNG or
non-power-of-two TGA, so each one used by the 3.3.5 absorb overlay
(EllesmereUI_Absorbs_335.lua) is written as an uncompressed 32-bit TGA in
EllesmereUI/media/textures/shields_335. Sizes are resized to the nearest
power of two; the striped tiles are already 256x128 and keep their pixels.
The Retail sources stay byte-identical.
"""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
src = root / 'EllesmereUI' / 'media' / 'textures' / 'shields'
dst = root / 'EllesmereUI' / 'media' / 'textures' / 'shields_335'


def pot(n):
    p = 1
    while p < n:
        p *= 2
    return p if (p - n) <= (n - p // 2) else p // 2


def convert(name, out_name):
    img = Image.open(src / name).convert('RGBA')
    size = (max(8, pot(img.size[0])), max(8, pot(img.size[1])))
    if size != img.size:
        img = img.resize(size, Image.LANCZOS)
    dst.mkdir(parents=True, exist_ok=True)
    out = dst / (out_name + '.tga')
    img.save(out, compression=None)
    print('wrote', out.relative_to(root), size)


for name, out_name in (('striped-5.png', 'striped-5'), ('striped-5-reversed.png', 'striped-5-reversed'),
                       ('striped-thick.png', 'striped-thick'), ('striped-thick-r.png', 'striped-thick-r'),
                       ('striped3.tga', 'striped3'), ('blizzard.tga', 'blizzard')):
    convert(name, out_name)
