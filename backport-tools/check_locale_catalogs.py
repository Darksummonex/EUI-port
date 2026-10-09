"""Coverage and sanity report for every EllesmereUILocales catalog (read only).

Coverage is measured against backport-tools/ptbr_work/keys.tsv (the port's UI
text). Each entry is checked like build_ptbr_catalog.py does: format
placeholders, |c/|r/|T markup, \\n escapes. Writes %TEMP%/eui_locale_check.txt
and the missing keys per locale to backport-tools/locale_work/missing_<code>.tsv.
"""
import os
import re
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'backport-tools'))
from build_ptbr_catalog import spec_ok, markup, read_tsv

CODES = ['deDE', 'esES', 'esMX', 'frFR', 'koKR', 'ruRU', 'zhCN', 'zhTW', 'ptBR']
ENTRY = re.compile(r'^L\["((?:[^"\\]|\\.)*)"\]\s*=\s*(?:"((?:[^"\\]|\\.)*)"|(true))\s*$')


def entries(code):
    out = {}
    for line in (ROOT / 'EllesmereUILocales' / (code + '.lua')).read_text(encoding='utf-8-sig').splitlines():
        m = ENTRY.match(line.strip())
        if m:
            out[m.group(1)] = m.group(2) if m.group(2) is not None else m.group(1)
    return out


def main():
    keys = read_tsv(ROOT / 'backport-tools' / 'ptbr_work' / 'keys.tsv')
    work = ROOT / 'backport-tools' / 'locale_work'
    work.mkdir(exist_ok=True)
    lines = []
    for code in CODES:
        cat = entries(code)
        have = [i for i, k in keys.items() if k in cat]
        bad = []
        for k, v in cat.items():
            why = []
            if not spec_ok(k, v):
                why.append('placeholders')
            if markup(k) != markup(v):
                why.append('markup')
            if why:
                bad.append((','.join(why), k, v))
        missing = [(i, k) for i, k in sorted(keys.items()) if k not in cat]
        lines.append('%s: %d entries, covers %d/%d port keys, missing %d, suspicious %d' % (
            code, len(cat), len(have), len(keys), len(missing), len(bad)))
        for why, k, v in bad:
            lines.append('   [%s] %r -> %r' % (why, k, v))
        if code != 'ptBR':
            (work / ('missing_%s.tsv' % code)).write_text(
                ''.join('%d\t%s\n' % (i, k) for i, k in missing), encoding='utf-8')
    report = Path(tempfile.gettempdir()) / 'eui_locale_check.txt'
    report.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    for l in lines:
        if not l.startswith('   '):
            print(l)
    print('report:', report)


if __name__ == '__main__':
    main()
