-------------------------------------------------------------------------------
--  EUI_UnitFrames_335_FormBar.lua  (Wrath 3.3.5a, druids only)
--
--  Wrath port of EUI_UnitFrames_ForeverFormBar.lua: Power Type "Mana + Form
--  Power" keeps the player power bar on mana and adds a second bar with the
--  form's own power (Cat Form energy, Bear Form rage). Same keys as Retail:
--  powerTypeOverride.foreverDruid, foreverFormBar, foreverFormTextX/Y.
--  Off = no frames, no events. On: UNIT_DISPLAYPOWER, plus the form power's
--  events while the bar shows.
-------------------------------------------------------------------------------
local _, ns = ...
local EllesmereUI = _G.EllesmereUI
if not (EllesmereUI and EUI_WOW_335) then return end
local _, playerClass = UnitClass("player")
if playerClass ~= "DRUID" then return end

local W = ns.Wrath
local CreateFrame = W.CreateFrame
local MANA = (Enum and Enum.PowerType and Enum.PowerType.Mana) or 0
local WHITE = "Interface\\Buttons\\WHITE8X8"
local UNDER_ART_GAP = 2
local UnitPower, UnitPowerMax, UnitPowerType = UnitPower, UnitPowerMax, UnitPowerType

local evf = CreateFrame("Frame")
local S = { on = false, live = false }
ns.UF_WrathFormBarState = S

local function Pct(pt)
    return W.UnitPowerPercent("player", pt, true, CurveConstants and CurveConstants.ScaleTo100)
end

local function Paint()
    local bar, pt = S.bar, S.pt
    if not (bar and pt) then return end
    bar:SetMinMaxValues(0, math.max(1, UnitPowerMax("player", pt) or 0))
    bar:SetValue(UnitPower("player", pt) or 0)
    local mode = S.text
    if mode == "cur" then
        bar.text:SetFormattedText("%d", UnitPower("player", pt) or 0)
    elseif mode == "pct" then
        bar.text:SetFormattedText(S.fmtPct, Pct(pt) or 0)
    elseif mode == "both" then
        bar.text:SetFormattedText(S.fmtBoth, UnitPower("player", pt) or 0, Pct(pt) or 0)
    end
end

local function Color()
    local s, bar = S.settings, S.bar
    local info = S.token and ns.UF_PowerInfo(S.token)
    local r, g, b = 1, 1, 1
    if info then r, g, b = info.r, info.g, info.b end
    local op = s.powerBarOpacity or 100
    if op <= 1.0 then op = op * 100 end
    bar:SetStatusBarColor(r, g, b, op / 100)
    local tc = s.powerTextColor
    if s.powerPercentTextPowerColor then
        bar.text:SetTextColor(r, g, b)
    elseif tc then
        bar.text:SetTextColor(tc.r, tc.g, tc.b, tc.a or 1)
    else
        bar.text:SetTextColor(1, 1, 1)
    end
    if s.powerBgPowerColored then
        local f = EllesmereUI.GetPowerBgDarkenFactor and EllesmereUI.GetPowerBgDarkenFactor() or 0.25
        bar.bg:SetColorTexture(r * f, g * f, b * f, 1)
    else
        local c = s.customPowerBgColor
        if c then
            bar.bg:SetColorTexture(c.r, c.g, c.b, 1)
        else
            bar.bg:SetColorTexture(17/255, 17/255, 17/255, 1)
        end
    end
end

local function SetLive(on)
    if S.live == on then return end
    S.live = on
    if on then
        evf:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
        evf:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    else
        evf:UnregisterEvent("UNIT_POWER_FREQUENT")
        evf:UnregisterEvent("UNIT_MAXPOWER")
    end
end

local function Sync()
    local bar = S.bar
    if not bar then return end
    local pt, token = UnitPowerType("player")
    local show = S.on and pt ~= MANA
    if show then
        S.pt, S.token = pt, token
        Color()
        Paint()
    end
    SetLive(show)
    bar:SetShown(show)
end

evf:SetScript("OnEvent", function(_, event, _, token)
    if event == "UNIT_DISPLAYPOWER" then
        Sync()
    elseif event == "UNIT_MAXPOWER" or token == S.token then
        Paint()
    end
end)

local function Build(frame)
    local bar = CreateFrame("StatusBar", nil, frame)
    bar:SetStatusBarTexture(WHITE)
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bar.bg = bg
    local bdr = CreateFrame("Frame", nil, bar)
    bdr:SetAllPoints(bar)
    EllesmereUI.PP.CreateBorder(bdr, 0, 0, 0, 1, 1)
    bar.border = bdr
    local tf = CreateFrame("Frame", nil, bar)
    tf:SetAllPoints(bar)
    bar.textFrame = tf
    bar.text = tf:CreateFontString(nil, "OVERLAY")
    bar.text:SetWordWrap(false)
    bar:Hide()
    S.bar = bar
end

local function StyleText(s)
    local fs = S.bar.text
    local pos, fmt = s.powerPercentText or "none", s.powerTextFormat or "perpp"
    if pos == "none" or fmt == "none" then
        S.text = nil
        fs:Hide()
        return
    end
    S.text = (fmt == "curpp" or fmt == "smart") and "cur" or (fmt == "both" and "both") or "pct"
    local sign = (s.powerShowPercent ~= false) and "%%" or ""
    S.fmtPct, S.fmtBoth = "%d" .. sign, "%d | %d" .. sign
    if not (s.powerPercentOutline and EllesmereUI.ApplyTextOutline
        and EllesmereUI.ApplyTextOutline(fs, nil, s.powerPercentSize or 9, s.powerPercentOutline, "unitFrames")) then
        EllesmereUI.ApplyModuleFont(fs, nil, s.powerPercentSize or 9, "unitFrames")
    end
    local ox, oy = s.foreverFormTextX, s.foreverFormTextY
    if ox == nil then ox = s.powerPercentX or 0 end
    if oy == nil then oy = s.powerPercentY or 0 end
    fs:ClearAllPoints()
    if pos == "left" then
        fs:SetJustifyH("LEFT")
        fs:SetPoint("LEFT", S.bar, "LEFT", 2 + ox, oy)
    elseif pos == "right" then
        fs:SetJustifyH("RIGHT")
        fs:SetPoint("RIGHT", S.bar, "RIGHT", -2 + ox, oy)
    else
        fs:SetJustifyH("CENTER")
        fs:SetPoint("CENTER", S.bar, "CENTER", ox, oy)
    end
    fs:Show()
end

local function ArtBottom(G)
    local base = ns.UF_Forever and ns.UF_Forever() and ns.UF_KITS and ns.UF_KITS.blizzard
    local bg = base and ((G == ns.UF_BLIZZ.target) and base.target or base.player)
    return (bg and bg.vis and bg.vis.b) or G.vis.b
end

local function Layout(frame, power, s)
    local bar, PP = S.bar, EllesmereUI.PP
    local pos = s.powerPosition or "below"
    local detached = (pos == "detached_top" or pos == "detached_bottom")
    local G = (not detached) and ns.UF_Blizz and ns.UF_Blizz() and ns.UF_BlizzGeom(frame)
    local bs, c, h
    bar:ClearAllPoints()
    if G and G.power and G.vis and G.h then
        bs, h = 1, G.power.h
        local drop = G.h - ArtBottom(G) - (G.power.y + G.power.h) + UNDER_ART_GAP
        bar:SetPoint("TOPLEFT", power, "BOTTOMLEFT", 0, -drop)
        bar:SetPoint("TOPRIGHT", power, "BOTTOMRIGHT", 0, -drop)
    else
        if detached then
            bs, c = s.powerBorderSize or 0, s.powerBorderColor
        else
            bs, c = s.borderSize or 1, s.borderColor
        end
        h = power:GetHeight()
        local overlap = bs * (PP.mult or 1)
        if pos == "above" or pos == "detached_top" then
            bar:SetPoint("BOTTOMLEFT", power, "TOPLEFT", 0, -overlap)
            bar:SetPoint("BOTTOMRIGHT", power, "TOPRIGHT", 0, -overlap)
        else
            bar:SetPoint("TOPLEFT", power, "BOTTOMLEFT", 0, overlap)
            bar:SetPoint("TOPRIGHT", power, "BOTTOMRIGHT", 0, overlap)
        end
    end
    bar:SetHeight(math.max(1, h or 1))
    local fill = power:GetStatusBarTexture()
    bar:SetStatusBarTexture((fill and fill:GetTexture()) or WHITE)
    bar:SetReverseFill(s.powerReverseFill and true or false)
    if bs > 0 then
        PP.UpdateBorder(bar.border, bs, c and c.r or 0, c and c.g or 0, c and c.b or 0, 1)
        bar.border:Show()
    else
        bar.border:Hide()
    end
end

-- frame: the player frame; power: its power bar; s: the player settings.
function ns.UF_ForeverFormBar(frame, power, s)
    local ov = s and s.powerTypeOverride
    S.on = (power and ov and ov.foreverDruid and s.foreverFormBar
        and ns.UF_PowerBarDraws(s)) and true or false
    if not S.on then
        evf:UnregisterAllEvents()
        S.live = false
        if S.bar then S.bar:Hide() end
        return
    end
    if not S.bar then Build(frame) end
    local bar = S.bar
    if bar:GetParent() ~= frame then bar:SetParent(frame) end
    bar:SetFrameStrata(power:GetFrameStrata())
    bar:SetFrameLevel(power:GetFrameLevel() + 1)
    bar.border:SetFrameLevel(bar:GetFrameLevel() + 5)
    bar.textFrame:SetFrameLevel(bar:GetFrameLevel() + 6)
    S.settings = s
    Layout(frame, power, s)
    StyleText(s)
    evf:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
    Sync()
end
