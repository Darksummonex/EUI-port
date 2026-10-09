# Resource Bars 3.3.5a — 0.5

0.5: Latency (Spell Queue) Overlay funciona sem evento SENT, usa latência
world quando disponível e mantém a zona visível nos canais. Wrath usa a
latência nativa como fallback; cor e texto em ms continuam configuráveis.

0.4: as texturas das barras incluem a LibSharedMedia e chaves `sm:` são
resolvidas em jogo.

Native Wrath resource displays with EllesmereUI fonts and flat bar textures.
Open EllesmereUI > Resource Bars, or /erb. Select a bar in the single Bars page.

- Player power: mana, rage, energy and runic power, using native power colors.
- Optional player health with a class-color toggle.
- Rogue/Druid Cat combo points; six DK runes with type colors/recharge timers.
- Shaman totem duration bars in native Fire/Earth/Water/Air order.
- Optional player cast/channel bar, spell icon, name and timer.
- Optional GCD bar using the native 61304 cooldown marker; ability cooldowns
  longer than 1.7 seconds are excluded.
- Six independent positions in Edit Mode, with automatic previews of enabled,
  class-supported bars. The panel also provides Preview/End Preview buttons.
- Global Fonts/Textures edit the same profile fields. Fifteen fill textures
  are supplied as Wrath-compatible power-of-two RGBA TGA assets.

Health and Cast Bar start disabled to avoid redundant displays in an existing
HUD. Enabling Cast Bar suppresses the native CastingBarFrame alpha and restores
its previous alpha when disabled. UnitFrames' own cast bar is configured separately.

Only EUI_ResourceBars_335.lua is loaded. Original Retail sources are preserved;
Retail secret-value APIs, modern spec mechanics, Forever/12.1 helpers and
swing-timer/threshold extensions are not loaded in this initial Wrath module.
Resource frames and settings are local-player displays, not group unit frames.

validate_inventory_resources.py exercises native power types, Rogue/Cat/DK/
Shaman resources, cast/channel/delayed/stale-stop events, GCD expiry, native
cast restoration, combat deferral, profiles, fonts/textures and mover callbacks.
In-game visuals, native taint and modified-client behavior still require testing.

0.2: cast/GCD fills update every render frame; class resource work keeps the
.05s throttle. Known Wrath channels show pulse separators by default. Toggle
Show Channel Ticks under Bars > Player Cast Bar. Native endpoints account for
haste; pushback retains initial pulse spacing; unknown spells get no invented
markers. Core EUI_ChannelTicks_335.lua is shared with UnitFrames.

## 0.3 (pt-BR)

O módulo foi reconstruído sobre o esquema de configurações do Retail
(`health`, `primary`, `secondary`, `castBar`, `gcdBar`, `swingTimer`,
`totemBar`, `callTotemBar`, `general`), em cinco arquivos carregados:
`EUI_ResourceBars_335.lua` (núcleo), `_Bars`, `_Cast`, `_Swing` e `_Totems`.
Perfis da 0.2 são migrados uma vez (posições viram `unlockPos`).

- Páginas iguais às do Retail: "Class, Power and Health Bars", "Cast Bar",
  "GCD Bar", "Swing Timer" e "Totem Bar".
- Unlock Mode usa as chaves do Retail (`ERB_Health`, `ERB_Power`,
  `ERB_ClassResource`, `ERB_CastBar`, `ERB_GCDBar`, `ERB_SwingTimer`,
  `ERB_TotemBar`, `ERB_CallTotemBar`). Cada elemento tem mover,
  redimensionamento (exceto os de ícones) e painel "Element Options"
  registrado em `_ELEMENT_SETTINGS_MAP`.
- Vida/Poder: orientação horizontal e vertical (para cima/baixo), textos do
  Retail, cor de classe/poder/personalizada, gradiente, opacidade do
  preenchimento, limiar, faixas de cor, linhas de marcação, suavização,
  visibilidade (modos + opções compartilhadas), esmaecer fora de combate,
  ocultar por forma de druida, borda sólida/estilos do Retail/estilo Classic.
- Barra de mana enquanto transformado (druida), faísca de regeneração de mana
  e previsão de custo de feitiço pelos módulos compartilhados do núcleo.
- Recurso de classe: pontos de combo (ladino, druida em forma de gato) e as
  seis runas de DK (ordem do Blizzard ou prontas primeiro, modo simples,
  cor de recarga, contagem regressiva). Opção de mostrar a arte original do
  Blizzard (RuneFrame/ComboFrame) no lugar.
- Cast bar: ícone à esquerda/direita, faísca, textos com posição, ticks de
  canalização com cor e último tick, latência, duração total, cor de
  ininterruptível e de interrompido.
- GCD bar com orientação, esvaziar, faísca, só em instância e só instantâneos.
- Swing timer (novo): mão principal, secundária e à distância pelo combat log,
  Heroic Strike/Cleave/Maul na fila, parry haste, mudança de velocidade,
  alcance e ocultar quando parado.
- Totem bar com ícones, cooldown, timer, direção de crescimento e opção de
  esconder o TotemFrame; Call Totem Bar move a MultiCastActionBarFrame só
  fora de combate.

Não portado: valores secretos e curvas do Retail, arte Blizzard Style
(atlas), recursos de especializações modernas (poder sagrado, fragmentos,
chi, cargas arcanas, essência, stagger, maelstrom, Ebon Might, Arcane Soul,
Ignore Pain, cargas de guerreiro, Devourer), estágios de empower, Eclipse,
cartões de limiar por especialização, ocultar com gamepad, pings e destruir
totem com clique. `validate_resourcebars.py` cobre o módulo.
