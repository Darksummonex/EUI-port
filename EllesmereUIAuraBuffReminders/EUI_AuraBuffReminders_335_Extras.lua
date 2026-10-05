-------------------------------------------------------------------------------
--  EUI_AuraBuffReminders_335_Extras.lua
--  Ready check low-mana warning, zone talent reminders and last-used
--  consumable tracking for the Wrath runtime.
-------------------------------------------------------------------------------
local _, ns = ...
local EABR = ns.EABR
if not EABR then return end
local E = EllesmereUI

local function Consumables()
    local p = EABR.db and EABR.db.profile
    return p and p.consumables
end

-------------------------------------------------------------------------------
--  Last-used flask / food / weapon enchant (bag count drops)
-------------------------------------------------------------------------------
EABR._trackedItems, EABR._prevItemCounts = nil, {}

function EABR.BuildTrackedItems()
    local t = {}
    for _, f in ipairs(EABR.FLASK_ITEMS) do for _, id in ipairs(f.items) do t[id] = "lastUsedFlask" end end
    for _, f in ipairs(EABR.FOOD_ITEMS) do t[f.itemID] = "lastUsedFood" end
    for _, w in ipairs(EABR.WEAPON_ENCHANT_ITEMS) do t[w.itemID] = "lastUsedWeaponEnchant" end
    EABR._trackedItems = t
    return t
end

function EABR.TrackItemUse()
    local c = Consumables()
    if not c then return end
    local tracked = EABR._trackedItems or EABR.BuildTrackedItems()
    local prev = EABR._prevItemCounts
    local primed = EABR._itemCountsPrimed
    for id, field in pairs(tracked) do
        local n = GetItemCount(id) or 0
        if primed and n < (prev[id] or 0) then c[field] = id end
        prev[id] = n
    end
    EABR._itemCountsPrimed = true
end

-------------------------------------------------------------------------------
--  Ready check mana warning (healers, raid, out of combat)
-------------------------------------------------------------------------------
function EABR.RCWEnabled()
    local c = Consumables()
    return not c or c.rcManaWarn ~= false
end

function EABR.RCWColor()
    local c = Consumables()
    local col = c and c.rcManaWarnColor
    if col and col.r then return col.r, col.g, col.b end
    local mc = E.GetPowerColor and E.GetPowerColor("MANA")
    if mc then return math.min(mc.r * 1.5, 1), math.min(mc.g * 1.5, 1), math.min(mc.b * 1.5, 1) end
    return 0, 0.825, 1
end

-- Alpha breathes 1 -> 0.6 -> 1 every 0.8 s (Wrath alpha animations have no
-- start alpha, so this runs on OnUpdate).
local function Breathe(self, elapsed)
    self._breatheT = (self._breatheT or 0) + elapsed
    local t = self._breatheT % 0.8
    local k = (t < 0.4) and (t / 0.4) or (1 - (t - 0.4) / 0.4)
    local s = k * k * (3 - 2 * k)
    self:SetAlpha(1 - 0.4 * s)
end

function EABR.RCWHide()
    local f = EABR._rcFrame
    if f then
        f:SetScript("OnUpdate", nil)
        f:Hide()
    end
    if EABR._rcTimer then EABR._rcTimer:Cancel(); EABR._rcTimer = nil end
end

function EABR.RCWApplySettings()
    local f = EABR._rcFrame
    if not f then return end
    local c = Consumables()
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "CENTER", (c and c.rcManaWarnX) or 0, 75 + ((c and c.rcManaWarnY) or 0))
    local fs = f._fs
    local outline = E.GetFontOutlineFlag("auraBuff")
    if E.PrimeFontShadow then E.PrimeFontShadow(fs, outline == "" and E.GetFontUseShadow("auraBuff")) end
    local size = (c and c.rcManaWarnSize) or 48
    fs:SetFont(EABR.ResolveFontPath(c and c.rcManaWarnFont), size, outline)
    if not fs:GetFont() then fs:SetFont("Fonts\\FRIZQT__.TTF", size, outline) end
    local r, g, b = EABR.RCWColor()
    fs:SetTextColor(r, g, b, 1)
end

function EABR.RCWBuild()
    if EABR._rcFrame then return EABR._rcFrame end
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(600, 60)
    f:SetFrameStrata("FULLSCREEN")
    f:SetFrameLevel(100)
    f:Hide()
    local fs = f:CreateFontString(nil, "OVERLAY")
    fs:SetPoint("CENTER")
    f._fs = fs
    EABR._rcFrame = f
    EABR.RCWApplySettings()
    fs:SetText(E.L("LOW MANA"))
    return f
end

function EABR.RCWShow(timed)
    local f = EABR.RCWBuild()
    EABR.RCWApplySettings()
    f._breatheT = 0
    f:SetAlpha(1)
    f:SetScript("OnUpdate", Breathe)
    f:Show()
    if EABR._rcTimer then EABR._rcTimer:Cancel(); EABR._rcTimer = nil end
    if timed then EABR._rcTimer = C_Timer.NewTimer(10, EABR.RCWHide) end
end

function EABR.RCWUpdateRegistration()
    local rc = EABR._rcEvents
    if not rc then return end
    if EABR.InRaid() and not InCombatLockdown() and EABR.RCWEnabled() then
        rc:RegisterEvent("READY_CHECK")
    else
        rc:UnregisterEvent("READY_CHECK")
        EABR.RCWHide()
    end
end

function EABR.RCWOnEvent(_, event)
    if event ~= "READY_CHECK" then EABR.RCWUpdateRegistration(); return end
    if not EABR.RCWEnabled() or not EABR.PlayerIsHealer() then return end
    if UnitPowerType("player") ~= 0 then return end
    local maxMana = UnitPowerMax("player", 0) or 0
    if maxMana <= 0 or (UnitPower("player", 0) or 0) / maxMana > 0.80 then return end
    EABR.RCWShow(true)
end

-------------------------------------------------------------------------------
--  Talent reminders: in a picked instance, show talents you lack; with
--  "show not needed", show talents you have outside those instances.
-------------------------------------------------------------------------------
EABR._talentPool, EABR._talentActive = {}, {}

function EABR.HasTalentOrSpell(id)
    local tab, index = EABR.TalentFromKey(id)
    if tab then
        local _, _, _, _, rank = GetTalentInfo(tab, index)
        return (rank or 0) > 0
    end
    return EABR.Known(id)
end

function EABR.TR_GetIcon(index)
    local f = EABR._talentPool[index]
    if f then return f end
    f = CreateFrame("Frame", "EABR_TalentIcon" .. index, EABR._talentAnchor)
    f:SetSize(EABR.ICON_SIZE, EABR.ICON_SIZE)
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(100)
    f:Hide()
    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    f._icon = icon
    if E.PP and E.PP.CreateBorder then E.PP.CreateBorder(f, 0, 0, 0, 1, 1, "OVERLAY", 7) end
    local text = f:CreateFontString(nil, "OVERLAY")
    text:SetPoint("TOP", f, "BOTTOM", 0, -2)
    if E.ApplyModuleFont then E.ApplyModuleFont(text, nil, 11, "auraBuff") else text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE") end
    text:SetTextColor(1, 1, 1, 1)
    f._text = text
    EABR._talentPool[index] = f
    return f
end

function EABR.TR_HideIcons()
    for _, f in ipairs(EABR._talentActive) do f._text:SetText(""); f:Hide() end
    wipe(EABR._talentActive)
    if EABR._talentAnchor then E.SetElementVisibility(EABR._talentAnchor, false) end
end

function EABR.TR_Collect(out)
    if EABR.InCombat() then return end
    local inInstance, iType = IsInInstance()
    if not inInstance or iType == "none" then return end
    local p = EABR.db and EABR.db.profile
    local reminders = p and p.talentReminders
    if not reminders or #reminders == 0 then return end
    local current = GetInstanceInfo()
    if not current then return end
    local _, playerClass = UnitClass("player")
    for _, r in ipairs(reminders) do
        if r.spellID and (not r.class or r.class == playerClass) then
            local zoneMatch = false
            for _, zn in ipairs(r.zoneNames or {}) do
                if zn == current then zoneMatch = true; break end
            end
            local has = EABR.HasTalentOrSpell(r.spellID)
            local label = r.spellName or EABR.SpellName(r.spellID, "Unknown")
            if zoneMatch and not has then
                out[#out + 1] = { texture = EABR.Tex(r.spellID) or EABR.QUESTION_ICON, label = label }
            elseif not zoneMatch and r.showNotNeeded and has then
                out[#out + 1] = { texture = EABR.Tex(r.spellID) or EABR.QUESTION_ICON, label = label .. " (N/N)" }
            end
        end
    end
end

function EABR.TR_Refresh()
    EABR._trQueued = false
    EABR._trLast = GetTime()
    if not (EABR.db and EABR._talentAnchor) then return end
    EABR.TR_HideIcons()
    if UnitIsDeadOrGhost("player") or IsResting() or (IsMounted() and IsFlying()) or UnitInVehicle("player") then
        return
    end
    local list = {}
    EABR.TR_Collect(list)
    local count = #list
    if count == 0 then return end
    local sz, spacing = EABR.ICON_SIZE, 40
    local totalW = count * sz + (count - 1) * spacing
    for i, m in ipairs(list) do
        local f = EABR.TR_GetIcon(i)
        f._icon:SetTexture(m.texture)
        f._icon:SetDesaturated(false)
        f._text:SetText(m.label or "")
        f._text:Show()
        f:SetSize(sz, sz)
        f:SetAlpha(1)
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", EABR._talentAnchor, "TOP", -totalW / 2 + (i - 1) * (sz + spacing), 0)
        f:Show()
        EABR._talentActive[#EABR._talentActive + 1] = f
    end
    E.SetElementVisibility(EABR._talentAnchor, true)
end

function EABR.TR_RequestRefresh()
    if EABR._trQueued then return end
    EABR._trQueued = true
    local elapsed = GetTime() - (EABR._trLast or 0)
    C_Timer.After(elapsed >= 0.5 and 0 or (0.5 - elapsed), EABR.TR_Refresh)
end

function EABR.TR_OnEvent(_, event)
    if event == "PLAYER_REGEN_DISABLED" then EABR.TR_HideIcons(); return end
    if event == "PLAYER_ENTERING_WORLD" then C_Timer.After(0.5, EABR.TR_RequestRefresh) end
    EABR.TR_RequestRefresh()
end

-------------------------------------------------------------------------------
--  Wiring (called from OnEnable)
-------------------------------------------------------------------------------
function EABR.EnableExtras()
    EABR.TrackItemUse()

    local rc = CreateFrame("Frame")
    EABR._rcEvents = rc
    for _, e in ipairs({ "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "RAID_ROSTER_UPDATE",
        "PARTY_MEMBERS_CHANGED", "ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD" }) do
        rc:RegisterEvent(e)
    end
    rc:SetScript("OnEvent", EABR.RCWOnEvent)
    EABR.RCWUpdateRegistration()

    local a = CreateFrame("Frame", "EABR_TalentAnchor", UIParent)
    a:SetSize(1, 1)
    a:SetFrameStrata("MEDIUM")
    a:SetFrameLevel(100)
    a:EnableMouse(false)
    a:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    a:Show()
    EABR._talentAnchor = a
    E.SetElementVisibility(a, false)
    local tr = CreateFrame("Frame")
    for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "PLAYER_REGEN_DISABLED",
        "PLAYER_REGEN_ENABLED", "PLAYER_TALENT_UPDATE", "ACTIVE_TALENT_GROUP_CHANGED", "SPELLS_CHANGED",
        "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST", "PLAYER_UPDATE_RESTING" }) do
        tr:RegisterEvent(e)
    end
    tr:SetScript("OnEvent", EABR.TR_OnEvent)
    C_Timer.After(1, EABR.TR_RequestRefresh)

    _G._EABR_RCWarnApply = function() EABR.RCWBuild(); EABR.RCWApplySettings() end
    _G._EABR_RCWarnPreview = function() EABR.RCWShow(false) end
    _G._EABR_RCWarnHidePreview = EABR.RCWHide
    _G._EABR_RCWarnUpdateReg = EABR.RCWUpdateRegistration
    _G._EABR_TR_RequestRefresh = EABR.TR_RequestRefresh
    _G._EABR_TR_HideIcons = EABR.TR_HideIcons
    _G._EABR_TR_GetAnchor = function() return EABR._talentAnchor end
end
