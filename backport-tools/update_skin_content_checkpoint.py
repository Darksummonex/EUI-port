from pathlib import Path

root=Path(__file__).resolve().parents[1]
package=root/'backport-tools/package_unitframes.py'
s=package.read_text(encoding='utf-8-sig')
for old,new in [
    ("'EllesmereUIBlizzardSkin':'9.3.4-335-0.3'", "'EllesmereUIBlizzardSkin':'9.3.4-335-0.4'"),
    ('EllesmereUIBlizzardSkin-3.3.5-0.3.zip','EllesmereUIBlizzardSkin-3.3.5-0.4.zip'),
    ('EllesmereUI-3.3.5-HUD-test-0.19.zip','EllesmereUI-3.3.5-HUD-test-0.20.zip')
]:
    assert s.count(old)==1,old
    s=s.replace(old,new)
package.write_text(s,encoding='utf-8')

entry='''Latest build: HUD-test-0.20. Core 0.23 / Options 0.26 / BlizzardSkin 0.4.
Other module versions are unchanged, including Raid Frames 0.2.

User reported unreadable Currency rows, missing random-dungeon reward icons,
missing talent icons, overlapping talent tabs and asked to check other tab
indicators. Shared skin fills now use an owned BACKGROUND texture on the
native owner; the child panel draws only borders. This prevents filled child
frames covering native icons/text when frame levels change. Native icons
are promoted to ARTWORK, including iconTexture/IconTexture fields, with
original layer/sublevel/coords restored when disabled. Currency uses native
sheet dimensions and header while PaperDoll is hidden; the expanded character
layout returns only on its own tab. Native Currency/LFD refresh functions and
TokenFrameContainer.update get guarded hooks even after delayed addon loading.

Talent footer tabs measure labels, pack with 6px gaps and retain IDs/native
clicks/selection. The point bar stays above the tab rows. Native geometry
restores on disable. Other native footer/header tab panels respect 10px
transparent margins rather than drawing over adjacent selection indicators;
FriendsTabHeader is recognized. Other tabs retain their native geometry/input.

Validation: validate_skin_content.py covers Currency sizing/text/icons,
LFD icons/tooltips/late refresh, talent icons/clicks/tab spacing, seven native
window tab strips (Merchant/Friends/GuildBank/Auction/Inspect/Achievement/
Options), selection state, combat deferral, native restoration and reuse.
Full BlizzardSkin/character-sheet checks and compilation of all 191 Lua 5.1
sources pass. Tests model native API contracts; in-game rendering still needs
confirmation. Thirteen current archives match the installed source and are
recorded with SHA-256 in the current manifest. Older archives retained.

Previous checkpoint: HUD-test-0.19. Core 0.23 / Options 0.26 / Raid Frames 0.2.
'''
for filename in ['CODEX_HANDOFF_EllesmereUI_335_CURRENT.md','ELLESMEREUI_335_BACKPORT_STATUS.md']:
    p=root/filename; s=p.read_text(encoding='utf-8-sig')
    old='Latest build: HUD-test-0.19. Core 0.23 / Options 0.26 / Raid Frames 0.2.\n'
    assert s.count(old)==1,filename
    s=s.replace(old,entry,1)
    if filename.startswith('CODEX_HANDOFF'):
        s=s.replace('| EllesmereUIBlizzardSkin | 9.3.4-335-0.3 |','| EllesmereUIBlizzardSkin | 9.3.4-335-0.4 |')
        s=s.replace('Full build: EllesmereUI-3.3.5-HUD-test-0.19.zip.','Full build: EllesmereUI-3.3.5-HUD-test-0.20.zip.')
    p.write_text(s,encoding='utf-8')
print('PASS: BlizzardSkin content fix versions and checkpoint documentation updated')
