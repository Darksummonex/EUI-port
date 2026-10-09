-- Wrath omits the shield caster from damage events. Attribute actual absorbed
-- amounts only when the observed active shields identify a single friendly owner.
local _,ns=...
local durations, restrictions={},{}
local function Shields(seconds,ids,mask)
    for _,id in ipairs(ids) do durations[id]=seconds; restrictions[id]=mask end
end
Shields(30,{17,592,600,3747,6065,6066,10898,10899,10900,10901,25217,25218,48065,48066}) -- Power Word: Shield
Shields(12,{47509,47511,47515,47753,54704}) -- Divine Aegis
Shields(6,{58597}) -- Sacred Shield proc (not the persistent 53601 buff)
Shields(60,{11426,13031,13032,13033,27134,33405,43038,43039}) -- Ice Barrier
Shields(60,{1463,8494,8495,10191,10192,10193,27131,43019,43020}) -- Mana Shield
Shields(30,{543,8457,8458,10223,10225,27128,43010},4) -- Fire Ward
Shields(30,{6143,8461,8462,10177,28609,32796,43012},16) -- Frost Ward
Shields(30,{6229,11739,11740,28610,47890,47891},32) -- Shadow Ward
Shields(30,{7812,19438,19440,19441,19442,19443,27273,47985,47986}) -- Sacrifice
Shields(5,{48707},126) -- Anti-Magic Shell
Shields(10,{62606},1) -- Savage Defense
local shields={}
function ns.TrackShield(event,sg,sn,sf,dg,dn,df,id,name,school,auraType,expires)
    if not dg or not durations[id] or auraType~="BUFF" or not ns.Friendly(dg,df) then return end
    local list=shields[dg]
    if not list then list={}; shields[dg]=list end
    local key=tostring(id)..":"..tostring(sg)
    if event=="SPELL_AURA_REMOVED" or event=="SPELL_AURA_BROKEN" or event=="SPELL_AURA_BROKEN_SPELL" then
        list[key]=nil
        -- Removal events can omit the original caster.
        if not sg or event=="SPELL_AURA_BROKEN" or event=="SPELL_AURA_BROKEN_SPELL" then
            for k,a in pairs(list) do if a.id==id then list[k]=nil end end
        end
    else
        if sg then list[tostring(id)..":nil"]=nil end
        list[key]={id=id,spell=name,school=school,guid=sg,name=sn,flags=sf,
            expires=expires and expires>0 and expires or GetTime()+durations[id],mask=restrictions[id]}
    end
end
function ns.ClearShields(guid)
    if guid then shields[guid]=nil else shields={} end
end
function ns.CreditAbsorb(amount,dg,dn,school)
    amount=tonumber(amount) or 0
    if amount<=0 or not ns.current then return end
    local list=shields[dg]; if not list then return end
    local selected,owner,ownerName,ownerFlags,multiple
    for key,a in pairs(list) do
        if a.expires<=GetTime() then list[key]=nil
        elseif not a.mask or not school or bit.band(a.mask,school)~=0 then
            if not a.guid or not ns.Friendly(a.guid,a.flags) then return end
            local guid,name,flags=ns.Owner(a.guid,a.name,a.flags)
            if owner and owner~=guid then return end
            if selected and selected.id~=a.id then multiple=true end
            selected,owner,ownerName,ownerFlags=a,guid,name,flags
        end
    end
    if not selected then return end
    local id,name,spellSchool=selected.id,selected.spell,selected.school
    -- Multiple shields from the same caster: owner is known, spell split is not.
    if multiple then id,name,spellSchool=-3,"Absorbs (combined shields)",nil end
    ns.Add("shielding",amount,owner,ownerName,ownerFlags,id,name,dg,dn,false,spellSchool)
    ns.Add("healing",amount,owner,ownerName,ownerFlags,id,name,dg,dn,false,spellSchool)
end
ns.metrics[#ns.metrics+1]={key="shielding",label="Absorbs Done"}
ns.metricMap.shielding=ns.metrics[#ns.metrics]
