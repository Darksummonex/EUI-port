# DataBars 3.3.5a — 0.4

0.4: barras presas a uma borda da tela ("Snap to Screen Edge") ou em tela
cheia não começam mais em posição estranha depois do login. Antes a posição era
calculada em coordenadas absolutas a partir do tamanho do UIParent no
OnEnable; o Core reaplica a escala da UI depois disso, e a barra só voltava ao
lugar ao abrir e fechar o Unlock Mode. Agora a barra é ancorada nas bordas do
UIParent (TOP, TOPLEFT/TOPRIGHT, etc.), então a escala não a desloca. Teste:
backport-tools/validate_databars.py.

0.3 porta o motor e o visual do DataBars Retail. Requer EllesmereUIOptions
9.3.4-335-0.67 ou superior.

- Arquivos carregados: EUI_DataBars_335.lua (motor), EUI_DataBars_335_Tip.lua
  (tooltip próprio), EUI_DataBars_335_Kit.lua (kit dos blocos) e
  Blocks_335\*.lua (um arquivo por bloco, como no Retail). O antigo
  EUI_DataBars_335_Blocks.lua foi removido.
- Motor Retail: modos Auto Sized (com um bloco Fill Remaining e um Force
  Centered opcional) e Even Split; fundo EllesmereUI (modern_blizz em
  cover-fit) ou Modern (cor lisa ou textura de barra); borda, camada
  (strata), largura/altura de tela cheia, encaixe na borda da tela, escala de
  texto, destaque de blocos ao passar o mouse; por bloco: margens, alinhamento,
  deslocamento do texto e do conteúdo, escala, fundo e cores de texto/ícone
  (Custom/Class/Accent/Dynamic).
- Tooltip próprio do Retail com colunas, linhas clicáveis, roda do mouse e
  linhas seguras (feitiço/item/macro) que somem em combate.
- Os 20 blocos usam dados nativos do Wrath: relógio (correio, descanso,
  instâncias salvas, reset diário), FPS, latência, local, coordenadas, ouro
  (histórico por personagem em EllesmereUIDB.dataBarsGold, sessão), bolsas,
  durabilidade, combate, XP/reputação, talentos (troca de spec dupla por
  linha segura), profissões primárias e secundárias, viagem (Pedra de Regresso
  segura, teleportes de mago, Astral Recall, Death Gate, Moonglade, anéis do
  Kirin Tor), micro menu (botões próprios com ícones EUI), moeda, nível de
  item, áudio, broker e espaçador.
- Cada barra tem mover no Unlock Mode e o botão "Element Options", que abre a
  página DataBars com a barra já selecionada em BAR SETTINGS > Visibility.
- Visibilidade: driver seguro para combate/grupo; mouseover e opções
  extras pelo motor de visibilidade do EUI. Mudanças estruturais esperam o
  fim do combate.
- Perfis 0.2 são migrados automaticamente (tema, visibilidade, modo de
  tamanho, modo XP/rep, moeda).
- Mídia convertida para TGA potência de dois em Media_335 por
  backport-tools\prepare_databars_media.py.

Não portado: Crests e Great Vault (sistemas só do Retail); loot spec e
loadouts (o Wrath usa talentos duplos); warbank e preço do WoW Token;
hearthstones de brinquedo, sorteio de hearthstone e portais de M+; canal de
áudio Dialog; segunda latência "World" (o Wrath só informa uma); animação de
descanso e atlases (sem FlipBook/SetAtlas; usa textura estática); contagem
do reset semanal sem raid salva (não há API no Wrath); botões de Housing,
Adventure Journal, Collections e Shop; "Hide Blizzard Micro Menu" (os botões
pertencem ao HUD do ActionBars); plugins LDB de outros addons (só brokers do
EllesmereUI); prévia com arrastar-e-soltar e cartões de modelo nas opções
(substituídos por botões de mover e listas).

# DataBars 3.3.5a — 0.2

0.2 fixes OnInitialize through the actual Lua 5.1 Lite dispatcher: xpcall
does not forward the self argument on this client, so initialization uses
the captured addon reference. Tests now dispatch ADDON_LOADED/PLAYER_LOGIN
through the real Core rather than invoking lifecycle methods directly.

Open EllesmereUI > DataBars or /edb. A bottom information bar appears on first
login. Create additional bars from Bottom Info Bar, Minimap Companion, Micro
Menu Strip or Empty Bar. Select a bar, rename it and configure its layout,
length/thickness, scale, fonts, visibility and accent/dark appearance. Move it
in Unlock Mode. Bars and their ordered blocks/positions follow EUI profiles.
Global Fonts uses the existing DataBars entry; its Text Scale link opens this
page. Hide/delete bars or add/reorder/remove individual blocks in the same page.

The twenty supported block types use native Wrath data: clock, FPS, latency,
location, coordinates, gold, bag capacity, durability, combat state, XP/rep,
talent specialization/dual spec, professions, secondary professions,
hearthstone, micro menu, currency, equipped average item level, audio, EUI Bags
broker and spacer. Hover for information and click for the relevant native
window. The Hearthstone button uses SecureActionButtonTemplate with item 6948.
Audio supports mute and wheel volume adjustments. Bag/broker clicks integrate
with EUI inventory/bank when available and use native bags otherwise.

XP/rep mode selects XP, watched reputation or automatic XP below max level /
reputation at max. A visible progress block hides the corresponding existing
EUI ActionBars progress holder and mover. Removing/disabling it restores that
bar without rewriting the ActionBars settings. The default information-bar
template leaves the existing XP/rep bars in place. No native frame is reparented
by the DataBars micro-menu shortcuts. Combat/group visibility uses native
secure state drivers; bar creation/deletion/layout changes defer until combat
ends. Information continues updating once per second and on native events.

Only EUI_DataBars_335.lua and EUI_DataBars_335_Blocks.lua load. Copied Retail
engine/Blocks/media remain unchanged, unloaded references. No external addon
data or dependency is used. The broker block reads only the EUI Bags object.
The EUI Core central profile database owns settings; no separate inventory
store is added. Retail-only Great Vault/Crests, loot spec, warbank and modern
profession systems are not exposed. Coordinates never change map selection;
they may be unavailable when a different map is selected or in instances.
Currency/skills show native expanded categories. Item level is an average of
occupied equipment slots (shirt excluded), with uncached items retried later.

validate_databars.py tests all block values/clicks/fonts, native TOC, original
byte integrity, multiple bars/CRUD, layout bounds and vertical behavior without
native texture rotation, secure actions/drivers, combat queue, profile changes,
frame reuse, Edit Mode callbacks, options/search and slash commands.
validate_actionbars.py verifies progress handoff/fallback. validate_unitframes.py
compiles every module Lua file under Lua 5.1. In-game rendering/input and taint
verification still require client testing.
