# Action Bars 3.3.5 — 0.21

0.21: barra de experiência do Retail (Menu, Bags & XP Bars). Fill Style (plano ou
gradiente horizontal/vertical) com cor do XP e cor final, fundo com cor e opacidade,
Show Rested XP com cor própria. Quest XP Overlay: XP das quests completas à frente
do preenchimento (verde) e das incompletas depois (dourado), com Completed Quests
Only e Current Zone Only. Show Dividers: linha a cada 10% e marca a cada 5% (Dashed,
Dotted, Solid ou None), Smart Ticks esconde as marcas já passadas e Divider Text
escreve 10%..90%. EXPERIENCE BAR TEXT: sete posições (centro, esquerda, direita e
os quatro cantos fora da barra), cada uma mostrando um item: XP e Rested % (o texto
antigo, padrão do centro), porcentagem, valores, restante, rested, XP das quests
completas, nível, XP por hora, tempo para upar, tempo nesta sessão e tempo neste
nível. Tooltip mostra o restante, as quests completas e o XP por hora.
Wrath: o XP das quests vem da entrada selecionada do quest log (a seleção é
restaurada) e quests sob cabeçalhos recolhidos não contam. Time This Level pede
/played uma vez por sessão (o jogo imprime as duas linhas no chat). A sessão e o XP
por hora recomeçam no /reload. Sem os estilos de arte do Retail (Professions,
flipbook, Forever): usam atlas que o 3.3.5 não tem.
Também na 0.21, o layout da WeakAura "[Merfin] Experience Bar (Luxthos)": itens
"Percent (with Completed)" (50% (65%)) e "Completed % - Rested %" (laranja e azul),
Rested After Quest XP (o rested começa onde termina o overlay de quests), Show
Spark, Show at Max Level (barra cheia com nível e "Time played" no lugar de Time
This Level) e Keep Session on Reload (sessão e XP por hora seguem após um /reload
feito em até cinco minutos; o tempo neste nível é sempre guardado, sem outro
/played). O botão "Apply Luxthos Layout" aplica as sete posições, o gradiente
azul-roxo e as cores da WeakAura. Diferença: quests falhadas não contam como XP
de quests completas.

0.20: "Show Equipped Item Color" (Retail 9.4) em ICON EFFECTS. Desligado por
padrão: a borda verde redonda da Blizzard em itens equipados some. Ligado: a
borda usa a arte quadrada (ou o formato do botão) na cor da raridade do item,
lida do slot equipado; verde a 50% quando o item não é encontrado.

0.19: as setas de página da Barra 1 chamavam `ChangeActionBarPage`, que no
3.3.5 é exclusiva da Blizzard (popup "blocked from an action"). Agora são
`SecureActionButtonTemplate` com `type = "actionbar"` e `action =
"increment"/"decrement"`, a página padrão (1..6) da Blizzard.

0.18: Barras de Ação 7 a 10, desligadas por padrão (como a Barra 6). Cada uma
tem os próprios atalhos (categoria EllesmereUI Action Bars da tela de Key
Bindings e o Quick Keybind), mover no Unlock Mode e todas as opções de Bar
Display. O Wrath não tem slots de ação sobrando: as barras usam as páginas
7-10 (slots 73-120), as mesmas para onde a Barra 1 troca nas posturas e
formas. Para Guerreiro (Battle/Defensive/Berserker Stance nas páginas 7-9),
Druida (Cat 7, Prowl 8, Bear 9, Moonkin 10), Ladino (Stealth e Shadow Dance na
7) e Sacerdote (Shadowform na 7), a barra que divide a página mostra os mesmos
botões dessa postura, e a página da barra em Bar Display avisa isso. Ligar
"Disable Form Paging" na Barra 1 libera as páginas. As outras classes usam as
quatro barras livremente. Os modificadores de paginação da Barra 1
(Shift/Ctrl/Alt e alvo) também podem ir para as páginas 7-10. Bindings.xml
agora tem 60 comandos (Barras 6-10). Requer Options 0.84.

0.17: Diamond, Hexagon e Shield agora recortam o ícone no formato (antes só
ganhavam o contorno), com fundo de slot e swipe dentro da forma. Requer
Options 0.83.

0.16: "Custom Button Shape" do Retail, por barra (inclusive pet e postura):
None, Square, Circle, Curved Square, Diamond, Hexagon, Portrait e Shield. O
Wrath não tem máscara de textura, então Circle e Portrait desenham o ícone
redondo com SetPortraitToTexture (refeito a cada troca de ícone). Diamond,
Hexagon e Shield recortam o ícone em faixas horizontais finas (cerca de 1 px),
cada uma da largura da máscara da forma naquela linha; as faixas copiam
textura, cor de alcance/uso, dessaturação, transparência e visibilidade do
ícone. Essas cinco formas ganham fundo de slot com a forma. Square e Curved
Square mantêm o ícone quadrado com o contorno por cima. O contorno usa a arte de EllesmereUI/media/portraits, ajustada para a
abertura da forma encostar na borda do botão, e segue o Border Size e a cor (ou
cor de classe) da barra, como no Retail; com tamanho 0 some. Com forma, a borda
quadrada sai e as animações de pressionado, destaque e lançamento viram o
contorno da forma na cor escolhida. O swipe de recarga do 3.3.5 é sempre
quadrado: nas formas redondas ele encolhe para o quadrado inscrito no círculo,
e em Diamond, Hexagon e Shield para o maior retângulo dentro da forma.
A área de clique continua quadrada. None devolve ícone, zoom, borda e swipe.
Requer Options 0.82.

Não portado: a forma "Cropped", recorte dos cantos em Curved Square, swipe
com a forma, espessura própria do contorno e os botões nativos
de pet/postura continuam com o destaque quadrado da Blizzard.

0.15: Quick Keybind Mode com o atalho /kb (o Wrath não tem o
Blizzard_QuickKeybind, então a janela e a captura são do EUI). Passe o mouse
sobre um botão e aperte a tecla (com Shift/Ctrl/Alt, botões 3-5 do mouse ou a
roda) para atribuir; botão direito remove o atalho. Cada comando guarda até
dois atalhos, como na janela de Key Bindings. Vale para as Barras 1-6, pet e
postura. Enquanto o modo está aberto, todas as barras (menos as em Never)
aparecem com opacidade total. Okay salva, Cancel e Esc desfazem, Reset To
Default volta aos padrões e "Character Specific Keybindings" alterna entre
atalhos do personagem e da conta. Entrar em combate salva e fecha o modo.

0.14: o texto de atalho agora é abreviado como no Retail: Shift+1 vira S1,
Control+1 vira C1, Alt+Q vira AQ, botões do mouse viram M4/M3, roda do mouse
MwU/MwD e teclado numérico N5/N+. Vale para as barras do EUI e para os botões
nativos de pet e postura (estes só enquanto o módulo estiver ativo).

0.13: porta as funções e o visual do Retail que existem no 3.3.5. Cada barra
agora tem as próprias configurações de texto (atalho, macro, contagem e tempo
de recarga: tamanho, cor, posição e deslocamento), borda (tamanho, cor ou cor
de classe), fundo da barra (espaçamento, cor e borda), opacidade, click
through, orientação vertical, ordem dos ícones, direção de crescimento,
dicas, coloração fora de alcance e cor. Globais: zoom do ícone, fundo do slot,
dessaturar e transparência em recarga, opacidade do swipe, números de recarga
próprios do EUI e as animações de botão do Retail (Light, Medium, Strong,
Solid Color, Border e None) para pressionado, destaque e lançamento, com cor
de classe ou personalizada. A visibilidade usa o mesmo motor do Retail
(seleção múltipla, Any/All, instâncias, descanso, veículo, montado, alvo e
"Toggle Action Bar" com atalho fora de combate). A Barra 1 ganhou paginação por
Shift/Ctrl/Alt e alvo amigo/hostil, opção para desligar a paginação por forma
e setas de página. As opções antigas (visibility, showHotkeys, showMacroNames,
fontSize, rangeColor, tooltip, borda e iconCrop) migram uma vez para as novas
chaves por barra; sem mudanças, o driver de paginação continua idêntico. Os
contratos seguros (paginação, veículo, arrastar, atalhos) não mudaram. As
texturas de destaque viraram TGA 64x64 em Media/Textures_335. Requer
Options 0.59.

Não portado: formas/máscaras de ícone, paginação e visibilidade de
skyriding, housing, assisted highlight e one-button assist, brilho de proc,
rank de item, cargas, Quick Keybind (use o Key Bindings da Blizzard), mostrar
barras ao abrir o grimório ou arrastar, estilos Blizzard/Classic e end caps,
multiplicadores de fundo, borda e cor do swipe de recarga (o Cooldown do 3.3.5
não tem essa API), flash de atalho pressionado, texturas de interação nos
botões nativos de pet/postura, linhas de visibilidade das barras de dados e
animações de lançamento.

0.12 places the native stance/pet controllers and unused bonus bar shell
under a hidden parent while EUI is active. Blizzard Show/alpha/animation
updates cannot reveal a duplicate shell when entering a stance. Native
event registrations and EUI-reparented pet/stance buttons remain active;
EUI secure paging continues to handle bonus action pages. Disabling EUI
restores original parents, positions, alpha, visibility and native updates.
Checks simulate native Show/alpha reset in combat, enabled/disabled stance
headers, native button actions, restoration and existing secure paging.

0.11 hides its XP or reputation holder/mover while a visible DataBars block
displays that progress type. Existing native bar suppression stays intact.
Disabling/removing the DataBars block restores the configured HUD bar; no
saved ActionBars preference is changed.


0.10 keeps Player Buffs growing downward. Saved CENTER/BOTTOM anchors previously
moved the top row upward when the holder grew taller. The existing top-right
corner now stays fixed as rows are added/removed, and the saved position uses
that top anchor. Row offsets remain negative Y. Edit Mode drag sessions retain
their current anchor until committed; combat changes follow the existing queue.
Checks cover row growth/shrink, native timers/cancellation, drag, combat,
position persistence, restoration and independent debuff layout.

0.9 adds /eab > Action Bars > Select Bar > Bag Bar > Consolidate Bags.
This reduces the HUD to one native backpack button, which opens the unified
inventory when EllesmereUIBags is enabled. Equipped bag/keyring buttons retain
their native events and input handlers under a hidden parent; turning the
option off returns them to the full strip. Layout changes wait until combat
ends. Disabling the HUD restores original native geometry and parents.
The bag-slot strips inside inventory and bank windows remain independent.
Consolidation, combat deferral and restoration pass validate_actionbars.py.

0.8: retained MainMenuBar/art container mouse surfaces are disabled while EUI bars are active, allowing Bar 1 spell drops. Micro/bag children stay functional; disabling the module restores native mouse state. Real secure drag/paging/lock and HUD regressions passed; in-game input confirmation pending.

Earlier notes:

Core 0.15 integra os overlays legados Buffs/Debuffs à edição dos movers Player
Buffs/Player Debuffs: enquanto cada mover está habilitado, somente seu controle
real aparece no Unlock. O ActionBars 0.7 mantém as mesmas auras e posições.
Pacote atual da combinação: EllesmereUI-3.3.5-HUD-test-0.7.zip.

0.7 corrige self nil em IsUnlockModeActive do Core. As três chamadas ativas
de HUD preview, refresh durante drag e alpha mouseover agora usam dois-pontos
para fornecer EllesmereUI como self. O Core permanece intacto. A regressão
executa o método real extraído de EUI_UnlockMode.lua, sem stub permissivo;
reproduziu o erro antes do ajuste e passa depois, incluindo entrar/sair da
sessão Unlock com XP no nível máximo/facção vazia, hover e drag ao vivo.

0.6 corrige SetText(): Font not set na primeira atualização de XP/reputação.
UpdateData agora aplica a fonte antes de qualquer SetText, incluindo os ramos
rested, XP normal, reputação e facção vazia. A fixture rejeita texto sem fonte
nas FontStrings sem template dos data bars; reproduziu o erro antes do ajuste
e passa após a correção, incluindo mudanças de tamanho de fonte nos dois HUDs.

0.5 corrige GetScale nil na inicialização de NativeHUD: ExhaustionLevelFillBar
e ExhaustionTick são regiões Texture no Wrath. O caminho de XP agora captura,
esvazia e restaura essas texturas pelo estado de textura, sem métodos de Frame.
Snapshots gerais só leem/restauram escala quando disponível. A fixture expõe
as APIs realmente ausentes nessas regiões; reproduziu o erro da linha 38 antes
da correção e passou depois, incluindo restore de path/alpha/texcoords e re-enable.
Options 0.19 e os demais módulos permanecem na mesma versão.

0.4 / Options 0.19: /eab tem uma página Action Bars com Select Bar para os
oito grupos de action buttons e seis elementos HUD/auras. Layout e reset de
posição editam somente a seleção; Global Settings reúne controles comuns.
Hide Blizzard Bar Art remove/restaura texturas decorativas sem esconder os
containers e seus controles; mudanças em combate aguardam regen. As posições
e preferências existentes são mantidas. Micro/bags, XP/Rep e buffs/debuffs
podem receber dimensões/colunas separadas; campos antigos compartilhados são
usados até o usuário editar cada grupo. Atalhos dos movers abrem sua seleção.

XP usa preenchimento azul (0, .4, 1), rested roxo (.5, 0, .5, .8), fundo escuro
e borda plana, com fill/rested inset de 1px. Zero XP não colore a área vazia;
rested ausente/zero esconde sua camada. Media/Textures_335/elvui-norm.tga é
uma cópia byte a byte de ElvUI/Media/Textures/normTex2.tga instalado, usada
pelo estilo ElvUI Norm; ElvUI/Modules/DataBars foi consultado como referência.
Não exige carregar ElvUI. Reputação mantém a cor do standing da facção.

0.3 adiciona EUI_NativeHUD_335.lua e a página /eab > Blizzard UI (Options 0.18).
Micro Menu e Bag Bar recebem controles quadrados/escuros, com cliques, drag,
tooltips, disponibilidade e eventos nativos. Bag Bar inclui KeyRing quando
existente; Micro inclui Store/Collections/Paragon do Rebuffed. Hit rects seguem
o botão quadrado e são restaurados ao desligar; ícones próprios desses botões
continuam reconhecíveis. XP/rested e reputação observada usam barras planas com
fonte Ellesmere, porcentagem, tooltip e valores/eventos Wrath reais. XP oculta
no nível máximo e Rep sem facção observada; no Unlock ambas mostram sua área.

Há seis elementos reais no Unlock Mode: Micro Menu, Bag Bar, Experience Bar,
Reputation Bar, Player Buffs e Player Debuffs. Posições vão para barPositions
do perfil ActionBars, junto com os campos nativeHUD. Buffs/debuffs usam os
botões nativos com timers, tooltip e cancelamento preservados. Weapon enchants
e ConsolidatedBuffs seguem o grupo Buffs. Novas auras/reanchor nativo respeitam
os dois grupos separados; drag ao vivo não é sobrescrito por refresh de HUD.
Native BuffFrame/DebuffFrame, quando existente, acompanham o holder para que
o overlay legado fique sob o mover real. Não há mudança no Core 0.14.

Reconfiguração/movimento em combate ficam na fila; reanchors de auras só são
aplicados durante combate em frames não protegidos. Sair do combate reaplica
a fila. Desligar controles devolve os parents/âncoras, tamanho, escala, alpha,
hit rects, fontes e texturas capturados. Conteúdo dinâmico de bolsas e estado
das auras permanecem atualizados. As posições antigas das action bars são
preservadas ao migrar defaults com o NewDB real do Core.

0.2: OnInitialize usa a instância capturada do addon, pois xpcall em Lua 5.1
não repassa os argumentos extras do dispatcher do Core. Corrige self nil na
linha 261 e o erro subsequente ao ler barPositions no Unlock Mode. Callbacks de
posição toleram banco ainda ausente e OnEnable só registra elementos com banco.
O teste agora executa o safecall real do Core; antes da correção reproduziu
exatamente o erro da linha 261. Core 0.14 e Options 0.12 permanecem inalterados.

Use com Core 0.14 e Options 0.19. UnitFrames 0.5 e Minimap 0.1 continuam na base.
Abra /eab para configurar; use Unlock Mode para mover cada barra.

Esta implementação específica para Wrath carrega EUI_ActionBars_335.lua e uma
cópia isolada de LibActionButton-1.0 do ElvUI Wrath instalado. O main Retail,
Flyout e Media originais ficam preservados como referência e não são carregados.
Bindings-Retail-reference.xml preserva os comandos Retail; o Bindings.xml ativo
contém somente os 12 comandos de Bar6 para Wrath, carregados automaticamente.

Inclui seis barras de 12 slots (a sexta desabilitada por padrão), tamanho,
quantidade/colunas, espaçamento, posição, alpha, borda sólida/classe, crop,
fonte, hotkeys/macros, tooltip, cooldown, contagem e cores de alcance/recursos.
Arrastar/receber habilidades usa os handlers seguros da biblioteca. Lock permite
o modificador de PICKUPACTION nativo. Atalhos vêm dos comandos Blizzard existentes;
Bar6 fica na categoria EllesmereUI Action Bars da tela nativa de atalhos.
O módulo não grava novos bindings, não captura teclado e não depende do ElvUI.

Mapeamento: Bar1 página principal dinâmica; Bar2 página 6 (MULTIACTIONBAR1);
Bar3 página 5 (MULTIACTIONBAR2); Bar4 página 3 (MULTIACTIONBAR3);
Bar5 página 4 (MULTIACTIONBAR4); Bar6 página 2. Essas páginas são os slots reais
do jogo: Bar6 mostra os mesmos slots da página 2 da principal, não slots extras.
Formas/poses usam páginas 7–10, furtividade felina usa 8 e controle/bonus5 usa 11.

Página, visibilidade e ativação/liberação de atalhos passam por snippets seguros
e RegisterStateDriver; funcionam sem mover ou reconfigurar frames em combate.
Alterações de opções/layout em combate são aplicadas após PLAYER_REGEN_ENABLED.
Modo mouseover usa alpha e mantém a superfície para revelar a barra ao passar
o mouse. Pet e poses reutilizam os botões nativos, preservando clique, autocast,
tooltip, eventos e atalhos; têm posição, tamanho, colunas, alpha e visibilidade.

A interface de veículos, mira/ângulo e saída permanece nativa. Em vehicleui,
as barras customizadas se escondem e liberam os atalhos ao Blizzard. Controles
nativos de possessão e totems são preservados. HUD opcional é descrito acima.
Desabilitar o módulo restaura pais, âncoras, dimensões, alpha, escala e decorações
capturados, libera seus atalhos e atualiza os estados nativos de pet/poses.

Ainda não portados: flyouts Retail, barras 7–10 extras, Favor/Housing,
Quickdraw/Gamepad, efeitos de brilho/mascaramento, estilos Retail e layouts de
totems. Fonts/Textures mostram somente os controles aplicáveis
a esta versão; Styles não oferece estilos de ActionBars ainda não implementados.

Biblioteca: Libs/LibActionButton-1.0-335.lua mantém o copyright/licença BSD do
autor Hendrik Leppkes. A identidade da cópia foi alterada para
LibActionButton-1.0-Ellesmere335 e a integração opcional LibKeyBound foi removida.
O hook seguro opcional usa control:RunFor, compatível com os handles do Wrath.
Não altera nem atualiza a biblioteca do ElvUI.

Contratos nativos consultados no código FrameXML 3.3.5:
https://github.com/wowgaming/3.3.5-interface-files/blob/main/SecureStateDriver.lua
https://github.com/wowgaming/3.3.5-interface-files/blob/main/RestrictedFrames.lua
https://github.com/wowgaming/3.3.5-interface-files/blob/main/VehicleMenuBar.lua
https://github.com/wowgaming/3.3.5-interface-files/blob/main/PetActionBarFrame.lua

Validação local: backport-tools/validate_actionbars.py executa biblioteca, módulo,
snippets seguros, opções e cards Fonts/Textures reais em fixture Lua 5.1 com
APIs antigas. Cobre páginas em combate, formas/furtividade, retorno de veículos,
bindings/duas teclas/alterações, drag lock/receive, dados de botões, fila de layout,
restauração, unlock e XML. A fixture rejeita escritas inseguras em atributos em
combate, mas não reproduz taint nativo nem verifica renderização ou casts reais.
0.3 amplia a fixture com HUD nativo, micro/bag/keyring e hit rects, dados XP,
rested/reputação, max level/facção vazia e preview; seis movers/posições,
timers/cancelamento e weapon enchants, refresh/drag, combate/proteção,
restore/reuse, defaults/migração e MakeUnlockElement reais, nova página/card.

Teste no jogo: atalhos/click, arrastar habilidades, macro/item/cooldown, combate,
Shift+troca de página, poses/formas/furtividade, pet/autocast e entrada/saída de
veículo. Verificar /eab, mover via Unlock e desabilitar/reabilitar o módulo.
Em /eab > Action Bars > Select Bar, confira cada seleção e Hide Blizzard Bar
Art, inclusive desligando as skins micro/bags. Verifique XP zero, com/sem rested
e cores em diferentes classes, resets separados e persistência das opções.
Mova Player Buffs e Player
Debuffs separadamente, receba/perca auras e entre/saia de combate; confira
cancelamento/tooltip/enchant. Mova micro/bags/XP/rep e faça reload/relogin para
validar persistência real; teste XP abaixo de 80 e seleção de facção observada.
0.4 amplia a regressão com cores/texture/layers XP, esconder/restaurar arte,
fila em combate, página única/14 seleções, dimensões independentes, callbacks
antigos, resets selecionados, atalhos dos movers e migração de perfil real.
Pacote anterior do ActionBars 0.7: EllesmereUI-3.3.5-HUD-test-0.5.zip.
