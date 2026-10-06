-------------------------------------------------------------------------------
--  EllesmereUI_PartyMode_335.lua
--  Wrath port of EllesmereUI_PartyMode.lua: full-screen disco spotlight
--  overlay, celebration triggers and the Party Mode spin engine.
--
--  3.3.5 cannot rotate a quad, so each beam is one large square whose texture
--  coordinates are rotated (8-point SetTexCoord). Its texture bakes the three
--  Retail layers (wide dim outer, medium mid, narrow bright core) into one
--  additive profile; see backport-tools/prepare_core_media.py.
--  Wrath triggers: Randomly, Level Up, Bloodlust/Heroism (Sated and
--  Exhaustion), heroic and normal dungeon/raid boss kills (DBM kill callback,
--  else boss units dying), battleground wins and rated arena wins. Keystones,
--  Mythic, Raid Finder and Mythic 0 do not exist on Wrath.
--  Dim the Lights uses the contrast/brightness CVars when the client has
--  them, else gamma.
--
--  Performance:
--    • Zero CPU when disabled — container hidden, OnUpdate doesn't fire.
--    • OnUpdate throttled to ~30fps.
--    • Screen dimensions cached; refreshed on resize.
--
--  Shared across all EllesmereUI addons — only the first to load runs.
-------------------------------------------------------------------------------
if _G._EllesmereUIPartyModeLoaded then return end
_G._EllesmereUIPartyModeLoaded = true

local ADDON_NAME = ...
local GRADIENT_TEX = "Interface\\AddOns\\EllesmereUI\\media\\backgrounds_335\\party_beam.tga"
-- Baked profile: peak of the summed layer alphas, and texture width over
-- the profile's width (2048 / 64).
local BEAM_PEAK = 1.1
local BEAM_SPAN = 32

local BASE_OVERLAY_ALPHA = 0.30
local function OVERLAY_ALPHA()
    local db = EllesmereUIDB
    local bri = db and db.partyModeBrightness
    if bri == nil then bri = 0.65 end
    return BASE_OVERLAY_ALPHA * (bri / 0.65)
end
local HUE_CYCLE_SPEED  = 0.06
local GLOBAL_HUE_SHIFT = 0.03
local SATURATION       = 0.85
local BRIGHTNESS       = 0.85
local THROTTLE         = 0.033

local math_floor  = math.floor
local math_sin    = math.sin
local math_random = math.random
local math_pi     = math.pi
local math_rad    = math.rad

-------------------------------------------------------------------------------
--  Keybind registration (pure Lua — no Bindings.xml needed)
--  Uses a hidden button + SetOverrideBindingClick. Only the first addon
--  to load creates the button; subsequent addons skip if it already exists.
--  The bound key is saved in EllesmereUIDB.partyModeKey (nil = unbound).
-------------------------------------------------------------------------------
if not _G["EllesmereUIPartyModeBindBtn"] then
    local btn = CreateFrame("Button", "EllesmereUIPartyModeBindBtn", UIParent)
    btn:Hide()
    btn:SetScript("OnClick", function()
        EllesmereUI_TogglePartyMode()
    end)
end

-------------------------------------------------------------------------------
--  Celebration / dim-lights state
-------------------------------------------------------------------------------
local celebrationTimer = nil
local randomTimer = nil
local randomScheduledTimer = nil
local randomCooldownTimer = nil
local dimLightsActive = false
local savedContrast = nil
local savedBrightness = nil
local savedGamma = nil

local function ReadCVar(name)
    local ok, v = pcall(GetCVar, name)
    return ok and tonumber(v) or nil
end

-------------------------------------------------------------------------------
--  Dim lights helpers (for live toggle from options)
-------------------------------------------------------------------------------
function EllesmereUI_IsDimLightsActive()
    return dimLightsActive
end

function EllesmereUI_ApplyDimLights()
    if dimLightsActive then return end
    savedContrast = ReadCVar("contrast")
    savedBrightness = ReadCVar("brightness")
    if savedContrast and savedBrightness then
        SetCVar("contrast", math.max(0, math.min(100, savedContrast + 14)))
        SetCVar("brightness", math.max(0, savedBrightness - (savedBrightness - 10) * 0.7))
    else
        savedContrast, savedBrightness = nil, nil
        savedGamma = ReadCVar("gamma")
        if not savedGamma then return end
        SetCVar("gamma", math.max(0.5, savedGamma * 0.7))
    end
    dimLightsActive = true
end

function EllesmereUI_RestoreDimLights()
    if not dimLightsActive then return end
    if savedContrast then
        SetCVar("contrast", savedContrast)
        SetCVar("brightness", savedBrightness)
    elseif savedGamma then
        SetCVar("gamma", savedGamma)
    end
    savedContrast, savedBrightness, savedGamma = nil, nil, nil
    dimLightsActive = false
end

-------------------------------------------------------------------------------
--  Beam definitions — 12 beams
--  Each beam gets 3 layers: wide outer glow, medium mid, narrow core
--  This creates the cone/spotlight spread effect
--
--  originX: horizontal origin (fraction of screen, 0=center)
--  baseAngle: resting angle degrees (neg=lean left, pos=lean right)
--  sweepDeg: oscillation range in degrees
--  sweepSpeed: oscillation speed (rad/s)
--  width: base width as fraction of screen (core layer uses this,
--         mid layer 2.5x, outer layer 5x)
--  brightness, hue, phaseOff: visual tuning
-------------------------------------------------------------------------------
local BEAM_DEFS = {
    -- Far left edge — steep inward angle
    { originX=-0.65, baseAngle=-60, sweepDeg=20, sweepSpeed=1.6, width=0.10, brightness=0.90, hue=0.00, phaseOff=0.0 },
    -- Left — moderate inward
    { originX=-0.40, baseAngle=-35, sweepDeg=22, sweepSpeed=2.0, width=0.10, brightness=0.85, hue=0.12, phaseOff=1.8 },
    -- Left-center
    { originX=-0.20, baseAngle=-18, sweepDeg=18, sweepSpeed=1.8, width=0.10, brightness=0.90, hue=0.25, phaseOff=3.5 },
    -- Center-left
    { originX=-0.05, baseAngle=-5,  sweepDeg=15, sweepSpeed=2.2, width=0.10, brightness=1.00, hue=0.38, phaseOff=5.2 },
    -- Center
    { originX= 0.05, baseAngle= 5,  sweepDeg=15, sweepSpeed=1.7, width=0.10, brightness=0.95, hue=0.50, phaseOff=0.7 },
    -- Center-right
    { originX= 0.15, baseAngle= 12, sweepDeg=18, sweepSpeed=2.1, width=0.10, brightness=0.90, hue=0.62, phaseOff=2.4 },
    -- Right-center
    { originX= 0.25, baseAngle= 20, sweepDeg=20, sweepSpeed=1.9, width=0.10, brightness=0.85, hue=0.72, phaseOff=4.1 },
    -- Right
    { originX= 0.40, baseAngle= 35, sweepDeg=22, sweepSpeed=2.3, width=0.10, brightness=0.85, hue=0.82, phaseOff=5.8 },
    -- Far right edge — steep inward angle
    { originX= 0.65, baseAngle= 60, sweepDeg=20, sweepSpeed=1.6, width=0.10, brightness=0.90, hue=0.92, phaseOff=1.3 },
    -- Extra center fill
    { originX=-0.10, baseAngle=-10, sweepDeg=16, sweepSpeed=2.4, width=0.10, brightness=0.80, hue=0.45, phaseOff=3.0 },
    -- Far top-left gap filler — steep inward
    { originX=-0.50, baseAngle=-48, sweepDeg=18, sweepSpeed=1.8, width=0.10, brightness=0.88, hue=0.06, phaseOff=4.6 },
    -- Far top-right gap filler — steep inward
    { originX= 0.50, baseAngle= 48, sweepDeg=18, sweepSpeed=1.8, width=0.10, brightness=0.88, hue=0.88, phaseOff=2.0 },
}
local NUM_BEAMS = #BEAM_DEFS

local function HSVtoRGB(h, s, v)
    h = h % 1
    local i = math_floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    local rem = i % 6
    if     rem == 0 then return v, t, p
    elseif rem == 1 then return q, v, p
    elseif rem == 2 then return p, v, t
    elseif rem == 3 then return p, q, v
    elseif rem == 4 then return t, p, v
    else                 return v, p, q end
end

-------------------------------------------------------------------------------
--  State
-------------------------------------------------------------------------------
local container, beams, globalHueOffset, accumulator, globalTime
local cachedSW, cachedSH, squareD

local math_cos = math.cos
local ORIGIN_Y = 600   -- beam pivot above the screen top, as Retail

-- Square side that covers the whole screen from any beam pivot.
local function MeasureScreen()
    cachedSW = GetScreenWidth()
    cachedSH = GetScreenHeight()
    squareD = 2 * math.max(cachedSW * 1.2, cachedSH + ORIGIN_Y + 50)
end

-- Rotates the beam profile by rot (counter-clockwise, radians) inside its
-- square: u runs across the beam (texture width = BEAM_SPAN outer widths),
-- v along it. Corners in SetTexCoord order UL, LL, UR, LR (y up).
local function SetBeamCoords(tex, rot, outerW)
    local c, s = math_cos(rot), math_sin(rot)
    local h = squareD / 2
    local wTex = outerW * BEAM_SPAN
    local function U(x, y) return 0.5 + (x * c + y * s) / wTex end
    local function V(x, y) return 0.5 - (y * c - x * s) / squareD end
    tex:SetTexCoord(U(-h, h), V(-h, h), U(-h, -h), V(-h, -h),
                    U(h, h), V(h, h), U(h, -h), V(h, -h))
end

local function CreateOverlay()
    if container then return end
    container = CreateFrame("Frame", "EllesmereUIPartyModeFrame", UIParent)
    container:SetFrameStrata("TOOLTIP")
    container:SetFrameLevel(250)
    container:SetAllPoints(UIParent)
    container:EnableMouse(false)
    container:Hide()

    beams = {}
    globalHueOffset = 0
    globalTime = 0
    accumulator = 0

    MeasureScreen()

    for i = 1, NUM_BEAMS do
        local def = BEAM_DEFS[i]
        local tex = container:CreateTexture(nil, "ARTWORK")
        tex:SetTexture(GRADIENT_TEX)
        tex:SetBlendMode("ADD")
        beams[i] = {
            def = def,
            tex = tex,
            bri = BRIGHTNESS * (def.brightness or 0.8),
            hueOffset = 0,
            sweepPhase = def.phaseOff or (math_random() * math_pi * 2),
        }
    end

    container:RegisterEvent("DISPLAY_SIZE_CHANGED")
    container:SetScript("OnEvent", MeasureScreen)

    container:SetScript("OnUpdate", function(self, elapsed)
        if elapsed > 0.1 then elapsed = 0.1 end
        accumulator = accumulator + elapsed
        if accumulator < THROTTLE then return end
        local dt = accumulator
        accumulator = 0

        globalTime = globalTime + dt
        globalHueOffset = globalHueOffset + GLOBAL_HUE_SHIFT * dt
        local alpha = math.min(1, OVERLAY_ALPHA() * BEAM_PEAK)

        for i = 1, NUM_BEAMS do
            local beam = beams[i]
            local def = beam.def

            beam.sweepPhase = beam.sweepPhase + def.sweepSpeed * dt
            local currentAngle = def.baseAngle + math_sin(beam.sweepPhase) * (def.sweepDeg or 20)
            local rotRad = math_rad(-currentAngle)

            beam.hueOffset = beam.hueOffset + HUE_CYCLE_SPEED * dt
            local r, g, b = HSVtoRGB((def.hue + beam.hueOffset + globalHueOffset) % 1, SATURATION, beam.bri)

            local tex = beam.tex
            tex:ClearAllPoints()
            tex:SetWidth(squareD)
            tex:SetHeight(squareD)
            tex:SetPoint("CENTER", container, "TOP", def.originX * cachedSW, ORIGIN_Y)
            SetBeamCoords(tex, rotRad, cachedSW * def.width * 5)
            tex:SetVertexColor(r, g, b, alpha)
        end
    end)
end

-------------------------------------------------------------------------------
--  Activation sound catalogue
--  Same built-in files as the chat whisper alert, plus LibSharedMedia
--  sounds. Built lazily on first request (options page open or first
--  activation): both happen well after login, so sound packs other addons
--  register with SharedMedia at their own load time are all present.
-------------------------------------------------------------------------------
local _soundPaths, _soundNames, _soundOrder
local function GetSoundTables()
    if not _soundPaths then
        local EUI = _G.EllesmereUI
        _soundPaths, _soundNames, _soundOrder = EUI.BuildAlertSoundTables()
        EUI.AppendSharedMediaSounds(_soundPaths, _soundNames, _soundOrder)
    end
    return _soundPaths, _soundNames, _soundOrder
end

-- Options page reads the catalogue through this accessor.
function EllesmereUI_GetPartyModeSounds()
    return GetSoundTables()
end

-------------------------------------------------------------------------------
--  Global API
-------------------------------------------------------------------------------
function EllesmereUI_StartPartyMode()
    CreateOverlay()
    -- Activation sound: only on the actual off->on edge, so re-entrant
    -- Start calls while the overlay is already visible stay silent.
    if not container:IsShown() then
        local key = EllesmereUIDB and EllesmereUIDB.partyModeSoundKey
        if key and key ~= "none" then
            local paths, EUI = GetSoundTables(), _G.EllesmereUI
            local path = EUI.ResolveSoundPath and EUI.ResolveSoundPath(paths, key) or paths[key]
            if path then PlaySoundFile(path, "Master") end
        end
    end
    container:Show()
    -- Dim the lights if enabled (defaults to on)
    if EllesmereUIDB and (EllesmereUIDB.partyModeDimLights ~= false) then
        EllesmereUI_ApplyDimLights()
    end
    -- Party Mode visibility lanes (Visibility > Party Mode) have no game event.
    if EllesmereUI.FireVisEdge then EllesmereUI.FireVisEdge() end
end

function EllesmereUI_StopPartyMode()
    if container then container:Hide() end
    EllesmereUI_RestoreDimLights()
    if EllesmereUI.FireVisEdge then EllesmereUI.FireVisEdge() end
end

-------------------------------------------------------------------------------
--  Keybind toggle function
-------------------------------------------------------------------------------
function EllesmereUI_TogglePartyMode()
    if not EllesmereUIDB then EllesmereUIDB = {} end
    if EllesmereUIDB.partyMode then
        EllesmereUIDB.partyMode = false
        EllesmereUI_StopPartyMode()
    else
        EllesmereUIDB.partyMode = true
        EllesmereUI_StartPartyMode()
    end
end

-------------------------------------------------------------------------------
--  Random trigger helpers
--  New behavior: pick a random time within a 15-minute window, fire once,
--  then 10-minute cooldown, then new 15-minute window.
-------------------------------------------------------------------------------
local RANDOM_WINDOW = 900   -- 15 minutes in seconds

local function GetRandomCooldown()
    return ((EllesmereUIDB and EllesmereUIDB.partyModeRandomCooldown) or 10) * 60
end

local function ScheduleRandomActivation()
    if randomScheduledTimer then return end
    local delay = math_random(0, RANDOM_WINDOW)
    randomScheduledTimer = C_Timer.NewTimer(delay, function()
        randomScheduledTimer = nil
        if not (EllesmereUIDB and EllesmereUIDB.partyModeTriggerRandom) then return end
        if EllesmereUIDB.partyMode then
            -- Already active, try again after cooldown
            randomCooldownTimer = C_Timer.NewTimer(GetRandomCooldown(), function()
                randomCooldownTimer = nil
                ScheduleRandomActivation()
            end)
            return
        end
        EllesmereUIDB.partyMode = true
        EllesmereUI_StartPartyMode()
        if celebrationTimer then celebrationTimer:Cancel() end
        local duration = (EllesmereUIDB and EllesmereUIDB.partyModeMPlusDuration) or 30
        celebrationTimer = C_Timer.NewTimer(duration, function()
            celebrationTimer = nil
            if EllesmereUIDB then EllesmereUIDB.partyMode = false end
            EllesmereUI_StopPartyMode()
            -- Start cooldown, then schedule next random window
            randomCooldownTimer = C_Timer.NewTimer(GetRandomCooldown(), function()
                randomCooldownTimer = nil
                ScheduleRandomActivation()
            end)
        end)
    end)
end

function EllesmereUI_StartRandomTrigger()
    if randomTimer or randomScheduledTimer or randomCooldownTimer then return end
    ScheduleRandomActivation()
end

function EllesmereUI_StopRandomTrigger()
    if randomTimer then randomTimer:Cancel(); randomTimer = nil end
    if randomScheduledTimer then randomScheduledTimer:Cancel(); randomScheduledTimer = nil end
    if randomCooldownTimer then randomCooldownTimer:Cancel(); randomCooldownTimer = nil end
end

-------------------------------------------------------------------------------
--  Pause random trigger while EUI settings panel is open
-------------------------------------------------------------------------------
local function OnSettingsOpen()
    -- Cancel any pending random activation / cooldown
    EllesmereUI_StopRandomTrigger()
    -- If party mode is running from a celebration timer (auto-triggered), stop it
    if celebrationTimer then
        celebrationTimer:Cancel()
        celebrationTimer = nil
        if EllesmereUIDB then EllesmereUIDB.partyMode = false end
        EllesmereUI_StopPartyMode()
    end
end

local function OnSettingsClose()
    -- Resume random trigger if enabled
    if EllesmereUIDB and EllesmereUIDB.partyModeTriggerRandom then
        EllesmereUI_StartRandomTrigger()
    end
end

EllesmereUI:RegisterOnShow(OnSettingsOpen)
EllesmereUI:RegisterOnHide(OnSettingsClose)

-------------------------------------------------------------------------------
--  Init frame — handles PLAYER_LOGIN, events, PLAYER_LOGOUT
-------------------------------------------------------------------------------
local function Celebrate(duration)
    EllesmereUIDB.partyMode = true
    EllesmereUI_StartPartyMode()
    if celebrationTimer then celebrationTimer:Cancel() end
    celebrationTimer = C_Timer.NewTimer(duration, function()
        celebrationTimer = nil
        if EllesmereUIDB then EllesmereUIDB.partyMode = false end
        EllesmereUI_StopPartyMode()
    end)
end

local function AutoDuration()
    return (EllesmereUIDB and EllesmereUIDB.partyModeMPlusDuration) or 30
end

-- Bloodlust celebration trigger: the player's Sated (Bloodlust) or Exhaustion
-- (Heroism) debuff appears the instant lust goes out. Hardcoded 40s
-- celebration -- it deliberately ignores the Auto Celebration Duration slider.
local PM_SATED_DEBUFFS = { [57723] = true, [57724] = true }
local _pmSatedPresent = false
local function _pmPlayerHasSated()
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, _, spellId = UnitDebuff("player", i)
        if not name then return false end
        if PM_SATED_DEBUFFS[spellId] then return true end
    end
    return false
end

local pmInit = CreateFrame("Frame")
pmInit:RegisterEvent("PLAYER_LOGIN")
pmInit:RegisterEvent("PLAYER_LOGOUT")

-- UNIT_AURA is registered only while the Bloodlust trigger is on (it is
-- high-frequency); 3.3.5 has no unit filter, so the handler drops other units.
function EllesmereUI_UpdatePartyModeLustListener()
    if EllesmereUIDB and EllesmereUIDB.partyModeTriggerBloodlust then
        _pmSatedPresent = _pmPlayerHasSated()  -- baseline so only NEW edges fire
        pmInit:RegisterEvent("UNIT_AURA")
    else
        pmInit:UnregisterEvent("UNIT_AURA")
    end
end

function EllesmereUI_UpdatePartyModeLevelUpListener()
    if EllesmereUIDB and EllesmereUIDB.partyModeTriggerLevelUp then
        pmInit:RegisterEvent("PLAYER_LEVEL_UP")
    else
        pmInit:UnregisterEvent("PLAYER_LEVEL_UP")
    end
end

-------------------------------------------------------------------------------
--  Boss kills. The trigger key follows the instance difficulty: heroic
--  dungeons and heroic raids (incl. a dynamic heroic toggle) are Heroic,
--  every other dungeon or raid is Normal. With DBM loaded its kill callback
--  decides; otherwise the boss units seen engaged must all die (combat log),
--  listened to only while an encounter is engaged.
-------------------------------------------------------------------------------
local function BossKillKey()
    local _, instanceType, difficulty, _, _, dynamicDifficulty, isDynamic = GetInstanceInfo()
    if instanceType ~= "party" and instanceType ~= "raid" then return nil end
    local heroic
    if instanceType == "party" then
        heroic = difficulty == 2
    else
        heroic = (difficulty or 0) >= 3 or (isDynamic and dynamicDifficulty == 1) or false
    end
    return heroic and "partyModeTriggerHeroicBoss" or "partyModeTriggerNormalBoss"
end

local lastBossKill = 0
local function OnBossKill()
    local now = GetTime()
    if now - lastBossKill < 10 then return end
    lastBossKill = now
    local key = BossKillKey()
    if key and EllesmereUIDB and EllesmereUIDB[key] then Celebrate(AutoDuration()) end
end

local bossGUIDs, bossCount = {}, 0
local function TrackBossUnits()
    for i = 1, 4 do
        local guid = UnitGUID("boss" .. i)
        if guid and not bossGUIDs[guid] and not UnitIsDead("boss" .. i) then
            bossGUIDs[guid] = true
            bossCount = bossCount + 1
        end
    end
    if bossCount > 0 then
        pmInit:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        pmInit:RegisterEvent("PLAYER_REGEN_ENABLED")
    end
end

local function ResetBossUnits()
    wipe(bossGUIDs)
    bossCount = 0
    pmInit:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    pmInit:UnregisterEvent("PLAYER_REGEN_ENABLED")
end

local dbmHooked = false
local function HookDBM()
    if dbmHooked or not (DBM and DBM.RegisterCallback) then return dbmHooked end
    local ok = pcall(DBM.RegisterCallback, DBM, "DBM_Kill", function() OnBossKill() end)
    dbmHooked = ok
    if ok then
        pmInit:UnregisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
        ResetBossUnits()
    end
    return ok
end

-------------------------------------------------------------------------------
--  Battleground and arena wins. GetBattlefieldWinner reports 0 (Horde /
--  green team) or 1 (Alliance / gold team) once a match ends; one
--  celebration per match. Arenas count only when rated (registered).
-------------------------------------------------------------------------------
local pvpCelebrated = false
local function CheckBattlefieldWin()
    local winner = GetBattlefieldWinner and GetBattlefieldWinner()
    if winner == nil then pvpCelebrated = false; return end
    if pvpCelebrated or not EllesmereUIDB then return end
    pvpCelebrated = true
    local isArena, isRated = false, false
    if IsActiveBattlefieldArena then isArena, isRated = IsActiveBattlefieldArena() end
    local mine
    if isArena then
        mine = GetBattlefieldArenaFaction and GetBattlefieldArenaFaction()
        if not (isRated and EllesmereUIDB.partyModeTriggerRatedArena) then return end
    else
        mine = (UnitFactionGroup("player") == "Alliance") and 1 or 0
        if not EllesmereUIDB.partyModeTriggerRatedBG then return end
    end
    if mine ~= winner then return end
    Celebrate(AutoDuration())
end

pmInit:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        -- Restore saved keybind for party mode toggle
        if EllesmereUIDB and EllesmereUIDB.partyModeKey then
            SetOverrideBindingClick(EllesmereUIPartyModeBindBtn, true, EllesmereUIDB.partyModeKey, "EllesmereUIPartyModeBindBtn")
        end
        -- Start party mode if saved on
        if EllesmereUIDB and EllesmereUIDB.partyMode then
            EllesmereUI_StartPartyMode()
        end
        self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
        self:RegisterEvent("ADDON_LOADED")
        if not HookDBM() then self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT") end
        if EllesmereUIDB and EllesmereUIDB.partyModeTriggerRandom then
            EllesmereUI_StartRandomTrigger()
        end
        EllesmereUI_UpdatePartyModeLustListener()
        EllesmereUI_UpdatePartyModeLevelUpListener()

    elseif event == "ADDON_LOADED" then
        if HookDBM() then self:UnregisterEvent("ADDON_LOADED") end

    elseif event == "UNIT_AURA" then
        if (...) ~= "player" then return end
        if not (EllesmereUIDB and EllesmereUIDB.partyModeTriggerBloodlust) then return end
        local present = _pmPlayerHasSated()
        if present and not _pmSatedPresent then
            -- Rising edge: lust just went out. Hardcoded 40s (NOT the slider).
            Celebrate(40)
        end
        _pmSatedPresent = present

    elseif event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
        if not dbmHooked then TrackBossUnits() end

    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, _, _, destGUID = ...
        if subEvent == "UNIT_DIED" and bossGUIDs[destGUID] then
            bossGUIDs[destGUID] = nil
            bossCount = bossCount - 1
            if bossCount <= 0 then
                ResetBossUnits()
                OnBossKill()
            end
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Combat over with tracked bosses still standing: a wipe or a reset.
        -- A dead player keeps tracking, so the group's kill still counts.
        if not UnitIsDeadOrGhost("player") then ResetBossUnits() end

    elseif event == "UPDATE_BATTLEFIELD_STATUS" then
        CheckBattlefieldWin()

    elseif event == "PLAYER_LEVEL_UP" then
        if not (EllesmereUIDB and EllesmereUIDB.partyModeTriggerLevelUp) then return end
        Celebrate(AutoDuration())

    elseif event == "PLAYER_LOGOUT" then
        -- An automatic celebration only lives as long as its timer, so never save
        -- it as on: the next login would start Party Mode with nothing to stop it.
        -- A session the user turned on by hand has no timer and stays saved.
        if celebrationTimer and EllesmereUIDB then EllesmereUIDB.partyMode = false end
        EllesmereUI_RestoreDimLights()
    end
end)

-------------------------------------------------------------------------------
--  Party Mode spin engine. EllesmereUI.PartySpin_Create(opts) -> refresh()
--  opts: target (one key of the Spinning setting, read through
--  EllesmereUI.PartySpinOn; every target turns at partyModeSpinSpeed, deg/s,
--  default 120), collect() -> { { pivot = frame, frames = {...} }, ... }
--  (runs about once a second while spinning, so it reuses its tables), and
--  optional onClaim() (idempotent, same cadence) and onRestore().
--  EllesmereUI.PartySpin_RefreshAll() re-applies every engine.
--  A SetPoint post-hook marks a member dirty when its module re-anchors it.
--  Pauses in combat and while Unlock Mode is open (members go home to drag).
-------------------------------------------------------------------------------
do
local SPIN_TARGETS = { "actionBars", "dataBars", "unitFrames", "resource", "power" }

-- EllesmereUIDB.partyModeSpinBars: nil / false = nothing spins, true = Action
-- Bars only, a table = one boolean per target. Every reader comes through
-- here: a plain truthiness test would take a table for "on". settingOnly
-- skips the Party Mode check (the options checkmarks).
local function SpinOn(target, settingOnly)
    local db = EllesmereUIDB
    if not (db and (settingOnly or db.partyMode)) then return false end
    local v = db.partyModeSpinBars
    if type(v) == "table" then return v[target] == true end
    return v == true and target == "actionBars"
end
EllesmereUI.PartySpinOn = SpinOn

-- The options writer: a boolean store becomes the per-target table on its
-- first write, keeping its Action Bars meaning.
function EllesmereUI.PartySpinSet(target, on)
    local db = EllesmereUIDB
    if not db then return end
    local v = db.partyModeSpinBars
    if type(v) ~= "table" then
        local ab = (v == true)
        v = {}
        for i = 1, #SPIN_TARGETS do v[SPIN_TARGETS[i]] = false end
        v.actionBars = ab
        db.partyModeSpinBars = v
    end
    v[target] = on and true or false
end

local function Speed()
    local v = EllesmereUIDB and EllesmereUIDB.partyModeSpinSpeed
    if v == nil then v = 120 end
    return v
end

-- Per-frame records live here, never on the frame: some members are
-- Blizzard-owned (stance and pet buttons). A record outlives its membership,
-- so a re-claim reuses its tables and the one SetPoint hook.
local recOf = setmetatable({}, { __mode = "k" })
local guardDepth = 0
local refreshers = {}
local EMPTY = {}

local function OnMemberSetPoint(self)
    if guardDepth > 0 then return end
    local r = recOf[self]
    if r then r.dirty = true end
end

local function Measure(f, rec)
    local pts, n = rec.points, 0
    for i = 1, f:GetNumPoints() do
        local a, rel, b, x, y = f:GetPoint(i)
        -- Skip our own orbit point if the module anchored without clearing it.
        if not (rec.ox and a == "CENTER" and rel == UIParent and b == "BOTTOMLEFT"
                and x == rec.ox and y == rec.oy) then
            n = n + 1
            local p = pts[n]
            if not p then p = {}; pts[n] = p end
            p[1], p[2], p[3], p[4], p[5] = a, rel, b, x, y
        end
    end
    for i = n + 1, #pts do pts[i] = nil end
    rec.n = n
    -- A member sized by two or more anchors (SetAllPoints) loses its size
    -- under a single orbit point, so its rest size is carried explicitly.
    rec.multi = n > 1
    rec.w, rec.h = f:GetWidth(), f:GetHeight()
    local cx, cy = f:GetCenter()
    local px, py = rec.pivot:GetCenter()
    if not (cx and px) then rec.dx = nil; return end
    local fs, ps = f:GetEffectiveScale(), rec.pivot:GetEffectiveScale()
    rec.dx, rec.dy = cx * fs - px * ps, cy * fs - py * ps
    rec.dirty = false
end

-- Back onto the captured rest anchors. A member its module re-anchored since
-- the last tick is re-measured first, so that newer anchor is the one kept.
local function Restore(f, rec)
    if rec.dirty then Measure(f, rec) end
    local n = rec.n or 0
    if n == 0 then return end
    guardDepth = guardDepth + 1
    f:ClearAllPoints()
    local pts = rec.points
    for i = 1, n do
        local p = pts[i]
        f:SetPoint(p[1], p[2], p[3], p[4], p[5])
    end
    guardDepth = guardDepth - 1
    rec.ox, rec.oy = nil, nil
end

local function RefreshAll()
    for i = 1, #refreshers do refreshers[i]() end
end
EllesmereUI.PartySpin_RefreshAll = RefreshAll

-- Targets whose module created an engine this session. Several Wrath modules
-- run their own builds without one, so the options list only these.
local liveTargets = {}
function EllesmereUI.PartySpinHasTarget(target)
    return liveTargets[target] == true
end

function EllesmereUI.PartySpin_Create(opts)
    local target = opts.target
    liveTargets[target] = true
    local driver
    local angle, held, since, claimed = 0, false, 0, false
    local members = {}     -- frame -> its recOf record
    local order = {}       -- array of frames (stable iteration)
    local seen = {}        -- Claim scratch, wiped after each pass

    local function On() return SpinOn(target) end

    local function RestoreAll()
        for i = 1, #order do
            local f = order[i]
            Restore(f, members[f])
        end
        wipe(members); wipe(order)
        claimed = false
        if opts.onRestore then opts.onRestore() end
    end

    local function Claim()
        claimed = true
        local groups = opts.collect() or EMPTY
        for g = 1, #groups do
            local grp = groups[g]
            local pivot, list = grp.pivot, grp.frames
            if pivot and list then
                for i = 1, #list do
                    local f = list[i]
                    if f and f.GetCenter and not seen[f] then
                        seen[f] = true
                        if not members[f] then
                            local rec = recOf[f]
                            if not rec then
                                rec = { points = {} }
                                recOf[f] = rec
                                hooksecurefunc(f, "SetPoint", OnMemberSetPoint)
                            end
                            rec.pivot = pivot
                            members[f] = rec
                            order[#order + 1] = f
                            Measure(f, rec)
                        end
                    end
                end
            end
        end
        -- Members that left the collection (block removed, frame gone) go home.
        for i = #order, 1, -1 do
            local f = order[i]
            if not seen[f] then
                Restore(f, members[f])
                members[f] = nil
                table.remove(order, i)
            end
        end
        wipe(seen)
        if opts.onClaim then opts.onClaim() end
    end

    local function Tick(c, s)
        guardDepth = guardDepth + 1
        -- Members come grouped by pivot, so each pivot is read once a tick.
        local lastPivot, px, py, ps
        for i = 1, #order do
            local f = order[i]
            local rec = members[f]
            -- The module just re-anchored it: that IS rest.
            if rec.dirty or not rec.dx then Measure(f, rec) end
            local pivot = rec.pivot
            if pivot ~= lastPivot then
                lastPivot = pivot
                px, py = pivot:GetCenter()
                ps = pivot:GetEffectiveScale()
            end
            if rec.dx and px then
                local fs = f:GetEffectiveScale()
                if fs and fs > 0 then
                    local x = px * ps + rec.dx * c - rec.dy * s
                    local y = py * ps + rec.dx * s + rec.dy * c
                    rec.ox, rec.oy = x / fs, y / fs
                    f:ClearAllPoints()
                    f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", rec.ox, rec.oy)
                    if rec.multi then f:SetSize(rec.w, rec.h) end
                end
            end
        end
        guardDepth = guardDepth - 1
    end

    local refresh
    refresh = function()
        local on = On()
        -- Off with nothing claimed: nothing to put back, so nothing runs.
        if not on and not claimed then
            if driver then driver:Hide() end
            angle, held = 0, false
            return
        end
        -- Moving a protected member is blocked in combat, so only the safe
        -- half (Show/Hide of our own driver) runs there; the rest re-runs on
        -- PLAYER_REGEN_ENABLED with the member table left intact.
        if InCombatLockdown() then
            EllesmereUI.CombatQueue.Defer(refresh, refresh)
            if not on then
                if driver then driver:Hide() end
                angle = 0
            elseif driver then
                driver:Show()
            end
            return
        end
        if not on then
            if driver then driver:Hide() end
            angle, held = 0, false
            RestoreAll()
            return
        end
        if not driver then
            driver = CreateFrame("Frame")
            driver:Hide()
            driver:SetScript("OnUpdate", function(_, elapsed)
                if not On() then refresh(); return end
                if InCombatLockdown() then return end
                if EllesmereUI._unlockActive then
                    if not held then held = true; RestoreAll() end
                    return
                end
                if held then held = false; Claim() end
                -- Pick up late spawns / added blocks about once a second.
                since = since + elapsed
                if since > 1 then since = 0; Claim() end
                angle = (angle + math.rad(Speed()) * elapsed) % (math.pi * 2)
                if #order > 0 then Tick(math.cos(angle), math.sin(angle)) end
            end)
        end
        Claim()
        driver:Show()
    end

    refreshers[#refreshers + 1] = refresh
    return refresh
end

-- Party Mode starts from the options page, a keybind, a random timer or
-- Bloodlust; its two public entry points catch all of them.
hooksecurefunc("EllesmereUI_StartPartyMode", RefreshAll)
hooksecurefunc("EllesmereUI_StopPartyMode", RefreshAll)
end
