"""Record the build 0.21 inventory/cache and consolidated HUD transition once."""
from pathlib import Path

root=Path(__file__).resolve().parents[1]
for folder,old,new in [('EllesmereUIBags','0.1','0.2'),('EllesmereUIActionBars','0.8','0.9'),('EllesmereUIOptions','0.26','0.27')]:
    path=root/folder/(folder+'.toc')
    text=path.read_text(encoding='utf-8-sig')
    before='## Version: 9.3.4-335-'+old
    assert before in text,path
    path.write_text(text.replace(before,'## Version: 9.3.4-335-'+new),encoding='utf-8')
path=root/'backport-tools/package_unitframes.py'
text=path.read_text(encoding='utf-8-sig')
for before,after in [
    ("'EllesmereUIBags':'9.3.4-335-0.1'","'EllesmereUIBags':'9.3.4-335-0.2'"),
    ("'EllesmereUIActionBars':'9.3.4-335-0.8'","'EllesmereUIActionBars':'9.3.4-335-0.9'"),
    ("'EllesmereUIOptions':'9.3.4-335-0.26'","'EllesmereUIOptions':'9.3.4-335-0.27'"),
    ('EllesmereUIBags-3.3.5-0.1.zip','EllesmereUIBags-3.3.5-0.2.zip'),
    ('EllesmereUIActionBars-3.3.5-0.8.zip','EllesmereUIActionBars-3.3.5-0.9.zip'),
    ('EllesmereUIOptions-3.3.5-0.26.zip','EllesmereUIOptions-3.3.5-0.27.zip'),
    ('EllesmereUI-3.3.5-HUD-test-0.20.zip','EllesmereUI-3.3.5-HUD-test-0.21.zip'),
]:
    assert before in text,before
    text=text.replace(before,after)
path.write_text(text,encoding='utf-8')

entry='''Latest build: HUD-test-0.21. Core 0.23 / Options 0.27 / Bags 0.2 /
ActionBars 0.9. Other module versions are unchanged.

Inventory and bank now include bag-equipment slot strips with capacities,
click filters, native item drop/bag pickup and confirmed bank-slot purchases.
Bank opens the current character's last saved bank away from a banker;
Characters selects saved bag/bank contents for alts across realms. Saved items
use separate plain buttons with no native item-action handlers. Search, bag
filters, saved timestamps and cross-character item counts work on snapshots.
Unknown bank contents are identified instead of reported as an empty bank.

Account snapshots live in EllesmereUIDB.wrathInventoryCache outside layout
profiles. Bags record even while closed/in combat; bank reads occur only in
an active bank session. Each alt must be logged into, and its bank visited,
to populate the cache. Normal game logout/reload persists SavedVariables.
The project pack contains code, not player inventory data.

Action Bars > Select Bar > Bag Bar > Consolidate Bags reduces the HUD strip
to one native backpack button opening the unified inventory. It preserves
the interior bag-slot strips, native events/scripts and full-strip restoration;
changes made during combat wait until combat ends.

Validation: validate_bag_cache.py covers native slot IDs/drop/pickup/purchase,
saved banks away from bankers, realm/alt isolation, stale removal, closed-window
and combat recording, read-only pools, search/counts, profile/reset/reload
persistence, selector/options and exact bank-session/native restoration.
Inventory/resource and secure ActionBars/HUD regressions pass, as do Raid/QoL
regressions and compilation of 192 Lua 5.1 files. Client rendering/input and
real logout/relogin persistence still require user confirmation. Twelve addon
folders/thirteen release archives are saved and verified against installed
sources with SHA-256. Older archives retained.

Previous checkpoint: HUD-test-0.20. Core 0.23 / Options 0.26 / BlizzardSkin 0.4.
User confirmed its currency, dungeon rewards, talent icons and tab skins look
good in the client; project-0.20 was saved and verified.
'''
for name,heading in [('CODEX_HANDOFF_EllesmereUI_335_CURRENT.md','# EllesmereUI 3.3.5a — Current checkpoint — 2026-10-01'),('ELLESMEREUI_335_BACKPORT_STATUS.md','# Estado do backport — 01/10/2026')]:
    path=root/name
    text=path.read_text(encoding='utf-8-sig')
    old='Latest build: HUD-test-0.20. Core 0.23 / Options 0.26 / BlizzardSkin 0.4.'
    assert old in text,name
    text=heading+'\n'+text.split('\n',1)[1]
    text=text.replace(old,entry,1)
    if name.startswith('CODEX'):
        for before,after in [('| EllesmereUIOptions | 9.3.4-335-0.26 |','| EllesmereUIOptions | 9.3.4-335-0.27 |'),('| EllesmereUIActionBars | 9.3.4-335-0.8 |','| EllesmereUIActionBars | 9.3.4-335-0.9 |'),('| EllesmereUIBags | 9.3.4-335-0.1 |','| EllesmereUIBags | 9.3.4-335-0.2 |'),('Full build: EllesmereUI-3.3.5-HUD-test-0.20.zip','Full build: EllesmereUI-3.3.5-HUD-test-0.21.zip')]:
            assert before in text,before
            text=text.replace(before,after,1)
    path.write_text(text,encoding='utf-8')
path=root/'ELLESMEREUI_PROJECT_PACK.md'
text=path.read_text(encoding='utf-8-sig').replace('build 0.20','build 0.21').replace('EllesmereUI-3.3.5-HUD-test-0.20.zip','EllesmereUI-3.3.5-HUD-test-0.21.zip')
text=text.replace('Saved checkpoint: 30 September 2026. The user confirmed the currency, dungeon\nreward, talent icon and tab skin corrections look good in the game client.','Saved checkpoint: 1 October 2026. Build 0.21 adds live bag-slot strips, saved\nbank/alt inventory and HUD Bag Bar consolidation; automated checks pass and\nclient confirmation is pending. The user confirmed build 0.20 currency, dungeon\nreward, talent icon and tab skin corrections looked good in the game client.')
path.write_text(text,encoding='utf-8')
print('PASS: Bags 0.2 / ActionBars 0.9 / Options 0.27; build 0.21 checkpoint recorded.')
