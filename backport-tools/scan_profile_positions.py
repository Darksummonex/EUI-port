"""List position records ({point, x, y}) in a decoded Retail profile and whether
the port profile (port.json) has a record at the same path.

Usage: scan_profile_positions.py <retail label> [<port label>]
"""
import json
import pathlib
import sys

root = pathlib.Path(__file__).resolve().parent.parent
d = root / '.codex-backups' / 'profile-strings'
retail = json.loads((d / (sys.argv[1] + '.json')).read_text(encoding='utf-8'))
port = json.loads((d / ((sys.argv[2] if len(sys.argv) > 2 else 'port') + '.json')).read_text(encoding='utf-8'))


def is_pos(v):
    return isinstance(v, dict) and 'point' in v and ('x' in v or 'y' in v)


def walk(node, other, path, out):
    if not isinstance(node, dict):
        return
    for k, v in node.items():
        here = path + [k]
        o = other.get(k) if isinstance(other, dict) else None
        if is_pos(v):
            out.append(('/'.join(here), v, o))
        elif isinstance(v, dict):
            walk(v, o, here, out)


out = []
walk(retail['data'].get('addons', {}), port['data'].get('addons', {}), [], out)
for key in ('tooltipFixedPos',):
    if key in retail['data']:
        out.append((key, retail['data'][key], port['data'].get(key)))
by_parent = {}
for path, v, o in out:
    parent = path.rsplit('/', 1)[0]
    by_parent.setdefault(parent, []).append((path.rsplit('/', 1)[-1], v, o))
for parent, rows in sorted(by_parent.items()):
    have = sum(1 for r in rows if r[2] is not None)
    print('%s: %d records, %d also in port profile' % (parent, len(rows), have))
    for name, v, o in rows[:6]:
        fields = ','.join(sorted(v.keys()))
        print('   %-22s %-46s port: %s' % (name, fields[:46], 'yes ' + ','.join(sorted(o.keys()))[:40] if isinstance(o, dict) else 'no'))
