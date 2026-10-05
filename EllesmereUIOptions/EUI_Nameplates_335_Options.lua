local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
local E=EllesmereUI
local ns=E and E._ModuleNS and E._ModuleNS.EllesmereUINameplates
if not ns or not ns.IsWrath then return end
local init=CreateFrame("Frame"); init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent",function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local function P() return ns.GetSettings() end
    local function Get(key) local p=P(); return p and p[key] end
    -- Preview header: clickable elements, Retail hint (29 px, dismissed on first click).
    local HINT_H=29
    local overlays,hint,headerBaseH={},nil,0
    local function HintShown() return not (EllesmereUIDB and EllesmereUIDB.previewHintDismissed) end
    local function SyncOverlays()
        for _,o in ipairs(overlays) do
            local on=o.el:IsShown() and (not o.text or (o.el:GetText() or "")~="")
            if on and o.text and o.btn._resizeToText then o.btn._resizeToText() end
            if on then o.btn:Show() else o.btn:Hide() end
        end
    end
    local function PaintHeader()
        if not ns.preview or not ns.PaintPreview then return 0 end
        headerBaseH=ns.PaintPreview(); SyncOverlays()
        local shown=hint and HintShown()
        if hint then if shown then hint:SetAlpha(.45); hint:Show() else hint:Hide() end end
        return headerBaseH+(shown and HINT_H or 0)
    end
    local function UpdatePreview()
        if not ns.preview or not ns.preview.plate:IsVisible() then return end
        local h=PaintHeader()
        if E.SetContentHeaderHeightSilent then E:SetContentHeaderHeightSilent(h) end
    end
    ns.onPreviewShown=PaintHeader
    local function Refresh() ns.Apply(); UpdatePreview() end
    local function Set(key,value)
        local p=P(); if not p then return end
        p[key]=value
        if key=="onlyPlayerDebuffs" then p.debuffFilterMode=value and "own" or "all" end
        if key=="hideEnemiesOutOfCombat" and not value then ns.SetNativeCVar("nameplateShowEnemies",true) end
        Refresh()
    end
    local function Toggle(key,label,tip,extra)
        local cfg={type="toggle",text=label,tooltip=tip,getValue=function() return Get(key) end,setValue=function(v) Set(key,v) end}
        for k,v in pairs(extra or {}) do cfg[k]=v end
        return cfg
    end
    local function Slider(key,label,low,high,step,extra)
        local cfg={type="slider",text=label,min=low,max=high,step=step or 1,getValue=function() return Get(key) end,setValue=function(v) Set(key,v) end}
        for k,v in pairs(extra or {}) do cfg[k]=v end
        return cfg
    end
    local function Dropdown(key,label,values,order,tip,extra)
        local cfg={type="dropdown",text=label,tooltip=tip,values=values,order=order,getValue=function() return Get(key) end,setValue=function(v) Set(key,v) end}
        for k,v in pairs(extra or {}) do cfg[k]=v end
        return cfg
    end
    local function Color(key,label,tip)
        return {type="colorpicker",text=label,tooltip=tip,
            getValue=function() local c=Get(key) or {r=1,g=1,b=1}; return c.r,c.g,c.b,1 end,
            setValue=function(r,g,b) local p=P(); if p then p[key]={r=r,g=g,b=b}; Refresh() end end}
    end
    -- Opacity stored 0..1, shown as the Retail 0..100 slider.
    local function Alpha(key,label)
        return {type="slider",text=label,min=0,max=100,step=1,
            getValue=function() return math.floor((Get(key) or 1)*100+.5) end,
            setValue=function(v) Set(key,v/100) end}
    end
    local function CVar(key,label,tip,inverted)
        return {type="toggle",text=label,tooltip=tip,
            getValue=function() local on=GetCVar(key)=="1"; if inverted then return not on end; return on end,
            setValue=function(v) if inverted then v=not v end; ns.SetNativeCVar(key,v) end}
    end
    local SPACER={type="spacer"}

    -- Inline widgets (Retail idiom): chained right-to-left left of the row control.
    local function Inline(rgn) return rgn and not E._prebuilding and rgn end
    local function Chain(rgn,widget,gap)
        widget:ClearAllPoints()
        local anchor=rgn._lastInline or rgn._control
        if anchor then widget:SetPoint("RIGHT",anchor,"LEFT",-(gap or 12),0)
        else widget:SetPoint("RIGHT",rgn,"RIGHT",-20,0) end
        rgn._lastInline=widget
    end
    local function Swatch(rgn,key,off,tip)
        if not Inline(rgn) or not E.BuildColorSwatch then return end
        local get=function() local c=Get(key) or {r=1,g=1,b=1}; return c.r,c.g,c.b end
        local set=function(r,g,b) local p=P(); if p then p[key]={r=r,g=g,b=b}; Refresh() end end
        local sw,update=E.BuildColorSwatch(rgn,rgn:GetFrameLevel()+5,get,set,nil,20)
        Chain(rgn,sw)
        if tip then
            sw:HookScript("OnEnter",function(btn) E.ShowWidgetTooltip(btn,tip) end)
            sw:HookScript("OnLeave",function() E.HideWidgetTooltip() end)
        end
        local function State()
            local disabled=off and off()
            sw:SetAlpha(disabled and .15 or 1); sw:EnableMouse(not disabled); update()
        end
        State(); E.RegisterWidgetRefresh(State)
        return sw
    end
    local function CogSlider(key,label,low,high,step)
        return {type="slider",label=label,min=low,max=high,step=step or 1,get=function() return Get(key) end,set=function(v) Set(key,v) end}
    end
    local function CogToggle(key,label)
        return {type="toggle",label=label,get=function() return Get(key) end,set=function(v) Set(key,v) end}
    end
    local function CogDropdown(key,label,values,order)
        return {type="dropdown",label=label,values=values,order=order,get=function() return Get(key) end,set=function(v) Set(key,v) end}
    end
    local function Cog(rgn,title,rows,opts)
        if not Inline(rgn) or not E.BuildInlineCog then return end
        opts=opts or {}
        opts.title,opts.rows,opts.captureRegion=title,rows,rgn
        return E.BuildInlineCog(rgn,opts)
    end
    local function Resize(rgn,title,rows,opts)
        opts=opts or {}; opts.icon=E.RESIZE_ICON
        return Cog(rgn,title,rows,opts)
    end
    local function Subtitle(header,text)
        if not header or not header.GetRegions or E._prebuilding then return end
        for _,rgn in ipairs({header:GetRegions()}) do
            if rgn:IsObjectType("FontString") then
                local sub=header:CreateFontString(nil,"OVERLAY")
                sub:SetFont(rgn:GetFont()); sub:SetTextColor(1,1,1,.25)
                sub:SetText(E.L and E.L(text) or text); sub:SetPoint("LEFT",rgn,"RIGHT",6,0)
                return
            end
        end
    end

    -- Core positions: Retail picks one element per slot; the engine stores a slot per element.
    local CORE_KEYS={debuffs="debuffSlot",buffs="buffSlot",raidmarker="raidMarkerSlot",classification="classificationSlot"}
    local CORE_VALUES={debuffs="Debuffs",buffs="Buffs",raidmarker="Raid Marker",classification="Boss Icon",none="None"}
    local CORE_ORDER={"debuffs","buffs","raidmarker","classification","none"}
    local function ElementAt(slot)
        for element,key in pairs(CORE_KEYS) do if Get(key)==slot then return element end end
        return "none"
    end
    local function SetElementAt(slot,element)
        local p=P(); if not p then return end
        local old=ElementAt(slot)
        if old~="none" then p[CORE_KEYS[old]]="none" end
        if element~="none" then p[CORE_KEYS[element]]=slot end
        Refresh()
        if E.RefreshPage then E:RefreshPage() end
    end
    local CORE_ROWS={
        debuffs={title="Debuffs",rows={CogSlider("auraSize","Size",12,40),CogSlider("maxAuras","Max Debuffs",1,ns.MAX_DEBUFFS),
            CogSlider("auraSpacing","Spacing",0,8),CogSlider("debuffYOffset","Y Offset",-10,20)}},
        buffs={title="Buffs",rows={CogSlider("buffSize","Size",12,40),CogSlider("maxBuffs","Max Buffs",1,ns.MAX_BUFFS),
            CogSlider("auraSpacing","Spacing",0,8),CogSlider("sideAuraXOffset","X Offset",0,20)}},
        raidmarker={title="Raid Marker",rows={CogSlider("raidMarkerSize","Size",12,40)}},
        classification={title="Boss Icon",rows={CogSlider("classificationSize","Size",10,32)}},
    }
    local corePopups={}
    local function ShowCorePopup(slot,btn)
        local element=ElementAt(slot); local def=CORE_ROWS[element]
        if not def or not E.BuildCogPopup then return end
        if not corePopups[element] then corePopups[element]=select(2,E.BuildCogPopup({title=def.title,rows=def.rows})) end
        corePopups[element](btn)
    end
    local function CoreSlot(slot,label)
        return {type="dropdown",text=label,values=CORE_VALUES,order=CORE_ORDER,
            getValue=function() return ElementAt(slot) end,setValue=function(v) SetElementAt(slot,v) end}
    end
    local slotRegions,eyes={},{}
    local function PlaceEyes()
        for element,eye in pairs(eyes) do
            local rgn=slotRegions[Get(CORE_KEYS[element])]
            if rgn then
                eye:SetParent(rgn); eye:ClearAllPoints()
                eye:SetPoint("RIGHT",rgn._slotCog or rgn._control,"LEFT",-8,0)
                eye:SetFrameLevel(rgn:GetFrameLevel()+5); eye:Show()
            else eye:Hide() end
        end
    end
    local function Eye(parent,element)
        if E._prebuilding then return end
        local btn=CreateFrame("Button",nil,parent); btn:SetWidth(26); btn:SetHeight(26); btn:SetAlpha(.4)
        local tex=btn:CreateTexture(nil,"OVERLAY"); tex:SetAllPoints()
        local function Icon() tex:SetTexture(ns.previewHidden[element] and E.EYE_INVISIBLE_ICON or E.EYE_VISIBLE_ICON) end
        Icon()
        btn:SetScript("OnClick",function() ns.previewHidden[element]=not ns.previewHidden[element]; Icon(); UpdatePreview() end)
        btn:SetScript("OnEnter",function(b) b:SetAlpha(.7); E.ShowWidgetTooltip(b,"Show/Hide on Preview") end)
        btn:SetScript("OnLeave",function(b) b:SetAlpha(.4); E.HideWidgetTooltip() end)
        eyes[element]=btn
    end
    local function SlotCog(rgn,slot)
        if not Inline(rgn) then return end
        slotRegions[slot]=rgn
        rgn._slotCog=Resize(rgn,"Slot",nil,{show=function(btn) ShowCorePopup(slot,btn) end,
            disabled=function() return ElementAt(slot)=="none" end,
            disabledTooltip="Choose an element for this slot first.",rawTooltip=true})
    end

    -- Core text positions: one text element per slot.
    local TEXT_VALUES={name="Enemy Name",healthPercent="Health %",level="Level",none="None"}
    local TEXT_ORDER={"name","healthPercent","level","none"}
    local TEXT_SLOTS={"Top","Right","Left","Center"}
    local function TextSlot(slot,label)
        local key="textSlot"..slot
        return {type="dropdown",text=label,values=TEXT_VALUES,order=TEXT_ORDER,getValue=function() return Get(key) end,
            setValue=function(v)
                local p=P(); if not p then return end
                if v~="none" then for _,other in ipairs(TEXT_SLOTS) do if p["textSlot"..other]==v then p["textSlot"..other]="none" end end end
                p[key]=v; Refresh()
                if E.RefreshPage then E:RefreshPage() end
            end}
    end
    local TEXT_ROWS={
        name={title="Enemy Name",rows={CogSlider("nameSize","Size",8,24),CogSlider("nameYOffset","Top Offset",-10,20)}},
        healthPercent={title="Health %",rows={CogSlider("healthTextSize","Size",8,20)}},
        level={title="Level",rows={CogSlider("levelSize","Size",8,20)}},
    }
    local textPopups={}
    local function TextCog(rgn,slot)
        Resize(rgn,"Text",nil,{show=function(btn)
            local element=Get("textSlot"..slot); local def=TEXT_ROWS[element]
            if not def or not E.BuildCogPopup then return end
            if not textPopups[element] then textPopups[element]=select(2,E.BuildCogPopup({title=def.title,rows=def.rows})) end
            textPopups[element](btn)
        end,disabled=function() return not TEXT_ROWS[Get("textSlot"..slot)] end,
        disabledTooltip="Choose a text for this slot first.",rawTooltip=true})
    end

    local EFFECTS={glow="EUI Glow",border="Border Color",highlight="Highlight",none="None"}
    local EFFECT_ORDER={"glow","border","highlight","none"}
    local ARROWS={}
    for key,style in pairs(ns.TARGET_ARROW_STYLES) do ARROWS[key]=style.label end
    local function HeaderBuilder(headerParent)
        if not ns.CreatePreview then return 0 end
        local s=ns.CreatePreview(headerParent)
        if HintShown() and E.MakeFont then
            -- Parented to the plate so it travels through the content-header cache with it.
            if not hint then
                hint=E.MakeFont(s.plate,11,nil,1,1,1)
                hint:SetText(E.L and E.L("Click elements to scroll to and highlight their options") or "Click elements to scroll to and highlight their options")
            end
            hint:ClearAllPoints(); hint:SetPoint("BOTTOM",headerParent,"BOTTOM",0,17)
        end
        return PaintHeader()
    end

    -- Click-to-navigate: each preview element scrolls to and glows the row that configures it.
    local refs={}
    local PlayGlow
    local function Glow(target)
        PlayGlow=PlayGlow or (E.MakeSettingGlow and E.MakeSettingGlow({color=E.ELLESMERE_GREEN,thickness=2,noSnap=true}))
        if PlayGlow then PlayGlow(target) end
    end
    local function At(header,row,side) return function() return {section=refs[header],target=refs[row],side=side} end end
    local CORE_ROW={top={"core1","left"},right={"core1","right"},left={"core2","left"},topright={"core2","right"},
        topleft={"core3","left"},bottom={"core3","right"}}
    local TEXT_ROW={Top={"text1","left"},Right={"text1","right"},Left={"text2","left"},Center={"text2","right"}}
    local function CoreAt(element) return function()
        local info=CORE_ROW[Get(CORE_KEYS[element])] or {"core1"}
        return {section=refs.coreHeader,target=refs[info[1]],side=info[2]}
    end end
    local function TextAt(element) return function()
        local info={"text1"}
        for _,slot in ipairs(TEXT_SLOTS) do if Get("textSlot"..slot)==element then info=TEXT_ROW[slot] end end
        return {section=refs.textHeader,target=refs[info[1]],side=info[2]}
    end end
    local NAV={
        healthBar=At("barHeader","barSize"),castBar=At("barHeader","castSize","left"),
        castIcon=At("barHeader","castShow","right"),castName=At("barHeader","castText","left"),castTimer=At("barHeader","castText","right"),
        targetArrows=At("targetHeader","targetEffect","right"),classResource=At("classHeader","classPower","left"),
        auraStack=At("generalHeader","auraText","left"),auraDuration=At("generalHeader","auraText","right"),
        debuffIcon=CoreAt("debuffs"),buffIcon=CoreAt("buffs"),raidMarker=CoreAt("raidmarker"),classIcon=CoreAt("classification"),
        enemyName=TextAt("name"),healthText=TextAt("healthPercent"),levelText=TextAt("level"),
    }
    local function Navigate(key)
        local m=NAV[key] and NAV[key]()
        if not m or not m.section or not m.target then return end
        if hint and E.DismissPreviewHint then E.DismissPreviewHint(hint,headerBaseH,HINT_H,17) end
        local _,_,_,_,y=m.section:GetPoint(1)
        if y and E.SmoothScrollTo then E.SmoothScrollTo(math.max(0,math.abs(y)-40)) end
        local target=m.target
        if m.side then target=target[m.side=="left" and "_leftRegion" or "_rightRegion"] or target end
        C_Timer.After(.15,function() Glow(target) end)
    end
    ns.NavigatePreview=Navigate
    local HIT_STYLE={container=true}
    local function BuildOverlays()
        for _,o in ipairs(overlays) do
            for _,f in ipairs(o.frames) do f:EnableMouse(false); f:Hide(); f:SetParent(nil) end
        end
        wipe(overlays)
        local s=ns.preview
        if not s or not E.CreatePreviewHitOverlay then return end
        local function Hit(el,key,isText,level,opts)
            local btn,hlBase,hlCont=E.CreatePreviewHitOverlay(el,Navigate,key,isText,level,opts,HIT_STYLE)
            local frames={btn}
            if hlBase and hlBase~=btn then frames[#frames+1]=hlBase end
            if hlCont then frames[#frames+1]=hlCont end
            overlays[#overlays+1]={btn=btn,el=el,text=isText,frames=frames}
        end
        local function Auras(list,key,durationKey)
            for _,a in ipairs(list) do
                local textLevel=a:GetFrameLevel()+30
                Hit(a,key,false,nil,{hlBehindText=true})
                Hit(a.count,"auraStack",true,textLevel); Hit(a.time,durationKey,true,textLevel)
            end
        end
        Hit(s.health,"healthBar"); Hit(s.cast,"castBar"); Hit(s.castIcon,"castIcon")
        Hit(s.castText,"castName",true); Hit(s.castTimer,"castTimer",true)
        Hit(s.name,"enemyName",true); Hit(s.healthText,"healthText",true); Hit(s.level,"levelText",true)
        Hit(s.raid,"raidMarker"); Hit(s.class,"classIcon")
        Hit(s.arrowL,"targetArrows"); Hit(s.arrowR,"targetArrows")
        for _,pip in ipairs(s.pips) do Hit(pip,"classResource") end
        Auras(s.auras,"debuffIcon","auraDuration"); Auras(s.buffs,"buffIcon","auraDuration")
        SyncOverlays()
    end

    E:RegisterModule("EllesmereUINameplates",{
        title="Nameplates",description="Custom nameplate design and behavior.",
        pages={"Display","Colors","General","Aura Filters"},
        searchTerms="nameplate enemy friendly health cast aura debuff buff filter tracked excluded spell id threat tank target arrows glow hash execute combo opacity name font",
        buildPage=function(page,parent,y)
            local W=E.Widgets
            local function Row(left,right) local row,h=W:DualRow(parent,y,left,right); y=y-h; return row end
            local function Section(label) local header,h=W:SectionHeader(parent,label,y); y=y-h; return header end
            local preview=page=="Display" and E.SetContentHeader and not E._prebuilding
            if preview then E:SetContentHeader(HeaderBuilder) end
            parent._showRowDivider=true
            if page=="Display" then
                Section("STYLE")
                local row=Row(Dropdown("showBorder","Border",{basic="Basic",none="None"},{"basic","none"},nil,{
                        getValue=function() return Get("showBorder")==false and "none" or "basic" end,
                        setValue=function(v) Set("showBorder",v=="basic") end}),
                    Slider("borderSize","Border Size",1,4,1,{disabled=function() return Get("showBorder")==false end,disabledTooltip="Border"}))
                Swatch(row and row._leftRegion,"borderColor",function() return Get("showBorder")==false end)
                row=Row(Alpha("bgAlpha","Background"),Alpha("castBgAlpha","Cast Background"))
                Swatch(row and row._leftRegion,"bgColor"); Swatch(row and row._rightRegion,"castBgColor")
                Row(Dropdown("healthBarTexture","Bar Texture",ns.textureValues,ns.textureOrder),Dropdown("castBarTexture","Cast Bar Texture",ns.textureValues,ns.textureOrder))

                refs.coreHeader=Section("CORE POSITIONS"); Subtitle(refs.coreHeader,"(one per slot)")
                local r1=Row(CoreSlot("top","Top"),CoreSlot("right","Right"))
                local r2=Row(CoreSlot("left","Left"),CoreSlot("topright","Top Right"))
                local r3=Row(CoreSlot("topleft","Top Left"),CoreSlot("bottom","Bottom"))
                refs.core1,refs.core2,refs.core3=r1,r2,r3
                if r1 and r1._leftRegion and not E._prebuilding then
                    wipe(slotRegions); wipe(eyes)
                    SlotCog(r1._leftRegion,"top"); SlotCog(r1._rightRegion,"right")
                    SlotCog(r2._leftRegion,"left"); SlotCog(r2._rightRegion,"topright")
                    SlotCog(r3._leftRegion,"topleft"); SlotCog(r3._rightRegion,"bottom")
                    Eye(parent,"raidmarker"); Eye(parent,"classification")
                    PlaceEyes(); E.RegisterWidgetRefresh(PlaceEyes)
                end

                refs.textHeader=Section("CORE TEXT POSITIONS"); Subtitle(refs.textHeader,"(one per slot)")
                local t1=Row(TextSlot("Top","Top Text"),TextSlot("Right","Right Text"))
                local t2=Row(TextSlot("Left","Left Text"),TextSlot("Center","Center Text"))
                refs.text1,refs.text2=t1,t2
                TextCog(t1 and t1._leftRegion,"Top"); TextCog(t1 and t1._rightRegion,"Right")
                TextCog(t2 and t2._leftRegion,"Left"); TextCog(t2 and t2._rightRegion,"Center")

                refs.barHeader=Section("HEALTH AND CAST BAR")
                refs.barSize=Row(Slider("width","Health Bar Width",60,300),Slider("height","Health Bar Height",4,40))
                refs.castSize=Row(Slider("castHeight","Cast Bar Height",4,40),Slider("castBarOffsetY","Cast Bar Y Offset",-20,20))
                local castOff={disabled=function() return not Get("showCastBar") end,disabledTooltip="Show Cast Bar"}
                refs.castShow=Row(Toggle("showCastBar","Show Cast Bar"),Dropdown("castIconPosition","Spell Icon",{left="Left",right="Right",none="None"},{"left","right","none"},nil,castOff))
                row=Row(Toggle("showCastName","Spell Name","Spell names appear on identified target and mouseover plates.",castOff),Toggle("showCastTimer","Cast Timer",nil,castOff))
                refs.castText=row
                Resize(row and row._leftRegion,"Spell Name",{CogSlider("castNameSize","Size",8,20)})
                Resize(row and row._rightRegion,"Cast Timer",{CogSlider("castTimerSize","Size",8,20)})
                Row(Slider("yOffset","Vertical Offset",-30,40),SPACER)

                Section("CAST COLORS AND EFFECTS")
                row=Row(Color("castBarColor","Cast Color","Interruptible cast."),
                    Toggle("kickTickEnabled","Kick Ready Mid-Cast Hint","Marks where the cast will be when your interrupt is ready."))
                Swatch(row and row._leftRegion,"castBarUninterruptible",nil,"Uninterruptible")
                Swatch(row and row._leftRegion,"interruptReady",function() return not Get("castBarKickTint") end,"Interrupt on CD")
                Swatch(row and row._rightRegion,"kickTickColor",function() return not Get("kickTickEnabled") end)
                row=Row(Toggle("castBarKickTint","Color by Interrupt Cooldown","Uses the Interrupt on CD color while your interrupt is cooling down."),
                    Toggle("showInterruptedFlash","Show Interrupted Flash Effect"))
                Swatch(row and row._rightRegion,"interruptedColor",function() return not Get("showInterruptedFlash") end)
                Row(Toggle("castBarShieldEnabled","Uninterruptible Shield"),Toggle("castBarSparkEnabled","Cast Spark"))

                refs.targetHeader=Section("TARGET, FOCUS & HOVER EFFECTS")
                row=Row(Dropdown("targetEffect","Target Effect",EFFECTS,EFFECT_ORDER),
                    Toggle("showTargetArrows","Target Arrows"))
                refs.targetEffect=row
                Swatch(row and row._leftRegion,"targetBorderColor",function() return Get("targetEffect")~="border" end,"Border Color")
                Swatch(row and row._leftRegion,"targetGlowColor",function() return Get("targetEffect")~="glow" end,"Glow Color")
                Swatch(row and row._rightRegion,"targetArrowColor",function() return not Get("showTargetArrows") or Get("targetArrowClassColor") end)
                Cog(row and row._rightRegion,"Target Arrows",{CogDropdown("targetArrowStyle","Style",ARROWS,ns.TARGET_ARROW_ORDER),
                    CogSlider("targetArrowScale","Scale",.5,2,.05),CogToggle("targetArrowClassColor","Class Color")},
                    {disabled=function() return not Get("showTargetArrows") end,disabledTooltip="Target Arrows"})
                row=Row(Toggle("enableTargetColor","Enable Target Color"),Dropdown("targetTexture","Target Texture",ns.TARGET_TEXTURES,ns.TARGET_TEXTURE_ORDER))
                Swatch(row and row._leftRegion,"targetColor",function() return not Get("enableTargetColor") end)
                Row(Dropdown("hoverEffect","Hover Effect",{highlight="Highlight",none="None"},{"highlight","none"}),SPACER)

                refs.classHeader=Section("CLASS RESOURCE")
                row=Row(Toggle("showClassPower","Show Class Resource","Combo points on the target nameplate (Rogue and Druid)."),SPACER)
                refs.classPower=row
                Resize(row and row._leftRegion,"Class Resource",{CogSlider("classPowerScale","Size",1,3,.1)},
                    {disabled=function() return not Get("showClassPower") end,disabledTooltip="Show Class Resource"})

                refs.generalHeader=Section("GENERAL TEXT")
                refs.auraText=Row(Slider("auraStackTextSize","Aura Stacks",8,20),Slider("auraDurationTextSize","Debuff Duration",8,20))
                Row(Dropdown("auraTimerPosition","Duration Position",{topleft="Top Left",center="Center"},{"topleft","center"}),
                    Toggle("classColoredNames","Class Colored Names","Allied names keep their class color without target or mouseover. Group/raid members are identified automatically; other allies are learned from target, mouseover or focus."))
                Row(Toggle("showHealthText","Health Percentage"),Toggle("showLevel","Level & Elite Indicator"))
                if preview then BuildOverlays() end
            elseif page=="Colors" then
                Section("ENEMY COLORS")
                Row(Color("enemyInCombat","Enemy"),Color("neutral","Neutral & Mini Enemies"))
                local row=Row(Color("tapped","Tapped"),Toggle("colorBosses","Color Bosses"))
                Swatch(row and row._rightRegion,"boss",function() return not Get("colorBosses") end)
                row=Row(Toggle("colorElitesInInstances","Color Elites in Instances"),SPACER)
                Swatch(row and row._leftRegion,"miniboss",function() return not Get("colorElitesInInstances") end)

                Section("THREAT COLORS")
                Row(Dropdown("threatColorMode","Show Threat Colors",{never="Never",instances="In Instances",always="Always"},{"never","instances","always"}),
                    Dropdown("threatRole","Role",{auto="Auto (stance/form)",tank="Tank",dps="Non-Tank"},{"auto","tank","dps"},
                        "Auto treats Defensive Stance, Bear Form, Righteous Fury and Frost Presence as tanking."))
                row=Row({type="label",text="Tank Threat"},{type="label",text="Non-Tank Threat"})
                local threatOff=function() return Get("threatColorMode")=="never" end
                Swatch(row and row._leftRegion,"tankHasAggro",function() return threatOff() or not Get("classicTankAggro") end,"Has Aggro (Classic Tank Aggro)")
                Swatch(row and row._leftRegion,"tankLosingAggro",threatOff,"Losing Aggro")
                Swatch(row and row._leftRegion,"tankNoAggro",threatOff,"No Aggro")
                Swatch(row and row._rightRegion,"dpsHasAggro",threatOff,"Has Aggro")
                Swatch(row and row._rightRegion,"dpsNearAggro",threatOff,"Near Aggro")
                Row(Toggle("classicTankAggro","Classic Tank Aggro","Use the Has Aggro color while you tank instead of the normal reaction color."),
                    Toggle("threatColorHealth","Show Threat On Health Bar"))
                Row(Toggle("threatColorBorder","Show Threat On Border"),Toggle("threatColorName","Show Threat On Name"))

                Section("OTHER COLORS")
                Row(Color("friendlyBarColor","Friendly Player"),Color("friendlyNPCColor","Friendly NPC"))
                Row(Toggle("friendlyHealthClassColored","Class Colored Health Bar","Colors allied player bars using their class. Group/raid members are identified automatically; other allies are learned from target, mouseover or focus."),
                    CVar("ShowClassColorInNameplate","Enemy Player Class Colors","Native Wrath class colors for enemy players."))
            elseif page=="General" then
                Section("OTHER NAMEPLATES")
                Row(CVar("nameplateShowEnemies","Show Enemy Nameplates"),CVar("nameplateShowFriends","Show Friendly Nameplates"))
                local row=Row(CVar("nameplateShowEnemyPets","Show Enemy Pet Nameplates"),Toggle("friendlyNameOnly","Make Friendly Nameplates Name Only"))
                Resize(row and row._rightRegion,"Friendly Names",{CogSlider("friendlyNameSize","Friendly Name Size",8,24)},
                    {disabled=function() return not Get("friendlyNameOnly") end,disabledTooltip="Make Friendly Nameplates Name Only"})

                Section("NAMEPLATE SPACING")
                Row(CVar("nameplateAllowOverlap","Stacking Nameplates",nil,true),SPACER)

                Section("EXTRA AURA OPTIONS")
                Row(Toggle("showAuras","Show Auras","Uses live target/mouseover auras and the GUID aura cache for other identified plates."),
                    Toggle("onlyPlayerDebuffs","Only Your Debuffs","Includes debuffs cast by your pet."))
                Row(Toggle("showDebuffs","Show Debuffs"),Toggle("showBuffs","Show Enemy Buffs"))

                Section("TARGET AND FOCUS EFFECTS")
                local hashOff={disabled=function() return not Get("hashLineEnabled") end,disabledTooltip="Show Hash Line on Target"}
                row=Row(Toggle("hashLineEnabled","Show Hash Line on Target"),Slider("hashLinePercent","Hash Line Percent",1,99,1,hashOff))
                Swatch(row and row._leftRegion,"hashLineColor",hashOff.disabled)
                Row(Slider("targetScale","Scale Target Nameplate",1,1.5,.05),Slider("nonTargetAlpha","Non-Target Opacity",10,100))
                Row(Slider("opacity","Opacity",10,100),SPACER)

                Section("EXTRAS")
                Row(Toggle("executeGlow","Execute Pulse Glow","Execute, Hammer of Wrath and Kill Shot at 20%; Drain Soul at 25%."),
                    Toggle("hideEnemiesOutOfCombat","Hide Enemy Nameplates out of Combat"))
                Row(Toggle("hideEnemyNameWhileCasting","Hide Enemy Name While Casting"),SPACER)
            elseif page=="Aura Filters" then
                return E.BuildWrathAuraFilters("EllesmereUINameplates",parent,y)
            end
            return math.abs(y)
        end,
        getHeaderBuilder=function(page) if page=="Display" then return HeaderBuilder end end,
        onPageCacheRestore=function(page) if page=="Display" then UpdatePreview() end end,
        onReset=function() if ns.db and ns.db.ResetProfile then ns.db:ResetProfile() end; Refresh(); E:InvalidatePageCache() end,
    })
    SLASH_ELLESMERENAMEPLATES1="/enp"
    SlashCmdList.ELLESMERENAMEPLATES=function() if not InCombatLockdown() then E:ShowModule("EllesmereUINameplates") end end
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
