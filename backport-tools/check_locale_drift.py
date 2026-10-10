"""Read-only: how far the project's trimmed locale catalogs (text above the port
MARKER) drift from the current Retail catalogs. Counts base lines missing from
Retail (as a set and as an ordered subsequence)."""
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
RETAIL = pathlib.Path('D:/World of Warcraft/_retail_/Interface/AddOns/EllesmereUILocales')
MARKER = b'-- == 3.3.5 port additions (backport-tools/build_locale_additions.py) =='

for code in ('deDE', 'esES', 'esMX', 'frFR', 'koKR', 'ruRU', 'zhCN', 'zhTW'):
    ours = [l for l in (ROOT / 'EllesmereUILocales' / (code + '.lua')).read_bytes().split(MARKER, 1)[0].splitlines() if l.strip()]
    theirs = (RETAIL / (code + '.lua')).read_bytes().splitlines()
    have = set(theirs)
    missing = [l for l in ours if l not in have]
    print('%s: %d base lines, %d not in Retail 9.4' % (code, len(ours), len(missing)))
    for l in missing[:3]:
        print('    ', l.decode('utf-8', 'replace')[:110])
