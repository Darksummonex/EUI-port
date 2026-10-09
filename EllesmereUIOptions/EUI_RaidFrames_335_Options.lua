local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
local E=EllesmereUI
local ns=E and E._ModuleNS and E._ModuleNS.EllesmereUIRaidFrames
if not ns or not ns.IsWrath then return end
local init=CreateFrame("Frame"); init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent",function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local function Field(kind,key,label,type,min,max,step)
        return {type=type,text=label,min=min,max=max,step=step or 1,
            getValue=function() local p=ns.GetOptionSettings(kind); return p and p[key] end,
            setValue=function(v) local p=ns.GetOptionSettings(kind); if p then p[key]=v; ns.Apply() end end}
    end
    local function Toggle(kind,key,label) return Field(kind,key,label,"toggle") end
    local function Slider(kind,key,label,min,max,step) return Field(kind,key,label,"slider",min,max,step) end
    local function DD(kind,key,label,values,order) local c=Field(kind,key,label,"dropdown"); c.values,c.order=values,order; return c end
    local function Color(kind,key,label,disabled)
        return {type="colorpicker",text=label,hasAlpha=false,disabled=disabled,
            getValue=function() local p=ns.GetOptionSettings(kind); local c=p and p[key] or {r=1,g=1,b=1}; return c.r,c.g,c.b,1 end,
            setValue=function(r,g,b) local p=ns.GetOptionSettings(kind); if p then p[key]={r=r,g=g,b=b}; ns.Apply() end end}
    end
    -- Profile-level Extras tables (tankFrames, petFrames, friendlyBoss, healerMana).
    local function XField(sub,key,label,type,min,max,step)
        return {type=type,text=label,min=min,max=max,step=step or 1,
            getValue=function() return ns.GetSettings()[sub][key] end,
            setValue=function(v) ns.GetSettings()[sub][key]=v; ns.Apply() end}
    end
    local function XDD(sub,key,label,values,order) local c=XField(sub,key,label,"dropdown"); c.values,c.order=values,order; return c end
    local function Label(text) return {type="label",text=text} end
    local editor={mod="shift",button=1,action="spell",id=""}
    ns.RegisterElementPanels()
    local colorModes={class="Class",dark="Dark",classic="Classic (Health %)",custom="Custom",customDynamic="Custom Dynamic"}
    local colorOrder={"class","dark","classic","custom","customDynamic"}
    local textModes={class="Class",accent="Accent",custom="Custom"}
    local textOrder={"class","accent","custom"}
    local P,PO=ns.POSITION_VALUES,ns.POSITION_ORDER
    local previewModes={real="Real Preview",overlay="Overlay Preview",none="No Preview"}
    local previewOrder={"real","overlay","none"}
    -- Retail's centred "Preview Mode" row at the top of the Raid and Party pages.
    local function PreviewModeRow(parent,y)
        local pad=E.CONTENT_PAD or 45
        y=y-10
        local row=CreateFrame("Frame",nil,parent)
        row:SetWidth(math.max(1,(parent:GetWidth() or 0)-pad*2)); row:SetHeight(50); row:SetPoint("TOPLEFT",parent,"TOPLEFT",pad,y)
        local label=row:CreateFontString(nil,"OVERLAY")
        E.ApplyModuleFont(label,(E.GetFontPath and E.GetFontPath("raidFrames")) or "Fonts\\FRIZQT__.TTF",14,"raidFrames")
        label:SetPoint("TOP",row,"TOP",0,0); label:SetText(E.L and E.L("Preview Mode") or "Preview Mode"); label:SetTextColor(1,1,1,.6)
        local dd=E.BuildDropdownControl(row,180,row:GetFrameLevel()+2,previewModes,previewOrder,
            function() return ns.GetSettings().previewMode or "overlay" end,
            function(v) ns.GetSettings().previewMode=v; ns.SyncOptionsPreview(true) end)
        dd:SetPoint("TOP",label,"BOTTOM",0,-9)
        ns.previewModeControl=dd
        return y-50
    end
    -- Retail DISPELS section (Wrath has no Bleed type, so four swatches).
    local overlayValues={none="None",fill="Fill Overlay",full="Full Overlay",gradient="Gradient Overlay",gradient_sharp="Gradient Sharp"}
    local overlayOrder={"none","fill","full","gradient","gradient_sharp"}
    local iconValues,iconOrder={none="None"},{"none"}
    for _,key in ipairs(PO) do iconValues[key]=P[key]; iconOrder[#iconOrder+1]=key end
    local dispelTypes={{"Magic",.349,.475,1},{"Curse",.636,0,.64},{"Disease",.671,.384,.098},{"Poison",0,.706,.286}}
    local function DispelRows(kind,Row,Section)
        local function S(key) local p=ns.GetOptionSettings(kind); return p and p[key] end
        local function Set(key,v) local p=ns.GetOptionSettings(kind); if p then p[key]=v; ns.Apply() end end
        Section("DISPELS")
        Row({type="dropdown",text="Dispel Overlay",values=overlayValues,order=overlayOrder,
                getValue=function() return S("dispelOverlay") or "fill" end,
                setValue=function(v) Set("dispelOverlay",v); E:RefreshPage() end},
            {type="slider",text="Overlay Opacity",min=5,max=100,step=1,
                disabled=function() return (S("dispelOverlay") or "fill")=="none" end,disabledTooltip="Dispel Overlay",
                getValue=function() return S("dispelOverlayOpacity") or 100 end,
                setValue=function(v) Set("dispelOverlayOpacity",v) end})
        local row=Row({type="slider",text="Frame Border",min=0,max=4,step=1,
                tooltip="Draws a border in the dispel type color around the health bar.",
                getValue=function() return S("dispelBorderSize") or 0 end,
                setValue=function(v) Set("dispelBorderSize",v) end},
            {type="dropdown",text="Type Icon Position",values=iconValues,order=iconOrder,
                getValue=function() if not S("showDispelIcons") then return "none" end; return S("dispelIconPosition") or "center" end,
                setValue=function(v)
                    local p=ns.GetOptionSettings(kind); if not p then return end
                    p.showDispelIcons=v~="none"; if v~="none" then p.dispelIconPosition=v end
                    ns.Apply(); E:RefreshPage()
                end})
        if row and row._leftRegion and E.BuildInlineCog and not E._prebuilding then
            E.BuildInlineCog(row._leftRegion,{title="Dispel Border",rows={
                {type="slider",label="Debuff Icon Border",min=-1,max=4,step=1,
                    tooltip="Thickness in pixels. -1 follows each debuff indicator's Border setting, 0 hides the dispel color border.",
                    get=function() return S("dispelIconBorderSize") or -1 end,set=function(v) Set("dispelIconBorderSize",v) end},
                {type="toggle",label="Color Custom Borders",
                    tooltip="Recolors the frame border in the dispel type color while a debuff of that type is shown.",
                    disabled=function() return (tonumber(S("borderSize")) or 1)<=0 end,disabledTooltip="This option requires a Border Size above 0",
                    get=function() return S("dispelHighlight")~=false end,set=function(v) Set("dispelHighlight",v) end}}})
            E.BuildInlineCog(row._rightRegion,{icon=E.RESIZE_ICON,title="Dispel Icon",
                disabled=function() return not S("showDispelIcons") end,disabledTooltip="This option requires a Type Icon Position other than None",
                rows={
                {type="slider",label="Icon Size",min=8,max=48,step=1,get=function() return S("dispelIconSize") or 16 end,set=function(v) Set("dispelIconSize",v) end},
                {type="slider",label="Offset X",min=-50,max=50,step=1,get=function() return S("dispelIconOffsetX") or 0 end,set=function(v) Set("dispelIconOffsetX",v) end},
                {type="slider",label="Offset Y",min=-50,max=50,step=1,get=function() return S("dispelIconOffsetY") or 0 end,set=function(v) Set("dispelIconOffsetY",v) end}}})
        end
        local swatches={}
        for i,t in ipairs(dispelTypes) do
            local key="dispelColor"..t[1]
            swatches[i]={tooltip=t[1],hasAlpha=true,
                getValue=function() local c=S(key); if c then return c.r,c.g,c.b,c.a or 1 end; return t[2],t[3],t[4],1 end,
                setValue=function(r,g,b,a) Set(key,{r=r,g=g,b=b,a=a or 1}) end}
        end
        Row({type="multiSwatch",text="Dispel Colors",swatches=swatches},
            {type="toggle",text="Only Show Dispellable",
                tooltip="Only highlights debuffs your character can remove right now.",
                getValue=function() return S("dispelShowAll")==false end,
                setValue=function(v) Set("dispelShowAll",not v) end})
        Section("RAID DEBUFFS")
        local function Off() return S("raidDebuffs")==false end
        Row({type="toggle",text="Boss Debuff Icon",
                tooltip="Shows the most important boss debuff (ICC, Ruby Sanctum, ToC, Ulduar, Naxxramas) as a large icon in the middle of the frame.",
                getValue=function() return S("raidDebuffs")~=false end,setValue=function(v) Set("raidDebuffs",v); E:RefreshPage() end},
            {type="slider",text="Icon Size",min=10,max=48,step=1,disabled=Off,disabledTooltip="Boss Debuff Icon",
                getValue=function() return S("raidDebuffSize") or 22 end,setValue=function(v) Set("raidDebuffSize",v) end})
        Row({type="toggle",text="Show Dispellable When No Boss Debuff",disabled=Off,disabledTooltip="Boss Debuff Icon",
                tooltip="Falls back to the first debuff your character can remove.",
                getValue=function() return S("raidDebuffDispellable")~=false end,setValue=function(v) Set("raidDebuffDispellable",v) end},
            {type="slider",text="Icon Offset Y",min=-30,max=30,step=1,disabled=Off,disabledTooltip="Boss Debuff Icon",
                getValue=function() return S("raidDebuffOffsetY") or 0 end,setValue=function(v) Set("raidDebuffOffsetY",v) end})
    end
    E:RegisterModule("EllesmereUIRaidFrames",{title="Raid Frames",description="Wrath raid and party frames with native unit clicks, auras, range and click casting.",pages={"Raid","Party","Buffs","Debuffs","Extras","Aura Filters","Click Casting"},
        searchTerms="raid party group 10 25 40 players layout hide healer health mana power class name range threat aggro dispel buffs debuffs filter click casting healing ready leader marker preview mode overlay real horizontal frames heal prediction healcomm resurrection combat main tank pets boss valithria healer mana role icon border hover gradient sated dispels dispel overlay opacity frame border type icon dispel colors only show dispellable absorb absorbs shield shields overshield targeted spells targeted spell enemy cast casting incoming",
        buildPage=function(page,parent,y)
            if page=="Aura Filters" then return E.BuildWrathAuraFilters("EllesmereUIRaidFrames",parent,y) end
            local W=E.Widgets; local kind=page=="Party" and "party" or "raid"
            local function Row(a,b) local row,h=W:DualRow(parent,y,a,b or Label("")); y=y-h; return row end
            local function Section(text) local _,h=W:SectionHeader(parent,text,y); y=y-h end
            local function Button(text,fn) local _,h=W:WideButton(parent,text,y,fn); y=y-h end
            if page=="Buffs" or page=="Debuffs" then
                return E.BuildWrathAuraIndicators("EllesmereUIRaidFrames",page=="Buffs" and "buff" or "debuff",parent,y)
            end
            if page=="Click Casting" then
                Section("CLICK CASTING")
                Row({type="toggle",text="Enable Built-in Click Casting",getValue=function() return ns.GetSettings().clickCasting.enabled end,setValue=function(v) ns.GetSettings().clickCasting.enabled=v; ns.Apply() end},Label("Default: left target, right unit menu"))
                Row(Label("Clique can manage frames with built-in bindings off"),Label("Binding changes apply outside combat"))
                Section("EDIT BINDING")
                Row({type="dropdown",text="Modifier",values={none="None",shift="Shift",ctrl="Ctrl",alt="Alt",["ctrl-shift"]="Ctrl + Shift",["alt-shift"]="Alt + Shift",["alt-ctrl"]="Alt + Ctrl",["alt-ctrl-shift"]="Alt + Ctrl + Shift"},order={"none","shift","ctrl","alt","ctrl-shift","alt-shift","alt-ctrl","alt-ctrl-shift"},getValue=function() return editor.mod end,setValue=function(v) editor.mod=v end},
                    {type="dropdown",text="Mouse Button",values={[1]="Left",[2]="Right",[3]="Middle",[4]="Button 4",[5]="Button 5"},order={1,2,3,4,5},getValue=function() return editor.button end,setValue=function(v) editor.button=v end})
                Row({type="dropdown",text="Click Action",values={spell="Cast Spell",target="Target",menu="Unit Menu",focus="Focus",assist="Assist"},order={"spell","target","menu","focus","assist"},getValue=function() return editor.action end,setValue=function(v) editor.action=v end},
                    {type="input",text="Spell ID",placeholder="Example: 2061",getValue=function() return editor.id end,setValue=function(v) editor.id=v end})
                Button("Save Binding",function()
                    if not ns.SaveBinding(editor.mod,editor.button,editor.action,editor.id) then if E.PrintError then E.PrintError("Enter a valid spell ID for Cast Spell.") end; return end
                    E:InvalidatePageCache(); E:RefreshPage(true)
                end)
                Button("Remove Selected Binding",function() ns.ClearBinding(editor.mod,editor.button); E:InvalidatePageCache(); E:RefreshPage(true) end)
                Section("SAVED BINDINGS")
                local mods={"none","shift","ctrl","alt","ctrl-shift","alt-shift","alt-ctrl","alt-ctrl-shift"}
                for _,mod in ipairs(mods) do for button=1,5 do
                    local bind=ns.GetSettings().clickCasting.bindings[mod..":"..button]
                    if bind then Row(Label(mod.." + Button "..button),Label(bind.action=="spell" and ((GetSpellInfo(bind.spellID) or "Unknown").." ("..bind.spellID..")") or bind.action)) end
                end end
                return math.abs(y)
            end
            if page=="Extras" then
                local sizeTip="Added to the current raid or party frame size."
                Section("MAIN TANK FRAMES")
                Row(XField("tankFrames","enabled","Show Main Tank Frames","toggle"),XField("tankFrames","includeAssist","Include Main Assists","toggle"))
                Row(XField("tankFrames","horizontal","Horizontal Layout","toggle"),Label("Uses raid /maintank and /mainassist"))
                Row(XField("tankFrames","extraWidth","Extra Width","slider",-60,100),XField("tankFrames","extraHeight","Extra Height","slider",-30,60))
                Section("PET FRAMES")
                Row(XField("petFrames","party","Show Party Pets","toggle"),XField("petFrames","raid","Show Raid Pets","toggle"))
                Row(XField("petFrames","horizontal","Horizontal Layout","toggle"),Label("Up to 20 raid pets"))
                Row(XField("petFrames","extraWidth","Extra Width","slider",-60,100),XField("petFrames","extraHeight","Extra Height","slider",-30,60))
                Section("FRIENDLY BOSS FRAMES")
                local boss=XDD("friendlyBoss","display","Show Friendly Bosses",{never="Never",healers="Healers Only",always="Always"},{"never","healers","always"})
                boss.tooltip="Healable encounter units (boss1-4), for example Valithria Dreamwalker."
                Row(boss,XField("friendlyBoss","horizontal","Horizontal Layout","toggle"))
                Row(XField("friendlyBoss","extraWidth","Extra Width","slider",-60,100),XField("friendlyBoss","extraHeight","Extra Height","slider",-30,60))
                Section("HEALER MANA")
                Row(XDD("healerMana","mode","Healer Mana Display",{none="None",party="Party",raid="Raid",both="Party and Raid"},{"none","party","raid","both"}),XField("healerMana","textSize","Text Size","slider",8,24))
                Row(XField("healerMana","spacing","Row Spacing","slider",0,12),XDD("healerMana","align","Alignment",{LEFT="Left",CENTER="Center",RIGHT="Right"},{"LEFT","CENTER","RIGHT"}))
                Row(XDD("healerMana","growth","Growth",{DOWN="Down",UP="Up"},{"DOWN","UP"}),XField("healerMana","showNames","Show Names (Raid)","toggle"))
                local unassigned=XField("healerMana","includeUnassigned","Include Unassigned Healer Classes","toggle")
                unassigned.tooltip="Outside the Dungeon Finder Wrath has no healer role; mana users of healing classes are listed."
                Row(XField("healerMana","classNames","Class Colored Names","toggle"),unassigned)
                Row(Label(sizeTip),Label("Move each element in Unlock Mode"))
                Button("Preview Frames",function() ns.SetPreview(true) end); Button("End Preview",function() ns.SetPreview(false) end)
                Button("Unlock Mode",function() if E.ToggleUnlockMode then E:ToggleUnlockMode() end end)
                return math.abs(y)
            end
            y=PreviewModeRow(parent,y)
            if kind=="raid" then
                Section("RAID LAYOUTS")
                Row(DD(nil,"raidLayoutMode","Use Raid Layout",{auto="Automatic",["10"]="10 Players",["25"]="25 Players",["40"]="40 Players"},{"auto","10","25","40"}),ns.RaidLayoutDropdown())
                Row(Label("Automatic uses instance capacity, then roster size"),Label("Each layout saves its settings and position"))
            end
            Section("VISIBILITY")
            Row(Toggle(nil,"enabled","Enable Raid Frames Module"),Toggle(kind,"enabled",kind=="raid" and "Show Raid Frames" or "Show Party Frames"))
            if kind=="party" then
                local solo=Toggle(kind,"showSolo","Show While Solo"); solo.tooltip="Requires Show Player. Party frames hide while in a raid."
                Row(Toggle(kind,"showPlayer","Show Player"),solo)
                Section("LAYOUT")
                local horizontal=Toggle(kind,"partyHorizontal","Horizontal Frames"); horizontal.tooltip="Places the five party frames side by side instead of stacked."
                Row(horizontal,DD(kind,"sortMethod","Member Sorting",{ROLE="Tank > Healer > DPS",INDEX="Roster Order",NAME="Name"},{"ROLE","INDEX","NAME"}))
                local selfPos=DD(kind,"selfPosition","Self Position",{sorted="Sorted",first="First",last="Last"},{"sorted","first","last"})
                selfPos.tooltip="Places your own frame first or last in the party. Uses the native name list, refreshed outside combat."
                Row(selfPos,Toggle(kind,"reverseUnits","Reverse Member Order"))
            else
                local size=tonumber(ns.selectedRaidLayout or ns.activeRaidLayout or "40")
                Row(Slider(kind,"maxGroups","Group Limit",1,size/5),DD(kind,"orientation","Group Layout",{horizontal="Groups Across",vertical="Groups Down"},{"horizontal","vertical"}))
                Section("VISIBLE GROUPS")
                local function Group(group)
                    return {type="toggle",text="Show Group "..group,tooltip="Saved for this raid layout. Hidden groups leave no empty space.",
                        getValue=function() local c=ns.GetOptionSettings("raid"); return group<=c.maxGroups and not c.hiddenGroups[group] end,
                        setValue=function(v) local c=ns.GetOptionSettings("raid"); c.hiddenGroups[group]=not v; if v then c.maxGroups=math.max(c.maxGroups,group) end; ns.Apply() end}
                end
                for group=1,size/5,2 do Row(Group(group),group+1<=size/5 and Group(group+1) or Label("")) end
            end
            Section("FRAME SIZES")
            Row(Slider(kind,"frameWidth","Frame Width",60,300),Slider(kind,"frameHeight","Frame Height",30,120))
            Row(Slider(kind,"cellSpacing","Member Spacing",0,20),kind=="raid" and Slider(kind,"groupSpacing","Group Spacing",0,40) or Label("Five party slots including yourself"))
            if kind=="raid" then
                local selfPos=DD(kind,"selfPosition","Self Position",{sorted="Sorted",first="First",last="Last"},{"sorted","first","last"})
                selfPos.tooltip="Places your own frame first or last in its group. Uses the native name list, refreshed outside combat."
                Row(DD(kind,"sortMethod","Member Sorting",{ROLE="Tank > Healer > DPS",INDEX="Roster Order",NAME="Name"},{"ROLE","INDEX","NAME"}),selfPos)
                Row(Toggle(kind,"reverseGroups","Reverse Group Order"),Toggle(kind,"reverseUnits","Reverse Member Order"))
            end
            Row(DD(kind,"frameStrata","Frame Strata",{BACKGROUND="Background",LOW="Low",MEDIUM="Medium",HIGH="High"},{"BACKGROUND","LOW","MEDIUM","HIGH"}),Toggle(kind,"showPower","Show Power Bar"))
            Row(Slider(kind,"powerHeight","Power Height",2,12),Toggle(kind,"showPowerText","Show Power Percent"))
            Section("HEALTH BAR")
            local function ModeIs(mode) return function() local p=ns.GetOptionSettings(kind); return not p or p.healthColorMode~=mode end end
            local healthMode=DD(kind,"healthColorMode","Health Color",colorModes,colorOrder)
            local setMode=healthMode.setValue
            healthMode.setValue=function(v) local p=ns.GetOptionSettings(kind); if p then p.healthClassColored=(v=="class") end; setMode(v) end
            Row(healthMode,DD(kind,"healthBarTexture","Health Bar Texture",ns.healthBarTextureNames,ns.healthBarTextureOrder))
            Row(Color(kind,"customFillColor","Custom Fill Color",ModeIs("custom")),Toggle(kind,"healthVerticalFill","Vertical Fill"))
            Row(Color(kind,"dynamicColor100","Full Health Color",ModeIs("customDynamic")),Color(kind,"dynamicColor50","Half Health Color",ModeIs("customDynamic")))
            Row(Color(kind,"dynamicColor0","Low Health Color",ModeIs("customDynamic")),Label("Custom Dynamic blends these by health"))
            Row(Toggle(kind,"bgClassColored","Class Colored Background"),Slider(kind,"bgDarkness","Background Darkness",0,100,5))
            Row(Color(kind,"customBgColor","Background Color"),Label(""))
            Row(Color(kind,"statusColorOffline","Offline Background"),Color(kind,"statusColorDead","Dead Background"))
            Section("HEAL PREDICTION")
            local prediction=Toggle(kind,"healPrediction","Show Heal Prediction")
            prediction.tooltip="Incoming heals from LibHealComm-4.0 (bundled). Only heals from players running a HealComm addon are seen."
            Row(prediction,Slider(kind,"healPredOpacity","Prediction Opacity",10,100,5))
            Row(Color(kind,"healPredColor","Prediction Color"),Label("Next 4 seconds of incoming heals"))
            local AB=E.Absorbs
            if AB then
                Section("ABSORBS")
                local function NoAbsorb() local p=ns.GetOptionSettings(kind); return p and p.absorbStyle=="none" end
                local styleValues,styleOrder=AB.StyleMenu(ns.healthBarTextureNames,ns.healthBarTextureOrder)
                local style=DD(kind,"absorbStyle","Absorb Style",styleValues,styleOrder)
                style.tooltip="Damage shields on the health bar. 3.3.5 does not report shield amounts, so they are estimated from the combat log (base rank value plus your own spell power, minus what each shield absorbed)."
                local setStyle=style.setValue
                style.setValue=function(v) local p=ns.GetOptionSettings(kind); if p then p.absorbOpacity=(v=="clean") and 30 or 90 end; setStyle(v); E:RefreshPage() end
                local opacity=Slider(kind,"absorbOpacity","Absorb Opacity",5,100,5); opacity.disabled,opacity.disabledTooltip=NoAbsorb,"Absorb Style"
                Row(style,opacity)
                local placement=DD(kind,"absorbEdgeMode","Placement",AB.EDGE_NAMES,AB.EDGE_ORDER); placement.disabled,placement.disabledTooltip=NoAbsorb,"Absorb Style"
                local setPlacement=placement.setValue
                placement.setValue=function(v) setPlacement(v); E:RefreshPage() end
                Row(Color(kind,"absorbColor","Absorb Color",NoAbsorb),placement)
                local over=DD(kind,"overshieldMode","Show Overshield",AB.OVERSHIELD_NAMES,AB.OVERSHIELD_ORDER)
                over.tooltip="Overshield is the part of an absorb exceeding your empty health. Always backfills it over current health from the shield's edge; From Left grows it from the opposite end of the bar; Never hides it."
                over.disabledTooltip="Absorb Style and the Overlay placement"
                over.disabled=function() local p=ns.GetOptionSettings(kind); return not p or p.absorbStyle=="none" or (p.absorbEdgeMode or "overlay")~="overlay" end
                over.getValue=function() local p=ns.GetOptionSettings(kind); return p and (p.overshieldMode or (p.showOvershield==false and "never" or "always")) end
                over.setValue=function(v) local p=ns.GetOptionSettings(kind); if p then p.overshieldMode=v; p.showOvershield=(v~="never"); ns.Apply() end end
                Row(over,Label("Shields are estimated on 3.3.5"))
            end
            Section("BORDERS")
            Row(Slider(kind,"borderSize","Border Size",0,4),Color(kind,"borderColor","Border Color"))
            Row(Toggle(kind,"showThreat","Threat Border"),Color(kind,"threatBorderColor","Threat Color"))
            Row(Toggle(kind,"showTargetBorder","Target Border"),Color(kind,"targetBorderColor","Target Color"))
            Row(Toggle(kind,"hoverBorderEnabled","Hover Border"),Color(kind,"hoverBorderColor","Hover Color"))
            Row(Toggle(kind,"rangeFade","Dim Out of Range"),Slider(kind,"outOfRangeAlpha","Out of Range Alpha",.1,1,.05))
            Section("TEXT DISPLAY")
            Row(Slider(kind,"nameSize","Name Size",8,24),Slider(kind,"healthTextSize","Health Text Size",8,24))
            Row(DD(kind,"namePosition","Name Position",P,PO),DD(kind,"nameColorMode","Name Color",textModes,textOrder))
            Row(Color(kind,"nameCustomColor","Name Custom Color"),Slider(kind,"nameMaxLength","Name Max Length",0,20))
            Row(Slider(kind,"nameOffsetX","Name X Offset",-50,50),Slider(kind,"nameOffsetY","Name Y Offset",-50,50))
            Row(DD(kind,"healthDisplay","Health Text",{none="None",percent="Percent",current="Current",missing="Missing",both="Current / Maximum"},{"none","percent","current","missing","both"}),DD(kind,"healthTextPosition","Health Text Position",P,PO))
            Row(DD(kind,"healthTextColorMode","Health Text Color",textModes,textOrder),Color(kind,"healthTextCustomColor","Health Text Custom Color"))
            Row(Slider(kind,"healthTextOffsetX","Health Text X Offset",-50,50),Slider(kind,"healthTextOffsetY","Health Text Y Offset",-50,50))
            Row(Slider(kind,"powerTextSize","Power Text Size",8,18),Slider(kind,"statusTextSize","Status Text Size",8,24))
            Row(Toggle(kind,"statusShowAFK","Show AFK Status"),kind=="raid" and Slider(kind,"groupNumberSize","Group Number Size",8,20) or Label(""))
            Section("INDICATORS")
            Row(Toggle(kind,"showRole","Role Icons"),DD(kind,"roleIconStyle","Role Icon Style",ns.ROLE_STYLE_VALUES,ns.ROLE_STYLE_ORDER))
            Row(Slider(kind,"roleIconSize","Role Icon Size",8,32),DD(kind,"roleIconPosition","Role Icon Position",P,PO))
            Row(Toggle(kind,"showRoleForTank","Show Tank Icons"),Toggle(kind,"showRoleForHealer","Show Healer Icons"))
            Row(Toggle(kind,"hideDpsRoleIcons","Hide DPS Role Icons"),Toggle(kind,"roleIconHideInCombat","Hide Role Icons In Combat"))
            Row(Slider(kind,"roleIconOffsetX","Role Icon X Offset",-50,50),Slider(kind,"roleIconOffsetY","Role Icon Y Offset",-50,50))
            Row(Toggle(kind,"showLeader","Leader Icon"),Toggle(kind,"showLeaderIconInCombat","Leader Icon In Combat"))
            Row(Slider(kind,"leaderIconSize","Leader Icon Size",8,32),DD(kind,"leaderIconPosition","Leader Icon Position",P,PO))
            Row(Toggle(kind,"showRaidMarker","Raid Markers"),Slider(kind,"raidMarkerSize","Raid Marker Size",8,40))
            Row(DD(kind,"raidMarkerPosition","Raid Marker Position",P,PO),kind=="raid" and Toggle(kind,"showGroupNumber","Group Numbers") or Label(""))
            Row(Toggle(kind,"showReadyCheck","Ready Check Icons"),Slider(kind,"readyCheckSize","Ready Check Size",8,40))
            local rez=Toggle(kind,"showIncomingRez","Incoming Resurrection"); rez.tooltip="Shown on dead members being resurrected (LibResComm-1.0, bundled)."
            Row(DD(kind,"readyCheckPosition","Ready Check Position",P,PO),rez)
            Row(Toggle(kind,"showCombatIndicator","Combat Indicator"),Slider(kind,"combatIndicatorSize","Combat Icon Size",8,32))
            Row(DD(kind,"combatIndicatorPosition","Combat Icon Position",P,PO),Label("Members currently in combat"))
            DispelRows(kind,Row,Section)
            local TS=ns.TargetedSpells
            if TS then
                Section("TARGETED SPELLS")
                local function TsOff() local p=ns.GetOptionSettings(kind); return not p or (p.tsMode or "never")=="never" end
                local function Ts(control) control.disabled,control.disabledTooltip=TsOff,"Show Targeted Spells"; return control end
                local mode=DD(kind,"tsMode","Show Targeted Spells",TS.MODE_VALUES,TS.MODE_ORDER)
                mode.tooltip="Icons on the member an enemy is casting at. 3.3.5 has no spell target, so the victim is the caster's target, and only enemies targeted by someone in the group (or your target, focus or mouseover) are seen."
                local setMode=mode.setValue
                mode.setValue=function(v) setMode(v); E:RefreshPage() end
                local preview=Ts(Toggle(kind,"tsPreview","Show targeted spells on preview"))
                Row(mode,preview)
                Row(Ts(Slider(kind,"tsSize","Targeted Spell Size",10,40)),Ts(Slider(kind,"tsMax","Maximum Icons",1,5)))
                Row(Ts(DD(kind,"tsPosition","Icon Position",P,PO)),Ts(DD(kind,"tsGrowth","Growth Direction",TS.GROWTH_VALUES,TS.GROWTH_ORDER)))
                Row(Ts(Slider(kind,"tsOffsetX","Targeted Spells Offset X",-60,60)),Ts(Slider(kind,"tsOffsetY","Targeted Spells Offset Y",-60,60)))
                Row(Ts(Toggle(kind,"tsSwipe","Cast Swipe")),Ts(Toggle(kind,"tsTimer","Cast Timer")))
                local colorBy=Ts(Toggle(kind,"tsColorInterrupt","Color by Interruptible"))
                colorBy.tooltip="Border color shows whether the cast can be interrupted."
                Row(colorBy,Label("When Healing uses your role or healing talents"))
                local function NoColor() return TsOff() or ns.GetOptionSettings(kind).tsColorInterrupt==false end
                Row(Color(kind,"tsInterruptibleColor","Interruptible Color",NoColor),Color(kind,"tsUninterruptibleColor","Uninterruptible Color",NoColor))
            end
            Section("AURAS")
            Row(Toggle(kind,"showBuffs","Show Buffs"),Toggle(kind,"showDebuffs","Show Debuffs"))
            Row(Slider(kind,"maxBuffs","Maximum Buffs",0,8),Slider(kind,"maxDebuffs","Maximum Debuffs",0,8))
            Row(Slider(kind,"auraSize","Aura Icon Size",8,30),Toggle(kind,"showAuraTooltips","Aura Tooltips"))
            Row(Slider(kind,"auraDurationTextSize","Aura Duration Size",8,18),Slider(kind,"auraStackTextSize","Aura Stack Size",8,18))
            Row(Toggle(kind,"onlyDispellable","Only Dispellable Debuffs"),Label("Choose spell lists on Aura Filters"))
            Section("TOOLTIPS")
            Row(DD(kind,"tooltipMode","Unit Tooltip",{always="Always",outOfCombat="Out of Combat",never="Never"},{"always","outOfCombat","never"}),Label("Aura icon tooltips use Aura Tooltips"))
            Button("Unlock Mode",function() if E.ToggleUnlockMode then E:ToggleUnlockMode() end end)
            Button("Reset This Group Position",function() local key=kind=="raid" and "raid"..(ns.selectedRaidLayout or ns.activeRaidLayout or "40") or kind; ns.GetSettings().positions[key]=nil; ns.Apply() end)
            return math.abs(y)
        end,
        getHeaderBuilder=function(page)
            if page=="Buffs" or page=="Debuffs" then return E.WrathAuraIndicatorHeader("EllesmereUIRaidFrames",page=="Buffs" and "buff" or "debuff") end
        end,
        onPageCacheRestore=function(page)
            if page=="Buffs" or page=="Debuffs" then E.UpdateWrathAuraIndicatorPreview("EllesmereUIRaidFrames",page=="Buffs" and "buff" or "debuff") end
        end,
        onReset=function() ns.addon.db:ResetProfile(); ns.Apply(); E:InvalidatePageCache() end})
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
