"""One-off: right-click menus without Set/Clear Focus (blocked action on 3.3.5).
Core 0.65, Raid Frames 0.22, Unit Frames 0.23: TOC bumps, README entries, patch-note
fix items, handoff versions and the targeted-spells validator pin."""
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent

MODULES = [
    {
        'folder': 'EllesmereUI', 'toc_prefix': '## Version: 3.3.5-core-', 'old': '0.64', 'new': '0.65',
        'label': 'Core', 'handoff': 'Core ',
        'readme': [
            '0.65: novo EUI_UnitMenu_335.lua com EllesmereUI.UnitMenuWithoutFocus(dropdown).',
            'Menus de unidade abertos por addon rodam com taint no 3.3.5, e Set Focus /',
            'Clear Focus chamam FocusUnit/ClearFocus protegidos ("blocked from an action',
            'only available to the Blizzard UI"). Um hooksecurefunc em UnitPopup_HideButtons',
            'zera esses itens em UnitPopupShown só nos menus registrados; os menus da',
            'Blizzard ficam iguais (HideButtons reescreve todos os slots a cada chamada).',
        ],
        'fix': 'Right-click menus from EUI frames no longer offer Set Focus or Clear Focus, which the Wrath client blocks from addons.',
    },
    {
        'folder': 'EllesmereUIRaidFrames', 'toc_prefix': '## Version: 9.3.4-335-', 'old': '0.21', 'new': '0.22',
        'label': 'Raid Frames', 'handoff': 'Raid Frames ',
        'readme': [
            '0.22: o menu de clique direito dos quadros de raide/grupo oferecia Set Focus, que',
            'o cliente bloqueia vindo de addon (popup "EllesmereUIRaidFrames has been',
            'blocked"). O menu agora se registra em EllesmereUI.UnitMenuWithoutFocus (Core',
            '0.65) e não mostra Set Focus / Clear Focus. Para focar, use Click Casting',
            '(ação Focus) ou uma macro /focus.',
        ],
        'fix': 'Choosing Set Focus from the raid or party frame menu no longer triggers the 'blocked from an action' popup; the entry is gone, use a Click Casting Focus binding instead.',
    },
    {
        'folder': 'EllesmereUIUnitFrames', 'toc_prefix': '## Version: 9.3.4-335-', 'old': '0.22', 'new': '0.23',
        'label': 'Unit Frames', 'handoff': 'Unit Frames ',
        'readme': [
            '0.23: o menu de clique direito dos unit frames oferecia Set Focus / Clear Focus,',
            'bloqueados pelo cliente quando vêm de addon. O menu agora se registra em',
            'EllesmereUI.UnitMenuWithoutFocus (Core 0.65) e esconde os dois itens.',
        ],
        'fix': 'The unit frame right-click menu no longer offers Set Focus or Clear Focus, which caused a 'blocked from an action' popup.',
    },
]

notes = root / 'EllesmereUIOptions' / 'EUI__General_Options.lua'
handoff = root / 'CODEX_HANDOFF_EllesmereUI_335_CURRENT.md'
notes_raw = notes.read_bytes()
notes_eol = '\r\n' if b'\r\n' in notes_raw else '\n'
notes_text = notes_raw.decode('utf-8')
handoff_text = handoff.read_bytes().decode('utf-8')

for m in MODULES:
    old, new, folder = m['old'], m['new'], m['folder']

    toc = root / folder / (folder + '.toc')
    raw = toc.read_bytes()
    assert not raw.startswith(b'\xef\xbb\xbf')
    text = raw.decode('utf-8').replace(m['toc_prefix'] + old, m['toc_prefix'] + new, 1)
    assert m['toc_prefix'] + new in text, folder
    toc.write_bytes(text.encode('utf-8'))

    readme = root / folder / 'README-335.md'
    raw = readme.read_bytes()
    eol = '\r\n' if b'\r\n' in raw else '\n'
    rows = raw.decode('utf-8').split(eol)
    if rows[0].endswith(old):
        rows[0] = rows[0][:-len(old)] + new
    assert rows[0].endswith(new), folder
    entry = m['readme'] + ['']
    if not rows[2].startswith(entry[0]):
        rows[2:2] = entry
    readme.write_bytes(eol.join(rows).encode('utf-8'))

    old_ver = 'version = "%s %s",' % (m['label'], old)
    new_ver = 'version = "%s %s",' % (m['label'], new)
    if old_ver in notes_text:
        start = notes_text.index(old_ver)
        head = '        fixes = {' + notes_eol
        fixes = notes_text.index(head, start)
        assert 'version = "' not in notes_text[start + len(old_ver):fixes], 'fixes list belongs to another entry'
        at = fixes + len(head)
        item = '            { text = "%s" },' % m['fix'] + notes_eol
        notes_text = notes_text[:at] + item + notes_text[at:]
        notes_text = notes_text.replace(old_ver, new_ver, 1)
    assert new_ver in notes_text, m['label']

    for sep in (';', '.'):
        if m['handoff'] + old + sep in handoff_text:
            handoff_text = handoff_text.replace(m['handoff'] + old + sep, m['handoff'] + new + sep, 1)
    assert m['handoff'] + new + ';' in handoff_text or m['handoff'] + new + '.' in handoff_text, m['label']

notes.write_bytes(notes_text.encode('utf-8'))
handoff.write_bytes(handoff_text.encode('utf-8'))

pin = root / 'backport-tools' / 'validate_raid_targeted_spells.py'
text = pin.read_bytes().decode('utf-8')
text = text.replace("'## Version: 9.3.4-335-0.21'", "'## Version: 9.3.4-335-0.22'", 1)
assert "'## Version: 9.3.4-335-0.22'" in text
pin.write_bytes(text.encode('utf-8'))
print('ok')
