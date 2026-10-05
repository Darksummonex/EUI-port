local ADDON_NAME,ns=...
local E=EllesmereUI
if not ns.addon then return end
local white="Interface\\Buttons\\WHITE8X8"
local textures,names,order={flat=white,blizzard="Interface\\TargetingFrame\\UI-StatusBar"},{flat="Flat",blizzard="Blizzard"},{"flat","blizzard"}
for _,key in ipairs({"atrocity","beautiful","divide","fade","fade-right","glass","gradient-bt","gradient-lr","gradient-rl","gradient-tb","matte","plating","sheer","thin-line-bottom","thin-line-top"}) do
    textures[key]="Interface\\AddOns\\EllesmereUIRaidFrames\\Media\\Textures_335\\"..key..".tga"; names[key]=key:gsub("-"," "):gsub("^%l",string.upper); order[#order+1]=key
end
ns.healthBarTextures,ns.healthBarTextureNames,ns.healthBarTextureOrder=textures,names,order
local function Texture(key) return textures[key] or (type(key)=="string" and key:find("\\",1,true) and key) or white end
local function Text(fs,value) if fs:GetText()~=value then fs:SetText(value) end end
local function NewText(parent)
    local fs=parent:CreateFontString(nil,"OVERLAY"); ns.Font(fs,11); return fs
end
function ns.AuraIndicators(c,prefix)
    return E.WrathAuraIndicators.List(c,prefix,true)
end
local function IndicatorLimit(c,prefix,d)
    return math.max(0,math.min(8,tonumber(d.maxIcons) or (prefix=="buff" and c.maxBuffs or c.maxDebuffs) or 3))
end
local function NewIcon(parent,size)
    local t=parent:CreateTexture(nil,"OVERLAY"); ns.Size(t,size,size); t:Hide(); return t
end
local function Aura(parent)
    local a=CreateFrame("Frame",nil,parent); a:EnableMouse(false); a:Hide()
    a.icon=a:CreateTexture(nil,"ARTWORK"); a.icon:SetAllPoints(a); a.icon:SetTexCoord(.08,.92,.08,.92)
    a:SetBackdrop({edgeFile=white,edgeSize=1})
    a.cooldown=CreateFrame("Cooldown",nil,a,"CooldownFrameTemplate"); a.cooldown:SetAllPoints(a)
    a.count=NewText(a); a.count:SetPoint("BOTTOMRIGHT",a,"BOTTOMRIGHT",0,0)
    a.time=NewText(a); a.time:SetPoint("CENTER",a,"CENTER",0,0)
    return a
end
local dropdown
local function PrepareMenu()
    if dropdown then return end
    dropdown=CreateFrame("Frame","EUI335RaidUnitMenu",UIParent,"UIDropDownMenuTemplate"); dropdown:SetID(1)
    if UnitPopupFrames then table.insert(UnitPopupFrames,dropdown:GetName()) end
    UIDropDownMenu_Initialize(dropdown,function(self)
        local unit=self.unit; if not unit then return end
        local menu=UnitIsUnit(unit,"player") and "SELF" or UnitIsUnit(unit,"vehicle") and "VEHICLE" or UnitIsUnit(unit,"pet") and "PET" or UnitIsPlayer(unit) and (UnitInRaid(unit) and "RAID_PLAYER" or "PARTY") or "TARGET"
        UnitPopup_ShowMenu(self,menu,unit)
    end,"MENU")
end
function ns.InitButton(b)
    if b.Health then return end
    local h=b:GetParent(); b._euiKind=b._euiKind or h._euiKind; b._euiGroup=b._euiGroup or h._euiGroup
    b:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1}); b:SetBackdropColor(.025,.03,.04,1)
    b.Health=CreateFrame("StatusBar",nil,b); b.Health:SetMinMaxValues(0,1); b.Health:SetValue(0)
    b.Health.bg=b.Health:CreateTexture(nil,"BACKGROUND"); b.Health.bg:SetAllPoints(b.Health); b.Health.bg:SetTexture(white); b.Health.bg:SetVertexColor(.08,.08,.09,1)
    b.Power=CreateFrame("StatusBar",nil,b); b.Power:SetMinMaxValues(0,1); b.Power:SetValue(0)
    local textHost=CreateFrame("Frame",nil,b); textHost:SetFrameLevel(b:GetFrameLevel()+5); textHost:EnableMouse(false); textHost:SetAllPoints(b); b.textHost=textHost
    b.name,b.healthText,b.powerText,b.status=NewText(textHost),NewText(textHost),NewText(textHost),NewText(textHost)
    b.role,b.leader,b.raidMarker,b.ready=NewIcon(textHost,12),NewIcon(textHost,12),NewIcon(textHost,18),NewIcon(textHost,22)
    b.leader:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
    b.raidMarker:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    b.buffs,b.debuffs={},{}
    for i=1,8 do b.buffs[i]=Aura(textHost); b.debuffs[i]=Aura(textHost) end
    if not b._euiPreview then
        b:RegisterForClicks("AnyUp"); b:SetAttribute("*type1","target"); b:SetAttribute("*type2","menu")
        b:SetAttribute("toggleForVehicle",true); b:SetAttribute("checkselfcast",false); b:SetAttribute("checkfocuscast",false)
        PrepareMenu()
        b.menu=function(self,unit)
            unit=unit or SecureButton_GetModifiedUnit(self); if not unit then return end
            if dropdown.openedFor and dropdown.openedFor~=self then CloseDropDownMenus() end
            dropdown.unit,dropdown.openedFor=unit,self; ToggleDropDownMenu(1,nil,dropdown,"cursor")
        end
        b:HookScript("OnAttributeChanged",function(self,key)
            if key=="unit" then self._euiGUID=nil; ns.UpdateFrame(self,true) end
        end)
        b:HookScript("OnShow",function(self) ns.UpdateFrame(self,true) end)
        b:HookScript("OnHide",function(self) if ns.hovered==self then ns.hovered=nil; GameTooltip:Hide() end end)
        b:HookScript("OnEnter",function(self) ns.hovered=self; ns.tooltipKey=nil; ns.UpdateTooltip() end)
        b:HookScript("OnLeave",function(self) if ns.hovered==self then ns.hovered=nil; ns.tooltipKey=nil; GameTooltip:Hide() end end)
        ns.buttons[#ns.buttons+1]=b
        ns.LayoutButton(b)
        -- Clique's conventional registration table also supports this module.
        ClickCastFrames=ClickCastFrames or {}; ClickCastFrames[b]=true
    else ns.LayoutButton(b) end
end
_G.EUI335RaidFrames_OnLoad=ns.InitButton
function ns.LayoutButton(b)
    local c=ns.GetSettings(b._euiKind); if not c then return end
    local w=math.max(60,math.min(300,tonumber(c.frameWidth) or 125)); local h=math.max(30,math.min(120,tonumber(c.frameHeight) or 52))
    local power=c.showPower and math.min(h/3,math.max(2,tonumber(c.powerHeight) or 4)) or 0
    ns.Size(b,w,h); b.Health:ClearAllPoints(); b.Health:SetPoint("TOPLEFT",b,"TOPLEFT",1,-1); b.Health:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-1,1+power)
    b.Power:ClearAllPoints(); b.Power:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",1,1); ns.Size(b.Power,w-2,math.max(1,power)); if power>0 then b.Power:Show() else b.Power:Hide() end
    b.Health:SetStatusBarTexture(Texture(c.healthBarTexture)); b.Power:SetStatusBarTexture(Texture(c.healthBarTexture))
    ns.Font(b.name,c.nameSize); ns.Font(b.healthText,c.healthTextSize); ns.Font(b.powerText,c.powerTextSize); ns.Font(b.status,c.statusTextSize)
    local inset=c.showRole and 18 or 4
    local healthWidth=c.healthDisplay=="none" and 0 or math.max(18,w*(c.healthDisplay=="both" and .55 or c.healthDisplay=="percent" and .28 or .4))
    b.name:ClearAllPoints(); b.name:SetPoint("TOPLEFT",b,"TOPLEFT",inset,-5); b.name:SetWidth(math.max(10,w-inset-healthWidth-6)); b.name:SetHeight(c.nameSize+2); b.name:SetJustifyH("LEFT")
    b.healthText:ClearAllPoints(); b.healthText:SetPoint("TOPRIGHT",b,"TOPRIGHT",-4,-5); b.healthText:SetWidth(math.max(1,healthWidth)); b.healthText:SetHeight(c.healthTextSize+2); b.healthText:SetJustifyH("RIGHT")
    b.powerText:ClearAllPoints(); b.powerText:SetPoint("CENTER",b.Power,"CENTER",0,0)
    b.status:ClearAllPoints(); b.status:SetPoint("CENTER",b.Health,"CENTER",0,-2)
    b.role:SetPoint("TOPLEFT",b,"TOPLEFT",3,-3); b.leader:SetPoint("TOPRIGHT",b,"TOPRIGHT",4,6)
    b.raidMarker:SetPoint("BOTTOM",b,"TOP",0,2); b.ready:SetPoint("CENTER",b,"CENTER",0,0)
    -- Fit both pools into the frame; the large configured value is capped only
    -- for drawing, so narrowing a frame never puts icons over its neighbour.
    for _,entry in ipairs({{"buff",b.buffs},{"debuff",b.debuffs}}) do
        local prefix,pool=unpack(entry); local used=0
        for _,d in ipairs(ns.AuraIndicators(c,prefix)) do
            local limit=IndicatorLimit(c,prefix,d)
            for i=1,limit do
                used=used+1; local a=pool[used]; if not a then break end
                local size,point,x,y=E.WrathAuraIndicators.Geometry(c,prefix,d,i,w,h,true)
                ns.Size(a,size,size); a:ClearAllPoints()
                a:SetPoint(point,b.Health,point,x,y); a:SetAlpha(d.opacity or 1)
                a:SetBackdrop({edgeFile=white,edgeSize=math.max(1,tonumber(d.border) or 1)})
                a.indicator=d; a.prefix=prefix
                ns.Font(a.count,d.stackSize or c.auraStackTextSize); ns.Font(a.time,d.durationSize or c.auraDurationTextSize)
            end
        end
    end
end
local function ClearAuras(b)
    for _,list in ipairs({b.buffs,b.debuffs}) do for _,a in ipairs(list) do a:Hide(); a.unit=nil end end
end
function ns.UpdateAuras(b,unit,c)
    ClearAuras(b); b.dispelType=nil; b.dispelCandidates={}
    if not unit or not UnitExists(unit) then return end
    for _,entry in ipairs({{"buff",b.buffs,c.showBuffs,math.min(8,c.maxBuffs or 3),"HELPFUL"},{"debuff",b.debuffs,c.showDebuffs,math.min(8,c.maxDebuffs or 3),c.onlyDispellable and "HARMFUL|RAID" or "HARMFUL"}}) do
        local prefix,pool,show,limit,filter=unpack(entry)
        local records={}
        for i=1,40 do
            local name,_,icon,stacks,dtype,duration,expiry,caster,stealable,_,id=UnitAura(unit,i,filter)
            if not name then break end
            if prefix=="debuff" and dtype then b.dispelCandidates[#b.dispelCandidates+1]={kind=dtype,expiry=expiry or 0} end
            local mine=caster and (UnitIsUnit(caster,"player") or UnitIsUnit(caster,"pet") or UnitIsUnit(caster,"vehicle"))
            local allow=E.WrathAuraIndicators.Allows(c,prefix,id,mine,duration,stealable)
            if show and allow then records[#records+1]={index=i,id=id,icon=icon,stacks=stacks,dtype=dtype,duration=duration or 0,expiry=expiry or 0,mine=mine} end
        end
        local allocated=0
        for _,d in ipairs(ns.AuraIndicators(c,prefix)) do
            local count=IndicatorLimit(c,prefix,d); local used=0; local sorted={}
            for i,r in ipairs(records) do sorted[i]=r end
            if d.customOrder then
                local order={}; for i,id in ipairs(d.spellOrder or {}) do order[id]=i end
                table.sort(sorted,function(a,z) local ar,zr=order[a.id] or 999,order[z.id] or 999; return ar~=zr and ar<zr or ar==zr and a.index<z.index end)
            end
            for _,r in ipairs(sorted) do
                local tracked=E.WrathAuraIndicators.HasSpell(d.spells,r.id)
                local accepts=d.filter~="tracked" or tracked
                if d.filter=="own" or d.ownOnly then accepts=accepts and r.mine end
                if d.enabled~=false and (not d.showIn or d.showIn=="both" or d.showIn==b._euiKind) and accepts and used<count then
                    local a=pool[allocated+used+1]; if not a then break end
                    used=used+1
                    a.unit,a.index,a.filter,a.spellID,a.expiry,a.duration=unit,r.index,filter,r.id,r.expiry,r.duration
                    a.indicator=d; a.icon:SetTexture(r.icon); if d.hideIcons then a.icon:Hide() else a.icon:Show() end
                    Text(a.count,d.showStacks~=false and r.stacks and r.stacks>1 and tostring(r.stacks) or "")
                    local color=prefix=="debuff" and DebuffTypeColor and DebuffTypeColor[r.dtype or "none"] or nil
                    a:SetBackdropBorderColor(color and color.r or 0,color and color.g or 0,color and color.b or 0,d.border==0 and 0 or 1)
                    if d.durationSwipe~=false then a.cooldown:SetCooldown(a.duration>0 and a.expiry-a.duration or 0,a.duration); a.cooldown:Show() else a.cooldown:Hide() end
                    a:Show()
                end
            end
            allocated=allocated+count; if allocated>=#pool then break end
        end
    end
    -- Frame colour: the client's RAID debuff filter only returns debuffs this character can
    -- remove right now (class, spec and talents), so no dispel tables are needed.
    b.dispelColorCandidates=nil
    if c.dispelFrameColor~=false then
        local list={}
        for i=1,40 do
            local name,_,_,_,dtype,_,expiry=UnitAura(unit,i,"HARMFUL|RAID")
            if not name then break end
            if dtype and dtype~="" then list[#list+1]={kind=dtype,expiry=expiry or 0} end
        end
        if #list>0 then b.dispelColorCandidates=list end
    end
end
-- Highest priority first when several removable types are present.
local dispelPriority={Magic=1,Curse=2,Disease=3,Poison=4}
local function DispelColorType(b)
    local best,rank
    for _,a in ipairs(b.dispelColorCandidates or {}) do
        local r=dispelPriority[a.kind] or 9
        if (a.expiry==0 or a.expiry>GetTime()) and (not rank or r<rank) then best,rank=a.kind,r end
    end
    return best
end
local function AuraTimers(b)
    for _,list in ipairs({b.buffs,b.debuffs}) do for _,a in ipairs(list) do if a:IsShown() then
        local remaining=a.expiry>0 and a.expiry-GetTime() or 0
        if a.expiry>0 and remaining<=0 then a:Hide()
        else Text(a.time,a.indicator and a.indicator.durationText==false and "" or (remaining>60 and math.ceil(remaining/60).."m" or remaining>0 and tostring(math.ceil(remaining)) or "")) end
    end end end
end
local function Small(value)
    if value>=1000000 then return string.format("%.1fm",value/1000000) elseif value>=1000 then return string.format("%.1fk",value/1000) end
    return tostring(math.floor(value))
end
local previewClasses={"WARRIOR","PRIEST","DRUID","PALADIN","MAGE","HUNTER","SHAMAN","ROGUE","WARLOCK","DEATHKNIGHT"}
function ns.UpdateFrame(b,auras)
    if not b.Health then return end
    local c=ns.GetSettings(b._euiKind); if not c then return end
    local base=not b._euiPreview and b:GetAttribute("unit")
    local unit=base and SecureButton_GetModifiedUnit(b)
    if base and unit=="pet" and base~="pet" then unit="vehicle" end
    if base and (not unit or not UnitExists(unit)) then unit=base end
    local valid=b._euiPreview or (unit and UnitExists(unit))
    b.unit=unit
    if not valid then
        b._euiGUID=nil; b.dispelCandidates=nil; b.Health:SetValue(0); b.Power:SetValue(0); Text(b.name,""); Text(b.healthText,""); Text(b.powerText,""); Text(b.status,""); ClearAuras(b)
        for _,t in ipairs({b.role,b.leader,b.raidMarker,b.ready}) do t:Hide() end; b:SetAlpha(1)
        if ns.hovered==b then ns.tooltipKey=nil; GameTooltip:Hide() end; return
    end
    local guid=b._euiPreview or UnitGUID(unit)
    if guid~=b._euiGUID then b._euiGUID=guid; auras=true; ns.tooltipKey=nil end
    local class=b._euiPreview and previewClasses[(b._euiPreview-1)%#previewClasses+1] or select(2,UnitClass(unit))
    local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] or {r=.15,g=.8,b=.25}
    local hp=b._euiPreview and (60+b._euiPreview%4*10) or (UnitHealth(unit) or 0)
    local maximum=b._euiPreview and 100 or (UnitHealthMax(unit) or 1); maximum=math.max(1,maximum); hp=math.min(maximum,math.max(0,hp))
    b.Health:SetMinMaxValues(0,maximum); b.Health:SetValue(hp)
    local connected=b._euiPreview or UnitIsConnected(unit)
    local baseR,baseG,baseB=.15,.8,.25
    if not connected then baseR,baseG,baseB=.35,.35,.35
    elseif c.healthClassColored then baseR,baseG,baseB=color.r,color.g,color.b end
    b.Health:SetStatusBarColor(baseR,baseG,baseB)
    Text(b.name,b._euiPreview and ("Player "..b._euiPreview) or (UnitName(base or unit) or ""))
    if c.classColoredNames then b.name:SetTextColor(color.r,color.g,color.b) else b.name:SetTextColor(1,1,1) end
    local status=not connected and "Offline" or not b._euiPreview and (UnitIsGhost(unit) and "Ghost" or UnitIsDead(unit) and "Dead" or UnitIsAFK(unit) and "AFK") or ""
    Text(b.status,status)
    local health=c.healthDisplay=="percent" and math.floor(hp/maximum*100+.5).."%" or c.healthDisplay=="current" and Small(hp) or c.healthDisplay=="missing" and (hp<maximum and ("-"..Small(maximum-hp)) or "") or c.healthDisplay=="both" and (Small(hp).." / "..Small(maximum)) or ""
    Text(b.healthText,status~="" and "" or health)
    local powerType,token=0,"MANA"; if not b._euiPreview then powerType,token=UnitPowerType(unit) end
    local power=b._euiPreview and 65 or (UnitPower(unit,powerType) or 0); local maxPower=b._euiPreview and 100 or (UnitPowerMax(unit,powerType) or 0)
    b.Power:SetMinMaxValues(0,math.max(1,maxPower)); b.Power:SetValue(power)
    local pc=PowerBarColor and (PowerBarColor[token] or PowerBarColor[powerType]) or {r=.1,g=.4,b=1}; b.Power:SetStatusBarColor(pc.r,pc.g,pc.b)
    Text(b.powerText,c.showPowerText and status=="" and maxPower>0 and math.floor(power/maxPower*100+.5).."%" or "")
    if auras then if b._euiPreview then ClearAuras(b) else ns.UpdateAuras(b,unit,c) end end
    AuraTimers(b)
    b.dispelType=nil
    for _,a in ipairs(b.dispelCandidates or {}) do if a.expiry==0 or a.expiry>GetTime() then b.dispelType=a.kind; break end end
    -- Swap the health colour to the removable debuff's type colour (Magic/Curse/Disease/Poison).
    b.dispelColorType=nil
    if connected and c.dispelFrameColor~=false and DebuffTypeColor then
        local kind=DispelColorType(b)
        if b._euiPreview and not kind then
            local demo={"Magic","Curse","Disease","Poison"}
            if b._euiPreview%3==0 then kind=demo[(b._euiPreview/3-1)%4+1] end
        end
        local dc=kind and DebuffTypeColor[kind]
        if dc then
            local s=math.max(.1,math.min(1,tonumber(c.dispelFrameColorStrength) or 1))
            b.dispelColorType=kind
            b.Health:SetStatusBarColor(baseR+(dc.r-baseR)*s,baseG+(dc.g-baseG)*s,baseB+(dc.b-baseB)*s)
        end
    end
    local threat=not b._euiPreview and UnitThreatSituation(base or unit)
    if c.showThreat and threat and threat>=2 then b:SetBackdropBorderColor(1,.15,.15,1)
    elseif c.dispelHighlight and b.dispelType and DebuffTypeColor and DebuffTypeColor[b.dispelType] then local dc=DebuffTypeColor[b.dispelType]; b:SetBackdropBorderColor(dc.r,dc.g,dc.b,1)
    elseif c.showTargetBorder and base and UnitIsUnit(base,"target") then b:SetBackdropBorderColor(.05,.82,.61,1)
    else b:SetBackdropBorderColor(0,0,0,1) end
    local range,checked=true,false
    if c.rangeFade and not b._euiPreview and not UnitIsUnit(base or unit,"player") and UnitInRange then range,checked=UnitInRange(base or unit) end
    b:SetAlpha(checked and (range==false or range==0) and c.outOfRangeAlpha or 1)
    local role
    if b._euiPreview then role=b._euiPreview%5==1 and "tank" or b._euiPreview%5==2 and "healer" or "dps"
    else role=ns.UnitRole(base or unit) end
    if c.showRole and role and not (role=="dps" and c.hideDpsRoleIcons) then b.role:SetTexture("Interface\\AddOns\\EllesmereUIRaidFrames\\Media\\Icons_335\\"..role..".tga"); b.role:Show() else b.role:Hide() end
    local leader=b._euiPreview and b._euiPreview==1 or base and UnitIsPartyLeader(base)
    local raidIndex=base and tonumber(base:match("^raid(%d+)$"))
    if raidIndex then leader=select(2,GetRaidRosterInfo(raidIndex))==2 end
    if c.showLeader and leader then b.leader:Show() else b.leader:Hide() end
    local marker=not b._euiPreview and GetRaidTargetIndex(base or unit)
    if c.showRaidMarker and marker then SetRaidTargetIconTexture(b.raidMarker,marker); b.raidMarker:Show() else b.raidMarker:Hide() end
    local ready=not b._euiPreview and ns.readyUntil and GetTime()<ns.readyUntil and GetReadyCheckStatus(base or unit)
    if c.showReadyCheck and ready then b.ready:SetTexture("Interface\\RaidFrame\\UI-ReadyCheck-"..(ready=="ready" and "Ready" or ready=="notready" and "NotReady" or "Waiting")); b.ready:Show() else b.ready:Hide() end
end
function ns.UpdateTooltip()
    local b=ns.hovered; if not b then return end
    if not b:IsShown() or not b.unit or not UnitExists(b.unit) then ns.tooltipKey=nil; GameTooltip:Hide(); return end
    local c=ns.GetSettings(b._euiKind); local key=b.unit..":"..tostring(b._euiGUID); local hovered
    if c.showAuraTooltips then
        local x,y=GetCursorPosition()
        for _,list in ipairs({b.buffs,b.debuffs}) do for _,a in ipairs(list) do if a:IsShown() then
            local left,right,top,bottom=a:GetLeft(),a:GetRight(),a:GetTop(),a:GetBottom(); local scale=a:GetEffectiveScale()
            if left and right and top and bottom and x>=left*scale and x<=right*scale and y>=bottom*scale and y<=top*scale then hovered=a; break end
        end end; if hovered then break end end
    end
    if hovered then key=key..":"..hovered.filter..":"..hovered.index end
    if ns.tooltipKey==key then return end; ns.tooltipKey=key
    GameTooltip:SetOwner(b,"ANCHOR_RIGHT")
    if hovered then
        if hovered.filter=="HELPFUL" then GameTooltip:SetUnitBuff(hovered.unit,hovered.index)
        else GameTooltip:SetUnitDebuff(hovered.unit,hovered.index,c.onlyDispellable and "RAID" or nil) end
    else GameTooltip:SetUnit(b.unit) end
    GameTooltip:Show()
end
