-- Index-based Wrath auras. Retail aura containers are deliberately not loaded;
-- the lanes read the same saved keys (anchor/growth/per-row/spacing, crop and
-- zoom, aura border, dispel borders, duration and stack text) and lay out the
-- way the Retail containers do.
local _, ns = ...
local CreateFrame = ns.Wrath.CreateFrame
local entries = {}
ns.WrathAuraEntries=entries

local AURA_ZOOM, CROP_H = 0.07, 0.80
local SATED_DEBUFFS = { [57723] = true, [57724] = true, [81005] = true }
local ANCHOR_IA = {
    topleft = "BOTTOMLEFT", topright = "BOTTOMRIGHT",
    bottomleft = "TOPLEFT", bottomright = "TOPRIGHT",
    left = "RIGHT", right = "LEFT",
}
local ANCHOR_FP = {
    topleft = { "TOPLEFT", 0, 1 }, topright = { "TOPRIGHT", 0, 1 },
    bottomleft = { "BOTTOMLEFT", 0, -1 }, bottomright = { "BOTTOMRIGHT", 0, -1 },
    left = { "LEFT", -1, 0 }, right = { "RIGHT", 1, 0 },
}
local AUTO_GROWTH = {
    topleft = { "RIGHT", "UP" }, topright = { "LEFT", "UP" },
    bottomleft = { "RIGHT", "DOWN" }, bottomright = { "LEFT", "DOWN" },
    left = { "LEFT", "DOWN" }, right = { "RIGHT", "DOWN" },
}
local EXPLICIT_GROWTH = {
    right = { "RIGHT", "UP" }, left = { "LEFT", "UP" },
    up = { "RIGHT", "UP" }, down = { "RIGHT", "DOWN" },
}
local STACK_POINTS = {
    bottomright = { "BOTTOMRIGHT", -1 }, bottomleft = { "BOTTOMLEFT", 1 },
    topright = { "TOPRIGHT", -1 }, topleft = { "TOPLEFT", 1 },
    center = { "CENTER", 0 },
}
-- Priority order Magic > Curse > Disease > Poison (Wrath has no Bleed type).
local DISPEL_SLOTS = {
    { key = "Magic",   colorKey = "dispelColorMagic",   fallback = { 0.349, 0.475, 1.0 } },
    { key = "Curse",   colorKey = "dispelColorCurse",   fallback = { 0.636, 0.0, 0.64 } },
    { key = "Disease", colorKey = "dispelColorDisease", fallback = { 0.671, 0.384, 0.098 } },
    { key = "Poison",  colorKey = "dispelColorPoison",  fallback = { 0.0, 0.706, 0.286 } },
}
local STOCK_DISPEL = {
    none = { r = 0.8, g = 0, b = 0 }, Magic = { r = 0.2, g = 0.6, b = 1 },
    Curse = { r = 0.6, g = 0, b = 1 }, Disease = { r = 0.6, g = 0.4, b = 0 },
    Poison = { r = 0, g = 0.6, b = 0 },
}
-- Retail's type icons are Retail-only atlases; these are the Wrath dispel spells.
local DISPEL_ICONS = {
    Magic = "Interface\\Icons\\Spell_Holy_DispelMagic", Curse = "Interface\\Icons\\Spell_Nature_RemoveCurse",
    Disease = "Interface\\Icons\\Spell_Holy_NullifyDisease", Poison = "Interface\\Icons\\Spell_Nature_NullifyPoison",
}
ns.UF_WrathDispelIcons = DISPEL_ICONS
local GRADIENT_TEXTURE = "Interface\\AddOns\\EllesmereUI\\media\\textures\\gradient-tb.tga"
local GRADIENT_SHARP_TEXTURE = "Interface\\AddOns\\EllesmereUI\\media\\textures\\gradient-sharp.tga"
local CB_UNITS = { player = true, target = true, focus = true }
local CB_STRIP_SLACK = 8
-- Offensive Magic removal on 3.3.5 (Purge, Dispel Magic, Spellsteal,
-- Tranquilizing Shot, Felhunter Devour Magic).
local PURGE_CLASSES = { SHAMAN = true, PRIEST = true, MAGE = true, HUNTER = true, WARLOCK = true }
local PURGE_UNITS = { target = true, focus = true }

local function Settings(unit)
    return ns.UF_GetSettings and ns.UF_GetSettings(unit)
end
local function Profile()
    return ns.UF_GetProfile and ns.UF_GetProfile()
end
function ns.UF_DebuffFilterMode(s)
    local mode = s.debuffFilterMode or (s.onlyPlayerDebuffs and "own" or "all")
    -- Wrath exposes no Blizzard "important" classification.
    if mode ~= "tracked" and mode ~= "own" and mode ~= "raid" and mode ~= "raidOwn" then return "all" end
    return mode
end
function ns.UF_DebuffHasIncludes(s)
    for _, enabled in pairs(s.debuffInclude or {}) do if enabled then return true end end
    return false
end

-- Explicit either/or: a falsy setting must not fall through to the other key.
local function Pick(isBuff, a, b)
    if isBuff then return a end
    return b
end
local function Px(v)
    local PP = EllesmereUI.PP
    return (PP and PP.FromPixels) and PP.FromPixels(v) or v
end
local function Blizz() return ns.UF_Blizz and ns.UF_Blizz() or false end

local function ResolveLayout(anchor, growth)
    local ia = ANCHOR_IA[anchor] or "BOTTOMLEFT"
    local fp = ANCHOR_FP[anchor] or ANCHOR_FP.topleft
    local g
    if growth and growth ~= "auto" then g = EXPLICIT_GROWTH[growth] end
    g = g or AUTO_GROWTH[anchor] or AUTO_GROWTH.topleft
    return ia, fp[1], fp[2], fp[3], g[1], g[2]
end
local function ResolveColumns(growth, maxCount, maxPerRow)
    if maxPerRow and maxPerRow >= 1 and maxPerRow < maxCount then return maxPerRow end
    if growth == "up" or growth == "down" then return 1 end
    return nil
end

-- Blizzard-like countdown: bare seconds under a minute, then m/h/d; "Precise
-- Below" (stored in seconds) switches to m:ss under its threshold.
local function FormatDuration(rem, precision)
    if rem < 60 then return string.format("%d", math.ceil(rem)) end
    if precision and precision > 0 and rem < precision then
        local m = math.floor(rem / 60)
        return string.format("%d:%02d", m, math.floor(rem - m * 60))
    end
    if rem < 3600 then return string.format("%dm", math.ceil(rem / 60)) end
    if rem < 86400 then return string.format("%dh", math.ceil(rem / 3600)) end
    return string.format("%dd", math.ceil(rem / 86400))
end
ns.UF_WrathFormatAuraDuration = FormatDuration

-- Does the unit's cast bar sit in the strip directly below the frame (where a
-- bottom-anchored stack would go)? Mirrors the Retail geometry test.
local function CastbarBelowFrame(unit, frame)
    if not CB_UNITS[unit] then return true end
    local vb = 0
    if Blizz() and ns.UF_BlizzVis then
        local _, _, _, b = ns.UF_BlizzVis(frame)
        vb = b or 0
    end
    local cb = frame and frame.Castbar and frame.Castbar:GetParent()
    if not cb then return true end
    local fl, fr, fb = frame:GetLeft(), frame:GetRight(), frame:GetBottom()
    local cl, cr, ct, cbot = cb:GetLeft(), cb:GetRight(), cb:GetTop(), cb:GetBottom()
    if not (fl and fr and fb and cl and cr and ct and cbot) then return true end
    local fs, cs = frame:GetEffectiveScale(), cb:GetEffectiveScale()
    fl, fr, fb = fl * fs, fr * fs, (fb + vb) * fs
    cl, cr, ct, cbot = cl * cs, cr * cs, ct * cs, cbot * cs
    if cl >= fr or cr <= fl then return false end
    local h = ct - cbot
    if h <= 0 then h = 14 end
    local drop = fb - ct
    return drop < h and drop >= -CB_STRIP_SLACK
end
ns.UF_CastbarBelowFrame = CastbarBelowFrame
EllesmereUI.UF_CastbarBelowFrame = CastbarBelowFrame

-- Shared duration clock: one throttled OnUpdate for every visible countdown.
local timed = {}
local clock = CreateFrame("Frame")
clock:Hide()
local clockAcc = 0
local enchantExpired
clock:SetScript("OnUpdate", function(self, elapsed)
    clockAcc = clockAcc + (elapsed or 0)
    if clockAcc < 0.1 then return end
    clockAcc = 0
    local now, any = GetTime(), false
    for b in pairs(timed) do
        if b:IsShown() and b.expires then
            local rem = b.expires - now
            if rem > 0 then
                b.dur:SetText(FormatDuration(rem, b.precision))
            else
                b.dur:SetText("")
                if b.slot then enchantExpired = true end
            end
            any = true
        else
            timed[b] = nil
        end
    end
    if enchantExpired then
        enchantExpired = nil
        for frame, entry in pairs(entries) do
            if entry.unit == "player" then ns.UF_ReloadAuraContainers(frame, "player") end
        end
    end
    if not any then self:Hide() end
end)

local function OnEnter(self)
    if self.noTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
    if self.slot then GameTooltip:SetInventoryItem("player", self.slot)
    else GameTooltip:SetUnitAura(self.unit, self.index, self.filter) end
    GameTooltip:Show()
end
local function OnLeave() GameTooltip:Hide() end
-- Cancelling is restricted in combat on 3.3.5, exactly like the stock buff frame.
local function OnClick(self, button)
    if button ~= "RightButton" or not self.cancel or InCombatLockdown() then return end
    if self.slot then CancelItemTempEnchantment(self.slot == 16 and 1 or 2)
    else CancelUnitBuff(self.unit, self.index, self.filter) end
end

local function NewButton(parent)
    local b = CreateFrame("Button", nil, parent)
    b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetAllPoints(b); b.icon:SetTexCoord(.07,.93,.07,.93)
    b.cooldown = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate"); b.cooldown:SetAllPoints(b)
    if b.cooldown.SetReverse then b.cooldown:SetReverse(true) end
    b.border = CreateFrame("Frame", nil, b); b.border:SetAllPoints(b)
    b.glow = CreateFrame("Frame", nil, b); b.glow:SetAllPoints(b); b.glow:Hide()
    b.textFrame = CreateFrame("Frame", nil, b); b.textFrame:SetAllPoints(b)
    b.count = b.textFrame:CreateFontString(nil, "OVERLAY")
    b.dur = b.textFrame:CreateFontString(nil, "OVERLAY")
    b:SetScript("OnEnter", OnEnter)
    b:SetScript("OnLeave", OnLeave)
    b:SetScript("OnClick", OnClick)
    return b
end

local function ApplyFont(fs, path, size)
    if EllesmereUI.ApplyIconTextFont then EllesmereUI.ApplyIconTextFont(fs, path, size, "unitFrames")
    else fs:SetFont(path, size, "OUTLINE") end
end

-- Target/focus Purgeable Buff Glow spec from the Retail buffPurgeGlow* keys
-- (nil = off); the options preview draws with the same spec.
function ns.UF_PurgeGlowSpec(s)
    local G = EllesmereUI.Glows
    local g = s and s.buffPurgeGlow
    if not (G and G.StartSpecGlow and type(g) == "number" and g > 0) then return nil end
    local c, bgc = s.buffPurgeGlowColor, s.buffPurgeGlowBackgroundColor
    local spec = { style = g, lines = s.buffPurgeGlowLines,
        thickness = s.buffPurgeGlowThickness, speed = s.buffPurgeGlowSpeed }
    spec.r, spec.g, spec.b = G.ResolveColor(s.buffPurgeGlowColorMode or (c and "custom" or "default"),
        c and c.r, c and c.g, c and c.b)
    if s.buffPurgeGlowBackground == true then
        spec.bg, spec.bgR, spec.bgG, spec.bgB = true, bgc and bgc.r or 0, bgc and bgc.g or 0, bgc and bgc.b or 0
    end
    return spec
end
function ns.UF_WrathCanPurge()
    local _, class = UnitClass("player")
    return PURGE_CLASSES[class] == true
end

-- Per-paint style for a lane (pure function of the settings).
local function BuildStyle(unit, isBuff, s, simpleOn, size, h, cropped)
    local p = Pick(isBuff, "buff", "debuff")
    local cap = p:gsub("^%l", string.upper)
    local showKey, sizeKey, sizeDef = p .. "ShowCooldownText", p .. "CooldownTextSize", 10
    if simpleOn then
        showKey, sizeKey, sizeDef = "simple" .. cap .. "ShowCooldownText", "simple" .. cap .. "CooldownTextSize", 14
    end
    local blizz = Blizz()
    local st = {
        w = size, h = h,
        zoom = blizz and 0 or (Pick(isBuff, s.buffIconZoom, s.debuffIconZoom) or AURA_ZOOM),
        cropped = cropped,
        showDur = s[showKey] == true, durSize = s[sizeKey] or sizeDef,
        durColor = s[p .. "CooldownTextColor"],
        durX = s[p .. "CooldownTextOffsetX"] or 0, durY = s[p .. "CooldownTextOffsetY"] or 0,
        precision = tonumber(s[p .. "CooldownTextPrecision"]),
        stackSize = s[p .. "StackTextSize"] or 14, stackColor = s[p .. "StackTextColor"],
        stackPos = s[p .. "StackTextPosition"] or "bottomright",
        stackX = s[p .. "StackTextOffsetX"] or 0, stackY = s[p .. "StackTextOffsetY"] or 0,
        noTooltip = s.showAuraTooltips == false,
        cancel = unit == "player" and isBuff,
        font = (EllesmereUI.GetFontPath and EllesmereUI.GetFontPath("unitFrames")) or STANDARD_TEXT_FONT,
    }
    if blizz then
        st.borderSize = isBuff and 0 or 1
        st.br, st.bgc, st.bb, st.ba = 0, 0, 0, 1
        st.borderTex = "solid"
        st.dispel = not isBuff
        st.stockDispel = true
    else
        st.borderSize = s.auraBorderSize or 1
        st.br, st.bgc, st.bb, st.ba = s.auraBorderR or 0, s.auraBorderG or 0, s.auraBorderB or 0, s.auraBorderA or 1
        st.borderTex = s.auraBorderTexture or "solid"
        st.edgePx = EllesmereUI.BorderPx and EllesmereUI.BorderPx(s.auraBorderSizePx, st.borderSize, st.borderTex)
        st.offX, st.offY = s.auraBorderTextureOffset, s.auraBorderTextureOffsetY
        st.shX, st.shY = s.auraBorderTextureShiftX, s.auraBorderTextureShiftY
        st.dispel = (not isBuff and s.debuffDispelBorder == true)
            or (isBuff and unit ~= "player" and s.buffDispelBorder == true)
        if st.dispel and not isBuff and unit == "player" and s.debuffDispelUsePalette == true then
            st.palette = Profile()
        end
        if st.dispel then
            if s.auraBorderDispelTextured == true and st.borderTex ~= "solid" and st.borderTex ~= "" then
                st.dispelTex, st.dispelEdgePx = st.borderTex, st.edgePx
            else
                st.dispelTex = "solid"
                st.dispelEdgePx = EllesmereUI.BorderPx and EllesmereUI.BorderPx(s.auraBorderSizePx, st.borderSize, "solid")
            end
        end
        st.behind, st.behindUF = s.auraBorderBehind == true, s.auraBorderBehindUnitFrame == true
    end
    if isBuff and PURGE_UNITS[unit] then st.purge = ns.UF_PurgeGlowSpec(s) end
    st.fp = table.concat({ st.w, st.h, st.zoom, tostring(cropped), st.durSize, st.durX, st.durY,
        st.stackSize, st.stackPos, st.stackX, st.stackY, st.font,
        st.durColor and (st.durColor.r .. "," .. st.durColor.g .. "," .. st.durColor.b) or "-",
        st.stackColor and (st.stackColor.r .. "," .. st.stackColor.g .. "," .. st.stackColor.b) or "-" }, "|")
    return st
end

local function DispelColor(st, dtype)
    if st.stockDispel then
        local t = DebuffTypeColor or STOCK_DISPEL
        local c = t[dtype or "none"] or t.none or STOCK_DISPEL.none
        return c.r, c.g, c.b
    end
    if not dtype then return nil end
    for i = 1, #DISPEL_SLOTS do
        local slot = DISPEL_SLOTS[i]
        if slot.key == dtype then
            local c = st.palette and st.palette[slot.colorKey]
            if c then return c.r, c.g, c.b end
            local t = DebuffTypeColor and DebuffTypeColor[dtype]
            if t and not st.palette then return t.r, t.g, t.b end
            return slot.fallback[1], slot.fallback[2], slot.fallback[3]
        end
    end
end

local function PaintBorder(b, st, dtype)
    local size, r, g, bl, a = st.borderSize, st.br, st.bgc, st.bb, st.ba
    local tex, edgePx = st.borderTex, st.edgePx
    if st.dispel then
        local dr, dg, db = DispelColor(st, dtype)
        if dr then
            r, g, bl, a = dr, dg, db, 1
            if size <= 0 then size = 1 end
            if st.dispelTex then tex, edgePx = st.dispelTex, st.dispelEdgePx end
        end
    end
    local key = size .. "|" .. r .. "|" .. g .. "|" .. bl .. "|" .. a .. "|" .. tex .. "|" .. tostring(edgePx)
        .. "|" .. tostring(st.offX) .. "|" .. tostring(st.offY) .. "|" .. tostring(st.shX) .. "|" .. tostring(st.shY)
    if b._bdKey == key then return end
    b._bdKey = key
    if size <= 0 then
        local PP = EllesmereUI.PP
        if PP and PP.GetBorders and PP.GetBorders(b.border) then PP.HideBorder(b.border) end
        b.border:Hide()
        return
    end
    b.border:Show()
    EllesmereUI.ApplyBorderStyle(b.border, size, r, g, bl, a, tex, st.offX, st.offY,
        st.shX, st.shY, "unitframes", size, nil, edgePx)
end

local function PaintPurge(b, st, purgeable)
    if not (st.purge and purgeable) then b.glow:Hide(); return end
    b.glow:Show()
    EllesmereUI.Glows.StartSpecGlow(b.glow, st.purge, st.w, st.h, "icon")
end

local function StyleButton(b, st)
    b:SetSize(st.w, st.h)
    if ns.SetAuraIconCrop then ns.SetAuraIconCrop(b.icon, st.cropped, st.w, st.h, st.zoom)
    else b.icon:SetTexCoord(st.zoom, 1 - st.zoom, st.zoom, 1 - st.zoom) end
    local lvl = b:GetFrameLevel()
    if st.behindUF then b.border:SetFrameLevel(0)
    elseif st.behind then b.border:SetFrameLevel(math.max(0, lvl - 1))
    else b.border:SetFrameLevel(lvl + 2) end
    b.glow:SetFrameLevel(lvl + 3)
    b.textFrame:SetFrameLevel(lvl + 4)
    b.noTooltip, b.cancel, b.precision = st.noTooltip, st.cancel, st.precision
    b:EnableMouse(not st.noTooltip or st.cancel)
    if st.cancel then b:RegisterForClicks("RightButtonUp") else b:RegisterForClicks() end
    if b._styleFP == st.fp then return end
    b._styleFP = st.fp
    ApplyFont(b.dur, st.font, st.durSize)
    local c = st.durColor
    b.dur:SetTextColor(c and c.r or 1, c and c.g or 1, c and c.b or 1)
    b.dur:ClearAllPoints()
    b.dur:SetPoint("CENTER", b, "CENTER", st.durX, st.durY)
    ApplyFont(b.count, st.font, st.stackSize)
    c = st.stackColor
    b.count:SetTextColor(c and c.r or 1, c and c.g or 1, c and c.b or 1)
    local sp = STACK_POINTS[st.stackPos] or STACK_POINTS.bottomright
    b.count:ClearAllPoints()
    b.count:SetPoint(sp[1], b, sp[1], sp[2] + st.stackX, st.stackY)
end

local function FillButton(b, st, icon, count, dtype, duration, expires, purgeable)
    b.icon:SetTexture(icon)
    b.count:SetText(count and count > 1 and count or "")
    if duration and duration > 0 and expires then
        b.cooldown:SetCooldown(expires - duration, duration); b.cooldown:Show()
    else b.cooldown:Hide() end
    b.expires = expires and expires > 0 and expires or nil
    if st.showDur and b.expires then
        b.dur:Show()
        b.dur:SetText(FormatDuration(math.max(0, b.expires - GetTime()), b.precision))
        timed[b] = true
        clock:Show()
    else
        b.dur:SetText(""); b.dur:Hide()
        timed[b] = nil
    end
    PaintBorder(b, st, dtype)
    PaintPurge(b, st, purgeable)
    b:Show()
end

-- Weapon enchants lead the player's buff run in the broad (All) mode, as the
-- Retail item-enchantment group does.
local function CollectEnchants(lane, st)
    local list = lane.enchants
    local n = 0
    if not GetWeaponEnchantInfo then return 0 end
    local hasMain, mainExp, mainCharges, hasOff, offExp, offCharges = GetWeaponEnchantInfo()
    local now = GetTime()
    for _, e in ipairs({ { hasMain, mainExp, mainCharges, 16 }, { hasOff, offExp, offCharges, 17 } }) do
        if e[1] then
            n = n + 1
            local b = list[n]
            if not b then b = NewButton(lane); list[n] = b end
            b.slot, b.unit, b.index, b.filter = e[4], "player", nil, nil
            StyleButton(b, st)
            FillButton(b, st, GetInventoryItemTexture("player", e[4]), e[3], nil, nil, e[2] and now + e[2] / 1000)
        end
    end
    for i = n + 1, #list do list[i]:Hide(); timed[list[i]] = nil end
    return n
end

local function HideLane(lane)
    lane:Hide()
    for _, b in ipairs(lane.buttons) do timed[b] = nil end
    for _, b in ipairs(lane.enchants) do timed[b] = nil end
end

local function PointBlizzAuraBlock(frame, unit, s, isBuff, lane, ia, xOff, merged, gY)
    if not (CB_UNITS[unit] and ns.UF_BlizzAuraBlock and ns.UF_BlizzAuraBlock(frame)) then return end
    local dA, bA = s.debuffAnchor or "none", s.buffAnchor or "topleft"
    local dBottom = (dA == "bottomleft" or dA == "bottomright")
    local bBottom = (bA == "bottomleft" or bA == "bottomright") and s.showBuffs ~= false
    local lowestIsBuff
    if merged then
        if dBottom then lowestIsBuff = (gY == "UP") end
    elseif dBottom then lowestIsBuff = false
    elseif bBottom then lowestIsBuff = true end
    if lowestIsBuff == nil then
        ns.UF_BlizzAuraBlockBottom(frame, nil)
    elseif lane and lowestIsBuff == isBuff then
        local corner = (ia and ia:find("RIGHT", 1, true)) and "BOTTOMRIGHT" or "BOTTOMLEFT"
        ns.UF_BlizzAuraBlockBottom(frame, lane, corner, -(xOff or 0))
    end
end

local function PaintLane(entry, isBuff, s)
    local frame = entry.frame
    local lane = isBuff and entry.buffs or entry.debuffs
    local unit = frame._euiUnit or entry.unit
    local isBoss = (entry.unit or unit or ""):match("^boss") ~= nil
    local prefix = Pick(isBuff, "buff", "debuff")
    local simpleMode = "none"
    if isBoss then
        if isBuff then simpleMode = ns.GetBossSimpleBuffMode and ns.GetBossSimpleBuffMode(s) or "none"
        else simpleMode = ns.GetBossSimpleDebuffMode and ns.GetBossSimpleDebuffMode(s) or "none" end
    end
    local simpleOn = simpleMode ~= "none"
    local merged = s.debuffAnchorBuffs == true and not isBoss and (s.debuffAnchor or "none") ~= "none"
    local mergedBuff = merged and isBuff
    local shown
    if isBuff then shown = (s.showBuffs ~= false) or simpleOn or merged
    else shown = ((s.debuffAnchor or "none") ~= "none") or simpleOn end
    local anchor = Pick(isBuff, s.buffAnchor, s.debuffAnchor)
    if anchor == nil then anchor = Pick(isBuff, "topleft", "none") end
    if mergedBuff then anchor = s.debuffAnchor end
    if not shown or (anchor == "none" and not simpleOn) then
        if not merged then PointBlizzAuraBlock(frame, unit, s, isBuff, nil, nil, nil, merged, nil) end
        HideLane(lane); return
    end
    local cap = math.min(40, Pick(isBuff, s.maxBuffs or 4, s.maxDebuffs or 28))
    if cap <= 0 then HideLane(lane); return end

    local size = Pick(isBuff, s.buffSize, s.debuffSize) or 22
    if simpleOn then
        local pp = s.powerPosition or "below"
        local powerH = (pp == "below" or pp == "above") and (s.powerHeight or 0) or 0
        local PP = EllesmereUI.PP
        size = (PP and PP.Scale) and PP.Scale((s.healthHeight or 0) + powerH) or ((s.healthHeight or 0) + powerH)
        if size <= 0 then size = frame:GetHeight() end
    end
    local cropped = Pick(isBuff, s.buffCropIcons, s.debuffCropIcons) and true or false
    local h = cropped and math.floor(size * CROP_H + 0.5) or size
    local spX, spY
    if isBoss and ns.GetBossBuffSpacing then
        local sp = isBuff and ns.GetBossBuffSpacing(s, simpleOn) or ns.GetBossDebuffSpacing(s, simpleOn)
        spX = Px(sp or 1); spY = spX
    else
        spX = Px(Pick(isBuff, s.buffSpacingX, s.debuffSpacingX) or 1)
        spY = Px(Pick(isBuff, s.buffSpacingY, s.debuffSpacingY) or 1)
    end

    local growth = Pick(isBuff, s.buffGrowth, s.debuffGrowth)
    if simpleOn then growth = "auto" end
    if mergedBuff then growth = s.debuffGrowth end
    local ia, fp, ox, oy, gX, gY, offX, offY
    if simpleOn then
        if simpleMode == "right" then ia, fp, gX = "TOPLEFT", "TOPRIGHT", "RIGHT"
        else ia, fp, gX = "TOPRIGHT", "TOPLEFT", "LEFT" end
        gY, ox, oy = "DOWN", 0, 0
        if isBuff then offX, offY = ns.GetBossSimpleBuffOffset(s) else offX, offY = ns.GetBossSimpleDebuffOffset(s) end
    else
        ia, fp, ox, oy, gX, gY = ResolveLayout(anchor, growth)
        local vl, vr, vt, vb
        if ns.UF_BlizzVis then vl, vr, vt, vb = ns.UF_BlizzVis(frame) end
        if vl then
            if anchor == "topleft" or anchor == "bottomleft" or anchor == "left" then ox = ox + vl
            elseif anchor == "topright" or anchor == "bottomright" or anchor == "right" then ox = ox - vr end
            if anchor == "topleft" or anchor == "topright" then oy = oy - vt
            elseif anchor == "bottomleft" or anchor == "bottomright" then oy = oy + vb end
        end
        local showCb, cbH
        if unit == "player" then showCb, cbH = s.showPlayerCastbar, s.playerCastbarHeight
        else showCb, cbH = s.showCastbar, s.castbarHeight end
        if showCb and (anchor == "bottomleft" or anchor == "bottomright")
            and not (vl and CB_UNITS[unit]) and CastbarBelowFrame(unit, frame) then
            if not cbH or cbH <= 0 then cbH = 14 end
            oy = oy - cbH
        end
        offX = Pick(isBuff, s.buffOffsetX, s.debuffOffsetX) or 0
        offY = Pick(isBuff, s.buffOffsetY, s.debuffOffsetY) or 0
        if mergedBuff then offX, offY = s.debuffOffsetX or 0, s.debuffOffsetY or 0 end
    end

    local st = BuildStyle(unit, isBuff, s, simpleOn, size, h, cropped)
    local filter = isBuff and "HELPFUL" or "HARMFUL"
    local mode = ns.UF_DebuffFilterMode(s)
    local Filters = EllesmereUI.WrathAuraFilters
    local nEnch = 0
    local buffMode = (Filters and Filters.Mode) and Filters.Mode(s, "buff") or (s.onlyPlayerBuffs and "own" or "all")
    local canPurge = st.purge and UnitCanAttack("player", unit)
    local purgeClass = canPurge and ns.UF_WrathCanPurge()
    if unit == "player" and isBuff and buffMode == "all" then
        nEnch = CollectEnchants(lane, st)
    else
        for _, b in ipairs(lane.enchants) do b:Hide(); timed[b] = nil end
    end
    local shownCount = 0
    for index = 1, 40 do
        local name, _, icon, count, dtype, duration, expires, caster, stealable, _, spellID = UnitAura(unit, index, filter)
        if not name then break end
        local mine = caster == "player" or caster == "pet" or caster == "vehicle"
        local include, excluded
        if Filters then
            include = Filters.Allow(s, prefix, spellID, mine, duration, stealable, name)
        else
            local tracked = not isBuff and s.debuffInclude and (s.debuffInclude[spellID] or s.debuffInclude[tostring(spellID)])
            excluded = not isBuff and s.debuffExclude and (s.debuffExclude[spellID] or s.debuffExclude[tostring(spellID)])
            include = isBuff or mode == "all" or (mode == "own" and mine) or tracked
            if isBuff and s.onlyPlayerBuffs and not mine then include = false end
            if isBuff and s.buffStealable and not stealable then include = false end
            if isBuff and s.buffHasDuration and (not duration or duration <= 0) then include = false end
        end
        if not isBuff and s.debuffHideExhaustion ~= false and SATED_DEBUFFS[spellID] then include = false end
        if isBuff and unit ~= "player" and s.buffDurOnly == true and (not duration or duration <= 0) then include = false end
        if include and not excluded and shownCount < cap then
            shownCount = shownCount + 1
            local b = lane.buttons[shownCount]
            if not b then b = NewButton(lane); lane.buttons[shownCount] = b end
            b.unit, b.index, b.filter, b.slot = unit, index, filter, nil
            StyleButton(b, st)
            FillButton(b, st, icon, count, dtype, duration, expires,
                canPurge and (stealable or (purgeClass and dtype == "Magic")))
        end
    end
    for i = shownCount + 1, #lane.buttons do lane.buttons[i]:Hide(); timed[lane.buttons[i]] = nil end

    local total = nEnch + shownCount
    local cols = ResolveColumns(growth, cap, Pick(isBuff, s.buffMaxPerRow, s.debuffMaxPerRow)) or math.max(1, total)
    local corner = (gY == "UP" and "BOTTOM" or "TOP") .. (gX == "RIGHT" and "LEFT" or "RIGHT")
    local dx, dy = (gX == "RIGHT") and 1 or -1, (gY == "UP") and 1 or -1
    local slot = 0
    local function Place(b)
        local col, row = slot % cols, math.floor(slot / cols)
        b:ClearAllPoints()
        b:SetPoint(corner, lane, corner, dx * col * (st.w + spX), dy * row * (st.h + spY))
        slot = slot + 1
    end
    -- Main hand next to the aura run, as the Retail Slot/Reverse order does.
    for i = nEnch, 1, -1 do Place(lane.enchants[i]) end
    for i = 1, shownCount do Place(lane.buttons[i]) end
    local usedCols = math.max(1, math.min(total, cols))
    local rows = math.max(1, math.ceil(total / cols))
    lane:SetSize(usedCols * st.w + (usedCols - 1) * spX, rows * st.h + (rows - 1) * spY)

    lane:ClearAllPoints()
    local buffs = entry.buffs
    if merged and not isBuff and buffs:IsShown() then
        local horiz = ia:find("LEFT") and "LEFT" or (ia:find("RIGHT") and "RIGHT" or "")
        local vert, relVert, gapSign
        if gY == "UP" then vert, relVert, gapSign = "BOTTOM", "TOP", 1
        else vert, relVert, gapSign = "TOP", "BOTTOM", -1 end
        lane:SetPoint(vert .. horiz, buffs, relVert .. horiz, 0, Px(s.debuffSpacingY or 1) * gapSign)
    else
        lane:SetPoint(ia, frame, fp, ox + offX, oy + offY)
    end
    local visible = total > 0 and UnitExists(unit)
    lane:SetShown(visible)
    if not simpleOn then PointBlizzAuraBlock(frame, unit, s, isBuff, visible and lane or nil, ia, ox + offX, merged, gY) end
end

-------------------------------------------------------------------------------
--  Player Dispel Overlay: the highest-priority dispellable debuff tints the
--  health bar (fill / full / gradient / sharp gradient) and can copy the
--  player border in its colour. "By me" uses Wrath's HARMFUL|RAID filter,
--  which lists only debuffs the player can dispel.
-------------------------------------------------------------------------------
local function DispelState(entry)
    local d = entry.dispel
    if d then return d end
    local frame = entry.frame
    local host = CreateFrame("Frame", nil, frame.Health or frame)
    host:SetAllPoints(frame.Health or frame)
    local tex = host:CreateTexture(nil, "ARTWORK")
    local bd = CreateFrame("Frame", nil, frame)
    bd:SetAllPoints(frame.unifiedBorder or frame)
    local iconHost = CreateFrame("Frame", nil, frame.Health or frame)
    iconHost:SetAllPoints(frame.Health or frame)
    local icon = iconHost:CreateTexture(nil, "OVERLAY")
    icon:SetTexCoord(.08, .92, .08, .92)
    icon:Hide()
    d = { host = host, tex = tex, border = bd, iconHost = iconHost, icon = icon }
    entry.dispel = d
    return d
end

local function HideDispel(d)
    if not d then return end
    d.tex:Hide()
    d.icon:Hide()
    if d.borderOn then
        EllesmereUI.ApplyBorderStyle(d.border, 0, 0, 0, 0, 0, "solid")
        d.border:Hide()
        d.borderOn = nil
    end
    d.type = nil
end

local function PaintDispel(entry)
    local p = Profile()
    local frame = entry.frame
    if not (p and frame and frame.Health) then return end
    local mode = p.dispelOverlay or "none"
    local cbOn = p.dispelCustomBorder == true and ns.UF_CustomBorderOn and ns.UF_CustomBorderOn(p.player)
    local iconOn = p.showDispelIcons == true
    if mode == "none" and not cbOn and not iconOn then HideDispel(entry.dispel); return end
    local filter = (p.dispelOverlayByMe == true) and "HARMFUL|RAID" or "HARMFUL"
    local best
    for i = 1, 40 do
        local name, _, _, _, dtype = UnitAura("player", i, filter)
        if not name then break end
        for r = 1, best and best - 1 or #DISPEL_SLOTS do
            if DISPEL_SLOTS[r].key == dtype then best = r; break end
        end
        if best == 1 then break end
    end
    local d = DispelState(entry)
    if not best then HideDispel(d); return end
    local slot = DISPEL_SLOTS[best]
    local c = p[slot.colorKey]
    local r, g, b = c and c.r or slot.fallback[1], c and c.g or slot.fallback[2], c and c.b or slot.fallback[3]
    local alpha = (p.dispelOverlayOpacity or 100) / 100
    local health, tex = frame.Health, d.tex
    d.host:SetFrameLevel(health:GetFrameLevel() + 1)
    tex:ClearAllPoints()
    if mode == "none" then
        tex:Hide()
    elseif mode == "gradient" or mode == "gradient_sharp" then
        tex:SetAllPoints(health)
        tex:SetTexture(mode == "gradient_sharp" and GRADIENT_SHARP_TEXTURE or GRADIENT_TEXTURE)
        tex:SetVertexColor(r, g, b, alpha)
        tex:Show()
    else
        local fill = mode == "fill" and health.GetStatusBarTexture and health:GetStatusBarTexture()
        tex:SetAllPoints(fill or health)
        tex:SetColorTexture(r, g, b, alpha)
        tex:SetVertexColor(1, 1, 1, 1)
        tex:Show()
    end
    -- Type Icon Position: the dispel type's icon on a point of the health bar.
    if iconOn then
        local icon, size = d.icon, math.max(8, math.min(48, tonumber(p.dispelIconSize) or 16))
        local point = (p.dispelIconPosition or "right"):upper()
        d.iconHost:SetFrameLevel(health:GetFrameLevel() + 5)
        icon:ClearAllPoints()
        icon:SetSize(size, size)
        icon:SetPoint(point, health, point, p.dispelIconOffsetX or 0, p.dispelIconOffsetY or 0)
        icon:SetTexture(DISPEL_ICONS[slot.key])
        icon:Show()
    else
        d.icon:Hide()
    end
    if cbOn then
        local s = p.player
        local bs, btex = s.borderSize or 1, s.borderTexture
        local ub = frame.unifiedBorder or frame
        d.border:ClearAllPoints()
        d.border:SetAllPoints(ub)
        d.border:SetFrameLevel(ub:GetFrameLevel() + 1)
        EllesmereUI.ApplyBorderStyle(d.border, bs, r, g, b, 1, btex, s.borderTextureOffset, s.borderTextureOffsetY,
            s.borderTextureShiftX, s.borderTextureShiftY, "unitframes", bs, nil,
            EllesmereUI.BorderPx and EllesmereUI.BorderPx(s.borderSizePx, bs, btex))
        d.border:Show()
        d.borderOn = true
    elseif d.borderOn then
        EllesmereUI.ApplyBorderStyle(d.border, 0, 0, 0, 0, 0, "solid")
        d.border:Hide()
        d.borderOn = nil
    end
    d.type = slot.key
end

function ns.UF_ReloadPlayerDispelSlots()
    for _, entry in pairs(entries) do
        if entry.unit == "player" then PaintDispel(entry) end
    end
end

function ns.UF_ReloadAuraContainers(frame, unit)
    local entry = entries[frame]
    local s = entry and Settings(unit or entry.unit)
    if not s then return end
    for _,prefix in ipairs({"buff","debuff"}) do
        local lane=prefix=="buff" and entry.buffs or entry.debuffs
        if s[prefix.."IndicatorMode"] then
            HideLane(lane)
            local kind=GetNumRaidMembers()>0 and "raid" or GetNumPartyMembers()>0 and "party" or "solo"
            EllesmereUI.WrathAuraIndicators.Render(entry.indicators[prefix],frame.Health or frame,s,prefix,frame._euiUnit or entry.unit,kind,frame:GetWidth(),frame:GetHeight())
        else
            for _,a in ipairs(entry.indicators[prefix]) do a:Hide(); a.unit=nil end
            PaintLane(entry,prefix=="buff",s)
        end
    end
    if entry.unit == "player" then PaintDispel(entry) end
end
function ns.UF_HideAuraContainers(frame)
    local entry = entries[frame]
    if entry then
        HideLane(entry.buffs); HideLane(entry.debuffs)
        for _,pool in pairs(entry.indicators) do for _,a in ipairs(pool) do a:Hide() end end
        HideDispel(entry.dispel)
    end
end
function ns.UF_ReloadAllAuraContainers()
    for frame, entry in pairs(entries) do ns.UF_ReloadAuraContainers(frame, entry.unit) end
end
function ns.UF_CreateAuraContainers(frame, unit)
    if entries[frame] then return ns.UF_ReloadAuraContainers(frame, unit) end
    local buffs, debuffs = CreateFrame("Frame", nil, frame), CreateFrame("Frame", nil, frame)
    buffs.buttons, debuffs.buttons = {}, {}
    buffs.enchants, debuffs.enchants = {}, {}
    local indicators={buff={},debuff={}}
    for _,pool in pairs(indicators) do for i=1,8 do pool[i]=EllesmereUI.WrathAuraIndicators.NewIcon(frame) end end
    entries[frame] = { frame=frame, unit=unit, buffs=buffs, debuffs=debuffs,indicators=indicators }
    frame:HookScript("OnShow", function(f) ns.UF_ReloadAuraContainers(f, unit) end)
    ns.UF_ReloadAuraContainers(frame, unit)
end
local watcher = CreateFrame("Frame")
watcher:RegisterEvent("UNIT_AURA")
watcher:RegisterEvent("UNIT_INVENTORY_CHANGED")
watcher:RegisterEvent("PLAYER_TARGET_CHANGED")
watcher:RegisterEvent("PLAYER_FOCUS_CHANGED")
watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:RegisterEvent("PARTY_MEMBERS_CHANGED")
watcher:RegisterEvent("RAID_ROSTER_UPDATE")
watcher:SetScript("OnEvent", function(_, event, token)
    if event == "UNIT_INVENTORY_CHANGED" then
        if token ~= "player" then return end
        token, event = "player", "UNIT_AURA"
    end
    for frame, entry in pairs(entries) do
        if frame:IsShown() and (event ~= "UNIT_AURA" or token == (frame._euiUnit or entry.unit)) then
            ns.UF_ReloadAuraContainers(frame, entry.unit)
        end
    end
end)
