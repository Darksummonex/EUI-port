-- Native Wrath Resource Bars: Retail settings schema, unlock keys and looks
-- rebuilt on legacy widgets. Retail sources stay in the folder, unloaded.
local ADDON_NAME, ns = ...
local E = EllesmereUI
if not E or not E.Lite then return end
E._ModuleNS[ADDON_NAME] = ns
local addon = E.Lite.NewAddon(ADDON_NAME)
ns.addon, ns.ERB, ns.IsWrath = addon, addon, true
local WHITE = "Interface\\Buttons\\WHITE8X8"
local _, CLASS = UnitClass("player")
ns.WHITE, ns.class = WHITE, CLASS
local max, min, floor = math.max, math.min, math.floor

local function Merge(...)
    local t = {}
    for i = 1, select("#", ...) do for k, v in pairs((select(i, ...))) do t[k] = v end end
    return t
end
ns.Merge = Merge
local VIS = { visibility = "always", visOnlyInstances = false, visHideMounted = false, visHideNoTarget = false,
    visHideNoEnemy = false, oocFadeEnabled = false, oocAlpha = 0.5, barAlpha = 1, barDisabledForms = {} }
local BORDER = { borderSize = 1, borderR = 0, borderG = 0, borderB = 0, borderA = 1, borderTexture = "solid", stockBorderScale = 60 }
local BAR = Merge(VIS, BORDER, { smoothBars = false, width = 214, height = 16, customColored = false, fillR = 1, fillG = 1, fillB = 1, fillA = 1,
    fillOpacity = 100, bgR = 0x11 / 255, bgG = 0x11 / 255, bgB = 0x11 / 255, bgA = 0.75, textFormat = "none", textSize = 11,
    textXOffset = 0, textYOffset = 0, textAnchor = "CENTER", textCustomColored = true, textFillR = 1, textFillG = 1, textFillB = 1, textFillA = 1,
    gradientEnabled = false, gradientR = 0.2, gradientG = 0.2, gradientB = 0.8, gradientA = 1, gradientDir = "HORIZONTAL",
    offsetX = 0, orientation = "HORIZONTAL", thresholdEnabled = false, thresholdPct = 30, thresholdR = 1, thresholdG = 0.2,
    thresholdB = 0.2, thresholdA = 1, thresholdTextInstead = false, multiBandEnabled = false, bandMode = "percent",
    bandReverse = false, bands = {}, hashEnabled = false, hashValues = "", hashMode = "percent", hashWidth = 1,
    hashColorR = 1, hashColorG = 1, hashColorB = 1, hashColorA = 0.7 })
local TIMED = Merge(BORDER, { width = 220, anchorX = 0, classColored = false, gradientEnabled = false, gradientR = 0.2, gradientG = 0.2,
    gradientB = 0.8, gradientA = 1, gradientDir = "HORIZONTAL", texture = "none", bgR = 0, bgG = 0, bgB = 0, bgA = 0.7, frameStrata = "MEDIUM" })
local defaults = { profile = {
    enabled = true, font = "__global", splitTex = false, useClassicStyleBars = false,
    general = { anchorX = 0, anchorY = -100, barTexture = "none", frameStrata = "MEDIUM" },
    health = Merge(BAR, { enabled = false, borderSize = 0, offsetY = -75, fillR = 37 / 255, fillG = 193 / 255, fillB = 29 / 255 }),
    primary = Merge(BAR, { enabled = true, height = 14, textFormat = "perpp", showPercent = true, textSize = 10, offsetY = -57,
        thresholdPartialOnly = false, manaRegenSpark = false, manaRegenSparkMode = "fsr", powerCostPrediction = false,
        powerCostR = 0.4, powerCostG = 0.7, powerCostB = 1,
        foreverDruidMana = { enabled = false, position = "below", gap = 2, height = 6, offsetX = 0, offsetY = 0, textFormat = "none",
            showPercent = true, textSize = 8, textXOffset = 0, textYOffset = 0, textAnchor = "CENTER", textCustomColored = true,
            textFillR = 1, textFillG = 1, textFillB = 1, textFillA = 1 } }),
    secondary = Merge(VIS, BORDER, { enabled = true, smoothBars = false, pipWidth = 214, pipHeight = 20, pipSpacing = 1,
        pipOrientation = "HORIZONTAL", pipBgOnPips = false, raiseLevel = false, darkTheme = false, blizzardClassArt = false,
        blizzardClassArtScale = 1, classColored = true, resourceColored = false, fillR = 0.95, fillG = 0.90, fillB = 0.60, fillA = 1,
        fillOpacity = 100, bgR = 1, bgG = 1, bgB = 1, bgA = 0.1, showText = true, textSize = 11, textR = 1, textG = 1, textB = 1,
        textXOffset = 0, textYOffset = 0, textAnchor = "CENTER", barBgR = 0, barBgG = 0, barBgB = 0, barBgA = 0.5,
        gapColorEnabled = false, gapR = 0, gapG = 0, gapB = 0, gapA = 1, thresholdEnabled = false, thresholdCount = 3,
        thresholdPartialOnly = false, thresholdR = 0x0c / 255, thresholdG = 0xd2 / 255, thresholdB = 0x9d / 255, thresholdA = 1,
        thresholdTextInstead = false, multiBandEnabled = false, bandReverse = false, bands = {}, runesSimple = false,
        runesCustomRecharge = false, runesRechargeR = 0.5, runesRechargeG = 0.5, runesRechargeB = 0.5, runesRechargeA = 1,
        runeSortReady = false, offsetX = 0, offsetY = -38 }),
    castBar = Merge(TIMED, { enabled = false, useClassicStyle = false, alwaysShow = false, showIcon = true, iconOnRight = false,
        showIconDivider = false, height = 20, anchorY = -54, fillR = 0.898, fillG = 0.729, fillB = 0.267, fillA = 1, fillOpacity = 100,
        showSpark = true, showTimer = true, timerSize = 11, timerX = 0, timerY = 0, timerSide = "right", timerR = 1, timerG = 1,
        timerB = 1, timerA = 1, showSpellText = true, spellTextSize = 11, spellTextX = 0, spellTextY = 0, spellTextSide = "left",
        spellTextR = 1, spellTextG = 1, spellTextB = 1, spellTextA = 1, showChannelTicks = true, showTickMarks = true,
        tickMarksR = 1, tickMarksG = 1, tickMarksB = 1, tickMarksA = 0.7, showLastTick = false, lastTickR = 1, lastTickG = 0.82,
        lastTickB = 0, lastTickA = 0.95, showTotalDuration = false, latencyEnabled = false, latencyShowText = false,
        latencyR = 0.835, latencyG = 0.290, latencyB = 0.290, latencyA = 1, uninterruptibleColored = true,
        uninterruptibleR = 0.6, uninterruptibleG = 0.6, uninterruptibleB = 0.6, failedR = 0.85, failedG = 0.2, failedB = 0.2 }),
    gcdBar = Merge(TIMED, { enabled = false, height = 12, anchorY = -78, orientation = "HORIZONTAL", fillR = 0.267, fillG = 0.729,
        fillB = 0.898, fillA = 1, showSpark = false, depleteFill = false, instanceOnly = false, instantOnly = false, alwaysShow = false }),
    swingTimer = Merge(TIMED, VIS, { enabled = false, height = 12, rowSpacing = 2, anchorY = -130, mhR = 0.898, mhG = 0.702,
        mhB = 0.267, mhA = 1, ohR = 0.898, ohG = 0.451, ohB = 0.267, ohA = 1, rR = 0.267, rG = 0.729, rB = 0.898, rA = 1,
        showSpark = false, depleteFill = true, idleShowFill = false, hideWhenIdle = false, showTime = true, showLabel = true,
        showMH = true, showOH = true, showR = true, combineHands = false, textSize = 11, rangeCheck = true, outOfRangeAlpha = 0.4,
        queueHighlight = true, queueR = 1, queueG = 0.70, queueB = 0.20, queueA = 1, queueCleaveR = 0.95, queueCleaveG = 0.35,
        queueCleaveB = 0.25, queueCleaveA = 1, visibility = "in_combat" }),
    totemBar = Merge(BORDER, { iconSize = 30, spacing = 2, showTimer = true, timerSize = 11, orientation = "HORIZONTAL", growDirection = "RIGHT",
        frameStrata = "MEDIUM", hideBlizzard = true, enabledClasses = { SHAMAN = true } }),
    callTotemBar = Merge(BORDER, { enabled = false, iconSize = 30, spacing = 2, showTimer = true, timerSize = 11,
        orientation = "HORIZONTAL", fadeArt = true }),
} }
ns.defaults = defaults

-- Bar keys, unlock keys (Retail names) and labels.
ns.BARS = { "health", "primary", "secondary", "castBar", "gcdBar", "swingTimer", "totemBar", "callTotemBar" }
ns.KEYS = { health = "ERB_Health", primary = "ERB_Power", secondary = "ERB_ClassResource", castBar = "ERB_CastBar",
    gcdBar = "ERB_GCDBar", swingTimer = "ERB_SwingTimer", totemBar = "ERB_TotemBar", callTotemBar = "ERB_CallTotemBar" }
ns.LABELS = { health = "Health Bar", primary = "Power Bar", secondary = "Class Resource", castBar = "Cast Bar", gcdBar = "GCD Bar",
    swingTimer = "Swing Timer", totemBar = "Totem Bar", callTotemBar = "Call Totem Bar" }
ns.ORDER = { health = 500, primary = 501, secondary = 502, castBar = 504, totemBar = 505, gcdBar = 506, swingTimer = 507, callTotemBar = 508 }
ns.PAGES = { display = "Class, Power and Health Bars", cast = "Cast Bar", gcd = "GCD Bar", swing = "Swing Timer", totem = "Totem Bar" }
ns.frames = {}

-- Textures: power-of-two TGA copies of Retail's fills.
local textures, names, texOrder = { none = WHITE, blizzard = "Interface\\TargetingFrame\\UI-StatusBar" }, { none = "Solid", blizzard = "Blizzard" }, { "none", "blizzard" }
for _, key in ipairs({ "atrocity", "beautiful", "divide", "fade", "fade-right", "glass", "gradient-bt", "gradient-lr", "gradient-rl",
    "gradient-tb", "matte", "plating", "sheer", "thin-line-bottom", "thin-line-top" }) do
    textures[key] = "Interface\\AddOns\\EllesmereUIResourceBars\\Media\\Textures_335\\" .. key .. ".tga"
    names[key] = key:gsub("-", " "):gsub("^%l", string.upper); texOrder[#texOrder + 1] = key
end
_G._ERB_BarTextures, _G._ERB_BarTextureNames, _G._ERB_BarTextureOrder = textures, names, texOrder
_G._ERB_CastBarTextures, _G._ERB_CastBarTextureNames, _G._ERB_CastBarTextureOrder = textures, names, texOrder
if E.AppendSharedMediaTextures then E.AppendSharedMediaTextures(names, texOrder, nil, textures) end

function ns.GetSettings() return addon.db and addon.db.profile end
function ns.Size(f, w, h) f:SetWidth(max(0.01, w)); f:SetHeight(max(0.01, h)) end
function ns.Texture(key)
    local path = E.ResolveTexturePath(textures, key)
    if path then return path end
    if type(key) == "string" and key:find("\\", 1, true) then return key end
    return WHITE
end
-- The shared key textures every bar; "per bar" gives health and power their own.
function ns.BarTexture(key)
    local p = ns.GetSettings()
    local c = p and key ~= "secondary" and p[key]
    return ns.Texture((p and p.splitTex and c and c.barTexture) or (p and p.general.barTexture) or "none")
end
function ns.Font(fs, size, flags)
    local p = ns.GetSettings()
    local path = p and p.font ~= "__global" and E.ResolveFontName and E.ResolveFontName(p.font)
    path = path or (E.GetFontPath and E.GetFontPath("resourceBars")) or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    local flag = flags or ((E.GetFontOutlineFlag and E.GetFontOutlineFlag("resourceBars")) or "OUTLINE")
    flag = flag:gsub(",?%s*SLUG", "")
    if not fs:SetFont(path, max(6, tonumber(size) or 11), flag) then fs:SetFont("Fonts\\FRIZQT__.TTF", max(6, tonumber(size) or 11), "OUTLINE") end
    if fs.SetShadowOffset then
        if flag == "" then fs:SetShadowOffset(1, -1); fs:SetShadowColor(0, 0, 0, 1) else fs:SetShadowOffset(0, 0) end
    end
end
function ns.Pixel() return (E.PP and E.PP.mult) or 1 end
function ns.Accent()
    local g = E.ELLESMERE_GREEN
    if g then return g.r, g.g, g.b end
    return 12 / 255, 210 / 255, 157 / 255
end
function ns.ClassRGB(token)
    token = token or CLASS
    local c = E.GetClassColor and E.GetClassColor(token)
    if not c or c == E._COLOR_WHITE then c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[token] or c end
    if c then return c.r or 1, c.g or 1, c.b or 1 end
    return 1, 1, 1
end
local POWER_TOKENS = { [0] = "MANA", [1] = "RAGE", [2] = "FOCUS", [3] = "ENERGY", [6] = "RUNIC_POWER" }
local POWER_FALLBACK = { MANA = { 0, 0.55, 1 }, RAGE = { 1, 0, 0 }, FOCUS = { 1, 0.5, 0.25 }, ENERGY = { 1, 1, 0 }, RUNIC_POWER = { 0, 0.82, 1 } }
ns.POWER_TOKENS = POWER_TOKENS
function ns.PowerRGB(powerType, token)
    token = token or POWER_TOKENS[powerType] or "MANA"
    local c = E.GetPowerColor and E.GetPowerColor(token)
    if not c and PowerBarColor then c = PowerBarColor[token] or PowerBarColor[powerType] end
    if c then return c.r or c[1] or 1, c.g or c[2] or 1, c.b or c[3] or 1 end
    local f = POWER_FALLBACK[token] or POWER_FALLBACK.MANA
    return f[1], f[2], f[3]
end
function ns.ResourceRGB()
    local c = E.GetResourceColor and E.GetResourceColor(CLASS)
    if c then return c.r or 1, c.g or 1, c.b or 1 end
    return ns.ClassRGB()
end
-- Number text like Retail's abbreviated values.
function ns.Short(n)
    n = tonumber(n) or 0
    if E.AbbreviateNumber then local ok, s = pcall(E.AbbreviateNumber, n); if ok and s then return s end end
    if n >= 1e6 then return string.format("%.1fm", n / 1e6) elseif n >= 1e4 then return string.format("%.1fk", n / 1e3) end
    return tostring(floor(n + 0.5))
end

--------------------------------------------------------------------------------
-- Fill engine: a texture sized from the value, so every orientation (vertical
-- up/down, reversed) works through texcoords instead of a rotated texture.
--------------------------------------------------------------------------------
local Bar = {}
ns.BarMethods = Bar
local function Render(f)
    local lo, hi = f._min, f._max
    local range = hi - lo
    local frac = range > 0 and max(0, min(1, (f._shown - lo) / range)) or 0
    local fill, o = f.fill, f._orient
    local vertical = o == "VERTICAL_UP" or o == "VERTICAL_DOWN"
    local len = vertical and f:GetHeight() or f:GetWidth()
    local size = frac * len
    f._frac = frac
    if size <= 0.01 then fill:Hide(); if f._onRender then f._onRender(f, frac, 0) end; return end
    fill:ClearAllPoints()
    if o == "VERTICAL_UP" then
        fill:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0); fill:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0); fill:SetHeight(size)
        fill:SetTexCoord(frac, 0, 0, 0, frac, 1, 0, 1)
    elseif o == "VERTICAL_DOWN" then
        fill:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0); fill:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0); fill:SetHeight(size)
        fill:SetTexCoord(0, 0, frac, 0, 0, 1, frac, 1)
    elseif f._reverse then
        fill:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0); fill:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0); fill:SetWidth(size)
        fill:SetTexCoord(1 - frac, 1, 0, 1)
    else
        fill:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0); fill:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0); fill:SetWidth(size)
        fill:SetTexCoord(0, frac, 0, 1)
    end
    fill:Show()
    if f._bgEmpty then
        local bg = f.bg; bg:ClearAllPoints()
        if o == "VERTICAL_UP" then bg:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0); bg:SetPoint("BOTTOMRIGHT", fill, "TOPRIGHT", 0, 0)
        elseif o == "VERTICAL_DOWN" then bg:SetPoint("TOPLEFT", fill, "BOTTOMLEFT", 0, 0); bg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
        elseif f._reverse then bg:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0); bg:SetPoint("BOTTOMRIGHT", fill, "BOTTOMLEFT", 0, 0)
        else bg:SetPoint("TOPLEFT", fill, "TOPRIGHT", 0, 0); bg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0) end
    end
    if f._onRender then f._onRender(f, frac, size) end
end
ns.Render = Render
local function SmoothStep(f, dt)
    local d = f._value - f._shown
    if math.abs(d) <= (f._max - f._min) * 0.002 then f._shown = f._value; f:SetScript("OnUpdate", nil)
    else f._shown = f._shown + d * min(1, dt * 14) end
    Render(f)
end
function Bar:SetMinMaxValues(lo, hi)
    lo, hi = tonumber(lo) or 0, tonumber(hi) or 1
    if hi < lo then hi = lo end
    if self._min == lo and self._max == hi then return end
    self._min, self._max = lo, hi; Render(self)
end
function Bar:GetMinMaxValues() return self._min, self._max end
function Bar:SetValue(v, snap)
    v = tonumber(v) or 0
    self._value = v
    if self._smooth and not snap and self:IsVisible() then
        if self._shown ~= v then self:SetScript("OnUpdate", SmoothStep) end
        return
    end
    self._shown = v; self:SetScript("OnUpdate", nil); Render(self)
end
function Bar:GetValue() return self._value end
function Bar:GetOrientation() local o = self._orient; return (o == "VERTICAL_UP" or o == "VERTICAL_DOWN") and "VERTICAL" or "HORIZONTAL" end
function Bar:GetReverseFill() return self._orient == "VERTICAL_DOWN" or (self._reverse and true or false) end
function Bar:GetStatusBarTexture() return self.fill end
function Bar:SetStatusBarTexture(path) if self._tex ~= path then self._tex = path; self.fill:SetTexture(path) end end
function Bar:SetStatusBarColor(r, g, b, a) self._lgOn = nil; self.fill:SetVertexColor(r or 1, g or 1, b or 1, a or 1) end
function Bar:SetFillOrientation(o, reverse)
    self._orient, self._reverse = o or "HORIZONTAL", reverse and true or false; Render(self)
end
-- Fill color: flat or Retail's two-stop gradient (native SetGradientAlpha).
function Bar:Paint(r, g, b, a, c)
    local fill = self.fill
    if c and c.gradientEnabled and fill.SetGradientAlpha then
        local dir = (c.gradientDir == "VERTICAL") and "VERTICAL" or "HORIZONTAL"
        fill:SetVertexColor(1, 1, 1, 1)
        fill:SetGradientAlpha(dir, r, g, b, a or 1, c.gradientR or r, c.gradientG or g, c.gradientB or b, c.gradientA or 1)
    else
        fill:SetVertexColor(r, g, b, a or 1)
    end
end
function ns.NewBar(parent, name)
    local f = CreateFrame("Frame", name, parent)
    for k, fn in pairs(Bar) do f[k] = fn end
    f._min, f._max, f._value, f._shown, f._orient = 0, 1, 0, 0, "HORIZONTAL"
    f.bg = f:CreateTexture(nil, "BACKGROUND"); f.bg:SetAllPoints(f); f.bg:SetTexture(0.067, 0.067, 0.067, 0.75)
    f.fill = f:CreateTexture(nil, "ARTWORK"); f.fill:SetTexture(WHITE); f._tex = WHITE; f.fill:Hide()
    f.over = CreateFrame("Frame", nil, f); f.over:SetAllPoints(f); f.over:SetFrameLevel(f:GetFrameLevel() + 6)
    f.text = f.over:CreateFontString(nil, "OVERLAY"); ns.Font(f.text, 11); f.text:SetPoint("CENTER", f, "CENTER", 0, 0)
    f:EnableMouse(false)
    return f
end

--------------------------------------------------------------------------------
-- Borders: solid pixel strips, Retail's textured styles through the core,
-- or the Classic WoW UI vanilla cast-bar frame (EllesmereUI.ClassicFrame).
--------------------------------------------------------------------------------
function ns.ApplyBorder(host, c, classic)
    local b = host._erbBorder
    if not b then
        b = CreateFrame("Frame", nil, host); b:SetAllPoints(host); b.edges = {}
        for i = 1, 4 do b.edges[i] = b:CreateTexture(nil, "OVERLAY"); b.edges[i]:SetTexture(WHITE) end
        host._erbBorder = b
    end
    b:SetFrameLevel(host:GetFrameLevel() + 2)
    local size = tonumber(c.borderSize) or 0
    local r, g, bl, a = c.borderR or 0, c.borderG or 0, c.borderB or 0, c.borderA or 1
    local CF = E.ClassicFrame
    if classic and CF then
        for _, t in ipairs(b.edges) do t:Hide() end
        if b.tex then b.tex:Hide() end
        if not b.classic then b.classic = CF.Create(b, "OVERLAY", 2) end
        local ok = pcall(CF.Seat, b.classic, host, CF.ScaleK(c.stockBorderScale), host._erbVertical)
        if ok then for _, t in ipairs(b.classic) do t:Show() end; return end
    end
    if b.classic then for _, t in ipairs(b.classic) do t:Hide() end; b.classic._rect = nil end
    local key = c.borderTexture or "solid"
    if size > 0 and key ~= "solid" and E.ApplyBorderStyle and E.ResolveBorderTexture and E.ResolveBorderTexture(key) then
        if not b.tex then b.tex = CreateFrame("Frame", nil, b); b.tex:SetAllPoints(host) end
        b.tex:SetFrameLevel(b:GetFrameLevel()); b.tex:Show()
        if pcall(E.ApplyBorderStyle, b.tex, size, r, g, bl, a, key, nil, nil, nil, nil, "resourcebars", size) then
            for _, t in ipairs(b.edges) do t:Hide() end
            return
        end
    end
    if b.tex then b.tex:Hide() end
    local px = size * ns.Pixel()
    local e = b.edges
    for _, t in ipairs(e) do t:ClearAllPoints(); t:SetVertexColor(r, g, bl, a); if px > 0 then t:Show() else t:Hide() end end
    if px <= 0 then return end
    e[1]:SetPoint("TOPLEFT", host, "TOPLEFT", 0, 0); e[1]:SetPoint("TOPRIGHT", host, "TOPRIGHT", 0, 0); e[1]:SetHeight(px)
    e[2]:SetPoint("BOTTOMLEFT", host, "BOTTOMLEFT", 0, 0); e[2]:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", 0, 0); e[2]:SetHeight(px)
    e[3]:SetPoint("TOPLEFT", host, "TOPLEFT", 0, 0); e[3]:SetPoint("BOTTOMLEFT", host, "BOTTOMLEFT", 0, 0); e[3]:SetWidth(px)
    e[4]:SetPoint("TOPRIGHT", host, "TOPRIGHT", 0, 0); e[4]:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", 0, 0); e[4]:SetWidth(px)
end

-- Hash lines ("25, 50, 75" in percent or absolute values) over a bar.
function ns.ParseValues(str)
    local out = {}
    for v in tostring(str or ""):gmatch("[%d%.]+") do local n = tonumber(v); if n then out[#out + 1] = n end end
    return out
end
function ns.ApplyHashLines(bar, c, maxValue)
    local pool = bar._erbHash or {}
    bar._erbHash = pool
    local used = 0
    if c and c.hashEnabled and (c.hashValues or "") ~= "" then
        local vertical = bar._orient == "VERTICAL_UP" or bar._orient == "VERTICAL_DOWN"
        local len = vertical and bar:GetHeight() or bar:GetWidth()
        local w = max(1, tonumber(c.hashWidth) or 1) * ns.Pixel()
        for _, v in ipairs(ns.ParseValues(c.hashValues)) do
            local frac = c.hashMode == "value" and (maxValue and maxValue > 0 and v / maxValue) or v / 100
            if frac and frac > 0 and frac < 1 then
                used = used + 1
                local t = pool[used]
                if not t then t = bar.over:CreateTexture(nil, "OVERLAY"); t:SetTexture(WHITE); pool[used] = t end
                t:ClearAllPoints(); t:SetVertexColor(c.hashColorR or 1, c.hashColorG or 1, c.hashColorB or 1, c.hashColorA or 0.7)
                local off = frac * len
                if vertical then
                    t:SetHeight(w); t:SetPoint("LEFT", bar, bar._orient == "VERTICAL_DOWN" and "TOPLEFT" or "BOTTOMLEFT", 0, bar._orient == "VERTICAL_DOWN" and -off or off)
                    t:SetPoint("RIGHT", bar, bar._orient == "VERTICAL_DOWN" and "TOPRIGHT" or "BOTTOMRIGHT", 0, bar._orient == "VERTICAL_DOWN" and -off or off)
                else
                    t:SetWidth(w); t:SetPoint("TOP", bar, bar._reverse and "TOPRIGHT" or "TOPLEFT", bar._reverse and -off or off, 0)
                    t:SetPoint("BOTTOM", bar, bar._reverse and "BOTTOMRIGHT" or "BOTTOMLEFT", bar._reverse and -off or off, 0)
                end
                t:Show()
            end
        end
    end
    for i = used + 1, #pool do pool[i]:Hide() end
end

-- Threshold / multi-band color for a value (Retail semantics: health turns the
-- threshold color at or below the percent; power above it unless "partial").
function ns.ThresholdColor(c, cur, mx, baseR, baseG, baseB, isPower)
    if not c or not mx or mx <= 0 then return baseR, baseG, baseB, false end
    local pct = cur / mx * 100
    if c.multiBandEnabled and type(c.bands) == "table" and #c.bands > 0 then
        local v = c.bandMode == "value" and cur or pct
        if c.bandReverse then
            for i = #c.bands, 1, -1 do local b = c.bands[i]; if v >= (b.to or 0) then return b.r or 1, b.g or 1, b.b or 1, true end end
        else
            for i = 1, #c.bands do local b = c.bands[i]; if v <= (b.to or 0) then return b.r or 1, b.g or 1, b.b or 1, true end end
        end
        return baseR, baseG, baseB, false
    end
    if not c.thresholdEnabled then return baseR, baseG, baseB, false end
    local at = pct <= (c.thresholdPct or 30)
    if isPower and not c.thresholdPartialOnly then at = not at end
    if at then return c.thresholdR or 1, c.thresholdG or 0.2, c.thresholdB or 0.2, true end
    return baseR, baseG, baseB, false
end

--------------------------------------------------------------------------------
-- Visibility: Retail's modes plus the shared option checklist; Fade Out of
-- Combat; druid per-form hiding.
--------------------------------------------------------------------------------
ns.inCombat = false
local function InRaid() return (GetNumRaidMembers and GetNumRaidMembers() or 0) > 0 end
local function InParty() return not InRaid() and (GetNumPartyMembers and GetNumPartyMembers() or 0) > 0 end
function ns.ShouldShow(c)
    if not c then return false end
    if E.CheckVisibilityOptions then local ok, hide = pcall(E.CheckVisibilityOptions, c); if ok and hide then return false end end
    if E.EvalVisibilityExtended then
        local ok, owned = pcall(E.EvalVisibilityExtended, c, "visibility")
        if ok and owned ~= nil then return owned end
    end
    local v = c.visibility or "always"
    if v == "always" then return true end
    if v == "never" then return false end
    if v == "mouseover" then return "mouseover" end
    if v == "combat" or v == "in_combat" then return ns.inCombat end
    if v == "out_of_combat" then return not ns.inCombat end
    if v == "target" then return (UnitExists("target") and UnitCanAttack("player", "target")) and true or false end
    if v == "in_raid" then return InRaid() end
    if v == "in_party" then return InParty() end
    if v == "solo" then return not InRaid() and not InParty() end
    return true
end
function ns.BarAlpha(c)
    if c and c.oocFadeEnabled and not ns.inCombat then return c.oocAlpha or 0.5 end
    return (c and c.barAlpha) or 1
end
function ns.FormBucket()
    if CLASS ~= "DRUID" or not GetShapeshiftFormID then return nil end
    local f = GetShapeshiftFormID()
    if f == 1 then return "energy" elseif f == 5 or f == 8 then return "rage" elseif f == 31 then return "moonkin" end
    return "mana"
end
function ns.HiddenByForm(c, isClass)
    local bucket = ns.FormBucket()
    if not bucket or not c or type(c.barDisabledForms) ~= "table" then return false end
    if isClass and bucket == "moonkin" then return false end
    return c.barDisabledForms[bucket] and true or false
end
-- Apply a show verdict: hidden, shown at bar alpha, or hover-revealed.
function ns.SetVisible(f, verdict, c)
    if not f then return end
    if ns.preview and verdict ~= nil then verdict = true end
    f._erbMouseover = verdict == "mouseover"
    if verdict then
        if not f:IsShown() then f:Show() end
        f:SetAlpha(verdict == "mouseover" and ((MouseIsOver and MouseIsOver(f)) and ns.BarAlpha(c) or 0) or ns.BarAlpha(c))
    elseif f:IsShown() then f:Hide() end
end

--------------------------------------------------------------------------------
-- Positions: Retail's unlockPos per bar, else the bar's default offsets.
--------------------------------------------------------------------------------
function ns.DefaultPoint(key)
    local p = ns.GetSettings(); local c = p[key]; local g = p.general
    if key == "health" or key == "primary" or key == "secondary" then return "CENTER", (g.anchorX or 0) + (c.offsetX or 0), (g.anchorY or -100) + (c.offsetY or 0) end
    if key == "totemBar" then return "CENTER", 0, -200 end
    if key == "callTotemBar" then return "CENTER", 0, -240 end
    return "CENTER", c.anchorX or 0, c.anchorY or 0
end
function ns.Position(key)
    local p, f = ns.GetSettings(), ns.frames[key]
    if not p or not f or InCombatLockdown() and f:IsProtected() then return end
    if ns.KEYS[key] and E._TryOverrideAnchor and not E._unlockActive then
        local ok, owned = pcall(E._TryOverrideAnchor, ns.KEYS[key], f)
        if ok and owned then return end
    end
    local pos = p[key] and p[key].unlockPos
    f:ClearAllPoints()
    if pos and pos.point then f:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
    else local pt, x, y = ns.DefaultPoint(key); f:SetPoint(pt, UIParent, pt, x, y) end
end

-- 0.2 profiles: positions table and toggles move into Retail's keys.
function ns.Migrate(p)
    if p._wrathSchema == 1 then return end
    local map = { health = "health", primary = "primary", secondary = "secondary", castBar = "castBar", gcdBar = "gcdBar", totemBar = "totemBar" }
    if type(p.positions) == "table" then
        for old, new in pairs(map) do local pos = p.positions[old]; if pos and p[new] and not p[new].unlockPos then p[new].unlockPos = pos end end
        p.positions = nil
    end
    if p.health and p.health.classColored == false then p.health.customColored = true; p.health.fillR, p.health.fillG, p.health.fillB = 0.12, 0.8, 0.25 end
    if p.health and p.health.showText == true and p.health.textFormat == "none" then p.health.textFormat = "both" end
    if p.primary and p.primary.showText == false then p.primary.textFormat = "none" end
    if p.castBar and p.castBar.showText == false then p.castBar.showSpellText = false; p.castBar.showTimer = false end
    for _, k in ipairs({ "health", "primary", "secondary", "castBar" }) do if p[k] then p[k].showText = (k == "secondary") and p[k].showText or nil; p[k].classColored = (k ~= "health") and p[k].classColored or nil end end
    p._wrathSchema = 1
end

--------------------------------------------------------------------------------
-- Apply orchestration. Frames here are plain (insecure) widgets except the
-- Call Totem Bar host, so only that piece waits for combat to end.
--------------------------------------------------------------------------------
ns.pending = false
local layouts, updates = {}, {}
ns.layouts, ns.updates = layouts, updates
function ns.RegisterPart(key, layout, update) layouts[#layouts + 1] = { key, layout }; if update then updates[key] = update end end
function ns.Apply()
    local p = ns.GetSettings(); if not p then return end
    ns.cfgGen = (ns.cfgGen or 0) + 1
    for _, entry in ipairs(layouts) do
        local ok, err = pcall(entry[2], p)
        if not ok and geterrorhandler then geterrorhandler()(err) end
    end
    ns.UpdateAll()
end
local function Report(ok, err) if not ok and geterrorhandler then geterrorhandler()(err) end end
function ns.UpdateAll()
    for _, fn in pairs(updates) do Report(pcall(fn)) end
    ns.UpdateVisibility()
end
local visibilityParts = {}
function ns.RegisterVisibility(fn) visibilityParts[#visibilityParts + 1] = fn end
function ns.UpdateVisibility()
    local p = ns.GetSettings(); if not p then return end
    for _, fn in ipairs(visibilityParts) do Report(pcall(fn, p)) end
end
function ns.SetPreview(value) ns.preview = value and true or false; ns.Apply() end
function ns.ResetPositions()
    local p = ns.GetSettings(); if not p then return end
    for _, k in ipairs(ns.BARS) do if p[k] then p[k].unlockPos = nil end end
    ns.Apply()
end
_G._ERB_Apply = function() ns.Apply() end
_G._ERB_RefreshAll = _G._ERB_Apply

-- Unlock Mode elements: Retail keys, resizable bars, Element Options entries.
local function SizeFns(key)
    local function Cfg() local p = ns.GetSettings(); return p and p[key] end
    local wk, hk = (key == "secondary") and "pipWidth" or "width", (key == "secondary") and "pipHeight" or "height"
    local function Vertical(c)
        if key == "secondary" then return (c.pipOrientation or "HORIZONTAL") ~= "HORIZONTAL" end
        return c.orientation == "VERTICAL_UP" or c.orientation == "VERTICAL_DOWN" or c.orientation == "VERTICAL"
    end
    local function Set(axis, v)
        local c = Cfg(); v = tonumber(v); if not c or not v then return end
        v = floor(max(2, min(1200, v)) + 0.5)
        local long = (axis == "w") ~= Vertical(c)
        c[long and wk or hk] = v; ns.Apply()
    end
    return function() return ns.FrameSize(key) end, function(_, w) Set("w", w) end, function(_, h) Set("h", h) end
end
function ns.FrameSize(key)
    local f = ns.frames[key]
    if f then return f:GetWidth(), f:GetHeight() end
    return 214, 16
end
function ns.RegisterSettingsTargets()
    E._ELEMENT_SETTINGS_MAP = E._ELEMENT_SETTINGS_MAP or {}
    local M, P = E._ELEMENT_SETTINGS_MAP, ns.PAGES
    M.ERB_Health = { module = ADDON_NAME, page = P.display, sectionName = "HEALTH BAR", highlightText = "Show Health Bar" }
    M.ERB_Power = { module = ADDON_NAME, page = P.display, sectionName = "POWER BAR", highlightText = "Show Power Bar" }
    M.ERB_ClassResource = { module = ADDON_NAME, page = P.display, sectionName = "CLASS RESOURCE BAR", highlightText = "Show Class Resource" }
    M.ERB_CastBar = { module = ADDON_NAME, page = P.cast, sectionName = "BAR DISPLAY", highlightText = "Enable Player Cast Bar" }
    M.ERB_GCDBar = { module = ADDON_NAME, page = P.gcd, sectionName = "BAR DISPLAY", highlightText = "Enable GCD Bar" }
    M.ERB_SwingTimer = { module = ADDON_NAME, page = P.swing, sectionName = "BAR DISPLAY", highlightText = "Enable Swing Timer" }
    M.ERB_TotemBar = { module = ADDON_NAME, page = P.totem, sectionName = "TOTEM BAR", highlightText = "Show Totem Bar (Shaman)" }
    M.ERB_CallTotemBar = { module = ADDON_NAME, page = P.totem, sectionName = "CALL TOTEM BAR", highlightText = "Enable Call Totem Bar" }
end
function ns.IsElementHidden(key)
    local p = ns.GetSettings()
    if not p or not p.enabled or not p[key] then return true end
    if ns.supported and ns.supported[key] and not ns.supported[key]() then return true end
    local c = p[key]
    if key == "totemBar" then return not (c.enabledClasses and c.enabledClasses[CLASS]) end
    return c.enabled == false
end
function ns.RegisterUnlock()
    if not (E.RegisterUnlockElements and E.MakeUnlockElement) then return end
    local elements = {}
    for _, key in ipairs(ns.BARS) do
        local barKey = key
        local getSize, setW, setH = SizeFns(barKey)
        local fixed = barKey == "totemBar" or barKey == "callTotemBar"
        elements[#elements + 1] = E.MakeUnlockElement({ key = ns.KEYS[barKey], label = ns.LABELS[barKey], group = "Resource Bars",
            order = ns.ORDER[barKey], noAnchorTo = true, noResize = fixed, noAnchorTarget = barKey == "castBar" or nil,
            getFrame = function() return ns.frames[barKey] end, getSize = getSize,
            setWidth = not fixed and setW or nil, setHeight = not fixed and setH or nil,
            isHidden = function() return ns.IsElementHidden(barKey) end,
            savePos = function(_, point, relPoint, x, y)
                local p = ns.GetSettings(); if not p or not point then return end
                p[barKey].unlockPos = { point = point, relPoint = relPoint or point, x = x, y = y }
                if not E._unlockActive then ns.Position(barKey) end
            end,
            loadPos = function()
                local p = ns.GetSettings(); local pos = p and p[barKey] and p[barKey].unlockPos
                return pos and { point = pos.point, relPoint = pos.relPoint or pos.point, x = pos.x, y = pos.y } or nil
            end,
            clearPos = function() local p = ns.GetSettings(); if p and p[barKey] then p[barKey].unlockPos = nil end end,
            applyPos = function() ns.Position(barKey) end,
        })
    end
    ns.RegisterSettingsTargets()
    E:RegisterUnlockElements(elements, ADDON_NAME)
end
_G._ERB_RegisterUnlock = function() ns.RegisterUnlock() end

function addon:OnInitialize()
    addon.db = E.Lite.NewDB("EllesmereUIResourceBarsDB", defaults); ns.db = addon.db; _G._ERB_AceDB = addon.db
    ns.Migrate(addon.db.profile)
    SLASH_EUI335RESOURCE1 = "/erb"
    SlashCmdList.EUI335RESOURCE = function()
        if InCombatLockdown() then return end
        if E.EnsureOptionsLoaded then E.EnsureOptionsLoaded() end
        E:ShowModule(ADDON_NAME)
    end
end

-- One event frame dispatches to the parts; unit events are filtered here.
local events = CreateFrame("Frame")
ns.events = events
local handlers = {}
function ns.On(event, fn)
    local list = handlers[event]
    if not list then list = {}; handlers[event] = list; events:RegisterEvent(event) end
    list[#list + 1] = fn
end
local tickers = {}
function ns.OnTick(fn) tickers[#tickers + 1] = fn end
local fastTickers = {}
function ns.OnFrame(fn) fastTickers[#fastTickers + 1] = fn end

function addon:OnEnable()
    if not addon.db then return end
    ns.Migrate(addon.db.profile)
    ns.inCombat = InCombatLockdown() and true or false
    ns.Apply()
    if E.RegisterUnlockModeListener then E:RegisterUnlockModeListener(ADDON_NAME, function(active) ns.SetPreview(active) end) end
    ns.RegisterUnlock()
    if E.RegisterVisEdge then E.RegisterVisEdge(ns.UpdateVisibility) end
    ns.On("PLAYER_ENTERING_WORLD", function() ns.Apply() end)
    ns.On("PLAYER_REGEN_DISABLED", function() ns.inCombat = true; ns.UpdateVisibility() end)
    ns.On("PLAYER_REGEN_ENABLED", function() ns.inCombat = false; if ns.pending then ns.pending = false; ns.Apply() else ns.UpdateVisibility() end end)
    for _, ev in ipairs({ "PLAYER_TARGET_CHANGED", "PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE", "ZONE_CHANGED_NEW_AREA" }) do ns.On(ev, ns.UpdateVisibility) end
    ns.On("UPDATE_SHAPESHIFT_FORM", function() ns.Apply() end)
    events:SetScript("OnEvent", function(_, event, ...)
        local list = handlers[event]
        if not list then return end
        for i = 1, #list do list[i](event, ...) end
    end)
    local elapsed = 0
    events:SetScript("OnUpdate", function(_, dt)
        local p = ns.GetSettings(); if not p or not p.enabled then return end
        for i = 1, #fastTickers do fastTickers[i](dt) end
        elapsed = elapsed + dt; if elapsed < 0.05 then return end
        local step = elapsed; elapsed = 0
        for i = 1, #tickers do tickers[i](step) end
        for _, f in pairs(ns.frames) do
            if f._erbMouseover and f:IsShown() then
                local c = p[f._erbKey]
                f:SetAlpha((MouseIsOver and MouseIsOver(f)) and ns.BarAlpha(c) or 0)
            end
        end
    end)
    if ns.OnEnableParts then for _, fn in ipairs(ns.OnEnableParts) do fn() end end
end
ns.OnEnableParts = {}
function ns.AfterEnable(fn) ns.OnEnableParts[#ns.OnEnableParts + 1] = fn end
