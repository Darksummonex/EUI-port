"""Build a lightweight standalone addon for one EUI module.

The standalone folder holds the module, its option page and a small shim
(backport-tools/standalone_src/<Module>_Standalone.lua) that stands in for the
Core: addon lifecycle, settings storage and a settings window of its own. No EUI
options panel, Unlock Mode or other Core code is shipped:

  EUIStandalone<Module>/   (the installed folder; contains "Standalone")

The source is rewritten the same way the Retail packager does it (see the notes in
EllesmereUI.lua, EllesmereUI_Profiles.lua and EllesmereUI_FirstInstall.lua):

  1. Interface\\AddOns paths to the bundled folders point at the standalone folder.
  2. The module folder name "EllesmereUI<Module>" becomes "EUIStandalone<Module>".
  3. Every other contiguous "EllesmereUI" becomes the core token
     "EUICoreStandalone<Module>" (own globals and SavedVariables, so the build
     never shares state with the full suite).  Inside string literals only a
     name-like use ("EllesmereUIDB", "EllesmereUI_Frame") is renamed; the rest
     ("EllesmereUI", "EllesmereUI: ...", "EllesmereUI Original") is display text
     or a theme key and is kept.
  4. Addon API lookups of the core ("EllesmereUI" addon name) point at the folder.

Usage:
  python build_standalone.py [--module DamageMeters] [--out DIR] [--zip]
"""
import argparse
import re
import shutil
import sys
import zipfile
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

MODULES = {
    'DamageMeters': {
        'title': 'Damage Meters',
        'options': ['EUI_DamageMeters_335_Options.lua'],
        'assets': ['Media_335'],
        # Bar textures live in Resource Bars; the build ships its own copy.
        'extra_assets': [('EllesmereUIResourceBars/Media/Textures_335', 'Textures_335')],
        'path_aliases': [('EllesmereUIResourceBars\\\\Media\\\\Textures_335\\\\', 'Textures_335\\\\')],
        # Core media the build needs: the meter font and the addon list icon.
        'core_media': ['fonts/Expressway.ttf', 'eg-logo.tga'],
        # LibSharedMedia fonts and bar textures. Versioned through LibStub, so
        # they load safely beside other copies.
        'libs': ['Libs\\LibStub\\LibStub.lua', 'Libs\\CallbackHandler-1.0\\CallbackHandler-1.0.lua',
                 'Libs\\LibSharedMedia-3.0\\LibSharedMedia-3.0.lua'],
        'slash': '/edm',
    },
}

SHIM_DIR = ROOT / 'backport-tools' / 'standalone_src'

TOKEN_WORD = 'EllesmereUI'
ADDON_APIS = ('GetAddOnMetadata', 'IsAddOnLoaded', 'GetAddOnInfo', 'LoadAddOn',
              'EnableAddOn', 'DisableAddOn', 'IsAddOnLoadOnDemand')


def toc_files(toc_path):
    out = []
    for line in toc_path.read_text(encoding='utf-8-sig').splitlines():
        s = line.strip()
        if s and not s.startswith('#'):
            out.append(s)
    return out


def toc_field(toc_path, field):
    for line in toc_path.read_text(encoding='utf-8-sig').splitlines():
        if line.startswith('## %s:' % field):
            return line.split(':', 1)[1].strip()
    return None


def string_spans(src):
    """(start, end) of the CONTENT of every Lua string literal (short and long)."""
    spans, i, n = [], 0, len(src)
    long_open = re.compile(r'\[(=*)\[')
    while i < n:
        c = src[i]
        if c == '-' and src.startswith('--', i):
            m = long_open.match(src, i + 2)
            if m:
                close = ']' + m.group(1) + ']'
                j = src.find(close, m.end())
                i = n if j < 0 else j + len(close)
            else:
                j = src.find('\n', i)
                i = n if j < 0 else j + 1
            continue
        if c in '"\'':
            j = i + 1
            while j < n and src[j] != c:
                if src[j] == '\\':
                    j += 1
                elif src[j] == '\n':
                    break
                j += 1
            spans.append((i + 1, j))
            i = j + 1
            continue
        if c == '[':
            m = long_open.match(src, i)
            if m:
                close = ']' + m.group(1) + ']'
                j = src.find(close, m.end())
                j = n if j < 0 else j
                spans.append((m.end(), j))
                i = j + len(close)
                continue
        i += 1
    return spans


def transform(src, module, folder, token, aliases):
    # 1. AddOns paths into the bundled folders.
    for sep in ('\\\\', '\\', '/'):
        for name in ('EllesmereUI' + module, 'EllesmereUIOptions', 'EllesmereUI'):
            src = src.replace('AddOns' + sep + name + sep, 'AddOns' + sep + folder + sep)
    for old, new in aliases:
        src = src.replace('AddOns\\\\' + old, 'AddOns\\\\' + folder + '\\\\' + new)
    # 2. The module folder.
    src = src.replace('EllesmereUI' + module, folder)
    # 3. The core token, keeping display text inside strings.
    spans = string_spans(src)
    out, last, si = [], 0, 0
    for m in re.finditer(TOKEN_WORD, src):
        pos = m.start()
        while si < len(spans) and spans[si][1] <= pos:
            si += 1
        in_str = si < len(spans) and spans[si][0] <= pos < spans[si][1]
        if in_str:
            s, e = spans[si]
            nxt = src[m.end()] if m.end() < e else ''
            if not (nxt.isalnum() or nxt == '_'):
                continue
        out.append(src[last:pos])
        out.append(token)
        last = m.end()
    out.append(src[last:])
    src = ''.join(out)
    # 4. Addon lookups of the core name. A bare "EllesmereUI" string is otherwise
    #    display text or a theme key and stays readable.
    for api in ADDON_APIS:
        src = re.sub(r'(%s\s*\(\s*)(["\'])%s\2' % (api, TOKEN_WORD), r'\1\2%s\2' % folder, src)
    return src


GUARD = '''-- Generated by backport-tools/build_standalone.py. With the full suite enabled the
-- standalone stays inert: every bundled file returns on its first line, so the two
-- cores never both apply UI scale, fonts or frame layouts.
-- The bundled LibSharedMedia checks paths through C_UIFileAsset (same shim as the
-- suite's EllesmereUI_3.3.5_Compat.lua; this folder loads before the suite).
if not C_UIFileAsset then C_UIFileAsset = {} end
if not C_UIFileAsset.IsKnownFile then
    C_UIFileAsset.IsKnownFile = function(path) return type(path) == "string" and path ~= "" end
end
local _, _, _, enabled = GetAddOnInfo("Ellesmere" .. "UI")
if not enabled then return end
%(flag)s = true
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    DEFAULT_CHAT_FRAME:AddMessage("|cff0cd29fEllesmereUI %(title)s (Standalone):|r inactive because the full EllesmereUI is enabled. Use the suite's %(title)s, or disable the suite for this character.")
end)
'''
INERT_LINE = 'if %s then return end '


def add_inert_check(src, flag):
    """Prefix the first line, keeping line numbers (and a UTF-8 BOM) intact."""
    bom = '\xef\xbb\xbf' if src.startswith('\xef\xbb\xbf') else ''
    return bom + (INERT_LINE % flag) + src[len(bom):]


def build(module, out_dir):
    cfg = MODULES[module]
    folder = 'EUIStandalone' + module
    token = 'EUICoreStandalone' + module
    flag = folder + '_Inert'
    core, opts, mod = ROOT / 'EllesmereUI', ROOT / 'EllesmereUIOptions', ROOT / ('EllesmereUI' + module)
    dest = Path(out_dir).resolve() / folder
    if dest.exists():
        assert dest.name == folder and dest.parent.exists()
        shutil.rmtree(dest)
    dest.mkdir(parents=True)

    mod_toc = mod / ('EllesmereUI%s.toc' % module)
    mod_files = toc_files(mod_toc)
    shim = '%s_Standalone.lua' % module
    load = []

    def emit(src_dir, rel):
        src_path = src_dir / rel.replace('\\', '/')
        target = dest / rel.replace('\\', '/')
        target.parent.mkdir(parents=True, exist_ok=True)
        raw = src_path.read_bytes()
        if rel.lower().endswith('.lua') and not rel.lower().startswith('libs'):
            text = transform(raw.decode('latin-1'), module, folder, token, cfg['path_aliases'])
            raw = add_inert_check(text, flag).encode('latin-1')
        target.write_bytes(raw)
        load.append(rel)

    (dest / 'Standalone_Guard.lua').write_bytes((GUARD % {'flag': flag, 'title': cfg['title']}).encode('utf-8'))
    load.append('Standalone_Guard.lua')
    for rel in cfg['libs']:
        emit(core, rel)
    emit(SHIM_DIR, shim)
    for rel in mod_files:
        emit(mod, rel)
    for rel in cfg['options']:
        emit(opts, rel)

    for rel in cfg['core_media']:
        target = dest / 'media' / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(core / 'media' / rel, target)
    for name in cfg['assets']:
        shutil.copytree(mod / name, dest / name)
    for src_rel, dst_rel in cfg['extra_assets']:
        shutil.copytree(ROOT / src_rel, dest / dst_rel)

    version = toc_field(mod_toc, 'Version')
    release = toc_field(core / 'EllesmereUI.toc', 'X-EUI-Release')
    sv = [v.strip().replace('EllesmereUI' + module, folder)
          for v in (toc_field(mod_toc, 'SavedVariables') or '').split(',') if v.strip()]
    svc = [v.strip().replace('EllesmereUI' + module, folder)
           for v in (toc_field(mod_toc, 'SavedVariablesPerCharacter') or '').split(',') if v.strip()]
    lines = [
        '## Interface: 30300',
        '## Title: |cff0cd29fEllesmereUI|r %s |cff888888(Standalone)|r' % cfg['title'],
        '## Notes: EllesmereUI %s for WoW 3.3.5a without the rest of the suite. Settings: %s' % (cfg['title'], cfg['slash']),
        '## Author: Ellesmere / 3.3.5 backport',
        '## Version: %s-standalone' % version,
        '## X-EUI-Release: %s' % release,
        '## SavedVariables: %s' % ', '.join(sv),
    ]
    if svc:
        lines.append('## SavedVariablesPerCharacter: %s' % ', '.join(svc))
    lines.append('## IconTexture: Interface\\AddOns\\%s\\media\\eg-logo.tga' % folder)
    lines.append('')
    lines += load
    (dest / (folder + '.toc')).write_bytes(('\r\n'.join(lines) + '\r\n').encode('utf-8'))
    return dest


def make_zip(dest):
    stamp = datetime.now().strftime('%Y%m%d-%H%M')
    zpath = ROOT / ('EllesmereUI-3.3.5-%s-%s.zip' % (dest.name, stamp))
    with zipfile.ZipFile(zpath, 'w', zipfile.ZIP_DEFLATED) as z:
        for p in sorted(dest.rglob('*')):
            if p.is_file():
                z.write(p, Path(dest.name) / p.relative_to(dest))
    return zpath


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--module', default='DamageMeters', choices=sorted(MODULES))
    ap.add_argument('--out', default=str(ROOT / 'standalone'))
    ap.add_argument('--zip', action='store_true')
    args = ap.parse_args()
    dest = build(args.module, args.out)
    files = [p for p in dest.rglob('*') if p.is_file()]
    print('%s | %d files, %.1f MB' % (dest, len(files), sum(p.stat().st_size for p in files) / 1048576))
    if args.zip:
        print(make_zip(dest))


if __name__ == '__main__':
    sys.exit(main())
