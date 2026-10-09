"""Check native badge art, alpha and the compiled panel entry point."""
from pathlib import Path
import sys
import re
from PIL import Image
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime
lua = LuaRuntime(unpack_returned_tuples=True)
panel = (root / 'EllesmereUI/EllesmereUI_Panel.lua').read_text(encoding='utf-8-sig')
lua.execute('assert(loadstring(...))', panel)
core = (root / 'EllesmereUI/EllesmereUI.lua').read_text(encoding='utf-8-sig')
names = set(re.findall(r'\["backgrounds\\\\([^"\\]+)\.png"\]\s*=\s*\{[^}]*\bex\s*=', core))
assert len(names) == 9, names
for name in sorted(names | {'ring', 'pixels-accent'}):
    image = Image.open(root / 'EllesmereUI/media/mini_335' / (name + '.tga')).convert('RGBA')
    assert image.size == (128, 128), name
    alpha = image.getchannel('A')
    assert all(alpha.getpixel(point) == 0 for point in [(0,0), (127,0), (0,127), (127,127)]), name
    assert alpha.getextrema()[1] > 0, name
    if name != 'pixels-accent':
        assert alpha.getpixel((64,64)) == 255, name
close = Image.open(root / 'EllesmereUI/media/icons_335/close-popup-4.tga').convert('RGBA')
assert close.getchannel('A').getextrema()[1] > 0
print('PASS: Lua 5.1 panel compilation; all nine theme badges, ring and accent have native circular alpha; close glyph exists')
