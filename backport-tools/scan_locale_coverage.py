"""Locale coverage: which EllesmereUILocales catalog keys (English text) still
appear in the 3.3.5 port's loaded Lua, which only exist in Retail, which are
unused even in Retail, and which port UI labels have no catalog entry.

Read only. Usage: python scan_locale_coverage.py [--out FILE]
"""
import argparse
import difflib
import re
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RETAIL = Path('D:/World of Warcraft/_retail_/Interface/AddOns')
CODES = ['deDE', 'esES', 'esMX', 'frFR', 'koKR', 'ruRU', 'zhCN', 'zhTW']
KEY_RE = re.compile(r'^\s*L\["((?:[^"\\]|\\.)*)"\]\s*=', re.M)
UI_FILES = re.compile(r'(Options|Widgets|Panel|UnlockMode|Popups|ManagerPages|Presets|StyleCards|SpecOverrides|'
                      r'Conditions|TalentConditions|FirstInstall|Profiles)', re.I)


def lua_strings(src):
    """Raw (still escaped) content of every short string literal outside comments."""
    out, i, n = [], 0, len(src)
    long_open = re.compile(r'\[(=*)\[')
    while i < n:
        c = src[i]
        if c == '-' and src.startswith('--', i):
            m = long_open.match(src, i + 2)
            if m:
                j = src.find(']' + m.group(1) + ']', m.end())
                i = n if j < 0 else j + len(m.group(1)) + 2
            else:
                j = src.find('\n', i)
                i = n if j < 0 else j + 1
            continue
        if c in '"\'':
            j = i + 1
            while j < n and src[j] != c and src[j] != '\n':
                j += 2 if src[j] == '\\' else 1
            s = src[i + 1:j]
            out.append(s if c == '"' else s.replace("\\'", "'").replace('"', '\\"'))
            i = j + 1
            continue
        if c == '[':
            m = long_open.match(src, i)
            if m:
                j = src.find(']' + m.group(1) + ']', m.end())
                i = n if j < 0 else j + len(m.group(1)) + 2
                continue
        i += 1
    return out


def load_list(folder, toc):
    files = []

    def add(path):
        if not path.is_file():
            return
        if path.suffix.lower() == '.lua':
            files.append(path)
        elif path.suffix.lower() == '.xml':
            text = path.read_text(encoding='utf-8-sig', errors='replace')
            for m in re.finditer(r'<(?:Script|Include)\s+file="([^"]+)"', text):
                add(path.parent / m.group(1).replace('\\', '/'))

    for line in toc.read_text(encoding='utf-8-sig', errors='replace').splitlines():
        s = line.strip()
        if s and not s.startswith('#'):
            add(folder / s.replace('\\', '/'))
    return files


def collect(base, locales_folder='EllesmereUILocales'):
    """{literal: set(relative files)} over every TOC-loaded Lua file."""
    found = defaultdict(set)
    for folder in sorted(base.glob('EllesmereUI*')):
        if not folder.is_dir() or folder.name == locales_folder:
            continue
        tocs = [t for t in folder.glob('*.toc')]
        main = [t for t in tocs if t.stem == folder.name] or tocs
        for toc in main:
            for path in load_list(folder, toc):
                rel = str(path.relative_to(base)).replace('\\', '/')
                for s in lua_strings(path.read_text(encoding='utf-8-sig', errors='replace')):
                    found[s].add(rel)
    return found


def catalog():
    keys = {}
    for code in CODES:
        text = (ROOT / 'EllesmereUILocales' / (code + '.lua')).read_text(encoding='utf-8-sig', errors='replace')
        for k in KEY_RE.findall(text):
            keys.setdefault(k, set()).add(code)
    return keys


def ui_like(s):
    if len(s) < 3 or not re.search(r'[A-Za-z]', s) or '\\\\' in s or '/' in s and ' ' not in s:
        return False
    if re.fullmatch(r'[A-Z0-9_]+', s) or re.fullmatch(r'[a-z][A-Za-z0-9_.]*', s):
        return False  # constants, keys, events, identifiers
    if s.startswith(('|T', 'Interface', 'sm:', 'lsm:')) or re.fullmatch(r'[%\-.\w$]+', s) and ' ' not in s and not s[0].isupper():
        return False
    if ' ' not in s and (re.search(r'[a-z][A-Z]|_|\\', s) or re.search(r'\.(ttf|tga|blp|png|lua|ogg|mp3)$', s, re.I)):
        return False  # CamelCase API/field names, frame names, file names
    return s[0].isupper() or s[0] in '(<'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default=str(Path.home() / 'AppData/Local/Temp/eui_locale_coverage.txt'))
    args = ap.parse_args()

    keys = catalog()
    port = collect(ROOT)
    retail = collect(RETAIL)
    port_lower = {s.lower(): s for s in port}

    used, retail_only, dead = [], [], []
    for k in sorted(keys):
        if k in port:
            used.append(k)
        elif k in retail:
            retail_only.append(k)
        else:
            dead.append(k)

    # Retail-only keys: reworded in the port (near match) vs feature/text not ported.
    port_ui = [s for s in port if ui_like(s)]
    reworded, missing = [], defaultdict(list)
    for k in retail_only:
        near = port_lower.get(k.lower())
        if near and not ui_like(near):
            near = None
        if not near:
            m = difflib.get_close_matches(k, port_ui, n=1, cutoff=0.88) if 6 <= len(k) <= 120 else []
            near = m[0] if m else None
        if near:
            reworded.append((k, near))
        else:
            src = sorted(retail[k])[0].split('/')[0]
            missing[src].append(k)

    # Port UI labels with no catalog entry (English on every locale).
    untranslated = defaultdict(list)
    for s, files in port.items():
        if s in keys or not ui_like(s):
            continue
        ui_files = [f for f in files if UI_FILES.search(f)]
        if ui_files:
            notes_only = all(f.endswith('EUI__General_Options.lua') for f in ui_files) and len(s) > 40
            group = 'Patch notes (EUI__General_Options.lua)' if notes_only else sorted(ui_files)[0].split('/')[-1]
            untranslated[group].append(s)

    per_locale = {c: sum(1 for k in used if c in keys[k]) for c in CODES}
    lines = []
    w = lines.append
    w('Catalog keys (all locales): %d' % len(keys))
    w('  used by the port:              %d' % len(used))
    w('  reworded in the port:          %d' % len(reworded))
    w('  Retail-only (not ported):      %d' % sum(len(v) for v in missing.values()))
    w('  unused even in Retail:         %d' % len(dead))
    w('Port UI labels without a key:    %d' % sum(len(v) for v in untranslated.values()))
    w('Used keys per locale: ' + ', '.join('%s %d' % (c, per_locale[c]) for c in CODES))
    w('')
    w('== Reworded (Retail key -> port text) ==')
    for k, near in reworded:
        w('  %r -> %r' % (k, near))
    w('')
    w('== Retail-only keys by Retail addon ==')
    for folder in sorted(missing):
        w('-- %s (%d)' % (folder, len(missing[folder])))
        for k in sorted(missing[folder]):
            w('  ' + k)
    w('')
    w('== Unused even in Retail (dynamic/concatenated or stale) ==')
    for k in dead:
        w('  ' + k)
    w('')
    w('== Port UI labels with no catalog entry, by addon ==')
    for folder in sorted(untranslated):
        w('-- %s (%d)' % (folder, len(untranslated[folder])))
        for s in sorted(untranslated[folder]):
            w('  ' + s)
    Path(args.out).write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines[:8]))
    print('-- Retail-only by addon: ' + ', '.join('%s %d' % (f, len(v)) for f, v in sorted(missing.items())))
    print('-- Untranslated port labels by addon: ' + ', '.join('%s %d' % (f, len(v)) for f, v in sorted(untranslated.items())))
    print('Report: ' + args.out)


if __name__ == '__main__':
    sys.exit(main())
