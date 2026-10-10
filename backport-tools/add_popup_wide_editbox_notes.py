"""One-off: Blizz UI Enhanced 0.31 (wide popup edit box skin fix) TOC bump, README
entry, patch-note fix item and handoff version."""
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent
OLD, NEW = '0.30', '0.31'
FOLDER = 'EllesmereUIBlizzardSkin'

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
    '0.31: a caixa larga dos popups (Guild Message Of The Day e afins) é mais alta',
    'que a linha de texto; o painel do skin cobria o título e os botões. Agora',
    'enquadra só a linha (24 px, centralizada, 6 px de folga dos lados).',
    '',
]
if not rows[2].startswith(entry[0]):
    rows[2:2] = entry
readme.write_bytes(eol.join(rows).encode('utf-8'))

notes = root / 'EllesmereUIOptions' / 'EUI__General_Options.lua'
raw = notes.read_bytes()
eol = '\r\n' if b'\r\n' in raw else '\n'
text = raw.decode('utf-8')
old_ver = 'version = "Blizz UI Enhanced %s",' % OLD
new_ver = 'version = "Blizz UI Enhanced %s",' % NEW
item = ('            { text = "The Guild Message Of The Day popup (and other wide text popups) no longer '
        'covers its title and buttons with the input box." },' + eol)
if old_ver in text:
    start = text.index(old_ver)
    fixes = text.index('        fixes = {' + eol, start)
    assert 'version = "' not in text[start + len(old_ver):fixes], 'fixes list belongs to another entry'
    at = fixes + len('        fixes = {' + eol)
    text = text[:at] + item + text[at:]
    text = text.replace(old_ver, new_ver, 1)
assert new_ver in text
notes.write_bytes(text.encode('utf-8'))

handoff = root / 'CODEX_HANDOFF_EllesmereUI_335_CURRENT.md'
text = handoff.read_bytes().decode('utf-8')
before = text
a = 'Blizz UI Enhanced (BlizzardSkin) '
if a + OLD + ';' in text:
    text = text.replace(a + OLD + ';', a + NEW + ';', 1)
assert a + NEW + ';' in text
handoff.write_bytes(text.encode('utf-8'))
print('ok')
