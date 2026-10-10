# Unit Frames 3.3.5 — 0.25

0.25: com Classic WoW UI ou Blizzard Style, o ícone de líder em Top Left (padrão)
fica no canto de cima do retrato, como no PlayerFrame do 3.3.5 (coroa de 16px a
6,-8 de um retrato de 64px, escalado pelo tamanho do retrato do kit; espelhado no
retrato do lado direito, como o do target), em vez de dentro da barra de vida.
`ns.UF_PlaceStockLeader` é usado pelo quadro e pela prévia das opções; X/Y somam
ao ponto. As outras posições e o estilo EllesmereUI não mudam (o Retail também
põe a coroa na barra de vida nos estilos de stock).

0.25: o ícone de líder dos quadros (player, target, focus) usa
GetPartyLeaderIndex / IsPartyLeader em grupo em vez de UnitIsPartyLeader(unit),
que no 3.3.5 pode marcar mais de um membro. Em raide continua o rank da raide.
Ignora UnitIsGroupLeader global de addons de compatibilidade (!!!ClassicAPI), que
marcava o alvo como líder; o rank de raide procura raid1..N por UnitIsUnit.

0.24: opção Clear Focus Click na página do Focus (Shift/Ctrl/Alt + Right Click,
Middle Click, Shift + Left Click ou None; padrão Shift + Right Click). Grava
atributos seguros no quadro do focus (<mod>type<n>=macro, macrotext=/clearfocus),
então funciona em combate, onde o Clear Focus do menu fica escondido. Mudanças em
combate esperam PLAYER_REGEN_ENABLED; ReloadFrames reaplica (troca de perfil).

0.23: o menu de clique direito dos unit frames oferecia Set Focus / Clear Focus,
bloqueados pelo cliente quando vêm de addon. O menu agora se registra em
EllesmereUI.UnitMenuWithoutFocus (Core 0.65): fora de combate os dois itens
funcionam por um botão seguro sobre o item; em combate somem.

Sem bump: "Hide Sated / Exhaustion" também esconde o 81005 (lockout de Bloodlust do servidor).

0.22: dois modos novos no Debuff Filter (Aura Filters e o menu de debuffs de cada
frame): "Raid Debuffs" mostra só os debuffs de raid comuns de qualquer um, e "Own
and Raid Debuffs" junta os seus. A lista (Core, EUI_AuraFilters_335.lua) cobre
armadura (Sunder, Expose, Acid Spit, Faerie Fire, Curse of Weakness), dano mágico
(Curse of the Elements, Earth and Moon, Ebon Plague), crítico mágico (Improved
Scorch, Winter's Chill, Shadow Mastery), acerto (Misery), crítico recebido (Heart
of the Crusader, Totem of Wrath), dano físico (Blood Frenzy, Savage Combat), bleed
(Mangle, Trauma), AP (Demoralizing Shout/Roar, Vindication), velocidade de ataque
(Thunder Clap, Frost Fever, Infected Wounds, Judgements of the Just), cura recebida
(Mortal Strike, Wound Poison, Aimed Shot, Furious Attacks), conjuração (Curse of
Tongues, Slow, Mind-numbing Poison, Lava Breath), Judgements of Light/Wisdom e
Hunter's Mark. Compara pelo nome da magia, então vale qualquer rank. Tracked IDs
continuam somando e Excluded continua escondendo. O Retail usa a flag "important"
da Blizzard, que o Wrath não tem.

0.21: "Type Icon Position" no Dispel Overlay do player (como no Retail e no
Raid Frames): o ícone do tipo de debuff dispelável de maior prioridade num
ponto da barra de vida, com tamanho e offsets na engrenagem; funciona mesmo
com o overlay em None. Usa ícones das magias de dispel do Wrath (os do Retail
são atlas). "Only Dispellable by You" saiu da engrenagem e fica ao
lado, valendo para overlay, ícone e bordas. O focus ganhou Border Style,
tamanho e cor das auras, como player e target.

0.20: Heal Prediction funciona no 3.3.5 (player, target e focus). O elemento
do Retail depende de APIs que o Wrath não tem; `EUI_UnitFrames_335_HealPred.lua`
(arquivo novo, reinicie o cliente) desenha seus heals e os dos outros depois
da barra de vida, com as chaves do Retail (cor, outra cor, opacidade, textura,
Overheal). Valores do LibHealComm-4.0, agora embutido também aqui (o LibStub
mantém uma cópia só com o Raid Frames).

Sem bump: com o !!!ClassicAPI instalado, barras e retratos eram movidos para
ScrollFrames pelo SetClipsChildren dele. `PatchRegion` agora sempre usa um
SetClipsChildren vazio no próprio frame.

0.19: filtro "Hide Sated / Exhaustion" (Retail 9.4) na aba Aura Filters. Antes
Sated e Exhaustion eram sempre escondidos; agora dá para mostrar. Ligado por
padrão (debuffHideExhaustion, como na Retail). Raid Frames já tinham o "Hide
Bloodlust Debuff". Player Aura Bars da Retail não existem no port.

0.18: escudos (absorbs) nas barras de vida de player, target, focus e boss
(estilo do target, com "Show on Boss Frames"). Seção ABSORBS no 3.3.5: Absorb
Style, Absorb Opacity, Absorb Color, Placement e Show Overshield, com prévia nas
opções. O valor é estimado pelo Core a partir do combat log. Ligado uma vez por
padrão (Striped). Heal absorbs, barras de faixa e Glow Line não existem no 3.3.5.
Boss frames atualizam vida, poder e texto sem o boss estar no target/focus: o
cliente Wrath só manda `UNIT_HEALTH` pelo token do target/focus, não por `bossN`,
então os boss frames visíveis são lidos a cada 0,2 s. Barras de cast mostram o
nome do feitiço canalizado em vez de "Channeling" (terceiro retorno de
`UnitChannelInfo` no 3.3.5).
"Important Cast Glow" (barra de cast de target/focus, com cog e sync) fica
oculto no 3.3.5, também na página de Glows: depende de
`C_Spell.IsSpellImportant`, que o cliente não tem.

0.17: as condições de Visibility (combate, grupo, esconder sem alvo) davam
erro `RegisterAttributeDriver` (nil): essa API não existe no 3.3.5. As 7
chamadas (Register/UnregisterAttributeDriver) passam por
`ns.Wrath.RegisterAttributeDriver`/`UnregisterAttributeDriver`, que usam a
nativa quando existe e, no 3.3.5, mapeiam o atributo `state-X` para
`RegisterStateDriver(frame, "X", ...)` (o mesmo atributo). Era também o
motivo das caixas do menu Visibility só mudarem ao reabrir.

0.16: no Classic WoW UI a barra de power passava por cima da borda da arte
(saía da caixa embaixo e à direita). No Retail o contêiner das barras desenha
as duas como um grupo no nível dele, abaixo da arte; no 3.3.5 cada barra
desenha no próprio nível e a de power fica em vida + 2, acima da arte. Agora,
no 3.3.5, a arte dos frames clássicos sobe para acima das duas barras (vida + 3
ou power + 1), ainda abaixo do nível, dos textos, do brilho de absorção e do
ícone de descanso.

0.15: no Classic WoW UI a barra de recurso (mana, raiva, energia, poder
rúnico) usava a paleta do EllesmereUI (mana azul-claro) em vez das cores
originais do jogo. Agora, só nesse estilo, a cor vem do `PowerBarColor` do
cliente (mana azul-escuro, raiva vermelha, energia amarela), via
`ns.UF_PowerColor` / `ns.UF_PowerInfo`: barra, fundo, textos de power, Bottom
Text Bar e a barra de forma do druida. Os outros estilos continuam com a
paleta; tipos que o cliente não tem caem nela. Nenhuma opção é alterada.

0.14: no estilo Classic WoW UI (arte vanilla) a barra de vida usava a cor da
classe (o azul-arroxeado do bruxo) em vez do verde original. Ao entrar no
estilo, uma vez por perfil, todos os frames (player, target, focus, pet,
targettarget, focustarget, boss) recebem preenchimento personalizado verde e a
cor de classe é desligada. Um perfil que já estava no Classic recebe o verde no
próximo /reload, e as cores anteriores vão para o slot do visual EllesmereUI,
então voltar a esse visual devolve as cores do usuário.

0.13: o contorno por texto só aparecia na prévia. Ao salvar uma opção, o
recarregamento dos frames principais refazia a fonte de Left, Right e Center
Text (`SetMiniFont`) depois do layout, sem o contorno; agora ele recebe o
contorno do slot. O texto de power da barra de forma do druida segue o
contorno do Power Percent.

0.12: correção para outro jogador: em alguns clientes/addons o
`CreateMaskTexture` existe mas devolve nil, e um `UnitGetTotalAbsorbs` global
faz a barra de absorção ser criada; o frame do jogador parava com "attempt to
index local 'absorbMask'". O shim (EUI_UnitFrames_335.lua) agora devolve uma
textura escondida quando a máscara nativa vem vazia, e `AddMaskTexture` /
`RemoveMaskTexture` nativos nunca recebem essa máscara falsa. Teste:
backport-tools/validate_unitframes.py.

0.11: contorno por texto. As engrenagens de Left, Right, Center e Extra Text
(nome, vida, power, etc.), dos três textos da Bottom Text Bar e do Power
Percent ganharam o menu "Outline" (Module Default, None, Outline, Thick
Outline, Shadow) logo abaixo do Size, também nos frames menores. Vale ao vivo e
na prévia das opções. Padrão: Module Default (requer Core 0.50 e Options 0.86).

0.10: paridade visual com o Retail. O indicador de combate (estilos 0-5 e os
dois personalizados) aparecia vazio: as artes eram PNG ou TGA fora de potência
de dois. Agora há cópias TGA 64/128/512 em Media/Art_335/combat, geradas por
backport-tools/prepare_unitframe_media.py e redirecionadas por
EUI_UnitFrames_335_Media.lua. Ícones por ID numérico (fallback da barra de
cast, cast falso do Unlock Mode) mostram o ícone certo ou o ponto de
interrogação, nunca um quadrado vazio. Indicador de facção: os estilos PvP
Emblem, Honor Portrait e Map Flag (atlas do Retail) usam o ícone PvP do Wrath,
e o modo mercenário não quebra mais (UnitIsMercenary não existe no 3.3.5).
Retrato destacado: sem máscaras no 3.3.5, a arte é ajustada à abertura do
formato em vez de transbordar; Portrait, Circle e Pixels Circle mostram o
retrato redondo do Wrath inteiro (Mirror Portrait respeitado). Diamond,
Hexagon, Shield e quadrados mantêm o recorte quadrado. Sem máscara, o recorte
do zoom de classe e a forma exata não podem ser reproduzidos. Requer Options
0.63 e o EllesmereUI com o C_Spell.GetSpellInfo corrigido (tempo de cast).

0.9: as faixas de auras do Wrath seguem as chaves do Retail. Âncora,
crescimento, ícones por linha, espaçamento, recorte (80% da altura) e zoom;
debuffs presos aos buffs; deslocamento abaixo da barra de cast. Texto de
duração (tamanho, cor, posição, "Precise Below" em m:ss) e de acúmulos.
Borda das auras com textura, "Show Behind"/"Behind Unit Frame" e anel por tipo
de dispel (sólido, ou na textura da borda com "Textured Dispel Ring"). Encantos
de arma lideram os buffs do jogador no modo Show All. Clique direito cancela
buff/encanto fora de combate. Em alvo/foco, Purgeable Buff Glow para buffs
mágicos que a classe remove (Shaman, Priest, Mage, Hunter, Warlock) ou que
podem ser roubados. Sated/Exhaustion ficam ocultos.

Overlay de dispel do jogador: preenchimento, barra cheia, gradiente e
gradiente nítido (nova textura gradient-sharp.tga 256x64), "By Me" via
HARMFUL|RAID e borda personalizada na cor do dispel.

Também como no Forever: Threat %; barra de poder e humor do pet; druida com
Power Type Mana ou Mana + Form Power (nova barra da forma, em
EUI_UnitFrames_335_FormBar.lua). O alcance dos chefes usa IsSpellInRange do
3.3.5 e magias de cura do Wrath. Eventos de poder levam o tipo do evento
nativo (UNIT_RAGE = RAGE), não o tipo exibido. Dieta do pet devolve lista.
Absorção/cura recebida, Player Aura Bars e alternativas por spec não existem no
3.3.5 e não foram portados. Requer Options 0.62.

0.8 adds pooled aura indicators attached to the frame's own health bar.
Enable Unit Frames > Buffs > Select Frame: Player > Use Indicator Layout.
The normal aura lane is hidden only while this per-frame/per-aura-type mode
is enabled; switching it off restores the existing row and settings.
Eight indicators icons per aura type are preallocated before combat.
Events scan only the affected unit; vehicle tokens, live tooltips, stacks,
duration text/swipes, expiration and instance-group scope are retained.
Player/target/focus/boss and buffs/debuffs store separate configurations.
Defaults show healer assignments, personal defensives and external active
effects; ordinary buffs are added manually. External Own Only starts off.

0.6: corrige SetText(): Font not set no nível do visual Blizzard durante a
primeira criação dos frames. GameNormalNumberFont é opcional no Wrath; se o
FontString ainda não tem fonte, recebe a fonte selecionada do módulo e o
tamanho do nível/nome antes do refresh. Arquivo rejeitado usa a fonte nativa.
O nome continua fornecendo fonte, outline e FontObject quando disponível.
Teste com FontString sem fonte cobre player/target/focus, tamanho próprio,
herança posterior do nome, arquivo ausente, eventos de nível, skull e ocultação.
Validação local passou; aparência e funcionamento no cliente aguardam teste.

0.5: corrige a textura nil durante CreatePowerBar com a seleção Fade. As 15
texturas do catálogo com altura 40 passam a usar cópias TGA BGRA32 256x64 em
Media/Textures_335; os arquivos do Core permanecem intactos. Barras e previews
do módulo usam esses caminhos. Se uma textura de barra não produzir um fill,
o adaptador usa WHITE8X8; limpar explicitamente com nil continua funcionando.
O teste usa o catálogo/resolver reais, simula a rejeição de arquivo e reproduziu
a pilha exata em CreatePowerBar:7546 antes da correção. Passaram inicialização
com Fade, rebuild com todas as seleções, previews e fallback de arquivo ausente.

0.4: valida a existência do atlas antes de chamar SetAtlas, inclusive em clientes
Wrath com SharedXML. Corrige nameplates-icon-elite-gold no preview das opções.
Elite/rare usam um badge TGA do módulo (prata usa dessaturação), felicidade do pet
usa a textura antiga com coordenadas por estado, classe usa o sprite do Core e
casting usa UI-StatusBar. Atlas válidos continuam nativos; decoração sem atlas
nem alternativa conhecida fica sem textura. Inclui texturas de statusbars/masks.

0.3: evita SetRotatesTexture no Wrath após ERROR #132 no build 12340.
A orientação horizontal/vertical das barras permanece nativa; a textura usa
a rotação padrão do cliente. A proteção cobre criação, reload e previews.

0.2: corrige issecretvalue ausente antes de Options carregar. O engine e o módulo
capturam o predicado local do adaptador de Wrath; sem dependência de abrir Options.

Primeiro backport para testes. Use com EllesmereUI Core 0.14 e Options 0.12.
As pastas internas devem ser EllesmereUI, EllesmereUIOptions e EllesmereUIUnitFrames.

Inclui jogador, alvo, foco, pet, alvo do alvo, alvo do foco e boss frames;
vida/poder, textos, retratos, barras de casting/canalização, indicadores de líder
e assistente, combo points e runas. A atualização de poder usa os eventos de Wrath;
casting usa os retornos e identificadores de Wrath.

Auras básicas usam UnitAura: contagem, cooldown, tooltip, posição/tamanho,
debuffs de todos/somente seus/somente rastreados e exclusões por spell ID.
Buffs suportam somente seus, roubáveis e com duração.

Ainda não portados: Player Aura Bars, classificações de auras específicas do
Retail (Important, Big Defensive, Role, etc.), previsões de cura/escudo,
efeitos dependentes de máscaras/clipping, atlas sem alternativa e ping do Retail.
Alguns controles avançados herdados ainda aparecem nas opções; esses recursos
não são anunciados como funcionais. Retratos e barras usam uma apresentação
mais simples quando o cliente não oferece os recursos gráficos modernos.
Preenchimento invertido depende de suporte nativo do cliente.
Rotação automática da textura de preenchimento está desabilitada no Wrath.

Validação local: sintaxe Lua 5.1 de Core/Options/UnitFrames; contratos de eventos,
filtro por unidade, foco de EditBox, retornos de casting, timers, curvas, auras,
construção inicial/reload dos frames e registro da página de opções em ambiente
simulado. O teste falha se o módulo chamar SetRotatesTexture; cobre barras com
e sem textura e ambas as orientações.
Valida também atlas ausentes/existentes, fallbacks de ícones, C_Texture/AtlasUtil
e regiões retornadas por GetStatusBarTexture/CreateMaskTexture.
Isso não verifica renderização, combate, veículos ou proteção/taint dentro do WoW.

Teste no cliente:
1. Ative os três addons e faça /reload. Use /euf para abrir as opções.
2. Confira jogador/alvo/foco/pet e mudanças de alvo, vida e poder.
3. Teste casts, canais, interrupções e pushback; teste buffs/debuffs e tooltips.
4. Abra/feche as opções, inclusive após digitar num campo, e confira WASD,
   Espaço, 1–5, Tab, Escape e modificadores.
5. Confira frames em combate, veículos e boss frames quando disponíveis.
6. Envie qualquer erro Lua completo e informe a ação que o provocou.

0.7: cast fill/text/expiry share one render-frame engine driver; generic timer
shim no longer adds a second clock. Known Wrath channels show separators by
default; Show Channel Ticks in Main Frames > CAST BAR. Aura Filters adds player/
target/focus/boss selection, all/own/tracked, tracked/excluded spell IDs, timed
and stealable-buff controls. Native UnitAura indexes/tooltips stay intact.
Requires Core 0.22 and Options 0.23.
