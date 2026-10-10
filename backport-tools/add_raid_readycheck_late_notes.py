"""One-off: Raid Frames 0.24 (ready check late answers / initiator) TOC bump, README entry,
patch-note fix, handoff version and the targeted-spells TOC pin."""
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent
OLD, NEW = '0.23', '0.24'
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
    '0.24: ready check no grupo marcava X (não pronto) em quem aceitou e no próprio',
    'iniciador. O cliente pode disparar READY_CHECK_FINISHED antes do último',
    'READY_CHECK_CONFIRM; respostas que chegam depois do fim (dentro dos 10 s) agora',
    'contam, o FINISHED lê GetReadyCheckStatus de cada quadro antes de virar "waiting"',
    'em "notready", e quem iniciou o ready check aparece sempre como pronto. CONFIRM',
    'com nome em vez de unit token é resolvido pelo grupo.',
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
item = ('            { text = "Ready check icons show a green check for players who accepted and for the one who '
        'started the check, instead of a red X when the check ended." },' + eol)
if old_ver in text:
    start = text.index(old_ver)
    head = '        fixes = {' + eol
    at = text.index(head, start)
    assert 'version = "' not in text[start + len(old_ver):at], 'fixes list belongs to another entry'
    at += len(head)
    text = text[:at] + item + text[at:]
    text = text.replace(old_ver, new_ver, 1)
assert new_ver in text
notes.write_bytes(text.encode('utf-8'))

handoff = root / 'CODEX_HANDOFF_EllesmereUI_335_CURRENT.md'
text = handoff.read_bytes().decode('utf-8')
a = 'Raid Frames '
if a + OLD + ';' in text:
    text = text.replace(a + OLD + ';', a + NEW + ';', 1)
assert a + NEW + ';' in text
handoff.write_bytes(text.encode('utf-8'))

pin = root / 'backport-tools' / 'validate_raid_targeted_spells.py'
text = pin.read_bytes().decode('utf-8').replace("335-%s' in toc" % OLD, "335-%s' in toc" % NEW, 1)
assert "335-%s' in toc" % NEW in text
pin.write_bytes(text.encode('utf-8'))
print('ok')
