"""Append port UI keys added since the last locale pass without renumbering.

New keys (find_new_locale_keys.py) get ids after the last one in
ptbr_work/keys.tsv. Writes the next ptbr_work/in_NN.tsv and, per Retail-based
catalog, the next locale_work/<code>/in_NN.tsv with the keys that catalog lacks.
Translations then go into the matching out_NN.tsv; rebuild with
build_ptbr_catalog.py and build_locale_additions.py.

Usage: python append_locale_keys.py [--check]
"""
import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import export_ptbr_keys as X
from build_ptbr_catalog import read_tsv
from check_locale_catalogs import entries

CODES = ['deDE', 'frFR', 'ruRU', 'koKR', 'zhCN', 'zhTW', 'esES']
# Language names stay in their own language.
SKIP = {'Portugu\u00eas (Brasil)'}


def next_number(folder):
    nums = [int(p.stem[3:]) for p in folder.glob('in_*.tsv')]
    return max(nums) + 1 if nums else 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    ap.add_argument('--patch-notes', action='store_true', help='also the What\'s New prose (patch_note_strings.py)')
    ap.add_argument('--batch', type=int, default=300)
    args = ap.parse_args()
    keys_path = X.WORK / 'keys.tsv'
    keys = read_tsv(keys_path)
    known = set(keys.values())
    wanted = X.keys()
    if args.patch_notes:
        import patch_note_strings
        wanted = wanted + patch_note_strings.strings()[0]
    new, seen = [], set()
    for k in wanted:
        if k not in known and k not in SKIP and k not in seen:
            seen.add(k)
            new.append(k)
    start = max(keys) + 1
    rows = [(start + n, k) for n, k in enumerate(new)]
    print('appending %d keys as ids %d-%d' % (len(rows), start, start + len(rows) - 1))
    if not rows:
        return
    folders = {'ptBR': (X.WORK, rows)}
    for code in CODES:
        cat = entries(code)
        folders[code] = (X.S.ROOT / 'backport-tools' / 'locale_work' / code, [r for r in rows if r[1] not in cat])
    files = []
    for code, (folder, todo) in folders.items():
        first = next_number(folder)
        chunks = [todo[i:i + args.batch] for i in range(0, len(todo), args.batch)]
        for n, chunk in enumerate(chunks):
            files.append((folder / ('in_%02d.tsv' % (first + n)), chunk))
        print('%s: %d keys -> in_%02d..in_%02d' % (code, len(todo), first, first + len(chunks) - 1))
    if args.check:
        return
    raw = keys_path.read_bytes()
    nl = b'\r\n' if b'\r\n' in raw else b'\n'
    tail = b'' if raw.endswith(nl) else nl
    keys_path.write_bytes(raw + tail + b''.join(('%d\t%s' % r).encode('utf-8') + nl for r in rows))
    for path, chunk in files:
        path.write_text(''.join('%d\t%s\n' % r for r in chunk), encoding='utf-8')


if __name__ == '__main__':
    sys.exit(main())
