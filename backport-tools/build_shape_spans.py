"""Print the Lua row spans used to crop action button icons into the EUI
diamond, hexagon and shield shapes (Wrath has no mask textures), plus the
largest rectangle inside each shape for the cooldown swipe. Reference only:
the output is pasted into EUI_ActionBars_335.lua, nothing is written."""
from pathlib import Path
here = Path(__file__).resolve().parent
source = (here / 'measure_shape_borders.py').read_text().split("\nfor shape in", 1)[0]
measure = {'__file__': str(here / 'measure_shape_borders.py')}
exec(compile(source, 'measure_shape_borders.py', 'exec'), measure)
load, media = measure['load'], measure['media']

OPEN = {'diamond': 114, 'hexagon': 126, 'shield': 118}
ROWS = 64
THRESHOLD = 128

for shape, opening in OPEN.items():
    w, h, rows = load(media / ('%s_mask.tga' % shape))
    start = (128 - opening) / 2
    spans = []
    for k in range(ROWS):
        y = int(start + (k + .5) * opening / ROWS)
        line = rows[y]
        lit = [x for x, a in enumerate(line) if a >= THRESHOLD]
        if not lit:
            spans.append((0.0, 0.0)); continue
        left = max(0.0, (lit[0] - start) / opening)
        right = min(1.0, (lit[-1] + 1 - start) / opening)
        spans.append((round(left, 3), round(right, 3)))
    best = (0, 0, 0, 0, 0)
    for a in range(ROWS):
        lo, hi = 0.0, 1.0
        for b in range(a, ROWS):
            lo, hi = max(lo, spans[b][0]), min(hi, spans[b][1])
            if hi <= lo:
                break
            area = (hi - lo) * (b + 1 - a) / ROWS
            if area > best[0]:
                best = (area, lo, a / ROWS, hi, (b + 1) / ROWS)
    flat = ','.join('%g,%g' % s for s in spans)
    print('%s={%s},' % (shape, flat))
    print('-- %s swipe rect l,t,r,b = %.3f,%.3f,%.3f,%.3f' % ((shape,) + tuple(best[1:])))
    for k in range(0, ROWS, 4):
        l, r = spans[k]
        print('   |' + ''.join('#' if l <= (i + .5) / 32 < r else '.' for i in range(32)) + '|')
