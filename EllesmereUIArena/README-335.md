# EllesmereUI Arena (3.3.5a)

Módulo novo do EllesmereUI para o WoW 3.3.5a: quadros dos inimigos de arena (arena1–5). Não existe equivalente no EUI Retail; foi criado para cobrir a lacuna em relação ao ElvUI.

## 9.3.4-335-0.1

- Cinco botões seguros (`SecureUnitButtonTemplate`) para arena1–5: clique esquerdo seleciona o alvo, clique direito define o foco.
- Os quadros aparecem ao entrar na arena, conforme o tamanho da chave (`GetBattlefieldStatus`), e continuam visíveis quando o inimigo fica furtivo ou fora de vista (ficam esmaecidos, com "Unseen").
- Barra de vida com cor de classe ou cor personalizada, texto de vida (porcentagem, atual, ambos ou nenhum) e barra de poder opcional.
- Ícone de classe (estilo moderno do EUI ou Blizzard) que troca para o controle de grupo ou imunidade de maior prioridade, com espiral e contador. As auras são comparadas pelo nome, então todos os ranks contam.
- Ícone do berloque PvP com recarga de 2 minutos, detectado pelo log de combate (Berloque PvP 42292 e Cada Um por Si 59752). O ícone segue a facção do inimigo.
- Barra de lançamento com ícone, nome e tempo; cor própria para feitiços não interrompíveis e aviso "Interrupted".
- Borda destacada no inimigo que é seu alvo.
- Os quadros de arena da Blizzard (`Blizzard_ArenaUI`) ficam ocultos (opção).
- Pré-visualização com 2 a 5 quadros fictícios no Unlock Mode, com a página de opções aberta ou com `/earena test`.
- Mover no Unlock Mode ("Arena Frames") com Element Options apontando para a seção LAYOUT.
- Texturas de barra próprias em `Media/Textures_335` (cópias potência de dois das texturas dos Raid Frames).
- Comandos: `/earena` ou `/arenaframes` abrem as opções; `/earena test` alterna os quadros de teste.

### Não portado / limitações

- Retornos decrescentes (DR) não são rastreados.
- Detecção de especialização não existe no 3.3.5 (não há API de spec para inimigos).
- Quadros de pets da arena (arenapet1–5) ainda não foram incluídos.
- Desvanecimento por alcance não foi incluído: o 3.3.5 não tem checagem de alcance confiável para inimigos sem usar feitiços da classe.
- Mudanças de tamanho ou posição durante o combate esperam o fim do combate (restrição dos botões seguros).
