local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
-- Retail Resource Bars pages on Wrath widgets; every control has a native implementation.
local E=EllesmereUI
local ns=E and E._ModuleNS and E._ModuleNS.EllesmereUIResourceBars
if not ns or not ns.IsWrath then return end
local init=CreateFrame("Frame"); init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent",function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    if ns.RegisterSettingsTargets then ns.RegisterSettingsTargets() end
    local O={}
    ns.Options=O
    local _,CLASS=UnitClass("player")
    function O.Cfg(bar)
        local p=ns.GetSettings(); if not p then return nil end
        if not bar then return p end
        if bar=="druidMana" then return p.primary.foreverDruidMana end
        return p[bar]
    end
    function O.Get(bar,key,fallback) local c=O.Cfg(bar); if not c or c[key]==nil then return fallback end; return c[key] end
    function O.Set(bar,key,value) local c=O.Cfg(bar); if c then c[key]=value; ns.Apply() end end
    function O.Toggle(bar,key,label,tooltip,disabled)
        return {type="toggle",text=label,tooltip=tooltip,disabled=disabled,
            getValue=function() return O.Get(bar,key,false) and true or false end,setValue=function(v) O.Set(bar,key,v) end}
    end
    function O.Slider(bar,key,label,min,max,step,fallback,tooltip,disabled)
        return {type="slider",text=label,min=min,max=max,step=step or 1,tooltip=tooltip,disabled=disabled,
            getValue=function() return O.Get(bar,key,fallback or min) end,setValue=function(v) O.Set(bar,key,v) end}
    end
    -- 0-1 alpha keys shown as a 0-100 slider, as Retail does.
    function O.Percent(bar,key,label,fallback,tooltip,disabled)
        return {type="slider",text=label,min=0,max=100,step=5,tooltip=tooltip,disabled=disabled,
            getValue=function() return math.floor((O.Get(bar,key,fallback or 1))*100+.5) end,setValue=function(v) O.Set(bar,key,v/100) end}
    end
    function O.Dropdown(bar,key,label,values,order,fallback,tooltip,disabled)
        return {type="dropdown",text=label,values=values,order=order,tooltip=tooltip,disabled=disabled,
            getValue=function() return O.Get(bar,key,fallback) end,setValue=function(v) O.Set(bar,key,v) end}
    end
    -- Flat Retail color keys: prefix.."R"/"G"/"B"/"A".
    function O.Color(bar,prefix,label,hasAlpha,disabled,tooltip)
        return {type="colorpicker",text=label,hasAlpha=hasAlpha,tooltip=tooltip,disabled=disabled,
            getValue=function()
                local c=O.Cfg(bar) or {}
                return c[prefix.."R"] or 1,c[prefix.."G"] or 1,c[prefix.."B"] or 1,c[prefix.."A"] or 1
            end,
            setValue=function(r,g,b,a)
                local c=O.Cfg(bar); if not c then return end
                c[prefix.."R"],c[prefix.."G"],c[prefix.."B"]=r,g,b
                if hasAlpha then c[prefix.."A"]=a or 1 end
                ns.Apply()
            end}
    end
    function O.Off(bar) return function() return not O.Get(bar,"enabled",false) end end
    function O.Label(text) return {type="label",text=text or ""} end
    O.spacer={type="label",text=""}
    function O.BorderTextures()
        if E.GetBorderTextureDropdown then
            local ok,values,order=pcall(E.GetBorderTextureDropdown)
            if ok and values and order then return values,order end
        end
        return {solid="Solid"},{"solid"}
    end
    O.strata={BACKGROUND="Background",LOW="Low",MEDIUM="Medium",HIGH="High",DIALOG="Dialog"}
    O.strataOrder={"BACKGROUND","LOW","MEDIUM","HIGH","DIALOG"}
    O.anchors={LEFT="Left",CENTER="Center",RIGHT="Right"}
    O.anchorOrder={"LEFT","CENTER","RIGHT"}
    O.orient={HORIZONTAL="Horizontal",VERTICAL_UP="Vertical Up",VERTICAL_DOWN="Vertical Down"}
    O.orientOrder={"HORIZONTAL","VERTICAL_UP","VERTICAL_DOWN"}
    O.gradDir={HORIZONTAL="Horizontal",VERTICAL="Vertical"}
    O.gradOrder={"HORIZONTAL","VERTICAL"}
    O.sides={left="Left",center="Center",right="Right"}
    O.sideOrder={"left","center","right"}

    -- Page context: rows advance one shared y.
    function O.Context(W,parent,y)
        local B={W=W,parent=parent,y=y}
        function B.Row(a,b) local row,h=W:DualRow(parent,B.y,a,b or O.spacer); B.y=B.y-h; return row end
        function B.Section(text) local _,h=W:SectionHeader(parent,text,B.y); B.y=B.y-h end
        function B.Button(text,fn) local _,h=W:WideButton(parent,text,B.y,fn); B.y=B.y-h end
        function B.Visibility(bar,rightCfg)
            if E.BuildVisibilityRow and not E._prebuilding then
                local ok,_,h=pcall(E.BuildVisibilityRow,W,parent,B.y,{getStore=function() return O.Cfg(bar) end,legacyKey="visibility",
                    caps={partyIncludesRaid=false},onChanged=function() ns.Apply() end,onOptionChanged=function() ns.UpdateVisibility() end},rightCfg)
                if ok and h then B.y=B.y-h; return end
            end
            B.Row(O.Dropdown(bar,"visibility","Visibility",{always="Always",never="Never",mouseover="Mouseover",in_combat="In Combat",
                out_of_combat="Out of Combat",target="Enemy Target",in_raid="In Raid",in_party="In Party",solo="Solo"},
                {"always","never","mouseover","in_combat","out_of_combat","target","in_raid","in_party","solo"},"always"),rightCfg)
        end
        -- Shared border rows (size, color, Retail border style).
        function B.Border(bar,dis)
            local tv,to=O.BorderTextures()
            B.Row(O.Slider(bar,"borderSize","Border Size",0,8,1,1,nil,dis),O.Color(bar,"border","Border Color",true,dis))
            B.Row(O.Dropdown(bar,"borderTexture","Border Style",tv,to,"solid","Retail border styles from the shared border catalogue.",dis),
                O.Slider(bar,"stockBorderScale","Classic Frame Size",30,150,5,60,"Size of the Classic WoW UI frame when the classic style is on.",dis))
        end
        -- Fade out of combat and opacity (Retail's Opacity row and its cog).
        function B.Opacity(bar,dis)
            B.Row(O.Percent(bar,"barAlpha","Opacity",1,nil,dis),O.Slider(bar,"fillOpacity","Fill Color",0,100,1,100,
                "Opacity of the bar fill; below 100 the world shows through the fill instead of the background.",dis))
            B.Row(O.Toggle(bar,"oocFadeEnabled","Fade Out of Combat",nil,dis),
                O.Percent(bar,"oocAlpha","Out of Combat Opacity",.5,nil,function() return dis() or not O.Get(bar,"oocFadeEnabled") end))
        end
        function B.Gradient(bar,dis)
            local gd=function() return dis() or not O.Get(bar,"gradientEnabled") end
            B.Row(O.Toggle(bar,"gradientEnabled","Enable Gradient",nil,dis),O.Color(bar,"gradient","Gradient End Color",true,gd))
            B.Row(O.Dropdown(bar,"gradientDir","Gradient Direction",O.gradDir,O.gradOrder,"HORIZONTAL",nil,gd),O.spacer)
        end
        function B.Thresholds(bar,dis,isPower,isPips)
            local td=function() return dis() or not O.Get(bar,"thresholdEnabled") end
            B.Row(O.Toggle(bar,"thresholdEnabled","Enable Threshold",nil,dis),
                isPips and O.Slider(bar,"thresholdCount","Threshold Count",1,6,1,3,nil,td) or O.Slider(bar,"thresholdPct","Threshold %",1,99,1,30,nil,td))
            B.Row(O.Color(bar,"threshold","Threshold Color",true,td),O.Toggle(bar,"thresholdTextInstead","Color Text Instead",
                "Colors the bar text instead of the fill when the threshold applies.",td))
            if isPower or isPips then
                B.Row(O.Toggle(bar,"thresholdPartialOnly",isPips and "Only Below Threshold" or "Below Threshold Only",
                    "Uses the threshold color below the value instead of at or above it.",td),O.spacer)
            end
            if not isPips then
                local hd=function() return dis() or not O.Get(bar,"hashEnabled") end
                B.Row(O.Toggle(bar,"hashEnabled","Hash Lines",nil,dis),{type="input",text="Hash Values",tooltip="Comma separated, for example 25, 50, 75.",disabled=hd,
                    getValue=function() return O.Get(bar,"hashValues","") end,setValue=function(v) O.Set(bar,"hashValues",v) end})
                B.Row(O.Dropdown(bar,"hashMode","Hash Mode",{percent="Percent",value="Value"},{"percent","value"},"percent",nil,hd),
                    O.Slider(bar,"hashWidth","Hash Width",1,6,1,1,nil,hd))
                B.Row(O.Color(bar,"hashColor","Hash Color",true,hd),O.spacer)
            end
        end
        function B.DruidForms(bar,dis)
            if CLASS~="DRUID" then return end
            local function Form(bucket,label)
                return {type="toggle",text=label,disabled=dis,
                    getValue=function() local c=O.Cfg(bar); return c and type(c.barDisabledForms)=="table" and c.barDisabledForms[bucket] and true or false end,
                    setValue=function(v) local c=O.Cfg(bar); if not c then return end; if type(c.barDisabledForms)~="table" then c.barDisabledForms={} end; c.barDisabledForms[bucket]=v or nil; ns.Apply() end}
            end
            B.Row(Form("energy","Hide in Cat Form"),Form("rage","Hide in Bear Form"))
            B.Row(Form("moonkin","Hide in Moonkin Form"),Form("mana","Hide in Caster Forms"))
        end
        return B
    end

    --------------------------------------------------------------------------
    -- Page: Class, Power and Health Bars
    --------------------------------------------------------------------------
    function O.General(B)
        B.Section("GENERAL")
        B.Row(O.Toggle(nil,"enabled","Enable Resource Bars"),O.Dropdown("general","frameStrata","Frame Strata",O.strata,O.strataOrder,"MEDIUM"))
        local tex={type="dropdown",text="Bar Texture",values=_ERB_BarTextureNames,order=_ERB_BarTextureOrder,
            getValue=function() return O.Get("general","barTexture","none") end,setValue=function(v) O.Set("general","barTexture",v) end}
        B.Row(tex,O.Toggle(nil,"splitTex","Choose texture per bar"))
        local split=function() return not O.Get(nil,"splitTex") end
        B.Row(O.Dropdown("health","barTexture","Health Texture",_ERB_BarTextureNames,_ERB_BarTextureOrder,"none",nil,split),
            O.Dropdown("primary","barTexture","Power Texture",_ERB_BarTextureNames,_ERB_BarTextureOrder,"none",nil,split))
        B.Row(O.Toggle(nil,"useClassicStyleBars","Classic Style Bars","Wraps the health, power and class resource bars in the Classic WoW UI cast bar frame."),
            {type="label",text="With per-bar textures on, Bar Texture applies to the class resource."})
        B.Row({type="toggle",text="Smooth Bars",getValue=function() return O.Get("primary","smoothBars") and true or false end,
            setValue=function(v) local p=ns.GetSettings(); if not p then return end; p.health.smoothBars=v; p.primary.smoothBars=v; p.secondary.smoothBars=v; ns.Apply() end},
            {type="label",text="Drag bars in Unlock Mode; the cog opens these options."})
    end
    function O.Health(B)
        local dis=O.Off("health")
        B.Section("HEALTH BAR")
        B.Row(O.Toggle("health","enabled","Show Health Bar"),O.Dropdown("health","orientation","Orientation",O.orient,O.orientOrder,"HORIZONTAL",nil,dis))
        B.Row(O.Slider("health","height","Bar Height",1,60,1,16,nil,dis),O.Slider("health","width","Bar Width",50,800,1,214,nil,dis))
        B.Border("health",dis)
        B.Opacity("health",dis)
        B.Row(O.Toggle("health","customColored","Custom Fill Color","Off uses your class color.",dis),
            O.Color("health","fill","Fill Color",false,function() return dis() or not O.Get("health","customColored") end))
        B.Row(O.Color("health","bg","Background Color",true,dis),O.spacer)
        B.Gradient("health",dis)
        B.Row(O.Dropdown("health","textFormat","Health Text",{none="None",perhp="Health %",perhpnosign="Health % (No Sign)",curhpshort="Health #",
            perhpnum="Health % | #",both="Health # | %"},{"none","perhp","perhpnosign","curhpshort","perhpnum","both"},"none",nil,dis),
            O.Slider("health","textSize","Text Size",8,24,1,11,nil,dis))
        B.Row(O.Toggle("health","textCustomColored","Custom Text Color","Off colors the text like the fill.",dis),O.Color("health","textFill","Text Color",true,dis))
        B.Row(O.Dropdown("health","textAnchor","Text Anchor",O.anchors,O.anchorOrder,"CENTER",nil,dis),O.spacer)
        B.Row(O.Slider("health","textXOffset","Text X Offset",-100,100,1,0,nil,dis),O.Slider("health","textYOffset","Text Y Offset",-100,100,1,0,nil,dis))
        B.Thresholds("health",dis,false,false)
        B.Visibility("health")
        B.DruidForms("health",dis)
    end
    function O.Power(B)
        local dis=O.Off("primary")
        B.Section("POWER BAR")
        B.Row(O.Toggle("primary","enabled","Show Power Bar"),O.Dropdown("primary","orientation","Orientation",O.orient,O.orientOrder,"HORIZONTAL",nil,dis))
        B.Row(O.Slider("primary","height","Bar Height",1,60,1,14,nil,dis),O.Slider("primary","width","Bar Width",50,800,1,214,nil,dis))
        B.Border("primary",dis)
        B.Opacity("primary",dis)
        B.Row(O.Toggle("primary","customColored","Custom Fill Color","Off uses the power type color.",dis),
            O.Color("primary","fill","Fill Color",false,function() return dis() or not O.Get("primary","customColored") end))
        B.Row(O.Color("primary","bg","Background Color",true,dis),O.spacer)
        B.Gradient("primary",dis)
        B.Row(O.Dropdown("primary","textFormat","Power Text",{none="None",smart="Smart Text",curpp="Power Value",perpp="Power %",both="Power Value | Power %"},
            {"none","smart","curpp","perpp","both"},"perpp",nil,dis),O.Slider("primary","textSize","Text Size",8,24,1,10,nil,dis))
        B.Row(O.Toggle("primary","showPercent","Show %",nil,dis),O.Dropdown("primary","textAnchor","Text Anchor",O.anchors,O.anchorOrder,"CENTER",nil,dis))
        B.Row(O.Toggle("primary","textCustomColored","Custom Text Color","Off colors the text with the power color.",dis),O.Color("primary","textFill","Text Color",true,dis))
        B.Row(O.Slider("primary","textXOffset","Text X Offset",-100,100,1,0,nil,dis),O.Slider("primary","textYOffset","Text Y Offset",-100,100,1,0,nil,dis))
        B.Thresholds("primary",dis,true,false)
        B.Row(O.Toggle("primary","manaRegenSpark","Mana Regen Spark","Five second rule and mana tick spark on a mana bar.",dis),
            O.Dropdown("primary","manaRegenSparkMode","Spark Mode",{fsr="Five Second Rule",ticks="Mana Ticks"},{"fsr","ticks"},"fsr",nil,
                function() return dis() or not O.Get("primary","manaRegenSpark") end))
        B.Row(O.Toggle("primary","powerCostPrediction","Spell Cost Prediction","Shows the cost of the spell being cast on the power bar.",dis),
            {type="colorpicker",text="Cost Color",disabled=function() return dis() or not O.Get("primary","powerCostPrediction") end,
                getValue=function() return O.Get("primary","powerCostR",.4),O.Get("primary","powerCostG",.7),O.Get("primary","powerCostB",1),1 end,
                setValue=function(r,g,b) local c=O.Cfg("primary"); if c then c.powerCostR,c.powerCostG,c.powerCostB=r,g,b; ns.Apply() end end})
        B.Visibility("primary")
        B.DruidForms("primary",dis)
        if CLASS=="DRUID" then
            local dd=function() return dis() or not O.Get("druidMana","enabled") end
            B.Section("MANA BAR WHILE SHAPESHIFTED")
            B.Row(O.Toggle("druidMana","enabled","Show Mana Bar while Shapeshifted",nil,dis),
                O.Dropdown("druidMana","position","Position",{below="Below",above="Above",inside="Inside"},{"below","above","inside"},"below",nil,dd))
            B.Row(O.Slider("druidMana","gap","Gap",0,20,1,2,nil,dd),O.Slider("druidMana","height","Height",2,30,1,6,nil,dd))
            B.Row(O.Slider("druidMana","offsetX","X Offset",-100,100,1,0,nil,dd),O.Slider("druidMana","offsetY","Y Offset",-100,100,1,0,nil,dd))
            B.Row(O.Dropdown("druidMana","textFormat","Mana Text",{none="None",curpp="Mana Value",perpp="Mana %",both="Mana Value | Mana %"},
                {"none","curpp","perpp","both"},"none",nil,dd),O.Slider("druidMana","textSize","Text Size",6,24,1,8,nil,dd))
        end
    end
    function O.Resource(B)
        local dis=O.Off("secondary")
        B.Section("CLASS RESOURCE BAR")
        B.Row(O.Toggle("secondary","enabled","Show Class Resource"),O.Dropdown("secondary","pipOrientation","Orientation",O.orient,O.orientOrder,"HORIZONTAL",nil,dis))
        B.Row(O.Slider("secondary","pipHeight","Bar Height",3,60,1,20,nil,dis),O.Slider("secondary","pipWidth","Bar Width",30,800,1,214,nil,dis))
        B.Row(O.Slider("secondary","pipSpacing","Spacing",0,20,1,1,nil,dis),O.Toggle("secondary","raiseLevel","Raise Frame Level",nil,dis))
        B.Border("secondary",dis)
        B.Row(O.Percent("secondary","barAlpha","Opacity",1,nil,dis),O.Slider("secondary","fillOpacity","Fill Color",0,100,1,100,nil,dis))
        B.Row(O.Toggle("secondary","oocFadeEnabled","Fade Out of Combat",nil,dis),
            O.Percent("secondary","oocAlpha","Out of Combat Opacity",.5,nil,function() return dis() or not O.Get("secondary","oocFadeEnabled") end))
        local custom=function() return dis() or O.Get("secondary","classColored") or O.Get("secondary","resourceColored") end
        B.Row(O.Toggle("secondary","classColored","Class Colored",nil,dis),O.Toggle("secondary","resourceColored","Resource Colored","Uses the EllesmereUI resource color for your class.",dis))
        B.Row(O.Color("secondary","fill","Fill Color",false,custom),O.Toggle("secondary","darkTheme","Dark Mode Class Resource",nil,dis))
        B.Row(O.Color("secondary","bg","Pip Background",true,dis),O.Color("secondary","barBg","Bar Background",true,dis))
        B.Row(O.Toggle("secondary","gapColorEnabled","Color Gaps",nil,dis),O.Color("secondary","gap","Gap Color",true,function() return dis() or not O.Get("secondary","gapColorEnabled") end))
        B.Row(O.Toggle("secondary","pipBgOnPips","Background Only on Pips",nil,dis),O.spacer)
        B.Row(O.Toggle("secondary","showText","Resource Text","Combo point count; DK rune recharge seconds.",dis),O.Slider("secondary","textSize","Text Size",8,24,1,11,nil,dis))
        B.Row(O.Color("secondary","text","Text Color",false,dis),O.Dropdown("secondary","textAnchor","Text Anchor",O.anchors,O.anchorOrder,"CENTER",nil,dis))
        B.Row(O.Slider("secondary","textXOffset","Text X Offset",-100,100,1,0,nil,dis),O.Slider("secondary","textYOffset","Text Y Offset",-100,100,1,0,nil,dis))
        B.Thresholds("secondary",dis,false,true)
        if CLASS=="DEATHKNIGHT" then
            B.Row(O.Toggle("secondary","runesSimple","Simple Runes","Ready runes only, with a central ready count.",dis),
                O.Toggle("secondary","runeSortReady","Sort Ready Runes First",nil,dis))
            B.Row(O.Toggle("secondary","runesCustomRecharge","Custom Recharge Color",nil,dis),
                O.Color("secondary","runesRecharge","Recharge Color",true,function() return dis() or not O.Get("secondary","runesCustomRecharge") end))
        end
        B.Row(O.Toggle("secondary","blizzardClassArt","Blizzard Class Resource Art","Shows the stock rune or combo point frame here instead of the pips.",dis),
            {type="slider",text="Art Scale",min=50,max=200,step=5,disabled=function() return dis() or not O.Get("secondary","blizzardClassArt") end,
                getValue=function() return math.floor(O.Get("secondary","blizzardClassArtScale",1)*100+.5) end,
                setValue=function(v) O.Set("secondary","blizzardClassArtScale",v/100) end})
        B.Visibility("secondary")
        B.DruidForms("secondary",dis)
    end

    --------------------------------------------------------------------------
    -- Page: Cast Bar
    --------------------------------------------------------------------------
    function O.Cast(B)
        local bar="castBar"; local dis=O.Off(bar)
        B.Section("BAR DISPLAY")
        B.Row(O.Toggle(bar,"enabled","Enable Player Cast Bar","Replaces the stock player cast bar."),O.Toggle(bar,"alwaysShow","Always Show",nil,dis))
        B.Row(O.Slider(bar,"height","Bar Height",6,60,1,20,nil,dis),O.Slider(bar,"width","Bar Width",50,800,1,220,nil,dis))
        B.Row(O.Toggle(bar,"showIcon","Show Spell Icon",nil,dis),O.Toggle(bar,"iconOnRight","Icon on Right",nil,function() return dis() or not O.Get(bar,"showIcon") end))
        B.Row(O.Toggle(bar,"showIconDivider","Icon Divider",nil,dis),O.Dropdown(bar,"frameStrata","Frame Strata",O.strata,O.strataOrder,"MEDIUM",nil,dis))
        B.Row(O.Toggle(bar,"useClassicStyle","Classic Style","Classic WoW UI cast bar frame.",dis),O.Toggle(bar,"showSpark","Show Spark",nil,dis))
        B.Section("COLORS")
        B.Row(O.Dropdown(bar,"texture","Bar Texture",_ERB_CastBarTextureNames,_ERB_CastBarTextureOrder,"none",nil,dis),O.Toggle(bar,"classColored","Class Colored",nil,dis))
        B.Row(O.Color(bar,"fill","Fill Color",true,function() return dis() or O.Get(bar,"classColored") end),O.Color(bar,"bg","Background Color",true,dis))
        B.Row(O.Slider(bar,"fillOpacity","Fill Opacity",0,100,1,100,nil,dis),O.spacer)
        B.Gradient(bar,dis)
        B.Row(O.Toggle(bar,"uninterruptibleColored","Uninterruptible Color",nil,dis),
            O.Color(bar,"uninterruptible","Uninterruptible",false,function() return dis() or not O.Get(bar,"uninterruptibleColored") end))
        B.Row(O.Color(bar,"failed","Interrupted / Failed",false,dis),O.spacer)
        B.Section("TEXT")
        B.Row(O.Toggle(bar,"showSpellText","Spell Name",nil,dis),O.Slider(bar,"spellTextSize","Spell Text Size",8,24,1,11,nil,dis))
        B.Row(O.Dropdown(bar,"spellTextSide","Spell Text Position",O.sides,O.sideOrder,"left",nil,dis),O.Color(bar,"spellText","Spell Text Color",true,dis))
        B.Row(O.Slider(bar,"spellTextX","Spell Text X",-100,100,1,0,nil,dis),O.Slider(bar,"spellTextY","Spell Text Y",-50,50,1,0,nil,dis))
        B.Row(O.Toggle(bar,"showTimer","Timer",nil,dis),O.Slider(bar,"timerSize","Timer Size",8,24,1,11,nil,dis))
        B.Row(O.Dropdown(bar,"timerSide","Timer Position",O.sides,O.sideOrder,"right",nil,dis),O.Color(bar,"timer","Timer Color",true,dis))
        B.Row(O.Slider(bar,"timerX","Timer X",-100,100,1,0,nil,dis),O.Slider(bar,"timerY","Timer Y",-50,50,1,0,nil,dis))
        B.Row(O.Toggle(bar,"showTotalDuration","Show Total Duration",nil,dis),O.spacer)
        B.Section("CHANNEL TICKS AND LATENCY")
        local td=function() return dis() or not O.Get(bar,"showChannelTicks") end
        B.Row(O.Toggle(bar,"showChannelTicks","Channel Ticks","Wrath channel pulse positions.",dis),O.Color(bar,"tickMarks","Tick Color",true,td))
        B.Row(O.Toggle(bar,"showLastTick","Highlight Last Tick",nil,td),O.Color(bar,"lastTick","Last Tick Color",true,function() return td() or not O.Get(bar,"showLastTick") end))
        local ld=function() return dis() or not O.Get(bar,"latencyEnabled") end
        B.Row(O.Toggle(bar,"latencyEnabled","Latency (Spell Queue) Overlay","Shows the network latency zone at the end of casts or channels, including queued spells.",dis),O.Color(bar,"latency","Latency Color",true,ld))
        B.Row(O.Toggle(bar,"latencyShowText","Latency Text",nil,ld),O.spacer)
        B.Section("BORDER")
        B.Border(bar,dis)
    end

    --------------------------------------------------------------------------
    -- Page: GCD Bar
    --------------------------------------------------------------------------
    function O.GCD(B)
        local bar="gcdBar"; local dis=O.Off(bar)
        B.Section("BAR DISPLAY")
        B.Row(O.Toggle(bar,"enabled","Enable GCD Bar"),O.Toggle(bar,"alwaysShow","Always Show",nil,dis))
        B.Row(O.Slider(bar,"height","Bar Height",2,60,1,12,nil,dis),O.Slider(bar,"width","Bar Width",20,800,1,220,nil,dis))
        B.Row(O.Dropdown(bar,"orientation","Orientation",{HORIZONTAL="Horizontal",VERTICAL="Vertical"},{"HORIZONTAL","VERTICAL"},"HORIZONTAL",nil,dis),
            O.Toggle(bar,"instanceOnly","Instance Only",nil,dis))
        B.Row(O.Toggle(bar,"instantOnly","Instant Casts Only","Hidden while a cast bar is running.",dis),O.Toggle(bar,"depleteFill","Deplete Fill",nil,dis))
        B.Row(O.Toggle(bar,"showSpark","Show Spark",nil,dis),O.Dropdown(bar,"frameStrata","Frame Strata",O.strata,O.strataOrder,"MEDIUM",nil,dis))
        B.Section("COLORS")
        B.Row(O.Dropdown(bar,"texture","Bar Texture",_ERB_CastBarTextureNames,_ERB_CastBarTextureOrder,"none",nil,dis),O.Toggle(bar,"classColored","Class Colored",nil,dis))
        B.Row(O.Color(bar,"fill","Fill Color",true,function() return dis() or O.Get(bar,"classColored") end),O.Color(bar,"bg","Background Color",true,dis))
        B.Gradient(bar,dis)
        B.Section("BORDER")
        B.Border(bar,dis)
    end

    --------------------------------------------------------------------------
    -- Page: Swing Timer
    --------------------------------------------------------------------------
    function O.Swing(B)
        local bar="swingTimer"; local dis=O.Off(bar)
        B.Section("BAR DISPLAY")
        B.Row(O.Toggle(bar,"enabled","Enable Swing Timer"),O.Toggle(bar,"hideWhenIdle","Hide When Idle",nil,dis))
        B.Row(O.Slider(bar,"height","Row Height",4,40,1,12,nil,dis),O.Slider(bar,"width","Bar Width",50,800,1,220,nil,dis))
        B.Row(O.Slider(bar,"rowSpacing","Row Spacing",0,20,1,2,nil,dis),O.Dropdown(bar,"frameStrata","Frame Strata",O.strata,O.strataOrder,"MEDIUM",nil,dis))
        B.Row(O.Toggle(bar,"depleteFill","Deplete Fill",nil,dis),O.Toggle(bar,"idleShowFill","Full Bar When Idle",nil,dis))
        B.Row(O.Toggle(bar,"showSpark","Show Spark",nil,dis),O.spacer)
        B.Section("ROWS")
        B.Row(O.Toggle(bar,"showMH","Main Hand",nil,dis),O.Toggle(bar,"showOH","Off Hand",nil,function() return dis() or O.Get(bar,"combineHands") end))
        B.Row(O.Toggle(bar,"showR","Ranged",nil,dis),O.Toggle(bar,"combineHands","Combine Hands","One melee row showing the next swing of either hand.",dis))
        B.Section("TEXT")
        B.Row(O.Toggle(bar,"showTime","Show Time",nil,dis),O.Toggle(bar,"showLabel","Show Labels",nil,dis))
        B.Row(O.Slider(bar,"textSize","Text Size",8,24,1,11,nil,dis),O.spacer)
        B.Section("COLORS")
        B.Row(O.Dropdown(bar,"texture","Bar Texture",_ERB_CastBarTextureNames,_ERB_CastBarTextureOrder,"none",nil,dis),O.Toggle(bar,"classColored","Class Colored",nil,dis))
        local cc=function() return dis() or O.Get(bar,"classColored") end
        B.Row(O.Color(bar,"mh","Main Hand Color",true,cc),O.Color(bar,"oh","Off Hand Color",true,cc))
        B.Row(O.Color(bar,"r","Ranged Color",true,cc),O.Color(bar,"bg","Background Color",true,dis))
        local qd=function() return dis() or not O.Get(bar,"queueHighlight") end
        B.Row(O.Toggle(bar,"queueHighlight","Next Swing Highlight","Heroic Strike, Cleave, Maul or Raptor Strike queued.",dis),O.Color(bar,"queue","Queued Color",true,qd))
        B.Row(O.Color(bar,"queueCleave","Cleave Queued Color",true,qd),O.spacer)
        B.Row(O.Toggle(bar,"rangeCheck","Out of Range Fade",nil,dis),O.Percent(bar,"outOfRangeAlpha","Out of Range Opacity",.4,nil,
            function() return dis() or not O.Get(bar,"rangeCheck") end))
        B.Section("VISIBILITY")
        B.Visibility(bar)
        B.Row(O.Percent(bar,"barAlpha","Opacity",1,nil,dis),O.Toggle(bar,"oocFadeEnabled","Fade Out of Combat",nil,dis))
        B.Section("BORDER")
        B.Border(bar,dis)
    end

    --------------------------------------------------------------------------
    -- Page: Totem Bar
    --------------------------------------------------------------------------
    function O.Totem(B)
        local bar="totemBar"
        local function ClassToggle(token,label)
            return {type="toggle",text=label,
                getValue=function() local c=O.Cfg(bar); return c and c.enabledClasses and c.enabledClasses[token] and true or false end,
                setValue=function(v) local c=O.Cfg(bar); if not c then return end; c.enabledClasses=c.enabledClasses or {}; c.enabledClasses[token]=v or nil; ns.Apply() end}
        end
        local dis=function() local c=O.Cfg(bar); return not (c and c.enabledClasses and c.enabledClasses[CLASS]) end
        B.Section("TOTEM BAR")
        B.Row(ClassToggle("SHAMAN","Show Totem Bar (Shaman)"),ClassToggle("DEATHKNIGHT","Show Totem Bar (Death Knight)"))
        B.Row(O.Slider(bar,"iconSize","Icon Size",16,64,1,30,nil,dis),O.Slider(bar,"spacing","Spacing",0,20,1,2,nil,dis))
        B.Row(O.Dropdown(bar,"orientation","Orientation",{HORIZONTAL="Horizontal",VERTICAL="Vertical"},{"HORIZONTAL","VERTICAL"},"HORIZONTAL",nil,dis),
            {type="dropdown",text="Grow Direction",disabled=dis,
                values={LEFT="Left",RIGHT="Right",UP="Up",DOWN="Down",CENTER="Center"},order={"RIGHT","LEFT","DOWN","UP","CENTER"},
                getValue=function() return (E.GetTotemGrowDir and E.GetTotemGrowDir()) or "RIGHT" end,setValue=function(v) O.Set(bar,"growDirection",v) end})
        B.Row(O.Toggle(bar,"showTimer","Show Timer",nil,dis),O.Slider(bar,"timerSize","Timer Size",8,24,1,11,nil,dis))
        B.Row(O.Toggle(bar,"hideBlizzard","Hide Blizzard Totem Frame",nil,dis),O.Dropdown(bar,"frameStrata","Frame Strata",O.strata,O.strataOrder,"MEDIUM",nil,dis))
        B.Border(bar,dis)
        if CLASS=="SHAMAN" then
            local cd=O.Off("callTotemBar")
            B.Section("CALL TOTEM BAR")
            B.Row(O.Toggle("callTotemBar","enabled","Enable Call Totem Bar","Moves the stock multi-cast totem bar so Unlock Mode can place it."),
                O.Slider("callTotemBar","iconSize","Icon Size",16,60,1,30,"Scales the stock bar; 30 is its normal size.",cd))
        end
    end

    O.pages={"Class, Power and Health Bars","Cast Bar","GCD Bar","Swing Timer","Totem Bar"}
    E:RegisterModule("EllesmereUIResourceBars",{title="Resource Bars",description="Wrath health, power, class resources, cast, GCD, swing and totem bars.",
        pages=O.pages,
        searchTerms="resource mana rage energy runic power combo points runes cast channel ticks latency cooldown gcd swing timer shaman totems druid",
        buildPage=function(page,parent,y)
            local B=O.Context(E.Widgets,parent,y)
            if page=="Cast Bar" then O.Cast(B)
            elseif page=="GCD Bar" then O.GCD(B)
            elseif page=="Swing Timer" then O.Swing(B)
            elseif page=="Totem Bar" then O.Totem(B)
            else O.General(B); O.Health(B); O.Power(B); O.Resource(B) end
            B.Section("POSITION")
            B.Button("Unlock Mode",function() if E.ToggleUnlockMode then E:ToggleUnlockMode() end end)
            B.Button("Reset Bar Positions",ns.ResetPositions)
            return math.abs(B.y)
        end,
        onReset=function() if ns.addon.db then ns.addon.db:ResetProfile() end; ns.Apply(); E:InvalidatePageCache() end,
    })
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
