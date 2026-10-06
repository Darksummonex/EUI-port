"""Convert the Retail Friends row art into textures Wrath can load.

Wrath cannot read PNG and needs power-of-two textures. The 840x78 faction
banners are stretched across the whole friend row (texcoords 0..1), so they
are resampled to 512x64; the offline glyph is fitted onto a transparent
128x128 canvas. Output is uncompressed 32-bit TGA in Media_335. Region icons
are skipped (Wrath has no Battle.net region data). Retail PNGs stay untouched.
"""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
src = root / 'EllesmereUIFriends' / 'Media'
dst = root / 'EllesmereUIFriends' / 'Media_335'
dst.mkdir(exist_ok=True)
for name in ('alliance', 'horde', 'neutral'):
    img = Image.open(src / (name + '.png')).convert('RGBA').resize((512, 64), Image.LANCZOS)
    img.save(dst / (name + '.tga'), compression=None)
    print('wrote', (dst / (name + '.tga')).relative_to(root))
img = Image.open(src / 'offline.png').convert('RGBA')
img.thumbnail((128, 128), Image.LANCZOS)
canvas = Image.new('RGBA', (128, 128), (0, 0, 0, 0))
canvas.paste(img, ((128 - img.width) // 2, (128 - img.height) // 2), img)
canvas.save(dst / 'offline.tga', compression=None)
print('wrote', (dst / 'offline.tga').relative_to(root))
