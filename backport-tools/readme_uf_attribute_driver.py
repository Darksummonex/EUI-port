"""One-off: README entry for the Unit Frames visibility driver fix (Unit Frames 0.17)."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
path = ROOT / 'EllesmereUIUnitFrames' / 'README-335.md'
added = [
    '0.17: as condições de Visibility (combate, grupo, esconder sem alvo) davam',
    'erro `RegisterAttributeDriver` (nil): essa API não existe no 3.3.5. As 7',
    'chamadas (Register/UnregisterAttributeDriver) passam por',
    '`ns.Wrath.RegisterAttributeDriver`/`UnregisterAttributeDriver`, que usam a',
    'nativa quando existe e, no 3.3.5, mapeiam o atributo `state-X` para',
    '`RegisterStateDriver(frame, "X", ...)` (o mesmo atributo). Era também o',
    'motivo das caixas do menu Visibility só mudarem ao reabrir.',
]
data = path.read_bytes().decode('utf-8')
eol = '\r\n' if '\r\n' in data else '\n'
lines = data.split(eol)
if added[0] in lines:
    print('already noted')
else:
    assert lines[0].endswith('— 0.16'), lines[0]
    lines[0] = lines[0][:-len('0.16')] + '0.17'
    lines[2:2] = added + ['']
    path.write_bytes(eol.join(lines).encode('utf-8'))
    print('noted')
