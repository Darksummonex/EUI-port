"""List globals that TOC-loaded EllesmereUI files assign or define without an EUI prefix,
so Blizzard-owned names (taint sources) can be spotted. Locals in scope are excluded."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OURS = re.compile(r'^(EllesmereUI|Ellesmere|EUI|eui|_EUI|SLASH_EUI|SLASH_ELLESMERE|BINDING_|ns$|E$|L$)')
ASSIGN = re.compile(r'^([A-Za-z_]\w*)\s*=(?!=)')
FUNC = re.compile(r'^function\s+([A-Za-z_]\w*)\s*\(')

found = {}
for toc in sorted(ROOT.glob('EllesmereUI*/EllesmereUI*.toc')):
    if toc.stem != toc.parent.name:
        continue
    for raw in toc.read_text(encoding='utf-8-sig', errors='replace').splitlines():
        rel = raw.strip()
        if not rel or rel.startswith('#') or not rel.lower().endswith('.lua') or '\\Libs\\' in '\\' + rel:
            continue
        path = toc.parent / rel.replace('\\', '/')
        if not path.exists():
            continue
        text = path.read_text(encoding='utf-8', errors='replace')
        locals_ = set(re.findall(r'\blocal\s+(?:function\s+)?([A-Za-z_]\w*)', text))
        for m in re.finditer(r'\blocal\s+([A-Za-z_][\w\s,]*)=', text):
            locals_.update(x.strip() for x in m.group(1).split(','))
        for m in re.finditer(r'\bfunction\s*[\w.:]*\(([^)]*)\)', text):
            locals_.update(x.strip() for x in m.group(1).split(','))
        for m in re.finditer(r'\bfor\s+([\w\s,]+?)\s+(?:in|=)', text):
            locals_.update(x.strip() for x in m.group(1).split(','))
        depth = 0
        for n, line in enumerate(text.splitlines(), 1):
            code = line.split('--', 1)[0]
            top = depth == 0 and not line[:1].isspace()
            depth += code.count('{') - code.count('}')
            if not top:
                continue
            for stmt in code.split(';'):
                stmt = stmt.strip()
                m = FUNC.match(stmt) or ASSIGN.match(stmt)
                if not m:
                    continue
                name = m.group(1)
                if name in locals_ or OURS.match(name) or name in ('local', 'return', 'self'):
                    continue
                found.setdefault(name, []).append(f'{path.relative_to(ROOT)}:{n}')
for name in sorted(found):
    print(f'{name}: {", ".join(found[name][:3])}{" ..." if len(found[name]) > 3 else ""}')
print('names', len(found))
