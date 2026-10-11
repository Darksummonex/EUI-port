# Nameplates 3.3.5 — 0.20

0.20: desempenho. UNIT_AURA de qualquer unidade não roda mais o update completo
de todas as placas: só target/mouseover/focus marcam a placa (auraDirty) e o
player só invalida o cache de tank. Os demais eventos só marcam
`ns.updatePending`; o OnUpdate faz no máximo um `ns.Update` por frame (além do
ciclo de 0,05 s). Interrupção e roster continuam imediatos. Uma placa que
aparece faz bind/classe e pinta só ela (`ns.UpdatePlate`), não todas. `IsTank`
guarda o resultado (`ns.tankState`) e os nomes das auras de tank, em vez de 5
GetSpellInfo + 5 UnitAura por placa a cada mudança de vida. O paint só chama
SetScale/SetAlpha do root e SetTexture/SetText dos ícones de aura quando o
valor muda; as chaves de layout e de auras viraram números (sem concatenar
strings a cada paint).

0.19: o elemento "Boss Icon" das Core Positions vira o Rare/Quest Indicator do
Retail. O dropdown oferece "Rare/Quest Indicator", "Rare Indicator" e "Quest
Indicator" (as duas metades dividem o mesmo slot, `classificationHideRare` /
`classificationHideQuest`); o cog do slot tem Size, as duas metades e Show In
Instances (`classificationShowInInstances`, desligado: some em party/raid, como
no Retail). Prioridade: quest > skull de boss > rare/rare elite > elite. No 3.3.5
a placa não tem unit e o tooltip não lista objetivos, então quest mob = nome da
placa igual a um objetivo de matar ainda incompleto do quest log
(`GetQuestLogLeaderBoard`, padrão de `QUEST_MONSTERS_KILLED`, refeito em
QUEST_LOG_UPDATE); rare é aprendido pelo nome quando a placa está ligada a
target/mouseover (`UnitClassification`); elite vem da região nativa de elite.
Os atlas do Retail não existem no 3.3.5: estrela dourada (elite), estrela
prateada (rare elite) e losango prateado (rare) em `Media_335/class-*.tga`
(`backport-tools/prepare_nameplate_class_icons.py`), e o "!" do cliente
(`Interface\GossipFrame\AvailableQuestIcon`) para quest. Não portado: "Replace
Quest Icon with Objective" (contagem no lugar do ícone), Faction e
"Rare/Quest + Faction".

0.19 também traz o Crowd Control do Retail às Core Positions: "Crowd Control"
(slot próprio `ccSlot`, padrão "right" como no Retail, até 2 ícones,
`ccSize` 24 / `ccSpacing` 2 no cog, com X Offset) e "Debuffs + CC"
(`debuffIncludeCC`: o CC entra primeiro na fileira de debuffs e o slot próprio
fica "none"). O 3.3.5 não tem a flag CROWD_CONTROL: CC = feitiço da tabela de DR
do LibAuraInfo (`drSpells`, lista do DRData com todos os ranks; toda categoria
menos taunt), por spell ID e, para outros ranks, por nome. Como no Retail, CC
de qualquer caster vai ao slot de CC e sai da fileira de debuffs; sem nenhum
elemento de CC posicionado, os debuffs ficam como antes. Perfis antigos que já
usam o slot "right" ficam com `ccSlot = "none"` (Migrate). O preview mostra
Polymorph e Hammer of Justice. Não portado: listas de inclusão/exclusão próprias
do CC, Cropped Icons e Hide Border por elemento.

0.18: as texturas de barra do EllesmereUI (Melli, Atrocity, Fade, Matte...,
`EllesmereUI.BuildBarTextureTables(true)`) entram nos dropdowns de textura de
vida e cast, como no Retail. Perfis do Retail com `healthBarTexture = "melli"`
mostravam a barra Flat.

0.17: Scale Target Nameplate (targetScale) é multiplicador no port (1-1.5), mas
o Retail guarda porcentagem (100). Um perfil do Retail importado deixava a
placa do alvo 100x maior, cobrindo a tela. Valores acima de 5 agora são lidos
como porcentagem e a escala fica entre 0.5 e 2; o import do Core 0.66 converte.

0.16: Debuff Filter (aba Aura Filters) ganhou "Raid Debuffs" e "Own and Raid
Debuffs", com a mesma lista de debuffs de raid dos Unit Frames (Core,
EUI_AuraFilters_335.lua).

0.15: "Enemy Buff Filter" (Retail 9.4) na seção EXTRA AURA OPTIONS da aba
General: Timed Buffs (padrão; Wrath não tem a flag "important" da Retail),
Only Dispellable e Show All (todos os buffs). Usa os mesmos campos da aba Aura
Filters (Only Timed Auras / Only Stealable Buffs).

0.14: texturas de vida e de cast bar incluem a LibSharedMedia e chaves
`sm:` são resolvidas em jogo.

0.13: cada texto da placa ganhou o menu "Outline" (Module Default, None,
Outline, Thick Outline, Shadow) logo abaixo do Size na sua engrenagem: nome
(e combinações de nome/nível), Level, Target of Target, textos de vida, Spell
Name, Cast Timer e Friendly Names. Aura Stacks e Debuff Duration (GENERAL TEXT)
ganharam uma engrenagem só com o contorno. Padrão: Module Default, então nada
muda até você escolher (requer Core 0.50).

0.12: a barra de lançamento preenche suavemente. Antes o preenchimento só era
atualizado no refresh das placas (a cada 0,05 s), por isso andava em degraus.
Agora a barra tem um OnUpdate próprio que roda a cada frame só enquanto há
cast visível (sai no fim, no flash "Interrupted" e ao esconder): casts de
alvo/mouseover seguem GetTime() contra o fim do cast, canais esvaziam, e placas
anônimas espelham a barra nativa. Spark e tempo também andam por frame; o texto
do tempo só é reescrito quando muda o décimo (fora isso, nada é alocado por
frame).

0.11: o menu de texto de CORE TEXT POSITIONS agora tem todas as opções do
Retail: None, Enemy Name, Level | Name, Name | Level, Level, Target of Target,
Health %, Health % (No Sign), Health #, Health % | #, Health # | %,
Health % - # e Health # - %. Cada elemento tem a própria FontString
(`ns.TextString`); as variantes de nome dividem a do nome, então escolher uma
tira a outra do slot (regra Retail), enquanto vida e nível podem coexistir.
Vida # vem do valor absoluto da barra nativa, abreviado como o
AbbreviateNumbers padrão da Blizzard (1.2K, 12K, 1.2M; `ns.AbbreviateNumber`).
O cog de vida ganhou "Show % Decimal" (global, `healthPctDecimal`); Target of
Target tem tamanho próprio (`totSize`) e só aparece em placas identificadas
(alvo/mouseover), com cor de classe para jogadores. Como no Retail, os textos
combinados ficam bloqueados em Left/Right enquanto um nome está no Center.
O toggle "Health Percentage" virou "Health Text" e vale para todos os textos de
vida. Perfis com o valor antigo `name` migram para `enemyName`. A
pré-visualização mostra amostras de todos os elementos (72% de 10.000 = 7.2K;
o próprio jogador como Target of Target). Não portados: slots Bottom Left/Bottom
Right, cor/largura/offset/strata por slot, Level Difficulty Color opcional (o
nível usa sempre a cor nativa) e Name Format do WoW Forever.

0.10: a placa de pré-visualização ignora o OnHide do cache do cabeçalho e se
redesenha no OnShow; mostra 3 pontos de combo de exemplo para qualquer classe.
Border None agora esconde só as bordas: antes escondia também o texto, o tempo,
o escudo e a marca de kick da barra de lançamento.

0.9: suporte às opções no estilo Retail. Novo slot `bottom` (abaixo da barra
de lançamento) para auras, marcador e classificação; `showBorder` liga/desliga
a borda (perfis com Border Size 0 migram para borda desligada com tamanho 1);
`ns.CreatePreview`/`ns.PaintPreview` desenham a placa de exemplo do cabeçalho
das opções com o renderizador real, sem entrar na lista de placas vivas e sem
ser limpa pela reciclagem; `ns.previewHidden` atende aos olhos das opções.

0.8: visual Retail do EllesmereUI portado sobre as placas nativas do Wrath. A
identificação (alvo/mouseover únicos), o cache de auras por GUID, as dicas de
classe, o adiamento em combate e a restauração continuam iguais. O TOC agora
carrega EUI_Nameplates_335.lua (dados, eventos, Apply) e
EUI_Nameplates_335_Display.lua (construção e pintura). As artes Retail foram
convertidas para TGA potência de dois em Media_335 (fundo do glow, execute glow,
escudo, 6 texturas listradas e as 16 setas); os PNG originais seguem intactos.

- Padrões Retail: barra 150x17, fundo .12, borda interna de 1 px (.067), nome
  centralizado acima, vida % à direita, nível à esquerda. Posições de texto
  configuráveis (Top/Left/Right/Center: nome, vida %, nível ou nada).
- Cores Retail: inimigo, neutro, tapped, boss (caveira nativa), elite em
  instâncias, jogador/NPC aliado, classe do jogador inimigo pela cor nativa.
- Ameaça Retail: modo Never/In Instances/Always, papel Auto (Defensive Stance,
  Bear/Dire Bear, Righteous Fury, Frost Presence)/Tank/Non-Tank, cores de tank
  e não-tank, Classic Tank Aggro, canais vida/borda/nome. Placas anônimas usam
  o brilho nativo; alvo/mouseover identificados usam UnitThreatSituation.
- Cast Retail: roxo, "Interrupt on CD" enquanto o kick recarrega (via
  E.ComputeCastBarTint), cinza com escudo quando não interrompível, spark,
  fundo .1/.9, ícone fora da barra (esquerda/direita/nenhum), marca do kick no
  ponto em que ele volta (E.GetKickCooldownRemaining), flash vermelho
  "Interrupted" (UNIT_SPELLCAST_INTERRUPTED) e opção de esconder o nome durante
  o cast.
- Efeitos de alvo: EUI Glow 9-slice, cor de borda ou highlight; setas (16
  estilos, escala, cor ou cor da classe); cor de alvo; textura listrada no
  preenchimento; escala do alvo; highlight de mouseover; hash line em % no alvo.
- Execute Pulse Glow: Execute, Hammer of Wrath e Kill Shot a 20%, Drain Soul a
  25% (apenas se a magia estiver no grimório).
- Auras: debuffs centralizados acima do nome (26 px) e buffs inimigos à esquerda
  (24 px), slots configuráveis, espaçamento/offsets, tempo no canto superior
  esquerdo, stacks embaixo à direita. Raid marker (24) e ícone de boss (20) em
  slots próprios.
- Class Resource: combo points sob a placa do alvo (Rogue/Druid).
- General: Friendly Name Only ligado por padrão com tamanho 15, Show Enemy Pet
  Nameplates, Stacking Nameplates (inverso de nameplateAllowOverlap), Hide Enemy
  Nameplates out of Combat (CVar trocado em REGEN_DISABLED/ENABLED).
- Opções reorganizadas como no Retail: Display, Colors, General e Aura Filters.
  Perfis antigos migram threatColors -> threatColorMode "always", tankMode ->
  threatRole "tank" e showTargetBorder=false -> targetEffect "none". O card de
  Textures agora aponta para Display > STYLE.
- Correção junto com o port: a cor "Interrupt on CD" em EllesmereUI_Kick_335.lua
  estava invertida em relação ao Retail.

Não portado (motivo): focus (placas Wrath não identificam o focus), absorções
(sem API), cor de mobs de quest e ícone de objetivo (sem dados de quest por
placa), casts importantes/M+, glows de dispel/pandemic e CC lockout (exigem auras
de todas as placas), alcance/linha de visão e "Darken Out of Combat" (sem unidade
por placa), cor por tipo de caster, faction badge, estilos Blizzard/Classic e
bordas customizadas (dependem de atlas/arte Retail), hitbox e friendly
click-through (a área de clique é do cliente), threat %, ícone elite dourado
(atlas Retail; elites mostram "+" no nível) e Unlock Mode (Retail também não
registra elementos de nameplate).

# Nameplates 3.3.5 — 0.7

0.7: ElvUI-style look (rendering only; unit binding, auras and filters unchanged).
- Dark translucent backdrop with a thin dark border drawn OUTSIDE each bar. The old border sat behind the opaque bar and was never visible.
- Name above-left, level above-right (difficulty colour), health % centred on the bar.
- Cast bar under the health bar with spark, text inside the bar, and a bordered spell icon on the left spanning both bars. Cast colour yellow, red when shielded/uninterruptible.
- Target indicator: soft blue glow ring around the bar (replaces the invisible teal border). Mouseover highlight is a white overlay on the filled part of the bar.
- Native pure red/yellow/green/blue bars are mapped to a softer palette; threat colours use the same palette.
- Aura icons get a 1 px border and the timer is centred on the icon; raid marker sits to the right of the bar.
- Existing options (width, height, border size, textures, fonts, threat/tank mode) still apply. The target arrows from ElvUI are not included: the Wrath client cannot load PNG textures.

# Nameplates 3.3.5 — 0.6

0.6: identified target/mouseover aura lists refresh the GUID cache directly, so debuffs persist after deselection even when library events arrived before observation. Unknown timers are learned; removal/expiry/hide/reuse still clear the affected plate only. No name-based identity inference. New regression fails on 0.5 and passes on 0.6.

Earlier notes:

Implementação própria para as placas anônimas do Wrath. O TOC carrega LibAuraInfo-1.0 e
EUI_Nameplates_335.lua; os engines e recursos Retail copiados permanecem como
referência. A pasta original em D:/World of Warcraft/_retail_/Interface/AddOns/
EllesmereUINameplates não foi modificada. Use com Core 0.22 e Options 0.23.

0.5 fixes debuffs leaking onto nearby same-name plates. Combat-log name matches
are no longer used to assign aura GUIDs. Native target/mouseover observation
binds the recipient GUID to one plate; cached debuffs remain there after a
target change, until that plate hides/recycles. Unidentified plates stay empty.
Direct observation clears an old owner of the same GUID immediately; conflicting
selection alpha/native hover evidence uses the hover and rejects duplication.
validate_channel_aura_filters.py reproduces the old bug using 0.4 and checks
neighbor/reuse/isolation and one-owner transitions against 0.5.

0.3 corrige a caixa de aggro deslocada: uma borda própria de 2 px fica ancorada
diretamente na barra de vida inteira, acompanhando largura/altura, offset e
escala do alvo. Lê o estado e cor do indicador nativo, inclusive warnings,
independentemente da opção Threat Colors que colore o fill. Não aparece em
aliados ou quando não há barra visível. A textura do flash nativo é esvaziada
enquanto o módulo está ativo: a animação do cliente pode reescrever seu alpha
e fazer o desenho antigo aparecer fora da barra. Ao desligar restaura a textura
original; o tamanho/posição/clique do frame nativo continuam preservados.

0.2 mantém a opção existente Class Colored Names e aplica a cor aos aliados
conhecidos mesmo sem target/mouseover. Group/raid/player são consultados pelas
unidades Wrath, e target/mouseover/focus ensinam a classe de aliados fora do
grupo. O cache de observações dura até PLAYER_ENTERING_WORLD. O novo controle
Class Colored Health Bar, em FRIENDLY PLAYERS, colore a barra dos jogadores
aliados de modo independente; começa desligado para preservar a aparência.
Friendly Name Only continua usando Class Colored Names para a cor do nome.

As correspondências por nome servem somente para a cor da classe de placas
nativas de jogadores aliados (barra azul), sem fabricar unit token, GUID, cast
ou aura. Nomes ambíguos, NPCs e classes desconhecidas conservam a cor nativa;
para um aliado desconhecido fora do grupo, passe o mouse ou selecione uma vez.
Mudanças de grupo/raid atualizam o índice. Há testes de controles independentes,
classes diferentes, persistência após mouseover, nomes iguais, NPCs, reciclagem,
atualização do roster, cache de sessão/zona e reaproveitamento da opção existente.

Abra /enp. Use V para alternar as placas inimigas (atalho padrão do cliente).
As páginas Nameplates, Cast & Auras, Aura Filters e Fonts controlam largura/altura visuais,
texturas Flat/Blizzard, bordas, nomes, nível/elite, raid markers, seleção,
opacidade, cores de ameaça, cast e auras. Fonts/Textures globais usam os campos
implementados no Wrath. O módulo não oferece os presets Retail de Styles.

Vida percentual e progresso de cast vêm dos StatusBars nativos. A identificação
de alvo é inferida pelo nome e alpha de seleção do cliente; mouseover pelo nome
e highlight nativo. Ambos exigem um único candidato. Somente essas placas
recebem GUID da unidade, nome/tempo da magia e auras via UnitAura. Placas de nome
igual com seleção ambígua não recebem dados de outra unidade. Auras podem incluir
seus debuffs, os do pet e buffs; até oito ícones com stacks e tempo restante.
As outras placas conservam o progresso e ícone do cast nativo, sem nome/timer
inventados. Não há vida absoluta nem GUID disponível para todas as placas.

Os frames nativos conservam parent, posição, tamanho, scripts, mouse e alpha.
As novas regiões não recebem mouse. Largura e Target Scale alteram o desenho;
a área nativa de clique permanece do cliente. Additional Non-target Opacity é
um multiplicador adicional sobre a transparência nativa. O módulo esconde
somente a arte nativa com alpha zero e esvazia a textura do flash de ameaça,
preservando seu estado e atualizações.
Ao desligar restaura os alphas originais e o CVar showVKeyCastbar. Mudanças de
layout/CVars em combate são adiadas até PLAYER_REGEN_ENABLED.

Não há dependência ElvUI. Seus contratos Wrath de regiões/StatusBars foram usados
como referência: [ElvUI-WotLK Nameplates](https://github.com/ElvUI-WotLK/ElvUI/blob/master/ElvUI/Modules/Nameplates/Nameplates.lua).
Se uma placa já pertence a outro renderer com UnitFrame, ela não é capturada;
é emitido um aviso observado para desativar o outro módulo de nameplates.

Recursos Retail como C_NamePlate, nameplate1, absorções, NPC IDs de todas as
unidades, cast targets, quests, distância e containers de auras modernos não
foram portados ou emulados. Placas ficam ancoradas nas unidades pelo cliente;
não são elementos livres do Unlock Mode.

Validação local: validate_nameplates.py executa o Lite/safecall real e o módulo
em Lua 5.1, com uma fixture explícita de placas Wrath. Cobre descoberta/reuso,
vida, cast/canal, seleção única, auras/GUIDs, cliques/alpha preservados, ameaça,
raid markers, friendly name only, combate/restauração e páginas/cards reais.
Os arquivos de referência Retail são comparados byte a byte com o original.
Sintaxe dos sete addons e regressões de Chat/ActionBars/UnitFrames são verificadas.
Renderização e taint ainda dependem de teste no cliente real.

No jogo, confira V, seleção por clique/Tab, dois inimigos com o mesmo nome,
troca de alvo/mouseover, seus debuffs e os do pet, cast interrompível/canalização,
raid marker e ameaça. Entre/saia de combate após mudar opções. Desligue e religue
o módulo para conferir a restauração. Teste fontes/texturas compartilhadas e
a troca de perfil. Teste Class Colored Names com um aliado do grupo e outro
fora dele; tire o alvo/mouseover e confira o nome. Ative/desative Class Colored
Health Bar e Friendly Name Only. Ganhe/perca aggro com diferentes tamanhos,
offsets e Target Scale; confira a borda e desligue o módulo para restaurar a
arte nativa. Pacote: EllesmereUI-3.3.5-HUD-test-0.16.zip.

0.4: /enp > Aura Filters offers all/own/tracked, tracked/excluded spell IDs,
timed-only and stealable buffs. Own includes pet/vehicle; tracked IDs supplement
own mode; exclusions always win. GUID aura tracking uses the unchanged local
ElvUI/Libraries/LibAuraInfo-1.0 by Cyprias, author header preserved. ElvUI need
not be active. Native combat log tracks debuffs beyond target/mouseover; UnitAura
learns custom IDs/durations. Observed plates retain identity until hide/reuse;
unobserved plates stay empty until target/mouseover identifies their GUID.
Name-based aura inference introduced in 0.4 was removed in 0.5. Estimated durations are corrected by observation; combat
log lacks Stealable, so this filter confirms only direct native UnitAura buffs.
validate_channel_aura_filters.py exercises the actual library and Wrath events.
