"""One-off: Raid Frames 0.20 (Name Outline) TOC bump, README entry, patch note and handoff."""
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent
OLD, NEW = '0.19', '0.20'

toc = root / 'EllesmereUIRaidFrames' / 'EllesmereUIRaidFrames.toc'
raw = toc.read_bytes()
assert not raw.startswith(b'\xef\xbb\xbf')
text = raw.decode('utf-8').replace('## Version: 9.3.4-335-' + OLD, '## Version: 9.3.4-335-' + NEW, 1)
assert '## Version: 9.3.4-335-' + NEW in text
toc.write_bytes(text.encode('utf-8'))

readme = root / 'EllesmereUIRaidFrames' / 'README-335.md'
raw = readme.read_bytes()
eol = '\r\n' if b'\r\n' in raw else '\n'
rows = raw.decode('utf-8').split(eol)
if rows[0].endswith(OLD):
    rows[0] = rows[0][:-len(OLD)] + NEW
assert rows[0].endswith(NEW)
entry = [
    '0.20: nova opção "Name Outline" em TEXT DISPLAY, separada para Raid e Party:',
    'Module Default (segue o contorno da fonte de Raid Frames na página Fonts), None,',
    'Outline, Thick Outline ou Shadow, aplicada só aos nomes. O Retail só tem o',
    'contorno do módulo inteiro.',
    '',
]
if not rows[2].startswith(entry[0]):
    rows[2:2] = entry
readme.write_bytes(eol.join(rows).encode('utf-8'))

notes = root / 'EllesmereUIOptions' / 'EUI__General_Options.lua'
raw = notes.read_bytes()
eol = '\r\n' if b'\r\n' in raw else '\n'
text = raw.decode('utf-8')
old_head = '        version = "Raid Frames %s",%s        heroes = {%s' % (OLD, eol, eol)
new_head = '        version = "Raid Frames %s",%s        heroes = {%s' % (NEW, eol, eol)
item = ('            { title = "Name Outline", desc = "Raid and party names each get their own outline: '
        'None, Outline, Thick Outline, Shadow, or the Raid Frames font default.", '
        'nav = Nav("EllesmereUIRaidFrames", "Raid", "TEXT DISPLAY", "Name Outline") },' + eol)
if old_head in text:
    text = text.replace(old_head, new_head + item, 1)
assert new_head in text
notes.write_bytes(text.encode('utf-8'))

handoff = root / 'CODEX_HANDOFF_EllesmereUI_335_CURRENT.md'
raw = handoff.read_bytes()
text = raw.decode('utf-8')
before = text
for a in ('Raid Frames ' + OLD + ';', 'Raid Frames ' + OLD + ','):
    text = text.replace(a, a.replace(OLD, NEW), 1)
assert text != before, 'handoff Raid Frames version not found'
handoff.write_bytes(text.encode('utf-8'))
print('ok')
