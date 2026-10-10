"""Execute the theme palette and actual Presets navigation/style callbacks in Lua 5.1."""
from pathlib import Path
import sys
from PIL import Image

root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute((root / 'backport-tools/wrath_mock.lua').read_text(encoding='utf-8-sig'))
ns = lua.table()
lua.execute((root / 'EllesmereUIUnitFrames/EUI_UnitFrames_335.lua').read_text(encoding='utf-8-sig'), 'EllesmereUIUnitFrames', ns)
lua.globals().W335 = ns.Wrath
lua.execute('''
CreateFrame=W335.CreateFrame
local E=EllesmereUI
EUI_WOW_335=true
faction="Alliance"
UnitFactionGroup=function() return faction end
E.RefreshPage=function() refreshes=(refreshes or 0)+1 end
E._InvalidateConfirmPopup=function() end
E._accentElements={}
E.ELLESMERE_GREEN={r=0,g=0,b=0}
E.DEFAULT_ACCENT_R,E.DEFAULT_ACCENT_G,E.DEFAULT_ACCENT_B=12/255,210/255,157/255
E.CLASS_COLOR_MAP={WARRIOR={r=.78,g=.61,b=.43}}
E._playerClass="WARRIOR"
E.GetActiveProfileData=function() return EllesmereUIDB.profiles.Default end
E.PanelPP=E.PP
E.L=function(s) return s end
E.Lf=function(s,...) return s end
E.MakeBorder=function() return {SetColor=function() end} end
widgetRefreshes={}
E.RegisterWidgetRefresh=function(fn) widgetRefreshes[#widgetRefreshes+1]=fn end
CreateColor=function(r,g,b,a) return {r=r,g=g,b=b,a=a} end
''')
core = (root / 'EllesmereUI/EllesmereUI.lua').read_text(encoding='utf-8-sig')
config = 'local THEME_PRESETS =' + core.split('local THEME_PRESETS =', 1)[1].split('-- Hidden 1x1 frame', 1)[0]
lua.execute(config + '\nEllesmereUI.THEME_PRESETS=THEME_PRESETS; EllesmereUI.THEME_ORDER=THEME_ORDER; EllesmereUI._THEME_BG_FILES=THEME_BG_FILES; EllesmereUI._ResolveFactionTheme=ResolveFactionTheme')
e = lua.globals().EllesmereUI
for _, file in e._THEME_BG_FILES.items():
    p = root / 'EllesmereUI/media' / file.replace('\\', '/')
    assert p.suffix == '.tga' and p.is_file(), file
    with Image.open(p) as im:
        assert im.size == (1024, 1024) and im.mode == 'RGBA', file
    assert e.THEME_CLOSE_BOX[file] is not None, file
for file in [e.OPTIONS_BASE_BG, e.THEME_ACCENT_OVERLAYS['Pixels'].file]:
    assert (root / 'EllesmereUI/media' / file.replace('\\', '/')).is_file()

def native_texture(path):
    if not isinstance(path, str):
        return
    if not path.startswith('Interface\\AddOns\\EllesmereUI\\media\\'):
        return
    assert path.endswith('.tga'), path
    p = root / path.replace('\\', '/').split('Interface/AddOns/', 1)[1]
    assert p.is_file(), path
    with Image.open(p) as im:
        w, h = im.size
        assert w & (w - 1) == 0 and h & (h - 1) == 0 and im.mode == 'RGBA', path

lua.globals().checkNativeTexture = native_texture
lua.execute('''
local methods=getmetatable(CreateFrame("Frame")).__index
methods.SetTexture=function(self,path) checkNativeTexture(path); self.texture=path end
methods.SetAlpha=function(self,a) self.alpha=a end
methods.GetAlpha=function(self) return self.alpha or 1 end
methods.SetDrawLayer=function(self,layer) self.layer=layer end -- ignore Retail sublevels
local createTexture=methods.CreateTexture
methods.CreateTexture=function(self,name,layer,...) local t=createTexture(self,name,layer,...); t.layer=layer or "ARTWORK"; return t end
''')
preload = core.split('-- Hidden 1x1 frame', 1)[1].split('-- EllesmereUIDB arrives', 1)[0]
lua.execute('local THEME_BG_FILES=EllesmereUI._THEME_BG_FILES\n-- Hidden 1x1 frame' + preload)
lua.execute('EllesmereUI._PreloadLazyThemeBG("Pixels")')

ui = (root / 'EllesmereUI/EllesmereUI_UICore.lua').read_text(encoding='utf-8-sig')
api = ui.split('-- Theme API -- exposed', 1)[1].split('--  ShowContextMenu', 1)[0]
lua.execute('local ELLESMERE_GREEN=EllesmereUI.ELLESMERE_GREEN\n-- Theme API -- exposed' + api)
lua.execute('''
local E=EllesmereUI
EllesmereUIDB={activeProfile="Default", profiles={Default={euiAccent={custom={r=.8,g=.2,b=.1},useClass=false}}}}
E._applyThemeBG=function(theme,r,g,b) applied={theme,r,g,b} end
E._accentElements[1]={type="callback",fn=function(r,g,b) menuColor={r,g,b} end}
local seen={}
for _,theme in ipairs(E.THEME_ORDER) do
 assert(not seen[theme]); seen[theme]=true
 E.SetActiveTheme(theme) -- API itself must update registered menu elements
 local r,g,b=E.ResolveThemeColor(theme)
 assert(E.ELLESMERE_GREEN.r==r and E.ELLESMERE_GREEN.g==g and E.ELLESMERE_GREEN.b==b)
 assert(menuColor[1]==r and menuColor[2]==g and menuColor[3]==b)
 assert(applied[1]==theme)
end
assert(seen["Lich King"])
E.SetActiveTheme("Lich King"); E.RefreshAccent()
assert(E.ELLESMERE_GREEN.r==92/255 and E.ELLESMERE_GREEN.g==195/255 and E.ELLESMERE_GREEN.b==235/255)
assert(EllesmereUIDB.profiles.Default.euiAccent.custom.r==.8)
EllesmereUIDB.themeAccentMatch=false; E.RefreshAccent(); assert(E.ELLESMERE_GREEN.r==.8)
EllesmereUIDB.themeAccentMatch=true
E.SetAccentColor(.2,.3,.4); assert(EllesmereUIDB.themeAccentMatch==false)
assert(E.ELLESMERE_GREEN.r==.2)
EllesmereUIDB.themeAccentMatch=true
E.SetActiveProfileAccent(nil,true); E.RefreshAccent(); assert(E.ELLESMERE_GREEN.r==.78)
EllesmereUIDB.themeAccentMatch=true
E.SetActiveTheme("Faction (Auto)"); faction="Horde"; E.RefreshAccent()
assert(E.ELLESMERE_GREEN.g==90/255)
E.SetActiveTheme("Class Colored"); E.RefreshAccent(); assert(E.ELLESMERE_GREEN.r==.78)
assert(select(1,E.GetActiveAccentState())==true)
E.ResetTheme(); assert(EllesmereUIDB.themeAccentMatch==nil and E.GetActiveTheme()=="EllesmereUI")
EUI_WOW_335=false; E.RefreshAccent(); assert(E.ELLESMERE_GREEN.r==.78)
EUI_WOW_335=true
''')
panel = (root / 'EllesmereUI/EllesmereUI_Panel.lua').read_text(encoding='utf-8-sig')
# Execute actual initial layer construction with a Wrath renderer that ignores
# all Retail sublevels. The opaque base must be below both selectable images.
layers = 'local bgBase = ' + panel.split('local bgBase = ',1)[1].split('-- Track which layer',1)[0]
lua.execute('''
local bgFrame=CreateFrame("Frame")
local MEDIA_PATH="Interface\\\\AddOns\\\\EllesmereUI\\\\media\\\\"
''' + layers + '''
bgBase:SetDrawLayer("BACKGROUND")
assert(bgA.layer=="BORDER" and bgB.layer=="BORDER" and bgBase.layer=="BACKGROUND")
''')
tint = 'function tbox.TintColor' + panel.split('function tbox.TintColor', 1)[1].split('local function ApplyBgTintToLayer', 1)[0]
lua.execute('local tbox={}\n' + tint + '\nassert(tbox.TintColor("Lich King",.2,.4,.8)==nil)')
apply = 'local function ApplyThemeBG' + panel.split('local function ApplyThemeBG', 1)[1].split('-- For tint-only updates', 1)[0]
lua.execute('''
local E=EllesmereUI
local ResolveFactionTheme=E._ResolveFactionTheme
local THEME_BG_FILES=E._THEME_BG_FILES
local MEDIA_PATH="Interface\\\\AddOns\\\\EllesmereUI\\\\media\\\\"
local bgFront,bgBack=CreateFrame("Frame"):CreateTexture(),CreateFrame("Frame"):CreateTexture()
local bgFadeTicker=CreateFrame("Frame")
local bgFadeProgress=1
local tbox={front={},back={},Layer=function() end, Paint=function() end,Alpha=function(set,a) set.alpha=a end}
local function ApplyBgTintToLayer() end
local function ApplyThemeAccentOverlay() end
''' + apply + '''
for _,theme in ipairs(E.THEME_ORDER) do
 ApplyThemeBG(theme,E.ResolveThemeColor(theme))
 assert(bgFront.texture==MEDIA_PATH..(THEME_BG_FILES[ResolveFactionTheme(theme)] or THEME_BG_FILES.EllesmereUI))
 assert(bgFadeProgress==1 and not bgFadeTicker:IsShown())
 assert(bgFront:GetAlpha()==1 and bgBack:GetAlpha()==0)
 assert(bgFront.layer=="BORDER" and bgBack.layer=="BORDER")
 assert(tbox.front.alpha==1 and tbox.back.alpha==0)
 assert(E._bgTexture==bgFront)
end
-- Even rapid choices while the window is hidden must leave just one visible
-- image, independent of legacy creation order/ignored texture sublevels.
ApplyThemeBG("Pixels",1,1,1); ApplyThemeBG("Lich King",E.ResolveThemeColor("Lich King"))
assert(bgFront.texture:find("lichking") and bgFront:GetAlpha()==1 and bgBack:GetAlpha()==0)
EUI_WOW_335=false; ApplyThemeBG("Horde",1,.2,0)
assert(bgFadeProgress==0 and bgFadeTicker:IsShown()) -- retain Retail crossfade
EUI_WOW_335=true
''')

# Execute the real overlay helper: Pixel art must disappear immediately on
# Wrath rather than waiting for a hidden crossfade ticker.
overlay='local function ApplyThemeAccentOverlay'+panel.split('local function ApplyThemeAccentOverlay',1)[1].split('--- Apply the full theme:',1)[0]
lua.execute('''
local bgFrame=CreateFrame("Frame")
local MEDIA_PATH="Interface\\\\AddOns\\\\EllesmereUI\\\\media\\\\"
local ELLESMERE_GREEN=EllesmereUI.ELLESMERE_GREEN
local function RegAccent() end
''' + overlay + '''
ApplyThemeAccentOverlay("Pixels",false)
assert(bgFrame._accentOverlay:IsShown() and bgFrame._accentOverlay:GetAlpha()==1)
assert(bgFrame._accentOverlay.layer=="ARTWORK")
ApplyThemeAccentOverlay("Lich King",false)
assert(not bgFrame._accentOverlay:IsShown() and bgFrame._accentOverlay.texture==nil and bgFrame._accentOverlayDir==nil)
ApplyThemeAccentOverlay("Pixels",false); ApplyThemeAccentOverlay("Horde",true)
assert(bgFrame._accentOverlayDir==-1) -- animated Retail path
''')

# General Options registers the real callbacks; no mock replacement of the
# restored Presets builder or SelectPage interception.
lua.execute('''
local E=EllesmereUI
registrations={}; selected={}
E.RegisterModule=function(self,key,cfg) registrations[key]=cfg end
E.SelectPage=function(self,page,...) selected[#selected+1]=page end
E.GetActiveModule=function() return "_EUIProfiles" end
E.RegisterOnShow=function() end; E.RegisterOnHide=function() end
E.ModuleNS=function() return nil end
E.GetFontOutlineFlag=function() return "" end
E.SetCVar=function() end
E.GetPlayerClassColor=function() return .78,.61,.43 end
GetCVar=function() return "0" end
GetCVarDefault=function() return "0" end
C_CVar.GetCVarInfo=function() return "1","0" end
SetCVar=function() end
IsLoggedIn=function() return false end
''')
lua.execute((root / 'EllesmereUIOptions/EUI__General_Options.lua').read_text(encoding='utf-8-sig'), 'EllesmereUIOptions')
lua.execute('''
for _,f in ipairs(allFrames) do
 if f.events.PLAYER_LOGIN and f:GetScript("OnEvent") then f:GetScript("OnEvent")(f,"PLAYER_LOGIN") end
end
assert(registrations._EUIProfiles)
EllesmereUI:SelectPage("Presets"); assert(selected[#selected]=="Presets")
''')
general = (root / 'EllesmereUIOptions/EUI__General_Options.lua').read_text(encoding='utf-8-sig')
display = 'local themeValues = {}' + general.split('local themeValues = {}', 1)[1].split('-- The custom background tint swatch', 1)[0]
lua.execute('''
local E=EllesmereUI
themeControls={}
E.Widgets={DualRow=function(self,parent,y,left,right)
 themeControls[left.text]=left; themeControls[right.text]=right
 return {},50
end}
local W=E.Widgets
local parent=CreateFrame("Frame",nil,UIParent)
local y=0
local _,h
''' + display + '''
local menu=themeControls["EUI Options Theme"]
local match=themeControls["Match Accent to Theme"]
assert(menu.values["Lich King"]=="Lich King")
match.setValue(true); menu.setValue("Lich King")
assert(menu.getValue()=="Lich King" and E.ELLESMERE_GREEN.b==235/255)
match.setValue(false); assert(match.getValue()==false and E.ELLESMERE_GREEN.r==.78)
match.setValue(true)
''')
lua.execute('''
local E=EllesmereUI
uf={useBlizzardStyle=false,useClassicStyle=false,playerAuraBars={}}
mm={useBlizzardStyle=false,useClassicStyle=false}
E._ModuleNS={EllesmereUIUnitFrames={db={profile=uf}}, EllesmereUIMinimap={},
 EllesmereUIActionBars={IsWrath=true},EllesmereUINameplates={IsWrath=true},
 EllesmereUIChat={IsWrath=true},EllesmereUIBlizzardSkin={IsWrath=true},
 EllesmereUIResourceBars={IsWrath=true},EllesmereUIBags={IsWrath=true},EllesmereUIRaidFrames={IsWrath=true,db={profile={}}}}
_EMM_DB={profile={minimap=mm}}
E.SolidTex=function(parent) return parent:CreateTexture() end
E.CONTENT_PAD=45
E.ShowConfirmPopup=function(self,opts) pending=opts end
-- Retail 9.4 look dropdowns: capture each card's checklist and Apply Styles.
styleMenus={}
E.BuildVisOptsCBDropdown=function(parent,w,lvl,items,getFn,setFn,onChanged,maxVis,s,c,closed,opts)
 assert(opts and opts.dimLocked)
 local dd=CreateFrame("Button",nil,parent)
 styleMenus[#styleMenus+1]={items=items,get=getFn,set=setFn,changed=onChanged,dd=dd}
 return dd,function() end
end
E.MakeStyledButton=function(btn,text,size,colours,fn) if text=="Apply Styles" then applyStyles=fn; applyBtn=btn end end
''')
lua.execute((root / 'EllesmereUI/EllesmereUI_StyleCards.lua').read_text(encoding='utf-8-sig'))
lua.execute((root / 'EllesmereUIOptions/EUI_Style_Options.lua').read_text(encoding='utf-8-sig'))
lua.execute('''
local E=EllesmereUI
-- Capture handles while still building the real art and click handlers.
local real=E.BuildStyleCards
E.BuildStyleCards=function(...) cards=real(...); return cards end
local p=CreateFrame("Frame",nil,UIParent); p:SetWidth(900)
local profiles=registrations._EUIProfiles
local height=profiles.buildPage("Presets",p,0)
assert(height>300 and cards.eui and cards.blizzard and cards.classic)
cards.blizzard.card:GetScript("OnClick")(cards.blizzard.card)
assert(pending and pending.reload and pending.confirmText=="Reload Now")
assert(uf.useBlizzardStyle==false and mm.useBlizzardStyle==false)
-- Cancelling/closing writes nothing. Confirming changes supported modules.
-- Minimap draws no Blizzard Style on Wrath: Apply to All leaves it alone.
pending.onConfirm(); assert(uf.useBlizzardStyle and not mm.useBlizzardStyle)
for _,fn in ipairs(widgetRefreshes) do fn() end
-- One checklist per look card; a look a module cannot draw leaves it out.
assert(#styleMenus==3 and applyStyles and applyBtn)
for _,menu in ipairs(styleMenus) do
 local labels={}
 for _,it in ipairs(menu.items) do
  assert(it.label~="Resource Bars" and it.label~="Player Cast Bar" and it.label~="Raid Frames"
   and it.label~="Player Aura Bars", "unimplemented Retail styles exposed on Wrath")
  labels[it.label]=it
 end
 menu.labels=labels
end
for _,menu in ipairs(styleMenus) do
 if menu.get("unitframes") then assert(menu.labels["Unit Frames"].lockedFn(), "a module's current look is locked") end
end
local classic
for _,menu in ipairs(styleMenus) do
 if menu.labels["Damage Meters"] and not menu.get("damagemeters") and menu.labels["Minimap"] and not menu.get("minimap") then classic=menu end
end
assert(classic, "Classic list offers Minimap and Damage Meters")
local blizz
for _,menu in ipairs(styleMenus) do
 if not menu.labels["Minimap"] and not menu.labels["Damage Meters"] then blizz=menu end
end
assert(blizz and blizz.labels["Unit Frames"], "Blizzard list leaves out looks Wrath cannot draw")
-- Picks write nothing until Apply Styles; its prompt moves only the picks.
pending=nil
classic.set("minimap",true); classic.changed()
assert(classic.get("minimap") and not mm.useClassicStyle and applyBtn:GetAlpha()==1)
applyStyles(); assert(pending and pending.reload); pending.onConfirm()
assert(mm.useClassicStyle and uf.useBlizzardStyle, "Apply Styles moved Minimap only")
for _,fn in ipairs(widgetRefreshes) do fn() end
assert(applyBtn:GetAlpha()==.3, "no picks left after the switch")
mm.useClassicStyle=false
for _,fn in ipairs(widgetRefreshes) do fn() end
cards.classic.card:GetScript("OnClick")(cards.classic.card); pending.onConfirm()
assert(uf.useClassicStyle and not uf.useBlizzardStyle and mm.useClassicStyle)
for _,fn in ipairs(widgetRefreshes) do fn() end
cards.eui.card:GetScript("OnClick")(cards.eui.card); pending.onConfirm()
assert(not uf.useClassicStyle and not uf.useBlizzardStyle and not mm.useClassicStyle)
profiles.onPageCacheRestore("Presets")
E._prebuilding=true; local before=#allFrames
assert(profiles.buildPage("Presets",p,0)>0 and #allFrames==before)
E._prebuilding=nil
''')
# Real sidebar module rows: Wrath-loadable power/sync/download icons and the
# Disable & Reload confirmation for each installed module.
core_icons = core.split('-- Shared icon paths', 1)[1].split('EllesmereUI.EYE_VISIBLE_ICON', 1)[0]
lua.execute('local MEDIA_PATH="Interface\\\\AddOns\\\\EllesmereUI\\\\media\\\\"\n' + core_icons)
row_fn = 'local function CreateAddonChildRow' + panel.split('local function CreateAddonChildRow', 1)[1].split('\n        return btn\n    end\n', 1)[0] + '\n        return btn\n    end\n'
lua.execute('''
local E=EllesmereUI
E.MEDIA_PATH="Interface\\\\AddOns\\\\EllesmereUI\\\\media\\\\"
E._syncExempt={}; E._syncGlobalOnly={}
E.IsProfileSynced=function() return false end
EllesmereUIDB.profiles.Second={}
local methods=getmetatable(CreateFrame("Frame")).__index
methods.SetWordWrap=methods.SetWordWrap or function() end
methods.SetMaxLines=methods.SetMaxLines or function() end
loadedAddons={EllesmereUIDamageMeters=true}
disabled={}; enabled={}; C_AddOns=C_AddOns or {}
C_AddOns.DisableAddOn=function(f) disabled[#disabled+1]=f end
C_AddOns.EnableAddOn=function(f) enabled[#enabled+1]=f end
GetAddOnInfo=function(f) if f=="EllesmereUIMythicTimer" then return f,nil,nil,nil,nil,"MISSING" end; return f,f,"",1,1,nil,"INSECURE" end
''')
lua.execute('''
local E=EllesmereUI
local addonScrollChild=CreateFrame("Frame",nil,UIParent)
local SIDEBAR_W,CHILD_ROW_H,CHILD_INDENT_X=200,28,30
local ICONS_PATH=E.MEDIA_PATH.."icons\\\\"
local IS_STANDALONE=false
local IsAddonLoaded=function(f) return loadedAddons[f]==true end
local C={r=1,g=1,b=1,a=1}
local TEXT_DIM,NAV_DISABLED_TEXT,NAV_ENABLED_TEXT,NAV_HOVER_ENABLED_TEXT,NAV_HOVER_DISABLED_TEXT=C,C,C,C,C
local activeModule,modules=nil,{}
local function DecorateSidebarButton() end
local function MakeFont(parent) return parent:CreateFontString() end
local function SolidTex(parent) return parent:CreateTexture() end
''' + row_fn + '''
local meters=CreateAddonChildRow({folder="EllesmereUIDamageMeters",display="Damage Meters"})
local bags=CreateAddonChildRow({folder="EllesmereUIBags",display="Bags"})
local mythic=CreateAddonChildRow({folder="EllesmereUIMythicTimer",display="Mythic+ Tools"})
local party=CreateAddonChildRow({folder="EllesmereUIPartyMode",display="Party Mode",alwaysLoaded=true})
assert(meters._pwrBtn and bags._pwrBtn and not mythic._pwrBtn and not party._pwrBtn)
assert(meters._pwrBtn._tex.texture:find("icons_335\\\\power.tga",1,true) and meters._dlIcon.texture:find("icons_335",1,true))
assert(meters._syncBtn and meters._syncBtn._tex.texture:find("icons_335\\\\sync.tga",1,true))
pending=nil; meters._pwrBtn:GetScript("OnClick")(meters._pwrBtn)
assert(pending and pending.reload and pending.confirmText=="Disable & Reload" and pending.cancelText=="Cancel")
pending.onConfirm(); assert(disabled[1]=="EllesmereUIDamageMeters" and #enabled==0)
pending=nil; bags._pwrBtn:GetScript("OnClick")(bags._pwrBtn)
assert(pending.confirmText=="Enable & Reload"); pending.onConfirm(); assert(enabled[1]=="EllesmereUIBags")
''')
print('PASS: native theme textures/palette matching/custom/class accents; Presets navigation, cards, reload-gated switches, cache restore and hidden indexing; sidebar power/sync icons and Disable & Reload confirmation')
