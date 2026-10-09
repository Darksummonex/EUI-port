# Locales 3.3.5 — 0.1

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
