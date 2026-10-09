-- Player cast bar and GCD bar.
local _, ns = ...
local E = EllesmereUI
if not E or not ns.NewBar then return end
local WHITE = ns.WHITE
local max, min, format = math.max, math.min, string.format
local SPARK = "Interface\\CastingBar\\UI-CastingBar-Spark"
local C = {}
ns.CastPart = C

local function Spark(bar)
    local s = bar.over:CreateTexture(nil, "OVERLAY")
    s:SetTexture(SPARK); s:SetBlendMode("ADD"); s:Hide()
    bar._spark = s
    bar._onRender = function(self, frac, size)
        local sp = self._spark
        if not self._sparkOn or frac <= 0 or frac >= 1 then sp:Hide(); return end
        sp:ClearAllPoints()
        local o = self._orient
        if o == "VERTICAL_UP" or o == "VERTICAL_DOWN" then
            ns.Size(sp, self:GetWidth() * 2.2, 20)
            sp:SetPoint("CENTER", self, o == "VERTICAL_UP" and "BOTTOM" or "TOP", 0, o == "VERTICAL_UP" and size or -size)
        else
            ns.Size(sp, 20, self:GetHeight() * 2.2)
            sp:SetPoint("CENTER", self, self._reverse and "RIGHT" or "LEFT", self._reverse and -size or size, 0)
        end
        sp:Show()
    end
    return s
end
ns.AddSpark = Spark
local function Side(fs, bar, side, x, y)
    fs:ClearAllPoints()
    if side == "center" then fs:SetPoint("CENTER", bar, "CENTER", x or 0, y or 0); fs:SetJustifyH("CENTER")
    elseif side == "right" then fs:SetPoint("RIGHT", bar, "RIGHT", -4 + (x or 0), y or 0); fs:SetJustifyH("RIGHT")
    else fs:SetPoint("LEFT", bar, "LEFT", 4 + (x or 0), y or 0); fs:SetJustifyH("LEFT") end
end

--------------------------------------------------------------------------------
-- Cast bar
--------------------------------------------------------------------------------
local state = { mode = nil }
C.state = state
function C.LayoutCast(p)
    local c = p.castBar
    local f = ns.frames.castBar
    if not f then
        f = CreateFrame("Frame", "ERB_CastBar", UIParent); f._erbKey = "castBar"
        f.icon = f:CreateTexture(nil, "ARTWORK"); f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        f.divider = f:CreateTexture(nil, "OVERLAY"); f.divider:SetTexture(WHITE)
        f.bar = ns.NewBar(f)
        Spark(f.bar)
        f.latency = f.bar:CreateTexture(nil, "BORDER"); f.latency:SetTexture(WHITE); f.latency:Hide()
        f.latencyFront = f.bar.over:CreateTexture(nil, "ARTWORK"); f.latencyFront:SetTexture(WHITE); f.latencyFront:Hide()
        f.spell = f.bar.text
        f.timer = f.bar.over:CreateFontString(nil, "OVERLAY")
        ns.frames.castBar = f
    end
    local w, h = c.width or 220, c.height or 20
    ns.Size(f, w, h)
    f:SetFrameStrata(c.frameStrata or "MEDIUM")
    local iconW = c.showIcon and h or 0
    f.icon:ClearAllPoints(); f.bar:ClearAllPoints(); f.divider:ClearAllPoints()
    if iconW > 0 then
        ns.Size(f.icon, iconW, h)
        f.icon:SetPoint(c.iconOnRight and "RIGHT" or "LEFT", f, c.iconOnRight and "RIGHT" or "LEFT", 0, 0); f.icon:Show()
    else f.icon:Hide() end
    if c.iconOnRight then f.bar:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0); f.bar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -iconW, 0)
    else f.bar:SetPoint("TOPLEFT", f, "TOPLEFT", iconW, 0); f.bar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0) end
    ns.Size(f.bar, max(1, w - iconW), h)
    if iconW > 0 and c.showIconDivider then
        local px = max(1, c.borderSize or 1) * ns.Pixel()
        f.divider:SetVertexColor(c.borderR or 0, c.borderG or 0, c.borderB or 0, c.borderA or 1)
        f.divider:SetWidth(px); f.divider:SetPoint("TOP", f.bar, c.iconOnRight and "TOPRIGHT" or "TOPLEFT", 0, 0)
        f.divider:SetPoint("BOTTOM", f.bar, c.iconOnRight and "BOTTOMRIGHT" or "BOTTOMLEFT", 0, 0); f.divider:Show()
    else f.divider:Hide() end
    local bar = f.bar
    bar:SetStatusBarTexture(ns.Texture(c.texture))
    bar.bg:SetTexture(WHITE); bar.bg:SetVertexColor(c.bgR or 0, c.bgG or 0, c.bgB or 0, c.bgA or 0.7)
    bar._bgEmpty = (c.fillOpacity or 100) < 100
    if not bar._bgEmpty then bar.bg:ClearAllPoints(); bar.bg:SetAllPoints(bar) end
    bar._sparkOn = c.showSpark and true or false
    bar:SetFillOrientation("HORIZONTAL", false)
    ns.Font(f.spell, c.spellTextSize or 11); ns.Font(f.timer, c.timerSize or 11)
    f.spell:SetTextColor(c.spellTextR or 1, c.spellTextG or 1, c.spellTextB or 1, c.spellTextA or 1)
    f.timer:SetTextColor(c.timerR or 1, c.timerG or 1, c.timerB or 1, c.timerA or 1)
    Side(f.spell, bar, c.spellTextSide or "left", c.spellTextX, c.spellTextY)
    Side(f.timer, bar, c.timerSide or "right", c.timerX, c.timerY)
    if c.showSpellText then f.spell:Show() else f.spell:Hide() end
    if c.showTimer then f.timer:Show() else f.timer:Hide() end
    for _,overlay in ipairs({f.latency,f.latencyFront}) do overlay:SetVertexColor(c.latencyR or 0.835, c.latencyG or 0.29, c.latencyB or 0.29, (c.latencyA or 1) * 0.6) end
    ns.ApplyBorder(f, c, c.useClassicStyle)
    ns.Position("castBar")
    C.HideNative(p.enabled and c.enabled)
    C.ReadCast()
end

-- Native CastingBarFrame: kept transparent while ours is enabled, restored after.
local native = {}
function C.HideNative(hide)
    local cb = _G.CastingBarFrame
    if not cb then return end
    if not native.hooked then
        native.alpha = cb:GetAlpha(); native.hooked = true
        hooksecurefunc(cb, "SetAlpha", function(self, a)
            if native.hidden and a ~= 0 and not native.busy then native.busy = true; self:SetAlpha(0); native.busy = nil end
        end)
        cb:HookScript("OnShow", function(self) if native.hidden then native.busy = true; self:SetAlpha(0); native.busy = nil end end)
    end
    if hide and not native.hidden then
        native.hidden = true; native.busy = true; cb:SetAlpha(0); native.busy = nil
    elseif not hide and native.hidden then
        native.hidden = nil; native.busy = true; cb:SetAlpha(native.alpha or 1); native.busy = nil
    end
end

local function Latency()
    if not GetNetStats then return 0 end
    local _, _, home, world = GetNetStats()
    local lat=tonumber(world) or 0
    if lat<=0 then lat=tonumber(home) or 0 end
    return max(0,lat) / 1000
end
function C.ReadCast()
    local name, _, text, icon, startMS, endMS, _, _, notInt = UnitCastingInfo("player")
    local mode = "cast"
    if not name then
        -- Wrath's third channel return is the literal "Channeling", not the spell.
        local cn, _, _, ci, cs, ce, _, cni = UnitChannelInfo("player")
        name, text, icon, startMS, endMS, notInt, mode = cn, cn, ci, cs, ce, cni, "channel"
    end
    if name and startMS and endMS then
        local start, finish = startMS / 1000, endMS / 1000
        if state.mode ~= mode or state.name ~= name or state.start ~= start then state.lat = nil end
        state.mode, state.name, state.text, state.icon, state.start, state.finish = mode, name, text or name, icon, start, finish
        state.notInterruptible, state.failedUntil = notInt and true or false, nil
        if mode == "channel" then
            state.ticks = E.WrathChannelTicks and E.WrathChannelTicks.Schedule(name, start, finish, state.ticks, nil, false) or nil
        else state.ticks = nil end
        if state.lat==nil then state.lat = Latency() end
        state.sentAt = nil
    elseif not state.failedUntil then
        state.mode = nil
    end
    C.UpdateCast()
end
function C.Failed(label)
    if not state.mode or UnitCastingInfo("player") or UnitChannelInfo("player") then return end
    state.failedUntil = GetTime() + 0.6
    state.failedText = label
    C.UpdateCast()
end
local function TickColors(bar, c)
    local ticks = bar._euiChannelTicks
    if not ticks then return end
    local last
    for _, t in ipairs(ticks) do
        if t:IsShown() then t:SetVertexColor(c.tickMarksR or 1, c.tickMarksG or 1, c.tickMarksB or 1, c.tickMarksA or 0.7); last = t end
    end
    if last and c.showLastTick then last:SetVertexColor(c.lastTickR or 1, c.lastTickG or 0.82, c.lastTickB or 0, c.lastTickA or 0.95) end
end
function C.UpdateCast()
    local p = ns.GetSettings(); local f = ns.frames.castBar
    if not p or not f then return end
    local c = p.castBar
    local bar, now = f.bar, GetTime()
    local r, g, b
    if c.classColored then r, g, b = ns.ClassRGB() else r, g, b = c.fillR or 0.9, c.fillG or 0.73, c.fillB or 0.27 end
    local alpha = (c.fillA or 1) * ((c.fillOpacity or 100) / 100)
    if state.failedUntil and now >= state.failedUntil then state.failedUntil = nil; state.mode = nil end
    local mode = state.mode
    if not mode and ns.preview then
        bar:SetMinMaxValues(0, 1); bar:SetValue(0.6, true); bar:Paint(r, g, b, alpha, c)
        f.spell:SetText("Cast Bar"); f.timer:SetText("1.2"); f.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        f.latency:Hide(); f.latencyFront:Hide(); if E.WrathChannelTicks then E.WrathChannelTicks.Hide(bar) end
        return
    end
    if not mode then
        bar:SetMinMaxValues(0, 1); bar:SetValue(0, true); f.spell:SetText(""); f.timer:SetText(""); f.latency:Hide(); f.latencyFront:Hide()
        if E.WrathChannelTicks then E.WrathChannelTicks.Hide(bar) end
        return
    end
    local duration = max(0.001, state.finish - state.start)
    if state.failedUntil then
        bar:SetMinMaxValues(0, 1); bar:SetValue(1, true)
        bar:Paint(c.failedR or 0.85, c.failedG or 0.2, c.failedB or 0.2, alpha)
        f.spell:SetText(state.failedText or ""); f.timer:SetText(""); f.latency:Hide(); f.latencyFront:Hide()
        if E.WrathChannelTicks then E.WrathChannelTicks.Hide(bar) end
        return
    end
    local elapsed = max(0, min(duration, now - state.start))
    local value = mode == "channel" and (duration - elapsed) or elapsed
    bar:SetMinMaxValues(0, duration); bar:SetValue(value, true)
    if state.notInterruptible and c.uninterruptibleColored then
        bar:Paint(c.uninterruptibleR or 0.6, c.uninterruptibleG or 0.6, c.uninterruptibleB or 0.6, alpha)
    else bar:Paint(r, g, b, alpha, c) end
    f.icon:SetTexture(state.icon)
    f.spell:SetText(state.text or "")
    local remaining = max(0, duration - elapsed)
    local timer = format("%.1f", remaining)
    if c.showTotalDuration then timer = timer .. format(" / %.1f", duration) end
    local lat = state.lat
    local overlay=mode=="channel" and f.latencyFront or f.latency
    if mode=="channel" then f.latency:Hide() else f.latencyFront:Hide() end
    if c.latencyEnabled and lat and lat > 0 then
        local frac = min(1, lat / duration)
        overlay:ClearAllPoints()
        overlay:SetWidth(max(1, bar:GetWidth() * frac))
        local anchor = mode == "channel" and "LEFT" or "RIGHT"
        overlay:SetPoint("TOP" .. anchor, bar, "TOP" .. anchor, 0, 0); overlay:SetPoint("BOTTOM" .. anchor, bar, "BOTTOM" .. anchor, 0, 0)
        overlay:Show()
        if c.latencyShowText then timer = timer .. format(" (%dms)", lat * 1000 + 0.5) end
    else f.latency:Hide(); f.latencyFront:Hide() end
    f.timer:SetText(timer)
    if E.WrathChannelTicks then
        E.WrathChannelTicks.Draw(bar, state.ticks, state.start, state.finish, mode == "channel" and c.showChannelTicks and c.showTickMarks)
        TickColors(bar, c)
    end
end
local function CastVisible(p)
    local f = ns.frames.castBar; if not f then return end
    local c = p.castBar
    if not p.enabled or not c.enabled then ns.SetVisible(f, nil, c); return end
    ns.SetVisible(f, (state.mode or c.alwaysShow) and true or false, c)
end

--------------------------------------------------------------------------------
-- GCD bar
--------------------------------------------------------------------------------
local GCD_REFERENCE = { WARRIOR = 6673, ROGUE = 1752, MAGE = 168, PRIEST = 1243, WARLOCK = 687, HUNTER = 2973, DRUID = 1126,
    SHAMAN = 403, PALADIN = 635, DEATHKNIGHT = 47541 }
local gcd = {}
C.gcd = gcd
function C.ReadGCD()
    local start, duration = GetSpellCooldown(61304)
    if not start then
        local ref = GCD_REFERENCE[ns.class]
        local refName = ref and GetSpellInfo(ref)
        if refName then start, duration = GetSpellCooldown(refName) end
    end
    start, duration = tonumber(start) or 0, tonumber(duration) or 0
    if duration > 0 and duration <= 1.7 then gcd.start, gcd.duration = start, duration
    elseif not gcd.start or GetTime() >= gcd.start + gcd.duration then gcd.start, gcd.duration = nil, nil end
end
function C.LayoutGCD(p)
    local c = p.gcdBar
    local f = ns.frames.gcdBar
    if not f then f = ns.NewBar(UIParent, "ERB_GCDBar"); f._erbKey = "gcdBar"; Spark(f); ns.frames.gcdBar = f end
    local vertical = c.orientation == "VERTICAL" or c.orientation == "VERTICAL_UP" or c.orientation == "VERTICAL_DOWN"
    f._erbVertical = vertical
    local w, h = c.width or 220, c.height or 12
    if vertical then w, h = h, w end
    ns.Size(f, w, h)
    f:SetFrameStrata(c.frameStrata or "MEDIUM")
    f:SetStatusBarTexture(ns.Texture(c.texture))
    f.bg:SetTexture(WHITE); f.bg:SetVertexColor(c.bgR or 0, c.bgG or 0, c.bgB or 0, c.bgA or 0.7)
    f._sparkOn = c.showSpark and true or false
    f:SetFillOrientation(vertical and (c.orientation == "VERTICAL_DOWN" and "VERTICAL_DOWN" or "VERTICAL_UP") or "HORIZONTAL", false)
    f.text:SetText("")
    ns.ApplyBorder(f, c, false)
    ns.Position("gcdBar")
end
function C.UpdateGCD()
    local p = ns.GetSettings(); local f = ns.frames.gcdBar
    if not p or not f then return end
    local c = p.gcdBar
    local r, g, b
    if c.classColored then r, g, b = ns.ClassRGB() else r, g, b = c.fillR or 0.27, c.fillG or 0.73, c.fillB or 0.9 end
    f:Paint(r, g, b, c.fillA or 1, c)
    f:SetMinMaxValues(0, 1)
    if gcd.start then
        local frac = max(0, min(1, (GetTime() - gcd.start) / gcd.duration))
        f:SetValue(c.depleteFill and (1 - frac) or frac, true)
    else
        f:SetValue(ns.preview and 0.5 or 0, true)
    end
end
local function GCDVisible(p)
    local f = ns.frames.gcdBar; if not f then return end
    local c = p.gcdBar
    if not p.enabled or not c.enabled then ns.SetVisible(f, nil, c); return end
    local active = gcd.start ~= nil
    if active and c.instantOnly and state.mode then active = false end
    if c.instanceOnly and not ns.preview then
        local inInstance, kind = IsInInstance()
        if not inInstance or kind == "pvp" or kind == "arena" then ns.SetVisible(f, nil, c); return end
    end
    ns.SetVisible(f, (active or c.alwaysShow) and true or false, c)
end

ns.RegisterPart("castBar", C.LayoutCast, C.UpdateCast)
ns.RegisterPart("gcdBar", C.LayoutGCD, C.UpdateGCD)
ns.RegisterVisibility(CastVisible)
ns.RegisterVisibility(GCDVisible)

ns.AfterEnable(function()
    local function Cast(_, unit)
        if unit ~= "player" then return end
        C.ReadCast(); ns.UpdateVisibility()
    end
    for _, ev in ipairs({ "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_STOP",
        "UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_INTERRUPTIBLE",
        "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" }) do ns.On(ev, Cast) end
    ns.On("UNIT_SPELLCAST_SENT", function(_, unit) if unit == "player" then state.sentAt = GetTime() end end)
    ns.On("UNIT_SPELLCAST_FAILED", function(_, unit) if unit == "player" then C.Failed(FAILED or "Failed"); ns.UpdateVisibility() end end)
    ns.On("UNIT_SPELLCAST_INTERRUPTED", function(_, unit) if unit == "player" then C.Failed(INTERRUPTED or "Interrupted"); ns.UpdateVisibility() end end)
    ns.On("SPELL_UPDATE_COOLDOWN", function() C.ReadGCD(); C.UpdateGCD(); ns.UpdateVisibility() end)
    ns.On("ACTIONBAR_UPDATE_COOLDOWN", function() C.ReadGCD(); C.UpdateGCD(); ns.UpdateVisibility() end)
    ns.OnFrame(function()
        local p = ns.GetSettings()
        if p.castBar.enabled and (state.mode or state.failedUntil) then
            local was = state.mode
            C.UpdateCast()
            if was and not state.mode then ns.UpdateVisibility() end
        end
        if p.gcdBar.enabled and gcd.start then
            if GetTime() >= gcd.start + gcd.duration then gcd.start, gcd.duration = nil, nil; C.UpdateGCD(); ns.UpdateVisibility()
            else C.UpdateGCD() end
        end
    end)
end)
