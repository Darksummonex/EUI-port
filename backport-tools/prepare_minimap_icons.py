"""Convert the EUI PNG glyphs used by the Wrath Minimap into loadable TGA files.

Wrath cannot read PNG and needs power-of-two textures. Retail draws the
Friends Online and addon-flyout toggle glyphs from atlases that do not exist
on Wrath, so the shared EUI glyphs stand in, fitted onto a transparent 64x64
canvas and written as uncompressed 32-bit TGA. The PNG sources stay untouched.
"""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
media = root / 'EllesmereUI' / 'media'
dst = root / 'EllesmereUIMinimap' / 'Media_335'
dst.mkdir(exist_ok=True)
SIZE = 64
for src, name in [(media / 'micromenu' / 'menu-friends.png', 'friends'),
                  (media / 'icons' / 'grid.png', 'flyout')]:
    img = Image.open(src).convert('RGBA')
    if img.width < SIZE and img.height < SIZE:
        scale = min(SIZE * 0.75 / img.width, SIZE * 0.75 / img.height)
        img = img.resize((round(img.width * scale), round(img.height * scale)), Image.LANCZOS)
    img.thumbnail((SIZE, SIZE), Image.LANCZOS)
    canvas = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    canvas.paste(img, ((SIZE - img.width) // 2, (SIZE - img.height) // 2), img)
    canvas.save(dst / (name + '.tga'), compression=None)
    print('wrote', (dst / (name + '.tga')).relative_to(root))
