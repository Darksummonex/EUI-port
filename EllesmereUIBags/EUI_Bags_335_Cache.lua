-- Account-wide snapshots are deliberately outside layout profiles.
local _,ns=...
local E=EllesmereUI
if not ns.addon then return end
local white="Interface\\Buttons\\WHITE8X8"
local function Size(f,w,h) f:SetWidth(w); f:SetHeight(h) end
local function Font(fs,size)
    local flags=((E.GetFontOutlineFlag and E.GetFontOutlineFlag("bags")) or "OUTLINE"):gsub(",?%s*SLUG","")
    if not fs:SetFont((E.GetFontPath and E.GetFontPath("bags")) or "Fonts\\FRIZQT__.TTF",size or 10,flags) then fs:SetFont("Fonts\\FRIZQT__.TTF",size or 10,"OUTLINE") end
end
local function Button(parent,label,width,fn)
    local b=CreateFrame("Button",nil,parent); Size(b,width,22); b:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1})
    b:SetBackdropColor(.04,.08,.08,.95); b:SetBackdropBorderColor(.12,.5,.4,1)
    b.label=b:CreateFontString(nil,"OVERLAY"); Font(b.label); b.label:SetPoint("CENTER",b,"CENTER",0,0); b.label:SetText(label)
    b:SetScript("OnClick",fn); return b
end
function ns.CurrentCharacter()
    return GetRealmName and GetRealmName() or "Unknown Realm",UnitName("player") or "Unknown Character"
end
function ns.InventoryStore()
    local store=EllesmereUIInventoryDB
    if type(store)~="table" or store.version~=2 then store={version=2,realms={}}; EllesmereUIInventoryDB=store end
    store.realms=store.realms or {}
    if not store.migratedCore then
        local legacy=EllesmereUIDB and EllesmereUIDB.wrathInventoryCache
        if type(legacy)=="table" and type(legacy.realms)=="table" then
            for realm,chars in pairs(legacy.realms) do for name,old in pairs(chars) do
                local bags=old.bags and not old.bags.source and old.bags
                local bank=old.bank and not old.bank.source and old.bank
                if bags or bank then
                    local target=store.realms[realm] or {}; store.realms[realm]=target
                    local record=target[name] or {name=name,realm=realm,class=old.class,money=old.money}; target[name]=record
                    if bags and not record.bags then record.bags=bags end
                    if bank and not record.bank then record.bank=bank end
                end
            end end
        end
        store.migratedCore=true
        if EllesmereUIDB then EllesmereUIDB.wrathInventoryCache=nil end
    end
    return store
end
function ns.CharacterRecord(realm,name,create)
    local store=ns.InventoryStore(); local chars=store.realms[realm]
    if not chars and create then chars={}; store.realms[realm]=chars end
    if chars and not chars[name] and create then chars[name]={name=name,realm=realm} end
    return chars and chars[name]
end
function ns.CaptureMoney()
    local realm,name=ns.CurrentCharacter()
    if realm=="Unknown Realm" or name=="Unknown Character" then return end
    local money=GetMoney(); if type(money)~="number" or money<0 then return end
    local record=ns.CharacterRecord(realm,name,true)
    local _,class=UnitClass("player"); record.class=class
    record.money,record.moneyUpdated=money,time()
    return record
end
function ns.MoneyText(money)
    money=math.max(0,tonumber(money) or 0)
    if GetCoinTextureString then return GetCoinTextureString(money) end
    return string.format("%dg %ds %dc",math.floor(money/10000),math.floor(money/100)%100,money%100)
end
function ns.GoldTotals()
    local total,realmTotal,entries=0,0,{}
    local currentRealm=ns.CurrentCharacter()
    for _,entry in ipairs(ns.Characters()) do
        local record=ns.CharacterRecord(entry.realm,entry.name)
        if type(record.money)=="number" then
            local money=math.max(0,record.money)
            entries[#entries+1]={realm=entry.realm,name=entry.name,money=money,updated=record.moneyUpdated}
            total=total+money; if entry.realm==currentRealm then realmTotal=realmTotal+money end
        end
    end
    return total,realmTotal,entries
end
function ns.AddGoldTooltip(tooltip)
    local total,realmTotal,entries=ns.GoldTotals()
    tooltip:AddLine("Character Gold",1,.82,.2)
    for _,entry in ipairs(entries) do tooltip:AddLine(entry.name.." - "..entry.realm..": "..ns.MoneyText(entry.money),.9,.9,.9) end
    tooltip:AddLine("Realm Total: "..ns.MoneyText(realmTotal),1,.82,.2)
    tooltip:AddLine("Combined Total: "..ns.MoneyText(total),1,.82,.2)
    tooltip:AddLine("Alts show their last recorded balance.",.7,.7,.7)
end
function ns.IsLiveView(f)
    local realm,name=ns.CurrentCharacter()
    return (not f.selectedName or f.selectedName==name and f.selectedRealm==realm) and (f.kind~="bank" or ns.IsBankOpen())
end
function ns.UseCurrentView(kind)
    local f=ns.views[kind]; if not f then return end
    f.selectedRealm,f.selectedName=ns.CurrentCharacter(); f.selectedBag=nil
end
function ns.BagInventorySlot(bag)
    if bag>=1 and bag<=4 then return ContainerIDToInventoryID(bag) end
    if bag>=5 and bag<=11 then return BankButtonIDToInvSlotID(bag,1) end
end
local function IDs(kind)
    local ids={}
    if kind=="bank" then ids[1]=-1; for bag=5,11 do ids[#ids+1]=bag end
    else for bag=0,4 do ids[#ids+1]=bag end; if GetKeyRingSize then ids[#ids+1]=-2 end end
    return ids
end
function ns.CaptureInventory(kind)
    if kind=="bank" and not ns.IsBankOpen() then return end
    local realm,name=ns.CurrentCharacter()
    if realm=="Unknown Realm" or name=="Unknown Character" then return end
    local record=ns.CaptureMoney()
    -- Loading screens can briefly expose no backpack/bank capacity. Keep the
    -- previous snapshot and retry through native events/periodic recording.
    if GetContainerNumSlots(kind=="bank" and -1 or 0)<=0 then return nil,record end
    local snapshot={updated=time(),containers={}}
    local purchased=kind=="bank" and GetNumBankSlots() or nil; snapshot.purchased=purchased
    for _,bag in ipairs(IDs(kind)) do
        local slots=bag==-2 and GetKeyRingSize() or GetContainerNumSlots(bag)
        local c={slots=slots or 0,items={},purchased=bag<=4 or bag-4<=purchased}
        local inv=bag>0 and ns.BagInventorySlot(bag)
        if inv then c.link=GetInventoryItemLink("player",inv); c.icon=GetInventoryItemTexture("player",inv) end
        for slot=1,c.slots do
            local icon,count,locked,quality,readable,lootable,link=GetContainerItemInfo(bag,slot)
            link=link or GetContainerItemLink(bag,slot)
            if link then
                local n,_,q,level,_,itemType,itemSubType,_,equip=GetItemInfo(link)
                c.items[slot]={link=link,icon=icon,count=count or 1,quality=quality or q,name=n,level=level,itemType=itemType,itemSubType=itemSubType,equip=equip}
            end
        end
        snapshot.containers[bag]=c
    end
    record=record or ns.CharacterRecord(realm,name,true)
    record[kind]=snapshot; if ns.UpdateBroker then ns.UpdateBroker() end; return snapshot,record
end
function ns.SaveInventoryAndReload()
    if InCombatLockdown() then return end
    ns.CaptureInventory("bags"); if ns.IsBankOpen() then ns.CaptureInventory("bank") end
    if ReloadUI then ReloadUI() end
end
function ns.InventoryCacheSummary()
    local characters,bags,bank=0,0,0
    for _,chars in pairs(ns.InventoryStore().realms) do for _,record in pairs(chars) do
        characters=characters+1; if record.bags then bags=bags+1 end; if record.bank then bank=bank+1 end
    end end
    return characters.." saved characters; "..bags.." bags / "..bank.." banks"
end
function ns.ViewSnapshot(f)
    if ns.IsLiveView(f) then return ns.CaptureInventory(f.kind) end
    local realm,name=ns.CurrentCharacter(); local record=ns.CharacterRecord(f.selectedRealm or realm,f.selectedName or name)
    return record and record[f.kind],record
end
function ns.ViewItems(f)
    local snapshot,record=ns.ViewSnapshot(f); local items,free,total,uncached={},0,0,false
    if not snapshot then return items,free,total,false,nil,record end
    local live=ns.IsLiveView(f); local p=ns.GetSettings()
    for _,bag in ipairs(IDs(f.kind)) do local c=snapshot.containers[bag]
        if c and (bag~=-2 or p.bagIncludeKeyring) and (not f.selectedBag or f.selectedBag==bag) then
            for slot=1,c.slots do
                total=total+1; local saved=c.items[slot]; local item={bag=bag,slot=slot,quality=1,name=""}
                if saved then
                    for key,value in pairs(saved) do item[key]=value end
                    local n,_,q,level,_,itemType,itemSubType,_,equip,icon=GetItemInfo(item.link)
                    item.name=n or item.name or ""; item.quality=q or item.quality or 1; item.level=level or item.level; item.itemType=itemType or item.itemType; item.equip=equip or item.equip
                    item.icon=icon or item.icon
                    item.itemSubType=itemSubType or item.itemSubType
                    if not n then uncached=true end
                    if live then local _,_,locked,_,readable,lootable=GetContainerItemInfo(bag,slot); item.locked,item.readable,item.lootable=locked,readable,lootable end
                else free=free+1 end
                items[#items+1]=item
            end
        end
    end
    return items,free,total,uncached,snapshot,record
end
function ns.SelectCharacter(kind,realm,name)
    local f=ns.views[kind]; if not f or InCombatLockdown() then return end
    f.selectedRealm,f.selectedName,f.selectedBag=realm,name,nil; if f.selector then f.selector:Hide() end
    ns.Show(kind,true)
end
function ns.Characters()
    local list={}
    for realm,chars in pairs(ns.InventoryStore().realms) do for name in pairs(chars) do list[#list+1]={realm=realm,name=name} end end
    table.sort(list,function(a,b) return a.realm==b.realm and a.name<b.name or a.realm<b.realm end); return list
end
function ns.ItemTotals(link)
    local id=link and link:match("item:(%d+)"); local totals={}; if not id then return totals end
    for _,entry in ipairs(ns.Characters()) do local record=ns.CharacterRecord(entry.realm,entry.name); local counts={bags=0,bank=0}
        for _,kind in ipairs({"bags","bank"}) do local snapshot=record[kind]
            if snapshot then for _,c in pairs(snapshot.containers) do for _,item in pairs(c.items) do if item.link and item.link:match("item:(%d+)")==id then counts[kind]=counts[kind]+(item.count or 1) end end end end
        end
        if counts.bags+counts.bank>0 then counts.name,counts.realm,counts.bankKnown=entry.name,entry.realm,record.bank~=nil; totals[#totals+1]=counts end
    end
    return totals
end
function ns.AddOwnershipTooltip(link)
    if not ns.GetSettings().bagShowAltCounts then return end
    local totals=ns.ItemTotals(link)
    for i=1,math.min(10,#totals) do local c=totals[i]; GameTooltip:AddLine(c.name.." - "..c.realm..": Bags "..c.bags..", Bank "..(c.bankKnown and c.bank or "?"),.5,.85,.75) end
end
function ns.BuildInventoryControls(f,kind)
    f.kind=kind; ns.UseCurrentView(kind); f.savedPool={}; f.bagSlots={}
    f.characters=Button(f,"Characters",85,function()
        if InCombatLockdown() then return end
        if f.selector and f.selector:IsShown() then f.selector:Hide(); return end
        if not f.selector then
            local menu=CreateFrame("Frame",nil,f); f.selector=menu; menu:SetFrameStrata("DIALOG"); menu:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1}); menu:SetBackdropColor(.02,.04,.05,.98)
            menu:SetPoint("TOPRIGHT",f.characters,"BOTTOMRIGHT",0,-3); menu.rows={}
            menu.scroll=CreateFrame("ScrollFrame",nil,menu,"UIPanelScrollFrameTemplate"); menu.scroll:SetPoint("TOPLEFT",menu,"TOPLEFT",3,-3); menu.scroll:SetPoint("BOTTOMRIGHT",menu,"BOTTOMRIGHT",-24,3)
            menu.content=CreateFrame("Frame",nil,menu.scroll); menu.scroll:SetScrollChild(menu.content)
        end
        local menu=f.selector; local entries=ns.Characters()
        for _,row in ipairs(menu.rows) do row:Hide() end
        for i,entry in ipairs(entries) do
            local row=menu.rows[i] or Button(menu.content,"",230,function() end); menu.rows[i]=row
            row:ClearAllPoints(); row:SetPoint("TOPLEFT",menu.content,"TOPLEFT",0,-(i-1)*24); row.label:SetWidth(220); row.label:SetText(entry.name.." - "..entry.realm)
            local realm,name=entry.realm,entry.name; row:SetScript("OnClick",function() ns.SelectCharacter(kind,realm,name) end); row:Show()
        end
        Size(menu,260,math.min(246,math.max(30,#entries*24+6))); Size(menu.content,232,math.max(1,#entries*24)); menu:Show()
    end)
    f.characters:SetPoint("TOPRIGHT",f,"TOPRIGHT",-10,-33)
    if kind=="bags" then
        f.bankButton=Button(f,"Bank",85,ns.OpenCharacterBank); f.bankButton:SetPoint("RIGHT",f.characters,"LEFT",-6,0)
    end
    for _,bag in ipairs(IDs(kind)) do
        local b=Button(f,"",26,function() end); f.bagSlots[bag]=b; b.bagID=bag; Size(b,26,26)
        b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetPoint("TOPLEFT",b,"TOPLEFT",1,-1); b.icon:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-1,1)
        b.label:ClearAllPoints(); b.label:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-1,1); b:RegisterForDrag("LeftButton")
        local function Drop()
            if InCombatLockdown() or not ns.IsLiveView(f) or not CursorHasItem() then return end
            if bag==0 then PutItemInBackpack() elseif bag==-2 then PutKeyInKeyRing() elseif bag>0 and b.purchased then PutItemInBag(ns.BagInventorySlot(bag)) end
        end
        b:SetScript("OnReceiveDrag",Drop)
        b:SetScript("OnClick",function()
            if InCombatLockdown() then return end
            if ns.IsLiveView(f) and bag>=5 and not b.purchased then ns.RequestBankSlot(); return end
            if ns.IsLiveView(f) and CursorHasItem() then Drop(); return end
            if f.selectedBag==bag then f.selectedBag=nil else f.selectedBag=bag end; ns.Refresh(kind)
        end)
        b:SetScript("OnDragStart",function() if not InCombatLockdown() and ns.IsLiveView(f) and bag>0 and b.purchased then PickupBagFromSlot(ns.BagInventorySlot(bag)) end end)
        b:SetScript("OnEnter",function()
            GameTooltip:SetOwner(b,"ANCHOR_RIGHT")
            if b.link then GameTooltip:SetHyperlink(b.link) else GameTooltip:SetText(bag==0 and "Backpack" or bag==-1 and "Bank" or bag==-2 and "Keyring" or b.purchased and "Empty bag slot" or "Locked bank bag slot") end
            GameTooltip:AddLine("Click to filter this bag; click again for all slots.",.7,.7,.7)
            if not ns.IsLiveView(f) then GameTooltip:AddLine("Saved view - read only",1,.8,.2)
            elseif bag>=5 and not b.purchased then GameTooltip:AddLine("Click to purchase the next bank bag slot.",1,.8,.2) end
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave",function() GameTooltip:Hide() end)
    end
end
function ns.RefreshInventoryControls(f,snapshot)
    local p=ns.GetSettings(); local x=10
    for _,bag in ipairs(IDs(f.kind)) do local b=f.bagSlots[bag]
        if b then
            if not p.bagShowSlots or bag==-2 and not p.bagIncludeKeyring then b:Hide()
            else
                local c=snapshot and snapshot.containers[bag]; b.purchased=c and c.purchased or bag<=4; b.link=c and c.link
                b:ClearAllPoints(); b:SetPoint("TOPLEFT",f,"TOPLEFT",x,-62); x=x+30
                b.icon:SetTexture(c and c.icon or (bag==0 or bag==-1) and "Interface\\Buttons\\Button-Backpack-Up" or "Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag")
                b.icon:SetTexCoord(.08,.92,.08,.92); b.icon:SetDesaturated(not b.purchased)
                b.label:SetText(c and c.slots>0 and tostring(c.slots) or not b.purchased and "+" or "")
                b:SetBackdropBorderColor(f.selectedBag==bag and 1 or .12,f.selectedBag==bag and .8 or .5,.4,1); b:Show()
            end
        end
    end
    f.scroll:SetPoint("TOPLEFT",f,"TOPLEFT",0,p.bagShowSlots and -98 or -62)
    f.nativeShown=ns.IsLiveView(f)
    if f.native then if f.nativeShown then f.native:Show() else f.native:Hide() end end
end
function ns.RequestBankSlot()
    if not ns.IsBankOpen() or not ns.IsLiveView(ns.views.bank) or InCombatLockdown() then return end
    local purchased=GetNumBankSlots(); if purchased>=7 then return end
    ns.requestedBankSlot=purchased+1
    StaticPopupDialogs.EUI335_BUY_BANK_SLOT=StaticPopupDialogs.EUI335_BUY_BANK_SLOT or {text="Purchase the next bank bag slot for %s?",button1=ACCEPT or "Accept",button2=CANCEL or "Cancel",timeout=0,whileDead=1,hideOnEscape=1,
        OnAccept=function() if ns.IsBankOpen() and ns.IsLiveView(ns.views.bank) and not InCombatLockdown() and GetNumBankSlots()+1==ns.requestedBankSlot then PurchaseSlot() end; ns.requestedBankSlot=nil end}
    StaticPopup_Show("EUI335_BUY_BANK_SLOT",GetCoinTextureString(GetBankSlotCost(purchased)))
end
