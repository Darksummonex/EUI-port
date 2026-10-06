"""Standalone AbilityTimeline 3.3.5 port: timeline math, big icon, centre text,
voice countdown, options and the DBM/BigWigs adapters (DBM callbacks, old DBM
bars, BigWigs loader messages, BigWigs AceEvent messages). Rendering still
needs in-game review."""
from pathlib import Path
import re
import sys
from game_paths import ADDONS, DATA, WTF
root=Path(__file__).resolve().parents[1]
addon=ADDONS/'AbilityTimeline'
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime

toc=(addon/'AbilityTimeline.toc').read_text(encoding='utf-8-sig')
assert '## Interface: 30300' in toc
assert '## SavedVariables: AbilityTimeline335DB' in toc
files=[l.strip() for l in toc.splitlines() if l.strip().endswith('.lua') and not l.startswith('#')]
assert files==['Core.lua','Sound.lua','Timeline.lua','Highlights.lua','Sources.lua','Options.lua'],files
for name in files:
    source=re.sub(r'--[^\n]*','',(addon/name).read_text(encoding='utf-8-sig'))
    for banned in ['C_Timer','C_EncounterTimeline','C_Spell','SetRotatesTexture','BackdropTemplate','SetSize(','SetAtlas','.png"']:
        assert banned not in source,(name,banned)
    assert not re.search(r'SetTexture\(\d',source),name
voices=['Male_1','Male_2','Female_1','AI_Male_1','AI_Male_2','AI_Female_1','AI_Female_2','D.va']
for v in voices:
    for n in range(1,6):
        assert (addon/'Media'/'Sounds'/v/f'{n}.ogg').is_file(),(v,n)

MOCK=r'''
local m=getmetatable(UIParent).__index
function m:SetPoint(...) self.point={...} end
function m:GetPoint() local p=self.point or {"CENTER",UIParent,"CENTER",0,0}; return p[1],p[2],p[3],p[4],p[5] end
function m:ClearAllPoints() self.point=nil end
function m:SetBackdrop(b) self.backdrop=b end
function m:SetBackdropColor(...) self.bgColor={...} end
function m:SetBackdropBorderColor(...) self.borderColor={...} end
function m:SetAlpha(a) self.alpha=a end
function m:EnableMouse(v) self.mouse=v end
function m:SetMovable() end
function m:SetClampedToScreen() end
function m:RegisterForDrag() end
function m:StartMoving() self.moving=true end
function m:StopMovingOrSizing() self.moving=nil end
function m:SetChecked(v) self.checked=v end
function m:GetChecked() return self.checked end
function m:SetValueStep(v) self.valueStep=v end
function m:GetValue() return self.value end
function m:SetValue(v) self.value=v; local f=self.scripts.OnValueChanged; if f then f(self,v) end end
function m:SetTextColor(...) self.textColor={...} end
local baseCreate=CreateFrame
function CreateFrame(kind,name,parent,template)
    local f=baseCreate(kind,name,parent,template)
    if name and template=="OptionsSliderTemplate" then
        for _,r in ipairs({"Text","Low","High"}) do _G[name..r]=f:CreateFontString() end
    elseif name and template=="InterfaceOptionsCheckButtonTemplate" then
        _G[name.."Text"]=f:CreateFontString()
    end
    return f
end
STANDARD_TEXT_FONT="Fonts\\FRIZQT__.TTF"
function GetSpellInfo(id) if id==69057 then return "Bone Spike",nil,"Interface\\Icons\\Ability_Warrior_BoneSpike" end end
sounds={}; function PlaySoundFile(path,channel) sounds[#sounds+1]=path; soundChannel=channel end
categories={}; function InterfaceOptions_AddCategory(p) categories[#categories+1]=p end
opened=0; function InterfaceOptionsFrame_OpenToCategory() opened=opened+1 end
GameTooltip=CreateFrame("GameTooltip","GameTooltip",UIParent); tipLines={}
function GameTooltip:SetOwner(o) self.owner=o; tipLines={} end
function GameTooltip:AddLine(t) tipLines[#tipLines+1]=t end
chat={}; DEFAULT_CHAT_FRAME={AddMessage=function(_,msg) chat[#chat+1]=msg end}
function hooksecurefunc(tbl,name,post)
    local orig=tbl[name]
    tbl[name]=function(...) local r={orig(...)}; post(...); return unpack(r) end
end
function FireEvent(event,...)
    for _,f in ipairs(allFrames) do
        if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f,event,...) end
    end
end
function LoadAddon(chunks)
    local ns={}
    for _,c in ipairs(chunks) do assert(loadstring(c[2],c[1]))("AbilityTimeline",ns) end
    FireEvent("ADDON_LOADED","AbilityTimeline")
    FireEvent("PLAYER_LOGIN")
    return ns
end
function FindIcon(path)
    for _,f in ipairs(AbilityTimeline335Frame.children) do
        if f.tex and f.tex.texture==path and f.shown then return f end
    end
end
function ShownChildren(frame,field)
    local n=0
    for _,f in ipairs(frame.children) do if f[field] and f.shown then n=n+1 end end
    return n
end
'''

def runtime(setup=''):
    lua=LuaRuntime()
    lua.execute((root/'backport-tools'/'wrath_mock.lua').read_text(encoding='utf-8-sig'))
    lua.execute(MOCK)
    lua.execute(setup)
    chunks=lua.table_from([lua.table_from([name,(addon/name).read_text(encoding='utf-8-sig')]) for name in files])
    lua.globals().LoadAddon(chunks)
    return lua

# Core, timeline, highlights, sound, options and slash commands without boss mods.
lua=runtime()
lua.execute(r'''
local AT=AbilityTimeline335
assert(AT.db==AbilityTimeline335DB and AT.db.window==10 and AT.db.positions.timeline.x==410)
assert(#categories==3 and categories[2].parent=="AbilityTimeline")
local dbm,bw=AT.Sources.Status(); assert(dbm=="not found" and bw=="not found")
assert(not AbilityTimeline335Frame.shown,"empty locked timeline hidden")
AT.Test()
assert(#AT.List()==4 and AT.List()[1].text=="Fireball")
assert(AT.Timeline.Offset(7)==300 and AT.Timeline.Offset(12,1)==465 and AT.Timeline.Offset(0)==20)
local fire=FindIcon("Interface\\Icons\\Spell_Fire_FlameBolt")
assert(fire and fire.point[1]=="CENTER" and fire.point[3]=="BOTTOM" and fire.point[5]==300,"fireball at 7s")
local nova=FindIcon("Interface\\Icons\\Spell_Frost_FrostNova")
assert(nova and nova.point[5]==465 and nova.alpha==.6,"frost nova queued first")
local enrage=FindIcon("Interface\\Icons\\Ability_Druid_ChallangingRoar")
assert(enrage and enrage.point[5]==465+2*45,"enrage queued third")
assert(fire.time.text=="7.0" and fire.name.text=="Fireball")
assert(AbilityTimeline335Frame.shown and AbilityTimeline335Frame.height==440)
assert(not AbilityTimeline335BigIcons.shown and #sounds==0)

now=now+3; AT.Tick()
assert(AbilityTimeline335BigIcons.shown and ShownChildren(AbilityTimeline335BigIcons,"count")==1)
local big; for _,f in ipairs(AbilityTimeline335BigIcons.children) do if f.count and f.shown then big=f end end
assert(big.count.text==4 and big.name.text=="Fireball")
local line; for _,f in ipairs(AbilityTimeline335Text.children) do if f.shown and f.text then line=f end end
assert(line and line.text=="Fireball - 4")
assert(#sounds==1 and sounds[1]:find("Sounds\\Male_1\\4.ogg",1,true) and soundChannel=="Master",sounds[1])
assert(fire.borderColor[1]==1,"5 second crossing flashes the border")
now=now+.5; AT.Tick(); assert(#sounds==1)
now=now+.6; AT.Tick(); assert(#sounds==2 and sounds[2]:find("\\3.ogg",1,true),"frame hitch speaks current number")
now=now+1; AT.Tick(); assert(#sounds==3 and sounds[3]:find("\\2.ogg",1,true))

AT.Clear(); sounds={}
AT.Start("X",1,"A",3.95,"a"); AT.Start("X",2,"B",3.9,"b"); AT.Tick()
assert(#sounds==2 and sounds[1]:find("Male_1",1,true) and sounds[2]:find("Male_2",1,true),"overlapping countdowns use different voices")
assert(ShownChildren(AbilityTimeline335BigIcons,"count")==2)
local va,vb=AT.timers["X:1"].voice,AT.timers["X:2"].voice
assert(va=="Male_1" and vb=="Male_2",tostring(va)..","..tostring(vb))
now=now+5; AT.Tick()
assert(#AT.List()==0 and not AbilityTimeline335Frame.shown and not AbilityTimeline335BigIcons.shown)
for v in pairs(AT.Sound.busy) do error("voice still busy: "..v) end
AT.Start("X",3,"C",3.95,"c"); AT.Tick()
assert(#sounds==3 and sounds[3]:find("Male_1\\4.ogg",1,true),"released voices are reused")
AT.Clear()

AT.db.inverse=true; AT.Refresh(); AT.Start("X",4,"D",7,"d")
local function near(a,b) return math.abs(a-b)<.01 end
assert(FindIcon("d").point[3]=="TOP" and near(FindIcon("d").point[5],-300))
AT.db.vertical=false; AT.Refresh()
assert(FindIcon("d").point[3]=="RIGHT" and near(FindIcon("d").point[4],-300) and AbilityTimeline335Frame.width==440)
AT.db.inverse=false; AT.db.vertical=true; AT.Clear()

AT.Start("X",5,"Paused",20,"p"); AT.Pause("X",5); now=now+8; AT.Tick()
assert(math.abs(AT.Remaining(AT.timers["X:5"])-20)<.001)
AT.Resume("X",5); now=now+2; assert(math.abs(AT.Remaining(AT.timers["X:5"])-18)<.001)
AT.Update("X",5,9,30); assert(AT.timers["X:5"].duration==30 and math.abs(AT.Remaining(AT.timers["X:5"])-9)<.001)
AT.Stop("X",5); assert(#AT.List()==0)
AT.db.enabled=false; AT.Start("X",6,"Off",5); assert(#AT.List()==0); AT.db.enabled=true
assert(AT.ResolveIcon(69057)=="Interface\\Icons\\Ability_Warrior_BoneSpike" and AT.ResolveIcon(nil)==AT.questionMark and AT.ResolveIcon(1)==AT.questionMark)

local byKey={}
for i=1,40 do local w=_G["AbilityTimeline335Option"..i]; if w and w.key then byKey[w.key]=w end end
for _,k in ipairs({"enabled","vertical","inverse","ticks","showNames","showQueued","textSide","window","length","width","iconSize","margin","maxQueued","bgAlpha","bigIcon","bigIconGrow","textHighlight","textGrow","sound","voice","bigIconSize","bigIconTime","textSize","textTime","dbm","bigwigs","pull"}) do
    assert(byKey[k],"option for "..k)
end
categories[1].refresh()
assert(byKey.vertical.checked==true and byKey.window.value==10)
byKey.vertical:SetChecked(false); byKey.vertical.scripts.OnClick(byKey.vertical); assert(AT.db.vertical==false)
byKey.vertical:SetChecked(true); byKey.vertical.scripts.OnClick(byKey.vertical)
byKey.window:SetValue(14.6); assert(AT.db.window==15 and byKey.window.text.text=="Timeline seconds: 15")
byKey.bgAlpha:SetValue(.52); assert(AT.db.bgAlpha==.5)
byKey.voice.scripts.OnClick(byKey.voice); assert(AT.db.voice=="Male_1")
AT.Start("X",7,"V",2.95,"v"); AT.Tick(); assert(sounds[#sounds]:find("Male_1\\3.ogg",1,true)); AT.Clear()
for _=1,7 do byKey.voice.scripts.OnClick(byKey.voice) end
assert(AT.db.voice=="D.va" and byKey.voice.text=="Voice: D.va")
AT.Start("X",8,"D",2.95,"dv"); AT.Tick(); assert(sounds[#sounds]:find("Sounds\\D.va\\3.ogg",1,true)); AT.Clear()
byKey.voice.scripts.OnClick(byKey.voice); assert(AT.db.voice=="auto")
byKey.bigIconGrow.scripts.OnClick(byKey.bigIconGrow); assert(AT.db.bigIconGrow=="LEFT")
AT.db.window=10

SlashCmdList.ABILITYTIMELINE("unlock")
assert(AT.db.locked==false and AbilityTimeline335Frame.shown and AbilityTimeline335BigIcons.shown and AbilityTimeline335Text.shown)
assert(AbilityTimeline335Frame.mouse==true and AT.Options.lockButton.text=="Lock")
AbilityTimeline335Frame.point={"CENTER",UIParent,"CENTER",123.4,-50.6}
AbilityTimeline335Frame.scripts.OnDragStop(AbilityTimeline335Frame)
assert(AT.db.positions.timeline.x==123 and AT.db.positions.timeline.y==-51)
-- Corner grip: drag right/down grows thickness/length on the vertical timeline.
local grip=AT.Timeline.grip
assert(grip.shown and grip.tex.texture:find("SizeGrabber"))
grip.scripts.OnEnter(grip); assert(#tipLines==3 and grip.tex.texture:find("Highlight")); grip.scripts.OnLeave(grip)
cursorX,cursorY=500,500; function GetCursorPosition() return cursorX,cursorY end
shift,alt=false,false; function IsShiftKeyDown() return shift end; function IsAltKeyDown() return alt end
local function Drag(dx,dy)
    cursorX,cursorY=500,500; grip.scripts.OnMouseDown(grip,"LeftButton"); assert(AT.Timeline.resizing)
    cursorX,cursorY=500+dx,500-dy; grip.scripts.OnUpdate(grip); grip.scripts.OnMouseUp(grip)
    assert(not AT.Timeline.resizing and not grip.scripts.OnUpdate)
end
AbilityTimeline335Frame.GetLeft=function() return 200 end; AbilityTimeline335Frame.GetTop=function() return 700 end
Drag(30,60)
assert(AT.db.width==80 and AT.db.length==460,"grip resizes thickness and length "..AT.db.width..","..AT.db.length)
assert(AT.db.positions.timeline.point=="TOPLEFT" and AT.db.positions.timeline.x==200 and AT.db.positions.timeline.y==700)
assert(AbilityTimeline335Frame.width==80 and AbilityTimeline335Frame.height==500 and byKey.length.value==460)
shift=true; Drag(-10,100); shift=false; assert(AT.db.width==70 and AT.db.length==460,"shift: width only")
alt=true; Drag(50,-60); alt=false; assert(AT.db.width==70 and AT.db.length==400,"alt: height only")
AT.db.vertical=false; AT.Refresh(); Drag(100,10); assert(AT.db.length==500 and AT.db.width==80,"horizontal swaps axes")
Drag(-5000,-5000); assert(AT.db.length==100 and AT.db.width==20,"limits")
AT.db.vertical=true; AT.db.width,AT.db.length=50,400; AT.Refresh()
SlashCmdList.ABILITYTIMELINE("lock")
assert(not grip.shown,"grip hidden while locked")
SlashCmdList.ABILITYTIMELINE("unlock")
AbilityTimeline335Frame.point={"CENTER",UIParent,"CENTER",123.4,-50.6}
AbilityTimeline335Frame.scripts.OnDragStop(AbilityTimeline335Frame)
SlashCmdList.ABILITYTIMELINE("lock")
assert(AT.db.locked and not AbilityTimeline335Frame.shown and AbilityTimeline335Frame.point[4]==123)
SlashCmdList.ABILITYTIMELINE("reset"); assert(AT.db.positions.timeline.x==410)
SlashCmdList.ABILITYTIMELINE("test"); assert(#AT.List()==4)
SlashCmdList.ABILITYTIMELINE("status"); assert(chat[#chat]:find("timers: 4",1,true))
SlashCmdList.ABILITYTIMELINE("clear"); assert(#AT.List()==0)
SlashCmdList.ABILITYTIMELINE(""); assert(opened==2)
''')

# Newer DBM builds: timer callbacks.
lua=runtime(r'''
cbs={}
DBM={RegisterCallback=function(self,event,f) assert(self==DBM); cbs[event]=f end}
''')
lua.execute(r'''
local AT=AbilityTimeline335
assert(AT.Sources.Status()=="callbacks")
cbs.DBM_TimerStart("DBM_TimerStart","t1","Bone Spike",20,69057,"cd",69057)
local t=AT.timers["DBM:t1"]; assert(t and t.text=="Bone Spike" and t.icon=="Interface\\Icons\\Ability_Warrior_BoneSpike")
cbs.DBM_TimerUpdate("DBM_TimerUpdate","t1",5,20); assert(math.abs(AT.Remaining(t)-15)<.001)
cbs.DBM_TimerPause("DBM_TimerPause","t1"); now=now+10; assert(math.abs(AT.Remaining(t)-15)<.001)
cbs.DBM_TimerResume("DBM_TimerResume","t1"); now=now+1; assert(math.abs(AT.Remaining(t)-14)<.001)
cbs.DBM_TimerStop("DBM_TimerStop","t1"); assert(not AT.timers["DBM:t1"])
cbs.DBM_TimerStart("DBM_TimerStart","p","Pull in",10,nil,"pull"); assert(AT.timers["DBM:p"])
AT.db.pull=false; cbs.DBM_TimerStart("DBM_TimerStart","p2","Pull in",10,nil,"pull"); assert(not AT.timers["DBM:p2"])
AT.db.dbm=false; cbs.DBM_TimerStart("DBM_TimerStart","t2","X",10); assert(not AT.timers["DBM:t2"])
FireEvent("ADDON_LOADED","Other"); assert(AT.Sources.Status()=="callbacks")
''')

# Older Wrath DBM: hooks on the DBT bar object.
lua=runtime(r'''
created={}
DBM={Bars={}}
function DBM.Bars:CreateBar(timer,id) created[#created+1]=id; return {} end
function DBM.Bars:CancelBar() end
function DBM.Bars:UpdateBar() end
function DBM.Bars:CancelAllBars() end
''')
lua.execute(r'''
local AT=AbilityTimeline335
assert(AT.Sources.Status()=="bars")
DBM.Bars:CreateBar(30,"Bone Storm","Interface\\Icons\\Ability_Whirlwind",nil,nil,{r=1,g=0,b=0})
local t=AT.timers["DBM:Bone Storm"]
assert(created[1]=="Bone Storm","original bar still created")
assert(t and t.text=="Bone Storm" and t.icon=="Interface\\Icons\\Ability_Whirlwind" and t.color[1]==1)
DBM.Bars:CreateBar(10,"Dummy",nil,nil,nil,nil,true); assert(not AT.timers["DBM:Dummy"])
DBM.Bars:UpdateBar("Bone Storm",10,30); assert(math.abs(AT.Remaining(t)-20)<.001)
DBM.Bars:CancelBar("Bone Storm"); assert(not AT.timers["DBM:Bone Storm"])
DBM.Bars:CreateBar(30,"A"); DBM.Bars:CreateBar(30,"B"); AT.Start("BW","C","C",30)
DBM.Bars:CancelAllBars(); assert(#AT.List()==1 and AT.List()[1].source=="BW")
AT.Sources.Attach(); DBM.Bars:CreateBar(30,"Once"); assert(#AT.List()==2,"hooks attach once")
''')

# Newer BigWigs: loader message API.
lua=runtime(r'''
msgs={}
BigWigsLoader={RegisterMessage=function(owner,msg,f) assert(owner==AbilityTimeline335.Sources); msgs[msg]=f end}
''')
lua.execute(r'''
local AT=AbilityTimeline335
assert(select(2,AT.Sources.Status())=="loader")
local mod={}
msgs.BigWigs_StartBar("BigWigs_StartBar",mod,69057,"Bone Spike",18,"Interface\\Icons\\Ability_Warrior_BoneSpike")
assert(AT.timers["BW:Bone Spike"] and math.abs(AT.Remaining(AT.timers["BW:Bone Spike"])-18)<.001)
msgs.BigWigs_StopBar("BigWigs_StopBar",mod,"Bone Spike"); assert(not AT.timers["BW:Bone Spike"])
msgs.BigWigs_StartBar("BigWigs_StartBar",mod,"pull","Pull",10); AT.Start("DBM","x","x",10)
msgs.BigWigs_OnBossDisable("BigWigs_OnBossDisable",mod); assert(#AT.List()==1 and AT.List()[1].source=="DBM")
AT.db.pull=false; msgs.BigWigs_StartBar("BigWigs_StartBar",mod,"pull","Pull",10); assert(not AT.timers["BW:Pull"])
AT.db.bigwigs=false; msgs.BigWigs_StartBar("BigWigs_StartBar",mod,1,"Off",10); assert(not AT.timers["BW:Off"])
''')

# Older Wrath BigWigs: AceEvent-3.0 messages.
lua=runtime(r'''
BigWigs={}
handlers={}
local ace={}
function ace:Embed(t) t.RegisterMessage=function(self,msg,f) handlers[msg]=f end; return t end
function LibStub(name,silent) assert(silent); if name=="AceEvent-3.0" then return ace end end
function SendMessage(msg,...) handlers[msg](msg,...) end
''')
lua.execute(r'''
local AT=AbilityTimeline335
assert(select(2,AT.Sources.Status())=="aceevent")
SendMessage("BigWigs_StartBar",{}, "impale","Impale",25,"Interface\\Icons\\Ability_SearingArrow")
assert(AT.timers["BW:Impale"] and AT.timers["BW:Impale"].icon=="Interface\\Icons\\Ability_SearingArrow")
SendMessage("BigWigs_StopBars",{}); assert(#AT.List()==0)
SendMessage("BigWigs_StartBar",{}, 1,"Whirl",25); SendMessage("BigWigs_OnBossWin",{}); assert(#AT.List()==0)
''')
print('AbilityTimeline 3.3.5 validation passed')
