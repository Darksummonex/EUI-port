"""One-off: route the Unit Frames visibility drivers through ns.Wrath's 3.3.5 adapter
(RegisterAttributeDriver/UnregisterAttributeDriver do not exist on 3.3.5)."""
import re
from pathlib import Path

path = Path(__file__).resolve().parent.parent / 'EllesmereUIUnitFrames' / 'EllesmereUIUnitFrames.lua'
data = path.read_bytes().decode('utf-8')
new, n = re.subn(r'(?<![\w.])(Unregister|Register)AttributeDriver\(', r'ns.Wrath.\1AttributeDriver(', data)
print('replaced', n)
if n:
    path.write_bytes(new.encode('utf-8'))
