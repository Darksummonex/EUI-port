"""One-time checkpoint 0.29: embedded glyph sheet and inert widget probes."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
changes={'EllesmereUIOptions':('9.3.4-335-0.33','9.3.4-335-0.34'),
         'EllesmereUIBlizzardSkin':('9.3.4-335-0.5','9.3.4-335-0.6')}
path=root/'backport-tools/package_unitframes.py'
text=path.read_text(encoding='utf-8-sig')
for folder,(old,new) in changes.items():
    before=f"'{folder}':'{old}'"; assert before in text
    text=text.replace(before,f"'{folder}':'{new}'")
    toc=root/folder/(folder+'.toc'); content=toc.read_text(encoding='utf-8-sig')
    assert '## Version: '+old in content
    toc.write_text(content.replace('## Version: '+old,'## Version: '+new),encoding='utf-8')
for old,new in {'EllesmereUIOptions-3.3.5-0.33.zip':'EllesmereUIOptions-3.3.5-0.34.zip',
                'EllesmereUIBlizzardSkin-3.3.5-0.5.zip':'EllesmereUIBlizzardSkin-3.3.5-0.6.zip',
                'EllesmereUI-3.3.5-HUD-test-0.28.zip':'EllesmereUI-3.3.5-HUD-test-0.29.zip'}.items():
    assert old in text; text=text.replace(old,new)
path.write_text(text,encoding='utf-8')
notes={
'EllesmereUIOptions':'''0.34 keeps all widget compatibility probes under a hidden, mouse/keyboard
disabled parent. Each probe is hidden and input disabled; the EditBox uses
the private factory with autofocus off and explicit ClearFocus. Build 0.28
preserved native CreateFrame but accidentally created its EditBox probe
with native default autofocus, allowing it to steal gameplay keyboard input
after other windows closed with Escape. Native CreateFrame and native
window inputs remain untouched. Search inputs retain click-to-focus.''',
'EllesmereUIBlizzardSkin':'''0.6 treats GlyphFrame as an elevated content sheet inside PlayerTalentFrame.
The glyph fill occupies only the body (TOPLEFT 16/-58, BOTTOMRIGHT -45/72),
leaving the shared portrait/header, close button and footer tabs visible.
There is no second glyph accent/header border. Talent-only title, scroll,
points, status, preview and activation controls hide while glyphs are shown;
previously shown controls restore on leaving/disable, and inactive controls
remain hidden. Native glyph sockets, glyph/ring textures, click/tooltip and
OnShow/OnHide scripts are retained. Skin writes defer until out of combat.
No external addon dependency or data is used.
Native Wrath structure reviewed:
https://github.com/wowgaming/3.3.5-interface-files/blob/main/Blizzard_GlyphUI/Blizzard_GlyphUI.xml'''}
for folder,entry in notes.items():
    path=root/folder/'README-335.md'; lines=path.read_text(encoding='utf-8-sig').splitlines()
    lines[0]=lines[0].rsplit(' — ',1)[0]+' — '+changes[folder][1].rsplit('-',1)[-1]
    path.write_text(lines[0]+'\n\n'+entry+'\n\n'+'\n'.join(lines[2:])+'\n',encoding='utf-8')
entry='''Latest build: HUD-test-0.29. Options 0.34 / BlizzardSkin 0.6;
Core 0.24 / Minimap 0.3 and all other modules unchanged.

User confirmed the 0.28 blocked-action warning was fixed, then reported
keyboard input locking after repeated Escape closes. The compatibility
EditBox probe had native autofocus after the global factory removal. All
probe widgets now live under a hidden input-disabled parent, are themselves
hidden/input-disabled, and the EditBox explicitly disables autofocus and
clears focus. Native frame creation remains unchanged; EUI search fields
retain click-to-focus and normal typing.

Glyphs no longer paint a second full-window panel over talents. The higher
glyph sheet fill is bounded to the body and has no duplicate accent/header;
shared tabs, portrait and close button remain visible. Talent-only content
is hidden while glyphs are active and its prior visibility restored when
leaving or disabling the skin. Native glyph socket art/clicks/tooltips and
native show/hide handlers remain intact. Combat defers skin writes.

Validated: probe visibility/focus/input across show/hide cycles, native
CreateFrame identity, actual search/widget behavior, six glyph sockets and
repeated talent/glyph switching, footer/body bounds, native callbacks,
inactive control restoration, skin disable/combat deferral/frame reuse,
existing currency/LFD/mail/quest/character skins and 215 Lua 5.1 files.
Client rendering and repeated Escape/input flow still need confirmation.

Previous checkpoint: HUD-test-0.28.'''
for filename in ['CODEX_HANDOFF_EllesmereUI_335_CURRENT.md','ELLESMEREUI_335_BACKPORT_STATUS.md']:
    path=root/filename; text=path.read_text(encoding='utf-8-sig')
    assert 'Latest build: HUD-test-0.28.' in text
    text=text.replace('Latest build: HUD-test-0.28.',entry+'\n\nHUD-test-0.28.',1)
    for folder,(old,new) in changes.items(): text=text.replace(f'| {folder} | {old} |',f'| {folder} | {new} |')
    text=text.replace('Full build: EllesmereUI-3.3.5-HUD-test-0.28.zip','Full build: EllesmereUI-3.3.5-HUD-test-0.29.zip')
    path.write_text(text,encoding='utf-8')
path=root/'ELLESMEREUI_PROJECT_PACK.md'; text=path.read_text(encoding='utf-8-sig')
start=text.index('Saved checkpoint:'); end=text.index('This project pack contains')
text=text[:start]+'''Saved checkpoint: 1 October 2026. Build 0.29 confines the glyph background
to the talent window body and makes all compatibility probes invisible and
input disabled. It fixes the autofocus probe regression after 0.28 removed
the global frame factory. Tests passed; repeat talent/glyph switching and
Escape closes in the client to confirm rendering and keyboard behavior.

'''+text[end:]
text=text.replace('build 0.28','build 0.29').replace('HUD-test-0.28.zip','HUD-test-0.29.zip')
path.write_text(text,encoding='utf-8')
print('PASS: 0.29 versions, package selection and checkpoint docs updated.')
