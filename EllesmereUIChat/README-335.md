# EllesmereUI Chat — 3.3.5 — 0.3

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
