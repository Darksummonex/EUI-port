"""Read-only: dropdown labels in the Retail Nameplates options vs the 3.3.5 port.

A dropdown is a table with type = "dropdown" (any spacing/case); its label is the
nearest text = / label = string in the same table. Prints labels Retail has and
the port lacks, grouped by Retail file.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RETAIL = Path('D:/World of Warcraft/_retail_/Interface/AddOns/EllesmereUIOptions')
RETAIL_FILES = [RETAIL / 'EUI_Nameplates_Options.lua'] + sorted((RETAIL / 'Nameplates_Options').glob('*.lua'))
PORT = ROOT / 'EllesmereUIOptions' / 'EUI_Nameplates_335_Options.lua'
TYPE = re.compile(r'type\s*=\s*"dropdown"', re.I)
LABEL = re.compile(r'\b(?:text|label)\s*=\s*"((?:[^"\\]|\\.)*)"')


def labels(text):
    out = []
    for m in TYPE.finditer(text):
        lo = text.rfind('{', 0, m.start())
        window = text[lo:m.end() + 600]
        lm = LABEL.search(window)
        out.append(lm.group(1) if lm else '?')
    return out


def port_strings(text):
    return set(re.findall(r'"((?:[^"\\]|\\.)*)"', text))


def main():
    port_text = PORT.read_text(encoding='utf-8-sig')
    have = port_strings(port_text)
    print('port dropdowns: %d' % len(labels(port_text)))
    for f in RETAIL_FILES:
        found = labels(f.read_text(encoding='utf-8-sig', errors='replace'))
        missing = sorted(set(l for l in found if l not in have))
        print('\n%s: %d dropdowns, %d labels missing in port' % (f.name, len(found), len(missing)))
        for l in missing:
            print('   ', l)


if __name__ == '__main__':
    main()
