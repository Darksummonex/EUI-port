local ADDON_NAME,ns=...
local E=EllesmereUI
if not ns.addon then return end
local white="Interface\\Buttons\\WHITE8X8"
local textures,names,order={flat=white,blizzard="Interface\\TargetingFrame\\UI-StatusBar"},{flat="Flat",blizzard="Blizzard"},{"flat","blizzard"}
for _,key in ipairs({"atrocity","beautiful","divide","fade","fade-right","glass","gradient-bt","gradient-lr","gradient-rl","gradient-tb","matte","plating","sheer","thin-line-bottom","thin-line-top"}) do
    textures[key]="Interface\\AddOns\\EllesmereUIRaidFrames\\Media\\Textures_335\\"..key..".tga"; names[key]=key:gsub("-"," "):gsub("^%l",string.upper); order[#order+1]=key
end
ns.healthBarTextures,ns.healthBarTextureNames,ns.healthBarTextureOrder=textures,names,order
if E.AppendSharedMediaTextures then E.AppendSharedMediaTextures(names,order,nil,textures) end
local function Texture(key) return E.ResolveTexturePath(textures,key) or (type(key)=="string" and key:find("\\",1,true) and key) or white end
local function Text(fs,value) if fs:GetText()~=value then fs:SetText(value) end end
local function NewText(parent)
    local fs=parent:CreateFontString(nil,"OVERLAY"); ns.Font(fs,11); return fs
end
-- Nine-point placement shared by text and icons (Retail position keys).
local POINTS={topleft="TOPLEFT",top="TOP",topright="TOPRIGHT",left="LEFT",center="CENTER",right="RIGHT",bottomleft="BOTTOMLEFT",bottom="BOTTOM",bottomright="BOTTOMRIGHT"}
ns.POSITION_VALUES={topleft="Top Left",top="Top",topright="Top Right",left="Left",center="Center",right="Right",bottomleft="Bottom Left",bottom="Bottom",bottomright="Bottom Right"}
ns.POSITION_ORDER={"topleft","top","topright","left","center","right","bottomleft","bottom","bottomright"}
local function Place(region,anchor,position,size,ox,oy,inset)
    local point=POINTS[position] or "CENTER"; inset=inset or 2
    if size then ns.Size(region,size,size) end
    region:ClearAllPoints()
    region:SetPoint(point,anchor,point,(point:find("LEFT") and inset or point:find("RIGHT") and -inset or 0)+(tonumber(ox) or 0),(point:find("TOP") and -inset or point:find("BOTTOM") and inset or 0)+(tonumber(oy) or 0))
    return point
end
ns.Place=Place
-- Role icon styles: Retail "modern", "light" (blizzLight art) and "pixels" as
-- uncompressed TGAs, plus the native 3.3.5 LFD role sheet.
local ROLE_DIR="Interface\\AddOns\\EllesmereUIRaidFrames\\Media\\Icons_335\\"
local LFG_ROLES={tank={0,19/64,22/64,41/64},healer={20/64,39/64,1/64,20/64},dps={20/64,39/64,22/64,41/64}}
ns.ROLE_STYLE_VALUES={modern="Modern",light="Light",pixels="Pixels",blizzard="Blizzard (LFD)"}
ns.ROLE_STYLE_ORDER={"modern","light","pixels","blizzard"}
function ns.SetRoleTexture(t,role,style)
    if style=="blizzard" then t:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES"); t:SetTexCoord(unpack(LFG_ROLES[role]))
    else t:SetTexture(ROLE_DIR..(style=="pixels" and "pixels-"..role or style=="light" and role or role.."-modern")..".tga"); t:SetTexCoord(0,1,0,1) end
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
-- Debuff type colours: the per-layout Retail swatches, else the client table.
local dispelKeys={Magic="dispelColorMagic",Curse="dispelColorCurse",Disease="dispelColorDisease",Poison="dispelColorPoison"}
function ns.DispelColor(c,kind)
    local custom=kind and dispelKeys[kind] and c[dispelKeys[kind]]
    if custom then return custom end
    return kind and DebuffTypeColor and DebuffTypeColor[kind]
end
-- Wrath has no Bleed debuff type, so Retail's fifth slot does not exist here.
local dispelPriority={Magic=1,Curse=2,Disease=3,Poison=4}
local function DispelActive(c)
    return (c.dispelOverlay or "fill")~="none" or (tonumber(c.dispelBorderSize) or 0)>0 or c.showDispelIcons or c.dispelHighlight
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
local function ShowHover(self,on)
    local c=ns.GetSettings(self._euiKind)
    if on and c and c.hoverBorderEnabled~=false then local hc=c.hoverBorderColor or {r=1,g=1,b=1}; self.hover:SetBackdropBorderColor(hc.r,hc.g,hc.b,1); self.hover:Show() else self.hover:Hide() end
end
function ns.InitButton(b)
    if b.Health then return end
    local h=b:GetParent(); b._euiKind=b._euiKind or h._euiKind; b._euiGroup=b._euiGroup or h._euiGroup; b._euiPet=b._euiPet or h._euiPet
    b:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1}); b:SetBackdropColor(.025,.03,.04,1); b._euiBorder=1
    b.Health=CreateFrame("StatusBar",nil,b); b.Health:SetMinMaxValues(0,1); b.Health:SetValue(0)
    b.Health.bg=b.Health:CreateTexture(nil,"BACKGROUND"); b.Health.bg:SetAllPoints(b.Health); b.Health.bg:SetTexture(white); b.Health.bg:SetVertexColor(.08,.08,.09,1)
    b.healPred=b.Health:CreateTexture(nil,"OVERLAY"); b.healPred:Hide()
    b.absorb=E.Absorbs and E.Absorbs.CreateOverlay(b.Health,"OVERLAY")
    b.dispelOverlay=b.Health:CreateTexture(nil,"OVERLAY"); b.dispelOverlay:SetAllPoints(b.Health); b.dispelOverlay:SetTexture(white); b.dispelOverlay:Hide()
    b.dispelBorder=CreateFrame("Frame",nil,b.Health); b.dispelBorder:SetAllPoints(b.Health); b.dispelBorder:EnableMouse(false); b.dispelBorder:Hide()
    b.Power=CreateFrame("StatusBar",nil,b); b.Power:SetMinMaxValues(0,1); b.Power:SetValue(0)
    local textHost=CreateFrame("Frame",nil,b); textHost:SetFrameLevel(b:GetFrameLevel()+5); textHost:EnableMouse(false); textHost:SetAllPoints(b); b.textHost=textHost
    b.hover=CreateFrame("Frame",nil,textHost); b.hover:SetAllPoints(b); b.hover:EnableMouse(false); b.hover:SetBackdrop({edgeFile=white,edgeSize=1}); b.hover:Hide()
    b.name,b.healthText,b.powerText,b.status=NewText(textHost),NewText(textHost),NewText(textHost),NewText(textHost)
    b.role,b.leader,b.raidMarker=NewIcon(textHost,12),NewIcon(textHost,12),NewIcon(textHost,18)
    b.readyHost=CreateFrame("Frame",nil,textHost); b.readyHost:SetAllPoints(b); b.readyHost:SetFrameLevel(textHost:GetFrameLevel()+5); b.readyHost:EnableMouse(false)
    b.ready=NewIcon(b.readyHost,22)
    b.combat,b.rez=NewIcon(textHost,16),NewIcon(textHost,20)
    b.dispelIcon=NewIcon(textHost,16); b.dispelIcon:SetTexCoord(.08,.92,.08,.92)
    b.leader:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
    b.raidMarker:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    b.combat:SetTexture("Interface\\CharacterFrame\\UI-StateIcon"); b.combat:SetTexCoord(.5,1,0,.49)
    b.rez:SetTexture("Interface\\Icons\\Spell_Holy_Resurrection"); b.rez:SetTexCoord(.08,.92,.08,.92)
    b.buffs,b.debuffs={},{}
    for i=1,8 do b.buffs[i]=Aura(textHost); b.debuffs[i]=Aura(textHost) end
    b.raidDebuff=Aura(textHost); b.raidDebuff:SetFrameLevel(textHost:GetFrameLevel()+3)
    if not b._euiPreview then
        b:RegisterForClicks("AnyUp"); b:SetAttribute("*type1","target"); b:SetAttribute("*type2","menu")
        b:SetAttribute("toggleForVehicle",not b._euiPet); b:SetAttribute("checkselfcast",false); b:SetAttribute("checkfocuscast",false)
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
        b:HookScript("OnHide",function(self) ShowHover(self,false); if ns.hovered==self then ns.hovered=nil; GameTooltip:Hide() end end)
        b:HookScript("OnEnter",function(self) ShowHover(self,true); ns.hovered=self; ns.tooltipKey=nil; ns.UpdateTooltip() end)
        b:HookScript("OnLeave",function(self) ShowHover(self,false); if ns.hovered==self then ns.hovered=nil; ns.tooltipKey=nil; GameTooltip:Hide() end end)
        ns.buttons[#ns.buttons+1]=b
        ns.LayoutButton(b)
        -- Clique's conventional registration table also supports this module.
        ClickCastFrames=ClickCastFrames or {}; ClickCastFrames[b]=true
    else ns.LayoutButton(b) end
end
_G.EUI335RaidFrames_OnLoad=ns.InitButton
local function PlaceText(fs,b,position,ox,oy)
    local point=Place(fs,b.Health,position,nil,ox,oy,3)
    fs:SetJustifyH(point:find("LEFT") and "LEFT" or point:find("RIGHT") and "RIGHT" or "CENTER")
    return point
end
function ns.LayoutButton(b)
    local c=ns.GetSettings(b._euiKind); if not c then return end
    local w=math.max(40,math.min(300,tonumber(c.frameWidth) or 125)); local h=math.max(20,math.min(120,tonumber(c.frameHeight) or 52))
    local bs=math.max(0,math.min(4,math.floor(tonumber(c.borderSize) or 1)))
    local power=c.showPower and math.min(h/3,math.max(2,tonumber(c.powerHeight) or 4)) or 0
    ns.Size(b,w,h)
    if b._euiBorder~=bs then
        b:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=math.max(1,bs)}); b:SetBackdropColor(.025,.03,.04,1)
        b.hover:SetBackdrop({edgeFile=white,edgeSize=math.max(1,bs)}); b._euiBorder=bs
    end
    b.Health:ClearAllPoints(); b.Health:SetPoint("TOPLEFT",b,"TOPLEFT",bs,-bs); b.Health:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-bs,bs+power)
    b.Health:SetOrientation(c.healthVerticalFill and "VERTICAL" or "HORIZONTAL")
    b._healthW,b._healthH=w-2*bs,h-2*bs-power
    b.Power:ClearAllPoints(); b.Power:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",bs,bs); ns.Size(b.Power,w-2*bs,math.max(1,power)); if power>0 then b.Power:Show() else b.Power:Hide() end
    b.Health:SetStatusBarTexture(Texture(c.healthBarTexture)); b.Power:SetStatusBarTexture(Texture(c.healthBarTexture)); b.healPred:SetTexture(Texture(c.healthBarTexture))
    if not (E.ApplyTextOutline and E.ApplyTextOutline(b.name,nil,math.max(8,tonumber(c.nameSize) or 11),c.nameOutline,"raidFrames")) then ns.Font(b.name,c.nameSize) end
    ns.Font(b.healthText,c.healthTextSize); ns.Font(b.powerText,c.powerTextSize); ns.Font(b.status,c.statusTextSize)
    -- Name and health text share a row when both sit on the same edge.
    local namePos,healthPos=c.namePosition or "topleft",c.healthTextPosition or "topright"
    local roleSize=math.max(8,math.min(32,tonumber(c.roleIconSize) or 13))
    local inset=(c.showRole and (c.roleIconPosition or "bottomleft")==namePos and namePos:find("left")) and roleSize+3 or 0
    local healthWidth=c.healthDisplay=="none" and 0 or math.max(18,w*(c.healthDisplay=="both" and .55 or c.healthDisplay=="percent" and .28 or .4))
    local sameRow=namePos:sub(1,3)==healthPos:sub(1,3) and namePos~=healthPos
    PlaceText(b.name,b,namePos,(tonumber(c.nameOffsetX) or 0)+inset,c.nameOffsetY)
    b.name:SetWidth(math.max(10,w-inset-(sameRow and healthWidth or 0)-8)); b.name:SetHeight((tonumber(c.nameSize) or 11)+2)
    PlaceText(b.healthText,b,healthPos,c.healthTextOffsetX,c.healthTextOffsetY)
    b.healthText:SetWidth(math.max(1,healthWidth)); b.healthText:SetHeight((tonumber(c.healthTextSize) or 10)+2)
    b.powerText:ClearAllPoints(); b.powerText:SetPoint("CENTER",b.Power,"CENTER",0,0)
    b.status:ClearAllPoints(); b.status:SetPoint("CENTER",b.Health,"CENTER",0,-2)
    Place(b.role,b,c.roleIconPosition or "bottomleft",roleSize,c.roleIconOffsetX,c.roleIconOffsetY)
    Place(b.leader,b,c.leaderIconPosition or "top",math.max(8,math.min(32,tonumber(c.leaderIconSize) or 14)),c.leaderIconOffsetX,(tonumber(c.leaderIconOffsetY) or 0)+6)
    Place(b.raidMarker,b,c.raidMarkerPosition or "center",math.max(8,math.min(40,tonumber(c.raidMarkerSize) or 16)),c.raidMarkerOffsetX,c.raidMarkerOffsetY)
    local readySize=math.max(8,math.min(40,tonumber(c.readyCheckSize) or 20))
    Place(b.ready,b,c.readyCheckPosition or "center",readySize,c.readyCheckOffsetX,c.readyCheckOffsetY)
    Place(b.rez,b,c.readyCheckPosition or "center",readySize,c.readyCheckOffsetX,c.readyCheckOffsetY)
    Place(b.combat,b,c.combatIndicatorPosition or "right",math.max(8,math.min(32,tonumber(c.combatIndicatorSize) or 16)),c.combatIndicatorOffsetX,c.combatIndicatorOffsetY)
    Place(b.dispelIcon,b.Health,c.dispelIconPosition or "center",math.max(8,math.min(48,tonumber(c.dispelIconSize) or 16)),c.dispelIconOffsetX,c.dispelIconOffsetY,0)
    local rd=b.raidDebuff
    if rd then
        local size=math.max(10,math.min(48,tonumber(c.raidDebuffSize) or 22))
        Place(rd,b.Health,"center",math.min(size,math.max(10,h-4)),c.raidDebuffOffsetX,c.raidDebuffOffsetY,0)
        ns.Font(rd.count,math.max(8,math.floor(size*.45))); ns.Font(rd.time,math.max(8,math.floor(size*.45)))
    end
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
                a._edge=math.max(1,tonumber(d.border) or 1); a:SetBackdrop({edgeFile=white,edgeSize=a._edge})
                a.indicator=d; a.prefix=prefix
                ns.Font(a.count,d.stackSize or c.auraStackTextSize); ns.Font(a.time,d.durationSize or c.auraDurationTextSize)
            end
        end
    end
end
local function ClearAuras(b)
    for _,list in ipairs({b.buffs,b.debuffs}) do for _,a in ipairs(list) do a:Hide(); a.unit=nil end end
    if b.raidDebuff then b.raidDebuff:Hide(); b.raidDebuff.unit=nil end
end
-- Listed boss debuff with the highest priority; otherwise (optional) the
-- first debuff this character can dispel, via the client's RAID filter.
local function RaidDebuff(b,unit,c)
    local rd=b.raidDebuff
    if not rd or c.raidDebuffs==false then return end
    local list=ns.RAID_DEBUFFS or {}
    local best,rank
    for i=1,40 do
        local name,_,icon,stacks,dtype,duration,expiry,_,_,_,id=UnitAura(unit,i,"HARMFUL")
        if not name then break end
        local p=id and list[id]
        if p and (not rank or p>rank) then best,rank={index=i,filter="HARMFUL",icon=icon,stacks=stacks,dtype=dtype,duration=duration,expiry=expiry,id=id},p end
    end
    if not best and c.raidDebuffDispellable~=false then
        local name,_,icon,stacks,dtype,duration,expiry,_,_,_,id=UnitAura(unit,1,"HARMFUL|RAID")
        if name then best={index=1,filter="HARMFUL|RAID",icon=icon,stacks=stacks,dtype=dtype,duration=duration,expiry=expiry,id=id} end
    end
    if not best then return end
    rd.unit,rd.index,rd.filter,rd.indicator,rd.spellID=unit,best.index,best.filter,nil,best.id
    rd.duration,rd.expiry=best.duration or 0,best.expiry or 0
    rd.icon:SetTexture(best.icon); rd.icon:Show()
    Text(rd.count,best.stacks and best.stacks>1 and tostring(best.stacks) or "")
    local color=dispelPriority[best.dtype] and ns.DispelColor(c,best.dtype) or {r=.8,g=0,b=0}
    rd:SetBackdropBorderColor(color.r,color.g,color.b,1)
    if rd.duration>0 then rd.cooldown:SetCooldown(rd.expiry-rd.duration,rd.duration); rd.cooldown:Show() else rd.cooldown:Hide() end
    rd:Show()
end
-- Sated / Exhaustion (Retail "Hide Bloodlust Debuff"; Wrath IDs).
local lustDebuffs={[57724]=true,[57723]=true}
function ns.UpdateAuras(b,unit,c)
    ClearAuras(b); b.dispelColorCandidates=nil
    if not unit or not UnitExists(unit) then return end
    RaidDebuff(b,unit,c)
    local highlighted=b.raidDebuff and b.raidDebuff:IsShown() and b.raidDebuff.spellID
    for _,entry in ipairs({{"buff",b.buffs,c.showBuffs,math.min(8,c.maxBuffs or 3),"HELPFUL"},{"debuff",b.debuffs,c.showDebuffs,math.min(8,c.maxDebuffs or 3),c.onlyDispellable and "HARMFUL|RAID" or "HARMFUL"}}) do
        local prefix,pool,show,limit,filter=unpack(entry)
        local records={}
        for i=1,40 do
            local name,_,icon,stacks,dtype,duration,expiry,caster,stealable,_,id=UnitAura(unit,i,filter)
            if not name then break end
            local mine=caster and (UnitIsUnit(caster,"player") or UnitIsUnit(caster,"pet") or UnitIsUnit(caster,"vehicle"))
            local allow=E.WrathAuraIndicators.Allows(c,prefix,id,mine,duration,stealable) and not (prefix=="debuff" and c.hideLustDebuff and lustDebuffs[id])
            if show and allow and not (prefix=="debuff" and highlighted and id==highlighted) then records[#records+1]={index=i,id=id,icon=icon,stacks=stacks,dtype=dtype,duration=duration or 0,expiry=expiry or 0,mine=mine} end
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
                    local ibs=prefix=="debuff" and dispelPriority[r.dtype] and math.floor(tonumber(c.dispelIconBorderSize) or -1) or -1
                    local edge=ibs>0 and math.min(4,ibs) or math.max(1,tonumber(d.border) or 1)
                    if a._edge~=edge then a:SetBackdrop({edgeFile=white,edgeSize=edge}); a._edge=edge end
                    local color=prefix=="debuff" and ibs~=0 and (ns.DispelColor(c,r.dtype) or DebuffTypeColor and DebuffTypeColor.none) or nil
                    a:SetBackdropBorderColor(color and color.r or 0,color and color.g or 0,color and color.b or 0,(ibs<=0 and d.border==0) and 0 or 1)
                    if d.durationSwipe~=false then a.cooldown:SetCooldown(a.duration>0 and a.expiry-a.duration or 0,a.duration); a.cooldown:Show() else a.cooldown:Hide() end
                    a:Show()
                end
            end
            allocated=allocated+count; if allocated>=#pool then break end
        end
    end
    -- Dispel visuals: any typed debuff, or with Only Show Dispellable the client's RAID
    -- filter, which returns only what this character can remove right now (class,
    -- spec and talents), so no dispel tables are needed.
    b.dispelColorCandidates=nil
    if DispelActive(c) then
        local list={}
        local filter=c.dispelShowAll==false and "HARMFUL|RAID" or "HARMFUL"
        for i=1,40 do
            local name,_,_,_,dtype,_,expiry=UnitAura(unit,i,filter)
            if not name then break end
            if dtype and dispelPriority[dtype] then list[#list+1]={kind=dtype,expiry=expiry or 0} end
        end
        if #list>0 then b.dispelColorCandidates=list end
    end
end
-- Highest priority first; a type whose swatch alpha is 0 is opted out.
local function DispelColorType(b,c)
    local best,rank
    for _,a in ipairs(b.dispelColorCandidates or {}) do
        local r=dispelPriority[a.kind] or 9
        local col=ns.DispelColor(c,a.kind)
        if (a.expiry==0 or a.expiry>GetTime()) and (not rank or r<rank) and not (col and col.a==0) then best,rank=a.kind,r end
    end
    return best
end
local GRADIENT="Interface\\AddOns\\EllesmereUIRaidFrames\\Media\\Textures_335\\dispel-gradient.tga"
local GRADIENT_SHARP="Interface\\AddOns\\EllesmereUIRaidFrames\\Media\\Textures_335\\dispel-gradient-sharp.tga"
-- Retail's type icons are Retail-only atlases; these are the Wrath dispel spells.
local DISPEL_ICONS={Magic="Interface\\Icons\\Spell_Holy_DispelMagic",Curse="Interface\\Icons\\Spell_Nature_RemoveCurse",
    Disease="Interface\\Icons\\Spell_Holy_NullifyDisease",Poison="Interface\\Icons\\Spell_Nature_NullifyPoison"}
local function PaintDispel(b,c,kind,dc)
    local alpha=dc and (dc.a or 1) or 0
    local t,mode=b.dispelOverlay,c.dispelOverlay or "fill"
    if dc and mode~="none" then
        local a=math.max(.05,math.min(1,(tonumber(c.dispelOverlayOpacity) or 100)/100))*alpha
        t:ClearAllPoints()
        if mode=="gradient" or mode=="gradient_sharp" then
            t:SetAllPoints(b.Health); t:SetTexture(mode=="gradient_sharp" and GRADIENT_SHARP or GRADIENT)
        else
            t:SetAllPoints(mode=="fill" and b.Health:GetStatusBarTexture() or b.Health); t:SetTexture(white)
        end
        t:SetVertexColor(dc.r,dc.g,dc.b,a); t:Show()
    else t:Hide() end
    local size=math.max(0,math.min(4,math.floor(tonumber(c.dispelBorderSize) or 0)))
    if dc and size>0 then
        if b._dispelEdge~=size then b.dispelBorder:SetBackdrop({edgeFile=white,edgeSize=size}); b._dispelEdge=size end
        b.dispelBorder:SetBackdropBorderColor(dc.r,dc.g,dc.b,alpha); b.dispelBorder:Show()
    else b.dispelBorder:Hide() end
    if dc and c.showDispelIcons then
        b.dispelIcon:SetTexture(DISPEL_ICONS[kind]); b.dispelIcon:SetAlpha(alpha); b.dispelIcon:Show()
    else b.dispelIcon:Hide() end
end
local function AuraTimers(b)
    for _,list in ipairs({b.buffs,b.debuffs,{b.raidDebuff}}) do for _,a in ipairs(list) do if a:IsShown() then
        local remaining=a.expiry>0 and a.expiry-GetTime() or 0
        if a.expiry>0 and remaining<=0 then a:Hide()
        else Text(a.time,a.indicator and a.indicator.durationText==false and "" or (remaining>60 and math.ceil(remaining/60).."m" or remaining>0 and tostring(math.ceil(remaining)) or "")) end
    end end end
end
local function Small(value)
    if value>=1000000 then return string.format("%.1fm",value/1000000) elseif value>=1000 then return string.format("%.1fk",value/1000) end
    return tostring(math.floor(value))
end
-- UTF-8 aware character cap (Retail Name Max Length; 0 = no cap).
local function Truncate(s,limit)
    limit=tonumber(limit) or 0; if limit<=0 or not s then return s end
    local count,i=0,1
    while i<=#s do
        count=count+1; if count>limit then return s:sub(1,i-1) end
        local byte=s:byte(i); i=i+(byte>=240 and 4 or byte>=224 and 3 or byte>=192 and 2 or 1)
    end
    return s
end
local function Accent() if E.GetAccentColor then return E.GetAccentColor() end return .05,.82,.61 end
local function ModeColor(mode,custom,color)
    if mode=="class" then return color.r,color.g,color.b elseif mode=="accent" then return Accent() end
    custom=custom or {r=1,g=1,b=1}; return custom.r,custom.g,custom.b
end
local function Blend(a,z,t) return a.r+(z.r-a.r)*t,a.g+(z.g-a.g)*t,a.b+(z.b-a.b)*t end
local classicStops={{r=1,g=0,b=0},{r=1,g=1,b=0},{r=0,g=1,b=0}}
-- Retail Health Color modes: class, dark, classic gradient, custom, custom dynamic.
function ns.HealthColor(c,color,hp,maximum)
    local mode=c.healthColorMode or (c.healthClassColored and "class" or "custom")
    if mode=="class" then return color.r,color.g,color.b end
    if mode=="dark" then
        local r,g,b=E.GetDarkModeFill and E.GetDarkModeFill(); if r then return r,g,b end
        return .2,.2,.2
    end
    if mode=="classic" or mode=="customDynamic" then
        local lo,mid,hi=classicStops[1],classicStops[2],classicStops[3]
        if mode=="customDynamic" then lo,mid,hi=c.dynamicColor0 or lo,c.dynamicColor50 or mid,c.dynamicColor100 or hi end
        local pct=math.max(0,math.min(1,hp/math.max(1,maximum)))
        if pct>=.5 then return Blend(mid,hi,(pct-.5)*2) end
        return Blend(lo,mid,pct*2)
    end
    local f=c.customFillColor or {r=.15,g=.8,b=.25}; return f.r,f.g,f.b
end
function ns.BackgroundColor(c,color,dead,offline)
    local s=offline and c.statusColorOffline or dead and c.statusColorDead
    if s then return s.r,s.g,s.b end
    if (c.healthColorMode=="dark") and E.GetDarkModeBg then local r,g,b=E.GetDarkModeBg(); if r then return r,g,b end end
    if c.bgClassColored then local k=1-math.max(0,math.min(100,tonumber(c.bgDarkness) or 50))/100; return color.r*k,color.g*k,color.b*k end
    local bg=c.customBgColor or {r=.08,g=.08,b=.09}; return bg.r,bg.g,bg.b
end
-- Incoming heals come from LibHealComm-4.0 (bundled; Wrath has no native API).
local HealComm,ResComm
function ns.IncomingHeals(guid)
    if not HealComm or not guid then return 0 end
    local amount=HealComm:GetHealAmount(guid,HealComm.ALL_HEALS,GetTime()+4)
    if not amount then return 0 end
    return amount*(HealComm:GetHealModifier(guid) or 1)
end
local function UpdatePrediction(b,c,hp,maximum,guid)
    local t=b.healPred
    if not c.healPrediction then t:Hide(); return end
    local incoming=b._euiPreview and (b._euiPreview%3==1 and maximum*.15 or 0) or ns.IncomingHeals(guid)
    incoming=math.min(incoming,maximum-hp)
    if incoming<=0 then t:Hide(); return end
    local W,H=b._healthW or 1,b._healthH or 1
    t:ClearAllPoints()
    if c.healthVerticalFill then
        t:SetPoint("BOTTOMLEFT",b.Health,"BOTTOMLEFT",0,H*hp/maximum); ns.Size(t,W,math.max(1,H*incoming/maximum))
    else
        t:SetPoint("TOPLEFT",b.Health,"TOPLEFT",W*hp/maximum,0); ns.Size(t,math.max(1,W*incoming/maximum),H)
    end
    local col=c.healPredColor or {r=.4,g=.95,b=.4}
    t:SetVertexColor(col.r,col.g,col.b,math.max(0,math.min(100,tonumber(c.healPredOpacity) or 75))/100); t:Show()
end
-- Shields (Core estimate on 3.3.5, see EllesmereUI_Absorbs_335.lua) from the
-- end of the fill; the part past full health is drawn back over the fill.
local function UpdateAbsorb(b,c,hp,maximum,unit)
    local o=b.absorb; if not o then return end
    local style=c.absorbStyle or "striped"
    local amount=b._euiPreview and (b._euiPreview%3==2 and maximum*.25 or 0) or (unit and E.GetUnitAbsorb(unit) or 0)
    if style=="none" or amount<=0 then E.Absorbs.Hide(o); return end
    local col=c.absorbColor or {r=1,g=1,b=1}
    local overshield=c.overshieldMode or (c.showOvershield==false and "never" or "always")
    E.Absorbs.Paint(o,hp,maximum,amount,style,col.r,col.g,col.b,math.max(5,math.min(100,tonumber(c.absorbOpacity) or 90))/100,
        c.absorbEdgeMode or "overlay",overshield,c.healthVerticalFill,false,b._healthW or 1,b._healthH or 1,textures)
end
function ns.RefreshGUID(guid)
    for _,b in ipairs(ns.buttons) do if b:IsShown() and b._euiGUID==guid then ns.UpdateFrame(b,false) end end
end
function ns.RefreshAbsorb(guid)
    for _,b in ipairs(ns.buttons) do
        if b.absorb and b._euiGUID==guid and b.unit and b:IsShown() then
            local c=ns.GetSettings(b._euiKind)
            if c then UpdateAbsorb(b,c,b._euiHP or 0,b._euiMax or 1,b.unit) end
        end
    end
end
function ns.InitPrediction()
    if ns._predictionReady then return end; ns._predictionReady=true
    local stub=_G.LibStub
    HealComm=stub and stub("LibHealComm-4.0",true); ResComm=stub and stub("LibResComm-1.0",true)
    ns.HealComm,ns.ResComm=HealComm,ResComm
    if E.RegisterAbsorbCallback then E.RegisterAbsorbCallback(ns,ns.RefreshAbsorb) end
    if HealComm and HealComm.RegisterCallback then
        local function Targets(...) for i=1,select("#",...) do ns.RefreshGUID((select(i,...))) end end
        local function Cast(_,_,_,_,_,...) Targets(...) end
        for _,event in ipairs({"HealComm_HealStarted","HealComm_HealUpdated","HealComm_HealDelayed","HealComm_HealStopped"}) do HealComm.RegisterCallback(ns,event,Cast) end
        HealComm.RegisterCallback(ns,"HealComm_ModifierChanged",function(_,guid) ns.RefreshGUID(guid) end)
        HealComm.RegisterCallback(ns,"HealComm_GUIDDisappeared",function(_,guid) ns.RefreshGUID(guid) end)
    end
    if ResComm and ResComm.RegisterCallback then
        for _,event in ipairs({"ResComm_ResStart","ResComm_ResEnd","ResComm_Ressed","ResComm_ResExpired"}) do ResComm.RegisterCallback(ns,event,function() ns.UpdateAll(false) end) end
    end
end
local previewClasses={"WARRIOR","PRIEST","DRUID","PALADIN","MAGE","HUNTER","SHAMAN","ROGUE","WARLOCK","DEATHKNIGHT"}
local function Indicators(b,c,base,unit,connected,status)
    local preview=b._euiPreview; local combat=ns.InCombat()
    local role
    if preview then role=b._euiNoRole and nil or preview%5==1 and "tank" or preview%5==2 and "healer" or "dps"
    else role=ns.UnitRole(base or unit) end
    local showRole=c.showRole and role and not (c.roleIconHideInCombat and combat)
        and (role=="tank" and c.showRoleForTank~=false or role=="healer" and c.showRoleForHealer~=false or role=="dps" and not c.hideDpsRoleIcons)
    if showRole then ns.SetRoleTexture(b.role,role,c.roleIconStyle); b.role:Show() else b.role:Hide() end
    local leader=preview and preview==1 or base and UnitIsPartyLeader(base)
    local raidIndex=base and tonumber(base:match("^raid(%d+)$"))
    if raidIndex then leader=select(2,GetRaidRosterInfo(raidIndex))==2 end
    if c.showLeader and leader and (c.showLeaderIconInCombat~=false or not combat) then b.leader:Show() else b.leader:Hide() end
    local marker=not preview and GetRaidTargetIndex(base or unit)
    if c.showRaidMarker and marker then SetRaidTargetIconTexture(b.raidMarker,marker); b.raidMarker:Show() else b.raidMarker:Hide() end
    local ready
    if not preview and ns.readyUntil and GetTime()<ns.readyUntil then
        local token=base or unit; local guid=UnitGUID(token)
        local results=ns.readyResults or {}; ns.readyResults=results
        ready=guid and results[guid]
        if not ns.readyFinished then
            local live=GetReadyCheckStatus(token)
            if live=="ready" or live=="notready" then ready=live
            elseif not ready and (live=="waiting" or token=="player" or token:match("^party%d+$") or token:match("^raid%d+$")) then ready=connected and "waiting" or "notready" end
            if guid and ready then results[guid]=ready end
        end
    end
    if c.showReadyCheck and ready then b.ready:SetTexture("Interface\\RaidFrame\\UI-ReadyCheck-"..(ready=="ready" and "Ready" or ready=="notready" and "NotReady" or "Waiting")); b.ready:Show() else b.ready:Hide() end
    local inCombat=preview and preview%4==3 or not preview and UnitAffectingCombat and UnitAffectingCombat(base or unit)
    if c.showCombatIndicator and connected and inCombat then b.combat:Show() else b.combat:Hide() end
    local dead=not preview and (status=="Dead" or status=="Ghost")
    local rezzing=dead and ResComm and ResComm:IsUnitBeingRessed(UnitName(base or unit) or "")
    if c.showIncomingRez~=false and rezzing and not b.ready:IsShown() then b.rez:Show() else b.rez:Hide() end
end
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
        b._euiGUID=nil; b.dispelColorCandidates=nil; b.dispelBorder:Hide(); b.dispelIcon:Hide(); b.Health:SetValue(0); b.Power:SetValue(0); Text(b.name,""); Text(b.healthText,""); Text(b.powerText,""); Text(b.status,""); ClearAuras(b)
        for _,t in ipairs({b.role,b.leader,b.raidMarker,b.ready,b.combat,b.rez,b.healPred,b.dispelOverlay}) do t:Hide() end; b:SetAlpha(1)
        if b.absorb then E.Absorbs.Hide(b.absorb) end
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
    local status=not connected and "Offline" or not b._euiPreview and (UnitIsGhost(unit) and "Ghost" or UnitIsDead(unit) and "Dead" or c.statusShowAFK~=false and UnitIsAFK(unit) and "AFK") or ""
    local baseR,baseG,baseB=.35,.35,.35
    if connected then baseR,baseG,baseB=ns.HealthColor(c,color,hp,maximum) end
    b.Health:SetStatusBarColor(baseR,baseG,baseB)
    b.Health.bg:SetVertexColor(ns.BackgroundColor(c,color,status=="Dead" or status=="Ghost",not connected))
    UpdatePrediction(b,c,hp,maximum,not b._euiPreview and guid)
    b._euiHP,b._euiMax=hp,maximum
    UpdateAbsorb(b,c,hp,maximum,not b._euiPreview and unit)
    Text(b.name,Truncate(b._euiPreviewName or (b._euiPreview and ("Player "..b._euiPreview)) or (UnitName(base or unit) or ""),c.nameMaxLength))
    b.name:SetTextColor(ModeColor(c.nameColorMode or (c.classColoredNames and "class" or "custom"),c.nameCustomColor,color))
    Text(b.status,status)
    local health=c.healthDisplay=="percent" and math.floor(hp/maximum*100+.5).."%" or c.healthDisplay=="current" and Small(hp) or c.healthDisplay=="missing" and (hp<maximum and ("-"..Small(maximum-hp)) or "") or c.healthDisplay=="both" and (Small(hp).." / "..Small(maximum)) or ""
    Text(b.healthText,status~="" and "" or health)
    b.healthText:SetTextColor(ModeColor(c.healthTextColorMode or "custom",c.healthTextCustomColor,color))
    local powerType,token=0,"MANA"; if not b._euiPreview then powerType,token=UnitPowerType(unit) end
    local power=b._euiPreview and 65 or (UnitPower(unit,powerType) or 0); local maxPower=b._euiPreview and 100 or (UnitPowerMax(unit,powerType) or 0)
    b.Power:SetMinMaxValues(0,math.max(1,maxPower)); b.Power:SetValue(power)
    local pc=PowerBarColor and (PowerBarColor[token] or PowerBarColor[powerType]) or {r=.1,g=.4,b=1}; b.Power:SetStatusBarColor(pc.r,pc.g,pc.b)
    Text(b.powerText,c.showPowerText and status=="" and maxPower>0 and math.floor(power/maxPower*100+.5).."%" or "")
    if auras then if b._euiPreview then ClearAuras(b) else ns.UpdateAuras(b,unit,c) end end
    AuraTimers(b)
    -- Highest-priority dispellable type: overlay, health-bar border, type icon
    -- and (Color Custom Borders) the frame border, as Retail's DISPELS section.
    local kind=connected and DispelActive(c) and DispelColorType(b,c) or nil
    if b._euiPreview and connected and not kind and DispelActive(c) and b._euiPreview%3==0 then
        kind=({"Magic","Curse","Disease","Poison"})[(b._euiPreview/3-1)%4+1]
    end
    local dc=kind and ns.DispelColor(c,kind)
    if dc and dc.a==0 then dc=nil end
    b.dispelType=dc and kind or nil; b.dispelColorType=b.dispelType
    PaintDispel(b,c,kind,dc)
    local threat=not b._euiPreview and UnitThreatSituation(base or unit)
    local dispel=c.dispelHighlight and dc
    local border=c.showThreat and threat and threat>=2 and (c.threatBorderColor or {r=1,g=.15,b=.15})
        or dispel or c.showTargetBorder and base and UnitIsUnit(base,"target") and (c.targetBorderColor or {r=.05,g=.82,b=.61}) or c.borderColor or {r=0,g=0,b=0}
    b:SetBackdropBorderColor(border.r,border.g,border.b,(tonumber(c.borderSize) or 1)>0 and 1 or 0)
    local range,checked=true,false
    if c.rangeFade and connected and not b._euiPreview and not UnitIsUnit(base or unit,"player") and UnitInRange then
        range,checked=UnitInRange(base or unit)
        -- Wrath returns only inRange (nil means out of range). Newer clients
        -- may supply checkedRange; respect an explicit unavailable result.
        if checked==nil then checked=b._euiKind=="raid" or b._euiKind=="party" or range~=nil end
    end
    local opacity=math.max(.1,math.min(1,tonumber(c.outOfRangeAlpha) or .4))
    b:SetAlpha(checked and (not range or range==0) and opacity or 1)
    Indicators(b,c,base,unit,connected,status)
end
-- Unit tooltip follows Tooltip Mode; aura icon tooltips keep their own toggle.
function ns.UnitTooltipAllowed(c)
    local mode=c.tooltipMode or "outOfCombat"
    if mode=="never" then return false end
    if mode=="outOfCombat" and ns.InCombat() then return false end
    return true
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
    local allowUnit=ns.UnitTooltipAllowed(c)
    if hovered then key=key..":"..hovered.filter..":"..hovered.index elseif not allowUnit then key="none" end
    if ns.tooltipKey==key then return end; ns.tooltipKey=key
    if not hovered and not allowUnit then GameTooltip:Hide(); return end
    GameTooltip:SetOwner(b,"ANCHOR_RIGHT")
    if hovered then
        if hovered.filter=="HELPFUL" then GameTooltip:SetUnitBuff(hovered.unit,hovered.index)
        else GameTooltip:SetUnitDebuff(hovered.unit,hovered.index,c.onlyDispellable and "RAID" or nil) end
    else GameTooltip:SetUnit(b.unit) end
    GameTooltip:Show()
end
