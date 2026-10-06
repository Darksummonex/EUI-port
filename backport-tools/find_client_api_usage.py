"""Search every client FrameXML Lua/XML file in the MPQs for a token (reference
only, nothing is written). Usage: find_client_api_usage.py TOKEN [TOKEN...]"""
from pathlib import Path
import sys
from game_paths import ADDONS, DATA, WTF
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
import mpyq

data = DATA
archives = ['zz-ptbr.mpq', 'rebuffed.mpq', 'patch-6.MPQ', 'patch-3.MPQ', 'patch-2.MPQ', 'patch.MPQ', 'common-2.MPQ', 'common.MPQ',
            'ptBR/patch-ptBR-3.MPQ', 'ptBR/patch-ptBR-2.MPQ', 'ptBR/patch-ptBR.MPQ', 'ptBR/locale-ptBR.MPQ',
            'enUS/patch-enUS-3.MPQ', 'enUS/patch-enUS-2.MPQ', 'enUS/patch-enUS.MPQ', 'enUS/locale-enUS.MPQ']
tokens = [t.encode() for t in sys.argv[1:]]
done = set()
for rel in archives:
    path = data / rel
    if not path.exists():
        continue
    try:
        mpq = mpyq.MPQArchive(str(path))
    except Exception as exc:
        print('skip', rel, exc)
        continue
    names = [n.decode('latin-1') if isinstance(n, bytes) else n for n in (mpq.files or [])]
    for name in names:
        low = name.lower()
        if not low.startswith('interface\\') or not (low.endswith('.xml') or low.endswith('.lua')) or low in done:
            continue
        try:
            blob = mpq.read_file(name)
        except Exception:
            continue
        if not blob:
            continue
        done.add(low)
        for i, line in enumerate(blob.split(b'\n'), 1):
            if any(t in line for t in tokens):
                print('%s %s:%d: %s' % (rel, name, i, line.strip()[:160].decode('latin-1')))
print('scanned', len(done), 'files')
