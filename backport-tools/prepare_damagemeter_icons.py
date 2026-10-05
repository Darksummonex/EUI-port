"""Convert the Retail damage meter PNG icons into Wrath-loadable TGA files.

Wrath cannot read PNG and needs power-of-two textures, so every dm_*.png is
fitted onto a transparent 64x64 canvas and written as 32-bit RLE-free TGA.
The original PNGs stay untouched (they must match the Retail reference).
"""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
src = root / 'EllesmereUIDamageMeters' / 'Media'
dst = root / 'EllesmereUIDamageMeters' / 'Media_335'
dst.mkdir(exist_ok=True)
SIZE = 64
for png in sorted(src.glob('dm_*.png')):
    img = Image.open(png).convert('RGBA')
    img.thumbnail((SIZE, SIZE), Image.LANCZOS)
    canvas = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    canvas.paste(img, ((SIZE - img.width) // 2, (SIZE - img.height) // 2), img)
    canvas.save(dst / (png.stem + '.tga'), compression=None)
    print('wrote', (dst / (png.stem + '.tga')).relative_to(root))
