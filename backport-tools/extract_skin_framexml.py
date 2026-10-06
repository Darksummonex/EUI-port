"""Extract the client's FrameXML for the windows targeted by the ElvUI-parity skins
(reference only) into backport-tools/framexml-skins. Blizzard code: never commit it.

The highest-priority archive that carries a file wins.
"""
from pathlib import Path
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
import mpyq

data = root.parents[1] / 'Data'
archives = ['zz-ptbr.mpq', 'rebuffed.mpq', 'patch-6.MPQ', 'patch-3.MPQ', 'patch-2.MPQ', 'patch.MPQ',
            'ptBR/patch-ptBR-3.MPQ', 'ptBR/patch-ptBR-2.MPQ', 'ptBR/patch-ptBR.MPQ', 'ptBR/locale-ptBR.MPQ',
            'enUS/patch-enUS-3.MPQ', 'enUS/patch-enUS-2.MPQ', 'enUS/patch-enUS.MPQ', 'enUS/locale-enUS.MPQ']
keys = ['barbershop', 'battlefieldminimap', 'worldstateframe', 'pvpframe', 'battlefieldframe', 'arenaframe',
        'arenaregistrar', 'helpframe', 'gmsurvey', 'gmchat', 'mirrortimer', 'timemanager', 'raidui', 'debugtools',
        'pvpbattleground', 'lootframe', 'globalstrings', 'raidframe']
out = root / 'backport-tools' / 'framexml-skins'
out.mkdir(exist_ok=True)
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
        if not low.startswith('interface\\') or not (low.endswith('.xml') or low.endswith('.lua')):
            continue
        if not any(k in low for k in keys) or low in done:
            continue
        try:
            blob = mpq.read_file(name)
        except Exception as exc:
            print('error', rel, name, exc)
            continue
        if blob:
            done.add(low)
            (out / name.split('\\')[-1]).write_bytes(blob)
            print('found', rel, name, len(blob))
