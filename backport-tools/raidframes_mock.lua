-- Wrath header/secure action contracts, independent of the addon's layout.
-- Attribute names and startingIndex allocation follow native header comments
-- preserved in the installed Cell RaidFrames/Groups/RaidFrame.lua.
local m=getmetatable(UIParent).__index
local create=CreateFrame
local set=m.SetAttribute; local show=m.Show; local hide=m.Hide
raidCount,partyCount=0,0; units={}; headers={}; drivers={}; nativeSecure=false
WRATH_ANCHORS={TOP=true,BOTTOM=true,LEFT=true,RIGHT=true,TOPLEFT=true,TOPRIGHT=true,BOTTOMLEFT=true,BOTTOMRIGHT=true}
instanceType,instanceCapacity="none",0
function GetInstanceInfo() return "Test instance",instanceType,1,"Normal",instanceCapacity end
function CopyTable(source) local result={}; for key,value in pairs(source) do result[key]=type(value)=="table" and CopyTable(value) or value end; return result end
function m:GetChildren() local children={}; for _,f in ipairs(self.children) do if f.kind~='Texture' and f.kind~='FontString' then children[#children+1]=f end end; return unpack(children) end
function m:HookScript(event,fn) local old=self.hooks[event]; self.hooks[event]=function(...) if old then old(...) end; fn(...) end end
function m:IsVisible() if not self.shown then return false end; local parent=self:GetParent(); return not parent or parent:IsVisible() end
function m:EnableMouse(v) self.mouse=v end
function m:IsMouseEnabled() return self.mouse or false end
function m:SetTextColor(...) self.textColor={...} end
function m:SetVertexColor(...) self.vertexColor={...} end
function m:RegisterForClicks(...) self.clicks={...} end
function m:SetStatusBarTexture() self:GetStatusBarTexture() end
function GetNumRaidMembers() return raidCount end
function GetNumPartyMembers() return partyCount end
function UnitExists(unit) return units[unit]~=nil end
function UnitGUID(unit) local u=units[unit]; return u and u.guid end
function UnitName(unit) local u=units[unit]; return u and u.name end
function UnitClass(unit) local u=units[unit]; return u and u.class,u and u.class end
function UnitHealth(unit) return units[unit] and units[unit].health or 0 end
function UnitHealthMax(unit) return units[unit] and units[unit].maxHealth or 0 end
function UnitPowerType(unit) return units[unit] and units[unit].powerType or 0,units[unit] and units[unit].powerToken or 'MANA' end
function UnitPower(unit) return units[unit] and units[unit].power or 0 end
function UnitPowerMax(unit) return units[unit] and units[unit].maxPower or 0 end
function UnitIsConnected(unit) return units[unit] and units[unit].connected~=false end
function UnitIsDead(unit) return units[unit] and units[unit].dead or false end
function UnitIsGhost(unit) return units[unit] and units[unit].ghost or false end
function UnitIsAFK(unit) return units[unit] and units[unit].afk or false end
function UnitIsPlayer(unit) return units[unit] and not units[unit].pet end
function UnitIsUnit(a,b) return a==b or units[a] and units[b] and units[a].guid==units[b].guid end
function UnitIsPartyLeader(unit) return units[unit] and units[unit].rank==2 end
function UnitInRaid(unit) return unit and unit:find('raid')==1 end
function UnitInParty(unit) return unit and unit:find('party')==1 end
function GetRaidRosterInfo(i) local u=units['raid'..i]; if u then return u.name,u.rank or 0,u.group or 1,80,u.class,u.class,'zone',u.connected~=false,u.dead,u.mainRole end end
function UnitGroupRolesAssigned(unit) local role=units[unit] and units[unit].role; return role=='TANK',role=='HEALER',role=='DAMAGER' end
function UnitThreatSituation(unit) return units[unit] and units[unit].threat end
function UnitInRange(unit) return units[unit] and units[unit].range~=false,units[unit] and units[unit].rangeChecked~=false end
function GetRaidTargetIndex(unit) return units[unit] and units[unit].marker end
function GetReadyCheckStatus(unit) return units[unit] and units[unit].ready end
function SetRaidTargetIconTexture(texture,index) texture.marker=index end
function UnitAura(unit,index,filter)
    local u=units[unit]; local list=u and u[filter=='HELPFUL' and 'buffs' or 'debuffs']
    -- RAID: only debuffs the player can remove (removable=false opts one out).
    if list and filter and filter:find('RAID',1,true) then local kept={}; for _,d in ipairs(list) do if d.removable~=false then kept[#kept+1]=d end end; list=kept end
    local a=list and list[index]
    if a then return a.name,'Rank 1',a.icon or 'aura-'..a.id,a.stacks or 1,a.dispel,a.duration or 0,a.expires or 0,a.caster,false,false,a.id end
end
function GetSpellInfo(id) if type(id)=='number' and id>0 and id~=999999 then return 'Spell '..id,'Rank 1','icon-'..id end end
function SecureButton_GetModifiedUnit(button) local unit=button:GetAttribute('unit'); return units[unit] and units[unit].vehicle or unit end
function m:GetAttribute(key) return self.attributes[key] end
function SetNativeAttribute(frame,key,value) local old=nativeSecure; nativeSecure=true; frame:SetAttribute(key,value); nativeSecure=old end
function HeaderUpdate(h)
    if h._updating or not h:IsShown() or not h:GetAttribute('template') then return end
    h._updating=true; local old=nativeSecure; nativeSecure=true
    local roster={}
    local pet=h.template=='SecureGroupPetHeaderTemplate'
    local filter=h:GetAttribute('groupFilter')
    local function Allowed(i)
        if not filter then return true end
        local u=units['raid'..i]
        for token in tostring(filter):gmatch('[^,]+') do if token==tostring(u.group or 1) or token==u.mainRole then return true end end
    end
    if raidCount>0 and h:GetAttribute('showRaid') then
        for i=1,raidCount do
            local unit=pet and 'raidpet'..i or 'raid'..i
            if Allowed(i) and (not pet or units[unit]) then roster[#roster+1]=unit end
        end
    elseif raidCount==0 and ((partyCount>0 and h:GetAttribute('showParty')) or partyCount==0 and h:GetAttribute('showSolo')) then
        if h:GetAttribute('showPlayer') and (not pet or units.pet) then roster[#roster+1]=pet and 'pet' or 'player' end
        for i=1,partyCount do if not pet or units['partypet'..i] then roster[#roster+1]=pet and 'partypet'..i or 'party'..i end end
    end
    if not h:GetAttribute('groupFilter') and h:GetAttribute('nameList') then
        local selected={}; for name in h:GetAttribute('nameList'):gmatch('[^,]+') do for _,unit in ipairs(roster) do if UnitName(unit)==name then selected[#selected+1]=unit; break end end end
        roster=selected
    end
    if h:GetAttribute('sortMethod')=='NAME' then table.sort(roster,function(a,b) return UnitName(a)<UnitName(b) end) end
    local starting=h:GetAttribute('startingIndex') or 1
    local slots=(h:GetAttribute('unitsPerColumn') or 5)*(h:GetAttribute('maxColumns') or 1)
    local displayed=math.min(starting-1+slots,#roster)-starting+1
    local needed=math.max(1,displayed)
    h.nativeButtons=h.nativeButtons or {}
    for i=1,needed do if not h.nativeButtons[i] then h.nativeButtons[i]=CreateFrame('Button',h:GetName()..'Unit'..i,h,h:GetAttribute('template')) end end
    -- Wrath SecureTemplates.lua configureChildren (lines 729-790): after creating
    -- children it runs getRelativePointAnchor -> strupper (line 624) on point
    -- (default TOP) and, with more than one column, on columnAnchorPoint (no default).
    local wrathDisplayed=#roster-(starting-1)
    local perColumn=h:GetAttribute('unitsPerColumn'); local columns=1
    if perColumn and wrathDisplayed>perColumn then columns=math.min(math.ceil(wrathDisplayed/perColumn),h:GetAttribute('maxColumns') or 1) end
    local function Anchor(key,value)
        if type(value)~='string' or not WRATH_ANCHORS[value:upper()] then
            nativeSecure=old; h._updating=false
            error(("SecureTemplates.lua:624: bad argument #1 to 'strupper' (string expected, got %s) [%s %s=%s]"):format(type(value),h:GetName() or '?',key,tostring(value)),0)
        end
    end
    Anchor('point',h:GetAttribute('point') or 'TOP')
    if columns>1 then Anchor('columnAnchorPoint',h:GetAttribute('columnAnchorPoint')) end
    for i,b in ipairs(h.nativeButtons) do
        local unit=roster[starting+i-1]; b:SetAttribute('unit',unit)
        if unit then b:Show() else b:Hide() end
    end
    nativeSecure=old; h._updating=false
end
function m:SetAttribute(key,value)
    assert(not combat or not self.protected or nativeSecure,'Insecure protected attribute: '..key)
    -- Native headers rerun SecureGroupHeader_Update for every addon write while shown.
    if self.isHeader and not nativeSecure and self:IsShown() then self.shownAttributeWrites=(self.shownAttributeWrites or 0)+1; self.lastShownWrite=key end
    local changed=self.attributes[key]~=value; set(self,key,value)
    if changed then self:RunScript('OnAttributeChanged',key,value); if self.isHeader then HeaderUpdate(self) end end
end
function m:Show()
    assert(not combat or not self.protected or nativeSecure,'Insecure protected Show')
    if self.isHeader and self.firstShowPoint==nil then self.firstShowPoint=self:GetAttribute('point') or false; self.firstShowColumnAnchor=self:GetAttribute('columnAnchorPoint') or false end
    show(self); if self.isHeader then HeaderUpdate(self) end
end
function m:Hide() assert(not combat or not self.protected or nativeSecure,'Insecure protected Hide'); hide(self) end
for _,key in ipairs({'SetWidth','SetHeight','SetPoint','ClearAllPoints','SetParent'}) do
    local before=m[key]; m[key]=function(self,...) assert(not combat or not self.protected or nativeSecure,'Insecure protected layout: '..key); return before(self,...) end
end
function CreateFrame(kind,name,parent,template)
    assert(not combat,'Preallocated headers attempted to create a frame in combat')
    local f=create(kind,name,parent,template); f.protected=template and (template:find('Secure') or template=='EUI335RaidUnitTemplate') and true or false
    if template=='SecureGroupHeaderTemplate' or template=='SecureGroupPetHeaderTemplate' then f.isHeader=true; headers[#headers+1]=f end
    if template=='EUI335RaidUnitTemplate' then f:Hide(); EUI335RaidFrames_OnLoad(f) end
    return f
end
-- Macro conditionals used by the module's visibility drivers.
local function Condition(cond)
    if cond=='' then return true end
    local target
    for part in cond:gmatch('[^,]+') do
        part=part:gsub('^%s+',''):gsub('%s+$','')
        local t=part:match('^target=(.+)$') or part:match('^@(.+)$')
        if t then target=t
        elseif part=='group:raid' then if raidCount==0 then return false end
        elseif part=='group:party' then if raidCount>0 or partyCount==0 then return false end
        elseif part=='help' then local u=target and units[target]; if not u or u.hostile then return false end
        elseif part=='nocombat' then if combat then return false end
        else error('Unsupported macro condition: '..part) end
    end
    return true
end
function EvaluateDriver(driver)
    for clause in driver:gmatch('[^;]+') do
        clause=clause:gsub('^%s+','')
        local conds,rest=clause:match('^%[(.-)%]%s*(.*)$')
        if not conds then conds,rest='',clause end
        if Condition(conds) then return (rest:gsub('%s+$','')) end
    end
end
function TickHeaders() local previous=nativeSecure; nativeSecure=true; for _,h in ipairs(headers) do HeaderUpdate(h) end; for f,driver in pairs(drivers) do
    if EvaluateDriver(driver)=='show' then f:Show() else f:Hide() end
end; nativeSecure=previous end
function RegisterStateDriver(f,_,driver) assert(not combat); drivers[f]=driver; TickHeaders() end
UnitPopupFrames={}
function UIDropDownMenu_Initialize(f,fn) f.initialize=fn end
function UnitPopup_ShowMenu(f,menu,unit) lastUnitMenu={menu,unit} end
function ToggleDropDownMenu(_,_,f) f.initialize(f) end
function CloseDropDownMenus() menusClosed=(menusClosed or 0)+1 end
function GameTooltip:SetUnit(unit) self.tooltipUnit=unit; self.auraIndex=nil end
function GameTooltip:SetUnitBuff(unit,index) self.tooltipUnit,self.auraIndex,self.auraFilter=unit,index,'HELPFUL' end
function GameTooltip:SetUnitDebuff(unit,index,filter) self.tooltipUnit,self.auraIndex,self.auraFilter=unit,index,filter or 'HARMFUL' end
cursorX,cursorY=500,500
function GetCursorPosition() return cursorX,cursorY end
RAID_CLASS_COLORS.PRIEST={r=1,g=1,b=1}; RAID_CLASS_COLORS.DRUID={r=1,g=.49,b=.04}
RAID_CLASS_COLORS.PALADIN={r=.96,g=.55,b=.73}; RAID_CLASS_COLORS.WARRIOR={r=.78,g=.61,b=.43}
DebuffTypeColor={Magic={r=.2,g=.6,b=1},Curse={r=.6,g=0,b=1},Poison={r=0,g=.6,b=0}}
for i=1,4 do local f=CreateFrame('Button','PartyMemberFrame'..i,UIParent); f.protected=true; f:SetPoint('TOPLEFT',UIParent,'TOPLEFT',10,-i*70); f:RegisterEvent('UNIT_HEALTH'); f.nativeCallback=function() end end
units.player={name='Player',guid='P',class='DRUID',health=15000,maxHealth=20000,power=5000,maxPower=10000,role='HEALER',rank=2}
