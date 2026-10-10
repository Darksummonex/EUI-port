"""One-off: decode the saved port and Retail profile strings
(.codex-backups/profile-strings/{port,retail}.txt), dump each payload as JSON next to
them, and list per module where the Retail data differs in shape from the port's:
keys the port export lacks, type mismatches, and differing string values."""
import json
import pathlib
import sys

root = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

src_dir = root / '.codex-backups' / 'profile-strings'
lua = LuaRuntime(unpack_returned_tuples=True)
lua.globals().LibDeflate = lua.execute((root / 'EllesmereUI/Libs/LibDeflate/LibDeflate.lua').read_text(encoding='utf-8-sig'))
profiles = (root / 'EllesmereUI/EllesmereUI_Profiles.lua').read_text(encoding='utf-8-sig')
chunk = profiles.split('local Serializer = {}', 1)[1].split('EllesmereUI._Serializer = Serializer', 1)[0]
decode = lua.execute('local Serializer = {}' + chunk + '''
local LD = LibDeflate
return function(s)
    return Serializer.Deserialize(LD:DecompressDeflate(LD:DecodeForPrint(s:sub(6))))
end''')
lua_type = lua.eval('type')


def to_py(v, depth=0):
    if lua_type(v) != 'table':
        return v
    out = {}
    for k, x in v.items():
        out[str(k) if not isinstance(k, (int, float)) else '#%s' % k] = to_py(x, depth + 1)
    return out


payloads = {}
for label in ('port', 'retail'):
    p = to_py(decode((src_dir / (label + '.txt')).read_text(encoding='ascii').strip()))
    payloads[label] = p
    (src_dir / (label + '.json')).write_text(json.dumps(p, indent=1, sort_keys=True), encoding='utf-8')

port_addons = payloads['port']['data']['addons']
retail_addons = payloads['retail']['data']['addons']


def kind(v):
    return 'table' if isinstance(v, dict) else type(v).__name__


def walk(path, a, b, out):
    for k, rv in b.items():
        p = path + '.' + k
        if k not in a:
            out['missing'].append(p)
            continue
        pv = a[k]
        if kind(pv) != kind(rv) and not (isinstance(pv, (int, float)) and isinstance(rv, (int, float))):
            out['type'].append('%s port=%s retail=%s' % (p, kind(pv), kind(rv)))
        elif isinstance(rv, dict):
            walk(p, pv, rv, out)
        elif isinstance(rv, str) and rv != pv:
            out['string'].append('%s port=%r retail=%r' % (p, pv, rv))


for name in sorted(retail_addons):
    if name not in port_addons:
        print('== %s: not in port export' % name)
        continue
    out = {'missing': [], 'type': [], 'string': []}
    walk('', port_addons[name], retail_addons[name], out)
    print('== %s: %d missing, %d type, %d string' % (name, len(out['missing']), len(out['type']), len(out['string'])))
    for t in out['type']:
        print('  TYPE', t)
    for s in out['string']:
        print('  STR ', s)
    if out['missing']:
        print('  MISSING', ', '.join(out['missing'][:60]) + (' ...' if len(out['missing']) > 60 else ''))
