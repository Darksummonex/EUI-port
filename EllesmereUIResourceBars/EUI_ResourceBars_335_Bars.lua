-- Health, power (with druid mana while shapeshifted) and class resource bars.
local _, ns = ...
local E = EllesmereUI
if not E or not ns.NewBar then return end
local WHITE, CLASS = ns.WHITE, ns.class
local max, min, floor, ceil, format = math.max, math.min, math.floor, math.ceil, string.format
local B = {}
ns.BarsPart = B

local function TextPoint(f, c)
    local a = c.textAnchor or "CENTER"
    local pad = (a == "LEFT" and 4) or (a == "RIGHT" and -4) or 0
    f.text:ClearAllPoints()
    f.text:SetPoint(a, f, a, pad + (c.textXOffset or 0), c.textYOffset or 0)
    f.text:SetJustifyH(a)
end
-- Shared health/power styling (size, orientation, texture, bg, border, text).
function B.StyleBar(f, key, c, p)
    local vertical = c.orientation == "VERTICAL_UP" or c.orientation == "VERTICAL_DOWN"
    local w, h = c.width or 214, c.height or 16
    if vertical then w, h = h, w end
    f._erbVertical = vertical
    ns.Size(f, w, h)
    f:SetFrameStrata(p.general.frameStrata or "MEDIUM")
    f._smooth = c.smoothBars and true or false
    f:SetStatusBarTexture(ns.BarTexture(key))
    f.bg:SetTexture(WHITE)
    f.bg:SetVertexColor(c.bgR or 0.067, c.bgG or 0.067, c.bgB or 0.067, c.bgA or 0.75)
    local opacity = (c.fillOpacity or 100) / 100
    f._fillAlpha = opacity
    f._bgEmpty = opacity < 1
    if not f._bgEmpty then f.bg:ClearAllPoints(); f.bg:SetAllPoints(f) end
    f:SetFillOrientation(c.orientation or "HORIZONTAL", false)
    ns.ApplyBorder(f, c, p.useClassicStyleBars)
    ns.Font(f.text, c.textSize or 11)
    TextPoint(f, c)
end

--------------------------------------------------------------------------------
-- Health
--------------------------------------------------------------------------------
local function HealthText(fmt, cur, mx)
    local pct = mx > 0 and floor(cur / mx * 100 + 0.5) or 0
    if fmt == "perhp" then return pct .. "%" end
    if fmt == "perhpnosign" then return tostring(pct) end
    if fmt == "curhpshort" then return ns.Short(cur) end
    if fmt == "perhpnum" then return pct .. "% | " .. ns.Short(cur) end
    if fmt == "both" then return ns.Short(cur) .. " | " .. pct .. "%" end
    return ""
end
B.HealthText = HealthText
function B.LayoutHealth(p)
    local c = p.health
    local f = ns.frames.health
    if not f then f = ns.NewBar(UIParent, "ERB_HealthBar"); f._erbKey = "health"; ns.frames.health = f end
    B.StyleBar(f, "health", c, p)
    ns.Position("health")
end
function B.UpdateHealth()
    local p = ns.GetSettings(); local f = ns.frames.health
    if not p or not f then return end
    local c = p.health
    local cur, mx = UnitHealth("player") or 0, UnitHealthMax("player") or 1
    if ns.preview and mx <= 1 then cur, mx = 75, 100 end
    f:SetMinMaxValues(0, max(1, mx)); f:SetValue(cur)
    local r, g, b
    if c.customColored then r, g, b = c.fillR or 1, c.fillG or 1, c.fillB or 1 else r, g, b = ns.ClassRGB() end
    local tr, tg, tb, hit = ns.ThresholdColor(c, cur, mx, r, g, b, false)
    if hit and not c.thresholdTextInstead then r, g, b = tr, tg, tb end
    f:Paint(r, g, b, f._fillAlpha or 1, (not hit) and c or nil)
    ns.ApplyHashLines(f, c, mx)
    local txt = HealthText(c.textFormat, cur, mx)
    f.text:SetText(txt)
    if hit and c.thresholdTextInstead then f.text:SetTextColor(tr, tg, tb, 1)
    elseif c.textCustomColored == false then f.text:SetTextColor(r, g, b, 1)
    else f.text:SetTextColor(c.textFillR or 1, c.textFillG or 1, c.textFillB or 1, c.textFillA or 1) end
end

--------------------------------------------------------------------------------
-- Power (mana/rage/energy/runic power by numeric type)
--------------------------------------------------------------------------------
local function PowerText(c, cur, mx, powerType)
    local fmt = c.textFormat or "none"
    if fmt == "none" then return "" end
    local pctText = (mx > 0 and floor(cur / mx * 100 + 0.5) or 0) .. ((c.showPercent == false) and "" or "%")
    if fmt == "smart" then return powerType == 0 and pctText or ns.Short(cur) end
    if fmt == "both" then return ns.Short(cur) .. " | " .. pctText end
    if fmt == "perpp" then return pctText end
    return ns.Short(cur)
end
B.PowerText = PowerText
function B.LayoutPower(p)
    local c = p.primary
    local f = ns.frames.primary
    if not f then f = ns.NewBar(UIParent, "ERB_PrimaryBar"); f._erbKey = "primary"; ns.frames.primary = f end
    B.StyleBar(f, "primary", c, p)
    ns.Position("primary")
    local MRS, SCP = E.ManaRegenSpark, E.SpellCostPrediction
    if MRS then
        if c.manaRegenSpark then pcall(MRS.Attach, "erb", f, c.manaRegenSparkMode == "ticks") else pcall(MRS.Detach, "erb") end
    end
    if SCP then
        if c.powerCostPrediction then
            pcall(SCP.Attach, "erb", f, { PowerType = function() return UnitPowerType("player") end,
                Color = function() return c.powerCostR or 0.4, c.powerCostG or 0.7, c.powerCostB or 1 end })
        else pcall(SCP.Detach, "erb") end
    end
    B.LayoutDruidMana(p)
end
function B.UpdatePower()
    local p = ns.GetSettings(); local f = ns.frames.primary
    if not p or not f then return end
    local c = p.primary
    local powerType = UnitPowerType("player") or 0
    local cur, mx = UnitPower("player", powerType) or 0, UnitPowerMax("player", powerType) or 0
    if ns.preview and mx <= 0 then cur, mx = 60, 100 end
    f:SetMinMaxValues(0, max(1, mx)); f:SetValue(cur)
    local r, g, b
    if c.customColored then r, g, b = c.fillR or 1, c.fillG or 1, c.fillB or 1 else r, g, b = ns.PowerRGB(powerType) end
    local tr, tg, tb, hit = ns.ThresholdColor(c, cur, mx, r, g, b, true)
    if hit and not c.thresholdTextInstead then r, g, b = tr, tg, tb end
    f:Paint(r, g, b, f._fillAlpha or 1, (not hit) and c or nil)
    ns.ApplyHashLines(f, c, mx)
    f.text:SetText(PowerText(c, cur, mx, powerType))
    if hit and c.thresholdTextInstead then f.text:SetTextColor(tr, tg, tb, 1)
    elseif c.textCustomColored == false then local pr, pg, pb = ns.PowerRGB(powerType); f.text:SetTextColor(pr, pg, pb, 1)
    else f.text:SetTextColor(c.textFillR or 1, c.textFillG or 1, c.textFillB or 1, c.textFillA or 1) end
    if E.ManaRegenSpark and c.manaRegenSpark then pcall(E.ManaRegenSpark.SetMana, "erb", powerType == 0) end
    B.UpdateDruidMana()
end

-- "Mana Bar while Shapeshifted": a thin mana strip attached to the power bar
-- while a druid's form uses rage or energy.
function B.LayoutDruidMana(p)
    local power = ns.frames.primary
    local d = p.primary.foreverDruidMana
    if CLASS ~= "DRUID" or not d then return end
    local f = ns.frames.druidMana
    if not f then f = ns.NewBar(power, "ERB_DruidManaBar"); ns.frames.druidMana = f end
    f:SetParent(power); f:SetFrameLevel(power:GetFrameLevel() + (d.position == "inside" and 4 or 0))
    f:SetStatusBarTexture(ns.BarTexture("primary"))
    f:SetFillOrientation("HORIZONTAL", false)
    local w = power:GetWidth()
    ns.Size(f, w, max(1, d.height or 6))
    f:ClearAllPoints()
    local gap, ox, oy = d.gap or 2, d.offsetX or 0, d.offsetY or 0
    if d.position == "above" then f:SetPoint("BOTTOM", power, "TOP", ox, gap + oy)
    elseif d.position == "inside" then f:SetPoint("BOTTOM", power, "BOTTOM", ox, oy)
    else f:SetPoint("TOP", power, "BOTTOM", ox, -gap + oy) end
    ns.ApplyBorder(f, p.primary, false)
    ns.Font(f.text, d.textSize or 8)
    TextPoint(f, d)
end
function B.UpdateDruidMana()
    local f = ns.frames.druidMana
    if not f then return end
    local p = ns.GetSettings(); local d = p.primary.foreverDruidMana
    local powerType = UnitPowerType("player")
    local show = d and d.enabled and p.primary.enabled and (powerType ~= 0 or ns.preview)
    if not show then f:Hide(); return end
    local cur, mx = UnitPower("player", 0) or 0, UnitPowerMax("player", 0) or 0
    if mx <= 0 then cur, mx = 1, 1 end
    f:SetMinMaxValues(0, mx); f:SetValue(cur)
    local r, g, b = ns.PowerRGB(0)
    f:Paint(r, g, b, 1)
    f.text:SetText(PowerText(d, cur, mx, 0))
    if d.textCustomColored == false then f.text:SetTextColor(r, g, b, 1) else f.text:SetTextColor(d.textFillR or 1, d.textFillG or 1, d.textFillB or 1, d.textFillA or 1) end
    f:Show()
end

--------------------------------------------------------------------------------
-- Class resource: combo points (rogue, cat druid) and DK runes as pips.
--------------------------------------------------------------------------------
local RUNE_COLORS = { { 1, 0.25, 0.25 }, { 0.25, 1, 0.25 }, { 0.25, 0.85, 1 }, { 0.75, 0.3, 1 } }
local RUNE_SLOTS = { 1, 2, 5, 6, 3, 4 }
B.RUNE_COLORS, B.RUNE_SLOTS = RUNE_COLORS, RUNE_SLOTS
function B.ResourceKind()
    if CLASS == "DEATHKNIGHT" then return "runes" end
    if CLASS == "ROGUE" then return "combo" end
    if CLASS == "DRUID" then return (ns.preview or (GetShapeshiftFormID and GetShapeshiftFormID() == 1)) and "combo" or nil end
    return nil
end
ns.supported = ns.supported or {}
ns.supported.secondary = function() return CLASS == "DEATHKNIGHT" or CLASS == "ROGUE" or CLASS == "DRUID" end

local function NewPip(parent)
    local pip = CreateFrame("Frame", nil, parent)
    pip.bg = pip:CreateTexture(nil, "BACKGROUND"); pip.bg:SetAllPoints(pip); pip.bg:SetTexture(WHITE)
    pip.fill = pip:CreateTexture(nil, "ARTWORK"); pip.fill:SetTexture(WHITE)
    pip.timer = pip:CreateFontString(nil, "OVERLAY"); ns.Font(pip.timer, 9); pip.timer:SetPoint("CENTER", pip, "CENTER", 0, 0)
    return pip
end
function B.LayoutResource(p)
    local c = p.secondary
    local f = ns.frames.secondary
    if not f then
        f = CreateFrame("Frame", "ERB_ClassResourceBar", UIParent); f._erbKey = "secondary"; f.pips = {}
        f.back = f:CreateTexture(nil, "BACKGROUND"); f.back:SetAllPoints(f); f.back:SetTexture(WHITE)
        f.over = CreateFrame("Frame", nil, f); f.over:SetAllPoints(f)
        f.text = f.over:CreateFontString(nil, "OVERLAY"); ns.Font(f.text, 11)
        ns.frames.secondary = f
    end
    local kind = B.ResourceKind() or (CLASS == "DRUID" and "combo")
    local count = kind == "runes" and 6 or 5
    local vertical = (c.pipOrientation or "HORIZONTAL") ~= "HORIZONTAL"
    local long, thick = c.pipWidth or 214, c.pipHeight or 20
    f._erbVertical = vertical
    ns.Size(f, vertical and thick or long, vertical and long or thick)
    f:SetFrameStrata(p.general.frameStrata or "MEDIUM")
    if c.raiseLevel then f:SetFrameLevel(max(f:GetFrameLevel(), 20)) end
    f.over:SetFrameLevel(f:GetFrameLevel() + 6)
    local px = ns.Pixel()
    local spacing = max(0, c.pipSpacing or 1) * px
    local size = (long - spacing * (count - 1)) / count
    local gapOn = c.gapColorEnabled and spacing > 0
    f.back:SetVertexColor(gapOn and (c.gapR or 0) or (c.barBgR or 0), gapOn and (c.gapG or 0) or (c.barBgG or 0), gapOn and (c.gapB or 0) or (c.barBgB or 0),
        gapOn and (c.gapA or 1) or (c.barBgA or 0.5))
    if c.pipBgOnPips and not gapOn then f.back:SetVertexColor(0, 0, 0, 0) end
    local tex = ns.BarTexture("secondary")
    for i = 1, 6 do
        local pip = f.pips[i] or NewPip(f)
        f.pips[i] = pip
        pip:ClearAllPoints()
        if i <= count then
            local off = (i - 1) * (size + spacing)
            if not vertical then ns.Size(pip, size, thick); pip:SetPoint("TOPLEFT", f, "TOPLEFT", off, 0)
            elseif c.pipOrientation == "VERTICAL_DOWN" then ns.Size(pip, thick, size); pip:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -off)
            else ns.Size(pip, thick, size); pip:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, off) end
            pip._vertical = vertical
            pip.fill:SetTexture(tex)
            pip.bg:SetVertexColor(c.bgR or 1, c.bgG or 1, c.bgB or 1, c.bgA or 0.1)
            ns.Font(pip.timer, max(7, floor((c.textSize or 11) * 0.8)))
            pip.timer:SetTextColor(c.textR or 1, c.textG or 1, c.textB or 1, 1)
            if spacing > 0 then ns.ApplyBorder(pip, c, false); pip._erbBorder:Show()
            elseif pip._erbBorder then pip._erbBorder:Hide() end
            pip:Show()
        else
            pip:Hide()
        end
    end
    f._count, f._kind = count, kind
    if spacing <= 0 then ns.ApplyBorder(f, c, p.useClassicStyleBars); f._erbBorder:Show()
    elseif f._erbBorder then f._erbBorder:Hide() end
    ns.Font(f.text, c.textSize or 11)
    f.text:ClearAllPoints()
    local a = c.textAnchor or "CENTER"
    f.text:SetPoint(a, f, a, c.textXOffset or 0, c.textYOffset or 0)
    ns.Position("secondary")
    B.LayoutClassArt(p)
end

-- Partial fill of one pip (runes recharge) in the pip's own direction.
local function FillPip(pip, frac)
    local fill = pip.fill
    fill:ClearAllPoints()
    if frac <= 0 then fill:Hide(); return end
    if pip._vertical then
        fill:SetPoint("BOTTOMLEFT", pip, "BOTTOMLEFT", 0, 0); fill:SetPoint("BOTTOMRIGHT", pip, "BOTTOMRIGHT", 0, 0)
        fill:SetHeight(max(0.01, pip:GetHeight() * frac))
    else
        fill:SetPoint("TOPLEFT", pip, "TOPLEFT", 0, 0); fill:SetPoint("BOTTOMLEFT", pip, "BOTTOMLEFT", 0, 0)
        fill:SetWidth(max(0.01, pip:GetWidth() * frac))
    end
    fill:Show()
end
B.FillPip = FillPip
local function PipColor(c, kind, runeType)
    if c.darkTheme then return 0.6, 0.6, 0.6 end
    if kind == "runes" and runeType and not c.classColored and not c.resourceColored then
        local rc = RUNE_COLORS[runeType] or RUNE_COLORS[1]; return rc[1], rc[2], rc[3]
    end
    if c.resourceColored then return ns.ResourceRGB() end
    if c.classColored then return ns.ClassRGB() end
    return c.fillR or 1, c.fillG or 1, c.fillB or 1
end
local runeOrder = {}
function B.UpdateResource()
    local p = ns.GetSettings(); local f = ns.frames.secondary
    if not p or not f or not f._count then return end
    local c = p.secondary
    local kind = B.ResourceKind()
    if f._kind ~= kind and kind then f._kind = kind; return B.LayoutResource(p) end
    local alpha = (c.fillA or 1) * ((c.fillOpacity or 100) / 100)
    local now = GetTime()
    if kind == "runes" then
        local ready = 0
        for i = 1, 6 do runeOrder[i] = RUNE_SLOTS[i] end
        local starts, durs, oks = {}, {}, {}
        for i = 1, 6 do
            local s, d, ok = GetRuneCooldown(i)
            if ns.preview and not s then s, d, ok = 0, 10, i % 3 ~= 0 end
            starts[i], durs[i], oks[i] = s or 0, d or 0, ok and true or false
            if oks[i] then ready = ready + 1 end
        end
        if c.runeSortReady then
            table.sort(runeOrder, function(a, b)
                if oks[a] ~= oks[b] then return oks[a] end
                local ra, rb = starts[a] + durs[a] - now, starts[b] + durs[b] - now
                if ra ~= rb then return ra < rb end
                return a < b
            end)
        end
        local useThresh = c.thresholdEnabled and ready >= (c.thresholdCount or 3)
        for slot = 1, 6 do
            local rune = runeOrder[slot]
            local pip = f.pips[slot]
            local r, g, b = PipColor(c, kind, GetRuneType and GetRuneType(rune) or 1)
            if useThresh and oks[rune] then r, g, b = c.thresholdR or r, c.thresholdG or g, c.thresholdB or b end
            if oks[rune] then
                pip.fill:SetVertexColor(r, g, b, alpha); FillPip(pip, 1); pip.timer:SetText("")
            elseif c.runesSimple then
                FillPip(pip, 0); pip.timer:SetText("")
            else
                local dur = durs[rune]
                local frac = dur > 0 and max(0, min(1, (now - starts[rune]) / dur)) or 0
                if c.runesCustomRecharge then pip.fill:SetVertexColor(c.runesRechargeR or 0.5, c.runesRechargeG or 0.5, c.runesRechargeB or 0.5, c.runesRechargeA or 1)
                else pip.fill:SetVertexColor(r * 0.75, g * 0.75, b * 0.75, alpha) end
                FillPip(pip, frac)
                local rem = starts[rune] + dur - now
                pip.timer:SetText((c.showText and rem > 0 and rem < 999) and format("%d", ceil(rem)) or "")
            end
        end
        f.text:SetText((c.showText and c.runesSimple) and tostring(ready) or "")
        f.text:SetTextColor(c.textR or 1, c.textG or 1, c.textB or 1, 1)
        return
    end
    local cur = GetComboPoints("player", "target") or 0
    if ns.preview and cur == 0 then cur = 3 end
    local useThresh = c.thresholdEnabled and cur >= (c.thresholdCount or 3)
    if c.thresholdPartialOnly and c.thresholdEnabled then useThresh = cur > 0 and cur < (c.thresholdCount or 3) end
    local r, g, b = PipColor(c, "combo")
    if useThresh and not c.thresholdTextInstead then r, g, b = c.thresholdR or r, c.thresholdG or g, c.thresholdB or b end
    for i = 1, f._count do
        local pip = f.pips[i]
        if i <= cur then pip.fill:SetVertexColor(r, g, b, alpha); FillPip(pip, 1) else FillPip(pip, 0) end
        pip.timer:SetText("")
    end
    f.text:SetText((c.showText and cur > 0) and tostring(cur) or "")
    if useThresh and c.thresholdTextInstead then f.text:SetTextColor(c.thresholdR or 1, c.thresholdG or 1, c.thresholdB or 1, 1)
    else f.text:SetTextColor(c.textR or 1, c.textG or 1, c.textB or 1, 1) end
end

-- "Blizzard Class Resource Art": re-host the stock rune or combo frame on the
-- class resource position instead of the pips.
local artState = {}
function B.ArtFrame()
    if CLASS == "DEATHKNIGHT" then return _G.RuneFrame end
    if CLASS == "ROGUE" or CLASS == "DRUID" then return _G.ComboFrame end
end
function B.LayoutClassArt(p)
    local art, f, c = B.ArtFrame(), ns.frames.secondary, p.secondary
    if not art or not f then return end
    local want = c.blizzardClassArt and c.enabled and p.enabled
    if want then
        if not artState.parent then
            artState.parent = art:GetParent(); artState.scale = art:GetScale()
            artState.points = {}
            for i = 1, art:GetNumPoints() do artState.points[i] = { art:GetPoint(i) } end
        end
        art:SetParent(f); art:ClearAllPoints(); art:SetPoint("CENTER", f, "CENTER", 0, 0)
        art:SetScale(max(0.5, min(2, c.blizzardClassArtScale or 1)))
        for _, pip in ipairs(f.pips) do pip:SetAlpha(0) end
        f.back:SetAlpha(0); f.text:SetAlpha(0)
        if f._erbBorder then f._erbBorder:Hide() end
        f._erbArt = true
    elseif artState.parent then
        art:SetParent(artState.parent); art:ClearAllPoints()
        for _, pt in ipairs(artState.points) do art:SetPoint(unpack(pt)) end
        art:SetScale(artState.scale or 1)
        artState.parent = nil
        for _, pip in ipairs(f.pips) do pip:SetAlpha(1) end
        f.back:SetAlpha(1); f.text:SetAlpha(1)
        f._erbArt = nil
    end
end

local function BarVisible(key, isClass)
    return function(p)
        local f = ns.frames[key]; if not f then return end
        local c = p[key]
        if not p.enabled or not c.enabled or (ns.supported[key] and not ns.supported[key]()) then ns.SetVisible(f, nil, c); return end
        if key == "secondary" and not B.ResourceKind() and not ns.preview then ns.SetVisible(f, nil, c); return end
        if key == "primary" and UnitPowerMax("player", UnitPowerType("player")) <= 0 and not ns.preview then ns.SetVisible(f, nil, c); return end
        local v = ns.ShouldShow(c)
        if v and ns.HiddenByForm(c, isClass) then v = false end
        ns.SetVisible(f, v, c)
    end
end
ns.RegisterPart("health", B.LayoutHealth, B.UpdateHealth)
ns.RegisterPart("primary", B.LayoutPower, B.UpdatePower)
ns.RegisterPart("secondary", B.LayoutResource, B.UpdateResource)
ns.RegisterVisibility(BarVisible("health"))
ns.RegisterVisibility(BarVisible("primary"))
ns.RegisterVisibility(BarVisible("secondary", true))

ns.AfterEnable(function()
    local function Health(_, unit) if unit == "player" then B.UpdateHealth() end end
    local function Power(_, unit) if unit == "player" then B.UpdatePower() end end
    ns.On("UNIT_HEALTH", Health); ns.On("UNIT_MAXHEALTH", Health)
    for _, ev in ipairs({ "UNIT_MANA", "UNIT_RAGE", "UNIT_ENERGY", "UNIT_RUNIC_POWER", "UNIT_FOCUS", "UNIT_MAXMANA", "UNIT_MAXRAGE",
        "UNIT_MAXENERGY", "UNIT_MAXRUNIC_POWER", "UNIT_MAXFOCUS", "UNIT_DISPLAYPOWER" }) do ns.On(ev, Power) end
    ns.On("UNIT_DISPLAYPOWER", function(_, unit) if unit == "player" then ns.UpdateVisibility() end end)
    local function Resource() B.UpdateResource() end
    for _, ev in ipairs({ "UNIT_COMBO_POINTS", "PLAYER_TARGET_CHANGED", "RUNE_POWER_UPDATE", "RUNE_TYPE_UPDATE" }) do ns.On(ev, Resource) end
    -- Energy/rage tick between events; runes animate their recharge.
    ns.OnTick(function()
        B.UpdatePower()
        if CLASS == "DEATHKNIGHT" then B.UpdateResource() end
    end)
end)
