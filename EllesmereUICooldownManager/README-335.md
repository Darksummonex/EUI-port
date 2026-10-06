# EllesmereUI Cooldown Manager — Wrath 3.3.5a — 0.3

0.3: texturas das Tracking Bars incluem a LibSharedMedia. O Cast Sound da
barra FocusKick mantém os 5 sons da Blizzard (`PlaySound`) e agora lista os
sons do EUI e da SharedMedia, tocados com `PlaySoundFile`.

## Novidades da 0.2 (português)

A 0.2 reconstrói o módulo sobre o modelo de barras do Retail. O rastreamento é
próprio do Wrath (livro de feitiços, GetSpellCooldown, UnitAura, talentos e
eventos SPELL_UPDATE_COOLDOWN/UNIT_AURA), sem C_CooldownViewer nem outras APIs C_*.
Só executam os cinco arquivos EUI_CooldownManager_335_* listados no TOC. Os Lua
originais do Retail continuam na pasta, intactos e não carregados.

**Barras CDM**
- Cooldowns, Utilidade e Buffs, mais barras personalizadas e uma barra FocusKick
  (interrupção do foco ou do alvo, com texto de aviso e som).
- Layout: tamanho do ícone, linhas, espaçamento, direção de crescimento (com
  centro), direção das linhas e orientação vertical.
- Limite de ícones com transbordo para outra barra; ancoragem a outra barra ou
  ao cursor; deslocamento adicional.
- Opacidade, esmaecer fora de combate, camada (strata), fundo da barra e o
  motor de visibilidade do EUI (modos e opções).
- Ícones: zoom, recorte, formato circular, borda com cor, estilo e cor de
  classe, e fundo.
- Textos de tempo, pilhas/quantidade e atalho (com abreviação), cada um com
  posição, tamanho e cor.
- Tooltip, dessaturar em recarga, cor de fora de alcance e de mana
  insuficiente, opacidade do giro, "só números", espelhar teclas pressionadas,
  trinkets passivos e ocultar itens ausentes.
- Estados de recarga do Retail: sempre mostrar, opacidade reduzida, ocultar em
  recarga ou quando pronto (com ou sem manter o lugar), brilhar quando pronto ou
  quando pronto e utilizável.
- Brilhos de proc, aura ativa, máximo de pilhas, pandemia e buff, usando a
  numeração de brilhos do CDM.
- Estado ativo: o buff curto do próprio feitiço, um ID de aura ou uma duração
  após o lançamento.
- Condições de talento por entrada.
- Predefinições de raciais, itens (pedra de vida e poções do Wrath, com troca
  automática quando acabam) e buffs (Heroísmo/Sede de Sangue, poções, Truques
  etc.).
- Listas separadas por grupo de talentos, com cópia para o outro grupo.

**Barras de rastreamento (Tracking Bars)**
- Aura (jogador, alvo, foco ou mascote) ou recarga de feitiço.
- Aparência: largura, altura, vertical, preenchimento invertido, encher para
  cima, texturas do Core (TGA), cor ou cor de classe, gradiente, faísca e borda.
- Ícone, textos de nome, tempo e pilhas, e decimais.
- Pilhas: limite de cor, barra por pilhas com marcas, e brilho de pandemia.
- Grupos com direção e espaçamento próprios.

**Brilhos nas barras de ação (Bar Glows)**
- Acendem botões do EUI ActionBars, da Blizzard ou do ElvUI enquanto uma aura
  está ativa (ou ausente), com pilhas mínimas, só em combate, estilo e cor.
- As molduras de brilho são criadas fora de combate.

**Modo de desbloqueio**
- Cada barra CDM (CDM_<barra>), cada barra de rastreamento (TBB_1 a TBB_20) e
  cada grupo (TBBG_1 a TBBG_4) tem mover próprio.
- Cada um também tem painel "Element Options" que abre a página e a seção
  certas.
- Perfis 0.1 são convertidos automaticamente: as barras indexadas, as
  "Tracking Bars" antigas e os "Highlight Spell ID" das auras.

## Não portado

- Ícone/assistente de rotação: o Wrath não tem C_AssistedCombat.
- Ocultar ou abrir o CDM da Blizzard: ele não existe no 3.3.5a.
- Cargas de feitiço e linhas de carga: o Wrath não tem cargas. As opções
  "só cargas" e "ocultar texto de carga zero" valem só para itens.
- Cor do giro e cor do giro ativo: o Cooldown do Wrath não tem SetSwipeColor.
  A borda do giro só funciona se o cliente expuser SetDrawEdge; caso
  contrário, a opção fica desativada.
- Formatos com máscara além do círculo: não há MaskTexture. O círculo usa
  SetPortraitToTexture.
- Estilos de ícone e barra com atlas da Blizzard moderna: substituídos pelo
  anel UI-Quickslot2 e pela borda da barra de lançamento clássica.
- FocusKick preso à placa de nome: virou uma barra móvel.
- Regras internas de "FakeActive" do 12.0: substituídas por "Active
  Duration" por entrada.
- Biblioteca de layouts de feitiços, sincronização RPT, seletor visual de
  feitiços do Retail e visibilidade de moradia/voo dinâmico: não existem no
  Wrath. Os feitiços entram por ID, pela lista aprendida, pelas raciais ou
  pelas predefinições.
- Poções e itens do Retail: substituídos pelas versões do Wrath.

`validate_cooldownmanager.py` cobre:
- o ciclo de vida real do Core e a migração da 0.1;
- os movers e painéis do modo de desbloqueio;
- resolução e estados de feitiços, itens e auras, brilhos, talentos,
  transbordo, ancoragem e FocusKick;
- barras de rastreamento e grupos, Bar Glows e atalhos;
- as páginas de opções, a ausência de criação de molduras em combate e a
  compilação em Lua 5.1.

A renderização nativa ainda precisa de revisão no jogo.
