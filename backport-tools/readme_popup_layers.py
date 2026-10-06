"""One-off: README entries for the options popup layer/background fix (Core 0.54, Options 0.91)."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENTRIES = {
    'EllesmereUI': (' 0.53', ' 0.54', [
        '0.54: o shim `SetColorTexture` do 3.3.5 guarda a cor pedida na textura',
        '(`_euiR/_euiG/_euiB/_euiA`), para o Options trocar fundos sólidos de popups',
        'por uma textura opaca com a mesma cor.',
    ]),
    'EllesmereUIOptions': ('— 0.90', '— 0.91', [
        '0.91: as listas de dropdown (ex.: Visibility das DataBars), checklists e',
        'outros popups das opções mostravam os itens apagados, por baixo do próprio',
        'fundo, com a página aparecendo através dele (mesma causa da busca no Core',
        '0.52-0.53). `EllesmereUI.CreateOptionsFrame` agora, para todo frame sem nome',
        'criado direto no UIParent (ou na camada de overlay), engancha o OnShow: em',
        'cada exibição e de novo no frame seguinte, cada filho fica acima do pai e um',
        'fundo sólido quase opaco (alfa >= 0.9, camada BACKGROUND) vira',
        '`WHITE8X8` tingido com alfa 1. Só ganchos por instância, nada em metatable',
        'compartilhada.',
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
    assert lines[0].endswith(old), lines[0]
    lines[0] = lines[0][:-len(old)] + new
    lines[2:2] = added + ['']
    path.write_bytes(eol.join(lines).encode('utf-8'))
    print(folder, 'noted')
