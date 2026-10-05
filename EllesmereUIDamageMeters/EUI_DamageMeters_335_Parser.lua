-- Stock 3.3.5 CLEU has eight common fields (no hideCaster or raid flags).
local ADDON,ns=...
local damageEvents={SPELL_DAMAGE=true,SPELL_PERIODIC_DAMAGE=true,RANGE_DAMAGE=true,DAMAGE_SHIELD=true,DAMAGE_SPLIT=true}
local healEvents={SPELL_HEAL=true,SPELL_PERIODIC_HEAL=true}
local missEvents={SPELL_MISSED=true,SPELL_PERIODIC_MISSED=true,RANGE_MISSED=true,DAMAGE_SHIELD_MISSED=true}
local countEvents={SPELL_INTERRUPT="interrupts",SPELL_DISPEL="dispels",SPELL_STOLEN="dispels",
    SPELL_CAST_SUCCESS="casts",SPELL_RESURRECT="resurrections",SPELL_AURA_BROKEN_SPELL="ccbreaks"}
local powerKeys={[0]="mana",[1]="rage",[2]="focus",[3]="energy",[6]="runic"}
for key,label in pairs({mana="Mana Gained",rage="Rage Gained",focus="Focus Gained",energy="Energy Gained",runic="Runic Power Gained"}) do
    local m={key=key,label=label}; ns.metrics[#ns.metrics+1]=m; ns.metricMap[key]=m
end
ns.metricMap.resources.label="Resource Gain Events"
local function BrokenAura(recipient,id)
    -- A break reports the breaker; the applied aura may have another caster.
    for key,a in pairs(ns.activeAuras or {}) do if a.recipient==recipient and a.id==id then
        ns.Add(a.metric,math.max(0,GetTime()-a.at),a.guid,a.name,a.flags,a.id,a.spell,a.targetGUID,a.targetName)
        ns.activeAuras[key]=nil
    end end
end
local function Log(guid,name,flags,kind,amount,id,spellName,source)
    if not ns.Friendly(guid,flags) then return end
    local a=ns.Actor(ns.current,guid,name,flags)
    local log={at=GetTime()-ns.started,kind=kind,amount=amount,id=id,name=spellName or "Melee",source=source or "Environment"}
    a.logs[#a.logs+1]=log
    while #a.logs>40 or (#a.logs>1 and a.logs[1].at<log.at-20) do table.remove(a.logs,1) end
end
function ns.Aura(event,sg,sn,sf,dg,dn,df,id,name,auraType)
    if not id or not ns.current then return end
    if event=="SPELL_AURA_BROKEN" or event=="SPELL_AURA_BROKEN_SPELL" then BrokenAura(dg,id); return end
    local debuff=auraType=="DEBUFF"
    local ownerGUID,ownerName,ownerFlags,targetGUID,targetName
    if debuff then
        if not ns.Friendly(sg,sf) then return end
        ownerGUID,ownerName,ownerFlags=ns.Owner(sg,sn,sf); targetGUID,targetName=dg,dn
    else
        if not ns.Friendly(dg,df) then return end
        ownerGUID,ownerName,ownerFlags=dg,dn,df; targetGUID,targetName=sg,sn
    end
    local key=(auraType or "BUFF")..":"..tostring(id)..":"..tostring(sg)..":"..tostring(dg)
    local previous=ns.activeAuras[key]
    if not previous and not debuff then
        -- A pre-combat UnitAura can omit its caster. Reconcile that one
        -- recipient/spell observation when CLEU later supplies the source.
        local unknown="BUFF:"..tostring(id)..":nil:"..tostring(dg)
        previous=ns.activeAuras[unknown]
        if previous then ns.activeAuras[unknown]=nil; ns.activeAuras[key]=previous end
    end
    if event=="SPELL_AURA_REMOVED" or event=="SPELL_AURA_BROKEN" or event=="SPELL_AURA_BROKEN_SPELL" then
        if previous then
            local elapsed=math.max(0,GetTime()-previous.at)
            ns.Add(previous.metric,elapsed,previous.guid,previous.name,previous.flags,previous.id,previous.spell,previous.targetGUID,previous.targetName)
            ns.activeAuras[key]=nil
        end
    elseif not previous then
        ns.activeAuras[key]={at=GetTime(),metric=debuff and "debuffUptime" or "buffUptime",id=id,spell=name,
            guid=ownerGUID,name=ownerName,flags=ownerFlags,targetGUID=targetGUID,targetName=targetName,recipient=dg}
    end
end
function ns.FlushAuras(now,close)
    for key,a in pairs(ns.activeAuras or {}) do
        local elapsed=math.max(0,now-a.at)
        ns.Add(a.metric,elapsed,a.guid,a.name,a.flags,a.id,a.spell,a.targetGUID,a.targetName)
        a.at=now; if close then ns.activeAuras[key]=nil end
    end
end
function ns.SeedAuras()
    for _,unit in ipairs(ns.units or {}) do
        for i=1,40 do
            local name,rank,icon,count,kind,duration,expires,caster,stealable,consolidate,id=UnitAura(unit,i,"HELPFUL")
            if not name then break end
            ns.Aura("SPELL_AURA_APPLIED",caster and UnitGUID(caster),caster and UnitName(caster),nil,
                UnitGUID(unit),UnitName(unit),nil,id,name,"BUFF")
        end
    end
end
function ns.Parse(timestamp,event,sg,sn,sf,dg,dn,df,...)
    if not ns.Profile() or not ns.Profile().enabled then return end
    if event=="SPELL_SUMMON" or event=="SPELL_CREATE" then
        if dg and ns.Friendly(sg,sf) then
            local guid,name,flags=ns.Owner(sg,sn,sf)
            ns.pets[dg]={guid=guid,name=name,flags=flags}
            ns.roster[dg]={guid=dg,name=dn,class=ns.roster[guid] and ns.roster[guid].class,pet=true}
        end
        return
    end
    local sourceFriendly,destFriendly=ns.Friendly(sg,sf),ns.Friendly(dg,df)
    if not sourceFriendly and not destFriendly then return end
    local isDamage=damageEvents[event] or event=="SWING_DAMAGE" or event=="ENVIRONMENTAL_DAMAGE"
    if ns.current and ns.endedAt and not isDamage and not ns.GroupInCombat() then return end
    if not ns.current then
        if isDamage or ns.GroupInCombat() then ns.Start(not destFriendly and dn or not sourceFriendly and sn or nil) else return end
    end
    if not ns.current then return end
    if isDamage or ns.GroupInCombat() then ns.lastActivity=GetTime(); ns.endedAt=nil end
    if ns.current.label=="Combat" and isDamage then ns.current.label=not destFriendly and dn or not sourceFriendly and sn or "Combat" end
    if isDamage then
        local id,name,school,amount,overkill,resisted,blocked,absorbed,critical
        if event=="SWING_DAMAGE" then
            amount,overkill,school,resisted,blocked,absorbed,critical=...; id,name=0,"Melee"
        elseif event=="ENVIRONMENTAL_DAMAGE" then
            local kind; kind,amount,overkill,school,resisted,blocked,absorbed,critical=...; id,name=-1,kind or "Environment"
        else
            local spellSchool; id,name,spellSchool,amount,overkill,school,resisted,blocked,absorbed,critical=...
        end
        if sourceFriendly then
            ns.Add("damage",amount,sg,sn,sf,id,name,dg,dn,critical,school)
            if destFriendly then ns.Add("friendlyFire",amount,sg,sn,sf,id,name,dg,dn,critical,school)
            else ns.Add("enemyTaken",amount,dg,dn,df,id,name,sg,sn,critical,school) end
        end
        if destFriendly then
            ns.Add("taken",amount,dg,dn,df,id,name,sg,sn,critical,school)
            ns.Add("absorbed",absorbed,dg,dn,df,id,name,sg,sn,false,school)
            ns.Add("blocked",blocked,dg,dn,df,id,name,sg,sn,false,school)
            ns.Add("resisted",resisted,dg,dn,df,id,name,sg,sn,false,school)
            Log(dg,dn,df,"damage",amount,id,name,sn)
        end
    elseif healEvents[event] then
        local id,name,school,amount,overheal,absorbed,critical=...
        if sourceFriendly then
            ns.Add("healing",math.max(0,(tonumber(amount) or 0)-(tonumber(overheal) or 0)),sg,sn,sf,id,name,dg,dn,critical,school)
            ns.Add("overheal",overheal,sg,sn,sf,id,name,dg,dn,critical,school)
        end
        local effective=math.max(0,(tonumber(amount) or 0)-(tonumber(overheal) or 0))
        if destFriendly then ns.Add("healingReceived",effective,dg,dn,df,id,name,sg,sn,critical,school) end
        Log(dg,dn,df,"heal",effective,id,name,sn)
    elseif missEvents[event] or event=="SWING_MISSED" then
        local id,name,school,miss,amount
        if event=="SWING_MISSED" then miss,amount=...; id,name=0,"Melee"
        else id,name,school,miss,amount=... end
        if miss=="ABSORB" and destFriendly then ns.Add("absorbed",amount,dg,dn,df,id,name,sg,sn) end
        if sourceFriendly then ns.Add("misses",1,sg,sn,sf,id,name,dg,dn) end
        if destFriendly then ns.Add("avoided",1,dg,dn,df,id,name,sg,sn) end
    elseif event=="SPELL_ENERGIZE" or event=="SPELL_PERIODIC_ENERGIZE" then
        local id,name,school,amount,power=...
        if destFriendly then
            ns.Add("resources",1,dg,dn,df,id,name,sg,sn)
            if powerKeys[power] then ns.Add(powerKeys[power],amount,dg,dn,df,id,name,sg,sn) end
        end
    elseif event=="UNIT_DIED" or event=="UNIT_DESTROYED" then
        -- Pet deaths stay with the pet, rather than counting as owner deaths.
        if destFriendly and not ns.pets[dg] then
            ns.Add("deaths",1,dg,dn,df,-2,"Death",dg,dn)
            local a=ns.Actor(ns.current,dg,dn,df)
            ns.current.deaths[#ns.current.deaths+1]={guid=dg,name=dn,at=GetTime()-ns.started,logs=ns.Copy(a.logs)}
            while #ns.current.deaths>100 do table.remove(ns.current.deaths,1) end
            a.logs={}
        end
        for key,a in pairs(ns.activeAuras) do if a.recipient==dg then
            ns.Add(a.metric,math.max(0,GetTime()-a.at),a.guid,a.name,a.flags,a.id,a.spell,a.targetGUID,a.targetName); ns.activeAuras[key]=nil
        end end
    elseif event=="SPELL_AURA_APPLIED" or event=="SPELL_AURA_REFRESH" or event=="SPELL_AURA_REMOVED" or event=="SPELL_AURA_BROKEN" then
        local id,name,school,auraType=...; ns.Aura(event,sg,sn,sf,dg,dn,df,id,name,auraType)
    elseif countEvents[event] then
        local id,name,school,extraID,extraName,extraSchool,auraType=...
        if sourceFriendly then ns.Add(countEvents[event],1,sg,sn,sf,id,name,dg,dn,false,school) end
        if event=="SPELL_AURA_BROKEN_SPELL" then BrokenAura(dg,id) end
    end
end
