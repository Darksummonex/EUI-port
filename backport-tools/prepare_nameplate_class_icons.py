"""Build the Wrath TGA marks for the Nameplates Rare/Quest Indicator.

Retail draws them from atlases (nameplates-icon-elite-gold/-silver,
nameplates-icon-rareelite) that 3.3.5 does not have, so these are drawn here:
gold star = elite, silver star = rare elite, silver diamond = rare.
The quest mark reuses the client's Interface\\GossipFrame\\AvailableQuestIcon.
"""
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

root = Path(__file__).resolve().parents[1]
dst = root / 'EllesmereUINameplates' / 'Media_335'
FOOTER = b'TRUEVISION-XFILE.\x00'
SS = 8
SIZE = 64
BIG = SIZE * SS


def save(img, out):
    """Plain 18-byte header + pixels (no TGA 2.0 footer), like the other Wrath media."""
    img.save(out, compression=None)
    data = out.read_bytes()
    if data.endswith(FOOTER):
        out.write_bytes(data[:-26])
    print('wrote', out.relative_to(root))


def star(cx, cy, outer, inner, points=5):
    pts = []
    for i in range(points * 2):
        r = outer if i % 2 == 0 else inner
        a = -math.pi / 2 + i * math.pi / points
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def diamond(cx, cy, rx, ry):
    return [(cx, cy - ry), (cx + rx, cy), (cx, cy + ry), (cx - rx, cy)]


def mask(poly):
    m = Image.new('L', (BIG, BIG), 0)
    ImageDraw.Draw(m).polygon(poly, fill=255)
    return m


def mark(outline_poly, fill_poly, top, bottom):
    edge = mask(outline_poly)
    body = mask(fill_poly)
    img = Image.new('RGBA', (BIG, BIG), (0, 0, 0, 0))
    img.paste((12, 10, 8, 255), (0, 0), edge)
    grad = Image.new('RGBA', (BIG, BIG))
    px = grad.load()
    for y in range(BIG):
        t = y / (BIG - 1)
        c = tuple(round(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,)
        for x in range(BIG):
            px[x, y] = c
    img.paste(grad, (0, 0), body)
    shine = Image.new('L', (BIG, BIG), 0)
    ImageDraw.Draw(shine).ellipse((BIG * .2, BIG * .02, BIG * .8, BIG * .42), fill=70)
    shine = Image.composite(shine, Image.new('L', (BIG, BIG), 0), body).filter(ImageFilter.GaussianBlur(SS * 2))
    img.paste((255, 255, 255, 255), (0, 0), shine)
    alpha = img.getchannel('A')
    img.putalpha(Image.composite(alpha, Image.new('L', (BIG, BIG), 0), edge))
    out = img.resize((SIZE, SIZE), Image.LANCZOS)
    out.info.clear()
    return out


c = BIG / 2
GOLD = ((255, 232, 120), (196, 128, 18))
SILVER = ((246, 248, 252), (128, 136, 150))
star_edge = star(c, c + BIG * .03, BIG * .49, BIG * .22)
star_body = star(c, c + BIG * .03, BIG * .40, BIG * .175)
dia_edge = diamond(c, c, BIG * .38, BIG * .49)
dia_body = diamond(c, c, BIG * .29, BIG * .39)

save(mark(star_edge, star_body, *GOLD), dst / 'class-elite.tga')
save(mark(star_edge, star_body, *SILVER), dst / 'class-rareelite.tga')
save(mark(dia_edge, dia_body, *SILVER), dst / 'class-rare.tga')
