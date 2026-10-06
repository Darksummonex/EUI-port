-- EllesmereUIDataBars 3.3.5: travel block (port of Retail Blocks\Travel.lua).
-- Wrath has no toys and no Mythic+ teleports: the hearthstone pool is the
-- Wrath items sharing the hearthstone cooldown, the extras are the class
-- recalls (Astral Recall, Death Gate, Teleport: Moonglade) and the teleport
-- section (settings.clickableTeleports) lists known mage teleports and owned
-- Kirin Tor rings. The block's hearthstone button is a real secure item
-- button inside the block content (the bar's [combat] state driver may hide
-- it); tooltip rows are the owned tooltip's secure spell/item rows.
local _, ns = ...
if not ns.IsWrath then return end
local L = ns.L
local MEDIA = ns.MEDIA
local K = ns.BlockKit

local CreateFrame      = CreateFrame
local InCombatLockdown = InCombatLockdown
local GetTime          = GetTime
local ipairs           = ipairs
local type             = type
local floor            = math.floor
local max              = math.max
local min              = math.min
local mrandom          = math.random
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
local ParkSecureFrame      = K.ParkSecureFrame

local TELEPORTS_LABEL = L["TELEPORTS"] or "Teleports"
local EQUIP_LABEL = "Equip"

-------------------------------------------------------------------------------
--  TRAVEL (Hearthstone + class/mage teleports; SECURE hearth button)
-------------------------------------------------------------------------------
-- Hearthstone pool: Hearthstone and Ethereal Portal (shared cooldown, usable
-- from the bags; equip-to-use variants are left out so a click never swaps gear).
local HEARTHSTONE_IDS = { 6948, 54452 }

-- Class recalls with their OWN cooldown, listed under the Hearthstone row.
local TRAVEL_EXTRAS = {
    556,    -- Astral Recall
    50977,  -- Death Gate
    18960,  -- Teleport: Moonglade
}

-- Teleport section: mage city teleports (spells) and Kirin Tor rings (items).
local TELEPORT_SPELLS = {
    3561, 3562, 3565, 32271, 33690, 49359,   -- Stormwind, Ironforge, Darnassus, Exodar, Shattrath (A), Theramore
    3563, 3566, 3567, 32272, 35715, 49358,   -- Undercity, Thunder Bluff, Orgrimmar, Silvermoon, Shattrath (H), Stonard
    53140,                                   -- Dalaran
}
local TELEPORT_ITEMS = {
    40585, 40586, 44934, 44935, 45688, 45689, 45690, 45691,
    48954, 48955, 48956, 48957, 51557, 51558, 51559, 51560,
}

-- Known-spell check: IsSpellKnown when present, else a spellbook name scan.
local function SpellKnown(id)
    local name = GetSpellInfo(id)
    if not name then return false end
    if IsSpellKnown then return IsSpellKnown(id) and true or false end
    if not (GetNumSpellTabs and GetSpellTabInfo and GetSpellName) then return false end
    for tab = 1, GetNumSpellTabs() do
        local _, _, offset, count = GetSpellTabInfo(tab)
        for i = (offset or 0) + 1, (offset or 0) + (count or 0) do
            if GetSpellName(i, BOOKTYPE_SPELL or "spell") == name then return true end
        end
    end
    return false
end

local function TravelIsUsable(id)
    if type(id) ~= "number" then return false end
    return (GetItemCount(id) or 0) > 0
end

-- Options-side exports: the hearthstone dropdown lists owned pool entries.
ns.TravelHearthstoneIDs = HEARTHSTONE_IDS
ns.TravelIsUsable = TravelIsUsable

-- Remaining cooldown of an item id or a spell id. The global cooldown is not
-- a travel cooldown, so spell durations up to 1.5 s read as ready.
local function TravelGetRemainingCooldown(id, isSpell)
    local startTime, duration
    if isSpell then
        local name = GetSpellInfo(id)
        if name then startTime, duration = GetSpellCooldown(name) end
        if type(duration) == "number" and duration <= 1.5 then return 0, true end
    else
        startTime, duration = GetItemCooldown(id)
    end
    if type(startTime) == "number" and type(duration) == "number" and duration > 0 and startTime > 0 then
        return max(0, startTime + duration - GetTime()), true
    end
    return 0, true
end

local _hearthList = {}
local function TravelGetAvailableHearthstones()
    local n = 0
    for _, id in ipairs(HEARTHSTONE_IDS) do
        if TravelIsUsable(id) then n = n + 1; _hearthList[n] = id end
    end
    for i = n + 1, #_hearthList do _hearthList[i] = nil end
    return _hearthList
end

local function TravelPickHearthstone(randomize)
    local list = TravelGetAvailableHearthstones()
    if #list == 0 then return nil end
    if randomize then return list[mrandom(#list)] end
    for _, id in ipairs(list) do if id == 6948 then return id end end
    return list[1]
end

-- Ownership cache, cleared on the bag/spell/bind edges the block listens to.
local travelPrimaryHearthId, travelNoHearth
function ns.TravelInvalidateHearthCache()
    travelNoHearth = nil
    travelPrimaryHearthId = nil
end
local function TravelGetPrimaryCooldown()
    if not travelPrimaryHearthId then
        if travelNoHearth then return 0, true end
        travelPrimaryHearthId = TravelPickHearthstone(false)
        if not travelPrimaryHearthId then
            travelNoHearth = true
            return 0, true
        end
    end
    return TravelGetRemainingCooldown(travelPrimaryHearthId, false)
end

local function ItemName(id)
    local name = GetItemInfo(id)
    return name or ("Item " .. id)
end

ns.BlockFactories.travel = function(blockCfg, slot, content, barCtx)
    local inst = { cfg = blockCfg, slot = slot, content = content, ctx = barCtx }
    inst.key = InstKey(barCtx, blockCfg)
    -- UNIT_SPELLCAST_SUCCEEDED (player only, filtered in the handler) is the
    -- cooldown-start lane; the rest are ownership/bind edges.
    inst.events = { "HEARTHSTONE_BOUND", "PLAYER_ENTERING_WORLD", "BAG_UPDATE", "SPELLS_CHANGED",
        "UNIT_SPELLCAST_SUCCEEDED" }

    local HEARTH_TEX = MEDIA .. "hearthstone"
    local mouseOver = false
    -- Heartbeat demand-gate: ticks only while something cools or the tip is open.
    local ticking = false
    local TravelSyncTicker

    local _teleBuf = {}
    local _teleCount = 0

    local function D() return blockCfg.settings or {} end
    local function BC() return barCtx.cfg end

    local function ChosenHearthstone()
        local dt = D()
        local choice = dt.hsChoice
        if choice == nil then choice = dt.randomizeHs and "random" or 6948 end
        if choice ~= "random" and TravelIsUsable(choice) then return choice end
        return TravelPickHearthstone(choice == "random")
    end

    local built = false
    local hearthButton, hearthIcon, hearthText
    local placeholder

    local function AddTeleport(name, id, isSpell)
        _teleCount = _teleCount + 1
        local e = _teleBuf[_teleCount]
        if not e then e = {}; _teleBuf[_teleCount] = e end
        local cd, known = TravelGetRemainingCooldown(id, isSpell)
        e.name, e.id, e.isSpell, e.cd, e.cdKnown = name, id, isSpell, cd, known
        e.unequipped = (not isSpell) and IsEquippedItem and not IsEquippedItem(id) or false
    end

    local function RefreshTravelTooltip()
        local ar, ag, ab = 1, 1, 1
        ns.Tip_Begin(hearthButton)
        -- Hover-persistent: the cursor can travel onto the tip to click ready rows.
        ns.Tip_MarkInteractive()
        ns.Tip_AddLine("|cFFFFFFFF[|r" .. L["TRAVEL_COOLDOWNS"] .. "|cFFFFFFFF]|r", ar, ag, ab)
        ns.Tip_AddLine(" ")
        local cd2, cdKnown = TravelGetPrimaryCooldown()
        local cdStr
        if cdKnown then
            cdStr = ns.FormatCooldown(cd2)
            if not cdStr then cdStr = L["READY"] end
        else
            cdStr = "-"
        end
        local ready = cdKnown and cd2 <= 0
        local rr, rg, rb = 0.5, 0.5, 0.5
        if ready then rr, rg, rb = 0, 1, 0 end
        local hsLabel = L["HEARTHSTONE"] .. " (" .. (GetBindLocation() or "?") .. ")"
        local hsId = ready and ChosenHearthstone()
        if hsId then
            ns.Tip_AddItemActionDouble(hsLabel, cdStr, hsId, 1, 1, 1, rr, rg, rb)
        else
            local hg = ready and 1 or 0.65
            ns.Tip_AddDouble(hsLabel, cdStr, hg, hg, hg, rr, rg, rb)
            ns.Tip_PadRow()
        end

        for _, spellId in ipairs(TRAVEL_EXTRAS) do
            if SpellKnown(spellId) then
                local entryName = GetSpellInfo(spellId)
                local tcd, tKnown = TravelGetRemainingCooldown(spellId, true)
                local tstr
                if tKnown then
                    tstr = ns.FormatCooldown(tcd)
                    if not tstr then tstr = L["READY"] end
                else
                    tstr = "-"
                end
                local tready = tKnown and tcd <= 0
                if tready then
                    ns.Tip_AddActionDouble(entryName, tstr, spellId, 1, 1, 1, 0, 1, 0)
                else
                    ns.Tip_AddDouble(entryName, tstr, 0.65, 0.65, 0.65, 0.5, 0.5, 0.5)
                end
            end
        end

        -- Teleport section: nil reads as shown; OFF skips the scan entirely.
        _teleCount = 0
        if D().clickableTeleports ~= false then
            for _, id in ipairs(TELEPORT_SPELLS) do
                if SpellKnown(id) then AddTeleport(GetSpellInfo(id), id, true) end
            end
            for _, id in ipairs(TELEPORT_ITEMS) do
                if (GetItemCount(id) or 0) > 0 or (IsEquippedItem and IsEquippedItem(id)) then
                    AddTeleport(ItemName(id), id, false)
                end
            end
        end
        if _teleCount > 0 then
            ns.Tip_AddLine(" ")
            ns.Tip_AddLine(TELEPORTS_LABEL, ar, ag, ab)
            -- Insertion sort on active entries only.
            for i = 2, _teleCount do
                local j = i
                while j > 1 and _teleBuf[j].name < _teleBuf[j - 1].name do
                    _teleBuf[j], _teleBuf[j - 1] = _teleBuf[j - 1], _teleBuf[j]
                    j = j - 1
                end
            end
            -- Ready rows are click-to-teleport; cooling ones collapse into one "On Cooldown" line.
            local cdMin, cdUnknown
            for i = 1, _teleCount do
                local e = _teleBuf[i]
                if not e.cdKnown then
                    cdUnknown = true
                elseif e.cd <= 0 then
                    if e.isSpell then
                        ns.Tip_AddActionDouble(e.name, L["READY"], e.id, 0.8, 0.8, 0.8, 0, 1, 0)
                    elseif e.unequipped then
                        -- Kirin Tor rings must be worn: the secure item click equips it first.
                        ns.Tip_AddItemActionDouble(e.name, EQUIP_LABEL, e.id, 0.8, 0.8, 0.8, 1, 0.82, 0)
                    else
                        ns.Tip_AddItemActionDouble(e.name, L["READY"], e.id, 0.8, 0.8, 0.8, 0, 1, 0)
                    end
                elseif not cdMin or e.cd < cdMin then
                    cdMin = e.cd
                end
            end
            if cdMin then
                local cs = ns.FormatCooldown(cdMin)
                if not cs then cs = L["READY"] end
                ns.Tip_AddDouble(L["ON_COOLDOWN"], cs, 0.65, 0.65, 0.65, 0.5, 0.5, 0.5)
            elseif cdUnknown then
                ns.Tip_AddDouble(L["ON_COOLDOWN"], "-", 0.65, 0.65, 0.65, 0.5, 0.5, 0.5)
            end
        end
        ns.Tip_AddLine(" ")
        ns.Tip_AddDouble(L["LEFT_CLICK"], L["USE_HEARTHSTONE"], 1, 1, 1, ar, ag, ab)
        ns.Tip_AddDouble(L["RIGHT_CLICK"], L["RANDOM_HEARTHSTONE"], 1, 1, 1, ar, ag, ab)
        ns.Tip_Show()
    end

    -- 1 = the chosen hearthstone, 2 = always a random owned one (OOC only).
    local function ItemAttr(id)
        if not id then return nil end
        return GetItemInfo(id) or ("item:" .. id)
    end
    local function SeedMacro()
        if not hearthButton or InCombatLockdown() then return end
        hearthButton:SetAttribute("*item1", ItemAttr(ChosenHearthstone()))
        hearthButton:SetAttribute("*item2", ItemAttr(TravelPickHearthstone(true)))
    end

    local function Build()
        if built then return end
        built = true
        if placeholder then placeholder:Hide() end

        hearthButton = CreateFrame("Button", "EllesmereUIDataBarsHearth_" .. inst.key, content, "SecureActionButtonTemplate")
        hearthButton:SetAllPoints()
        hearthButton:EnableMouse(true)
        hearthButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        hearthButton:SetAttribute("*type1", "item")
        hearthButton:SetAttribute("*type2", "item")

        hearthIcon = hearthButton:CreateTexture(nil, "OVERLAY"); hearthIcon:SetTexture(HEARTH_TEX)
        hearthText = hearthButton:CreateFontString(nil, "OVERLAY")
        AttachTextOffset(inst, hearthText)

        -- Reseed on every PreClick (OOC only) so the button always fires the
        -- currently owned / freshly rolled hearthstone.
        hearthButton:SetScript("PreClick", function()
            if InCombatLockdown() then return end
            SeedMacro()
        end)

        hearthButton:SetScript("OnEnter", function()
            mouseOver = true
            inst:Refresh()
            RefreshTravelTooltip()
        end)
        hearthButton:SetScript("OnLeave", function()
            mouseOver = false
            ns.Tip_HideUnlessInteractive(hearthButton)
            inst:Refresh()
        end)

        SeedMacro()
    end

    -- Combat-deferred construction: dimmed non-interactive icon until OOC.
    if InCombatLockdown() then
        placeholder = content:CreateTexture(nil, "OVERLAY")
        placeholder:SetTexture(HEARTH_TEX)
        placeholder:SetVertexColor(0.6, 0.6, 0.6, 0.6)
        Size(placeholder, 16, 16)
        placeholder:SetPoint("CENTER")
        ns.DeferUntilOOC("edbbuild:" .. inst.key, function()
            if inst._dead then return end
            Build()
            inst:Refresh()
        end)
    else
        Build()
    end

    function inst:Refresh()
        if not built then return end
        local barCfg = BC()
        local barH = barCtx.GetThickness()
        local fontSize = max(9, floor(CONTENT_BASE * 0.4333 + 0.5))
        local isSide = barCtx.IsVertical()

        local location = GetBindLocation() or "?"
        ns.SetFont(hearthText, fontSize, barCfg)
        hearthText:SetText(location)

        -- Icon + bind location only; the remaining cooldown lives in the tooltip.
        local cd, cdKnown = TravelGetPrimaryCooldown()
        inst._lastCooling = (not cdKnown) or cd > 0
        TravelSyncTicker(mouseOver or inst._lastCooling)

        if mouseOver then
            local ar, ag, ab = ns.GetAccent()
            hearthText:SetTextColor(ar, ag, ab, 1); hearthIcon:SetVertexColor(ar, ag, ab, 1)
        elseif (not cdKnown) or cd > 0 then
            hearthText:SetTextColor(0.5, 0.5, 0.5, 1); hearthIcon:SetVertexColor(0.5, 0.5, 0.5, 1)
        else
            local br, bgr, bb = BlockColorOf(blockCfg)
            local ir, ig, ib = IconColorOf(blockCfg)
            hearthText:SetTextColor(br, bgr, bb, 1); hearthIcon:SetVertexColor(ir, ig, ib, 1)
        end

        -- Content hosts a secure button: geometry only out of combat.
        if InCombatLockdown() then return end

        local iconSz, gap = fontSize + 2, ICON_GAP - 2
        if isSide then
            iconSz = min(iconSz, max(14, floor(CONTENT_BASE * 0.72 + 0.5)))
        end
        hearthIcon:ClearAllPoints()
        Size(hearthIcon, iconSz, iconSz)

        if isSide then
            local slotW = VSlotW(inst)
            local innerW = max(30, slotW - 8)
            local totalH = 8 + iconSz + 2

            content:SetWidth(slotW)
            hearthButton:SetWidth(slotW)
            hearthIcon:SetPoint("TOP", hearthButton, "TOP", 0, -4)

            ns.SetWrappedText(hearthText, innerW, "CENTER")
            hearthText:ClearAllPoints()
            hearthText:SetPoint("TOP", hearthIcon, "BOTTOM", 0, -2)
            totalH = totalH + ns.SnapToPixelGrid(hearthText:GetStringHeight())

            totalH = max(totalH, barH)
            content:SetHeight(totalH)
            hearthButton:SetHeight(totalH)
        else
            local slotW = HBudget(inst, 120)
            iconSz = min(fontSize + 2, max(14, floor(CONTENT_BASE * 0.72 + 0.5)))
            Size(hearthIcon, iconSz, iconSz)
            ns.ResetInlineText(hearthText, "LEFT")
            local tw = ns.SnapToPixelGrid(hearthText:GetStringWidth())
            local totalW = min(slotW, iconSz + gap + tw + 4)
            Size(content, totalW, barH)
            Size(hearthButton, totalW, barH)
            hearthIcon:SetPoint("LEFT", hearthButton, "LEFT", 0, 0)
            hearthText:ClearAllPoints(); hearthText:SetPoint("LEFT", hearthButton, "LEFT", iconSz + gap, 0)
        end
        MaybeRelayout(inst)
    end

    -- 1s heartbeat. Hovered: full refresh for the tip's live M:SS columns.
    -- Un-hovered: a cheap cooling probe; Refresh runs only on the tint edge.
    local function TravelTick()
        if built and mouseOver and ns.Tip_IsOwned(hearthButton) then
            inst:Refresh()
            RefreshTravelTooltip()
            return
        end
        local pcd, pKnown = TravelGetPrimaryCooldown()
        local cooling = (not pKnown) or pcd > 0
        if cooling ~= inst._lastCooling then
            inst._lastCooling = cooling
            inst:Refresh()
        elseif not cooling and not mouseOver then
            TravelSyncTicker(false)
        end
    end

    TravelSyncTicker = function(want)
        if want then
            if not ticking then
                ticking = true
                ns.RegisterHeartbeat("travel:" .. inst.key, TravelTick)
            end
        elseif ticking then
            ticking = false
            ns.UnregisterHeartbeat("travel:" .. inst.key)
        end
    end

    local function OwnershipChanged()
        ns.TravelInvalidateHearthCache()
        SeedMacro()
        inst:Refresh()
    end
    -- BAG_UPDATE fires per bag in bursts: coalesce into one pass on the next frame.
    local function FlushBags(f)
        f:SetScript("OnUpdate", nil)
        OwnershipChanged()
    end
    inst.eventFrame = MakeEventFrame(inst, function(self, event, unit)
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            -- Cooldown-START lane: player casts only; one probe re-arms the tick.
            if unit == "player" and not ticking then TravelTick() end
            return
        end
        if event == "BAG_UPDATE" then
            self.eventFrame:SetScript("OnUpdate", FlushBags)
            return
        end
        OwnershipChanged()
    end)

    function inst:Enable()
        if not InCombatLockdown() then content:Show() end
        RegisterInstEvents(self)
        -- Armed as a belt; the first settled ready read stands it down.
        TravelSyncTicker(true)
    end

    function inst:Disable()
        TravelSyncTicker(false)
        UnregisterInstEvents(self)
        if not InCombatLockdown() then content:Hide() end
    end

    function inst:GetAutoLength()
        if not built then return 40 end
        local barH = barCtx.GetThickness()
        if barCtx.IsVertical() then
            local fontSize = max(9, floor(CONTENT_BASE * 0.4333 + 0.5))
            local textH = hearthText:GetStringHeight() or fontSize
            return max(8 + fontSize + 2 + textH + 4, barH, 50)
        end
        return max(content:GetWidth() or 120, 40)
    end

    function inst:Destroy()
        self._dead = true
        TravelSyncTicker(false)
        if hearthButton then
            ns.Tip_Hide(hearthButton)
            ParkSecureFrame(hearthButton, self.key .. "_hearth")
        end
        if not InCombatLockdown() then content:Hide() end
    end

    return inst
end
