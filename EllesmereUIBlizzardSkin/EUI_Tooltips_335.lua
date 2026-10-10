-- Unit tooltip information, placement and visibility for the native GameTooltip.
-- Content is only appended to lines the client and server already built.
local ADDON_NAME,ns=...
if not ns.IsWrath then return end
local E=EllesmereUI
local Items=ns.Items
for key,value in pairs({tooltipPlayerTitles=false,tooltipItemLevel=true,tooltipShowGearScore=true,tooltipShowMount=false,tooltipShowGuildRank=false,
    tooltipShowTarget=false,tooltipShowMode="always",tooltipShowModifier="none",tooltipGrowthDirection="auto",
    uberTooltips=true,uberTooltipsManual=false,tooltipHideHealthStrip=true,tooltipAnchorCursor=false,
    tooltipCursorPosition="top",tooltipCursorOffsetX=0,tooltipCursorOffsetY=0,
    tooltipShowBuffs=false,tooltipBuffSize=20,tooltipBuffsPerRow=8,tooltipBuffPosition="bottom",tooltipBuffOffsetX=0,tooltipBuffOffsetY=0}) do ns.defaults[key]=value end
local T={}; ns.Tooltips=T
table.insert(ns.extras,T)
local function On(key) return ns.GetValue(key) and ns.GetValue("customTooltips")~=false end
local function Line(i) return _G["GameTooltipTextLeft"..i] end
local function HasLine(tip,prefix)
    for i=2,tip:NumLines() do local fs=Line(i); local text=fs and fs:GetText(); if text and text:find(prefix,1,true)==1 then return true end end
end
local function Hex(r,g,b) return string.format("|cff%02x%02x%02x",math.floor((r or 1)*255),math.floor((g or 1)*255),math.floor((b or 1)*255)) end
local function UnitHex(unit)
    if UnitIsPlayer(unit) then local r,g,b=ns.ClassColor(unit); if r then return Hex(r,g,b) end end
    local reaction=UnitReaction(unit,"player")
    local c=reaction and FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction]
    return c and Hex(c.r,c.g,c.b) or "|cffffffff"
end
-- Mounts: the server's journal maps a summon spell to its mount and whether
-- this account has collected it; the companion list is the fallback.
local mountSpells
local function MountSpells()
    if mountSpells then return mountSpells end
    mountSpells={}
    local journal=_G.C_MountJournal
    if journal and journal.GetMountIDs and journal.GetMountInfoByID then
        for _,id in ipairs(journal.GetMountIDs() or {}) do
            local name,spell,icon=journal.GetMountInfoByID(id)
            if spell then mountSpells[spell]={id=id,name=name,icon=icon} end
        end
    end
    if GetNumCompanions and GetCompanionInfo then
        for i=1,GetNumCompanions("MOUNT") do
            local _,name,spell,icon=GetCompanionInfo("MOUNT",i)
            if spell and not mountSpells[spell] then mountSpells[spell]={name=name,icon=icon,known=true} end
        end
    end
    return mountSpells
end
function T.InvalidateMounts() mountSpells=nil end
local function MountLine(unit)
    local map=MountSpells()
    for i=1,40 do
        local name,_,icon,_,_,_,_,_,_,_,spell=UnitAura(unit,i,"HELPFUL")
        if not name then return end
        local mount=spell and map[spell]
        if mount then
            local text="Mount: |T"..(mount.icon or icon)..":14:14:0:0|t "..(mount.name or name)
            local collected=mount.known
            if mount.id and C_MountJournal then collected=select(11,C_MountJournal.GetMountInfoByID(mount.id)) end
            if collected~=nil then text=text..(collected and " |cff33ff33(Collected)|r" or " |cffff5555(Not collected)|r") end
            return text
        end
    end
end
-- Inspect item level and GearScore: one paced request for the hovered player, cached per GUID.
local inspectCache,pending,lastInspect,ownRequest={},nil,0,false
local INSPECT_GAP,INSPECT_REST,CACHE_TIME=1.5,.25,300
local function ItemLevelText(avg) return string.format("Item Level: |cffffffff%.1f|r",avg) end
-- GearScoreLite prints its own player line when its Player option is on.
local function ExternalGearScore()
    return type(_G.GearScore_HookSetUnit)=="function" and type(_G.GS_Settings)=="table" and GS_Settings.Player==1
end
local function WantLevel() return On("tooltipItemLevel") end
local function WantScore() return On("tooltipShowGearScore") and ns.GearScore and not ExternalGearScore() end
local function AddGear(tip,avg,score)
    if WantLevel() and avg and avg>0 and not HasLine(tip,"Item Level:") then tip:AddLine(ItemLevelText(avg),1,.82,0) end
    if WantScore() and score and score>0 and not HasLine(tip,"GearScore:") then
        local r,g,b=ns.GearScoreColor(score)
        tip:AddLine("GearScore: "..Hex(r,g,b)..score.."|r",1,.82,0)
    end
end
local function AddItemLevel(tip,unit)
    if not (WantLevel() or WantScore()) or not UnitIsPlayer(unit) or not tip:GetUnit() then return end
    local guid=UnitGUID(unit)
    if UnitIsUnit(unit,"player") then
        local avg,unknown=Items.Average("player")
        if not unknown then AddGear(tip,avg,WantScore() and ns.GearScore("player")) end
        return
    end
    local cached=guid and inspectCache[guid]
    if cached and GetTime()-cached.time<CACHE_TIME then AddGear(tip,cached.avg,cached.score); return end
    if CanInspect and CanInspect(unit) and CheckInteractDistance(unit,1) then
        pending={guid=guid,unit=unit,since=GetTime(),tries=0}
    end
end
-- Hovered player's buffs as icons beside the tooltip (Retail tooltipShowBuffs):
-- up to 16, parented to GameTooltip so they hide with it.
local MAX_BUFFS=16
-- position = { container point, tooltip point, x step sign, y step sign, x, y }
local BUFF_POS={
    bottom={"TOPLEFT","BOTTOMLEFT",1,-1,0,-2},
    top={"BOTTOMLEFT","TOPLEFT",1,1,0,2},
    left={"TOPRIGHT","TOPLEFT",-1,-1,-2,0},
    right={"TOPLEFT","TOPRIGHT",1,-1,2,0},
}
T.BUFF_POS=BUFF_POS
local buffBox
local function BuffBox(tip)
    if buffBox then return buffBox end
    buffBox=CreateFrame("Frame",nil,tip); buffBox:Hide(); buffBox.icons={}
    for i=1,MAX_BUFFS do
        local b=CreateFrame("Frame",nil,buffBox)
        b.bg=b:CreateTexture(nil,"BACKGROUND"); b.bg:SetTexture("Interface\\Buttons\\WHITE8X8"); b.bg:SetVertexColor(0,0,0,1); b.bg:SetAllPoints(b)
        b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetPoint("TOPLEFT",b,"TOPLEFT",1,-1); b.icon:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-1,1); b.icon:SetTexCoord(.08,.92,.08,.92)
        b.count=b:CreateFontString(nil,"OVERLAY","NumberFontNormalSmall"); b.count:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",0,1)
        b:Hide(); buffBox.icons[i]=b
    end
    tip:HookScript("OnTooltipCleared",function() buffBox:Hide() end)
    T.buffBox=buffBox
    return buffBox
end
function T.ShowBuffs(tip,unit)
    if not (On("tooltipShowBuffs") and unit and UnitIsPlayer(unit)) then if buffBox then buffBox:Hide() end; return end
    local box=BuffBox(tip)
    local size=math.max(10,math.min(40,tonumber(ns.GetValue("tooltipBuffSize")) or 20))
    local perRow=math.max(1,math.min(16,tonumber(ns.GetValue("tooltipBuffsPerRow")) or 8))
    local p=BUFF_POS[ns.GetValue("tooltipBuffPosition")] or BUFF_POS.bottom
    local n=0
    for i=1,40 do
        if n>=MAX_BUFFS then break end
        local name,_,icon,count=UnitAura(unit,i,"HELPFUL")
        if not name then break end
        n=n+1
        local b=box.icons[n]
        b:SetWidth(size); b:SetHeight(size); b:ClearAllPoints()
        local col,row=(n-1)%perRow,math.floor((n-1)/perRow)
        b:SetPoint(p[1],box,p[1],p[3]*col*(size+2),p[4]*row*(size+2))
        b.icon:SetTexture(icon); b.count:SetText((count or 0)>1 and count or ""); b:Show()
    end
    for i=n+1,MAX_BUFFS do box.icons[i]:Hide() end
    if n==0 then box:Hide(); return end
    local cols=math.min(n,perRow); local rows=math.ceil(n/perRow)
    box:SetWidth(cols*(size+2)-2); box:SetHeight(rows*(size+2)-2)
    box:ClearAllPoints(); box:SetPoint(p[1],tip,p[2],p[5]+(tonumber(ns.GetValue("tooltipBuffOffsetX")) or 0),p[6]+(tonumber(ns.GetValue("tooltipBuffOffsetY")) or 0))
    box:Show()
end
local function AddUnitInfo(tip)
    if ns.GetValue("customTooltips")==false then return end
    local _,unit=tip:GetUnit()
    if not unit or not UnitExists(unit) then return end
    local first=Line(1)
    if UnitIsPlayer(unit) then
        local name,realm=UnitName(unit)
        local pvpName=UnitPVPName and UnitPVPName(unit)
        local text=first and first:GetText()
        -- Only a genuinely present title is removed; other line-1 formatting stays.
        if not ns.GetValue("tooltipPlayerTitles") and name and pvpName and pvpName~=name and text and text:find(pvpName,1,true) then
            first:SetText((text:gsub(pvpName:gsub("%p","%%%0"),name,1)))
        end
        local r,g,b=ns.ClassColor(unit)
        if r and first then first:SetTextColor(r,g,b) end
        if On("tooltipShowGuildRank") and GetGuildInfo then
            local guild,rank=GetGuildInfo(unit)
            if guild and rank then
                for i=2,tip:NumLines() do
                    local fs=Line(i); local line=fs and fs:GetText()
                    if line==guild or line=="<"..guild..">" then fs:SetText(line.." |cff999999- "..rank.."|r"); break end
                end
            end
        end
        if On("tooltipShowMount") and not HasLine(tip,"Mount:") then
            local mount=MountLine(unit); if mount then tip:AddLine(mount,1,.82,0) end
        end
        AddItemLevel(tip,unit)
    end
    T.ShowBuffs(tip,unit)
    if On("tooltipShowTarget") and UnitExists(unit.."target") and not HasLine(tip,"Targeting:") then
        local target=unit.."target"
        local who=UnitIsUnit(target,"player") and "|cffff3333>> YOU <<|r" or UnitHex(target)..(UnitName(target) or "").."|r"
        tip:AddLine("Targeting: "..who,1,.82,0)
    end
    tip:Show()
end
local function ColorHealth(bar)
    if ns.GetValue("customTooltips")==false then return end
    local _,unit=GameTooltip:GetUnit()
    if unit and UnitIsPlayer(unit) then local r,g,b=ns.ClassColor(unit); if r then bar:SetStatusBarColor(r,g,b) end end
end
-- Placement.
local POINT_FOR_POS={top="BOTTOM",bottom="TOP",left="RIGHT",right="LEFT"}
local fixedFrame
local function FixedPos()
    local p=E.GetActiveProfileData and E.GetActiveProfileData()
    return p and p.tooltipFixedPos
end
local function EnsureFixedFrame()
    if fixedFrame then return fixedFrame end
    fixedFrame=CreateFrame("Frame","EUI335TooltipFixedAnchor",UIParent)
    fixedFrame:SetWidth(280); fixedFrame:SetHeight(165); fixedFrame:EnableMouse(false)
    ns.owned[fixedFrame]=true
    return fixedFrame
end
function T.PositionFixed()
    local f=EnsureFixedFrame(); local pos=FixedPos()
    f:ClearAllPoints()
    if pos then f:SetPoint(pos.point or "CENTER",UIParent,pos.relPoint or pos.point or "CENTER",pos.x or 0,pos.y or 0)
    else f:SetPoint("BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",-(CONTAINER_OFFSET_X or 0)-13,CONTAINER_OFFSET_Y or 70) end
end
local function Corner(f)
    local l,b=f:GetLeft(),f:GetBottom()
    local cx=l and l+f:GetWidth()/2-UIParent:GetWidth()/2 or 1
    local cy=b and b+f:GetHeight()/2-UIParent:GetHeight()/2 or -1
    local dir=ns.GetValue("tooltipGrowthDirection")
    local vert=dir=="down" and "TOP" or dir=="up" and "BOTTOM" or (cy<0 and "BOTTOM" or "TOP")
    return vert..(cx<0 and "LEFT" or "RIGHT")
end
local function FollowCursor(tip)
    local scale=UIParent:GetEffectiveScale(); if not scale or scale<=0 then return end
    local x,y=GetCursorPosition()
    tip:ClearAllPoints()
    tip:SetPoint(POINT_FOR_POS[ns.GetValue("tooltipCursorPosition")] or "BOTTOM",UIParent,"BOTTOMLEFT",
        x/scale+(tonumber(ns.GetValue("tooltipCursorOffsetX")) or 0),y/scale+(tonumber(ns.GetValue("tooltipCursorOffsetY")) or 0))
end
local function DefaultAnchor(tip)
    if tip~=GameTooltip or ns.GetValue("customTooltips")==false then return end
    tip.euiCursor=nil
    if ns.GetValue("tooltipAnchorCursor") then tip.euiCursor=true; FollowCursor(tip); return end
    if FixedPos() then
        local f=EnsureFixedFrame(); local corner=Corner(f)
        tip:ClearAllPoints(); tip:SetPoint(corner,f,corner,0,0)
    end
end
-- Visibility: a suppressed tooltip stays shown inside a hidden host, so the
-- peek modifier only has to move it back.
local host,nativeParent
local parked={}
local function ModifierHeld()
    local mod=ns.GetValue("tooltipShowModifier")
    if mod=="control" then return IsControlKeyDown() elseif mod=="alt" then return IsAltKeyDown()
    elseif mod=="shift" then return IsShiftKeyDown() end
    return false
end
function T.Suppressed()
    if ns.GetValue("customTooltips")==false then return false end
    local mode=ns.GetValue("tooltipShowMode")
    if mode=="always" or ModifierHeld() then return false end
    if mode=="never" then return true end
    local fighting=InCombatLockdown() or UnitAffectingCombat("player")
    if mode=="outOfCombat" then return fighting and true or false end
    if mode=="outOfBossCombat" then return fighting and UnitExists("boss1") and true or false end
    return false
end
function T.UpdateVisibility()
    if not host then return end
    local hide=T.Suppressed()
    for _,name in ipairs({"GameTooltip","ShoppingTooltip1","ShoppingTooltip2","ShoppingTooltip3"}) do
        local tip=_G[name]
        if tip then
            if hide and tip:GetParent()~=host then parked[tip]=tip:GetParent() or nativeParent; tip:SetParent(host)
            elseif not hide and parked[tip] then tip:SetParent(parked[tip]); parked[tip]=nil; tip:SetFrameStrata("TOOLTIP") end
        end
    end
end
function T.ApplyHealthStrip()
    local bar=_G.GameTooltipStatusBar; if not bar then return end
    bar:SetAlpha(ns.GetValue("customTooltips")~=false and ns.GetValue("tooltipHideHealthStrip") and 0 or 1)
end
function T.Apply()
    T.ApplyHealthStrip(); T.UpdateVisibility()
    -- ns.Apply runs this on every skin refresh; in Unlock Mode the mover owns the anchor.
    if not E._unlockActive then T.PositionFixed() end
    if ns.GetValue("uberTooltipsManual") and SetCVar then
        local v=ns.GetValue("uberTooltips") and "1" or "0"
        if E.SetCVar then E.SetCVar("UberTooltips",v,"EllesmereUIBlizzardSkin") else SetCVar("UberTooltips",v) end
    end
end
local function InspectTick()
    if not pending then return end
    local now=GetTime()
    local unit=pending.unit
    if UnitGUID(unit)~=pending.guid then pending=nil; return end
    if pending.requested then
        if now-pending.requested>4 then pending=nil end
        return
    end
    if now-pending.since<INSPECT_REST or now-lastInspect<INSPECT_GAP then return end
    if _G.InspectFrame and InspectFrame:IsShown() then pending=nil; return end
    ownRequest=true; pending.requested=now; NotifyInspect(unit); ownRequest=false
end
local function InspectReady()
    if not pending or not pending.requested then return end
    local unit=pending.unit
    if UnitGUID(unit)~=pending.guid then pending=nil; return end
    local avg,unknown=Items.Average(unit)
    if unknown and pending.tries<10 then pending.tries=pending.tries+1; pending.retryAt=GetTime()+.3; return end
    local score=ns.GearScore and ns.GearScore(unit)
    inspectCache[pending.guid]={avg=avg,score=score,time=GetTime()}
    pending=nil
    local _,shown=GameTooltip:GetUnit()
    if shown and UnitGUID(shown)==UnitGUID(unit) then
        local lines=GameTooltip:NumLines()
        AddGear(GameTooltip,avg,score)
        if GameTooltip:NumLines()~=lines then GameTooltip:Show(); ns.RequestRefresh() end
    end
end
function T.Enable()
    local tip=_G.GameTooltip; if not tip or T.enabled then return end
    T.enabled=true
    nativeParent=tip:GetParent() or UIParent
    host=CreateFrame("Frame",nil,UIParent); host:Hide(); ns.owned[host]=true
    tip:HookScript("OnTooltipSetUnit",AddUnitInfo)
    tip:HookScript("OnShow",T.UpdateVisibility)
    tip:HookScript("OnHide",function(self) self.euiCursor=nil end)
    tip:HookScript("OnUpdate",function(self)
        if not self.euiCursor then return end
        if ns.GetValue("customTooltips")==false or not ns.GetValue("tooltipAnchorCursor") then self.euiCursor=nil; return end
        local _,unit=self:GetUnit()
        if unit=="mouseover" and not UnitExists("mouseover") then self:Hide(); return end
        FollowCursor(self)
    end)
    if tip.FadeOut then
        hooksecurefunc(tip,"FadeOut",function(self) if self.euiCursor then self:Hide() end end)
    end
    if type(_G.GameTooltip_SetDefaultAnchor)=="function" then hooksecurefunc("GameTooltip_SetDefaultAnchor",DefaultAnchor) end
    if type(_G.NotifyInspect)=="function" then
        -- Another inspect replaces the client's inspect data; ask again later.
        hooksecurefunc("NotifyInspect",function()
            lastInspect=GetTime()
            if not ownRequest and pending and pending.requested then pending.requested=nil; pending.since=GetTime() end
        end)
    end
    local bar=_G.GameTooltipStatusBar
    if bar then bar:HookScript("OnValueChanged",ColorHealth) end
    local f=CreateFrame("Frame"); T.events=f
    for _,event in ipairs({"INSPECT_TALENT_READY","MODIFIER_STATE_CHANGED","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED",
        "INSTANCE_ENCOUNTER_ENGAGE_UNIT","COMPANION_LEARNED","PLAYER_ENTERING_WORLD"}) do pcall(f.RegisterEvent,f,event) end
    f:SetScript("OnEvent",function(_,event)
        if event=="INSPECT_TALENT_READY" then InspectReady()
        elseif event=="COMPANION_LEARNED" then T.InvalidateMounts()
        elseif event=="PLAYER_ENTERING_WORLD" then T.Apply()
        else T.UpdateVisibility() end
    end)
    f:SetScript("OnUpdate",function()
        if pending and pending.retryAt and GetTime()>=pending.retryAt then pending.retryAt=nil; InspectReady() end
        InspectTick()
    end)
    if E.MakeUnlockElement and E.RegisterUnlockElements then
        E:RegisterUnlockElements({E.MakeUnlockElement({key="EBS_TooltipAnchor",label="Tooltip",group="Tooltips",order=980,noResize=true,noInitHook=true,
            getFrame=EnsureFixedFrame,getSize=function() return 280,165 end,
            isHidden=function() return ns.GetValue("customTooltips")==false or ns.GetValue("tooltipAnchorCursor") end,
            savePos=function(_,point,relPoint,x,y) local p=E.GetActiveProfileData(); if p then p.tooltipFixedPos={point=point,relPoint=relPoint,x=x,y=y} end end,
            loadPos=FixedPos,
            clearPos=function() local p=E.GetActiveProfileData(); if p then p.tooltipFixedPos=nil end end,
            applyPos=T.PositionFixed})},ADDON_NAME)
    end
end
