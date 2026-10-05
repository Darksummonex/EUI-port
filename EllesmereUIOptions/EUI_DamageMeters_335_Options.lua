local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
local E=EllesmereUI
local ns=E and E._ModuleNS and E._ModuleNS.EllesmereUIDamageMeters
if not ns or not ns.IsWrath then return end
local init=CreateFrame("Frame"); init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent",function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local function Refresh() E:InvalidatePageCache(); E:RefreshPage(true) end
    local function Selected()
        ns.selectedWindow=ns.Clamp(ns.selectedWindow or 1,1,#ns.Profile().windows)
        return ns.Profile().windows[ns.selectedWindow]
    end
    local function Label(text) return {type="label",text=text} end
    local function Field(store,key,label,kind,min,max,step)
        return {type=kind,text=label,min=min,max=max,step=step or 1,
            getValue=function() local t=store(); return t and t[key] end,
            setValue=function(value) local t=store(); if t then t[key]=value; ns.Apply() end end}
    end
    local function DD(store,key,label,values,order)
        local cfg=Field(store,key,label,"dropdown"); cfg.values,cfg.order=values,order; return cfg
    end
    local function ColorField(key,label,hasAlpha)
        return {type="colorpicker",text=label,hasAlpha=hasAlpha,
            getValue=function() local c=Selected()[key] or {}; return c.r or 1,c.g or 1,c.b or 1,c.a or 1 end,
            setValue=function(r,g,b,a) Selected()[key]={r=r,g=g,b=b,a=hasAlpha and (a or 1) or nil}; ns.Apply() end}
    end
    local function ModeSwatch(label,modeKey,colorKey,modes)
        local function Mode() return Selected()[modeKey] end
        local function Pick(mode) Selected()[modeKey]=mode; ns.Apply(); if E.RefreshPage then E:RefreshPage() end end
        local swatches={}
        for _,mode in ipairs(modes) do
            local id=mode
            local entry={tooltip=id=="class" and "Class Color" or id=="accent" and "Accent Color" or "Custom Color",hasAlpha=false,
                refreshAlpha=function() return Mode()==id and 1 or .3 end}
            if id=="custom" then
                entry.getValue=function() local c=Selected()[colorKey] or {}; return c.r or 1,c.g or 1,c.b or 1 end
                entry.setValue=function(r,g,b) Selected()[colorKey]={r=r,g=g,b=b}; Pick("custom") end
                entry.onClick=function(button) if Mode()~="custom" then Pick("custom"); return end; if button._eabOrigClick then button._eabOrigClick(button) end end
            elseif id=="class" then
                entry.getValue=function() local c=RAID_CLASS_COLORS and RAID_CLASS_COLORS[select(2,UnitClass("player"))]; if c then return c.r,c.g,c.b end; return 1,1,1 end
                entry.setValue=function() end; entry.onClick=function() Pick("class") end
            else
                entry.getValue=function() if E.GetAccentColor then return E.GetAccentColor() end; return 1,1,1 end
                entry.setValue=function() end; entry.onClick=function() Pick(id) end
            end
            swatches[#swatches+1]=entry
        end
        return {type="multiSwatch",text=label,swatches=swatches}
    end
    local function BorderSwatch()
        local function Accent() return Selected().borderUseAccent~=false end
        local function Pick(accent) Selected().borderUseAccent=accent; ns.Apply(); if E.RefreshPage then E:RefreshPage() end end
        return {type="multiSwatch",text="Border Color",swatches={
            {tooltip="Accent Color",hasAlpha=false,
             getValue=function() if E.GetAccentColor then return E.GetAccentColor() end; return 1,1,1 end,
             setValue=function() end,onClick=function() Pick(true) end,refreshAlpha=function() return Accent() and 1 or .3 end},
            {tooltip="Custom Color",hasAlpha=false,
             getValue=function() local c=Selected().borderColor or {}; return c.r or 1,c.g or 1,c.b or 1 end,
             setValue=function(r,g,b) Selected().borderColor={r=r,g=g,b=b}; Pick(false) end,
             onClick=function(button) if Accent() then Pick(false); return end; if button._eabOrigClick then button._eabOrigClick(button) end end,
             refreshAlpha=function() return Accent() and .3 or 1 end},
        }}
    end
    E:RegisterModule("EllesmereUIDamageMeters",{
        title="Damage Meters",description="Independent combat statistics for Wrath. No Details dependency.",
        pages={"Windows","Combat Data"},
        searchTerms="damage DPS healing HPS meter details overheal taken absorbs interrupts dispels deaths recap resources mana rage energy runic power threat pets segments history spells targets buffs debuffs uptime report opacity transparency background outline fonts specialization icons border header bar texture spacing refresh rate always show player number format rank bookmarks",
        buildPage=function(page,parent,y)
            local W=E.Widgets
            local function Row(a,b) local _,h=W:DualRow(parent,y,a,b or Label("")); y=y-h end
            local function Section(text) local _,h=W:SectionHeader(parent,text,y); y=y-h end
            local function Button(text,fn) local _,h=W:WideButton(parent,text,y,fn); y=y-h end
            Section("DAMAGE METERS")
            Row(Field(ns.Profile,"enabled","Enable Damage Meters","toggle"),Label("Uses native Wrath combat events"))
            if page=="Combat Data" then
                Section("COLLECTION AND HISTORY")
                Row(Field(ns.Profile,"mergePets","Merge Pets With Owners","toggle"),Field(ns.Profile,"groupOnly","Only Show Group Members","toggle"))
                Row(Field(ns.Profile,"saveHistory","Save History Between Sessions","toggle"),Field(ns.Profile,"historyLimit","Stored Segments","slider",1,30))
                Row(Field(ns.Profile,"autoCurrent","Current Segment On Combat","toggle"),Field(ns.Profile,"endDelay","Combat End Grace (Seconds)","slider",1,10))
                Row(Label("Pet merge applies to newly collected events."),Label("DPS/HPS use combat duration."))
                Section("WRATH DATA")
                Row(Label("Absorbs Received: shields consumed on each player."),Label("Healing excludes overheal and inferred shields."))
                Row(Label("Aura uptime: sum of observed seconds across targets."),Label("Threat: native values for the current target."))
                Row(Label("Resource amounts are separated by power type."),Label("Death recap: last 20 seconds, up to 40 events."))
                Button("Clear Combat History...",ns.ShowReset)
                return math.abs(y)
            end
            Section("WINDOW SETTINGS")
            local values,order={},{}
            for i,w in ipairs(ns.Profile().windows) do values[i]=w.name; order[#order+1]=i end
            Row({type="dropdown",text="Select Window",values=values,order=order,getValue=function() Selected(); return ns.selectedWindow end,
                setValue=function(value) ns.selectedWindow=value; Refresh() end},Label("Up to four independent windows"))
            Button("Create Meter Window",function() ns.NewWindow(); Refresh() end)
            local cfg=Selected(); if not cfg then return math.abs(y) end
            Row(Field(Selected,"name","Window Name","input"),Field(Selected,"enabled","Show Window","toggle"))
            local metrics,metricOrder={},{}
            for _,m in ipairs(ns.metrics) do metrics[m.key]=m.label; metricOrder[#metricOrder+1]=m.key end
            local segments,segmentOrder=ns.SegmentChoices()
            Row(DD(Selected,"metric","Display",metrics,metricOrder),DD(Selected,"segment","Segment",segments,segmentOrder))
            Row(Field(Selected,"width","Window Width","slider",220,650,10),Field(Selected,"rows","Visible Rows","slider",1,40))
            Row(Field(Selected,"scale","Window Scale","slider",.5,2,.05),Field(Selected,"locked","Lock Window Position","toggle"))

            Section("DISPLAY")
            Row(DD(Selected,"visibility","Visibility",{always="Always",combat="In Combat",group="In Group"},{"always","combat","group"}),
                Field(ns.Profile,"refreshRate","Refresh Rate (Seconds)","slider",.1,2,.1))
            Row(Field(Selected,"borderSize","Border Size","slider",0,4),BorderSwatch())
            Row(Field(Selected,"alpha","Background Opacity","slider",0,1,.05),ColorField("bgColor","Background Color"))
            Row(Field(Selected,"alwaysShowPlayer","Always Show Player","toggle"),DD(Selected,"fontOutline","Font Outline",
                {OUTLINE="Outline",THICKOUTLINE="Thick Outline",[""]="None",GLOBAL="Use EUI Font Setting"},{"OUTLINE","THICKOUTLINE","","GLOBAL"}))

            Section("HEADER")
            Row(Field(Selected,"headerHeight","Header Height","slider",16,34),Field(Selected,"chromeAlpha","Header / Footer Opacity","slider",0,1,.05))
            Row(Field(Selected,"headerBorderSize","Header Bottom Border","slider",0,4),ColorField("headerBorderColor","Header Border Color"))
            Row(Field(Selected,"titleFontSize","Header Text Size","slider",8,20),ColorField("titleColor","Header Text Color"))
            Row(ColorField("headerColor","Header / Footer Color"),Label(""))

            Section("BARS")
            local texNames,texOrder=ns.BarTextureChoices()
            Row(DD(Selected,"barTexture","Bar Texture",texNames,texOrder),Field(Selected,"rowHeight","Bar Height","slider",14,36))
            Row(ModeSwatch("Bar Color","barColorMode","barColor",{"class","custom","accent"}),Field(Selected,"barAlpha","Bar Opacity","slider",0,1,.05))
            local iconStyle=DD(Selected,"iconStyle","Icon Style",{spec="Specialization Icons",class="Class Icons",none="No Icons"},{"spec","class","none"})
            iconStyle.getValue=function() local c=Selected(); return c.showSpecIcons==false and "none" or c.iconStyle or "spec" end
            iconStyle.setValue=function(v) local c=Selected(); c.iconStyle=v; c.showSpecIcons=v~="none"; ns.Apply() end
            Row(Field(Selected,"barSpacing","Spacing","slider",0,10),iconStyle)
            Row(Field(Selected,"barBorderSize","Bar Border Size","slider",0,3),ColorField("barBorderColor","Bar Border Color"))
            Row(ColorField("barBgColor","Bar Background",true),Label(""))

            Section("BAR TEXT")
            Row(DD(Selected,"numberFormat","Number Format",{short="Short (12.3k)",full="Full (12345)",comma="Separated (12,345)"},{"short","full","comma"}),
                Field(Selected,"hideRank","Hide Rank Numbers","toggle"))
            Row(Field(Selected,"fontSize","Left Text Size","slider",8,20),Field(Selected,"valueFontSize","Right Text Size","slider",8,20))
            Row(Field(Selected,"showRate","Show DPS / HPS Beside Total","toggle"),Field(Selected,"showPercent","Show Percentage","toggle"))

            Section("EXTRAS")
            Row(Field(Selected,"hoverBreakdown","Show Breakdown on Hover","toggle"),Field(Selected,"spellTooltips","Show Spell Tooltips on Hover","toggle"))
            Row(Label("Click a player: spell details. Shift-click: full window."),Label("Right click: back from details, or open meter bookmarks."))
            Row(Label("Drag the header to move; mouse wheel scrolls rows."),Label("Middle click a bookmark to remove it."))
            Button("Unlock Mode",function() if E.ToggleUnlockMode then E:ToggleUnlockMode() end end)
            Button("Reset Window Position",function() cfg.savedPos=nil; ns.Apply() end)
            Button("Preview / Copy / Send Report",function() ns.ShowReport(ns.selectedWindow) end)
            Button("Clear Combat History...",ns.ShowReset)
            return math.abs(y)
        end,
        onReset=function() ns.addon.db:ResetProfile(); ns.Apply(); Refresh() end,
    })
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
