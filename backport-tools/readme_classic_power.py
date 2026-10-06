"""One-off: README entries for the Classic WoW UI stock power colours (Unit Frames 0.15, Options 0.90)."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENTRIES = {
    'EllesmereUIUnitFrames': ('0.14', '0.15', [
        '0.15: no Classic WoW UI a barra de recurso (mana, raiva, energia, poder',
        'rúnico) usava a paleta do EllesmereUI (mana azul-claro) em vez das cores',
        'originais do jogo. Agora, só nesse estilo, a cor vem do `PowerBarColor` do',
        'cliente (mana azul-escuro, raiva vermelha, energia amarela), via',
        '`ns.UF_PowerColor` / `ns.UF_PowerInfo`: barra, fundo, textos de power, Bottom',
        'Text Bar e a barra de forma do druida. Os outros estilos continuam com a',
        'paleta; tipos que o cliente não tem caem nela. Nenhuma opção é alterada.',
    ]),
    'EllesmereUIOptions': ('0.89', '0.90', [
        '0.90: a prévia e as amostras de cor de power dos Unit Frames usam',
        '`ns.UF_PowerInfo` / `ns.UF_PowerColor`, então mostram as cores originais do',
        'jogo no Classic WoW UI.',
    ]),
}

for folder, (old, new, added) in ENTRIES.items():
    path = ROOT / folder / 'README-335.md'
    data = path.read_bytes().decode('utf-8')
    eol = '\r\n' if '\r\n' in data else '\n'
    lines = data.split(eol)
    if added[0] in lines:
        print(folder, 'already noted')
        continue
    assert lines[0].endswith('— ' + old), lines[0]
    lines[0] = lines[0][:-len(old)] + new
    lines[2:2] = added + ['']
    path.write_bytes(eol.join(lines).encode('utf-8'))
    print(folder, 'noted')
