-- Boss debuffs shown as the centre icon (ElvUI RaidDebuffs). Wrath spell IDs;
-- higher priority wins when a player carries several.
local _,ns=...
if not ns.addon then return end
local list={
    -- Icecrown Citadel
    [69065]=5,                                              -- Impaled (Marrowgar)
    [71289]=6,[71204]=4,[71001]=3,                          -- Dominate Mind, Touch of Insignificance, Death and Decay (Deathwhisper)
    [72293]=6,[72410]=4,[72441]=3,[72385]=3,                -- Mark of the Fallen Champion, Rune of Blood, Boiling Blood, Blood Nova (Saurfang)
    [69279]=6,[69240]=4,[71218]=4,[72219]=3,                -- Gas Spore, Vile Gas, Gastric Bloat (Festergut)
    [69674]=6,[71224]=6,                                    -- Mutated Infection (Rotface)
    [72856]=6,[70911]=6,[70215]=5,[70447]=5,[72451]=3,      -- Unbound Plague, Gaseous Bloat, Volatile Ooze Adhesive, Mutated Plague (Putricide)
    [72999]=3,                                              -- Shadow Prison (Blood Princes)
    [71340]=6,[71861]=5,[71265]=5,[70877]=6,[70923]=7,      -- Pact of the Darkfallen, Swarming Shadows, Frenzied Bloodthirst, Uncontrollable Frenzy (Lana'thel)
    [70867]=2,[71473]=2,                                    -- Essence of the Blood Queen
    [70633]=4,[70751]=3,[70744]=3,                          -- Gut Spray, Corrosion, Acid Burst (Valithria)
    [70126]=7,[69762]=5,[69766]=3,[70106]=3,[70128]=3,[70157]=8, -- Frost Beacon, Unchained Magic, Instability, Chilled to the Bone, Mystic Buffet, Ice Tomb (Sindragosa)
    [70337]=7,[73912]=7,[70541]=3,[72762]=6,[68980]=8,[69409]=6, -- Necrotic Plague, Infest, Defile, Harvest Soul, Soul Reaper (Lich King)
    -- Ruby Sanctum
    [74562]=6,[74792]=6,[74502]=4,[74456]=5,                -- Fiery Combustion, Soul Consumption, Enervating Brand, Conflagration
    -- Trial of the Crusader
    [66331]=4,[66406]=5,[66823]=4,[66869]=4,[66689]=5,      -- Impale, Snobolled!, Paralytic Toxin, Burning Bile, Arctic Breath (Beasts)
    [66237]=6,[66197]=5,[66334]=4,                          -- Incinerate Flesh, Legion Flame, Mistress' Kiss (Jaraxxus)
    [65950]=4,[66001]=4,                                    -- Touch of Light, Touch of Darkness (Twin Val'kyr)
    [66013]=5,[67574]=7,                                    -- Penetrating Cold, Pursued by Anub'arak
    -- Ulduar
    [62717]=5,[63024]=6,[63018]=6,[64290]=5,[62469]=3,      -- Slag Pot, Gravity Bomb, Searing Light, Stone Grip, Freeze
    [63666]=4,[63276]=6,[63830]=5,[64125]=6,[63802]=5,      -- Napalm Shell, Mark of the Faceless, Malady of the Mind, Squeeze, Brain Link
    -- Naxxramas
    [28169]=6,[28522]=6,[27808]=5,[27819]=6,[25646]=3,[55593]=4, -- Mutating Injection, Icebolt, Frost Blast, Detonate Mana, Mortal Wound, Necrotic Aura
}
ns.RAID_DEBUFFS=list
