"""Build Wrath TGA copies of the options footer social icons and the GitHub mark.

Wrath cannot read PNG and needs power-of-two sizes, so the 40x40 Twitch,
Discord, Patreon and PayPal icons and the 64x64 GitHub mark are written as
64x64 uncompressed 32-bit TGA in icons_335. The PNG sources stay untouched.
"""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
src = root / 'EllesmereUI' / 'media' / 'icons'
dst = root / 'EllesmereUI' / 'media' / 'icons_335'
dst.mkdir(exist_ok=True)

for name in ('github', 'twitch-2', 'discord-2', 'donate-3', 'paypal'):
    img = Image.open(src / (name + '.png')).convert('RGBA')
    if img.size != (64, 64):
        img = img.resize((64, 64), Image.LANCZOS)
    out = dst / (name + '.tga')
    img.save(out, compression=None)
    print('wrote', out.relative_to(root))
