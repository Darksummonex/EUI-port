"""Convert the Retail DataBars art into textures Wrath can load.

Wrath cannot read PNG and needs power-of-two textures. Every image is
resampled to the next power of two on each axis (stretch, so the Retail
texcoords keep addressing the same art) and written as uncompressed 32-bit
TGA into EllesmereUIDataBars/Media_335. Spec icons for Retail-only classes
(Demon Hunter, Evoker, Monk) and the micro menu icons for systems Wrath lacks
(adventure guide, collections, housing, shop, great vault) are skipped.
Retail PNGs stay untouched.
"""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
src = root / 'EllesmereUIDataBars' / 'media'
dst = root / 'EllesmereUIDataBars' / 'Media_335'
micro_src = root / 'EllesmereUI' / 'media' / 'micromenu'

SKIP_SPEC_PREFIX = ('dh-', 'evoker-', 'monk-')
SKIP_MICRO = {'menu-adventure', 'menu-collections', 'menu-housing', 'menu-shop', 'menu-vault'}


def pow2(n):
    p = 1
    while p < n:
        p *= 2
    return max(8, min(p, 1024))


def convert(path, out, size=None):
    img = Image.open(path).convert('RGBA')
    w, h = size or (pow2(img.width), pow2(img.height))
    if (w, h) != img.size:
        img = img.resize((w, h), Image.LANCZOS)
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out, compression=None)
    print('wrote', out.relative_to(root), img.size)


convert(root / 'EllesmereUI' / 'media' / 'modern_blizz.png', dst / 'modern_blizz.tga', (512, 512))
for name in ('audio', 'coordinates', 'hearthstone', 'home_latency', 'world_latency'):
    convert(src / (name + '.png'), dst / (name + '.tga'))
for png in sorted((src / 'profession').glob('*.png')):
    convert(png, dst / 'profession' / (png.stem + '.tga'))
for png in sorted((src / 'spec').glob('*.png')):
    if png.stem.startswith(SKIP_SPEC_PREFIX):
        continue
    convert(png, dst / 'spec' / (png.stem + '.tga'))
for png in sorted(micro_src.glob('*.png')):
    if png.stem in SKIP_MICRO:
        continue
    convert(png, dst / 'micromenu' / (png.stem + '.tga'))
