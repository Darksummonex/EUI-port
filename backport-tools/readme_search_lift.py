"""One-off: README entry for the search results re-raise (Core 0.51)."""
from pathlib import Path

PATH = Path(__file__).resolve().parent.parent / 'EllesmereUI' / 'README-335.md'
OLD, NEW = '0.50', '0.51'
ADDED = [
    '0.51: a lista de resultados da busca das opções voltou a ficar atrás da barra',
    'lateral e da página (texto apagado, misturado com o do painel). Alguns clientes',
    '3.3.5 recolocam a camada (strata/nível) de um frame depois do OnShow; agora a',
    'lista reaplica `FULLSCREEN_DIALOG` / 220 e chama `Raise` logo após o `Show` e',
    'de novo no frame seguinte (OnUpdate de uma vez). A lista fica em',
    '`EllesmereUI._searchPopup` para conferir a camada no jogo.',
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
