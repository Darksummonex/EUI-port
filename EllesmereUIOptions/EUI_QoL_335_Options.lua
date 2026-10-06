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
        searchTerms="qol repair junk sell loot mail open all attach delete cinematic train screenshot containers reset role check map coordinates right click rested transform flyout item level fps latency stats crit haste hit coordinates crosshair durability death combat alert sound distance zone text rebirth bloodlust sated movement cursor shifter raid ready markers pull disband interrupt announce invite accept guild friends dbm bigwigs boss mod bars ability timeline logging",
        buildPage=function(page,parent,y)
            local W=E.Widgets
            local function Row(a,b) local row,h=W:DualRow(parent,y,a,b or Label("")); y=y-h; return row end
            local function Section(label) local _,h=W:SectionHeader(parent,label,y); y=y-h end
            local function Button(label,fn) local _,h=W:WideButton(parent,label,y,fn); y=y-h end
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
                Section("MAIL")
                Row(Toggle(nil,"mailOpenAll","Mailbox: Open All Button"),Toggle(nil,"mailBulkAttach","Shift-Click: Attach Same Category"))
                Row(Label("Open All skips COD and GM mail"),Label("Ore, herbs, cloth... BoE gear by quality"))
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
                Row(Toggle(nil,"fpsLabels","Latency Labels"),Dropdown(nil,"fpsColorMode","Text Color",{custom="Custom",class="Class Color"},{"custom","class"}))
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
                zone.tooltip="Moves the zone name shown when entering an area to the top of the screen. Off restores Blizzard's position."
                Row(zone,Label("Fixed at top center, X 9 / Y 322"))
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
                Section("RAID TOOLS")
                Row(Toggle("raidTools","enabled","Show Raid Tools"),Toggle("raidTools","groupOnly","Only in a Group"))
                Row(Slider("raidTools","scale","Window Scale %",50,200),Label("Eight target markers, Ready Check, Pull and Disband"))
                Row(Slider("raidTools","pullSeconds","Pull Timer Length (seconds)",3,60),Toggle("raidTools","pullSync","Send to DBM / BigWigs"))
                Row(Toggle("raidTools","pullChat","Chat Countdown"),Label("Raid Warning > Raid > Party; 10s and final 5s"))
                Row(Label("Boss mod sync: raid leader / assistant or party leader"),Label(""))
                Button("Move Raid Tools",unlock)
                Button("Disband Group",function() if ns.ConfirmDisband then ns.ConfirmDisband() end end)
                Section("BOSS MOD BARS")
                local bossBars=Toggle(nil,"hideBossModBars","Hide DBM/BigWigs Bars While Timeline Is Active")
                bossBars.tooltip="While AbilityTimeline shows DBM or BigWigs timers, that boss mod's own bars turn invisible and click-through. The timers keep running, and the bars come back when the timeline, its source or this option is turned off."
                Row(bossBars,Label(ns.BossBarsStatus and ns.BossBarsStatus() or ""))
            elseif page=="Logging" then
                Section("COMBAT LOGGING")
                Row(Toggle("logging","enabled","Automatic Combat Logging"),Toggle("logging","raids","Log Raids"))
                Row(Toggle("logging","dungeons","Log Dungeons"),Label("Uses Logs/WoWCombatLog.txt"))
                Row(Label("Logging you started manually remains under your control"),Label(""))
            end
            return math.abs(y)
        end,
        onReset=function() ns.addon.db:ResetProfile(); ns.Apply(); E:InvalidatePageCache() end})
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
