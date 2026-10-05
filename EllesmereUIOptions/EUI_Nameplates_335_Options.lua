local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
local E=EllesmereUI
local ns=E and E._ModuleNS and E._ModuleNS.EllesmereUINameplates
if not ns or not ns.IsWrath then return end
local init=CreateFrame("Frame"); init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent",function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local function Get(key) local p=ns.GetSettings(); return p and p[key] end
    local function Set(key,value) local p=ns.GetSettings(); if p then p[key]=value; if key=="onlyPlayerDebuffs" then p.debuffFilterMode=value and "own" or "all" end; ns.Apply() end end
    local function Toggle(key,label,tip) return {type="toggle",text=label,tooltip=tip,getValue=function() return Get(key) end,setValue=function(v) Set(key,v) end} end
    local function Slider(key,label,low,high,step) return {type="slider",text=label,min=low,max=high,step=step or 1,getValue=function() return Get(key) end,setValue=function(v) Set(key,v) end} end
    local function CVar(key,label,tip)
        return {type="toggle",text=label,tooltip=tip,getValue=function() return GetCVar(key)=="1" end,setValue=function(v) ns.SetNativeCVar(key,v) end}
    end
    local function Texture(key,label)
        return {type="dropdown",text=label,values=ns.textureValues,order=ns.textureOrder,getValue=function() return Get(key) end,setValue=function(v) Set(key,v) end}
    end
    E:RegisterModule("EllesmereUINameplates",{
        title="Nameplates",description="Wrath nameplate health, casts, GUID-tracked auras and filters.",
        pages={"Nameplates","Cast & Auras","Aura Filters","Fonts"},searchTerms="nameplate enemy friendly health cast aura debuff buff filter tracked excluded spell id threat tank target opacity name font",
        buildPage=function(page,parent,y)
            local W=E.Widgets
            local function Row(left,right) local _,h=W:DualRow(parent,y,left,right); y=y-h end
            local function Section(label) local _,h=W:SectionHeader(parent,label,y); y=y-h end
            if page=="Nameplates" then
                Section("DISPLAY")
                Row(Toggle("enabled","Enable Nameplate Styling"),Toggle("friendlyNameOnly","Friendly Name Only"))
                Row(CVar("nameplateShowEnemies","Show Enemy Nameplates"),CVar("nameplateShowFriends","Show Friendly Nameplates"))
                Row(CVar("nameplateAllowOverlap","Allow Overlap"),CVar("ShowClassColorInNameplate","Native Class Colors"))
                Row(Slider("width","Width",60,300),Slider("height","Health Bar Height",4,30))
                Row(Slider("yOffset","Vertical Offset",-30,40),Texture("healthBarTexture","Health Texture"))
                Row(Slider("borderSize","Border Size",0,4),Slider("targetScale","Target Scale",1,1.5,.05))
                Row(Toggle("showTargetBorder","Target Border"),Toggle("showHealthText","Health Percentage"))
                Row(Toggle("showLevel","Level & Elite Indicator"),Toggle("classColoredNames","Class Colored Names","Allied names keep their class color without target or mouseover. Group/raid members are identified automatically; other allies are learned from target, mouseover or focus."))
                Row(Slider("opacity","Opacity",10,100),Slider("nonTargetAlpha","Additional Non-target Opacity",10,100))
                Row(Toggle("showRaidMarker","Raid Marker"),Slider("raidMarkerSize","Raid Marker Size",12,40))
                Section("FRIENDLY PLAYERS")
                Row(Toggle("friendlyHealthClassColored","Class Colored Health Bar","Colors allied player bars using their class. Group/raid members are identified automatically; other allies are learned from target, mouseover or focus."),{type="label",text="Names use Class Colored Names above."})
                Section("THREAT")
                Row(Toggle("threatColors","Threat Colors"),Toggle("tankMode","Tank Threat Colors","Green when you hold aggro; orange for the native rising-threat indicator. Other roles use red for aggro."))
            elseif page=="Cast & Auras" then
                Section("CAST BAR")
                Row(Toggle("showCastBar","Show Cast Bar"),Slider("castHeight","Cast Bar Height",4,20))
                Row(Toggle("showCastName","Cast Name","Spell names appear on identified target and mouseover plates."),Toggle("showCastTimer","Cast Timer"))
                Row(Texture("castBarTexture","Cast Texture"),{type="label",text=""})
                Section("AURAS")
                Row(Toggle("showAuras","Show Auras","Uses live target/mouseover auras and the GUID aura cache for other identified plates."),Toggle("onlyPlayerDebuffs","Only Your Debuffs","Includes debuffs cast by your pet."))
                Row(Toggle("showDebuffs","Show Debuffs"),Toggle("showBuffs","Show Buffs"))
                Row(Slider("auraSize","Aura Icon Size",12,36),Slider("maxAuras","Maximum Auras",1,8))
            elseif page=="Aura Filters" then
                return E.BuildWrathAuraFilters("EllesmereUINameplates",parent,y)
            elseif page=="Fonts" then
                Section("TEXT SIZES")
                Row(Slider("nameSize","Name Size",8,24),Slider("healthTextSize","Health Text Size",8,20))
                Row(Slider("levelSize","Level Size",8,20),Slider("castNameSize","Cast Name Size",8,20))
                Row(Slider("castTimerSize","Cast Timer Size",8,20),Slider("auraStackTextSize","Aura Stack Size",8,20))
                Row(Slider("auraDurationTextSize","Aura Timer Size",8,20),{type="label",text="Font and outline follow Global Settings > Fonts > Nameplates."})
            end
            return math.abs(y)
        end,
        onReset=function() if ns.db and ns.db.ResetProfile then ns.db:ResetProfile() end; ns.Apply(); E:InvalidatePageCache() end,
    })
    SLASH_ELLESMERENAMEPLATES1="/enp"
    SlashCmdList.ELLESMERENAMEPLATES=function() if not InCombatLockdown() then E:ShowModule("EllesmereUINameplates") end end
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
