"""One-off: find numeric settings whose units differ between Retail and the port
(percent vs multiplier, 0-100 vs 0-1). Compares each numeric value in the decoded
Retail profile (.codex-backups/profile-strings/retail2.json) with the same key in the
port profile export (port.json) and with `key=<number>` defaults in the port's
*_335*.lua sources, and flags a ratio of 20x or more either way."""
import json
import pathlib
import re

root = pathlib.Path(__file__).resolve().parent.parent
strings = root / '.codex-backups' / 'profile-strings'
retail = json.loads((strings / 'retail2.json').read_text(encoding='utf-8'))['data']['addons']
port = json.loads((strings / 'port.json').read_text(encoding='utf-8'))['data']['addons']


def port_defaults(folder):
    out = {}
    d = root / folder
    if not d.is_dir():
        return out
    for f in d.glob('*_335*.lua'):
        for k, v in re.findall(r'\b([A-Za-z_]\w*)\s*=\s*(-?\d+(?:\.\d+)?)\b', f.read_text(encoding='utf-8', errors='replace')):
            out.setdefault(k, set()).add(float(v))
    return out


def far(a, b):
    a, b = abs(a), abs(b)
    if a == 0 or b == 0:
        return False
    return a / b >= 20 or b / a >= 20


def walk(path, r, p, defaults, out):
    for k, v in r.items():
        here = path + '.' + k
        pv = p.get(k) if isinstance(p, dict) else None
        if isinstance(v, dict):
            walk(here, v, pv if isinstance(pv, dict) else {}, defaults, out)
        elif isinstance(v, (int, float)) and not isinstance(v, bool):
            if isinstance(pv, (int, float)) and not isinstance(pv, bool) and far(v, pv):
                out.append('%s retail=%s port=%s' % (here, v, pv))
            elif pv is None and k in defaults and all(far(v, d) for d in defaults[k]):
                out.append('%s retail=%s portDefault=%s' % (here, v, sorted(defaults[k])))


for folder in sorted(retail):
    out = []
    walk('', retail[folder], port.get(folder, {}), port_defaults(folder), out)
    if out:
        print('==', folder)
        for line in out:
            print('  ', line)
