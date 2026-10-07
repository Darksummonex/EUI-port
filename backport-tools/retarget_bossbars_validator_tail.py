"""One-off: replace the EUI QoL tail of validate_abilitytimeline_bossbars.py (its old
Raid Tools option test) with checks that the feature now lives only in AbilityTimeline."""
from pathlib import Path

path = Path(__file__).resolve().parent / 'validate_abilitytimeline_bossbars.py'
data = path.read_bytes().decode('utf-8')
eol = '\r\n' if '\r\n' in data else '\n'
marker = '# 5) Options: Raid Tools > BOSS MOD BARS toggle with tooltip and live status.'
assert marker in data
tail = '''# 5) The feature lives in AbilityTimeline only; EUI QoL no longer hides the bars.
src = read('AbilityTimeline/BossBars.lua')
assert 'SetRotatesTexture' not in src and 'EllesmereUI' not in src
toc = read('AbilityTimeline/AbilityTimeline.toc')
assert 'Sources.lua\\nBossBars.lua\\nOptions.lua' in toc.replace('\\r\\n', '\\n')
assert not (root / 'EllesmereUIQoL' / 'EUI_QoL_335_BossBars.lua').exists()
assert 'BossBars' not in read('EllesmereUIQoL/EllesmereUIQoL.toc')
for rel in ['EllesmereUIQoL/EUI_QoL_335.lua', 'EllesmereUIOptions/EUI_QoL_335_Options.lua']:
    assert 'hideBossModBars' not in read(rel) and 'BossBars' not in read(rel), rel
print('PASS: with AbilityTimeline active, real DBT bars (existing, new, enlarged) go alpha 0 via their anchor and click-through '
      'while still counting down, expiring and feeding the timeline; BigWigs bars (message and LibCandyBar Start paths, '
      'on-demand load) park under a transparent holder that survives SetAlpha(1); late timeline load, source/timeline/Hide '
      'option toggles, combat, ClickThrough and Move Bars all restore correctly; DBT saved options untouched; both Hide options off leaves the bars alone.')
'''
data = data[:data.index(marker)] + tail.replace('\n', eol)
path.write_bytes(data.encode('utf-8'))
print('tail replaced')
