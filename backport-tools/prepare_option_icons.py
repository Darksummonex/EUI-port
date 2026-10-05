"""Build Wrath TGA copies of the shared options icons.

Wrath cannot read PNG, so the shared cog, directions, eye, close and undo
icons used by inline option cogs and the Aura Buff Reminders page are scaled
from 30x30 to 32x32 and written as uncompressed 32-bit TGA in icons_335.
The PNG sources stay untouched.
"""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
src = root / 'EllesmereUI' / 'media' / 'icons'
dst = root / 'EllesmereUI' / 'media' / 'icons_335'
dst.mkdir(exist_ok=True)

for name in ('cogs-3', 'eui-directions', 'eui-visible', 'eui-invisible', 'eui-close', 'undo'):
    img = Image.open(src / (name + '.png')).convert('RGBA')
    if img.size != (32, 32):
        img = img.resize((32, 32), Image.LANCZOS)
    out = dst / (name + '.tga')
    img.save(out, compression=None)
    print('wrote', out.relative_to(root))
