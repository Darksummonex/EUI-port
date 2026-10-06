"""Write a unified diff of Retail vs Wrath EUI_UnlockMode.lua (read-only on both)."""
from pathlib import Path
import difflib
import sys
root = Path(__file__).resolve().parents[1]
retail = Path('D:/World of Warcraft/_retail_/Interface/AddOns/EllesmereUI/EUI_UnlockMode.lua')
wrath = root / 'EllesmereUI/EUI_UnlockMode.lua'
pattern = sys.argv[1].lower() if len(sys.argv) > 1 else None
a = retail.read_text(encoding='utf-8', errors='replace').splitlines()
b = wrath.read_text(encoding='utf-8', errors='replace').splitlines()
out = []
for line in difflib.unified_diff(a, b, 'retail', 'wrath', n=2, lineterm=''):
    out.append(line)
text = '\n'.join(out)
if pattern:
    hunks = text.split('\n@@')
    text = '\n@@'.join(h for h in hunks if pattern in h.lower())
(root / 'backport-tools/_unlock_diff.txt').write_text(text, encoding='utf-8')
print(len(out), 'diff lines')
