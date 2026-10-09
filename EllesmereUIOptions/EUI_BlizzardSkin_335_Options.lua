local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
local E=EllesmereUI
local ns=E and E._ModuleNS and E._ModuleNS.EllesmereUIBlizzardSkin
if not ns or not ns.IsWrath then return end
local init=CreateFrame("Frame"); init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent",function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local function Toggle(key,label) return {type="toggle",text=label,getValue=function() return ns.GetValue(key) end,setValue=function(v) ns.SetValue(key,v) end} end
    local function Slider(key,label,low,high,step) return {type="slider",text=label,min=low,max=high,step=step or 1,getValue=function() return ns.GetValue(key) end,setValue=function(v) ns.SetValue(key,v) end} end
    local function Drop(key,label,values,order) return {type="dropdown",text=label,values=values,order=order,getValue=function() return ns.GetValue(key) end,setValue=function(v) ns.SetValue(key,v) end} end
    local function When(cfg,fn) cfg.disabled=function() return not fn() end; return cfg end
    local function On(key) return function() return ns.GetValue(key) and true or false end end
    local function StatColor(spec)
        return {type="colorpicker",text=spec.text.." Color",hasAlpha=false,
            getValue=function() return ns.SectionColor(spec.text,unpack(spec.color)) end,
            setValue=function(r,g,b)
                local p=ns.GetSettings()
                p.statCategoryColors=type(p.statCategoryColors)=="table" and p.statCategoryColors or {}
                p.statCategoryUseColor=type(p.statCategoryUseColor)=="table" and p.statCategoryUseColor or {}
                p.statCategoryColors[spec.text]={r=r,g=g,b=b}; p.statCategoryUseColor[spec.text]=true; ns.Apply()
            end}
    end
    E:RegisterModule("EllesmereUIBlizzardSkin",{
        title="Blizz UI Enhanced",description="Square dark skins for Wrath windows, tooltips, menus and popups.",
        pages={"Blizzard Window Skins","Tooltips, Menus & Popups"},searchTerms="blizzard skin character inspect quest merchant trade mail auction talent spellbook tooltip popup menu font collections wardrobe transmog mount gem socket enchant durability cursor resurrect queue gearscore barber pvp arena battleground score minimap help gm ticket breath fatigue timer stopwatch pullout debug ace3 loot roll need greed",
        buildPage=function(page,parent,y)
            local W=E.Widgets
            local function Row(left,right) local _,h=W:DualRow(parent,y,left,right); y=y-h end
            local function Section(text) local _,h=W:SectionHeader(parent,text,y); y=y-h end
            if page=="Blizzard Window Skins" then
                Section("WINDOWS")
                Row({type="toggle",text="Enable Window Skins",tooltip="Applies to this profile. Keeps your individual window choices.",getValue=ns.WindowsEnabled,setValue=ns.SetWindowsEnabled},
                    {type="toggle",text="Accent Header",getValue=function() local c=ns.GetSettings().blizzWinAccentBar; return type(c)~="table" or c.enabled~=false end,
                    setValue=function(v) local p=ns.GetSettings(); p.blizzWinAccentBar=type(p.blizzWinAccentBar)=="table" and p.blizzWinAccentBar or {}; p.blizzWinAccentBar.enabled=v; ns.Apply() end})
                local shownWindows={}
                for _,spec in ipairs(ns.windows) do
                    if not spec.optional or _G[spec.frames[1]] then shownWindows[#shownWindows+1]=spec end
                end
                for i=1,#shownWindows,2 do
                    local left,right=shownWindows[i],shownWindows[i+1]
                    Row(Toggle(left.key,left.label),right and Toggle(right.key,right.label) or {type="label",text=""})
                end
                Section("CHARACTER ENHANCEMENT")
                Row(Toggle("enhancedCharacterSheet","Enhanced Character Layout"),Toggle("characterItemLevels","Equipment Item Levels"))
                Row(Toggle("characterMissingEnhancements","Missing Enchant, Gem & Buckle Icons"),{type="label",text="Shown at max level. Header shows GearScore."})
                Row(Toggle("showEnchants","Enchants on Equipment Slots"),When(Toggle("charSheetEnchantNames","Show Enchant Names Instead of Icons"),On("showEnchants")))
                Row(When(Slider("charSheetEnchantSize","Enchant Name Size",6,16),On("charSheetEnchantNames")),Toggle("showGems","Socketed Gem Icons"))
                Row(Toggle("showCharSheetDurability","Show Durability"),When(Drop("charSheetDurabilityLocation","Durability Location",
                    {model="Above Model",header="Stats Header",footer="Frame Footer"},{"model","header","footer"}),On("showCharSheetDurability")))
                Row(When(Toggle("charSheetDurabilityShowLabel","Durability Label"),On("showCharSheetDurability")),Toggle("charSheetSocketPanel","Socket Panel & One-Click Gems"))
                Row({type="label",text="Model: left-drag rotates, right-drag pans, wheel zooms. The eye hides slot details."},{type="label",text="Hover the item level for better items in your bags."})
                Row({type="label",text="Fonts follow Global Settings > Fonts > Blizz UI Enhanced."},{type="label",text="Changes apply outside combat."})
                Section("STATS SIDEBAR")
                for _,spec in ipairs(ns.statGroups or {}) do Row(Toggle("showStatCategory_"..spec.key,"Show "..spec.text),StatColor(spec)) end
                Row({type="button",text="Reset Stat Colors & Order",onClick=function()
                    local p=ns.GetSettings(); p.statCategoryColors,p.statCategoryUseColor,p.statSectionsOrder=nil,nil,nil; ns.Apply(); E:InvalidatePageCache()
                end},{type="label",text="Use the arrows on each section header to reorder."})
                Section("INSPECT")
                Row(Toggle("inspectShowItemLevel","Inspect Item Levels"),Toggle("inspectShowEnchants","Inspect Enchants"))
                Row(Toggle("inspectDock","Dock Inspect Beside Character"),{type="label",text="Docks when both windows fit on screen."})
                Section("MERCHANT")
                Row(Toggle("merchantShowAsList","Show Merchant as List"),When(Slider("merchantListRowHeight","List Row Height",24,44),On("merchantShowAsList")))
                Row(Toggle("merchantShowItemLevel","Merchant Item Levels"),{type="label",text="Paging, buying and buyback stay native."})
                Section("WORLD MAP")
                Row(Toggle("worldMapReveal","Reveal Unexplored Areas"),Toggle("worldMapRevealTint","Dim Unexplored Areas"))
                Row(Toggle("worldMapZoneLevels","Zone Level Ranges"),Toggle("worldMapCoords","Player & Cursor Coordinates"))
                Row(Toggle("worldMapInstances","Dungeon & Raid Entrances"),Toggle("worldMapFlightPoints","Flight Points"))
                Row({type="label",text="Hover markers for names, levels and flight master details."},{type="label",text="Flights: gold neutral, blue Alliance, red Horde, green undiscovered."})
            elseif page=="Tooltips, Menus & Popups" then
                Section("TOOLTIPS")
                Row(Toggle("customTooltips","Reskin Tooltips"),Slider("tooltipFontScale","Tooltip Font Scale",.7,1.5,.05))
                Row(Slider("tooltipBorderSize","Tooltip Border Size",0,4),Slider("tooltipBgOpacity","Tooltip Background Opacity",.1,1,.05))
                local tips=On("customTooltips")
                Section("TOOLTIP INFORMATION")
                Row(When(Toggle("tooltipPlayerTitles","Show Player Titles"),tips),When(Toggle("tooltipItemLevel","Inspect Item Level"),tips))
                Row(When(Toggle("tooltipShowGuildRank","Guild Rank"),tips),When(Toggle("tooltipShowTarget","Show Target"),tips))
                Row(When(Toggle("tooltipShowMount","Show Mount & Collected Status"),tips),When(Toggle("tooltipHideHealthStrip","Hide Health Bar"),tips))
                Row(When(Toggle("tooltipShowGearScore","Show GearScore"),tips),{type="label",text="GearScoreLite's own player line replaces it when enabled."})
                Section("TOOLTIP POSITION")
                local cursor=function() return tips() and ns.GetValue("tooltipAnchorCursor") end
                Row(When(Toggle("tooltipAnchorCursor","Anchor to Cursor"),tips),When(Drop("tooltipCursorPosition","Cursor Position",
                    {top="Above Cursor",bottom="Below Cursor",left="Left of Cursor",right="Right of Cursor"},{"top","bottom","left","right"}),cursor))
                Row(When(Slider("tooltipCursorOffsetX","Cursor Offset X",-100,100),cursor),When(Slider("tooltipCursorOffsetY","Cursor Offset Y",-100,100),cursor))
                Row(When(Drop("tooltipGrowthDirection","Growth Direction",{auto="Automatic",up="Up",down="Down"},{"auto","up","down"}),tips),
                    {type="label",text="Move the fixed tooltip position in Unlock Mode."})
                Section("TOOLTIP VISIBILITY")
                Row(When(Drop("tooltipShowMode","Show Tooltips",{always="Always",outOfCombat="Out of Combat",outOfBossCombat="Out of Boss Combat",never="Never"},
                    {"always","outOfCombat","outOfBossCombat","never"}),tips),When(Drop("tooltipShowModifier","Peek Modifier",{none="None",shift="Shift",control="Ctrl",alt="Alt"},{"none","shift","control","alt"}),tips))
                Row(Toggle("uberTooltipsManual","Manage Enhanced Tooltips"),When(Toggle("uberTooltips","Enhanced Tooltips"),On("uberTooltipsManual")))
                Section("MENUS & POPUPS")
                Row(Toggle("reskinGameMenu","Reskin Pause Menu"),Toggle("reskinPopupsMenus","Reskin Popups & Context Menus"))
                Row(Toggle("reskinQueuePopup","Reskin Dungeon Ready & Role Check"),{type="label",text="Native actions, input and tooltip anchoring remain available."})
                Row(Toggle("resurrectAcceptGlow","Resurrect Accept Glow"),Toggle("showQueueTimer","Dungeon Ready Countdown"))
                Row(Toggle("lootRollShowChoices","Show Group Roll Choices"),{type="label",text="Counts on Need/Greed/Disenchant/Pass; hover a button for names."})
                local timer=On("showQueueTimer")
                Row(When(Slider("queueTimerBarHeight","Countdown Bar Height",2,30),timer),When(Slider("queueTimerTextSize","Countdown Text Size",6,24),timer))
                Row(When({type="colorpicker",text="Countdown Text Color",hasAlpha=false,
                    getValue=function() local c=ns.GetSettings().queueTimerTextColor; local QT=E.QUEUE_TIMER or {}
                        if type(c)=="table" then return c.r,c.g,c.b end; return QT.TEXT_R or 1,QT.TEXT_G or .831,QT.TEXT_B or 0 end,
                    setValue=function(r,g,b) ns.GetSettings().queueTimerTextColor={r=r,g=g,b=b}; ns.Apply() end},timer),
                    When(Slider("queueTimerTextOffsetY","Countdown Text Offset",-10,10),timer))
            end
            return math.abs(y)
        end,
        onReset=function()
            local p=ns.GetSettings(); for key in pairs(ns.defaults) do p[key]=nil end
            p.statCategoryColors,p.statCategoryUseColor,p.statSectionsOrder,p.queueTimerTextColor=nil,nil,nil,nil
            if type(p.blizzWinAccentBar)=="table" then p.blizzWinAccentBar.enabled=nil end
            ns.SetWindowsEnabled(true); ns.Apply(); E:InvalidatePageCache()
        end,
    })
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
