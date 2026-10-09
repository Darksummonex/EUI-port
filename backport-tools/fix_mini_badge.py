from pathlib import Path
import shutil
from datetime import datetime
root = Path(__file__).resolve().parents[1]
backup = root / '.codex-backups' / ('before-mini-badge-' + datetime.now().strftime('%Y%m%d-%H%M%S'))
shutil.copytree(root / 'EllesmereUI', backup / 'EllesmereUI')
def edit(name, old, new):
    p = root / name
    raw = p.read_bytes()
    nl = '\r\n' if b'\r\n' in raw else '\n'
    text = raw.decode('utf-8').replace('\r\n', '\n')
    assert old in text, name
    p.write_bytes(text.replace(old, new, 1).replace('\n', nl).encode('utf-8'))
panel = 'EllesmereUI/EllesmereUI_Panel.lua'
edit(panel, '        local badge = mini:CreateTexture(nil, "ARTWORK", nil, 1)', '''        -- Wrath cannot mask textures; baked alpha and a separate frame keep
        -- the solid ring from covering the emblem in its texture batching.
        local badgeHost = mini
        if _G.EUI_WOW_335 then
            badgeHost = CreateFrame("Frame", nil, mini)
            badgeHost:SetAllPoints(mini)
            badgeHost:SetFrameLevel(mini:GetFrameLevel() + 3)
        end
        local badge = badgeHost:CreateTexture(nil, "ARTWORK", nil, 1)''')
edit(panel, 'local badgeOv = mini:CreateTexture(nil, "ARTWORK", nil, 2)', 'local badgeOv = badgeHost:CreateTexture(nil, "ARTWORK", nil, 2)')
edit(panel, '        -- Badge: a thin ring', '''        local closeIcon
        if _G.EUI_WOW_335 then
            closeIcon = miniClose:CreateTexture(nil, "OVERLAY")
            closeIcon:SetTexture(MEDIA_PATH .. "icons_335\\\\close-popup-4.tga")
            closeIcon:SetSize(16, 16)
            closeIcon:SetPoint("CENTER", miniClose, "CENTER")
        end

        -- Badge: a thin ring''')
edit(panel, '            tbox.Paint(expandBox, theme, tr, tg, tb)', '''            if _G.EUI_WOW_335 then
                badge:SetTexture(MEDIA_PATH .. "mini_335\\\\" .. file:match("([^\\\\]+)$"))
                badge:SetTexCoord(0, 1, 0, 1)
                ring:SetTexture(MEDIA_PATH .. "mini_335\\\\ring.tga")
                ring:SetVertexColor(rr, rg, rb, 1)
                if ov then
                    badgeOv:SetTexture(MEDIA_PATH .. "mini_335\\\\pixels-accent.tga")
                    badgeOv:SetTexCoord(0, 1, 0, 1)
                    badgeOv:SetSize(H, H)
                    badgeOv:ClearAllPoints()
                    badgeOv:SetPoint("TOPLEFT", mini, "TOPLEFT", 0, 0)
                end
                closeIcon:SetVertexColor(spec.r, spec.g, spec.b, 1)
            end
            tbox.Paint(expandBox, theme, tr, tg, tb)''')
edit('EllesmereUI/EllesmereUI.toc', '3.3.5-core-0.56', '3.3.5-core-0.57')
edit('EllesmereUI/README-335.md', '# EllesmereUI Wrath Core — 0.56\n', '# EllesmereUI Wrath Core — 0.57\n')
edit('EllesmereUI/README-335.md', '\n\n0.56:', '\n\n0.57: menu recolhido usa emblemas circulares com transparência nativa e\nícone de fechar explícito no Wrath; corrige o quadrado de cor sobre o logo.\n\n0.56:')
edit('EllesmereUIOptions/EUI__General_Options.lua', 'version = "Core 0.56",\n        heroes = {', 'version = "Core 0.57",\n        heroes = {\n            { title = "Collapsed Menu Icons", desc = "The collapsed menu badge and close icon now render correctly on the Wrath client." },')
edit('CODEX_HANDOFF_EllesmereUI_335_CURRENT.md', 'Core 0.56; Action', 'Core 0.57; Action')
edit('CODEX_HANDOFF_EllesmereUI_335_CURRENT.md', 'Chat 0.47;', 'Chat 0.48;')
edit('CODEX_HANDOFF_EllesmereUI_335_CURRENT.md', 'Options 0.106;', 'Options 0.107;')
edit('CODEX_HANDOFF_EllesmereUI_335_CURRENT.md', '## Latest work (2026-10-05 / 06)', '''## Latest work (2026-10-05 / 06)

- 2026-10-07: restored Chat 0.48 / Options 0.107 gold-seller filters at Alex's
  request, including bucks offers and disguised website names. Core 0.57 uses
  baked circular badge alpha and an explicit close icon for the collapsed menu.
  No Gargul changes are included.''')
