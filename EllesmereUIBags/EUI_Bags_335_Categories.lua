-- Retail category system on Wrath: item classes come from localized
-- GetItemInfo type names, since Wrath has no GetItemInfoInstant class IDs.
local _,ns=...
local E=EllesmereUI
if not ns.addon then return end
local CM={}
ns.CM=CM
local function BP() return ns.GetSettings() or {} end
local function DB() EllesmereUIDB=EllesmereUIDB or {}; return EllesmereUIDB end
local ICON="Interface\\Icons\\"

-- Wrath item class IDs; 8 is the Item Enhancement consumable subclass.
local IC_CONSUMABLE,IC_CONTAINER,IC_WEAPON,IC_GEM,IC_ARMOR,IC_REAGENT,IC_PROJECTILE=0,1,2,3,4,5,6
local IC_TRADE,IC_ENHANCE,IC_RECIPE,IC_QUIVER,IC_QUEST,IC_KEY,IC_MISC,IC_GLYPH=7,8,9,11,12,13,15,16
local CLASS_EN={Consumable=0,Container=1,Weapon=2,Gem=3,Armor=4,Reagent=5,Projectile=6,["Trade Goods"]=7,
    Recipe=9,Quiver=11,Quest=12,Key=13,Miscellaneous=15,Glyph=16}
-- GetAuctionItemClasses order on 3.3.5.
local AUCTION_ORDER={IC_WEAPON,IC_ARMOR,IC_CONTAINER,IC_CONSUMABLE,IC_GLYPH,IC_TRADE,IC_PROJECTILE,IC_QUIVER,IC_RECIPE,IC_GEM,IC_MISC,IC_QUEST}
local classByName,enhanceName={}, "Item Enhancement"
for name,id in pairs(CLASS_EN) do classByName[name]=id end
local classesRead=false
function CM:RefreshClasses()
    if not classesRead and GetAuctionItemClasses then
        local list={GetAuctionItemClasses()}
        if #list>0 then
            classesRead=true
            for i,name in ipairs(list) do if AUCTION_ORDER[i] then classByName[name]=AUCTION_ORDER[i] end end
            local subs=GetAuctionItemSubClasses and {GetAuctionItemSubClasses(4)} or {}
            if subs[6] then enhanceName=subs[6] end
        end
    end
    for id,class in pairs({[17020]=IC_REAGENT,[7146]=IC_KEY}) do
        local _,_,_,_,_,itemType=GetItemInfo(id)
        if itemType then classByName[itemType]=class end
    end
end
function CM:ClassOf(itemType,itemSubType)
    local class=itemType and classByName[itemType]
    if class==IC_CONSUMABLE and itemSubType==enhanceName then return IC_ENHANCE end
    return class
end
CM.IC_WEAPON,CM.IC_ARMOR=IC_WEAPON,IC_ARMOR

local DEFAULT_CATEGORIES={
    {name="Pinned Items",types={},isPinned=true,noGroup=true,noMove=true,icon=ICON.."INV_Misc_Rune_01"},
    {name="Recent Items",types={},isRecent=true,noGroup=true,noMove=true,icon=ICON.."INV_Misc_PocketWatch_01"},
    {name="Item Set Gear",types={IC_ARMOR,IC_WEAPON},isSetGear=true,icon=ICON.."INV_Chest_Chain_05"},
    {name="Quest Items",types={IC_QUEST},icon="Interface\\GossipFrame\\AvailableQuestIcon"},
    {name="Weapons / Trinkets",types={IC_WEAPON},equipSlots={"INVTYPE_TRINKET"},icon=ICON.."INV_Sword_27"},
    {name="Armor",types={IC_ARMOR},excludeEquipSlots={"INVTYPE_TRINKET"},icon=ICON.."INV_Chest_Cloth_21"},
    {name="Consumables",types={IC_CONSUMABLE,IC_PROJECTILE},icon=ICON.."INV_Misc_Food_19"},
    {name="Trade Goods",types={IC_TRADE,IC_REAGENT},icon=ICON.."INV_Fabric_Silk_02"},
    {name="Gear Enhancements",types={IC_GEM,IC_ENHANCE,IC_GLYPH},icon=ICON.."INV_Misc_Gem_Variety_01"},
    {name="Professions",types={IC_RECIPE},icon=ICON.."Trade_Engineering"},
    {name="Keys",types={IC_KEY},icon=ICON.."INV_Misc_Key_04"},
    {name="Miscellaneous",types={IC_MISC,IC_CONTAINER,IC_QUIVER},isCatchAll=true,icon=ICON.."INV_Misc_Gear_01"},
    -- Junk: always last, and only while the Junk Marker is on.
    {name="Junk",types={},isJunk=true,noGroup=true,icon=ICON.."INV_Misc_Coin_01"},
}
CM.JUNK_KEY="Junk"
function CM:IsJunkMarkerEnabled() return BP().bagShowJunkIcon~=false end
CM.DEFAULT_CATEGORIES=DEFAULT_CATEGORIES
CM.DEFAULT_ICON=ICON.."INV_Misc_QuestionMark"

-- Retail's first-login seeding: Armory/Adventure Prep groups, default order,
-- Quest Items routed to the catch-all until the user enables it.
function CM:Seed()
    local p=ns.GetSettings(); if not p then return end
    local db=DB()
    if db.bagDisabledCategoriesSeeded==nil then
        db.bagDisabledCategoriesSeeded=true
        p.bagDisabledCategories=p.bagDisabledCategories or {}
        p.bagDisabledCategories["Quest Items"]=true
    end
    if not db.bagDefaultGroupsSeeded then
        db.bagDefaultGroupsSeeded=true
        if not p.bagCategoryState and not p.bagCategoryOrder then
            p.bagCategoryState={
                ["Weapons / Trinkets"]={groupName="The Armory",groupNameCustom=true},
                ["Armor"]={groupName="The Armory",groupNameCustom=true},
                ["Item Set Gear"]={groupName="The Armory",groupNameCustom=true},
                ["Consumables"]={groupName="Adventure Prep",groupNameCustom=true},
                ["Gear Enhancements"]={groupName="Adventure Prep",groupNameCustom=true},
            }
            p.bagCategoryOrder={"Pinned Items","Recent Items","Weapons / Trinkets","Armor","Item Set Gear","Consumables",
                "Gear Enhancements","Trade Goods","Professions","Keys","Miscellaneous","Quest Items"}
        end
    end
    self._categories=nil
end

local function EquipmentSets()
    local sets={}
    if not GetNumEquipmentSets then return sets end
    for i=1,GetNumEquipmentSets() do
        local name,icon=GetEquipmentSetInfo(i)
        if name then sets[#sets+1]={name=name,icon=icon and (icon:find("\\",1,true) and icon or ICON..icon)} end
    end
    table.sort(sets,function(a,b) return a.name<b.name end)
    return sets
end

function CM:InitCategories()
    local p=BP(); local userState=p.bagCategoryState or {}; local userOrder=p.bagCategoryOrder
    local defByName={}; for _,def in ipairs(DEFAULT_CATEGORIES) do defByName[def.name]=def end
    local userCatByKey={}; for _,uc in ipairs(p.bagUserCategories or {}) do userCatByKey[uc.key]=uc end
    local ordered={}
    if userOrder and #userOrder>0 then
        local seen={}
        for _,name in ipairs(userOrder) do
            if defByName[name] then ordered[#ordered+1]=defByName[name]; seen[name]=true
            elseif userCatByKey[name] then ordered[#ordered+1]={name=name,_isCustom=true}; seen[name]=true end
        end
        for _,def in ipairs(DEFAULT_CATEGORIES) do
            if not seen[def.name] then
                local at=#ordered+1
                for i,od in ipairs(ordered) do if od.isCatchAll then at=i; break end end
                table.insert(ordered,at,def)
            end
        end
    else
        for _,def in ipairs(DEFAULT_CATEGORIES) do ordered[#ordered+1]=def end
    end
    local top,rest,junk={}, {}, nil
    for _,def in ipairs(DEFAULT_CATEGORIES) do if def.noMove then top[#top+1]=def elseif def.isJunk then junk=def end end
    for _,def in ipairs(ordered) do if not def.noMove and not def.isJunk then rest[#rest+1]=def end end
    ordered={}; for _,d in ipairs(top) do ordered[#ordered+1]=d end; for _,d in ipairs(rest) do ordered[#ordered+1]=d end
    if junk and self:IsJunkMarkerEnabled() then ordered[#ordered+1]=junk end
    local cats,inserted={}, {}
    local function Custom(uc)
        local state=userState[uc.key]
        inserted[uc.key]=true
        return {_defaultName=uc.key,_userName=uc.name,name=(state and state.rename) or uc.name,types={},icon=uc.icon or CM.DEFAULT_ICON,
            isUserCreated=true,groupName=state and state.groupName or nil,groupNameCustom=state and state.groupNameCustom}
    end
    for _,def in ipairs(ordered) do
        if def._isCustom then cats[#cats+1]=Custom(userCatByKey[def.name])
        else
            local state=userState[def.name]
            local group; if state and state.groupName~=nil then group=state.groupName or nil end
            cats[#cats+1]={_defaultName=def.name,name=(state and state.rename) or def.name,types=def.types,icon=def.icon,
                equipSlots=def.equipSlots,excludeEquipSlots=def.excludeEquipSlots,isCatchAll=def.isCatchAll,isSetGear=def.isSetGear,
                isPinned=def.isPinned,isRecent=def.isRecent,isJunk=def.isJunk,noGroup=def.noGroup,noMove=def.noMove,groupName=group,
                groupNameCustom=state and state.groupNameCustom}
            if def.isSetGear and p.bagSplitSetGearBySet then
                for _,set in ipairs(EquipmentSets()) do
                    cats[#cats+1]={_defaultName="EquipSet:"..set.name,name=set.name,types=def.types,icon=set.icon or def.icon,
                        isSetGear=true,isEquipSet=true,equipSetName=set.name,noGroup=true}
                end
            end
        end
    end
    local catchIdx=#cats+1; for i,c in ipairs(cats) do if c.isCatchAll or c.isJunk then catchIdx=i; break end end
    for _,uc in ipairs(p.bagUserCategories or {}) do
        if not inserted[uc.key] then table.insert(cats,catchIdx,Custom(uc)); catchIdx=catchIdx+1 end
    end
    self._categories=cats
end

function CM:SaveState()
    local cats=self._categories; local p=ns.GetSettings(); if not cats or not p then return end
    local state,order,user={}, {}, {}
    local old=p.bagCategoryState
    for _,cat in ipairs(cats) do
        if not cat.isEquipSet then
            if not cat.isJunk then order[#order+1]=cat._defaultName end
            local entry,has={},false
            if cat.name~=cat._defaultName and not cat.isUserCreated then entry.rename=cat.name; has=true end
            if cat.isUserCreated and cat.name~=cat._userName then entry.rename=cat.name; has=true end
            if cat.groupName then entry.groupName=cat.groupName; has=true end
            if cat.groupNameCustom then entry.groupNameCustom=true; has=true end
            if has then state[cat._defaultName]=entry end
            if cat.isUserCreated then user[#user+1]={key=cat._defaultName,name=cat._userName or cat.name,icon=cat.icon} end
        end
    end
    -- Junk is out of the list while the Junk Marker is off: keep its rename.
    if not self:IndexOf(self.JUNK_KEY) and old and old[self.JUNK_KEY] then state[self.JUNK_KEY]=old[self.JUNK_KEY] end
    p.bagCategoryState,p.bagCategoryOrder,p.bagUserCategories=state,order,#user>0 and user or nil
end

function CM:GetCategories()
    if not self._categories then self:InitCategories() end
    return self._categories
end
function CM:Invalidate() self._categories=nil end
function CM:IndexOf(key) for i,c in ipairs(self:GetCategories()) do if c._defaultName==key then return i,c end end end

-- bag*1000+slot -> set name, rebuilt per classification pass.
local setLookup={}
local function BuildSetLookup(live)
    wipe(setLookup)
    if not live or not GetNumEquipmentSets or not GetEquipmentSetLocations or not EquipmentManager_UnpackLocation then return end
    for i=1,GetNumEquipmentSets() do
        local name=GetEquipmentSetInfo(i)
        local locations=name and GetEquipmentSetLocations(name)
        for _,location in pairs(locations or {}) do
            if type(location)=="number" and location>1 then
                local _,bank,bags,slot,bag=EquipmentManager_UnpackLocation(location)
                if bank and not bags and slot then bag,slot=-1,slot-39 end
                if (bags or bank) and bag and slot then
                    local key=bag*1000+slot
                    if not setLookup[key] then setLookup[key]=name end
                end
            end
        end
    end
end
function CM:SetNameAt(bag,slot) return setLookup[bag*1000+slot] end

local function HasType(cat,class) for _,t in ipairs(cat.types or {}) do if t==class then return true end end end
function CM:ClassifyItem(item)
    if not item or not item.link then return nil end
    local cats=self:GetCategories()
    local assigned=item.itemID and DB().bagItemAssignments and DB().bagItemAssignments[item.itemID]
    if assigned then for i,cat in ipairs(cats) do if cat._defaultName==assigned then return i end end end
    -- Grey items go to Junk while the Junk Marker is on (quest items never do).
    if item.quality==0 and not item.isQuest then for i,cat in ipairs(cats) do if cat.isJunk then return i end end end
    if item.isQuest then for i,cat in ipairs(cats) do if HasType(cat,IC_QUEST) then return i end end end
    local class=self:ClassOf(item.itemType,item.itemSubType)
    if class==nil then for i,cat in ipairs(cats) do if cat.isCatchAll then return i end end; return #cats end
    if (class==IC_ARMOR or class==IC_WEAPON) and item.bag and item.slot then
        local set=setLookup[item.bag*1000+item.slot]
        if set then
            for i,cat in ipairs(cats) do if cat.equipSetName==set then return i end end
            for i,cat in ipairs(cats) do if cat.isSetGear and not cat.isEquipSet then return i end end
        end
    end
    local equip=item.equip
    for i,cat in ipairs(cats) do
        if #(cat.types or {})>0 and not cat.isSetGear then
            local match=HasType(cat,class)
            if not match and cat.equipSlots and equip then for _,slot in ipairs(cat.equipSlots) do if slot==equip then match=true end end end
            if match and cat.excludeEquipSlots and equip then for _,slot in ipairs(cat.excludeEquipSlots) do if slot==equip then match=false end end end
            if match then return i end
        end
    end
    for i,cat in ipairs(cats) do if cat.isCatchAll then return i end end
    return #cats
end

function CM:ClassifyAll(items,live)
    self:RefreshClasses(); BuildSetLookup(live)
    local cats=self:GetCategories(); local counts,total={},0
    for i=1,#cats do counts[i]=0 end
    local disabled=BP().bagDisabledCategories; local catchAll,off
    if disabled then
        off={}
        for i,cat in ipairs(cats) do
            if cat.isCatchAll then catchAll=i end
            if disabled[cat._defaultName] or cat.isEquipSet and disabled["Item Set Gear"] then off[i]=true end
        end
    end
    local stamp=BP().bagShowSetGearName==true
    for _,item in ipairs(items) do
        if item.link then
            local idx=self:ClassifyItem(item)
            item._setName=stamp and item.bag and setLookup[item.bag*1000+item.slot] or nil
            if off and idx and off[idx] and catchAll then idx=catchAll end
            item.categoryIndex=idx
            if idx then counts[idx]=(counts[idx] or 0)+1 end
            total=total+1
        end
    end
    return counts,total
end

function CM:RenameCategory(index,name)
    local cats=self:GetCategories(); local cat=cats[index]
    if not cat or not name or name=="" then return false end
    local group=cat.groupName; local regen=group and not self:IsGroupNameCustom(group)
    cat.name=name; if regen then self:RegenerateGroupName(group) end
    self:SaveState(); return true
end
function CM:ReorderCategory(from,to)
    local cats=self:GetCategories()
    if not cats[from] or from==to or cats[from].isEquipSet or cats[from].isJunk or to<1 or to>#cats+1 then return end
    if cats[#cats].isJunk and to>#cats then to=#cats end
    local entry=table.remove(cats,from)
    table.insert(cats,from<to and to-1 or to,entry)
    self:SaveState()
end
local function JoinNames(names)
    if #names==2 then return names[1].." & "..names[2] end
    if #names>=3 then return table.concat(names,", ",1,#names-1)..", & "..names[#names] end
end
function CM:GroupCategories(indices,groupName)
    local cats=self:GetCategories(); if not indices or #indices<2 then return end
    if not groupName then local names={}; for _,i in ipairs(indices) do if cats[i] then names[#names+1]=cats[i].name end end; groupName=JoinNames(names) or "Group" end
    for _,i in ipairs(indices) do if cats[i] then cats[i].groupName=groupName; cats[i].groupNameCustom=nil end end
    self:SaveState()
end
function CM:AddToGroup(index,groupName)
    local cats=self:GetCategories(); if not cats[index] or not groupName then return end
    cats[index].groupName=groupName
    if not self:IsGroupNameCustom(groupName) then self:RegenerateGroupName(groupName) end
    self:SaveState()
end
function CM:UngroupCategory(index)
    local cats=self:GetCategories(); local cat=cats[index]; if not cat or not cat.groupName then return end
    local old=cat.groupName; local custom=self:IsGroupNameCustom(old)
    cat.groupName,cat.groupNameCustom=nil,nil
    local remaining={}; for i,c in ipairs(cats) do if c.groupName==old then remaining[#remaining+1]=i end end
    if #remaining==1 then cats[remaining[1]].groupName=nil; cats[remaining[1]].groupNameCustom=nil
    elseif #remaining>1 and not custom then self:RegenerateGroupName(old) end
    self:SaveState()
end
function CM:DisbandGroup(groupName)
    for _,cat in ipairs(self:GetCategories()) do if cat.groupName==groupName then cat.groupName,cat.groupNameCustom=nil,nil end end
    self:SaveState()
end
function CM:RenameGroup(old,new)
    if not new or new=="" then return end
    for _,cat in ipairs(self:GetCategories()) do if cat.groupName==old then cat.groupName=new end end
    self:SaveState()
end
function CM:IsGroupNameCustom(groupName)
    for _,cat in ipairs(self:GetCategories()) do if cat.groupName==groupName and cat.groupNameCustom then return true end end
    return false
end
function CM:SetGroupNameCustom(groupName,custom)
    for _,cat in ipairs(self:GetCategories()) do if cat.groupName==groupName then cat.groupNameCustom=custom or nil end end
    self:SaveState()
end
function CM:RegenerateGroupName(groupName)
    local names={}; for _,cat in ipairs(self:GetCategories()) do if cat.groupName==groupName then names[#names+1]=cat.name end end
    local new=JoinNames(names)
    if new and new~=groupName then self:RenameGroup(groupName,new); self:SetGroupNameCustom(new,false) end
end
function CM:GetGroupNames()
    local seen,groups={}, {}
    for _,cat in ipairs(self:GetCategories()) do if cat.groupName and not seen[cat.groupName] then seen[cat.groupName]=true; groups[#groups+1]=cat.groupName end end
    return groups
end
function CM:GetGroupMembers(groupName)
    local members={}; for i,cat in ipairs(self:GetCategories()) do if cat.groupName==groupName then members[#members+1]=i end end
    return members
end

function CM:AddCustomCategory(name,icon)
    if not name or name=="" then return end
    local p=ns.GetSettings(); if not p then return end
    p.bagUserCategories=p.bagUserCategories or {}
    local n=0; for _,uc in ipairs(p.bagUserCategories) do n=math.max(n,tonumber(uc.key:match("Custom_(%d+)")) or 0) end
    local key="Custom_"..(n+1)
    local cats=self:GetCategories(); local at=#cats+1
    for i,c in ipairs(cats) do if c.isCatchAll or c.isJunk then at=i; break end end
    table.insert(cats,at,{_defaultName=key,_userName=name,name=name,types={},icon=icon or CM.DEFAULT_ICON,isUserCreated=true})
    self:SaveState(); return at
end
function CM:SetCategoryIcon(index,icon)
    local cat=self:GetCategories()[index]; if not cat or not cat.isUserCreated then return end
    cat.icon=icon or CM.DEFAULT_ICON; self:SaveState()
end
function CM:RemoveCustomCategory(index)
    local cats=self:GetCategories(); local cat=cats[index]
    if not cat or not cat.isUserCreated then return false end
    local assignments=DB().bagItemAssignments
    for id,key in pairs(assignments or {}) do if key==cat._defaultName then assignments[id]=nil end end
    local prev=DB().bagJunkPrev
    for id,key in pairs(prev or {}) do if key==cat._defaultName then prev[id]=nil end end
    table.remove(cats,index)
    local p=ns.GetSettings(); if p and p.bagDisabledCategories then p.bagDisabledCategories[cat._defaultName]=nil end
    self:SaveState(); return true
end
-- A Junk mark remembers the category the item was filed in (bagJunkPrev), so
-- unmarking puts it back there.
local function SetJunkPrev(itemID,key)
    local db=DB(); local prev=db.bagJunkPrev
    if key then if not prev then prev={}; db.bagJunkPrev=prev end; prev[itemID]=key
    elseif prev then prev[itemID]=nil; if not next(prev) then db.bagJunkPrev=nil end end
end
function CM:AssignItem(itemID,key)
    if not itemID then return end
    local db=DB(); db.bagItemAssignments=db.bagItemAssignments or {}
    local current=db.bagItemAssignments[itemID]
    if key==self.JUNK_KEY then if current~=self.JUNK_KEY then SetJunkPrev(itemID,current) end
    elseif current==self.JUNK_KEY then SetJunkPrev(itemID,nil) end
    db.bagItemAssignments[itemID]=key
end
function CM:UnassignItem(itemID)
    local a=DB().bagItemAssignments; if not (a and itemID) then return end
    if a[itemID]==self.JUNK_KEY then
        local prev=DB().bagJunkPrev; a[itemID]=prev and prev[itemID] or nil; SetJunkPrev(itemID,nil)
    else a[itemID]=nil end
end
-- Junk: marked items, and grey items (unmarked), while the Junk Marker is on.
function CM:IsJunk(itemID,quality)
    if not itemID or not self:IsJunkMarkerEnabled() then return false end
    local a=DB().bagItemAssignments
    if a and a[itemID]==self.JUNK_KEY then return true end
    return quality==0
end
function CM:ToggleJunk(itemID)
    if not itemID then return end
    local a=DB().bagItemAssignments
    if a and a[itemID]==self.JUNK_KEY then self:UnassignItem(itemID) else self:AssignItem(itemID,self.JUNK_KEY) end
end
function CM:RebuildSetLookup() BuildSetLookup(true) end
function CM:CanAssignToCategory(index)
    local cat=self:GetCategories()[index]
    return cat and not cat.isPinned and not cat.isRecent and not cat.isEquipSet or false
end
function CM:OnEquipmentSetsChanged() self._categories=nil end
_G.EUI_CategoryManager=_G.EUI_CategoryManager or CM
