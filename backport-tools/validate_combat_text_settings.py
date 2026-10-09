"""Execute the real General combat-text callbacks against strict client CVars."""
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

general = (root / 'EllesmereUIOptions/EUI__General_Options.lua').read_text(encoding='utf-8-sig')
assert 'if not _G.EUI_WOW_335 and (EllesmereUI.ModuleNS("EllesmereUIActionBars")' in general, 'Gamepad page must stay hidden on Wrath (no gamepad mode or module hooks)'
# Options that cannot work on 3.3.5 are hidden there (Retail rows kept in the else branches).
assert 'if EllesmereUI._applyHideBlizzardPartyFrame then' in general, 'Global reset must not call a Retail-only party frame hook unguarded'
assert 'if _G.EUI_WOW_335 then\n            _, h = W:DualRow(parent, y, cameraCfg, keyDownCfg)' in general.replace('\r\n', '\n')
assert 'local combatTextSizeCfg = not _G.EUI_WOW_335 and' in general
assert 'if playerClass == "DRUID" and not _G.EUI_WOW_335 then' in general
assert '_G.EUI_WOW_335 and { type = "label", text = "" } or\n                { type = "toggle", text = "Dark Mode (Class Resource Bar)"' in general.replace('\r\n', '\n')
assert 'if not _G.EUI_WOW_335 then\n            _, h = W:SectionHeader(parent, "CLASS RESOURCE COLORS", y)' in general.replace('\r\n', '\n')
assert 'ipairs(WithoutWrathMissing(CLASS_ORDER))' in general and 'ipairs(WithoutWrathMissing(POWER_ORDER))' in general
fonts = (root / 'EllesmereUIOptions/EUI_Fonts_Options.lua').read_text(encoding='utf-8-sig')
assert 'local slugCfg = not _G.EUI_WOW_335 and' in fonts
assert fonts.split('local function TileCombatText(', 1)[1].split('WorldTextScale_v2', 1)[0].count('if not _G.EUI_WOW_335 then') == 1
textures = (root / 'EllesmereUIOptions/EUI_Textures_Options.lua').read_text(encoding='utf-8-sig')
qol_tile = textures.split('local function TileQoL(', 1)[1].split('local function TileMythicTimer(', 1)[0]
assert qol_tile.index('if _G.EUI_WOW_335 then') < qol_tile.index('W:DualRow(parent, y, maCfg or BLANK(), cursorCfg)')
assert 'TILE_BUILDERS.EllesmereUIQoL = nil' in textures

# Behaviour: on Wrath the class/power swatch lists drop Retail-only entries; Retail keeps them all.
filt = 'local function WithoutWrathMissing(' + general.split('local function WithoutWrathMissing(', 1)[1].split('\n        local classItems', 1)[0]
for wrath in (True, False):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.globals().EUI_WOW_335 = wrath
    out = lua.execute(filt + '''
local c = WithoutWrathMissing({"WARRIOR","DEATHKNIGHT","MONK","DRUID","DEMONHUNTER","EVOKER"})
local p = WithoutWrathMissing({"MANA","RUNIC_POWER","FURY","LUNAR_POWER","INSANITY","MAELSTROM","EBON_MIGHT"})
return table.concat(c, ","), table.concat(p, ",")''')
    if wrath:
        assert out == ('WARRIOR,DEATHKNIGHT,DRUID', 'MANA,RUNIC_POWER'), out
    else:
        assert out == ('WARRIOR,DEATHKNIGHT,MONK,DRUID,DEMONHUNTER,EVOKER', 'MANA,RUNIC_POWER,FURY,LUNAR_POWER,INSANITY,MAELSTROM,EBON_MIGHT'), out

helpers = '-- Stock Wrath names differ' + general.split('-- Stock Wrath names differ', 1)[1].split('--- Returns current, default', 1)[0]
rows = 'local showDmgRow' + general.split('local showDmgRow', 1)[1].split('-- Swiftmend Brightness Fix', 1)[0]

for wrath in (True, False):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.globals().EUI_WOW_335 = wrath
    lua.execute('''
local names = EUI_WOW_335 and {
 "CombatDamage", "CombatHealing", "CombatLogPeriodicSpells", "PetMeleeDamage", "PetSpellDamage"
} or {
 "floatingCombatTextCombatDamage_v2", "floatingCombatTextCombatHealing_v2",
 "floatingCombatTextCombatLogPeriodicSpells_v2", "floatingCombatTextPetMeleeDamage_v2",
 "floatingCombatTextPetSpellDamage_v2"
}
values={}; writes={}; combat=false; refreshes=0
for _,key in ipairs(names) do values[key]="0" end
values[names[2]]="1"
GetCVar=function(key) assert(values[key]~=nil,"unknown client CVar: "..key); return values[key] end
SetCVar=function(key,value)
 assert(values[key]~=nil,"unknown client CVar: "..key)
 writes[#writes+1]={key,value}; values[key]=value
end
InCombatLockdown=function() return combat end
EllesmereUI={RefreshPage=function() refreshes=refreshes+1 end,
 BuildInlineCog=function(parent,opts) cog=opts end}
local W={DualRow=function(self,parent,y,left,right)
 damage=left; healing=right; return {_leftRegion={}},50
end}
local parent,y,h={},0,0
''' + helpers + rows + '''
assert(not damage.getValue() and healing.getValue())
assert(cog.disabled())
damage.setValue(true)
assert(values[names[1]]=="1" and values[names[2]]=="1" and refreshes==1)
assert(damage.getValue() and not cog.disabled())
healing.setValue(false)
assert(not healing.getValue() and damage.getValue())
for i,row in ipairs(cog.rows) do
 assert(not row.get())
 row.set(true); assert(row.get() and values[names[i+2]]=="1")
 row.set(false); assert(not row.get() and values[names[i+2]]=="0")
end
damage.setValue(false); assert(not damage.getValue() and cog.disabled())
healing.setValue(true); assert(healing.getValue() and not damage.getValue())
assert(#writes==10)
-- Preserve the page's existing combat restriction and safe unknown-CVar behavior.
combat=true; damage.setValue(true); healing.setValue(false)
assert(#writes==10 and not damage.getValue() and healing.getValue())
combat=false
assert(SafeGetCVar("unsupportedSetting")==nil)
assert(not SetCVarSafe("unsupportedSetting","1"))
assert(#writes==10)
-- Max Camera Distance uses the Retail name; Wrath's CVar is cameraDistanceMaxFactor.
local camera=EUI_WOW_335 and "cameraDistanceMaxFactor" or "cameraDistanceMaxZoomFactor"
values[camera]="1"
assert(SetCVarSafe("cameraDistanceMaxZoomFactor",2.6) and values[camera]==2.6)
assert(GetCVarNum("cameraDistanceMaxZoomFactor")==2.6,"Max Camera Distance must read back what it saved")
''')

print('PASS: General damage/healing and periodic/pet callbacks read/write native Wrath CVars; independent toggles, combat guard, unknown CVars and Retail names preserved.')
