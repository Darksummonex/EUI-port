--------------------------------------------------------------------------------
--  EllesmereUI_Kick_335.lua
--  Wrath port of EllesmereUI_Kick.lua: shared interrupt lookup and cast-bar
--  tint helper for unit frames and nameplates.
--
--  3.3.5 has no C_SpellBook, cooldown duration objects or color curves. The
--  interrupt is resolved by localized name from the spellbook (pet book first,
--  so a Felhunter's Spell Lock wins), its cooldown is read from that spellbook
--  slot, and a cooldown no longer than the global cooldown counts as ready.
--  Warriors know two interrupts, one per stance set; the usable one wins.
--  The Retail secure menu proxies are not ported: 3.3.5 has no "togglemenu"
--  action and the unit frames open their menus through their own Wrath path.
--------------------------------------------------------------------------------

local EllesmereUI = _G.EllesmereUI or {}
_G.EllesmereUI = EllesmereUI

local kickSpellsByClass = {
    DEATHKNIGHT = { 47528 },          -- Mind Freeze
    WARRIOR     = { 6552, 72 },       -- Pummel, Shield Bash
    WARLOCK     = { 19647 },          -- Spell Lock (Felhunter)
    SHAMAN      = { 57994 },          -- Wind Shear
    ROGUE       = { 1766 },           -- Kick
    PRIEST      = { 15487 },          -- Silence
    MAGE        = { 2139 },           -- Counterspell
    HUNTER      = { 34490 },          -- Silencing Shot
    DRUID       = { 16979 },          -- Feral Charge - Bear
}
local GCD_MAX = 1.5

-- Resolved candidates: { id, name, slot, book }, in class-table order.
local candidates = {}
local activeKickSpell

local function FindInBook(name, book)
    if book == "pet" then
        local n = HasPetSpells and HasPetSpells() or 0
        local found
        for i = 1, n or 0 do
            if GetSpellName(i, "pet") == name then found = i end
        end
        return found
    end
    local found
    for tab = 1, (GetNumSpellTabs and GetNumSpellTabs() or 0) do
        local _, _, offset, count = GetSpellTabInfo(tab)
        for i = offset + 1, offset + count do
            if GetSpellName(i, "spell") == name then found = i end
        end
    end
    return found
end

local function LinkID(slot, book, fallback)
    local link = GetSpellLink and GetSpellLink(slot, book)
    local id = link and tonumber(link:match("spell:(%d+)"))
    return id or fallback
end

local function RefreshKickAbility()
    local _, playerClass = UnitClass("player")
    local classKicks = kickSpellsByClass[playerClass]
    for i = #candidates, 1, -1 do candidates[i] = nil end
    activeKickSpell = nil
    if not classKicks then return end
    local petHit
    for i = 1, #classKicks do
        local name = GetSpellInfo(classKicks[i])
        if name then
            local slot = FindInBook(name, "pet")
            local book = "pet"
            if not slot then slot, book = FindInBook(name, "spell"), "spell" end
            if slot then
                local rec = { id = LinkID(slot, book, classKicks[i]), name = name, slot = slot, book = book }
                if book == "pet" then petHit = rec else candidates[#candidates + 1] = rec end
            end
        end
    end
    if petHit then table.insert(candidates, 1, petHit) end
    activeKickSpell = candidates[1] and candidates[1].id or nil
end

-- The candidate the player can press now: the first one usable in the current
-- stance or form (a mana shortfall still counts), else the first known.
local function CurrentKick()
    local first = candidates[1]
    if not candidates[2] then return first end
    for i = 1, #candidates do
        local c = candidates[i]
        local usable, noMana = IsUsableSpell(c.name)
        if usable or noMana then return c end
    end
    return first
end

local function KickReady(c)
    local start, duration, enabled = GetSpellCooldown(c.slot, c.book)
    if enabled == 0 then return false end
    if not start or start == 0 or not duration or duration == 0 then return true end
    return duration <= GCD_MAX
end

-- readyTint is the Retail "interruptReady" swatch, labelled "Interrupt on CD":
-- it shows while the kick is cooling down; an available kick keeps baseTint.
local function ComputeCastBarTint(readyTint, baseTint)
    local c = CurrentKick()
    if not c then return baseTint.r, baseTint.g, baseTint.b end
    activeKickSpell = c.id
    if KickReady(c) then
        return baseTint.r, baseTint.g, baseTint.b
    end
    return readyTint.r, readyTint.g, readyTint.b
end

-- Seconds until the current kick is usable (0 = ready), or nil without one.
EllesmereUI.GetKickCooldownRemaining = function()
    local c = CurrentKick()
    if not c then return nil end
    if KickReady(c) then return 0 end
    local start, duration = GetSpellCooldown(c.slot, c.book)
    return math.max(0, (start or 0) + (duration or 0) - GetTime())
end

EllesmereUI.GetActiveKickSpell = function()
    return activeKickSpell
end
EllesmereUI.IsKickReady = function()
    local c = CurrentKick()
    return c and KickReady(c) or false
end
EllesmereUI.RefreshKickAbility = RefreshKickAbility
EllesmereUI.ComputeCastBarTint = ComputeCastBarTint

local kickFrame = CreateFrame("Frame")
kickFrame:RegisterEvent("PLAYER_LOGIN")
kickFrame:RegisterEvent("SPELLS_CHANGED")
kickFrame:RegisterEvent("LEARNED_SPELL_IN_TAB")
kickFrame:RegisterEvent("UNIT_PET")
kickFrame:RegisterEvent("PET_BAR_UPDATE")
kickFrame:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_PET" and unit ~= "player" then return end
    RefreshKickAbility()
end)

if UnitGUID("player") then
    RefreshKickAbility()
end
