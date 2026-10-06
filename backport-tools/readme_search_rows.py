"""One-off: README entry for the search rows drawn above the list background (Core 0.53)."""
from pathlib import Path

PATH = Path(__file__).resolve().parent.parent / 'EllesmereUI' / 'README-335.md'
OLD, NEW = '0.52', '0.53'
ADDED = [
    '0.53: com o fundo opaco a lista de busca ficou vazia: as linhas de resultado',
    'estavam abaixo do próprio fundo da lista (por isso pareciam apagadas antes,',
    'com o fundo translúcido). A cada exibição a lista agora fixa os níveis: lista',
    '220, área de resultados 221, linhas 222; o `Raise()` da 0.51 saiu.',
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
