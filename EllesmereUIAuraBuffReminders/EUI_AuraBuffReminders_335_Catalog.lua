-------------------------------------------------------------------------------
--  EUI_AuraBuffReminders_335_Catalog.lua
--  Wrath 3.3.5 data and shared helpers for the AuraBuff Reminders runtime.
--  Same profile schema and option-facing tables as the Retail module; the
--  spell/item data is Wrath's. Spells are matched by name so every rank
--  counts, and casts go through the spell name so the highest rank fires.
-------------------------------------------------------------------------------
local ADDON_NAME, ns = ...
local E = EllesmereUI
if not (E and E.Lite and E._ModuleNS) then return end
E._ModuleNS[ADDON_NAME] = ns

local EABR = E.Lite.NewAddon(ADDON_NAME)
ns.EABR, ns.addon, ns.IsWrath = EABR, EABR, true

local floor = math.floor
local ICON_PATH = "Interface\\Icons\\"
EABR.ICON_SIZE = 40
EABR.QUESTION_ICON = ICON_PATH .. "INV_Misc_QuestionMark"
EABR.EATING_ICON = ICON_PATH .. "INV_Misc_Fork&Knife"
EABR.HEALTHSTONE_ICON = ICON_PATH .. "INV_Stone_04"
EABR.PET_ICON = ICON_PATH .. "Ability_Hunter_BeastCall"
EABR.FLASK_ICON = ICON_PATH .. "INV_Alchemy_EndlessFlask_06"
EABR.FOOD_ICON = ICON_PATH .. "INV_Misc_Food_DimSum"

-------------------------------------------------------------------------------
--  Spellbook (rank-agnostic Known) and spell lookups
-------------------------------------------------------------------------------
EABR._spellbook = {}
function EABR.ScanSpellbook()
    local book = EABR._spellbook
    wipe(book)
    local bookType = BOOKTYPE_SPELL or "spell"
    for slot = 1, 1024 do
        local name = GetSpellName(slot, bookType)
        if not name then break end
        book[name] = slot
    end
end

function EABR.SpellName(id, fallback)
    if not id then return fallback end
    local tab, index = EABR.TalentFromKey and EABR.TalentFromKey(id)
    if tab then return (GetTalentInfo(tab, index)) or fallback end
    return (GetSpellInfo(id)) or fallback
end

function EABR.Known(id)
    local name = id and GetSpellInfo(id)
    return name ~= nil and EABR._spellbook[name] ~= nil
end

-- Talent reminder keys encode tab*100+index above this base; they resolve to
-- the talent's icon so the options list can draw them like spells.
EABR.TALENT_KEY_BASE = 900000
function EABR.TalentFromKey(id)
    id = tonumber(id)
    if not id or id < EABR.TALENT_KEY_BASE then return nil end
    local v = id - EABR.TALENT_KEY_BASE
    return floor(v / 100), v % 100
end

local texCache = {}
function EABR.Tex(id)
    if not id then return nil end
    local c = texCache[id]; if c then return c end
    local tab, index = EABR.TalentFromKey(id)
    local t
    if tab then
        local _, icon = GetTalentInfo(tab, index)
        t = icon
    else
        t = select(3, GetSpellInfo(id))
    end
    if t then texCache[id] = t end
    return t
end

function EABR.ItemIcon(id)
    return id and (GetItemIcon and GetItemIcon(id) or select(10, GetItemInfo(id))) or nil
end

-- Dominant talent tree (1-3), Wrath's stand-in for a Retail specialization.
function EABR.GetSpecTab()
    if not GetNumTalentTabs then return nil end
    local group = GetActiveTalentGroup and GetActiveTalentGroup() or 1
    local best, bestPoints = nil, 0
    for tab = 1, (GetNumTalentTabs() or 0) do
        local _, _, points = GetTalentTabInfo(tab, false, false, group)
        points = tonumber(points) or 0
        if points > bestPoints then best, bestPoints = tab, points end
    end
    return best
end

-- Synthetic spec ID matching the compat C_SpecializationInfo shape.
local CLASS_IDS = { WARRIOR=1, PALADIN=2, HUNTER=3, ROGUE=4, PRIEST=5, DEATHKNIGHT=6, SHAMAN=7, MAGE=8, WARLOCK=9, DRUID=11 }
function EABR.GetSpecID()
    local tab = EABR.GetSpecTab()
    if not tab then return nil end
    local _, class = UnitClass("player")
    return 33000 + (CLASS_IDS[class] or 0) * 10 + tab
end
function EABR.SpecIDFor(class, tab) return 33000 + (CLASS_IDS[class] or 0) * 10 + tab end

local HEALER_TABS = { PRIEST = { [1]=true, [2]=true }, PALADIN = { [1]=true }, SHAMAN = { [3]=true }, DRUID = { [3]=true } }
function EABR.PlayerIsHealer()
    local _, class = UnitClass("player")
    local tabs = HEALER_TABS[class]
    return tabs and tabs[EABR.GetSpecTab() or 0] or false
end

-------------------------------------------------------------------------------
--  Group helpers (Wrath has no IsInGroup / GetNumGroupMembers)
-------------------------------------------------------------------------------
function EABR.InRaid() return (GetNumRaidMembers() or 0) > 0 end
function EABR.InGroup() return EABR.InRaid() or (GetNumPartyMembers() or 0) > 0 end

local raidTokens, partyTokens = {}, {}
for i = 1, 40 do raidTokens[i] = "raid" .. i end
for i = 1, 4 do partyTokens[i] = "party" .. i end
local rosterScratch = {}
-- Group units including the player (raid tokens in a raid, else player+party).
function EABR.GroupUnits()
    wipe(rosterScratch)
    if EABR.InRaid() then
        for i = 1, GetNumRaidMembers() do rosterScratch[#rosterScratch + 1] = raidTokens[i] end
    else
        rosterScratch[1] = "player"
        for i = 1, GetNumPartyMembers() do rosterScratch[#rosterScratch + 1] = partyTokens[i] end
    end
    return rosterScratch
end

function EABR.UnitOk(u)
    return UnitExists(u) and UnitIsConnected(u) and not UnitIsDeadOrGhost(u)
end

function EABR.UnitInRangeOk(u)
    if UnitIsUnit(u, "player") then return true end
    if UnitInRange then
        local inRange = UnitInRange(u)
        if inRange ~= nil and not inRange then return false end
    end
    return not UnitIsVisible or UnitIsVisible(u) and true or false
end

-------------------------------------------------------------------------------
--  Aura helpers: all ranks share a name, so every match is by name.
-------------------------------------------------------------------------------
local nameSets = setmetatable({}, { __mode = "k" })
function EABR.NameSet(ids)
    local s = nameSets[ids]
    if s and s._n == #ids then return s end
    s = { _n = #ids }
    for _, id in ipairs(ids) do
        local n = GetSpellInfo(id)
        if n then s[n] = true end
    end
    nameSets[ids] = s
    return s
end

local function FromPlayer(caster)
    return caster == "player" or caster == "pet" or caster == "vehicle"
end
EABR.FromPlayer = FromPlayer

-- Returns found, duration, expirationTime of the first aura on unit whose
-- name is in ids. ownOnly limits to the player's casts.
function EABR.FindAura(unit, ids, ownOnly, filter)
    local names = EABR.NameSet(ids)
    for i = 1, 40 do
        local name, _, _, _, _, duration, expires, caster = UnitAura(unit, i, filter or "HELPFUL")
        if not name then break end
        if names[name] and (not ownOnly or FromPlayer(caster)) then
            return true, duration or 0, expires or 0, caster
        end
    end
    return false
end

function EABR.FindAuraByName(unit, auraName, filter)
    if not auraName then return false end
    for i = 1, 40 do
        local name, _, _, _, _, duration, expires = UnitAura(unit, i, filter or "HELPFUL")
        if not name then break end
        if name == auraName then return true, duration or 0, expires or 0 end
    end
    return false
end

-------------------------------------------------------------------------------
--  Instance and "Where to Show" buckets
-------------------------------------------------------------------------------
-- open_world, raid_heroic, raid_normal_lfr (normal 10/25), dungeon_heroic,
-- dungeon_nonmythic (normal); nil for PvP so reminders never silently vanish.
function EABR.CacheInstanceInfo()
    local inInstance, iType = IsInInstance()
    local name, _, diff, _, _, dynDiff, isDynamic = GetInstanceInfo()
    EABR._iType = inInstance and iType or "none"
    EABR._iName = name
    EABR._diff = tonumber(diff) or 0
    EABR._heroic = (iType == "party" and EABR._diff == 2)
        or (iType == "raid" and (EABR._diff == 3 or EABR._diff == 4 or (isDynamic and dynDiff == 1)))
end

function EABR.InInstance()
    local t = EABR._iType
    return t == "party" or t == "raid" or t == "pvp" or t == "arena"
end

function EABR.InPvPInstance()
    return EABR._iType == "pvp" or EABR._iType == "arena"
end

function EABR.CurrentWhereBucket(inInstance)
    local t = EABR._iType
    if t == "raid" then return EABR._heroic and "raid_heroic" or "raid_normal_lfr" end
    if t == "party" then return EABR._heroic and "dungeon_heroic" or "dungeon_nonmythic" end
    if not inInstance then return "open_world" end
    return nil
end

function EABR.InCombat() return EABR._inCombat or InCombatLockdown() end

function EABR.SectionShows(whereToShow, inInstance)
    if whereToShow and whereToShow.in_combat == false and EABR.InCombat() then return false end
    local bucket = EABR.CurrentWhereBucket(inInstance)
    if not bucket or not whereToShow then return true end
    return whereToShow[bucket] ~= false
end

function EABR.ShowUnderThresholdApplies() return not EABR.InCombat() end

-- True when a timed buff falls under the global "Show Below" minutes; arms
-- the next refresh for the soonest threshold crossing otherwise.
function EABR.IsUnderDuration(duration, expirationTime)
    if not (duration and expirationTime) or duration <= 0 or expirationTime <= 0 then return false end
    if not EABR.ShowUnderThresholdApplies() then return false end
    local p = EABR.db and EABR.db.profile
    local thresholdSeconds = ((p and p.display and p.display.showUnder) or 5) * 60
    if thresholdSeconds <= 0 or duration < thresholdSeconds then return false end
    local now = GetTime()
    if expirationTime - now < thresholdSeconds then return true end
    local refreshAt = expirationTime - thresholdSeconds
    if not EABR._nextDurationRefreshTime or refreshAt < EABR._nextDurationRefreshTime then
        EABR._nextDurationRefreshTime = refreshAt
    end
    return false
end

-------------------------------------------------------------------------------
--  Spell data
-------------------------------------------------------------------------------
-- castSpell is rank 1 (name/icon source); groupSpell is the party-wide
-- version, cast when grouped and usable (reagents present).
EABR.RAID_BUFFS = {
    { key="motw",   class="DRUID",       name="Mark of the Wild",        castSpell=1126,  groupSpell=21849, buffIDs={1126, 21849}, check="raid" },
    { key="fort",   class="PRIEST",      name="Power Word: Fortitude",   castSpell=1243,  groupSpell=21562, buffIDs={1243, 21562}, check="raid" },
    { key="spirit", class="PRIEST",      name="Divine Spirit",           castSpell=14752, groupSpell=27681, buffIDs={14752, 27681}, check="raid", benefit="intellect" },
    { key="shadow", class="PRIEST",      name="Shadow Protection",       castSpell=976,   groupSpell=27683, buffIDs={976, 27683}, check="raid" },
    { key="ai",     class="MAGE",        name="Arcane Intellect",        castSpell=1459,  groupSpell=23028, buffIDs={1459, 23028, 61024, 61316}, check="raid", benefit="intellect" },
    { key="bshout", class="WARRIOR",     name="Battle Shout",            castSpell=6673,  buffIDs={6673, 19740, 25782}, check="raid", benefit="attackPower" },
    { key="horn",   class="DEATHKNIGHT", name="Horn of Winter",          castSpell=57330, buffIDs={57330, 8076}, check="raid", benefit="attackPower" },
    { key="kings",  class="PALADIN",     name="Blessing of Kings",       castSpell=20217, groupSpell=25898, buffIDs={20217, 25898, 69378}, check="raid" },
}

local function SpecCast(byTab, fallback)
    return function()
        local id = byTab[EABR.GetSpecTab() or 0]
        if id and EABR.Known(id) then return id end
        for _, alt in ipairs(fallback or {}) do if EABR.Known(alt) then return alt end end
        return id or (fallback and fallback[1])
    end
end
local function FirstKnown(list)
    return function()
        for _, id in ipairs(list) do if EABR.Known(id) then return id end end
        return list[1]
    end
end

EABR.AURAS = {
    { key="inner_fire",       class="PRIEST",  name="Inner Fire",        castSpell=588,   buffIDs={588}, check="player" },
    { key="shadowform",       class="PRIEST",  name="Shadowform",        castSpell=15473, buffIDs={15473}, check="player", specTabs={3} },
    { key="vampiric_embrace", class="PRIEST",  name="Vampiric Embrace",  castSpell=15286, buffIDs={15286}, check="player", specTabs={3} },
    { key="mage_armor",       class="MAGE",    name="Mage Armor",        castSpell=6117,  buffIDs={30482, 6117, 7302, 168}, check="player",
      castSpellFn=FirstKnown({30482, 6117, 7302, 168}) },
    { key="demon_armor",      class="WARLOCK", name="Fel Armor",         castSpell=28176, buffIDs={28176, 706, 687}, check="player",
      castSpellFn=FirstKnown({28176, 706, 687}) },
    { key="aspect",           class="HUNTER",  name="Aspect of the Dragonhawk", castSpell=61846, buffIDs={61846, 13165, 34074, 13163, 13161, 20043}, check="player",
      castSpellFn=FirstKnown({61846, 13165}) },
    { key="trueshot",         class="HUNTER",  name="Trueshot Aura",     castSpell=19506, buffIDs={19506}, check="player", ownOnly=true, specTabs={2} },
    { key="pala_aura",        class="PALADIN", name="Devotion Aura",     castSpell=465,   buffIDs={465, 7294, 19746, 19876, 19888, 19891}, check="player", ownOnly=true, noMounted=true,
      castSpellFn=SpecCast({ [1]=19746, [2]=465, [3]=7294 }, {465}) },
    { key="seal_wisdom",      class="PALADIN", name="Seal of Wisdom", castSpell=20166, buffIDs={20166}, check="player", ownOnly=true, specTabs={1} },
    { key="seal",             class="PALADIN", name="Seal of Righteousness", castSpell=21084, buffIDs={21084, 20375, 20165, 20166, 20164, 31801, 53736}, check="player", ownOnly=true, excludeSpecTabs={1},
      castSpellFn=SpecCast({ [1]=20166, [2]=31801, [3]=20375 }, {53736, 21084}) },
    { key="righteous_fury",   class="PALADIN", name="Righteous Fury",    castSpell=25780, buffIDs={25780}, check="player", specTabs={2} },
    { key="battle_stance",    class="WARRIOR", name="Battle Stance",     castSpell=2457,  check="player", specTabs={1}, isStance=true },
    { key="berserk_stance",   class="WARRIOR", name="Berserker Stance",  castSpell=2458,  check="player", specTabs={2}, isStance=true },
    { key="def_stance",       class="WARRIOR", name="Defensive Stance",  castSpell=71,    check="player", specTabs={3}, isStance=true },
    -- Soulstone: satisfied by this Warlock's own stone on anyone in the group.
    { key="soulstone",        class="WARLOCK", name="Soulstone Resurrection", castSpell=20707, buffIDs={20707}, check="ownGroupOrSelf" },
}

for _, def in ipairs(EABR.AURAS) do
    if def.specTabs then
        def.specs = {}
        for i, tab in ipairs(def.specTabs) do def.specs[i] = EABR.SpecIDFor(def.class, tab) end
    end
end

EABR.SOULSTONE_ITEMS = { 36895, 22116, 16896, 16895, 16893, 16892, 5232 }
EABR.CREATE_SOULSTONE = 693

EABR.HEALTHSTONE_ITEM_IDS = {
    36892, 36893, 36894, 22103, 22104, 22105, 9421, 19012, 19013,
    5510, 19010, 19011, 5509, 19008, 19009, 5511, 19006, 19007, 5512, 19004, 19005,
}
EABR.CREATE_HEALTHSTONE = 6201

EABR.PET_CLASSES = { HUNTER = true, WARLOCK = true, DEATHKNIGHT = true }

-- Rogue poisons are bag items in Wrath; any poison on a hand satisfies it.
EABR.ROGUE_POISONS = {
    { key="deadly",      name="Deadly Poison",       castSpell=2823,  cat="lethal",    items={43233, 43232, 22054, 22053, 20844, 8985, 8984, 2893, 2892} },
    { key="instant",     name="Instant Poison",      castSpell=8679,  cat="lethal",    items={43231, 43230, 21927, 8928, 8927, 8926, 6950, 6949, 6947} },
    { key="wound",       name="Wound Poison",        castSpell=13219, cat="lethal",    items={43235, 43234, 22055, 10922, 10921, 10920, 10918} },
    { key="crippling",   name="Crippling Poison",    castSpell=3408,  cat="nonlethal", items={3775, 3776} },
    { key="mindnumbing", name="Mind-numbing Poison", castSpell=5761,  cat="nonlethal", items={5237, 6951, 9186} },
    { key="anesthetic",  name="Anesthetic Poison",   castSpell=26785, cat="nonlethal", items={43237, 21835} },
}

EABR.PALADIN_RITES = {}

-- Shaman weapon imbues; hand = which weapon each spec prefers it on.
EABR.SHAMAN_IMBUES = {
    { key="windfury",    name="Windfury Weapon",    castSpell=8232 },
    { key="flametongue", name="Flametongue Weapon", castSpell=8024 },
    { key="frostbrand",  name="Frostbrand Weapon",  castSpell=8033 },
    { key="rockbiter",   name="Rockbiter Weapon",   castSpell=8017 },
    { key="earthliving", name="Earthliving Weapon", castSpell=51730 },
}
-- Main/off-hand imbue preference per talent tree (Elemental, Enhancement, Restoration).
EABR.SHAMAN_IMBUE_SPEC = {
    [1] = { "flametongue", "flametongue" },
    [2] = { "windfury", "flametongue" },
    [3] = { "earthliving", "earthliving" },
}

EABR.SHAMAN_SHIELDS = {
    { key="shield_basic", name="Lightning/Water Shield", buffIDs={324, 52127}, check="player",
      castSpellFn=function() return (EABR.GetSpecTab() == 3 and EABR.Known(52127)) and 52127 or 324 end, castSpell=324 },
    { key="es_ally", name="Earth Shield (Ally)", castSpell=974, buffIDs={974} },
}

-- Warlock permanent demons; petSpell is a signature ability in the pet's
-- spellbook, which identifies the demon without localized family names.
EABR.WARLOCK_PETS = {
    { key="felguard",   name="Felguard",   castSpell=30146, petSpell=30213 },
    { key="imp",        name="Imp",        castSpell=688,   petSpell=3110 },
    { key="voidwalker", name="Voidwalker", castSpell=697,   petSpell=3716 },
    { key="succubus",   name="Succubus",   castSpell=712,   petSpell=7814 },
    { key="felhunter",  name="Felhunter",  castSpell=691,   petSpell=19505 },
}
EABR.DEMONIC_SACRIFICE_BUFFS = { 18789, 18790, 18791, 18792, 35701 }

-- Temporary weapon enchant items (stones and oils).
EABR.WEAPON_ENCHANT_ITEMS = {
    { itemID=20749, name="Brilliant Wizard Oil",         weaponType="NEUTRAL" },
    { itemID=22522, name="Superior Wizard Oil",          weaponType="NEUTRAL" },
    { itemID=22521, name="Superior Mana Oil",            weaponType="NEUTRAL" },
    { itemID=20748, name="Brilliant Mana Oil",           weaponType="NEUTRAL" },
    { itemID=23529, name="Adamantite Sharpening Stone",  weaponType="BLADED" },
    { itemID=23528, name="Fel Sharpening Stone",         weaponType="BLADED" },
    { itemID=28421, name="Adamantite Weightstone",       weaponType="BLUNT" },
    { itemID=28420, name="Fel Weightstone",              weaponType="BLUNT" },
}
EABR.WEAPON_ENCHANT_CHOICES = {
    { key="brilliant_wizard_oil",   name="Brilliant Wizard Oil",        itemID=20749 },
    { key="superior_wizard_oil",    name="Superior Wizard Oil",         itemID=22522 },
    { key="superior_mana_oil",      name="Superior Mana Oil",           itemID=22521 },
    { key="brilliant_mana_oil",     name="Brilliant Mana Oil",          itemID=20748 },
    { key="adamantite_sharpening",  name="Adamantite Sharpening Stone", itemID=23529 },
    { key="adamantite_weightstone", name="Adamantite Weightstone",      itemID=28421 },
}

EABR.FLASK_ITEMS = {
    { key="frost_wyrm",         buffID=53755, name="Flask of the Frost Wyrm",        items={46376} },
    { key="endless_rage",       buffID=53760, name="Flask of Endless Rage",          items={46377} },
    { key="pure_mojo",          buffID=54212, name="Flask of Pure Mojo",             items={46378} },
    { key="stoneblood",         buffID=53758, name="Flask of Stoneblood",            items={46379} },
    { key="lesser_toughness",   buffID=53752, name="Lesser Flask of Toughness",      items={40079} },
    { key="lesser_resistance",  buffID=62380, name="Lesser Flask of Resistance",     items={44939} },
    { key="relentless_assault", buffID=28520, name="Flask of Relentless Assault",    items={22854} },
    { key="mighty_restoration", buffID=28519, name="Flask of Mighty Restoration",    items={22853} },
    { key="fortification",      buffID=28518, name="Flask of Fortification",         items={22851} },
    { key="supreme_power",      buffID=17628, name="Flask of Supreme Power",         items={13512} },
    { key="distilled_wisdom",   buffID=17627, name="Flask of Distilled Wisdom",      items={13511} },
    { key="titans",             buffID=17626, name="Flask of the Titans",            items={13510} },
}

EABR.FOOD_ITEMS = {
    { key="fish_feast",           itemID=43015, name="Fish Feast" },
    { key="great_feast",          itemID=34753, name="Great Feast" },
    { key="gigantic_feast",       itemID=43478, name="Gigantic Feast" },
    { key="small_feast",          itemID=43480, name="Small Feast" },
    { key="dragonfin_filet",      itemID=43000, name="Dragonfin Filet" },
    { key="blackened_dragonfin",  itemID=42999, name="Blackened Dragonfin" },
    { key="firecracker_salmon",   itemID=34767, name="Firecracker Salmon" },
    { key="imperial_manta_steak", itemID=34769, name="Imperial Manta Steak" },
    { key="mega_mammoth_meal",    itemID=34754, name="Mega Mammoth Meal" },
    { key="tender_shoveltusk",    itemID=34755, name="Tender Shoveltusk Steak" },
    { key="spiced_worm_burger",   itemID=34756, name="Spiced Worm Burger" },
    { key="very_burnt_worg",      itemID=34757, name="Very Burnt Worg" },
    { key="mighty_rhino_dogs",    itemID=34758, name="Mighty Rhino Dogs" },
    { key="smoked_rockfin",       itemID=34759, name="Smoked Rockfin" },
    { key="grilled_bonescale",    itemID=34760, name="Grilled Bonescale" },
    { key="sauteed_goby",         itemID=34761, name="Sauteed Goby" },
    { key="grilled_sculpin",      itemID=34762, name="Grilled Sculpin" },
    { key="smoked_salmon",        itemID=34763, name="Smoked Salmon" },
    { key="poached_nettlefish",   itemID=34764, name="Poached Nettlefish" },
    { key="pickled_fangtooth",    itemID=34765, name="Pickled Fangtooth" },
    { key="poached_sculpin",      itemID=34766, name="Poached Northern Sculpin" },
    { key="spicy_blue_nettlefish", itemID=34768, name="Spicy Blue Nettlefish" },
    { key="spicy_fried_herring",  itemID=42993, name="Spicy Fried Herring" },
    { key="rhinolicious",         itemID=42994, name="Rhinolicious Wormsteak" },
    { key="hearty_rhino",         itemID=42995, name="Hearty Rhino" },
    { key="snapper_extreme",      itemID=42996, name="Snapper Extreme" },
    { key="blackened_worg_steak", itemID=42997, name="Blackened Worg Steak" },
    { key="cuttlesteak",          itemID=42998, name="Cuttlesteak" },
    { key="dalaran_clam_chowder", itemID=43268, name="Dalaran Clam Chowder" },
}

EABR.FLASK_BUFF_IDS = {}
for _, f in ipairs(EABR.FLASK_ITEMS) do EABR.FLASK_BUFF_IDS[#EABR.FLASK_BUFF_IDS + 1] = f.buffID end
EABR.WELL_FED_SPELL = 19705
EABR.FOOD_SPELL = 433
EABR.RUNEFORGING_SPELL = 53428
EABR.RAISE_DEAD = 46584
EABR.CALL_PET = 883
EABR.REVIVE_PET = 982

-- Classes that carry mana or melee power, for the receiver ("I am missing")
-- view and group coverage of stat-specific buffs.
EABR.BUFF_BENEFICIARIES = {
    intellect = { MAGE=true, WARLOCK=true, PRIEST=true, DRUID=true, SHAMAN=true, PALADIN=true, HUNTER=true },
    attackPower = { WARRIOR=true, ROGUE=true, HUNTER=true, DEATHKNIGHT=true, PALADIN=true, SHAMAN=true, DRUID=true },
}
function EABR.UnitBenefits(u, benefit)
    local set = benefit and EABR.BUFF_BENEFICIARIES[benefit]
    if not set then return true end
    local _, class = UnitClass(u)
    return class ~= nil and set[class] == true
end

-------------------------------------------------------------------------------
--  Talent reminder zones (English names; the options picker also offers the
--  current instance under its client name).
-------------------------------------------------------------------------------
EABR.TALENT_REMINDER_ZONES = {
    { name="Icecrown Citadel",          type="raid" },
    { name="The Ruby Sanctum",          type="raid" },
    { name="Trial of the Crusader",     type="raid" },
    { name="Onyxia's Lair",             type="raid" },
    { name="Ulduar",                    type="raid" },
    { name="Naxxramas",                 type="raid" },
    { name="The Obsidian Sanctum",      type="raid" },
    { name="The Eye of Eternity",       type="raid" },
    { name="Vault of Archavon",         type="raid" },
    { name="The Forge of Souls",        type="dungeon" },
    { name="Pit of Saron",              type="dungeon" },
    { name="Halls of Reflection",       type="dungeon" },
    { name="Trial of the Champion",     type="dungeon" },
    { name="The Culling of Stratholme", type="dungeon" },
    { name="Utgarde Pinnacle",          type="dungeon" },
    { name="The Oculus",                type="dungeon" },
    { name="Halls of Lightning",        type="dungeon" },
    { name="Halls of Stone",            type="dungeon" },
    { name="Gundrak",                   type="dungeon" },
    { name="The Violet Hold",           type="dungeon" },
    { name="Drak'Tharon Keep",          type="dungeon" },
    { name="Ahn'kahet: The Old Kingdom", type="dungeon" },
    { name="Azjol-Nerub",               type="dungeon" },
    { name="The Nexus",                 type="dungeon" },
    { name="Utgarde Keep",              type="dungeon" },
    { name="Nagrand Arena",             type="pvp" },
    { name="Blade's Edge Arena",        type="pvp" },
    { name="Ruins of Lordaeron",        type="pvp" },
    { name="Dalaran Arena",             type="pvp" },
    { name="The Ring of Valor",         type="pvp" },
    { name="Warsong Gulch",             type="pvp" },
    { name="Arathi Basin",              type="pvp" },
    { name="Alterac Valley",            type="pvp" },
    { name="Eye of the Storm",          type="pvp" },
    { name="Strand of the Ancients",    type="pvp" },
    { name="Isle of Conquest",          type="pvp" },
    { name="Wintergrasp",               type="pvp" },
}

-------------------------------------------------------------------------------
--  Text, glow and border shared definitions
-------------------------------------------------------------------------------
EABR.DEFAULT_TEXT_COLOR = { r=1, g=1, b=1 }
EABR.TEXT_ANCHOR_POINTS = {
    BOTTOM = { "TOP",    "BOTTOM" },
    TOP    = { "BOTTOM", "TOP"    },
    CENTER = { "CENTER", "CENTER" },
    LEFT   = { "RIGHT",  "LEFT"   },
    RIGHT  = { "LEFT",   "RIGHT"  },
}
function EABR.GetTextAnchorPoints(p)
    local m = EABR.TEXT_ANCHOR_POINTS[(p and p.textAnchor) or "BOTTOM"] or EABR.TEXT_ANCHOR_POINTS.BOTTOM
    return m[1], m[2]
end

local LABEL_OVERRIDES = {
    ["Battle Stance"] = "Stance", ["Defensive Stance"] = "Stance", ["Berserker Stance"] = "Stance",
    ["Devotion Aura"] = "Aura", ["Power Word: Fortitude"] = "Fortitude", ["Arcane Intellect"] = "Intellect",
    ["Battle Shout"] = "Shout", ["Earth Shield (Ally)"] = "Ally", ["Divine Spirit"] = "Spirit",
    ["Shadow Protection"] = "Shadow", ["Blessing of Kings"] = "Kings", ["Mark of the Wild"] = "Mark",
}
local LABEL_CLASS_OVERRIDES = { ROGUE = "Poison", SHAMAN_IMBUE = "Weapon", SHAMAN_SHIELD = "Shield" }
function EABR.ShortLabel(name, classOverride)
    if classOverride and LABEL_CLASS_OVERRIDES[classOverride] then
        return E.L(LABEL_CLASS_OVERRIDES[classOverride])
    end
    if not name then return "" end
    if LABEL_OVERRIDES[name] then return LABEL_OVERRIDES[name] end
    return name:match("^(%S+)") or name
end

EABR.GLOW_VIEW = E.Glows and E.Glows.MakeView and E.Glows.MakeView({ 2, 1, 3, 5, 6, 7 })

-- Per-profile fixups at the read path: corrupt scale resets, glow color mode
-- derives once from the stored color.
function EABR.EnsureGlowModeMigrated(p)
    if not p then return end
    local s = p.scale
    if type(s) == "number" and (s < 0.5 or s > 3.0) then p.scale = 1.0 end
    if p.glowColorMode then return end
    local c = p.glowColor
    if c and not (c.r == 1 and c.g == 0.776 and c.b == 0.376) then
        p.glowColorMode = "custom"
    else
        p.glowColorMode = "default"
    end
end

function EABR.ResolveGlowTint(p)
    if not p then return nil end
    EABR.EnsureGlowModeMigrated(p)
    if p.glowColorMode == "class" then
        local cc = E.GetClassColor(E._playerClass or select(2, UnitClass("player")))
        return cc.r, cc.g, cc.b
    end
    if p.glowColorMode ~= "custom" then return nil end
    local c = p.glowColor
    if not c then return nil end
    return c.r or 1, c.g or 0.776, c.b or 0.376
end

do
    local function AllBorderSizes(ox, oy, sx, sy)
        local t = {}
        for size = 0, 4 do t[size] = { offsetX = ox, offsetY = oy, shiftX = sx, shiftY = sy } end
        return t
    end
    if E.RegisterBorderDefaults then
        E.RegisterBorderDefaults("aurabuffreminders", {
            glow = { defaultSize = 1, sizes = AllBorderSizes(0, 0, 0, 0) },
            blizz = { defaultSize = 4, sizes = {
                [0] = { offsetX = 0, offsetY = 0, shiftX = 0, shiftY = 0 },
                [1] = { offsetX = 2, offsetY = 1, shiftX = 0, shiftY = 0 },
                [2] = { offsetX = 3, offsetY = 1, shiftX = 1, shiftY = 0 },
                [3] = { offsetX = 4, offsetY = 2, shiftX = 2, shiftY = 0 },
                [4] = { offsetX = 5, offsetY = 3, shiftX = 2, shiftY = 0 },
            } },
            dialog = { defaultSize = 2, sizes = {
                [0] = { offsetX = 0, offsetY = 0, shiftX = 0, shiftY = 0 },
                [1] = { offsetX = 2, offsetY = 2, shiftX = 0, shiftY = 0 },
                [2] = { offsetX = 2, offsetY = 2, shiftX = 0, shiftY = 0 },
                [3] = { offsetX = 4, offsetY = 4, shiftX = 0, shiftY = 0 },
                [4] = { offsetX = 8, offsetY = 8, shiftX = 0, shiftY = 0 },
            } },
            ["sm:Blizzard Achievement Wood"] = { defaultSize = 1, sizes = AllBorderSizes(1, 1, 0, 0) },
        })
    end
end

-------------------------------------------------------------------------------
--  Defaults (Retail schema; Wrath keys)
-------------------------------------------------------------------------------
EABR.defaults = {
    profile = {
        display = {
            remindersEnabled = true,
            glowType = 0,
            scale = 1.0,
            xOffset = 0,
            yOffset = 200,
            showText = true,
            showTooltips = true,
            textColor = { r=1, g=1, b=1 },
            textSize = 12,
            textXOffset = 0,
            textYOffset = -5,
            textAnchor = "BOTTOM",
            showCount = true,
            countSize = 16,
            countXOffset = 0,
            countYOffset = 0,
            iconSpacing = 14,
            growDirection = "CENTER",
            opacity = 1.0,
            frameStrata = "MEDIUM",
            cursorAttach = false,
            borderTexture = "solid",
            borderSize = 1,
            borderR = 0, borderG = 0, borderB = 0, borderA = 1,
            borderBehind = false,
            showUnder = 5,
        },
        raidBuffs = {
            enabled = { motw=true, fort=true, spirit=true, shadow=true, ai=true, bshout=true, horn=true, kings=false },
            whereToShow = { open_world = false },
            showWhen = { othersMissing = true, iAmMissing = false },
        },
        auras = {
            enabled = {
                inner_fire=true, shadowform=true, vampiric_embrace=true, mage_armor=true, demon_armor=true,
                aspect=true, trueshot=true, pala_aura=true, seal=true, seal_wisdom=true, righteous_fury=true,
                battle_stance=true, berserk_stance=true, def_stance=true,
                soulstone=false,
            },
            whereToShow = {},
        },
        consumables = {
            showWithoutItem = true,
            enabled = {
                deadly=true, instant=true, wound=false, crippling=false, mindnumbing=false, anesthetic=false,
                windfury=true, flametongue=true, frostbrand=false, rockbiter=false, earthliving=true,
                shield_basic=true, es_ally=false,
                weapon_enchant=false, flask=true, food=true,
            },
            whereToShow = { open_world = false },
            specialsWhereToShow = {},
            warlockWhereToShow = {},
            wrongPetAllowed = { felguard = true },
            preferredFlask = "last_used",
            preferredFood = "last_used",
            preferredWeaponEnchant = "last_used",
        },
        custom = {
            whereToShow = {},
            customIDs = {},
        },
        unlockPos = nil,
        talentReminders = {},
    },
}
