"""One-time checkpoint 0.30: healer indicator editor, previews, personal/externals."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
changes={'EllesmereUI':('3.3.5-core-0.24','3.3.5-core-0.25'),
         'EllesmereUIOptions':('9.3.4-335-0.34','9.3.4-335-0.35'),
         'EllesmereUIUnitFrames':('9.3.4-335-0.7','9.3.4-335-0.8'),
         'EllesmereUIRaidFrames':('9.3.4-335-0.3','9.3.4-335-0.4')}
path=root/'backport-tools/package_unitframes.py'; text=path.read_text(encoding='utf-8-sig')
for folder,(old,new) in changes.items():
    before=f"'{folder}':'{old}'"; assert before in text; text=text.replace(before,f"'{folder}':'{new}'")
    toc=root/folder/(folder+'.toc'); content=toc.read_text(encoding='utf-8-sig'); assert '## Version: '+old in content
    toc.write_text(content.replace('## Version: '+old,'## Version: '+new),encoding='utf-8')
for old,new in {'EllesmereUI-3.3.5-core-0.24.zip':'EllesmereUI-3.3.5-core-0.25.zip',
                'EllesmereUIOptions-3.3.5-0.34.zip':'EllesmereUIOptions-3.3.5-0.35.zip',
                'EllesmereUIUnitFrames-3.3.5-0.7.zip':'EllesmereUIUnitFrames-3.3.5-0.8.zip',
                'EllesmereUIRaidFrames-3.3.5-0.3.zip':'EllesmereUIRaidFrames-3.3.5-0.4.zip',
                'EllesmereUI-3.3.5-HUD-test-0.29.zip':'EllesmereUI-3.3.5-HUD-test-0.30.zip'}.items():
    assert old in text; text=text.replace(old,new)
path.write_text(text,encoding='utf-8')
notes={
'EllesmereUI':'''0.25 adds EUI_AuraIndicators_335.lua: shared native aura indicator geometry,
Wrath healer/defensive/external spell catalogues, local-name rank matching,
assignment selection, icon/text/cooldown display and reusable unit-frame
pools. No other addon data or runtime dependency is consulted. Exclusions
and timed/stealable constraints override explicit assignments; assigned
externals can come from another caster despite the global Own filter.
Cooldown indicators display active aura duration, not other players'
unobservable spell cooldown availability.''',
'EllesmereUIOptions':'''0.35 adds a shared Buffs/Debuffs indicator editor and persistent header
preview for Raid Frames and Unit Frames. The non-secure preview shows spell
icons at their configured anchors, growth, offsets and sizes and refreshes
on every edit. Click preview icons or the indicator list to select one.
It scales the complete layout to fit without changing live sizes. Header
frames/icons/list entries are reused across page/cache refreshes.
Healing, personal defensive and external presets are provided; new manual
indicators start with empty spell lists. Other buffs require manual IDs.
Raid/party and 10/25/40 configurations remain independent. Unit Frames >
Buffs > Player > Use Indicator Layout enables the new player display;
disabling returns to existing aura rows. The same editor supports target,
focus, boss frames and Debuffs. Aura Filters retains global exclusions.
Options still preserve native CreateFrame and inert compatibility probes.''',
'EllesmereUIUnitFrames':'''0.8 adds pooled aura indicators attached to the frame's own health bar.
Enable Unit Frames > Buffs > Select Frame: Player > Use Indicator Layout.
The normal aura lane is hidden only while this per-frame/per-aura-type mode
is enabled; switching it off restores the existing row and settings.
Eight indicators icons per aura type are preallocated before combat.
Events scan only the affected unit; vehicle tokens, live tooltips, stacks,
duration text/swipes, expiration and instance-group scope are retained.
Player/target/focus/boss and buffs/debuffs store separate configurations.
Defaults show healer assignments, personal defensives and external active
effects; ordinary buffs are added manually. External Own Only starts off.''',
'EllesmereUIRaidFrames':'''0.4 uses shared geometry for native live aura icons and the options preview.
The old automatically-created broad Buff Icons default becomes explicit
healer assignments while retaining its visual settings. Named/manual or
custom-filter indicators are preserved. Personal defensive and external
presets occupy separate positions; other buffs are assigned manually.
Defaults use a 3+2+2 icon budget, with eight shared per aura type.
Externals accept other casters independently of global Own filtering;
per-indicator Own Only, exclusions and hard aura constraints still apply.
The preview follows the selected raid layout/party config, supports clickable
indicator selection and live position/growth/size/text/style changes.
Native secure roster/click casting, subgroup sorting and combat rules remain.'''}
for folder,entry in notes.items():
    path=root/folder/'README-335.md'; lines=path.read_text(encoding='utf-8-sig').splitlines()
    lines[0]=lines[0].rsplit(' — ',1)[0]+' — '+changes[folder][1].rsplit('-',1)[-1]
    path.write_text(lines[0]+'\n\n'+entry+'\n\n'+'\n'.join(lines[2:])+'\n',encoding='utf-8')
entry='''Latest build: HUD-test-0.30. Core 0.25 / Options 0.35 / UnitFrames 0.8 /
RaidFrames 0.4; other modules unchanged.

Buffs/Debuffs pages share a non-secure header preview and indicator editor
for Raid Frames and Unit Frames. Click a preview spell or indicator list
entry to edit it. Positions, growth, size, offsets, stacks, duration/swipe,
opacity, border and manual spell assignments refresh the preview in place.
The whole preview layout scales to fit its canvas; live icon sizes do not.

Default buff indicators are healer assignments, personal defensives and
external active effects (3+2+2 icons). Other buffs start empty and must be
added manually. An explicit Wrath-only catalogue matches rank variants by
native localized spell name, without importing another addon's filters or
saved data. Externals may come from other casters even with the global Own
filter; indicator Own Only and global exclusions/hard constraints apply.
These indicators show active effect durations, not remote cooldown readiness.

Unit Frames > Buffs > Select Frame: Player > Use Indicator Layout enables
the new player display and hides only its previous aura row. Disabling the
mode restores the old row/settings. Buff/debuff and player/target/focus/boss
settings remain independent. Sixteen plain icons are preallocated per
unit frame (eight per aura type); aura events/expiry reuse this pool.
Raid/party and 10/25/40 settings are independent. The old automatic broad
Buff Icons default migrates to healing, retaining its visual edits; named,
manual and custom-filter indicators are retained.

Validated: real raid/UF lifecycle and registration, shared editor/preview,
all nine anchors and four growth directions compared to live raid layout,
rank matching/exclusions, external any-caster, healing Own Only, manual-only
ordinary buffs, selected-layout isolation, live player pools/expiration,
no combat allocations, old-row restore, header reuse/input/native-factory
safety and 217 Lua 5.1 files. Native rendering still needs client review.

Previous checkpoint: HUD-test-0.29.'''
for filename in ['CODEX_HANDOFF_EllesmereUI_335_CURRENT.md','ELLESMEREUI_335_BACKPORT_STATUS.md']:
    path=root/filename; text=path.read_text(encoding='utf-8-sig'); assert 'Latest build: HUD-test-0.29.' in text
    text=text.replace('Latest build: HUD-test-0.29.',entry+'\n\nHUD-test-0.29.',1)
    for folder,(old,new) in changes.items(): text=text.replace(f'| {folder} | {old} |',f'| {folder} | {new} |')
    text=text.replace('Full build: EllesmereUI-3.3.5-HUD-test-0.29.zip','Full build: EllesmereUI-3.3.5-HUD-test-0.30.zip')
    path.write_text(text,encoding='utf-8')
path=root/'ELLESMEREUI_PROJECT_PACK.md'; text=path.read_text(encoding='utf-8-sig')
start=text.index('Saved checkpoint:'); end=text.index('This project pack contains')
text=text[:start]+'''Saved checkpoint: 1 October 2026. Build 0.30 adds the shared raid/unit-frame
indicator editor and live preview, healer buff defaults and separate personal
defensive/external effects. Other buffs are assigned manually. Enable the
new player display in Unit Frames > Buffs > Player > Use Indicator Layout.
Automated tests passed; review the positions and icons in the native client.

'''+text[end:]
text=text.replace('build 0.29','build 0.30').replace('HUD-test-0.29.zip','HUD-test-0.30.zip')
text+='\nconnect_indicator_editor.py is a completed one-time migration; do not rerun.\n'
path.write_text(text,encoding='utf-8')
print('PASS: 0.30 versions, runtime/option TOCs, package selection and checkpoint docs updated.')
