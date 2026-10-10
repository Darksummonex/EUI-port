"""Summarise a decoded profile payload saved by save_last_profile_string.py.

Usage: inspect_profile_payload.py <label> [<module>]
Prints top-level and data keys; with a module, lists its settings next to the
port's current live profile (port.json) and flags missing keys and type changes.
"""
import json
import pathlib
import sys

root = pathlib.Path(__file__).resolve().parent.parent
d = root / '.codex-backups' / 'profile-strings'
p = json.loads((d / (sys.argv[1] + '.json')).read_text(encoding='utf-8'))
print('top keys:', sorted(p.keys()), 'version', p.get('version'), 'client', p.get('client'))
data = p.get('data', {})
for k in sorted(data):
    v = data[k]
    print(' data.%s: %s' % (k, ('table(%d)' % len(v)) if isinstance(v, dict) else repr(v)[:80]))
if len(sys.argv) < 3:
    sys.exit()
mod = sys.argv[2]
blob = data.get('addons', {}).get(mod, {})
port = json.loads((d / 'port.json').read_text(encoding='utf-8'))
live = port.get('data', {}).get('addons', {}).get(mod, {})


def walk(a, b, path=''):
    same = missing = typed = 0
    for k, v in sorted(a.items()):
        here = path + '.' + k if path else k
        if k not in b:
            missing += 1
            print('  MISSING', here, repr(v)[:70])
        elif isinstance(v, dict) and isinstance(b[k], dict):
            s, m, t = walk(v, b[k], here)
            same += s; missing += m; typed += t
        elif type(v) is not type(b[k]) and not (isinstance(v, (int, float)) and isinstance(b[k], (int, float))):
            typed += 1
            print('  TYPE', here, repr(v)[:40], 'port:', repr(b[k])[:40])
        else:
            same += 1
            if v != b[k]:
                print('  VALUE', here, repr(v)[:40], 'port:', repr(b[k])[:40])
    return same, missing, typed


s, m, t = walk(blob, live)
print('%s: %d importable, %d not in port profile, %d type mismatch' % (mod, s, m, t))
