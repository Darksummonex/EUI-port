"""Exercise the actual visibility checklist logic with optional spec APIs absent/present."""
from pathlib import Path
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

lua = LuaRuntime()
lua.execute((root / 'backport-tools/wrath_mock.lua').read_text())
lua.execute('''
EllesmereUI._deferredInits={}
EllesmereUI.L=function(s) return s end
EllesmereUI.RegisterWidgetRefresh=function() end
EllesmereUI.RefreshPage=function() end
''')
for name in ['EllesmereUI/EllesmereUI_VisibilityRules.lua',
             'EllesmereUI/EllesmereUI_Visibility.lua',
             'EllesmereUIOptions/EllesmereUI_Widgets.lua']:
    lua.execute((root / name).read_text(encoding='utf-8-sig'))

lua.execute('''
-- Replace only row/dropdown drawing. Keep actual BuildVisibilityRow,
-- AttachVisibilityChecklist and Core selection read/write semantics.
local E=EllesmereUI
function E.BuildVisOptsCBDropdown(parent, width, level, items, get, set, _, _, _, _, closed, config)
    local control=CreateFrame("Button",nil,parent)
    control.get,control.set,control.config,control.items=get,set,config,items
    local function refresh()
        config.ovLockedFn()
        config.ovHeldFn()
        config.separatorFn()
        for _, item in ipairs(items) do
            if item.key then get(item.key); get(item.key,true) end
            if item.ovLockedFn then item.ovLockedFn() end
            if type(item.tooltip)=="function" then item.tooltip() end
        end
    end
    refresh()
    return control,refresh
end
local Factory={}
function Factory:DualRow(parent,y,left,right)
    local row=CreateFrame("Frame",nil,parent)
    row._leftRegion=CreateFrame("Frame",nil,row)
    row._rightRegion=CreateFrame("Frame",nil,row)
    return row,50
end
local store={barVisibility="always"}
local changes=0
local opts={getStore=function() return store end,legacyKey="barVisibility",
    onChanged=function() changes=changes+1 end}
assert(not E.SpecOverrides_EditSessionActive and not E.SpecOverrides_SlotOverridable)
local row,height=E.BuildVisibilityRow(Factory,UIParent,-96,opts,{type="toggle",text="Show Nicknames"})
assert(height==50)
local dd=row._leftRegion._control
assert(dd.config.ovLockedFn()==false and dd.get("always"))
dd.set("combat",true)
assert(store.barVisibility=="in_combat" and dd.get("combat"))
dd.set("never",true)
assert(store.barVisibility=="never" and dd.get("never") and not dd.get("combat"))
dd.set("always",true)
assert(store.barVisibility=="always" and changes==3)
-- An explicit shared edit releases a stale marker even without the spec system.
store.visibilityOverride="never"
dd.set("combat",true)
assert(store.visibilityOverride==nil and store.barVisibility=="in_combat")
-- Keep the existing spec behavior when the optional system is actually supplied.
E.SpecOverrides_EditSessionActive=function() return true end
E.SpecOverrides_SlotOverridable=function() return true end
store.visibilityOverride="never"
row=E.BuildVisibilityRow(Factory,UIParent,0,opts)
dd=row._leftRegion._control
assert(dd.config.ovLockedFn() and dd.get("never"))
dd.set("never",true)
assert(store.visibilityOverride==nil and store.barVisibility=="in_combat")
local clearCalls=0
E.SpecOverrides_ClearStoreKey=function(stores,key)
    clearCalls=clearCalls+1
    assert(stores[1]==store and key=="visibilityOverride" and store[key]==nil)
end
dd.set("always",true); assert(store.visibilityOverride=="always")
dd.set("always",true); assert(store.visibilityOverride==nil and clearCalls==1)
-- Excluded slots still edit shared visibility while another slot's session is open.
E.SpecOverrides_SlotOverridable=function() return false end
dd.set("always",true); assert(store.barVisibility=="always" and not store.visibilityOverride)
-- Ownership cleanup is guarded and does not run inside an active edit session.
E.SpecOverrides_KeyIsOwned=function() return false end
store.visibilityOverride="never"
E.BuildVisibilityRow(Factory,UIParent,0,opts)
assert(store.visibilityOverride=="never")
E.SpecOverrides_EditSessionActive=function() return false end
E.BuildVisibilityRow(Factory,UIParent,0,opts)
assert(store.visibilityOverride==nil)
-- Both supported row arrangements attach independent controls.
local other={barVisibility="never"}
opts.rightVis={getStore=function() return other end,legacyKey="barVisibility"}
row=E.BuildVisibilityRow(Factory,UIParent,0,opts)
assert(row._leftRegion._control.get("always") and row._rightRegion._control.get("never"))
opts.rightVis=nil; opts.leftCfg={type="label",text="Left"}
row=E.BuildVisibilityRow(Factory,UIParent,0,opts)
assert(row._rightRegion._control.get("always"))
''')
print('PASS: actual visibility rows; missing/present spec APIs, shared writes, override clearing/ownership, excluded slots, dual/right checklists.')
