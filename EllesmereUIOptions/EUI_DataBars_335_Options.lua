local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
local E=EllesmereUI
local ns=E and E._ModuleNS and E._ModuleNS.EllesmereUIDataBars
if not ns or not ns.IsWrath then return end
local init=CreateFrame("Frame"); init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent",function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local template,blockType="minimapc","clock"
    local function Refresh() E:InvalidatePageCache(); E:RefreshPage(true) end
    local function Selected() local cfg=ns.GetBar(ns.selectedBarId); if not cfg then cfg=ns.BarsInOrder()[1]; ns.selectedBarId=cfg and cfg.id end; return cfg end
    local function Label(text) return {type="label",text=text} end
    local function Field(store,key,label,kind,min,max,step)
        return {type=kind,text=label,min=min,max=max,step=step or 1,
            getValue=function() local t=store(); return t and t[key] end,
            setValue=function(v) local t=store(); if t then t[key]=v; ns.Apply() end end}
    end
    local function DD(store,key,label,values,order) local c=Field(store,key,label,"dropdown"); c.values,c.order=values,order; return c end
    E:RegisterModule("EllesmereUIDataBars",{title="DataBars",description="Configurable Wrath information bars with native game data.",pages={"DataBars"},
        searchTerms="data bars clock fps latency gold bags bank inventory coordinates location durability experience XP reputation currency talent spec professions hearthstone micro menu item level audio volume spacer",
        buildPage=function(page,parent,y)
            local W=E.Widgets
            local function Row(a,b) local _,h=W:DualRow(parent,y,a,b or Label("")); y=y-h end
            local function Section(text) local _,h=W:SectionHeader(parent,text,y); y=y-h end
            local function Button(text,fn) local _,h=W:WideButton(parent,text,y,fn); y=y-h end
            local cfg=Selected()
            Section("DATA BARS")
            Row(Field(ns.GetProfile,"enabled","Enable DataBars","toggle"),Label("Bar changes apply outside combat"))
            local values,order={},{}
            for _,bar in ipairs(ns.BarsInOrder()) do values[bar.id]=bar.name; order[#order+1]=bar.id end
            if cfg then Row({type="dropdown",text="Select Bar",values=values,order=order,getValue=function() return ns.selectedBarId end,
                setValue=function(v) ns.selectedBarId=v; Refresh() end},Label("Configure one bar at a time")) end
            Row({type="dropdown",text="New Bar Template",values={bottom="Bottom Info Bar",minimapc="Minimap Companion",microstrip="Micro Menu Strip",empty="Empty Bar"},order={"bottom","minimapc","microstrip","empty"},getValue=function() return template end,setValue=function(v) template=v end})
            Button("Create DataBar",function() if ns.CreateBar(template) then Refresh() end end)
            if not cfg then return math.abs(y) end
            local function Store() return ns.GetBar(cfg.id) end
            Section("BAR SETTINGS")
            Row(Field(Store,"name","Bar Name","input"),Field(Store,"enabled","Show This Bar","toggle"))
            Row(DD(Store,"orientation","Orientation",{H="Horizontal",V="Vertical"},{"H","V"}),DD(Store,"lengthMode","Bar Length Mode",{custom="Custom",full="Full Screen"},{"custom","full"}))
            Row(Field(Store,"length","Bar Length","slider",120,2500,10),Field(Store,"thickness","Bar Thickness","slider",20,100))
            Row(Field(Store,"scale","Bar Scale","slider",.5,2,.05),Field(Store,"fontScale","Text Scale","slider",60,180,5))
            Row(Field(Store,"fontSize","Font Size","slider",8,24),Field(Store,"spacing","Block Spacing","slider",0,20))
            Row(DD(Store,"sizingMode","Block Sizes",{even="Even Split",weighted="Custom Width Weights"},{"even","weighted"}),DD(Store,"theme","Bar Theme",{eui="EllesmereUI",modern="Flat Dark"},{"eui","modern"}))
            Row(Field(Store,"hideBorder","Hide Border","toggle"),Field(Store,"bgAlpha","Background Opacity","slider",0,1,.05))
            Row(DD(Store,"visibility","Visibility",{always="Always",combat="In Combat",outofcombat="Out of Combat",group="In Group"},{"always","combat","outofcombat","group"}),Label("Move bars in Unlock Mode"))
            Button("Unlock Mode",function() if E.ToggleUnlockMode then E:ToggleUnlockMode() end end)
            Button("Reset Bar Position",function() cfg.savedPos=nil; ns.Apply() end)
            Button("Delete Selected DataBar",function() ns.DeleteBar(cfg.id); Refresh() end)
            Section("BLOCKS")
            local types,typeOrder={},{}
            for _,b in ipairs(ns.BLOCK_TYPES) do types[b.key]=b.label; typeOrder[#typeOrder+1]=b.key end
            Row({type="dropdown",text="Block To Add",values=types,order=typeOrder,getValue=function() return blockType end,setValue=function(v) blockType=v end})
            Button("Add Block",function() ns.AddBlock(cfg.id,blockType); Refresh() end)
            for index,b in ipairs(cfg.blocks) do
                local id=b.id
                local function Settings() local block=ns.GetBlock(cfg.id,id); return block and block.settings end
                Section(index..". "..(types[b.type] or b.type))
                Row(Field(function() return ns.GetBlock(cfg.id,id) end,"width","Width Weight","slider",10,600,10),Label("Used with Custom Width Weights"))
                if b.type=="clock" then Row(Field(Settings,"localTime","Local Time","toggle"),Field(Settings,"twentyFour","24 Hour Clock","toggle"))
                elseif b.type=="location" then Row(Field(Settings,"showSubZone","Show Subzone","toggle"))
                elseif b.type=="coords" then Row(Field(Settings,"hideInInstance","Hide Instance Coordinates","toggle"),Field(Settings,"precision","Coordinate Decimals","slider",0,2))
                elseif b.type=="bags" then Row(DD(Settings,"value","Bag Slot Count",{free="Free Slots",used="Used Slots"},{"free","used"}))
                elseif b.type=="xprep" then Row(DD(Settings,"mode","Progress Mode",{auto="XP Below Max Level / Reputation At Max",xp="Experience",reputation="Reputation"},{"auto","xp","reputation"}))
                elseif b.type=="currency" then local currencyValues,currencyOrder=ns.BuildCurrencyList(); Row(DD(Settings,"currencyKey","Currency",currencyValues,currencyOrder),Label("Expand categories in Character > Currency"))
                elseif b.type=="ilvl" then Row(Field(Settings,"precision","Item Level Decimals","slider",0,2))
                elseif b.type=="audio" then Row(DD(Settings,"channel","Audio Channel",{Master="Master",SFX="Sound Effects",Music="Music",Ambience="Ambience"},{"Master","SFX","Music","Ambience"})) end
                Button("Move Block "..index.." Left / Up",function() ns.MoveBlock(cfg.id,id,-1); Refresh() end)
                Button("Move Block "..index.." Right / Down",function() ns.MoveBlock(cfg.id,id,1); Refresh() end)
                Button("Remove Block "..index,function() ns.RemoveBlock(cfg.id,id); Refresh() end)
            end
            return math.abs(y)
        end,
        onReset=function() if InCombatLockdown() then return end; ns.addon.db:ResetProfile(); ns.GetProfile().initialized=true; ns.Apply(); Refresh() end})
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
