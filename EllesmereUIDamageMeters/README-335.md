# EllesmereUI Damage Meters — Wrath 3.3.5a — 0.9

0.9 (Classic WoW UI): estilo Classic na página Style (`useClassicStyle`, igual ao
Retail). Cada janela usa a borda e o fundo de tooltip (`UI-Tooltip-Border`, inset
de 5), o header vira uma faixa de tooltip mais clara com linha fina embaixo, e os
botões do header usam a arte vanilla do Retail (engrenagem de Engineering, livro
de quest, refresh, plus/minimize) com ícone de magia por métrica. Na primeira vez
(`classicSeeded`) fundo 16/16/16, textura "blizzard" e trilha preta a 25%; o slot
de estilo guarda e devolve os valores ao voltar para EllesmereUI. Não portado: a
borda de aba de chat do Retail (usa a borda de tooltip) e o bloqueio dos controles
de borda/header nas opções enquanto o Classic está ativo. Trocar de estilo pede
/reload.

0.9: ID da magia no breakdown. O tooltip de uma magia (passar o mouse numa magia
com o jogador focado) ganhou a linha "Spell ID: <id>", e cada linha da janela
detalhada (Shift-clique) termina com "ID <id>" em cinza. Não aparece em Targets
nem no ataque corpo a corpo (sem ID). Vale também para a versão standalone.

Versão standalone (sem bump): `backport-tools/build_standalone.py --zip` gera a
pasta `EUIStandaloneDamageMeters`, só o Damage Meters (1.6 MB): sem Core, sem
painel do EUI e sem Unlock Mode. Um shim pequenino
(`backport-tools/standalone_src/DamageMeters_Standalone.lua`) cuida do ciclo da
addon, das configurações (em `EUIStandaloneDamageMetersDB`) e de uma janela de
configurações própria (`/edm` ou a engrenagem) com as abas Windows, Spell History
e Combat Data. As janelas se movem arrastando o cabeçalho. Ao lado da suite fica
inerte, com um aviso no chat. Em BAR TEXT há a opção Font (só no standalone):
Expressway ou qualquer fonte do LibSharedMedia, com prévia na lista; o
LibSharedMedia vai junto e também libera as texturas de barra.

0.8: absorções consumidas por escudos observados contam em Healing Done/HPS
para o dono identificado, com métrica Absorbs Done e detalhes por alvo/magia.
Rastreia Power Word: Shield, Divine Aegis, proc de Sacred Shield, escudos pessoais
e wards comuns, inclusive antes do combate. Absorbs Received permanece intacto.
Escudos de donos diferentes, caster desconhecido, escudos não suportados e
misses sem quantidade não recebem atribuição inventada. Escudos do mesmo dono
sem divisão confiável usam a magia agregada Absorbs (combined shields).
Expiração/remoção/morte/reset limpam os escudos. Combate pode começar por miss.

0.7: a textura das barras aceita chaves `sm:` (formato do resto do EUI)
além de `lsm:`, então perfis com texturas da SharedMedia carregam certo.

0.6 ports the remaining Retail features and look:
- Windows: flat black body, dark header with accent title, Atrocity bars,
  18 px rows. Untouched profiles switch once (styleVersion 2); customised
  values are kept. Header icons, right to left: Settings, Segment, Meter
  Type, Reset, then + (window 1, up to five windows) or x (deletes an
  unlocked window). Options: header icons on mouseover, hide Reset.
- Corner grip and padlock fade in on hover. Shift locks the first axis
  moved; width/height snap to other windows and title drags snap to their
  edges (Disable Snapping per window). Locked windows cannot move, resize
  or close.
- Hover breakdown: up to 15 spells (or 8) and the top three targets, with
  scale, anchor (row/center/left/right) and bar texture options. Death
  recaps draw the victim's health at each hit plus overkill.
- Standalone combat timer (preview while options are open, corner anchors,
  outline/border/strata, Unlock Mode element).
- Typed keybinds for Reset Data and Show / Hide Windows (override bindings,
  applied after combat and restored after LoadBindings), optionally also
  hiding the timer and Spell History.
- Spell History: icon strip and bar window of the player's casts, with
  failed/interrupted outcomes, hide rules and Unlock Mode. Wrath cast events
  carry only spell names, so casts are matched by name.

0.3 adds a live hover breakdown with spell icons, amounts/percentages,
target bars and Other totals. Left-click a player to replace that meter
with the person's spell bars. Its footer selects Spells/Targets; Back
returns to group. Spell bars include native icons and hover hit/crit/range
information. Mouse wheel scrolls. Death focus provides recorded recaps;
right-click opens the separate detailed statistics window. Reports follow
the displayed group/focus view and still require explicit Send.
Focus is transient per-window state. View/profile changes and reset clear
it; hover is cleaned up on reorder/hide. Tooltip rows are preallocated.

0.2 adds independent background, bar and header/footer opacity controls.
Names and values default to OUTLINE with black shadow so white class bars
stay readable. Font Outline and Show Specialization Icons are per-window.
Player talent data and throttled native group inspection provide spec icons;
class icons appear until talent data is available. Inspection runs outside
combat, respects the native Inspect UI/other queries and verifies GUIDs.
Known segment icons are retained across talent switches. No external
cache/library is used. Existing windows retain their values and gain the
new defaults. Native talent availability/range can delay group icons.

An independent implementation of the combat functions needed on Wrath.
The installed Details main addon was inspected as a protocol reference;
no separate Details plugins were installed. No Details code, libraries,
globals, plugin APIs or SavedVariables are required or loaded here.
The original EllesmereUI Retail Lua/media are retained byte for byte as
unloaded references. Only the EUI_DamageMeters_335 files run.

Open `/edm` or EllesmereUI > Damage Meters. Two windows (damage/healing)
start enabled; create up to four in Windows. Change metric by clicking
the header and segment by clicking the footer. Scroll those menus for
additional entries. Drag the header or use Unlock Mode. Scroll rows;
left click focuses that player inside the meter, right click opens statistics.
The deaths view opens the last 20 seconds (up to 40 damage/heal events)
before each observed death. Spell entries have native spell tooltips.

Included: damage/DPS, healing/HPS, overheal, healing received, damage taken,
enemy damage taken, friendly/self damage, absorbs received, blocked/resisted
damage, misses/avoidance, interrupts, dispels/spellsteal, casts, resurrections,
crowd-control breaks, resource gain events and separate mana/rage/focus/
energy/runic amounts, buff/debuff uptime and current-target native threat.
Default collection concerns combat involving the player/group; unrelated
outsider combat is ignored. Group Only controls actor display, while enemy
damage taken deliberately displays affected enemies. Pet/guardian merging
uses roster ownership and summon events; toggling affects future events.

Current/last, overall and 1–30 saved segments are selectable. DPS/HPS divide
by encounter duration, rather than per-actor activity. The end grace allows
late/continuing combat to join the segment; duration freezes when group
combat stops. Overall rows combine live/current summaries without copying
the full spell/target history on each refresh. Spell tables merge on demand.

Settings live in EllesmereUIDamageMetersDB through the EllesmereUI profile
system. Combat history is separate, per character, in this module's own
EllesmereUIDamageMetersHistory SavedVariables. It survives logout/reload
when Save History Between Sessions is enabled and is excluded from UI
profile exports. Reset requires confirmation and is blocked during combat.
Disabling collection unregisters CLEU and hides its windows/popups.

Wrath limits: absorbed damage belongs to the recipient. The collector does
not invent a shield caster from ambiguous damage-log absorption fields;
shield healing is not added to Healing Done. Aura uptime is the sum of
observed aura seconds across targets, not a universal 0–100% percentage;
pre-combat helpful auras are seeded from native UnitAura. Resource amounts
of different power types are not mixed. Threat is live for the selected
target and is not a historical combat-log estimate. Combat-log visibility,
unseen pet ownership and server-specific events can limit completeness.
This implementation does not load arbitrary Details plugins or import its
historical data, and is not a promise of parity with every Details feature.

The R button opens a local copy/preview. Only Send queues chat messages;
channel availability is checked, messages are paced, and module disable
cancels the queue. `/edm show`, `hide`, `toggle`, `reset`, `report`, `spells` are also supported.
All runtime frames are unprotected, rows are preallocated, native frame
creation/Escape bindings/game menus are untouched. Report EditBoxes never
autofocus and clear focus on hide. Client rendering/real encounter totals
still require in-game review.

Validation: `python backport-tools/validate_damagemeters.py` executes the
actual Lua 5.1 Core lifecycle, native eight-field CLEU parser, segmented/
overall calculations, pets, statistics, recaps, aura timing/reconciliation,
history reload/retention, threat, profile callbacks, windows, options,
Unlock Mode and explicit report flow with Details unavailable. It checks
native CreateFrame identity, font-before-text, no row allocation during
combat refresh, Lua compilation and unchanged Retail references.
