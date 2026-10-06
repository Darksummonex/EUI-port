"""Report assignments to Blizzard-owned globals in every file the EllesmereUI TOCs load.
Writing a Blizzard global from addon code taints it (even `X = X or {}`), and Blizzard
code that later reads it can be blocked from protected calls in the addon's name.
Adding a FIELD to a Blizzard table (StaticPopupDialogs.MY_KEY = ...) is fine, and so is
`if not X then X = ... end`, which only writes a name the client lacks."""
import re
from scan_protected_calls import ROOT, loaded_files

BLIZZARD = [
    'StaticPopupDialogs', 'UIPanelWindows', 'UISpecialFrames', 'UnitPopupMenus', 'UnitPopupButtons',
    'UIMenus', 'CHAT_FRAMES', 'ChatTypeInfo', 'ChatTypeGroup', 'SlashCmdList', 'RAID_CLASS_COLORS',
    'PowerBarColor', 'UIDROPDOWNMENU_MAXBUTTONS', 'UIDROPDOWNMENU_MAXLEVELS',
    'UIDROPDOWNMENU_OPEN_MENU', 'UIDROPDOWNMENU_INIT_MENU', 'MAX_PARTY_MEMBERS', 'NUM_CHAT_WINDOWS',
    'StaticPopup_Show', 'StaticPopup_Hide', 'ToggleDropDownMenu', 'UIDropDownMenu_Initialize',
    'SetItemRef', 'ChatFrame_OnHyperlinkShow', 'GameTooltip_SetDefaultAnchor', 'UIParent_ManageFramePositions',
    'FCF_OpenTemporaryWindow', 'ContainerFrame_Update', 'ShowUIPanel', 'HideUIPanel', 'CloseWindows',
    'TargetFrame_OnEvent', 'PlayerFrame_OnEvent', 'BuffFrame_Update', 'WorldMapFrame_Update',
    'QuestLog_Update', 'WatchFrame_Update', 'Minimap_ZoomIn', 'LFDQueueFrame_Update',
    'MainMenuBar_UpdateExperienceBars', 'ActionButton_Update', 'PaperDollItemSlotButton_Update',
    'tinsert', 'tremove', 'wipe', 'strtrim', 'strsplit', 'strjoin',
]
WRITE = re.compile(r'^\s*(?:_G\.)?(' + '|'.join(BLIZZARD) + r')\s*=(?!=)')
WRITE_G = re.compile(r'_G\[\s*["\'](' + '|'.join(BLIZZARD) + r')["\']\s*\]\s*=(?!=)')
GUARDED = re.compile(r'^\s*if\s+not\s+(?:_G\.)?(\w+)\s+then\s+(?:_G\.)?\1\s*=')


def scan():
    hits = []
    for path in loaded_files():
        for n, line in enumerate(path.read_text(encoding='utf-8', errors='replace').splitlines(), 1):
            code = line.split('--', 1)[0]
            if GUARDED.match(code):
                continue
            for stmt in code.split(';'):
                m = WRITE.match(stmt) or WRITE_G.search(stmt)
                if m and not re.match(r'^\s*local\b', stmt):
                    hits.append((str(path.relative_to(ROOT)), n, m.group(1), line.strip()))
    return hits


if __name__ == '__main__':
    found = scan()
    for rel, n, name, line in found:
        print(f'{rel}:{n}: {name}  | {line[:140]}')
    print('hits', len(found))
