"""Per-element text outline (None / Outline / Thick / Shadow / module default) for
Nameplates texts, Unit Frames text slots and Zone Text, via EllesmereUI.ApplyTextOutline."""
from pathlib import Path
import re
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime


def read(rel):
    return (root / rel).read_text(encoding='utf-8-sig')


fonts = read('EllesmereUI/EllesmereUI_Fonts.lua')
start = fonts.index('-- Runtime FontString:SetShadowOffset')
end = fonts.index('-- "Apply to All Game Text"')
block = fonts[start:end]
assert 'function EllesmereUI.ApplyTextOutline' in block

lua = LuaRuntime()
lua.execute(r'''
EllesmereUI={}
function EllesmereUI.GetFontPath() return "module.ttf" end
function CreateFont(name)
    local o={name=name}
    function o:SetFont() end
    function o:SetShadowColor() end
    function o:SetShadowOffset(x,y) self.shadow=(x~=0 or y~=0) end
    return o
end
function NewFS()
    local fs={r=.2,g=.4,b=.6,a=1}
    function fs:SetFont(path,size,flags) self.path,self.size,self.flags=path,size,flags end
    function fs:SetFontObject(o) self.obj=o; self.r,self.g,self.b,self.a=1,1,1,1 end
    function fs:GetTextColor() return self.r,self.g,self.b,self.a end
    function fs:SetTextColor(r,g,b,a) self.r,self.g,self.b,self.a=r,g,b,a end
    return fs
end
''')
lua.execute(block)
run = lua.eval('''function(mode, path)
    local fs=NewFS()
    local handled=EllesmereUI.ApplyTextOutline(fs,path,14,mode,"nameplates")
    return handled, fs.flags, fs.obj and fs.obj.shadow, fs.path, fs.size, fs.r, fs._euiTextOutline
end''')
for mode, flag, shadow in (('none', '', False), ('outline', 'OUTLINE', False), ('thick', 'THICKOUTLINE', False), ('shadow', '', True)):
    handled, flags, sh, path, size, r, mark = run(mode, 'x.ttf')
    assert handled is True and flags == flag and bool(sh) == shadow and path == 'x.ttf' and size == 14, mode
    assert abs(r - .2) < 1e-6, f'{mode}: painted colour lost'
    assert mark == mode
handled, flags, *_ = run('outline', None)
assert run('outline', None)[3] == 'module.ttf'
for mode in ('module', None):
    handled, flags, obj, *_ = run(mode, 'x.ttf')
    assert handled is False and flags is None and obj is None, f'{mode}: module default must be left to the caller'
# Leaving an override clears the primed shadow and keeps the colour.
back = lua.eval('''function()
    local fs=NewFS(); EllesmereUI.ApplyTextOutline(fs,"x.ttf",12,"shadow","nameplates")
    fs.r=.3; local handled=EllesmereUI.ApplyTextOutline(fs,"x.ttf",12,"module","nameplates")
    return handled, fs.obj.shadow, fs._euiTextOutline, fs.r
end''')
handled, shadow, mark, r = back()
assert handled is False and not shadow and mark is None and abs(r - .3) < 1e-6
values = lua.eval('EllesmereUI.TEXT_OUTLINE_ORDER')
assert [values[i] for i in range(1, 6)] == ['module', 'none', 'outline', 'thick', 'shadow']

# Nameplates: defaults, runtime wiring and one cog dropdown per text element.
NP_KEYS = ['nameOutline', 'healthTextOutline', 'levelOutline', 'totOutline', 'castNameOutline', 'castTimerOutline',
           'auraStackTextOutline', 'auraDurationTextOutline', 'friendlyNameOutline']
np_core = read('EllesmereUINameplates/EUI_Nameplates_335.lua')
np_display = read('EllesmereUINameplates/EUI_Nameplates_335_Display.lua')
np_options = read('EllesmereUIOptions/EUI_Nameplates_335_Options.lua')
for key in NP_KEYS:
    assert f'{key}="module"' in np_core, key
    assert f'p.{key}' in np_display, key
    assert f'CogOutline("{key}")' in np_options, key
assert 'local function Font(fs,size,outline)' in np_display and 'E.ApplyTextOutline(fs,' in np_display
assert not re.search(r'\bFont\((s\.castText|s\.castTimer|a\.count|a\.time|s\.name),[^,()]+\)', np_display), 'nameplate text without outline'

# Unit Frames: every text-slot SetFSFont carries its slot outline; options + preview expose it.
uf = read('EllesmereUIUnitFrames/EllesmereUIUnitFrames.lua')
assert 'local function SetFSFont(fs, size, flags, outline)' in uf
SLOT_FS = {'leftText': 'leftText', 'rightText': 'rightText', 'centerText': 'centerText', 'extraText': 'extraText',
           'leftFS': 'btbLeft', 'rightFS': 'btbRight', 'centerFS': 'btbCenter', 'ppFS': 'powerPercent'}
calls = 0
for m in re.finditer(r'SetFSFont\((\w+), (.+)\)', uf):
    if m.group(1) in SLOT_FS:
        assert re.search(r', nil, \w+\.' + SLOT_FS[m.group(1)] + r'Outline$', m.group(2)), m.group(0)
        calls += 1
assert calls == 38, calls
uf_opt = read('EllesmereUIOptions/EUI_UnitFrames_Options.lua')
for slot in ('leftText', 'rightText', 'centerText', 'extraText', 'btbLeft', 'btbRight', 'btbCenter', 'powerPercent'):
    assert f'SVal("{slot}Outline", "module")' in uf_opt, slot
    assert f's.{slot}Outline)' in uf_opt, f'{slot} preview'
for slot in ('leftText', 'rightText', 'centerText', 'extraText', 'powerPercent'):
    assert f'MVal("{slot}Outline", "module")' in uf_opt, f'{slot} (mini frames)'
assert uf_opt.count('label="Outline", values=EllesmereUI.TEXT_OUTLINE_VALUES') == 13
assert 'local function SetPVOutlineFont(fs, size, outline)' in uf_opt
assert not re.search(r'(leftFS|rightFS|centerFS|extraFS|btb\w+FS|ppPreviewFS):SetFont\(PREVIEW_FONT', uf_opt)

# Zone Text: default, runtime hook-up and the dropdown beside Move Zone Text.
qol = read('EllesmereUIQoL/EUI_QoL_335.lua')
qol_disp = read('EllesmereUIQoL/EUI_QoL_335_Displays.lua')
qol_opt = read('EllesmereUIOptions/EUI_QoL_335_Options.lua')
assert 'zoneTextOutline="module"' in qol
assert 'function ns.ApplyZoneOutline()' in qol_disp and 'ns.ApplyZoneText(); ns.ApplyZoneOutline()' in qol_disp
for name in ('ZoneTextString', 'SubZoneTextString', 'PVPInfoTextString', 'PVPArenaTextString'):
    assert f'"{name}"' in qol_disp, name
assert 'Dropdown(nil,"zoneTextOutline","Zone Text Outline"' in qol_opt and 'zoneOutlines.module="Blizzard Default"' in qol_opt

# Every touched file still compiles under Lua 5.1 (also catches the 200-local limit).
compile_error = lua.eval('function(src,name) local f,e=loadstring(src,name); return not f and e or nil end')
for rel in ('EllesmereUI/EllesmereUI_Fonts.lua', 'EllesmereUINameplates/EUI_Nameplates_335.lua',
            'EllesmereUINameplates/EUI_Nameplates_335_Display.lua', 'EllesmereUIOptions/EUI_Nameplates_335_Options.lua',
            'EllesmereUIUnitFrames/EllesmereUIUnitFrames.lua', 'EllesmereUIOptions/EUI_UnitFrames_Options.lua',
            'EllesmereUIQoL/EUI_QoL_335.lua', 'EllesmereUIQoL/EUI_QoL_335_Displays.lua', 'EllesmereUIOptions/EUI_QoL_335_Options.lua'):
    err = compile_error(read(rel), '@' + rel)
    assert err is None, err

print('text outline: OK')
