"""Report direct calls to 3.3.5 protected (Blizzard-only) functions in every file the
EllesmereUI TOCs load. Comments and string contents (secure snippets) are skipped, since
restricted-environment snippets may call some of these legitimately."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PROTECTED = [
    'CastSpell', 'CastSpellByName', 'CastSpellByID', 'UseAction', 'UseItemByName', 'UseInventoryItem',
    'TargetUnit', 'AssistUnit', 'FocusUnit', 'ClearTarget', 'ClearFocus', 'AttackTarget', 'StartAttack',
    'StopAttack', 'PetAttack', 'CastPetAction', 'SpellStopCasting', 'SpellStopTargeting', 'SpellTargetUnit',
    'CancelShapeshiftForm', 'CastShapeshiftForm', 'CancelUnitBuff', 'RunMacro', 'RunMacroText', 'Logout',
    'Quit', 'ForceQuit', 'InteractUnit', 'CallCompanion', 'UseQuestLogSpecialItem', 'ChangeActionBarPage',
    'JumpOrAscendStart', 'TargetNearestEnemy', 'TargetNearestFriend', 'TogglePetAutocast', 'PetFollow',
    'PetStay', 'PetPassiveMode', 'PetDefensiveMode', 'PetAggressiveMode', 'TargetTotem', 'DestroyTotem',
    'CancelItemTempEnchantment', 'Stuck', 'ReplaceEnchant', 'TurnOrActionStart', 'CameraOrSelectOrMoveStart',
]
CALL = re.compile(r'(?<![\w.:])(' + '|'.join(PROTECTED) + r')\s*\(')


def strip(src):
    src = re.sub(r'--\[(=*)\[.*?\]\1\]', '', src, flags=re.S)
    src = re.sub(r'\[(=*)\[.*?\]\1\]', '""', src, flags=re.S)
    out = []
    for line in src.split('\n'):
        line = re.sub(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'', '""', line)
        out.append(line.split('--', 1)[0])
    return out


def loaded_files():
    for toc in sorted(ROOT.glob('EllesmereUI*/EllesmereUI*.toc')):
        if toc.stem != toc.parent.name:
            continue
        for raw in toc.read_text(encoding='utf-8-sig', errors='replace').splitlines():
            rel = raw.strip()
            if not rel or rel.startswith('#') or not rel.lower().endswith('.lua'):
                continue
            path = toc.parent / rel.replace('\\', '/')
            if path.exists():
                yield path


def scan():
    hits = []
    for path in loaded_files():
        for n, line in enumerate(strip(path.read_text(encoding='utf-8', errors='replace')), 1):
            for m in CALL.finditer(line):
                hits.append((str(path.relative_to(ROOT)), n, m.group(1), line.strip()))
    return hits


if __name__ == '__main__':
    found = scan()
    for rel, n, name, line in found:
        print(f'{rel}:{n}: {name}  | {line[:140]}')
    print('hits', len(found))
