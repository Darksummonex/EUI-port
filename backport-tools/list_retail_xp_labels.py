"""Lists the option labels and section headers of Retail's XP Bar options tab and
the XP text item ids, to scope the Wrath port."""
import re
import pathlib

base = pathlib.Path('D:/World of Warcraft/_retail_/Interface/AddOns')
opts = (base / 'EllesmereUIOptions/ActionBars_Options/XPBarPage_Options.lua').read_text(encoding='utf-8')
seen = []
for m in re.finditer(r'(?:text\s*=\s*|SectionHeader\(\w+,\s*|Lbl\(|L\()"([^"]{3,60})"', opts):
    if m.group(1) not in seen:
        seen.append(m.group(1))
print('\n'.join(seen))
print('---- items')
code = (base / 'EllesmereUIActionBars/EUI_ActionBars_XPBar.lua').read_text(encoding='utf-8')
start = code.find('local function XPTextItems')
print(code[code.rfind('-- What a text shows', 0, start):start][:3000])
i = code.find('local function XPItemText')
print(code[i:i + 2600])
