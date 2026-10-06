"""One-off: README entries for the taint fixes (QoL 0.11, Action Bars 0.19, Options 0.93)."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENTRIES = {
    'EllesmereUIQoL': ('0.10', '0.11', [
        '0.11: "EllesmereUIQoL has been blocked from an action only available to the',
        'Blizzard UI". `EUI_QoL_335_Group.lua` fazia `StaticPopupDialogs =',
        'StaticPopupDialogs or {}`: reescrever a global (mesmo com o mesmo valor) a',
        'contamina, e os popups da Blizzard que chamam funções protegidas (Logout,',
        'Quit, Release Spirit...) eram bloqueados em nome do QoL. A linha saiu; só o',
        'campo `EUI335_DISBAND_GROUP` é adicionado.',
    ]),
    'EllesmereUIActionBars': ('0.18', '0.19', [
        '0.19: as setas de página da Barra 1 chamavam `ChangeActionBarPage`, que no',
        '3.3.5 é exclusiva da Blizzard (popup "blocked from an action"). Agora são',
        '`SecureActionButtonTemplate` com `type = "actionbar"` e `action =',
        '"increment"/"decrement"`, a página padrão (1..6) da Blizzard.',
    ]),
    'EllesmereUIOptions': ('0.92', '0.93', [
        '0.93: `tinsert = tinsert or table.insert` reescrevia a global `tinsert` da',
        'Blizzard e a contaminava ao abrir as opções; agora só escreve se faltar.',
        'Novo `validate_taint_safety.py` varre todos os arquivos dos TOCs: nenhuma',
        'chamada direta a função protegida (exceto cancelar buff fora de combate) e',
        'nenhuma escrita em global da Blizzard.',
    ]),
}
for folder, (old, new, added) in ENTRIES.items():
    path = ROOT / folder / 'README-335.md'
    data = path.read_bytes().decode('utf-8')
    eol = '\r\n' if '\r\n' in data else '\n'
    lines = data.split(eol)
    if added[0] in lines:
        print(folder, 'already noted')
        continue
    assert lines[0].endswith(old), lines[0]
    lines[0] = lines[0][:-len(old)] + new
    lines[2:2] = added + ['']
    path.write_bytes(eol.join(lines).encode('utf-8'))
    print(folder, 'noted')
