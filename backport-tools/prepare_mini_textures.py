"""Bake circular collapsed-panel emblems for the client without texture masks."""
from pathlib import Path
import re
from PIL import Image, ImageDraw, ImageChops

root = Path(__file__).resolve().parents[1]
media = root / 'EllesmereUI/media'
dest = media / 'mini_335'
dest.mkdir(exist_ok=True)
core = (root / 'EllesmereUI/EllesmereUI.lua').read_text(encoding='utf-8-sig')
mask = Image.new('L', (512, 512))
ImageDraw.Draw(mask).ellipse((0, 0, 511, 511), fill=255)
mask = mask.resize((128, 128), Image.Resampling.LANCZOS)
ring = Image.new('RGBA', (128, 128), 'white')
ring.putalpha(mask)
ring.save(dest / 'ring.tga')
for name, body in re.findall(r'\["backgrounds\\\\([^"\\]+)\.png"\]\s*=\s*\{([^}]+)\}', core):
    ex = re.search(r'\bex\s*=\s*(\d+)', body)
    ey = re.search(r'\bey\s*=\s*(\d+)', body)
    if not ex or not ey:
        continue
    ex, ey = int(ex[1]), int(ey[1])
    source = Image.open(media / 'backgrounds_335' / (name + '.tga')).convert('RGBA')
    box = (ex * source.width / 1500, ey * source.height / 1154,
           (ex + 76) * source.width / 1500, (ey + 76) * source.height / 1154)
    badge = source.transform((128, 128), Image.Transform.EXTENT, box, Image.Resampling.BICUBIC)
    badge.putalpha(ImageChops.multiply(badge.getchannel('A'), mask))
    badge.save(dest / (name + '.tga'))
    if name == 'eui-bg-pixels-compressed':
        overlay = Image.open(media / 'backgrounds_335/eui-bg-pixels-accent.tga').convert('RGBA')
        box = ((ex - 102) * overlay.width / 1295, (ey - 127) * overlay.height / 110,
               (ex + 76 - 102) * overlay.width / 1295, (ey + 76 - 127) * overlay.height / 110)
        overlay = overlay.transform((128, 128), Image.Transform.EXTENT, box, Image.Resampling.BICUBIC)
        overlay.putalpha(ImageChops.multiply(overlay.getchannel('A'), mask))
        overlay.save(dest / 'pixels-accent.tga')
    print(name)
