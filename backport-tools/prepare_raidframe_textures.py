"""Keep originals intact; give this module independent native texture assets."""
from pathlib import Path
from PIL import Image
import struct
root=Path(__file__).resolve().parents[1]
media=root/'EllesmereUIRaidFrames/Media'
bars=media/'Textures_335'; bars.mkdir(exist_ok=True)
for source in (root/'EllesmereUIUnitFrames/Media/Textures_335').glob('*.tga'):
    (bars/source.name).write_bytes(source.read_bytes())
icons=media/'Icons_335'; icons.mkdir(exist_ok=True)
for name in ['tank','healer','dps']:
    image=Image.open(media/(name+'.png')).convert('RGBA').resize((32,32),Image.Resampling.LANCZOS)
    header=struct.pack('<BBBHHBHHHHBB',0,0,2,0,0,0,0,0,32,32,32,8)
    (icons/(name+'.tga')).write_bytes(header+image.transpose(Image.Transpose.FLIP_TOP_BOTTOM).tobytes('raw','BGRA'))
print('PASS: independent native Raid Frames bar textures and three role icons; Retail originals retained.')
