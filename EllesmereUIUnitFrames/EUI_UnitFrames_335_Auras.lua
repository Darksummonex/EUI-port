-- Index-based Wrath auras. Retail aura containers are deliberately not loaded.
local _, ns = ...
local CreateFrame = ns.Wrath.CreateFrame
local entries = {}
ns.WrathAuraEntries=entries
local function Settings(unit)
    return ns.UF_GetSettings and ns.UF_GetSettings(unit)
end
function ns.UF_DebuffFilterMode(s)
    local mode = s.debuffFilterMode or (s.onlyPlayerDebuffs and "own" or "all")
    -- Wrath exposes no Blizzard "important" classification.
    if mode ~= "tracked" and mode ~= "own" then return "all" end
    return mode
end
function ns.UF_DebuffHasIncludes(s)
    for _, enabled in pairs(s.debuffInclude or {}) do if enabled then return true end end
    return false
end
local function NewButton(parent)
    local b = CreateFrame("Button", nil, parent)
    b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetAllPoints(b); b.icon:SetTexCoord(.07,.93,.07,.93)
    b.cooldown = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate"); b.cooldown:SetAllPoints(b)
    b.count = b:CreateFontString(nil, "OVERLAY")
    b.count:SetFont(EllesmereUI.GetFontPath("unitFrames"), 10, "OUTLINE")
    b.count:SetPoint("BOTTOMRIGHT", -1, 1)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetUnitAura(self.unit, self.index, self.filter)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
end
local function PaintLane(entry, helpful, s)
    local lane = helpful and entry.buffs or entry.debuffs
    local prefix = helpful and "buff" or "debuff"
    local simple = helpful and s.simpleBuffs or s.simpleDebuffs
    if simple == true then simple = "left" end
    local isSimple = simple == "left" or simple == "right"
    local anchor = s[prefix.."Anchor"] or (helpful and "topleft" or "bottomleft")
    if helpful and s.showBuffs == false or (anchor == "none" and not isSimple) then
        lane:Hide(); return
    end
    local size = isSimple and entry.frame:GetHeight() or s[prefix.."Size"] or 22
    local cap = math.min(40, s[helpful and "maxBuffs" or "maxDebuffs"] or (helpful and 4 or 10))
    if cap <= 0 then lane:Hide(); return end
    local rightSide = simple == "right"
    local right = (isSimple and simple == "left") or (not isSimple and anchor:find("right") ~= nil)
    local top = not isSimple and anchor:find("top") ~= nil
    local x, y = s[prefix.."OffsetX"] or 0, s[prefix.."OffsetY"] or 0
    lane:ClearAllPoints()
    if isSimple then
        lane:SetPoint(rightSide and "LEFT" or "RIGHT", entry.frame, rightSide and "RIGHT" or "LEFT", rightSide and 4 or -4, 0)
    else
        lane:SetPoint(top and (right and "BOTTOMRIGHT" or "BOTTOMLEFT") or (right and "TOPRIGHT" or "TOPLEFT"),
            entry.frame, top and (right and "TOPRIGHT" or "TOPLEFT") or (right and "BOTTOMRIGHT" or "BOTTOMLEFT"), x, y+(top and 4 or -4))
    end
    local filter = helpful and "HELPFUL" or "HARMFUL"
    local mode = ns.UF_DebuffFilterMode(s)
    local shown = 0
    local unit = entry.frame._euiUnit or entry.unit
    for index = 1, 40 do
        local name, rank, icon, count, dtype, duration, expires, caster, stealable, _, spellID = UnitAura(unit, index, filter)
        if not name then break end
        local mine = caster == "player" or caster == "pet" or caster == "vehicle"
        local tracked = not helpful and s.debuffInclude and (s.debuffInclude[spellID] or s.debuffInclude[tostring(spellID)])
        local excluded = not helpful and s.debuffExclude and (s.debuffExclude[spellID] or s.debuffExclude[tostring(spellID)])
        local include = helpful or mode == "all" or (mode == "own" and mine) or tracked
        if helpful and s.onlyPlayerBuffs and not mine then include = false end
        if helpful and s.buffStealable and not stealable then include = false end
        if helpful and s.buffHasDuration and (not duration or duration <= 0) then include = false end
        if EllesmereUI.WrathAuraFilters then
            include=EllesmereUI.WrathAuraFilters.Allow(s,prefix,spellID,mine,duration,stealable)
            excluded=false -- the shared predicate already applies exclusions
        end
        if include and not excluded and shown < cap then
            shown = shown+1
            local b = lane.buttons[shown]
            if not b then b = NewButton(lane); lane.buttons[shown] = b end
            b.unit, b.index, b.filter = unit, index, filter
            b:SetSize(size, size); b:ClearAllPoints()
            local perRow = isSimple and cap or math.max(1, math.floor(entry.frame:GetWidth()/(size+3)))
            local col, row = (shown-1)%perRow, math.floor((shown-1)/perRow)
            b:SetPoint(right and "TOPRIGHT" or "TOPLEFT", lane, right and "TOPRIGHT" or "TOPLEFT",
                (right and -1 or 1)*col*(size+3), -row*(size+3))
            b.icon:SetTexture(icon); b.count:SetText(count and count > 1 and count or "")
            if duration and duration > 0 and expires then
                b.cooldown:SetCooldown(expires-duration, duration); b.cooldown:Show()
            else b.cooldown:Hide() end
            b:Show()
        end
    end
    for i = shown+1, #lane.buttons do lane.buttons[i]:Hide() end
    local perRow = isSimple and cap or math.max(1, math.floor(entry.frame:GetWidth()/(size+3)))
    lane:SetSize(math.max(size, math.min(shown,perRow)*(size+3)-3), math.max(size,math.ceil(shown/perRow)*(size+3)-3))
    lane:SetShown(shown > 0 and UnitExists(unit))
end
function ns.UF_ReloadAuraContainers(frame, unit)
    local entry = entries[frame]
    local s = entry and Settings(unit or entry.unit)
    if not s then return end
    for _,prefix in ipairs({"buff","debuff"}) do
        local lane=prefix=="buff" and entry.buffs or entry.debuffs
        if s[prefix.."IndicatorMode"] then
            lane:Hide()
            local kind=GetNumRaidMembers()>0 and "raid" or GetNumPartyMembers()>0 and "party" or "solo"
            EllesmereUI.WrathAuraIndicators.Render(entry.indicators[prefix],frame.Health or frame,s,prefix,frame._euiUnit or entry.unit,kind,frame:GetWidth(),frame:GetHeight())
        else
            for _,a in ipairs(entry.indicators[prefix]) do a:Hide(); a.unit=nil end
            PaintLane(entry,prefix=="buff",s)
        end
    end
end
function ns.UF_HideAuraContainers(frame)
    local entry = entries[frame]
    if entry then
        entry.buffs:Hide(); entry.debuffs:Hide()
        for _,pool in pairs(entry.indicators) do for _,a in ipairs(pool) do a:Hide() end end
    end
end
function ns.UF_ReloadAllAuraContainers()
    for frame, entry in pairs(entries) do ns.UF_ReloadAuraContainers(frame, entry.unit) end
end
function ns.UF_CreateAuraContainers(frame, unit)
    if entries[frame] then return ns.UF_ReloadAuraContainers(frame, unit) end
    local buffs, debuffs = CreateFrame("Frame", nil, frame), CreateFrame("Frame", nil, frame)
    buffs.buttons, debuffs.buttons = {}, {}
    local indicators={buff={},debuff={}}
    for _,pool in pairs(indicators) do for i=1,8 do pool[i]=EllesmereUI.WrathAuraIndicators.NewIcon(frame) end end
    entries[frame] = { frame=frame, unit=unit, buffs=buffs, debuffs=debuffs,indicators=indicators }
    frame:HookScript("OnShow", function(f) ns.UF_ReloadAuraContainers(f, unit) end)
    ns.UF_ReloadAuraContainers(frame, unit)
end
local watcher = CreateFrame("Frame")
watcher:RegisterEvent("UNIT_AURA")
watcher:RegisterEvent("PLAYER_TARGET_CHANGED")
watcher:RegisterEvent("PLAYER_FOCUS_CHANGED")
watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:RegisterEvent("PARTY_MEMBERS_CHANGED")
watcher:RegisterEvent("RAID_ROSTER_UPDATE")
watcher:SetScript("OnEvent", function(_, event, token)
    for frame, entry in pairs(entries) do
        if frame:IsShown() and (event ~= "UNIT_AURA" or token == (frame._euiUnit or entry.unit)) then
            ns.UF_ReloadAuraContainers(frame, entry.unit)
        end
    end
end)
