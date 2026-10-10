"""One-off: Raid Frames 0.23 / Unit Frames 0.25 (single party leader icon) TOC bumps,
README entries, patch-note fixes, handoff versions and the targeted-spells TOC pin."""
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent
notes_path = root / 'EllesmereUIOptions' / 'EUI__General_Options.lua'
handoff_path = root / 'CODEX_HANDOFF_EllesmereUI_335_CURRENT.md'

MODULES = [
    ('EllesmereUIRaidFrames', 'Raid Frames', '0.22', '0.23', [
        '0.23: o ícone de líder aparecia em mais de um membro do grupo. No 3.3.5',
        'UnitIsPartyLeader(unit) pode responder sim para vários; agora o ícone segue',
        'GetPartyLeaderIndex (0 = você, N = partyN) e IsPartyLeader para o jogador, como',
        'os quadros de grupo da Blizzard. Em raide continua o rank de GetRaidRosterInfo.',
        '',
    ], 'The party leader icon shows on the leader only instead of on several party members.'),
    ('EllesmereUIUnitFrames', 'Unit Frames', '0.24', '0.25', [
        '0.25: o ícone de líder dos quadros (player, target, focus) usa',
        'GetPartyLeaderIndex / IsPartyLeader em grupo em vez de UnitIsPartyLeader(unit),',
        'que no 3.3.5 pode marcar mais de um membro. Em raide continua o rank da raide.',
        '',
    ], 'The party leader icon on unit frames shows on the leader only instead of on several party members.'),
]

raw = notes_path.read_bytes()
neol = '\r\n' if b'\r\n' in raw else '\n'
notes = raw.decode('utf-8')
handoff = handoff_path.read_bytes().decode('utf-8')

for folder, label, old, new, entry, fix in MODULES:
    toc = root / folder / (folder + '.toc')
    data = toc.read_bytes()
    assert not data.startswith(b'\xef\xbb\xbf')
    text = data.decode('utf-8').replace('## Version: 9.3.4-335-' + old, '## Version: 9.3.4-335-' + new, 1)
    assert '## Version: 9.3.4-335-' + new in text
    toc.write_bytes(text.encode('utf-8'))

    readme = root / folder / 'README-335.md'
    data = readme.read_bytes()
    eol = '\r\n' if b'\r\n' in data else '\n'
    rows = data.decode('utf-8').split(eol)
    if rows[0].endswith(old):
        rows[0] = rows[0][:-len(old)] + new
    assert rows[0].endswith(new)
    if not rows[2].startswith(entry[0]):
        rows[2:2] = entry
    readme.write_bytes(eol.join(rows).encode('utf-8'))

    old_ver = 'version = "%s %s",' % (label, old)
    new_ver = 'version = "%s %s",' % (label, new)
    if old_ver in notes:
        start = notes.index(old_ver)
        head = '        fixes = {' + neol
        at = notes.index(head, start)
        assert 'version = "' not in notes[start + len(old_ver):at], 'fixes list belongs to another entry'
        at += len(head)
        notes = notes[:at] + '            { text = "%s" },' % fix + neol + notes[at:]
        notes = notes.replace(old_ver, new_ver, 1)
    assert new_ver in notes

    for tail in (';', '.'):
        if label + ' ' + old + tail in handoff:
            handoff = handoff.replace(label + ' ' + old + tail, label + ' ' + new + tail, 1)
    assert label + ' ' + new in handoff

notes_path.write_bytes(notes.encode('utf-8'))
handoff_path.write_bytes(handoff.encode('utf-8'))

pin = root / 'backport-tools' / 'validate_raid_targeted_spells.py'
text = pin.read_bytes().decode('utf-8').replace("335-0.22' in toc", "335-0.23' in toc", 1)
assert "335-0.23' in toc" in text
pin.write_bytes(text.encode('utf-8'))
print('ok')
