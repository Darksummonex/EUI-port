-- Group loot roll choices: counts each player's Need/Greed/Disenchant/Pass
-- from the loot chat messages and shows them on the native roll buttons.
local _,ns=...
if not ns.IsWrath then return end
local E=EllesmereUI
ns.defaults.lootRollShowChoices=true
local R={}; ns.LootRolls=R
table.insert(ns.extras,R)
local BUTTONS={need="RollButton",greed="GreedButton",disenchant="DisenchantButton",pass="PassButton"}
local function Label(choice)
    return choice=="need" and (NEED or "Need") or choice=="greed" and (GREED or "Greed")
        or choice=="disenchant" and (ROLL_DISENCHANT or "Disenchant") or (PASS or "Pass")
end
-- Self lines first ("You passed on: %s" also fits "%s passed on: %s"), and
-- the automatic passes before the plain pass.
local SOURCES={{"LOOT_ROLL_PASSED_SELF_AUTO","pass",true},{"LOOT_ROLL_NEED_SELF","need",true},{"LOOT_ROLL_GREED_SELF","greed",true},
    {"LOOT_ROLL_DISENCHANT_SELF","disenchant",true},{"LOOT_ROLL_PASSED_SELF","pass",true},
    {"LOOT_ROLL_PASSED_AUTO","pass"},{"LOOT_ROLL_PASSED_AUTO_FEMALE","pass"},
    {"LOOT_ROLL_NEED","need"},{"LOOT_ROLL_GREED","greed"},{"LOOT_ROLL_DISENCHANT","disenchant"},{"LOOT_ROLL_PASSED","pass"}}
local rolls={}
R.rolls=rolls
local function Escape(text) return (text:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])","%%%1")) end
-- Localized formats may use positional "%1$s" tokens.
function R.ToPattern(format)
    local out,order,pos,index={},{},1,0
    while true do
        local s1,e1,n=format:find("%%(%d)%$s",pos)
        local s2,e2=format:find("%%s",pos)
        local s,e
        if s1 and (not s2 or s1<=s2) then s,e=s1,e1 else s,e,n=s2,e2,nil end
        if not s then break end
        out[#out+1]=Escape(format:sub(pos,s-1)); out[#out+1]="(.+)"
        index=index+1; order[#order+1]=tonumber(n) or index; pos=e+1
    end
    out[#out+1]=Escape(format:sub(pos))
    return "^"..table.concat(out).."$",order
end
local patterns
local function Patterns()
    if patterns then return patterns end
    patterns={}
    for _,source in ipairs(SOURCES) do
        local format=_G[source[1]]
        if type(format)=="string" and format~="" then
            local pattern,order=R.ToPattern(format)
            patterns[#patterns+1]={pattern=pattern,order=order,choice=source[2],self=source[3]}
        end
    end
    return patterns
end
function R.Parse(msg)
    if type(msg)~="string" then return end
    for _,p in ipairs(Patterns()) do
        local captures={msg:match(p.pattern)}
        if captures[1] then
            local values={}
            for i,value in ipairs(captures) do values[p.order[i] or i]=value end
            if p.self then return p.choice,UnitName("player"),values[1] end
            local name,link=values[1],values[2]
            if name and name:find("|H",1,true) then name,link=link,name end
            return p.choice,name,link
        end
    end
end
local function Key(link)
    if type(link)~="string" then return end
    return link:match("item:(%-?%d+)") or link:match("%[(.-)%]") or link
end
function R.Start(rollID)
    local link=GetLootRollItemLink and GetLootRollItemLink(rollID)
    rolls[rollID]={key=Key(link),need={},greed={},disenchant={},pass={},chosen={}}
    R.Refresh()
end
function R.Cancel(rollID) rolls[rollID]=nil; R.Refresh() end
function R.Record(choice,name,link)
    local key=Key(link)
    if not choice or not name or not key then return end
    -- Several rolls can share an item; give the pick to the oldest roll this
    -- player has not answered yet.
    local id
    for rollID,r in pairs(rolls) do
        if r.key==key and not r.chosen[name] and (not id or rollID<id) then id=rollID end
    end
    if not id then return end
    local r=rolls[id]; r.chosen[name]=choice; table.insert(r[choice],name)
    R.Refresh()
end
local function ClassColor(name)
    local colors=CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS or {}
    local class
    if UnitName("player")==name then class=select(2,UnitClass("player")) end
    for i=1,(GetNumRaidMembers and GetNumRaidMembers() or 0) do
        if class then break end
        local raidName,_,_,_,_,fileName=GetRaidRosterInfo(i)
        if raidName==name then class=fileName end
    end
    for i=1,(GetNumPartyMembers and GetNumPartyMembers() or 0) do
        if class then break end
        if UnitName("party"..i)==name then class=select(2,UnitClass("party"..i)) end
    end
    local c=class and colors[class]
    if c then return c.r,c.g,c.b end
    return 1,1,1
end
local counts,owners={},{}
function R.ShowTooltip(button)
    if not ns.GetValue("lootRollShowChoices") then return end
    local owner=owners[button]; if not owner then return end
    local r=owner.frame.rollID and rolls[owner.frame.rollID]
    local names=r and r[owner.choice]
    if not names or #names==0 then return end
    if not GameTooltip:IsOwned(button) then GameTooltip:SetOwner(button,"ANCHOR_RIGHT"); GameTooltip:SetText(Label(owner.choice)) end
    for _,name in ipairs(names) do GameTooltip:AddLine(name,ClassColor(name)) end
    GameTooltip:Show()
end
local function Count(frame,choice,button)
    local fs=counts[button]
    if not fs then
        fs=button:CreateFontString(nil,"OVERLAY"); ns.owned[fs]=true
        fs:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",2,-2)
        counts[button]=fs; owners[button]={frame=frame,choice=choice}
        button:HookScript("OnEnter",R.ShowTooltip)
    end
    fs:SetFont(E.GetFontPath("blizzardSkin"),12,"OUTLINE"); fs:SetTextColor(1,1,1,1)
    return fs
end
function R.Refresh()
    local on=ns.GetValue("lootRollShowChoices")
    for i=1,(NUM_GROUP_LOOT_FRAMES or 4) do
        local frame=_G["GroupLootFrame"..i]
        if frame then
            local r=on and frame:IsShown() and frame.rollID and rolls[frame.rollID]
            for choice,suffix in pairs(BUTTONS) do
                local button=_G["GroupLootFrame"..i..suffix]
                if button and (r or counts[button]) then
                    local fs=Count(frame,choice,button)
                    local n=r and #r[choice] or 0
                    if n>0 then fs:SetText(n); fs:Show() else fs:SetText(""); fs:Hide() end
                end
            end
        end
    end
end
R.Apply=R.Refresh
function R.Enable()
    for i=1,(NUM_GROUP_LOOT_FRAMES or 4) do
        local frame=_G["GroupLootFrame"..i]
        if frame then frame:HookScript("OnShow",R.Refresh) end
    end
    local f=CreateFrame("Frame"); R.events=f
    for _,event in ipairs({"START_LOOT_ROLL","CANCEL_LOOT_ROLL","CHAT_MSG_LOOT"}) do pcall(f.RegisterEvent,f,event) end
    f:SetScript("OnEvent",function(_,event,arg1)
        if event=="START_LOOT_ROLL" then R.Start(arg1)
        elseif event=="CANCEL_LOOT_ROLL" then R.Cancel(arg1)
        else R.Record(R.Parse(arg1)) end
    end)
end
