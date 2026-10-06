-- EllesmereUIDataBars 3.3.5: Audio volume block factory (port of Retail Blocks\Audio.lua).
local _, ns = ...
if not ns.IsWrath then return end
local L = ns.L
local MEDIA = ns.MEDIA
local K = ns.BlockKit

-- Upvalues
local CreateFrame = CreateFrame
local ipairs      = ipairs
local tostring    = tostring
local floor       = math.floor
local max         = math.max
local Clamp       = ns.Clamp
local Size        = ns.Size

local ICON_GAP             = K.ICON_GAP
local CONTENT_BASE         = K.CONTENT_BASE
local InstKey              = K.InstKey
local MakeEventFrame       = K.MakeEventFrame
local RegisterInstEvents   = K.RegisterInstEvents
local UnregisterInstEvents = K.UnregisterInstEvents
local VSlotW               = K.VSlotW
local MaybeRelayout        = K.MaybeRelayout
local IconColorOf          = K.IconColorOf

-------------------------------------------------------------------------------
--  AUDIO (interactive volume bar; channel picked in block settings)
--  Volume rides the sound CVars, which are unprotected: reads and writes are combat-legal.
--  3.3.5 has no Dialog channel; a stored "dialog" choice falls back to Master.
-------------------------------------------------------------------------------
local AUDIO_CHANNELS = {
    master   = { cvar = "Sound_MasterVolume",   enable = "Sound_EnableAllSound", label = "AUDIO_MASTER" },
    sfx      = { cvar = "Sound_SFXVolume",      enable = "Sound_EnableSFX",      label = "AUDIO_SFX" },
    music    = { cvar = "Sound_MusicVolume",    enable = "Sound_EnableMusic",    label = "AUDIO_MUSIC" },
    ambience = { cvar = "Sound_AmbienceVolume", enable = "Sound_EnableAmbience", label = "AUDIO_AMBIENCE" },
}
local AUDIO_CHANNEL_ORDER = { "master", "sfx", "music", "ambience" }
ns.AUDIO_CHANNELS = AUDIO_CHANNELS
ns.AUDIO_CHANNEL_ORDER = AUDIO_CHANNEL_ORDER

-- A missing enable CVar reads as ON (same as a missing volume reads as full).
local function CVarOn(name)
    local v = GetCVar(name)
    return v == nil or v ~= "0"
end

ns.BlockFactories.audio = function(blockCfg, slot, content, barCtx)
    local inst = { cfg = blockCfg, slot = slot, content = content, ctx = barCtx }
    inst.key = InstKey(barCtx, blockCfg)
    inst.events = { "CVAR_UPDATE", "PLAYER_ENTERING_WORLD" }

    local AUDIO_TEX = MEDIA .. "audio"
    local mouseOver = false
    local dragging = false
    local lastSig

    local function D() return blockCfg.settings or {} end
    local function BC() return barCtx.cfg end

    local function Chan()
        return AUDIO_CHANNELS[D().channel] or AUDIO_CHANNELS.master
    end
    -- Channel volume 0..1. A missing CVar reads as full volume on every path (bar, rows, wheel).
    local function ReadVol(ch)
        return Clamp(tonumber(GetCVar(ch.cvar)) or 1, 0, 1)
    end
    local function GetVol() return ReadVol(Chan()) end
    -- Wheel step: 1%, or 10% with Shift. Rounds to whole percents so repeated steps never drift.
    local function WheelStep(v, delta)
        return floor((v + delta * (IsShiftKeyDown() and 0.10 or 0.01)) * 100 + 0.5) / 100
    end
    -- 3.3.5 SetCVar raises no CVAR_UPDATE for addon writes, so every writer repaints itself.
    local function Repaint() if not inst._dead then inst:Refresh() end end
    -- The one volume writer, clamped to 0..1.
    local function SetChanVol(ch, v)
        SetCVar(ch.cvar, tostring(Clamp(v, 0, 1)))
        Repaint()
    end
    local function SetVol(v) SetChanVol(Chan(), v) end

    local audioButton = CreateFrame("Button", nil, content)
    audioButton:SetAllPoints()
    audioButton:EnableMouse(true)
    audioButton:EnableMouseWheel(true)

    local audioIcon = audioButton:CreateTexture(nil, "OVERLAY")
    audioIcon:SetTexture(AUDIO_TEX)

    -- Volume bar: flat fill + dark track, same visual recipe as the profession skill bars.
    local volTrack = audioButton:CreateTexture(nil, "BACKGROUND")
    ns.Solid(volTrack, 0.15, 0.15, 0.15, 0.6)
    local volBar = CreateFrame("StatusBar", nil, audioButton)
    volBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    volBar:SetMinMaxValues(0, 1)

    -- Drag hit frame: covers the track plus 4px above/below; clicks on the icon never set the volume.
    local hit = CreateFrame("Button", nil, audioButton)
    hit:EnableMouse(true)

    local function SetFromCursor()
        local left = volTrack:GetLeft()
        local w = volTrack:GetWidth()
        if not left or not w or w <= 0 then return end
        local scale = volTrack:GetEffectiveScale()
        if not scale or scale == 0 then scale = 1 end
        local cx = GetCursorPosition() / scale
        SetVol((cx - left) / w)
    end

    hit:SetScript("OnMouseDown", function(_, btn)
        if btn ~= "LeftButton" then return end
        dragging = true
        SetFromCursor()
        -- OnUpdate lives only for the duration of the drag.
        hit:SetScript("OnUpdate", SetFromCursor)
    end)
    hit:SetScript("OnMouseUp", function()
        if not dragging then return end
        dragging = false
        hit:SetScript("OnUpdate", nil)
        inst:Refresh()
    end)

    audioButton:SetScript("OnMouseWheel", function(_, delta)
        SetVol(WheelStep(GetVol(), delta))
    end)

    local function ToggleMute(ch)
        SetCVar(ch.enable, CVarOn(ch.enable) and "0" or "1")
        Repaint()
    end

    -- Left-click off the bar (icon) toggles mute for the block's channel; the bar's hit frame keeps drag-to-set.
    audioButton:RegisterForClicks("LeftButtonUp")
    audioButton:SetScript("OnClick", function() ToggleMute(Chan()) end)

    -- Per-channel tooltip row handlers, built once: left-click toggles mute, wheel steps volume.
    local rowClick, rowWheel = {}, {}
    for _, key in ipairs(AUDIO_CHANNEL_ORDER) do
        local ch = AUDIO_CHANNELS[key]
        rowClick[key] = function(mouseButton)
            if mouseButton == "LeftButton" then ToggleMute(ch) end
        end
        rowWheel[key] = function(delta)
            SetChanVol(ch, WheelStep(ReadVol(ch), delta))
        end
    end

    local function AudioTooltip()
        ns.Tip_Begin(audioButton)
        ns.Tip_AddLine("|cFFFFFFFF[|r" .. L["AUDIO"] .. "|cFFFFFFFF]|r", 1, 1, 1)
        ns.Tip_AddLine(" ")
        local selected = Chan()
        -- Master off silences every other channel, so their rows dim; a muted channel keeps its red "Muted".
        local masterOn = CVarOn(AUDIO_CHANNELS.master.enable)
        for _, key in ipairs(AUDIO_CHANNEL_ORDER) do
            local ch = AUDIO_CHANNELS[key]
            local isSel = ch == selected
            local lc, vc = isSel and 1 or 0.65, 1
            if not masterOn and key ~= "master" then
                lc, vc = isSel and 0.55 or 0.35, 0.45
            end
            if CVarOn(ch.enable) then
                local pct = floor(ReadVol(ch) * 100 + 0.5)
                ns.Tip_AddClickable(L[ch.label], pct .. "%", rowClick[key], lc, lc, lc, vc, vc, vc)
            else
                ns.Tip_AddClickable(L[ch.label], L["AUDIO_MUTED"], rowClick[key], lc, lc, lc, 1, 0.3, 0.3)
            end
            ns.Tip_SetRowWheel(rowWheel[key])
        end
        ns.Tip_AddLine(" ")
        ns.Tip_AddDouble(L["LEFT_CLICK"], L["AUDIO_MUTE_HINT"], 1, 1, 1, 1, 1, 1)
        ns.Tip_AddDouble(L["DRAG_BAR"], L["AUDIO_SET_HINT"], 1, 1, 1, 1, 1, 1)
        ns.Tip_AddDouble(L["SCROLL_WHEEL"], L["AUDIO_SCROLL_HINT"], 1, 1, 1, 1, 1, 1)
        ns.Tip_AddLine(L["AUDIO_SHIFT_HINT"], 0.65, 0.65, 0.65)
        ns.Tip_Show()
    end

    local function OnEnter()
        mouseOver = true
        inst:Refresh()
        AudioTooltip()
    end
    local function OnLeave()
        mouseOver = false
        inst:Refresh()
        ns.Tip_HideUnlessInteractive(audioButton)
    end
    audioButton:SetScript("OnEnter", OnEnter)
    audioButton:SetScript("OnLeave", OnLeave)
    hit:SetScript("OnEnter", OnEnter)
    hit:SetScript("OnLeave", OnLeave)

    local function Signature()
        local ch = Chan()
        return tostring(GetCVar(ch.cvar)) .. "|" .. tostring(GetCVar(ch.enable)) .. "|"
            .. tostring(GetCVar(AUDIO_CHANNELS.master.enable))
    end

    function inst:Refresh()
        local barH = barCtx.GetThickness()
        local fontSize = max(9, floor(CONTENT_BASE * 0.4333 + 0.5))
        local isSide = barCtx.IsVertical()
        local iconSz = fontSize + 4
        local barW = max(40, floor(CONTENT_BASE * 2 + 0.5))
        local bH = 5
        lastSig = Signature()

        -- Show Icon (default ON): hidden drops the icon and its gap entirely.
        local showIcon = D().showIcon ~= false
        if showIcon then audioIcon:Show() else audioIcon:Hide(); iconSz = 0 end

        -- Icon color follows the Icon Color row; hover sweeps to accent. Muted (channel or master) paints icon and fill red.
        local ar, ag, ab = ns.GetAccent()
        if not (CVarOn(Chan().enable) and CVarOn(AUDIO_CHANNELS.master.enable)) then
            audioIcon:SetVertexColor(1, 0.3, 0.3, 1)
            ar, ag, ab = 1, 0.3, 0.3
        elseif mouseOver then
            audioIcon:SetVertexColor(ar, ag, ab, 1)
        else
            local ir, ig, ib = IconColorOf(blockCfg)
            audioIcon:SetVertexColor(ir, ig, ib, 1)
        end
        -- Accent fill, like the profession bars.
        volBar:SetStatusBarColor(ar, ag, ab, 1)
        volBar:SetValue(GetVol())

        if showIcon then Size(audioIcon, iconSz, iconSz) end
        local effGap = showIcon and ICON_GAP or 0
        if isSide then
            local slotW = VSlotW(inst)
            local innerW = max(30, slotW - 8)
            audioIcon:ClearAllPoints()
            audioIcon:SetPoint("TOP", audioButton, "TOP", 0, -4)
            volTrack:ClearAllPoints()
            Size(volTrack, innerW, bH)
            if showIcon then
                volTrack:SetPoint("TOP", audioIcon, "BOTTOM", 0, -4)
            else
                volTrack:SetPoint("TOP", audioButton, "TOP", 0, -6)
            end
            Size(content, slotW, max(4 + iconSz + 4 + bH + 4, 40))
        else
            audioIcon:ClearAllPoints()
            audioIcon:SetPoint("LEFT", audioButton, "LEFT", 0, 0)
            volTrack:ClearAllPoints()
            Size(volTrack, barW, bH)
            volTrack:SetPoint("LEFT", audioButton, "LEFT", iconSz + effGap, 0)
            Size(content, iconSz + effGap + barW, barH)
        end
        volBar:ClearAllPoints()
        volBar:SetAllPoints(volTrack)
        hit:ClearAllPoints()
        hit:SetPoint("TOPLEFT", volTrack, "TOPLEFT", 0, 4)
        hit:SetPoint("BOTTOMRIGHT", volTrack, "BOTTOMRIGHT", 0, -4)
        audioButton:ClearAllPoints()
        audioButton:SetAllPoints(content)

        -- Owned, not mouseOver: the tip must also repaint while the cursor sits on its rows.
        if ns.Tip_IsOwned(audioButton) and not dragging then AudioTooltip() end
        MaybeRelayout(inst)
    end

    -- Blizzard's sound panel and the Toggle Sound binding write the CVars without telling us: poll a cheap signature.
    local function Tick()
        if dragging then return end
        if Signature() ~= lastSig then inst:Refresh() end
    end

    inst.eventFrame = MakeEventFrame(inst, function(self)
        self:Refresh()
    end)

    function inst:Enable()
        content:Show()
        RegisterInstEvents(self)
        ns.RegisterHeartbeat("audio:" .. self.key, Tick)
    end

    function inst:Disable()
        ns.UnregisterHeartbeat("audio:" .. self.key)
        UnregisterInstEvents(self)
        content:Hide()
    end

    function inst:GetAutoLength()
        local fontSize = max(9, floor(CONTENT_BASE * 0.4333 + 0.5))
        if barCtx.IsVertical() then
            return max(content:GetHeight() or 40, 40)
        end
        local iconPart = 0
        if D().showIcon ~= false then iconPart = (fontSize + 4) + ICON_GAP end
        return iconPart + max(40, floor(CONTENT_BASE * 2 + 0.5))
    end

    function inst:Destroy()
        self._dead = true
        ns.UnregisterHeartbeat("audio:" .. self.key)
        UnregisterInstEvents(self)
        content:Hide()
    end

    inst:Refresh()
    return inst
end
