local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
local E=EllesmereUI
local ns=E and E._ModuleNS and E._ModuleNS.EllesmereUIQoL
if not ns or not ns.IsWrath then return end
local init=CreateFrame("Frame"); init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent",function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local function Field(group,key,label,kind,min,max)
        return {type=kind,text=label,min=min,max=max,step=1,
            getValue=function() local p=ns.GetSettings(); return p and (group and p[group] or p)[key] end,
            setValue=function(value) local p=ns.GetSettings(); if p then (group and p[group] or p)[key]=value; ns.Apply() end end}
    end
    local function Toggle(group,key,label) return Field(group,key,label,"toggle") end
    local function Slider(group,key,label,min,max) return Field(group,key,label,"slider",min,max) end
    local function Label(text) return {type="label",text=text} end
    E._ELEMENT_SETTINGS_MAP=E._ELEMENT_SETTINGS_MAP or {}
    for _,c in ipairs(ns.displayLayout) do
        local label=c[1]=="bloodlust" and "Sated / Exhaustion Timer" or c[1]=="battleRes" and "Rebirth Cooldown (Druid)" or c[2]
        E._ELEMENT_SETTINGS_MAP[c[8]]={module="EllesmereUIQoL",page="QoL",sectionName="DISPLAYS",highlightText=label}
    end
    E._ELEMENT_SETTINGS_MAP.EUI_RaidTools={module="EllesmereUIQoL",page="Raid Tools",sectionName="RAID TOOLS",highlightText="Show Raid Tools"}
    E:RegisterModule("EllesmereUIQoL",{title="Quality of Life",description="Native Wrath conveniences, displays, cursor, window dragging and raid tools.",pages={"QoL","Cursor","Shifter","Raid Tools","Logging"},
        searchTerms="qol repair junk sell loot delete cinematic train fps latency stats crit haste coordinates crosshair durability death rebirth bloodlust sated movement cursor shifter raid ready markers pull logging",
        buildPage=function(page,parent,y)
            local W=E.Widgets
            local function Row(a,b) local _,h=W:DualRow(parent,y,a,b or Label("")); y=y-h end
            local function Section(label) local _,h=W:SectionHeader(parent,label,y); y=y-h end
            local function Button(label,fn) local _,h=W:WideButton(parent,label,y,fn); y=y-h end
            if page=="QoL" then
                Section("QUALITY OF LIFE"); Row(Toggle(nil,"enabled","Enable Quality of Life"),Label("Automation and displays start disabled"))
                Section("AUTOMATION")
                Row(Toggle(nil,"autoRepair","Auto Repair"),Toggle(nil,"guildRepair","Use Guild Repair First"))
                Row(Toggle(nil,"autoSellJunk","Auto Sell Junk"),Toggle(nil,"quickLoot","Quick Loot"))
                Row(Toggle(nil,"trainAll","Trainer: Train All Button"),Toggle(nil,"fillDelete","Fill Delete Confirmation"))
                Row(Toggle(nil,"skipCinematics","Skip Cinematics"),Toggle(nil,"hideTutorials","Hide Tutorials"))
                Row(Toggle(nil,"hideErrors","Hide Red Error Messages"),Label("Delete confirmation still requires your click"))
                Section("DISPLAYS")
                Row(Toggle(nil,"fps","FPS and Latency"),Toggle(nil,"stats","Secondary Stats"))
                Row(Toggle(nil,"coordinates","Map Coordinates"),Toggle(nil,"crosshair","Character Crosshair"))
                Row(Slider(nil,"crosshairSize","Crosshair Size",6,40),Toggle(nil,"durability","Durability Warning"))
                Row(Slider(nil,"durabilityThreshold","Durability Threshold %",5,90),Toggle(nil,"combatAlert","Combat Alert"))
                Row(Toggle(nil,"deathAlert","Group Death Alert"),Toggle(nil,"bloodlust","Sated / Exhaustion Timer"))
                Row(Toggle(nil,"battleRes","Rebirth Cooldown (Druid)"),Toggle(nil,"movement","Movement Cooldown"))
                Row(Toggle(nil,"showReady","Show Ready Cooldowns"),Label("Rebirth uses your cooldown; no shared raid charges"))
                Row({type="input",text="Movement Spell ID",placeholder="0 = class default",getValue=function() return tostring(ns.GetSettings().movementSpellID) end,
                    setValue=function(value) local id=tonumber(value); if id and id>=0 and id==math.floor(id) and (id==0 or GetSpellInfo(id)) then ns.GetSettings().movementSpellID=id; ns.Apply() end end},Label("Only learned spells appear"))
                Button("Unlock Display Positions",function() if E.ToggleUnlockMode then E:ToggleUnlockMode() end end)
            elseif page=="Cursor" then
                Section("CURSOR")
                Row(Toggle("cursor","enabled","Cursor Circle"),Toggle("cursor","combatOnly","Only in Combat"))
                Row(Slider("cursor","size","Cursor Size",12,100),Toggle("cursor","classColor","Class Color"))
                Row(Toggle("cursor","trail","Cursor Trail"),Toggle("cursor","gcd","Global Cooldown Progress"))
                Row(Toggle("cursor","cast","Cast / Channel Progress"),{type="dropdown",text="Ring Thickness",values={ring_thin="Thin",ring_light="Light",ring_normal="Normal",ring_heavy="Heavy",ring_thick="Thick"},order={"ring_thin","ring_light","ring_normal","ring_heavy","ring_thick"},getValue=function() return ns.GetSettings().cursor.texture end,setValue=function(v) ns.GetSettings().cursor.texture=v; ns.Apply() end})
            elseif page=="Shifter" then
                Section("WINDOW DRAGGING")
                Row(Toggle("shifter","enabled","Enable Window Dragging"),Label("Shift + left drag: save position"))
                Row(Label("Ctrl + left drag: move until window closes"),Label("Drag empty window backgrounds outside combat"))
                Button("Reset Window Positions",function() ns.GetSettings().shifter.positions={}; ns.GetSettings().shifter.enabled=false; ns.Apply(); E:InvalidatePageCache(); E:RefreshPage(true) end)
            elseif page=="Raid Tools" then
                Section("RAID TOOLS")
                Row(Toggle("raidTools","enabled","Show Raid Tools"),Toggle("raidTools","groupOnly","Only in a Group"))
                Row(Slider("raidTools","pullSeconds","Pull Timer Length (seconds)",3,60),Toggle("raidTools","pullSync","Send to DBM / BigWigs"))
                Row(Toggle("raidTools","pullChat","Chat Countdown"),Label("Raid Warning > Raid > Party; 10s and final 5s"))
                Row(Label("Boss mod sync: raid leader / assistant or party leader"),Label("Eight target markers and Ready Check"))
                Button("Move Raid Tools",function() if E.ToggleUnlockMode then E:ToggleUnlockMode() end end)
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
