"""One-off: pull the !EUI_ profile strings Alex pasted (port + Retail) out of the chat
transcript, decode them with the port's LibDeflate + Serializer, and summarize both.
Strings are saved under .codex-backups/profile-strings/ for later import tests."""
import json
import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

transcript = pathlib.Path(sys.argv[1])
out_dir = root / '.codex-backups' / 'profile-strings'
out_dir.mkdir(parents=True, exist_ok=True)

found = []
for line in transcript.read_text(encoding='utf-8').splitlines():
    if '!EUI_S3' not in line:
        continue
    try:
        event = json.loads(line)
    except ValueError:
        continue
    if event.get('role') != 'user':
        continue
    for part in event.get('message', {}).get('content', []):
        text = part.get('text', '') if isinstance(part, dict) else ''
        found.extend(re.findall(r'!EUI_[A-Za-z0-9()]+', text))
strings = []
for s in found:
    if s not in strings:
        strings.append(s)
assert len(strings) >= 2, 'expected the port and Retail strings, found %d' % len(strings)
labels = ['port', 'retail']
for label, s in zip(labels, strings[-2:]):
    (out_dir / (label + '.txt')).write_text(s, encoding='ascii')

lua = LuaRuntime(unpack_returned_tuples=True)
lua.globals().LibDeflate = lua.execute((root / 'EllesmereUI/Libs/LibDeflate/LibDeflate.lua').read_text(encoding='utf-8-sig'))
profiles = (root / 'EllesmereUI/EllesmereUI_Profiles.lua').read_text(encoding='utf-8-sig')
chunk = profiles.split('local Serializer = {}', 1)[1].split('EllesmereUI._Serializer = Serializer', 1)[0]
decode = lua.execute('local Serializer = {}' + chunk + '''
local LD = LibDeflate or (LibStub and LibStub("LibDeflate", true))
return function(s)
    local decoded = LD:DecodeForPrint(s:sub(6))
    if not decoded then return nil, "decode" end
    local raw = LD:DecompressDeflate(decoded)
    if not raw then return nil, "decompress" end
    local payload = Serializer.Deserialize(raw)
    if type(payload) ~= "table" then return nil, "deserialize" end
    return payload, #raw
end''')
def keys(t):
    return sorted(str(k) for k in t.keys()) if t is not None and lua.eval('type')(t) == 'table' else []


for label, s in zip(labels, strings[-2:]):
    payload, size = decode(s)
    print('==', label, 'string chars', len(s))
    if payload is None:
        print('  FAILED at', size)
        continue
    print('  raw bytes', size, 'version', payload['version'], 'type', payload['type'])
    print('  top keys', keys(payload))
    data = payload['data']
    print('  data keys', keys(data))
    if data is not None and data['addons'] is not None:
        for name in keys(data['addons']):
            sub = data['addons'][name]
            print('    addon', name, len(keys(sub)) if lua.eval('type')(sub) == 'table' else type(sub))
    for k in keys(payload):
        v = payload[k]
        if lua.eval('type')(v) != 'table':
            print('  ', k, '=', v)
