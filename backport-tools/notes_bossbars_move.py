"""One-off: QoL 0.13 notes for moving "hide DBM/BigWigs bars under AbilityTimeline"
out of EUI and into AbilityTimeline's own Sources options."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def load(rel):
    data = (ROOT / rel).read_bytes().decode('utf-8')
    return data, ('\r\n' if '\r\n' in data else '\n')


def save(rel, data):
    (ROOT / rel).write_bytes(data.encode('utf-8'))


toc = ROOT / 'EllesmereUIQoL/EllesmereUIQoL.toc'
raw = toc.read_bytes()
if b'## Version: 9.3.4-335-0.13' not in raw:
    assert raw.count(b'## Version: 9.3.4-335-0.12') == 1
    toc.write_bytes(raw.replace(b'## Version: 9.3.4-335-0.12', b'## Version: 9.3.4-335-0.13'))

readme, eol = load('EllesmereUIQoL/README-335.md')
entry = [
    '0.13: esconder as barras do DBM/BigWigs com o AbilityTimeline ativo saiu do',
    'EUI (seção BOSS MOD BARS do Raid Tools e `EUI_QoL_335_BossBars.lua`) e foi',
    'para o próprio AbilityTimeline, como no Retail: AbilityTimeline > Sources >',
    '"Hide DBM bars" / "Hide BigWigs bars" (`BossBars.lua`, AbilityTimeline',
    '335-0.2). Teste: `validate_abilitytimeline_bossbars.py`.',
]
lines = readme.split(eol)
if entry[0] not in lines:
    assert lines[0].endswith('0.12'), lines[0]
    lines[0] = lines[0][:-4] + '0.13'
    lines[2:2] = entry + ['']
    save('EllesmereUIQoL/README-335.md', eol.join(lines))

notes, eol = load('EllesmereUIOptions/EUI__General_Options.lua')
if 'version = "Quality of Life 0.13"' not in notes:
    hero = eol.join([
        '            {',
        '                title = "Hide Boss Mod Bars Under AbilityTimeline",',
        '                desc  = "While AbilityTimeline shows DBM or BigWigs timers, their own bars turn invisible and click-through. Timers keep running, nothing in DBM or BigWigs settings changes, and the bars return when the timeline or the option is turned off.",',
        '                nav   = Nav("EllesmereUIQoL", "Raid Tools"),',
        '            },',
    ]) + eol
    assert notes.count(hero) == 1
    notes = notes.replace(hero, '')
    old_line = '            { module = "Quality of Life", text = "Raid Tools has a BOSS MOD BARS section with Hide DBM/BigWigs Bars While Timeline Is Active and a status line." },'
    new_line = '            { module = "Quality of Life", text = "Raid Tools no longer has a BOSS MOD BARS section: AbilityTimeline\'s Sources options hide DBM and BigWigs bars." },'
    assert notes.count(old_line) == 1
    notes = notes.replace(old_line, new_line)
    head = '        version = "Quality of Life 0.12",'
    assert notes.count(head) == 1
    start = notes.index(head)
    notes = notes.replace(head, '        version = "Quality of Life 0.13",', 1)
    anchor = '        fixes = {' + eol
    at = notes.index(anchor, start) + len(anchor)
    fix = ('            { text = "Hiding DBM and BigWigs bars while AbilityTimeline is active moved to AbilityTimeline itself, as on Retail: '
           'Hide DBM bars and Hide BigWigs bars on its Sources page. The Raid Tools option is gone." },' + eol)
    notes = notes[:at] + fix + notes[at:]
    save('EllesmereUIOptions/EUI__General_Options.lua', notes)

handoff, eol = load('CODEX_HANDOFF_EllesmereUI_335_CURRENT.md')
if 'QoL 0.13;' not in handoff:
    assert handoff.count('QoL 0.12;') == 1
    save('CODEX_HANDOFF_EllesmereUI_335_CURRENT.md', handoff.replace('QoL 0.12;', 'QoL 0.13;'))
print('boss bars move noted')
