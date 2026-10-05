from pathlib import Path

root = Path(__file__).resolve().parents[1]
entry = '''Latest build: HUD-test-0.18. Core 0.23 / Options 0.25 / Raid Frames 0.1.
Other module versions are unchanged.

Raid Frames: native secure raid and party headers with 45 preallocated unit
buttons, separate layouts, class colors, health/power, range, threat, roles,
leader/raid markers, ready checks, vehicles and offline/dead/AFK status.
Native headers own membership and sorting; layout and click-binding edits
defer until combat ends. Aura icons follow each member independently of target
selection, retain click-through behavior and support native tooltips, timers,
stacks, dispellable rules and separate raid/party tracked/excluded ID filters.
Click casting is opt-in with modifiers and mouse buttons 1–5; default target
and native unit menu remain. Clique registration is available. Native party
frames preserve scripts/events and restore their original parent/positions
when the replacement is disabled. Other group addons and native raid pullouts
are not modified. Preview uses independent nonsecure buttons and does not
cover live groups. Unlock movers, central profiles, Global Fonts and Textures
use the live native settings. /erf and /rf open the four options pages.

Retail sources remain unchanged, unloaded. Converted roles/textures are
independent native TGA assets. Unsupported Retail private-aura, prediction,
portrait and advanced manager controls are not exposed. Other preset menus
remain available; the unsupported Retail raid style selector is omitted.

Validation: 191 Lua 5.1 sources compile. Actual native Raid Frames runtime and
options builders pass explicit Wrath contract tests for roster/subgroup/GUID
changes, aura ownership/removal/expiry, vehicles, secure combat deferral,
click bindings, range/status/ready checks, preview, native restoration,
profiles and movers. Shared UnitFrames, nameplate GUID/aura filters,
themes/presets, Bags/Resource Bars and QoL regression checks pass.
The contract fixture does not replace in-game native secure/rendering checks.
Current build contains twelve addon folders and thirteen archives including
the bundle; the current manifest verifies every ZIP member and SHA-256 hash.
Older archives remain after the prior approval-review deletion block.

Previous checkpoint: HUD-test-0.17. Core 0.23 / Options 0.24 / ActionBars 0.8 /
'''

for filename in ['CODEX_HANDOFF_EllesmereUI_335_CURRENT.md', 'ELLESMEREUI_335_BACKPORT_STATUS.md']:
    p = root / filename
    s = p.read_text(encoding='utf-8-sig')
    old = 'Latest build: HUD-test-0.17. Core 0.23 / Options 0.24 / ActionBars 0.8 /\n'
    assert s.count(old) == 1, filename
    s = s.replace(old, entry, 1)
    if filename.startswith('CODEX_HANDOFF'):
        s = s.replace('| EllesmereUIOptions | 9.3.4-335-0.24 |', '| EllesmereUIOptions | 9.3.4-335-0.25 |')
        s = s.replace('| EllesmereUIQoL | 9.3.4-335-0.1 |', '| EllesmereUIQoL | 9.3.4-335-0.1 |\n| EllesmereUIRaidFrames | 9.3.4-335-0.1 |')
        s = s.replace('Full build: EllesmereUI-3.3.5-HUD-test-0.17.zip. Keep it together with the eleven', 'Full build: EllesmereUI-3.3.5-HUD-test-0.18.zip. Keep it together with the twelve')
    p.write_text(s, encoding='utf-8')
print('PASS: Raid Frames checkpoint documentation updated')
