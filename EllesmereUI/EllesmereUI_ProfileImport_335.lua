-------------------------------------------------------------------------------
--  EllesmereUI_ProfileImport_335.lua
--
--  Profile strings from Retail (or WoW Forever) on the Wrath port. Port modules
--  share most setting names with Retail but not all of them, nor every value
--  type, so a foreign string is not merged wholesale: each module starts from
--  the port's live settings and takes only the values whose key exists here
--  with the same type. Retail-only modules, spec assignments, spec overrides
--  and Cooldown Manager spells are dropped; anchors survive only between
--  elements this client registers. Port strings import unchanged.
-------------------------------------------------------------------------------
local EllesmereUI = _G.EllesmereUI
if not EllesmereUI then return end

local PORT_CLIENT = "wrath"
-- Synthetic Wrath spec IDs (EllesmereUI_3.3.5_Compat.lua); Retail IDs are far below.
local WRATH_SPEC_MIN = 33000
local RETAIL_ONLY_MODULES = { EllesmereUIDragonRiding = true, EllesmereUIMythicTimer = true }
local AB_RETAIL_KEYS = {
    MainBar = "bar1", Bar2 = "bar2", Bar3 = "bar3", Bar4 = "bar4", Bar5 = "bar5",
    Bar6 = "bar6", Bar7 = "bar7", Bar8 = "bar8", Bar9 = "bar9", Bar10 = "bar10",
    PetBar = "petBar", StanceBar = "stanceBar",
}
-- Retail data/menu bars the port moves as native HUD frames (EUI_NativeHUD_335.lua).
local AB_RETAIL_HUD_KEYS = { XPBar = "hud_xp", RepBar = "hud_reputation", MicroBar = "hud_micro", BagBar = "hud_bags" }
-- Port fields holding one position record, and tables holding records by element key.
local POSITION_FIELDS = { unlockPos = true, position = true, savedPos = true }
local POSITION_TABLES = { positions = true, barPositions = true }
-- Retail position records the port stores elsewhere: { folder, retailPath, { portPath, ... } }.
local POSITION_MOVES = {
    { "EllesmereUIChat", { "chat", "chatPosition" }, { { "chat", "position" } } },
    { "EllesmereUIRaidFrames", { "unlockPos" },
        { { "positions", "raid10" }, { "positions", "raid25" }, { "positions", "raid40" } } },
    { "EllesmereUIRaidFrames", { "partyUnlockPos" }, { { "positions", "party" } } },
    { "EllesmereUIRaidFrames", { "healerMana", "unlockPos" }, { { "positions", "healerMana" } } },
    { "EllesmereUIQoL", { "fpsPos" }, { { "positions", "fps" } } },
    { "EllesmereUIQoL", { "secondaryStatsPos" }, { { "positions", "stats" } } },
}
local OVERRIDE_KEYS = {
    "specOverrides", "specOverrideGroups", "specOverrideNextId",
    "condOverrides", "condOverrideGroups", "condOverrideNextId",
    "specUnlockOverrides", "condUnlockOverrides",
    "specBmOverrides", "condBmOverrides",
    "specDmOverrides", "condDmOverrides",
    "unlockOverrideAnchors",
}

-- Retail Nameplates keys the port engine stores under another name:
-- { retailKey, portKey, convert(value, retailBlob) or nil }. A nil result drops the value.
local NP_RETAIL_KEYS = {
    -- Retail draws the bar BAR_W (150) + healthBarWidth wide; the port stores the full width.
    { "healthBarWidth", "width", function(v) return type(v) == "number" and 150 + v or nil end },
    { "healthBarHeight", "height" },
    { "castBarHeight", "castHeight" },
    { "enemyNameTextSize", "nameSize" },
    { "friendlyNameTextSize", "friendlyNameSize" },
    { "nameplateYOffset", "yOffset" },
    { "castBar", "castBarColor" },
    { "interruptedFlashEnabled", "showInterruptedFlash" },
    { "interruptedFlashColor", "interruptedColor" },
    { "targetColorEnabled", "enableTargetColor" },
    { "target", "targetColor" },
    { "maxDebuffs", "maxAuras" },
    { "debuffIconSize", "auraSize" },
    { "buffIconSize", "buffSize" },
    { "debuffSpacing", "auraSpacing" },
    { "rareEliteIconSize", "classificationSize" },
    { "raidMarkerPos", "raidMarkerSlot" },
    { "debuffTimerPosition", "auraTimerPosition", function(v) return (v == "topleft" or v == "center") and v or nil end },
    { "showCastIcon", "castIconPosition", function(v, src)
        if v == false then return "none" end
        if v == true then return src.castIconOnRight and "right" or "left" end
    end },
}
-- Present in every Retail Nameplates profile and never in a port one.
local NP_RETAIL_MARKERS = { "healthBarHeight", "castBarHeight", "enemyNameTextSize" }

-- Settings stored in other units on Retail: { folder, path, convert }.
local UNIT_FIXES = {
    { "EllesmereUINameplates", { "targetScale" }, function(v) return v > 5 and v / 100 or v end },
    { "EllesmereUIQoL", { "raidTools", "scale" }, function(v) return v <= 5 and v * 100 or v end },
}

EllesmereUI.WRATH_PAYLOAD_CLIENT = PORT_CLIENT

local function Copy(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, x in pairs(v) do out[k] = Copy(x) end
    return out
end

--- The client a decoded payload was exported on: "wrath", "forever" or "retail".
--- Port strings made before the client stamp carry Wrath markers (port Action
--- Bars keys, synthetic spec IDs); an untagged string without Retail markers
--- is read as an older port export.
function EllesmereUI.WrathPayloadClient(payload)
    if type(payload) ~= "table" then return "retail" end
    if type(payload.client) == "string" then return payload.client end
    local data = type(payload.data) == "table" and payload.data or {}
    local addons = type(data.addons) == "table" and data.addons or {}
    local ab = addons.EllesmereUIActionBars
    if type(ab) == "table" then
        local bars = type(ab.bars) == "table" and ab.bars or {}
        if ab._abRetail ~= nil or bars.bar1 ~= nil then return PORT_CLIENT end
        if bars.MainBar ~= nil then return "retail" end
    end
    for folder in pairs(RETAIL_ONLY_MODULES) do
        if addons[folder] ~= nil then return "retail" end
    end
    local np = addons.EllesmereUINameplates
    if type(np) == "table" and np.width == nil then
        for _, k in ipairs(NP_RETAIL_MARKERS) do
            if np[k] ~= nil then return "retail" end
        end
    end
    if type(data.assignedSpecs) == "table" then
        for _, id in ipairs(data.assignedSpecs) do
            if type(id) == "number" then
                return id >= WRATH_SPEC_MIN and PORT_CLIENT or "retail"
            end
        end
    end
    return PORT_CLIENT
end

function EllesmereUI.WrathPayloadIsForeign(payload)
    return EllesmereUI.WrathPayloadClient(payload) ~= PORT_CLIENT
end

local function IsList(t)
    return type(t) == "table" and t[1] ~= nil
end

local Overlay

-- Lists of records match by their `key` field when they carry one (Cooldown
-- Manager bars), else by position. Scalar lists (orders, spell IDs) are taken
-- only when they are a reordering of the port's own entries.
local function OverlayList(dst, src, stats)
    if type(src[1]) == "table" then
        local byKey = {}
        for _, v in ipairs(dst) do
            if type(v) == "table" and v.key ~= nil then byKey[v.key] = v end
        end
        for i, v in ipairs(src) do
            local target
            if type(v) == "table" then
                if v.key ~= nil then
                    target = byKey[v.key]
                elseif type(dst[i]) == "table" and dst[i].key == nil then
                    target = dst[i]
                end
            end
            if target then Overlay(target, v, stats) else stats.skipped = stats.skipped + 1 end
        end
        return
    end
    if #src ~= #dst then stats.skipped = stats.skipped + 1; return end
    local have = {}
    for _, v in ipairs(dst) do have[v] = true end
    for _, v in ipairs(src) do
        if not have[v] then stats.skipped = stats.skipped + 1; return end
    end
    for i, v in ipairs(src) do dst[i] = v end
    stats.applied = stats.applied + 1
end

Overlay = function(dst, src, stats)
    for k, v in pairs(src) do
        local cur = dst[k]
        if type(v) == "table" then
            if type(cur) ~= "table" then
                stats.skipped = stats.skipped + 1
            elseif IsList(v) and IsList(cur) then
                OverlayList(cur, v, stats)
            else
                Overlay(cur, v, stats)
            end
        elseif cur ~= nil and type(cur) == type(v) then
            dst[k] = v
            stats.applied = stats.applied + 1
        else
            stats.skipped = stats.skipped + 1
        end
    end
end
EllesmereUI.WrathOverlayCompatible = Overlay

local function IsBarPosition(p)
    return type(p) == "table" and type(p.point) == "string" and type(p.x) == "number" and type(p.y) == "number"
end

local function CleanPosition(p)
    return { point = p.point, relPoint = type(p.relPoint) == "string" and p.relPoint or p.point, x = p.x, y = p.y }
end

-- A port profile only stores a position once the element was moved, so the
-- Overlay finds no slot for most Retail records: take valid records whole
-- where the port keeps positions, inside tables the port profile has.
local function TakePositions(dst, src, stats, inPositions)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if (inPositions or POSITION_FIELDS[k]) and IsBarPosition(v) then
                dst[k] = CleanPosition(v)
                stats.applied = stats.applied + 1
            elseif type(dst[k]) == "table" and not IsBarPosition(v) then
                TakePositions(dst[k], v, stats, POSITION_TABLES[k])
            end
        end
    end
end

local function GetPath(t, path)
    for i = 1, #path do
        if type(t) ~= "table" then return nil end
        t = t[path[i]]
    end
    return t
end

local function SetPath(t, path, v)
    for i = 1, #path - 1 do
        if type(t[path[i]]) ~= "table" then t[path[i]] = {} end
        t = t[path[i]]
    end
    t[path[#path]] = v
end

-- Moves Retail position records onto the port's keys inside the Retail blob.
local function MovePositions(folder, snap, base)
    for _, m in ipairs(POSITION_MOVES) do
        if m[1] == folder then
            local p = GetPath(snap, m[2])
            if p ~= nil then
                SetPath(snap, m[2], nil)
                if IsBarPosition(p) then
                    for _, to in ipairs(m[3]) do SetPath(snap, to, CleanPosition(p)) end
                end
            end
        end
    end
    if folder == "EllesmereUICooldownManager" and type(snap.cdmBarPositions) == "table" then
        -- Only bars this profile has: Retail custom bar keys never match the port's.
        local known = {}
        local bars = GetPath(base, { "cdmBars", "bars" })
        if type(bars) == "table" then
            for _, b in ipairs(bars) do if type(b) == "table" and b.key then known[b.key] = true end end
        end
        if type(base.positions) == "table" then
            for k in pairs(base.positions) do known[k] = true end
        end
        snap.positions = type(snap.positions) == "table" and snap.positions or {}
        for k, p in pairs(snap.cdmBarPositions) do
            if known[k] and IsBarPosition(p) then snap.positions[k] = p end
        end
        snap.cdmBarPositions = nil
    elseif folder == "EllesmereUIDamageMeters" and type(GetPath(snap, { "dm", "windows" })) == "table" then
        snap.windows = type(snap.windows) == "table" and snap.windows or {}
        for i, w in ipairs(snap.dm.windows) do
            if type(w) == "table" and IsBarPosition(w.position) then
                snap.windows[i] = type(snap.windows[i]) == "table" and snap.windows[i] or {}
                snap.windows[i].savedPos = w.position
            end
        end
    end
end

-- Retail Action Bars key bars by MainBar/Bar2/PetBar; the port by bar1/bar2/petBar.
-- Bar positions are taken whole, as the port only stores the moved bars.
local function AdaptActionBars(dst, src, stats)
    for _, field in ipairs({ "bars", "barPositions" }) do
        if type(src[field]) == "table" then
            local renamed = {}
            for k, v in pairs(src[field]) do renamed[AB_RETAIL_KEYS[k] or k] = v end
            src[field] = renamed
        end
    end
    local positions = src.barPositions
    src.barPositions = nil
    Overlay(dst, src, stats)
    if type(positions) == "table" and type(dst.barPositions) == "table" then
        for _, key in pairs(AB_RETAIL_KEYS) do
            if IsBarPosition(positions[key]) then
                dst.barPositions[key] = CleanPosition(positions[key])
                stats.applied = stats.applied + 1
            end
        end
        for retailKey, hudKey in pairs(AB_RETAIL_HUD_KEYS) do
            if IsBarPosition(positions[retailKey]) then
                dst.barPositions[hudKey] = CleanPosition(positions[retailKey])
                stats.applied = stats.applied + 1
            end
        end
    end
end

local function RenameNameplateKeys(snap)
    for _, r in ipairs(NP_RETAIL_KEYS) do
        local v = snap[r[1]]
        if v ~= nil then
            snap[r[1]] = nil
            if r[3] then v = r[3](v, snap) end
            if v ~= nil and snap[r[2]] == nil then snap[r[2]] = v end
        end
    end
end

local function FixUnits(folder, snap)
    for _, fix in ipairs(UNIT_FIXES) do
        if fix[1] == folder then
            local t, path = snap, fix[2]
            for i = 1, #path - 1 do t = type(t) == "table" and t[path[i]] or nil end
            local k = path[#path]
            if type(t) == "table" and type(t[k]) == "number" then t[k] = fix[3](t[k]) end
        end
    end
end

local function LiveModuleProfiles()
    local out = {}
    local reg = EllesmereUI.Lite and EllesmereUI.Lite._dbRegistry
    if reg then
        for _, db in ipairs(reg) do
            if db.folder and type(db.profile) == "table" then out[db.folder] = db.profile end
        end
    end
    return out
end

-- Keep anchor and size-match links only between elements this client knows:
-- registered unlock elements or keys already in the port's own layout.
local function FilterLayout(ul, current, stats)
    if type(ul) ~= "table" then return nil end
    local reg = EllesmereUI._unlockRegisteredElements or {}
    local known = {}
    if type(current) == "table" then
        for _, field in ipairs({ "anchors", "widthMatch", "heightMatch" }) do
            if type(current[field]) == "table" then
                for child, target in pairs(current[field]) do
                    known[child] = true
                    if type(target) == "table" then target = target.target end
                    if type(target) == "string" then known[target] = true end
                end
            end
        end
    end
    local function Known(key) return type(key) == "string" and (reg[key] ~= nil or known[key] == true) end
    local isEdge = EllesmereUI.IsScreenEdgeKey
    local out = { anchors = {}, widthMatch = {}, heightMatch = {}, phantomBounds = {},
        widthMatchExtra = {}, heightMatchExtra = {} }
    if type(ul.anchors) == "table" then
        for child, info in pairs(ul.anchors) do
            if type(info) == "table" and Known(child)
               and (Known(info.target) or (isEdge and isEdge(info.target))) then
                out.anchors[child] = Copy(info)
            else
                stats.anchorsSkipped = stats.anchorsSkipped + 1
            end
        end
    end
    for _, field in ipairs({ "widthMatch", "heightMatch" }) do
        if type(ul[field]) == "table" then
            local extras = type(ul[field .. "Extra"]) == "table" and ul[field .. "Extra"] or {}
            for child, target in pairs(ul[field]) do
                if Known(child) and Known(target) then
                    out[field][child] = target
                    out[field .. "Extra"][child] = extras[child]
                else
                    stats.anchorsSkipped = stats.anchorsSkipped + 1
                end
            end
        end
    end
    if type(ul.phantomBounds) == "table" then
        for key, v in pairs(ul.phantomBounds) do
            if Known(key) then out.phantomBounds[key] = Copy(v) end
        end
    end
    return out
end

local function FontUsable(name)
    if type(name) ~= "string" then return false end
    if name:sub(1, 2) == "__" then return true end
    if EllesmereUI.FONT_FILES and EllesmereUI.FONT_FILES[name] then return true end
    if EllesmereUI.FONT_BLIZZARD and EllesmereUI.FONT_BLIZZARD[name] then return true end
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    return LSM and LSM:IsValid("font", name) and true or false
end

--- Rewrites a decoded foreign (Retail / WoW Forever) full payload in place so
--- ImportProfile merges only what the port supports. Port payloads are left
--- untouched. Returns the stats table, or nil when nothing was adapted.
function EllesmereUI.WrathAdaptForeignPayload(payload)
    if type(payload) ~= "table" or payload.type ~= "full" or type(payload.data) ~= "table" then return nil end
    if not EllesmereUI.WrathPayloadIsForeign(payload) then return nil end
    local data = payload.data
    local stats = { applied = 0, skipped = 0, anchorsSkipped = 0, modules = 0, modulesSkipped = {} }

    if type(data.addons) == "table" then
        local live = LiveModuleProfiles()
        local adapted = {}
        for folder, snap in pairs(data.addons) do
            local base = live[folder]
            if type(snap) == "table" and type(base) == "table" then
                local merged = Copy(base)
                if folder == "EllesmereUINameplates" then RenameNameplateKeys(snap) end
                FixUnits(folder, snap)
                if folder == "EllesmereUIActionBars" then
                    AdaptActionBars(merged, Copy(snap), stats)
                else
                    MovePositions(folder, snap, merged)
                    Overlay(merged, snap, stats)
                    TakePositions(merged, snap, stats)
                end
                adapted[folder] = merged
                stats.modules = stats.modules + 1
            else
                stats.modulesSkipped[#stats.modulesSkipped + 1] = folder
            end
        end
        data.addons = adapted
    end

    local db = EllesmereUIDB
    local current = db and db.profiles and db.profiles[db.activeProfile or "Default"]
    if data.unlockLayout ~= nil then
        data.unlockLayout = FilterLayout(data.unlockLayout, current and current.unlockLayout, stats)
    end
    data.unlockLayoutMeta = nil

    for _, k in ipairs(OVERRIDE_KEYS) do data[k] = nil end
    data.overridesIncluded = nil
    data.overridesExcluded = true
    data.assignedSpecs = nil
    data.cdmSpells = nil
    -- The module data is now the port's current shape: keep the port's migration stamps.
    data._migrations = nil

    if type(data.fonts) == "table" and EllesmereUI.GetFontsDB then
        local fonts = Copy(EllesmereUI.GetFontsDB())
        local incoming = Copy(data.fonts)
        if not FontUsable(incoming.global) then incoming.global = nil end
        Overlay(fonts, incoming, stats)
        data.fonts = fonts
    end

    -- Retail keeps the fixed tooltip anchor as CENTER offsets { centerX, centerY }.
    local tip = data.tooltipFixedPos
    if type(tip) == "table" then
        if type(tip.centerX) == "number" and type(tip.centerY) == "number" then
            data.tooltipFixedPos = { point = "CENTER", relPoint = "CENTER", x = tip.centerX, y = tip.centerY }
        elseif IsBarPosition(tip) then
            data.tooltipFixedPos = CleanPosition(tip)
        else
            data.tooltipFixedPos = nil
        end
    end

    -- Window-skin bundle: ApplyBlizzSkinGlobals would clear every allowlisted key
    -- the Retail bundle lacks, so take only the keys this client already has.
    if type(data.blizzSkinGlobals) == "table" and db then
        for k, v in pairs(data.blizzSkinGlobals) do
            local cur = db[k]
            if type(v) == "table" and type(cur) == "table" then
                Overlay(cur, v, stats)
            elseif cur ~= nil and type(cur) == type(v) then
                db[k] = v
                stats.applied = stats.applied + 1
            end
        end
    end
    data.blizzSkinGlobals = nil
    data.applyBlizzSkinGlobals = nil

    payload._wrathImportStats = stats
    if EllesmereUI.Print then
        local skipped = #stats.modulesSkipped > 0
            and (" Not on this client: " .. table.concat(stats.modulesSkipped, ", "):gsub("EllesmereUI", "") .. ".") or ""
        EllesmereUI.Print(("Retail profile: %d settings imported into %d modules, %d Retail-only settings and %d anchors skipped.%s")
            :format(stats.applied, stats.modules, stats.skipped, stats.anchorsSkipped, skipped))
    end
    return stats
end
