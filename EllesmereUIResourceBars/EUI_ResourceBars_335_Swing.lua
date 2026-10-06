-- Swing timer: main hand, off hand and ranged rows from the combat log.
local _, ns = ...
local E = EllesmereUI
if not E or not ns.NewBar then return end
local WHITE = ns.WHITE
local max, min, abs, format = math.max, math.min, math.abs, string.format
local S = {}
ns.SwingPart = S
local timers = { mh = {}, oh = {}, r = {} }
S.timers = timers
local LABELS = { mh = "MH", oh = "OH", r = "R" }

-- Next-swing abilities replace the white hit and restart the main hand.
local NEXT_SWING = { [78] = "queue", [845] = "cleave", [6807] = "queue", [2973] = "queue" }
local nextSwingNames = {}
for id, kind in pairs(NEXT_SWING) do local name = GetSpellInfo and GetSpellInfo(id); if name then nextSwingNames[name] = kind end end
S.nextSwingNames = nextSwingNames
local AUTO_SHOT, SHOOT = GetSpellInfo and GetSpellInfo(75), GetSpellInfo and GetSpellInfo(5019)
S.AUTO_SHOT, S.SHOOT = AUTO_SHOT, SHOOT

local function Start(key, speed, at)
    local t = timers[key]
    speed = tonumber(speed) or 0
    if speed <= 0 then return end
    t.start, t.duration = at or GetTime(), speed
end
S.Start = Start
local function Running(t, now) return t.start and now < t.start + t.duration end
-- A white hit is credited to the hand whose expected swing is nearest.
function S.MeleeHit(now)
    local _, ohSpeed = UnitAttackSpeed("player")
    local mhSpeed = UnitAttackSpeed("player")
    if not ohSpeed or ohSpeed <= 0 or not (OffhandHasWeapon and OffhandHasWeapon()) then return Start("mh", mhSpeed, now) end
    local mh, oh = timers.mh, timers.oh
    local mhDue = mh.start and abs(mh.start + mh.duration - now) or math.huge
    local ohDue = oh.start and abs(oh.start + oh.duration - now) or math.huge
    if not oh.start and mh.start and mhDue > 0.2 then return Start("oh", ohSpeed, now) end
    if ohDue < mhDue then Start("oh", ohSpeed, now) else Start("mh", mhSpeed, now) end
end
-- Parry haste: a parried enemy swing cuts 40% off the remaining main hand,
-- never below 20% of the swing.
function S.ParryHaste(now)
    local t = timers.mh
    if not Running(t, now) then return end
    local remaining = t.start + t.duration - now
    local floorTime = t.duration * 0.2
    if remaining <= floorTime then return end
    local cut = min(t.duration * 0.4, remaining - floorTime)
    t.start = t.start - cut
end
function S.Rescale()
    local now = GetTime()
    local mhSpeed, ohSpeed = UnitAttackSpeed("player")
    for key, speed in pairs({ mh = mhSpeed, oh = ohSpeed }) do
        local t = timers[key]
        if Running(t, now) and speed and speed > 0 then
            local frac = (now - t.start) / t.duration
            t.duration = speed; t.start = now - frac * speed
        end
    end
end

function S.Rows(p)
    local c = p.swingTimer
    local rows = {}
    local now = GetTime()
    local hasOH = OffhandHasWeapon and OffhandHasWeapon()
    local hasR = ns.class == "HUNTER" or (HasWandEquipped and HasWandEquipped()) or Running(timers.r, now)
    if c.showMH ~= false then rows[#rows + 1] = "mh" end
    if c.showOH ~= false and not c.combineHands and (hasOH or ns.preview) then rows[#rows + 1] = "oh" end
    if c.showR ~= false and (hasR or ns.preview) then rows[#rows + 1] = "r" end
    if c.hideWhenIdle and not ns.preview then
        local kept = {}
        for _, key in ipairs(rows) do
            if Running(timers[key], now) or (key == "mh" and c.combineHands and Running(timers.oh, now)) then kept[#kept + 1] = key end
        end
        rows = kept
    end
    return rows
end
function S.Layout(p)
    local c = p.swingTimer
    local f = ns.frames.swingTimer
    if not f then f = CreateFrame("Frame", "ERB_SwingTimer", UIParent); f._erbKey = "swingTimer"; f.bars = {}; ns.frames.swingTimer = f end
    f:SetFrameStrata(c.frameStrata or "MEDIUM")
    local rows = S.Rows(p)
    f._rows = rows
    local h, gap = c.height or 12, c.rowSpacing or 2
    ns.Size(f, c.width or 220, max(h, #rows * h + max(0, #rows - 1) * gap))
    for _, key in ipairs({ "mh", "oh", "r" }) do
        local bar = f.bars[key]
        if not bar then
            bar = ns.NewBar(f); f.bars[key] = bar
            if ns.AddSpark then ns.AddSpark(bar) end
            bar.label = bar.over:CreateFontString(nil, "OVERLAY"); bar.label:SetPoint("LEFT", bar, "LEFT", 4, 0)
        end
        bar:Hide()
    end
    for i, key in ipairs(rows) do
        local bar = f.bars[key]
        bar:ClearAllPoints(); bar:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -(i - 1) * (h + gap))
        ns.Size(bar, c.width or 220, h)
        bar:SetStatusBarTexture(ns.Texture(c.texture))
        bar.bg:SetTexture(WHITE); bar.bg:SetVertexColor(c.bgR or 0, c.bgG or 0, c.bgB or 0, c.bgA or 0.7)
        bar._sparkOn = c.showSpark and true or false
        bar:SetFillOrientation("HORIZONTAL", false)
        ns.Font(bar.text, c.textSize or 11); ns.Font(bar.label, c.textSize or 11)
        bar.text:ClearAllPoints(); bar.text:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
        bar.label:SetText(c.showLabel and LABELS[key] or "")
        ns.ApplyBorder(bar, c, false)
        bar:Show()
    end
    ns.Position("swingTimer")
end
local function RowColor(c, key)
    if c.classColored then return ns.ClassRGB() end
    if key == "oh" then return c.ohR or 0.9, c.ohG or 0.45, c.ohB or 0.27 end
    if key == "r" then return c.rR or 0.27, c.rG or 0.73, c.rB or 0.9 end
    return c.mhR or 0.9, c.mhG or 0.7, c.mhB or 0.27
end
function S.QueuedKind()
    if not IsCurrentSpell then return nil end
    for name, kind in pairs(nextSwingNames) do if IsCurrentSpell(name) then return kind end end
end
function S.InRange(key)
    if not UnitExists("target") or not UnitCanAttack("player", "target") then return true end
    if key == "r" then
        local name = ns.class == "HUNTER" and AUTO_SHOT or SHOOT
        return not name or not IsSpellInRange or IsSpellInRange(name, "target") ~= 0
    end
    return not CheckInteractDistance or CheckInteractDistance("target", 3) and true or false
end
function S.Update()
    local p = ns.GetSettings(); local f = ns.frames.swingTimer
    if not p or not f or not f._rows then return end
    local c = p.swingTimer
    local now = GetTime()
    local queued = c.queueHighlight and S.QueuedKind()
    for _, key in ipairs(f._rows) do
        local bar = f.bars[key]
        local t = timers[key]
        if key == "mh" and c.combineHands and Running(timers.oh, now) and (not Running(t, now) or timers.oh.start + timers.oh.duration < t.start + t.duration) then t = timers.oh end
        local r, g, b = RowColor(c, key)
        local a = 1
        if key == "mh" and queued then
            if queued == "cleave" then r, g, b, a = c.queueCleaveR or r, c.queueCleaveG or g, c.queueCleaveB or b, c.queueCleaveA or 1
            else r, g, b, a = c.queueR or r, c.queueG or g, c.queueB or b, c.queueA or 1 end
        end
        bar:Paint(r, g, b, a, c)
        bar:SetMinMaxValues(0, 1)
        if Running(t, now) then
            local frac = max(0, min(1, (now - t.start) / t.duration))
            bar:SetValue(c.depleteFill and (1 - frac) or frac, true)
            bar.text:SetText(c.showTime and format("%.1f", t.start + t.duration - now) or "")
        else
            bar:SetValue((c.idleShowFill or ns.preview) and 1 or 0, true)
            bar.text:SetText("")
        end
        bar:SetAlpha((c.rangeCheck and not S.InRange(key)) and (c.outOfRangeAlpha or 0.4) or 1)
    end
end
local function Visible(p)
    local f = ns.frames.swingTimer; if not f then return end
    local c = p.swingTimer
    if not p.enabled or not c.enabled or (#(f._rows or {}) == 0 and not ns.preview) then ns.SetVisible(f, nil, c); return end
    ns.SetVisible(f, ns.ShouldShow(c), c)
end
ns.RegisterPart("swingTimer", S.Layout, S.Update)
ns.RegisterVisibility(Visible)

function S.CombatLog(_, _, event, srcGUID, _, _, dstGUID, _, _, ...)
    local me = UnitGUID("player")
    local now = GetTime()
    if srcGUID == me then
        if event == "SWING_DAMAGE" or event == "SWING_MISSED" then S.MeleeHit(now)
        elseif event == "SPELL_DAMAGE" or event == "SPELL_MISSED" then
            local spellID, spellName = ...
            if NEXT_SWING[spellID] or nextSwingNames[spellName] then Start("mh", (UnitAttackSpeed("player")), now) end
        else return end
    elseif dstGUID == me and (event == "SWING_MISSED" or event == "SPELL_MISSED") then
        local missType = event == "SWING_MISSED" and ... or select(4, ...)
        if missType == "PARRY" then S.ParryHaste(now) else return end
    else return end
    S.Refresh()
end
function S.Refresh()
    local p = ns.GetSettings()
    if not p or not p.swingTimer.enabled then return end
    local f = ns.frames.swingTimer
    local rows = S.Rows(p)
    if not f or table.concat(rows, ",") ~= table.concat(f._rows or {}, ",") then S.Layout(p) end
    S.Update(); ns.UpdateVisibility()
end

ns.AfterEnable(function()
    ns.On("COMBAT_LOG_EVENT_UNFILTERED", S.CombatLog)
    ns.On("UNIT_ATTACKSPEED", function(_, unit) if unit == "player" then S.Rescale() end end)
    local castStart
    ns.On("UNIT_SPELLCAST_START", function(_, unit) if unit == "player" then castStart = GetTime() end end)
    ns.On("UNIT_SPELLCAST_SUCCEEDED", function(_, unit, spell)
        if unit ~= "player" then return end
        local now = GetTime()
        if spell and (spell == AUTO_SHOT or spell == SHOOT) then
            local speed = UnitRangedDamage("player")
            Start("r", speed, now)
        elseif castStart then
            -- Finishing a cast restarts the melee swing.
            if Running(timers.mh, now) then Start("mh", (UnitAttackSpeed("player")), now) end
            local _, ohSpeed = UnitAttackSpeed("player")
            if Running(timers.oh, now) and ohSpeed then Start("oh", ohSpeed, now) end
        end
        castStart = nil
        S.Refresh()
    end)
    for _, ev in ipairs({ "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_FAILED" }) do
        ns.On(ev, function(_, unit) if unit == "player" then castStart = nil end end)
    end
    ns.On("PLAYER_EQUIPMENT_CHANGED", function() S.Refresh() end)
    ns.On("PLAYER_REGEN_ENABLED", function() S.Refresh() end)
    ns.OnTick(function()
        local p = ns.GetSettings()
        if not p.swingTimer.enabled then return end
        local f = ns.frames.swingTimer
        if f and f:IsShown() then
            if p.swingTimer.hideWhenIdle then
                local rows = S.Rows(p)
                if table.concat(rows, ",") ~= table.concat(f._rows or {}, ",") then S.Layout(p); ns.UpdateVisibility() end
            end
            S.Update()
        end
    end)
end)
