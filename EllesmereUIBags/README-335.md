# Bags 3.3.5a — 0.11

0.11 permite abrir e fechar as bolsas em combate pelos atalhos normais.
Atualizações do layout e operações restritas continuam adiadas até sair do combate.

0.10 corrige o erro ao abrir a lista Characters (UIPanelTemplates.lua:255):
no Wrath o UIPanelScrollFrameTemplate monta a barra de rolagem pelo nome do
frame, e o scroll da lista não tinha nome. O mock dos testes agora exige nome
para esse template, como o cliente.

0.9 adiciona um botão de engrenagem no cabeçalho (ao lado da busca) que abre
as opções de Bags, ou a página Bank na janela do banco. Na lista Characters,
cada personagem salvo tem um "x" que apaga suas bolsas, banco e ouro após
confirmação; o personagem logado não pode ser apagado (é gravado de novo
automaticamente). Janelas que mostravam o personagem apagado voltam ao atual.

0.8 porta o visual e as funções portáveis do Bags Retail. Use com Options 0.51.

- Janela Retail: fundo modern_blizz, bordas finas, cabeçalho com título,
  contagem de itens, busca com placeholder/limpar, ícones de ordenar,
  aleatorizar (OneBag), bolsas, personagens e banco; rodapé com moedas
  selecionadas, ouro e status.
- Sidebar Retail com All Items / OneBag / MultiBag, Pinned Items, Recent
  Items, grupos (The Armory, Adventure Prep) com membros recuados, contadores,
  divisor e "Add Category". Recolhível; arrastar reordena; clique direito
  renomeia, agrupa, desagrupa, dissolve, oculta em All Items, edita ou apaga.
- Categorias Retail (EUI_Bags_335_Categories.lua) com classes Wrath: Item Set
  Gear (gestor de equipamentos, opcionalmente uma subcategoria por set), Quest
  Items, Weapons / Trinkets, Armor, Consumables, Trade Goods, Gear
  Enhancements, Professions, Keys e Miscellaneous. Categorias próprias com
  ícone; soltar um item na categoria (sidebar ou "+") o atribui a ela.
- Pins (clique do meio ou "+" em Pinned Items; a Hearthstone é fixada na
  primeira abertura), Recent Items da sessão (com Clear), mesclagem de pilhas
  duplicadas (pausada com correio/troca/leilão/banco/guild bank), ordem visual
  salva por seção, Group Armory by Slot (compacto opcional).
- Ordenação física por pickups nativos (substitui SortBags): OneBag consolida
  pilhas e ordena por família de bolsa, MultiBag ordena cada bolsa, banco sem
  agrupamento também. Sort to Bottom e Randomize; confirmação com "Don't show
  me again". Nas outras visões o botão reinicia a ordem visual.
- Botões de item: borda por qualidade, borda dourada e ícone para itens de
  missão, vermelho para itens inutilizáveis, item level, texto BoE/BoU, nome do
  set, sucata dessaturada, cooldown e destaque Retail. A busca escurece (alpha
  .2) os que não combinam.
- Stack Splitter opcional (Split / Auto Split), Gold Summary com cores de
  classe (Ctrl+clique direito zera), seletor de moedas por personagem.
- Banco: Group by Category (com bloco de slots vazios, ocultável), sidebar de
  categorias e opção de ocultar as bolsas do banco nela.
- A barra de slots de bolsas agora flutua acima da janela (botão Bags no
  cabeçalho ou opção Show Bag Slot Bar) e vem desligada por padrão.

Não portado: Warband bank/ouro, reagent bag, Nest by Expansion, upgrade track,
keystones, preferência de SortBags do cliente, setas do Pawn, Housing, suporte
a controle, filtros de depósito/renomear abas do banco e rótulo Warbound.
Moedas dentro de cabeçalhos recolhidos só aparecem no rodapé depois de
expandidas uma vez (o Wrath não lista moedas recolhidas).

0.7 records each character's gold independently of bag capacity in the
EUI-owned account SavedVariables cache. Saved bag views display that alt's
balance; hover the footer money for individual balances and the total.
Offline balances are the last recorded values, not live server data.
Broker tooltips include the same totals. Item subclasses are cached with
snapshots. Localized class/subclass names are resolved from native cached item
information.

0.6 fixes SetCheckedTexture on saved bank/alt buttons. These are plain
Button objects for read-only snapshots; only live CheckButtons clear checked
textures.

Inventory storage is entirely owned by EllesmereUI. EllesmereUIInventoryDB is
declared as account SavedVariables in the Bags TOC and saved in the game's
EllesmereUIBags.lua file. Realm/character inventories are separate from layout
profiles and the Core database. Each character records its bags automatically
on login, item events, every five seconds and logout, even with the window
closed or during combat. Bank snapshots record only during a banker session.
Startup with unavailable backpack/bank capacity cannot overwrite good data.
Visit each alt and its bank to populate data; logout/reload writes it to disk.

Bags > Save Inventory & Reload UI captures current contents and requests a
normal UI reload to persist them. The cache summary shows recorded characters,
inventories and banks. Characters in the window header selects saved views.
Saved item buttons are read-only and show snapshot timestamps. The native bank
window can be restored during an active bank session.

Existing directly recorded EUI snapshots migrate once from the old Core cache.
No data from other addons is accessed. The LibDataBroker object uses libraries
already bundled with the EUI Core. Broker inventory APIs return copies, with
slot-count text, per-character tooltip and bag/bank clicks.

Native item buttons retain item clicks, stack splitting and drag actions.
Bag slot buttons support click filters, item drop/bag pickup and bank slot
purchase confirmation. Action Bars > Select Bar > Bag Bar > Consolidate Bags
reduces only the HUD.

Loaded files: EUI_Bags_335.lua, EUI_Bags_335_Cache.lua,
EUI_Bags_335_Categories.lua, EUI_Bags_335_Window.lua and EUI_Bags_335_Broker.lua.
Retail Lua/media remain unchanged unloaded references.

Tests: validate_inventory_resources.py (actions, views, sidebar, pins, merge,
recent, assignment, bank, both option pages, fonts), validate_bag_cache.py
(slot strip, saved views, physical sort), validate_gold_categories.py (gold
summary, categories), validate_bag_broker.py and
validate_inventory_persistence.py. Real client rendering still requires testing.
