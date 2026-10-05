# Minimap 3.3.5 — 0.4

0.4 ports every Retail feature and look that Wrath can run.
- Shapes: square, rectangular (Retail crop mask, 256x192 window, hit insets),
  circle (disc border sized for circle_mask's 104/128 fill, which 0.3 hid
  under the map) and textured circle (EUI textured ring for the Retail atlas).
- Borders: size, opacity, solid strips outside the visible rect or the core
  textured border styles, custom/accent/class colour, show behind. 0.3's
  "class colour" flag migrates once to Retail's borderUseClassColor.
- Style: EllesmereUI or Classic WoW UI (vanilla ring and zone banner, native
  zoom buttons at vanilla anchors, ring-bordered indicators orbiting the map).
- Indicators: tracking (Wrath tracking menu), calendar (day, saved instances
  and server time on hover), mail (row or map corner with offsets, senders on
  hover), Retail black backgrounds, button size, element row position/spacing/
  distance; round maps chain them beside a top clock. The native Blizzard
  buttons stay alpha 0 and are restored on disable.
- Addon buttons: always collected into the Retail flyout (grid, junk-texture
  stripping, auto/manual grow direction, outside-click close); ungrouped
  picker, button row position/spacing/distance, backgrounds, Shift-drag Free
  Move with click-through blocking and Reset Button Positions. A lone button
  sits on the row with no flyout button.
- Extra buttons: Friends Online (guild, Real ID and character friends, notes,
  row cap; left-click whispers, right-click invites), flyout button toggle,
  extras on mouseover.
- Text: clock and zone as Inside/Map Edge boxes with ten positions, scale and
  offsets; Retail clock format; coordinates always/hover, position, scale;
  FPS/MS segments with divider, size, scale, interval, position, offsets;
  instance difficulty as text (5N/25H, tier colours); accented descriptions;
  saved-instance hover on clock and FPS; custom tooltip size.
- Visibility: shared Visibility Options list (instances, mounted, target,
  enemy target and the other lanes the 3.3.5 core evaluates).
- EllesmereUI style zoom buttons appear while the map is hovered.

Wrath substitutions: lockouts show the reset timer (no encounter progress API)
and no weekly reset row; latency is a single value (GetNetStats has no world
MS); Friends Online and the flyout button use EUI glyphs converted to TGA by
backport-tools/prepare_minimap_icons.py. Not ported (no Wrath equivalent):
Great Vault, M+ portals, crafting orders, Omnium Folio, Addon Compartment,
housing, Blizzard 12.1 Style.

0.3 dispatches every native-window menu action through Wrath securecall.
Where available, the menu calls the original native toggle by name; it
otherwise invokes a native micro button through securecall. Native button
availability/disabled state, arguments, combat guard and dismissal remain.
This avoids carrying the menu callback context into native UIPanel state
which is later closed by Escape. No native window hide handler, Escape
binding or protected-action error handler is replaced or suppressed.
Source reviewed for the reported Spellbook close path:
https://github.com/wowgaming/3.3.5-interface-files/blob/main/SpellBookFrame.lua
https://github.com/wowgaming/3.3.5-interface-files/blob/main/UIParent.lua
Automated checks verify securecall dispatch for every menu route and native
CreateFrame identity preservation. Lua fixtures cannot prove native taint
behavior; repeat middle click > Spellbook/other windows > Escape in client.

0.2 restores the middle-click micro menu using a native EUI popup rather
than depending on EasyMenu. Character, talents, spellbook, professions,
group finder, achievements, quests, PvP, friends, guild, calendar, game menu
and support use native buttons or native window toggles. Professions falls
back to the Wrath Skills tab. Optional modern windows appear only when a
native button exists. Menu fonts and hover accent follow EUI. Outside click,
Escape, minimap hide, setting/module disable and combat entry close it.
Open Micro Menu on Middle Click remains selectable in Minimap options.
Original minimap scripts and mouse state are restored when disabled.

Use com EllesmereUI Core 0.14 e Options 0.12. UnitFrames 0.5 pode continuar ativo.
Pasta original: D:/World of Warcraft/_retail_/Interface/AddOns/EllesmereUIMinimap.
O original EllesmereUIMinimap.lua e Media foram copiados e preservados; o TOC
carrega somente EUI_Minimap_335.lua, uma implementação específica para Wrath.
As opções carregam EUI_Minimap_335_Options.lua; a página Retail fica como referência.

Inclui:
- Formato quadrado/circular, tamanho, borda sólida/cor de classe, opacidade.
- Posição salva com Shift + arrastar ou integração com Unlock Mode; bloqueio.
- Zoom por roda, zoom salvo, temporizador real para retornar ao nível zero.
- Relógio local/servidor em 12h/24h, zona/subzona e cor de PvP.
- Coordenadas GetPlayerMapPosition e FPS/latência do GetNetStats do Wrath.
- Elementos nativos de zoom/tracking/correio/calendário/dificuldade/filas.
- Agrupamento opcional de botões de addons no popup +; tamanho e ocultação.
- Menu de atalhos no clique do meio usando EasyMenu do Wrath.
- Visibilidade Always/Never/Mouseover/combate/grupo e filtros de montaria/alvo.
- Mudanças de layout em combate ficam pendentes até PLAYER_REGEN_ENABLED.

Desabilitar o módulo restaura pai, pontos, tamanho, escala, alpha, máscara,
scripts de mouse, zoom, CVar de rotação, decoração e botões capturados.
Não captura teclado. As ações próprias dos botões de addons são preservadas.
As coordenadas ficam vazias enquanto o mapa-múndi está aberto, para não alterar
a região que o jogador está consultando. Após fechar, retomam a zona atual.

Esta primeira versão não inclui bordas texturizadas, máscara retangular,
artes Retail de estilo Blizzard, Great Vault, portais M+, housing, Omnium Folio,
Addon Compartment ou o tooltip Retail de amigos. As opções desses recursos não
são expostas. Flags compartilhadas de estilo clássico/Blizzard usam o círculo
compatível. Botões protegidos de outros addons não entram no agrupamento.

Validação: sintaxe Lua 5.1, inicialização e aplicação reais do módulo em mock,
formato/textos/contexto do mapa/zoom/menu/arraste/Unlock Mode, ações dos botões,
visibilidade, fila de combate, restauração/re-enable, registro e setters da página.
Inclui regressões de UnitFrames, foco de EditBox, widgets e visibilidade.
Renderização, taint e integração com outros addons exigem teste no WoW.

Teste: abra /emm ou a página Minimap no painel; confira os formatos e textos;
teste zoom, Shift + arrastar, + e botões nativos. Desabilite/reabilite o módulo
e confira a restauração. Teste opções, teclado, combate e mudança de zona.
