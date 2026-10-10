"""Cooldown Manager 0.9: Retail Hidden Until Usable and Hidden Outside Form/Stance
(Keep Place and shifting), the tooltip form check with its caster-form fallback,
and Empty Slot spacer entries in the core, display and options."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime

core=(root/'EllesmereUICooldownManager/EUI_CooldownManager_335.lua').read_text(encoding='utf-8')
display=(root/'EllesmereUICooldownManager/EUI_CooldownManager_335_Display.lua').read_text(encoding='utf-8')
options=(root/'EllesmereUIOptions/EUI_CooldownManager_335_Options.lua').read_text(encoding='utf-8')

assert '"UPDATE_SHAPESHIFT_FORM"' in core and 'event=="UPDATE_SHAPESHIFT_FORM" then ns.Update()' in core
assert 'ns.WipeFormCache()\n    ns.ScanSpells(); ns.ScanTalents()' in core
assert 'st.meta.kind=="empty" or not (st.bar.showTooltip' in display, 'empty slots show no tooltip'
for key in ('hiddenUnusableShift','hiddenFormShift','hiddenUnusable','hiddenForm'):
    assert options.count(key)>=2, key
assert 'Add("Empty Slot",nil,false,Close(function() O.AddEntry("empty") end))' in options
assert 'empty="Empty Slot"' in options and 'elseif e.kind=="empty" then' in options
assert 'l[#l+1]={kind="empty",enabled=true}' in options

lua=LuaRuntime()
lua.execute('''
function wipe(t) for k in pairs(t) do t[k]=nil end return t end
SPELL_REQUIRED_FORM="Requires %s"
EllesmereUI={Lite={NewAddon=function() return {} end},_ModuleNS={}}
forms={"Battle Stance","Defensive Stance","Berserker Stance"}; form=1
function GetNumShapeshiftForms() return #forms end
function GetShapeshiftFormInfo(i) return "icon"..i,forms[i],i==form,true end
function GetShapeshiftForm() return form end
tips={}; reads=0
local function Line(i)
    local fs={}
    function fs:GetText() local l=tips.cur and tips.cur[i]; return l and l[1] end
    function fs:GetTextColor() local l=tips.cur[i]; return l[2],l[3],l[4] end
    return fs
end
for i=1,8 do _G["EUI335CdmFormScanTextLeft"..i]=Line(i) end
function CreateFrame(kind,name)
    assert(kind=="GameTooltip" and name=="EUI335CdmFormScan")
    local t={}
    function t:SetOwner() end
    function t:ClearLines() tips.cur=nil end
    function t:SetSpell(slot) reads=reads+1; tips.cur=tips[slot] end
    function t:NumLines() return tips.cur and #tips.cur or 0 end
    return t
end
''')
ns=lua.table()
lua.execute(core,'EllesmereUICooldownManager',ns)
lua.globals().D=ns
lua.execute('''
local RED,WHITE={1,.13,.13},{1,1,1}
local function St(meta,effect,fields)
    local st={meta=meta,bar={spellDefaults={cdStateEffect=effect}},entry={}}
    for k,v in pairs(fields or {}) do st[k]=v end
    return st
end
local overpower={kind="spell",name="Overpower",slot=1,book="spell"}
local charge={kind="spell",name="Charge",slot=2,book="spell"}
local whirl={kind="spell",name="Whirlwind",slot=3,book="spell"}
tips[1]={{"Overpower"},{"Requires Battle Stance",unpack(WHITE)},{"Instantly overpower the enemy...",1,.82,0}}
tips[2]={{"Charge"},{"Requires Battle Stance",unpack(RED)}}
tips[3]={{"Whirlwind"},{"Increases damage in Berserker Stance",1,.82,0}}

-- Empty Slot: always reserves its position, never glows.
assert(D.Resolve({kind="empty"}).name=="Empty Slot")
assert(D.Placement(St({kind="empty"},"hiddenOnCDShift"))=="keep")

-- Shared hide map: shift removes, the others keep the place.
assert(D.Placement(St(charge,"hiddenOnCDShift",{onCD=true}))==nil)
assert(D.Placement(St(charge,"hiddenOnCD",{onCD=true}))=="keep")
assert(D.Placement(St(charge,"hiddenReady",{onCD=false}))=="keep")
assert(D.Placement(St(charge,"hiddenReady",{onCD=false,activeAura=true}))=="show")

-- Hidden Until Usable: cooldown or not usable hides; low resources do not.
assert(D.Placement(St(overpower,"hiddenUnusableShift",{notUsable=true}))==nil)
assert(D.Placement(St(overpower,"hiddenUnusable",{notUsable=true}))=="keep")
assert(D.Placement(St(overpower,"hiddenUnusable",{onCD=true}))=="keep")
assert(D.Placement(St(overpower,"hiddenUnusableShift",{notUsable=false}))=="show")
assert(D.Placement(St({kind="item",id=5},"hiddenUnusableShift",{onCD=true}))==nil)
assert(D.Placement(St({kind="item",id=5},"hiddenUnusableShift",{}))=="show")

-- Hidden Outside Form/Stance: a white "Requires" line is met, red is not.
assert(D.Placement(St(overpower,"hiddenFormShift",{onCD=true}))=="show","met form shows even on cooldown")
assert(D.Placement(St(charge,"hiddenFormShift"))==nil)
assert(D.Placement(St(charge,"hiddenForm"))=="keep")
-- Read once per spell and form.
local r=reads; D.Placement(St(charge,"hiddenForm")); assert(reads==r)
form=2; D.Placement(St(charge,"hiddenForm")); assert(reads==r+1)
-- Description lines naming a stance are not requirements; without casterOK the spell shows.
form=1; assert(D.Placement(St(whirl,"hiddenFormShift",{notUsable=true}))=="show")
-- Caster-form fallback: usable in caster form, unusable while shapeshifted -> outside.
form=0; assert(D.Placement(St(whirl,"hiddenFormShift",{notUsable=false}))=="show")
form=3; assert(D.Placement(St(whirl,"hiddenFormShift",{notUsable=true}))==nil)
assert(D.Placement(St(whirl,"hiddenFormShift",{notUsable=false}))=="show")
-- Items always show; unread tooltips are not cached.
assert(D.Placement(St({kind="item",id=5},"hiddenFormShift"))=="show")
local unread={kind="spell",name="Unread",slot=7,book="spell"}
r=reads; assert(D.Placement(St(unread,"hiddenFormShift"))=="show"); D.Placement(St(unread,"hiddenFormShift")); assert(reads==r+2)
-- Talent / spell changes clear the cache.
form=1; D.WipeFormCache(); r=reads; D.Placement(St(charge,"hiddenForm")); assert(reads==r+1)
''')
print('CDM hide modes and Empty Slot OK')
