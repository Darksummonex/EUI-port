local ADDON_NAME,ns=...
local E=EllesmereUI
if not ns.addon then return end
local panels={"CharacterFrame","FriendsFrame","MerchantFrame","GossipFrame","QuestFrame","QuestLogFrame","MailFrame","BankFrame","DressUpFrame","ClassTrainerFrame","TaxiFrame","InspectFrame","AuctionFrame","TradeFrame","AchievementFrame"}
local snapshots,moving,temp={},nil,{}
local pullState
local function True(value) return value~=nil and value~=false and value~=0 end
local function GroupChannel()
    if GetNumRaidMembers()>0 then return "RAID" end
    if GetNumPartyMembers()>0 then return "PARTY" end
end
local function CanLead()
    return True(UnitIsPartyLeader("player")) or (UnitIsRaidOfficer and True(UnitIsRaidOfficer("player")))
end
function ns.GetPullChatChannel()
    local channel=GroupChannel()
    if channel=="RAID" and CanLead() then return "RAID_WARNING" end
    return channel
end
function ns.GetPullSeconds()
    local p=ns.GetSettings(); local value=tonumber(p and p.raidTools.pullSeconds) or 10
    if value~=value then value=10 end
    return math.floor(math.max(3,math.min(60,value)))
end
local function SyncPull(seconds,channel)
    if not channel or not CanLead() or not SendAddonMessage then return false end
    -- Native Wrath DBM, newer DBM-compatible BigWigs Pull plugins, and the
    -- original Wrath BigWigs custom-bar protocol. No boss mod is required here.
    SendAddonMessage("DBMv4-PT",tostring(seconds),channel)
    SendAddonMessage("D4","PT\t"..seconds,channel)
    SendAddonMessage("BigWigs","BWCustomBar "..seconds.." Pull",channel)
    return true
end
local function ChatPull(state,text)
    local p=ns.GetSettings(); local channel=ns.GetPullChatChannel()
    if p and p==state.profile and p.raidTools.pullChat and channel and GroupChannel()==state.channel and SendChatMessage then
        SendChatMessage(text,channel)
    end
end
function ns.CancelPull(quiet)
    local state=pullState; pullState=nil
    if state and GetTime()<state.ends then
        if state.synced and GroupChannel()==state.channel then SyncPull(0,state.channel) end
        if not quiet then ChatPull(state,"Pull canceled") end
    end
    if ns.pullFrame then ns.pullFrame:Hide() end
end
function ns.CancelEarlyPull()
    if pullState and GetTime()<pullState.ends then ns.CancelPull() end
end
function ns.StartPull()
    local p=ns.GetSettings()
    if not p or not p.enabled or not p.raidTools.enabled or InCombatLockdown() or not ns.pullFrame then return false end
    local seconds=ns.GetPullSeconds()
    pullState={profile=p,ends=GetTime()+seconds,last=seconds,channel=GroupChannel()}
    if p.raidTools.pullSync then pullState.synced=SyncPull(seconds,pullState.channel) end
    ChatPull(pullState,"Pull in "..seconds.." seconds")
    ns.UpdatePull(); return true
end
local function Points(f) local t={}; for i=1,f:GetNumPoints() do t[i]={f:GetPoint(i)} end; return t end
local function Restore(f,points) f:ClearAllPoints(); for _,point in ipairs(points) do f:SetPoint(unpack(point)) end end
local function Allowed() local p=ns.GetSettings(); return p and p.enabled and p.shifter.enabled and not InCombatLockdown() end
function ns.FinishMoving(force)
    if not moving or InCombatLockdown() or (not force and IsMouseButtonDown and IsMouseButtonDown("LeftButton")) then return end
    local f,name,permanent=moving.frame,moving.name,moving.permanent
    f:StopMovingOrSizing(); moving=nil
    local x,y=f:GetCenter(); local factor=f:GetEffectiveScale()/UIParent:GetEffectiveScale()
    if permanent and x and y then ns.GetSettings().shifter.positions[name]={x=x*factor,y=y*factor} end
end
local function InstallPanel(name,f)
    if snapshots[f] then return end
    snapshots[f]={points=Points(f),mouse=f:IsMouseEnabled(),movable=f:IsMovable(),name=name}
    f:HookScript("OnMouseDown",function(self,button)
        if button~="LeftButton" or not Allowed() or not (IsShiftKeyDown() or IsControlKeyDown()) then return end
        ns.FinishMoving(true)
        local permanent=IsShiftKeyDown()
        if not permanent and not temp[self] then temp[self]=Points(self) end
        moving={frame=self,name=name,permanent=permanent}; self:StartMoving()
    end)
    f:HookScript("OnMouseUp",function(self) if moving and moving.frame==self then ns.FinishMoving(true) end end)
    f:HookScript("OnHide",function(self)
        if moving and moving.frame==self then ns.FinishMoving(true) end
        if temp[self] and not InCombatLockdown() then Restore(self,temp[self]); temp[self]=nil end
    end)
    f:HookScript("OnShow",function(self)
        local p=ns.GetSettings(); local pos=p and p.shifter.positions[name]
        if Allowed() and pos then self:ClearAllPoints(); self:SetPoint("CENTER",UIParent,"BOTTOMLEFT",pos.x,pos.y) end
    end)
end
local function Button(parent,text,x,width,fn)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate"); ns.Size(b,width,22); b:SetPoint("BOTTOMLEFT",parent,"BOTTOMLEFT",x,0); b:SetText(text); b:SetScript("OnClick",fn); return b
end
local function CreateRaid()
    local f=CreateFrame("Frame","EUI335QoLRaidTools",UIParent,"SecureHandlerStateTemplate"); ns.raidFrame=f; ns.Size(f,232,54)
    f:SetFrameStrata("MEDIUM"); f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1}); f:SetBackdropColor(.035,.045,.05,.95); f:SetBackdropBorderColor(0,0,0,1)
    ns.markers={}
    for i=1,8 do
        local b=CreateFrame("Button",nil,f,"SecureActionButtonTemplate"); ns.Size(b,26,26); b:SetPoint("TOPLEFT",f,"TOPLEFT",(i-1)*29,-1)
        b:RegisterForClicks("AnyUp"); b:SetAttribute("type","macro"); b:SetAttribute("macrotext","/run SetRaidTarget(\"target\","..i..")")
        local t=b:CreateTexture(nil,"ARTWORK"); t:SetAllPoints(b); t:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
        SetRaidTargetIconTexture(t,i); ns.markers[i]=b
        b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
    end
    ns.readyButton=Button(f,"Ready",2,54,function()
        if not InCombatLockdown() and (UnitIsPartyLeader("player") or (UnitIsRaidOfficer and UnitIsRaidOfficer("player"))) then DoReadyCheck() end
    end)
    ns.pullButton=Button(f,"Pull 10s",59,54,ns.StartPull)
    ns.cancelPullButton=Button(f,"Cancel",116,54,function() ns.CancelPull() end)
    ns.disbandButton=Button(f,"Disband",173,57,function() if ns.ConfirmDisband then ns.ConfirmDisband() end end)
    local timer=CreateFrame("Frame",nil,UIParent); ns.pullFrame=timer; ns.Size(timer,240,32); timer:SetPoint("CENTER",UIParent,"CENTER",0,85); timer:EnableMouse(false)
    timer.text=timer:CreateFontString(nil,"OVERLAY"); ns.Font(timer.text,24); timer.text:SetPoint("CENTER",timer,"CENTER",0,0); timer:Hide()
end
function ns.UpdatePull()
    local p=ns.GetSettings(); local f=ns.pullFrame; if not f then return end
    local state=pullState
    if state and (not p or p~=state.profile or not p.enabled or not p.raidTools.enabled or GroupChannel()~=state.channel) then ns.CancelPull(true); return end
    if not state then f:Hide(); return end
    if state.synced and not p.raidTools.pullSync then SyncPull(0,state.channel); state.synced=false end
    local now=GetTime(); local remaining=math.max(0,math.ceil(state.ends-now))
    if remaining~=state.last then
        -- Announce the current checkpoint only; a stalled frame must not flood
        -- chat with stale numbers. Repeated updates in the same second are silent.
        if remaining==10 or remaining<=5 then ChatPull(state,remaining>0 and ("Pull in "..remaining.." seconds") or "Pull!") end
        state.last=remaining
    end
    if now<state.ends+1 then f.text:SetText(remaining>0 and ("Pull in "..remaining) or "Pull!"); f:Show()
    else pullState=nil; f:Hide() end
end
function ns.ApplyPanels()
    if InCombatLockdown() then return end
    local p=ns.GetSettings(); ns.FinishMoving(false)
    for _,name in ipairs(panels) do local f=_G[name]
        if f then
            InstallPanel(name,f); local s=snapshots[f]
            if p.enabled and p.shifter.enabled then
                f:EnableMouse(true); f:SetMovable(true); local pos=p.shifter.positions[name]
                if not (moving and moving.frame==f) then
                    if pos then f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"BOTTOMLEFT",pos.x,pos.y)
                    elseif s.positioned then Restore(f,s.points) end
                end
                s.positioned=pos~=nil
            else
                if moving and moving.frame==f then ns.FinishMoving(true) end
                f:EnableMouse(s.mouse); f:SetMovable(s.movable)
                if s.active then Restore(f,temp[f] or s.points) end
                temp[f]=nil; s.positioned=false
            end
            s.active=p.enabled and p.shifter.enabled
            if temp[f] and not f:IsShown() then Restore(f,temp[f]); temp[f]=nil end
        end
    end
    if not ns.raidFrame then CreateRaid() end
    local f=ns.raidFrame; local pos=p.positions.raidTools; f:ClearAllPoints()
    if pos then f:SetPoint(pos.point,UIParent,pos.relPoint,pos.x,pos.y) else f:SetPoint("CENTER",UIParent,"CENTER",0,270) end
    if f.SetScale then f:SetScale(math.max(.5,math.min(2,(tonumber(p.raidTools.scale) or 100)/100))) end
    RegisterStateDriver(f,"visibility",not (p.enabled and p.raidTools.enabled) and "hide" or (p.raidTools.groupOnly and not ns.preview and "[group] show; hide" or "show"))
    ns.pullButton:SetText("Pull "..ns.GetPullSeconds().."s")
    ns.Font(ns.pullFrame.text,p.combatAlertTextSize); ns.UpdatePull()
end
