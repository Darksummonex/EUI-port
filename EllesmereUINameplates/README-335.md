# Nameplates 3.3.5 — 0.7

0.7: ElvUI-style look (rendering only; unit binding, auras and filters unchanged).
- Dark translucent backdrop with a thin dark border drawn OUTSIDE each bar. The old border sat behind the opaque bar and was never visible.
- Name above-left, level above-right (difficulty colour), health % centred on the bar.
- Cast bar under the health bar with spark, text inside the bar, and a bordered spell icon on the left spanning both bars. Cast colour yellow, red when shielded/uninterruptible.
- Target indicator: soft blue glow ring around the bar (replaces the invisible teal border). Mouseover highlight is a white overlay on the filled part of the bar.
- Native pure red/yellow/green/blue bars are mapped to a softer palette; threat colours use the same palette.
- Aura icons get a 1 px border and the timer is centred on the icon; raid marker sits to the right of the bar.
- Existing options (width, height, border size, textures, fonts, threat/tank mode) still apply. The target arrows from ElvUI are not included: the Wrath client cannot load PNG textures.

# Nameplates 3.3.5 — 0.6

0.6: identified target/mouseover aura lists refresh the GUID cache directly, so debuffs persist after deselection even when library events arrived before observation. Unknown timers are learned; removal/expiry/hide/reuse still clear the affected plate only. No name-based identity inference. New regression fails on 0.5 and passes on 0.6.

Earlier notes:

Implementação própria para as placas anônimas do Wrath. O TOC carrega LibAuraInfo-1.0 e
EUI_Nameplates_335.lua; os engines e recursos Retail copiados permanecem como
referência. A pasta original em D:/World of Warcraft/_retail_/Interface/AddOns/
EllesmereUINameplates não foi modificada. Use com Core 0.22 e Options 0.23.

0.5 fixes debuffs leaking onto nearby same-name plates. Combat-log name matches
are no longer used to assign aura GUIDs. Native target/mouseover observation
binds the recipient GUID to one plate; cached debuffs remain there after a
target change, until that plate hides/recycles. Unidentified plates stay empty.
Direct observation clears an old owner of the same GUID immediately; conflicting
selection alpha/native hover evidence uses the hover and rejects duplication.
validate_channel_aura_filters.py reproduces the old bug using 0.4 and checks
neighbor/reuse/isolation and one-owner transitions against 0.5.

0.3 corrige a caixa de aggro deslocada: uma borda própria de 2 px fica ancorada
diretamente na barra de vida inteira, acompanhando largura/altura, offset e
escala do alvo. Lê o estado e cor do indicador nativo, inclusive warnings,
independentemente da opção Threat Colors que colore o fill. Não aparece em
aliados ou quando não há barra visível. A textura do flash nativo é esvaziada
enquanto o módulo está ativo: a animação do cliente pode reescrever seu alpha
e fazer o desenho antigo aparecer fora da barra. Ao desligar restaura a textura
original; o tamanho/posição/clique do frame nativo continuam preservados.

0.2 mantém a opção existente Class Colored Names e aplica a cor aos aliados
conhecidos mesmo sem target/mouseover. Group/raid/player são consultados pelas
unidades Wrath, e target/mouseover/focus ensinam a classe de aliados fora do
grupo. O cache de observações dura até PLAYER_ENTERING_WORLD. O novo controle
Class Colored Health Bar, em FRIENDLY PLAYERS, colore a barra dos jogadores
aliados de modo independente; começa desligado para preservar a aparência.
Friendly Name Only continua usando Class Colored Names para a cor do nome.

As correspondências por nome servem somente para a cor da classe de placas
nativas de jogadores aliados (barra azul), sem fabricar unit token, GUID, cast
ou aura. Nomes ambíguos, NPCs e classes desconhecidas conservam a cor nativa;
para um aliado desconhecido fora do grupo, passe o mouse ou selecione uma vez.
Mudanças de grupo/raid atualizam o índice. Há testes de controles independentes,
classes diferentes, persistência após mouseover, nomes iguais, NPCs, reciclagem,
atualização do roster, cache de sessão/zona e reaproveitamento da opção existente.

Abra /enp. Use V para alternar as placas inimigas (atalho padrão do cliente).
As páginas Nameplates, Cast & Auras, Aura Filters e Fonts controlam largura/altura visuais,
texturas Flat/Blizzard, bordas, nomes, nível/elite, raid markers, seleção,
opacidade, cores de ameaça, cast e auras. Fonts/Textures globais usam os campos
implementados no Wrath. O módulo não oferece os presets Retail de Styles.

Vida percentual e progresso de cast vêm dos StatusBars nativos. A identificação
de alvo é inferida pelo nome e alpha de seleção do cliente; mouseover pelo nome
e highlight nativo. Ambos exigem um único candidato. Somente essas placas
recebem GUID da unidade, nome/tempo da magia e auras via UnitAura. Placas de nome
igual com seleção ambígua não recebem dados de outra unidade. Auras podem incluir
seus debuffs, os do pet e buffs; até oito ícones com stacks e tempo restante.
As outras placas conservam o progresso e ícone do cast nativo, sem nome/timer
inventados. Não há vida absoluta nem GUID disponível para todas as placas.

Os frames nativos conservam parent, posição, tamanho, scripts, mouse e alpha.
As novas regiões não recebem mouse. Largura e Target Scale alteram o desenho;
a área nativa de clique permanece do cliente. Additional Non-target Opacity é
um multiplicador adicional sobre a transparência nativa. O módulo esconde
somente a arte nativa com alpha zero e esvazia a textura do flash de ameaça,
preservando seu estado e atualizações.
Ao desligar restaura os alphas originais e o CVar showVKeyCastbar. Mudanças de
layout/CVars em combate são adiadas até PLAYER_REGEN_ENABLED.

Não há dependência ElvUI. Seus contratos Wrath de regiões/StatusBars foram usados
como referência: [ElvUI-WotLK Nameplates](https://github.com/ElvUI-WotLK/ElvUI/blob/master/ElvUI/Modules/Nameplates/Nameplates.lua).
Se uma placa já pertence a outro renderer com UnitFrame, ela não é capturada;
é emitido um aviso observado para desativar o outro módulo de nameplates.

Recursos Retail como C_NamePlate, nameplate1, absorções, NPC IDs de todas as
unidades, cast targets, quests, distância e containers de auras modernos não
foram portados ou emulados. Placas ficam ancoradas nas unidades pelo cliente;
não são elementos livres do Unlock Mode.

Validação local: validate_nameplates.py executa o Lite/safecall real e o módulo
em Lua 5.1, com uma fixture explícita de placas Wrath. Cobre descoberta/reuso,
vida, cast/canal, seleção única, auras/GUIDs, cliques/alpha preservados, ameaça,
raid markers, friendly name only, combate/restauração e páginas/cards reais.
Os arquivos de referência Retail são comparados byte a byte com o original.
Sintaxe dos sete addons e regressões de Chat/ActionBars/UnitFrames são verificadas.
Renderização e taint ainda dependem de teste no cliente real.

No jogo, confira V, seleção por clique/Tab, dois inimigos com o mesmo nome,
troca de alvo/mouseover, seus debuffs e os do pet, cast interrompível/canalização,
raid marker e ameaça. Entre/saia de combate após mudar opções. Desligue e religue
o módulo para conferir a restauração. Teste fontes/texturas compartilhadas e
a troca de perfil. Teste Class Colored Names com um aliado do grupo e outro
fora dele; tire o alvo/mouseover e confira o nome. Ative/desative Class Colored
Health Bar e Friendly Name Only. Ganhe/perca aggro com diferentes tamanhos,
offsets e Target Scale; confira a borda e desligue o módulo para restaurar a
arte nativa. Pacote: EllesmereUI-3.3.5-HUD-test-0.16.zip.

0.4: /enp > Aura Filters offers all/own/tracked, tracked/excluded spell IDs,
timed-only and stealable buffs. Own includes pet/vehicle; tracked IDs supplement
own mode; exclusions always win. GUID aura tracking uses the unchanged local
ElvUI/Libraries/LibAuraInfo-1.0 by Cyprias, author header preserved. ElvUI need
not be active. Native combat log tracks debuffs beyond target/mouseover; UnitAura
learns custom IDs/durations. Observed plates retain identity until hide/reuse;
unobserved plates stay empty until target/mouseover identifies their GUID.
Name-based aura inference introduced in 0.4 was removed in 0.5. Estimated durations are corrected by observation; combat
log lacks Stealable, so this filter confirms only direct native UnitAura buffs.
validate_channel_aura_filters.py exercises the actual library and Wrath events.
