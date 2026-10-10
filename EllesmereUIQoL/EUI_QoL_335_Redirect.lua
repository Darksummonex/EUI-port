-- Misdirection / Tricks of the Trade helper. A secure macro button (click it or
-- bind it) casts on the focus, else the tank (typed name, raid Main Tank, then
-- the Dungeon Finder tank role), else a friendly target, else the hunter's pet.
-- The macro conditionals pick the unit at click time, so a focus set in combat
-- still works; the tank name, visibility and position only change out of combat.
-- The icon shows who the cast would land on now, the cooldown and the buff timer.
local _,ns=...
local E=EllesmereUI
if not ns.addon then return end
ns.defaults.profile.redirect={enabled=false,useFocus=true,tankName="",size=36,showName=true}
ns.REDIRECT_SPELLS={HUNTER=34477,ROGUE=57934}
local _,class=UnitClass("player")
local BUTTON="EUI335QoLRedirect"
BINDING_HEADER_EUI335_QOL="EllesmereUI Quality of Life"
_G["BINDING_NAME_CLICK "..BUTTON..":LeftButton"]="Misdirection / Tricks of the Trade Helper"
local button,pending

local function Settings() local p=ns.GetSettings(); return p and p.redirect end
local function SpellID() return ns.REDIRECT_SPELLS[class] end
function ns.RedirectActive()
    local p=ns.GetSettings(); local r=p and p.redirect; local id=SpellID()
    return (p and p.enabled and r and r.enabled and id and ns.KnownSpell and ns.KnownSpell(id)) and true or false
end
local function GroupUnits()
    local units,raid={},GetNumRaidMembers()
    if raid>0 then for i=1,raid do units[#units+1]="raid"..i end
    else for i=1,GetNumPartyMembers() do units[#units+1]="party"..i end end
    return units
end
function ns.RedirectTank()
    local r=Settings() or {}
    local me=UnitName("player")
    local units=GroupUnits()
    local wanted=(tostring(r.tankName or ""):match("^%s*(.-)%s*$") or ""):lower()
    if wanted~="" then
        for _,u in ipairs(units) do local name=UnitName(u); if name and name:lower()==wanted then return name end end
    end
    for i=1,GetNumRaidMembers() do
        local name,_,_,_,_,_,_,_,_,role=GetRaidRosterInfo(i)
        if name and name~=me and role=="MAINTANK" then return name end
    end
    if UnitGroupRolesAssigned then
        for _,u in ipairs(units) do
            local tank=UnitGroupRolesAssigned(u)
            if tank==true or tank=="TANK" then local name=UnitName(u); if name and name~=me then return name end end
        end
    end
end
function ns.RedirectMacro(spell,tank,useFocus,pet)
    local conds={}
    if useFocus then conds[#conds+1]="[target=focus,help,nodead]" end
    if tank then conds[#conds+1]="[target="..tank..",help,nodead]" end
    conds[#conds+1]="[help,nodead]"
    if pet then conds[#conds+1]="[target=pet,exists,nodead]" end
    for i,c in ipairs(conds) do conds[i]=c.." "..spell end
    return "/cast "..table.concat(conds,"; ")
end
local function Usable(unit) return UnitExists(unit) and UnitCanAssist("player",unit) and not UnitIsDeadOrGhost(unit) and not UnitIsUnit(unit,"player") end
function ns.RedirectWho(tank)
    local r=Settings() or {}
    if r.useFocus~=false and Usable("focus") then return "focus" end
    if tank and Usable(tank) then return tank end
    if Usable("target") then return "target" end
    if class=="HUNTER" and UnitExists("pet") and not UnitIsDead("pet") then return "pet" end
end

local function Build()
    if button then return button end
    local b=CreateFrame("Button",BUTTON,UIParent,"SecureActionButtonTemplate"); button=b; ns.redirectButton=b
    b:SetFrameStrata("MEDIUM"); b:RegisterForClicks("AnyUp"); b:SetAttribute("type","macro"); b:Hide()
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    b:SetBackdropColor(0,0,0,.6); b:SetBackdropBorderColor(0,0,0,1)
    b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetPoint("TOPLEFT",b,"TOPLEFT",1,-1); b.icon:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-1,1)
    b.icon:SetTexCoord(.08,.92,.08,.92)
    b.cooldown=CreateFrame("Cooldown",nil,b,"CooldownFrameTemplate"); b.cooldown:SetAllPoints(b.icon)
    local text=CreateFrame("Frame",nil,b); text:SetAllPoints(b); text:SetFrameLevel(b.cooldown:GetFrameLevel()+2)
    b.timer=text:CreateFontString(nil,"OVERLAY"); b.timer:SetPoint("CENTER",b,"CENTER",0,0)
    b.name=text:CreateFontString(nil,"OVERLAY"); b.name:SetPoint("TOP",b,"BOTTOM",0,-2)
    b:SetScript("OnEnter",function(self)
        if not GameTooltip or not self.spell then return end
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(self.spell,1,1,1)
        local who=ns.RedirectWho(self.tank)
        GameTooltip:AddLine("Casts on: "..(who and UnitName(who) or "nobody right now"),.8,.8,.8)
        GameTooltip:AddLine("Order: focus, "..(self.tank and self.tank.." (tank)" or "tank").. ", friendly target"..(class=="HUNTER" and ", pet" or ""),.6,.6,.6,true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    local clock=0
    b:SetScript("OnUpdate",function(_,dt) clock=clock+(dt or 0); if clock>=.1 then clock=0; ns.UpdateRedirect() end end)
    return b
end
function ns.UpdateRedirect()
    local b=button; if not b or not b:IsShown() or not b.spell then return end
    local r=Settings() or {}
    local who=ns.RedirectWho(b.tank)
    if r.showName==false then b.name:SetText("")
    elseif who then
        local _,cls=UnitClass(who); local c=cls and RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls]
        b.name:SetText(UnitName(who) or ""); if c then b.name:SetTextColor(c.r,c.g,c.b) else b.name:SetTextColor(1,1,1) end
    else b.name:SetText("No target"); b.name:SetTextColor(.6,.6,.6) end
    if b.icon.SetDesaturated then b.icon:SetDesaturated(not who) end
    local name,_,_,_,_,_,expires=UnitBuff("player",b.spell)
    b.timer:SetText(name and expires and expires>0 and string.format("%.0f",math.max(0,expires-GetTime())) or "")
    local start,duration=GetSpellCooldown(b.spell)
    if not (start and duration and duration>1.5) then start,duration=0,0 end
    if start~=b.cdStart or duration~=b.cdDuration then b.cdStart,b.cdDuration=start,duration; b.cooldown:SetCooldown(start,duration) end
end
function ns.ApplyRedirect()
    if InCombatLockdown() then pending=true; return end
    pending=false
    local on=ns.RedirectActive()
    if not on and not button then return end
    local b=Build(); local p=ns.GetSettings(); local r=Settings()
    local size=math.max(20,math.min(64,tonumber(r.size) or 36)); ns.Size(b,size,size)
    local pos=p.positions.redirect
    b:ClearAllPoints()
    if pos then b:SetPoint(pos.point,UIParent,pos.relPoint,pos.x,pos.y) else b:SetPoint("CENTER",UIParent,"CENTER",0,-180) end
    ns.Font(b.timer,math.floor(size*.45)); ns.Font(b.name,11)
    if not on then b:SetAttribute("macrotext",nil); b.spell=nil; b:Hide(); return end
    local spell,_,icon=GetSpellInfo(SpellID())
    b.spell=spell; b.icon:SetTexture(icon); b.tank=ns.RedirectTank()
    b:SetAttribute("macrotext",ns.RedirectMacro(spell,b.tank,r.useFocus~=false,class=="HUNTER"))
    b:Show(); ns.UpdateRedirect()
end
function ns.Redirect_UnlockElement()
    if not SpellID() or not E.MakeUnlockElement then return end
    Build()
    return E.MakeUnlockElement({key="EUI_Redirect",label="Misdirection / Tricks Helper",group="Quality of Life",order=925,noResize=true,noAnchorTo=true,
        getFrame=function() return button end,getSize=function() return button:GetWidth(),button:GetHeight() end,
        isHidden=function() return not button:IsShown() end,
        savePos=function(_,point,relPoint,x,y) local p=ns.GetSettings(); if p then p.positions.redirect={point=point,relPoint=relPoint,x=x,y=y} end end,
        loadPos=function() local p=ns.GetSettings(); return p and p.positions.redirect end,
        clearPos=function() local p=ns.GetSettings(); if p then p.positions.redirect=nil; ns.Apply() end end,applyPos=ns.Apply})
end
local events=CreateFrame("Frame"); ns.redirectEvents=events
for _,event in ipairs({"PLAYER_ENTERING_WORLD","RAID_ROSTER_UPDATE","PARTY_MEMBERS_CHANGED","PLAYER_REGEN_ENABLED","SPELLS_CHANGED","LEARNED_SPELL_IN_TAB","PLAYER_ROLES_ASSIGNED"}) do
    pcall(events.RegisterEvent,events,event)
end
events:SetScript("OnEvent",function(_,event)
    if event=="PLAYER_REGEN_ENABLED" and not pending then return end
    if ns.GetSettings() then ns.ApplyRedirect() end
end)
