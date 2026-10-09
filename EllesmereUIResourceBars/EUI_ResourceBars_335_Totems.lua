-- Totem bar (active totems / DK ghoul) and the shaman Call Totem Bar host.
local _, ns = ...
local E = EllesmereUI
if not E or not ns.NewBar then return end
local CLASS = ns.class
local max, min, ceil, format = math.max, math.min, math.ceil, string.format
local T = {}
ns.TotemPart = T
local DISPLAY = { 2, 1, 3, 4 } -- Earth, Fire, Water, Air
local PREVIEW_ICONS = { "Interface\\Icons\\Spell_Fire_SearingTotem", "Interface\\Icons\\Spell_Nature_StoneSkinTotem",
    "Interface\\Icons\\Spell_Frost_SummonWaterElemental", "Interface\\Icons\\Spell_Nature_Windfury" }
T.DISPLAY = DISPLAY

function T.GrowDir()
    local p = ns.GetSettings()
    local c = p and p.totemBar or {}
    local vertical = c.orientation == "VERTICAL"
    local g = c.growDirection
    if vertical then
        if g ~= "UP" and g ~= "DOWN" and g ~= "CENTER" then g = "DOWN" end
    elseif g ~= "LEFT" and g ~= "RIGHT" and g ~= "CENTER" then g = "RIGHT" end
    return g, vertical
end
E.GetTotemGrowDir = T.GrowDir

local function TimerText(rem)
    if rem >= 60 then return format("%dm", ceil(rem / 60)) end
    return format("%d", ceil(rem))
end
local function NewIcon(parent, slot)
    local b = CreateFrame("Frame", nil, parent)
    b.slot = slot
    b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetAllPoints(b); b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.cd = CreateFrame("Cooldown", nil, b); b.cd:SetAllPoints(b)
    if b.cd.SetReverse then b.cd:SetReverse(true) end
    b.over = CreateFrame("Frame", nil, b); b.over:SetAllPoints(b); b.over:SetFrameLevel(b:GetFrameLevel() + 4)
    b.timer = b.over:CreateFontString(nil, "OVERLAY"); b.timer:SetPoint("CENTER", b, "CENTER", 0, 0)
    b:EnableMouse(true)
    b:SetScript("OnEnter", function(self)
        if not GameTooltip or ns.preview then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        if GameTooltip.SetTotem then GameTooltip:SetTotem(self.slot) end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    return b
end
function T.Supported() return CLASS == "SHAMAN" or CLASS == "DEATHKNIGHT" end
ns.supported = ns.supported or {}
ns.supported.totemBar = T.Supported
ns.supported.callTotemBar = function() return CLASS == "SHAMAN" end

function T.Layout(p)
    local c = p.totemBar
    local f = ns.frames.totemBar
    if not f then f = CreateFrame("Frame", "ERB_TotemBar", UIParent); f._erbKey = "totemBar"; f.icons = {}; ns.frames.totemBar = f end
    f:SetFrameStrata(c.frameStrata or "MEDIUM")
    local size, gap = c.iconSize or 30, c.spacing or 2
    local _, vertical = T.GrowDir()
    local long = size * 4 + gap * 3
    ns.Size(f, vertical and size or long, vertical and long or size)
    for slot = 1, 4 do
        local b = f.icons[slot] or NewIcon(f, slot)
        f.icons[slot] = b
        ns.Size(b, size, size)
        ns.Font(b.timer, c.timerSize or 11)
        ns.ApplyBorder(b, c, false)
    end
    T.HideBlizzard(p.enabled and c.hideBlizzard and T.Enabled(p))
    ns.Position("totemBar")
    T.Update()
end
function T.Enabled(p)
    local c = p.totemBar
    return T.Supported() and c.enabledClasses and c.enabledClasses[CLASS] and true or false
end
function T.Update()
    local p = ns.GetSettings(); local f = ns.frames.totemBar
    if not p or not f then return end
    local c = p.totemBar
    local size, gap = c.iconSize or 30, c.spacing or 2
    local dir, vertical = T.GrowDir()
    local now = GetTime()
    local active = {}
    for _, slot in ipairs(DISPLAY) do
        local have, _, start, duration, icon = GetTotemInfo(slot)
        local b = f.icons[slot]
        if have and icon and icon ~= "" and (duration or 0) > 0 and start + duration > now then
            b.icon:SetTexture(icon); b._ends = start + duration
            if b._cdStart ~= start then b._cdStart = start; b.cd:SetCooldown(start, duration) end
            active[#active + 1] = b
        elseif ns.preview then
            b.icon:SetTexture(PREVIEW_ICONS[slot]); b._ends = nil
            if b._cdStart then b._cdStart = nil; b.cd:SetCooldown(0, 0) end
            active[#active + 1] = b
        else
            b._ends, b._cdStart = nil, nil; b:Hide()
        end
    end
    local n = #active
    local span = n * size + max(0, n - 1) * gap
    local total = 4 * size + 3 * gap
    for i, b in ipairs(active) do
        local off = (i - 1) * (size + gap)
        b:ClearAllPoints()
        if vertical then
            if dir == "UP" then b:SetPoint("BOTTOM", f, "BOTTOM", 0, off)
            elseif dir == "CENTER" then b:SetPoint("TOP", f, "TOP", 0, -((total - span) / 2 + off))
            else b:SetPoint("TOP", f, "TOP", 0, -off) end
        else
            if dir == "LEFT" then b:SetPoint("RIGHT", f, "RIGHT", -off, 0)
            elseif dir == "CENTER" then b:SetPoint("LEFT", f, "LEFT", (total - span) / 2 + off, 0)
            else b:SetPoint("LEFT", f, "LEFT", off, 0) end
        end
        b:Show()
        local rem = b._ends and (b._ends - now) or 0
        b.timer:SetText((c.showTimer and rem > 0) and TimerText(rem) or "")
    end
    f._active = n
end
function E.LayoutTotemBar()
    local p = ns.GetSettings()
    if p then T.Layout(p); ns.UpdateVisibility() end
end

-- Stock TotemFrame parked on a hidden parent while ours is enabled.
local hiddenParent = CreateFrame("Frame"); hiddenParent:Hide()
local blizz = {}
function T.HideBlizzard(hide)
    local tf = _G.TotemFrame
    if not tf or InCombatLockdown() then if tf then ns.pending = true end; return end
    if hide and not blizz.parent then
        blizz.parent = tf:GetParent(); tf:SetParent(hiddenParent)
    elseif not hide and blizz.parent then
        tf:SetParent(blizz.parent); blizz.parent = nil
    end
end
local function TotemVisible(p)
    local f = ns.frames.totemBar; if not f then return end
    if not p.enabled or not T.Enabled(p) then ns.SetVisible(f, nil, p.totemBar); return end
    ns.SetVisible(f, (f._active or 0) > 0, p.totemBar)
end

--------------------------------------------------------------------------------
-- Call Totem Bar: the secure MultiCastActionBarFrame pinned to a movable
-- holder, re-pinned out of combat only.
--------------------------------------------------------------------------------
local call = {}
T.call = call
function T.PinCall()
    local bar, holder = _G.MultiCastActionBarFrame, ns.frames.callTotemBar
    if not bar or not holder or not call.active then return end
    if InCombatLockdown() then ns.pending = true; return end
    call.busy = true
    if bar:GetParent() ~= holder then bar:SetParent(holder) end
    bar:ClearAllPoints(); bar:SetPoint("CENTER", holder, "CENTER", 0, 0)
    call.busy = nil
end
function T.LayoutCall(p)
    local c = p.callTotemBar
    local holder = ns.frames.callTotemBar
    if not holder then holder = CreateFrame("Frame", "ERB_CallTotemBar", UIParent); holder._erbKey = "callTotemBar"; ns.frames.callTotemBar = holder end
    local bar = _G.MultiCastActionBarFrame
    -- The holder parents the protected totem buttons, so it can't move in combat either.
    if bar and InCombatLockdown() then ns.pending = true; return end
    local scale = max(0.5, min(2, (c.iconSize or 30) / 30))
    local bw, bh = bar and bar:GetWidth() or 230, bar and bar:GetHeight() or 38
    ns.Size(holder, max(30, bw * scale), max(30, bh * scale))
    ns.Position("callTotemBar")
    local want = p.enabled and c.enabled and CLASS == "SHAMAN" and bar ~= nil
    if not bar then return end
    if not call.hooked then
        call.hooked = true
        hooksecurefunc(bar, "SetPoint", function() if call.active and not call.busy then T.PinCall() end end)
    end
    if want then
        if not call.active then call.parent = bar:GetParent(); call.scale = bar:GetScale() end
        call.active = true
        bar:SetScale(scale)
        T.PinCall()
    elseif call.active then
        call.active = nil
        call.busy = true
        bar:SetParent(call.parent or UIParent); bar:SetScale(call.scale or 1); bar:ClearAllPoints()
        call.busy = nil
        if UIParent_ManageFramePositions then pcall(UIParent_ManageFramePositions) end
    end
end
local function CallVisible(p)
    local holder = ns.frames.callTotemBar; if not holder then return end
    if not p.enabled or not p.callTotemBar.enabled or CLASS ~= "SHAMAN" then holder:Hide(); return end
    holder:Show()
end

ns.RegisterPart("totemBar", T.Layout, T.Update)
ns.RegisterPart("callTotemBar", T.LayoutCall)
ns.RegisterVisibility(TotemVisible)
ns.RegisterVisibility(CallVisible)

ns.AfterEnable(function()
    ns.On("PLAYER_TOTEM_UPDATE", function() T.Update(); ns.UpdateVisibility() end)
    ns.OnTick(function()
        local f = ns.frames.totemBar
        if f and f:IsShown() and (f._active or 0) > 0 then
            local before = f._active
            T.Update()
            if f._active ~= before then ns.UpdateVisibility() end
        end
    end)
end)
