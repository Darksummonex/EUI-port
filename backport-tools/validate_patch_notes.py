"""Patch Notes module on Wrath: backport notes only (no Retail entries), the
Legends/donor content removed, the header thanks line fixed to Ellesmere,
Original Staff page with the port staff card and its GitHub link, both
pages built through the real General Options registration in Lua 5.1, and the
new-patch dot stamp re-arming on backport version changes."""
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

general_path = root / 'EllesmereUIOptions/EUI__General_Options.lua'
general = general_path.read_text(encoding='utf-8-sig')
core = (root / 'EllesmereUI/EllesmereUI.lua').read_text(encoding='utf-8-sig')

# Module folder -> display name used in the notes headers ("<Name> <x.y>").
DISPLAY = {
    'EllesmereUI': 'Core', 'EllesmereUIOptions': 'Options', 'EllesmereUIArena': 'Arena',
    'EllesmereUIActionBars': 'Action Bars', 'EllesmereUIAuraBuffReminders': 'Aura Buff Reminders',
    'EllesmereUIBags': 'Bags', 'EllesmereUIBlizzardSkin': 'Blizz UI Enhanced', 'EllesmereUIChat': 'Chat',
    'EllesmereUICooldownManager': 'Cooldown Manager', 'EllesmereUIDamageMeters': 'Damage Meters',
    'EllesmereUIDataBars': 'DataBars', 'EllesmereUIFriends': 'Friends List', 'EllesmereUIMinimap': 'Minimap',
    'EllesmereUINameplates': 'Nameplates', 'EllesmereUIQoL': 'Quality of Life',
    'EllesmereUIQuestTracker': 'Quest Tracker', 'EllesmereUIQuickdraw': 'Quickdraw',
    'EllesmereUIRaidFrames': 'Raid Frames', 'EllesmereUIResourceBars': 'Resource Bars',
    'EllesmereUIUnitFrames': 'Unit Frames',
}
DONOR_ONLY = ['Thias', 'StickyMittens', 'Xeno', 'Toxik', 'Pelleas', 'GamingGrammers', 'Khardi',
              'Cartridgebros', 'Lurn', 'fizzle_crunk', 'Venalis', 'Natasi', 'Quiim', 'Keato03',
              'e_luvin', 'ccpoppin1', 'Arjax', 'Excelvior', 'Marple_V', 'shy_x00']
RETAIL_TITLES = ['Target of Target and Bottom Text', 'First Install Keeps Your Layout', 'Threat Meter Type',
                 'Fastest Run Splits', 'Micro Menu and Bag Bar End Caps', 'Missing Buffs Choices',
                 'Swing Timer is now', 'Anchor Offsets and Corner Anchors']

# --- Static source checks -------------------------------------------------
for s in ['_LEGENDS', '_PickLegendsThanks', '_BuildLegendsPage', 'Seasonal Top Donors', 'ALL-TIME DONORS',
          'View EUI Legends', 'EUI Legends', 'GENERATED DONORS', 'EUI STAFF', '"EUI Staff"']:
    assert s not in general, 'removed content still present: ' + s
for name in DONOR_ONLY:
    assert not re.search(r'"%s"' % re.escape(name), general), 'donor name still listed: ' + name
for t in RETAIL_TITLES:
    assert t not in general, 'Retail patch note still present: ' + t
assert 'EllesmereUI._STAFF = {' in general and '"ORIGINAL STAFF"' in general and '"PORT STAFF"' in general
assert (root / 'EllesmereUI/media/icons/github.png').is_file(), 'GitHub icon missing'

# --- Lua environment (same adapter as validate_themes_presets.py) ---------
def make_runtime(addons_loaded):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute((root / 'backport-tools/wrath_mock.lua').read_text(encoding='utf-8-sig'))
    ns = lua.table()
    lua.execute((root / 'EllesmereUIUnitFrames/EUI_UnitFrames_335.lua').read_text(encoding='utf-8-sig'), 'EllesmereUIUnitFrames', ns)
    lua.globals().W335 = ns.Wrath
    lua.globals().addonsLoaded = addons_loaded
    lua.execute('''
CreateFrame=W335.CreateFrame
EUI_WOW_335=true
local E=EllesmereUI
local methods=getmetatable(CreateFrame("Frame")).__index
local function stub(name, fn) if not methods[name] then methods[name]=fn end end
stub("SetSize", function(self,w,h) self.width,self.height=w,h end)
stub("SetPoint", function(self,...) self.points=self.points or {}; self.points[#self.points+1]={...} end)
stub("ClearAllPoints", function(self) self.points={} end)
stub("SetAllPoints", function() end)
stub("SetColorTexture", function(self,r,g,b,a) self.color={r,g,b,a} end)
stub("SetFrameLevel", function() end)
stub("EnableMouse", function(self,v) self.mouse=v end)
stub("SetJustifyH", function() end); stub("SetJustifyV", function() end)
stub("SetWordWrap", function() end); stub("SetTextColor", function() end)
stub("SetAlpha", function(self,a) self.alpha=a end)
stub("SetShown", function(self,v) self.shown=v and true or false end)
stub("GetStringHeight", function() return 14 end)
stub("GetStringWidth", function() return 120 end)
stub("SetDrawLayer", function() end)
stub("SetVertexOffset", function() end)
stub("CreateAnimationGroup", function() return {SetLooping=function() end,
  CreateAnimation=function() local a={}; return setmetatable(a,{__index=function() return function() end end}) end,
  Play=function() end, Stop=function() end} end)
IsAddOnLoaded=function(name) return addonsLoaded end
C_AddOns=C_AddOns or {}; C_AddOns.IsAddOnLoaded=nil
E.ELLESMERE_GREEN={r=.05,g=.82,b=.62}
E.PanelPP=E.PP
E.CONTENT_PAD=45
E.ICONS_PATH=E.ICONS_PATH or "Interface\\\\AddOns\\\\EllesmereUI\\\\media\\\\icons\\\\"
E.L=function(s) return s end
E.Lf=function(s) return s end
E.MakeFont=function(parent) return parent:CreateFontString() end
E.MakeBorder=function() return {SetColor=function() end} end
E.ShowWidgetTooltip=function() end; E.HideWidgetTooltip=function() end
E.Widgets={
  SectionHeader=function(self,parent,text,y) local fs=parent:CreateFontString(); fs:SetText(text); return fs,30 end,
  Spacer=function(self,parent,y,h) return nil,h end,
  DualRow=function() return {},50 end,
}
registrations={}; onShow={}; navCalls={}
E.RegisterModule=function(self,key,cfg) registrations[key]=cfg end
E.RegisterOnShow=function(self,fn) onShow[#onShow+1]=fn end
E.RegisterOnHide=function() end
E.SelectPage=function() end
E.GetActiveModule=function() return nil end
E.NavigateToElementSettings=function(self,...) navCalls[#navCalls+1]={...} end
E.ModuleNS=function() return nil end
E.GetFontOutlineFlag=function() return "" end
E.SetCVar=function() end
E.GetPlayerClassColor=function() return .78,.61,.43 end
GetCVarDefault=function() return "0" end
C_CVar.GetCVarInfo=function() return "1","0" end
SetCVar=function() end
''')
    lua.execute(general, 'EllesmereUIOptions')
    lua.execute('''
for _,f in ipairs(allFrames) do
 if f.events.PLAYER_LOGIN and f:GetScript("OnEvent") then f:GetScript("OnEvent")(f,"PLAYER_LOGIN") end
end
''')
    return lua


def page_texts(lua, page):
    return list(lua.eval('''function(page)
local cfg=registrations._EUIPatchNotes
local before=#allFrames
local parent=CreateFrame("Frame"); parent:SetWidth(900)
local h=cfg.buildPage(page,parent,-6)
assert(type(h)=="number" and h>100, "page height "..tostring(h))
local out={}
for i=before+1,#allFrames do
 local f=allFrames[i]
 if f.kind=="FontString" and type(f.text)=="string" and f.text~="" then out[#out+1]=f.text end
end
return out
end''')(page).values())


lua = make_runtime(True)
E = lua.globals().EllesmereUI
cfg = lua.globals().registrations['_EUIPatchNotes']
assert cfg is not None, 'Patch Notes module not registered'
assert list(cfg.pages.values()) == ['Patch Notes', 'Original Staff'], list(cfg.pages.values())
for k in ['_LEGENDS', '_LEGENDS_SEASONS', '_PickLegendsThanks', '_BuildLegendsPage']:
    assert E[k] is None, k + ' should be gone'

# --- Notes data -------------------------------------------------------------
patches = [p for p in E._WHATSNEW_PATCHES.values()]
assert len(patches) >= 2
assert patches[0].heroes[1].banner, 'overview banner expected first'
versions = [p.version for p in patches]
for v in versions:
    assert not re.match(r'^\d', v), 'Retail-style version header: ' + v
headers = {}
for v in versions[1:]:
    m = re.match(r'^(.+) (\d+)\.(\d+)$', v)
    assert m, 'module header must be "<Module> <x.y>": ' + v
    assert m.group(1) not in headers, 'duplicate module header: ' + v
    headers[m.group(1)] = (int(m.group(2)), int(m.group(3)))

def toc_version(folder):
    toc = root / folder / (folder + '.toc')
    for line in toc.read_text(encoding='utf-8-sig').splitlines():
        if line.startswith('## Version:'):
            m = re.search(r'-(\d+)\.(\d+)\s*$', line)
            return (int(m.group(1)), int(m.group(2))) if m else None

warnings = []
for d in sorted(p for p in root.iterdir() if p.is_dir() and p.name.startswith('EllesmereUI')):
    if not (d / 'README-335.md').is_file():
        continue
    name = DISPLAY.get(d.name)
    if not name:
        warnings.append('no patch-notes mapping for ' + d.name)
        continue
    assert name in headers, 'missing backport notes for ' + d.name + ' (' + name + ')'
    tv = toc_version(d.name)
    assert tv and headers[name] <= tv, '%s notes %s ahead of TOC %s' % (name, headers[name], tv)
    if headers[name] < tv:
        warnings.append('%s notes cover %d.%d, TOC is %d.%d' % ((name,) + headers[name] + tv))

options_src = {}
for f in (root / 'EllesmereUIOptions').glob('*.lua'):
    txt = f.read_text(encoding='utf-8-sig', errors='replace')
    for mod in re.findall(r'RegisterModule\(\s*"(EllesmereUI\w+)"', txt):
        options_src.setdefault(mod, '')
        options_src[mod] += txt
navs = 0
for p in patches:
    for tier in ('heroes', 'features', 'fixes'):
        lst = p[tier]
        for e in (lst.values() if lst else []):
            assert not e.forever, 'Forever entry in backport notes'
            text = e.title or e.text
            assert text, 'entry without title/text in ' + p.version
            for t in RETAIL_TITLES:
                assert t not in text
            nav = e.nav
            if nav:
                navs += 1
                assert nav.module and nav.page, 'nav needs module and page'
                src = general if nav.module.startswith('_') else options_src.get(nav.module)
                assert src, 'nav to unregistered module ' + nav.module
                assert '"%s"' % nav.page in src, 'nav page %r not found for %s' % (nav.page, nav.module)
assert navs >= 10

# --- Build both pages ------------------------------------------------------
notes_text = page_texts(lua, 'Patch Notes')
joined = '\n'.join(notes_text)
for v in versions:
    assert 'EllesmereUI ' + v in notes_text, 'header not rendered: ' + v
for s in ['9.3.4', 'WoW Forever', 'Special thanks']:
    assert s not in joined, 'unexpected text on Patch Notes page: ' + s
assert 'New Module: Arena Frames' in joined or 'EllesmereUIArena' not in [d.name for d in root.iterdir()]
# A nav card click deep-links through NavigateToElementSettings.
lua.execute('''
local hit
for i=#allFrames,1,-1 do
 local f=allFrames[i]
 if f.kind=="Button" and f.mouse~=false and f:GetScript("OnClick") then hit=f; break end
end
assert(hit, "no clickable patch-note entry")
hit:GetScript("OnClick")(hit)
assert(#navCalls==1 and type(navCalls[1][1])=="string" and type(navCalls[1][2])=="string")
''')

staff_text = page_texts(lua, 'Original Staff')
for s in ['Special thanks to Ellesmere', 'PORT STAFF', '3.3.5a Backport', 'Laraystiri', 'ORIGINAL STAFF',
          'Support Leads', 'Support Team', 'Major Bugfix/Feature Contributors',
          'Multi-language Support Contributors', 'Burne', 'Bierbauch', 'TF0rd', 'Shiyan66666']:
    assert s in staff_text, 'staff page missing ' + s
groups = list(E._PORT_STAFF.values()) + list(E._STAFF.values())
staff_names = sum(len(list(g.members.values())) for g in groups)
assert len(staff_text) == 3 + len(groups) + staff_names, 'unexpected extra text on staff page'
for s in DONOR_ONLY + ['Seasonal Top Donors', 'ALL-TIME DONORS', 'Thank you', 'Unclaimed']:
    assert s not in staff_text, 'donor content on staff page: ' + s
# Laraystiri's GitHub icon opens the copy-link popup with the releases URL.
lua.execute('''
local shown
EllesmereUI.ShowLinkPopup=function(url) shown=url end
local parent=CreateFrame("Frame"); parent:SetWidth(900)
local before=#allFrames
registrations._EUIPatchNotes.buildPage("Original Staff",parent,-6)
local icon
for i=before+1,#allFrames do
 local f=allFrames[i]
 if f.kind=="Button" and f:GetScript("OnClick") then assert(not icon,"one link icon expected"); icon=f end
end
assert(icon,"GitHub icon button missing")
icon:GetScript("OnClick")(icon)
assert(shown=="https://github.com/Darksummonex/EUI-port/releases", tostring(shown))
''')

# The header thanks line names Ellesmere and opens the Original Staff page.
lua.execute('''
EllesmereUI._clickArea=CreateFrame("Frame")
local before=#allFrames
for _,fn in ipairs(onShow) do pcall(fn) end
local texts, btn={}, nil
for i=before+1,#allFrames do
 local f=allFrames[i]
 if type(f.text)=="string" then texts[f.text]=true end
 if f.kind=="Button" and f:GetScript("OnClick") then btn=f end
end
assert(texts["Special thanks to:"] and texts["Ellesmere"], "header thanks line missing")
local mod, page
EllesmereUI.SelectModule=function(_,m) mod=m end
EllesmereUI.SelectPage=function(_,p) page=p end
btn:GetScript("OnClick")(btn)
assert(mod=="_EUIPatchNotes" and page=="Original Staff", tostring(mod).." "..tostring(page))
''')

# Without the target modules loaded, entries render static (no dead links).
lua2 = make_runtime(False)
for p in lua2.globals().EllesmereUI._WHATSNEW_PATCHES.values():
    for tier in ('heroes', 'features', 'fixes'):
        lst = p[tier]
        for e in (lst.values() if lst else []):
            if e.nav:
                assert e.nav.module.startswith('_'), 'nav kept for unloaded ' + e.nav.module
page_texts(lua2, 'Patch Notes')

# --- New-patch dot stamp ------------------------------------------------------
stamp_block = '-- Version-increase detection' + core.split('-- Version-increase detection', 1)[1].split('-- Version mismatch check', 1)[0]
lua3 = LuaRuntime(unpack_returned_tuples=True)
lua3.execute((root / 'backport-tools/wrath_mock.lua').read_text(encoding='utf-8-sig'))
lua3.execute('''
EllesmereUI.VERSION="9.3.4"
dotUpdates=0; EllesmereUI._UpdatePatchDot=function() dotUpdates=dotUpdates+1 end
addons={{"EllesmereUI","3.3.5-core-0.44"},{"EllesmereUINameplates","9.3.4-335-0.12"},{"ElvUI","6.0"}}
GetNumAddOns=function() return #addons end
GetAddOnInfo=function(i) return addons[i][1] end
GetAddOnMetadata=function(name,field)
 assert(field=="Version")
 for _,a in ipairs(addons) do if a[1]==name then return a[2] end end
end
function login()
 local before=#allFrames
 local fn=loadstring(stampBlock); fn()
 for i=before+1,#allFrames do
  local f=allFrames[i]
  if f.events.PLAYER_LOGIN then f:GetScript("OnEvent")(f,"PLAYER_LOGIN") end
 end
end
''')
lua3.globals().stampBlock = stamp_block
lua3.execute('''
EllesmereUIDB={lastLoginVersion="9.3.4"}
login()
assert(EllesmereUIDB.patchDotPending==true, "Retail stamp -> backport stamp should raise the dot")
local s=EllesmereUIDB.lastLoginVersion
assert(s:find("EllesmereUINameplates=9.3.4-335-0.12",1,true) and not s:find("ElvUI",1,true))
EllesmereUIDB.patchDotPending=nil; login()
assert(EllesmereUIDB.patchDotPending==nil, "same versions must not raise the dot")
addons[2][2]="9.3.4-335-0.13"; login()
assert(EllesmereUIDB.patchDotPending==true, "module update should raise the dot")
EllesmereUIDB={}; login()
assert(EllesmereUIDB.patchDotPending==nil, "first login never raises the dot")
EUI_WOW_335=false; EllesmereUIDB={lastLoginVersion="9.3.4"}; login()
assert(EllesmereUIDB.patchDotPending==nil and EllesmereUIDB.lastLoginVersion=="9.3.4", "Retail stamp unchanged")
assert(dotUpdates==5)
''')

for w in warnings:
    print('NOTE:', w)
print('PASS: %d backport patch-note entries (no Retail notes), %d deep links checked; Legends/donors removed; '
      'header thanks to Ellesmere; Original Staff page built with %d names and the port GitHub link; both pages build in the Lua 5.1 mocks; patch dot re-arms on backport updates'
      % (len(patches), navs, staff_names))
