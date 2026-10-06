"""One-off: README-335 entries for the nil CreateMaskTexture fallback."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENTRIES = {
    'EllesmereUIUnitFrames': ('0.11', '0.12', """0.12: correção para outro jogador: em alguns clientes/addons o
`CreateMaskTexture` existe mas devolve nil, e um `UnitGetTotalAbsorbs` global
faz a barra de absorção ser criada; o frame do jogador parava com "attempt to
index local 'absorbMask'". O shim (EUI_UnitFrames_335.lua) agora devolve uma
textura escondida quando a máscara nativa vem vazia, e `AddMaskTexture` /
`RemoveMaskTexture` nativos nunca recebem essa máscara falsa. Teste:
backport-tools/validate_unitframes.py."""),
    'EllesmereUIOptions': ('0.86', '0.87', """0.87: o compat das opções aplica a mesma proteção: `CreateMaskTexture` nativo
que devolve nil vira uma textura escondida, ignorada por `AddMaskTexture` e
`RemoveMaskTexture`."""),
}

for module, (old, new, entry) in ENTRIES.items():
    path = ROOT / module / 'README-335.md'
    data = path.read_bytes().decode('utf-8')
    eol = '\r\n' if '\r\n' in data else '\n'
    lines = data.split(eol)
    if lines[0].endswith(' ' + new):
        print(f'{module}: already {new}')
        continue
    assert lines[0].endswith(' ' + old), (module, lines[0])
    lines[0] = lines[0][:-len(old)] + new
    assert lines[1] == '', module
    lines[2:2] = entry.split('\n') + ['']
    path.write_bytes(eol.join(lines).encode('utf-8'))
    print(f'{module}: {old} -> {new}')
