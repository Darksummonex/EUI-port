-------------------------------------------------------------------------------
-- EllesmereUI_Absorbs_335.lua
-- Shield (damage absorb) amounts for the Raid Frames and Unit Frames health
-- bars, plus the overlay both modules draw them with.
--
-- 3.3.5 has no UnitGetTotalAbsorbs and UnitAura reports no absorb value, so
-- the amount is estimated from the combat log:
--   * SPELL_AURA_APPLIED/REFRESH of a known shield sets its capacity from a
--     per-rank base. Shields the player casts add the spell-power share
--     (bonus healing for priest/paladin, the spell school's bonus damage for
--     mage/warlock); talents and glyphs are not counted.
--   * Divine Aegis takes 30% of the caster's last critical heal on that
--     target, Protection of Ancient Kings (Val'anyr) 15% of the last heal,
--     both stacking up to their cap.
--   * The absorbed part of every damage event and *_MISSED ABSORB lowers the
--     shields of that target, oldest first, honouring school-only wards.
--   * SPELL_AURA_REMOVED/BROKEN, UNIT_DIED and a UNIT_AURA rescan clear them;
--     the rescan also seeds a known shield the log never reported.
--   * When a shield breaks right after absorbing damage, what it absorbed is
--     its real capacity: later casts of that spell by that caster start from
--     the larger of the base and that value.
-- A client with a native (secure) UnitGetTotalAbsorbs is used directly.
--
-- API: EllesmereUI.GetUnitAbsorb(unit), EllesmereUI.GetGUIDAbsorb(guid),
-- EllesmereUI.RegisterAbsorbCallback(owner, fn) (fn(guid) when the amount of
-- that GUID changes), EllesmereUI.UnregisterAbsorbCallback(owner).
-- Drawing: EllesmereUI.Absorbs.CreateOverlay / Paint / Hide, style tables.
-------------------------------------------------------------------------------

local EllesmereUI = _G.EllesmereUI
if not EllesmereUI then return end

local A = {}
EllesmereUI.Absorbs = A

local floor, min, max = math.floor, math.min, math.max

-- Physical 1, Holy 2, Fire 4, Nature 8, Frost 16, Shadow 32, Arcane 64.
local MAGIC = 126
local AEGIS_FALLBACK, VALANYR_FALLBACK, SAVAGE_FALLBACK, AMS_FALLBACK = 1000, 1000, 1500, 5000

-- [spellID] = { base, coefficient, bonus ("heal" or school index), duration, school mask, kind }
local SPELLS = {}
A.SPELLS = SPELLS
local function Ranks(ids, amounts, coef, bonus, duration, mask, kind)
    for i, id in ipairs(ids) do
        SPELLS[id] = { base = amounts and amounts[i] or 0, coef = coef, bonus = bonus,
            duration = duration, mask = mask, kind = kind }
    end
end
Ranks({ 17, 592, 600, 3747, 6065, 6066, 10898, 10899, 10900, 10901, 25217, 25218, 48065, 48066 },
    { 44, 88, 158, 234, 301, 381, 484, 605, 763, 942, 1125, 1265, 1920, 2230 }, .8068, "heal", 30) -- Power Word: Shield
Ranks({ 47753, 54704 }, nil, nil, nil, 12, nil, "aegis") -- Divine Aegis
Ranks({ 58597 }, { 500 }, .75, "heal", 6) -- Sacred Shield proc (not the 53601 buff)
Ranks({ 11426, 13031, 13032, 13033, 27134, 33405, 43038, 43039 },
    { 438, 549, 678, 818, 925, 1075, 2800, 3300 }, .8053, 5, 60) -- Ice Barrier
Ranks({ 1463, 8494, 8495, 10191, 10192, 10193, 27131, 43019, 43020 },
    { 120, 210, 300, 390, 480, 570, 715, 1080, 1330 }, .8053, 7, 60) -- Mana Shield
Ranks({ 543, 8457, 8458, 10223, 10225, 27128, 43010 },
    { 165, 290, 470, 675, 875, 1125, 1950 }, .8053, 3, 30, 4) -- Fire Ward
Ranks({ 6143, 8461, 8462, 10177, 28609, 32796, 43012 },
    { 165, 290, 470, 675, 875, 1125, 1950 }, .8053, 5, 30, 16) -- Frost Ward
Ranks({ 6229, 11739, 11740, 28610, 47890, 47891 },
    { 290, 470, 675, 875, 2750, 3300 }, .8068, 6, 30, 32) -- Shadow Ward
Ranks({ 7812, 19438, 19440, 19441, 19442, 19443, 27273, 47985, 47986 },
    { 319, 529, 794, 1124, 1503, 1931, 2725, 6750, 8350 }, nil, nil, 30) -- Sacrifice
Ranks({ 48707 }, nil, nil, nil, 5, MAGIC, "ams") -- Anti-Magic Shell
Ranks({ 50461 }, { 10000 }, nil, nil, 10, MAGIC) -- Anti-Magic Zone
Ranks({ 62606 }, nil, nil, nil, 10, 1, "savage") -- Savage Defense
Ranks({ 64413 }, nil, nil, nil, 15, nil, "valanyr") -- Protection of Ancient Kings

local active = {}      -- [dstGUID] = { entry, ... } oldest first
local learned = {}     -- [spellID] = { [srcGUID] = capacity seen when it broke }
local lastHeal, lastHealSrc, lastCrit, lastCritSrc = {}, {}, {}, {}
local callbacks = {}
local playerGUID
local adds = 0

local function Native()
    local fn = _G.UnitGetTotalAbsorbs
    if not fn then return nil end
    -- An addon-defined stand-in is not the client API.
    if issecurevariable and not issecurevariable("UnitGetTotalAbsorbs") then return nil end
    return fn
end

local function HasSchool(mask, school)
    if not mask or not school or school == 0 then return true end
    while mask > 0 and school > 0 do
        if mask % 2 == 1 and school % 2 == 1 then return true end
        mask, school = floor(mask / 2), floor(school / 2)
    end
    return false
end

local function Fire(guid)
    for _, fn in pairs(callbacks) do
        local ok, err = pcall(fn, guid)
        if not ok and geterrorhandler then geterrorhandler()(err) end
    end
end

local GROUP_UNITS = { "player", "pet", "target", "focus" }
for i = 1, 4 do GROUP_UNITS[#GROUP_UNITS + 1] = "party" .. i end
for i = 1, 40 do GROUP_UNITS[#GROUP_UNITS + 1] = "raid" .. i end
local function UnitForGUID(guid)
    for _, unit in ipairs(GROUP_UNITS) do
        if UnitGUID(unit) == guid then return unit end
    end
end

local function SpellPower(info)
    if info.bonus == "heal" then return GetSpellBonusHealing and GetSpellBonusHealing() or 0 end
    if info.bonus then return GetSpellBonusDamage and GetSpellBonusDamage(info.bonus) or 0 end
    return 0
end

local function Cap(kind)
    if kind == "valanyr" then return 20000 end
    return 125 * ((UnitLevel and UnitLevel("player")) or 80)
end

-- Capacity of a fresh cast; stacking shields add to what is left.
local function Estimate(id, info, src, dst, unit, current)
    local kind = info.kind
    if kind == "aegis" or kind == "valanyr" then
        local pct = kind == "aegis" and .3 or .15
        local heal = kind == "aegis" and (lastCritSrc[dst] == src and lastCrit[dst])
            or (kind == "valanyr" and lastHealSrc[dst] == src and lastHeal[dst])
        local add = heal and heal * pct or (kind == "aegis" and AEGIS_FALLBACK or VALANYR_FALLBACK)
        return min(Cap(kind), (current or 0) + add)
    end
    local amount = info.base
    if kind == "ams" then
        unit = unit or UnitForGUID(dst)
        local hp = unit and UnitHealthMax(unit)
        amount = hp and hp > 0 and hp * .5 or AMS_FALLBACK
    elseif kind == "savage" then
        if src and src == playerGUID and UnitAttackPower then
            local base, pos, neg = UnitAttackPower("player")
            amount = ((base or 0) + (pos or 0) + (neg or 0)) * .25
        else
            amount = SAVAGE_FALLBACK
        end
    elseif src and src == playerGUID and info.coef then
        amount = amount + SpellPower(info) * info.coef
    end
    local seen = src and learned[id] and learned[id][src]
    if seen and seen > amount then amount = seen end
    return floor(amount + .5)
end

local function Find(list, id, src)
    for i = 1, #list do
        local e = list[i]
        if e.id == id and (src == nil or e.src == nil or e.src == src) then return e, i end
    end
end

local function Prune(guid, now)
    local list = active[guid]
    if not list then return end
    for i = #list, 1, -1 do
        if list[i].expires < now then table.remove(list, i) end
    end
    if #list == 0 then active[guid] = nil end
end

local function PruneAll(now)
    for guid in pairs(active) do Prune(guid, now) end
end

local function Apply(id, src, dst, refresh, expires, unit)
    local info = SPELLS[id]
    if not info or not dst then return end
    local now = GetTime()
    adds = adds + 1
    if adds % 50 == 0 then PruneAll(now) end
    local list = active[dst]
    if not list then list = {}; active[dst] = list end
    local e = Find(list, id, src)
    local stacks = info.kind == "aegis" or info.kind == "valanyr"
    if e then
        e.amount = Estimate(id, info, src or e.src, dst, unit, (stacks and refresh) and e.amount or nil)
        if not stacks or not refresh then e.used = 0 end
        e.src = src or e.src
    else
        e = { id = id, src = src, used = 0, mask = info.mask }
        e.amount = Estimate(id, info, src, dst, unit)
        list[#list + 1] = e
    end
    e.expires = (expires and expires > 0) and expires or (now + info.duration)
    e.lastHit = nil
    Fire(dst)
end

local function Remove(id, src, dst)
    local list = active[dst]
    if not list then return end
    local now, changed = GetTime(), false
    for i = #list, 1, -1 do
        local e = list[i]
        if e.id == id and (src == nil or e.src == nil or e.src == src) then
            -- Broke right after soaking damage: what it absorbed is its capacity.
            if e.src and e.used > 0 and e.lastHit and now - e.lastHit <= .5 then
                learned[id] = learned[id] or {}
                learned[id][e.src] = e.used
            end
            table.remove(list, i); changed = true
        end
    end
    if #list == 0 then active[dst] = nil end
    if changed then Fire(dst) end
end

local function Absorb(dst, amount, school)
    local list = active[dst]
    amount = tonumber(amount) or 0
    if not list or amount <= 0 then return end
    local now, first = GetTime(), nil
    for i = 1, #list do
        local e = list[i]
        if HasSchool(e.mask, school) then
            first = first or e
            local take = min(e.amount, amount)
            e.amount, e.used, e.lastHit = e.amount - take, e.used + take, now
            amount = amount - take
            if amount <= 0 then break end
        end
    end
    -- More was absorbed than estimated: keep it for the learned capacity.
    if first and amount > 0 then first.used = first.used + amount end
    if first then Fire(dst) end
end

local SPELL_DAMAGE = { SPELL_DAMAGE = true, SPELL_PERIODIC_DAMAGE = true, RANGE_DAMAGE = true,
    DAMAGE_SHIELD = true, DAMAGE_SPLIT = true, SPELL_BUILDING_DAMAGE = true }
local SPELL_MISSED = { SPELL_MISSED = true, SPELL_PERIODIC_MISSED = true, RANGE_MISSED = true,
    DAMAGE_SHIELD_MISSED = true }
local AURA_ON = { SPELL_AURA_APPLIED = false, SPELL_AURA_REFRESH = true, SPELL_AURA_APPLIED_DOSE = true }
local AURA_OFF = { SPELL_AURA_REMOVED = true, SPELL_AURA_BROKEN = true, SPELL_AURA_BROKEN_SPELL = true }

-- 3.3.5 layout: timestamp, event, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...
function A.CombatLog(_, event, src, _, _, dst, _, _, ...)
    if not dst then return end
    if SPELL_DAMAGE[event] then
        if active[dst] then
            local _, _, _, _, _, school, _, _, absorbed = ...
            Absorb(dst, absorbed, school)
        end
    elseif event == "SWING_DAMAGE" then
        if active[dst] then
            local _, _, school, _, _, absorbed = ...
            Absorb(dst, absorbed, school or 1)
        end
    elseif SPELL_MISSED[event] then
        if active[dst] then
            local _, _, school, missType, amount = ...
            if missType == "ABSORB" then Absorb(dst, amount, school) end
        end
    elseif event == "SWING_MISSED" then
        if active[dst] then
            local missType, amount = ...
            if missType == "ABSORB" then Absorb(dst, amount, 1) end
        end
    elseif event == "ENVIRONMENTAL_DAMAGE" then
        if active[dst] then
            local _, _, _, school, _, _, absorbed = ...
            Absorb(dst, absorbed, school)
        end
    elseif event == "SPELL_HEAL" or event == "SPELL_PERIODIC_HEAL" then
        local _, _, _, amount, _, _, critical = ...
        amount = tonumber(amount)
        if amount and amount > 0 then
            lastHeal[dst], lastHealSrc[dst] = amount, src
            if critical then lastCrit[dst], lastCritSrc[dst] = amount, src end
        end
    elseif AURA_ON[event] ~= nil then
        local id, _, _, auraType = ...
        if SPELLS[id] and auraType ~= "DEBUFF" then Apply(id, src, dst, AURA_ON[event]) end
    elseif AURA_OFF[event] then
        local id = ...
        if SPELLS[id] then Remove(id, event == "SPELL_AURA_REMOVED" and src or nil, dst) end
    elseif event == "UNIT_DIED" or event == "UNIT_DESTROYED" then
        if active[dst] then active[dst] = nil; Fire(dst) end
    end
end

-- Reconcile one unit with its buffs: drop shields that are gone, seed known
-- shields the combat log never reported (cast out of range, before login).
local seen = {}
function A.ScanUnit(unit)
    local guid = unit and UnitGUID(unit)
    if not guid or Native() then return end
    for k in pairs(seen) do seen[k] = nil end
    local changed = false
    for i = 1, 40 do
        local name, _, _, _, _, _, expires, caster, _, _, id = UnitAura(unit, i, "HELPFUL")
        if not name then break end
        if id and SPELLS[id] then
            seen[id] = true
            local list = active[guid]
            local e = list and Find(list, id, nil)
            if e then
                if expires and expires > 0 then e.expires = expires end
            else
                Apply(id, caster and UnitGUID(caster) or nil, guid, false, expires, unit)
            end
        end
    end
    local list = active[guid]
    if list then
        for i = #list, 1, -1 do
            if not seen[list[i].id] then table.remove(list, i); changed = true end
        end
        if #list == 0 then active[guid] = nil end
    end
    if changed then Fire(guid) end
end

function A.Reset()
    for _, t in ipairs({ active, learned, lastHeal, lastHealSrc, lastCrit, lastCritSrc }) do
        for k in pairs(t) do t[k] = nil end
    end
end

function EllesmereUI.GetGUIDAbsorb(guid)
    local list = guid and active[guid]
    if not list then return 0 end
    local now, total = GetTime(), 0
    for i = 1, #list do
        local e = list[i]
        if e.expires >= now then total = total + e.amount end
    end
    return total
end

function EllesmereUI.GetUnitAbsorb(unit)
    if not unit then return 0 end
    local native = Native()
    if native then return tonumber(native(unit)) or 0 end
    return EllesmereUI.GetGUIDAbsorb(UnitGUID(unit))
end

-------------------------------------------------------------------------------
-- Events: registered once something listens for absorbs.
-------------------------------------------------------------------------------
local ev
local function OnEvent(_, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        if not Native() then A.CombatLog(...) end
    elseif event == "UNIT_AURA" then
        A.ScanUnit((...))
    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
        local guid = UnitGUID((...))
        if guid then Fire(guid) end
    elseif event == "PLAYER_TARGET_CHANGED" then
        A.ScanUnit("target")
    elseif event == "PLAYER_FOCUS_CHANGED" then
        A.ScanUnit("focus")
    elseif event == "PLAYER_REGEN_ENABLED" then
        for _, t in ipairs({ lastHeal, lastHealSrc, lastCrit, lastCritSrc }) do
            for k in pairs(t) do t[k] = nil end
        end
        PruneAll(GetTime())
    else
        playerGUID = UnitGUID("player")
        if event == "PLAYER_ENTERING_WORLD" then PruneAll(GetTime()) end
        A.ScanUnit("player"); A.ScanUnit("pet")
        for i = 1, (GetNumPartyMembers and GetNumPartyMembers() or 0) do A.ScanUnit("party" .. i) end
        for i = 1, (GetNumRaidMembers and GetNumRaidMembers() or 0) do A.ScanUnit("raid" .. i) end
    end
end
A.OnEvent = OnEvent

local function EnsureEvents()
    if ev then return end
    ev = CreateFrame("Frame")
    for _, event in ipairs({ "COMBAT_LOG_EVENT_UNFILTERED", "UNIT_AURA", "PLAYER_TARGET_CHANGED",
        "PLAYER_FOCUS_CHANGED", "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD",
        "PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE" }) do
        ev:RegisterEvent(event)
    end
    -- Only clients that have the native API know this event.
    pcall(ev.RegisterEvent, ev, "UNIT_ABSORB_AMOUNT_CHANGED")
    ev:SetScript("OnEvent", OnEvent)
    playerGUID = UnitGUID("player")
    -- Modules enabled after login missed the entering-world scan.
    if IsLoggedIn and IsLoggedIn() then OnEvent(ev, "PLAYER_LOGIN") end
end

function EllesmereUI.RegisterAbsorbCallback(owner, fn)
    if owner == nil or type(fn) ~= "function" then return end
    callbacks[owner] = fn
    EnsureEvents()
end

function EllesmereUI.UnregisterAbsorbCallback(owner)
    if owner ~= nil then callbacks[owner] = nil end
end

-------------------------------------------------------------------------------
-- Overlay: two textures on a health bar. "fw" covers missing health (or the
-- whole shield in the edge placements), "os" is the overshield drawn back
-- over the fill. Tiled styles keep the art at its native pixel density.
-------------------------------------------------------------------------------
local DIR = "Interface\\AddOns\\EllesmereUI\\media\\textures\\shields_335\\"
local WHITE = "Interface\\Buttons\\WHITE8X8"
A.STYLES = {
    striped         = { DIR .. "striped-5.tga", 256, 128 },
    stripedReversed = { DIR .. "striped-5-reversed.tga", 256, 128 },
    stripedThick    = { DIR .. "striped-thick.tga", 256, 128 },
    stripedThickR   = { DIR .. "striped-thick-r.tga", 256, 128 },
    clean           = { WHITE },
    blizzard        = { DIR .. "blizzard.tga" },
    -- Unit Frames' Retail "Striped" is striped3 stretched across the bar.
    stripedStretch  = { DIR .. "striped3.tga" },
}
A.STYLE_NAMES = { none = "None", striped = "Striped", stripedReversed = "Striped Reversed",
    stripedThick = "Striped Thick", stripedThickR = "Striped Thick Reversed",
    clean = "Clean (Flat)", blizzard = "Blizzard" }
A.STYLE_ORDER = { "none", "striped", "stripedReversed", "stripedThick", "stripedThickR", "clean", "blizzard" }
A.EDGE_NAMES = { overlay = "Overlay", overlayReverse = "Overlay Reverse", right = "From Right Edge", left = "From Left Edge" }
A.EDGE_ORDER = { "overlay", "overlayReverse", "right", "left" }
A.OVERSHIELD_NAMES = { never = "Never", always = "Always", fromleft = "From Left" }
A.OVERSHIELD_ORDER = { "never", "always", "fromleft" }

-- Style dropdown data: built-ins, then the module's SharedMedia bar textures.
function A.StyleMenu(textureNames, textureOrder)
    local values, order = {}, {}
    for k, v in pairs(A.STYLE_NAMES) do values[k] = v end
    for i, k in ipairs(A.STYLE_ORDER) do order[i] = k end
    local first = true
    for _, k in ipairs(textureOrder or {}) do
        if type(k) == "string" and k:find("^sm:") then
            if first then order[#order + 1] = "---"; first = false end
            order[#order + 1] = k
            values[k] = textureNames and textureNames[k] or k
        end
    end
    return values, order
end

-- Style -> texture path, tile width, tile height (no size = stretched).
function A.ResolveStyle(style, textures, overrides)
    local e = (overrides and overrides[style]) or A.STYLES[style]
    if e then return e[1], e[2], e[3] end
    local path = textures and EllesmereUI.ResolveTexturePath and EllesmereUI.ResolveTexturePath(textures, style)
    return path or WHITE
end

function A.CreateOverlay(host, layer)
    local o = { host = host }
    o.fw = host:CreateTexture(nil, layer or "OVERLAY")
    o.os = host:CreateTexture(nil, layer or "OVERLAY")
    o.fw:Hide(); o.os:Hide()
    return o
end

function A.Hide(o)
    if o then o.fw:Hide(); o.os:Hide() end
end

-- a, b: segment as fractions of the bar along the fill axis.
local function Place(o, t, a, b, w, h, vertical, reverse, tw, th)
    if b - a <= 0 then t:Hide(); return end
    if reverse then a, b = 1 - b, 1 - a end
    t:ClearAllPoints()
    if vertical then
        local len = max(1, (b - a) * h)
        t:SetPoint("BOTTOMLEFT", o.host, "BOTTOMLEFT", 0, a * h)
        t:SetWidth(w); t:SetHeight(len)
        if tw then
            local sx, sy = max(tw, w), max(th, h)
            t:SetTexCoord(0, w / sx, (1 - b) * h / sy, (1 - a) * h / sy)
        else
            t:SetTexCoord(0, 1, 1 - b, 1 - a)
        end
    else
        local len = max(1, (b - a) * w)
        t:SetPoint("TOPLEFT", o.host, "TOPLEFT", a * w, 0)
        t:SetWidth(len); t:SetHeight(h)
        if tw then
            local sx, sy = max(tw, w), max(th, h)
            t:SetTexCoord(a * w / sx, b * w / sx, 0, h / sy)
        else
            t:SetTexCoord(a, b, 0, 1)
        end
    end
    t:Show()
end

-- hp, maxHP, absorb in health points. edge: overlay | overlayReverse | right |
-- left. overshield (overlay only): always | never | fromleft. alpha 0-1.
function A.Paint(o, hp, maxHP, absorb, style, r, g, b, alpha, edge, overshield, vertical, reverse, w, h, textures, overrides)
    if not o then return end
    maxHP = tonumber(maxHP) or 0
    absorb = tonumber(absorb) or 0
    w = w or o.host:GetWidth() or 0
    h = h or o.host:GetHeight() or 0
    if not style or style == "none" or maxHP <= 0 or absorb <= 0 or w <= 0 or h <= 0 then A.Hide(o); return end
    local path, tw, th = A.ResolveStyle(style, textures, overrides)
    if o.path ~= path then
        o.path = path
        o.fw:SetTexture(path); o.os:SetTexture(path)
    end
    o.fw:SetVertexColor(r or 1, g or 1, b or 1, alpha or 1)
    o.os:SetVertexColor(r or 1, g or 1, b or 1, alpha or 1)
    local f = max(0, min(1, (tonumber(hp) or 0) / maxHP))
    local s = min(1, absorb / maxHP)
    local a1, b1, a2, b2 = 0, 0, 0, 0
    if edge == "right" then
        a1, b1 = 1 - s, 1
    elseif edge == "left" then
        a1, b1 = 0, s
    elseif edge == "overlayReverse" then
        a1, b1 = max(0, f - s), f
    else
        a1, b1 = f, min(1, f + s)
        local over = f + s - 1
        if over > 0 then
            if overshield == "fromleft" then a2, b2 = 0, min(f, over)
            elseif overshield ~= "never" then a2, b2 = max(0, f - over), f end
        end
    end
    Place(o, o.fw, a1, b1, w, h, vertical, reverse, tw, th)
    Place(o, o.os, a2, b2, w, h, vertical, reverse, tw, th)
end
