"""Convert the Retail Bags art into textures Wrath can load.

Wrath cannot read PNG and needs power-of-two textures, so every image is
written as an uncompressed 32-bit TGA into EllesmereUIBags/Media_335. Full
bleed art (window background, slot background, pushed glow) is resized to the
canvas; glyphs are fitted onto a transparent canvas. Sources stay untouched.
"""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
dst = root / 'EllesmereUIBags' / 'Media_335'
dst.mkdir(exist_ok=True)
bags = root / 'EllesmereUIBags' / 'Media'
icons = root / 'EllesmereUI' / 'media' / 'icons'

STRETCH = {
    'modern_blizz': (root / 'EllesmereUI' / 'media' / 'modern_blizz.png', 512),
    'icon-bg': (bags / 'icon-bg.png', 64),
    'highlight-3': (bags / 'highlight-3.png', 64),
}
FIT = {
    'clean-up': (bags / 'clean-up.png', 64),
    'eui-close': (icons / 'eui-close.png', 32),
    'eui-arrow-left': (icons / 'eui-arrow-left.png', 32),
    'eui-arrow-right': (icons / 'eui-arrow-right.png', 32),
}

for name, (source, size) in STRETCH.items():
    img = Image.open(source).convert('RGBA').resize((size, size), Image.LANCZOS)
    img.save(dst / (name + '.tga'), compression=None)
    print('wrote', (dst / (name + '.tga')).relative_to(root))

for name, (source, size) in FIT.items():
    img = Image.open(source).convert('RGBA')
    img.thumbnail((size, size), Image.LANCZOS)
    canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    canvas.paste(img, ((size - img.width) // 2, (size - img.height) // 2), img)
    canvas.save(dst / (name + '.tga'), compression=None)
    print('wrote', (dst / (name + '.tga')).relative_to(root))
