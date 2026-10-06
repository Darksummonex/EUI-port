-- EllesmereUIDataBars 3.3.5: item level block factory (port of Retail Blocks\ItemLevel.lua).
-- Wrath has no GetAverageItemLevel: the averages are computed here.
local _, ns = ...
if not ns.IsWrath then return end
local E = EllesmereUI
local L = ns.L
local K = ns.BlockKit

-- Upvalues
local CreateFrame      = CreateFrame
local InCombatLockdown = InCombatLockdown
local GetItemInfo      = GetItemInfo
local format           = string.format
local floor            = math.floor
local max              = math.max
local min              = math.min
local tsort            = table.sort
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

-------------------------------------------------------------------------------
--  Wrath average item level
-------------------------------------------------------------------------------
-- Blizzard formula: 17 gear slots (1..18 minus the shirt), empty slots count 0,
-- a two-hander with an empty off hand counts twice.
local IL = { SLOTS = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 }, DIVISOR = 17, usable = {} }
IL.GROUP = {
    INVTYPE_HEAD = "head", INVTYPE_NECK = "neck", INVTYPE_SHOULDER = "shoulder", INVTYPE_CLOAK = "back",
    INVTYPE_CHEST = "chest", INVTYPE_ROBE = "chest", INVTYPE_WRIST = "wrist", INVTYPE_HAND = "hands",
    INVTYPE_WAIST = "waist", INVTYPE_LEGS = "legs", INVTYPE_FEET = "feet",
    INVTYPE_FINGER = "finger", INVTYPE_TRINKET = "trinket",
    INVTYPE_WEAPON = "1h", INVTYPE_WEAPONMAINHAND = "mh", INVTYPE_2HWEAPON = "2h",
    INVTYPE_WEAPONOFFHAND = "oh", INVTYPE_SHIELD = "oh", INVTYPE_HOLDABLE = "oh",
    INVTYPE_RANGED = "ranged", INVTYPE_RANGEDRIGHT = "ranged", INVTYPE_THROWN = "ranged", INVTYPE_RELIC = "ranged",
}
IL.SINGLES = { "head", "neck", "shoulder", "back", "chest", "wrist", "hands", "waist", "legs", "feet", "ranged" }
IL.PAIRS = { "finger", "trinket" }
IL.SIDES = { "Left", "Right" }

-- Equipped average; second return = some item info is not cached yet.
function IL.Equipped()
    local sum, missing = 0, false
    local mhLvl, mh2H
    for i = 1, #IL.SLOTS do
        local s = IL.SLOTS[i]
        local link = GetInventoryItemLink("player", s)
        if link then
            local _, _, _, lvl, _, _, _, _, equipLoc = GetItemInfo(link)
            if lvl then
                sum = sum + lvl
                if s == 16 then mhLvl, mh2H = lvl, equipLoc == "INVTYPE_2HWEAPON" end
            else
                missing = true
            end
        end
    end
    if mhLvl and mh2H and not GetInventoryItemLink("player", 17) then sum = sum + mhLvl end
    return sum / IL.DIVISOR, missing
end

-- Bag items the character cannot wear (class, proficiency, level) show red tooltip lines.
function IL.Usable(bag, slot, link)
    local cached = IL.usable[link]
    if cached ~= nil then return cached end
    local tip = IL.scan
    if not tip then
        tip = CreateFrame("GameTooltip", "EllesmereUIDataBarsIlvlScan", UIParent, "GameTooltipTemplate")
        IL.scan = tip
    end
    tip:SetOwner(WorldFrame, "ANCHOR_NONE")
    tip:ClearLines()
    tip:SetBagItem(bag, slot)
    local ok = true
    for i = 2, tip:NumLines() do
        for _, side in ipairs(IL.SIDES) do
            local fs = _G["EllesmereUIDataBarsIlvlScanText" .. side .. i]
            if fs and fs:IsShown() and (fs:GetText() or "") ~= "" then
                local r, g, b = fs:GetTextColor()
                if r and r > 0.9 and g < 0.2 and b < 0.2 then ok = false end
            end
        end
    end
    tip:Hide()
    IL.usable[link] = ok
    return ok
end

local function TopDesc(list) tsort(list, function(a, b) return a > b end); return list end

-- "Total": average of the best wearable item per slot across equipped gear and bags.
function IL.Total()
    local groups, missing = {}, false
    local function Add(link, bag, slot)
        local _, _, _, lvl, _, _, _, _, equipLoc = GetItemInfo(link)
        if not lvl then missing = true; return end
        local g = IL.GROUP[equipLoc or ""]
        if not g then return end
        if bag and not IL.Usable(bag, slot, link) then return end
        local list = groups[g]
        if not list then list = {}; groups[g] = list end
        list[#list + 1] = lvl
    end
    for i = 1, #IL.SLOTS do
        local link = GetInventoryItemLink("player", IL.SLOTS[i])
        if link then Add(link) end
    end
    for bag = 0, NUM_BAG_SLOTS or 4 do
        for slot = 1, GetContainerNumSlots(bag) or 0 do
            local link = GetContainerItemLink(bag, slot)
            if link then Add(link, bag, slot) end
        end
    end
    local sum = 0
    for i = 1, #IL.SINGLES do
        local list = groups[IL.SINGLES[i]]
        if list then sum = sum + TopDesc(list)[1] end
    end
    for _, g in ipairs(IL.PAIRS) do
        local list = groups[g]
        if list then TopDesc(list); sum = sum + (list[1] or 0) + (list[2] or 0) end
    end
    local twoH = groups["2h"] and TopDesc(groups["2h"])[1] or 0
    local oneH = groups["1h"] and TopDesc(groups["1h"]) or {}
    local mhOnly = groups.mh and TopDesc(groups.mh)[1] or 0
    local ohOnly = groups.oh and TopDesc(groups.oh)[1] or 0
    local dual = CanDualWield and CanDualWield()
    local mh, oh
    if (oneH[1] or 0) > mhOnly then
        mh = oneH[1]
        oh = max(ohOnly, dual and (oneH[2] or 0) or 0)
    else
        mh = mhOnly
        oh = max(ohOnly, dual and (oneH[1] or 0) or 0)
    end
    sum = sum + max(twoH * 2, mh + oh)
    return sum / IL.DIVISOR, missing
end

-------------------------------------------------------------------------------
--  ITEM LEVEL (equipped / total, with an optional prefix)
-------------------------------------------------------------------------------
ns.BlockFactories.ilvl = function(blockCfg, slot, content, barCtx)
    local inst = { cfg = blockCfg, slot = slot, content = content, ctx = barCtx }
    inst.key = InstKey(barCtx, blockCfg)
    inst.events = { "PLAYER_EQUIPMENT_CHANGED", "UNIT_INVENTORY_CHANGED", "BAG_UPDATE", "PLAYER_LEVEL_UP",
                    "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED" }

    local ILVL_TEX = ns.MICROMENU_MEDIA .. "menu-character"
    local mouseOver = false
    local enabled = false

    local function D() return blockCfg.settings or {} end
    local function BC() return barCtx.cfg end
    local function Locked() return InCombatLockdown() and content.IsProtected and content:IsProtected() end
    local function NeedsTotal()
        local mode = D().value or "equipped"
        return mode == "total" or mode == "both"
    end

    local button = CreateFrame("Button", nil, content)
    button:SetAllPoints()
    button:EnableMouse(true)
    button:RegisterForClicks("AnyUp")

    local icon = button:CreateTexture(nil, "OVERLAY")
    icon:SetTexture(ILVL_TEX)
    local ilvlText = button:CreateFontString(nil, "OVERLAY")
    AttachTextOffset(inst, ilvlText)

    -- Uncached item info (fresh login, new loot): retry on the 1 s heartbeat until complete.
    local function SetPending(pending)
        if pending and enabled then
            ns.RegisterHeartbeat(inst.key .. "_ilvl", function() inst:Refresh() end)
        else
            ns.UnregisterHeartbeat(inst.key .. "_ilvl")
        end
    end

    local function AvgIlvl(wantTotal)
        local equipped, missing = IL.Equipped()
        local total
        if wantTotal then
            local m
            total, m = IL.Total()
            missing = missing or m
        end
        return total, equipped, missing
    end

    local function Fmt(v, p)
        if not v then return "-" end
        return format("%." .. p .. "f", v)
    end

    local function Loc(s) return (E.L and E.L(s)) or s end
    local function LongLabel()
        return STAT_AVERAGE_ITEM_LEVEL or Loc(L["ITEM_LEVEL"])
    end

    function inst:Refresh()
        local s = D()
        local barCfg = BC()
        local barH = barCtx.GetThickness()
        local fontSize = max(9, floor(CONTENT_BASE * 0.4333 + 0.5))
        local isSide = barCtx.IsVertical()
        local gap = ICON_GAP

        local mode = s.value or "equipped"
        local total, equipped, missing = AvgIlvl(mode == "total" or mode == "both")
        SetPending(missing)
        -- Published for the "Band" text swatch (and its options preview).
        K.lastAvgIlvl = equipped or total

        local p = s.precision
        if p == nil then p = 0 end
        p = max(0, min(2, floor(p)))
        local body
        if mode == "total" then
            body = Fmt(total, p)
        elseif mode == "both" then
            body = Fmt(equipped, p) .. " / " .. Fmt(total, p)
        else
            body = Fmt(equipped, p)
        end

        local prefix = s.prefix or "short"
        local text = body
        if prefix == "short" then
            text = Loc(L["ILVL"]) .. " " .. body
        elseif prefix == "long" then
            text = LongLabel() .. " " .. body
        end

        local iconSz = 0
        if prefix == "icon" then
            iconSz = fontSize + 2
            icon:Show()
        else
            icon:Hide()
        end

        ns.SetFont(ilvlText, fontSize, barCfg)
        do
            local ir, ig, ib = IconColorOf(blockCfg)
            icon:SetVertexColor(ir, ig, ib, 1)
        end
        if mouseOver then
            ilvlText:SetTextColor(ns.GetAccent())
        else
            ilvlText:SetTextColor(BlockColorOf(blockCfg))
        end
        if Locked() then
            ilvlText:SetText(text)
            return
        end
        if isSide then
            local slotW = VSlotW(inst)
            local innerW = max(24, slotW - 8)
            ilvlText:SetText(text)
            local totalH = 8
            if iconSz > 0 then
                Size(icon, iconSz, iconSz)
                icon:ClearAllPoints()
                icon:SetPoint("TOP", button, "TOP", 0, -4)
                totalH = totalH + iconSz + 2
            end
            ns.SetWrappedText(ilvlText, innerW, "CENTER")
            ilvlText:ClearAllPoints()
            if iconSz > 0 then
                ilvlText:SetPoint("TOP", icon, "BOTTOM", 0, -2)
            else
                ilvlText:SetPoint("TOP", button, "TOP", 0, -4)
            end
            totalH = totalH + ns.SnapToPixelGrid(ilvlText:GetStringHeight()) + 4
            totalH = max(totalH, barH)
            Size(content, slotW, totalH)
            Size(button, slotW, totalH)
        else
            local slotW = HBudget(inst, 120)
            ns.ResetInlineText(ilvlText, "LEFT")
            ilvlText:SetText(text)
            if iconSz > 0 then
                Size(icon, iconSz, iconSz)
                icon:ClearAllPoints()
                icon:SetPoint("LEFT", button, "LEFT", 0, 0)
            end
            ilvlText:ClearAllPoints()
            local xOff = 0
            if iconSz > 0 then xOff = iconSz + gap end
            ilvlText:SetPoint("LEFT", button, "LEFT", xOff, 0)
            local tw = ns.SnapToPixelGrid(ilvlText:GetStringWidth())
            local totalW = min(slotW, xOff + tw + 4)
            Size(content, max(totalW, 10), barH)
            Size(button, max(totalW, 10), barH)
        end

        MaybeRelayout(inst)
    end

    local function ShowIlvlTooltip()
        local ar, ag, ab = ns.GetAccent()
        local total, equipped = AvgIlvl(true)
        ns.Tip_Begin(button)
        ns.Tip_AddLine(LongLabel(), 1, 1, 1)
        ns.Tip_AddLine(" ")
        if equipped then
            ns.Tip_AddDouble(L["EQUIPPED"], format("%.2f", equipped), 0.6, 0.6, 0.6, 1, 1, 1)
        end
        if total then
            ns.Tip_AddDouble(L["TOTAL"], format("%.2f", total), 0.6, 0.6, 0.6, 1, 1, 1)
        end
        ns.Tip_AddLine(" ")
        ns.Tip_AddDouble(L["LEFT_CLICK"], L["OPEN_CHARACTER"], 1, 1, 1, ar, ag, ab)
        ns.Tip_Show()
    end

    button:SetScript("OnEnter", function()
        mouseOver = true
        inst:Refresh()
        ShowIlvlTooltip()
    end)
    button:SetScript("OnLeave", function()
        mouseOver = false
        ns.Tip_Hide(button)
        inst:Refresh()
    end)
    -- CharacterFrame is not protected on Wrath; combat keeps the click inert, as the Retail secure overlay does.
    button:SetScript("OnClick", function(_, mb)
        if mb == "LeftButton" and ToggleCharacter and not InCombatLockdown() then
            ToggleCharacter("PaperDollFrame")
        end
    end)

    -- Bag changes only matter to the "total" figure: coalesced to one refresh per frame.
    local pump = CreateFrame("Frame")
    pump:Hide()
    pump:SetScript("OnUpdate", function(self)
        self:Hide()
        if not inst._dead then inst:Refresh() end
    end)

    inst.eventFrame = MakeEventFrame(inst, function(self, event, arg1)
        if event == "UNIT_INVENTORY_CHANGED" and arg1 ~= "player" then return end
        if event == "PLAYER_LEVEL_UP" then ns.Wipe(IL.usable) end
        if event == "BAG_UPDATE" then
            if NeedsTotal() then pump:Show() end
            return
        end
        self:Refresh()
    end)

    function inst:Enable()
        enabled = true
        if not content:IsShown() and not Locked() then content:Show() end
        RegisterInstEvents(self)
    end

    function inst:Disable()
        enabled = false
        SetPending(false)
        pump:Hide()
        UnregisterInstEvents(self)
        if not Locked() then content:Hide() end
    end

    function inst:GetAutoLength()
        if barCtx.IsVertical() then
            return max(content:GetHeight() or 40, 30)
        end
        return max(content:GetWidth() or 60, 24)
    end

    function inst:Destroy()
        self._dead = true
        enabled = false
        SetPending(false)
        pump:Hide()
        UnregisterInstEvents(self)
        if not Locked() then content:Hide() end
    end

    return inst
end
