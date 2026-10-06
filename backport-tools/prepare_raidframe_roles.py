"""Raid Frames 0.7: Retail "modern" and "pixels" role icon styles as uncompressed Wrath TGAs.

Retail ships PNGs and RLE-compressed TGAs; Wrath needs power-of-two, uncompressed
32-bit TGAs. Originals in Media/ stay byte-identical with Retail.
"""
from pathlib import Path
from PIL import Image
import struct
root=Path(__file__).resolve().parents[1]
media=root/'EllesmereUIRaidFrames/Media'
icons=media/'Icons_335'; icons.mkdir(exist_ok=True)

def write_tga(image,size,target):
    image=image.convert('RGBA').resize((size,size),Image.Resampling.LANCZOS if size>16 else Image.Resampling.NEAREST)
    header=struct.pack('<BBBHHBHHHHBB',0,0,2,0,0,0,0,0,size,size,32,8)
    target.write_bytes(header+image.transpose(Image.Transpose.FLIP_TOP_BOTTOM).tobytes('raw','BGRA'))

for role in ['tank','healer','dps']:
    write_tga(Image.open(media/(role+'-modern.png')),32,icons/(role+'-modern.tga'))
    write_tga(Image.open(media/('pixels-'+role+'.tga')),16,icons/('pixels-'+role+'.tga'))
for file in sorted(icons.glob('*.tga')):
    data=file.read_bytes(); width,height,depth,flags=struct.unpack('<HHBB',data[12:18])
    assert data[2]==2 and depth==32 and flags==8 and len(data)==18+width*height*4,file
print('PASS: modern and pixels role icons written as uncompressed power-of-two TGAs.')
