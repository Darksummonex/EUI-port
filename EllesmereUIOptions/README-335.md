# Options 3.3.5 — 0.43

0.43 adds native Friends and Quest Tracker settings, including visibility,
Unlock Mode placement, fonts and optional quest helpers.

0.42 makes Quickdraw Assign Key capture the next pressed hotkey, with modifier
support and keyboard cleanup on release/cancel/hide/combat/focus/timeout.

0.41 adds native AuraBuff Reminders and Quickdraw settings, assignments,
reminder preview/filters and palette layout/action/keybind controls.

0.40 adds native Cooldown Manager pages: CDM Bars, Tracking Bars and Bar Glows,
manual assignments, aura filters, dual-spec lists, outlines and previews.

0.39 updates Damage Meters window help for hover breakdown, inline player
focus, Back and the focused footer Spells/Targets selector.

0.38 adds Damage Meters per-window bar/header/footer opacity, font outline
and specialization-icon controls alongside the existing background opacity.

0.37 maps General combat damage/healing, periodic damage and pet melee/
spell damage toggles to stock 3.3.5 CVars. The theme dropdown uses one
complete background/accent update through the core API. Existing combat
guards and safe unavailable-CVar handling remain in place.

0.36 adds native Damage Meters Windows and Combat Data pages. Four windows,
metrics/history, size/fonts/position/visibility, own persistence, collection,
pet merge and explicit report preview/send use the new independent module.
The options builder retains the private frame adapter.

0.35 adds a shared Buffs/Debuffs indicator editor and persistent header
preview for Raid Frames and Unit Frames. The non-secure preview shows spell
icons at their configured anchors, growth, offsets and sizes and refreshes
on every edit. Click preview icons or the indicator list to select one.
It scales the complete layout to fit without changing live sizes. Header
frames/icons/list entries are reused across page/cache refreshes.
Healing, personal defensive and external presets are provided; new manual
indicators start with empty spell lists. Other buffs require manual IDs.
Raid/party and 10/25/40 configurations remain independent. Unit Frames >
Buffs > Player > Use Indicator Layout enables the new player display;
disabling returns to existing aura rows. The same editor supports target,
focus, boss frames and Debuffs. Aura Filters retains global exclusions.
Options still preserve native CreateFrame and inert compatibility probes.

0.34 keeps all widget compatibility probes under a hidden, mouse/keyboard
disabled parent. Each probe is hidden and input disabled; the EditBox uses
the private factory with autofocus off and explicit ClearFocus. Build 0.28
preserved native CreateFrame but accidentally created its EditBox probe
with native default autofocus, allowing it to steal gameplay keyboard input
after other windows closed with Escape. Native CreateFrame and native
window inputs remain untouched. Search inputs retain click-to-focus.

0.33 removes the global CreateFrame replacement. Retail-only template
filtering and EditBox autofocus/OnHide cleanup now live in
EllesmereUI.CreateOptionsFrame, locally bound by the 18 active options
builders which create frames. UnitFrames retains its own Wrath adapter.
Native frames and other addons no longer enter the Options frame factory.
This addresses a taint source identified while investigating the blocked
action popup after closing windows opened by the minimap micro menu.
No global native API is restored/reassigned at runtime; a full client
restart is needed to clear taint from the previous loaded build.
Existing settings, search inputs, template filtering and callbacks remain.

0.32 retains the Minimap middle-click switch and adds Raid Tools pull
duration, DBM/BigWigs broadcast and chat countdown controls under Quality
of Life. The chat channel priority and synchronization permissions are
shown alongside the settings. Existing module options are retained.

0.31 adds the Bags category selector/gold hint and raid role order/DPS
icon controls. Raid Frames includes independent Buffs/Debuffs indicator
pages alongside its existing shared Aura Filters and Click Casting pages.

0.30 adds a native DataBars page: bar selector, templates, appearance/layout,
visibility, ordered blocks and block-specific settings. The original Retail
options file remains unloaded. Use /edb or EllesmereUI > DataBars.


0.24: adds five native Quality of Life pages and native Global Fonts controls. Use the current manifest for the complete module/version combination.

Earlier notes:

0.22: páginas nativas Bags e Resource Bars. Resource Bars usa um seletor único
de barra e deep links dos movers; Bags permite grid/banco/busca/categorias e
fontes. Global Fonts/Textures escreve campos efetivos destes módulos. Estilos
Retail de Resource Bars e labels Warbound/set names de Bags não são expostos.
validate_inventory_resources.py cobre construção de todas as seleções e
setters reais dos tiles globais. Teste visual no cliente pendente.

Use com Core 0.18, UnitFrames 0.6, Minimap 0.1, ActionBars 0.7, Chat 0.3,
Nameplates 0.3 e BlizzardSkin 0.3.

0.20 acrescenta /ebs > Blizzard Window Skins > CHARACTER ENHANCEMENT:
Enhanced Character Layout e Equipment Item Levels. Desligar o layout restaura
o tamanho/modelo/equipamentos nativos; a correção de espaçamento das abas
continua enquanto a skin Character estiver ligada. Presets permanece pausado.

0.19 reúne ActionBars em uma página /eab > Action Bars. Select Bar escolhe
entre 14 grupos: seis action bars, pet/stance, micro/bags, XP/Rep e buffs/debuffs.
Layout/reset seguem a seleção; Global Settings inclui Hide Blizzard Bar Art.
Dimensões HUD e colunas de auras podem ser separadas por seleção, mantendo
fallback das preferências compartilhadas anteriores. Fonts/Textures apontam
para essa página; XP/Rep usam ElvUI Norm. Core e proteções de widgets/foco
permanecem inalterados. Pacote combinado HUD-test-0.2.

0.18 adiciona /eab > Blizzard UI: skins Micro/Bag/XP/Rep, tamanho/spacing dos
botões, largura/altura das barras, movers Player Buffs/Player Debuffs e colunas
de auras. Open Unlock Mode e Reset HUD & Aura Positions ficam na mesma página.
Textures globais apontam para a página HUD e descrevem a textura plana atual.
Proteções de foco/teclado e widgets anteriores permanecem inalteradas.

0.17 adiciona /ebs (/ebui), com Blizzard Window Skins e Tooltips, Menus & Popups.
As escolhas usam os campos de conta já exportados pelo Core; o kill switch de
janelas pertence ao perfil. Desligar/religar restaura a arte nativa sem reload;
alterações em combate aguardam regen. Cards Fonts/Textures oferecem apenas as
funções Wrath; Styles não mostra Character Sheet Retail/Skyriding. Preserva as
proteções de foco, callbacks opcionais e os módulos anteriores.

0.16 reutiliza Class Colored Names para os aliados conhecidos mesmo sem alvo/
mouseover; acrescenta somente Class Colored Health Bar em /enp > Nameplates >
FRIENDLY PLAYERS. A classe dos membros de grupo/raid é identificada automaticamente.
Aliados desconhecidos fora do grupo precisam ser identificados por mouseover,
target ou focus. Não há uma segunda opção de cor da classe no nome.

0.15 adiciona /enp com Nameplates, Cast & Auras e Fonts. Os cards globais de
Fonts/Textures editam os campos Wrath; Styles não expõe os presets Retail de
Nameplates. Auras e nomes/timers de cast são do alvo ou mouseover identificado.
Veja EllesmereUINameplates/README-335.md e o pacote Nameplates-test-0.1.

0.14 adiciona Square Skin em /echat > Chat para as abas e controles planos do
Chat 0.2, com underline da aba ativa e restauração da arte nativa ao desligar.

0.13 adiciona EUI_Chat_335_Options.lua, com páginas Chat e Fonts. /echat abre
as opções e /ecopy copia a janela atual. Cards Fonts/Textures usam os recursos
implementados no Wrath; Styles não expõe estilos Retail de Chat. Preserva foco
opt-in/ClearFocus, hooks opcionais e os módulos já confirmados.

0.12 adiciona EUI_ActionBars_335_Options.lua, com General e páginas das seis
barras, pet e poses. /eab abre a página; usa a tela nativa de keybindings.
Os cards Fonts/Textures de ActionBars foram limitados aos recursos implementados
no Wrath; Styles não oferece seus estilos Retail. Preserva os callbacks/foco.

0.11 adiciona a página Minimap Wrath para EllesmereUIMinimap 0.1, via
EUI_Minimap_335_Options.lua. Exibe apenas os controles implementados no cliente
3.3.5; /emm abre a página. Mantém as proteções de foco e de callbacks de 0.10.

0.10 corrige _NotifySettingWrite ausente ao arrastar/digitar em sliders.
A notificação de captura de Spec Overrides é opcional; a gravação do valor e
a marcação _settingsChanged continuam normais. Protege todos os usos nos widgets
compartilhados (toggles, dropdowns, sliders, cores, popups) e nos controles de
cores dos textos do UnitFrames. Não adiciona um hook fictício ao Core.

0.9 corrige SpecOverrides_EditSessionActive ausente na construção da linha de
visibilidade. O Core de Wrath não carrega o sistema opcional de overrides por
especialização. Os widgets consultam as funções apenas quando existem e editam
a visibilidade compartilhada normalmente quando o sistema está ausente.
Também protege SlotOverridable, ClearStoreKey e CloseEditSessions na troca de
estilo. Não cria APIs fictícias nem habilita overrides por especialização.

Mantém os EditBoxes com SetAutoFocus(false) e ClearFocus ao esconder; mantém
o adaptador GetSpellInfo de 0.7 e as três páginas UnitFrames de 0.8.

Validação: backport-tools/validate_visibility.py executa BuildVisibilityRow e
AttachVisibilityChecklist reais, com leitura/escrita de seleção do Core real.
Apenas a construção gráfica da linha/dropdown usa um mock. Cobre APIs opcionais
ausentes/presentes, edição compartilhada, remoção de overrides, ownership,
slots excluídos e duas disposições de checklists. Não substitui teste no WoW.
validate_widgets.py executa o slider real (arraste, release e entrada digitada),
toggle e callbacks reais de cor/cancelamento; verifica gravação/dirty state e
notificação ausente/presente/removida. Usa widgets gráficos simulados.

Após reiniciar o cliente, abra /euf, confira Main Frames/Boss Frames/Mini Frames
e altere a visibilidade. Abra/feche as opções após digitar num campo e confira
WASD, Espaço, 1–5, Tab, Escape e modificadores.

0.21: Profiles > Presets abre os cards de estilo em jogo no Wrath, com mudanças
gravadas somente ao confirmar reload. Global Settings > General > DISPLAY
oferece Lich King em EUI Options Theme e Match Accent to Theme (padrão on).
Core 0.19 carrega TGA compatíveis dos backgrounds originais sem modificar PNGs.
General > DEVELOPER > Show Spell ID on Tooltip usa os tooltips nativos do Wrath
para magias, action bars, buffs/debuffs e links de magia no chat; padrão off.
O módulo de tooltip respeita spellIDModifier e evita linhas duplicadas.
Validadores de temas/Presets e IDs executam callbacks reais em Lua 5.1.

0.23: dedicated Aura Filters pages for UnitFrames and Nameplates, independent
UF frame settings, all/own/tracked modes, tracked/excluded spell IDs, timed-only
and stealable buffs. Invalid input preserves lists; reset is per selected frame.
Show Channel Ticks controls for both Wrath castbars. Requires Core 0.22.
