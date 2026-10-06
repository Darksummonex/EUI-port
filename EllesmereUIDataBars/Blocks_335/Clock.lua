-- EllesmereUIDataBars 3.3.5: Clock block factory (port of Retail Blocks\Clock.lua).
local _, ns = ...
if not ns.IsWrath then return end
local L = ns.L
local K = ns.BlockKit

-- Upvalues
local CreateFrame      = CreateFrame
local InCombatLockdown = InCombatLockdown
local format           = string.format
local floor            = math.floor
local max              = math.max
local min              = math.min
local abs              = math.abs
local date             = date
local Size, Shown      = ns.Size, ns.Shown

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

-- Static stand-ins for Retail's rest flipbook atlas and the mail crosshair atlas.
local REST_TEX    = "Interface\\CharacterFrame\\UI-StateIcon"
local REST_COORDS = { 0, 0.5, 0, 0.421875 }
local MAIL_TEX    = "Interface\\Minimap\\Tracking\\Mailbox"

-- Localized weekday / month names (the Calendar's tables only exist once Blizzard_Calendar loads).
local WEEKDAY_KEYS = { "SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY" }
local MONTH_KEYS = { "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY",
                     "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER" }
local function WeekdayName(i)
    local t = CALENDAR_WEEKDAY_NAMES
    return (t and t[i]) or _G["WEEKDAY_" .. WEEKDAY_KEYS[i]] or date("%A", 86400 * (i + 2) + 43200)
end
local function MonthName(i)
    local t = CALENDAR_FULLDATE_MONTH_NAMES
    return (t and t[i]) or _G["FULLDATE_MONTH_" .. MONTH_KEYS[i]] or _G["MONTH_" .. MONTH_KEYS[i]]
        or date("%B", time({ year = 2000, month = i, day = 15 }))
end
-- Realm calendar date (CalendarGetDate), falling back to the local clock.
local function TodayLine()
    local wd, mo, dd, yy
    if CalendarGetDate then wd, mo, dd, yy = CalendarGetDate() end
    if not (wd and wd >= 1 and wd <= 7 and mo and mo >= 1 and mo <= 12) then
        local t = date("*t")
        wd, mo, dd, yy = t.wday, t.month, t.day, t.year
    end
    local wn, mn = WeekdayName(wd), MonthName(mo)
    if FULLDATE then
        local ok, s = pcall(format, FULLDATE, wn, mn, dd, yy)
        if ok and s then return s end
    end
    return format("%s, %s %d, %d", wn, mn, dd, yy)
end

-- Weekly reset: Wrath has no API for it, so it is read off the player's own
-- weekly raid lockouts (10/25/40-player raids reset together, on a daily-reset
-- boundary). Nil when not saved to any such raid.
local function WeeklyResetFromLockouts(daily)
    if not (GetNumSavedInstances and GetSavedInstanceInfo) then return nil end
    local best
    for i = 1, GetNumSavedInstances() do
        local _, _, reset, _, locked, _, _, isRaid, maxPlayers = GetSavedInstanceInfo(i)
        if locked and isRaid and reset and reset > 0 and reset <= 7 * 86400 + 120
           and (maxPlayers == 10 or maxPlayers == 25 or maxPlayers == 40) then
            local aligned = true
            if daily and daily > 0 then
                local d = abs(reset - daily) % 86400
                aligned = d < 300 or d > 86400 - 300
            end
            if aligned and (not best or reset < best) then best = reset end
        end
    end
    return best
end

local function ToggleCalendarPanel()
    if ToggleCalendar then ToggleCalendar(); return end
    if not CalendarFrame and LoadAddOn then LoadAddOn("Blizzard_Calendar") end
    if Calendar_Toggle then Calendar_Toggle() end
end
local function ToggleClockPanel()
    if ToggleTimeManager then ToggleTimeManager(); return end
    if not TimeManagerFrame and LoadAddOn then LoadAddOn("Blizzard_TimeManager") end
    if TimeManager_Toggle then TimeManager_Toggle()
    elseif TimeManagerFrame then Shown(TimeManagerFrame, not TimeManagerFrame:IsShown()) end
end

-------------------------------------------------------------------------------
--  CLOCK
-------------------------------------------------------------------------------
ns.BlockFactories.clock = function(blockCfg, slot, content, barCtx)
    local inst = { cfg = blockCfg, slot = slot, content = content, ctx = barCtx }
    inst.key = InstKey(barCtx, blockCfg)
    inst.events = { "PLAYER_UPDATE_RESTING", "PLAYER_REGEN_ENABLED",
                    "MAIL_INBOX_UPDATE", "UPDATE_PENDING_MAIL" }

    local infoTimer, infoIndex = 0, 1
    local lastTimeStr
    local infoItems = {}
    local needsResize = false
    local isMouseOver = false

    local function D() return blockCfg.settings or {} end
    local function BC() return barCtx.cfg end

    -- Fixed defaults (26 / 16 off CONTENT_BASE); bar Height never scales text.
    local function FontSizeClock()
        local d = D()
        if d.fontSizeClock then return d.fontSizeClock end
        return max(12, floor(CONTENT_BASE * 0.7333 + 0.5))
    end
    local function FontSizeInfo()
        local d = D()
        if d.fontSizeInfo then return d.fontSizeInfo end
        return max(9, floor(CONTENT_BASE * 0.53 + 0.5))
    end

    -- Untouched toggles follow the game's Time Manager CVars (same source the minimap clock reads); explicit toggle overrides.
    local function ClockUses()
        local d = D()
        local useLocal = d.localTime
        if useLocal == nil then useLocal = GetCVar("timeMgrUseLocalTime") == "1" end
        local use24 = d.twentyFour
        if use24 == nil then use24 = GetCVar("timeMgrUseMilitaryTime") == "1" end
        return useLocal, use24
    end

    -- Matches the minimap clock: padded hour in 24-hour mode (01:04), unpadded hour + AM/PM in 12-hour mode (1:04 PM).
    local function FormatClock(h, m, use24)
        if use24 then return format("%02d:%02d", h, m) end
        local ampm = h >= 12 and "PM" or "AM"
        h = h % 12
        if h == 0 then h = 12 end
        return format("%d:%02d %s", h, m, ampm)
    end

    local function GetTimeString()
        local useLocal, use24 = ClockUses()
        local h, m
        if useLocal then
            h = tonumber(date("%H")); m = tonumber(date("%M"))
        else
            local gh, gm = GetGameTime()
            h = floor(gh); m = floor(gm)
        end
        return FormatClock(h, m, use24)
    end

    local function RebuildInfoItems()
        -- Empty by design (mail is an icon); rotation kept for future lines.
        ns.Wipe(infoItems)
        if infoIndex > #infoItems then infoIndex = 1 end
    end

    local clockTextFrame = CreateFrame("Button", nil, content)
    Size(clockTextFrame, 100, 20)
    clockTextFrame:SetPoint("CENTER")
    clockTextFrame:EnableMouse(true)
    clockTextFrame:RegisterForClicks("AnyUp")

    local clockText = clockTextFrame:CreateFontString(nil, "OVERLAY")
    AttachTextOffset(inst, clockText)
    clockText:SetPoint("CENTER")
    clockText:SetTextColor(1, 1, 1, 1)

    local eventText = clockTextFrame:CreateFontString(nil, "OVERLAY")
    eventText:SetPoint("CENTER", clockText, "TOP", 0, 6)
    eventText:Hide()

    -- Resting indicator: the PlayerFrame's static rest glyph, desaturated so it takes the clock color.
    local restFrame = CreateFrame("Frame", nil, content)
    Size(restFrame, 16, 16)
    restFrame:Hide()
    local restIcon = restFrame:CreateTexture(nil, "OVERLAY")
    restIcon:SetDrawLayer("OVERLAY", 7)
    restIcon:SetPoint("CENTER", restFrame, "CENTER", 0, 2)
    restIcon:SetTexture(REST_TEX)
    restIcon:SetTexCoord(REST_COORDS[1], REST_COORDS[2], REST_COORDS[3], REST_COORDS[4])
    restIcon:SetDesaturated(true)
    restIcon:SetVertexColor(1, 1, 1, 1)

    -- Mail indicator: LEFT of the clock while mail waits, gated by showMail.
    local mailIcon = clockTextFrame:CreateTexture(nil, "OVERLAY")
    mailIcon:SetTexture(MAIL_TEX)
    mailIcon:Hide()

    -- One color authority: text and resting icon move together (accent on hover).
    local function ApplyClockColor()
        local r, g, b
        if isMouseOver then
            r, g, b = ns.GetAccent()
        else
            r, g, b = BlockColorOf(blockCfg)
        end
        clockText:SetTextColor(r, g, b, 1)
        restIcon:SetVertexColor(r, g, b, 1)
    end

    local function MailWaiting() return HasNewMail and HasNewMail() and true or false end

    function inst:Refresh()
        if InCombatLockdown() then
            -- Combat: text-only refresh; sizing+anchoring wait for PLAYER_REGEN_ENABLED via needsResize.
            needsResize = true
            clockText:SetText(GetTimeString())
            ApplyClockColor()
            local dCombat = D()
            Shown(mailIcon, dCombat.showMail ~= false and MailWaiting())
            RebuildInfoItems()
            if #infoItems > 0 then
                eventText:SetText(infoItems[infoIndex] or "")
                local r, g, b = ns.GetAccent()
                eventText:SetTextColor(r, g, b, 1)
                eventText:Show()
            else
                eventText:Hide()
            end
            Shown(restFrame, dCombat.showResting ~= false and IsResting())
            return
        end

        local isSide = barCtx.IsVertical()
        local barCfg = BC()
        local clockSz = FontSizeClock()
        local infoSz  = FontSizeInfo()
        local timeText = GetTimeString()
        local barH = barCtx.GetThickness()

        ns.SetFont(clockText, clockSz, barCfg)
        clockText:SetText(timeText)
        ApplyClockColor()

        ns.SetFont(eventText, infoSz, barCfg)
        RebuildInfoItems()
        if #infoItems > 0 then
            eventText:SetText(infoItems[infoIndex] or "")
            local r, g, b = ns.GetAccent()
            eventText:SetTextColor(r, g, b, 1)
            eventText:Show()
        else
            eventText:Hide()
        end

        local dc = D()
        Shown(restFrame, dc.showResting ~= false and IsResting())
        Shown(mailIcon, dc.showMail ~= false and MailWaiting())

        local barAtTop = barCtx.IsBarAtTop()
        local restW = floor(CONTENT_BASE * 0.5 + 0.5)
        local restH = restW
        Size(restFrame, restW, restH)
        Size(restIcon, floor(restW * 1.25 + 0.5), floor(restH * 1.25 * 0.84 + 0.5))
        restFrame:ClearAllPoints()
        local mailW = restW + 8
        Size(mailIcon, mailW, mailW)
        mailIcon:ClearAllPoints()

        if isSide then
            local slotW = VSlotW(inst)
            local innerW = max(30, slotW - 8)

            content:SetWidth(slotW)
            clockTextFrame:SetWidth(slotW)
            clockTextFrame:ClearAllPoints()
            clockTextFrame:SetPoint("CENTER", content, "CENTER", 0, 0)

            ns.SetWrappedText(clockText, innerW, "CENTER")
            clockText:ClearAllPoints()
            clockText:SetPoint("TOP", clockTextFrame, "TOP", 0, -4)

            local totalH = 8 + ns.SnapToPixelGrid(clockText:GetStringHeight())
            if eventText:IsShown() then
                ns.SetWrappedText(eventText, innerW, "CENTER")
                eventText:ClearAllPoints()
                eventText:SetPoint("TOP", clockText, "BOTTOM", 0, -4)
                totalH = totalH + 4 + ns.SnapToPixelGrid(eventText:GetStringHeight())
            end

            totalH = max(totalH, barH + 8)
            content:SetHeight(totalH)
            clockTextFrame:SetHeight(totalH)

            if restFrame:IsShown() then
                restFrame:SetPoint("TOPRIGHT", content, "TOPRIGHT", -2, -2)
            end
            if mailIcon:IsShown() then
                mailIcon:SetPoint("TOPLEFT", content, "TOPLEFT", 2, -2)
            end
        else
            local slotW = HBudget(inst, 120)
            local restExtra = 0
            if restFrame:IsShown() then restExtra = restW + 4 end
            local mailExtra = 0
            if mailIcon:IsShown() then mailExtra = mailW + 8 end
            ns.SetFont(clockText, clockSz, barCfg)
            clockText:SetText(timeText)
            if #infoItems > 0 then
                ns.SetFont(eventText, infoSz, barCfg)
                eventText:SetText(infoItems[infoIndex] or "")
            end

            ns.ResetInlineText(clockText, "CENTER")
            ns.ResetInlineText(eventText, "CENTER")

            local tw = ns.SnapToPixelGrid(clockText:GetStringWidth())
            local th = ns.SnapToPixelGrid(clockText:GetStringHeight())
            if th < 1 then th = 1 end

            local w = min(slotW, max(tw, 1) + restExtra + mailExtra)
            Size(content, w, th)
            Size(clockTextFrame, w, th)
            clockTextFrame:ClearAllPoints()
            clockTextFrame:SetPoint("CENTER")

            clockText:ClearAllPoints()
            clockText:SetPoint("CENTER")

            eventText:ClearAllPoints()
            if barAtTop then
                eventText:SetPoint("CENTER", clockText, "BOTTOM", 0, -6)
            else
                eventText:SetPoint("CENTER", clockText, "TOP", 0, 6)
            end

            if restFrame:IsShown() then
                if barAtTop then
                    restFrame:SetPoint("TOPLEFT", clockText, "TOPRIGHT", 2, -12)
                else
                    restFrame:SetPoint("BOTTOMLEFT", clockText, "BOTTOMRIGHT", 2, 12)
                end
            end
            if mailIcon:IsShown() then
                mailIcon:SetPoint("RIGHT", clockText, "LEFT", -8, 0)
            end
        end
        MaybeRelayout(inst)
    end

    -- Heartbeat: full layout pass only when the rendered HH:MM changes.
    local function ClockTick()
        infoTimer = infoTimer + 1
        if #infoItems > 1 and infoTimer >= 5 then
            infoTimer = 0
            infoIndex = (infoIndex % #infoItems) + 1
            local r, g, b = ns.GetAccent()
            eventText:SetText(infoItems[infoIndex] or "")
            eventText:SetTextColor(r, g, b, 1)
        end
        local t = GetTimeString()
        if t ~= lastTimeStr then
            lastTimeStr = t
            inst:Refresh()
        end
    end

    inst.eventFrame = MakeEventFrame(inst, function(self, event)
        if event == "PLAYER_REGEN_ENABLED" then
            if needsResize then needsResize = false; self:Refresh() end
        else
            self:Refresh()
        end
    end)

    clockTextFrame:SetScript("OnEnter", function()
        isMouseOver = true
        ApplyClockColor()
        ns.Tip_Begin(clockTextFrame)
        ns.Tip_AddLine(TodayLine(), 1, 1, 1)
        local gh, gm = GetGameTime()
        local _, tipUse24 = ClockUses()
        ns.Tip_AddDouble(L["SERVER_TIME"], FormatClock(floor(gh), floor(gm), tipUse24), 0.6, 0.6, 0.6, 1, 1, 1)

        local numInstances = 0
        if GetNumSavedInstances then numInstances = GetNumSavedInstances() end
        if numInstances > 0 then
            ns.Tip_AddLine(" ")
            ns.Tip_AddLine(L["SAVED_INSTANCES"], 1, 0.82, 0)
            for i = 1, numInstances do
                local name, _, reset, _, locked, extended, _, _, _, diffName = GetSavedInstanceInfo(i)
                if locked or extended then
                    if diffName and diffName ~= "" then name = format("%s (%s)", name, diffName) end
                    ns.Tip_AddDouble(name, ns.FormatTimeLeft(reset), 1, 1, 1, 0.6, 0.6, 0.6)
                end
            end
        end
        ns.Tip_AddLine(" ")
        local dailyReset = 0
        if GetQuestResetTime then dailyReset = GetQuestResetTime() or 0 end
        if dailyReset > 0 then
            ns.Tip_AddDouble(L["DAILY_RESET"], ns.FormatTimeLeft(dailyReset), 0.6, 0.6, 0.6, 1, 1, 1)
        end
        local weeklyReset = WeeklyResetFromLockouts(dailyReset) or 0
        if weeklyReset > 0 then
            ns.Tip_AddDouble(L["WEEKLY_RESET"], ns.FormatTimeLeft(weeklyReset), 0.6, 0.6, 0.6, 1, 1, 1)
        end
        if MailWaiting() then
            ns.Tip_AddLine(" ")
            ns.Tip_AddLine(L["YOU_HAVE_MAIL"], 1, 0.82, 0)
        end
        ns.Tip_AddLine(" ")
        ns.Tip_AddDouble(L["LEFT_CLICK"], L["TOGGLE_CALENDAR"], 1, 1, 1, 1, 1, 1)
        ns.Tip_AddDouble(L["RIGHT_CLICK"], L["TOGGLE_CLOCK"], 1, 1, 1, 1, 1, 1)
        ns.Tip_AddDouble(L["SHIFT_MIDDLE_CLICK"], L["RELOAD_UI"], 1, 1, 1, 1, 1, 1)
        ns.Tip_Show()
    end)
    clockTextFrame:SetScript("OnLeave", function()
        isMouseOver = false
        ApplyClockColor()
        ns.Tip_Hide(clockTextFrame)
    end)
    clockTextFrame:SetScript("OnClick", function(_, button)
        if button == "MiddleButton" and IsShiftKeyDown() then
            -- Never reload mid-combat: it drops the player out of the fight.
            if InCombatLockdown() then return end
            local E = EllesmereUI
            if E and E.RequestReload then
                E.RequestReload(E.L("Reload UI"), E.L("Reload the UI now?"))
            else
                ReloadUI()
            end
        elseif button == "LeftButton" then
            ToggleCalendarPanel()
        elseif button == "RightButton" then
            ToggleClockPanel()
        end
    end)

    function inst:Enable()
        content:Show()
        needsResize = false
        infoTimer = 0
        lastTimeStr = nil
        RegisterInstEvents(self)
        -- Saved-instance data is only cached after a raid-info request.
        if RequestRaidInfo then RequestRaidInfo() end
        ns.RegisterHeartbeat("clock:" .. self.key, ClockTick)
    end

    function inst:Disable()
        ns.UnregisterHeartbeat("clock:" .. self.key)
        UnregisterInstEvents(self)
        restFrame:Hide()
        content:Hide()
    end

    function inst:GetAutoLength()
        if barCtx.IsVertical() then
            local barH = barCtx.GetThickness()
            local textH = clockText:GetStringHeight() or FontSizeClock()
            local infoH = 0
            if eventText:IsShown() then infoH = (eventText:GetStringHeight() or 0) + 4 end
            return max(8 + textH + infoH + 8, barH, 60)
        end
        local w = clockTextFrame:GetWidth() or 80
        local dc = D()
        if dc.showResting ~= false then
            w = w + floor(CONTENT_BASE * 0.5 + 0.5) + 4
        end
        if dc.showMail ~= false and MailWaiting() then
            w = w + floor(CONTENT_BASE * 0.5 + 0.5) + 8 + 8
        end
        return max(w, 60)
    end

    function inst:Destroy()
        self._dead = true
        ns.UnregisterHeartbeat("clock:" .. self.key)
        UnregisterInstEvents(self)
        content:Hide()
    end

    return inst
end
