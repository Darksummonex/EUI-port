-- EllesmereUIDataBars 3.3.5: XP / reputation bar block (port of Retail Blocks\XPRep.lua).
-- Wrath has no paragon, renown, friendship or major factions: the watched
-- faction comes from GetWatchedFactionInfo() and XP from UnitXP/UnitXPMax.
-- settings.mode stays "auto" / "xp" / "rep" (legacy "reputation" reads as
-- "rep") so ns.ResolveProgressMode and the ActionBars HUD hand-off agree.
local _, ns = ...
if not ns.IsWrath then return end
local L = ns.L
local K = ns.BlockKit

local CreateFrame      = CreateFrame
local InCombatLockdown = InCombatLockdown
local type             = type
local floor            = math.floor
local max              = math.max
local min              = math.min
local Size, Solid      = ns.Size, ns.Solid

local CONTENT_BASE         = K.CONTENT_BASE
local InstKey              = K.InstKey
local MakeEventFrame       = K.MakeEventFrame
local RegisterInstEvents   = K.RegisterInstEvents
local UnregisterInstEvents = K.UnregisterInstEvents
local HBudget              = K.HBudget
local VSlotW               = K.VSlotW
local MaybeRelayout        = K.MaybeRelayout
local AttachTextOffset     = K.AttachTextOffset
local BlockColorOf         = K.BlockColorOf

local function MaxPlayerLevel()
    local t = MAX_PLAYER_LEVEL_TABLE
    local lvl = t and GetAccountExpansionLevel and t[GetAccountExpansionLevel()]
    if lvl and lvl > 0 then return lvl end
    if MAX_PLAYER_LEVEL and MAX_PLAYER_LEVEL > 0 then return MAX_PLAYER_LEVEL end
    return 80
end
local function XPAtMaxLevel() return (UnitLevel("player") or 0) >= MaxPlayerLevel() end
local function XPUserDisabled() return (IsXPUserDisabled and IsXPUserDisabled()) and true or false end

-------------------------------------------------------------------------------
--  XPREP (XP / Reputation bar)
-------------------------------------------------------------------------------
ns.BlockFactories.xprep = function(blockCfg, slot, content, barCtx)
    local inst = { cfg = blockCfg, slot = slot, content = content, ctx = barCtx }
    inst.key = InstKey(barCtx, blockCfg)
    inst.events = { "PLAYER_XP_UPDATE", "UPDATE_FACTION", "PLAYER_ENTERING_WORLD", "UPDATE_EXHAUSTION",
        "PLAYER_LEVEL_UP", "PLAYER_UPDATE_RESTING", "ENABLE_XP_GAIN", "DISABLE_XP_GAIN" }

    local mode = "rep"
    local lastMode

    local function D() return blockCfg.settings or {} end
    local function BC() return barCtx.cfg end
    local function StoredMode()
        local m = D().mode
        if m == "reputation" then m = "rep" end
        return m
    end

    local function UpdateMode()
        local m = StoredMode()
        if m == "xp" or m == "rep" then mode = m; return end
        mode = "rep"
        if not XPAtMaxLevel() and not XPUserDisabled() then mode = "xp" end
    end

    local function GetProgressValues(cur, minV, maxV)
        if type(minV) ~= "number" then minV = 0 end
        if type(maxV) ~= "number" then maxV = minV + 1 end
        if type(cur) ~= "number" then cur = minV end
        local pCur = cur - minV
        local pMax = maxV - minV
        if pMax <= 0 then
            local n = 1
            if pCur > 0 then n = pCur end
            return n, n, 100
        end
        return pCur, pMax, max(0, min(100, floor((pCur / pMax) * 100)))
    end

    local barButton = CreateFrame("Button", nil, content)
    barButton:SetAllPoints()
    barButton:EnableMouse(true)
    barButton:RegisterForClicks("AnyUp")
    barButton:SetScript("OnClick", function(_, btn)
        if btn == "RightButton" and not InCombatLockdown() then
            local d = D()
            if mode == "xp" then d.mode = "rep" else d.mode = "xp" end
            inst:Refresh()
        end
    end)
    local nameText = content:CreateFontString(nil, "OVERLAY")
    AttachTextOffset(inst, nameText)
    local barTrack = content:CreateTexture(nil, "BACKGROUND")
    -- Rested overlay sits one level under the fill so the fill always reads on top.
    local restBar = CreateFrame("StatusBar", nil, content)
    restBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    restBar:SetStatusBarColor(0.3, 0.3, 1, 0.5)
    restBar:SetFrameLevel(content:GetFrameLevel() + 1)
    restBar:Hide()
    local bar = CreateFrame("StatusBar", nil, content)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    bar:SetFrameLevel(content:GetFrameLevel() + 2)
    barButton:SetFrameLevel(content:GetFrameLevel() + 3)

    -- Shared value/label computation. Returns nil when nothing to show.
    local function ComputeState()
        UpdateMode()
        if mode == "xp" then
            -- An explicit "xp" mode must keep rendering at the cap: a collapsed
            -- block has no hitbox, so the right-click back to rep could never fire.
            local atMax = XPAtMaxLevel()
            local xpOff = XPUserDisabled()
            if atMax or xpOff then
                if StoredMode() ~= "xp" then return nil end
                return {
                    label = xpOff and "XP Off (Right-Click: Rep)" or "Max Level (Right-Click: Rep)",
                    minV = 0, maxV = 1, curV = 0,
                    r = 0.5, g = 0.5, b = 0.5, rested = 0,
                }
            end
            local curXP = UnitXP("player") or 0
            local maxXP = UnitXPMax("player") or 1
            if maxXP <= 0 then maxXP = 1 end
            local pct = floor((curXP / maxXP) * 100)
            local level = UnitLevel("player") or 0
            local ar, ag, ab = ns.GetAccent()
            return {
                label = pct .. "% to level " .. (level + 1), minV = 0, maxV = maxXP, curV = curXP,
                r = ar, g = ag, b = ab, rested = GetXPExhaustion() or 0, isXP = true,
            }
        end
        local name, reaction, minV, maxV, curV = GetWatchedFactionInfo()
        if not name then
            if StoredMode() ~= "rep" then return nil end
            return {
                label = "No Rep Tracked",
                minV = 0, maxV = 1, curV = 0,
                r = 0.5, g = 0.5, b = 0.5, rested = 0,
            }
        end
        if type(minV) == "number" and type(maxV) == "number" and type(curV) == "number" then
            local nMax = maxV - minV
            local nCur = curV - minV
            if nMax > 0 then minV = 0; maxV = nMax; curV = nCur end
        end
        if type(minV) ~= "number" then minV = 0 end
        if type(maxV) ~= "number" then maxV = 1 end
        if type(curV) ~= "number" then curV = 0 end
        if maxV <= minV then maxV = minV + 1 end
        curV = max(minV, min(maxV, curV))
        local _, _, pct = GetProgressValues(curV, minV, maxV)
        local dname = name
        if #name > 20 then dname = name:sub(1, 20) .. "..." end
        local cr, cg, cb
        local color = FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction]
        if color then cr, cg, cb = color.r, color.g, color.b
        else cr, cg, cb = ns.GetAccent() end
        return {
            label = dname .. " " .. pct .. "%", minV = minV, maxV = maxV, curV = curV,
            r = cr, g = cg, b = cb, rested = 0,
        }
    end

    barButton:SetScript("OnEnter", function()
        local state = ComputeState()
        if not state then return end
        local ar, ag, ab = ns.GetAccent()
        ns.Tip_Begin(barButton)
        ns.Tip_AddLine(state.label, 1, 1, 1)
        if state.maxV and state.maxV > 1 then
            ns.Tip_AddDouble(L["PROGRESS"], ns.GroupDigits(state.curV) .. " / " .. ns.GroupDigits(state.maxV),
                0.6, 0.6, 0.6, 1, 1, 1)
        end
        if state.rested and state.rested > 0 then
            ns.Tip_AddDouble(L["RESTED"], ns.GroupDigits(state.rested), 0.6, 0.6, 0.6, 0.3, 0.3, 1)
        end
        ns.Tip_AddLine(" ")
        ns.Tip_AddDouble(L["RIGHT_CLICK"], mode == "xp" and L["SWITCH_TO_REP"] or L["SWITCH_TO_XP"],
            1, 1, 1, ar, ag, ab)
        ns.Tip_Show()
    end)
    barButton:SetScript("OnLeave", function() ns.Tip_Hide(barButton) end)

    function inst:Refresh()
        local barCfg = BC()
        local barH = barCtx.GetThickness()
        local isSide = barCtx.IsVertical()
        local textHeight = max(9, floor(CONTENT_BASE * 0.4333 + 0.5))

        local state = ComputeState()
        -- The resolved mode drives the ActionBars HUD hand-off (ns.ProgressUsed).
        if lastMode ~= nil and lastMode ~= mode then ns.AfterBarStateChange() end
        lastMode = mode
        if not state then
            content:Hide()
            MaybeRelayout(inst)
            return
        end
        content:Show()
        inst._xpExtend = (state.isXP and 40) or 0

        do
            local br, bgr, bb = BlockColorOf(blockCfg)
            nameText:SetTextColor(br, bgr, bb, 1)
        end

        restBar:Hide()
        bar:SetStatusBarColor(state.r, state.g, state.b, 1)
        bar:SetMinMaxValues(state.minV, state.maxV)
        bar:SetValue(state.curV)
        if state.rested > 0 then
            restBar:SetMinMaxValues(state.minV, state.maxV)
            restBar:SetValue(min(state.curV + state.rested, state.maxV))
            restBar:Show()
        end

        if isSide then
            -- Vertical: label stacked above a thin horizontal bar.
            local slotW = VSlotW(inst)
            local innerW = max(24, slotW - 8)
            ns.SetFont(nameText, textHeight, barCfg)
            nameText:SetText(state.label)
            ns.SetWrappedText(nameText, innerW, "CENTER")
            nameText:ClearAllPoints()
            nameText:SetPoint("TOP", content, "TOP", 0, -3)
            local textH = ns.SnapToPixelGrid(nameText:GetStringHeight())
            local bH = 4
            barTrack:ClearAllPoints()
            barTrack:SetPoint("TOP", content, "TOP", 0, -(3 + textH + 3))
            Size(barTrack, innerW, bH)
            Solid(barTrack, 1, 1, 1, 0.1)
            bar:ClearAllPoints()
            Size(bar, innerW, bH)
            bar:SetPoint("TOP", content, "TOP", 0, -(3 + textH + 3))
            restBar:ClearAllPoints(); restBar:SetAllPoints(bar)
            Size(content, slotW, max(3 + textH + 3 + bH + 3, 40))
        else
            local slotW = HBudget(inst, 300)
            slotW = max(slotW, 60)
            local bH = max(2, floor(CONTENT_BASE * 0.2 + 0.5) - 1)

            -- Text on top, bar underneath sharing the left edge; the bar tracks the TEXT width.
            ns.SetFont(nameText, textHeight, barCfg)
            ns.ResetInlineText(nameText, "LEFT")
            nameText:SetText(state.label)

            local textW = nameText:GetStringWidth() or 0
            local maxTextW = max(20, slotW)
            if textW > maxTextW then
                textW = maxTextW
                nameText:SetWidth(textW)
            end
            if textW < 20 then textW = 20 end
            textW = ns.SnapToPixelGrid(textW)

            -- XP mode only: the bar runs 40px past the text's right edge.
            local barW = textW
            if state.isXP then barW = min(textW + 40, maxTextW) end

            local textH = ns.SnapToPixelGrid(nameText:GetStringHeight() or textHeight)
            local stackH = textH + 2 + bH
            local pad = max(0, floor((barH - stackH) / 2 + 0.5))
            Size(content, min(slotW, barW), barH)
            nameText:ClearAllPoints()
            nameText:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -pad)
            barTrack:ClearAllPoints()
            barTrack:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(pad + textH + 2))
            Size(barTrack, barW, bH)
            Solid(barTrack, 1, 1, 1, 0.1)
            bar:ClearAllPoints(); Size(bar, barW, bH)
            bar:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(pad + textH + 2))
            restBar:ClearAllPoints(); restBar:SetAllPoints(bar)
        end
        MaybeRelayout(inst)
    end

    inst.eventFrame = MakeEventFrame(inst, function(self)
        self:Refresh()
    end)

    function inst:Enable()
        content:Show()
        RegisterInstEvents(self)
    end

    function inst:Disable()
        UnregisterInstEvents(self)
        content:Hide()
    end

    function inst:GetAutoLength()
        if not content:IsShown() then return 0 end
        if barCtx.IsVertical() then
            return max(content:GetHeight() or 40, 40)
        end
        local tw = nameText:GetStringWidth() or 0
        if tw < 20 then tw = 120 end
        return tw + (self._xpExtend or 0)
    end

    function inst:Destroy()
        self._dead = true
        ns.Tip_Hide(barButton)
        content:Hide()
    end

    return inst
end
