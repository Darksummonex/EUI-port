"""Look up Wrath aura IDs by name in LibAuraInfo's spellIdData (debuff duration table).

Usage: lookup_aura_ids.py "Name A" "Name B" ...
Prints every ID whose comment starts with each name (any rank).
"""
import re
import sys
from pathlib import Path

DATA = Path(__file__).resolve().parent.parent / 'EllesmereUINameplates' / 'Libs' / 'LibAuraInfo-1.0' / 'spellIdData.lua'
ROW = re.compile(r'\[(\d+)\]\s*=\s*[^,]*,\s*--\s*(.+)$')

rows = {}
for line in DATA.read_text(encoding='utf-8', errors='replace').splitlines():
    m = ROW.search(line)
    if m:
        rows.setdefault(int(m.group(1)), m.group(2).strip())

for name in sys.argv[1:]:
    hits = sorted(i for i, label in rows.items() if re.match(re.escape(name) + r'(\s*\(|$)', label))
    print('%-28s %s' % (name, ', '.join('%d' % i for i in hits) or '-- none --'))
