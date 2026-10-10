"""Read-only helper: the translatable strings of EllesmereUI._WHATSNEW_PATCHES
(eyebrow, title, desc, text, module fields) in EUI__General_Options.lua, as raw
Lua string contents in file order without duplicates. Run directly for counts.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / 'EllesmereUIOptions' / 'EUI__General_Options.lua'
FIELD = re.compile(r'\b(eyebrow|title|desc|text|module)\s*=\s*"((?:[^"\\\n]|\\.)*)"\s*(\.\.)?')


def block():
    text = SRC.read_text(encoding='utf-8-sig').replace('\r\n', '\n')
    start = text.index('EllesmereUI._WHATSNEW_PATCHES = {')
    return text[start:text.index('\n    }\nend', start)]


def strings():
    seen, out, joined = set(), [], []
    for m in FIELD.finditer(block()):
        if m.group(3):
            joined.append(m.group(2))
        s = m.group(2)
        if s and s not in seen:
            seen.add(s)
            out.append(s)
    return out, joined


if __name__ == '__main__':
    out, joined = strings()
    print('%d strings, %d chars; %d concatenated (need a manual look)' % (len(out), sum(map(len, out)), len(joined)))
    for s in joined[:10]:
        print('  JOIN', s[:80])
