-------------------------------------------------------------------------------
--  EUI_AuraBuffReminders_335.lua
--  Wrath 3.3.5 runtime: collectors, refresh pipeline, events, profile
--  migration and the _G._EABR_* surface the Retail options page reads.
-------------------------------------------------------------------------------
local _, ns = ...
local EABR = ns.EABR
if not EABR then return end
local E = EllesmereUI
local floor = math.floor

local function P() return EABR.db.profile end

-------------------------------------------------------------------------------
--  Entry pool
-------------------------------------------------------------------------------
EABR._entryPool, EABR._entryUsed = {}, 0
function EABR.NewEntry(cat, key, label)
    EABR._entryUsed = EABR._entryUsed + 1
    local m = EABR._entryPool[EABR._entryUsed]
    if m then wipe(m) else m = {}; EABR._entryPool[EABR._entryUsed] = m end
    m.cat, m.key, m.label = cat, key, label
    m.dismissKey = cat .. ":" .. key
    return m
end

local function Enabled(tbl, key)
    return tbl and tbl[key] ~= false
end

local function SpellCooldownReady(id)
    local name = EABR.SpellName(id)
    if not name then return false end
    local start, duration = GetSpellCooldown(name)
    return not (start and start > 0 and duration and duration > 1.5)
end

local function ItemCooldownReady(itemID)
    local start, duration = GetItemCooldown(itemID)
    return not (start and start > 0 and duration and duration > 1.5)
end

local function FirstOwned(items)
    for _, id in ipairs(items) do
        local n = GetItemCount(id)
        if n and n > 0 then return id, n end
    end
    return nil, 0
end

-------------------------------------------------------------------------------
--  Raid buffs: provider view (buffs you cast) and receiver view (buffs a
--  groupmate of the right class could give you).
-------------------------------------------------------------------------------
function EABR.GroupHasClass(class)
    if not EABR.InGroup() then return false end
    for _, u in ipairs(EABR.GroupUnits()) do
        if not UnitIsUnit(u, "player") and EABR.UnitOk(u) then
            local _, c = UnitClass(u)
            if c == class then return true end
        end
    end
    return false
end

function EABR.CollectRaidBuffs(out, inInstance)
    local rb = P().raidBuffs
    if not EABR.SectionShows(rb.whereToShow, inInstance) then return end
    local showWhen = rb.showWhen or {}
    local playerClass = EABR._class
    local grouped = EABR.InGroup()
    local inCombat = EABR.InCombat()
    for _, def in ipairs(EABR.RAID_BUFFS) do
        if Enabled(rb.enabled, def.key) then
            if def.class == playerClass and showWhen.othersMissing ~= false and EABR.Known(def.castSpell) then
                local have, total, firstMissing = 0, 0, nil
                local units = grouped and EABR.GroupUnits() or { "player" }
                for _, u in ipairs(units) do
                    if EABR.UnitOk(u) and EABR.UnitBenefits(u, def.benefit) and (inCombat or EABR.UnitInRangeOk(u)) then
                        total = total + 1
                        local found, dur, exp = EABR.FindAura(u, def.buffIDs)
                        if found and not EABR.IsUnderDuration(dur, exp) then
                            have = have + 1
                        elseif not firstMissing then
                            firstMissing = u
                        end
                    end
                end
                if firstMissing then
                    local m = EABR.NewEntry("raidbuff", def.key, EABR.ShortLabel(EABR.SpellName(def.castSpell, def.name)))
                    m.data = def
                    m.mode = "spell"
                    m.spellID = def.castSpell
                    local groupName = def.groupSpell and EABR.SpellName(def.groupSpell)
                    if grouped and groupName and EABR._spellbook[groupName] and IsUsableSpell(groupName) then
                        m.spellName = groupName
                    end
                    m.unit = firstMissing
                    if grouped then m.groupHave, m.groupTotal = have, total end
                    out[#out + 1] = m
                end
            elseif def.class ~= playerClass and showWhen.iAmMissing and grouped
                and EABR.UnitBenefits("player", def.benefit) and EABR.GroupHasClass(def.class) then
                local found, dur, exp = EABR.FindAura("player", def.buffIDs)
                if not found or EABR.IsUnderDuration(dur, exp) then
                    local m = EABR.NewEntry("raidbuff", def.key, EABR.ShortLabel(EABR.SpellName(def.castSpell, def.name)))
                    m.data = def
                    m.mode = "texture"
                    m.spellID = def.castSpell
                    out[#out + 1] = m
                end
            end
        end
    end
end

-------------------------------------------------------------------------------
--  Auras (self buffs, stances, soulstone)
-------------------------------------------------------------------------------
local function SpecAllowed(def)
    if not def.specTabs then return true end
    local tab = EABR.GetSpecTab()
    for _, t in ipairs(def.specTabs) do if t == tab then return true end end
    return false
end

local function StanceActive(spellID)
    local want = EABR.SpellName(spellID)
    for i = 1, (GetNumShapeshiftForms() or 0) do
        local _, name, active = GetShapeshiftFormInfo(i)
        if active and name == want then return true end
    end
    return false
end

function EABR.OwnSoulstoneActive()
    local units = EABR.InGroup() and EABR.GroupUnits() or { "player" }
    for _, u in ipairs(units) do
        if UnitExists(u) and EABR.FindAura(u, { 20707 }, true) then return true end
    end
    return false
end

function EABR.CollectSoulstone(out, def, inInstance)
    if EABR.InCombat() or not EABR.SectionShows(P().consumables.warlockWhereToShow, inInstance) then return end
    if EABR.OwnSoulstoneActive() then return end
    local itemID = FirstOwned(EABR.SOULSTONE_ITEMS)
    local m = EABR.NewEntry("aura", def.key, EABR.ShortLabel(EABR.SpellName(def.castSpell, def.name)))
    m.data = def
    if itemID then
        if not ItemCooldownReady(itemID) then EABR._entryUsed = EABR._entryUsed - 1; return end
        m.mode, m.itemID = "macro", itemID
        m.macro = "/use [help,nodead][target=player] item:" .. itemID
        m.texture = EABR.ItemIcon(itemID)
    elseif EABR.Known(EABR.CREATE_SOULSTONE) then
        m.mode, m.spellID = "spell", EABR.CREATE_SOULSTONE
    else
        EABR._entryUsed = EABR._entryUsed - 1
        return
    end
    out[#out + 1] = m
end

function EABR.CollectAuras(out, inInstance)
    local au = P().auras
    local playerClass = EABR._class
    local auraShows = EABR.SectionShows(au.whereToShow, inInstance)
    for _, def in ipairs(EABR.AURAS) do
        if def.class == playerClass and Enabled(au.enabled, def.key) and SpecAllowed(def) then
            if def.key == "soulstone" then
                if au.enabled.soulstone == true then EABR.CollectSoulstone(out, def, inInstance) end
            elseif auraShows and not (def.noMounted and IsMounted()) then
                local castID = def.castSpellFn and def.castSpellFn() or def.castSpell
                if EABR.Known(castID) then
                    local missing
                    if def.isStance then
                        missing = not StanceActive(def.castSpell)
                    else
                        local found, dur, exp = EABR.FindAura("player", def.buffIDs, def.ownOnly)
                        missing = not found or EABR.IsUnderDuration(dur, exp)
                    end
                    if missing then
                        local m = EABR.NewEntry("aura", def.key, EABR.ShortLabel(EABR.SpellName(castID, def.name)))
                        m.data = def
                        m.mode, m.spellID = "spell", castID
                        out[#out + 1] = m
                    end
                end
            end
        end
    end
end

-------------------------------------------------------------------------------
--  Weapons: temporary enchants (poisons, imbues, oils), runeforges
-------------------------------------------------------------------------------
local OFFHAND_WEAPON = { INVTYPE_WEAPON = true, INVTYPE_WEAPONOFFHAND = true }
function EABR.WeaponSlots()
    local mhLink = GetInventoryItemLink("player", 16)
    local ohLink = GetInventoryItemLink("player", 17)
    local ohWeapon = false
    if ohLink then
        local equipLoc = select(9, GetItemInfo(ohLink))
        ohWeapon = OFFHAND_WEAPON[equipLoc] or false
    end
    return mhLink, ohWeapon and ohLink or nil
end

-- Returns missing flags for MH/OH temporary enchants, honoring Show Below.
function EABR.TempEnchantMissing()
    local mhLink, ohLink = EABR.WeaponSlots()
    local hasMH, mhExp, _, hasOH, ohExp = GetWeaponEnchantInfo()
    local now = GetTime()
    local mhMissing = mhLink and (not hasMH or EABR.IsUnderDuration(1800, now + (mhExp or 0) / 1000)) or false
    local ohMissing = ohLink and (not hasOH or EABR.IsUnderDuration(1800, now + (ohExp or 0) / 1000)) or false
    return mhMissing, ohMissing, hasMH
end

local POISON_PRIORITY_MH = { "instant", "deadly", "wound", "crippling", "mindnumbing", "anesthetic" }
local POISON_PRIORITY_OH = { "deadly", "instant", "wound", "crippling", "mindnumbing", "anesthetic" }
local poisonByKey
local function PoisonFor(priority, en, skip)
    if not poisonByKey then
        poisonByKey = {}
        for _, d in ipairs(EABR.ROGUE_POISONS) do poisonByKey[d.key] = d end
    end
    local fallback
    for _, key in ipairs(priority) do
        local d = poisonByKey[key]
        if d and en[key] == true and key ~= skip then
            if FirstOwned(d.items) then return d end
            fallback = fallback or d
        end
    end
    if skip then return PoisonFor(priority, en, nil) end
    return fallback
end

function EABR.AddWeaponItemEntry(out, key, label, itemID, items, slot, spellID)
    local c = P().consumables
    local owned, count = itemID, itemID and GetItemCount(itemID) or 0
    if items and (not owned or count == 0) then owned, count = FirstOwned(items) end
    if (not owned or count == 0) and c.showWithoutItem == false then return end
    local m = EABR.NewEntry("consumable", key, label)
    m.slot = slot
    m.spellID = spellID
    m.itemID = owned or itemID or (items and items[1])
    m.texture = EABR.ItemIcon(m.itemID) or (spellID and EABR.Tex(spellID))
    m.bagCount = count
    if owned and count > 0 then
        m.mode = "macro"
        m.macro = "/use item:" .. owned .. "\n/use " .. slot
    else
        m.desaturated = true
    end
    out[#out + 1] = m
    return m
end

function EABR.CollectRoguePoisons(out)
    local c = P().consumables
    local en = c.enabled
    local mhMissing, ohMissing = EABR.TempEnchantMissing()
    local mhDef = PoisonFor(POISON_PRIORITY_MH, en)
    local ohDef = PoisonFor(POISON_PRIORITY_OH, en, mhDef and mhDef.key)
    if mhMissing and mhDef then
        local m = EABR.AddWeaponItemEntry(out, mhDef.key, EABR.ShortLabel(nil, "ROGUE"), nil, mhDef.items, 16, mhDef.castSpell)
        if m then m.dismissKey = "consumable:" .. mhDef.key .. ":mh" end
    end
    if ohMissing and ohDef then
        local m = EABR.AddWeaponItemEntry(out, ohDef.key, EABR.ShortLabel(nil, "ROGUE"), nil, ohDef.items, 17, ohDef.castSpell)
        if m then m.dismissKey = "consumable:" .. ohDef.key .. ":oh" end
    end
end

local imbueByKey
function EABR.CollectShamanImbues(out)
    local en = P().consumables.enabled
    if not imbueByKey then
        imbueByKey = {}
        for _, d in ipairs(EABR.SHAMAN_IMBUES) do imbueByKey[d.key] = d end
    end
    local pref = EABR.SHAMAN_IMBUE_SPEC[EABR.GetSpecTab() or 1] or EABR.SHAMAN_IMBUE_SPEC[1]
    local function Pick(prefKey)
        local d = imbueByKey[prefKey]
        if d and en[d.key] ~= false and EABR.Known(d.castSpell) then return d end
        for _, alt in ipairs(EABR.SHAMAN_IMBUES) do
            if en[alt.key] == true and EABR.Known(alt.castSpell) then return alt end
        end
    end
    local mhMissing, ohMissing, hasMH = EABR.TempEnchantMissing()
    -- An imbue cast lands on the main hand first, then the off hand.
    local d, hand
    if mhMissing then d, hand = Pick(pref[1]), "mh"
    elseif ohMissing and hasMH then d, hand = Pick(pref[2]), "oh" end
    if not d then return end
    local m = EABR.NewEntry("consumable", d.key, EABR.ShortLabel(nil, "SHAMAN_IMBUE"))
    m.dismissKey = "consumable:" .. d.key .. ":" .. hand
    m.mode, m.spellID = "spell", d.castSpell
    out[#out + 1] = m
end

function EABR.FindTankUnit()
    if not EABR.InGroup() then return nil end
    for _, u in ipairs(EABR.GroupUnits()) do
        if not UnitIsUnit(u, "player") and EABR.UnitOk(u) then
            local isTank = UnitGroupRolesAssigned and UnitGroupRolesAssigned(u)
            if isTank == true or isTank == "TANK" or (GetPartyAssignment and GetPartyAssignment("MAINTANK", u)) then
                return u
            end
        end
    end
    if UnitExists("focus") and UnitIsFriend("player", "focus") then return "focus" end
    return nil
end

function EABR.CollectShamanShields(out)
    local en = P().consumables.enabled
    for _, def in ipairs(EABR.SHAMAN_SHIELDS) do
        if def.key == "shield_basic" and en.shield_basic ~= false then
            local castID = def.castSpellFn()
            if EABR.Known(castID) then
                local found, dur, exp = EABR.FindAura("player", def.buffIDs, true)
                if not found or EABR.IsUnderDuration(dur, exp) then
                    local m = EABR.NewEntry("consumable", def.key, EABR.ShortLabel(nil, "SHAMAN_SHIELD"))
                    m.mode, m.spellID = "spell", castID
                    out[#out + 1] = m
                end
            end
        elseif def.key == "es_ally" and en.es_ally == true and EABR.Known(def.castSpell) and EABR.InGroup() then
            local active = false
            for _, u in ipairs(EABR.GroupUnits()) do
                if not UnitIsUnit(u, "player") and UnitExists(u) and EABR.FindAura(u, def.buffIDs, true) then
                    active = true; break
                end
            end
            if not active then
                local m = EABR.NewEntry("consumable", def.key, EABR.ShortLabel(EABR.SpellName(def.castSpell, def.name)))
                m.mode, m.spellID = "spell", def.castSpell
                m.unit = EABR.FindTankUnit() or false
                out[#out + 1] = m
            end
        end
    end
end

function EABR.CollectWeaponEnchant(out)
    local c = P().consumables
    if c.enabled.weapon_enchant ~= true then return end
    local mhMissing = EABR.TempEnchantMissing()
    if not mhMissing then return end
    local wanted = c.preferredWeaponEnchant
    local itemID
    if wanted == "last_used" or not wanted then
        itemID = c.lastUsedWeaponEnchant
    else
        for _, ch in ipairs(EABR.WEAPON_ENCHANT_CHOICES) do
            if ch.key == wanted then itemID = ch.itemID end
        end
    end
    local all = {}
    for _, it in ipairs(EABR.WEAPON_ENCHANT_ITEMS) do all[#all + 1] = it.itemID end
    local m = EABR.AddWeaponItemEntry(out, "weapon_enchant", E.L("Weapon"), itemID, all, 16)
    if m and itemID and m.itemID ~= itemID and m.bagCount > 0 then m.substitute = true end
end

function EABR.CollectRuneforge(out)
    if EABR._class ~= "DEATHKNIGHT" or not EABR.Known(EABR.RUNEFORGING_SPELL) then return end
    local mhLink, ohLink = EABR.WeaponSlots()
    local function Bare(link)
        local enchant = link and link:match("item:%d+:(%d+)")
        return link and tonumber(enchant or 0) == 0
    end
    if Bare(mhLink) or Bare(ohLink) then
        local m = EABR.NewEntry("consumable", "runeforge", EABR.ShortLabel(EABR.SpellName(EABR.RUNEFORGING_SPELL, "Runeforging")))
        m.mode, m.spellID = "spell", EABR.RUNEFORGING_SPELL
        out[#out + 1] = m
    end
end

-------------------------------------------------------------------------------
--  Flask, food, healthstone
-------------------------------------------------------------------------------
function EABR.HasFlask()
    local names = EABR.NameSet(EABR.FLASK_BUFF_IDS)
    for i = 1, 40 do
        local name, _, _, _, _, duration, expires = UnitAura("player", i, "HELPFUL")
        if not name then break end
        if names[name] or name:find("Flask") then
            return true, duration or 0, expires or 0
        end
    end
    return false
end

-- Resolves the preferred item (or last used) against bag contents; returns
-- itemID, count, substitute flag.
function EABR.ResolvePreferred(prefKey, lastUsed, catalog, idsOf)
    local wanted
    if prefKey == "last_used" or not prefKey then
        wanted = lastUsed
    else
        for _, it in ipairs(catalog) do
            if it.key == prefKey then wanted = idsOf(it)[1] end
        end
    end
    if wanted then
        local n = GetItemCount(wanted)
        if n and n > 0 then return wanted, n, false end
    end
    for _, it in ipairs(catalog) do
        local id, n = FirstOwned(idsOf(it))
        if id then return id, n, wanted ~= nil end
    end
    return wanted or idsOf(catalog[1])[1], 0, false
end

local function FlaskIDs(it) return it.items end
local foodIDsScratch = {}
local function FoodIDs(it) foodIDsScratch[1] = it.itemID; return foodIDsScratch end

function EABR.AddItemEntry(out, key, label, itemID, count, substitute)
    local c = P().consumables
    if count == 0 and c.showWithoutItem == false then return end
    local m = EABR.NewEntry("consumable", key, label)
    m.itemID = itemID
    m.texture = EABR.ItemIcon(itemID)
    m.bagCount = count
    if count > 0 then
        m.mode = "item"
        m.substitute = substitute or nil
    else
        m.desaturated = true
    end
    out[#out + 1] = m
    return m
end

function EABR.CollectFlaskFood(out)
    local c = P().consumables
    if c.enabled.flask ~= false then
        local found, dur, exp = EABR.HasFlask()
        if not found or EABR.IsUnderDuration(dur, exp) then
            local id, n, sub = EABR.ResolvePreferred(c.preferredFlask, c.lastUsedFlask, EABR.FLASK_ITEMS, FlaskIDs)
            local m = EABR.AddItemEntry(out, "flask", E.L("Flask"), id, n, sub)
            if m and not m.texture then m.texture = EABR.FLASK_ICON end
        end
    end
    if c.enabled.food ~= false then
        local eating, _, eatExp = EABR.FindAuraByName("player", EABR.SpellName(EABR.FOOD_SPELL))
        local fed, dur, exp = EABR.FindAuraByName("player", EABR.SpellName(EABR.WELL_FED_SPELL))
        if eating and not fed then
            local m = EABR.NewEntry("consumable", "food", E.L("Food"))
            m.isEating, m.eatingExpirationTime = true, (eatExp and eatExp > 0) and eatExp or nil
            m.texture = EABR.EATING_ICON
            out[#out + 1] = m
        elseif not fed or EABR.IsUnderDuration(dur, exp) then
            local id, n, sub = EABR.ResolvePreferred(c.preferredFood, c.lastUsedFood, EABR.FOOD_ITEMS, FoodIDs)
            local m = EABR.AddItemEntry(out, "food", E.L("Food"), id, n, sub)
            if m and not m.texture then m.texture = EABR.FOOD_ICON end
        end
    end
end

function EABR.CollectHealthstone(out, inCombat)
    local c = P().consumables
    if c.enabled.healthstone == false then return end
    local isLock = EABR._class == "WARLOCK"
    if inCombat and not isLock then return end
    if FirstOwned(EABR.HEALTHSTONE_ITEM_IDS) then return end
    if not isLock and not EABR.GroupHasClass("WARLOCK") then return end
    local m = EABR.NewEntry("consumable", "healthstone", EABR.ShortLabel(EABR.SpellName(EABR.CREATE_HEALTHSTONE, "Healthstone")))
    m.texture = EABR.HEALTHSTONE_ICON
    m.tooltipItem = EABR.HEALTHSTONE_ITEM_IDS[1]
    if isLock and not inCombat and EABR.Known(EABR.CREATE_HEALTHSTONE) then
        m.mode, m.spellID = "spell", EABR.CREATE_HEALTHSTONE
        m.tooltipItem = nil
    end
    out[#out + 1] = m
end

-------------------------------------------------------------------------------
--  Pets
-------------------------------------------------------------------------------
function EABR.ActiveDemonKey()
    if not UnitExists("pet") then return nil end
    local n = HasPetSpells and HasPetSpells() or 0
    if n == 0 then return nil end
    local have = {}
    for i = 1, n do
        local name = GetSpellName(i, BOOKTYPE_PET or "pet")
        if name then have[name] = true end
    end
    for _, d in ipairs(EABR.WARLOCK_PETS) do
        local sig = EABR.SpellName(d.petSpell)
        if sig and have[sig] then return d.key end
    end
    return nil
end

local demonChoices = {}
function EABR.AllowedDemons(onlyAllowed)
    wipe(demonChoices)
    local allowed = P().consumables.wrongPetAllowed or {}
    for _, d in ipairs(EABR.WARLOCK_PETS) do
        if EABR.Known(d.castSpell) and (not onlyAllowed or allowed[d.key]) then
            demonChoices[#demonChoices + 1] = d
        end
    end
    return demonChoices
end

local function PetCycleEntry(out, key, label, choices)
    local total = #choices
    if total == 0 then return end
    local idx = EABR._petCycleIndex or 1
    if idx > total then idx = 1; EABR._petCycleIndex = 1 end
    local d = choices[idx]
    local m = EABR.NewEntry("consumable", key, label)
    m.mode, m.spellID = "spell", d.castSpell or d
    if total > 1 then m.petCycleTotal = total end
    out[#out + 1] = m
end

function EABR.CollectPets(out, inInstance, inCombat)
    local c = P().consumables
    local en = c.enabled
    local class = EABR._class
    if not EABR.PET_CLASSES[class] then return end
    if class == "WARLOCK" and not EABR.SectionShows(c.warlockWhereToShow, inInstance) then return end
    if class ~= "WARLOCK" and not EABR.SectionShows(c.whereToShow, inInstance) then return end
    local hasPet = UnitExists("pet") and not UnitIsDead("pet")
    if en.pet ~= false and not hasPet and not inCombat then
        if class == "HUNTER" and EABR.Known(EABR.CALL_PET) then
            local list = { EABR.CALL_PET }
            if EABR.Known(EABR.REVIVE_PET) then
                if UnitExists("pet") then list[1] = EABR.REVIVE_PET else list[2] = EABR.REVIVE_PET end
            end
            local choices = {}
            for i, id in ipairs(list) do choices[i] = { castSpell = id } end
            PetCycleEntry(out, "pet", E.L("Pet"), choices)
        elseif class == "WARLOCK" and not EABR.FindAura("player", EABR.DEMONIC_SACRIFICE_BUFFS) then
            local allowed = EABR.AllowedDemons(true)
            if #allowed == 0 then allowed = EABR.AllowedDemons(false) end
            local copy = {}
            for i, d in ipairs(allowed) do copy[i] = d end
            PetCycleEntry(out, "pet", E.L("Pet"), copy)
        elseif class == "DEATHKNIGHT" and EABR.GetSpecTab() == 3 and EABR.Known(EABR.RAISE_DEAD)
            and SpellCooldownReady(EABR.RAISE_DEAD) then
            local m = EABR.NewEntry("consumable", "pet", E.L("Pet"))
            m.mode, m.spellID = "spell", EABR.RAISE_DEAD
            out[#out + 1] = m
        end
    end
    if hasPet and en.wrong_pet ~= false and class == "WARLOCK" and not inCombat then
        local known = EABR.AllowedDemons(false)
        local nKnown = #known
        local allowed = EABR.AllowedDemons(true)
        local nAllowed = #allowed
        if nAllowed > 0 and nAllowed < nKnown then
            local active = EABR.ActiveDemonKey()
            local ok = false
            for _, d in ipairs(allowed) do if d.key == active then ok = true end end
            if active and not ok then
                local copy = {}
                for i, d in ipairs(allowed) do copy[i] = d end
                PetCycleEntry(out, "wrong_pet", E.L("Wrong Demon"), copy)
            end
        end
    end
    if hasPet and en.pet_passive ~= false then
        for i = 1, (NUM_PET_ACTION_SLOTS or 10) do
            local name, _, texture, isToken, isActive = GetPetActionInfo(i)
            if name == "PET_MODE_PASSIVE" and isActive then
                local m = EABR.NewEntry("consumable", "pet_passive", E.L("Passive"))
                m.texture = isToken and _G[texture] or texture
                m.mode, m.macro = "macro", "/petdefensive"
                out[#out + 1] = m
                break
            end
        end
    end
end

-------------------------------------------------------------------------------
--  Custom spell reminders
-------------------------------------------------------------------------------
function EABR.CollectCustom(out, inInstance)
    local cu = P().custom
    local ids = cu and cu.customIDs
    if not ids or #ids == 0 or not EABR.SectionShows(cu.whereToShow, inInstance) then return end
    for _, id in ipairs(ids) do
        local name = EABR.SpellName(id)
        if name then
            local found, dur, exp = EABR.FindAuraByName("player", name)
            if not found or EABR.IsUnderDuration(dur, exp) then
                local m = EABR.NewEntry("custom", tostring(id), EABR.ShortLabel(name))
                m.spellID = id
                if EABR._spellbook[name] then m.mode = "spell" end
                out[#out + 1] = m
            end
        end
    end
end

-------------------------------------------------------------------------------
--  Appear sounds
-------------------------------------------------------------------------------
function EABR.IsSpecialKey(key)
    local set = EABR._specialKeySet
    if not set then
        set = {}
        for _, tbl in ipairs({ EABR.ROGUE_POISONS, EABR.PALADIN_RITES, EABR.SHAMAN_IMBUES, EABR.SHAMAN_SHIELDS }) do
            for _, it in ipairs(tbl) do set[it.key] = true end
        end
        EABR._specialKeySet = set
    end
    return set[key]
end

function EABR.ResolveReminderSound(dk)
    local prefix, key = dk:match("^(%a+):([^:]+)")
    if not prefix then return nil end
    local p = P()
    if prefix == "raidbuff" then return p.raidBuffs.sectionSound end
    if prefix == "aura" then return p.auras.sectionSound end
    if prefix == "custom" then return p.custom and p.custom.sectionSound end
    if prefix == "consumable" then
        if EABR.IsSpecialKey(key) then return p.consumables.specialsSound end
        return p.consumables.sectionSound
    end
    return nil
end

function EABR.HandleAppearSounds(missing)
    local prev = EABR._soundPrev or {}
    local cur = EABR._soundCur or {}
    wipe(cur)
    local primed = EABR._soundPrimed
    for i = 1, #missing do
        local dk = missing[i].dismissKey
        if dk and not EABR.dismissed[dk] then
            cur[dk] = true
            if primed and not prev[dk] then
                local skey = EABR.ResolveReminderSound(dk)
                local paths = E._groupDeathSoundPaths
                local path = skey and skey ~= "none" and paths and paths[skey]
                if path then PlaySoundFile(path, "Master") end
            end
        end
    end
    EABR._soundPrev, EABR._soundCur, EABR._soundPrimed = cur, prev, true
end

-------------------------------------------------------------------------------
--  Refresh
-------------------------------------------------------------------------------
EABR._missing = {}

function EABR.HideAllIcons()
    EABR.HideRowIcons()
    EABR.HideCursorIcons()
    EABR.HideActions()
    if EABR._providerCastBtn and not InCombatLockdown() then EABR.ParkProviderCastButton() end
end

local function HideForState()
    EABR.HideRowIcons()
    EABR.HideCursorIcons()
    EABR.HideActions()
    if not InCombatLockdown() and EABR._providerCastBtn then EABR.ParkProviderCastButton() end
end

function EABR.Collect(out)
    local p = P()
    local inCombat = EABR.InCombat()
    local inInstance = EABR.InInstance()
    if p.display.remindersEnabled == false then return end
    EABR.CollectRaidBuffs(out, inInstance)
    EABR.CollectAuras(out, inInstance)
    local c = p.consumables
    local class = EABR._class
    if not EABR.InPvPInstance() then
        if EABR.SectionShows(c.specialsWhereToShow, inInstance) then
            if class == "ROGUE" then EABR.CollectRoguePoisons(out) end
            if class == "SHAMAN" then
                EABR.CollectShamanImbues(out)
                if not inCombat then EABR.CollectShamanShields(out) end
            end
        end
        if EABR.SectionShows(c.whereToShow, inInstance) then
            if class ~= "ROGUE" and class ~= "SHAMAN" then EABR.CollectWeaponEnchant(out) end
            if not inCombat then
                EABR.CollectFlaskFood(out)
                EABR.CollectRuneforge(out)
            end
            EABR.CollectHealthstone(out, inCombat)
        end
    end
    EABR.CollectPets(out, inInstance, inCombat)
    EABR.CollectCustom(out, inInstance)
end

function EABR.Refresh()
    EABR._refreshQueued = false
    EABR._cachedOutline = nil
    EABR._nextDurationRefreshTime = nil
    if not (EABR.db and EABR.iconAnchor) then return end
    if EABR._panelOpen then HideForState(); return end
    if UnitInVehicle("player") or (IsMounted() and IsFlying()) or UnitIsDeadOrGhost("player") or IsResting() then
        HideForState(); return
    end
    EABR.CacheInstanceInfo()
    EABR._entryUsed = 0
    local missing = EABR._missing
    wipe(missing)
    EABR.Collect(missing)
    EABR.HandleAppearSounds(missing)

    local p = P().display
    local inCombat = InCombatLockdown()
    local useCursor = p.cursorAttach and EABR.cursorAnchor
    EABR.HideRowIcons()
    EABR.HideCursorIcons()

    local rowIdx, curIdx, providerEntry = 0, 0, nil
    local rows = {}
    for _, m in ipairs(missing) do
        if not EABR.dismissed[m.dismissKey] then
            local provider = m.cat == "raidbuff" and m.mode == "spell"
            if provider and useCursor then
                curIdx = curIdx + 1
                local f = EABR.GetOrCreateCursorIcon(curIdx)
                EABR.PaintIcon(f, m)
                EABR.cursorActive[curIdx] = f
            elseif provider and not providerEntry
                and (not inCombat or EABR._providerReserved) then
                providerEntry = m
            else
                rows[#rows + 1] = m
            end
        end
    end

    local slots = {}
    local providerVisual
    if providerEntry or (inCombat and EABR._providerReserved) then
        rowIdx = 1
        if providerEntry then
            providerVisual = EABR.GetOrCreateIcon(1)
            EABR.PaintIcon(providerVisual, providerEntry)
            slots[1] = providerVisual
            EABR.activeIcons[1] = providerVisual
        else
            slots[1] = false
        end
    end
    for _, m in ipairs(rows) do
        rowIdx = rowIdx + 1
        local f = EABR.GetOrCreateIcon(rowIdx)
        EABR.PaintIcon(f, m)
        slots[rowIdx] = f
        EABR.activeIcons[#EABR.activeIcons + 1] = f
    end
    if #EABR.activeIcons > 0 then
        E.SetElementVisibility(EABR.iconAnchor, true)
        EABR.LayoutRow(slots)
    end
    if curIdx > 0 then
        EABR.cursorAnchor:Show()
        E.SetElementVisibility(EABR.cursorAnchor, true)
        EABR.LayoutCursorIcons()
    end

    if not inCombat then
        if providerVisual then
            EABR.PlaceProviderCastButton(providerVisual, providerEntry)
        elseif EABR._providerCastBtn then
            EABR.ParkProviderCastButton()
        end
        EABR.SyncActions()
    end
end

function EABR.RequestRefresh()
    if EABR._refreshQueued then return end
    EABR._refreshQueued = true
    local now = GetTime()
    local wait = 0.5 - (now - (EABR._lastRefresh or 0))
    if wait < 0 then wait = 0 end
    C_Timer.After(wait, function()
        EABR._lastRefresh = GetTime()
        EABR.Refresh()
        if EABR.TR_RequestRefresh then EABR.TR_RequestRefresh() end
    end)
end

-------------------------------------------------------------------------------
--  Events
-------------------------------------------------------------------------------
local ev = CreateFrame("Frame")
EABR._events = ev

function EABR.UpdateGroupAuraRegistration() EABR.RequestRefresh() end

local REFRESH_EVENTS = {
    "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
    "UNIT_AURA", "UNIT_INVENTORY_CHANGED", "BAG_UPDATE", "BAG_UPDATE_COOLDOWN",
    "PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE", "UNIT_PET", "PET_BAR_UPDATE",
    "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB", "PLAYER_TALENT_UPDATE", "ACTIVE_TALENT_GROUP_CHANGED",
    "ZONE_CHANGED_NEW_AREA", "PLAYER_UPDATE_RESTING", "UPDATE_SHAPESHIFT_FORM",
    "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST", "UNIT_ENTERED_VEHICLE", "UNIT_EXITED_VEHICLE",
    "COMPANION_UPDATE", "PLAYER_EQUIPMENT_CHANGED", "UNIT_SPELLCAST_SUCCEEDED",
}

local function IsGroupUnit(u)
    return u and (u == "player" or u == "pet" or u:find("^party") or u:find("^raid")) and true or false
end

function EABR.OnEvent(_, event, arg1)
    if event == "PLAYER_ENTERING_WORLD" then
        wipe(EABR.dismissed)
        EABR._soundPrimed = false
        EABR.ScanSpellbook()
        C_Timer.After(0.5, EABR.RequestRefresh)
        return
    elseif event == "PLAYER_REGEN_DISABLED" then
        EABR._inCombat = true
    elseif event == "PLAYER_REGEN_ENABLED" then
        EABR._inCombat = false
        if EABR._actionsDirty then EABR.SyncActions() end
    elseif event == "SPELLS_CHANGED" or event == "LEARNED_SPELL_IN_TAB"
        or event == "PLAYER_TALENT_UPDATE" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
        EABR.ScanSpellbook()
    elseif event == "UNIT_AURA" or event == "UNIT_INVENTORY_CHANGED" or event == "UNIT_PET"
        or event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE" then
        if event == "UNIT_PET" then
            if arg1 ~= "player" then return end
        elseif arg1 ~= "player" and not (event == "UNIT_AURA" and not EABR._inCombat and IsGroupUnit(arg1)) then
            return
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        if arg1 ~= "player" then return end
    elseif event == "BAG_UPDATE" then
        if EABR.TrackItemUse then EABR.TrackItemUse() end
    end
    EABR.RequestRefresh()
end

-- Re-checks timed thresholds and group range without waiting for an event.
function EABR.OnTick(_, elapsed)
    EABR._tickAcc = (EABR._tickAcc or 0) + elapsed
    if EABR._tickAcc < 0.5 then return end
    EABR._tickAcc = 0
    local now = GetTime()
    local due = EABR._nextDurationRefreshTime
    if due and now >= due then
        EABR._nextDurationRefreshTime = nil
        EABR.RequestRefresh()
        return
    end
    if not EABR._inCombat and EABR.InGroup() and now - (EABR._lastRangePoll or 0) >= 2 then
        EABR._lastRangePoll = now
        EABR.RequestRefresh()
    end
end

-------------------------------------------------------------------------------
--  Profile migration from the 0.1 Wrath schema
-------------------------------------------------------------------------------
local OLD_SOUNDS = { AirHorn = "airhorn", BananaPeelSlip = "banana", BikeHorn = "bikehorn", BoxingArenaSound = "boxing", WaterDrop = "water" }
local function OldWhere(v)
    if v == "instances" then return { open_world = false } end
    if v == "outofcombat" then return { in_combat = false } end
    return {}
end

function EABR.MigrateLegacyProfile(p)
    local d = p.display
    if d.iconSize then
        d.scale = math.max(0.5, math.min(3, (d.scale or 1) * d.iconSize / EABR.ICON_SIZE))
    end
    -- The old threshold was seconds; the current slider caps at 60 minutes.
    if type(d.showUnder) == "number" and d.showUnder > 60 then
        d.showUnder = math.min(60, floor(d.showUnder / 60 + 0.5))
    end
    d.iconSize, d.hideInCombat, d.hideMounted, d.glow, d.fontOutline = nil, nil, nil, nil, nil
    local rb = p.raidBuffs
    if rb.where ~= nil or rb.scope ~= nil then
        local en = rb.enabled
        if en.intellect ~= nil then en.ai = en.intellect; en.intellect = nil end
        if en.shout ~= nil then en.bshout = en.shout; en.shout = nil end
        rb.whereToShow = OldWhere(rb.where)
        rb.showWhen = { othersMissing = rb.othersMissing ~= false, iAmMissing = rb.iAmMissing == true }
        rb.sectionSound = OLD_SOUNDS[rb.sound] or rb.sectionSound
        rb.where, rb.scope, rb.othersMissing, rb.iAmMissing, rb.sound = nil, nil, nil, nil, nil
    end
    local au = p.auras
    local co = p.consumables
    if au.where ~= nil then
        local en = au.enabled
        if en.innerfire ~= nil then en.inner_fire = en.innerfire; en.innerfire = nil end
        if en.armor ~= nil then en.mage_armor = en.armor; en.demon_armor = en.armor; en.armor = nil end
        if en.aura ~= nil then en.pala_aura = en.aura; en.aura = nil end
        if en.shield ~= nil then co.enabled.shield_basic = en.shield; en.shield = nil end
        if en.pet ~= nil then co.enabled.pet = en.pet; en.pet = nil end
        en.aspect = en.aspect ~= false
        au.whereToShow = OldWhere(au.where)
        au.sectionSound = OLD_SOUNDS[au.sound] or au.sectionSound
        au.where, au.sound = nil, nil
    end
    if co.where ~= nil or type(co.food) == "boolean" then
        if type(co.food) == "boolean" then co.enabled.food = co.food end
        if type(co.flask) == "boolean" then co.enabled.flask = co.flask end
        if co.mainhand == true or co.offhand == true then co.enabled.weapon_enchant = true end
        if type(co.preferredFood) == "number" then
            local want = co.preferredFood
            co.preferredFood = "last_used"
            for _, it in ipairs(EABR.FOOD_ITEMS) do if it.itemID == want then co.preferredFood = it.key end end
        end
        if type(co.preferredFlask) == "number" then
            local want = co.preferredFlask
            co.preferredFlask = "last_used"
            for _, it in ipairs(EABR.FLASK_ITEMS) do if it.items[1] == want then co.preferredFlask = it.key end end
        end
        co.whereToShow = OldWhere(co.where)
        co.sectionSound = OLD_SOUNDS[co.sound] or co.sectionSound
        co.food, co.flask, co.mainhand, co.offhand, co.where, co.sound = nil, nil, nil, nil, nil, nil
    end
    if type(p.customReminders) == "table" then
        local cu = p.custom
        cu.customIDs = cu.customIDs or {}
        for _, r in ipairs(p.customReminders) do
            if r.spellID and r.enabled ~= false then cu.customIDs[#cu.customIDs + 1] = r.spellID end
        end
        p.customReminders = nil
    end
    local _, class = UnitClass("player")
    for _, r in ipairs(p.talentReminders or {}) do
        if r.zone and not r.zoneNames then
            r.zoneNames = { r.zone }
            r.zone = nil
        end
        r.spellName = r.spellName or EABR.SpellName(r.spellID, "Unknown")
        r.class = r.class or class
    end
end

-------------------------------------------------------------------------------
--  Lifecycle
-------------------------------------------------------------------------------
function EABR:OnInitialize()
    EABR.db = E.Lite.NewDB("EllesmereUIAuraBuffRemindersDB", EABR.defaults, true)
    ns.db = EABR.db
    EABR.MigrateLegacyProfile(EABR.db.profile)
    EABR.EnsureGlowModeMigrated(EABR.db.profile.display)
end

function EABR.PublishGlobals()
    _G._EABR_AceDB = EABR.db
    _G._EABR_RequestRefresh = EABR.RequestRefresh
    _G._EABR_ApplyIconBorder = EABR.ApplyIconBorder
    _G._EABR_ApplyAllIconBorders = EABR.ApplyAllIconBorders
    _G._EABR_HideAllIcons = EABR.HideAllIcons
    _G._EABR_GLOW_VIEW = EABR.GLOW_VIEW
    _G._EABR_EnsureGlowModeMigrated = EABR.EnsureGlowModeMigrated
    _G._EABR_RegisterUnlock = EABR.RegisterUnlockElements
    _G._EABR_ApplyUnlockPos = EABR.ApplyUnlockPos
    _G._EABR_RAID_BUFFS = EABR.RAID_BUFFS
    _G._EABR_AURAS = EABR.AURAS
    _G._EABR_ROGUE_POISONS = EABR.ROGUE_POISONS
    _G._EABR_PALADIN_RITES = EABR.PALADIN_RITES
    _G._EABR_SHAMAN_IMBUES = EABR.SHAMAN_IMBUES
    _G._EABR_SHAMAN_SHIELDS = EABR.SHAMAN_SHIELDS
    _G._EABR_WARLOCK_PETS = EABR.WARLOCK_PETS
    _G._EABR_WEAPON_ENCHANT_ITEMS = EABR.WEAPON_ENCHANT_ITEMS
    _G._EABR_Tex = EABR.Tex
    _G._EABR_Known = EABR.Known
    _G._EABR_SpellName = EABR.SpellName
    _G._EABR_GetSpecID = EABR.GetSpecID
    _G._EABR_ICON_SIZE = EABR.ICON_SIZE
    _G._EABR_FLASK_ITEMS = EABR.FLASK_ITEMS
    _G._EABR_FOOD_ITEMS = EABR.FOOD_ITEMS
    _G._EABR_WEAPON_ENCHANT_CHOICES = EABR.WEAPON_ENCHANT_CHOICES
    _G._EABR_TEXT_ANCHORS = EABR.TEXT_ANCHOR_POINTS
    _G._EABR_GlowSpec = EABR.GlowSpec
    _G._EABR_UpdateGroupAuraRegistration = EABR.UpdateGroupAuraRegistration
    _G._EABR_TALENT_REMINDER_ZONES = EABR.TALENT_REMINDER_ZONES
    _G._EABR_STRATA_VALUES = E.FRAME_STRATA_LABELS
    _G._EABR_STRATA_ORDER = E.FRAME_STRATA_ORDER_FULL
    _G._EABR_ApplyStrata = EABR.ApplyStrata
end

function EABR:OnEnable()
    local _, class = UnitClass("player")
    EABR._class = class
    if not E._groupDeathSoundPaths and E.BuildAlertSoundTables then
        E._groupDeathSoundPaths, E._groupDeathSoundNames, E._groupDeathSoundOrder = E.BuildAlertSoundTables()
    end
    EABR.ScanSpellbook()
    EABR.PublishGlobals()
    EABR.CreateAnchors()
    EABR.EnsureProviderCastButton()
    E:RegisterOnShow(function() EABR._panelOpen = true; EABR.HideAllIcons() end)
    E:RegisterOnHide(function() EABR._panelOpen = false; EABR.RequestRefresh() end)
    for _, e in ipairs(REFRESH_EVENTS) do ev:RegisterEvent(e) end
    ev:SetScript("OnEvent", EABR.OnEvent)
    ev:SetScript("OnUpdate", EABR.OnTick)
    if EABR.EnableExtras then EABR.EnableExtras() end
    C_Timer.After(0.5, EABR.RegisterUnlockElements)
    EABR.RequestRefresh()
end

SLASH_EABR1, SLASH_EABR2 = "/eabr", "/ebr"
SlashCmdList.EABR = function()
    if E.EnsureOptionsLoaded then E.EnsureOptionsLoaded() end
    if E.ShowModule then E:ShowModule("EllesmereUIAuraBuffReminders") end
end
