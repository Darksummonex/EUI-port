"""One-off: Core README "Sem bump" note (line 3) for the nil CreateMaskTexture fix."""
import pathlib

path = pathlib.Path(__file__).resolve().parent.parent / 'EllesmereUI' / 'README-335.md'
LINES = [
    'Sem bump: abrir as opções dava erro "attempt to index local \'mask\'"',
    '(`EllesmereUI_Panel.lua`) em clientes onde outro addon cria um',
    'CreateMaskTexture que retorna nil. As três máscaras do painel (anel e emblema',
    'do logo, ponto de patch novo) agora são ignoradas quando vêm nil.',
    '',
]
raw = path.read_bytes()
assert b'\r\n' in raw and not raw.startswith(b'\xef\xbb\xbf')
rows = raw.decode('utf-8').split('\r\n')
if not rows[2].startswith(LINES[0]):
    rows[2:2] = LINES
    path.write_bytes('\r\n'.join(rows).encode('utf-8'))
print(rows[2])
