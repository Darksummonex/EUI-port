"""One-off: Unit Frames 0.24 (focus frame Clear Focus Click) TOC bump, README entry,
patch-note hero and handoff version."""
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent
OLD, NEW = '0.23', '0.24'
FOLDER = 'EllesmereUIUnitFrames'

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
    '0.24: opção Clear Focus Click na página do Focus (Shift/Ctrl/Alt + Right Click,',
    'Middle Click, Shift + Left Click ou None; padrão Shift + Right Click). Grava',
    'atributos seguros no quadro do focus (<mod>type<n>=macro, macrotext=/clearfocus),',
    'então funciona em combate, onde o Clear Focus do menu fica escondido. Mudanças em',
    'combate esperam PLAYER_REGEN_ENABLED; ReloadFrames reaplica (troca de perfil).',
    '',
]
if not rows[2].startswith(entry[0]):
    rows[2:2] = entry
readme.write_bytes(eol.join(rows).encode('utf-8'))

notes = root / 'EllesmereUIOptions' / 'EUI__General_Options.lua'
raw = notes.read_bytes()
eol = '\r\n' if b'\r\n' in raw else '\n'
text = raw.decode('utf-8')
old_ver = 'version = "Unit Frames %s",' % OLD
new_ver = 'version = "Unit Frames %s",' % NEW
item = ('            { title = "Clear Focus Click", desc = "Clear your focus by clicking the focus frame '
        '(Shift + Right Click by default, or Ctrl/Alt + Right Click, Middle Click, Shift + Left Click). '
        'Set it on the Focus frame page. Works in combat.", nav = Nav("EllesmereUIUnitFrames", "Main Frames") },' + eol)
if old_ver in text:
    start = text.index(old_ver)
    head = '        heroes = {' + eol
    heroes = text.index(head, start)
    assert 'version = "' not in text[start + len(old_ver):heroes], 'heroes list belongs to another entry'
    at = heroes + len(head)
    text = text[:at] + item + text[at:]
    text = text.replace(old_ver, new_ver, 1)
assert new_ver in text
notes.write_bytes(text.encode('utf-8'))

handoff = root / 'CODEX_HANDOFF_EllesmereUI_335_CURRENT.md'
text = handoff.read_bytes().decode('utf-8')
a = 'Unit Frames '
if a + OLD + '.' in text:
    text = text.replace(a + OLD + '.', a + NEW + '.', 1)
assert a + NEW + '.' in text
handoff.write_bytes(text.encode('utf-8'))
print('ok')
