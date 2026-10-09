"""Use the existing Ellesmere E logo in the native collapsed badge."""
from pathlib import Path
from datetime import datetime
import shutil
root = Path(__file__).resolve().parents[1]
backup = root / '.codex-backups' / ('before-mini-logo-' + datetime.now().strftime('%Y%m%d-%H%M%S'))
def edit(name, old, new):
    path = root / name
    dest = backup / name
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, dest)
    raw = path.read_bytes()
    nl = '\r\n' if b'\r\n' in raw else '\n'
    text = raw.decode('utf-8').replace('\r\n', '\n')
    assert old in text, name
    path.write_bytes(text.replace(old, new, 1).replace('\n', nl).encode('utf-8'))
edit('EllesmereUI/EllesmereUI_Panel.lua', '''                badge:SetTexture(MEDIA_PATH .. "mini_335\\\\" .. file:match("([^\\\\]+)$"))
                badge:SetTexCoord(0, 1, 0, 1)
                ring:SetTexture(MEDIA_PATH .. "mini_335\\\\ring.tga")
                ring:SetVertexColor(rr, rg, rb, 1)
                if ov then
                    badgeOv:SetTexture(MEDIA_PATH .. "mini_335\\\\pixels-accent.tga")
                    badgeOv:SetTexCoord(0, 1, 0, 1)
                    badgeOv:SetSize(H, H)
                    badgeOv:ClearAllPoints()
                    badgeOv:SetPoint("TOPLEFT", mini, "TOPLEFT", 0, 0)
                end''', '''                badge:SetTexture(MEDIA_PATH .. "mini_335\\\\ring.tga")
                badge:SetTexCoord(0, 1, 0, 1)
                badge:SetDesaturated(false)
                badge:SetVertexColor(0, 0, 0, 1)
                ring:SetTexture(MEDIA_PATH .. "mini_335\\\\ring.tga")
                ring:SetVertexColor(rr, rg, rb, 1)
                badgeOv:SetTexture(MEDIA_PATH .. "eg-logo.tga")
                badgeOv:SetTexCoord(0, 1, 0, 1)
                badgeOv:SetDesaturated(true)
                badgeOv:SetSize(H * 0.8, H * 0.8)
                badgeOv:ClearAllPoints()
                badgeOv:SetPoint("CENTER", badge, "CENTER")
                badgeOv:SetVertexColor(ELLESMERE_GREEN.r, ELLESMERE_GREEN.g, ELLESMERE_GREEN.b, 1)
                badgeOv:Show()''')
edit('EllesmereUI/README-335.md', '0.57: menu recolhido usa emblemas circulares com transparência nativa e', '0.57: menu recolhido usa o logo E original do Ellesmere sobre um disco\npreto com transparência circular nativa, cor de destaque do UI e')
edit('EllesmereUIOptions/EUI__General_Options.lua', 'The collapsed menu badge and close icon now render correctly on the Wrath client.', 'The collapsed menu displays the original Ellesmere E logo with the UI accent color and a working close icon on the Wrath client.')
edit('CODEX_HANDOFF_EllesmereUI_335_CURRENT.md', 'baked circular badge alpha and an explicit close icon for the collapsed menu.', 'baked circular badge alpha, the existing eg-logo.tga Ellesmere E logo tinted\n  with the UI accent, and an explicit close icon for the collapsed menu.')
