"""Exercise the native locale engine and all shipped catalogs in Lua 5.1."""
from pathlib import Path
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime
codes = ['deDE','esES','esMX','frFR','koKR','ruRU','zhCN','zhTW']
engine = (root / 'EllesmereUI/EUI_Locale_335.lua').read_text(encoding='utf-8')
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
                retail = Path('D:/World of Warcraft/_retail_/Interface/AddOns/EllesmereUILocales') / path.name
                assert path.read_bytes() == retail.read_bytes(), code
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
    return lua
for code in codes + ['enUS','enGB']:
    run(code)
for code in codes:
    run('enUS', code)
run('enUS','ptBR'); run('enUS','itIT'); run('deDE',missing=True)
print('PASS: eight original catalogs; native/English clients, manual overrides, missing-addon/key fallback, reverse lookup, native fonts and positional/ordinary/escaped Lua 5.1 formats')
