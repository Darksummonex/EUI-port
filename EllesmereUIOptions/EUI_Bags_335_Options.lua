local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
local E=EllesmereUI
local ns=E and E._ModuleNS and E._ModuleNS.EllesmereUIBags
if not ns or not ns.IsWrath then return end
local init=CreateFrame("Frame"); init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent",function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local function P() return ns.GetSettings() end
    local function Field(key,label,kind,tip,min,max,step,refreshPage)
        return {type=kind,text=label,tooltip=tip,min=min,max=max,step=step,
            getValue=function() local p=P(); return p and p[key] end,
            setValue=function(v) local p=P(); if not p then return end; p[key]=v; ns.Apply(); if refreshPage and E.RefreshPage then E:RefreshPage() end end}
    end
    local function Toggle(key,label,tip,refreshPage) return Field(key,label,"toggle",tip,nil,nil,nil,refreshPage) end
    local function Slider(key,label,min,max,step,tip) return Field(key,label,"slider",tip,min,max,step or 1) end
    local function Cog(region,opts) if region and not E._prebuilding and E.BuildInlineCog then E.BuildInlineCog(region,opts) end end
    local function CogToggle(key,label,tip) return {type="toggle",label=label,tooltip=tip,get=function() return P()[key]==true end,set=function(v) P()[key]=v and true or false; ns.Apply() end} end
    local function CogSlider(key,label,min,max,def) return {type="slider",label=label,min=min,max=max,step=1,get=function() return P()[key] or def end,set=function(v) P()[key]=v; ns.Apply() end} end
    local function Picker(region,items,getFn,setFn)
        if not region or E._prebuilding or not E.BuildVisOptsCBDropdown then return end
        local dd,refresh=E.BuildVisOptsCBDropdown(region,210,region:GetFrameLevel()+2,items,getFn,setFn,nil,10,true)
        dd:SetPoint("RIGHT",region,"RIGHT",-20,0); region._control=dd; region._lastInline=nil
        if E.RegisterWidgetRefresh then E.RegisterWidgetRefresh(refresh) end
    end
    local function CategoryItems()
        local list={}
        for _,cat in ipairs(ns.CM:GetCategories()) do
            if not cat.isCatchAll and not cat.isPinned and not cat.isRecent and not cat.isEquipSet then list[#list+1]={key=cat._defaultName,label=cat.name} end
        end
        return list
    end
    -- Wrath lists currencies under collapsible headers; expand them while reading.
    local function CurrencyItems()
        local list,collapsed={}, {}
        if not GetCurrencyListSize or not GetCurrencyListInfo then return list end
        if ExpandCurrencyList then
            local i=1
            while i<=GetCurrencyListSize() do
                local _,isHeader,isExpanded=GetCurrencyListInfo(i)
                if isHeader and not isExpanded then collapsed[#collapsed+1]=i; ExpandCurrencyList(i,1) end
                i=i+1
            end
        end
        for i=1,GetCurrencyListSize() do
            local name,isHeader,_,_,_,_,_,icon,itemID=GetCurrencyListInfo(i)
            if name then
                if isHeader then list[#list+1]={isHeader=true,label=name}
                else list[#list+1]={key=(itemID and itemID>0) and itemID or name,label=name,icon=icon} end
            end
        end
        for i=#collapsed,1,-1 do ExpandCurrencyList(collapsed[i],0) end
        return list
    end
    local function ChosenCurrencies(create)
        EllesmereUIDB=EllesmereUIDB or {}; local db=EllesmereUIDB; local key=ns.CurrentCharKey()
        db.bagCurrencyByChar=db.bagCurrencyByChar or {}
        if not db.bagCurrencyByChar[key] and create then
            local seeded={}; for _,c in ipairs(ns.CurrencyList()) do if c.watched then seeded[#seeded+1]=c.key end end
            db.bagCurrencyByChar[key]=seeded
        end
        return db.bagCurrencyByChar[key]
    end
    E._ELEMENT_SETTINGS_MAP=E._ELEMENT_SETTINGS_MAP or {}
    E._ELEMENT_SETTINGS_MAP.EUI335_bags={module="EllesmereUIBags",page="Bags"}
    E._ELEMENT_SETTINGS_MAP.EUI335_bank={module="EllesmereUIBags",page="Bank"}
    E:RegisterModule("EllesmereUIBags",{title="Bags",description="Enhanced inventory system with sidebar categories, item levels, and quality borders.",pages={"Bags","Bank"},
        searchTerms="bags bank inventory items slots categories columns sidebar pinned recent sort merge armory currency gold money keyring saved offline alts characters cache save databroker",
        buildPage=function(page,parent,y)
            local W=E.Widgets
            local function Row(a,b) local row,h=W:DualRow(parent,y,a,b); y=y-h; return row end
            local function Section(text) local _,h=W:SectionHeader(parent,text,y); y=y-h end
            local function Button(text,fn) local _,h=W:WideButton(parent,text,y,fn); y=y-h end
            if page=="Bank" then
                Section("GROUPING")
                Row(Toggle("bankGroupByCategory","Group by Category","Split bank items by category, using the same category list, order and renames as the All Items bag view.",true),
                    Slider("bankColumns","Columns",6,24,1,"Item columns in the bank window."))
                Section("SIDEBAR")
                Row(Toggle("bankCategorySidebar","Category Sidebar","List item categories in a bank sidebar the way the bags sidebar does. Selecting one filters the grid to that category.",true),
                    {type="toggle",text="Hide Bank Bags in Sidebar",tooltip="Drop the individual Bank / Bank Bag entries once the category list is doing the navigating.",
                     disabled=function() return not P().bankCategorySidebar end,disabledTooltip="Category Sidebar",
                     getValue=function() return P().bankHideTabsInSidebar end,setValue=function(v) P().bankHideTabsInSidebar=v; ns.Apply() end})
                Row({type="toggle",text="Hide Empty Slots When Grouped",tooltip="While Group by Category is on, drop the trailing block of empty slots so the view only shows items.",
                     disabled=function() return not P().bankGroupByCategory end,disabledTooltip="Group by Category",
                     getValue=function() return P().bankHideEmptyWhenNested end,setValue=function(v) P().bankHideEmptyWhenNested=v; ns.Apply() end},
                    Toggle("enhancedBank","Enable Bank","Use the EllesmereUI bank window instead of the default bank frame."))
                Section("CHARACTERS")
                Row({type="label",text="Window scale, icon zoom and item level settings are shared with the Bags page."},{type="label",text="The bank opens anywhere from the Bags header; away from a banker it shows the last saved contents."})
                Button("Show Character Bank",ns.OpenCharacterBank)
                return math.abs(y)
            end
            local row
            Section("DISPLAY")
            Row({type="slider",text="Window Scale",min=50,max=150,step=5,tooltip="Scale of the bag and bank windows.",
                 getValue=function() return math.floor((P().bagScale or 1)*100+.5) end,setValue=function(v) P().bagScale=v/100; ns.Apply() end},
                Slider("bagItemIconZoom","Icon Zoom",0,.2,.01,"Crops the border of every item icon in bags and bank. 0 shows the full icon."))
            Row(Toggle("bagHideEmptyCategories","Hide Categories with 0 Items","Hide sidebar categories that have no items in them."),
                Toggle("bagAutoSize","Auto-Size to Fit","Grow the bag window (more columns and taller) so every slot fits without scrolling."))
            Row(Toggle("bagMergeDuplicates","Merge Duplicate Items","Show copies of the same item in separate slots as one icon with their counts added together. Paused while the mail, trade, auction house, bank or guild bank window is open."),
                Toggle("bagDesaturateJunkItems","Desaturate Junk Items","Display junk items (grey quality and items you marked as junk) in a greyed-out style."))
            row=Row({type="toggle",text="Junk Marker",tooltip="Show the coin button in the bag header. Click it, then click items to mark or unmark them as junk. Junk goes into its own Junk category, and a Sell Junk button appears next to the coin while a merchant is open.",
                 getValue=function() return P().bagShowJunkIcon~=false end,
                 setValue=function(v) P().bagShowJunkIcon=v and true or false; if not v and ns.ExitSelectMode then ns.ExitSelectMode() end; ns.CM:Invalidate(); ns.Apply(); if E.RefreshPage then E:RefreshPage() end end},
                {type="label",text="Sell Junk skips items with no vendor price, equipment set gear and pinned items."})
            Cog(row and row._leftRegion,{chain=false,disabled=function() return P().bagShowJunkIcon==false end,disabledTooltip="Junk Marker",title="Junk Marker Options",
                rows={CogToggle("bagShowJunkCoin","Show Coin on Junk","Show a small coin in the corner of items marked as junk.")}})
            row=Row({type="toggle",text="Split Set Gear by Set",tooltip="Show one sub-category per equipment set (named after the set) under Item Set Gear.",
                 getValue=function() return P().bagSplitSetGearBySet end,setValue=function(v) P().bagSplitSetGearBySet=v; ns.CM:OnEquipmentSetsChanged(); ns.Apply() end},
                Toggle("bagShowSetGearName","Show Set Name on Gear","Display the equipment set's name at the bottom of bag items that belong to one of your equipment sets.",true))
            Cog(row and row._rightRegion,{icon=E.RESIZE_ICON,chain=false,disabled=function() return not P().bagShowSetGearName end,disabledTooltip="Show Set Name on Gear",
                title="Set Name Text Options",rows={CogSlider("bagSetNameFontSize","Text Size",7,14,9)}})
            row=Row({type="dropdown",text="Default Bag Type",tooltip="Which view the bags open to by default.",values={all="All Items",onebag="OneBag",multibag="MultiBag"},order={"all","onebag","multibag"},
                 getValue=function() return P().bagDefaultBagType or "all" end,
                 setValue=function(v) P().bagDefaultBagType=v; if ns.views.bags then ns.ResetView(ns.views.bags) end; ns.Apply() end},
                Toggle("bagDisplayBindType","Show BoE Text","Display Binds when Equipped / Binds when Used on unbound items in your bags and bank.",true))
            Cog(row and row._rightRegion,{icon=E.RESIZE_ICON,chain=false,disabled=function() return not P().bagDisplayBindType end,disabledTooltip="Show BoE Text",
                title="BoE Text Options",rows={CogSlider("bagBindTypeFontSize","Text Size",8,16,11)}})
            Row(Slider("bagCatTitleSize","Category Title Size",8,16,1,"Font size for category titles in the content grid."),
                Toggle("showItemlevelInBags","Show Item Level","Display item levels on equipment items in the inventory."))
            row=Row({type="label",text="Enabled Categories"},{type="label",text="Enabled Currencies"})
            Picker(row and row._leftRegion,CategoryItems,
                function(key) local dc=P().bagDisabledCategories; return not (dc and dc[key]) end,
                function(key,v) local p=P(); p.bagDisabledCategories=p.bagDisabledCategories or {}; p.bagDisabledCategories[key]=(not v) or nil; ns.Apply() end)
            Picker(row and row._rightRegion,CurrencyItems,
                function(key) local chosen=ChosenCurrencies(false); if not chosen then for _,c in ipairs(ns.CurrencyList()) do if c.key==key then return c.watched end end; return false end
                    for _,k in ipairs(chosen) do if k==key then return true end end; return false end,
                function(key,v) local chosen=ChosenCurrencies(true)
                    for i=#chosen,1,-1 do if chosen[i]==key then table.remove(chosen,i) end end
                    if v then chosen[#chosen+1]=key end; ns.Apply() end)
            Row(Slider("bagCountFontSize","Item Count Text Size",8,16,1,"Font size for stack counts."),
                Slider("itemlevelFontSize","Item Level Text Size",8,16,1,"Font size for item level numbers on equipment items."))
            Section("EXTRAS")
            row=Row(Toggle("bagShowSortIcon","Show Sort Icon","Display the sort button in the bag header.",true),
                Toggle("enableGoldTracking","Gold Tracking and History","Track and display gold amounts from all your characters on hover."))
            Cog(row and row._leftRegion,{chain=false,disabled=function() return not P().bagShowSortIcon end,disabledTooltip="Show Sort Icon",title="Sort Options",
                rows={CogToggle("bagSortToBottom","Sort to Bottom","Pack sorted items into the last slots so the empty slots end up at the top. Affects OneBag, MultiBag and the bank.")}})
            row=Row(Toggle("bagShowPinnedItems","Show Pinned Items","Show the Pinned Items category in the sidebar and content grid.",true),
                Toggle("bagShowRecentItems","Show Recent Items","Show the Recent Items category in the sidebar and content grid for newly acquired items.",true))
            Cog(row and row._leftRegion,{chain=false,disabled=function() return not P().bagShowPinnedItems end,disabledTooltip="Show Pinned Items",title="Pinned Items Options",
                rows={{type="toggle",label="Show in OneBag/MultiBag",get=function() return P().bagPinnedInOneBag~=false end,set=function(v) P().bagPinnedInOneBag=v; ns.Apply() end}}})
            Cog(row and row._rightRegion,{chain=false,disabled=function() return not P().bagShowRecentItems end,disabledTooltip="Show Recent Items",title="Recent Items Options",
                rows={CogToggle("bagRecentInOneBag","Show in OneBag/MultiBag"),CogToggle("bagShowRecentClear","Show Clear Button")}})
            Row(Toggle("bagShowPinRecentTips","Show Pinned & Recent Tips","Show helpful tip text on Pinned Items and Recent Items category headers."),
                Toggle("bagHideAddCategory","Hide 'Add Category' Tab","Hides the Add Category button at the bottom of the bag sidebar."))
            Row(Toggle("bagMoveNoShift","Move Bags Without Shift","Left-click dragging the bag window moves it without holding Shift."),
                Toggle("bagHideOneBagWarning","Hide OneBag/MultiBag Warning","Hide the warning text at the top of the OneBag view."))
            row=Row({type="toggle",text="Group Armory by Slot",tooltip="In The Armory and the Weapons / Trinkets, Armor and Item Set Gear views, group items under equip-slot sub-headers.",
                 disabled=function() local dc=P().bagDisabledCategories; return dc and dc.Armor==true end,disabledTooltip="Armor",
                 getValue=function() return P().bagArmoryGroupBySlot end,setValue=function(v) P().bagArmoryGroupBySlot=v; ns.Apply(); if E.RefreshPage then E:RefreshPage() end end},
                Toggle("bagHideRandomize","Hide OneBag Randomize Button","Hide the randomize (dice) button in the OneBag view."))
            Cog(row and row._leftRegion,{chain=false,disabled=function() return not P().bagArmoryGroupBySlot end,disabledTooltip="Group Armory by Slot",title="Armory Slot Group Options",
                rows={CogToggle("bagCompactArmorySlotGroups","Compact Slot Groups","Place smaller Armory slot groups beside each other. Large groups still use full rows.")}})
            Row(Toggle("bagStackSplitter","Stack Splitter","Replace Blizzard's split popup for bag and bank items with the split dialog that also offers Auto Split."),
                {type="label",text="Middle-click an item to pin it. Drag categories on the sidebar to reorder; right-click them to rename or group."})
            Section("WRATH INVENTORY")
            Row(Toggle("enhancedBags","Enable Bags","Use the EllesmereUI bag window instead of the default bags. After turning it off, /reload to hand the bag keys fully back to the default bags."),
                Slider("bagColumns","Columns",4,24,1,"Item columns in the bag window."))
            Row(Toggle("bagIncludeKeyring","Include Keyring","Show the keyring in the bag window."),
                Toggle("bagShowSlots","Show Bag Slot Bar","Show the equipped bag slots above the window (also toggled by the Bags header button)."))
            Row(Toggle("bagShowAltCounts","Show Character Item Counts","Add how many of an item your other characters own to its tooltip."),
                {type="label",text="Characters (header) browses saved bags and banks."})
            local values,order,lookup={none="Select a character"},{"none"},{}
            for _,entry in ipairs(ns.Characters()) do
                if ns.CanDeleteCharacter(entry.realm,entry.name) then
                    local key=entry.realm.."\001"..entry.name; lookup[key]=entry; values[key]=entry.name.." - "..entry.realm; order[#order+1]=key
                end
            end
            Row({type="dropdown",text="Delete Saved Character",values=values,order=order,
                 tooltip="Remove a character's saved bags, bank and gold from the account cache. The character you are logged in on is recorded again automatically and cannot be deleted.",
                 disabled=function() return #order<2 end,disabledTooltip="No other saved characters",
                 getValue=function() return "none" end,
                 setValue=function(key)
                    local entry=lookup[key]; if not entry then return end
                    local function Rebuild() E:InvalidatePageCache(); if E.RefreshPage then E:RefreshPage(true) end end
                    if E.ShowConfirmPopup then
                        E:ShowConfirmPopup({title="Delete Saved Character",message="Delete the saved bags, bank and gold of "..values[key].."?",confirmText="Delete",cancelText="Cancel",
                            onConfirm=function() if ns.DeleteCharacter(entry.realm,entry.name) then Rebuild() end end})
                    else ns.ConfirmDeleteCharacter(entry.realm,entry.name,Rebuild) end
                 end},
                {type="label",text=ns.InventoryCacheSummary().."; saves on logout or UI reload."})
            Button("Show Bags",function() ns.Show("bags") end)
            Button("Show Character Bank",ns.OpenCharacterBank)
            Button("Save Inventory & Reload UI",ns.SaveInventoryAndReload)
            Button("Unlock Mode",function() ns.Show("bags"); if E.ToggleUnlockMode then E:ToggleUnlockMode() end end)
            Button("Reset Window Positions",ns.ResetPositions)
            return math.abs(y)
        end,
        onReset=function()
            if ns.addon.db then ns.addon.db:ResetProfile() end
            if EllesmereUIDB then
                EllesmereUIDB.bagPinnedItems=nil; EllesmereUIDB.bagItemAssignments=nil
                EllesmereUIDB.bagCurrencyByChar=nil; EllesmereUIDB.bagVisualOrder=nil
            end
            ns.CM:Invalidate(); ns.Apply(); E:InvalidatePageCache()
        end,
    })
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
