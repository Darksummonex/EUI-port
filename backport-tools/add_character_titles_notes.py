"""One-off: Blizz UI Enhanced 0.32 (character sheet Titles list) TOC bump, README entry,
patch-note fix item, handoff version and the lootroll validator version pin."""
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent
OLD, NEW = '0.31', '0.32'
FOLDER = 'EllesmereUIBlizzardSkin'

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
    '0.32: a aba Titles da ficha do personagem abria o PlayerTitlePickerFrame da',
    'Blizzard sem a lista montada (vazio). Agora a barra lateral tem a própria lista:',
    'None primeiro e os títulos conhecidos em ordem alfabética (GetNumTitles,',
    'IsTitleKnown, GetTitleName), o atual em dourado, clique chama SetCurrentTitle,',
    'com rolagem pela roda. Atualiza com KNOWN_TITLES_UPDATE, NEW_TITLE_EARNED,',
    'OLD_TITLE_LOST e UNIT_NAME_UPDATE do jogador. O picker nativo não é mais movido.',
    '',
]
if not rows[2].startswith(entry[0]):
    rows[2:2] = entry
readme.write_bytes(eol.join(rows).encode('utf-8'))

notes = root / 'EllesmereUIOptions' / 'EUI__General_Options.lua'
raw = notes.read_bytes()
eol = '\r\n' if b'\r\n' in raw else '\n'
text = raw.decode('utf-8')
old_ver = 'version = "Blizz UI Enhanced %s",' % OLD
new_ver = 'version = "Blizz UI Enhanced %s",' % NEW
item = ('            { text = "The character sheet Titles tab lists your known titles again; '
        'click one to wear it." },' + eol)
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
a = 'Blizz UI Enhanced (BlizzardSkin) '
if a + OLD + ';' in text:
    text = text.replace(a + OLD + ';', a + NEW + ';', 1)
assert a + NEW + ';' in text
handoff.write_bytes(text.encode('utf-8'))

pin = root / 'backport-tools' / 'validate_skins_lootroll.py'
text = pin.read_bytes().decode('utf-8')
text = text.replace("'## Version: 9.3.4-335-%s'" % OLD, "'## Version: 9.3.4-335-%s'" % NEW, 1)
assert "'## Version: 9.3.4-335-%s'" % NEW in text
pin.write_bytes(text.encode('utf-8'))
print('ok')
