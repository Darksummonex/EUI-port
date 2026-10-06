"""One-off: route Unit Frames power colours through ns.UF_PowerColor / ns.UF_PowerInfo,
which return the client's stock PowerBarColor under Classic WoW UI."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EDITS = {
    'EllesmereUIUnitFrames/EllesmereUIUnitFrames.lua': [
        ('EllesmereUI.ResolveUnitPowerColor(unit)', 'ns.UF_PowerColor(unit)'),
        ('EllesmereUI.ResolveUnitPowerColor(u)', 'ns.UF_PowerColor(u)'),
    ],
    'EllesmereUIUnitFrames/EUI_UnitFrames_335_FormBar.lua': [
        ('EllesmereUI.GetPowerColor(S.token)', 'ns.UF_PowerInfo(S.token)'),
    ],
    'EllesmereUIOptions/EUI_UnitFrames_Options.lua': [
        ('EllesmereUI.ResolveUnitPowerColor("player")', 'ns.UF_PowerColor("player")'),
        ('EllesmereUI.GetPowerColor(pToken or "MANA")', 'ns.UF_PowerInfo(pToken or "MANA")'),
        ('EllesmereUI.GetPowerColor(pbToken or "MANA")', 'ns.UF_PowerInfo(pbToken or "MANA")'),
    ],
}

for rel, pairs in EDITS.items():
    path = ROOT / rel
    data = path.read_bytes().decode('utf-8')
    for old, new in pairs:
        n = data.count(old)
        data = data.replace(old, new)
        print(f'{rel}: {old} -> {n}')
    path.write_bytes(data.encode('utf-8'))
