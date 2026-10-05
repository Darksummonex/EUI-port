"""Build the power-of-two, uncompressed RGBA character backdrop from the Retail art."""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
media = root / 'EllesmereUIBlizzardSkin/Media'
source = media / 'character-bg.png'
dest = media / 'character-bg.tga'
im = Image.open(source).convert('RGBA')
# The whole canvas is rescaled, so cover-cropping by the original 787x1030
# aspect in normalized UV space still matches the art. The PNG stays untouched.
im.resize((512, 1024), Image.Resampling.LANCZOS).save(dest)
print(f'{source.name} {im.size} -> {dest.name} (512, 1024)')
