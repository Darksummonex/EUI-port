"""Remove Optimize My FPS and Graphics from the Global Settings General page.

Its CVars are Retail-only (graphics*, RAIDsettingsEnabled, ResampleAlwaysSharpen,
Contrast), so on 3.3.5 it changed nothing. Cuts the CVar table with its
Apply/Restore functions, and replaces the middle Optimize/Restore card and its
"What Does This Do?" link with a two-card row (Reset ALL | Uninstall EUI).
Keeps CRLF endings.
"""
from pathlib import Path

path = Path(__file__).resolve().parents[1] / 'EllesmereUIOptions' / 'EUI__General_Options.lua'
text = path.read_bytes().decode('utf-8')
NL = '\r\n'
RULE = '        -------------------------------------------------------------------' + NL


def cut(start, end, replacement, keep_end):
    global text
    assert text.count(start) == 1, start[:60]
    assert text.count(end) == 1, end[:60]
    s = text.index(start)
    e = text.index(end)
    assert s < e
    stop = e if keep_end else e + len(end)
    removed = text[s:stop]
    text = text[:s] + replacement + text[stop:]
    return removed.count(NL)


n1 = cut(RULE + '        --  Optimized graphics CVar table + buttons (above all sections)' + NL,
         RULE + '        --  TOP SECTION: one row', '', keep_end=True)

new_row = NL.join([
    '        local cards',
    '        y, cards = EllesmereUI.BuildActionCardRow(parent, y, {',
    '            { icon = MEDIA_ICONS .. "sync.tga", accent = WARN,',
    '              title = EllesmereUI.L("Reset ALL EUI Addon Settings"),',
    '              desc = EllesmereUI.L("Return every EUI addon to its defaults."),',
    '              onClick = ConfirmResetAll },',
    '            -- power\'s glyph fills its whole canvas: drawn smaller, it matches sync.',
    '            { icon = MEDIA_ICONS .. "power.tga", accent = WARN, iconSize = 22,',
    '              title = EllesmereUI.L("Uninstall EUI"), desc = EllesmereUI.L("Revert EUI\'s changes and disable."),',
    '              onClick = ConfirmUninstall },',
    '        }, { inline = true })',
    '        y = y - 6',
    '',
]) + NL
n2 = cut("        -- The middle card's two forms: Optimize, or Restore while a backup exists" + NL,
         '        PP.Point(infoBtn, "TOP", gfxCard, "BOTTOM", 0, -GFX_GAP)' + NL + '        y = y - 6' + NL,
         new_row, keep_end=False)

assert 'ApplyOptimizedGfx' not in text and 'GfxCardContent' not in text and 'infoBtn' not in text[text.index('local function BuildGeneralPage'):text.index('--  DISPLAY')]
path.write_bytes(text.encode('utf-8'))
print('removed', n1, 'and', n2, 'lines')
