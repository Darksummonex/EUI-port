-- Group automation matching ElvUI's Misc module: interrupt announce, accepting
-- invites from friends and guildmates, and disbanding the group.
local _,ns=...
local E=EllesmereUI
if not ns.addon then return end
local Enabled=ns.Enabled
for key,value in pairs({interruptAnnounce="NONE",autoAcceptInvites=false}) do ns.defaults.profile[key]=value end
local events=CreateFrame("Frame"); ns.groupEvents=events

-- Interrupt announce ---------------------------------------------------------
ns.INTERRUPT_CHANNELS={NONE="Off",SAY="Say",EMOTE="Emote",PARTY="Party",RAID="Raid, else Party",RAID_ONLY="Raid Only"}
ns.INTERRUPT_ORDER={"NONE","SAY","EMOTE","PARTY","RAID","RAID_ONLY"}
function ns.InterruptChannel(mode)
    if mode=="SAY" or mode=="EMOTE" then return mode end
    local _,kind=IsInInstance()
    local raid,party=GetNumRaidMembers()>0,GetNumPartyMembers()>0
    local group=kind=="pvp" and "BATTLEGROUND"
    if mode=="PARTY" then return party and (group or "PARTY") or nil end
    if mode=="RAID" then
        if raid then return group or "RAID" end
        return party and (group or "PARTY") or nil
    end
    if mode=="RAID_ONLY" then return raid and (group or "RAID") or nil end
end
-- 3.3.5 SPELL_INTERRUPT: ..., spellId, spellName, school, extraSpellId, extraSpellName.
function ns.AnnounceInterrupt(sub,srcGUID,dstName,extraId,extraName)
    if sub~="SPELL_INTERRUPT" or not srcGUID then return end
    if srcGUID~=UnitGUID("player") and srcGUID~=UnitGUID("pet") then return end
    local p=ns.GetSettings()
    local channel=p and p.enabled and ns.InterruptChannel(p.interruptAnnounce)
    if not channel then return end
    local spell=(extraId and GetSpellLink and GetSpellLink(extraId)) or (extraName and "["..extraName.."]") or ""
    SendChatMessage(string.format("%s %s's %s!",INTERRUPTED or "Interrupted",dstName or UNKNOWN or "Unknown",spell),channel)
end

-- Auto-accept invites --------------------------------------------------------
local function Short(name) return type(name)=="string" and name:match("^[^%-]+") or nil end
function ns.IsFriendOrGuildmate(name)
    name=Short(name)
    if not name then return false end
    for i=1,(GetNumFriends and GetNumFriends() or 0) do
        if Short(GetFriendInfo(i))==name then return true end
    end
    if IsInGuild and IsInGuild() and GetNumGuildMembers then
        for i=1,(GetNumGuildMembers() or 0) do
            if Short(GetGuildRosterInfo(i))==name then return true end
        end
    end
    return false
end
local accepted=false
function ns.AutoAcceptInvite(name)
    if not Enabled("autoAcceptInvites") then return end
    -- Accepting while queued would drop the Dungeon Finder queue.
    if MiniMapLFGFrame and MiniMapLFGFrame:IsShown() then return end
    if GetNumPartyMembers()>0 or GetNumRaidMembers()>0 then return end
    if not ns.IsFriendOrGuildmate(name) then return end
    AcceptGroup(); accepted=true
    if StaticPopup_Hide then StaticPopup_Hide("PARTY_INVITE") end
end

-- Disband --------------------------------------------------------------------
function ns.IsGroupLeader()
    return ((UnitIsPartyLeader and UnitIsPartyLeader("player")) or (IsRaidLeader and IsRaidLeader())) and true or false
end
function ns.DisbandGroup()
    if InCombatLockdown() then return end
    local raid,party=GetNumRaidMembers(),GetNumPartyMembers()
    if raid==0 and party==0 then return end
    if not ns.IsGroupLeader() then ns.Print("Only the group leader can disband the group."); return end
    local me=UnitName("player")
    if raid>0 then
        for i=1,raid do local name=GetRaidRosterInfo(i); if name and name~=me then UninviteUnit(name) end end
    else
        for i=party,1,-1 do local name=UnitName("party"..i); if name then UninviteUnit(name) end end
    end
    LeaveParty()
end
StaticPopupDialogs.EUI335_DISBAND_GROUP={text="Disband your group? Everyone will be removed.",button1=YES or "Yes",button2=NO or "No",
    OnAccept=function() ns.DisbandGroup() end,timeout=0,whileDead=1,hideOnEscape=1}
function ns.ConfirmDisband()
    if InCombatLockdown() or (GetNumRaidMembers()==0 and GetNumPartyMembers()==0) then return end
    if StaticPopup_Show then StaticPopup_Show("EUI335_DISBAND_GROUP") else ns.DisbandGroup() end
end

-- Disband and reinvite -------------------------------------------------------
-- Everyone is removed, then invited back once the old group is gone. A party
-- holds five, so a raid gets four invites, converts once the first one joins,
-- then gets the rest. Wrath has no ConvertToParty: a raid of five or fewer is
-- turned into a party the same way, without the conversion.
local rebuild=CreateFrame("Frame"); ns.rebuildEvents=rebuild
local pending,asRaid,phase,deadline
local function Roster()
    local me=UnitName("player"); local names={}
    if GetNumRaidMembers()>0 then
        for i=1,GetNumRaidMembers() do local name=GetRaidRosterInfo(i); if name and name~=me then names[#names+1]=name end end
    else
        for i=1,GetNumPartyMembers() do local name=UnitName("party"..i); if name then names[#names+1]=name end end
    end
    return names
end
local function Stop() pending,phase=nil,nil; rebuild:UnregisterAllEvents() end
local function InviteNext(limit)
    local n=0
    while pending[1] and (not limit or n<limit) do InviteUnit(table.remove(pending,1)); n=n+1 end
    if not pending[1] and not (asRaid and GetNumRaidMembers()==0) then Stop() end
end
function ns.CanReinvite()
    return (GetNumRaidMembers()>1 or GetNumPartyMembers()>0) and ns.IsGroupLeader() and not InCombatLockdown()
end
function ns.CanRebuildParty() return GetNumRaidMembers()<=5 and GetNumRaidMembers()>1 and ns.CanReinvite() end
local function Rebuild(raid)
    local names=Roster(); if #names==0 then return end
    pending,asRaid,phase,deadline=names,raid,"leaving",GetTime()+15
    rebuild:RegisterEvent("RAID_ROSTER_UPDATE"); rebuild:RegisterEvent("PARTY_MEMBERS_CHANGED")
    for _,name in ipairs(names) do UninviteUnit(name) end
    LeaveParty()
end
function ns.ReinviteGroup() if ns.CanReinvite() then Rebuild(GetNumRaidMembers()>0) end end
function ns.RebuildAsParty() if ns.CanRebuildParty() then Rebuild(false) end end
rebuild:SetScript("OnEvent",function()
    if not pending or GetTime()>deadline then Stop(); return end
    local raid,party=GetNumRaidMembers(),GetNumPartyMembers()
    if phase=="leaving" then
        if raid>0 or party>0 then return end
        phase="inviting"; deadline=GetTime()+120
        InviteNext((asRaid or #pending>4) and 4 or nil)
    elseif raid==0 and party>0 and asRaid then ConvertToRaid()
    elseif raid>0 then InviteNext() end
end)
StaticPopupDialogs.EUI335_REBUILD_PARTY={text="Convert the raid to a party? Everyone is removed and invited back to a new party.",button1=YES or "Yes",button2=NO or "No",
    OnAccept=function() ns.RebuildAsParty() end,timeout=0,whileDead=1,hideOnEscape=1}
StaticPopupDialogs.EUI335_REINVITE_GROUP={text="Disband and reinvite? Everyone is removed and invited back to the same kind of group.",button1=YES or "Yes",button2=NO or "No",
    OnAccept=function() ns.ReinviteGroup() end,timeout=0,whileDead=1,hideOnEscape=1}
function ns.ConfirmReinvite()
    if not ns.CanReinvite() then return end
    if StaticPopup_Show then StaticPopup_Show("EUI335_REINVITE_GROUP") else ns.ReinviteGroup() end
end
function ns.ConfirmRebuildParty()
    if not ns.CanRebuildParty() then return end
    if StaticPopup_Show then StaticPopup_Show("EUI335_REBUILD_PARTY") else ns.RebuildAsParty() end
end

events:SetScript("OnEvent",function(_,event,...)
    if event=="COMBAT_LOG_EVENT_UNFILTERED" then
        local _,sub,srcGUID,_,_,_,dstName,_,_,_,_,extraId,extraName=...
        ns.AnnounceInterrupt(sub,srcGUID,dstName,extraId,extraName)
    elseif event=="PARTY_INVITE_REQUEST" then ns.AutoAcceptInvite(...)
    elseif event=="PARTY_MEMBERS_CHANGED" then
        if accepted then accepted=false; if StaticPopup_Hide then StaticPopup_Hide("PARTY_INVITE") end end
    elseif event=="PLAYER_ENTERING_WORLD" then
        if Enabled("autoAcceptInvites") then
            if ShowFriends then ShowFriends() end
            if IsInGuild and IsInGuild() and GuildRoster then GuildRoster() end
        end
    end
end)
function ns.ApplyGroup()
    local p=ns.GetSettings()
    local function Watch(event,on) if on then events:RegisterEvent(event) else events:UnregisterEvent(event) end end
    Watch("COMBAT_LOG_EVENT_UNFILTERED",p and p.enabled and (p.interruptAnnounce or "NONE")~="NONE")
    local invites=Enabled("autoAcceptInvites") and true or false
    Watch("PARTY_INVITE_REQUEST",invites); Watch("PARTY_MEMBERS_CHANGED",invites); Watch("PLAYER_ENTERING_WORLD",invites)
end
