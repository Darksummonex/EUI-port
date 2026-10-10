-- Incoming heals on the player, target and focus health bars. Retail builds
-- them on the HealthPrediction absorb element, which Wrath never gets; the
-- amounts come from LibHealComm-4.0 (bundled; LibStub keeps one copy shared
-- with Raid Frames). Reads the Retail keys (healPrediction, healPredOpacity,
-- healPredColor, healPredOtherColor, healPredTexture, healPredOverheal).
-- Wrath cannot clip, so each segment is sized to the room it has instead.
local _, ns = ...
local HealComm = LibStub and LibStub("LibHealComm-4.0", true)
if not HealComm then return end

local WHITE = "Interface\\Buttons\\WHITE8X8"
local UNITS = { player = true, target = true, focus = true }
local WINDOW = 4
local tracked = {}
local owner = {}

local function Settings(unit)
    local p = (ns.db and ns.db.profile) or (ns.UF_GetProfile and ns.UF_GetProfile())
    local s = p and p[unit]
    if s and s.healPrediction == true then return s end
end

local function TexturePath(bar, s)
    local key = s.healPredTexture or "health"
    if key == "health" then
        local fill = bar:GetStatusBarTexture()
        return fill and fill:GetTexture() or WHITE
    elseif key ~= "flat" then
        return EllesmereUI.ResolveTexturePath(ns.healthBarTextures, key, nil) or WHITE
    end
    return WHITE
end

-- Your heals and everyone else's, scaled by the target's healing modifier.
function ns.UF_WrathIncomingHeals(unit)
    local guid = UnitGUID(unit)
    if not guid then return 0, 0 end
    local t = GetTime() + WINDOW
    local mod = HealComm:GetHealModifier(guid) or 1
    local mine = HealComm:GetHealAmount(guid, HealComm.ALL_HEALS, t, UnitGUID("player")) or 0
    local others = HealComm:GetOthersHealAmount(guid, HealComm.ALL_HEALS, t) or 0
    return mine * mod, others * mod
end

-- One segment starting `from` value units into the bar, `amount` long.
local function Place(tex, bar, vertical, size, range, from, amount)
    if amount <= 0 then tex:Hide(); return from end
    local offset, length = size * from / range, size * amount / range
    tex:ClearAllPoints()
    if vertical then
        tex:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, offset)
        tex:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, offset)
        tex:SetHeight(length)
        tex:SetTexCoord(0, 1, 0, 1)
    else
        tex:SetPoint("TOPLEFT", bar, "TOPLEFT", offset, 0)
        tex:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", offset, 0)
        tex:SetWidth(length)
        tex:SetTexCoord(math.min(1, from / range), math.min(1, (from + amount) / range), 0, 1)
    end
    tex:Show()
    return from + amount
end

local function Hide(o) o.my:Hide(); o.other:Hide() end

local function Paint(frame)
    local o, unit = frame._euiWrathHealPred, tracked[frame]
    if not o then return end
    local s = unit and Settings(unit)
    if not s or not frame:IsShown() or not UnitExists(unit) then Hide(o); return end
    local bar = frame.Health
    local minV, maxV = bar:GetMinMaxValues()
    local range = (maxV or 0) - (minV or 0)
    local vertical = bar.GetOrientation and bar:GetOrientation() == "VERTICAL"
    local size = vertical and bar:GetHeight() or bar:GetWidth()
    if range <= 0 or not size or size <= 0 then Hide(o); return end
    local mine, others = ns.UF_WrathIncomingHeals(unit)
    if mine + others <= 0 then Hide(o); return end
    local filled = math.max(0, math.min(range, (bar:GetValue() or 0) - minV))
    local room = range - filled + range * math.max(0, tonumber(s.healPredOverheal) or 0) / 100
    mine = math.min(mine, room)
    others = math.min(others, room - mine)
    local path = TexturePath(bar, s)
    if o.path ~= path then o.path = path; o.my:SetTexture(path); o.other:SetTexture(path) end
    local alpha = (s.healPredOpacity or 60) / 100
    local mc = s.healPredColor or ns.UF_HEAL_PRED_MY
    local oc = s.healPredOtherColor or ns.UF_HEAL_PRED_OTHER
    o.my:SetVertexColor(mc.r, mc.g, mc.b, alpha)
    o.other:SetVertexColor(oc.r, oc.g, oc.b, alpha)
    local at = Place(o.my, bar, vertical, size, range, filled, mine)
    Place(o.other, bar, vertical, size, range, at, others)
end

local function RefreshAll()
    for frame in pairs(tracked) do Paint(frame) end
end
ns.UF_WrathHealPredRefresh = RefreshAll

local function RefreshGUID(guid)
    for frame, unit in pairs(tracked) do
        if UnitGUID(unit) == guid then Paint(frame) end
    end
end

local function Attach(frame, unit)
    if not frame or not UNITS[unit] or not frame.Health or frame._euiWrathHealPred then return end
    local bar = frame.Health
    frame._euiWrathHealPred = { my = bar:CreateTexture(nil, "ARTWORK"), other = bar:CreateTexture(nil, "ARTWORK") }
    Hide(frame._euiWrathHealPred)
    tracked[frame] = unit
    local function Repaint() Paint(frame) end
    bar:HookScript("OnValueChanged", Repaint)
    bar:HookScript("OnSizeChanged", Repaint)
    frame:HookScript("OnShow", Repaint)
end

local attach = ns.UF_AttachEngineFrame
if attach then
    ns.UF_AttachEngineFrame = function(frame, unit, ...)
        attach(frame, unit, ...)
        Attach(frame, unit)
    end
end

local reload = ns.UF_ReloadAllAuraContainers
ns.UF_ReloadAllAuraContainers = function(...)
    if reload then reload(...) end
    RefreshAll()
end

local function Cast(_, _, _, _, _, ...)
    for i = 1, select("#", ...) do RefreshGUID((select(i, ...))) end
end
for _, event in ipairs({ "HealComm_HealStarted", "HealComm_HealUpdated", "HealComm_HealDelayed", "HealComm_HealStopped" }) do
    HealComm.RegisterCallback(owner, event, Cast)
end
HealComm.RegisterCallback(owner, "HealComm_ModifierChanged", function(_, guid) RefreshGUID(guid) end)
HealComm.RegisterCallback(owner, "HealComm_GUIDDisappeared", function(_, guid) RefreshGUID(guid) end)

local ev = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED", "UNIT_MAXHEALTH" }) do
    ev:RegisterEvent(event)
end
ev:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_MAXHEALTH" and not UNITS[unit] then return end
    RefreshAll()
end)
