-- EllesmereUIDataBars 3.3.5: talent specialization block (port of Retail Blocks\Spec.lua).
-- Wrath has three talent trees and two talent groups (dual spec): the shown
-- "spec" is the tree with the most points in the active group. Switching
-- groups casts Activate Primary/Secondary Spec, which is protected, so the
-- Retail hover popup becomes the owned tooltip with secure spell rows
-- (ns.Tip_AddActionDouble; hidden in combat). No loot spec and no loadouts:
-- settings.showLoadout shows the dual-spec group label ("Primary"/"Secondary")
-- inline after the tree name instead.
local _, ns = ...
if not ns.IsWrath then return end
local E = EllesmereUI
local L = ns.L
local MEDIA = ns.MEDIA
local K = ns.BlockKit

local CreateFrame      = CreateFrame
local InCombatLockdown = InCombatLockdown
local floor            = math.floor
local max              = math.max
local min              = math.min
local tconcat          = table.concat
local Size             = ns.Size

local ICON_GAP             = K.ICON_GAP
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
local IconColorOf          = K.IconColorOf

local function Loc(text) if E and E.L then return E.L(text) end; return text end

-- Activate Primary Spec / Activate Secondary Spec, indexed by talent group.
local ACTIVATE_SPELLS = { 63645, 63644 }
local GROUP_LABELS = { "Primary", "Secondary" }
local NO_TALENTS = "No Talents"

-- One TGA per tree in Media_335\spec\, in talent-tab order per class.
local SPEC_MEDIA = MEDIA .. "spec\\"
local SPEC_ICON_FILES = {
    WARRIOR     = { "warrior-arms", "warrior-fury", "warrior-prot" },
    PALADIN     = { "paladin-holy", "paladin-prot", "paladin-ret" },
    HUNTER      = { "hunter-beastmaster", "hunter-marksman", "hunter-survival" },
    ROGUE       = { "rogue-assasin", "rogue-outlaw", "rogue-sub" },
    PRIEST      = { "priest-disc", "priest-holy", "priest-shadow" },
    DEATHKNIGHT = { "dk-blood", "dk-frost", "dk-unholy" },
    SHAMAN      = { "shaman-ele", "shaman-enhance", "shaman-resto" },
    MAGE        = { "mage-arcane", "mage-fire", "mage-frost" },
    WARLOCK     = { "warlock-aff", "warlock-demo", "warlock-destro" },
    DRUID       = { "druid-balance", "druid-feral", "druid-resto" },
}

-------------------------------------------------------------------------------
--  SPEC (dominant talent tree + dual-spec switching)
-------------------------------------------------------------------------------
ns.BlockFactories.spec = function(blockCfg, slot, content, barCtx)
    local inst = { cfg = blockCfg, slot = slot, content = content, ctx = barCtx }
    inst.key = InstKey(barCtx, blockCfg)
    inst.events = { "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_TALENT_UPDATE", "CHARACTER_POINTS_CHANGED",
        "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED" }

    -- groups[g] = { tab = dominant tab or nil, name, icon, points = { per tab } }
    local groups, numGroups, activeGroup = {}, 1, 1
    local mouseOver = false

    local function D() return blockCfg.settings or {} end
    local function BC() return barCtx.cfg end

    local function BuildSpecCache()
        numGroups = (GetNumTalentGroups and GetNumTalentGroups()) or 1
        if numGroups < 1 then numGroups = 1 end
        activeGroup = (GetActiveTalentGroup and GetActiveTalentGroup()) or 1
        local numTabs = (GetNumTalentTabs and GetNumTalentTabs()) or 3
        for g = 1, numGroups do
            local info = groups[g]
            if not info then info = { points = {} }; groups[g] = info end
            info.tab, info.name, info.icon = nil, nil, nil
            local best = 0
            for tab = 1, numTabs do
                local name, icon, pts = GetTalentTabInfo(tab, false, false, g)
                pts = pts or 0
                info.points[tab] = pts
                if pts > best then best, info.tab, info.name, info.icon = pts, tab, name, icon end
            end
            for tab = numTabs + 1, #info.points do info.points[tab] = nil end
        end
    end

    local function GroupText(g)
        local info = groups[g]
        return (info and info.name) or NO_TALENTS
    end

    local function GetBarDisplayText()
        local text = GroupText(activeGroup)
        if D().useUppercase == true then return text:upper() end
        return text
    end

    -- Dual-spec group label (stands in for Retail's loadout / loot-spec suffix).
    local function GetGroupSuffix()
        if D().showLoadout == false or numGroups < 2 then return nil end
        local label = Loc(GROUP_LABELS[activeGroup] or "")
        if label == "" then return nil end
        if D().useUppercase ~= false then label = label:upper() end
        return label
    end

    local specButton = CreateFrame("Button", nil, content)
    specButton:SetAllPoints()
    specButton:EnableMouse(true)
    specButton:RegisterForClicks("AnyUp")

    local specIcon = content:CreateTexture(nil, "OVERLAY"); Size(specIcon, 16, 16)
    local specText = content:CreateFontString(nil, "OVERLAY")
    local infoText = content:CreateFontString(nil, "OVERLAY"); infoText:Hide()
    AttachTextOffset(inst, specText)   -- infoText chains to specText

    -- Change-spec panel: one row per talent group; the inactive group is a
    -- secure Activate Spec cast, the active one is an accent informational row.
    local function ShowSpecTip()
        local ar, ag, ab = ns.GetAccent()
        ns.Tip_Begin(specButton)
        ns.Tip_MarkInteractive()
        ns.Tip_AddLine(L["CHANGE_SPEC"], 1, 1, 1)
        ns.Tip_AddLine(" ")
        for g = 1, numGroups do
            local info = groups[g]
            local left = GroupText(g)
            if info and info.icon then left = "|T" .. info.icon .. ":14:14|t " .. left end
            if numGroups > 1 then left = left .. "  |cff808080(" .. Loc(GROUP_LABELS[g] or "") .. ")|r" end
            local right = (info and #info.points > 0) and tconcat(info.points, " / ") or ""
            if g == activeGroup then
                ns.Tip_AddDouble(left, right, ar, ag, ab, 0.7, 0.7, 0.7)
                ns.Tip_PadRow()
            else
                ns.Tip_AddActionDouble(left, right, ACTIVATE_SPELLS[g], 1, 1, 1, 0.7, 0.7, 0.7)
            end
        end
        ns.Tip_AddLine(" ")
        if numGroups > 1 then
            if InCombatLockdown() then
                ns.Tip_AddLine(L["CANNOT_USE_COMBAT"], 1, 0.3, 0.3)
            else
                ns.Tip_AddDouble(L["LEFT_CLICK"], L["CHANGE_SPEC_SHORT"], 1, 1, 1, 1, 1, 1)
            end
        end
        ns.Tip_AddDouble(L["SHIFT_LEFT_CLICK"], L["OPEN_TALENTS"], 1, 1, 1, 1, 1, 1)
        ns.Tip_Show()
    end

    function inst:Refresh()
        -- No combat gate: only our own insecure frames (text, textures, sizes).
        local d = D()
        local barCfg = BC()
        local barH = barCtx.GetThickness()
        local fontSize = max(9, floor(CONTENT_BASE * 0.4333 + 0.5))
        local infoSz = max(8, floor(CONTENT_BASE * 0.36 + 0.5))
        local gap = 4
        local iconGap = ICON_GAP
        local ar, ag, ab = ns.GetAccent()
        local isSide = barCtx.IsVertical()
        local specLabel = GetBarDisplayText()
        local iconSz = fontSize + 8

        ns.SetFont(specText, fontSize, barCfg); ns.SetFont(infoText, infoSz, barCfg)
        specText:SetText(specLabel)

        local info = groups[activeGroup]
        local _, classId = UnitClass("player")
        local files = classId and SPEC_ICON_FILES[classId]
        local file = info and info.tab and files and files[info.tab]
        if file then
            specIcon:SetTexture(SPEC_MEDIA .. file)
            specIcon:SetTexCoord(0, 1, 0, 1)
        elseif info and info.icon then
            specIcon:SetTexture(info.icon)
            specIcon:SetTexCoord(4 / 64, 60 / 64, 4 / 64, 60 / 64)
        else
            specIcon:SetTexture(nil)
        end

        if mouseOver then
            specText:SetTextColor(ar, ag, ab, 1); specIcon:SetVertexColor(ar, ag, ab, 1)
        else
            local br, bgr, bb = BlockColorOf(blockCfg)
            local ir, ig, ib = IconColorOf(blockCfg)
            specText:SetTextColor(br, bgr, bb, 1)
            -- Blizzard tree icons (no media file) stay untinted.
            if file then specIcon:SetVertexColor(ir, ig, ib, 1) else specIcon:SetVertexColor(1, 1, 1, 1) end
        end

        local suffix = GetGroupSuffix()
        if suffix then
            infoText:SetText("(" .. suffix .. ")")
            infoText:SetTextColor(1, 1, 1, 0.8); infoText:Show()
        else
            infoText:Hide()
        end

        local showIcon = d.showIcon ~= false and (file or (info and info.icon)) and true or false
        if showIcon then specIcon:Show() else specIcon:Hide(); iconSz = 0 end

        if isSide then
            iconSz = min(iconSz, max(14, floor(CONTENT_BASE * 0.72 + 0.5)))
            if not showIcon then iconSz = 0 end
        end
        if showIcon then Size(specIcon, iconSz, iconSz) end

        if isSide then
            local slotW = VSlotW(inst)
            local innerW = max(30, slotW - 8)
            local totalH = 8 + iconSz + 2

            specIcon:ClearAllPoints()
            specIcon:SetPoint("TOP", content, "TOP", 0, -4)

            ns.SetWrappedText(specText, innerW, "CENTER")
            specText:ClearAllPoints()
            if showIcon then
                specText:SetPoint("TOP", specIcon, "BOTTOM", 0, -2)
            else
                specText:SetPoint("TOP", content, "TOP", 0, -4)
            end
            totalH = totalH + ns.SnapToPixelGrid(specText:GetStringHeight())

            if infoText:IsShown() then
                ns.SetWrappedText(infoText, innerW, "CENTER")
                infoText:ClearAllPoints()
                infoText:SetPoint("TOP", specText, "BOTTOM", 0, -2)
                totalH = totalH + 2 + ns.SnapToPixelGrid(infoText:GetStringHeight())
            end

            totalH = max(totalH, barH)
            Size(content, slotW, totalH)
        else
            local slotW = HBudget(inst, 120)
            if showIcon then
                iconSz = min(fontSize + 8, max(14, floor(CONTENT_BASE * 0.72 + 0.5)))
                Size(specIcon, iconSz, iconSz)
            else
                iconSz = 0
            end
            ns.ResetInlineText(specText, "LEFT")
            ns.ResetInlineText(infoText, "LEFT")
            local tw = ns.SnapToPixelGrid(specText:GetStringWidth())
            -- Group label sits INLINE right of the tree name (below on vertical bars).
            local iw = 0
            if infoText:IsShown() then iw = ns.SnapToPixelGrid(infoText:GetStringWidth() or 0) end
            local infoPad = 0
            if iw > 0 then infoPad = gap + iw end
            local effIconGap = showIcon and iconGap or 0
            local totalW = min(slotW, iconSz + effIconGap + tw + infoPad + 4)
            specIcon:ClearAllPoints(); specIcon:SetPoint("LEFT", content, "LEFT", 0, 0)
            specText:ClearAllPoints(); specText:SetPoint("LEFT", content, "LEFT", iconSz + effIconGap, 0)
            infoText:ClearAllPoints(); infoText:SetPoint("LEFT", specText, "RIGHT", gap, 0)
            Size(content, totalW, barH)
        end
        specButton:ClearAllPoints(); specButton:SetAllPoints(content)
        MaybeRelayout(inst)
    end

    specButton:SetScript("OnEnter", function()
        mouseOver = true; inst:Refresh()
        ShowSpecTip()
    end)
    specButton:SetScript("OnLeave", function()
        mouseOver = false; inst:Refresh()
        -- Interactive tip: the keep-alive poll dismisses it once the cursor leaves block + tip.
        ns.Tip_HideUnlessInteractive(specButton)
    end)
    specButton:SetScript("OnClick", function(_, button)
        if button == "LeftButton" and IsShiftKeyDown() then
            ns.Tip_Hide(specButton)
            if ToggleTalentFrame then ToggleTalentFrame() end
        end
    end)

    inst.eventFrame = MakeEventFrame(inst, function(self)
        BuildSpecCache()
        self:Refresh()
        if ns.Tip_IsOwned(specButton) then ShowSpecTip() end
    end)

    function inst:Enable()
        content:Show()
        BuildSpecCache()
        RegisterInstEvents(self)
    end

    function inst:Disable()
        UnregisterInstEvents(self)
        ns.Tip_Hide(specButton)
        content:Hide()
    end

    function inst:GetAutoLength()
        local barH = barCtx.GetThickness()
        if barCtx.IsVertical() then
            local fontSize = max(9, floor(CONTENT_BASE * 0.4333 + 0.5))
            local iconSz = min(fontSize + 8, max(14, floor(CONTENT_BASE * 0.72 + 0.5)))
            local textH = specText:GetStringHeight() or fontSize
            local infoH = 0
            if infoText:IsShown() then infoH = (infoText:GetStringHeight() or 0) + 2 end
            return max(8 + iconSz + 2 + textH + infoH + 4, barH, 60)
        end
        return max(content:GetWidth() or 120, 40)
    end

    function inst:Destroy()
        self._dead = true
        ns.Tip_Hide(specButton)
        content:Hide()
    end

    BuildSpecCache()
    return inst
end
