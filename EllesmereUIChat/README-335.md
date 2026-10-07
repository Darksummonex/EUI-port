# EllesmereUI Chat — 3.3.5 — 0.46

0.46: filtro de mortes do Hardcore em Chat > Spam Filter > HARDCORE. Esconde
anúncios do servidor como "Warrash the level 11 Gnome Warrior has been slain
by Sergeant Brashclaw in Westfall" (mensagens de sistema, emotes, BG e canais;
has been slain/killed, has died, has drowned, has fallen, has burned, was
slain/killed). "Keep Deaths From Level" mantém visíveis mortes a partir de um
nível (81 esconde todas). Desligado por padrão; chat de jogadores não é afetado.
O preset de anúncios de comércio também esconde LFW (looking for work).
Registro de mensagens escondidas na sessão (últimas 200 linhas, com hora, motivo,
canal e autor), aberto pelo botão "Show Hidden Messages"; "Clear Filter History"
virou "Reset Repeat Memory", que só zera a memória do filtro de repetição.
Corrigido erro "SetPoint(): is dependent on this" em balões de fala de NPC
ancorados ao próprio texto.

0.45: correções do filtro de spam. O preset de recrutamento não esconde mais
anúncios de raide com tag de guilda ("<Frost> LF 1 heal ICC25"); só "LF guild"
conta. Sussurros e mensagens de GM (flag GM) sempre aparecem. Palavras-chave
ignoram maiúsculas acentuadas (PROMOÇÃO = promoção) sem depender do locale. Os
presets de comércio e recrutamento seguem a opção Public Chat. Com todos os
filtros desligados, nenhuma mensagem é processada.

0.44: filtros opcionais de conquistas, anúncios de comércio (WTS/WTB/WTT)
e recrutamento de guilda, além de palavras/frases personalizadas separadas
por vírgulas ou ponto e vírgula. Funcionam sem ativar o filtro de repetição;
mensagens próprias são preservadas. Presets de anúncios atuam no chat público.

0.43: nova página Spam Filter nas opções do Chat. Filtro opcional de mensagens
repetidas com janela de 1–120 segundos, comparação por remetente ou entre
remetentes e seleção de chat público, grupos/guilda e sussurros recebidos.
Ignora maiúsculas e espaços extras; preserva mensagens próprias, sistemas e
NPCs. Decisão consistente entre abas, histórico limitado e limpeza imediata
ao alterar as opções. Desativado por padrão.

0.42: no Unlock Mode, clique direito (ou engrenagem) no chat mostra "Element
Options", que abre /echat > Chat na seção DISPLAY destacando Main Chat Width.

0.41 corrige o primeiro teste no cliente:
- Os contadores da sidebar recebiam texto antes da fonte; o cliente Wrath
  rejeita isso e interrompia todo Apply. Por isso a sidebar não aparecia, as
  abas não subiam acima da entrada no topo e os toggles (ex.: Lock Main Chat
  Size) só atualizavam ao reabrir as opções.
- Unlock Mode: o elemento usa a chave Retail ECHAT_MainChat (o Unlock não
  instala hooks de SetPoint no ChatFrame1), aplica ao fechar a sessão e marca
  o chat como user placed, pois FCF_UpdateDockPosition adicionava de volta seu
  ponto BOTTOMLEFT. Desabilitar o módulo devolve o estado original.
- Opacidade 0 salva na 0.3 volta ao padrão Retail 0.65 uma vez (painel e
  sidebar compartilham essa opacidade).

0.4 porta o visual e as funções portáveis do Chat Retail. Use com Options 0.50.

- Painel EUI: fundo com cor/opacidade/textura, divisor entre mensagens e
  entrada, entrada acima/abaixo com altura própria, borda Retail (estilo,
  tamanho, cor/origem, opacidade, atrás) envolvendo painel e sidebar.
- Abas Retail desenhadas sobre as abas nativas do dock: largura pelo texto,
  espaçamento, padding, altura, offset, alinhamento ao painel, fundo/textura,
  underline ativo, borda ativa e borda sincronizada. O alerta de nova
  mensagem vira o texto da aba na cor de destaque. As abas nativas mantêm
  cliques, menu, drag e docking.
- Sidebar Retail com os ícones originais (convertidos para TGA em Media_335):
  amigos (online + Battle.net), guilda, durabilidade, copiar, voz/canais,
  configurações e rolar ao fim. Ordem, tamanho, espaçamento, cor/destaque,
  lado direito, fundo, separada, Free Move com posições salvas e botão de
  scroll no painel. Visibilidade Always/Mouseover/Never.
- Visibilidade do chat e Idle Fade (atraso/intensidade) com mouseover pelas
  áreas do chat; com alpha zero o chat deixa os cliques passarem.
- Timestamps Retail (formatos com espaço, Blizzard Default, None, Timestamp
  All) via filtros: por padrão só as linhas de chat de jogadores, igual ao
  Wrath. Remove o timestamp nativo duplicado.
- Nomes de canais abreviados ([2], [P]; letras opcionais Ge/T/LD/WD/LFG),
  nomes do grupo/raide na cor da classe, tooltip de links no hover, som de
  whisper (sons EUI + SharedMedia), histórico das últimas linhas salvo por
  personagem (EllesmereUIChatScrollDB) e mostrado no próximo login.
- URL abre a janela Retail no cursor; cópia usa a janela Retail com Close.
- Lock Main Chat Size esconde o grip nativo; o tamanho escolhido no menu da
  aba vira o tamanho do perfil para todas as janelas.
- Botões nativos de menu do chat e social ficam ocultos (a sidebar os substitui).
- Chat Bubbles: liga as CVars de bolhas pelos canais marcados, oculta em
  instâncias, e reestiliza as bolhas do WorldFrame (fundo, borda, padding,
  largura, fonte, cor, offset). Desligar restaura as CVars salvas.
- Página Style: Blizzard/Classic usam o chat nativo (fixado até o reload);
  timestamps, URLs e os demais recursos de texto continuam.
- Chaves 0.3 alteradas pelo usuário são migradas (borda, timestamps).

Não portado: portais M+ (Retail), mute/troca do som nativo de whisper
(MuteSoundFile não existe; o som escolhido toca junto), switch de bolhas de
raide (Wrath não tem CVar), motor de display/scrollbar Retail, kits da
sidebar stock e look Forever, e integração com Edit Mode. Abas dinâmicas
com espaçamento usam a rolagem nativa aproximada.

0.3 permite arrastar a borda inferior do chat até Y=0, removendo a reserva
nativa de 50px em GetClampRectInsets. Mantém clamping ligado e os insets de
laterais/topo; captura/restaura os insets originais ao desabilitar o módulo.
Apply/OnShow reaplicam a margem inferior zero, com fila até sair de combate.
Unlock salva/reaplica Y=0 sem mover automaticamente a posição existente.
Teste cobre limite nativo 50px, drag/Y=0 salvo, reapply, janelas temporárias,
refresh nativo/combat e restore/re-enable. Core e Options permanecem intactos.
Pacote combinado: EllesmereUI-3.3.5-HUD-test-0.6.zip.

Use com Core 0.14 e Options 0.14. `/echat` abre as opções; `/ecopy` copia a
janela atual. Os botões C e O ao lado da janela abrem cópia e opções.

0.2 acrescenta Square Skin, ligada por padrão em /echat > Chat. Abas e coluna
de scroll usam fundo plano/borda reta; a aba selecionada recebe um underline
na cor do tema. Controles ^, v e = representam subir, descer e ir ao fim.
Os próprios botões nativos preservam cliques, docking, drag e alertas. A skin
acompanha FCFTab_UpdateColors; desligar Square Skin restaura a arte nativa.
O painel/input já usam bordas retas desde 0.1. A inspiração visual é ElvUI,
sem depender desse addon nem reproduzir seus painéis extras.

O TOC carrega apenas EUI_Chat_335.lua. Todos os engines Retail foram copiados
sem alterações e permanecem fora do TOC. O script de validação compara todos
os bytes dos arquivos de referência com os originais, exceto o TOC adaptado.
O original em D:/World of Warcraft/_retail_/Interface/AddOns/EllesmereUIChat
permanece intacto. O módulo não depende de ElvUI nem dos módulos anteriores.

A implementação usa as janelas e abas nativas do Wrath. Não substitui envio,
whispers, histórico da entrada, seleção/docking das abas, filtros ou os eventos
do chat. Combat Log recebe aparência, mas seu texto não recebe URLs/timestamps.
Links de itens, jogadores, quests etc. seguem o OnHyperlinkClick original.

Recursos: fundo/borda sólidos, cores/opacity, fontes do chat/abas/entrada,
tamanho da janela principal, entrada acima/abaixo, ocultação da coluna nativa,
timestamps nas novas linhas, URLs http/https/www selecionáveis para Ctrl+C,
cópia sem escapes de cor/link/textura e buffer de sessão de 50 a 2000 linhas
por janela. A captura inicia com o scrollback nativo disponível e acompanha
Clear; não persiste mensagens entre sessões nem reenvia mensagens.
Mouse wheel rola mensagens; Shift vai ao início/fim; fade de mensagens usa
o ScrollingMessageFrame nativo. Janelas temporárias também são estilizadas.

Unlock Mode move a janela principal e salva sua posição. Alterações em combate
ficam pendentes até PLAYER_REGEN_ENABLED. Desabilitar restaura pontos/tamanho,
fontes, texturas, fading, input e scripts capturados. Outros addons que envolvam
o bridge de mensagens continuam na cadeia; reapply não envolve o bridge de novo.
Não adiciona OnKeyDown, bindings, propagação de teclado ou APIs Retail fictícias.
Entrada nativa continua sem autofocus; cópia recebe foco por ação explícita,
e esconde/fecha com ClearFocus. Core permanece 0.14.

Options 0.14 inclui Chat e Fonts, e adapta os cards compartilhados Fonts/Textures.
Ainda não portados: motor de display/abas Retail, estilos Blizzard/Classic/Forever,
sidebar de amigos/portais/voz, bolhas, abreviação de canais/class colors de nomes,
texturas decorativas e histórico persistente. Esses controles não são expostos.

Contratos consultados no FrameXML 3.3.5:
https://github.com/wowgaming/3.3.5-interface-files/blob/main/ChatFrame.lua
https://github.com/wowgaming/3.3.5-interface-files/blob/main/FloatingChatFrame.lua
https://github.com/wowgaming/3.3.5-interface-files/blob/main/ChatFrame.xml

Validação: backport-tools/validate_chat.py executa módulo, Lite/NewDB e dispatcher
reais em Lua 5.1, e funções nativas de hyperlink/fontes/cor/alpha do FrameXML.
Cobre links/argumentos de mensagem, URLs/cópia/foco, scroll, janelas temporárias,
combate/unlock/reset, restauração, wrappers externos, opções e cards reais.
Taint e aparência requerem confirmação no cliente. Roteiro manual: /echat,
Ctrl+C em C e URL, links de itens e nomes, abas/whispers, envio com Enter,
Escape, habilidades de teclado após fechar cópia/opções, combate e Unlock Mode.
