"""Extract the client's UI-GlyphFrame art and report the glyph sheet's opaque regions.

Read-only on the client archives; writes PNG copies into backport-tools/_glyph_art.
"""
from pathlib import Path
import io
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
import mpyq
from PIL import Image
import numpy as np

data = root.parents[1] / 'Data'
out = root / 'backport-tools' / '_glyph_art'
out.mkdir(exist_ok=True)
archives = ['zz-ptbr.mpq', 'ptBR/patch-ptBR-3.MPQ', 'ptBR/patch-ptBR-2.MPQ', 'ptBR/patch-ptBR.MPQ',
            'rebuffed-hd-wo.mpq', 'rebuffed-hd-it.mpq', 'rebuffed-hd-cr.mpq', 'rebuffed-hd-ch.mpq',
            'rebuffed.mpq', 'patch-6.MPQ', 'ptBR/locale-ptBR.MPQ', 'enUS/locale-enUS.MPQ', 'common.MPQ']
names = ['Interface\\Spellbook\\UI-GlyphFrame.blp', 'Interface\\Spellbook\\UI-GlyphFrame-Glow.blp']
for name in names:
    for rel in archives:
        path = data / rel
        if not path.exists():
            continue
        try:
            blob = mpyq.MPQArchive(str(path), listfile=False).read_file(name)
        except Exception as exc:
            print('ERR', rel, type(exc).__name__, exc)
            continue
        if not blob:
            continue
        img = Image.open(io.BytesIO(blob)).convert('RGBA')
        stem = name.split('\\')[-1].replace('.blp', '')
        img.save(out / (stem + '.png'))
        a = np.array(img)[:, :, 3]
        print('FOUND', name, 'in', rel, 'size', img.size)
        # Sheet area used by GlyphFrameBackground: 352x441 at texcoords 0..0.6875 x 0..0.8613.
        w, h = img.size
        sx, sy = w / 512, h / 512
        sheet = a[:int(441 * sy), :int(352 * sx)]
        ys, xs = np.nonzero(sheet > 16)
        print('  opaque bbox (in 512 units): x', xs.min() / sx, '-', xs.max() / sx, ' y', ys.min() / sy, '-', ys.max() / sy)
        # Row/column opacity profile to locate the inner body versus border/title chrome.
        for y in range(0, 441, 8):
            row = sheet[int(y * sy)]
            cols = np.nonzero(row > 16)[0]
            if len(cols):
                print('  row', y, 'opaque x', round(cols.min() / sx), '-', round(cols.max() / sx), 'count', len(cols))
            else:
                print('  row', y, 'transparent')
        break
    else:
        print('MISSING', name)
