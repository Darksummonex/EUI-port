"""One-off: Chat 0.45 / Options 0.97 notes for the spam filter review fixes."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def load(rel):
    data = (ROOT / rel).read_bytes().decode('utf-8')
    return data, ('\r\n' if '\r\n' in data else '\n')


def save(rel, data):
    (ROOT / rel).write_bytes(data.encode('utf-8'))


for rel, old, new in [('EllesmereUIChat/EllesmereUIChat.toc', '0.44', '0.45'),
                      ('EllesmereUIOptions/EllesmereUIOptions.toc', '0.96', '0.97')]:
    raw = (ROOT / rel).read_bytes()
    o, n = f'## Version: 9.3.4-335-{old}'.encode(), f'## Version: 9.3.4-335-{new}'.encode()
    if n not in raw:
        assert raw.count(o) == 1, rel
        (ROOT / rel).write_bytes(raw.replace(o, n))

READMES = {
    'EllesmereUIChat/README-335.md': ('0.44', '0.45', [
        '0.45: correções do filtro de spam. O preset de recrutamento não esconde mais',
        'anúncios de raide com tag de guilda ("<Frost> LF 1 heal ICC25"); só "LF guild"',
        'conta. Sussurros e mensagens de GM (flag GM) sempre aparecem. Palavras-chave',
        'ignoram maiúsculas acentuadas (PROMOÇÃO = promoção) sem depender do locale. Os',
        'presets de comércio e recrutamento seguem a opção Public Chat. Com todos os',
        'filtros desligados, nenhuma mensagem é processada.',
    ]),
    'EllesmereUIOptions/README-335.md': ('0.96', '0.97', [
        '0.97: Chat > Spam Filter: as opções de escopo ficam ativas também com os',
        'presets de comércio/recrutamento ligados, e as dicas explicam que eles seguem',
        'Public Chat, que GMs sempre aparecem e que acentos são ignorados.',
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
FIXES = {
    ('Chat 0.44', 'Chat 0.45'): [
        'The guild recruitment filter no longer hides raid ads that mention a guild, such as \\"<Frost> LF 1 heal ICC25\\"; only LF guild phrases count.',
        'GM whispers and messages are never hidden by the spam filter.',
        'Spam filter keywords ignore case for accented letters too, so promoção also hides PROMOÇÃO.',
        'The trade ad and guild recruitment filters follow the Public Chat setting, and the spam filter does no work while every filter is off.',
    ],
    ('Options 0.96', 'Options 0.97'): [
        'Chat > Spam Filter: the chat type settings stay usable when only the trade or recruitment filter is on, and the tooltips explain what each one covers.',
    ],
}
if 'version = "Chat 0.45"' not in notes:
    for (old, new), items in FIXES.items():
        head = f'        version = "{old}",'
        assert notes.count(head) == 1, head
        start = notes.index(head)
        notes = notes.replace(head, f'        version = "{new}",', 1)
        nxt = notes.find(eol + '        version = "', start + len(head))
        anchor = '        fixes = {' + eol
        at = notes.find(anchor, start)
        assert at != -1 and (nxt == -1 or at < nxt), (old, 'no fixes list')
        at += len(anchor)
        prefix = '{ module = "Chat", text = "' if old.startswith('Options') else '{ text = "'
        block = ''.join(f'            {prefix}{t}" }},{eol}' for t in items)
        notes = notes[:at] + block + notes[at:]
    save('EllesmereUIOptions/EUI__General_Options.lua', notes)

handoff, eol = load('CODEX_HANDOFF_EllesmereUI_335_CURRENT.md')
for old, new in [('Chat 0.44;', 'Chat 0.45;'), ('Options 0.96;', 'Options 0.97;')]:
    if new not in handoff:
        assert handoff.count(old) == 1, old
        handoff = handoff.replace(old, new)
save('CODEX_HANDOFF_EllesmereUI_335_CURRENT.md', handoff)
print('spam filter fix notes written')
