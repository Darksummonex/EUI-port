# Quest Tracker 3.3.5 — 0.3

0.3: paridade com o Retail. Auto Accept agora também escolhe a missão em
diálogos de NPC (gossip e saudação de missões), com "Prevent Multi Quest
Accept": um NPC que oferece várias missões fica manual. Auto Turn In entrega
missões com uma única recompensa e seleciona, no gossip, a missão já completa
(quando o cliente informa). Quest Item Hotkey procura o item no diário de
missões (primeiro a missão rastreada) e só prende a tecla enquanto houver item;
sem item no diário, usa o botão nativo do rastreador. Arenas sempre escondem o
rastreador. A linha do topo usa a cor de destaque; Line Color pinta o divisor
sob o cabeçalho e o botão de recolher segue a Header Color. A sombra da fonte
segue a configuração de fontes. /eqt show, hide e toggle. Requer Options 0.64.

Open /eqt or EllesmereUI > Quest Tracker. Wrath's native WatchFrame continues
to handle quests, achievements, timers, map links, collapse controls and
quest-item clicks/cooldowns. EUI adds readable fonts, a background sized to
visible content, accent line, scale, width/height and visibility settings.
Move it using Unlock Mode. Disabling restores native geometry and text.

Quest Helpers are optional and default off. Auto accept/turn-in can be skipped
with Shift. Multiple reward choices and paid/material turn-ins remain manual.
Quest Item Hotkey, e.g. ALT-X, securely uses the watched quest's item (or the
first native tracker item button). Leave blank to disable. Rebinding and structural
changes defer during combat; no persistent keyboard capture or Escape hook.

EllesmereUIQuestTrackerDB is owned by EUI Lite and participates in EUI profiles,
presets and global/module font settings. No external addons/data are required.
Original Retail Lua/media remain unchanged and unloaded. Retail-only objectives
systems are not loaded on Wrath. The tracker displays what the native client
watches; this port does not invent Retail campaign/world-quest APIs.

validate_friends_questtracker.py verifies lifecycle/combat deferral, native
line hooks, background/font/visibility behavior, quest item hotkeys and native
clicks, Unlock Mode position, restoration, helper guards and Options pages.
Confirm rendering and native interactions in the real client.
