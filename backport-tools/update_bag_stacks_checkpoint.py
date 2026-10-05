"""Record the build 0.22 stack-count correction once."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
for file in ['validate_inventory_resources.py','validate_bag_cache.py']:
    path=root/'backport-tools'/file
    text=path.read_text(encoding='utf-8-sig').replace('.count:','.stackCount:').replace('.count.font','.stackCount.font')
    if file=='validate_inventory_resources.py':
        text=text.replace("assert(potion.stackCount:IsShown(),'Native template stack count remains hidden')","assert(potion.count==12 and sword.count==1 and f.pool['0:4'].count==0,'Native numeric item count missing')\nassert(potion.stackCount:IsShown(),'Native template stack count remains hidden')")
    path.write_text(text,encoding='utf-8')
path=root/'EllesmereUIBags/EllesmereUIBags.toc'
text=path.read_text(encoding='utf-8-sig'); assert '## Version: 9.3.4-335-0.2' in text
path.write_text(text.replace('## Version: 9.3.4-335-0.2','## Version: 9.3.4-335-0.3'),encoding='utf-8')
path=root/'EllesmereUIBags/README-335.md'
text=path.read_text(encoding='utf-8-sig').replace('# Bags 3.3.5a — 0.2','# Bags 3.3.5a — 0.3')
text=text.replace("Native unified player bags and bank using EllesmereUI's flat appearance.",'''0.3 fixes missing stack quantities. Native Count FontStrings start hidden;
the renderer now explicitly shows stacks above one and hides counts for single
items/empty slots in both live and saved views. Stack labels use white OVERLAY
text, with the native numeric button.count kept separate for item/refund
handlers. Regression checks reproduce the hidden-label failure before the fix
and pass afterward, including stack changes, saved banks/alts and font sizes.

Native unified player bags and bank using EllesmereUI's flat appearance.''')
path.write_text(text,encoding='utf-8')
path=root/'backport-tools/package_unitframes.py'
text=path.read_text(encoding='utf-8-sig')
for before,after in [("'EllesmereUIBags':'9.3.4-335-0.2'","'EllesmereUIBags':'9.3.4-335-0.3'"),('EllesmereUIBags-3.3.5-0.2.zip','EllesmereUIBags-3.3.5-0.3.zip'),('EllesmereUI-3.3.5-HUD-test-0.21.zip','EllesmereUI-3.3.5-HUD-test-0.22.zip')]:
    assert before in text,before
    text=text.replace(before,after)
path.write_text(text,encoding='utf-8')
entry='''Latest build: HUD-test-0.22. Bags 0.3; other versions unchanged.

User reported missing item stack information. Wrath ItemButtonTemplate Count
starts hidden; setting its text did not reveal live bag/bank quantities. The
renderer now shows counts above one, hides single/empty counts and promotes
white stack text to OVERLAY. The label is stored as stackCount separately from
the native numeric button.count expected by item/refund handlers. Saved bank
and alt views follow the same visibility rule; existing count font settings
still apply.

Validation: the legacy fixture models the native hidden Count region and its
BORDER layer. Visibility regression failed before the correction and passes
afterward. Inventory/resource and cache checks cover live counts, stack changes,
empty/single slots, saved bank/alts, numeric count metadata and Global Fonts.
All 192 Lua 5.1 sources compile. Build archives and project pack are verified;
client display confirmation pending. Older archives retained.

Native references: https://github.com/wowgaming/3.3.5-interface-files/blob/main/ItemButtonTemplate.xml
and https://github.com/wowgaming/3.3.5-interface-files/blob/main/ItemButtonTemplate.lua

Previous checkpoint: HUD-test-0.21. Core 0.23 / Options 0.27 / Bags 0.2 /
ActionBars 0.9. Other module versions are unchanged.'''
for name in ['CODEX_HANDOFF_EllesmereUI_335_CURRENT.md','ELLESMEREUI_335_BACKPORT_STATUS.md']:
    path=root/name; text=path.read_text(encoding='utf-8-sig')
    before='Latest build: HUD-test-0.21. Core 0.23 / Options 0.27 / Bags 0.2 /\nActionBars 0.9. Other module versions are unchanged.'
    assert before in text,name
    text=text.replace(before,entry,1)
    if name.startswith('CODEX'):
        text=text.replace('| EllesmereUIBags | 9.3.4-335-0.2 |','| EllesmereUIBags | 9.3.4-335-0.3 |').replace('Full build: EllesmereUI-3.3.5-HUD-test-0.21.zip','Full build: EllesmereUI-3.3.5-HUD-test-0.22.zip')
    path.write_text(text,encoding='utf-8')
path=root/'ELLESMEREUI_PROJECT_PACK.md'
text=path.read_text(encoding='utf-8-sig').replace('build 0.21','build 0.22').replace('EllesmereUI-3.3.5-HUD-test-0.21.zip','EllesmereUI-3.3.5-HUD-test-0.22.zip')
text=text.replace('Build 0.21 adds live bag-slot strips, saved\nbank/alt inventory and HUD Bag Bar consolidation; automated checks pass and','Build 0.22 fixes hidden stack counts in live/saved bag and bank views, following\nbuild 0.21 bag-slot strips, bank/alt caching and HUD consolidation. Checks pass and')
path.write_text(text,encoding='utf-8')
print('PASS: Bags 0.3 / build 0.22 stack-count checkpoint recorded.')
