-- Unified Wrath inventory. Physical slot IDs and native item actions stay intact.
local ADDON_NAME,ns=...
local E=EllesmereUI
if not E or not E.Lite then return end
E._ModuleNS[ADDON_NAME]=ns
local addon=E.Lite.NewAddon(ADDON_NAME)
ns.addon,ns.IsWrath=addon,true
local defaults={profile={enhancedBags=true,enhancedBank=true,bagScale=1,bagColumns=12,bagIconSize=34,bagSpacing=4,
    bagItemIconZoom=.08,bagCountFontSize=11,itemlevelFontSize=11,bagCatTitleSize=11,
    showItemlevelInBags=true,bagDesaturateJunkItems=false,bagGroupByCategory=true,bagHideEmptySlots=false,
    bagIncludeKeyring=true,bagSortView=false,bagShowSlots=true,bagShowAltCounts=true,bagCategoryFilter=0,bgAlpha=.95,positions={},}}
ns.defaults=defaults
local views,bankOpen,nativeBank,pending,bankSnapshot={},false,false,false,nil
ns.views=views
function ns.IsBankOpen() return bankOpen end
local white="Interface\\Buttons\\WHITE8X8"
local categories={"Weapons","Armor","Other Consumables","Crafting Reagents","Quest Items","Miscellaneous","Junk","Empty Slots","Food & Drink","Potions","Flasks & Elixirs"}
ns.categoryNames=categories
local itemTypes={consumable="Consumable",trade="Trade Goods",reagent="Reagent",quest="Quest",food="Food & Drink",potion="Potion",flask="Flask",elixir="Elixir"}
local function RefreshItemTypes()
    -- Native cached items supply localized class/subclass names on Wrath.
    for _,sample in ipairs({{117,"consumable","food"},{118,"consumable","potion"},{13510,"consumable","flask"},{9233,"consumable","elixir"},{2589,"trade"},{17020,"reagent"},{29443,"quest"}}) do
        local _,_,_,_,_,class,subclass=GetItemInfo(sample[1])
        if class then itemTypes[sample[2]]=class end
        if sample[3] and subclass then itemTypes[sample[3]]=subclass end
    end
end
local function Size(f,w,h) f:SetWidth(w); f:SetHeight(h) end
function ns.GetSettings() return addon.db and addon.db.profile end
local function Font(fs,size)
    local path=(E.GetFontPath and E.GetFontPath("bags")) or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    local flag=((E.GetFontOutlineFlag and E.GetFontOutlineFlag("bags")) or "OUTLINE"):gsub(",?%s*SLUG","")
    if not fs:SetFont(path,size or 11,flag) then fs:SetFont("Fonts\\FRIZQT__.TTF",11,"OUTLINE") end
end
local function Backdrop(f,alpha)
    f:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1}); f:SetBackdropColor(.025,.04,.045,alpha or .95); f:SetBackdropBorderColor(.06,.45,.35,1)
end
local function Text(parent,size)
    local f=parent:CreateFontString(nil,"OVERLAY"); Font(f,size); return f
end
local function Button(parent,label,width,fn)
    local b=CreateFrame("Button",nil,parent); Size(b,width,20); Backdrop(b,.8)
    b.label=Text(b,11); b.label:SetPoint("CENTER",b,"CENTER",0,0); b.label:SetText(label); b:SetScript("OnClick",fn); return b
end
local function SavePosition(kind)
    local p=ns.GetSettings(); local f=views[kind]; if not p or not f then return end
    local point,relative,relPoint,x,y=f:GetPoint(1); p.positions[kind]={point=point,relPoint=relPoint,x=x,y=y}
end
local function RestoreBank()
    if not bankSnapshot or not BankFrame then return end
    BankFrame:ClearAllPoints(); for _,point in ipairs(bankSnapshot.points) do BankFrame:SetPoint(unpack(point)) end
    BankFrame:SetAlpha(bankSnapshot.alpha)
    if BankFrame.SetClampedToScreen then BankFrame:SetClampedToScreen(bankSnapshot.clamped) end
    bankSnapshot=nil
end
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
local function MakeView(kind)
    local f=CreateFrame("Frame","EUI335Inventory_"..kind,UIParent); f:Hide(); f:SetFrameStrata("HIGH")
    f:SetMovable(true); f:SetClampedToScreen(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function(self) if not InCombatLockdown() then self:StartMoving() end end)
    f:SetScript("OnDragStop",function(self) self:StopMovingOrSizing(); SavePosition(kind) end)
    f.pool,f.bagParents,f.headings={}, {}, {}
    f.scroll=CreateFrame("ScrollFrame","EUI335InventoryScroll_"..kind,f,"UIPanelScrollFrameTemplate")
    f.scroll:SetPoint("TOPLEFT",f,"TOPLEFT",0,-62); f.scroll:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-25,32)
    f.content=CreateFrame("Frame",nil,f.scroll); Size(f.content,400,200); f.scroll:SetScrollChild(f.content)
    f.title=Text(f,13); f.title:SetPoint("TOPLEFT",f,"TOPLEFT",10,-10); f.title:SetText(kind=="bank" and "Bank" or "Bags")
    f.close=Button(f,"X",22,function() f:Hide() end); f.close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-7,-7)
    f.search=CreateFrame("EditBox",nil,f); Size(f.search,180,22); f.search:SetPoint("TOPLEFT",f,"TOPLEFT",10,-33)
    Font(f.search,11); f.search:SetAutoFocus(false); f.search:SetTextInsets(5,5,0,0); Backdrop(f.search,.9)
    f.search:SetScript("OnTextChanged",function() if f:IsShown() then ns.Refresh(kind) end end)
    f.search:SetScript("OnEscapePressed",function(self) self:ClearFocus(); self:SetText("") end)
    f.search:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
    f.footer=Text(f,11); f.footer:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",10,10)
    f.footer:SetHeight(16)
    f.footerHover=CreateFrame("Frame",nil,f); f.footerHover:SetAllPoints(f.footer); f.footerHover:EnableMouse(true)
    f.footerHover:SetScript("OnEnter",function(self)
        ns.CaptureMoney(); GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText("EllesmereUI Bags")
        ns.AddGoldTooltip(GameTooltip); GameTooltip:Show()
    end)
    f.footerHover:SetScript("OnLeave",function() GameTooltip:Hide() end)
    if kind=="bank" then f.native=Button(f,"Native Bank",95,ns.UseNativeBank); f.native:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-8,7)
    else f.settings=Button(f,"Options",65,function() if E.EnsureOptionsLoaded then E.EnsureOptionsLoaded() end; E:ShowModule(ADDON_NAME) end); f.settings:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-8,7) end
    f:SetScript("OnHide",function(self)
        self.search:ClearFocus()
        if self.selector then self.selector:Hide() end
        if kind=="bank" and bankOpen and not self._restoring then RestoreBank(); if CloseBankFrame then CloseBankFrame() end end
    end)
    views[kind]=f; ns.BuildInventoryControls(f,kind); return f
end
local function Category(link,quality,itemType,equip,subclass)
    if not link then return 8 end
    if quality==0 then return 7 end
    if equip and equip~="" then if equip:find("WEAPON",1,true) or equip=="INVTYPE_2HWEAPON" or equip=="INVTYPE_RANGED" or equip=="INVTYPE_RANGEDRIGHT" or equip=="INVTYPE_THROWN" then return 1 end; return 2 end
    if itemType==itemTypes.consumable then
        if subclass==itemTypes.food then return 9 end
        if subclass==itemTypes.potion then return 10 end
        if subclass==itemTypes.flask or subclass==itemTypes.elixir then return 11 end
        return 3
    end
    if itemType==itemTypes.trade or itemType==itemTypes.reagent then return 4 end
    if itemType==itemTypes.quest or itemType=="Quest Item" then return 5 end
    return 6
end
ns.Category=Category
local function ItemButton(f,bag,slot)
    local readonly=not ns.IsLiveView(f); local pool=readonly and f.savedPool or f.pool
    local key=bag..":"..slot; local b=pool[key]; if b then return b end
    local parent=f.bagParents[bag]
    if not parent then parent=CreateFrame("Frame",nil,f.content); parent:SetID(bag); parent:SetAllPoints(f.content); f.bagParents[bag]=parent end
    local name="EUI335Item_"..(readonly and "Saved" or "")..(f==views.bank and "Bank" or "Bags").."_"..(bag<0 and "N"..(-bag) or bag).."_"..slot
    b=CreateFrame(readonly and "Button" or "CheckButton",name,parent,not readonly and (bag==-1 and "BankItemButtonGenericTemplate" or "ContainerFrameItemButtonTemplate") or nil)
    b:SetID(slot); b.bagID=bag; b.slotID=slot
    b.icon=_G[name.."IconTexture"] or b:GetNormalTexture() or b:CreateTexture(nil,"ARTWORK")
    b.stackCount=_G[name.."Count"] or Text(b,11); b.level=Text(b,11); b.level:SetPoint("TOPLEFT",b,"TOPLEFT",2,-2)
    b.cooldown=_G[name.."Cooldown"]
    if not b.cooldown then b.cooldown=CreateFrame("Cooldown",name.."Cooldown",b,"CooldownFrameTemplate"); b.cooldown:SetAllPoints(b) end
    b.stackCount:ClearAllPoints(); b.stackCount:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-2,2)
    b.stackCount:SetDrawLayer("OVERLAY"); b.stackCount:SetTextColor(1,1,1,1)
    b.shade=b:CreateTexture(nil,"OVERLAY"); b.shade:SetAllPoints(b); b.shade:SetTexture(0,0,0,.75); b.shade:Hide()
    b:SetNormalTexture(""); b:SetPushedTexture("")
    if not readonly then b:SetCheckedTexture("") end
    b:SetHighlightTexture(white); b:GetHighlightTexture():SetAlpha(.2)
    b:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        if readonly then if self.link then GameTooltip:SetHyperlink(self.link) else GameTooltip:SetText("Empty slot") end; GameTooltip:AddLine("Saved view - read only",1,.8,.2)
        else GameTooltip:SetBagItem(bag,slot) end
        ns.AddOwnershipTooltip(self.link); GameTooltip:Show()
    end)
    b:SetScript("OnLeave",function() GameTooltip:Hide() end)
    -- Keep template OnClick/OnDragStart/OnReceiveDrag: they use parent bag ID
    -- and button slot ID for pickup, equip, split stacks, trade and purchases.
    pool[key]=b; return b
end
function ns.Refresh(kind)
    local p,f=ns.GetSettings(),views[kind]; if not p or not f or not f:IsShown() then return end
    if kind=="bank" and ns.IsLiveView(f) and nativeBank then return end
    if InCombatLockdown() then pending=true; return end
    local rows,free,total,uncached,snapshot,record=ns.ViewItems(f); local items={}
    RefreshItemTypes()
    for _,item in ipairs(rows) do if not p.bagHideEmptySlots or item.link then
        item.category=Category(item.link,item.quality,item.itemType,item.equip,item.itemSubType)
        if not p.bagCategoryFilter or p.bagCategoryFilter==0 or p.bagCategoryFilter==item.category then items[#items+1]=item end
    end end
    if p.bagGroupByCategory or p.bagSortView then table.sort(items,function(a,b)
        if p.bagGroupByCategory and a.category~=b.category then return a.category<b.category end
        if p.bagSortView and a.name~=b.name then return a.name<b.name end
        if a.bag~=b.bag then return a.bag<b.bag end; return a.slot<b.slot
    end) end
    for _,b in pairs(f.pool) do b:Hide() end
    for _,b in pairs(f.savedPool) do b:Hide() end
    for _,heading in ipairs(f.headings) do heading:Hide() end
    local columns=math.max(4,math.min(20,math.floor(p.bagColumns))); local size=math.max(20,math.min(60,p.bagIconSize)); local spacing=p.bagSpacing
    local width=math.max(270,columns*(size+spacing)-spacing+45); local x,y,current,headingIndex=0,0,nil,0
    local query=string.lower(f.search:GetText() or "")
    for _,item in ipairs(items) do
        if p.bagGroupByCategory and current~=item.category then
            if current then if x>0 then y=y+size+spacing end; y=y+4 end
            current=item.category; x=0; headingIndex=headingIndex+1
            local h=f.headings[headingIndex] or Text(f.content,p.bagCatTitleSize); f.headings[headingIndex]=h
            Font(h,p.bagCatTitleSize); h:ClearAllPoints(); h:SetPoint("TOPLEFT",f.content,"TOPLEFT",10,-y); h:SetText(categories[current]); h:Show(); y=y+18
        end
        local b=ItemButton(f,item.bag,item.slot); b:ClearAllPoints(); b:SetPoint("TOPLEFT",f.content,"TOPLEFT",10+x*(size+spacing),-y); Size(b,size,size)
        Backdrop(b,.65)
        local c=ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[item.quality]; b:SetBackdropBorderColor(c and c.r or .2,c and c.g or .2,c and c.b or .2,1)
        if b.icon then b.icon:ClearAllPoints(); b.icon:SetPoint("TOPLEFT",b,"TOPLEFT",1,-1); b.icon:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-1,1); b.icon:SetTexture(item.icon or "Interface\\PaperDoll\\UI-Backpack-EmptySlot"); local z=p.bagItemIconZoom; b.icon:SetTexCoord(z,1-z,z,1-z); b.icon:SetDesaturated((item.locked or (p.bagDesaturateJunkItems and item.quality==0)) and true or false) end
        Font(b.stackCount,p.bagCountFontSize); Font(b.level,p.itemlevelFontSize)
        -- Native item/refund handlers expect count to be a number.
        b.count=item.count or 0
        -- Wrath ItemButtonTemplate starts with its Count FontString hidden.
        -- SetText alone does not reveal it; apply visibility for both pools.
        if item.link and b.count>1 then b.stackCount:SetText(tostring(b.count)); b.stackCount:Show()
        else b.stackCount:SetText(""); b.stackCount:Hide() end
        b.level:SetText(p.showItemlevelInBags and item.equip and item.equip~="" and item.level and tostring(item.level) or "")
        local start,duration,enabled=0,0,0
        if ns.IsLiveView(f) then start,duration,enabled=GetContainerItemCooldown(item.bag,item.slot) end
        if CooldownFrame_SetTimer then CooldownFrame_SetTimer(b.cooldown,start or 0,duration or 0,enabled or 0) end
        b.link=item.link; b.hasItem=item.link~=nil; b.readable=item.readable; b.lootable=item.lootable; b.locked=item.locked
        local match=query=="" or string.lower(item.name):find(query,1,true) or (item.link and tostring(item.link):find(query,1,true))
        if match then b.shade:Hide() else b.shade:Show() end
        b:Show(); x=x+1; if x>=columns then x=0; y=y+size+spacing end
    end
    if x>0 then y=y+size+spacing end
    Size(f.content,width-25,math.max(1,y))
    local available=math.max(220,(GetScreenHeight and GetScreenHeight() or 1080)/p.bagScale-120)
    Size(f,width,math.max(180,math.min(available,y+(p.bagShowSlots and 130 or 94)))); f.search:SetWidth(math.max(64,width-(kind=="bags" and 202 or 111)))
    local _,current=ns.CurrentCharacter(); local live=ns.IsLiveView(f)
    f.title:SetText((f.selectedName or current).." - "..(kind=="bank" and "Bank" or "Bags")..(live and "" or " (Saved)")); f.title:SetWidth(width-45)
    local money=ns.MoneyText(record and record.money or 0)
    f.footer:SetText(not snapshot and "Contents not ready - visit the bank to record it" or free.." / "..total.." free   "..(kind=="bags" and money or live and "" or "Saved "..date("%Y-%m-%d %H:%M",snapshot.updated)))
    f.footer:SetWidth(math.max(100,width-(kind=="bank" and live and 118 or kind=="bags" and 88 or 20)))
    ns.RefreshInventoryControls(f,snapshot)
    f._uncached=uncached
end
function ns.Show(kind,keepSelection)
    local p=ns.GetSettings(); if not p then return end
    if kind=="bank" and not p.enhancedBank then return end
    if kind=="bags" and not p.enhancedBags then return end
    if InCombatLockdown() then return end
    local f=views[kind]; if f then
        if not keepSelection then ns.UseCurrentView(kind) end
        if kind=="bank" and ns.IsLiveView(f) and nativeBank then return end
        f:Show(); f.search:ClearFocus(); ns.Refresh(kind)
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
    for i,kind in ipairs({"bags","bank"}) do
        local f=views[kind] or MakeView(kind); Backdrop(f,p.bgAlpha); f:SetScale(p.bagScale)
        local pos=p.positions[kind]; f:ClearAllPoints()
        if pos then f:SetPoint(pos.point,UIParent,pos.relPoint,pos.x,pos.y) else f:SetPoint("BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",-40-(i-1)*470,100) end
        if not p[kind=="bags" and "enhancedBags" or "enhancedBank"] then f._restoring=true; f:Hide(); f._restoring=false end
        ns.Refresh(kind)
    end
    if bankOpen and p.enhancedBank and not nativeBank then SuppressBank(); ns.Show("bank",true) else RestoreBank() end
end
function ns.ResetPositions() local p=ns.GetSettings(); if p then p.positions={}; ns.Apply() end end
local function TakeOverBags()
    local function Active() local p=ns.GetSettings(); return p and p.enhancedBags and not InCombatLockdown() end
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
    _G.EUI_Bags={RefreshTextSizes=function() ns.Apply() end,RefreshInventory=function() ns.Refresh("bags"); ns.Refresh("bank") end}
    _G.EUI_BankFrame={RefreshTextSizes=function() ns.Apply() end,RefreshInventory=function() ns.Refresh("bank") end}
    SLASH_EUI335BAGS1="/ebags"; SlashCmdList.EUI335BAGS=function() ns.Toggle() end
end
function addon:OnEnable()
    ns.InventoryStore(); ns.CaptureInventory("bags"); ns.InitializeBroker(); ns.Apply(); TakeOverBags()
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
    for _,event in ipairs({"ADDON_LOADED","PLAYER_ENTERING_WORLD","PLAYER_LOGOUT","PLAYER_REGEN_ENABLED","BAG_UPDATE","BAG_UPDATE_COOLDOWN","ITEM_LOCK_CHANGED","PLAYER_MONEY","BANKFRAME_OPENED","BANKFRAME_CLOSED","PLAYERBANKSLOTS_CHANGED","PLAYERBANKBAGSLOTS_CHANGED"}) do events:RegisterEvent(event) end
    events:SetScript("OnEvent",function(_,event)
        if event=="ADDON_LOADED" then
            ns.InitializeBroker()
            return
        end
        if event=="PLAYER_ENTERING_WORLD" then ns.InitializeBroker() end
        if event~="BANKFRAME_CLOSED" and event~="BAG_UPDATE_COOLDOWN" and event~="ITEM_LOCK_CHANGED" then ns.CaptureInventory("bags"); if bankOpen then ns.CaptureInventory("bank") end end
        if event=="BANKFRAME_OPENED" then bankOpen=true; nativeBank=false; ns.CaptureInventory("bank"); ns.UseCurrentView("bank"); ns.Apply()
        elseif event=="BANKFRAME_CLOSED" then bankOpen=false; nativeBank=false; RestoreBank(); if views.bank then views.bank._restoring=true; views.bank:Hide(); views.bank._restoring=false end
        elseif event=="PLAYER_ENTERING_WORLD" or (event=="PLAYER_REGEN_ENABLED" and pending) then ns.Apply()
        else ns.Refresh("bags"); ns.Refresh("bank") end
    end)
    if BankFrame and BankFrame.HookScript then BankFrame:HookScript("OnShow",function() local p=ns.GetSettings(); if bankOpen and p and p.enhancedBank and not nativeBank and not InCombatLockdown() then SuppressBank() end end) end
    -- GetItemInfo can be uncached on Wrath; bounded visible retries, no modern event.
    local elapsed,retries,recordElapsed=0,0,0
    events:SetScript("OnUpdate",function(_,dt)
        recordElapsed=recordElapsed+dt
        if recordElapsed>=5 then recordElapsed=0; ns.CaptureInventory("bags"); if bankOpen then ns.CaptureInventory("bank") end end
        elapsed=elapsed+dt; if elapsed<.5 then return end; elapsed=0
        local needed=false; for _,f in pairs(views) do if f:IsShown() and f._uncached then needed=true end end
        if needed and retries<20 then retries=retries+1; ns.Refresh("bags"); ns.Refresh("bank") elseif not needed then retries=0 end
    end)
end
