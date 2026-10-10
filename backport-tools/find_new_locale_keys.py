"""Read-only: port UI keys that export_ptbr_keys.py would export today but that
are not in backport-tools/ptbr_work/keys.tsv yet, and which catalogs lack them.
Also lists keys.tsv entries the port no longer shows (stale).

Usage: python find_new_locale_keys.py [--out FILE]  (FILE gets <key> lines)
"""
import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import export_ptbr_keys as X
from build_ptbr_catalog import read_tsv
from check_locale_catalogs import entries

CODES = ['ptBR', 'deDE', 'frFR', 'ruRU', 'koKR', 'zhCN', 'zhTW', 'esES', 'esMX']


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out')
    args = ap.parse_args()
    known = set(read_tsv(X.WORK / 'keys.tsv').values())
    now = X.keys()
    new = [k for k in now if k not in known]
    stale = sorted(known - set(now))
    print('%d current keys, %d in keys.tsv, %d new, %d stale' % (len(now), len(known), len(new), len(stale)))
    cats = {c: entries(c) for c in CODES}
    for k in new:
        have = [c for c in CODES if k in cats[c]]
        print('NEW  %s%s' % (k, ('  [in: ' + ','.join(have) + ']') if have else ''))
    for k in stale:
        print('STALE %s' % k)
    if args.out:
        Path(args.out).write_text(''.join(k + '\n' for k in new), encoding='utf-8')


if __name__ == '__main__':
    sys.exit(main())
