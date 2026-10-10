"""One-off: adds the Luxthos XP bar pieces to the Action Bars 0.21 README entry and patch note."""
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent

readme = root / 'EllesmereUIActionBars' / 'README-335.md'
raw = readme.read_bytes()
eol = '\r\n' if b'\r\n' in raw else '\n'
rows = raw.decode('utf-8').split(eol)
anchor = 'flipbook, Forever): usam atlas que o 3.3.5 não tem.'
extra = [
    'Também na 0.21, o layout da WeakAura "[Merfin] Experience Bar (Luxthos)": itens',
    '"Percent (with Completed)" (50% (65%)) e "Completed % - Rested %" (laranja e azul),',
    'Rested After Quest XP (o rested começa onde termina o overlay de quests), Show',
    'Spark, Show at Max Level (barra cheia com nível e "Time played" no lugar de Time',
    'This Level) e Keep Session on Reload (sessão e XP por hora seguem após um /reload',
    'feito em até cinco minutos; o tempo neste nível é sempre guardado, sem outro',
    '/played). O botão "Apply Luxthos Layout" aplica as sete posições, o gradiente',
    'azul-roxo e as cores da WeakAura. Diferença: quests falhadas não contam como XP',
    'de quests completas.',
]
idx = rows.index(anchor)
if rows[idx + 1] != extra[0]:
    rows[idx + 1:idx + 1] = extra
readme.write_bytes(eol.join(rows).encode('utf-8'))

notes = root / 'EllesmereUIOptions' / 'EUI__General_Options.lua'
raw = notes.read_bytes()
text = raw.decode('utf-8')
old = 'XP per hour, time to level and time played.",'
new = ('XP per hour, time to level and time played. Apply Luxthos Layout recreates the popular '
       'Luxthos XP bar WeakAura, with Show at Max Level, a spark and rested XP after quest XP.",')
if old in text:
    text = text.replace(old, new, 1)
assert new in text
notes.write_bytes(text.encode('utf-8'))
print('ok')
