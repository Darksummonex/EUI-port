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
    local original=ContainerFrameItemButton_OnModifiedClick
    ContainerFrameItemButton_OnModifiedClick=function(self,button,...)
        if button=="LeftButton" and Enabled("mailBulkAttach") and IsShiftKeyDown() and not IsControlKeyDown() and not IsAltKeyDown()
            and SendMailFrame and SendMailFrame:IsVisible() and not CursorHasItem() and not ChatOpen() then
            local parent=self:GetParent(); local bag,slot=parent and parent:GetID(),self:GetID()
            if bag and bag>=0 and bag<=(NUM_BAG_SLOTS or 4) and ns.MailAttachCategory(bag,slot) then return end
        end
        return original(self,button,...)
    end
end

function ns.ApplyMail()
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
