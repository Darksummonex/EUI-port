# EllesmereUI Arena (3.3.5a)

Módulo novo do EllesmereUI para o WoW 3.3.5a: quadros dos inimigos de arena (arena1–5). Não existe equivalente no EUI Retail; foi criado para cobrir a lacuna em relação ao ElvUI.

## 9.3.4-335-0.2

- Retornos decrescentes (DR): ícones ao lado de cada inimigo, um por categoria (atordoamento, atordoamento aleatório, investida, medo, desorientação, silêncio, horror, enraizamento, ciclone, banir, controle mental, desarmar). A borda indica o próximo efeito: verde metade da duração, amarelo um quarto, vermelho imune. O contador mostra os 18 segundos até zerar. Os feitiços são comparados pelo nome (todos os ranks contam) via `SPELL_AURA_APPLIED/REFRESH/REMOVED` do log de combate, apenas dentro da arena. Lado (esquerda/direita) e tamanho configuráveis; os ícones ficam fora do bloco do quadro.
- Pets da arena: barra de vida e nome do `arenapetN` abaixo da barra de lançamento do dono, em botão seguro com `RegisterUnitWatch` (aparece e some sozinho, inclusive em combate). Clique esquerdo seleciona, direito define foco. Altura configurável; a pré-visualização mostra Water Elemental e Ghoul.
- Desvanecimento por alcance: inimigos fora do alcance de um feitiço de 30–40 jardas da sua classe (Fireball, Shadow Bolt, Shadow Word: Pain, Wrath, Lightning Bolt, Auto Shot, Hand of Reckoning, Death Grip, Throw, Shattering Throw) ficam com a opacidade escolhida; sem o feitiço, usa `CheckInteractDistance` (28 jardas).
- Opções: seções PETS e DIMINISHING RETURNS; "Fade Out of Range" e "Out of Range Opacity" em TARGET AND VISIBILITY.
- Teste: `backport-tools/validate_arena.py` (pré-visualização, unit watch, DR aplicado/renovado/removido/zerado, buffs ignorados, alcance com feitiço e com distância, opções).

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

- DR só conta o que o log de combate mostra: aplicações fora do alcance do log (~50 jardas) não entram. As categorias seguem a tabela padrão do Wrath; regras próprias do servidor não são consideradas.
- Detecção de especialização não existe no 3.3.5 (não há API de spec para inimigos).
- O alcance depende de um feitiço conhecido da classe; personagens sem ele usam a distância de 28 jardas.
- Os pets não têm barra de lançamento nem auras.
- Mudanças de tamanho ou posição durante o combate esperam o fim do combate (restrição dos botões seguros).
