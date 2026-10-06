# Unit Frames 3.3.5 — 0.12

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
