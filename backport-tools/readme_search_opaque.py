"""One-off: README entry for the opaque search results background (Core 0.52)."""
from pathlib import Path

PATH = Path(__file__).resolve().parent.parent / 'EllesmereUI' / 'README-335.md'
OLD, NEW = '0.51', '0.52'
ADDED = [
    '0.52: o teste no jogo mostrou a lista de busca na camada certa',
    '(FULLSCREEN_DIALOG 220, acima da barra lateral em DIALOG 104-106), mas o fundo',
    'deixava passar cerca de um quinto do que estava atrás: a textura de cor sólida',
    '(`SetTexture(r,g,b,a)`, 0.97) sai translúcida nesse cliente. No 3.3.5 o fundo',
    'agora é `Interface\\Buttons\\WHITE8X8` tingido com `SetVertexColor(..., 1)`,',
    'opaco, e o texto da barra lateral e da página não aparece mais na lista.',
]

data = PATH.read_bytes().decode('utf-8')
eol = '\r\n' if '\r\n' in data else '\n'
lines = data.split(eol)
if ADDED[0] in lines:
    print('already noted')
else:
    assert lines[0].endswith(' ' + OLD), lines[0]
    lines[0] = lines[0][:-len(OLD)] + NEW
    lines[2:2] = ADDED + ['']
    PATH.write_bytes(eol.join(lines).encode('utf-8'))
    print('noted')
