"""Execute real search UI handlers, indexing/navigation and page row filtering."""
from pathlib import Path
import runpy

root = Path(__file__).resolve().parents[1]
fixture = runpy.run_path(str(root / 'backport-tools/validate_widgets.py'))
lua = fixture['lua']
lua.execute('''
local E=EllesmereUI
EUI_WOW_335=true
C_AddOns={IsAddOnLoaded=function() return true end}
E._STYLE=setmetatable({}, {__index=function() return .5 end})
E._modules={}; E._widgetRefreshList={}; E.ADDON_ROSTER={}
E._rowCounters={}
E.TEXT_DIM={r=1,g=1,b=1,a=.5}; E.CONTENT_PAD=45
E.MEDIA_PATH="Interface\\\\AddOns\\\\EllesmereUI\\\\media\\\\"
E._IS_STANDALONE=false
E._THEME_BG_FILES={}; E.GetFontPath=function() return "Fonts\\\\FRIZQT__.TTF" end
E.PrimeFontShadow=function() end
E.IsDevModeActive=function() return true end
E.HexColor=function() return "|cff5cc3eb" end
E.lerp=function(a,b,t) return a+(b-a)*t end
E.ResetRowCounters=function() end
E.COLOR_CODES={WHITE="|cffffffff"}
local m=getmetatable(UIParent).__index
function m:GetObjectType() return self.kind end
function m:EnableKeyboard(value) self.keyboard=value end
function m:SetFocus() assert(self.keyboard~=false,"EditBox keyboard disabled"); self.focus=true end
function m:HookScript(event,fn)
 self.hooks[event]=self.hooks[event] or {}; table.insert(self.hooks[event],fn)
end
function m:Run(event,...)
 if self.scripts[event] then self.scripts[event](self,...) end
 for _,fn in ipairs(self.hooks[event] or {}) do fn(self,...) end
end
function m:SetText(v) self.text=v; self:Run("OnTextChanged",true) end
function m:GetChildren()
 local out={}; for _,v in ipairs(self.children) do
  if v.kind~="Texture" and v.kind~="FontString" then out[#out+1]=v end
 end; return unpack(out)
end
function m:SetPoint(...) self.points=self.points or {}; self.points[#self.points+1]={...} end
function m:GetPoint(i) return unpack((self.points or {})[i or 1] or {}) end
function m:ClearAllPoints() self.points={} end
function m:SetClampedToScreen() end
function m:IsMouseOver() return false end
function m:HasScript(event) return event~="OnArrowPressed" end
function m:SetVerticalScroll(v) self.scroll=v end
timers={}
C_Timer.NewTimer=function(delay,fn)
 local t={callback=fn}; function t:Cancel() self.cancelled=true end
 timers[#timers+1]=t; return t
end
C_Timer.After=function(delay,fn) C_Timer.NewTimer(delay,fn) end
function Drain()
 local count=0
 while #timers>0 do
  count=count+1; assert(count<200,"timer loop")
  local t=table.remove(timers,1); if not t.cancelled then t.callback() end
 end
end
debugprofilestop=function() return 0 end
''')
panel = (root / 'EllesmereUI/EllesmereUI_Panel.lua').read_text(encoding='utf-8-sig')
lua.execute(panel)
lua.execute('''
local E=EllesmereUI
local root=CreateFrame("Frame")
local edit=CreateFrame("EditBox",nil,root)
local capture=CreateFrame("Frame",nil,root)
edit:SetFocus(); capture:EnableKeyboard(true)
E.ReleaseWrathPanelKeyboard(root)
assert(not edit.focus and capture.keyboard==false)
assert(edit.keyboard~=false,"panel cleanup permanently disables EditBoxes")
edit:SetFocus(); assert(edit.focus)
E.ReleaseWrathPanelKeyboard(root); assert(not edit.focus)
edit:SetFocus(); assert(edit.focus,"EditBox cannot focus after reopening")
''')
lua.execute('''
local E=EllesmereUI
function SetUp(fn,wanted,value)
 for i=1,100 do
  local n=debug.getupvalue(fn,i); if not n then break end
  if n==wanted then debug.setupvalue(fn,i,value); return end
 end; error("missing upvalue "..wanted)
end
main=CreateFrame("Frame"); content=CreateFrame("Frame"); scroller=CreateFrame("ScrollFrame")
SetUp(E.ApplyInlineSearch,"activeModule","Test")
SetUp(E.ApplyInlineSearch,"activePage","Appearance")
SetUp(E.ApplyInlineSearch,"contentFrame",content)
SetUp(E.ApplyInlineSearch,"scrollFrame",scroller)
SetUp(E.ApplyInlineSearch,"UpdateScrollThumb",function() end)
wrapper=CreateFrame("Frame")
E._pageCache["Test::Appearance"]={wrapper=wrapper,totalH=400}
E._buildingModule="Test"; E._buildingPage="Appearance"
SetUp(E.Widgets.SectionHeader,"TEXT_SECTION",{r=1,g=1,b=1,a=.5})
SetUp(E.Widgets.SectionHeader,"BORDER_COLOR",{r=1,g=1,b=1,a=.1})
SetUp(E.Widgets.DualRow,"RowBg",function() end)
E.Widgets:SectionHeader(wrapper,"APPEARANCE",0)
rowA=E.Widgets:DualRow(wrapper,-40,{type="label",text="Health Bar Texture"},{type="label",text="Fade"})
rowB=E.Widgets:DualRow(wrapper,-90,{type="label",text="Portrait Size"},{type="label",text="Square"})
E.Widgets:SectionHeader(wrapper,"POSITION",-140)
rowC=E.Widgets:DualRow(wrapper,-180,{type="label",text="Horizontal Offset"},{type="label",text="Vertical Offset"})
E._buildingModule=nil; E._buildingPage=nil
-- Test filtering against this real widget cache without a page rebuild.
E.SetLessCommonSearchActive=function(v) E._lessCommonSearchActive=v end
''')
lua.execute('''
EllesmereUI:ApplyInlineSearch("Health",true)
assert(rowA:IsShown() and not rowC:IsShown())
-- Existing behavior retains the matching section's context.
assert(rowB:IsShown())
EllesmereUI:ApplyInlineSearch("",true)
assert(rowA:IsShown() and rowB:IsShown() and rowC:IsShown())
''')
inline_handlers = 'local searchDebounceTimer' + panel.split('local searchDebounceTimer', 1)[1].split('tabBar._searchBox = editBox', 1)[0]
lua.execute('''
moduleBox=CreateFrame("EditBox",nil,main)
local editBox=moduleBox
local placeholder=CreateFrame("Frame")
local clearBtn=CreateFrame("Button")
''' + inline_handlers + '''
EllesmereUI.ReleaseWrathPanelKeyboard(main)
moduleBox:SetFocus(); assert(moduleBox.focus and moduleBox.autoFocus==false)
moduleBox:SetText("Health"); Drain()
assert(rowA:IsShown() and not rowC:IsShown())
moduleBox:SetText("Portrait"); moduleBox:SetText("Health")
moduleBox:Run("OnEscapePressed"); Drain()
assert(moduleBox:GetText()=="" and not moduleBox.focus)
assert(rowA:IsShown() and rowB:IsShown() and rowC:IsShown())
moduleBox:SetFocus(); moduleBox:Run("OnEnterPressed"); assert(not moduleBox.focus)
EllesmereUI.ReleaseWrathPanelKeyboard(main); moduleBox:SetFocus(); assert(moduleBox.focus)
''')

lua.execute('''
local E=EllesmereUI
E.Show=function() end; E.Toggle=function() end; E.ShowModule=function() end
E._clickArea=CreateFrame("Frame")
E._sidebarSearchBox=CreateFrame("EditBox",nil,E._clickArea); E._sidebarSearchBox:SetText("")
E.NavigateToElementSettings=function(self,folder,page,section,pre,label)
 if pre then pre() end; jump={folder,page,section,label}
end
E.SelectModule=function(self,folder) selectedModule=folder end
E.SelectPage=function(self,page) selectedPage=page end
E._modules.Test={title="Unit Frames",pages={"Appearance","Unvisited"},buildPage=function(page,parent,y)
 local W=E.Widgets
 W:SectionHeader(parent,"APPEARANCE",y)
 W:DualRow(parent,y-40,{type="toggle",text="Health Class Color"},{type="slider",text="Portrait Size"})
 return 200
end}
''')
escape = next(line for line in panel.splitlines() if 'sbEdit:SetScript("OnEscapePressed"' in line)
lua.execute('local sbEdit=EllesmereUI._sidebarSearchBox\n' + escape)
lua.execute('EUI335={IsWrath=true}; local m=getmetatable(UIParent).__index; function m:SetFrameStrata(s) self.strata=s end')
lua.execute((root / 'EllesmereUI/EllesmereUI_GlobalSearch.lua').read_text(encoding='utf-8-sig'))
lua.execute('''
local E=EllesmereUI
E:Show()
local box=E._sidebarSearchBox
E.ReleaseWrathPanelKeyboard(E._clickArea); box:SetFocus(); assert(box.focus)
assert(box.hooks.OnTextChanged and #box.hooks.OnTextChanged==1)
box:SetText("Health Class"); Drain()
local found
for _,f in ipairs(allFrames) do
 if f._label and f._label:GetText()=="Health Class Color" and f:IsShown() then found=f end
end
assert(found,"feature search has no row for unvisited page")
-- Wrath: the results list lives outside the panel so the sidebar/page can't draw over it.
local popup=found:GetParent():GetParent()
assert(popup:GetParent()==UIParent and popup:IsShown(),'search popup still parented inside the panel')
popup.strata=nil; popup:Run("OnShow"); assert(popup.strata=="FULLSCREEN_DIALOG",'strata not reapplied on show')
assert(E._searchPopup==popup,'search popup not exposed for in-game checks')
local bg; for _,c in ipairs(popup.children) do if c.kind=="Texture" then bg=c; break end end
assert(bg and bg.texture=="Interface\\\\Buttons\\\\WHITE8X8",'search list background not a file texture on Wrath')
assert(popup.scripts.OnUpdate,'no next-frame strata lift')
popup.strata=nil; popup:Run("OnUpdate")
assert(popup.strata=="FULLSCREEN_DIALOG" and not popup.scripts.OnUpdate,'next-frame lift did not run once')
E._clickArea:Run("OnHide"); assert(not popup:IsShown(),'popup outlived the panel'); popup:Show()
found:Run("OnClick"); assert(jump and jump[1]=="Test" and jump[4]=="Health Class Color")
assert(box:GetText()=="")
E:Show(); E:Toggle(); assert(#box.hooks.OnTextChanged==1)
box:SetText("zzzzzzzz"); Drain()
box:Run("OnEscapePressed"); assert(box:GetText()=="")
''')
print('PASS: Wrath keyboard/focus cleanup and reopen; feature popup/hidden indexing/result navigation and module filtering/restoration')
