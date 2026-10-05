"""Convert the sidebar module icons (power, sync, download) into Wrath TGA files.

Wrath cannot read PNG and needs power-of-two textures. Each glyph is cropped to
its visible pixels and scaled up to fill a transparent 64x64 canvas in
EllesmereUI/media/icons_335, so it covers the button like the Retail PNG does.
The PNGs stay as-is.
"""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
src = root / 'EllesmereUI' / 'media' / 'icons'
dst = root / 'EllesmereUI' / 'media' / 'icons_335'
dst.mkdir(exist_ok=True)
SIZE, PAD = 64, 2
for name in ('power', 'sync', 'eui-download'):
    img = Image.open(src / (name + '.png')).convert('RGBA')
    img = img.crop(img.split()[3].getbbox())
    scale = (SIZE - PAD * 2) / max(img.width, img.height)
    img = img.resize((max(1, round(img.width * scale)), max(1, round(img.height * scale))), Image.LANCZOS)
    canvas = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    canvas.paste(img, ((SIZE - img.width) // 2, (SIZE - img.height) // 2), img)
    canvas.save(dst / (name + '.tga'), compression=None)
    print('wrote', (dst / (name + '.tga')).relative_to(root))
