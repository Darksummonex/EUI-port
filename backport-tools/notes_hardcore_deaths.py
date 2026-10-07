"""One-off: Chat 0.46 / Options 0.98 notes for the hardcore death announcement filter."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def load(rel):
    data = (ROOT / rel).read_bytes().decode('utf-8')
    return data, ('\r\n' if '\r\n' in data else '\n')


def save(rel, data):
    (ROOT / rel).write_bytes(data.encode('utf-8'))


for rel, old, new in [('EllesmereUIChat/EllesmereUIChat.toc', '0.45', '0.46'),
                      ('EllesmereUIOptions/EllesmereUIOptions.toc', '0.97', '0.98')]:
    raw = (ROOT / rel).read_bytes()
    o, n = f'## Version: 9.3.4-335-{old}'.encode(), f'## Version: 9.3.4-335-{new}'.encode()
    if n not in raw:
        assert raw.count(o) == 1, rel
        (ROOT / rel).write_bytes(raw.replace(o, n))

READMES = {
    'EllesmereUIChat/README-335.md': ('0.45', '0.46', [
        '0.46: filtro de mortes do Hardcore em Chat > Spam Filter > HARDCORE. Esconde',
        'anúncios do servidor como "Warrash the level 11 Gnome Warrior has been slain',
        'by Sergeant Brashclaw in Westfall" (mensagens de sistema, emotes, BG e canais;',
        'has been slain/killed, has died, has drowned, has fallen, has burned, was',
        'slain/killed). "Keep Deaths From Level" mantém visíveis mortes a partir de um',
        'nível (81 esconde todas). Desligado por padrão; chat de jogadores não é afetado.',
    ]),
    'EllesmereUIOptions/README-335.md': ('0.97', '0.98', [
        '0.98: seção HARDCORE em Chat > Spam Filter com "Filter Hardcore Deaths" e',
        '"Keep Deaths From Level".',
    ]),
}
for rel, (old, new, entry) in READMES.items():
    data, eol = load(rel)
    lines = data.split(eol)
    if entry[0] in lines:
        continue
    assert lines[0].endswith(old), lines[0]
    lines[0] = lines[0][:-len(old)] + new
    lines[2:2] = entry + ['']
    save(rel, eol.join(lines))

notes, eol = load('EllesmereUIOptions/EUI__General_Options.lua')
FEATURE = {
    ('Chat 0.45', 'Chat 0.46'): None,
    ('Options 0.97', 'Options 0.98'): 'Chat',
}
TITLE = 'Hardcore Death Filter'
DESC = ('Hide server announcements such as \\"Name the level 11 Gnome Warrior has been slain by ... in Westfall\\", '
        'optionally keeping deaths from a chosen level up visible.')
if 'version = "Chat 0.46"' not in notes:
    for (old, new), module in FEATURE.items():
        head = f'        version = "{old}",'
        assert notes.count(head) == 1, head
        start = notes.index(head)
        notes = notes.replace(head, f'        version = "{new}",', 1)
        nxt = notes.find(eol + '        version = "', start + len(head))
        anchor = '        features = {' + eol
        at = notes.find(anchor, start)
        assert at != -1 and (nxt == -1 or at < nxt), (old, 'no features list')
        at += len(anchor)
        item = ['            {']
        if module:
            item += [f'                module = "{module}",', f'                title  = "{TITLE}",', f'                desc   = "{DESC}",',
                     '                nav    = Nav("EllesmereUIChat", "Spam Filter"),']
        else:
            item += [f'                title = "{TITLE}",', f'                desc  = "{DESC}",',
                     '                nav   = Nav("EllesmereUIChat", "Spam Filter"),']
        item.append('            },')
        notes = notes[:at] + eol.join(item) + eol + notes[at:]
    save('EllesmereUIOptions/EUI__General_Options.lua', notes)

handoff, eol = load('CODEX_HANDOFF_EllesmereUI_335_CURRENT.md')
for old, new in [('Chat 0.45;', 'Chat 0.46;'), ('Options 0.97;', 'Options 0.98;')]:
    if new not in handoff:
        assert handoff.count(old) == 1, old
        handoff = handoff.replace(old, new)
save('CODEX_HANDOFF_EllesmereUI_335_CURRENT.md', handoff)
print('hardcore death notes written')
