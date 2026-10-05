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
    local function Label(text) return {type="label",text=text} end
    local editor={mod="shift",button=1,action="spell",id=""}
    E._ELEMENT_SETTINGS_MAP=E._ELEMENT_SETTINGS_MAP or {}
    E._ELEMENT_SETTINGS_MAP.RF_RaidFrames={module="EllesmereUIRaidFrames",page="Raid",sectionName="FRAME SIZES",highlightText="Frame Width"}
    E._ELEMENT_SETTINGS_MAP.RF_PartyFrames={module="EllesmereUIRaidFrames",page="Party",sectionName="FRAME SIZES",highlightText="Frame Width"}
    E:RegisterModule("EllesmereUIRaidFrames",{title="Raid Frames",description="Wrath raid and party frames with native unit clicks, auras, range and click casting.",pages={"Raid","Party","Buffs","Debuffs","Aura Filters","Click Casting"},
        searchTerms="raid party group 10 25 40 players layout hide healer health mana power class name range threat aggro dispel buffs debuffs filter click casting healing ready leader marker preview",
        buildPage=function(page,parent,y)
            if page=="Aura Filters" then return E.BuildWrathAuraFilters("EllesmereUIRaidFrames",parent,y) end
            local W=E.Widgets; local kind=page=="Party" and "party" or "raid"
            local function Row(a,b) local _,h=W:DualRow(parent,y,a,b or Label("")); y=y-h end
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
            else
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
                Row(DD(kind,"sortMethod","Member Sorting",{ROLE="Tank > Healer > DPS",INDEX="Roster Order",NAME="Name"},{"ROLE","INDEX","NAME"}),Toggle(kind,"showPower","Show Power Bar"))
                Row(Slider(kind,"powerHeight","Power Height",2,12),Toggle(kind,"showPowerText","Show Power Percent"))
                Section("APPEARANCE")
                Row(Toggle(kind,"healthClassColored","Class Color Health"),Toggle(kind,"classColoredNames","Class Color Names"))
                Row(DD(kind,"healthBarTexture","Health Bar Texture",ns.healthBarTextureNames,ns.healthBarTextureOrder),DD(kind,"healthDisplay","Health Text",{none="None",percent="Percent",current="Current",missing="Missing",both="Current / Maximum"},{"none","percent","current","missing","both"}))
                Row(Toggle(kind,"rangeFade","Dim Out of Range"),Slider(kind,"outOfRangeAlpha","Out of Range Alpha",.1,1,.05))
                Row(Toggle(kind,"showThreat","Threat Border"),Toggle(kind,"dispelHighlight","Debuff Type Border"))
                Row(Toggle(kind,"showTargetBorder","Target Border"),Toggle(kind,"showRaidMarker","Raid Markers"))
                Row(Toggle(kind,"showRole","Role Icons"),Toggle(kind,"showLeader","Leader Icon"))
                Row(Toggle(kind,"hideDpsRoleIcons","Hide DPS Role Icons"),Label("Tank and healer icons stay visible"))
                Row(Toggle(kind,"showReadyCheck","Ready Check Icons"),kind=="raid" and Toggle(kind,"showGroupNumber","Group Numbers") or Label(""))
                Section("TEXT DISPLAY")
                Row(Slider(kind,"nameSize","Name Size",8,24),Slider(kind,"healthTextSize","Health Text Size",8,24))
                Row(Slider(kind,"powerTextSize","Power Text Size",8,18),Slider(kind,"statusTextSize","Status Text Size",8,24))
                if kind=="raid" then Row(Slider(kind,"groupNumberSize","Group Number Size",8,20),Label("")) end
                Section("AURAS")
                Row(Toggle(kind,"showBuffs","Show Buffs"),Toggle(kind,"showDebuffs","Show Debuffs"))
                Row(Slider(kind,"maxBuffs","Maximum Buffs",0,8),Slider(kind,"maxDebuffs","Maximum Debuffs",0,8))
                Row(Slider(kind,"auraSize","Aura Icon Size",8,30),Toggle(kind,"showAuraTooltips","Aura Tooltips"))
                Row(Slider(kind,"auraDurationTextSize","Aura Duration Size",8,18),Slider(kind,"auraStackTextSize","Aura Stack Size",8,18))
                Row(Toggle(kind,"onlyDispellable","Only Dispellable Debuffs"),Label("Choose spell lists on Aura Filters"))
                Button("Preview Frames",function() ns.SetPreview(true) end); Button("End Preview",function() ns.SetPreview(false) end)
                Button("Unlock Mode",function() if E.ToggleUnlockMode then E:ToggleUnlockMode() end end)
                Button("Reset This Group Position",function() local key=kind=="raid" and "raid"..(ns.selectedRaidLayout or ns.activeRaidLayout or "40") or kind; ns.GetSettings().positions[key]=nil; ns.Apply() end)
            end
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
