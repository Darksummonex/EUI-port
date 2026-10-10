local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
local E=EllesmereUI
local ns=E and E._ModuleNS and E._ModuleNS.EllesmereUIQoL
if not ns or not ns.IsWrath then return end
local init=CreateFrame("Frame"); init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent",function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local function Store(group) local p=ns.GetSettings(); return p and (group and p[group] or p) end
    local function Field(group,key,label,kind,min,max)
        return {type=kind,text=label,min=min,max=max,step=1,
            getValue=function() local t=Store(group); return t and t[key] end,
            setValue=function(value) local t=Store(group); if t then t[key]=value; ns.Apply() end end}
    end
    local function Toggle(group,key,label) return Field(group,key,label,"toggle") end
    local function Slider(group,key,label,min,max) return Field(group,key,label,"slider",min,max) end
    local function Label(text) return {type="label",text=text} end
    local function Dropdown(group,key,label,values,order)
        local row=Field(group,key,label,"dropdown"); row.values=values; row.order=order; return row
    end
    local function Color(group,key,label,alpha)
        return {type="colorpicker",text=label,hasAlpha=alpha,
            getValue=function() local t=Store(group); local c=t and t[key] or {}; return c.r or 1,c.g or 1,c.b or 1,c.a or 1 end,
            setValue=function(r,g,b,a) local t=Store(group); if not t then return end
                local c=type(t[key])=="table" and t[key] or {}; t[key]=c; c.r,c.g,c.b=r,g,b; if alpha then c.a=a end; ns.Apply() end}
    end
    local function Text(group,key,label,placeholder)
        return {type="input",text=label,placeholder=placeholder,getValue=function() local t=Store(group); return t and tostring(t[key] or "") or "" end,
            setValue=function(value) local t=Store(group); if t then t[key]=tostring(value or ""); ns.Apply() end end}
    end
    -- Rested Indicator lives on the account root because Unit Frames reads it there.
    local function Root(key,label,kind,min,max)
        return {type=kind,text=label,min=min,max=max,step=1,
            getValue=function() local v=EllesmereUIDB and EllesmereUIDB[key]; if kind=="toggle" then return v==true end; return v or 0 end,
            setValue=function(value) if not EllesmereUIDB then return end; EllesmereUIDB[key]=value; if ns.ApplyRested then ns.ApplyRested() end end}
    end
    local function Sounds(key,label)
        local _,names,order=ns.Sounds()
        return Dropdown(nil,key,label,names,order)
    end
    if ns.RegisterElementSettings then ns.RegisterElementSettings() end
    local unlock=function() if E.ToggleUnlockMode then E:ToggleUnlockMode() end end
    E:RegisterModule("EllesmereUIQoL",{title="Quality of Life",description="Native Wrath conveniences, displays, cursor, window dragging and raid tools.",pages={"QoL","Displays","Cursor","Shifter","Raid Tools","Logging"},
        searchTerms="qol repair junk sell loot gossip dialog npc mail open all attach recipient alts merchant vendor wheel pages delete cinematic train screenshot containers reset role check map coordinates right click rested transform flyout item level fps latency stats crit haste hit coordinates crosshair durability death combat alert sound distance zone text rebirth bloodlust sated movement cursor shifter raid ready markers pull disband interrupt announce invite accept guild friends dbm bigwigs logging self combat text scrolling damage taken healing received",
        buildPage=function(page,parent,y)
            local W=E.Widgets
            local function Row(a,b) local row,h=W:DualRow(parent,y,a,b or Label("")); y=y-h; return row end
            local function Section(label) local _,h=W:SectionHeader(parent,label,y); y=y-h end
            local function Button(label,fn) local _,h=W:WideButton(parent,label,y,fn); y=y-h end
            if not E._prebuilding and ns.RaidToolsPreview then ns.RaidToolsPreview(page=="Raid Tools") end
            if page=="QoL" then
                Section("QUALITY OF LIFE"); Row(Toggle(nil,"enabled","Enable Quality of Life"),Label("Automation and displays start disabled"))
                Section("AUTOMATION")
                local loot,delete=Toggle(nil,"quickLoot","Quick Loot"),Toggle(nil,"fillDelete","Auto-Fill Delete Confirmation")
                loot.tooltip="Loots everything instantly, even with Auto Loot off. Hold Shift when looting to show the loot window."
                delete.tooltip="Automatically types DELETE when throwing away a valuable item. Also allows you to press enter to accept the deletion."
                Row(loot,delete)
                local repair,junk=Toggle(nil,"autoRepair","Auto Repair"),Toggle(nil,"autoSellJunk","Auto Sell Junk")
                repair.tooltip="Automatically repair all gear when visiting a repair vendor."
                junk.tooltip="Automatically sell all junk items when visiting a vendor."
                local repairRow=Row(repair,junk)
                if repairRow and repairRow._leftRegion and E.BuildInlineCog and not E._prebuilding then
                    E.BuildInlineCog(repairRow._leftRegion,{title="Auto Repair Settings",
                        disabled=function() local p=Store(); return not (p and p.autoRepair) end,disabledTooltip="Auto Repair",
                        rows={{type="toggle",label="Use Guild Bank Funds",
                            tooltip="Repairs from the guild bank when your withdraw limit covers the cost, otherwise from your own gold.",
                            get=function() local p=Store(); return p and p.guildRepair end,
                            set=function(v) local p=Store(); if p then p.guildRepair=v; ns.Apply() end end}}})
                end
                Row(Toggle(nil,"trainAll","Trainer: Train All Button"),Toggle(nil,"skipCinematics","Skip Cinematics"))
                Row(Toggle(nil,"autoOpen","Auto Open Containers"),Label("Containers wait for vendors, mail, bank and trade"))
                local wheel=Toggle(nil,"merchantWheel","Merchant: Mouse Wheel Pages")
                wheel.tooltip="Scroll the mouse wheel over a vendor window to turn its item pages."
                local gossip=Toggle(nil,"autoGossip","Auto Select Single Gossip")
                gossip.tooltip="Picks an NPC's only dialog option for you."
                local gossipRow=Row(wheel,gossip)
                if gossipRow and gossipRow._rightRegion and E.BuildInlineCog and not E._prebuilding then
                    local function GossipToggle(key,label,default)
                        return {type="toggle",label=label,
                            get=function() local p=Store(); if not p then return default end; if default then return p[key]~=false end; return p[key] or false end,
                            set=function(v) local p=Store(); if p then p[key]=v end end}
                    end
                    E.BuildInlineCog(gossipRow._rightRegion,{title="Auto Gossip Settings",
                        disabled=function() local p=Store(); return not (p and p.autoGossip) end,disabledTooltip="Auto Select Single Gossip",
                        rows={GossipToggle("autoGossipShiftSkip","Hold Shift to Skip",true),
                            GossipToggle("autoGossipDisableInstance","Disable in Instances",true),
                            GossipToggle("autoGossipIgnoreTrivial","Ignore Low Level Quests",false)}})
                end
                Section("MAIL")
                Row(Toggle(nil,"mailOpenAll","Mailbox: Open All Button"),Toggle(nil,"mailBulkAttach","Shift-Click: Attach Same Category"))
                Row(Label("Open All skips COD and GM mail"),Label("Ore, herbs, cloth... BoE gear by quality"))
                local recipients=Toggle(nil,"mailRecipients","Send Mail: Recipient List")
                recipients.tooltip="An arrow next to the To box lists your alts on this realm and faction, guild members and the last names you mailed."
                Row(recipients,Label("Alts appear after logging in on each one"))
                Section("INTERFACE")
                Row(Toggle(nil,"hideErrors","Hide Error Messages"),Toggle(nil,"hideTutorials","Hide Tutorials"))
                Row(Toggle(nil,"hideScreenshot","Hide Screenshot Status"),Toggle(nil,"mapCoords","Show Coordinates on World Map"))
                Row(Toggle(nil,"flyoutIlvl","Equipment Flyout Item Levels"),Toggle(nil,"hideTransforms","Hide Item Transforms"))
                Row(Root("showRestedIndicator","Rested Indicator","toggle"),Label("ZZZ on the EUI player frame while resting"))
                Row(Root("restedIndicatorXOffset","Rested Indicator X Offset","slider",-50,50),Root("restedIndicatorYOffset","Rested Indicator Y Offset","slider",-50,50))
                Row(Toggle(nil,"rightClickEnemy","Disable Right Click on Enemies"),Toggle(nil,"rightClickAlly","Disable Right Click on Allies in Combat"))
                Row(Label("Right-drag still turns the camera"),Label("Transforms: Hallow's End, Noblegarden, Pilgrim's turkey, Noggenfogger"))
                Section("GROUP")
                Row(Toggle(nil,"resetAnnounce","Announce Instance Reset"),Text(nil,"resetMessage","Reset Message","Instance has been reset - you can re-enter now!"))
                Row(Toggle(nil,"roleCheck","Auto-Accept Role Check"),Label("Hold Shift to review the Dungeon Finder role check"))
                local interrupt=Dropdown(nil,"interruptAnnounce","Announce Interrupts",ns.INTERRUPT_CHANNELS,ns.INTERRUPT_ORDER)
                interrupt.tooltip="Posts the spell you or your pet interrupted. Party and Raid use the battleground channel inside battlegrounds."
                local invites=Toggle(nil,"autoAcceptInvites","Accept Invites from Friends & Guild")
                invites.tooltip="Accepts group invites from your friends list and guildmates. Skipped while queued in the Dungeon Finder or already grouped."
                Row(interrupt,invites)
            elseif page=="Displays" then
                Section("FPS COUNTER")
                Row(Toggle(nil,"fps","FPS and Latency"),Slider(nil,"fpsInterval","Update Interval (seconds)",1,5))
                Row(Toggle(nil,"fpsWorld","Show World Latency"),Toggle(nil,"fpsLocal","Show Local Latency"))
                local fpsColor=Dropdown(nil,"fpsColorMode","Text Color",{quality="Quality",custom="Custom",class="Class Color"},{"quality","custom","class"})
                fpsColor.tooltip="Quality: FPS and each latency value turn green, yellow or red (60/30 fps, 100/250 ms)."
                Row(Toggle(nil,"fpsLabels","Latency Labels"),fpsColor)
                Row(Color(nil,"fpsColor","Custom Color"),Text(nil,"fpsKey","Toggle Keybind","e.g. CTRL-SHIFT-F"))
                Section("SECONDARY STATS")
                Row(Toggle(nil,"stats","Secondary Stats"),Toggle(nil,"statsExtra","Show Hit / Expertise / Armor Pen"))
                Section("CROSSHAIR AND COORDINATES")
                Row(Toggle(nil,"crosshair","Character Crosshair"),Dropdown(nil,"crosshairVisibility","Crosshair Visibility",
                    {always="Always",combat="In Combat",instances="In Instances",instances_combat="Instances + Combat"},{"always","combat","instances","instances_combat"}))
                Row(Slider(nil,"crosshairSize","Crosshair Length",6,80),Slider(nil,"crosshairThickness","Crosshair Thickness",1,6))
                Row(Color(nil,"crosshairColor","Crosshair Color",true),Slider(nil,"crosshairBorder","Crosshair Border",0,3))
                Row(Color(nil,"crosshairBorderColor","Border Color",true),Toggle(nil,"crosshairRange","Color Out of Range"))
                Row(Color(nil,"crosshairRangeColor","Out of Range Color",true),Label("Melee 5 yd, Hunter 35 yd, casters 30 yd"))
                Row(Toggle(nil,"coordinates","Screen Coordinates"),Label("World map overlay: QoL > Interface"))
                Section("TARGET DISTANCE")
                Row(Toggle(nil,"targetDistance","Target Distance Text"),Dropdown(nil,"targetDistanceFormat","Distance Format",
                    {range="Range (30-35)",plus="Lower Bound (30+)",min="Minimum (30)"},{"range","plus","min"}))
                Section("ZONE TEXT")
                local zone=Toggle(nil,"zoneText","Move Zone Text")
                zone.tooltip="Moves the zone name shown when entering an area to the top of the screen (top center, X 9 / Y 322). Off restores Blizzard's position."
                local zoneOutlines={}; for k,v in pairs(E.TEXT_OUTLINE_VALUES or {}) do zoneOutlines[k]=v end; zoneOutlines.module="Blizzard Default"
                local zoneOutline=Dropdown(nil,"zoneTextOutline","Zone Text Outline",zoneOutlines,E.TEXT_OUTLINE_ORDER)
                zoneOutline.getValue=function() local p=Store(); return p and p.zoneTextOutline or "module" end
                zoneOutline.tooltip="Outline for the zone, sub-zone and PvP status text shown when entering an area."
                Row(zone,zoneOutline)
                Section("SELF COMBAT TEXT")
                local sct=Toggle("selfCombatText","enabled","Self Combat Text")
                sct.tooltip="Shows your damage taken, healing, avoids and combat enter/leave above the player frame instead of Blizzard's combat text, whose other messages are hidden while this is on. Move it in Unlock Mode."
                Row(sct,Slider("selfCombatText","size","Combat Text Size",10,48))
                local function Decimal(key,label,min,max,step)
                    local row=Field("selfCombatText",key,label,"slider",min,max); row.step=step; return row
                end
                Row(Dropdown("selfCombatText","anim","Animation",{straight="Straight",fountain="Fountain",static="Static"},{"straight","fountain","static"}),
                    Dropdown("selfCombatText","direction","Direction",{up="Up",down="Down"},{"up","down"}))
                Row(Slider("selfCombatText","rise","Scroll Distance",20,300),Decimal("duration","Duration (seconds)",.5,5,.1))
                local stagger=Toggle("selfCombatText","stagger","Stagger Hits")
                stagger.tooltip="Pushes older messages along so a new one never overlaps them."
                Row(stagger,Decimal("critScale","Crit Size Multiplier",1,3,.1))
                Row(Dropdown("selfCombatText","font","Font",{__combat="Combat Text Font",__global="EllesmereUI Font"},{"__combat","__global"}),
                    Dropdown("selfCombatText","outline","Outline",{NONE="None",OUTLINE="Outline",THICKOUTLINE="Thick Outline"},{"NONE","OUTLINE","THICKOUTLINE"}))
                Row(Toggle("selfCombatText","shadow","Text Shadow"),Toggle("selfCombatText","abbreviate","Abbreviate Numbers"))
                Row(Toggle("selfCombatText","damage","Damage Taken"),Color("selfCombatText","damageColor","Damage Color"))
                Row(Toggle("selfCombatText","heal","Healing Received"),Color("selfCombatText","healColor","Healing Color"))
                Row(Toggle("selfCombatText","avoid","Misses, Dodges and Parries"),Color("selfCombatText","avoidColor","Avoid Color"))
                Row(Toggle("selfCombatText","combat","Entering / Leaving Combat"),Color("selfCombatText","combatColor","Combat Color"))
                Section("ALERTS")
                Row(Toggle(nil,"durability","Low Durability Warning"),Slider(nil,"durabilityThreshold","Durability Threshold %",5,90))
                Row(Color(nil,"durabilityColor","Durability Text Color"),Label("Hidden during combat"))
                Row(Toggle(nil,"combatAlert","Combat Alert"),Dropdown(nil,"combatAlertMode","Show On",{both="Enter and Leave",enter="Entering Combat",leave="Leaving Combat"},{"both","enter","leave"}))
                Row(Text(nil,"combatEnterText","Enter Text","+Combat"),Text(nil,"combatLeaveText","Leave Text","-Combat"))
                Row(Color(nil,"combatEnterColor","Enter Color"),Color(nil,"combatLeaveColor","Leave Color"))
                Row(Toggle(nil,"combatClassColor","Combat Alert Class Color"),Label(""))
                Row(Toggle(nil,"deathAlert","Group Death Alert"),Sounds("deathSound","Death Alert Sound"))
                Section("TRACKERS")
                Row(Toggle(nil,"bloodlust","Sated / Exhaustion Timer"),Toggle(nil,"battleRes","Rebirth Cooldown (Druid)"))
                Row(Toggle(nil,"movement","Movement Cooldown"),Toggle(nil,"movementCombatOnly","Movement: Combat Only"))
                Row(Toggle(nil,"showReady","Show Ready Cooldowns"),Slider(nil,"trackerIconSize","Tracker Icon Size",16,64))
                Row(Sounds("movementSound","Movement Ready Sound"),Label("Rebirth uses your cooldown; no shared raid charges"))
                Row({type="input",text="Movement Spell ID",placeholder="0 = class default",getValue=function() return tostring(ns.GetSettings().movementSpellID) end,
                    setValue=function(value) local id=tonumber(value); if id and id>=0 and id==math.floor(id) and (id==0 or GetSpellInfo(id)) then ns.GetSettings().movementSpellID=id; ns.Apply() end end},Label("Only learned spells appear"))
                Section("MISDIRECTION / TRICKS HELPER")
                local redirect=Toggle("redirect","enabled","Misdirection / Tricks Helper")
                redirect.tooltip="Hunters and Rogues: an icon you click (or bind in Key Bindings > EllesmereUI Quality of Life) that casts Misdirection or Tricks of the Trade on your focus, else the tank, else a friendly target"..", else your pet (Hunter). It shows who it will land on, the cooldown and the buff timer."
                local focus=Toggle("redirect","useFocus","Focus First")
                focus.tooltip="A friendly focus wins over the tank. The focus is checked at the moment you press it, also in combat."
                Row(redirect,focus)
                local tank=Text("redirect","tankName","Tank Name","Empty = raid Main Tank, then tank role")
                tank.tooltip="A group member to use as the tank. Empty uses the raid Main Tank, then the Dungeon Finder tank role. Updates out of combat."
                Row(tank,Slider("redirect","size","Helper Icon Size",20,64))
                Row(Toggle("redirect","showName","Show Target Name"),Label("Macro alternative: /click EUI335QoLRedirect"))
                Button("Unlock Display Positions",unlock)
            elseif page=="Cursor" then
                Section("CURSOR")
                Row(Toggle("cursor","enabled","Cursor Circle"),Toggle("cursor","combatOnly","Only in Combat"))
                Row(Slider("cursor","size","Cursor Size",12,100),Toggle("cursor","classColor","Class Color"))
                Row(Color("cursor","color","Custom Color"),Slider("cursor","opacity","Circle Opacity",10,100))
                Row(Toggle("cursor","instancesOnly","Only Show in Instances"),Toggle("cursor","reticle","Center Reticle"))
                Row(Toggle("cursor","trail","Cursor Trail"),Toggle("cursor","gcd","Global Cooldown Progress"))
                Row(Toggle("cursor","cast","Cast / Channel Progress"),Dropdown("cursor","texture","Ring Thickness",{ring_thin="Thin",ring_light="Light",ring_normal="Normal",ring_heavy="Heavy",ring_thick="Thick"},{"ring_thin","ring_light","ring_normal","ring_heavy","ring_thick"}))
            elseif page=="Shifter" then
                Section("WINDOW DRAGGING")
                Row(Toggle("shifter","enabled","Enable Window Dragging"),Label("Shift + left drag: save position"))
                Row(Label("Ctrl + left drag: move until window closes"),Label("Drag empty window backgrounds outside combat"))
                Button("Reset Window Positions",function() ns.GetSettings().shifter.positions={}; ns.GetSettings().shifter.enabled=false; ns.Apply(); E:InvalidatePageCache(); E:RefreshPage(true) end)
            elseif page=="Raid Tools" then
                local function RT() return Store("raidTools") or {} end
                local function Off() return ns.RaidToolsMode(Store())=="never" end
                local function ShowAs() return ns.RaidToolsShowAs() end
                local function WindowsOff() return Off() or ShowAs()=="compact" end
                local function PanelOff() return Off() or ShowAs()=="compact" or ShowAs()=="markers" end
                local function PullOff() return Off() or ShowAs()=="markers" end
                local function Gate(row,fn) row.disabled=fn; row.disabledTooltip="Show Raid Tools"; return row end
                Section("GENERAL")
                local mode=Dropdown("raidTools","mode","Show Raid Tools",{never="Never",raid="In Raid Group",group="In Any Group",always="Always"},{"never","raid","group","always"})
                mode.tooltip="A raid control panel with ready check, pull timer and target markers. In a raid it only shows while you are the leader or an assistant, since none of its buttons work without that; in a party it always shows."
                mode.getValue=function() return ns.RaidToolsMode(Store()) end
                mode.setValue=function(v) local r=RT(); r.mode=v; r.enabled=v~="never"; ns.Apply(); E:RefreshPage() end
                local kbRow=Row(mode,Label("Toggle Raid Tools"))
                local rgn=kbRow and kbRow._rightRegion
                if rgn and E.BuildKeybindButton and not E._prebuilding then
                    local kb,refresh=E.BuildKeybindButton(rgn,{w=126,h=29,level=4,
                        get=function() return RT().toggleKey end,
                        set=function(v) RT().toggleKey=v or false; ns.Apply() end,
                        disabled=Off,disabledTip="Show Raid Tools",
                        tooltip="Toggles the Raid Tools panels, in or out of combat.\n\nLeft-click to set a keybind.\nRight-click to unbind."})
                    kb:SetPoint("RIGHT",rgn,"RIGHT",-20,0)
                    if E.RegisterWidgetRefresh then E.RegisterWidgetRefresh(refresh) end
                end
                local collapsed=Gate(Toggle("raidTools","collapsedIcon","Default to Collapsed When Shown"),WindowsOff)
                collapsed.tooltip="Full-window modes only. Shows start as a small icon, and the keybind switches between the icon and the full windows."
                collapsed.getValue=function() return RT().collapsedIcon~=false end
                local showAs=Gate(Dropdown("raidTools","showAs","Show as",{compact="Compact Band",one="One Window",two="Two Windows",group="Only Group & Pull",markers="Only Markers"},{"compact","one","two","group","markers"}),Off)
                showAs.tooltip="Compact Band puts markers, ready check and pull timer in one row you can resize in Unlock Mode. The other choices keep the window layouts."
                showAs.getValue=ShowAs
                showAs.setValue=function(v) RT().showAs=v; ns.Apply(); E:RefreshPage() end
                Row(collapsed,showAs)
                local grow=Gate(Dropdown("raidTools","growDir","Menu Grow Direction",{downright="Down Right",upright="Up Right",downleft="Down Left",upleft="Up Left"},{"downright","upright","downleft","upleft"}),WindowsOff)
                grow.tooltip="Full-window modes only. Which way the windows extend from the collapsed icon when they open."
                grow.getValue=function() return RT().growDir or "downright" end
                Row(Gate(Slider("raidTools","scale","Window Scale %",50,200),Off),grow)
                Section("GROUP BUTTONS")
                local convert=Gate(Toggle("raidTools","showConvert","Show Convert to Raid"),PanelOff)
                convert.tooltip="Shows the Convert to Raid button. In a raid of five or fewer it reads Convert to Party: everyone is removed and invited back to a new party."
                convert.getValue=function() return RT().showConvert~=false end
                local disband=Gate(Toggle("raidTools","showDisband","Show Disband"),PanelOff)
                disband.tooltip="Shows the Disband button. It always asks before disbanding, but hiding it puts it out of misclick range for good."
                disband.getValue=function() return RT().showDisband~=false end
                Row(convert,disband)
                local reinvite=Gate(Toggle("raidTools","showReinvite","Show Reinvite"),PanelOff)
                reinvite.tooltip="Shows the Reinvite button. It asks first, then removes everyone and invites them back to the same kind of group. Players have to accept the new invite."
                reinvite.getValue=function() return RT().showReinvite~=false end
                local world=Gate(Toggle("raidTools","worldMarkers","Shift + Click World Markers"),PanelOff)
                world.tooltip="Shift + Left Click a marker icon to use its world marker item, then click the ground. Only markers whose item is in your bags get it; the rest keep Shift + Click to clear the target marker. Shift + Left Click the clear icon presses the server's Reset Markers button."
                world.getValue=function() return RT().worldMarkers~=false end
                Row(reinvite,world)
                Section("PULL TIMER")
                local PULL_TIP="Countdown length in seconds. Compact Band uses First with Ctrl + Left Click, Second with Shift + Left Click, Third with Left Click, and Right Click stops the timer. Set a timer to 0 to disable that shortcut."
                local function Pull(i,label)
                    local row=Gate({type="slider",text=label,min=0,max=60,step=1,tooltip=PULL_TIP,
                        getValue=function() local t=RT().pullTimes; local v=t and t[i]; if v==nil then v=ns.PULL_DEFAULTS[i] end; return v end,
                        setValue=function(v) local r=RT(); if type(r.pullTimes)~="table" then r.pullTimes={} end; r.pullTimes[i]=v; ns.Apply() end},PullOff)
                    return row
                end
                Row(Pull(1,"First Timer"),Pull(2,"Second Timer"))
                Row(Pull(3,"Third Timer"),Gate(Toggle("raidTools","pullSync","Send to DBM / BigWigs"),PullOff))
                Row(Gate(Toggle("raidTools","pullChat","Chat Countdown"),PullOff),Label("Raid Warning > Raid > Party; 10s and final 5s"))
                Row(Label("Boss mod sync: raid leader / assistant or party leader"),Label(""))
                Button("Move Raid Tools",unlock)
            elseif page=="Logging" then
                Section("COMBAT LOGGING")
                Row(Toggle("logging","enabled","Automatic Combat Logging"),Toggle("logging","raids","Log Raids"))
                Row(Toggle("logging","dungeons","Log Dungeons"),Label("Uses Logs/WoWCombatLog.txt"))
                Row(Label("Logging you started manually remains under your control"),Label(""))
            end
            return math.abs(y)
        end,
        onReset=function() ns.addon.db:ResetProfile(); ns.Apply(); E:InvalidatePageCache() end})
    local function Preview(on) if ns.RaidToolsPreview then ns.RaidToolsPreview(on) end end
    if E.RegisterOnHide then E:RegisterOnHide(function() Preview(false) end) end
    if E.RegisterOnShow then E:RegisterOnShow(function()
        if E.GetActiveModule and E:GetActiveModule()=="EllesmereUIQoL" and E:GetActivePage()=="Raid Tools" then Preview(true) end
    end) end
    if E.SelectModule and hooksecurefunc then
        hooksecurefunc(E,"SelectModule",function(_,folder) if folder~="EllesmereUIQoL" then Preview(false) end end)
    end
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
