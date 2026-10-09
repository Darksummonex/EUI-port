-- Retail EllesmereUI Bags on Wrath. Physical slot IDs and native item actions stay intact.
local ADDON_NAME,ns=...
local E=EllesmereUI
if not E or not E.Lite then return end
E._ModuleNS[ADDON_NAME]=ns
local addon=E.Lite.NewAddon(ADDON_NAME)
ns.addon,ns.IsWrath=addon,true
local defaults={profile={enhancedBags=true,enhancedBank=true,bagScale=1,bagItemIconZoom=.08,bagColumns=12,bankColumns=14,
    bagAutoSize=false,bagCatTitleSize=11,bagCountFontSize=11,itemlevelFontSize=12,showItemlevelInBags=true,
    bagHideEmptyCategories=true,bagSplitSetGearBySet=false,bagShowSetGearName=false,bagSetNameFontSize=9,
    bagMergeDuplicates=true,bagSidebarCollapsed=false,bankSidebarCollapsed=false,bagShowPinnedItems=true,bagShowRecentItems=true,
    bagPinnedInOneBag=true,bagRecentInOneBag=false,bagShowRecentClear=false,bagShowPinRecentTips=true,bagShowSortIcon=true,
    bagSortToBottom=false,bagHideRandomize=false,bagDefaultBagType="all",bankGroupByCategory=false,bankCategorySidebar=false,
    bankHideTabsInSidebar=false,bankHideEmptyWhenNested=false,bagArmoryGroupBySlot=false,bagCompactArmorySlotGroups=false,
    bagHideOneBagWarning=false,bagHideAddCategory=false,bagMoveNoShift=false,bagStackSplitter=false,enableGoldTracking=true,
    bagDesaturateJunkItems=false,bagDisplayBindType=false,bagBindTypeFontSize=11,
    bagIncludeKeyring=true,bagShowSlots=false,bagShowAltCounts=true,positions={},}}
ns.defaults=defaults
local views,bankOpen,nativeBank,pending,bankSnapshot={},false,false,false,nil
ns.views=views
ns.MEDIA="Interface\\AddOns\\EllesmereUIBags\\Media_335\\"
ns.WHITE="Interface\\Buttons\\WHITE8X8"
ns.SLOT,ns.SPACING,ns.HEADER_H,ns.FOOTER_H=34,4,35,28
function ns.IsBankOpen() return bankOpen end
function ns.GetSettings() return addon.db and addon.db.profile end
function ns.Size(f,w,h) f:SetWidth(w); f:SetHeight(h) end
function ns.Shown(f,show) if not f then return end; if show then f:Show() else f:Hide() end end
function ns.Font(fs,size)
    local path=(E.GetFontPath and E.GetFontPath("bags")) or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    local flag=((E.GetFontOutlineFlag and E.GetFontOutlineFlag("bags")) or "OUTLINE"):gsub(",?%s*SLUG","")
    if not fs:SetFont(path,size or 11,flag) then fs:SetFont("Fonts\\FRIZQT__.TTF",size or 11,"OUTLINE") end
end
function ns.Text(parent,size,layer)
    local fs=parent:CreateFontString(nil,layer or "OVERLAY"); ns.Font(fs,size); return fs
end
function ns.Solid(parent,layer,r,g,b,a)
    local t=parent:CreateTexture(nil,layer or "BACKGROUND"); t:SetTexture(r,g,b,a); return t
end
function ns.Accent()
    if E.GetAccentColor then local r,g,b=E.GetAccentColor(); if r then return r,g,b end end
    local c=E.ELLESMERE_GREEN; if c then return c.r,c.g,c.b end
    return .047,.824,.616
end
-- 1px inset edges (Retail CreateInsetBorder); SetTexture colours them on Wrath.
function ns.Border(f,r,g,b,a,layer)
    local edges={}
    for i=1,4 do edges[i]=f:CreateTexture(nil,layer or "OVERLAY"); edges[i]:SetTexture(ns.WHITE) end
    edges[1]:SetPoint("TOPLEFT",f,"TOPLEFT",0,0); edges[1]:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0)
    edges[2]:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",0,0); edges[2]:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",0,0)
    edges[3]:SetPoint("TOPLEFT",f,"TOPLEFT",0,0); edges[3]:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",0,0)
    edges[4]:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0); edges[4]:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",0,0)
    ns.BorderSize(edges,1); ns.BorderColor(edges,r,g,b,a)
    return edges
end
function ns.BorderColor(edges,r,g,b,a) for _,t in ipairs(edges) do t:SetVertexColor(r,g,b,a) end; edges.color={r,g,b,a} end
function ns.BorderSize(edges,px) edges[1]:SetHeight(px); edges[2]:SetHeight(px); edges[3]:SetWidth(px); edges[4]:SetWidth(px); edges.size=px end

-- Wrath has no C_Timer: one shared OnUpdate runs delayed callbacks.
local timers={}
local timerFrame=CreateFrame("Frame"); timerFrame:Hide()
timerFrame:SetScript("OnUpdate",function(self)
    local now=GetTime(); local due={}
    for i=#timers,1,-1 do if timers[i].at<=now then due[#due+1]=table.remove(timers,i).fn end end
    for i=#due,1,-1 do due[i]() end
    if #timers==0 then self:Hide() end
end)
function ns.After(delay,fn) timers[#timers+1]={at=GetTime()+(delay or 0),fn=fn}; timerFrame:Show() end
ns.timerFrame=timerFrame

-- Merging pauses while a panel that takes items (mail, trade, AH, bank) is open.
ns.panels={}
function ns.ItemPanelOpen() return next(ns.panels)~=nil end
local PANEL_EVENTS={MAIL_SHOW={"mail",true},MAIL_CLOSED={"mail"},TRADE_SHOW={"trade",true},TRADE_CLOSED={"trade"},
    AUCTION_HOUSE_SHOW={"auction",true},AUCTION_HOUSE_CLOSED={"auction"},GUILDBANKFRAME_OPENED={"guildbank",true},
    GUILDBANKFRAME_CLOSED={"guildbank"},BANKFRAME_OPENED={"bank",true},BANKFRAME_CLOSED={"bank"}}

-- Recent Items: session only, newest 15 item IDs whose bag count rose.
ns.recent={}
local lastTotals
function ns.TrackRecent()
    if GetContainerNumSlots(0)<=0 then return end
    local totals={}
    for bag=0,4 do
        for slot=1,GetContainerNumSlots(bag) do
            local link=GetContainerItemLink(bag,slot); local id=link and tonumber(link:match("item:(%d+)"))
            if id then local _,count=GetContainerItemInfo(bag,slot); totals[id]=(totals[id] or 0)+(count or 1) end
        end
    end
    if lastTotals and not ns.sorting then
        local now=GetTime()
        for id,n in pairs(totals) do if n>(lastTotals[id] or 0) then ns.recent[id]=now end end
        local list={}; for id,at in pairs(ns.recent) do list[#list+1]={id=id,at=at} end
        table.sort(list,function(a,b) return a.at>b.at end)
        for i=16,#list do ns.recent[list[i].id]=nil end
    end
    lastTotals=totals
end
function ns.ClearRecent() wipe(ns.recent); ns.Refresh("bags") end

local function SavePosition(kind)
    local p=ns.GetSettings(); local f=views[kind]; if not p or not f then return end
    local point,_,relPoint,x,y=f:GetPoint(1); p.positions[kind]={point=point,relPoint=relPoint,x=x,y=y}
end
ns.SavePosition=SavePosition
local function RestoreBank()
    if not bankSnapshot or not BankFrame then return end
    BankFrame:ClearAllPoints(); for _,point in ipairs(bankSnapshot.points) do BankFrame:SetPoint(unpack(point)) end
    BankFrame:SetAlpha(bankSnapshot.alpha)
    if BankFrame.SetClampedToScreen then BankFrame:SetClampedToScreen(bankSnapshot.clamped) end
    bankSnapshot=nil
end
ns.RestoreBank=RestoreBank
local function SuppressBank()
    if not BankFrame or bankSnapshot then return end
    bankSnapshot={alpha=BankFrame:GetAlpha(),points={},clamped=BankFrame:IsClampedToScreen()}
    for i=1,BankFrame:GetNumPoints() do bankSnapshot.points[i]={BankFrame:GetPoint(i)} end
    -- Hiding BankFrame would run its OnHide and close the server bank session.
    BankFrame:SetAlpha(0); BankFrame:SetClampedToScreen(false); BankFrame:ClearAllPoints(); BankFrame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",-2000,-2000)
end
function ns.UseNativeBank()
    nativeBank=true; RestoreBank()
    if views.bank then views.bank._restoring=true; views.bank:Hide(); views.bank._restoring=false end
    if BankFrame and bankOpen then BankFrame:Show() end
end
function ns.IsNativeBank() return nativeBank end
function ns.Refresh(kind)
    local p,f=ns.GetSettings(),views[kind]; if not p or not f or not f:IsShown() then return end
    if kind=="bank" and ns.IsLiveView(f) and nativeBank then return end
    if InCombatLockdown() then pending=true; return end
    ns.Render(f)
end
function ns.RefreshAll() ns.Refresh("bags"); ns.Refresh("bank") end
function ns.Show(kind,keepSelection)
    local p=ns.GetSettings(); if not p then return end
    if kind=="bank" and not p.enhancedBank then return end
    if kind=="bags" and not p.enhancedBags then return end
    if InCombatLockdown() and kind~="bags" then return end
    local f=views[kind]; if f then
        -- Combat opens the existing layout; refresh and selection changes wait.
        if not keepSelection and not InCombatLockdown() then ns.UseCurrentView(kind) end
        if kind=="bank" and ns.IsLiveView(f) and nativeBank then return end
        local first=not f:IsShown()
        f:Show(); f.search:ClearFocus(); ns.Refresh(kind)
        if first and kind=="bags" and ns.OnFirstOpen then ns.OnFirstOpen(f) end
    end
end
function ns.OpenCharacterBank()
    if InCombatLockdown() then return end
    nativeBank=false; ns.UseCurrentView("bank")
    if bankOpen then ns.Apply() else ns.Show("bank",true) end
end
function ns.Toggle() local f=views.bags; if not f then return end; if f:IsShown() then f:Hide() else ns.Show("bags") end end
function ns.Apply()
    local p=ns.GetSettings(); if not p then return end
    if InCombatLockdown() then pending=true; return end; pending=false
    for _,kind in ipairs({"bags","bank"}) do
        local f=views[kind] or ns.MakeView(kind); f:SetScale(p.bagScale)
        local pos=p.positions[kind]; f:ClearAllPoints()
        if pos then f:SetPoint(pos.point,UIParent,pos.relPoint,pos.x,pos.y)
        elseif kind=="bags" then f:SetPoint("BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",-50,50)
        else f:SetPoint("TOPLEFT",UIParent,"TOPLEFT",50,-120) end
        if not p[kind=="bags" and "enhancedBags" or "enhancedBank"] then f._restoring=true; f:Hide(); f._restoring=false end
        ns.Refresh(kind)
    end
    if bankOpen and p.enhancedBank and not nativeBank then SuppressBank(); ns.Show("bank",true) else RestoreBank() end
    if ns.TakeOverBags then ns.TakeOverBags() end
end
function ns.ResetPositions() local p=ns.GetSettings(); if p then p.positions={}; ns.Apply() end end
-- The replaced globals stay insecure until /reload, so they are only installed
-- once Enable Bags is on; with it off the native bag functions stay untouched.
function ns.TakeOverBags()
    local function Active() local p=ns.GetSettings(); return p and p.enhancedBags end
    if ns.bagsTakenOver or not Active() then return end
    ns.bagsTakenOver=true
    for _,name in ipairs({"ToggleAllBags","ToggleBackpack","OpenAllBags","OpenBackpack","CloseAllBags","CloseBackpack","ToggleBag","OpenBag","CloseBag","IsBagOpen"}) do
        local native=_G[name]
        if type(native)=="function" then
            local entry=name
            _G[name]=function(...)
                local bag=...; local specific=entry=="ToggleBag" or entry=="OpenBag" or entry=="CloseBag" or entry=="IsBagOpen"
                if not Active() or (specific and not (type(bag)=="number" and (bag>=0 and bag<=4 or bag==-2 and ns.GetSettings().bagIncludeKeyring))) then return native(...) end
                if entry=="IsBagOpen" then return views.bags and views.bags:IsShown() or false end
                if entry:find("Close",1,true)==1 then views.bags:Hide()
                elseif entry:find("Toggle",1,true)==1 then ns.Toggle() else ns.Show("bags") end
            end
        end
    end
end
function addon:OnInitialize()
    addon.db=E.Lite.NewDB("EllesmereUIBagsDB",defaults); ns.db=addon.db; E._bagsDB=addon.db
    _G._EBAGS_RefreshAll=ns.Apply
    _G.EUI_Bags={RefreshTextSizes=function() ns.Apply() end,RefreshInventory=function() ns.RefreshAll() end,
        ClearRecentItems=function() ns.ClearRecent() end}
    _G.EUI_BankFrame={RefreshTextSizes=function() ns.Apply() end,RefreshInventory=function() ns.Refresh("bank") end}
    SLASH_EUI335BAGS1="/ebags"; SlashCmdList.EUI335BAGS=function() ns.Toggle() end
end
function addon:OnEnable()
    ns.CM:Seed(); ns.InventoryStore(); ns.CaptureInventory("bags"); ns.TrackRecent(); ns.InitializeBroker(); ns.Apply()
    if UISpecialFrames then for _,kind in ipairs({"bags","bank"}) do UISpecialFrames[#UISpecialFrames+1]="EUI335Inventory_"..kind end end
    if E.RegisterUnlockElements and E.MakeUnlockElement then
        local elements={}
        for i,kind in ipairs({"bags","bank"}) do local k=kind
            elements[#elements+1]=E.MakeUnlockElement({key="EUI335_"..kind,label=kind=="bank" and "Bank" or "Bags",group="Bags",order=800+i,noResize=true,noAnchorTo=true,
                getFrame=function() return views[k] end,getSize=function() local f=views[k]; return f and f:GetWidth() or 420,f and f:GetHeight() or 180 end,
                isHidden=function() return not views[k] or not views[k]:IsShown() end,
                savePos=function(_,point,relPoint,x,y) local p=ns.GetSettings(); if p then p.positions[k]={point=point,relPoint=relPoint,x=x,y=y} end end,
                loadPos=function() local p=ns.GetSettings(); return p and p.positions[k] end,
                clearPos=function() local p=ns.GetSettings(); if p then p.positions[k]=nil; ns.Apply() end end,applyPos=ns.Apply,
            })
        end
        E:RegisterUnlockElements(elements,ADDON_NAME)
    end
    local events=CreateFrame("Frame"); ns.events=events
    for _,event in ipairs({"ADDON_LOADED","PLAYER_ENTERING_WORLD","PLAYER_LOGOUT","PLAYER_REGEN_ENABLED","BAG_UPDATE","BAG_UPDATE_COOLDOWN",
        "ITEM_LOCK_CHANGED","PLAYER_MONEY","BANKFRAME_OPENED","BANKFRAME_CLOSED","PLAYERBANKSLOTS_CHANGED","PLAYERBANKBAGSLOTS_CHANGED",
        "EQUIPMENT_SETS_CHANGED","CURRENCY_DISPLAY_UPDATE","PLAYER_LEVEL_UP","SKILL_LINES_CHANGED","MAIL_SHOW","MAIL_CLOSED","TRADE_SHOW",
        "TRADE_CLOSED","AUCTION_HOUSE_SHOW","AUCTION_HOUSE_CLOSED","GUILDBANKFRAME_OPENED","GUILDBANKFRAME_CLOSED"}) do events:RegisterEvent(event) end
    events:SetScript("OnEvent",function(_,event)
        if event=="ADDON_LOADED" then ns.InitializeBroker(); return end
        local panel=PANEL_EVENTS[event]
        if panel then ns.panels[panel[1]]=panel[2] end
        if event=="EQUIPMENT_SETS_CHANGED" then ns.CM:OnEquipmentSetsChanged() end
        if event=="PLAYER_LEVEL_UP" or event=="SKILL_LINES_CHANGED" then if ns.ClearScanCache then ns.ClearScanCache() end end
        if event=="PLAYER_ENTERING_WORLD" then ns.InitializeBroker() end
        if event=="PLAYER_ENTERING_WORLD" or event=="CURRENCY_DISPLAY_UPDATE" then ns.CaptureCurrencies() end
        if event=="BAG_UPDATE" then ns.TrackRecent() end
        if event~="BANKFRAME_CLOSED" and event~="BAG_UPDATE_COOLDOWN" and event~="ITEM_LOCK_CHANGED" and not panel then ns.CaptureInventory("bags"); if bankOpen then ns.CaptureInventory("bank") end end
        if event=="BANKFRAME_OPENED" then bankOpen=true; nativeBank=false; ns.CaptureInventory("bank"); ns.UseCurrentView("bank"); if views.bank then ns.ResetView(views.bank) end; ns.Apply()
        elseif event=="BANKFRAME_CLOSED" then bankOpen=false; nativeBank=false; RestoreBank(); if views.bank then views.bank._restoring=true; views.bank:Hide(); views.bank._restoring=false end; ns.Refresh("bags")
        elseif event=="PLAYER_ENTERING_WORLD" or (event=="PLAYER_REGEN_ENABLED" and pending) then ns.Apply()
        elseif not ns.sorting then ns.RefreshAll() end
    end)
    if BankFrame and BankFrame.HookScript then BankFrame:HookScript("OnShow",function() local p=ns.GetSettings(); if bankOpen and p and p.enhancedBank and not nativeBank and not InCombatLockdown() then SuppressBank() end end) end
    if hooksecurefunc and ns.HookSplitter then ns.HookSplitter() end
    -- GetItemInfo can be uncached on Wrath; bounded visible retries, no modern event.
    local elapsed,retries,recordElapsed=0,0,0
    events:SetScript("OnUpdate",function(_,dt)
        recordElapsed=recordElapsed+dt
        if recordElapsed>=5 then recordElapsed=0; ns.CaptureInventory("bags"); if bankOpen then ns.CaptureInventory("bank") end end
        elapsed=elapsed+dt; if elapsed<.5 then return end; elapsed=0
        local needed=false; for _,f in pairs(views) do if f:IsShown() and f._uncached then needed=true end end
        if needed and retries<20 then retries=retries+1; ns.RefreshAll() elseif not needed then retries=0 end
    end)
end
