local E=EllesmereUI
local F=E and E.WrathAuraFilters
if not F then return end
function E.BuildWrathAuraFilters(folder,parent,y,selectedPrefix)
    local ns=E._ModuleNS[folder]; if not ns then return 0 end
    local uf=folder=="EllesmereUIUnitFrames"
    local rf=folder=="EllesmereUIRaidFrames"
    local W=E.Widgets
    local function Settings()
        if rf then return ns.GetOptionSettings(ns.selectedWrathAuraGroup or "raid") end
        if not uf then return ns.GetSettings() end
        local unit=ns.selectedWrathAuraUnit or "player"
        if ns.UF_GetSettings then return ns.UF_GetSettings(unit) end
        local profile=ns.db and ns.db.profile
        return profile and profile[unit=="boss1" and "boss" or unit]
    end
    local function Apply() if uf then ns.UF_ReloadAllAuraContainers() else ns.Apply() end end
    local function Row(a,b) local _,h=W:DualRow(parent,y,a,b); y=y-h end
    local function Section(label) local _,h=W:SectionHeader(parent,label,y); y=y-h end
    if rf then
        Section("GROUP SELECTION")
        Row({type="dropdown",text="Select Group",values={raid="Raid",party="Party"},order={"raid","party"},getValue=function() return ns.selectedWrathAuraGroup or "raid" end,
            setValue=function(v) ns.selectedWrathAuraGroup=v; E:InvalidatePageCache(); E:RefreshPage(true) end},(ns.selectedWrathAuraGroup or "raid")=="raid" and ns.RaidLayoutDropdown() or {type="label",text="Raid and party filters are saved separately"})
    elseif uf then
        Section("FRAME SELECTION")
        Row({type="dropdown",text="Select Frame",values={player="Player",target="Target",focus="Focus",boss1="Boss Frames"},order={"player","target","focus","boss1"},
            getValue=function() return ns.selectedWrathAuraUnit or "player" end,
            setValue=function(v) ns.selectedWrathAuraUnit=v; E:InvalidatePageCache(); E:RefreshPage(true) end},{type="label",text="Filters are saved separately for each frame"})
    end
    local function List(prefix,suffix,label)
        return {type="input",text=label,inputStyle="popup",inputWidth=160,placeholder="123, 456",tooltip="Comma-separated spell IDs. Empty means no entries.",
            getValue=function() local s=Settings(); return F.Format(s and s[prefix..suffix]) end,
            setValue=function(text) local s=Settings(); local parsed=F.Parse(text)
                if not parsed then if E.PrintError then E.PrintError("Enter positive spell IDs separated by commas or spaces.") end; return end
                if s then s[prefix..suffix]=parsed; Apply() end
            end}
    end
    for _,prefix in ipairs(selectedPrefix and {selectedPrefix} or {"debuff","buff"}) do
        local pre=prefix
        Section(pre=="debuff" and "DEBUFF FILTERS" or "BUFF FILTERS")
        Row({type="dropdown",text=pre=="debuff" and "Debuff Filter" or "Buff Filter",values={all="Show All",own="Own Only",tracked="Only Tracked"},order={"all","own","tracked"},
            getValue=function() local s=Settings(); return s and F.Mode(s,pre) or "all" end,
            setValue=function(v) local s=Settings(); if s then s[pre.."FilterMode"]=v; if pre=="debuff" then s.onlyPlayerDebuffs=v=="own" else s.onlyPlayerBuffs=v=="own" end; Apply() end end},
            {type="label",text="Tracked IDs are added; excluded IDs always hide"})
        Row(List(pre,"Include","Tracked Spell IDs"),List(pre,"Exclude","Excluded Spell IDs"))
        Row({type="toggle",text="Only Timed Auras",getValue=function() local s=Settings(); return s and s[pre.."HasDuration"] or false end,
            setValue=function(v) local s=Settings(); if s then s[pre.."HasDuration"]=v; Apply() end end},
            pre=="buff" and {type="toggle",text="Only Stealable Buffs",getValue=function() local s=Settings(); return s and s.buffStealable or false end,
            setValue=function(v) local s=Settings(); if s then s.buffStealable=v; Apply() end end}
            or uf and {type="toggle",text="Hide Sated / Exhaustion",tooltip="Hides the Bloodlust and Heroism lockout debuffs.",
            getValue=function() local s=Settings(); return not s or s.debuffHideExhaustion~=false end,
            setValue=function(v) local s=Settings(); if s then s.debuffHideExhaustion=v; Apply() end end}
            or {type="label",text="Own includes your pet and vehicle"})
    end
    local _,h=W:WideButton(parent,"Reset Selected Aura Filters",y,function()
        local s=Settings(); if not s then return end
        for _,prefix in ipairs(selectedPrefix and {selectedPrefix} or {"buff","debuff"}) do
            s[prefix.."Include"]={}; s[prefix.."Exclude"]={}; s[prefix.."IncludeMine"]={}; s[prefix.."HasDuration"]=false; s[prefix.."FilterMode"]="all"
            if prefix=="buff" then s.onlyPlayerBuffs=false; s.buffStealable=false else s.onlyPlayerDebuffs=false end
        end
        Apply(); E:RefreshPage(true)
    end); y=y-h
    return math.abs(y)
end
