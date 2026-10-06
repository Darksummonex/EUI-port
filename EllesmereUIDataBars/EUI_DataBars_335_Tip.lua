-- EllesmereUIDataBars 3.3.5: owned rich tooltip, popup helper and frame pool.
-- Port of the Retail ns.Tip_* family: one tooltip frame with pooled two-column
-- rows, aligned token sub-columns, wrapped prose, click-to-cast rows (secure
-- buttons on a host the [combat] driver hides), insecure clickable rows with
-- optional wheel handlers and a keep-alive hover poll. Wrath has no toy action
-- type and no secret values; spell rows cast by localized spell name.
local _, ns = ...
if not ns.IsWrath then return end
local E = EllesmereUI
local CreateFrame, UIParent, InCombatLockdown = CreateFrame, UIParent, InCombatLockdown
local max = math.max
local PP = E.PP
local Size, Solid = ns.Size, ns.Solid

local function Loc(text) if text ~= nil and E.L then return E.L(text) end; return text end

-------------------------------------------------------------------------------
--  Frame pool (popup rows)
-------------------------------------------------------------------------------
function ns.CreateFramePool(frameType, parent, template)
    local pool = { _type = frameType, _parent = parent, _template = template, _active = {}, _inactive = {} }
    function pool:Acquire()
        local f = table.remove(self._inactive)
        if not f then f = CreateFrame(self._type, nil, self._parent, self._template) end
        f:SetParent(self._parent)
        f:Show()
        self._active[#self._active + 1] = f
        return f
    end
    local function Reset(f)
        f:Hide(); f:ClearAllPoints(); f:SetParent(pool._parent); f:SetAlpha(1); f:SetScale(1)
        Size(f, 1, 1)
        f:EnableMouse(false)
        if f.RegisterForClicks then f:RegisterForClicks() end
        for _, s in ipairs({ "OnEnter", "OnLeave", "OnClick", "OnMouseDown", "OnMouseUp", "OnUpdate", "OnShow", "OnHide" }) do
            pcall(f.SetScript, f, s, nil)
        end
        if f.SetButtonState then f:SetButtonState("NORMAL") end
        if f.SetChecked then f:SetChecked(false) end
        if f.SetText then f:SetText("") end
        for i = 1, f:GetNumRegions() do
            local r = select(i, f:GetRegions())
            if r then
                r:Hide(); r:SetAlpha(1); r:ClearAllPoints()
                if r.SetText then r:SetText("") end
                if r.SetTexture then r:SetTexture(nil); r:SetVertexColor(1, 1, 1, 1); r:SetTexCoord(0, 1, 0, 1) end
            end
        end
    end
    function pool:ReleaseAll()
        for i = #self._active, 1, -1 do
            local f = table.remove(self._active, i)
            Reset(f)
            self._inactive[#self._inactive + 1] = f
        end
    end
    return pool
end

-------------------------------------------------------------------------------
--  Popup helper: one shared click-catcher closes whichever popup is open
-------------------------------------------------------------------------------
do
    local catcher, activePopup
    local function GetCatcher()
        if not catcher then
            catcher = CreateFrame("Button", nil, UIParent)
            catcher:SetAllPoints(UIParent)
            catcher:SetFrameStrata("DIALOG")
            catcher:SetFrameLevel(100)
            catcher:Hide()
            catcher:EnableMouse(true)
            catcher:RegisterForClicks("AnyDown", "AnyUp")
            catcher:SetScript("OnClick", function() if activePopup and activePopup:IsShown() then activePopup:Hide() end end)
        end
        return catcher
    end
    function ns.CreatePopupFrame()
        local popup = CreateFrame("Frame", nil, UIParent)
        local bg = popup:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        Solid(bg, 0.067, 0.067, 0.067, 0.97)
        if PP and PP.CreateBorder then PP.CreateBorder(popup, 0, 0, 0, 0.9, 1, "OVERLAY", 7) end
        popup:SetFrameStrata("TOOLTIP")
        popup:SetClampedToScreen(true)
        popup:Hide()
        if popup.SetToplevel then popup:SetToplevel(true) end
        local cc = GetCatcher()
        popup._wbClickCatcher = cc
        popup:SetFrameLevel(cc:GetFrameLevel() + 10)
        popup:SetScript("OnShow", function(self)
            activePopup = self
            if not self._wbNoCatcher then
                cc:ClearAllPoints(); cc:SetAllPoints(UIParent); cc:Show()
                cc:SetFrameStrata(self:GetFrameStrata())
                cc:SetFrameLevel(max(1, self:GetFrameLevel() - 1))
            end
        end)
        popup:SetScript("OnHide", function(self)
            if activePopup == self then activePopup = nil end
            if not activePopup or not activePopup:IsShown() then cc:Hide() end
            if self._wbOnHide then self:_wbOnHide() end
        end)
        return popup
    end
end

-------------------------------------------------------------------------------
--  Owned rich tooltip
-------------------------------------------------------------------------------
do
    local tip, owner
    local rows, data, colW = {}, {}, {}
    local dataCount = 0
    local PAD, ROW_GAP, COL_GAP, TOKEN_GAP, FONT_SIZE, TIP_LEVEL = 10, 3, 18, 8, 12, 100
    local actionPool, activeActions, actionHost, actionsDirty = {}, 0, nil, false
    local clickPool, activeClicks, clickRow = {}, 0, 0
    local interactive, forceInteractive = false, false
    local keepAlive, missed, kaElapsed = false, 0, 0
    local KA_SLACK = 12

    local function EnsureTip()
        if tip then return tip end
        tip = CreateFrame("Frame", "EllesmereUIDataBarsTip", UIParent)
        tip:SetFrameStrata("TOOLTIP")
        tip:SetFrameLevel(TIP_LEVEL)
        tip:SetClampedToScreen(true)
        tip:SetScript("OnMouseWheel", function() end)
        tip:EnableMouseWheel(false)
        tip:Hide()
        local bg = tip:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        Solid(bg, 0.067, 0.067, 0.067, 0.97)
        if PP and PP.CreateBorder then PP.CreateBorder(tip, 0, 0, 0, 0.9, 1, "OVERLAY", 7) end
        tip:SetScript("OnUpdate", function(_, dt)
            if not keepAlive then return end
            kaElapsed = kaElapsed + (dt or 0)
            if kaElapsed < 0.1 then return end
            kaElapsed = 0
            if ns.MouseOver(owner, KA_SLACK) or ns.MouseOver(tip, KA_SLACK) then missed = 0
            else missed = missed + 1; if missed >= 2 then ns.Tip_Hide() end end
        end)
        return tip
    end
    ns.EnsureTip = EnsureTip

    local function EnsureRow(i)
        local row = rows[i]
        if not row then
            row = { left = tip:CreateFontString(nil, "OVERLAY"), right = tip:CreateFontString(nil, "OVERLAY"), cols = {} }
            rows[i] = row
        end
        return row
    end
    local function EnsureCol(row, c)
        if not row.cols[c] then row.cols[c] = tip:CreateFontString(nil, "OVERLAY") end
        return row.cols[c]
    end
    local function HideCols(row, from) for c = from, #row.cols do row.cols[c]:Hide() end end
    local function SetWrap(fs, on) if fs.SetWordWrap then fs:SetWordWrap(on) end end

    local function ClearActionButtons()
        for i = 1, #actionPool do
            local b = actionPool[i]
            b:Hide(); b:ClearAllPoints(); b:SetScript("OnEnter", nil); b:SetScript("OnLeave", nil)
        end
        activeActions = 0
    end
    local function HideActionButtons()
        if activeActions == 0 and not actionsDirty then return end
        if InCombatLockdown() then actionsDirty = true; return end
        actionsDirty = false
        ClearActionButtons()
    end
    local function EnsureActionHost()
        if actionHost then return actionHost end
        actionHost = CreateFrame("Frame", "EllesmereUIDataBarsTipActions", UIParent, "SecureHandlerStateTemplate")
        actionHost:SetFrameStrata("TOOLTIP")
        actionHost:SetFrameLevel(TIP_LEVEL + 10)
        actionHost:SetAllPoints(tip)
        RegisterStateDriver(actionHost, "visibility", "[combat] hide; show")
        local regen = CreateFrame("Frame")
        regen:RegisterEvent("PLAYER_REGEN_ENABLED")
        regen:SetScript("OnEvent", function() if actionsDirty then HideActionButtons() end end)
        return actionHost
    end
    local function AddRowHighlight(b)
        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        Solid(hl, 1, 1, 1, 0.10)
    end
    local function AcquireActionButton()
        activeActions = activeActions + 1
        local b = actionPool[activeActions]
        if not b then
            b = CreateFrame("Button", nil, EnsureActionHost(), "SecureActionButtonTemplate")
            b:SetFrameLevel(TIP_LEVEL + 10)
            b:EnableMouse(true)
            b:RegisterForClicks("AnyUp")
            AddRowHighlight(b)
            b:SetAttribute("type", "spell")
            b:HookScript("PostClick", function() ns.Tip_Hide() end)
            actionPool[activeActions] = b
        end
        return b
    end
    local function HideClickButtons()
        if activeClicks == 0 then return end
        for i = 1, #clickPool do
            local b = clickPool[i]
            b:Hide(); b:ClearAllPoints()
            b:SetScript("OnClick", nil); b:SetScript("OnEnter", nil); b:SetScript("OnLeave", nil); b:SetScript("OnMouseWheel", nil)
            b:EnableMouseWheel(false)
        end
        activeClicks = 0
    end
    local function AcquireClickButton()
        activeClicks = activeClicks + 1
        local b = clickPool[activeClicks]
        if not b then
            b = CreateFrame("Button", nil, EnsureTip())
            b:SetFrameLevel(tip:GetFrameLevel() + 5)
            b:EnableMouse(true)
            b:RegisterForClicks("AnyUp")
            AddRowHighlight(b)
            clickPool[activeClicks] = b
        end
        return b
    end
    local function PlaceRowOverlay(b, i, innerW)
        local d, row = data[i], rows[i]
        local want = tip:GetFrameLevel() + 5
        if b:GetFrameLevel() < want then b:SetFrameLevel(want) end
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", tip, "TOPLEFT", PAD, d._y)
        Size(b, max(1, innerW), max(1, d._h))
        local ar, ag, ab = ns.GetAccent()
        local lr, lg, lb = d.lr or 1, d.lg or 1, d.lb or 1
        b:SetScript("OnEnter", function() row.left:SetTextColor(ar, ag, ab, 1) end)
        b:SetScript("OnLeave", function() row.left:SetTextColor(lr, lg, lb, 1) end)
        b:Show()
    end
    local function NewRow()
        dataCount = dataCount + 1
        local d = data[dataCount]
        if not d then d = {}; data[dataCount] = d end
        d.r, d.wrap, d.action, d.actionMacro, d.actionItem, d._padBand, d.onClick, d.onWheel, d.ncols, d._h = nil
        return d
    end

    function ns.Tip_Begin(ownerFrame)
        EnsureTip()
        owner = ownerFrame
        dataCount, clickRow, forceInteractive = 0, 0, false
    end
    function ns.Tip_AddLine(text, r, g, b)
        if not tip then return end
        clickRow = 0
        local d = NewRow()
        d.l = Loc(text) or " "
        d.lr, d.lg, d.lb = r, g, b
        return true
    end
    function ns.Tip_AddWrappedLine(text, maxWidth, r, g, b)
        if ns.Tip_AddLine(text, r, g, b) then data[dataCount].wrap = maxWidth or 280 end
    end
    function ns.Tip_AddDouble(left, right, lr, lg, lb, rr, rg, rb)
        if not tip then return end
        clickRow = 0
        local d = NewRow()
        d.l = Loc(left) or " "
        d.lr, d.lg, d.lb = lr, lg, lb
        d.r = Loc(right) or ""
        d.rr, d.rg, d.rb = rr, rg, rb
        return true
    end
    function ns.Tip_AddColumns(left, tokens, lr, lg, lb)
        if not tip then return end
        clickRow = 0
        local d = NewRow()
        d.l = left or " "
        d.lr, d.lg, d.lb = lr, lg, lb
        local n = tokens and #tokens or 0
        d.ncols = n > 0 and n or nil
        if n > 0 then
            d.cols = d.cols or {}
            for i = 1, n do d.cols[i] = tokens[i] end
        end
        return true
    end
    -- spellID MUST be a static integer; the row casts it by localized name.
    function ns.Tip_AddActionDouble(left, right, spellID, lr, lg, lb, rr, rg, rb)
        if ns.Tip_AddDouble(left, right, lr, lg, lb, rr, rg, rb) and spellID then data[dataCount].action = spellID end
    end
    function ns.Tip_AddItemActionDouble(left, right, itemID, lr, lg, lb, rr, rg, rb)
        if ns.Tip_AddDouble(left, right, lr, lg, lb, rr, rg, rb) and itemID then data[dataCount].actionItem = itemID end
    end
    ns.Tip_AddToyActionDouble = ns.Tip_AddItemActionDouble
    function ns.Tip_AddMacroActionDouble(left, right, macrotext, lr, lg, lb, rr, rg, rb)
        if ns.Tip_AddDouble(left, right, lr, lg, lb, rr, rg, rb) and macrotext then data[dataCount].actionMacro = macrotext end
    end
    function ns.Tip_PadRow() if tip and dataCount > 0 then data[dataCount]._padBand = true end end
    function ns.Tip_AddClickable(left, right, onClick, lr, lg, lb, rr, rg, rb)
        if ns.Tip_AddDouble(left, right, lr, lg, lb, rr, rg, rb) and onClick then
            data[dataCount].onClick = onClick
            clickRow = dataCount
        end
    end
    function ns.Tip_AddClickableColumns(left, tokens, onClick, lr, lg, lb)
        if ns.Tip_AddColumns(left, tokens, lr, lg, lb) and onClick then
            data[dataCount].onClick = onClick
            clickRow = dataCount
        end
    end
    function ns.Tip_SetRowWheel(onWheel) if clickRow > 0 then data[clickRow].onWheel = onWheel end end

    local function Padded(d) return d.action or d.actionMacro or d.actionItem or d._padBand end

    function ns.Tip_Show()
        if not tip or not owner then return end
        local gt = GameTooltip and GameTooltip:GetFrameLevel()
        local lvl = TIP_LEVEL
        if gt and gt >= lvl then lvl = gt + 10 end
        if tip:GetFrameLevel() < lvl then tip:SetFrameLevel(lvl) end
        local maxLeft, maxRight, totalH, colCount = 0, 0, 0, 0
        local anyRight, maxWrap, anyWrap = false, 0, false
        for k in pairs(colW) do colW[k] = nil end
        for i = 1, dataCount do
            local d = data[i]
            local row = EnsureRow(i)
            ns.SetFont(row.left, FONT_SIZE)
            ns.SetFont(row.right, FONT_SIZE)
            SetWrap(row.left, false)
            row.left:SetWidth(0)
            row.left:SetText(d.l)
            row.left:SetTextColor(d.lr or 1, d.lg or 1, d.lb or 1, 1)
            row.left:Show()
            local lw = row.left:GetStringWidth() or 0
            if d.wrap then
                anyWrap = true
                if lw > d.wrap then lw = d.wrap end
                if lw > maxWrap then maxWrap = lw end
            elseif lw > maxLeft then
                maxLeft = lw
            end
            if d.r then
                anyRight = true
                row.right:SetText(d.r)
                row.right:SetTextColor(d.rr or 1, d.rg or 1, d.rb or 1, 1)
                row.right:Show()
                maxRight = max(maxRight, row.right:GetStringWidth() or 0)
            else
                row.right:SetText("")
                row.right:Hide()
            end
            local colH = 0
            if d.ncols then
                anyRight = true
                colCount = max(colCount, d.ncols)
                for c = 1, d.ncols do
                    local fs = EnsureCol(row, c)
                    ns.SetFont(fs, FONT_SIZE)
                    SetWrap(fs, false)
                    fs:SetWidth(0)
                    fs:SetText(d.cols[c])
                    fs:Show()
                    colW[c] = max(colW[c] or 0, fs:GetStringWidth() or 0)
                    colH = max(colH, fs:GetStringHeight() or 0)
                end
            end
            HideCols(row, (d.ncols or 0) + 1)
            if not d.wrap then
                local h = row.left:GetStringHeight() or FONT_SIZE
                if d.r then h = max(h, row.right:GetStringHeight() or 0) end
                h = max(h, colH)
                if Padded(d) then h = h + 4 end
                d._h = h
            end
        end
        for i = dataCount + 1, #rows do rows[i].left:Hide(); rows[i].right:Hide(); HideCols(rows[i], 1) end
        local colsW = 0
        for c = 1, colCount do colsW = colsW + (colW[c] or 0) + (c > 1 and TOKEN_GAP or 0) end
        if colsW > maxRight then maxRight = colsW end
        local innerW = maxLeft
        if anyRight then innerW = maxLeft + COL_GAP + maxRight end
        if anyWrap then
            if maxWrap > innerW then innerW = maxWrap end
            for i = 1, dataCount do
                local d = data[i]
                if d.wrap then
                    local left = rows[i].left
                    SetWrap(left, true)
                    left:SetWidth(innerW)
                    local h = left:GetStringHeight() or FONT_SIZE
                    if Padded(d) then h = h + 4 end
                    d._h = h
                end
            end
        end
        for i = 1, dataCount do
            local d = data[i]
            d._h = d._h or FONT_SIZE
            totalH = totalH + d._h + (i > 1 and ROW_GAP or 0)
        end
        Size(tip, max(60, innerW + PAD * 2), max(24, totalH + PAD * 2))
        local y = -PAD
        for i = 1, dataCount do
            local d, row = data[i], rows[i]
            local ty = Padded(d) and y - 2 or y
            row.left:ClearAllPoints()
            row.left:SetPoint("TOPLEFT", tip, "TOPLEFT", PAD, ty)
            if d.r then row.right:ClearAllPoints(); row.right:SetPoint("TOPRIGHT", tip, "TOPRIGHT", -PAD, ty) end
            if d.ncols then
                local off = PAD
                for c = colCount, 1, -1 do
                    local fs = c <= d.ncols and row.cols[c]
                    if fs then fs:ClearAllPoints(); fs:SetPoint("TOPRIGHT", tip, "TOPRIGHT", -off, ty) end
                    off = off + (colW[c] or 0) + (c > 1 and TOKEN_GAP or 0)
                end
            end
            d._y = y
            y = y - d._h - ROW_GAP
        end
        HideActionButtons()
        interactive = false
        if not InCombatLockdown() then
            for i = 1, dataCount do
                local d = data[i]
                if d.action or d.actionMacro or d.actionItem then
                    interactive = true
                    if activeActions == 0 then
                        local host = EnsureActionHost()
                        host:ClearAllPoints()
                        host:SetAllPoints(tip)
                        local hw = tip:GetFrameLevel() + 10
                        if host:GetFrameLevel() < hw then host:SetFrameLevel(hw) end
                    end
                    local b = AcquireActionButton()
                    if d.action then
                        b:SetAttribute("type", "spell")
                        b:SetAttribute("spell", (GetSpellInfo(d.action)) or d.action)
                        b:SetAttribute("item", nil); b:SetAttribute("macrotext", nil)
                    elseif d.actionItem then
                        b:SetAttribute("type", "item")
                        b:SetAttribute("item", "item:" .. d.actionItem)
                        b:SetAttribute("spell", nil); b:SetAttribute("macrotext", nil)
                    else
                        b:SetAttribute("type", "macro")
                        b:SetAttribute("macrotext", d.actionMacro)
                        b:SetAttribute("spell", nil); b:SetAttribute("item", nil)
                    end
                    PlaceRowOverlay(b, i, innerW)
                end
            end
        end
        HideClickButtons()
        local anyWheel = false
        for i = 1, dataCount do
            local d = data[i]
            if d.onClick then
                interactive = true
                local b = AcquireClickButton()
                local cb = d.onClick
                PlaceRowOverlay(b, i, innerW)
                b:SetScript("OnClick", function(_, mouseButton) cb(mouseButton) end)
                if d.onWheel then
                    local wcb = d.onWheel
                    anyWheel = true
                    b:EnableMouseWheel(true)
                    b:SetScript("OnMouseWheel", function(_, delta) wcb(delta) end)
                end
            end
        end
        tip:EnableMouseWheel(anyWheel)
        if forceInteractive then interactive = true end
        tip:EnableMouse(interactive)
        keepAlive, missed, kaElapsed = interactive, 0, 0
        -- Opens off the bar's roomier side, centered on the hovered block.
        tip:ClearAllPoints()
        local bar = owner.GetParent and owner:GetParent()
        while bar do
            local n = bar.GetName and bar:GetName()
            if n and n:find("^EllesmereUIDataBarsBar%d+$") then break end
            bar = bar.GetParent and bar:GetParent()
        end
        local ocx, ocy = owner:GetCenter()
        if bar and ocx then
            local os, ts = owner:GetEffectiveScale(), tip:GetEffectiveScale()
            local bcx, bcy = bar:GetCenter()
            local bs = bar:GetEffectiveScale()
            local ui = UIParent:GetEffectiveScale()
            local halfW, halfH = UIParent:GetWidth() * ui / 2, UIParent:GetHeight() * ui / 2
            if bar:GetHeight() > bar:GetWidth() then
                local oy = (ocy * os - bcy * bs) / ts
                if bcx * bs < halfW then tip:SetPoint("LEFT", bar, "RIGHT", 6, oy)
                else tip:SetPoint("RIGHT", bar, "LEFT", -6, oy) end
            else
                local ox = (ocx * os - bcx * bs) / ts
                if bcy * bs < halfH then tip:SetPoint("BOTTOM", bar, "TOP", ox, 6)
                else tip:SetPoint("TOP", bar, "BOTTOM", ox, -6) end
            end
        elseif ocy and ocy < UIParent:GetHeight() / 2 then
            tip:SetPoint("BOTTOM", owner, "TOP", 0, 6)
        else
            tip:SetPoint("TOP", owner, "BOTTOM", 0, -6)
        end
        tip:Show()
    end
    function ns.Tip_Hide(ownerFrame)
        if not tip then return end
        if ownerFrame and owner ~= ownerFrame then return end
        owner = nil
        HideActionButtons()
        HideClickButtons()
        keepAlive, interactive = false, false
        tip:EnableMouse(false)
        tip:EnableMouseWheel(false)
        tip:Hide()
    end
    function ns.Tip_HideUnlessInteractive(ownerFrame)
        if not tip or (ownerFrame and owner ~= ownerFrame) or interactive then return end
        ns.Tip_Hide(ownerFrame)
    end
    function ns.Tip_IsOwned(ownerFrame) return tip ~= nil and tip:IsShown() and owner == ownerFrame end
    function ns.Tip_MarkInteractive() forceInteractive = true end
    -- Test/introspection hook: the rows of the tooltip currently shown.
    function ns.Tip_Lines()
        local out = {}
        for i = 1, dataCount do out[i] = { left = data[i].l, right = data[i].r, cols = data[i].ncols and data[i].cols } end
        return out
    end
end
