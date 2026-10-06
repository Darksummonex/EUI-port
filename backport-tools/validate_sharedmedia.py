"""SharedMedia (LibSharedMedia-3.0) fonts, bar textures and sounds on 3.3.5:
Core's helpers run against a mock LSM (initial + late registrations), and every module
with a texture or sound picker lists SharedMedia and resolves its keys at runtime."""
from pathlib import Path
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime


def read(rel):
    return (root / rel).read_text(encoding='utf-8-sig')


core = read('EllesmereUI/EllesmereUI.lua')
helpers = core[core.index('function EllesmereUI.ResolveTexturePath'):core.index('--  Deferred file initialization')]

lua = LuaRuntime()
lua.execute(r'''
EllesmereUI = { FONT_FILES = {}, FONT_BLIZZARD = {} }
local media = { statusbar = { Solid = "Interface\\Buttons\\WHITE8X8", Smooth = "Interface\\SM\\Smooth.tga" },
                sound = { Ding = "Sound\\SM\\Ding.ogg" }, font = {} }
local callbacks = {}
LSM = {}
function LSM:HashTable(kind) return media[kind] end
function LSM:Fetch(kind, name) return media[kind] and media[kind][name] end
function LSM.RegisterCallback(owner, event, fn) callbacks[#callbacks + 1] = fn end
function LSM_Register(kind, name, path)
    media[kind][name] = path
    for _, fn in ipairs(callbacks) do fn("LibSharedMedia_Registered", kind, name) end
end
function LibStub(name, silent) return LSM end
function EllesmereUI.BuildAlertSoundTables()
    return { alert = "Interface\\AddOns\\EllesmereUI\\media\\sounds\\alert.ogg" }, { none = "None", alert = "Alert" }, { "none", "alert" }
end
''')
lua.execute(helpers)
r = lua.execute(r'''
local E = EllesmereUI
local out = {}
-- Textures: a module table gets SM entries once, late ones too, and sm: keys resolve.
local tex, names, order = { none = "Interface\\Buttons\\WHITE8X8" }, { none = "Solid" }, { "none" }
E.AppendSharedMediaTextures(names, order, nil, tex)
E.AppendSharedMediaTextures(names, order, nil, tex)
out[1] = tex["sm:Smooth"] == "Interface\\SM\\Smooth.tga" and tex["sm:Solid"] == nil   -- exact native duplicate dropped
local seps = 0; for _, k in ipairs(order) do if k == "---" then seps = seps + 1 end end
out[2] = seps == 1 and #order == 3
LSM_Register("statusbar", "Late", "Interface\\SM\\Late.tga")
out[3] = tex["sm:Late"] == "Interface\\SM\\Late.tga" and order[#order] == "sm:Late"
out[4] = E.ResolveTexturePath({}, "sm:Late", "x") == "Interface\\SM\\Late.tga" and E.ResolveTexturePath(tex, "missing", "fb") == "fb"
E.AppendSharedMediaTextures({}, {}, nil, nil)                                  -- no table: ignored, no error
-- Sounds: shared catalogue, one separator, late registration, resolve.
local paths, snames, sorder = E.GetAlertSoundCatalogue()
E.GetAlertSoundCatalogue()
out[5] = paths["sm:Ding"] == "Sound\\SM\\Ding.ogg" and snames["sm:Ding"] == "Ding"
seps = 0; for _, k in ipairs(sorder) do if k == "---" then seps = seps + 1 end end
out[6] = seps == 1 and #sorder == 4
LSM_Register("sound", "Horn", "Sound\\SM\\Horn.ogg")
out[7] = paths["sm:Horn"] == "Sound\\SM\\Horn.ogg" and sorder[#sorder] == "sm:Horn"
out[8] = E.ResolveSoundPath(paths, "alert") ~= nil and E.ResolveSoundPath({}, "sm:Horn") == "Sound\\SM\\Horn.ogg"
    and E.ResolveSoundPath(paths, "none") == nil and E.ResolveSoundPath(paths, "RaidWarning") == nil
return unpack(out)
''')
assert all(x is True for x in r), r

checks = {
    'EllesmereUINameplates/EUI_Nameplates_335_Display.lua': [
        'E.AppendSharedMediaTextures(ns.textureValues,ns.textureOrder,nil,textures)',
        'E.ResolveTexturePath(textures,p.healthBarTexture,FLAT)', 'E.ResolveTexturePath(textures,p.castBarTexture,FLAT)'],
    'EllesmereUIArena/EUI_Arena_335_Display.lua': [
        'E.AppendSharedMediaTextures(names,order,nil,textures)', 'return E.ResolveTexturePath(textures,key,white)'],
    'EllesmereUICooldownManager/EUI_CooldownManager_335_TrackingBars.lua': [
        'E.AppendSharedMediaTextures(ns.TBB_TEXTURE_NAMES,ns.TBB_TEXTURE_ORDER,nil,ns.TBB_TEXTURES)',
        'E.ResolveTexturePath(ns.TBB_TEXTURES,key or "none")'],
    'EllesmereUIRaidFrames/EUI_RaidFrames_335_Display.lua': [
        'E.AppendSharedMediaTextures(names,order,nil,textures)', 'E.ResolveTexturePath(textures,key)'],
    'EllesmereUIResourceBars/EUI_ResourceBars_335.lua': [
        'E.AppendSharedMediaTextures(names, texOrder, nil, textures)', 'E.ResolveTexturePath(textures, key)'],
    'EllesmereUIDamageMeters/EUI_DamageMeters_335_Display.lua': ['key:match("^sm:(.+)")'],
    'EllesmereUIRaidFrames/EUI_RaidFrames_335_Indicators.lua': ['E.ResolveTexturePath(ns.healthBarTextures,'],
    'EllesmereUIOptions/EUI_AuraIndicators_335_Options.lua': ['E.ResolveTexturePath(ns.healthBarTextures,'],
    'EllesmereUIOptions/EUI_Textures_Options.lua': ['"Bar Texture (per window)", tile.folder, "Windows", "BARS", "Bar Texture"'],
    'EllesmereUIAuraBuffReminders/EUI_AuraBuffReminders_335.lua': [
        'E.GetAlertSoundCatalogue()', 'E.ResolveSoundPath(paths, skey)'],
    'EllesmereUICooldownManager/EUI_CooldownManager_335_Display.lua': ['function D.PlayCastSound(key)', 'D.PlayCastSound(bar.focusCastSoundKey)'],
    'EllesmereUIOptions/EUI_CooldownManager_335_Options.lua': ['E.GetAlertSoundCatalogue()'],
    'EllesmereUIOptions/EUI_Chat_335_Options.lua': ['E.GetAlertSoundCatalogue or E.BuildAlertSoundTables'],
    'EllesmereUIQoL/EUI_QoL_335_Displays.lua': ['E.ResolveSoundPath(ns.Sounds(),key)'],
    'EllesmereUI/EllesmereUI_PartyMode_335.lua': ['EUI.ResolveSoundPath(paths, key)'],
}
compile_fn = lua.execute('return function(src) local f, e = loadstring(src) if not f then return e end return true end')
for rel, needles in checks.items():
    src = read(rel)
    for needle in needles:
        assert needle in src, f'{rel}: missing {needle}'
    res = compile_fn(src)
    assert res is True, f'{rel}: {res}'
res = compile_fn(core)
assert res is True, f'EllesmereUI.lua: {res}'
assert 'E.AppendSharedMediaSounds(paths,names,o)' not in read('EllesmereUIOptions/EUI_Chat_335_Options.lua'), \
    'per-build sound tables would each stay registered for late sounds'

print('SharedMedia OK')
