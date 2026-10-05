-- Socket strip at the bottom of the character stats sidebar: every socket on
-- equipped gear, a flyout of matching bag gems and one-click socketing through
-- the client's own socketing calls.
local _,ns=...
if not ns.IsWrath then return end
local E=EllesmereUI
local flat="Interface\\Buttons\\WHITE8X8"
local P={}; ns.SocketPanel=P
local STRIP_H,ICON,PER_PAGE,FLYOUT_ROWS=40,26,6,8
local slotOrder={1,2,3,15,5,9,10,6,7,8,11,12,13,14,16,17,18}
local cacheKey,cacheList
local job,flyout
local function Own(obj) ns.owned[obj]=true; return obj end
local function Sockets()
    local Items=ns.Items
    local links={}
    for i,slot in ipairs(slotOrder) do links[i]=GetInventoryItemLink("player",slot) or "" end
    local key=table.concat(links,";")
    if key==cacheKey and cacheList then return cacheList end
    local list={}
    for i,slot in ipairs(slotOrder) do
        local link=links[i]~="" and links[i]
        if link then
            local fields=Items.Fields(link)
            local empty=Items.EmptySockets("SetInventoryItem","player",slot)
            local filled=0
            for f=3,6 do if fields[f]~=0 then filled=filled+1 end end
            local nextEmpty=1
            for index=1,filled+#empty do
                local entry={slot=slot,index=index,itemLink=link}
                if (fields[2+index] or 0)~=0 then
                    local gemLink
                    if GetItemGem then gemLink=select(2,GetItemGem(link,index)) end
                    entry.gemLink=gemLink
                    entry.icon=gemLink and (select(10,GetItemInfo(gemLink)) or (GetItemIcon and GetItemIcon(gemLink)))
                else entry.kind=empty[nextEmpty]; nextEmpty=nextEmpty+1 end
                list[#list+1]=entry
            end
        end
    end
    cacheKey,cacheList=key,list
    return list
end
function P.Invalidate() cacheKey,cacheList=nil,nil end
local gemClass,metaClass,simpleClass
local function Classes()
    if gemClass then return end
    gemClass,metaClass,simpleClass={Gem=true},{Meta=true},{Simple=true}
    local classes=GetAuctionItemClasses and {GetAuctionItemClasses()} or {}
    if classes[10] then gemClass[classes[10]]=true end
    local subs=GetAuctionItemSubClasses and {GetAuctionItemSubClasses(10)} or {}
    if subs[7] then metaClass[subs[7]]=true end
    if subs[8] then simpleClass[subs[8]]=true end
end
local function StatText(link)
    local stats=GetItemStats and GetItemStats(link)
    local parts={}
    for key,value in pairs(stats or {}) do
        local label=_G[key]
        if type(label)=="string" and type(value)=="number" then parts[#parts+1]="+"..value.." "..label end
    end
    table.sort(parts)
    if #parts>0 then return table.concat(parts,", ") end
    for i,line in ipairs(ns.Items.Lines("SetHyperlink",link:match("item:[%-%d:]+") or link) or {}) do
        if i>1 and line.text:find("^%+") then return line.text end
    end
    return ""
end
function P.BagGems(entry)
    Classes()
    local list={}
    if not (GetContainerNumSlots and GetContainerItemLink) then return list end
    local meta=entry.kind=="Meta"
    for bag=0,(NUM_BAG_SLOTS or 4) do
        for index=1,GetContainerNumSlots(bag) or 0 do
            local link=GetContainerItemLink(bag,index)
            if link then
                local name,_,quality,_,_,class,sub,_,_,icon=GetItemInfo(link)
                if name and gemClass[class] and not simpleClass[sub] and (metaClass[sub] and true or false)==meta then
                    local _,count=GetContainerItemInfo(bag,index)
                    list[#list+1]={bag=bag,index=index,link=link,name=name,quality=quality,icon=icon,count=count or 1,stats=StatText(link)}
                end
            end
        end
    end
    table.sort(list,function(a,b) if (a.quality or 0)~=(b.quality or 0) then return (a.quality or 0)>(b.quality or 0) end return a.name<b.name end)
    return list
end
local function Finish(success)
    if not job then return end
    job=nil
    if CursorHasItem and CursorHasItem() then ClearCursor() end
    if CloseSocketInfo then CloseSocketInfo() end
    if _G.ItemSocketingFrame and ItemSocketingFrame:IsShown() and HideUIPanel then HideUIPanel(ItemSocketingFrame) end
    P.Invalidate(); ns.RequestRefresh()
    if not success and UIErrorsFrame then UIErrorsFrame:AddMessage(E.L("The gem could not be socketed."),1,.1,.1) end
end
function P.Start(data)
    if InCombatLockdown() or job or not SocketInventoryItem then return end
    job={data=data,stage="open",started=GetTime()}
    if CursorHasItem and CursorHasItem() then ClearCursor() end
    SocketInventoryItem(data.entry.slot)
end
function P.Socket(entry,gem)
    if InCombatLockdown() then return end
    if flyout then flyout:Hide() end
    local data={entry=entry,bag=gem.bag,index=gem.index}
    if entry.gemLink and StaticPopup_Show then
        StaticPopupDialogs.EUI335_REPLACE_GEM=StaticPopupDialogs.EUI335_REPLACE_GEM or {text="%s",button1=ACCEPT or "Accept",button2=CANCEL or "Cancel",
            OnAccept=function(self) if self.data then P.Start(self.data) end end,timeout=0,whileDead=1,hideOnEscape=1}
        local dialog=StaticPopup_Show("EUI335_REPLACE_GEM",CONFIRM_ACCEPT_SOCKETS or "The socketed gem will be destroyed. Continue?")
        if type(dialog)=="table" then dialog.data=data end
        return
    end
    P.Start(data)
end
function P.OnSocketInfo()
    if not job or job.stage~="open" then return end
    local d=job.data
    job.stage="placed"
    PickupContainerItem(d.bag,d.index)
    ClickSocketButton(d.entry.index)
    if CursorHasItem and CursorHasItem() then Finish(false); return end
    AcceptSockets()
    job.stage,job.acceptedAt="accepted",GetTime()
end
function P.Tick()
    if not job then return end
    local now=GetTime()
    if job.stage=="accepted" and now-job.acceptedAt>.3 then Finish(true)
    elseif now-job.started>5 then Finish(false) end
end
local function Tooltip(self)
    local entry=self.entry; if not entry then return end
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
    if entry.gemLink then GameTooltip:SetHyperlink(entry.gemLink)
    else
        GameTooltip:SetText(_G["EMPTY_SOCKET_"..(entry.kind=="Prismatic" and "PRISMATIC" or (entry.kind or ""):upper())] or E.L("Empty Socket"),1,1,1)
        GameTooltip:AddLine(entry.itemLink,1,1,1)
    end
    GameTooltip:AddLine(E.L("Click to choose a gem from your bags"),.6,.8,1)
    GameTooltip:Show()
end
local function FlatFrame(kind,parent)
    local f=Own(CreateFrame(kind,nil,parent))
    f:SetBackdrop({bgFile=flat,edgeFile=flat,edgeSize=1})
    f:SetBackdropColor(.05,.05,.05,.97); f:SetBackdropBorderColor(.25,.25,.25,1)
    return f
end
local function BuildFlyout()
    flyout=FlatFrame("Frame",UIParent); P.flyout=flyout
    flyout:SetFrameStrata("DIALOG"); flyout:SetWidth(240); flyout:Hide()
    flyout:EnableMouse(true); flyout:EnableMouseWheel(true)
    flyout.rows={}
    for i=1,FLYOUT_ROWS do
        local row=Own(CreateFrame("Button",nil,flyout)); row:SetHeight(26)
        row:SetPoint("TOPLEFT",flyout,"TOPLEFT",4,-4-(i-1)*27); row:SetPoint("RIGHT",flyout,"RIGHT",-4,0)
        row.hl=Own(row:CreateTexture(nil,"BACKGROUND")); row.hl:SetTexture(flat); row.hl:SetAllPoints(row); row.hl:SetVertexColor(1,1,1,.08); row.hl:Hide()
        row.icon=Own(row:CreateTexture(nil,"ARTWORK")); row.icon:SetWidth(22); row.icon:SetHeight(22); row.icon:SetPoint("LEFT",row,"LEFT",2,0)
        row.icon:SetTexCoord(.08,.92,.08,.92)
        row.name=Own(row:CreateFontString(nil,"OVERLAY")); ns.ApplyFont(row.name,11)
        row.name:SetPoint("TOPLEFT",row.icon,"TOPRIGHT",6,0); row.name:SetPoint("RIGHT",row,"RIGHT",-2,0); row.name:SetJustifyH("LEFT")
        row.stats=Own(row:CreateFontString(nil,"OVERLAY")); ns.ApplyFont(row.stats,9)
        row.stats:SetPoint("BOTTOMLEFT",row.icon,"BOTTOMRIGHT",6,0); row.stats:SetPoint("RIGHT",row,"RIGHT",-2,0); row.stats:SetJustifyH("LEFT")
        row.stats:SetTextColor(.6,.9,.6,1)
        row:SetScript("OnEnter",function(self) self.hl:Show(); if self.gem then GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetHyperlink(self.gem.link); GameTooltip:Show() end end)
        row:SetScript("OnLeave",function(self) self.hl:Hide(); GameTooltip:Hide() end)
        row:SetScript("OnClick",function(self) if self.gem and flyout.entry then P.Socket(flyout.entry,self.gem) end end)
        flyout.rows[i]=row
    end
    flyout.empty=Own(flyout:CreateFontString(nil,"OVERLAY")); ns.ApplyFont(flyout.empty,11)
    flyout.empty:SetPoint("CENTER",flyout,"CENTER",0,0); flyout.empty:SetTextColor(.7,.7,.7,1)
    flyout:SetScript("OnMouseWheel",function(self,delta)
        self.offset=math.max(0,math.min(math.max(0,#self.gems-FLYOUT_ROWS),(self.offset or 0)-delta)); P.DrawFlyout()
    end)
end
function P.DrawFlyout()
    local gems=flyout.gems
    local rows=math.max(1,math.min(FLYOUT_ROWS,#gems))
    flyout:SetHeight(8+rows*27)
    for i,row in ipairs(flyout.rows) do
        local gem=gems[i+(flyout.offset or 0)]
        row.gem=gem
        if gem then
            row.icon:SetTexture(gem.icon); row.name:SetText((gem.count>1 and gem.count.."x " or "")..gem.name)
            row.name:SetTextColor(ns.Items.QualityColor(gem.quality)); row.stats:SetText(gem.stats); row:Show()
        else row:Hide() end
    end
    if #gems==0 then flyout.empty:SetText(E.L("No matching gems in your bags")); flyout.empty:Show() else flyout.empty:Hide() end
end
function P.OpenFlyout(button)
    if InCombatLockdown() then return end
    if not flyout then BuildFlyout() end
    if flyout:IsShown() and flyout.entry==button.entry then flyout:Hide(); return end
    flyout.entry,flyout.offset=button.entry,0
    flyout.gems=P.BagGems(button.entry)
    flyout:ClearAllPoints(); flyout:SetPoint("BOTTOMLEFT",button,"TOPLEFT",0,4)
    P.DrawFlyout(); flyout:Show()
end
local function Build(c)
    if c.socketStrip then return c.socketStrip end
    local strip=Own(CreateFrame("Frame",nil,c.sidebar)); c.socketStrip=strip
    strip:SetHeight(STRIP_H-6); strip:SetPoint("BOTTOMLEFT",c.sidebar,"BOTTOMLEFT",7,4); strip:SetPoint("BOTTOMRIGHT",c.sidebar,"BOTTOMRIGHT",-7,4)
    local line=Own(strip:CreateTexture(nil,"BACKGROUND")); line:SetTexture(flat); line:SetVertexColor(.25,.25,.25,1)
    line:SetHeight(1); line:SetPoint("TOPLEFT",strip,"TOPLEFT",0,2); line:SetPoint("TOPRIGHT",strip,"TOPRIGHT",0,2)
    strip.buttons={}
    for i=1,PER_PAGE do
        local b=FlatFrame("Button",strip); b:SetWidth(ICON); b:SetHeight(ICON)
        b:SetPoint("LEFT",strip,"LEFT",15+(i-1)*(ICON+4),-1)
        b.tex=Own(b:CreateTexture(nil,"ARTWORK")); b.tex:SetPoint("TOPLEFT",b,"TOPLEFT",1,-1); b.tex:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-1,1)
        b:SetScript("OnEnter",Tooltip); b:SetScript("OnLeave",function() GameTooltip:Hide() end)
        b:SetScript("OnClick",function(self) P.OpenFlyout(self) end)
        strip.buttons[i]=b
    end
    for _,spec in ipairs({{"prev","LEFT",0,"<",-1},{"next","RIGHT",0,">",1}}) do
        local b=Own(CreateFrame("Button",nil,strip)); b:SetWidth(13); b:SetHeight(ICON)
        b:SetPoint(spec[2],strip,spec[2],spec[3],-1)
        b.text=Own(b:CreateFontString(nil,"OVERLAY")); ns.ApplyFont(b.text,13); b.text:SetPoint("CENTER"); b.text:SetText(spec[4])
        local delta=spec[5]
        b:SetScript("OnClick",function() c.socketPage=(c.socketPage or 1)+delta; P.Update(c,true) end)
        strip[spec[1]]=b
    end
    c.frame:HookScript("OnHide",function() if flyout then flyout:Hide() end end)
    return strip
end
function P.Hide(c)
    if c and c.socketStrip then c.socketStrip:Hide() end
    if flyout then flyout:Hide() end
end
function P.Update(c,stats)
    local list=ns.GetValue("charSheetSocketPanel")~=false and ns.Items and Sockets() or {}
    if #list==0 then P.Hide(c); return end
    local strip=Build(c)
    c.scrollHeight=340-STRIP_H
    if not stats then strip:Hide(); if flyout then flyout:Hide() end; return end
    local pages=math.ceil(#list/PER_PAGE)
    c.socketPage=math.max(1,math.min(pages,c.socketPage or 1))
    for i,b in ipairs(strip.buttons) do
        local entry=list[(c.socketPage-1)*PER_PAGE+i]
        b.entry=entry
        if entry then
            if entry.gemLink then b.tex:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark"); b.tex:SetTexCoord(.08,.92,.08,.92); b:SetBackdropBorderColor(.25,.25,.25,1)
            else b.tex:SetTexture(ns.Items.SocketArt(entry.kind)); b.tex:SetTexCoord(0,1,0,1); b:SetBackdropBorderColor(1,.2,.2,1) end
            b:Show()
        else b:Hide() end
    end
    strip.prev.text:SetTextColor(1,1,1,c.socketPage>1 and 1 or .25)
    strip.next.text:SetTextColor(1,1,1,c.socketPage<pages and 1 or .25)
    if pages>1 then strip.prev:Show(); strip.next:Show() else strip.prev:Hide(); strip.next:Hide() end
    strip:Show()
end
local events=CreateFrame("Frame")
events:RegisterEvent("SOCKET_INFO_UPDATE"); events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:SetScript("OnEvent",function(_,event)
    if event=="SOCKET_INFO_UPDATE" then P.OnSocketInfo()
    else Finish(false); if flyout then flyout:Hide() end end
end)
events:SetScript("OnUpdate",P.Tick)
