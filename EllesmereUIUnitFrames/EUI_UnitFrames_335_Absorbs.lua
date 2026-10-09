-- Shields on the player, target, focus and boss health bars. Wrath has no
-- absorb API, so Retail's HealthPrediction absorb bar is never built (it
-- needs UnitGetTotalAbsorbs and masks); the amount comes from the Core
-- estimate (EllesmereUI_Absorbs_335.lua) and is drawn by the shared overlay:
-- from the end of the fill, the overshield backfilled over it. Reads the
-- Retail keys (showPlayerAbsorb, absorbOpacity/absorbCleanAlpha, absorbColor,
-- absorbEdgeMode, overshieldMode/showOvershield, boss.showAbsorbs).
local _, ns = ...
local E = EllesmereUI
local A = E and E.Absorbs
if not A or not E.GetUnitAbsorb then return end

local ABSORB_UNITS = { player = true, target = true, focus = true,
    boss1 = true, boss2 = true, boss3 = true, boss4 = true, boss5 = true }
-- Retail Unit Frames draw "Striped" with striped3 stretched across the bar.
local OVERRIDES = { striped = A.STYLES.stripedStretch }
local tracked = {}

local function Profile()
    if ns.db and ns.db.profile then return ns.db.profile end
    return ns.UF_GetProfile and ns.UF_GetProfile()
end

-- Shields default on: one-time switch from the Retail "none" default, which
-- was the only value Wrath could store before the overlay existed.
local function Seed(s)
    if s and not s.wrathAbsorbSeeded then
        if (s.showPlayerAbsorb or "none") == "none" then s.showPlayerAbsorb = "striped" end
        s.wrathAbsorbSeeded = true
    end
end

local function Settings(unit)
    local p = Profile()
    if not p then return end
    if unit:find("^boss") then
        if p.boss and p.boss.showAbsorbs == false then return end
        return p.target
    end
    return p[unit]
end

local function Opacity(style, s)
    if s.absorbOpacity then return s.absorbOpacity / 100 end
    if style == "clean" then return (s.absorbCleanAlpha or 30) / 100 end
    return .8
end
ns.UF_WrathAbsorbOpacity = Opacity

local function OvershieldMode(s)
    return s.overshieldMode or (s.showOvershield == false and "never" or "always")
end

local function PaintWith(o, s, hp, maxHP, absorb, vertical, reverse, w, h)
    local style = s.showPlayerAbsorb or "none"
    local c = s.absorbColor or { r = 1, g = 1, b = 1 }
    A.Paint(o, hp, maxHP, absorb, style, c.r or 1, c.g or 1, c.b or 1, Opacity(style, s),
        s.absorbEdgeMode or "overlay", OvershieldMode(s), vertical, reverse, w, h, ns.healthBarTextures, OVERRIDES)
end

local function Paint(frame)
    local o = frame._euiWrathAbsorb
    local unit = tracked[frame]
    if not o or not unit then return end
    local s = Settings(unit)
    if not s or not frame:IsShown() or not UnitExists(unit) then A.Hide(o); return end
    local bar = frame.Health
    local vertical = bar.GetOrientation and bar:GetOrientation() == "VERTICAL"
    -- The 3.3.5 SetReverseFill shim only stores the flag; the fill stays forward.
    local reverse = bar._eui335Reverse == nil and bar.GetReverseFill and bar:GetReverseFill() and true or false
    PaintWith(o, s, UnitHealth(unit), UnitHealthMax(unit), E.GetUnitAbsorb(unit), vertical, reverse)
end

local function RefreshAll()
    local p = Profile()
    if p then Seed(p.player); Seed(p.target); Seed(p.focus) end
    for frame in pairs(tracked) do Paint(frame) end
end
ns.UF_WrathAbsorbRefresh = RefreshAll

local function Attach(frame, unit)
    if not frame or not ABSORB_UNITS[unit] or not frame.Health or frame._euiWrathAbsorb then return end
    -- A client with the native absorb bar keeps Retail's element.
    if frame.HealthPrediction and frame.HealthPrediction.damageAbsorb then return end
    frame._euiWrathAbsorb = A.CreateOverlay(frame.Health, "OVERLAY")
    tracked[frame] = unit
    local function Repaint() Paint(frame) end
    frame.Health:HookScript("OnValueChanged", Repaint)
    frame.Health:HookScript("OnSizeChanged", Repaint)
    frame:HookScript("OnShow", Repaint)
end

local attach = ns.UF_AttachEngineFrame
if attach then
    ns.UF_AttachEngineFrame = function(frame, unit, ...)
        attach(frame, unit, ...)
        Attach(frame, unit)
    end
end

-- Reload passes (options, profile switch, spec override) restyle the bars.
local reloadAuras = ns.UF_ReloadAllAuraContainers
ns.UF_ReloadAllAuraContainers = function(...)
    if reloadAuras then reloadAuras(...) end
    RefreshAll()
end

E.RegisterAbsorbCallback(ns, function(guid)
    for frame, unit in pairs(tracked) do
        if UnitGUID(unit) == guid then Paint(frame) end
    end
end)

local ev = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED",
    "UNIT_MAXHEALTH", "INSTANCE_ENCOUNTER_ENGAGE_UNIT" }) do
    ev:RegisterEvent(event)
end
ev:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_MAXHEALTH" and not ABSORB_UNITS[unit] then return end
    RefreshAll()
end)

-- Options preview: the same overlay on the preview health bar with a sample
-- shield (fraction of max health), using the edited unit's settings and the
-- preview's own fill direction.
function ns.UF_WrathAbsorbPreview(host, s, w, h, hpFrac, sample)
    if not host then return end
    local o = host._euiWrathAbsorbPreview
    if not o then o = A.CreateOverlay(host, "OVERLAY"); host._euiWrathAbsorbPreview = o end
    if not s or (s.showPlayerAbsorb or "none") == "none" then A.Hide(o); return end
    PaintWith(o, s, (hpFrac or .75) * 100, 100, (sample or .2) * 100,
        s.healthVerticalFill and true or false, s.healthReverseFill and true or false, w, h)
end
