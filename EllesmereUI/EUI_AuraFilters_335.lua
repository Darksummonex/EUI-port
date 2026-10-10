local E=EllesmereUI
if not E then return end
local F={}; E.WrathAuraFilters=F
function F.Has(list,id) return list and (list[id] or list[tostring(id)]) end
-- Common Wrath raid debuffs, matched by name so every rank and same-named
-- NPC version counts. Armor, spell damage/crit/hit taken, crit and physical
-- damage taken, bleed, attack power, attack and cast speed, healing taken,
-- Judgements and Hunter's Mark.
F.RAID_DEBUFFS={
    58567,8647,55753,770,16857,702,
    1490,60433,51735,22959,12579,17800,33198,
    54499,30708,30070,58683,48564,48566,46857,
    1160,99,26017,6343,55095,58181,68055,
    12294,13218,19434,56112,1714,31589,5760,58611,
    20185,20186,1130,
}
local raidDebuffs
function F.IsRaidDebuff(id,name)
    if not raidDebuffs then
        raidDebuffs={}
        for _,sid in ipairs(F.RAID_DEBUFFS) do
            raidDebuffs[sid]=true
            local spell=GetSpellInfo and GetSpellInfo(sid)
            if spell then raidDebuffs[spell]=true end
        end
    end
    return (id and raidDebuffs[id]) or (name and raidDebuffs[name]) or false
end
function F.Mode(s,prefix)
    local mode=s[prefix.."FilterMode"]
    if mode=="all" or mode=="own" or mode=="tracked" then return mode end
    if prefix=="debuff" and (mode=="raid" or mode=="raidOwn") then return mode end
    local own=prefix=="debuff" and s.onlyPlayerDebuffs or prefix=="buff" and s.onlyPlayerBuffs
    return own and "own" or "all"
end
function F.Allow(s,prefix,id,mine,duration,stealable,name)
    if F.Has(s[prefix.."Exclude"],id) then return false end
    local tracked=F.Has(s[prefix.."Include"],id)
    if tracked and F.Has(s[prefix.."IncludeMine"],id) and not mine then tracked=false end
    local mode=F.Mode(s,prefix)
    local include=mode=="all" or (mode=="own" or mode=="raidOwn") and mine or tracked
        or (mode=="raid" or mode=="raidOwn") and F.IsRaidDebuff(id,name)
    if s[prefix.."HasDuration"] and (not duration or duration<=0) then return false end
    if prefix=="buff" and s.buffStealable and not stealable then return false end
    return include and true or false
end
function F.Format(list)
    local ids,seen={},{}
    for key,value in pairs(list or {}) do local id=tonumber(key); if value and id and not seen[id] then ids[#ids+1]=id; seen[id]=true end end
    table.sort(ids); for i,id in ipairs(ids) do ids[i]=tostring(id) end
    return table.concat(ids,", ")
end
function F.Parse(text)
    local list={}
    for token in tostring(text or ""):gmatch("[^,%s;]+") do
        local id=tonumber(token); if not id or id<=0 or id~=math.floor(id) then return nil end
        list[id]=true
    end
    return list
end
