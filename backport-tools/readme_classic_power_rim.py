"""One-off: README entry for the Classic WoW UI power bar over the art rim (Unit Frames 0.16)."""
from pathlib import Path

PATH = Path(__file__).resolve().parent.parent / 'EllesmereUIUnitFrames' / 'README-335.md'
OLD, NEW = '0.15', '0.16'
ADDED = [
    '0.16: no Classic WoW UI a barra de power passava por cima da borda da arte',
    '(saía da caixa embaixo e à direita). No Retail o contêiner das barras desenha',
    'as duas como um grupo no nível dele, abaixo da arte; no 3.3.5 cada barra',
    'desenha no próprio nível e a de power fica em vida + 2, acima da arte. Agora,',
    'no 3.3.5, a arte dos frames clássicos sobe para acima das duas barras (vida + 3',
    'ou power + 1), ainda abaixo do nível, dos textos, do brilho de absorção e do',
    'ícone de descanso.',
]

data = PATH.read_bytes().decode('utf-8')
eol = '\r\n' if '\r\n' in data else '\n'
lines = data.split(eol)
if ADDED[0] in lines:
    print('already noted')
else:
    assert lines[0].endswith('— ' + OLD), lines[0]
    lines[0] = lines[0][:-len(OLD)] + NEW
    lines[2:2] = ADDED + ['']
    PATH.write_bytes(eol.join(lines).encode('utf-8'))
    print('noted')
