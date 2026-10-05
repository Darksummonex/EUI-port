# Blizz UI Enhanced 3.3.5 — 0.17

0.17 adds "GearScore: N" to player tooltips (on by default), coloured by the
GearScoreLite bands. It uses the character sheet formula (GearScoreLite's own
function when loaded) on the same paced inspect as the item level and shares its
cache. When GearScoreLite's Player tooltip option is on, its line is kept and
ours is not added.

0.16 ports the portable Retail BlizzardSkin features; Retail-only systems
(Edit Mode, M+/Vault, upgrade tracks, housing, Catalyst) stay out.
TOC order: core, EUI_Items_335 (link/enchant/gem/durability helpers),
CharacterSheet, SocketPanel, Tooltips, Inspect, Merchant, Popups, World Map.
Modules register in ns.extras: Enable runs before the first Apply, Apply after
each skin pass.

- Tooltips: class-coloured names and health bar, optional title strip, guild
  rank, target (">> YOU <<"), mount with server C_MountJournal collected state,
  item level (own gear directly; others through one paced NotifyInspect per
  hover, cached 5 minutes per GUID, skipped while InspectFrame is open).
  Cursor anchor (top/bottom/left/right + offsets) or a fixed anchor moved in
  Unlock Mode ("Tooltip"); growth direction; show always / out of combat /
  out of boss combat / never with a peek modifier; optional UberTooltips CVar.
  Suppressed tooltips are parked in a hidden host, never Hide()-forced.
- Character slots: enchant icon or name (green tooltip line diffed against the
  un-enchanted link), socketed gems via GetItemGem, missing flags first;
  lowest durability on model/header/footer; eye toggles slot details;
  left-drag rotate, right-drag pan, wheel zoom; Retail backdrop art converted to
  Media/character-bg.tga (512x1024).
- Stats sidebar: per-section show/hide, up/down reorder (statSectionsOrder),
  custom colours (statCategoryUseColor/statCategoryColors), better bag items
  arrow + tooltip on the item level (no red requirement lines).
- Socket strip under the stats: every socket on equipped gear, a flyout of
  matching bag gems (meta only in meta sockets), one click runs
  SocketInventoryItem, ClickSocketButton, AcceptSockets and closes the socket
  window; replacing a gem asks first; aborts in combat or after 5 s.
- Inspect: slot item levels/enchants, average item level, docking beside the
  character window after UpdateUIPanelPositions when it fits on screen.
- Merchant: list mode re-lays out the ten native rows (row height 24-44),
  grows the frame, keeps paging/buying/IDs native; buyback restores the native
  grid and its -15 spacing. Optional gear item levels.
- Popups: resurrect accept glow, Dungeon Ready countdown bar below the dialog
  (height/text size/colour/offset), Dungeon Ready status and role check skin.
- Windows: the server's Collections (CollectionsJournal) and Wardrobe &
  Transmog (WardrobeFrame) frames join the window skin list.

Off by default as in Retail: guild rank, target, mount, list mode, merchant
item levels, resurrect glow, durability, enchant names. validate_blizzardskin_extras.py
covers every feature, combat abort, restore paths and that every option row
persists; all eight BlizzardSkin validators pass. Rendering needs in-game review.

0.7 hands FriendsFrame ownership to the enabled native Friends module and
restores its own social skin when that module is disabled. Other windows retain
their existing skin behavior. Skin changes defer in combat.

0.6 treats GlyphFrame as an elevated content sheet inside PlayerTalentFrame.
The glyph fill occupies only the body (TOPLEFT 16/-58, BOTTOMRIGHT -45/72),
leaving the shared portrait/header, close button and footer tabs visible.
There is no second glyph accent/header border. Talent-only title, scroll,
points, status, preview and activation controls hide while glyphs are shown;
previously shown controls restore on leaving/disable, and inactive controls
remain hidden. Native glyph sockets, glyph/ring textures, click/tooltip and
OnShow/OnHide scripts are retained. Skin writes defer until out of combat.
No external addon dependency or data is used.
Native Wrath structure reviewed:
https://github.com/wowgaming/3.3.5-interface-files/blob/main/Blizzard_GlyphUI/Blizzard_GlyphUI.xml

0.5 keeps native inbox/send/open mail quantity text above skinned item
icons, without replacing stack values, click/drag handlers or native empty
count visibility. It restores original layers and colors when disabled.
Quest/gossip parchment colors, including dark inline color codes, are made
legible on dark backgrounds; refresh hooks repair native repainting. Native
actions and high contrast quest colors remain intact.

Use com Core 0.23 e Options 0.26. Abra /ebs ou /ebui. O TOC carrega
EUI_BlizzardSkin_335.lua e EUI_CharacterSheet_335.lua. A referência Retail e seus assets foram copiados sem
modificar D:/World of Warcraft/_retail_/Interface/AddOns/EllesmereUIBlizzardSkin;
os engines Retail, CharacterSheetForever e DragonRiding não são carregados.

0.4 corrige os fundos de botões/painéis cobrindo textos e ícones: o preenchimento
fica numa textura BACKGROUND do próprio controle; o frame filho desenha apenas
a borda. Ícones nativos são mantidos em ARTWORK, com layer/coords restaurados ao
desligar. Também reconhece iconTexture/IconTexture usados por controles nativos.
Currency retorna ao tamanho/header nativos quando PaperDoll está oculto; o
layout ampliado aplica-se somente à aba Character. Atualizações de TokenFrame,
seu container e recompensas LFD ganham hooks mesmo quando carregadas depois.

Abas de talentos medem os textos e recebem espaçamento próprio, preservando
IDs, scripts e seleção; textos longos podem ocupar mais de uma linha. A barra
de pontos fica acima delas. Nas demais abas nativas, os painéis respeitam as
margens transparentes de 10px para não sobrepor os indicadores de seleção.
FriendsTabHeader também é reconhecido. Geometria de talentos restaura ao
desligar, e demais abas mantêm a geometria/cliques nativos.

validate_skin_content.py cobre Currency, recompensa LFD, talentos, atualizações
LOD, tooltips/cliques, indicadores/margens de sete janelas, restauração,
adiamento em combate e reutilização. Tests gerais de skin/Character e os 191
arquivos Lua 5.1 passaram. Renderização nativa aguarda confirmação no jogo.

0.3 corrige abas Character/Pet/Reputation/Skills/Currency sobrepostas: mede o
texto e usa largura/padding/gap próprios, preservando seleção/IDs/scripts e
visibilidade do Pet. Textos longos quebram para outra linha com espaço no footer.
Enhanced Character Layout, ligado por default, expande o paper doll para 660x580:
modelo central maior, duas colunas de slots 40px com bordas de qualidade,
armas/ammo embaixo, header nome/título/nível/classe, ilvl por item e média equipada.
Média usa 17 slots de combate; camisa/tabard não entram, duas mãos sem offhand
contam nos dois slots. Cache incompleto mostra ... e tenta novamente por até
15 segundos enquanto visível; Wrath não tem GET_ITEM_INFO_RECEIVED. Reabrir
ou trocar equipamentos renova a tentativa.

Sidebar tem Attributes/Melee/Ranged/Spell/Defense, scroll e seções recolhíveis.
Valores e tooltips são gerados por UpdatePaperdollStats/PaperDollStatTooltip
nativos, com os nomes globais de rows que o cliente espera. Health e item level
usam dados do jogador. Titles/Equipment abrem o seletor/gerenciador nativo.
Não apresenta dados Retail como M+ Score, Mastery ou Versatility no Wrath.

Options 0.20 adiciona controles de layout/labels; Core 0.18 inclui as duas chaves
no bundle de Window Skins. Desligar o enhancement restaura geometria/visibilidade,
largura UIPanel, modelo/slots/ícones/picker. Desligar Character skin restaura
também as abas. Combate adia as mudanças; reaplicar reutiliza os frames.
validate_character_sheet.py cobre layout/abas/pet/wrap, cliques nativos, stats,
tooltips/scroll/collapse, títulos/equipment manager, cache/retry, duas mãos,
combat/restore/reuse e roundtrip do bundle. Tests da skin e 139 Lua passaram.
Aparência e comportamento no cliente ainda aguardam confirmação.

Histórico 0.2 (antes da reorganização do paper doll em 0.3):

0.2 amplia a skin para o desenho interno das janelas: remove a arte dos
painéis nativos conhecidos de Character, Quest, Spellbook, Mail, professions,
Friends, Macros, Options e Achievements. Os insets, campos de texto e dropdowns
recebem fundos escuros com bordas retas. Abas mostram a seleção nativa com o
accent Ellesmere; botões, checkboxes, setas e thumbs de sliders/scrollbars
recebem tratamento plano. Ícones de spells/itens ficam com crop e borda
quadrada, preservando seus cooldowns; equipamentos Character/Inspect mantêm
bordas de qualidade. Tooltips, pause menu, popups e menus continuam cobertos.
Os controles nativos preservam cliques, scripts, campos de texto, ícones,
conteúdo, modelos, tamanho, parent, ancoragem e área de clique. Textos escuros
de parchment ganham contraste. A skin não reorganiza atributos/equipamentos,
talentos, merchants, inventário, quests, abas ou keybindings.

O catálogo cobre Character/Inspect, Spellbook/Talents/Glyphs, Friends/Guild/Raid,
Guild Bank e serviços de guild, Quest Log/Quest Dialogs, Gossip, Merchant,
Mail/Open Mail, Auction, Trade, TradeSkill/Craft, Trainer/Stable/Taxi, Socketing,
Dressing Room, Macros, Options/Key Bindings/AddOn List, Achievements, Calendar,
Dungeon/Raid Finder, World Map, Loot/Loot Rolls e Ready Check. Cada grupo pode
ser desligado. Só frames existentes no cliente são capturados. Não há carga
forçada de addons Blizzard; ADDON_LOADED e OnShow tratam as telas sob demanda.
Itens, textos, árvores de talentos, modelos, tiles do mapa, cooldowns e
indicadores de aceite no Trade permanecem nativos. O tratamento é visual,
sem reescrever o backend ou reorganizar o layout. Widgets especiais fora
das famílias de arte identificadas podem conservar parte de sua aparência.

As configurações usam os campos de conta de EllesmereUIDB que o Core já exporta
no bundle BlizzardSkin. Enable Window Skins segue o flag disableWindowSkins do
perfil ativo e preserva as escolhas de cada janela. Tooltips, Pause Menu e
Popups têm controles independentes. Accent Header segue blizzWinAccentBar;
Tooltip Font Scale/Border Size/Background Opacity são editáveis. Fonts/Textures
globais oferecem somente funções nativas; Styles não expõe Character Sheet
Retail ou Skyriding. Os campos já existentes são respeitados, inclusive off.

Mudanças em combate são adiadas. A arte decorativa é esvaziada além de ter
alpha zero, para não reaparecer quando o cliente anima seu alpha. Atualizações
nativas e OnShow solicitam reaplicação. Desligar uma skin restaura caminhos
de textura, alphas, backdrops internos, fontes/cores e coordenadas dos ícones;
os hooks ficam como observadores para
permitir reativação sem criar frames duplicados. Os campos de texto nativos
mantêm sua política de foco; as proteções dos EditBoxes de Options continuam.
Sem alteração no código/versão do Core ou Options e sem dependência externa. Os nomes e
contratos de frames Wrath foram conferidos nos arquivos locais
ElvUI/Modules/Skins/Blizzard como referência. As famílias de chrome e abas
também foram conferidas em DragonUI/modules/characterpanel/chrome.lua e
tabs.lua. DragonUI foi apenas lido; seus módulos/assets não são carregados
nem alterados por este backport. O desenho permanece no estilo Ellesmere.

Não portados: Skyriding/Great Vault, upgrades/tracks, housing, Delves, Catalyst,
procurador de grupos Retail e Season/Mythic data (sidebar, socket panel e
etiquetas de enchants/ilvl foram portados em 0.16). A interface Wrath mantém
seus recursos originais. Não cria namespaces ou templates modernos fictícios.
Bank/bags e outros módulos separados continuam fora deste catálogo.

Validação: validate_blizzardskin.py executa o módulo e Lite/safecall reais em
Lua 5.1. Cobre off pré-existente, primeiro capture, fontes/contraste, gear
quality, controles/ícones/rect preservados, LOD/late controls, combate,
restauração/reuso, kill switch de perfil, tooltips/menus/popups e opções/cards.
Regressões 0.2 cobrem fundos internos antes não tratados, seleção de abas
inclusive após hover, scroll nativo, checkboxes/dropdowns, edição, botões de
dialog, ícones/cooldowns, conteúdo de mapas/talentos/Trade, alpha animado e
refresh de texturas. Restauração devolve o desenho sem desfazer a seleção,
o scroll, checks ou outras ações feitas pelo usuário.
Fixture rejeita escritas de skin em combate e scripts GameTooltip em Frame
comum. Referências Retail são comparadas byte a byte. Os 136 Lua dos oito
addons compilaram; regressões de todos os módulos e foco/widgets passaram.
O mock não comprova renderização/taint. Essas verificações dependem do jogo.

Após o reinício, abra /ebs, Character (C), Spellbook (P), Talents (N), Friends
(O), Quest Log (L) e o menu Escape. Confira um item no tooltip, popup e menu
por clique direito; teste merchant, mail, auction e profissão ao acessá-los.
Desligue/religue cada skin; confira texto legível, ícones/modelos, clicks,
campos de texto e restauração. Mude opções durante combate e confira após sair.
Compare as bordas e áreas visuais das telas sob demanda no cliente real.

Pacote: EllesmereUI-3.3.5-BlizzardSkin-test-0.2.zip (oito addons com pastas originais).
Os pacotes BlizzardSkin 0.1 continuam preservados.
