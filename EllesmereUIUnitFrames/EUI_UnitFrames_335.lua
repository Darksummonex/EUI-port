-- Wrath adapters scoped to this addon. No keyboard or global CreateFrame hooks.
local _, ns = ...
ns.Wrath = {}
local W = ns.Wrath
-- Wrath has no secret-value type. Define the predicate before the engine/main
-- capture it, without relying on the load-on-demand Options compatibility layer.
W.IsSecretValue = _G.issecretvalue or function() return false end
function W.ResolveBarTexture(path)
    if type(path) == "string" and W.BarTexturePaths then
        return W.BarTexturePaths[path:lower():gsub("/", "\\")] or path
    end
    return path
end
local nativeCreateFrame = CreateFrame
local powerEvents = { "UNIT_MANA", "UNIT_RAGE", "UNIT_ENERGY", "UNIT_FOCUS", "UNIT_RUNIC_POWER" }
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
    local name, rank, text, icon, startMS, endMS, trade, protected = UnitChannelInfo(unit)
    local info = name and C_Spell.GetSpellInfo(name)
    return name, text or name, icon, startMS, endMS, trade, protected, info and info.spellID, false
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
C_PetInfo.GetPetFoodTypes = C_PetInfo.GetPetFoodTypes or GetPetFoodTypes
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
        if obj.CreateMaskTexture then
            local createMask = obj.CreateMaskTexture
            function obj:CreateMaskTexture(...) return PatchRegion(createMask(self, ...)) end
        else
            function obj:CreateMaskTexture(...) local t = self:CreateTexture(); t:Hide(); return t end
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
                            local _, token = UnitPowerType(unit); fn(frame, logical, unit, token)
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
    local index = UnitInRaid(unit)
    if index then local _, rank = GetRaidRosterInfo(index); return rank end
end
W.UnitIsGroupLeader = UnitIsGroupLeader or function(unit)
    return RaidRank(unit) == 2 or UnitIsPartyLeader(unit)
end
W.UnitIsGroupAssistant = UnitIsGroupAssistant or function(unit) return RaidRank(unit) == 1 end
