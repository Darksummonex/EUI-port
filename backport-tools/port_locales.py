"""Install the original community catalogs for native 3.3.5 locales."""
from pathlib import Path
from datetime import datetime
import shutil
root = Path(__file__).resolve().parents[1]
source = Path('D:/World of Warcraft/_retail_/Interface/AddOns/EllesmereUILocales')
dest = root / 'EllesmereUILocales'
dest.mkdir(exist_ok=True)
codes = ['deDE', 'esES', 'esMX', 'frFR', 'koKR', 'ruRU', 'zhCN', 'zhTW']
for code in codes:
    shutil.copy2(source / (code + '.lua'), dest / (code + '.lua'))
(dest / 'EllesmereUILocales.toc').write_text('''## Interface: 30300
## Title: |cff0cd29fEllesmereUI|r Locales
## Notes: Community translations for native WoW 3.3.5 languages; untranslated text falls back to English.
## Author: Ellesmere / community translators / 3.3.5 backport
## Version: 3.3.5-locales-0.1
## Dependencies: EllesmereUI
## LoadOnDemand: 1
## IconTexture: Interface\\AddOns\\EllesmereUI\\media\\eg-logo.tga
''' + '\n'.join(code + '.lua' for code in codes) + '\n', encoding='utf-8')
(dest / 'README-335.md').write_text('''# Locales 3.3.5 — 0.1

0.1: catálogos originais da comunidade para deDE, esES, esMX, frFR, koKR,
ruRU, zhCN e zhTW. Inglês enUS/enGB usa os textos originais sem carregar
este addon. Carregamento sob demanda, escolha automática ou manual e fallback
para inglês nas entradas ausentes. Core adapta formatos posicionais ao Lua 5.1.
Português e italiano não são idiomas nativos do cliente original 3.3.5.
Os catálogos são preservados sem alterações; traduções incompletas usam inglês.
''', encoding='utf-8')
engine = (root / 'EllesmereUI/EllesmereUI_Locale.lua').read_text(encoding='utf-8-sig')
engine = engine.replace('    itIT = true, ptBR = true, ruRU = true,', '    ruRU = true,')
engine = engine.replace('local function GlyphFont(locale)', '''local function GlyphFont(locale)
    -- Localized Wrath clients expose their installed native glyph font here.
    if locale == GetLocale() and STANDARD_TEXT_FONT then return STANDARD_TEXT_FONT end''')
engine = engine.replace('    return t:format(...)', '''    -- Lua 5.1 does not understand WoW's positional %1$s notation.
    -- Format each conversion independently so translated word order is kept.
    local args, nextArg, out, i = {...}, 1, {}, 1
    while i <= #t do
        local start = t:find("%", i, true)
        if not start then out[#out + 1] = t:sub(i); break end
        out[#out + 1] = t:sub(i, start - 1)
        if t:sub(start + 1, start + 1) == "%" then
            out[#out + 1] = "%"; i = start + 2
        else
            local tail = t:sub(start + 1)
            local position, spec = tail:match("^(%d+)%$([%-%+ #0]*%d*%.?%d*[cdiouxXeEfgGqs])")
            local consumed
            if position then
                consumed = #position + 1 + #spec
            else
                spec = tail:match("^([%-%+ #0]*%d*%.?%d*[cdiouxXeEfgGqs])")
                position = nextArg; nextArg = nextArg + 1
                consumed = spec and #spec
            end
            if not spec then return t:format(unpack(args)) end
            out[#out + 1] = string.format("%" .. spec, args[tonumber(position)])
            i = start + 1 + consumed
        end
    end
    return table.concat(out)''')
(root / 'EllesmereUI/EUI_Locale_335.lua').write_text('-- Native Wrath locale engine; Retail reference remains untouched.\n' + engine, encoding='utf-8')
backup = root / '.codex-backups' / ('before-locales-' + datetime.now().strftime('%Y%m%d-%H%M%S'))
def edit(name, old, new):
    path = root / name
    save = backup / name
    save.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, save)
    raw = path.read_bytes(); nl = '\r\n' if b'\r\n' in raw else '\n'
    text = raw.decode('utf-8').replace('\r\n', '\n')
    assert old in text, name
    path.write_bytes(text.replace(old, new, 1).replace('\n', nl).encode('utf-8'))
edit('EllesmereUI/EllesmereUI.toc', 'EllesmereUI_Locale.lua', 'EUI_Locale_335.lua')
edit('EllesmereUI/EllesmereUI.toc', '3.3.5-core-0.57', '3.3.5-core-0.58')
edit('EllesmereUI/README-335.md', '— 0.57\n', '— 0.58\n\n0.58: idiomas nativos do Wrath com Locales 0.1; formatos posicionais\ncompatíveis com Lua 5.1 e fonte nativa no cliente localizado.\n')
edit('EllesmereUIOptions/EUI__General_Options.lua', '                ["itIT"] = { text = "Italiano" },\n                ["ptBR"] = { text = "Português (BR)" },\n', '')
edit('EllesmereUIOptions/EUI__General_Options.lua', '"esMX", "itIT", "ptBR", "ruRU"', '"esMX", "ruRU"')
edit('EllesmereUIOptions/EUI__General_Options.lua', 'version = "Core 0.57",', 'version = "Core 0.58",')
edit('EllesmereUIOptions/EUI__General_Options.lua', 'version = "Core 0.58",\n        heroes = {', 'version = "Core 0.58",\n        heroes = {\n            { title = "Native Wrath Languages", desc = "The Locales addon provides community translations for all original Wrath client languages, with English fallback and Lua 5.1 formatting." },')
edit('EllesmereUIOptions/EllesmereUIOptions.toc', '0.107', '0.108')
edit('EllesmereUIOptions/EUI__General_Options.lua', 'version = "Options 0.99"', 'version = "Options 0.108"')
edit('EllesmereUIOptions/README-335.md', '— 0.107\n', '— 0.108\n\n0.108: seletor de idioma limitado aos idiomas nativos do WoW 3.3.5.\n')
edit('CODEX_HANDOFF_EllesmereUI_335_CURRENT.md', 'Core 0.57;', 'Core 0.58;')
edit('CODEX_HANDOFF_EllesmereUI_335_CURRENT.md', 'Options 0.107;', 'Options 0.108; Locales 0.1;')
edit('CODEX_HANDOFF_EllesmereUI_335_CURRENT.md', '## Latest work (2026-10-05 / 06)', '''## Latest work (2026-10-05 / 06)

- Core 0.58 / Options 0.108 / Locales 0.1: eight byte-identical Retail
  community catalogs for native 3.3.5 locales; English is built in. New
  EUI_Locale_335.lua replaces the Retail engine in the TOC and supports Lua 5.1
  positional formats, native-client glyph fonts, automatic/manual selection
  and missing-key fallback. No ptBR/itIT catalogs (not native original Wrath).
  Project changes only; not deployed to Test yet.''')
