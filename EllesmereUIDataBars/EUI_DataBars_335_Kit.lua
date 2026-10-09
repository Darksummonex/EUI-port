-- EllesmereUIDataBars 3.3.5: shared block scaffolding (port of Retail Blocks\Shared.lua).
-- Contract (engine calls, see EUI_DataBars_335.lua):
--   ns.BlockFactories[typeKey] = function(blockCfg, slot, content, barCtx) -> inst
--   inst:Refresh() / Enable() / Disable() / GetAutoLength() (0 = collapsed) / Destroy()
local _, ns = ...
if not ns.IsWrath then return end
local E = EllesmereUI
local CreateFrame, InCombatLockdown, pcall, type, abs = CreateFrame, InCombatLockdown, pcall, type, math.abs

local K = {}
ns.BlockKit = K

local ICON_GAP = 8
local CONTENT_BASE = 30

local barTextures, barTextureNames, barTextureOrder
if E.BuildBarTextureTables then barTextures, barTextureNames, barTextureOrder = E.BuildBarTextureTables(true) end
barTextures = barTextures or { none = nil }
barTextureNames = barTextureNames or { none = "None" }
barTextureOrder = barTextureOrder or { "none" }
ns.barTextures, ns.barTextureNames, ns.barTextureOrder = barTextures, barTextureNames, barTextureOrder
if E.AppendSharedMediaTextures then pcall(E.AppendSharedMediaTextures, barTextureNames, barTextureOrder, nil, barTextures) end

local function InstKey(barCtx, blockCfg) return "EDB" .. barCtx.id .. "_" .. blockCfg.id end

local function MakeEventFrame(inst, handler)
    local f = CreateFrame("Frame")
    f:SetScript("OnEvent", function(_, event, ...) handler(inst, event, ...) end)
    return f
end
local function RegisterInstEvents(inst)
    if not (inst.eventFrame and inst.events) then return end
    for i = 1, #inst.events do pcall(inst.eventFrame.RegisterEvent, inst.eventFrame, inst.events[i]) end
end
local function UnregisterInstEvents(inst) if inst.eventFrame then inst.eventFrame:UnregisterAllEvents() end end

local function ContentScaleOf(inst)
    local s = ((inst.cfg and inst.cfg.scale) or 100) / 100
    if s <= 0 then return 1 end
    return s
end
local function HBudget(inst, fallback)
    local w = inst.slot and inst.slot:GetWidth()
    if w and w > 8 then return w / ContentScaleOf(inst) end
    return fallback
end
local function VSlotW(inst)
    local w = inst.slot and inst.slot:GetWidth()
    if w and w > 2 then return w / ContentScaleOf(inst) end
    return inst.ctx.GetThickness()
end

-- Re-layout only when the measured auto extent changed (breaks Refresh -> layout -> Refresh).
local function MaybeRelayout(inst)
    local b = inst.cfg
    local barCfg = inst.ctx and inst.ctx.cfg
    if not barCfg then return end
    local w = 0
    if inst.GetAutoLength then w = inst:GetAutoLength() or 0 end
    if ns.BarSizingMode(barCfg) ~= "auto" then
        local was = inst._lastAuto
        inst._lastAuto = w
        if was ~= nil and ((was <= 0) ~= (w <= 0)) then inst.ctx.RequestLayout() end
        return
    end
    if barCfg.fillBlockId == b.id then return end
    if inst._lastAuto == nil or abs(w - inst._lastAuto) > 0.5 then
        inst._lastAuto = w
        inst.ctx.RequestLayout()
    end
end

-- Text-only X/Y offset: wraps a primary FontString's SetPoint so every anchor carries the live cfg offset.
local function AttachTextOffset(inst, fs)
    if not fs or fs._edbTxo then return end
    fs._edbTxo = true
    local orig = fs.SetPoint
    fs.SetPoint = function(self, point, a2, a3, a4, a5)
        local c = inst.cfg
        local dx = (c and c.textXOff) or 0
        local dy = (c and c.textYOff) or 0
        if a2 == nil then return orig(self, point, dx, dy) end
        if type(a2) == "number" then return orig(self, point, a2 + dx, (a3 or 0) + dy) end
        return orig(self, point, a2, a3 or point, (a4 or 0) + dx, (a5 or 0) + dy)
    end
end

local function ClassRGB()
    local _, classFile = UnitClass("player")
    local cc = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if cc then return cc.r, cc.g, cc.b end
end

local function BlockColorOf(b)
    if b.useDynamicColor then return ns.BlockTextDynamic(b.type) end
    if b.useClassColor then
        local r, g, bl = ClassRGB()
        if r then return r, g, bl end
    elseif b.useAccentColor then
        return ns.GetAccent()
    end
    local c = b.color
    if c then return c.r or 1, c.g or 1, c.b or 1 end
    if ns.TEXT_DYNAMIC_DEFAULT[b.type] then return ns.BlockTextDynamic(b.type) end
    return 1, 1, 1
end

-- Wrath GetZonePVPInfo() returns the same ruleset tokens as Retail C_PvP.GetZonePVPInfo.
local function ZoneReactionColor()
    local pvpType = GetZonePVPInfo and GetZonePVPInfo()
    if pvpType == "friendly" then return 0.05, 0.85, 0.03
    elseif pvpType == "sanctuary" then return 0.035, 0.58, 0.84
    elseif pvpType == "arena" or pvpType == "hostile" or pvpType == "combat" then return 0.84, 0.03, 0.03 end
    return 0.9, 0.85, 0.05
end

-- Item-level tint bands for Wrath gear tiers (Naxx 200 -> ICC heroic 277), item-quality colors.
local ILVL_BANDS = {
    { 264, 1, 0.502, 0 }, { 245, 0.639, 0.208, 0.933 }, { 226, 0, 0.439, 0.867 }, { 200, 0.118, 1, 0 },
}
K.lastAvgIlvl = nil
K.lastDurabilityPct = nil

local ICON_DEFAULTS = {
    gold = { 0.886, 0.675, 0.478 }, bags = { 0.886, 0.675, 0.478 }, travel = { 0.596, 0.804, 0.961 },
    currency = { 0.886, 0.675, 0.478 }, audio = { 1, 1, 1 }, location = { 0.918, 0.263, 0.208 },
    coords = { 0.961, 0.784, 0.259 }, ilvl = { 1, 1, 1 },
}
function ns.BlockIconDefault(bType)
    if bType == "spec" then
        local r, g, b = ClassRGB()
        return r or 1, g or 1, b or 1
    end
    if bType == "profession" or bType == "profession2" then return ns.GetAccent() end
    if bType == "durability" then
        local pct = K.lastDurabilityPct or 100
        local t = (pct - 20) * (100 / 80)
        if t < 0 then t = 0 elseif t > 100 then t = 100 end
        local gb = 0.35 + 0.65 * (t / 100)
        return 1, gb, gb
    end
    local d = ICON_DEFAULTS[bType]
    if d then return d[1], d[2], d[3] end
    return 1, 1, 1
end

local TEXT_DYNAMIC = {
    location = ZoneReactionColor,
    coords = ZoneReactionColor,
    ilvl = function()
        local lvl = K.lastAvgIlvl
        if not lvl then return 1, 1, 1 end
        for i = 1, #ILVL_BANDS do
            local band = ILVL_BANDS[i]
            if lvl >= band[1] then return band[2], band[3], band[4] end
        end
        return 1, 1, 1
    end,
    ms = function()
        if ns.LatencyTextColor then return ns.LatencyTextColor() end
        return 1, 1, 1
    end,
}
-- Blocks whose text takes the state-driven color while no text color is chosen.
ns.TEXT_DYNAMIC_DEFAULT = { ms = true }
function ns.BlockTextDynamic(bType)
    local fn = TEXT_DYNAMIC[bType]
    if fn then return fn() end
    return ns.BlockIconDefault(bType)
end

local function IconColorOf(b)
    if b.useIconDefaultColor then return ns.BlockIconDefault(b.type) end
    if b.useIconClassColor then
        local r, g, bl = ClassRGB()
        if r then return r, g, bl end
    elseif b.useIconAccentColor then
        return ns.GetAccent()
    end
    local c = b.iconColor
    if c then return c.r or 1, c.g or 1, c.b or 1 end
    return ns.BlockIconDefault(b.type)
end

-- Retire a secure frame: hide + park, deferred out of combat (alpha-hidden at once).
local function ParkSecureFrame(f, key)
    if not f then return end
    if InCombatLockdown() then
        f:SetAlpha(0)
        ns.DeferUntilOOC("edbkill:" .. key, function() f:Hide(); f:SetParent(ns._park) end)
    else
        f:Hide()
        f:SetParent(ns._park)
    end
end

-- Shared statusbar for XP/Rep and professions: horizontal or vertical fill without texture rotation.
local function MakeStatusBar(parent)
    local sb = CreateFrame("StatusBar", nil, parent)
    sb:SetMinMaxValues(0, 1)
    sb:SetValue(0)
    sb:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    local bg = sb:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    ns.Solid(bg, 0, 0, 0, 0.45)
    sb._bg = bg
    return sb
end
local function SetBarTexture(sb, key)
    local path = key and key ~= "none" and barTextures[key]
    sb:SetStatusBarTexture(path or "Interface\\Buttons\\WHITE8X8")
end

-- Icon texture with the shared vertex-tint convention.
local function MakeIcon(content, path, size)
    local t = content:CreateTexture(nil, "ARTWORK")
    t:SetTexture(path)
    ns.Size(t, size or 16, size or 16)
    return t
end

K.ICON_GAP = ICON_GAP
K.CONTENT_BASE = CONTENT_BASE
K.InstKey = InstKey
K.MakeEventFrame = MakeEventFrame
K.RegisterInstEvents = RegisterInstEvents
K.UnregisterInstEvents = UnregisterInstEvents
K.ContentScaleOf = ContentScaleOf
K.HBudget = HBudget
K.VSlotW = VSlotW
K.MaybeRelayout = MaybeRelayout
K.AttachTextOffset = AttachTextOffset
K.BlockColorOf = BlockColorOf
K.ZoneReactionColor = ZoneReactionColor
K.IconColorOf = IconColorOf
K.ParkSecureFrame = ParkSecureFrame
K.MakeStatusBar = MakeStatusBar
K.SetBarTexture = SetBarTexture
K.MakeIcon = MakeIcon
K.ClassRGB = ClassRGB
