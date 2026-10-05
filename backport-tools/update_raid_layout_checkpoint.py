from pathlib import Path

root = Path(__file__).resolve().parents[1]
package = root / 'backport-tools/package_unitframes.py'
s = package.read_text(encoding='utf-8-sig')
for old, new in [
    ("'EllesmereUIOptions':'9.3.4-335-0.25'", "'EllesmereUIOptions':'9.3.4-335-0.26'"),
    ("'EllesmereUIRaidFrames':'9.3.4-335-0.1'", "'EllesmereUIRaidFrames':'9.3.4-335-0.2'"),
    ('EllesmereUIOptions-3.3.5-0.25.zip', 'EllesmereUIOptions-3.3.5-0.26.zip'),
    ('EllesmereUIRaidFrames-3.3.5-0.1.zip', 'EllesmereUIRaidFrames-3.3.5-0.2.zip'),
    ('EllesmereUI-3.3.5-HUD-test-0.18.zip', 'EllesmereUI-3.3.5-HUD-test-0.19.zip')
]:
    assert s.count(old) == 1, old
    s = s.replace(old, new)
package.write_text(s, encoding='utf-8')

entry = '''Latest build: HUD-test-0.19. Core 0.23 / Options 0.26 / Raid Frames 0.2.
Other module versions are unchanged.

Raid Frames now saves independent 10-, 25- and 40-player layouts, including
dimensions, appearance, aura/filter settings and Unlock positions. Raid >
RAID LAYOUTS separates Use Raid Layout (Automatic or forced size) from Edit
Raid Layout (which size to configure). Automatic chooses native instance
capacity first, otherwise roster size; outside raids it uses 40. Nonsecure
preview outside a raid follows the edited size. Global Fonts, Textures and
Aura Filters also expose the layout selector. Migration copies the previous
raid settings, filter tables and position independently to all three layouts.
The old raid table remains a migration source, not the live runtime profile.

Show Group 1–2 / 1–5 / 1–8 toggles hide individual subgroups per layout.
Remaining headers pack without gaps and preserve their native groupFilter
and group labels. Group Limit still caps the last subgroup; showing a group
raises that limit as needed. All hidden means the raid holder and mover hide.
Native roster assignment remains with secure headers. Layout/visibility/size
switches during combat defer until PLAYER_REGEN_ENABLED. Roster/zone events
and the existing native poll detect automatic layout changes.

Validation: actual Lua 5.1 runtime/options tests cover 10/25/40 thresholds,
underfilled instance capacity, manual override, hidden-group compaction and
all-hidden state, combat roster/visibility deferral, legacy migration without
shared filter tables, separate positions, inactive-layout editing, preview,
and Global Fonts/Textures/filter isolation. All 191 Lua sources compile;
UnitFrames, nameplate GUID/channel/aura filters and Bags/Resource Bars shared
option regressions pass. Thirteen current archives are checked against the
installed source and recorded in the SHA-256 manifest. In-game secure behavior
and appearance still require client confirmation. Older archives retained.

Previous checkpoint: HUD-test-0.18. Core 0.23 / Options 0.25 / Raid Frames 0.1.
'''
for filename in ['CODEX_HANDOFF_EllesmereUI_335_CURRENT.md', 'ELLESMEREUI_335_BACKPORT_STATUS.md']:
    p = root / filename
    s = p.read_text(encoding='utf-8-sig')
    old = 'Latest build: HUD-test-0.18. Core 0.23 / Options 0.25 / Raid Frames 0.1.\n'
    assert s.count(old) == 1, filename
    s = s.replace(old, entry, 1)
    if filename.startswith('CODEX_HANDOFF'):
        s = s.replace('| EllesmereUIOptions | 9.3.4-335-0.25 |', '| EllesmereUIOptions | 9.3.4-335-0.26 |')
        s = s.replace('| EllesmereUIRaidFrames | 9.3.4-335-0.1 |', '| EllesmereUIRaidFrames | 9.3.4-335-0.2 |')
        s = s.replace('Full build: EllesmereUI-3.3.5-HUD-test-0.18.zip.', 'Full build: EllesmereUI-3.3.5-HUD-test-0.19.zip.')
    p.write_text(s, encoding='utf-8')
print('PASS: Raid layout versions and checkpoint documentation updated')
