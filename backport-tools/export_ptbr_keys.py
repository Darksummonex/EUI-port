"""Export the English UI text the port can show, for the pt-BR catalog.

Keys = catalog keys the port uses verbatim + port UI labels with no catalog
entry (scan_locale_coverage.py), minus patch-notes prose. Writes numbered
batches `<id>\\t<raw Lua-escaped key>` to backport-tools/ptbr_work/in_NN.tsv,
skipping ids already translated in out_NN.tsv files.

Usage: python export_ptbr_keys.py [--batch 350]
"""
import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import scan_locale_coverage as S

WORK = S.ROOT / 'backport-tools' / 'ptbr_work'


def keys():
    catalog = S.catalog()
    port = S.collect(S.ROOT)
    out = set(k for k in catalog if k in port)
    for s, files in port.items():
        if s in catalog or not S.ui_like(s):
            continue
        ui = [f for f in files if S.UI_FILES.search(f)]
        if not ui:
            continue
        if all(f.endswith('EUI__General_Options.lua') for f in ui) and len(s) > 40:
            continue  # patch notes prose
        if re.fullmatch(r'[A-Z][\w ]* \d+\.\d+', s):
            continue  # "Raid Frames 0.18" version tags
        out.add(s)
    return sorted(out, key=lambda s: (s.lower(), s))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--batch', type=int, default=350)
    args = ap.parse_args()
    WORK.mkdir(exist_ok=True)
    all_keys = keys()
    (WORK / 'keys.tsv').write_text(''.join('%d\t%s\n' % (i, k) for i, k in enumerate(all_keys)), encoding='utf-8')
    for old in WORK.glob('in_*.tsv'):
        old.unlink()
    batches = [all_keys[i:i + args.batch] for i in range(0, len(all_keys), args.batch)]
    start = 0
    for n, batch in enumerate(batches):
        lines = ''.join('%d\t%s\n' % (start + i, k) for i, k in enumerate(batch))
        (WORK / ('in_%02d.tsv' % n)).write_text(lines, encoding='utf-8')
        start += len(batch)
    print('%d keys in %d batches -> %s' % (len(all_keys), len(batches), WORK))


if __name__ == '__main__':
    sys.exit(main())
