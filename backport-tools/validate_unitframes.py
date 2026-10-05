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
lua.execute('assert(rotationCalls == 0, "native rotation reached during validation")')
print(f'PASS: {count} Lua 5.1 files; Blizzard level font-before-text without Retail FontObject/name, custom size, name inheritance, rejected font fallback, level events/skulls/visibility; real bar catalogue/Fade initialization, all texture swaps and missing-file fallback; missing/existing atlases and icon fallbacks, native rotation avoided on Wrath, absent/native secret predicates, event mappings/filtering, EditBox lifecycle, cast/channel start-stop, timers, curves, frame initialization/reload, options registration, aura filtering.')
