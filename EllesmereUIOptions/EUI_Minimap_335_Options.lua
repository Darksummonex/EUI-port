local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
-- Wrath-only Minimap controls: every exposed setting has a native implementation.
local E=EllesmereUI
local ns=E and E._ModuleNS and E._ModuleNS.EllesmereUIMinimap
if not ns or not ns.IsWrath then return end
local init=CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent",function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local function Get(key,fallback)
        local p=ns.GetSettings()
        if not p or p[key]==nil then return fallback end
        return p[key]
    end
    local function Set(key,value)
        local p=ns.GetSettings(); if not p then return end
        p[key]=value; ns.Apply()
    end
    local function Toggle(key,label,fallback,tooltip,disabled)
        return {type="toggle",text=label,tooltip=tooltip,disabled=disabled,
            getValue=function() return Get(key,fallback or false) end,
            setValue=function(v) Set(key,v) end}
    end
    local function Inverse(key,label,tooltip,disabled)
        return {type="toggle",text=label,tooltip=tooltip,disabled=disabled,
            getValue=function() return not Get(key,false) end,
            setValue=function(v) Set(key,not v) end}
    end
    local function Slider(key,label,min,max,step,fallback,disabled)
        return {type="slider",text=label,min=min,max=max,step=step,disabled=disabled,
            getValue=function() return Get(key,fallback) end,
            setValue=function(v) Set(key,v) end}
    end
    local function Dropdown(key,label,values,order,fallback,tooltip,disabled)
        return {type="dropdown",text=label,values=values,order=order,tooltip=tooltip,disabled=disabled,
            getValue=function() return Get(key,fallback) end,
            setValue=function(v) Set(key,v) end}
    end
    local function Extra(key,label,inverse,tooltip)
        return {type="toggle",text=label,tooltip=tooltip,
            getValue=function()
                local t=Get("hideExtraBtns",{}); if inverse then return not t[key] end; return t[key] and true or false
            end,
            setValue=function(v)
                local p=ns.GetSettings(); if not p then return end
                p.hideExtraBtns=p.hideExtraBtns or {}
                if inverse then p.hideExtraBtns[key]=not v else p.hideExtraBtns[key]=v end
                ns.Apply()
            end}
    end
    local function Color(label,read,write,tooltip,disabled)
        return {type="colorpicker",text=label,hasAlpha=false,tooltip=tooltip,disabled=disabled,
            getValue=read,setValue=function(r,g,b) local p=ns.GetSettings(); if p then write(p,r,g,b); ns.Apply() end end}
    end
    local spacer={type="spacer"}
    local positions={topLeft="Top Left",top="Top",topRight="Top Right",left="Left",right="Right",
        bottomLeft="Bottom Left",bottom="Bottom",bottomRight="Bottom Right",aboveMap="Above Map",belowMap="Below Map"}
    local positionOrder={"topLeft","top","topRight","left","right","bottomLeft","bottom","bottomRight","aboveMap","belowMap"}
    local rowModes={blUp="Bottom Left, Upward",tlDown="Top Left, Downward",brUp="Bottom Right, Upward",
        trDown="Top Right, Downward",tlRight="Top Left, Rightward",trLeft="Top Right, Leftward",
        blRight="Bottom Left, Rightward",brLeft="Bottom Right, Leftward"}
    local rowOrder={"blUp","tlDown","brUp","trDown","tlRight","trLeft","blRight","brLeft"}
    local textModes={none="Hide",inside="Inside Map",edge="Map Edge"}
    local textOrder={"none","inside","edge"}
    local tooltipModes={none="None",lockouts="Saved Instances"}
    local tooltipOrder={"none","lockouts"}
    local function Off(key) return function() return not Get(key,false) end end
    local function NoMode(key) return function() return Get(key,"inside")=="none" end end
    E:RegisterModule("EllesmereUIMinimap",{
        title="Minimap",description="Minimap layout and controls for Wrath.",pages={"Minimap"},
        searchTerms="minimap middle click mouse micro menu shortcuts character talents professions guild calendar support flyout addon buttons friends lockouts coordinates fps difficulty classic",
        buildPage=function(page,parent,y)
            if page~="Minimap" then return end
            local W=E.Widgets
            local PP=E.PP or E.PanelPP
            local function Row(left,right) local row,h=W:DualRow(parent,y,left,right); y=y-h; return row end
            local function Section(label) local _,h=W:SectionHeader(parent,label,y); y=y-h end
            -- Swap a placeholder dropdown for the shared checkbox dropdown.
            local function CheckboxDropdown(row,items,getFn,setFn)
                if E._prebuilding or not E.BuildVisOptsCBDropdown or not row or not row._rightRegion then return end
                local region=row._rightRegion
                if region._control then region._control:Hide() end
                local dd,refresh=E.BuildVisOptsCBDropdown(region,210,region:GetFrameLevel()+2,items,getFn,setFn)
                if PP and PP.Point then PP.Point(dd,"RIGHT",region,"RIGHT",-20,0) else dd:SetPoint("RIGHT",region,"RIGHT",-20,0) end
                region._control=dd; region._lastInline=nil
                if E.RegisterWidgetRefresh and refresh then E.RegisterWidgetRefresh(refresh) end
            end
            local function Placeholder(label,tooltip)
                return {type="dropdown",text=label,tooltip=tooltip,values={__placeholder="..."},order={"__placeholder"},
                    getValue=function() return "__placeholder" end,setValue=function() end}
            end
            Section("DISPLAY")
            Row(Toggle("enabled","Enable Minimap",true),
                Toggle("lock","Lock Position",false,"When unlocked, hold Shift and drag the minimap. Position is also available in Unlock Mode."))
            Row(Slider("size","Size",100,600,1,180),
                Dropdown("shape","Shape",{square="Square",rectangular="Rectangular",circle="Circle",textured_circle="Textured Circle"},
                    {"square","rectangular","circle","textured_circle"},"square",nil,function() return Get("useClassicStyle",false) end))
            Row({type="dropdown",text="Style",values={eui="EllesmereUI",classic="Classic WoW UI"},order={"eui","classic"},
                    tooltip="Classic WoW UI wears the vanilla ring, zone banner, zoom buttons and ring-bordered indicators on a round map.",
                    getValue=function() return Get("useClassicStyle",false) and "classic" or "eui" end,
                    setValue=function(v) Set("useClassicStyle",v=="classic") end},
                Toggle("rotateMinimap","Rotate Minimap"))
            local borderValues,borderOrder={solid="Solid"},{"solid"}
            if E.GetBorderTextureDropdown then
                local ok,values,order=pcall(E.GetBorderTextureDropdown)
                if ok and values and order then borderValues,borderOrder=values,order end
            end
            local classicOn=function() return Get("useClassicStyle",false) end
            Row(Slider("borderSize","Border Size",0,8,1,1,classicOn),
                Dropdown("borderTexture","Border Texture",borderValues,borderOrder,"solid","Square and rectangular maps only.",classicOn))
            Row(Color("Border Color",function() return Get("borderR",0),Get("borderG",0),Get("borderB",0) end,
                    function(p,r,g,b) p.borderR,p.borderG,p.borderB=r,g,b; p.borderColor=nil; p.useClassColor=false; p.borderUseClassColor=false end,
                    nil,classicOn),
                {type="dropdown",text="Border Color Source",values={custom="Custom",accent="Accent Color",class="Class Color"},
                    order={"custom","accent","class"},disabled=classicOn,
                    getValue=function()
                        if Get("borderUseClassColor",false) then return "class" end
                        return Get("useClassColor",false) and "accent" or "custom"
                    end,
                    setValue=function(v)
                        local p=ns.GetSettings(); if not p then return end
                        p.borderUseClassColor=v=="class"; p.useClassColor=v=="accent"; ns.Apply()
                    end})
            Row(Slider("borderA","Border Opacity",0,1,.05,1,classicOn),
                Toggle("borderBehind","Show Border Behind",false,"Draw square borders below the map surface.",classicOn))
            local visValues={always="Always",never="Never",mouseover="Mouseover",in_combat="In Combat",
                out_of_combat="Out of Combat",in_party="In Party",in_raid="In Raid",solo="Solo"}
            Row(Dropdown("visibility","Visibility",visValues,
                {"always","never","mouseover","in_combat","out_of_combat","in_party","in_raid","solo"},"always"),
                Slider("opacity","Opacity",10,100,1,100))
            local visItems={}
            for _,item in ipairs(E.VIS_OPT_ITEMS or {}) do
                if not item.key:find("Housing") and not item.key:find("Dragonriding") then visItems[#visItems+1]=item end
            end
            local visRow=Row(Placeholder("Visibility Options"),Toggle("openMicroMenuOnMiddleClick","Middle Click Menu",true,
                "Middle-click the minimap for character, talents, professions, group finder and other native shortcuts. Opens outside combat."))
            if visRow and visRow._leftRegion and not E._prebuilding and E.BuildVisOptsCBDropdown then
                local region=visRow._leftRegion
                if region._control then region._control:Hide() end
                local dd,refresh=E.BuildVisOptsCBDropdown(region,210,region:GetFrameLevel()+2,visItems,
                    function(k) return Get(k,false) end,function(k,v) Set(k,v) end)
                if PP and PP.Point then PP.Point(dd,"RIGHT",region,"RIGHT",-20,0) else dd:SetPoint("RIGHT",region,"RIGHT",-20,0) end
                region._control=dd; region._lastInline=nil
                if E.RegisterWidgetRefresh and refresh then E.RegisterWidgetRefresh(refresh) end
            end
            Section("ZOOM")
            Row(Toggle("scrollZoom","Mouse Wheel Zoom",true),Slider("zoomResetSeconds","Auto Zoom Reset (seconds)",0,15,1,0))
            Row(Inverse("hideZoomButtons","Show Zoom Buttons","EllesmereUI style shows them while the map is hovered."),spacer)
            Section("ELEMENTS")
            Row(Inverse("hideTrackingButton","Show Tracking"),Inverse("hideGameTime","Show Calendar",
                "Hover the calendar for saved instances and server time."))
            Row(Inverse("hideMail","Show Mail Indicator"),
                Dropdown("mailPosition","Mail Position",{button="Element Row",TOPLEFT="Top Left",TOPRIGHT="Top Right",
                    BOTTOMLEFT="Bottom Left",BOTTOMRIGHT="Bottom Right"},{"button","TOPLEFT","TOPRIGHT","BOTTOMLEFT","BOTTOMRIGHT"},"button"))
            local mailFixed=function() return Get("mailPosition","button")=="button" end
            Row(Slider("mailOffsetX","Mail Offset X",-50,50,1,0,mailFixed),Slider("mailOffsetY","Mail Offset Y",-50,50,1,0,mailFixed))
            Row(Dropdown("elementRowPosition","Element Row Position",rowModes,rowOrder,"tlDown",
                    "Tracking, calendar and mail. Round maps place them beside a top clock."),
                Slider("elementRowSpacing","Element Row Spacing",0,20,1,0))
            Row(Slider("elementRowDistance","Element Row Distance",-40,40,1,0),
                Slider("interactableBtnSize","Button Size",14,40,1,21))
            Row(Inverse("hideRaidDifficulty","Show Difficulty Flag"),Inverse("hideQueueStatus","Show Queue Indicators"))
            Row(Inverse("hideWorldMapButton","Show World Map Button"),
                Slider("customTooltipScale","Custom Tooltip Size",.5,2,.05,1))
            Section("ADDON BUTTONS")
            local ungroupRow=Row(Toggle("hideAddonButtons","Hide Addon Buttons"),Placeholder("Ungrouped Buttons",
                "Checked buttons leave the flyout and sit on the button row."))
            CheckboxDropdown(ungroupRow,function()
                    local items={}
                    for _,f in ipairs(ns.ScanButtons and ns.ScanButtons() or {}) do
                        local name=f:GetName()
                        items[#items+1]={key=name,label=(name:gsub("^LibDBIcon10_",""))}
                    end
                    return items
                end,
                function(k) local t=Get("ungroupedButtons",{}); return t[k]~=nil and t[k]~=false end,
                function(k,v)
                    local p=ns.GetSettings(); if not p then return end
                    p.ungroupedButtons=p.ungroupedButtons or {}
                    if v then
                        local top=0
                        for _,order in pairs(p.ungroupedButtons) do top=math.max(top,tonumber(order) or 0) end
                        p.ungroupedButtons[k]=top+1
                    else p.ungroupedButtons[k]=nil end
                    ns.Apply()
                end)
            Row(Slider("addonBtnSize","Flyout Button Size",14,40,1,24),
                Dropdown("flyoutGrowDir","Flyout Direction",{auto="Automatic",up="Up",down="Down",left="Left",right="Right"},
                    {"auto","up","down","left","right"},"auto"))
            Row(Dropdown("btnRowPosition","Button Row Position",rowModes,rowOrder,"blUp"),
                Slider("btnRowSpacing","Button Row Spacing",0,20,1,0))
            Row(Slider("btnRowDistance","Button Row Distance",-40,40,1,0),Toggle("btnBackgrounds","Button Backgrounds",true))
            Row(Toggle("freeMoveBtns","Free Move Buttons",false,"Hold Shift and drag row buttons to nudge them. Reset Button Positions returns them."),
                Extra("groupButton","Show Flyout Button",true))
            Section("EXTRA BUTTONS")
            Row(Extra("friendsOnline","Show Friends Online",true,"Hover for online guild members and friends. Left-click a name to whisper, right-click to invite."),
                Toggle("mouseoverExtraBtns","Extra Buttons on Mouseover",false,"Show the friends and flyout buttons only while the map is hovered."))
            Row(Slider("friendsMaxRows","Friends Max Rows",0,30,1,0),Toggle("friendsShowNotes","Show Friend Notes"))
            Section("CLOCK & ZONE")
            Row(Dropdown("clockMode","Clock",textModes,textOrder,"inside"),
                Dropdown("clockPosition","Clock Position",positions,positionOrder,"top",nil,NoMode("clockMode")))
            Row(Dropdown("clockFormat","Clock Format",{["12h"]="12 Hour",["24h"]="24 Hour"},{"12h","24h"},"12h",nil,NoMode("clockMode")),
                Toggle("clockServer","Use Server Time",false,nil,NoMode("clockMode")))
            Row(Slider("clockScale","Clock Scale",.5,2,.05,1.15,NoMode("clockMode")),
                Dropdown("clockHoverTooltip","Clock Hover",tooltipModes,tooltipOrder,"none",nil,NoMode("clockMode")))
            Row(Slider("clockOffsetX","Clock Offset X",-50,50,1,0,NoMode("clockMode")),
                Slider("clockOffsetY","Clock Offset Y",-50,50,1,0,NoMode("clockMode")))
            Row(Dropdown("locationMode","Zone Text",textModes,textOrder,"inside"),
                Dropdown("locationPosition","Zone Position",positions,positionOrder,"bottom",nil,NoMode("locationMode")))
            Row(Toggle("zoneShowSubZone","Show Subzone",false,nil,NoMode("locationMode")),
                Toggle("zoneReactiveColor","Zone PvP Color",false,nil,NoMode("locationMode")))
            Row(Slider("locationScale","Zone Scale",.5,2,.05,1.15,NoMode("locationMode")),spacer)
            Row(Slider("locationOffsetX","Zone Offset X",-50,50,1,0,NoMode("locationMode")),
                Slider("locationOffsetY","Zone Offset Y",-50,50,1,0,NoMode("locationMode")))
            Section("COORDINATES")
            Row(Toggle("showCoords","Show Coordinates"),
                Dropdown("coordsMode","Coordinates Mode",{always="Always",hover="On Hover"},{"always","hover"},"always",nil,Off("showCoords")))
            Row(Dropdown("coordsPosition","Coordinates Position",positions,positionOrder,"topLeft",nil,Off("showCoords")),
                Slider("coordPrecision","Coordinate Decimals",0,2,1,0,Off("showCoords")))
            Row(Slider("coordsScale","Coordinates Scale",.5,2,.05,1,Off("showCoords")),spacer)
            Section("FPS & LATENCY")
            Row(Toggle("showFPS","Show FPS & Latency"),
                Dropdown("fpsPosition","FPS Position",positions,positionOrder,"bottomLeft",nil,Off("showFPS")))
            Row(Slider("fpsTextSize","FPS Text Size",8,24,1,12,Off("showFPS")),Slider("fpsScale","FPS Scale",.5,2,.05,1,Off("showFPS")))
            Row(Toggle("fpsShowLocalMS","Show Latency",true,nil,Off("showFPS")),
                Slider("fpsUpdateInterval","Update Interval (seconds)",1,5,1,3,Off("showFPS")))
            Row(Slider("fpsOffsetX","FPS Offset X",-50,50,1,0,Off("showFPS")),Slider("fpsOffsetY","FPS Offset Y",-50,50,1,0,Off("showFPS")))
            Row(Dropdown("fpsHoverTooltip","FPS Hover",tooltipModes,tooltipOrder,"none",nil,Off("showFPS")),spacer)
            Section("DIFFICULTY")
            Row(Toggle("diffTextEnabled","Difficulty as Text",false,"Replaces the difficulty flag with a compact readout such as 25H."),
                Dropdown("diffTextPosition","Difficulty Position",positions,positionOrder,"topLeft",nil,Off("diffTextEnabled")))
            Row(Slider("diffTextSize","Difficulty Text Size",8,24,1,12,Off("diffTextEnabled")),
                Toggle("diffTextReactive","Difficulty Tier Colors",false,"Normal bronze, heroic blue.",Off("diffTextEnabled")))
            Row(Slider("diffTextOffsetX","Difficulty Offset X",-50,50,1,0,Off("diffTextEnabled")),
                Slider("diffTextOffsetY","Difficulty Offset Y",-50,50,1,0,Off("diffTextEnabled")))
            Section("ACCENTED TEXT")
            Row(Toggle("fpsUseAccent","Use Accent Color",false,"Description text (FPS/MS suffixes, AM/PM, difficulty letter) follows the accent color."),
                Color("Description Color",function()
                        local c=Get("fpsColor"); if c then return c.r or 1,c.g or 1,c.b or 1 end; return 1,1,1
                    end,function(p,r,g,b) p.fpsColor={r=r,g=g,b=b} end,nil,function() return Get("fpsUseAccent",false) end))
            Row(Toggle("fpsColorSuffix","Color FPS/MS Suffix",true),Toggle("fpsColorClockAMPM","Color Clock AM/PM"))
            Row(Toggle("diffTextAccent","Color Difficulty Letter",false,nil,function() return Get("diffTextReactive",false) end),spacer)
            local _,h=W:WideButton(parent,"Reset Position",y,function()
                local p=ns.GetSettings(); if p then p.position=nil; ns.Apply() end
            end)
            y=y-h
            _,h=W:WideButton(parent,"Reset Button Positions",y,function()
                local p=ns.GetSettings(); if p then p.btnPositions={}; ns.Apply() end
            end)
            return math.abs(y-h)
        end,
        onReset=function()
            if ns.addon.db and ns.addon.db.ResetProfile then ns.addon.db:ResetProfile() end
            ns.Apply(); E:InvalidatePageCache()
        end,
    })
    SLASH_EMM1="/emm"
    SlashCmdList.EMM=function()
        if not InCombatLockdown() then E:ShowModule("EllesmereUIMinimap") end
    end
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
