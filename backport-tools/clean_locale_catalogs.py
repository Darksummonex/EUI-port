"""Remove EllesmereUILocales catalog entries the 3.3.5 port never shows.

Drops keys that only Retail uses and keys no addon uses, as found by
scan_locale_coverage.py. Kept on purpose:
  - keys used verbatim by the port's loaded Lua;
  - near matches of port text (reworded keys, recoverable by matching the text);
  - keys the port can build at runtime: a port label plus a short tail
    ("Trinket Slot " .. 1).
Game names (classes, zones, professions) come from the client already localized,
so their Retail keys only mattered for the language override and are dropped.
Only whole single-line `L["key"] = value` statements are removed; every kept
line stays byte-identical to the Retail catalog. Empty section headers go too.

Usage: python clean_locale_catalogs.py [--dry-run]
"""
import argparse
import difflib
import re
import shutil
import sys
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import scan_locale_coverage as S

ROOT = S.ROOT
ENTRY = re.compile(r'^\s*L\["((?:[^"\\]|\\.)*)"\]\s*=\s*(?:"(?:[^"\\]|\\.)*"|true)\s*;?\s*(?:--.*)?$')
HEADER = re.compile(r'^\s*--\s*==')
TAIL = re.compile(r'^[\w%$.\-]{1,12}\)?$')


def keep_set(keys, port):
    port_ui = [s for s in port if S.ui_like(s)]
    port_lower = {s.lower(): s for s in port_ui}
    prefixes = {s for s in port_ui if len(s) >= 4 and s[-1] in ' :(-'}
    keep, why = set(), {'used': 0, 'reworded': 0, 'runtime prefix': 0}
    for k in keys:
        reason = None
        if k in port:
            reason = 'used'
        elif any(k.startswith(p) and TAIL.match(k[len(p):]) for p in prefixes if len(p) < len(k)):
            reason = 'runtime prefix'
        elif k.lower() in port_lower or (6 <= len(k) <= 120 and difflib.get_close_matches(k, port_ui, n=1, cutoff=0.88)):
            reason = 'reworded'
        if reason:
            keep.add(k)
            why[reason] += 1
    return keep, why


def clean(text, keep):
    lines = text.splitlines(keepends=True)
    out, removed, multiline = [], 0, 0
    for line in lines:
        body = line.rstrip('\r\n')
        m = ENTRY.match(body)
        if m:
            if m.group(1) not in keep:
                removed += 1
                continue
        elif re.match(r'^\s*L\["', body):
            multiline += 1
        out.append(line)
    # Drop section headers (and the blank line before them) that no longer head any entry.
    final = []
    for i, line in enumerate(out):
        if HEADER.match(line):
            j = i + 1
            while j < len(out) and not out[j].strip():
                j += 1
            if j >= len(out) or HEADER.match(out[j]):
                if final and not final[-1].strip():
                    final.pop()
                continue
        final.append(line)
    return ''.join(final), removed, multiline


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dry-run', action='store_true')
    args = ap.parse_args()

    keys = S.catalog()
    port = S.collect(ROOT)
    keep, why = keep_set(keys, port)
    print('Catalog keys %d, keeping %d (%s), removing %d' % (
        len(keys), len(keep), ', '.join('%s %d' % kv for kv in why.items()), len(keys) - len(keep)))

    folder = ROOT / 'EllesmereUILocales'
    if not args.dry_run:
        stamp = datetime.now().strftime('%Y%m%d-%H%M%S')
        backup = ROOT / '.codex-backups' / ('locales-before-clean-' + stamp)
        backup.mkdir(parents=True)
        for code in S.CODES:
            shutil.copy2(folder / (code + '.lua'), backup / (code + '.lua'))
        print('Backup: ' + str(backup))
    for code in S.CODES:
        path = folder / (code + '.lua')
        raw = path.read_bytes()
        text = raw.decode('utf-8', errors='surrogateescape')
        new, removed, multiline = clean(text, keep)
        data = new.encode('utf-8', errors='surrogateescape')
        print('%s: removed %d entries, %d -> %d KB%s' % (
            code, removed, len(raw) // 1024, len(data) // 1024,
            ', %d multi-line entries left untouched' % multiline if multiline else ''))
        if not args.dry_run:
            path.write_bytes(data)


if __name__ == '__main__':
    sys.exit(main())
