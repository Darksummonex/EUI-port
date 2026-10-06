-- EllesmereUIDataBars 3.3.5: user-created multi-bar engine.
-- Native port of the Retail engine (EllesmereUIDataBars.lua, kept as an unloaded
-- reference): DB + profile shape, shared helpers (fonts, money/time formatting,
-- heartbeat, combat deferral, text fit cache), the layout solver (Auto Sized with
-- one Fill Remaining block and an optional Force Centered block / Even Split),
-- the bar factory (EllesmereUI art cover-fit or Modern flat theme, border, slots,
-- per-block background/hover/content scale/offsets), the visibility runtime
-- (shared EUI visibility engine + mouseover proxies + a secure state driver for
-- the combat/group scalars), one Unlock Mode mover per bar and the CRUD API the
-- options page calls. The owned tooltip lives in EUI_DataBars_335_Tip.lua, block
-- helpers in EUI_DataBars_335_Kit.lua and the factories in Blocks_335\*.lua.
local ADDON, ns = ...
local E = EllesmereUI
if not E or not E.Lite then return end
E._ModuleNS[ADDON] = ns
local addon = E.Lite.NewAddon(ADDON)
ns.addon, ns.WB, ns.IsWrath = addon, addon, true

local MEDIA = "Interface\\AddOns\\EllesmereUIDataBars\\Media_335\\"
ns.MEDIA = MEDIA
ns.MICROMENU_MEDIA = MEDIA .. "micromenu\\"

local L = {
    LEFT_CLICK = "|cffFFFFFFLeft Click:|r", RIGHT_CLICK = "|cffFFFFFFRight Click:|r",
    MIDDLE_CLICK = "|cffFFFFFFMiddle Click:|r",
    SHIFT_MIDDLE_CLICK = "|cffFFFFFFShift + Middle Click:|r", SHIFT_LEFT_CLICK = "|cffFFFFFFShift + Left Click:|r",
    CTRL_LEFT_CLICK = "|cffFFFFFFCtrl + Left Click:|r", CTRL_RIGHT_CLICK = "|cffFFFFFFCtrl + Right Click:|r",
    CTRL_ALT_LEFT_CLICK = "|cffFFFFFFCtrl + Alt + Left Click:|r",
    YOU_HAVE_MAIL = "You've Got Mail!", SERVER_TIME = "Server time", SAVED_INSTANCES = "Saved Raid(s)",
    DAILY_RESET = "Daily reset", WEEKLY_RESET = "Weekly reset", TOGGLE_CALENDAR = "Toggle Calendar",
    TOGGLE_CLOCK = "Toggle Clock", RELOAD_UI = "Reload UI", FPS = "FPS", HOME = "Home", WORLD = "World",
    DOWNLOAD = "Download", UPLOAD = "Upload", KB_PER_SEC = "KB/s", MEMORY_USAGE = "Memory Usage",
    REFRESH_STATS = "Refresh stats / print memory snapshot", FORCE_GC = "Force garbage collection",
    GOLD = "Gold", SESSION = "Session", EARNED = "Earned", SPENT = "Spent", PROFIT = "Profit",
    DEFICIT = "Deficit", TOTAL = "Total", OPEN_BAGS = "Open Bags", BAGS = "Bags", FREE = "Free",
    OPEN_CURRENCIES = "Open Currencies", RESET_SESSION = "Reset Session", REMOVE_CHARACTER = "Remove Character",
    PLUS_N_MORE = "+ %d more", TRAVEL_COOLDOWNS = "Travel Cooldowns", HEARTHSTONE = "Hearthstone",
    READY = "Ready", ON_COOLDOWN = "On Cooldown", USE_HEARTHSTONE = "Use Hearthstone",
    RANDOM_HEARTHSTONE = "Random Hearthstone", CURRENT_SPEC = "Current Specialization",
    CHANGE_SPEC = "Change Specialization", CHANGE_SPEC_SHORT = "Change Spec", OPEN_TALENTS = "Open Talents",
    CANNOT_USE_COMBAT = "Cannot Use While In Combat", COMBAT_STATUS = "Combat Status",
    IN_COMBAT = "In Combat", OUT_OF_COMBAT = "Out of Combat", AUDIO = "Audio", AUDIO_MASTER = "Master",
    AUDIO_SFX = "Sound Effects", AUDIO_MUSIC = "Music", AUDIO_AMBIENCE = "Ambience",
    AUDIO_MUTE_HINT = "Toggle Mute", AUDIO_SET_HINT = "Set Volume", AUDIO_SCROLL_HINT = "Adjust Volume",
    AUDIO_SHIFT_HINT = "Hold Shift for 10% Steps", AUDIO_MUTED = "Muted",
    SCROLL_WHEEL = "|cffFFFFFFScroll:|r", DRAG_BAR = "|cffFFFFFFDrag Bar:|r",
    OPEN_PROFESSION = "Open Profession", OPEN_PROFESSION_BOOK = "Open Profession Book",
    START_CAMPFIRE = "Start a Campfire", ACH_POINTS = "Achievement Points",
    SELECT_CURRENCY = "Select a currency", SELECT_PLUGIN = "Select a plugin", OPEN_SETTINGS = "Open Settings",
    ILVL = "ILVL", ITEM_LEVEL = "Item Level", EQUIPPED = "Equipped", OPEN_CHARACTER = "Open Character Sheet",
    WHISPER = "Whisper", INVITE = "Invite", NO_FRIENDS_ONLINE = "No friends online",
    NOT_IN_GUILD = "Not in a guild", TOGGLE_WORLD_MAP = "Toggle World Map",
    SWITCH_TO_REP = "Switch to Reputation", SWITCH_TO_XP = "Switch to Experience",
    PROGRESS = "Progress", RESTED = "Rested", DUAL_SPEC = "Dual Specialization",
}
ns.L = L

local CreateFrame, UIParent = CreateFrame, UIParent
local InCombatLockdown = InCombatLockdown
local pairs, ipairs, type, pcall = pairs, ipairs, type, pcall
local format, tconcat, tremove, tsort = string.format, table.concat, table.remove, table.sort
local floor, max, min, abs = math.floor, math.max, math.min, math.abs
local PP = E.PP

-------------------------------------------------------------------------------
--  Legacy widget helpers (no SetSize/SetShown/SetColorTexture on this client)
-------------------------------------------------------------------------------
function ns.Size(f, w, h) f:SetWidth(w); f:SetHeight(h) end
function ns.Shown(f, v) if v then f:Show() else f:Hide() end end
function ns.Solid(t, r, g, b, a)
    if t.SetColorTexture then t:SetColorTexture(r, g, b, a == nil and 1 or a)
    else t:SetTexture(r, g, b, a == nil and 1 or a) end
end
function ns.Wipe(t) for k in pairs(t) do t[k] = nil end; return t end
function ns.Copy(v)
    if type(v) ~= "table" then return v end
    local out = {}; for k, x in pairs(v) do out[k] = ns.Copy(x) end; return out
end
local Copy, Wipe = ns.Copy, ns.Wipe
function ns.Clamp(v, lo, hi) return max(lo, min(hi, tonumber(v) or lo)) end
function ns.InRaid() return (GetNumRaidMembers and GetNumRaidMembers() or 0) > 0 end
function ns.InGroup() return ns.InRaid() or (GetNumPartyMembers and GetNumPartyMembers() or 0) > 0 end
function ns.MouseOver(f, slack)
    if not (f and f.IsVisible and f:IsVisible()) then return false end
    slack = slack or 0
    if f.IsMouseOver then return f:IsMouseOver(slack, -slack, -slack, slack) end
    if MouseIsOver then return MouseIsOver(f, slack, -slack, -slack, slack) end
    return false
end

-------------------------------------------------------------------------------
--  Defaults / block registry (Retail-only Crests and Great Vault are absent)
-------------------------------------------------------------------------------
local defaults = { profile = { nextBarId = 0, bars = {}, initialized = false, schema = 2 } }
ns.defaults = defaults

ns.BLOCK_TYPES = {
    { key = "clock", label = "Clock" }, { key = "fps", label = "FPS" }, { key = "ms", label = "Latency" },
    { key = "location", label = "Location" }, { key = "coords", label = "Coordinates" },
    { key = "gold", label = "Gold" }, { key = "bags", label = "Bags" },
    { key = "durability", label = "Durability" }, { key = "combat", label = "Combat Status" },
    { key = "xprep", label = "XP / Reputation Bar" }, { key = "spec", label = "Talent Specialization" },
    { key = "profession", label = "Professions" }, { key = "profession2", label = "Secondary Professions" },
    { key = "travel", label = "Travel Cooldowns" }, { key = "micromenu", label = "Micro Menu" },
    { key = "currency", label = "Currency" }, { key = "ilvl", label = "Item Level" },
    { key = "audio", label = "Audio" }, { key = "ldb", label = "Broker Plugin" }, { key = "spacer", label = "Spacer" },
}

ns.BLOCK_DEFAULTS = {
    clock = { localTime = true, twentyFour = true, showMail = true, showResting = true },
    fps = {},
    ms = { showIcon = false },
    location = { showIcon = true, showSubZone = true },
    coords = { showIcon = true, precision = 0, hideInInstance = true },
    gold = { showIcons = true, showBagSpace = false, showSmall = false, coinIcons = false, abbreviate = false, forceEnglishUnits = false },
    bags = { showIcon = true, value = "free", lowThreshold = 0 },
    durability = { showIcon = true },
    combat = { onlyInCombat = false },
    xprep = { mode = "auto" },
    spec = { showLoadout = true, useUppercase = false },
    profession = {}, profession2 = {},
    travel = { randomizeHs = true },
    micromenu = { hideSocialText = false, mainMenuSpacing = 4, iconSpacing = 2,
        menu = true, guild = true, social = true, char = true, spell = true, talent = true,
        ach = true, quest = true, lfg = true, pvp = true, help = true },
    currency = { currencyId = nil, showIcon = true, showDescription = true },
    ilvl = { prefix = "short", value = "equipped", precision = 0 },
    audio = { channel = "master" },
    ldb = { source = nil, showIcon = true, showLabel = false, showText = true, stripColors = true, maxWidth = nil },
    spacer = {},
}
ns.BlockFactories = {}

-------------------------------------------------------------------------------
--  Profile access
-------------------------------------------------------------------------------
function ns.GetProfile() return addon.db and addon.db.profile end
function ns.BarsInOrder() local p = ns.GetProfile(); return p and p.bars or {} end
function ns.GetBar(id)
    local bars = ns.BarsInOrder()
    for i = 1, #bars do if bars[i].id == id then return bars[i] end end
end
local function GetBlock(barCfg, blockId)
    if not barCfg then return end
    for i = 1, #barCfg.blocks do if barCfg.blocks[i].id == blockId then return barCfg.blocks[i], i end end
end
function ns.GetBlock(barId, blockId) return GetBlock(ns.GetBar(barId), blockId) end

-------------------------------------------------------------------------------
--  Fonts / colors
-------------------------------------------------------------------------------
function ns.SetFont(fs, size, barCfg)
    if not (fs and fs.SetFont) then return end
    local path = (E.GetFontPath and E.GetFontPath("dataBars")) or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    local flags = (E.GetFontOutlineFlag and E.GetFontOutlineFlag("dataBars")) or "OUTLINE"
    flags = flags:gsub(",?%s*SLUG", "")
    local scale = barCfg and barCfg.fontScale or 100
    local sz = max(6, floor((size or 11) * scale / 100 + 0.5))
    if E.PrimeFontShadow then
        local shadow = flags == "" and (not E.GetFontUseShadow or E.GetFontUseShadow("dataBars"))
        E.PrimeFontShadow(fs, shadow and true or false)
    end
    if not fs:SetFont(path, sz, flags) then fs:SetFont("Fonts\\FRIZQT__.TTF", sz, flags) end
end
function ns.GetAccent()
    if E.GetAccentColor then
        local r, g, b = E.GetAccentColor()
        if type(r) == "table" then return r.r, r.g, r.b end
        if r then return r, g, b end
    end
    local t = E.ELLESMERE_GREEN
    if t then return t.r, t.g, t.b end
    return 0.047, 0.824, 0.616
end
function ns.SlowColorGradient(perc)
    perc = max(0, min(1, perc))
    local function smooth(t) return t * t * (3 - 2 * t) end
    if perc < 0.5 then local t = smooth(perc * 2); return 1, t, 0.08 * (1 - t) end
    local t = smooth((perc - 0.5) * 2); return 1, 1, t
end
function ns.SnapToPixelGrid(v)
    local r = floor((v or 0) + 0.5)
    return max(2, r + (r % 2))
end

-------------------------------------------------------------------------------
--  Money / time formatting
-------------------------------------------------------------------------------
local DENOMINATIONS = {
    { divisor = 10000, symbol = GOLD_AMOUNT_SYMBOL or "g", color = "|cffe2ac7a" },
    { divisor = 100, symbol = SILVER_AMOUNT_SYMBOL or "s", color = "|cffc7c7cf" },
    { divisor = 1, symbol = COPPER_AMOUNT_SYMBOL or "c", color = "|cffed8a3f" },
}
local COIN_TEX = {
    "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t",
    "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t",
    "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t",
}
local function CoinMarker(i, coinIcons, coloured)
    if coinIcons then return COIN_TEX[i] end
    local d = DENOMINATIONS[i]
    if coloured then return d.color .. d.symbol .. "|r" end
    return d.symbol
end
function ns.GroupDigits(n)
    local s = tostring(floor(n or 0))
    local sep = LARGE_NUMBER_SEPERATOR or ","
    local out = s:reverse():gsub("(%d%d%d)", "%1" .. sep):reverse()
    return (out:gsub("^%" .. sep, ""))
end
local function GoldDisplay(val, abbreviate, forceEnglish)
    if abbreviate and E.AbbreviateNumber then return E.AbbreviateNumber(val, forceEnglish) end
    return ns.GroupDigits(val)
end
local _moneyTokens = {}
function ns.MoneyTokens(amount, showSmall, coinIcons, coloured, abbreviate, forceEnglish)
    amount = floor(abs(amount or 0))
    Wipe(_moneyTokens)
    _moneyTokens[1] = GoldDisplay(floor(amount / 10000), abbreviate, forceEnglish) .. CoinMarker(1, coinIcons, coloured)
    if showSmall ~= false then
        _moneyTokens[2] = floor((amount % 10000) / 100) .. CoinMarker(2, coinIcons, coloured)
        _moneyTokens[3] = (amount % 100) .. CoinMarker(3, coinIcons, coloured)
    end
    return _moneyTokens
end
function ns.FormatMoney(amount, useColors, showSmall, coinIcons, abbreviate, forceEnglish)
    amount = floor(abs(amount or 0))
    local coloured = useColors ~= false
    local parts, foundGold = {}, false
    for i, d in ipairs(DENOMINATIONS) do
        local val = floor(amount / d.divisor)
        amount = amount % d.divisor
        if i == 1 and val > 0 then
            foundGold = true
            parts[#parts + 1] = GoldDisplay(val, abbreviate, forceEnglish) .. CoinMarker(i, coinIcons, coloured)
        elseif i > 1 and (not foundGold or showSmall ~= false) and (val > 0 or (i == 3 and #parts == 0)) then
            parts[#parts + 1] = val .. CoinMarker(i, coinIcons, coloured)
        end
    end
    if #parts == 0 then return "0" .. CoinMarker(3, coinIcons, coloured) end
    return tconcat(parts, " ")
end
function ns.FormatTimeLeft(seconds)
    seconds = floor(seconds or 0)
    if SecondsToTime then return SecondsToTime(seconds, seconds >= 60, nil, 3) end
    return ns.FormatCooldown(seconds) or "0"
end
function ns.FormatCooldown(cd)
    if not cd or cd <= 0 then return nil end
    cd = floor(cd)
    if cd >= 3600 then return format("%d:%02d:%02d", floor(cd / 3600), floor(cd % 3600 / 60), cd % 60) end
    return format("%d:%02d", floor(cd / 60), cd % 60)
end
function ns.GetFPSSuffix() return FPS_ABBR or " fps" end
function ns.GetMSSuffix() return MILLISECONDS_ABBR or " ms" end

-------------------------------------------------------------------------------
--  Runtime frame: combat deferral, 1 s heartbeat, coalesced layouts
-------------------------------------------------------------------------------
local runtime = CreateFrame("Frame")
ns.runtime = runtime
local deferred, deferredOrder = {}, {}
function ns.DeferUntilOOC(key, fn)
    if not InCombatLockdown() then fn(); return end
    if not deferred[key] then deferredOrder[#deferredOrder + 1] = key end
    deferred[key] = fn
    ns.pending = true
end
function ns.FlushDeferred()
    if InCombatLockdown() then return end
    local order = deferredOrder
    deferredOrder = {}
    local fns = deferred
    deferred = {}
    ns.pending = false
    for i = 1, #order do
        local fn = fns[order[i]]
        if fn then
            local ok, err = pcall(fn)
            if not ok and geterrorhandler then geterrorhandler()(err) end
        end
    end
end
local listeners, listenerCount = {}, 0
function ns.RegisterHeartbeat(key, fn)
    if not listeners[key] then listenerCount = listenerCount + 1 end
    listeners[key] = fn
end
function ns.UnregisterHeartbeat(key)
    if listeners[key] then listenerCount = listenerCount - 1; listeners[key] = nil end
end
function ns.HeartbeatTick()
    for _, cb in pairs(listeners) do
        local ok, err = pcall(cb)
        if not ok and geterrorhandler then geterrorhandler()(err) end
    end
end
local layoutQueue = {}
local ApplyLayout
function ns.FlushLayouts()
    for id in pairs(layoutQueue) do
        layoutQueue[id] = nil
        ApplyLayout(id)
    end
end
do
    local elapsed = 0
    runtime:SetScript("OnUpdate", function(_, dt)
        if next(layoutQueue) then ns.FlushLayouts() end
        elapsed = elapsed + (dt or 0)
        if elapsed >= 1 then elapsed = 0; if listenerCount > 0 then ns.HeartbeatTick() end end
    end)
end

-------------------------------------------------------------------------------
--  Text fitting helpers + fit cache
-------------------------------------------------------------------------------
function ns.SetWrappedText(fs, width, justify)
    if not fs then return end
    fs:SetWidth(max(1, width or 1))
    if fs.SetWordWrap then fs:SetWordWrap(true) end
    if fs.SetNonSpaceWrap then fs:SetNonSpaceWrap(true) end
    if fs.SetJustifyH then fs:SetJustifyH(justify or "CENTER") end
end
function ns.ResetInlineText(fs, justify)
    if not fs then return end
    fs:SetWidth(0)
    if fs.SetWordWrap then fs:SetWordWrap(false) end
    if fs.SetNonSpaceWrap then fs:SetNonSpaceWrap(false) end
    if fs.SetJustifyH then fs:SetJustifyH(justify or "LEFT") end
end
local _fitCache, _fitCount, _measureFS = {}, 0, nil
function ns.MeasureFS()
    if not _measureFS then _measureFS = UIParent:CreateFontString(nil, "OVERLAY") end
    return _measureFS
end
function ns.FitFontToLines(lines, startSize, minSize, maxWidth, barCfg)
    local fs = ns.MeasureFS()
    local width = max(1, maxWidth or 1)
    local start = startSize or 14
    local floorSize = minSize or max(8, start - 6)
    local parts = { start, floorSize, width, barCfg and barCfg.fontScale or 100 }
    for i, line in ipairs(lines or {}) do parts[i + 4] = line or "" end
    local key = tconcat(parts, "\1")
    if _fitCache[key] then return _fitCache[key] end
    local result = floorSize
    for size = start, floorSize, -1 do
        ns.SetFont(fs, size, barCfg)
        local widest = 0
        for _, line in ipairs(lines or {}) do
            fs:SetText(line or "")
            widest = max(widest, fs:GetStringWidth() or 0)
        end
        if widest <= width then result = size; break end
    end
    if _fitCount > 200 then _fitCache, _fitCount = {}, 0 end
    _fitCache[key] = result; _fitCount = _fitCount + 1
    return result
end
function ns.WipeFitCache() _fitCache, _fitCount = {}, 0 end

-------------------------------------------------------------------------------
--  Layout solver (pure; identical semantics to Retail)
-------------------------------------------------------------------------------
local EDGE_PAD = 0
ns.EDGE_PAD = EDGE_PAD
function ns.BarSizingMode(barCfg)
    if barCfg and barCfg.sizingMode == "even" then return "even" end
    return "auto"
end
function ns.EnsureFillBlock(barCfg)
    local blocks = barCfg and barCfg.blocks
    local n = blocks and #blocks or 0
    if n == 0 then return nil end
    local id = barCfg.fillBlockId
    if id ~= nil then for i = 1, n do if blocks[i].id == id then return id end end end
    id = blocks[n].id
    barCfg.fillBlockId = id
    return id
end
local function ContentGapsOf(b)
    local base = b.contentGap
    if base == nil then base = 10 end
    local l, r = b.contentGapL, b.contentGapR
    if l == nil then l = base end
    if r == nil then r = base end
    return l, r
end
ns.ContentGapsOf = ContentGapsOf

function ns.SolveLayout(barCfg, len, measure)
    local segs = {}
    local n = #barCfg.blocks
    if n == 0 then return segs end
    if ns.BarSizingMode(barCfg) == "even" then
        local shares, nShare = {}, 0
        for i = 1, n do
            local b = barCfg.blocks[i]
            local has = true
            if b.type ~= "spacer" and measure then has = (measure(b) or 0) > 0 end
            shares[i] = has
            if has then nShare = nShare + 1 end
        end
        if nShare == 0 then nShare = n; for i = 1, n do shares[i] = true end end
        local prev, k = 0, 0
        for i = 1, n do
            if shares[i] then
                k = k + 1
                local edge = floor(k * len / nShare + 0.5)
                segs[i] = { block = barCfg.blocks[i], at = prev, px = edge - prev }
                prev = edge
            else
                segs[i] = { block = barCfg.blocks[i], at = prev, px = 0 }
            end
        end
        return segs
    end
    local fillId = ns.EnsureFillBlock(barCfg)
    local centerIdx
    if barCfg.centerBlockId ~= nil then
        for i = 1, n do if barCfg.blocks[i].id == barCfg.centerBlockId then centerIdx = i; break end end
    end
    local function SizedPx(b)
        local w = 0
        if b.type ~= "spacer" and measure then
            w = measure(b) or 0
            if w <= 0 then return 0, 0, 0 end
        end
        local gl, gr = ContentGapsOf(b)
        return w + gl + gr, gl, w
    end
    for i = 1, n do
        local b = barCfg.blocks[i]
        local seg = { block = b, at = 0, px = 0 }
        if b.id == fillId then seg.isFill = true else seg.desired = SizedPx(b) end
        segs[i] = seg
    end
    local function SolveRegion(first, last, rStart, rEnd, packRight)
        if first > last then return end
        local rLen = max(0, rEnd - rStart)
        local sumFixed, hasFill = 0, false
        for i = first, last do
            if segs[i].isFill then hasFill = true else sumFixed = sumFixed + segs[i].desired end
        end
        local scale, fillPx = 1, 0
        if sumFixed > rLen then
            if sumFixed > 0 then scale = rLen / sumFixed end
        elseif hasFill then
            fillPx = rLen - sumFixed
        end
        if packRight and not hasFill then
            local cum, prev = 0, 0
            local rE = floor(rEnd + 0.5)
            for i = last, first, -1 do
                cum = cum + segs[i].desired * scale
                local edge = floor(cum + 0.5)
                segs[i].px = edge - prev
                segs[i].at = rE - edge
                prev = edge
            end
            return
        end
        local base = floor(rStart + 0.5)
        local cum, prev = 0, 0
        for i = first, last do
            local s = segs[i]
            cum = cum + (s.isFill and fillPx or s.desired * scale)
            local edge = floor(cum + 0.5)
            if hasFill and i == last then edge = floor(rEnd + 0.5) - base end
            s.px = edge - prev
            s.at = base + prev
            prev = edge
        end
    end
    if not centerIdx then SolveRegion(1, n, 0, len, false); return segs end
    local cB = barCfg.blocks[centerIdx]
    local cIsFill = cB.id == fillId
    local cDesired, cGl, cW = SizedPx(cB)
    local cPx = floor(cDesired + 0.5)
    local cAt = floor(len / 2 - cW / 2 - cGl + 0.5)
    if cAt < 0 then cAt = 0 end
    if cAt + cPx > len then cAt = floor(max(0, len - cPx) + 0.5) end
    local cSeg = segs[centerIdx]
    cSeg.desired = nil
    SolveRegion(1, centerIdx - 1, 0, cAt, false)
    SolveRegion(centerIdx + 1, n, cAt + cPx, len, true)
    if cIsFill then
        local leftEnd = 0
        if centerIdx > 1 then local ls = segs[centerIdx - 1]; leftEnd = ls.at + ls.px end
        local rightStart = floor(len + 0.5)
        if centerIdx < n then rightStart = segs[centerIdx + 1].at end
        cSeg.isFill = true
        cSeg.at = leftEnd
        cSeg.px = max(0, rightStart - leftEnd)
        cSeg.contentShift = (len / 2) - (cSeg.at + cSeg.px / 2)
    else
        cSeg.at, cSeg.px = cAt, cPx
    end
    return segs
end

-------------------------------------------------------------------------------
--  Theme rendering: EllesmereUI art cover-fit / Modern flat / bar texture
-------------------------------------------------------------------------------
local BG_ASPECT = 561 / 433
local BASE_L, BASE_R, BASE_T, BASE_B = 0.25, 1, 0, 0.75
local BASE_U, BASE_V = BASE_R - BASE_L, BASE_B - BASE_T
local function UpdateBgTexCoords(host)
    local fw, fh = host:GetWidth(), host:GetHeight()
    if not fw or fw <= 0 or not fh or fh <= 0 or not host._edbBgAtlas then return end
    local fa = fw / fh
    if fa > BG_ASPECT then
        local trim = (BASE_V - BASE_V * (BG_ASPECT / fa)) / 2
        host._edbBgAtlas:SetTexCoord(BASE_L, BASE_R, BASE_T + trim, BASE_B - trim)
    else
        local trim = (BASE_U - BASE_U * (fa / BG_ASPECT)) / 2
        host._edbBgAtlas:SetTexCoord(BASE_L + trim, BASE_R - trim, BASE_T, BASE_B)
    end
end
local function EnsureThemeTextures(host)
    if host._edbBgAtlas then return end
    local atlas = host:CreateTexture(nil, "BACKGROUND", nil, -8)
    atlas:SetTexture(MEDIA .. "modern_blizz")
    atlas:SetAllPoints(host)
    local overlay = host:CreateTexture(nil, "BACKGROUND", nil, -7)
    ns.Solid(overlay, 0, 0, 0, 0.5); overlay:SetAllPoints(host)
    local modern = host:CreateTexture(nil, "BACKGROUND", nil, -7)
    ns.Solid(modern, 0.067, 0.067, 0.067, 0.95); modern:SetAllPoints(host)
    local barTex = host:CreateTexture(nil, "BACKGROUND", nil, -6)
    barTex:SetAllPoints(host); barTex:SetAlpha(0)
    host._edbBgAtlas, host._edbBgOverlay, host._edbModernBg, host._edbBarTex = atlas, overlay, modern, barTex
    host:HookScript("OnSizeChanged", function(self) UpdateBgTexCoords(self) end)
    UpdateBgTexCoords(host)
end
local function ApplyThemeToHost(host, theme, texKey, showBorder)
    EnsureThemeTextures(host)
    theme = theme or {}
    local texPath
    if texKey and texKey ~= "none" and ns.barTextures then texPath = ns.barTextures[texKey] end
    local op
    if theme.style == "modern" then
        host._edbBgAtlas:SetAlpha(0); host._edbBgOverlay:SetAlpha(0)
        local c = theme.modernColor or {}
        local r, g, b, a = c.r or 0.067, c.g or 0.067, c.b or 0.067, c.a or 0.95
        if texPath then
            host._edbBarTex:SetTexture(texPath)
            host._edbBarTex:SetVertexColor(r, g, b, a)
            host._edbBarTex:SetAlpha(a)
            host._edbModernBg:SetAlpha(0)
        else
            host._edbBarTex:SetAlpha(0)
            ns.Solid(host._edbModernBg, r, g, b, a)
            host._edbModernBg:SetAlpha(1)
        end
        op = a
    else
        op = theme.euiOpacity
        if op == nil then op = 1 end
        host._edbBarTex:SetAlpha(0)
        host._edbBgAtlas:SetAlpha(op)
        ns.Solid(host._edbBgOverlay, 0, 0, 0, theme.euiAlpha or 0.5)
        host._edbBgOverlay:SetAlpha(op)
        host._edbModernBg:SetAlpha(0)
    end
    local border = host._edbBorder
    if border and border.SetAlpha then border:SetAlpha(showBorder == false and 0 or op) end
    UpdateBgTexCoords(host)
end
function ns.MakePreviewBackdrop(host, themeCfg, showBorder) ApplyThemeToHost(host, themeCfg, nil, showBorder) end

-------------------------------------------------------------------------------
--  Live registry + bar factory
-------------------------------------------------------------------------------
local live = {}
ns.live, ns._live = live, live
ns._moEligible = {}
local parkFrame = CreateFrame("Frame"); parkFrame:Hide()
ns._park = parkFrame
local AfterBarStateChange, RegisterBarMouseoverProxy

local function MakeBarCtx(id)
    local ctx = { id = id }
    function ctx.IsVertical() return ctx.cfg ~= nil and ctx.cfg.orientation == "V" end
    function ctx.GetThickness() return (ctx.cfg and ctx.cfg.thickness) or 30 end
    function ctx.RequestLayout() ns.RequestLayout(id) end
    function ctx.IsBarAtTop()
        local rec = live[id]
        if not (rec and rec.bar) then return false end
        local _, cy = rec.bar:GetCenter()
        return cy ~= nil and cy > (UIParent:GetHeight() / 2)
    end
    return ctx
end
-- Horizontal ("H": LEFT/RIGHT/"") or vertical ("V": TOP/BOTTOM/"") half of an anchor point.
local function PointPart(point, axis)
    point = point or "CENTER"
    if axis == "H" then return point:find("LEFT") and "LEFT" or point:find("RIGHT") and "RIGHT" or "" end
    return point:find("TOP") and "TOP" or point:find("BOTTOM") and "BOTTOM" or ""
end
local function JoinPoint(v, h)
    local p = v .. h
    return p == "" and "CENTER" or p
end
local function ApplyBarPosition(id)
    local rec, cfg = live[id], ns.GetBar(id)
    if not (rec and rec.bar and cfg) then return end
    local bar = rec.bar
    if InCombatLockdown() then ns.DeferUntilOOC("pos:" .. id, function() ApplyBarPosition(id) end); return end
    local vertical = cfg.orientation == "V"
    local full = cfg.lengthMode == "full"
    local sp = cfg.savedPos
    local edge = cfg.snapEdge
    if edge == "none" then edge = nil end
    if edge and vertical and edge ~= "left" and edge ~= "right" then edge = nil end
    if edge and not vertical and edge ~= "bottom" and edge ~= "top" then edge = nil end
    bar:ClearAllPoints()
    if not (full or edge) then
        if sp and sp.point then bar:SetPoint(sp.point, UIParent, sp.relPoint or sp.point, sp.x or 0, sp.y or 0)
        else bar:SetPoint("CENTER", UIParent, "CENTER", 0, 0) end
        return
    end
    -- Anchor to UIParent's edges, never to coordinates computed from its size: Core
    -- re-applies the UI scale after OnEnable, which would strand absolute offsets.
    local pt = sp and sp.point or "CENTER"
    local rpt = sp and (sp.relPoint or sp.point) or "CENTER"
    local x, y = sp and sp.x or 0, sp and sp.y or 0
    if vertical then
        if full then
            local h, rh = PointPart(pt, "H"), PointPart(rpt, "H")
            if edge then h = edge == "left" and "LEFT" or "RIGHT"; rh, x = h, 0 end
            bar:SetPoint(JoinPoint("TOP", h), UIParent, JoinPoint("TOP", rh), x, 0)
            bar:SetPoint(JoinPoint("BOTTOM", h), UIParent, JoinPoint("BOTTOM", rh), x, 0)
        else
            local e = edge == "left" and "LEFT" or "RIGHT"
            bar:SetPoint(JoinPoint(PointPart(pt, "V"), e), UIParent, JoinPoint(PointPart(rpt, "V"), e), 0, y)
        end
    elseif full then
        local v, rv = PointPart(pt, "V"), PointPart(rpt, "V")
        if edge then v = edge == "top" and "TOP" or "BOTTOM"; rv, y = v, 0 end
        bar:SetPoint(JoinPoint(v, "LEFT"), UIParent, JoinPoint(rv, "LEFT"), 0, y)
        bar:SetPoint(JoinPoint(v, "RIGHT"), UIParent, JoinPoint(rv, "RIGHT"), 0, y)
    else
        local e = edge == "top" and "TOP" or "BOTTOM"
        bar:SetPoint(JoinPoint(e, PointPart(pt, "H")), UIParent, JoinPoint(e, PointPart(rpt, "H")), x, 0)
    end
end
ns.ApplyBarPosition = ApplyBarPosition

local function EnsureSlot(rec, blockCfg)
    local slot = rec.slots[blockCfg.id]
    if not slot then
        slot = CreateFrame("Frame", nil, rec.bar)
        ns.Size(slot, 10, 10)
        local content = CreateFrame("Frame", nil, slot)
        ns.Size(content, 10, 10)
        slot._edbContent = content
        rec.slots[blockCfg.id] = slot
    end
    return slot
end
local function ApplyBlockDecor(slot, blockCfg, barCfg)
    if blockCfg.bg then
        if not slot._edbBg then
            slot._edbBg = slot:CreateTexture(nil, "BACKGROUND", nil, -5)
            slot._edbBg:SetAllPoints(slot)
        end
        local c = blockCfg.bg
        ns.Solid(slot._edbBg, c.r or 0, c.g or 0, c.b or 0, c.a or 0.5)
        slot._edbBg:Show()
    elseif slot._edbBg then
        slot._edbBg:Hide()
    end
    if barCfg and barCfg.hoverHighlight then
        if not slot._edbHover then
            slot._edbHover = slot:CreateTexture(nil, "OVERLAY", nil, 6)
            slot._edbHover:SetAllPoints(slot)
            ns.Solid(slot._edbHover, 1, 1, 1, 0.04)
            slot._edbHover:Hide()
        end
        slot._edbHoverOn = true
        ns.SetupSlotHover(slot)
    else
        slot._edbHoverOn = nil
        slot:SetScript("OnUpdate", nil)
        if slot._edbHover then slot._edbHover:Hide() end
    end
end
local function AnchorContent(slot, blockCfg, vertical, barCfg)
    local content = slot._edbContent
    if not content then return end
    local s = (blockCfg.scale or 100) / 100
    if s < 0.25 then s = 0.25 elseif s > 3 then s = 3 end
    content:SetScale(s)
    content:ClearAllPoints()
    local a = blockCfg.align or "CENTER"
    local x, y = (blockCfg.xOff or 0) / s, (blockCfg.yOff or 0) / s
    local shift = slot._edbCenterShift
    if shift then
        a = "CENTER"
        if vertical then y = y - shift / s else x = x + shift / s end
    end
    if barCfg and ns.BarSizingMode(barCfg) == "auto" and blockCfg.id ~= ns.EnsureFillBlock(barCfg) then
        local gl, gr = ContentGapsOf(blockCfg)
        gl, gr = gl / s, gr / s
        if vertical then
            if a == "LEFT" then y = y - gl elseif a == "RIGHT" then y = y + gr else y = y - (gl - gr) / 2 end
        else
            if a == "LEFT" then x = x + gl elseif a == "RIGHT" then x = x - gr else x = x + (gl - gr) / 2 end
        end
    end
    if vertical then
        if a == "LEFT" then content:SetPoint("TOP", slot, "TOP", x, y)
        elseif a == "RIGHT" then content:SetPoint("BOTTOM", slot, "BOTTOM", x, y)
        else content:SetPoint("CENTER", slot, "CENTER", x, y) end
    else
        if a == "LEFT" then content:SetPoint("LEFT", slot, "LEFT", x, y)
        elseif a == "RIGHT" then content:SetPoint("RIGHT", slot, "RIGHT", x, y)
        else content:SetPoint("CENTER", slot, "CENTER", x, y) end
    end
end

function ns.ReflowBlocks(id)
    local rec = live[id]
    if not rec then return end
    Wipe(rec.assigned)
    ns.RequestLayout(id)
end
function ns.RequestLayout(id)
    if live[id] then layoutQueue[id] = true end
end

ApplyLayout = function(id)
    local rec, cfg = live[id], ns.GetBar(id)
    if not (rec and rec.bar and cfg and rec.enabled) then return end
    if InCombatLockdown() then ns.DeferUntilOOC("layout:" .. id, function() ApplyLayout(id) end); return end
    local vertical = cfg.orientation == "V"
    local barLen = vertical and rec.bar:GetHeight() or rec.bar:GetWidth()
    local len = max(1, (barLen or 0) - 2 * EDGE_PAD)
    local function measure(b)
        local inst = rec.insts[b.id]
        if inst and inst.GetAutoLength then return inst:GetAutoLength() or 0 end
        return 0
    end
    local segs = ns.SolveLayout(cfg, len, measure)
    for i = 1, #segs do
        local seg = segs[i]
        local slot = rec.slots[seg.block.id]
        if slot then
            local px = max(1, seg.px)
            local at = EDGE_PAD + (seg.at or 0)
            slot:ClearAllPoints()
            if vertical then
                ns.Size(slot, max(1, rec.bar:GetWidth()), px)
                slot:SetPoint("TOP", rec.bar, "TOP", 0, -at)
            else
                ns.Size(slot, px, max(1, rec.bar:GetHeight()))
                slot:SetPoint("LEFT", rec.bar, "LEFT", at, 0)
            end
            ns.Shown(slot, rec.contentShown ~= false)
            if slot._edbCenterShift ~= seg.contentShift then
                slot._edbCenterShift = seg.contentShift
                AnchorContent(slot, seg.block, vertical, cfg)
            end
            local prev = rec.assigned[seg.block.id]
            if prev == nil or abs(prev - px) > 0.5 then
                rec.assigned[seg.block.id] = px
                local inst = rec.insts[seg.block.id]
                if inst and inst.Refresh then inst:Refresh() end
            end
        end
    end
end
ns.ApplyLayout = function(id) return ApplyLayout(id) end

function ns.VisIsNever(cfg)
    if not cfg then return true end
    local ov = E.VisOverrideValue and E.VisOverrideValue(cfg)
    if ov then return ov == "never" end
    return cfg.visibility == "never"
end

-- Combat/group scalars ride a secure state driver: the bar hosts a secure
-- hearthstone button, so only the driver may hide it while in combat.
local function DriverFor(cfg)
    if ns.preview then return "show" end
    if ns.VisIsNever(cfg) then return "hide" end
    if E.VisOverrideValue and E.VisOverrideValue(cfg) then return "show" end
    local v = cfg.visibility
    if v == "in_combat" then return "[combat] show; hide" end
    if v == "out_of_combat" then return "[combat] hide; show" end
    if v == "in_raid" then return "[group:raid] show; hide" end
    if v == "in_party" then return "[group:raid] hide; [group:party] show; hide" end
    if v == "solo" then return "[group] hide; show" end
    return "show"
end
ns.DriverFor = DriverFor

local function DisableRecord(rec)
    for _, inst in pairs(rec.insts) do if inst.Disable then inst:Disable() end end
    if rec.bar then RegisterStateDriver(rec.bar, "visibility", "hide"); rec.driver = "hide" end
    rec.enabled = false
end

function ns.ApplyBar(id)
    if not ns.GetProfile() then return end
    local cfg, rec = ns.GetBar(id), live[id]
    if InCombatLockdown() then ns.DeferUntilOOC("applybar:" .. id, function() ns.ApplyBar(id) end); return end
    if not cfg or (ns.VisIsNever(cfg) and not ns.preview) then
        if rec and rec.enabled then DisableRecord(rec) end
        if AfterBarStateChange then AfterBarStateChange() end
        return
    end
    if not rec then
        rec = { slots = {}, insts = {}, assigned = {}, enabled = false }
        rec.bar = CreateFrame("Frame", "EllesmereUIDataBarsBar" .. id, UIParent, "SecureHandlerStateTemplate")
        rec.frame = rec.bar
        rec.bar:SetMovable(true)
        rec.bar:EnableMouse(false)
        rec.bar:SetClampedToScreen(true)
        if PP and PP.CreateBorder then rec.bar._edbBorder = PP.CreateBorder(rec.bar, 0, 0, 0, 0.8, 1, "OVERLAY", 7) end
        rec.bar:HookScript("OnSizeChanged", function() ns.RequestLayout(id) end)
        rec.ctx = MakeBarCtx(id)
        rec.ctx.frame = rec.bar
        live[id] = rec
        RegisterBarMouseoverProxy(id)
    end
    rec.bar:SetFrameStrata(cfg.barStrata or "MEDIUM")
    rec.bar:SetFrameLevel(10)
    local border = rec.bar._edbBorder
    if border and border.SetFrameLevel then border:SetFrameLevel(rec.bar:GetFrameLevel() + 1) end
    local wasDisabled = not rec.enabled
    rec.enabled = true
    rec.ctx.cfg = cfg
    local vertical = cfg.orientation == "V"
    local thickness = cfg.thickness or 30
    local length = cfg.length or 400
    if cfg.lengthMode == "full" then length = vertical and UIParent:GetHeight() or UIParent:GetWidth() end
    if vertical then ns.Size(rec.bar, thickness, length) else ns.Size(rec.bar, length, thickness) end
    ApplyBarPosition(id)
    ApplyThemeToHost(rec.bar, cfg.theme, cfg.barTexture, not cfg.hideBorder)
    local want = {}
    for i = 1, #cfg.blocks do want[cfg.blocks[i].id] = cfg.blocks[i] end
    for blockId, inst in pairs(rec.insts) do
        local b = want[blockId]
        if not b or b.type ~= inst._edbType or inst.cfg ~= b then
            if inst.Disable then inst:Disable() end
            if inst.Destroy then inst:Destroy() end
            rec.insts[blockId] = nil
            rec.assigned[blockId] = nil
            -- A rebuilt instance gets a fresh slot so the old content tree never overlaps it.
            local slot = rec.slots[blockId]
            if slot then
                slot:Hide()
                slot:SetParent(parkFrame)
                rec.slots[blockId] = nil
            end
        end
    end
    for blockId, slot in pairs(rec.slots) do if not want[blockId] then slot:Hide() end end
    for i = 1, #cfg.blocks do
        local b = cfg.blocks[i]
        b.settings = b.settings or {}
        local factory = ns.BlockFactories[b.type]
        if factory then
            local slot = EnsureSlot(rec, b)
            ApplyBlockDecor(slot, b, cfg)
            AnchorContent(slot, b, vertical, cfg)
            local inst = rec.insts[b.id]
            if not inst then
                local ok, made = pcall(factory, b, slot, slot._edbContent, rec.ctx)
                if ok and made then
                    inst = made
                    inst._edbType = b.type
                    rec.insts[b.id] = inst
                    if inst.Enable then inst:Enable() end
                elseif not ok and geterrorhandler then
                    geterrorhandler()(made)
                end
            elseif wasDisabled and inst.Enable then
                inst:Enable()
            end
        end
    end
    local driver = DriverFor(cfg)
    if rec.driver ~= driver then RegisterStateDriver(rec.bar, "visibility", driver); rec.driver = driver end
    for i = 1, #cfg.blocks do
        local inst = rec.insts[cfg.blocks[i].id]
        if inst and inst.Refresh then
            local ok, err = pcall(inst.Refresh, inst)
            if not ok and geterrorhandler then geterrorhandler()(err) end
        end
    end
    ApplyLayout(id)
    if AfterBarStateChange then AfterBarStateChange() end
end

-- Hover wash: an OnUpdate-free mouse poll on the slot (slots never take the
-- mouse, so block buttons keep receiving clicks underneath).
function ns.SetupSlotHover(slot)
    local elapsed = 0
    slot:SetScript("OnUpdate", function(self, dt)
        if not self._edbHoverOn then return end
        elapsed = elapsed + (dt or 0)
        if elapsed < 0.05 then return end
        elapsed = 0
        if self._edbHover then ns.Shown(self._edbHover, ns.MouseOver(self)) end
    end)
end

function ns.ApplyTheme(id)
    local rec, cfg = live[id], ns.GetBar(id)
    if rec and rec.bar and cfg then ApplyThemeToHost(rec.bar, cfg.theme, cfg.barTexture, not cfg.hideBorder) end
end
function ns.GetLiveAutoLength(barId, blockId)
    local rec = live[barId]
    local inst = rec and rec.insts[blockId]
    if inst and inst.GetAutoLength then return inst:GetAutoLength() end
end
function ns.NormalizedShare(barCfg, blockId)
    if not barCfg or #barCfg.blocks == 0 then return 0 end
    local rec = live[barCfg.id]
    local len
    if rec and rec.bar then len = barCfg.orientation == "V" and rec.bar:GetHeight() or rec.bar:GetWidth() end
    if not len or len < 2 then
        if barCfg.lengthMode == "full" then len = barCfg.orientation == "V" and UIParent:GetHeight() or UIParent:GetWidth()
        else len = barCfg.length or 400 end
    end
    len = max(1, len - 2 * EDGE_PAD)
    local segs = ns.SolveLayout(barCfg, len, function(b)
        local inst = rec and rec.insts[b.id]
        if inst and inst.GetAutoLength then return inst:GetAutoLength() or 0 end
        return 0
    end)
    for i = 1, #segs do if segs[i].block.id == blockId then return segs[i].px * 100 / len end end
    return 0
end

-------------------------------------------------------------------------------
--  Visibility runtime (alpha + content gate; secure driver handles combat)
-------------------------------------------------------------------------------
ns.EDB_VIS_CAPS = { partyIncludesRaid = false, luaDragonriding = false }
local function SetBarAlphaVisible(rec, visible) if rec and rec.bar then rec.bar:SetAlpha(visible and 1 or 0) end end
local function SetBarContentShown(id, shown)
    local rec = live[id]
    if not rec then return end
    shown = shown and true or false
    if (rec.contentShown ~= false) == shown and not rec.contentDeferred then return end
    rec.contentShown = shown
    rec.contentDeferred = nil
    local inCombat = InCombatLockdown()
    local function apply(slot, s)
        if inCombat and slot.IsProtected and slot:IsProtected() then rec.contentDeferred = true
        elseif slot:IsShown() ~= s then ns.Shown(slot, s) end
    end
    if not shown then
        for _, slot in pairs(rec.slots) do apply(slot, false) end
    else
        local cfg = rec.ctx and rec.ctx.cfg
        if cfg then for i = 1, #cfg.blocks do local slot = rec.slots[cfg.blocks[i].id]; if slot then apply(slot, true) end end end
    end
end
local _editHL
function ns.SetBlockEditHighlight(barId, blockId)
    if _editHL then
        local rec = live[_editHL.barId]
        local slot = rec and rec.slots[_editHL.blockId]
        if slot and slot._edbEditHL then slot._edbEditHL:Hide() end
        _editHL = nil
    end
    if not (barId and blockId) then return end
    local rec = live[barId]
    local slot = rec and rec.slots[blockId]
    if not slot then return end
    if not slot._edbEditHL then
        local t = slot:CreateTexture(nil, "OVERLAY", nil, 6)
        t:SetAllPoints(slot)
        ns.Solid(t, 1, 1, 1, 0.15)
        slot._edbEditHL = t
    end
    slot._edbEditHL:Show()
    _editHL = { barId = barId, blockId = blockId }
end

local visRuntime = {}
do
    local _inCombat = false
    local st = {}
    local function LegacyScalar(mode)
        mode = mode or "always"
        if mode == "always" then return true end
        if mode == "never" then return false end
        if mode == "mouseover" then return "mouseover" end
        if mode == "in_combat" then return _inCombat end
        if mode == "out_of_combat" then return not _inCombat end
        local inRaid, inGroup = ns.InRaid(), ns.InGroup()
        if mode == "in_raid" then return inRaid end
        if mode == "in_party" then return inGroup and not inRaid end
        if mode == "solo" then return not inGroup end
        return true
    end
    ns.LegacyScalar = LegacyScalar
    function ns.UpdateAllBarVisibility()
        local profile = ns.GetProfile()
        if not profile then return end
        for _, cfg in ipairs(profile.bars) do
            local rec = live[cfg.id]
            if rec and rec.enabled then
                local vis
                if ns.preview then
                    vis = true
                elseif E.CheckVisibilityOptions and E.CheckVisibilityOptions(cfg) then
                    vis = false
                else
                    st.inCombat = _inCombat
                    st.inRaid = ns.InRaid()
                    st.inParty = (not st.inRaid) and ns.InGroup()
                    local ext = E.EvalVisibilityExtended and E.EvalVisibilityExtended(cfg, "visibility", st, ns.EDB_VIS_CAPS)
                    if ext ~= nil then vis = ext else vis = LegacyScalar(cfg.visibility) end
                    -- The secure driver already shows/hides these scalars; alpha stays on.
                    local v = cfg.visibility
                    if ext == nil and (v == "in_combat" or v == "out_of_combat" or v == "in_raid" or v == "in_party" or v == "solo") then vis = true end
                end
                if vis == "mouseover" then
                    ns._moEligible[cfg.id] = true
                    SetBarAlphaVisible(rec, false)
                    SetBarContentShown(cfg.id, false)
                else
                    ns._moEligible[cfg.id] = nil
                    SetBarAlphaVisible(rec, vis and true or false)
                    SetBarContentShown(cfg.id, vis and true or false)
                end
            else
                ns._moEligible[cfg.id] = nil
            end
        end
    end
    function ns.SetVisCombat(v) _inCombat = v and true or false end
    local visFrame
    local VIS_EVENTS = { "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_TARGET_CHANGED",
        "PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE", "ZONE_CHANGED_NEW_AREA", "UPDATE_SHAPESHIFT_FORM",
        "PLAYER_ENTERING_WORLD", "PLAYER_UPDATE_RESTING", "UNIT_ENTERED_VEHICLE", "UNIT_EXITED_VEHICLE",
        "COMPANION_UPDATE" }
    local function OnVisEvent(_, event)
        if event == "PLAYER_REGEN_DISABLED" then _inCombat = true
        elseif event == "PLAYER_REGEN_ENABLED" then _inCombat = false
        elseif event == "PLAYER_ENTERING_WORLD" then _inCombat = InCombatLockdown() and true or false end
        ns.UpdateAllBarVisibility()
    end
    function visRuntime.UpdateEventRegistration()
        local any = false
        for _, cfg in ipairs(ns.BarsInOrder()) do if not ns.VisIsNever(cfg) then any = true; break end end
        if any then
            if not visFrame then visFrame = CreateFrame("Frame"); visFrame:SetScript("OnEvent", OnVisEvent) end
            for _, e in ipairs(VIS_EVENTS) do pcall(visFrame.RegisterEvent, visFrame, e) end
            _inCombat = InCombatLockdown() and true or false
        elseif visFrame then
            visFrame:UnregisterAllEvents()
        end
    end
    local moRegistered = {}
    RegisterBarMouseoverProxy = function(id)
        if moRegistered[id] or not E.RegisterMouseoverTarget then return end
        moRegistered[id] = true
        local proxy = {}
        function proxy.GetRect() local rec = live[id]; if rec and rec.bar and rec.bar:IsShown() then return rec.bar:GetRect() end end
        function proxy.GetEffectiveScale() local rec = live[id]; return rec and rec.bar and rec.bar:GetEffectiveScale() or 1 end
        function proxy.SetAlpha() end
        function proxy.EnableMouse() end
        function proxy.Show() local rec = live[id]; if rec and rec.bar then SetBarAlphaVisible(rec, true); SetBarContentShown(id, true) end end
        function proxy.Hide() local rec = live[id]; if rec and rec.bar then SetBarAlphaVisible(rec, false); SetBarContentShown(id, false) end end
        ns._moProxies = ns._moProxies or {}
        ns._moProxies[id] = proxy
        E.RegisterMouseoverTarget(proxy, function() return ns._moEligible[id] and true or false end)
    end
end

local dispRuntime = {}
do
    local dispFrame
    function dispRuntime.UpdateEventRegistration()
        local any = false
        for _, cfg in ipairs(ns.BarsInOrder()) do
            if not ns.VisIsNever(cfg) and cfg.lengthMode == "full" then any = true; break end
        end
        if any then
            if not dispFrame then
                dispFrame = CreateFrame("Frame")
                dispFrame:SetScript("OnEvent", function()
                    ns.WipeFitCache()
                    for _, cfg in ipairs(ns.BarsInOrder()) do if cfg.lengthMode == "full" then ns.ApplyBar(cfg.id) end end
                end)
            end
            dispFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
            dispFrame:RegisterEvent("UI_SCALE_CHANGED")
        elseif dispFrame then
            dispFrame:UnregisterAllEvents()
        end
    end
end

AfterBarStateChange = function()
    visRuntime.UpdateEventRegistration()
    dispRuntime.UpdateEventRegistration()
    ns.UpdateAllBarVisibility()
    local ab = E._ModuleNS and E._ModuleNS.EllesmereUIActionBars
    if ab and ab.NativeHUD and ab.NativeHUD.UpdateData then pcall(ab.NativeHUD.UpdateData) end
end
ns.AfterBarStateChange = function() AfterBarStateChange() end

-- XP/reputation hand-off read by the ActionBars native HUD: an XP/Rep block on
-- a live bar replaces the corresponding EUI progress holder.
function ns.ResolveProgressMode(mode)
    mode = mode or "auto"
    if mode == "reputation" then mode = "rep" end
    if mode == "auto" then
        mode = (UnitLevel("player") or 0) < (MAX_PLAYER_LEVEL or 80) and "xp" or "rep"
    end
    return mode
end
function ns.ProgressUsed(key)
    if key == "reputation" then key = "rep" end
    for _, cfg in ipairs(ns.BarsInOrder()) do
        local rec = live[cfg.id]
        if rec and rec.enabled and not ns.VisIsNever(cfg) then
            for _, b in ipairs(cfg.blocks) do
                if b.type == "xprep" and ns.ResolveProgressMode(b.settings and b.settings.mode) == key then return true end
            end
        end
    end
    return false
end

-------------------------------------------------------------------------------
--  Unlock Mode: one mover per bar ("EDB_<id>") + Element Options deep link
-------------------------------------------------------------------------------
ns.registered = {}
local function MakeBarElement(barId, orderIdx)
    local function cfgOf() return ns.GetBar(barId) end
    local c = cfgOf()
    return E.MakeUnlockElement({
        key = "EDB_" .. barId, label = (c and c.name) or ("DataBar " .. barId),
        group = "DataBars", order = 700 + orderIdx, noInitHook = true,
        getFrame = function() local rec = live[barId]; if rec and rec.enabled and cfgOf() then return rec.bar end end,
        getSize = function()
            local rec = live[barId]
            if rec and rec.bar then return rec.bar:GetWidth(), rec.bar:GetHeight() end
            return 0, 0
        end,
        savePos = function(_, pt, rpt, x, y)
            local cfg = cfgOf()
            if not cfg then return end
            cfg.savedPos = { point = pt, relPoint = rpt, x = x, y = y }
            if cfg.snapEdge and cfg.snapEdge ~= "none" then cfg.snapEdge = "none" end
        end,
        loadPos = function()
            local sp = cfgOf() and cfgOf().savedPos
            if not (sp and sp.point) then return nil end
            return { point = sp.point, relPoint = sp.relPoint, x = sp.x, y = sp.y }
        end,
        clearPos = function() local cfg = cfgOf(); if cfg then cfg.savedPos = nil end end,
        applyPos = function() ApplyBarPosition(barId) end,
        setWidth = function(_, w)
            local cfg = cfgOf()
            if not cfg then return end
            w = max(16, floor((w or 0) + 0.5))
            if cfg.orientation == "V" then cfg.thickness = w
            else if cfg.lengthMode == "full" then return end; cfg.length = w end
            ns.ApplyBar(barId)
        end,
        setHeight = function(_, h)
            local cfg = cfgOf()
            if not cfg then return end
            h = max(16, floor((h or 0) + 0.5))
            if cfg.orientation == "V" then if cfg.lengthMode == "full" then return end; cfg.length = h
            else cfg.thickness = h end
            ns.ApplyBar(barId)
        end,
        isHidden = function() return cfgOf() == nil end,
        allowMatchSource = true,
    })
end
function ns.RegisterAllUnlockElements()
    local profile = ns.GetProfile()
    if not profile then return end
    E._ELEMENT_SETTINGS_MAP = E._ELEMENT_SETTINGS_MAP or {}
    local elements = {}
    for i, cfg in ipairs(profile.bars) do
        local barId = cfg.id
        E._ELEMENT_SETTINGS_MAP["EDB_" .. barId] = { module = ADDON, page = "DataBars", sectionName = "BAR SETTINGS",
            highlightText = "Visibility",
            preSelectFn = function() local p = ns.GetProfile(); if p and ns.GetBar(barId) then p.selectedBarId = barId end end }
        if E.MakeUnlockElement then
            local elem = MakeBarElement(barId, i)
            elements[#elements + 1] = elem
            ns.registered[barId] = elem
        end
    end
    if #elements > 0 and E.RegisterUnlockElements then E:RegisterUnlockElements(elements, ADDON) end
end

-------------------------------------------------------------------------------
--  Templates + CRUD
-------------------------------------------------------------------------------
local TEMPLATES = {
    bottom = {
        name = "Bottom Info Bar", orientation = "H", lengthMode = "full", length = 1200, thickness = 30,
        theme = "eui", snapEdge = "top", sizingMode = "auto", fillType = "clock", centerType = "clock",
        savedPos = { point = "BOTTOM", relPoint = "BOTTOM", x = 0, y = 0 },
        blocks = {
            { type = "micromenu", textYOff = 8, contentGapR = 40, settings = { help = false } },
            { type = "xprep", contentGapL = 40, contentGapR = 40 },
            { type = "spec", contentGapL = 40, contentGapR = 40 },
            { type = "durability", contentGapL = 40, contentGapR = 40, useIconDefaultColor = true, iconColor = { r = 1, g = 0.62, b = 0.25 } },
            { type = "clock", scale = 90, settings = { twentyFour = false } },
            { type = "profession", contentGapL = 40, contentGapR = 40, align = "LEFT", textXOff = 0, useIconAccentColor = true, iconColor = { r = 1, g = 0.55, b = 0.25 } },
            { type = "gold", contentGapL = 40, contentGapR = 40, useCoinColor = true, coinForced = true, useIconDefaultColor = true,
              color = { r = 1, g = 1, b = 1 }, iconColor = { r = 1, g = 1, b = 1 } },
            { type = "fps", contentGapL = 40, contentGapR = 0 },
            { type = "ms", contentGapL = 0, contentGapR = 40 },
            { type = "travel", align = "RIGHT", xOff = -5, contentGapL = 40, useIconDefaultColor = true,
              iconColor = { r = 0.35, g = 0.72, b = 1 }, settings = { hsChoice = "random" } },
        },
    },
    minimapc = {
        name = "Minimap Companion", orientation = "H", lengthMode = "custom", length = 220, thickness = 24,
        theme = "modern", sizingMode = "even",
        savedPos = { point = "TOPRIGHT", relPoint = "TOPRIGHT", x = -4, y = -240 },
        blocks = { { type = "clock" }, { type = "fps" }, { type = "ms" } },
    },
    microstrip = {
        name = "Micro Menu Strip", orientation = "H", lengthMode = "custom", length = 420, thickness = 28,
        theme = "modern", sizingMode = "auto",
        savedPos = { point = "BOTTOMRIGHT", relPoint = "BOTTOMRIGHT", x = -4, y = 4 },
        blocks = { { type = "micromenu" } },
    },
    empty = {
        name = "New DataBar", orientation = "H", lengthMode = "custom", length = 400, thickness = 30,
        theme = "eui", sizingMode = "auto", blocks = {},
    },
}
ns.TEMPLATES = TEMPLATES
local function UniqueBarName(base)
    local bars = ns.BarsInOrder()
    local function taken(n) for i = 1, #bars do if bars[i].name == n then return true end end end
    if not taken(base) then return base end
    local n = 2
    while taken(base .. " " .. n) do n = n + 1 end
    return base .. " " .. n
end
local function Structural() return InCombatLockdown() end

function ns.AddBlock(barId, typeKey, noApply)
    if Structural() then return nil end
    local cfg = ns.GetBar(barId)
    if not cfg or not ns.BLOCK_DEFAULTS[typeKey] then return nil end
    cfg.nextBlockId = (cfg.nextBlockId or 0) + 1
    local b = { id = cfg.nextBlockId, type = typeKey, align = "CENTER", xOff = 0, yOff = 0,
        settings = Copy(ns.BLOCK_DEFAULTS[typeKey]) }
    if typeKey == "micromenu" then b.textYOff = 8 end
    cfg.blocks[#cfg.blocks + 1] = b
    if not noApply then ns.ApplyBar(barId) end
    return b
end
function ns.RemoveBlock(barId, blockId)
    if Structural() then return end
    local cfg = ns.GetBar(barId)
    if not cfg then return end
    for i = 1, #cfg.blocks do if cfg.blocks[i].id == blockId then tremove(cfg.blocks, i); break end end
    if cfg.centerBlockId == blockId then cfg.centerBlockId = nil end
    ns.ApplyBar(barId)
end
function ns.MoveBlock(barId, blockId, delta)
    if Structural() then return end
    local cfg = ns.GetBar(barId)
    local _, idx = GetBlock(cfg, blockId)
    if not idx then return end
    local target = idx + (delta or 0)
    if target < 1 or target > #cfg.blocks then return end
    cfg.blocks[idx], cfg.blocks[target] = cfg.blocks[target], cfg.blocks[idx]
    ns.ApplyBar(barId)
end
function ns.MoveBlockTo(barId, blockId, newIndex)
    if Structural() then return end
    local cfg = ns.GetBar(barId)
    if not cfg then return end
    local _, from = GetBlock(cfg, blockId)
    if not from then return end
    local b = tremove(cfg.blocks, from)
    local to = newIndex or (from + 1)
    if to > from then to = to - 1 end
    to = max(1, min(#cfg.blocks + 1, to))
    table.insert(cfg.blocks, to, b)
    ns.ApplyBar(barId)
end
function ns.SetFillBlock(barId, blockId)
    local cfg = ns.GetBar(barId)
    if not GetBlock(cfg, blockId) then return end
    cfg.fillBlockId = blockId
    ns.ApplyBar(barId)
end
function ns.SetCenterBlock(barId, blockId)
    local cfg = ns.GetBar(barId)
    if not cfg then return end
    if blockId ~= nil and not GetBlock(cfg, blockId) then return end
    cfg.centerBlockId = blockId
    ns.ApplyBar(barId)
end
function ns.TransferPct(barId, aId, bId, newA)
    local cfg = ns.GetBar(barId)
    local a, b = GetBlock(cfg, aId), GetBlock(cfg, bId)
    if not (a and b) then return end
    local budget = (a.widthPct or 10) + (b.widthPct or 10)
    local w = max(0, min(budget, newA or budget / 2))
    a.widthPct, b.widthPct = w, budget - w
    ns.RequestLayout(barId)
end

function ns.CreateBar(templateKey)
    if Structural() then return nil end
    local profile = ns.GetProfile()
    if not profile then return nil end
    local t = TEMPLATES[templateKey] or TEMPLATES.empty
    profile.nextBarId = (profile.nextBarId or 0) + 1
    local id = profile.nextBarId
    local sp = t.savedPos and { point = t.savedPos.point, relPoint = t.savedPos.relPoint, x = t.savedPos.x, y = t.savedPos.y }
    local cfg = {
        id = id, name = UniqueBarName(t.name), orientation = t.orientation, lengthMode = t.lengthMode,
        length = t.length, thickness = t.thickness, snapEdge = t.snapEdge, sizingMode = t.sizingMode,
        fontScale = 100, theme = { style = t.theme, euiAlpha = 0.5, modernColor = { r = 0.067, g = 0.067, b = 0.067, a = 0.95 } },
        visibility = "always", savedPos = sp, nextBlockId = 0, blocks = {},
    }
    profile.bars[#profile.bars + 1] = cfg
    for _, bt in ipairs(t.blocks) do
        local b = ns.AddBlock(id, bt.type, true)
        if b then
            for k, v in pairs(bt) do
                if k == "settings" then for sk, sv in pairs(v) do b.settings[sk] = Copy(sv) end
                elseif k ~= "type" then b[k] = Copy(v) end
            end
        end
    end
    if t.fillType then for _, b in ipairs(cfg.blocks) do if b.type == t.fillType then cfg.fillBlockId = b.id; break end end end
    if t.centerType then for _, b in ipairs(cfg.blocks) do if b.type == t.centerType then cfg.centerBlockId = b.id; break end end end
    profile.selectedBarId = id
    ns.selectedBarId = id
    ns.ApplyBar(id)
    ns.RegisterAllUnlockElements()
    return cfg
end
function ns.DeleteBar(id)
    if Structural() then return end
    local profile = ns.GetProfile()
    if not profile then return end
    for i = 1, #profile.bars do if profile.bars[i].id == id then tremove(profile.bars, i); break end end
    local rec = live[id]
    if rec then
        for _, inst in pairs(rec.insts) do
            if inst.Disable then inst:Disable() end
            if inst.Destroy then inst:Destroy() end
        end
        Wipe(rec.insts)
        RegisterStateDriver(rec.bar, "visibility", "hide")
        rec.driver = "hide"
        rec.enabled = false
        live[id] = nil
        ns._retired = ns._retired or {}
        ns._retired[id] = rec
    end
    ns._moEligible[id] = nil
    if profile.selectedBarId == id then profile.selectedBarId = profile.bars[1] and profile.bars[1].id end
    ns.selectedBarId = profile.selectedBarId
    AfterBarStateChange()
end
function ns.RenameBar(id, name)
    local cfg = ns.GetBar(id)
    if not cfg or type(name) ~= "string" then return end
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return end
    cfg.name = name
    local elem = ns.registered[id]
    if elem then elem.label = name end
    ns.RegisterAllUnlockElements()
end

-------------------------------------------------------------------------------
--  Currency discovery (Wrath token list; collapsed headers restored)
-------------------------------------------------------------------------------
function ns.CurrencyKey(name, itemID, extra)
    if itemID and itemID > 0 then return itemID end
    if extra and extra > 0 then return "pvp" .. extra end
    return name
end
function ns.Currencies()
    local rows = {}
    if not (GetCurrencyListSize and GetCurrencyListInfo) then return rows end
    local collapsed = {}
    local i = 1
    while i <= GetCurrencyListSize() do
        local name, isHeader, isExpanded = GetCurrencyListInfo(i)
        if name and isHeader and not isExpanded and ExpandCurrencyList then
            collapsed[#collapsed + 1] = i
            ExpandCurrencyList(i, 1)
        end
        i = i + 1
    end
    for idx = 1, GetCurrencyListSize() do
        local name, isHeader, _, _, isWatched, count, extra, icon, itemID = GetCurrencyListInfo(idx)
        if name and not isHeader then
            if extra == 1 then icon = icon or "Interface\\PVPFrame\\PVP-ArenaPoints-Icon"
            elseif extra == 2 then icon = icon or ("Interface\\TargetingFrame\\UI-PVP-" .. (UnitFactionGroup("player") or "Horde")) end
            if icon and not icon:find("\\") then icon = "Interface\\Icons\\" .. icon end
            rows[#rows + 1] = { key = ns.CurrencyKey(name, itemID, extra), name = name, count = count or 0,
                icon = icon, itemID = itemID, extra = extra, watched = isWatched, index = idx }
        end
    end
    for k = #collapsed, 1, -1 do ExpandCurrencyList(collapsed[k], 0) end
    return rows
end
function ns.BuildCurrencyList()
    local values, order = {}, {}
    for _, r in ipairs(ns.Currencies()) do
        if values[r.key] == nil then values[r.key] = r.name; order[#order + 1] = r.key end
    end
    return values, order
end

-------------------------------------------------------------------------------
--  LibDataBroker: only EllesmereUI's own data objects (no other addon data)
-------------------------------------------------------------------------------
local _ldb
function ns.GetLDB()
    if _ldb then return _ldb end
    if not LibStub then return nil end
    _ldb = LibStub:GetLibrary("LibDataBroker-1.1", true)
    return _ldb
end
function ns.IsOwnBroker(name) return type(name) == "string" and name:find("^EllesmereUI") ~= nil end
function ns.LDBLabel(name, obj)
    local lbl = obj and obj.label
    if type(lbl) == "string" and lbl ~= "" and lbl ~= name then return name .. " |cff808080(" .. lbl .. ")|r" end
    return name
end
function ns.BuildLDBList()
    local values, order = {}, {}
    local LDB = ns.GetLDB()
    if not LDB then return values, order end
    for name, obj in LDB:DataObjectIterator() do
        if ns.IsOwnBroker(name) then values[name] = ns.LDBLabel(name, obj); order[#order + 1] = name end
    end
    tsort(order, function(a, b) return a:lower() < b:lower() end)
    return values, order
end

-------------------------------------------------------------------------------
--  0.2 -> Retail profile shape migration (one shot per profile)
-------------------------------------------------------------------------------
local VIS_MAP = { combat = "in_combat", outofcombat = "out_of_combat", group = "in_party" }
local AUDIO_MAP = { Master = "master", SFX = "sfx", Music = "music", Ambience = "ambience" }
function ns.MigrateProfile(p)
    if not p or (p.schema or 1) >= 2 then return end
    local masterOff = p.enabled == false
    for _, cfg in ipairs(p.bars or {}) do
        if type(cfg.theme) ~= "table" then
            local alpha = cfg.bgAlpha or 0.92
            cfg.theme = { style = cfg.theme == "modern" and "modern" or "eui", euiAlpha = 0.5, euiOpacity = alpha,
                modernColor = { r = 0.067, g = 0.067, b = 0.067, a = alpha } }
        end
        if cfg.enabled == false or masterOff then cfg.visibility = "never"
        else cfg.visibility = VIS_MAP[cfg.visibility] or cfg.visibility or "always" end
        cfg.sizingMode = cfg.sizingMode == "even" and "even" or "auto"
        cfg.enabled, cfg.bgAlpha, cfg.spacing, cfg.fontSize, cfg.scale = nil, nil, nil, nil, nil
        for _, b in ipairs(cfg.blocks or {}) do
            b.settings = b.settings or {}
            local s = b.settings
            b.width = nil
            b.align = b.align or "CENTER"
            if b.type == "xprep" and s.mode == "reputation" then s.mode = "rep" end
            if b.type == "audio" then s.channel = AUDIO_MAP[s.channel] or s.channel or "master" end
            if b.type == "currency" and s.currencyKey then
                s.currencyId = tonumber(s.currencyKey) or (s.currencyKey ~= "" and s.currencyKey or nil)
                s.currencyKey = nil
            end
            local d = ns.BLOCK_DEFAULTS[b.type]
            if d then for k, v in pairs(d) do if s[k] == nil then s[k] = Copy(v) end end end
        end
    end
    p.enabled = nil
    p.schema = 2
end

-------------------------------------------------------------------------------
--  Lifecycle
-------------------------------------------------------------------------------
local function ApplyAll()
    local profile = ns.GetProfile()
    if not profile then return end
    if InCombatLockdown() then ns.DeferUntilOOC("applyall", ApplyAll); return end
    ns.MigrateProfile(profile)
    if not profile.initialized then
        profile.initialized = true
        if #profile.bars == 0 then ns.CreateBar("bottom"); return end
    end
    ns.WipeFitCache()
    local active = {}
    for _, cfg in ipairs(profile.bars) do active[cfg.id] = true end
    for id, rec in pairs(live) do
        if not active[id] then
            DisableRecord(rec)
            live[id] = nil
        end
    end
    for _, cfg in ipairs(profile.bars) do ns.ApplyBar(cfg.id) end
    for _, cfg in ipairs(profile.bars) do ApplyLayout(cfg.id) end
    ns.RegisterAllUnlockElements()
    AfterBarStateChange()
end
ns.Apply = ApplyAll
function ns.Update()
    for _, rec in pairs(live) do
        if rec.enabled then for _, inst in pairs(rec.insts) do if inst.Refresh then pcall(inst.Refresh, inst) end end end
    end
end
_G._EDB_Apply = ApplyAll
_G._EDB_RegisterUnlock = function() ns.RegisterAllUnlockElements() end

function addon:OnInitialize()
    -- Lua 5.1 xpcall in the Core lifecycle does not forward its addon argument.
    addon.db = E.Lite.NewDB("EllesmereUIDataBarsDB", defaults)
    ns.db = addon.db
    if addon.db.profile then addon.db.profile.characters = nil end
end
function addon:OnEnable()
    ns.events = runtime
    runtime:RegisterEvent("PLAYER_REGEN_ENABLED")
    runtime:RegisterEvent("PLAYER_REGEN_DISABLED")
    runtime:RegisterEvent("PLAYER_ENTERING_WORLD")
    runtime:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" then
            if ns.SetVisCombat then ns.SetVisCombat(false) end
            ns.FlushDeferred()
            ns.FlushLayouts()
            ns.UpdateAllBarVisibility()
        elseif event == "PLAYER_REGEN_DISABLED" then
            if ns.SetVisCombat then ns.SetVisCombat(true) end
        elseif event == "PLAYER_ENTERING_WORLD" then
            ns.Update()
        end
    end)
    ApplyAll()
    if E.RegisterUnlockModeListener then
        E:RegisterUnlockModeListener(ADDON, function(active)
            ns.preview = active and true or nil
            if InCombatLockdown() then return end
            for _, cfg in ipairs(ns.BarsInOrder()) do ns.ApplyBar(cfg.id) end
            AfterBarStateChange()
        end)
    end
end

if E.PartySpin_Create then
    local groups, groupOf = {}, setmetatable({}, { __mode = "k" })
    pcall(E.PartySpin_Create, {
        target = "dataBars",
        collect = function()
            Wipe(groups)
            for _, rec in pairs(live) do
                if rec.enabled and rec.bar and rec.slots then
                    local grp = groupOf[rec]
                    if not grp then grp = { frames = {} }; groupOf[rec] = grp end
                    grp.pivot = rec.bar
                    Wipe(grp.frames)
                    for _, slot in pairs(rec.slots) do grp.frames[#grp.frames + 1] = slot end
                    groups[#groups + 1] = grp
                end
            end
            return groups
        end,
    })
end
if E.RegisterVisEdge then E.RegisterVisEdge(function() if ns.UpdateAllBarVisibility then ns.UpdateAllBarVisibility() end end) end

SLASH_EUI335DATABARS1 = "/edb"
SlashCmdList.EUI335DATABARS = function()
    if E.EnsureOptionsLoaded then E.EnsureOptionsLoaded() end
    if E.ShowModule then E:ShowModule(ADDON) end
end
