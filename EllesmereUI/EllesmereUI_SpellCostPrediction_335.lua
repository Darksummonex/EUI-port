-------------------------------------------------------------------------------
-- EllesmereUI_SpellCostPrediction_335.lua
-- Wrath port of EllesmereUI_SpellCostPrediction.lua: while a spell with a
-- cast time is cast, the mana it will spend is drawn on the power bar in a
-- lighter color, like Blizzard's player frame.
--
-- Same host API as Retail (SCP.Color, Attach(key, bar, cb), Detach; hosts
-- "uf" and "erb"). 3.3.5 has no clipping frames, mask textures or secret
-- values, so the segment is a plain texture laid over the end of the fill:
-- its length is min(cost, shown value) of the bar's range, which keeps it
-- inside the bar without clipping. Its geometry is read from the bar's own
-- value, range, size, orientation and texture while the segment shows, so a
-- smoothed fill, mana ticks, resizes and texture swaps follow with no hooks.
-- The cast is matched by UnitCastingInfo's cast ID: a failed instant pressed
-- during the cast leaves the segment alone.
-------------------------------------------------------------------------------

local EllesmereUI = _G.EllesmereUI
if not EllesmereUI then return end

local MANA = 0
local WHITE = "Interface\\Buttons\\WHITE8X8"
local EVENTS = { "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP",
    "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED" }

local hosts = {}
local built = {}
local ev
local listening = false
local castID, castName, castRank
local castCost
local costRead = false

local SCP = {}
EllesmereUI.SpellCostPrediction = SCP

function SCP.Color(s)
    local c = s and s.powerCostColor
    if c then return c.r, c.g, c.b end
    local b = POWERBAR_PREDICTION_COLOR_MANA
    if b and b.GetRGB then return b:GetRGB() end
    return 0.40, 0.70, 1
end

local function CastCost()
    if not costRead then
        costRead = true
        castCost = nil
        if castName then
            local _, _, _, cost, _, powerType
            if castRank and castRank ~= "" then
                _, _, _, cost, _, powerType = GetSpellInfo(castName .. "(" .. castRank .. ")")
            end
            if cost == nil then
                _, _, _, cost, _, powerType = GetSpellInfo(castName)
            end
            if powerType == MANA and type(cost) == "number" and cost > 0 then castCost = cost end
        end
    end
    return castCost
end

-- Lays the segment over the last `cost` of the fill. Returns false when
-- there is nothing to draw (empty bar, zero size, no cost).
local function Place(h)
    local power, seg = h.bar, h.seg
    local cost = CastCost()
    local lo, hi = power:GetMinMaxValues()
    local val = power:GetValue()
    local range = (hi or 0) - (lo or 0)
    local w, ht = power:GetWidth(), power:GetHeight()
    if not cost or range <= 0 or not val or w <= 0 or ht <= 0 then return false end
    local shown = math.max(0, math.min(val - lo, range))
    local part = math.min(cost, shown)
    if part <= 0 then return false end
    local vert = power.GetOrientation and power:GetOrientation() == "VERTICAL" or false
    local rev = power.GetReverseFill and power:GetReverseFill() and true or false
    local len = vert and ht or w
    local endFrac, startFrac = shown / range, (shown - part) / range
    seg:ClearAllPoints()
    if vert then
        seg:SetWidth(w)
        seg:SetHeight(math.max(1, part / range * len))
        if rev then
            seg:SetPoint("TOP", power, "TOP", 0, -startFrac * len)
            seg:SetTexCoord(0, 1, startFrac, endFrac)
        else
            seg:SetPoint("BOTTOM", power, "BOTTOM", 0, startFrac * len)
            seg:SetTexCoord(0, 1, 1 - endFrac, 1 - startFrac)
        end
    else
        seg:SetHeight(ht)
        seg:SetWidth(math.max(1, part / range * len))
        if rev then
            seg:SetPoint("RIGHT", power, "RIGHT", -startFrac * len, 0)
            seg:SetTexCoord(1 - endFrac, 1 - startFrac, 0, 1)
        else
            seg:SetPoint("LEFT", power, "LEFT", startFrac * len, 0)
            seg:SetTexCoord(startFrac, endFrac, 0, 1)
        end
    end
    return true
end

local function HideHost(h)
    if h.holder then h.holder:Hide() end
end

local CurrentCastID

local function OnHolderUpdate(holder)
    local h = holder._euiHost
    if castID and not CurrentCastID() then
        castID, castName, castRank, castCost = nil, nil, nil, nil
    end
    if not castID or hosts[h.key] ~= h then
        holder:Hide()
    elseif Place(h) then
        h.seg:Show()
    else
        h.seg:Hide()
    end
end

local function Show(h)
    local power = h.bar
    local ptype = h.cb.PowerType(power)
    if ptype ~= MANA or not CastCost() then
        HideHost(h)
        return
    end
    if not h.holder then
        local holder = CreateFrame("Frame", nil, power)
        holder:SetAllPoints(power)
        holder._euiHost = h
        h.holder = holder
        h.seg = holder:CreateTexture(nil, "OVERLAY")
        holder:SetScript("OnUpdate", OnHolderUpdate)
    end
    h.holder:SetFrameLevel(power:GetFrameLevel() + 1)
    local pfill = power:GetStatusBarTexture()
    local path = pfill and pfill:GetTexture() or WHITE
    if h.texPath ~= path then
        h.texPath = path
        h.seg:SetTexture(path)
    end
    local r, g, b, a = h.cb.Color(power)
    h.seg:SetVertexColor(r, g, b, a or 1)
    h.holder:Show()
    OnHolderUpdate(h.holder)
end

local function HideAll()
    for _, h in pairs(hosts) do HideHost(h) end
end

CurrentCastID = function()
    local name, _, _, _, _, _, _, id = UnitCastingInfo("player")
    if name then return id or name end
end

local function OnEvent(_, event, unit, spellName, rank)
    if unit ~= "player" then return end
    if event == "UNIT_SPELLCAST_START" then
        castID = CurrentCastID() or spellName
        castName, castRank, costRead = spellName, rank, false
        for _, h in pairs(hosts) do
            if h.bar:IsVisible() then Show(h) end
        end
        return
    end
    if castID == nil then return end
    if event == "UNIT_SPELLCAST_FAILED" then
        local live = CurrentCastID()
        if live and live == castID then return end
    end
    castID, castName, castRank, castCost = nil, nil, nil, nil
    HideAll()
end

local function Listen()
    local on = false
    for _, h in pairs(hosts) do
        if h.bar:IsVisible() then on = true; break end
    end
    if on == listening then return end
    listening = on
    if on then
        for i = 1, #EVENTS do ev:RegisterEvent(EVENTS[i]) end
    else
        ev:UnregisterAllEvents()
        castID, castName, castRank, castCost = nil, nil, nil, nil
        HideAll()
    end
end

local function OnHostShow(bar)
    local h = built[bar]
    if hosts[h.key] == h then
        Listen()
        if castID then Show(h) end
    end
end

local function OnHostHide(bar)
    local h = built[bar]
    if hosts[h.key] == h then Listen() end
end

function SCP.Attach(key, bar, cb)
    local h = built[bar]
    if not h then
        if not ev then
            ev = CreateFrame("Frame")
            ev:SetScript("OnEvent", OnEvent)
        end
        h = { bar = bar }
        built[bar] = h
        bar:HookScript("OnShow", OnHostShow)
        bar:HookScript("OnHide", OnHostHide)
    end
    local old = hosts[key]
    local fresh = old ~= h or h.cb ~= cb
    if fresh then
        if old and old ~= h then HideHost(old) end
        h.cb, h.key = cb, key
        hosts[key] = h
        Listen()
    end
    if castID and bar:IsVisible() then Show(h) end
end

function SCP.Detach(key)
    local h = hosts[key]
    if not h then return end
    hosts[key] = nil
    HideHost(h)
    Listen()
end
