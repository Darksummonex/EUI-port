"""Append the port's own translations to the Retail-based EllesmereUILocales catalogs.

Reads backport-tools/locale_work/<code>/in_*.tsv + out_*.tsv (written from
export_locale_batches.py), checks each line like build_ptbr_catalog.py
(placeholders, markup, escapes, edge spaces, Lua syntax), drops lines equal to
the English key, and rewrites everything after MARKER at the end of the catalog.
Lines above MARKER stay byte-identical to Retail (validate_locales.py checks it).
esMX reuses the esES translations. FIXES override broken Retail entries.

Usage: python build_locale_additions.py [--check]
"""
import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'backport-tools'))
sys.path.insert(0, str(ROOT / '.codex-tools'))
from build_ptbr_catalog import spec_ok, markup, bare_quote, read_tsv
from check_locale_catalogs import ENTRY
from lupa.lua51 import LuaRuntime

MARKER = '-- == 3.3.5 port additions (backport-tools/build_locale_additions.py) =='
SOURCES = {'deDE': 'deDE', 'frFR': 'frFR', 'ruRU': 'ruRU', 'koKR': 'koKR',
           'zhCN': 'zhCN', 'zhTW': 'zhTW', 'esES': 'esES', 'esMX': 'esES'}
# Retail entries that break at runtime; written after the additions so they win.
FIXES = {
    # Retail dropped the middle %s (plural suffix), so the trainer name became "s".
    'deDE': {'Learn %d skill%s for %s': 'Lerne %1$d Fertigkeit(en) für %3$s'},
}


def problems(en, tr, compiles):
    why = []
    if not spec_ok(en, tr):
        why.append('placeholders')
    if markup(en) != markup(tr):
        why.append('markup')
    if bare_quote(tr) or '\t' in tr:
        why.append('quote/escape')
    if (en[:1] == ' ' and tr[:1] != ' ') or (en[-1:] == ' ') != (tr[-1:] == ' '):
        why.append('edge spaces')
    if not why and not compiles('L["%s"] = "%s"' % (en, tr)):
        why.append('lua')
    return why


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    args = ap.parse_args()
    compiles = LuaRuntime().eval('function(s) return loadstring(s) ~= nil end')
    work = ROOT / 'backport-tools' / 'locale_work'
    for code, src in SOURCES.items():
        keys, trans = {}, {}
        for p in sorted((work / src).glob('in_*.tsv')):
            keys.update(read_tsv(p))
        for p in sorted((work / src).glob('out_*.tsv')):
            trans.update(read_tsv(p))
        path = ROOT / 'EllesmereUILocales' / (code + '.lua')
        raw = path.read_bytes()
        text = raw.decode('utf-8-sig')
        base = text.split('\r\n' + MARKER, 1)[0].split('\n' + MARKER, 1)[0]
        have = {m.group(1) for m in (ENTRY.match(l.strip()) for l in base.splitlines()) if m}
        added, rejected, same, missing = [], [], 0, 0
        for i, en in sorted(keys.items()):
            if en in have:
                continue
            tr = trans.get(i)
            if tr is None:
                missing += 1
                continue
            if tr == en:
                same += 1
                continue
            why = problems(en, tr, compiles)
            if why:
                rejected.append((i, ','.join(why), en, tr))
                continue
            added.append('L["%s"] = "%s"' % (en, tr))
        fixes = ['L["%s"] = "%s"' % kv for kv in FIXES.get(code, {}).items()]
        print('%s: added %d, kept English %d, rejected %d, not translated yet %d, fixes %d' % (
            code, len(added), same, len(rejected), missing, len(fixes)))
        for i, why, en, tr in rejected:
            print('   %d [%s] %r -> %r' % (i, why, en, tr))
        if args.check:
            continue
        nl = '\r\n' if '\r\n' in base else '\n'
        body = base.rstrip('\r\n') + nl + nl + MARKER + nl
        body += '-- Port UI text missing from the Retail catalog; Retail lines above are unchanged.' + nl
        body += nl.join(added + fixes) + nl
        out = body.encode('utf-8')
        if raw.startswith(b'\xef\xbb\xbf'):
            out = b'\xef\xbb\xbf' + out
        path.write_bytes(out)


if __name__ == '__main__':
    main()
