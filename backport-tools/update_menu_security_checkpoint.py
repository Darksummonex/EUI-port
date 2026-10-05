"""Record build 0.28 once after private options factory / native menu fixes."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
changes={'EllesmereUI':('3.3.5-core-0.23','3.3.5-core-0.24'),
         'EllesmereUIOptions':('9.3.4-335-0.32','9.3.4-335-0.33'),
         'EllesmereUIMinimap':('9.3.4-335-0.2','9.3.4-335-0.3')}
archives={'EllesmereUI-3.3.5-core-0.23.zip':'EllesmereUI-3.3.5-core-0.24.zip',
          'EllesmereUIOptions-3.3.5-0.32.zip':'EllesmereUIOptions-3.3.5-0.33.zip',
          'EllesmereUIMinimap-3.3.5-0.2.zip':'EllesmereUIMinimap-3.3.5-0.3.zip',
          'EllesmereUI-3.3.5-HUD-test-0.27.zip':'EllesmereUI-3.3.5-HUD-test-0.28.zip'}
path=root/'backport-tools/package_unitframes.py'; text=path.read_text(encoding='utf-8-sig')
for folder,(old,new) in changes.items():
    before=f"'{folder}':'{old}'"; assert before in text
    text=text.replace(before,f"'{folder}':'{new}'")
    toc=root/folder/(folder+'.toc'); content=toc.read_text(encoding='utf-8-sig')
    assert '## Version: '+old in content
    toc.write_text(content.replace('## Version: '+old,'## Version: '+new),encoding='utf-8')
for old,new in archives.items(): assert old in text; text=text.replace(old,new)
path.write_text(text,encoding='utf-8')
notes={
'EllesmereUI':'''0.24 routes options-panel and global-search frame creation through the
private EUI options factory when available, retaining the native factory
before options loads. EUI search/EditBox focus behavior remains scoped to
its controls. Blizzard's global CreateFrame is preserved.''',
'EllesmereUIOptions':'''0.33 removes the global CreateFrame replacement. Retail-only template
filtering and EditBox autofocus/OnHide cleanup now live in
EllesmereUI.CreateOptionsFrame, locally bound by the 18 active options
builders which create frames. UnitFrames retains its own Wrath adapter.
Native frames and other addons no longer enter the Options frame factory.
This addresses a taint source identified while investigating the blocked
action popup after closing windows opened by the minimap micro menu.
No global native API is restored/reassigned at runtime; a full client
restart is needed to clear taint from the previous loaded build.
Existing settings, search inputs, template filtering and callbacks remain.''',
'EllesmereUIMinimap':'''0.3 dispatches every native-window menu action through Wrath securecall.
Where available, the menu calls the original native toggle by name; it
otherwise invokes a native micro button through securecall. Native button
availability/disabled state, arguments, combat guard and dismissal remain.
This avoids carrying the menu callback context into native UIPanel state
which is later closed by Escape. No native window hide handler, Escape
binding or protected-action error handler is replaced or suppressed.
Source reviewed for the reported Spellbook close path:
https://github.com/wowgaming/3.3.5-interface-files/blob/main/SpellBookFrame.lua
https://github.com/wowgaming/3.3.5-interface-files/blob/main/UIParent.lua
Automated checks verify securecall dispatch for every menu route and native
CreateFrame identity preservation. Lua fixtures cannot prove native taint
behavior; repeat middle click > Spellbook/other windows > Escape in client.'''}
for folder,entry in notes.items():
    path=root/folder/'README-335.md'; text=path.read_text(encoding='utf-8-sig'); lines=text.splitlines()
    label=changes[folder][1].rsplit('-',1)[-1]
    if ' — ' in lines[0]: lines[0]=lines[0].rsplit(' — ',1)[0]+' — '+label
    path.write_text(lines[0]+'\n\n'+entry+'\n\n'+'\n'.join(lines[2:])+'\n',encoding='utf-8')
entry='''Latest build: HUD-test-0.28. Core 0.24 / Options 0.33 / Minimap 0.3;
other modules unchanged.

Reported trigger: middle-click minimap menu > Spellbook or another native
window > Escape produced an EllesmereUIOptions blocked-action popup.
Options globally replaced CreateFrame; that adapter is now private and
bound only inside 18 active EUI options builders. Panel/global search use
it locally; UnitFrames retains its private Wrath frame adapter. Native
CreateFrame stays unchanged after options loads, and native EditBoxes no
longer receive EUI autofocus/OnHide modifications.

All minimap menu actions now use securecall for native named toggles or
native micro-button clicks, preserving disabled state, arguments and OOC
guards. Native close handlers, Escape bindings and blocked-action reports
are retained. Restart clears the previous session's existing taint.

Validated: unchanged native factory identity, template filtering/private
focus cleanup, idempotent compatibility loading, active builder bindings,
secure menu routes, Spellbook open/close, existing search/options access,
widget setters and 215 Lua 5.1 compilation/UnitFrames regressions. Native
client taint confirmation is still required for the exact reported flow.

Previous checkpoint: HUD-test-0.27.'''
for filename in ['CODEX_HANDOFF_EllesmereUI_335_CURRENT.md','ELLESMEREUI_335_BACKPORT_STATUS.md']:
    path=root/filename; text=path.read_text(encoding='utf-8-sig')
    old='Latest build: HUD-test-0.27.'; assert old in text
    text=text.replace(old,entry+'\n\nHUD-test-0.27.',1)
    for folder,(old,new) in changes.items(): text=text.replace(f'| {folder} | {old} |',f'| {folder} | {new} |')
    text=text.replace('Full build: EllesmereUI-3.3.5-HUD-test-0.27.zip','Full build: EllesmereUI-3.3.5-HUD-test-0.28.zip')
    path.write_text(text,encoding='utf-8')
path=root/'ELLESMEREUI_PROJECT_PACK.md'; text=path.read_text(encoding='utf-8-sig')
start=text.index('Saved checkpoint:'); end=text.index('This project pack contains')
text=text[:start]+'''Saved checkpoint: 1 October 2026. Build 0.28 scopes the Options frame
factory to EUI controls and uses securecall for native minimap menu actions.
It addresses the blocked-action popup when native windows are closed with
Escape after opening through the micro menu. Automated checks passed;
native taint verification still requires repeating that exact client flow.

'''+text[end:]
text=text.replace('build 0.27','build 0.28').replace('HUD-test-0.27.zip','HUD-test-0.28.zip')
text=text.replace('do not rerun them on the already-updated checkpoint.',
                  'do not rerun them on the already-updated checkpoint. The scope_options_factory.py\nscript is also a completed one-time migration and must not be rerun.')
path.write_text(text,encoding='utf-8')
print('PASS: build 0.28 TOCs, package versions and handoff/project docs updated.')
