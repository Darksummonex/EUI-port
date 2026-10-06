"""Unlock Mode movers must stay under the cog/snap click-catcher on Wrath's frame-level cap."""
from pathlib import Path
import re
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

source = (root / 'EllesmereUI/EUI_UnlockMode.lua').read_text(encoding='utf-8-sig')
start = 'local mover = CreateFrame("Button", nil, unlockFrame)'
end = '-- Party Frames always render above Raid Frames in unlock mode'
block = source.split(start, 1)[1].split(end, 1)[0]
assert 'EUI_WOW_335' in block and 'SetFrameLevel' in block, 'Wrath mover level clamp missing'
create = source.split(start, 1)[1]
assert create.index(end) < create.index('mover:SetFrameLevel(MOVER_BASE_LEVEL)'), 'Clamp installed after the first level write'

# The levels the clamp has to stay under, and the hover boost that overflows them.
catchers = [int(v) for v in re.findall(r'(?:cogClickCatcher|snapClickCatcher):SetFrameLevel\((\d+)\)', source)]
menus = [int(v) for v in re.findall(r'(?:cogMenu|snapMenu):SetFrameLevel\((\d+)\)', source)]
assert catchers and menus, (catchers, menus)
catcher, menu = min(catchers), min(menus)
assert 'self:SetFrameLevel(self._raisedLevel + 100)' in source
cog_step = int(re.search(r'self\._cogBtn:SetFrameLevel\(self:GetFrameLevel\(\) \+ (\d+)\)', source).group(1))

lua = LuaRuntime()
lua.execute((root / 'backport-tools/wrath_mock.lua').read_text())
lua.execute('''
local m=getmetatable(UIParent).__index
function m:SetFrameLevel(l) self.level=math.min(l,255) end
function m:GetFrameLevel() return self.level or 0 end
unlockFrame=CreateFrame('Frame',nil,UIParent)
''')
make = lua.eval('function(wrath) EUI_WOW_335=wrath; local mover=CreateFrame("Button",nil,unlockFrame)\n'
                + block + '\nreturn mover end')

wrath = make(True)
# SortMoverFrameLevels: BASE = unlock level + 20; raised = BASE + i + N + 5; hover +100.
for count in (40, 80, 140):
    smallest = 2 + 20 + count
    hovered = smallest + count + 5 + 100
    wrath.SetFrameLevel(wrath, hovered)
    level = wrath.GetFrameLevel(wrath)
    assert level < catcher and level + cog_step < catcher, (count, level, catcher)
    assert level < menu, (count, level, menu)
wrath.SetFrameLevel(wrath, 30)
assert wrath.GetFrameLevel(wrath) == 30, 'Normal mover levels changed'

retail = make(False)
retail.SetFrameLevel(retail, 300)
assert retail.GetFrameLevel(retail) == 255, 'Clamp leaked outside Wrath'
print('PASS: Wrath movers and cogs stay below the click-catcher (%d) and menu (%d) for 40/80/140 movers; '
      'normal levels and non-Wrath unchanged.' % (catcher, menu))
