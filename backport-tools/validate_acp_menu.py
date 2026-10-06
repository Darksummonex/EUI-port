"""Exercise ACP's actual XML callbacks against stock/custom/EUI menu chains."""
from pathlib import Path
import sys
import xml.etree.ElementTree as ET
from game_paths import ADDONS, DATA, WTF
root=Path(__file__).resolve().parents[1]
if not (ADDONS/'ACP/ACP.lua').exists():
    print('SKIP: optional ACP addon is not installed.'); raise SystemExit(0)
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
source=(ADDONS/'ACP/ACP.lua').read_text(encoding='utf-8-sig')
xml=ET.parse(ADDONS/'ACP/ACP.xml').getroot()
button=next(n for n in xml.iter() if n.attrib.get('name')=='GameMenuButtonAddOns')
scripts=next(n for n in button if n.tag.split('}')[-1]=='Scripts')
callbacks={n.tag.split('}')[-1]:n.text for n in scripts}
for with_eui in [False,True]:
    for extended in [False,True]:
        lua=LuaRuntime()
        lua.execute((root/'backport-tools/wrath_mock.lua').read_text())
        lua.execute('''
combat=false; EUI335={IsWrath=true}
function InCombatLockdown() return combat end
function IsLoggedIn() return true end
local m=getmetatable(UIParent).__index
function m:GetPoint(i) return unpack((self.points or {})[i or 1] or {}) end
function m:ClearAllPoints() self.points={} end
function m:SetPoint(...) assert(not combat,'Combat menu mutation'); self.points={{...}} end
function m:GetChildren() return unpack(self.children) end
function m:GetTop(seen)
 if self==GameMenuFrame then return 600 end
 seen=seen or {}; assert(not seen[self],'Circular menu anchors'); seen[self]=true
 local point,relative,relativePoint,_,y=self:GetPoint(1)
 relative=type(relative)=='string' and _G[relative] or relative
 if not relative then return nil end
 local top=relative:GetTop(seen); if not top then return end
 local edge=relativePoint=='BOTTOM' and top-relative:GetHeight() or top
 return edge+(y or 0)
end
function m:GetBottom() local top=self:GetTop(); return top and top-self:GetHeight() end
function m:HookScript(event,fn) self.hooks[event]=self.hooks[event] or {}; table.insert(self.hooks[event],fn) end
function m:RunScript(event,...) if self.scripts[event] then self.scripts[event](self,...) end; for _,fn in ipairs(self.hooks[event] or {}) do fn(self,...) end end
function m:Show() self.shown=true; self:RunScript('OnShow') end
function m:Hide() self.shown=false; self:RunScript('OnHide') end
function MenuButton(name,relative,gap)
 local b=CreateFrame('Button',name,GameMenuFrame); b:SetWidth(144); b:SetHeight(21)
 b:SetPoint('TOP',relative,'BOTTOM',0,gap or -1); return b
end
GameMenuFrame=CreateFrame('Frame','GameMenuFrame',UIParent); GameMenuFrame:SetHeight(240); GameMenuFrame:Hide()
GameMenuButtonOptions=MenuButton('GameMenuButtonOptions',GameMenuFrame); GameMenuButtonOptions:SetPoint('TOP',GameMenuFrame,'TOP',0,-26)
GameMenuButtonKeybindings=MenuButton('GameMenuButtonKeybindings',GameMenuButtonOptions)
GameMenuButtonMacros=MenuButton('GameMenuButtonMacros',GameMenuButtonKeybindings)
GameMenuButtonLogout=MenuButton('GameMenuButtonLogout',GameMenuButtonMacros)
GameMenuButtonQuit=MenuButton('GameMenuButtonQuit',GameMenuButtonLogout)
GameMenuButtonContinue=MenuButton('GameMenuButtonContinue',GameMenuButtonQuit,-16)
GameMenuButtonAddOns=MenuButton('GameMenuButtonAddOns',GameMenuButtonMacros)
function NativeMenuLayout()
 GameMenuButtonLogout:ClearAllPoints(); GameMenuButtonLogout:SetPoint('TOP',GameMenuButtonMacros,'BOTTOM',0,-1)
 GameMenuFrame:SetHeight(240)
end
GameMenuFrame:SetScript('OnShow',NativeMenuLayout)
''')
        lua.execute('assert(loadstring(...))',source)
        lua.execute(source[:source.index('ACP_LINEHEIGHT =')])
        for event,body in callbacks.items():
            lua.globals().GameMenuButtonAddOns.SetScript(lua.globals().GameMenuButtonAddOns,event,lua.eval('function(self) '+body+' end'))
        lua.execute("GameMenuButtonAddOns:RunScript('OnLoad')")
        if extended:
            lua.execute('''
local store=MenuButton('GameMenuButtonRebuffedStore',GameMenuButtonKeybindings)
local help=MenuButton('GameMenuButtonHelpSupport',store)
local client=MenuButton('GameMenuButtonRebuffed',help)
GameMenuButtonMacros:ClearAllPoints(); GameMenuButtonMacros:SetPoint('TOP',client,'BOTTOM',0,-1)
''')
        if with_eui:
            lua.execute((root/'EllesmereUI/EUI_OptionsAccess_335.lua').read_text())
        lua.execute('''
local macrosRelative=select(2,GameMenuButtonMacros:GetPoint(1))
local function Open()
 GameMenuFrame:Show(); GameMenuButtonAddOns:RunScript('OnShow')
 ACP.menuLayoutEvents:RunScript('OnUpdate',.01)
 assert(not ACP.menuLayoutEvents.scripts.OnUpdate)
 local buttons={}
 for _,b in ipairs(GameMenuFrame.children) do if b:IsObjectType('Button') and b:IsShown() then buttons[#buttons+1]=b end end
 for i,a in ipairs(buttons) do
  for j=i+1,#buttons do local b=buttons[j]; assert(a:GetBottom()>=b:GetTop() or b:GetBottom()>=a:GetTop(),'Overlapping buttons: '..tostring(a.text)..' / '..tostring(b.text)) end
  assert(GameMenuFrame:GetTop()-a:GetBottom()+16<=GameMenuFrame:GetHeight(),'Clipped menu button')
 end
 assert(select(2,GameMenuButtonMacros:GetPoint(1))==macrosRelative,'ACP moved native/client Macros anchor')
end
Open(); local height=GameMenuFrame:GetHeight()
for i=1,20 do
 GameMenuFrame:Hide(); assert(not ACP.menuLayoutEvents.scripts.OnUpdate)
 Open(); assert(GameMenuFrame:GetHeight()==height,'Menu height drifted')
end
-- Re-running layout preserves another addon's insertion and never makes a cycle.
local other=MenuButton('AnotherAddonMenuButton',GameMenuButtonAddOns)
GameMenuButtonLogout:ClearAllPoints(); GameMenuButtonLogout:SetPoint('TOP',other,'BOTTOM',0,-1)
ACP:LayoutGameMenu(); assert(select(2,GameMenuButtonLogout:GetPoint(1))==other)
-- Combat prevents writes; the next regen retry restores the extended layout.
combat=true; ACP:LayoutGameMenu(); GameMenuFrame:Hide(); GameMenuFrame.shown=true
ACP:ScheduleGameMenuLayout(); ACP.menuLayoutEvents:RunScript('OnUpdate',.01)
combat=false; NativeMenuLayout(); ACP.menuLayoutEvents:RunScript('OnEvent','PLAYER_REGEN_ENABLED')
ACP.menuLayoutEvents:RunScript('OnUpdate',.01)
assert(select(2,GameMenuButtonLogout:GetPoint(1))==GameMenuButtonAddOns)
GameMenuFrame:Hide(); ACP:ScheduleGameMenuLayout(); ACP.menuLayoutEvents:RunScript('OnUpdate',.01)
assert(not ACP.menuLayoutEvents.scripts.OnUpdate)
''')
print('PASS: full ACP Lua compiles; real XML callbacks and deferred insertion with stock/custom menus, EUI enabled/disabled, no overlap/cycles/clipping, 20 reopen cycles without height drift, other addon insertion, combat/regen and hidden-menu cleanup.')
