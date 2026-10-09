-- Native 3.3.5 mailbox helpers: Retail's Open All button and Shift-click category attach.
local _,ns=...
local function Enabled(key) local p=ns.GetSettings and ns.GetSettings(); return p and p.enabled and p[key] end
local MAX_SEND,MAX_RECEIVE=ATTACHMENTS_MAX_SEND or 12,ATTACHMENTS_MAX_RECEIVE or 16
local MIN_DELAY,TIMEOUT=.15,3

local function Print(text) if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff0cd29fEllesmereUI|r: "..text) end end
local function InboxSignature()
    local count=GetInboxNumItems(); local items,money=0,0
    for i=1,count do
        local _,_,_,_,m,_,_,n=GetInboxHeaderInfo(i)
        items=items+(n or 0); money=money+(m or 0)
    end
    return count..":"..items..":"..money
end

local run
local function UpdateButton()
    local b=ns.mailButton; if not b then return end
    local postal=_G.PostalOpenAllButton
    if not Enabled("mailOpenAll") or (postal and postal~=b and postal:IsShown()) then b:Hide(); return end
    b:Show(); b:SetText(run and "Opening..." or "Open All")
    if run or GetInboxNumItems()>0 then b:Enable() else b:Disable() end
end
local function StopOpenAll()
    if not run then return end
    local full=run.full; run=nil
    if ns.mailDriver then ns.mailDriver:Hide() end
    if full then Print("Open All stopped taking items because your bags are full.") end
    UpdateButton()
end
local function Act(fn,index,slot)
    run.signature=InboxSignature(); run.deadline=GetTime()+TIMEOUT; run.waiting=true
    if slot then fn(index,slot) else fn(index) end
end
function ns.MailStep()
    if not run then return end
    if not Enabled("mailOpenAll") or not InboxFrame or not InboxFrame:IsVisible() then return StopOpenAll() end
    local now=GetTime()
    if run.waiting then
        local changed=InboxSignature()~=run.signature
        if not changed and now<run.deadline then return end
        -- A take the server never answered: leave that mail rather than retry forever.
        if not changed then run.index=run.index-1 end
        run.waiting=false; run.nextAt=now+MIN_DELAY
    end
    if now<run.nextAt then return end
    run.index=math.min(run.index,GetInboxNumItems())
    while run.index>0 do
        local index=run.index
        local _,_,_,_,money,cod,_,count,_,_,_,_,isGM=GetInboxHeaderInfo(index)
        if (cod or 0)>0 or isGM then run.index=index-1
        else
            local slot
            if not run.full and (count or 0)>0 then
                for a=MAX_RECEIVE,1,-1 do if GetInboxItemLink(index,a) then slot=a; break end end
            end
            if slot then return Act(TakeInboxItem,index,slot)
            elseif (money or 0)>0 then return Act(TakeInboxMoney,index)
            else run.index=index-1 end
        end
    end
    StopOpenAll()
end
function ns.MailOpenAll()
    if run then return StopOpenAll() end
    if not Enabled("mailOpenAll") or GetInboxNumItems()==0 then return end
    run={index=GetInboxNumItems(),nextAt=0}
    ns.mailDriver:Show(); UpdateButton(); ns.MailStep()
end
local function OnMailEvent(_,event,message)
    if event=="MAIL_CLOSED" then StopOpenAll()
    elseif event=="UI_ERROR_MESSAGE" then
        if not run then return end
        if message==ERR_INV_FULL then run.full=true; run.waiting=false; run.nextAt=GetTime()+MIN_DELAY
        elseif message==ERR_ITEM_MAX_COUNT then run.index=run.index-1; run.waiting=false; run.nextAt=GetTime()+MIN_DELAY end
    else UpdateButton() end
end

local scan
local function Binding(bag,slot)
    scan=scan or _G.EUI335QoLMailScan or CreateFrame("GameTooltip","EUI335QoLMailScan",nil,"GameTooltipTemplate")
    scan:SetOwner(UIParent,"ANCHOR_NONE"); scan:ClearLines(); scan:SetBagItem(bag,slot)
    for i=2,math.min(scan:NumLines() or 0,6) do
        local line=_G["EUI335QoLMailScanTextLeft"..i]; local text=line and line:GetText()
        if text==ITEM_SOULBOUND then return "soulbound"
        elseif text==ITEM_BIND_QUEST then return "quest"
        elseif text==ITEM_BIND_ON_EQUIP then return "boe"
        elseif text==ITEM_BIND_ON_USE then return "bou"
        elseif text==ITEM_BIND_TO_ACCOUNT or (ITEM_BIND_TO_BNETACCOUNT and text==ITEM_BIND_TO_BNETACCOUNT) then return "boa" end
    end
end
local function ItemInfo(bag,slot)
    local link=GetContainerItemLink(bag,slot); if not link then return end
    local _,_,locked=GetContainerItemInfo(bag,slot)
    local _,_,quality,_,_,class,subclass=GetItemInfo(link)
    if not class or locked then return end
    local bind=Binding(bag,slot)
    if bind=="soulbound" or bind=="quest" then return end
    local weapon,armor=GetAuctionItemClasses()
    return {quality=quality,class=class,subclass=subclass,bind=bind,gear=class==weapon or class==armor}
end
-- Gear groups by binding and quality (BoE greens stay apart from BoE epics);
-- everything else by item class and subclass (Metal & Stone, Herb, Cloth...).
local function SameCategory(a,b)
    if a.gear or b.gear then return a.gear and b.gear and a.bind==b.bind and a.quality==b.quality end
    return a.class==b.class and a.subclass==b.subclass
end
local function Attach(bag,slot,index)
    PickupContainerItem(bag,slot); ClickSendMailItemButton(index)
    if CursorHasItem() then ClearCursor(); return false end
    return true
end
function ns.MailAttachCategory(bag,slot)
    local source=ItemInfo(bag,slot); if not source then return false end
    local free={}
    for i=1,MAX_SEND do if not GetSendMailItem(i) then free[#free+1]=i end end
    if #free==0 or not Attach(bag,slot,free[1]) then return true end
    local used=1
    for b=0,NUM_BAG_SLOTS or 4 do
        for s=1,GetContainerNumSlots(b) do
            if used>=#free then return true end
            if b~=bag or s~=slot then
                local info=ItemInfo(b,s)
                if info and SameCategory(source,info) then
                    used=used+1
                    if not Attach(b,s,free[used]) then return true end
                end
            end
        end
    end
    return true
end
local function ChatOpen()
    if ChatEdit_GetActiveWindow then return ChatEdit_GetActiveWindow() and true end
    return ChatFrameEditBox and ChatFrameEditBox:IsVisible()
end
local function InstallBulkAttach()
    if ns.mailHooked or type(ContainerFrameItemButton_OnModifiedClick)~="function" then return end
    ns.mailHooked=true
    -- Post-hook: the native shift-click may have opened the split-stack box for this slot.
    hooksecurefunc("ContainerFrameItemButton_OnModifiedClick",function(self,button)
        if button=="LeftButton" and Enabled("mailBulkAttach") and IsShiftKeyDown() and not IsControlKeyDown() and not IsAltKeyDown()
            and SendMailFrame and SendMailFrame:IsVisible() and not CursorHasItem() and not ChatOpen() then
            local parent=self:GetParent(); local bag,slot=parent and parent:GetID(),self:GetID()
            if bag and bag>=0 and bag<=(NUM_BAG_SLOTS or 4) and ns.MailAttachCategory(bag,slot) then
                if StackSplitFrame and StackSplitFrame:IsShown() and StackSplitFrame.owner==self then StackSplitFrame:Hide() end
            end
        end
    end)
end

-- Send Mail recipient list: this realm's alts (same faction), guild members and recent recipients.
local ROWS,ROW_H,RECENT_MAX=12,16,15
local picker,pendingRecipient
local function Realm() return GetRealmName() or "?" end
local function MailDB()
    if type(EllesmereUIDB)~="table" then EllesmereUIDB={} end
    local db=EllesmereUIDB.mailRecipients
    if type(db)~="table" then db={}; EllesmereUIDB.mailRecipients=db end
    if type(db.alts)~="table" then db.alts={} end
    if type(db.recent)~="table" then db.recent={} end
    return db
end
function ns.MailRecordCharacter()
    local name=UnitName("player"); if not name or name=="" or name==UNKNOWNOBJECT then return end
    local alts=MailDB().alts; local realm=Realm()
    if type(alts[realm])~="table" then alts[realm]={} end
    local _,class=UnitClass("player")
    alts[realm][name]={class=class,level=UnitLevel("player"),faction=UnitFactionGroup("player")}
end
function ns.MailRemember(name)
    if type(name)~="string" then return end
    name=name:gsub("^%s+",""):gsub("%s+$","")
    if name=="" then return end
    local recent=MailDB().recent; local realm=Realm()
    if type(recent[realm])~="table" then recent[realm]={} end
    local list=recent[realm]
    for i=#list,1,-1 do if list[i]:lower()==name:lower() then table.remove(list,i) end end
    table.insert(list,1,name)
    for i=#list,RECENT_MAX+1,-1 do list[i]=nil end
end
function ns.MailRecipients(tab)
    local me,out=UnitName("player"),{}
    if tab=="alts" then
        local faction=UnitFactionGroup("player")
        for name,info in pairs(MailDB().alts[Realm()] or {}) do
            if name~=me and (not info.faction or info.faction==faction) then out[#out+1]={name=name,class=info.class,level=info.level,online=true} end
        end
        table.sort(out,function(a,b) return a.name<b.name end)
    elseif tab=="guild" then
        for i=1,(IsInGuild() and GetNumGuildMembers(true) or 0) do
            local name,_,_,level,_,_,_,_,online,_,class=GetGuildRosterInfo(i)
            if name and name~=me then out[#out+1]={name=name,class=class,level=level,online=online and true or false} end
        end
        table.sort(out,function(a,b)
            if a.online~=b.online then return a.online end
            return a.name<b.name
        end)
    else
        for _,name in ipairs(MailDB().recent[Realm()] or {}) do out[#out+1]={name=name,online=true} end
    end
    return out
end
local function RefreshPicker()
    if not picker then return end
    local list=ns.MailRecipients(picker.tab)
    picker.offset=math.max(0,math.min(picker.offset,#list-ROWS))
    for i,row in ipairs(picker.rows) do
        local e=list[picker.offset+i]
        if e then
            local c=e.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[e.class]
            row.text:SetText(e.name); row.text:SetTextColor(c and c.r or 1,c and c.g or 1,c and c.b or 1,e.online and 1 or .45)
            row.level:SetText(e.level and e.level>0 and tostring(e.level) or "")
            row.name=e.name; row:Show()
        else row.name=nil; row:Hide() end
    end
    if #list==0 then picker.empty:Show() else picker.empty:Hide() end
    for _,b in ipairs(picker.tabs) do
        if b.key==picker.tab then b.text:SetTextColor(.05,.82,.62) else b.text:SetTextColor(.8,.8,.8) end
    end
end
local function SelectTab(tab)
    picker.tab,picker.offset=tab,0
    if tab=="guild" and IsInGuild() and GuildRoster then GuildRoster() end
    RefreshPicker()
end
local function BuildPicker()
    local f=CreateFrame("Frame","EUI335QoLMailRecipients",SendMailFrame); picker=f; ns.mailPicker=f
    f:SetFrameStrata("DIALOG"); f:SetWidth(186); f:SetHeight(ROWS*ROW_H+34)
    f:EnableMouse(true); f:EnableMouseWheel(true)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    f:SetBackdropColor(.05,.05,.05,.97); f:SetBackdropBorderColor(.25,.25,.25,1)
    f:Hide(); f.tab,f.offset,f.rows,f.tabs="alts",0,{},{}
    for i,info in ipairs({{"alts","Alts"},{"guild","Guild"},{"recent","Recent"}}) do
        local b=CreateFrame("Button",nil,f); b:SetWidth(58); b:SetHeight(18); b.key=info[1]
        b:SetPoint("TOPLEFT",f,"TOPLEFT",4+(i-1)*60,-4)
        b.text=b:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); b.text:SetPoint("CENTER",b,"CENTER",0,0); b.text:SetText(info[2])
        b:SetScript("OnClick",function() SelectTab(info[1]) end)
        f.tabs[i]=b
    end
    for i=1,ROWS do
        local r=CreateFrame("Button",nil,f); r:SetHeight(ROW_H)
        r:SetPoint("TOPLEFT",f,"TOPLEFT",4,-26-(i-1)*ROW_H); r:SetPoint("RIGHT",f,"RIGHT",-4,0)
        r:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
        r.text=r:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); r.text:SetPoint("LEFT",r,"LEFT",4,0); r.text:SetJustifyH("LEFT")
        r.level=r:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); r.level:SetPoint("RIGHT",r,"RIGHT",-4,0)
        r:SetScript("OnClick",function(self)
            if not self.name then return end
            SendMailNameEditBox:SetText(self.name)
            if SendMailSubjectEditBox then SendMailSubjectEditBox:SetFocus() end
            f:Hide()
        end)
        f.rows[i]=r
    end
    f.empty=f:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); f.empty:SetPoint("TOP",f,"TOP",0,-44); f.empty:SetText("Nobody here yet")
    f:SetScript("OnMouseWheel",function(_,delta) f.offset=f.offset-delta*3; RefreshPicker() end)
    f:RegisterEvent("GUILD_ROSTER_UPDATE")
    f:SetScript("OnEvent",function() if f:IsShown() and f.tab=="guild" then RefreshPicker() end end)
end
function ns.ToggleMailRecipients()
    if not picker then BuildPicker() end
    if picker:IsShown() then picker:Hide(); return end
    picker:ClearAllPoints(); picker:SetPoint("TOPLEFT",ns.mailRecipientsButton,"BOTTOMLEFT",0,-2)
    picker:Show(); SelectTab(picker.tab)
end
local function InstallRecipients()
    if ns.mailRecipientsButton or not SendMailFrame or not SendMailNameEditBox then return end
    local b=CreateFrame("Button","EUI335QoLMailRecipientsButton",SendMailFrame); ns.mailRecipientsButton=b
    b:SetWidth(22); b:SetHeight(22); b:SetPoint("LEFT",SendMailNameEditBox,"RIGHT",2,0)
    b:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    b:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
    b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
    b:SetScript("OnClick",ns.ToggleMailRecipients)
    b:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText("Recipients")
        GameTooltip:AddLine("Your alts, guild members and recent names.",1,1,1,true); GameTooltip:Show()
    end)
    b:SetScript("OnLeave",function() GameTooltip:Hide() end)
    -- SendMail is not protected; the post-hook only notes the name for MAIL_SEND_SUCCESS.
    hooksecurefunc("SendMail",function(name) pendingRecipient=name end)
    local events=CreateFrame("Frame"); ns.mailRecipientEvents=events
    events:RegisterEvent("MAIL_SEND_SUCCESS"); events:RegisterEvent("MAIL_FAILED")
    events:SetScript("OnEvent",function(_,event)
        if event=="MAIL_SEND_SUCCESS" and Enabled("mailRecipients") then ns.MailRemember(pendingRecipient) end
        pendingRecipient=nil
    end)
end

function ns.ApplyMail()
    ns.MailRecordCharacter()
    if Enabled("mailRecipients") then InstallRecipients() end
    if ns.mailRecipientsButton then
        if Enabled("mailRecipients") then ns.mailRecipientsButton:Show() else ns.mailRecipientsButton:Hide(); if picker then picker:Hide() end end
    end
    if Enabled("mailBulkAttach") then InstallBulkAttach() end
    if not Enabled("mailOpenAll") then StopOpenAll() end
    if InboxFrame and not ns.mailButton then
        local b=CreateFrame("Button","EUI335QoLOpenAllMail",InboxFrame,"UIPanelButtonTemplate"); ns.mailButton=b
        ns.Size(b,120,25); b:SetPoint("CENTER",InboxFrame,"TOP",-22,-410); b:SetText("Open All")
        b:SetScript("OnClick",ns.MailOpenAll)
        local driver=CreateFrame("Frame"); ns.mailDriver=driver; driver:Hide()
        driver:SetScript("OnUpdate",ns.MailStep)
        local events=CreateFrame("Frame"); ns.mailEvents=events
        for _,event in ipairs({"MAIL_SHOW","MAIL_CLOSED","MAIL_INBOX_UPDATE","UI_ERROR_MESSAGE"}) do events:RegisterEvent(event) end
        events:SetScript("OnEvent",OnMailEvent)
    end
    UpdateButton()
end
