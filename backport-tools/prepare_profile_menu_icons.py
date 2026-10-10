"""Build the Wrath keybind icon for the Profiles page's Active Profile menu.

Wrath cannot read PNG and wants power-of-two sizes: media/icons/eui-keybind-2.png
is written as uncompressed 32-bit TGA under media/icons_335 (eui-close and
eui-edit already exist there). The Retail PNG stays untouched.
"""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
media = root / 'EllesmereUI' / 'media'


def pow2(n):
    p = 1
    while p < n:
        p *= 2
    return p


img = Image.open(media / 'icons' / 'eui-keybind-2.png').convert('RGBA')
size = (pow2(img.width), pow2(img.height))
if size != img.size:
    img = img.resize(size, Image.LANCZOS)
dst = media / 'icons_335' / 'eui-keybind-2.tga'
img.save(dst, compression=None)
print('wrote', dst.relative_to(root), size)
