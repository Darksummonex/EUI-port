"""Build the Wrath textures for Settings Overrides (spec + conditional).

Wrath cannot read PNG and wants power-of-two sizes, so each Retail icon the
override UI draws is written as uncompressed 32-bit TGA under
media/icons_335. Non power-of-two art is resampled to the next power of two;
the Lua side keeps the Retail on-screen sizes, so the quad still shows the
original aspect. The Retail PNG files stay untouched.
"""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
media = root / 'EllesmereUI' / 'media'
out_dir = media / 'icons_335'
out_dir.mkdir(exist_ok=True)

SOURCES = {
    'multispec': media / 'icons' / 'class-full' / 'multispec.png',
    'eui-info': media / 'icons' / 'eui-info.png',
    'eui-edit': media / 'icons' / 'eui-edit.png',
    'eui-unlocked-small': media / 'icons' / 'eui-unlocked-small.png',
    'role-tank': root / 'EllesmereUIRaidFrames' / 'Media' / 'tank-modern.png',
    'role-healer': root / 'EllesmereUIRaidFrames' / 'Media' / 'healer-modern.png',
    'role-dps': root / 'EllesmereUIRaidFrames' / 'Media' / 'dps-modern.png',
}
for name in ('arena', 'dungeons', 'horde', 'keybinds', 'raid', 'solo'):
    SOURCES['override-' + name] = media / 'icons' / 'overrides' / f'override-{name}.png'

# Class sprites ship as RLE 1024x1024 TGA; the copies are uncompressed and
# halved (the sprite coordinates are fractions, so they stay valid).
SPRITES = {
    'class-glyph': media / 'icons' / 'class-full' / 'glyph.tga',
    'class-modern': media / 'icons' / 'class-full' / 'modern.tga',
}


def pow2(n):
    p = 1
    while p < n:
        p *= 2
    return p


for name, src in SOURCES.items():
    img = Image.open(src).convert('RGBA')
    w, h = img.size
    size = (pow2(w), pow2(h))
    if size != img.size:
        img = img.resize(size, Image.LANCZOS)
    dst = out_dir / (name + '.tga')
    img.save(dst, compression=None)
    print('wrote', dst.relative_to(root), size)

for name, src in SPRITES.items():
    img = Image.open(src).convert('RGBA')
    img = img.resize((img.width // 2, img.height // 2), Image.LANCZOS)
    dst = out_dir / (name + '.tga')
    img.save(dst, compression=None)
    print('wrote', dst.relative_to(root), img.size)
