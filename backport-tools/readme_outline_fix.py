"""One-off: README-335 entries for the live Unit Frames outline fix and nameplate outline cogs."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENTRIES = {
    'EllesmereUIUnitFrames': ('0.12', '0.13', """0.13: o contorno por texto só aparecia na prévia. Ao salvar uma opção, o
recarregamento dos frames principais refazia a fonte de Left, Right e Center
Text (`SetMiniFont`) depois do layout, sem o contorno; agora ele recebe o
contorno do slot. O texto de power da barra de forma do druida segue o
contorno do Power Percent."""),
    'EllesmereUIOptions': ('0.87', '0.88', """0.88: Nameplates: o contorno saiu do popup de tamanho (ícone de redimensionar)
e ganhou uma engrenagem própria em cada linha de CORE TEXT POSITIONS (segue o
texto escolhido no slot), em Spell Name, Cast Timer e Friendly Names."""),
}

for module, (old, new, entry) in ENTRIES.items():
    path = ROOT / module / 'README-335.md'
    data = path.read_bytes().decode('utf-8')
    eol = '\r\n' if '\r\n' in data else '\n'
    lines = data.split(eol)
    if lines[0].endswith(' ' + new):
        print(f'{module}: already {new}')
        continue
    assert lines[0].endswith(' ' + old), (module, lines[0])
    lines[0] = lines[0][:-len(old)] + new
    assert lines[1] == '', module
    lines[2:2] = entry.split('\n') + ['']
    path.write_bytes(eol.join(lines).encode('utf-8'))
    print(f'{module}: {old} -> {new}')
