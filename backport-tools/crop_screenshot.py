"""Crop and upscale part of a screenshot for inspection.

Usage: python crop_screenshot.py <image> <left> <top> <right> <bottom> [scale]
Writes %TEMP%/eui_crop.png.
"""
import os
import sys
import tempfile
from PIL import Image

path, l, t, r, b = sys.argv[1], *map(int, sys.argv[2:6])
scale = int(sys.argv[6]) if len(sys.argv) > 6 else 4
img = Image.open(path).crop((l, t, r, b))
img = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
out = os.path.join(tempfile.gettempdir(), 'eui_crop.png')
img.save(out)
print(out)
