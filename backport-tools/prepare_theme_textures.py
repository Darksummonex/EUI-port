"""Build power-of-two, uncompressed RGBA textures from the original theme art."""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
media = root / 'EllesmereUI/media'
for source_dir, dest_dir, names in [
    ('backgrounds', 'backgrounds_335', None),
    ('icons', 'icons_335', ['eui-resize-5.png', 'close-popup-4.png']),
]:
    source = media / source_dir
    dest = media / dest_dir
    dest.mkdir(exist_ok=True)
    files = [source / name for name in names] if names else sorted(source.glob('*.png'))
    for path in files:
        im = Image.open(path).convert('RGBA')
        size = (1024, 1024) if source_dir == 'backgrounds' else (32, 32)
        # Rescale the whole canvas so existing normalized UV cuts still match.
        # No padding/cropping, and the original PNG remains untouched.
        im.resize(size, Image.Resampling.LANCZOS).save(dest / (path.stem + '.tga'))
        print(f'{path.name} -> {dest_dir}/{path.stem}.tga {size}')
