-- EllesmereUIDataBars 3.3.5: bag space block factory (port of Retail Blocks\Bags.lua;
-- Wrath has no reagent bag, so the `reagent` setting is ignored).
local _, ns = ...
if not ns.IsWrath then return end
local E = EllesmereUI
local L = ns.L
local K = ns.BlockKit

-- Upvalues
local CreateFrame      = CreateFrame
local InCombatLockdown = InCombatLockdown
local floor            = math.floor
local max              = math.max
local min              = math.min
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

-- Backpack + four bag slots.
local LAST_BAG = NUM_BAG_SLOTS or 4

-- Low space text color default (soft red, matches durability's low tint).
local LOW_R, LOW_G, LOW_B = 1, 0.35, 0.35
ns.BAGS_LOW_COLOR = { LOW_R, LOW_G, LOW_B }

-- Returns free, total across the general-purpose bags (family 0, as Blizzard's
-- own free-space checks count): a quiver, soul bag or profession bag cannot take ordinary loot.
local function Count()
    local free, total = 0, 0
    for bag = 0, LAST_BAG do
        local nFree, family = GetContainerNumFreeSlots(bag)
        if not family or family == 0 then
            total = total + (GetContainerNumSlots(bag) or 0)
            free = free + (nFree or 0)
        end
    end
    return free, total
end

-- EllesmereUI Bags 3.3.5 window when it owns the bags, Blizzard bags otherwise.
local function ToggleBagsUI()
    local bags = E._ModuleNS and E._ModuleNS.EllesmereUIBags
    local p = bags and bags.GetSettings and bags.GetSettings()
    if p and p.enhancedBags and bags.Toggle and not InCombatLockdown() then bags.Toggle(); return end
    if ToggleAllBags then ToggleAllBags() elseif OpenAllBags then OpenAllBags() end
end

-------------------------------------------------------------------------------
--  BAGS (free / used slot counts)
-------------------------------------------------------------------------------
ns.BlockFactories.bags = function(blockCfg, slot, content, barCtx)
    local inst = { cfg = blockCfg, slot = slot, content = content, ctx = barCtx }
    inst.key = InstKey(barCtx, blockCfg)
    -- Wrath has no BAG_UPDATE_DELAYED: BAG_UPDATE bursts are coalesced to one check per frame below.
    inst.events = { "BAG_UPDATE", "PLAYER_ENTERING_WORLD" }

    local BAG_TEX = ns.MICROMENU_MEDIA .. "menu-bags"
    local mouseOver = false

    local function D() return blockCfg.settings or {} end
    local function BC() return barCtx.cfg end

    local button = CreateFrame("Button", nil, content)
    button:SetAllPoints()
    button:EnableMouse(true)
    button:RegisterForClicks("AnyUp")

    local icon = button:CreateTexture(nil, "OVERLAY")
    icon:SetTexture(BAG_TEX)
    local bagText = button:CreateFontString(nil, "OVERLAY")
    AttachTextOffset(inst, bagText)

    -- The counts on screen, from whichever path painted last: the event gate compares against these.
    local lastFree, lastTotal

    function inst:Refresh()
        local s = D()
        local barCfg = BC()
        local barH = barCtx.GetThickness()
        local fontSize = max(9, floor(CONTENT_BASE * 0.4333 + 0.5))
        local isSide = barCtx.IsVertical()

        local free, total = Count()
        lastFree, lastTotal = free, total
        local mode = s.value or "free"
        local text
        if mode == "used" then
            text = tostring(total - free)
        elseif mode == "usedTotal" then
            text = (total - free) .. "/" .. total
        elseif mode == "freeTotal" then
            text = free .. "/" .. total
        else
            text = tostring(free)
        end

        local iconSz = 0
        if s.showIcon ~= false then
            iconSz = fontSize + 4
            icon:Show()
        else
            icon:Hide()
        end

        ns.SetFont(bagText, fontSize, barCfg)
        icon:SetVertexColor(IconColorOf(blockCfg))
        local low = s.lowThreshold or 0
        if mouseOver then
            bagText:SetTextColor(ns.GetAccent())
        elseif low > 0 and free < low then
            local c = s.lowColor
            if c then
                bagText:SetTextColor(c.r or LOW_R, c.g or LOW_G, c.b or LOW_B)
            else
                bagText:SetTextColor(LOW_R, LOW_G, LOW_B)
            end
        else
            bagText:SetTextColor(BlockColorOf(blockCfg))
        end

        if isSide then
            local slotW = VSlotW(inst)
            local innerW = max(24, slotW - 8)
            bagText:SetText(text)
            local totalH = 8
            if iconSz > 0 then
                Size(icon, iconSz, iconSz)
                icon:ClearAllPoints()
                icon:SetPoint("TOP", button, "TOP", 0, -4)
                totalH = totalH + iconSz + 2
            end
            ns.SetWrappedText(bagText, innerW, "CENTER")
            bagText:ClearAllPoints()
            if iconSz > 0 then
                bagText:SetPoint("TOP", icon, "BOTTOM", 0, -2)
            else
                bagText:SetPoint("TOP", button, "TOP", 0, -4)
            end
            totalH = totalH + ns.SnapToPixelGrid(bagText:GetStringHeight()) + 4
            totalH = max(totalH, barH)
            Size(content, slotW, totalH)
            Size(button, slotW, totalH)
        else
            local slotW = HBudget(inst, 120)
            ns.ResetInlineText(bagText, "LEFT")
            bagText:SetText(text)
            if iconSz > 0 then
                Size(icon, iconSz, iconSz)
                icon:ClearAllPoints()
                icon:SetPoint("LEFT", button, "LEFT", 0, 0)
            end
            bagText:ClearAllPoints()
            local xOff = 0
            if iconSz > 0 then xOff = iconSz + ICON_GAP - 2 end
            bagText:SetPoint("LEFT", button, "LEFT", xOff, 0)
            local tw = ns.SnapToPixelGrid(bagText:GetStringWidth())
            local totalW = min(slotW, xOff + tw + 4)
            Size(content, max(totalW, 10), barH)
            Size(button, max(totalW, 10), barH)
        end

        MaybeRelayout(inst)
    end

    local function AddBagRow(bag)
        local n = GetContainerNumSlots(bag) or 0
        if n <= 0 then return end
        local used = n - (GetContainerNumFreeSlots(bag) or 0)
        local name = GetBagName and GetBagName(bag)
        if not name and bag == 0 then name = BACKPACK_TOOLTIP end
        ns.Tip_AddDouble(name or ("#" .. bag), used .. "/" .. n, 0.6, 0.6, 0.6, 1, 1, 1)
    end

    local function ShowBagsTooltip()
        local ar, ag, ab = ns.GetAccent()
        local free, total = Count()
        ns.Tip_Begin(button)
        ns.Tip_AddLine(L["BAGS"], 1, 1, 1)
        ns.Tip_AddLine(" ")
        for bag = 0, LAST_BAG do AddBagRow(bag) end
        ns.Tip_AddLine(" ")
        ns.Tip_AddDouble(L["FREE"], free .. "/" .. total, 1, 1, 1, 1, 1, 1)
        ns.Tip_AddLine(" ")
        ns.Tip_AddDouble(L["LEFT_CLICK"], L["OPEN_BAGS"], 1, 1, 1, ar, ag, ab)
        ns.Tip_Show()
    end

    button:SetScript("OnEnter", function()
        mouseOver = true
        inst:Refresh()
        ShowBagsTooltip()
    end)
    button:SetScript("OnLeave", function()
        mouseOver = false
        ns.Tip_Hide(button)
        inst:Refresh()
    end)
    button:SetScript("OnClick", function(_, mb)
        if mb == "LeftButton" then ToggleBagsUI() end
    end)

    -- Most bag batches (a potion, stacking, sorting) leave the counts unchanged and skip the repaint.
    local pump = CreateFrame("Frame")
    pump:Hide()
    pump:SetScript("OnUpdate", function(self)
        self:Hide()
        if inst._dead then return end
        local free, total = Count()
        if free == lastFree and total == lastTotal then return end
        inst:Refresh()
    end)

    inst.eventFrame = MakeEventFrame(inst, function(self, event)
        if event == "BAG_UPDATE" then pump:Show(); return end
        self:Refresh()
    end)

    function inst:Enable()
        lastFree, lastTotal = nil, nil
        content:Show()
        RegisterInstEvents(self)
    end

    function inst:Disable()
        UnregisterInstEvents(self)
        pump:Hide()
        content:Hide()
    end

    function inst:GetAutoLength()
        if barCtx.IsVertical() then
            return max(content:GetHeight() or 40, 30)
        end
        return max(content:GetWidth() or 40, 24)
    end

    function inst:Destroy()
        self._dead = true
        UnregisterInstEvents(self)
        pump:Hide()
        content:Hide()
    end

    return inst
end
