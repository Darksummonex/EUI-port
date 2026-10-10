"""One-off: version on README line 1 and new Portuguese entry at line 3 for the
easy Retail 9.4 batch (gossip, grid growth, enemy buff filter, Sated, equipped border)."""
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
ENTRIES = {
    'EllesmereUIQoL': ('0.16', [
        '0.16: Auto Select Single Gossip (Retail 9.4). Quando o NPC tem uma única opção',
        'de diálogo, ela é escolhida sozinha. Segurar Shift pula; desligado em',
        'instâncias por padrão; NPCs com missão para pegar ou entregar não são tocados.',
        'Engrenagem "Auto Gossip Settings": Hold Shift to Skip, Disable in Instances e',
        'Ignore Low Level Quests (pula missões triviais, a menos que o Quest Tracker',
        'aceite automaticamente as triviais). Cada diálogo é escolhido uma vez só até',
        'fechar a janela. API Wrath (GetGossipOptions/SelectGossipOption).',
    ]),
    'EllesmereUIRaidFrames': ('0.19', [
        '0.19: novo Group Layout "Down and then Right" (Retail 9.4): dois grupos por',
        'coluna, depois a próxima coluna à direita (raid de 20 vira um bloco 2x2).',
        'Membros correm na horizontal dentro do grupo, como em "Groups Down". Holder,',
        'preview e overlay usam o mesmo cálculo de tamanho.',
    ]),
    'EllesmereUINameplates': ('0.15', [
        '0.15: "Enemy Buff Filter" (Retail 9.4) na seção EXTRA AURA OPTIONS da aba',
        'General: Timed Buffs (padrão; Wrath não tem a flag "important" da Retail),',
        'Only Dispellable e Show All (todos os buffs). Usa os mesmos campos da aba Aura',
        'Filters (Only Timed Auras / Only Stealable Buffs).',
    ]),
    'EllesmereUIUnitFrames': ('0.19', [
        '0.19: filtro "Hide Sated / Exhaustion" (Retail 9.4) na aba Aura Filters. Antes',
        'Sated e Exhaustion eram sempre escondidos; agora dá para mostrar. Ligado por',
        'padrão (debuffHideExhaustion, como na Retail). Raid Frames já tinham o "Hide',
        'Bloodlust Debuff". Player Aura Bars da Retail não existem no port.',
    ]),
    'EllesmereUIActionBars': ('0.20', [
        '0.20: "Show Equipped Item Color" (Retail 9.4) em ICON EFFECTS. Desligado por',
        'padrão: a borda verde redonda da Blizzard em itens equipados some. Ligado: a',
        'borda usa a arte quadrada (ou o formato do botão) na cor da raridade do item,',
        'lida do slot equipado; verde a 50% quando o item não é encontrado.',
    ]),
}

for folder, (version, lines) in ENTRIES.items():
    path = ROOT / folder / 'README-335.md'
    raw = path.read_bytes()
    assert b'\r\n' in raw and not raw.startswith(b'\xef\xbb\xbf'), path
    rows = raw.decode('utf-8').split('\r\n')
    if rows[2].startswith(version + ':'):
        print('already', folder)
        continue
    rows[0] = re.sub(r'[0-9]+\.[0-9]+$', version, rows[0])
    rows[2:2] = lines + ['']
    path.write_bytes('\r\n'.join(rows).encode('utf-8'))
    print(folder, rows[0])
