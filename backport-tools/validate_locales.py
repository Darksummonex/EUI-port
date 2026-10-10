"""Exercise the native locale engine and all shipped catalogs in Lua 5.1."""
from pathlib import Path
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime
codes = ['deDE','esES','esMX','frFR','koKR','ruRU','zhCN','zhTW','ptBR']
# ptBR is port-only (built by build_ptbr_catalog.py); Retail ships no ptBR catalog.
port_only = {'ptBR'}
engine = (root / 'EllesmereUI/EUI_Locale_335.lua').read_text(encoding='utf-8')
# Catalogs are trimmed by clean_locale_catalogs.py: entries the port never shows
# are removed, every kept line is byte-identical to Retail and in Retail order.
# Port-only translations live after MARKER (build_locale_additions.py); only the
# part above it must match Retail.
MARKER = b'-- == 3.3.5 port additions (backport-tools/build_locale_additions.py) =='
# The trim was made from the Retail 9.3.4 catalogs, kept untrimmed in commit
# 4654752; later Retail versions reword or drop keys the port still uses.
RETAIL_SOURCE = '4654752'
GIT = r'C:\Program Files\Git\cmd\git.exe'
_subset = {}
def subset_of_retail(path, retail):
    if path not in _subset:
        import subprocess
        source = subprocess.run([GIT, '-C', str(root), 'show', RETAIL_SOURCE + ':' + retail],
                                capture_output=True, check=True).stdout
        theirs = iter(source.splitlines())
        ours = path.read_bytes().split(MARKER, 1)[0].splitlines()
        _subset[path] = all(any(line == other for other in theirs) for line in ours if line.strip())
    return _subset[path]
toc = (root / 'EllesmereUILocales/EllesmereUILocales.toc').read_text(encoding='utf-8')
for code in codes:
    assert (code + '.lua') in toc.split(), code
ptbr = (root / 'EllesmereUILocales/ptBR.lua').read_bytes()
assert not ptbr.startswith(b'\xef\xbb\xbf') and b'\r\n' in ptbr and b'\n' not in ptbr.replace(b'\r\n', b'')
assert ptbr.count(b'\nL["') > 4000
opts = (root / 'EllesmereUIOptions/EUI__General_Options.lua').read_text(encoding='utf-8')
assert '["ptBR"] = { text = "Português (Brasil)" }' in opts and '"esMX", "ptBR", "ruRU"' in opts
def run(client, override=None, missing=False):
    lua = LuaRuntime(unpack_returned_tuples=True)
    g = lua.globals()
    g.client = client; g.override = override
    lua.execute('''
EllesmereUI={}; EllesmereUIDB={displayLocale=override}
GetLocale=function() return client end
STANDARD_TEXT_FONT="Fonts\\\\FRIZQT__.TTF"
CreateFrame=function() return {
 RegisterEvent=function() end, UnregisterEvent=function() end,
 SetScript=function(self,event,fn) handler=fn; frame=self end} end
''')
    loaded = []
    def load(name):
        assert name == 'EllesmereUILocales'
        loaded.append(name)
        if not missing:
            for code in codes:
                path = root / 'EllesmereUILocales' / (code + '.lua')
                if code not in port_only:
                    assert subset_of_retail(path, 'EllesmereUILocales/' + path.name), code
                lua.execute(path.read_text(encoding='utf-8-sig'))
        return not missing
    g.C_AddOns = lua.table(LoadAddOn=load)
    lua.execute(engine, 'EllesmereUI')
    g.handler(g.frame, 'ADDON_LOADED', 'EllesmereUI')
    active = override if override in codes + ['enUS'] else ('enUS' if client == 'enGB' else client)
    if active not in codes: active = 'enUS'
    assert g.EllesmereUI.LOCALE == active
    assert bool(loaded) == (active != 'enUS')
    assert g.EllesmereUI.L('UNTRANSLATED_NATIVE_TEST') == 'UNTRANSLATED_NATIVE_TEST'
    assert g.EllesmereUI.L(123) == 123
    assert g.EllesmereUI.Lf('%2$s: %1$04d (100%%)', 7, 'value') == 'value: 0007 (100%)'
    assert g.EllesmereUI.Lf('%s %.2f', 'value', 1.5) == 'value 1.50'
    if active in codes and not missing:
        translated = g.EllesmereUI.L('Background')
        assert translated != 'Background', (active, translated)
        assert g.EllesmereUI.EnKey(translated) == 'Background'
        assert g.EllesmereUI._localeFont == g.STANDARD_TEXT_FONT or override
    if active == 'deDE' and not missing:
        assert g.EllesmereUI.Lf('Learn %d skill%s for %s', 2, 's', 'Trainer') == 'Lerne 2 Fertigkeit(en) für Trainer'
    if active == 'ptBR' and not missing:
        assert g.EllesmereUI.L('Background') == 'Fundo'
        assert g.EllesmereUI.L('Enable') == 'Ativar'
    return lua
for code in codes + ['enUS','enGB']:
    run(code)
for code in codes:
    run('enUS', code)
run('enUS','itIT'); run('deDE',missing=True)
print('PASS: eight Retail catalogs trimmed to the text the port shows (kept lines identical to Retail) plus the port-only pt-BR catalog; native/English clients, manual overrides incl. Português (Brasil), missing-addon/key fallback, reverse lookup, native fonts and positional/ordinary/escaped Lua 5.1 formats')
