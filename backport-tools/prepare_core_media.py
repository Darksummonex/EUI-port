"""Build the Wrath textures for core Party Mode and Video Guides.

Wrath cannot read PNG. The Video Guides play glyph is power-of-two and is
written as uncompressed 32-bit TGA at its original size.

Party Mode beams: Retail rotates three stacked quads per beam (outer 5x,
mid 2.5x, core 1x width; alpha 0.25 / 0.50 / 0.35) with Texture:SetRotation.
3.3.5 cannot rotate a quad, so each beam is one large square whose texture
coordinates are rotated instead. With additive blending the three layers sum
linearly, so their cross-section is baked into one profile (normalised by its
peak, 1.1, which the Lua side multiplies back into the vertex alpha). The
profile spans the middle 64 of 2048 columns: for every beam the rotated
coordinates stay inside 0..1 across the whole square, so edge clamping or
wrapping never shows. The Retail PNG files stay untouched.
"""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
media = root / 'EllesmereUI' / 'media'

play_src = media / 'icons' / 'play.png'
play_out = media / 'icons_335' / 'play.tga'
play_out.parent.mkdir(exist_ok=True)
img = Image.open(play_src).convert('RGBA')
w, h = img.size
assert w & (w - 1) == 0 and h & (h - 1) == 0
img.save(play_out, compression=None)
print('wrote', play_out.relative_to(root))

party = Image.open(media / 'party.png').convert('RGBA')
pw, ph = party.size
row = [party.getpixel((x, ph // 2))[3] / 255.0 for x in range(pw)]


def profile(s):
    """Retail beam alpha at s in [-0.5, 0.5] across the quad, 0 outside."""
    if s < -0.5 or s > 0.5:
        return 0.0
    x = (s + 0.5) * (pw - 1)
    i = int(x)
    j = min(i + 1, pw - 1)
    f = x - i
    return row[i] * (1 - f) + row[j] * f


LAYERS = ((1.0, 0.25), (0.5, 0.50), (0.2, 0.35))  # width relative to outer, alpha
PEAK = 1.1
TEX_W, TEX_H, CONTENT = 2048, 8, 64
beam = Image.new('RGBA', (TEX_W, TEX_H), (255, 255, 255, 0))
left = (TEX_W - CONTENT) // 2
for c in range(CONTENT):
    t = (c + 0.5) / CONTENT - 0.5
    a = sum(am * profile(t / wf) for wf, am in LAYERS) / PEAK
    v = max(0, min(255, round(a * 255)))
    for y in range(TEX_H):
        beam.putpixel((left + c, y), (255, 255, 255, v))
beam_out = media / 'backgrounds_335' / 'party_beam.tga'
beam_out.parent.mkdir(exist_ok=True)
beam.save(beam_out, compression=None)
print('wrote', beam_out.relative_to(root))
