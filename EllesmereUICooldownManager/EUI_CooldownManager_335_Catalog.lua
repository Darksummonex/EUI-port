local _,ns=...
-- Wrath spell IDs are name/rank anchors; only learned cooldown spells render.
ns.catalog={
 WARRIOR={cooldowns={1719,12292,46924,23920,871,12975,2565,676,6552,5246,3411,1680},utility={100,20252,3411,18499,55694,1160},buffs={46916,52437,18499,12292,1719}},
 PALADIN={cooldowns={31884,642,498,633,1044,1022,6940,1038,31821,20216,20473,31935,53385},utility={853,20066,96231,62124,54428,19752},buffs={31884,53601,53563,54149,59578,642}},
 HUNTER={cooldowns={3045,19574,19263,5384,23989,34490,53301,53209,19386},utility={781,1543,13809,1499,34477,20736,19801},buffs={19574,3045,56453,56342,53220}},
 ROGUE={cooldowns={13750,13877,51690,14177,14185,5277,31224,1856,57934,1766,51713},utility={2983,2094,1725,1776,408,51722},buffs={5171,32645,14177,51713,31665}},
 PRIEST={cooldowns={10060,33206,47788,47585,34433,64843,64901,47540,33076},utility={6346,586,15487,64044,10890},buffs={10060,33206,47788,59887,33151,63731,15286}},
 DEATHKNIGHT={cooldowns={48792,48707,49016,55233,51271,49206,51052,47568,49222,49028,48982,42650},utility={49576,47528,47476,48743,57330,49998},buffs={48792,48707,59052,51124,51271,55233}},
 SHAMAN={cooldowns={2825,32182,16188,16166,16190,30823,51533,51514,57994},utility={20608,8177,2484,5394,2894,2062},buffs={53817,53390,16246,49281,2825,32182}},
 MAGE={cooldowns={12042,12472,11129,11958,31687,45438,12051,2139,44572,55342},utility={1953,122,120,543,1463,66,30449},buffs={44401,48108,57761,44544,12042,12472,11129}},
 WARLOCK={cooldowns={47897,17962,50796,48181,47241,18540,1122,19647,7812},utility={48020,6789,5484,18220,18708,29858,17928},buffs={54277,34936,71165,47241,17941}},
 DRUID={cooldowns={17116,50334,61336,22812,22842,29166,48477,18562,50516,48505,33831},utility={5229,5217,1850,8983,6795,5209},buffs={16870,48517,48518,69369,5217,50334,22812}},
}
-- Retail RACE_RACIALS with the Wrath spell IDs (class variants share one slot).
ns.RACE_RACIALS={
 Human={59752},Dwarf={20594},NightElf={58984},Gnome={20589},
 Draenei={28880,59542,59543,59544,59545,59547,59548},
 Orc={20572,33697,33702},Scourge={7744},Tauren={20549},Troll={26297},
 BloodElf={28730,25046,50613},
}
ns.racials,ns.RACIAL_GROUP={},{}
for _,list in pairs(ns.RACE_RACIALS) do for _,id in ipairs(list) do ns.racials[#ns.racials+1]=id; ns.RACIAL_GROUP[id]=list[1] end end
table.sort(ns.racials)
-- Variants resolve by name to the one spell the character knows, so a bar keeps a
-- single entry per racial (older seeds added every variant: three Arcane Torrents).
function ns.CollapseRacials(lists)
    for _,list in pairs(lists) do
        if type(list)=="table" and list[1]~=nil then
            local seen,i={},1
            while list[i] do
                local e=list[i]; local g=type(e)=="table" and (e.kind or "spell")=="spell" and ns.RACIAL_GROUP[tonumber(e.id) or 0]
                if g and seen[g] then
                    if e.enabled~=false then seen[g].enabled=true end
                    table.remove(list,i)
                else
                    if g then seen[g]=e end
                    i=i+1
                end
            end
        end
    end
end
-- Retail CDM_ITEM_PRESETS with Wrath consumables. items is the display order:
-- the first one in the bags is shown; swapWith follows when a family runs out.
ns.ITEM_PRESETS={
 {key="healthstone",name="Healthstone",items={36892,36893,36894,36889,36890,36891,22103,22104,22105,9421,19012,19013}},
 {key="runic_healing",name="Runic Healing Potion",items={33447,43569,41166,22829}},
 {key="runic_mana",name="Runic Mana Potion",items={33448,43570,42545,22832}},
 {key="potion_speed",name="Potion of Speed",items={40211},swapWith={"potion_wild_magic","indestructible"}},
 {key="potion_wild_magic",name="Potion of Wild Magic",items={40212},swapWith={"potion_speed","indestructible"}},
 {key="indestructible",name="Indestructible Potion",items={40093},swapWith={"potion_speed","potion_wild_magic"}},
 {key="saronite_bomb",name="Saronite Bomb",items={41119,40771}},
}
ns.ITEM_PRESET_BY_KEY={}
for _,p in ipairs(ns.ITEM_PRESETS) do ns.ITEM_PRESET_BY_KEY[p.key]=p end
-- Retail BUFF_BAR_PRESETS for Tracking Bars and buff bars. Wrath auras are readable,
-- so Bloodlust/Heroism track the buff itself instead of the Sated debuff edge.
ns.BUFF_PRESETS={
 {key="bloodlust",name="Bloodlust / Heroism",ids={2825,32182},icon="Interface\\Icons\\Spell_Nature_BloodLust"},
 {key="potion_speed",name="Potion of Speed",ids={53908}},
 {key="potion_wild_magic",name="Potion of Wild Magic",ids={53909}},
 {key="indestructible",name="Indestructible Potion",ids={53762}},
 {key="hyperspeed",name="Hyperspeed Acceleration",ids={54758}},
 {key="tricks",name="Tricks of the Trade",ids={57933}},
 {key="power_infusion",name="Power Infusion",ids={10060}},
 {key="innervate",name="Innervate",ids={29166}},
}
ns.BUFF_PRESET_BY_KEY={}
for _,p in ipairs(ns.BUFF_PRESETS) do ns.BUFF_PRESET_BY_KEY[p.key]=p end
-- Proc glow on Wrath: no spell activation overlay exists, so procs come from
-- the player's own proc buffs. [spellID]={auraID,minStacks}.
ns.PROC_AURAS={
 [879]={59578},[19750]={59578},[635]={54149},                 -- Art of War, Infusion of Light
 [133]={57761},[44614]={57761},[11366]={48108},[5143]={44401},[30455]={44544},[44572]={44544}, -- Brain Freeze, Hot Streak, Missile Barrage, Fingers of Frost
 [403]={53817,5},[421]={53817,5},[331]={53817,5},[8004]={53817,5},[1064]={53817,5},[51514]={53817,5}, -- Maelstrom Weapon x5
 [1464]={46916},[5308]={52437},[7384]={60503},[23922]={50227},   -- Bloodsurge, Sudden Death, Taste for Blood, Sword and Board
 [49184]={59052},[45477]={51124},[49143]={51124},               -- Freezing Fog, Killing Machine
 [53301]={56453},[3044]={56453},                                -- Lock and Load
 [2912]={48518},[5176]={48517},                                 -- Eclipse
 [2061]={33151},[585]={33151},                                  -- Surge of Light
 [6353]={63167},[29722]={71165},[686]={17941},                   -- Decimation, Molten Core, Nightfall
}
-- Spells that become usable after an event (dodge, parry, low health).
ns.REACTIVE={[7384]=true,[6572]=true,[5308]=true,[53351]=true,[24275]=true,[34428]=true,[14251]=true,[19306]=true,[1495]=true}
-- Retail cooldown-viewer glow numbering (saved values) and the shared Core index.
ns.GLOW_NAMES={"Pixel Glow","Shape Glow","Action Button Glow","Auto-Cast Shine","GCD","Modern WoW Glow","Classic WoW Glow"}
ns.GLOW_ORDER={1,3,4,2,5,6,7}
ns.GLOW_TO_SHARED={1,4,2,3,5,6,7}
function ns.SeedLists(class)
    local seed=ns.catalog[class] or {cooldowns={},utility={},buffs={}}
    local lists={cooldowns={},utility={},buffs={},tbb={},barGlows={enabled=true,list={}}}
    for _,key in ipairs({"cooldowns","utility","buffs"}) do
        for _,id in ipairs(seed[key]) do lists[key][#lists[key]+1]={kind=key=="buffs" and "aura" or "spell",id=id,unit="player",filter="HELPFUL",enabled=true} end
    end
    local _,race=UnitRace("player")
    local racial=ns.RACE_RACIALS[race or ""]
    if racial then lists.utility[#lists.utility+1]={kind="spell",id=racial[1],enabled=true}
    else for _,list in pairs(ns.RACE_RACIALS) do lists.utility[#lists.utility+1]={kind="spell",id=list[1],enabled=true} end end
    for _,slot in ipairs({13,14}) do lists.utility[#lists.utility+1]={kind="slot",id=slot,enabled=true} end
    lists.utility[#lists.utility+1]={kind="preset",id="healthstone",enabled=true}
    for i=1,math.min(3,#lists.buffs) do
        lists.tbb[i]={spellID=lists.buffs[i].id,enabled=true}
    end
    return lists
end
