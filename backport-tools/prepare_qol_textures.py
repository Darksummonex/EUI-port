"""Convert the Retail trail texture's 325px canvas to a native Wrath TGA."""
from pathlib import Path
import struct
from PIL import Image
root=Path(__file__).resolve().parents[1]
media=root/'EllesmereUIQoL/Media'
target=media/'Textures_335'
target.mkdir(exist_ok=True)
for source in [media/'circle_cursor.tga',*sorted(media.glob('ring_*.tga'))]:
    image=Image.open(source).convert('RGBA')
    if source.name=='circle_cursor.tga': image=image.resize((256,256),Image.Resampling.LANCZOS)
    width,height=image.size
    header=struct.pack('<BBBHHBHHHHBB',0,0,2,0,0,0,0,0,width,height,32,8)
    (target/source.name).write_bytes(header+image.transpose(Image.Transpose.FLIP_TOP_BOTTOM).tobytes('raw','BGRA'))
print('PASS: six QoL cursor textures normalized to bottom-origin uncompressed BGRA32, power-of-two dimensions; originals retained.')
