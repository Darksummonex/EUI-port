local _,ns=...
if not ns.IsWrath then return end
local E=EllesmereUI
local white="Interface\\Buttons\\WHITE8X8"
local progressTexture="Interface\\TargetingFrame\\UI-StatusBar"
local function Label(key) for _,row in ipairs(ns.BLOCK_TYPES) do if row.key==key then return row.label end end; return key end
local function Coins(value)
    value=math.floor(value or 0)
    return string.format("%dg %ds %dc",math.floor(value/10000),math.floor(value/100)%100,value%100)
end
local function BagSpace()
    local free,total=0,0
    for bag=0,4 do free=free+(GetContainerNumFreeSlots(bag) or 0); total=total+(GetContainerNumSlots(bag) or 0) end
    return free,total
end
function ns.Currencies()
    local rows={}
    for i=1,GetCurrencyListSize and GetCurrencyListSize() or 0 do
        local name,header,expanded,unused,watched,count,extra,icon,itemID=GetCurrencyListInfo(i)
        if name and not header then
            if extra==1 then icon="Interface\\PVPFrame\\PVP-ArenaPoints-Icon"
            elseif extra==2 then icon="Interface\\TargetingFrame\\UI-PVP-"..(UnitFactionGroup("player") or "Horde") end
            rows[#rows+1]={key=itemID and tostring(itemID) or name,name=name,count=count or 0,icon=icon,index=i}
        end
    end
    return rows
end
function ns.BuildCurrencyList()
    local values,order={[""]="Select Currency"},{""}
    for _,r in ipairs(ns.Currencies()) do values[r.key]=r.name; order[#order+1]=r.key end
    return values,order
end
local function Spec()
    local chosen,icon,highest="No Talents",nil,0
    local group=GetActiveTalentGroup and GetActiveTalentGroup() or 1
    for tab=1,3 do
        local name,path,points=GetTalentTabInfo(tab,false,false,group)
        if name and (points or 0)>highest then chosen,icon,highest=name,path,points end
    end
    return chosen,icon,group
end
local function Skills(secondary)
    local ids=secondary and {2550,3273,7620} or {2259,2018,7411,4036,2366,45357,25229,2108,2575,8613,3908}
    local names={}
    for _,id in ipairs(ids) do local name=GetSpellInfo(id); if name then names[name]=true end end
    local rows={}
    for i=1,GetNumSkillLines and GetNumSkillLines() or 0 do
        local name,header,expanded,rank,temp,modifier,maximum=GetSkillLineInfo(i)
        if not header and names[name] then rows[#rows+1]=string.format("%s %d/%d",name,rank or 0,maximum or 0) end
    end
    return rows
end
local function Progress(b)
    local mode=b.settings.mode or "auto"
    if mode=="auto" then mode=UnitLevel("player")<(MAX_PLAYER_LEVEL or 80) and "xp" or "reputation" end
    if mode=="xp" then
        local current,maximum=UnitXP("player"),math.max(1,UnitXPMax("player"))
        if UnitLevel("player")>=(MAX_PLAYER_LEVEL or 80) then return "Max Level",0,1,{r=0,g=.4,b=1},0 end
        return string.format("XP: %.1f%%",100*current/maximum),current,maximum,{r=0,g=.4,b=1},GetXPExhaustion() or 0
    end
    local name,standing,minRep,maxRep,value=GetWatchedFactionInfo()
    if not name then return "No Watched Reputation",0,1,{r=.047,g=.824,b=.616},0 end
    local current=math.max(0,(value or 0)-(minRep or 0)); local maximum=math.max(1,(maxRep or 1)-(minRep or 0))
    local color=FACTION_BAR_COLORS and FACTION_BAR_COLORS[standing] or {r=.047,g=.824,b=.616}
    return name..string.format(": %.1f%%",100*current/maximum),current,maximum,color,0
end
local function ToggleBags()
    local b=E._ModuleNS.EllesmereUIBags
    if b and b.GetSettings and b.GetSettings().enhancedBags then b.Toggle() elseif ToggleAllBags then ToggleAllBags() end
end
local function Click(slot,button)
    if InCombatLockdown() then return end
    local b=slot.block; local key=b.type
    if key=="clock" then if button=="RightButton" and ToggleTimeManager then ToggleTimeManager() elseif ToggleCalendar then ToggleCalendar() end
    elseif key=="bags" or key=="gold" or key=="ldb" then
        local inventory=E._ModuleNS.EllesmereUIBags
        if button=="RightButton" and inventory and inventory.OpenCharacterBank then inventory.OpenCharacterBank() else ToggleBags() end
    elseif key=="location" or key=="coords" then if ToggleWorldMap then ToggleWorldMap() end
    elseif key=="durability" or key=="ilvl" then if ToggleCharacter then ToggleCharacter("PaperDollFrame") end
    elseif key=="currency" then if ToggleCharacter then ToggleCharacter("TokenFrame") end
    elseif key=="xprep" then if ToggleCharacter then ToggleCharacter("ReputationFrame") end
    elseif key=="spec" then if button=="RightButton" and GetNumTalentGroups and GetNumTalentGroups()>1 then SetActiveTalentGroup(GetActiveTalentGroup()==1 and 2 or 1) elseif ToggleTalentFrame then ToggleTalentFrame() end
    elseif key=="profession" or key=="profession2" then if ToggleCharacter then ToggleCharacter("SkillFrame") end
    elseif key=="audio" then
        local channel=b.settings.channel or "Master"
        local cvar=channel=="Master" and "Sound_EnableAllSound" or "Sound_Enable"..channel
        SetCVar(cvar,GetCVar(cvar)=="1" and "0" or "1")
    end
end
local function Tooltip(slot)
    local b=slot.block; GameTooltip:SetOwner(slot,"ANCHOR_TOP"); GameTooltip:SetText(Label(b.type))
    GameTooltip:AddLine(slot.text:GetText() or "",1,1,1)
    if slot.details then for _,line in ipairs(slot.details) do GameTooltip:AddLine(line,.85,.85,.85) end end
    local hints={clock="Left: calendar / Right: clock",bags="Left: bags / Right: saved bank",gold="Left: bags / Right: saved bank",ldb="Left: bags / Right: saved bank",
        spec="Left: talents / Right: switch dual spec",audio="Click: mute / Mouse wheel: volume",travel="Click: use Hearthstone",
        currency="Click: currencies",xprep="Click: reputation",ilvl="Click: character",durability="Click: character",
        location="Click: world map",coords="Click: world map",profession="Click: skills",profession2="Click: skills"}
    if hints[b.type] then GameTooltip:AddLine(hints[b.type],.047,.824,.616) end
    GameTooltip:Show()
end
local micro={
    {"CharacterMicroButton","Character","INV_Misc_Head_Human_01"},
    {"SpellbookMicroButton","Spellbook","INV_Misc_Book_09"},
    {"TalentMicroButton","Talents","Ability_Marksmanship"},
    {"AchievementMicroButton","Achievements","Achievement_Level_80"},
    {"QuestLogMicroButton","Quests","INV_Misc_Note_01"},
    {"SocialsMicroButton","Social","INV_Misc_GroupNeedMore"},
    {"PVPMicroButton","PvP","INV_BannerPVP_01"},
    {"LFDMicroButton","Dungeon Finder","INV_Helmet_08"},
    {"MainMenuMicroButton","Menu","INV_Misc_Gear_01"},
    {"HelpMicroButton","Help","INV_Misc_QuestionMark"},
}
function ns.MakeBlock(parent,b,barID)
    local slot=CreateFrame("Button",nil,parent); slot.block,slot.barID=b,barID
    if b.type=="xprep" then
        slot.rested=CreateFrame("StatusBar",nil,slot); slot.rested:SetAllPoints(slot); slot.rested:SetStatusBarTexture(progressTexture); slot.rested:SetStatusBarColor(.5,0,.5,.75)
        slot.fill=CreateFrame("StatusBar",nil,slot); slot.fill:SetAllPoints(slot); slot.fill:SetStatusBarTexture(progressTexture); slot.fill:SetFrameLevel(slot.rested:GetFrameLevel()+1)
    end
    slot.text=(slot.fill or slot):CreateFontString(nil,"OVERLAY"); ns.Font(slot.text,11); slot.text:SetPoint("CENTER",slot,"CENTER",0,0)
    slot.text:SetJustifyH("CENTER"); if slot.text.SetWordWrap then slot.text:SetWordWrap(false) end
    slot:RegisterForClicks("LeftButtonUp","RightButtonUp")
    slot:SetScript("OnClick",Click)
    slot:SetScript("OnEnter",Tooltip); slot:SetScript("OnLeave",function() GameTooltip:Hide() end)
    slot:SetHighlightTexture(white); slot:GetHighlightTexture():SetAlpha(.08)
    if b.type=="travel" then
        local secure=CreateFrame("Button",nil,slot,"SecureActionButtonTemplate"); slot.secure=secure
        secure:RegisterForClicks("AnyUp"); secure:SetAttribute("type","item"); secure:SetAttribute("item","item:6948")
        secure:SetScript("OnEnter",function() Tooltip(slot) end); secure:SetScript("OnLeave",function() GameTooltip:Hide() end)
    elseif b.type=="micromenu" then
        slot.micro={}
        for _,entry in ipairs(micro) do if _G[entry[1]] then
            local name,label,path=unpack(entry)
            local button=CreateFrame("Button",nil,slot)
            local icon=button:CreateTexture(nil,"ARTWORK"); icon:SetAllPoints(button); icon:SetTexture("Interface\\Icons\\"..path); icon:SetTexCoord(.08,.92,.08,.92)
            button:RegisterForClicks("LeftButtonUp")
            button:SetScript("OnClick",function() local native=_G[name]; if not InCombatLockdown() and native and native:IsEnabled() then native:Click() end end)
            button:SetScript("OnEnter",function() GameTooltip:SetOwner(button,"ANCHOR_TOP"); GameTooltip:SetText(label); GameTooltip:Show() end)
            button:SetScript("OnLeave",function() GameTooltip:Hide() end)
            slot.micro[#slot.micro+1]=button
        end end
    elseif b.type=="audio" then
        slot:EnableMouseWheel(true)
        slot:SetScript("OnMouseWheel",function(_,delta)
            local cvar="Sound_"..(slot.block.settings.channel or "Master").."Volume"
            SetCVar(cvar,ns.Clamp((tonumber(GetCVar(cvar)) or 0)+delta*.05,0,1)); ns.Update()
        end)
    end
    return slot
end
function ns.UpdateBlock(slot,b,cfg)
    slot.block=b; slot.details=nil; local text,key,s="",b.type,b.settings
    if key=="clock" then
        local hour,minute
        if s.localTime~=false then hour,minute=tonumber(date("%H")),tonumber(date("%M")) else hour,minute=GetGameTime() end
        local suffix=""; if not s.twentyFour then suffix=hour>=12 and " PM" or " AM"; hour=hour%12; if hour==0 then hour=12 end end
        text=string.format("%02d:%02d%s",hour,minute,suffix)
        if HasNewMail and HasNewMail() then text=text.." [Mail]" end
    elseif key=="fps" then text=string.format("%.0f FPS",GetFramerate())
    elseif key=="ms" then local down,up,home,world=GetNetStats(); text=string.format("%d ms",home or 0); slot.details={string.format("Home: %d ms / World: %d ms",home or 0,world or home or 0),string.format("Download: %.1f KB/s / Upload: %.1f KB/s",down or 0,up or 0)}
    elseif key=="location" then text=s.showSubZone and GetSubZoneText() or ""; if not text or text=="" then text=GetZoneText() end
    elseif key=="coords" then
        local instance=IsInInstance and IsInInstance()
        local x,y=GetPlayerMapPosition("player")
        -- Do not change the user's world-map selection to obtain coordinates.
        text=(s.hideInInstance and instance or not x or not y or x==0 and y==0) and "--, --" or string.format("%."..ns.Clamp(s.precision or 1,0,2).."f, %."..ns.Clamp(s.precision or 1,0,2).."f",x*100,y*100)
    elseif key=="gold" then text=Coins(GetMoney())
    elseif key=="bags" then local free,total=BagSpace(); text=s.value=="used" and (total-free).."/"..total.." Used" or free.."/"..total.." Free"
    elseif key=="durability" then
        local current,maximum=0,0; local lowest=100
        for i=1,18 do local value,maxDur=GetInventoryItemDurability(i); if maxDur and maxDur>0 then current=current+value; maximum=maximum+maxDur; lowest=math.min(lowest,100*value/maxDur) end end
        text=string.format("Durability: %.0f%%",maximum>0 and 100*current/maximum or 100); slot.details={string.format("Lowest item: %.0f%%",lowest)}
    elseif key=="combat" then text=InCombatLockdown() and "In Combat" or "Out of Combat"
    elseif key=="xprep" then
        local current,maximum,color,rested
        text,current,maximum,color,rested=Progress(b)
        slot.fill:SetMinMaxValues(0,maximum); slot.fill:SetValue(current); slot.fill:SetStatusBarColor(color.r,color.g,color.b,1)
        slot.rested:SetMinMaxValues(0,maximum); slot.rested:SetValue(math.min(maximum,current+rested))
        if rested>0 then slot.rested:Show() else slot.rested:Hide() end
        slot.details={string.format("%d / %d",current,maximum)}
        if rested>0 then slot.details[#slot.details+1]="Rested: "..rested end
    elseif key=="spec" then local name,icon,group=Spec(); text=name; slot.details={"Talent Group: "..group}
    elseif key=="profession" or key=="profession2" then local rows=Skills(key=="profession2"); text=#rows>0 and table.concat(rows," | ") or "No Professions"; slot.details=rows
    elseif key=="travel" then
        local start,duration=GetItemCooldown(6948); local remaining=math.max(0,(start or 0)+(duration or 0)-GetTime())
        text=remaining>0 and string.format("Hearth: %d:%02d",math.floor(remaining/60),math.floor(remaining%60)) or "Hearthstone"
        if GetBindLocation then slot.details={GetBindLocation()} end
    elseif key=="micromenu" and not InCombatLockdown() then
        local n=#slot.micro; local gap=2; local vertical=cfg.orientation=="V"
        local length=vertical and slot:GetHeight() or slot:GetWidth(); local cross=vertical and slot:GetWidth() or slot:GetHeight()
        local size=math.max(1,math.min(26,cross,(length-gap*math.max(0,n-1))/math.max(1,n)))
        for i,button in ipairs(slot.micro) do button:ClearAllPoints(); ns.Size(button,size,size)
            if vertical then button:SetPoint("TOP",slot,"TOP",0,-(i-1)*(size+gap)) else button:SetPoint("LEFT",slot,"LEFT",(i-1)*(size+gap),0) end
        end
    elseif key=="currency" then
        text="Select Currency"
        for _,r in ipairs(ns.Currencies()) do if r.key==s.currencyKey then text=r.name..": "..r.count; break end end
    elseif key=="ilvl" then
        local total,count,missing=0,0,0
        for i=1,18 do if i~=4 then local link=GetInventoryItemLink("player",i); if link then
            local _,_,_,level=GetItemInfo(link); if level then total=total+level; count=count+1 else missing=missing+1 end
        end end end
        text=missing>0 and "iLvl: loading" or string.format("iLvl: %."..ns.Clamp(s.precision or 0,0,2).."f",count>0 and total/count or 0)
        slot.details={"Average equipped items (empty slots excluded)"}
    elseif key=="audio" then local channel=s.channel or "Master"; local cvar=channel=="Master" and "Sound_EnableAllSound" or "Sound_Enable"..channel; text=channel..": "..(GetCVar(cvar)=="0" and "Muted" or string.format("%.0f%%",100*(tonumber(GetCVar("Sound_"..channel.."Volume")) or 0)))
    elseif key=="ldb" then
        -- Only the suite's own inventory object; never read another addon's data.
        local inventory=E._ModuleNS.EllesmereUIBags; local object=inventory and inventory.broker
        if object then text=object.text or "Bags" else local free,total=BagSpace(); text=free.."/"..total.." Free" end
    end
    slot.text:SetText(text or "")
end
