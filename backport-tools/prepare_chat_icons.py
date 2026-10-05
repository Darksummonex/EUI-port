"""Convert the Retail Chat sidebar glyphs into textures Wrath can load.

Wrath cannot read PNG and needs power-of-two textures. The Retail 100x100
sidebar glyphs are fitted onto a transparent 64x64 canvas and written as
uncompressed 32-bit TGA. The M+ portal glyph is skipped (no keystones on
Wrath). The Retail PNG files stay untouched.
"""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
src_dir = root / 'EllesmereUIChat' / 'Media'
dst = root / 'EllesmereUIChat' / 'Media_335'
dst.mkdir(exist_ok=True)
SIZE = 64
for name in ('copy', 'durability', 'friends', 'guild', 'scroll2', 'settings', 'voice'):
    img = Image.open(src_dir / ('chat_' + name + '.png')).convert('RGBA')
    img.thumbnail((SIZE, SIZE), Image.LANCZOS)
    canvas = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    canvas.paste(img, ((SIZE - img.width) // 2, (SIZE - img.height) // 2), img)
    out = dst / ('chat_' + name + '.tga')
    canvas.save(out, compression=None)
    print('wrote', out.relative_to(root))
