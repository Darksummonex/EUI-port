"""One-time 0.37 checkpoint: Quickdraw hotkey capture in Options 0.42."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=root/'EllesmereUIOptions/EllesmereUIOptions.toc'
s=p.read_text(encoding='utf-8-sig'); assert '## Version: 9.3.4-335-0.41' in s
p.write_text(s.replace('## Version: 9.3.4-335-0.41','## Version: 9.3.4-335-0.42'),encoding='utf-8')
p=root/'backport-tools/package_unitframes.py'; s=p.read_text(encoding='utf-8-sig')
for old,new in [("'EllesmereUIOptions':'9.3.4-335-0.41'","'EllesmereUIOptions':'9.3.4-335-0.42'"),('Options-3.3.5-0.41.zip','Options-3.3.5-0.42.zip'),('HUD-test-0.36.zip','HUD-test-0.37.zip')]:
    assert old in s; s=s.replace(old,new)
p.write_text(s,encoding='utf-8')
note='''Latest build: HUD-test-0.37. Options 0.42. Core and all module versions
remain unchanged from 0.36; Quickdraw runtime remains 0.1.

Quickdraw Assign Key now opens a temporary hotkey capture dialog instead of
trying to bind a typed key string. It samples Ctrl/Alt/Shift on the first
non-modifier key press, shows the selected chord, and saves the binding when
that key is released. Bare modifiers and key repeats never become bindings.
Escape, Cancel/right-click, page teardown, closing Options, combat start,
focus transfer or a 20-second timeout always disable the dialog's keyboard
input and clear its event registration. Capture never uses keyboard propagation,
global Escape hooks or persistent keyboard handlers. Existing native binding
and secure Quickdraw hold/release behavior remains in place.

Lua 5.1 tests exercise actual capture scripts, modifier snapshots, repeat and
release handling, persistence, invalid bindings, ten Escape cycles, hide/page/
Options/combat/timeout/focus/cancel cleanup, and rearming after failure.
Quickdraw secure regressions, Options factory/focus and all active Lua compile
checks pass. Native in-game input and appearance still need client review.

Previous checkpoint: HUD-test-0.36.

'''
for filename in ['CODEX_HANDOFF_EllesmereUI_335_CURRENT.md','ELLESMEREUI_335_BACKPORT_STATUS.md']:
    p=root/filename; s=p.read_text(encoding='utf-8-sig'); i=s.index('\n\n')+2
    p.write_text(s[:i]+note+s[i:],encoding='utf-8')
p=root/'EllesmereUIOptions/README-335.md'; s=p.read_text(encoding='utf-8-sig'); i=s.index('\n\n')+2
p.write_text('# Options 3.3.5 — 0.42\n\n0.42 makes Quickdraw Assign Key capture the next pressed hotkey, with modifier\nsupport and keyboard cleanup on release/cancel/hide/combat/focus/timeout.\n\n'+s[i:],encoding='utf-8')
p=root/'EllesmereUIQuickdraw/README-335.md'; s=p.read_text(encoding='utf-8-sig')
needle='a holdable key in settings or the game\'s keybindings menu. Hold to open,'
assert needle in s
s=s.replace(needle,'a holdable key in settings or the game\'s keybindings menu. Assign Key opens\na capture dialog: press the desired key with Ctrl/Alt/Shift as needed, then\nrelease to save. Esc/Cancel closes without changing bindings; hiding the page,\nclosing Options, combat, focus transfer or a 20-second timeout releases capture.\nHold the assigned key to open,')
p.write_text(s,encoding='utf-8')
p=root/'ELLESMEREUI_PROJECT_PACK.md'; s=p.read_text(encoding='utf-8-sig')
s=s.replace('build 0.36','build 0.37').replace('HUD-test-0.36.zip','HUD-test-0.37.zip')
start=s.index('Saved checkpoint:'); end=s.index('\n\nThis project pack',start)
s=s[:start]+'''Saved checkpoint: 1 October 2026. Build 0.37 updates Options to 0.42 with
Quickdraw hotkey capture, modifier support and complete keyboard cleanup on
release/cancel/hide/combat/focus/timeout. The 0.36 modules remain included.
Automated Lua 5.1, secure palette and input lifecycle tests pass. Real client
keyboard input and appearance need in-game review.'''+s[end:]
p.write_text(s,encoding='utf-8')
print('Updated checkpoint 0.37; Options 0.42; all module runtime versions unchanged.')
