local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
local E=EllesmereUI
local ns=E and E._ModuleNS and E._ModuleNS.EllesmereUIResourceBars
if not ns or not ns.IsWrath then return end
local init=CreateFrame("Frame"); init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent",function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    ns.selectedWrathBar=ns.selectedWrathBar or "primary"
    function ns.SelectWrathBar(key,refresh)
        if not ns.labels[key] then return end; ns.selectedWrathBar=key
        if E.InvalidatePageCache then E:InvalidatePageCache() end
        if refresh~=false and E.RefreshPage then E:RefreshPage(true) end
    end
    E._ELEMENT_SETTINGS_MAP=E._ELEMENT_SETTINGS_MAP or {}
    for _,key in ipairs(ns.order) do local selected=key
        E._ELEMENT_SETTINGS_MAP[ns.keys[key]]={module="EllesmereUIResourceBars",page="Bars",sectionName="BAR SELECTION",highlightText="Select Bar",preSelectFn=function() ns.SelectWrathBar(selected,false) end}
    end
    local function Field(bar,key,label,kind,min,max,step)
        return {type=kind,text=label,min=min,max=max,step=step,
            getValue=function() local p=ns.GetSettings(); return p and (bar and p[bar] or p)[key] end,
            setValue=function(value) local p=ns.GetSettings(); if p then (bar and p[bar] or p)[key]=value; ns.Apply() end end}
    end
    local function Toggle(bar,key,label) return Field(bar,key,label,"toggle") end
    local function Slider(bar,key,label,min,max,step) return Field(bar,key,label,"slider",min,max,step or 1) end
    E:RegisterModule("EllesmereUIResourceBars",{title="Resource Bars",description="Wrath health, power, class resources, cast, GCD and totem timers.",pages={"Bars"},
        searchTerms="resource mana rage energy runic power combo points runes cast channel cooldown gcd shaman totems",
        buildPage=function(page,parent,y)
            local W=E.Widgets; local key=ns.selectedWrathBar
            local function Row(a,b) local _,h=W:DualRow(parent,y,a,b); y=y-h end
            local function Section(text) local _,h=W:SectionHeader(parent,text,y); y=y-h end
            local function Button(text,fn) local _,h=W:WideButton(parent,text,y,fn); y=y-h end
            Section("BAR SELECTION")
            Row({type="dropdown",text="Select Bar",values=ns.labels,order=ns.order,getValue=function() return ns.selectedWrathBar end,setValue=ns.SelectWrathBar},Toggle(key,"enabled","Show Bar"))
            Row(Toggle(nil,"enabled","Enable Resource Bars"),{type="label",text="Health and Cast Bar start disabled"})
            Section("LAYOUT")
            Row(Slider(key,key=="secondary" and "pipWidth" or "width","Width",60,600),Slider(key,key=="secondary" and "pipHeight" or "height","Height",3,60))
            if key=="secondary" then
                Row(Slider(key,"pipSpacing","Pip Spacing",0,12),{type="label",text="Rogue / Cat: combo points. DK: six runes."})
            elseif key=="castBar" then
                Row(Toggle(key,"showIcon","Show Spell Icon"),{type="label",text="Replaces the native player cast bar"})
                Row(Toggle(key,"showChannelTicks","Show Channel Ticks"),{type="label",text="Wrath channel pulse positions"})
            elseif key=="totemBar" then Row({type="label",text="Shaman: Fire, Earth, Water, Air"},{type="label",text="Shown while a totem is active"})
            elseif key=="health" then Row(Toggle(key,"classColored","Class Color"),{type="label",text=""}) end
            if key~="gcdBar" then
                Section("TEXT")
                Row(Toggle(key,"showText","Show Text"),Slider(key,key=="castBar" and "spellTextSize" or key=="totemBar" and "timerSize" or "textSize","Text Size",8,24))
                if key=="castBar" then Row(Slider(key,"timerSize","Timer Size",8,24),{type="label",text=""}) end
            end
            Section("TEXTURES")
            local texture={type="dropdown",text=(key=="castBar" or key=="gcdBar") and "Bar Texture" or "Resource Bar Texture",
                values=_ERB_BarTextureNames,order=_ERB_BarTextureOrder,
                getValue=function() local p=ns.GetSettings(); if not p then return "none" end; return (key=="castBar" or key=="gcdBar") and p[key].texture or p.general.barTexture end,
                setValue=function(v) local p=ns.GetSettings(); if p then if key=="castBar" or key=="gcdBar" then p[key].texture=v else p.general.barTexture=v; p.splitTex=false end; ns.Apply() end end}
            Row(texture,{type="label",text="More fonts and textures in Global Settings"})
            Button("Preview Enabled Bars",function() ns.SetPreview(true) end)
            Button("End Preview",function() ns.SetPreview(false) end)
            Button("Unlock Mode",function() if E.ToggleUnlockMode then E:ToggleUnlockMode() end end)
            Button("Reset Bar Positions",ns.ResetPositions)
            return math.abs(y)
        end,
        onReset=function() if ns.addon.db then ns.addon.db:ResetProfile() end; ns.Apply(); E:InvalidatePageCache() end,
    })
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
