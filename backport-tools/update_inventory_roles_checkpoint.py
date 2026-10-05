"""Record build 0.26 after lifecycle, inventory, skins and raid options fixes."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
changes={'EllesmereUIDataBars':('0.1','0.2'),'EllesmereUIBags':('0.6','0.7'),'EllesmereUIBlizzardSkin':('0.4','0.5'),'EllesmereUIRaidFrames':('0.2','0.3'),'EllesmereUIOptions':('0.30','0.31')}
path=root/'backport-tools/package_unitframes.py'; text=path.read_text(encoding='utf-8-sig')
for folder,(old,new) in changes.items():
    before=f"'{folder}':'9.3.4-335-{old}'"; assert before in text
    text=text.replace(before,f"'{folder}':'9.3.4-335-{new}'")
    text=text.replace(f'{folder}-3.3.5-{old}.zip',f'{folder}-3.3.5-{new}.zip')
    toc=root/folder/(folder+'.toc'); content=toc.read_text(encoding='utf-8-sig')
    assert f'## Version: 9.3.4-335-{old}' in content
    toc.write_text(content.replace(f'## Version: 9.3.4-335-{old}',f'## Version: 9.3.4-335-{new}'),encoding='utf-8')
text=text.replace('HUD-test-0.25.zip','HUD-test-0.26.zip'); path.write_text(text,encoding='utf-8')
notes={
'EllesmereUIDataBars':'''0.2 fixes OnInitialize through the actual Lua 5.1 Lite dispatcher: xpcall
does not forward the self argument on this client, so initialization uses
the captured addon reference. Tests now dispatch ADDON_LOADED/PLAYER_LOGIN
through the real Core rather than invoking lifecycle methods directly.''',
'EllesmereUIBags':'''0.7 records each character's gold independently of bag capacity in the
EUI-owned account SavedVariables cache. Saved bag views display that alt's
balance; hover the footer for individual balances, realm total and combined
total. Offline balances are the last recorded values, not live server data.
Broker tooltips include the same totals. Item subclasses are cached with
snapshots. Categories now include Crafting Reagents (Trade Goods/Reagents),
Food & Drink, Potions, Flasks & Elixirs, and Other Consumables. Item Category
filters the view without changing physical slots or moving items. Localized
class/subclass names are resolved from native cached item information.''',
'EllesmereUIBlizzardSkin':'''0.5 keeps native inbox/send/open mail quantity text above skinned item
icons, without replacing stack values, click/drag handlers or native empty
count visibility. It restores original layers and colors when disabled.
Quest/gossip parchment colors, including dark inline color codes, are made
legible on dark backgrounds; refresh hooks repair native repainting. Native
actions and high contrast quest colors remain intact.''',
'EllesmereUIRaidFrames':'''0.3 defaults existing/new profiles to Tank > Healer > DPS sorting inside
each raid subgroup and in the party. Unknown roles remain last; the module
does not infer healers from class. Both native Boolean and string role APIs
are supported, with native main-tank assignment fallback. Member Sorting
can still use Name or Roster Order. Hide DPS Role Icons hides only their
icons, keeping DPS frames visible; tank/healer icons follow Role Icons.
Role ordering uses Wrath secure header nameList order and updates outside
combat. Role/name/roster changes to those lists wait until combat ends;
new names/subgroup changes can therefore wait for that refresh. Roster/Name
sorting retains native automatic membership updates in combat.

Buffs and Debuffs now have separate pages with group/layout selection and
independent icon indicators: selector, add/remove/rename/enable, assigned
spell IDs, filter/own-only, raid/party display, custom spell order, anchor,
growth/offsets, icon limit, size/spacing/opacity/border, swipe/duration text,
stacks and hide-icon controls. Each aura type shares eight preallocated
icons across up to eight indicators per frame; the UI enforces that budget.
Global aura exclusions/filters apply before indicator selection. The existing
Aura Filters page remains available. Settings are separate per raid layout
and party, and protected layout changes defer until combat ends.''',
'EllesmereUIOptions':'''0.31 adds the Bags category selector/gold hint and raid role order/DPS
icon controls. Raid Frames includes independent Buffs/Debuffs indicator
pages alongside its existing shared Aura Filters and Click Casting pages.'''}
for folder,entry in notes.items():
    path=root/folder/'README-335.md'; text=path.read_text(encoding='utf-8-sig'); lines=text.splitlines()
    lines[0]=lines[0].rsplit(' — ',1)[0]+' — '+changes[folder][1]
    path.write_text(lines[0]+'\n\n'+entry+'\n\n'+'\n'.join(lines[2:])+'\n',encoding='utf-8')
entry='''Latest build: HUD-test-0.26. DataBars 0.2 / Bags 0.7 / BlizzardSkin 0.5 /
RaidFrames 0.3 / Options 0.31; other versions unchanged.

DataBars initialization uses the captured addon reference with Lua 5.1
xpcall. The regression now runs the real Core loading/login dispatcher.
Mail quantities remain above skinned icons; dark quest/gossip text and
inline colors remain readable, including after native refresh. Actions,
empty counts and original appearance restoration are preserved.

Bags owns alt gold snapshots even when inventory is not yet ready. Saved
bags show the character balance; footer/broker hover includes each alt,
realm total and combined total, explicitly last recorded for offline alts.
Cached item subclasses support Crafting Reagents, Food & Drink, Potions,
Flasks & Elixirs and Other Consumables plus a view-only category filter.

Raid/party defaults to Tank > Healer > DPS within each subgroup. Hide DPS
Role Icons keeps all player frames visible. Role/name lists update outside
combat; membership changes in this sorting mode can wait until combat ends.
Unknown roles sort last. Name/Roster sorting remains selectable. Separate
Buffs/Debuffs pages offer independent indicators and filters, spell lists,
custom order, show-in raid/party, anchors/growth/offsets, sizes, opacity,
borders, duration swipe/text, stack counts and hide-icon options. Eight
preallocated icons per aura type are shared across indicators. Existing
group/layout profiles, aura filters and click casting are retained.

Validated: actual lifecycle, serialized SavedVariables across three
character/realm sessions, gold updates/tooltip/categories, native mail
stack layers/actions/restore, quest colors including inline codes,
secure header role ordering, icon hiding only, independent indicator
filters/options/render state, combat deferral and existing module checks.
215 Lua 5.1 files compile. Thirteen addon folders/fourteen release ZIPs
are current. Rendering and taint still require client confirmation.

Previous checkpoint: HUD-test-0.25.'''
for filename in ['CODEX_HANDOFF_EllesmereUI_335_CURRENT.md','ELLESMEREUI_335_BACKPORT_STATUS.md']:
    path=root/filename; text=path.read_text(encoding='utf-8-sig')
    old='Latest build: HUD-test-0.25.'; assert old in text
    text=text.replace(old,entry+'\n\nHUD-test-0.25.',1)
    for folder,(old,new) in changes.items(): text=text.replace(f'| {folder} | 9.3.4-335-{old} |',f'| {folder} | 9.3.4-335-{new} |')
    text=text.replace('Full build: EllesmereUI-3.3.5-HUD-test-0.25.zip','Full build: EllesmereUI-3.3.5-HUD-test-0.26.zip')
    path.write_text(text,encoding='utf-8')
path=root/'ELLESMEREUI_PROJECT_PACK.md'; text=path.read_text(encoding='utf-8-sig')
start=text.index('Saved checkpoint:'); end=text.index('This project pack contains')
text=text[:start]+'''Saved checkpoint: 1 October 2026. Build 0.26 fixes DataBars loading,
mail quantities and quest contrast; records alt gold with combined tooltip;
adds crafting/consumable bag categories and raid/party role sorting with
DPS icon hiding. Buffs/Debuffs have independent configurable indicators.
Automated checks passed; client rendering/taint confirmation is pending.
See module READMEs for role sorting combat behavior and icon budgets.

'''+text[end:]
text=text.replace('build 0.25','build 0.26').replace('HUD-test-0.25.zip','HUD-test-0.26.zip'); path.write_text(text,encoding='utf-8')
print('PASS: build 0.26 TOCs, package versions and handoff/project documentation updated.')
