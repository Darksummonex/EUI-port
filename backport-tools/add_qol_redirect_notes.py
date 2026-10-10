"""One-off: QoL 0.18 (Misdirection / Tricks of the Trade helper) TOC bump, README entry,
patch-note hero and handoff version."""
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent
OLD, NEW = '0.17', '0.18'
FOLDER = 'EllesmereUIQoL'

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
    '0.18: Misdirection / Tricks helper (Displays > MISDIRECTION / TRICKS HELPER,',
    'desligado por padrão). Botão seguro EUI335QoLRedirect com macro',
    '/cast [target=focus,help,nodead] > tank > alvo amigo > pet (hunter). Tank: nome',
    'digitado, depois Main Tank da raide, depois papel de tank. Atalho em Key Bindings',
    '(EllesmereUI Quality of Life) ou /click EUI335QoLRedirect. Ícone mostra para quem vai, o',
    'tempo do buff e o cooldown; mover no Unlock Mode. Macro só muda fora de combate.',
    '',
]
if not rows[2].startswith(entry[0]):
    rows[2:2] = entry
readme.write_bytes(eol.join(rows).encode('utf-8'))

notes = root / 'EllesmereUIOptions' / 'EUI__General_Options.lua'
raw = notes.read_bytes()
eol = '\r\n' if b'\r\n' in raw else '\n'
text = raw.decode('utf-8')
old_ver = 'version = "Quality of Life %s",' % OLD
new_ver = 'version = "Quality of Life %s",' % NEW
item = ('            { title = "Misdirection / Tricks Helper", desc = "One key casts Misdirection or Tricks of the Trade '
        'on your focus, the tank (typed name, Main Tank or tank role), your friendly target or your pet. '
        'An icon shows who it will go to, the buff timer and the cooldown. Bind it in Key Bindings.", '
        'nav = Nav("EllesmereUIQoL", "Displays", "MISDIRECTION / TRICKS HELPER") },' + eol)
if old_ver in text:
    start = text.index(old_ver)
    head = '        heroes = {' + eol
    heroes = text.index(head, start)
    assert 'version = "' not in text[start + len(old_ver):heroes], 'heroes list belongs to another entry'
    at = heroes + len(head)
    text = text[:at] + item + text[at:]
    text = text.replace(old_ver, new_ver, 1)
assert new_ver in text
notes.write_bytes(text.encode('utf-8'))

handoff = root / 'CODEX_HANDOFF_EllesmereUI_335_CURRENT.md'
text = handoff.read_bytes().decode('utf-8')
a = 'QoL '
if a + OLD + ';' in text:
    text = text.replace(a + OLD + ';', a + NEW + ';', 1)
assert a + NEW + ';' in text
handoff.write_bytes(text.encode('utf-8'))
print('ok')
