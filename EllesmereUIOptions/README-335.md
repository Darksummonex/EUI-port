# Options 3.3.5 — 0.90

0.90: a prévia e as amostras de cor de power dos Unit Frames usam
`ns.UF_PowerInfo` / `ns.UF_PowerColor`, então mostram as cores originais do
jogo no Classic WoW UI.

0.89: a página Style guarda por estilo a cor de vida dos Unit Frames
(`healthClassColored` e `customFillColor` de cada frame, carimbo
`classicHealthSeeded`), junto da textura e do ícone de combate.

0.88: Nameplates: o contorno saiu do popup de tamanho (ícone de redimensionar)
e ganhou uma engrenagem própria em cada linha de CORE TEXT POSITIONS (segue o
texto escolhido no slot), em Spell Name, Cast Timer e Friendly Names.
Desfeita a proteção da 0.87: ela substituía `CreateMaskTexture` /
`AddMaskTexture` que o cliente já tinha, nas tabelas de métodos compartilhadas
com os frames da Blizzard, e isso contaminava o código seguro: fechar janelas
da Blizzard com Esc mostrava "EllesmereUIOptions has been blocked from an
action". O compat volta a só preencher métodos ausentes (a correção do Unit
Frames 0.12 continua, por ser só nos frames do EUI).

0.87: o compat das opções aplica a mesma proteção: `CreateMaskTexture` nativo
que devolve nil vira uma textura escondida, ignorada por `AddMaskTexture` e
`RemoveMaskTexture`.

0.86: menus "Outline" por texto nas engrenagens de Nameplates e Unit Frames e
"Zone Text Outline" em QoL > Displays. A prévia de Unit Frames mostra o
contorno escolhido em cada texto (requer Core 0.50).

0.85: o compat das opções reaplica o `EUI335_SafeAtlasInfo` do Core antes de
carregar os widgets, caso outro addon tenha trocado `C_Texture.GetAtlasInfo`
depois do Core. O painel abre em clientes cuja busca de atlas gera erro (requer
Core 0.49).

0.84: Action Bars > Bar Display lista as Barras 7 a 10 no seletor de barras e
mostra, no topo da página da barra, um aviso quando ela divide os botões com
uma postura ou forma da Barra 1. Os modificadores de paginação da Barra 1
ganharam as páginas 7-10 (requer Action Bars 0.18).

0.83: a prévia de Action Bars mostra Diamond, Hexagon e Shield recortados, e a
dica de "Custom Button Shape" explica quais formas recortam e quais só ganham
contorno (requer Action Bars 0.17).

0.82: Action Bars > Bar Display ganhou "Custom Button Shape" no topo da seção
ICONS, com o link para aplicar em todas as barras. A prévia do topo mostra o
ícone redondo e o contorno da forma escolhida. A busca encontra button shape,
circle e round (requer Action Bars 0.16). Patch notes atualizadas.

0.81: Arena Frames ganhou as seções PETS ("Show Arena Pets", "Pet Bar Height")
e DIMINISHING RETURNS ("Track Diminishing Returns", "DR Icons Side", "DR Icon
Size"), e "Fade Out of Range"/"Out of Range Opacity" em TARGET AND VISIBILITY
(requer Arena 0.2). QoL: "Announce Interrupts" e "Accept Invites from Friends &
Guild" na seção GROUP e o botão "Disband Group" em Raid Tools (requer Quality of
Life 0.9). Raid Frames: seção RAID DEBUFFS dentro de Dispels (requer Raid Frames
0.12). Os interruptores "Battleground Capture Bar" e "GM Chat Status" aparecem
sozinhos em Blizzard Window Skins (requer Blizz UI Enhanced 0.25). Patch notes
atualizadas.

0.80: Blizz UI Enhanced ganhou a opção "Show Group Roll Choices" (Tooltips,
Menus & Popups) e os novos interruptores de janela aparecem sozinhos em
Blizzard Window Skins. A busca encontra barber, pvp, arena, battleground, help,
timer, pullout, debug, ace3 e loot roll (requer Blizz UI Enhanced 0.24).

0.79: a dica e o rótulo de "Move Zone Text" (QoL > Displays) não falam mais do
mover do Unlock Mode; o nome da zona fica fixo no topo, X 9 / Y 322 (requer
Quality of Life 0.8).

0.78: QoL > Raid Tools ganhou a seção BOSS MOD BARS com "Hide DBM/BigWigs Bars
While Timeline Is Active" (ligado por padrão; requer Quality of Life 0.7) e uma
linha de status dizendo se o AbilityTimeline está carregado e quais barras
estão escondidas.

0.77: QoL > Displays ganhou a seção ZONE TEXT com "Move Zone Text" (ligado
por padrão; requer Quality of Life 0.6). O Element Options do mover "Zone Text"
no Unlock Mode abre essa seção.

0.76: Patch Notes no Wrath mostra só as notas do backport (um banner de visão
geral e uma entrada por módulo, da mais nova para a mais antiga, com a versão
do backport de cada módulo no título); as notas do Retail saíram. A aba EUI
Legends (pódio e lista de doadores) e a linha "Special thanks to:" do
cabeçalho foram removidas; a equipe continua na nova aba "EUI Staff".

0.75: nova página Arena Frames (EUI_Arena_335_Options.lua) para o módulo
EllesmereUI Arena, com seções General, Layout, Health and Power, Text, Icons,
Cast Bar e Target and Visibility. Os quadros de teste aparecem enquanto a
página está aberta.

0.74: QoL > Automation segue o layout do Retail: Quick Loot | Auto-Fill
Delete Confirmation, depois Auto Repair | Auto Sell Junk. "Use Guild Repair
First" virou "Use Guild Bank Funds" dentro da engrenagem do Auto Repair
(desativada enquanto o Auto Repair estiver desligado). As quatro opções têm as
dicas do Retail; o texto "Delete confirmation still requires your click" saiu,
porque Enter já confirma a exclusão.

0.73: Raid Frames ganhou a seção DISPELS do Retail nas páginas Raid e Party
(Dispel Overlay, Overlay Opacity, Frame Border com engrenagem, Type Icon
Position com engrenagem, Dispel Colors e Only Show Dispellable; requer Raid
Frames 0.9). "Debuff Type Border" saiu de BORDERS (agora é Color Custom
Borders na engrenagem de Frame Border) e as linhas de cor de dispel saíram
da página Debuffs.

0.72: Raid Frames ganhou o "Preview Mode" do Retail (Real, Overlay ou No
Preview) no topo das páginas Raid e Party, e a página Party ganhou a seção
LAYOUT com "Horizontal Frames". Requer Raid Frames 0.8.

0.66: Quality of Life ganhou a seção MAIL com "Mailbox: Open All Button" e
"Shift-Click: Attach Same Category" (QoL 0.3).

0.65: Friends List no layout do Retail, numa seção DISPLAY com o aviso do
Style: Class Icon Theme (Blizzard, Modern, Pixel, Pixels Comic, Glyph, Arcade,
Legend, Midnight, Runic) | Class Color Names; Border Size | Border Color
(Custom / Accent Colored); Enable Accent Colors | Enable Faction Banners; Show
Class Icons | Auto-Accept Friend Invites (engrenagem: Accept Invites from
Guildmates). Ficam, só no Wrath: Enable Friends Skin, Window Scale,
Background/Friend Row Opacity e os tamanhos de fonte (engrenagem com Font
Outline). Com Blizzard/Classic ativo, as linhas do visual EllesmereUI ficam
desativadas. O seletor de estilo saiu da página (fica na página Style).
Requer Friends 0.3.

0.64: Quest Tracker no layout do Retail. No topo, "Reposition this element
within Unlock Mode" e o link verde "Force Quest Tracker on Screen" / "Allow
Quest Tracker to be Moved Offscreen" (alterna a trava na tela e abre o Unlock
Mode). DISPLAY traz o aviso do Style quando Blizzard/Classic está ativo e
esconde as linhas que só valem para o visual EllesmereUI; Background Opacity
tem a amostra de cor inline e Font tem a engrenagem com Font Outline. COLORS
usa rótulo + amostra (Title, Completed, Focused, Objective) e as amostras
Class/Custom/Accent de Header e Line. EXTRAS: Auto Accept com engrenagem
(Prevent Multi Quest Accept, Hold Shift to Skip), Auto Turn In com engrenagem
e Quest Item Hotkey. O atalho do Unlock Mode abre DISPLAY > Visibility. O
seletor de estilo saiu da página (fica na página Style, como no Retail).
Requer Quest Tracker 0.3.

0.63: Unit Frames, paridade visual da pré-visualização. Os ícones de buffs e
debuffs da prévia eram IDs de arquivo do Retail (quadrados vazios no Wrath);
agora vêm de magias do Wrath da mesma classe/tipo. A barra de cast da prévia
usa Pedra de Regresso (Hearthstone) quando a classe não tem magia com tempo de
cast, e mostra o tempo real: o C_Spell.GetSpellInfo do núcleo lia o custo de
mana como tempo de cast (correção compartilhada no EllesmereUI). O indicador de
facção e o retrato destacado da prévia usam os mesmos ajustes do quadro real
(ícone PvP do Wrath; arte ajustada ao formato, sem máscara). Requer Unit
Frames 0.10.

0.62: Unit Frames. A linha de filtro de Buffs/Debuffs do Retail dependia do
registro de filtros do Player Aura Bars, que o Wrath não tem; agora usa os
modos do Aura Filters (Show All, Own Only, Only Tracked Auras) com "Edit in
Aura Filters" no topo do menu. A engrenagem de buffs tem Has Duration e, em
alvo/foco, Stealable Only e o brilho de buffs removíveis (Purgeable Buff Glow,
com pré-visualização). A de debuffs tem Has Duration. Passam a aparecer, como
no Forever: posição do Threat %, ícone de humor do pet na prévia, seção do pet
com barra de poder, Power Type de druida (Mana / Mana + Form Power) com os
deslocamentos do texto da forma e o Mana Regen Spark. Somem as opções sem API
no 3.3.5: absorção/cura recebida e as alternativas de poder por spec. Em Class
Resource, "Blizzard" fica desativado fora do Death Knight (só as runas têm
barra nativa no Wrath). Requer Unit Frames 0.9.

0.61: o botão do topo de Bar Display agora é "Quick Keybind Mode (/kb)", como
no Retail, e abre o modo de atalho rápido do Action Bars (no lugar de
"Blizzard Key Bindings"). Requer Action Bars 0.15.

0.60: a pré-visualização de Bar Display mostra os atalhos abreviados (S1, C1)
e deixa vazio o slot sem atalho, em vez do ponto de alcance. Requer Action
Bars 0.14.

0.59: Action Bars no estilo Retail, com três páginas: "Bar Display", "Menu,
Bags & XP Bars" e "Bar Animations". Bar Display tem no cabeçalho o seletor de
barra (350 px) e uma pré-visualização ao vivo com os ícones, atalhos, macros e
contagens reais da barra, borda, fundo de slot, zoom, fundo da barra e layout
(linhas, orientação, ordem e direção). Clicar num ícone, atalho, macro,
contagem ou no fundo rola até a opção e a destaca em verde. Seções:
VISIBILITY (linha de visibilidade do Retail com seleção múltipla, Any/All,
"Apply to all Bars" e o atalho "Toggle Action Bar"), LAYOUT, BAR BACKGROUND,
ICONS, ICON EFFECTS, PAGING (só na Barra 1: formas, setas e páginas por
Shift/Ctrl/Alt/alvo amigo/hostil), TEXT (atalho, macro, contagem e tempo de
recarga com cor, posição e deslocamento por barra) e GENERAL. As cores ficam
em amostras inline, os ajustes finos em engrenagens e cada controle por barra
tem o link "Apply to all". Os atalhos do Unlock Mode abrem Bar Display com a
barra certa ou a página Menu, Bags & XP Bars na seção do elemento. Os cartões
de Fonts e Textures apontam para as novas páginas. Requer Action Bars 0.13.

0.58: Nameplates > CORE TEXT POSITIONS oferece todos os textos do Retail
(Enemy Name, Level | Name, Name | Level, Level, Target of Target, Health %,
Health % (No Sign), Health #, Health % | #, Health # | %, Health % - #,
Health # - % e None). Escolher uma variante de nome libera o slot de outra
variante; textos combinados de vida ficam bloqueados em Left/Right com um nome
no Center. A engrenagem de cada texto abre Size (e "Show % Decimal" para vida),
e cada texto da pré-visualização é clicável e leva ao slot onde está. O toggle
"Health Percentage" de GENERAL TEXT agora se chama "Health Text". Requer
Nameplates 0.11.

0.57: a pré-visualização de Nameplates não some mais ao trocar de aba ou
fechar o painel (o cache do cabeçalho escondia a placa e ninguém a redesenhava).
Como no Retail, ela fica só na página Display, e cada elemento é clicável:
barra de vida, barra/ícone/nome/tempo do lançamento, nome, vida %, nível,
marcador, classificação, setas, recurso de classe, auras e seus textos rolam
até a opção correspondente e a destacam em verde. Os elementos de slot seguem o
slot onde estão (Core Positions / Core Text Positions). A dica "Click elements
to scroll to and highlight their options" aparece até o primeiro clique.

0.56: opções de Nameplates no estilo Retail. As páginas Display e Colors agora
têm o cabeçalho com uma placa de pré-visualização ao vivo (o mesmo renderizador
das placas reais, com auras, barra de lançamento, marcador e caveira de exemplo)
que se atualiza a cada alteração. As cores ficam em amostras inline ao lado dos
controles (borda, fundos, interrompível/kick, alvo, setas, hash line, chefes,
elites, ameaça de tanque/não-tanque), e as engrenagens inline abrem os tamanhos
e deslocamentos (spell name, cast timer, setas, recurso de classe, nome amigo e
cada texto). CORE POSITIONS e CORE TEXT POSITIONS funcionam como no Retail:
cada slot escolhe um elemento, "(one per slot)", escolher um elemento já usado
libera o slot anterior, a engrenagem de cada slot redimensiona o elemento que
estiver nele e os olhos de marcador/classificação ocultam o elemento só na
pré-visualização. Border virou dropdown Basic/None + Border Size (1–4); fundo
e fundo da barra de lançamento são opacidade 0–100 com amostra de cor.

Não portado: a lista de elementos extras do Retail para os slots (ícones de
quest, pets de batalha) — esses dados não existem no 3.3.5.

0.55: `EUI_Nameplates_335_Options.lua` reescrito com as páginas Retail Display,
Colors, General e Aura Filters (seções STYLE, CORE POSITIONS, CORE TEXT
POSITIONS, HEALTH AND CAST BAR, CAST COLORS AND EFFECTS, TARGET, FOCUS & HOVER
EFFECTS, CLASS RESOURCE, GENERAL TEXT; ENEMY/THREAT/OTHER COLORS; OTHER
NAMEPLATES, NAMEPLATE SPACING, EXTRA AURA OPTIONS, TARGET AND FOCUS EFFECTS,
EXTRAS). O card Nameplates de Textures aponta para Display > STYLE.

0.53: nova página Party Mode (`EUI_PartyMode_335_Options.lua`), cópia da
Retail com gatilhos Wrath (Heroic/Normal Boss Kill, Rated Arena Win,
Battleground Win, Bloodlust / Heroism, Level Up, Randomly), alvos de spin só
para módulos com motor de spin carregado e ícone de preview de som nativo.

0.52: Bags > WRATH INVENTORY ganha "Delete Saved Character", que apaga um
personagem salvo (exceto o logado) após confirmação.

0.51 refaz as opções de Bags para o port Retail, agora com as páginas Bags e
Bank: DISPLAY (escala, zoom, auto-size, mesclar, sets, Default Bag Type, BoE,
categorias e moedas habilitadas), EXTRAS (sort, ouro, pinned/recent com
engrenagens, dicas, Add Category, mover sem Shift, avisos, Armory, Stack
Splitter) e WRATH INVENTORY (colunas, keyring, barra de slots, contagens de
personagens, cache). Bank: agrupamento, sidebar e slots vazios. A aba Fonts
de Bags mostra Set Name e BoE Text Size no Wrath.

0.50 rebuilds the Chat pages for the Retail port: Chat (display, visibility,
border, idle fade, input field, extras), Tabs, Sidebar and Chat Bubbles. The
Style page now lists Chat, and the Textures card shows the Retail background
and tab textures.

0.49 rebuilds the Minimap page for the Retail port: shape and style, border
texture/colour source, visibility options, elements, addon flyout and rows,
extra buttons, clock/zone boxes, coordinates, FPS, difficulty text and
accented text.

0.48 adds the Damage Meters Spell History page and Windows rows for header
icons, snapping, hover breakdown, standalone combat timer and keybinds.

0.43 adds native Friends and Quest Tracker settings, including visibility,
Unlock Mode placement, fonts and optional quest helpers.

0.42 makes Quickdraw Assign Key capture the next pressed hotkey, with modifier
support and keyboard cleanup on release/cancel/hide/combat/focus/timeout.

0.41 adds native AuraBuff Reminders and Quickdraw settings, assignments,
reminder preview/filters and palette layout/action/keybind controls.

0.40 adds native Cooldown Manager pages: CDM Bars, Tracking Bars and Bar Glows,
manual assignments, aura filters, dual-spec lists, outlines and previews.

0.39 updates Damage Meters window help for hover breakdown, inline player
focus, Back and the focused footer Spells/Targets selector.

0.38 adds Damage Meters per-window bar/header/footer opacity, font outline
and specialization-icon controls alongside the existing background opacity.

0.37 maps General combat damage/healing, periodic damage and pet melee/
spell damage toggles to stock 3.3.5 CVars. The theme dropdown uses one
complete background/accent update through the core API. Existing combat
guards and safe unavailable-CVar handling remain in place.

0.36 adds native Damage Meters Windows and Combat Data pages. Four windows,
metrics/history, size/fonts/position/visibility, own persistence, collection,
pet merge and explicit report preview/send use the new independent module.
The options builder retains the private frame adapter.

0.35 adds a shared Buffs/Debuffs indicator editor and persistent header
preview for Raid Frames and Unit Frames. The non-secure preview shows spell
icons at their configured anchors, growth, offsets and sizes and refreshes
on every edit. Click preview icons or the indicator list to select one.
It scales the complete layout to fit without changing live sizes. Header
frames/icons/list entries are reused across page/cache refreshes.
Healing, personal defensive and external presets are provided; new manual
indicators start with empty spell lists. Other buffs require manual IDs.
Raid/party and 10/25/40 configurations remain independent. Unit Frames >
Buffs > Player > Use Indicator Layout enables the new player display;
disabling returns to existing aura rows. The same editor supports target,
focus, boss frames and Debuffs. Aura Filters retains global exclusions.
Options still preserve native CreateFrame and inert compatibility probes.

0.34 keeps all widget compatibility probes under a hidden, mouse/keyboard
disabled parent. Each probe is hidden and input disabled; the EditBox uses
the private factory with autofocus off and explicit ClearFocus. Build 0.28
preserved native CreateFrame but accidentally created its EditBox probe
with native default autofocus, allowing it to steal gameplay keyboard input
after other windows closed with Escape. Native CreateFrame and native
window inputs remain untouched. Search inputs retain click-to-focus.

0.33 removes the global CreateFrame replacement. Retail-only template
filtering and EditBox autofocus/OnHide cleanup now live in
EllesmereUI.CreateOptionsFrame, locally bound by the 18 active options
builders which create frames. UnitFrames retains its own Wrath adapter.
Native frames and other addons no longer enter the Options frame factory.
This addresses a taint source identified while investigating the blocked
action popup after closing windows opened by the minimap micro menu.
No global native API is restored/reassigned at runtime; a full client
restart is needed to clear taint from the previous loaded build.
Existing settings, search inputs, template filtering and callbacks remain.

0.32 retains the Minimap middle-click switch and adds Raid Tools pull
duration, DBM/BigWigs broadcast and chat countdown controls under Quality
of Life. The chat channel priority and synchronization permissions are
shown alongside the settings. Existing module options are retained.

0.31 adds the Bags category selector/gold hint and raid role order/DPS
icon controls. Raid Frames includes independent Buffs/Debuffs indicator
pages alongside its existing shared Aura Filters and Click Casting pages.

0.30 adds a native DataBars page: bar selector, templates, appearance/layout,
visibility, ordered blocks and block-specific settings. The original Retail
options file remains unloaded. Use /edb or EllesmereUI > DataBars.


0.24: adds five native Quality of Life pages and native Global Fonts controls. Use the current manifest for the complete module/version combination.

Earlier notes:

0.22: páginas nativas Bags e Resource Bars. Resource Bars usa um seletor único
de barra e deep links dos movers; Bags permite grid/banco/busca/categorias e
fontes. Global Fonts/Textures escreve campos efetivos destes módulos. Estilos
Retail de Resource Bars e labels Warbound/set names de Bags não são expostos.
validate_inventory_resources.py cobre construção de todas as seleções e
setters reais dos tiles globais. Teste visual no cliente pendente.

Use com Core 0.18, UnitFrames 0.6, Minimap 0.1, ActionBars 0.7, Chat 0.3,
Nameplates 0.3 e BlizzardSkin 0.3.

0.20 acrescenta /ebs > Blizzard Window Skins > CHARACTER ENHANCEMENT:
Enhanced Character Layout e Equipment Item Levels. Desligar o layout restaura
o tamanho/modelo/equipamentos nativos; a correção de espaçamento das abas
continua enquanto a skin Character estiver ligada. Presets permanece pausado.

0.19 reúne ActionBars em uma página /eab > Action Bars. Select Bar escolhe
entre 14 grupos: seis action bars, pet/stance, micro/bags, XP/Rep e buffs/debuffs.
Layout/reset seguem a seleção; Global Settings inclui Hide Blizzard Bar Art.
Dimensões HUD e colunas de auras podem ser separadas por seleção, mantendo
fallback das preferências compartilhadas anteriores. Fonts/Textures apontam
para essa página; XP/Rep usam ElvUI Norm. Core e proteções de widgets/foco
permanecem inalterados. Pacote combinado HUD-test-0.2.

0.18 adiciona /eab > Blizzard UI: skins Micro/Bag/XP/Rep, tamanho/spacing dos
botões, largura/altura das barras, movers Player Buffs/Player Debuffs e colunas
de auras. Open Unlock Mode e Reset HUD & Aura Positions ficam na mesma página.
Textures globais apontam para a página HUD e descrevem a textura plana atual.
Proteções de foco/teclado e widgets anteriores permanecem inalteradas.

0.17 adiciona /ebs (/ebui), com Blizzard Window Skins e Tooltips, Menus & Popups.
As escolhas usam os campos de conta já exportados pelo Core; o kill switch de
janelas pertence ao perfil. Desligar/religar restaura a arte nativa sem reload;
alterações em combate aguardam regen. Cards Fonts/Textures oferecem apenas as
funções Wrath; Styles não mostra Character Sheet Retail/Skyriding. Preserva as
proteções de foco, callbacks opcionais e os módulos anteriores.

0.16 reutiliza Class Colored Names para os aliados conhecidos mesmo sem alvo/
mouseover; acrescenta somente Class Colored Health Bar em /enp > Nameplates >
FRIENDLY PLAYERS. A classe dos membros de grupo/raid é identificada automaticamente.
Aliados desconhecidos fora do grupo precisam ser identificados por mouseover,
target ou focus. Não há uma segunda opção de cor da classe no nome.

0.15 adiciona /enp com Nameplates, Cast & Auras e Fonts. Os cards globais de
Fonts/Textures editam os campos Wrath; Styles não expõe os presets Retail de
Nameplates. Auras e nomes/timers de cast são do alvo ou mouseover identificado.
Veja EllesmereUINameplates/README-335.md e o pacote Nameplates-test-0.1.

0.14 adiciona Square Skin em /echat > Chat para as abas e controles planos do
Chat 0.2, com underline da aba ativa e restauração da arte nativa ao desligar.

0.13 adiciona EUI_Chat_335_Options.lua, com páginas Chat e Fonts. /echat abre
as opções e /ecopy copia a janela atual. Cards Fonts/Textures usam os recursos
implementados no Wrath; Styles não expõe estilos Retail de Chat. Preserva foco
opt-in/ClearFocus, hooks opcionais e os módulos já confirmados.

0.12 adiciona EUI_ActionBars_335_Options.lua, com General e páginas das seis
barras, pet e poses. /eab abre a página; usa a tela nativa de keybindings.
Os cards Fonts/Textures de ActionBars foram limitados aos recursos implementados
no Wrath; Styles não oferece seus estilos Retail. Preserva os callbacks/foco.

0.11 adiciona a página Minimap Wrath para EllesmereUIMinimap 0.1, via
EUI_Minimap_335_Options.lua. Exibe apenas os controles implementados no cliente
3.3.5; /emm abre a página. Mantém as proteções de foco e de callbacks de 0.10.

0.10 corrige _NotifySettingWrite ausente ao arrastar/digitar em sliders.
A notificação de captura de Spec Overrides é opcional; a gravação do valor e
a marcação _settingsChanged continuam normais. Protege todos os usos nos widgets
compartilhados (toggles, dropdowns, sliders, cores, popups) e nos controles de
cores dos textos do UnitFrames. Não adiciona um hook fictício ao Core.

0.9 corrige SpecOverrides_EditSessionActive ausente na construção da linha de
visibilidade. O Core de Wrath não carrega o sistema opcional de overrides por
especialização. Os widgets consultam as funções apenas quando existem e editam
a visibilidade compartilhada normalmente quando o sistema está ausente.
Também protege SlotOverridable, ClearStoreKey e CloseEditSessions na troca de
estilo. Não cria APIs fictícias nem habilita overrides por especialização.

Mantém os EditBoxes com SetAutoFocus(false) e ClearFocus ao esconder; mantém
o adaptador GetSpellInfo de 0.7 e as três páginas UnitFrames de 0.8.

Validação: backport-tools/validate_visibility.py executa BuildVisibilityRow e
AttachVisibilityChecklist reais, com leitura/escrita de seleção do Core real.
Apenas a construção gráfica da linha/dropdown usa um mock. Cobre APIs opcionais
ausentes/presentes, edição compartilhada, remoção de overrides, ownership,
slots excluídos e duas disposições de checklists. Não substitui teste no WoW.
validate_widgets.py executa o slider real (arraste, release e entrada digitada),
toggle e callbacks reais de cor/cancelamento; verifica gravação/dirty state e
notificação ausente/presente/removida. Usa widgets gráficos simulados.

Após reiniciar o cliente, abra /euf, confira Main Frames/Boss Frames/Mini Frames
e altere a visibilidade. Abra/feche as opções após digitar num campo e confira
WASD, Espaço, 1–5, Tab, Escape e modificadores.

0.21: Profiles > Presets abre os cards de estilo em jogo no Wrath, com mudanças
gravadas somente ao confirmar reload. Global Settings > General > DISPLAY
oferece Lich King em EUI Options Theme e Match Accent to Theme (padrão on).
Core 0.19 carrega TGA compatíveis dos backgrounds originais sem modificar PNGs.
General > DEVELOPER > Show Spell ID on Tooltip usa os tooltips nativos do Wrath
para magias, action bars, buffs/debuffs e links de magia no chat; padrão off.
O módulo de tooltip respeita spellIDModifier e evita linhas duplicadas.
Validadores de temas/Presets e IDs executam callbacks reais em Lua 5.1.

0.23: dedicated Aura Filters pages for UnitFrames and Nameplates, independent
UF frame settings, all/own/tracked modes, tracked/excluded spell IDs, timed-only
and stealable buffs. Invalid input preserves lists; reset is per selected frame.
Show Channel Ticks controls for both Wrath castbars. Requires Core 0.22.
