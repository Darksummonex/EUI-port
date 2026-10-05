"""Build 0.25: native DataBars, progress integration and saved bag-button fix."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
path=root/'backport-tools/package_unitframes.py'; text=path.read_text(encoding='utf-8-sig')
for before,after in [
    ("'EllesmereUIBags':'9.3.4-335-0.5'","'EllesmereUIBags':'9.3.4-335-0.6'"),
    ("'EllesmereUIOptions':'9.3.4-335-0.29'","'EllesmereUIOptions':'9.3.4-335-0.30'"),
    ("'EllesmereUIActionBars':'9.3.4-335-0.10'","'EllesmereUIActionBars':'9.3.4-335-0.11'"),
    ("'EllesmereUIRaidFrames':'9.3.4-335-0.2'}","'EllesmereUIRaidFrames':'9.3.4-335-0.2','EllesmereUIDataBars':'9.3.4-335-0.1'}"),
    ('EllesmereUIBags-3.3.5-0.5.zip','EllesmereUIBags-3.3.5-0.6.zip'),
    ('EllesmereUIOptions-3.3.5-0.29.zip','EllesmereUIOptions-3.3.5-0.30.zip'),
    ('EllesmereUIActionBars-3.3.5-0.10.zip','EllesmereUIActionBars-3.3.5-0.11.zip'),
    ("    'EllesmereUI-3.3.5-HUD-test-0.24.zip':list(versions),","    'EllesmereUIDataBars-3.3.5-0.1.zip':['EllesmereUIDataBars'],\n    'EllesmereUI-3.3.5-HUD-test-0.25.zip':list(versions),"),
]:
    assert before in text,before; text=text.replace(before,after)
path.write_text(text,encoding='utf-8')
path=root/'EllesmereUIBags/README-335.md'; text=path.read_text(encoding='utf-8-sig')
text=text.replace('# Bags 3.3.5a — 0.5','# Bags 3.3.5a — 0.6',1)
text=text.replace('Inventory storage is entirely owned',
    '0.6 fixes SetCheckedTexture on saved bank/alt buttons. These are plain\nButton objects for read-only snapshots; only live CheckButtons clear checked\ntextures. The fixture now enforces this native method distinction, reproduces\nthe reported error before the fix, and passes afterward.\n\nInventory storage is entirely owned',1)
path.write_text(text,encoding='utf-8')
path=root/'EllesmereUIActionBars/README-335.md'; text=path.read_text(encoding='utf-8-sig')
text=text.replace('# Action Bars 3.3.5 — 0.10',
    '# Action Bars 3.3.5 — 0.11\n\n0.11 hides its XP or reputation holder/mover while a visible DataBars block\ndisplays that progress type. Existing native bar suppression stays intact.\nDisabling/removing the DataBars block restores the configured HUD bar; no\nsaved ActionBars preference is changed.\n',1)
path.write_text(text,encoding='utf-8')
path=root/'EllesmereUIOptions/README-335.md'; text=path.read_text(encoding='utf-8-sig')
text=text.replace('# Options 3.3.5 — 0.24',
    '# Options 3.3.5 — 0.30\n\n0.30 adds a native DataBars page: bar selector, templates, appearance/layout,\nvisibility, ordered blocks and block-specific settings. The original Retail\noptions file remains unloaded. Use /edb or EllesmereUI > DataBars.\n',1)
path.write_text(text,encoding='utf-8')
entry='''Latest build: HUD-test-0.25. DataBars 0.1 / Bags 0.6 / Options 0.30 /
ActionBars 0.11; other versions unchanged.

Added the requested EllesmereUIDataBars Retail folder as unchanged Lua/media
references with a native 3.3.5 TOC loading only EUI_DataBars_335.lua and
EUI_DataBars_335_Blocks.lua. /edb opens a single native settings page: bar
selection, four templates, CRUD, ordered blocks, horizontal/vertical layouts,
full-screen/custom length, equal/custom width weights, scale, fonts, opacity,
EUI accent/flat themes, border and secure combat/group visibility. A bottom
information bar is seeded once on a fresh profile. Every bar has its own Edit
Mode mover and profile position. Core profile refresh already invokes _EDB_Apply.

Twenty native block types: clock, FPS, latency, location, coordinates, gold,
bags, durability, combat, XP/reputation, talents/dual spec, primary/secondary
professions, hearthstone, micro menu, currency, equipped item-level average,
audio, EUI inventory broker and spacer. The travel action is a native secure
item button. Data comes from the client or EUI's own inventory namespace only;
no external addon data or dependency. Retail-only Crests/Great Vault/loot spec,
warbank, random hearthstones and arbitrary external broker plugins are absent.
Coordinates do not alter the user's map selection and can be unavailable;
currency/skill lists follow native expanded categories. Equipped iLvl is a
local average of occupied slots, not a Retail item-level API value.

ActionBars hides its own XP/reputation holder and Edit Mode entry while an
active DataBars block presents the same progress type. Its suppression of
native Blizzard bars is retained; removing/disabling the block restores the
configured ActionBars holder without changing saved preferences. The default
bottom template uses information blocks, leaving the existing progress bars.

Bags saved bank/alt item buttons remain read-only plain Buttons. They no
longer call CheckButton-only SetCheckedTexture; live item CheckButtons still
clear their checked texture. A stricter fixture reproduced the exact reported
line-109 failure before the fix. Cache, serialization/persistence, broker and
inventory/resource tests now pass with native button types enforced.

DataBars tests execute actual Lite/module/options code and verify all block
values/actions, secure hearthstone, state drivers, combat deferral, profile
replacement, frame reuse, layout bounds/vertical, positions, option writes,
source byte integrity and native TOC. ActionBars regressions include progress
handoff/fallback. 215 Lua 5.1 files compile. Thirteen addon folders/fourteen
release archives are current; project pack excludes player data. Native
rendering, input and taint confirmation still require the in-game test.

Previous checkpoint: HUD-test-0.24. Bags 0.5 / Options 0.29 / ActionBars 0.10;
other versions unchanged.'''
for name in ['CODEX_HANDOFF_EllesmereUI_335_CURRENT.md','ELLESMEREUI_335_BACKPORT_STATUS.md']:
    path=root/name; text=path.read_text(encoding='utf-8-sig')
    old='Latest build: HUD-test-0.24. Bags 0.5 / Options 0.29 / ActionBars 0.10;\nother versions unchanged.'
    assert old in text,name; text=text.replace(old,entry,1)
    if name.startswith('CODEX'):
        text=text.replace('| EllesmereUIBags | 9.3.4-335-0.5 |','| EllesmereUIBags | 9.3.4-335-0.6 |')
        text=text.replace('| EllesmereUIOptions | 9.3.4-335-0.29 |','| EllesmereUIOptions | 9.3.4-335-0.30 |')
        text=text.replace('| EllesmereUIActionBars | 9.3.4-335-0.10 |','| EllesmereUIActionBars | 9.3.4-335-0.11 |')
        text=text.replace('| EllesmereUIRaidFrames | 9.3.4-335-0.2 |','| EllesmereUIRaidFrames | 9.3.4-335-0.2 |\n| EllesmereUIDataBars | 9.3.4-335-0.1 |')
        text=text.replace('Full build: EllesmereUI-3.3.5-HUD-test-0.24.zip. Keep it together with the twelve','Full build: EllesmereUI-3.3.5-HUD-test-0.25.zip. Keep it together with the thirteen')
    path.write_text(text,encoding='utf-8')
path=root/'ELLESMEREUI_PROJECT_PACK.md'; text=path.read_text(encoding='utf-8-sig')
start=text.index('Saved checkpoint:'); end=text.index('This project pack contains')
text=text[:start]+'''Saved checkpoint: 1 October 2026. Build 0.25 adds native DataBars with
twenty information blocks, multiple configurable bars and secure Edit Mode /
combat integration. It also fixes saved-bank/alt button APIs and integrates
XP/reputation with ActionBars. Automated checks passed; client confirmation
is pending. Inventory remains owned entirely by EllesmereUI.

'''+text[end:]
text=text.replace('build 0.24','build 0.25').replace('HUD-test-0.24.zip','HUD-test-0.25.zip')
text=text.replace('twelve EllesmereUI','thirteen EllesmereUI').replace('thirteen current release ZIPs','fourteen current release ZIPs').replace('the twelve addon folders','the thirteen addon folders')
path.write_text(text,encoding='utf-8')
print('PASS: DataBars 0.1 / Bags 0.6 / Options 0.30 / ActionBars 0.11 / build 0.25 checkpoint recorded.')
