-------------------------------------------------------------------------------
-- EllesmereUI_ManaRegenSpark_335.lua
-- Wrath port of EllesmereUI_ManaRegenSpark.lua: mana regen spark on mana
-- power bars (the five second rule, optionally followed by 2s regen ticks).
--
-- Same rules and host API as Retail (Attach / Detach / SetMana, hosts "uf"
-- and "erb"). A completed cast of a spell that costs mana starts one 5s sweep;
-- in Regen Ticks mode 2s sweeps follow while mana keeps updating. 3.3.5 has
-- no StatusBar timer fill, so one OnUpdate on the event frame, running only
-- while a sweep is shown, places each spark from the sweep's elapsed time.
-- UNIT_SPELLCAST_SUCCEEDED carries the spell name and rank; the cost comes
-- from GetSpellInfo for that rank (power type 0 = mana). UNIT_MANA replaces
-- UNIT_POWER_UPDATE as the regen keep-alive. Warriors and rogues, who have
-- no mana, get nothing.
-------------------------------------------------------------------------------

local EllesmereUI = _G.EllesmereUI
if not EllesmereUI then return end
local _, PLAYER_CLASS = UnitClass("player")
if PLAYER_CLASS == "WARRIOR" or PLAYER_CLASS == "ROGUE" then return end

local WINDOW = 5
local TICK = 2
local SPARK_W = 8
local SPARK_TEX = "Interface\\AddOns\\EllesmereUI\\media\\cast_spark.tga"

local hosts = {}
local built = {}
local mana = {}
local listening = false
local ticking = false
local sweepStart, sweepLen, sweepEnd
local inWindow = false
local regenSeen = false
local ev = CreateFrame("Frame")

local function CostsMana(spellName, rank)
    if not spellName then return false end
    local _, _, _, cost, _, powerType
    if rank and rank ~= "" then
        _, _, _, cost, _, powerType = GetSpellInfo(spellName .. "(" .. rank .. ")")
    end
    if cost == nil then
        _, _, _, cost, _, powerType = GetSpellInfo(spellName)
    end
    return powerType == 0 and type(cost) == "number" and cost > 0
end

local function Orientation(bar)
    local vert = bar.GetOrientation and bar:GetOrientation() == "VERTICAL" or false
    local rev = bar.GetReverseFill and bar:GetReverseFill() and true or false
    return vert, rev
end

local function Layout(h)
    local vert, rev = Orientation(h.bar)
    if h.vert == vert and h.rev == rev then return end
    h.vert, h.rev = vert, rev
    local s = h.spark
    s:ClearAllPoints()
    if vert then
        s:SetTexCoord(0, 0, 1, 0, 0, 1, 1, 1)
    else
        s:SetTexCoord(0, 1, 0, 1)
    end
end

local function Place(h, frac)
    local bar, s = h.bar, h.spark
    local w, ht = bar:GetWidth(), bar:GetHeight()
    s:ClearAllPoints()
    if h.vert then
        local off = frac * ht
        if h.rev then
            s:SetPoint("CENTER", bar, "TOP", 0, -off)
        else
            s:SetPoint("CENTER", bar, "BOTTOM", 0, off)
        end
        s:SetWidth(w)
        s:SetHeight(SPARK_W)
    else
        local off = frac * w
        if h.rev then
            s:SetPoint("CENTER", bar, "RIGHT", -off, 0)
        else
            s:SetPoint("CENTER", bar, "LEFT", off, 0)
        end
        s:SetWidth(SPARK_W)
        s:SetHeight(ht)
    end
end

local function Shows(h)
    return sweepEnd and (inWindow or h.ticks) and mana[h.key] and h.bar:IsVisible()
end

local Sweep, Idle

local function OnUpdate()
    local now = GetTime()
    if now >= sweepEnd then
        if ticking and (inWindow or regenSeen) then
            inWindow = false
            regenSeen = false
            Sweep(TICK, sweepEnd)
        else
            Idle()
        end
        return
    end
    local frac = (now - sweepStart) / sweepLen
    for _, h in pairs(hosts) do
        if h.holder:IsShown() then Place(h, frac) end
    end
end

local function Arm(h)
    if Shows(h) then
        h.holder:Show()
        Place(h, (GetTime() - sweepStart) / sweepLen)
    else
        h.holder:Hide()
    end
end

Idle = function()
    ev:SetScript("OnUpdate", nil)
    sweepStart, sweepLen, sweepEnd = nil, nil, nil
    inWindow = false
    regenSeen = false
    for _, h in pairs(hosts) do h.holder:Hide() end
end

Sweep = function(len, start)
    local now = GetTime()
    if not start or start + len <= now then start = now end
    sweepStart, sweepLen, sweepEnd = start, len, start + len
    for _, h in pairs(hosts) do Arm(h) end
    ev:SetScript("OnUpdate", OnUpdate)
end

ev:SetScript("OnEvent", function(_, event, unit, spellName, rank)
    if unit ~= "player" then return end
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if CostsMana(spellName, rank) then
            inWindow = true
            regenSeen = false
            Sweep(WINDOW)
        end
    elseif event == "UNIT_MANA" and not inWindow then
        if sweepEnd then regenSeen = true else Sweep(TICK) end
    end
end)

local function Listen()
    local on, tk = false, false
    for _, h in pairs(hosts) do
        if h.bar:IsVisible() then
            on = true
            if h.ticks then tk = true end
        end
    end
    if tk ~= ticking then
        ticking = tk
        if tk then ev:RegisterEvent("UNIT_MANA") else ev:UnregisterEvent("UNIT_MANA") end
    end
    if on == listening then return end
    listening = on
    if on then
        ev:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    else
        ev:UnregisterAllEvents()
        ticking = false
        Idle()
    end
end

local function OnHostShow(bar)
    local h = built[bar]
    if hosts[h.key] == h then
        Listen()
        Arm(h)
    end
end

local function OnHostHide(bar)
    local h = built[bar]
    if hosts[h.key] == h then Listen() end
end

local MRS = {}
EllesmereUI.ManaRegenSpark = MRS

function MRS.Attach(key, bar, ticks)
    ticks = ticks and true or false
    local h = built[bar]
    if not h then
        local o = CreateFrame("Frame", nil, bar)
        o:SetAllPoints(bar)
        o:SetFrameLevel(bar:GetFrameLevel() + 2)
        o:Hide()
        local s = o:CreateTexture(nil, "OVERLAY")
        s:SetTexture(SPARK_TEX)
        s:SetBlendMode("ADD")
        h = { bar = bar, holder = o, spark = s }
        built[bar] = h
        bar:HookScript("OnShow", OnHostShow)
        bar:HookScript("OnHide", OnHostHide)
    end
    Layout(h)
    local old = hosts[key]
    if old == h then
        if h.ticks ~= ticks then
            h.ticks = ticks
            Listen()
            Arm(h)
        end
        return
    end
    if old then old.holder:Hide() end
    h.key, h.ticks = key, ticks
    hosts[key] = h
    Listen()
    Arm(h)
end

function MRS.Detach(key)
    local h = hosts[key]
    if not h then return end
    hosts[key] = nil
    h.holder:Hide()
    Listen()
end

function MRS.SetMana(key, isMana)
    if mana[key] == isMana then return end
    mana[key] = isMana
    local h = hosts[key]
    if h then
        if isMana then Layout(h) end
        Arm(h)
    end
end
