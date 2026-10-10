"""One-off: TOC bumps, README entries, patch notes and handoff for Bags 0.12 (Junk Marker),
QoL 0.17 (Self Combat Text), Core 0.63 (Uninstall EUI) and Blizz UI Enhanced 0.30
(tooltip buffs, stat hover highlight)."""
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent
ENTRIES = {
    'EllesmereUIBags': ('9.3.4-335-', '0.11', '0.12', [
        '0.12: Junk Marker do Retail. A moeda no cabeçalho das bolsas entra no modo de',
        'marcar: clique nos itens para marcar ou desmarcar como lixo (com um item no',
        'cursor, clicar na moeda marca esse item). Itens cinza e marcados vão para a nova',
        'categoria Junk (sempre a última); desmarcar devolve o item à categoria de onde',
        'veio. Com um vendedor aberto aparece "Sell Junk" ao lado da moeda: vende um item',
        'por vez, pula itens sem preço, de equipment set e fixados, e para se o vendedor',
        'fechar, em combate ou com item no cursor. Na engrenagem, "Show Coin on Junk" põe',
        'uma moedinha no canto dos itens marcados; Desaturate Junk Items vale também',
        'para eles. Desligar o Junk Marker remove a moeda, a categoria e o botão.',
        '',
    ]),
    'EllesmereUIQoL': ('9.3.4-335-', '0.16', '0.17', [
        '0.17: Self Combat Text do Retail (Displays > SELF COMBAT TEXT). Dano recebido,',
        'cura recebida, esquivas/aparos/erros e entrar/sair de combate sobem acima do',
        'player frame no lugar do combat text da Blizzard, que fica oculto enquanto está',
        'ligado. Animação Straight, Fountain ou Static, para cima ou para baixo, distância,',
        'duração, críticos maiores, Stagger Hits, fonte, contorno, sombra, números',
        'abreviados e cor por tipo. Move-se no Unlock Mode. O Wrath não tem C_CombatText',
        'nem animações Path: os valores vêm do combat log (jogador ou veículo como alvo).',
        'Arquivo novo (EUI_QoL_335_CombatText.lua): reinicie o cliente.',
        '',
    ]),
    'EllesmereUI': ('3.3.5-core-', '0.62', '0.63', [
        '0.63: botão "Uninstall EUI" em Global Settings > General, como no Retail: devolve',
        'as configurações do jogo que o EUI mudou (CVars de nameplates, minimapa, chat,',
        'tooltips e tutoriais, tamanho da fonte das janelas de chat e as teclas que o',
        'Quickdraw tomou), desliga os addons EllesmereUI deste personagem e recarrega.',
        'Só volta o que ainda tem o valor do EUI; o que você mudou depois fica. Contas',
        'de antes deste registro voltam os CVars ao padrão do jogo. Os perfis ficam',
        'guardados. Wrath: sem Edit Mode; DisableAddOn vale só para o personagem atual.',
        'Arquivo novo (EllesmereUI_Uninstall_335.lua): reinicie o cliente.',
        '',
    ]),
    'EllesmereUIBlizzardSkin': ('9.3.4-335-', '0.29', '0.30', [
        '0.30: dois recursos do Retail. "Show Player Buffs" mostra os buffs do jogador sob',
        'o mouse como ícones ao lado do tooltip (até 16), com posição, tamanho, ícones',
        'por linha e offsets. "Highlight Items on Stat Hover" (STATS SIDEBAR) faz brilhar',
        'os itens equipados que dão o atributo sob o mouse (Hit, Crit, Haste, Defense,',
        'Strength...), lendo os atributos do próprio item; encantos e gemas não contam.',
        '',
    ]),
}
for folder, (prefix, old, new, lines) in ENTRIES.items():
    toc = root / folder / (folder + '.toc')
    raw = toc.read_bytes()
    assert not raw.startswith(b'\xef\xbb\xbf'), toc
    text = raw.decode('utf-8')
    if '## Version: ' + prefix + old in text:
        text = text.replace('## Version: ' + prefix + old, '## Version: ' + prefix + new, 1)
        toc.write_bytes(text.encode('utf-8'))
    assert '## Version: ' + prefix + new in text, toc

    path = root / folder / 'README-335.md'
    raw = path.read_bytes()
    assert not raw.startswith(b'\xef\xbb\xbf'), path
    eol = '\r\n' if b'\r\n' in raw else '\n'
    rows = raw.decode('utf-8').split(eol)
    if rows[0].endswith(old):
        rows[0] = rows[0][:-len(old)] + new
    assert rows[0].endswith(new), rows[0]
    if not rows[2].startswith(lines[0]):
        rows[2:2] = lines
    path.write_bytes(eol.join(rows).encode('utf-8'))
    print(folder, 'ok')

HEROES = {
    'Bags': ('0.11', '0.12', [
        '            {',
        '                title = "Junk Marker",',
        '                desc  = "A coin in the bag header marks items as junk: click it, then click items. Grey and marked items go to a Junk category, and a Sell Junk button appears next to the coin at merchants. Its cog adds a coin badge on marked items.",',
        '                nav   = Nav("EllesmereUIBags", "Bags"),',
        '            },',
    ]),
    'Quality of Life': ('0.16', '0.17', [
        '            {',
        '                title = "Self Combat Text",',
        '                desc  = "Damage taken, healing, avoids and entering or leaving combat scroll above the player frame instead of Blizzard\'s combat text, with Straight, Fountain or Static animations, colors per type and a mover in Unlock Mode.",',
        '                nav   = Nav("EllesmereUIQoL", "Displays", "SELF COMBAT TEXT"),',
        '            },',
    ]),
    'Core': ('0.62', '0.63', [
        '            {',
        '                title = "Uninstall EUI",',
        '                desc  = "A button on Global Settings puts back the game settings EUI changed (nameplate, minimap, chat and tooltip options, chat font sizes and keys Quickdraw took), then turns EUI off for this character and reloads. Your profiles are kept.",',
        '                nav   = Nav("_EUIGlobal", "General"),',
        '            },',
    ]),
    'Blizz UI Enhanced': ('0.29', '0.30', [
        '            {',
        '                title = "Player Buffs on Tooltips",',
        '                desc  = "Show Player Buffs puts the hovered player\'s buffs as icons beside the tooltip, with position, size, icons per row and offsets.",',
        '                nav   = Nav("EllesmereUIBlizzardSkin", "Tooltips, Menus & Popups", "TOOLTIP INFORMATION", "Show Player Buffs"),',
        '            },',
        '            {',
        '                title = "Stat Hover Highlight",',
        '                desc  = "Hovering a stat in the character sheet sidebar glows the equipped items that give it.",',
        '                nav   = Nav("EllesmereUIBlizzardSkin", "Blizzard Window Skins", "STATS SIDEBAR", "Highlight Items on Stat Hover"),',
        '            },',
    ]),
}
notes = root / 'EllesmereUIOptions' / 'EUI__General_Options.lua'
raw = notes.read_bytes()
eol = '\r\n' if b'\r\n' in raw else '\n'
text = raw.decode('utf-8')
for name, (old, new, block) in HEROES.items():
    old_head = '        version = "%s %s",%s        heroes = {%s' % (name, old, eol, eol)
    new_head = '        version = "%s %s",%s        heroes = {%s' % (name, new, eol, eol)
    if old_head in text:
        text = text.replace(old_head, new_head + eol.join(block) + eol, 1)
    assert new_head in text, name
notes.write_bytes(text.encode('utf-8'))
print('patch notes ok')

handoff = root / 'CODEX_HANDOFF_EllesmereUI_335_CURRENT.md'
raw = handoff.read_bytes()
eol = '\r\n' if b'\r\n' in raw else '\n'
text = raw.decode('utf-8')
for a, b in (('Core 0.62; Action Bars', 'Core 0.63; Action Bars'),
             ('Bags 0.11;', 'Bags 0.12;'),
             ('Blizz UI Enhanced (BlizzardSkin) 0.29', 'Blizz UI Enhanced (BlizzardSkin) 0.30'),
             ('QoL 0.16;', 'QoL 0.17;')):
    text = text.replace(a, b, 1)
old_tail = 'enchant icon/hover or names (inspectEnchantNames, inspectEnchantSize).'
new_tail = (old_tail + eol +
            'General/QoL/Bags/Skins+ batch: Core 0.63 Uninstall EUI (EllesmereUI_Uninstall_335.lua:' + eol +
            'E.SetCVar/SetChatWindowSize/NoteBinding/OnUninstall/Uninstall, per-character records in' + eol +
            'EllesmereUIDB.restoreOnUninstall; Minimap, Nameplates, Chat, QoL, Tooltips and Quickdraw' + eol +
            'write through it; validate_uninstall.py). Bags 0.12 Junk Marker (bagShowJunkIcon,' + eol +
            'bagShowJunkCoin, Junk category, bagJunkPrev, ns.SellJunk; validate_bag_junk.py). QoL 0.17' + eol +
            'Self Combat Text (EUI_QoL_335_CombatText.lua, combat log, OnUpdate scroll;' + eol +
            'validate_qol_combattext.py). Blizz UI Enhanced 0.30 tooltipShowBuffs icons and' + eol +
            'highlightStatItems glow (validate_blizzardskin_extras.py). Two new files: full restart.')
if old_tail in text and 'General/QoL/Bags/Skins+ batch' not in text:
    text = text.replace(old_tail, new_tail, 1)
assert 'Core 0.63;' in text and 'Bags 0.12;' in text and 'BlizzardSkin) 0.30' in text and 'QoL 0.17;' in text
assert 'General/QoL/Bags/Skins+ batch' in text
handoff.write_bytes(text.encode('utf-8'))
print('handoff ok')

pin = root / 'backport-tools' / 'validate_skins_lootroll.py'
t = pin.read_bytes().decode('utf-8')
t = t.replace("'## Version: 9.3.4-335-0.29'", "'## Version: 9.3.4-335-0.30'")
assert "9.3.4-335-0.30" in t
pin.write_bytes(t.encode('utf-8'))
print('pins ok')
