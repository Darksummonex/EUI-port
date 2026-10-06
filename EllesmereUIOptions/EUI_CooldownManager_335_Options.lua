local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
-- Retail Cooldown Manager pages (CDM Bars, Bar Glows, Tracking Bars) on Wrath widgets.
local E=EllesmereUI
local ns=E._ModuleNS and E._ModuleNS.EllesmereUICooldownManager
if not ns or not ns.IsWrath then return end
local init=CreateFrame("Frame"); init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent",function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local O={entry=1,rule=1,addKind="spell",addID="",status=""}
    ns.Options=O
    function O.Refresh() E:InvalidatePageCache(); E:RefreshPage(true) end
    function O.Label(t) return {type="label",text=t or ""} end
    O.spacer={type="label",text=""}
    -- Stores: functions returning the table a control edits.
    function O.Bar() local b=ns.BarByKey(ns.selectedBar or "cooldowns") or ns.Bars()[1]; ns.selectedBar=b and b.key; return b end
    function O.Defaults() local b=O.Bar(); if b then b.spellDefaults=b.spellDefaults or {}; return b.spellDefaults end end
    function O.List() return ns.EntriesFor(O.Bar().key) end
    function O.Entry() return O.List()[O.entry] end
    function O.TBB() local l=ns.TBBList(); ns.selectedTBB=math.max(1,math.min(ns.selectedTBB or 1,#l)); return l[ns.selectedTBB] end
    function O.TBBGroupStore() local c=O.TBB(); return c and (c.groupID or 0)>0 and ns.TBBGroup(c.groupID) or nil end
    function O.Glows() local l=ns.Lists(); return l and l.barGlows end
    function O.Rule() local g=O.Glows(); return g and g.list and g.list[O.rule] end
    function O.Get(store,key,fallback) local t=store(); if not t or t[key]==nil then return fallback end; return t[key] end
    function O.Set(store,key,value) local t=store(); if t then t[key]=value; ns.Apply() end end
    function O.T(store,key,label,dis,tip)
        return {type="toggle",text=label,tooltip=tip,disabled=dis,getValue=function() return O.Get(store,key,false) and true or false end,setValue=function(v) O.Set(store,key,v) end}
    end
    function O.S(store,key,label,min,max,step,dis,tip)
        return {type="slider",text=label,min=min,max=max,step=step or 1,tooltip=tip,disabled=dis,getValue=function() return O.Get(store,key,min) end,setValue=function(v) O.Set(store,key,v) end}
    end
    function O.P(store,key,label,dis,tip)
        return {type="slider",text=label,min=0,max=100,step=5,tooltip=tip,disabled=dis,getValue=function() return math.floor(O.Get(store,key,1)*100+.5) end,setValue=function(v) O.Set(store,key,v/100) end}
    end
    function O.D(store,key,label,values,order,dis,tip,fallback)
        return {type="dropdown",text=label,values=values,order=order,tooltip=tip,disabled=dis,getValue=function() return O.Get(store,key,fallback) end,setValue=function(v) O.Set(store,key,v) end}
    end
    -- Per-entry override: "default" clears the key so the bar default applies.
    function O.ED(key,label,values,order,tip)
        return {type="dropdown",text=label,values=values,order=order,tooltip=tip,
            getValue=function() local e=O.Entry(); return e and e[key]~=nil and e[key] or "default" end,
            setValue=function(v) local e=O.Entry(); if e then if v=="default" then e[key]=nil else e[key]=v end; ns.Apply() end end}
    end
    function O.C(store,prefix,label,alpha,dis,tip)
        return {type="colorpicker",text=label,hasAlpha=alpha,tooltip=tip,disabled=dis,
            getValue=function() local t=store() or {}; return t[prefix.."R"] or 1,t[prefix.."G"] or 1,t[prefix.."B"] or 1,t[prefix.."A"] or 1 end,
            setValue=function(r,g,b,a) local t=store(); if not t then return end; t[prefix.."R"],t[prefix.."G"],t[prefix.."B"]=r,g,b; if alpha then t[prefix.."A"]=a or 1 end; ns.Apply() end}
    end
    function O.I(store,key,label,numeric,tip)
        return {type="input",text=label,tooltip=tip,getValue=function() local v=O.Get(store,key); return v~=nil and tostring(v) or "" end,
            setValue=function(v) if numeric then v=tonumber(v) or 0 elseif v=="" then v=nil end; O.Set(store,key,v) end}
    end
    function O.BorderTextures()
        if E.GetBorderTextureDropdown then local ok,v,o=pcall(E.GetBorderTextureDropdown); if ok and v and o then return v,o end end
        return {solid="Solid"},{"solid"}
    end
    O.glow={[0]="None"}; O.glowOrder={0}
    for _,i in ipairs(ns.GLOW_ORDER) do O.glow[i]=ns.GLOW_NAMES[i]; O.glowOrder[#O.glowOrder+1]=i end
    O.glowD={default="Bar Default",[0]="None"}; O.glowDOrder={"default",0}
    for _,i in ipairs(ns.GLOW_ORDER) do O.glowD[i]=ns.GLOW_NAMES[i]; O.glowDOrder[#O.glowDOrder+1]=i end
    O.cse={none="Always Show",lowerAlphaOnCD="Lower Opacity on Cooldown",hiddenOnCDShift="Hide on Cooldown",hiddenReadyShift="Hide When Ready",
        hiddenOnCD="Hide on Cooldown (Keep Place)",hiddenReady="Hide When Ready (Keep Place)",pixelGlowReady="Glow When Ready",pixelGlowReadyUsable="Glow When Ready and Usable"}
    O.cseOrder={"none","lowerAlphaOnCD","hiddenOnCDShift","hiddenReadyShift","hiddenOnCD","hiddenReady","pixelGlowReady","pixelGlowReadyUsable"}
    O.cseD={default="Bar Default"}; O.cseDOrder={"default"}
    for _,k in ipairs(O.cseOrder) do O.cseD[k]=O.cse[k]; O.cseDOrder[#O.cseDOrder+1]=k end
    O.strata={BACKGROUND="Background",LOW="Low",MEDIUM="Medium",HIGH="High",DIALOG="Dialog"}
    O.strataOrder={"BACKGROUND","LOW","MEDIUM","HIGH","DIALOG"}
    O.textPos={center="Center",top="Top",bottom="Bottom",left="Left",right="Right",topleft="Top Left",topright="Top Right",bottomleft="Bottom Left",bottomright="Bottom Right"}
    O.textPosOrder={"center","top","bottom","left","right","topleft","topright","bottomleft","bottomright"}
    O.corner={TOPLEFT="Top Left",TOPRIGHT="Top Right",BOTTOMLEFT="Bottom Left",BOTTOMRIGHT="Bottom Right",CENTER="Center"}
    O.cornerOrder={"TOPLEFT","TOPRIGHT","BOTTOMLEFT","BOTTOMRIGHT","CENTER"}
    O.units={player="Player",target="Target",focus="Focus",pet="Pet"}; O.unitOrder={"player","target","focus","pet"}
    O.filters={HELPFUL="Buff",HARMFUL="Debuff"}; O.filterOrder={"HELPFUL","HARMFUL"}
    O.sounds={none="None",RaidWarning="Raid Warning",ReadyCheck="Ready Check",igQuestFailed="Quest Failed",TellMessage="Whisper",AuctionWindowOpen="Auction Bell"}
    O.soundOrder={"none","RaidWarning","ReadyCheck","igQuestFailed","TellMessage","AuctionWindowOpen"}
    -- Then the shared alert sounds: EllesmereUI's own and SharedMedia ("sm:" keys).
    if E.GetAlertSoundCatalogue then
        local _,names,order=E.GetAlertSoundCatalogue(); local sep=true
        for _,key in ipairs(order) do
            if key=="---" then sep=true
            elseif key~="none" and not O.sounds[key] then
                if sep then O.soundOrder[#O.soundOrder+1]="---"; sep=false end
                O.sounds[key]=names[key] or key; O.soundOrder[#O.soundOrder+1]=key
            end
        end
    end
    O.barTypes={cooldowns="Cooldown Bar",utility="Utility Bar",buffs="Buff Bar",focuskick="FocusKick Bar"}
    O.barTypeOrder={"cooldowns","utility","buffs","focuskick"}
    O.addBarType="cooldowns"
    function O.Context(W,parent,y)
        local B={y=y}
        function B.Row(a,b) local _,h=W:DualRow(parent,B.y,a,b or O.spacer); B.y=B.y-h end
        function B.Section(t) local _,h=W:SectionHeader(parent,t,B.y); B.y=B.y-h end
        function B.Button(t,fn) local _,h=W:WideButton(parent,t,B.y,fn); B.y=B.y-h end
        function B.Visibility(store,rightCfg)
            if E.BuildVisibilityRow and not E._prebuilding then
                local ok,_,h=pcall(E.BuildVisibilityRow,W,parent,B.y,{getStore=store,legacyKey="barVisibility",caps={partyIncludesRaid=false},
                    onChanged=function() ns.Apply() end,onOptionChanged=function() ns.Update() end},rightCfg)
                if ok and h then B.y=B.y-h; return end
            end
            B.Row(O.D(store,"barVisibility","Visibility",{always="Always",never="Never",mouseover="Mouseover",in_combat="In Combat",out_of_combat="Out of Combat",in_raid="In Raid",in_party="In Party",solo="Solo"},
                {"always","never","mouseover","in_combat","out_of_combat","in_raid","in_party","solo"},nil,nil,"always"),rightCfg)
        end
        return B
    end
    function O.Header(B)
        B.Section("COOLDOWN MANAGER")
        B.Row(O.T(ns.Profile,"enabled","Enable Cooldown Manager"),O.Label("Assignments: "..ns.SpecKey()))
        B.Row({type="toggle",text="Preview",tooltip="Shows every bar with placeholder icons while the options are open.",getValue=function() return ns.optionsPreview end,
            setValue=function(v) ns.optionsPreview=v; ns.preview=v or ns.unlockPreview; ns.Apply() end},O.T(ns.Profile,"glowsOnlyInCombat","Glows Only In Combat"))
    end

    --------------------------------------------------------------------------
    -- Page: CDM Bars
    --------------------------------------------------------------------------
    function O.BarSelect(B)
        local values,order={},{}
        for _,b in ipairs(ns.Bars()) do values[b.key]=b.name or b.key; order[#order+1]=b.key end
        B.Section("BARS")
        B.Row({type="dropdown",text="Select Bar",values=values,order=order,getValue=function() return O.Bar().key end,setValue=function(v) ns.selectedBar=v; O.entry=1; O.Refresh() end},
            {type="input",text="Bar Name",getValue=function() return O.Bar().name or "" end,setValue=function(v) if v~="" then O.Bar().name=v; ns.Apply(); O.Refresh() end end})
        B.Row(O.T(O.Bar,"enabled","Show This Bar"),O.Label("Type: "..(O.barTypes[O.Bar().barType] or O.Bar().barType)))
        B.Row(O.T(ns.Profile,"useClassicStyle","Classic Icon Style","Blizzard action button ring and press highlight."),O.T(ns.Profile,"swapPotions","Swap Out-of-Stock Potions","Item presets show the next potion of the family when one runs out."))
        B.Row(O.T(ns.Profile,"readySound","Cooldown Ready Sound"),O.spacer)
        B.Row({type="dropdown",text="New Bar Type",values=O.barTypes,order=O.barTypeOrder,getValue=function() return O.addBarType end,setValue=function(v) O.addBarType=v end},O.spacer)
        B.Button("Add Bar",function() local b=ns.AddBar(O.addBarType); if b then ns.selectedBar=b.key; O.entry=1 end; ns.Apply(); O.Refresh() end)
        local key=O.Bar().key
        if key~="cooldowns" and key~="utility" and key~="buffs" then
            B.Button("Remove Selected Bar",function() if ns.RemoveBar(key) then ns.selectedBar="cooldowns"; O.entry=1 end; ns.Apply(); O.Refresh() end)
        end
    end
    function O.FocusKick(B)
        local s=O.Bar
        B.Section("FOCUSKICK OPTIONS")
        B.Row(O.I(s,"focusKickInterruptSpellID","Interrupt Spell",true,"Spell ID of the interrupt to show. 0 uses your class interrupt."),O.T(s,"focusKickUseTarget","Also Watch Target","Uses your target when no focus is casting."))
        B.Row(O.T(s,"focusReminderEnabled","Cast Reminder Text"),O.C(s,"focusReminder","Reminder Color",false))
        B.Row(O.S(s,"focusReminderSize","Reminder Size",8,32),O.D(s,"focusCastSoundKey","Cast Sound",O.sounds,O.soundOrder,nil,nil,"none"))
        B.Row(O.S(s,"focusReminderOffsetX","Reminder X",-200,200),O.S(s,"focusReminderOffsetY","Reminder Y",-200,200))
    end
    function O.Layout(B)
        local s=O.Bar
        local anchors,anchorOrder={none="None (Free Move)",mouse="Mouse Cursor"},{"none","mouse"}
        local overflow,overflowOrder={},{}
        for _,b in ipairs(ns.Bars()) do if b.key~=O.Bar().key then anchors[b.key]=b.name or b.key; anchorOrder[#anchorOrder+1]=b.key; overflow[b.key]=b.name or b.key; overflowOrder[#overflowOrder+1]=b.key end end
        B.Section("BAR LAYOUT")
        B.Row(O.S(s,"iconSize","Icon Size",16,80),O.S(s,"numRows","Rows",1,10))
        B.Row(O.S(s,"spacing","Spacing",0,20),O.D(s,"growDirection","Grow Direction",{RIGHT="Right",LEFT="Left",CENTER="Center"},{"RIGHT","LEFT","CENTER"}))
        B.Row(O.D(s,"rowGrowDirection","Row Grow Direction",{DOWN="Down",UP="Up"},{"DOWN","UP"}),O.T(s,"verticalOrientation","Vertical Orientation"))
        B.Row(O.S(s,"maxIcons","Max Icons",0,40,1,nil,"0 = no limit. Extra icons move to the overflow bar."),O.D(s,"overflowTarget","Overflow To",overflow,overflowOrder,function() return (O.Get(s,"maxIcons",0) or 0)==0 end))
        B.Row(O.D(s,"anchorTo","Anchor To",anchors,anchorOrder,nil,nil,"none"),O.D(s,"anchorPosition","Anchor Side",{left="Left",right="Right",top="Top",bottom="Bottom"},{"left","right","top","bottom"},function() local a=O.Get(s,"anchorTo","none"); return a=="none" or a=="mouse" end))
        B.Row(O.S(s,"anchorOffsetX","Anchor Offset X",-300,300),O.S(s,"anchorOffsetY","Anchor Offset Y",-300,300))
        B.Row(O.P(s,"barOpacity","Bar Opacity"),O.D(s,"barStrata","Frame Strata",O.strata,O.strataOrder,nil,nil,"MEDIUM"))
        B.Row(O.T(s,"oocFadeEnabled","Fade Out of Combat"),O.P(s,"oocFadeAlpha","Out of Combat Opacity",function() return not O.Get(s,"oocFadeEnabled") end))
        B.Row(O.D(s,"sort","Icon Order",{assigned="Assigned Order",remaining="Remaining Duration"},{"assigned","remaining"}),O.T(s,"suppressGCD","Ignore Global Cooldown"))
        B.Visibility(s)
        B.Row(O.T(s,"barBgEnabled","Bar Background"),O.C(s,"barBg","Bar Background Color",true,function() return not O.Get(s,"barBgEnabled") end))
        B.Section("ADDITIONAL BAR OFFSET")
        B.Row(O.S(s,"addOffsetX","Offset X",-200,200),O.S(s,"addOffsetY","Offset Y",-200,200))
    end
    function O.IconDisplay(B)
        local s=O.Bar; local tv,to=O.BorderTextures()
        local hasEdge=ns.D and ns.D.HasDrawEdge
        B.Section("ICON DISPLAY")
        B.Row(O.S(s,"iconZoom","Icon Zoom",0,.3,.01),O.D(s,"iconShape","Icon Shape",{none="Square",cropped="Cropped",circle="Circle"},{"none","cropped","circle"}))
        B.Row(O.S(s,"iconCropPercent","Crop Amount",5,25,1,function() return O.Get(s,"iconShape")~="cropped" end),O.C(s,"bg","Icon Background",true))
        B.Row(O.S(s,"borderSize","Border Size",0,8),O.C(s,"border","Border Color",true,function() return O.Get(s,"borderClassColor") end))
        B.Row(O.D(s,"borderTexture","Border Style",tv,to,nil,nil,"solid"),O.T(s,"borderClassColor","Class Colored Border"))
        B.Row(O.T(s,"showCooldownText","Cooldown Text"),O.S(s,"cooldownFontSize","Cooldown Text Size",6,32))
        B.Row(O.D(s,"cooldownTextPosition","Cooldown Text Position",O.textPos,O.textPosOrder),O.C(s,"cooldownText","Cooldown Text Color",false))
        B.Row(O.S(s,"cooldownTextX","Cooldown Text X",-30,30),O.S(s,"cooldownTextY","Cooldown Text Y",-30,30))
        B.Row(O.T(s,"showItemCount","Stacks / Item Count"),O.S(s,"stackCountSize","Stack Text Size",6,32))
        B.Row(O.D(s,"stackCountPosition","Stack Text Position",O.textPos,O.textPosOrder),O.C(s,"stackCount","Stack Text Color",false))
        B.Row(O.T(s,"showKeybind","Show Keybinds"),O.S(s,"keybindSize","Keybind Size",6,24))
        B.Row(O.D(s,"keybindAnchor","Keybind Position",O.corner,O.cornerOrder),O.C(s,"keybind","Keybind Color",true))
        B.Row(O.T(s,"showTooltip","Show Tooltip"),O.T(s,"desaturateOnCD","Desaturate on Cooldown"))
        B.Row(O.T(s,"showRange","Out of Range Color"),O.C(s,"range","Range Color",false,function() return not O.Get(s,"showRange") end))
        B.Row(O.T(s,"showNoMana","Not Enough Mana Color"),O.C(s,"mana","Mana Color",false,function() return not O.Get(s,"showNoMana") end))
        B.Row(O.P(s,"swipeAlpha","Swipe Opacity"),O.T(s,"showCooldownEdge","Cooldown Edge",function() return not hasEdge end,"Bright line on the swipe edge (needs a client with Cooldown:SetDrawEdge)."))
        B.Row(O.T(s,"onlyShowNumbers","Only Show Numbers","Hides the swipe and keeps the timer."),O.T(s,"pressMirror","Show Key Presses","Flashes the icon when its action button is pressed."))
        B.Row(O.T(s,"showPassiveTrinkets","Show Passive Trinkets"),O.T(s,"hideItemsIfMissing","Hide Missing Items"))
        if ns.IsBuffBar(O.Bar()) then
            B.Row(O.T(s,"showInactiveBuffIcons","Always Show Buffs"),O.T(s,"desaturateInactiveBuffs","Desaturate Inactive Buffs",function() return not O.Get(s,"showInactiveBuffIcons") end))
            B.Row(O.T(s,"hidePlaceholderIcon","Keep Buffs in Same Place"),O.spacer)
        end
    end
    function O.Extras(B)
        local s,d=O.Bar,O.Defaults
        B.Section("EXTRAS")
        B.Row(O.D(d,"cdStateEffect","Cooldown State",O.cse,O.cseOrder,nil,"Default for every icon on this bar; icons can override it.","none"),O.P(d,"cdStateLowerAlpha","Lower Opacity Amount"))
        B.Row(O.D(s,"procGlowStyle","Proc Glow",O.glow,O.glowOrder),O.D(d,"activeGlow","Active Aura Glow",O.glow,O.glowOrder,nil,nil,0))
        B.Row(O.T(s,"activeState","Show Active State","Spell icons show your own short buff from that spell instead of the cooldown."),O.D(s,"buffGlow","Buff Glow",O.glow,O.glowOrder,nil,nil,0))
        B.Row(O.T(s,"pandemicGlow","Pandemic Glow","Glow when an aura has 30% or less of its duration left."),O.D(s,"pandemicGlowStyle","Pandemic Glow Style",O.glow,O.glowOrder,function() return not O.Get(s,"pandemicGlow") end))
        B.Row(O.C(s,"pandemic","Pandemic Glow Color",false),O.S(s,"pixelGlowLines","Pixel Glow Lines",2,16))
        B.Row(O.S(s,"pixelGlowThickness","Pixel Glow Thickness",1,6),O.S(s,"pixelGlowSpeed","Pixel Glow Speed",1,10))
    end
    function O.Entries(B)
        local list=O.List(); local values,order={},{}
        for i,e in ipairs(list) do
            local m=ns.Resolve(e,O.Bar()); values[i]=i..". "..(m and m.name or ((e.kind or "spell").." "..tostring(e.id))); order[#order+1]=i
        end
        B.Section("TRACKED SPELLS")
        if #order==0 then B.Row(O.Label("No entries on this bar."),O.spacer); return end
        O.entry=math.max(1,math.min(O.entry,#order))
        local e=O.Entry(); local Ent=O.Entry
        B.Row({type="dropdown",text="Edit Entry",values=values,order=order,getValue=function() return O.entry end,setValue=function(v) O.entry=v; O.Refresh() end},O.T(Ent,"enabled","Enable Entry"))
        if e.kind=="aura" then
            B.Row(O.D(Ent,"unit","Aura Unit",O.units,O.unitOrder,nil,nil,"player"),O.D(Ent,"filter","Aura Type",O.filters,O.filterOrder,nil,nil,"HELPFUL"))
            B.Row(O.T(Ent,"ownOnly","Own Auras Only"),O.T(Ent,"alwaysShow","Always Show","Keeps the icon visible (dimmed) while the aura is down."))
            B.Row(O.ED("buffGlow","Buff Glow",O.glowD,O.glowDOrder),O.S(Ent,"maxStacks","Max Stacks",0,20,1,nil,"0 = off"))
            B.Row(O.D(Ent,"maxStacksGlow","Max Stacks Glow",O.glow,O.glowOrder,nil,nil,0),O.C(Ent,"glowColor","Glow Color",false))
        else
            B.Row(O.ED("cdStateEffect","Cooldown State",O.cseD,O.cseDOrder),O.ED("cdStateGlowStyle","Ready Glow Style",O.glowD,O.glowDOrder))
            if e.kind=="spell" then
                B.Row(O.ED("procGlow","Proc Glow",O.glowD,O.glowDOrder),O.ED("activeGlow","Active Aura Glow",O.glowD,O.glowDOrder))
                B.Row(O.I(Ent,"procAuraID","Proc Aura ID",true,"Buff that marks this spell as proc'd (0 = built-in list)."),O.S(Ent,"procStacks","Proc Stacks",0,10))
                B.Row(O.I(Ent,"activeAuraID","Active Aura ID",true,"Buff shown as the active state (0 = same-named buff)."),O.I(Ent,"activeDuration","Active Duration",true,"Seconds to show the active state after a cast, for spells without a buff."))
                B.Row(O.T(Ent,"activeBorderEnabled","Active Border"),O.C(Ent,"activeBorder","Active Border Color",true))
            end
            B.Row(O.T(Ent,"reverseSwipe","Reverse Swipe"),O.T(Ent,"hideCDSwipe","Hide Swipe"))
            B.Row(O.T(Ent,"suppressGCD","Ignore Global Cooldown"),O.C(Ent,"glowColor","Glow Color",false))
        end
        B.Row(O.I(Ent,"customIcon","Custom Icon",false,"Spell ID or texture path."),O.spacer)
        B.Row(O.I(Ent,"talentName","Talent Condition",false,"Talent name; the entry only shows when the condition matches."),
            {type="dropdown",text="Talent Must Be",values={taken="Taken",missing="Not Taken"},order={"taken","missing"},
                disabled=function() local x=O.Get(Ent,"talentName"); return not x or x=="" end,
                getValue=function() return O.Get(Ent,"talentTaken")==false and "missing" or "taken" end,
                setValue=function(v) O.Set(Ent,"talentTaken",v~="missing") end})
        B.Button("Move Entry Up",function() local l=O.List(); local i=O.entry; if i>1 then l[i],l[i-1]=l[i-1],l[i]; O.entry=i-1; ns.Apply(); O.Refresh() end end)
        B.Button("Move Entry Down",function() local l=O.List(); local i=O.entry; if i<#l then l[i],l[i+1]=l[i+1],l[i]; O.entry=i+1; ns.Apply(); O.Refresh() end end)
        B.Button("Remove Entry",function() table.remove(O.List(),O.entry); ns.Apply(); O.Refresh() end)
    end
    function O.AddEntry(kind,id)
        local l=O.List(); local isPreset=kind=="preset" or kind=="buffpreset"
        if #l>=40 then O.status="Maximum 40 entries per bar"; O.Refresh(); return end
        if not isPreset then
            id=tonumber(id)
            if not id or id<1 or id~=math.floor(id) or kind=="slot" and id>19 then O.status="Enter a valid ID or equipment slot 1-19"; O.Refresh(); return end
            if (kind=="spell" or kind=="aura") and not GetSpellInfo(id) then O.status="Spell ID unavailable in this client"; O.Refresh(); return end
        end
        local entry
        if kind=="buffpreset" then local p=ns.BUFF_PRESET_BY_KEY[id]; if not p then return end; entry={kind="aura",id=p.ids[1],preset=id,unit="player",filter="HELPFUL",enabled=true}
        else entry={kind=kind,id=id,enabled=true,unit="player",filter="HELPFUL"} end
        l[#l+1]=entry; O.entry=#l
        O.status="Added. Unlearned spells and empty slots stay hidden."; ns.Apply(); O.Refresh()
    end
    function O.Add(B)
        B.Section("ADD ENTRY")
        B.Row({type="dropdown",text="Entry Type",values={spell="Spell Cooldown",aura="Buff / Debuff",item="Item Cooldown",slot="Equipment Slot"},order={"spell","aura","item","slot"},
            getValue=function() return O.addKind end,setValue=function(v) O.addKind=v end},{type="input",text="Spell / Item ID",getValue=function() return O.addID end,setValue=function(v) O.addID=v end})
        B.Button("Add Entry",function() O.AddEntry(O.addKind,O.addID) end)
        local learned,lo={},{}
        for key,m in pairs(ns.spells or {}) do if type(key)=="string" and m.id and not m.passive and not learned[m.id] then learned[m.id]=m.name; lo[#lo+1]=m.id end end
        table.sort(lo,function(a,b) return learned[a]<learned[b] end)
        B.Row({type="dropdown",text="Add Learned Spell",values=learned,order=lo,getValue=function() return nil end,setValue=function(v) O.AddEntry("spell",v) end},O.Label(O.status))
        local racial,ro={},{}
        for _,id in ipairs(ns.racials) do local n=GetSpellInfo(id); if n and not racial[id] then racial[id]=n; ro[#ro+1]=id end end
        local items,io={},{}; for _,p in ipairs(ns.ITEM_PRESETS) do items[p.key]=p.name; io[#io+1]=p.key end
        B.Row({type="dropdown",text="Add Racial",values=racial,order=ro,getValue=function() return nil end,setValue=function(v) O.AddEntry("spell",v) end},
            {type="dropdown",text="Add Item Preset",values=items,order=io,getValue=function() return nil end,setValue=function(v) O.AddEntry("preset",v) end})
        local buffs,bo={},{}; for _,p in ipairs(ns.BUFF_PRESETS) do buffs[p.key]=p.name; bo[#bo+1]=p.key end
        B.Row({type="dropdown",text="Add Buff Preset",values=buffs,order=bo,getValue=function() return nil end,setValue=function(v) O.AddEntry("buffpreset",v) end},O.spacer)
        B.Button("Copy This Bar to Other Talent Group",function()
            local other=ns.ListsFor(ns.OtherSpecKey()); if other then other[O.Bar().key]=ns.Copy(O.List()); O.status="Copied to "..ns.OtherSpecKey(); O.Refresh() end
        end)
        B.Button("Restore Default Assignments For This Bar",function()
            local _,class=UnitClass("player"); local seed=ns.SeedLists(class)[O.Bar().key]
            ns.Lists()[O.Bar().key]=seed or {}; O.entry=1; ns.Apply(); O.Refresh()
        end)
    end
    function O.CDMBars(B)
        if ns.selectedEntry then
            for i,e in ipairs(O.List()) do if e==ns.selectedEntry then O.entry=i end end
            ns.selectedEntry=nil
        end
        O.BarSelect(B)
        if O.Bar().barType=="focuskick" then O.FocusKick(B) end
        O.Layout(B); O.IconDisplay(B); O.Extras(B)
        if O.Bar().barType~="focuskick" then O.Entries(B); O.Add(B) end
        B.Section("POSITION")
        B.Button("Unlock Mode",function() if E.ToggleUnlockMode then E:ToggleUnlockMode() end end)
        B.Button("Reset Bar Position",function() ns.Profile().positions[O.Bar().key]=nil; ns.Apply() end)
    end

    --------------------------------------------------------------------------
    -- Page: Bar Glows
    --------------------------------------------------------------------------
    function O.BarGlows(B)
        local g=O.Glows(); if not g then return end
        g.list=g.list or {}
        B.Section("BAR GLOWS")
        B.Row(O.T(O.Glows,"enabled","Enable Bar Glows","Glows action buttons (EUI, Blizzard and ElvUI bars) while an aura is up or missing."),O.Label("Assignments: "..ns.SpecKey()))
        local values,order={},{}
        for i,r in ipairs(g.list) do
            local a=GetSpellInfo(tonumber(r.auraID) or 0) or ("Aura "..tostring(r.auraID)); local s=GetSpellInfo(tonumber(r.spellID) or 0) or ("Spell "..tostring(r.spellID))
            values[i]=i..". "..a.." > "..s; order[#order+1]=i
        end
        if #order>0 then
            O.rule=math.max(1,math.min(O.rule,#order))
            local R=O.Rule
            B.Row({type="dropdown",text="Select Glow",values=values,order=order,getValue=function() return O.rule end,setValue=function(v) O.rule=v; O.Refresh() end},O.T(R,"enabled","Enable Glow"))
            B.Row(O.I(R,"auraID","Aura Spell ID",true,"Buff or debuff to watch."),O.I(R,"spellID","Action Button Spell ID",true,"Every action button holding this spell glows."))
            B.Row(O.D(R,"unit","Aura Unit",O.units,O.unitOrder,nil,nil,"player"),O.D(R,"filter","Aura Type",O.filters,O.filterOrder,nil,nil,"HELPFUL"))
            B.Row(O.D(R,"mode","Glow When",{active="Aura Active",missing="Aura Missing"},{"active","missing"},nil,nil,"active"),O.T(R,"ownOnly","Own Auras Only"))
            B.Row(O.S(R,"atStacks","At Stacks",0,20,1,nil,"0 = any stack count"),O.T(R,"onlyInCombat","Only In Combat"))
            B.Row(O.D(R,"glowType","Glow Type",O.glow,O.glowOrder,nil,nil,1),O.C(R,"glow","Glow Color",false))
            B.Button("Remove Glow",function() table.remove(g.list,O.rule); ns.Apply(); O.Refresh() end)
        else B.Row(O.Label("No bar glows yet."),O.spacer) end
        B.Button("Add Glow",function() g.list[#g.list+1]=ns.NewBarGlowRule(); O.rule=#g.list; ns.Apply(); O.Refresh() end)
    end

    --------------------------------------------------------------------------
    -- Page: Tracking Bars
    --------------------------------------------------------------------------
    function O.TBBSelect(B)
        local list=ns.TBBList(); local values,order={},{}
        for i,c in ipairs(list) do
            local n=(c.preset and ns.BUFF_PRESET_BY_KEY[c.preset] and ns.BUFF_PRESET_BY_KEY[c.preset].name) or GetSpellInfo(tonumber(c.spellID) or 0) or c.name or "Bar"
            values[i]=i..". "..n; order[#order+1]=i
        end
        B.Section("TRACKING BARS")
        B.Row(O.T(ns.Profile,"tbbSmooth","Smooth Animation"),O.T(ns.Profile,"useClassicStyleBars","Classic Bar Style"))
        if #order>0 then
            B.Row({type="dropdown",text="Select Bar",values=values,order=order,getValue=function() return ns.selectedTBB end,setValue=function(v) ns.selectedTBB=v; O.Refresh() end},O.T(O.TBB,"enabled","Enable Bar"))
        end
        B.Button("Add Tracking Bar",function() local _,i=ns.AddTrackedBar(0); if i then ns.selectedTBB=i end; ns.Apply(); O.Refresh() end)
        if #order>0 then B.Button("Remove Selected Bar",function()
            local i=ns.selectedTBB; table.remove(list,i)
            local pos=ns.Profile().positions
            for j=i,#list do pos["TBB_"..j]=pos["TBB_"..(j+1)] end
            pos["TBB_"..(#list+1)]=nil
            ns.selectedTBB=math.max(1,i-1); ns.Apply(); O.Refresh()
        end) end
        return #order>0
    end
    function O.TBBTracking(B)
        local s=O.TBB
        local buffs,bo={none="None"},{"none"}; for _,p in ipairs(ns.BUFF_PRESETS) do buffs[p.key]=p.name; bo[#bo+1]=p.key end
        B.Section("TRACKING")
        B.Row(O.D(s,"trackType","Track",{aura="Buff / Debuff",cooldown="Spell Cooldown"},{"aura","cooldown"},nil,nil,"aura"),O.I(s,"spellID","Spell ID",true))
        B.Row(O.I(s,"name","Bar Name",false),{type="dropdown",text="Buff Preset",values=buffs,order=bo,getValue=function() return O.Get(s,"preset") or "none" end,
            setValue=function(v) O.Set(s,"preset",v~="none" and v or nil) end})
        local auraOff=function() return O.Get(s,"trackType")=="cooldown" end
        B.Row(O.D(s,"unit","Aura Unit",O.units,O.unitOrder,auraOff,nil,"player"),O.D(s,"filter","Aura Type",O.filters,O.filterOrder,auraOff,nil,"HELPFUL"))
        B.Row(O.T(s,"ownOnly","Own Auras Only",auraOff),O.T(s,"fillUp","Fill Up",function() return not auraOff() end,"Cooldown bars fill as the cooldown recovers."))
        B.Row(O.T(s,"hideWhenInactive","Hide When Inactive"),O.T(s,"onlyInCombat","Only In Combat"))
        B.Visibility(s)
    end
    function O.TBBLayout(B)
        local s=O.TBB; local texOrder={}
        for _,k in ipairs(ns.TBB_TEXTURE_ORDER) do texOrder[#texOrder+1]=k end
        B.Section("BAR LAYOUT")
        B.Row(O.S(s,"width","Width",40,800),O.S(s,"height","Height",4,80))
        B.Row(O.T(s,"verticalOrientation","Vertical"),O.T(s,"reverseFill","Reverse Fill"))
        B.Row(O.D(s,"texture","Bar Texture",ns.TBB_TEXTURE_NAMES,texOrder,nil,nil,"none"),O.D(s,"barStrata","Frame Strata",O.strata,O.strataOrder,nil,nil,"MEDIUM"))
        B.Row(O.C(s,"fill","Fill Color",true,function() return O.Get(s,"useClassColor") end),O.T(s,"useClassColor","Class Colored Fill"))
        B.Row(O.C(s,"bg","Background Color",true),O.P(s,"opacity","Opacity"))
        B.Row(O.T(s,"gradientEnabled","Enable Gradient"),O.C(s,"gradient","Gradient End Color",true,function() return not O.Get(s,"gradientEnabled") end))
        B.Row(O.D(s,"gradientDir","Gradient Direction",{HORIZONTAL="Horizontal",VERTICAL="Vertical"},{"HORIZONTAL","VERTICAL"},function() return not O.Get(s,"gradientEnabled") end),O.T(s,"showSpark","Show Spark"))
        B.Row(O.S(s,"borderSize","Border Size",0,8),O.C(s,"border","Border Color",true))
        B.Row(O.D(s,"iconDisplay","Icon",{none="Hidden",left="Left",right="Right"},{"none","left","right"},nil,nil,"left"),O.S(s,"iconBorderSize","Icon Border",0,4))
        B.Row(O.S(s,"iconX","Icon X",-50,50),O.S(s,"iconY","Icon Y",-50,50))
    end
    function O.TBBText(B)
        local s=O.TBB; local pos={left="Left",center="Center",right="Right",top="Top",bottom="Bottom"}; local po={"left","center","right","top","bottom"}
        B.Section("TEXT")
        B.Row(O.T(s,"showName","Show Name"),O.S(s,"nameSize","Name Size",6,24))
        B.Row(O.D(s,"namePosition","Name Position",pos,po),O.C(s,"nameText","Name Color",true))
        B.Row(O.S(s,"nameX","Name X",-50,50),O.S(s,"nameY","Name Y",-50,50))
        B.Row(O.T(s,"showTimer","Show Timer"),O.S(s,"timerSize","Timer Size",6,24))
        B.Row(O.D(s,"timerPosition","Timer Position",pos,po),O.C(s,"timerText","Timer Color",true))
        B.Row(O.S(s,"timerX","Timer X",-50,50),O.S(s,"timerY","Timer Y",-50,50))
        B.Row(O.T(s,"decimals","Show Decimals"),O.S(s,"decimalThreshold","Decimals Below",1,30,1,function() return not O.Get(s,"decimals") end))
        B.Row(O.D(s,"stacksPosition","Stacks Position",pos,po),O.S(s,"stacksSize","Stacks Size",6,24))
        B.Row(O.C(s,"stacksText","Stacks Color",true),O.spacer)
    end
    function O.TBBStacks(B)
        local s=O.TBB
        local thr=function() return not O.Get(s,"stackThresholdEnabled") end
        local mx=function() return not O.Get(s,"stackThresholdMaxEnabled") end
        B.Section("STACKS")
        B.Row(O.T(s,"stackThresholdEnabled","Stack Threshold Color"),O.S(s,"stackThreshold","At Stacks",1,50,1,thr))
        B.Row(O.C(s,"stackThreshold","Threshold Color",true,thr),O.T(s,"stackBasedBar","Fill by Stacks","The bar shows stacks out of the maximum instead of time."))
        B.Row(O.T(s,"stackThresholdMaxEnabled","Stack Ticks"),O.S(s,"stackThresholdMax","Max Stacks",1,100,1,mx))
        B.Row(O.I(s,"stackThresholdTicks","Ticks at Stacks",false,"Comma separated, e.g. 3,5"),O.C(s,"stackThresholdTick","Tick Color",true,mx))
        B.Section("PANDEMIC GLOW")
        local pg=function() return not O.Get(s,"pandemicGlow") end
        B.Row(O.T(s,"pandemicGlow","Pandemic Glow","Glows in the last 30% of the duration."),O.D(s,"pandemicGlowStyle","Glow Style",{[1]="Pixel Glow",[4]="Auto-Cast Shine"},{1,4},pg))
        B.Row(O.C(s,"pandemicGlow","Glow Color",false,pg),O.S(s,"pandemicGlowLines","Lines",2,16,1,pg))
        B.Row(O.S(s,"pandemicGlowThickness","Thickness",1,6,1,pg),O.S(s,"pandemicGlowSpeed","Speed",1,10,1,pg))
    end
    function O.TBBGroups(B)
        local s=O.TBB; local G=O.TBBGroupStore; local off=function() return not G() end
        B.Section("GROUP SETTINGS")
        B.Row(O.D(s,"groupID","Group",{[0]="None",[1]="Group 1",[2]="Group 2",[3]="Group 3",[4]="Group 4"},{0,1,2,3,4},nil,"Grouped bars stack together and share one mover.",0),
            O.D(G,"growDirection","Grow Direction",{DOWN="Down",UP="Up",RIGHT="Right",LEFT="Left"},{"DOWN","UP","RIGHT","LEFT"},off,nil,"DOWN"))
        B.Row(O.S(G,"spacing","Group Spacing",0,40,1,off),O.T(G,"autoAdd","Add New Bars to Group",off))
    end
    function O.TrackingBars(B)
        if O.TBBSelect(B) and O.TBB() then O.TBBTracking(B); O.TBBLayout(B); O.TBBText(B); O.TBBStacks(B); O.TBBGroups(B) end
        B.Section("POSITION")
        B.Button("Unlock Mode",function() if E.ToggleUnlockMode then E:ToggleUnlockMode() end end)
        B.Button("Reset Tracking Bar Positions",function()
            local pos=ns.Profile().positions
            for i=1,20 do pos["TBB_"..i]=nil end; for gid=1,4 do pos["TBBG_"..gid]=nil end
            ns.Apply()
        end)
    end
    E:RegisterModule("EllesmereUICooldownManager",{title="Cooldown Manager",description="Wrath spells, items and auras. Assignments are saved for each dual talent group.",
        pages={"CDM Bars","Bar Glows","Tracking Bars"},
        searchTerms="cooldown manager CDM tracking bars buffs debuffs spell aura item equipment trinket glow keybind duration stacks range preview focus kick interrupt pandemic racial potion",
        buildPage=function(page,parent,y)
            local B=O.Context(E.Widgets,parent,y)
            O.Header(B)
            if page=="Bar Glows" then O.BarGlows(B)
            elseif page=="Tracking Bars" then O.TrackingBars(B)
            else O.CDMBars(B) end
            return math.abs(B.y)
        end,
        onReset=function() ns.addon.db:ResetProfile(); ns.unlockSig=nil; ns.Apply(); O.Refresh() end})
    if E.RegisterOnHide then E:RegisterOnHide(function() ns.optionsPreview=false; ns.preview=ns.unlockPreview; ns.Update() end) end
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
