"""One-off: Action Bars 0.21 (XP bar overhaul) TOC bump, README entry, patch notes and handoff."""
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent
OLD, NEW = '0.20', '0.21'

toc = root / 'EllesmereUIActionBars' / 'EllesmereUIActionBars.toc'
raw = toc.read_bytes()
assert not raw.startswith(b'\xef\xbb\xbf')
eol = '\r\n' if b'\r\n' in raw else '\n'
text = raw.decode('utf-8').replace('## Version: 9.3.4-335-' + OLD, '## Version: 9.3.4-335-' + NEW, 1)
assert '## Version: 9.3.4-335-' + NEW in text
toc.write_bytes(text.encode('utf-8'))

readme = root / 'EllesmereUIActionBars' / 'README-335.md'
raw = readme.read_bytes()
assert not raw.startswith(b'\xef\xbb\xbf')
eol = '\r\n' if b'\r\n' in raw else '\n'
rows = raw.decode('utf-8').split(eol)
if rows[0].endswith(OLD):
    rows[0] = rows[0][:-len(OLD)] + NEW
assert rows[0].endswith(NEW)
entry = [
    '0.21: barra de experiência do Retail (Menu, Bags & XP Bars). Fill Style (plano ou',
    'gradiente horizontal/vertical) com cor do XP e cor final, fundo com cor e opacidade,',
    'Show Rested XP com cor própria. Quest XP Overlay: XP das quests completas à frente',
    'do preenchimento (verde) e das incompletas depois (dourado), com Completed Quests',
    'Only e Current Zone Only. Show Dividers: linha a cada 10% e marca a cada 5% (Dashed,',
    'Dotted, Solid ou None), Smart Ticks esconde as marcas já passadas e Divider Text',
    'escreve 10%..90%. EXPERIENCE BAR TEXT: sete posições (centro, esquerda, direita e',
    'os quatro cantos fora da barra), cada uma mostrando um item: XP e Rested % (o texto',
    'antigo, padrão do centro), porcentagem, valores, restante, rested, XP das quests',
    'completas, nível, XP por hora, tempo para upar, tempo nesta sessão e tempo neste',
    'nível. Tooltip mostra o restante, as quests completas e o XP por hora.',
    'Wrath: o XP das quests vem da entrada selecionada do quest log (a seleção é',
    'restaurada) e quests sob cabeçalhos recolhidos não contam. Time This Level pede',
    '/played uma vez por sessão (o jogo imprime as duas linhas no chat). A sessão e o XP',
    'por hora recomeçam no /reload. Sem os estilos de arte do Retail (Professions,',
    'flipbook, Forever): usam atlas que o 3.3.5 não tem.',
    '',
]
if not rows[2].startswith(entry[0]):
    rows[2:2] = entry
readme.write_bytes(eol.join(rows).encode('utf-8'))

notes = root / 'EllesmereUIOptions' / 'EUI__General_Options.lua'
raw = notes.read_bytes()
eol = '\r\n' if b'\r\n' in raw else '\n'
text = raw.decode('utf-8')
old_head = '        version = "Action Bars %s",%s        heroes = {%s' % (OLD, eol, eol)
new_head = '        version = "Action Bars %s",%s        heroes = {%s' % (NEW, eol, eol)
block = eol.join([
    '            {',
    '                title = "Experience Bar Overhaul",',
    '                desc  = "The XP bar gets Retail\'s Quest XP Overlay (completed quests in green, incomplete in gold), dividers with Smart Ticks, gradient fills, background and rested colors, and seven text positions showing values, completed quest XP, XP per hour, time to level and time played.",',
    '                nav   = Nav("EllesmereUIActionBars", "Menu, Bags & XP Bars", "EXPERIENCE BAR"),',
    '            },',
]) + eol
if old_head in text:
    text = text.replace(old_head, new_head + block, 1)
assert new_head in text
notes.write_bytes(text.encode('utf-8'))

handoff = root / 'CODEX_HANDOFF_EllesmereUI_335_CURRENT.md'
text = handoff.read_bytes().decode('utf-8')
if 'Action Bars ' + OLD + ';' in text:
    text = text.replace('Action Bars ' + OLD + ';', 'Action Bars ' + NEW + ';', 1)
assert 'Action Bars ' + NEW + ';' in text
handoff.write_bytes(text.encode('utf-8'))
print('ok')
