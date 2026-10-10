"""One-off: save the newest !EUI_ string Alex pasted in the chat transcript to
.codex-backups/profile-strings/<label>.txt and dump it as <label>.json.
Usage: python save_last_profile_string.py <transcript.jsonl> <label>"""
import json
import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

transcript, label = pathlib.Path(sys.argv[1]), sys.argv[2]
last = None
for line in transcript.read_text(encoding='utf-8').splitlines():
    if '!EUI_' not in line:
        continue
    try:
        event = json.loads(line)
    except ValueError:
        continue
    if event.get('role') != 'user':
        continue
    for part in event.get('message', {}).get('content', []):
        text = part.get('text', '') if isinstance(part, dict) else ''
        for s in re.findall(r'!EUI_[A-Za-z0-9()]+', text):
            last = s
assert last, 'no string found'
out_dir = root / '.codex-backups' / 'profile-strings'
out_dir.mkdir(parents=True, exist_ok=True)
(out_dir / (label + '.txt')).write_text(last, encoding='ascii')

lua = LuaRuntime(unpack_returned_tuples=True)
lua.globals().LibDeflate = lua.execute((root / 'EllesmereUI/Libs/LibDeflate/LibDeflate.lua').read_text(encoding='utf-8-sig'))
profiles = (root / 'EllesmereUI/EllesmereUI_Profiles.lua').read_text(encoding='utf-8-sig')
chunk = profiles.split('local Serializer = {}', 1)[1].split('EllesmereUI._Serializer = Serializer', 1)[0]
decode = lua.execute('local Serializer = {}' + chunk + '''
return function(s) return Serializer.Deserialize(LibDeflate:DecompressDeflate(LibDeflate:DecodeForPrint(s:sub(6)))) end''')
lua_type = lua.eval('type')


def to_py(v):
    if lua_type(v) != 'table':
        return v
    return {(('#%s' % k) if isinstance(k, (int, float)) else str(k)): to_py(x) for k, x in v.items()}


p = to_py(decode(last))
(out_dir / (label + '.json')).write_text(json.dumps(p, indent=1, sort_keys=True), encoding='utf-8')
print(label, 'chars', len(last), 'client', p.get('client'), 'type', p.get('type'),
      'modules', sorted(p['data'].get('addons', {}).keys()))
