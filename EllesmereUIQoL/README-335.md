# Quality of Life 3.3.5 — 0.17

0.17: Self Combat Text do Retail (Displays > SELF COMBAT TEXT). Dano recebido,
cura recebida, esquivas/aparos/erros e entrar/sair de combate sobem acima do
player frame no lugar do combat text da Blizzard, que fica oculto enquanto está
ligado. Animação Straight, Fountain ou Static, para cima ou para baixo, distância,
duração, críticos maiores, Stagger Hits, fonte, contorno, sombra, números
abreviados e cor por tipo. Move-se no Unlock Mode. O Wrath não tem C_CombatText
nem animações Path: os valores vêm do combat log (jogador ou veículo como alvo).
Arquivo novo (EUI_QoL_335_CombatText.lua): reinicie o cliente.

0.16: Auto Select Single Gossip (Retail 9.4). Quando o NPC tem uma única opção
de diálogo, ela é escolhida sozinha. Segurar Shift pula; desligado em
instâncias por padrão; NPCs com missão para pegar ou entregar não são tocados.
Engrenagem "Auto Gossip Settings": Hold Shift to Skip, Disable in Instances e
Ignore Low Level Quests (pula missões triviais, a menos que o Quest Tracker
aceite automaticamente as triviais). Cada diálogo é escolhido uma vez só até
fechar a janela. API Wrath (GetGossipOptions/SelectGossipOption).

0.15: Send Mail ganha uma seta ao lado do campo "To" com a lista de destinatários:
Alts (personagens deste reino e facção, salvos na conta ao logar em cada um),
Guild (roster da guilda, online primeiro) e Recent (últimos 15 nomes enviados
com sucesso). Clicar preenche o nome e passa o foco para o assunto. Opção
"Send Mail: Recipient List" na seção MAIL; painel próprio, sem o UIDropDownMenu
da Blizzard (evita taint).
Merchant: a roda do mouse sobre a janela do vendedor vira as páginas de itens
(pelos botões nativos Prev/Next). Opção "Merchant: Mouse Wheel Pages".

0.14: contador de FPS com nova cor padrão "Quality": FPS e cada latência ficam
verde, amarelo ou vermelho (60/30 fps, 100/250 ms), e os rótulos seguem a cor do
valor. Custom e Class Color continuam disponíveis em Text Color.
Shift-clique para anexar itens no correio usa `hooksecurefunc` em vez de
substituir `ContainerFrameItemButton_OnModifiedClick` (sem taint nas bolsas).

0.13: esconder as barras do DBM/BigWigs com o AbilityTimeline ativo saiu do
EUI (seção BOSS MOD BARS do Raid Tools e `EUI_QoL_335_BossBars.lua`) e foi
para o próprio AbilityTimeline, como no Retail: AbilityTimeline > Sources >
"Hide DBM bars" / "Hide BigWigs bars" (`BossBars.lua`, AbilityTimeline
335-0.2). Teste: `validate_abilitytimeline_bossbars.py`.

0.12: sons de alerta tocam chaves `sm:` de pacotes SharedMedia carregados
depois do QoL.

0.11: "EllesmereUIQoL has been blocked from an action only available to the
Blizzard UI". `EUI_QoL_335_Group.lua` fazia `StaticPopupDialogs =
StaticPopupDialogs or {}`: reescrever a global (mesmo com o mesmo valor) a
contamina, e os popups da Blizzard que chamam funções protegidas (Logout,
Quit, Release Spirit...) eram bloqueados em nome do QoL. A linha saiu; só o
campo `EUI335_DISBAND_GROUP` é adicionado.

0.10: Displays > ZONE TEXT ganhou "Zone Text Outline" ao lado de "Move Zone
Text": Blizzard Default, None, Outline, Thick Outline ou Shadow, aplicado aos
textos de zona, subzona e status PvP mostrados ao entrar numa área. Blizzard
Default restaura a fonte original do jogo (requer Core 0.50).

0.9: automação de grupo no estilo do Misc do ElvUI (EUI_QoL_335_Group.lua).
"Announce Interrupts" (QoL > GROUP) anuncia o feitiço que você ou seu pet
interromperam, com link, em Say, Emote, Party, Raid (cai para Party fora de
raide) ou Raid Only; Party e Raid usam o canal de campo de batalha dentro de
battlegrounds. "Accept Invites from Friends & Guild" aceita convites de grupo
de amigos e membros da guilda (ignora sufixo de reino), exceto se você já
estiver em grupo ou na fila do Dungeon Finder; ao contrário da opção do Friends
List, não depende da skin do Friends. Raid Tools ganhou o botão "Disband" (e
"Disband Group" na página de opções): após confirmação, o líder remove todos
(inclusive offline) e sai do grupo; nunca em combate. Teste:
backport-tools/validate_qol_group.py.

0.8: o Zone Text não tem mais mover no Unlock Mode nem Element Options. O nome
da zona fica fixo no topo (X 9 / Y 322 a partir do centro da tela) enquanto
"Move Zone Text" estiver ligado; uma posição salva pelo mover antigo é
descartada. Teste: backport-tools/validate_qol_zonetext.py.

0.7: com o addon AbilityTimeline ativo, as barras do DBM e do BigWigs somem da
tela (o timeline já mostra os mesmos timers). As barras ficam invisíveis e sem
clique, mas continuam contando: o DBM lê o tempo restante das próprias barras.
DBM: o anchor das barras (DBT) fica com alpha 0; BigWigs: cada barra vai para um
quadro transparente. Nenhuma opção salva do DBM/BigWigs é alterada. Tudo volta
ao desligar o AbilityTimeline, a fonte (DBM/BigWigs) dele ou a nova opção
QoL > Raid Tools > BOSS MOD BARS > "Hide DBM/BigWigs Bars While Timeline Is
Active" (ligada por padrão). "Move bars" do DBM mostra as barras enquanto move.
Novo arquivo EUI_QoL_335_BossBars.lua; teste: validate_qol_bossbars.py.

0.6: o nome da zona (o texto grande ao entrar numa área) não aparece mais no
meio da tela. O Wrath prende o ZoneTextFrame a 512 da borda de baixo, e com uma
escala de UI pequena (ex.: 0,62) isso cai no centro. Agora ele fica no novo
mover "Zone Text" do Unlock Mode, por padrão no topo: X 9 / Y 322 a partir do
centro da tela (em pixels, como o Unlock Mode mostra). Se a Blizzard ou outro
addon reposicionar o quadro, ele volta sozinho. Uma posição salva em 0,0 (o
centro quebrado) é limpa uma única vez; posições escolhidas são mantidas.
QoL > Displays > ZONE TEXT > "Move Zone Text" desligado devolve a posição da
Blizzard.

0.5: "Quick Loot" agora funciona como no Retail: pega tudo na hora mesmo com o
Auto Loot da Blizzard desligado, e segurar Shift ao saquear mostra a janela de
saque. Espaços travados (rolagem de grupo, master loot) são ignorados. Antes
ele só agia quando o Auto Loot estava ligado.

0.4 traz mais funções e o visual do Retail (novo arquivo EUI_QoL_335_Extras.lua
e nova página Displays nas opções). Tudo o que é automação começa desligado.
- QoL > Automation: "Auto Open Containers" abre caixas/bolsas com
  "<Right Click to Open>", uma por vez, só fora de combate e com vendedor,
  correio, banco, troca, leilão, banco da guilda e saque fechados. Se a caixa
  não abrir (bolsa cheia, trancada), não tenta de novo.
- Reparo e venda de lixo avisam no chat (valor, banco da guilda, ouro
  insuficiente, itens que não puderam ser vendidos). Train All fica ao lado do
  botão Train, desativa quando não há nada para aprender, mostra no tooltip
  quantas magias e o custo, e respeita os espaços livres de profissão.
- Hide Error Messages mantém visíveis os erros importantes do Retail (bolsa
  cheia, log de quests cheio, jogador morto...). O texto DELETE já vem com o
  foco no campo.
- QoL > Interface: esconder o aviso de screenshot, coordenadas do jogador e do
  cursor no mapa-múndi, item level na janela de troca de equipamento (flyout),
  remover transformações de itens de evento (Hallow's End, Noblegarden, peru do
  Pilgrim's, Noggenfogger; só fora de combate), indicador de descanso (ZZZ) no
  quadro do jogador do EUI com ajuste X/Y, e desativar o clique direito em
  inimigos (e em aliados durante o combate). O clique direito vira giro de
  câmera via driver seguro; nada muda em combate.
- QoL > Group: anunciar reset de instância no grupo/raide (mensagem
  personalizável) e aceitar sozinho o role check do Dungeon Finder (segure
  Shift para revisar).
- Displays (visual do Retail): FPS com latência world/local, rótulos, cor
  própria ou da classe, intervalo e tecla de atalho; Secondary Stats em linhas
  (Hit/Expertise/Armor Pen opcionais); aviso de durabilidade pulsando com cor
  própria e escondido em combate; alerta de combate com textos, cores e modo
  (entrar/sair); alerta de morte com ícone de caveira, nome na cor da classe e
  som; mira com comprimento, espessura, cor, borda, visibilidade (combate/
  instância) e cor quando o alvo está fora de alcance; novo texto de distância
  do alvo (faixas como 30-35, estilo LibRangeCheck); tamanho dos ícones dos
  rastreadores, movimento só em combate e som quando fica pronto.
- Cursor: cor própria, opacidade, só em instâncias e retícula central.
  Raid Tools: escala da janela (50-200%).
- Unlock Mode: 12 elementos (o novo Target Distance incluído), todos com
  "Element Options" levando à seção certa da página Displays ou Raid Tools.

Não portado (não existe no 3.3.5): filtro de expansão do leilão, Talking
Head, janela de histórico de loot, chaves Mítica+ e lista de grupos premade
(inscrição rápida, nota fixa), coleções para desembrulhar, privacidade do chat
de guilda das Communities, marcadores de chão (world markers), TTS, rastreios
de Time Spiral/Gateway, cargas compartilhadas de battle-res, Mastery e
Versatility. A correção do relógio 24h não é necessária (o CVar persiste). O
painel de grupo da Blizzard fica com o Core/RaidFrames.

0.3 adiciona funções de correio (seção MAIL, ligadas por padrão):
- Botão "Open All" na caixa de entrada, como o do Retail. Pega itens e ouro
  do fim da lista para o começo, uma ação por vez, esperando a caixa mudar
  (mínimo de 0,15 s; 3 s sem resposta pula a carta). Ignora cartas COD, de GM
  e só com texto. Com a bolsa cheia, para de pegar itens mas continua pegando
  o ouro, e avisa no chat. Clique de novo para parar; fechar o correio para.
  Se o Postal estiver com o próprio Open All ativo, o botão do EUI se esconde.
- Shift + clique esquerdo num item da bolsa com a aba Send Mail aberta anexa
  o item e todos os da mesma categoria até os 12 espaços: mesma classe e
  subclasse (Metal & Stone = minérios e barras, Herb, Cloth, Elemental...).
  Equipamentos agrupam por tipo de vínculo e qualidade (BoE verdes não
  levam BoE épicos). Itens Soulbound, de quest ou travados ficam de fora.
  Com o chat aberto, o Shift + clique continua inserindo o link; fora do
  correio, continua dividindo a pilha. Nada é enviado sozinho.

0.2 adds Raid Tools > Pull Timer Length (3-60 seconds, default 10), Send to
DBM / BigWigs and Chat Countdown. The Pull button displays the selected
duration. Countdown is owned by EUI; no external addon is required locally.
Chat announces the chosen duration, 10 seconds, 5/4/3/2/1 and Pull!, using
Raid Warning when permitted, otherwise Raid then Party. Solo stays local.
Updates deduplicate announcements and omit missed numbers after a stall.
Cancel, early combat, module/tools disable and profile/group changes stop
the local countdown; permitted cancellation is sent to the original group.
Boss-mod packets require raid leader/assistant or party leader. Recipient
addons retain their own permissions, filters, enable state and throttles.
Native Wrath DBM receives DBMv4-PT; D4 PT supports newer compatible Pull
plugins. Original Wrath BigWigs receives a BWCustomBar Pull timer and finish
alert (not its later voice countdown UI). Broadcast and chat are independent.
Protocol references reviewed:
https://github.com/bkader/BigWigs-WoTLK/blob/main/BigWigs/Plugins/Bars.lua
https://github.com/bkader/BigWigs-WoTLK/blob/main/BigWigs/Core/Core.lua
https://github.com/BigWigsMods/BigWigs/blob/v10/Plugins/Pull.lua
https://github.com/BigWigsMods/BigWigs/blob/v10/Loader.lua
Tests simulate scheduling/channels/packets and optionally run the actual
locally installed DBM PT receiver. Remote client rendering/audio still
needs in-game confirmation.

Native Wrath module, opened through Quality of Life in EUI or /eqol (/qol).
Use with Core 0.23 and Options 0.24. The three EUI_QoL_335 runtime files load;
the copied Retail Lua/media files remain unchanged, unloaded references.
Settings live in the Core's EllesmereUIDB profiles, including imports/resets.

Pages: QoL, Displays, Cursor, Shifter, Raid Tools, Logging. Automation and overlays
start disabled and can be enabled individually. The first-install Cursor
Circle checkbox is respected. Global Settings > Fonts edits native text sizes
and the module font; Unlock Mode moves enabled displays and the raid toolbar.

Supported: personal/guild repair with funds checks; bounded junk selling at a
merchant (quality zero, positive sell price, unlocked, non-quest/non-lootable);
quick loot honoring the native auto-loot modifier; trainer Train All button;
fill delete confirmation without accepting it; skip cinematics; error/tutorial
toggles with restoration; FPS/latency, native crit/haste, coordinates, crosshair,
durability, local combat/group-death alerts, player Sated/Exhaustion, player
Rebirth and a learned class/custom movement spell cooldown; cursor ring/trail
with GCD/cast/channel progress; native window dragging; target raid markers,
Ready Check and local pull countdown; optional raid/dungeon combat logging.

Shift + left-drag on a native window background saves its position. Ctrl +
left-drag moves it until it closes. Window changes and secure raid layout
wait until out of combat. Native mouse/movable/point state restores on disable.
Logging already active when QoL starts does not become owned by this module.

Wrath has no modern shared battle-res charges, Mythic+ keys, upgrade calculator,
teleport prompt, Mastery or Versatility. Those Retail pages are not exposed.
Rebirth tracks only the player's learned spell; Sated tracks the player's own
debuff. Cooldown displays cannot read arbitrary remote group cooldowns.
Cursor progress uses native textures and 32 pips, without masks/rotation APIs.
The 325px Retail trail texture has a separate 256px uncompressed native copy.

validate_qol.py runs the actual Lite dispatcher/native module in Lua 5.1 and
tests automation, ownership, native tuples/timers, combat guards, restoration,
profiles, movers, options/global fonts and original file integrity. Visual
appearance and native secure behavior still need confirmation in the client.
