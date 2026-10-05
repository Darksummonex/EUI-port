"""Build Wrath TGA copies of the Unlock Mode art.

Wrath reads only power-of-two TGA/BLP. Every Unlock Mode texture is drawn at
a size set in Lua (banner, lock logo layers, grid flash, toolbar and cog
arrows), so stretching the source to a power of two keeps the drawn result.
Sizes round up for detail, capped at 1024 (the 1144 px banner -> 1024).
Lock/banner/flash art goes to media/unlock_335, icons to media/icons_335.
The PNG sources stay byte-identical to Retail.
"""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
media = root / 'EllesmereUI' / 'media'


def pot(n):
    p = 1
    while p < n:
        p *= 2
    return min(p, 1024)


def convert(src, dst):
    img = Image.open(src).convert('RGBA')
    size = (pot(img.size[0]), pot(img.size[1]))
    if size != img.size:
        img = img.resize(size, Image.LANCZOS)
    dst.parent.mkdir(parents=True, exist_ok=True)
    img.save(dst, compression=None)
    print('wrote', dst.relative_to(root), size)


for name in ('eui-unlocked-banner-2', 'eui-unlocked-outer-2', 'eui-unlocked-inner-2', 'eui-unlocked-top-2'):
    for suffix in ('', '-override'):
        convert(media / (name + suffix + '.png'), media / 'unlock_335' / (name + suffix + '.tga'))
convert(media / 'unlock-flash.png', media / 'unlock_335' / 'unlock-flash.tga')
for name in ('eui-arrow', 'right-arrow', 'grid', 'magnet', 'flashlight', 'hover', 'dark-overlay', 'coordinates'):
    convert(media / 'icons' / (name + '.png'), media / 'icons_335' / (name + '.tga'))
