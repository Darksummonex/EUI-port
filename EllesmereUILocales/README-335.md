# Locales 3.3.5 — 0.1

Sem bump: Rare/Quest Indicator das Nameplates 0.19 (IDs 5828-5836: nomes do
dropdown, dicas do cog, Show In Instances e o item das Patch Notes) e Crowd
Control / Debuffs + CC (IDs 5837-5840; rótulos com o texto do catálogo Retail)
traduzidos em todos os idiomas.

Sem bump: Patch Notes traduzidas. Os 580 textos de `_WHATSNEW_PATCHES`
(eyebrow, title, desc, text, module) já passam por `EllesmereUI.L`; os 349 que
faltavam viraram IDs 5479-5827 (`append_locale_keys.py --patch-notes`, lista de
`patch_note_strings.py`) e foram traduzidos em todos os idiomas. Nomes de
produto, APIs, comandos e mensagens de erro citadas ficam em inglês.

Sem bump: 220 textos novos do port (Raid Tools, Reinvite, marcadores de chão,
Quickdraw 0.4, DataBars/XP, End Caps, CDM, Junk, Item ID etc.) traduzidos em
todos os idiomas (ptBR 220, deDE 213, frFR 217, ruRU 218, koKR 213, zhCN/zhTW
212, esES/esMX 220; o resto já existia no catálogo Retail). IDs 5259-5478
anexados a `ptbr_work/keys.tsv` sem renumerar, por
`backport-tools/append_locale_keys.py`; `find_new_locale_keys.py` lista chaves
novas e as antigas que o port não usa mais (38, mantidas no catálogo).

Sem bump: os outros idiomas foram completados com os textos do port que faltavam
(deDE +1871, frFR +2664, ruRU +3224, koKR +1716, zhCN +1692, zhTW +1713, esES/esMX
+4775). As adições ficam no fim de cada catálogo Retail, depois da linha
`-- == 3.3.5 port additions ... ==`; o que vem antes continua sendo o texto Retail
(só sem as chaves não usadas).
Gerado por `backport-tools/build_locale_additions.py` a partir de
`backport-tools/locale_work/<idioma>/out_*.tsv` (esMX usa o esES), com a mesma
checagem de placeholders, cores, quebras de linha e sintaxe Lua. Corrigido o texto
alemão "Learn %d skill%s for %s", que perdia um argumento. Cobertura agora entre
93% (esES) e 97% (zhCN); o resto são nomes e siglas que ficam em inglês.

Sem bump: novo catálogo `ptBR.lua` (Português do Brasil), feito para o port: 4925 de 5259
textos do port traduzidos (os outros 334 são nomes, siglas e termos que ficam em
inglês). Gerado por `backport-tools/build_ptbr_catalog.py` a partir de
`backport-tools/ptbr_work` (glossário em `GLOSSARY.md`), que confere placeholders,
códigos de cor/textura, quebras de linha e sintaxe Lua. Termos: Bônus/Penalidade,
Quadros de Raide, Placas de Identificação, JxJ, VaE; nomes de módulos e fontes em
inglês. Escolha em EUI Options Language; o que faltar continua em inglês.

Limpeza (sem bump): `backport-tools/clean_locale_catalogs.py` removeu 5430
entradas que o port nunca mostra (texto só do Retail ou sem uso nem no Retail).
Ficam 4048 chaves: as usadas pelo port, as quase iguais ao texto do port
(recuperáveis) e as montadas em tempo de execução ("Trinket Slot " .. 1). As
linhas mantidas continuam idênticas ao Retail; os catálogos caíram de 3,6 MB para
1,4 MB. Backup em `.codex-backups/locales-before-clean-20261009-015841`.
`scan_locale_coverage.py` mostra a cobertura atual.

0.1: catálogos originais da comunidade para deDE, esES, esMX, frFR, koKR,
ruRU, zhCN e zhTW. Inglês enUS/enGB usa os textos originais sem carregar
este addon. Carregamento sob demanda, escolha automática ou manual e fallback
para inglês nas entradas ausentes. Core adapta formatos posicionais ao Lua 5.1.
Português e italiano não são idiomas nativos do cliente original 3.3.5.
Os catálogos são preservados sem alterações; traduções incompletas usam inglês.
