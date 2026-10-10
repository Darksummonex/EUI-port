-- End caps (Retail 9.4 EUI_ActionBars_Chrome.lua, Wrath subset). Every bar can
-- carry the vanilla gryphons at its left end, right end or both (the End Caps
-- checklist), with its own size and offsets (the End Caps cog). Retail's other
-- arts (Modern and WoW Forever) are atlases this client lacks: Classic only.
-- Built per bar the first time a side is on; off, a built host hides.
local _, ns = ...
if not ns or not ns.IsWrath then return end
local min, max = math.min, math.max

-- Vanilla's compact end caps (the right one mirrored): the size at the icon
-- size `unit` the art is drawn for (caps only ever scale down), the level over
-- the bar, and the anchors { left point, bar point, x, y, right point, bar
-- point, x, y } for one row (near) and several (far).
ns.AB_CAP = {
    unit = 36, w = 128, h = 128, lvl = 17,
    file = "Interface\\MainMenuBar\\UI-MainMenuBar-EndCap-Dwarf",
    near = { "BOTTOMRIGHT", "BOTTOMLEFT", 28, -3, "BOTTOMLEFT", "BOTTOMRIGHT", -29, -3 },
    far  = { "BOTTOMRIGHT", "BOTTOMLEFT", 0, -3, "BOTTOMLEFT", "BOTTOMRIGHT", -1, -3 },
}

-- Which ends of a bar show a cap; unset reads none.
function ns.AB_CapsSides(key)
    local s = ns.GetSettings(key)
    if not s then return false, false end
    return s.endCapLeft == true, s.endCapRight == true
end

-- A bar's cap tweaks: the size as a fraction of the art's own, the X/Y offsets
-- (X mirrored: positive moves both caps away from the bar; Y defaults to 5),
-- and last the size in percent as stored.
function ns.AB_CapsTweak(key)
    local s = ns.GetSettings(key) or {}
    local sc = tonumber(s.endCapScale) or 100
    return sc / 100, tonumber(s.endCapOffsetX) or 0, tonumber(s.endCapOffsetY) or 5, sc
end

-- How far a bar's caps reach past a button grid w x gridH (left, right, top,
-- bottom), for a preview that must make room. pxK scales the offsets.
function ns.AB_CapsReach(key, btnW, gridH, multi, pxK, sideL, sideR)
    if not (sideL or sideR) then return 0, 0, 0, 0 end
    local c = ns.AB_CAP
    local sc, dx, dy = ns.AB_CapsTweak(key)
    pxK = pxK or 1
    local kc = min(btnW / c.unit, 1) * sc
    local g = multi and c.far or c.near
    local top = max(0, (c.h + g[4]) * kc - gridH + dy * pxK)
    local bottom = max(0, -g[4] * kc - dy * pxK)
    local left = sideL and max(0, (c.w - g[3]) * kc + dx * pxK) or 0
    local right = sideR and max(0, (c.w + g[7]) * kc + dx * pxK) or 0
    return left, right, top, bottom
end

-- Paints the caps onto st (a state table the caller keeps) round a button grid
-- w x h whose TOPLEFT sits at (ox, oy) off owner's TOPLEFT; btnW = the button
-- size, multi = several rows. The caps sit the art's lvl over owner, scale
-- with the icon size (down only) times the bar's size, and move by its offsets
-- (times pxK, the preview's scale; nil = 1).
function ns.AB_PaintCaps(st, owner, ox, oy, w, h, btnW, multi, pxK, key, sideL, sideR)
    local host = st.capHost
    if not (sideL or sideR) then
        if host then host:Hide() end
        return
    end
    local c = ns.AB_CAP
    if not host then
        host = CreateFrame("Frame", nil, owner)
        st.capL = host:CreateTexture(nil, "OVERLAY")
        st.capR = host:CreateTexture(nil, "OVERLAY")
        st.capL:SetTexture(c.file); st.capL:SetTexCoord(0, 1, 0, 1)
        st.capR:SetTexture(c.file); st.capR:SetTexCoord(1, 0, 0, 1)
        st.capL:SetWidth(c.w); st.capL:SetHeight(c.h)
        st.capR:SetWidth(c.w); st.capR:SetHeight(c.h)
        st.capHost = host
    end
    local sc, dx, dy = ns.AB_CapsTweak(key)
    local kc = min(btnW / c.unit, 1) * sc
    dx, dy = dx * (pxK or 1) / kc, dy * (pxK or 1) / kc
    local g = multi and c.far or c.near
    local capL, capR = st.capL, st.capR
    capL:ClearAllPoints(); capR:ClearAllPoints()
    capL:SetPoint(g[1], host, g[2], g[3] - dx, g[4] + dy)
    capR:SetPoint(g[5], host, g[6], g[7] + dx, g[8] + dy)
    if sideL then capL:Show() else capL:Hide() end
    if sideR then capR:Show() else capR:Hide() end
    host:SetFrameLevel(owner:GetFrameLevel() + c.lvl)
    host:SetScale(kc)
    host:ClearAllPoints()
    host:SetPoint("TOPLEFT", owner, "TOPLEFT", ox / kc, oy / kc)
    host:SetWidth(max(1, w / kc)); host:SetHeight(max(1, h / kc))
    host:Show()
end

-- A live bar's caps, from Layout's tail: horizontal bars only (the art sits at
-- the bar's two ends). The host is the bar's child, so it fades and hides with it.
function ns.AB_ApplyCaps(key, bar, btnW, vertical, multi)
    local sideL, sideR = false, false
    if not vertical then sideL, sideR = ns.AB_CapsSides(key) end
    local st = bar._euiCaps
    if not (sideL or sideR) then
        if st and st.capHost then st.capHost:Hide() end
        return
    end
    if not st then st = {}; bar._euiCaps = st end
    ns.AB_PaintCaps(st, bar, 0, 0, bar:GetWidth(), bar:GetHeight(), btnW, multi, nil, key, sideL, sideR)
end
