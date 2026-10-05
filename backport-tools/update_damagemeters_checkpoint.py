"""One-time 0.31 checkpoint: independent Wrath Damage Meters."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
toc=root/'EllesmereUIOptions/EllesmereUIOptions.toc'
text=toc.read_text(encoding='utf-8-sig'); assert '## Version: 9.3.4-335-0.35' in text
toc.write_text(text.replace('## Version: 9.3.4-335-0.35','## Version: 9.3.4-335-0.36'),encoding='utf-8')
p=root/'backport-tools/package_unitframes.py'; text=p.read_text(encoding='utf-8-sig')
assert "'EllesmereUIOptions':'9.3.4-335-0.35'" in text
text=text.replace("'EllesmereUIOptions':'9.3.4-335-0.35'","'EllesmereUIOptions':'9.3.4-335-0.36'")
text=text.replace("'EllesmereUIDataBars':'9.3.4-335-0.2'}","'EllesmereUIDataBars':'9.3.4-335-0.2','EllesmereUIDamageMeters':'9.3.4-335-0.1'}")
assert "'EllesmereUIDamageMeters':'9.3.4-335-0.1'" in text
text=text.replace('EllesmereUIOptions-3.3.5-0.35.zip','EllesmereUIOptions-3.3.5-0.36.zip')
text=text.replace("    'EllesmereUI-3.3.5-HUD-test-0.30.zip':list(versions),",
    "    'EllesmereUIDamageMeters-3.3.5-0.1.zip':['EllesmereUIDamageMeters'],\n    'EllesmereUI-3.3.5-HUD-test-0.31.zip':list(versions),")
assert 'HUD-test-0.31.zip' in text
p.write_text(text,encoding='utf-8')
note='''Latest build: HUD-test-0.31. Damage Meters 0.1 / Options 0.36;
Core 0.25 and all other modules unchanged.

EllesmereUIDamageMeters now runs its own Wrath CLEU collector and saved
history. The installed Details main addon was examined as a reference;
there were no separate installed Details plugins. No Details runtime,
libraries, globals, saved data or copied parser are used. Retail EUI
sources/media remain unloaded and unchanged. Native combat collection
replaces Retail C_DamageMeter, which is not available on stock 3.3.5.

Two default windows (damage/healing), up to four, support damage/DPS,
healing/HPS, overheal/received healing, incoming/enemy/friendly damage,
absorbs received, blocks/resists/misses/avoidance, deaths/recaps, interrupts,
dispels, casts, resurrections, CC breaks, distinct power gains, buff/debuff
uptime and native current-target threat. Header selects metric, footer
selects current/last, overall or one of up to 30 saved segments; menus and
rows scroll. Left click opens spells, right click targets. R previews a
report; only the explicit Send button sends paced chat messages.

Open /edm or the Damage Meters sidebar. Windows move by header drag or
Unlock Mode; profiles and per-window display/visibility settings apply.
Combat history is per-character EllesmereUIDamageMetersHistory, separate
from exported UI profiles. Save History controls logout persistence.
Clearing data requires confirmation and is blocked during combat.

Absorbs belong to the recipient: no guessed shield caster/healing credit.
Aura uptime sums observed target-seconds and does not claim a universal
percentage. Resource types stay separate. DPS/HPS use encounter duration,
which freezes during the end grace; active group combat keeps collecting.
Overall refresh merges summaries; spell/target breakdowns merge on demand.
Rows are preallocated; native frame factory, Escape and game menus remain
untouched. Report inputs do not autofocus and clear focus on hide.

Validated: actual Lua 5.1 Core lifecycle with Details absent, eight-field
CLEU/spells/pets/statistics, recaps, aura timing/reconciliation, segments/
overall/rates/frozen duration, history reload/retention/disable, threat,
options/profile rebind/unlock/window pooling and explicit report flow.
Native client appearance and actual encounter totals require review.

Previous checkpoint: HUD-test-0.30.

'''
for name in ['CODEX_HANDOFF_EllesmereUI_335_CURRENT.md','ELLESMEREUI_335_BACKPORT_STATUS.md']:
    p=root/name; text=p.read_text(encoding='utf-8-sig'); i=text.index('\n\n')+2
    p.write_text(text[:i]+note+text[i:],encoding='utf-8')
p=root/'EllesmereUIOptions/README-335.md'; text=p.read_text(encoding='utf-8-sig'); i=text.index('\n\n')+2
p.write_text(text[:i]+'''0.36 adds native Damage Meters Windows and Combat Data pages. Four windows,
metrics/history, size/fonts/position/visibility, own persistence, collection,
pet merge and explicit report preview/send use the new independent module.
The options builder retains the private frame adapter.

'''+text[i:],encoding='utf-8')
p=root/'ELLESMEREUI_PROJECT_PACK.md'; text=p.read_text(encoding='utf-8-sig')
text=text.replace('build 0.30','build 0.31').replace('HUD-test-0.30.zip','HUD-test-0.31.zip')
start=text.index('Saved checkpoint:'); end=text.index('This project pack contains')
text=text[:start]+'''Saved checkpoint: 1 October 2026. Build 0.31 adds independent Wrath Damage
Meters with expanded combat statistics, spell/target breakdowns, death
recaps, native threat, persistent per-character history and up to four
windows. Details does not have to be enabled. Native appearance and real
encounter totals still need client review.

'''+text[end:]
text=text.replace('thirteen','fourteen').replace('fourteen current release ZIPs','fifteen current release ZIPs')
p.write_text(text,encoding='utf-8')
print('PASS: 0.31 module/Options versions, package selection and checkpoint documentation saved.')
