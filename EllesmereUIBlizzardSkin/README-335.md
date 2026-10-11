# Blizz UI Enhanced 3.3.5 — 0.34

0.34: desempenho. No 3.3.5 os eventos UNIT_* chegam para todas as unidades, e
qualquer UNIT_AURA/UNIT_STATS/UNIT_MAXHEALTH de raid ou nameplate marcava
`dirty`, refazendo a skin de todas as janelas 5 vezes por segundo fora de
combate. Agora só contam os do player (UNIT_INVENTORY_CHANGED também do
inspecionado com o Inspect aberto), e os eventos de atributos/auras só marcam
`dirty` com a ficha do personagem aberta. Tooltips (OnShow e
OnTooltipSetItem/Unit/Spell) repintam só o próprio tooltip, sem `dirty`, e o
SetBackdrop do tooltip só roda quando a borda muda (`s.tooltipEdge`, limpo no
Restore).

0.33: quem iniciava o ready check via um painel preto vazio: no 3.3.5 o
ReadyCheckFrame abre para o iniciador com o ReadyCheckListenerFrame (Yes/No)
escondido, e a skin pintava o fundo. Agora um hooksecurefunc em ShowReadyCheck
esconde o frame quando o iniciador é o jogador ou o listener está escondido
(como no ElvUI). Quem precisa responder continua vendo a janela normal.
O mesmo painel ficava na tela depois de responder (o Yes/No esconde só o
listener) até o fim do check. A skin agora vai no ReadyCheckListenerFrame, como
no Retail, e o ReadyCheckFrame vazio nunca é pintado.

0.32: a aba Titles da ficha do personagem abria o PlayerTitlePickerFrame da
Blizzard sem a lista montada (vazio). Agora a barra lateral tem a própria lista:
None primeiro e os títulos conhecidos em ordem alfabética (GetNumTitles,
IsTitleKnown, GetTitleName), o atual em dourado, clique chama SetCurrentTitle,
com rolagem pela roda. Atualiza com KNOWN_TITLES_UPDATE, NEW_TITLE_EARNED,
OLD_TITLE_LOST e UNIT_NAME_UPDATE do jogador. O picker nativo não é mais movido.

0.31: a caixa larga dos popups (Guild Message Of The Day e afins) é mais alta
que a linha de texto; o painel do skin cobria o título e os botões. Agora
enquadra só a linha (24 px, centralizada, 6 px de folga dos lados).

0.30: dois recursos do Retail. "Show Player Buffs" mostra os buffs do jogador sob
o mouse como ícones ao lado do tooltip (até 16), com posição, tamanho, ícones
por linha e offsets. "Highlight Items on Stat Hover" (STATS SIDEBAR) faz brilhar
os itens equipados que dão o atributo sob o mouse (Hit, Crit, Haste, Defense,
Strength...), lendo os atributos do próprio item; encantos e gemas não contam.

0.29: encantamentos na janela de Inspect como no Retail e na ficha do
personagem: por padrão um ícone com o nome no hover; com "Show Inspect
Enchant Names Instead of Icons" o nome, com contorno e tingido pela
qualidade do item, limitado a 45% do vão entre as colunas (nome completo no
hover), em tamanho próprio ("Inspect Enchant Name Size"). O Inspect também
marca, no nível máximo, encantamento faltando, socket vazio e fivela de cinto
faltando, com os mesmos ícones vermelhos da ficha ("Inspect Missing Enchant,
Gem & Buckle Icons"). As profissões dos outros não são visíveis, então anel de
encantador e sockets de ferreiro só são cobrados na sua própria ficha.

0.28 (sem bump): a janela de Conquistas não escurece mais a lista. A moldura
sem nome que o Blizzard põe acima das linhas (Conquistas, Resumo, Estatísticas e
Comparação) agora ganha só a borda, sem o fundo escuro que cobria o conteúdo.

0.28: Casa de Leilões convive com addons (Auctionator e similares): painéis,
abas e artes que o addon cria dentro do AuctionFrame mantêm o visual e o
layout do addon; só fontes e botões de texto padrão seguem o skin. Os botões
"Close" do rodapé não ganham mais um "x" por cima do texto.
Correio: as caixas To, Subject e do texto da carta voltam a aparecer (a borda
ficava sob o fundo da página Send Mail). A âncora fixa do tooltip não volta
mais para a posição salva enquanto é arrastada no Unlock Mode. Fonte e backdrop
das caixas de texto só são reaplicados quando mudam, para o cursor de digitação
não sumir com o refresh do skin.
A opção "AddOn List" em Blizzard Window Skins só aparece se o cliente tiver o
frame `AddonList` (o 3.3.5 padrão não tem; servidores que o incluem continuam
com a opção).

0.27: Save de equipamentos inicializa a lista de ícones mesmo com o popup
aberto, evitando comparar números com nil. New Set limpa a seleção anterior.

0.26: as caixas de dropdown das janelas da Blizzard (UIDropDownMenuTemplate,
como o "Type" do Dungeon Finder) não passam mais da borda da janela. O quadro
nativo inclui as margens transparentes da arte; o painel agora começa 17 px
para dentro e termina no botão da seta. A janela Raid Information usava os
recuos da janela de Amigos (feitos para a arte grande de 384x512) e o fundo
terminava 76 px acima da base; agora o fundo cobre o diálogo inteiro de
345x250, com título, botão de fechar, última linha e os botões Extend Raid
Lock e Close.

0.25: duas skins novas em Blizzard Window Skins. "Battleground Capture Bar":
a barra de captura (WorldStateCaptureBarN, criada sob demanda pelo
`WorldStateAlwaysUpFrame_Update`) fica lisa, com zona azul da Aliança, vermelha
da Horda e neutra clara, linhas finas e indicador branco; a arte e o brilho dos
ícones somem. "GM Chat Status": a caixa do aviso de chat com GM
(Blizzard_GMChatUI, carregado sob demanda) ganha fundo escuro e borda na cor de
destaque. Ambas restauram o visual original ao desligar (inclusive pelo
interruptor geral). Teste: backport-tools/validate_skins_lootroll.py.

0.24: novas skins no estilo ElvUI, cada uma com interruptor próprio em
Blizzard Window Skins: Barber Shop; PvP, Battlemasters (Battleground/Arena) e
Arena Registrar com o criador de estandarte; placar do campo de batalha e
minimapa do campo de batalha (os tiles do mapa ficam acima do fundo e o fundo
segue a opacidade nativa); Help/GM (a janela própria do Rebuffed, a padrão,
pesquisa GM e aviso de ticket); timers de fôlego/fadiga com barra lisa,
cronômetro e relógio; Raid Pullouts; Debug Tools (erros de script e Event
Trace); janelas Ace3 (AceGUI-3.0: frames, grupos, abas, botões, caixas de
texto, dropdowns, sliders, títulos e checkboxes). Os recuos de cada janela
foram medidos no FrameXML do cliente; retratos, emblemas de time de arena e
símbolos de honra/arena não são apagados. A skin Ace3 vale para widgets novos;
desligá-la por completo pede /reload.
Loot rolls: os botões Need/Greed/Disenchant/Pass mostram quantos jogadores do
grupo escolheram cada opção (lido das mensagens de saque, inclusive passes
automáticos e strings localizadas com %1$s) e a dica do botão lista os nomes
com cor de classe. Opção "Show Group Roll Choices" em Tooltips, Menus & Popups.

0.23: na janela de Talentos, o botão de fechar (x) e o rodapé de pontos agora
terminam na borda direita da barra de rolagem, dentro do fundo, em vez de
passar da borda. As abas das janelas voltam a ter fundo escuro: o fundo da aba
fica na camada BACKGROUND do próprio botão e era apagado junto com a arte
nativa da aba. Teste: backport-tools/validate_skin_content.py.

0.22: no mapa-múndi (inclusive mapas de instância), a seta do jogador, os
pontos de grupo/raide, o cadáver e os marcadores de missão voltam a cair sobre
a arte do mapa. No 3.3.5 a arte (WorldMapDetailFrame, 1002x668) faz parte da
família de âncoras do WorldMapBlobFrame, que é protegido; quando o Blizzard
troca de visão (mapa cheio, lista de missões ou janela) por um caminho
contaminado em combate, só o SetScale/SetPoint da arte é bloqueado, e a arte
fica em 0.691 enquanto WORLDMAP_SETTINGS.size, o WorldMapButton e a seta vão
para 1.0. O EUI agora segue a arte em combate (escala do WorldMapButton e do
WorldMapPOIFrame, seta reposicionada) sem tocar na arte nem escrever em
WORLDMAP_SETTINGS, e ao sair do combate devolve a arte à visão nativa. As
coordenadas do cursor passaram a ser medidas sobre a própria arte.

0.21: os menus suspensos nativos (Localizador de Masmorras, carimbo de hora
do chat etc.) não mostram mais um quadrado vazio à direita de cada linha. Era
a moldura do ícone nativo da linha, que fica oculto quando a opção não tem
ícone; agora a moldura só aparece quando o ícone está visível.

0.20: o fundo escuro da janela de Talentos/Glifos agora termina logo acima da
fileira de abas e à esquerda das abas de especialização dupla (que ficam
penduradas na borda direita, fora da janela), em vez de cobrir as duas
áreas. Sem especialização dupla, a borda direita fica em -32, a borda da arte
nativa.

0.19: a aba de Glifos voltou a mostrar o fundo nativo (o pergaminho com o
desenho das runas). Antes, a skin apagava a textura UI-GlyphFrame junto com o
resto da arte da janela. Essa textura, porém, é uma janela inteira em escala
1:1 (barra de título, borda e o furo do retrato); por isso agora ela aparece
recortada só no corpo do pergaminho, na mesma posição nativa, e as linhas
continuam alinhadas com os encaixes. A caixa do EUI também foi ajustada a esse
corpo (x 22–342, y 58–432 da folha de 384x512); antes ela ia de 16 a 339 e
descia até 440, passando por cima da borda inferior. O brilho nativo que
aparece ao aprender um glifo também deixou de ser apagado. Ao esconder a aba
ou desligar a skin, a textura volta ao tamanho e recorte originais. O Retail
não tem GlyphFrame (os glifos saíram no Legion), então não há referência
Retail para este ajuste.

0.18: os controles deslizantes (sliders) das janelas da Blizzard, como as
páginas Camera e Mouse das opções de Interface, voltaram ao tamanho certo. O botão nativo é uma arte 32x32
com margens transparentes, e a pintura lisa do EUI preenchia o quadrado
inteiro; agora o botão pintado fica com 8x16 (8x20 nas barras de rolagem
verticais) e o tamanho original volta quando o skin é desligado.

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
