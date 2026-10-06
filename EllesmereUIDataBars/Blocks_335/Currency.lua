-- EllesmereUIDataBars 3.3.5: currency block factory (port of Retail Blocks\Currency.lua).
-- settings.currencyId holds ns.CurrencyKey: the token's itemID, "pvp"..extraCurrencyType
-- for honor/arena points, or the currency name.
local _, ns = ...
if not ns.IsWrath then return end
local E = EllesmereUI
local L = ns.L
local K = ns.BlockKit

-- Upvalues
local CreateFrame      = CreateFrame
local InCombatLockdown = InCombatLockdown
local GetTime          = GetTime
local tostring         = tostring
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

-------------------------------------------------------------------------------
--  Wrath currency lookup
-------------------------------------------------------------------------------
-- Honor (extraCurrencyType 2) and arena points (1) have dedicated getters and
-- fixed 3.3.5 caps; every other token is read off the currency list.
local PVP = {
    pvp1 = { name = function() return ARENA_POINTS or "Arena Points" end, get = function() return GetArenaCurrency and GetArenaCurrency() end,
             cap = 5000, desc = function() return TOOLTIP_ARENA_POINTS end },
    pvp2 = { name = function() return HONOR_POINTS or "Honor Points" end, get = function() return GetHonorCurrency and GetHonorCurrency() end,
             cap = 75000, desc = function() return TOOLTIP_HONOR_POINTS end },
}

local Cur = { cache = {}, fullAt = 0, desc = {} }

function Cur.Icon(icon, itemID, extra)
    if extra == 1 then return "Interface\\PVPFrame\\PVP-ArenaPoints-Icon" end
    if extra == 2 then return "Interface\\PVPFrame\\PVP-Currency-" .. (UnitFactionGroup("player") or "Horde") end
    if icon and icon ~= "" then
        if not icon:find("\\") then icon = "Interface\\Icons\\" .. icon end
        return icon
    end
    if itemID and GetItemIcon then return GetItemIcon(itemID) end
end

function Cur.Same(a, b) return a ~= nil and b ~= nil and tostring(a) == tostring(b) end

function Cur.Make(name, count, icon, itemID, extra)
    return { name = name, quantity = count or 0, iconFileID = Cur.Icon(icon, itemID, extra), itemID = itemID, extra = extra }
end

-- Visible rows first (no header expansion); then a full scan through ns.Currencies,
-- which expands collapsed headers and is throttled so the CURRENCY_DISPLAY_UPDATE
-- it may raise can never loop. Returns info, stale.
function Cur.Lookup(key)
    if key == nil then return nil end
    local pvp = PVP[key]
    if pvp then
        local extra = key == "pvp1" and 1 or 2
        return Cur.Make(pvp.name(), pvp.get() or 0, nil, nil, extra), false
    end
    if GetCurrencyListSize and GetCurrencyListInfo then
        for i = 1, GetCurrencyListSize() do
            local name, isHeader, _, _, _, count, extra, icon, itemID = GetCurrencyListInfo(i)
            if name and not isHeader and Cur.Same(ns.CurrencyKey(name, itemID, extra), key) then
                local info = Cur.Make(name, count, icon, itemID, extra)
                Cur.cache[tostring(key)] = info
                return info, false
            end
        end
    end
    local now = GetTime()
    if now >= Cur.fullAt and ns.Currencies then
        Cur.fullAt = now + 2
        Cur.lastFull = now
        for _, r in ipairs(ns.Currencies()) do
            Cur.cache[tostring(r.key)] = Cur.Make(r.name, r.count, r.icon, r.itemID, r.extra)
        end
        return Cur.cache[tostring(key)], false
    end
    return Cur.cache[tostring(key)], true
end

-- Wrath tokens carry no description field: the item's quoted flavor line is the description.
function Cur.Description(info)
    if info.extra then
        local pvp = PVP["pvp" .. info.extra]
        return pvp and pvp.desc() or nil
    end
    local id = info.itemID
    if not id then return nil end
    if Cur.desc[id] ~= nil then return Cur.desc[id] or nil end
    local tip = Cur.scan
    if not tip then
        tip = CreateFrame("GameTooltip", "EllesmereUIDataBarsCurrencyScan", UIParent, "GameTooltipTemplate")
        Cur.scan = tip
    end
    tip:SetOwner(WorldFrame, "ANCHOR_NONE")
    tip:ClearLines()
    tip:SetHyperlink("item:" .. id)
    local out
    local lines = tip:NumLines()
    for i = 2, lines do
        local fs = _G["EllesmereUIDataBarsCurrencyScanTextLeft" .. i]
        local t = fs and fs:GetText()
        if t and t:sub(1, 1) == "\"" then out = out and (out .. "\n" .. t) or t end
    end
    tip:Hide()
    -- An uncached item has no lines yet; only remember a found description or a loaded item.
    if out or lines > 1 then Cur.desc[id] = out or false end
    return out
end

local function Num(v) return ns.GroupDigits(v or 0) end

local function OpenCurrencyPanel()
    if ToggleCharacter then ToggleCharacter("TokenFrame") end
end

-------------------------------------------------------------------------------
--  CURRENCY (searchable-picker driven; icon + amount + owned tooltip)
-------------------------------------------------------------------------------
ns.BlockFactories.currency = function(blockCfg, slot, content, barCtx)
    local inst = { cfg = blockCfg, slot = slot, content = content, ctx = barCtx }
    inst.key = InstKey(barCtx, blockCfg)
    -- Honor and arena points also move on HONOR_CURRENCY_UPDATE.
    inst.events = { "CURRENCY_DISPLAY_UPDATE", "HONOR_CURRENCY_UPDATE", "PLAYER_ENTERING_WORLD" }

    local mouseOver = false
    local enabled = false

    local function D() return blockCfg.settings or {} end
    local function BC() return barCtx.cfg end

    local button = CreateFrame("Button", nil, content)
    button:SetAllPoints()
    button:EnableMouse(true)
    button:RegisterForClicks("AnyUp")

    local icon = button:CreateTexture(nil, "OVERLAY")
    local amountText = button:CreateFontString(nil, "OVERLAY")
    AttachTextOffset(inst, amountText)

    -- A throttled lookup painted cached data: re-check on the 1 s heartbeat until fresh.
    local function SetStale(stale)
        if stale and enabled then
            ns.RegisterHeartbeat(inst.key .. "_cur", function() inst:Refresh() end)
        else
            ns.UnregisterHeartbeat(inst.key .. "_cur")
        end
    end

    local function GetInfo()
        local s = D()
        if not s.currencyId then SetStale(false); return nil end
        local info, stale = Cur.Lookup(s.currencyId)
        SetStale(stale)
        return info
    end

    function inst:Refresh()
        local s = D()
        local barCfg = BC()
        local barH = barCtx.GetThickness()
        local fontSize = max(9, floor(CONTENT_BASE * 0.4333 + 0.5))
        local isSide = barCtx.IsVertical()
        local gap = ICON_GAP

        local info = GetInfo()
        local text
        if not s.currencyId then
            -- Bar text skips the Tip_* locale routing, so translate by hand.
            text = (E.L and E.L(L["SELECT_CURRENCY"])) or L["SELECT_CURRENCY"]
        elseif info then
            text = Num(info.quantity)
        else
            text = "-"
        end

        local iconSz = 0
        if s.showIcon ~= false and info and info.iconFileID then
            iconSz = fontSize + 2
            icon:SetTexture(info.iconFileID)
            if info.iconFileID:find("^Interface\\Icons\\") then
                icon:SetTexCoord(5 / 64, 59 / 64, 5 / 64, 59 / 64)
            else
                icon:SetTexCoord(0, 1, 0, 1)
            end
            icon:Show()
        else
            icon:Hide()
        end

        if isSide then
            local slotW = VSlotW(inst)
            local innerW = max(24, slotW - 8)
            ns.SetFont(amountText, fontSize, barCfg)
            amountText:SetText(text)
            local totalH = 8
            if iconSz > 0 then
                Size(icon, iconSz, iconSz)
                icon:ClearAllPoints()
                icon:SetPoint("TOP", button, "TOP", 0, -4)
                totalH = totalH + iconSz + 2
            end
            ns.SetWrappedText(amountText, innerW, "CENTER")
            amountText:ClearAllPoints()
            if iconSz > 0 then
                amountText:SetPoint("TOP", icon, "BOTTOM", 0, -2)
            else
                amountText:SetPoint("TOP", button, "TOP", 0, -4)
            end
            totalH = totalH + ns.SnapToPixelGrid(amountText:GetStringHeight()) + 4
            totalH = max(totalH, barH)
            Size(content, slotW, totalH)
            Size(button, slotW, totalH)
        else
            local slotW = HBudget(inst, 120)
            ns.SetFont(amountText, fontSize, barCfg)
            ns.ResetInlineText(amountText, "LEFT")
            amountText:SetText(text)
            if iconSz > 0 then
                Size(icon, iconSz, iconSz)
                icon:ClearAllPoints()
                icon:SetPoint("LEFT", button, "LEFT", 0, 0)
            end
            amountText:ClearAllPoints()
            local xOff = 0
            if iconSz > 0 then xOff = iconSz + gap end
            amountText:SetPoint("LEFT", button, "LEFT", xOff, 0)
            local tw = ns.SnapToPixelGrid(amountText:GetStringWidth())
            local totalW = min(slotW, iconSz + (iconSz > 0 and gap or 0) + tw + 4)
            Size(content, max(totalW, 10), barH)
            Size(button, max(totalW, 10), barH)
        end

        local cbr, cbg, cbb = BlockColorOf(blockCfg)
        do
            local ir, ig, ib = IconColorOf(blockCfg)
            icon:SetVertexColor(ir, ig, ib, 1)
        end
        if not s.currencyId then
            amountText:SetTextColor(0.55, 0.55, 0.55, 1)
        elseif mouseOver then
            local ar, ag, ab = ns.GetAccent()
            amountText:SetTextColor(ar, ag, ab, 1)
        else
            amountText:SetTextColor(cbr, cbg, cbb, 1)
        end
        MaybeRelayout(inst)
    end

    local function ShowCurrencyTooltip()
        local s = D()
        local ar, ag, ab = ns.GetAccent()
        -- Unconfigured: the tooltip says where the currency is actually picked.
        if not s.currencyId then
            ns.Tip_Begin(button)
            ns.Tip_AddLine(L["SELECT_CURRENCY"], 1, 1, 1)
            ns.Tip_AddLine(" ")
            ns.Tip_AddDouble(L["LEFT_CLICK"], L["OPEN_SETTINGS"], 1, 1, 1, ar, ag, ab)
            ns.Tip_Show()
            return
        end
        local info = Cur.Lookup(s.currencyId)
        if not info then return end
        ns.Tip_Begin(button)
        local qr, qg, qb = 1, 1, 1
        local quality = info.itemID and select(3, GetItemInfo(info.itemID))
        if quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality] then
            local qc = ITEM_QUALITY_COLORS[quality]
            qr, qg, qb = qc.r, qc.g, qc.b
        end
        ns.Tip_AddLine(info.name or "?", qr, qg, qb)
        if s.showDescription ~= false then
            local desc = Cur.Description(info)
            if desc and desc ~= "" then
                ns.Tip_AddLine(" ")
                ns.Tip_AddWrappedLine(desc, 280, 0.8, 0.8, 0.8)
            end
        end
        ns.Tip_AddLine(" ")
        local qty = Num(info.quantity)
        local pvp = info.extra and PVP["pvp" .. info.extra]
        local cap = pvp and pvp.cap
        if cap and cap > 0 then
            ns.Tip_AddDouble(L["TOTAL"], qty .. " / " .. Num(cap), 0.6, 0.6, 0.6, 1, 1, 1)
        else
            ns.Tip_AddDouble(L["TOTAL"], qty, 0.6, 0.6, 0.6, 1, 1, 1)
        end
        ns.Tip_AddLine(" ")
        ns.Tip_AddDouble(L["LEFT_CLICK"], L["OPEN_CURRENCIES"], 1, 1, 1, ar, ag, ab)
        ns.Tip_Show()
    end

    button:SetScript("OnEnter", function()
        mouseOver = true
        inst:Refresh()
        ShowCurrencyTooltip()
    end)
    button:SetScript("OnLeave", function()
        mouseOver = false
        ns.Tip_Hide(button)
        inst:Refresh()
    end)
    button:SetScript("OnClick", function(_, mb)
        if mb ~= "LeftButton" then return end
        -- No currency picked yet: send the player to the picker instead of the Blizzard panel.
        if not D().currencyId then
            if InCombatLockdown() then return end
            if not ns.OpenBlockSettings and E.EnsureLoaded then pcall(E.EnsureLoaded, E) end
            if ns.OpenBlockSettings then
                ns.OpenBlockSettings(barCtx.id, blockCfg.id, "currency")
            elseif E.ShowModule then
                E:ShowModule("EllesmereUIDataBars")
            end
            return
        end
        OpenCurrencyPanel()
    end)

    inst.eventFrame = MakeEventFrame(inst, function(self, event)
        -- The echo of a full scan's own header expand/collapse carries no new data.
        if event == "CURRENCY_DISPLAY_UPDATE" and Cur.lastFull and GetTime() - Cur.lastFull < 0.1 then return end
        self:Refresh()
    end)

    function inst:Enable()
        enabled = true
        content:Show()
        RegisterInstEvents(self)
    end

    function inst:Disable()
        enabled = false
        SetStale(false)
        UnregisterInstEvents(self)
        content:Hide()
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
        SetStale(false)
        UnregisterInstEvents(self)
        content:Hide()
    end

    return inst
end
