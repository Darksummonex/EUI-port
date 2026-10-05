-------------------------------------------------------------------------------
--  EUI_AuraBuffReminders_335_Display.lua
--  Reminder icons: Retail look (bordered icon, glow, name, count badges,
--  eating countdown, hover highlight, tooltips) on non-secure frames that
--  stay live through combat. Click-to-cast rides transparent secure buttons
--  parented to UIParent and placed out of combat on top of each icon, so no
--  display frame is ever anchored to (and protected by) a secure frame.
-------------------------------------------------------------------------------
local _, ns = ...
local EABR = ns.EABR
if not EABR then return end
local E = EllesmereUI
local floor, max, abs = math.floor, math.max, math.abs
local ICON_SIZE = EABR.ICON_SIZE

EABR.iconPool, EABR.activeIcons = {}, {}
EABR.cursorPool, EABR.cursorActive = {}, {}
EABR.actions = {}
EABR.dismissed = {}

local function DB() return EABR.db and EABR.db.profile end
local function DDB() local p = DB(); return p and p.display end

function EABR.GetStrata()
    local d = DDB()
    return d and d.frameStrata or "MEDIUM"
end

-------------------------------------------------------------------------------
--  Fonts
-------------------------------------------------------------------------------
function EABR.ResolveFontPath(fontName)
    if fontName and fontName ~= "__global" and E.ResolveFontName then
        local path = E.ResolveFontName(fontName)
        if path and path ~= "" then return path end
    end
    if E.GetFontPath then return E.GetFontPath("auraBuff") end
    return "Interface\\AddOns\\EllesmereUI\\media\\fonts\\Expressway.TTF"
end

function EABR.SetABRFont(fs, font, size)
    if not (fs and fs.SetFont) then return end
    if not EABR._cachedOutline then EABR._cachedOutline = E.GetFontOutlineFlag("auraBuff") end
    local outline = EABR._cachedOutline
    if E.PrimeFontShadow then E.PrimeFontShadow(fs, outline == "" and E.GetFontUseShadow("auraBuff")) end
    fs:SetFont(font, size, outline)
    if not fs:GetFont() then fs:SetFont("Fonts\\FRIZQT__.TTF", size, outline) end
end

-------------------------------------------------------------------------------
--  Borders, text overlay, glow
-------------------------------------------------------------------------------
function EABR.ApplyIconBorder(f)
    if not f then return end
    local border = f._eabrBorderFrame
    if not border then
        border = CreateFrame("Frame", nil, f)
        border:SetAllPoints()
        border:EnableMouse(false)
        f._eabrBorderFrame = border
    end
    local p = DDB()
    local size = (p and p.borderSize) or 1
    local texture = (p and p.borderTexture) or "solid"
    local r, g, b, a = (p and p.borderR) or 0, (p and p.borderG) or 0, (p and p.borderB) or 0, (p and p.borderA) or 1
    local ox, oy = p and p.borderTextureOffset, p and p.borderTextureOffsetY
    local sx, sy = p and p.borderTextureShiftX, p and p.borderTextureShiftY
    local behind = p and p.borderBehind == true
    local level = behind and max(0, f:GetFrameLevel() - 1) or (f:GetFrameLevel() + 2)
    local pxRaw = p and p.borderSizePx
    if border._eabrSize == size and border._eabrTexture == texture and border._eabrPx == pxRaw
        and border._eabrR == r and border._eabrG == g and border._eabrB == b and border._eabrA == a
        and border._eabrOX == ox and border._eabrOY == oy and border._eabrSX == sx and border._eabrSY == sy
        and border._eabrBehind == behind and border._eabrLevel == level then
        return
    end
    border:SetFrameLevel(level)
    E.ApplyBorderStyle(border, size, r, g, b, a, texture, ox, oy, sx, sy, "aurabuffreminders", size, nil,
        E.BorderPx and E.BorderPx(pxRaw, size, texture))
    border._eabrSize, border._eabrTexture, border._eabrPx = size, texture, pxRaw
    border._eabrR, border._eabrG, border._eabrB, border._eabrA = r, g, b, a
    border._eabrOX, border._eabrOY, border._eabrSX, border._eabrSY = ox, oy, sx, sy
    border._eabrBehind, border._eabrLevel = behind, level
end

function EABR.ApplyAllIconBorders()
    for _, f in pairs(EABR.iconPool) do EABR.ApplyIconBorder(f) end
    for _, f in pairs(EABR.cursorPool) do EABR.ApplyIconBorder(f) end
    if EABR._talentPool then for _, f in pairs(EABR._talentPool) do EABR.ApplyIconBorder(f) end end
end

function EABR.GetIconTextOverlay(f)
    if f._textOverlay then return f._textOverlay end
    local overlay = CreateFrame("Frame", nil, f)
    overlay:SetAllPoints()
    overlay:SetFrameLevel(f:GetFrameLevel() + 5)
    f._textOverlay = overlay
    return overlay
end

do
    local SPEC = {}
    function EABR.GlowSpec(p, out)
        local view = EABR.GLOW_VIEW
        local shared = p and view and view.toShared[p.glowType or 0]
        if not shared then return nil end
        out = out or SPEC
        out.style = shared
        out.r, out.g, out.b = EABR.ResolveGlowTint(p)
        out.lines, out.thickness, out.speed = p.glowLines, p.glowThickness, p.glowSpeed
        local bgc = p.glowBackgroundColor
        out.bg = (p.glowBackground == true) or nil
        out.bgR, out.bgG, out.bgB = bgc and bgc.r, bgc and bgc.g, bgc and bgc.b
        return out
    end
end

function EABR.ApplyGlow(f, p, sz)
    local spec = EABR.GlowSpec(p)
    local G = E.Glows
    if not spec or not G then
        local w = f._eabrGlowWrapper
        if w and G then G.StopAllGlows(w) end
        if w then w:Hide() end
        return
    end
    if not f._eabrGlowWrapper then
        local w = CreateFrame("Frame", nil, f)
        w:SetAllPoints(f)
        w:SetFrameLevel(f:GetFrameLevel() + 4)
        f._eabrGlowWrapper = w
    end
    local w = f._eabrGlowWrapper
    sz = sz or f:GetWidth() or ICON_SIZE
    G.StartSpecGlow(w, spec, sz, sz, "icon")
    w:SetAlpha(1)
    w:Show()
end

function EABR.RemoveGlow(f)
    local w = f._eabrGlowWrapper
    if w then
        if E.Glows then E.Glows.StopAllGlows(w) end
        w:Hide()
    end
end

-------------------------------------------------------------------------------
--  Tooltips, hover, click hints, dismiss
-------------------------------------------------------------------------------
function EABR.ShowIconTooltip(f, owner)
    local d = DDB()
    if not f or (d and d.showTooltips == false) then return end
    owner = owner or f
    if f._tooltipItem or f._tooltipSpell then
        GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
        if f._tooltipItem then
            GameTooltip:SetHyperlink("item:" .. f._tooltipItem)
        else
            GameTooltip:SetHyperlink("spell:" .. f._tooltipSpell)
        end
        if f._outOfStock then
            GameTooltip:AddLine(E.L("You don't have this item in your bags"), 1, 0.3, 0.3, true)
        elseif f._substitute then
            GameTooltip:AddLine(E.L("Your preferred food is out - using a backup you own"), 1, 0.82, 0, true)
        end
        GameTooltip:Show()
    elseif f._tooltipLabel and f._tooltipLabel ~= "" then
        E.ShowWidgetTooltip(owner, tostring(f._tooltipLabel))
    end
end

function EABR.HideIconTooltip(f)
    if f and (f._tooltipItem or f._tooltipSpell) then
        GameTooltip:Hide()
    elseif E.HideWidgetTooltip then
        E.HideWidgetTooltip()
    end
end

function EABR.NotifyCombatClickDisabled()
    local now = GetTime()
    if EABR._clickHintAt and now - EABR._clickHintAt < 2.5 then return end
    EABR._clickHintAt = now
    if UIErrorsFrame then
        UIErrorsFrame:AddMessage(E.L("Click-to-use is disabled in combat"), 1.0, 0.3, 0.3, 1.0)
    end
end

function EABR.Dismiss(key)
    if not key then return end
    EABR.dismissed[key] = true
    if EABR.RequestRefresh then EABR.RequestRefresh() end
end

function EABR.CyclePet(total)
    if not total then return end
    EABR._petCycleIndex = ((EABR._petCycleIndex or 1) % total) + 1
    if EABR.RequestRefresh then EABR.RequestRefresh() end
end

local function VisualOnEnter(self)
    if self._hl then self._hl:Show() end
    EABR.ShowIconTooltip(self)
end
local function VisualOnLeave(self)
    if self._hl then self._hl:Hide() end
    EABR.HideIconTooltip(self)
end
local function VisualOnMouseUp(self, button)
    if button == "MiddleButton" then
        EABR.Dismiss(self._dismissKey)
    elseif button == "RightButton" and self._petCycleTotal then
        EABR.CyclePet(self._petCycleTotal)
    elseif button == "LeftButton" and InCombatLockdown() and self._hasAction then
        EABR.NotifyCombatClickDisabled()
    end
end

-------------------------------------------------------------------------------
--  Count / bag-count / coverage badges and the eating countdown
-------------------------------------------------------------------------------
function EABR.SizeIconBagCount(f, sz)
    local fs = f._bagCount
    if not fs or not f._bagCountShown then return end
    local p = DDB()
    local base = (p and p.countSize) or 16
    local fsz = max(6, floor(base * (sz / ICON_SIZE) + 0.5))
    EABR.SetABRFont(fs, EABR.ResolveFontPath(p and p.countFont), fsz)
    fs:ClearAllPoints()
    fs:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", (p and p.countXOffset) or 0, (p and p.countYOffset) or 0)
end

function EABR.ApplyIconBagCount(f, count, outOfStock, substitute)
    f._outOfStock = outOfStock and true or nil
    f._substitute = (substitute and not outOfStock) and true or nil
    local fs = f._bagCount
    local p = DDB()
    local showCount = not p or p.showCount ~= false
    if showCount and outOfStock then
        f._bagCountShown = true
        fs:SetText("0")
        fs:SetTextColor(1, 0.2, 0.2, 1)
    elseif showCount and count and count > 0 then
        f._bagCountShown = true
        fs:SetText(count)
        if substitute then fs:SetTextColor(1, 0.82, 0, 1) else fs:SetTextColor(1, 1, 1, 1) end
    else
        f._bagCountShown = nil
        fs:SetText("")
        fs:Hide()
        return
    end
    EABR.SizeIconBagCount(f, f:GetWidth() or ICON_SIZE)
    fs:Show()
end

function EABR.ApplyIconGroupCoverage(f, have, total)
    local fs = f._bagCount
    f._outOfStock, f._substitute = nil, nil
    if have ~= nil and total and total > 0 then
        f._bagCountShown = true
        fs:SetText(have .. "/" .. total)
        fs:SetTextColor(1, 1, 1, 1)
        EABR.SizeIconBagCount(f, f:GetWidth() or ICON_SIZE)
        fs:Show()
    else
        f._bagCountShown = nil
        fs:SetText("")
        fs:Hide()
    end
end

function EABR.ClearEatingVisual(f)
    if f._eabrEatingOnUpdate then
        f:SetScript("OnUpdate", nil)
        f._eabrEatingOnUpdate = nil
    end
    if f._count then f._count:Hide() end
end

function EABR.EatingTick(self, elapsed)
    self._eatingAccum = (self._eatingAccum or 0) + elapsed
    if self._eatingAccum < 0.2 then return end
    self._eatingAccum = 0
    local rem = (self._eatingExp or 0) - GetTime()
    if rem > 0 then
        local mins = math.ceil(rem / 60)
        local txt = (mins > 1) and (mins .. "m") or (math.ceil(rem) .. "s")
        if txt ~= self._eatingText then
            self._eatingText = txt
            self._count:SetText(txt)
        end
        self._count:Show()
        if self._text then self._text:Hide() end
    else
        self._count:Hide()
        self:SetScript("OnUpdate", nil)
        self._eabrEatingOnUpdate = nil
        if EABR.RequestRefresh then EABR.RequestRefresh() end
    end
end

function EABR.ApplyEatingVisual(f, m)
    EABR.ClearEatingVisual(f)
    if not (m and m.isEating) then return end
    f._icon:SetDesaturated(false)
    f._icon:SetTexture(EABR.EATING_ICON)
    EABR.RemoveGlow(f)
    local expTime = m.eatingExpirationTime
    if not expTime then return end
    local p = DDB()
    EABR.SetABRFont(f._count, EABR.ResolveFontPath(), max(14, floor(((p and p.textSize) or 11) * 1.15)))
    f._count:SetTextColor(1, 1, 1, 1)
    f._eatingExp = expTime
    f._eatingText = nil
    f._eatingAccum = 1
    EABR.EatingTick(f, 0)
    f._eabrEatingOnUpdate = true
    f:SetScript("OnUpdate", EABR.EatingTick)
end

-------------------------------------------------------------------------------
--  Visual icon factory
-------------------------------------------------------------------------------
function EABR.CreateVisualIcon(name, parent, strata, level)
    local f = CreateFrame("Frame", name, parent)
    f:SetSize(ICON_SIZE, ICON_SIZE)
    f:SetFrameStrata(strata)
    f:SetFrameLevel(level)
    f:Hide()
    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    f._icon = icon
    EABR.ApplyIconBorder(f)
    local overlay = EABR.GetIconTextOverlay(f)
    local text = overlay:CreateFontString(nil, "OVERLAY")
    text:SetPoint("TOP", f, "BOTTOM", 0, -2)
    EABR.SetABRFont(text, EABR.ResolveFontPath(), 11)
    text:SetTextColor(1, 1, 1, 1)
    f._text = text
    local count = overlay:CreateFontString(nil, "OVERLAY", "NumberFontNormalLarge")
    count:SetPoint("CENTER", icon, "CENTER", 0, 0)
    count:Hide()
    f._count = count
    local bag = overlay:CreateFontString(nil, "OVERLAY")
    EABR.SetABRFont(bag, EABR.ResolveFontPath(), 11)
    bag:Hide()
    f._bagCount = bag
    local hl = f:CreateTexture(nil, "OVERLAY")
    hl:SetAllPoints(icon)
    hl:SetTexture(1, 1, 1, 0.2)
    hl:Hide()
    f._hl = hl
    f:EnableMouse(true)
    f:SetScript("OnEnter", VisualOnEnter)
    f:SetScript("OnLeave", VisualOnLeave)
    f:SetScript("OnMouseUp", VisualOnMouseUp)
    return f
end

local function EntryTexture(m)
    local spellID = m.spellID or (m.data and m.data.castSpell)
    return m.texture or (spellID and EABR.Tex(spellID)) or EABR.QUESTION_ICON
end

-- Paints one reminder entry onto a visual icon.
function EABR.PaintIcon(f, m)
    local p = DDB()
    f._dismissKey = m.dismissKey
    f._petCycleTotal = m.petCycleTotal
    f._hasAction = m.mode == "spell" or m.mode == "item" or m.mode == "macro"
    f._entry = m
    f._icon:SetTexture(EntryTexture(m))
    f._icon:SetDesaturated(m.desaturated and true or false)
    f._tooltipItem = m.tooltipItem or m.itemID
    f._tooltipSpell = (not f._tooltipItem) and (m.spellID or (m.data and m.data.castSpell)) or nil
    f._tooltipLabel = m.label
    if p and p.showText and not m.isEating then
        local tc = p.textColor or EABR.DEFAULT_TEXT_COLOR
        EABR.SetABRFont(f._text, EABR.ResolveFontPath(p.nameFont), p.textSize or 11)
        f._text:ClearAllPoints()
        local tp, ip = EABR.GetTextAnchorPoints(p)
        f._text:SetPoint(tp, f, ip, p.textXOffset or 0, p.textYOffset or -2)
        f._text:SetTextColor(tc.r, tc.g, tc.b, 1)
        f._text:SetText(m.label or "")
        f._text:Show()
    else
        f._text:SetText("")
        f._text:Hide()
    end
    EABR.ApplyEatingVisual(f, m)
    if m.groupTotal then
        EABR.ApplyIconGroupCoverage(f, m.groupHave, m.groupTotal)
    else
        EABR.ApplyIconBagCount(f, (not m.isEating) and m.bagCount or nil,
            (not m.isEating) and m.desaturated or nil, (not m.isEating) and m.substitute or nil)
    end
    if not m.isEating then
        EABR.ApplyGlow(f, p, floor(ICON_SIZE * ((p and p.scale) or 1) + 0.5))
    end
    f:Show()
end

local function ResetIcon(f)
    EABR.ClearEatingVisual(f)
    EABR.RemoveGlow(f)
    f._text:SetText("")
    f._entry, f._dismissKey, f._petCycleTotal, f._hasAction = nil, nil, nil, nil
    if f._hl then f._hl:Hide() end
    f:Hide()
end

function EABR.GetOrCreateIcon(index)
    local f = EABR.iconPool[index]
    if f then return f end
    f = EABR.CreateVisualIcon("EABR_Icon" .. index, EABR.iconAnchor, EABR.GetStrata(), 120)
    EABR.iconPool[index] = f
    return f
end

function EABR.GetOrCreateCursorIcon(index)
    local f = EABR.cursorPool[index]
    if f then return f end
    f = EABR.CreateVisualIcon("EABR_CursorIcon" .. index, EABR.cursorAnchor, "TOOLTIP", 100)
    EABR.cursorPool[index] = f
    return f
end

function EABR.HideRowIcons()
    for _, f in pairs(EABR.iconPool) do ResetIcon(f) end
    wipe(EABR.activeIcons)
    EABR._rowSlots = nil
    if EABR.iconAnchor then E.SetElementVisibility(EABR.iconAnchor, false) end
end

function EABR.HideCursorIcons()
    for _, f in pairs(EABR.cursorPool) do ResetIcon(f) end
    wipe(EABR.cursorActive)
    if EABR.cursorAnchor then
        E.SetElementVisibility(EABR.cursorAnchor, false)
        EABR.cursorAnchor:Hide()
    end
end

-------------------------------------------------------------------------------
--  Layout
-------------------------------------------------------------------------------
function EABR.IconPixelSize()
    local p = DDB()
    return floor(ICON_SIZE * ((p and p.scale) or 1.0) + 0.5)
end

local function SizeIcon(f, sz, p)
    f:SetSize(sz, sz)
    f:SetAlpha(p.opacity or 1.0)
    EABR.ApplyIconBorder(f)
    EABR.SizeIconBagCount(f, sz)
end

-- Out of combat the row hangs off the anchor's grow edge and resizes it;
-- in combat the anchor keeps its size and the row runs from its left edge
-- (right edge for Grow Left) so the slot under the provider cast button,
-- placed before combat, never moves. slots may hold false = empty slot.
function EABR.LayoutRow(slots)
    local anchor = EABR.iconAnchor
    local count = #slots
    if not anchor or count == 0 then return end
    local p = DDB()
    local spacing = p.iconSpacing or 8
    local sz = EABR.IconPixelSize()
    local textH = p.showText and ((p.textSize or 11) + abs(p.textYOffset or -2)) or 0
    local pt, startX, yOff
    if InCombatLockdown() then
        pt, startX, yOff = "TOPLEFT", 0, 0
        if p.growDirection == "LEFT" and not EABR._providerReserved then
            pt, startX = "TOPRIGHT", -(count - 1) * (sz + spacing)
        end
    else
        local totalW = count * sz + (count - 1) * spacing
        pt, startX, yOff = "CENTER", -(totalW / 2) + (sz / 2), textH / 2
        if p.growDirection == "RIGHT" then
            pt, startX, yOff = "TOPLEFT", 0, 0
        elseif p.growDirection == "LEFT" then
            pt, startX, yOff = "TOPRIGHT", -(count - 1) * (sz + spacing), 0
        end
        anchor:SetSize(totalW, sz + textH)
    end
    for i, f in ipairs(slots) do
        if f then
            SizeIcon(f, sz, p)
            f:ClearAllPoints()
            f:SetPoint(pt, anchor, pt, startX + (i - 1) * (sz + spacing), yOff)
        end
    end
end

function EABR.LayoutCursorIcons()
    local count = #EABR.cursorActive
    if count == 0 then return end
    local p = DDB()
    local spacing = p.iconSpacing or 8
    local sz = EABR.IconPixelSize()
    local totalW = count * sz + (count - 1) * spacing
    local startX = -(totalW / 2) + (sz / 2)
    for i, f in ipairs(EABR.cursorActive) do
        SizeIcon(f, sz, p)
        f:ClearAllPoints()
        f:SetPoint("CENTER", EABR.cursorAnchor, "CENTER", startX + (i - 1) * (sz + spacing), 0)
    end
end

-------------------------------------------------------------------------------
--  Secure click overlays (out of combat only)
-------------------------------------------------------------------------------
local function OverlayOnEnter(self)
    local v = self._visual
    if v then
        if v._hl then v._hl:Show() end
        EABR.ShowIconTooltip(v, self)
    end
end
local function OverlayOnLeave(self)
    local v = self._visual
    if v then
        if v._hl then v._hl:Hide() end
        EABR.HideIconTooltip(v)
    end
end
local function OverlayPostClick(self, button)
    local v = self._visual
    if not v then return end
    if button == "MiddleButton" then
        EABR.Dismiss(v._dismissKey)
    elseif button == "RightButton" and v._petCycleTotal then
        EABR.CyclePet(v._petCycleTotal)
    end
end

local function CreateSecureOverlay(name)
    local b = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
    b:SetSize(ICON_SIZE, ICON_SIZE)
    b:SetFrameStrata(EABR.GetStrata())
    b:SetFrameLevel(200)
    b:RegisterForClicks("LeftButtonUp", "MiddleButtonUp")
    b:SetScript("OnEnter", OverlayOnEnter)
    b:SetScript("OnLeave", OverlayOnLeave)
    b:SetScript("PostClick", OverlayPostClick)
    b:Hide()
    return b
end

-- Writes the reminder's click action onto a secure button (left click only:
-- every attribute carries the "1" suffix, so middle/right never fire it).
local function ApplySecureAction(b, m)
    b:SetAttribute("type1", nil)
    b:SetAttribute("spell1", nil)
    b:SetAttribute("item1", nil)
    b:SetAttribute("macrotext1", nil)
    b:SetAttribute("unit1", nil)
    if not m then return false end
    if m.mode == "spell" then
        local name = m.spellName or EABR.SpellName(m.spellID)
        if not name then return false end
        b:SetAttribute("type1", "spell")
        b:SetAttribute("spell1", name)
        if m.unit ~= false then b:SetAttribute("unit1", m.unit or "player") end
    elseif m.mode == "item" then
        b:SetAttribute("type1", "item")
        b:SetAttribute("item1", "item:" .. m.itemID)
    elseif m.mode == "macro" then
        b:SetAttribute("type1", "macro")
        b:SetAttribute("macrotext1", m.macro)
    else
        return false
    end
    return true
end

-- Places a secure button exactly over a visual icon in UIParent space.
local function PlaceOver(b, v)
    local l, bt = v:GetLeft(), v:GetBottom()
    if not (l and bt) then return false end
    local ratio = v:GetEffectiveScale() / UIParent:GetEffectiveScale()
    b:ClearAllPoints()
    b:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", l * ratio, bt * ratio)
    b:SetSize(v:GetWidth() * ratio, v:GetHeight() * ratio)
    return true
end

local function SetDriver(b, driver)
    if b._driver ~= driver then
        RegisterStateDriver(b, "visibility", driver)
        b._driver = driver
    end
end

-- Binds overlays to the visible row icons (index-aligned with activeIcons).
function EABR.SyncActions()
    if InCombatLockdown() then EABR._actionsDirty = true; return end
    EABR._actionsDirty = false
    local strata = EABR.GetStrata()
    local used, failed = 0, false
    for _, v in ipairs(EABR.activeIcons) do
        local m = v._entry
        if m and v ~= EABR._providerVisual and v:IsShown() then
            used = used + 1
            local b = EABR.actions[used]
            if not b then
                b = CreateSecureOverlay("EABR_Action" .. used)
                EABR.actions[used] = b
            end
            b._visual = v
            b:SetFrameStrata(strata)
            if m.petCycleTotal then
                b:RegisterForClicks("LeftButtonUp", "MiddleButtonUp", "RightButtonUp")
            else
                b:RegisterForClicks("LeftButtonUp", "MiddleButtonUp")
            end
            ApplySecureAction(b, m)
            if PlaceOver(b, v) then
                SetDriver(b, "[combat] hide; show")
            else
                SetDriver(b, "hide")
                failed = true
                EABR._placeRetries = (EABR._placeRetries or 0) + 1
                if not EABR._placeRetry and EABR._placeRetries <= 5 then
                    EABR._placeRetry = true
                    C_Timer.After(0, function() EABR._placeRetry = nil; EABR.SyncActions() end)
                end
            end
        end
    end
    if not failed then EABR._placeRetries = 0 end
    for i = used + 1, #EABR.actions do
        local b = EABR.actions[i]
        b._visual = nil
        ApplySecureAction(b, nil)
        SetDriver(b, "hide")
    end
end

function EABR.HideActions()
    if InCombatLockdown() then return end
    for _, b in ipairs(EABR.actions) do
        b._visual = nil
        SetDriver(b, "hide")
    end
end

-------------------------------------------------------------------------------
--  Provider raid-buff cast button: bound out of combat to the player's own
--  raid buff and left in place through combat, so a rebuff after a battle
--  res stays clickable. Only its alpha/visual changes under lockdown.
-------------------------------------------------------------------------------
function EABR.EnsureProviderCastButton()
    if EABR._providerCastBtn then return EABR._providerCastBtn end
    if InCombatLockdown() then return nil end
    local b = CreateSecureOverlay("EABR_ProviderCast")
    b:Show()
    EABR._providerCastBtn = b
    EABR.ParkProviderCastButton()
    return b
end

function EABR.ParkProviderCastButton()
    local b = EABR._providerCastBtn
    if not b or InCombatLockdown() then return end
    EABR._providerReserved = false
    EABR._providerVisual = nil
    b._visual = nil
    b:EnableMouse(false)
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -10000, 10000)
end

function EABR.PlaceProviderCastButton(v, m)
    if InCombatLockdown() then return end
    local b = EABR.EnsureProviderCastButton()
    if not b then return end
    b:SetFrameStrata(EABR.GetStrata())
    if ApplySecureAction(b, m) and PlaceOver(b, v) then
        b._visual = v
        b:EnableMouse(true)
        EABR._providerReserved = true
        EABR._providerVisual = v
    else
        EABR.ParkProviderCastButton()
    end
end

-------------------------------------------------------------------------------
--  Anchors, strata, unlock mode
-------------------------------------------------------------------------------
function EABR.CreateAnchors()
    if EABR.iconAnchor then return end
    local a = CreateFrame("Frame", "EABR_Anchor", UIParent)
    a:SetSize(1, 1)
    a:SetFrameStrata(EABR.GetStrata())
    a:EnableMouse(false)
    a:Show()
    EABR.iconAnchor = a
    E.SetElementVisibility(a, false)
    for i = 1, 6 do EABR.GetOrCreateIcon(i) end

    local c = CreateFrame("Frame", "EABR_CursorAnchor", UIParent)
    c:SetSize(1, 1)
    c:SetFrameStrata("TOOLTIP")
    c:SetFrameLevel(90)
    c:EnableMouse(false)
    c:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    local lastX, lastY
    local function Glue(rawX, rawY)
        local s = UIParent:GetEffectiveScale()
        local cx, cy = floor(rawX / s + 0.5), floor(rawY / s + 0.5)
        if cx ~= lastX or cy ~= lastY then
            lastX, lastY = cx, cy
            c:ClearAllPoints()
            c:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx, cy + 60)
        end
    end
    local M = E.Mouse
    if M and M.SubscribeFrame then
        c:SetScript("OnShow", function() Glue(M.Get()); M.SubscribeFrame("abrCursor", Glue, true) end)
        c:SetScript("OnHide", function() M.UnsubscribeFrame("abrCursor") end)
    else
        c:SetScript("OnUpdate", function() Glue(GetCursorPosition()) end)
    end
    c:Hide()
    EABR.cursorAnchor = c
    EABR.ApplyUnlockPos()
end

function EABR.ApplyStrata()
    local strata = EABR.GetStrata()
    if EABR.iconAnchor then EABR.iconAnchor:SetFrameStrata(strata) end
    for _, f in pairs(EABR.iconPool) do f:SetFrameStrata(strata) end
    if not InCombatLockdown() then
        for _, b in ipairs(EABR.actions) do b:SetFrameStrata(strata) end
        if EABR._providerCastBtn then EABR._providerCastBtn:SetFrameStrata(strata) end
    end
    EABR.ApplyAllIconBorders()
    if EABR.RequestRefresh then EABR.RequestRefresh() end
end

function EABR.NominalRowW(d)
    return 2 * floor(ICON_SIZE * (d.scale or 1.0) + 0.5) + (d.iconSpacing or 8)
end

function EABR.ApplyUnlockPos()
    local a = EABR.iconAnchor
    local p = DB()
    if not a or not p then return end
    if E.IsUnlockAnchored and E.IsUnlockAnchored("EABR_Reminders") and a:GetLeft() then return end
    local pos = p.unlockPos
    a:ClearAllPoints()
    if pos and pos.point then
        local px, py = pos.x or 0, pos.y or 0
        local PPa = E.PP
        if PPa then
            local es = a:GetEffectiveScale()
            if pos.point == "CENTER" and (pos.relPoint == "CENTER" or pos.relPoint == nil) and PPa.SnapCenterForDim then
                px = PPa.SnapCenterForDim(px, a:GetWidth() or 0, es)
                py = PPa.SnapCenterForDim(py, a:GetHeight() or 0, es)
            elseif PPa.SnapForES then
                px, py = PPa.SnapForES(px, es), PPa.SnapForES(py, es)
            end
        end
        a:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, px, py)
    else
        local d = p.display
        if d.growDirection == "RIGHT" then
            a:SetPoint("LEFT", UIParent, "CENTER", (d.xOffset or 0) - EABR.NominalRowW(d) / 2, d.yOffset or 0)
        elseif d.growDirection == "LEFT" then
            a:SetPoint("RIGHT", UIParent, "CENTER", (d.xOffset or 0) + EABR.NominalRowW(d) / 2, d.yOffset or 0)
        else
            a:SetPoint("CENTER", UIParent, "CENTER", d.xOffset or 0, d.yOffset or 0)
        end
    end
    if EABR.RequestRefresh then EABR.RequestRefresh() end
end

-- Moves a saved position onto the new grow edge without moving the row.
function EABR.UpdateUnlockPosForGrowDir(newGrowDir)
    local p = DB()
    local pos = p and p.unlockPos
    if not pos or not pos.point or (pos.relPoint or pos.point) ~= "CENTER" then return end
    local cur = pos.point
    if cur ~= "CENTER" and cur ~= "LEFT" and cur ~= "RIGHT" then return end
    local target = (newGrowDir == "RIGHT" and "LEFT") or (newGrowDir == "LEFT" and "RIGHT") or "CENTER"
    if cur == target then return end
    local w = EABR.iconAnchor and EABR.iconAnchor:GetWidth() or 0
    if w <= 1 then w = EABR.NominalRowW(p.display) end
    local cx = pos.x or 0
    if cur == "LEFT" then cx = cx + w / 2 elseif cur == "RIGHT" then cx = cx - w / 2 end
    if target == "LEFT" then pos.x = cx - w / 2 elseif target == "RIGHT" then pos.x = cx + w / 2 else pos.x = cx end
    pos.point, pos.relPoint = target, "CENTER"
end

function E.GetAuraBuffGrowDir()
    local d = DDB()
    return d and d.growDirection or "CENTER"
end

function E.SetAuraBuffGrowDir(v)
    local d = DDB()
    if not d then return end
    d.growDirection = v
    EABR.UpdateUnlockPosForGrowDir(v)
    EABR.ApplyUnlockPos()
end

function EABR.RegisterUnlockElements()
    if not (E.RegisterUnlockElements and E.MakeUnlockElement) or EABR._unlockRegistered then return end
    EABR._unlockRegistered = true
    local MK = E.MakeUnlockElement
    E:RegisterUnlockElements({
        MK({
            key = "EABR_Reminders",
            label = "AuraBuff Reminders",
            group = "AuraBuff Reminders",
            order = 600,
            noAnchorTarget = true,
            noResize = true,
            getFrame = function() return EABR.iconAnchor end,
            getSize = function()
                local p = DDB()
                local sz = EABR.IconPixelSize()
                local spacing = p.iconSpacing or 8
                local count = #EABR.activeIcons
                if count < 1 then count = 2 end
                local w = count * sz + (count - 1) * spacing
                local h = sz + (p.showText and ((p.textSize or 11) + abs(p.textYOffset or -2)) or 0)
                if EABR.iconAnchor and not InCombatLockdown() then EABR.iconAnchor:SetSize(w, h) end
                return w, h
            end,
            savePos = function(_, point, relPoint, x, y)
                local p = DB()
                local growDir = p.display.growDirection
                if (growDir == "RIGHT" or growDir == "LEFT") and point == "CENTER" and relPoint == "CENTER" then
                    local halfW = (EABR.iconAnchor and EABR.iconAnchor:GetWidth() or 0) / 2
                    if growDir == "RIGHT" then point, x = "LEFT", x - halfW else point, x = "RIGHT", x + halfW end
                end
                p.unlockPos = { point = point, relPoint = relPoint, x = x, y = y }
                if not E._unlockActive then EABR.ApplyUnlockPos() end
            end,
            loadPos = function()
                local pos = DB().unlockPos
                if not pos or (pos.point ~= "LEFT" and pos.point ~= "RIGHT") or pos.relPoint ~= "CENTER" then
                    return pos
                end
                local halfW = (EABR.iconAnchor and EABR.iconAnchor:GetWidth() or 0) / 2
                return { point = "CENTER", relPoint = "CENTER",
                    x = (pos.x or 0) + ((pos.point == "LEFT") and halfW or -halfW), y = pos.y or 0 }
            end,
            loadRawPos = function() return DB().unlockPos end,
            saveRawPos = function(_, pos)
                if not (pos and pos.point) then return end
                DB().unlockPos = { point = pos.point, relPoint = pos.relPoint or pos.point, x = pos.x, y = pos.y }
                EABR.UpdateUnlockPosForGrowDir(DB().display.growDirection)
            end,
            clearPos = function() DB().unlockPos = nil end,
            applyPos = function() EABR.ApplyUnlockPos() end,
        }),
    })
end
