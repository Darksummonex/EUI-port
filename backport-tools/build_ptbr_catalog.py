"""Assemble EllesmereUILocales/ptBR.lua from backport-tools/ptbr_work.

Reads keys.tsv (id -> English key) and out_*.tsv (id -> pt-BR), checks every
translation (format placeholders, |c/|r/|T markup, \\n escapes, quotes, Lua 5.1
syntax), drops entries equal to the English key, and writes the catalog (UTF-8
without BOM, CRLF like the other catalogs). Rejected entries are listed and left
out (they fall back to English).

Usage: python build_ptbr_catalog.py [--check]
"""
import argparse
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORK = ROOT / 'backport-tools' / 'ptbr_work'
OUT = ROOT / 'EllesmereUILocales' / 'ptBR.lua'
sys.path.insert(0, str(ROOT / '.codex-tools'))
from lupa.lua51 import LuaRuntime

SPEC = re.compile(r'%(?:(\d+)\$)?[-+#0]*\d*(?:\.\d+)?([cdiouxXeEfgGqs])|%%')


def specs(s):
    out = Counter()
    for m in SPEC.finditer(s):
        if m.group(0) == '%%':
            out['%%'] += 1
        else:
            out[(m.group(1) or '?', m.group(2))] += 1
    return out


def spec_ok(en, pt):
    a, b = specs(en), specs(pt)
    if a == b:
        return True
    # Plain %s/%d in English may become positional %1$s/%2$d in pt-BR.
    seq = [m for m in SPEC.finditer(en) if m.group(0) != '%%']
    if a['%%'] != b['%%'] or any(m.group(1) for m in seq):
        return False
    pos = {}
    for m in SPEC.finditer(pt):
        if m.group(0) == '%%':
            continue
        if not m.group(1):
            return False
        pos.setdefault(int(m.group(1)), set()).add(m.group(2))
    return sorted(pos) == list(range(1, len(seq) + 1)) and all(pos[i + 1] == {m.group(2)} for i, m in enumerate(seq))


def markup(s):
    return (s.count('|c'), s.count('|r'), s.count('|T'), s.count('|t'), s.count('\\n'), s.count('|n'))


def bare_quote(s):
    i = 0
    while i < len(s):
        if s[i] == '\\':
            i += 2
            continue
        if s[i] == '"':
            return True
        i += 1
    return s.endswith('\\') and not s.endswith('\\\\')


def read_tsv(path):
    out = {}
    for line in path.read_text(encoding='utf-8-sig').splitlines():
        if not line.strip():
            continue
        i, _, text = line.partition('\t')
        out[int(i)] = text
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true', help='report only, do not write')
    args = ap.parse_args()

    keys = read_tsv(WORK / 'keys.tsv')
    trans = {}
    for p in sorted(WORK.glob('out_*.tsv')):
        trans.update(read_tsv(p))
    lua = LuaRuntime()
    compiles = lua.eval('function(s) return loadstring(s) ~= nil end')

    entries, problems, same, missing = [], [], 0, []
    for i, en in sorted(keys.items()):
        pt = trans.get(i)
        if pt is None:
            missing.append(i)
            continue
        if pt == en:
            same += 1
            continue
        why = []
        if not spec_ok(en, pt):
            why.append('placeholders')
        if markup(en) != markup(pt):
            why.append('markup')
        if bare_quote(pt) or '\t' in pt:
            why.append('quote/escape')
        if (en[:1] == ' ' and pt[:1] != ' ') or (en[-1:] == ' ') != (pt[-1:] == ' '):
            why.append('edge spaces')
        line = 'L["%s"] = "%s"' % (en, pt)
        if not why and not compiles(line):
            why.append('lua')
        if why:
            problems.append((i, ','.join(why), en, pt))
            continue
        entries.append(line)

    print('keys %d, translated %d, same as English %d, missing %d, rejected %d' % (
        len(keys), len(entries), same, len(missing), len(problems)))
    for i, why, en, pt in problems:
        print('  %d [%s] %r -> %r' % (i, why, en, pt))
    if missing:
        print('  missing ids: %s' % missing[:40])
    if args.check:
        return
    header = [
        'if EUI_CLIENT_BLOCKED then return end',
        '-- Brazilian Portuguese (pt-BR) localization for EllesmereUI, 3.3.5 backport.',
        '-- Encoding: UTF-8 without BOM. Built by backport-tools/build_ptbr_catalog.py from',
        '-- backport-tools/ptbr_work. Untranslated keys fall back to English.',
        'local L = EllesmereUI.RegisterLocale("ptBR")',
        'if not L then return end',
        '',
    ]
    OUT.write_bytes(('\r\n'.join(header + entries) + '\r\n').encode('utf-8'))
    print('Wrote %s (%d entries, %d KB)' % (OUT, len(entries), OUT.stat().st_size // 1024))


if __name__ == '__main__':
    sys.exit(main())
