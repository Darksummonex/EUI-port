"""Standalone Damage Meters build (backport-tools/build_standalone.py).

Lightweight build: only the meter, its option page and the standalone shim (no
EUI Core, options panel or Unlock Mode). Checks the TOC, that every file compiles
in Lua 5.1, that no EllesmereUI identifier or suite path is left, that bundled
media resolves, the inert-beside-the-suite guard, and runs the real build in the
mock: lifecycle, own SavedVariables, /edm settings window with its three pages,
every widget kind, deferred refresh, reset and close."""
from pathlib import Path
import re
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
sys.path.insert(0, str(root / 'backport-tools'))
from lupa.lua51 import LuaRuntime
import build_standalone as B

FOLDER, TOKEN = 'EUIStandaloneDamageMeters', 'EUICoreStandaloneDamageMeters'

MOCK_EXTRA = r'''
local m=getmetatable(UIParent).__index
setmetatable(m,{__index=function(_,k) if type(k)=='string' and k:find('^%u') then return function() end end end})
function m:SetSize(w,h) self.width,self.height=w,h end
function m:SetThumbTexture() self.thumb=self.thumb or self:CreateTexture() end
function m:GetThumbTexture() return self.thumb end
function m:SetValue(v) local old=self.value; self.value=v; if self.kind=='Slider' and old~=v then self:RunScript('OnValueChanged',v) end end
function m:GetValue() return self.value end
function m:SetShadowColor() end
function m:SetShadowOffset() end
function m:SetVertexColor(...) self.vertex={...} end
function m:GetStringHeight() return 14 end
function m:GetVerticalScrollRange() return 0 end
function m:SetFocus() self.focus=true; editFocus=self end
function m:ClearFocus() if self.focus then self.focus=false; self:RunScript('OnEditFocusLost') end end
function m:SetColorRGB(r,g,b) self.rgb={r,g,b}; if self.func then self.func() end end
function m:GetColorRGB() return unpack(self.rgb) end
ColorPickerFrame=CreateFrame('Frame','ColorPickerFrame',UIParent); ColorPickerFrame:Hide()
OpacitySliderFrame=CreateFrame('Slider','OpacitySliderFrame',UIParent); OpacitySliderFrame.value=0
tinsert,tremove=table.insert,table.remove
strmatch,strfind,strsub,strlower,strupper,gsub,format=string.match,string.find,string.sub,string.lower,string.upper,string.gsub,string.format
LOCALE_MASK_LATIN=1
function IsLoggedIn() return loggedIn end
function GetSpellInfo(id) return 'Spell '..tostring(id),nil,'spell-icon' end
function IsInInstance() return nil,'none' end
function UnitAffectingCombat() return false end
function GetNumPartyMembers() return 0 end
function GetNumRaidMembers() return 0 end
function GetActiveTalentGroup() return 1 end
function GetTalentTabInfo() return 'Arms','icon',10 end
function CanInspect() return false end
function IsInGuild() return false end
function time() return 1790840000 end
function GetCursorPosition() return 0,0 end
bit={band=function(a,b) local v,p=0,1; while a>0 and b>0 do if a%2==1 and b%2==1 then v=v+p end; a=math.floor(a/2); b=math.floor(b/2); p=p*2 end; return v end}
chat={}; DEFAULT_CHAT_FRAME={AddMessage=function(_,t) chat[#chat+1]=t end}
GetAddOnInfo=function(n) assert(n=='EllesmereUI'); return n,n,'',nil end
'''

FLOW = r'''
local FOLDER,TOKEN=...
local function Fire(event,...) for _,f in ipairs(allFrames) do if f.events[event] and f.scripts.OnEvent then f:RunScript('OnEvent',event,...) end end end
Fire('ADDON_LOADED','SomethingElse')
local T=_G[TOKEN]; local ns=T._ModuleNS[FOLDER]
assert(ns and ns.addon and not ns.addon.db,'initialized before its own ADDON_LOADED')
Fire('ADDON_LOADED',FOLDER)
assert(ns.addon.db and ns.Profile()==_G[FOLDER..'DB'].profile,'settings live in the own SavedVariables')
loggedIn=true; Fire('PLAYER_LOGIN')
assert(ns.events and #ns.Profile().windows>=1)
assert(not T.ToggleUnlockMode and not T.RegisterUnlockElements,'no Unlock Mode in the standalone')
assert(T.GetFontPath():find('AddOns\\'..FOLDER..'\\media\\fonts\\Expressway.ttf',1,true))

SlashCmdList.EUI335DM('')
local win=T._StandaloneSettings(); assert(win and win:IsShown() and ns.optionsOpen,'/edm opens the own window')
assert(T:GetActiveModule()==FOLDER and #win.tabs==3)
local function Walk(frame,out)
    for _,c in ipairs(frame.children) do
        if c.cells then for _,cell in ipairs(c.cells) do out[#out+1]=cell end end
        Walk(c,out)
    end
    return out
end
local function Cells() return Walk(win.content,{}) end
local function Find(text) for _,cell in ipairs(Cells()) do if cell.cfg.text==text then return cell end end; error('missing field: '..text) end
local function Buttons() local out={} for _,c in ipairs(win.content.children) do if c.text and c.kind=='Button' then out[c.text:GetText()]=c end end; return out end
local function Flush() for _,f in ipairs(allFrames) do if f.scripts.OnUpdate and f:IsShown() then f:RunScript('OnUpdate',.1) end end end

local kinds={}
for i,tab in ipairs(win.tabs) do
    tab:Click(); assert(win.tabs[i].underline:IsShown())
    for _,cell in ipairs(Cells()) do kinds[cell.cfg.type]=true end
end
for _,k in ipairs({'toggle','slider','dropdown','input','label','colorpicker','multiSwatch'}) do assert(kinds[k],'no '..k..' widget rendered') end
win.tabs[1]:Click()
local b=Buttons(); assert(b['Reset Window Position'] and b['Create Meter Window'] and not b['Unlock Mode'],'Unlock Mode button is hidden')

local p=ns.Profile(); local w=p.windows[1]
Find('Hide Rank Numbers').toggle:Click(); assert(w.hideRank==true)
Find('Hide Rank Numbers').toggle:Click(); assert(w.hideRank==false)
Find('Left Text Size').slider:SetValue(15.3); assert(w.fontSize==15)
local box=Find('Left Text Size').box; box:SetText('30'); box:RunScript('OnEnterPressed'); assert(w.fontSize==20,'typed values clamp to the slider range')
Find('Background Opacity').slider:SetValue(.42); assert(w.alpha==.4)
local dd=Find('Display').dropdown; dd:Click()
local popupRow
for _,f in ipairs(allFrames) do if f.key=='healing' and f:IsShown() then popupRow=f end end
assert(popupRow,'dropdown list shows the meter types'); popupRow:Click(); assert(w.metric=='healing' and dd.text:GetText()=='Healing Done')
local name=Find('Window Name').box; name:SetText('Raid'); name:RunScript('OnEnterPressed'); assert(w.name=='Raid')
Find('Background Color').swatches[1]:Click(); assert(ColorPickerFrame:IsShown() and not ColorPickerFrame.hasOpacity)
ColorPickerFrame:SetColorRGB(.2,.3,.4); assert(w.bgColor.b==.4)
ColorPickerFrame.cancelFunc(ColorPickerFrame.previousValues); ColorPickerFrame:Hide()
local bar=Find('Bar Color'); bar.swatches[2]:Click(); assert(w.barColorMode=='custom')
local before=win.content; Flush(); assert(win.content~=before,'swatch picks refresh the page')
Find('Bar Background').swatches[1]:Click(); assert(ColorPickerFrame.hasOpacity)
OpacitySliderFrame.value=.5; ColorPickerFrame:SetColorRGB(.1,.1,.1); assert(w.barBgColor.a==.5)
before=win.content; T:RefreshPage(); Flush(); assert(win.content==before,'no rebuild while the color picker is open')
ColorPickerFrame:Hide(); Flush(); assert(win.content~=before)
-- Fonts: Expressway by default, any LibSharedMedia font on pick, previewed in the list.
local lsm=LibStub('LibSharedMedia-3.0')
assert(lsm:Fetch('font','Expressway')==T.GetFontPath() and lsm:Fetch('font','Expressway'):find(FOLDER,1,true))
lsm:Register('font','Fake Font','Interface\\AddOns\\FakeMedia\\fake.ttf')
win.tabs[2]:Click(); win.tabs[1]:Click()
local fontDD=Find('Font').dropdown; assert(fontDD.text:GetText()=='Expressway')
fontDD:Click(); popupRow=nil
for _,f in ipairs(allFrames) do if f.key=='Fake Font' and f:IsShown() then popupRow=f end end
if not popupRow then for _,f in ipairs(allFrames) do if f.wheel and f:IsShown() and f.order then for i=1,#f.order do f:RunScript('OnMouseWheel',-1) end end end end
for _,f in ipairs(allFrames) do if f.key=='Fake Font' and f:IsShown() then popupRow=f end end
assert(popupRow and popupRow.text.font[1]=='Interface\\AddOns\\FakeMedia\\fake.ttf','font list previews each font')
popupRow:Click(); assert(p.font=='Fake Font' and T.GetFontPath()=='Interface\\AddOns\\FakeMedia\\fake.ttf')
assert(ns.windows[1].empty.font[1]=='Interface\\AddOns\\FakeMedia\\fake.ttf','meter rows use the picked font')
assert(fontDD.text.font[1]=='Interface\\AddOns\\FakeMedia\\fake.ttf')
Buttons()['Create Meter Window']:Click(); Flush(); assert(#p.windows==3)
win.tabs[2]:Click(); Find('Enable Icon History').toggle:Click(); assert(p.spellHistory.iconEnabled)
win.tabs[3]:Click(); Find('Stored Segments').slider:SetValue(7); assert(p.historyLimit==7)
win.reset:Click(); assert(p.historyLimit==7 and win.reset.text:GetText()=='Click to Confirm')
win.reset:Click(); assert(ns.Profile().historyLimit==15 and ns.Profile().spellHistory.iconEnabled==false,'reset restores defaults')
Flush()
local key=Find('Stored Segments').box; key:SetFocus(); win.close:Click()
assert(not win:IsShown() and not ns.optionsOpen and not key.focus,'closing clears focus and options state')
T:ShowModule(FOLDER); T:SelectPage('Spell History'); assert(win.tabs[2].underline:IsShown())
T:Hide(); assert(not win:IsShown())
'''

with tempfile.TemporaryDirectory() as tmp:
    dest = B.build('DamageMeters', tmp)
    assert dest.name == FOLDER
    toc = (dest / (FOLDER + '.toc')).read_bytes().decode('utf-8')
    assert '\r\n' in toc and '\r\r' not in toc
    head = dict(l[3:].split(':', 1) for l in toc.splitlines() if l.startswith('## '))
    assert re.match(r'\d{10}$', head['X-EUI-Release'].strip())
    assert head['SavedVariables'].strip() == FOLDER + 'DB', head['SavedVariables']
    assert head['SavedVariablesPerCharacter'].strip() == FOLDER + 'History'
    assert '/edm' in head['Notes'] and '/eui' not in head['Notes']
    files = [l.strip() for l in toc.splitlines() if l.strip() and not l.startswith('#')]
    mod_files = B.toc_files(root / 'EllesmereUIDamageMeters/EllesmereUIDamageMeters.toc')
    libs = B.MODULES['DamageMeters']['libs']
    assert files == ['Standalone_Guard.lua'] + libs + ['DamageMeters_Standalone.lua'] + mod_files + ['EUI_DamageMeters_335_Options.lua'], files
    shipped = sorted(str(p.relative_to(dest)).replace('\\', '/') for p in dest.rglob('*') if p.is_file())
    assert [s for s in shipped if s.startswith('Libs/')] == sorted(l.replace('\\', '/') for l in libs), 'only LibStub, CallbackHandler and LibSharedMedia'
    for l in libs:
        assert (dest / l.replace('\\', '/')).read_bytes() == (root / 'EllesmereUI' / l.replace('\\', '/')).read_bytes(), l + ' must ship unchanged'
    assert not any(s.startswith('EllesmereUI') for s in shipped), 'Core shipped'
    assert [s for s in shipped if s.startswith('media/')] == ['media/eg-logo.tga', 'media/fonts/Expressway.ttf'], shipped

    lua = LuaRuntime()
    load = lua.eval('function(src, name) local f, err = loadstring(src, name); return f ~= nil, err end')
    lower = {str(p.relative_to(dest)).lower().replace('/', '\\'): p for p in dest.rglob('*') if p.is_file()}
    lowdirs = {str(p.relative_to(dest)).lower().replace('/', '\\') for p in dest.rglob('*') if p.is_dir()}
    kept, missing = set(), []
    path_re = re.compile(r'Interface\\{1,2}AddOns\\{1,2}' + FOLDER + r'\\{1,2}([^"\'\]|:]*)', re.I)
    for rel in files:
        p = dest / rel.replace('\\', '/')
        assert p.is_file(), 'TOC file missing: ' + rel
        src = p.read_bytes().decode('latin-1')
        ok, err = load(src, rel)
        assert ok, '%s does not compile: %s' % (rel, err)
        if rel == 'Standalone_Guard.lua' or rel in libs:
            continue
        spans = B.string_spans(src)
        for m in re.finditer('EllesmereUI', src):
            inside = [s for s in spans if s[0] <= m.start() < s[1]]
            assert inside, '%s: EllesmereUI identifier left at %d' % (rel, m.start())
            s, e = inside[0]
            nxt = src[m.end()] if m.end() < e else ''
            assert not (nxt.isalnum() or nxt == '_'), '%s: renamable token left in a string' % rel
            kept.add(src[s:e][:60])
        for bad in [r'AddOns\\\\EllesmereUI', r'AddOns\\\\' + TOKEN]:
            assert not re.search(bad, src), '%s still points at %s' % (rel, bad)
        for m in path_re.finditer(src):
            sub = m.group(1).replace('\\\\', '\\').rstrip('\\').lower()
            if not sub or sub in lower or sub in lowdirs:
                continue
            if '.' not in sub.rsplit('\\', 1)[-1] and any(sub + ext in lower for ext in ('.tga', '.blp', '.png', '.ttf')):
                continue
            missing.append('%s -> %s' % (rel, sub))
    assert not missing, 'bundled paths without files:\n  ' + '\n  '.join(sorted(set(missing)))

    opts = (dest / 'EUI_DamageMeters_335_Options.lua').read_text(encoding='latin-1')
    assert 'E._ModuleNS.' + FOLDER in opts
    disp = (dest / 'EUI_DamageMeters_335_Display.lua').read_text(encoding='latin-1')
    assert 'AddOns\\\\%s\\\\Media_335\\\\' % FOLDER in disp and 'AddOns\\\\%s\\\\Textures_335\\\\' % FOLDER in disp
    assert (dest / 'Textures_335' / 'matte.tga').is_file() and (dest / 'Media_335' / 'dm_settings.tga').is_file()
    guard = (dest / 'Standalone_Guard.lua').read_text(encoding='utf-8')
    assert '"Ellesmere" .. "UI"' in guard
    # Inert beside the suite: every bundled file returns on its (unchanged) first line.
    inert = 'if %s_Inert then return end ' % FOLDER
    for rel in files[1:]:
        if rel in libs:
            continue
        assert (dest / rel).read_bytes().decode('latin-1').lstrip('\xef\xbb\xbf').startswith(inert), rel + ' lacks the inert check'
    src_lines = (root / 'EllesmereUIDamageMeters/EUI_DamageMeters_335.lua').read_bytes().count(b'\n')
    assert (dest / 'EUI_DamageMeters_335.lua').read_bytes().count(b'\n') == src_lines, 'inert check shifted line numbers'

    shim_src = (dest / 'DamageMeters_Standalone.lua').read_bytes().decode('latin-1')
    for suite_enabled in (True, False):
        g = LuaRuntime()
        g.execute((root / 'backport-tools/wrath_mock.lua').read_text(encoding='utf-8-sig'))
        g.globals().suiteOn = suite_enabled
        g.execute('GetAddOnInfo=function(n) assert(n=="EllesmereUI"); return n,n,"",suiteOn and 1 or nil end; msgs={}; '
                  'DEFAULT_CHAT_FRAME={AddMessage=function(_,m) msgs[#msgs+1]=m end}')
        g.execute(guard, 'Standalone_Guard.lua')
        assert bool(g.eval(FOLDER + '_Inert')) == suite_enabled, 'inert flag with suite enabled=%s' % suite_enabled
        if suite_enabled:
            g.execute(shim_src, 'DamageMeters_Standalone.lua')
            assert g.eval('type(%s)' % TOKEN) == 'nil', 'shim ran while inert'
            for fr in g.eval('allFrames').values():
                if fr.events['PLAYER_LOGIN']:
                    fr.scripts['OnEvent'](fr, 'PLAYER_LOGIN')
            assert 'inactive' in g.eval('msgs[1]')

    # The real build, running on its own.
    r = LuaRuntime()
    for mock in ('wrath_mock.lua', 'inventory_resources_mock.lua'):
        r.execute((root / 'backport-tools' / mock).read_text(encoding='utf-8-sig'))
    r.execute(MOCK_EXTRA)
    ns = r.table()
    for rel in files:
        r.execute((dest / rel.replace('\\', '/')).read_bytes().decode('latin-1').lstrip('\xef\xbb\xbf'), FOLDER, ns)
    r.execute(FLOW, FOLDER, TOKEN)

print('PASS: standalone Damage Meters (lightweight): %d TOC files compile with no Core or Unlock Mode; own '
      'SavedVariables; /edm settings window renders all three pages and every widget kind; LibSharedMedia font '
      'pick with previews; refresh, reset and '
      'close work; inert beside the suite; %d display strings keep the EllesmereUI name' % (len(files), len(kept)))
