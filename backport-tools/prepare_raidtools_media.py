"""Build the Wrath TGA media used by QoL Raid Tools.

Wrath cannot read PNG. The window art reuses the Data Bars 512x512 copy of
modern_blizz (same crop numbers as Retail), and the collapsed icon is the
Retail raid-tools.png scaled to 64x64. Sources stay untouched.
"""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
dst = root / 'EllesmereUIQoL' / 'Media' / 'Textures_335'
dst.mkdir(parents=True, exist_ok=True)
FOOTER = b'TRUEVISION-XFILE.\x00'


def save(img, out):
    """Plain 18-byte header + pixels, like the other QoL textures (no TGA 2.0 footer)."""
    img.save(out, compression=None)
    data = out.read_bytes()
    if data.endswith(FOOTER):
        out.write_bytes(data[:-26])
    print('wrote', out.relative_to(root))


art = Image.open(root / 'EllesmereUIDataBars' / 'Media_335' / 'modern_blizz.tga').convert('RGBA')
art.info.clear()
save(art, dst / 'modern_blizz.tga')

img = Image.open(root / 'EllesmereUI' / 'media' / 'icons' / 'raid-tools.png').convert('RGBA')
save(img.resize((64, 64), Image.LANCZOS), dst / 'raid-tools.tga')
