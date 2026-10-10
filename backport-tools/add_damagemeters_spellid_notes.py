"""One-off: Damage Meters 0.9 (spell IDs in the breakdown) TOC bump, README entry,
patch-note hero and handoff version."""
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent
OLD, NEW = '0.8', '0.9'
FOLDER = 'EllesmereUIDamageMeters'

toc = root / FOLDER / (FOLDER + '.toc')
raw = toc.read_bytes()
assert not raw.startswith(b'\xef\xbb\xbf')
text = raw.decode('utf-8').replace('## Version: 9.3.4-335-' + OLD, '## Version: 9.3.4-335-' + NEW, 1)
assert '## Version: 9.3.4-335-' + NEW in text
toc.write_bytes(text.encode('utf-8'))

readme = root / FOLDER / 'README-335.md'
raw = readme.read_bytes()
eol = '\r\n' if b'\r\n' in raw else '\n'
rows = raw.decode('utf-8').split(eol)
if rows[0].endswith(OLD):
    rows[0] = rows[0][:-len(OLD)] + NEW
assert rows[0].endswith(NEW)
entry = [
    '0.9: ID da magia no breakdown. O tooltip de uma magia (passar o mouse numa magia',
    'com o jogador focado) ganhou a linha "Spell ID: <id>", e cada linha da janela',
    'detalhada (Shift-clique) termina com "ID <id>" em cinza. Não aparece em Targets',
    'nem no ataque corpo a corpo (sem ID). Vale também para a versão standalone.',
    '',
]
if not rows[2].startswith(entry[0]):
    rows[2:2] = entry
readme.write_bytes(eol.join(rows).encode('utf-8'))

notes = root / 'EllesmereUIOptions' / 'EUI__General_Options.lua'
raw = notes.read_bytes()
eol = '\r\n' if b'\r\n' in raw else '\n'
text = raw.decode('utf-8')
old_head = '        version = "Damage Meters %s",%s        heroes = {%s' % (OLD, eol, eol)
new_head = '        version = "Damage Meters %s",%s        heroes = {%s' % (NEW, eol, eol)
item = ('            {' + eol
        + '                title = "Spell IDs in the Breakdown",' + eol
        + '                desc  = "A spell\'s breakdown tooltip shows its Spell ID, and each spell row in the detailed window ends with its ID.",' + eol
        + '                nav   = Nav("EllesmereUIDamageMeters", "Windows"),' + eol
        + '            },' + eol)
if old_head in text:
    text = text.replace(old_head, new_head + item, 1)
assert new_head in text
notes.write_bytes(text.encode('utf-8'))

handoff = root / 'CODEX_HANDOFF_EllesmereUI_335_CURRENT.md'
text = handoff.read_bytes().decode('utf-8')
if 'Damage Meters ' + OLD + ';' in text:
    text = text.replace('Damage Meters ' + OLD + ';', 'Damage Meters ' + NEW + ';', 1)
assert 'Damage Meters ' + NEW + ';' in text
handoff.write_bytes(text.encode('utf-8'))
print('ok')
