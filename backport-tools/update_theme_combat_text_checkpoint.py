"""One-time 0.32 checkpoint: options theme refresh and native combat-text CVars."""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
for folder, old, new in [
    ('EllesmereUI', '3.3.5-core-0.25', '3.3.5-core-0.26'),
    ('EllesmereUIOptions', '9.3.4-335-0.36', '9.3.4-335-0.37'),
]:
    p = root / folder / (folder + '.toc')
    text = p.read_text(encoding='utf-8-sig')
    assert '## Version: ' + old in text
    p.write_text(text.replace('## Version: ' + old, '## Version: ' + new), encoding='utf-8')

p = root / 'backport-tools/package_unitframes.py'
text = p.read_text(encoding='utf-8-sig')
for old, new in [('3.3.5-core-0.25', '3.3.5-core-0.26'),
                 ('9.3.4-335-0.36', '9.3.4-335-0.37'),
                 ('EllesmereUIOptions-3.3.5-0.36.zip', 'EllesmereUIOptions-3.3.5-0.37.zip'),
                 ('HUD-test-0.31.zip', 'HUD-test-0.32.zip')]:
    assert old in text
    text = text.replace(old, new)
p.write_text(text, encoding='utf-8')

note = '''Latest build: HUD-test-0.32. Core 0.26 / Options 0.37;
all other modules unchanged.

Options theme changes now apply the selected background and menu accent
together. Wrath switches the background/collapse-box layers immediately,
hides the outgoing art and clears the Pixels overlay without relying on
a crossfade ticker under a hidden or collapsed panel. The live background
handle follows the selected layer. Retail retains its animated transition.
Match Accent to Theme still controls theme versus independent profile color.

General combat damage/healing toggles and the periodic/pet damage cog now
read/write stock Wrath CombatDamage, CombatHealing,
CombatLogPeriodicSpells, PetMeleeDamage and PetSpellDamage. Retail v2 names
remain used on Retail. Existing combat restrictions and safe handling of
unavailable CVars are preserved.

Validated in Lua 5.1: real theme API/menu colors, every native TGA path,
visible background/collapse layers, rapid hidden-panel selections, Pixels
overlay removal and Retail transition; actual combat-text row/cog callbacks
against strict native and Retail CVar sets; independent toggles, combat
guard and unavailable CVars. Unit Frames, private options factory and
search/focus regressions pass. Native appearance requires client review.

Previous checkpoint: HUD-test-0.31.

'''
for name in ['CODEX_HANDOFF_EllesmereUI_335_CURRENT.md', 'ELLESMEREUI_335_BACKPORT_STATUS.md']:
    p = root / name
    text = p.read_text(encoding='utf-8-sig')
    i = text.index('\n\n') + 2
    p.write_text(text[:i] + note + text[i:], encoding='utf-8')

for folder, title, note in [
    ('EllesmereUI', '# EllesmereUI Core — 3.3.5 — 0.26', '''0.26 applies theme background and registered menu colors together.
Wrath switches both art layers and the collapse box immediately, clears
outgoing Pixels overlays and keeps the live texture handle current even
when the panel is hidden. Theme matching and independent profile accents
remain selectable; Retail keeps its animated crossfade.

'''),
    ('EllesmereUIOptions', '# Options 3.3.5 — 0.37', '''0.37 maps General combat damage/healing, periodic damage and pet melee/
spell damage toggles to stock 3.3.5 CVars. The theme dropdown uses one
complete background/accent update through the core API. Existing combat
guards and safe unavailable-CVar handling remain in place.

'''),
]:
    p = root / folder / 'README-335.md'
    text = p.read_text(encoding='utf-8-sig')
    i = text.index('\n\n') + 2
    p.write_text(title + '\n\n' + note + text[i:], encoding='utf-8')

p = root / 'ELLESMEREUI_PROJECT_PACK.md'
text = p.read_text(encoding='utf-8-sig').replace('build 0.31', 'build 0.32').replace('HUD-test-0.31.zip', 'HUD-test-0.32.zip')
start, end = text.index('Saved checkpoint:'), text.index('This project pack contains')
text = text[:start] + '''Saved checkpoint: 1 October 2026. Build 0.32 fixes options theme background
and menu-color refresh, including hidden/collapsed windows, and maps General
damage/healing plus periodic/pet combat text to native Wrath settings.
Automated Lua 5.1 regressions pass; native appearance needs client review.

''' + text[end:]
p.write_text(text, encoding='utf-8')
print('PASS: 0.32 Core/Options versions, package selection and checkpoint documentation saved.')
