"""QoL: hide DBM / BigWigs bars while AbilityTimeline shows their timers.

Runs the real DBM-StatusBarTimers DBT.lua and the real AbilityTimeline Core.lua
and Sources.lua in Lua 5.1, with mocked DBM-Core callbacks, BigWigs messages and
LibCandyBar. Bars must turn invisible and click-through while the timeline is
active, keep counting (and expiring) while invisible, come back when the
timeline, its source or the EUI option goes off, follow late/on-demand loading,
never touch DBM saved options, and do nothing at all without the timeline."""
from pathlib import Path
import sys
from game_paths import ADDONS, DATA, WTF
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

QOL_FILES = ['EUI_QoL_335.lua', 'EUI_QoL_335_Displays.lua', 'EUI_QoL_335_Panels.lua', 'EUI_QoL_335_Mail.lua',
             'EUI_QoL_335_Extras.lua', 'EUI_QoL_335_BossBars.lua']


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
                   'backport-tools/qol_mock.lua', 'EllesmereUI/EllesmereUI_Lite.lua']:
        lua.execute(read(source))
    lua.execute(MOCK)
    # DBM loads before EUI (folder order); the timeline is loaded later on purpose.
    lua.execute(read('DBM-StatusBarTimers/DBT.lua'))
    lua.execute("DBT:LoadOptions('DBM')")
    ns = lua.table()
    lua.execute("ERR_INV_FULL='Inventory is full.'")
    for name in QOL_FILES:
        lua.execute(read('EllesmereUIQoL/' + name), 'EllesmereUIQoL', ns)
    lua.globals().Q = ns
    core = read('EllesmereUI/EllesmereUI_Lite.lua')
    safe = lua.execute('local function errorhandler(' + core.split('local function errorhandler(', 1)[1].split(
        '\n-------------------------------------------------------------------------------', 1)[0] + '\nreturn safecall')
    safe(ns.addon.OnInitialize, ns.addon)
    safe(ns.addon.OnEnable, ns.addon)
    return lua


def load_timeline(lua):
    at = lua.table()
    for name in ['Core.lua', 'Sources.lua']:
        lua.execute(read('AbilityTimeline/' + name), 'AbilityTimeline', at)
    lua.globals().AT = at


# 1) No timeline installed: nothing is hooked, hidden or registered.
lua = runtime()
lua.execute('''
LoadBigWigsPlugins(); sendBarCreated=true
local B=Q.bossBars; local p=Q.GetSettings()
assert(p.hideBossModBars==true,'Option must default on')
local create,start,handlers=DBT.CreateBar,candy.barPrototype.Start,#bwHandlers
local bar=StartDBM('Boss Ability',30); BWSend('BigWigs_StartBar','Boss','k1','Breath',40)
Q.Apply(); B.events.scripts.OnEvent(B.events,'ADDON_LOADED','BigWigs_Plugins'); B.events.scripts.OnUpdate(B.events,0)
assert(Own(bar.frame) and bar.frame:IsMouseEnabled(),'DBM bar touched without the timeline')
assert(bwBars.Breath:GetParent()==UIParent and EffAlpha(bwBars.Breath)==1,'BigWigs bar touched without the timeline')
assert(DBT.CreateBar==create and candy.barPrototype.Start==start and #bwHandlers==handlers,'Hooks installed without the timeline')
assert(not B.hidden.dbm and not B.hidden.bigwigs and Q.BossBarsStatus()=='AbilityTimeline is not loaded')
''')

# 2) Full flow: DBM loaded, BigWigs loader only, timeline loads late.
lua = runtime()
lua.execute('''
B=Q.bossBars; p=Q.GetSettings()
optionsBefore=Snapshot(DBT.Options); createBefore=DBT.CreateBar
long=StartDBM('Boss Ability',120)
assert(Own(long.frame) and long.frame:IsMouseEnabled())
''')
load_timeline(lua)
lua.execute('''
-- QoL's ADDON_LOADED handler runs before the timeline's own: AT.db is not set yet.
B.events.scripts.OnEvent(B.events,'ADDON_LOADED','AbilityTimeline')
assert(not B.hidden.dbm and DBT.CreateBar==createBefore,'Acted before the timeline initialized')
AT.events.scripts.OnEvent(AT.events,'ADDON_LOADED','AbilityTimeline')
assert(AT.Sources.dbm=='callbacks' and AT.Sources.bigwigs=='loader')
assert(B.events:IsShown(),'Deferred re-check not armed'); B.events.scripts.OnUpdate(B.events,0); assert(not B.events:IsShown())
assert(B.hidden.dbm and B.hidden.bigwigs,'Timeline active but bars not hidden')
assert(EffAlpha(long.frame)==0 and long.frame:IsVisible() and not long.frame:IsMouseEnabled(),'Existing DBM bar must be invisible, shown and click-through')
assert(Q.BossBarsStatus()=='AbilityTimeline active: DBM and BigWigs bars hidden')
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

# 4) Reversible: timeline source toggles, timeline toggle, EUI option, QoL master switch.
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
assert(Q.BossBarsStatus()=='AbilityTimeline loaded: no boss mod bars hidden')
local visible=StartDBM('Visible',20); assert(Own(visible.frame) and visible.frame:IsMouseEnabled(),'Bar hidden while timeline off')
AT.db.enabled=true; AT.Refresh(); assert(DBMHidden() and BWHidden() and EffAlpha(visible.frame)==0)
p.hideBossModBars=false; Q.Apply(); assert(DBMShown() and BWShown(),'EUI option off must restore')
p.hideBossModBars=true; Q.Apply(); assert(DBMHidden() and BWHidden())
p.enabled=false; Q.Apply(); assert(DBMShown() and BWShown(),'QoL master switch off must restore'); p.enabled=true; Q.Apply(); assert(DBMHidden())
-- Combat: QoL defers its other work, the bars still follow (no frames created).
combat=true
AT.db.enabled=false; AT.Refresh(); assert(DBMShown() and BWShown(),'Restore blocked in combat')
AT.db.enabled=true; AT.Refresh(); assert(DBMHidden() and BWHidden(),'Hide blocked in combat')
p.hideBossModBars=false; Q.Apply(); assert(DBMShown(),'EUI option ignored in combat')
p.hideBossModBars=true; Q.Apply(); assert(DBMHidden())
combat=false; Q.events.scripts.OnEvent(Q.events,'PLAYER_REGEN_ENABLED'); assert(DBMHidden())
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

# 5) Options: Raid Tools > BOSS MOD BARS toggle with tooltip and live status.
lua.execute(read('EllesmereUIOptions/EUI_QoL_335_Options.lua'))
lua.execute("allFrames[#allFrames]:RunScript('OnEvent','PLAYER_LOGIN')")
lua.execute('''
local module=modules.EllesmereUIQoL; rows={}; module.buildPage('Raid Tools',UIParent,0)
local row=FindRow('Hide DBM/BigWigs Bars While Timeline Is Active')
assert(row.getValue()==true and row.tooltip:find('timers keep running',1,true))
FindRow('AbilityTimeline active: DBM and BigWigs bars hidden')
row.setValue(false); assert(p.hideBossModBars==false and Own(long.frame) and not B.hidden.bigwigs)
row.setValue(true); assert(EffAlpha(long.frame)==0 and B.hidden.bigwigs)
assert(module.searchTerms:find('bigwigs',1,true) and #module.pages==6)
''')

src = read('EllesmereUIQoL/EUI_QoL_335_BossBars.lua')
assert 'SetRotatesTexture' not in src
assert sum(1 for line in src.splitlines() if line.startswith('local ')) < 200
toc = read('EllesmereUIQoL/EllesmereUIQoL.toc')
assert 'EUI_QoL_335_Extras.lua\nEUI_QoL_335_BossBars.lua' in toc
assert 'hideBossModBars=true' in read('EllesmereUIQoL/EUI_QoL_335.lua')
print('PASS: with AbilityTimeline active, real DBT bars (existing, new, enlarged) go alpha 0 via their anchor and click-through '
      'while still counting down, expiring and feeding the timeline; BigWigs bars (message and LibCandyBar Start paths, '
      'on-demand load) park under a transparent holder that survives SetAlpha(1); late timeline load, source/timeline/EUI/QoL '
      'toggles, combat, ClickThrough and Move Bars all restore correctly; DBT saved options untouched; nothing happens without the timeline.')
