# Raid Frames 3.3.5 — 0.16

0.16: ícones de ready check acima dos debuffs; respostas por GUID permanecem
por 10 segundos após terminar. Pendentes viram não prontos ao fim da checagem.

0.15: o debuff destacado no ícone central não se repete na barra de debuffs.
Os outros debuffs ocupam os espaços livres; desativar o ícone central devolve
o debuff à barra.

0.14 corrige o fade de membros fora de alcance no Wrath, inclusive em combate.
Dim Out of Range usa Out of Range Alpha (40% por padrão); volta a 100% ao
entrar no alcance. Jogador, prévias e desconectados não recebem esse fade.

0.13: a textura de vida lista a LibSharedMedia e as resolve nos quadros e
na prévia dos indicadores de aura.

A 0.12 traz o "Raid Debuffs" do ElvUI: um ícone grande no centro de cada
quadro para debuffs importantes de ICC, Ruby Sanctum, Trial of the Crusader,
Ulduar e Naxxramas (lista com prioridade em EUI_RaidFrames_335_RaidDebuffs.lua;
por exemplo Ice Tomb e Harvest Soul acima de Frost Beacon). O de maior
prioridade vence; sem nenhum da lista, mostra o primeiro debuff que você pode
dissipar (opcional). Borda na cor do tipo de dissipação (ou vermelha), espiral,
contador e acúmulos. Opções na seção RAID DEBUFFS (dentro de Dispels): Boss
Debuff Icon, Icon Size, Icon Offset Y e Show Dispellable When No Boss Debuff.
Perfis antigos já começam com o ícone ligado. Teste:
backport-tools/validate_raidframes.py.

A 0.11 corrige o erro `SecureTemplates.lua:624: bad argument #1 to 'strupper'`
(repetido ~19x) ao carregar. O header dos pets cria 20 botões (4 colunas de
5) antes do combate, mas era mostrado antes de receber `columnAnchorPoint`; no
Wrath esse atributo não tem padrão quando há mais de uma coluna. Agora todos
os headers seguros (raide, party, tanques e pets) recebem `point` e
`columnAnchorPoint` válidos (com padrão TOP/LEFT) antes do primeiro `Show`, e
os atributos de layout só mudam com o header escondido, e só quando algum valor
mudou de fato. Assim acaba a cadeia recursiva de `SecureGroupPetHeader_Update`.
Em combate, nada muda: o ajuste espera o `PLAYER_REGEN_ENABLED`. Não precisa de
nova versão do Options.

A 0.10 faz a prévia do Unlock Mode (e a da página de opções) abrir no layout
de 25 jogadores em vez do máximo de 40. Fora de raide, o padrão também passou
a ser o layout de 25, então o seletor "Edit Raid Layout", o tamanho do mover e
o "Element Options" ficam todos no mesmo layout de 25. A escolha em "Edit Raid
Layout" continua valendo para a prévia; se "Use Raid Layout" estiver fixo em
10, 25 ou 40, a prévia mostra esse layout (cuja posição é a usada de verdade).
Não precisa de nova versão do Options.

A 0.9 traz a seção DISPELS do Retail para as páginas Raid e Party (requer
Options 0.73):
- Dispel Overlay: None, Fill Overlay, Full Overlay, Gradient Overlay e
  Gradient Sharp, com Overlay Opacity (5–100).
- Frame Border (0–4): borda na cor do tipo em volta da barra de vida. A
  engrenagem tem Debuff Icon Border (-1 segue a borda de cada indicador, 0
  tira a cor do tipo) e Color Custom Borders, que é a antiga "Debuff Type
  Border" (recolore a borda do quadro).
- Type Icon Position, com tamanho e deslocamento X/Y na engrenagem.
- Dispel Colors: quatro cores com alfa; alfa 0 desliga aquele tipo.
- Only Show Dispellable: só destaca o que o seu personagem remove agora
  (filtro RAID do cliente). Desligado (padrão do Retail), destaca qualquer
  debuff com tipo.
As linhas "Color Frame by Debuff Type", "Color Strength" e "Dispel Color
Style" saíram da página Debuffs. Os valores salvos são convertidos uma única
vez (`dispelsVersion`): desligado vira None, Gradient continua Gradient e a
força vira a opacidade.
Diferenças do Retail: o Wrath não tem o tipo Bleed (sem a quinta cor); os
ícones de tipo do Retail são atlas que não existem no Wrath, então são
usados os ícones das magias de dispel (Dispel Magic, Remove Curse, Cure
Disease, Cure Poison); os gradientes de 256×40 do Core viraram cópias
256×64 em `Media/Textures_335`, porque o Wrath só carrega texturas em
potência de dois; o botão de olho do cabeçalho não existe, porque a prévia
do Wrath já mostra exemplos de dispel.

A 0.8 traz o "Preview Mode" do Retail no topo das páginas Raid e Party
(requer Options 0.72). A prévia agora abre sozinha enquanto a página está
aberta e fecha ao sair dela, ao fechar o painel ou ao entrar em combate:
- Overlay Preview (padrão): um painel "Overlay Preview" encostado à esquerda
  das opções, com os quatro primeiros grupos visíveis e os números dos grupos;
  os quadros reais ficam a 20%.
- Real Preview: os quadros falsos aparecem no lugar dos reais quando não há
  grupo ao vivo (o mesmo do antigo botão "Preview Frames").
- No Preview: nada é mostrado.
Os botões "Preview Frames"/"End Preview" saíram das páginas Raid e Party
(continuam em Extras). A página Party ganhou a seção LAYOUT com "Horizontal
Frames" (antes "Horizontal Layout", escondido em Frame Sizes), ao lado de
Member Sorting, Self Position e Reverse Member Order. Não portado: os ícones
de olho por grupo da prévia do Retail.

A 0.7 aproxima o visual e as opções do Raid Frames do Retail. Requer Options 0.71.

Aparência (páginas Raid e Party, separadas por layout 10/25/40 e grupo):
- Cor da vida: Classe, Escuro, Clássico (por % de vida), Personalizada e Personalizada
  Dinâmica (três cores: 100%, 50% e 0%). Preenchimento vertical opcional.
- Fundo: cor própria ou cor da classe com escurecimento, e cores próprias para
  Offline e Morto.
- Bordas: espessura e cor, borda de ameaça, de alvo e de hover (mouse por cima), cada uma
  com a sua cor. Prioridade: ameaça, tipo de debuff, alvo, normal.
- Textos: posição (9 pontos), deslocamento X/Y, cor (Classe, Destaque ou Personalizada)
  e limite de caracteres do nome; mostrar ou esconder AFK.
- Ícones: estilo do ícone de função (Modern, Light, Pixels ou o do LFD do Blizzard),
  tamanho, posição, mostrar tanque/curador e esconder em combate; líder (também em
  combate), marcador de raide, ready check, indicador de combate e ressurreição a
  caminho, todos com tamanho e posição.
- Debuffs: estilo da cor por tipo de debuff (Preencher ou Gradiente), cores Magia,
  Maldição, Doença e Veneno, e esconder Saciado/Exaustão (57724/57723).
- Tooltip da unidade: Sempre, Fora de Combate (padrão do Retail) ou Nunca. Os
  tooltips das auras continuam com a opção própria.
- Layout: Posição Própria (Ordenado, Primeiro ou Último), inverter ordem dos grupos e
  dos membros, party na horizontal e camada (strata) do quadro.

Previsão de cura e ressurreição: o Wrath não tem API nativa, por isso o módulo inclui
LibHealComm-4.0, LibResComm-1.0 e ChatThrottleLib (o LibStub usa a versão mais nova se
ElvUI, Cell ou WeakAuras trouxerem a sua). Só aparecem curas de jogadores que usam um
addon com HealComm.

Nova página Extras, cada elemento com mover no Unlock Mode e painel "Element Options":
- Main Tank Frames: membros marcados como /maintank (e /mainassist, opcional) no raide.
- Pet Frames: pets da party (incluindo o seu) e/ou do raide, até 20 botões criados
  antes do combate.
- Friendly Boss Frames: unidades boss1–4 amigáveis (ex.: Valithria). "Só Curadores"
  usa a função do LFD e, fora dele, a árvore de talentos principal.
- Healer Mana: texto com a mana dos curadores (party, raide ou ambos). Fora do LFD o
  Wrath não tem função de curador, então classes de cura com mana entram como "sem
  função" (opção "Include Unassigned Healer Classes").
Todos usam o visual do raide (ou da party fora do raide) com largura e altura extra.

Correções: o menu "Add New" do editor de Buffs/Debuffs abria e fechava no primeiro clique.
Os painéis "Element Options" do Raid/Party apontavam para rótulos que não existem nas
páginas do Wrath; agora o módulo registra os seus próprios.

Não portado e porquê:
- Auras privadas, pings e supressão do Edit Mode só existem no Retail.
- Absorções, absorção de cura e redução de vida máxima não têm API no Wrath.
- Invocação pendente depende de C_IncomingSummon, que não existe no Wrath.
- Esconder grupos no Mítico: o Wrath não tem dificuldade Mítica.
- Frames dos alvos da party: os headers ordenados trocam unidades em combate e os
  quadros de alvo teriam de seguir por snippets restritos; ficou para depois.
- Retratos, barras suaves, texto de nível e barra de nome no topo: adiados.
- Ícones do tipo de dispel: a arte é do Retail.
- Buff/Debuff Manager completo e extras do ClickCast do Retail; buffs em falta do WoW
  Forever (exclusivo do Forever); câmera livre com botão direito; partySmallRaid; e
  ordem de classes personalizada.

# Raid Frames 3.3.5 — 0.6

0.6 adds Color Frame by Debuff Type (Debuffs tab, Dispel Frame Color). When a debuff your
character can currently remove is on a unit, the health bar swaps to the type colour
(Magic blue, Curse purple, Disease brown, Poison green). Removability comes from the
client's RAID debuff filter, so class, spec and talents are respected without tables.
Priority when several are present: Magic, Curse, Disease, Poison. Color Strength blends
between the normal bar colour and the type colour. Preview frames demo the effect.

# Raid Frames 3.3.5 — 0.5.1

0.5.1 fixes the header never appearing: the Buffs/Debuffs page build now asks the panel to
show the header (getHeaderBuilder alone is only the cache hook, and nothing was requesting it).

0.5 notes:

0.5 moves the retail-style Buffs/Debuffs indicator editor into this module
(EUI_RaidFrames_335_Indicators.lua); no other addon folder needs changes.
- Fixed header: preview built from settings (no group/raid needed), Editing Spec
  dropdown (All Specs + the three talent trees) and the indicator list with enable
  switch, delete and an Add New menu.
- Scrolling page: Group Selection, selected indicator (enable/name), Assigned Buffs,
  Position (position, growth, X/Y) and Display.
- Per-spec lists: the first edit while a spec is selected copies the shared list for
  that spec; "Use Shared List" removes the copy. The active talent tree's list is used
  by the frames, and they refresh on respec / talent-group change.
- The editor installs itself when the load-on-demand options addon loads and applies
  to Raid Frames only; Unit Frames keep the stock Buffs/Debuffs builders.

# Raid Frames 3.3.5 — 0.4

0.4 uses shared geometry for native live aura icons and the options preview.
The old automatically-created broad Buff Icons default becomes explicit
healer assignments while retaining its visual settings. Named/manual or
custom-filter indicators are preserved. Personal defensive and external
presets occupy separate positions; other buffs are assigned manually.
Defaults use a 3+2+2 icon budget, with eight shared per aura type.
Externals accept other casters independently of global Own filtering;
per-indicator Own Only, exclusions and hard aura constraints still apply.
The preview follows the selected raid layout/party config, supports clickable
indicator selection and live position/growth/size/text/style changes.
Native secure roster/click casting, subgroup sorting and combat rules remain.

0.3 defaults existing/new profiles to Tank > Healer > DPS sorting inside
each raid subgroup and in the party. Unknown roles remain last; the module
does not infer healers from class. Both native Boolean and string role APIs
are supported, with native main-tank assignment fallback. Member Sorting
can still use Name or Roster Order. Hide DPS Role Icons hides only their
icons, keeping DPS frames visible; tank/healer icons follow Role Icons.
Role ordering uses Wrath secure header nameList order and updates outside
combat. Role/name/roster changes to those lists wait until combat ends;
new names/subgroup changes can therefore wait for that refresh. Roster/Name
sorting retains native automatic membership updates in combat.

Buffs and Debuffs now have separate pages with group/layout selection and
independent icon indicators: selector, add/remove/rename/enable, assigned
spell IDs, filter/own-only, raid/party display, custom spell order, anchor,
growth/offsets, icon limit, size/spacing/opacity/border, swipe/duration text,
stacks and hide-icon controls. Each aura type shares eight preallocated
icons across up to eight indicators per frame; the UI enforces that budget.
Global aura exclusions/filters apply before indicator selection. The existing
Aura Filters page remains available. Settings are separate per raid layout
and party, and protected layout changes defer until combat ends.

Open Raid Frames in EUI or use /erf (/rf). Requires Core 0.23 and Options
0.26. The TOC loads only the three native EUI_RaidFrames_335 Lua files and
their secure XML template. Retail Lua/media originals remain unchanged,
unloaded references. Settings and positions use the Core's EllesmereUIDB
profiles, including profile switches, imports and resets.

Pages: Raid, Party, Aura Filters, Click Casting. Raid and party have separate
dimensions, textures, fonts, power bars, health text, class colors, range
fading, sorting, roles, leader/raid markers, ready checks and aura settings.
Raid groups can run across or down, with up to eight groups of five members.
The preview uses separate nonsecure buttons; it never replaces live members.
Unlock Mode moves Raid Frames and Party Frames. Global Fonts and Textures
edit the same live settings used by the module.

Raid > RAID LAYOUTS: Use Raid Layout selects Automatic, 10 Players, 25 Players
or 40 Players. Automatic uses the raid/battleground instance capacity when
available, otherwise the current raid roster size (10 or fewer, 11–25, 26–40).
Outside a raid it returns to the 25-player layout, which is also the default
Unlock Mode/options preview (Edit Raid Layout, then a forced Use Raid Layout,
take precedence). Edit Raid Layout selects
which size to configure without forcing the live layout. Each size stores its
own dimensions, appearance, auras/filter lists and Unlock position. Global
Fonts, Textures and Aura Filters have the same layout selector. Existing 0.1
raid settings/position are copied independently into all three layouts.

VISIBLE GROUPS: Show Group 1–2, 1–5 or 1–8 hides individual subgroups for the
edited size. Visible groups pack together without gaps, retaining their native
group numbers and membership. Group Limit caps the last group shown; enabling
a group raises that limit if necessary. Hiding every group hides the raid
holder. Both size changes and group visibility defer during combat. Preview
while outside a raid shows the edited layout, including its hidden groups.

Native SecureGroupHeaderTemplate headers own roster membership, subgroup
sorting, unit assignment and visibility. All 45 secure buttons are allocated
before combat. Layout and binding changes requested in combat apply after
combat ends; native roster changes can still update existing secure buttons.
Vehicle health/power and clicks follow the secure effective unit. Normal
left-click targets and right-click opens the native unit menu.

Buff/debuff icons read each member's native UnitAura list, independently of
the selected target. Timers, stacks, own-caster rules, dispellable debuffs and
dispel borders are supported. Raid and party have separate tracked/excluded
spell-ID filters. Icons allow clicks through to the secure unit button; their
tooltips use cursor position without covering healer click targets.

Built-in click casting starts disabled. Enable it to assign a learned spell
ID, target, menu, focus or assist to mouse buttons 1–5 and modifier keys.
Invalid spell IDs preserve the previous binding. When disabled, registered
ClickCastFrames remain available to Clique; the module clears only attributes
it previously wrote and still owns.

Native party frames are hidden by reparenting outside combat, preserving
their original parent, points, scripts and events. Disabling the replacement
restores them. Other addons' group frames and manually opened native raid
pullouts are not replaced. Disable competing group-frame modules separately
if you want only one set of raid frames.

Retail private auras, modern heal/absorb prediction, advanced buff-manager
containers, portrait layouts and shared battle-res resources are not exposed.
Wrath-compatible role icons and 15 health textures have separate uncompressed
TGA copies, so this module can be installed independently of UnitFrames.

validate_raidframes.py exercises the real runtime in Lua 5.1 with an explicit
Wrath API/secure-header contract fixture: roster changes, aura ownership,
vehicles, combat deferral, bindings, range/status, preview, native restoration,
profiles, movers and the actual options/global-font/global-texture builders.
It also checks XML, TGA headers and Retail byte integrity. Native rendering
and protected behavior still require verification inside the game client.
