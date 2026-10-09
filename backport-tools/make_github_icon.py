"""Rasterize the Octicons GitHub mark (MIT) to EllesmereUI/media/icons/github.png.

White on transparent, 64x64, like the other footer social icons. The single small
arc in the path is approximated by a straight segment.
"""
import re
from pathlib import Path
from PIL import Image, ImageDraw

PATH = ("M10.226 17.284c-2.965-.36-5.054-2.493-5.054-5.256 0-1.123.404-2.336 1.078-3.144-.292-.741-.247-2.314.09-2.965"
        ".898-.112 2.111.36 2.83 1.01.853-.269 1.752-.404 2.853-.404 1.1 0 1.999.135 2.807.382.696-.629 1.932-1.1 2.83-.988"
        ".315.606.36 2.179.067 2.942.72.854 1.101 2 1.101 3.167 0 2.763-2.089 4.852-5.098 5.234.763.494 1.28 1.572 1.28 2.807"
        "v2.336c0 .674.561 1.056 1.235.786 4.066-1.55 7.255-5.615 7.255-10.646C23.5 6.188 18.334 1 11.978 1 5.62 1 .5 6.188"
        ".5 12.545c0 4.986 3.167 9.12 7.435 10.669.606.225 1.19-.18 1.19-.786V20.63a2.9 2.9 0 0 1-1.078.224c-1.483 0-2.359-.808"
        "-2.987-2.313-.247-.607-.517-.966-1.034-1.033-.27-.023-.359-.135-.359-.27 0-.27.45-.471.898-.471.652 0 1.213.404"
        " 1.797 1.235.45.651.921.943 1.483.943.561 0 .92-.202 1.437-.719.382-.381.674-.718.944-.943")
SIZE, SS = 64, 8

def tokens(d):
    return re.findall(r"[A-Za-z]|-?(?:\d+\.\d*|\.\d+|\d+)(?:e-?\d+)?", d)

def flatten(d):
    toks, i, cmd = tokens(d), 0, None
    x = y = 0.0
    pts = []
    def num():
        nonlocal i
        v = float(toks[i]); i += 1; return v
    def cubic(p0, p1, p2, p3):
        for k in range(1, 17):
            t = k / 16; u = 1 - t
            pts.append((u**3*p0[0] + 3*u*u*t*p1[0] + 3*u*t*t*p2[0] + t**3*p3[0],
                        u**3*p0[1] + 3*u*u*t*p1[1] + 3*u*t*t*p2[1] + t**3*p3[1]))
    while i < len(toks):
        if toks[i].isalpha():
            cmd = toks[i]; i += 1
            if cmd in "zZ":
                continue
        rel = cmd.islower(); c = cmd.upper()
        ox, oy = (x, y) if rel else (0.0, 0.0)
        if c == "M":
            x, y = ox + num(), oy + num(); pts.append((x, y)); cmd = "l" if rel else "L"
        elif c == "L":
            x, y = ox + num(), oy + num(); pts.append((x, y))
        elif c == "H":
            x = ox + num(); pts.append((x, y))
        elif c == "V":
            y = oy + num(); pts.append((x, y))
        elif c == "C":
            p1 = (ox + num(), oy + num()); p2 = (ox + num(), oy + num()); p3 = (ox + num(), oy + num())
            cubic((x, y), p1, p2, p3); x, y = p3
        elif c == "A":
            for _ in range(5):
                num()
            x, y = ox + num(), oy + num(); pts.append((x, y))
        else:
            raise ValueError(cmd)
    return pts

def main():
    big = SIZE * SS
    pad = 1.5
    scale = (SIZE - 2 * pad) * SS / 23.0
    pts = [((px - 0.5) * scale + pad * SS, (py - 0.5) * scale + pad * SS) for px, py in flatten(PATH)]
    mask = Image.new("L", (big, big), 0)
    ImageDraw.Draw(mask).polygon(pts, fill=255)
    mask = mask.resize((SIZE, SIZE), Image.LANCZOS)
    img = Image.new("RGBA", (SIZE, SIZE), (255, 255, 255, 0))
    img.putalpha(mask)
    out = Path(__file__).resolve().parent.parent / "EllesmereUI" / "media" / "icons" / "github.png"
    img.save(out)
    print(out, img.size)
    import os, tempfile
    preview = Image.new("RGBA", (SIZE * 4, SIZE * 4), (20, 24, 30, 255))
    preview.alpha_composite(img.resize((SIZE * 4, SIZE * 4), Image.NEAREST))
    pv = os.path.join(tempfile.gettempdir(), "eui_github_preview.png")
    preview.save(pv)
    print(pv)

if __name__ == "__main__":
    main()
