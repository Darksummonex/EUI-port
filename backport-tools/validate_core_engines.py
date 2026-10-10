"""Core 0.33 Wrath engines: LibDeflate, Kick, Mana Regen Spark, Spell Cost
Prediction, Video Guides and Party Mode (engine + options page).

The widget mock is strict: Retail-only methods (SetRotation, SetShown,
SetVertexOffset, SetClipsChildren, RegisterUnitEvent, SetTimerDuration,
masks) are absent, so any call to them fails the run.
"""
from pathlib import Path
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

core = root / 'EllesmereUI'
opts = root / 'EllesmereUIOptions'
NEW = ['EllesmereUI_Kick_335.lua', 'EllesmereUI_ManaRegenSpark_335.lua',
       'EllesmereUI_SpellCostPrediction_335.lua', 'EllesmereUI_VideoGuides_335.lua',
       'EllesmereUI_PartyMode_335.lua', 'EllesmereUI_Absorbs_335.lua']

toc = (core / 'EllesmereUI.toc').read_text(encoding='utf-8-sig').splitlines()
toc = [l.strip() for l in toc if l.strip() and not l.startswith('#')]
for name in NEW + ['Libs\\LibDeflate\\LibDeflate.lua']:
    assert name in toc, name
assert toc.index('Libs\\LibDeflate\\LibDeflate.lua') < toc.index('EllesmereUI_Profiles.lua')
# 3.3.5 EditBoxes have no GetNumLines; the import/export popup must measure instead.
profiles_src = (core / 'EllesmereUI_Profiles.lua').read_text(encoding='utf-8-sig')
assert profiles_src.count(':GetNumLines()') == profiles_src.count('if editBox.GetNumLines then'), 'unguarded EditBox:GetNumLines'
assert 'm:GetStringHeight()' in profiles_src
# Some 3.3.5 clients/addons expose a CreateMaskTexture that returns nil.
import re
panel_src = (core / 'EllesmereUI_Panel.lua').read_text(encoding='utf-8-sig')
for name in re.findall(r'local (\w+) = \w+:CreateMaskTexture\(\)', panel_src):
    assert re.search(r'local %s = \w+:CreateMaskTexture\(\)\s*\n(\s*--[^\n]*\n)?\s*if %s then' % (name, name), panel_src), 'unguarded mask ' + name
assert toc.index('Libs\\LibStub\\LibStub.lua') < toc.index('Libs\\LibDeflate\\LibDeflate.lua')
assert toc.index('EllesmereUI_Panel.lua') < toc.index('EllesmereUI_PartyMode_335.lua')
assert toc.index('EllesmereUI_Ticker.lua') < toc.index('EllesmereUI_PartyMode_335.lua')
for retail_only in ('EllesmereUI_Kick.lua', 'EllesmereUI_PartyMode.lua', 'EllesmereUI_VideoGuides.lua',
                    'EllesmereUI_ManaRegenSpark.lua', 'EllesmereUI_SpellCostPrediction.lua'):
    assert retail_only not in toc, retail_only
otoc = (opts / 'EllesmereUIOptions.toc').read_text(encoding='utf-8-sig').splitlines()
assert 'EUI_PartyMode_335_Options.lua' in [l.strip() for l in otoc]
assert '#EUI_PartyMode_Options.lua' in [l.strip() for l in otoc]
for p in ['backgrounds_335/party_beam.tga', 'icons_335/play.tga', 'cast_spark.tga']:
    assert (core / 'media' / p).exists(), p

for name in NEW:
    src = (core / name).read_text(encoding='utf-8')
    for bad in ('SetRotation(', ':SetShown(', 'SetVertexOffset(', 'SetClipsChildren',
                'RegisterUnitEvent', 'SetTimerDuration', 'SetRotatesTexture', '.png"',
                'C_DurationUtil', 'C_CurveUtil', 'EUI_CLIENT_BLOCKED'):
        assert bad not in src, (name, bad)
psrc = (opts / 'EUI_PartyMode_335_Options.lua').read_text(encoding='utf-8')
assert psrc.startswith('local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame\n')
for need in ('Heroic Boss Kill', 'Normal Boss Kill', 'Battleground Win', 'Rated Arena Win',
             'Bloodlust / Heroism', 'Level Up', 'PartySpinHasTarget', 'VoiceChat-Speaker'):
    assert need in psrc, need
for gone in ('Timed Keystone', 'Mythic Boss Kill', 'Raid Finder Boss Kill', 'Mythic 0 Completion',
             'iconAtlas', 'EUI_CLIENT_BLOCKED'):
    assert gone not in psrc, gone

lua = LuaRuntime()
compile_ok = lua.eval('function(src, name) local f, err = loadstring(src, name); return f ~= nil, err end')
for path in [core / n for n in NEW] + [opts / 'EUI_PartyMode_335_Options.lua']:
    ok, err = compile_ok(path.read_text(encoding='utf-8'), path.name)
    assert ok, err

lua.execute(r'''
now = 100
function GetTime() return now end
local registry = {}
frames = {}
local function noop() end

local Region = {}
Region.__index = Region
function Region:SetPoint(...) self.points[#self.points + 1] = { ... } end
function Region:ClearAllPoints() self.points = {} end
function Region:SetAllPoints(p) self.points = { { "ALL", p } } end
function Region:SetWidth(v) self.width = v end
function Region:SetHeight(v) self.height = v end
function Region:SetSize(w, h) self.width, self.height = w, h end
function Region:GetWidth() return self.width or 0 end
function Region:GetHeight() return self.height or 0 end
function Region:Show() self.shown = true; local f = self.scripts and self.scripts.OnShow; if f then f(self) end end
function Region:Hide()
    local was = self.shown
    self.shown = false
    if was and self.scripts and self.scripts.OnHide then self.scripts.OnHide(self) end
    for _, h in ipairs(self.hideHooks or {}) do h(self) end
end
function Region:IsShown() return self.shown end
function Region:IsVisible() return self.shown and (not self.parent or self.parent.IsVisible == nil or self.parent:IsVisible()) end
function Region:SetAlpha(a) self.alpha = a end
function Region:GetParent() return self.parent end
function Region:SetTexture(t) self.texture = t end
function Region:GetTexture() return self.texture end
function Region:SetTexCoord(...) self.texcoords = { ... } end
function Region:SetVertexColor(r, g, b, a) self.color = { r, g, b, a } end
function Region:SetColorTexture(r, g, b, a) self.color = { r, g, b, a }; self.texture = "color" end
function Region:SetBlendMode(m) self.blend = m end
function Region:SetDrawLayer() end
function Region:SetFont(...) self.font = { ... } end
function Region:SetText(t) self.text = t end
function Region:GetText() return self.text end
function Region:SetTextColor() end
function Region:SetJustifyH() end
function Region:GetStringWidth() return 50 end

local Frame = setmetatable({}, { __index = Region })
Frame.__index = Frame
function Frame:RegisterEvent(e) self.events[e] = true end
function Frame:UnregisterEvent(e) self.events[e] = nil end
function Frame:UnregisterAllEvents() self.events = {} end
function Frame:SetScript(s, f) self.scripts[s] = f end
function Frame:GetScript(s) return self.scripts[s] end
function Frame:HookScript(s, f)
    if s == "OnHide" then self.hideHooks = self.hideHooks or {}; table.insert(self.hideHooks, f); return end
    local old = self.scripts[s]
    self.scripts[s] = function(...) if old then old(...) end; f(...) end
end
function Frame:SetFrameLevel(v) self.level = v end
function Frame:GetFrameLevel() return self.level or 1 end
function Frame:SetFrameStrata(v) self.strata = v end
function Frame:EnableMouse() end
function Frame:EnableMouseWheel() end
function Frame:EnableKeyboard() end
function Frame:SetScale(s) self.scale = s end
function Frame:GetScale() return self.scale or 1 end
function Frame:GetEffectiveScale() return 1 end
function Frame:RegisterForClicks() end
function Frame:CreateTexture()
    local t = setmetatable({ points = {}, kind = "Texture", parent = self }, Region)
    self.textures = self.textures or {}
    self.textures[#self.textures + 1] = t
    return t
end
function Frame:CreateFontString() local t = setmetatable({ points = {}, kind = "FontString", parent = self }, Region); return t end
function Frame:SetMinMaxValues(a, b) self.minv, self.maxv = a, b end
function Frame:GetMinMaxValues() return self.minv, self.maxv end
function Frame:SetValue(v) self.value = v end
function Frame:GetValue() return self.value end
function Frame:GetOrientation() return self.orientation or "HORIZONTAL" end
function Frame:GetStatusBarTexture() self.fill = self.fill or self:CreateTexture(); return self.fill end
function Frame:GetChildren() return end
function Frame:GetRegions() return end
function Frame:SetMultiLine() end
function Frame:SetAutoFocus(v) self.autoFocus = v end
function Frame:SetTextInsets() end
function Frame:SetCursorPosition() end
function Frame:SetFocus() self.focus = true end
function Frame:ClearFocus() self.focus = false end
function Frame:HighlightText() end

function CreateFrame(kind, name, parent, template)
    local f = setmetatable({ kind = kind, name = name, parent = parent, points = {}, events = {}, scripts = {}, shown = true }, Frame)
    if name then _G[name] = f end
    frames[#frames + 1] = f
    return f
end
UIParent = CreateFrame("Frame", "UIParent")
function Fire(frame, event, ...) local f = frame.scripts.OnEvent; if f and frame.events[event] then f(frame, event, ...) end end
function FireAll(event, ...) for _, f in ipairs(frames) do Fire(f, event, ...) end end
function Tick(dt)
    now = now + dt
    for _, f in ipairs(frames) do
        local u = f.scripts.OnUpdate
        if u and f.shown then u(f, dt) end
    end
end

timers = {}
C_Timer = {
    After = function(_, fn) fn() end,
    NewTimer = function(d, fn) local t = { d = d, fn = fn }; function t:Cancel() self.cancelled = true end; timers[#timers + 1] = t; return t end,
    NewTicker = function() return { Cancel = noop } end,
}
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
function hooksecurefunc(a, b, c)
    if type(a) == "string" then local old = _G[a]; _G[a] = function(...) local r = old(...); b(...); return r end
    else local old = a[b]; a[b] = function(...) local r = old(...); c(...); return r end end
end
function InCombatLockdown() return false end
function UnitGUID(u) return u == "player" and "Player-1" or nil end
playerClass = "MAGE"
function UnitClass() return playerClass, playerClass end
cvars = { gamma = "1.0" }
function GetCVar(n) return cvars[n] end
function SetCVar(n, v) cvars[n] = tostring(v) end
function PlaySoundFile(p) lastSound = p end
function SetOverrideBindingClick() end
function UnitFactionGroup() return "Alliance" end
function UnitIsDead() return false end
function UnitIsDeadOrGhost() return false end
function UnitExists() return false end
strmatch = string.match
SlashCmdList = {}
function IsShiftKeyDown() return false end
function IsControlKeyDown() return false end
function GetScreenWidth() return 1366 end
function GetScreenHeight() return 768 end

EllesmereUI = { PanelPP = {}, PP = {} }
local PP = EllesmereUI.PanelPP
function PP.Size(f, w, h) f:SetWidth(w); f:SetHeight(h) end
function PP.Point(f, ...) f:SetPoint(...) end
EllesmereUI.PP.DisablePixelSnap = noop
function EllesmereUI.MakeBorder() return { SetColor = noop } end
function EllesmereUI.BuildPopupShell(name)
    local d = CreateFrame("Frame", name .. "Dimmer", UIParent); d.shown = false
    local p = CreateFrame("Frame", name .. "Popup", d)
    return d, p
end
function EllesmereUI.GetPopupScale() return 1 end
function EllesmereUI.PopupBump(m) return m or 1 end
function EllesmereUI.HideWidgetTooltip() end
function EllesmereUI.ShowWidgetTooltip() end
function EllesmereUI.RegAccent() end
function EllesmereUI.L(s) return s end
function EllesmereUI:RefreshPage() end
onShow, onHide = {}, {}
function EllesmereUI:RegisterOnShow(f) onShow[#onShow + 1] = f end
function EllesmereUI:RegisterOnHide(f) onHide[#onHide + 1] = f end
EllesmereUI.CombatQueue = { Defer = noop }
function EllesmereUI.BuildAlertSoundTables() return { airhorn = "Interface\\AddOns\\EllesmereUI\\media\\sounds\\AirHorn.ogg" }, { none = "None", airhorn = "Air Horn" }, { "none", "airhorn" } end
function EllesmereUI.AppendSharedMediaSounds() end
visEdges = 0
function EllesmereUI.FireVisEdge() visEdges = visEdges + 1 end
''')

def load(name, *varargs):
    src = (core / name).read_text(encoding='utf-8')
    fn = lua.eval('function(src, name, ...) local f = assert(loadstring(src, name)); return f(...) end')
    return fn(src, name, *varargs)

# LibDeflate: profile export / import round trip.
for lib in ['Libs/LibStub/LibStub.lua', 'Libs/LibDeflate/LibDeflate.lua']:
    load(lib)
assert lua.eval('''(function()
    local LD = LibStub("LibDeflate")
    local s = string.rep("EllesmereUI profile {a=1,b='two'} ", 40)
    local enc = LD:EncodeForPrint(LD:CompressDeflate(s))
    assert(#enc < #s)
    return LD:DecompressDeflate(LD:DecodeForPrint(enc)) == s
end)()''')

# Kick: spellbook resolution, pet book precedence, stance choice, GCD.
lua.execute(r'''
spellNames = { [2139] = "Counterspell", [19647] = "Spell Lock", [6552] = "Pummel", [72] = "Shield Bash" }
book = { spell = {}, pet = {} }
cooldowns = {}
usable = {}
function GetSpellInfo(id) return spellNames[id] end
function GetNumSpellTabs() return 1 end
function GetSpellTabInfo() return "General", "", 0, #book.spell end
function HasPetSpells() return #book.pet > 0 and #book.pet or nil end
function GetSpellName(i, bt) return book[bt][i] end
function GetSpellLink(i, bt)
    local n = book[bt][i]
    for id, nm in pairs(spellNames) do if nm == n then return "|Hspell:" .. (id + 1000) .. "|h[" .. n .. "]|h" end end
end
function GetSpellCooldown(i, bt) local c = cooldowns[bt .. i] or { 0, 0, 1 }; return c[1], c[2], c[3] end
function IsUsableSpell(n) return usable[n] or false, false end
''')
load('EllesmereUI_Kick_335.lua')
assert lua.eval('''(function()
    local E, ready, base = EllesmereUI, { r = 1, g = 0, b = 0 }, { r = 0, g = 0, b = 1 }
    playerClass = "MAGE"; book.spell = { "Fireball", "Counterspell", "Frostbolt" }
    E.RefreshKickAbility()
    assert(E.GetActiveKickSpell() == 3139, "link id")
    assert(select(3, E.ComputeCastBarTint(ready, base)) == 1, "off cd = base")
    cooldowns.spell2 = { 50, 24, 1 }
    assert(E.ComputeCastBarTint(ready, base) == 1, "on cd = interrupt-on-cd tint")
    cooldowns.spell2 = { 50, 1.5, 1 }
    assert(select(3, E.ComputeCastBarTint(ready, base)) == 1, "gcd = base")
    playerClass = "WARLOCK"; book.spell = { "Shadow Bolt" }; book.pet = { "Devour Magic", "Spell Lock" }
    E.RefreshKickAbility()
    assert(E.GetActiveKickSpell() == 20647, "pet spell lock")
    cooldowns.pet2 = { 50, 24, 1 }
    assert(E.ComputeCastBarTint(ready, base) == 1, "pet cooldown read from pet book")
    playerClass = "WARRIOR"; book.pet = {}; book.spell = { "Pummel", "Shield Bash" }
    E.RefreshKickAbility()
    usable["Shield Bash"] = true
    cooldowns.spell1 = { 50, 10, 1 }
    assert(select(3, E.ComputeCastBarTint(ready, base)) == 1, "usable shield bash wins")
    assert(E.GetActiveKickSpell() == 1072)
    playerClass = "PALADIN"; E.RefreshKickAbility()
    assert(E.GetActiveKickSpell() == nil and select(3, E.ComputeCastBarTint(ready, base)) == 1)
    return true
end)()''')

# Mana Regen Spark.
lua.execute(r'''
spellCosts = { ["Flash Heal(Rank 9)"] = { 380, 0 }, ["Maul"] = { 15, 1 } }
function GetSpellInfo(n)
    local c = spellCosts[n]
    if c then return n, nil, "icon", c[1], false, c[2] end
    if type(n) == "number" then return spellNames[n] end
end
playerClass = "PRIEST"
''')
load('EllesmereUI_ManaRegenSpark_335.lua')
assert lua.eval('''(function()
    local MRS = EllesmereUI.ManaRegenSpark
    local bar = CreateFrame("StatusBar", nil, UIParent); bar:SetWidth(200); bar:SetHeight(10)
    MRS.SetMana("uf", true)
    MRS.Attach("uf", bar, false)
    local h
    for _, f in ipairs(frames) do if f.parent == bar then h = f end end
    local ev
    for _, f in ipairs(frames) do if f.events.UNIT_SPELLCAST_SUCCEEDED then ev = f end end
    assert(ev and not ev.events.UNIT_MANA, "listening, no ticks")
    Fire(ev, "UNIT_SPELLCAST_SUCCEEDED", "target", "Flash Heal", "Rank 9")
    assert(not h.shown, "other units ignored")
    Fire(ev, "UNIT_SPELLCAST_SUCCEEDED", "player", "Maul", "")
    assert(not h.shown, "rage spell ignored")
    Fire(ev, "UNIT_SPELLCAST_SUCCEEDED", "player", "Flash Heal", "Rank 9")
    assert(h.shown and ev.scripts.OnUpdate, "5s sweep")
    Tick(2.5)
    local spark = h.textures[1]
    local p = spark.points[1]
    assert(spark.texture:find("cast_spark") and spark.blend == "ADD")
    assert(p[1] == "CENTER" and p[2] == bar and p[3] == "LEFT" and math.abs(p[4] - 100) < 1e-6, "half way")
    assert(spark.width == 8 and spark.height == 10)
    bar.GetReverseFill = function() return true end
    MRS.Attach("uf", bar, false)
    Tick(0.5)
    p = spark.points[1]
    assert(p[3] == "RIGHT" and math.abs(p[4] + 120) < 1e-6, "reverse fill runs from the right")
    bar.GetReverseFill = nil
    MRS.Attach("uf", bar, false)
    return true
end)()''')
assert lua.eval('''(function()
    local MRS = EllesmereUI.ManaRegenSpark
    local ev, holder, bar
    for _, f in ipairs(frames) do if f.events.UNIT_SPELLCAST_SUCCEEDED then ev = f end end
    for _, f in ipairs(frames) do if f.kind == "StatusBar" then bar = f end end
    for _, f in ipairs(frames) do if f.parent == bar then holder = f end end
    Tick(2.1)
    assert(not holder.shown and ev.scripts.OnUpdate == nil, "window over, idle")
    MRS.Attach("uf", bar, true)
    assert(ev.events.UNIT_MANA, "ticks listen to UNIT_MANA")
    Fire(ev, "UNIT_SPELLCAST_SUCCEEDED", "player", "Flash Heal", "Rank 9")
    Tick(5.1)
    assert(holder.shown, "tick sweep follows the window")
    Fire(ev, "UNIT_MANA", "player")
    Tick(2.0)
    assert(holder.shown, "regen seen: next tick")
    Tick(2.1)
    assert(not holder.shown, "no regen: idle")
    MRS.SetMana("uf", false)
    Fire(ev, "UNIT_SPELLCAST_SUCCEEDED", "player", "Flash Heal", "Rank 9")
    assert(not holder.shown, "bar not showing mana")
    MRS.SetMana("uf", true)
    assert(holder.shown, "joins running sweep on the edge to mana")
    MRS.Detach("uf")
    assert(not holder.shown and next(ev.events) == nil, "detach drops events")
    return true
end)()''')
assert lua.eval('''(function()
    -- a vertical host: the spark lies across the bar, rising from the bottom
    local MRS = EllesmereUI.ManaRegenSpark
    local bar = CreateFrame("StatusBar", nil, UIParent); bar:SetWidth(12); bar:SetHeight(100)
    bar.orientation = "VERTICAL"
    local before = #frames
    MRS.SetMana("erb", true); MRS.Attach("erb", bar, false)
    local holder = frames[before + 1]
    local ev
    for _, f in ipairs(frames) do if f.events.UNIT_SPELLCAST_SUCCEEDED then ev = f end end
    Fire(ev, "UNIT_SPELLCAST_SUCCEEDED", "player", "Flash Heal", "Rank 9")
    Tick(1.0)
    local spark = holder.textures[1]
    local p = spark.points[1]
    assert(holder.shown and p[3] == "BOTTOM" and math.abs(p[5] - 20) < 1e-6, "vertical")
    assert(spark.width == 12 and spark.height == 8 and #spark.texcoords == 8, "transposed spark")
    MRS.Detach("erb")
    return true
end)()''')

# Spell Cost Prediction.
lua.execute(r'''
spellCosts["Greater Heal(Rank 7)"] = { 300, 0 }
castInfo = nil
function UnitCastingInfo(u) if castInfo then return castInfo.name, castInfo.rank, nil, nil, 0, 0, false, castInfo.id, false end end
''')
load('EllesmereUI_SpellCostPrediction_335.lua')
assert lua.eval('''(function()
    local SCP = EllesmereUI.SpellCostPrediction
    assert(select(3, SCP.Color({ powerCostColor = { r = .1, g = .2, b = .3 } })) == .3)
    local bar = CreateFrame("StatusBar", nil, UIParent); bar:SetWidth(200); bar:SetHeight(10)
    bar:SetMinMaxValues(0, 1000); bar:SetValue(600); bar:GetStatusBarTexture():SetTexture("bar.tga")
    local ptype = 0
    local cb = { PowerType = function() return ptype end, Color = function() return .4, .7, 1, .8 end }
    local before = #frames
    SCP.Attach("uf", bar, cb)
    local ev
    for _, f in ipairs(frames) do if f.events.UNIT_SPELLCAST_START then ev = f end end
    assert(ev, "listening while the bar shows")
    castInfo = { name = "Greater Heal", rank = "Rank 7", id = 77 }
    Fire(ev, "UNIT_SPELLCAST_START", "player", "Greater Heal", "Rank 7")
    local holder = frames[#frames]
    assert(holder.parent == bar and holder.shown, "holder on the bar")
    local seg = holder._euiHost.seg
    assert(seg.shown and seg.width == 60 and seg.texture == "bar.tga", "segment = cost of range")
    local p = seg.points[1]
    assert(p[1] == "LEFT" and p[4] == 60, "starts cost-before the fill end")
    assert(math.abs(seg.texcoords[1] - 0.3) < 1e-9 and math.abs(seg.texcoords[2] - 0.6) < 1e-9)
    assert(seg.color[4] == .8)
    bar:SetValue(100); Tick(0.1)
    assert(seg.width == 20 and seg.points[1][4] == 0, "clamped to the shown value")
    bar.GetReverseFill = function() return true end; bar:SetValue(600); Tick(0.1)
    assert(seg.points[1][1] == "RIGHT" and seg.points[1][4] == -60, "reverse fill")
    bar.GetReverseFill = nil; bar.orientation = "VERTICAL"; bar:SetHeight(100); Tick(0.1)
    assert(seg.points[1][1] == "BOTTOM" and seg.height == 30 and seg.width == 200, "vertical")
    bar.orientation = nil; bar:SetHeight(10)
    Fire(ev, "UNIT_SPELLCAST_FAILED", "player", "Power Word: Shield", "Rank 14")
    assert(holder.shown, "failed instant during the cast keeps it")
    Fire(ev, "UNIT_SPELLCAST_STOP", "player", "Greater Heal", "Rank 7")
    assert(not holder.shown, "stop hides")
    castInfo = { name = "Greater Heal", rank = "Rank 7", id = 78 }
    Fire(ev, "UNIT_SPELLCAST_START", "player", "Greater Heal", "Rank 7")
    assert(holder.shown)
    castInfo = nil; Tick(0.1)
    assert(not holder.shown, "missed end event: cleared when no cast")
    ptype = 1
    castInfo = { name = "Greater Heal", rank = "Rank 7", id = 79 }
    Fire(ev, "UNIT_SPELLCAST_START", "player", "Greater Heal", "Rank 7")
    assert(not holder.shown, "non-mana bar draws nothing")
    SCP.Detach("uf")
    assert(next(ev.events) == nil, "detach drops events")
    return true
end)()''')

# Video Guides.
load('EllesmereUI_VideoGuides_335.lua', 'EllesmereUI')
assert lua.eval('''(function()
    local VG = EllesmereUI.VideoGuides
    assert(VG and EllesmereUI.MIDNIGHT_VIDEO_URL and EllesmereUI.PRESETS_URL)
    assert(VG.Show("midnight_121") == false, "12.1 announcement not registered")
    EllesmereUIDB = {}
    assert(VG.Show("presets_website") == true)
    local dimmer = _G.EUIVideoGuideDimmer
    assert(dimmer and dimmer.shown, "popup shown")
    assert(VG.FireOnce("unlock_mode") == true and EllesmereUIDB.videoGuidesSeen.unlock_mode)
    assert(VG.FireOnce("unlock_mode") == false, "once")
    local row = CreateFrame("Button", nil, UIParent)
    local tip = VG.AttachTip(row, "cooldown_manager")
    assert(tip and tip.shown and tip.textures[1].texture:find("icons_335\\\\play.tga", 1, true))
    EllesmereUIDB.tutorialTipsDisabled = true
    VG.RefreshTips()
    assert(not tip.shown, "tips toggle hides without SetShown")
    EllesmereUIDB.tutorialTipsDisabled = nil
    VG.RefreshTips()
    assert(tip.shown)
    tip.scripts.OnClick(tip, "LeftButton")
    assert(EllesmereUIDB.tutorialTipsSeen.cooldown_manager and not tip.shown)
    return true
end)()''')
vg = (core / 'EllesmereUI_VideoGuides_335.lua').read_text(encoding='utf-8')
assert 'icons_335\\\\play.tga' in vg and 'Register("midnight_121"' not in vg
assert 'eb:HookScript("OnHide", function(self) self:ClearFocus() end)' in vg

# Party Mode.
lua.execute(r'''
debuffs = {}
function UnitDebuff(u, i) local d = debuffs[i]; if d then return d.name, nil, nil, 0, nil, 0, 0, nil, nil, nil, d.id end end
instance = { "Halls", "party", 2, "Heroic", 5, 0, false }
function GetInstanceInfo() return unpack(instance) end
bossGUID = nil
function UnitGUID(u) if u == "boss1" then return bossGUID end; return u == "player" and "Player-1" or nil end
winner = nil
function GetBattlefieldWinner() return winner end
arena = { false, false }
function IsActiveBattlefieldArena() return arena[1], arena[2] end
function GetBattlefieldArenaFaction() return 0 end
EllesmereUIDB = {}
''')
load('EllesmereUI_PartyMode_335.lua', 'EllesmereUI')
assert lua.eval('''(function()
    EllesmereUIDB.partyModeSoundKey = "airhorn"
    EllesmereUI_TogglePartyMode()
    local c = _G.EllesmereUIPartyModeFrame
    assert(c and c.shown and EllesmereUIDB.partyMode and lastSound:find("AirHorn"))
    assert(cvars.gamma == "0.7", "dim lights falls back to gamma: " .. tostring(cvars.gamma))
    assert(#c.textures == 12 and c.textures[1].texture:find("party_beam.tga", 1, true) and c.textures[1].blend == "ADD")
    return true
end)()''')
assert lua.eval('''(function()
    local c = _G.EllesmereUIPartyModeFrame
    local mt = getmetatable(c.textures[1])
    local orig = mt.__index.SetTexCoord
    local coords = {}
    mt.__index.SetTexCoord = function(self, ...) coords[#coords + 1] = { ... }; return orig(self, ...) end
    Tick(0.05)
    mt.__index.SetTexCoord = orig
    assert(#coords == 12, "one quad per beam: " .. #coords)
    for _, t in ipairs(coords) do
        assert(#t == 8, "rotated coords")
        for i = 1, 8, 2 do assert(t[i] >= 0 and t[i] <= 1, "u inside the texture") end
    end
    EllesmereUI_TogglePartyMode()
    assert(not c.shown and cvars.gamma == "1", "stop restores gamma: " .. tostring(cvars.gamma))
    return true
end)()''')
assert lua.eval('''(function()
    local init
    for _, f in ipairs(frames) do if f.events.PLAYER_LOGIN and f.events.PLAYER_LOGOUT then init = f end end
    EllesmereUIDB.partyModeTriggerBloodlust = true
    EllesmereUIDB.partyModeTriggerHeroicBoss = true
    EllesmereUIDB.partyModeTriggerRatedBG = true
    EllesmereUIDB.partyModeTriggerRatedArena = true
    EllesmereUIDB.partyModeTriggerLevelUp = true
    Fire(init, "PLAYER_LOGIN")
    assert(init.events.UNIT_AURA and init.events.PLAYER_LEVEL_UP and init.events.UPDATE_BATTLEFIELD_STATUS)
    assert(init.events.INSTANCE_ENCOUNTER_ENGAGE_UNIT, "no DBM: boss units")
    local function reset() EllesmereUIDB.partyMode = false; EllesmereUI_StopPartyMode(); timers = {} end
    debuffs = { { name = "Sated", id = 57724 } }
    Fire(init, "UNIT_AURA", "target")
    assert(not EllesmereUIDB.partyMode, "other unit ignored")
    Fire(init, "UNIT_AURA", "player")
    assert(EllesmereUIDB.partyMode and timers[#timers].d == 40, "bloodlust 40s")
    reset()
    Fire(init, "UNIT_AURA", "player")
    assert(not EllesmereUIDB.partyMode, "edge only")
    debuffs = {}
    Fire(init, "UNIT_AURA", "player")
    bossGUID = "Creature-1"
    Fire(init, "INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    assert(init.events.COMBAT_LOG_EVENT_UNFILTERED)
    Fire(init, "COMBAT_LOG_EVENT_UNFILTERED", 1, "UNIT_DIED", "x", "y", 0, "Creature-1")
    assert(EllesmereUIDB.partyMode and timers[#timers].d == 30, "heroic boss kill")
    assert(not init.events.COMBAT_LOG_EVENT_UNFILTERED, "combat log dropped after the kill")
    reset(); now = now + 20
    instance[3] = 1
    Fire(init, "INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    Fire(init, "COMBAT_LOG_EVENT_UNFILTERED", 1, "UNIT_DIED", "x", "y", 0, "Creature-1")
    assert(not EllesmereUIDB.partyMode, "normal kill with only heroic enabled")
    reset(); now = now + 20
    instance = { "ICC", "raid", 2, "25", 25, 1, true }
    Fire(init, "INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    Fire(init, "COMBAT_LOG_EVENT_UNFILTERED", 1, "UNIT_DIED", "x", "y", 0, "Creature-1")
    assert(EllesmereUIDB.partyMode, "dynamic heroic raid")
    reset()
    winner = 1
    Fire(init, "UPDATE_BATTLEFIELD_STATUS")
    assert(EllesmereUIDB.partyMode, "alliance battleground win")
    reset()
    Fire(init, "UPDATE_BATTLEFIELD_STATUS")
    assert(not EllesmereUIDB.partyMode, "one celebration per match")
    winner = nil; Fire(init, "UPDATE_BATTLEFIELD_STATUS")
    winner = 0; arena = { true, false }
    Fire(init, "UPDATE_BATTLEFIELD_STATUS")
    assert(not EllesmereUIDB.partyMode, "skirmish arena does not count")
    winner = nil; Fire(init, "UPDATE_BATTLEFIELD_STATUS")
    winner = 0; arena = { true, true }
    Fire(init, "UPDATE_BATTLEFIELD_STATUS")
    assert(EllesmereUIDB.partyMode, "rated arena win")
    reset()
    Fire(init, "PLAYER_LEVEL_UP")
    assert(EllesmereUIDB.partyMode, "level up")
    Fire(init, "PLAYER_LOGOUT")
    assert(EllesmereUIDB.partyMode == false, "auto celebration not saved on")
    -- DBM path
    local cbs = {}
    DBM = { RegisterCallback = function(self, ev, fn) cbs[ev] = fn end }
    winner = nil
    Fire(init, "ADDON_LOADED", "DBM-Core")
    assert(cbs.DBM_Kill and not init.events.INSTANCE_ENCOUNTER_ENGAGE_UNIT, "DBM replaces boss units")
    reset(); now = now + 20
    instance = { "Naxx", "raid", 4, "25H", 25, 0, false }
    cbs.DBM_Kill("DBM_Kill", {})
    assert(EllesmereUIDB.partyMode, "DBM kill")
    -- spin registry
    assert(not EllesmereUI.PartySpinHasTarget("unitFrames"))
    EllesmereUI.PartySpin_Create({ target = "unitFrames", collect = function() return {} end })
    assert(EllesmereUI.PartySpinHasTarget("unitFrames") and not EllesmereUI.PartySpinHasTarget("actionBars"))
    return true
end)()''')
print('core engines ok')
