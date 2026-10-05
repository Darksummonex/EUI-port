"""Settings Overrides (spec groups + conditional overrides) on Wrath.

Static: TOC order, Retail-only API/art absent, TGA media present, Wrath spec
table in Presets. Behavior (Wrath mock): Wrath roster and spec names, value
apply/harvest across a dual-spec swap, conditional resolution (solo, party,
battleground, keybind) and a conditional flip writing and restoring values.
"""
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

core = root / 'EllesmereUI'
so_path = core / 'EllesmereUI_SpecOverrides_335.lua'
cond_path = core / 'EllesmereUI_Conditions_335.lua'
presets_path = core / 'EllesmereUI_Presets.lua'
so = so_path.read_text(encoding='utf-8-sig')
cond = cond_path.read_text(encoding='utf-8-sig')
presets = presets_path.read_text(encoding='utf-8-sig')

toc = [l.strip() for l in (core / 'EllesmereUI.toc').read_text(encoding='utf-8-sig').splitlines()]
order = [l for l in toc if l.endswith('.lua')]
for name in ('EllesmereUI_SpecOverrides_335.lua', 'EllesmereUI_Conditions_335.lua'):
    assert name in order, name
assert 'EllesmereUI_SpecOverrides.lua' not in order and 'EllesmereUI_Conditions.lua' not in order
i_so, i_cond = order.index('EllesmereUI_SpecOverrides_335.lua'), order.index('EllesmereUI_Conditions_335.lua')
for before in ('EllesmereUI_Presets.lua', 'EllesmereUI_Profiles.lua', 'EUI_UnlockMode.lua', 'EllesmereUI_VideoGuides_335.lua'):
    assert order.index(before) < i_so, before
assert i_so < i_cond

for banned in ('.png"', 'GetMouseFoci', 'SetAtlas(', 'GLOBAL_MOUSE_UP', 'GetSpecializationInfoByID',
               'GetSpecializationInfoForClassID', 'GetNumClasses', 'GetClassInfo', 'icons\\\\class-full',
               'EUI_CLIENT_BLOCKED', 'SetMouseClickEnabled'):
    assert banned not in so, banned
for banned in ('GROUP_ROSTER_UPDATE"', 'EUI_CLIENT_BLOCKED'):
    assert banned not in cond, banned
assert 'local function IsInGroup()' in cond
assert 'class-modern.tga' in (core / 'EllesmereUI_VideoGuides_335.lua').read_text(encoding='utf-8-sig')

for tex in re.findall(r'icons_335\\\\([\w-]+\.tga)', so) + ['class-glyph.tga', 'class-modern.tga']:
    assert (core / 'media' / 'icons_335' / tex).exists(), tex
for name in re.findall(r'"(override-[\w]+\.tga)"', so):
    assert (core / 'media' / 'icons_335' / name).exists(), name
assert (core / 'media' / 'backgrounds_335' / 'eui-glow-override.tga').exists()

for retail_id in ('id = 250', 'id = 577', 'id = 1467', 'id = 268', 'DEMONHUNTER', 'EVOKER', '"MONK"'):
    assert retail_id not in presets, retail_id
assert 'local COL_LISTS = { {1,6}, {2,7}, {3,8}, {4,9}, {5,10} }' in presets
assert 'row._roles and row._roles[role]' in presets

lua = LuaRuntime()
lua.execute((root / 'backport-tools' / 'wrath_mock.lua').read_text())
lua.execute(r'''
function UnitClass() return "Mage", "MAGE" end
function strsplit(sep, s)
    local out, start = {}, 1
    while true do
        local i = s:find(sep, start, true)
        if not i then out[#out + 1] = s:sub(start); break end
        out[#out + 1] = s:sub(start, i - 1)
        start = i + #sep
    end
    return unpack(out)
end
tinsert, tremove = table.insert, table.remove
local frameMethods = getmetatable(UIParent).__index
function frameMethods:GetName() return self._name end
local mockCreateFrame = CreateFrame
function CreateFrame(kind, name, ...)
    local f = mockCreateFrame(kind, name, ...)
    f._name = name
    return f
end
LOCALIZED_CLASS_NAMES_MALE = { WARRIOR="Warrior", PALADIN="Paladin", HUNTER="Hunter", ROGUE="Rogue",
    PRIEST="Priest", DEATHKNIGHT="Death Knight", SHAMAN="Shaman", MAGE="Mage", WARLOCK="Warlock", DRUID="Druid" }
RAID_CLASS_COLORS = {}
for k in pairs(LOCALIZED_CLASS_NAMES_MALE) do RAID_CLASS_COLORS[k] = { r=1, g=1, b=1 } end
function GetTalentTabInfo(i) return ({ "Arcano", "Fogo", "Gelo" })[i], "tab-icon-" .. i, 0 end
inst = "none"
function IsInInstance() return inst ~= "none", inst end
party = 0
function GetNumPartyMembers() return party end
bound = {}
function ClearOverrideBindings() bound = {} end
function SetOverrideBindingClick(_, _, key, name) bound[key] = name end
function GetBindingText(k) return k end
function IsShiftKeyDown() return false end
function IsControlKeyDown() return false end
function IsAltKeyDown() return false end
function IsMouseButtonDown() return false end
function GetMouseFocus() return nil end
function methods_patch() end
local function DeepCopy(v)
    if type(v) ~= "table" then return v end
    local t = {}
    for k, x in pairs(v) do t[k] = DeepCopy(x) end
    return t
end
EllesmereUI.Lite.DeepCopy = DeepCopy
abProfile = { bar1 = { size = 30 } }
EllesmereUI.Lite._dbRegistry = { { folder = "EllesmereUIActionBars", profile = abProfile } }
EllesmereUIDB = { activeProfile = "Default", profiles = { Default = {} } }
function EllesmereUI.GetProfilesDB() return EllesmereUIDB end
function EllesmereUI.GetActiveProfileData() return EllesmereUIDB.profiles.Default end
EllesmereUI._specID = 33083
function EllesmereUI._RefreshSpecID() end
function EllesmereUI.L(s) return s end
function EllesmereUI.Lf(s, ...) return s end
dark = false
function EllesmereUI.IsDarkModeAllOn() return dark end
EllesmereUI.CombatQueue = { Defer = function() end }
EllesmereUI.CLASS_TOKEN_ORDER = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT",
    "SHAMAN", "MAGE", "WARLOCK", "MONK", "DRUID", "DEMONHUNTER", "EVOKER" }
EllesmereUI.MEDIA_PATH = "Interface\\AddOns\\EllesmereUI\\media\\"
refreshed = 0
_G._EAB_Apply = function() refreshed = refreshed + 1 end
''')


def load(path, *args):
    fn = lua.eval('function(src, name) local f, e = loadstring(src, name); if not f then error(e) end; return f end')(
        path.read_text(encoding='utf-8-sig'), path.name)
    return fn(*args)


lua.execute('''
EllesmereUI.BORDER_R, EllesmereUI.BORDER_G, EllesmereUI.BORDER_B = 1, 1, 1
EllesmereUI.ELLESMERE_GREEN = { r = 0, g = 1, b = 0 }
function EllesmereUI.GetPopupScale() return 1 end
function EllesmereUI:RegisterOnCollapse() end
''')
load(presets_path, 'EllesmereUI')
load(so_path, 'EllesmereUI')
load(cond_path, 'EllesmereUI')

lua.execute(r'''
-- Wrath roster: 10 classes x 3 trees, Retail class-ID order, synthetic IDs.
local values, order, icons, classes = EllesmereUI.BuildSpecBucketRoster()
local specs = {}
for _, k in ipairs(order) do if k:match("^spec") then specs[#specs + 1] = k end end
assert(#specs == 30, #specs)
assert(specs[1] == "spec33011" and specs[30] == "spec33113", specs[1] .. " " .. specs[30])
assert(values.spec33081 == "Arcano Mage" and icons.spec33081 == "tab-icon-1")
assert(values.spec33061 == "Blood Death Knight" and classes.spec33061 == "DEATHKNIGHT")
assert(icons.spec33113 == "Interface\\Icons\\Spell_Nature_HealingTouch")
for k in pairs(values) do assert(not k:match("^spec%d%d?%d?$"), k) end
local name, className, icon, token, roles = EllesmereUI.WrathSpecInfo(33112)
assert(name == "Feral Combat" and className == "Druid" and token == "DRUID" and roles.TANK and roles.DAMAGER)
assert(EllesmereUI.WrathSpecInfo(250) == nil)
local items = EllesmereUI.SpecBucketMenuItems("spec33083")
local sawDisabled = false
for _, it in ipairs(items) do if it.key == "spec33083" then sawDisabled = it.disabled end end
assert(sawDisabled)

-- Values: Frost (33083) overrides the bar size; Arcane (33081) uses the default.
local FK = "EllesmereUIActionBars\31bar1\30size"
local prof = EllesmereUIDB.profiles.Default
prof.specOverrideGroups = { { id = 1, name = "Frost", specs = { 33083 } } }
prof.specOverrideNextId = 1
prof.specOverrides = { { group = 1, label = "Size", module = "EllesmereUIActionBars",
    values = { default = { [FK] = 30 }, [33083] = { [FK] = 45 } } } }
EllesmereUI.SpecOverrides_Apply(33083)
assert(abProfile.bar1.size == 45, abProfile.bar1.size)
assert(refreshed == 1, refreshed)
assert(EllesmereUI.SpecOverrides_IsCaptured("EllesmereUIActionBars", "bar1", "size"))
-- Dual-spec swap to Arcane: Frost's live edit is banked, Arcane gets the default.
abProfile.bar1.size = 50
EllesmereUI.SpecOverrides_OnSpecChanged(33083, 33081)
EllesmereUI.SpecOverrides_Apply(33081)
assert(abProfile.bar1.size == 30, abProfile.bar1.size)
assert(prof.specOverrides[1].values[33083][FK] == 50)
EllesmereUI.SpecOverrides_OnSpecChanged(33081, 33083)
EllesmereUI.SpecOverrides_Apply(33083)
assert(abProfile.bar1.size == 50, abProfile.bar1.size)
EllesmereUI.SpecOverrides_OnSpecChanged(33083, 33081)
EllesmereUI.SpecOverrides_Apply(33081)
assert(abProfile.bar1.size == 30)

-- Conditional resolution ladder on Wrath.
prof.condOverrideGroups = {
    { id = 1, name = "Solo", conds = { solo = true } },
    { id = 2, name = "BG", conds = { battleground = true } },
    { id = 3, name = "Key", conds = { keybind = true }, key = "ALT-X" },
}
assert(EllesmereUI.Conditions_ActiveGroup().id == 1)
party = 2
assert(EllesmereUI.Conditions_ActiveGroup() == nil)
inst = "pvp"
assert(EllesmereUI.Conditions_ActiveGroup().id == 2)
inst = "arena"
assert(EllesmereUI.Conditions_ActiveGroup() == nil)
EllesmereUI.Conditions_RebuildKeyBindings()
assert(bound["ALT-X"] == "EUICondKeyBtn1")
EllesmereUI.Conditions_ToggleKey(3)
assert(EllesmereUI.Conditions_ActiveGroup().id == 3)
EllesmereUI.Conditions_ToggleKey(3)
inst, party = "none", 0

-- Conditional flip: the Solo group's size applies, joining a party restores it.
local CK = "EllesmereUIActionBars\31bar1\30scale"
abProfile.bar1.scale = 1
prof.condOverrides = { { group = 1, label = "Scale", module = "EllesmereUIActionBars",
    values = { default = { [CK] = 1 }, [1] = { [CK] = 0.8 } } } }
if EllesmereUI._CondOv.RebuildIndex then EllesmereUI._CondOv.RebuildIndex() end
EllesmereUI.Conditions_Recheck()
assert(abProfile.bar1.scale == 0.8, abProfile.bar1.scale)
assert(prof.condAppliedGid == 1)
party = 3
EllesmereUI.Conditions_Recheck()
assert(abProfile.bar1.scale == 1, abProfile.bar1.scale)
assert(prof.condAppliedGid == nil)
''')

events = lua.eval('''function()
    local found = {}
    for _, f in ipairs(allFrames) do
        if f.events.PARTY_MEMBERS_CHANGED and f.events.RAID_ROSTER_UPDATE and f.events.ZONE_CHANGED_NEW_AREA then
            found.roster = true
        end
        if f.events.GROUP_ROSTER_UPDATE then found.retail = true end
    end
    return found
end''')()
assert events['roster'] and not events['retail']
print('PASS: overrides TOC/media/static checks; Wrath roster (30 specs, synthetic IDs, localized own trees); '
      'spec apply/harvest across dual-spec swaps; conditional ladder, keybind toggle and flip apply/restore.')
