"""Remove the old bottom Uninstall EUI and Reset ALL buttons from the Global
Settings General page; Retail 9.4 moved both into the top action card row.

Cuts from the Uninstall block's spacer line through the end of the Reset ALL
`do` block (the line before `return math.abs(y)`), keeping CRLF endings.
"""
from pathlib import Path

path = Path(__file__).resolve().parents[1] / 'EllesmereUIOptions' / 'EUI__General_Options.lua'
data = path.read_bytes()
text = data.decode('utf-8')

start_marker = ('        -- Uninstall EUI: puts back the game settings EllesmereUI changed, turns its\r\n'
                '        -- addons off for this character and reloads (EllesmereUI_Uninstall_335.lua).\r\n'
                '        y = y - 30  -- spacer\r\n')
end_marker = ('            y = y - BTN_H\r\n'
              '        end\r\n'
              '\r\n'
              '        return math.abs(y)\r\n')

assert text.count(start_marker) == 1, 'start marker'
assert text.count(end_marker) == 1, 'end marker'
s = text.index(start_marker)
e = text.index(end_marker)
assert s < e
removed = text[s:e + len(end_marker)]
assert 'Reset ALL EUI Addon Settings' in removed and removed.count('\r\n') < 200
text = text[:s] + '        return math.abs(y)\r\n' + text[e + len(end_marker):]
path.write_bytes(text.encode('utf-8'))
print('removed', removed.count('\r\n'), 'lines')
