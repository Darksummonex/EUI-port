-- Shared Wrath indicator geometry for live unit frames and options previews.
local E=EllesmereUI
local A={}
E.WrathAuraIndicators=A
local white="Interface\\Buttons\\WHITE8X8"
local spellNames={}
local function SpellName(id)
    if not id then return end
    if not spellNames[id] then spellNames[id]=GetSpellInfo(id) end
    return spellNames[id]
end
-- Native Wrath spell IDs only. Rank variants are matched by the client's
-- localized spell name, without importing saved filters from another addon.
A.catalog={healing={17,139,41635,774,8936,33763,48438,974,61295,53563,53601},
    defensive={871,12975,2565,22812,61336,22842,498,642,66233,48707,48792,55233,49039,31224,5277,45438,47585,19263,30823,6229},
    external={33206,47788,6940,1022,10060,29166}}
function A.HasSpell(list,id)
    if E.WrathAuraFilters.Has(list,id) then return true end
    local name=SpellName(id); if not name then return false end
    for key,enabled in pairs(list or {}) do if enabled and SpellName(tonumber(key))==name then return true end end
    return false
end
function A.Preset(category)
    local labels={healing="Healer Buffs",defensive="Personal Defensives",external="External Cooldowns"}
    local d={name=labels[category] or "Manual Buffs",category=category,enabled=true,filter="tracked",spells={},spellOrder={},
        position=category=="defensive" and "CENTER" or category=="external" and "TOPRIGHT" or "BOTTOMLEFT",
        growth=category=="external" and "LEFT" or "RIGHT",maxIcons=category=="healing" and 3 or 2,
        ownOnly=category=="healing",showIn="both",opacity=1,spacing=1,border=1,showStacks=true,durationText=true,durationSwipe=true}
    for _,id in ipairs(A.catalog[category] or {}) do d.spells[id]=true; d.spellOrder[#d.spellOrder+1]=id end
    return d
end
local function Clamp(v,lo,hi,default) return math.max(lo,math.min(hi,tonumber(v) or default or lo)) end
function A.List(c,prefix,create)
    local key=prefix.."Indicators"
    if not c[key] and create then
        if prefix=="buff" then c[key]={A.Preset("healing"),A.Preset("defensive"),A.Preset("external")}
        else c[key]={{name="Debuff Icons",enabled=true,
            position=prefix=="buff" and "BOTTOMLEFT" or "BOTTOMRIGHT",growth=prefix=="buff" and "RIGHT" or "LEFT",
            showIn="both",opacity=1,spacing=1,border=1,showStacks=true,durationText=true,durationSwipe=true}} end
    end
    local list=c[key]
    if prefix=="buff" and list and #list==1 and list[1].name=="Buff Icons" and not list[1].filter and not list[1].spells then
        -- Convert only the old automatically-created broad default. Keep its
        -- visual edits; named/manual/custom-filter indicators stay untouched.
        local old=list[1]; local d=A.Preset("healing")
        for k,v in pairs(old) do if k~="name" then d[k]=v end end
        list[1]=d
        local used=A.Limit and A.Limit(c,prefix,d) or d.maxIcons
        if used<=4 then list[2]=A.Preset("defensive"); list[3]=A.Preset("external") end
    end
    return c[key] or {}
end
function A.Limit(c,prefix,d) return math.floor(Clamp(d.maxIcons,0,8,c[prefix=="buff" and "maxBuffs" or "maxDebuffs"] or 3)) end
function A.Geometry(c,prefix,d,index,w,h,raid)
    local spacing=Clamp(d.spacing,0,12,1)
    local size=Clamp(d.size,6,64,c[prefix.."Size"] or c.auraSize or 18)
    if raid then
        local power=c.showPower and math.min(h/3,math.max(2,tonumber(c.powerHeight) or 4)) or 0
        local count=math.max(1,math.min(8,c.maxBuffs or 3)+math.min(8,c.maxDebuffs or 3))
        size=math.max(6,math.min(size,(w-6)/count-spacing,h-power-18))
    end
    local point=d.position or "BOTTOMLEFT"
    local growth=d.growth or "RIGHT"
    local x=point:find("RIGHT") and -2 or point:find("LEFT") and 2 or 0
    local y=point:find("TOP") and -2 or point:find("BOTTOM") and 2 or 0
    local offset=(index-1)*(size+spacing)
    x=x+(growth=="LEFT" and -offset or growth=="RIGHT" and offset or 0)
    y=y+(growth=="DOWN" and -offset or growth=="UP" and offset or 0)
    return size,point,x+(tonumber(d.x) or 0),y+(tonumber(d.y) or 0)
end
local function Font(fs,size,module)
    local path=E.GetFontPath and E.GetFontPath(module) or "Fonts\\FRIZQT__.TTF"
    if not fs:SetFont(path,Clamp(size,8,24,10),"OUTLINE") then fs:SetFont("Fonts\\FRIZQT__.TTF",10,"OUTLINE") end
end
function A.NewIcon(parent)
    local a=CreateFrame("Button",nil,parent); a:Hide()
    a.icon=a:CreateTexture(nil,"ARTWORK"); a.icon:SetAllPoints(a); a.icon:SetTexCoord(.08,.92,.08,.92)
    a.cooldown=CreateFrame("Cooldown",nil,a,"CooldownFrameTemplate"); a.cooldown:SetAllPoints(a)
    local textHost=CreateFrame("Frame",nil,a); textHost:SetFrameLevel(a.cooldown:GetFrameLevel()+2); textHost:SetAllPoints(a); textHost:EnableMouse(false)
    a.count=textHost:CreateFontString(nil,"OVERLAY"); Font(a.count,10); a.count:SetPoint("BOTTOMRIGHT",a,"BOTTOMRIGHT",-1,1)
    a.time=textHost:CreateFontString(nil,"OVERLAY"); Font(a.time,9); a.time:SetPoint("CENTER",a,"CENTER",0,0)
    a:SetScript("OnEnter",function(self)
        if not self.unit and not self.spellID then return end
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        if self.unit then GameTooltip:SetUnitAura(self.unit,self.index,self.filter)
        elseif GameTooltip.SetHyperlink and GetSpellInfo(self.spellID) then GameTooltip:SetHyperlink("spell:"..self.spellID) else return end
        GameTooltip:Show()
    end)
    a:SetScript("OnLeave",function() GameTooltip:Hide() end)
    a:SetScript("OnUpdate",function(self,dt)
        if self.preview or not self.expiry or self.expiry<=0 then return end
        self.elapsed=(self.elapsed or 0)+dt; if self.elapsed<.2 then return end; self.elapsed=0
        local remaining=self.expiry-GetTime()
        if remaining<=0 then self:Hide()
        else self.time:SetText(self.indicator.durationText==false and "" or remaining>60 and math.ceil(remaining/60).."m" or tostring(math.ceil(remaining))) end
    end)
    return a
end
function A.Place(a,anchor,c,prefix,d,index,w,h,raid,module)
    local size,point,x,y=A.Geometry(c,prefix,d,index,w,h,raid)
    a:SetWidth(size); a:SetHeight(size); a:ClearAllPoints(); a:SetPoint(point,anchor,point,x,y)
    a:SetAlpha(Clamp(d.opacity,0,1,1)); a.indicator=d
    a:SetBackdrop({edgeFile=white,edgeSize=math.max(1,Clamp(d.border,0,3,1))})
    a:SetBackdropBorderColor(0,0,0,d.border==0 and 0 or 1)
    Font(a.count,d.stackSize or c.auraStackTextSize or c.buffStackTextSize, module)
    Font(a.time,d.durationSize or c.auraDurationTextSize or c.buffCooldownTextSize,module)
end
function A.Paint(a,d,r,preview)
    a.preview=preview; a.unit=r.unit; a.index=r.index; a.filter=r.filter; a.spellID=r.id; a.expiry=r.expiry or 0
    a.icon:SetTexture(r.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    if d.hideIcons then a.icon:Hide() else a.icon:Show() end
    a.count:SetText(d.showStacks~=false and (r.stacks or 0)>1 and tostring(r.stacks) or "")
    local remaining=a.expiry>0 and math.max(0,a.expiry-GetTime()) or 0
    a.time:SetText(d.durationText==false and "" or preview and "12" or remaining>60 and math.ceil(remaining/60).."m" or remaining>0 and tostring(math.ceil(remaining)) or "")
    if d.durationSwipe~=false and (r.duration or 0)>0 then a.cooldown:SetCooldown(a.expiry-r.duration,r.duration); a.cooldown:Show() else a.cooldown:Hide() end
    a:Show()
end
function A.Allows(c,prefix,id,mine,duration,stealable)
    local F=E.WrathAuraFilters
    if A.HasSpell(c[prefix.."Exclude"],id) or c[prefix.."HasDuration"] and (not duration or duration<=0) or prefix=="buff" and c.buffStealable and not stealable then return false end
    if F.Allow(c,prefix,id,mine,duration,stealable) then return true end
    -- Explicitly assigned spells may come from somebody else (externals).
    -- Own Only on an individual indicator is enforced again by Select.
    for _,d in ipairs(A.List(c,prefix)) do
        if d.enabled~=false and d.filter=="tracked" and A.HasSpell(d.spells,id) and (not d.ownOnly or mine) then return true end
    end
    return false
end
function A.Records(unit,c,prefix)
    local records={}; if not UnitExists(unit) then return records end
    local filter=prefix=="buff" and "HELPFUL" or "HARMFUL"
    for index=1,40 do
        local name,_,icon,stacks,dtype,duration,expiry,caster,stealable,_,id=UnitAura(unit,index,filter)
        if not name then break end
        local mine=caster and (UnitIsUnit(caster,"player") or UnitIsUnit(caster,"pet") or UnitIsUnit(caster,"vehicle"))
        if A.Allows(c,prefix,id,mine,duration,stealable) then
            records[#records+1]={unit=unit,index=index,filter=filter,id=id,icon=icon,stacks=stacks,dtype=dtype,duration=duration or 0,expiry=expiry or 0,mine=mine}
        end
    end
    return records
end
function A.Matches(d,kind)
    return d.enabled~=false and (not d.showIn or d.showIn=="both" or d.showIn==kind)
end
function A.Select(records,d)
    local out={}
    for _,r in ipairs(records) do
        local accepts=d.filter~="tracked" or A.HasSpell(d.spells,r.id)
        if d.filter=="own" or d.ownOnly then accepts=accepts and r.mine end
        if accepts then out[#out+1]=r end
    end
    if d.customOrder then
        local order={}; for i,id in ipairs(d.spellOrder or {}) do order[id]=i end
        table.sort(out,function(a,b)
            local ar,br=order[a.id] or 999,order[b.id] or 999
            return ar~=br and ar<br or ar==br and a.index<b.index
        end)
    end
    return out
end
function A.Render(pool,anchor,c,prefix,unit,kind,w,h)
    for _,a in ipairs(pool) do a:Hide(); a.unit=nil end
    if prefix=="buff" and c.showBuffs==false then return end
    local records=A.Records(unit,c,prefix); local allocated=0
    for _,d in ipairs(A.List(c,prefix,true)) do
        local limit=A.Limit(c,prefix,d)
        if A.Matches(d,kind) then
            for i,r in ipairs(A.Select(records,d)) do
                if i>limit then break end
                local a=pool[allocated+i]; if not a then break end
                A.Place(a,anchor,c,prefix,d,i,w,h,false,"unitFrames"); A.Paint(a,d,r)
            end
        end
        allocated=allocated+limit; if allocated>=#pool then break end
    end
end
function A.SpellIDs(d)
    local ids,seen={},{}
    for _,id in ipairs(d.spellOrder or {}) do if E.WrathAuraFilters.Has(d.spells,id) and not seen[id] then ids[#ids+1]=id; seen[id]=true end end
    local rest={}; for id,enabled in pairs(d.spells or {}) do id=tonumber(id); if enabled and id and not seen[id] then rest[#rest+1]=id end end
    table.sort(rest); for _,id in ipairs(rest) do ids[#ids+1]=id end
    return ids
end
