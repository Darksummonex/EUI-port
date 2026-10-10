"""One-off, no bump: spell 81005 counts as a Sated/Exhaustion lockout. README notes in
Unit Frames, Raid Frames, QoL and Core; patch-note fix items in Unit Frames and Raid Frames."""
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent

READMES = {
    'EllesmereUIUnitFrames': 'Sem bump: "Hide Sated / Exhaustion" também esconde o 81005 (lockout de Bloodlust do servidor).',
    'EllesmereUIRaidFrames': 'Sem bump: "Hide Sated / Exhaustion" também esconde o 81005 (lockout de Bloodlust do servidor).',
    'EllesmereUIQoL': 'Sem bump: o timer Sated / Exhaustion também conta o 81005 (lockout de Bloodlust do servidor).',
    'EllesmereUI': 'Sem bump: o Party Mode também dispara com o 81005 (lockout de Bloodlust do servidor).',
}
for folder, line in READMES.items():
    path = root / folder / 'README-335.md'
    raw = path.read_bytes()
    eol = '\r\n' if b'\r\n' in raw else '\n'
    rows = raw.decode('utf-8').split(eol)
    if rows[2] != line:
        rows[2:2] = [line, '']
    path.write_bytes(eol.join(rows).encode('utf-8'))

notes = root / 'EllesmereUIOptions' / 'EUI__General_Options.lua'
raw = notes.read_bytes()
eol = '\r\n' if b'\r\n' in raw else '\n'
text = raw.decode('utf-8')
item = ('            { text = "Hide Sated / Exhaustion also hides the 81005 Bloodlust lockout debuff." },' + eol)
for version in ('Unit Frames 0.22', 'Raid Frames 0.20'):
    head = 'version = "%s",' % version
    start = text.index(head)
    fixes = text.index('        fixes = {' + eol, start)
    assert 'version = "' not in text[start + len(head):fixes], version
    at = fixes + len('        fixes = {' + eol)
    if not text[at:].startswith(item):
        text = text[:at] + item + text[at:]
notes.write_bytes(text.encode('utf-8'))
print('ok')
