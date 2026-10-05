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
    local function Toggle(key,label,fallback,tooltip)
        return {type="toggle",text=label,tooltip=tooltip,
            getValue=function() return Get(key,fallback or false) end,
            setValue=function(v) Set(key,v) end}
    end
    local function Slider(key,label,min,max,step,fallback)
        return {type="slider",text=label,min=min,max=max,step=step,
            getValue=function() return Get(key,fallback) end,
            setValue=function(v) Set(key,v) end}
    end
    local function Dropdown(key,label,values,order,fallback)
        return {type="dropdown",text=label,values=values,order=order,
            getValue=function() return Get(key,fallback) end,
            setValue=function(v) Set(key,v) end}
    end
    E:RegisterModule("EllesmereUIMinimap",{
        title="Minimap",description="Minimap layout and controls for Wrath.",pages={"Minimap"},
        searchTerms="minimap middle click mouse micro menu shortcuts character talents professions guild calendar support",
        buildPage=function(page,parent,y)
            if page~="Minimap" then return end
            local W=E.Widgets
            local function Row(left,right) local _,h=W:DualRow(parent,y,left,right); y=y-h end
            local function Section(label) local _,h=W:SectionHeader(parent,label,y); y=y-h end
            Section("DISPLAY")
            Row(Toggle("enabled","Enable Minimap",true),
                Toggle("lock","Lock Position",false,"When unlocked, hold Shift and drag the minimap. Position is also available in Unlock Mode."))
            Row(Slider("size","Size",100,400,1,180),
                Dropdown("shape","Shape",{square="Square",circle="Circle"},{"square","circle"},"square"))
            Row(Slider("borderSize","Border Size",0,8,1,1),Toggle("useClassColor","Class Colored Border"))
            Row({type="colorpicker",text="Border Color",hasAlpha=true,
                getValue=function() return Get("borderR",0),Get("borderG",0),Get("borderB",0),Get("borderA",1) end,
                setValue=function(r,g,b,a)
                    local p=ns.GetSettings(); if not p then return end
                    p.borderR,p.borderG,p.borderB,p.borderA=r,g,b,a or 1; p.useClassColor=false; ns.Apply()
                end},Slider("opacity","Opacity",10,100,1,100))
            local visValues={always="Always",never="Never",mouseover="Mouseover",in_combat="In Combat",
                out_of_combat="Out of Combat",in_party="In Party",in_raid="In Raid",solo="Solo"}
            Row(Dropdown("visibility","Visibility",visValues,
                {"always","never","mouseover","in_combat","out_of_combat","in_party","in_raid","solo"},"always"),
                Toggle("visHideMounted","Hide when Mounted"))
            Row(Toggle("visHideNoTarget","Hide without Target"),Toggle("rotateMinimap","Rotate Minimap"))
            Section("ZOOM & BUTTONS")
            Row(Toggle("scrollZoom","Mouse Wheel Zoom",true),Slider("zoomResetSeconds","Reset Zoom (seconds)",0,15,1,0))
            Row(Toggle("hideZoomButtons","Hide Zoom Buttons"),Toggle("hideTrackingButton","Hide Tracking Button"))
            Row(Toggle("hideMail","Hide Mail Indicator"),Toggle("hideGameTime","Hide Calendar Button"))
            Row(Toggle("hideRaidDifficulty","Hide Difficulty Indicator"),
                Toggle("openMicroMenuOnMiddleClick","Middle Click Menu",true,"Middle-click the minimap for character, talents, professions, group finder and other native shortcuts. Opens outside combat."))
            Row(Toggle("groupAddonButtons","Group Addon Buttons",false,"Collect addon minimap buttons in the + popup. Their own click actions are preserved."),
                Slider("addonBtnSize","Grouped Button Size",14,40,1,24))
            Row(Toggle("hideAddonButtons","Hide Addon Buttons"),
                Toggle("hideQueueStatus","Hide Queue Indicators"))
            Section("TEXT")
            Row(Dropdown("clockMode","Clock",{inside="Show",none="Hide"},{"inside","none"},"inside"),
                Dropdown("clockFormat","Clock Format",{["12h"]="12 Hour",["24h"]="24 Hour"},{"12h","24h"},"12h"))
            Row(Toggle("clockServer","Use Server Time"),Toggle("showFPS","Show FPS & Latency"))
            Row(Dropdown("locationMode","Zone Text",{inside="Show",none="Hide"},{"inside","none"},"inside"),
                Toggle("zoneShowSubZone","Show Subzone"))
            Row(Toggle("zoneReactiveColor","Zone PvP Color"),Toggle("showCoords","Show Coordinates"))
            Row(Slider("coordPrecision","Coordinate Decimals",0,2,1,0),{type="label",text=""})
            local _,h=W:WideButton(parent,"Reset Position",y,function()
                local p=ns.GetSettings(); if p then p.position=nil; ns.Apply() end
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
