"""Normalize esES batch terms to match the Retail esES catalog (Health = "vida").

Keeps "piedra de salud" (Healthstone item name). Edits locale_work/esES/out_*.tsv in place.
"""
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent / 'locale_work' / 'esES'
FIXED = {
    '2523': 'iLvl',
    '2524': 'ilvl',
}
KEEP = re.compile(r'(piedra|Piedra|PIEDRA)(s)? de (salud|SALUD)')
WORD = re.compile(r'\b(salud|Salud|SALUD)\b')
REPL = {'salud': 'vida', 'Salud': 'Vida', 'SALUD': 'VIDA'}


def fix(text):
    keep = {}

    def stash(m):
        k = '\x00%d\x00' % len(keep)
        keep[k] = m.group(0)
        return k

    text = KEEP.sub(stash, text)
    text = WORD.sub(lambda m: REPL[m.group(1)], text)
    for k, v in keep.items():
        text = text.replace(k, v)
    return text


changed = 0
for path in sorted(ROOT.glob('out_*.tsv')):
    raw = path.read_bytes().decode('utf-8')
    nl = '\r\n' if '\r\n' in raw else '\n'
    out = []
    for line in raw.split(nl):
        if '\t' in line:
            i, t = line.split('\t', 1)
            n = FIXED.get(i, fix(t))
            if n != t:
                changed += 1
            line = i + '\t' + n
        out.append(line)
    path.write_bytes(nl.join(out).encode('utf-8'))
print('changed', changed)
