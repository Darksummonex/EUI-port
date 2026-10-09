"""Export the port UI keys each Retail-based catalog is missing, in translation batches.

Keys come from backport-tools/ptbr_work/keys.tsv. Keys the pt-BR pass kept in
English (names, abbreviations, fonts) are skipped. esMX shares the esES batches
(build_locale_additions.py writes the same text to both). Output:
backport-tools/locale_work/<code>/in_NN.tsv (<id>\\t<raw Lua-escaped key>).
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'backport-tools'))
from build_ptbr_catalog import read_tsv
from check_locale_catalogs import entries

CODES = ['deDE', 'frFR', 'ruRU', 'koKR', 'zhCN', 'zhTW', 'esES']
BATCH = 450


def main():
    work = ROOT / 'backport-tools' / 'ptbr_work'
    keys = read_tsv(work / 'keys.tsv')
    pt = {}
    for p in sorted(work.glob('out_*.tsv')):
        pt.update(read_tsv(p))
    keep_english = {i for i, k in keys.items() if pt.get(i) == k}
    total = 0
    for code in CODES:
        cat = entries(code)
        todo = [(i, k) for i, k in sorted(keys.items()) if k not in cat and i not in keep_english]
        out = ROOT / 'backport-tools' / 'locale_work' / code
        out.mkdir(parents=True, exist_ok=True)
        for n in range(0, len(todo), BATCH):
            chunk = todo[n:n + BATCH]
            (out / ('in_%02d.tsv' % (n // BATCH))).write_text(
                ''.join('%d\t%s\n' % (i, k) for i, k in chunk), encoding='utf-8')
        print('%s: %d keys, %d batches' % (code, len(todo), (len(todo) + BATCH - 1) // BATCH))
        total += len(todo)
    print('total', total)


if __name__ == '__main__':
    main()
