"""Unified diff of stock 3.3.5 vs Rebuffed world map FrameXML (reference only)."""
from pathlib import Path
import difflib, sys
d = Path(__file__).resolve().parent / 'framexml-worldmap'
a = sys.argv[1] if len(sys.argv) > 1 else 'enUS_patch-enUS-3.MPQ__WorldMapFrame.lua'
b = sys.argv[2] if len(sys.argv) > 2 else 'rebuffed.mpq__WorldMapFrame.lua'
x = (d / a).read_text(encoding='utf-8', errors='replace').splitlines()
y = (d / b).read_text(encoding='utf-8', errors='replace').splitlines()
for line in difflib.unified_diff(x, y, a, b, n=4, lineterm=''):
    print(line)
