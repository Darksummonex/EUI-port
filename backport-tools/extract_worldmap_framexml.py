"""Extract the client's world map FrameXML (reference only) into backport-tools/framexml-worldmap.

Archives are searched highest priority first; every archive that carries a file
gets its own copy so custom Rebuffed changes can be diffed against stock.
"""
from pathlib import Path
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
import mpyq

data = root.parents[1] / 'Data'
archives = ['zz-ptbr.mpq', 'rebuffed.mpq', 'patch-6.MPQ',
            'ptBR/patch-ptBR-3.MPQ', 'ptBR/patch-ptBR-2.MPQ', 'ptBR/patch-ptBR.MPQ', 'ptBR/locale-ptBR.MPQ',
            'enUS/patch-enUS-3.MPQ', 'enUS/patch-enUS-2.MPQ', 'enUS/patch-enUS.MPQ', 'enUS/locale-enUS.MPQ']
files = ['Interface\\FrameXML\\WorldMapFrame.lua', 'Interface\\FrameXML\\WorldMapFrame.xml',
         'Interface\\FrameXML\\UIParent.lua', 'Interface\\FrameXML\\WatchFrame.lua']
out = root / 'backport-tools' / 'framexml-worldmap'
out.mkdir(exist_ok=True)
for rel in archives:
    path = data / rel
    if not path.exists():
        continue
    try:
        mpq = mpyq.MPQArchive(str(path), listfile=False)
    except Exception as exc:
        print('skip', rel, exc)
        continue
    for name in files:
        try:
            blob = mpq.read_file(name)
        except Exception as exc:
            print('error', rel, name, exc)
            continue
        if blob:
            target = out / (rel.replace('/', '_') + '__' + name.split('\\')[-1])
            target.write_bytes(blob)
            print('found', rel, name, len(blob))
