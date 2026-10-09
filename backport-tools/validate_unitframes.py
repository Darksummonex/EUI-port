"""Lua 5.1 syntax and focused Wrath contract tests; not an in-game substitute."""
from pathlib import Path
import sys
import struct
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / '.codex-tools'))
from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parents[1]
lua = LuaRuntime(unpack_returned_tuples=True)
compiler = lua.eval('function(s,n) local f,e=loadstring(s,n); return f,e end')
count = 0
for folder in ['EllesmereUI', 'EllesmereUIOptions', 'EllesmereUIUnitFrames', 'EllesmereUIMinimap', 'EllesmereUIActionBars', 'EllesmereUIChat', 'EllesmereUINameplates', 'EllesmereUIBlizzardSkin', 'EllesmereUIBags', 'EllesmereUIResourceBars', 'EllesmereUIQoL', 'EllesmereUIRaidFrames', 'EllesmereUIDataBars']:
    for p in (root / folder).rglob('*.lua'):
        f, error = compiler(p.read_text(encoding='utf-8-sig'), str(p))
        assert f is not None, error
        count += 1

lua.execute((root / 'backport-tools/wrath_mock.lua').read_text())
lua.execute('assert(issecretvalue == nil and issecrettable == nil)')
lua.execute('function GetSpellInfo(id) return id==689 and "Drain Life" or id==47540 and "Penance" or tostring(id) end')
for helper in ['EUI_ChannelTicks_335.lua','EUI_AuraFilters_335.lua','EUI_AuraIndicators_335.lua']:
    lua.execute((root/'EllesmereUI'/helper).read_text())
# Use the real catalogue/resolver and a native-like statusbar contract: a
# rejected file does not yield a fill object. The old permissive mock hid this.
core_source = (root / 'EllesmereUI/EllesmereUI.lua').read_text(encoding='utf-8-sig')
catalog = 'EllesmereUI.BAR_TEXTURE_FILES =' + core_source.split('EllesmereUI.BAR_TEXTURE_FILES =', 1)[1].split('-- Numeric constants', 1)[0]
lua.execute('local MEDIA_PATH = "Interface\\\\AddOns\\\\EllesmereUI\\\\media\\\\"\n' + catalog)
resolver = core_source.split('function EllesmereUI.ResolveTexturePath(', 1)[1].split('\n-------------------------------------------------------------------------------', 1)[0]
lua.execute('function EllesmereUI.ResolveTexturePath(' + resolver)

def can_load_texture(path):
    if not isinstance(path, str):
        return path is not None
    relative = path.replace('\\', '/')
    if not relative.lower().startswith('interface/addons/'):
        return True
    asset = root / relative[len('Interface/AddOns/'):]
    if not asset.is_file():
        return False
    if asset.suffix.lower() != '.tga':
        return True
    width, height, depth = struct.unpack('<HHB', asset.read_bytes()[12:17])
    return width > 0 and height > 0 and width & (width - 1) == 0 and height & (height - 1) == 0 and depth in (24, 32)

lua.globals().canLoadTexture = can_load_texture
lua.execute('''
local methods = getmetatable(UIParent).__index
function methods:GetStatusBarTexture() return self.barTex end
function methods:SetStatusBarTexture(path)
    if not canLoadTexture(path) then self.barTex=nil; return false end
    if type(path)=="table" then self.barTex=path
    else self.barTex=self:CreateTexture(); self.barTex:SetTexture(path) end
    return true
end
''')
ns = lua.table()
def load(name):
    f, error = compiler((root / 'EllesmereUIUnitFrames' / name).read_text(encoding='utf-8-sig'), name)
    assert f, error
    f('EllesmereUIUnitFrames', ns)

load('EUI_UnitFrames_335.lua')
load('EUI_UnitFrames_335_Textures.lua')
load('EUI_UnitFrames_335_Media.lua')
lua.globals().W = ns.Wrath
lua.execute('''
assert(type(W.IsSecretValue) == "function")
assert(not W.IsSecretValue(nil) and not W.IsSecretValue(42) and not W.IsSecretValue({}))
assert(issecretvalue == nil, "module must not require the Options global")
local preview = W.CreateFrame("Frame"):CreateTexture()
preview:SetAtlas("nameplates-icon-elite-gold")
assert(preview.texture == "Interface\\\\AddOns\\\\EllesmereUIUnitFrames\\\\Media\\\\elite-badge-335.tga")
assert(preview.texcoords[2] == 43/64 and preview.desaturated == false)
for _, name in ipairs({"nameplates-icon-elite-silver", "nameplates-icon-rareelite"}) do
    preview:SetAtlas(name); assert(preview.desaturated == true)
end
preview:SetAtlas("nameplates-icon-elite-gold", true)
assert(preview.desaturated == false and preview.width == 16 and preview.height == 16)
local moods = {["UI-PetHappiness"]=0, ["UI-PetNeutral"]=.1875, ["UI-PetMad"]=.375}
for name, left in pairs(moods) do
    preview:SetAtlas(name, true)
    assert(preview.texture == "Interface\\\\PetPaperDollFrame\\\\UI-PetHappiness")
    assert(preview.texcoords[1] == left and preview.texcoords[2] == left+.1875)
    assert(preview.width == 24 and preview.height == 23)
end
preview:SetAtlas("classicon-warrior")
assert(preview.texture == "Interface\\\\AddOns\\\\EllesmereUI\\\\media\\\\icons\\\\class-full\\\\modern.tga")
assert(preview.texcoords[2] == EllesmereUI.CLASS_ICON_SPRITE_COORDS.WARRIOR[2])
preview:SetAtlas("UI-CastingBar-Fill")
assert(preview.texture == "Interface\\\\TargetingFrame\\\\UI-StatusBar")
preview:SetAtlas("unsupported-decoration")
assert(preview.texture == nil and nativeAtlasCalls == 0)
local status = W.CreateFrame("StatusBar")
status:SetStatusBarTexture("Interface\\\\Buttons\\\\WHITE8X8")
status:GetStatusBarTexture():SetAtlas("UI-CastingBar-Fill")
assert(status:GetStatusBarTexture().texture == "Interface\\\\TargetingFrame\\\\UI-StatusBar")
local mask = status:CreateMaskTexture()
mask:SetAtlas("unsupported-mask"); assert(mask.texture == nil and nativeAtlasCalls == 0)
atlasInfoMock["wrath-existing-atlas"]={width=32,height=32}
preview:SetAtlas("wrath-existing-atlas", true)
assert(preview.atlas == "wrath-existing-atlas" and preview.atlasUseSize == true and nativeAtlasCalls == 1)
-- Also support clients whose AtlasUtil owns the registry rather than C_Texture.
local getInfo = C_Texture.GetAtlasInfo
C_Texture.GetAtlasInfo=function() return nil end
AtlasUtil={AtlasExists=function(_, name) return atlasInfoMock[name] ~= nil end}
preview:SetAtlas("wrath-existing-atlas")
assert(nativeAtlasCalls == 2)
preview:SetAtlas("missing-even-with-atlasutil"); assert(preview.texture == nil and nativeAtlasCalls == 2)
C_Texture.GetAtlasInfo=getInfo; AtlasUtil=nil
local f = W.CreateFrame("Frame")
local seen = {}
f:RegisterUnitEvent("UNIT_POWER_UPDATE", "player", "vehicle")
f:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
f:SetScript("OnEvent", function(_, event, unit, kind) seen[event] = (seen[event] or 0)+1; assert(kind == "MANA") end)
f:GetScript("OnEvent")(f, "UNIT_MANA", "target")
assert(not next(seen), "unit filtering failed")
f:GetScript("OnEvent")(f, "UNIT_MANA", "player")
assert(seen.UNIT_POWER_UPDATE == 1 and seen.UNIT_POWER_FREQUENT == 1)
f:UnregisterEvent("UNIT_POWER_UPDATE")
assert(f.events.UNIT_MANA, "shared registration removed too early")
f:GetScript("OnEvent")(f, "UNIT_MANA", "vehicle")
assert(seen.UNIT_POWER_FREQUENT == 1)
f:UnregisterEvent("UNIT_POWER_FREQUENT")
assert(not f.events.UNIT_MANA)
f:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
assert(not f.events.UNIT_ABSORB_AMOUNT_CHANGED)
local talents = W.CreateFrame("Frame")
talents:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
talents:SetScript("OnEvent", function(_, event, unit) assert(event == "PLAYER_SPECIALIZATION_CHANGED" and unit == "player") end)
talents:GetScript("OnEvent")(talents, "ACTIVE_TALENT_GROUP_CHANGED", 2)
local edit = W.CreateFrame("EditBox")
assert(edit.autoFocus == false)
edit.focus = true; edit.hooks.OnHide(edit); assert(edit.focus == false)
assert(not edit.SetPropagateKeyboardInput and not edit.scripts.OnKeyDown)
local name,text,icon,startMS,endMS,trade,_,protected = W.UnitCastingInfo("player")
assert(name == "Fireball" and text == "Fireball" and icon == "fire-icon" and startMS == 1000 and endMS == 4000)
assert(protected == false and trade == false)
local channel,_,channelIcon,cs,ce,_,locked = W.UnitChannelInfo("target")
assert(channel == "Drain Life" and channelIcon == "drain-icon" and cs == 1000 and ce == 6000 and locked == true)
local duration = W.UnitCastingDuration("player")
assert(duration:GetTotalDuration() == 3 and duration:GetElapsedDuration() == 1 and duration:GetRemainingDuration() == 2)
local bar = W.CreateFrame("StatusBar")
bar:SetTimerDuration(duration, nil, Enum.StatusBarTimerDirection.ElapsedTime)
assert(bar.value == 1 and bar.maximum == 3)
bar.casting = true; now = 3; bar.hooks.OnUpdate(bar); assert(bar.value == 2)
now = 4; bar.hooks.OnUpdate(bar); assert(not bar.shown and not bar.casting)
now = 2
local curve = C_CurveUtil.CreateColorCurve()
curve:AddPoint(0,W.CreateColor(1,0,0,1)); curve:AddPoint(1,W.CreateColor(0,1,0,1))
local color = W.UnitHealthPercent("player", true, curve)
assert(color.r == .75 and color.g == .25)
assert(W.UnitPowerPercent("player",0,true,CurveConstants.ScaleTo100) == 50)
assert(W.UnitHealthPercent("missing",true,CurveConstants.ScaleTo100) == 0)
''')
load('EUI_UnitFrames_Engine.lua')
load('EllesmereUIUnitFrames.lua')
lua.execute('function EllesmereUI.Lite.NewDB(_, defaults) testUnitDB={profile=defaults.profile}; return testUnitDB end')
lua.execute('testAddon:OnInitialize()')
lua.globals().UF = ns
lua.execute('testUnitDB.profile.player.healthBarTexture="fade"')
load('EUI_UnitFrames_335_Auras.lua')
lua.execute((root/'EllesmereUI/EllesmereUI_Absorbs_335.lua').read_text(encoding='utf-8-sig'))
load('EUI_UnitFrames_335_Absorbs.lua')
lua.execute('''
-- Blizzard layout runs before name font initialization. Model an untemplated
-- level FontString honestly: no implicit font, and SetText requires one.
local methods=getmetatable(UIParent).__index
local createFontString=methods.CreateFontString
function methods:CreateFontString(...)
    local fs=createFontString(self,...)
    if self.parent and self.parent._blizzLevelHost == self then
        function fs:GetFont() return self.fontFace,self.fontSize,self.fontFlags end
        function fs:SetFont(face,size,flags)
            if face == "missing-font.ttf" then return false end
            assert(type(face)=="string" and size>0)
            self.fontFace,self.fontSize,self.fontFlags=face,size,flags
            return true
        end
        function fs:SetFontObject(obj)
            assert(obj, "missing Retail FontObject passed to SetFontObject")
            self.fontObject=obj
            self:SetFont(obj:GetFont())
        end
        function fs:SetText(text)
            assert(self.fontFace, "Blizzard level SetText(): Font not set")
            self.text=text
        end
    end
    return fs
end
local geom=UF.UF_BlizzGeom
UF.UF_BlizzGeom=function(frame)
    return frame._testLevelGeom or geom(frame)
end
local level=UnitLevel
local effectiveLevel=UnitEffectiveLevel
local exists=UnitExists
local frames={}
local settings=testUnitDB.profile.player
assert(GameNormalNumberFont==nil)
settings.blizzLevelSize=17
for _,unit in ipairs({"player","target","focus"}) do
    local frame=W.CreateFrame("Frame")
    frame._euiUnit,frame._euiBaseUnit=unit,unit
    frame._testLevelGeom={level={point="CENTER",x=0,y=0}}
    frames[unit]=frame
    UF.UF_BlizzLevelPass(frame)
    assert(frame._blizzLevel:GetFont(), unit.." level has no initial font")
    assert(frame._blizzLevel.text==80 and frame._blizzLevel:IsShown())
end
local frame=frames.player
assert(frame._blizzLevel.fontSize==17)
local count=#UF._ufBlizzLevelFrames
local events=UF._ufBlizzLevelEvents
-- Later layout inherits the name font, retaining the level's custom size.
local nameFont={GetFont=function() return "Fonts\\\\ARIALN.TTF",13,"OUTLINE" end}
frame.LeftText={GetFont=nameFont.GetFont,GetFontObject=function() return nameFont end}
UF.UF_BlizzLevelPass(frame)
assert(frame._blizzLevel.fontFace=="Fonts\\\\ARIALN.TTF" and frame._blizzLevel.fontSize==17)
assert(frame._blizzLevel.fontObject==nameFont)
assert(#UF._ufBlizzLevelFrames==count and UF._ufBlizzLevelEvents==events)
-- Real shared event handler, skull transitions, visibility and absent unit.
UnitLevel=function() return 81 end; UnitEffectiveLevel=UnitLevel
events:GetScript("OnEvent")(events,"PLAYER_LEVEL_UP",81)
assert(frame._blizzLevel.text==81)
UnitEffectiveLevel=function() return -1 end
UF.UF_BlizzLevelRefresh(frames.target)
assert(not frames.target._blizzLevel:IsShown() and frames.target._blizzLevelSkull:IsShown())
settings.blizzShowLevel=false; UF.UF_BlizzLevelRefresh(frame)
assert(not frame._blizzLevel:IsShown() and not frame._blizzLevelSkull:IsShown())
settings.blizzShowLevel=true; UnitEffectiveLevel=UnitLevel
UF.UF_BlizzLevelRefresh(frame); assert(frame._blizzLevel:IsShown())
UnitExists=function() return false end; UF.UF_BlizzLevelRefresh(frame)
assert(not frame._blizzLevel:IsShown() and not frame._blizzLevelSkull:IsShown())
settings.blizzLevelSize=nil; settings.blizzShowLevel=nil
UnitLevel,UnitEffectiveLevel,UnitExists=level,effectiveLevel,exists
UF.UF_BlizzGeom=geom
''')
lua.execute('InitializeFrames(); SetupOptionsPanel()')
lua.globals().UF = ns
lua.execute('''
-- A rejected custom file must still leave an actual native font before text.
local getFontPath=EllesmereUI.GetFontPath
EllesmereUI.GetFontPath=function() return "missing-font.ttf" end
UF.ResolveFontPath()
local fallback=W.CreateFrame("Frame")
fallback._euiUnit,fallback._euiBaseUnit="player","player"
fallback._blizzGeom={level={point="CENTER",x=0,y=0}}
UF.UF_BlizzLevelPass(fallback)
assert(fallback._blizzLevel.fontFace==(STANDARD_TEXT_FONT or "Fonts\\\\FRIZQT__.TTF"))
assert(fallback._blizzLevel.text==80 and fallback._blizzLevel.fontSize==12)
EllesmereUI.GetFontPath=getFontPath; UF.ResolveFontPath()
-- Regression: the user's saved Fade setting failed in CreatePowerBar:7546.
assert(UF.frames.player.Power:GetStatusBarTexture():GetTexture() == UF.healthBarTextures.fade)
assert(UF.healthBarTextures.fade:find("Textures_335", 1, true))
local function FlushReload()
    UF.ReloadFrames()
    for i=1,10 do
        local name,frame=debug.getupvalue(UF.ReloadFrames,i)
        if name=="reloadThrottle" then frame:GetScript("OnUpdate")(frame); return end
    end
    error("reload throttle not found")
end
-- Exercise every real catalogue choice on live frame rebuilds.
for _, key in ipairs(UF.healthBarTextureOrder) do
    UF.db.profile.player.healthBarTexture=key
    FlushReload()
    local expected=EllesmereUI.ResolveTexturePath(UF.healthBarTextures,key,"Interface\\\\Buttons\\\\WHITE8X8")
    local actual=UF.frames.player.Power:GetStatusBarTexture():GetTexture()
    assert(actual:lower() == expected:lower(), key..": "..actual.." expected "..expected)
end
UF.db.profile.player.healthBarTexture="fade"
FlushReload()
-- Wrath sends boss health only under the target/focus token: shown boss frames repaint on a poll.
do
    local b1=UF.frames.boss1; assert(b1, "boss1 frame")
    local vis,frames,ticker
    for i=1,30 do local n,v=debug.getupvalue(UF.Engine.Attach,i); if not n then break end
        if n=="BossVisibilityChanged" then vis=v elseif n=="bossFrames" then frames=v end end
    assert(vis and frames and frames[b1], "boss1 joins the boss poll")
    for i=1,10 do local n,v=debug.getupvalue(vis,i); if not n then break end; if n=="bossTicker" then ticker=v end end
    local health,wasShown=UnitHealth,{}
    for i=1,5 do local f=UF.frames["boss"..i]; if f then wasShown[f]=f:IsShown() end end
    b1:Show(); vis(); assert(ticker:IsShown(), "boss poll runs while a boss frame shows")
    UnitHealth=function(u) if u=="boss1" then return 7 end return health(u) end
    local savedNow=now
    now=(now or 0)+1
    ticker:GetScript("OnUpdate")(ticker,.25)
    assert(b1.Health.value==7, "untargeted boss health repaints: "..tostring(b1.Health.value))
    UnitHealth,now=health,savedNow
    for i=1,5 do local f=UF.frames["boss"..i]; if f then f:Hide() end end
    vis(); assert(not ticker:IsShown(), "boss poll stops with no boss frame shown")
    for f,shown in pairs(wasShown) do if shown then f:Show() end end
    vis()
end
-- Wrath shields: the Core estimate on player/target/focus/boss health bars, seeded
-- on once, Retail UF "Striped" = striped3 stretched, overshield backfilled.
do
    local AB=EllesmereUI.Absorbs; AB.Reset()
    local pl=UF.frames.player; local o=pl._euiWrathAbsorb
    assert(o and UF.frames.target._euiWrathAbsorb and UF.frames.focus._euiWrathAbsorb and not UF.frames.pet._euiWrathAbsorb)
    local ps=UF.db.profile.player
    assert(ps.showPlayerAbsorb=="striped" and ps.wrathAbsorbSeeded and UF.db.profile.target.showPlayerAbsorb=="striped")
    ps.showPlayerAbsorb="none"; FlushReload(); assert(ps.showPlayerAbsorb=="none", "seed runs once"); ps.showPlayerAbsorb="striped"
    local W0=pl.Health:GetWidth()
    o.fw.SetVertexColor=function(self,...) self.vertexColor={...} end
    AB.CombatLog(0,"SPELL_AURA_APPLIED","X",nil,0,"player",nil,0,17,"Power Word: Shield",2,"BUFF")
    assert(EllesmereUI.GetUnitAbsorb("player")==44 and o.fw:IsShown() and not o.os:IsShown())
    -- Stretched styles use bar-space texcoords, so texcoords[1] is the segment start.
    assert(math.abs(o.fw.texcoords[1]-.25)<1e-6 and math.abs(o.fw:GetWidth()-W0*.44)<.01)
    assert(o.fw:GetTexture():find("shields_335\\\\striped3.tga",1,true) and canLoadTexture(o.fw:GetTexture()))
    assert(math.abs(o.fw.vertexColor[4]-.8)<1e-6, "unset opacity keeps Retail 0.8")
    AB.CombatLog(0,"SWING_DAMAGE","M",nil,0,"player",nil,0,100,0,1,0,0,24)
    assert(EllesmereUI.GetUnitAbsorb("player")==20 and math.abs(o.fw:GetWidth()-W0*.2)<.01)
    AB.CombatLog(0,"SPELL_AURA_APPLIED","X",nil,0,"player",nil,0,48066,"Power Word: Shield",2,"BUFF")
    assert(o.os:IsShown() and math.abs(o.os:GetWidth()-W0*.25)<.01 and o.os.texcoords[1]==0 and math.abs(o.os.texcoords[2]-.25)<1e-6)
    ps.overshieldMode="fromleft"; UF.UF_WrathAbsorbRefresh(); assert(o.os:IsShown() and o.os.texcoords[1]==0)
    ps.overshieldMode="never"; UF.UF_WrathAbsorbRefresh(); assert(not o.os:IsShown()); ps.overshieldMode=nil
    ps.showPlayerAbsorb="clean"; ps.absorbOpacity=nil; UF.UF_WrathAbsorbRefresh()
    assert(o.fw:GetTexture()=="Interface\\\\Buttons\\\\WHITE8X8" and math.abs(o.fw.vertexColor[4]-.3)<1e-6)
    ps.showPlayerAbsorb="none"; UF.UF_WrathAbsorbRefresh(); assert(not o.fw:IsShown() and not o.os:IsShown()); ps.showPlayerAbsorb="striped"
    local b1=UF.frames.boss1
    if b1 and b1._euiWrathAbsorb then
        AB.CombatLog(0,"SPELL_AURA_APPLIED","X",nil,0,"boss1",nil,0,17,"Power Word: Shield",2,"BUFF")
        assert(b1._euiWrathAbsorb.fw:IsShown(), "boss frames use the target styling")
        UF.db.profile.boss.showAbsorbs=false; UF.UF_WrathAbsorbRefresh(); assert(not b1._euiWrathAbsorb.fw:IsShown())
        UF.db.profile.boss.showAbsorbs=nil
    end
    -- Options preview: same overlay on the preview bar, sample shield, preview fill direction.
    local host=W.CreateFrame("Frame")
    UF.UF_WrathAbsorbPreview(host,{showPlayerAbsorb="striped",absorbOpacity=50},100,20,.7,.4)
    local po=host._euiWrathAbsorbPreview
    assert(po.fw:IsShown() and math.abs(po.fw.texcoords[1]-.7)<1e-6 and math.abs(po.fw:GetWidth()-30)<.01)
    assert(po.os:IsShown() and math.abs(po.os.texcoords[1]-.6)<1e-6 and math.abs(po.os:GetWidth()-10)<.01)
    UF.UF_WrathAbsorbPreview(host,{showPlayerAbsorb="striped",healthReverseFill=true},100,20,.7,.2)
    assert(math.abs(po.fw.texcoords[1]-.1)<1e-6 and math.abs(po.fw:GetWidth()-20)<.01)
    UF.UF_WrathAbsorbPreview(host,nil,100,20,.7,.2); assert(not po.fw:IsShown())
    AB.Reset(); UF.UF_WrathAbsorbRefresh(); assert(not o.fw:IsShown())
end
local fallbackBar = W.CreateFrame("StatusBar")
assert(fallbackBar:GetStatusBarTexture() == nil, "getter must not invent a fill")
fallbackBar:SetStatusBarTexture("Interface\\\\AddOns\\\\MissingMedia\\\\absent.tga")
assert(fallbackBar:GetStatusBarTexture():GetTexture() == "Interface\\\\Buttons\\\\WHITE8X8")
fallbackBar:SetStatusBarTexture("Interface\\\\AddOns\\\\EllesmereUI\\\\media\\\\textures\\\\fade.tga")
assert(fallbackBar:GetStatusBarTexture():GetTexture() == UF.healthBarTextures.fade)
fallbackBar:SetStatusBarTexture("Interface\\\\TargetingFrame\\\\UI-StatusBar")
assert(fallbackBar:GetStatusBarTexture():GetTexture() == "Interface\\\\TargetingFrame\\\\UI-StatusBar")
fallbackBar:SetStatusBarTexture(nil)
assert(fallbackBar:GetStatusBarTexture() == nil, "intentional clearing must remain native")
local preview = W.CreateFrame("Frame"):CreateTexture()
preview:SetTexture("Interface\\\\AddOns\\\\EllesmereUI\\\\media\\\\textures\\\\fade.tga")
assert(preview:GetTexture() == UF.healthBarTextures.fade)
-- Rotation is cosmetic and must never reach the crashing native method on
-- Wrath, whether or not a fill exists. Orientation remains native/functional.
local noFill = {
    SetRotatesTexture=function() error("rotation called without fill") end,
    GetStatusBarTexture=function() return nil end,
}
UF.ApplyFillRotation(noFill)
local orientBar = W.CreateFrame("StatusBar")
orientBar:SetStatusBarTexture("Interface\\\\Buttons\\\\WHITE8x8")
for _, axis in ipairs({"HORIZONTAL", "VERTICAL"}) do
    orientBar:SetOrientation(axis)
    UF.ApplyFillRotation(orientBar)
    assert(orientBar:GetOrientation() == axis)
end
assert(rotationCalls == 0, "initialization entered native rotation")
local function Dispatch(event, ...)
    for _, f in ipairs(allFrames) do
        if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f,event,...) end
    end
end
local player=UF.frames.player
UF.db.profile.player.showPlayerCastbar=true
UF.ReloadFrames()
assert(rotationCalls == 0, "reload entered native rotation")
player:EnableElement("Castbar"); UF.Engine.RepaintAll(player,"Test")
assert(player and player.Health and player.Power and player.Castbar and player.Castbar.casting)
assert(player:GetAttribute("*type2")=="menu" and type(player.menu)=="function")
Dispatch("UNIT_SPELLCAST_STOP","player","Fireball","Rank 1",19)
assert(not player.Castbar.casting)
castingMock=false
Dispatch("UNIT_SPELLCAST_CHANNEL_START","target","Drain Life","Rank 1")
assert(UF.frames.target.Castbar.channeling)
local cb=UF.frames.target.Castbar
assert(#cb._euiChannelTicks==4 and cb._euiChannelTicks[4]:IsShown())
assert(not cb._eui335TimerHook, "Castbar has competing OnUpdate clocks")
local firstValue=cb.value
now=2.016; cb:GetScript("OnUpdate")(cb,.016)
assert(math.abs(cb.value-(firstValue-.016))<.00001)
channelEnd=5000; Dispatch("UNIT_SPELLCAST_CHANNEL_UPDATE","target","Drain Life","Rank 1")
assert(cb._wrathChannelSchedule.interval==1 and cb._euiChannelTicks[3]:IsShown() and not cb._euiChannelTicks[4]:IsShown())
channelEnd=nil
Dispatch("UNIT_SPELLCAST_CHANNEL_STOP","target","Drain Life","Rank 1")
assert(not cb._euiChannelTicks[1]:IsShown())
channelName="Penance"; Dispatch("UNIT_SPELLCAST_CHANNEL_START","target","Penance","Rank 1")
assert(cb._euiChannelTicks[1]:IsShown() and not cb._euiChannelTicks[2]:IsShown())
now=6.01; cb:GetScript("OnUpdate")(cb,.016)
assert(not cb:IsShown() and not cb.channeling and not cb._euiChannelTicks[1]:IsShown())
channelName=nil; now=2
Dispatch("UNIT_SPELLCAST_CHANNEL_STOP","target","Drain Life","Rank 1")
assert(not UF.frames.target.Castbar.channeling)
castingMock=true
local opts={breakpointData={{breakpoint=1000,significandDivisor=100,fractionDivisor=10,abbreviation="k"}}}
assert(W.AbbreviateNumbers(12345,opts)=="12.3k")
local c=C_CurveUtil.CreateCurve(); c:SetType(Enum.LuaCurveType.Step); c:AddPoint(0,1); c:AddPoint(1,0)
assert(c:Evaluate(.5)==1 and c:Evaluate(1)==0)
''')
lua.execute('IsLoggedIn=function() return true end')
f, error = compiler((root/'EllesmereUIOptions/EUI_UnitFrames_Options.lua').read_text(encoding='utf-8-sig'), 'EUI_UnitFrames_Options.lua')
assert f, error
f()
lua.execute('assert(testModule and #testModule.pages == 6 and testModule.pages[4] == "Buffs" and testModule.pages[5] == "Debuffs" and testModule.pages[6] == "Aura Filters" and SlashCmdList.ELLESMEREUNITFRAMES)')
lua.execute('''
local settings = { showBuffs=true, buffAnchor="topleft", debuffAnchor="bottomleft", maxBuffs=4, maxDebuffs=4, debuffFilterMode="own" }
UF.UF_GetSettings = function() return settings end
local frame = W.CreateFrame("Button"); frame._euiUnit="target"; frame:SetSize(200,40)
UF.UF_CreateAuraContainers(frame,"target")
local buffs, debuffs = frame.children[1], frame.children[2]
assert(#buffs.buttons == 1 and buffs.buttons[1].index == 1)
assert(#debuffs.buttons == 1 and debuffs.buttons[1].index == 2)
assert(debuffs.buttons[1].icon.texture == "mine-icon")
settings.debuffFilterMode="all"; UF.UF_ReloadAuraContainers(frame,"target")
assert(#debuffs.buttons == 2 and debuffs.buttons[1].icon.texture == "other-icon")
settings.debuffExclude = { [101]=true }; UF.UF_ReloadAuraContainers(frame,"target")
assert(debuffs.buttons[1].icon.texture == "mine-icon" and not debuffs.buttons[2].shown)
settings.debuffExclude={}; settings.debuffFilterMode="tracked"; settings.debuffInclude={[101]=true}
UF.UF_ReloadAuraContainers(frame,"target"); assert(debuffs.buttons[1].icon.texture=="other-icon" and not debuffs.buttons[2].shown)
settings.debuffIncludeMine={[101]=true}; UF.UF_ReloadAuraContainers(frame,"target"); assert(not debuffs.shown)
settings.debuffIncludeMine={}; settings.debuffHasDuration=true; UF.UF_ReloadAuraContainers(frame,"target"); assert(debuffs.shown)
settings.buffFilterMode="tracked"; settings.buffInclude={[100]=true}; UF.UF_ReloadAuraContainers(frame,"target"); assert(buffs.shown)
settings.buffExclude={[100]=true}; UF.UF_ReloadAuraContainers(frame,"target"); assert(not buffs.shown)
settings.showBuffs=false; UF.UF_ReloadAuraContainers(frame,"target"); assert(not buffs.shown)
UF.UF_HideAuraContainers(frame); assert(not debuffs.shown)
''')
lua.execute('''
-- Retail aura look keys on the Wrath lanes: layout, crop, text, borders,
-- weapon enchants, right-click cancel, purge glow and the dispel overlay.
local methods = getmetatable(UIParent).__index
local setPoint, setLevel, border = methods.SetPoint, methods.SetFrameLevel, EllesmereUI.ApplyBorderStyle
function methods:SetPoint(...) self.point = {...} end
function methods:SetFrameLevel(v) self.level = v end
function EllesmereUI.ApplyBorderStyle(f, size, r, g, b, a, tex) f.bs = {size=size, r=r, g=g, b=b, a=a, tex=tex} end
local fmt = UF.UF_WrathFormatAuraDuration
assert(fmt(30) == "30" and fmt(90) == "2m" and fmt(90, 120) == "1:30" and fmt(150, 120) == "3m" and fmt(7200) == "2h")
local s = { showBuffs=true, buffAnchor="topleft", buffGrowth="auto", maxBuffs=4, buffSize=20, buffSpacingX=2, buffSpacingY=3,
    debuffAnchor="bottomright", debuffGrowth="left", maxDebuffs=8, debuffSize=30, debuffCropIcons=true, debuffMaxPerRow=1,
    debuffShowCooldownText=true, debuffStackTextPosition="topleft", debuffDispelBorder=true, auraBorderTexture="beveled" }
UF.UF_GetSettings = function() return s end
local frame = W.CreateFrame("Button"); frame._euiUnit="target"; frame:SetSize(200,40)
UF.UF_CreateAuraContainers(frame,"target")
local buffs, debuffs = frame.children[1], frame.children[2]
assert(buffs.width == 20 and buffs.height == 20 and buffs.point[1] == "BOTTOMLEFT" and buffs.point[3] == "TOPLEFT")
assert(buffs.buttons[1].count.text == 2 and buffs.buttons[1].border.level == 3 and buffs.buttons[1].textFrame.level == 5)
local d1, d2 = debuffs.buttons[1], debuffs.buttons[2]
assert(debuffs.point[1] == "TOPRIGHT" and debuffs.point[3] == "BOTTOMRIGHT")
assert(d1.width == 30 and d1.height == 24, "cropped icons are 80% tall")
assert(debuffs.width == 30 and debuffs.height == 24*2+1, "one per row stacks the lane")
assert(d2.point[1] == "BOTTOMRIGHT" and d2.point[4] == 0 and d2.point[5] == 25)
assert(d1.dur.shown and d1.dur.text == "10" and not buffs.buttons[1].dur.shown)
assert(d1.border.bs.tex == "solid" and math.abs(d1.border.bs.b - 1) < 1e-9, "dispel ring defaults to a solid Magic tint")
s.auraBorderDispelTextured=true; UF.UF_ReloadAuraContainers(frame,"target")
assert(d1.border.bs.tex == "beveled")
s.auraBorderBehind=true; UF.UF_ReloadAuraContainers(frame,"target"); assert(d1.border.level == 0)
s.auraBorderBehind=nil; s.debuffDispelBorder=nil; s.auraBorderR=.5; UF.UF_ReloadAuraContainers(frame,"target")
assert(d1.border.bs.r == .5 and d1.border.bs.tex == "beveled")
-- Purgeable Buff Glow: an attackable unit, a Magic buff and a class that can remove it.
local glow = EllesmereUI.Glows
glow.StartSpecGlow = function(w, spec, wd, ht, host) w.spec, w.host = spec, host end
glow.ResolveColor = function(mode, r, g, b) if mode ~= "default" then return r, g, b end end
local ua, uc, uca = UnitAura, UnitClass, UnitCanAttack
UnitAura = function(u, i, f)
    if f == "HELPFUL" and i == 1 then return "Buff",nil,"buff-icon",1,"Magic",10,12,"other",nil,nil,100 end
    return ua(u, i, f)
end
UnitCanAttack = function() return true end
UnitClass = function() return "Mage","MAGE" end
s.buffPurgeGlow=3; s.buffPurgeGlowColor={r=0,g=1,b=0}; UF.UF_ReloadAuraContainers(frame,"target")
local bg = buffs.buttons[1].glow
assert(bg.shown and bg.spec.style == 3 and bg.spec.g == 1 and bg.host == "icon")
assert(UF.UF_PurgeGlowSpec(s).style == 3 and UF.UF_WrathCanPurge())
UnitClass = uc; UF.UF_ReloadAuraContainers(frame,"target"); assert(not bg.shown, "warriors cannot purge")
UnitClass = function() return "Mage","MAGE" end; UnitCanAttack = uca
UF.UF_ReloadAuraContainers(frame,"target"); assert(not bg.shown, "friendly buffs never glow")
UnitAura, UnitClass, s.buffPurgeGlow = ua, uc, nil
-- Player: weapon enchants lead the All buff run; right-click cancels out of combat.
local enchant = { 1, 60000, 3 }
GetWeaponEnchantInfo = function() return enchant[1], enchant[2], enchant[3], nil, nil, nil end
GetInventoryItemTexture = function(_, slot) return slot == 16 and "mh-icon" end
local cancelled = {}
CancelUnitBuff = function(u, i, f) cancelled[#cancelled+1] = u..i..f end
CancelItemTempEnchantment = function(w) cancelled[#cancelled+1] = "enchant"..w end
local pf = W.CreateFrame("Button"); pf._euiUnit="player"; pf:SetSize(200,40)
pf.Health = W.CreateFrame("StatusBar", nil, pf)
UF.UF_CreateAuraContainers(pf,"player")
local pb = UF.WrathAuraEntries[pf].buffs
local e1, b1 = pb.enchants[1], pb.buttons[1]
assert(e1.shown and e1.slot == 16 and e1.icon.texture == "mh-icon" and e1.count.text == 3)
assert(e1.point[4] == 0 and b1.point[4] == 22 and pb.width == 42, "main hand sits before the aura run")
b1:GetScript("OnClick")(b1, "RightButton"); e1:GetScript("OnClick")(e1, "RightButton")
assert(cancelled[1] == "player1HELPFUL" and cancelled[2] == "enchant1")
local combat = InCombatLockdown; InCombatLockdown = function() return true end
b1:GetScript("OnClick")(b1, "RightButton"); assert(#cancelled == 2, "cancel is blocked in combat")
InCombatLockdown = combat
s.buffFilterMode="own"; UF.UF_ReloadAuraContainers(pf,"player"); assert(not e1.shown)
s.buffFilterMode=nil; enchant[1] = nil; UF.UF_ReloadAuraContainers(pf,"player"); assert(not e1.shown and pb.width == 20)
-- Player dispel overlay: fill / sharp gradient / By Me (HARMFUL|RAID) / custom border.
local profile = { dispelOverlay="fill", dispelOverlayOpacity=50, player={} }
local getProfile = UF.UF_GetProfile
UF.UF_GetProfile = function() return profile end
UF.UF_ReloadAuraContainers(pf,"player")
local d = UF.WrathAuraEntries[pf].dispel
assert(d and d.type == "Magic" and d.tex.shown)
profile.dispelOverlay="gradient_sharp"; UF.UF_ReloadAuraContainers(pf,"player")
assert(d.tex.texture:find("gradient-sharp.tga", 1, true))
profile.dispelOverlayByMe=true; UF.UF_ReloadAuraContainers(pf,"player")
assert(not d.tex.shown and d.type == nil, "By Me reads HARMFUL|RAID only")
profile.dispelOverlayByMe=nil; profile.dispelOverlay="none"; UF.UF_ReloadAuraContainers(pf,"player")
assert(not d.tex.shown)
UF.UF_GetProfile = getProfile
GetWeaponEnchantInfo, GetInventoryItemTexture, CancelUnitBuff, CancelItemTempEnchantment = nil, nil, nil, nil
methods.SetPoint, methods.SetFrameLevel, EllesmereUI.ApplyBorderStyle = setPoint, setLevel, border
-- Power events carry the native event's power token, not the display type.
local pe, got = W.CreateFrame("Frame")
pe:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
pe:SetScript("OnEvent", function(_, _, _, token) got = token end)
pe:GetScript("OnEvent")(pe, "UNIT_RAGE", "player"); assert(got == "RAGE")
pe:GetScript("OnEvent")(pe, "UNIT_RUNIC_POWER", "player"); assert(got == "RUNIC_POWER")
-- Boss range, threat %, pet power/happiness and the diet list.
IsSpellInRange = function(name) if name == "Smite" then return 1 elseif name == "Far" then return 0 end end
assert(W.IsSpellInRange("Smite", "boss1") == true and W.IsSpellInRange("Far", "boss1") == false)
assert(W.IsSpellInRange("Unknown", "boss1") == nil and W.IsSpellInRange("Smite", nil) == nil)
assert(W.HealSpells.PRIEST and W.HarmRangeSpells.SHAMAN)
IsSpellInRange = nil
local fs = W.CreateFrame("Frame"):CreateFontString()
EllesmereUI.PaintThreatPct(fs, 87.4, 2, false, true); assert(fs.text == "87%")
assert(UF.UF_PetHasPower == true and type(UF.UF_ApplyPetHappiness) == "function")
GetPetFoodTypes = function() return "Meat", "Fish" end
local diet = C_PetInfo.GetPetFoodTypes(); assert(type(diet) == "table" and diet[2] == "Fish")
GetPetFoodTypes = nil
assert(type(UF.UFOpt_WrathFilterRow) == "function")
''')
# The druid form bar loads for druids only; exercise it as a Cat Form druid.
lua.execute('''
local methods = getmetatable(UIParent).__index
methods.SetWordWrap = methods.SetWordWrap or function() end
methods.SetReverseFill = methods.SetReverseFill or function() end
EllesmereUI.PP.UpdateBorder = EllesmereUI.PP.UpdateBorder or function() end
savedUnitClass, UnitClass = UnitClass, function() return "Druid","DRUID" end
savedPowerType, UnitPowerType = UnitPowerType, function() return formPT or 0, formToken or "MANA" end
''')
load('EUI_UnitFrames_335_FormBar.lua')
lua.execute('''
local draws = UF.UF_PowerBarDraws
formPT, formToken = 3, "ENERGY"
UF.UF_PowerBarDraws = function() return true end
local fp = W.CreateFrame("Frame"); local pw = W.CreateFrame("StatusBar", nil, fp)
pw:SetStatusBarTexture("Interface\\\\Buttons\\\\WHITE8X8")
local fs = { powerTypeOverride={ foreverDruid=0 }, foreverFormBar=true, powerPercentText="center", powerTextFormat="perpp" }
UF.UF_ForeverFormBar(fp, pw, fs)
local S = UF.UF_WrathFormBarState
assert(S.on and S.live and S.bar:IsShown() and S.token == "ENERGY" and S.bar.value == 50 and S.bar.text.text == "50%")
formPT, formToken = nil, nil; UF.UF_ForeverFormBar(fp, pw, fs)
assert(not S.bar:IsShown() and not S.live, "caster form hides the form bar")
fs.foreverFormBar = nil; UF.UF_ForeverFormBar(fp, pw, fs); assert(not S.on)
UF.UF_PowerBarDraws, UnitClass, UnitPowerType = draws, savedUnitClass, savedPowerType
savedUnitClass, savedPowerType = nil, nil
''')
# Every UF unlock mover must have a settings-map entry on a real Wrath page.
import re
uf_src = (root/'EllesmereUIUnitFrames/EllesmereUIUnitFrames.lua').read_text(encoding='utf-8-sig')
unlock_src = (root/'EllesmereUI/EUI_UnlockMode.lua').read_text(encoding='utf-8-sig')
mover_keys = set(re.findall(r'(?:AddUFElement|MakeUFElement|MakeCastBarElement)\("(\w+)"', uf_src))
assert {'player', 'target', 'focus', 'pet', 'targettarget', 'focustarget', 'boss', 'classPower',
        'playerCastbar', 'targetCastbar', 'focusCastbar'} <= mover_keys, mover_keys
pages = {'Main Frames', 'Boss Frames', 'Mini Frames', 'Buffs', 'Debuffs', 'Aura Filters'}
for key in mover_keys:
    m = re.search(r'\["' + key + r'"\]\s*=\s*\{([^\n]*)\}', unlock_src)
    assert m, 'no _ELEMENT_SETTINGS_MAP entry for ' + key
    entry = m.group(1)
    assert 'module = "EllesmereUIUnitFrames"' in entry, key
    page = re.search(r'page\s*=\s*"([^"]+)"', entry)
    assert page and page.group(1) in pages, key
    assert 'sectionName' in entry and 'highlightText' in entry, key
native_lua = LuaRuntime()
native_lua.execute((root/'backport-tools/wrath_mock.lua').read_text())
native_lua.execute('issecretvalue=function(v) return v == "native-secret" end')
native_ns = native_lua.table()
native_lua.execute((root/'EllesmereUIUnitFrames/EUI_UnitFrames_335.lua').read_text(), 'EllesmereUIUnitFrames', native_ns)
assert native_ns.Wrath.IsSecretValue('native-secret') is True
assert native_ns.Wrath.IsSecretValue(42) is False
legacy_lua = LuaRuntime()
legacy_lua.execute((root/'backport-tools/wrath_mock.lua').read_text())
legacy_lua.execute('local t=CreateFrame("Frame"):CreateTexture(); getmetatable(t).__index.SetAtlas=nil')
legacy_ns = legacy_lua.table()
legacy_lua.execute((root/'EllesmereUIUnitFrames/EUI_UnitFrames_335.lua').read_text(), 'EllesmereUIUnitFrames', legacy_ns)
legacy_lua.globals().W = legacy_ns.Wrath
legacy_lua.execute('''
local t=W.CreateFrame("Frame"):CreateTexture()
t:SetAtlas("nameplates-icon-elite-gold")
assert(t.texture == "Interface\\\\AddOns\\\\EllesmereUIUnitFrames\\\\Media\\\\elite-badge-335.tga")
assert(nativeAtlasCalls == 0)
''')
# Clients/addons whose CreateMaskTexture returns nil (absorb bar crashed on a player's
# machine: "attempt to index local 'absorbMask'"): placeholder mask, native Add never sees it.
nilmask_lua = LuaRuntime()
nilmask_lua.execute((root/'backport-tools/wrath_mock.lua').read_text())
nilmask_lua.execute('''
local fm=getmetatable(CreateFrame("Frame")).__index
fm.CreateMaskTexture=function() return nil end
local tm=getmetatable(CreateFrame("Frame"):CreateTexture()).__index
nativeMaskAdds=0
tm.AddMaskTexture=function(_, m) assert(m and m.realMask, "native AddMaskTexture got a fake mask"); nativeMaskAdds=nativeMaskAdds+1 end
tm.RemoveMaskTexture=tm.AddMaskTexture
''')
nilmask_ns = nilmask_lua.table()
nilmask_lua.execute((root/'EllesmereUIUnitFrames/EUI_UnitFrames_335.lua').read_text(), 'EllesmereUIUnitFrames', nilmask_ns)
nilmask_lua.globals().W = nilmask_ns.Wrath
nilmask_lua.execute('''
local bar=W.CreateFrame("StatusBar")
local mask=bar:CreateMaskTexture()
assert(mask and mask._eui335FakeMask and not mask:IsShown(), "nil native mask needs a hidden placeholder")
mask:SetAllPoints(bar); mask:SetTexture("Interface\\\\Buttons\\\\WHITE8X8")
local tex=bar:CreateTexture(); tex:AddMaskTexture(mask); tex:RemoveMaskTexture(mask)
assert(nativeMaskAdds==0)
local fm=getmetatable(CreateFrame("Frame")).__index
fm.CreateMaskTexture=function(self) local t=self:CreateTexture(); t.realMask=true; return t end
local real=W.CreateFrame("StatusBar"):CreateMaskTexture()
assert(real.realMask and not real._eui335FakeMask)
local tex2=W.CreateFrame("Frame"):CreateTexture(); tex2:AddMaskTexture(real)
assert(nativeMaskAdds==1, "real masks still reach the native method")
''')
# Visual parity: Retail media Wrath cannot load (PNG, non-power-of-two TGA,
# file IDs, missing atlases, masks) resolves to art that does load.
lua.execute('''
local t = W.CreateFrame("Frame"):CreateTexture()
local COMBAT = "Interface\\\\AddOns\\\\EllesmereUI\\\\media\\\\combat\\\\"
local ART = "Interface\\\\AddOns\\\\EllesmereUIUnitFrames\\\\Media\\\\Art_335\\\\combat\\\\"
for i = 0, 5 do
    t:SetTexture(COMBAT .. "combat" .. i .. ".tga")
    assert(t.texture == ART .. "combat" .. i .. ".tga" and canLoadTexture(t.texture), t.texture)
end
for _, name in ipairs({"combat-indicator-custom", "combat-indicator-class-custom"}) do
    t:SetTexture(COMBAT .. name .. ".png")
    assert(t.texture == ART .. name .. ".tga" and canLoadTexture(t.texture), t.texture)
end
t:SetTexture(136197); assert(t.texture == "Interface\\\\Icons\\\\Spell_Shadow_ShadowBolt")
t:SetTexture(136243); assert(t.texture == "Interface\\\\Icons\\\\Trade_Engineering")
t:SetTexture(4622462); assert(t.texture == "Interface\\\\Icons\\\\INV_Misc_QuestionMark")
t:SetTexture(0); assert(t.texture == 0)
t:SetTexture(1); assert(t.texture == 1)
t:SetTexture(nil); assert(t.texture == nil)
-- Faction badge: Retail atlas styles fall back to the Wrath PvP icon.
EllesmereUI.FACTION_ART = {
    pvp = { atlas = "UI-HUD-UnitFrame-Player-PVP-%sIcon" },
    honor = { atlas = "honorsystem-portrait-%s", lower = true },
    classic = { file = "Interface\\\\TargetingFrame\\\\UI-PVP-%s", coords = { 0, 0.65625, 0, 0.65625 } },
}
local fallback = EllesmereUI.SetFactionArt
local delegated
EllesmereUI.SetFactionArt = function(_, style) delegated = style end
for _, style in ipairs({"pvp", "honor", "missing"}) do
    t.texture = nil
    W.SetFactionArt(t, style, "Horde")
    assert(t.texture == "Interface\\\\TargetingFrame\\\\UI-PVP-Horde" and t.texcoords[2] == 0.65625, style)
end
assert(delegated == nil)
W.SetFactionArt(t, "classic", "Alliance"); assert(delegated == "classic")
atlasInfoMock["honorsystem-portrait-horde"] = {width=32, height=32}
delegated = nil; W.SetFactionArt(t, "honor", "Horde"); assert(delegated == "honor")
atlasInfoMock["honorsystem-portrait-horde"] = nil
EllesmereUI.SetFactionArt, EllesmereUI.FACTION_ART = fallback, nil
assert(W.UnitIsMercenary("player") == false)
-- Detached shapes without masks: the art fits the shape opening.
local methods = getmetatable(UIParent).__index
local setPoint, clear = methods.SetPoint, methods.ClearAllPoints
methods.SetPoint = function(self, p, _, _, x, y) self.pts = self.pts or {}; self.pts[p] = {x, y} end
methods.ClearAllPoints = function(self) self.pts = {} end
local host = W.CreateFrame("Frame"); host.width, host.height = 128, 128
local tex2d, texClass = host:CreateTexture(), host:CreateTexture()
W.FitUnmaskedPortrait(host, "circle", 17, tex2d, texClass)
assert(tex2d.pts.TOPLEFT[1] == 17 and tex2d.pts.TOPLEFT[2] == -17 and tex2d.pts.BOTTOMRIGHT[1] == -17)
assert(math.abs(texClass.pts.TOPLEFT[1] - (17 + 128 * 0.08)) < 1e-6)
assert(tex2d.texcoords[1] == 0 and tex2d.texcoords[2] == 1 and tex2d._wrathRound)
W.FitUnmaskedPortrait(host, "diamond", 20, tex2d)
assert(math.abs(tex2d.texcoords[1] - .15) < 1e-6 and not tex2d._wrathRound)
tex2d.texcoords = nil
W.FitUnmaskedPortrait(host, nil, nil, tex2d); assert(tex2d.texcoords == nil, "reset only after a round fit")
tex2d._mirrored = true
W.FitUnmaskedPortrait(host, "portrait", 17, tex2d)
assert(tex2d.texcoords[1] == 1 and tex2d.texcoords[2] == 0)
W.FitUnmaskedPortrait(host, nil, nil, tex2d)
assert(math.abs(tex2d.texcoords[1] - .85) < 1e-6 and math.abs(tex2d.texcoords[2] - .15) < 1e-6 and not tex2d._wrathRound)
methods.SetPoint, methods.ClearAllPoints = setPoint, clear
-- Options preview aura icons come from Wrath spells.
local getInfo = GetSpellInfo
GetSpellInfo = function(id) if id ~= 34914 then return "S" .. id, "", "Interface\\\\Icons\\\\S" .. id end end
local icons = W.SpellIcons(W.PreviewDebuffSpells)
assert(#icons == 20 and icons[1] == "Interface\\\\Icons\\\\S589" and icons[20] == "Interface\\\\Icons\\\\INV_Misc_QuestionMark")
for class, ids in pairs(W.PreviewBuffSpells) do assert(#ids == 5, class) end
assert(W.PreviewCastSpells[1].spellID == 8690)
GetSpellInfo = getInfo
''')
# The core C_Spell.GetSpellInfo shim reads the 3.3.5 return order (cost and
# power type sit before the cast time).
compat_lua = LuaRuntime()
compat_lua.execute('GetSpellInfo=function() return "Hearthstone","","hs-icon",0,false,0,10000,0,5 end; GetSpellLink=function() return "|Hspell:8690|h[Hearthstone]|h" end')
compat_src = (root/'EllesmereUI/EllesmereUI_3.3.5_Compat.lua').read_text(encoding='utf-8-sig')
shim = 'C_Spell={}\nC_Spell.GetSpellInfo=C_Spell.GetSpellInfo or function(id)' + compat_src.split('C_Spell.GetSpellInfo=C_Spell.GetSpellInfo or function(id)', 1)[1].split('\nend\n', 1)[0] + '\nend\n'
compat_lua.execute(shim)
info = compat_lua.eval('C_Spell.GetSpellInfo("Hearthstone")')
assert info.castTime == 10000 and info.iconID == 'hs-icon' and info.maxRange == 5 and info.spellID == 8690
assert compat_lua.eval('C_Spell.GetSpellInfo(8690)').spellID == 8690
# Live detached portrait and the options preview use the same unmasked fit.
opts_src = (root/'EllesmereUIOptions/EUI_UnitFrames_Options.lua').read_text(encoding='utf-8-sig')
live_fn = uf_src.split('function ApplyDetachedPortraitShape(', 1)[1].split('\nend\n', 1)[0]
pv_fn = opts_src.split('local function ApplyPreviewPortraitShape(', 1)[1].split('\n    end\n\n', 1)[0]
assert live_fn.count('FitUnmaskedPortrait(') == 3, live_fn.count('FitUnmaskedPortrait(')
assert pv_fn.count('FitUnmaskedPortrait(') == 3, pv_fn.count('FitUnmaskedPortrait(')
assert 'FitUnmaskedPortrait(backdrop, shape, insetPx, backdrop._2d, backdrop._class)' in live_fn
assert 'ns.Wrath.SetFactionArt(tex, style, fac)' in uf_src and 'UnitIsMercenary("player")' not in uf_src.replace('ns.Wrath.UnitIsMercenary("player")', '')
assert 'ns.Wrath.SetFactionArt or EllesmereUI.SetFactionArt' in opts_src
assert 'ns.Wrath.SpellIcons(ns.Wrath.PreviewDebuffSpells)' in opts_src and 'FALLBACK_CAST_SPELLS = ns.Wrath.PreviewCastSpells' in opts_src
toc = (root/'EllesmereUIUnitFrames/EllesmereUIUnitFrames.toc').read_text(encoding='utf-8-sig')
assert toc.index('EUI_UnitFrames_335_Textures.lua') < toc.index('EUI_UnitFrames_335_Media.lua') < toc.index('EllesmereUIUnitFrames.lua')
assert toc.index('EUI_UnitFrames_335_Auras.lua') < toc.index('EUI_UnitFrames_335_Absorbs.lua')
# Wrath ABSORBS section (player/target/focus) and the shared preview painter.
wrath_absorbs = opts_src.split('elseif EUI_WOW_335 and EllesmereUI.Absorbs', 1)[1].split('end -- _supportsAbsorbs', 1)[0]
for row in ('"ABSORBS"', 'text="Absorb Style"', 'text="Absorb Opacity"', 'text="Absorb Color"', 'text="Placement"',
            'text="Show Overshield"', 'text="Show on Boss Frames"', 'absorbRow, h = W:DualRow'):
    assert row in wrath_absorbs, row
assert 'ns.UF_WrathAbsorbPreview(health, (not _healWillShow) and s or nil, fw, hh' in opts_src
# Default fonts and every redirected/declared UF media file load on 3.3.5.
fonts_src = (root/'EllesmereUI/EllesmereUI_Fonts.lua').read_text(encoding='utf-8-sig')
for font in re.findall(r'=\s*"([^"]+\.(?:ttf|TTF|otf))"', fonts_src.split('EllesmereUI.FONT_FILES = {', 1)[1].split('\n}', 1)[0]):
    assert (root/'EllesmereUI/media/fonts'/font).is_file(), font
import subprocess
audit = subprocess.run([sys.executable, str(root/'backport-tools/audit_unitframe_media.py')], capture_output=True, text=True)
assert audit.returncode == 0, audit.stdout + audit.stderr
lua.execute('assert(rotationCalls == 0, "native rotation reached during validation")')
print(f'PASS: {count} Lua 5.1 files; Blizzard level font-before-text without Retail FontObject/name, custom size, name inheritance, rejected font fallback, level events/skulls/visibility; real bar catalogue/Fade initialization, all texture swaps and missing-file fallback; missing/existing atlases and icon fallbacks, native rotation avoided on Wrath, absent/native secret predicates, event mappings/filtering, EditBox lifecycle, cast/channel start-stop, timers, curves, frame initialization/reload, options registration, aura filtering; aura layout/crop/duration/stack/border/dispel ring/behind levels, weapon enchants, combat-safe cancel, purge glow, dispel overlay modes, power event tokens, boss range, threat %, pet power/diet, druid form bar, unlock settings map; visual parity: combat media redirects, file-ID icons, faction fallback, unmasked portrait fit (live = preview), preview spell icons, GetSpellInfo order, fonts, media audit.')
