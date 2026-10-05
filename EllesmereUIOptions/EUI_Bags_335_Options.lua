local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
local E=EllesmereUI
local ns=E and E._ModuleNS and E._ModuleNS.EllesmereUIBags
if not ns or not ns.IsWrath then return end
local init=CreateFrame("Frame"); init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent",function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local function Field(key,label,kind,min,max,step)
        return {type=kind,text=label,min=min,max=max,step=step,
            getValue=function() local p=ns.GetSettings(); return p and p[key] end,
            setValue=function(v) local p=ns.GetSettings(); if p then p[key]=v; ns.Apply() end end}
    end
    local function Toggle(key,label) return Field(key,label,"toggle") end
    local function Slider(key,label,min,max,step) return Field(key,label,"slider",min,max,step or 1) end
    E._ELEMENT_SETTINGS_MAP=E._ELEMENT_SETTINGS_MAP or {}
    for _,key in ipairs({"EUI335_bags","EUI335_bank"}) do E._ELEMENT_SETTINGS_MAP[key]={module="EllesmereUIBags",page="Bags"} end
    E:RegisterModule("EllesmereUIBags",{title="Bags",description="Unified Wrath bags and bank with native item actions.",pages={"Bags"},
        searchTerms="bags bank inventory item search category crafting reagents food drink potions flask elixir gold money total quality level keyring slots saved offline alts characters cache save databroker",
        buildPage=function(page,parent,y)
            local W=E.Widgets
            local function Row(a,b) local _,h=W:DualRow(parent,y,a,b); y=y-h end
            local function Section(text) local _,h=W:SectionHeader(parent,text,y); y=y-h end
            local function Button(text,fn) local _,h=W:WideButton(parent,text,y,fn); y=y-h end
            Section("DISPLAY")
            Row(Toggle("enhancedBags","Enable Bags"),Toggle("enhancedBank","Enable Bank"))
            Row(Slider("bagScale","Window Scale",.5,1.5,.05),Slider("bgAlpha","Background Opacity",.1,1,.05))
            Row(Slider("bagColumns","Columns",4,20),Slider("bagIconSize","Item Size",20,60))
            Row(Slider("bagSpacing","Item Spacing",0,12),Slider("bagItemIconZoom","Icon Crop",0,.2,.01))
            Section("INVENTORY")
            Row(Toggle("bagGroupByCategory","Group by Category"),Toggle("bagHideEmptySlots","Hide Empty Slots"))
            local values,order={[0]="All Items"},{0}
            for i,name in ipairs(ns.categoryNames) do values[i]=name; order[#order+1]=i end
            local category=Field("bagCategoryFilter","Item Category","dropdown"); category.values,category.order=values,order
            Row(category,{type="label",text="Hover the bag footer for all characters' gold."})
            Row(Toggle("bagIncludeKeyring","Include Keyring"),Toggle("bagSortView","Sort View by Name"))
            Row(Toggle("showItemlevelInBags","Show Item Level"),Toggle("bagDesaturateJunkItems","Desaturate Junk"))
            Row(Toggle("bagShowSlots","Show Bag Slot Bar"),Toggle("bagShowAltCounts","Show Character Item Counts"))
            Row({type="label",text="Characters selects saved bags/bank. Bank opens anywhere."},{type="label",text="Visit each character and its bank to save contents."})
            Row({type="label",text=ns.InventoryCacheSummary()},{type="label",text="EUI account cache; saves on logout or UI reload."})
            Section("TEXT")
            Row(Slider("bagCountFontSize","Item Count Size",8,16),Slider("itemlevelFontSize","Item Level Size",8,16))
            Row(Slider("bagCatTitleSize","Category Title Size",8,16),{type="label",text="Fonts follow Global Settings > Fonts"})
            Button("Show Bags",function() ns.Show("bags") end)
            Button("Show Character Bank",ns.OpenCharacterBank)
            Button("Save Inventory & Reload UI",ns.SaveInventoryAndReload)
            Button("Unlock Mode",function() ns.Show("bags"); if E.ToggleUnlockMode then E:ToggleUnlockMode() end end)
            Button("Reset Window Positions",ns.ResetPositions)
            return math.abs(y)
        end,
        onReset=function() if ns.addon.db then ns.addon.db:ResetProfile() end; ns.Apply(); E:InvalidatePageCache() end,
    })
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
