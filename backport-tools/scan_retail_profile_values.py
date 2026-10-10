"""One-off: for every string value in the decoded Retail profile
(.codex-backups/profile-strings/retail.json, written by compare_profile_strings.py),
report the ones that never appear as a quoted literal in the port module's loaded Lua
files or its options file. Those are the Retail-only choices a port import must not keep."""
import json
import pathlib
import re

root = pathlib.Path(__file__).resolve().parent.parent
data = json.loads((root / '.codex-backups/profile-strings/retail.json').read_text(encoding='utf-8'))['data']

def module_sources(folder):
    d = root / folder
    if not d.is_dir():
        return None
    toc = (d / (folder + '.toc')).read_text(encoding='utf-8-sig').splitlines()
    files = [d / l.strip().replace('\\', '/') for l in toc if l.strip().endswith('.lua') and not l.startswith('#')]
    short = folder.replace('EllesmereUI', '')
    files += list((root / 'EllesmereUIOptions').glob('EUI_%s*_Options.lua' % short))
    files += [root / 'EllesmereUI/EllesmereUI.lua', root / 'EllesmereUI/EllesmereUI_Fonts.lua']
    return '\n'.join(f.read_text(encoding='utf-8-sig', errors='replace') for f in files if f.exists())

FREE_TEXT = re.compile(r'(name|text|label|title|hex|key|macro|filter|zones?)$', re.I)

def walk(path, v, src, out):
    if isinstance(v, dict):
        for k, x in v.items():
            walk(path + '.' + k, x, src, out)
    elif isinstance(v, str) and v:
        last = path.rsplit('.', 1)[-1]
        if v.startswith('sm:') or FREE_TEXT.search(last):
            return
        if ('"%s"' % v) not in src and ("'%s'" % v) not in src:
            out.append('%s = %r' % (path, v))

for folder, blob in sorted(data['addons'].items()):
    src = module_sources(folder)
    if src is None:
        print('==', folder, 'no port module')
        continue
    out = []
    walk('', blob, src, out)
    print('== %s: %d unknown string values' % (folder, len(out)))
    for line in out:
        print('  ', line)
