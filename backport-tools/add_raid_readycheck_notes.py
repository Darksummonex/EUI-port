"""One-off: Raid Frames 0.21 (ready check icon art) TOC bump, README entry, patch-note
fix item, handoff version and the targeted-spells validator version pin."""
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent
OLD, NEW = '0.20', '0.21'
FOLDER = 'EllesmereUIRaidFrames'

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
    '0.21: o ícone de ready check não aparecia: usava Interface\\RaidFrame\\UI-ReadyCheck-*,',
    'que não existe no 3.3.5. Agora usa READY_CHECK_READY/NOT_READY/WAITING_TEXTURE',
    '(Interface\\RaidFrame\\ReadyCheck-Ready, -NotReady, -Waiting).',
    '',
]
if not rows[2].startswith(entry[0]):
    rows[2:2] = entry
readme.write_bytes(eol.join(rows).encode('utf-8'))

notes = root / 'EllesmereUIOptions' / 'EUI__General_Options.lua'
raw = notes.read_bytes()
eol = '\r\n' if b'\r\n' in raw else '\n'
text = raw.decode('utf-8')
old_ver = 'version = "Raid Frames %s",' % OLD
new_ver = 'version = "Raid Frames %s",' % NEW
item = '            { text = "Ready check icons show on raid and party frames again." },' + eol
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
if 'Raid Frames ' + OLD + ';' in text:
    text = text.replace('Raid Frames ' + OLD + ';', 'Raid Frames ' + NEW + ';', 1)
assert 'Raid Frames ' + NEW + ';' in text
handoff.write_bytes(text.encode('utf-8'))

pin = root / 'backport-tools' / 'validate_raid_targeted_spells.py'
text = pin.read_bytes().decode('utf-8')
text = text.replace("'## Version: 9.3.4-335-%s'" % OLD, "'## Version: 9.3.4-335-%s'" % NEW, 1)
assert "'## Version: 9.3.4-335-%s'" % NEW in text
pin.write_bytes(text.encode('utf-8'))
print('ok')
