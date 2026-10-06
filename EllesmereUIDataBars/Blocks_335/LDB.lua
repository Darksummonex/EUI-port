-- Blocks_335\LDB.lua
-- LibDataBroker plugin block factory (3.3.5 port of Retail Blocks\LDB.lua).
-- Restricted to EllesmereUI's own data objects (ns.IsOwnBroker): a source that
-- names any other addon's broker is treated as unconfigured and never read.
local _, ns = ...
if not ns.IsWrath then return end
local L = ns.L
local K = ns.BlockKit
local E = EllesmereUI

-- Upvalues
local CreateFrame      = CreateFrame
local InCombatLockdown = InCombatLockdown
local type             = type
local pcall            = pcall
local tostring         = tostring
local floor            = math.floor
local max              = math.max

local ICON_GAP             = K.ICON_GAP
local CONTENT_BASE         = K.CONTENT_BASE
local InstKey              = K.InstKey
local MakeEventFrame       = K.MakeEventFrame
local RegisterInstEvents   = K.RegisterInstEvents
local UnregisterInstEvents = K.UnregisterInstEvents
local VSlotW               = K.VSlotW
local MaybeRelayout        = K.MaybeRelayout
local AttachTextOffset     = K.AttachTextOffset
local BlockColorOf         = K.BlockColorOf
local IconColorOf          = K.IconColorOf
local Size                 = ns.Size

local function Loc(text)
    if text ~= nil and E and E.L then return E.L(text) end
    return text
end

-------------------------------------------------------------------------------
--  BROKER PLUGIN (LibDataBroker) -- one block type for EllesmereUI's brokers
-------------------------------------------------------------------------------
-- Three rules carried over from Retail:
--   1. Never write to the data object. A display READS; the plugin owns its own text.
--   2. Every call into the plugin (OnEnter/OnLeave/OnClick/OnTooltipShow/
--      OnMouseWheel) goes through pcall, so a plugin error never takes the bar's layout down.
--   3. Width is never assumed stable: this block measures live and offers a Max Width clamp.
--
-- Tooltips route three ways, in the plugin's own order of preference:
--   OnEnter        the plugin draws its own tooltip into the frame we hand it,
--                  and OnLeave takes it away. The owned tooltip stays out of it.
--   OnTooltipShow  the broker contract's GameTooltip path: the plugin writes
--                  into it directly, which we cannot re-render.
--   neither        name + text in the owned tooltip, so hover is never dead.

-- Attributes worth a repaint (the library fires a per-NAME event carrying the changed key).
local LDB_WATCH = {
    text = true, value = true, suffix = true, label = true,
    icon = true, iconR = true, iconG = true, iconB = true, iconCoords = true,
}

-- Broker text arrives full of the plugin's own color codes, which silently beat
-- this block's Text Color and its accent hover. Stripping them (default on)
-- hands the color back to the block; leaving them keeps the plugin's palette.
local function LDBStripColors(str)
    if not str then return str end
    str = str:gsub("|c%x%x%x%x%x%x%x%x", "")
    str = str:gsub("|cn[%a%d_]+:", "")   -- named-color form (|cnGREEN_FONT_COLOR:)
    str = str:gsub("|r", "")
    return str
end

-- text is the display string; value+suffix is the fallback pair for plugins
-- that publish the number and its unit separately.
local function LDBDisplayText(obj)
    if not obj then return nil end
    local t = obj.text
    if type(t) == "string" and t ~= "" then return t end
    local v = obj.value
    if v ~= nil then
        local str = tostring(v)
        local suf = obj.suffix
        if type(suf) == "string" and suf ~= "" then str = str .. " " .. suf end
        return str
    end
    return nil
end

-- Options surface is LoadOnDemand; load it so OpenBlockSettings exists.
local function OpenSettings(barId, blockId)
    if not ns.OpenBlockSettings and E and E.EnsureLoaded then pcall(E.EnsureLoaded, E) end
    if ns.OpenBlockSettings then pcall(ns.OpenBlockSettings, barId, blockId, "ldb") end
end

ns.BlockFactories.ldb = function(blockCfg, slot, content, barCtx)
    local inst = { cfg = blockCfg, slot = slot, content = content, ctx = barCtx }
    inst.key = InstKey(barCtx, blockCfg)

    local mouseOver = false
    local bound        -- source name we currently hold attribute callbacks for
    local tipMode      -- "own" | "gametip" | nil; picked at hover, read at leave

    -- A block built or re-sourced mid-combat settles here rather than waiting
    -- for a plugin update that may never come.
    inst.events = { "PLAYER_REGEN_ENABLED" }

    local function D() return blockCfg.settings or {} end
    local function BC() return barCtx.cfg end

    local button = CreateFrame("Button", nil, content)
    button:EnableMouse(true)
    button:RegisterForClicks("AnyUp")

    local icon = button:CreateTexture(nil, "OVERLAY")
    local text = button:CreateFontString(nil, "OVERLAY")
    AttachTextOffset(inst, text)

    -- The chosen source when it is one of EllesmereUI's own brokers; anything
    -- else reads as unconfigured.
    local function Source()
        local name = D().source
        if name and ns.IsOwnBroker(name) then return name end
        return nil
    end

    -- The chosen source's data object, or nil while it has not registered yet.
    local function Obj()
        local name = Source()
        if not name then return nil end
        local LDB = ns.GetLDB()
        if not LDB then return nil end
        return LDB:GetDataObjectByName(name)
    end

    local function Unbind()
        local LDB = ns.GetLDB()
        if LDB and bound then
            pcall(LDB.UnregisterCallback, inst, "LibDataBroker_AttributeChanged_" .. bound)
        end
        bound = nil
    end

    -- Idempotent: re-binds only when the chosen source actually changed.
    local function Bind()
        local name = Source()
        if bound == name then return end
        Unbind()
        if not name then return end
        local LDB = ns.GetLDB()
        if not LDB then return end
        -- Args are (event, sourceName, key, value, obj); only the key matters.
        local function OnAttr(_, _, key)
            if LDB_WATCH[key] and not inst._dead then inst:Refresh() end
        end
        pcall(LDB.RegisterCallback, inst, "LibDataBroker_AttributeChanged_" .. name, OnAttr)
        bound = name
    end

    -- Untouched Icon Color leaves the plugin's artwork alone, honouring the
    -- iconR/G/B tint if it declares one; any explicit choice in the options wins.
    local function IconTint(obj)
        local b = blockCfg
        if b.iconColor or b.useIconClassColor or b.useIconAccentColor or b.useIconDefaultColor then
            return IconColorOf(b)
        end
        if obj and type(obj.iconR) == "number" then
            return obj.iconR, obj.iconG or 1, obj.iconB or 1
        end
        return 1, 1, 1
    end

    function inst:Refresh()
        if self._dead then return end
        local s = D()
        local src = Source()
        local barCfg = BC()
        local barH = barCtx.GetThickness()
        local fontSize = max(9, floor(CONTENT_BASE * 0.4333 + 0.5))
        local isSide = barCtx.IsVertical()
        local gap = ICON_GAP
        Bind()

        local obj = Obj()

        -- An own source picked on a session where it registered, opened on one
        -- where it has not: collapse rather than show a dead slot. GetAutoLength
        -- reports 0 and the solver drops the block and its gaps entirely.
        local collapsed = (src ~= nil) and (obj == nil)
        if content:IsShown() == collapsed and not InCombatLockdown() then
            if collapsed then content:Hide() else content:Show() end
        end
        if collapsed then
            MaybeRelayout(inst)
            return
        end

        local str
        local placeholder = false
        if not src then
            -- Bar text goes straight through SetText, so translate by hand.
            str = Loc(L["SELECT_PLUGIN"])
            placeholder = true
        else
            local body = LDBDisplayText(obj)
            if s.showText == false then body = nil end
            local lbl = obj.label
            if s.showLabel and type(lbl) == "string" and lbl ~= "" then
                if body then str = lbl .. ": " .. body else str = lbl end
            else
                str = body
            end
            if s.stripColors ~= false then str = LDBStripColors(str) end
            if not str then str = "" end
        end

        local iconSz = 0
        local tex = obj and obj.icon
        if s.showIcon ~= false and tex then
            iconSz = fontSize + 2
            icon:SetTexture(tex)
            local c = obj.iconCoords
            if type(c) == "table" and #c == 4 then
                icon:SetTexCoord(c[1], c[2], c[3], c[4])
            else
                icon:SetTexCoord(0, 1, 0, 1)
            end
            Size(icon, iconSz, iconSz)
            local ir, ig, ib = IconTint(obj)
            icon:SetVertexColor(ir, ig, ib, 1)
            icon:Show()
        else
            icon:Hide()
        end

        -- Only steal the wheel for a plugin that asked for it.
        button:EnableMouseWheel((obj and obj.OnMouseWheel) ~= nil)

        if placeholder then
            text:SetTextColor(0.55, 0.55, 0.55, 1)
        elseif mouseOver then
            local ar, ag, ab = ns.GetAccent()
            text:SetTextColor(ar, ag, ab, 1)
        else
            local tr, tg, tb = BlockColorOf(blockCfg)
            text:SetTextColor(tr, tg, tb, 1)
        end

        ns.SetFont(text, fontSize, barCfg)

        if isSide then
            local slotW = VSlotW(inst)
            local innerW = max(24, slotW - 8)
            local totalH = 8
            if iconSz > 0 then
                icon:ClearAllPoints()
                icon:SetPoint("TOP", button, "TOP", 0, -4)
                totalH = totalH + iconSz + 2
            end
            ns.SetWrappedText(text, innerW, "CENTER")
            text:SetText(str)
            text:ClearAllPoints()
            if iconSz > 0 then
                text:SetPoint("TOP", icon, "BOTTOM", 0, -2)
            else
                text:SetPoint("TOP", button, "TOP", 0, -4)
            end
            totalH = totalH + ns.SnapToPixelGrid(text:GetStringHeight() or fontSize) + 4
            totalH = max(totalH, barH)
            Size(content, slotW, totalH)
            Size(button, slotW, totalH)
        else
            ns.ResetInlineText(text, "LEFT")
            text:SetText(str)
            local iconPad = 0
            if iconSz > 0 then
                iconPad = iconSz + gap
                icon:ClearAllPoints()
                icon:SetPoint("LEFT", button, "LEFT", 0, 0)
            end
            text:ClearAllPoints()
            text:SetPoint("LEFT", button, "LEFT", iconPad, 0)
            local w = s.maxWidth
            if w then
                -- Max Width: the block holds this width whatever the plugin
                -- publishes, and longer strings clip.
                text:SetWidth(max(20, w - iconPad - 2))
                if text.SetWordWrap then text:SetWordWrap(false) end
            else
                w = iconPad + ns.SnapToPixelGrid(text:GetStringWidth() or 40) + 2
            end
            if w < 24 then w = 24 end
            Size(content, w, barH)
            Size(button, w, barH)
        end

        button:ClearAllPoints()
        button:SetPoint("CENTER", content, "CENTER", 0, 0)
        MaybeRelayout(inst)
    end

    local function HideTip()
        if tipMode == "own" then
            local obj = Obj()
            if obj and obj.OnLeave then pcall(obj.OnLeave, button) end
        elseif tipMode == "gametip" then
            if GameTooltip:IsOwned(button) then GameTooltip:Hide() end
        else
            ns.Tip_Hide(button)
        end
        tipMode = nil
    end

    local function ShowTip()
        local ar, ag, ab = ns.GetAccent()
        -- Cleared up front so every early return below leaves the LAST hover's
        -- route behind: HideTip reads this to decide whose tooltip to take away.
        tipMode = nil
        -- Unconfigured: the placeholder is the whole block, so the tooltip has
        -- to say where a plugin is actually picked.
        local src = Source()
        if not src then
            ns.Tip_Begin(button)
            ns.Tip_AddLine(L["SELECT_PLUGIN"], 1, 1, 1)
            ns.Tip_AddLine(" ")
            ns.Tip_AddDouble(L["LEFT_CLICK"], L["OPEN_SETTINGS"], 1, 1, 1, ar, ag, ab)
            ns.Tip_Show()
            return
        end
        local obj = Obj()
        if not obj then return end
        if obj.OnEnter then
            tipMode = "own"
            pcall(obj.OnEnter, button)
            return
        end
        if obj.OnTooltipShow then
            tipMode = "gametip"
            GameTooltip:SetOwner(button, "ANCHOR_NONE")
            GameTooltip:ClearAllPoints()
            -- Same flip the owned tooltip does: a top bar drops its tooltip
            -- below itself, a bottom bar lifts it above.
            if barCtx.IsBarAtTop() then
                GameTooltip:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -6)
            else
                GameTooltip:SetPoint("BOTTOMLEFT", button, "TOPLEFT", 0, 6)
            end
            GameTooltip:ClearLines()
            if pcall(obj.OnTooltipShow, GameTooltip) then
                GameTooltip:Show()
            else
                GameTooltip:Hide()
                tipMode = nil
            end
            return
        end
        ns.Tip_Begin(button)
        ns.Tip_AddLine(ns.LDBLabel(src, obj), 1, 1, 1)
        local body = LDBDisplayText(obj)
        if body then
            ns.Tip_AddLine(" ")
            ns.Tip_AddLine(LDBStripColors(body), 0.8, 0.8, 0.8)
        end
        ns.Tip_Show()
    end

    button:SetScript("OnEnter", function()
        mouseOver = true
        inst:Refresh()
        ShowTip()
    end)
    button:SetScript("OnLeave", function()
        mouseOver = false
        HideTip()
        inst:Refresh()
    end)
    button:SetScript("OnClick", function(_, mb)
        -- No plugin picked yet: send the player to the picker instead of dead-ending there.
        if not Source() then
            OpenSettings(barCtx.id, blockCfg.id)
            return
        end
        local obj = Obj()
        if obj and obj.OnClick then pcall(obj.OnClick, button, mb) end
    end)
    button:SetScript("OnMouseWheel", function(_, delta)
        local obj = Obj()
        if obj and obj.OnMouseWheel then pcall(obj.OnMouseWheel, button, delta) end
    end)

    -- A source whose broker registers later binds the moment it appears;
    -- without this the block would sit collapsed until something forced a Refresh.
    local function OnCreated(_, name)
        if name ~= nil and name == Source() and not inst._dead then
            Bind()
            inst:Refresh()
        end
    end

    function inst:Enable()
        content:Show()
        if not self.eventFrame then
            self.eventFrame = MakeEventFrame(self, function(me)
                if not me._dead then me:Refresh() end
            end)
        end
        RegisterInstEvents(self)
        local LDB = ns.GetLDB()
        if LDB then
            pcall(LDB.RegisterCallback, inst, "LibDataBroker_DataObjectCreated", OnCreated)
        end
        Bind()
    end

    function inst:Disable()
        UnregisterInstEvents(self)
        local LDB = ns.GetLDB()
        if LDB then
            pcall(LDB.UnregisterCallback, inst, "LibDataBroker_DataObjectCreated")
        end
        Unbind()
        HideTip()
        content:Hide()
    end

    function inst:GetAutoLength()
        if not content:IsShown() then return 0 end
        if barCtx.IsVertical() then
            return max(content:GetHeight() or 40, 30)
        end
        return max(content:GetWidth() or 60, 24)
    end

    function inst:Destroy()
        self._dead = true
        UnregisterInstEvents(self)
        local LDB = ns.GetLDB()
        if LDB then
            pcall(LDB.UnregisterCallback, inst, "LibDataBroker_DataObjectCreated")
        end
        Unbind()
        HideTip()
        content:Hide()
    end

    return inst
end
