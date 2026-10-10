"""Report average colour and alpha of the visible pixels of icon textures.

Usage: scan_icon_brightness.py <file> [<file> ...]
"""
import sys
from PIL import Image

for path in sys.argv[1:]:
    img = Image.open(path).convert('RGBA')
    px = [p for p in img.getdata() if p[3] > 16]
    if not px:
        print(f'{path}: {img.size} no visible pixels')
        continue
    n = len(px)
    r, g, b, a = (sum(p[i] for p in px) / n for i in range(4))
    print(f'{path}: {img.size} mode={Image.open(path).mode} visible={n} avg rgb=({r:.0f},{g:.0f},{b:.0f}) alpha={a:.0f}')
