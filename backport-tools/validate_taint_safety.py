"""3.3.5 taint safety across every TOC-loaded EllesmereUI file:
- no direct call to a Blizzard-only (protected) function, except the buff cancels the stock
  buff frame also makes, which 3.3.5 allows out of combat and whose callers skip combat;
- no write to a Blizzard global (that taints it, and Blizzard code reading it afterwards is
  blocked from protected calls in the addon's name: "blocked from an action only available
  to the Blizzard UI");
- the Action Bars paging arrows page through the secure "actionbar" action."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import scan_protected_calls
import scan_blizzard_global_writes

root = scan_protected_calls.ROOT
OUT_OF_COMBAT_OK = {
    ('EllesmereUIQoL\\EUI_QoL_335_Extras.lua', 'CancelUnitBuff'),
    ('EllesmereUIUnitFrames\\EUI_UnitFrames_335_Auras.lua', 'CancelUnitBuff'),
    ('EllesmereUIUnitFrames\\EUI_UnitFrames_335_Auras.lua', 'CancelItemTempEnchantment'),
}
bad = [h for h in scan_protected_calls.scan() if (h[0].replace('/', '\\'), h[2]) not in OUT_OF_COMBAT_OK]
assert not bad, 'protected calls: ' + '; '.join(f'{r}:{n} {name}' for r, n, name, _ in bad)

writes = scan_blizzard_global_writes.scan()
assert not writes, 'Blizzard global writes: ' + '; '.join(f'{r}:{n} {name}' for r, n, name, _ in writes)

qol = (root / 'EllesmereUIQoL/EUI_QoL_335_Extras.lua').read_text(encoding='utf-8')
assert 'or InCombatLockdown() or UnitAffectingCombat("player") then return end' in qol
auras = (root / 'EllesmereUIUnitFrames/EUI_UnitFrames_335_Auras.lua').read_text(encoding='utf-8')
assert 'not self.cancel or InCombatLockdown() then return end' in auras

bars = (root / 'EllesmereUIActionBars/EUI_ActionBars_335.lua').read_text(encoding='utf-8')
arrows = bars[bars.index('local function PagingArrows'):bars.index('local function Layout(d,bar)')]
assert '"SecureActionButtonTemplate"' in arrows and 'SetAttribute("type","actionbar")' in arrows
assert 'Arrow("Up","increment"),Arrow("Down","decrement")' in arrows
assert 'SetScript("OnClick"' not in arrows, 'a Lua OnClick would replace the secure click handler'

print('taint safety OK')
