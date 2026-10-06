# EllesmereUI Wrath Core — 0.48

0.48: o popup "Incompatible Addon Detected" ganhou uma linha de botões acima de
Okay / Don't show again: "Disable <addon>" desativa o addon incompatível e
"Disable EUI <módulo>" (ou "Disable EUI Modules" quando há mais de um) desativa
o módulo afetado do EllesmereUI; os dois recarregam a UI em seguida. O botão do
módulo só aparece quando o conflito é com módulos inteiros: conflitos com todo
o EUI (addons Ellesmere antigos, idTip), com uma parte de um módulo (skins da
ficha de personagem) ou com mensagem própria (ElvUI, WonderBar) só oferecem
desativar o outro addon. O ShowConfirmPopup aceita extraButtons (até dois),
reaproveitados e escondidos quando não usados. Teste:
backport-tools/validate_conflict_popup.py.

0.47 conserta o erro "attempt to call method 'SetMaxLines'" ao abrir o Unlock
Mode: o FontString:SetMaxLines só existe em expansões depois do Wrath, e o menu
"Snap to" de cada mover o chama antes de o Options (que tinha um no-op) carregar.
O compat do Core agora define SetMaxLines/GetMaxLines no metatable de FontString
(1 linha = sem quebra de linha; limites maiores só são guardados, sem mudar a
altura) e EditBox:HasFocus (via GetCurrentKeyBoardFocus), só quando faltam.
Teste: backport-tools/validate_compat_fontstring.py.

0.46: o ponto de "novo patch" do Patch Notes agora compara as versões dos TOCs
dos módulos EllesmereUI instalados (o EllesmereUI.VERSION fica fixo em 9.3.4
no Wrath), então acende uma vez após cada atualização do backport. As notas
em si ficam no Options 0.76. Teste: backport-tools/validate_patch_notes.py.

0.45 registra o novo módulo EllesmereUI Arena: entra na barra lateral como
"Arena Frames" no grupo Core Addons (abaixo de Raid Frames), na lista do
primeiro uso, nos perfis (EllesmereUIArenaDB), na troca de perfil e nas
substituições por especialização (_EARENA_Apply), na fonte por módulo
(chave "arena") e nos apelidos da busca ("arena", "trinket", "gladius").

0.44 conserta a lista de resultados da busca do painel: ela aparecia sem fundo,
com a barra lateral (nomes dos módulos e botões de ligar) e a página por cima
dos resultados. No Wrath o estrato próprio de um quadro filho volta ao do pai
quando ele aparece, então a lista ficava atrás do painel. Agora ela é filha do
UIParent (como os menus suspensos), reaplica FULLSCREEN_DIALOG ao abrir, segue
a escala do painel e fecha junto com ele.

0.43 limpa os nomes na lista de addons: o Core agora aparece só como
"EllesmereUI" (sem "- 3.3.5 Core"), e Options e DataBars perderam o
"- 3.3.5". Todos os módulos declaram `## X-Part-Of: EllesmereUI`, então no
ACP, com "Group By Name", eles ficam agrupados (e recolhíveis) abaixo da linha
do Core, como os módulos do DBM. Na ordenação "Titles" eles também vêm logo
depois do Core, porque o título do Core é o prefixo de todos os outros.

0.42 traz de volta o botão "EllesmereUI" do menu Esc. Até a 0.40 o Wrath
ignorava a opção "Hide Pause Menu Button", então um `hideGameMenuButton=true`
salvo (de um perfil importado ou marcado sem querer) nunca aparecia. A 0.40
passou a respeitar essa opção e o botão sumiu. O valor salvo é limpo uma única
vez (`wrathGameMenuFlagsV1`); depois disso a opção em "EUI Buttons" funciona
normalmente e uma escolha nova de esconder é mantida.

0.41 corrige o menu de clique direito (engrenagem) dos elementos no Unlock
Mode, que sumia logo depois de aberto. O Wrath limita o nível dos frames a
cerca de 256. Com muitos elementos, o mover em foco (nível +100) passava do
bloqueador de cliques (249) e do próprio menu (250). Ao tirar o mouse do
mover, a sobreposição se recolhia em 0,15 s e a engrenagem, ao esconder,
fechava o menu. No Wrath, os movers agora ficam no máximo no nível 238 (a
engrenagem, em 248), sempre abaixo do bloqueador. O menu fica aberto como no
Retail.

0.40 adiciona o botão "EUI Unlock Mode" ao menu Esc, logo abaixo do botão
"EllesmereUI". Ele fecha o menu e liga/desliga o Unlock Mode; em combate só
mostra o aviso. Diferente do Retail, que o esconde até ser ativado, no Wrath
ele aparece por padrão (o valor salvo `hideUnlockMenuButton=false` é gravado
uma única vez, e uma escolha explícita de esconder é respeitada). Os dois
botões seguem o menu "EUI Buttons" das opções gerais. Agora eles ficam
ancorados em Macros, e o que vinha depois (Logout, ElvUI, ACP) desce para
baixo deles; assim a cadeia nunca fica circular com o ElvUI, em qualquer
ordem de carregamento.

0.39 clareia a barra superior do Unlock Mode, que ficava quase ilegível no
Wrath: o texto de 10px com contorno perde o preenchimento em alfa baixo (o
Wrath não tem o renderizador Slug do Retail). As opções (Cursor Light, Dark
Overlays, Grid Lines, Snap Elements, Coordinates, Hover Top Bar) passam de
0,60/0,30 para 0,90/0,60 (ligado/desligado) e chegam a 1,0 com o mouse por
cima. O botão Exit ganhou texto e borda mais fortes, e o texto não escurece
mais depois de passar o mouse. O painel de opções não muda.

0.38 corrige o "C stack overflow" em `EllesmereUI_SpecOverrides_335.lua` ao
abrir as opções de Raid Frames. As bordas douradas leem as opções através de
proxies; quando um getter gravava de volta o que leu (`t.x = t.x or {}`), o
proxy era salvo no perfil real e ganhava uma camada a cada leitura. Agora os
proxies nunca são gravados no perfil, e os que já estavam presos são
desembrulhados na próxima leitura. `validate_spec_overrides.py` repete o
padrão 300 vezes.

0.37 converte a arte do Unlock Mode para TGA (o Wrath não lê PNG):
`prepare_unlock_media.py` gerou cópias potência-de-dois do banner, das camadas
do cadeado (normal e override), do brilho da grade (`media/unlock_335`) e dos
ícones da barra e das setas (`media/icons_335`). Todas são desenhadas com
tamanho fixo no Lua, então o esticamento mantém o resultado; o banner de 1144 px
fica com 1024x128. `EUI_UnlockMode.lua` aponta para os TGA e os PNG originais
continuam intactos. `validate_unlock_media.py` confere que todo caminho existe
e é potência de dois.

0.36 corrige `EllesmereUI_Kick_335.lua`: a cor "Interrupt on CD" (interruptReady)
aparecia com o kick disponível; agora, como no Retail, ela aparece enquanto o
kick recarrega e o kick disponível mantém a cor base. Novo
`EllesmereUI.GetKickCooldownRemaining()` (segundos até o kick, 0 = pronto),
usado pela marca do kick nas nameplates.

0.35 corrige os ícones das páginas de opções: o Wrath não lê PNG, então
`prepare_option_icons.py` gerou cópias TGA potência-de-dois em `media/icons_335`
e as constantes de ícone (fechar, olho, direções, etc.) em `EllesmereUI.lua`
apontam para elas. Os PNGs originais continuam intactos.

0.34 porta o sistema Settings Overrides do Retail:

- `EllesmereUI_SpecOverrides_335.lua`: grupos de spec ("Editing as"), captura
  automática das configurações alteradas, bordas douradas, Default Editing
  Mode, layouts de Unlock Mode por grupo, lista de overrides em Profiles &
  Presets e o botão de glifo ao lado da busca. Spec no Wrath = árvore de
  talentos dominante do talent group ativo (dual spec troca os valores na
  hora), usando os IDs sintéticos do core (33000 + classID*10 + aba).
- `EllesmereUI_Conditions_335.lua`: overrides condicionais (keybind fora de
  combate, Dark Mode, dungeon, raid, arena, battleground, solo). Solo usa
  `GetNumPartyMembers`/`GetNumRaidMembers` e os eventos
  `PARTY_MEMBERS_CHANGED`/`RAID_ROSTER_UPDATE`.
- `EllesmereUI_Presets.lua`: o popup de specs agora lista as 10 classes e 30
  árvores do Wrath (com IDs sintéticos e papéis para Tanks/Healers/DPS). Antes
  listava specs Retail que nunca batiam com o spec do Wrath, então a
  atribuição de perfil por spec também passa a funcionar.
- Arte em TGA (`media/icons_335`): ícones de condição, papéis, multispec,
  info/editar/cadeado e sprites de classe sem RLE.

Não portado: forks de Buff/Debuff Manager (o Raid Frames Wrath não tem esse
sistema; o motor fica inerte) e a condição Druid Form (também "em breve" no
Retail). Teste: `backport-tools/validate_spec_overrides.py`.

0.33 porta os motores portáveis do Core Retail:

- `Libs\LibDeflate` (1.0.2, cópia Retail) carrega antes de Profiles, então
  export/import de perfis e strings compartilhadas voltam a funcionar.
- `EllesmereUI_Kick_335.lua`: interrupt ativo por classe (Mind Freeze,
  Pummel/Shield Bash, Spell Lock do Felhunter, Wind Shear, Kick, Silence,
  Counterspell, Silencing Shot, Feral Charge), resolvido pelo spellbook do
  jogador/pet, com `GetActiveKickSpell`, `IsKickReady`,
  `RefreshKickAbility` e `ComputeCastBarTint`.
- `EllesmereUI_ManaRegenSpark_335.lua`: spark da regra dos 5 segundos e dos
  ticks de mana (`Attach`/`Detach`/`SetMana`), horizontal, invertido e
  vertical; ignora Warrior/Rogue e só conta feitiços que custam mana.
- `EllesmereUI_SpellCostPrediction_335.lua`: segmento do custo do cast atual
  sobre a barra de power, acompanhando castID do `UnitCastingInfo`.
- `EllesmereUI_VideoGuides_335.lua`: guias em vídeo do Retail (Overrides,
  Unlock Mode, Cooldown Manager, presets) com ícone play em TGA; o guia do
  lançamento 12.1 foi removido.
- `EllesmereUI_PartyMode_335.lua`: Party Mode completo (luzes, feixes em TGA
  com rotação por texcoord, música, spin) com gatilhos Wrath: boss kill
  heroico/normal (unidades boss ou DBM_Kill), vitória em arena ranqueada e
  battleground, Bloodlust/Heroism (Sated/Exhaustion), level up e aleatório.
  Brilho/contraste usam gamma quando os CVars Retail não existem.

Não portado: ClientGate, RetailAtlas, AuraKit, WarriorCharges, LibKeystone,
LibSpecialization (APIs/sistemas inexistentes no 3.3.5), BlizzardParty (não
existe CompactRaidFrameManager), proxies seguros de menu do Kick (sem ação
"togglemenu"), gatilhos de keystone/Mythic/LFR/rated BG e o vídeo 12.1.
Range e MacroFactory ficam para Nameplates/QoL; ResourceBars ainda não
hospeda o spark/custo. Teste: `backport-tools/validate_core_engines.py`.

0.28 replaces the Options sidebar CPU readout with combined loaded EUI addon
memory, including Options. Native KB accounting is shown as MB every 5 seconds
while the panel is visible.

0.27 separates the Wrath theme image from the opaque base using native
BORDER/BACKGROUND layers. Pixels/collapse decoration sits above the art;
Retail retains its sublevels. This fixes the base occlusion left in 0.26.

0.26 applies theme background and registered menu colors together.
Wrath switches both art layers and the collapse box immediately, clears
outgoing Pixels overlays and keeps the live texture handle current even
when the panel is hidden. Theme matching and independent profile accents
remain selectable; Retail keeps its animated crossfade.

0.25 adds EUI_AuraIndicators_335.lua: shared native aura indicator geometry,
Wrath healer/defensive/external spell catalogues, local-name rank matching,
assignment selection, icon/text/cooldown display and reusable unit-frame
pools. No other addon data or runtime dependency is consulted. Exclusions
and timed/stealable constraints override explicit assignments; assigned
externals can come from another caster despite the global Own filter.
Cooldown indicators display active aura duration, not other players'
unobservable spell cooldown availability.

0.24 routes options-panel and global-search frame creation through the
private EUI options factory when available, retaining the native factory
before options loads. EUI search/EditBox focus behavior remains scoped to
its controls. Blizzard's global CreateFrame is preserved.

0.23: QoL receives its own full profile-refresh step for native overlays, automation, logging, window dragging and secure raid tools. Existing Core behavior is preserved.

Earlier notes:

0.18 inclui enhancedCharacterSheet/characterItemLevels no bundle opcional de
Window Skins de export/import. Ausência das chaves continua representando o
default do módulo. Tooltip Unlock e confirmação Edit Mode de 0.17 preservados.

0.17 troca o tutorial automático do sidebar Wrath por tooltip no mouseover
do botão Unlock Mode, à direita da linha. Fecha imediatamente ao sair,
clicar ou esconder o botão/painel; não cobre as linhas inferiores ao abrir.
O tutorial dentro de Edit Mode mantém a confirmação: botão Okay com fonte,
limites, alpha e ordem de desenho explícitos no Wrath. Clique fecha a mensagem,
cancela o fade e grava unlockTipSeen. Fluxos de hover/dismiss foram executados
localmente com funções reais; aparência final ainda precisa de teste no cliente.
Presets continua pausado; proposta em backport-tools/paused-presets-navigation.patch.

0.16 adiciona EUI_OptionsAccess_335.lua: botão EllesmereUI no menu Esc do Wrath
e categoria Interface > AddOns > EllesmereUI com Open EllesmereUI. Abrem o
painel existente, carregando Options sob demanda somente ao clicar. Combat
guard impede load/open em combate; falha de load mantém a tela nativa aberta.
Registro/layout são idempotentes, preservam outras entradas de addons e não
duplicam o botão do menu pooled Retail. Layout acompanha a cadeia de Logout e
expande a altura conforme Continue, evitando anchors circulares entre addons.
Categoria não cria bindings nem captura teclado. validate_options_access.py
cobre entradas/cliques, lazy load, guards, re-layout/coexistência, eventos
repetidos e menu moderno; sintaxe dos 138 Lua/UnitFrames passou.

0.15 elimina overlays de edição duplicados de Buffs/Debuffs quando os movers
Player Buffs/Player Debuffs do ActionBars Wrath estão registrados, inicializados
e habilitados. Auras nativas já seguem esses movers; o overlay somente leitura
agora cede sua superfície de edição ao mesmo grupo. Nenhuma aura é escondida,
copiada ou recriada, e as posições salvas permanecem no perfil ActionBars.

Sem o módulo/mover inicializado ou com a opção desligada, o overlay nativo
volta a ser elegível. Overlays criados em sessões anteriores são escondidos
quando o mover assume o grupo. Não altera o movimento ou os dados dos addons.

Validado por validate_actionbars.py com catálogo/show reais do Unlock Mode:
overlay inicial, ativação/desativação de cada grupo e do módulo, mover ainda
ausente, re-enable, refresh sem frames duplicados e ícones nativos preservados.
Também passaram os 137 Lua e a regressão UnitFrames. Aparência/taint aguardam
confirmação detalhada no cliente. Usuário confirmou "Great so far so good";
os ZIPs anteriores foram excluídos por solicitação dele. Core 0.14 é a base
histórica, e a versão atual está registrada no manifesto do diretório AddOns.
Use o combinado EllesmereUI-3.3.5-HUD-test-0.14.zip para a base atual.

Core 0.21: refresh de perfis das novas janelas Bags/Bank pelo hook
_EBAGS_RefreshAll. A combinação inclui Bags 0.1 e ResourceBars 0.1 nativos,
Options 0.22 e mantém todas as correções anteriores. Teste no cliente pendente.

Core 0.19 / Options 0.21: Presets retomado por solicitação explícita do usuário.
Profiles > Presets e UI Style Presets abrem o seletor de estilo em jogo, com
cards EllesmereUI / Blizzard / Classic e escolhas por módulo compatível.
As gravações permanecem dentro da confirmação de reload; cancelar preserva o perfil.
Os temas agora usam cópias TGA RGBA 1024x1024 de backgrounds em media;
preservam o canvas completo/UV, transparência e todos os PNGs originais.
Também converte base/sombra, overlay Pixels e ícone collapse/expand.
Lich King usa eui-bg-lichking.png fornecido pelo usuário, com paleta azul-gelo.
Global Settings > General > DISPLAY > Match Accent to Theme segue a paleta
do tema (padrão ligado no Wrath). Desligar recupera o accent salvo; escolher
swatch custom/class também desliga, sem perder o accent anterior do perfil.
validate_themes_presets.py testa os callbacks reais de tema/matching, preload,
crossfade, navegação, cards/setters/reload, cache e prebuild. Validação gráfica
no WoW continua necessária após o reinício.
EUI_TooltipIDs_335.lua ativa a opção existente General > DEVELOPER > Show
Spell ID on Tooltip no Wrath (padrão off), sem TooltipDataProcessor/CVar Retail.
Hook nativo para spells/actions/macros/auras/links, ID de aura na posição 11,
suporte a spellIDModifier e dedup por tooltip/convivência com outros addons.
validate_tooltip_ids.py testa estes contratos e registro idempotente.

Core 0.20: corrigido teclado dos dois campos Search Features / Search Module
Settings. ReleaseWrathPanelKeyboard desligava EnableKeyboard nos EditBoxes ao
abrir/fechar o painel, deixando impossível digitar mesmo após SetFocus.
EditBoxes agora mantêm teclado habilitado e liberam foco na limpeza; frames
de captura de keybind continuam desativados até serem armados por click.
validate_search.py reproduziu o defeito anterior e valida cleanup/reopen/foco,
handlers reais de digitação/debounce/Escape/Enter, filtro/restauração de módulo,
popup de features, indexação de página não visitada e navegação do resultado.
Mantém autofocus off e ausência de OnKeyDown/propagação fictícia.
