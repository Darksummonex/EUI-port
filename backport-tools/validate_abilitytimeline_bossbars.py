"""AbilityTimeline BossBars.lua: hide DBM / BigWigs bars while the timeline shows
their timers (Retail AbilityTimeline's "disable boss mod bars").

Runs the real DBM-StatusBarTimers DBT.lua and the real AbilityTimeline Core.lua,
Sources.lua and BossBars.lua in Lua 5.1, with mocked DBM-Core callbacks, BigWigs
messages and LibCandyBar. Bars must turn invisible and click-through while the
timeline is active, keep counting (and expiring) while invisible, come back when
the timeline, its source or its Hide option goes off, follow late/on-demand
loading, never touch DBM saved options, and stay untouched with both options off."""
from pathlib import Path
import sys
from game_paths import ADDONS, DATA, WTF
root = Path(__file__).resolve().parents[1]
if not ADDONS:
    print('SKIP: needs the real DBM and AbilityTimeline from a game install; set EUI_GAME_DIR.'); raise SystemExit(0)
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime


def read(rel):
    path = ADDONS / rel if rel.startswith(('DBM-', 'AbilityTimeline')) else root / rel
    return path.read_text(encoding='utf-8-sig', errors='replace')


MOCK = r'''
local m=getmetatable(UIParent).__index
function m:GetName() return self.name end
function m:SetAlpha(a) self.alpha=a end
function m:GetAlpha() return self.alpha or 1 end
function m:IsVisible() local f=self; while f do if not f.shown then return false end; f=f.parent end; return true end
function m:SetSize(w,h) self.width,self.height=w,h end
function m:SetMovable(v) self.movable=v end
function m:StartMoving() end
function m:StopMovingOrSizing() end
function m:SetClampedToScreen() end
function m:SetWordWrap() end
function m:SetBackdrop() end
function m:SetBackdropColor() end
function m:GetStatusBarColor() return 1,.7,0 end
function m:GetValue() return self.value or 0 end
function EffAlpha(f) local a=1; while f do a=a*(f.alpha or 1); f=f.parent end; return a end
-- No ancestor fades the frame (DBT bars carry their own Alpha option, 0.8 by default).
function Own(f) return EffAlpha(f)==(f.alpha or 1) end
function tDeleteItem(t,item) for i=#t,1,-1 do if t[i]==item then table.remove(t,i) end end end
-- DBT names its children "$parentBar", "$parentSpark"... and reads them back from _G.
local function Named(name,parent)
    if name and name:find('$parent',1,true) then name=name:gsub('%$parent',parent and parent.name or '') end
    return name
end
local create=CreateFrame
function CreateFrame(kind,name,parent,template) name=Named(name,parent); local f=create(kind,name,parent,template); f.name=name; return f end
for _,key in ipairs({'CreateTexture','CreateFontString'}) do
    local orig=m[key]
    m[key]=function(self,name,layer,template)
        local r=orig(self,name,layer,template); name=Named(name,self); if name then r.name=name; _G[name]=r end
        if key=='CreateFontString' and template then r:SetFont('Fonts\\FRIZQT__.TTF',10,'') end
        return r
    end
end
local function pack(...) return {n=select('#',...),...} end
function hooksecurefunc(t,k,fn)
    if type(t)=='string' then t,k,fn=_G,t,k end
    local orig=t[k]; assert(type(orig)=='function','hooksecurefunc on non-function '..tostring(k))
    t[k]=function(...) local r=pack(orig(...)); fn(...); return unpack(r,1,r.n) end
end
-- DBM-Core: callbacks plus the scheduler ShowMovableBar uses.
callbacks={}; scheduled={}
DBM={Options={},InfoFrame={Show=function() end,Hide=function() end},RangeCheck={Show=function() end,Hide=function() end}}
function DBM:RegisterCallback(event,f) callbacks[event]=callbacks[event] or {}; table.insert(callbacks[event],f) end
function DBM:Schedule(_,f,...) scheduled[#scheduled+1]={f,...} end
function DBM:Unschedule() end
function DBM:Debug() end
DBM_CORE_L={MOVABLE_BAR='Drag me'}; DBM_COMMON_L={IMPORTANT_ICON=''}
function FireDBM(event,...) for _,f in ipairs(callbacks[event] or {}) do f(event,...) end end
function StartDBM(id,duration)
    local bar=DBT:CreateBar(duration,id,'Interface\\Icons\\Spell_Fire_Fire')
    FireDBM('DBM_TimerStart',id,id,duration,'Interface\\Icons\\Spell_Fire_Fire','cd')
    return bar
end
-- BigWigs: the always-loaded loader; core/plugins and LibCandyBar load on demand.
bwHandlers={}
BigWigsLoader={RegisterMessage=function(obj,msg,fn) bwHandlers[#bwHandlers+1]={obj=obj,msg=msg,fn=fn} end}
function BWSend(msg,...) for _,h in ipairs(bwHandlers) do if h.msg==msg then h.fn(msg,...) end end end
libs={}
LibStub=setmetatable({},{__call=function(_,name) return libs[name] end})
sendBarCreated=false
function LoadBigWigsPlugins()
    candy={barPrototype={},barCache={},all={}}
    local proto=candy.barPrototype
    function proto:Set(k,v) self.data[k]=v end
    function proto:Get(k) return self.data and self.data[k] end
    function proto:Start(d) self.running=true; self.remaining=d; self.lastTick=now; self:Show() end
    function proto:Stop() self.running=nil; self.data=nil; self:Hide(); self:SetParent(UIParent); candy.barCache[self]=true end
    function candy:New()
        local bar=next(self.barCache)
        if bar then self.barCache[bar]=nil else
            bar=CreateFrame('Frame',nil,UIParent); local base=getmetatable(bar).__index
            setmetatable(bar,{__index=function(_,k) local v=proto[k]; if v~=nil then return v end; return base[k] end})
            bar:SetScript('OnUpdate',function(self)
                if not self.running then return end
                self.remaining=self.remaining-(now-self.lastTick); self.lastTick=now
                if self.remaining<=0 then self:Stop() end
            end)
            self.all[#self.all+1]=bar
        end
        bar.data={}; bar:SetAlpha(1); bar:EnableMouse(false); return bar
    end
    libs['LibCandyBar-3.0']=candy
    bwBars={}; bwPlugin={}
    BigWigsLoader.RegisterMessage(bwPlugin,'BigWigs_StartBar',function(_,module,key,text,time)
        local bar=candy:New(); bar:Set('bigwigs:module',module); bar:Set('bigwigs:anchor','normalPosition'); bar:Start(time); bwBars[text]=bar
        if sendBarCreated then BWSend('BigWigs_BarCreated',bwPlugin,bar,module,key,text,time) end
    end)
    BigWigsLoader.RegisterMessage(bwPlugin,'BigWigs_StopBar',function(_,_,text) local bar=bwBars[text]; if bar and bar.running then bar:Stop() end end)
end
function Pump(seconds)
    for _=1,math.floor(seconds/0.1+0.5) do
        now=now+0.1
        for bar in pairs(DBT.bars) do local f=bar.frame; if f:IsVisible() and f.scripts.OnUpdate then f.scripts.OnUpdate(f,0.1) end end
        if candy then for _,f in ipairs(candy.all) do if f:IsVisible() and f.scripts.OnUpdate then f.scripts.OnUpdate(f,0.1) end end end
        if AT and AT.driver and AT.driver:IsVisible() then AT.driver.scripts.OnUpdate(AT.driver,0.1) end
    end
end
function Near(a,b) return math.abs(a-b)<0.25 end
function Snapshot(t) local c={}; for k,v in pairs(t) do c[k]=v end; return c end
function SameTable(a,b) for k,v in pairs(a) do if b[k]~=v then return false,k end end; for k in pairs(b) do if a[k]==nil then return false,k end end; return true end
'''


def runtime():
    lua = LuaRuntime(unpack_returned_tuples=True)
    for source in ['backport-tools/wrath_mock.lua', 'backport-tools/inventory_resources_mock.lua',
                   'backport-tools/qol_mock.lua']:
        lua.execute(read(source))
    lua.execute(MOCK)
    # DBM loads first (folder order); the timeline is loaded later on purpose.
    lua.execute(read('DBM-StatusBarTimers/DBT.lua'))
    lua.execute("DBT:LoadOptions('DBM')")
    return lua


def load_timeline(lua):
    at = lua.table()
    for name in ['Core.lua', 'Sources.lua', 'BossBars.lua']:
        lua.execute(read('AbilityTimeline/' + name), 'AbilityTimeline', at)
    lua.globals().AT = at
    lua.globals().B = at.BossBars


# 1) Both Hide options off (saved): the timeline still gets timers, the bars stay as they are.
lua = runtime()
lua.execute('''
LoadBigWigsPlugins(); sendBarCreated=true
AbilityTimeline335DB={hideDBMBars=false,hideBigWigsBars=false}
''')
load_timeline(lua)
lua.execute('''
AT.events.scripts.OnEvent(AT.events,'ADDON_LOADED','AbilityTimeline')
B.events.scripts.OnEvent(B.events,'ADDON_LOADED','AbilityTimeline'); B.events.scripts.OnUpdate(B.events,0)
local bar=StartDBM('Boss Ability',30); BWSend('BigWigs_StartBar','Boss','k1','Breath',40)
assert(AT.timers['DBM:Boss Ability'] and AT.timers['BW:Breath'],'Timeline must still receive timers')
assert(Own(bar.frame) and bar.frame:IsMouseEnabled(),'DBM bar touched with Hide DBM bars off')
assert(bwBars.Breath:GetParent()==UIParent and EffAlpha(bwBars.Breath)==1,'BigWigs bar touched with Hide BigWigs bars off')
assert(not B.hidden.dbm and not B.hidden.bigwigs and B.Status()=='no boss mod bars hidden')
''')

# 2) Full flow: DBM loaded with a running bar, BigWigs loader only, timeline loads late.
lua = runtime()
lua.execute('''
optionsBefore=Snapshot(DBT.Options); createBefore=DBT.CreateBar
long=StartDBM('Boss Ability',120)
assert(Own(long.frame) and long.frame:IsMouseEnabled())
''')
load_timeline(lua)
lua.execute('''
-- Before the timeline's ADDON_LOADED, AT.db is not set yet.
B.Apply(); assert(not B.hidden.dbm and DBT.CreateBar==createBefore,'Acted before the timeline initialized')
AT.events.scripts.OnEvent(AT.events,'ADDON_LOADED','AbilityTimeline')
assert(AT.db.hideDBMBars==true and AT.db.hideBigWigsBars==true,'Hide options must default on')
assert(AT.Sources.dbm=='callbacks' and AT.Sources.bigwigs=='loader')
B.events.scripts.OnEvent(B.events,'ADDON_LOADED','AbilityTimeline')
assert(B.events:IsShown(),'Deferred re-check not armed'); B.events.scripts.OnUpdate(B.events,0); assert(not B.events:IsShown())
assert(B.hidden.dbm and B.hidden.bigwigs,'Timeline active but bars not hidden')
assert(EffAlpha(long.frame)==0 and long.frame:IsVisible() and not long.frame:IsMouseEnabled(),'Existing DBM bar must be invisible, shown and click-through')
assert(B.Status()=='DBM and BigWigs bars hidden')
-- New bars while active: hidden on creation, enlarged ones too; the timeline still gets the timer.
local short=StartDBM('Short',8)
assert(short.enlarged and EffAlpha(short.frame)==0 and not short.frame:IsMouseEnabled(),'New DBM bar visible')
assert(AT.timers['DBM:Short'] and AT.timers['DBM:Boss Ability']==nil,'Timeline must receive DBM timers started while active')
-- Timers keep running while invisible: DBT counts down and expires bars itself.
Pump(3)
assert(Near(long.timer,117) and Near(short.timer,5),'DBM bars stopped counting: '..long.timer..' '..short.timer)
assert(Near(long.totalTime-long.timer,3),'DBM-Core time read-back broken')
shortFrame=short.frame
Pump(6)
assert(DBT:GetBar('Short')==nil and DBT.numBars==1,'Invisible DBM bar did not expire')
local same,key=SameTable(optionsBefore,DBT.Options); assert(same,'DBT option changed: '..tostring(key))
''')

# 3) BigWigs core/plugins and LibCandyBar load on demand.
lua.execute('''
LoadBigWigsPlugins()
B.events.scripts.OnEvent(B.events,'ADDON_LOADED','BigWigs_Plugins'); B.events.scripts.OnUpdate(B.events,0)
assert(B.hooked.candy==candy.barPrototype,'LibCandyBar Start not hooked after on-demand load')
-- Without BigWigs_BarCreated (classic builds) the Start hook catches the bar.
sendBarCreated=false; BWSend('BigWigs_StartBar','Boss','k1','Breath',20)
local breath=bwBars.Breath
assert(breath:GetParent()==B.holder and EffAlpha(breath)==0 and breath:IsVisible(),'BigWigs bar visible (Start hook path)')
assert(AT.timers['BW:Breath'],'Timeline must receive BigWigs timers')
-- BigWigs re-showing an over-limit bar with SetAlpha(1) must not bring it back.
breath:SetAlpha(1); assert(EffAlpha(breath)==0,'SetAlpha(1) re-showed a hidden BigWigs bar')
-- Retail-style builds announce bars by message.
sendBarCreated=true; BWSend('BigWigs_StartBar','Boss','k2','Tail Sweep',30)
assert(bwBars['Tail Sweep']:GetParent()==B.holder,'BigWigs bar visible (message path)')
-- Another addon's LibCandyBar bar is left alone.
local other=candy:New(); other:Start(15); assert(other:GetParent()==UIParent and EffAlpha(other)==1,'Non-BigWigs bar hidden')
Pump(5)
assert(Near(breath.remaining,15) and breath.running,'BigWigs bar stopped counting: '..tostring(breath.remaining))
Pump(16)
assert(not breath.running and breath:GetParent()==UIParent,'Expired BigWigs bar not released')
-- A recycled bar started while hidden is hidden again.
BWSend('BigWigs_StartBar','Boss','k3','Fireball',25)
assert((bwBars.Fireball==breath or bwBars.Fireball==other) and bwBars.Fireball:GetParent()==B.holder,'Recycled BigWigs bar visible')
''')

# 4) Reversible: source toggles, timeline toggle, the two Hide options, combat.
lua.execute('''
local function DBMShown() return Own(long.frame) and long.frame:IsMouseEnabled() end
local function DBMHidden() return EffAlpha(long.frame)==0 and not long.frame:IsMouseEnabled() end
local function BWShown() return bwBars.Fireball:GetParent()==UIParent and bwBars['Tail Sweep']:GetParent()==UIParent and EffAlpha(bwBars.Fireball)==1 end
local function BWHidden() return bwBars.Fireball:GetParent()==B.holder and bwBars['Tail Sweep']:GetParent()==B.holder end
-- Options panel changes go through AT.Refresh().
AT.db.dbm=false; AT.Refresh(); assert(DBMShown() and BWHidden(),'DBM source off must restore DBM bars only')
assert(shortFrame:IsMouseEnabled(),'Recycled DBT frame kept a disabled mouse')
AT.db.dbm=true; AT.Refresh(); assert(DBMHidden())
AT.db.bigwigs=false; AT.Refresh(); assert(BWShown() and DBMHidden(),'BigWigs source off must restore BigWigs bars only')
AT.db.bigwigs=true; AT.Refresh(); assert(BWHidden(),'Running BigWigs bars not re-hidden')
AT.db.enabled=false; AT.Refresh(); assert(DBMShown() and BWShown() and not B.hidden.dbm and not B.hidden.bigwigs,'Timeline off must restore everything')
assert(B.Status()=='no boss mod bars hidden')
local visible=StartDBM('Visible',20); assert(Own(visible.frame) and visible.frame:IsMouseEnabled(),'Bar hidden while timeline off')
AT.db.enabled=true; AT.Refresh(); assert(DBMHidden() and BWHidden() and EffAlpha(visible.frame)==0)
AT.db.hideDBMBars=false; AT.Refresh(); assert(DBMShown() and BWHidden(),'Hide DBM bars off must restore DBM bars only')
assert(B.Status()=='BigWigs bars hidden')
AT.db.hideDBMBars=true; AT.Refresh(); assert(DBMHidden())
AT.db.hideBigWigsBars=false; AT.Refresh(); assert(BWShown() and DBMHidden(),'Hide BigWigs bars off must restore BigWigs bars only')
AT.db.hideBigWigsBars=true; AT.Refresh(); assert(BWHidden())
-- Combat: only alpha, mouse and parents of boss mod frames change, so the bars still follow.
combat=true
AT.db.enabled=false; AT.Refresh(); assert(DBMShown() and BWShown(),'Restore blocked in combat')
AT.db.enabled=true; AT.Refresh(); assert(DBMHidden() and BWHidden(),'Hide blocked in combat')
AT.db.hideDBMBars=false; AT.Refresh(); assert(DBMShown(),'Hide DBM bars ignored in combat')
AT.db.hideDBMBars=true; AT.Refresh(); assert(DBMHidden())
combat=false
-- ClickThrough changes while hidden keep bars click-through; restore follows the option.
DBT:SetOption('ClickThrough',false); assert(DBMHidden(),'SetOption re-enabled the mouse on a hidden bar')
DBT:SetOption('ClickThrough',true); AT.db.enabled=false; AT.Refresh(); assert(Own(long.frame) and not long.frame:IsMouseEnabled(),'ClickThrough not honoured on restore')
DBT:SetOption('ClickThrough',false); AT.db.enabled=true; AT.Refresh(); assert(DBMHidden())
-- DBM "Move bars" shows them while movable; the next bar after it ends is hidden again.
DBT:ShowMovableBar(); assert(DBT.movable and DBMShown() and Own(DBT:GetBar('Move1').frame),'Movable bars must be visible')
local moveEnd=scheduled[#scheduled]; moveEnd[1](moveEnd[2]); assert(not DBT.movable)
StartDBM('After Move',25); assert(DBMHidden() and EffAlpha(DBT:GetBar('After Move').frame)==0)
-- Dummy bars (DBM options preview) sit on UIParent and stay visible.
local dummy=DBT:CreateDummyBar(nil,nil,'Preview'); assert(dummy.frame:GetParent()==UIParent and Own(dummy.frame))
local same,key=SameTable(optionsBefore,DBT.Options); assert(same,'DBT option changed: '..tostring(key))
''')

# 5) The feature lives in AbilityTimeline only; EUI QoL no longer hides the bars.
src = read('AbilityTimeline/BossBars.lua')
assert 'SetRotatesTexture' not in src and 'EllesmereUI' not in src
toc = read('AbilityTimeline/AbilityTimeline.toc')
assert 'Sources.lua\nBossBars.lua\nOptions.lua' in toc.replace('\r\n', '\n')
assert not (root / 'EllesmereUIQoL' / 'EUI_QoL_335_BossBars.lua').exists()
assert 'BossBars' not in read('EllesmereUIQoL/EllesmereUIQoL.toc')
for rel in ['EllesmereUIQoL/EUI_QoL_335.lua', 'EllesmereUIOptions/EUI_QoL_335_Options.lua']:
    assert 'hideBossModBars' not in read(rel) and 'BossBars' not in read(rel), rel
print('PASS: with AbilityTimeline active, real DBT bars (existing, new, enlarged) go alpha 0 via their anchor and click-through '
      'while still counting down, expiring and feeding the timeline; BigWigs bars (message and LibCandyBar Start paths, '
      'on-demand load) park under a transparent holder that survives SetAlpha(1); late timeline load, source/timeline/Hide '
      'option toggles, combat, ClickThrough and Move Bars all restore correctly; DBT saved options untouched; both Hide options off leaves the bars alone.')
