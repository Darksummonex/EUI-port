-- EllesmereUIDataBars 3.3.5: location and coordinates block factories
-- (port of Retail Blocks\Location.lua).
local _, ns = ...
if not ns.IsWrath then return end
local L = ns.L
local MEDIA = ns.MEDIA
local K = ns.BlockKit

-- Upvalues
local CreateFrame      = CreateFrame
local InCombatLockdown = InCombatLockdown
local GetTime          = GetTime
local format           = string.format
local floor            = math.floor
local max              = math.max
local Size             = ns.Size

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
local ZoneReactionColor    = K.ZoneReactionColor
local IconColorOf          = K.IconColorOf

-------------------------------------------------------------------------------
--  LOCATION + COORDINATES (two block types on one text renderer)
-------------------------------------------------------------------------------
-- Location block width in Manual mode (px); shared with the options slider.
local LOC_MAX_WIDTH_DEFAULT = 200
ns.LOC_MAX_WIDTH_DEFAULT = LOC_MAX_WIDTH_DEFAULT

-- Icon size above the text size (the map glyph needs less headroom than wide icons).
local LOC_ICON_EXTRA = 4

function ns.LocationWidthMode(s)
    return (s and s.widthMode) or "auto"
end

local COORD_FMT = { [0] = "%.0f, %.0f", [1] = "%.1f, %.1f", [2] = "%.2f, %.2f" }
-- Width rulers: coords reserves width from each precision's widest value, never the live one.
local COORD_TEMPLATE = { [0] = "88, 88", [1] = "88.8, 88.8", [2] = "88.88, 88.88" }

local function LocDisplayText(showSubZone)
    local zone = GetRealZoneText() or ""
    local sub = GetMinimapZoneText() or ""
    if showSubZone and sub ~= "" and sub ~= zone then
        return zone .. ": " .. sub
    end
    if sub ~= "" then return sub end
    return zone
end

-- Wrath reads the player position off the world map's current zone. The map is
-- only moved back to the player's zone while WorldMapFrame is hidden, so the map
-- a user is browsing never changes under them.
local Map = { file = nil, reset = false, retryAt = 0 }
function Map.Ensure(force)
    if not SetMapToCurrentZone then return end
    if WorldMapFrame and WorldMapFrame:IsShown() then return end
    local file = GetMapInfo and GetMapInfo()
    if not force and Map.reset and file == Map.file then return end
    SetMapToCurrentZone()
    Map.file = GetMapInfo and GetMapInfo()
    Map.reset = true
end

local function LocPlayerPosition()
    if not GetPlayerMapPosition then return nil end
    Map.Ensure(false)
    local x, y = GetPlayerMapPosition("player")
    if not (x and y) or (x == 0 and y == 0) then
        -- No position on the current map (instance, map left on another zone):
        -- re-sync at most every few seconds; instances keep reporting 0,0.
        local now = GetTime()
        if now >= Map.retryAt then
            Map.retryAt = now + 5
            Map.Ensure(true)
            x, y = GetPlayerMapPosition("player")
        end
    end
    if not (x and y) or (x == 0 and y == 0) then return nil end
    return x * 100, y * 100
end

local function LocCoordText(precision)
    local x, y = LocPlayerPosition()
    if not x then return "-" end
    return format(COORD_FMT[precision] or COORD_FMT[0], x, y)
end

local function LocContinentName()
    if not (GetCurrentMapContinent and GetMapContinents) then return nil end
    if WorldMapFrame and WorldMapFrame:IsShown() then return nil end
    Map.Ensure(false)
    local c = GetCurrentMapContinent()
    if not c or c <= 0 then return nil end
    return (select(c, GetMapContinents()))
end

local function LocZoneStatus()
    local pvpType = GetZonePVPInfo and GetZonePVPInfo()
    if pvpType == "sanctuary" then return SANCTUARY_TERRITORY or "(Sanctuary)" end
    if pvpType == "arena" then return ARENA or "Arena" end
    if pvpType == "friendly" then return FRIENDLY or "Friendly" end
    if pvpType == "hostile" then return HOSTILE or "Hostile" end
    if pvpType == "combat" then return COMBAT or "Combat" end
    if pvpType == "contested" then return CONTESTED_TERRITORY or "(Contested Territory)" end
    if IsInInstance() then return AGGRO_WARNING_IN_INSTANCE or "Instance" end
    return CONTESTED_TERRITORY or "(Contested Territory)"
end

local function LocTooltip(ownerFrame)
    local ar, ag, ab = ns.GetAccent()
    ns.Tip_Begin(ownerFrame)
    ns.Tip_AddDouble(ZONE or "Zone", LocDisplayText(true), 0.6, 0.6, 0.6, 1, 1, 1)
    local continent = LocContinentName()
    if continent then
        ns.Tip_AddDouble(CONTINENT or "Continent", continent, 0.6, 0.6, 0.6, 1, 1, 1)
    end
    local sr, sg, sb = ZoneReactionColor()
    ns.Tip_AddDouble(STATUS or "Status", LocZoneStatus(), 0.6, 0.6, 0.6, sr, sg, sb)
    ns.Tip_AddLine(" ")
    ns.Tip_AddDouble(L["LEFT_CLICK"], L["TOGGLE_WORLD_MAP"], 1, 1, 1, ar, ag, ab)
    ns.Tip_Show()
end

-- Insecure world map toggle (WorldMapFrame is not protected on Wrath). Combat
-- keeps the click inert, as the Retail secure passthrough does.
local function ToggleWorldMapFrame()
    if InCombatLockdown() then return end
    if WorldMapFrame and ToggleFrame then ToggleFrame(WorldMapFrame)
    elseif ToggleWorldMap then ToggleWorldMap() end
end

-- Shared single-line text block. opts:
--   text()        -> string to display
--   template()    -> stable width-reservation string; nil sizes from the live text
--   width()       -> fixed width in px, or nil to size from the text
--   collapse()    -> true drops the block from the bar entirely
--   texture       -> optional icon file, gated by the block's showIcon setting
--   events        -> event list driving Refresh
--   onEvent(ev)   -> optional hook run before the event Refresh
--   tickSeconds   -> dedicated ticker period, for values no event announces
local function MakeLocationBlock(blockCfg, slot, content, barCtx, opts)
    local inst = { cfg = blockCfg, slot = slot, content = content, ctx = barCtx }
    inst.key = InstKey(barCtx, blockCfg)
    inst.events = opts.events

    local function BC() return barCtx.cfg end
    local function D() return blockCfg.settings or {} end
    -- Geometry and Show/Hide wait for regen only if something made the content protected.
    local function Locked() return InCombatLockdown() and content.IsProtected and content:IsProtected() end

    local mouseOver = false
    local ticker -- private OnUpdate frame; shown = ticking
    local lastText

    local frame = CreateFrame("Button", nil, content)
    Size(frame, 60, 20); frame:EnableMouse(true); frame:RegisterForClicks("AnyUp")
    local icon
    if opts.texture then
        icon = frame:CreateTexture(nil, "OVERLAY")
        icon:SetTexture(opts.texture); icon:SetPoint("LEFT")
    end
    local text = frame:CreateFontString(nil, "OVERLAY")
    AttachTextOffset(inst, text)
    text:SetPoint("LEFT")
    local measureFS
    if opts.template then
        measureFS = frame:CreateFontString(nil, "OVERLAY")
        measureFS:Hide()
    end

    local function ApplyColors()
        local r, g, b
        if mouseOver then r, g, b = ns.GetAccent() else r, g, b = BlockColorOf(blockCfg) end
        text:SetTextColor(r, g, b, 1)
        if icon then
            if mouseOver then
                icon:SetVertexColor(r, g, b, 1)
            else
                local ir, ig, ib = IconColorOf(blockCfg)
                icon:SetVertexColor(ir, ig, ib, 1)
            end
        end
    end

    frame:SetScript("OnEnter", function()
        mouseOver = true
        ApplyColors()
        LocTooltip(frame)
    end)
    frame:SetScript("OnLeave", function()
        mouseOver = false
        ns.Tip_Hide(frame)
        ApplyColors()
    end)
    frame:SetScript("OnClick", function(_, mb)
        if mb == "LeftButton" then ToggleWorldMapFrame() end
    end)

    function inst:Refresh(pre)
        local collapsed = (opts.collapse and opts.collapse()) or false
        if content:IsShown() == collapsed and not Locked() then
            ns.Shown(content, not collapsed)
        end
        if collapsed then
            lastText = nil
            MaybeRelayout(inst)
            return
        end

        local barCfg = BC()
        local barH = barCtx.GetThickness()
        local fontSize = max(9, floor(CONTENT_BASE * 0.4333 + 0.5))
        local isSide = barCtx.IsVertical()
        local gap = ICON_GAP

        local str = pre or opts.text()
        lastText = str
        ns.SetFont(text, fontSize, barCfg)
        text:SetText(str)
        ApplyColors()

        local iconSz = 0
        if icon and D().showIcon ~= false then
            iconSz = fontSize + LOC_ICON_EXTRA
            Size(icon, iconSz, iconSz)
            icon:Show()
        elseif icon then
            icon:Hide()
        end

        if Locked() then return end

        if isSide then
            local slotW = VSlotW(inst)
            local innerW = max(36, slotW - 8)
            text:ClearAllPoints()
            if iconSz > 0 then
                icon:ClearAllPoints(); icon:SetPoint("LEFT", frame, "LEFT", 0, 0)
                text:SetPoint("LEFT", icon, "RIGHT", gap, 0)
                ns.SetWrappedText(text, max(16, innerW - iconSz - gap - 2), "LEFT")
            else
                text:SetPoint("CENTER", frame, "CENTER", 0, 0)
                ns.SetWrappedText(text, innerW, "CENTER")
            end
            local lineH = max(fontSize + 4, iconSz, ns.SnapToPixelGrid(text:GetStringHeight() or fontSize))
            Size(frame, innerW, lineH)
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", content, "CENTER", 0, 0)
            Size(content, slotW, max(lineH + 8, barH))
        else
            ns.ResetInlineText(text, "LEFT")
            local iconPad = 0
            if iconSz > 0 then
                iconPad = iconSz + gap
                icon:ClearAllPoints(); icon:SetPoint("LEFT", frame, "LEFT", 0, 0)
            end
            text:ClearAllPoints()
            text:SetPoint("LEFT", frame, "LEFT", iconPad, 0)
            -- Manual width: exactly this wide whatever the zone is called (longer names clip).
            local w = opts.width and opts.width()
            if w then
                text:SetWidth(max(20, w - iconPad - 2))
                if text.SetWordWrap then text:SetWordWrap(false) end
            else
                local tpl = opts.template and opts.template()
                if tpl then
                    ns.SetFont(measureFS, fontSize, barCfg)
                    measureFS:SetText(tpl)
                    w = iconPad + ns.SnapToPixelGrid(measureFS:GetStringWidth() or 40) + 2
                else
                    w = iconPad + ns.SnapToPixelGrid(text:GetStringWidth() or 40) + 2
                end
            end
            if w < 24 then w = 24 end
            Size(frame, w, barH)
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", content, "CENTER", 0, 0)
            Size(content, w, barH)
        end
        MaybeRelayout(inst)
    end

    inst.eventFrame = MakeEventFrame(inst, function(self, event)
        if opts.onEvent then opts.onEvent(event) end
        self:Refresh()
    end)

    -- Movement raises no event: a private 0.5 s OnUpdate ticker, dirty-gated on the text.
    local function StartTicker()
        if not opts.tickSeconds then return end
        if not ticker then
            ticker = CreateFrame("Frame")
            local elapsed = 0
            ticker:SetScript("OnUpdate", function(_, dt)
                elapsed = elapsed + (dt or 0)
                if elapsed < opts.tickSeconds then return end
                elapsed = 0
                if opts.collapse and opts.collapse() then return end
                local str = opts.text()
                if str == lastText then return end
                inst:Refresh(str)
            end)
        end
        ticker:Show()
    end
    local function StopTicker()
        if ticker then ticker:Hide() end
    end

    function inst:Enable()
        if not content:IsShown() and not Locked() then content:Show() end
        lastText = nil
        RegisterInstEvents(self)
        StartTicker()
    end

    function inst:Disable()
        UnregisterInstEvents(self)
        StopTicker()
        if not Locked() then content:Hide() end
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
        StopTicker()
        if not Locked() then content:Hide() end
    end

    return inst
end

ns.BlockFactories.location = function(blockCfg, slot, content, barCtx)
    local function D() return blockCfg.settings or {} end

    return MakeLocationBlock(blockCfg, slot, content, barCtx, {
        events = { "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA",
                   "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED" },
        texture = ns.MICROMENU_MEDIA .. "menu-map",
        text = function() return LocDisplayText(D().showSubZone ~= false) end,
        width = function()
            local d = D()
            if ns.LocationWidthMode(d) ~= "manual" then return nil end
            return d.maxWidth or LOC_MAX_WIDTH_DEFAULT
        end,
    })
end

ns.BlockFactories.coords = function(blockCfg, slot, content, barCtx)
    local function D() return blockCfg.settings or {} end
    local function Precision()
        local p = D().precision
        if p == nil then p = 0 end
        return p
    end

    return MakeLocationBlock(blockCfg, slot, content, barCtx, {
        -- Wrath positions are map-relative, so subzone map switches re-sync the map too.
        events = { "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA",
                   "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED" },
        onEvent = function(event)
            if event ~= "PLAYER_REGEN_ENABLED" then Map.Ensure(true) end
        end,
        tickSeconds = 0.5,
        texture = MEDIA .. "coordinates",
        text = function() return LocCoordText(Precision()) end,
        template = function() return COORD_TEMPLATE[Precision()] or COORD_TEMPLATE[0] end,
        collapse = function()
            if D().hideInInstance == false then return false end
            local inInstance, instanceType = IsInInstance()
            if not inInstance then return false end
            -- Battlegrounds and arenas keep a player map on Wrath; dungeons and raids report 0,0.
            return instanceType == "party" or instanceType == "raid"
        end,
    })
end
