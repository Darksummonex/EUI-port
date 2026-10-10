"""One-off audit: settings a Retail profile could carry that the port reads differently.
Collects `key = value,` table fields (defaults) from the Retail install's module files
(read only) and from the port module's TOC-loaded files, then per key name reports:
  NUM  both numeric, every Retail/port pair 20x apart (percent vs multiplier etc.)
  TYPE Retail and port value kinds never overlap (bool vs number, number vs string)
  ENUM Retail string default never appears as a literal in the port module or options
The profile import only keeps a value whose key exists in the port with the same type,
so TYPE rows are already skipped; NUM and ENUM rows would be imported as-is."""
import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent.parent
retail_root = pathlib.Path('D:/World of Warcraft/_retail_/Interface/AddOns')
FIELD = re.compile(r'\b([A-Za-z_]\w*)\s*=\s*("(?:[^"\\\n]|\\.)*"|true|false|-?\d+(?:\.\d+)?)\s*[,}]')
MODULES = ['ActionBars', 'Arena', 'AuraBuffReminders', 'Bags', 'Chat', 'CooldownManager', 'DamageMeters',
           'DataBars', 'Friends', 'Minimap', 'Nameplates', 'QoL', 'QuestTracker', 'Quickdraw', 'RaidFrames',
           'ResourceBars', 'UnitFrames']
SKIP_KEYS = {'r', 'g', 'b', 'a', 'x', 'y', 'id', 'key', 'name', 'label', 'text', 'title', 'desc', 'order',
             'width', 'height', 'size', 'min', 'max', 'step', 'value', 'default', 'type', 'point', 'relPoint',
             'tooltip', 'icon', 'spellID', 'group', 'page', 'count', 'index', 'level', 'duration', 'offset'}


def read(paths):
    return '\n'.join(p.read_text(encoding='utf-8-sig', errors='replace') for p in paths if p.exists())


def fields(src):
    out = {}
    for k, v in FIELD.findall(src):
        if k in SKIP_KEYS or len(k) < 5:
            continue
        if v in ('true', 'false'):
            val = ('bool', v)
        elif v.startswith('"'):
            val = ('str', v[1:-1])
        else:
            val = ('num', float(v))
        out.setdefault(k, set()).add(val)
    return out


def port_files(folder):
    d = root / folder
    toc = (d / (folder + '.toc')).read_text(encoding='utf-8-sig').splitlines()
    return [d / l.strip().replace('\\', '/') for l in toc
            if l.strip().endswith('.lua') and not l.startswith('#') and 'Libs' not in l]


RATIO = float(sys.argv[1]) if len(sys.argv) > 1 else 20


def far(a, b):
    a, b = abs(a), abs(b)
    return a != 0 and b != 0 and (a / b >= RATIO or b / a >= RATIO)


report = []
for mod in MODULES:
    folder = 'EllesmereUI' + mod
    rdir = retail_root / folder
    if not rdir.is_dir() or not (root / folder).is_dir():
        continue
    rsrc = read([p for p in rdir.rglob('*.lua') if 'Libs' not in p.parts and 'Locales' not in p.parts])
    psrc = read(port_files(folder))
    opts = read(list((root / 'EllesmereUIOptions').glob('EUI_%s*_Options.lua' % mod)))
    rf, pf = fields(rsrc), fields(psrc)
    rows = []
    for k in sorted(set(rf) & set(pf)):
        rk = {t for t, _ in rf[k]}
        pk = {t for t, _ in pf[k]}
        rn = [v for t, v in rf[k] if t == 'num']
        pn = [v for t, v in pf[k] if t == 'num']
        if not (rk & pk):
            rows.append('TYPE %s retail=%s port=%s' % (k, sorted(v for _, v in rf[k])[:4], sorted(v for _, v in pf[k])[:4]))
        elif rk == {'num'} and pk == {'num'} and all(far(a, b) for a in rn for b in pn):
            rows.append('NUM  %s retail=%s port=%s' % (k, sorted(rn)[:4], sorted(pn)[:4]))
        for t, v in rf[k]:
            if t == 'str' and v and ('str', v) not in pf[k] and '"%s"' % v not in psrc + opts \
                    and not v.startswith(('Interface', 'sm:', '|')) and ' ' not in v:
                rows.append('ENUM %s retail=%r port=%s' % (k, v, sorted(x for tt, x in pf[k] if tt == 'str')[:5]))
    if rows:
        report.append('== ' + folder)
        report.extend('  ' + r for r in rows)

out = root / '.codex-backups' / 'profile-strings' / 'audit_defaults.txt'
out.write_text('\n'.join(report), encoding='utf-8')
print('\n'.join(report))
