# Friends 3.3.5 — 0.3

0.3: paridade com o Retail. Ícone de classe à esquerda da linha, com os temas
do EUI (Modern por padrão; Blizzard usa o atlas nativo), nome deslocado e
detalhes logo abaixo; amigos offline mostram o ícone offline esmaecido. Orbe
de status ao lado do nome (online, AFK, DND, offline) no lugar do ícone
nativo, nota do amigo anexada aos detalhes, faixa de facção (Enable Faction
Banners; sem ela, a faixa neutra do Retail) e realce ao passar o mouse. Borda
com tamanho 0 a 4 e cor Custom ou Accent (o antigo "Accent Border"/"Show
Border" é migrado uma vez). Enable Accent Colors sublinha a aba selecionada.
Auto-Accept Friend Invites aceita convites de grupo de amigos (e de membros da
guilda, pela engrenagem) e fecha o popup. Com Blizzard/Classic ativo, a janela
fica nativa mas as linhas ganham ícone de classe e nome colorido. A arte do
Retail foi convertida para TGA em Media_335 (prepare_friends_media.py).
/efr abre a página. Requer Options 0.65.

Open /efriends or EllesmereUI > Friends. The native social window and friend
list keep their existing actions, tabs, tooltips and client-supported data.
EUI adds readable outlined text, localized class colors/icons, row/background
opacity, window scale and borders. Blizzard/classic styles use native Wrath art.
Disabling the module restores its fonts/art/scale; Blizzard Skin resumes its
configured social skin. Window and row construction defers during combat.

Settings use EllesmereUIFriendsDB through EUI Lite and join EUI profiles,
presets and global font settings. This module reads native friend information;
no other addon is required. Retail Lua/media are retained unchanged and unloaded.
Modern Retail-only social/group/collection APIs are not emulated.

validate_friends_questtracker.py verifies real lifecycle, native actions,
recycled/localized/offline rows, styles, fonts, combat deferral and Options.
validate_blizzardskin.py verifies social-window ownership handoff. Confirm
appearance and native interaction in the real client.
