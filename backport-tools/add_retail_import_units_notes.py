"""One-off: Nameplates 0.17 / QoL 0.19 (Retail scale units: target nameplate scale,
Raid Tools scale) TOC bumps, README entries, patch-note fixes, handoff versions, plus
an amendment to the Core 0.66 README entry (no bump)."""
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent
notes_path = root / 'EllesmereUIOptions' / 'EUI__General_Options.lua'
handoff_path = root / 'CODEX_HANDOFF_EllesmereUI_335_CURRENT.md'

MODULES = [
    ('EllesmereUINameplates', 'Nameplates', '0.16', '0.17', [
        '0.17: Scale Target Nameplate (targetScale) é multiplicador no port (1-1.5), mas',
        'o Retail guarda porcentagem (100). Um perfil do Retail importado deixava a',
        'placa do alvo 100x maior, cobrindo a tela. Valores acima de 5 agora são lidos',
        'como porcentagem e a escala fica entre 0.5 e 2; o import do Core 0.66 converte.',
        '',
    ], 'A profile imported from Retail no longer blows the target nameplate up to fill the screen.'),
    ('EllesmereUIQoL', 'Quality of Life', '0.18', '0.19', [
        '0.19: a escala do Raid Tools é porcentagem no port (100), mas o Retail guarda',
        'multiplicador (1), que virava 1% e era travado em 0.5. Valores até 5 agora são',
        'lidos como multiplicador; o import do Core 0.66 converte.',
        '',
    ], 'Raid Tools keeps its size after importing a Retail profile.'),
]
HANDOFF = {'Nameplates': 'Nameplates', 'Quality of Life': 'QoL'}

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
        nxt = notes.find('version = "', start + len(old_ver))
        head = '        fixes = {' + neol
        at = notes.find(head, start)
        item = '            { text = "%s" },' % fix + neol
        if at != -1 and (nxt == -1 or at < nxt):
            at += len(head)
            notes = notes[:at] + item + notes[at:]
        else:
            at = start + len(old_ver) + len(neol)
            notes = notes[:at] + head + item + '        },' + neol + notes[at:]
        notes = notes.replace(old_ver, new_ver, 1)
    assert new_ver in notes

    short = HANDOFF[label]
    for tail in (';', '.'):
        if short + ' ' + old + tail in handoff:
            handoff = handoff.replace(short + ' ' + old + tail, short + ' ' + new + tail, 1)
    assert short + ' ' + new in handoff

notes_path.write_bytes(notes.encode('utf-8'))
handoff_path.write_bytes(handoff.encode('utf-8'))

core = root / 'EllesmereUI' / 'README-335.md'
data = core.read_bytes()
eol = '\r\n' if b'\r\n' in data else '\n'
rows = data.decode('utf-8').split(eol)
amend = ['Valores com unidade diferente são convertidos no import: Nameplates targetScale',
         '(porcentagem no Retail, multiplicador aqui) e QoL raidTools.scale (o contrário).']
if amend[0] not in rows:
    at = rows.index('', 2)
    rows[at:at] = amend
core.write_bytes(eol.join(rows).encode('utf-8'))
print('ok')
