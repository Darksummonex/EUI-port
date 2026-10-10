"""One-off: Core 0.64 (Unlock Mode arrow-key nudging on 3.3.5) TOC bump, README entry,
patch-note fix item and handoff version."""
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent
OLD, NEW = '0.63', '0.64'

toc = root / 'EllesmereUI' / 'EllesmereUI.toc'
raw = toc.read_bytes()
assert not raw.startswith(b'\xef\xbb\xbf')
text = raw.decode('utf-8').replace('## Version: 3.3.5-core-' + OLD, '## Version: 3.3.5-core-' + NEW, 1)
assert '## Version: 3.3.5-core-' + NEW in text
toc.write_bytes(text.encode('utf-8'))

readme = root / 'EllesmereUI' / 'README-335.md'
raw = readme.read_bytes()
eol = '\r\n' if b'\r\n' in raw else '\n'
rows = raw.decode('utf-8').split(eol)
if rows[0].endswith(OLD):
    rows[0] = rows[0][:-len(OLD)] + NEW
assert rows[0].endswith(NEW)
entry = [
    '0.64: setas do teclado no Unlock Mode (1 px; Shift = 100 px), como no Retail. O',
    '3.3.5 não propaga teclado (sem SetPropagateKeyboardInput), então em vez de um frame',
    'com EnableKeyboard o EUI335UnlockNudgeButton usa SetOverrideBindingClick só para',
    'UP/DOWN/LEFT/RIGHT e SHIFT-<seta> enquanto o Unlock Mode está aberto, e',
    'ClearOverrideBindings ao fechar ou ao entrar em combate (SuspendForCombat esconde',
    'antes do lockdown; PLAYER_REGEN_ENABLED limpa se sobrou). Com o Unlock Mode aberto',
    'as setas não giram o personagem. Caixas de texto com foco recebem as setas antes.',
    '',
]
if not rows[2].startswith(entry[0]):
    rows[2:2] = entry
readme.write_bytes(eol.join(rows).encode('utf-8'))

notes = root / 'EllesmereUIOptions' / 'EUI__General_Options.lua'
raw = notes.read_bytes()
eol = '\r\n' if b'\r\n' in raw else '\n'
text = raw.decode('utf-8')
old_ver = 'version = "Core %s",' % OLD
new_ver = 'version = "Core %s",' % NEW
item = ('            { text = "Unlock Mode: the arrow keys move the selected element 1 pixel again '
        '(hold Shift for 100)." },' + eol)
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
if 'Core ' + OLD + ';' in text:
    text = text.replace('Core ' + OLD + ';', 'Core ' + NEW + ';', 1)
assert 'Core ' + NEW + ';' in text
handoff.write_bytes(text.encode('utf-8'))
print('ok')
