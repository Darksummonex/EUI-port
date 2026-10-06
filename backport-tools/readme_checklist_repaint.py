"""One-off: README entry for the checklist repaint fix (Options 0.92)."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
path = ROOT / 'EllesmereUIOptions' / 'README-335.md'
added = [
    '0.92: nas checklists (ex.: Visibility das Unit Frames) as caixas só mudavam',
    'depois de fechar e reabrir o menu. O clique grava o valor e roda a cadeia de',
    'atualização do módulo antes de repintar as linhas; um erro nessa cadeia',
    'interrompia o repaint. `BuildVisOptsCBDropdown` agora chama o `setFn` das',
    'linhas e das ações via `pcall`, repinta sempre e só então entrega o erro ao',
    '`geterrorhandler()`.',
]
data = path.read_bytes().decode('utf-8')
eol = '\r\n' if '\r\n' in data else '\n'
lines = data.split(eol)
if added[0] in lines:
    print('already noted')
else:
    assert lines[0].endswith('— 0.91'), lines[0]
    lines[0] = lines[0][:-len('0.91')] + '0.92'
    lines[2:2] = added + ['']
    path.write_bytes(eol.join(lines).encode('utf-8'))
    print('noted')
