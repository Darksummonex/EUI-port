"""Generate the anti-aliased world map marker textures used by EUI_WorldMap_335.lua.

All textures share one 64x64 canvas so they can be layered with SetAllPoints:
shadow (black disc behind the flight icon), ring shadow (black, hollow) and ring (white,
tinted to the marker colour), so instance markers stay see-through in the middle.
"""
import math
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'EllesmereUIBlizzardSkin' / 'Media'
SIZE, SS = 64, 4
BIG = SIZE * SS


def smooth(edge0, edge1, x):
    t = min(1.0, max(0.0, (x - edge0) / (edge1 - edge0)))
    return t * t * (3 - 2 * t)


def render(alpha_fn, value_fn=lambda r, x, y: 1.0):
    img = Image.new('RGBA', (BIG, BIG))
    px = img.load()
    for j in range(BIG):
        y = (j + .5) / BIG * 2 - 1
        for i in range(BIG):
            x = (i + .5) / BIG * 2 - 1
            r = math.hypot(x, y)
            a = alpha_fn(r)
            if a > 0:
                v = int(255 * max(0.0, min(1.0, value_fn(r, x, y))))
                px[i, j] = (v, v, v, int(255 * a))
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def band(r, inner, outer):
    return 1.0 if inner <= r <= outer else 0.0


def save_tga(img, path):
    # Uncompressed 32-bit BGRA with a bottom-left origin, the layout the Wrath client reads reliably.
    w, h = img.size
    header = bytes([0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, w & 255, w >> 8, h & 255, h >> 8, 32, 8])
    data = bytearray()
    px = img.load()
    for j in range(h - 1, -1, -1):
        for i in range(w):
            r, g, b, a = px[i, j]
            data += bytes((b, g, r, a))
    path.write_bytes(header + bytes(data))


def flight_icon():
    """The client's winged boot as normalised white luminance so SetVertexColor gives a clean tint."""
    import io, sys
    sys.path.insert(0, str(ROOT / '.codex-tools'))
    import mpyq
    archive = ROOT.parents[1] / 'Data' / 'enUS' / 'locale-enUS.MPQ'
    data = mpyq.MPQArchive(str(archive), listfile=False).read_file('Interface\\Minimap\\Tracking\\FlightMaster.blp')
    src = Image.open(io.BytesIO(data)).convert('RGBA').resize((SIZE, SIZE), Image.LANCZOS)
    px = src.load()
    lum = [(.299 * r + .587 * g + .114 * b) / 255 for j in range(SIZE) for i in range(SIZE)
           for r, g, b, a in [px[i, j]] if a > 128]
    top = sorted(lum)[int(len(lum) * .97)]
    out = Image.new('RGBA', (SIZE, SIZE))
    dst = out.load()
    for j in range(SIZE):
        for i in range(SIZE):
            r, g, b, a = px[i, j]
            v = min(1.0, ((.299 * r + .587 * g + .114 * b) / 255 / top) ** .8)
            c = int(255 * v)
            dst[i, j] = (c, c, c, a)
    return out


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    shadow = render(lambda r: .85 * (1 - smooth(.55, 1.0, r)), lambda r, x, y: 0.0)
    ring_shadow = render(lambda r: .85 * smooth(.40, .48, r) * (1 - smooth(.74, .95, r)), lambda r, x, y: 0.0)
    ring = render(lambda r: band(r, .50, .70),
                  lambda r, x, y: .86 + .14 * max(0.0, -(x + y) * .7))
    for name, img in (('WorldMapMarkerShadow', shadow), ('WorldMapMarkerRingShadow', ring_shadow),
                      ('WorldMapMarkerRing', ring), ('WorldMapMarkerFlight', flight_icon())):
        save_tga(img, OUT / f'{name}.tga')
        print('wrote', OUT / f'{name}.tga')


if __name__ == '__main__':
    main()
