"""One-off: note the Esc blocked-action fix in the Options 0.88 README entry."""
from pathlib import Path

PATH = Path(__file__).resolve().parent.parent / 'EllesmereUIOptions' / 'README-335.md'
ANCHOR = 'texto escolhido no slot), em Spell Name, Cast Timer e Friendly Names.'
ADDED = ['Desfeita a proteção da 0.87: ela substituía `CreateMaskTexture` /',
         '`AddMaskTexture` que o cliente já tinha, nas tabelas de métodos compartilhadas',
         'com os frames da Blizzard, e isso contaminava o código seguro: fechar janelas',
         'da Blizzard com Esc mostrava "EllesmereUIOptions has been blocked from an',
         'action". O compat volta a só preencher métodos ausentes (a correção do Unit',
         'Frames 0.12 continua, por ser só nos frames do EUI).']

data = PATH.read_bytes().decode('utf-8')
eol = '\r\n' if '\r\n' in data else '\n'
lines = data.split(eol)
if ADDED[0] in lines:
    print('already noted')
else:
    i = lines.index(ANCHOR)
    lines[i + 1:i + 1] = ADDED
    PATH.write_bytes(eol.join(lines).encode('utf-8'))
    print('noted')
