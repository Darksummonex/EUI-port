"""Power-of-two copies of Core's 256x40 dispel gradients for the Wrath Raid Frames overlay."""
from pathlib import Path
from PIL import Image
import struct
root=Path(__file__).resolve().parents[1]
source=root/'EllesmereUI/media/textures'
target=root/'EllesmereUIRaidFrames/Media/Textures_335'
for name,out in [('gradient-tb.tga','dispel-gradient.tga'),('gradient-sharp.tga','dispel-gradient-sharp.tga')]:
    image=Image.open(source/name).convert('RGBA').resize((256,64),Image.Resampling.BICUBIC)
    header=struct.pack('<BBBHHBHHHHBB',0,0,2,0,0,0,0,0,256,64,32,8)
    (target/out).write_bytes(header+image.transpose(Image.Transpose.FLIP_TOP_BOTTOM).tobytes('raw','BGRA'))
print('PASS: dispel-gradient.tga and dispel-gradient-sharp.tga (256x64, 32-bit) written; Core originals untouched.')
