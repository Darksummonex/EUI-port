-- EllesmereUIDataBars 3.3.5: gold block factory and the shared session/character
-- ledger (port of Retail Blocks\Gold.lua; no warbank or WoW Token on Wrath).
local _, ns = ...
if not ns.IsWrath then return end
local E = EllesmereUI
local L = ns.L
local K = ns.BlockKit

-- Upvalues
local CreateFrame      = CreateFrame
local InCombatLockdown = InCombatLockdown
local pairs            = pairs
local ipairs           = ipairs
local type             = type
local format           = string.format
local tinsert          = table.insert
local tconcat          = table.concat
local tsort            = table.sort
local floor            = math.floor
local max              = math.max
local min              = math.min
local abs              = math.abs
local Size             = ns.Size

local ICON_GAP         = K.ICON_GAP
local CONTENT_BASE     = K.CONTENT_BASE
local InstKey          = K.InstKey
local HBudget          = K.HBudget
local VSlotW           = K.VSlotW
local MaybeRelayout    = K.MaybeRelayout
local AttachTextOffset = K.AttachTextOffset
local BlockColorOf     = K.BlockColorOf
local IconColorOf      = K.IconColorOf

-- Roster rows list balances above this (copper) plus the live character; the
-- Retail 10,000 g cut scaled to Wrath's economy. Filtered characters still sum into the total.
local ROSTER_MIN_COPPER = 100 * 10000

-------------------------------------------------------------------------------
--  GOLD (engine-level session ledger + cross-character store)
-------------------------------------------------------------------------------
-- One PLAYER_MONEY ledger shared by every gold instance; ctrl-right-click resets the shared session.
local goldLedger = { profit = 0, spent = 0, lastMoney = nil }
local goldInstances, goldQueued = {}, {}
local goldEventFrame

local function GoldCharKey()
    return (UnitName("player") or "Unknown") .. "-" .. (GetRealmName() or "Unknown")
end

-- ACCOUNT-level (EllesmereUIDB.dataBarsGold), never the profile: profiles are
-- shared and exported, the roster lists the player's characters and balances.
local function GoldStore()
    if type(EllesmereUIDB) ~= "table" then return {} end
    local store = EllesmereUIDB.dataBarsGold
    if type(store) ~= "table" then
        store = {}
        EllesmereUIDB.dataBarsGold = store
    end
    return store
end
ns.GoldStore = GoldStore

local function QueueAll()
    for gi in pairs(goldInstances) do gi:QueueRefresh() end
end

local function GoldForgetCharacter(key)
    GoldStore()[key] = nil
    QueueAll()
end

local function GoldSaveCurrentMoney(money)
    local store = GoldStore()
    local _, class = UnitClass("player")
    store[GoldCharKey()] = { currentMoney = money, class = class, realm = GetRealmName(), name = UnitName("player") }
end

local function GoldLedgerUpdate()
    local money = GetMoney()
    if type(money) ~= "number" then return end
    if goldLedger.lastMoney then
        local diff = money - goldLedger.lastMoney
        if diff > 0 then goldLedger.profit = goldLedger.profit + diff
        elseif diff < 0 then goldLedger.spent = goldLedger.spent + (-diff) end
    end
    goldLedger.lastMoney = money
    GoldSaveCurrentMoney(money)
end

local function GoldResetSession()
    goldLedger.profit = 0
    goldLedger.spent = 0
    QueueAll()
end
ns.GoldResetSession = GoldResetSession

local function GoldOnEvent(_, event)
    -- BAG_UPDATE changes bag slots only, never money.
    if event ~= "BAG_UPDATE" then GoldLedgerUpdate() end
    QueueAll()
end

local function UpdateGoldEvents()
    if next(goldInstances) then
        if not goldEventFrame then
            goldEventFrame = CreateFrame("Frame")
            goldEventFrame:SetScript("OnEvent", GoldOnEvent)
        end
        goldEventFrame:RegisterEvent("PLAYER_MONEY")
        goldEventFrame:RegisterEvent("BAG_UPDATE")
    elseif goldEventFrame then
        goldEventFrame:UnregisterAllEvents()
    end
end

-- Next-frame coalescing (C_Timer.After(0) on Retail): one shared OnUpdate, shown only while queued.
local goldQueueFrame = CreateFrame("Frame")
goldQueueFrame:Hide()
goldQueueFrame:SetScript("OnUpdate", function(self)
    self:Hide()
    for gi in pairs(goldQueued) do
        goldQueued[gi] = nil
        gi._refreshQueued = false
        if goldInstances[gi] then gi:Refresh() end
    end
end)

-- General-purpose bags only (family 0): a quiver, soul bag or profession bag cannot take ordinary loot.
local function GetFreeBagSlots()
    local free = 0
    for i = 0, NUM_BAG_SLOTS or 4 do
        local n, family = GetContainerNumFreeSlots(i)
        if n and (not family or family == 0) then free = free + n end
    end
    return free
end

-- EllesmereUI Bags 3.3.5 window when it owns the bags, Blizzard bags otherwise.
local function ToggleBagsUI()
    local bags = E._ModuleNS and E._ModuleNS.EllesmereUIBags
    local p = bags and bags.GetSettings and bags.GetSettings()
    if p and p.enhancedBags and bags.Toggle and not InCombatLockdown() then bags.Toggle(); return end
    if ToggleAllBags then ToggleAllBags() elseif OpenAllBags then OpenAllBags() end
end

ns.BlockFactories.gold = function(blockCfg, slot, content, barCtx)
    local inst = { cfg = blockCfg, slot = slot, content = content, ctx = barCtx }
    inst.key = InstKey(barCtx, blockCfg)

    local GOLD_TEX = ns.MICROMENU_MEDIA .. "menu-bags"
    local mouseOver = false

    -- Coin Colored is the default text mode, forced once onto existing blocks;
    -- the marker makes every later swatch choice stick.
    if not blockCfg.coinForced then
        blockCfg.coinForced = true
        blockCfg.useCoinColor = true
        blockCfg.useClassColor = nil
        blockCfg.useAccentColor = nil
    end

    local function D() return blockCfg.settings or {} end
    local function BC() return barCtx.cfg end

    local goldButton = CreateFrame("Button", nil, content)
    Size(goldButton, 120, 20); goldButton:SetPoint("CENTER")
    goldButton:EnableMouse(true); goldButton:RegisterForClicks("AnyUp")

    local goldIcon = goldButton:CreateTexture(nil, "OVERLAY"); goldIcon:SetTexture(GOLD_TEX)
    local goldText = goldButton:CreateFontString(nil, "OVERLAY")
    local bagText  = goldButton:CreateFontString(nil, "OVERLAY")
    AttachTextOffset(inst, goldText)   -- bagText chains to goldText

    function inst:Refresh()
        local dg = D()
        local barCfg = BC()
        local barH = barCtx.GetThickness()
        local fontSize = max(9, floor(CONTENT_BASE * 0.4333 + 0.5))
        local iconSz = 0
        if dg.showIcons ~= false then iconSz = fontSize + 4 end
        local gap = ICON_GAP - 2
        local isSide = barCtx.IsVertical()

        ns.SetFont(goldText, fontSize, barCfg)
        ns.SetFont(bagText, fontSize, barCfg)

        local money = GetMoney()
        local sm = dg.showSmall == true
        local ci = dg.coinIcons == true
        local ab = dg.abbreviate == true
        local fe = dg.forceEnglishUnits == true
        if isSide then
            -- One token per coin, one coin per line; hovering drops the coin tint so the accent wash reads.
            local lines = ns.MoneyTokens(money, sm, ci, blockCfg.useCoinColor == true and not mouseOver, ab, fe)
            local startSize = min(fontSize, max(10, floor(CONTENT_BASE * 0.52 + 0.5)))
            ns.SetFont(goldText, startSize, barCfg)
            goldText:SetText(tconcat(lines, "\n"))
            local r, g, b
            if mouseOver then r, g, b = ns.GetAccent()
            elseif blockCfg.useCoinColor then r, g, b = 1, 1, 1
            else r, g, b = BlockColorOf(blockCfg) end
            goldText:SetTextColor(r, g, b, 1)
        elseif mouseOver then
            goldText:SetText(ns.FormatMoney(money, false, sm, ci, ab, fe))
            local r, g, b = ns.GetAccent()
            goldText:SetTextColor(r, g, b, 1)
        else
            goldText:SetText(ns.FormatMoney(money, blockCfg.useCoinColor == true, sm, ci, ab, fe))
            if blockCfg.useCoinColor then
                goldText:SetTextColor(1, 1, 1, 1)
            else
                goldText:SetTextColor(BlockColorOf(blockCfg))
            end
        end

        if dg.showBagSpace == true then
            bagText:SetText("(" .. GetFreeBagSlots() .. ")"); bagText:Show()
        else
            bagText:Hide()
        end

        local r, g, b
        if mouseOver then r, g, b = ns.GetAccent()
        elseif blockCfg.useCoinColor then r, g, b = 1, 1, 1
        else r, g, b = BlockColorOf(blockCfg) end
        bagText:SetTextColor(r, g, b, 1)

        if dg.showIcons ~= false and iconSz > 0 then
            Size(goldIcon, iconSz, iconSz)
            if mouseOver then
                goldIcon:SetVertexColor(r, g, b, 1)
            else
                local ir, ig, ib = IconColorOf(blockCfg)
                goldIcon:SetVertexColor(ir, ig, ib, 1)
            end
            goldIcon:Show()
        else
            goldIcon:Hide(); iconSz = 0
        end

        if isSide then
            local slotW = VSlotW(inst)
            local innerW = max(30, slotW - 8)
            local totalH = 8

            if iconSz > 0 then
                goldIcon:ClearAllPoints()
                goldIcon:SetPoint("TOP", goldButton, "TOP", 0, -4)
                totalH = totalH + iconSz + 2
            end

            ns.SetWrappedText(goldText, innerW, "CENTER")
            goldText:ClearAllPoints()
            if iconSz > 0 then
                goldText:SetPoint("TOP", goldIcon, "BOTTOM", 0, -2)
            else
                goldText:SetPoint("TOP", goldButton, "TOP", 0, -4)
            end
            totalH = totalH + ns.SnapToPixelGrid(goldText:GetStringHeight())

            if bagText:IsShown() then
                ns.SetWrappedText(bagText, innerW, "CENTER")
                bagText:ClearAllPoints()
                bagText:SetPoint("TOP", goldText, "BOTTOM", 0, -2)
                totalH = totalH + 2 + ns.SnapToPixelGrid(bagText:GetStringHeight())
            end

            totalH = max(totalH, barH)
            Size(goldButton, slotW, totalH)
            Size(content, slotW, totalH)
            goldButton:ClearAllPoints(); goldButton:SetPoint("CENTER", content, "CENTER", 0, 0)
        else
            local slotW = HBudget(inst, 100)
            -- Width from BOTH money formats so the frame never resizes on hover.
            local plainText = ns.FormatMoney(money, false, sm, ci, ab, fe)
            local fancyText = ns.FormatMoney(money, blockCfg.useCoinColor == true, sm, ci, ab, fe)
            local moneyText
            if mouseOver then moneyText = plainText else moneyText = fancyText end
            local bagTextValue = ""
            if dg.showBagSpace == true then bagTextValue = "(" .. GetFreeBagSlots() .. ")" end
            local fitSize = fontSize
            ns.SetFont(goldText, fitSize, barCfg)
            ns.SetFont(bagText, fitSize, barCfg)
            goldText:SetText(moneyText)
            if bagTextValue ~= "" then bagText:SetText(bagTextValue) end
            ns.ResetInlineText(goldText, "LEFT")
            ns.ResetInlineText(bagText, "LEFT")
            iconSz = 0
            if dg.showIcons ~= false then iconSz = fitSize + 4 end
            Size(goldIcon, max(1, iconSz), max(1, iconSz))
            goldIcon:ClearAllPoints(); goldIcon:SetPoint("LEFT", goldButton, "LEFT", 0, 0)
            goldText:ClearAllPoints(); goldText:SetPoint("LEFT", goldButton, "LEFT", iconSz + gap, 0)
            local bagW = 0
            if dg.showBagSpace == true then bagW = (bagText:GetStringWidth() or 0) + 4 end
            bagText:ClearAllPoints(); bagText:SetPoint("LEFT", goldText, "RIGHT", 4, 0)

            local moneyW = goldText:GetStringWidth() or 0
            local measureFS = ns.MeasureFS()
            if measureFS then
                ns.SetFont(measureFS, fitSize, barCfg)
                local other
                if mouseOver then other = fancyText else other = plainText end
                measureFS:SetText(other)
                moneyW = max(moneyW, measureFS:GetStringWidth() or 0)
            end
            local textW = min(slotW, iconSz + gap + moneyW + bagW + 4)
            Size(goldButton, textW, barH)
            Size(content, textW, barH)
            goldButton:ClearAllPoints(); goldButton:SetPoint("CENTER", content, "CENTER", 0, 0)
        end
        MaybeRelayout(inst)
    end

    function inst:QueueRefresh()
        if self._refreshQueued then return end
        self._refreshQueued = true
        goldQueued[self] = true
        goldQueueFrame:Show()
    end

    goldButton:SetScript("OnEnter", function()
        mouseOver = true
        inst:Refresh()
        local d = D()
        local sm = d.showSmall == true
        local ci = d.coinIcons == true
        -- Show Tooltip Data checklist: each section defaults ON.
        local showSession = d.tipSession ~= false
        local showChars   = d.tipCharacters ~= false
        local ar, ag, ab = 1, 1, 1
        ns.Tip_Begin(goldButton)
        ns.Tip_AddLine(L["GOLD"], ar, ag, ab)
        if showSession then
            ns.Tip_AddLine(" ")
            ns.Tip_AddLine(L["SESSION"], 0.8, 0.8, 0.8)
            ns.Tip_AddDouble(L["EARNED"], ns.FormatMoney(goldLedger.profit, true, sm, ci), 0.6, 0.6, 0.6, 0, 1, 0)
            ns.Tip_AddDouble(L["SPENT"],  ns.FormatMoney(goldLedger.spent,  true, sm, ci), 0.6, 0.6, 0.6, 1, 0.3, 0.3)
            local net = goldLedger.profit - goldLedger.spent
            if net ~= 0 then
                local label
                if net > 0 then label = L["PROFIT"] else label = L["DEFICIT"] end
                local nr, ngr = 1, 0.3
                if net > 0 then nr, ngr = 0, 1 end
                ns.Tip_AddDouble(label, ns.FormatMoney(abs(net), true, sm, ci), 0.6, 0.6, 0.6, nr, ngr, 0.3)
            end
        end
        local charCount = 0
        if showChars then
            local store = GoldStore()
            local selfKey = GoldCharKey()
            local total, charList = 0, {}
            for key, cdata in pairs(store) do
                local cm = type(cdata) == "table" and cdata.currentMoney
                if type(cm) == "number" then
                    if cm > ROSTER_MIN_COPPER or key == selfKey then
                        tinsert(charList, key)
                    end
                    total = total + cm
                end
            end
            tsort(charList, function(a, b)
                return (store[a].currentMoney or 0) > (store[b].currentMoney or 0)
            end)
            charCount = #charList
            if charCount > 0 then
                ns.Tip_AddLine(" ")
                ns.Tip_AddLine(GetRealmName() or "?", 0.5, 0.78, 1)
                -- Cap roster rows (richest first); the live character always shows.
                local maxRows, shownRows, hiddenRows = 10, 0, 0
                for _, key in ipairs(charList) do
                    local char = store[key]
                    if shownRows >= maxRows and key ~= selfKey then
                        hiddenRows = hiddenRows + 1
                    else
                        shownRows = shownRows + 1
                        local cr, cg, cb = 1, 1, 1
                        if char.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[char.class] then
                            local cc = RAID_CLASS_COLORS[char.class]; cr, cg, cb = cc.r, cc.g, cc.b
                        end
                        local label = char.name or "?"
                        local tokens = ns.MoneyTokens(char.currentMoney, sm, ci, true)
                        -- The live character's click is inert (it re-saves on every money event).
                        ns.Tip_AddClickableColumns(label, tokens, function(mouseButton)
                            if key == selfKey then return end
                            if mouseButton ~= "LeftButton" then return end
                            if not (IsControlKeyDown() and IsAltKeyDown()) then return end
                            GoldForgetCharacter(key)
                            ns.Tip_Hide(goldButton)
                        end, cr, cg, cb)
                    end
                end
                if hiddenRows > 0 then
                    ns.Tip_AddLine(format(L["PLUS_N_MORE"], hiddenRows), 0.6, 0.6, 0.6)
                end
            end
            ns.Tip_AddLine(" ")
            ns.Tip_AddDouble(L["TOTAL"], ns.FormatMoney(total, true, sm, ci), ar, ag, ab, 1, 1, 1)
        end
        ns.Tip_AddLine(" ")
        ns.Tip_AddDouble(L["LEFT_CLICK"],       L["OPEN_BAGS"],       1, 1, 1, ar, ag, ab)
        ns.Tip_AddDouble(L["RIGHT_CLICK"],      L["OPEN_CURRENCIES"], 1, 1, 1, ar, ag, ab)
        ns.Tip_AddDouble(L["CTRL_RIGHT_CLICK"], L["RESET_SESSION"],   1, 1, 1, ar, ag, ab)
        if charCount > 1 then
            ns.Tip_AddDouble(L["CTRL_ALT_LEFT_CLICK"], L["REMOVE_CHARACTER"], 1, 1, 1, ar, ag, ab)
        end
        ns.Tip_Show()
    end)
    goldButton:SetScript("OnLeave", function()
        mouseOver = false
        -- The character rows are clickable, so the tooltip survives the cursor leaving the block.
        ns.Tip_HideUnlessInteractive(goldButton)
        inst:Refresh()
    end)
    goldButton:SetScript("OnClick", function(_, button)
        if IsControlKeyDown() and button == "RightButton" then
            GoldResetSession()
            inst:Refresh()
        elseif button == "RightButton" then
            if ToggleCharacter then ToggleCharacter("TokenFrame") end
        elseif button == "LeftButton" then
            ToggleBagsUI()
        end
    end)

    function inst:Enable()
        content:Show()
        if goldLedger.lastMoney == nil then
            goldLedger.lastMoney = GetMoney()
            goldLedger.profit = 0
            goldLedger.spent = 0
            GoldSaveCurrentMoney(goldLedger.lastMoney)
        end
        goldInstances[self] = true
        UpdateGoldEvents()
    end

    function inst:Disable()
        goldInstances[self] = nil
        goldQueued[self] = nil
        self._refreshQueued = false
        UpdateGoldEvents()
        content:Hide()
    end

    function inst:GetAutoLength()
        if barCtx.IsVertical() then
            local barH = barCtx.GetThickness()
            local fontSize = max(9, floor(CONTENT_BASE * 0.4333 + 0.5))
            local iconTerm = 0
            local dg = blockCfg.settings
            if not dg or dg.showIcons ~= false then iconTerm = fontSize + 2 end
            local textH = goldText:GetStringHeight() or fontSize
            local bagH = 0
            if bagText:IsShown() then bagH = (bagText:GetStringHeight() or 0) + 2 end
            return max(8 + iconTerm + textH + bagH + 4, barH, 50)
        end
        return max(content:GetWidth() or 100, 40)
    end

    function inst:Destroy()
        self._dead = true
        goldInstances[self] = nil
        goldQueued[self] = nil
        UpdateGoldEvents()
        content:Hide()
    end

    return inst
end
