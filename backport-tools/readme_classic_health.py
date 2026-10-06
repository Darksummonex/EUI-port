"""One-off: README entries for the Classic WoW UI green health seed (Unit Frames 0.14, Options 0.89)."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENTRIES = {
    'EllesmereUIUnitFrames': ('0.13', '0.14', [
        '0.14: no estilo Classic WoW UI (arte vanilla) a barra de vida usava a cor da',
        'classe (o azul-arroxeado do bruxo) em vez do verde original. Ao entrar no',
        'estilo, uma vez por perfil, todos os frames (player, target, focus, pet,',
        'targettarget, focustarget, boss) recebem preenchimento personalizado verde e a',
        'cor de classe é desligada. Um perfil que já estava no Classic recebe o verde no',
        'próximo /reload, e as cores anteriores vão para o slot do visual EllesmereUI,',
        'então voltar a esse visual devolve as cores do usuário.',
    ]),
    'EllesmereUIOptions': ('0.88', '0.89', [
        '0.89: a página Style guarda por estilo a cor de vida dos Unit Frames',
        '(`healthClassColored` e `customFillColor` de cada frame, carimbo',
        '`classicHealthSeeded`), junto da textura e do ícone de combate.',
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
