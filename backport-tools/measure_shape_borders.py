"""Print where each EUI shape border ring and mask opening sit along the centre
row and column of their 128px TGAs (reference only, nothing is written)."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
media = root / 'EllesmereUI' / 'media' / 'portraits'


def load(path):
    data = path.read_bytes()
    idlen, cmap, kind = data[0], data[1], data[2]
    w, h = data[12] | data[13] << 8, data[14] | data[15] << 8
    depth, desc = data[16], data[17]
    assert cmap == 0 and kind in (2, 10) and depth in (24, 32), (path.name, kind, depth)
    bpp = depth // 8
    pos = 18 + idlen
    pixels = []
    if kind == 2:
        raw = data[pos:pos + w * h * bpp]
        pixels = [raw[i:i + bpp] for i in range(0, len(raw), bpp)]
    else:
        while len(pixels) < w * h:
            head = data[pos]; pos += 1
            count = (head & 0x7f) + 1
            if head & 0x80:
                px = data[pos:pos + bpp]; pos += bpp
                pixels.extend([px] * count)
            else:
                for _ in range(count):
                    pixels.append(data[pos:pos + bpp]); pos += bpp
    alpha = [p[3] if bpp == 4 else 255 for p in pixels]
    top = bool(desc & 0x20)
    rows = [alpha[r * w:(r + 1) * w] for r in range(h)]
    if not top:
        rows.reverse()
    return w, h, rows


def spans(line, threshold=40):
    out, start = [], None
    for i, a in enumerate(line):
        if a >= threshold and start is None:
            start = i
        elif a < threshold and start is not None:
            out.append((start, i - 1)); start = None
    if start is not None:
        out.append((start, len(line) - 1))
    return out


for shape in ['circle', 'portrait', 'csquare', 'diamond', 'hexagon', 'shield', 'square']:
    for kind in ['border', 'mask']:
        path = media / ('%s_%s.tga' % (shape, kind))
        if not path.exists():
            print(shape, kind, 'missing'); continue
        w, h, rows = load(path)
        row = rows[h // 2]
        col = [rows[r][w // 2] for r in range(h)]
        print('%-8s %-6s %dx%d row %s col %s' % (shape, kind, w, h, spans(row), spans(col)))
