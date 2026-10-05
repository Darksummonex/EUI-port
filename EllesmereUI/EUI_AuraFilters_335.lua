local E=EllesmereUI
if not E then return end
local F={}; E.WrathAuraFilters=F
function F.Has(list,id) return list and (list[id] or list[tostring(id)]) end
function F.Mode(s,prefix)
    local mode=s[prefix.."FilterMode"]
    if mode=="all" or mode=="own" or mode=="tracked" then return mode end
    local own=prefix=="debuff" and s.onlyPlayerDebuffs or prefix=="buff" and s.onlyPlayerBuffs
    return own and "own" or "all"
end
function F.Allow(s,prefix,id,mine,duration,stealable)
    if F.Has(s[prefix.."Exclude"],id) then return false end
    local tracked=F.Has(s[prefix.."Include"],id)
    if tracked and F.Has(s[prefix.."IncludeMine"],id) and not mine then tracked=false end
    local mode=F.Mode(s,prefix)
    local include=mode=="all" or mode=="own" and mine or tracked
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
