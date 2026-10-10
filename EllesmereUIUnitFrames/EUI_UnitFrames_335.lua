-- Wrath adapters scoped to this addon. No keyboard or global CreateFrame hooks.
local _, ns = ...
ns.Wrath = {}
local W = ns.Wrath
-- Wrath has no secret-value type. Define the predicate before the engine/main
-- capture it, without relying on the load-on-demand Options compatibility layer.
W.IsSecretValue = _G.issecretvalue or function() return false end
-- 3.3.5 cannot load file data IDs. The few the engine and the options preview
-- pass resolve to the same art by path; any other ID shows the question mark.
W.ICON_FILE_IDS = {
    [134400] = "Interface\\Icons\\INV_Misc_QuestionMark",
    [136197] = "Interface\\Icons\\Spell_Shadow_ShadowBolt",
    [136243] = "Interface\\Icons\\Trade_Engineering",
}
function W.ResolveBarTexture(path)
    if type(path) == "string" and W.BarTexturePaths then
        return W.BarTexturePaths[path:lower():gsub("/", "\\")] or path
    end
    -- Color components (SetColorTexture) are 0..1; file IDs are large integers.
    if type(path) == "number" and path > 1 and path % 1 == 0 then
        return W.ICON_FILE_IDS[path] or W.ICON_FILE_IDS[134400]
    end
    return path
end
-- 3.3.5 only has state drivers: an attribute driver on "state-X" is the state
-- driver X (RegisterStateDriver writes that same attribute). Other attributes
-- have no 3.3.5 driver and are left alone.
function W.RegisterAttributeDriver(frame, attribute, values)
    if _G.RegisterAttributeDriver then return _G.RegisterAttributeDriver(frame, attribute, values) end
    local state = type(attribute) == "string" and attribute:match("^state%-(.+)$")
    if state then RegisterStateDriver(frame, state, values) end
end
function W.UnregisterAttributeDriver(frame, attribute)
    if _G.UnregisterAttributeDriver then return _G.UnregisterAttributeDriver(frame, attribute) end
    local state = type(attribute) == "string" and attribute:match("^state%-(.+)$")
    if state then UnregisterStateDriver(frame, state) end
end
local nativeCreateFrame = CreateFrame
local powerEvents = { "UNIT_MANA", "UNIT_RAGE", "UNIT_ENERGY", "UNIT_FOCUS", "UNIT_RUNIC_POWER" }
local powerTokens = { UNIT_MANA = "MANA", UNIT_RAGE = "RAGE", UNIT_ENERGY = "ENERGY", UNIT_FOCUS = "FOCUS", UNIT_RUNIC_POWER = "RUNIC_POWER" }
local maxPowerEvents = { "UNIT_MAXMANA", "UNIT_MAXRAGE", "UNIT_MAXENERGY", "UNIT_MAXFOCUS", "UNIT_MAXRUNIC_POWER" }
local eventMap = {
    UNIT_POWER_UPDATE = powerEvents, UNIT_POWER_FREQUENT = powerEvents,
    UNIT_MAXPOWER = maxPowerEvents,
    GROUP_ROSTER_UPDATE = { "PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE" },
    PLAYER_SPECIALIZATION_CHANGED = { "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_TALENT_UPDATE" },
    TRAIT_CONFIG_UPDATED = { "PLAYER_TALENT_UPDATE", "SPELLS_CHANGED" },
    UNIT_MAX_HEALTH_MODIFIERS_CHANGED = { "UNIT_MAXHEALTH" },
    UNIT_TARGETABLE_CHANGED = { "UNIT_FLAGS" },
    PLAYER_MOUNT_DISPLAY_CHANGED = { "UNIT_AURA" },
    UNIT_ABSORB_AMOUNT_CHANGED = false, UNIT_HEAL_ABSORB_AMOUNT_CHANGED = false,
    UNIT_HEAL_PREDICTION = false, UNIT_POWER_BAR_SHOW = false, UNIT_POWER_BAR_HIDE = false,
    UNIT_SPELLCAST_EMPOWER_START = false, UNIT_SPELLCAST_EMPOWER_UPDATE = false,
    UNIT_SPELLCAST_EMPOWER_STOP = false, PLAYER_CAN_GLIDE_CHANGED = false,
    PLAYER_IS_GLIDING_CHANGED = false,
}
local function Color(r, g, b, a)
    local c = { r = r or 0, g = g or 0, b = b or 0, a = a == nil and 1 or a }
    function c:GetRGB() return self.r, self.g, self.b end
    function c:GetRGBA() return self.r, self.g, self.b, self.a end
    function c:SetRGB(x, y, z) self.r, self.g, self.b = x, y, z end
    function c:SetRGBA(x, y, z, w) self:SetRGB(x, y, z); self.a = w end
    function c:GenerateHexColor()
        return string.format("%02x%02x%02x%02x", self.a*255, self.r*255, self.g*255, self.b*255)
    end
    return c
end
W.CreateColor = Color
local function Curve()
    local c = { points = {} }
    function c:SetType(kind) self.kind = kind end
    function c:AddPoint(x, y)
        self.points[#self.points + 1] = { x, y }
        table.sort(self.points, function(a, b) return a[1] < b[1] end)
    end
    function c:Evaluate(x)
        local p = self.points
        if #p == 0 then return x end
        if x <= p[1][1] then return p[1][2] end
        for i = 2, #p do
            if x <= p[i][1] then
                local a, b = p[i-1], p[i]
                if self.kind == Enum.LuaCurveType.Step then return x == b[1] and b[2] or a[2] end
                local f = (x - a[1]) / (b[1] - a[1])
                if type(a[2]) == "table" then
                    return Color(a[2].r+(b[2].r-a[2].r)*f, a[2].g+(b[2].g-a[2].g)*f,
                        a[2].b+(b[2].b-a[2].b)*f, a[2].a+(b[2].a-a[2].a)*f)
                end
                return a[2] + (b[2]-a[2])*f
            end
        end
        return p[#p][2]
    end
    return c
end
C_CurveUtil = C_CurveUtil or {}
C_CurveUtil.CreateCurve = C_CurveUtil.CreateCurve or Curve
C_CurveUtil.CreateColorCurve = C_CurveUtil.CreateColorCurve or Curve
C_CurveUtil.EvaluateColorValueFromBoolean = C_CurveUtil.EvaluateColorValueFromBoolean or function(v, yes, no) return v and yes or no end
Enum = Enum or {}
Enum.PowerType = Enum.PowerType or { Mana=0, Rage=1, Focus=2, Energy=3, ComboPoints=4, Runes=5, RunicPower=6 }
Enum.LuaCurveType = Enum.LuaCurveType or { Linear=0, Step=1 }
Enum.StatusBarInterpolation = Enum.StatusBarInterpolation or { Immediate=0, ExponentialEaseOut=1 }
Enum.StatusBarTimerDirection = Enum.StatusBarTimerDirection or { ElapsedTime=0, RemainingTime=1 }
Enum.StatusBarFillStyle = Enum.StatusBarFillStyle or { Standard=0, Reverse=1 }
CurveConstants = CurveConstants or {}
if not CurveConstants.ScaleTo100 then
    local c = Curve(); c:AddPoint(0, 0); c:AddPoint(1, 100); CurveConstants.ScaleTo100 = c
end
function W.UnitHealthPercent(unit, _, curve)
    local max = UnitHealthMax(unit) or 0
    local value = max > 0 and (UnitHealth(unit) or 0)/max or 0
    return curve and curve:Evaluate(value) or value
end
function W.UnitPowerPercent(unit, kind, _, curve)
    local max = UnitPowerMax(unit, kind) or 0
    local value = max > 0 and (UnitPower(unit, kind) or 0)/max or 0
    return curve and curve:Evaluate(value) or value
end
function W.UnitCastingInfo(unit)
    local name, rank, text, icon, startMS, endMS, trade, castID, protected = UnitCastingInfo(unit)
    local info = name and C_Spell.GetSpellInfo(name)
    return name, text or name, icon, startMS, endMS, trade, castID, protected, info and info.spellID, castID
end
function W.UnitChannelInfo(unit)
    -- Wrath's third return for channels is the literal "Channeling", not the spell.
    local name, rank, text, icon, startMS, endMS, trade, protected = UnitChannelInfo(unit)
    local info = name and C_Spell.GetSpellInfo(name)
    return name, name, icon, startMS, endMS, trade, protected, info and info.spellID, false
end
function W.Duration(startTime, endTime)
    local d = { startTime=startTime, endTime=endTime }
    function d:GetTotalDuration() return math.max(0, self.endTime-self.startTime) end
    function d:GetElapsedDuration() return math.max(0, math.min(self:GetTotalDuration(), GetTime()-self.startTime)) end
    function d:GetRemainingDuration() return math.max(0, self.endTime-GetTime()) end
    function d:IsZero() return self:GetRemainingDuration() == 0 end
    return d
end
function W.UnitCastingDuration(unit)
    local _, _, _, startMS, endMS = W.UnitCastingInfo(unit)
    return startMS and W.Duration(startMS/1000, endMS/1000)
end
function W.UnitChannelDuration(unit)
    local _, _, _, startMS, endMS = W.UnitChannelInfo(unit)
    return startMS and W.Duration(startMS/1000, endMS/1000)
end
C_Spell.GetSpellCooldownDuration = C_Spell.GetSpellCooldownDuration or function(id)
    local start, duration = GetSpellCooldown(id)
    return start and W.Duration(start, start+(duration or 0))
end
C_StringUtil = C_StringUtil or {}
C_StringUtil.TruncateWhenZero = C_StringUtil.TruncateWhenZero or function(n) return n == 0 and "" or tostring(n) end
C_CVar.GetCVarBool = C_CVar.GetCVarBool or function(key) return GetCVar(key) == "1" end
C_PetInfo = C_PetInfo or {}
C_PetInfo.GetPetHappiness = C_PetInfo.GetPetHappiness or GetPetHappiness
-- Wrath returns the diet as varargs; the Retail caller expects a list.
C_PetInfo.GetPetFoodTypes = C_PetInfo.GetPetFoodTypes or function()
    if GetPetFoodTypes then return { GetPetFoodTypes() } end
end
W.UnitIsTapDenied = UnitIsTapDenied or function(u) return UnitIsTapped(u) and not UnitIsTappedByPlayer(u) end
W.IsInGroup = IsInGroup or function() return GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0 end
W.IsInRaid = IsInRaid or function() return GetNumRaidMembers() > 0 end
-- Shared visibility helpers resolve these globals at paint time.
IsInGroup = IsInGroup or W.IsInGroup
IsInRaid = IsInRaid or W.IsInRaid
W.AbbreviateNumbers = AbbreviateNumbers or function(n, opts)
    n = tonumber(n) or 0
    local a = math.abs(n)
    local rows = opts and (opts.breakpointData or opts.config)
    if rows then
        for _, row in ipairs(rows) do
            if a >= row.breakpoint then
                local divisor, fraction = row.significandDivisor or 1, row.fractionDivisor or 1
                local v = math.floor(a/divisor)/fraction
                local precision = math.max(0, math.floor(math.log10(fraction)+.5))
                local text = string.format("%."..precision.."f", n < 0 and -v or v)
                if precision > 0 then text = text:gsub("0+$", ""):gsub("%.$", "") end
                local suffix = row.abbreviation or ""
                if row.abbreviationIsGlobal then suffix = _G[suffix] or suffix end
                return text..suffix
            end
        end
        return tostring(math.floor(n))
    end
    if a >= 1000000 then return string.format("%.1fm", n/1000000) end
    if a >= 1000 then return string.format("%.1fk", n/1000) end
    return tostring(math.floor(n))
end

-- Some patched Wrath clients expose SetAtlas but only ship a subset of Retail
-- atlases. Never submit an unknown name to that method. Known icons use files;
-- unsupported decoration clears instead of leaving stale art or raising errors.
function W.AtlasExists(atlas)
    if type(atlas) ~= "string" or atlas == "" then return false end
    if C_Texture and C_Texture.GetAtlasInfo then
        local ok, info = pcall(C_Texture.GetAtlasInfo, atlas)
        if ok and info then return true end
    end
    if AtlasUtil and AtlasUtil.AtlasExists then
        local ok, exists = pcall(AtlasUtil.AtlasExists, AtlasUtil, atlas)
        if ok and exists then return true end
    end
    return false
end

local happinessCoords = {
    ["UI-PetHappiness"] = {0, .1875, 0, .359375},
    ["UI-PetNeutral"] = {.1875, .375, 0, .359375},
    ["UI-PetMad"] = {.375, .5625, 0, .359375},
}
local eliteAtlases = {
    ["nameplates-icon-elite-gold"] = true,
    ["nameplates-icon-elite-silver"] = true,
    ["nameplates-icon-rareelite"] = true,
}
local function SetAtlasFallback(tex, atlas, useSize)
    if not tex.SetTexture then return end
    local coords = happinessCoords[atlas]
    if coords then
        tex:SetTexture("Interface\\PetPaperDollFrame\\UI-PetHappiness")
        tex:SetTexCoord(unpack(coords))
        if useSize then tex:SetSize(24, 23) end
    elseif eliteAtlases[atlas] then
        tex:SetTexture("Interface\\AddOns\\EllesmereUIUnitFrames\\Media\\elite-badge-335.tga")
        tex:SetTexCoord(0, 43/64, 0, 43/64)
        if tex.SetDesaturated then tex:SetDesaturated(atlas ~= "nameplates-icon-elite-gold") end
        if useSize then tex:SetSize(16, 16) end
    elseif atlas == "UI-CastingBar-Fill" then
        tex:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        tex:SetTexCoord(0, 1, 0, 1)
    else
        local class = type(atlas) == "string" and atlas:match("^classicon%-(.+)$")
        local classCoords = class and EllesmereUI.CLASS_ICON_SPRITE_COORDS[class:upper()]
        if classCoords then
            tex:SetTexture("Interface\\AddOns\\EllesmereUI\\media\\icons\\class-full\\modern.tga")
            tex:SetTexCoord(unpack(classCoords))
            if useSize then tex:SetSize(16, 16) end
        else
            tex:SetTexture(nil)
        end
    end
end

-- Patch addon-owned regions only. Rendering flags have no Wrath equivalent.
local function PatchRegion(obj)
    if not obj or obj._eui335Region then return obj end
    obj._eui335Region = true
    local function noop() end
    for _, key in ipairs({ "SetSnapToPixelGrid", "SetTexelSnappingBias", "SetClipsChildren",
        "AddMaskTexture", "RemoveMaskTexture", "SetMouseClickEnabled", "EnableMouseMotion",
        "SetDrawBling", "SetDrawEdge", "SetDrawSwipe", "SetHideCountdownNumbers", "SetMaxLines",
        "SetCamDistanceScale", "SetPortraitZoom", "SetWordWrap" }) do
        if not obj[key] then obj[key] = noop end
    end
    -- Any clipping found here is another addon's ScrollFrame reparenting polyfill.
    if obj.CreateTexture then obj.SetClipsChildren = noop end
    if not obj.SetSize then function obj:SetSize(w, h) self:SetWidth(w); self:SetHeight(h) end end
    if not obj.SetShown then function obj:SetShown(v) if v then self:Show() else self:Hide() end end end
    if not obj.SetAlphaFromBoolean then function obj:SetAlphaFromBoolean(v, a, b) self:SetAlpha(v and (a or 1) or (b or 0)) end end
    if not obj.IsMouseOver then function obj:IsMouseOver() return MouseIsOver(self) end end
    if obj.SetTexture and not obj.SetColorTexture then function obj:SetColorTexture(r,g,b,a) self:SetTexture(r,g,b,a or 1) end end
    if obj.SetTexture then
        local setTexture = obj.SetTexture
        function obj:SetTexture(path, ...)
            return setTexture(self, W.ResolveBarTexture(path), ...)
        end
        local nativeSetAtlas = obj.SetAtlas
        function obj:SetAtlas(atlas, useSize, ...)
            if nativeSetAtlas and W.AtlasExists(atlas) then
                return nativeSetAtlas(self, atlas, useSize, ...)
            end
            return SetAtlasFallback(self, atlas, useSize)
        end
    end
    if obj.SetGradientAlpha then
        -- Lua only expands the final call: unpack both colors explicitly.
        function obj:SetGradient(orientation, a, b)
            local r,g,bl,alpha = a:GetRGBA(); local x,y,z,w = b:GetRGBA()
            self:SetGradientAlpha(orientation,r,g,bl,alpha,x,y,z,w)
        end
    end
    if obj.SetStatusBarTexture then
        local setTexture = obj.SetStatusBarTexture
        local getTexture = obj.GetStatusBarTexture
        if getTexture then
            function obj:SetStatusBarTexture(path, ...)
                local result = setTexture(self, W.ResolveBarTexture(path), ...)
                -- A rejected/missing Wrath file can leave the bar without a
                -- fill object. Use a real native texture instead of a fake region.
                if path ~= nil and not getTexture(self) then
                    return setTexture(self, "Interface\\Buttons\\WHITE8X8", ...)
                end
                return result
            end
            function obj:GetStatusBarTexture() return PatchRegion(getTexture(self)) end
        end
        if not obj.SetReverseFill then function obj:SetReverseFill(v) self._eui335Reverse = v end end
        if not obj.GetReverseFill then function obj:GetReverseFill() return self._eui335Reverse or false end end
        if not obj.SetFillStyle then function obj:SetFillStyle(v) self:SetReverseFill(v == Enum.StatusBarFillStyle.Reverse) end end
        function obj:GetTimerDuration() return self._eui335Duration end
        function obj:SetTimerDuration(duration, _, direction)
            self._eui335Duration, self._eui335Direction = duration, direction
            if not duration then return end
            self:SetMinMaxValues(0, math.max(.001, duration:GetTotalDuration()))
            self:SetValue(direction == Enum.StatusBarTimerDirection.RemainingTime and duration:GetRemainingDuration() or duration:GetElapsedDuration())
            -- The cast engine owns one render-frame clock for fill, labels
            -- and expiry. Generic timer bars still need this fallback hook.
            if not self._euiCastDriver and not self._eui335TimerHook then
                self._eui335TimerHook = true
                self:HookScript("OnUpdate", function(bar)
                    local d = bar._eui335Duration
                    if d and (bar.casting or bar.channeling) then
                        bar:SetValue(bar._eui335Direction == Enum.StatusBarTimerDirection.RemainingTime and d:GetRemainingDuration() or d:GetElapsedDuration())
                        if d:IsZero() then bar.casting, bar.channeling = nil, nil; bar:Hide() end
                    end
                end)
            end
        end
    end
    if obj.CreateTexture then
        local create = obj.CreateTexture
        function obj:CreateTexture(...) return PatchRegion(create(self, ...)) end
        local font = obj.CreateFontString
        function obj:CreateFontString(...) return PatchRegion(font(self, ...)) end
        -- Some 3.3.5 clients/addons expose a CreateMaskTexture that returns nil:
        -- fall back to a hidden placeholder that native AddMaskTexture never sees.
        local createMask = obj.CreateMaskTexture
        function obj:CreateMaskTexture(...)
            local mask = createMask and createMask(self, ...)
            if mask then return PatchRegion(mask) end
            mask = self:CreateTexture(); mask:Hide(); mask._eui335FakeMask = true
            return mask
        end
    end
    for _, key in ipairs({ "AddMaskTexture", "RemoveMaskTexture" }) do
        local native = obj[key]
        if native then
            obj[key] = function(self, mask, ...)
                if not mask or mask._eui335FakeMask then return end
                return native(self, mask, ...)
            end
        end
    end
    return obj
end
function W.CreateFrame(kind, name, parent, templates, ...)
    if templates then
        local keep = {}
        for t in templates:gmatch("[^,%s]+") do
            if t ~= "BackdropTemplate" and t ~= "PingableUnitFrameTemplate" then keep[#keep+1] = t end
        end
        templates = #keep > 0 and table.concat(keep, ",") or nil
    end
    local f = PatchRegion(nativeCreateFrame(kind, name, parent, templates, ...))
    if kind == "EditBox" then
        f:SetAutoFocus(false)
        f:HookScript("OnHide", function(self) self:ClearFocus() end)
    end
    local register, unregister, unregisterAll, setScript = f.RegisterEvent, f.UnregisterEvent, f.UnregisterAllEvents, f.SetScript
    local registrations, aliases = {}, {}
    function f:RegisterEvent(event)
        if registrations[event] then return end
        local mapped = eventMap[event]
        if mapped == false then return end
        mapped = mapped or { event }
        registrations[event] = mapped
        for _, native in ipairs(mapped) do
            local list = aliases[native]
            if not list then list = {}; aliases[native] = list; register(self, native) end
            list[event] = true
        end
    end
    function f:RegisterUnitEvent(event, ...)
        self:RegisterEvent(event)
        if registrations[event] then
            self._eui335Units = self._eui335Units or {}
            self._eui335Units[event] = { ... }
        end
    end
    function f:UnregisterEvent(event)
        for _, native in ipairs(registrations[event] or {}) do
            aliases[native][event] = nil
            if not next(aliases[native]) then aliases[native] = nil; unregister(self, native) end
        end
        registrations[event] = nil
        if self._eui335Units then self._eui335Units[event] = nil end
    end
    function f:UnregisterAllEvents()
        registrations, aliases = {}, {}; self._eui335Units = nil; unregisterAll(self)
    end
    function f:SetScript(script, fn)
        if script ~= "OnEvent" or not fn then return setScript(self, script, fn) end
        setScript(self, script, function(frame, native, unit, ...)
            -- Load-on-demand options explicitly invoke their init script after login.
            if native == nil then return fn(frame) end
            local list = aliases[native]
            if not list then return end
            -- Snapshot: handlers can unregister their own events during dispatch.
            local events = {}; for logical in pairs(list) do events[#events+1] = logical end
            for _, logical in ipairs(events) do
                if registrations[logical] then
                    local units = frame._eui335Units and frame._eui335Units[logical]
                    local accept = not units or #units == 0
                    if units then for _, token in ipairs(units) do if token == unit then accept = true end end end
                    -- Talent events do not carry a unit token on Wrath.
                    if logical == "PLAYER_SPECIALIZATION_CHANGED" then accept = true end
                    if accept then
                        if logical == "PLAYER_SPECIALIZATION_CHANGED" then fn(frame, logical, "player")
                        elseif logical == "UNIT_POWER_UPDATE" or logical == "UNIT_POWER_FREQUENT" then
                            -- The token names the power that changed (a druid's
                            -- mana keeps ticking while a form shows rage/energy).
                            local token = powerTokens[native]
                            if not token then local _, t = UnitPowerType(unit); token = t end
                            fn(frame, logical, unit, token)
                        else fn(frame, logical, unit, ...) end
                    end
                end
            end
        end)
    end
    return f
end
-- Wrath's SecureUnitButton uses the "menu" action and a menu callback.
-- The Retail "togglemenu" action does not exist on the stock 3.3.5 client.
local dropdown
local function OpenUnitMenu(button, unit)
    unit = unit or SecureButton_GetModifiedUnit(button) or button._euiUnit
    if not unit then return end
    if not dropdown then
        dropdown = W.CreateFrame("Frame", "EllesmereUIUnitFrames335Dropdown", UIParent, "UIDropDownMenuTemplate")
        dropdown:SetID(1)
        table.insert(UnitPopupFrames, "EllesmereUIUnitFrames335Dropdown")
        if EllesmereUI.UnitMenuWithoutFocus then EllesmereUI.UnitMenuWithoutFocus(dropdown) end
        UIDropDownMenu_Initialize(dropdown, function(self)
            local u = self.unit
            if not u then return end
            local menu
            if UnitIsUnit(u,"player") then menu="SELF"
            elseif UnitIsUnit(u,"vehicle") then menu="VEHICLE"
            elseif UnitIsUnit(u,"pet") then menu="PET"
            elseif u == "focus" then menu="FOCUS"
            elseif UnitIsPlayer(u) then
                menu = UnitInRaid(u) and "RAID_PLAYER" or UnitInParty(u) and "PARTY" or "PLAYER"
            else menu="TARGET" end
            UnitPopup_ShowMenu(self,menu,u)
        end,"MENU")
    end
    if dropdown.openedFor and dropdown.openedFor ~= button then CloseDropDownMenus() end
    dropdown.unit, dropdown.openedFor = unit, button
    ToggleDropDownMenu(1,nil,dropdown,"cursor")
end
function W.AttachUnitMenu(frame)
    frame.menu = OpenUnitMenu
    frame:SetAttribute("*type2", "menu")
end
-- Focus frame "Clear Focus Click": a secure /clearfocus macro on one click, so it
-- also works in combat, where the menu's Clear Focus is hidden.
W.CLEAR_FOCUS_CLICKS = {
    shift2 = { "shift-", "2" }, ctrl2 = { "ctrl-", "2" }, alt2 = { "alt-", "2" },
    middle = { "", "3" }, shift1 = { "shift-", "1" },
}
W.CLEAR_FOCUS_LABELS = {
    none = "None", shift2 = "Shift + Right Click", ctrl2 = "Ctrl + Right Click",
    alt2 = "Alt + Right Click", middle = "Middle Click", shift1 = "Shift + Left Click",
}
W.CLEAR_FOCUS_ORDER = { "none", "shift2", "ctrl2", "alt2", "middle", "shift1" }
local clearFocusWait, clearFocusSettings
function W.ApplyClearFocusClick(settings)
    if settings then clearFocusSettings = settings end
    local frame = ns.frames and ns.frames.focus
    if not frame or not frame.SetAttribute then return end
    if InCombatLockdown() then
        if not clearFocusWait then
            clearFocusWait = CreateFrame("Frame")
            clearFocusWait:SetScript("OnEvent", function(self)
                self:UnregisterEvent("PLAYER_REGEN_ENABLED"); W.ApplyClearFocusClick()
            end)
        end
        clearFocusWait:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    for key, value in pairs(frame._euiClearFocusAttrs or {}) do
        if frame:GetAttribute(key) == value then frame:SetAttribute(key, nil) end
    end
    frame._euiClearFocusAttrs = {}
    local s = ns.db and ns.db.profile and ns.db.profile.focus or clearFocusSettings
    local click = s and W.CLEAR_FOCUS_CLICKS[s.clearFocusClick or "shift2"]
    if not click then return end
    local mod, button = click[1], click[2]
    for key, value in pairs({ [mod .. "type" .. button] = "macro", [mod .. "macrotext" .. button] = "/clearfocus" }) do
        frame:SetAttribute(key, value); frame._euiClearFocusAttrs[key] = value
    end
end
function W.ContinueOnAddOnLoaded(name, callback)
    if IsAddOnLoaded(name) then callback(); return end
    local f = W.CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, _, loaded)
        if loaded == name then self:UnregisterAllEvents(); callback() end
    end)
end
function W.UnitPowerMax(unit, kind, ...)
    if kind == 4 then return 5 end
    if kind == 5 then return 6 end
    return UnitPowerMax(unit, kind, ...)
end
local function RaidRank(unit)
    if not unit then return end
    local count = GetNumRaidMembers() or 0
    if count == 0 then return end
    local index = tonumber(tostring(unit):match("^raid(%d+)$"))
    if not index then
        for i = 1, count do
            if UnitIsUnit(unit, "raid" .. i) then index = i; break end
        end
    end
    if index then local _, rank = GetRaidRosterInfo(index); return rank end
end
-- UnitIsPartyLeader(unit) can answer true for several party members on 3.3.5;
-- Blizzard's party frames use GetPartyLeaderIndex (0 = player) instead.
local function PartyLeader(unit)
    if not unit then return false end
    if not GetPartyLeaderIndex then return UnitIsPartyLeader(unit) and true or false end
    if (GetNumRaidMembers() or 0) > 0 or (GetNumPartyMembers() or 0) == 0 then return false end
    local index = GetPartyLeaderIndex() or 0
    if UnitIsUnit(unit, "player") then
        if IsPartyLeader then return IsPartyLeader() and true or false end
        return index == 0
    end
    for i = 1, GetNumPartyMembers() do
        if UnitIsUnit(unit, "party" .. i) then return index == i end
    end
    return false
end
-- Always ours: compat addons (!!!ClassicAPI) define UnitIsGroupLeader on top of
-- UnitIsPartyLeader and crown several party members.
W.UnitIsGroupLeader = function(unit)
    return RaidRank(unit) == 2 or PartyLeader(unit)
end
W.UnitIsGroupAssistant = function(unit) return RaidRank(unit) == 1 end
-- Wrath IsSpellInRange takes a spellbook name and answers 1/0/nil; the core
-- C_Spell shim forwards numeric IDs, which the 3.3.5 client rejects.
function W.IsSpellInRange(spell, unit)
    local name = type(spell) == "number" and GetSpellInfo(spell) or spell
    if not (name and unit) then return nil end
    local r = IsSpellInRange(name, unit)
    if r == nil then return nil end
    return r == 1
end
W.HarmRangeSpells = { SHAMAN = { 403 } }
W.HealSpells = {
    PRIEST = { 2061, 2050 }, PALADIN = { 19750, 635 },
    SHAMAN = { 8004, 331 }, DRUID = { 8936, 5185 },
}
W.UnitIsMercenary = UnitIsMercenary or function() return false end
-- Options preview auras: Retail lists icon file IDs, so Wrath lists spells of
-- the same kind and takes their icons from the client.
W.PreviewBuffSpells = {
    WARRIOR = { 6673, 2687, 871, 1719, 18499 },
    PALADIN = { 19740, 642, 465, 21084, 31884 },
    HUNTER = { 13165, 3045, 19506, 5118, 19263 },
    ROGUE = { 5171, 5277, 2983, 1784, 13750 },
    PRIEST = { 1243, 17, 139, 588, 15473 },
    DEATHKNIGHT = { 57330, 49222, 48792, 48707, 51271 },
    SHAMAN = { 324, 52127, 2825, 974, 2645 },
    MAGE = { 1459, 11426, 1463, 30482, 12472 },
    WARLOCK = { 706, 28176, 5697, 6229, 19028 },
    DRUID = { 1126, 774, 8936, 467, 22812 },
    FALLBACK = { 1126, 1243, 1459, 20217, 467 },
}
W.PreviewDebuffSpells = {
    589, 172, 980, 122, 348, 770, 8056, 7386, 772, 1715,
    118, 5782, 8921, 1978, 1943, 703, 702, 1130, 8050, 34914,
}
W.PreviewCastSpells = { { name = "Hearthstone", spellID = 8690, castTime = 10.0 } }
function W.SpellIcons(ids)
    local out = {}
    for i, id in ipairs(ids) do
        local _, _, icon = GetSpellInfo(id)
        out[i] = icon or W.ICON_FILE_IDS[134400]
    end
    return out
end
-- Faction badge: the Retail atlas styles (PvP Emblem, Honor Portrait, Map
-- Flag) are not in the 3.3.5 client; they draw the stock Wrath PvP icon, the
-- art the Classic Banner style also uses. File styles stay as they are.
function W.SetFactionArt(tex, style, faction)
    local art = EllesmereUI.FACTION_ART
    local entry = art and (art[style] or art.pvp)
    if entry and entry.atlas then
        local name = entry.atlas:format(entry.lower and faction:lower() or faction)
        if not W.AtlasExists(name) then
            tex:SetTexture("Interface\\TargetingFrame\\UI-PVP-" .. faction)
            tex:SetTexCoord(0, 0.65625, 0, 0.65625)
            return
        end
    end
    EllesmereUI.SetFactionArt(tex, style, faction)
end
-- Detached portrait shapes: Retail enlarges the art past the shape's opening
-- and lets the shape mask clip it. 3.3.5 has no mask textures, so the art is
-- fitted to the opening instead. The client's 2D portrait is already round,
-- so round shapes show it whole; other shapes keep the square crop.
local ROUND_SHAPES = { circle = true, pixelsCircle = true, portrait = true }
local function FitTo(tex, host, ix, iy)
    if not tex then return end
    tex:ClearAllPoints()
    tex:SetPoint("TOPLEFT", host, "TOPLEFT", ix, -iy)
    tex:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -ix, iy)
end
-- Mirror Portrait only rewrites the crop when its flip state changes, so the
-- flip is carried over here.
local function SetCrop(tex, c)
    if tex._mirrored then tex:SetTexCoord(c, 1 - c, 1 - c, c) else tex:SetTexCoord(1 - c, c, 1 - c, c) end
end
function W.FitUnmaskedPortrait(host, shape, insetPx, tex2d, texClass)
    if tex2d and ns.UF_Blizz and ns.UF_Blizz() then tex2d._wrathRound = nil; tex2d = nil end
    if not shape then
        if tex2d and tex2d._wrathRound then SetCrop(tex2d, .85); tex2d._wrathRound = nil end
        return
    end
    local w, h = host:GetWidth(), host:GetHeight()
    if w < 1 then w = 46 end
    if h < 1 then h = 46 end
    local ix, iy = w * (insetPx or 17) / 128, h * (insetPx or 17) / 128
    FitTo(tex2d, host, ix, iy)
    FitTo(texClass, host, ix + w * 0.08, iy + h * 0.08)
    if tex2d then
        local round = ROUND_SHAPES[shape] == true
        SetCrop(tex2d, round and 1 or .85)
        tex2d._wrathRound = round or nil
    end
end
if EllesmereUI and not EllesmereUI.PaintThreatPct then
    function EllesmereUI.PaintThreatPct(fs, pct, status, isTanking, colorByThreat)
        fs:SetFormattedText("%.0f%%", pct)
        if colorByThreat and type(status) == "number" then fs:SetTextColor(GetThreatStatusColor(status))
        elseif colorByThreat and isTanking then fs:SetTextColor(GetThreatStatusColor(3))
        else fs:SetTextColor(1, 1, 1) end
    end
end
