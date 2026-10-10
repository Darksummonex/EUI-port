"""One-off: Core 0.66 (Retail profile strings import what the port supports) TOC bump,
README entry, patch-note hero and handoff version."""
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent
OLD, NEW = '0.65', '0.66'

toc = root / 'EllesmereUI' / 'EllesmereUI.toc'
data = toc.read_bytes()
assert not data.startswith(b'\xef\xbb\xbf')
text = data.decode('utf-8').replace('## Version: 3.3.5-core-' + OLD, '## Version: 3.3.5-core-' + NEW, 1)
assert '## Version: 3.3.5-core-' + NEW in text
toc.write_bytes(text.encode('utf-8'))

ENTRY = [
    '0.66: strings de perfil do Retail importam o que existe no port. Novo',
    'EllesmereUI_ProfileImport_335.lua: cada módulo parte das configurações atuais do',
    'port e recebe só valores com a mesma chave e o mesmo tipo (Action Bars renomeia',
    'MainBar/Bar2/PetBar para bar1/bar2/petBar). Módulos só do Retail (Dragon Riding,',
    'Mythic+), specs atribuídas, overrides de spec e feitiços do Cooldown Manager ficam',
    'de fora; âncoras só entre elementos registrados aqui. Exportações do port agora',
    'levam client = "wrath"; strings antigas do port são reconhecidas (bar1/_abRetail,',
    'IDs de spec 33xxx) e importam como antes. O chat mostra quantas opções entraram.',
    '',
]
readme = root / 'EllesmereUI' / 'README-335.md'
data = readme.read_bytes()
eol = '\r\n' if b'\r\n' in data else '\n'
rows = data.decode('utf-8').split(eol)
if rows[0].endswith(OLD):
    rows[0] = rows[0][:-len(OLD)] + NEW
assert rows[0].endswith(NEW)
if not rows[2].startswith(ENTRY[0]):
    rows[2:2] = ENTRY
readme.write_bytes(eol.join(rows).encode('utf-8'))

notes_path = root / 'EllesmereUIOptions' / 'EUI__General_Options.lua'
raw = notes_path.read_bytes()
neol = '\r\n' if b'\r\n' in raw else '\n'
notes = raw.decode('utf-8')
old_ver = 'version = "Core %s",' % OLD
new_ver = 'version = "Core %s",' % NEW
if old_ver in notes:
    start = notes.index(old_ver)
    head = '        heroes = {' + neol
    at = notes.index(head, start)
    assert 'version = "' not in notes[start + len(old_ver):at]
    at += len(head)
    hero = ('            {' + neol +
            '                title = "Import Retail Profiles",' + neol +
            '                desc  = "Profile strings exported from Retail EllesmereUI import everything this client supports: each module keeps its current settings and takes the Retail values it understands. Retail-only modules, spec setups and Cooldown Manager spells are skipped, and chat reports how many settings came in.",' + neol +
            '            },' + neol)
    notes = notes[:at] + hero + notes[at:]
    notes = notes.replace(old_ver, new_ver, 1)
assert new_ver in notes
notes_path.write_bytes(notes.encode('utf-8'))

handoff_path = root / 'CODEX_HANDOFF_EllesmereUI_335_CURRENT.md'
handoff = handoff_path.read_bytes().decode('utf-8')
handoff = handoff.replace('Core %s;' % OLD, 'Core %s;' % NEW, 1)
assert 'Core %s;' % NEW in handoff
handoff_path.write_bytes(handoff.encode('utf-8'))
print('ok')
